--------------------------------------------------------
--  DDL for Package Body FAL_TASK_LIST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_TASK_LIST" 
is
  procedure GenerateLMU(
    FalScheduleStepId TYPE_ID
  , MachineGruppeId   TYPE_ID
  , ScsWorkTime       FAL_LIST_STEP_LINK.SCS_WORK_TIME%type
  , ScsQtyRefWork     FAL_LIST_STEP_LINK.SCS_QTY_REF_WORK%type
  )
  is
  begin
    insert into FAL_LIST_STEP_USE
                (FAL_LIST_STEP_USE_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_FACTORY_FLOOR_ID
               , LSU_WORK_TIME
               , LSU_QTY_REF_WORK
               , LSU_PRIORITY
               , LSU_EXCEPT_MACH
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , FalScheduleStepId
           , FAL_FACTORY_FLOOR_ID
           , ScsWorkTime
           , ScsQtyRefWork
           , 0
           , 0
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_FACTORY_FLOOR FFF
       where FAL_FAL_FACTORY_FLOOR_ID = MachineGruppeId
         and FAL_FACTORY_FLOOR_ID not in(select FAL_FACTORY_FLOOR_ID
                                           from FAL_LIST_STEP_USE
                                          where FAL_FACTORY_FLOOR_ID = FFF.FAL_FACTORY_FLOOR_ID
                                            and FAL_SCHEDULE_STEP_ID = FalScheduleStepId);
  end;

  procedure Duplicate_LMU_On_Dupl_Gamme(OLDFalScheduleStepId TYPE_ID, NEWFalScheduleStepId TYPE_ID)
  is
    -- Déclaration des curseurs
    cursor crLMU
    is
      select *
        from FAL_LIST_STEP_USE
       where FAL_SCHEDULE_STEP_ID = OLDFalScheduleStepId;
  begin
    -- Pour Chaque Machine Utilisable de l'opération
    for tplLMU in crLMU loop
      insert into FAL_LIST_STEP_USE
                  (FAL_LIST_STEP_USE_ID
                 , FAL_SCHEDULE_STEP_ID
                 , FAL_FACTORY_FLOOR_ID
                 , LSU_WORK_TIME
                 , LSU_QTY_REF_WORK
                 , LSU_PRIORITY
                 , LSU_EXCEPT_MACH
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , NEWFalScheduleStepId
                 , tplLMU.FAL_FACTORY_FLOOR_ID
                 , tplLMU.LSU_WORK_TIME
                 , tplLMU.LSU_QTY_REF_WORK
                 , tplLMU.LSU_PRIORITY
                 , tplLMU.LSU_EXCEPT_MACH
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end;

-- Passage du code Planif 2->3 de la gamme passée en paramètre. Si NULL Toutes les gammes
  procedure PassageCodePlanif2to3(PrmFAL_SCHEDULE_PLAN_ID TYPE_ID)
  is
    -- Curseur pour parcourir les gammes opératoires
    cursor Cgamme
    is
      select     *
            from FAL_SCHEDULE_PLAN
           where (FAL_SCHEDULE_PLAN_ID = PrmFAL_SCHEDULE_PLAN_ID)
              or (PrmFAL_SCHEDULE_PLAN_ID is null)
      for update;

    cursor Coper(PrmGammeEnCours TYPE_ID)
    is
      select     *
            from FAL_LIST_STEP_LINK
           where FAL_SCHEDULE_PLAN_ID = PrmGammeEnCours
      for update;

    EGamme CGamme%rowtype;
    EOper  Coper%rowtype;
  begin
    -- Parcours des Gammes;
    open CGamme;

    loop
      fetch CGamme
       into EGamme;

      exit when CGamme%notfound;
      DBMS_OUTPUT.put_line('Gamme : ' || EGamme.FAL_SCHEDULE_PLAN_ID);

      if EGamme.C_SCHEDULE_PLANNING = 2 then
        -- On passa la gamme en code 3
        update FAL_SCHEDULE_PLAN
           set C_SCHEDULE_PLANNING = 3
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where current of CGamme;

        -- Parcours des OP de la gamme et modif selon le code imputation;
        open Coper(Egamme.FAL_SCHEDULE_PLAN_ID);

        loop
          fetch Coper
           into EOper;

          exit when Coper%notfound;

          if eOper.C_TASK_IMPUTATION = 1 then   -- Mach. et M.O. = réglage + Travail
            update FAL_LIST_STEP_LINK
               set SCS_ADJUSTING_FLOOR = 1
                 , SCS_ADJUSTING_OPERATOR = 1
                 , SCS_NUM_ADJUST_OPERATOR = 1
                 , SCS_PERCENT_ADJUST_OPER = 100
                 , SCS_WORK_FLOOR = 1
                 , SCS_WORK_OPERATOR = 1
                 , SCS_NUM_WORK_OPERATOR = 1
                 , SCS_PERCENT_WORK_OPER = 100
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where current of COper;
          elsif eOper.C_TASK_IMPUTATION = 2 then   -- Mach. = Travail/M.O. = réglage
            update FAL_LIST_STEP_LINK
               set SCS_ADJUSTING_FLOOR = 0
                 , SCS_ADJUSTING_OPERATOR = 1
                 , SCS_NUM_ADJUST_OPERATOR = 1
                 , SCS_PERCENT_ADJUST_OPER = 100
                 , SCS_WORK_FLOOR = 1
                 , SCS_WORK_OPERATOR = 0
                 , SCS_NUM_WORK_OPERATOR = 0
                 , SCS_PERCENT_WORK_OPER = 0
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where current of COper;
          elsif eOper.C_TASK_IMPUTATION = 3 then   -- Mach. = Travail/M.O. = Réglage + travail
            update FAL_LIST_STEP_LINK
               set SCS_ADJUSTING_FLOOR = 0
                 , SCS_ADJUSTING_OPERATOR = 1
                 , SCS_NUM_ADJUST_OPERATOR = 1
                 , SCS_PERCENT_ADJUST_OPER = 100
                 , SCS_WORK_FLOOR = 1
                 , SCS_WORK_OPERATOR = 1
                 , SCS_NUM_WORK_OPERATOR = 1
                 , SCS_PERCENT_WORK_OPER = 100
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where current of COper;
          elsif eOper.C_TASK_IMPUTATION = 4 then   -- Mach. = réglage + travail/M.O. = réglage
            update FAL_LIST_STEP_LINK
               set SCS_ADJUSTING_FLOOR = 1
                 , SCS_ADJUSTING_OPERATOR = 1
                 , SCS_NUM_ADJUST_OPERATOR = 1
                 , SCS_PERCENT_ADJUST_OPER = 100
                 , SCS_WORK_FLOOR = 1
                 , SCS_WORK_OPERATOR = 0
                 , SCS_NUM_WORK_OPERATOR = 0
                 , SCS_PERCENT_WORK_OPER = 100
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where current of COper;
          end if;
        end loop;

        close Coper;
      -- Fin de Parcours des OP de la gamme;
      end if;
    end loop;

    close CGamme;
  -- Fin de Parcours des gammes opératoires;
  end;
end;
