--------------------------------------------------------
--  DDL for Package Body FAL_INDIVIDUAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_INDIVIDUAL" 
IS


 Procedure GetLOT_REFCOMPLforDETAIL_LOT(PrmGCO_GOOD_ID in GCO_GOOD.GCO_GOOD_ID%TYPE, PrmFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%TYPE, OutLOT_REFCOMPL OUT varchar) IS
 BEGIN
  OutLOT_REFCOMPL := NULL; -- C'est cette variable qui doit contenir la chaine finale !!!
  -- Implémenter ici le code nécessaire pour retourner la valeur de la LOT_REFCOMPL pour les détails lot.


 END;


END; -- Fin du Package
