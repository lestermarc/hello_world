--------------------------------------------------------
--  DDL for Package Body DOC_RECORD_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_RECORD_MANAGEMENT" 
is
  /**
  * procedure pCreateRecordCategory
  * Description
  *   Création d'une catégorie de dossier
  * @created fp 24.09.2007
  * @lastUpdate
  * @private
  * @param aCategoryType : type de catégorie
  * @param aDescription  : description de la catégorie
  * @param aKey
  * @param aGoodNumberingId  : Id de numérotation
  */
  procedure pCreateRecordCategory(
    aCategoryType    DOC_RECORD_CATEGORY.C_RCO_TYPE%type
  , aDescription     DOC_RECORD_CATEGORY.RCY_DESCR%type
  , aKey             DOC_RECORD_CATEGORY.RCY_KEY%type
  , aGoodNumberingId DOC_RECORD_CATEGORY.GCO_GOOD_NUMBERING_ID%type default null
  )
  is
  begin
    insert into DOC_RECORD_CATEGORY
                (DOC_RECORD_CATEGORY_ID
               , C_RCO_STATUS
               , C_RCO_TYPE
               , GCO_GOOD_NUMBERING_ID
               , RCY_DESCR
               , RCY_KEY
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , '0'
               , aCategoryType
               , aGoodNumberingId
               , aDescription
               , aKey
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end pCreateRecordCategory;

  /**
  * Description
  *    Méthode de création d'un dossier, retourne l'id du dossier créé
  * @author SK
  * @lastupdate hto 19.11.2007
  * @private
  */
  function pGenerateNewRecord(
    aThirdId           DOC_DOCUMENT.PAC_THIRD_ID%type
  , aDocumentId        DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocNumber         DOC_DOCUMENT.DMT_NUMBER%type
  , aAutomaticCreation DOC_GAUGE.C_GAU_AUTO_CREATE_RECORD%type
  , aRcoType           DOC_RECORD.C_RCO_TYPE%type default null
  , aRecordCategoryId  DOC_RECORD.DOC_RECORD_ID%type default null
  )
    return DOC_DOCUMENT.DOC_RECORD_ID%type
  is
    vNewRecordId      DOC_RECORD.DOC_RECORD_ID%type;   --Variable récupérant le nouvel Id de dossier créé
    vRecordTittle     DOC_RECORD.RCO_TITLE%type;   --Variable récupérant le titre du dossier
    vRecordNumber     DOC_RECORD.RCO_NUMBER%type;   --Variable récupérant le n° de dossier
    vRecordCategoryId DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;   -- id de la catégorie
    vGoodNumberingId  GCO_GOOD_NUMBERING.GCO_GOOD_NUMBERING_ID%type;   -- type de numérotation automatiques
  begin
    select INIT_ID_SEQ.nextval
      into vNewRecordId
      from dual;

    vRecordCategoryId  := aRecordCategoryId;

    if vRecordCategoryId is not null then
      -- recherche si une numérotation automatique est associée à la catégorie du dossier
      select GCO_GOOD_NUMBERING_ID
        into vGoodNumberingId
        from DOC_RECORD_CATEGORY
       where DOC_RECORD_CATEGORY_ID = vRecordCategoryId;
    else
      vGoodNumberingId  := null;
    end if;

    if     aRcoType = '09'
       and vRecordCategoryId is null then
      begin
        select DOC_RECORD_CATEGORY_ID
          into vRecordCategoryId
          from DOC_RECORD_CATEGORY
         where C_RCO_TYPE = '09';
      exception
        when no_data_found then
          pCreateRecordCategory('09'
                              , PCS.PC_FUNCTIONS.TranslateWord('Commandes Affaires / Création automatique')
                              , PCS.PC_FUNCTIONS.TranslateWord('Commandes Affaires')
                               );
        when too_many_rows then
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                                ('PCS - Plus d''une catégorie de dossier de type ''09''! Vous devez avoir une et une seule catégorie de dossier de type ''09''.')
            );
      end;
    end if;

    if vGoodNumberingId is not null then   --or vGoodNumberingId != '' then
      -- appel de la fonction de numérotation automatique appropriée
      vRecordTittle  := GCO_GOOD_NUMBERING_FUNCTIONS.AutoNumbering(vGoodNumberingId, vNewRecordId);
    else
      if aAutomaticCreation = '1' then   --Le mode de création est 1
        vRecordTittle  := aDocNumber;   --   Le titre du dossier est initialisé avec le n° de document
      else   --Sinon le mode de création est forcément 2
        --Initialisation de la variable du n° de dossier
        select RCO_NUMBER_SEQ.nextval
          into vRecordNumber
          from dual;

        vRecordTittle  := vRecordNumber;   --   Le Titre du dossier est initialisé avec le n° de dossier
      end if;
    end if;

    --Insertion dans la base du nouveau Record
    if aRcoType is not null then
      insert into DOC_RECORD
                  (DOC_RECORD_ID
                 , DOC_RECORD_CATEGORY_ID
                 , PAC_THIRD_ID
                 , RCO_TITLE
                 , RCO_NUMBER
                 , C_RCO_TYPE
                 , DOC_PROJECT_DOCUMENT_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vNewRecordId
                 , vRecordCategoryId
                 , aThirdId
                 , decode(aRcoType, '09', '09_' || vRecordTittle, vRecordTittle)
                 , vRecordNumber
                 , aRcoType
                 , decode(aRcoType, '09', aDocumentId)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    else   -- si aRcoType est null, afin de prendre la valeur par défaut du champ C_RCO_TYPE
      insert into DOC_RECORD
                  (DOC_RECORD_ID
                 , DOC_RECORD_CATEGORY_ID
                 , PAC_THIRD_ID
                 , RCO_TITLE
                 , RCO_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vNewRecordId
                 , vRecordCategoryId
                 , aThirdId
                 , vRecordTittle
                 , vRecordNumber
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    return vNewRecordId;   --Retour du nouvel Id de dossier
  end;

  /**
  * Description
  *    Création automatique de dossier, retourne l'id du dossier créé
  */
  function CreateRecord(
    aGaugeId   DOC_DOCUMENT.DOC_RECORD_ID%type
  , aGaugeName DOC_GAUGE.GAU_DESCRIBE%type
  , aRecordId  DOC_DOCUMENT.DOC_RECORD_ID%type
  , aThirdId   DOC_DOCUMENT.PAC_THIRD_ID%type
  , aDocNumber DOC_DOCUMENT.DMT_NUMBER%type
  )
    return DOC_DOCUMENT.DOC_RECORD_ID%type
  is
    vLinkRecord number(1);
  begin
    return CreateRecord(aGaugeId, aGaugeName, aRecordId, aThirdId, aDocNumber, vLinkRecord);
  end CreateRecord;

  /**
  * Description
  *    Création automatique de dossier, retourne l'id du dossier créé
  */
  function CreateRecord(
    aGaugeId        DOC_DOCUMENT.DOC_RECORD_ID%type
  , aGaugeName      DOC_GAUGE.GAU_DESCRIBE%type
  , aRecordId       DOC_DOCUMENT.DOC_RECORD_ID%type
  , aThirdId        DOC_DOCUMENT.PAC_THIRD_ID%type
  , aDocNumber      DOC_DOCUMENT.DMT_NUMBER%type
  , aLinkRecord out number
  )
    return DOC_DOCUMENT.DOC_RECORD_ID%type
  is
  begin
    return CreateRecord(aGaugeId, aGaugeName, aRecordId, aThirdId, null, aDocNumber, aLinkRecord, null);
  end CreateRecord;

  /**
  * Description
  *    Création automatique de dossier, retourne l'id du dossier créé
  */
  function CreateRecord(
    aGaugeId              DOC_DOCUMENT.DOC_RECORD_ID%type
  , aGaugeName            DOC_GAUGE.GAU_DESCRIBE%type
  , aRecordId             DOC_DOCUMENT.DOC_RECORD_ID%type
  , aThirdId              DOC_DOCUMENT.PAC_THIRD_ID%type
  , aDocumentId           DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocNumber            DOC_DOCUMENT.DMT_NUMBER%type
  , aLinkRecord       out number
  , aRecordCategoryId     DOC_RECORD.DOC_RECORD_ID%type default null
  )
    return DOC_DOCUMENT.DOC_RECORD_ID%type
  is
    vRecordManagement  DOC_GAUGE.GAU_DOSSIER%type;   --Variable récupérant le champ DOC_GAUGE.GAU_DOSSIER (gestion dossier)
    vAutomaticCreation DOC_GAUGE.C_GAU_AUTO_CREATE_RECORD%type;   --Varaiable récupérant le mode de création du dossier
    vExistingRecordId  DOC_RECORD.DOC_RECORD_ID%type;   --Variable récupérant le dossier existant dont le titre égale le n° de document nouvellement créé
    vRcoType           DOC_RECORD.C_RCO_TYPE%type;
  begin
    vExistingRecordId  := -1;

    select decode(max(DOC_GAUGE_ID), null, null, '09')
         , decode(max(DOC_GAUGE_ID), null, 1, 0)
      into vRcoType
         , aLinkRecord
      from DOC_GAUGE
     where DOC_GAUGE_ID = aGaugeId
       and PCS.PC_CONFIG.GetConfig('GAL_PROJECT_MANAGEMENT') = '1'
       and checkList(GAU_DESCRIBE, PCS.PC_CONFIG.getConfig('GAL_GAUGE_BALANCE_ORDER') ) = 1;

    if    vRcoType = '09'
       or aRecordId is null then
      if aGaugeId <> 0 then   --Initialisation de la valeur de retour
        select GAU_DOSSIER
             , C_GAU_AUTO_CREATE_RECORD   --Récupération du flag "gestion dossier" et le mode de création
          into vRecordManagement
             , vAutomaticCreation   --du gabarit du document
          from DOC_GAUGE
         where DOC_GAUGE_ID = aGaugeId;
      else
        begin
          select GAU_DOSSIER
               , C_GAU_AUTO_CREATE_RECORD   --Récupération du flag "gestion dossier" et le mode de création
            into vRecordManagement
               , vAutomaticCreation   --du gabarit du document
            from DOC_GAUGE
           where GAU_DESCRIBE = aGaugeName;
        exception
          when no_data_found then
            raise_application_error(-20070, 'PCS - Mandatory configuration "DOC_CART_CONFIG_GAUGE" bad or not defined!');
        end;
      end if;

      if     vRecordManagement = 1
         and vAutomaticCreation in('1', '2') then   --Le gabarit gère les dossiers
        if vAutomaticCreation = '1' then   --Le mode de gestion est "Titre Dossier = N° Document"
          if vRcoType = '09' then
            select nvl(max(DOC_RECORD_ID), 0)
              into vExistingRecordId   --Récupère l'éventuel dossier déjà existant dont le titre = n° Document
              from DOC_RECORD
             where RCO_TITLE = '09_' || aDocNumber;
          else
            select nvl(max(DOC_RECORD_ID), 0)
              into vExistingRecordId   --Récupère l'éventuel dossier déjà existant dont le titre = n° Document
              from DOC_RECORD
             where RCO_TITLE = aDocNumber;
          end if;
        end if;

        if    vExistingRecordId = 0
           or vAutomaticCreation = '2' then   --Pas de dossier déjà existant ou Le mode de création est "Titre dossier = N° dossier"
          --Génération du dossier
          vExistingRecordId  := pGenerateNewRecord(aThirdId, aDocumentId, aDocNumber, vAutomaticCreation, vRcoType, aRecordCategoryId);
        end if;
      end if;
    end if;

    return vExistingRecordId;
  end CreateRecord;

  /**
  * Description
  *    Duplication d'un dossier, retourne l'id du dossier créé
  */
  procedure DuplicateRecord(
    SourceDocRecID     in     DOC_RECORD.DOC_RECORD_ID%type
  , NewDocRecID        in out DOC_RECORD.DOC_RECORD_ID%type
  , NewDocRecTitle     in     DOC_RECORD.RCO_TITLE%type
  , DuplicateAddress   in     integer
  , DuplicateAddresses in     integer
  , DuplicateFreeData  in     integer
  , DuplicateFreeCode  in     integer
  , DuplicateDiscount  in     integer
  , DuplicateCharge    in     integer
  )
  is
    cursor csSrcDocRec(pSrcDocRecID DOC_RECORD.DOC_RECORD_ID%type)
    is
      select *
        from DOC_RECORD
       where DOC_RECORD_ID = pSrcDocRecID;

    rSrcDocRec      csSrcDocRec%rowtype;
    NewDocRecNumber DOC_RECORD.RCO_NUMBER%type;
  begin
    -- Recherche des informations à copier
    open csSrcDocRec(SourceDocRecID);

    fetch csSrcDocRec
     into rSrcDocRec;

    if csSrcDocRec%found then
      -- Recherche l'ID du nouveau dossier
      select INIT_ID_SEQ.nextval
           , RCO_NUMBER_SEQ.nextval
        into NewDocRecID
           , NewDocRecNumber
        from dual;

      -- Vider les champs de l'adresse si non dupliqués
      if DuplicateAddress = 0 then
        rSrcDocRec.DIC_PERSON_POLITNESS_ID  := null;
        rSrcDocRec.RCO_NAME                 := null;
        rSrcDocRec.RCO_FORENAME             := null;
        rSrcDocRec.RCO_ACTIVITY             := null;
        rSrcDocRec.RCO_ADDRESS              := null;
        rSrcDocRec.PC_CNTRY_ID              := null;
        rSrcDocRec.RCO_ZIPCODE              := null;
        rSrcDocRec.RCO_CITY                 := null;
        rSrcDocRec.RCO_STATE                := null;
        rSrcDocRec.PC_LANG_ID               := null;
        rSrcDocRec.RCO_PHONE                := null;
        rSrcDocRec.RCO_FAX                  := null;
        rSrcDocRec.RCO_ADD_FORMAT           := null;
      end if;

      -- Vider les champs des données libres si non dupliqués
      if DuplicateFreeData = 0 then
        rSrcDocRec.DIC_RECORD1_ID     := null;
        rSrcDocRec.DIC_RECORD2_ID     := null;
        rSrcDocRec.DIC_RECORD3_ID     := null;
        rSrcDocRec.DIC_RECORD4_ID     := null;
        rSrcDocRec.DIC_RECORD5_ID     := null;
        rSrcDocRec.DIC_RECORD6_ID     := null;
        rSrcDocRec.DIC_RECORD7_ID     := null;
        rSrcDocRec.DIC_RECORD8_ID     := null;
        rSrcDocRec.DIC_RECORD9_ID     := null;
        rSrcDocRec.DIC_RECORD10_ID    := null;
        rSrcDocRec.RCO_BOOLEAN1       := null;
        rSrcDocRec.RCO_BOOLEAN2       := null;
        rSrcDocRec.RCO_BOOLEAN3       := null;
        rSrcDocRec.RCO_BOOLEAN4       := null;
        rSrcDocRec.RCO_BOOLEAN5       := null;
        rSrcDocRec.RCO_BOOLEAN6       := null;
        rSrcDocRec.RCO_BOOLEAN7       := null;
        rSrcDocRec.RCO_BOOLEAN8       := null;
        rSrcDocRec.RCO_BOOLEAN9       := null;
        rSrcDocRec.RCO_BOOLEAN10      := null;
        rSrcDocRec.RCO_ALPHA_SHORT1   := null;
        rSrcDocRec.RCO_ALPHA_SHORT2   := null;
        rSrcDocRec.RCO_ALPHA_SHORT3   := null;
        rSrcDocRec.RCO_ALPHA_SHORT4   := null;
        rSrcDocRec.RCO_ALPHA_SHORT5   := null;
        rSrcDocRec.RCO_ALPHA_SHORT6   := null;
        rSrcDocRec.RCO_ALPHA_SHORT7   := null;
        rSrcDocRec.RCO_ALPHA_SHORT8   := null;
        rSrcDocRec.RCO_ALPHA_SHORT9   := null;
        rSrcDocRec.RCO_ALPHA_SHORT10  := null;
        rSrcDocRec.RCO_ALPHA_LONG1    := null;
        rSrcDocRec.RCO_ALPHA_LONG2    := null;
        rSrcDocRec.RCO_ALPHA_LONG3    := null;
        rSrcDocRec.RCO_ALPHA_LONG4    := null;
        rSrcDocRec.RCO_ALPHA_LONG5    := null;
        rSrcDocRec.RCO_ALPHA_LONG6    := null;
        rSrcDocRec.RCO_ALPHA_LONG7    := null;
        rSrcDocRec.RCO_ALPHA_LONG8    := null;
        rSrcDocRec.RCO_ALPHA_LONG9    := null;
        rSrcDocRec.RCO_ALPHA_LONG10   := null;
        rSrcDocRec.RCO_DATE1          := null;
        rSrcDocRec.RCO_DATE2          := null;
        rSrcDocRec.RCO_DATE3          := null;
        rSrcDocRec.RCO_DATE4          := null;
        rSrcDocRec.RCO_DATE5          := null;
        rSrcDocRec.RCO_DATE6          := null;
        rSrcDocRec.RCO_DATE7          := null;
        rSrcDocRec.RCO_DATE8          := null;
        rSrcDocRec.RCO_DATE9          := null;
        rSrcDocRec.RCO_DATE10         := null;
        rSrcDocRec.RCO_DECIMAL1       := null;
        rSrcDocRec.RCO_DECIMAL2       := null;
        rSrcDocRec.RCO_DECIMAL3       := null;
        rSrcDocRec.RCO_DECIMAL4       := null;
        rSrcDocRec.RCO_DECIMAL5       := null;
        rSrcDocRec.RCO_DECIMAL6       := null;
        rSrcDocRec.RCO_DECIMAL7       := null;
        rSrcDocRec.RCO_DECIMAL8       := null;
        rSrcDocRec.RCO_DECIMAL9       := null;
        rSrcDocRec.RCO_DECIMAL10      := null;
      end if;

      -- Duplication de l'enregistrement principal (DOC_RECORD)
      insert into DOC_RECORD
                  (
                   -- Données de base
                   DOC_RECORD_ID
                 , DOC_RECORD_CATEGORY_ID
                 , RCO_TITLE
                 , RCO_NUMBER
                 , PAC_THIRD_ID
                 , DIC_ACCOUNTABLE_GROUP_ID
                 , PAC_REPRESENTATIVE_ID
                 , RCO_DESCRIPTION
                 ,
                   -- Adresse
                   DIC_PERSON_POLITNESS_ID
                 , RCO_NAME
                 , RCO_FORENAME
                 , RCO_ACTIVITY
                 , RCO_ADDRESS
                 , PC_CNTRY_ID
                 , RCO_ZIPCODE
                 , RCO_CITY
                 , RCO_STATE
                 , PC_LANG_ID
                 , RCO_PHONE
                 , RCO_FAX
                 , RCO_ADD_FORMAT
                 ,
                   -- Données libres
                   DIC_RECORD1_ID
                 , DIC_RECORD2_ID
                 , DIC_RECORD3_ID
                 , DIC_RECORD4_ID
                 , DIC_RECORD5_ID
                 , DIC_RECORD6_ID
                 , DIC_RECORD7_ID
                 , DIC_RECORD8_ID
                 , DIC_RECORD9_ID
                 , DIC_RECORD10_ID
                 , RCO_BOOLEAN1
                 , RCO_BOOLEAN2
                 , RCO_BOOLEAN3
                 , RCO_BOOLEAN4
                 , RCO_BOOLEAN5
                 , RCO_BOOLEAN6
                 , RCO_BOOLEAN7
                 , RCO_BOOLEAN8
                 , RCO_BOOLEAN9
                 , RCO_BOOLEAN10
                 , RCO_ALPHA_SHORT1
                 , RCO_ALPHA_SHORT2
                 , RCO_ALPHA_SHORT3
                 , RCO_ALPHA_SHORT4
                 , RCO_ALPHA_SHORT5
                 , RCO_ALPHA_SHORT6
                 , RCO_ALPHA_SHORT7
                 , RCO_ALPHA_SHORT8
                 , RCO_ALPHA_SHORT9
                 , RCO_ALPHA_SHORT10
                 , RCO_ALPHA_LONG1
                 , RCO_ALPHA_LONG2
                 , RCO_ALPHA_LONG3
                 , RCO_ALPHA_LONG4
                 , RCO_ALPHA_LONG5
                 , RCO_ALPHA_LONG6
                 , RCO_ALPHA_LONG7
                 , RCO_ALPHA_LONG8
                 , RCO_ALPHA_LONG9
                 , RCO_ALPHA_LONG10
                 , RCO_DATE1
                 , RCO_DATE2
                 , RCO_DATE3
                 , RCO_DATE4
                 , RCO_DATE5
                 , RCO_DATE6
                 , RCO_DATE7
                 , RCO_DATE8
                 , RCO_DATE9
                 , RCO_DATE10
                 , RCO_DECIMAL1
                 , RCO_DECIMAL2
                 , RCO_DECIMAL3
                 , RCO_DECIMAL4
                 , RCO_DECIMAL5
                 , RCO_DECIMAL6
                 , RCO_DECIMAL7
                 , RCO_DECIMAL8
                 , RCO_DECIMAL9
                 , RCO_DECIMAL10
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , C_ASA_GUARANTY_UNIT
                 , C_ASA_MACHINE_STATE
                 , C_RCO_STATUS
                 , C_RCO_TYPE
                 , DIC_RCO_MACHINE1_ID
                 , DIC_RCO_MACHINE10_ID
                 , DIC_RCO_MACHINE2_ID
                 , DIC_RCO_MACHINE3_ID
                 , DIC_RCO_MACHINE4_ID
                 , DIC_RCO_MACHINE5_ID
                 , DIC_RCO_MACHINE6_ID
                 , DIC_RCO_MACHINE7_ID
                 , DIC_RCO_MACHINE8_ID
                 , DIC_RCO_MACHINE9_ID
                 , DOC_PURCHASE_POSITION_ID
                 , GAL_BUDGET_ID
                 , GAL_PROJECT_ID
                 , GAL_TASK_ID
                 , PC_USER_ID
                 , RCO_AGREEMENT_NUMBER
                 , RCO_COST_PRICE
                 , RCO_DIC_ASSOCIATION_TYPE
                 , RCO_ENDING_DATE
                 , RCO_ESTIMATE_PRICE
                 , RCO_MACHINE_ALPHA_LONG1
                 , RCO_MACHINE_ALPHA_LONG10
                 , RCO_MACHINE_ALPHA_LONG2
                 , RCO_MACHINE_ALPHA_LONG3
                 , RCO_MACHINE_ALPHA_LONG4
                 , RCO_MACHINE_ALPHA_LONG5
                 , RCO_MACHINE_ALPHA_LONG6
                 , RCO_MACHINE_ALPHA_LONG7
                 , RCO_MACHINE_ALPHA_LONG8
                 , RCO_MACHINE_ALPHA_LONG9
                 , RCO_MACHINE_ALPHA_SHORT1
                 , RCO_MACHINE_ALPHA_SHORT10
                 , RCO_MACHINE_ALPHA_SHORT2
                 , RCO_MACHINE_ALPHA_SHORT3
                 , RCO_MACHINE_ALPHA_SHORT4
                 , RCO_MACHINE_ALPHA_SHORT5
                 , RCO_MACHINE_ALPHA_SHORT6
                 , RCO_MACHINE_ALPHA_SHORT7
                 , RCO_MACHINE_ALPHA_SHORT8
                 , RCO_MACHINE_ALPHA_SHORT9
                 , RCO_MACHINE_BOOLEAN1
                 , RCO_MACHINE_BOOLEAN10
                 , RCO_MACHINE_BOOLEAN2
                 , RCO_MACHINE_BOOLEAN3
                 , RCO_MACHINE_BOOLEAN4
                 , RCO_MACHINE_BOOLEAN5
                 , RCO_MACHINE_BOOLEAN6
                 , RCO_MACHINE_BOOLEAN7
                 , RCO_MACHINE_BOOLEAN8
                 , RCO_MACHINE_BOOLEAN9
                 , RCO_MACHINE_COMMENT
                 , RCO_MACHINE_DATE1
                 , RCO_MACHINE_DATE10
                 , RCO_MACHINE_DATE2
                 , RCO_MACHINE_DATE3
                 , RCO_MACHINE_DATE4
                 , RCO_MACHINE_DATE5
                 , RCO_MACHINE_DATE6
                 , RCO_MACHINE_DATE7
                 , RCO_MACHINE_DATE8
                 , RCO_MACHINE_DATE9
                 , RCO_MACHINE_DECIMAL1
                 , RCO_MACHINE_DECIMAL10
                 , RCO_MACHINE_DECIMAL2
                 , RCO_MACHINE_DECIMAL3
                 , RCO_MACHINE_DECIMAL4
                 , RCO_MACHINE_DECIMAL5
                 , RCO_MACHINE_DECIMAL6
                 , RCO_MACHINE_DECIMAL7
                 , RCO_MACHINE_DECIMAL8
                 , RCO_MACHINE_DECIMAL9
                 , RCO_MACHINE_FREE_DESCR
                 , RCO_MACHINE_GOOD_ID
                 , RCO_MACHINE_LONG_DESCR
                 , RCO_MACHINE_REMARK
                 , RCO_STARTING_DATE
                 , RCO_SUPPLIER_SERIAL_NUMBER
                 , RCO_SUPPLIER_WARRANTY_END
                 , RCO_SUPPLIER_WARRANTY_START
                 , RCO_SUPPLIER_WARRANTY_TERM
                 , RCO_WARRANTY_PC_APPLTXT_ID
                 , RCO_WARRANTY_TEXT
                 , RCO_XML_CONDITIONS
                 , STM_ELEMENT_NUMBER_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (
                   -- Base
                   NewDocRecID
                 , rSrcDocRec.DOC_RECORD_CATEGORY_ID
                 , nvl(NewDocRecTitle, NewDocRecNumber)
                 , NewDocRecNumber
                 , rSrcDocRec.PAC_THIRD_ID
                 , rSrcDocRec.DIC_ACCOUNTABLE_GROUP_ID
                 , rSrcDocRec.PAC_REPRESENTATIVE_ID
                 , rSrcDocRec.RCO_DESCRIPTION
                 ,
                   -- Adresse
                   rSrcDocRec.DIC_PERSON_POLITNESS_ID
                 , rSrcDocRec.RCO_NAME
                 , rSrcDocRec.RCO_FORENAME
                 , rSrcDocRec.RCO_ACTIVITY
                 , rSrcDocRec.RCO_ADDRESS
                 , rSrcDocRec.PC_CNTRY_ID
                 , rSrcDocRec.RCO_ZIPCODE
                 , rSrcDocRec.RCO_CITY
                 , rSrcDocRec.RCO_STATE
                 , rSrcDocRec.PC_LANG_ID
                 , rSrcDocRec.RCO_PHONE
                 , rSrcDocRec.RCO_FAX
                 , rSrcDocRec.RCO_ADD_FORMAT
                 ,
                   -- Données libres
                   rSrcDocRec.DIC_RECORD1_ID
                 , rSrcDocRec.DIC_RECORD2_ID
                 , rSrcDocRec.DIC_RECORD3_ID
                 , rSrcDocRec.DIC_RECORD4_ID
                 , rSrcDocRec.DIC_RECORD5_ID
                 , rSrcDocRec.DIC_RECORD6_ID
                 , rSrcDocRec.DIC_RECORD7_ID
                 , rSrcDocRec.DIC_RECORD8_ID
                 , rSrcDocRec.DIC_RECORD9_ID
                 , rSrcDocRec.DIC_RECORD10_ID
                 , rSrcDocRec.RCO_BOOLEAN1
                 , rSrcDocRec.RCO_BOOLEAN2
                 , rSrcDocRec.RCO_BOOLEAN3
                 , rSrcDocRec.RCO_BOOLEAN4
                 , rSrcDocRec.RCO_BOOLEAN5
                 , rSrcDocRec.RCO_BOOLEAN6
                 , rSrcDocRec.RCO_BOOLEAN7
                 , rSrcDocRec.RCO_BOOLEAN8
                 , rSrcDocRec.RCO_BOOLEAN9
                 , rSrcDocRec.RCO_BOOLEAN10
                 , rSrcDocRec.RCO_ALPHA_SHORT1
                 , rSrcDocRec.RCO_ALPHA_SHORT2
                 , rSrcDocRec.RCO_ALPHA_SHORT3
                 , rSrcDocRec.RCO_ALPHA_SHORT4
                 , rSrcDocRec.RCO_ALPHA_SHORT5
                 , rSrcDocRec.RCO_ALPHA_SHORT6
                 , rSrcDocRec.RCO_ALPHA_SHORT7
                 , rSrcDocRec.RCO_ALPHA_SHORT8
                 , rSrcDocRec.RCO_ALPHA_SHORT9
                 , rSrcDocRec.RCO_ALPHA_SHORT10
                 , rSrcDocRec.RCO_ALPHA_LONG1
                 , rSrcDocRec.RCO_ALPHA_LONG2
                 , rSrcDocRec.RCO_ALPHA_LONG3
                 , rSrcDocRec.RCO_ALPHA_LONG4
                 , rSrcDocRec.RCO_ALPHA_LONG5
                 , rSrcDocRec.RCO_ALPHA_LONG6
                 , rSrcDocRec.RCO_ALPHA_LONG7
                 , rSrcDocRec.RCO_ALPHA_LONG8
                 , rSrcDocRec.RCO_ALPHA_LONG9
                 , rSrcDocRec.RCO_ALPHA_LONG10
                 , rSrcDocRec.RCO_DATE1
                 , rSrcDocRec.RCO_DATE2
                 , rSrcDocRec.RCO_DATE3
                 , rSrcDocRec.RCO_DATE4
                 , rSrcDocRec.RCO_DATE5
                 , rSrcDocRec.RCO_DATE6
                 , rSrcDocRec.RCO_DATE7
                 , rSrcDocRec.RCO_DATE8
                 , rSrcDocRec.RCO_DATE9
                 , rSrcDocRec.RCO_DATE10
                 , rSrcDocRec.RCO_DECIMAL1
                 , rSrcDocRec.RCO_DECIMAL2
                 , rSrcDocRec.RCO_DECIMAL3
                 , rSrcDocRec.RCO_DECIMAL4
                 , rSrcDocRec.RCO_DECIMAL5
                 , rSrcDocRec.RCO_DECIMAL6
                 , rSrcDocRec.RCO_DECIMAL7
                 , rSrcDocRec.RCO_DECIMAL8
                 , rSrcDocRec.RCO_DECIMAL9
                 , rSrcDocRec.RCO_DECIMAL10
                 , rSrcDocRec.ACS_CDA_ACCOUNT_ID
                 , rSrcDocRec.ACS_CPN_ACCOUNT_ID
                 , rSrcDocRec.ACS_DIVISION_ACCOUNT_ID
                 , rSrcDocRec.ACS_FINANCIAL_ACCOUNT_ID
                 , rSrcDocRec.ACS_PF_ACCOUNT_ID
                 , rSrcDocRec.ACS_PJ_ACCOUNT_ID
                 , rSrcDocRec.C_ASA_GUARANTY_UNIT
                 , rSrcDocRec.C_ASA_MACHINE_STATE
                 , rSrcDocRec.C_RCO_STATUS
                 , rSrcDocRec.C_RCO_TYPE
                 , rSrcDocRec.DIC_RCO_MACHINE1_ID
                 , rSrcDocRec.DIC_RCO_MACHINE10_ID
                 , rSrcDocRec.DIC_RCO_MACHINE2_ID
                 , rSrcDocRec.DIC_RCO_MACHINE3_ID
                 , rSrcDocRec.DIC_RCO_MACHINE4_ID
                 , rSrcDocRec.DIC_RCO_MACHINE5_ID
                 , rSrcDocRec.DIC_RCO_MACHINE6_ID
                 , rSrcDocRec.DIC_RCO_MACHINE7_ID
                 , rSrcDocRec.DIC_RCO_MACHINE8_ID
                 , rSrcDocRec.DIC_RCO_MACHINE9_ID
                 , rSrcDocRec.DOC_PURCHASE_POSITION_ID
                 , rSrcDocRec.GAL_BUDGET_ID
                 , rSrcDocRec.GAL_PROJECT_ID
                 , rSrcDocRec.GAL_TASK_ID
                 , rSrcDocRec.PC_USER_ID
                 , rSrcDocRec.RCO_AGREEMENT_NUMBER
                 , rSrcDocRec.RCO_COST_PRICE
                 , rSrcDocRec.RCO_DIC_ASSOCIATION_TYPE
                 , rSrcDocRec.RCO_ENDING_DATE
                 , rSrcDocRec.RCO_ESTIMATE_PRICE
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG1
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG10
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG2
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG3
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG4
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG5
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG6
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG7
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG8
                 , rSrcDocRec.RCO_MACHINE_ALPHA_LONG9
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT1
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT10
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT2
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT3
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT4
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT5
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT6
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT7
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT8
                 , rSrcDocRec.RCO_MACHINE_ALPHA_SHORT9
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN1
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN10
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN2
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN3
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN4
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN5
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN6
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN7
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN8
                 , rSrcDocRec.RCO_MACHINE_BOOLEAN9
                 , rSrcDocRec.RCO_MACHINE_COMMENT
                 , rSrcDocRec.RCO_MACHINE_DATE1
                 , rSrcDocRec.RCO_MACHINE_DATE10
                 , rSrcDocRec.RCO_MACHINE_DATE2
                 , rSrcDocRec.RCO_MACHINE_DATE3
                 , rSrcDocRec.RCO_MACHINE_DATE4
                 , rSrcDocRec.RCO_MACHINE_DATE5
                 , rSrcDocRec.RCO_MACHINE_DATE6
                 , rSrcDocRec.RCO_MACHINE_DATE7
                 , rSrcDocRec.RCO_MACHINE_DATE8
                 , rSrcDocRec.RCO_MACHINE_DATE9
                 , rSrcDocRec.RCO_MACHINE_DECIMAL1
                 , rSrcDocRec.RCO_MACHINE_DECIMAL10
                 , rSrcDocRec.RCO_MACHINE_DECIMAL2
                 , rSrcDocRec.RCO_MACHINE_DECIMAL3
                 , rSrcDocRec.RCO_MACHINE_DECIMAL4
                 , rSrcDocRec.RCO_MACHINE_DECIMAL5
                 , rSrcDocRec.RCO_MACHINE_DECIMAL6
                 , rSrcDocRec.RCO_MACHINE_DECIMAL7
                 , rSrcDocRec.RCO_MACHINE_DECIMAL8
                 , rSrcDocRec.RCO_MACHINE_DECIMAL9
                 , rSrcDocRec.RCO_MACHINE_FREE_DESCR
                 , rSrcDocRec.RCO_MACHINE_GOOD_ID
                 , rSrcDocRec.RCO_MACHINE_LONG_DESCR
                 , rSrcDocRec.RCO_MACHINE_REMARK
                 , rSrcDocRec.RCO_STARTING_DATE
                 , rSrcDocRec.RCO_SUPPLIER_SERIAL_NUMBER
                 , rSrcDocRec.RCO_SUPPLIER_WARRANTY_END
                 , rSrcDocRec.RCO_SUPPLIER_WARRANTY_START
                 , rSrcDocRec.RCO_SUPPLIER_WARRANTY_TERM
                 , rSrcDocRec.RCO_WARRANTY_PC_APPLTXT_ID
                 , rSrcDocRec.RCO_WARRANTY_TEXT
                 , rSrcDocRec.RCO_XML_CONDITIONS
                 , rSrcDocRec.STM_ELEMENT_NUMBER_ID
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- Duplication des codes libres
      if DuplicateFreeCode = 1 then
        insert into DOC_FREE_CODE
                    (DOC_FREE_CODE_ID
                   , DOC_RECORD_ID
                   , DFC_BOO_CODE
                   , DIC_DOC_BOOLEAN_CODE_TYPE_ID
                   , DFC_CHA_CODE
                   , DIC_DOC_CHAR_CODE_TYPE_ID
                   , DFC_DAT_CODE
                   , DIC_DOC_DATE_CODE_TYPE_ID
                   , DFC_NUM_CODE
                   , DIC_DOC_NUM_CODE_TYPE_ID
                   , DFC_MEM_CODE
                   , DIC_DOC_MEMO_CODE_TYPE_ID
                   , A_DATECRE
                   , A_IDCRE
                   , DFC_CODE_VALUE
                   , CPC_NAME
                    )
          select INIT_ID_SEQ.nextval
               , NewDocRecID
               , DFC_BOO_CODE
               , DIC_DOC_BOOLEAN_CODE_TYPE_ID
               , DFC_CHA_CODE
               , DIC_DOC_CHAR_CODE_TYPE_ID
               , DFC_DAT_CODE
               , DIC_DOC_DATE_CODE_TYPE_ID
               , DFC_NUM_CODE
               , DIC_DOC_NUM_CODE_TYPE_ID
               , DFC_MEM_CODE
               , DIC_DOC_MEMO_CODE_TYPE_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , DFC_CODE_VALUE
               , CPC_NAME
            from DOC_FREE_CODE
           where DOC_RECORD_ID = SourceDocRecID;
      end if;

      -- Duplication des remises
      if DuplicateDiscount = 1 then
        insert into PTC_DISCOUNT_S_RECORD
                    (PTC_DISCOUNT_ID
                   , DOC_RECORD_ID
                    )
          select PTC_DISCOUNT_ID
               , NewDocRecID
            from PTC_DISCOUNT_S_RECORD
           where DOC_RECORD_ID = SourceDocRecID;
      end if;

      -- Duplication des taxes
      if DuplicateCharge = 1 then
        insert into PTC_CHARGE_S_RECORD
                    (PTC_CHARGE_ID
                   , DOC_RECORD_ID
                    )
          select PTC_CHARGE_ID
               , NewDocRecID
            from PTC_CHARGE_S_RECORD
           where DOC_RECORD_ID = SourceDocRecID;
      end if;
    end if;

    -- Duplication des adresses
    if DuplicateAddresses = 1 then
      insert into DOC_RECORD_ADDRESS
                  (DOC_RECORD_ADDRESS_ID
                 , DOC_RECORD_ID
                 , DIC_RCO_LINK_TYPE_ID
                 , PAC_PERSON_ID
                 , RCA_REMARK
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , NewDocRecID
             , DIC_RCO_LINK_TYPE_ID
             , PAC_PERSON_ID
             , RCA_REMARK
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from DOC_RECORD_ADDRESS
         where DOC_RECORD_ID = SourceDocRecID;
    end if;

    close csSrcDocRec;
  end DuplicateRecord;
end DOC_RECORD_MANAGEMENT;
