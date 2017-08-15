--------------------------------------------------------
--  DDL for Package Body FAL_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_RPT" 
is
/**
*Description
*   STORED PROCEDURE USED FOR FAL_TEPS_BY_MONTH, FAL_TEPS_BY_YEAR
*/
  procedure FAL_TEPS_RPT_PK(
    arefcursor     in out crystal_cursor_types.dualcursortyp
  , parameter_0    in     varchar2
  , parameter_1    in     varchar2
  , parameter_6    in     varchar2
  , parameter_7    in     varchar2
  , parameter_8    in     varchar2
  , procuser_lanid in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID             pcs.pc_lang.pc_lang_id%type;
    GOO_MAJOR_REFERENCE_MIN varchar2(30 char);
    GOO_MAJOR_REFERENCE_MAX varchar2(30 char);
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    if PARAMETER_0 = '*' then
      GOO_MAJOR_REFERENCE_MIN  := '(';
    else
      GOO_MAJOR_REFERENCE_MIN  := PARAMETER_0;
    end if;

    if PARAMETER_1 = '*' then
      GOO_MAJOR_REFERENCE_MAX  := '}';
    else
      GOO_MAJOR_REFERENCE_MAX  := PARAMETER_1;
    end if;

    open AREFCURSOR for
      select '3. NEED' TYP
           , GOO.GOO_MAJOR_REFERENCE
           , FNN.FAN_DESCRIPTION
           , FLO.C_LOT_STATUS
           , PER.PER_SHORT_NAME
           , STO.STO_DESCRIPTION
           , FNN.FAN_BALANCE_QTY *(-1) FAN_BALANCE_QTY
           , to_number(substr(to_char(fnn.fan_beg_plan, 'dd.MM.yyyy'), 7, 4) ) ANNEE
           , to_number(substr(to_char(fnn.fan_beg_plan, 'dd.MM.yyyy'), 4, 2) ) MOIS
           , to_number(substr(DOC_DELAY_FUNCTIONS.DATETOWEEK(fnn.fan_beg_plan), 6, 2) ) SEMAINE
           , FNN.C_GAUGE_TITLE
           , FNN.DOC_POSITION_DETAIL_ID
           , FNN.FAL_LOT_ID
           , FNN.FAL_DOC_PROP_ID
           , FNN.FAL_LOT_PROP_ID
           , STO.STM_STOCK_ID
           , '' STM_STM_LOCATION
           , FNN.FAL_PIC_LINE_ID
           , decode(FNN.FAL_PIC_LINE_ID
                  , null, ''
                  , decode(PCS.PC_CONFIG.GetConfig('FAL_PIC_WEEK_MONTH')
                         , 1, GOO2.GOO_MAJOR_REFERENCE || ' - ' || to_char(FPL.PIL_DATE, 'DD.MM.YYYY')
                         , GOO2.GOO_MAJOR_REFERENCE || ' - ' || translate(DOC_DELAY_FUNCTIONS.DateToWeek(FPL.PIL_DATE), '.', '/')
                          )
                   ) FAL_PIC_LINE_DESCR
           ,
             --COM.CST_QUANTITY_MIN,
             (select COM.CST_QUANTITY_MIN
                from GCO_COMPL_DATA_STOCK COM
               where STO.STM_STOCK_ID = com.STM_STOCK_ID(+)
                 and GOO.GCO_GOOD_ID = COM.GCO_GOOD_ID(+)) CST_QUANTITY_MIN
           , PCS.PC_CONFIG.GETCONFIG('DOC_DELAY_WEEKSTART') DOC_DELAY_WEEKSTART
        from PAC_PERSON PER
           , GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
           , FAL_LOT FLO
           , STM_STOCK STO
           , STM_LOCATION LOC
           , FAL_NETWORK_NEED FNN
           , FAL_PIC_LINE FPL
           , GCO_GOOD GOO2   --,
       --GCO_COMPL_DATA_STOCK COM
      where
             --STO.STM_STOCK_ID=COM.STM_STOCK_ID(+)
             --AND GOO.GCO_GOOD_ID=COM.GCO_GOOD_ID
             --AND
             FNN.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
         and FNN.PAC_THIRD_ID = PER.PAC_PERSON_ID(+)
         and FNN.STM_STOCK_ID = STO.STM_STOCK_ID
         and FNN.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and FNN.FAL_LOT_ID = FLO.FAL_LOT_ID(+)
         and FNN.FAL_PIC_LINE_ID = FPL.FAL_PIC_LINE_ID(+)
         and FPL.GCO_GOOD_ID = GOO2.GCO_GOOD_ID(+)
         and FNN.FAN_BEG_PLAN is not null
         and GOO.GOO_MAJOR_REFERENCE >= GOO_MAJOR_REFERENCE_MIN
         and GOO.GOO_MAJOR_REFERENCE <= GOO_MAJOR_REFERENCE_MAX
         and ( (   PARAMETER_6 = '*'
                or decode(FNN.FAL_LOT_ID, null, decode(DOC_POSITION_DETAIL_ID, null, decode(FPL.FAL_PIC_LINE_ID, null, 0, 1), 1), 1) = 1
                or (    PARAMETER_7 = 1
                    and decode(C_GAUGE_TITLE, '14', decode(FAL_DOC_PROP_ID, null, decode(FAL_LOT_PROP_ID, null, 0, 1), 1), 0) = 1)
                or (    PARAMETER_8 = 1
                    and decode(C_GAUGE_TITLE, '14', 0, decode(FAL_DOC_PROP_ID, null, decode(FAL_LOT_PROP_ID, null, 0, 1), 1) ) = 1)
               )
             )
      union all
      select '2. SUPPLY' TYP
           , GOO.GOO_MAJOR_REFERENCE
           , FNS.FAN_DESCRIPTION
           , FLO.C_LOT_STATUS
           , PER.PER_SHORT_NAME
           , STO.STO_DESCRIPTION
           , FNS.FAN_BALANCE_QTY
           , to_number(substr(to_char(fns.fan_end_plan, 'dd.MM.yyyy'), 7, 4) ) ANNEE
           , to_number(substr(to_char(fns.fan_end_plan, 'dd.MM.yyyy'), 4, 2) ) MOIS
           , to_number(substr(DOC_DELAY_FUNCTIONS.DATETOWEEK(fns.fan_end_plan), 6, 2) ) SEMAINE
           , FNS.C_GAUGE_TITLE
           , FNS.DOC_POSITION_DETAIL_ID
           , FNS.FAL_LOT_ID
           , FNS.FAL_DOC_PROP_ID
           , FNS.FAL_LOT_PROP_ID
           , STO.STM_STOCK_ID
           , '' STM_STM_LOCATION
           , FNS.FAL_PIC_LINE_ID
           , decode(FNS.FAL_PIC_LINE_ID
                  , null, ''
                  , decode(PCS.PC_CONFIG.GetConfig('FAL_PIC_WEEK_MONTH')
                         , 1, GOO2.GOO_MAJOR_REFERENCE || ' - ' || to_char(FPL.PIL_DATE, 'DD.MM.YYYY')
                         , GOO2.GOO_MAJOR_REFERENCE || ' - ' || translate(DOC_DELAY_FUNCTIONS.DateToWeek(FPL.PIL_DATE), '.', '/')
                          )
                   ) FAL_PIC_LINE_DESCR
           , (select COM.CST_QUANTITY_MIN
                from GCO_COMPL_DATA_STOCK COM
               where STO.STM_STOCK_ID = com.STM_STOCK_ID(+)
                 and GOO.GCO_GOOD_ID = COM.GCO_GOOD_ID(+)) CST_QUANTITY_MIN
           , PCS.PC_CONFIG.GETCONFIG('DOC_DELAY_WEEKSTART') DOC_DELAY_WEEKSTART
        from PAC_PERSON PER
           , GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
           , STM_STOCK STO
           , STM_LOCATION LOC
           , FAL_LOT FLO
           , FAL_NETWORK_SUPPLY FNS
           , FAL_PIC_LINE FPL
           , GCO_GOOD GOO2
       where FNS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
         and FNS.PAC_THIRD_ID = PER.PAC_PERSON_ID(+)
         and FNS.STM_STOCK_ID = STO.STM_STOCK_ID
         and FNS.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and FNS.FAL_LOT_ID = FLO.FAL_LOT_ID(+)
         and FNS.FAL_PIC_LINE_ID = FPL.FAL_PIC_LINE_ID(+)
         and FPL.GCO_GOOD_ID = GOO2.GCO_GOOD_ID(+)
         and FNS.FAN_BEG_PLAN is not null
         and GOO.GOO_MAJOR_REFERENCE >= GOO_MAJOR_REFERENCE_MIN
         and GOO.GOO_MAJOR_REFERENCE <= GOO_MAJOR_REFERENCE_MAX
         and ( (   PARAMETER_6 = '*'
                or decode(FLO.FAL_LOT_ID, null, decode(DOC_POSITION_DETAIL_ID, null, decode(FPL.FAL_PIC_LINE_ID, null, 0, 1), 1), 1) = 1
                or (    PARAMETER_7 = 1
                    and decode(C_GAUGE_TITLE, '14', decode(FAL_DOC_PROP_ID, null, decode(FAL_LOT_PROP_ID, null, 0, 1), 1), 0) = 1)
                or (    PARAMETER_8 = 1
                    and decode(C_GAUGE_TITLE, '14', 0, decode(FAL_DOC_PROP_ID, null, decode(FAL_LOT_PROP_ID, null, 0, 1), 1) ) = 1)
               )
             )
      union all
      select '1. STOCK' TYP
           , GOO.GOO_MAJOR_REFERENCE
           , ''
           , ''
           , ''
           , STO.STO_DESCRIPTION
           ,
             --SUM(SSP.SPO_THEORETICAL_QUANTITY),
             (select sum(SPO_THEORETICAL_QUANTITY)
                from STM_STOCK_POSITION
               where GCO_GOOD_ID = SSP.GCO_GOOD_ID
                 and STM_STOCK_ID = SSP.STM_STOCK_ID
                 and STM_LOCATION_ID = SSP.STM_LOCATION_ID) FAN_BALANCE_QTY
           , to_number(null)
           , to_number(null)
           , to_number(null)
           , ''
           , to_number(null)
           , to_number(null)
           , to_number(null)
           , to_number(null)
           , STO.STM_STOCK_ID
           , EMPL.LOC_DESCRIPTION
           , to_number(null)
           , ''
           , (select COM.CST_QUANTITY_MIN
                from GCO_COMPL_DATA_STOCK COM
               where STO.STM_STOCK_ID = com.STM_STOCK_ID(+)
                 and GOO.GCO_GOOD_ID = COM.GCO_GOOD_ID(+)) CST_QUANTITY_MIN
           , PCS.PC_CONFIG.GETCONFIG('DOC_DELAY_WEEKSTART') DOC_DELAY_WEEKSTART
        from STM_STOCK STO
           , STM_LOCATION LOC
           , STM_LOCATION EMPL
           , GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
           , STM_STOCK_POSITION SSP
           , the(select cast(DOC_STAT_RPT.in_list(PARAMETER_6) as char_table_type)
                   from dual) stock_id_list
       where GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
         and SSP.STM_STOCK_ID = STO.STM_STOCK_ID
         and SSP.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and ssp.gco_good_id = goo.gco_good_id
         and LOC.STM_LOCATION_ID = EMPL.STM_LOCATION_ID(+)
         and STO.STO_NEED_CALCULATION = 1
         and GOO.GOO_MAJOR_REFERENCE >= GOO_MAJOR_REFERENCE_MIN
         and GOO.GOO_MAJOR_REFERENCE <= GOO_MAJOR_REFERENCE_MAX
         and ( ( (   PARAMETER_6 = '*'
                  or (STO.STM_STOCK_ID = stock_id_list.column_value) ) ) );
  end FAL_TEPS_RPT_PK;

/**
*Description
        Used for report FAL_MPS_8WEEKS_QTY
*/
  procedure FAL_MPS_8WEEKS_QTY_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, USER_LANID in PCS.PC_LANG.LANID%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;   --user language id
    FIRSTDAY1   date;   --The first day of current week (week 1)
    FIRSTDAY2   date;   --The first day of week 1
    FIRSTDAY3   date;   --The first day of week 1
    FIRSTDAY4   date;   --The first day of week 1
    FIRSTDAY5   date;   --The first day of week 1
    FIRSTDAY6   date;   --The first day of week 1
    FIRSTDAY7   date;   --The first day of week 1
    FIRSTDAY8   date;   --The first day of week 1
    FIRSTDAY9   date;   --The first day of week 1
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(USER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;
    FIRSTDAY1    := sysdate - to_char(sysdate, 'D') + 2;   --get the date of Monday of current week
    FIRSTDAY2    := FIRSTDAY1 + 7;
    FIRSTDAY3    := FIRSTDAY2 + 7;
    FIRSTDAY4    := FIRSTDAY3 + 7;
    FIRSTDAY5    := FIRSTDAY4 + 7;
    FIRSTDAY6    := FIRSTDAY5 + 7;
    FIRSTDAY7    := FIRSTDAY6 + 7;
    FIRSTDAY8    := FIRSTDAY7 + 7;
    FIRSTDAY9    := FIRSTDAY8 + 7;

    open AREFCURSOR for
      select GOO.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , MAN.DIC_UNIT_OF_MEASURE_ID
           , LOT.LOT_REFCOMPL
           , to_char(LOT.LOT_PLAN_BEGIN_DTE, 'IW') BEGIN_DTE
           , to_char(FIRSTDAY1, 'IW') WEEK1
           , to_char(FIRSTDAY2, 'IW') WEEK2
           , to_char(FIRSTDAY3, 'IW') WEEK3
           , to_char(FIRSTDAY4, 'IW') WEEK4
           , to_char(FIRSTDAY5, 'IW') WEEK5
           , to_char(FIRSTDAY6, 'IW') WEEK6
           , to_char(FIRSTDAY7, 'IW') WEEK7
           , to_char(FIRSTDAY8, 'IW') WEEK8
           , (case LOT.C_LOT_STATUS
                when '1' then LOT.LOT_TOTAL_QTY
                when '2' then LOT.LOT_TOTAL_QTY
                when '5' then LOT.LOT_RELEASED_QTY
                else 0
              end) QTY
           , sysdate SYS_DATE
           , to_char(sysdate, 'YYYYIW') SYSWEEK
        from FAL_LOT LOT
           , GCO_GOOD GOO
           , GCO_COMPL_DATA_MANUFACTURE MAN
       where GOO.GCO_GOOD_ID = LOT.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = MAN.GCO_GOOD_ID
         and nvl(MAN.DIC_FAB_CONDITION_ID, ' ') = nvl(LOT.DIC_FAB_CONDITION_ID, ' ')
         and LOT.LOT_PLAN_BEGIN_DTE >= FIRSTDAY1
         and LOT.LOT_PLAN_BEGIN_DTE < FIRSTDAY9;
  end FAL_MPS_8WEEKS_QTY_RPT_PK;

/*
*Description
*   STORED PROCEDURE USED FOR FAL_FACTORY_FLOOR, FAL_FACTORY_FLOOR_BATCH.
    This one is used only since SP6
*/
  procedure FAL_FACTORY_FLOOR_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, USER_LANID in PCS.PC_LANG.LANID%type, parameter_0 in date)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(USER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select   FAL_FACTORY_FLOOR.FAC_REFERENCE
             , FAL_FACTORY_FLOOR.FAC_DESCRIBE
             , FAL_FACTORY_FLOOR.FAC_RESOURCE_NUMBER
             , FAL_FACTORY_RATE.FFR_VALIDITY_DATE
             , FAL_FACTORY_RATE.FFR_RATE1
             , FAL_FACTORY_RATE.FFR_RATE2
             , FAL_FACTORY_RATE.FFR_RATE3
             , FAL_FACTORY_RATE.FFR_RATE4
             , FAL_FACTORY_RATE.FFR_RATE5
             , FAL_FACTORY_FLOOR.PAC_CALENDAR_TYPE_ID
             , FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID
             , FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE2_ID
          from FAL_FACTORY_FLOOR
             , FAL_FACTORY_RATE
         where FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID = FAL_FACTORY_RATE.FAL_FACTORY_FLOOR_ID
           and FFR_validity_date <= to_date(nvl(to_char(parameter_0, 'DD.MM.YYYY'), to_char(sysdate, 'DD.MM.YYYY') ), 'DD.MM.YYYY')
      order by FAL_FACTORY_FLOOR.FAC_REFERENCE;
  end FAL_FACTORY_FLOOR_RPT_PK;

/**
*Description
        Used for report FAL_ORDER_DETAILED_BATCH
*/
  procedure FAL_ORDER_DET_BAT_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type, parameter_0 in number)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select FJP.JOP_REFERENCE
           , FLO.FAL_LOT_ID
           , FLO.GCO_GOOD_ID GCO_GOOD_ID_LOT
           , FLO.LOT_REF
           , FLO.LOT_ASKED_QTY
           , FLO.LOT_REJECT_PLAN_QTY
           , FLO.LOT_TOTAL_QTY
           , FLO.LOT_PLAN_BEGIN_DTE
           , FLO.LOT_PLAN_END_DTE
           , FLO.LOT_PLAN_LEAD_TIME
           , FLO.LOT_PLAN_NUMBER
           , FLO.FAL_SCHEDULE_PLAN_ID
           , FLO.STM_LOCATION_ID
           , FLO.PPS_OPERATION_PROCEDURE_ID
           , FLO.STM_STOCK_ID
           , FOD.FAL_ORDER_ID
           , FOD.GCO_GOOD_ID GCO_GOOD_ID_ORD
           , FOD.ORD_REF
           , FOD.ORD_OSHORT_DESCR
           , FOD.ORD_RELEASED_QTY
           , FOD.ORD_OPENED_QTY
           , FOD.ORD_STILL_TO_RELEASE_QTY
           , FOD.ORD_PLANNED_QTY
           , FOD.ORD_END_DATE
           , FOD.ORD_PSHORT_DESCR
           , (select count(*)
                from FAL_LOT_MATERIAL_LINK FML
               where FML.FAL_LOT_ID = FLO.FAL_LOT_ID) MAT_RECORD
           , (select count(*)
                from FAL_TASK_LINK FTL
               where FTL.FAL_LOT_ID = FLO.FAL_LOT_ID) TASK_RECORD
           , FLO.LOT_REFCOMPL
        from FAL_ORDER FOD
           , FAL_LOT FLO
           , FAL_JOB_PROGRAM FJP
       where FOD.FAL_ORDER_ID = FLO.FAL_ORDER_ID(+)
         and FOD.FAL_JOB_PROGRAM_ID = FJP.FAL_JOB_PROGRAM_ID(+)
         and FOD.FAL_ORDER_ID >= 1
         and FLO.FAL_LOT_ID = parameter_0;
  end FAL_ORDER_DET_BAT_RPT_PK;

/**
*Description
        Used for report FAL_ORDER_DETAILED_BATCH_HIST
*/
  procedure FAL_ORDER_DET_HIS_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type, parameter_0 in number)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select FJP.JOP_REFERENCE
           , FLO.FAL_LOT_HIST_ID FAL_LOT_ID
           , FLO.GCO_GOOD_ID GCO_GOOD_ID_LOT
           , FLO.LOT_REF
           , FLO.LOT_ASKED_QTY
           , FLO.LOT_REJECT_PLAN_QTY
           , FLO.LOT_TOTAL_QTY
           , FLO.LOT_PLAN_BEGIN_DTE
           , FLO.LOT_PLAN_END_DTE
           , FLO.LOT_PLAN_LEAD_TIME
           , FLO.LOT_PLAN_NUMBER
           , FLO.FAL_SCHEDULE_PLAN_ID
           , FLO.STM_LOCATION_ID
           , FLO.PPS_OPERATION_PROCEDURE_ID
           , FLO.STM_STOCK_ID
           , FOD.FAL_ORDER_HIST_ID FAL_ORDER_HIST_ID
           , FOD.GCO_GOOD_ID GCO_GOOD_ID_ORD
           , FOD.ORD_REF
           , FOD.ORD_OSHORT_DESCR
           , FOD.ORD_RELEASED_QTY
           , FOD.ORD_OPENED_QTY
           , FOD.ORD_STILL_TO_RELEASE_QTY
           , FOD.ORD_PLANNED_QTY
           , FOD.ORD_END_DATE
           , FOD.ORD_PSHORT_DESCR
           , (select count(*)
                from FAL_LOT_MAT_LINK_HIST FML
               where FML.FAL_LOT_HIST_ID = FLO.FAL_LOT_HIST_ID) MAT_RECORD
           , (select count(*)
                from FAL_TASK_LINK_HIST FTL
               where FTL.FAL_LOT_HIST_ID = FLO.FAL_LOT_HIST_ID) TASK_RECORD
           , FLO.LOT_REFCOMPL
        from FAL_ORDER_HIST FOD
           , FAL_LOT_HIST FLO
           , FAL_JOB_PROGRAM_HIST FJP
       where FOD.FAL_ORDER_HIST_ID = FLO.FAL_ORDER_HIST_ID(+)
         and FOD.FAL_JOB_PROGRAM_HIST_ID = FJP.FAL_JOB_PROGRAM_HIST_ID(+)
         and FOD.FAL_ORDER_HIST_ID >= 1
         and FLO.FAL_LOT_HIST_ID = parameter_0;
  end FAL_ORDER_DET_HIS_RPT_PK;
end FAL_RPT;
