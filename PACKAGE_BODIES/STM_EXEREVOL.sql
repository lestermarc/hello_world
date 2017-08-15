--------------------------------------------------------
--  DDL for Package Body STM_EXEREVOL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_EXEREVOL" 
is
  -- Reconstruction des évolution de stock par périodes
  procedure RedoExerciseEvolution
  is
  begin
    STM_PRC_STOCK_EVOLUTION.RedoExerciseEvolution;
  end RedoExerciseEvolution;

  /*
  * Reconstruction des évolution de stock par périodes
  */
  procedure RedoGoodExerciseEvolution(aGoodId in number)
  is
  begin
    STM_PRC_STOCK_EVOLUTION.RedoGoodExerciseEvolution(aGoodId);
  end RedoGoodExerciseEvolution;

  /*
  * Cette procédure met à jour les informations d'évolution périodique de stock d'après un mouvement de stock
  */
  procedure STM_Update_Exercise_Evolution(
    Good_id          in number
  , exercise_id      in number
  , period_id        in number
  , Movement_kind_id in number
  , stock_id         in number
  , quantity         in number
  , price            in number
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
    vEntityMovement.STM_EXERCISE_ID               := exercise_id;
    vEntityMovement.STM_PERIOD_ID                 := period_id;
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
    STM_PRC_STOCK_EVOLUTION.updateExerciseEvolution(vEntityMovement);
  end STM_Update_Exercise_Evolution;
end STM_EXEREVOL;
