--------------------------------------------------------
--  DDL for Package Body STM_LIB_STOCK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_LIB_STOCK" 
is
  /**
  * Description
  *    return the default location of a stock regarding the smallest classification number
  */
  function GetDefaultLocation(iStockId in STM_STOCK.STM_STOCK_ID%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    lClassif STM_LOCATION.LOC_CLASSIFICATION%type;
    lResult  STM_LOCATION.STM_LOCATION_ID%type;
  begin
    -- return the min classification
    select min(LOC_CLASSIFICATION)
      into lClassif
      from STM_LOCATION
     where STM_STOCK_ID = iStockId;

    -- look for the location identifier
    select STM_LOCATION_ID
      into lResult
      from STM_LOCATION
     where STM_STOCK_ID = iStockId
       and LOC_CLASSIFICATION = lClassif;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetDefaultLocation;

  /**
  * function GetStockId
  * Description
  *    return Stock id from a location
  * @created ag 08.05.2012
  * @lastUpdate
  * @public
  * @param iLocationId
  * @return STM_STOCK_ID
  */
  function GetStockId(iLocationId in STM_LOCATION.STM_LOCATION_ID%type)
    return STM_LOCATION.STM_STOCK_ID%type
  is
    lvResult STM_LOCATION.STM_STOCK_ID%type;
  begin
    if iLocationId is not null then
      begin
        select STM_STOCK_ID
          into lvResult
          from STM_LOCATION
         where STM_LOCATION_ID = iLocationId;
      exception
        when no_data_found then
          lvResult  := null;
      end;
    end if;

    return lvResult;
  end;

  /**
  * Description
  *    return true if stock is Virtual
  */
  function IsVirtual(iStockId in STM_STOCK.STM_STOCK_ID%type)
    return number deterministic
  is
    lAccessMethod STM_STOCK.C_ACCESS_METHOD%type;
  begin
    select C_ACCESS_METHOD
      into lAccessMethod
      from STM_STOCK
     where STM_STOCK_ID = iStockId;

    if (lAccessMethod = 'DEFAULT') then
      return 1;
    else
      return 0;
    end if;
  end IsVirtual;

  /**
  * Description
  *   Retourne le stock virtuel
  */
  function GetDefaultStock
    return STM_STOCK.STM_STOCK_ID%type
  is
    lResult STM_STOCK.STM_STOCK_ID%type;
  begin
    /* Recherche du stock DEFAULT. */
    select STM_STOCK_ID
      into lResult
      from STM_STOCK
     where C_ACCESS_METHOD = 'DEFAULT';

    return lResult;
  exception
    when no_data_found then
      raise_application_error(-20020, PCS.PC_FUNCTIONS.TranslateWord('Un stock pour un bien sans gestion de stock doit être définit') );
  end;

  /**
  * Description
  *   Retourne la clef primaire du stock affaire par défaut (selon config GCO_DefltSTOCK_PROJECT).
  */
  function GetDefaultProjectStock
    return STM_STOCK.STM_STOCK_ID%type
  is
    lnStockID STM_STOCK.STM_STOCK_ID%type;
  begin
    select STM_STOCK_ID
      into lnStockID
      from STM_STOCK
     where upper(STO_DESCRIPTION) = upper(PCS.PC_CONFIG.GetConfig('GCO_DefltSTOCK_PROJECT') );

    return lnStockID;
  exception
    when no_data_found then
      return null;
  end GetDefaultProjectStock;

  /**
  * Description
  *    Retourne l'emplacement de stock affaire par défaut du stock affaire par défaut (selon config)
  */
  function GetDefaultProjectLocation(inDefaultProjectStockID in STM_STOCK.STM_STOCK_ID%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    lnLocationID STM_LOCATION.STM_LOCATION_ID%type;
  begin
    select STM_LOCATION_ID
      into lnLocationID
      from STM_LOCATION
     where STM_STOCK_ID = inDefaultProjectStockID
       and upper(LOC_DESCRIPTION) = upper(PCS.PC_CONFIG.GetConfig('GCO_DefltLOCATION_PROJECT') );

    return lnLocationID;
  exception
    when no_data_found then
      return null;
  end GetDefaultProjectLocation;

  /**
  * Description
  *    Retourne le stock affaire et l'emplacement de stock affaire par défaut du stock affaire par défaut (selon configs)
  */
  procedure GetDefltProjectStockAndLoc(onDfltProjectStockID out STM_STOCK.STM_STOCK_ID%type, onDfltProjectLocationID out STM_LOCATION.STM_LOCATION_ID%type)
  is
  begin
    /* Récupération du stock affaire par défaut selon config. */
    onDfltProjectStockID     := GetDefaultProjectStock;
    /* Récupération de l'emplacement de stock affaire par défaut selon config */
    onDfltProjectLocationID  := GetDefaultProjectLocation(inDefaultProjectStockID => onDfltProjectStockID);
  end GetDefltProjectStockAndLoc;

  /**
  * Description
  *    return stock and location for a customer
  */
  procedure getSubCStockAndLocation(
    iSupplierId in     STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type
  , oStockId    out    STM_STOCK.STM_STOCK_ID%type
  , oLocationId out    STM_LOCATION.STM_LOCATION_ID%type
  )
  is
  begin
    -- looking for supplier stock
    select STM_STOCK_ID
      into oStockId
      from STM_STOCK
     where PAC_SUPPLIER_PARTNER_ID = iSupplierId
       and STO_SUBCONTRACT = 1;

    -- looking for default location
    oLocationId  := GetDefaultLocation(oStockId);
  exception
    when no_data_found then
      oStockId     := null;
      oLocationId  := null;
  end getSubCStockAndLocation;

  /**
  * Description
  *    return customer subcontract stock description
  */
  function getSubCStockDescription(iSupplierId in STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type)
    return STM_STOCK.STO_DESCRIPTION%type
  is
    lResult STM_STOCK.STO_DESCRIPTION%type;
  begin
    -- looking for supplier stock
    select STO_DESCRIPTION
      into lResult
      from STM_STOCK
     where PAC_SUPPLIER_PARTNER_ID = iSupplierId
       and STO_SUBCONTRACT = 1;

    return lResult;
  end getSubCStockDescription;

  /**
  * function getSubCStockID
  * Description
  *    return customer subcontract stock description
  * @created ag 07.05.2012
  * @lastUpdate
  * @public
  * @param  iSupplierId
  * @return identifiant du stock
  */
  function getSubCStockID(iSupplierId in STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type)
    return STM_STOCK.STM_STOCK_ID%type
  is
    lvResult STM_STOCK.STM_STOCK_ID%type;
  begin
    begin
      select STM_STOCK_ID
        into lvResult
        from STM_STOCK
       where PAC_SUPPLIER_PARTNER_ID = iSupplierId
         and STO_SUBCONTRACT = 1;
    exception
      when no_data_found then
        lvResult  := null;
    end;

    return lvResult;
  end getSubCStockID;

    /**
  * function getSubCPartnerID
  * Description
  *    return supplier subcontract id
  * @created ag 07.05.2012
  * @lastUpdate
  * @public
  * @param  iStockId
  * @param  iLocationId
  * @return identifiant du fournisseur sous-traitant
  */
  function getSubCPartnerID(iStockId in STM_STOCK.STM_STOCK_ID%type default null, iLocationId in STM_LOCATION.STM_LOCATION_ID%type default null)
    return STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type
  is
    lvResult STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type;
  begin
    if iStockId is not null then
      begin
        select PAC_SUPPLIER_PARTNER_ID
          into lvResult
          from STM_STOCK
         where STM_STOCK_ID = iStockId
           and STO_SUBCONTRACT = 1;
      exception
        when no_data_found then
          lvResult  := null;
      end;
    elsif iLocationId is not null then
      begin
        select PAC_SUPPLIER_PARTNER_ID
          into lvResult
          from STM_STOCK STO
             , STM_LOCATION LOC
         where STO.STM_STOCK_ID = LOC.STM_STOCK_ID
           and LOC.STM_LOCATION_ID = iLocationId
           and STO_SUBCONTRACT = 1;
      exception
        when no_data_found then
          lvResult  := null;
      end;
    end if;

    return lvResult;
  end getSubCPartnerID;

  /**
  * Description
  *    return si le stock est de type sous-traitant en fonction de l'id du stock
  */
  function getSubContract(iStockId in STM_STOCK.STM_STOCK_ID%type)
    return STM_STOCK.STO_SUBCONTRACT%type
  is
    lResult STM_STOCK.STO_SUBCONTRACT%type;
  begin
    select STO_SUBCONTRACT
      into lResult
      from STM_STOCK
     where STM_STOCK_ID = iStockId;

    return lResult;
  exception
    when no_data_found then
      return 0;
  end getSubContract;

  /**
  * Description
  *    return la description du stock
  */
  function getDescriptionStock(iStockId in STM_STOCK.STM_STOCK_ID%type)
    return STM_STOCK.STO_DESCRIPTION%type
  is
    lvResult STM_STOCK.STO_DESCRIPTION%type;
  begin
    select max(STO_DESCRIPTION)
      into lvResult
      from STM_STOCK
     where STM_STOCK_ID = iStockId;

    return lvResult;
  end getDescriptionStock;

  /**
  * Description
  *    return la description du stock
  */
  function getStockDescr(iStockID in STM_STOCK.STM_STOCK_ID%type)
    return STM_STOCK.STO_DESCRIPTION%type
  as
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'STM_STOCK', iv_column_name => 'STO_DESCRIPTION', it_pk_value => iStockID);
  end getStockDescr;

  /**
  * Description
  *    return la description de l'emplacement de stock
  */
  function getLocationDescr(iLocationID in STM_LOCATION.STM_LOCATION_ID%type)
    return STM_LOCATION.LOC_DESCRIPTION%type
  as
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'STM_LOCATION', iv_column_name => 'LOC_DESCRIPTION', it_pk_value => iLocationID);
  end getLocationDescr;
end STM_LIB_STOCK;
