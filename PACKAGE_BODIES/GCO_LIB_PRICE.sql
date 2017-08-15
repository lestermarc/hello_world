--------------------------------------------------------
--  DDL for Package Body GCO_LIB_PRICE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_PRICE" 
is
  -- C_ADMIN_DOMAIN
  gcAdminDomainPurchase    constant char(1) := '1';
  gcAdminDomainSale        constant char(1) := '2';
  gcAdminDomainStock       constant char(1) := '3';
  gcAdminDomainFAL         constant char(1) := '4';
  gcAdminDomainSubContract constant char(1) := '5';
  gcAdminDomainQuality     constant char(1) := '6';
  gcAdminDomainASA         constant char(1) := '7';
  gcAdminDomainInventory   constant char(1) := '8';
  -- C_MANAGEMENT_MODE
  gcManagementModePRCS     constant char(1) := '1';
  gcManagementModePRC      constant char(1) := '2';
  gcManagementModePRF      constant char(1) := '3';

  /**
  * Function GetCostPriceAtDate
  * Description
  *     Renvoie le prix de revient à une date précise
  *     par rapport au mode de gestion du produit
  *     Contrairement à la fonction GetCostPriceWithManagementMode,  GetCostPriceAtDate
  *     prend en compte la date passée en paramètre lors de la recherche du PRCS
  * @created fpe 01.12.2011
  * @lastUpdate
  * @public
  * @API
  * @param iGoodID  : id du bien
  * @param iThirdId : id du tiers (facultatif)
  * @param iManagementMode : type de gestion de prix (si vide, on prend le type de gestion défini au niveau du bien)
  *                          (1 PRCS, 2 PRC, 3 PRF, 4 prix dernier mouvement)
  * @param iDateRef        : date de  référence pour la recherche du prix de revient
  * @return   :  prix unitaire du bien en monnaie de base
  */
  function GetCostPriceAtDate(
    iGoodID         in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdId        in number default null
  , iManagementMode in varchar2 default null
  , iDateRef        in date default null
  )
    return number
  is
    lManagementMode GCO_GOOD.C_MANAGEMENT_MODE%type;
    lCostlPrice     number;
    lDateRef        date                              := nvl(iDateRef, sysdate);
  begin
    -- Recherche du mode de gestion
    lManagementMode  := nvl(iManagementMode, GCO_LIB_FUNCTIONS.getManagementMode(iGoodID) );

    -- Recherche du prix de revient calculé standard
    if lManagementMode = gcManagementModePRCS then
      if iDateRef is null then
        -- si aucune date n'est passée en paramètre, on retourne le PRCS actuel
        select nvl(max(GOO_BASE_COST_PRICE), 0)
          into lCostlPrice
          from GCO_GOOD_CALC_DATA
         where GCO_GOOD_ID = iGoodID;
      else
        -- si une date est passée en paramètre, on retourne le PRCS actuel
        for ltplMovements in (select   SMO_PRCS_AFTER
                                  from STM_STOCK_MOVEMENT
                                 where GCO_GOOD_ID = iGoodId
                                   and SMO_VALUE_DATE < trunc(lDateRef) + 1
                              order by SMO_VALUE_DATE desc
                                     , STM_STOCK_MOVEMENT_ID desc) loop
          return ltplMovements.SMO_PRCS_AFTER;
        end loop;

        -- si rien trouvé dans la boucle
        return 0;
      end if;
    -- Recherche du prix de revient calculé
    elsif lManagementMode = gcManagementModePRC then
      -- Recherche pour le tiers (si renseigné)
      if iThirdId is not null then
        select max(CPR_PRICE)
          into lCostlPrice
          from PTC_CALC_COSTPRICE
         where GCO_GOOD_ID = iGoodID
           and PAC_THIRD_ID = iThirdId
           and CPR_DEFAULT = 1;
      end if;

      -- Recherche prix "public" si pas trouvé de prix pour le tiers
      if lCostlPrice is null then
        select max(CPR_PRICE)
          into lCostlPrice
          from PTC_CALC_COSTPRICE
         where GCO_GOOD_ID = iGoodID
           and PAC_THIRD_ID is null
           and CPR_DEFAULT = 1;
      end if;
    -- Recherche du prix de revient fixe
    elsif lManagementMode = gcManagementModePRF then
      -- Recherche pour le tiers (si renseigné)
      if iThirdId is not null then
        -- 1. PRF du tiers pour la date demandée (PRF par défaut en 1er)
        for ltplPRF in (select   CPR_PRICE
                            from PTC_FIXED_COSTPRICE
                           where GCO_GOOD_ID = iGoodID
                             and PAC_THIRD_ID = iThirdId
                             and trunc(lDateRef) between nvl(trunc(FCP_START_DATE), to_date('01.01.0001', 'DD.MM.YYYY') )
                                                     and nvl(trunc(FCP_END_DATE), to_date('31.12.2999', 'DD.MM.YYYY') )
                        order by CPR_DEFAULT desc) loop
          return ltplPRF.CPR_PRICE;
        end loop;

        -- 2. PRF du tiers sans tenir compte de la date demandée (PRF par défaut en 1er)
        for ltplPRF in (select   CPR_PRICE
                            from PTC_FIXED_COSTPRICE
                           where GCO_GOOD_ID = iGoodID
                             and PAC_THIRD_ID = iThirdId
                             and CPR_DEFAULT = 1
                        order by CPR_DEFAULT desc) loop
          return ltplPRF.CPR_PRICE;
        end loop;
      end if;

      -- 3. PRF "public" pour la date demandée (PRF par défaut en 1er)
      for ltplPRF in (select   CPR_PRICE
                          from PTC_FIXED_COSTPRICE
                         where GCO_GOOD_ID = iGoodID
                           and PAC_THIRD_ID is null
                           and trunc(lDateRef) between nvl(trunc(FCP_START_DATE), to_date('01.01.0001', 'DD.MM.YYYY') )
                                                   and nvl(trunc(FCP_END_DATE), to_date('31.12.2999', 'DD.MM.YYYY') )
                      order by CPR_DEFAULT desc) loop
        return ltplPRF.CPR_PRICE;
      end loop;

      -- 4. PRF "public" sans tenir compte de la date demandée (PRF par défaut en 1er)
      for ltplPRF in (select   CPR_PRICE
                          from PTC_FIXED_COSTPRICE
                         where GCO_GOOD_ID = iGoodID
                           and PAC_THIRD_ID is null
                      order by CPR_DEFAULT desc) loop
        return ltplPRF.CPR_PRICE;
      end loop;
    end if;

    return nvl(lCostlPrice, 0);
  end GetCostPriceAtDate;

  /**
  * Description
  *    Renvoie le prix de revient par rapport au mode de gestion du produit
  */
  function GetCostPriceWithManagementMode(
    iGCO_GOOD_ID    in GCO_GOOD.GCO_GOOD_ID%type
  , iPAC_THIRD_ID   in number default null
  , iManagementMode in varchar2 default null
  , iDateRef        in date default null
  )
    return number
  is
  begin
    -- suite à la tâche DEVERP-20363, plus aucune différence entre les 2 fonctions
    return GetCostPriceAtDate(iGCO_GOOD_ID, iPAC_THIRD_ID, iManagementMode, iDateRef);
  end GetCostPriceWithManagementMode;

  /**
  * Description
  *   recherche le prix du dernier mouvement d'entrée
  */
  function GetLastInputPrice(iGoodId number)
    return STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type
  is
    cursor lcurMvtLastDate(ciGoodId number)
    is
      select   up.SMO_UNIT_PRICE
          from STM_STOCK_MOVEMENT up
             , STM_MOVEMENT_KIND MOK1
         where up.GCO_GOOD_ID = ciGoodId
           and up.SMO_MOVEMENT_DATE = (select max(SMO_MOVEMENT_DATE)
                                         from STM_STOCK_MOVEMENT SMO
                                            , STM_MOVEMENT_KIND MOK
                                        where SMO.GCO_GOOD_ID = ciGoodId
                                          and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
                                          and MOK.C_MOVEMENT_SORT = 'ENT')
           and MOK1.STM_MOVEMENT_KIND_ID = up.STM_MOVEMENT_KIND_ID
           and MOK1.C_MOVEMENT_SORT = 'ENT'
      order by up.STM_STOCK_MOVEMENT_ID desc;

    lResult STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type;
  begin
    open lcurMvtLastDate(iGoodId);

    fetch lcurMvtLastDate
     into lResult;

    close lcurMvtLastDate;

    return nvl(lResult, 0);
  end GetLastInputPrice;

  /**
  * Description
  *       fonction qui renvoie le prix de l'opération lorsque le mode
  *       d'initialisation du prix de la position est selon opération (7).
  *       La recherche de ce prix est fait selon la cascade définie par
  *       la configuration DOC_SUBCONTRACT_INIT_PRICE.
  */
  function GetSubcontractGoodPrice(
    iFalScheduleStepId in     number
  , iQuantity          in     number
  , ioCurrencyId       in out number
  , ioDicTariff        in out varchar2
  , iGoodId            in     number
  , iThirdId           in     number
  , iRecordId          in     number
  , iDateRef           in     date
  , oNet               out    number
  , oSpecial           out    number
  , ioRoundType        in out varchar2
  , ioRoundAmount      in out number
  , oTariffUnit        out    number
  )
    return number
  is
    lResult    number(18, 5);
    lbFound    boolean;
    lScsQtyRef FAL_TASK_LINK.SCS_QTY_REF_AMOUNT%type;
    lScsAmount FAL_TASK_LINK.SCS_AMOUNT%type;
    lThirdId   PAC_THIRD.PAC_THIRD_ID%type;
    lTariffId  PTC_TARIFF.PTC_TARIFF_ID%type;
    iConfig    PCS.PC_CBASE.CBACVALUE%type;
  begin
    oSpecial  := 0;
    oNet      := 0;
    lbFound   := false;
    lThirdId  := iThirdId;
    lResult   := 0;
    iConfig   := PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_INIT_PRICE');

    /*
    DOC_SUBCONTRACT_INIT_PRICE         :

    Méthode de recherche du prix d'une opération de sous-traitance

    Définit la  méthode de recherche du  prix d'une opération de sous-traitance dans les cas suivants :
    - dans la pré-calculation, lors du calcul du prix d'une opération de sous-traitance,
    - lors de la génération de la commande sous-traitance (le mode d'initialisation du prix de la position est selon opération).

    Valeurs possibles :

    0 = Montant, si pas défini : Tarif achat du service, si pas défini : PRF du service
    1 = Montant opération, si pas défini : PRF du service
    2 = Tarif achat du service, si pas défini : PRF du service; le Montant opération est créé séparément en tant que POSITION_CHARGE
    3 = PRF du service
    */
    if     iConfig in('0', '1')
       and (iFalScheduleStepId is not null) then
      --  DOC_SUBCONTRACT_INIT_PRICE -> scAmountTariffCostPrice,  scAmountCostPrice
      -- 0 = Montant opération + (tarif service ou PR service)
      -- 1 = Montant opération + (PR service)
      -- Montant
      lResult  := FAL_I_LIB_SUBCONTRACTO.GetOperationPrice(iFalScheduleStepId, iQuantity) / zvl(iQuantity, 1);

      -- Taxe montant fixe : Cas Qté ref = 0 -> Valeur unitaire = 0
      -- La casacade ne doit pas continuer car le montant est présent dans la taxe
      select nvl(SCS_QTY_REF_AMOUNT, 0)
           , nvl(SCS_AMOUNT, 0)
        into lScsQtyRef
           , lScsAmount
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = iFalScheduleStepId;

      lbFound  :=    lResult is not null
                  or (    lScsQtyRef = 0
                      and lScsAmount <> 0);

      if lbFound then
        -- Le montant d'une opération est toujours exprimé en monnaie de base.
        ioCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
      end if;
    end if;

    if     iConfig in('0', '2')
       and not lbFound then
      -- Tarif achat
      PTC_FIND_TARIFF.GetTariff(iGoodId
                              , lThirdId
                              , iRecordId
                              , ioCurrencyId
                              , ioDicTariff
                              , iQuantity
                              , iDateRef
                              , 'A_PAYER'
                              , 'UNIQUE'
                              , lTariffId
                              , ioCurrencyId
                              , oNet
                              , oSpecial
                               );

      if lTariffId is not null then
        lResult  := PTC_FIND_TARIFF.GetTariffPrice(lTariffId, iQuantity, ioRoundType, ioRoundAmount, oTariffUnit);
        lbFound  := true;
      end if;

      -- Exprime toujours le prix en fonction de l'unité de stockage
      lResult  :=(lResult / PTC_FIND_TARIFF.GetPurchaseConvertFactor(iGoodId, lThirdId) );
    end if;

    if    (iConfig = '3')
       or not lbFound then
      -- Prix de revient fixe
      lResult       := GetCostPriceWithManagementMode(iGoodId, lThirdId, '3');
      oNet          := 0;
      oSpecial      := 0;
      ioCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
      ioDicTariff   := null;
    end if;

    return lResult;
  end;

  /**
  * Description
  *       fonction qui renvoie le prix du bien selon le type de prix demandé
  */
  function GetGoodPrice(
    iGoodId            in     number
  , iTypePrice         in     varchar2
  , iThirdId           in     number
  , iRecordId          in     number
  , iFalScheduleStepId in     number
  , ioDicTariff        in out varchar2
  , iQuantity          in     number
  , iDateRef           in     date
  , ioRoundType        in out varchar2
  , ioRoundAmount      in out number
  , ioCurrencyId       in out number
  , oNet               out    number
  , oSpecial           out    number
  , oFlatRate          out    number
  , oTariffUnit        out    number
  , iDicTariff2        in     varchar2 default null
  )
    return number
  is
    lResult              number;
    lTariffId            PTC_TARIFF.PTC_TARIFF_ID%type;
    lThirdId             PAC_THIRD.PAC_THIRD_ID%type;
    llDicTariff          DIC_TARIFF.DIC_TARIFF_ID%type;
    lCfgIndivTariflPrice varchar2(1);
    lPrice               number;
    lCodeTariff          varchar2(32000);
    lTariffType          varchar2(10);
    lTarifficationMode   varchar2(10);
    lResultCurrencyID    number;
    lManagementMode      GCO_GOOD.C_MANAGEMENT_MODE%type;
  begin
    oNet                  := 0;
    oSpecial              := 0;
    oFlatRate             := 0;
    oTariffUnit           := 0;
    -- Config indiquant si la recherche du prix est celle de PCS ou bien une recherche INDIV
    lCfgIndivTariflPrice  := nvl(PCS.PC_CONFIG.GetConfig('DOC_INDIV_GET_TARIFF'), '0');
    lThirdId              := iThirdId;

    -- selon mode de gestion
    if iTypePrice = '9' then
      -- Recherche du mode de gestion
      select decode(C_MANAGEMENT_MODE, '1', '3'   -- PRCS
                                               , '2', '4'   -- PRC
                                                         , '3', '5'   -- PRF
                                                                   , '4', '6'   -- Dernier prix d'entrée
                                                                             )
        into lManagementMode
        from GCO_GOOD
       where GCO_GOOD_ID = iGoodId;
    else
      lManagementMode  := iTypePrice;
    end if;

    -- tarif achat
    if lManagementMode = 1 then
      -- Recherche du prix par la méthode INDIV
      if    lCfgIndivTariflPrice = '1'
         or PCS.PC_CONFIG.GetConfig('PTC_INDIV_PUR_TARIFF_SQLST') is not null then
        -- Rechercher le code PL anonyme permettant la recherche d'un tarif individualisé
        lCodeTariff         :=
          PCS.PC_FUNCTIONS.GetSql('PTC_TARIFF'
                                , 'PTC_INDIV_TARIFF'
                                , nvl(PCS.PC_CONFIG.GetConfig('PTC_INDIV_PUR_TARIFF_SQLST'), 'GetIndivTariffPrice')
                                , PCS.PC_I_LIB_SESSION.GetObjectId
                                , 'ANSI SQL'
                                , false
                                 );
        lCodeTariff         := replace(lCodeTariff, '[' || 'CO]', PCS.PC_I_LIB_SESSION.GetCompanyOwner);
        lCodeTariff         := replace(lCodeTariff, '[' || 'COMPANY_OWNER]', PCS.PC_I_LIB_SESSION.GetCompanyOwner);
        lTariffType         := 'A_PAYER';
        lTarifficationMode  := 'UNIQUE';
        lResultCurrencyId   := ioCurrencyId;

        /*
        -- exemple d'utilisation
        execute immediate 'begin' ||
                          'PTC_INDIV_TARIFF.GetIndivTariflPrice(:aGoodId' ||
                          '                                   , :ThirdId' ||
                          '                                   , :aRecordId' ||
                          '                                   , :aCurrencyId' ||
                          '                                   , :adic_tariff' ||
                          '                                   , :aQuantity' ||
                          '                                   , :adateRef' ||
                          '                                   , :tariff_type' ||
                          '                                   , :tariffication_mode' ||
                          '                                   , :tariff_id' ||
                          '                                   , :Price' ||
                          '                                   , :aResultCurrencyId' ||
                          '                                   , :aNet' ||
                          '                                   , :aSpecial' ||
                          '                                    );' ||
                          'end;'
        */
        execute immediate lCodeTariff
                    using in     iGoodId
                        , in out lThirdId
                        , in     iRecordId
                        , in     ioCurrencyId
                        , in out ioDicTariff
                        , in     iQuantity
                        , in     iDateRef
                        , in     lTariffType
                        , in     lTarifficationMode
                        , in out lTariffId
                        , in out lPrice
                        , in out lResultCurrencyId
                        , in out oNet
                        , in out oSpecial;

        oTariffUnit         := 1;
        ioCurrencyId        := lResultCurrencyId;
        lResult             := lPrice;
      else
        PTC_FIND_TARIFF.GetTariff(iGoodId
                                , lThirdId
                                , iRecordId
                                , ioCurrencyId
                                , ioDicTariff
                                , iQuantity
                                , iDateRef
                                , 'A_PAYER'
                                , 'UNIQUE'
                                , lTariffId
                                , ioCurrencyId
                                , oNet
                                , oSpecial
                                , iDicTariff2
                                 );

        if lTariffId is not null then
          lResult  := PTC_FIND_TARIFF.GetTariffPrice(lTariffId, iQuantity, ioRoundType, ioRoundAmount, oTariffUnit, oFlatRate);
        end if;
      end if;

      if PCS.PC_CONFIG.GetConfig('PTC_PURCHASE_TARIFF_UNIT') = '0' then
        -- Exprime toujours le prix en fonction de l'unité de stockage si le paramètre d'entrée le demande
        lResult  := lResult / PTC_FIND_TARIFF.GetPurchaseConvertFactor(iGoodId, lThirdId);
      end if;
    -- tarif vente
    elsif lManagementMode = 2 then
      -- Recherche du prix par la méthode INDIV
      -- Recherche du prix par la méthode INDIV
      if    lCfgIndivTariflPrice = '1'
         or PCS.PC_CONFIG.GetConfig('PTC_INDIV_SALE_TARIFF_SQLST') is not null then
        -- Rechercher le code PL anonyme permettant la recherche d'un tarif individualisé
        lCodeTariff         :=
          PCS.PC_FUNCTIONS.GetSql('PTC_TARIFF'
                                , 'PTC_INDIV_TARIFF'
                                , nvl(PCS.PC_CONFIG.GetConfig('PTC_INDIV_SALE_TARIFF_SQLST'), 'GetIndivTariffPrice')
                                , PCS.PC_I_LIB_SESSION.GetObjectId
                                , 'ANSI SQL'
                                , false
                                 );
        lCodeTariff         := replace(lCodeTariff, '[' || 'CO]', PCS.PC_I_LIB_SESSION.GetCompanyOwner);
        lCodeTariff         := replace(lCodeTariff, '[' || 'COMPANY_OWNER]', PCS.PC_I_LIB_SESSION.GetCompanyOwner);
        lTariffType         := 'A_FACTURER';
        lTarifficationMode  := 'UNIQUE';
        lResultCurrencyId   := ioCurrencyId;

        /*
        -- exemple d'utilisation
        execute immediate 'begin' ||
                          'PTC_INDIV_TARIFF.GetIndivTariflPrice(:aGoodId' ||
                          '                                   , :ThirdId' ||
                          '                                   , :aRecordId' ||
                          '                                   , :aCurrencyId' ||
                          '                                   , :adic_tariff' ||
                          '                                   , :aQuantity' ||
                          '                                   , :adateRef' ||
                          '                                   , :tariff_type' ||
                          '                                   , :tariffication_mode' ||
                          '                                   , :tariff_id' ||
                          '                                   , :Price' ||
                          '                                   , :aResultCurrencyId' ||
                          '                                   , :aNet' ||
                          '                                   , :aSpecial' ||
                          '                                    );' ||
                          'end;'
        */
        execute immediate lCodeTariff
                    using in     iGoodId
                        , in out lThirdId
                        , in     iRecordId
                        , in     ioCurrencyId
                        , in out ioDicTariff
                        , in     iQuantity
                        , in     iDateRef
                        , in     lTariffType
                        , in     lTarifficationMode
                        , in out lTariffId
                        , in out lPrice
                        , in out lResultCurrencyId
                        , in out oNet
                        , in out oSpecial;

        oTariffUnit         := 1;
        ioCurrencyId        := lResultCurrencyId;
        lResult             := lPrice;
      else
        PTC_FIND_TARIFF.GetTariff(iGoodId
                                , lThirdId
                                , iRecordId
                                , ioCurrencyId
                                , ioDicTariff
                                , iQuantity
                                , iDateRef
                                , 'A_FACTURER'
                                , 'UNIQUE'
                                , lTariffId
                                , ioCurrencyId
                                , oNet
                                , oSpecial
                                , iDicTariff2
                                 );

        if lTariffId is not null then
          lResult  := PTC_FIND_TARIFF.GetTariffPrice(lTariffId, iQuantity, ioRoundType, ioRoundAmount, oTariffUnit, oFlatRate);
        end if;
      end if;

      -- Exprime toujours le prix en fonction de l'unité de stockage
      if PCS.PC_CONFIG.GetConfig('PTC_SALE_TARIFF_UNIT') = '0' then
        -- Exprime toujours le prix en fonction de l'unité de stockage
        lResult  := lResult / PTC_FIND_TARIFF.GetSaleConvertFactor(iGoodId, lThirdId);
      end if;
    -- 3 prcs
    elsif lManagementMode = 3 then
      lResult       := GetCostPriceWithManagementMode(iGoodId, lThirdId, '1');
      oNet          := 0;
      oSpecial      := 0;
      ioCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
      ioDicTariff   := null;
    -- 4 PRC
    elsif lManagementMode = 4 then
      lResult       := GetCostPriceWithManagementMode(iGoodId, lThirdId, '2');
      oNet          := 0;
      oSpecial      := 0;
      ioCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
      ioDicTariff   := null;
    -- 5 PRF
    elsif lManagementMode = 5 then
      lResult       := GetCostPriceWithManagementMode(iGoodId, lThirdId, '3');
      oNet          := 0;
      oSpecial      := 0;
      ioCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
      ioDicTariff   := null;
    -- 6 dernier mouvement d'entrée
    elsif lManagementMode = 6 then
      lResult       := GetLastInputPrice(iGoodId);
      oNet          := 0;
      oSpecial      := 0;
      ioCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
      ioDicTariff   := null;
    -- tarif Sous-traitance
    elsif lManagementMode = 7 then
      lResult  :=
        GetSubcontractGoodPrice(iFalScheduleStepId
                              , iQuantity
                              , ioCurrencyId
                              , ioDicTariff
                              , iGoodId
                              , iThirdId
                              , iRecordId
                              , iDateRef
                              , oNet
                              , oSpecial
                              , ioRoundType
                              , ioRoundAmount
                              , oTariffUnit
                               );
    -- tarif cours matières précieuses
    elsif lManagementMode = 8 then
      -- Renvoie le cours d'une matière de base ou d'un alliage pour une unité
      lResult       := GCO_LIB_FUNCTIONS.GetGoodMetalRate(iGoodID => iGoodId, iThirdID => lThirdId, iDate => iDateRef);
      oNet          := 0;
      oSpecial      := 0;
      ioCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
      ioDicTariff   := null;
    -- non traité
    else
      lResult      := 0;
      ioDicTariff  := null;
    end if;

    return lResult;
  end GetGoodPrice;

  /**
  * Description
  *       fonction qui renvoie le prix du bien selon le type de prix demandé
  */
  procedure GetGoodPrice(
    iGoodId            in     number
  , iTypePrice         in     varchar2
  , iThirdId           in     number
  , iRecordId          in     number
  , iFalScheduleStepId in     number
  , ioDicTariff        in out varchar2
  , iQuantity          in     number
  , iDateRef           in     date
  , oPrice             out    number
  , ioRoundType        in out varchar2
  , ioRoundAmount      in out number
  , ioCurrencyId       in out number
  , oNet               out    number
  , oSpecial           out    number
  , oFlatRate          out    number
  , oTariffUnit        out    number
  , iDicTariff2        in     varchar2 default null
  )
  is
  begin
    oPrice  :=
      GetGoodPrice(iGoodId              => iGoodId
                 , iTypePrice           => iTypePrice
                 , iThirdId             => iThirdId
                 , iRecordId            => iRecordId
                 , iFalScheduleStepId   => iFalScheduleStepId
                 , ioDicTariff          => ioDicTariff
                 , iQuantity            => iQuantity
                 , iDateRef             => iDateRef
                 , ioRoundType          => ioRoundType
                 , ioRoundAmount        => ioRoundAmount
                 , ioCurrencyId         => ioCurrencyId
                 , oNet                 => oNet
                 , oSpecial             => oSpecial
                 , oFlatRate            => oFlatRate
                 , oTariffUnit          => oTariffUnit
                 , iDicTariff2          => iDicTariff2
                  );
  end GetGoodPrice;

  /**
  * Description
  *       fonction qui renvoie le prix du bien selon le type de prix demandé.
  * Remarque
  *       Cette fonction est destinée à la recherche d'un prix dans des
  *       commmandes SELET, ou des VIEWS.
  */
  function GetGoodPriceForView(
    iGoodId            in number
  , iTypePrice         in varchar2
  , iThirdId           in number
  , iRecordId          in number
  , iFalScheduleStepId in number
  , ilDicTariff        in varchar2
  , iQuantity          in number
  , iDateRef           in date
  , ioCurrencyId       in number
  , iDicTariff2        in varchar2 default null
  )
    return number
  is
    lRoundType     varchar2(30)               := '';
    lRoundAmount   number                     := 0.0;
    lNewCurrencyId number;
    lbNet          number                     := 0;
    lbSpecial      number                     := 0;
    lbFlatRate     number                     := 0;
    lPrice         number;
    lDicTariff     varchar2(10);
    lTariffUnit    PTC_TARIFF.TRF_UNIT%type;
  begin
    lNewCurrencyId  := ioCurrencyId;
    lDicTariff      := ilDicTariff;
    lPrice          :=
      GetGoodPrice(iGoodId              => iGoodId
                 , iTypePrice           => iTypePrice
                 , iThirdId             => iThirdId
                 , iRecordId            => iRecordId
                 , iFalScheduleStepId   => iFalScheduleStepId
                 , ioDicTariff          => lDicTariff
                 , iQuantity            => iQuantity
                 , iDateRef             => iDateRef
                 , ioRoundType          => lRoundType
                 , ioRoundAmount        => lRoundAmount
                 , ioCurrencyId         => lNewCurrencyId
                 , oNet                 => lbNet
                 , oSpecial             => lbSpecial
                 , oFlatRate            => lbFlatRate
                 , oTariffUnit          => lTariffUnit
                 , iDicTariff2          => iDicTariff2
                  );

    if lNewCurrencyId <> ioCurrencyId then
      lPrice  := ACS_FUNCTION.ConvertAmountForView(lPrice, lNewCurrencyId, ioCurrencyId, iDateRef, 0, 0, 0, 5);   -- Cours logistique
    end if;

    return lPrice;
  end GetGoodPriceForView;

  /**
  * Description
  *   recherche du code assortiment en fonction du bien et du domain d'application
  */
  function GetTariffSet(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type)
    return varchar2
  is
    lResult GCO_GOOD.DIC_TARIFF_SET_SALE_ID%type;
  begin
    select decode(iAdminDomain, gcAdminDomainPurchase, DIC_TARIFF_SET_PURCHASE_ID, gcAdminDomainSale, DIC_TARIFF_SET_SALE_ID)
      into lResult
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  end GetTariffSet;
end GCO_LIB_PRICE;
