--------------------------------------------------------
--  DDL for Package Body DOC_BUDGET_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_BUDGET_FUNCTIONS" 
is
  /**
   * function ControlBudget
   * Description
   *   Contrôle le dépassement de budget pour les positions d'un document.
   *   La procédure spécifiée dans la configuration DOC_BUDGET_CONTROL_PROC est
   *   appelée si elle est renseignée.
   */
  function ControlBudget(
    aDocumentId      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aConsumptionType in DOC_GAUGE_STRUCTURED.C_BUDGET_CONSUMPTION_TYPE%type
  , aNatureCode      in DIC_GAU_NATURE_CODE.DIC_GAU_NATURE_CODE_ID%type
  , aDateValue       in DOC_DOCUMENT.DMT_DATE_VALUE%type
  )
    return number
  is
    vPassed    number;
    vProcedure varchar2(255);
  begin
    vPassed     := 1;
    vProcedure  := PCS.PC_CONFIG.GetConfig('DOC_BUDGET_CONTROL_PROC');

    -- Appel de la procédure si spécifiée dans la config DOC_BUDGET_CONTROL_PROC
    if not vProcedure is null then
      execute immediate 'begin                                                            ' ||
                        vProcedure ||
                        '(aDocumentId      => :DOC_DOCUMENT_ID           ' ||
                        '                , aConsumptionType => :C_BUDGET_CONSUMPTION_TYPE ' ||
                        '                , aNatureCode      => :DIC_GAU_NATURE_CODE_ID    ' ||
                        '                , aDateValue       => :DMT_DATE_VALUE            ' ||
                        '                , aPassed          => :Passed);                  ' ||
                        'end;                                                             '
                  using in aDocumentId, in aConsumptionType, in aNatureCode, in aDateValue, out vPassed;
    end if;

    return vPassed;
  end ControlBudget;

  /**
   * procedure InitPosBudgetAmounts
   * Description
   *   Calcul des valeurs d'initialisation des montants de contrôle de budget au
   *   niveau de la position.
   *   Les valeurs des montants sont initialisées avec la valeur du mouvement
   *   en monnaie de base. Ensuite la procédure spécifiée dans la configuration
   *   DOC_BUDGET_INIT_AMOUNTS_PROC peut éventuellement modifier ces valeurs.
   */
  procedure InitPosBudgetAmounts(
    aPositionId           in     DOC_POSITION.DOC_POSITION_ID%type
  , aCalcBudgetAmountMB   out    DOC_POSITION.POS_CALC_BUDGET_AMOUNT_MB%type
  , aEffectBudgetAmountMB out    DOC_POSITION.POS_EFFECT_BUDGET_AMOUNT_MB%type
  )
  is
    vProcedure            varchar2(255);
    vCalcBudgetAmountMB   DOC_POSITION.POS_CALC_BUDGET_AMOUNT_MB%type;
    vEffectBudgetAmountMB DOC_POSITION.POS_EFFECT_BUDGET_AMOUNT_MB%type;
  begin
/*    -- Initialisation des montants avec : Prix de revient unitaire MB * Quantité de base en unité de stockage
    select POS.POS_UNIT_COST_PRICE * POS.POS_BASIS_QUANTITY_SU
      into aCalcBudgetAmountMB
      from DOC_POSITION POS
     where POS.DOC_POSITION_ID = aPositionId;
*/
    aCalcBudgetAmountMB  := DOC_POSITION_FUNCTIONS.CalcPosMvtValue(aPositionId);

    select POS_CALC_BUDGET_AMOUNT_MB
         , POS_EFFECT_BUDGET_AMOUNT_MB
      into vCalcBudgetAmountMB
         , vEffectBudgetAmountMB
      from DOC_POSITION
     where DOC_POSITION_ID = aPositionId;

    -- si un budget effectif a été défini manuellement, on ne le réinitialise pas
    if (vEffectBudgetAmountMB = vCalcBudgetAmountMB) then
      aEffectBudgetAmountMB  := aCalcBudgetAmountMB;
    else
      aEffectBudgetAmountMB  := vEffectBudgetAmountMB;
    end if;

    vProcedure           := PCS.PC_CONFIG.GetConfig('DOC_BUDGET_INIT_AMOUNTS_PROC');

    -- Appel de la procédure si spécifiée dans la config DOC_BUDGET_INIT_AMOUNTS_PROC
    if not vProcedure is null then
      execute immediate 'begin                                                                      ' ||
                        vProcedure ||
                        '(aPositionId           => :DOC_POSITION_ID                ' ||
                        '                , aCalcBudgetAmountMB   => :POS_CALC_BUDGET_AMOUNT_MB      ' ||
                        '                , aEffectBudgetAmountMB => :POS_EFFECT_BUDGET_AMOUNT_MB ); ' ||
                        'end;                                                                       '
                  using in aPositionId, in out aCalcBudgetAmountMB, in out aEffectBudgetAmountMB;
    end if;
  end InitPosBudgetAmounts;

  /**
   * procedure UpdatePosBudgetAmounts
   * Description
   *   Mise à jour des montants de contrôle de budget au niveau de la position.
   */
  procedure UpdatePosBudgetAmounts(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
  is
    vCalcBudgetAmountMB   DOC_POSITION.POS_CALC_BUDGET_AMOUNT_MB%type;
    vEffectBudgetAmountMB DOC_POSITION.POS_EFFECT_BUDGET_AMOUNT_MB%type;
  begin
    -- Calcul des montants (appel éventuel à une procédure indiv)
    InitPosBudgetAmounts(aPositionId => aPositionId, aCalcBudgetAmountMB => vCalcBudgetAmountMB, aEffectBudgetAmountMB => vEffectBudgetAmountMB);

    -- Mise à jour de la position
    update DOC_POSITION
       set POS_CALC_BUDGET_AMOUNT_MB = vCalcBudgetAmountMB
         , POS_EFFECT_BUDGET_AMOUNT_MB = vEffectBudgetAmountMB
         , POS_BUDGET_USER_ID = null
         , POS_BUDGET_ACCEPT_DATE = null
         , POS_BUDGET_EXCEEDED = 0
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where DOC_POSITION_ID = aPositionId
       and (   POS_CALC_BUDGET_AMOUNT_MB is null
            or (POS_CALC_BUDGET_AMOUNT_MB <> vCalcBudgetAmountMB) );
  end UpdatePosBudgetAmounts;

  /**
   * Description
   *   Renseigne les infos d'acceptation des dépassements de budget du document.
   *   Si aForceUpdate = 1 alors on renseigne même les positions qui ne dépassent
   *   pas le budget.
   */
  procedure AcceptAllExceeding(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aForceUpdate integer default 0)
  is
  begin
    update DOC_POSITION
       set POS_BUDGET_ACCEPT_DATE = sysdate
         , POS_BUDGET_USER_ID = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_DOCUMENT_ID = aDocumentID
       and (    (POS_BUDGET_EXCEEDED = 1)
            or (aForceUpdate = 1) )
       and (   POS_BUDGET_ACCEPT_DATE is null
            or POS_BUDGET_USER_ID is null);
  end AcceptAllExceeding;
end DOC_BUDGET_FUNCTIONS;
