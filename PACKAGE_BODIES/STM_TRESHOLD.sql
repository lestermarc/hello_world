--------------------------------------------------------
--  DDL for Package Body STM_TRESHOLD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_TRESHOLD" 
is
  procedure STM_TESTSTOCKEXERCISE(
    EXERCISE_ID           in number
  , STOCK_ID              in number
  , KIND_ID               in number
  , GOOD_ID               in number
  , MOVEMENT_ID           in number
  , SMO_MOVEMENT_QUANTITY in number
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    vEntityMovement.STM_EXERCISE_ID        := EXERCISE_ID;
    vEntityMovement.STM_STOCK_ID           := STOCK_ID;
    vEntityMovement.STM_MOVEMENT_KIND_ID   := KIND_ID;
    vEntityMovement.GCO_GOOD_ID            := STOCK_ID;
    vEntityMovement.STM_STOCK_MOVEMENT_ID  := MOVEMENT_ID;
    vEntityMovement.SMO_MOVEMENT_QUANTITY  := SMO_MOVEMENT_QUANTITY;
    STM_PRC_TRESHOLD.TestStockExercise(vEntityMovement);
  end;

  procedure STM_FINDSUPPLYINGPOLITICAL(
    STOCK_ID              in number
  , KIND_ID               in number
  , GOOD_ID               in number
  , MOVEMENT_ID           in number
  , SMO_MOVEMENT_QUANTITY in number
  )
  is
  begin
    STM_PRC_TRESHOLD.FindSupplyingPolitical(STOCK_ID, KIND_ID, GOOD_ID, MOVEMENT_ID, SMO_MOVEMENT_QUANTITY);
  end;

  procedure STM_ControlThresholdGoodStock(
    SUPPLYING_POLITICAL_ID in number
  , KIND_ID                in number
  , GOOD_ID                in number
  , STOCK_ID               in number
  , MOVEMENT_ID            in number
  , SMO_MOVEMENT_QUANTITY  in number
  )
  is
  begin
    STM_PRC_TRESHOLD.ControlThresholdGoodStock(SUPPLYING_POLITICAL_ID
                                             , KIND_ID
                                             , GOOD_ID
                                             , STOCK_ID
                                             , MOVEMENT_ID
                                             , SMO_MOVEMENT_QUANTITY
                                              );
  end;

  procedure STM_ControlThresholdGood(
    SUPPLYING_POLITICAL_ID in number
  , KIND_ID                in number
  , GOOD_ID                in number
  , STOCK_ID               in number
  , MOVEMENT_ID            in number
  , SMO_MOVEMENT_QUANTITY  in number
  )
  is
  begin
    STM_PRC_TRESHOLD.ControlThresholdGood(SUPPLYING_POLITICAL_ID
                                        , KIND_ID
                                        , GOOD_ID
                                        , STOCK_ID
                                        , MOVEMENT_ID
                                        , SMO_MOVEMENT_QUANTITY
                                         );
  end;

  procedure STM_ControlThresholdStock(
    SUPPLYING_POLITICAL_ID in number
  , KIND_ID                in number
  , STOCK_ID               in number
  , GOOD_ID                in number
  , MOVEMENT_ID            in number
  , SMO_MOVEMENT_QUANTITY  in number
  )
  is
  begin
    STM_PRC_TRESHOLD.ControlThresholdStock(SUPPLYING_POLITICAL_ID
                                         , KIND_ID
                                         , STOCK_ID
                                         , GOOD_ID
                                         , MOVEMENT_ID
                                         , SMO_MOVEMENT_QUANTITY
                                          );
  end;

  procedure STM_ThresholdOk(
    SUPPLYING_POLITICAL_ID in number
  , MOVEMENT_ID            in number
  , STOCK_ID               in number
  , GOOD_ID                in number
  , numberInStock          in number
  , SMO_MOVEMENT_QUANTITY  in number
  )
  is
  begin
    STM_PRC_TRESHOLD.ThresholdOk(SUPPLYING_POLITICAL_ID
                               , MOVEMENT_ID
                               , STOCK_ID
                               , GOOD_ID
                               , numberInStock
                               , SMO_MOVEMENT_QUANTITY
                                );
  end;
end STM_TRESHOLD;
