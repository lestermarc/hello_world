--------------------------------------------------------
--  DDL for Procedure UPDATE_ORTEMS_BATCH_COLOR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "UPDATE_ORTEMS_BATCH_COLOR" (aSchemaName in varchar2)
/**
* Description
*    Export a color for batches and propositions according to their status
*
* @author   Christophe Le Gland
* @version  29.09.2004
* @public
* @param    aSchemaName
*/
is
  BuffSQL        varchar2(2000);
  Cursor_Handle  integer;
  Execute_Cursor integer;
  aLotOrPropId   varchar2(15);
  aIsLot         number;
  aStatus        number;
  aColor         char(2);

  procedure Update_Batch_Color
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'UPDATE ' || aSchemaName || '.B_OF             ';
    BuffSQL         := BuffSQL || '   SET CODECOUL = :vCODECOUL       ';
    BuffSQL         := BuffSQL || ' WHERE OF_CH_DESC1 = :vOF_CH_DESC1 ';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCODECOUL', aColor);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vOF_CH_DESC1', aLotOrPropId);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;
begin
  BuffSQL         := 'SELECT  OF_CH_DESC1 ';
  BuffSQL         := BuffSQL || 'FROM ' || aSchemaName || '.B_OF ';

  if DBMS_SQL.IS_OPEN(Cursor_Handle) then
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end if;

  Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
  DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 1, aLotOrPropId, 15);
  Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

  loop
    if DBMS_SQL.FETCH_ROWS(Cursor_Handle) > 0 then
      DBMS_SQL.COLUMN_VALUE(Cursor_Handle, 1, aLotOrPropId);

      select 1 is_lot
           , to_number(c_lot_status) status
        into aIsLot
           , aStatus
        from fal_lot
       where fal_lot_id = aLotOrPropId
      union
      select 0 is_lot
           , fal_pic_id status
        from fal_lot_prop
       where fal_lot_prop_id = aLotOrPropId;

      if aIsLot = 1 then
        if aStatus = 1 then
          -- Planned batch (green)
          aColor  := '10';
        else
          -- Launched batch (yellow)
          aColor  := '14';
        end if;
      else
        if nvl(aStatus, 0) > 0 then
          -- Propositions coming from master plan (pink)
          aColor  := '13';
        else
          -- Propositions coming from need calculation (blue)
          aColor  := '11';
        end if;
      end if;

      Update_Batch_Color;
    else
      exit;
    end if;
  end loop;

  DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
end Update_Ortems_Batch_Color;
