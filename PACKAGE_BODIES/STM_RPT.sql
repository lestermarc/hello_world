--------------------------------------------------------
--  DDL for Package Body STM_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_RPT" 
is
/**
* Description
*    This function will convert a string to table type value, which will allow to 'IN' in the SQL statement
*    Becase sometimes the string may be longer than 4000 char, so we will use type CLOB instead of VARCHAR2
*/
  function IN_LIST(PARAM_STRING in clob)
    return CHAR_TABLE_TYPE
  is
    TEMP_STRING    varchar2(32767) default PARAM_STRING || ',';
    RESULT_IN_LIST CHAR_TABLE_TYPE := CHAR_TABLE_TYPE();
    N              number;
  begin
    loop
      exit when TEMP_STRING is null;
      N                                     := instr(TEMP_STRING, ',');
      RESULT_IN_LIST.extend;
      RESULT_IN_LIST(RESULT_IN_LIST.count)  := ltrim(rtrim(substr(TEMP_STRING, 1, N - 1) ) );
      TEMP_STRING                           := substr(TEMP_STRING, N + 1);
    end loop;

    return RESULT_IN_LIST;
  end IN_LIST;

/*
*Description
*   STORED PROCEDURE USED FOR THE REPORT STM_QTY_END_OF_MONTH.RPT
*/
  procedure STM_QTY_END_OF_MONTH_RPT_PK(
    AREFCURSOR    in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP
  , PARAMETER_0   in     varchar2
  , PARAMETER_1   in     varchar2
  , PARAMETER_2   in     varchar2
  , COMPANY_LANID in     PCS.PC_LANG.LANID%type
  )
  is
    VPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(COMPANY_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open arefcursor for
      select GOO.GCO_GOOD_ID
           , GOO.C_MANAGEMENT_MODE
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , DES.C_DESCRIPTION_TYPE
           , DES.DES_LONG_DESCRIPTION
           , SAE.SAE_YEAR
           , SAE.SAE_MONTH
           , SAE.SAE_START_QUANTITY
           , SAE.SAE_OUTPUT_QUANTITY
           , SAE.SAE_INPUT_QUANTITY
           , STO.STO_DESCRIPTION
           , GCO_FUNCTIONS.GETCOSTPRICEWITHMANAGEMENTMODE(GOO.GCO_GOOD_ID, null, decode(PARAMETER_2, '0', GOO.C_MANAGEMENT_MODE, PARAMETER_2), sysdate)
                                                                                                                                                 V_PRIX_PRODUIT
        from GCO_GOOD GOO
           , STM_ANNUAL_EVOLUTION SAE
           , STM_STOCK STO
           , GCO_PRODUCT PDT
           , (select GCO_GOOD_ID
                   , C_DESCRIPTION_TYPE
                   , DES_LONG_DESCRIPTION
                from GCO_DESCRIPTION
               where PC_LANG_ID = VPC_LANG_ID
                 and C_DESCRIPTION_TYPE = '01') DES
       where GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
         and GOO.GCO_GOOD_ID = SAE.GCO_GOOD_ID(+)
         and SAE.STM_STOCK_ID = STO.STM_STOCK_ID(+)
         and GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID(+)
         and PDT.PDT_STOCK_MANAGEMENT = 1
         and SAE.SAE_YEAR = PARAMETER_0
         and SAE.SAE_MONTH between 1 and to_number(PARAMETER_1);
  end STM_QTY_END_OF_MONTH_RPT_PK;

/*
*Procedure STM_STOCK_EFFECTIF_RPT_PK
*Description
*   STORED PROCEDURE USED FOR THE REPORT STM_STOCK_EFFECTIF_BY_STOCK_VAL.RPT
*                                        STM_STOCK_EFFECTIF_VALORISED_DET.RPT
*/
  procedure STM_STOCK_EFFECTIF_RPT_PK(AREFCURSOR in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP, PARAMETER_0 in varchar2, USER_LANID in PCS.PC_LANG.LANID%type)
  is
    VPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(USER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open arefcursor for
      select GOO.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , GOO.C_MANAGEMENT_MODE
           , GOO.DIC_GOOD_FAMILY_ID
           , nvl(FAM.DIC_GOOD_FAMILY_WORDING, '-') DIC_GOOD_FAMILY_WORDING
           , DES.DES_SHORT_DESCRIPTION
           , DES.DES_LONG_DESCRIPTION
           , DES.DES_FREE_DESCRIPTION
           , STO.STO_DESCRIPTION
           , LOC.LOC_DESCRIPTION
           , SPO.SPO_STOCK_QUANTITY
           , round(GCO_FUNCTIONS.GETCOSTPRICEWITHMANAGEMENTMODE(GOO.GCO_GOOD_ID, null, decode(PARAMETER_0, '0', GOO.C_MANAGEMENT_MODE, PARAMETER_0), sysdate)
                 , 2) PRICE
        from STM_STOCK_POSITION SPO
           , GCO_GOOD GOO
           , STM_STOCK STO
           , DIC_GOOD_FAMILY FAM
           , STM_LOCATION LOC
           , (select GCO_GOOD_ID
                   , DES_SHORT_DESCRIPTION
                   , DES_LONG_DESCRIPTION
                   , DES_FREE_DESCRIPTION
                from GCO_DESCRIPTION
               where PC_LANG_ID = VPC_LANG_ID
                 and C_DESCRIPTION_TYPE = '01') DES
       where SPO.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and SPO.STM_STOCK_ID = STO.STM_STOCK_ID
         and SPO.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID(+)
         and GOO.DIC_GOOD_FAMILY_ID = FAM.DIC_GOOD_FAMILY_ID(+);
  end STM_STOCK_EFFECTIF_RPT_PK;

/*
*Description
*   STORED PROCEDURE USED FOR THE REPORT STM_STOCK_EFFECTIF_VALORISED_GAMME.RPT
*/
  procedure STM_STOCK_EFF_VAL_GAMME_RPT_PK(
    AREFCURSOR   in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP
  , PARAMETER_0  in     varchar2
  , PARAMETER_1  in     varchar2
  , PARAMETER_7  in     varchar2
  , PARAMETER_8  in     varchar2
  , PARAMETER_9  in     varchar2
  , PARAMETER_12 in     clob
  , PARAMETER_13 in     clob
  , USER_LANID   in     PCS.PC_LANG.LANID%type
  )
  is
    GOO_MAJOR_REFERENCE_MIN varchar2(30 char);
    GOO_MAJOR_REFERENCE_MAX varchar2(30 char);
    category                varchar2(4000 char);
  begin
    if     PARAMETER_7 <> '0'
       and PARAMETER_1 = '1' then
      category  := PARAMETER_7;
    else
      category  := '*';
    end if;

    if PARAMETER_8 <> '0' then
      GOO_MAJOR_REFERENCE_MIN  := PARAMETER_8;
    else
      GOO_MAJOR_REFERENCE_MIN  := '(';
    end if;

    if PARAMETER_9 <> '0' then
      GOO_MAJOR_REFERENCE_MAX  := PARAMETER_9;
    else
      GOO_MAJOR_REFERENCE_MAX  := '}';
    end if;

    open arefcursor for
      select GOO.GCO_GOOD_ID
           , GOO.C_MANAGEMENT_MODE
           , GOO.GOO_MAJOR_REFERENCE
           , CAT.GCO_GOOD_CATEGORY_WORDING
           , LIN.DIC_GOOD_LINE_WORDING
           , FAM.DIC_GOOD_FAMILY_WORDING
           , mod.DIC_GOOD_MODEL_WORDING
           , GRP.DIC_GOOD_GROUP_WORDING
           , FCP.CPR_PRICE
           , GCO_FUNCTIONS.GETCOSTPRICEWITHMANAGEMENTMODE(GOO.GCO_GOOD_ID, null, decode(PARAMETER_0, '0', GOO.C_MANAGEMENT_MODE, PARAMETER_0), sysdate) PRICE
           , STM_FUNCTIONS.GetQtyStock(GOO.GCO_GOOD_ID, PARAMETER_12, PARAMETER_13) / 1000 QTY
           , STM_FUNCTIONS.GetQtyCC(GOO.GCO_GOOD_ID, PARAMETER_12, PARAMETER_13) / 1000 QTY_CC
           , STM_FUNCTIONS.GetQtyCF(GOO.GCO_GOOD_ID, PARAMETER_12, PARAMETER_13) / 1000 QTY_CF
           , GCO_FUNCTIONS.GetDescription(GOO.GCO_GOOD_ID, USER_LANID, 1, '01') DES_SHORT_DESCRIPTION
        from GCO_GOOD GOO
           , GCO_PRODUCT PDT
           , GCO_GOOD_CATEGORY CAT
           , DIC_GOOD_LINE LIN
           , DIC_GOOD_FAMILY FAM
           , DIC_GOOD_MODEL mod
           , DIC_GOOD_GROUP GRP
           , (select GCO_GOOD_ID
                   , CPR_PRICE
                from PTC_FIXED_COSTPRICE
               where C_COSTPRICE_STATUS = 'ACT'
                 and CPR_DEFAULT = 1) FCP
       where GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
         and GOO.DIC_GOOD_LINE_ID = LIN.DIC_GOOD_LINE_ID(+)
         and GOO.DIC_GOOD_FAMILY_ID = FAM.DIC_GOOD_FAMILY_ID(+)
         and GOO.DIC_GOOD_MODEL_ID = mod.DIC_GOOD_MODEL_ID(+)
         and GOO.DIC_GOOD_GROUP_ID = GRP.DIC_GOOD_GROUP_ID(+)
         and GOO.GCO_GOOD_ID = FCP.GCO_GOOD_ID(+)
         and PDT.PDT_STOCK_MANAGEMENT = 1
         and GOO.C_GOOD_STATUS <> '3'
         and CAT.GCO_GOOD_CATEGORY_WORDING like LIKE_PARAM(category)
         and GOO.GOO_MAJOR_REFERENCE between GOO_MAJOR_REFERENCE_MIN and GOO_MAJOR_REFERENCE_MAX;
  end STM_STOCK_EFF_VAL_GAMME_RPT_PK;

/*
*Description
*   STORED PROCEDURE USED FOR THE SUB-REPORT MAGLIST.RPT OF STM_STOCK_EFFECTIF_VALORISED_GAMME.RPT
*/
  procedure STM_MAGLIST_SUB_RPT_PK(AREFCURSOR in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP, PARAMETER_12 in clob, PARAMETER_13 in clob)
  is
  begin
    open arefcursor for
      select LOC.LOC_DESCRIPTION
           , STO.STO_DESCRIPTION
        from STM_LOCATION LOC
           , STM_STOCK STO
           , the(select cast(in_list(PARAMETER_12) as char_table_type)
                   from dual) STOCK_LIST
           , the(select cast(in_list(PARAMETER_13) as char_table_type)
                   from dual) LOCATION_LIST
       where STO.STM_STOCK_ID = LOC.STM_STOCK_ID
         and STO.STM_STOCK_ID = to_number(STOCK_LIST.column_value)
         and LOC.STM_LOCATION_ID = to_number(LOCATION_LIST.column_value);
  end STM_MAGLIST_SUB_RPT_PK;

/*
*Description
*   STORED PROCEDURE USED FOR THE REPORT STM_STOCK_EFFECTIF_VAL.RPT
*/
  procedure STM_STOCK_EFFECTIF_VAL_RPT_PK(
    AREFCURSOR   in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP
  , PARAMETER_0  in     varchar2
  , PARAMETER_1  in     varchar2
  , PARAMETER_7  in     varchar2
  , PARAMETER_8  in     varchar2
  , PARAMETER_9  in     varchar2
  , PARAMETER_12 in     clob
  , PARAMETER_13 in     clob
  , USER_LANID   in     PCS.PC_LANG.LANID%type
  )
  is
    GOO_MAJOR_REFERENCE_MIN varchar2(30 char);
    GOO_MAJOR_REFERENCE_MAX varchar2(30 char);
    category                varchar2(50 char);
  begin
    if     PARAMETER_7 <> '0'
       and PARAMETER_1 = '1' then
      category  := PARAMETER_7;
    else
      category  := '*';
    end if;

    if PARAMETER_8 <> '0' then
      GOO_MAJOR_REFERENCE_MIN  := PARAMETER_8;
    else
      GOO_MAJOR_REFERENCE_MIN  := '(';
    end if;

    if PARAMETER_9 <> '0' then
      GOO_MAJOR_REFERENCE_MAX  := PARAMETER_9;
    else
      GOO_MAJOR_REFERENCE_MAX  := '}';
    end if;

    open arefcursor for
      select GOO.GCO_GOOD_ID
           , GOO.C_MANAGEMENT_MODE
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , CAT.GCO_GOOD_CATEGORY_WORDING
           , LIN.DIC_GOOD_LINE_WORDING
           , FAM.DIC_GOOD_FAMILY_WORDING
           , mod.DIC_GOOD_MODEL_WORDING
           , GRP.DIC_GOOD_GROUP_WORDING
           , SPO.SPO_STOCK_QUANTITY
           , GCO_FUNCTIONS.GETCOSTPRICEWITHMANAGEMENTMODE(GOO.GCO_GOOD_ID, null, decode(PARAMETER_0, '0', GOO.C_MANAGEMENT_MODE, PARAMETER_0), sysdate)
                                                                                                                                                 V_PRIX_PRODUIT
           , GCO_FUNCTIONS.GetDescription(GOO.GCO_GOOD_ID, USER_LANID, 1, '01') DES_SHORT_DESCRIPTION
        from STM_STOCK_POSITION SPO
           , GCO_GOOD GOO
           , STM_STOCK STO
           , STM_LOCATION LOC
           , GCO_GOOD_CATEGORY CAT
           , DIC_GOOD_LINE LIN
           , DIC_GOOD_FAMILY FAM
           , DIC_GOOD_MODEL mod
           , DIC_GOOD_GROUP GRP
           , the(select cast(in_list(PARAMETER_12) as char_table_type)
                   from dual) STOCK_LIST
           , the(select cast(in_list(PARAMETER_13) as char_table_type)
                   from dual) LOCATION_LIST
       where SPO.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and SPO.STM_STOCK_ID = STO.STM_STOCK_ID
         and SPO.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
         and GOO.DIC_GOOD_LINE_ID = LIN.DIC_GOOD_LINE_ID(+)
         and GOO.DIC_GOOD_FAMILY_ID = FAM.DIC_GOOD_FAMILY_ID(+)
         and GOO.DIC_GOOD_MODEL_ID = mod.DIC_GOOD_MODEL_ID(+)
         and GOO.DIC_GOOD_GROUP_ID = GRP.DIC_GOOD_GROUP_ID(+)
         and GOO.C_GOOD_STATUS <> '3'
         and CAT.GCO_GOOD_CATEGORY_WORDING like LIKE_PARAM(category)
         and GOO.GOO_MAJOR_REFERENCE between GOO_MAJOR_REFERENCE_MIN and GOO_MAJOR_REFERENCE_MAX
         and STO.STM_STOCK_ID = to_number(STOCK_LIST.column_value)
         and LOC.STM_LOCATION_ID = to_number(LOCATION_LIST.column_value);
  end STM_STOCK_EFFECTIF_VAL_RPT_PK;

/*
*Description
*   STORED PROCEDURE USED FOR THE REPORT STM_QTY_END_OF_MONTH_WITH_GROUP.RPT
*/
  procedure STM_QTY_EOM_WTIH_GRP_RPT_PK(
    AREFCURSOR   in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP
  , PARAMETER_0  in     varchar2
  , PARAMETER_1  in     varchar2
  , PARAMETER_7  in     varchar2
  , PARAMETER_8  in     varchar2
  , PARAMETER_9  in     varchar2
  , PARAMETER_11 in     varchar2
  , PARAMETER_12 in     clob
  , PARAMETER_13 in     clob
  , USER_LANID   in     PCS.PC_LANG.LANID%type
  )
  is
    VPC_LANG_ID             PCS.PC_LANG.PC_LANG_ID%type;
    P_CATEGORY_WORDING      varchar2(200 char);
    GOO_MAJOR_REFERENCE_MIN varchar2(200 char);
    GOO_MAJOR_REFERENCE_MAX varchar2(200 char);
    T_DATE                  date;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(USER_LANID);
    VPC_LANG_ID  := PCS.PC_I_LIB_SESSION.GETUSERLANGID;

    if     PARAMETER_7 <> '0'
       and PARAMETER_1 = '1' then
      P_CATEGORY_WORDING  := PARAMETER_7;
    else
      P_CATEGORY_WORDING  := '*';
    end if;

    if PARAMETER_8 <> '0' then
      GOO_MAJOR_REFERENCE_MIN  := PARAMETER_8;
    else
      GOO_MAJOR_REFERENCE_MIN  := '(';
    end if;

    if PARAMETER_9 <> '0' then
      GOO_MAJOR_REFERENCE_MAX  := PARAMETER_9;
    else
      GOO_MAJOR_REFERENCE_MAX  := '}';
    end if;

/*
IF PARAMETER_11 ='0'
 THEN
   T_DATE := TRUNC(SYSDATE);
ELSIF SUBSTR(PARAMETER_11,1,6) = TO_CHAR(SYSDATE,'YYYYMM')
 THEN T_DATE := TRUNC(SYSDATE);
ELSE
   T_DATE := LAST_DAY(TO_DATE(PARAMETER_11,'YYYYMMDD'));
END IF;
*/
    T_DATE       := to_date(PARAMETER_11, 'YYYYMMDD');

    open AREFCURSOR for
      select FAM.DIC_GOOD_FAMILY_WORDING
           , GRP.DIC_GOOD_GROUP_WORDING
           , LNE.DIC_GOOD_LINE_WORDING
           , mod.DIC_GOOD_MODEL_WORDING
           , GOO.GCO_GOOD_ID
           , GOO.C_GOOD_STATUS
           , GOO.C_MANAGEMENT_MODE
           , GOO.GOO_MAJOR_REFERENCE
           , CAT.GCO_GOOD_CATEGORY_WORDING
           , STM_FUNCTIONS.GETSELECTEDSTOCKATDATE(GOO.GCO_GOOD_ID, to_char(T_DATE, 'YYYYMMDD'), PARAMETER_12, PARAMETER_13) QTY_LIG
           , GCO_FUNCTIONS.GETDESCRIPTION(GOO.GCO_GOOD_ID, USER_LANID, 1, '01') V_DESCR
           , GCO_FUNCTIONS.GETCOSTPRICEWITHMANAGEMENTMODE(GOO.GCO_GOOD_ID, null, decode(PARAMETER_0, '0', GOO.C_MANAGEMENT_MODE, PARAMETER_0), T_DATE)
                                                                                                                                                 V_PRIX_PRODUIT
        from GCO_GOOD GOO
           , DIC_GOOD_FAMILY FAM
           , DIC_GOOD_GROUP GRP
           , DIC_GOOD_LINE LNE
           , DIC_GOOD_MODEL mod
           , GCO_GOOD_CATEGORY CAT
       where GOO.GCO_GOOD_ID in(select PDT.GCO_GOOD_ID
                                  from GCO_PRODUCT PDT
                                 where PDT.STM_LOCATION_ID is not null)
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
         and GOO.DIC_GOOD_LINE_ID = LNE.DIC_GOOD_LINE_ID(+)
         and GOO.DIC_GOOD_FAMILY_ID = FAM.DIC_GOOD_FAMILY_ID(+)
         and GOO.DIC_GOOD_MODEL_ID = mod.DIC_GOOD_MODEL_ID(+)
         and GOO.DIC_GOOD_GROUP_ID = GRP.DIC_GOOD_GROUP_ID(+)
         and GOO.C_GOOD_STATUS <> '3'
         and CAT.GCO_GOOD_CATEGORY_WORDING like LIKE_PARAM(P_CATEGORY_WORDING)
         and GOO.GOO_MAJOR_REFERENCE between GOO_MAJOR_REFERENCE_MIN and GOO_MAJOR_REFERENCE_MAX;
  end STM_QTY_EOM_WTIH_GRP_RPT_PK;
end STM_RPT;
