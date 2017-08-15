--------------------------------------------------------
--  DDL for Package Body SQM_ANC_POSITION_INITIALIZE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_ANC_POSITION_INITIALIZE" 
is

  /**
  * Procedure   : ResetANCPositionRecord
  * Description : Efface et réinitialise les données de création d'une position de NC.
  */
  procedure ResetANCPositionRecord(aSQM_ANC_POSITION_Rec in out TSQM_ANC_POSITION_Rec)
  is
    tmpSQM_ANC_POSITION_Rec           SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_POSITION_Rec;
  begin
    -- Initialisation position de NC.
    aSQM_ANC_POSITION_Rec           := tmpSQM_ANC_POSITION_Rec;
  end ResetANCPOSITIONRecord;

  /**
  * Procedure   : ResetNCCorrectionRecord
  * Description : Efface et réinitialise les données de création d'une Correction de position de NC.
  */
  procedure ResetNCCorrectionRecord(aSQM_ANC_CORRECTION_Rec in out TSQM_ANC_CORRECTION_Rec)
  is
    tmpSQM_ANC_CORRECTION_Rec           SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CORRECTION_Rec;
  begin
    -- Initialisation Correction.
    aSQM_ANC_CORRECTION_Rec           := tmpSQM_ANC_CORRECTION_Rec;
  end ResetNCCorrectionRecord;

  /**
  * Procedure   : ResetNCCauseRecord
  * Description : Efface et réinitialise les données de création d'une Cause de position de NC.
  */
  procedure ResetNCCauseRecord(aSQM_ANC_CAUSE_Rec in out TSQM_ANC_CAUSE_Rec)
  is
    tmpSQM_ANC_CAUSE_Rec           SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CAUSE_Rec;
  begin
    -- Initialisation Correction.
    aSQM_ANC_CAUSE_Rec           := tmpSQM_ANC_CAUSE_Rec;
  end ResetNCCauseRecord;

  /**
  * Procedure   : ResetNCActionRecord
  * Description : Efface et réinitialise les données de création d'une Action de position de NC.
  */
  procedure ResetNCActionRecord(aSQM_ANC_ACTION_Rec in out TSQM_ANC_ACTION_Rec)
  is
    tmpSQM_ANC_ACTION_Rec           SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_ACTION_Rec;
  begin
    -- Initialisation Correction.
    aSQM_ANC_ACTION_Rec           := tmpSQM_ANC_ACTION_Rec;
  end ResetNCActionRecord;

  /**
  * Procedure   : ResetNCLinkRecord
  * Description : Efface et réinitialise les données de création d'un lien sur position, correction de NC.
  */
  procedure ResetNCLinkRecord(aSQM_ANC_LINK_Rec in out TSQM_ANC_LINK_Rec)
  is
    tmpSQM_ANC_LINK_Rec           SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_LINK_Rec;
  begin
    -- Initialisation Correction.
    aSQM_ANC_LINK_Rec           := tmpSQM_ANC_LINK_Rec;
  end ResetNCLinkRecord;


end SQM_ANC_POSITION_INITIALIZE;
