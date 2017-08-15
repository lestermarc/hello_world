--------------------------------------------------------
--  DDL for Package Body WFL_ACTIVITIES_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_ACTIVITIES_FUNCTIONS" 
is
  --nombre de boucles maximales autorisés ds les procédures
  MaxLoopCount constant pls_integer := 1000;

/*************** SetLoopFlag ***********************************************/
  procedure SetLoopFlag(
    aActSourceId     in     WFL_TRANSITIONS.WFL_FROM_ACTIVITIES_ID%type
  , aActTargetId     in     WFL_TRANSITIONS.WFL_TO_ACTIVITIES_ID%type
  , aLastActSourceId in     WFL_TRANSITIONS.WFL_FROM_ACTIVITIES_ID%type
  , aTransitionInfos in out WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos
  , aTransitionList  in out WFL_ACTIVITIES_FUNCTIONS.TWflActTransitions
  )
  is
    nCnt      pls_integer;
    nCntTrans pls_integer;
    bFound    boolean     default false;
  begin
    --parcours et on détecte si l'élément est déjà dans la liste
    for nCnt in 1 .. aTransitionList.count loop
      if     (aTransitionList(nCnt).pActSourceId = aActSourceId)
         and (aTransitionList(nCnt).pActTargetId = aActTargetId) then
        bFound  := true;

        --update sur la transition qui contient la boucle
        for nCntTrans in 1 .. aTransitionInfos.count loop
          if     aTransitionInfos(nCntTrans).pSourceId = aLastActSourceId
             and aTransitionInfos(nCntTrans).pTargetId = aActSourceId then
            aTransitionInfos(nCntTrans).pIsLoop  := true;
            exit;
          end if;
        end loop;

        exit;
      end if;
    end loop;

    if not bFound then
      --passage aux transitions suivantes
      for nCntTrans in 1 .. aTransitionInfos.count loop
        if     not aTransitionInfos(nCntTrans).pIsLoop
           and (aTransitionInfos(nCntTrans).pSourceId = aActTargetId) then
          aTransitionList.extend;
          aTransitionList(aTransitionList.count).pActSourceId  := aActSourceId;
          aTransitionList(aTransitionList.count).pActTargetId  := aActTargetId;
          SetLoopFlag(aActSourceId       => aActTargetId
                    , aActTargetId       => aTransitionInfos(nCntTrans).pTargetId
                    , aLastActSourceId   => aActSourceId
                    , aTransitionInfos   => aTransitionInfos
                    , aTransitionList    => aTransitionList
                     );
        end if;
      end loop;
    end if;
  end SetLoopFlag;

  /*************** GetTransitionsInfos ***************************************/
  function GetTransitionsInfos(aProcessId in WFL_ACTIVITIES.WFL_PROCESSES_ID%type)
    return WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos
  is
    --curseur pour parcours des activités
    cursor crActTrans(aProcessId in WFL_ACTIVITIES.WFL_PROCESSES_ID%type)
    is
      select TRA.WFL_FROM_ACTIVITIES_ID
           , TRA.WFL_TO_ACTIVITIES_ID
           , (select decode(count(WFL_TRANSITIONS_ID), 0, 1, 0)
                from WFL_TRANSITIONS TRA_ROOT
               where TRA_ROOT.WFL_TRANSITIONS_ID <> TRA.WFL_TRANSITIONS_ID
                 and TRA_ROOT.WFL_TO_ACTIVITIES_ID = TRA.WFL_FROM_ACTIVITIES_ID
                 and TRA_ROOT.WFL_TO_PROCESSES_ID = TRA.WFL_FROM_PROCESSES_ID) IsRoot
        from WFL_TRANSITIONS TRA
       where TRA.WFL_FROM_PROCESSES_ID = aProcessId;

    tplActTrans     crActTrans%rowtype;
    nCnt            pls_integer;
    oTransitionList WFL_ACTIVITIES_FUNCTIONS.TWflActTransitions default WFL_ACTIVITIES_FUNCTIONS.TWflActTransitions();
    result          WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos   default WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos();
  begin
    for tplActTrans in crActTrans(aProcessId => aProcessId) loop
      result.extend;
      result(result.count).pSourceId  := tplActTrans.WFL_FROM_ACTIVITIES_ID;
      result(result.count).pTargetId  := tplActTrans.WFL_TO_ACTIVITIES_ID;
      result(result.count).pIsRoot    :=(tplActTrans.IsRoot = 1);
      result(result.count).pIsLoop    := false;
    end loop;

    for nCnt in 1 .. result.count loop
      if result(nCnt).pIsRoot then
        SetLoopFlag(aActSourceId       => result(nCnt).pSourceId
                  , aActTargetId       => result(nCnt).pTargetId
                  , aLastActSourceId   => -1
                  , aTransitionInfos   => result
                  , aTransitionList    => oTransitionList
                   );
      end if;
    end loop;

    return result;
  end GetTransitionsInfos;

  /*************** GetAuthorizedTask ***************************************/
  function GetAuthorizedTasks(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    return WFL_ACTIVITIES_FUNCTIONS.TActivitiesInfos
  is
    result WFL_ACTIVITIES_FUNCTIONS.TActivitiesInfos default WFL_ACTIVITIES_FUNCTIONS.TActivitiesInfos();
  begin
    null;
  end;

/*************** IsActChild ************************************************/
  function IsActChild(
    aActivityChildId  in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aActivityParentId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aTransitionInfos  in WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos
  , aStopLoop         in pls_integer default 0
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    nCnt   pls_integer;
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 0;
  begin
    --parcours des transitions et teste si enfant
    for nCnt in 1 .. aTransitionInfos.count loop
      if     not aTransitionInfos(nCnt).pIsLoop
         and (aTransitionInfos(nCnt).pSourceId = aActivityParentId)
         and (aTransitionInfos(nCnt).pTargetId = aActivityChildId) then
        result  := 1;
      end if;
    end loop;

    if result <> 1 then
      --parcours des activités enfants et recherche
      for nCnt in 1 .. aTransitionInfos.count loop
        if     not aTransitionInfos(nCnt).pIsLoop
           and (aTransitionInfos(nCnt).pSourceId = aActivityParentId) then
          result  :=
            IsActChild(aActivityChildId    => aActivityChildId
                     , aActivityParentId   => aTransitionInfos(nCnt).pTargetId
                     , aTransitionInfos    => aTransitionInfos
                     , aStopLoop           => aStopLoop + 1
                      );

          --sortie si résultat trouvé ou nbre de boucles > max
          if    (result = 1)
             or (aStopLoop > MaxLoopCount) then
            exit;
          end if;
        end if;
      end loop;
    end if;

    return result;
  end IsActChild;

/*************** IsActParent ***********************************************/
  function IsActParent(
    aActivityParentId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aActivityChildId  in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aTransitionInfos  in WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos
  , aStopLoop         in pls_integer default 0
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    nCnt   pls_integer;
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 0;
  begin
    --parcours des transitions et teste si enfant
    for nCnt in 1 .. aTransitionInfos.count loop
      if     not aTransitionInfos(nCnt).pIsLoop
         and (aTransitionInfos(nCnt).pTargetId = aActivityChildId)
         and (aTransitionInfos(nCnt).pSourceId = aActivityParentId) then
        result  := 1;
      end if;
    end loop;

    if result <> 1 then
      --parcours des activités enfants et recherche
      for nCnt in 1 .. aTransitionInfos.count loop
        if     not aTransitionInfos(nCnt).pIsLoop
           and (aTransitionInfos(nCnt).pTargetId = aActivityChildId) then
          result  :=
            IsActChild(aActivityParentId   => aActivityParentId
                     , aActivityChildId    => aTransitionInfos(nCnt).pSourceId
                     , aTransitionInfos    => aTransitionInfos
                     , aStopLoop           => aStopLoop + 1
                      );

          --sortie si résultat trouvé ou nbre de boucles > max
          if    (result = 1)
             or (aStopLoop > MaxLoopCount) then
            exit;
          end if;
        end if;
      end loop;
    end if;

    return result;
  end IsActParent;

  /**
  * procedure UpdateActivityPositions
  * Description
  *   Sauvegarde les coordonnées top left des blocs d'activité
  */
  procedure UpdateActivityPositions(
    aActivityID in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aLeft          WFL_ACTIVITIES.ACT_LEFT%type
  , aTop           WFL_ACTIVITIES.ACT_TOP%type
  )
  is
  begin
    -- Màj de l'activité avec les coordonnées Left et Top
    update WFL_ACTIVITIES
       set ACT_LEFT = aLeft
         , ACT_TOP = aTop
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where WFL_ACTIVITIES_ID = aActivityID;
  end UpdateActivityPositions;
end WFL_ACTIVITIES_FUNCTIONS;
