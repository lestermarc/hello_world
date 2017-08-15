--------------------------------------------------------
--  DDL for Package Body WFL_PRC_TRANSITIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_PRC_TRANSITIONS" 
is
  /**
  * procedure UpdateGraphicInformations
  * Description
  *   Méthode permettant la sauvegarde des élements graphiques d'une transition.
  */
  procedure UpdateGraphicInformations(
    inTransitionID in WFL_TRANSITIONS.WFL_TRANSITIONS_ID%type
  , inXMLGraph     in WFL_TRANSITIONS.TRA_GRAPH%type
  )
  is
  begin
    update WFL_TRANSITIONS
       set TRA_GRAPH = inXMLGraph
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where WFL_TRANSITIONS_ID = inTransitionID;
  end UpdateGraphicInformations;
end WFL_PRC_TRANSITIONS;
