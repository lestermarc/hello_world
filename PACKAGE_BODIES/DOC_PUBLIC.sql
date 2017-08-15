--------------------------------------------------------
--  DDL for Package Body DOC_PUBLIC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PUBLIC" 
as
  /**
  * Description
  *  Donne le cumul des positions précédente et de la position courante
  *  pour la colonne POS_BASIS_QUANTITY  (tri en fonction de la colonne
  *  POS_NUMBER)
  */
  function CumulPosBasisQuantity(aPositionId number)
    return number
  is
  begin
    return DOC_FUNCTIONS.CumulPosBasisQuantity(aPositionId);
  end CumulPosBasisQuantity;

  /**
  * function CumulPosGrossValue
  * Description
  *  Donne le cumul des positions précédente et de la position courante
  *  pour la colonne POS_GROSS_VALUE (tri en fonction de la colonne POS_NUMBER)
  */
  function CumulPosGrossValue(aPositionId number)
    return number
  is
  begin
    return DOC_FUNCTIONS.CumulPosGrossValue(aPositionId);
  end CumulPosGrossValue;

  /**
  * Description
  *   Donne le cumul des positions précédente et de la position courante
  *   pour la formule  POS_UNIT_COST_PRICE*POS_BASIS_QUANTITY
  */
  function CumulPosCostValue(aPositionId number)
    return number
  is
  begin
    return DOC_FUNCTIONS.CumulPosCostValue(aPositionId);
  end CumulPosCostValue;

  /**
  * Description
  *    Vide les buffers document et position en mettant à jour
  *    les totalisateurs
  */
  procedure PURGE_BUFFERS
  is
  begin
    DOC_ACCUMULATOR.PURGE_BUFFERS;
  end PURGE_BUFFERS;

  /**
  * Description
  *   Cette procèdure recalcule complètement les totalisateurs de positions
  *   et de documents
  */
  procedure DOC_REDO_ACCUMULATORS
  is
  begin
    DOC_ACCUMULATOR.DOC_REDO_ACCUMULATORS;
  end DOC_REDO_ACCUMULATORS;
end DOC_PUBLIC;
