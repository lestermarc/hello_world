--------------------------------------------------------
--  DDL for Package Body PTC_PRC_SAMPLE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_PRC_SAMPLE" 
is
  /**
  * Description
  *   sample procedure to show how you have to code a method to create tarifs
  *   from fixed cost price in the tariff wizard.
  *   In this method we create 2 tarifs, one in local currency and one in EURO
  *   the two tarifs are 10 times the price of the source fixed cost price
  */
  procedure createTariffFromFCP_wizard(iFCPId in number, iDateFrom in date, iDateTo in date, oTariffListId out varchar2)
  is
    lTariffChf    PTC_TARIFF.PTC_TARIFF_ID%type             := -1;
    lTariffEur    PTC_TARIFF.PTC_TARIFF_ID%type             := -1;
    lExchangeRate ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    lBasePrice    ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
    ltplFCP       PTC_FIXED_COSTPRICE%rowtype;
  begin
    select *
      into ltplFCP
      from PTC_FIXED_COSTPRICE
     where PTC_FIXED_COSTPRICE_ID = iFCPId;

    insert into PTC_TARIFF
                (PTC_TARIFF_ID
               , GCO_GOOD_ID
               , DIC_TARIFF_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , C_TARIFF_TYPE
               , TRF_DESCR
               , TRF_STARTING_DATE
               , TRF_ENDING_DATE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , ltplFCP.GCO_GOOD_ID
               , 'INT'
               , ACS_FUNCTION.GetLocalCurrencyId
               , 'A_FACTURER'
               , 'Sale price calculated from FCP'
               , iDateFrom
               , iDateTo
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                )
      returning PTC_TARIFF_ID
           into lTariffChf;

    oTariffListId  := lTariffChf;

    insert into PTC_TARIFF_TABLE
                (PTC_TARIFF_TABLE_ID
               , PTC_TARIFF_ID
               , TTA_FROM_QUANTITY
               , TTA_TO_QUANTITY
               , TTA_PRICE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , lTariffChf
               , 0
               , 0
               , ltplFCP.CPR_PRICE * 10
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    insert into PTC_TARIFF
                (PTC_TARIFF_ID
               , GCO_GOOD_ID
               , DIC_TARIFF_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , C_TARIFF_TYPE
               , TRF_DESCR
               , TRF_STARTING_DATE
               , TRF_ENDING_DATE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , ltplFCP.GCO_GOOD_ID
               , 'INT'
               , ACS_FUNCTION.GetCurrencyId('EUR')
               , 'A_FACTURER'
               , 'Sale price calculated from FCP'
               , iDateFrom
               , iDateTo
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                )
      returning PTC_TARIFF_ID
           into lTariffEur;

    -- create a EURO tarif only if EURO is not the local currency
    if ACS_FUNCTION.GetLocalCurrencyId <> ACS_FUNCTION.GetCurrencyId('EUR') then
      ACS_FUNCTION.GETEXCHANGERATE(aDate           => sysdate
                                 , aCurrency_Id    => ACS_FUNCTION.GetCurrencyId('EUR')
                                 , aExchangeRate   => lExchangeRate
                                 , aBasePrice      => lBasePrice
                                  );

      insert into PTC_TARIFF_TABLE
                  (PTC_TARIFF_TABLE_ID
                 , PTC_TARIFF_ID
                 , TTA_FROM_QUANTITY
                 , TTA_TO_QUANTITY
                 , TTA_PRICE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , lTariffEur
                 , 0
                 , 0
                 , ltplFCP.CPR_PRICE * 10 * lBasePrice / lExchangeRate
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      oTariffListId  := oTariffListId || ';' || lTariffEur;
    end if;
  end createTariffFromFCP_wizard;

  /**
  * Description
  *   sample procedure to show how you have to code a method to create tarifs
  *   from calculated cost price in the tariff wizard.
  *   In this method we create a tariff in local currency which is 2 times the
  *   price of the calculated cost price.
  */
  procedure createTariffFromCCP_wizard(iCCPId in number, iDateFrom in date, iDateTo in date, oTariffListId out varchar2)
  is
    lTariffChf PTC_TARIFF.PTC_TARIFF_ID%type   := -1;
    ltplCCP    PTC_CALC_COSTPRICE%rowtype;
  begin
    select *
      into ltplCCP
      from PTC_CALC_COSTPRICE
     where PTC_CALC_COSTPRICE_ID = iCCPId;

    insert into PTC_TARIFF
                (PTC_TARIFF_ID
               , GCO_GOOD_ID
               , DIC_TARIFF_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , C_TARIFF_TYPE
               , TRF_DESCR
               , TRF_STARTING_DATE
               , TRF_ENDING_DATE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , ltplCCP.GCO_GOOD_ID
               , 'INT'
               , ACS_FUNCTION.GetLocalCurrencyId
               , 'A_FACTURER'
               , 'Sale price calculated from CCP'
               , iDateFrom
               , iDateTo
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                )
      returning PTC_TARIFF_ID
           into lTariffChf;

    insert into PTC_TARIFF_TABLE
                (PTC_TARIFF_TABLE_ID
               , PTC_TARIFF_ID
               , TTA_FROM_QUANTITY
               , TTA_TO_QUANTITY
               , TTA_PRICE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , lTariffChf
               , 0
               , 0
               , ltplCCP.CPR_PRICE * 2
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    oTariffListId  := lTariffChf;
  end createTariffFromCCP_wizard;

  /**
  * Description
  *   sample procedure to show how you have to code a method to create tarifs
  *   from PRCS-WAC (Weighted Average Cost) in the tariff wizard.
  *   In this method, we create a tariff with a 2 levels table the first for
  *   qty 0-9 (+100%) and the second for qty 10 - infinite (+80%)
  */
  procedure createTariffFromWAC_wizard(iGoodId in number, iDateFrom in date, iDateTo in date, oTariffListId out varchar2)
  is
    lTariffChf PTC_TARIFF.PTC_TARIFF_ID%type   := -1;
    ltplWAC    GCO_GOOD_CALC_DATA%rowtype;
  begin
    select *
      into ltplWAC
      from GCO_GOOD_CALC_DATA
     where GCO_GOOD_ID = iGoodId;

    insert into PTC_TARIFF
                (PTC_TARIFF_ID
               , GCO_GOOD_ID
               , DIC_TARIFF_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , C_TARIFF_TYPE
               , TRF_DESCR
               , TRF_STARTING_DATE
               , TRF_ENDING_DATE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , iGoodId
               , 'INT'
               , ACS_FUNCTION.GetLocalCurrencyId
               , 'A_FACTURER'
               , 'Sale price calculated from WAC'
               , iDateFrom
               , iDateTo
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                )
      returning PTC_TARIFF_ID
           into lTariffChf;

    insert into PTC_TARIFF_TABLE
                (PTC_TARIFF_TABLE_ID
               , PTC_TARIFF_ID
               , TTA_FROM_QUANTITY
               , TTA_TO_QUANTITY
               , TTA_PRICE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , lTariffChf
               , 0
               , 10 - gco_i_lib_functions.GetminimumQuantity(iGoodId)
               , ltplWAC.GOO_BASE_COST_PRICE * 2
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    insert into PTC_TARIFF_TABLE
                (PTC_TARIFF_TABLE_ID
               , PTC_TARIFF_ID
               , TTA_FROM_QUANTITY
               , TTA_TO_QUANTITY
               , TTA_PRICE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , lTariffChf
               , 10
               , 0
               , ltplWAC.GOO_BASE_COST_PRICE * 1.8
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    oTariffListId  := lTariffChf;
  exception
    -- May be it's no data for the good in the GCO_GOOD_CALC_DATA table
    when no_data_found then
      null;
  end createTariffFromWAC_wizard;

  /**
  * Description
  *   sample procedure to show how you have to code a method to create tarifs
  *   from other tariffs in the tariff wizard.
  *   In this method, we create a tariff with a 3 levels table
  *     the first for qty 0-9 (5 times the source)
  *     the second for qty 10 - 99 (4 times the source)
  *     the third for qty 100 - infinite (3 times the source)
  */
  procedure createTariffFromTariff_wizard(iTariffId in number, iDateFrom in date, iDateTo in date, oTariffListId out varchar2)
  is
    lTariffChf PTC_FIXED_COSTPRICE.PTC_FIXED_COSTPRICE_ID%type   := -1;
    ltplTariff PTC_TARIFF%rowtype;
  begin
    select *
      into ltplTariff
      from PTC_TARIFF
     where PTC_TARIFF_ID = iTariffId;

    insert into PTC_TARIFF
                (PTC_TARIFF_ID
               , GCO_GOOD_ID
               , DIC_TARIFF_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , C_TARIFF_TYPE
               , TRF_DESCR
               , TRF_STARTING_DATE
               , TRF_ENDING_DATE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , ltplTariff.GCO_GOOD_ID
               , 'INT'
               , ACS_FUNCTION.GetLocalCurrencyId
               , 'A_FACTURER'
               , 'Sample from createTariffFromTariff_wizard'
               , iDateFrom
               , iDateTo
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                )
      returning PTC_TARIFF_ID
           into lTariffChf;

    for ltplTariffTable in (select *
                              from PTC_TARIFF_TABLE
                             where PTC_TARIFF_ID = iTariffId) loop
      insert into PTC_TARIFF_TABLE
                  (PTC_TARIFF_TABLE_ID
                 , PTC_TARIFF_ID
                 , TTA_FROM_QUANTITY
                 , TTA_TO_QUANTITY
                 , TTA_PRICE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , lTariffChf
                 , 0
                 , 10 - gco_i_lib_functions.GetminimumQuantity(ltplTariff.GCO_GOOD_ID)
                 , ltplTariffTable.TTA_PRICE * 5
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      insert into PTC_TARIFF_TABLE
                  (PTC_TARIFF_TABLE_ID
                 , PTC_TARIFF_ID
                 , TTA_FROM_QUANTITY
                 , TTA_TO_QUANTITY
                 , TTA_PRICE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , lTariffChf
                 , 10
                 , 100 - gco_i_lib_functions.GetminimumQuantity(ltplTariff.GCO_GOOD_ID)
                 , ltplTariffTable.TTA_PRICE * 4
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      insert into PTC_TARIFF_TABLE
                  (PTC_TARIFF_TABLE_ID
                 , PTC_TARIFF_ID
                 , TTA_FROM_QUANTITY
                 , TTA_TO_QUANTITY
                 , TTA_PRICE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , lTariffChf
                 , 100
                 , 0
                 , ltplTariffTable.TTA_PRICE * 3
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;

    oTariffListId  := lTariffChf;
  end createTariffFromTariff_wizard;
end PTC_PRC_SAMPLE;
