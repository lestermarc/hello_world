--------------------------------------------------------
--  DDL for Package Body STM_ANNUALEVOL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_ANNUALEVOL" 
is
  procedure RedoAnnualEvolution
  is
  begin
    STM_PRC_STOCK_EVOLUTION.RedoAnnualEvolution;
  end RedoAnnualEvolution;

  procedure RedoGoodAnnualEvolution(aGoodId in number)
  is
  begin
    STM_PRC_STOCK_EVOLUTION.RedoGoodAnnualEvolution(aGoodId);
  end RedoGoodAnnualEvolution;

  /*
  * Mise à jour des évolutions annuelle selon un mouvement de stock
  */
  procedure STM_Update_Annual_Evolution(
    good_id             number
  , movement_date       date
  , exercise_id         number
  , movement_kind_id    number
  , stock_id            number
  , quantity            number
  , price               number
  , Charac_id1       in number
  , Charac_id2       in number
  , Charac_id3       in number
  , Charac_id4       in number
  , Charac_id5       in number
  , Charac1          in varchar2
  , Charac2          in varchar2
  , Charac3          in varchar2
  , Charac4          in varchar2
  , Charac5          in varchar2
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    vEntityMovement.GCO_GOOD_ID                   := good_id;
    vEntityMovement.SMO_MOVEMENT_DATE             := movement_date;
    vEntityMovement.STM_EXERCISE_ID               := exercise_id;
    vEntityMovement.STM_MOVEMENT_KIND_ID          := movement_kind_id;
    vEntityMovement.STM_STOCK_ID                  := stock_id;
    vEntityMovement.SMO_MOVEMENT_QUANTITY         := quantity;
    vEntityMovement.SMO_MOVEMENT_PRICE            := price;
    vEntityMovement.GCO_CHARACTERIZATION_ID       := Charac_id1;
    vEntityMovement.GCO_GCO_CHARACTERIZATION_ID   := Charac_id2;
    vEntityMovement.GCO2_GCO_CHARACTERIZATION_ID  := Charac_id3;
    vEntityMovement.GCO3_GCO_CHARACTERIZATION_ID  := Charac_id4;
    vEntityMovement.GCO4_GCO_CHARACTERIZATION_ID  := Charac_id5;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_1  := Charac1;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_2  := Charac2;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_3  := Charac3;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_4  := Charac4;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_5  := Charac5;
    STM_PRC_STOCK_EVOLUTION.updateAnnualEvolution(vEntityMovement);
  end STM_Update_Annual_Evolution;

  /*
  * Renvoie la quantité solde en tenant compte des caractérisations
  */
  function GetMonthBalanceQty_Char(
    GOOD_ID                  number
  , STOCK_ID                 number
  , REQUESTED_YEAR           varchar2
  , month                    number
  , CHARACTERIZATION_ID1     number
  , CHARACTERIZATION_ID2     number
  , CHARACTERIZATION_ID3     number
  , CHARACTERIZATION_ID4     number
  , CHARACTERIZATION_ID5     number
  , CHARACTERIZATION_VALUE_1 varchar2
  , CHARACTERIZATION_VALUE_2 varchar2
  , CHARACTERIZATION_VALUE_3 varchar2
  , CHARACTERIZATION_VALUE_4 varchar2
  , CHARACTERIZATION_VALUE_5 varchar2
  , TOTALIZATION_MODE        number
  )
    return number
  is
  begin
    return STM_PRC_STOCK_EVOLUTION.GetMonthBalanceQty_Char(GOOD_ID
                                                         , STOCK_ID
                                                         , REQUESTED_YEAR
                                                         , month
                                                         , CHARACTERIZATION_ID1
                                                         , CHARACTERIZATION_ID2
                                                         , CHARACTERIZATION_ID3
                                                         , CHARACTERIZATION_ID4
                                                         , CHARACTERIZATION_ID5
                                                         , CHARACTERIZATION_VALUE_1
                                                         , CHARACTERIZATION_VALUE_2
                                                         , CHARACTERIZATION_VALUE_3
                                                         , CHARACTERIZATION_VALUE_4
                                                         , CHARACTERIZATION_VALUE_5
                                                         , TOTALIZATION_MODE
                                                          );
  end GetMonthBalanceQty_Char;

  /*
  * Renvoie la quantité solde sans tenir compte des caractérisations
  */
  function GetMonthBalanceQty_NoChar(
    GOOD_ID           number
  , STOCK_ID          number
  , REQUESTED_YEAR    varchar2
  , month             number
  , TOTALIZATION_MODE number
  )
    return number
  is
  begin
    return STM_PRC_STOCK_EVOLUTION.GetMonthBalanceQty_NoChar(GOOD_ID
                                                           , STOCK_ID
                                                           , REQUESTED_YEAR
                                                           , month
                                                           , TOTALIZATION_MODE
                                                            );
  end GetMonthBalanceQty_NoChar;

  /*
  * Renvoie la quantité solde en tenant compte des caractérisations
  */
  function GetMonthBalanceValue_Char(
    GOOD_ID                  number
  , STOCK_ID                 number
  , REQUESTED_YEAR           varchar2
  , month                    number
  , CHARACTERIZATION_ID1     number
  , CHARACTERIZATION_ID2     number
  , CHARACTERIZATION_ID3     number
  , CHARACTERIZATION_ID4     number
  , CHARACTERIZATION_ID5     number
  , CHARACTERIZATION_VALUE_1 varchar2
  , CHARACTERIZATION_VALUE_2 varchar2
  , CHARACTERIZATION_VALUE_3 varchar2
  , CHARACTERIZATION_VALUE_4 varchar2
  , CHARACTERIZATION_VALUE_5 varchar2
  , TOTALIZATION_MODE        number
  )
    return number
  is
  begin
    return STM_PRC_STOCK_EVOLUTION.GetMonthBalanceValue_Char(GOOD_ID
                                                           , STOCK_ID
                                                           , REQUESTED_YEAR
                                                           , month
                                                           , CHARACTERIZATION_ID1
                                                           , CHARACTERIZATION_ID2
                                                           , CHARACTERIZATION_ID3
                                                           , CHARACTERIZATION_ID4
                                                           , CHARACTERIZATION_ID5
                                                           , CHARACTERIZATION_VALUE_1
                                                           , CHARACTERIZATION_VALUE_2
                                                           , CHARACTERIZATION_VALUE_3
                                                           , CHARACTERIZATION_VALUE_4
                                                           , CHARACTERIZATION_VALUE_5
                                                           , TOTALIZATION_MODE
                                                            );
  end GetMonthBalanceValue_Char;

  /*
  * Renvoie la quantité solde sans tenir compte des caractérisations
  */
  function GetMonthBalanceValue_NoChar(
    GOOD_ID           number
  , STOCK_ID          number
  , REQUESTED_YEAR    varchar2
  , month             number
  , TOTALIZATION_MODE number
  )
    return number
  is
  begin
    return STM_PRC_STOCK_EVOLUTION.GetMonthBalanceValue_NoChar(GOOD_ID
                                                             , STOCK_ID
                                                             , REQUESTED_YEAR
                                                             , month
                                                             , TOTALIZATION_MODE
                                                              );
  end GetMonthBalanceValue_NoChar;
end STM_ANNUALEVOL;
