--------------------------------------------------------
--  DDL for Package Body FAL_PRC_NETWORK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_NETWORK" 
is
  /**
  * procedure ReseauApproFALGood_Suppr
  * Description
  *   Suppression de l'enregistrement dans les Appros correspondant au LotID et GoodID donnés
  */
  procedure ReseauApproFALGood_Suppr(iLotID in FAL_NETWORK.TTypeID, iGoodID in FAL_NETWORK.TTypeID)
  is
  begin
    FAL_NETWORK.ReseauApproFAL_Suppr(iLotID, 1, iGoodID);
  end ReseauApproFALGood_Suppr;
end;
