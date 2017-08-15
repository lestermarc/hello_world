--------------------------------------------------------
--  DDL for Package Body GCO_PRODUCT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PRODUCT_FUNCTIONS" 
is
  /**
  * Description : Duplication des caractérisations d'un bien vers un autre
  */
  procedure DuplicateGoodCaracterization(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor Caract_Info(GoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   *
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = GoodID
      order by GCO_CHARACTERIZATION_ID;

    cursor CaractElement_Info(CaractID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    is
      select   *
          from GCO_CHARACTERISTIC_ELEMENT
         where GCO_CHARACTERIZATION_ID = CaractID
      order by GCO_CHARACTERISTIC_ELEMENT_ID;

    Tuple_Caract        Caract_Info%rowtype;
    Tuple_CaractElement CaractElement_Info%rowtype;
    NewCaract_ID        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    NewCaractElement_ID GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERISTIC_ELEMENT_ID%type;
  begin
    open Caract_Info(SourceGoodID);

    fetch Caract_Info
     into Tuple_Caract;

    -- Création des données de la table GCO_CHARACTERIZATION
    while Caract_Info%found loop
      -- ID de la nouvelle caractérisation
      select INIT_ID_SEQ.nextval
        into NewCaract_ID
        from dual;

      insert into GCO_CHARACTERIZATION
                  (GCO_CHARACTERIZATION_ID
                 , GCO_GOOD_ID
                 , C_CHRONOLOGY_TYPE
                 , C_CHARACT_TYPE
                 , C_UNIT_OF_TIME
                 , CHA_CHARACTERIZATION_DESIGN
                 , CHA_AUTOMATIC_INCREMENTATION
                 , CHA_INCREMENT_STE
                 , CHA_LAST_USED_INCREMENT
                 , CHA_LAPSING_DELAY
                 , CHA_MINIMUM_VALUE
                 , CHA_MAXIMUM_VALUE
                 , CHA_COMMENT
                 , CHA_STOCK_MANAGEMENT
                 , CHA_USE_DETAIL
                 , CHA_WITH_RETEST
                 , CHA_RETEST_DELAY
                 , CHA_RETEST_MARGIN
                 , CHA_QUALITY_STATUS_MGMT
                 , GCO_QUALITY_STAT_FLOW_ID
                 , GCO_QUALITY_STATUS_ID
                 , GCO_CHAR_AUTONUM_FUNC_ID
                 , CHA_PREFIXE
                 , CHA_SUFFIXE
                 , CHA_FREE_TEXT_1
                 , CHA_FREE_TEXT_2
                 , CHA_FREE_TEXT_3
                 , CHA_FREE_TEXT_4
                 , CHA_FREE_TEXT_5
                 , CHA_LAPSING_MARGE
                 , GCO_REFERENCE_TEMPLATE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewCaract_ID   -- GCO_CHARACTERIZATION_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , Tuple_Caract.C_CHRONOLOGY_TYPE
             , Tuple_Caract.C_CHARACT_TYPE
             , Tuple_Caract.C_UNIT_OF_TIME
             , Tuple_Caract.CHA_CHARACTERIZATION_DESIGN
             , Tuple_Caract.CHA_AUTOMATIC_INCREMENTATION
             , Tuple_Caract.CHA_INCREMENT_STE
             , Tuple_Caract.CHA_LAST_USED_INCREMENT
             , Tuple_Caract.CHA_LAPSING_DELAY
             , Tuple_Caract.CHA_MINIMUM_VALUE
             , Tuple_Caract.CHA_MAXIMUM_VALUE
             , Tuple_Caract.CHA_COMMENT
             , Tuple_Caract.CHA_STOCK_MANAGEMENT
             , Tuple_Caract.CHA_USE_DETAIL
             , Tuple_Caract.CHA_WITH_RETEST
             , Tuple_Caract.CHA_RETEST_DELAY
             , Tuple_Caract.CHA_RETEST_MARGIN
             , Tuple_Caract.CHA_QUALITY_STATUS_MGMT
             , Tuple_Caract.GCO_QUALITY_STAT_FLOW_ID
             , Tuple_Caract.GCO_QUALITY_STATUS_ID
             , Tuple_Caract.GCO_CHAR_AUTONUM_FUNC_ID
             , Tuple_Caract.CHA_PREFIXE
             , Tuple_Caract.CHA_SUFFIXE
             , Tuple_Caract.CHA_FREE_TEXT_1
             , Tuple_Caract.CHA_FREE_TEXT_2
             , Tuple_Caract.CHA_FREE_TEXT_3
             , Tuple_Caract.CHA_FREE_TEXT_4
             , Tuple_Caract.CHA_FREE_TEXT_5
             , Tuple_Caract.CHA_LAPSING_MARGE
             , Tuple_Caract.GCO_REFERENCE_TEMPLATE_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- Création des données de la table GCO_DESC_LANGUAGE pour la caractérisation
      insert into GCO_DESC_LANGUAGE
                  (GCO_DESC_LANGUAGE_ID
                 , GCO_CHARACTERIZATION_ID
                 , C_TYPE_DESC_LANG
                 , GCO_BASE_CHARACTERIZATION_ID
                 , PC_LANG_ID
                 , GCO_CHARACTERISTIC_ELEMENT_ID
                 , DLA_DESCRIPTION
                 , GCO_BASE_ELEMENT_CHARAC_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- GCO_DESC_LANGUAGE_ID
             , NewCaract_ID   -- GCO_CHARACTERIZATION_ID
             , C_TYPE_DESC_LANG
             , GCO_BASE_CHARACTERIZATION_ID
             , PC_LANG_ID
             , null   -- GCO_CHARACTERISTIC_ELEMENT_ID
             , DLA_DESCRIPTION
             , GCO_BASE_ELEMENT_CHARAC_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from GCO_DESC_LANGUAGE
         where GCO_CHARACTERIZATION_ID = Tuple_Caract.GCO_CHARACTERIZATION_ID;

      -- Créations des valeurs de caractérisation pour les caracts de type caractéristique
      if Tuple_Caract.C_CHARACT_TYPE = '2' then
        -- Création des valeurs de caractérisation pour la caractérisation courante
        open CaractElement_Info(Tuple_Caract.GCO_CHARACTERIZATION_ID);

        fetch CaractElement_Info
         into Tuple_CaractElement;

        while CaractElement_Info%found loop
          -- ID de la nouvelle valeur de caractérisation
          select INIT_ID_SEQ.nextval
            into NewCaractElement_ID
            from dual;

          insert into GCO_CHARACTERISTIC_ELEMENT
                      (GCO_CHARACTERISTIC_ELEMENT_ID
                     , GCO_CHARACTERIZATION_ID
                     , CHE_VALUE
                     , CHE_ALLOCATION
                     , CHE_EAN_CODE
                     , A_DATECRE
                     , A_IDCRE
                      )
            select NewCaractElement_ID   -- GCO_CHARACTERISTIC_ELEMENT_ID
                 , NewCaract_ID   -- GCO_CHARACTERIZATION_ID
                 , Tuple_CaractElement.CHE_VALUE
                 , Tuple_CaractElement.CHE_ALLOCATION
                 , null   -- CHE_EAN_CODE
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
              from dual;

          -- Création des données de la table GCO_DESC_LANGUAGE pour la valeur de caractérisation
          insert into GCO_DESC_LANGUAGE
                      (GCO_DESC_LANGUAGE_ID
                     , GCO_CHARACTERISTIC_ELEMENT_ID
                     , GCO_CHARACTERIZATION_ID
                     , C_TYPE_DESC_LANG
                     , GCO_BASE_CHARACTERIZATION_ID
                     , PC_LANG_ID
                     , DLA_DESCRIPTION
                     , GCO_BASE_ELEMENT_CHARAC_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
            select INIT_ID_SEQ.nextval   -- GCO_DESC_LANGUAGE_ID
                 , NewCaractElement_ID   -- GCO_CHARACTERISTIC_ELEMENT_ID
                 , null   -- GCO_CHARACTERIZATION_ID
                 , C_TYPE_DESC_LANG
                 , GCO_BASE_CHARACTERIZATION_ID
                 , PC_LANG_ID
                 , DLA_DESCRIPTION
                 , GCO_BASE_ELEMENT_CHARAC_ID
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
              from GCO_DESC_LANGUAGE
             where GCO_CHARACTERISTIC_ELEMENT_ID = Tuple_CaractElement.GCO_CHARACTERISTIC_ELEMENT_ID;

          -- Valeur de Caractérisation suivante
          fetch CaractElement_Info
           into Tuple_CaractElement;
        end loop;

        close CaractElement_Info;
      end if;

      -- Caractérisation suivante
      fetch Caract_Info
       into Tuple_Caract;
    end loop;

    close Caract_Info;
  end DuplicateGoodCaracterization;

  /**
  * Description : Duplication des tarifs d'un bien vers un autre
  */
  procedure DuplicateGoodTariff(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor TariffInfo(GoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select *
        from PTC_TARIFF
       where GCO_GOOD_ID = GoodID;

    Tuple_Tariff TariffInfo%rowtype;
    NewTariffID  PTC_TARIFF.PTC_TARIFF_ID%type;
  begin
    open TariffInfo(SourceGoodID);

    fetch TariffInfo
     into Tuple_Tariff;

    -- Création des données de la table PTC_TARIFF
    while TariffInfo%found loop
      -- ID de la nouveau tarif
      select INIT_ID_SEQ.nextval
        into NewTariffID
        from dual;

      insert into PTC_TARIFF
                  (PTC_TARIFF_ID
                 , GCO_GOOD_ID
                 , DIC_TARIFF_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , C_TARIFFICATION_MODE
                 , C_TARIFF_TYPE
                 , C_ROUND_TYPE
                 , PAC_THIRD_ID
                 , TRF_DESCR
                 , TRF_ROUND_AMOUNT
                 , TRF_UNIT
                 , TRF_SQL_CONDITIONAL
                 , TRF_STARTING_DATE
                 , TRF_ENDING_DATE
                 , PTC_FIXED_COSTPRICE_ID
                 , PTC_CALC_COSTPRICE_ID
                 , DIC_PUR_TARIFF_STRUCT_ID
                 , DIC_SALE_TARIFF_STRUCT_ID
                 , TRF_NET_TARIFF
                 , TRF_SPECIAL_TARIFF
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewTariffID   -- PTC_TARIFF_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , Tuple_Tariff.DIC_TARIFF_ID
             , Tuple_Tariff.ACS_FINANCIAL_CURRENCY_ID
             , Tuple_Tariff.C_TARIFFICATION_MODE
             , Tuple_Tariff.C_TARIFF_TYPE
             , Tuple_Tariff.C_ROUND_TYPE
             , Tuple_Tariff.PAC_THIRD_ID
             , Tuple_Tariff.TRF_DESCR
             , Tuple_Tariff.TRF_ROUND_AMOUNT
             , Tuple_Tariff.TRF_UNIT
             , Tuple_Tariff.TRF_SQL_CONDITIONAL
             , Tuple_Tariff.TRF_STARTING_DATE
             , Tuple_Tariff.TRF_ENDING_DATE
             , Tuple_Tariff.PTC_FIXED_COSTPRICE_ID
             , Tuple_Tariff.PTC_CALC_COSTPRICE_ID
             , Tuple_Tariff.DIC_PUR_TARIFF_STRUCT_ID
             , Tuple_Tariff.DIC_SALE_TARIFF_STRUCT_ID
             , Tuple_Tariff.TRF_NET_TARIFF
             , Tuple_Tariff.TRF_SPECIAL_TARIFF
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- Création des données de la table PTC_TARIFF_TABLE pour le tarif courant
      insert into PTC_TARIFF_TABLE
                  (PTC_TARIFF_TABLE_ID
                 , PTC_TARIFF_ID
                 , TTA_FROM_QUANTITY
                 , TTA_TO_QUANTITY
                 , TTA_PRICE
                 , TTA_FLAT_RATE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- PTC_TARIFF_TABLE_ID
             , NewTariffID   -- PTC_TARIFF_ID
             , TTA_FROM_QUANTITY
             , TTA_TO_QUANTITY
             , TTA_PRICE
             , TTA_FLAT_RATE   -- Tarif forfaitaire
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from PTC_TARIFF_TABLE
         where PTC_TARIFF_ID = Tuple_Tariff.PTC_TARIFF_ID;

      -- Tarif Suivant
      fetch TariffInfo
       into Tuple_Tariff;
    end loop;

    close TariffInfo;
  end DuplicateGoodTariff;

  /**
  * Description : Duplication des PRC d'un bien vers un autre
  */
  procedure DuplicateGoodPRC(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor PRC_Info(GoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select *
        from PTC_CALC_COSTPRICE
       where GCO_GOOD_ID = GoodID;

    Tuple_PRC PRC_Info%rowtype;
    NewPRC_ID PTC_CALC_COSTPRICE.PTC_CALC_COSTPRICE_ID%type;
  begin
    open PRC_Info(SourceGoodID);

    fetch PRC_Info
     into Tuple_PRC;

    -- Création des données de la table PTC_CALC_COSTPRICE
    while PRC_Info%found loop
      -- ID de la nouveau PRC
      select INIT_ID_SEQ.nextval
        into NewPRC_ID
        from dual;

      insert into PTC_CALC_COSTPRICE
                  (PTC_CALC_COSTPRICE_ID
                 , GCO_GOOD_ID
                 , DIC_CALC_COSTPRICE_DESCR_ID
                 , STM_STOCK_MOVEMENT_ID
                 , C_UPDATE_CYCLE
                 , C_COSTPRICE_STATUS
                 , PAC_THIRD_ID
                 , CPR_DESCR
                 , CPR_TEXT
                 , CPR_PRICE
                 , CCP_ADDED_QUANTITY
                 , CCP_ADDED_VALUE
                 , CCP_TOTAL_UPDATE
                 , CPR_DEFAULT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewPRC_ID   -- PTC_CALC_COSTPRICE_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , Tuple_PRC.DIC_CALC_COSTPRICE_DESCR_ID
             , Tuple_PRC.STM_STOCK_MOVEMENT_ID
             , Tuple_PRC.C_UPDATE_CYCLE
             , Tuple_PRC.C_COSTPRICE_STATUS
             , Tuple_PRC.PAC_THIRD_ID
             , Tuple_PRC.CPR_DESCR
             , Tuple_PRC.CPR_TEXT
             , 0   -- CPR_PRICE
             , 0   -- CCP_ADDED_QUANTITY
             , 0   -- CCP_ADDED_VALUE
             , Tuple_PRC.CCP_TOTAL_UPDATE
             , Tuple_PRC.CPR_DEFAULT
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- Création des données de la table PTC_PRC_S_STOCK_MVT pour le PRC courant
      insert into PTC_PRC_S_STOCK_MVT
                  (PTC_CALC_COSTPRICE_ID
                 , STM_MOVEMENT_KIND_ID
                  )
        select NewPRC_ID   -- PTC_CALC_COSTPRICE_ID
             , STM_MOVEMENT_KIND_ID
          from PTC_PRC_S_STOCK_MVT
         where PTC_CALC_COSTPRICE_ID = Tuple_PRC.PTC_CALC_COSTPRICE_ID;

      -- PRC Suivant
      fetch PRC_Info
       into Tuple_PRC;
    end loop;

    close PRC_Info;
  end DuplicateGoodPRC;

  /**
  * Description : Duplication des PRF d'un bien vers un autre
  */
  procedure DuplicateGoodPRF(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into PTC_FIXED_COSTPRICE
                (PTC_FIXED_COSTPRICE_ID
               , GCO_GOOD_ID
               , C_COSTPRICE_STATUS
               , PAC_THIRD_ID
               , CPR_DESCR
               , CPR_TEXT
               , CPR_PRICE
               , CPR_DEFAULT
               , FCP_START_DATE
               , FCP_END_DATE
               , DIC_FIXED_COSTPRICE_DESCR_ID
               , FCP_OPTIONS
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- PTC_FIXED_COSTPRICE_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , C_COSTPRICE_STATUS
           , PAC_THIRD_ID
           , CPR_DESCR
           , CPR_TEXT
           , CPR_PRICE
           , CPR_DEFAULT
           , FCP_START_DATE
           , FCP_END_DATE
           , DIC_FIXED_COSTPRICE_DESCR_ID
           , FCP_OPTIONS
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from PTC_FIXED_COSTPRICE
       where GCO_GOOD_ID = SourceGoodID
         and PTC_RECALC_JOB_ID is null;
  end DuplicateGoodPRF;

  /**
  * Description : Duplication des données complémentaires des attributs d'un bien vers un autre
  */
  procedure DuplicateGoodAttr(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_GOOD_ATTRIBUTE
                (GCO_GOOD_ID
               , GAT_INTEGER_01
               , GAT_INTEGER_02
               , GAT_INTEGER_03
               , GAT_INTEGER_04
               , GAT_INTEGER_05
               , GAT_INTEGER_06
               , GAT_INTEGER_07
               , GAT_INTEGER_08
               , GAT_INTEGER_09
               , GAT_INTEGER_10
               , GAT_INTEGER_11
               , GAT_INTEGER_12
               , GAT_INTEGER_13
               , GAT_INTEGER_14
               , GAT_INTEGER_15
               , GAT_INTEGER_16
               , GAT_INTEGER_17
               , GAT_INTEGER_18
               , GAT_INTEGER_19
               , GAT_INTEGER_20
               , GAT_INTEGER_21
               , GAT_INTEGER_22
               , GAT_INTEGER_23
               , GAT_INTEGER_24
               , GAT_INTEGER_25
               , GAT_INTEGER_26
               , GAT_INTEGER_27
               , GAT_INTEGER_28
               , GAT_INTEGER_29
               , GAT_INTEGER_30
               , GAT_FLOAT_01
               , GAT_FLOAT_02
               , GAT_FLOAT_03
               , GAT_FLOAT_04
               , GAT_FLOAT_05
               , GAT_FLOAT_06
               , GAT_FLOAT_07
               , GAT_FLOAT_08
               , GAT_FLOAT_09
               , GAT_FLOAT_10
               , GAT_FLOAT_11
               , GAT_FLOAT_12
               , GAT_FLOAT_13
               , GAT_FLOAT_14
               , GAT_FLOAT_15
               , GAT_FLOAT_16
               , GAT_FLOAT_17
               , GAT_FLOAT_18
               , GAT_FLOAT_19
               , GAT_FLOAT_20
               , GAT_FLOAT_21
               , GAT_FLOAT_22
               , GAT_FLOAT_23
               , GAT_FLOAT_24
               , GAT_FLOAT_25
               , GAT_FLOAT_26
               , GAT_FLOAT_27
               , GAT_FLOAT_28
               , GAT_FLOAT_29
               , GAT_FLOAT_30
               , GAT_BOOLEAN_01
               , GAT_BOOLEAN_02
               , GAT_BOOLEAN_03
               , GAT_BOOLEAN_04
               , GAT_BOOLEAN_05
               , GAT_BOOLEAN_06
               , GAT_BOOLEAN_07
               , GAT_BOOLEAN_08
               , GAT_BOOLEAN_09
               , GAT_BOOLEAN_10
               , GAT_BOOLEAN_11
               , GAT_BOOLEAN_12
               , GAT_BOOLEAN_13
               , GAT_BOOLEAN_14
               , GAT_BOOLEAN_15
               , GAT_BOOLEAN_16
               , GAT_BOOLEAN_17
               , GAT_BOOLEAN_18
               , GAT_BOOLEAN_19
               , GAT_BOOLEAN_20
               , GAT_BOOLEAN_21
               , GAT_BOOLEAN_22
               , GAT_BOOLEAN_23
               , GAT_BOOLEAN_24
               , GAT_BOOLEAN_25
               , GAT_BOOLEAN_26
               , GAT_BOOLEAN_27
               , GAT_BOOLEAN_28
               , GAT_BOOLEAN_29
               , GAT_BOOLEAN_30
               , GAT_CHAR_01
               , GAT_CHAR_02
               , GAT_CHAR_03
               , GAT_CHAR_04
               , GAT_CHAR_05
               , GAT_CHAR_06
               , GAT_CHAR_07
               , GAT_CHAR_08
               , GAT_CHAR_09
               , GAT_CHAR_10
               , GAT_CHAR_11
               , GAT_CHAR_12
               , GAT_CHAR_13
               , GAT_CHAR_14
               , GAT_CHAR_15
               , GAT_CHAR_16
               , GAT_CHAR_17
               , GAT_CHAR_18
               , GAT_CHAR_19
               , GAT_CHAR_20
               , GAT_CHAR_21
               , GAT_CHAR_22
               , GAT_CHAR_23
               , GAT_CHAR_24
               , GAT_CHAR_25
               , GAT_CHAR_26
               , GAT_CHAR_27
               , GAT_CHAR_28
               , GAT_CHAR_29
               , GAT_CHAR_30
               , GAT_MEMO_01
               , GAT_MEMO_02
               , GAT_MEMO_03
               , GAT_MEMO_04
               , GAT_MEMO_05
               , GAT_MEMO_06
               , GAT_MEMO_07
               , GAT_MEMO_08
               , GAT_MEMO_09
               , GAT_MEMO_10
               , GAT_MEMO_11
               , GAT_MEMO_12
               , GAT_MEMO_13
               , GAT_MEMO_14
               , GAT_MEMO_15
               , GAT_MEMO_16
               , GAT_MEMO_17
               , GAT_MEMO_18
               , GAT_MEMO_19
               , GAT_MEMO_20
               , GAT_MEMO_21
               , GAT_MEMO_22
               , GAT_MEMO_23
               , GAT_MEMO_24
               , GAT_MEMO_25
               , GAT_MEMO_26
               , GAT_MEMO_27
               , GAT_MEMO_28
               , GAT_MEMO_29
               , GAT_MEMO_30
               , GAT_DATE_01
               , GAT_DATE_02
               , GAT_DATE_03
               , GAT_DATE_04
               , GAT_DATE_05
               , GAT_DATE_06
               , GAT_DATE_07
               , GAT_DATE_08
               , GAT_DATE_09
               , GAT_DATE_10
               , GAT_DATE_11
               , GAT_DATE_12
               , GAT_DATE_13
               , GAT_DATE_14
               , GAT_DATE_15
               , GAT_DATE_16
               , GAT_DATE_17
               , GAT_DATE_18
               , GAT_DATE_19
               , GAT_DATE_20
               , GAT_DATE_21
               , GAT_DATE_22
               , GAT_DATE_23
               , GAT_DATE_24
               , GAT_DATE_25
               , GAT_DATE_26
               , GAT_DATE_27
               , GAT_DATE_28
               , GAT_DATE_29
               , GAT_DATE_30
               , GAT_DESCODES_01
               , GAT_DESCODES_02
               , GAT_DESCODES_03
               , GAT_DESCODES_04
               , GAT_DESCODES_05
               , GAT_DESCODES_06
               , GAT_DESCODES_07
               , GAT_DESCODES_08
               , GAT_DESCODES_09
               , GAT_DESCODES_10
               , GAT_DESCODES_11
               , GAT_DESCODES_12
               , GAT_DESCODES_13
               , GAT_DESCODES_14
               , GAT_DESCODES_15
               , GAT_DESCODES_16
               , GAT_DESCODES_17
               , GAT_DESCODES_18
               , GAT_DESCODES_19
               , GAT_DESCODES_20
               , GAT_DESCODES_21
               , GAT_DESCODES_22
               , GAT_DESCODES_23
               , GAT_DESCODES_24
               , GAT_DESCODES_25
               , GAT_DESCODES_26
               , GAT_DESCODES_27
               , GAT_DESCODES_28
               , GAT_DESCODES_29
               , GAT_DESCODES_30
               , DIC_GCO_ATTRIBUTE_FREE_01_ID
               , DIC_GCO_ATTRIBUTE_FREE_02_ID
               , DIC_GCO_ATTRIBUTE_FREE_03_ID
               , DIC_GCO_ATTRIBUTE_FREE_04_ID
               , DIC_GCO_ATTRIBUTE_FREE_05_ID
               , DIC_GCO_ATTRIBUTE_FREE_06_ID
               , DIC_GCO_ATTRIBUTE_FREE_07_ID
               , DIC_GCO_ATTRIBUTE_FREE_08_ID
               , DIC_GCO_ATTRIBUTE_FREE_09_ID
               , DIC_GCO_ATTRIBUTE_FREE_10_ID
               , DIC_GCO_ATTRIBUTE_FREE_11_ID
               , DIC_GCO_ATTRIBUTE_FREE_12_ID
               , DIC_GCO_ATTRIBUTE_FREE_13_ID
               , DIC_GCO_ATTRIBUTE_FREE_14_ID
               , DIC_GCO_ATTRIBUTE_FREE_15_ID
               , DIC_GCO_ATTRIBUTE_FREE_16_ID
               , DIC_GCO_ATTRIBUTE_FREE_17_ID
               , DIC_GCO_ATTRIBUTE_FREE_18_ID
               , DIC_GCO_ATTRIBUTE_FREE_19_ID
               , DIC_GCO_ATTRIBUTE_FREE_20_ID
               , DIC_GCO_ATTRIBUTE_FREE_21_ID
               , DIC_GCO_ATTRIBUTE_FREE_22_ID
               , DIC_GCO_ATTRIBUTE_FREE_23_ID
               , DIC_GCO_ATTRIBUTE_FREE_24_ID
               , DIC_GCO_ATTRIBUTE_FREE_25_ID
               , DIC_GCO_ATTRIBUTE_FREE_26_ID
               , DIC_GCO_ATTRIBUTE_FREE_27_ID
               , DIC_GCO_ATTRIBUTE_FREE_28_ID
               , DIC_GCO_ATTRIBUTE_FREE_29_ID
               , DIC_GCO_ATTRIBUTE_FREE_30_ID
               , DIC_GCO_ATTRIBUTE_FREE_31_ID
               , DIC_GCO_ATTRIBUTE_FREE_32_ID
               , DIC_GCO_ATTRIBUTE_FREE_33_ID
               , DIC_GCO_ATTRIBUTE_FREE_34_ID
               , DIC_GCO_ATTRIBUTE_FREE_35_ID
               , DIC_GCO_ATTRIBUTE_FREE_36_ID
               , DIC_GCO_ATTRIBUTE_FREE_37_ID
               , DIC_GCO_ATTRIBUTE_FREE_38_ID
               , DIC_GCO_ATTRIBUTE_FREE_39_ID
               , DIC_GCO_ATTRIBUTE_FREE_40_ID
               , DIC_GCO_ATTRIBUTE_FREE_41_ID
               , DIC_GCO_ATTRIBUTE_FREE_42_ID
               , DIC_GCO_ATTRIBUTE_FREE_43_ID
               , DIC_GCO_ATTRIBUTE_FREE_44_ID
               , DIC_GCO_ATTRIBUTE_FREE_45_ID
               , DIC_GCO_ATTRIBUTE_FREE_46_ID
               , DIC_GCO_ATTRIBUTE_FREE_47_ID
               , DIC_GCO_ATTRIBUTE_FREE_48_ID
               , DIC_GCO_ATTRIBUTE_FREE_49_ID
               , DIC_GCO_ATTRIBUTE_FREE_50_ID
               , DIC_GCO_ATTRIBUTE_FREE_51_ID
               , DIC_GCO_ATTRIBUTE_FREE_52_ID
               , DIC_GCO_ATTRIBUTE_FREE_53_ID
               , DIC_GCO_ATTRIBUTE_FREE_54_ID
               , DIC_GCO_ATTRIBUTE_FREE_55_ID
               , DIC_GCO_ATTRIBUTE_FREE_56_ID
               , DIC_GCO_ATTRIBUTE_FREE_57_ID
               , DIC_GCO_ATTRIBUTE_FREE_58_ID
               , DIC_GCO_ATTRIBUTE_FREE_59_ID
               , DIC_GCO_ATTRIBUTE_FREE_60_ID
               , A_DATECRE
               , A_IDCRE
                )
      select
--       INIT_ID_SEQ.NEXTVAL,     -- PTC_FIXED_COSTPRICE_ID
             TargetGoodID
           , GAT_INTEGER_01
           , GAT_INTEGER_02
           , GAT_INTEGER_03
           , GAT_INTEGER_04
           , GAT_INTEGER_05
           , GAT_INTEGER_06
           , GAT_INTEGER_07
           , GAT_INTEGER_08
           , GAT_INTEGER_09
           , GAT_INTEGER_10
           , GAT_INTEGER_11
           , GAT_INTEGER_12
           , GAT_INTEGER_13
           , GAT_INTEGER_14
           , GAT_INTEGER_15
           , GAT_INTEGER_16
           , GAT_INTEGER_17
           , GAT_INTEGER_18
           , GAT_INTEGER_19
           , GAT_INTEGER_20
           , GAT_INTEGER_21
           , GAT_INTEGER_22
           , GAT_INTEGER_23
           , GAT_INTEGER_24
           , GAT_INTEGER_25
           , GAT_INTEGER_26
           , GAT_INTEGER_27
           , GAT_INTEGER_28
           , GAT_INTEGER_29
           , GAT_INTEGER_30
           , GAT_FLOAT_01
           , GAT_FLOAT_02
           , GAT_FLOAT_03
           , GAT_FLOAT_04
           , GAT_FLOAT_05
           , GAT_FLOAT_06
           , GAT_FLOAT_07
           , GAT_FLOAT_08
           , GAT_FLOAT_09
           , GAT_FLOAT_10
           , GAT_FLOAT_11
           , GAT_FLOAT_12
           , GAT_FLOAT_13
           , GAT_FLOAT_14
           , GAT_FLOAT_15
           , GAT_FLOAT_16
           , GAT_FLOAT_17
           , GAT_FLOAT_18
           , GAT_FLOAT_19
           , GAT_FLOAT_20
           , GAT_FLOAT_21
           , GAT_FLOAT_22
           , GAT_FLOAT_23
           , GAT_FLOAT_24
           , GAT_FLOAT_25
           , GAT_FLOAT_26
           , GAT_FLOAT_27
           , GAT_FLOAT_28
           , GAT_FLOAT_29
           , GAT_FLOAT_30
           , GAT_BOOLEAN_01
           , GAT_BOOLEAN_02
           , GAT_BOOLEAN_03
           , GAT_BOOLEAN_04
           , GAT_BOOLEAN_05
           , GAT_BOOLEAN_06
           , GAT_BOOLEAN_07
           , GAT_BOOLEAN_08
           , GAT_BOOLEAN_09
           , GAT_BOOLEAN_10
           , GAT_BOOLEAN_11
           , GAT_BOOLEAN_12
           , GAT_BOOLEAN_13
           , GAT_BOOLEAN_14
           , GAT_BOOLEAN_15
           , GAT_BOOLEAN_16
           , GAT_BOOLEAN_17
           , GAT_BOOLEAN_18
           , GAT_BOOLEAN_19
           , GAT_BOOLEAN_20
           , GAT_BOOLEAN_21
           , GAT_BOOLEAN_22
           , GAT_BOOLEAN_23
           , GAT_BOOLEAN_24
           , GAT_BOOLEAN_25
           , GAT_BOOLEAN_26
           , GAT_BOOLEAN_27
           , GAT_BOOLEAN_28
           , GAT_BOOLEAN_29
           , GAT_BOOLEAN_30
           , GAT_CHAR_01
           , GAT_CHAR_02
           , GAT_CHAR_03
           , GAT_CHAR_04
           , GAT_CHAR_05
           , GAT_CHAR_06
           , GAT_CHAR_07
           , GAT_CHAR_08
           , GAT_CHAR_09
           , GAT_CHAR_10
           , GAT_CHAR_11
           , GAT_CHAR_12
           , GAT_CHAR_13
           , GAT_CHAR_14
           , GAT_CHAR_15
           , GAT_CHAR_16
           , GAT_CHAR_17
           , GAT_CHAR_18
           , GAT_CHAR_19
           , GAT_CHAR_20
           , GAT_CHAR_21
           , GAT_CHAR_22
           , GAT_CHAR_23
           , GAT_CHAR_24
           , GAT_CHAR_25
           , GAT_CHAR_26
           , GAT_CHAR_27
           , GAT_CHAR_28
           , GAT_CHAR_29
           , GAT_CHAR_30
           , GAT_MEMO_01
           , GAT_MEMO_02
           , GAT_MEMO_03
           , GAT_MEMO_04
           , GAT_MEMO_05
           , GAT_MEMO_06
           , GAT_MEMO_07
           , GAT_MEMO_08
           , GAT_MEMO_09
           , GAT_MEMO_10
           , GAT_MEMO_11
           , GAT_MEMO_12
           , GAT_MEMO_13
           , GAT_MEMO_14
           , GAT_MEMO_15
           , GAT_MEMO_16
           , GAT_MEMO_17
           , GAT_MEMO_18
           , GAT_MEMO_19
           , GAT_MEMO_20
           , GAT_MEMO_21
           , GAT_MEMO_22
           , GAT_MEMO_23
           , GAT_MEMO_24
           , GAT_MEMO_25
           , GAT_MEMO_26
           , GAT_MEMO_27
           , GAT_MEMO_28
           , GAT_MEMO_29
           , GAT_MEMO_30
           , GAT_DATE_01
           , GAT_DATE_02
           , GAT_DATE_03
           , GAT_DATE_04
           , GAT_DATE_05
           , GAT_DATE_06
           , GAT_DATE_07
           , GAT_DATE_08
           , GAT_DATE_09
           , GAT_DATE_10
           , GAT_DATE_11
           , GAT_DATE_12
           , GAT_DATE_13
           , GAT_DATE_14
           , GAT_DATE_15
           , GAT_DATE_16
           , GAT_DATE_17
           , GAT_DATE_18
           , GAT_DATE_19
           , GAT_DATE_20
           , GAT_DATE_21
           , GAT_DATE_22
           , GAT_DATE_23
           , GAT_DATE_24
           , GAT_DATE_25
           , GAT_DATE_26
           , GAT_DATE_27
           , GAT_DATE_28
           , GAT_DATE_29
           , GAT_DATE_30
           , GAT_DESCODES_01
           , GAT_DESCODES_02
           , GAT_DESCODES_03
           , GAT_DESCODES_04
           , GAT_DESCODES_05
           , GAT_DESCODES_06
           , GAT_DESCODES_07
           , GAT_DESCODES_08
           , GAT_DESCODES_09
           , GAT_DESCODES_10
           , GAT_DESCODES_11
           , GAT_DESCODES_12
           , GAT_DESCODES_13
           , GAT_DESCODES_14
           , GAT_DESCODES_15
           , GAT_DESCODES_16
           , GAT_DESCODES_17
           , GAT_DESCODES_18
           , GAT_DESCODES_19
           , GAT_DESCODES_20
           , GAT_DESCODES_21
           , GAT_DESCODES_22
           , GAT_DESCODES_23
           , GAT_DESCODES_24
           , GAT_DESCODES_25
           , GAT_DESCODES_26
           , GAT_DESCODES_27
           , GAT_DESCODES_28
           , GAT_DESCODES_29
           , GAT_DESCODES_30
           , DIC_GCO_ATTRIBUTE_FREE_01_ID
           , DIC_GCO_ATTRIBUTE_FREE_02_ID
           , DIC_GCO_ATTRIBUTE_FREE_03_ID
           , DIC_GCO_ATTRIBUTE_FREE_04_ID
           , DIC_GCO_ATTRIBUTE_FREE_05_ID
           , DIC_GCO_ATTRIBUTE_FREE_06_ID
           , DIC_GCO_ATTRIBUTE_FREE_07_ID
           , DIC_GCO_ATTRIBUTE_FREE_08_ID
           , DIC_GCO_ATTRIBUTE_FREE_09_ID
           , DIC_GCO_ATTRIBUTE_FREE_10_ID
           , DIC_GCO_ATTRIBUTE_FREE_11_ID
           , DIC_GCO_ATTRIBUTE_FREE_12_ID
           , DIC_GCO_ATTRIBUTE_FREE_13_ID
           , DIC_GCO_ATTRIBUTE_FREE_14_ID
           , DIC_GCO_ATTRIBUTE_FREE_15_ID
           , DIC_GCO_ATTRIBUTE_FREE_16_ID
           , DIC_GCO_ATTRIBUTE_FREE_17_ID
           , DIC_GCO_ATTRIBUTE_FREE_18_ID
           , DIC_GCO_ATTRIBUTE_FREE_19_ID
           , DIC_GCO_ATTRIBUTE_FREE_20_ID
           , DIC_GCO_ATTRIBUTE_FREE_21_ID
           , DIC_GCO_ATTRIBUTE_FREE_22_ID
           , DIC_GCO_ATTRIBUTE_FREE_23_ID
           , DIC_GCO_ATTRIBUTE_FREE_24_ID
           , DIC_GCO_ATTRIBUTE_FREE_25_ID
           , DIC_GCO_ATTRIBUTE_FREE_26_ID
           , DIC_GCO_ATTRIBUTE_FREE_27_ID
           , DIC_GCO_ATTRIBUTE_FREE_28_ID
           , DIC_GCO_ATTRIBUTE_FREE_29_ID
           , DIC_GCO_ATTRIBUTE_FREE_30_ID
           , DIC_GCO_ATTRIBUTE_FREE_31_ID
           , DIC_GCO_ATTRIBUTE_FREE_32_ID
           , DIC_GCO_ATTRIBUTE_FREE_33_ID
           , DIC_GCO_ATTRIBUTE_FREE_34_ID
           , DIC_GCO_ATTRIBUTE_FREE_35_ID
           , DIC_GCO_ATTRIBUTE_FREE_36_ID
           , DIC_GCO_ATTRIBUTE_FREE_37_ID
           , DIC_GCO_ATTRIBUTE_FREE_38_ID
           , DIC_GCO_ATTRIBUTE_FREE_39_ID
           , DIC_GCO_ATTRIBUTE_FREE_40_ID
           , DIC_GCO_ATTRIBUTE_FREE_41_ID
           , DIC_GCO_ATTRIBUTE_FREE_42_ID
           , DIC_GCO_ATTRIBUTE_FREE_43_ID
           , DIC_GCO_ATTRIBUTE_FREE_44_ID
           , DIC_GCO_ATTRIBUTE_FREE_45_ID
           , DIC_GCO_ATTRIBUTE_FREE_46_ID
           , DIC_GCO_ATTRIBUTE_FREE_47_ID
           , DIC_GCO_ATTRIBUTE_FREE_48_ID
           , DIC_GCO_ATTRIBUTE_FREE_49_ID
           , DIC_GCO_ATTRIBUTE_FREE_50_ID
           , DIC_GCO_ATTRIBUTE_FREE_51_ID
           , DIC_GCO_ATTRIBUTE_FREE_52_ID
           , DIC_GCO_ATTRIBUTE_FREE_53_ID
           , DIC_GCO_ATTRIBUTE_FREE_54_ID
           , DIC_GCO_ATTRIBUTE_FREE_55_ID
           , DIC_GCO_ATTRIBUTE_FREE_56_ID
           , DIC_GCO_ATTRIBUTE_FREE_57_ID
           , DIC_GCO_ATTRIBUTE_FREE_58_ID
           , DIC_GCO_ATTRIBUTE_FREE_59_ID
           , DIC_GCO_ATTRIBUTE_FREE_60_ID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_GOOD_ATTRIBUTE
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodAttr;

  /**
  * Description : Duplication des données compl. de stock d'un bien vers un autre
  */
  procedure DuplicateGoodDataStock(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_COMPL_DATA_STOCK
                (GCO_COMPL_DATA_STOCK_ID
               , GCO_GOOD_ID
               , DIC_UNIT_OF_MEASURE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_SUBSTITUTION_LIST_ID
               , GCO_QUALITY_PRINCIPLE_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_COMPLEMENTARY_EAN_CODE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , CDA_COMMENT
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , CDA_FREE_ALPHA_1
               , CDA_FREE_ALPHA_2
               , CDA_FREE_DEC_1
               , CDA_FREE_DEC_2
               , CST_QUANTITY_OBTAINING_STOCK
               , CST_QUANTITY_MIN
               , CST_STORING_CAUTION
               , DIC_COMPLEMENTARY_DATA_ID
               , CST_OBTAINING_MULTIPLE
               , CST_NUMBER_PERIOD
               , CST_PERIOD_VALUE
               , CST_QUANTITY_MAX
               , CST_PROPRIETOR_STOCK
               , CST_TRANSFERT_DELAY
               , CST_TRIGGER_POINT
               , CDA_COMPLEMENTARY_UCC14_CODE
               , CDA_SECONDARY_REFERENCE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_COMPL_DATA_STOCK_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , DIC_UNIT_OF_MEASURE_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_SUBSTITUTION_LIST_ID
           , GCO_QUALITY_PRINCIPLE_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , null   -- CDA_COMPLEMENTARY_EAN_CODE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMMENT
           , CDA_NUMBER_OF_DECIMAL
           , CDA_CONVERSION_FACTOR
           , CDA_FREE_ALPHA_1
           , CDA_FREE_ALPHA_2
           , CDA_FREE_DEC_1
           , CDA_FREE_DEC_2
           , CST_QUANTITY_OBTAINING_STOCK
           , CST_QUANTITY_MIN
           , CST_STORING_CAUTION
           , DIC_COMPLEMENTARY_DATA_ID
           , CST_OBTAINING_MULTIPLE
           , CST_NUMBER_PERIOD
           , CST_PERIOD_VALUE
           , CST_QUANTITY_MAX
           , CST_PROPRIETOR_STOCK
           , CST_TRANSFERT_DELAY
           , CST_TRIGGER_POINT
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CDA_SECONDARY_REFERENCE
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_COMPL_DATA_STOCK
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDataStock;

  /**
   * Description : Duplication des données compl. de distribution d'un bien vers un autre
   */
  procedure DuplicateGoodDataDistrib(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_COMPL_DATA_DISTRIB
                (GCO_COMPL_DATA_DISTRIB_ID
               , GCO_GOOD_ID
               , GCO_PRODUCT_GROUP_ID
               , STM_DISTRIBUTION_UNIT_ID
               , DIC_DISTRIB_COMPL_DATA_ID
               , CDI_PRIORITY_CODE
               , CDI_COVER_PERCENT
               , C_DRP_USE_COVER_PERCENT
               , CDI_BLOCKED_FROM
               , CDI_BLOCKED_TO
               , DIC_UNIT_OF_MEASURE_ID
               , CDI_ECONOMICAL_QUANTITY
               , C_DRP_QTY_RULE
               , C_DRP_DOC_MODE
               , CDI_STOCK_MIN
               , CDI_STOCK_MAX
               , C_DRP_RELIQUAT
               , CDA_COMMENT
               , CDA_COMPLEMENTARY_EAN_CODE
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_COMPLEMENTARY_UCC14_CODE
               , CDA_CONVERSION_FACTOR
               , CDA_FREE_ALPHA_1
               , CDA_FREE_ALPHA_2
               , CDA_FREE_DEC_1
               , CDA_FREE_DEC_2
               , CDA_FREE_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_NUMBER_OF_DECIMAL
               , CDA_SHORT_DESCRIPTION
               , CDA_SECONDARY_REFERENCE
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_SUBSTITUTION_LIST_ID
               , GCO_QUALITY_PRINCIPLE_ID
               , DIC_COMPLEMENTARY_DATA_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_COMPL_DATA_DISTRIB_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , GCO_PRODUCT_GROUP_ID
           , STM_DISTRIBUTION_UNIT_ID
           , DIC_DISTRIB_COMPL_DATA_ID
           , CDI_PRIORITY_CODE
           , CDI_COVER_PERCENT
           , C_DRP_USE_COVER_PERCENT
           , CDI_BLOCKED_FROM
           , CDI_BLOCKED_TO
           , DIC_UNIT_OF_MEASURE_ID
           , CDI_ECONOMICAL_QUANTITY
           , C_DRP_QTY_RULE
           , C_DRP_DOC_MODE
           , CDI_STOCK_MIN
           , CDI_STOCK_MAX
           , C_DRP_RELIQUAT
           , CDA_COMMENT
           , null   -- CDA_COMPLEMENTARY_EAN_CODE
           , CDA_COMPLEMENTARY_REFERENCE
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CDA_CONVERSION_FACTOR
           , CDA_FREE_ALPHA_1
           , CDA_FREE_ALPHA_2
           , CDA_FREE_DEC_1
           , CDA_FREE_DEC_2
           , CDA_FREE_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_NUMBER_OF_DECIMAL
           , CDA_SHORT_DESCRIPTION
           , CDA_SECONDARY_REFERENCE
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_SUBSTITUTION_LIST_ID
           , GCO_QUALITY_PRINCIPLE_ID
           , DIC_COMPLEMENTARY_DATA_ID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_COMPL_DATA_DISTRIB
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDataDistrib;

  /**
  * Description : Duplication des données compl. de l'inventaire d'un bien vers un autre
  */
  procedure DuplicateGoodDataInventory(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_COMPL_DATA_INVENTORY
                (GCO_COMPL_DATA_INVENTORY_ID
               , GCO_GOOD_ID
               , DIC_UNIT_OF_MEASURE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_SUBSTITUTION_LIST_ID
               , GCO_QUALITY_PRINCIPLE_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_COMPLEMENTARY_EAN_CODE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , CDA_COMMENT
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , CDA_FREE_ALPHA_1
               , CDA_FREE_ALPHA_2
               , CDA_FREE_DEC_1
               , CDA_FREE_DEC_2
               , CIN_TURNING_INVENTORY
               , CIN_TURNING_INVENTORY_DELAY
               , CIN_LAST_INVENTORY_DATE
               , CIN_NEXT_INVENTORY_DATE
               , CIN_FIXED_STOCK_POSITION
               , DIC_COMPLEMENTARY_DATA_ID
               , CDA_COMPLEMENTARY_UCC14_CODE
               , CDA_SECONDARY_REFERENCE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_COMPL_DATA_INVENTORY_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , DIC_UNIT_OF_MEASURE_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_SUBSTITUTION_LIST_ID
           , GCO_QUALITY_PRINCIPLE_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , null   -- CDA_COMPLEMENTARY_EAN_CODE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMMENT
           , CDA_NUMBER_OF_DECIMAL
           , CDA_CONVERSION_FACTOR
           , CDA_FREE_ALPHA_1
           , CDA_FREE_ALPHA_2
           , CDA_FREE_DEC_1
           , CDA_FREE_DEC_2
           , CIN_TURNING_INVENTORY
           , CIN_TURNING_INVENTORY_DELAY
           , decode(nvl(CIN_TURNING_INVENTORY, 0), 0, CIN_LAST_INVENTORY_DATE, sysdate) CIN_LAST_INVENTORY_DATE
           -- La date du prochain inventaire est le premier jour ouvrable depuis la date système + le décalage en jours (CIN_TURNING_INVENTORY_DELAY)
      ,      decode(nvl(CIN_TURNING_INVENTORY, 0)
                  , 0, CIN_NEXT_INVENTORY_DATE
                  , decode(to_char(trunc(sysdate) + CIN_TURNING_INVENTORY_DELAY, 'D')
                         , 1, trunc(sysdate) + CIN_TURNING_INVENTORY_DELAY + 1
                         , 7, trunc(sysdate) + CIN_TURNING_INVENTORY_DELAY + 2
                         , trunc(sysdate) + CIN_TURNING_INVENTORY_DELAY
                          )
                   ) CIN_NEXT_INVENTORY_DATE
           , CIN_FIXED_STOCK_POSITION
           , DIC_COMPLEMENTARY_DATA_ID
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CDA_SECONDARY_REFERENCE
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_COMPL_DATA_INVENTORY
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDataInventory;

  /**
  * Description : Duplication des données compl. d'achat d'un bien vers un autre
  */
  procedure DuplicateGoodDataPurchase(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_COMPL_DATA_PURCHASE
                (GCO_COMPL_DATA_PURCHASE_ID
               , GCO_GOOD_ID
               , C_QTY_SUPPLY_RULE
               , C_TIME_SUPPLY_RULE
               , PAC_SUPPLIER_PARTNER_ID
               , DIC_UNIT_OF_MEASURE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_SUBSTITUTION_LIST_ID
               , GCO_QUALITY_PRINCIPLE_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_COMPLEMENTARY_EAN_CODE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , CDA_COMMENT
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , CPU_AUTOMATIC_GENERATING_PROP
               , CPU_SUPPLY_DELAY
               , CPU_ECONOMICAL_QUANTITY
               , CPU_FIXED_DELAY
               , CPU_SUPPLY_CAPACITY
               , CPU_CONTROL_DELAY
               , CPU_PERCENT_TRASH
               , CPU_FIXED_QUANTITY_TRASH
               , CPU_QTY_REFERENCE_TRASH
               , CPU_DEFAULT_SUPPLIER
               , DIC_COMPLEMENTARY_DATA_ID
               , CDA_FREE_ALPHA_1
               , CDA_FREE_ALPHA_2
               , CDA_FREE_DEC_1
               , CDA_FREE_DEC_2
               , CPU_SECURITY_DELAY
               , C_ECONOMIC_CODE
               , CPU_SHIFT
               , C_GAUGE_TYPE_POS
               , CPU_GAUGE_TYPE_POS_MANDATORY
               , PAC_PAC_SUPPLIER_PARTNER_ID
               , GCO_GCO_GOOD_ID
               , CPU_PRECIOUS_MAT_VALUE
               , CPU_MODULO_QUANTITY
               , CDA_COMPLEMENTARY_UCC14_CODE
               , CPU_HIBC_CODE
               , CPU_PERCENT_SOURCING
               , CDA_SECONDARY_REFERENCE
               , C_ASA_GUARANTY_UNIT
               , CPU_GUARANTY_PC_APPLTXT_ID
               , CPU_OFFICIAL_SUPPLIER
               , CPU_WARRANTY_PERIOD
               , C_GOOD_LITIG
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_COMPL_DATA_PURCHASE_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , C_QTY_SUPPLY_RULE
           , C_TIME_SUPPLY_RULE
           , PAC_SUPPLIER_PARTNER_ID
           , DIC_UNIT_OF_MEASURE_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_SUBSTITUTION_LIST_ID
           , GCO_QUALITY_PRINCIPLE_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , null   -- CDA_COMPLEMENTARY_EAN_CODE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMMENT
           , CDA_NUMBER_OF_DECIMAL
           , CDA_CONVERSION_FACTOR
           , CPU_AUTOMATIC_GENERATING_PROP
           , CPU_SUPPLY_DELAY
           , CPU_ECONOMICAL_QUANTITY
           , CPU_FIXED_DELAY
           , CPU_SUPPLY_CAPACITY
           , CPU_CONTROL_DELAY
           , CPU_PERCENT_TRASH
           , CPU_FIXED_QUANTITY_TRASH
           , CPU_QTY_REFERENCE_TRASH
           , CPU_DEFAULT_SUPPLIER
           , DIC_COMPLEMENTARY_DATA_ID
           , CDA_FREE_ALPHA_1
           , CDA_FREE_ALPHA_2
           , CDA_FREE_DEC_1
           , CDA_FREE_DEC_2
           , CPU_SECURITY_DELAY
           , C_ECONOMIC_CODE
           , CPU_SHIFT
           , C_GAUGE_TYPE_POS
           , CPU_GAUGE_TYPE_POS_MANDATORY
           , PAC_PAC_SUPPLIER_PARTNER_ID
           , GCO_GCO_GOOD_ID
           , CPU_PRECIOUS_MAT_VALUE
           , CPU_MODULO_QUANTITY
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CPU_HIBC_CODE
           , CPU_PERCENT_SOURCING
           , CDA_SECONDARY_REFERENCE
           , C_ASA_GUARANTY_UNIT
           , CPU_GUARANTY_PC_APPLTXT_ID
           , CPU_OFFICIAL_SUPPLIER
           , CPU_WARRANTY_PERIOD
           , C_GOOD_LITIG
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_COMPL_DATA_PURCHASE
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDataPurchase;

  /**
  * Description : Duplication des données compl. de vente d'un bien vers un autre
  */
  procedure DuplicateGoodDataSale(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor DataSale_Info(GoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select *
        from GCO_COMPL_DATA_SALE
       where GCO_GOOD_ID = GoodID;

    Tuple_DataSale DataSale_Info%rowtype;
    NewDataSaleID  GCO_COMPL_DATA_SALE.GCO_COMPL_DATA_SALE_ID%type;
  begin
    open DataSale_Info(SourceGoodID);

    fetch DataSale_Info
     into Tuple_DataSale;

    -- Création des données de la table GCO_COMPL_DATA_SALE
    while DataSale_Info%found loop
      -- ID de la nouvelle donnée compl. de vente
      select INIT_ID_SEQ.nextval
        into NewDataSaleID
        from dual;

      insert into GCO_COMPL_DATA_SALE
                  (GCO_COMPL_DATA_SALE_ID
                 , GCO_GOOD_ID
                 , PAC_CUSTOM_PARTNER_ID
                 , DIC_UNIT_OF_MEASURE_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , GCO_SUBSTITUTION_LIST_ID
                 , GCO_QUALITY_PRINCIPLE_ID
                 , C_GAUGE_TYPE_POS
                 , CDA_COMPLEMENTARY_REFERENCE
                 , CDA_COMPLEMENTARY_EAN_CODE
                 , CDA_SHORT_DESCRIPTION
                 , CDA_LONG_DESCRIPTION
                 , CDA_FREE_DESCRIPTION
                 , CDA_COMMENT
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , CSA_DELIVERY_DELAY
                 , CSA_SHIPPING_CAUTION
                 , CSA_DISPATCHING_DELAY
                 , CSA_QTY_CONDITIONING
                 , CSA_GOOD_PACKED
                 , DIC_COMPLEMENTARY_DATA_ID
                 , CDA_FREE_ALPHA_1
                 , CDA_FREE_ALPHA_2
                 , CDA_FREE_DEC_1
                 , CDA_FREE_DEC_2
                 , CSA_GAUGE_TYPE_POS_MANDATORY
                 , CSA_STACKABLE
                 , DIC_PACKING_TYPE_ID
                 , CSA_TH_SUPPLY_DELAY
                 , CSA_SCALE_LINK
                 , CDA_COMPLEMENTARY_UCC14_CODE
                 , CSA_HIBC_CODE
                 , CDA_SECONDARY_REFERENCE
                 , CSA_LAPSING_MARGE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewDataSaleID   -- GCO_COMPL_DATA_SALE_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , Tuple_DataSale.PAC_CUSTOM_PARTNER_ID
             , Tuple_DataSale.DIC_UNIT_OF_MEASURE_ID
             , Tuple_DataSale.STM_STOCK_ID
             , Tuple_DataSale.STM_LOCATION_ID
             , Tuple_DataSale.GCO_SUBSTITUTION_LIST_ID
             , Tuple_DataSale.GCO_QUALITY_PRINCIPLE_ID
             , Tuple_DataSale.C_GAUGE_TYPE_POS
             , Tuple_DataSale.CDA_COMPLEMENTARY_REFERENCE
             , null   -- CDA_COMPLEMENTARY_EAN_CODE
             , Tuple_DataSale.CDA_SHORT_DESCRIPTION
             , Tuple_DataSale.CDA_LONG_DESCRIPTION
             , Tuple_DataSale.CDA_FREE_DESCRIPTION
             , Tuple_DataSale.CDA_COMMENT
             , Tuple_DataSale.CDA_NUMBER_OF_DECIMAL
             , Tuple_DataSale.CDA_CONVERSION_FACTOR
             , Tuple_DataSale.CSA_DELIVERY_DELAY
             , Tuple_DataSale.CSA_SHIPPING_CAUTION
             , Tuple_DataSale.CSA_DISPATCHING_DELAY
             , Tuple_DataSale.CSA_QTY_CONDITIONING
             , Tuple_DataSale.CSA_GOOD_PACKED
             , Tuple_DataSale.DIC_COMPLEMENTARY_DATA_ID
             , Tuple_DataSale.CDA_FREE_ALPHA_1
             , Tuple_DataSale.CDA_FREE_ALPHA_2
             , Tuple_DataSale.CDA_FREE_DEC_1
             , Tuple_DataSale.CDA_FREE_DEC_2
             , Tuple_DataSale.CSA_GAUGE_TYPE_POS_MANDATORY
             , Tuple_DataSale.CSA_STACKABLE
             , Tuple_DataSale.DIC_PACKING_TYPE_ID
             , Tuple_DataSale.CSA_TH_SUPPLY_DELAY
             , Tuple_DataSale.CSA_SCALE_LINK
             , Tuple_DataSale.CDA_COMPLEMENTARY_UCC14_CODE
             , Tuple_DataSale.CSA_HIBC_CODE
             , Tuple_DataSale.CDA_SECONDARY_REFERENCE
             , Tuple_DataSale.CSA_LAPSING_MARGE
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- Création des données de la table GCO_PACKING_ELEMENT
      insert into GCO_PACKING_ELEMENT
                  (GCO_PACKING_ELEMENT_ID
                 , GCO_COMPL_DATA_SALE_ID
                 , GCO_GOOD_ID
                 , SHI_SEQ
                 , SHI_QUOTA
                 , SHI_COMMENT
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- GCO_PACKING_ELEMENT_ID
             , NewDataSaleID   -- GCO_COMPL_DATA_SALE_ID
             , GCO_GOOD_ID
             , SHI_SEQ
             , SHI_QUOTA
             , SHI_COMMENT
             , STM_STOCK_ID
             , STM_LOCATION_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from GCO_PACKING_ELEMENT
         where GCO_COMPL_DATA_SALE_ID = Tuple_DataSale.GCO_COMPL_DATA_SALE_ID;

      -- Donnée compl. de vente suivante
      fetch DataSale_Info
       into Tuple_DataSale;
    end loop;

    close DataSale_Info;
  end DuplicateGoodDataSale;

  /**
  * Description : Duplication des données compl. du SAV d'un bien vers un autre
  */
  procedure DuplicateGoodDataSAV(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor DataSAV_Info(GoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select *
        from GCO_COMPL_DATA_ASS
       where GCO_GOOD_ID = GoodID;

    Tuple_DataSAV DataSAV_Info%rowtype;
    NewDataSAV_ID GCO_COMPL_DATA_ASS.GCO_COMPL_DATA_ASS_ID%type;
  begin
    open DataSAV_Info(SourceGoodID);

    fetch DataSAV_Info
     into Tuple_DataSAV;

    -- Création des données de la table GCO_COMPL_DATA_ASS
    while DataSAV_Info%found loop
      -- ID de la nouvelle donnée compl. du SAV
      select INIT_ID_SEQ.nextval
        into NewDataSAV_ID
        from dual;

      insert into GCO_COMPL_DATA_ASS
                  (GCO_COMPL_DATA_ASS_ID
                 , GCO_GOOD_ID
                 , DIC_UNIT_OF_MEASURE_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , GCO_SUBSTITUTION_LIST_ID
                 , GCO_QUALITY_PRINCIPLE_ID
                 , CDA_COMPLEMENTARY_REFERENCE
                 , CDA_COMPLEMENTARY_EAN_CODE
                 , CDA_SHORT_DESCRIPTION
                 , CDA_LONG_DESCRIPTION
                 , CDA_FREE_DESCRIPTION
                 , CDA_COMMENT
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , CAS_WITH_GUARANTEE
                 , CAS_GUARANTEE_DELAY
                 , DIC_COMPLEMENTARY_DATA_ID
                 , CDA_FREE_ALPHA_1
                 , CDA_FREE_ALPHA_2
                 , CDA_FREE_DEC_1
                 , CDA_FREE_DEC_2
                 , ASA_REP_TYPE_ID
                 , CAS_DEFAULT_REPAIR
                 , C_ASA_GUARANTY_UNIT
                 , DIC_TARIFF_ID
                 , CDA_COMPLEMENTARY_UCC14_CODE
                 , CDA_SECONDARY_REFERENCE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewDataSAV_ID   -- GCO_COMPL_DATA_ASS_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , Tuple_DataSAV.DIC_UNIT_OF_MEASURE_ID
             , Tuple_DataSAV.STM_STOCK_ID
             , Tuple_DataSAV.STM_LOCATION_ID
             , Tuple_DataSAV.GCO_SUBSTITUTION_LIST_ID
             , Tuple_DataSAV.GCO_QUALITY_PRINCIPLE_ID
             , Tuple_DataSAV.CDA_COMPLEMENTARY_REFERENCE
             , null   -- CDA_COMPLEMENTARY_EAN_CODE
             , Tuple_DataSAV.CDA_SHORT_DESCRIPTION
             , Tuple_DataSAV.CDA_LONG_DESCRIPTION
             , Tuple_DataSAV.CDA_FREE_DESCRIPTION
             , Tuple_DataSAV.CDA_COMMENT
             , Tuple_DataSAV.CDA_NUMBER_OF_DECIMAL
             , Tuple_DataSAV.CDA_CONVERSION_FACTOR
             , Tuple_DataSAV.CAS_WITH_GUARANTEE
             , Tuple_DataSAV.CAS_GUARANTEE_DELAY
             , Tuple_DataSAV.DIC_COMPLEMENTARY_DATA_ID
             , Tuple_DataSAV.CDA_FREE_ALPHA_1
             , Tuple_DataSAV.CDA_FREE_ALPHA_2
             , Tuple_DataSAV.CDA_FREE_DEC_1
             , Tuple_DataSAV.CDA_FREE_DEC_2
             , Tuple_DataSAV.ASA_REP_TYPE_ID
             , Tuple_DataSAV.CAS_DEFAULT_REPAIR
             , Tuple_DataSAV.C_ASA_GUARANTY_UNIT
             , Tuple_DataSAV.DIC_TARIFF_ID
             , Tuple_DataSAV.CDA_COMPLEMENTARY_UCC14_CODE
             , Tuple_DataSAV.CDA_SECONDARY_REFERENCE
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- Création des données de la table ASA_REP_TYPE_GOOD
      insert into ASA_REP_TYPE_GOOD
                  (ASA_REP_TYPE_GOOD_ID
                 , GCO_GOOD_TO_REPAIR_ID
                 , ASA_REP_TYPE_ID
                 , RTG_GARANTEE
                 , RTG_GARANTEE_DAYS
                 , GCO_GOOD_FOR_EXCH_ID
                 , STM_ASA_IN_STOCK_ID
                 , STM_ASA_OUT_STOCK_ID
                 , STM_ASA_IN_LOC_ID
                 , STM_ASA_OUT_LOC_ID
                 , RTG_COST_PRICE_W
                 , RTG_COST_PRICE_C
                 , RTG_COST_PRICE_T
                 , RTG_SALE_PRICE_W
                 , RTG_SALE_PRICE_C
                 , RTG_SALE_PRICE_T
                 , RTG_COST_PRICE_S
                 , RTG_SALE_PRICE_S
                 , RTG_NB_DAYS
                 , C_ASA_GUARANTY_UNIT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- ASA_REP_TYPE_GOOD_ID
             , TargetGoodID   -- GCO_GOOD_TO_REPAIR_ID
             , ASA_REP_TYPE_ID
             , RTG_GARANTEE
             , RTG_GARANTEE_DAYS
             , GCO_GOOD_FOR_EXCH_ID
             , STM_ASA_IN_STOCK_ID
             , STM_ASA_OUT_STOCK_ID
             , STM_ASA_IN_LOC_ID
             , STM_ASA_OUT_LOC_ID
             , RTG_COST_PRICE_W
             , RTG_COST_PRICE_C
             , RTG_COST_PRICE_T
             , RTG_SALE_PRICE_W
             , RTG_SALE_PRICE_C
             , RTG_SALE_PRICE_T
             , RTG_COST_PRICE_S
             , RTG_SALE_PRICE_S
             , RTG_NB_DAYS
             , C_ASA_GUARANTY_UNIT
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from ASA_REP_TYPE_GOOD
         where GCO_GOOD_TO_REPAIR_ID = SourceGoodID
           and ASA_REP_TYPE_ID = Tuple_DataSAV.ASA_REP_TYPE_ID;

      -- Donnée compl. du SAV suivante
      fetch DataSAV_Info
       into Tuple_DataSAV;
    end loop;

    close DataSAV_Info;
  end DuplicateGoodDataSAV;

  /**
  * Description : Duplication des données compl. du SAV externe d'un bien vers un autre
  */
  procedure DuplicateGoodDataExtASA(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    complDataID GCO_COMPL_DATA_EXTERNAL_ASA.GCO_COMPL_DATA_EXTERNAL_ASA_ID%type;
  begin
    -- copie des compteurs
    insert into ASA_COUNTER_TYPE_S_GOOD
                (ASA_COUNTER_TYPE_S_GOOD_ID
               , ASA_COUNTER_TYPE_ID
               , GCO_GOOD_ID
               , CTG_PC_APPLTXT_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , ASA_COUNTER_TYPE_ID
           , TargetGoodID
           , CTG_PC_APPLTXT_ID
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from ASA_COUNTER_TYPE_S_GOOD
       where GCO_GOOD_ID = SourceGoodID;

    -- copie des données de base
    for cr_complData in (select *
                           from GCO_COMPL_DATA_EXTERNAL_ASA
                          where GCO_GOOD_ID = SourceGoodID) loop
      select INIT_ID_SEQ.nextval
        into complDataID
        from dual;

      insert into GCO_COMPL_DATA_EXTERNAL_ASA
                  (GCO_COMPL_DATA_EXTERNAL_ASA_ID
                 , GCO_GOOD_ID
                 , DIC_UNIT_OF_MEASURE_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , GCO_SUBSTITUTION_LIST_ID
                 , GCO_QUALITY_PRINCIPLE_ID
                 , CDA_COMPLEMENTARY_REFERENCE
                 , CDA_SECONDARY_REFERENCE
                 , CDA_SHORT_DESCRIPTION
                 , CDA_LONG_DESCRIPTION
                 , CDA_FREE_DESCRIPTION
                 , CDA_COMMENT
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , CDA_FREE_ALPHA_1
                 , CDA_FREE_ALPHA_2
                 , CDA_FREE_DEC_1
                 , CDA_FREE_DEC_2
                 , DIC_COMPLEMENTARY_DATA_ID
                 , C_ASA_NEW_GUARANTY_UNIT
                 , C_ASA_OLD_GUARANTY_UNIT
                 , CEA_NEW_ITEMS_WARRANTY
                 , CEA_OLD_ITEMS_WARRANTY
                 , DOC_RECORD_CATEGORY_ID
                 , DIC_CEA_FREE_CODE1_ID
                 , DIC_CEA_FREE_CODE2_ID
                 , DIC_CEA_FREE_CODE3_ID
                 , DIC_CEA_FREE_CODE4_ID
                 , DIC_CEA_FREE_CODE5_ID
                 , CEA_FREE_TEXT1
                 , CEA_FREE_TEXT2
                 , CEA_FREE_TEXT3
                 , CEA_FREE_TEXT4
                 , CEA_FREE_TEXT5
                 , CEA_FREE_NUMBER1
                 , CEA_FREE_NUMBER2
                 , CEA_FREE_NUMBER3
                 , CEA_FREE_NUMBER4
                 , CEA_FREE_NUMBER5
                 , CEA_NEW_PC_APPLTXT_ID
                 , CEA_OLD_PC_APPLTXT_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select complDataID   -- GCO_COMPL_DATA_EXTERNAL_ASA_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , cr_complData.DIC_UNIT_OF_MEASURE_ID
             , cr_complData.STM_STOCK_ID
             , cr_complData.STM_LOCATION_ID
             , cr_complData.GCO_SUBSTITUTION_LIST_ID
             , cr_complData.GCO_QUALITY_PRINCIPLE_ID
             , cr_complData.CDA_COMPLEMENTARY_REFERENCE
             , cr_complData.CDA_SECONDARY_REFERENCE
             , cr_complData.CDA_SHORT_DESCRIPTION
             , cr_complData.CDA_LONG_DESCRIPTION
             , cr_complData.CDA_FREE_DESCRIPTION
             , cr_complData.CDA_COMMENT
             , cr_complData.CDA_NUMBER_OF_DECIMAL
             , cr_complData.CDA_CONVERSION_FACTOR
             , cr_complData.CDA_FREE_ALPHA_1
             , cr_complData.CDA_FREE_ALPHA_2
             , cr_complData.CDA_FREE_DEC_1
             , cr_complData.CDA_FREE_DEC_2
             , cr_complData.DIC_COMPLEMENTARY_DATA_ID
             , cr_complData.C_ASA_NEW_GUARANTY_UNIT
             , cr_complData.C_ASA_OLD_GUARANTY_UNIT
             , cr_complData.CEA_NEW_ITEMS_WARRANTY
             , cr_complData.CEA_OLD_ITEMS_WARRANTY
             , cr_complData.DOC_RECORD_CATEGORY_ID
             , cr_complData.DIC_CEA_FREE_CODE1_ID
             , cr_complData.DIC_CEA_FREE_CODE2_ID
             , cr_complData.DIC_CEA_FREE_CODE3_ID
             , cr_complData.DIC_CEA_FREE_CODE4_ID
             , cr_complData.DIC_CEA_FREE_CODE5_ID
             , cr_complData.CEA_FREE_TEXT1
             , cr_complData.CEA_FREE_TEXT2
             , cr_complData.CEA_FREE_TEXT3
             , cr_complData.CEA_FREE_TEXT4
             , cr_complData.CEA_FREE_TEXT5
             , cr_complData.CEA_FREE_NUMBER1
             , cr_complData.CEA_FREE_NUMBER2
             , cr_complData.CEA_FREE_NUMBER3
             , cr_complData.CEA_FREE_NUMBER4
             , cr_complData.CEA_FREE_NUMBER5
             , cr_complData.CEA_NEW_PC_APPLTXT_ID
             , cr_complData.CEA_OLD_PC_APPLTXT_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- copie des groupes de techniciens
      insert into GCO_COMPL_ASA_EXT_S_HRM_JOB
                  (HRM_JOB_ID
                 , GCO_COMPL_DATA_EXTERNAL_ASA_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select HRM_JOB_ID   -- HRM_JOB_ID
             , complDataID   -- GCO_COMPL_DATA_EXTERNAL_ASA_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from GCO_COMPL_ASA_EXT_S_HRM_JOB
         where GCO_COMPL_DATA_EXTERNAL_ASA_ID = cr_complData.GCO_COMPL_DATA_EXTERNAL_ASA_ID;

      -- copie des plans de service
      for cr_plan in (select CTG.ASA_COUNTER_TYPE_ID
                           , SER.GCO_SERVICE_PLAN_ID
                           , SER.ASA_COUNTER_TYPE_S_GOOD_ID
                           , SER.C_ASA_SERVICE_TYPE
                           , SER.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                           , SER.SER_COMMENT
                           , SER.SER_COUNTER_STATE
                           , SER.SER_CONVERSION_FACTOR
                           , SER.SER_PERIODICITY
                           , SER.SER_WORK_TIME
                           , SER.C_SERVICE_PLAN_PERIODICITY
                           , SER.DIC_SERVICE_TYPE_ID
                           , SER.DIC_SER_UNIT_OF_MEASURE_ID
                           , SER.A_DATECRE
                           , SER.A_IDCRE
                        from GCO_SERVICE_PLAN SER
                           , ASA_COUNTER_TYPE_S_GOOD CTG
                       where SER.GCO_COMPL_DATA_EXTERNAL_ASA_ID = cr_complData.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                         and SER.ASA_COUNTER_TYPE_S_GOOD_ID = CTG.ASA_COUNTER_TYPE_S_GOOD_ID) loop
        insert into GCO_SERVICE_PLAN
                    (GCO_SERVICE_PLAN_ID
                   , ASA_COUNTER_TYPE_S_GOOD_ID
                   , C_ASA_SERVICE_TYPE
                   , GCO_COMPL_DATA_EXTERNAL_ASA_ID
                   , SER_COMMENT
                   , SER_COUNTER_STATE
                   , SER_CONVERSION_FACTOR
                   , SER_PERIODICITY
                   , SER_WORK_TIME
                   , C_SERVICE_PLAN_PERIODICITY
                   , DIC_SERVICE_TYPE_ID
                   , DIC_SER_UNIT_OF_MEASURE_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , ASA_COUNTER_TYPE_S_GOOD_ID
               , cr_plan.C_ASA_SERVICE_TYPE
               , complDataID
               , cr_plan.SER_COMMENT
               , cr_plan.SER_COUNTER_STATE
               , cr_plan.SER_CONVERSION_FACTOR
               , cr_plan.SER_PERIODICITY
               , cr_plan.SER_WORK_TIME
               , cr_plan.C_SERVICE_PLAN_PERIODICITY
               , cr_plan.DIC_SERVICE_TYPE_ID
               , cr_plan.DIC_SER_UNIT_OF_MEASURE_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from ASA_COUNTER_TYPE_S_GOOD
           where GCO_GOOD_ID = TargetGoodID
             and ASA_COUNTER_TYPE_ID = cr_plan.ASA_COUNTER_TYPE_ID;
      end loop;
    end loop;
  end DuplicateGoodDataExtASA;

  /**
  * Description : Duplication des données compl. de fabrication d'un bien vers un autre
  */
  procedure DuplicateGoodDataManufacture(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_COMPL_DATA_MANUFACTURE
                (GCO_COMPL_DATA_MANUFACTURE_ID
               , GCO_GOOD_ID
               , C_QTY_SUPPLY_RULE
               , C_TIME_SUPPLY_RULE
               , DIC_UNIT_OF_MEASURE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_SUBSTITUTION_LIST_ID
               , GCO_QUALITY_PRINCIPLE_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_COMPLEMENTARY_EAN_CODE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , CDA_COMMENT
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , CMA_AUTOMATIC_GENERATING_PROP
               , CMA_ECONOMICAL_QUANTITY
               , CMA_FIXED_DELAY
               , CMA_MANUFACTURING_DELAY
               , CMA_PERCENT_TRASH
               , CMA_FIXED_QUANTITY_TRASH
               , CMA_PERCENT_WASTE
               , CMA_FIXED_QUANTITY_WASTE
               , CMA_QTY_REFERENCE_LOSS
               , FAL_SCHEDULE_PLAN_ID
               , PPS_OPERATION_PROCEDURE_ID
               , CMA_LOT_QUANTITY
               , CMA_PLAN_NUMBER
               , CMA_PLAN_VERSION
               , CMA_MULTIMEDIA_PLAN
               , PPS_NOMENCLATURE_ID
               , DIC_FAB_CONDITION_ID
               , CMA_DEFAULT
               , CMA_SCHEDULE_TYPE
               , DIC_COMPLEMENTARY_DATA_ID
               , PPS_RANGE_ID
               , CDA_FREE_ALPHA_1
               , CDA_FREE_ALPHA_2
               , CDA_FREE_DEC_1
               , CDA_FREE_DEC_2
               , C_ECONOMIC_CODE
               , CMA_SHIFT
               , CMA_FIX_DELAY
               , CMA_MODULO_QUANTITY
               , CMA_AUTO_RECEPT
               , CDA_COMPLEMENTARY_UCC14_CODE
               , CDA_SECONDARY_REFERENCE
               , CMA_SECURITY_DELAY
               , CMA_WEIGH
               , CMA_WEIGH_MANDATORY
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_COMPL_DATA_MANUFACTURE_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , C_QTY_SUPPLY_RULE
           , C_TIME_SUPPLY_RULE
           , DIC_UNIT_OF_MEASURE_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_SUBSTITUTION_LIST_ID
           , GCO_QUALITY_PRINCIPLE_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , null   -- CDA_COMPLEMENTARY_EAN_CODE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMMENT
           , CDA_NUMBER_OF_DECIMAL
           , CDA_CONVERSION_FACTOR
           , CMA_AUTOMATIC_GENERATING_PROP
           , CMA_ECONOMICAL_QUANTITY
           , CMA_FIXED_DELAY
           , CMA_MANUFACTURING_DELAY
           , CMA_PERCENT_TRASH
           , CMA_FIXED_QUANTITY_TRASH
           , CMA_PERCENT_WASTE
           , CMA_FIXED_QUANTITY_WASTE
           , CMA_QTY_REFERENCE_LOSS
           , FAL_SCHEDULE_PLAN_ID
           , PPS_OPERATION_PROCEDURE_ID
           , CMA_LOT_QUANTITY
           , CMA_PLAN_NUMBER
           , CMA_PLAN_VERSION
           , ''   -- CMA_MULTIMEDIA_PLAN
           , null   -- PPS_NOMENCLATURE_ID
           , DIC_FAB_CONDITION_ID
           , CMA_DEFAULT
           , CMA_SCHEDULE_TYPE
           , DIC_COMPLEMENTARY_DATA_ID
           , null   -- PPS_RANGE_ID
           , CDA_FREE_ALPHA_1
           , CDA_FREE_ALPHA_2
           , CDA_FREE_DEC_1
           , CDA_FREE_DEC_2
           , C_ECONOMIC_CODE
           , CMA_SHIFT
           , CMA_FIX_DELAY
           , CMA_MODULO_QUANTITY
           , CMA_AUTO_RECEPT
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CDA_SECONDARY_REFERENCE
           , CMA_SECURITY_DELAY
           , CMA_WEIGH
           , CMA_WEIGH_MANDATORY
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_COMPL_DATA_MANUFACTURE
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDataManufacture;

  /**
  * Description : Duplication des données compl. de la Sous-traitance d'un bien vers un autre
  */
  procedure DuplicateGoodDataSubcontract(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_COMPL_DATA_SUBCONTRACT
                (GCO_COMPL_DATA_SUBCONTRACT_ID
               , GCO_GOOD_ID
               , C_QTY_SUPPLY_RULE
               , C_TIME_SUPPLY_RULE
               , PAC_SUPPLIER_PARTNER_ID
               , DIC_UNIT_OF_MEASURE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_SUBSTITUTION_LIST_ID
               , GCO_QUALITY_PRINCIPLE_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_COMPLEMENTARY_EAN_CODE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , CDA_COMMENT
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , CSU_AUTOMATIC_GENERATING_PROP
               , CSU_ECONOMICAL_QUANTITY
               , CSU_FIXED_DELAY
               , CSU_SUBCONTRACTING_DELAY
               , CSU_HANDLING_CAUTION
               , CSU_PERCENT_TRASH
               , CSU_FIXED_QUANTITY_TRASH
               , CSU_QTY_REFERENCE_TRASH
               , CSU_DEFAULT_SUBCONTRACTER
               , DIC_COMPLEMENTARY_DATA_ID
               , CDA_FREE_ALPHA_1
               , CDA_FREE_ALPHA_2
               , CDA_FREE_DEC_1
               , CDA_FREE_DEC_2
               , C_ECONOMIC_CODE
               , CSU_CONTROL_DELAY
               , CSU_SHIFT
               , CSU_MODULO_QUANTITY
               , CDA_COMPLEMENTARY_UCC14_CODE
               , CDA_SECONDARY_REFERENCE
               , DIC_FAB_CONDITION_ID
               , PPS_NOMENCLATURE_ID
               , PPS_OPERATION_PROCEDURE_ID
               , C_GOOD_LITIG
               , CSU_VALIDITY_DATE
               , CSU_PLAN_NUMBER
               , CSU_PLAN_VERSION
               , CSU_SECURITY_DELAY
               , CSU_HIBC_CODE
               , C_DISCHARGE_COM
               , GCO_GCO_GOOD_ID
               , CSU_AMOUNT
               , CSU_WEIGH
               , CSU_WEIGH_MANDATORY
               , CSU_FIX_DELAY
               , CSU_LOT_QUANTITY
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_COMPL_DATA_SUBCONTRACT_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , C_QTY_SUPPLY_RULE
           , C_TIME_SUPPLY_RULE
           , PAC_SUPPLIER_PARTNER_ID
           , DIC_UNIT_OF_MEASURE_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_SUBSTITUTION_LIST_ID
           , GCO_QUALITY_PRINCIPLE_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , null   -- CDA_COMPLEMENTARY_EAN_CODE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMMENT
           , CDA_NUMBER_OF_DECIMAL
           , CDA_CONVERSION_FACTOR
           , CSU_AUTOMATIC_GENERATING_PROP
           , CSU_ECONOMICAL_QUANTITY
           , CSU_FIXED_DELAY
           , CSU_SUBCONTRACTING_DELAY
           , CSU_HANDLING_CAUTION
           , CSU_PERCENT_TRASH
           , CSU_FIXED_QUANTITY_TRASH
           , CSU_QTY_REFERENCE_TRASH
           , CSU_DEFAULT_SUBCONTRACTER
           , DIC_COMPLEMENTARY_DATA_ID
           , CDA_FREE_ALPHA_1
           , CDA_FREE_ALPHA_2
           , CDA_FREE_DEC_1
           , CDA_FREE_DEC_2
           , C_ECONOMIC_CODE
           , CSU_CONTROL_DELAY
           , CSU_SHIFT
           , CSU_MODULO_QUANTITY
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CDA_SECONDARY_REFERENCE
           , DIC_FAB_CONDITION_ID
           , PPS_NOMENCLATURE_ID
           , PPS_OPERATION_PROCEDURE_ID
           , C_GOOD_LITIG
           , CSU_VALIDITY_DATE
           , CSU_PLAN_NUMBER
           , CSU_PLAN_VERSION
           , CSU_SECURITY_DELAY
           , CSU_HIBC_CODE
           , C_DISCHARGE_COM
           , GCO_GCO_GOOD_ID
           , CSU_AMOUNT
           , CSU_WEIGH
           , CSU_WEIGH_MANDATORY
           , CSU_FIX_DELAY
           , CSU_LOT_QUANTITY
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_COMPL_DATA_SUBCONTRACT
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDataSubcontract;

  /**
  * Description : Duplication des données outil d'un bien vers un autre
  */
  procedure DuplicateGoodDataTool(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into PPS_TOOLS
                (GCO_GOOD_ID
               , C_TOOLS_TYPE
               , C_TOOLS_OWNER
               , TLS_TEXT
               , TLS_RATE
               , TLS_PLANNING_CODE
               , A_DATECRE
               , A_IDCRE
                )
      select TargetGoodID   -- GCO_GOOD_ID
           , C_TOOLS_TYPE
           , C_TOOLS_OWNER
           , TLS_TEXT
           , TLS_RATE
           , TLS_PLANNING_CODE
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from PPS_TOOLS
       where GCO_GOOD_ID = SourceGoodID;
  exception
    when no_data_found then
      null;
  end DuplicateGoodDataTool;

  /**
  * Description : Duplication des données libres d'un bien vers un autre
  */
  procedure DuplicateGoodFreeData(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    -- Copie des données libres de la table GCO_FREE_DATA
    insert into GCO_FREE_DATA
                (GCO_FREE_DATA_ID
               , GCO_GOOD_ID
               , DIC_FREE_TABLE_1_ID
               , DIC_FREE_TABLE_2_ID
               , DIC_FREE_TABLE_3_ID
               , DIC_FREE_TABLE_4_ID
               , DIC_FREE_TABLE_5_ID
               , DATA_ALPHA_COURT_1
               , DATA_ALPHA_COURT_2
               , DATA_ALPHA_COURT_3
               , DATA_ALPHA_COURT_4
               , DATA_ALPHA_COURT_5
               , DATA_ALPHA_LONG_1
               , DATA_ALPHA_LONG_2
               , DATA_ALPHA_LONG_3
               , DATA_ALPHA_LONG_4
               , DATA_ALPHA_LONG_5
               , DATA_INTEGER_1
               , DATA_INTEGER_2
               , DATA_INTEGER_3
               , DATA_INTEGER_4
               , DATA_INTEGER_5
               , DATA_BOOLEAN_1
               , DATA_BOOLEAN_2
               , DATA_BOOLEAN_3
               , DATA_BOOLEAN_4
               , DATA_BOOLEAN_5
               , DATA_DEC_1
               , DATA_DEC_2
               , DATA_DEC_3
               , DATA_DEC_4
               , DATA_DEC_5
               , DATA_UNIT_PRICE_SALE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_FREE_DATA_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , DIC_FREE_TABLE_1_ID
           , DIC_FREE_TABLE_2_ID
           , DIC_FREE_TABLE_3_ID
           , DIC_FREE_TABLE_4_ID
           , DIC_FREE_TABLE_5_ID
           , DATA_ALPHA_COURT_1
           , DATA_ALPHA_COURT_2
           , DATA_ALPHA_COURT_3
           , DATA_ALPHA_COURT_4
           , DATA_ALPHA_COURT_5
           , DATA_ALPHA_LONG_1
           , DATA_ALPHA_LONG_2
           , DATA_ALPHA_LONG_3
           , DATA_ALPHA_LONG_4
           , DATA_ALPHA_LONG_5
           , DATA_INTEGER_1
           , DATA_INTEGER_2
           , DATA_INTEGER_3
           , DATA_INTEGER_4
           , DATA_INTEGER_5
           , DATA_BOOLEAN_1
           , DATA_BOOLEAN_2
           , DATA_BOOLEAN_3
           , DATA_BOOLEAN_4
           , DATA_BOOLEAN_5
           , DATA_DEC_1
           , DATA_DEC_2
           , DATA_DEC_3
           , DATA_DEC_4
           , DATA_DEC_5
           , DATA_UNIT_PRICE_SALE
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_FREE_DATA
       where GCO_GOOD_ID = SourceGoodID;

    -- Copie des données libres de la table GCO_FREE_CODE
    insert into GCO_FREE_CODE
                (GCO_FREE_CODE_ID
               , GCO_GOOD_ID
               , FCO_NUM_CODE
               , FCO_MEM_CODE
               , FCO_DAT_CODE
               , FCO_CHA_CODE
               , FCO_BOO_CODE
               , DIC_GCO_NUMBER_CODE_TYPE_ID
               , DIC_GCO_MEMO_CODE_TYPE_ID
               , DIC_GCO_DATE_CODE_TYPE_ID
               , DIC_GCO_CHAR_CODE_TYPE_ID
               , DIC_GCO_BOOLEAN_CODE_TYPE_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_FREE_CODE_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , FCO_NUM_CODE
           , FCO_MEM_CODE
           , FCO_DAT_CODE
           , FCO_CHA_CODE
           , FCO_BOO_CODE
           , DIC_GCO_NUMBER_CODE_TYPE_ID
           , DIC_GCO_MEMO_CODE_TYPE_ID
           , DIC_GCO_DATE_CODE_TYPE_ID
           , DIC_GCO_CHAR_CODE_TYPE_ID
           , DIC_GCO_BOOLEAN_CODE_TYPE_ID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_FREE_CODE
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodFreeData;

  /**
  * Description : Duplication des Taxes et TVA
  */
  procedure DuplicateGoodVAT(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_VAT_GOOD
                (GCO_VAT_GOOD_ID
               , GCO_GOOD_ID
               , ACS_VAT_DET_ACCOUNT_ID
               , DIC_TYPE_VAT_GOOD_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_VAT_GOOD_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , ACS_VAT_DET_ACCOUNT_ID
           , DIC_TYPE_VAT_GOOD_ID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_VAT_GOOD
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodVAT;

  /**
  * Description : Duplication des descriptions du bien
  */
  procedure DuplicateGoodDescription(
    SourceGoodID  in GCO_GOOD.GCO_GOOD_ID%type
  , TargetGoodID  in GCO_GOOD.GCO_GOOD_ID%type
  , NewShortDescr in GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type default null
  , NewLongDescr  in GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type default null
  , NewFreeDescr  in GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type default null
  )
  is
  begin
    insert into GCO_DESCRIPTION
                (GCO_DESCRIPTION_ID
               , GCO_GOOD_ID
               , PC_LANG_ID
               , GCO_MULTIMEDIA_ELEMENT_ID
               , C_DESCRIPTION_TYPE
               , DES_SHORT_DESCRIPTION
               , DES_LONG_DESCRIPTION
               , DES_FREE_DESCRIPTION
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_DESCRIPTION_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , PC_LANG_ID
           , GCO_MULTIMEDIA_ELEMENT_ID
           , C_DESCRIPTION_TYPE
           , nvl(NewShortDescr, DES_SHORT_DESCRIPTION)
           , nvl(NewLongDescr, DES_LONG_DESCRIPTION)
           , nvl(NewFreeDescr, DES_FREE_DESCRIPTION)
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_DESCRIPTION
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDescription;

  /**
  * Description : Duplication des corrélations du bien
  */
  procedure DuplicateGoodConnection(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_CONNECTED_GOOD
                (GCO_CONNECTED_GOOD_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , DIC_CONNECTED_TYPE_ID
               , CON_REM
               , CON_UTIL_COEFF
               , CON_DEFAULT_SELECTION
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_CONNECTED_GOOD_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , GCO_GCO_GOOD_ID
           , DIC_CONNECTED_TYPE_ID
           , CON_REM
           , CON_UTIL_COEFF
           , CON_DEFAULT_SELECTION
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_CONNECTED_GOOD
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodConnection;

  /**
  * Description : Duplication de l'imputation comptable document
  */
  procedure DuplicateGoodDocImputation(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_IMPUT_DOC
                (GCO_IMPUT_DOC_ID
               , GCO_GOOD_ID
               , C_ADMIN_DOMAIN
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_IMPUT_DOC_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , C_ADMIN_DOMAIN
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_IMPUT_DOC
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodDocImputation;

  /**
  * Description : Duplication des contrats
  */
  procedure DuplicateGoodContract(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor Contract_Info(GoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select *
        from GCO_CONTRACT_DATA
       where GCO_GOOD_ID = GoodID;

    cursor ContractClauses_Info(ContractDataID GCO_CONTRACT_DATA.GCO_CONTRACT_DATA_ID%type)
    is
      select CLA.*
        from GCO_CONTRACT_CLAUSES CLA
           , GCO_DATA_CLAUSES_CONTRACT CLA_CTR
       where CLA_CTR.GCO_CONTRACT_DATA_ID = ContractDataID
         and CLA_CTR.GCO_CONTRACT_CLAUSES_ID = CLA.GCO_CONTRACT_CLAUSES_ID;

    Tuple_Contract        Contract_Info%rowtype;
    Tuple_ContractClauses ContractClauses_Info%rowtype;
    NewContract_ID        GCO_CONTRACT_DATA.GCO_CONTRACT_DATA_ID%type;
    NewContractClauses_ID GCO_CONTRACT_CLAUSES.GCO_CONTRACT_CLAUSES_ID%type;
  begin
    -- Curseur sur les contrats du bien source
    open Contract_Info(SourceGoodID);

    fetch Contract_Info
     into Tuple_Contract;

    -- Création des données de la table GCO_CONTRACT_DATA pour le bien cible
    while Contract_Info%found loop
      -- ID de la nouveau contrat
      select INIT_ID_SEQ.nextval
        into NewContract_ID
        from dual;

      -- Insertion du nouveau contrat pour le bien cible
      insert into GCO_CONTRACT_DATA
                  (GCO_CONTRACT_DATA_ID
                 , GCO_GOOD_ID
                 , CTR_NUMBER
                 , CTR_CONTRACTER
                 , CTR_START_DATE
                 , CTR_END_DATE
                 , CTR_TACIT_RENEW
                 , C_CONTRACT_RENEW
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewContract_ID   -- GCO_CONTRACT_DATA_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , Tuple_Contract.CTR_NUMBER
             , Tuple_Contract.CTR_CONTRACTER
             , Tuple_Contract.CTR_START_DATE
             , Tuple_Contract.CTR_END_DATE
             , Tuple_Contract.CTR_TACIT_RENEW
             , Tuple_Contract.C_CONTRACT_RENEW
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- Duplication de la table GCO_CONTRACT_OBJECT
      insert into GCO_CONTRACT_OBJECT
                  (GCO_CONTRACT_OBJECT_ID
                 , GCO_CONTRACT_DATA_ID
                 , GCO_CONTRACT_OBJECT_WORDING
                 , OBJ_FREE_NUMBER_1
                 , OBJ_FREE_NUMBER_2
                 , OBJ_FREE_NUMBER_3
                 , OBJ_FREE_ALPHA_1
                 , OBJ_FREE_ALPHA_2
                 , OBJ_FREE_ALPHA_3
                 , OBJ_OR_COUV
                 , OBJ_DESCRIPTION
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- GCO_CONTRACT_OBJECT_ID
             , NewContract_ID   -- GCO_CONTRACT_DATA_ID
             , GCO_CONTRACT_OBJECT_WORDING
             , OBJ_FREE_NUMBER_1
             , OBJ_FREE_NUMBER_2
             , OBJ_FREE_NUMBER_3
             , OBJ_FREE_ALPHA_1
             , OBJ_FREE_ALPHA_2
             , OBJ_FREE_ALPHA_3
             , OBJ_OR_COUV
             , OBJ_DESCRIPTION
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from GCO_CONTRACT_OBJECT
         where GCO_CONTRACT_DATA_ID = Tuple_Contract.GCO_CONTRACT_DATA_ID;

      -- Curseur sur les clauses de contrat du contart courant du bien source
      open ContractClauses_Info(Tuple_Contract.GCO_CONTRACT_DATA_ID);

      fetch ContractClauses_Info
       into Tuple_ContractClauses;

      -- Création des données de la table GCO_CONTRACT_CLAUSES pour le bien cible
      while ContractClauses_Info%found loop
        -- ID de la nouvelle clause de contrat
        select INIT_ID_SEQ.nextval
          into NewContractClauses_ID
          from dual;

        -- Insertion de la clause du contrat du bien cible
        insert into GCO_CONTRACT_CLAUSES
                    (GCO_CONTRACT_CLAUSES_ID
                   , CLA_DESCRIPTION
                   , CLA_TITLE
                   , CLA_REFERENCE
                   , A_DATECRE
                   , A_IDCRE
                    )
          select NewContractClauses_ID   -- GCO_CONTRACT_CLAUSES_ID
               , Tuple_ContractClauses.CLA_DESCRIPTION
               , Tuple_ContractClauses.CLA_TITLE
               , Tuple_ContractClauses.CLA_REFERENCE
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
            from dual;

        -- Table de jointure entre les clauses et le contract
        insert into GCO_DATA_CLAUSES_CONTRACT
                    (GCO_CONTRACT_CLAUSES_ID
                   , GCO_CONTRACT_DATA_ID
                    )
             values (NewContractClauses_ID
                   , NewContract_ID
                    );

        -- Clause de Contrat suivante
        fetch ContractClauses_Info
         into Tuple_ContractClauses;
      end loop;

      close ContractClauses_Info;
    end loop;

    close Contract_Info;
  end DuplicateGoodContract;

  /**
  * Description : Duplication des ressources
  */
  procedure DuplicateGoodRessource(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor Ressources_Info(GoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select RES.*
        from GCO_RESOURCE RES
           , GCO_SERVICE_RESOURCE GOO_RES
       where GOO_RES.GCO_GOOD_ID = GoodID
         and GOO_RES.GCO_RESOURCE_ID = RES.GCO_RESOURCE_ID;

    Tuple_Ressources Ressources_Info%rowtype;
    NewRessources_ID GCO_RESOURCE.GCO_RESOURCE_ID%type;
  begin
    -- Curseur sur les clauses de contrat du contart courant du bien source
    open Ressources_Info(SourceGoodID);

    fetch Ressources_Info
     into Tuple_Ressources;

    while Ressources_Info%found loop
      -- ID de la nouvelle Ressource
      select INIT_ID_SEQ.nextval
        into NewRessources_ID
        from dual;

      -- Insertion de la nouvelle ressource
      insert into GCO_RESOURCE
                  (GCO_RESOURCE_ID
                 , DIC_RESOURCE_TYPE_ID
                 , GCO_RESOURCE_WORDING
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewRessources_ID   -- GCO_RESOURCE_ID
             , Tuple_Ressources.DIC_RESOURCE_TYPE_ID
             , Tuple_Ressources.GCO_RESOURCE_WORDING
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual;

      -- Table de jointure entre les ressources et le bien
      insert into GCO_SERVICE_RESOURCE
                  (GCO_GOOD_ID
                 , GCO_RESOURCE_ID
                  )
           values (TargetGoodID
                 , NewRessources_ID
                  );

      fetch Ressources_Info
       into Tuple_Ressources;
    end loop;

    close Ressources_Info;
  end DuplicateGoodRessource;

  /**
  * Description : Duplication des matières précieuses
  */
  procedure DuplicateGoodPreciousMat(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    insert into GCO_PRECIOUS_MAT
                (GCO_PRECIOUS_MAT_ID
               , GCO_ALLOY_ID
               , GCO_GOOD_ID
               , DIC_FREE_PMAT1_ID
               , DIC_FREE_PMAT2_ID
               , DIC_FREE_PMAT3_ID
               , DIC_FREE_PMAT4_ID
               , DIC_FREE_PMAT5_ID
               , GPM_WEIGHT
               , GPM_REAL_WEIGHT
               , GPM_THEORICAL_WEIGHT
               , GPM_WEIGHT_DELIVER
               , GPM_STONE_NUMBER
               , GPM_WEIGHT_DELIVER_VALUE
               , GPM_WEIGHT_DELIVER_AUTO
               , GPM_LOSS_UNIT
               , GPM_LOSS_PERCENT
               , GPM_WEIGHT_INVEST
               , GPM_WEIGHT_INVEST_VALUE
               , GPM_WEIGHT_CHIP
               , GPM_WEIGHT_INVEST_TOTAL
               , GPM_WEIGHT_INVEST_TOTAL_VALUE
               , GPM_WEIGHT_CHIP_TOTAL
               , GPM_LOSS_TOTAL
               , GPM_COMMENT
               , GPM_COMMENT2
               , GPM_FREE_NUMBER1
               , GPM_FREE_NUMBER2
               , GPM_FREE_NUMBER3
               , GPM_FREE_NUMBER4
               , GPM_FREE_NUMBER5
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_PRECIOUS_MAT_ID
           , GCO_ALLOY_ID
           , TargetGoodID   -- GCO_GOOD_ID
           , DIC_FREE_PMAT1_ID
           , DIC_FREE_PMAT2_ID
           , DIC_FREE_PMAT3_ID
           , DIC_FREE_PMAT4_ID
           , DIC_FREE_PMAT5_ID
           , GPM_WEIGHT
           , GPM_REAL_WEIGHT
           , GPM_THEORICAL_WEIGHT
           , GPM_WEIGHT_DELIVER
           , GPM_STONE_NUMBER
           , GPM_WEIGHT_DELIVER_VALUE
           , GPM_WEIGHT_DELIVER_AUTO
           , GPM_LOSS_UNIT
           , GPM_LOSS_PERCENT
           , GPM_WEIGHT_INVEST
           , GPM_WEIGHT_INVEST_VALUE
           , GPM_WEIGHT_CHIP
           , GPM_WEIGHT_INVEST_TOTAL
           , GPM_WEIGHT_INVEST_TOTAL_VALUE
           , GPM_WEIGHT_CHIP_TOTAL
           , GPM_LOSS_TOTAL
           , GPM_COMMENT
           , GPM_COMMENT2
           , GPM_FREE_NUMBER1
           , GPM_FREE_NUMBER2
           , GPM_FREE_NUMBER3
           , GPM_FREE_NUMBER4
           , GPM_FREE_NUMBER5
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_PRECIOUS_MAT
       where GCO_GOOD_ID = SourceGoodID;
  end DuplicateGoodPreciousMat;

  /**
  * Description : Duplication des données de prestation
  */
  procedure DuplicateCMLService(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    vKind GCO_GOOD.C_SERVICE_KIND%type;
    vLink GCO_GOOD.C_SERVICE_GOOD_LINK%type;
  begin
    select nvl(C_SERVICE_KIND, 0)
         , nvl(C_SERVICE_GOOD_LINK, 0)
      into vKind
         , vLink
      from GCO_GOOD
     where GCO_GOOD_ID = SourceGoodID;

    -- Droit de consommation compteur
    if vKind = '1' then
      insert into GCO_SERVICE_COUNTER_LINK
                  (ASA_COUNTER_TYPE_ID
                 , GCO_SERVICE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select ASA_COUNTER_TYPE_ID
             , TargetGoodID
             , sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni
          from GCO_SERVICE_COUNTER_LINK
         where GCO_SERVICE_ID = SourceGoodID;
    -- Droit de consommation ou tarif préférentiel avec sélection manuelle des biens liés
    elsif     (   vKind = '2'
               or vKind = '3')
          and (vLink = '1') then
      insert into GCO_SERVICE_GOOD_LINK
                  (GCO_GOOD_ID
                 , GCO_SERVICE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GCO_GOOD_ID
             , TargetGoodID
             , sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni
          from GCO_SERVICE_GOOD_LINK
         where GCO_SERVICE_ID = SourceGoodID;
    end if;
  end DuplicateCMLService;

  /**
  *  Description : Génération du code EAN pour le produit
  */
  procedure GenerateEAN_Good(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(0, GoodID);

    update GCO_GOOD
       set GOO_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_Good;

  /**
  *  Description : Génération du code EAN pour les données compl. de stock
  */
  procedure GenerateEAN_ComplStock(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(1, GoodID);

    update GCO_COMPL_DATA_STOCK
       set CDA_COMPLEMENTARY_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_ComplStock;

  /**
  *  Description : Génération du code EAN pour les données compl. d'inventaire
  */
  procedure GenerateEAN_ComplInventory(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(2, GoodID);

    update GCO_COMPL_DATA_INVENTORY
       set CDA_COMPLEMENTARY_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_ComplInventory;

  /**
  *  Description : Génération du code EAN pour les données compl. d'achat
  */
  procedure GenerateEAN_ComplPurchase(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(3, GoodID);

    update GCO_COMPL_DATA_PURCHASE
       set CDA_COMPLEMENTARY_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_ComplPurchase;

  /**
  *  Description : Génération du code EAN pour les données compl. de vente
  */
  procedure GenerateEAN_ComplSale(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(4, GoodID);

    update GCO_COMPL_DATA_SALE
       set CDA_COMPLEMENTARY_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_ComplSale;

  /**
  *  Description : Génération du code EAN pour les données compl. de SAV
  */
  procedure GenerateEAN_ComplAss(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(5, GoodID);

    update GCO_COMPL_DATA_ASS
       set CDA_COMPLEMENTARY_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_ComplAss;

  /**
  *  Description : Génération du code EAN pour les données compl. de Sous-traitance
  */
  procedure GenerateEAN_ComplSubcontract(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(6, GoodID);

    update GCO_COMPL_DATA_SUBCONTRACT
       set CDA_COMPLEMENTARY_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_ComplSubcontract;

  /**
  *  Description : Génération du code EAN pour les données compl. de fabrication
  */
  procedure GenerateEAN_ComplManufacture(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    EanCode varchar2(40);
  begin
    EanCode  := GCO_EAN.EAN_Gen(7, GoodID);

    update GCO_COMPL_DATA_MANUFACTURE
       set CDA_COMPLEMENTARY_EAN_CODE = EanCode
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = GoodID;
  end GenerateEAN_ComplManufacture;

  /**
  *  Description : Génération des codes EAN pour le bien et ses données compl.
  */
  procedure GenerateEANCodes(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    /* Génération du code EAN pour
            0: Produit         - GCO_GOOD
            1: Stock           - GCO_COMPL_DATA_STOCK
            2: Inventaire      - GCO_COMPL_DATA_INVENTORY
            3: Achat           - GCO_COMPL_DATA_PURCHASE
            4: Vente           - GCO_COMPL_DATA_SALE
            5: SAV             - GCO_COMPL_DATA_ASS
            6: Sous-traitance  - GCO_COMPL_DATA_SUBCONTRACT
            7: Fabrication     - GCO_COMPL_DATA_MANUFACTURE
    */

    -- Génération du code EAN pour le produit
    GenerateEAN_Good(GoodID);
    -- Génération du code EAN pour les données compl. de stock
    GenerateEAN_ComplStock(GoodID);
    -- Génération du code EAN pour les données compl. d'inventaire
    GenerateEAN_ComplInventory(GoodID);
    -- Génération du code EAN pour les données compl. d'achat
    GenerateEAN_ComplPurchase(GoodID);
    -- Génération du code EAN pour les données compl. de vente
    GenerateEAN_ComplSale(GoodID);
    -- Génération du code EAN pour les données compl. de SAV
    GenerateEAN_ComplAss(GoodID);
    -- Génération du code EAN pour les données compl. de Sous-traitance
    GenerateEAN_ComplSubcontract(GoodID);
    -- Génération du code EAN pour les données compl. de fabrication
    GenerateEAN_ComplManufacture(GoodID);
  end GenerateEANCodes;

  /**
  * Description : Duplication des nomenclatures
  */
  procedure DuplicateGoodNomenclature(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor crNomenclature_Info(cGoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select *
        from PPS_NOMENCLATURE
       where GCO_GOOD_ID = cGoodID;

    NewNomenclature_ID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    for tplNomenclature_Info in crNomenclature_Info(SourceGoodID) loop
      -- id de la nouvelle Nomenclature
      select INIT_ID_SEQ.nextval
        into NewNomenclature_ID
        from dual;

      -- Copie de la nomenclature
      insert into PPS_NOMENCLATURE
                  (PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , C_TYPE_NOM
                 , NOM_TEXT
                 , NOM_REF_QTY
                 , NOM_VERSION
                 , C_REMPLACEMENT_NOM
                 , NOM_BEG_VALID
                 , NOM_DEFAULT
                 , FAL_SCHEDULE_PLAN_ID
                 , PPS_RANGE_ID
                 , DOC_RECORD_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewNomenclature_ID   -- PPS_NOMENCLATURE_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , C_TYPE_NOM
             , NOM_TEXT
             , NOM_REF_QTY
             , NOM_VERSION
             , C_REMPLACEMENT_NOM
             , NOM_BEG_VALID
             , NOM_DEFAULT
             , FAL_SCHEDULE_PLAN_ID
             , PPS_RANGE_ID
             , DOC_RECORD_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from PPS_NOMENCLATURE
         where PPS_NOMENCLATURE_ID = tplNomenclature_Info.PPS_NOMENCLATURE_ID;

      -- Copie les composants de la nomenclature
      insert into PPS_NOM_BOND
                  (PPS_NOM_BOND_ID
                 , PPS_NOMENCLATURE_ID
                 , PPS_RANGE_OPERATION_ID
                 , STM_LOCATION_ID
                 , GCO_GOOD_ID
                 , C_REMPLACEMENT_NOM
                 , C_TYPE_COM
                 , C_DISCHARGE_COM
                 , C_KIND_COM
                 , COM_SEQ
                 , COM_TEXT
                 , COM_RES_TEXT
                 , COM_RES_NUM
                 , COM_VAL
                 , COM_SUBSTITUT
                 , COM_POS
                 , COM_UTIL_COEFF
                 , COM_PDIR_COEFF
                 , COM_REC_PCENT
                 , COM_INTERVAL
                 , COM_BEG_VALID
                 , COM_END_VALID
                 , COM_REMPLACEMENT
                 , STM_STOCK_ID
                 , FAL_SCHEDULE_STEP_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , COM_REF_QTY
                 , COM_PERCENT_WASTE
                 , COM_FIXED_QUANTITY_WASTE
                 , COM_QTY_REFERENCE_LOSS
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- PPS_NOM_BOND_ID
             , NewNomenclature_ID   -- PPS_NOMENCLATURE_ID
             , PPS_RANGE_OPERATION_ID
             , STM_LOCATION_ID
             , GCO_GOOD_ID
             , C_REMPLACEMENT_NOM
             , C_TYPE_COM
             , C_DISCHARGE_COM
             , C_KIND_COM
             , COM_SEQ
             , COM_TEXT
             , COM_RES_TEXT
             , COM_RES_NUM
             , COM_VAL
             , COM_SUBSTITUT
             , COM_POS
             , COM_UTIL_COEFF
             , COM_PDIR_COEFF
             , COM_REC_PCENT
             , COM_INTERVAL
             , COM_BEG_VALID
             , COM_END_VALID
             , COM_REMPLACEMENT
             , STM_STOCK_ID
             , FAL_SCHEDULE_STEP_ID
             , PPS_PPS_NOMENCLATURE_ID
             , COM_REF_QTY
             , COM_PERCENT_WASTE
             , COM_FIXED_QUANTITY_WASTE
             , COM_QTY_REFERENCE_LOSS
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = tplNomenclature_Info.PPS_NOMENCLATURE_ID;
    end loop;
  end DuplicateGoodNomenclature;

  /**
  * Description : Duplication de la nomenclature de production
  */
  procedure DuplicateProdNomenclature(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor crNomenclature_Info(cGoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   *
          from PPS_NOMENCLATURE
         where GCO_GOOD_ID = cGoodID
           and C_TYPE_NOM = '2'
      order by NOM_DEFAULT desc;

    tplNomenclature_info PPS_NOMENCLATURE%rowtype;
    NewNomenclature_ID   PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    open crNomenclature_info(SourceGoodId);

    fetch crNomenclature_info
     into tplNomenclature_info;

    if crNomenclature_Info%found then
      -- id de la nouvelle Nomenclature
      select INIT_ID_SEQ.nextval
        into NewNomenclature_ID
        from dual;

      -- Copie de la nomenclature
      insert into PPS_NOMENCLATURE
                  (PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , C_TYPE_NOM
                 , NOM_TEXT
                 , NOM_REF_QTY
                 , NOM_VERSION
                 , C_REMPLACEMENT_NOM
                 , NOM_BEG_VALID
                 , NOM_DEFAULT
                 , FAL_SCHEDULE_PLAN_ID
                 , PPS_RANGE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewNomenclature_ID   -- PPS_NOMENCLATURE_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , C_TYPE_NOM
             , NOM_TEXT
             , NOM_REF_QTY
             , NOM_VERSION
             , C_REMPLACEMENT_NOM
             , NOM_BEG_VALID
             , NOM_DEFAULT
             , FAL_SCHEDULE_PLAN_ID
             , PPS_RANGE_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from PPS_NOMENCLATURE
         where PPS_NOMENCLATURE_ID = tplNomenclature_Info.PPS_NOMENCLATURE_ID;

      -- Copie les composants de la nomenclature
      insert into PPS_NOM_BOND
                  (PPS_NOM_BOND_ID
                 , PPS_NOMENCLATURE_ID
                 , PPS_RANGE_OPERATION_ID
                 , STM_LOCATION_ID
                 , GCO_GOOD_ID
                 , C_REMPLACEMENT_NOM
                 , C_TYPE_COM
                 , C_DISCHARGE_COM
                 , C_KIND_COM
                 , COM_SEQ
                 , COM_TEXT
                 , COM_RES_TEXT
                 , COM_RES_NUM
                 , COM_VAL
                 , COM_SUBSTITUT
                 , COM_POS
                 , COM_UTIL_COEFF
                 , COM_PDIR_COEFF
                 , COM_REC_PCENT
                 , COM_INTERVAL
                 , COM_BEG_VALID
                 , COM_END_VALID
                 , COM_REMPLACEMENT
                 , STM_STOCK_ID
                 , FAL_SCHEDULE_STEP_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , COM_REF_QTY
                 , COM_PERCENT_WASTE
                 , COM_FIXED_QUANTITY_WASTE
                 , COM_QTY_REFERENCE_LOSS
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- PPS_NOM_BOND_ID
             , NewNomenclature_ID   -- PPS_NOMENCLATURE_ID
             , PPS_RANGE_OPERATION_ID
             , STM_LOCATION_ID
             , GCO_GOOD_ID
             , C_REMPLACEMENT_NOM
             , C_TYPE_COM
             , C_DISCHARGE_COM
             , C_KIND_COM
             , COM_SEQ
             , COM_TEXT
             , COM_RES_TEXT
             , COM_RES_NUM
             , COM_VAL
             , COM_SUBSTITUT
             , COM_POS
             , COM_UTIL_COEFF
             , COM_PDIR_COEFF
             , COM_REC_PCENT
             , COM_INTERVAL
             , COM_BEG_VALID
             , COM_END_VALID
             , COM_REMPLACEMENT
             , STM_STOCK_ID
             , FAL_SCHEDULE_STEP_ID
             , PPS_PPS_NOMENCLATURE_ID
             , COM_REF_QTY
             , COM_PERCENT_WASTE
             , COM_FIXED_QUANTITY_WASTE
             , COM_QTY_REFERENCE_LOSS
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = tplNomenclature_Info.PPS_NOMENCLATURE_ID;
    end if;

    close crNomenclature_info;
  end DuplicateProdNomenclature;

  /**
  * Description : Duplication des liens sur les produits couplés
  */
  procedure DuplicateGoodCoupledGoods(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    -- Copie les liens des produits couplés
    insert into GCO_COUPLED_GOOD
                (GCO_COUPLED_GOOD_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , GCO_COMPL_DATA_MANUFACTURE_ID
               , GCG_REF_QUANTITY
               , GCG_QUANTITY
               , GCG_INCLUDE_GOOD
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_COUPLED_GOOD_ID
           , TargetGoodID
           , GCO_GCO_GOOD_ID
           , CMA_TRG.GCO_COMPL_DATA_MANUFACTURE_ID
           , GCG_REF_QUANTITY
           , GCG_QUANTITY
           , GCG_INCLUDE_GOOD
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_COUPLED_GOOD GCG
           , GCO_COMPL_DATA_MANUFACTURE CMA_SRC
           , GCO_COMPL_DATA_MANUFACTURE CMA_TRG
       where GCG.GCO_GOOD_ID = SourceGoodID
         and CMA_SRC.GCO_GOOD_ID = GCG.GCO_GOOD_ID
         and CMA_TRG.GCO_GOOD_ID = TargetGoodID
         and (    (CMA_SRC.DIC_FAB_CONDITION_ID = CMA_TRG.DIC_FAB_CONDITION_ID)
              or (     (CMA_SRC.DIC_FAB_CONDITION_ID is null)
                  and (CMA_TRG.DIC_FAB_CONDITION_ID is null) )
             );
  end DuplicateGoodCoupledGoods;

  /**
  * Description : Duplication des liens sur les homologations
  */
  procedure DuplicateGoodCertifications(
    SourceGoodID   in GCO_GOOD.GCO_GOOD_ID%type
  , TargetGoodID   in GCO_GOOD.GCO_GOOD_ID%type
  , CertifProperty in SQM_CERTIFICATION.C_CERTIFICATION_PROPERTY%type
  )
  is
  begin
    -- Copie les liens entre les homologations et ce produit
    insert into SQM_CERTIFICATION_S_GOOD
                (SQM_CERTIFICATION_ID
               , GCO_GOOD_ID
               , A_DATECRE
               , A_IDCRE
                )
      select CSG.SQM_CERTIFICATION_ID
           , TargetGoodID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from SQM_CERTIFICATION_S_GOOD CSG
           , SQM_CERTIFICATION CER
       where CSG.GCO_GOOD_ID = SourceGoodID
         and CSG.SQM_CERTIFICATION_ID = CER.SQM_CERTIFICATION_ID
         and CER.C_CERTIFICATION_PROPERTY = CertifProperty;
  end DuplicateGoodCertifications;

  /**
  * Description : Duplication des Outils
  */
  procedure DuplicateGoodSpecialTools(SourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor crSpecialTool_Info(cGoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select *
        from PPS_SPECIAL_TOOLS
       where GCO_GOOD_ID = cGoodID;
--    NewSpecialTool_ID PPS_SPECIAL_TOOLS.PPS_SPECIAL_TOOLS_ID%TYPE;
  begin
    for tplSpecialTool_Info in crSpecialTool_Info(SourceGoodID) loop
      -- Copie les outils spéciaux
      insert into PPS_SPECIAL_TOOLS
                  (PPS_SPECIAL_TOOLS_ID
                 , GCO_GOOD_ID
                 , C_TOOLS_STATUS
                 , SPT_REFERENCE
                 , SPT_DURATION
                 , SPT_THRESHOLD_SERVICING
                 , SPT_THRESHOLD_RENEW
                 , SPT_BALANCE
                 , SPT_USE
                 , SPT_INTO_SERVICE_DATE
                 , SPT_RENEW_NOTIFICATION_DATE
                 , SPT_COST
                 , SPT_RATE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- PPS_SPECIAL_TOOLS_ID
             , TargetGoodID   -- GCO_GOOD_ID
             , C_TOOLS_STATUS
             , SPT_REFERENCE
             , SPT_DURATION
             , SPT_THRESHOLD_SERVICING
             , SPT_THRESHOLD_RENEW
             , SPT_DURATION   -- SPT_BALANCE outil pas encore utilisé
             , 0   -- SPT_USE outil pas encore utilisé
             , SPT_INTO_SERVICE_DATE
             , SPT_RENEW_NOTIFICATION_DATE
             , SPT_COST
             , SPT_RATE
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from PPS_SPECIAL_TOOLS
         where PPS_SPECIAL_TOOLS_ID = tplSpecialTool_Info.PPS_SPECIAL_TOOLS_ID;
    end loop;
  end DuplicateGoodSpecialTools;

  procedure LinkComplDataManufacture(TargetGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    vNomencldId PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    begin
      select nom.PPS_NOMENCLATURE_ID
        into vNomencldId
        from PPS_NOMENCLATURE nom
       where nom.C_TYPE_NOM = '2'
         and nom.NOM_DEFAULT = 1
         and nom.GCO_GOOD_ID = TargetGoodID;
    exception
      when no_data_found then
        vNomencldId  := null;
    end;

    if nvl(vNomencldId, 0) <> 0 then
      update GCO_COMPL_DATA_MANUFACTURE
         set PPS_NOMENCLATURE_ID = vNomencldId
       where GCO_GOOD_ID = TargetGoodID;
    end if;
  end LinkComplDataManufacture;

  /**
  * Description : Méthode générale pour la duplication d'un produit
  */
  procedure DuplicateProduct(
    SourceGoodID            in     GCO_GOOD.GCO_GOOD_ID%type
  , NewMajorRef             in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , NewSecRef               in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , NewShortDescr           in     GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type default null
  , NewLongDescr            in     GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type default null
  , NewFreeDescr            in     GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type default null
  , NewGoodID               in out GCO_GOOD.GCO_GOOD_ID%type
  , DuplicateStock          in     integer default 0
  , DuplicateInventory      in     integer default 0
  , DuplicatePurchase       in     integer default 0
  , DuplicateSale           in     integer default 0
  , DuplicateSAV            in     integer default 0
  , DuplicateExternalASA    in     integer default 0
  , DuplicateManufacture    in     integer default 0
  , DuplicateSubcontract    in     integer default 0
  , DuplicateAttributes     in     integer default 0
  , DuplicateDistribution   in     integer default 0
  , DuplicateTool           in     integer default 0
  , DuplicateNomenclature   in     integer default 0
  , DuplicateCoupledGoods   in     integer default 0
  , DuplicateCertifications in     integer default 0
  , DuplicatePRF            in     integer default 0
  , DuplicatePRC            in     integer default 0
  , DuplicateTariff         in     integer default 0
  , DuplicateDiscount       in     integer default 0
  , DuplicateCharge         in     integer default 0
  , DuplicateFreeData       in     integer default 0
  , DuplicateVirtualFields  in     integer default 0
  , DuplicatePreciousMat    in     integer default 0
  , DuplicateSpecialTools   in     integer default 0
  , DuplicateCorrelation    in     integer default 0
  , aProductGeneratorMode   in     integer default 0
  )
  is
    vEANError     varchar2(3);
    vHIBC         GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
    vAutoMajorRef GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
    --  1. Duplication des données de la table GCO_GOOD
    --  2. Duplication des données de la table GCO_PRODUCT
    --  3. Duplication des descriptions
    --  4. Duplication des caractérisations
    --  5. Duplication des données complémentaires de stock
    --  6. Duplication des données complémentaires d'inventaire
    --  7. Duplication des données complémentaires d'achat
    --    7.1 Duplication des liens d'homologation achat
    --  8. Duplication des données complémentaires de vente
    --  9. Duplication des données complémentaires du SAV
    -- 10. Duplication des données complémentaires du SAV externe
    -- 11. Duplication des données complémentaires de fabrication
    --   11.1 Duplication des produits couplés
    --   11.2 Duplication des liens d'homologation
    -- 12. Duplication des données complémentaires de Sous-Traitance
    -- 13. Duplication des données complémentaires de disribution
    -- 14. Duplication des données complémentaires des attributs
    -- 15. Duplication des données de l'outil
    --   15.1 Duplication des outils spéciaux
    -- 16. Duplication des corrélations
    -- 17. Duplication de l'imputation comptable Document
    -- 18. Duplication de l'imputation comptable Stock
    -- 19. Duplication des Taxes et TVA
    -- 20. Duplication des Données libres
    -- 21. Duplication des Mesures et poids
    -- 22. Duplication des Matières
    -- 23. Duplication des Elements de douane
    -- 24. Duplication des Tarifs
    -- 25. Duplication des PRC
    -- 26. Duplication des PRF
    -- 27. Duplication des Remises
    -- 28. Duplication des Taxes
    -- 29. Duplication des champs virtuels
    -- 30. Duplication des Matières précieuses
    -- 31. Duplication des Nomenclatures
    -- 32. Génération des codes EAN

    -- Recherche l'ID du nouveau bien s'il n'as pas été passé en paramètre
    select decode(nvl(NewGoodID, 0), 0, INIT_ID_SEQ.nextval, NewGoodID)
      into NewGoodID
      from dual;

    -- 1. Duplication des données de la table GCO_GOOD
    insert into GCO_GOOD
                (GCO_GOOD_ID
               , GOO_MAJOR_REFERENCE
               , C_GOOD_STATUS
               , GCO_SUBSTITUTION_LIST_ID
               , DIC_UNIT_OF_MEASURE_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , GCO_MULTIMEDIA_ELEMENT_ID
               , GCO_GOOD_CATEGORY_ID
               , DIC_GOOD_LINE_ID
               , DIC_GOOD_FAMILY_ID
               , DIC_GOOD_MODEL_ID
               , DIC_GOOD_GROUP_ID
               , DIC_PTC_GOOD_GROUP_ID
               , C_MANAGEMENT_MODE
               , GOO_SECONDARY_REFERENCE
               , GOO_EAN_CODE
               , GOO_HIBC_REFERENCE
               , GOO_HIBC_PRIMARY_CODE
               , GOO_CCP_MANAGEMENT
               , GOO_NUMBER_OF_DECIMAL
               , GCO_DATA_PURCHASE
               , GCO_DATA_SALE
               , GCO_DATA_STOCK
               , GCO_DATA_INVENTORY
               , GCO_DATA_MANUFACTURE
               , GCO_DATA_SUBCONTRACT
               , GCO_DATA_SAV
               , GCO_GOOD_OLE_OBJECT
               , DIC_PUR_TARIFF_STRUCT_ID
               , DIC_SALE_TARIFF_STRUCT_ID
               , DIC_TARIFF_SET_SALE_ID
               , DIC_TARIFF_SET_PURCHASE_ID
               , DIC_COMMISSIONING_ID
               , GOO_INNOVATION_FROM
               , GOO_INNOVATION_TO
               , GOO_STD_PERCENT_WASTE
               , GOO_STD_FIXED_QUANTITY_WASTE
               , GOO_STD_QTY_REFERENCE_LOSS
               , DIC_GCO_STATISTIC_1_ID
               , DIC_GCO_STATISTIC_2_ID
               , DIC_GCO_STATISTIC_3_ID
               , DIC_GCO_STATISTIC_4_ID
               , DIC_GCO_STATISTIC_5_ID
               , DIC_GCO_STATISTIC_6_ID
               , DIC_GCO_STATISTIC_7_ID
               , DIC_GCO_STATISTIC_8_ID
               , DIC_GCO_STATISTIC_9_ID
               , DIC_GCO_STATISTIC_10_ID
               , GCO_PRODUCT_GROUP_ID
               , GOO_PRECIOUS_MAT
               , GOO_TO_PUBLISH
               , C_GOO_WEB_STATUS
               , GOO_WEB_VISUAL_LEVEL
               , GOO_WEB_ORDERABILITY_LEVEL
               , GOO_WEB_CAN_BE_ORDERED
               , DIC_GOO_WEB_CATEG1_ID
               , DIC_GOO_WEB_CATEG2_ID
               , DIC_GOO_WEB_CATEG3_ID
               , DIC_GOO_WEB_CATEG4_ID
               , GOO_WEB_PUBLISHED
               , GOO_WEB_ALIAS
               , GOO_WEB_PICTURE_URL
               , GOO_WEB_ATTACHEMENT_URL
               , GOO_UNSPSC
               , DIC_SET_TYPE_ID
               , C_SERVICE_KIND
               , C_SERVICE_RENEWAL
               , C_SERVICE_GOOD_LINK
               , A_DATECRE
               , A_IDCRE
                )
      select NewGoodID   -- GCO_GOOD_ID
           , NewMajorRef   -- GOO_MAJOR_REFERENCE
           , decode(nvl(PCS.PC_CONFIG.GETCONFIG('GCO_INACTIVE_CREATION_GOOD'), '0'), '0', '2', '1')
           , GCO_SUBSTITUTION_LIST_ID
           , DIC_UNIT_OF_MEASURE_ID
           , DIC_ACCOUNTABLE_GROUP_ID
           , GCO_MULTIMEDIA_ELEMENT_ID
           , GCO_GOOD_CATEGORY_ID
           , DIC_GOOD_LINE_ID
           , DIC_GOOD_FAMILY_ID
           , DIC_GOOD_MODEL_ID
           , DIC_GOOD_GROUP_ID
           , DIC_PTC_GOOD_GROUP_ID
           , C_MANAGEMENT_MODE
           , NewSecRef   -- GOO_SECONDARY_REFERENCE
           , null   -- GOO_EAN_CODE
           , null   -- GOO_HIBC_REFERENCE
           , null   -- GOO_HIBC_PRIMARY_CODE
           , GOO_CCP_MANAGEMENT
           , GOO_NUMBER_OF_DECIMAL
           , DuplicatePurchase   -- GCO_DATA_PURCHASE
           , DuplicateSale   -- GCO_DATA_SALE
           , DuplicateStock   -- GCO_DATA_STOCK
           , DuplicateInventory   -- GCO_DATA_INVENTORY
           , DuplicateManufacture   -- GCO_DATA_MANUFACTURE
           , DuplicateSubcontract   -- GCO_DATA_SUBCONTRACT
           , DuplicateSAV   -- GCO_DATA_SAV
           , null   -- GCO_GOOD_OLE_OBJECT
           , DIC_PUR_TARIFF_STRUCT_ID
           , DIC_SALE_TARIFF_STRUCT_ID
           , DIC_TARIFF_SET_SALE_ID
           , DIC_TARIFF_SET_PURCHASE_ID
           , DIC_COMMISSIONING_ID
           , GOO_INNOVATION_FROM
           , GOO_INNOVATION_TO
           , GOO_STD_PERCENT_WASTE
           , GOO_STD_FIXED_QUANTITY_WASTE
           , GOO_STD_QTY_REFERENCE_LOSS
           , DIC_GCO_STATISTIC_1_ID
           , DIC_GCO_STATISTIC_2_ID
           , DIC_GCO_STATISTIC_3_ID
           , DIC_GCO_STATISTIC_4_ID
           , DIC_GCO_STATISTIC_5_ID
           , DIC_GCO_STATISTIC_6_ID
           , DIC_GCO_STATISTIC_7_ID
           , DIC_GCO_STATISTIC_8_ID
           , DIC_GCO_STATISTIC_9_ID
           , DIC_GCO_STATISTIC_10_ID
           , GCO_PRODUCT_GROUP_ID
           , decode(DuplicatePreciousMat, 1, GOO_PRECIOUS_MAT, 0)   -- GOO_PRECIOUS_MAT
           , GOO_TO_PUBLISH
           , case GOO_WEB_PUBLISHED
               when 1 then '1'
               else '0'
             end C_GOO_WEB_STATUS
           , GOO_WEB_VISUAL_LEVEL
           , GOO_WEB_ORDERABILITY_LEVEL
           , GOO_WEB_CAN_BE_ORDERED
           , DIC_GOO_WEB_CATEG1_ID
           , DIC_GOO_WEB_CATEG2_ID
           , DIC_GOO_WEB_CATEG3_ID
           , DIC_GOO_WEB_CATEG4_ID
           , GOO_WEB_PUBLISHED
           , GOO_WEB_ALIAS
           , GOO_WEB_PICTURE_URL
           , GOO_WEB_ATTACHEMENT_URL
           , GOO_UNSPSC
           , DIC_SET_TYPE_ID
           , C_SERVICE_KIND
           , C_SERVICE_RENEWAL
           , C_SERVICE_GOOD_LINK
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_GOOD
       where GCO_GOOD_ID = SourceGoodID;

/*
    --1b. Données bien calculées maj par trigger (GCO_GOOD_CALC_DATA)
*/

    -- 2. Duplication des données de la table GCO_PRODUCT
    insert into GCO_PRODUCT
                (GCO_GOOD_ID
               , C_SUPPLY_MODE
               , PDT_MULTI_SOURCING
               , C_SUPPLY_TYPE
               , GCO_GCO_SERVICE_ID
               , C_PRODUCT_TYPE
               , PDT_STOCK_MANAGEMENT
               , PDT_THRESHOLD_MANAGEMENT
               , PDT_STOCK_OBTAIN_MANAGEMENT
               , PDT_CALC_REQUIREMENT_MNGMENT
               , STM_LOCATION_ID
               , STM_STOCK_ID
               , PDT_CONTINUOUS_INVENTAR
               , PDT_FULL_TRACABILITY
               , DIC_UNIT_OF_MEASURE_ID
               , DIC_UNIT_OF_MEASURE1_ID
               , DIC_UNIT_OF_MEASURE2_ID
               , PDT_ALTERNATIVE_QUANTITY_1
               , PDT_ALTERNATIVE_QUANTITY_2
               , PDT_ALTERNATIVE_QUANTITY_3
               , PDT_CONVERSION_FACTOR_1
               , PDT_CONVERSION_FACTOR_2
               , PDT_CONVERSION_FACTOR_3
               , C_PRODUCT_DELIVERY_TYP
               , DIC_DEL_TYP_EXPLAIN_ID
               , PDT_PIC
               , PDT_FACT_STOCK
               , PAC_SUPPLIER_PARTNER_ID
               , PDT_BLOCK_EQUI
               , PDT_GUARANTY_USE
               , GCO2_GCO_GOOD_ID
               , PDT_END_LIFE
               , PDT_MARK_USED
               , PDT_MARK_NOMENCLATURE
               , PDT_STOCK_ALLOC_BATCH
               , PDT_SCALE_LINK
               , PDT_FULL_TRACABILITY_COEF
               , PDT_FULL_TRACABILITY_SUPPLY
               , PDT_FULL_TRACABILITY_RULE
                )
      select NewGoodID
           , C_SUPPLY_MODE
           , PDT_MULTI_SOURCING
           , C_SUPPLY_TYPE
           , GCO_GCO_SERVICE_ID
           , C_PRODUCT_TYPE
           , PDT_STOCK_MANAGEMENT
           , PDT_THRESHOLD_MANAGEMENT
           , PDT_STOCK_OBTAIN_MANAGEMENT
           , PDT_CALC_REQUIREMENT_MNGMENT
           , STM_LOCATION_ID
           , STM_STOCK_ID
           , PDT_CONTINUOUS_INVENTAR
           , PDT_FULL_TRACABILITY
           , DIC_UNIT_OF_MEASURE_ID
           , DIC_UNIT_OF_MEASURE1_ID
           , DIC_UNIT_OF_MEASURE2_ID
           , PDT_ALTERNATIVE_QUANTITY_1
           , PDT_ALTERNATIVE_QUANTITY_2
           , PDT_ALTERNATIVE_QUANTITY_3
           , PDT_CONVERSION_FACTOR_1
           , PDT_CONVERSION_FACTOR_2
           , PDT_CONVERSION_FACTOR_3
           , C_PRODUCT_DELIVERY_TYP
           , DIC_DEL_TYP_EXPLAIN_ID
           , PDT_PIC
           , PDT_FACT_STOCK
           , PAC_SUPPLIER_PARTNER_ID
           , PDT_BLOCK_EQUI
           , PDT_GUARANTY_USE
           , GCO2_GCO_GOOD_ID
           , PDT_END_LIFE
           , PDT_MARK_USED
           , PDT_MARK_NOMENCLATURE
           , PDT_STOCK_ALLOC_BATCH
           , PDT_SCALE_LINK
           , PDT_FULL_TRACABILITY_COEF
           , PDT_FULL_TRACABILITY_SUPPLY
           , PDT_FULL_TRACABILITY_RULE
        from GCO_PRODUCT
       where GCO_GOOD_ID = SourceGoodID;

    -- 3. Duplication des descriptions
    DuplicateGoodDescription(SourceGoodID    => SourceGoodID
                           , TargetGoodID    => NewGoodID
                           , NewShortDescr   => NewShortDescr
                           , NewLongDescr    => NewLongDescr
                           , NewFreeDescr    => NewFreeDescr
                            );
    -- 4. Duplication des caractérisations
    DuplicateGoodCaracterization(SourceGoodID, NewGoodID);

    -- 5. Duplication des données complémentaires de stock
    if DuplicateStock = 1 then
      DuplicateGoodDataStock(SourceGoodID, NewGoodID);
    end if;

    -- 6. Duplication des données complémentaires d'inventaire
    if DuplicateInventory = 1 then
      DuplicateGoodDataInventory(SourceGoodID, NewGoodID);
    end if;

    -- 7. Duplication des données complémentaires d'achat
    if DuplicatePurchase = 1 then
      DuplicateGoodDataPurchase(SourceGoodID, NewGoodID);

      -- 7.1 Duplication des liens d'homologation achat
      if DuplicateCertifications = 1 then
        DuplicateGoodCertifications(SourceGoodID, NewGoodID, '1');
      end if;
    end if;

    -- 8. Duplication des données complémentaires de vente
    if DuplicateSale = 1 then
      DuplicateGoodDataSale(SourceGoodID, NewGoodID);
    end if;

    -- 9. Duplication des données complémentaires du SAV
    if DuplicateSAV = 1 then
      DuplicateGoodDataSAV(SourceGoodID, NewGoodID);
    end if;

    -- 10. Duplication des données complémentaires du SAV externe
    if DuplicateExternalASA = 1 then
      DuplicateGoodDataExtASA(SourceGoodID, NewGoodID);
    end if;

    -- 11. Duplication des données complémentaires de fabrication
    if DuplicateManufacture = 1 then
      DuplicateGoodDataManufacture(SourceGoodID, NewGoodID);

      -- 11.1 Duplication des produits couplés
      if DuplicateCoupledGoods = 1 then
        DuplicateGoodCoupledGoods(SourceGoodID, NewGoodID);
      end if;

      -- 11.2 Duplication des liens d'homologation fabrication
      if DuplicateCertifications = 1 then
        DuplicateGoodCertifications(SourceGoodID, NewGoodID, '0');
      end if;
    end if;

    -- 12. Duplication des données complémentaires de Sous-Traitance
    if DuplicateSubcontract = 1 then
      DuplicateGoodDataSubcontract(SourceGoodID, NewGoodID);
    end if;

    -- 13. Duplication des données complémentaires de disribution
    if DuplicateDistribution = 1 then
      DuplicateGoodDataDistrib(SourceGoodID, NewGoodID);
    end if;

    -- 14. Duplication des données complémentaires des attributs
    if DuplicateAttributes = 1 then
      DuplicateGoodAttr(SourceGoodID, NewGoodID);
    end if;

    -- 15. Duplication des données de l'outil
    if DuplicateTool = 1 then
      DuplicateGoodDataTool(SourceGoodID, NewGoodID);

      -- 15.1 Duplication des Outils spéciaux
      if DuplicateSpecialTools = 1 then
        DuplicateGoodSpecialTools(SourceGoodID, NewGoodID);
      end if;
    end if;

    -- 16. Duplication des corrélations
    if DuplicateCorrelation = 1 then
      DuplicateGoodConnection(SourceGoodID, NewGoodID);
    end if;

    -- 17. Duplication de l'imputation comptable Document
    DuplicateGoodDocImputation(SourceGoodID, NewGoodID);

    -- 18. Duplication de l'imputation comptable Stock
    insert into GCO_IMPUT_STOCK
                (GCO_IMPUT_STOCK_ID
               , GCO_GOOD_ID
               , STM_MOVEMENT_KIND_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_IMPUT_STOCK_ID
           , NewGoodID   -- GCO_GOOD_ID
           , STM_MOVEMENT_KIND_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_IMPUT_STOCK
       where GCO_GOOD_ID = SourceGoodID;

    -- 19. Duplication des Taxes et TVA
    DuplicateGoodVAT(SourceGoodID, NewGoodID);

    -- 20. Duplication des Données libres
    if DuplicateFreeData = 1 then
      DuplicateGoodFreeData(SourceGoodID, NewGoodID);
    end if;

    -- 21. Duplication des Mesures et poids
    insert into GCO_MEASUREMENT_WEIGHT
                (GCO_MEASUREMENT_WEIGHT_ID
               , GCO_GOOD_ID
               , DIC_SHAPE_TYPE_ID
               , MEA_NET_HEIGHT
               , MEA_NET_LENGTH
               , MEA_NET_DEPTH
               , MEA_NET_WEIGHT
               , MEA_NET_VOLUME
               , MEA_NET_SURFACE
               , MEA_GROSS_HEIGHT
               , MEA_GROSS_LENGTH
               , MEA_GROSS_DEPTH
               , MEA_GROSS_WEIGHT
               , MEA_GROSS_VOLUME
               , MEA_GROSS_SURFACE
               , MEA_NET_MANAGEMENT
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_MEASUREMENT_WEIGHT_ID
           , NewGoodID   -- GCO_GOOD_ID
           , DIC_SHAPE_TYPE_ID
           , MEA_NET_HEIGHT
           , MEA_NET_LENGTH
           , MEA_NET_DEPTH
           , MEA_NET_WEIGHT
           , MEA_NET_VOLUME
           , MEA_NET_SURFACE
           , MEA_GROSS_HEIGHT
           , MEA_GROSS_LENGTH
           , MEA_GROSS_DEPTH
           , MEA_GROSS_WEIGHT
           , MEA_GROSS_VOLUME
           , MEA_GROSS_SURFACE
           , MEA_NET_MANAGEMENT
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_MEASUREMENT_WEIGHT
       where GCO_GOOD_ID = SourceGoodID;

    -- 22. Duplication des Matières
    insert into GCO_MATERIAL
                (GCO_MATERIAL_ID
               , GCO_GOOD_ID
               , DIC_UNIT_OF_MEASURE_ID
               , DIC_MATERIAL_KIND_ID
               , MAT_MATERIAL_WEIGHT
               , MAT_GEM_NUMBER
               , MAT_COMMENT
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_MATERIAL_ID
           , NewGoodID   -- GCO_GOOD_ID
           , DIC_UNIT_OF_MEASURE_ID
           , DIC_MATERIAL_KIND_ID
           , MAT_MATERIAL_WEIGHT
           , MAT_GEM_NUMBER
           , MAT_COMMENT
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_MATERIAL
       where GCO_GOOD_ID = SourceGoodID;

    -- 23. Duplication des Elements de douane
    insert into GCO_CUSTOMS_ELEMENT
                (GCO_CUSTOMS_ELEMENT_ID
               , GCO_GOOD_ID
               , PC_CNTRY_ID
               , CUS_CUSTONS_POSITION
               , CUS_TRANSPORT_INFORMATION
               , DIC_REPAYMENT_CODE_ID
               , DIC_SUBJUGATED_LICENCE_ID
               , CUS_KEY_TARIFF
               , CUS_LICENCE_NUMBER
               , CUS_RATE_FOR_VALUE
               , PC_ORIGIN_PC_CNTRY_ID
               , DIC_UNIT_OF_MEASURE_ID
               , CUS_CONVERSION_FACTOR
               , C_CUSTOMS_ELEMENT_TYPE
               , CUS_COMMISSION_RATE
               , CUS_CHARGE_RATE
               , CUS_EXCISE_RATE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_CUSTOMS_ELEMENT_ID
           , NewGoodID   -- GCO_GOOD_ID
           , PC_CNTRY_ID
           , CUS_CUSTONS_POSITION
           , CUS_TRANSPORT_INFORMATION
           , DIC_REPAYMENT_CODE_ID
           , DIC_SUBJUGATED_LICENCE_ID
           , CUS_KEY_TARIFF
           , CUS_LICENCE_NUMBER
           , CUS_RATE_FOR_VALUE
           , PC_ORIGIN_PC_CNTRY_ID
           , DIC_UNIT_OF_MEASURE_ID
           , CUS_CONVERSION_FACTOR
           , C_CUSTOMS_ELEMENT_TYPE
           , CUS_COMMISSION_RATE
           , CUS_CHARGE_RATE
           , CUS_EXCISE_RATE
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_CUSTOMS_ELEMENT
       where GCO_GOOD_ID = SourceGoodID;

    -- 24. Duplication des Tarifs
    if DuplicateTariff = 1 then
      DuplicateGoodTariff(SourceGoodID, NewGoodID);
    end if;

    -- 25. Duplication des PRC
    if DuplicatePRC = 1 then
      DuplicateGoodPRC(SourceGoodID, NewGoodID);
    end if;

    -- 26. Duplication des PRF
    if DuplicatePRF = 1 then
      DuplicateGoodPRF(SourceGoodID, NewGoodID);
    end if;

    -- 27. Duplication des Remises
    if DuplicateDiscount = 1 then
      insert into PTC_DISCOUNT_S_GOOD
                  (GCO_GOOD_ID
                 , PTC_DISCOUNT_ID
                  )
        select NewGoodID   -- GCO_GOOD_ID
             , DNT.PTC_DISCOUNT_ID
          from PTC_DISCOUNT_S_GOOD PDG
             , PTC_DISCOUNT DNT
         where PDG.GCO_GOOD_ID = SourceGoodID
           and PDG.PTC_DISCOUNT_ID = DNT.PTC_DISCOUNT_ID
           and DNT.C_GOODRELATION_TYPE = '2';
    end if;

    -- 28. Duplication des Taxes
    if DuplicateCharge = 1 then
      insert into PTC_CHARGE_S_GOODS
                  (GCO_GOOD_ID
                 , PTC_CHARGE_ID
                  )
        select NewGoodID   -- GCO_GOOD_ID
             , CRG.PTC_CHARGE_ID
          from PTC_CHARGE_S_GOODS PCG
             , PTC_CHARGE CRG
         where PCG.GCO_GOOD_ID = SourceGoodID
           and PCG.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
           and CRG.C_GOODRELATION_TYPE = '2';
    end if;

    -- 29. Duplication des champs virtuels
    if DuplicateVirtualFields = 1 then
      COM_VFIELDS.DuplicateVirtualField('GCO_GOOD', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                        SourceGoodID, NewGoodID);
    end if;

    -- 30. Duplication des matières précieuses
    if DuplicatePreciousMat = 1 then
      DuplicateGoodPreciousMat(SourceGoodID, NewGoodID);
    end if;

    -- 31. Duplication des Nomenclatures
    if DuplicateNomenclature = 1 then
      DuplicateGoodNomenclature(SourceGoodID, NewGoodID);
    end if;

    -- 32. Génération des codes EAN/UCC14 et HIBC
    GCO_BARCODE_FUNCTIONS.GenerateEAN_UCC14(0, NewGoodId, 0, vEANError);
    GCO_BARCODE_FUNCTIONS.GenerateAllEAN(NewGoodID);
    GCO_BARCODE_FUNCTIONS.GenerateHIBC(NewGoodId, vHIBC, vEANError);

    -- mise à jour éventuelle du lien sur la nomenclature de fabrication par
    -- défaut dans les données complémentaires de fabrication
    if     DuplicateNomenclature = 1
       and DuplicateManufacture = 1 then
      LinkComplDataManufacture(NewGoodID);
    end if;

    -- Test si les 6 premiers caractères de NewMajorRef sont "_TEMP_",
    -- càd si c'est une référence temporaire qui sera modifié
    -- (par une génération automatique) lors de la validation du produit
    if     aProductGeneratorMode = 0
       and not(    length(NewMajorRef) >= 6
               and NewMajorRef like '%' || PCS.PC_FUNCTIONS.TranslateWord('Automatique') || '_%') then
      -- Mise à jour de la référence principale si Numérotation automatique
      GCO_GOOD_NUMBERING_FUNCTIONS.GetNumber(NewGoodID, 'GCO_GOOD_CATEGORY', vAutoMajorRef);

      if vAutoMajorRef is not null then
        update GCO_GOOD
           set GOO_MAJOR_REFERENCE = vAutoMajorRef
         where GCO_GOOD_ID = NewGoodID;
      end if;
    end if;
  end DuplicateProduct;

  /**
  * Description : Méthode générale pour la duplication d'un service
  */
  procedure DuplicateService(
    SourceGoodID           in     GCO_GOOD.GCO_GOOD_ID%type
  , NewMajorRef            in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , NewSecRef              in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , NewGoodID              in out GCO_GOOD.GCO_GOOD_ID%type
  , DuplicatePurchase      in     integer
  , DuplicateSale          in     integer
  , DuplicateCML           in     integer
  , DuplicatePRF           in     integer
  , DuplicateTariff        in     integer
  , DuplicateFreeData      in     integer
  , DuplicateVirtualFields in     integer
  , DuplicatePreciousMat   in     integer
  )
  is
    vAutoMajorRef GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
    --  1. Duplication des données de la table GCO_GOOD
    --  2. Insertion dans la table GCO_SERVICE
    --  3. Duplication des Taxes et TVA
    --  4. Duplication des Données libres
    --  5. Duplication des données complémentaires d'achat
    --  6. Duplication des données complémentaires de vente
    --  7. Duplication des descriptions
    --  8. Duplication des corrélations
    --  9. Duplication des contrats
    -- 10. Duplication des ressources
    -- 11. Duplication de l'imputation comptable Document
    -- 12. Duplication des PRC
    -- 13. Duplication des Tarifs
    -- 14. Duplication des champs virtuels
    -- 15. Génération du code EAN du bien
    -- 16. Génération du code EAN pour les données compl. d'achat
    -- 17. Génération du code EAN pour les données compl. de vente
    -- 18. Duplication des matières précieuses
    -- 19. Duplication des données de prestation

    -- Recherche l'ID du nouveau bien s'il n'as pas été passé en paramètre
    select decode(nvl(NewGoodID, 0), 0, INIT_ID_SEQ.nextval, NewGoodID)
      into NewGoodID
      from dual;

    -- 1. Duplication des données de la table GCO_GOOD
    insert into GCO_GOOD
                (GCO_GOOD_ID
               , GOO_MAJOR_REFERENCE
               , C_GOOD_STATUS
               , GCO_SUBSTITUTION_LIST_ID
               , DIC_UNIT_OF_MEASURE_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , GCO_MULTIMEDIA_ELEMENT_ID
               , GCO_GOOD_CATEGORY_ID
               , DIC_GOOD_LINE_ID
               , DIC_GOOD_FAMILY_ID
               , DIC_GOOD_MODEL_ID
               , DIC_GOOD_GROUP_ID
               , DIC_PTC_GOOD_GROUP_ID
               , C_MANAGEMENT_MODE
               , GOO_SECONDARY_REFERENCE
               , GOO_EAN_CODE
               , GOO_CCP_MANAGEMENT
               , GOO_NUMBER_OF_DECIMAL
               , GCO_DATA_PURCHASE
               , GCO_DATA_SALE
               , GCO_DATA_STOCK
               , GCO_DATA_INVENTORY
               , GCO_DATA_MANUFACTURE
               , GCO_DATA_SUBCONTRACT
               , GCO_DATA_SAV
               , DIC_PUR_TARIFF_STRUCT_ID
               , DIC_SALE_TARIFF_STRUCT_ID
               , DIC_COMMISSIONING_ID
               , GOO_INNOVATION_FROM
               , GOO_INNOVATION_TO
               , GOO_STD_PERCENT_WASTE
               , GOO_STD_FIXED_QUANTITY_WASTE
               , GOO_STD_QTY_REFERENCE_LOSS
               , DIC_GCO_STATISTIC_1_ID
               , DIC_GCO_STATISTIC_2_ID
               , DIC_GCO_STATISTIC_3_ID
               , DIC_GCO_STATISTIC_4_ID
               , DIC_GCO_STATISTIC_5_ID
               , DIC_GCO_STATISTIC_6_ID
               , DIC_GCO_STATISTIC_7_ID
               , DIC_GCO_STATISTIC_8_ID
               , DIC_GCO_STATISTIC_9_ID
               , DIC_GCO_STATISTIC_10_ID
               , GCO_PRODUCT_GROUP_ID
               , GOO_PRECIOUS_MAT
               , C_SERVICE_RENEWAL
               , C_SERVICE_GOOD_LINK
               , DIC_TARIFF_ID
               , GOO_CONTRACT_CONDITION
               , C_SERVICE_KIND
               , A_DATECRE
               , A_IDCRE
                )
      select NewGoodID   -- GCO_GOOD_ID
           , NewMajorRef   -- GOO_MAJOR_REFERENCE
           , decode(nvl(PCS.PC_CONFIG.GETCONFIG('GCO_INACTIVE_CREATION_GOOD'), '0'), '0', '2', '1')
           , GCO_SUBSTITUTION_LIST_ID
           , DIC_UNIT_OF_MEASURE_ID
           , DIC_ACCOUNTABLE_GROUP_ID
           , GCO_MULTIMEDIA_ELEMENT_ID
           , GCO_GOOD_CATEGORY_ID
           , DIC_GOOD_LINE_ID
           , DIC_GOOD_FAMILY_ID
           , DIC_GOOD_MODEL_ID
           , DIC_GOOD_GROUP_ID
           , DIC_PTC_GOOD_GROUP_ID
           , C_MANAGEMENT_MODE
           , NewSecRef   -- GOO_SECONDARY_REFERENCE
           , null   -- GOO_EAN_CODE
           , GOO_CCP_MANAGEMENT
           , GOO_NUMBER_OF_DECIMAL
           , DuplicatePurchase   -- GCO_DATA_PURCHASE
           , DuplicateSale   -- GCO_DATA_SALE
           , 0   -- GCO_DATA_STOCK
           , 0   -- GCO_DATA_INVENTORY
           , 0   -- GCO_DATA_MANUFACTURE
           , 0   -- GCO_DATA_SUBCONTRACT
           , 0   -- GCO_DATA_SAV
           , DIC_PUR_TARIFF_STRUCT_ID
           , DIC_SALE_TARIFF_STRUCT_ID
           , DIC_COMMISSIONING_ID
           , GOO_INNOVATION_FROM
           , GOO_INNOVATION_TO
           , GOO_STD_PERCENT_WASTE
           , GOO_STD_FIXED_QUANTITY_WASTE
           , GOO_STD_QTY_REFERENCE_LOSS
           , DIC_GCO_STATISTIC_1_ID
           , DIC_GCO_STATISTIC_2_ID
           , DIC_GCO_STATISTIC_3_ID
           , DIC_GCO_STATISTIC_4_ID
           , DIC_GCO_STATISTIC_5_ID
           , DIC_GCO_STATISTIC_6_ID
           , DIC_GCO_STATISTIC_7_ID
           , DIC_GCO_STATISTIC_8_ID
           , DIC_GCO_STATISTIC_9_ID
           , DIC_GCO_STATISTIC_10_ID
           , GCO_PRODUCT_GROUP_ID
           , decode(DuplicatePreciousMat, 1, GOO_PRECIOUS_MAT, 0)   -- GOO_PRECIOUS_MAT
           , decode(DuplicateCML, 1, C_SERVICE_RENEWAL, null)
           , decode(DuplicateCML, 1, C_SERVICE_GOOD_LINK, null)
           , decode(DuplicateCML, 1, DIC_TARIFF_ID, null)
           , decode(DuplicateCML, 1, GOO_CONTRACT_CONDITION, null)
           , decode(DuplicateCML, 1, C_SERVICE_KIND, null)
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_GOOD
       where GCO_GOOD_ID = SourceGoodID;

    --  2. Insertion dans la table GCO_SERVICE
    insert into GCO_SERVICE
                (GCO_GOOD_ID
                )
         values (NewGoodID
                );

    -- 3. Duplication des Taxes et TVA
    DuplicateGoodVAT(SourceGoodID, NewGoodID);

    -- 4. Duplication des Données libres
    if DuplicateFreeData = 1 then
      DuplicateGoodFreeData(SourceGoodID, NewGoodID);
    end if;

    -- 5. Duplication des données complémentaires d'achat
    if DuplicatePurchase = 1 then
      DuplicateGoodDataPurchase(SourceGoodID, NewGoodID);
    end if;

    -- 6. Duplication des données complémentaires de vente
    if DuplicateSale = 1 then
      DuplicateGoodDataSale(SourceGoodID, NewGoodID);
    end if;

    -- 7. Duplication des descriptions
    DuplicateGoodDescription(SourceGoodID => SourceGoodID, TargetGoodID => NewGoodID);
    -- 8. Duplication des corrélations
    DuplicateGoodConnection(SourceGoodID, NewGoodID);
    -- 9. Duplication des contrats
    DuplicateGoodContract(SourceGoodID, NewGoodID);
    -- 10. Duplication des ressources
    DuplicateGoodRessource(SourceGoodID, NewGoodID);
    -- 11. Duplication de l'imputation comptable Document
    DuplicateGoodDocImputation(SourceGoodID, NewGoodID);

    -- 12. Duplication des PRF
    if DuplicatePRF = 1 then
      DuplicateGoodPRF(SourceGoodID, NewGoodID);
    end if;

    -- 13. Duplication des Tarifs
    if DuplicateTariff = 1 then
      DuplicateGoodTariff(SourceGoodID, NewGoodID);
    end if;

    -- 14. Duplication des champs virtuels
    if DuplicateVirtualFields = 1 then
      COM_VFIELDS.DuplicateVirtualField('GCO_GOOD', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                        SourceGoodID, NewGoodID);
    end if;

    -- 15. Génération du code EAN du bien
    GenerateEAN_Good(NewGoodID);
    -- 16. Génération du code EAN pour les données compl. d'achat
    GenerateEAN_ComplPurchase(NewGoodID);
    -- 17. Génération du code EAN pour les données compl. de vente
    GenerateEAN_ComplSale(NewGoodID);

    -- 18. Duplication des matières précieuses
    if DuplicatePreciousMat = 1 then
      DuplicateGoodPreciousMat(SourceGoodID, NewGoodID);
    end if;

    -- 19. Duplication des données de prestation (CML)
    if DuplicateCML = 1 then
      DuplicateCMLService(SourceGoodID, NewGoodId);
    end if;

    -- Mise à jour de la référence principale si Numérotation automatique
    GCO_GOOD_NUMBERING_FUNCTIONS.GetNumber(NewGoodID, 'GCO_GOOD_CATEGORY', vAutoMajorRef);

    if vAutoMajorRef is not null then
      update GCO_GOOD
         set GOO_MAJOR_REFERENCE = vAutoMajorRef
       where GCO_GOOD_ID = NewGoodID;
    end if;
  end DuplicateService;

  /**
  * Description : Méthode générale pour la duplication d'un pseudo bien
  */
  procedure DuplicatePseudo(
    SourceGoodID           in     GCO_GOOD.GCO_GOOD_ID%type
  , NewMajorRef            in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , NewSecRef              in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , NewGoodID              in out GCO_GOOD.GCO_GOOD_ID%type
  , DuplicateVirtualFields in     integer
  )
  is
    vAutoMajorRef GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
    -- 1. Duplication des données de la table GCO_GOOD
    -- 2. Insertion dans la table GCO_PSEUDO_GOOD
    -- 3. Duplication des descriptions
    -- 4. Duplication des champs virtuels
    -- 5. Génération du code EAN du bien

    -- Recherche l'ID du nouveau bien s'il n'as pas été passé en paramètre
    select decode(nvl(NewGoodID, 0), 0, INIT_ID_SEQ.nextval, NewGoodID)
      into NewGoodID
      from dual;

    -- 1. Duplication des données de la table GCO_GOOD
    insert into GCO_GOOD
                (GCO_GOOD_ID
               , GOO_MAJOR_REFERENCE
               , C_GOOD_STATUS
               , GOO_NUMBER_OF_DECIMAL
               , DIC_UNIT_OF_MEASURE_ID
               , GCO_GOOD_CATEGORY_ID
               , DIC_GOOD_LINE_ID
               , DIC_GOOD_FAMILY_ID
               , DIC_GOOD_MODEL_ID
               , DIC_GOOD_GROUP_ID
               , DIC_PTC_GOOD_GROUP_ID
               , C_MANAGEMENT_MODE
               , GOO_SECONDARY_REFERENCE
               , GOO_EAN_CODE
               , DIC_GCO_STATISTIC_1_ID
               , DIC_GCO_STATISTIC_2_ID
               , DIC_GCO_STATISTIC_3_ID
               , DIC_GCO_STATISTIC_4_ID
               , DIC_GCO_STATISTIC_5_ID
               , DIC_GCO_STATISTIC_6_ID
               , DIC_GCO_STATISTIC_7_ID
               , DIC_GCO_STATISTIC_8_ID
               , DIC_GCO_STATISTIC_9_ID
               , DIC_GCO_STATISTIC_10_ID
               , A_DATECRE
               , A_IDCRE
                )
      select NewGoodID   -- GCO_GOOD_ID
           , NewMajorRef   -- GOO_MAJOR_REFERENCE
           , decode(nvl(PCS.PC_CONFIG.GETCONFIG('GCO_INACTIVE_CREATION_GOOD'), '0'), '0', '2', '1')
           , 0   -- GOO_NUMBER_OF_DECIMAL
           , DIC_UNIT_OF_MEASURE_ID
           , GCO_GOOD_CATEGORY_ID
           , DIC_GOOD_LINE_ID
           , DIC_GOOD_FAMILY_ID
           , DIC_GOOD_MODEL_ID
           , DIC_GOOD_GROUP_ID
           , DIC_PTC_GOOD_GROUP_ID
           , C_MANAGEMENT_MODE
           , NewSecRef   -- GOO_SECONDARY_REFERENCE
           , null   -- GOO_EAN_CODE
           , DIC_GCO_STATISTIC_1_ID
           , DIC_GCO_STATISTIC_2_ID
           , DIC_GCO_STATISTIC_3_ID
           , DIC_GCO_STATISTIC_4_ID
           , DIC_GCO_STATISTIC_5_ID
           , DIC_GCO_STATISTIC_6_ID
           , DIC_GCO_STATISTIC_7_ID
           , DIC_GCO_STATISTIC_8_ID
           , DIC_GCO_STATISTIC_9_ID
           , DIC_GCO_STATISTIC_10_ID
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_GOOD
       where GCO_GOOD_ID = SourceGoodID;

    --  2. Insertion dans la table GCO_PSEUDO_GOOD
    insert into GCO_PSEUDO_GOOD
                (GCO_GOOD_ID
                )
         values (NewGoodID
                );

    -- 3. Duplication des descriptions
    DuplicateGoodDescription(SourceGoodID => SourceGoodID, TargetGoodID => NewGoodID);

    -- 4. Duplication des champs virtuels
    if DuplicateVirtualFields = 1 then
      COM_VFIELDS.DuplicateVirtualField('GCO_GOOD', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                        SourceGoodID, NewGoodID);
    end if;

    -- 5. Génération du code EAN du bien
    GenerateEAN_Good(NewGoodID);


    -- Mise à jour de la référence principale si Numérotation automatique
    GCO_GOOD_NUMBERING_FUNCTIONS.GetNumber(NewGoodID, 'GCO_GOOD_CATEGORY', vAutoMajorRef);

    if vAutoMajorRef is not null then
      update GCO_GOOD
         set GOO_MAJOR_REFERENCE = vAutoMajorRef
       where GCO_GOOD_ID = NewGoodID;
    end if;
  end DuplicatePseudo;
end GCO_PRODUCT_FUNCTIONS;
