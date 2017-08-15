--------------------------------------------------------
--  DDL for Package Body STM_STOCK_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_STOCK_FUNCTIONS" 
is
-----------------------------------------------------------------------------------------------------------------------
  procedure CreateMetalAccount(
    pThirdID    in     PAC_THIRD.PAC_THIRD_ID%type
  , pStockID    out    STM_STOCK.STM_STOCK_ID%type
  , pLocationID out    STM_LOCATION.STM_LOCATION_ID%type
  )
  is
  begin
    pStockID     := null;
    pLocationID  := null;

    -- Recherche si un compte poids existe déjà pour le tiers passé en paramètre
    begin
      select STM_STOCK_ID
        into pStockID
        from STM_STOCK
       where PAC_THIRD_ID = pThirdID
         and STO_METAL_ACCOUNT = 1;
    exception
      when no_data_found then
        pStockID  := null;
    end;

    if pStockID is null then
      -- Création du compte poids pour le tiers donné
      select INIT_ID_SEQ.nextval
        into pStockID
        from dual;

      insert into STM_STOCK
                  (STM_STOCK_ID
                 , STO_DESCRIPTION
                 , STO_FREE_DESCRIPTION
                 , STO_CLASSIFICATION
                 , C_ACCESS_METHOD
                 , STO_NEED_PIC
                 , STO_METAL_ACCOUNT
                 , PAC_THIRD_ID
                 , C_STO_METAL_ACCOUNT_TYPE
                 , C_THIRD_MATERIAL_RELATION_TYPE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pStockID
             , 'MA' || lpad(STM_METAL_ACCOUNT_SEQ.nextval, 6, '0')
             , 'Metal Account - ' || PER_NAME
             , (select max(STO_CLASSIFICATION) + 1
                  from STM_STOCK)
             , 'PUBLIC'
             , 0
             , 1
             , pthirdId
             , '1'
             , '2'
             , sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni
          from PAC_PERSON
         where PAC_PERSON_ID = pThirdId;
    else
      -- Recherche  de l'emplacement de stock associé au compte poids
      begin
        select STM_LOCATION_ID
          into pLocationID
          from (select   STM_LOCATION_ID
                    from STM_LOCATION
                   where STM_STOCK_ID = pStockID
                order by LOC_CLASSIFICATION)
         where rownum = 1;
      exception
        when no_data_found then
          pLocationID  := null;
      end;
    end if;

    -- Création de l'emplacement
    if pLocationID is null then
      select INIT_ID_SEQ.nextval
        into pLocationID
        from dual;

      insert into STM_LOCATION
                  (STM_LOCATION_ID
                 , STM_STOCK_ID
                 , LOC_DESCRIPTION
                 , LOC_FREE_DESCRIPTION
                 , LOC_CLASSIFICATION
                 , LOC_LOCATION_MANAGEMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pLocationID
             , STM_STOCK_ID
             , STO_DESCRIPTION
             , STO_FREE_DESCRIPTION
             , nvl( (select max(LOC_CLASSIFICATION) + 1
                       from STM_LOCATION
                      where STM_STOCK_ID = pStockID), 0)
             , 0
             , sysdate
             , pcs.PC_I_LIB_SESSION.getUserIni
          from STM_STOCK
         where STM_STOCK_ID = pStockID;
    end if;
  end CreateMetalAccount;

  /**
  * Description
  *    Indicate if stock is a metal account
  */
  function IsMetalAccount(aStockId in STM_STOCK.STM_STOCK_ID%type)
    return number
  is
    vMetalAccount STM_STOCK.STO_METAL_ACCOUNT%type;
  begin
    select STO_METAL_ACCOUNT
      into vMetalAccount
      from STM_STOCK
     where STM_STOCK_ID = aStockId;

    return vMetalAccount;
  end IsMetalAccount;

  /**
  * Description
  *    Indicates if good is linked to a metal account
  */
  function IsGoodLinkedToMetalAccount(AStockId in PAC_SUPPLIER_PARTNER.STM_STOCK_ID%type, aGoodId in GCO_ALLOY.GCO_GOOD_ID%type)
    return number
  is
    vSupplierId PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
  begin
    select max(SUP.PAC_SUPPLIER_PARTNER_ID)
      into vSupplierId
      from PAC_SUPPLIER_PARTNER SUP
         , PAC_THIRD_ALLOY ALO
         , GCO_ALLOY GAL
     where SUP.STM_STOCK_ID = aStockId
       and ALO.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
       and ALO.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID
       and GAL.GCO_GOOD_ID = aGoodId;

    return sign(vSupplierId);
  end IsGoodLinkedToMetalAccount;

  /**
  * function getStockDescription
  * Description
  *    return description of a stock
  * @created fp 01.04.2009
  * @lastUpdate
  * @public
  * @param aStockId : stock ID
  * @return description
  */
  function getStockDescription(aStockId in STM_STOCK.STM_STOCK_ID%type)
    return STM_STOCK.STO_DESCRIPTION%type
  is
    vResult STM_STOCK.STO_DESCRIPTION%type;
  begin
    select STO_DESCRIPTION
      into vResult
      from STM_STOCK
     where STM_STOCK_ID = aStockId;

    return vResult;
  exception
    when no_data_found then
      return null;
  end getStockDescription;

  /**
  * function getStockGroupListId
  * Description
  *    return the list of STM_STOCK_ID from the same group of stock than iStockId. Return null if the group origin is null.
  * @created CLG 06.2015
  * @lastUpdate
  * @public
  * @param iStockId : stock ID
  * @return list of STM_STOCK_ID
  */
  function getStockGroupListId(iStockId in STM_STOCK.STM_STOCK_ID%type)
    return varchar2
  is
    lvResult varchar2(4000);
  begin
    for tplStock in (select STM_STOCK_ID
                       from STM_STOCK
                      where DIC_STO_GROUP_ID = (select DIC_STO_GROUP_ID
                                                  from STM_STOCK
                                                 where STM_STOCK_ID = iStockId)
                        and C_ACCESS_METHOD = 'PUBLIC'
                        and nvl(STO_SUBCONTRACT, 0) = 0
                        and STO_NEED_CALCULATION = 1) loop
      if lvResult is not null then
        lvResult  := lvResult || ',';
      end if;

      lvResult  := lvResult || tplStock.STM_STOCK_ID;
    end loop;

    return lvResult;
  exception
    when no_data_found then
      return null;
  end getStockGroupListId;
end STM_STOCK_FUNCTIONS;
