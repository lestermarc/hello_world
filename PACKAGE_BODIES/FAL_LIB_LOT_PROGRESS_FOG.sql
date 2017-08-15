--------------------------------------------------------
--  DDL for Package Body FAL_LIB_LOT_PROGRESS_FOG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_LOT_PROGRESS_FOG" 
is
  /**
  * Description
  *    Retourne les IDs de l'atelier, du lot et de la t�che du brouillard d'avancement
  *    transmis en param�tre.
  */
  procedure recoverIDs(
    inFalLotProgressID  in     FAL_LOT_PROGRESS_FOG.FAL_LOT_PROGRESS_FOG_ID%type
  , onFalFactoryFloorID out    FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , onFalLotID          out    FAL_LOT.FAL_LOT_ID%type
  , onFalTaskLinkID     out    FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  )
  as
    lvPfgRefFactoryFloor FAL_LOT_PROGRESS_FOG.PFG_REF_FACTORY_FLOOR%type;
    lvPfgLotRefCompl     FAL_LOT_PROGRESS_FOG.PFG_LOT_REFCOMPL%type;
    lnPfgSeq             FAL_LOT_PROGRESS_FOG.PFG_SEQ%type;
  begin
    /* R�cup�ration des r�f�rence Atelier et lot et de la s�quence de l'op�ration
       du brouillard d'avancement. */
    select PFG_REF_FACTORY_FLOOR
         , PFG_LOT_REFCOMPL
         , PFG_SEQ
      into lvPfgRefFactoryFloor
         , lvPfgLotRefCompl
         , lnPfgSeq
      from FAL_LOT_PROGRESS_FOG
     where FAL_LOT_PROGRESS_FOG_ID = inFalLotProgressID;

    /* R�cup�ration de l'ID de l'atelier */
    onFalFactoryFloorID  := FAL_LIB_FACTORY_FLOOR.getFactoryFloorIDByRef(ivFacReference => lvPfgRefFactoryFloor);
    /* R�cup�ration de l'ID du lot */
    onFalLotID           := FAL_LIB_BATCH.getLotIDByRefCompl(ivLotRefcompl => lvPfgLotRefCompl);
    /* R�cup�ration de l'ID de l'op�ration de lot */
    onFalTaskLinkID      := FAL_LIB_TASK_LINK.getTaskLinkIDbyStepAndLot(inFalLotID => onFalLotID, inScsStepNumber => lnPfgSeq);
  end recoverIDs;
end FAL_LIB_LOT_PROGRESS_FOG;
