--------------------------------------------------------
--  DDL for Package Body HRM_BUDGETS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_BUDGETS" 
AS

procedure generate_budget(vBudYear number, vDivID number, vDicDept varchar2)
is
begin
  -- G�n�ration du budget global
  if vDivID is null then
    -- Suppression du budget automatique existant
    DELETE FROM HRM_BUDGET
    WHERE BUD_YEAR = vBudYear
    AND BUD_AUTOMATIC = 1;
    -- G�n�ration du budget
    INSERT INTO HRM_BUDGET (HRM_BUDGET_ID, BUD_YEAR, HRM_DIVISION_ID, DIC_COST_TYPE_ID, BUD_AMOUNT, BUD_AUTOMATIC, A_DATECRE, A_IDCRE)
    (
    SELECT INIT_ID_SEQ.NextVal, vBudYear, HRM_DIVISION_ID, DIC_COST_TYPE_ID, TRF_AMOUNT, 1,  SysDate, 'AUTO'
    FROM(SELECT D.HRM_DIVISION_ID, DIC_COST_TYPE_ID, SUM(TRF_AMOUNT) TRF_AMOUNT
         FROM HRM_DIVISION D, HRM_PERSON P, HRM_TRAINING_FORECAST TF, HRM_SUBSCRIPTION S
         WHERE TF.HRM_TRAINING_ID = S.HRM_TRAINING_ID
         AND P.HRM_PERSON_ID = S.HRM_PERSON_ID
         AND S.SUB_PLANNED = 1
         AND TO_CHAR(S.SUB_PLAN_DATE,'yyyy') = vBudYear
         AND P.DIC_DEPARTMENT_ID = D.DIC_DEPARTMENT_ID
         GROUP BY D.HRM_DIVISION_ID, DIC_COST_TYPE_ID)
    );
    -- Mise � jour de l'info 'Est budg�t�' dans les inscriptions concernant l'ann�e g�n�r�e
    UPDATE HRM_SUBSCRIPTION SET SUB_IS_BUDGETED = 1
    WHERE SUB_PLANNED = 1
    AND TO_CHAR(SUB_PLAN_DATE,'yyyy') = vBudYear;
  -- Budget pour un d�partement
  else
    -- Suppression du budget automatique existant
    DELETE FROM HRM_BUDGET
    WHERE BUD_YEAR = vBudYear
    AND HRM_DIVISION_ID = vDivID
    AND BUD_AUTOMATIC = 1;
    -- G�n�ration du budget
    INSERT INTO HRM_BUDGET (HRM_BUDGET_ID, BUD_YEAR, HRM_DIVISION_ID, DIC_COST_TYPE_ID, BUD_AMOUNT, BUD_AUTOMATIC, A_DATECRE, A_IDCRE)
    (
    SELECT INIT_ID_SEQ.NextVal, vBudYear, vDivID, DIC_COST_TYPE_ID, TRF_AMOUNT, 1,  SysDate, 'AUTO'
    FROM(SELECT DIC_COST_TYPE_ID, SUM(TRF_AMOUNT) TRF_AMOUNT
         FROM HRM_PERSON P, HRM_TRAINING_FORECAST TF, HRM_SUBSCRIPTION S
         WHERE TF.HRM_TRAINING_ID = S.HRM_TRAINING_ID
         AND P.HRM_PERSON_ID = S.HRM_PERSON_ID
         AND S.SUB_PLANNED = 1
         AND TO_CHAR(S.SUB_PLAN_DATE,'yyyy') = vBudYear
         AND P.DIC_DEPARTMENT_ID = vDicDept
         GROUP BY DIC_COST_TYPE_ID)
    );
    -- Mise � jour de l'info 'Est budg�t�' dans les inscriptions
    UPDATE HRM_SUBSCRIPTION SET SUB_IS_BUDGETED = 1
    WHERE SUB_PLANNED = 1
    AND TO_CHAR(SUB_PLAN_DATE,'yyyy') = vBudYear
    AND HRM_PERSON_ID in (SELECT HRM_PERSON_ID FROM HRM_PERSON WHERE DIC_DEPARTMENT_ID = vDicDept);
  end if;
end;
end hrm_budgets;
