--------------------------------------------------------
--  DDL for Package Body GCO_LIB_QUALITY_STATUS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_QUALITY_STATUS" 
is
  /**
  * Description
  *   Retourne le status de réception du flux pour un produit
  */
  function GetReceiptStatus(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  is
    lResult GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type;
  begin
    if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      begin
        select GCO_QUALITY_STATUS_ID
          into lResult
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = iGoodId
           and CHA_QUALITY_STATUS_MGMT = 1;

        return lResult;
      exception
        when no_data_found then
          return null;
        when too_many_rows then
          ra(replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Plus d''une caractérisation gère le statut qualité [GOO_MAJOR_REFERENCE]')
                   , '[GOO_MAJOR_REFERENCE]'
                   , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId)
                    )
            );
      end;
    else
      return null;
    end if;
  end GetReceiptStatus;

  /**
  * Description
  *   Retourne le status de réception par défaut du flux
  */
  function GetDefaultReceiptStatus(iQualityFlowId in GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type default null)
    return GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  is
    lResult GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type;
  begin
    -- si aucun flux passé en paramètre, on prend le flux par défaut
    select GCO_QUALITY_STATUS_ID
      into lResult
      from GCO_QUALITY_STAT_FLOW
     where (    (    iQualityFlowId is null
                 and QSF_DEFAULT = 1)
            or (GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId) );

    return lResult;
  end GetDefaultReceiptStatus;

  /**
  * Description
  *   Retourne le flux qualité pour un produit
  */
  function GetQualityFlowId(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  is
    lResult GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type;
  begin
    if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      begin
        select GCO_QUALITY_STAT_FLOW_ID
          into lResult
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = iGoodId
           and CHA_QUALITY_STATUS_MGMT = 1;

        return lResult;
      exception
        when no_data_found then
          return null;
        when too_many_rows then
          ra(replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Plus d''une caractérisation gère le statut qualité [GOO_MAJOR_REFERENCE]')
                   , '[GOO_MAJOR_REFERENCE]'
                   , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId)
                    )
            );
      end;
    else
      return null;
    end if;
  end GetQualityFlowId;

  /**
  * Description
  *   Retourne le flux qualité par défaut
  */
  function GetDefaultFlowId
    return GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  is
    lResult GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type;
  begin
    begin
      select GCO_QUALITY_STAT_FLOW_ID
        into lResult
        from GCO_QUALITY_STAT_FLOW
       where QSF_DEFAULT = 1;
    exception
      when no_data_found then
        lResult  := null;
    end;

    return lResult;
  end GetDefaultFlowId;

  /**
  * function GetCategoryFlowId
  * Description
  *   Retourne le flux qualité défini sur la catégorie de biens
  */
  function GetCategoryFlowId(iCategoryID in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type)
    return GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  is
    lResult GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type;
  begin
    begin
      select GCO_QUALITY_STAT_FLOW_ID
        into lResult
        from GCO_GOOD_CATEGORY
       where GCO_GOOD_CATEGORY_ID = iCategoryID;
    exception
      when no_data_found then
        lResult  := null;
    end;

    return lResult;
  end GetCategoryFlowId;

  /**
  * function GetDefaultGoodFlowId
  * Description
  *   Retourne le flux qualité par défaut pour un produit
  *   Règles : 1. Récupérer le flux sur la catégorie de biens
  *            2. Récupérer le flux par défaut
  */
  function GetDefaultGoodFlowId(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  is
    lResult GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type;
  begin
    -- 1. Récupérer le flux sur la catégorie de biens
    lResult  := GCO_LIB_QUALITY_STATUS.GetCategoryFlowId(FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_GOOD', 'GCO_GOOD_CATEGORY_ID', iGoodID) );

    -- Récupérer le flux par défaut
    if lResult is null then
      lResult  := GCO_LIB_QUALITY_STATUS.GetDefaultFlowId;
    end if;

    return lResult;
  end GetDefaultGoodFlowId;

  /**
  * Description
  *   Indique si le tuple statut de,statut à est défini pour le flux donné
  *
  */
  function isDefinedFlowStatuses(
    iQualityFlowId in GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  , iFromStatusId  in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  , iToStatusId    in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  )
    return number
  is
    lnResult number;
  begin
    select count(*)
      into lnResult
      from GCO_QUALITY_STAT_FLOW_DET
     where GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId
       and GCO_QUALITY_STAT_FROM_ID = iFromStatusId
       and GCO_QUALITY_STAT_TO_ID = iToStatusId;

    return lnResult;
  end isDefinedFlowStatuses;

  /**
  * Description
  *   Indique s'il existe un flux par défaut différent du flux passé en paramètre
  *
  */
  function DefaultFlowIsDefined(iQualityFlowId in GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type default null)
    return number
  is
    lnResult number;
  begin
    select count(*)
      into lnResult
      from GCO_QUALITY_STAT_FLOW
     where QSF_DEFAULT = 1
       and GCO_QUALITY_STAT_FLOW_ID <> iQualityFlowId;

    return lnResult;
  end DefaultFlowIsDefined;

  /**
  * function GetNegativeRetestStatus
  * Description
  *   Retourne le statut correspondant au résultat négatif pour la ré-analyse
  */
  function GetNegativeRetestStatus(iQualityFlowId in GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type)
    return GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  is
    lStatusID GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type;
  begin
    select min(GCO_QUALITY_STATUS_ID)
      into lStatusID
      from (select QST_FROM.GCO_QUALITY_STATUS_ID
              from GCO_QUALITY_STAT_FLOW_DET QSF
                 , GCO_QUALITY_STATUS QST_FROM
             where QSF.GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId
               and QSF.GCO_QUALITY_STAT_FROM_ID = QST_FROM.GCO_QUALITY_STATUS_ID
               and QST_FROM.QST_NEGATIVE_RETEST_STATUS = 1
            union
            select QST_TO.GCO_QUALITY_STATUS_ID
              from GCO_QUALITY_STAT_FLOW_DET QSF
                 , GCO_QUALITY_STATUS QST_TO
             where QSF.GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId
               and QSF.GCO_QUALITY_STAT_TO_ID = QST_TO.GCO_QUALITY_STATUS_ID
               and QST_TO.QST_NEGATIVE_RETEST_STATUS = 1);

    return lStatusID;
  end GetNegativeRetestStatus;

  /**
  * Description
  *   Indique si le statut peut être défini comme statut de réception
  *
  */
  function isValidReceiptStatus(
    iQualityFlowId in GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  , iStatusId      in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  )
    return number
  is
    lnResult number(1);
  begin
    select sign(count(*) )
      into lnResult
      from GCO_QUALITY_STAT_FLOW_DET
     where GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId
       and GCO_QUALITY_STAT_FROM_ID = iStatusID;

    return lnResult;
  end isValidReceiptStatus;

  /**
  * function isAlreadyDefinedFlowDetail
  * Description
  *   Indique si le tuple statut de,statut à est défini pour le flux donné existe déjà
  */
  function isAlreadyDefinedFlowDetail(
    iQualityFlowId       in GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  , iQualityDetailFlowId in GCO_QUALITY_STAT_FLOW_DET.GCO_QUALITY_STAT_FLOW_DET_ID%type
  , iFromStatusId        in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  , iToStatusId          in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  )
    return number
  is
    lnResult number;
  begin
    select count(*)
      into lnResult
      from GCO_QUALITY_STAT_FLOW_DET
     where GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId
       and GCO_QUALITY_STAT_FLOW_DET_ID <> iQualityDetailFlowId
       and GCO_QUALITY_STAT_FROM_ID = iFromStatusId
       and GCO_QUALITY_STAT_TO_ID = iToStatusId;

    return lnResult;
  end isAlreadyDefinedFlowDetail;

  /**
  * Description
  *   Est-ce que le statut qualité autorise les attributions
  */
  function IsNetworkLinkManagement(iQualityStatusId in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type)
    return number
  is
    lResult number(1) := 1;
  begin
    if     iQualityStatusId is not null
       and STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      select sign(nvl(max(GCO_QUALITY_STATUS_ID), 0) )
        into lResult
        from GCO_QUALITY_STATUS
       where GCO_QUALITY_STATUS_ID = iQualityStatusId
         and QST_USE_FOR_LINK = 1
         and QST_USE_FOR_FORECAST = 1;
    end if;

    return lResult;
  end IsNetworkLinkManagement;

  /**
  * Description
  *   Est-ce que le statut qualité est disponible pour le prévisionnel
  */
  function IsForecastManagement(iQualityStatusId in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type)
    return number
  is
    lResult number(1) := 1;
  begin
    if     iQualityStatusId is not null
       and STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      select sign(nvl(max(GCO_QUALITY_STATUS_ID), 0) )
        into lResult
        from GCO_QUALITY_STATUS
       where GCO_QUALITY_STATUS_ID = iQualityStatusId
         and QST_USE_FOR_FORECAST = 1;
    end if;

    return lResult;
  end IsForecastManagement;

  /**
  * Description
  *   Indique si le flux qualité demande le rafraichissement des attributions
  */
  function getRefreshNetworkLink(
    iGoodID              in     GCO_GOOD.GCO_GOOD_ID%type
  , iQualityFlowID       in     GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  , iQualityStatusFromID in     GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  , iQualityStatusToID   in     GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  , ioDeleteLink         in out GCO_QUALITY_STAT_FLOW_DET.QSF_DELETE_NETWORK_LINK%type
  , ioUpdateLink         in out GCO_QUALITY_STAT_FLOW_DET.QSF_UPDATE_LINK%type
  )
    return number
  is
    lnResult        number(1)                                             := 0;
    lnQualityFlowID GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type;
  begin
    if     (   iQualityFlowID is not null
            or iGoodID is not null)
       and STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      begin
        -- Détermine éventuellement le flux qualité à utiliser.
        if iQualityFlowID is null then
          lnQualityFlowID  := GetQualityFlowId(iGoodID);
        else
          lnQualityFlowID  := iQualityFlowID;
        end if;

        -- Recherche les informations concernant les attributions liées au flux qualité
        select nvl(QSF_DELETE_NETWORK_LINK, 0)
             , nvl(QSF_UPDATE_LINK, 0)
          into ioDeleteLink
             , ioUpdateLink
          from GCO_QUALITY_STAT_FLOW_DET
         where GCO_QUALITY_STAT_FLOW_ID = lnQualityFlowID
           and GCO_QUALITY_STAT_FROM_ID = iQualityStatusFromID
           and GCO_QUALITY_STAT_TO_ID = iQualityStatusToID;

        if    (ioDeleteLink = 1)
           or (ioUpdateLink = 1) then
          lnResult  := 1;
        end if;
      exception
        when no_data_found then
          ioDeleteLink  := 0;
          ioUpdateLink  := 0;
      end;
    end if;

    return lnResult;
  end getRefreshNetworkLink;

  /**
  * function GetQualityStatusRef
  * Description
  *   Retourne la référence d'un statut qualité en tenant compte des traductions
  */
  function GetQualityStatusRef(iQualityStatusID in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type, iUserLangID in PCS.PC_LANG.PC_LANG_ID%type default null)
    return varchar2
  is
    lvReference GCO_QUALITY_STATUS.QST_REFERENCE%type;
  begin
    select nvl(QSD.QSD_REFERENCE, QST.QST_REFERENCE)
      into lvReference
      from GCO_QUALITY_STATUS QST
         , GCO_QUALITY_STAT_DESCR QSD
     where QST.GCO_QUALITY_STATUS_ID = iQualityStatusID
       and QST.GCO_QUALITY_STATUS_ID = QSD.GCO_QUALITY_STATUS_ID(+)
       and QSD.PC_LANG_ID(+) = nvl(iUserLangID, PCS.PC_I_LIB_SESSION.GetUserLangId);

    return lvReference;
  exception
    when others then
      return null;
  end GetQualityStatusRef;

  /**
  * function GetQualityStatusDescr
  * Description
  *   Retourne la description d'un statut qualité en tenant compte des traductions
  */
  function GetQualityStatusDescr(iQualityStatusID in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type, iUserLangID in PCS.PC_LANG.PC_LANG_ID%type default null)
    return varchar2
  is
    lvDescr GCO_QUALITY_STATUS.QST_DESCRIPTION%type;
  begin
    select nvl(QSD.QSD_DESCRIPTION, QST.QST_DESCRIPTION)
      into lvDescr
      from GCO_QUALITY_STATUS QST
         , GCO_QUALITY_STAT_DESCR QSD
     where QST.GCO_QUALITY_STATUS_ID = iQualityStatusID
       and QST.GCO_QUALITY_STATUS_ID = QSD.GCO_QUALITY_STATUS_ID(+)
       and QSD.PC_LANG_ID(+) = nvl(iUserLangID, PCS.PC_I_LIB_SESSION.GetUserLangId);

    return lvDescr;
  exception
    when others then
      return null;
  end GetQualityStatusDescr;

  /**
  * function GetQualityStatusID
  * Description
  *   Retourne l'id d'un statut qualité depuis sa référence en tenant compte des traductions
  */
  function GetQualityStatusID(iReference in GCO_QUALITY_STATUS.QST_DESCRIPTION%type, iUserLangID in PCS.PC_LANG.PC_LANG_ID%type default null)
    return GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  is
    lQualityStatusID GCO_QUALITY_STATUS.QST_DESCRIPTION%type;
  begin
    select QST.GCO_QUALITY_STATUS_ID
      into lQualityStatusID
      from GCO_QUALITY_STATUS QST
         , GCO_QUALITY_STAT_DESCR QSD
     where QST.GCO_QUALITY_STATUS_ID = QSD.GCO_QUALITY_STATUS_ID(+)
       and QSD.PC_LANG_ID(+) = nvl(iUserLangID, PCS.PC_I_LIB_SESSION.GetUserLangId)
       and nvl(QSD.QSD_REFERENCE, QST.QST_REFERENCE) = iReference;

    return lQualityStatusID;
  exception
    when others then
      return null;
  end GetQualityStatusID;
end GCO_LIB_QUALITY_STATUS;
