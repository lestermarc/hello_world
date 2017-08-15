--------------------------------------------------------
--  DDL for Package Body FAL_LIB_ADV_POSTCALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_ADV_POSTCALCULATION" 
is
  /**
  * Description
  *    Si la config FAL_PROGRESS_TYPE = 3, pas de suivi. Les t�ches sont mises � jour au solde
  *    du lot. Si config = 3 et lot pas sold�,  retourne donc le "travail th�orique"
  *    pr�vu dans l'op�ration du lot et non le "Travail r�alis�" (TAL_ACHIEVED_TSK)
  */
  function getTravailSiProgressType3(iQuantity in number, iTaskID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lTravail number;
  begin
    /* Identique au select de la m�thode TestOperationForBatchBalance du package FAL_BATCH_FUNCTIONS */
    select iQuantity / SCS_QTY_REF_WORK * SCS_WORK_TIME TRAVAIL
      into lTravail
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskID;

    return lTravail;
  exception
    when no_data_found then
      return 0;
  end getTravailSiProgressType3;

  /**
  * Description
  *    Si la config FAL_PROGRESS_TYPE = 3, pas de suivi. Les t�ches sont mises � jour au solde
  *    du lot. Si config = 3 et lot pas sold�, retourne donc le "R�glage th�orique"
  *    pr�vu dans l'op�ration du lot et non le "R�glage r�alis�" (TAL_ACHIEVED_AD_TSK)
  */
  function getReglageSiProgressType3(iQuantity in number, iTaskID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lReglage number;
  begin
    /* Identique au select de la m�thode TestOperationForBatchBalance du package FAL_BATCH_FUNCTIONS */
    select case
             when nvl(SCS_QTY_FIX_ADJUSTING, 0) = 0 then SCS_ADJUSTING_TIME
             else ceil(iQuantity / SCS_QTY_FIX_ADJUSTING) * SCS_ADJUSTING_TIME
           end
      into lReglage
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskID;

    return lReglage;
  exception
    when no_data_found then
      return 0;
  end getReglageSiProgressType3;

  /**
  * Description
  *    Si la config FAL_PROGRESS_TYPE = 3, pas de suivi. Les t�ches sont mises � jour au solde
  *    du lot. Si config = 3 et lot pas sold�, retourne donc le "Montant th�orique"
  *    pr�vu dans l'op�ration du lot et non le "Montant r�alis�" (TAL_ACHIEVED_AMT)
  */
  function getMontantSiProgressType3(iQuantity in number, iTaskID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lMontant1 number;
    lMontant2 number;
  begin
    /* Identique au select de la m�thode TestOperationForBatchBalance du package FAL_BATCH_FUNCTIONS */
    select case
             when nvl(SCS_DIVISOR_AMOUNT, 0) > 0 then (iQuantity / SCS_QTY_REF_AMOUNT) * SCS_AMOUNT
             else iQuantity * SCS_QTY_REF_AMOUNT * SCS_AMOUNT
           end,
           TAL_CST_UNIT_PRICE_B * iQuantity
      into lMontant1, lMontant2
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskID;

    return Nvl(lMontant2,lMontant1);
  exception
    when no_data_found then
      return 0;
  end getMontantSiProgressType3;
end FAL_LIB_ADV_POSTCALCULATION;
