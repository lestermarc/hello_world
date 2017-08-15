--------------------------------------------------------
--  DDL for Package Body STM_PRC_STOCK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_STOCK" 
is
  /**
  * Description
  *    creation of a sucontractor stock and its location
  */
  procedure CreateSubcontractStock(
    iSupplierID in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , oStockID    out    STM_STOCK.STM_STOCK_ID%type
  , oLocationID out    STM_LOCATION.STM_LOCATION_ID%type
  )
  is
    ltCRUD_DEF          FWK_I_TYP_DEFINITION.t_crud_def;
    lstoDescription     STM_STOCK.STO_DESCRIPTION%type;
    lstoFreeDescription STM_STOCK.STO_FREE_DESCRIPTION%type;
    lstoClassification  STM_STOCK.STO_CLASSIFICATION%type;
    lClassification     STM_LOCATION.LOC_CLASSIFICATION%type;
  begin
    oStockID     := null;
    oLocationID  := null;

    -- Recherche si un stock sous-traitant existe déjà pour le tiers passé en paramètre
    begin
      select STM_STOCK_ID
        into oStockID
        from STM_STOCK
       where PAC_SUPPLIER_PARTNER_ID = iSupplierID
         and STO_SUBCONTRACT = 1;
    exception
      when no_data_found then
        oStockID  := null;
    end;

    if oStockID is null then
      -- Création du stock sous-traitance pour le fournisseur donné
      select INIT_ID_SEQ.nextval
        into oStockID
        from dual;

      select 'Subcontractor - ' || PER_NAME
           , (select max(STO_CLASSIFICATION) + 1
                from STM_STOCK)
        into lstoFreeDescription
           , lstoClassification
        from PAC_PERSON
       where PAC_PERSON_ID = iSupplierId;

      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmStock, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_ID', oStockID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STO_DESCRIPTION', 'ST' || lpad(STM_SUBCONTRACT_SEQ.nextval, 6, '0') );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STO_FREE_DESCRIPTION', lstoFreeDescription);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STO_CLASSIFICATION', lstoClassification);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ACCESS_METHOD', 'PUBLIC');
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STO_SUBCONTRACT', 1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_SUPPLIER_PARTNER_ID', iSupplierId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', pcs.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;
--      insert into STM_STOCK
--                  (STM_STOCK_ID
--                 , STO_DESCRIPTION
--                 , STO_FREE_DESCRIPTION
--                 , STO_CLASSIFICATION
--                 , C_ACCESS_METHOD
--                 , STO_SUBCONTRACT
--                 , PAC_SUPPLIER_PARTNER_ID
--                 , A_DATECRE
--                 , A_IDCRE
--                  )
--        select pStockID
--             , 'ST' || lpad(STM_SUBCONTRACT_SEQ.nextval, 6, '0')
--             , 'Subcontractor - ' || PER_NAME
--             , (select max(STO_CLASSIFICATION) + 1
--                  from STM_STOCK)
--             , 'PUBLIC'
--             , 1
--             , pSupplierId
--             , sysdate
--             , pcs.PC_I_LIB_SESSION.GetUserIni
--          from PAC_PERSON
--         where PAC_PERSON_ID = pSupplierId;
    else
      -- Recherche  de l'emplacement de stock associé au stock sous-traitant
      begin
        select STM_LOCATION_ID
          into oLocationID
          from (select   STM_LOCATION_ID
                    from STM_LOCATION
                   where STM_STOCK_ID = oStockID
                order by LOC_CLASSIFICATION)
         where rownum = 1;
      exception
        when no_data_found then
          oLocationID  := null;
      end;
    end if;

    -- Création de l'emplacement
    if oLocationID is null then
      select INIT_ID_SEQ.nextval
        into oLocationID
        from dual;

      select STO_DESCRIPTION
           , STO_FREE_DESCRIPTION
           , nvl( (select max(LOC_CLASSIFICATION) + 1
                     from STM_LOCATION
                    where STM_STOCK_ID = oStockID), 0)
        into lstoDescription
           , lstoFreeDescription
           , lClassification
        from STM_STOCK
       where STM_STOCK_ID = oStockID;

      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmLocation, ltCRUD_DEF, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_LOCATION_ID', oLocationID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_ID', oStockID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOC_DESCRIPTION', lstoDescription);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOC_FREE_DESCRIPTION', lstoFreeDescription);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOC_CLASSIFICATION', lClassification);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOC_LOCATION_MANAGEMENT', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOC_CONTINUOUS_INVENTAR', 1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', pcs.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;
--      insert into STM_LOCATION
--                  (STM_LOCATION_ID
--                 , STM_STOCK_ID
--                 , LOC_DESCRIPTION
--                 , LOC_FREE_DESCRIPTION
--                 , LOC_CLASSIFICATION
--                 , LOC_LOCATION_MANAGEMENT
--                 , A_DATECRE
--                 , A_IDCRE
--                  )
--        select pLocationID
--             , STM_STOCK_ID
--             , STO_DESCRIPTION
--             , STO_FREE_DESCRIPTION
--             , nvl( (select max(LOC_CLASSIFICATION) + 1
--                       from STM_LOCATION
--                      where STM_STOCK_ID = pStockID), 0)
--             , 0
--             , sysdate
--             , pcs.PC_I_LIB_SESSION.getUserIni
--          from STM_STOCK
--         where STM_STOCK_ID = pStockID;
    end if;
  end CreateSubcontractStock;
end STM_PRC_STOCK;
