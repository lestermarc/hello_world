--------------------------------------------------------
--  DDL for Package Body SCH_GOOD_INTERFACE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_GOOD_INTERFACE" 
is
  -- Configurations
  cSchTarifCodeToUpdate varchar2(64) := PCS.PC_CONFIG.GetConfig('SCH_TARIF_CODE_TO_UPDATE');
  cSchPrcCalcTariff     varchar2(64) := PCS.PC_CONFIG.GetConfig('SCH_PRC_CALC_TARIFF');

  /**
  * function GetGcoGoodCategory
  * Description : Fonction, qui teste l'existence de la catégorie de bien passée en paramètre
  *             , la crée si elle n'existe pas, et renvoie son ID.
  *               Les catégories de bien utilisées sont données par les configurations
  *                -> SCH_ECOLAGE_GOOD_CATEGORY  : Ecolage
  *                -> SCH_DISCOUNT_GOOD_CATEGORY : Remise sur ecolage
  *                -> SCH_EXPENSES_GOOD_CATEGORY : Débours
  *               Utilisant chacun le gabarit de référence donné par la configuration
  *               SCH_GOOD_CAT_REF_TEMPLATE
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aGoodKind : Type du bien créé ( 1 : écolage - 2 : Remise - 3 : Débours)
  */
  function GetGcoGoodCategory(aGoodKind in number)
    return number
  is
    aGcoGoodCategoryId   number(12);
    aReferenceTemplateId number(12);
    aCategoryCode        number(9);
  begin
    -- Recherche de la catégorie de bien
    begin
      select GCO_GOOD_CATEGORY_ID
        into aGcoGoodCategoryId
        from GCO_GOOD_CATEGORY CAT
           , GCO_REFERENCE_TEMPLATE TEMP
       where CAT.GCO_REFERENCE_TEMPLATE_ID = TEMP.GCO_REFERENCE_TEMPLATE_ID
         and TEMP.RTE_DESIGNATION = PCS.PC_CONFIG.GetConfig('SCH_GOOD_CAT_REF_TEMPLATE')
         and (    (    aGoodKind = 1
                   and CAT.GCO_GOOD_CATEGORY_WORDING = PCS.PC_CONFIG.GetConfig('SCH_ECOLAGE_GOOD_CATEGORY') )
              or (    aGoodKind = 2
                  and CAT.GCO_GOOD_CATEGORY_WORDING = PCS.PC_CONFIG.GetConfig('SCH_DISCOUNT_GOOD_CATEGORY') )
              or (    aGoodKind = 3
                  and CAT.GCO_GOOD_CATEGORY_WORDING = PCS.PC_CONFIG.GetConfig('SCH_EXPENSES_GOOD_CATEGORY') )
             );
    exception
      when no_data_found then
        aGcoGoodCategoryId  := null;
    end;

    -- Si elle existe, on retourne son ID
    if nvl(aGcoGoodCategoryId, 0) <> 0 then
      return aGcoGoodCategoryId;
    -- Sinon, on la génère automatiquement
    else
      -- On vérifie si le gabarit de référence existe
      begin
        select GCO_REFERENCE_TEMPLATE_ID
          into aReferenceTemplateId
          from GCO_REFERENCE_TEMPLATE
         where RTE_DESIGNATION = PCS.PC_CONFIG.GetConfig('SCH_GOOD_CAT_REF_TEMPLATE');
      exception
        when no_data_found then
          aReferenceTemplateId  := null;
      end;

      -- S'il n'existe pas, on le génère automatiquement
      if nvl(aReferenceTemplateId, 0) = 0 then
        aReferenceTemplateId  := GetNewId;

        insert into GCO_REFERENCE_TEMPLATE
                    (GCO_REFERENCE_TEMPLATE_ID
                   , RTE_DESIGNATION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (aReferenceTemplateId
                   , PCS.PC_CONFIG.GetConfig('SCH_GOOD_CAT_REF_TEMPLATE')
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;

      -- Création du code de la catégorie de bien. Ce code de 9 chiffres doit être unique.
      -- On prendra le maximum + 1 .
      select max(GCO_CATEGORY_CODE) + 1
        into aCategoryCode
        from GCO_GOOD_CATEGORY;

      -- Enfin, on crée la catégorie de bien
      aGcoGoodCategoryId  := GetNewId;

      insert into GCO_GOOD_CATEGORY
                  (GCO_GOOD_CATEGORY_ID
                 , GCO_REFERENCE_TEMPLATE_ID
                 , GCO_GOOD_CATEGORY_WORDING
                 , GCO_CATEGORY_CODE
                 , CAT_COMPL_ACHAT
                 , CAT_COMPL_VENTE
                 , CAT_COMPL_SAV
                 , CAT_COMPL_STOCK
                 , CAT_COMPL_INV
                 , CAT_COMPL_FAB
                 , CAT_COMPL_STRAIT
                 , CAT_COMPL_DISTRIB
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aGcoGoodCategoryId
                 , aReferenceTemplateId
                 , (case
                      when aGoodKind = 1 then PCS.PC_CONFIG.GetConfig('SCH_ECOLAGE_GOOD_CATEGORY')
                      when aGoodKind = 2 then PCS.PC_CONFIG.GetConfig('SCH_DISCOUNT_GOOD_CATEGORY')
                      when aGoodKind = 3 then PCS.PC_CONFIG.GetConfig('SCH_EXPENSES_GOOD_CATEGORY')
                    end
                   )
                 , aCategoryCode
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      return aGcoGoodCategoryId;
    end if;
  exception
    when others then
      begin
        raise;
        return null;
      end;
  end GetGcoGoodCategory;

  /**
  * procedure InsertService
  * Description : Procedure de génération automatique des services associés aux écolages
  *               remises et débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGoodKind : Type du bien créé ( 1 : écolage - 2 : Remise - 3 : Débours)
  * @param   aMajorReference : Référence principale
  * @param   aSecondaryReference : Référence secondaire
  * @param   aShortDescription : Description courte
  * @param   aLongDescription : Description longue
  * @param   aFreeDescription : Description libre
  */
  procedure InsertService(
    aGoodKind           in     number
  , aMajorReference     in     varchar2
  , aSecondaryReference in     varchar2
  , aShortDescription   in     varchar2
  , aLongDescription    in     varchar2
  , aFreeDescription    in     varchar2
  , aGCO_GOOD_ID        in out number
  )
  is
    aGcoGoodCategoryId      number;
    aACS_VAT_DET_ACCOUNT_ID GCO_VAT_GOOD.ACS_VAT_DET_ACCOUNT_ID%type;
    aDIC_TYPE_VAT_GOOD_ID   GCO_VAT_GOOD.DIC_TYPE_VAT_GOOD_ID%type;
    aGooMajorReference      GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
    -- Création / récupération de la catégorie de biens pour gestion des écolages, remises et débours
    aGcoGoodCategoryId  := GetGcoGoodCategory(aGoodKind);
    -- Récupération d'une référence principale unique
    aGooMajorReference  := GetUniqueMajorReference(aMajorReference, null);
    -- Création du bien
    aGCO_GOOD_ID        := GetNewId;

    insert into GCO_GOOD
                (GCO_GOOD_ID
               , GCO_GOOD_CATEGORY_ID
               , DIC_UNIT_OF_MEASURE_ID
               , C_GOOD_STATUS
               , C_MANAGEMENT_MODE
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , GOO_CCP_MANAGEMENT
               , GOO_NUMBER_OF_DECIMAL
               , GCO_DATA_PURCHASE
               , GCO_DATA_SALE
               , GCO_DATA_STOCK
               , GCO_DATA_INVENTORY
               , GCO_DATA_MANUFACTURE
               , GCO_DATA_SUBCONTRACT
               , GCO_DATA_SAV
               , A_DATECRE
               , A_IDCRE
                )
         values (aGCO_GOOD_ID
               , aGcoGoodCategoryId
               , PCS.PC_CONFIG.GetConfig('GCO_Se_UNIT_OF_MEASURE')
               , '1'   -- bien inactif
               , '3'   -- Mode de gestion : Prix de revient fixe
               , aGooMajorReference
               , aSecondaryReference
               , 0
               , 4
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    -- Creation en tant que service
    insert into GCO_SERVICE
                (GCO_GOOD_ID
                )
         values (aGCO_GOOD_ID
                );

    -- Création de ses descriptions
    insert into GCO_DESCRIPTION
                (GCO_DESCRIPTION_ID
               , GCO_GOOD_ID
               , PC_LANG_ID
               , C_DESCRIPTION_TYPE
               , DES_SHORT_DESCRIPTION
               , DES_LONG_DESCRIPTION
               , DES_FREE_DESCRIPTION
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , aGCO_GOOD_ID
               , PCS.PC_I_LIB_SESSION.GetUserLangId
               , '01'
               , aShortDescription
               , aLongDescription
               , aFreeDescription
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    -- Création du Prix de revient fixe = 0.00
    insert into PTC_FIXED_COSTPRICE
                (PTC_FIXED_COSTPRICE_ID
               , GCO_GOOD_ID
               , DIC_FIXED_COSTPRICE_DESCR_ID
               , C_COSTPRICE_STATUS
               , CPR_DEFAULT
               , CPR_PRICE
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , aGCO_GOOD_ID
               , 'PRF'
               , 'ACT'
               , 1
               , 0
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    -- Activation du bien
    update GCO_GOOD
       set C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = aGCO_GOOD_ID;
  exception
    when others then
      raise;
  end InsertService;

  /**
  * procedure UpdateService
  * Description : Procedure de modification d'un service en regard de son élément associé
  *               à savoir, écolage, remise ou débours.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_GOOD_ID        : Produit
  * @param   aMajorReference     : Référence principale
  * @param   aSecondaryReference : Référence secondaire
  * @param   aShortDescription   : Description courte
  * @param   aLongDescription    : Description longue
  * @param   aFreeDescription    : Description libre
  * @param   aGoodKind : Type du bien créé ( 1 : écolage - 2 : Remise - 3 : Débours)
  * @param   aElementID : Id du type de bien à l'origine de la création
  */
  procedure UpdateService(
    aGCO_GOOD_ID        in GCO_GOOD.GCO_GOOD_ID%type
  , aMajorReference     in varchar2
  , aSecondaryReference in varchar2
  , aShortDescription   in varchar2
  , aLongDescription    in varchar2
  , aFreeDescription    in varchar2
  , aGoodKind           in number default null
  , aElementID          in number default null
  )
  is
    aDescriptionId      GCO_DESCRIPTION.GCO_DESCRIPTION_ID%type;
    aCreatedGCO_GOOD_ID number;
  begin
    if aGCO_GOOD_ID is not null then
      -- Reférences principales et secondaires
      update GCO_GOOD
         set GOO_MAJOR_REFERENCE = aMajorReference
           , GOO_SECONDARY_REFERENCE = aSecondaryReference
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GCO_GOOD_ID = aGCO_GOOD_ID;

      -- On teste si la description existe pour la langue de l'utilisateur
      begin
        select GCO_DESCRIPTION_ID
          into aDescriptionId
          from GCO_DESCRIPTION
         where GCO_GOOD_ID = aGCO_GOOD_ID
           and C_DESCRIPTION_TYPE = '01'
           and PC_LANG_ID = PCS.PC_PUBLIC.GetUserLangId;

        -- Mise à jour
        update GCO_DESCRIPTION
           set DES_SHORT_DESCRIPTION = aShortDescription
             , DES_LONG_DESCRIPTION = aLongDescription
             , DES_FREE_DESCRIPTION = aFreeDescription
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_DESCRIPTION_ID = aDescriptionId;
      exception
        -- Si elle n'existe pas, on la crée
        when no_data_found then
          begin
            insert into GCO_DESCRIPTION
                        (GCO_DESCRIPTION_ID
                       , GCO_GOOD_ID
                       , PC_LANG_ID
                       , C_DESCRIPTION_TYPE
                       , DES_SHORT_DESCRIPTION
                       , DES_LONG_DESCRIPTION
                       , DES_FREE_DESCRIPTION
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (INIT_ID_SEQ.nextval
                       , aGCO_GOOD_ID
                       , PCS.PC_I_LIB_SESSION.GetUserLangId
                       , '01'
                       , aShortDescription
                       , aLongDescription
                       , aFreeDescription
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          end;
      end;
    -- Le bien n'existe pas
    else
      InsertService(aGoodKind, aMajorReference, aSecondaryReference, aShortDescription, aLongDescription, aFreeDescription, aCreatedGCO_GOOD_ID);

      -- Ecolage
      if aGoodKind = 1 then
        update SCH_ECOLAGE_CATEGORY
           set GCO_GOOD_ID = aCreatedGCO_GOOD_ID
         where SCH_ECOLAGE_CATEGORY_ID = aElementID;
      -- Remise
      elsif aGoodKind = 2 then
        update SCH_DISCOUNT
           set GCO_GOOD_ID = aCreatedGCO_GOOD_ID
         where SCH_DISCOUNT_ID = aElementID;
      -- Débours
      elsif aGoodKind = 3 then
        update SCH_OUTLAY_CATEGORY
           set GCO_GOOD_ID = aCreatedGCO_GOOD_ID
         where SCH_OUTLAY_CATEGORY_ID = aElementID;
      end if;
    end if;
  exception
    when others then
      raise;
  end UpdateService;

  /**
  * procedure DeleteService
  * Description : Procedure de Suppression d'un service en regard de son élément associé
  *               à savoir, écolage, remise ou débours.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_GOOD_ID : Produit
  */
  procedure DeleteService(aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    -- Suppression en tant que service
    delete from GCO_SERVICE
          where GCO_GOOD_ID = aGCO_GOOD_ID;

    -- Suppression des descriptions
    delete from GCO_DESCRIPTION
          where GCO_GOOD_ID = aGCO_GOOD_ID;

    -- Suppression des prix de revient
    delete from PTC_FIXED_COSTPRICE
          where GCO_GOOD_ID = aGCO_GOOD_ID;

    -- Suppression des TVA
    delete from GCO_VAT_GOOD
          where GCO_GOOD_ID = aGCO_GOOD_ID;

    -- Suppression du produit
    delete from GCO_GOOD
          where GCO_GOOD_ID = aGCO_GOOD_ID;
  exception
    when others then
      raise;
  end;

  /**
  * function InsertVatGood
  * Description : Procedure de génération automatique des informations de TVA des services
  *               associés aux écolages, remises, débours.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_GOOD_ID             : produit
  , @param   aACS_VAT_DET_ACCOUNT_ID  : Décompte TVA
  , @param   aDIC_TYPE_VAT_GOOD_ID    : Nature de la prestation
  */
  function InsertVatGood(
    aElementID              in GCO_GOOD.GCO_GOOD_ID%type
  , aACS_VAT_DET_ACCOUNT_ID in ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID%type
  , aDIC_TYPE_VAT_GOOD_ID   in DIC_TYPE_VAT_GOOD.DIC_TYPE_VAT_GOOD_ID%type
  )
    return number
  is
    aVatGoodId   GCO_VAT_GOOD.GCO_VAT_GOOD_ID%type;
    aGCO_GOOD_ID number;
  begin
    -- Recherche service lié
    begin
      select GCO_GOOD_ID
        into aGCO_GOOD_ID
        from SCH_OUTLAY_CATEGORY
       where SCH_OUTLAY_CATEGORY_ID = aElementID;
    exception
      when no_data_found then
        begin
          select GCO_GOOD_ID
            into aGCO_GOOD_ID
            from SCH_ECOLAGE_CATEGORY
           where SCH_ECOLAGE_CATEGORY_ID = aElementID;
        exception
          when no_data_found then
            aGCO_GOOD_ID  := null;
        end;
    end;

    --ra('aElementID = ' || aElementID, 'ECASSIS');
    --ra('aGCO_GOOD_ID = ' || aGCO_GOOD_ID, 'ECASSIS');
    -- Vérification existance de l'enregistrement
    begin
      select GCO_VAT_GOOD_ID
        into aVatGoodId
        from GCO_VAT_GOOD
       where GCO_GOOD_ID = aGCO_GOOD_ID
         and ACS_VAT_DET_ACCOUNT_ID = aACS_VAT_DET_ACCOUNT_ID
         and DIC_TYPE_VAT_GOOD_ID = aDIC_TYPE_VAT_GOOD_ID;
    exception
      when no_data_found then
        begin
          aVatGoodId  := GetNewId;

          insert into GCO_VAT_GOOD
                      (GCO_VAT_GOOD_ID
                     , GCO_GOOD_ID
                     , ACS_VAT_DET_ACCOUNT_ID
                     , DIC_TYPE_VAT_GOOD_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (aVatGoodId
                     , aGCO_GOOD_ID
                     , aACS_VAT_DET_ACCOUNT_ID
                     , aDIC_TYPE_VAT_GOOD_ID
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end;
    end;

    return aVatGoodId;
  exception
    when others then
      begin
        raise;
        return null;
      end;
  end InsertVatGood;

  /**
  * procedure UpdateVatGood
  * Description : Procedure de modification automatique des informations de TVA des services
  *               associés aux écolages, remises, débours.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_VAT_GOOD_ID         : ID TVA
  * @param   aACS_VAT_DET_ACCOUNT_ID  : Décompte TVA
  * @param   aDIC_TYPE_VAT_GOOD_ID    : Nature de la prestation
  */
  procedure UpdateVatGood(
    aGCO_VAT_GOOD_ID        in GCO_VAT_GOOD.GCO_VAT_GOOD_ID%type
  , aACS_VAT_DET_ACCOUNT_ID in ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID%type
  , aDIC_TYPE_VAT_GOOD_ID   in DIC_TYPE_VAT_GOOD.DIC_TYPE_VAT_GOOD_ID%type
  )
  is
  begin
    update GCO_VAT_GOOD
       set DIC_TYPE_VAT_GOOD_ID = aDIC_TYPE_VAT_GOOD_ID
         , ACS_VAT_DET_ACCOUNT_ID = aACS_VAT_DET_ACCOUNT_ID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_VAT_GOOD_ID = aGCO_VAT_GOOD_ID;
  end UpdateVatGood;

  /**
  * procedure DeleteVatGood
  * Description : Procedure de suppression automatique des informations de TVA des services
  *               associés aux écolages, remises, débours.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_VAT_GOOD_ID         : ID TVA
  */
  procedure DeleteVatGood(aGCO_VAT_GOOD_ID GCO_VAT_GOOD.GCO_VAT_GOOD_ID%type)
  is
  begin
    -- Suppression de l'enreg dans GCO_VAT_GOOD
    delete from GCO_VAT_GOOD
          where GCO_VAT_GOOD_ID = aGCO_VAT_GOOD_ID;
  end DeleteVatGood;

  /**
  * function GetUniqueMajorReference
  * Description : Fonction de génération d'une référence principale unique
  *               pour création des dervices associés.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aMajorReference : Référence principale.
  * @param   aGCO_GOOD_ID    : ID Bien associé à l'élément en cours
  */
  function GetUniqueMajorReference(aMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%type, aGCO_GOOD_ID number)
    return varchar2
  is
    aGoodReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    aCounter       integer;

    -- Test l'existance d'une référence
    function ReferenceExists(aReference GCO_GOOD.GOO_MAJOR_REFERENCE%type, aGoodId number)
      return boolean
    is
      aExistingReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    begin
      select GOO_MAJOR_REFERENCE
        into aExistingReference
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = aReference
         and (   aGoodId is null
              or (    aGoodId is not null
                  and GCO_GOOD_ID <> aGoodId) );

      return true;
    exception
      when no_data_found then
        return false;
    end;
  begin
    -- La référence existe, génération d'une nouvelle référence sur la base du paramètre
    if ReferenceExists(aMajorReference, aGCO_GOOD_ID) then
      aCounter  := 0;

      loop
        aGoodReference  := substr(aMajorReference, 0, 25) || '<' || aCounter || '>';

        if    not ReferenceExists(aGoodReference, aGCO_GOOD_ID)
           or aCounter > 999 then
          exit;
        end if;

        aCounter        := aCounter + 1;
      end loop;
    else
      aGoodReference  := aMajorReference;
    end if;

    return aGoodReference;
  exception
    when others then
      raise;
  end GetUniqueMajorReference;

  /**
  * procedure UpdateSalesTarifsIndv
  * Description : Appel de la procédure individualisé définie dans la configuration SCH_PRC_CALC_TARIFF
  *               pour la mise à jour des tarifs.
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aGcoGoodId    : ID du produit
  * @param   aPoints       : Nombre de points
  * @param   aRate         : Taux 2
  * @param   aExecStandard : Exécution standard
  */
  procedure UpdateSalesTarifsIndv(aGcoGoodId in number, aPoints in number, aRate in number, aExecStandard in out integer)
  is
    vPrcSql varchar2(2000);
  begin
    vPrcSql  := ' begin ';
    vPrcSql  := vPrcSql || cSchPrcCalcTariff || '(:nGcoGoodId, :aPoints, :aRate, :aExecStandard);';
    vPrcSql  := vPrcSql || ' end; ';

    execute immediate vPrcSql
                using in aGcoGoodId, in aPoints, in aRate, in out aExecStandard;
  end;

  /**
  * procedure UpdateSalesTarifs
  * Description : Mise à jour des tarifs
  *               - Appel de la procédure définie dans la configuration SCH_PRC_CALC_TARIFF si elle existe
  *               - Appel de la procédure UpdateSalesTarifs sinon.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGcoGoodId : produit
  * @param   aPoints : Nombre de points
  * @param   aRate : Taux 2
  */
  procedure UpdateSalesTarifs(aGcoGoodId in number, aPoints in number, aRate in number)
  is
    iExecStandard integer;
  begin
    iExecStandard  := 1;

    if cSchPrcCalcTariff is not null then
      UpdateSalesTarifsIndv(aGcoGoodId, aPoints, aRate, iExecStandard);
    end if;

    if iExecStandard = 1 then
      UpdateSalesTarifsStd(aGcoGoodId, aPoints, aRate);
    end if;
  end UpdateSalesTarifs;

  /**
  * procedure UpdateSalesTarifsStd
  * Description : Procédure standard de mise à jour des tarifs (Nbre Pts * Taux),
  *               des codes tarif précisés par la configuration SCH_TARIF_CODE_TO_UPDATE
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGcoGoodId : produit
  * @param   aPoints : Nombre de points
  * @param   aRate : Taux 2
  */
  procedure UpdateSalesTarifsStd(aGcoGoodId in number, aPoints in number, aRate in number)
  is
    cursor crPTC_TARIFF(aDIC_TARIFF_IDList varchar2)
    is
      select TRF.PTC_TARIFF_ID
           , TRF.ACS_FINANCIAL_CURRENCY_ID
           , TTA1.PTC_TARIFF_TABLE_ID
        from PTC_TARIFF TRF
           , PTC_TARIFF_TABLE TTA1
       where TRF.GCO_GOOD_ID = aGcoGoodId
         and TTA1.PTC_TARIFF_ID = TRF.PTC_TARIFF_ID
         and TRF.C_TARIFF_TYPE = 'A_FACTURER'
         and (trunc(sysdate) between nvl(TRF.TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                 and nvl(TRF.TRF_ENDING_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
             )
         and aDIC_TARIFF_IDList is not null
         and instr(aDIC_TARIFF_IDList, TRF.DIC_TARIFF_ID) > 0
         and (select count(*)
                from PTC_TARIFF_TABLE TTA
               where TTA.PTC_TARIFF_ID = TRF.PTC_TARIFF_ID) = 1;

    lnACS_FINANCIAL_CURRENCY_ID number;
    lnAmountEUR                 number;
    lnAmountConvert             number;
  begin
    -- Récupération monnaie de base de la société
    lnACS_FINANCIAL_CURRENCY_ID  := ACS_FUNCTION.GetLocalCurrencyId;

    if not cSchTarifCodeToUpdate is null then
      -- Parcours des tarifs à mettre à jour
      for tplPTC_TARIFF in crPTC_TARIFF(cSchTarifCodeToUpdate) loop
        -- Monnaie du tarif <> de la monnaie de base de la société
        if lnACS_FINANCIAL_CURRENCY_ID <> tplPTC_TARIFF.ACS_FINANCIAL_CURRENCY_ID then
          -- Conversion dans la monnaie du tarif
          ACS_FUNCTION.ConvertAmount(aPoints * aRate
                                   , lnACS_FINANCIAL_CURRENCY_ID
                                   , tplPTC_TARIFF.ACS_FINANCIAL_CURRENCY_ID
                                   , sysdate
                                   , 0
                                   , 0
                                   , 0
                                   , lnAmountEUR
                                   , lnAmountConvert
                                    );
        else
          lnAmountConvert  := aPoints * aRate;
        end if;

        -- Mise à jour
        declare
          ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
        begin
          FWK_I_MGT_ENTITY.new(FWK_TYP_PTC_ENTITY.gcPtcTariffTable, ltCRUD_DEF, true);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PTC_TARIFF_TABLE_ID', tplPTC_TARIFF.PTC_TARIFF_TABLE_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TTA_PRICE', lnAmountConvert);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        end;
      end loop;
    end if;
  end UpdateSalesTarifsStd;
end;
