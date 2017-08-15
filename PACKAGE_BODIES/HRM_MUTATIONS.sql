--------------------------------------------------------
--  DDL for Package Body HRM_MUTATIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_MUTATIONS" 
AS

procedure TransfertToEmpConst(vMutationLogId number, vForceInsert number,
  vElemId number, vPrecision number, vRootFrom date, vRootTo date)
is
  cursor csMutation(pMutationLogId in number) is
    SELECT EMC_NUM_VALUE, EMC_VALUE, EMC_VALUE_FROM, EMC_VALUE_TO, EMC_ACTIVE,
        c.HRM_EMPLOYEE_ID, c.HRM_CONSTANTS_ID, HRM_EMPLOYEE_CONST_ID,
        ml.HRM_EMPLOYEE_ID EmpId,
        MUT_NEW_NUM_VALUE NewNumValue, MUT_NEW_ACTIVE NewActive,
        MUT_NEW_DATE_FROM NewDateFrom, MUT_NEW_DATE_TO NewDateTo,
        MUT_OLD_NUM_VALUE OldNumValue, MUT_OLD_ACTIVE OldActive,
        MUT_OLD_DATE_FROM OldDateFrom, MUT_OLD_DATE_TO OldDateTo,
        ml.HRM_EMPLOYEE_ELEM_ID EmpElemID, To_Number(NULL) NewEmpElemID
    FROM HRM_EMPLOYEE_CONST c, HRM_MUTATION_LOG ml
    WHERE c.HRM_EMPLOYEE_CONST_ID(+) = ml.HRM_EMPLOYEE_ELEM_ID AND
        ml.HRM_MUTATION_LOG_ID = pMutationLogId;

  rMutation csMutation%rowtype;
  nError number;

  function CheckDateOverlapConst return number
  is
    tmp number := 0;
  begin
    SELECT 1 into tmp FROM DUAL
    WHERE EXISTS
        (SELECT 1 FROM HRM_EMPLOYEE_CONST c
         WHERE c.HRM_EMPLOYEE_ID = rMutation.EmpId and
           c.HRM_CONSTANTS_ID = vElemId and
           c.HRM_EMPLOYEE_CONST_ID <> nvl(rMutation.EmpElemId, 0) and
           c.HRM_EMPLOYEE_CONST_ID <> nvl(rMutation.NewEmpElemId, 0) and
           c.EMC_VALUE_FROM <= rMutation.NewDateTo and
           c.EMC_VALUE_TO >= rMutation.NewDateFrom);
    return tmp;
    exception
      when others then return 0;
  end;

begin
  open csMutation(vMutationLogId);
  fetch csMutation into rMutation;

  -- CheckErrors
  -- Suppression
  if rMutation.EmpElemId is not null and
     rMutation.hrm_employee_const_id is null then
    nError := 1;
  -- Modification
  elsif rMutation.EmpElemId is not null and
         (rMutation.OldActive <> rMutation.EMC_ACTIVE or
          rMutation.OldNumValue <> rMutation.EMC_NUM_VALUE or
          rMutation.OldDateFrom <> rMutation.EMC_VALUE_FROM or
          rMutation.OldDateTo <> rMutation.EMC_VALUE_TO or
          rMutation.EmpId <> rMutation.HRM_EMPLOYEE_ID or
          vElemId <> rMutation.HRM_CONSTANTS_ID) then
    nError := 2;
  -- Erreur de calcul
  elsif HRM_VAR.IsProvisoryCalc(rMutation.EmpId) = 1 Then
    nError := 3;
  -- Chevauchement de dates
  elsif (rMutation.EmpElemId is null or
         rMutation.OldDateFrom <> rMutation.NewDateFrom or
         rMutation.OldDateTo <> rMutation.NewDateTo) and
         CheckDateOverlapConst = 1 then
    nError := 4;
  elsif vForceInsert = 1 and
        rMutation.OldDateFrom between rMutation.NewDateFrom and rMutation.NewDateTo then
    nError := 4;
  else
    nError := 0;
  end if;

  -- Transfert
  if not nError <> 0 then
    -- Update if exists
    if rMutation.EmpElemID IS NOT NULL then
      -- Mode Insert
      if vForceInsert = 1 then
        -- 'Clôturer' Employee_Elem/Const si besoin
        if rMutation.NewDateFrom between rMutation.EMC_VALUE_FROM and rMutation.EMC_VALUE_TO then
          UPDATE HRM_EMPLOYEE_CONST
          SET EMC_VALUE_TO = rMutation.NewDateFrom - 1,
            A_DATEMOD = SysDate,
            A_IDMOD = pcs.pc_public.GetUserIni
          WHERE HRM_EMPLOYEE_CONST_ID = rMutation.EmpElemId;
        end if;
        -- Créer le nouvel enregistrement
        SELECT INIT_ID_SEQ.NEXTVAL INTO rMutation.NewEmpElemId FROM DUAL;
        INSERT INTO HRM_EMPLOYEE_CONST
          (HRM_EMPLOYEE_CONST_ID, HRM_EMPLOYEE_ID, HRM_CONSTANTS_ID,
           EMC_NUM_VALUE, EMC_VALUE_FROM, EMC_VALUE_TO,
           EMC_ACTIVE, EMC_FROM, EMC_TO, A_DATECRE, A_IDCRE)
        VALUES
          (rMutation.NewEmpElemID, rMutation.EmpID, vElemID,
           rMutation.NewNumValue, rMutation.NewDateFrom, rMutation.NewDateTo,
           rMutation.NewActive, vRootFrom, vRootTo, SysDate, pcs.pc_public.GetUserIni);
        if ExistsEmpElemBreak(rMutation.EmpElemID) = 1 then
          CreateBreakLike(rMutation.EmpElemID, rMutation.NewEmpElemID,
                          rMutation.NewNumValue, vPrecision);
        end if;
      -- Mode Replace
      else
        -- Update Employee_Elem/Const
        UPDATE HRM_EMPLOYEE_CONST
        SET EMC_NUM_VALUE = rMutation.NewNumValue,
            EMC_VALUE = NULL,
            EMC_VALUE_FROM = rMutation.NewDateFrom,
            EMC_VALUE_TO = rMutation.NewDateTo,
            EMC_ACTIVE = rMutation.NewActive,
            A_DATEMOD = SysDate,
            A_IDMOD = pcs.pc_public.GetUserIni
        WHERE HRM_EMPLOYEE_CONST_ID = rMutation.EmpElemID;
        if rMutation.EMC_NUM_VALUE <> rMutation.NewNumValue AND
           ExistsEmpElemBreak(rMutation.EmpElemID) = 1 then
          UpdateBreak(rMutation.EmpElemID, rMutation.NewNumValue, vPrecision);
        end if;
      end if;
    -- Create if not exists
    else
      SELECT INIT_ID_SEQ.NEXTVAL INTO rMutation.EmpElemId FROM DUAL;
      INSERT INTO HRM_EMPLOYEE_CONST
          (HRM_EMPLOYEE_CONST_ID, HRM_CONSTANTS_ID, HRM_EMPLOYEE_ID, EMC_NUM_VALUE, EMC_VALUE,
           EMC_VALUE_FROM, EMC_VALUE_TO, EMC_ACTIVE, EMC_FROM, EMC_TO, A_DATECRE, A_IDCRE)
      VALUES
         (rMutation.EmpElemId, vElemID, rMutation.EmpId,
          rMutation.NewNumValue, NULL, rMutation.NewDateFrom,
          rMutation.NewDateTo, rMutation.NewActive, vRootFrom, vRootTo,
          SysDate, pcs.pc_public.GetUserIni);
    end if;
    UPDATE HRM_MUTATION_LOG
    SET HRM_EMPLOYEE_ELEM_ID = rMutation.EmpElemId,
        HRM_NEW_EMPLOYEE_ELEM_ID = rMutation.NewEmpElemId,
        MUT_TRANSFER_DATE = SysDate,
        MUT_TRANSFERED = 1,
        MUT_ROLLBACK = 0,
        C_MUTATION_ERROR = NULL
    WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
  else
    UPDATE HRM_MUTATION_LOG
    SET C_MUTATION_ERROR = nError
    WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
  end if;

  Close csMutation;
end;

procedure TransfertToEmpVar(vMutationLogId number, vForceInsert number,
  vElemId number, vPrecision number, vRootFrom date, vRootTo date)
is
  cursor csMutation(pMutationLogId in number) is
    SELECT EMP_NUM_VALUE, EMP_VALUE, EMP_VALUE_FROM, EMP_VALUE_TO, EMP_ACTIVE,
        e.HRM_EMPLOYEE_ID, e.HRM_ELEMENTS_ID, HRM_EMPLOYEE_ELEMENTS_ID,
        ml.HRM_EMPLOYEE_ID EmpId, MUT_NEW_VALUE NewValue,
        MUT_NEW_NUM_VALUE NewNumValue, MUT_NEW_ACTIVE NewActive,
        MUT_NEW_DATE_FROM NewDateFrom, MUT_NEW_DATE_TO NewDateTo,
        MUT_OLD_NUM_VALUE OldNumValue, MUT_OLD_ACTIVE OldActive,
        MUT_OLD_DATE_FROM OldDateFrom, MUT_OLD_DATE_TO OldDateTo,
        ml.HRM_EMPLOYEE_ELEM_ID EmpElemID, To_Number(NULL) NewEmpElemID
    FROM HRM_EMPLOYEE_ELEMENTS e, HRM_MUTATION_LOG ml
    WHERE e.HRM_EMPLOYEE_ELEMENTS_ID(+) = ml.HRM_EMPLOYEE_ELEM_ID AND
        ml.HRM_MUTATION_LOG_ID = pMutationLogId;

  rMutation csMutation%rowtype;
  nError number;

  function CheckDateOverlapVar return number
  is
    tmp number := 0;
  begin
    SELECT 1 into tmp FROM DUAL
    WHERE EXISTS
        (SELECT 1 FROM HRM_EMPLOYEE_ELEMENTS e
         WHERE e.HRM_EMPLOYEE_ID = rMutation.EmpId and
           e.HRM_ELEMENTS_ID = vElemId and
           e.HRM_EMPLOYEE_ELEMENTS_ID <> nvl(rMutation.EmpElemId,0) and
           e.HRM_EMPLOYEE_ELEMENTS_ID <> nvl(rMutation.NewEmpElemId, 0) and
           e.EMP_VALUE_FROM <= rMutation.NewDateTo and
           e.EMP_VALUE_TO >= rMutation.NewDateFrom);
    return tmp;
    exception
      when others then return 0;
  end;

begin
  open csMutation(vMutationLogId);
  fetch csMutation into rMutation;

  -- CheckErrors
  -- Suppression
  if rMutation.EmpElemId is not null and
     rMutation.hrm_employee_elements_id is null then
    nError := 1;
  -- Modification
  elsif rMutation.EmpElemId is not null and
         (rMutation.OldActive <> rMutation.EMP_ACTIVE or
          rMutation.OldNumValue <> rMutation.EMP_NUM_VALUE or
          rMutation.OldDateFrom <> rMutation.EMP_VALUE_FROM or
          rMutation.OldDateTo <> rMutation.EMP_VALUE_TO or
          rMutation.EmpId <> rMutation.HRM_EMPLOYEE_ID or
          vElemId <> rMutation.HRM_ELEMENTS_ID) then
    nError := 2;
  -- Erreur de calcul
  elsif HRM_VAR.IsProvisoryCalc(rMutation.EmpId) = 1 Then
    nError := 3;
  -- Chevauchement de dates
  elsif (rMutation.EmpElemId is null or
         rMutation.OldDateFrom <> rMutation.NewDateFrom or
         rMutation.OldDateTo <> rMutation.NewDateTo) and
         CheckDateOverlapVar = 1 then
    nError := 4;
  elsif vForceInsert = 1 and
        rMutation.OldDateFrom between rMutation.NewDateFrom and rMutation.NewDateTo then
    nError := 4;
  else
    nError := 0;
  end if;

  -- Transfert
  if not nError <> 0 then
    -- Update if exists
    if rMutation.EmpElemID IS NOT NULL then
      -- Mode Insert
      if vForceInsert = 1 then
        -- 'Clôturer' Employee_Elem/Const si besoin
        if rMutation.NewDateFrom between rMutation.EMP_VALUE_FROM and rMutation.EMP_VALUE_TO then
          UPDATE HRM_EMPLOYEE_ELEMENTS
          SET EMP_VALUE_TO = rMutation.NewDateFrom - 1,
            A_DATEMOD = SysDate,
            A_IDMOD = pcs.pc_public.GetUserIni
          WHERE HRM_EMPLOYEE_ELEMENTS_ID = rMutation.EmpElemId;
        end if;
        -- Créer le nouvel enregistrement
        SELECT INIT_ID_SEQ.NEXTVAL INTO rMutation.NewEmpElemId FROM DUAL;
        INSERT INTO HRM_EMPLOYEE_ELEMENTS
          (HRM_EMPLOYEE_ELEMENTS_ID, HRM_EMPLOYEE_ID, HRM_ELEMENTS_ID,
           EMP_NUM_VALUE, EMP_VALUE, EMP_VALUE_FROM, EMP_VALUE_TO,
           EMP_ACTIVE, EMP_FROM, EMP_TO, A_DATECRE, A_IDCRE)
        VALUES
          (rMutation.NewEmpElemID, rMutation.EmpID, vElemID,
           rMutation.NewNumValue, rMutation.NewValue,
           rMutation.NewDateFrom, rMutation.NewDateTo, rMutation.NewActive,
           vRootFrom, vRootTo, SysDate, pcs.pc_public.GetUserIni);
        if ExistsEmpElemBreak(rMutation.EmpElemID) = 1 then
          CreateBreakLike(rMutation.EmpElemID, rMutation.NewEmpElemID,
                          rMutation.NewNumValue, vPrecision);
        end if;
      -- Mode Replace
      else
        -- Update Employee_Elem/Const
        UPDATE HRM_EMPLOYEE_ELEMENTS
        SET EMP_NUM_VALUE = rMutation.NewNumValue,
            EMP_VALUE = rMutation.NewValue,
            EMP_VALUE_FROM = rMutation.NewDateFrom,
            EMP_VALUE_TO = rMutation.NewDateTo,
            EMP_ACTIVE = rMutation.NewActive,
            A_DATEMOD = SysDate,
            A_IDMOD = pcs.pc_public.GetUserIni
        WHERE HRM_EMPLOYEE_ELEMENTS_ID = rMutation.EmpElemID;
        if rMutation.EMP_NUM_VALUE <> rMutation.NewNumValue AND
           ExistsEmpElemBreak(rMutation.EmpElemID) = 1 then
          UpdateBreak(rMutation.EmpElemID, rMutation.NewNumValue, vPrecision);
        end if;
      end if;
    -- Create if not exists
    else
      SELECT INIT_ID_SEQ.NEXTVAL INTO rMutation.EmpElemId FROM DUAL;
      INSERT INTO HRM_EMPLOYEE_ELEMENTS
          (HRM_EMPLOYEE_ELEMENTS_ID, HRM_ELEMENTS_ID, HRM_EMPLOYEE_ID,
           EMP_NUM_VALUE, EMP_VALUE, EMP_VALUE_FROM, EMP_VALUE_TO, EMP_ACTIVE,
           EMP_FROM, EMP_TO, A_DATECRE, A_IDCRE)
      VALUES
         (rMutation.EmpElemId, vElemID, rMutation.EmpID,
          rMutation.NewNumValue, rMutation.NewValue,
          rMutation.NewDateFrom, rMutation.NewDateTo, rMutation.NewActive,
          vRootFrom, vRootTo, SysDate, pcs.pc_public.GetUserIni);
    end if;
    UPDATE HRM_MUTATION_LOG
    SET HRM_EMPLOYEE_ELEM_ID = rMutation.EmpElemId,
        HRM_NEW_EMPLOYEE_ELEM_ID = rMutation.NewEmpElemId,
        MUT_TRANSFER_DATE = SysDate,
        MUT_TRANSFERED = 1,
        MUT_ROLLBACK = 0,
        C_MUTATION_ERROR = NULL
    WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
  else
    UPDATE HRM_MUTATION_LOG
    SET C_MUTATION_ERROR = nError
    WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
  end if;

  Close csMutation;
end;

procedure RollBackEmpConst(vMutationLogId number, vElemId number, vPrecision number)
is
  cursor csMutation(pMutationLogId in number) is
    SELECT EMC_NUM_VALUE, EMC_VALUE_FROM, EMC_VALUE_TO, EMC_ACTIVE,
        c.HRM_EMPLOYEE_ID, c.HRM_CONSTANTS_ID, HRM_EMPLOYEE_CONST_ID,
        ml.HRM_EMPLOYEE_ID EmpId,
        MUT_NEW_NUM_VALUE NewNumValue, MUT_NEW_ACTIVE NewActive,
        MUT_NEW_DATE_FROM NewDateFrom, MUT_NEW_DATE_TO NewDateTo,
        MUT_OLD_NUM_VALUE OldNumValue, MUT_OLD_ACTIVE OldActive,
        MUT_OLD_DATE_FROM OldDateFrom, MUT_OLD_DATE_TO OldDateTo,
        MUT_OLD_VALUE OldValue,
        ml.HRM_EMPLOYEE_ELEM_ID EmpElemID, ml.HRM_NEW_EMPLOYEE_ELEM_ID NewEmpElemID
    FROM HRM_EMPLOYEE_CONST c, HRM_MUTATION_LOG ml
    WHERE c.HRM_EMPLOYEE_CONST_ID(+) = ml.HRM_EMPLOYEE_ELEM_ID AND
        ml.HRM_MUTATION_LOG_ID = pMutationLogId;

  rMutation csMutation%rowtype;
  nError number;

  function CheckDateOverlapConst return number
  is
    tmp number := 0;
  begin
    SELECT 1 into tmp FROM DUAL
    WHERE EXISTS
        (SELECT 1 FROM HRM_EMPLOYEE_CONST c
         WHERE c.HRM_EMPLOYEE_ID = rMutation.EmpId and
           c.HRM_CONSTANTS_ID = vElemId and
           c.HRM_EMPLOYEE_CONST_ID <> nvl(rMutation.EmpElemId, 0) and
           c.HRM_EMPLOYEE_CONST_ID <> nvl(rMutation.NewEmpElemId, 0) and
           c.EMC_VALUE_FROM <= rMutation.OldDateTo and
           c.EMC_VALUE_TO >= rMutation.OldDateFrom);
    return tmp;
    exception
      when others then return 0;
  end;

begin
  open csMutation(vMutationLogId);
  fetch csMutation into rMutation;

  -- CheckErrors
  -- Suppression
  if rMutation.HRM_EMPLOYEE_CONST_ID is null then
    nError := 1;
  -- Modification
  elsif rMutation.NewEmpElemId is null and
        (rMutation.NewActive <> rMutation.EMC_ACTIVE or
         rMutation.NewNumValue <> rMutation.EMC_NUM_VALUE or
         rMutation.NewDateFrom <> rMutation.EMC_VALUE_FROM or
         rMutation.NewDateTo <> rMutation.EMC_VALUE_TO or
         rMutation.EmpId <> rMutation.HRM_EMPLOYEE_ID or
         vElemId <> rMutation.HRM_CONSTANTS_ID) then
    nError := 2;
  elsif rMutation.NewEmpElemId is not null and
        (rMutation.OldActive <> rMutation.EMC_ACTIVE or
         rMutation.OldNumValue <> rMutation.EMC_NUM_VALUE or
         rMutation.OldDateFrom <> rMutation.EMC_VALUE_FROM or
         (rMutation.OldDateTo <> rMutation.EMC_VALUE_TO and
          rMutation.NewDateFrom - 1 <> rMutation.EMC_VALUE_TO) or
         rMutation.EmpId <> rMutation.HRM_EMPLOYEE_ID or
         vElemId <> rMutation.HRM_CONSTANTS_ID) then
    nError := 2;
  -- Erreur de calcul
  elsif HRM_VAR.IsProvisoryCalc(rMutation.EmpId) = 1 Then
    nError := 3;
  -- Chevauchement de dates
  elsif (rMutation.OldDateFrom <> rMutation.NewDateFrom or
         rMutation.OldDateTo <> rMutation.NewDateTo) and
         CheckDateOverlapConst = 1 then
    nError := 4;
  else
    nError := 0;
  end if;

  -- RollBack de EmployeeConst
  if not nError <> 0 then
    if (rMutation.OldNumValue is not null) or (rMutation.OldValue is not null) then
      UPDATE HRM_EMPLOYEE_CONST
      SET EMC_NUM_VALUE = rMutation.OldNumValue,
          EMC_VALUE = rMutation.OldValue,
          EMC_VALUE_FROM = rMutation.OldDateFrom,
          EMC_VALUE_TO = rMutation.OldDateTo,
          EMC_ACTIVE = rMutation.OldActive,
          A_DATEMOD = SysDate,
          A_IDMOD = pcs.pc_public.GetUserIni
      WHERE HRM_EMPLOYEE_CONST_ID = rMutation.EmpElemId;
      -- Mode insertion
      if rMutation.NewEmpElemId is not null then
        DELETE HRM_EMPLOYEE_CONST WHERE HRM_EMPLOYEE_CONST_ID = rMutation.NewEmpElemID;
        DELETE HRM_EMPLOYEE_ELEM_BREAK WHERE HRM_EMP_ELEMENTS_ID = rMutation.NewEmpElemID;
      -- Mode replace
      elsif ExistsEmpElemBreak(rMutation.EmpElemID) = 1 then
        UpdateBreak(rMutation.EmpElemID, rMutation.OldNumValue, vPrecision);
      end if;
      -- RollBack de la mutation
      UPDATE HRM_MUTATION_LOG
      SET MUT_TRANSFERED = 0,
          MUT_ROLLBACK = 1,
          C_MUTATION_ERROR_ROLLBACK = NULL,
          MUT_TRANSFER_DATE = NULL,
          HRM_NEW_EMPLOYEE_ELEM_ID = NULL
      WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
    else
      -- ou si Insert...
      DELETE HRM_EMPLOYEE_CONST WHERE HRM_EMPLOYEE_CONST_ID = rMutation.EmpElemID;
      DELETE HRM_EMPLOYEE_ELEM_BREAK WHERE HRM_EMP_ELEMENTS_ID = rMutation.EmpElemID;
      -- RollBack de la mutation
      UPDATE HRM_MUTATION_LOG
      SET MUT_TRANSFERED = 0,
          MUT_ROLLBACK = 1,
          C_MUTATION_ERROR_ROLLBACK = NULL,
          MUT_TRANSFER_DATE = NULL,
          HRM_EMPLOYEE_ELEM_ID = NULL
      WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
    end if;
  else
    UPDATE HRM_MUTATION_LOG
    SET C_MUTATION_ERROR_ROLLBACK = nError
    WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
  end if;

  Close csMutation;
end;

procedure RollBackEmpVar(vMutationLogId number, vElemId number, vPrecision number)
is
  cursor csMutation(pMutationLogId in number) is
    SELECT EMP_NUM_VALUE, EMP_VALUE_FROM, EMP_VALUE_TO, EMP_ACTIVE,
        e.HRM_EMPLOYEE_ID, e.HRM_ELEMENTS_ID, HRM_EMPLOYEE_ELEMENTS_ID,
        ml.HRM_EMPLOYEE_ID EmpId,
        MUT_NEW_NUM_VALUE NewNumValue, MUT_NEW_ACTIVE NewActive,
        MUT_NEW_DATE_FROM NewDateFrom, MUT_NEW_DATE_TO NewDateTo,
        MUT_OLD_NUM_VALUE OldNumValue, MUT_OLD_ACTIVE OldActive,
        MUT_OLD_DATE_FROM OldDateFrom, MUT_OLD_DATE_TO OldDateTo,
        MUT_OLD_VALUE OldValue,
        ml.HRM_EMPLOYEE_ELEM_ID EmpElemID, ml.HRM_NEW_EMPLOYEE_ELEM_ID NewEmpElemID
    FROM HRM_EMPLOYEE_ELEMENTS e, HRM_MUTATION_LOG ml
    WHERE e.HRM_EMPLOYEE_ELEMENTS_ID(+) = ml.HRM_EMPLOYEE_ELEM_ID AND
        ml.HRM_MUTATION_LOG_ID = pMutationLogId;

  rMutation csMutation%rowtype;
  nError number;

  function CheckDateOverlapVar return number
  is
    tmp number := 0;
  begin
    SELECT 1 into tmp FROM DUAL
    WHERE EXISTS
        (SELECT 1 FROM HRM_EMPLOYEE_ELEMENTS e
         WHERE e.HRM_EMPLOYEE_ID = rMutation.EmpId and
           e.HRM_ELEMENTS_ID = vElemId and
           e.HRM_EMPLOYEE_ELEMENTS_ID <> nvl(rMutation.EmpElemId,0) and
           e.HRM_EMPLOYEE_ELEMENTS_ID <> nvl(rMutation.NewEmpElemId, 0) and
           e.EMP_VALUE_FROM <= rMutation.OldDateTo and
           e.EMP_VALUE_TO >= rMutation.OldDateFrom);
    return tmp;
    exception
      when others then return 0;
  end;

begin
  open csMutation(vMutationLogId);
  fetch csMutation into rMutation;

  -- CheckErrors
  -- Suppression
  if rMutation.HRM_EMPLOYEE_ELEMENTS_ID is null then
    nError := 1;
  -- Modification
  elsif rMutation.NewEmpElemId is null and
        (rMutation.NewActive <> rMutation.EMP_ACTIVE or
         rMutation.NewNumValue <> rMutation.EMP_NUM_VALUE or
         rMutation.NewDateFrom <> rMutation.EMP_VALUE_FROM or
         rMutation.NewDateTo <> rMutation.EMP_VALUE_TO or
         rMutation.EmpId <> rMutation.HRM_EMPLOYEE_ID or
         vElemId <> rMutation.HRM_ELEMENTS_ID) then
    nError := 2;
  elsif rMutation.NewEmpElemId is not null and
        (rMutation.OldActive <> rMutation.EMP_ACTIVE or
         rMutation.OldNumValue <> rMutation.EMP_NUM_VALUE or
         rMutation.OldDateFrom <> rMutation.EMP_VALUE_FROM or
         (rMutation.OldDateTo <> rMutation.EMP_VALUE_TO and
          rMutation.NewDateFrom - 1 <> rMutation.EMP_VALUE_TO) or
         rMutation.EmpId <> rMutation.HRM_EMPLOYEE_ID or
         vElemId <> rMutation.HRM_ELEMENTS_ID) then
    nError := 2;
  -- Erreur de calcul
  elsif HRM_VAR.IsProvisoryCalc(rMutation.EmpId) = 1 Then
    nError := 3;
  -- Chevauchement de dates
  elsif (rMutation.OldDateFrom <> rMutation.NewDateFrom or
         rMutation.OldDateTo <> rMutation.NewDateTo) and
         CheckDateOverlapVar = 1 then
    nError := 4;
  else
    nError := 0;
  end if;

  -- RollBack de EmployeeConst
  if not nError <> 0 then
    if (rMutation.OldNumValue is not null) or (rMutation.OldValue is not null) then
      UPDATE HRM_EMPLOYEE_ELEMENTS
      SET EMP_NUM_VALUE = rMutation.OldNumValue,
          EMP_VALUE = rMutation.OldValue,
          EMP_VALUE_FROM = rMutation.OldDateFrom,
          EMP_VALUE_TO = rMutation.OldDateTo,
          EMP_ACTIVE = rMutation.OldActive,
          A_DATEMOD = SysDate,
          A_IDMOD = pcs.pc_public.GetUserIni
      WHERE HRM_EMPLOYEE_ELEMENTS_ID = rMutation.EmpElemId;
      -- Mode insertion
      if rMutation.NewEmpElemId is not null then
        DELETE HRM_EMPLOYEE_ELEMENTS WHERE HRM_EMPLOYEE_ELEMENTS_ID = rMutation.NewEmpElemID;
        DELETE HRM_EMPLOYEE_ELEM_BREAK WHERE HRM_EMP_ELEMENTS_ID = rMutation.NewEmpElemID;
      -- Mode replace
      elsif ExistsEmpElemBreak(rMutation.EmpElemID) = 1 then
        UpdateBreak(rMutation.EmpElemID, rMutation.OldNumValue, vPrecision);
      end if;
      -- RollBack de la mutation
      UPDATE HRM_MUTATION_LOG
      SET MUT_TRANSFERED = 0,
          MUT_ROLLBACK = 1,
          C_MUTATION_ERROR_ROLLBACK = NULL,
          MUT_TRANSFER_DATE = NULL,
          HRM_NEW_EMPLOYEE_ELEM_ID = NULL
      WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
    else
      -- ou si Insert...
      DELETE HRM_EMPLOYEE_ELEMENTS WHERE HRM_EMPLOYEE_ELEMENTS_ID = rMutation.EmpElemID;
      DELETE HRM_EMPLOYEE_ELEM_BREAK WHERE HRM_EMP_ELEMENTS_ID = rMutation.EmpElemID;
      -- RollBack de la mutation
      UPDATE HRM_MUTATION_LOG
      SET MUT_TRANSFERED = 0,
          MUT_ROLLBACK = 1,
          C_MUTATION_ERROR_ROLLBACK = NULL,
          MUT_TRANSFER_DATE = NULL,
          HRM_EMPLOYEE_ELEM_ID = NULL
      WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
    end if;
  else
    UPDATE HRM_MUTATION_LOG
    SET C_MUTATION_ERROR_ROLLBACK = nError
    WHERE HRM_MUTATION_LOG_ID = vMutationLogId;
  end if;

  Close csMutation;
end;

procedure UpdateBreak(vEmpElemId number, vNewValue number, vPrecision number)
is
begin
  UPDATE HRM_EMPLOYEE_ELEM_BREAK
  SET EEB_BASE_AMOUNT = vNewValue,
      EEB_VALUE = ROUND((vNewValue * EEB_PER_RATE / 100) / vPrecision) * vPrecision
  WHERE HRM_EMP_ELEMENTS_ID = vEmpElemId;

  UPDATE HRM_EMPLOYEE_ELEM_BREAK
  SET EEB_VALUE = (SELECT vNewValue - SUM(EEB_VALUE)
                   FROM HRM_EMPLOYEE_ELEM_BREAK
                   WHERE HRM_EMP_ELEMENTS_ID = vEmpElemId)
  WHERE HRM_EMPLOYEE_ELEM_BREAK_ID =
            (SELECT MAX(HRM_EMPLOYEE_ELEM_BREAK_ID)
              FROM HRM_EMPLOYEE_ELEM_BREAK
              WHERE HRM_EMP_ELEMENTS_ID = vEmpElemId
              HAVING vNewValue - SUM(EEB_VALUE) <> 0);
end;

procedure CreateBreakLike(vEmpElemId number, vNewEmpElemId number,
  vNewValue number, vPrecision number)
is
begin
  INSERT INTO HRM_EMPLOYEE_ELEM_BREAK
    (HRM_EMPLOYEE_ELEM_BREAK_ID, HRM_PERSON_ID, HRM_ELEMENTS_ID,
     HRM_EMP_ELEMENTS_ID, EEB_SERIAL, EEB_TIME_RATIO, EEB_BASE_AMOUNT,
     EEB_RATE, EEB_PER_RATE, EEB_VALUE, EEB_RATIO_GROUP, DIC_DEPARTMENT_ID,
     HRM_JOB_ID, EEB_IS_BREAK_DEBIT, EEB_IS_BREAK_CREDIT, EEB_D_CGBASE,
     EEB_C_CGBASE, EEB_DIVBASE, EEB_CPNBASE, EEB_CDABASE, EEB_PFBASE,
     EEB_PJBASE, EEB_IS_ACTIVE, EEB_SHIFT, A_DATECRE, A_IDCRE)
  SELECT
    INIT_ID_SEQ.NextVal, HRM_PERSON_ID, HRM_ELEMENTS_ID,
    vNewEmpElemId, EEB_SERIAL, EEB_TIME_RATIO, vNewValue EEB_BASE_AMOUNT,
    EEB_RATE, EEB_PER_RATE,
    ROUND((vNewValue * EEB_PER_RATE / 100) / vPrecision) * vPrecision EEB_VALUE,
    EEB_RATIO_GROUP, DIC_DEPARTMENT_ID,
    HRM_JOB_ID, EEB_IS_BREAK_DEBIT, EEB_IS_BREAK_CREDIT, EEB_D_CGBASE,
    EEB_C_CGBASE, EEB_DIVBASE, EEB_CPNBASE, EEB_CDABASE, EEB_PFBASE,
    EEB_PJBASE, EEB_IS_ACTIVE, EEB_SHIFT, SysDate, pcs.pc_public.GetUserIni
  FROM
    HRM_EMPLOYEE_ELEM_BREAK
  WHERE HRM_EMP_ELEMENTS_ID = vEmpElemId;

  UPDATE HRM_EMPLOYEE_ELEM_BREAK
  SET EEB_VALUE = (SELECT vNewValue - SUM(EEB_VALUE)
                   FROM HRM_EMPLOYEE_ELEM_BREAK
                   WHERE HRM_EMP_ELEMENTS_ID = vEmpElemId)
  WHERE HRM_EMPLOYEE_ELEM_BREAK_ID =
            (SELECT MAX(HRM_EMPLOYEE_ELEM_BREAK_ID)
             FROM HRM_EMPLOYEE_ELEM_BREAK
             WHERE HRM_EMP_ELEMENTS_ID = vNewEmpElemId
             HAVING vNewValue - SUM(EEB_VALUE) <> 0);
end;

function ExistsEmpElemBreak(vEmpElemId number) return number
is
 tmp number;
begin
  SELECT 1 into tmp FROM DUAL
  WHERE EXISTS
     (SELECT 1 FROM HRM_EMPLOYEE_ELEM_BREAK WHERE HRM_EMP_ELEMENTS_ID = vEmpElemId);
  return tmp;
  exception
    when others then return 0;
end;

end hrm_mutations;
