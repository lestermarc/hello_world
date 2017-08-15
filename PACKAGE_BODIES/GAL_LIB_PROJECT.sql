--------------------------------------------------------
--  DDL for Package Body GAL_LIB_PROJECT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_LIB_PROJECT" 
is
  /**
  * function GetProjectCurrency
  * Description
  *   Renvoi la devise de l'affaire
  * @created NGV 05.06.2012
  * @lastUpdate
  * @public
  * @param iProjectID : id de l'affaire
  * @return id de la devise
  */
  function GetProjectCurrency(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return number
  is
    lnCurrency ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- Rechercher la devise du contrat
    select max(ACS_FINANCIAL_CURRENCY_ID)
      into lnCurrency
      from GAL_CURRENCY_RATE
     where GAL_PROJECT_ID = iProjectID
       and GCT_CONTRACT_CURRENCY = 1;

    -- Renvoyer la monnaie de la société si celle ci n'est pas définie sur l'affaire
    return nvl(lnCurrency, ACS_FUNCTION.GetLocalCurrencyID);
  end GetProjectCurrency;

  /**
  * procedure GetProjectCurrencyRate
  * Description
  *   Renvoi le cours de change d'une devise de l'affaire
  */
  procedure GetProjectCurrencyRate(
    iProjectID  in     GAL_PROJECT.GAL_PROJECT_ID%type
  , iCurrencyID in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , oExchRate   out    GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type
  , oBasePrice  out    GAL_CURRENCY_RATE.GCT_BASE_PRICE%type
  )
  is
  begin
    select GCT_RATE_OF_EXCHANGE
         , GCT_BASE_PRICE
      into oExchRate
         , oBasePrice
      from GAL_CURRENCY_RATE
     where GAL_PROJECT_ID = iProjectID
       and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID;
  exception
    when no_data_found then
      oExchRate   := null;
      oBasePrice  := null;
  end GetProjectCurrencyRate;

  /**
  * function CanChangeCurrency
  * Description
  *   Indique si on peut effectuer des modifs dans les infos des monnaies de l'affaire
  */
  function CanChangeCurrency(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return number
  is
    lnResult   number;
    lvPrjState GAL_PROJECT.C_PRJ_STATE%type;
    lnCount    number;
  begin
    -- Config indiquant la gestion de la monnaie de contrat
    if pcs.pc_config.getconfig('GAL_CURRENCY_CONTRACT_BUDGET') = '1' then
      -- Voir le nbr de lignes de budget l'affaire
      select count(*)
        into lnCount
        from GAL_BUDGET_LINE BLI
           , GAL_BUDGET BDG
       where BDG.GAL_PROJECT_ID = iProjectID
         and BLI.GAL_BUDGET_ID = BDG.GAL_BUDGET_ID;

      -- Voir le nbr de photos à date de l'affaire
      select count(*) + lnCount
        into lnCount
        from GAL_SNAPSHOT
       where GAL_PROJECT_ID = iProjectID;

      -- Si l'affaire possède des lignes de budget ou qu'il y a déjà des photos à date
      --   la monnaie de contrat n'est pas modifiable
      if (lnCount > 0) then
        lnResult  := 0;
      else
        lnResult  := 1;
      end if;
    else
      lnResult  := 1;
    end if;

    return lnResult;
  end CanChangeCurrency;

  /**
  * function CanChangeRates
  * Description
  *   Indique si on peut effectuer des modifs des taux de change
  */
  function CanChangeRates(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return number
  is
    lnResult   number;
    lvPrjState GAL_PROJECT.C_PRJ_STATE%type;
    lnCount    number;
  begin
    -- Rechercher le statut de l'affaire
    select max(C_PRJ_STATE)
      into lvPrjState
      from GAL_PROJECT
     where GAL_PROJECT_ID = iProjectID;

    -- Voir le nbr de photos à date de l'affaire
    select count(*)
      into lnCount
      from GAL_SNAPSHOT
     where GAL_PROJECT_ID = iProjectID;

    -- Si l'affaire est au statut 20 (hmo 17.08.2012) ou plus ou qu'il y a déjà des photos à date
    --  les taux de change ne sont pas modifiables
    if    (lvPrjState > '10')
       or (lnCount > 0) then
      lnResult  := 0;
    else
      lnResult  := 1;
    end if;

    return lnResult;
  end CanChangeRates;

  /**
  * function CurrencyRiskManaged
  * Description
  *   Indique si une affaire est en gestion de risque de change
  * @created AGA 21.07.2013
  * @lastUpdate
  * @public
  * @param iProjectID : id de l'affaire
  * @return 0 : l'affaire n'est pas en gestion de risque de change
  *         1 : l'affaire est en gestion de risque de change
  */
  function CurrencyRiskManaged(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return number
  is
    lnResult number;
  begin
    -- Voir le nbr de couverture de l'affaire
    select sign(count(*) )
      into lnResult
      from GAL_CURRENCY_RISK
     where GAL_PROJECT_ID = iProjectID;

    return lnResult;
  end CurrencyRiskManaged;

  /**
  * function GetRecordProjectID
  * Description
  *   Renvoi l'id d'une affaire en partant d'un id de dossier
  */
  function GetRecordProjectID(iRecordID in DOC_RECORD.DOC_RECORD_ID%type)
    return GAL_PROJECT.GAL_PROJECT_ID%type
  is
    lnProjectID GAL_PROJECT.GAL_PROJECT_ID%type;
    lvRcoType   DOC_RECORD.C_RCO_TYPE%type;
  begin
    -- Rechercher le type du dossier
    select C_RCO_TYPE
      into lvRcoType
      from DOC_RECORD
     where DOC_RECORD_ID = iRecordID;

    -- Rechercher l'id de l'affaire en fonction du type de dossier
    if lvRcoType = '01' then
      select PRJ.GAL_PROJECT_ID
        into lnProjectID
        from GAL_PROJECT PRJ
       where PRJ.DOC_RECORD_ID = iRecordID;
    elsif lvRcoType in('02', '03') then
      select PRJ.GAL_PROJECT_ID
        into lnProjectID
        from GAL_PROJECT PRJ
           , GAL_TASK TSK
       where PRJ.GAL_PROJECT_ID = TSK.GAL_PROJECT_ID
         and TSK.DOC_RECORD_ID = iRecordID;
    elsif lvRcoType = '04' then
      select PRJ.GAL_PROJECT_ID
        into lnProjectID
        from GAL_PROJECT PRJ
           , GAL_BUDGET BDG
       where PRJ.GAL_PROJECT_ID = BDG.GAL_PROJECT_ID
         and BDG.DOC_RECORD_ID = iRecordID;
    elsif lvRcoType = '05' then
      select PRJ.GAL_PROJECT_ID
        into lnProjectID
        from GAL_PROJECT PRJ
           , GAL_TASK TSK
           , GAL_TASK_LINK LNK
       where PRJ.GAL_PROJECT_ID = TSK.GAL_PROJECT_ID
         and LNK.GAL_TASK_ID = TSK.GAL_TASK_ID
         and LNK.DOC_RECORD_ID = iRecordID;
    else
      lnProjectID  := null;
    end if;

    return lnProjectID;
  exception
    when no_data_found then
      return null;
  end GetRecordProjectID;

  /**
  * procedure GetCurrencyRiskVirtual
  * Description
  *   Renvoi l'identifiant de la tranche virtuelle disponible pour la monnaie et le montant passé en paramètre
  * @created AGA 02.07.2012
  * @lastUpdate
  * @public
  * @param iProjectID  : id de l'affaire
  * @param iCurrencyID : id de la devise
  * @param iAmount  : montant à convertir
  * @param oRiskId  : identifiant de la tranche virtuelle GAL_CURRENCY_RISK_VIRTUAL_ID
  * @param oErrorCode  : Code erreur :
                 0      : aucune erreur,
                 1      : aucune tranche virtuelle pour cette monnaie,
                 2      : aucune tranche virtuelle pour ce montant
  */
  procedure GetCurrencyRiskVirtual(
    iProjectID         in     GAL_CURRENCY_RISK_VIRTUAL.GAL_PROJECT_ID%type
  , iC_GAL_RISK_DOMAIN        GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_DOMAIN%type
  , iCurrencyID        in     GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type
  , iAmount            in     GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type
  , oRiskId            out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , oErrorCode         out    number
  )
  is
    lnCount          number;
    lnExchangeRate   GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    lnBasePrice      GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    lnAmountConfig01 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountConfig02 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountConfig03 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountConfig04 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountBase     GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountConfig   GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
  begin
    oRiskId  := null;

    -- premiere recherche d'une TC pour la monnaie et le domaine
    select count(*)
      into lnCount
      from GAL_CURRENCY_RISK_VIRTUAL
     where GAL_PROJECT_ID = iProjectID
       and C_GAL_RISK_DOMAIN = iC_GAL_RISK_DOMAIN
       and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID;

    if lnCount = 0 then
      oErrorCode  := 1;
    else
      ACS_FUNCTION.GetExchangeRate(aDate => sysdate, aCurrency_id => iCurrencyID, aRateType => 1, aExchangeRate => lnExchangeRate, aBasePrice => lnBasePrice);
      lnAmountBase      :=(iAmount *(lnExchangeRate / lnBasePrice) );
      lnAmountConfig01  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_01');
      lnAmountConfig02  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_02');
      lnAmountConfig03  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_03_04');
      lnAmountConfig04  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_03_04');

      begin
        -- premiere recherche d'une TC dont le solde >= au montant paramètré
        select GAL_CURRENCY_RISK_VIRTUAL_ID
             , 0
          into oRiskId
             , oErrorCode
          from (select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- auto-couverture
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = iC_GAL_RISK_DOMAIN
                     and C_GAL_RISK_TYPE = '01'
                     and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID
                     and (    (GCV_BALANCE >= iAmount -(lnAmountConfig01 /(GCV_RATE_OF_EXCHANGE / GCV_BASE_PRICE) ) )
                          or GCV_PCENT = 1)
                union
                select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- hedge
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = iC_GAL_RISK_DOMAIN
                     and C_GAL_RISK_TYPE = '02'
                     and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID
                     and GCV_BALANCE >= iAmount -(lnAmountConfig02 /(GCV_RATE_OF_EXCHANGE / GCV_BASE_PRICE) )
                union
                select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- hors couverture taux fixe
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = iC_GAL_RISK_DOMAIN
                     and C_GAL_RISK_TYPE = '03'
                     and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID
                     and GCV_BALANCE >= iAmount -(lnAmountConfig03 /(GCV_RATE_OF_EXCHANGE / GCV_BASE_PRICE) )
                union
                select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- hors couverture taux spot
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = iC_GAL_RISK_DOMAIN
                     and C_GAL_RISK_TYPE = '04'
                     and GCV_BALANCE >= lnAmountBase - lnAmountConfig04
                order by C_GAL_RISK_TYPE)
         where rownum = 1;
      exception
        when no_data_found then
          oErrorCode  := 2;
      end;
    end if;
  end GetCurrencyRiskVirtual;

  /**
  * procedure GetSaleMultiCurrRiskVirtual
  * Description
  *   Renvoi l'identifiant de la tranche virtuelle pour la monnaie dans le cadre
  *     de la multi couverture en vente
  * @created NGV 02.07.2012
  * @lastUpdate
  * @public
  * @param iProjectID  : id de l'affaire
  * @param iCurrencyID : id de la devise
  * @param oRiskId     : identifiant de la tranche virtuelle GAL_CURRENCY_RISK_VIRTUAL_ID
  * @param oErrorCode  : Code erreur :
                 0     : aucune erreur,
                 1     : aucune tranche virtuelle pour cette monnaie,
                 2     : aucune tranche virtuelle pour ce montant
  */
  procedure GetSaleMultiCurrRiskVirtual(
    iProjectID  in     GAL_CURRENCY_RISK_VIRTUAL.GAL_PROJECT_ID%type
  , iCurrencyID in     GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type
  , oRiskId     out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , oErrorCode  out    number
  )
  is
    lnCount number;
  begin
    oRiskId  := null;

    -- premiere recherche d'une TC pour la monnaie et le domaine
    select count(*)
      into lnCount
      from GAL_CURRENCY_RISK_VIRTUAL
     where GAL_PROJECT_ID = iProjectID
       and C_GAL_RISK_DOMAIN = '2'
       and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID
       and nvl(GCV_AMOUNT, 0) <> 0;

    if lnCount = 0 then
      oErrorCode  := 1;
    else
      begin
        -- premiere recherche d'une TC dont le solde >= au montant paramètré
        select GAL_CURRENCY_RISK_VIRTUAL_ID
             , 0
          into oRiskId
             , oErrorCode
          from (select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- auto-couverture
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = '2'
                     and C_GAL_RISK_TYPE = '01'
                     and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID
                     and nvl(GCV_AMOUNT, 0) <> 0
                union
                select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- hedge
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = '2'
                     and C_GAL_RISK_TYPE = '02'
                     and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID
                     and nvl(GCV_AMOUNT, 0) <> 0
                union
                select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- hors couverture taux fixe
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = '2'
                     and C_GAL_RISK_TYPE = '03'
                     and ACS_FINANCIAL_CURRENCY_ID = iCurrencyID
                     and nvl(GCV_AMOUNT, 0) <> 0
                union
                select   GAL_CURRENCY_RISK_VIRTUAL_ID
                       , C_GAL_RISK_TYPE   -- hors couverture taux spot
                    from GAL_CURRENCY_RISK_VIRTUAL
                   where GAL_PROJECT_ID = iProjectID
                     and C_GAL_RISK_DOMAIN = '2'
                     and C_GAL_RISK_TYPE = '04'
                     and nvl(GCV_AMOUNT, 0) <> 0
                order by C_GAL_RISK_TYPE)
         where rownum = 1;
      exception
        when no_data_found then
          oErrorCode  := 2;
      end;
    end if;
  end GetSaleMultiCurrRiskVirtual;

  /**
  * function CheckCurrencyRiskVirtual
  * Description
  *  Contrôle si la tranche virtuelle dispose du montant passé en paramètre
  * @created AGA 02.07.2012
  * @lastUpdate
  * @public
  * @param iVirtualID  : id de la tranche virtuelle
  * @param iAmount  : montant  à convertir
  * return : 0 = montant de la tranche insuffisante / 1 = montant de la tranche suffisant
  */
  function CheckCurrencyRiskVirtual(
    iVirtualID in GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , iAmount    in GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type
  )
    return number
  is
    lnCount          number;
    lnAmountConfig01 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountConfig02 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountConfig03 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lnAmountConfig04 GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lC_GAL_RISK_TYPE GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
  begin
    select C_GAL_RISK_TYPE
      into lC_GAL_RISK_TYPE
      from GAL_CURRENCY_RISK_VIRTUAL
     where GAL_CURRENCY_RISK_VIRTUAL_ID = iVirtualID;

    lnAmountConfig01  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_01');
    lnAmountConfig02  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_02');
    lnAmountConfig03  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_03_04');
    lnAmountConfig04  := pcs.pc_config.getconfig('GAL_CUR_RISK_AMNT_ADDED_03_04');
    lnCount           := 0;

    if lC_GAL_RISK_TYPE = '01' then   -- auto-couverture
      select count(*)
        into lnCount
        from GAL_CURRENCY_RISK_VIRTUAL
       where GAL_CURRENCY_RISK_VIRTUAL_ID = iVirtualID
         and (    (GCV_BALANCE >= iAmount -(lnAmountConfig01 /(GCV_RATE_OF_EXCHANGE / GCV_BASE_PRICE) ) )
              or GCV_PCENT = 1);
    elsif lC_GAL_RISK_TYPE = '02' then   -- hedge
      select count(*)
        into lnCount
        from GAL_CURRENCY_RISK_VIRTUAL
       where GAL_CURRENCY_RISK_VIRTUAL_ID = iVirtualID
         and GCV_BALANCE >= iAmount -(lnAmountConfig02 /(GCV_RATE_OF_EXCHANGE / GCV_BASE_PRICE) );
    elsif lC_GAL_RISK_TYPE = '03' then   -- hors couverture taux fixe
      select count(*)
        into lnCount
        from GAL_CURRENCY_RISK_VIRTUAL
       where GAL_CURRENCY_RISK_VIRTUAL_ID = iVirtualID
         and GCV_BALANCE >= iAmount -(lnAmountConfig03 /(GCV_RATE_OF_EXCHANGE / GCV_BASE_PRICE) );
    elsif lC_GAL_RISK_TYPE = '04' then   -- hors couverture taux spot
      select count(*)
        into lnCount
        from GAL_CURRENCY_RISK_VIRTUAL
       where GAL_CURRENCY_RISK_VIRTUAL_ID = iVirtualID
         and GCV_BALANCE >= iAmount - lnAmountConfig04;
    end if;

    return lnCount;
  end CheckCurrencyRiskVirtual;

    /**
  * function GetCurrencyRiskData
  * Description
  *   Renvoi les données de la tranche virtuelle disponible pour l'identifiant
  * @created AGA 02.07.2012
  * @lastUpdate
  * @public
  * @param iID  : identifiant de la tranche virtuelle GAL_CURRENCY_RISK_VIRTUAL_ID
  * @param oType : type de couverture
  * @param oRate  : taux unitaire
  * @param oMessage  : Message erreur
  * return : identifiant de la tranche virtuelle GAL_CURRENCY_RISK_VIRTUAL_ID
  */
  procedure GetCurrencyRiskData(
    ioID  in out GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , oType out    GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type
  , oRate out    GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type
  , oBase out    GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type
  )
  is
  begin
    begin
      select C_GAL_RISK_TYPE
           , GCV_RATE_OF_EXCHANGE
           , GCV_BASE_PRICE
        into oType
           , oRate
           , oBase
        from GAL_CURRENCY_RISK_VIRTUAL
       where GAL_CURRENCY_RISK_VIRTUAL_ID = ioID;
    exception
      when no_data_found then
        ioID   := null;
        oType  := null;
        oRate  := null;
    end;

    null;
  end GetCurrencyRiskData;

   /**
  * function GetLogisticCurrRiskData
  * Description
  *   Renvoi les données de la tranche virtuelle disponible pour l'identifiant d'un document logistique
  * @created AGA 02.07.2012
  * @lastUpdate
  * @public
  * @param iDocumentID : IDentifiant du document logistique
  * @param iAmount     : Montant HT en monnaie du document
  * @param oRiskId     : identifiant de la tranche virtuelle GAL_CURRENCY_RISK_VIRTUAL_ID
  * @param oRiskType   : type de couverture
  * @param oRiskUnit   : taux
  * @param oRiskBase   : base du taux
  * @param oErrorCode  : Code erreur :
                 0      : aucune erreur,
                 1      : aucune tranche virtuelle pour cette monnaie,
                 2      : aucune tranche virtuelle pour ce montant
  */
  procedure GetLogisticCurrRiskData(
    iDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iAmount     in     GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type
  , oRiskId     out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , oRiskType   out    GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type
  , oRiskRate   out    GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type
  , oRiskBase   out    GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type
  , oErrorCode  out    number
  )
  is
    lProjectId         GAL_CURRENCY_RISK_VIRTUAL.GAL_PROJECT_ID%type;
    lProjectCount      number;
    lCurrencyID        GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type;
    lC_GAL_RISK_DOMAIN GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_DOMAIN%type;
  begin
    select DMT.ACS_FINANCIAL_CURRENCY_ID
         , GAU.C_ADMIN_DOMAIN
      into lCurrencyId
         , lC_GAL_RISK_DOMAIN
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
     where DMT.DOC_DOCUMENT_ID = iDocumentID
       and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    -- Recherche de l'affaire
    GAL_LIB_PROJECT.GetLogisticRiskProjectID(iDocumentID => iDocumentID, oProjectID => lProjectID, oProjectCount => lProjectCount);

    -- Document de vente en multi-couverture
    if DOC_I_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(iDocumentID) = 1 then
      GetSaleMultiCurrRiskVirtual(iProjectID => lProjectID, iCurrencyID => lCurrencyID, oRiskId => oRiskId, oErrorCode => oErrorCode);
    else
      -- Recherche de la tranche virtuelle
      GetCurrencyRiskVirtual(lProjectID, lC_GAL_RISK_DOMAIN, lCurrencyID, iAmount, oRiskId, oErrorCode);
    end if;

    if nvl(oRiskId, 0) > 0 then
      GetCurrencyRiskData(oRiskId, oRiskType, oRiskRate, oRiskBase);

      if oRiskType = '04' then   -- hors couverture taux spot -> COURS DU JOUR
        ACS_FUNCTION.GetExchangeRate(aDate => sysdate, aCurrency_id => lCurrencyID, aRateType => 1, aExchangeRate => oRiskRate, aBasePrice => oRiskBase);
      end if;
    end if;
  end GetLogisticCurrRiskData;

   /**
  * function GetFinancialCurrencyRiskData
   * Description
  *   Renvoi les données de la tranche virtuelle disponible pour l'identifiant d'un document comptable
  * @created AGA 02.07.2012
  * @lastUpdate
  * @public
  * @param iDoc_ID : IDentifiant du document comptable
  * @param iRecordId : Identifiant dossier
  * @param iAmount: Montant HT en monnaie du document
  * @param oRiskId  : identifiant de la tranche virtuelle GAL_CURRENCY_RISK_VIRTUAL_ID
  * @param oRiskType : type de couverture
  * @param oRiskUnit  : taux
  * @param oRiskBase  : base du taux
  * @param oErrorCode  : Code erreur :
                 0      : aucune erreur,
                 1      : aucune tranche virtuelle pour cette monnaie,
                 2      : aucune tranche virtuelle pour ce montant
  */
  procedure GetFinancialCurrencyRiskData(
    iDoc_ID    in     ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
  , iRecordId  in     ACT_FINANCIAL_IMPUTATION.DOC_RECORD_ID%type
  , iAmount    in     GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type
  , iFinCurrId in     GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type
  , oRiskId    out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , oRiskType  out    GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type
  , oRiskRate  out    GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type
  , oRiskBase  out    GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type
  , oErrorCode out    number
  )
  is
    lProjectId         GAL_CURRENCY_RISK_VIRTUAL.GAL_PROJECT_ID%type;
    lC_GAL_RISK_DOMAIN GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_DOMAIN%type;
  begin
    select GetRecordProjectID(iRecordId)
         , CDO.C_ADMIN_DOMAIN
      into lProjectId
         , lC_GAL_RISK_DOMAIN
      from ACT_DOCUMENT DOC
         , ACJ_CATALOGUE_DOCUMENT CDO
     where DOC.ACT_DOCUMENT_ID = iDoc_ID
       and CDO.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;

    -- Recherche de la tranche virtuelle
    GetCurrencyRiskVirtual(lProjectID, lC_GAL_RISK_DOMAIN, iFinCurrId, iAmount, oRiskId, oErrorCode);

    if nvl(oRiskId, 0) > 0 then
      GetCurrencyRiskData(oRiskId, oRiskType, oRiskRate, oRiskBase);

      if oRiskType = '04' then   -- hors couverture taux spot -> COURS DU JOUR
        ACS_FUNCTION.GetExchangeRate(aDate => sysdate, aCurrency_id => iFinCurrId, aRateType => 1, aExchangeRate => oRiskRate, aBasePrice => oRiskBase);
      end if;
    end if;
  end GetFinancialCurrencyRiskData;

  /**
  * function GetFinancialVirtualId
   * Description
  *   Renvoi l'id de la tranche virtuelle concernée par le document donné
  * @created SKalayci 17.09.2013
  * @lastUpdate
  * @public
  * @param iDoc_ID   : IDentifiant du document comptable
  * @param iRecordId : Identifiant dossier  imputation
  * @param iFinCurrId: Identifiant devise
  * @param oRiskType : Type de couverture
  * @param oRiskId   : Identifiant tranche virtuelle
  */
  procedure GetImpFinancialVirtualId(
    iDoc_ID    in     ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
  , iRecordId  in     ACT_FINANCIAL_IMPUTATION.DOC_RECORD_ID%type
  , iFinCurrId in     GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type
  , iRiskType  in     GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type
  , oRiskId    out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  )
  is
    lProjectId         GAL_CURRENCY_RISK_VIRTUAL.GAL_PROJECT_ID%type;
    lC_GAL_RISK_DOMAIN GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_DOMAIN%type;
  begin
    --Recherche du domaine du document et du projet du dossier donné
    select GetRecordProjectID(iRecordId)
         , CDO.C_ADMIN_DOMAIN
      into lProjectId
         , lC_GAL_RISK_DOMAIN
      from ACT_DOCUMENT DOC
         , ACJ_CATALOGUE_DOCUMENT CDO
     where DOC.ACT_DOCUMENT_ID = iDoc_ID
       and CDO.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;

    -- Recherche de la tranche virtuelle
    select nvl(max(GAL_CURRENCY_RISK_VIRTUAL_ID), 0)
      into oRiskId
      from GAL_CURRENCY_RISK_VIRTUAL
     where GAL_PROJECT_ID = lProjectId
       and C_GAL_RISK_DOMAIN = lC_GAL_RISK_DOMAIN
       and C_GAL_RISK_TYPE = iRiskType
       and ACS_FINANCIAL_CURRENCY_ID = iFinCurrId;
  end GetImpFinancialVirtualId;

   /**
  * function GetActFinancialVirtualId
   * Description
  *   Renvoi l'id de la tranche virtuelle concernée par le document donné
  * @created SKalayci 17.09.2013
  * @lastUpdate
  * @public
  * @param iDoc_ID   : IDentifiant du document comptable
  * @param iRecordId : Identifiant dossier  imputation
  * @param iFinCurrId: Identifiant devise
  * @param oRiskType : Type de couverture
  * @param oRiskId   : Identifiant tranche virtuelle
  */
  procedure GetActFinancialVirtualId(
    iCatId     in     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , iRecordId  in     ACT_FINANCIAL_IMPUTATION.DOC_RECORD_ID%type
  , iFinCurrId in     GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type
  , iRiskType  in     GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type
  , oRiskId    out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  )
  is
    lProjectId         GAL_CURRENCY_RISK_VIRTUAL.GAL_PROJECT_ID%type;
    lC_GAL_RISK_DOMAIN GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_DOMAIN%type;
  begin
    --Recherche du domaine du document et du projet du dossier donné
    select GetRecordProjectID(iRecordId)
         , CDO.C_ADMIN_DOMAIN
      into lProjectId
         , lC_GAL_RISK_DOMAIN
      from ACJ_CATALOGUE_DOCUMENT CDO
     where CDO.ACJ_CATALOGUE_DOCUMENT_ID = iCatId;

    -- Recherche de la tranche virtuelle
    select nvl(max(GAL_CURRENCY_RISK_VIRTUAL_ID), 0)
      into oRiskId
      from GAL_CURRENCY_RISK_VIRTUAL
     where GAL_PROJECT_ID = lProjectId
       and C_GAL_RISK_DOMAIN = lC_GAL_RISK_DOMAIN
       and C_GAL_RISK_TYPE = iRiskType
       and ACS_FINANCIAL_CURRENCY_ID = iFinCurrId;
  end GetActFinancialVirtualId;

  /**
  * procedure GetLogisticRiskProjectID
  * Description
  *   Renvoi l'id de l'affaire liée au document logistique
  * @created ngv 25.09.2013
  * @lastUpdate
  * @public
  * @param iDocumentID       : document à contrôler
  * @param oProjectID        : id de l'affaire du risque de change (vide si pas risque de change ou plusieurs affaires )
  * @param oProjectCount     : nbre d'affaire gérées en risque de change liées au document
  */
  procedure GetLogisticRiskProjectID(
    iDocumentID   in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oProjectID    out    GAL_PROJECT.GAL_PROJECT_ID%type
  , oProjectCount out    number
  )
  is
  begin
    oProjectID     := null;
    oProjectCount  := 0;

    -- Recherche l'affaire qui possède une couverture pour la monnaie du document
    --  attention : dans cette cmd sert à savoir si au moins une (il peut y en avoir plusieurs) affaire contient la couverture de la monnaie
    select max(PRJ.GAL_PROJECT_ID)
      into oProjectID
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
         , GAL_CURRENCY_RISK GCK
         , (select distinct GAL_LIB_PROJECT.GetRecordProjectID(DOC_RECORD_ID) as GAL_PROJECT_ID
                       from (select POS.DOC_RECORD_ID
                               from DOC_POSITION POS
                              where POS.DOC_DOCUMENT_ID = iDocumentID
                                and POS.DOC_RECORD_ID is not null
                                and POS.C_GAUGE_TYPE_POS not in('4', '6') ) ) PRJ
     where DMT.DOC_DOCUMENT_ID = iDocumentID
       and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and GCK.GAL_PROJECT_ID = PRJ.GAL_PROJECT_ID
       and DMT.ACS_FINANCIAL_CURRENCY_ID = GCK.ACS_FINANCIAL_CURRENCY_ID
       and GCK.C_GAL_RISK_DOMAIN = GAU.C_ADMIN_DOMAIN;

    -- Si le document est couvert par une affaire, vérifier que le doc ne soit lié uniquement à cette affaire
    -- Car il n’est pas autorisé d’avoir des documents multi affaires si au moins une des affaires
    --   est couverte par une tranche de TC dans la monnaie considérée.
    if oProjectID is not null then
      select count(*)
        into oProjectCount
        from (select distinct GAL_LIB_PROJECT.GetRecordProjectID(DOC_RECORD_ID) as GAL_PROJECT_ID
                         from (select POS.DOC_RECORD_ID
                                 from DOC_POSITION POS
                                where POS.DOC_DOCUMENT_ID = iDocumentID
                                  and POS.DOC_RECORD_ID is not null
                                  and POS.C_GAUGE_TYPE_POS not in('4', '6') ) );
    end if;

    -- Si plusieurs affaires sur le doc, ne pas renvoyer l'affaire qui couvre le doc
    if oProjectCount > 1 then
      oProjectID  := null;
    end if;
  end GetLogisticRiskProjectID;

  /**
  * function GetLogisticRiskProjectID
  * Description
  *   Renvoi l'id de l'affaire liée au document logistique
  */
  function GetLogisticRiskProjectID(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return GAL_PROJECT.GAL_PROJECT_ID%type
  is
    lProjectID     GAL_PROJECT.GAL_PROJECT_ID%type;
    lnProjectCount number(12);
  begin
    GetLogisticRiskProjectID(iDocumentID => iDocumentID, oProjectID => lProjectID, oProjectCount => lnProjectCount);
    return lProjectID;
  end GetLogisticRiskProjectID;

  /**
  * function GetRecordList
  * Description
  *   Renvoi une liste d'id de dossiers liés à l'affaire, budget/task de l'affaire liée au document logistique
  */
  function GetRecordList(
    iProjectID            in GAL_PROJECT.GAL_PROJECT_ID%type
  , iBudgetID             in GAL_BUDGET.GAL_BUDGET_ID%type default null
  , iTaskID               in GAL_TASK.GAL_TASK_ID%type default null
  , iIncludeProjectRecord in number default 1
  )
    return ID_TABLE_TYPE
  is
    cursor lcrTask
    is
      select distinct DOC_RECORD_ID
                 from (select TAL.DOC_RECORD_ID
                         from GAL_TASK TAL
                        where TAL.GAL_TASK_ID = iTaskID
                          and TAL.DOC_RECORD_ID is not null
                       union
                       select TAL.DOC_RECORD_ID
                         from GAL_TASK_LINK TAL
                        where TAL.GAL_TASK_ID = iTaskID
                          and TAL.DOC_RECORD_ID is not null);

    cursor lcrBudget
    is
      select distinct DOC_RECORD_ID
                 from (select DOC_RECORD_ID
                         from GAL_BUDGET
                        where GAL_BUDGET_ID = iBudgetID
                          and DOC_RECORD_ID is not null
                       union
                       select DOC_RECORD_ID
                         from GAL_BUDGET
                        where GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                     from GAL_BUDGET
                                                    where GAL_PROJECT_ID = iProjectID
                                               connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
                                               start with GAL_FATHER_BUDGET_ID = iBudgetID)
                          and DOC_RECORD_ID is not null
                       union
                       select DOC_RECORD_ID
                         from GAL_TASK
                        where GAL_BUDGET_ID = iBudgetID
                          and DOC_RECORD_ID is not null
                       union
                       select DOC_RECORD_ID
                         from GAL_TASK
                        where GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                     from GAL_BUDGET
                                                    where GAL_PROJECT_ID = iProjectID
                                               connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
                                               start with GAL_FATHER_BUDGET_ID = iBudgetID)
                          and DOC_RECORD_ID is not null
                       union
                       select TAL.DOC_RECORD_ID
                         from GAL_TASK_LINK TAL
                            , GAL_TASK TAS
                        where TAS.GAL_BUDGET_ID = iBudgetID
                          and TAL.GAL_TASK_ID = TAS.GAL_TASK_ID
                          and TAL.DOC_RECORD_ID is not null
                       union
                       select TAL.DOC_RECORD_ID
                         from GAL_TASK_LINK TAL
                            , GAL_TASK TAS
                        where TAS.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                         from GAL_BUDGET
                                                        where GAL_PROJECT_ID = iProjectID
                                                   connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
                                                   start with GAL_FATHER_BUDGET_ID = iBudgetID)
                          and TAL.GAL_TASK_ID = TAS.GAL_TASK_ID
                          and TAL.DOC_RECORD_ID is not null);

    cursor lcrProject
    is
      select distinct DOC_RECORD_ID
                 from (select BDG.DOC_RECORD_ID
                         from GAL_BUDGET BDG
                        where BDG.GAL_PROJECT_ID = iProjectID
                          and BDG.DOC_RECORD_ID is not null
                       union
                       select TAS.DOC_RECORD_ID
                         from GAL_TASK TAS
                        where TAS.GAL_PROJECT_ID = iProjectID
                          and TAS.DOC_RECORD_ID is not null
                       union
                       select TAL.DOC_RECORD_ID
                         from GAL_TASK_LINK TAL
                            , GAL_TASK TAS
                        where TAS.GAL_PROJECT_ID = iProjectID
                          and TAL.GAL_TASK_ID = TAS.GAL_TASK_ID
                          and TAL.DOC_RECORD_ID is not null
                       union
                       select PRJ.DOC_RECORD_ID
                         from GAL_PROJECT PRJ
                        where PRJ.GAL_PROJECT_ID = iProjectID
                          and PRJ.DOC_RECORD_ID is not null
                          and iIncludeProjectRecord = 1);

    lnRecordList ID_TABLE_TYPE;
  begin
    if iBudgetID is not null then
      open lcrBudget;

      fetch lcrBudget
      bulk collect into lnRecordList;

      close lcrBudget;
    elsif iTaskID is not null then
      open lcrTask;

      fetch lcrTask
      bulk collect into lnRecordList;

      close lcrTask;
    elsif iProjectID is not null then
      open lcrProject;

      fetch lcrProject
      bulk collect into lnRecordList;

      close lcrProject;
    end if;

    return lnRecordList;
  end GetRecordList;
end GAL_LIB_PROJECT;
