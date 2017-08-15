--------------------------------------------------------
--  DDL for Package Body STM_INVENTORY_EXT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_INVENTORY_EXT_FUNCTIONS" 
is
  procedure pInsertLog(paId in STM_INVENTORY_EXTERNAL_LOG.STM_INVENTORY_EXTERNAL_LINE_ID%type, paType in varchar2, paOld in varchar2, paNew in varchar2)
-- Mise à jour du log
  is
    newId STM_INVENTORY_EXTERNAL_LOG.STM_INVENTORY_EXTERNAL_LOG_ID%type;
  begin
    select Init_id_seq.nextval
      into newId
      from dual;

    -- Insert nouveau log
    insert into STM_INVENTORY_EXTERNAL_LOG
                (STM_INVENTORY_EXTERNAL_LOG_ID
               , STM_INVENTORY_EXTERNAL_LINE_ID
               , C_INVENTORY_EXTERNAL_LOG_TYPE
               , ILO_OLD_VALUE
               , ILO_NEW_VALUE
               , A_DATECRE
               , A_IDCRE
                )
         values (newid
               , paId
               , paType
               , paOld
               , paNew
               , sysdate
               , pcs.PC_I_LIB_SESSION.GetUserIni
                );
  end;

  -- Recherche de la description du bien
  function pGetGoodDescr(paGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return varchar2
  is
    result varchar2(30);
  begin
    select GOO_MAJOR_REFERENCE
      into result
      from GCO_GOOD
     where GCO_GOOD_ID = paGoodId;

    return result;
  exception
    when no_data_found then
      return ' ';
  end pGetGoodDescr;

  -- Recherche de la description du stock
  function pGetStockDescr(paStockId in STM_STOCK.STM_STOCK_ID%type)
    return varchar2
  is
    result varchar2(30);
  begin
    select STO_DESCRIPTION
      into result
      from STM_STOCK
     where STM_STOCK_ID = paStockId;

    return result;
  exception
    when no_data_found then
      return ' ';
  end pGetStockDescr;

  -- Recherche de la description de l'emplacement
  function pGetLocationDescr(paLocationId in STM_LOCATION.STM_LOCATION_ID%type)
    return varchar2
  is
    result varchar2(30);
  begin
    select LOC_DESCRIPTION
      into result
      from STM_LOCATION
     where STM_LOCATION_ID = paLocationId;

    return result;
  exception
    when no_data_found then
      return ' ';
  end pGetLocationDescr;

  procedure STM_INSERT_LOG(paOld in STM_INVENTORY_EXTERNAL_LINE%rowtype, paNew in STM_INVENTORY_EXTERNAL_LINE%rowtype)
  is
  begin
    if paNew.C_INVENTORY_EXT_LINE_STATUS <> paOld.C_INVENTORY_EXT_LINE_STATUS then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID
               , '000'
               , PCS.PC_FUNCTIONS.GETDESCODEDESCR('C_INVENTORY_EXT_LINE_STATUS', paOld.C_INVENTORY_EXT_LINE_STATUS)
               , PCS.PC_FUNCTIONS.GETDESCODEDESCR('C_INVENTORY_EXT_LINE_STATUS', paNew.C_INVENTORY_EXT_LINE_STATUS)
                );
    end if;

    --
    if paNew.GCO_GOOD_ID <> paOld.GCO_GOOD_ID then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '001', pGetGoodDescr(paOld.GCO_GOOD_ID), pGetGoodDescr(paNew.GCO_GOOD_ID) );
    end if;

    --
    if paNew.STM_STOCK_ID <> paOld.STM_STOCK_ID then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '002', pGetStockDescr(paOld.STM_STOCK_ID), pGetStockDescr(paNew.STM_STOCK_ID) );
    end if;

    --
    if paNew.STM_LOCATION_ID <> paOld.STM_LOCATION_ID then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '003', pGetLocationDescr(paOld.STM_LOCATION_ID), pGetLocationDescr(paNew.STM_LOCAtION_ID) );
    end if;

    --
    if paNew.IEX_QUANTITY <> paOld.IEX_QUANTITY then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '004', to_char(paOld.IEX_QUANTITY), to_char(paNew.IEX_QUANTITY) );
    end if;

    --
    if paNew.IEX_CHARACTERIZATION_VALUE_1 <> paOld.IEX_CHARACTERIZATION_VALUE_1 then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '100', paOld.IEX_CHARACTERIZATION_VALUE_1, paNew.IEX_CHARACTERIZATION_VALUE_1);
    end if;

    --
    if paNew.IEX_CHARACTERIZATION_VALUE_2 <> paOld.IEX_CHARACTERIZATION_VALUE_2 then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '101', paOld.IEX_CHARACTERIZATION_VALUE_2, paNew.IEX_CHARACTERIZATION_VALUE_2);
    end if;

    --
    if paNew.IEX_CHARACTERIZATION_VALUE_3 <> paOld.IEX_CHARACTERIZATION_VALUE_3 then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '102', paOld.IEX_CHARACTERIZATION_VALUE_3, paNew.IEX_CHARACTERIZATION_VALUE_3);
    end if;

    --
    if paNew.IEX_CHARACTERIZATION_VALUE_4 <> paOld.IEX_CHARACTERIZATION_VALUE_4 then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '103', paOld.IEX_CHARACTERIZATION_VALUE_4, paNew.IEX_CHARACTERIZATION_VALUE_4);
    end if;

    --
    if paNew.IEX_CHARACTERIZATION_VALUE_5 <> paOld.IEX_CHARACTERIZATION_VALUE_5 then
      pInsertLog(paOld.STM_INVENTORY_EXTERNAL_LINE_ID, '104', paOld.IEX_CHARACTERIZATION_VALUE_5, paNew.IEX_CHARACTERIZATION_VALUE_5);
    end if;
  --
  end STM_INSERT_LOG;
end STM_INVENTORY_EXT_FUNCTIONS;
