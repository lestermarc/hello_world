--------------------------------------------------------
--  DDL for Package Body FAL_ADV_CALC_PRINT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ADV_CALC_PRINT" 
is
  cSessionId constant varchar2(30) := DBMS_SESSION.UNIQUE_SESSION_ID;

  function FAL_ADV_CALC_STRUCT_TABLE(aSessionId in FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type)
    return TTARS_RUBRIC pipelined
  is
    cursor crMainSeqs
    is
      select   0 ARS_LEVEL
             , ARS.FAL_ADV_RATE_STRUCT_ID
             , ARS.FAL_ADV_STRUCT_CALC_ID
          from FAL_ADV_RATE_STRUCT ARS
         where ARS.ARS_VISIBLE_LEVEL = 1
           and ARS.FAL_ADV_STRUCT_CALC_ID in(select FAL_ADV_STRUCT_CALC_ID
                                               from FAL_ADV_CALC_OPTIONS
                                              where CAO_SESSION_ID = aSessionId)
           and ARS.FAL_ADV_RATE_STRUCT_ID not in(select distinct FAL_FAL_ADV_RATE_STRUCT_ID
                                                            from FAL_ADV_TOTAL_RATE)
      order by ARS.FAL_ADV_STRUCT_CALC_ID
             , ARS.ARS_SEQUENCE;

    cursor crNextSeqs(
      aFAL_ADV_STRUCT_CALC_ID in FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type
    , aFAL_ADV_RATE_STRUCT_ID in FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type
    )
    is
      select     level ARS_LEVEL
               , ARS.FAL_ADV_RATE_STRUCT_ID
            from FAL_ADV_TOTAL_RATE ATR
               , FAL_ADV_RATE_STRUCT ARS
           where ARS.ARS_VISIBLE_LEVEL = 1
             and ARS.FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID
             and ATR.FAL_FAL_ADV_RATE_STRUCT_ID(+) = ARS.FAL_ADV_RATE_STRUCT_ID
      connect by prior ATR.FAL_FAL_ADV_RATE_STRUCT_ID = ATR.FAL_ADV_RATE_STRUCT_ID
      start with ATR.FAL_ADV_RATE_STRUCT_ID = aFAL_ADV_RATE_STRUCT_ID
        order siblings by ARS.ARS_SEQUENCE;

    vRubric TARS_RUBRIC;
  begin
    vRubric.ARS_ORDER  := 0;

    for tplMainSeq in crMainSeqs loop
      vRubric.ARS_ORDER               := vRubric.ARS_ORDER + 1;
      vRubric.ARS_LEVEL               := tplMainSeq.ARS_LEVEL;
      vRubric.FAL_ADV_RATE_STRUCT_ID  := tplMainSeq.FAL_ADV_RATE_STRUCT_ID;
      vRubric.FAL_ADV_STRUCT_CALC_ID  := tplMainSeq.FAL_ADV_STRUCT_CALC_ID;
      pipe row(vRubric);

      for tplNextSeq in crNextSeqs(tplMainSeq.FAL_ADV_STRUCT_CALC_ID, tplMainSeq.FAL_ADV_RATE_STRUCT_ID) loop
        vRubric.ARS_ORDER               := vRubric.ARS_ORDER + 1;
        vRubric.ARS_LEVEL               := tplNextSeq.ARS_LEVEL;
        vRubric.FAL_ADV_RATE_STRUCT_ID  := tplNextSeq.FAL_ADV_RATE_STRUCT_ID;
        pipe row(vRubric);
      end loop;
    end loop;

    return;
  end FAL_ADV_CALC_STRUCT_TABLE;

  /**
   * procedure ADV_CALC_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de calculations avancées
   * @author JCH 31.01.2008
   */
  procedure ADV_CALC_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aSessionId  in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , aCalcGoodId in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type default null
  , aCptGoodId  in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type default null
  , aUserLanId  in     PCS.PC_LANG.LANID%type
  )
  is
  begin
    PCS.PC_I_LIB_SESSION.setLanId(aUserLanId);

    open aRefCursor for
      select   GOO.GOO_MAJOR_REFERENCE
             , GOO.GOO_SECONDARY_REFERENCE
             , CAO.DIC_FAB_CONDITION_ID
             , CAO.FAL_ADV_STRUCT_CALC_ID
             , CAO.CAO_CALCULATION_STRUCTURE
             , CAO.FAL_LOT_ID
             , LOT.LOT_REFCOMPL
             , VALS.*
             , RUBR.*
             , ARS.*
             , COM_FUNCTIONS.GetDescodeDescr('C_BASIS_RUBRIC', ARS.C_BASIS_RUBRIC, PCS.PC_I_LIB_SESSION.USER_LANG_ID) C_BASIS_RUBRIC_WORDING
             , COM_FUNCTIONS.GetDescodeDescr('C_RUBRIC_TYPE', ARS.C_RUBRIC_TYPE, PCS.PC_I_LIB_SESSION.USER_LANG_ID) C_RUBRIC_TYPE_WORDING
             , COM_FUNCTIONS.GetDescodeDescr('C_COST_ELEMENT_TYPE', ARS.C_COST_ELEMENT_TYPE, PCS.PC_I_LIB_SESSION.USER_LANG_ID) C_COST_ELEMENT_TYPE_WORDING
          from FAL_ADV_CALC_OPTIONS CAO
             , (select CAG.FAL_ADV_CALC_OPTIONS_ID
                     , CAG.GCO_GOOD_ID
                     , CAG.GCO_CPT_GOOD_ID
                     , nvl(CAG.GCO_CPT_GOOD_ID, CAG.GCO_GOOD_ID) GCO_DESCR_GOOD_ID
                     , CAV.CAV_RUBRIC_SEQ
                     , CAV.CAV_VALUE
                     , CAV.CAV_UNIT_PRICE
                     , CAV.CAV_STD_UNIT_PRICE
                  from FAL_ADV_CALC_GOOD CAG
                     , FAL_ADV_CALC_STRUCT_VAL CAV
                 where CAG.CAG_SESSION_ID = aSessionId
                   and CAV.CAV_SESSION_ID = aSessionId
                   and CAV.FAL_ADV_CALC_GOOD_ID = CAG.FAL_ADV_CALC_GOOD_ID
                   and (   aCalcGoodId is null
                        or (CAG.GCO_GOOD_ID = aCalcGoodId) )
                   and nvl(CAG.GCO_CPT_GOOD_ID, -1) = nvl(aCptGoodId, -1) ) VALS
             , FAL_ADV_RATE_STRUCT ARS
             , table(FAL_ADV_CALC_PRINT.FAL_ADV_CALC_STRUCT_TABLE(aSessionId) ) RUBR
             , GCO_GOOD GOO
             , FAL_LOT LOT
         where CAO.CAO_SESSION_ID = aSessionId
           and ARS.FAL_ADV_STRUCT_CALC_ID = CAO.FAL_ADV_STRUCT_CALC_ID
           and ARS.FAL_ADV_RATE_STRUCT_ID = RUBR.FAL_ADV_RATE_STRUCT_ID
           and VALS.CAV_RUBRIC_SEQ = ARS.ARS_SEQUENCE
           and VALS.FAL_ADV_CALC_OPTIONS_ID = CAO.FAL_ADV_CALC_OPTIONS_ID
           and GOO.GCO_GOOD_ID = VALS.GCO_DESCR_GOOD_ID
           and LOT.FAL_LOT_ID(+) = CAO.FAL_LOT_ID
      order by GOO.GOO_MAJOR_REFERENCE
             , CAO.FAL_ADV_CALC_OPTIONS_ID
             , VALS.GCO_GOOD_ID
             , RUBR.ARS_ORDER;
  end ADV_CALC_RPT_PK;

  /**
   * procedure ADV_CALC_OPTIONS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de calculations avancées
   * @author JCH 31.01.2008
   * @param
   */
  procedure ADV_CALC_OPTIONS_RPT_PK(
    aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aSessionId in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , aOptionsId in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type default null
  )
  is
  begin
    open aRefCursor for
      select   CAO.C_CALCULATION_KIND
             , CAO.CAO_VALUE_DATE
             , CAO.CAO_CALC_BY_CATEGORY
             , CAO.CAO_MAT_RATE
             , CAO.CAO_WORK_RATE
             , CAO.CAO_STD_QTY
             , CAO.CAO_STD_QTY_FOR_CPT
             , CAO.CAO_FREE_QTY
             , CAO.CAO_STD_AND_FREE_QTY
             , CAO.CAO_MANAGEMENT_MODE
             , CAO.CAO_PRCS
             , CAO.DIC_CALC_COSTPRICE_DESCR_ID
             , CAO.DIC_FIXED_COSTPRICE_DESCR_ID
             , CAO.CAO_PURCHASE_TARIFF
             , CAO.CAO_TAXES_DISCOUNTS
             , CAO.CAO_SUBC_TAXES_DISCOUNTS
             , CAO.CAO_STD_COMPARISON
             , CAO.CAO_DERIVED_LINK
             , CAO.CAO_REJECT
             , CAO.CAO_WASTE
             , CAO.DIC_PM_TYPE_RATE_ID
             , CAO.CAO_PPS_DIC_MAT
             , CAO.CAO_PPS_DIC_WORK
             , case
                 when min(CAO.FAL_ADV_STRUCT_CALC_ID) = max(CAO.FAL_ADV_STRUCT_CALC_ID) then max(CAO.FAL_ADV_STRUCT_CALC_ID)
                 else null
               end FAL_ADV_STRUCT_CALC_ID
             , case
                 when min(CAO.FAL_ADV_STRUCT_CALC_ID) = max(CAO.FAL_ADV_STRUCT_CALC_ID) then max(CAO.CAO_CALCULATION_STRUCTURE)
                 else null
               end CAO_CALCULATION_STRUCTURE
          from FAL_ADV_CALC_OPTIONS CAO
         where CAO.CAO_SESSION_ID = aSessionId
           and (   aOptionsId is null
                or (CAO.FAL_ADV_CALC_OPTIONS_ID = aOptionsId) )
      group by CAO.C_CALCULATION_KIND
             , CAO.CAO_VALUE_DATE
             , CAO.CAO_CALC_BY_CATEGORY
             , CAO.CAO_MAT_RATE
             , CAO.CAO_WORK_RATE
             , CAO.CAO_STD_QTY
             , CAO.CAO_STD_QTY_FOR_CPT
             , CAO.CAO_FREE_QTY
             , CAO.CAO_STD_AND_FREE_QTY
             , CAO.CAO_MANAGEMENT_MODE
             , CAO.CAO_PRCS
             , CAO.DIC_CALC_COSTPRICE_DESCR_ID
             , CAO.DIC_FIXED_COSTPRICE_DESCR_ID
             , CAO.CAO_PURCHASE_TARIFF
             , CAO.CAO_TAXES_DISCOUNTS
             , CAO.CAO_SUBC_TAXES_DISCOUNTS
             , CAO.CAO_STD_COMPARISON
             , CAO.CAO_DERIVED_LINK
             , CAO.CAO_REJECT
             , CAO.CAO_WASTE
             , CAO.DIC_PM_TYPE_RATE_ID
             , CAO.CAO_PPS_DIC_MAT
             , CAO.CAO_PPS_DIC_WORK;
  end ADV_CALC_OPTIONS_RPT_PK;

  /**
   * procedure ADV_CALC_CPTS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de calculations avancées
   * @author JCH 31.01.2008
   * @param
   */
  procedure ADV_CALC_CPTS_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aSessionId  in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , aOptionsId  in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , aCalcGoodId in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  , aCptGoodId  in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type default null
  )
  is
  begin
    open aRefCursor for
      select   GOO.*
             , CAG.*
             , GCO_LIB_FUNCTIONS.GetDescription2(GOO.GCO_GOOD_ID, PCS.PC_I_LIB_SESSION.GetUserLangId, 1, '05') DES_SHORT_DESCRIPTION
             , GCO_LIB_FUNCTIONS.GetDescription2(GOO.GCO_GOOD_ID, PCS.PC_I_LIB_SESSION.GetUserLangId, 2, '05') DES_LONG_DESCRIPTION
             , GCO_LIB_FUNCTIONS.GetDescription2(GOO.GCO_GOOD_ID, PCS.PC_I_LIB_SESSION.GetUserLangId, 3, '05') DES_FREE_DESCRIPTION
             , nvl(COM_DIC_FUNCTIONS.getDicoDescr(CAO.CAO_PPS_DIC_MAT, CAG.CAG_MAT_SECTION), CAG.CAG_MAT_SECTION) CAG_MAT_SECTION_WORDING
          from FAL_ADV_CALC_GOOD CAG
             , FAL_ADV_CALC_OPTIONS CAO
             , GCO_GOOD GOO
         where CAG.CAG_SESSION_ID = aSessionId
           and CAG.FAL_ADV_CALC_OPTIONS_ID = aOptionsId
           and CAG.GCO_GOOD_ID = aCalcGoodId
           and (   aCptGoodId is null
                or (CAG.GCO_CPT_GOOD_ID = aCptGoodId) )
           and CAO.FAL_ADV_CALC_OPTIONS_ID = CAG.FAL_ADV_CALC_OPTIONS_ID
           and GOO.GCO_GOOD_ID = CAG.GCO_CPT_GOOD_ID
      order by CAG.FAL_ADV_CALC_GOOD_ID;
  end ADV_CALC_CPTS_RPT_PK;

  /**
   * procedure ADV_CALC_CPTS_TASKS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de calculations avancées
   *   Retourne la liste des composants (et leurs détails) liés au produit
   *   calculé, ainsi que les opérations qui y sont liées (et leurs détails).
   */
  procedure ADV_CALC_CPTS_TASKS_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aSessionId  in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , aOptionsId  in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , aCalcGoodId in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  )
  is
  begin
    open aRefCursor for
      select   CAG.*
             , GOO.*
             , CAK.*
             , nvl(COM_DIC_FUNCTIONS.getDicoDescr(CAO.CAO_PPS_DIC_MAT, CAG.CAG_MAT_SECTION), CAG.CAG_MAT_SECTION) CAG_MAT_SECTION_WORDING
             , nvl(COM_DIC_FUNCTIONS.getDicoDescr(CAO.CAO_PPS_DIC_WORK, CAK.CAK_TIME_SECTION), CAK.CAK_TIME_SECTION) CAK_TIME_SECTION_WORDING
          from FAL_ADV_CALC_GOOD CAG
             , FAL_ADV_CALC_OPTIONS CAO
             , GCO_GOOD GOO
             , FAL_ADV_CALC_TASK CAK
         where CAG.CAG_SESSION_ID = aSessionId
           and CAG.FAL_ADV_CALC_OPTIONS_ID = aOptionsId
           and CAG.GCO_GOOD_ID = aCalcGoodId
           and CAO.FAL_ADV_CALC_OPTIONS_ID = CAG.FAL_ADV_CALC_OPTIONS_ID
           and GOO.GCO_GOOD_ID = CAG.GCO_CPT_GOOD_ID
           and CAK.CAK_SESSION_ID(+) = aSessionId
           and CAK.FAL_ADV_CALC_GOOD_ID(+) = CAG.FAL_ADV_CALC_GOOD_ID
      order by CAG.FAL_ADV_CALC_GOOD_ID
             , CAK.CAK_TASK_SEQ
             , CAK.FAL_ADV_CALC_TASK_ID;
  end ADV_CALC_CPTS_TASKS_RPT_PK;

  /**
   * procedure ADV_CALC_WORK_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de pré-calculation et post-calculation avancées
   * @author JCH 31.01.2008
   */
  procedure ADV_CALC_WORK_RPT_PK(
    aRefCursor   in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aSessionId   in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , aOptionsId   in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , aCalcGoodId  in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  , aCptGoodId   in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type default null
  , aBasisRubric in     FAL_ADV_CALC_WORK.C_BASIS_RUBRIC%type default cWorkBasisRubric
  )
  is
  begin
    open aRefCursor for
      select   CAW.CAW_DECOMPOSITION_LEVEL
             , CAW.C_DECOMPOSITION_TYPE
             , COM_FUNCTIONS.GetDescodeDescr('C_DECOMPOSITION_TYPE', CAW.C_DECOMPOSITION_TYPE, PCS.PC_I_LIB_SESSION.USER_LANG_ID) C_DECOMPOSITION_TYPE_WORDING
             , CAW.CAW_WORK_SECTION
             , nvl(case CAW.C_DECOMPOSITION_TYPE
                     when '01' then COM_DIC_FUNCTIONS.getDicoDescr(CAO.CAO_PPS_DIC_WORK, CAW.CAW_WORK_SECTION)
                     when '03' then case CAW.CAW_WORK_SECTION
                                     when 'ctFixed' then PCS.PC_FUNCTIONS.TranslateWord('Coûts fixes')
                                     when 'ctVariable' then PCS.PC_FUNCTIONS.TranslateWord('Coûts variables')
                                     else PCS.PC_FUNCTIONS.TranslateWord('Autres coûts')
                                   end
                     when '04' then COM_DIC_FUNCTIONS.getDicoDescr('DIC_FACT_RATE_DESCR', CAW.CAW_WORK_SECTION)
                     when '05' then COM_DIC_FUNCTIONS.getDicoDescr('DIC_FACT_RATE_FREE1', CAW.CAW_WORK_SECTION)
                     when '06' then COM_DIC_FUNCTIONS.getDicoDescr('DIC_FACT_RATE_FREE2', CAW.CAW_WORK_SECTION)
                     when '07' then COM_DIC_FUNCTIONS.getDicoDescr('DIC_FACT_RATE_FREE3', CAW.CAW_WORK_SECTION)
                     when '08' then COM_DIC_FUNCTIONS.getDicoDescr('DIC_FACT_RATE_FREE4', CAW.CAW_WORK_SECTION)
                     else CAW.CAW_WORK_SECTION
                   end
                 , CAW.CAW_WORK_SECTION
                  ) CAW_WORK_SECTION_WORDING
             , CAW.CAW_IS_RATE_DECOMP
             , CAW.CAW_WORK_RATE
             , CAW.CAW_WORK_TOTAL
             , CAW.CAW_WORK_AMOUNT
             , CAW.CAW_WORK_RATE_AMOUNT
             , CAW.FAL_ADV_CALC_GOOD_ID
          from FAL_ADV_CALC_WORK CAW
             , FAL_ADV_CALC_GOOD CAG
             , FAL_ADV_CALC_OPTIONS CAO
         where CAW.CAW_SESSION_ID = aSessionId
           and CAG.FAL_ADV_CALC_OPTIONS_ID = aOptionsId
           and CAG.GCO_GOOD_ID = aCalcGoodId
           and CAO.FAL_ADV_CALC_OPTIONS_ID = CAG.FAL_ADV_CALC_OPTIONS_ID
           and nvl(CAG.GCO_CPT_GOOD_ID, -1) = nvl(aCptGoodId, -1)
           and CAW.C_BASIS_RUBRIC = aBasisRubric
           and CAW.FAL_ADV_CALC_GOOD_ID = CAG.FAL_ADV_CALC_GOOD_ID
      order by CAW.FAL_ADV_CALC_WORK_ID;
  end ADV_CALC_WORK_RPT_PK;

  /**
   * procedure ADV_CALC_TASKS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de pré-calculation et post-calculation avancées
   * @author JCH 31.01.2008
   */
  procedure ADV_CALC_TASKS_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aSessionId  in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , aOptionsId  in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , aCalcGoodId in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  , aCptGoodId  in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type default null
  )
  is
  begin
    open aRefCursor for
      select   CAK.CAK_TASK_SEQ
             , CAK.CAK_TASK_REF
             , CAK.CAK_TASK_DESCR
             , CAK.CAK_WORK_TOTAL
             , CAK.CAK_TIME_SECTION
             , CAK.CAK_ADJUSTING_TIME
             , CAK.CAK_WORK_TIME
             , nvl(COM_DIC_FUNCTIONS.getDicoDescr(CAO.CAO_PPS_DIC_WORK, CAK.CAK_TIME_SECTION), CAK.CAK_TIME_SECTION) CAK_TIME_SECTION_WORDING
             , CAK.CAK_STD_ADJUSTING_TIME
             , CAK.CAK_STD_WORK_TIME
             , CAK.CAK_MACHINE_COST
             , CAK.CAK_HUMAN_COST
             , CAG.GCO_GOOD_ID
             , CAG.GCO_CPT_GOOD_ID
             , CAG.GOO_MAJOR_REFERENCE
             , CAG.GOO_SECONDARY_REFERENCE
          from FAL_ADV_CALC_TASK CAK
             , FAL_ADV_CALC_GOOD CAG
             , FAL_ADV_CALC_OPTIONS CAO
         where CAK.CAK_SESSION_ID = aSessionId
           and CAG.FAL_ADV_CALC_OPTIONS_ID = aOptionsId
           and (   aCalcGoodId is null
                or (CAG.GCO_GOOD_ID = aCalcGoodId) )
           and (   aCptGoodId is null
                or (CAG.GCO_CPT_GOOD_ID = aCptGoodId) )
           and CAO.FAL_ADV_CALC_OPTIONS_ID = CAG.FAL_ADV_CALC_OPTIONS_ID
           and CAK.FAL_ADV_CALC_GOOD_ID = CAG.FAL_ADV_CALC_GOOD_ID
      order by CAG.FAL_ADV_CALC_GOOD_ID
             , CAG.GOO_MAJOR_REFERENCE
             , CAK.CAK_TASK_SEQ;
  end ADV_CALC_TASKS_RPT_PK;

  /**
   * procedure ADV_CALC_SIMPLE_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports simples (décomposition par
   *   composant du premier niveau) de calculations avancées
   * @author JCH 31.01.2008
   */
  procedure ADV_CALC_SIMPLE_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aSessionId  in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , aCalcGoodId in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type default null
  , aUserLanId  in     PCS.PC_LANG.LANID%type
  )
  is
  begin
    PCS.PC_I_LIB_SESSION.setLanId(aUserLanId);

    open aRefCursor for
      select   GOO.GOO_MAJOR_REFERENCE
             , GOO.GOO_SECONDARY_REFERENCE
             , GOO_CPT.GOO_MAJOR_REFERENCE GOO_CPT_MAJOR_REFERENCE
             , GOO_CPT.GOO_SECONDARY_REFERENCE GOO_CPT_SECONDARY_REFERENCE
             , CAO.DIC_FAB_CONDITION_ID
             , CAO.FAL_ADV_STRUCT_CALC_ID
             , CAO.CAO_CALCULATION_STRUCTURE
             , CAO.FAL_LOT_ID
             , LOT.LOT_REFCOMPL
             , CAV.CAV_RUBRIC_SEQ
             , case
                 when RUBR_CAG.CAG_LEVEL = 0 then CAV.CAV_VALUE
                 else nvl(CAV.CAV_VALUE, 0) +
                      nvl( (select     sum(nvl(SUB_CAV.CAV_VALUE, 0) )
                                  from FAL_ADV_CALC_GOOD SUB_CAG
                                     , FAL_ADV_CALC_STRUCT_VAL SUB_CAV
                                 where SUB_CAG.CAG_SESSION_ID = aSessionId
                                   and SUB_CAV.CAV_SESSION_ID = aSessionId
                                   and SUB_CAV.FAL_ADV_CALC_GOOD_ID = SUB_CAG.FAL_ADV_CALC_GOOD_ID
                                   and SUB_CAV.CAV_RUBRIC_SEQ = RUBR_CAG.ARS_SEQUENCE
                            start with SUB_CAG.FAL_PARENT_ADV_CALC_GOOD_ID = RUBR_CAG.FAL_ADV_CALC_GOOD_ID
                                   and SUB_CAG.CAG_SESSION_ID = aSessionId
                                   and SUB_CAV.CAV_SESSION_ID = aSessionId
                                   and SUB_CAV.FAL_ADV_CALC_GOOD_ID = SUB_CAG.FAL_ADV_CALC_GOOD_ID
                                   and SUB_CAV.CAV_RUBRIC_SEQ = RUBR_CAG.ARS_SEQUENCE
                            connect by prior SUB_CAG.FAL_ADV_CALC_GOOD_ID = SUB_CAG.FAL_PARENT_ADV_CALC_GOOD_ID)
                        , 0
                         )
               end CAV_VALUE
             , CAV.CAV_UNIT_PRICE
             , CAV.CAV_STD_UNIT_PRICE
             , CAV.*
             , ARS.*
             , COM_FUNCTIONS.GetDescodeDescr('C_BASIS_RUBRIC', ARS.C_BASIS_RUBRIC, PCS.PC_I_LIB_SESSION.USER_LANG_ID) C_BASIS_RUBRIC_WORDING
             , COM_FUNCTIONS.GetDescodeDescr('C_RUBRIC_TYPE', ARS.C_RUBRIC_TYPE, PCS.PC_I_LIB_SESSION.USER_LANG_ID) C_RUBRIC_TYPE_WORDING
             , COM_FUNCTIONS.GetDescodeDescr('C_COST_ELEMENT_TYPE', ARS.C_COST_ELEMENT_TYPE, PCS.PC_I_LIB_SESSION.USER_LANG_ID) C_COST_ELEMENT_TYPE_WORDING
             , RUBR_CAG.*
             , (select count(FAL_ADV_CALC_TASK_ID)
                  from FAL_ADV_CALC_TASK CAK
                     , FAL_ADV_CALC_GOOD CAG
                 where CAK.CAK_SESSION_ID = aSessionId
                   and CAG.CAG_SESSION_ID = aSessionId
                   and CAK.FAL_ADV_CALC_GOOD_ID = CAG.FAL_ADV_CALC_GOOD_ID
                   and CAG.GCO_GOOD_ID = RUBR_CAG.GCO_GOOD_ID
                   and CAG.GCO_CPT_GOOD_ID = RUBR_CAG.GCO_GOOD_ID) TASK_COUNT
             , zvl(case
                     when RUBR_CAG.CAG_LEVEL = 0 then (select sum(SUB_CAW.CAW_WORK_AMOUNT)
                                                         from FAL_ADV_CALC_WORK SUB_CAW
                                                        where SUB_CAW.FAL_ADV_CALC_GOOD_ID = RUBR_CAG.FAL_ADV_CALC_GOOD_ID
                                                          and SUB_CAW.CAW_DECOMPOSITION_LEVEL = 0)
                     else nvl( (select sum(SUB_CAW.CAW_WORK_AMOUNT)
                                  from FAL_ADV_CALC_WORK SUB_CAW
                                 where SUB_CAW.FAL_ADV_CALC_GOOD_ID = RUBR_CAG.FAL_ADV_CALC_GOOD_ID
                                   and SUB_CAW.CAW_DECOMPOSITION_LEVEL = 0), 0) +
                          nvl( (select     sum(SUB_CAW.CAW_WORK_AMOUNT)
                                      from FAL_ADV_CALC_GOOD SUB_CAG
                                         , FAL_ADV_CALC_WORK SUB_CAW
                                     where SUB_CAW.CAW_SESSION_ID = aSessionId
                                       and SUB_CAG.CAG_SESSION_ID = aSessionId
                                       and SUB_CAW.FAL_ADV_CALC_GOOD_ID = SUB_CAG.FAL_ADV_CALC_GOOD_ID
                                       and SUB_CAW.CAW_DECOMPOSITION_LEVEL = 0
                                start with SUB_CAG.FAL_PARENT_ADV_CALC_GOOD_ID = RUBR_CAG.FAL_ADV_CALC_GOOD_ID
                                       and SUB_CAW.CAW_SESSION_ID = aSessionId
                                       and SUB_CAG.CAG_SESSION_ID = aSessionId
                                       and SUB_CAW.FAL_ADV_CALC_GOOD_ID = SUB_CAG.FAL_ADV_CALC_GOOD_ID
                                       and SUB_CAW.CAW_DECOMPOSITION_LEVEL = 0
                                connect by prior SUB_CAG.FAL_ADV_CALC_GOOD_ID = SUB_CAG.FAL_PARENT_ADV_CALC_GOOD_ID)
                            , 0
                             )
                   end
                 , null
                  ) CAW_WORK_AMOUNT
          from FAL_ADV_CALC_OPTIONS CAO
             , FAL_ADV_RATE_STRUCT ARS
             , (select   ARS.FAL_ADV_RATE_STRUCT_ID
                       , ARS.FAL_ADV_STRUCT_CALC_ID
                       , ARS.ARS_SEQUENCE
                       , CAG.FAL_ADV_CALC_OPTIONS_ID
                       , CAG.FAL_ADV_CALC_GOOD_ID
                       , CAG.GCO_GOOD_ID
                       , CAG.GCO_CPT_GOOD_ID
                       , nvl(CAG.GCO_CPT_GOOD_ID, CAG.GCO_GOOD_ID) GCO_DESCR_GOOD_ID
                       , CAG.CAG_LEVEL
                       , CAG.CAG_NOM_COEF
                       , CAG.CAG_QUANTITY
                       , case
                           when CAG.CAG_LEVEL = 0 then CAG.CAG_MAT_AMOUNT
                           else nvl(CAG.CAG_MAT_AMOUNT, 0) +
                                nvl( (select     sum(SUB_CAG.CAG_MAT_AMOUNT)
                                            from FAL_ADV_CALC_GOOD SUB_CAG
                                           where SUB_CAG.CAG_SESSION_ID = aSessionId
                                      start with SUB_CAG.FAL_PARENT_ADV_CALC_GOOD_ID = CAG.FAL_ADV_CALC_GOOD_ID
                                             and SUB_CAG.CAG_SESSION_ID = aSessionId
                                      connect by prior SUB_CAG.FAL_ADV_CALC_GOOD_ID = SUB_CAG.FAL_PARENT_ADV_CALC_GOOD_ID), 0)
                         end CAG_MAT_AMOUNT
--                        , CAG.CAG_TOTAL
--                        , CAG.CAG_MAT_TOTAL
--                        , CAG.CAG_MAT_SECTION
--                        . CAG.CAG_MAT_AMOUNT
--                        , CAG.CAG_MAT_RATE
--                        , CAG.CAG_MAT_RATE_AMOUNT
                from     FAL_ADV_RATE_STRUCT ARS
                       , FAL_ADV_CALC_GOOD CAG
                   where ARS.ARS_VISIBLE_LEVEL = 1
                     and ARS.FAL_ADV_STRUCT_CALC_ID in(select FAL_ADV_STRUCT_CALC_ID
                                                         from FAL_ADV_CALC_OPTIONS
                                                        where CAO_SESSION_ID = aSessionId)
                     and (   ARS.FAL_ADV_RATE_STRUCT_ID not in(select distinct FAL_FAL_ADV_RATE_STRUCT_ID
                                                                          from FAL_ADV_TOTAL_RATE)
                          or ARS.ARS_PRF_LEVEL = 1)
                     and CAG.CAG_SESSION_ID = aSessionId
                     and CAG.CAG_LEVEL < 2
                     and (   aCalcGoodId is null
                          or (CAG.GCO_GOOD_ID = aCalcGoodId) )
                order by ARS.FAL_ADV_STRUCT_CALC_ID
                       , ARS.ARS_SEQUENCE) RUBR_CAG
             , FAL_ADV_CALC_STRUCT_VAL CAV
             , GCO_GOOD GOO
             , GCO_GOOD GOO_CPT
             , FAL_LOT LOT
         where CAO.CAO_SESSION_ID = aSessionId
           and CAV.CAV_SESSION_ID(+) = aSessionId
           and ARS.FAL_ADV_STRUCT_CALC_ID = CAO.FAL_ADV_STRUCT_CALC_ID
           and ARS.FAL_ADV_RATE_STRUCT_ID = RUBR_CAG.FAL_ADV_RATE_STRUCT_ID
           and RUBR_CAG.FAL_ADV_CALC_OPTIONS_ID = CAO.FAL_ADV_CALC_OPTIONS_ID
           and RUBR_CAG.GCO_CPT_GOOD_ID is not null
           and GOO.GCO_GOOD_ID = RUBR_CAG.GCO_GOOD_ID
           and GOO_CPT.GCO_GOOD_ID = RUBR_CAG.GCO_DESCR_GOOD_ID
           and LOT.FAL_LOT_ID(+) = CAO.FAL_LOT_ID
           and CAV.FAL_ADV_CALC_GOOD_ID(+) = RUBR_CAG.FAL_ADV_CALC_GOOD_ID
           and CAV.CAV_RUBRIC_SEQ(+) = RUBR_CAG.ARS_SEQUENCE
      order by GOO.GOO_MAJOR_REFERENCE
             , CAO.FAL_ADV_CALC_OPTIONS_ID
             , ARS.ARS_SEQUENCE desc
             , RUBR_CAG.FAL_ADV_CALC_GOOD_ID
             , RUBR_CAG.GCO_GOOD_ID;
  end ADV_CALC_SIMPLE_RPT_PK;

  procedure PurgePrintTables
  is
  begin
    /* Attention !
     * Le cast permet de contourner un bug Oracle ? Si on ne le spécifie pas,
     * on obtient, certains jours, irrémédiablement l'erreur :
     * ORA-00600: internal error code, arguments: [kgmgchd1], [], [], [], [], [], [], []
     */
    delete from FAL_ADV_CALC_OPTIONS
          where CAO_SESSION_ID = cast(cSessionId as varchar2(30) )
             or COM_FUNCTIONS.Is_Session_Alive(nvl(CAO_SESSION_ID, cast(cSessionId as varchar2(30) ) ) ) = 0;

    delete from FAL_ADV_CALC_GOOD
          where CAG_SESSION_ID = cast(cSessionId as varchar2(30) )
             or COM_FUNCTIONS.Is_Session_Alive(nvl(CAG_SESSION_ID, cast(cSessionId as varchar2(30) ) ) ) = 0;

    delete from FAL_ADV_CALC_WORK
          where CAW_SESSION_ID = cast(cSessionId as varchar2(30) )
             or COM_FUNCTIONS.Is_Session_Alive(nvl(CAW_SESSION_ID, cast(cSessionId as varchar2(30) ) ) ) = 0;

    delete from FAL_ADV_CALC_TASK
          where CAK_SESSION_ID = cast(cSessionId as varchar2(30) )
             or COM_FUNCTIONS.Is_Session_Alive(nvl(CAK_SESSION_ID, cast(cSessionId as varchar2(30) ) ) ) = 0;

    delete from FAL_ADV_CALC_STRUCT_VAL
          where CAV_SESSION_ID = cast(cSessionId as varchar2(30) )
             or COM_FUNCTIONS.Is_Session_Alive(nvl(CAV_SESSION_ID, cast(cSessionId as varchar2(30) ) ) ) = 0;
  end PurgePrintTables;

  procedure InsertOptions(
    aAdvCalcOptionsId         out    FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , aCalculationKind          in     FAL_ADV_CALC_OPTIONS.C_CALCULATION_KIND%type
  , aDicFabConditionId        in     FAL_ADV_CALC_OPTIONS.DIC_FAB_CONDITION_ID%type
  , aValueDate                in     FAL_ADV_CALC_OPTIONS.CAO_VALUE_DATE%type
  , aLotId                    in     FAL_ADV_CALC_OPTIONS.FAL_LOT_ID%type
  , aAdvStructCalcId          in     FAL_ADV_CALC_OPTIONS.FAL_ADV_STRUCT_CALC_ID%type
  , aCalculationStructure     in     FAL_ADV_CALC_OPTIONS.CAO_CALCULATION_STRUCTURE%type
  , aCalcByCategory           in     FAL_ADV_CALC_OPTIONS.CAO_CALC_BY_CATEGORY%type
  , aMatRate                  in     FAL_ADV_CALC_OPTIONS.CAO_MAT_RATE%type
  , aWorkRate                 in     FAL_ADV_CALC_OPTIONS.CAO_WORK_RATE%type
  , aStdQty                   in     FAL_ADV_CALC_OPTIONS.CAO_STD_QTY%type
  , aStdQtyForCpt             in     FAL_ADV_CALC_OPTIONS.CAO_STD_QTY_FOR_CPT%type
  , aFreeQty                  in     FAL_ADV_CALC_OPTIONS.CAO_FREE_QTY%type
  , aStdAndFreeQty            in     FAL_ADV_CALC_OPTIONS.CAO_STD_AND_FREE_QTY%type
  , aManagementMode           in     FAL_ADV_CALC_OPTIONS.CAO_MANAGEMENT_MODE%type
  , aPrcs                     in     FAL_ADV_CALC_OPTIONS.CAO_PRCS%type
  , aDicCalcCostpriceDescrId  in     FAL_ADV_CALC_OPTIONS.DIC_CALC_COSTPRICE_DESCR_ID%type
  , aDicFixedCostpriceDescrId in     FAL_ADV_CALC_OPTIONS.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , aPurchaseTariff           in     FAL_ADV_CALC_OPTIONS.CAO_PURCHASE_TARIFF%type
  , aTaxesDiscounts           in     FAL_ADV_CALC_OPTIONS.CAO_TAXES_DISCOUNTS%type
  , aSubcTaxesDiscounts       in     FAL_ADV_CALC_OPTIONS.CAO_SUBC_TAXES_DISCOUNTS%type
  , aStdComparison            in     FAL_ADV_CALC_OPTIONS.CAO_STD_COMPARISON%type
  , aDerivedLink              in     FAL_ADV_CALC_OPTIONS.CAO_DERIVED_LINK%type
  , aReject                   in     FAL_ADV_CALC_OPTIONS.CAO_REJECT%type
  , aWaste                    in     FAL_ADV_CALC_OPTIONS.CAO_WASTE%type
  , aDicPmTypeRateId          in     FAL_ADV_CALC_OPTIONS.DIC_PM_TYPE_RATE_ID%type
  , aPpsDicMat                in     FAL_ADV_CALC_OPTIONS.CAO_PPS_DIC_MAT%type
  , aPpsDicWork               in     FAL_ADV_CALC_OPTIONS.CAO_PPS_DIC_WORK%type
  , aSSTACalcul               in     FAL_ADV_CALC_OPTIONS.CAO_SSTA_CALCUL%type
  , aKeepResult               in     integer
  )
  is
    vCalculationStructure FAL_ADV_CALC_OPTIONS.CAO_CALCULATION_STRUCTURE%type;
    vAdvStructCalcId      FAL_ADV_CALC_OPTIONS.FAL_ADV_STRUCT_CALC_ID%type;
  begin
    vAdvStructCalcId  := zvl(aAdvStructCalcId, null);

    -- Recherche de la référence de la structure de calcul si non renseignée
    if     aCalculationStructure is null
       and vAdvStructCalcId is not null then
      select ASC_REFERENCE
        into vCalculationStructure
        from FAL_ADV_STRUCT_CALC
       where FAL_ADV_STRUCT_CALC_ID = vAdvStructCalcId;
    else
      vCalculationStructure  := aCalculationStructure;
    end if;

    insert into FAL_ADV_CALC_OPTIONS
                (FAL_ADV_CALC_OPTIONS_ID
               , CAO_SESSION_ID
               , C_CALCULATION_KIND
               , DIC_FAB_CONDITION_ID
               , CAO_VALUE_DATE
               , FAL_LOT_ID
               , FAL_ADV_STRUCT_CALC_ID
               , CAO_CALCULATION_STRUCTURE
               , CAO_CALC_BY_CATEGORY
               , CAO_MAT_RATE
               , CAO_WORK_RATE
               , CAO_STD_QTY
               , CAO_STD_QTY_FOR_CPT
               , CAO_FREE_QTY
               , CAO_STD_AND_FREE_QTY
               , CAO_MANAGEMENT_MODE
               , CAO_PRCS
               , DIC_CALC_COSTPRICE_DESCR_ID
               , DIC_FIXED_COSTPRICE_DESCR_ID
               , CAO_PURCHASE_TARIFF
               , CAO_TAXES_DISCOUNTS
               , CAO_SUBC_TAXES_DISCOUNTS
               , CAO_STD_COMPARISON
               , CAO_DERIVED_LINK
               , CAO_REJECT
               , CAO_WASTE
               , DIC_PM_TYPE_RATE_ID
               , CAO_PPS_DIC_MAT
               , CAO_PPS_DIC_WORK
               , CAO_SSTA_CALCUL
                )
         values (init_temp_id_seq.nextval
               , case aKeepResult
                   when 0 then cSessionId
                   else null
                 end
               , aCalculationKind
               , aDicFabConditionId
               , aValueDate
               , aLotId
               , vAdvStructCalcId
               , vCalculationStructure
               , aCalcByCategory
               , aMatRate
               , aWorkRate
               , aStdQty
               , aStdQtyForCpt
               , aFreeQty
               , aStdAndFreeQty
               , aManagementMode
               , aPrcs
               , aDicCalcCostpriceDescrId
               , aDicFixedCostpriceDescrId
               , aPurchaseTariff
               , aTaxesDiscounts
               , aSubcTaxesDiscounts
               , aStdComparison
               , aDerivedLink
               , aReject
               , aWaste
               , aDicPmTypeRateId
               , aPpsDicMat
               , aPpsDicWork
               , aSSTACalcul
                )
      returning FAL_ADV_CALC_OPTIONS_ID
           into aAdvCalcOptionsId;
  end InsertOptions;

  procedure InsertProductComponent(
    aAdvCalcGoodId     out    FAL_ADV_CALC_GOOD.FAL_ADV_CALC_GOOD_ID%type
  , aAdvCalcOptionsId  in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , aCalculatedGoodId  in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  , aCptGoodId         in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type
  , aMajorRef          in     FAL_ADV_CALC_GOOD.GOO_MAJOR_REFERENCE%type default null
  , aSecondaryRef      in     FAL_ADV_CALC_GOOD.GOO_SECONDARY_REFERENCE%type default null
  , aNomenclatureLevel in     FAL_ADV_CALC_GOOD.CAG_LEVEL%type
  , aCoeffUtilisation  in     FAL_ADV_CALC_GOOD.CAG_NOM_COEF%type
  , aQuantity          in     FAL_ADV_CALC_GOOD.CAG_QUANTITY%type
  , aC_SUPPLY_MODE     in     varchar2 default null
  , aC_MANAGEMENT_MODE in     varchar2 default null
  , aINCREASE_COST     in     number default null
  , aPRECIOUS_MAT      in     number default null
  , aMP_INCREASE_COST  in     number default null
  , aREJECT_PERCENT    in     number default null
  , aREJECT_FIX_QTY    in     number default null
  , aREJECT_REF_QTY    in     number default null
  , aSCRAP_PERCENT     in     number default null
  , aSCRAP_FIX_QTY     in     number default null
  , aSCRAP_REF_QTY     in     number default null
  , aNOM_REF_QTY       in     integer default null
  , aSTANDARD_QTY      in     number default null
  , aPRICE             in     number default null
  , aC_KIND_COM        in     varchar2 default null
  , aSEQ               in     integer default null
  , aSTM_STOCK_ID      in     number default null
  , aSTM_LOCATION_ID   in     number default null
  , aKeepResult        in     integer
  )
  is
    vMajorRef            FAL_ADV_CALC_GOOD.GOO_MAJOR_REFERENCE%type;
    vSecondaryRef        FAL_ADV_CALC_GOOD.GOO_SECONDARY_REFERENCE%type;
    vParentAdvCalcGoodId FAL_ADV_CALC_GOOD.FAL_ADV_CALC_GOOD_ID%type;
    vParentLevel         FAL_ADV_CALC_GOOD.CAG_LEVEL%type;
  begin
    if aMajorRef is null then
      select GOO_MAJOR_REFERENCE
           , GOO_SECONDARY_REFERENCE
        into vMajorRef
           , vSecondaryRef
        from GCO_GOOD
       where GCO_GOOD_ID = nvl(aCptGoodId, aCalculatedGoodId);
    else
      vMajorRef      := aMajorRef;
      vSecondaryRef  := aSecondaryRef;
    end if;

    -- Recherhce du composant parent
    select max(FAL_ADV_CALC_GOOD_ID)
      into vParentAdvCalcGoodId
      from FAL_ADV_CALC_GOOD
     where CAG_SESSION_ID = cSessionId
       and CAG_LEVEL = aNomenclatureLevel - 1;

    insert into FAL_ADV_CALC_GOOD
                (FAL_ADV_CALC_GOOD_ID
               , FAL_PARENT_ADV_CALC_GOOD_ID
               , CAG_SESSION_ID
               , FAL_ADV_CALC_OPTIONS_ID
               , GCO_GOOD_ID
               , GCO_CPT_GOOD_ID
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , CAG_LEVEL
               , CAG_NOM_COEF
               , CAG_QUANTITY
               , C_SUPPLY_MODE
               , C_MANAGEMENT_MODE
               , CAG_INCREASE_COST
               , CAG_PRECIOUS_MAT
               , CAG_MP_INCREASE_COST
               , CAG_REJECT_PERCENT
               , CAG_REJECT_FIX_QTY
               , CAG_REJECT_REF_QTY
               , CAG_SCRAP_PERCENT
               , CAG_SCRAP_FIX_QTY
               , CAG_SCRAP_REF_QTY
               , CAG_NOM_REF_QTY
               , CAG_STANDARD_QTY
               , CAG_PRICE
               , C_KIND_COM
               , CAG_SEQ
               , STM_STOCK_ID
               , STM_LOCATION_ID
                )
         values (init_temp_id_seq.nextval
               , vParentAdvCalcGoodId
               , case aKeepResult
                   when 0 then cSessionId
                   else null
                 end
               , aAdvCalcOptionsId
               , aCalculatedGoodId
               , aCptGoodId
               , vMajorRef
               , vSecondaryRef
               , aNomenclatureLevel
               , aCoeffUtilisation
               , aQuantity
               , aC_SUPPLY_MODE
               , aC_MANAGEMENT_MODE
               , aINCREASE_COST
               , aPRECIOUS_MAT
               , aMP_INCREASE_COST
               , aREJECT_PERCENT
               , aREJECT_FIX_QTY
               , aREJECT_REF_QTY
               , aSCRAP_PERCENT
               , aSCRAP_FIX_QTY
               , aSCRAP_REF_QTY
               , aNOM_REF_QTY
               , aSTANDARD_QTY
               , aPRICE
               , aC_KIND_COM
               , aSEQ
               , aSTM_STOCK_ID
               , aSTM_LOCATION_ID
                )
      returning FAL_ADV_CALC_GOOD_ID
           into aAdvCalcGoodId;
  end InsertProductComponent;

  procedure UpdateProductComponent(
    aAdvCalcGoodId in FAL_ADV_CALC_GOOD.FAL_ADV_CALC_GOOD_ID%type
  , aTotal         in FAL_ADV_CALC_GOOD.CAG_TOTAL%type
  , aMatSection    in FAL_ADV_CALC_GOOD.CAG_MAT_SECTION%type
  , aMatTotal      in FAL_ADV_CALC_GOOD.CAG_MAT_TOTAL%type
  , aMatAmount     in FAL_ADV_CALC_GOOD.CAG_MAT_AMOUNT%type
  , aMatRate       in FAL_ADV_CALC_GOOD.CAG_MAT_RATE%type
  , aMatRateAmount in FAL_ADV_CALC_GOOD.CAG_MAT_RATE_AMOUNT%type
  )
  is
    vIsComponentRow integer;
  begin
    select case nvl(GCO_CPT_GOOD_ID, GCO_GOOD_ID)
             when GCO_GOOD_ID then 0
             else 1
           end
      into vIsComponentRow
      from FAL_ADV_CALC_GOOD
     where FAL_ADV_CALC_GOOD_ID = aAdvCalcGoodId;

    if vIsComponentRow = 1 then
      update FAL_ADV_CALC_GOOD
         set CAG_TOTAL = aTotal
           , CAG_MAT_SECTION = substr(aMatSection, 1, 10)
           , CAG_MAT_TOTAL = nvl(CAG_MAT_TOTAL, 0) + aMatTotal
           , CAG_MAT_AMOUNT = nvl(CAG_MAT_AMOUNT, 0) + aMatAmount
           , CAG_MAT_RATE = aMatRate
           , CAG_MAT_RATE_AMOUNT = nvl(CAG_MAT_RATE_AMOUNT, 0) + aMatRateAmount
       where FAL_ADV_CALC_GOOD_ID = aAdvCalcGoodId;
    else
      update FAL_ADV_CALC_GOOD
         set CAG_TOTAL = aTotal
           , CAG_MAT_TOTAL = nvl(CAG_MAT_TOTAL, 0) + aMatTotal
       where FAL_ADV_CALC_GOOD_ID = aAdvCalcGoodId;
    end if;
  end UpdateProductComponent;

  procedure InsertProductTask(
    aAdvCalcTaskId            out    FAL_ADV_CALC_TASK.FAL_ADV_CALC_TASK_ID%type
  , aAdvCalcGoodId            in     FAL_ADV_CALC_TASK.FAL_ADV_CALC_GOOD_ID%type
  , aScheduleStepId           in     FAL_ADV_CALC_TASK.FAL_SCHEDULE_STEP_ID%type
  , aFactoryFloorId           in     FAL_ADV_CALC_TASK.FAL_FACTORY_FLOOR_ID%type
  , aSupplierPartnerId        in     FAL_ADV_CALC_TASK.PAC_SUPPLIER_PARTNER_ID%type
  , aTaskSeq                  in     FAL_ADV_CALC_TASK.CAK_TASK_SEQ%type
  , aTaskRef                  in     FAL_ADV_CALC_TASK.CAK_TASK_REF%type
  , aTaskDescr                in     FAL_ADV_CALC_TASK.CAK_TASK_DESCR%type
  , aTimeSection              in     FAL_ADV_CALC_TASK.CAK_TIME_SECTION%type
  , aAjustingTime             in     FAL_ADV_CALC_TASK.CAK_ADJUSTING_TIME%type
  , aWorkTime                 in     FAL_ADV_CALC_TASK.CAK_WORK_TIME%type
  , aStdAjustingTime          in     FAL_ADV_CALC_TASK.CAK_STD_ADJUSTING_TIME%type default null
  , aStdWorkTime              in     FAL_ADV_CALC_TASK.CAK_STD_WORK_TIME%type default null
  , aMachineCost              in     FAL_ADV_CALC_TASK.CAK_MACHINE_COST%type
  , aHumanCost                in     FAL_ADV_CALC_TASK.CAK_HUMAN_COST%type
  , aFAL_FAL_FACTORY_FLOOR_ID in     FAL_ADV_CALC_TASK.FAL_FAL_FACTORY_FLOOR_ID%type default null
  , aGCO_GOOD_ID              in     FAL_ADV_CALC_TASK.GCO_GOOD_ID%type default null
  , aC_TASK_TYPE              in     FAL_ADV_CALC_TASK.C_TASK_TYPE%type default null
  , aC_TASK_IMPUTATION        in     FAL_ADV_CALC_TASK.C_TASK_IMPUTATION%type default null
  , aC_SCHEDULE_PLANNING      in     FAL_ADV_CALC_TASK.C_SCHEDULE_PLANNING%type default null
  , aCAK_AMOUNT               in     FAL_ADV_CALC_TASK.CAK_AMOUNT%type default null
  , aCAK_DIVISOR              in     FAL_ADV_CALC_TASK.CAK_DIVISOR%type default null
  , aCAK_MINUTE_RATE          in     FAL_ADV_CALC_TASK.CAK_MINUTE_RATE%type default null
  , aCAK_MACH_RATE            in     FAL_ADV_CALC_TASK.CAK_MACH_RATE%type default null
  , aCAK_MO_RATE              in     FAL_ADV_CALC_TASK.CAK_MO_RATE%type default null
  , aCAK_PERCENT_WORK_OPER    in     FAL_ADV_CALC_TASK.CAK_PERCENT_WORK_OPER%type default null
  , aCAK_NUM_WORK_OPERATOR    in     FAL_ADV_CALC_TASK.CAK_NUM_WORK_OPERATOR%type default null
  , aCAK_WORK_OPERATOR        in     FAL_ADV_CALC_TASK.CAK_WORK_OPERATOR%type default null
  , aCAK_WORK_FLOOR           in     FAL_ADV_CALC_TASK.CAK_WORK_FLOOR%type default null
  , aCAK_QTY_FIX_ADJUSTING    in     FAL_ADV_CALC_TASK.CAK_QTY_FIX_ADJUSTING%type default null
  , aCAK_NUM_ADJUST_OPERATOR  in     FAL_ADV_CALC_TASK.CAK_NUM_ADJUST_OPERATOR%type default null
  , aCAK_ADJUSTING_OPERATOR   in     FAL_ADV_CALC_TASK.CAK_ADJUSTING_OPERATOR%type default null
  , aCAK_ADJUSTING_FLOOR      in     FAL_ADV_CALC_TASK.CAK_ADJUSTING_FLOOR%type default null
  , aCAK_PERCENT_ADJUST_OPER  in     FAL_ADV_CALC_TASK.CAK_PERCENT_ADJUST_OPER%type default null
  , aCAK_QTY_REF_WORK         in     FAL_ADV_CALC_TASK.CAK_QTY_REF_WORK%type default null
  , aCAK_WORK_RATE            in     FAL_ADV_CALC_TASK.CAK_WORK_RATE%type default null
  , aCAK_ADJUSTING_RATE       in     FAL_ADV_CALC_TASK.CAK_ADJUSTING_RATE%type default null
  , aCAK_VALUE_DATE           in     FAL_ADV_CALC_TASK.CAK_VALUE_DATE%type default null
  , aFAL_TASK_ID              in     FAL_ADV_CALC_TASK.FAL_TASK_ID%type default null
  , aCAK_QTY_REF_AMOUNT       in     FAL_ADV_CALC_TASK.CAK_QTY_REF_AMOUNT%type default null
  , aCAK_SCHED_WORK_TIME      in     FAL_ADV_CALC_TASK.CAK_SCHED_WORK_TIME%type default null
  , aCAK_SCHED_ADJUSTING_TIME in     FAL_ADV_CALC_TASK.CAK_SCHED_ADJUSTING_TIME%type default null
  , aKeepResult               in     integer
  )
  is
    vFactoryFloorId FAL_ADV_CALC_TASK.FAL_FACTORY_FLOOR_ID%type;
    vTimeSection    FAL_ADV_CALC_TASK.CAK_TIME_SECTION%type;
    vTaskSeq        FAL_ADV_CALC_TASK.CAK_TASK_SEQ%type;
  begin
    if aScheduleStepId is null then
      vTaskSeq         := null;
      vFactoryFloorId  := null;

      select TAS_REF
        into vTimeSection
        from FAL_TASK
       where FAL_TASK_ID = aFactoryFloorId;
    else
      vTaskSeq         := aTaskSeq;
      vFactoryFloorId  := aFactoryFloorId;
      vTimeSection     := aTimeSection;
    end if;

    insert into FAL_ADV_CALC_TASK
                (FAL_ADV_CALC_TASK_ID
               , CAK_SESSION_ID
               , FAL_ADV_CALC_GOOD_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_FACTORY_FLOOR_ID
               , PAC_SUPPLIER_PARTNER_ID
               , CAK_TASK_SEQ
               , CAK_TASK_REF
               , CAK_TASK_DESCR
               , CAK_TIME_SECTION
               , CAK_ADJUSTING_TIME
               , CAK_WORK_TIME
               , CAK_STD_ADJUSTING_TIME
               , CAK_STD_WORK_TIME
               , CAK_MACHINE_COST
               , CAK_HUMAN_COST
               , FAL_FAL_FACTORY_FLOOR_ID
               , GCO_GOOD_ID
               , C_TASK_TYPE
               , C_TASK_IMPUTATION
               , C_SCHEDULE_PLANNING
               , CAK_AMOUNT
               , CAK_DIVISOR
               , CAK_MINUTE_RATE
               , CAK_MACH_RATE
               , CAK_MO_RATE
               , CAK_PERCENT_WORK_OPER
               , CAK_NUM_WORK_OPERATOR
               , CAK_WORK_OPERATOR
               , CAK_WORK_FLOOR
               , CAK_QTY_FIX_ADJUSTING
               , CAK_NUM_ADJUST_OPERATOR
               , CAK_ADJUSTING_OPERATOR
               , CAK_ADJUSTING_FLOOR
               , CAK_PERCENT_ADJUST_OPER
               , CAK_QTY_REF_WORK
               , CAK_WORK_RATE
               , CAK_ADJUSTING_RATE
               , CAK_VALUE_DATE
               , FAL_TASK_ID
               , CAK_QTY_REF_AMOUNT
               , CAK_SCHED_WORK_TIME
               , CAK_SCHED_ADJUSTING_TIME
                )
         values (init_temp_id_seq.nextval
               , case aKeepResult
                   when 0 then cSessionId
                   else null
                 end
               , aAdvCalcGoodId
               , aScheduleStepId
               , vFactoryFloorId
               , aSupplierPartnerId
               , vTaskSeq
               , aTaskRef
               , aTaskDescr
               , vTimeSection
               , aAjustingTime
               , aWorkTime
               , aStdAjustingTime
               , aStdWorkTime
               , aMachineCost
               , aHumanCost
               , aFAL_FAL_FACTORY_FLOOR_ID
               , aGCO_GOOD_ID
               , aC_TASK_TYPE
               , aC_TASK_IMPUTATION
               , aC_SCHEDULE_PLANNING
               , aCAK_AMOUNT
               , aCAK_DIVISOR
               , aCAK_MINUTE_RATE
               , aCAK_MACH_RATE
               , aCAK_MO_RATE
               , aCAK_PERCENT_WORK_OPER
               , aCAK_NUM_WORK_OPERATOR
               , aCAK_WORK_OPERATOR
               , aCAK_WORK_FLOOR
               , aCAK_QTY_FIX_ADJUSTING
               , aCAK_NUM_ADJUST_OPERATOR
               , aCAK_ADJUSTING_OPERATOR
               , aCAK_ADJUSTING_FLOOR
               , aCAK_PERCENT_ADJUST_OPER
               , aCAK_QTY_REF_WORK
               , aCAK_WORK_RATE
               , aCAK_ADJUSTING_RATE
               , aCAK_VALUE_DATE
               , aFAL_TASK_ID
               , aCAK_QTY_REF_AMOUNT
               , aCAK_SCHED_WORK_TIME
               , aCAK_SCHED_ADJUSTING_TIME
                )
      returning FAL_ADV_CALC_TASK_ID
           into aAdvCalcTaskId;
  end InsertProductTask;

  procedure InsertProductWork(
    aAdvCalcWorkId      out    FAL_ADV_CALC_WORK.FAL_ADV_CALC_WORK_ID%type
  , aAdvCalcGoodId      in     FAL_ADV_CALC_WORK.FAL_ADV_CALC_GOOD_ID%type
  , aBasisRubric        in     FAL_ADV_CALC_WORK.C_BASIS_RUBRIC%type
  , aDecompositionLevel in     FAL_ADV_CALC_WORK.CAW_DECOMPOSITION_LEVEL%type
  , aDecompositionType  in     FAL_ADV_CALC_WORK.C_DECOMPOSITION_TYPE%type
  , aTotal              in     FAL_ADV_CALC_WORK.CAW_WORK_TOTAL%type
  , aWorkSection        in     FAL_ADV_CALC_WORK.CAW_WORK_SECTION%type
  , aIsRateDecomp       in     FAL_ADV_CALC_WORK.CAW_IS_RATE_DECOMP%type default null
  , aWorkAmount         in     FAL_ADV_CALC_WORK.CAW_WORK_AMOUNT%type default null
  , aWorkRate           in     FAL_ADV_CALC_WORK.CAW_WORK_RATE%type default null
  , aWorkRateAmount     in     FAL_ADV_CALC_WORK.CAW_WORK_RATE_AMOUNT%type default null
  , aKeepResult         in     integer
  )
  is
  begin
    insert into FAL_ADV_CALC_WORK
                (FAL_ADV_CALC_WORK_ID
               , CAW_SESSION_ID
               , FAL_ADV_CALC_GOOD_ID
               , C_BASIS_RUBRIC
               , CAW_DECOMPOSITION_LEVEL
               , C_DECOMPOSITION_TYPE
               , CAW_WORK_TOTAL
               , CAW_WORK_SECTION
               , CAW_IS_RATE_DECOMP
               , CAW_WORK_AMOUNT
               , CAW_WORK_RATE
               , CAW_WORK_RATE_AMOUNT
                )
         values (init_temp_id_seq.nextval
               , case aKeepResult
                   when 0 then cSessionId
                   else null
                 end
               , aAdvCalcGoodId
               , aBasisRubric
               , aDecompositionLevel
               , aDecompositionType
               , aTotal
               , aWorkSection
               , aIsRateDecomp
               , aWorkAmount
               , aWorkRate
               , aWorkRateAmount
                )
      returning FAL_ADV_CALC_WORK_ID
           into aAdvCalcWorkId;
  end InsertProductWork;

  procedure InsertProductValue(
    aAdvCalcStrucValId out    FAL_ADV_CALC_STRUCT_VAL.FAL_ADV_CALC_STRUCT_VAL_ID%type
  , aAdvCalcGoodId     in     FAL_ADV_CALC_STRUCT_VAL.FAL_ADV_CALC_GOOD_ID%type
  , aAdvRateStructId   in     FAL_ADV_CALC_STRUCT_VAL.FAL_ADV_RATE_STRUCT_ID%type
  , aLevel             in     FAL_ADV_CALC_STRUCT_VAL.CAV_LEVEL%type
  , aRubricSeq         in     FAL_ADV_CALC_STRUCT_VAL.CAV_RUBRIC_SEQ%type
  , aValue             in     FAL_ADV_CALC_STRUCT_VAL.CAV_VALUE%type
  , aUnitPrice         in     FAL_ADV_CALC_STRUCT_VAL.CAV_UNIT_PRICE%type
  , aStdUnitPrice      in     FAL_ADV_CALC_STRUCT_VAL.CAV_STD_UNIT_PRICE%type
  , aCostElementType   in     FAL_ADV_CALC_STRUCT_VAL.C_COST_ELEMENT_TYPE%type default null
  , aKeepResult        in     integer
  )
  is
  begin
    insert into FAL_ADV_CALC_STRUCT_VAL
                (FAL_ADV_CALC_STRUCT_VAL_ID
               , CAV_SESSION_ID
               , FAL_ADV_CALC_GOOD_ID
               , FAL_ADV_RATE_STRUCT_ID
               , CAV_LEVEL
               , CAV_RUBRIC_SEQ
               , CAV_VALUE
               , CAV_UNIT_PRICE
               , CAV_STD_UNIT_PRICE
               , C_COST_ELEMENT_TYPE
                )
         values (init_temp_id_seq.nextval
               , case aKeepResult
                   when 0 then cSessionId
                   else null
                 end
               , aAdvCalcGoodId
               , aAdvRateStructId
               , aLevel
               , aRubricSeq
               , aValue
               , aUnitPrice
               , aStdUnitPrice
               , aCostElementType
                )
      returning FAL_ADV_CALC_STRUCT_VAL_ID
           into aAdvCalcStrucValId;
  end InsertProductValue;
end FAL_ADV_CALC_PRINT;
