--------------------------------------------------------
--  DDL for Package Body FAL_FACTORY_CHARGE_ANALYSIS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_FACTORY_CHARGE_ANALYSIS" 
is
  -- Rattrapage du retard = Planification date d�but des lots s�lectionn�s � partir de la date du jour
  procedure PlanLot_DelayCorrection(aFilter varchar2, aBeginDate date, aEndDate date)
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    varFalLotId    FAL_LOT.FAL_LOT_ID%type;
  begin
    BuffSQL         := aFilter;
    Cursor_Handle   := DBMS_SQL.open_cursor;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.bind_variable(Cursor_Handle, ':BEGIN_DATE', aBeginDate);
    DBMS_SQL.bind_variable(Cursor_Handle, ':END_DATE', sysdate);   -- PRD-A040816-64185
    DBMS_SQL.Define_column(Cursor_Handle, 1, varFalLotId);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    loop
      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, varFalLotId);
        FAL_PLANIF.Planification_lot(varFalLotId, sysdate, FAL_PLANIF.ctDateDebut, FAL_PLANIF.ctAvecMAJLienCompoLot, FAL_PLANIF.ctAvecMAJReseau);
      else
        exit;
      end if;
    end loop;

    DBMS_SQL.close_cursor(Cursor_Handle);
  end;

  -- Rattrapage du retard = Planification date d�but des props s�lectionn�es � partir de la date du jour
  procedure PlanProp_DelayCorrection(aFilter varchar2, aBeginDate date, aEndDate date)
  is
    BuffSQL         varchar2(2000);
    Cursor_Handle   integer;
    Execute_Cursor  integer;
    varFalLotPropId FAL_LOT_PROP.FAL_LOT_PROP_ID%type;
  begin
    BuffSQL         := aFilter;
    Cursor_Handle   := DBMS_SQL.open_cursor;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.bind_variable(Cursor_Handle, ':BEGIN_DATE', aBeginDate);
    DBMS_SQL.bind_variable(Cursor_Handle, ':END_DATE', sysdate);
    DBMS_SQL.Define_column(Cursor_Handle, 1, varFalLotPropId);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    loop
      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, varFalLotPropId);
        FAL_PLANIF.Planification_lot_Prop(varFalLotPropId, sysdate, FAL_PLANIF.ctDateDebut, FAL_PLANIF.ctAvecMAJLienCompoLot, FAL_PLANIF.ctAvecMAJReseau);
      else
        exit;
      end if;
    end loop;

    DBMS_SQL.close_cursor(Cursor_Handle);
  end;

  -- Rattrapage du retard = Planification date d�but des lots s�lectionn�s � partir de la date du jour
  procedure PlanBusiness_DelayCorrection(aFilter varchar2, aBeginDate date, aEndDate date)
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    varGalTaskId   GAL_TASK.GAL_TASK_ID%type;
    aTaskBeginDate date;
    aTaskEndDate   date;
    aTaskDuration  number;
  begin
    BuffSQL         := aFilter;
    Cursor_Handle   := DBMS_SQL.open_cursor;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.bind_variable(Cursor_Handle, ':BEGIN_DATE', aBeginDate);
    DBMS_SQL.bind_variable(Cursor_Handle, ':END_DATE', sysdate);   -- PRD-A040816-64185
    DBMS_SQL.Define_column(Cursor_Handle, 1, varGalTaskId);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    loop
      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, varGalTaskId);
        FAL_PLANIF.GeneralPlanning(varGalTaskId   -- ID Tache
                                 , null   -- Pas besoin du produit, car planif selon op
                                 , null   -- Cond fabrication
                                 , null   -- Date plan debut tache
                                 , null   -- Date plan fin tache
                                 , '2'   -- Plannif selon operation.
                                 , 0   -- Tolerance
                                 , 1   -- Update on tache (dates, dur�es...)
                                 , sysdate   -- Date de planification
                                 , 1   -- Selon date d�but
                                 , 1   -- Qt�
                                 , 1   -- Capa infinie
                                 , aTaskBeginDate   -- Nvelle date d�but de tache
                                 , aTaskEndDate   -- Nvelle date fin de tache
                                 , aTaskDuration   -- Nvelle dur�e de tache
                                  );
      else
        exit;
      end if;
    end loop;

    DBMS_SQL.close_cursor(Cursor_Handle);
  end;
end;
