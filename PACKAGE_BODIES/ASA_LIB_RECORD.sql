--------------------------------------------------------
--  DDL for Package Body ASA_LIB_RECORD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_LIB_RECORD" 
is
  /**
  * function IsRecordProtected
  * Description
  *   Indique si le dossier SAV est protégé
  */
  function IsRecordProtected(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lProtected ASA_RECORD.ARE_PROTECTED%type;
  begin
    select nvl(ARE_PROTECTED, 0)
      into lProtected
      from ASA_RECORD
     where ASA_RECORD_ID = iAsaRecordID;

    return(lProtected = 1);
  end IsRecordProtected;

  /**
  * function IsRecordInBlockedStatus
  * Description
  *   Indique si le statut du dossier SAV figure dans les statuts de la config
  *     ASA_REP_STATUS_BLOCKED pour lesquels le dossier doit être bloqué
  */
  function IsRecordInBlockedStatus(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lvStatus ASA_RECORD.C_ASA_REP_STATUS%type;
  begin
    select C_ASA_REP_STATUS
      into lvStatus
      from ASA_RECORD
     where ASA_RECORD_ID = iAsaRecordID;

    return ASA_LIB_RECORD.isStatusInConfig(iStatus => lvStatus, iConfig => 'ASA_REP_STATUS_BLOCKED');
  end IsRecordInBlockedStatus;

  /**
  * procedure CanRecordModify
  * Description
  *   Indique si le dossier SAV est modifiable
  */
  procedure CanRecordModify(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type, oErrorCode out varchar2, oErrorText out varchar2)
  is
  begin
    oErrorCode  := null;
    oErrorText  := null;

    if oErrorCode is null then
      -- Test si le statut du dossier figure dans la config qui empeche toute modif (sauf flux et crm)
      if IsRecordInBlockedStatus(iAsaRecordID => iAsaRecordID) then
        oErrorCode  := '02';
        oErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Le statut du dossier ne permet pas cette action !');
      end if;
    end if;

    if oErrorCode is null then
      -- Test si le dossier SAV est protégé
      if IsRecordProtected(iAsaRecordID => iAsaRecordID) then
        oErrorCode  := '01';
        oErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Ce dossier est protégé !');
      end if;
    end if;
  end CanRecordModify;

  /**
  * procedure GetGoodDescr
  * Description
  *   Recherche les 3 descriptions d'un bien en fonction du domaine SAV
  */
  procedure GetGoodDescr(
    iGoodID     in     GCO_GOOD.GCO_GOOD_ID%type
  , iLangID     in     PCS.PC_LANG.PC_LANG_ID%type
  , oShortDescr out    ASA_RECORD_TASK.RET_DESCR%type
  , oLongDescr  out    ASA_RECORD_TASK.RET_DESCR2%type
  , oFreeDescr  out    ASA_RECORD_TASK.RET_DESCR3%type
  )
  is
    lStockId            STM_STOCK.STM_STOCK_ID%type;
    lLocationId         STM_LOCATION.STM_LOCATION_ID%type;
    lReference          GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    lEanCode            GCO_GOOD.GOO_EAN_CODE%type;
    lEanUCC14Code       GCO_GOOD.GOO_EAN_UCC14_CODE%type;
    lHIBCPrimaryCode    GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
    lDicUnitOfMeasure   GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lConvertFactor      GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    lNumberOfDecimal    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lQuantity           GCO_COMPL_DATA_PURCHASE.CPU_ECONOMICAL_QUANTITY%type;
  begin
    GCO_I_LIB_COMPL_DATA.GetComplementaryData(iGoodID               => iGoodID
                                            , iAdminDomain          => '7'
                                            , iThirdID              => null
                                            , iLangID               => iLangID
                                            , iOperationID          => null
                                            , iTransProprietor      => 0
                                            , iComplDataID          => null
                                            , oStockId              => lStockId
                                            , oLocationId           => lLocationId
                                            , oReference            => lReference
                                            , oSecondaryReference   => lSecondaryReference
                                            , oShortDescription     => oShortDescr
                                            , oLongDescription      => oLongDescr
                                            , oFreeDescription      => oFreeDescr
                                            , oEanCode              => lEanCode
                                            , oEanUCC14Code         => lEanUCC14Code
                                            , oHIBCPrimaryCode      => lHIBCPrimaryCode
                                            , oDicUnitOfMeasure     => lDicUnitOfMeasure
                                            , oConvertFactor        => lConvertFactor
                                            , oNumberOfDecimal      => lNumberOfDecimal
                                            , oQuantity             => lQuantity
                                             );
  end GetGoodDescr;

    /**
  * function GetGoodSalePrice
  * Description
  *   Recherche du prix de vente du bien
  */
  function GetGoodSalePrice(
    iGoodID     in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdID    in PAC_THIRD.PAC_THIRD_ID%type
  , iRecordID   in DOC_RECORD.DOC_RECORD_ID%type
  , iDicTariff  in DIC_TARIFF.DIC_TARIFF_ID%type
  , iCurrencyID in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , iDate       in ASA_RECORD.ARE_DATECRE%type
  )
    return number
  is
    lPrice       number                                                  := 0.0;
    lPriceEUR    number                                                  := 0.0;
    lDicTariff   varchar2(10);
    lRoundType   varchar2(30);
    lRoundAmount number;
    lCurrencyID  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lNet         number;
    lSpecial     number;
    lFlatRate    number;
    lTariffUnit  number;
  begin
    lDicTariff   := iDicTariff;
    lCurrencyID  := iCurrencyID;
    -- recherche du prix de vente
    lPrice       :=
      GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => iGoodID
                                 , iTypePrice           => '2'
                                 , iThirdId             => iThirdID
                                 , iRecordId            => iRecordID
                                 , iFalScheduleStepId   => null
                                 , ioDicTariff          => lDicTariff
                                 , iQuantity            => 1
                                 , iDateRef             => GetTariffDateRef(iDate)
                                 , ioRoundType          => lRoundType
                                 , ioRoundAmount        => lRoundAmount
                                 , ioCurrencyId         => lCurrencyID
                                 , oNet                 => lNet
                                 , oSpecial             => lSpecial
                                 , oFlatRate            => lFlatRate
                                 , oTariffUnit          => lTariffUnit
                                  );

    if nvl(lPrice, 0) <> 0 then
      -- Si la monnaie renvoyée est differente de la monnaie en entrée
      -- convertir le prix en monnaie passée en entrée
      if iCurrencyID <> lCurrencyID then
        ACS_FUNCTION.ConvertAmount(aAmount          => lPrice
                                 , aFromFinCurrId   => lCurrencyID
                                 , aToFinCurrId     => iCurrencyID
                                 , aDate            => GetTariffDateRef(iDate)
                                 , aExchangeRate    => 0
                                 , aBasePrice       => 0
                                 , aRound           => 2
                                 , aAmountEUR       => lPriceEUR
                                 , aAmountConvert   => lPrice
                                 , aRateType        => 5
                                  );
      end if;
    end if;

    return lPrice;
  end GetGoodSalePrice;

  /**
  * function GetGoodCostPrice
  * Description
  *   Recherche du prix de revient du bien
  */
  function GetGoodCostPrice(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type, iDate in date)
    return number
  is
    lPrice number := 0.0;
  begin
    lPrice  := GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(iGCO_GOOD_ID => iGoodID, iPAC_THIRD_ID => iThirdID, iDateRef => iDate);
    return lPrice;
  end GetGoodCostPrice;

  /**
  * function GetTotalCompPrice
  * Description
  *   Recherche du prix de vente et de revient total des composants
  * @author ECA
  * @created AUG.2011
  * @lastUpdate
  * @public
  * @param iRecordID   : id du bien
  * @param ioTotalSalePrice : Total prix de vente
  * @param ioTotalCostPrice : Total prix de revient
  */
  procedure GetTotalCompPrice(iRecordID in number, ioTotalSalePrice in out number, ioTotalCostPrice in out number)
  is
  begin
    ioTotalSalePrice  := 0;
    ioTotalCostPrice  := 0;

    for TplComp in (select decode(are.C_ASA_SELECT_PRICE, '1', nvl(ARC.ARC_SALE_PRICE, 0), nvl(ARC.ARC_SALE_PRICE2, 0) ) ARC_SALE_PRICE
                         , nvl(ARC.ARC_QUANTITY, 0) ARC_QUANTITY
                         , are.C_ASA_SELECT_PRICE
                         , ARC.ARC_OPTIONAL
                         , ARC.C_ASA_ACCEPT_OPTION
                         , ARC.ARC_GUARANTY_CODE
                         , ARC.C_ASA_GEN_DOC_POS
                         , nvl(ARC.ARC_COST_PRICE, 0) ARC_COST_PRICE
                      from ASA_RECORD are
                         , ASA_RECORD_COMP ARC
                     where are.ASA_RECORD_ID = iRecordId
                       and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
                       and (   are.ASA_RECORD_EVENTS_ID is null
                            or (    are.ASA_RECORD_EVENTS_ID is not null
                                and are.ASA_RECORD_EVENTS_ID = ARC.ASA_RECORD_EVENTS_ID) ) ) loop
      -- Calcul prix de vente.
      if     (   TplComp.ARC_OPTIONAL = 0
              or TplComp.C_ASA_ACCEPT_OPTION = '2')
         and TplComp.ARC_GUARANTY_CODE = 0
         and TplComp.C_ASA_GEN_DOC_POS = '2' then
        ioTotalSalePrice  := ioTotalSalePrice +(TplComp.ARC_SALE_PRICE * TplComp.ARC_QUANTITY);
      end if;

      -- Calcul prix de revient
      if    TplComp.ARC_OPTIONAL = 0
         or TplComp.C_ASA_ACCEPT_OPTION = '2' then
        ioTotalCostPrice  := ioTotalCostPrice +(TplComp.ARC_COST_PRICE * TplComp.ARC_QUANTITY);
      end if;
    end loop;
  end GetTotalCompPrice;

  /**
  * function GetTotalTaskPrice
  * Description
  *   Recherche du prix de vente et de revient total des opérations
  * @author ECA
  * @created AUG.2011
  * @lastUpdate
  * @public
  * @param iRecordID   : id du bien
  * @param ioTotalSalePrice : Total prix de vente
  * @param ioTotalCostPrice : Total prix de revient
  */
  procedure GetTotalTaskPrice(iRecordID in number, ioTotalSalePrice in out number, ioTotalCostPrice in out number)
  is
    lcfgASA_OPER_UNIT_SALE_PRICE varchar2(10);
    lcfgPPS_WORK_UNIT            varchar2(10);
    lnTime                       number;
  begin
    ioTotalSalePrice              := 0;
    ioTotalCostPrice              := 0;
    lnTime                        := 0;
    -- Prix total ou / unité de temps
    lcfgASA_OPER_UNIT_SALE_PRICE  := upper(PCS.PC_CONFIG.GetConfig('ASA_OPER_UNIT_SALE_PRICE') );
    -- unité de temps
    lcfgPPS_WORK_UNIT             := upper(PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') );

    -- Parcours des opérations
    for tplTasks in (select decode(are.C_ASA_SELECT_PRICE, '1', ART.RET_SALE_AMOUNT, ART.RET_SALE_AMOUNT2) RET_SALE_AMOUNT
                          , ART.RET_TIME_USED
                          , ART.RET_TIME
                          , ART.RET_FINISHED
                          , ART.RET_OPTIONAL
                          , ART.C_ASA_ACCEPT_OPTION
                          , ART.RET_GUARANTY_CODE
                          , ART.C_ASA_GEN_DOC_POS
                          , nvl(ART.RET_COST_PRICE, 0) RET_COST_PRICE
                          , nvl(ART.RET_AMOUNT, 0) RET_AMOUNT
                       from ASA_RECORD are
                          , ASA_RECORD_TASK ART
                      where are.ASA_RECORD_ID = iRecordId
                        and are.ASA_RECORD_ID = ART.ASA_RECORD_ID
                        and (   are.ASA_RECORD_EVENTS_ID is null
                             or (    are.ASA_RECORD_EVENTS_ID is not null
                                 and are.ASA_RECORD_EVENTS_ID = ART.ASA_RECORD_EVENTS_ID)
                            ) ) loop
      if (   TplTasks.RET_OPTIONAL = 0
          or TplTasks.C_ASA_ACCEPT_OPTION = '2') then
        /* La saisie des temps se fait en minutes ou en heure en fonction du code PPS_WORK_UNIT,
        les taux sont saisis en heure, ainsi si la saisie se fait en minute il faut diviser le temp
        par 60 avant de le multiplier par le taux */
        if TplTasks.RET_FINISHED = 1 then
          lnTime  := TplTasks.RET_TIME_USED;
        else
          if TplTasks.RET_TIME_USED > 0 then
            lnTime  := TplTasks.RET_TIME_USED;
          else
            lnTime  := TplTasks.RET_TIME;
          end if;
        end if;

        if lcfgPPS_WORK_UNIT = 'M' then
          lnTime  := lnTime / 60;
        end if;

        -- Calcul du prix de vente
        if     TplTasks.RET_GUARANTY_CODE = 0
           and TplTasks.C_ASA_GEN_DOC_POS = '2' then
          -- Le prix de vente / opération est le prix de vente total de l'opération
          if lcfgASA_OPER_UNIT_SALE_PRICE = 'FALSE' then
            ioTotalSalePrice  := ioTotalSalePrice + nvl(tplTasks.RET_SALE_AMOUNT, 0);
          -- Si l'opération est terminée, le calcul du prix exploite le temps utilisé
          else
            ioTotalSalePrice  := ioTotalSalePrice +(nvl(tplTasks.RET_SALE_AMOUNT, 0) * lnTime);
          end if;
        end if;

        -- Calcul du prix de revient
        ioTotalCostPrice  := ioTotalCostPrice +(TplTasks.RET_COST_PRICE * lnTime) + tplTasks.RET_AMOUNT;
      end if;
    end loop;
  end GetTotalTaskPrice;

  /**
  * function CheckStatus
  * Description
  *   Vérifie si le passage du OldStatus au NewStatus est autorisé
  */
  function CheckStatus(iAsaRecordID in number, iOldStatus in varchar2, iNewStatus in varchar2)
    return integer
  is
    type TStatus is ref cursor;

    crStatus    TStatus;
    lResult     integer;
    lvSql       varchar2(32000);
    lvSqlStatus varchar2(32000);
  begin
    -- L'événement "pièce volée" peut être créé à tout moment
    if iNewStatus = '13' then
      return 1;
    end if;

    lResult      := 0;
    -- Recherche de la cmd indiv contenant la liste des status autorisés
    lvSqlStatus  := PCS.PC_FUNCTIONS.GetSql('ASA_RECORD_EVENTS', 'C_ASA_REP_STAT_' || iOldStatus, 'NEXT_STATUS');

    -- Si pas de cmd, tous les status sont autorisés
    if lvSqlStatus is null then
      lvSqlStatus  := 'select GCLCODE from V_COM_CPY_PCS_CODES where GCGNAME = ''C_ASA_REP_STATUS'' group by GCLCODE ';
    end if;

    lvSql        := 'select count(COD_LIST.GCLCODE)' || '  from ( ' || lvSqlStatus || '       ) COD_LIST ' || ' where '':C_ASA_REP_STATUS'' = COD_LIST.GCLCODE ';
    --
    -- Remplacement du company owner
    lvSql        := replace(lvSql, '[' || 'CO].', '');
    -- Remplacement du company owner
    lvSql        := replace(lvSql, '[' || 'COMPANY_OWNER].', '');
    -- Remplacement du ASA_RECORD_ID
    lvSql        := replace(lvSql, ':ASA_RECORD_ID', to_char(iAsaRecordID) );
    -- Remplacement du PC_LANG_ID
    lvSql        := replace(lvSql, ':PC_LANG_ID', to_char(PCS.PC_I_LIB_SESSION.GetUserLangID) );
    -- Remplacement du Status
    lvSql        := replace(lvSql, ':C_ASA_REP_STATUS', iNewStatus);

    open crStatus for lvSql;

    fetch crStatus
     into lResult;

    close crStatus;

    return lResult;
  end CheckStatus;

  /*
  * function isStatusInConfig
  * Description
  *   Vérifie si le status est dans la valeur de la config
  */
  function isStatusInConfig(iStatus in ASA_RECORD.C_ASA_REP_STATUS%type, iConfig in PCS.PC_CBASE.CBACNAME%type)
    return boolean
  is
    lExits   boolean;
    lvConfig PCS.PC_CBASE.CBACVALUE%type;
  begin
    lvConfig  := ';' || PCS.PC_CONFIG.GetConfig(iConfig) || ';';
    lvConfig  := replace(lvConfig, ',', ';');
    lExits    := instr(lvConfig, ';' || iStatus || ';') > 0;
    return lExits;
  end isStatusInConfig;

  /*
  * function GetQtyMgm
  * Description
  *   Renvoi la valeur de "Gestion de la qté en réparation" pour une type de rép.
  */
  function GetQtyMgm(iRepTypeID in ASA_REP_TYPE.ASA_REP_TYPE_ID%type)
    return boolean
  is
    lResult boolean;
  begin
    lResult  :=(FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'ASA_REP_TYPE', iv_column_name => 'RET_QTY_MGM', it_pk_value => iRepTypeID) = 1);
    return lResult;
  end GetQtyMgm;

  /*
  * function IsDetExchMvtGen
  * Description
  *    Renvoie true si les mouvements de tous les détails pour échange ont été générés
  */
  function IsDetExchMvtGen(iASA_RECORD_ID in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lnId    number;
    lResult boolean;
  begin
    begin
      select ASA_RECORD_EXCH_DETAIL_ID
        into lnId
        from ASA_RECORD_EXCH_DETAIL REX
           , ASA_RECORD_DETAIL RED
       where REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
         and RED.ASA_RECORD_ID = iASA_RECORD_ID;

      select count(*)
        into lnId
        from ASA_RECORD_EXCH_DETAIL REX
           , ASA_RECORD_DETAIL RED
       where REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
         and RED.ASA_RECORD_ID = iASA_RECORD_ID
         and REX.STM_STOCK_MOVEMENT_ID is null;

      lResult  :=(lnId = 0);
      return lResult;
    exception
      when no_data_found then
        return false;
    end;
  end IsDetExchMvtGen;

  /*
  * function IsDetMvtGen
  * Description
  *    Renvoie true si les mouvements de tous les détails à échanger ont été générés
  */
  function IsDetMvtGen(iASA_RECORD_ID in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lnId    number;
    lResult boolean;
  begin
    begin
      select ASA_RECORD_DETAIL_ID
        into lnId
        from ASA_RECORD_DETAIL
       where ASA_RECORD_ID = iASA_RECORD_ID;

      select count(*)
        into lnId
        from ASA_RECORD_DETAIL
       where ASA_RECORD_ID = iASA_RECORD_ID
         and STM_STOCK_MOVEMENT_ID is null;

      lResult  :=(lnId = 0);
      return lResult;
    exception
      when no_data_found then
        return false;
    end;
  end IsDetMvtGen;

  /*
  * function GetGoodCharCount
  * Description
  *    Renvoie le nbr de caract. que possède le produit
  */
  function GetGoodCharCount(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lCharCount number;
  begin
    select count(*)
      into lCharCount
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodID;

    return lCharCount;
  end GetGoodCharCount;

  /*
  * function CtrlExchangeData
  * Description
  *   Ctrl des données relatives à un échange qté/caract./qté dispo
  */
  function CtrlExchangeData(iotAsaRecord in out nocopy fwk_i_typ_definition.t_crud_def)
    return boolean
  is
    lAsaRecord         ASA_RECORD%rowtype;
    lSumQtyToRepair    ASA_RECORD_DETAIL.RED_QTY_TO_REPAIR%type;
    lRepairCharCount   number;
    lExchangeCharCount number;
    lQty               number;
    lResult            boolean                                    := true;
  begin
    lAsaRecord  := FWK_TYP_ASA_ENTITY.gttRecord(iotAsaRecord.entity_id);

    -- Ctrl de la saisie des qtés et caract si gestion qté en rép.
    if ASA_I_LIB_RECORD.GetQtyMgm(lAsaRecord.ASA_REP_TYPE_ID) then
      -- Recherche le nbr de caract gérées par le bien à réparer
      lRepairCharCount    := ASA_I_LIB_RECORD.GetGoodCharCount(lAsaRecord.GCO_ASA_TO_REPAIR_ID);

      if lRepairCharCount > 0 then
        -- la somme des qtés du détail à échanger doit être égale à la quantité du produit à échanger
        select nvl(sum(RED.RED_QTY_TO_REPAIR), 0)
          into lSumQtyToRepair
          from ASA_RECORD_DETAIL RED
         where RED.ASA_RECORD_ID = lAsaRecord.ASA_RECORD_ID;

        -- Toutes les caractérisations du produit à échanger ne sont pas renseignées
        if lSumQtyToRepair <> lAsaRecord.ARE_REPAIR_QTY then
          lResult  := false;
          RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Valeurs de caractérisation manquantes pour le produit à échanger !'), aErrNo => -20900);
        end if;
      end if;

      -- Recherche le nbr de caract gérées par le bien en échange
      lExchangeCharCount  := ASA_I_LIB_RECORD.GetGoodCharCount(lAsaRecord.GCO_ASA_EXCHANGE_ID);

      -- Pas de caractérisations donc pas de détail ; contrôle au niveau des quantités du dossier
      if     (lRepairCharCount = 0)
         and (lExchangeCharCount = 0) then
        if lAsaRecord.ARE_REPAIR_QTY <> lAsaRecord.ARE_EXCH_QTY then
          lResult  := false;
          RA(aMessage   => PCS.PC_FUNCTIONS.TranslateWord('La qté totale du produit à échanger ne correspond pas à la qté du produit à réparer !')
           , aErrNo     => -20900
            );
        end if;
      else
        -- Contrôle au niveau des détails
        if ASA_FUNCTIONS.ControlQtyExchanged(lAsaRecord.ASA_RECORD_ID) = 0 then
          lResult  := false;
          RA(aMessage   => PCS.PC_FUNCTIONS.TranslateWord('La qté totale du produit à échanger ne correspond pas à la qté du produit à réparer !')
           , aErrNo     => -20900
            );
        end if;
      end if;

      -- Contrôle que les mouvements n'ont pas été effectués
      if     (lRepairCharCount = 0)
         and (lExchangeCharCount = 0) then
        lResult  :=     (lAsaRecord.STM_ASA_DEFECT_MVT_ID is null)
                    and (lAsaRecord.STM_ASA_EXCH_MVT_ID is null);
      else
        declare
          lCount integer;
        begin
          select count(*)
            into lCount
            from ASA_RECORD_DETAIL
           where ASA_RECORD_ID = lAsaRecord.ASA_RECORD_ID
             and STM_STOCK_MOVEMENT_ID is null;

          lResult  := lCount <> 0;
        end;
      end if;
    end if;

    if lResult then
      -- Contrôle disponibilité en stock de l'article pour échange
      if     (lAsaRecord.GCO_ASA_EXCHANGE_ID is not null)
         and (GCO_I_LIB_FUNCTIONS.getStockManagement(lAsaRecord.GCO_ASA_EXCHANGE_ID) = 1) then
        -- Pas de gestion qté ou pas de caract
        if    not(ASA_I_LIB_RECORD.GetQtyMgm(lAsaRecord.ASA_REP_TYPE_ID) )
           or (ASA_I_LIB_RECORD.GetGoodCharCount(lAsaRecord.GCO_ASA_EXCHANGE_ID) = 0) then
          -- Ctrl du dispo du produit à échanger
          lQty  :=
            ASA_FUNCTIONS.GetQuantity(good_id         => lAsaRecord.GCO_ASA_EXCHANGE_ID
                                    , stock_id        => lAsaRecord.STM_ASA_EXCH_STK_ID
                                    , location_id     => lAsaRecord.STM_ASA_EXCH_LOC_ID
                                    , charac1_id      => lAsaRecord.GCO_EXCH_CHAR1_ID
                                    , charac2_id      => lAsaRecord.GCO_EXCH_CHAR2_ID
                                    , charac3_id      => lAsaRecord.GCO_EXCH_CHAR3_ID
                                    , charac4_id      => lAsaRecord.GCO_EXCH_CHAR4_ID
                                    , charac5_id      => lAsaRecord.GCO_EXCH_CHAR5_ID
                                    , char_val_1      => lAsaRecord.ARE_EXCH_CHAR1_VALUE
                                    , char_val_2      => lAsaRecord.ARE_EXCH_CHAR2_VALUE
                                    , char_val_3      => lAsaRecord.ARE_EXCH_CHAR3_VALUE
                                    , char_val_4      => lAsaRecord.ARE_EXCH_CHAR4_VALUE
                                    , char_val_5      => lAsaRecord.ARE_EXCH_CHAR5_VALUE
                                    , qtyToReturn     => 'STOCK'
                                    , aRecordCompID   => null
                                     );

          if lQty < 1 then
            lResult  := false;
            RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Quantité disponible insuffisante pour l''échange !'), aErrNo => -20900);
          end if;
        else
          -- Si gestion qté en réparation ou caractérisations,
          --  le contrôle doit se faire pour chaque détail du produit à échanger
          for tplDet in (select REX.GCO_EXCH_CHAR1_ID
                              , REX.GCO_EXCH_CHAR2_ID
                              , REX.GCO_EXCH_CHAR3_ID
                              , REX.GCO_EXCH_CHAR4_ID
                              , REX.GCO_EXCH_CHAR5_ID
                              , REX.REX_EXCH_CHAR1_VALUE
                              , REX.REX_EXCH_CHAR2_VALUE
                              , REX.REX_EXCH_CHAR3_VALUE
                              , REX.REX_EXCH_CHAR4_VALUE
                              , REX.REX_EXCH_CHAR5_VALUE
                           from ASA_RECORD_EXCH_DETAIL REX
                              , ASA_RECORD_DETAIL RED
                          where REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
                            and RED.ASA_RECORD_ID = lAsaRecord.ASA_RECORD_ID) loop
            -- Qté disponnible
            lQty  :=
              ASA_FUNCTIONS.GetQuantity(good_id         => lAsaRecord.GCO_ASA_EXCHANGE_ID
                                      , stock_id        => lAsaRecord.STM_ASA_EXCH_STK_ID
                                      , location_id     => lAsaRecord.STM_ASA_EXCH_LOC_ID
                                      , charac1_id      => tplDet.GCO_EXCH_CHAR1_ID
                                      , charac2_id      => tplDet.GCO_EXCH_CHAR2_ID
                                      , charac3_id      => tplDet.GCO_EXCH_CHAR3_ID
                                      , charac4_id      => tplDet.GCO_EXCH_CHAR4_ID
                                      , charac5_id      => tplDet.GCO_EXCH_CHAR5_ID
                                      , char_val_1      => tplDet.REX_EXCH_CHAR1_VALUE
                                      , char_val_2      => tplDet.REX_EXCH_CHAR2_VALUE
                                      , char_val_3      => tplDet.REX_EXCH_CHAR3_VALUE
                                      , char_val_4      => tplDet.REX_EXCH_CHAR4_VALUE
                                      , char_val_5      => tplDet.REX_EXCH_CHAR5_VALUE
                                      , qtyToReturn     => 'STOCK'
                                      , aRecordCompID   => null
                                       );

            if lQty < 1 then
              lResult  := false;
              RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Quantité disponible insuffisante pour l''échange !'), aErrNo => -20900);
            end if;
          end loop;
        end if;
      end if;
    end if;

    return lResult;
  end CtrlExchangeData;

  /**
  * function GetGaugeIdFromConfig
  * Description
  *   Recherche l'id du gabarit
  */
  function GetGaugeIdFromConfig(iConfig in varchar2, iGauDescribe in DOC_GAUGE.GAU_DESCRIBE%type default null)
    return number
  is
    lnCount      number;
    lvConfig     varchar2(4000);
    lGauDescribe DOC_GAUGE.GAU_DESCRIBE%type;
    lDocGaugeId  DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    lDocGaugeId   := 0;
    lGauDescribe  := null;

    if iGauDescribe is not null then
      -- Contrôle si le gabarits extiste dans la config
      -- Récupérer le gauge
      for tplConfig in (select distinct ExtractLine(column_value, 1, ';') Config
                                   from table(PCS.CHARLISTTOTABLE(iConfig, ',') ) ) loop
        if iGauDescribe = tplConfig.Config then
          lGauDescribe  := iGauDescribe;
        end if;
      end loop;

      if lGauDescribe is null then
        -- Erreur: le nom du gabarit fourni n'est pas utilisable dans ce contexte
        RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Le gabarit spécifié n''est pas autorisé dans ce contexte !'), aErrNo => -20900);
      end if;
    else
      -- Compte le nombre de gabarit proposé dans la config
      lvConfig  := replace(iConfig, ',<OPTIONAL>');

      select count(*)
        into lnCount
        from table(PCS.CHARLISTTOTABLE(lvConfig, ',') );

      if lnCount = 1 then
        -- 1 seul gabarit possible
        lGauDescribe  := ExtractLine(lvConfig, 1, ';');
      elsif lnCount > 1 then
        -- Erreur: Plusieurs gabarits possibles et pas de choix de l'utilisateur
        RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Choix du gabarit impossible, car plusieurs gabarits sont spécifiés !'), aErrNo => -20900);
      end if;
    end if;

    if lGauDescribe is not null then
      -- Récupérer l'id du gabarit à générer
      select max(DOC_GAUGE_ID)
        into lDocGaugeId
        from DOC_GAUGE
       where GAU_DESCRIBE = lGauDescribe;
    end if;

    return lDocGaugeId;
  end GetGaugeIdFromConfig;

  /*
  * function isStatusInConfigOrDefault
  * Description
  *   Vérifie si le status est dans la valeur de la config
  *   si il n'y pas le status, il faut tester si le status
  *   correspond au status par défaut pour cette config
  */
  function isStatusInConfigOrDefault(iStatus in ASA_RECORD.C_ASA_REP_STATUS%type, iConfig in PCS.PC_CBASE.CBACNAME%type)
    return boolean
  is
    lExits      boolean;
    lvCfgValue  PCS.PC_CBASE.CBACVALUE%type;
    lnSep       integer;
    lvRepStatus varchar2(4000)                default null;
  begin
    -- Recherche la valeur de la config
    lvCfgValue  := PCS.PC_CONFIG.GetConfig(iConfig);
    -- Recherche la position du séparateur ; dans la valeur de la config
    lnSep       := instr(lvCfgValue, ';');

    -- Si config pas vide et séparateur trouvé
    if     (lvCfgValue is not null)
       and (lnSep > 0) then
      -- Lister les statuts spécifiés dans la valeur de la config
      for ltplStatus in (select column_value REP_STATUS
                           from table(PCS.charListToTable(substr(lvCfgValue, lnSep + 1), ',') ) ) loop
        lvRepStatus  := lvRepStatus || ';' || ltplStatus.REP_STATUS || ';';
      end loop;
    end if;

    -- Si le status est vide, définir un status par défaut en fonction de
    -- la config utilisée
    if lvRepStatus is null then
      if iConfig = 'ASA_DEFAULT_OFFER_GAUGE_NAME' then
        lvRepStatus  := '02';
      end if;

      if iConfig = 'ASA_DEFAULT_OFFER_BILL_GAUGE' then
        lvRepStatus  := '04';
      end if;

      if iConfig = 'ASA_DEFAULT_CMDC_GAUGE_NAME' then
        lvRepStatus  := '05';
      end if;

      if iConfig = 'ASA_DEFAULT_CMDS_GAUGE_NAME' then
        lvRepStatus  := '07';
      end if;

      if iConfig = 'ASA_DEFAULT_BILL_GAUGE_NAME' then
        lvRepStatus  := '10';
      end if;

      if iConfig = 'ASA_DEFAULT_NC_GAUGE_NAME' then
        lvRepStatus  := '12';
      end if;

      if iConfig = 'ASA_DEFAULT_ATTRIB_GAUGE_NAME' then
        lvRepStatus  := '05';
      end if;
    end if;

    lExits      := instr(';' || lvRepStatus || ';', ';' || iStatus || ';') > 0;
    return lExits;
  end isStatusInConfigOrDefault;

  /*
  * function GetLastRecordID
  * Description
  *   Recherche de l'id du dernier dossier SAV concernant un bien/n°série
  */
  function GetLastRecordID(
    iAsaRecordID    in ASA_RECORD.ASA_RECORD_ID%type
  , iGoodToRepairID in ASA_RECORD.GCO_ASA_TO_REPAIR_ID%type
  , iCharValue      in ASA_RECORD.ARE_STD_CHAR_1%type
  , iCustomerID     in ASA_RECORD.PAC_CUSTOM_PARTNER_ID%type
  )
    return ASA_RECORD.ASA_LAST_RECORD_ID%type
  is
    -- Type correspondant au select de la recherche du dernier dossier de réparation
    type T_LAST_REC is record(
      SORT_FIELD    integer
    , ASA_RECORD_ID ASA_RECORD.ASA_RECORD_ID%type
    , ARE_DATECRE   ASA_RECORD.ARE_DATECRE%type
    );

    type T_TAB_LAST_REC is table of T_LAST_REC
      index by binary_integer;

    ltTabLastRec T_TAB_LAST_REC;
    lvSQL        varchar2(32000);
    lnID         ASA_RECORD.ASA_LAST_RECORD_ID%type   := null;
  begin
    -- Rechercher le code sql de la commande : ASA_RECORD/INIT_ASA_LAST_RECORD_ID/ASA_LAST_RECORD_ID
    lvSQL  := upper(PCS.PC_LIB_SQL.GetSql(iTableName => 'ASA_RECORD', iGroup => 'INIT_ASA_LAST_RECORD_ID', iSqlId => 'ASA_LAST_RECORD_ID') );
    -- Remplacer les paramètres de la commande par leur valeur respective
    lvSQL  := replace(lvSQL, ':ARE_CHAR_VALUE', '''' || iCharValue || '''');
    lvSQL  := replace(lvSQL, ':GCO_ASA_TO_REPAIR_ID', iGoodToRepairID);
    lvSQL  := replace(lvSQL, ':GCO_NEW_GOOD_ID', iGoodToRepairID);
    lvSQL  := replace(lvSQL, ':ASA_RECORD_ID', iAsaRecordID);
    lvSQL  := replace(lvSQL, ':PAC_CUSTOM_PARTNER_ID', iCustomerID);

    execute immediate lvSQL
    bulk collect into ltTabLastRec;

    -- Récuperer l'id du dossier si la commande de recherche à renvoyé l'id du dernier dossier de réparation
    if ltTabLastRec.count > 0 then
      lnID  := ltTabLastRec(1).ASA_RECORD_ID;
    end if;

    return lnID;
  end GetLastRecordID;

  /*
  * function GetOriginPosID
  * Description
  *   Recherche de l'id de la dernière position de document concernant le bien/n°série
  */
  function GetOriginPosID(iGoodToRepairID in ASA_RECORD.GCO_ASA_TO_REPAIR_ID%type, iCharValue in ASA_RECORD.ARE_STD_CHAR_1%type)
    return ASA_RECORD.DOC_ORIGIN_POSITION_ID%type
  is
    cursor lcrPos(cGoodID ASA_RECORD.GCO_ASA_TO_REPAIR_ID%type, cCharValue ASA_RECORD.ARE_STD_CHAR_1%type)
    is
      select   PDE.DOC_POSITION_ID
          from DOC_DOCUMENT DMT
             , GCO_CHARACTERIZATION CHA
             , DOC_POSITION_DETAIL PDE
             , DOC_GAUGE_STRUCTURED GAS
         where CHA.C_CHARACT_TYPE = '3'
           and CHA.GCO_GOOD_ID = cGoodID
           and (    (    PDE.GCO_CHARACTERIZATION_ID = CHA.GCO_CHARACTERIZATION_ID
                     and PDE.PDE_CHARACTERIZATION_VALUE_1 = cCharValue)
                or (    PDE.GCO_GCO_CHARACTERIZATION_ID = CHA.GCO_CHARACTERIZATION_ID
                    and PDE.PDE_CHARACTERIZATION_VALUE_2 = cCharValue)
                or (    PDE.GCO2_GCO_CHARACTERIZATION_ID = CHA.GCO_CHARACTERIZATION_ID
                    and PDE.PDE_CHARACTERIZATION_VALUE_3 = cCharValue)
                or (    PDE.GCO3_GCO_CHARACTERIZATION_ID = CHA.GCO_CHARACTERIZATION_ID
                    and PDE.PDE_CHARACTERIZATION_VALUE_4 = cCharValue)
                or (    PDE.GCO4_GCO_CHARACTERIZATION_ID = CHA.GCO_CHARACTERIZATION_ID
                    and PDE.PDE_CHARACTERIZATION_VALUE_5 = cCharValue)
               )
           and GAS.DOC_GAUGE_ID = PDE.DOC_GAUGE_ID
           and GAS.C_GAUGE_TITLE = '8'
           and DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
      order by DMT_DATE_DOCUMENT desc;

    ltplPos lcrPos%rowtype;
    lnID    ASA_RECORD.DOC_ORIGIN_POSITION_ID%type   := null;
  begin
    open lcrPos(iGoodToRepairID, iCharValue);

    fetch lcrPos
     into ltplPos;

    if lcrPos%found then
      lnID  := ltplPos.DOC_POSITION_ID;
    end if;

    close lcrPos;

    return lnID;
  end GetOriginPosID;

  /*
  * function GetGoodGuarantyCardsID
  * Description
  *   Recherche de l'id de la carte de garantie pour un bien/n°série
  */
  function GetGoodGuarantyCardsID(iGoodID in ASA_GUARANTY_CARDS.GCO_GOOD_ID%type, iCharValue in ASA_GUARANTY_CARDS.AGC_CHAR1_VALUE%type)
    return ASA_GUARANTY_CARDS.ASA_GUARANTY_CARDS_ID%type
  is
    lnID ASA_GUARANTY_CARDS.ASA_GUARANTY_CARDS_ID%type   := null;
  begin
    select max(AGC.ASA_GUARANTY_CARDS_ID)
      into lnID
      from GCO_CHARACTERIZATION CHA
         , ASA_GUARANTY_CARDS AGC
     where CHA.C_CHARACT_TYPE = '3'
       and AGC.GCO_GOOD_ID = iGoodID
       and (    (    AGC.GCO_CHAR1_ID = CHA.GCO_CHARACTERIZATION_ID
                 and AGC.AGC_CHAR1_VALUE = iCharValue)
            or (    AGC.GCO_CHAR2_ID = CHA.GCO_CHARACTERIZATION_ID
                and AGC.AGC_CHAR2_VALUE = iCharValue)
            or (    AGC.GCO_CHAR3_ID = CHA.GCO_CHARACTERIZATION_ID
                and AGC.AGC_CHAR3_VALUE = iCharValue)
            or (    AGC.GCO_CHAR4_ID = CHA.GCO_CHARACTERIZATION_ID
                and AGC.AGC_CHAR4_VALUE = iCharValue)
            or (    AGC.GCO_CHAR5_ID = CHA.GCO_CHARACTERIZATION_ID
                and AGC.AGC_CHAR5_VALUE = iCharValue)
           );

    return lnID;
  end GetGoodGuarantyCardsID;

  /*
  * function GetStolenGoodsID
  * Description
  *   Recherche de l'id de la pièce volée validée pour un bien/n°série
  */
  function GetStolenGoodsID(iGoodID in ASA_STOLEN_GOODS.GCO_GOOD_ID%type, iCharValue in ASA_STOLEN_GOODS.ASG_CHAR1_VALUE%type)
    return ASA_STOLEN_GOODS.ASA_STOLEN_GOODS_ID%type
  is
    lnID ASA_STOLEN_GOODS.ASA_STOLEN_GOODS_ID%type   := null;
  begin
    select max(ASG.ASA_STOLEN_GOODS_ID)
      into lnID
      from GCO_CHARACTERIZATION CHA
         , ASA_STOLEN_GOODS ASG
         , GCO_GOOD GOO
     where CHA.C_CHARACT_TYPE = '3'
       and ASG.GCO_GOOD_ID = iGoodID
       and ASG.GCO_GOOD_ID = GOO.GCO_GOOD_ID
       and ASG.C_ASA_ASG_STATUS = '01'
       and (    (    ASG.GCO_CHAR1_ID = CHA.GCO_CHARACTERIZATION_ID
                 and ASG.ASG_CHAR1_VALUE = iCharValue)
            or (    ASG.GCO_CHAR2_ID = CHA.GCO_CHARACTERIZATION_ID
                and ASG.ASG_CHAR2_VALUE = iCharValue)
            or (    ASG.GCO_CHAR3_ID = CHA.GCO_CHARACTERIZATION_ID
                and ASG.ASG_CHAR3_VALUE = iCharValue)
            or (    ASG.GCO_CHAR4_ID = CHA.GCO_CHARACTERIZATION_ID
                and ASG.ASG_CHAR4_VALUE = iCharValue)
            or (    ASG.GCO_CHAR5_ID = CHA.GCO_CHARACTERIZATION_ID
                and ASG.ASG_CHAR5_VALUE = iCharValue)
           );

    return lnID;
  end GetStolenGoodsID;

  /*
  * function GetTariffDateRef
  * Description
  *   Renvoi la date à utiliser pour la recherche des prix ou pour les conversions
  *     en fonction de la config ASA_TARIFF_DATE_REF
  */
  function GetTariffDateRef(iRecordDateCre in date)
    return date
  is
  begin
    -- date de référence pour le calcul des prix dans un dossier SAV
    if PCS.PC_CONFIG.GetConfig('ASA_TARIFF_DATE_REF') = '1' then
      return iRecordDateCre;
    else
      return sysdate;
    end if;
  end GetTariffDateRef;
end ASA_LIB_RECORD;
