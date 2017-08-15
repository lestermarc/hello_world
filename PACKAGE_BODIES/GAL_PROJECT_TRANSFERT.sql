--------------------------------------------------------
--  DDL for Package Body GAL_PROJECT_TRANSFERT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PROJECT_TRANSFERT" 
is
  procedure TransfertSelectedData(inGAL_PROJECT_ID1 in GAL_PROJECT.GAL_PROJECT_ID%type, inGAL_PROJECT_ID2 in GAL_PROJECT.GAL_PROJECT_ID%type)
  is
    lnGAL_TASK_ID   GAL_TASK.GAL_TASK_ID%type;
    lvTAS_CODE      GAL_TASK.TAS_CODE%type;
    lnGAL_BUDGET_ID GAL_BUDGET.GAL_BUDGET_ID%type;
    lvBDG_CODE      GAL_BUDGET.BDG_CODE%type;

    cursor curBUD_TRANSFERT
    is
      select DUP.GAL_BUDGET_ID
           , (trim(GBD_PREFIX) || BDG_CODE) BDG_CODE
        from GAL_BUDGET_DUPLICATE DUP;

    cursor curTASK_TRANSFERT
    is
      select DUP.GAL_TASK_ID
           , (trim(GTD_PREFIX) || TAS_CODE) TAS_CODE
        from GAL_TASK_DUPLICATE DUP;
  begin
    -- mise à jour selon l'identifiant des budgets sélectionnés
    begin
      open curBUD_TRANSFERT;

      loop
        fetch curBUD_TRANSFERT
         into lnGAL_BUDGET_ID
            , lvBDG_CODE;

        exit when curBUD_TRANSFERT%notfound;
        UpdateBudgetProject(lnGAL_BUDGET_ID, lvBDG_CODE, inGAL_PROJECT_ID1, inGAL_PROJECT_ID2);
      end loop;

      close curBUD_TRANSFERT;

      open curBUD_TRANSFERT;

      loop
        fetch curBUD_TRANSFERT
         into lnGAL_BUDGET_ID
            , lvBDG_CODE;

        exit when curBUD_TRANSFERT%notfound;

        update GAL_BUDGET
           set GAL_FATHER_BUDGET_ID = null
         where GAL_FATHER_BUDGET_ID is not null
           and not exists(select GAL_BUDGET_ID
                            from GAL_BUDGET B
                           where GAL_BUDGET.GAL_FATHER_BUDGET_ID = B.GAL_BUDGET_ID
                             and GAL_BUDGET.GAL_PROJECT_ID = B.GAL_PROJECT_ID)
           and GAL_BUDGET_ID = lnGAL_BUDGET_ID;
      end loop;

      close curBUD_TRANSFERT;
    end;

    -- mise à jour selon l'identifiant des tâches sélectionnées
    begin
      open curTASK_TRANSFERT;

      loop
        fetch curTASK_TRANSFERT
         into lnGAL_TASK_ID
            , lvTAS_CODE;

        exit when curTASK_TRANSFERT%notfound;
        UpdateTaskProject(lnGAL_TASK_ID, lvTAS_CODE, inGAL_PROJECT_ID1, inGAL_PROJECT_ID2);
      end loop;

      close curTASK_TRANSFERT;

      update GAL_TASK
         set GAL_FATHER_TASK_ID = null
       where GAL_FATHER_TASK_ID is not null
         and not exists(select GAL_TASK_ID
                          from GAL_TASK B
                         where GAL_TASK.GAL_FATHER_TASK_ID = B.GAL_TASK_ID
                           and GAL_TASK.GAL_PROJECT_ID = B.GAL_PROJECT_ID)
         and GAL_TASK_ID = lnGAL_TASK_ID;
    end;
  end TransfertSelectedData;

  procedure TransfertBudgetData(inGAL_BUDGET_ID in GAL_BUDGET.GAL_BUDGET_ID%type, inGAL_PROJECT_ID2 in GAL_PROJECT.GAL_PROJECT_ID%type, inPrefix in varchar2)
  is
    lnGAL_PROJECT_ID GAL_PROJECT.GAL_PROJECT_ID%type;
  begin
    delete from GAL_BUDGET_DUPLICATE;

    delete from GAL_TASK_DUPLICATE;

    select GAL_PROJECT_ID
      into lnGAL_PROJECT_ID
      from GAL_BUDGET
     where GAL_BUDGET_ID = inGAL_BUDGET_ID;

    insert into GAL_BUDGET_DUPLICATE BDD
                (BDD.GAL_BUDGET_ID
               , BDD.GBD_PREFIX
               , BDD.BDG_CODE
               , BDD.BDG_WORDING
               , BDD.A_DATECRE
               , BDD.A_IDCRE
               , BDD.GBD_DUPLICATE_FATHERS
               , BDD.GBD_DUPLICATE_SONS
                )
      (select distinct GAL_BUDGET_ID
                     , inPREFIX
                     , BDG_CODE
                     , BDG_WORDING
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GETUSERINI
                     , 0
                     , 1
                  from (select GAL_BUDGET_ID
                             , BDG_CODE
                             , BDG_WORDING
                          from GAL_BUDGET
                         where GAL_BUDGET_ID = inGAL_BUDGET_ID
                        union
                        select     GAL_BUDGET_ID
                                 , BDG_CODE
                                 , BDG_WORDING
                              from GAL_BUDGET
                        connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
                        start with GAL_FATHER_BUDGET_ID = inGAL_BUDGET_ID) A
                 where not exists(select GAL_BUDGET_ID
                                    from GAL_BUDGET_DUPLICATE B
                                   where A.GAL_BUDGET_ID = B.GAL_BUDGET_ID) );

    insert into GAL_TASK_DUPLICATE
                (GAL_TASK_ID
               , TAS_CODE
               , TAS_WORDING
               , A_DATECRE
               , A_IDCRE
               , GTD_PREFIX
                )
      select distinct GAL_TASK_ID
                    , TAS_CODE
                    , TAS_WORDING
                    , sysdate
                    , PCS.PC_I_LIB_SESSION.GETUSERINI
                    , inPREFIX
                 from (   -- DF liés aux tâches
                       select T1.GAL_TASK_ID
                            , TAS_CODE
                            , TAS_WORDING
                         from GAL_TASK T1
                        where T1.GAL_FATHER_TASK_ID in(select GAL_TASK_ID
                                                         from GAL_TASK
                                                        where GAL_BUDGET_ID in(select GAL_BUDGET_ID
                                                                                 from GAL_BUDGET_DUPLICATE) )
                       union all
                       select GAL_TASK_ID
                            , TAS_CODE
                            , TAS_WORDING
                         from GAL_TASK
                        where GAL_BUDGET_ID in(select GAL_BUDGET_ID
                                                 from GAL_BUDGET_DUPLICATE) );

    TransfertSelectedData(lnGAL_PROJECT_ID, inGAL_PROJECT_ID2);
  end TransfertBudgetData;

  procedure UpdateBudgetProject(
    inGAL_BUDGET_ID   in GAL_BUDGET.GAL_BUDGET_ID%type
  , inBDG_CODE        in GAL_BUDGET.BDG_CODE%type
  , inGAL_PROJECT_ID1 in GAL_PROJECT.GAL_PROJECT_ID%type
  , inGAL_PROJECT_ID2 in GAL_PROJECT.GAL_PROJECT_ID%type
  )
  is
  begin
    if inGAL_PROJECT_ID1 <> inGAL_PROJECT_ID2 then
      update GAL_BUDGET
         set GAL_PROJECT_ID = inGAL_PROJECT_ID2
           , BDG_CODE = inBDG_CODE   -- Forcer l'update du rco_title via triggers
       where GAL_PROJECT_ID = inGAL_PROJECT_ID1
         and GAL_BUDGET_ID = inGAL_BUDGET_ID;

      update GAL_HOURS
         set GAL_PROJECT_ID = inGAL_PROJECT_ID2
       where GAL_PROJECT_ID = inGAL_PROJECT_ID1
         and GAL_BUDGET_ID = inGAL_BUDGET_ID;
    end if;
  end UpdateBudgetProject;

  procedure UpdateTaskProject(
    inGAL_TASK_ID     in GAL_TASK.GAL_TASK_ID%type
  , inTAS_CODE        in GAL_TASK.TAS_CODE%type
  , inGAL_PROJECT_ID1 in GAL_PROJECT.GAL_PROJECT_ID%type
  , inGAL_PROJECT_ID2 in GAL_PROJECT.GAL_PROJECT_ID%type
  )
  is
  begin
    if inGAL_PROJECT_ID1 <> inGAL_PROJECT_ID2 then
      update GAL_TASK
         set GAL_PROJECT_ID = inGAL_PROJECT_ID2
           , TAS_CODE = inTAS_CODE   -- Forcer l'update du rco_title via triggers
       where GAL_PROJECT_ID = inGAL_PROJECT_ID1
         and GAL_TASK_ID = inGAL_TASK_ID;

      update GAL_TASK_LOT_LINK_DOC
         set GAL_PROJECT_ID = inGAL_PROJECT_ID2
       where GAL_PROJECT_ID = inGAL_PROJECT_ID1
         and GAL_TASK_ID = inGAL_TASK_ID;

      update GAL_HOURS
         set GAL_PROJECT_ID = inGAL_PROJECT_ID2
       where GAL_PROJECT_ID = inGAL_PROJECT_ID1
         and GAL_TASK_ID = inGAL_TASK_ID;
    end if;
  end UpdateTaskProject;
end GAL_PROJECT_TRANSFERT;
