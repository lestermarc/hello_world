--------------------------------------------------------
--  DDL for Package Body STM_LIB_MOVEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_LIB_MOVEMENT" 
is
  /**
  * function IsPreciousMatMovement
  * Description
  *   Détermine si on a affaire à un mouvement de matières précieuses
  * @created fp 13.02.2012
  * @lastUpdate
  * @public
  * @param iMovementKindId : genre de mouvement
  * @return 0 ou 1
  */
  function IsPreciousMatMovement(iMovementKindId in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type)
    return number
  is
    lResult number(1) := 0;
  begin
    if iMovementKindId is not null then
      select decode(C_MOVEMENT_CODE, '025', 1, '026', 1, 0)
        into lResult
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = iMovementKindId;
    end if;

    return lResult;
  end IsPreciousMatMovement;

  /**
  * function GetFirstInputMvtID
  * Description
  *   Renvoi l'id du 1er mvt d'entrée pour l'id de l'élément correspondant à la valeur de caract. en question
  *     pour une caractérisation géré avec le détail
  */
  function GetUseDetailFirstInputMvtID(iElemNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    return STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  is
    cursor lcrMvt(lElemNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID
          from STM_STOCK_MOVEMENT SMO
             , STM_MOVEMENT_KIND MOK
             , STM_ELEMENT_NUMBER SEM
         where SEM.STM_ELEMENT_NUMBER_ID = lElemNumberID
           and SMO.GCO_GOOD_ID = SEM.GCO_GOOD_ID
           and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
           and MOK.C_MOVEMENT_SORT = 'ENT'
           and (    (    SMO.GCO_CHARACTERIZATION_ID = GCO_LIB_CHARACTERIZATION.GetUseDetailCharID(SEM.GCO_GOOD_ID)
                     and SMO.SMO_CHARACTERIZATION_VALUE_1 = SEM.SEM_VALUE
                    )
                or (    SMO.GCO_GCO_CHARACTERIZATION_ID = GCO_LIB_CHARACTERIZATION.GetUseDetailCharID(SEM.GCO_GOOD_ID)
                    and SMO.SMO_CHARACTERIZATION_VALUE_2 = SEM.SEM_VALUE
                   )
                or (    SMO.GCO2_GCO_CHARACTERIZATION_ID = GCO_LIB_CHARACTERIZATION.GetUseDetailCharID(SEM.GCO_GOOD_ID)
                    and SMO.SMO_CHARACTERIZATION_VALUE_3 = SEM.SEM_VALUE
                   )
                or (    SMO.GCO3_GCO_CHARACTERIZATION_ID = GCO_LIB_CHARACTERIZATION.GetUseDetailCharID(SEM.GCO_GOOD_ID)
                    and SMO.SMO_CHARACTERIZATION_VALUE_4 = SEM.SEM_VALUE
                   )
                or (    SMO.GCO4_GCO_CHARACTERIZATION_ID = GCO_LIB_CHARACTERIZATION.GetUseDetailCharID(SEM.GCO_GOOD_ID)
                    and SMO.SMO_CHARACTERIZATION_VALUE_5 = SEM.SEM_VALUE
                   )
               )
      order by SMO.SMO_MOVEMENT_DATE asc
             , SMO.STM_STOCK_MOVEMENT_ID;

    ltplMvt lcrMvt%rowtype;
    lMvtID  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    open lcrMvt(iElemNumberID);

    fetch lcrMvt
     into ltplMvt;

    if lcrMvt%found then
      lMvtID  := ltplMvt.STM_STOCK_MOVEMENT_ID;
    end if;

    close lcrMvt;

    return lMvtID;
  end GetUseDetailFirstInputMvtID;

  /**
  * procedure GetTransfCharMvtKind
  * Description
  *   Renvoi l'id de type de mvt d'entrée/sortie pour la transformation de caractérisation
  */
  procedure GetTransfCharMvtKind(oInMvtKindID out STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type, oOutMvtKindID out STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type)
  is
  begin
    -- Recherche le mvt d'entrée de type Transformation de caractérisation
    select min(STM_MOVEMENT_KIND_ID)
      into oInMvtKindID
      from STM_MOVEMENT_KIND
     where C_MOVEMENT_CODE = '024'
       and C_MOVEMENT_SORT = 'ENT'
       and C_MOVEMENT_TYPE = 'TRC';

    if oInMvtKindID is not null then
      -- Recherche le mvt associé au mvt d'entrée de type Transformation de caractérisation
      select min(STM_MOVEMENT_KIND_ID)
        into oOutMvtKindID
        from STM_MOVEMENT_KIND
       where STM_STM_MOVEMENT_KIND_ID = oInMvtKindID;

      -- Si pas trouvé mvt de sortie, effacer id du mvt d'entrée
      if oOutMvtKindID is null then
        oInMvtKindID  := null;
      end if;
    end if;
  end GetTransfCharMvtKind;

  /**
  * procedure GetTransformGoodMvtKind
  * Description
  *   Renvoi l'id de type de mvt d'entrée/sortie pour la transfert d'un bien sur en autre (versioning)
  */
  procedure GetTransformGoodMvtKind(
    oInMvtKindID  out STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , oOutMvtKindID out STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  )
  is
  begin
    -- Pour le Moment, on utilise GetTransfCharMvtKind
    GetTransfCharMvtKind(oInMvtKindID => oInMvtKindID, oOutMvtKindID => oOutMvtKindID);
  end GetTransformGoodMvtKind;

  /**
  * Description
  *    Retourne le type de mouvement (C_MOVEMENT_TYPE)
  */
  function GetMovementKindType(iMovementKindId in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type)
    return STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type result_cache
  is
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_MOVEMENT_KIND', 'C_MOVEMENT_TYPE', iMovementKindId);
  end GetMovementKindType;

     /**
  * Description
  *   Test si le bien est OK pour faire un mouvement par rapport à un éventuel inventaire en cours
  */
  function TestGoodStatus(
    iGoodId         in GCO_GOOD.GCO_GOOD_ID%type
  , iMovementKindId in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  , iStockId        in STM_STOCK.STM_STOCK_ID%type default null
  , iLocationId     in STM_LOCATION.STM_LOCATION_ID%type default null
  )
    return varchar2
  is
  begin
    if iMovementKindId is not null then
      -- si on est sur un mouvement de type inventaire, report d'exercice ou valeur, on laisse faire
      if GetMovementKindType(iMovementKindId) in
                                (STM_I_LIB_CONSTANT.gcMovementTypeInventory, STM_I_LIB_CONSTANT.gcMovementTypeExercice, STM_I_LIB_CONSTANT.gcMovementTypeValue) then
        return null;
      end if;
    end if;

    declare
      lGoodStatus GCO_GOOD.C_GOOD_STATUS%type   := GCO_I_LIB_FUNCTIONS.GetGoodStatus(iGoodId);
      lForbidden  number(1);
    begin
      if     lGoodStatus = GCO_I_LIB_CONSTANT.gcGoodStatusActive
         and (GCO_I_LIB_FUNCTIONS.IsGoodInInventory(iGoodId) = 1) then
        if GCO_I_LIB_CONSTANT.gcCfgCInvenFixedStPos then
          return PCS.PC_FUNCTIONS.TranslateWord('Toutes les positions du bien sont bloquées pour inventaire (config GCO_CInven_FIXED_ST_POS).');
        else
          -- recherche si les données complémentaires d'inventaire interdient le mouvement
          select sign(count(*) )
            into lForbidden
            from GCO_COMPL_DATA_INVENTORY
           where GCO_GOOD_ID = iGoodId
             and CIN_FIXED_STOCK_POSITION = 1
             and (   STM_STOCK_ID is null
                  or STM_STOCK_ID = iStockId)
             and (   STM_LOCATION_ID is null
                  or STM_LOCATION_ID = iLocationId);

          if lForbidden = 1 then
            return PCS.PC_FUNCTIONS.TranslateWord('Toutes les positions du bien sont bloquées pour inventaire (données complémentaires d''inventaire).');
          end if;

          if iStockId is not null then
            select sign(count(*) )
              into lForbidden
              from STM_STOCK
             where STM_STOCK_ID = iStockId
               and STO_FIXED_STOCK_POSITION = 1;
          end if;

          if lForbidden = 1 then
            return PCS.PC_FUNCTIONS.TranslateWord('Les positions du bien pour ce stock sont bloquées pour inventaire.');
          end if;

          if iLocationId is not null then
            select sign(count(*) )
              into lForbidden
              from STM_LOCATION
             where STM_LOCATION_ID = iLocationId
               and LOC_FIXED_STOCK_POSITION = 1;
          end if;

          if lForbidden = 1 then
            return PCS.PC_FUNCTIONS.TranslateWord('Les positions du bien pour cet emplacement de stock sont bloquées pour inventaire.');
          end if;

          -- tous les tests sont passés avec succès
          return null;
        end if;
      elsif lGoodStatus = GCO_I_LIB_CONSTANT.gcGoodStatusInactive then
        return PCS.PC_FUNCTIONS.TranslateWord('Le bien n''est pas actif, aucun mouvement n''est permis!');
      elsif lGoodStatus = GCO_I_LIB_CONSTANT.gcGoodStatusSuspended then
        return PCS.PC_FUNCTIONS.TranslateWord('Le bien est suspendu, aucun mouvement n''est permis!');
      elsif lGoodStatus = GCO_I_LIB_CONSTANT.gcGoodStatusArchived then
        return PCS.PC_FUNCTIONS.TranslateWord('Le bien est archivé, aucun mouvement n''est permis!');
      else
        return null;
      end if;
    end;
  end TestGoodStatus;

  /**
  * Description
  *   Test si le bien est OK pour faire un mouvement par rapport à un éventuel inventaire en cours
  */
  function TestGoodStatus(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
    return varchar2
  is
  begin
    return TestGoodStatus(iGoodID           => iotMovementRecord.GCO_GOOD_ID
                        , iStockId          => iotMovementRecord.STM_STOCK_ID
                        , iLocationId       => iotMovementRecord.STM_LOCATION_ID
                        , iMovementKindId   => iotMovementRecord.STM_MOVEMENT_KIND_ID
                         );
  end TestGoodStatus;

  /**
  * Description
  *    Indique si on a affaire à un mouvement de transformation de caractérisation
  */
  function IsCharTransformationMvt(iMovementKindId in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type)
    return number result_cache
  is
  begin
    -- Recherche le mvt d'entrée de type Transformation de caractérisation
    if FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_MOVEMENT_KIND', 'C_MOVEMENT_TYPE', iMovementKindId) = STM_I_LIB_CONSTANT.gcMovementTypeCharTransform then
      return 1;
    else
      return 0;
    end if;
  end IsCharTransformationMvt;

     /**
  * Description
  *   Vérifie si les conditions de stockage doivent être controlées
  */
  function MustControlStorageCondition(
    iGoodID         in GCO_GOOD.GCO_GOOD_ID%type
  , iLocationId     in STM_LOCATION.STM_LOCATION_ID%type
  , iMovementKindId in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  )
    return boolean
  is
  begin
    -- si la config est activée et qu'il ne s'agit pas d'un nouvement de report d'exercice
    if GCO_I_LIB_CONSTANT.gcCfgUseStorageCond and
      GetMovementKindType(iMovementKindId => iMovementKindId) <> STM_I_LIB_CONSTANT.gcMovementTypeExercice then
      -- s'il s'agit d'un mouvement d'entrée
      if    FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_MOVEMENT_KIND', 'C_MOVEMENT_SORT', iMovementKindId) = 'ENT'
         or iMovementKindId is null then
        -- si l'emplacement et le bien gèrent les conditions de stockage
        if     FWK_I_LIB_ENTITY.getBooleanFieldFromPk('STM_LOCATION', 'LOC_CHECK_STORAGE_COND', iLocationId)
           and (GCO_I_LIB_COMPL_DATA.GetStockComplDataTuple(iGoodId => iGoodID, iLocationId => iLocationId).CST_CHECK_STORAGE_COND = 1) then
          return true;
        else
          return false;
        end if;
      else
        return false;
      end if;
    else
      return false;
    end if;
  end MustControlStorageCondition;

  /**
  * Description
  *   procedure standard de vérification des conditions de stockage
  *   Il faut se baser sur cette structure pour réaliser une individualisation
  */
  procedure pVerifyStorageConditions(
    iGoodID        in     GCO_GOOD.GCO_GOOD_ID%type
  , iLocationId    in     STM_LOCATION.STM_LOCATION_ID%type
  , iConditionType in     varchar2
  , oError         out    varchar2
  )
  is
    ltplStockComplData GCO_COMPL_DATA_STOCK%rowtype   := GCO_I_LIB_COMPL_DATA.GetStockComplDataTuple(iGoodId => iGoodID, iLocationId => iLocationId);
    ltplLocation       STM_LOCATION%rowtype;
  begin
    select *
      into ltplLocation
      from STM_LOCATION
     where STM_LOCATION_ID = iLocationId;

    case
      when     nvl(iConditionType, 'DIC_STORAGE_POSITION') = 'DIC_STORAGE_POSITION'
           and ltplStockComplData.DIC_STORAGE_POSITION_ID is not null
           and ltplStockComplData.DIC_STORAGE_POSITION_ID <> nvl(ltplLocation.DIC_STORAGE_POSITION_ID, 'NULL') then
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Position de stockage non conforme.');
      when     nvl(iConditionType, 'DIC_TEMPERATURE') = 'DIC_TEMPERATURE'
           and ltplStockComplData.DIC_TEMPERATURE_ID is not null
           and ltplStockComplData.DIC_TEMPERATURE_ID <> nvl(ltplLocation.DIC_TEMPERATURE_ID, 'NULL') then
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Température de stockage non conforme.');
      when     nvl(iConditionType, 'DIC_RELATIVE_HUMIDITY') = 'DIC_RELATIVE_HUMIDITY'
           and ltplStockComplData.DIC_RELATIVE_HUMIDITY_ID is not null
           and ltplStockComplData.DIC_RELATIVE_HUMIDITY_ID <> nvl(ltplLocation.DIC_RELATIVE_HUMIDITY_ID, 'NULL') then
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Humidité relative de stockage non conforme.');
      when     nvl(iConditionType, 'DIC_LUMINOSITY') = 'DIC_LUMINOSITY'
           and ltplStockComplData.DIC_LUMINOSITY_ID is not null
           and ltplStockComplData.DIC_LUMINOSITY_ID <> nvl(ltplLocation.DIC_LUMINOSITY_ID, 'NULL') then
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Luminosité de stockage non conforme.');
      else
        oError  := null;
    end case;
  end pVerifyStorageConditions;

  /**
  * Description
  *   Vérification des conditions de stockage DEVLOG-16620
  */
  function VerifyStorageConditions(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
    return varchar2
  is
  begin
    return VerifyStorageConditions(iGoodID           => iotMovementRecord.GCO_GOOD_ID
                                 , iLocationId       => iotMovementRecord.STM_LOCATION_ID
                                 , iMovementKindId   => iotMovementRecord.STM_MOVEMENT_KIND_ID
                                  );
  end VerifyStorageConditions;

  /**
  * Description
  *   Vérification des conditions de stockage DEVLOG-16620
  */
  function VerifyStorageConditions(
    iGoodID         in GCO_GOOD.GCO_GOOD_ID%type
  , iLocationId     in STM_LOCATION.STM_LOCATION_ID%type
  , iConditionType  in varchar2 default null
  , iMovementKindId in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  )
    return varchar2
  is
    lError varchar2(255);
  begin
    if MustControlStorageCondition(iGoodID, iLocationId, iMovementKindId) then
      -- si une procedure indiv est déclarée, c'est elle qui se charge du contrôle
      if STM_I_LIB_CONSTANT.gcCfgProcCheckStorageCond is not null then
        execute immediate 'begin' ||
                          chr(13) ||
                          STM_I_LIB_CONSTANT.gcCfgProcCheckStorageCond ||
                          '(:iGoodID, :iLocation, :iConditionType, :oError);' ||
                          chr(13) ||
                          'end;'
                    using in iGoodID, in iLocationId, in iConditionType, in out lError;
      else
        -- Vérification des conditions de stockage
        pVerifyStorageConditions(iGoodID, iLocationId, iConditionType, lError);
      end if;
    end if;

    -- si lError est vide, il n'y a pas d'erreur, sinon la variable contient l'explication du problème
    return lError;
  end VerifyStorageConditions;

  /**
  * Description
  *   Contrôle du statut qualité.
  */
  function VerifyQualityStatus(
    iGoodId          in GCO_GOOD.GCO_GOOD_ID%type
  , iMovementKindId  in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  , iElementNumberId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type default null
  , iQualityStatusId in STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type default null
  , iContext         in varchar2 default null
  )
    return varchar2
  is
    lQualityStatusId STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
  begin
    if    iMovementKindId is not null
       or iContext = 'FORECAST' then
      if iQualityStatusId is not null then
        lQualityStatusId  := iQualityStatusId;
      elsif iElementNumberId is not null then
        lQualityStatusId  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_ELEMENT_NUMBER', 'GCO_QUALITY_STATUS_ID', iElementNumberId);
      else
        lQualityStatusId  := GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(iGoodID);
      end if;

      -- contexte d'un mouvement de stock
      if iMovementKindId is not null then
        -- si le genre de mouvement n'autorise pas le status qualité de la position
        if     lQualityStatusId is not null
           and ExistsNonAllowedMvt(iMovementKindId => iMovementKindId, iQualityStatusID => lQualityStatusId) = 1 then
          return PCS.PC_FUNCTIONS.TranslateWord('Le statut qualité de l''élément à mouvementer n''est pas autorisé avec ce genre de mouvement.');
        end if;
      end if;

      -- contexte du PIC
      if iContext = 'FORECAST' then
        if not FWK_I_LIB_ENTITY.getBooleanFieldFromPk('GCO_QUALITY_STATUS', 'QST_USE_FOR_FORECAST', lQualityStatusId) then
          return PCS.PC_FUNCTIONS.TranslateWord('Le statut qualité n''est pas pris en compte dans le calcul du PIC.');
        end if;
      end if;
    end if;

    return null;
  end VerifyQualityStatus;

  /**
  * Description
  *   Version framework
  */
  function VerifyQualityStatus(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
    return varchar2
  is
  begin
    if     iotMovementRecord.SMO_MOVEMENT_QUANTITY > 0
       and GCO_I_LIB_CHARACTERIZATION.HasQualityStatusManagement(iotMovementRecord.GCO_GOOD_ID) = 1 then
      declare
        lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
          := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => iotMovementRecord.GCO_GOOD_ID
                                                     , iPiece     => iotMovementRecord.SMO_PIECE
                                                     , iSet       => iotMovementRecord.SMO_SET
                                                     , iVersion   => iotMovementRecord.SMO_VERSION
                                                      );
      begin
        return VerifyQualityStatus(iGoodId            => iotMovementRecord.GCO_GOOD_ID
                                 , iMovementKindId    => iotMovementRecord.STM_MOVEMENT_KIND_ID
                                 , iElementNumberId   => lElementNumberId
                                  );
      end;
    else
      -- pas de contrôle -> pas d'erreur à retourner
      return null;
    end if;
  end VerifyQualityStatus;

  /**
  * function ExistsNonAllowedMvt
  * Description
  *   Indique s'il existe déjà un tuple de mvt non autorisé selon les champs définis en paramètre
  */
  function ExistsNonAllowedMvt(
    iMovementKindID  in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , iStockID         in STM_STOCK.STM_STOCK_ID%type default null
  , iQualityStatusID in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type default null
  )
    return number
  is
    lnExists number(1);
  begin
    if iMovementKindID is not null then
      select sign(count(*) )
        into lnExists
        from (select STM_NON_ALLOWED_MOVEMENTS_ID
                from STM_NON_ALLOWED_MOVEMENTS
               where STM_MOVEMENT_KIND_ID = iMovementKindID
                 and (    iStockID is not null
                      and (iStockID = STM_STOCK_ID) )
              union
              select STM_NON_ALLOWED_MOVEMENTS_ID
                from STM_NON_ALLOWED_MOVEMENTS
               where STM_MOVEMENT_KIND_ID = iMovementKindID
                 and (    iQualityStatusID is not null
                      and (iQualityStatusID = GCO_QUALITY_STATUS_ID) ) );

      return lnExists;
    else
      return 0;
    end if;
  end ExistsNonAllowedMvt;

  /**
  * function IsOutdatedMvt
  * Description
  *   Indique si le mouvement qui sera généré sera périmé. La valeur chronologique de la caractérisation testée doit être de type "Péremption".
  */
  function IsOutdatedMvt(
    iGoodID         in GCO_GOOD.GCO_GOOD_ID%type
  , iMovementKindID in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  , iTimeLimitDate  in STM_STOCK_MOVEMENT.SMO_CHRONOLOGICAL%type
  , iMovementDate   in STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type
  , iDocumentID     in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  )
    return number
  is
    lnResult        number(1) := 0;
    lPeremptionDate date;
  begin
    return IsOutdatedMvt(iGoodID            => iGoodId
                       , iMovementKindID    => iMovementKindId
                       , iTimeLimitDate     => iTimeLimitDate
                       , iMovementDate      => iMovementDate
                       , iDocumentID        => iDocumentId
                       , ioPeremptionDate   => lPeremptionDate
                        );
  end IsOutdatedMvt;

  /**
  * function IsOutdatedMvt
  * Description
  *   Indique si le mouvement qui sera généré sera périmé. La valeur chronologique de la caractérisation testée doit être de type "Péremption".
  */
  function IsOutdatedMvt(
    iGoodID          in     GCO_GOOD.GCO_GOOD_ID%type
  , iTimeLimitDate   in     STM_STOCK_MOVEMENT.SMO_CHRONOLOGICAL%type
  , iMovementDate    in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type
  , iLapsingMarge    in     GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type default null
  , iMovementKindID  in     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  , iDocumentID      in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , ioPeremptionDate in out date
  )
    return number
  is
    lnResult      number(1)                                     := 0;
    lLapsingMarge GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type;
  begin
    -- Si pas de type de mouvemment ou si le type de mvt n'autorise pas la qté périmée, on effectue le contrôle. Sinon c'est OK.
    if (   iMovementKindId is null
        or (FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_MOVEMENT_KIND', 'MOK_ALLOW_OUTDATED_QTY', iMovementKindID) ) = 0) then
      if lLapsingMarge is null then
        declare
          lAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type
            := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('DOC_GAUGE'
                                                     , 'C_ADMIN_DOMAIN'
                                                     , FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_GAUGE_ID', iDocumentId)
                                                      );
          lThirdID     DOC_DOCUMENT.PAC_THIRD_ID%type;
        begin
          -- Document du domaine Vente
          if lAdminDomain = '2' then
            lThirdID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'PAC_THIRD_ID', iDocumentId);
          end if;

          lLapsingMarge  := nvl(GCO_I_LIB_CHARACTERIZATION.getLapsingMarge(iGoodID, lThirdID), 0);
        end;
      else
        lLapsingMarge  := iLapsingMarge;
      end if;

      -- Contrôle de la date de péremption - la marge < date mouvement
      lnResult  :=
        GCO_I_LIB_CHARACTERIZATION.IsOutdated(iGoodID            => iGoodID
                                            , iThirdId           => null
                                            , iTimeLimitDate     => iTimeLimitDate
                                            , iDate              => iMovementDate
                                            , iLapsingMarge      => lLapsingMarge
                                            , ioPeremptionDate   => ioPeremptionDate
                                             );
    end if;

    return lnResult;
  end IsOutdatedMvt;

  /**
  * Description
  *   Version framework
  */
  function IsOutdatedMvt(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
    return number
  is
  begin
    if GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(iotMovementRecord.GCO_GOOD_ID) = 1 then
      return IsOutdatedMvt(iGoodID           => iotMovementRecord.GCO_GOOD_ID
                         , iMovementKindID   => iotMovementRecord.STM_MOVEMENT_KIND_ID
                         , iTimeLimitDate    => iotMovementRecord.SMO_CHRONOLOGICAL
                         , iMovementDate     => iotMovementRecord.SMO_MOVEMENT_DATE
                         , iDocumentID       => FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL'
                                                                                    , 'DOC_DOCUMENT_ID'
                                                                                    , iotMovementRecord.DOC_POSITION_DETAIL_ID
                                                                                     )
                          );
    else
      return 0;
    end if;
  end IsOutdatedMvt;

  /**
  * function IsRetestNeeded
  * Description
  *   Contrôle de la date de ré-analyse du mouvement
  */
  function IsRetestNeeded(
    iGoodID         in GCO_GOOD.GCO_GOOD_ID%type
  , iMovementKindID in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , iMovementDate   in STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type
  , iRetestDate     in date
  )
    return number
  is
    lnResult number(1) := 0;
  begin
    -- Si pas de type de mouvement ou que le type de mvt n'autorise pas les produits à ré-analyser, on contrôle. Sinon c'est OK.
    if    iMovementKindID is null
       or FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_MOVEMENT_KIND', 'MOK_ALLOW_QTY_TO_ANALYSE', iMovementKindID) = 0 then
      -- Effectuer le contrôle de la date de ré-analyse
      -- Le mvt a une date de ré-analyse dépassée si :
      --   Config GCO_RETEST_MODE = 0 et Date de retest < Date du mvt
      --     OU  Config GCO_RETEST_MODE = 1 et Date de retest - Marge sur retest < Date du jour
      lnResult  := GCO_I_LIB_CHARACTERIZATION.IsRetestNeeded(iGoodID, iRetestDate, iMovementDate);
    end if;

    return lnResult;
  end IsRetestNeeded;

  /**
  * Description
  *   Version framework
  */
  function IsRetestNeeded(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
    return number
  is
  begin
    if GCO_I_LIB_CHARACTERIZATION.IsRetestManagement(iotMovementRecord.GCO_GOOD_ID) = 1 then
      declare
        lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
          := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => iotMovementRecord.GCO_GOOD_ID
                                                     , iPiece     => iotMovementRecord.SMO_PIECE
                                                     , iSet       => iotMovementRecord.SMO_SET
                                                     , iVersion   => iotMovementRecord.SMO_VERSION
                                                      );
      begin
        if lElementNumberId is not null then
          declare
            lRetestDate STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type
                                                              := FWK_I_LIB_ENTITY.getDateFieldFromPk('STM_ELEMENT_NUMBER', 'SEM_RETEST_DATE', lElementNumberId);
          begin
            return IsRetestNeeded(iGoodID           => iotMovementRecord.GCO_GOOD_ID
                                , iMovementKindID   => iotMovementRecord.STM_MOVEMENT_KIND_ID
                                , iMovementDate     => iotMovementRecord.SMO_MOVEMENT_DATE
                                , iRetestDate       => lRetestDate
                                 );
          end;
        else
          return 0;
        end if;
      end;
    else
      return 0;
    end if;
  end IsRetestNeeded;

  /*
   * function VerifyStockOutputCond
   * Description
   *   Indique si le type de mouvement de sortie est autorisé pour une position des stock
   */
  function VerifyStockOutputCond(
    iGoodID          in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockId         in STM_STOCK_POSITION.STM_STOCK_ID%type
  , iLocationId      in STM_STOCK_POSITION.STM_LOCATION_ID%type
  , iQualityStatusId in STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type
  , iChronological   in STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type
  , iPiece           in STM_STOCK_POSITION.SPO_PIECE%type
  , iSet             in STM_STOCK_POSITION.SPO_SET%type
  , iVersion         in STM_STOCK_POSITION.SPO_VERSION%type
  , iMovementKindId  in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , iMovementDate    in STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type default trunc(sysdate)
  , iCheckAll        in integer default 1
  )
    return varchar2
  is
    lVerifyStorageCondMessage   varchar2(255);
    lVerifyQualityStatusMessage varchar2(255);
    lRetestNeededMessage        varchar2(255);
    lOutdatedMessage            varchar2(255);
    lMess                       varchar2(2000);
    lMovementDate               STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type;
    lElementNumberId            STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lRetestDate                 STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type;
  begin
    /* Retourne null si on ne gère pas les status qualité */
    if not STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      return null;
    end if;

    if ExistsNonAllowedMvt(iMovementKindID, iStockId, iQualityStatusId) <> 0 then
      lMess  := PCS.PC_FUNCTIONS.TranslateWord('Un mouvement de stock de ce genre n''est pas autorisé pour ce stock!');

      if iCheckAll = 0 then
        return lMess;
      end if;
    end if;

    lVerifyStorageCondMessage    := VerifyStorageConditions(iGoodId => iGoodId, iLocationId => iLocationId, iMovementKindId => iMovementKindId);

    if lVerifyStorageCondMessage is not null then
      if iCheckAll = 0 then
        return lVerifyStorageCondMessage;
      else
        lMess  := nvl(lMess, '') || lVerifyStorageCondMessage || chr(13);
      end if;
    end if;

    lMovementDate                := STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(iMovementDate), iMovementDate);

    if     GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(iGoodId) = 1
       and IsOutdatedMvt(iGoodId => iGoodId, iMovementKindID => iMovementKindId, iTimeLimitDate => iChronological, iMovementDate => lMovementDate) = 1 then
      lOutdatedMessage  := PCS.PC_FUNCTIONS.TranslateWord('Produit périmé');

      if lOutdatedMessage is not null then
        if iCheckAll = 0 then
          return lOutdatedMessage;
        else
          lMess  := nvl(lMess, '') || lOutdatedMessage || chr(13);
        end if;
      end if;
    end if;

    lElementNumberId             := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId => iGoodId, iPiece => iPiece, iSet => iSet, iVersion => iVersion);
    lVerifyQualityStatusMessage  := VerifyQualityStatus(iGoodId => iGoodId, iMovementKindId => iMovementKindId, iElementNumberId => lElementNumberId);

    if lVerifyQualityStatusMessage is not null then
      if iCheckAll = 0 then
        return lVerifyQualityStatusMessage;
      else
        lMess  := nvl(lMess, '') || lVerifyQualityStatusMessage || chr(13);
      end if;
    end if;

    if lElementNumberId is not null then
      lRetestDate  := FWK_I_LIB_ENTITY.getDateFieldFromPk('STM_ELEMENT_NUMBER', 'SEM_RETEST_DATE', lElementNumberId);

      if IsRetestNeeded(iGoodId => iGoodId, iMovementKindID => iMovementKindID, iMovementDate => lMovementDate, iRetestDate => lRetestDate) = 1 then
        lRetestNeededMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ré-analyse à effectuer');
      end if;

      if lRetestNeededMessage is not null then
        lMess  := nvl(lMess, '') || lRetestNeededMessage || chr(13);
      end if;
    end if;

    return lMess;
  end VerifyStockOutputCond;

  /*
   * function VerifyStockOutputCond
   * Description
   *   Indique si le type de mouvement de sortie est autorisé pour une position des stock
   */
  function VerifyStockOutputCond(
    iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iMovementKindId  in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  , iMovementDate    in STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type default trunc(sysdate)
  , iCheckAll        in integer default 1
  )
    return varchar2
  is
    lMess   varchar2(2000);

    cursor lcrSPO
    is
      select SPO.GCO_GOOD_ID
           , SPO.STM_STOCK_ID
           , SPO.STM_LOCATION_ID
           , SEM.GCO_QUALITY_STATUS_ID
           , SPO.SPO_CHRONOLOGICAL
           , SPO.SPO_PIECE
           , SPO.SPO_SET
           , SPO.SPO_VERSION
        from STM_STOCK_POSITION SPO
           , STM_ELEMENT_NUMBER SEM
       where SPO.STM_STOCK_POSITION_ID = iStockPositionId
         and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+);

    ltplSPO lcrSPO%rowtype;
  begin
    open lcrSPO;

    fetch lcrSPO
     into ltplSPO;

    if not lcrSPO%found then
      close lcrSPO;

      return('record STM_STOCK_POSITION not found');
    else
      close lcrSPO;
    end if;

    lMess  :=
      VerifyStockOutputCond(iGoodId            => ltplSPO.GCO_GOOD_ID
                          , iStockId           => ltplSPO.STM_STOCK_ID
                          , iLocationId        => ltplSPO.STM_LOCATION_ID
                          , iQualityStatusId   => ltplSPO.GCO_QUALITY_STATUS_ID
                          , iChronological     => ltplSPO.SPO_CHRONOLOGICAL
                          , iPiece             => ltplSPO.SPO_PIECE
                          , iSet               => ltplSPO.SPO_SET
                          , iVersion           => ltplSPO.SPO_VERSION
                          , iMovementKindId    => iMovementKindId
                          , iMovementDate      => iMovementDate
                          , iCheckAll          => iCheckAll
                           );
    return lMess;
  end VerifyStockOutputCond;

  /**
  * Description
  *   Indique si la position des stock doit être prise en compte en mode "prévisionnel" (PIC,CB,TEPS)
  */
  function VerifyForecastStockCond(iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type, iRefDate in date)
    return number
  is
    lVerifyQualityStatusMessage varchar2(255);
    lRetestNeededMessage        varchar2(255);
    lOutdatedMessage            varchar2(255);
    lMess                       varchar2(2000);
  begin
    for ltplSPO in (select SPO.GCO_GOOD_ID
                         , ELE.STM_ELEMENT_NUMBER_ID
                         , ELE.GCO_QUALITY_STATUS_ID
                         , SPO.SPO_CHRONOLOGICAL
                         , ELE.SEM_RETEST_DATE
                      from STM_STOCK_POSITION SPO
                         , STM_ELEMENT_NUMBER ELE
                     where SPO.STM_STOCK_POSITION_ID = iStockPositionId
                       and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = ELE.STM_ELEMENT_NUMBER_ID(+)) loop
      -- Statut qualité
      if STM_LIB_MOVEMENT.VerifyQualityStatus(iGoodId => ltplSPO.GCO_GOOD_ID, iElementNumberId => ltplSPO.STM_ELEMENT_NUMBER_ID, iContext => 'FORECAST') is not null then
        return 0;
      end if;

      -- Péremption
      if     GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(ltplSPO.GCO_GOOD_ID) = 1
         and STM_LIB_MOVEMENT.IsOutdatedMvt(iGoodID          => ltplSPO.GCO_GOOD_ID
                                          , iTimeLimitDate   => ltplSPO.SPO_CHRONOLOGICAL
                                          , iMovementDate    => iRefDate
                                          , iDocumentID      => null
                                           ) = 1 then
        return 0;
      end if;

      -- Ré-analyse
      -- Prise en compte des quantité à réanalyser selon la configuration GCO_RETEST_PREV_MODE
      if not GCO_I_LIB_CONSTANT.gcCfgRetestPrevMode then
        if STM_LIB_MOVEMENT.IsRetestNeeded(iGoodId => ltplSPO.GCO_GOOD_ID, iMovementDate => iRefDate, iRetestDate => ltplSPO.SEM_RETEST_DATE) = 1 then
          return 0;
        end if;
      end if;
    end loop;

    return 1;
  end VerifyForecastStockCond;

  function VerifyForecastStockPosCond(
    iGoodId          STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iPiece           STM_STOCK_POSITION.SPO_PIECE%type
  , iSet             STM_STOCK_POSITION.SPO_SET%type
  , iVersion         STM_STOCK_POSITION.SPO_VERSION%type
  , iChronological   STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type
  , iQualityStatusId STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type default null
  , iElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type default null
  , iDateRequest     date := sysdate
  , iCheckPeremption number := null
  , iLapsingMarge    number := null
  )
    return date
  is
    lbQualityStatus boolean;
    lResult         date;
  begin
    -- Statut qualité
    if    not STM_I_LIB_CONSTANT.gcCfgUseQualityStatus
       or iQualityStatusId is null then
      lbQualityStatus  := true;
    else
      if VerifyQualityStatus(iGoodId => iGoodId, iQualityStatusId => iQualityStatusId, iContext => 'FORECAST') is not null then
        lbQualityStatus  := false;
      else
        lbQualityStatus  := true;
      end if;
    end if;

    if lbQualityStatus then
      lResult  :=
        VerifyValidityDateStockPos(iGoodId            => iGoodId
                                 , iPiece             => iPiece
                                 , iSet               => iSet
                                 , iVersion           => iVersion
                                 , iChronological     => iChronological
                                 , iElementNumberId   => iElementNumberId
                                 , iDateRequest       => iDateRequest
                                 , iCheckPeremption   => iCheckPeremption
                                 , iLapsingMarge      => iLapsingMarge
                                  );
    end if;

    return lResult;
  end VerifyForecastStockPosCond;

  function VerifyValidityDateStockPos(
    iGoodId          STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iPiece           STM_STOCK_POSITION.SPO_PIECE%type
  , iSet             STM_STOCK_POSITION.SPO_SET%type
  , iVersion         STM_STOCK_POSITION.SPO_VERSION%type
  , iChronological   STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type
  , iElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type default null
  , iDateRequest     date := sysdate
  , iCheckPeremption number := null
  , iLapsingMarge    number := null
  )
    return date
  is
    lbChronological             boolean;
    lbRetestDelay               boolean;
    lbTriggerPoint              boolean;
    ln                          number;
    lnElementNumberId           STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lnGCO_CHARACTERIZATION_ID   GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnCHA_LAPSING_MARGE         GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type;
    lnProductWithDatePeremption number;
    ldChronologicalDate         date;
    ldRetestDate                date;
    lnRetestMargin              number;
  begin
    ldChronologicalDate  := null;
    ldRetestDate         := null;
    lnRetestMargin       := 0;

    -- Ré-analyse
    -- Prise en compte des quantité à réanalyser selon la configuration GCO_RETEST_PREV_MODE
    if (   GCO_I_LIB_CONSTANT.gcCfgRetestPrevMode
        or not GCO_I_LIB_CONSTANT.gcCfgChaUseDetail
        or (    iGoodId is null
            and iPiece is null
            and iSet is null
            and iVersion is null)
       ) then
      lbRetestDelay  := true;
    else
      if iElementNumberId is null then
        lnElementNumberId  := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId => iGoodId, iPiece => iPiece, iSet => iSet, iVersion => iVersion);
      else
        lnElementNumberId  := iElementNumberId;
      end if;

      if lnElementNumberId is null then
        lbRetestDelay  := true;
      else
        -- contrôle de la date de réanalyse
        begin
          select ELE.SEM_RETEST_DATE
               , GCO_I_LIB_CHARACTERIZATION.GetRetestMargin(ELE.GCO_GOOD_ID)
            into ldRetestDate
               , lnRetestMargin
            from STM_ELEMENT_NUMBER ELE
           where (    ELE.STM_ELEMENT_NUMBER_ID = lnElementNumberId
                  and GCO_I_LIB_CHARACTERIZATION.IsRetestNeeded(iGoodId => iGoodId, iRetestDate => ELE.SEM_RETEST_DATE, iDate => trunc(iDateRequest) ) = 0
                 );

          lbRetestDelay  := true;

          if GCO_I_LIB_CONSTANT.gcCfgRetestMode then
            -- Config GCO_RETEST_MODE = 1 et Date de retest - Marge sur retest < Date de référence
            ldRetestDate  := ldRetestDate - lnRetestMargin;
          end if;
        exception
          when others then
            begin
              lbRetestDelay  := false;
            end;
        end;
      end if;
    end if;

    if not lbRetestDelay then
      return null;
    end if;

    if iCheckPeremption is null then
      lnCHA_LAPSING_MARGE  := GCO_I_LIB_CHARACTERIZATION.getLapsingMarge(iGoodId);

      if lnCHA_LAPSING_MARGE is not null then
        lnProductWithDatePeremption  := 1;
      else
        lnProductWithDatePeremption  := 0;
        lnCHA_LAPSING_MARGE          := 0;
      end if;
    else
      lnProductWithDatePeremption  := iCheckPeremption;
      lnCHA_LAPSING_MARGE          := nvl(iLapsingMarge, 0);
    end if;

    if (lnProductWithDatePeremption = 0) then
      lbChronological  := true;
    else
      lbChronological  :=
        GCO_I_LIB_CHARACTERIZATION.IsOutdated(iGoodID            => iGoodId
                                            , iThirdId           => null
                                            , iTimeLimitDate     => iChronological
                                            , iDate              => iDateRequest
                                            , iLapsingMarge      => lnCHA_LAPSING_MARGE
                                            , ioPeremptionDate   => ldChronologicalDate
                                             ) = 0;
    end if;

    if not lbChronological then
      return null;
    else
      if ldChronologicalDate is not null then
        if    ldRetestDate is null
           or ldChronologicalDate < ldRetestDate then
          return ldChronologicalDate;
        else
          return ldRetestDate;
        end if;
      elsif ldRetestDate is not null then
        return ldRetestDate;
      else
        return gcInfiniteDate;
      end if;
    end if;
  end VerifyValidityDateStockPos;

  function VerifyValidityDateStockPosId(
    iStockPositionId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iDateRequest     date := sysdate
  , iCheckPeremption number := null
  , iLapsingMarge    number := null
  )
    return date
  is
    lGoodId        STM_STOCK_POSITION.GCO_GOOD_ID%type;
    lPiece         STM_STOCK_POSITION.SPO_PIECE%type;
    lSet           STM_STOCK_POSITION.SPO_SET%type;
    lVersion       STM_STOCK_POSITION.SPO_VERSION%type;
    lChronological STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type;
    lResult        date;
  begin
    select GCO_GOOD_ID
         , SPO_PIECE
         , SPO_SET
         , SPO_VERSION
         , SPO_CHRONOLOGICAL
      into lGoodId
         , lPiece
         , lSet
         , lVersion
         , lChronological
      from STM_STOCK_POSITION
     where STM_STOCK_POSITION_ID = iStockPositionId;

    lResult  :=
      VerifyValidityDateStockPos(iGoodId            => lGoodId
                               , iPiece             => lPiece
                               , iSet               => lSet
                               , iVersion           => lVersion
                               , iChronological     => lChronological
                               , iDateRequest       => iDateRequest
                               , iCheckPeremption   => iCheckPeremption
                               , iLapsingMarge      => iLapsingMarge
                                );
    return lResult;
  end VerifyValidityDateStockPosId;
end STM_LIB_MOVEMENT;
