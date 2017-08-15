--------------------------------------------------------
--  DDL for Package Body DOC_DOCUMENT_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DOCUMENT_GENERATE" 
is
  /**
  * Description
  *     Efface et réinitialise les données de la variable de type
  *       TDocumentInfo passée en param
  */
  procedure ResetDocumentInfo(aDocumentInfo in out DOC_DOCUMENT_INITIALIZE.TDocumentInfo)
  is
    tmpDocumentInfo DOC_DOCUMENT_INITIALIZE.TDocumentInfo;
  begin
    aDocumentInfo  := tmpDocumentInfo;
  end ResetDocumentInfo;

  procedure GenerateDocument(
    aNewDocumentID     in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aMode              in     varchar2 default null
  , aGaugeID           in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDocNumber         in     DOC_DOCUMENT.DMT_NUMBER%type default null
  , aThirdID           in     DOC_DOCUMENT.PAC_THIRD_ID%type default null
  , aThirdAciID        in     DOC_DOCUMENT.PAC_THIRD_ACI_ID%type default null
  , aThirdDeliveryID   in     DOC_DOCUMENT.PAC_THIRD_DELIVERY_ID%type default null
  , aThirdTariffID     in     DOC_DOCUMENT.PAC_THIRD_TARIFF_ID%type default null
  , aRepresentativeID  in     DOC_DOCUMENT.PAC_REPRESENTATIVE_ID%type default null
  , aRecordID          in     DOC_DOCUMENT.DOC_RECORD_ID%type default null
  , aDocDate           in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type default null
  , aDocCurrencyID     in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type default null
  , aActDocumentID     in     DOC_DOCUMENT.ACT_DOCUMENT_ID%type default null
  , aSrcInterfaceID    in     DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aSrcDocumentID     in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aFalScheduleStepID in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , aDebug             in     number default 1
  , aCreateType        in     varchar2 default null
  , aUserInitProc      in     varchar2 default null
  )
  is
    errorMsg varchar2(2000);
  begin
    GenerateDocument(aNewDocumentID       => aNewDocumentID
                   , aErrorMsg            => errorMsg
                   , aMode                => aMode
                   , aGaugeID             => aGaugeID
                   , aDocNumber           => aDocNumber
                   , aThirdID             => aThirdID
                   , aThirdAciID          => aThirdAciID
                   , aThirdDeliveryID     => aThirdDeliveryID
                   , aThirdTariffID       => aThirdTariffID
                   , aRepresentativeID    => aRepresentativeID
                   , aRecordID            => aRecordID
                   , aDocDate             => aDocDate
                   , aDocCurrencyID       => aDocCurrencyID
                   , aActDocumentID       => aActDocumentID
                   , aSrcInterfaceID      => aSrcInterfaceID
                   , aSrcDocumentID       => aSrcDocumentID
                   , aFalScheduleStepID   => aFalScheduleStepID
                   , aDebug               => aDebug
                   , aCreateType          => aCreateType
                   , aUserInitProc        => aUserInitProc
                    );
  end GenerateDocument;

  /**
  * Description
  *     Méthode générale pour la création de document
  */
  procedure GenerateDocument(
    aNewDocumentID     in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aErrorMsg          out    varchar2
  , aMode              in     varchar2 default null
  , aGaugeID           in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDocNumber         in     DOC_DOCUMENT.DMT_NUMBER%type default null
  , aThirdID           in     DOC_DOCUMENT.PAC_THIRD_ID%type default null
  , aThirdAciID        in     DOC_DOCUMENT.PAC_THIRD_ACI_ID%type default null
  , aThirdDeliveryID   in     DOC_DOCUMENT.PAC_THIRD_DELIVERY_ID%type default null
  , aThirdTariffID     in     DOC_DOCUMENT.PAC_THIRD_TARIFF_ID%type default null
  , aRepresentativeID  in     DOC_DOCUMENT.PAC_REPRESENTATIVE_ID%type default null
  , aRecordID          in     DOC_DOCUMENT.DOC_RECORD_ID%type default null
  , aDocDate           in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type default null
  , aDocCurrencyID     in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type default null
  , aActDocumentID     in     DOC_DOCUMENT.ACT_DOCUMENT_ID%type default null
  , aSrcInterfaceID    in     DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aSrcDocumentID     in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aFalScheduleStepID in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , aDebug             in     number default 1
  , aCreateType        in     varchar2 default null
  , aUserInitProc      in     varchar2 default null
  )
  is
    vCode number(3);
  begin
    -- Réinitialise les données de la varibale globale contenant les infos pour la création du document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO = 1 then
      ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
    end if;

    -- Récupérer le variables passées en param si on n'ont pas encore été
    -- initialisées avant l'appel de la procédure GenerateDocument
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE          := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE, aMode);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE                := upper(nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE, aCreateType) );
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER                 := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER, aDocNumber);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT          := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT, aDocDate);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID            := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID, aNewDocumentID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOC_DOCUMENT_ID        := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOC_DOCUMENT_ID, aSrcDocumentID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID        := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID, aSrcDocumentID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID           := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID, aSrcInterfaceID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID, aDocCurrencyID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID            := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID, aActDocumentID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID               := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID, aGaugeID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID               := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID, aThirdID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID           := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID, aThirdAciID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID      := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID, aThirdDeliveryID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID        := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID, aThirdTariffID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID              := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID, aRecordID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID      := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID, aRepresentativeID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.FAL_SCHEDULE_STEP_ID       := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.FAL_SCHEDULE_STEP_ID, aFalScheduleStepID);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_DEBUG                    := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_DEBUG, aDebug);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USER_INIT_PROCEDURE        := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.USER_INIT_PROCEDURE, aUserInitProc);

    -- Si le tiers preneur/donneur d'ordre a été passé en param, utiliser celui-ci
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID  := 1;
    end if;

    -- Si le tiers facturation a été passé en param, utiliser celui-ci
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID  := 1;
    end if;

    -- Si le tiers livraison a été passé en param, utiliser celui-ci
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
    end if;

    -- Si le tiers tarification a été passé en param, utiliser celui-ci
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID  := 1;
    end if;

    -- Si le dossier a été passé en param, utiliser celui-ci
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;

      -- Si Dossier = -1, cela signife que l'utilisateur veut laisser le Dossier vide
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID = -1 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID  := null;
      end if;
    end if;

    -- Si le représentant a été passé en param, utiliser celui-ci
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID  := 1;

      -- Si Représ. = -1, cela signife que l'utilisateur veut laisser le Représ. vide
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID = -1 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID  := null;
      end if;
    end if;

    -- Si la monnaie a été passée en param, utiliser celle-ci
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY  := 1;
    end if;

    -- Utiliser le ACT_DOCUMENT_ID si celui-ci est renseigné
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PRE_ENTRY  := 1;
    end if;

    begin
      vCode  := to_number(nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE, '0') );
    exception
      when others then
        vCode  := 0;
    end;

    -- Création -> codes 100 ... 199
    if vCode between 100 and 199 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE  := 'INSERT';
    -- Copie -> codes 200 ... 299
    elsif vCode between 200 and 299 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE  := 'COPY';
    -- Décharge -> codes 300 ... 399
    elsif vCode between 300 and 399 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE  := 'DISCHARGE';
    end if;

    -- Appel procédure d'initialisation du record DocumentInfo selon le mode de création
    if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE is not null)
       or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USER_INIT_PROCEDURE is not null) then
      DOC_DOCUMENT_INITIALIZE.CallInitProc;
    end if;

    -- Arrêter l'execution de cette procédure si code d'erreur
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR = 1 then
      aErrorMsg  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE;

      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_DEBUG = 1 then
        raise_application_error(-20000, DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE);
      else
        return;
      end if;
    end if;

    -- Vérifie que toutes les données ai été initialisées,
    --- sinon initialise les données manquantes
    DOC_DOCUMENT_INITIALIZE.ControlInitDocumentData;

    -- Arrêter l'execution de cette procédure si code d'erreur
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR = 1 then
      aErrorMsg  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE;

      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_DEBUG = 1 then
        raise_application_error(-20000, DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE);
      else
        return;
      end if;
    end if;

    -- Insertion du document
    InsertDocument(DOC_DOCUMENT_INITIALIZE.DocumentInfo);

    -- Insertion dans la table de liaison finance->logistique de la pré-saisie
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID is not null then
      declare
        vSql        varchar2(20000);
        vScrDbOwner PCS.PC_SCRIP.SCRDBOWNER%type;
        vScrDblink  PCS.PC_SCRIP.SCRDB_LINK%type;
        vComName    PCS.PC_COMP.COM_NAME%type;
      begin
        vComName  :=
                ACI_LOGISTIC_DOCUMENT.getFinancialCompany(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID);

        if vComName is not null then
          PCS.PC_FUNCTIONS.GetCompanyOwner(vComName, vScrDbOwner, vScrDblink);

          if vScrDblink is not null then
            vScrDblink  := '@' || vScrDblink;
          end if;
        else
          vScrDbOwner  := PCS.PC_I_LIB_SESSION.GetCompanyOwner;
        end if;

        vSql      :=
          'insert into [COMPANY_OWNER2].ACT_DOC_RECEIPT@[DB_LINK]' ||
          '(ACT_DOC_RECEIPT_ID' ||
          ', ACT_DOCUMENT_ID' ||
          ', DOC_DOCUMENT_ID' ||
          ', A_DATECRE' ||
          ', A_IDCRE' ||
          ' )' ||
          'values ([COMPANY_OWNER2].INIT_ID_SEQ@[DB_LINK].nextval' ||
          ', :ACT_DOCUMENT_ID' ||
          ', :DOC_DOCUMENT_ID' ||
          ', sysdate' ||
          ', :A_IDCRE' ||
          ')';
        vSql      := replace(vSql, '[COMPANY_OWNER2]', vScrDbOwner);
        vSql      := replace(vSql, '@[DB_LINK]', vScrDbLink);

        execute immediate vSql
                    using DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID
                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID
                        , PCS.PC_I_LIB_SESSION.GetUserIni;
      end;
    end if;

    -- ID du document créé
    aNewDocumentID                                                  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID;

    -- Copie des remises/taxes/frais de pied
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FOOT_CHARGE = 1 then
      DOC_DISCOUNT_CHARGE.DuplicateFootCharge(aSrcDocumentID, aNewDocumentID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.FROZE_COPY_FOOT_CHARGE);
    end if;

    -- Générateur de document, création des données libres depuis les données de DOC_INTERFACE_FREE_DATA
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID is not null then
      declare
        lInterfaceFreeData integer;
      begin
        -- Vérifier s'il y a des données dans la table DOC_INTERFACE_FREE_DATA
        select sign(count(*) )
          into lInterfaceFreeData
          from DOC_INTERFACE_FREE_DATA
         where DOC_INTERFACE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID;

        if lInterfaceFreeData = 1 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_FREE_DATA  := 0;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FREE_DATA    := 0;
          -- Création des données libres en reprenant les données figurant dans la table DOC_INTERFACE_FREE_DATA
          DOC_FREE_DATA_FUNCTIONS.CreateInterfaceFreeData(iDocumentID    => aNewDocumentID
                                                        , iInterfaceID   => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID);
        end if;
      end;
    end if;

    -- Création des données libres
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_FREE_DATA = 1 then
      DOC_FREE_DATA_FUNCTIONS.CreateFreeData(aNewDocumentID);
    end if;

    -- Copie des données libres
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FREE_DATA = 1 then
      DOC_FREE_DATA_FUNCTIONS.DuplicateFreeData(aSrcDocumentID, aNewDocumentID);
    end if;

    -- Création du Commissionement
    DOC_COMMISSION_FUNCTIONS.GenerateCommissioning(aNewDocumentID, aSrcDocumentID);
    -- Effacer le record des informations du document
    ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
  exception
    when others then
      -- Si le document n'est pas crée il faut libérer le N° de document de la table des numéros libres
      if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER is not null)
         and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID is not null) then
        declare
          lnDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
        begin
          -- Vérifier si le document existe
          select max(DOC_DOCUMENT_ID)
            into lnDocumentID
            from DOC_DOCUMENT
           where DOC_DOCUMENT_ID = aNewDocumentID;

          -- Libérer le n° de document
          if (lnDocumentID is null) then
            DOC_I_PRC_DOCUMENT_NUMBER.AddFreeNumber_AutoTrans(iNumber    => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER
                                                            , iGaugeID   => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                             );
          end if;
        end;
      end if;

      -- Effacer le record des informations du document
      ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
      PCS.RA(sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, null, -20900);
  end GenerateDocument;

  /*
  *  Insertion des données dans la table DOC_DOCUMENT
  **/
  procedure InsertDocument(aDocumentInfo in out DOC_DOCUMENT_INITIALIZE.TDocumentInfo)
  is
    ltCRUD_DEF  FWK_I_TYP_DEFINITION.t_crud_def;
    lDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type   := nvl(aDocumentInfo.DOC_DOCUMENT_ID, GetNewId);
  begin
    /*
     *  DOC_DOCUMENT
     */
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocDocument, iot_crud_definition => ltCRUD_DEF, ib_initialize => true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_DOCUMENT_ID', lDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_GAUGE_ID', aDocumentInfo.DOC_GAUGE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_NUMBER', aDocumentInfo.DMT_NUMBER);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_DOCUMENT', aDocumentInfo.DMT_DATE_DOCUMENT);

    if aDocumentInfo.DOC_DOCUMENT_SRC_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_DOCUMENT_SRC_ID', aDocumentInfo.DOC_DOCUMENT_SRC_ID);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_DOCUMENT_STATUS', aDocumentInfo.C_DOCUMENT_STATUS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_GAUGE_TYPE_DOC_ID', aDocumentInfo.DIC_GAUGE_TYPE_DOC_ID);

    if aDocumentInfo.USE_PAC_THIRD_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_ID', aDocumentInfo.PAC_THIRD_ID);
    end if;

    if aDocumentInfo.USE_PAC_THIRD_ACI_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_ACI_ID', aDocumentInfo.PAC_THIRD_ACI_ID);
    end if;

    if aDocumentInfo.USE_PAC_THIRD_DELIVERY_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_DELIVERY_ID', aDocumentInfo.PAC_THIRD_DELIVERY_ID);
    end if;

    if aDocumentInfo.USE_PAC_THIRD_TARIFF_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_TARIFF_ID', aDocumentInfo.PAC_THIRD_TARIFF_ID);
    end if;

    if aDocumentInfo.USE_PAC_THIRD_TARIFF_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_TARIFF_ID', aDocumentInfo.PAC_THIRD_TARIFF_ID);
    end if;

    if aDocumentInfo.DMT_PROTECTED is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PROTECTED', aDocumentInfo.DMT_PROTECTED);
    end if;

    if aDocumentInfo.C_DOC_CREATE_MODE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_DOC_CREATE_MODE', aDocumentInfo.C_DOC_CREATE_MODE);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                    , 'C_DOC_CREATE_MODE'
                                    , case aDocumentInfo.CREATE_TYPE
                                        when 'INSERT' then '910'
                                        when 'COPY' then '920'
                                        when 'DISCHARGE' then '930'
                                        else '999'
                                      end
                                     );
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DISCHARGE_FOOT_CHARGE', aDocumentInfo.DMT_DISCHARGE_FOOT_CHARGE);

    if aDocumentInfo.USE_DOC_CURRENCY = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_CURRENCY_ID', aDocumentInfo.ACS_FINANCIAL_CURRENCY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_BASE_PRICE', aDocumentInfo.DMT_BASE_PRICE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_RATE_OF_EXCHANGE', aDocumentInfo.DMT_RATE_OF_EXCHANGE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_RATE_EURO', aDocumentInfo.DMT_RATE_EURO);
    end if;

    if aDocumentInfo.USE_VAT_CURRENCY = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ACS_FINANCIAL_CURRENCY_ID', aDocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_VAT_BASE_PRICE', aDocumentInfo.DMT_VAT_BASE_PRICE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_VAT_EXCHANGE_RATE', aDocumentInfo.DMT_VAT_EXCHANGE_RATE);
    end if;

    if aDocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_VAT_DET_ACCOUNT_ID', aDocumentInfo.ACS_VAT_DET_ACCOUNT_ID);
    end if;

    if aDocumentInfo.USE_DIC_TYPE_SUBMISSION_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_TYPE_SUBMISSION_ID', aDocumentInfo.DIC_TYPE_SUBMISSION_ID);
    end if;

    if aDocumentInfo.USE_PC_LANG_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_LANG_ID', aDocumentInfo.PC_LANG_ID);
    end if;

    if aDocumentInfo.USE_PC_LANG_ACI_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_LANG_ACI_ID', aDocumentInfo.PC_LANG_ACI_ID);
    end if;

    if aDocumentInfo.USE_PC_LANG_DELIVERY_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_LANG_DELIVERY_ID', aDocumentInfo.PC_LANG_DELIVERY_ID);
    end if;

    if aDocumentInfo.USE_DOC_RECORD_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_RECORD_ID', aDocumentInfo.DOC_RECORD_ID);
    end if;

    if aDocumentInfo.USE_ACCOUNTS = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_ACCOUNT_ID', aDocumentInfo.ACS_FINANCIAL_ACCOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_DIVISION_ACCOUNT_ID', aDocumentInfo.ACS_DIVISION_ACCOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_CPN_ACCOUNT_ID', aDocumentInfo.ACS_CPN_ACCOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_PF_ACCOUNT_ID', aDocumentInfo.ACS_PF_ACCOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_PJ_ACCOUNT_ID', aDocumentInfo.ACS_PJ_ACCOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_CDA_ACCOUNT_ID', aDocumentInfo.ACS_CDA_ACCOUNT_ID);
    end if;

    if aDocumentInfo.USE_ADDRESS_1 = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_ADDRESS_ID', aDocumentInfo.PAC_ADDRESS_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDRESS1', aDocumentInfo.DMT_ADDRESS1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_POSTCODE1', aDocumentInfo.DMT_POSTCODE1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_TOWN1', aDocumentInfo.DMT_TOWN1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_STATE1', aDocumentInfo.DMT_STATE1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_CNTRY_ID', aDocumentInfo.PC_CNTRY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_FORMAT_CITY1', aDocumentInfo.DMT_FORMAT_CITY1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_NAME1', aDocumentInfo.DMT_NAME1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_FORENAME1', aDocumentInfo.DMT_FORENAME1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ACTIVITY1', aDocumentInfo.DMT_ACTIVITY1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_CARE_OF1', aDocumentInfo.DMT_CARE_OF1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PO_BOX1', aDocumentInfo.DMT_PO_BOX1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PO_BOX_NBR1', aDocumentInfo.DMT_PO_BOX_NBR1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_COUNTY1', aDocumentInfo.DMT_COUNTY1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_CONTACT1', aDocumentInfo.DMT_CONTACT1);
    end if;

    if aDocumentInfo.USE_ADDRESS_2 = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_PAC_ADDRESS_ID', aDocumentInfo.PAC_PAC_ADDRESS_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDRESS2', aDocumentInfo.DMT_ADDRESS2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_POSTCODE2', aDocumentInfo.DMT_POSTCODE2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_TOWN2', aDocumentInfo.DMT_TOWN2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_STATE2', aDocumentInfo.DMT_STATE2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC__PC_CNTRY_ID', aDocumentInfo.PC__PC_CNTRY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_FORMAT_CITY2', aDocumentInfo.DMT_FORMAT_CITY2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_NAME2', aDocumentInfo.DMT_NAME2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_FORENAME2', aDocumentInfo.DMT_FORENAME2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ACTIVITY2', aDocumentInfo.DMT_ACTIVITY2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_CARE_OF2', aDocumentInfo.DMT_CARE_OF2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PO_BOX2', aDocumentInfo.DMT_PO_BOX2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PO_BOX_NBR2', aDocumentInfo.DMT_PO_BOX_NBR2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_COUNTY2', aDocumentInfo.DMT_COUNTY2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_CONTACT2', aDocumentInfo.DMT_CONTACT2);
    end if;

    if aDocumentInfo.USE_ADDRESS_3 = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC2_PAC_ADDRESS_ID', aDocumentInfo.PAC2_PAC_ADDRESS_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDRESS3', aDocumentInfo.DMT_ADDRESS3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_POSTCODE3', aDocumentInfo.DMT_POSTCODE3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_TOWN3', aDocumentInfo.DMT_TOWN3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_STATE3', aDocumentInfo.DMT_STATE3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_2_PC_CNTRY_ID', aDocumentInfo.PC_2_PC_CNTRY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_FORMAT_CITY3', aDocumentInfo.DMT_FORMAT_CITY3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_NAME3', aDocumentInfo.DMT_NAME3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_FORENAME3', aDocumentInfo.DMT_FORENAME3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ACTIVITY3', aDocumentInfo.DMT_ACTIVITY3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_CARE_OF3', aDocumentInfo.DMT_CARE_OF3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PO_BOX3', aDocumentInfo.DMT_PO_BOX3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PO_BOX_NBR3', aDocumentInfo.DMT_PO_BOX_NBR3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_COUNTY3', aDocumentInfo.DMT_COUNTY3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_CONTACT3', aDocumentInfo.DMT_CONTACT3);
    end if;

    if aDocumentInfo.USE_DMT_TITLE_TEXT = 1 then
      if aDocumentInfo.PC__PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC__PC_APPLTXT_ID', aDocumentInfo.PC__PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.DMT_TITLE_TEXT is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_TITLE_TEXT', aDocumentInfo.DMT_TITLE_TEXT);
      end if;
    end if;

    if aDocumentInfo.USE_DMT_HEADING_TEXT = 1 then
      if aDocumentInfo.PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_APPLTXT_ID', aDocumentInfo.PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.DMT_HEADING_TEXT is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_HEADING_TEXT', aDocumentInfo.DMT_HEADING_TEXT);
      end if;
    end if;

    if aDocumentInfo.USE_DMT_DOCUMENT_TEXT = 1 then
      if aDocumentInfo.PC_2_PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_2_PC_APPLTXT_ID', aDocumentInfo.PC_2_PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.DMT_DOCUMENT_TEXT is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DOCUMENT_TEXT', aDocumentInfo.DMT_DOCUMENT_TEXT);
      end if;
    end if;

    if aDocumentInfo.USE_PAC_REPRESENTATIVE_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_REPRESENTATIVE_ID', aDocumentInfo.PAC_REPRESENTATIVE_ID);
    end if;

    if aDocumentInfo.USE_PAC_REPR_ACI_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_REPR_ACI_ID', aDocumentInfo.PAC_REPR_ACI_ID);
    end if;

    if aDocumentInfo.USE_PAC_REPR_DELIVERY_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_REPR_DELIVERY_ID', aDocumentInfo.PAC_REPR_DELIVERY_ID);
    end if;

    if aDocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_FINANCIAL_REFERENCE_ID', aDocumentInfo.PAC_FINANCIAL_REFERENCE_ID);
    end if;

    if aDocumentInfo.USE_DIC_TARIFF_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_TARIFF_ID', aDocumentInfo.DIC_TARIFF_ID);
    end if;

    if aDocumentInfo.USE_PAC_PAYMENT_CONDITION_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_PAYMENT_CONDITION_ID', aDocumentInfo.PAC_PAYMENT_CONDITION_ID);
    end if;

    if aDocumentInfo.USE_PAC_SENDING_CONDITION_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_SENDING_CONDITION_ID', aDocumentInfo.PAC_SENDING_CONDITION_ID);
    end if;

    if aDocumentInfo.USE_INCOTERMS = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_INCOTERMS', aDocumentInfo.C_INCOTERMS);

      if aDocumentInfo.DMT_INCOTERMS_PLACE is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_INCOTERMS_PLACE', aDocumentInfo.DMT_INCOTERMS_PLACE);
      end if;
    end if;

    if aDocumentInfo.USE_PAC_DIST_CHANNEL_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_DISTRIBUTION_CHANNEL_ID', aDocumentInfo.PAC_DISTRIBUTION_CHANNEL_ID);
    end if;

    if aDocumentInfo.USE_PAC_SALE_TERRITORY_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_SALE_TERRITORY_ID', aDocumentInfo.PAC_SALE_TERRITORY_ID);
    end if;

    if aDocumentInfo.USE_ACS_FIN_ACC_S_PAYMENT_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FIN_ACC_S_PAYMENT_ID', aDocumentInfo.ACS_FIN_ACC_S_PAYMENT_ID);
    end if;

    if aDocumentInfo.USE_DMT_DATE_DELIVERY = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_DELIVERY', aDocumentInfo.DMT_DATE_DELIVERY);
    end if;

    if aDocumentInfo.USE_DMT_DATE_VALUE = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_VALUE', aDocumentInfo.DMT_DATE_VALUE);
    end if;

    if aDocumentInfo.USE_DMT_DATE_FALLING_DUE = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_FALLING_DUE', aDocumentInfo.DMT_DATE_FALLING_DUE);
    end if;

    if aDocumentInfo.USE_DMT_RATE_FACTOR = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_RATE_FACTOR', aDocumentInfo.DMT_RATE_FACTOR);
    end if;

    if aDocumentInfo.USE_C_DMT_DELIVERY_TYP = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_DMT_DELIVERY_TYP', aDocumentInfo.C_DMT_DELIVERY_TYP);
    end if;

    if aDocumentInfo.USE_PRE_ENTRY = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PRE_ENTRY', aDocumentInfo.DMT_PRE_ENTRY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACT_DOCUMENT_ID', aDocumentInfo.ACT_DOCUMENT_ID);
    end if;

    if aDocumentInfo.USE_CML_POSITION_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CML_POSITION_ID', aDocumentInfo.CML_POSITION_ID);
    end if;

    if aDocumentInfo.USE_CML_INVOICING_JOB_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CML_INVOICING_JOB_ID', aDocumentInfo.CML_INVOICING_JOB_ID);
    end if;

    if aDocumentInfo.USE_ASA_RECORD_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_ID', aDocumentInfo.ASA_RECORD_ID);
    end if;

    if aDocumentInfo.USE_DMT_DOI_NUMBER = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DOI_NUMBER', aDocumentInfo.DMT_DOI_NUMBER);
    end if;

    if aDocumentInfo.USE_DMT_PARTNER_NUMBER = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PARTNER_NUMBER', aDocumentInfo.DMT_PARTNER_NUMBER);
    end if;

    if aDocumentInfo.USE_DMT_PARTNER_REFERENCE = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_PARTNER_REFERENCE', aDocumentInfo.DMT_PARTNER_REFERENCE);
    end if;

    if aDocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_PARTNER_DOCUMENT', aDocumentInfo.DMT_DATE_PARTNER_DOCUMENT);
    end if;

    if aDocumentInfo.USE_DMT_REFERENCE = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_REFERENCE', aDocumentInfo.DMT_REFERENCE);
    end if;

    if aDocumentInfo.USE_GAUGE_FREE_DATA = 1 then
      if aDocumentInfo.DIC_GAUGE_FREE_CODE_1_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_GAUGE_FREE_CODE_1_ID', aDocumentInfo.DIC_GAUGE_FREE_CODE_1_ID);
      end if;

      if aDocumentInfo.DIC_GAUGE_FREE_CODE_2_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_GAUGE_FREE_CODE_2_ID', aDocumentInfo.DIC_GAUGE_FREE_CODE_2_ID);
      end if;

      if aDocumentInfo.DIC_GAUGE_FREE_CODE_3_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_GAUGE_FREE_CODE_3_ID', aDocumentInfo.DIC_GAUGE_FREE_CODE_3_ID);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_NUMBER1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_NUMBER1', aDocumentInfo.DMT_GAU_FREE_NUMBER1);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_NUMBER2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_NUMBER2', aDocumentInfo.DMT_GAU_FREE_NUMBER2);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_DATE1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_DATE1', aDocumentInfo.DMT_GAU_FREE_DATE1);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_DATE2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_DATE2', aDocumentInfo.DMT_GAU_FREE_DATE2);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_BOOL1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_BOOL1', aDocumentInfo.DMT_GAU_FREE_BOOL1);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_BOOL2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_BOOL2', aDocumentInfo.DMT_GAU_FREE_BOOL2);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_TEXT_LONG is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_TEXT_LONG', aDocumentInfo.DMT_GAU_FREE_TEXT_LONG);
      end if;

      if aDocumentInfo.DMT_GAU_FREE_TEXT_SHORT is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_GAU_FREE_TEXT_SHORT', aDocumentInfo.DMT_GAU_FREE_TEXT_SHORT);
      end if;
    end if;

    if aDocumentInfo.USE_DIC_POS_FREE_TABLE = 1 then
      if aDocumentInfo.DIC_POS_FREE_TABLE_1_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_POS_FREE_TABLE_1_ID', aDocumentInfo.DIC_POS_FREE_TABLE_1_ID);
      end if;

      if aDocumentInfo.DIC_POS_FREE_TABLE_2_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_POS_FREE_TABLE_2_ID', aDocumentInfo.DIC_POS_FREE_TABLE_2_ID);
      end if;

      if aDocumentInfo.DIC_POS_FREE_TABLE_3_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_POS_FREE_TABLE_3_ID', aDocumentInfo.DIC_POS_FREE_TABLE_3_ID);
      end if;
    end if;

    if aDocumentInfo.USE_DMT_TEXT = 1 then
      if aDocumentInfo.DMT_TEXT_1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_TEXT_1', aDocumentInfo.DMT_TEXT_1);
      end if;

      if aDocumentInfo.DMT_TEXT_2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_TEXT_2', aDocumentInfo.DMT_TEXT_2);
      end if;

      if aDocumentInfo.DMT_TEXT_3 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_TEXT_3', aDocumentInfo.DMT_TEXT_3);
      end if;
    end if;

    if aDocumentInfo.USE_DMT_DECIMAL = 1 then
      if aDocumentInfo.DMT_DECIMAL_1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DECIMAL_1', aDocumentInfo.DMT_DECIMAL_1);
      end if;

      if aDocumentInfo.DMT_DECIMAL_2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DECIMAL_2', aDocumentInfo.DMT_DECIMAL_2);
      end if;

      if aDocumentInfo.DMT_DECIMAL_3 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DECIMAL_3', aDocumentInfo.DMT_DECIMAL_3);
      end if;
    end if;

    if aDocumentInfo.USE_DMT_DATE = 1 then
      if aDocumentInfo.DMT_DATE_1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_1', aDocumentInfo.DMT_DATE_1);
      end if;

      if aDocumentInfo.DMT_DATE_2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_2', aDocumentInfo.DMT_DATE_2);
      end if;

      if aDocumentInfo.DMT_DATE_3 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_3', aDocumentInfo.DMT_DATE_3);
      end if;
    end if;

    if aDocumentInfo.USE_FIN_DOC_BLOCKED = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_FIN_DOC_BLOCKED', aDocumentInfo.DMT_FIN_DOC_BLOCKED);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_BLOCKED_REASON_ID', aDocumentInfo.DIC_BLOCKED_REASON_ID);
    end if;

    if aDocumentInfo.USE_DOC_GRP_KEY = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_GRP_KEY', aDocumentInfo.DOC_GRP_KEY);
    end if;

    if aDocumentInfo.COM_NAME_ACI is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'COM_NAME_ACI', aDocumentInfo.COM_NAME_ACI);
    end if;

    if aDocumentInfo.PAC_THIRD_CDA_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_CDA_ID', aDocumentInfo.PAC_THIRD_CDA_ID);
    end if;

    if aDocumentInfo.PAC_THIRD_VAT_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_VAT_ID', aDocumentInfo.PAC_THIRD_VAT_ID);
    end if;

    if aDocumentInfo.C_GAU_THIRD_VAT is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_GAU_THIRD_VAT', aDocumentInfo.C_GAU_THIRD_VAT);
    end if;

    if aDocumentInfo.USE_ADDENDUM = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDENDUM_OF_DOC_ID', aDocumentInfo.DMT_ADDENDUM_OF_DOC_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDENDUM_SRC_DOC_ID', aDocumentInfo.DMT_ADDENDUM_SRC_DOC_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDENDUM_INDEX', aDocumentInfo.DMT_ADDENDUM_INDEX);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDENDUM_NUMBER', aDocumentInfo.DMT_ADDENDUM_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_ADDENDUM_COMMENT', aDocumentInfo.DMT_ADDENDUM_COMMENT);
    end if;

    if aDocumentInfo.PAC_EBPP_REFERENCE_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_EBPP_REFERENCE_ID', aDocumentInfo.PAC_EBPP_REFERENCE_ID);
    end if;

    if aDocumentInfo.PC_EXCHANGE_SYSTEM_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_EXCHANGE_SYSTEM_ID', aDocumentInfo.PC_EXCHANGE_SYSTEM_ID);
    end if;

    if aDocumentInfo.C_THIRD_MATERIAL_RELATION_TYPE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_THIRD_MATERIAL_RELATION_TYPE', aDocumentInfo.C_THIRD_MATERIAL_RELATION_TYPE);
    end if;

    if aDocumentInfo.USE_EXCHANGE_DATA_IN = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_EXCHANGE_DATA_IN_ID', aDocumentInfo.PC_EXCHANGE_DATA_IN_ID);
    end if;

    if aDocumentInfo.DOC_ESTIMATE_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_ESTIMATE_ID', aDocumentInfo.DOC_ESTIMATE_ID);
    end if;

    if aDocumentInfo.DOC_INVOICE_EXPIRY_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_INVOICE_EXPIRY_ID', aDocumentInfo.DOC_INVOICE_EXPIRY_ID);
    end if;

    if aDocumentInfo.USE_A_DATEMOD = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', aDocumentInfo.A_DATEMOD);
    end if;

    if aDocumentInfo.USE_A_IDMOD = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', aDocumentInfo.A_IDMOD);
    end if;

    if aDocumentInfo.USE_A_RECLEVEL = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_RECLEVEL', aDocumentInfo.A_RECLEVEL);
    end if;

    if aDocumentInfo.USE_A_RECSTATUS = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_RECSTATUS', aDocumentInfo.A_RECSTATUS);
    end if;

    if aDocumentInfo.USE_A_CONFIRM = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_CONFIRM', aDocumentInfo.A_CONFIRM);
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    /*
     *  DOC_FOOT
     */
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocFoot, iot_crud_definition => ltCRUD_DEF, ib_initialize => true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_FOOT_ID', lDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_DOCUMENT_ID', lDocumentId);

    if aDocumentInfo.USE_C_BVR_GENERATION_METHOD = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_BVR_GENERATION_METHOD', aDocumentInfo.C_BVR_GENERATION_METHOD);
    end if;

    if aDocumentInfo.USE_FOO_PAID_AMOUNT = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_PAID_AMOUNT', aDocumentInfo.FOO_PAID_AMOUNT);
    end if;

    if aDocumentInfo.USE_FOO_RETURN_AMOUNT = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_RETURN_AMOUNT', aDocumentInfo.FOO_RETURN_AMOUNT);
    end if;

    if aDocumentInfo.USE_DOC_GAUGE_SIGNATORY_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_GAUGE_SIGNATORY_ID', aDocumentInfo.DOC_GAUGE_SIGNATORY_ID);
    end if;

    if aDocumentInfo.USE_DOC_DOC_GAUGE_SIGNATORY_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_DOC_GAUGE_SIGNATORY_ID', aDocumentInfo.DOC_DOC_GAUGE_SIGNATORY_ID);
    end if;

    if aDocumentInfo.USE_DIC_TYPE_DOC_CUSTOM_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_TYPE_DOC_CUSTOM_ID', aDocumentInfo.DIC_TYPE_DOC_CUSTOM_ID);
    end if;

    if aDocumentInfo.USE_C_DIRECTION_NUMBER = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_DIRECTION_NUMBER', aDocumentInfo.C_DIRECTION_NUMBER);
    end if;

    if aDocumentInfo.USE_ACJ_JOB_TYPE_S_CAT_PMT_ID = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACJ_JOB_TYPE_S_CAT_PMT_ID', aDocumentInfo.ACJ_JOB_TYPE_S_CAT_PMT_ID);
    end if;

    if aDocumentInfo.USE_FOO_FOOT_TEXT = 1 then
      if aDocumentInfo.FOOT_PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_APPLTXT_ID', aDocumentInfo.FOOT_PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.FOO_FOOT_TEXT is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_FOOT_TEXT', aDocumentInfo.FOO_FOOT_TEXT);
      end if;
    end if;

    if aDocumentInfo.USE_FOO_FOOT_TEXT2 = 1 then
      if aDocumentInfo.FOOT_PC__PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC__PC_APPLTXT_ID', aDocumentInfo.FOOT_PC__PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.FOO_FOOT_TEXT2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_FOOT_TEXT2', aDocumentInfo.FOO_FOOT_TEXT2);
      end if;
    end if;

    if aDocumentInfo.USE_FOO_FOOT_TEXT3 = 1 then
      if aDocumentInfo.FOOT_PC_2_PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_2_PC_APPLTXT_ID', aDocumentInfo.FOOT_PC_2_PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.FOO_FOOT_TEXT3 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_FOOT_TEXT3', aDocumentInfo.FOO_FOOT_TEXT3);
      end if;
    end if;

    if aDocumentInfo.USE_FOO_FOOT_TEXT4 = 1 then
      if aDocumentInfo.FOOT_PC_3_PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_3_PC_APPLTXT_ID', aDocumentInfo.FOOT_PC_3_PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.FOO_FOOT_TEXT4 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_FOOT_TEXT4', aDocumentInfo.FOO_FOOT_TEXT4);
      end if;
    end if;

    if aDocumentInfo.USE_FOO_FOOT_TEXT5 = 1 then
      if aDocumentInfo.FOOT_PC_4_PC_APPLTXT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_4_PC_APPLTXT_ID', aDocumentInfo.FOOT_PC_4_PC_APPLTXT_ID);
      end if;

      if aDocumentInfo.FOO_FOOT_TEXT5 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_FOOT_TEXT5', aDocumentInfo.FOO_FOOT_TEXT5);
      end if;
    end if;

    if aDocumentInfo.USE_FOO_REF_BVR_NUMBER = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_REF_BVR_NUMBER', aDocumentInfo.FOO_REF_BVR_NUMBER);
    end if;

    if aDocumentInfo.USE_FOO_PACKAGING = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_PACKAGING', aDocumentInfo.FOO_PACKAGING);
    end if;

    if aDocumentInfo.USE_FOO_MARKING = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_MARKING', aDocumentInfo.FOO_MARKING);
    end if;

    if aDocumentInfo.USE_FOO_MEASURE = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_MEASURE', aDocumentInfo.FOO_MEASURE);
    end if;

    if aDocumentInfo.USE_FOO_TOTAL_WEIGHT_MEAS = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_TOTAL_GROSS_WEIGHT_MEAS', aDocumentInfo.FOO_TOTAL_GROSS_WEIGHT_MEAS);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_TOTAL_NET_WEIGHT_MEAS', aDocumentInfo.FOO_TOTAL_NET_WEIGHT_MEAS);
    end if;

    if aDocumentInfo.USE_FOO_TOTAL_WEIGHT = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_TOTAL_NET_WEIGHT', aDocumentInfo.FOO_TOTAL_NET_WEIGHT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FOO_TOTAL_GROSS_WEIGHT', aDocumentInfo.FOO_TOTAL_GROSS_WEIGHT);
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);

--     insert into DOC_FOOT
--                 (DOC_FOOT_ID
--                , DOC_DOCUMENT_ID
--                , C_BVR_GENERATION_METHOD
--                , FOO_PAID_AMOUNT
--                , FOO_RETURN_AMOUNT
--                , DOC_GAUGE_SIGNATORY_ID
--                , DOC_DOC_GAUGE_SIGNATORY_ID
--                , DIC_TYPE_DOC_CUSTOM_ID
--                , C_DIRECTION_NUMBER
--                , ACJ_JOB_TYPE_S_CAT_PMT_ID
--                , PC_APPLTXT_ID
--                , FOO_FOOT_TEXT
--                , PC__PC_APPLTXT_ID
--                , FOO_FOOT_TEXT2
--                , PC_2_PC_APPLTXT_ID
--                , FOO_FOOT_TEXT3
--                , PC_3_PC_APPLTXT_ID
--                , FOO_FOOT_TEXT4
--                , PC_4_PC_APPLTXT_ID
--                , FOO_FOOT_TEXT5
--                , FOO_REF_BVR_NUMBER
--                , FOO_PACKAGING
--                , FOO_MARKING
--                , FOO_MEASURE
--                , FOO_TOTAL_GROSS_WEIGHT_MEAS
--                , FOO_TOTAL_NET_WEIGHT_MEAS
--                , A_IDCRE
--                , A_DATECRE
--                 )
--       select aDocumentInfo.DOC_DOCUMENT_ID
--            , aDocumentInfo.DOC_DOCUMENT_ID
--            , aDocumentInfo.C_BVR_GENERATION_METHOD
--            , aDocumentInfo.FOO_PAID_AMOUNT
--            , aDocumentInfo.FOO_RETURN_AMOUNT
--            , aDocumentInfo.DOC_GAUGE_SIGNATORY_ID
--            , aDocumentInfo.DOC_DOC_GAUGE_SIGNATORY_ID
--            , aDocumentInfo.DIC_TYPE_DOC_CUSTOM_ID
--            , aDocumentInfo.C_DIRECTION_NUMBER
--            , aDocumentInfo.ACJ_JOB_TYPE_S_CAT_PMT_ID
--            , aDocumentInfo.FOOT_PC_APPLTXT_ID
--            , aDocumentInfo.FOO_FOOT_TEXT
--            , aDocumentInfo.FOOT_PC__PC_APPLTXT_ID
--            , aDocumentInfo.FOO_FOOT_TEXT2
--            , aDocumentInfo.FOOT_PC_2_PC_APPLTXT_ID
--            , aDocumentInfo.FOO_FOOT_TEXT3
--            , aDocumentInfo.FOOT_PC_3_PC_APPLTXT_ID
--            , aDocumentInfo.FOO_FOOT_TEXT4
--            , aDocumentInfo.FOOT_PC_4_PC_APPLTXT_ID
--            , aDocumentInfo.FOO_FOOT_TEXT5
--            , aDocumentInfo.FOO_REF_BVR_NUMBER
--            , aDocumentInfo.FOO_PACKAGING
--            , aDocumentInfo.FOO_MARKING
--            , aDocumentInfo.FOO_MEASURE
--            , aDocumentInfo.FOO_TOTAL_GROSS_WEIGHT_MEAS
--            , aDocumentInfo.FOO_TOTAL_NET_WEIGHT_MEAS
--            , aDocumentInfo.A_IDCRE
--            , aDocumentInfo.A_DATECRE
--         from dual;
    if substr(aDocumentInfo.C_DOC_CREATE_MODE, 1, 1) in(2, 3) then
      declare
        lSrcGaugeID       DOC_GAUGE.DOC_GAUGE_ID%type;
        lFlowID           DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
        lnTrsfLinkedFiles DOC_GAUGE_RECEIPT.GAR_DOC_TRSF_LINKED_FILES%type;
      begin
        lnTrsfLinkedFiles  := 0;

        -- Rechercher le gabarit du document source ainsi que l'éventuel flux
        select max(DMT.DOC_GAUGE_ID)
             , max(PDE.DOC_GAUGE_FLOW_ID)
          into lSrcGaugeID
             , lFlowID
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
         where DMT.DOC_DOCUMENT_ID = aDocumentInfo.DOC_DOCUMENT_SRC_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID;

        -- Copie
        if (substr(aDocumentInfo.C_DOC_CREATE_MODE, 1, 1) = 2) then
          lnTrsfLinkedFiles  :=
            DOC_I_LIB_GAUGE.GetGaugeCopyFlag(iCopyID      => DOC_I_LIB_GAUGE.GetGaugeCopyID(iSourceGaugeId   => lSrcGaugeID
                                                                                          , iTargetGaugeId   => aDocumentInfo.DOC_GAUGE_ID
                                                                                          , iThirdID         => aDocumentInfo.PAC_THIRD_ID
                                                                                          , iFlowID          => lFlowID
                                                                                           )
                                           , iFieldName   => 'GAC_DOC_TRSF_LINKED_FILES'
                                            );
        -- Décharge
        elsif(substr(aDocumentInfo.C_DOC_CREATE_MODE, 1, 1) = 3) then
          lnTrsfLinkedFiles  :=
            DOC_I_LIB_GAUGE.GetGaugeReceiptFlag(iReceiptID   => DOC_I_LIB_GAUGE.GetGaugeReceiptID(iSourceGaugeId   => lSrcGaugeID
                                                                                                , iTargetGaugeId   => aDocumentInfo.DOC_GAUGE_ID
                                                                                                , iThirdID         => aDocumentInfo.PAC_THIRD_ID
                                                                                                , iFlowID          => lFlowID
                                                                                                 )
                                              , iFieldName   => 'GAR_DOC_TRSF_LINKED_FILES'
                                               );
        end if;

        if lnTrsfLinkedFiles = 1 then
          COM_FUNCTIONS.DuplicateImageFiles('DOC_DOCUMENT', aDocumentInfo.DOC_DOCUMENT_SRC_ID, aDocumentInfo.DOC_DOCUMENT_ID);
        end if;
      end;
    end if;
  end InsertDocument;

  /**
  *   Create foot with minimal informations if no foot exists
  */
  procedure GenerateMinimalFoot(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lFootId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select max(DOC_FOOT_ID)
      into lFootId
      from DOC_FOOT
     where DOC_FOOT_ID = iDocumentId;

    if lFootId is null then
      for ltplGauge in (select DMT.DOC_GAUGE_ID
                             , DMT.PAC_THIRD_ID
                             , DMT.PC_LANG_ID
                             , GAU.DOC_GAUGE_SIGNATORY_ID
                             , GAU.DOC_DOC_GAUGE_SIGNATORY_ID
                             , GAU.DIC_TYPE_DOC_CUSTOM_ID
                             , GAU.C_DIRECTION_NUMBER
                             , GAS.C_BVR_GENERATION_METHOD
                             , GAS.ACJ_JOB_TYPE_S_CAT_PMT_ID
                          from DOC_DOCUMENT DMT
                             , DOC_GAUGE GAU
                             , DOC_GAUGE_STRUCTURED GAS
                         where DMT.DOC_DOCUMENT_ID = iDocumentId
                           and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
                           and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID) loop
        insert into DOC_FOOT
                    (DOC_FOOT_ID
                   , DOC_DOCUMENT_ID
                   , FOO_FOOT_TEXT
                   , FOO_FOOT_TEXT2
                   , FOO_FOOT_TEXT3
                   , FOO_FOOT_TEXT4
                   , FOO_FOOT_TEXT5
                   , DOC_GAUGE_SIGNATORY_ID
                   , DOC_DOC_GAUGE_SIGNATORY_ID
                   , DIC_TYPE_DOC_CUSTOM_ID
                   , C_DIRECTION_NUMBER
                   , C_BVR_GENERATION_METHOD
                   , ACJ_JOB_TYPE_S_CAT_PMT_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (iDocumentId
                   , iDocumentId
                   , PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(1, ltplGauge.DOC_GAUGE_ID, ltplGauge.PAC_THIRD_ID)
                                                         , ltplGauge.PC_LANG_ID
                                                          )
                   , PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(2, ltplGauge.DOC_GAUGE_ID, ltplGauge.PAC_THIRD_ID)
                                                         , ltplGauge.PC_LANG_ID
                                                          )
                   , PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(3, ltplGauge.DOC_GAUGE_ID, ltplGauge.PAC_THIRD_ID)
                                                         , ltplGauge.PC_LANG_ID
                                                          )
                   , PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(4, ltplGauge.DOC_GAUGE_ID, ltplGauge.PAC_THIRD_ID)
                                                         , ltplGauge.PC_LANG_ID
                                                          )
                   , PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(5, ltplGauge.DOC_GAUGE_ID, ltplGauge.PAC_THIRD_ID)
                                                         , ltplGauge.PC_LANG_ID
                                                          )
                   , ltplGauge.DOC_GAUGE_SIGNATORY_ID
                   , ltplGauge.DOC_DOC_GAUGE_SIGNATORY_ID
                   , ltplGauge.DIC_TYPE_DOC_CUSTOM_ID
                   , ltplGauge.C_DIRECTION_NUMBER
                   , ltplGauge.C_BVR_GENERATION_METHOD
                   , ltplGauge.ACJ_JOB_TYPE_S_CAT_PMT_ID
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end loop;
    end if;
  end GenerateMinimalFoot;
end DOC_DOCUMENT_GENERATE;
