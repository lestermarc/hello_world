--------------------------------------------------------
--  DDL for Package Body WFL_PROCESSES_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_PROCESSES_FUNCTIONS" 
is
  /*************** IsActivityChild *******************************************/
  function IsActivityChild(
    aProcParentId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aActParentId  in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aActChildId   in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oTransitionInfos WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos;
    result           WFL_WORKFLOW_TYPES.WFL_BOOLEAN            default 0;
  begin
    --récupération des informations sur les transitions
    oTransitionInfos  := WFL_ACTIVITIES_FUNCTIONS.GetTransitionsInfos(aProcessId => aProcParentId);
    --teste si il s'agit d'un élément enfant
    result            :=
      WFL_ACTIVITIES_FUNCTIONS.IsActChild(aActivityChildId    => aActChildId
                                        , aActivityParentId   => aActParentId
                                        , aTransitionInfos    => oTransitionInfos
                                         );
    return result;
  end IsActivityChild;

  /*************** IsActivityParent ******************************************/
  function IsActivityParent(
    aProcChildId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aActChildId  in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aActParentId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oTransitionInfos WFL_ACTIVITIES_FUNCTIONS.TTransitionInfos;
    result           WFL_WORKFLOW_TYPES.WFL_BOOLEAN            default 0;
  begin
    --récupération des informations sur les transitions
    oTransitionInfos  := WFL_ACTIVITIES_FUNCTIONS.GetTransitionsInfos(aProcessId => aProcChildId);
    --teste si il s'agit d'un élément enfant
    result            :=
      WFL_ACTIVITIES_FUNCTIONS.IsActParent(aActivityParentId   => aActParentId
                                         , aActivityChildId    => aActChildId
                                         , aTransitionInfos    => oTransitionInfos
                                          );
    return result;
  end IsActivityParent;

  /*************** IsHumanProcAllowed ****************************************/
  function IsHumanProcAllowed(
    aParticipantId in     PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aProcessId     in     WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aIsProxy       out    WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result                WFL_WORKFLOW_TYPES.WFL_BOOLEAN                        default 0;
    nCurParticipant       PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;

    --curseur pour récupérer les rôles, utilisateurs, OU autorisées pour le process
    cursor CrParticipantAllowed(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    is
      select WPA.PC_WFL_PARTICIPANTS_ID
           , WPA.C_PC_WFL_PARTICIPANT_TYPE
        from PCS.PC_WFL_PARTICIPANTS WPA
           , WFL_PROCESS_PART_ALLOW WPP
       where WPP.WFL_PROCESSES_ID = aProcessId
         and WPA.PC_WFL_PARTICIPANTS_ID = WPP.PC_WFL_PARTICIPANTS_ID;

    tplParticipantAllowed crParticipantAllowed%rowtype;
  begin
    --parcours des éléments autorisés pour le process et test pour savoir si l'utilisateur est autorisé
    for tplParticipantAllowed in crParticipantAllowed(aProcessId => aProcessId) loop
      nCurParticipant  := tplParticipantAllowed.PC_WFL_PARTICIPANTS_ID;

      --on teste le type du participant
      if tplParticipantAllowed.C_PC_WFL_PARTICIPANT_TYPE = 'HUMAN' then
        --on teste si l'utilisateur est directement ou indirectement autorisé
        if (nCurParticipant = aParticipantId) then
          result  := 1;
        else
          aIsProxy  :=
            PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.IsProxyOf(aProxyParticipantId   => aParticipantId
                                                      , aHumanParticipantId   => nCurParticipant
                                                       );
        end if;
      elsif tplParticipantAllowed.C_PC_WFL_PARTICIPANT_TYPE = 'ROLE' then
        result  :=
          PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.HasRole(aHumanParticipantId   => aParticipantId
                                                  , aRoleId               => nCurParticipant
                                                  , aIsProxy              => aIsProxy
                                                   );
      elsif tplParticipantAllowed.C_PC_WFL_PARTICIPANT_TYPE = 'ORGAN_UNIT' then
        result  :=
          PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.IsMemberOf(aHumanParticipantId   => aParticipantId
                                                     , aOrganUnitId          => nCurParticipant
                                                     , aIsProxy              => aIsProxy
                                                      );
      end if;

      if (result = 1) then
        aIsProxy  := 0;
        exit;
      end if;
    end loop;

    return result;
  end IsHumanProcAllowed;

  /*************** IsParticipantProcAllowed **********************************/
  function IsParticipantProcAllowed(
    aParticipantId in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aPartType      in PCS.PC_WFL_PARTICIPANTS.C_PC_WFL_PARTICIPANT_TYPE%type
  , aProcessId     in WFL_PROCESSES.WFL_PROCESSES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result   WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 0;
    bIsProxy WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
  begin
    if aPartType = 'HUMAN' then
      select decode(count(WPP.PC_WFL_PARTICIPANTS_ID), 0, 0, 1)
        into result
        from PCS.PC_WFL_PARTICIPANTS WPA
           , WFL_PROCESS_PART_ALLOW WPP
       where WPP.WFL_PROCESSES_ID = aProcessId
         and WPA.PC_WFL_PARTICIPANTS_ID = WPP.PC_WFL_PARTICIPANTS_ID
         and (    (    WPA.C_PC_WFL_PARTICIPANT_TYPE = 'HUMAN'
                   and WPA.PC_WFL_PARTICIPANTS_ID = aParticipantId)
              or (    WPA.C_PC_WFL_PARTICIPANT_TYPE = 'ROLE'
                  and PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.HasRole(aParticipantId, WPA.PC_WFL_PARTICIPANTS_ID) = 1
                 )
              or (    WPA.C_PC_WFL_PARTICIPANT_TYPE = 'ORGAN_UNIT'
                  and PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.IsMemberOf(aParticipantId, WPA.PC_WFL_PARTICIPANTS_ID) = 1
                 )
             );
    else
      select decode(count(WPP.PC_WFL_PARTICIPANTS_ID), 0, 0, 1)
        into result
        from WFL_PROCESS_PART_ALLOW WPP
       where WPP.WFL_PROCESSES_ID = aProcessId
         and WPP.PC_WFL_PARTICIPANTS_ID = aParticipantId;
    end if;

    return result;
  end IsParticipantProcAllowed;

/*************** IsHumanAllowed ********************************************/
  function IsHumanActAllowed(
    aParticipantId in     PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aActivityId    in     WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aActPartType   in     WFL_ACTIVITIES.C_WFL_ACT_PART_TYPE%type
  , aActPartId     in     WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  , aActAssignId   in     WFL_ACTIVITIES.ACT_ASSIGN_ID%type
  , aIsProxy       out    WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    bProcAllowed   WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
    result         WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
    cActPartType   WFL_ACTIVITIES.C_WFL_ACT_PART_TYPE%type;
    nProcessId     WFL_PROCESSES.WFL_PROCESSES_ID%type;
    nActAssignId   WFL_ACTIVITIES.ACT_ASSIGN_ID%type;
    nParticipantId WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type;
  begin
    --il faut que l'utilisateur soit autorisé pour le process et qu'en plus il ne soit pas dans WFL_ACTIVITY_PART_PROHIBITED
    select WFL_PROCESSES_ID
      into nProcessId
      from WFL_ACTIVITIES
     where WFL_ACTIVITIES_ID = aActivityId;

    --on teste si l'utilisateur est autorisé pour le process
    bProcAllowed  :=
                    IsHumanProcAllowed(aParticipantId   => aParticipantId, aProcessId => nProcessId
                                     , aIsProxy         => aIsProxy);
    --doit être défini pour l'activité et non le process
    aIsProxy      := 0;

    if bProcAllowed = 1 then
      --on teste si l'utilisateur a les droits pour l'activité
      cActPartType  := upper(aActPartType);

      if cActPartType = 'ACT_PERF' then
        select C_WFL_ACT_PART_TYPE
             , nvl(PC_WFL_PARTICIPANTS_ID, 0)
             , nvl(ACT_ASSIGN_ID, 0)
          into cActPartType
             , nParticipantId
             , nActAssignId
          from WFL_ACTIVITIES
         where WFL_ACTIVITIES_ID = aActAssignId;

        result  :=
          WFL_PROCESSES_FUNCTIONS.IsHumanActAllowed(aParticipantId   => aParticipantId
                                                  , aActivityId      => aActAssignId
                                                  , aActPartType     => cActPartType
                                                  , aActPartId       => nParticipantId
                                                  , aActAssignId     => nActAssignId
                                                  , aIsProxy         => aIsProxy
                                                   );
      elsif    (cActPartType = 'PROC_OWNER')
            or (cActPartType = 'PART_PLSQL') then
        --dans ce cas tous les participants doivent être affichés
        result  := 1;
      elsif     (cActPartType = 'HUMAN')
            and (aActPartId = aParticipantId) then
        result  := 1;
      elsif(cActPartType = 'ROLE') then
        result  :=
          PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.HasRole(aHumanParticipantId   => aParticipantId
                                                  , aRoleId               => aActPartId
                                                  , aIsProxy              => aIsProxy
                                                   );
      elsif(cActPartType = 'ORGAN_UNIT') then
        result  :=
          PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.IsMemberOf(aHumanParticipantId   => aParticipantId
                                                     , aOrganUnitId          => aActPartId
                                                     , aIsProxy              => aIsProxy
                                                      );
      end if;
    end if;

    return result;
  exception
    when no_data_found then
      return result;
  end IsHumanActAllowed;

  /*************** IsParticipantActAllowed ***********************************/
  function IsParticipantActAllowed(
    aParticipantId in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aPartType      in PCS.PC_WFL_PARTICIPANTS.C_PC_WFL_PARTICIPANT_TYPE%type
  , aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result     WFL_WORKFLOW_TYPES.WFL_BOOLEAN        default 0;
    bProcAllow WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
    bIsProxy   WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
    nProcessId WFL_PROCESSES.WFL_PROCESSES_ID%type;
  begin
    begin
      --récupération de l'identifiant du process
      select WFL_PROCESSES_ID
        into nProcessId
        from WFL_ACTIVITIES
       where WFL_ACTIVITIES_ID = aActivityId;

      bProcAllow  :=
        WFL_PROCESSES_FUNCTIONS.IsParticipantProcAllowed(aParticipantId   => aParticipantId
                                                       , aPartType        => aPartType
                                                       , aProcessId       => nProcessId
                                                        );

      select decode(count(WAP.PC_WFL_PARTICIPANTS_ID), 0, 1, 0)
        into result
        from WFL_ACTIVITY_PART_PROHIBITED WAP
       where WAP.WFL_ACTIVITIES_ID = aActivityId
         and WAP.PC_WFL_PARTICIPANTS_ID = aParticipantId;

      result      := result * bProcAllow;
    exception
      when no_data_found then
        result  := 0;
    end;

    return result;
  end;

  /*************** InsertPartAllowed *****************************************/
  procedure InsertPartAllowed(
    aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aActPartType   in WFL_ACTIVITIES.C_WFL_ACT_PART_TYPE%type
  , aParticipantId in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  , aActAssignId   in WFL_ACTIVITIES.ACT_ASSIGN_ID%type
  , aStopLoop      in number default 0
  )
  is
    cActPartType       WFL_ACTIVITIES.C_WFL_ACT_PART_TYPE%type;
    nParticipantId     WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type;
    nActAssignId       WFL_ACTIVITIES.ACT_ASSIGN_ID%type;
    bIsProxy           WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
    bPartAllow         WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
    bSearchProxies     boolean;

    --curseur qui parcours les participants
    cursor crAllParticipants(aParticipantId in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type)
    is
      select WPA.PC_WFL_PARTICIPANTS_ID
           , WPA.WPA_NAME
           , nvl(WPD.WPD_DESCRIPTION, WPA.WPA_DESCRIPTION) WPA_DESCRIPTION
        from PCS.PC_WFL_PARTICIPANTS WPA
           , PCS.PC_WFL_PARTICIPANTS_DESCR WPD
       where C_PC_WFL_PARTICIPANT_TYPE = 'HUMAN'
         and WPA.PC_WFL_PARTICIPANTS_ID <> aParticipantId
         and WPD.PC_WFL_PARTICIPANTS_ID(+) = WPA.PC_WFL_PARTICIPANTS_ID
         and WPD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId;

    tplAllParticipants crAllParticipants%rowtype;

    --curseur qui parcours les remplaçants d'un utilisateur
    cursor crProxies(aParticipantId in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type)
    is
      select PRE.PC_WFL_ARG1_PARTICIPANTS_ID
        from PCS.PC_WFL_PARTICIPANT_RELATIONS PRE
       where PRE.C_PC_WFL_RELATION_TYPE = 'PROXY OF'
         and PRE.PC_WFL_ARG2_PARTICIPANTS_ID = aParticipantId;

    tplProxies         crProxies%rowtype;
  begin
    --sortie de boucle
    if aStopLoop < 1000 then
      --suppression des éléments de la table temporaire
      delete from WFL_TMP_ALLOW_PART;

      --pour que l'on trouve des remplaçants il faut que le type de participant
      --et l'id soient définis, sauf si il s'agit de l'initiateur ou fonction plsql
      cActPartType    := upper(aActPartType);
      bSearchProxies  :=
           (cActPartType = 'PROC_OWNER')
        or (cActPartType = 'PART_PLSQL')
        or (     (    (cActPartType = 'HUMAN')
                  or (cActPartType = 'ROLE')
                  or (cActPartType = 'ORGAN_UNIT') )
            and (aParticipantId > 0)
            and (aParticipantId is not null)
           )
        or (     (cActPartType = 'ACT_PERF')
            and (aActAssignId > 0)
            and (aActAssignId is not null) );

      if bSearchProxies then
        if aActPartType = 'ACT_PERF' then
          begin
            --on remonte d'une activité pour recherche les remplaçants autorisés
            select C_WFL_ACT_PART_TYPE
                 , nvl(PC_WFL_PARTICIPANTS_ID, 0)
                 , nvl(ACT_ASSIGN_ID, 0)
              into cActPartType
                 , nParticipantId
                 , nActAssignId
              from WFL_ACTIVITIES
             where WFL_ACTIVITIES_ID = aActAssignId;

            --on remonte à l'activité parent et on insère les participants autorisés de l'activité parent
            WFL_PROCESSES_FUNCTIONS.InsertPartAllowed(aActivityId      => aActAssignId
                                                    , aActPartType     => cActPartType
                                                    , aParticipantId   => nParticipantId
                                                    , aActAssignId     => nActAssignId
                                                    , aStopLoop        => aStopLoop + 1
                                                     );
          exception
            when no_data_found then
              null;
          end;
        else
          --recherche des participants autorisés pour l'activité, et ensuite insertion remplaçants dans la table
          for tplAllParticipants in crAllParticipants(aParticipantId => aParticipantId) loop
            bPartAllow  :=
              WFL_PROCESSES_FUNCTIONS.IsHumanActAllowed(aParticipantId   => tplAllParticipants.PC_WFL_PARTICIPANTS_ID
                                                      , aActivityId      => aActivityId
                                                      , aActPartType     => aActPartType
                                                      , aActPartId       => aParticipantId
                                                      , aActAssignId     => 0
                                                      , aIsProxy         => bIsProxy
                                                       );

            if bPartAllow = 1 then
              --on ne doit insérer dans la table que les remplaçants
              for tplProxies in crProxies(aParticipantId => tplAllParticipants.PC_WFL_PARTICIPANTS_ID) loop
                --insertion dans les remplaçants autorisés
                merge into WFL_TMP_ALLOW_PART WTA
                  using (select WPA.PC_WFL_PARTICIPANTS_ID
                              , WPA.WPA_NAME
                              , nvl(WPD.WPD_DESCRIPTION, WPA.WPA_DESCRIPTION) WPA_DESCRIPTION
                              , 1 WTA_PROXY
                           from PCS.PC_WFL_PARTICIPANTS WPA
                              , PCS.PC_WFL_PARTICIPANTS_DESCR WPD
                          where WPA.PC_WFL_PARTICIPANTS_ID = tplProxies.PC_WFL_ARG1_PARTICIPANTS_ID
                            and WPD.PC_WFL_PARTICIPANTS_ID(+) = WPA.PC_WFL_PARTICIPANTS_ID
                            and WPD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId) WPA
                  on (WTA.PC_WFL_PARTICIPANTS_ID = WPA.PC_WFL_PARTICIPANTS_ID)
                  when matched then
                    update
                       set WTA.WPA_DESCRIPTION = WPA.WPA_DESCRIPTION
                  when not matched then
                    insert(WTA.PC_WFL_PARTICIPANTS_ID, WTA.WPA_NAME, WTA.WPA_DESCRIPTION, WTA.WTA_PROXY)
                    values(WPA.PC_WFL_PARTICIPANTS_ID, WPA.WPA_NAME, WPA.WPA_DESCRIPTION, WPA.WTA_PROXY);
              end loop;
            end if;
          end loop;
        end if;
      end if;
    end if;
  end InsertPartAllowed;

  /*************** DeleteActPartProhibitedParent *****************************/
  procedure DeleteActPartProhibitedParent(
    aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aParticipantId in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  )
  is
    --Curseur pour récupérer les activités parents assigned
    cursor crAssignedActivityParent(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    is
      select nvl(ACT_ASSIGN_ID, 0) ACT_ASSIGN_ID
        from WFL_ACTIVITIES
       where WFL_ACTIVITIES_ID = aActivityId
         and C_WFL_ACT_PART_TYPE = 'ACT_PERF';

    tplAssignedActivityParent crAssignedActivityParent%rowtype;
    nParentActivityId         WFL_ACTIVITIES.ACT_ASSIGN_ID%type;
  begin
    --parcours curseur activités parents
    for tplAssignedActivityParent in crAssignedActivityParent(aActivityId => aActivityId) loop
      nParentActivityId  := tplAssignedActivityParent.ACT_ASSIGN_ID;

      if     (nParentActivityId > 0)
         and (nParentActivityId is not null) then
        DeleteActPartProhibitedParent(aActivityId => nParentActivityId, aParticipantId => aParticipantId);
      end if;
    end loop;

    --suppression dans la table
    delete from WFL_ACTIVITY_PART_PROHIBITED
          where WFL_ACTIVITIES_ID = aActivityId
            and PC_WFL_PARTICIPANTS_ID = aParticipantId;
  end DeleteActPartProhibitedParent;

  /*************** DeleteActPartProhibitedChild *****************************/
  procedure DeleteActPartProhibitedChild(
    aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aParticipantId in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  )
  is
    --Curseur pour récupérer les activités enfants assignées
    cursor crAssignedActivityChild(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    is
      select nvl(WFL_ACTIVITIES_ID, 0) WFL_ACTIVITIES_ID
        from WFL_ACTIVITIES
       where ACT_ASSIGN_ID = aActivityId
         and C_WFL_ACT_PART_TYPE = 'ACT_PERF';

    tplAssignedActivityChild crAssignedActivityChild%rowtype;
    nChildActivityId         WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
  begin
    --parcours curseur activités enfants
    for tplAssignedActivityChild in crAssignedActivityChild(aActivityId => aActivityId) loop
      nChildActivityId  := tplAssignedActivityChild.WFL_ACTIVITIES_ID;

      if     (nChildActivityId > 0)
         and (nChildActivityId is not null) then
        DeleteActPartProhibitedChild(aActivityId => nChildActivityId, aParticipantId => aParticipantId);
      end if;
    end loop;

    --suppression dans la table
    delete from WFL_ACTIVITY_PART_PROHIBITED
          where WFL_ACTIVITIES_ID = aActivityId
            and PC_WFL_PARTICIPANTS_ID = aParticipantId;
  end DeleteActPartProhibitedChild;

  /*************** AllowParticipantToActivity ********************************/
  procedure AllowParticipantToActivity(
    aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aParticipantId in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  )
  is
  begin
    --autorisation des activités parents
    DeleteActPartProhibitedParent(aActivityId => aActivityId, aParticipantId => aParticipantId);
    --autorisation des activités enfants
    DeleteActPartProhibitedChild(aActivityId => aActivityId, aParticipantId => aParticipantId);
  end AllowParticipantToActivity;

  /*************** DeleteActPartProhibitedParent *****************************/
  procedure AddActPartProhibitedParent(
    aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aParticipantId in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  )
  is
    --Curseur pour récupérer les activités parents assigned
    cursor crAssignedActivityParent(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    is
      select nvl(ACT_ASSIGN_ID, 0) ACT_ASSIGN_ID
        from WFL_ACTIVITIES
       where WFL_ACTIVITIES_ID = aActivityId
         and C_WFL_ACT_PART_TYPE = 'ACT_PERF';

    tplAssignedActivityParent crAssignedActivityParent%rowtype;
    nParentActivityId         WFL_ACTIVITIES.ACT_ASSIGN_ID%type;
  begin
    --parcours curseur activités parents
    for tplAssignedActivityParent in crAssignedActivityParent(aActivityId => aActivityId) loop
      nParentActivityId  := tplAssignedActivityParent.ACT_ASSIGN_ID;

      if     (nParentActivityId > 0)
         and (nParentActivityId is not null) then
        AddActPartProhibitedParent(aActivityId => nParentActivityId, aParticipantId => aParticipantId);
      end if;
    end loop;

    --merge dans la table
    merge into WFL_ACTIVITY_PART_PROHIBITED WAP
      using (select aParticipantId PC_WFL_PARTICIPANTS_ID
                  , aActivityId WFL_ACTIVITIES_ID
               from dual) SEL
      on (    WAP.PC_WFL_PARTICIPANTS_ID = SEL.PC_WFL_PARTICIPANTS_ID
          and WAP.WFL_ACTIVITIES_ID = SEL.WFL_ACTIVITIES_ID)
      when matched then
        update
           set WAP.A_DATEMOD = WAP.A_DATEMOD, WAP.A_IDMOD = WAP.A_IDMOD   --ici on ne fait rien
      when not matched then
        insert(WAP.PC_WFL_PARTICIPANTS_ID, WAP.WFL_ACTIVITIES_ID, WAP.A_DATECRE, WAP.A_IDCRE)
        values(SEL.PC_WFL_PARTICIPANTS_ID, SEL.WFL_ACTIVITIES_ID, sysdate, PCS.PC_PUBLIC.GetUserIni);
  end AddActPartProhibitedParent;

  /*************** DeleteActPartProhibitedChild *****************************/
  procedure AddActPartProhibitedChild(
    aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aParticipantId in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  )
  is
    --Curseur pour récupérer les activités enfants assignées
    cursor crAssignedActivityChild(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    is
      select nvl(WFL_ACTIVITIES_ID, 0) WFL_ACTIVITIES_ID
        from WFL_ACTIVITIES
       where ACT_ASSIGN_ID = aActivityId
         and C_WFL_ACT_PART_TYPE = 'ACT_PERF';

    tplAssignedActivityChild crAssignedActivityChild%rowtype;
    nChildActivityId         WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
  begin
    --parcours curseur activités enfants
    for tplAssignedActivityChild in crAssignedActivityChild(aActivityId => aActivityId) loop
      nChildActivityId  := tplAssignedActivityChild.WFL_ACTIVITIES_ID;

      if     (nChildActivityId > 0)
         and (nChildActivityId is not null) then
        AddActPartProhibitedChild(aActivityId => nChildActivityId, aParticipantId => aParticipantId);
      end if;
    end loop;

    --merge dans la table
    merge into WFL_ACTIVITY_PART_PROHIBITED WAP
      using (select aParticipantId PC_WFL_PARTICIPANTS_ID
                  , aActivityId WFL_ACTIVITIES_ID
               from dual) SEL
      on (    WAP.PC_WFL_PARTICIPANTS_ID = SEL.PC_WFL_PARTICIPANTS_ID
          and WAP.WFL_ACTIVITIES_ID = SEL.WFL_ACTIVITIES_ID)
      when matched then
        update
           set WAP.A_DATEMOD = WAP.A_DATEMOD, WAP.A_IDMOD = WAP.A_IDMOD   --ici on ne fait rien
      when not matched then
        insert(WAP.PC_WFL_PARTICIPANTS_ID, WAP.WFL_ACTIVITIES_ID, WAP.A_DATECRE, WAP.A_IDCRE)
        values(SEL.PC_WFL_PARTICIPANTS_ID, SEL.WFL_ACTIVITIES_ID, sysdate, PCS.PC_PUBLIC.GetUserIni);
  end AddActPartProhibitedChild;

  /*************** ProhibeParticipantToActivity ******************************/
  procedure ProhibeParticipantToActivity(
    aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aParticipantId in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  )
  is
  begin
    --Interdiction des activités parents
    AddActPartProhibitedParent(aActivityId => aActivityId, aParticipantId => aParticipantId);
    --Interdiction des activités enfants
    AddActPartProhibitedChild(aActivityId => aActivityId, aParticipantId => aParticipantId);
  end ProhibeParticipantToActivity;

/*************** DeleteProcess *********************************************/
  function DeleteProcess(
    aDelProcessId     in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aDelInstancesOnly in WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result  WFL_WORKFLOW_TYPES.WFL_BOOLEAN         default 0;
    cStatus WFL_PROCESSES.C_WFL_PROC_STATUS%type;
  begin
    select nvl( (select C_WFL_PROC_STATUS
                   from WFL_PROCESSES
                  where WFL_PROCESSES_ID = aDelProcessId), '')
      into cStatus
      from dual;

    if    (cStatus = 'IN_PREPARE')
       or (cStatus = 'IN_TEST') then
      --suppression uniquement des instances
      if aDelInstancesOnly = 1 then
        --suppression des logs de process (cascade sur logs activités, performers, ...)
        delete from WFL_PROCESS_INST_LOG
              where WFL_PROCESSES_ID = aDelProcessId;

        --suppression des instances de process (cascade sur instances activités, performers, ...)
        delete from WFL_PROCESS_INSTANCES
              where WFL_PROCESSES_ID = aDelProcessId;
      else
        --suppression process (cascade sur activités, attributs, ...)
        delete from WFL_PROCESSES
              where WFL_PROCESSES_ID = aDelProcessId;
      end if;

      result  := 1;
    end if;

    return result;
  end DeleteProcess;

  /*************** DuplicateProcess ******************************************/
  function DuplicateProcess(
    aOldProcessId in     WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewProcessId out    WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewProcName  in     WFL_PROCESSES.PRO_NAME%type default null
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result           WFL_WORKFLOW_TYPES.WFL_BOOLEAN                            default 0;
    --relations entre activités
    nCnt             number;
    nOldActRelId     WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
    nNewActRelId     WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
    oActRelations    WFL_WORKFLOW_TYPES.TIdentRelations                                           default WFL_WORKFLOW_TYPES.TIdentRelations();

    --curseur qui parcours les attributs du process
    cursor crProcAttrib(aProcessId WFL_ATTRIBUTES.WFL_PROCESSES_ID%type)
    is
      select WFL_ATTRIBUTES_ID
        from WFL_ATTRIBUTES
       where WFL_PROCESSES_ID = aProcessId;

    tplProcAttrib    crProcAttrib%rowtype;
    nNewProcAttribId WFL_ATTRIBUTES.WFL_ATTRIBUTES_ID%type;

    --curseur qui parcours les activités du process
    cursor crProcActivity(aProcessId WFL_ACTIVITIES.WFL_PROCESSES_ID%type)
    is
      select WFL_ACTIVITIES_ID
        from WFL_ACTIVITIES
       where WFL_PROCESSES_ID = aProcessId;

    tplProcActivity  crProcActivity%rowtype;
    nNewActivityId   WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;

    --curseur qui parcours les attributs d'une activité
    cursor crActAttrib(
      aProcessId  WFL_ACTIVITY_ATTRIBUTES.WFL_PROCESSES_ID%type
    , aActivityId WFL_ACTIVITY_ATTRIBUTES.WFL_ACTIVITIES_ID%type
    )
    is
      select WFL_ACTIVITY_ATTRIBUTES_ID
        from WFL_ACTIVITY_ATTRIBUTES
       where WFL_ACTIVITIES_ID = aActivityId
         and WFL_PROCESSES_ID = aProcessId;

    tplActAttrib     crActAttrib%rowtype;
    nNewActAttribId  WFL_ACTIVITY_ATTRIBUTES.WFL_ACTIVITY_ATTRIBUTES_ID%type;

    --curseur qui parcours les transitions du process
    cursor crProcTrans(
      aNewProcessId WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aOldProcessId WFL_PROCESSES.WFL_PROCESSES_ID%type
    )
    is
      select TRA.WFL_TRANSITIONS_ID
           , nvl( (select ACT_NEW.WFL_ACTIVITIES_ID
                     from WFL_ACTIVITIES ACT_NEW
                        , WFL_ACTIVITIES ACT_OLD
                    where ACT_NEW.WFL_PROCESSES_ID = aNewProcessId
                      and ACT_NEW.ACT_NAME = ACT_OLD.ACT_NAME
                      and ACT_OLD.WFL_ACTIVITIES_ID = TRA.WFL_FROM_ACTIVITIES_ID)
               , 0
                ) WFL_FROM_ACTIVITIES_ID
           , nvl( (select ACT_NEW.WFL_ACTIVITIES_ID
                     from WFL_ACTIVITIES ACT_NEW
                        , WFL_ACTIVITIES ACT_OLD
                    where ACT_NEW.WFL_PROCESSES_ID = aNewProcessId
                      and ACT_NEW.ACT_NAME = ACT_OLD.ACT_NAME
                      and ACT_OLD.WFL_ACTIVITIES_ID = TRA.WFL_TO_ACTIVITIES_ID)
               , 0
                ) WFL_TO_ACTIVITIES_ID
        from WFL_TRANSITIONS TRA
       where TRA.WFL_FROM_PROCESSES_ID = aOldProcessId
         and TRA.WFL_TO_PROCESSES_ID = aOldProcessId;   --**pour l'instant ne traite que les transitions ds un seul process

    tplProcTrans     crProcTrans%rowtype;
    nNewTransitionId WFL_TRANSITIONS.WFL_TRANSITIONS_ID%type;
  begin
    --copie record process et descriptions
    result  :=
      WFL_PROCESSES_FUNCTIONS.CopyRecProcess(aNewProcessId   => aNewProcessId
                                           , aOldProcessId   => aOldProcessId
                                           , aNewProcName    => aNewProcName
                                            );

    if     (result = 1)
       and (aNewProcessId > 0) then
      --insertion des évènements des processus
      result  :=
        WFL_PROCESSES_FUNCTIONS.CopyRecProcessEvents(aNewProcessId => aNewProcessId, aOldProcessId => aOldProcessId) *
        result;
      --insertion des objets déclencheurs
      result  :=
        WFL_PROCESSES_FUNCTIONS.CopyRecProcessObjects(aNewProcessId => aNewProcessId, aOldProcessId => aOldProcessId) *
        result;
      --insertion des participants autorisés pour le processus
      result  :=
        WFL_PROCESSES_FUNCTIONS.CopyRecProcessPartAllow(aNewProcessId   => aNewProcessId
                                                      , aOldProcessId   => aOldProcessId) *
        result;

      --parcours des attributs référence et insertion nouveaux attributs
      for tplProcAttrib in crProcAttrib(aProcessId => aOldProcessId) loop
        result  :=
          WFL_PROCESSES_FUNCTIONS.CopyRecProcessAttribute(aNewProcessId     => aNewProcessId
                                                        , aNewAttributeId   => nNewProcAttribId
                                                        , aOldAttributeId   => tplProcAttrib.WFL_ATTRIBUTES_ID
                                                         ) *
          result;
      end loop;

      --parcours et insertion informations relatives aux activités
      for tplProcActivity in crProcActivity(aProcessId => aOldProcessId) loop
        --activités et description
        result                                     :=
          WFL_PROCESSES_FUNCTIONS.CopyRecProcessActivity(aNewProcessId    => aNewProcessId
                                                       , aNewActivityId   => nNewActivityId
                                                       , aOldActivityId   => tplProcActivity.WFL_ACTIVITIES_ID
                                                        ) *
          result;
        --évènements activité
        result                                     :=
          WFL_PROCESSES_FUNCTIONS.CopyRecProcessActEvent(aNewActivityId   => nNewActivityId
                                                       , aOldActivityId   => tplProcActivity.WFL_ACTIVITIES_ID
                                                        ) *
          result;
        --participants interdits par activité
        result                                     :=
          WFL_PROCESSES_FUNCTIONS.CopyRecProcessActPartProhibe(aNewActivityId   => nNewActivityId
                                                             , aOldActivityId   => tplProcActivity.WFL_ACTIVITIES_ID
                                                              ) *
          result;
        --deadlines activités
        result                                     :=
          WFL_PROCESSES_FUNCTIONS.CopyRecProcessActDeadline(aNewProcessId    => aNewProcessId
                                                          , aNewActivityId   => nNewActivityId
                                                          , aOldActivityId   => tplProcActivity.WFL_ACTIVITIES_ID
                                                           ) *
          result;

        --attributs des activités
        for tplActAttrib in crActAttrib(aProcessId => aOldProcessId, aActivityId => tplProcActivity.WFL_ACTIVITIES_ID) loop
          result  :=
            WFL_PROCESSES_FUNCTIONS.CopyRecProcessActAttribute
                                                        (aNewProcessId        => aNewProcessId
                                                       , aNewActivityId       => nNewActivityId
                                                       , aNewActAttributeId   => nNewActAttribId
                                                       , aOldActAttributeId   => tplActAttrib.WFL_ACTIVITY_ATTRIBUTES_ID
                                                        ) *
            result;
        end loop;

        --on garde les relations entre activités pour mise à jour champ ACT_ASSIGN_ID
        oActRelations.extend;
        oActRelations(oActRelations.count).pOldId  := tplProcActivity.WFL_ACTIVITIES_ID;
        oActRelations(oActRelations.count).pNewId  := nNewActivityId;
      end loop;

      --mise à jour des champs ACT_ASSIGN_ID
      for nCnt in 1 .. oActRelations.count loop
        --récupérations données élément collection
        nOldActRelId  := oActRelations(nCnt).pOldId;
        nNewActRelId  := oActRelations(nCnt).pNewId;

        --mise à jour
        update WFL_ACTIVITIES
           set ACT_ASSIGN_ID = nNewActRelId
         where ACT_ASSIGN_ID = nOldActRelId
           and WFL_PROCESSES_ID = aNewProcessId;
      end loop;

      --transitions des activités
      for tplProcTrans in crProcTrans(aNewProcessId => aNewProcessId, aOldProcessId => aOldProcessId) loop
        result  :=
          WFL_PROCESSES_FUNCTIONS.CopyRecProcessActTransition
                                                           (aNewProcessId        => aNewProcessId
                                                          , aNewFromActivityId   => tplProcTrans.WFL_FROM_ACTIVITIES_ID
                                                          , aNewToActivityId     => tplProcTrans.WFL_TO_ACTIVITIES_ID
                                                          , aNewTransitionId     => nNewTransitionId
                                                          , aOldTransitionId     => tplProcTrans.WFL_TRANSITIONS_ID
                                                           ) *
          result;
      end loop;
    end if;

    return result;
  end;

/*************** CopyRecProcess ********************************************/
  function CopyRecProcess(
    aNewProcessId out    WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aOldProcessId in     WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewProcName  in     WFL_PROCESSES.PRO_NAME%type default null
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    nNewVersion   WFL_PROCESSES.PRO_VERSION%type;
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
    cFieldsDescr  clob;
    cProName      WFL_PROCESSES.PRO_NAME%type;
  begin
    aNewProcessId  := 0;

    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_PROCESSES_ID';
      oExceptFields(4)        := 'PRO_VERSION';
      oExceptFields(5)        := 'C_WFL_PROC_STATUS';
      oExceptFields(6)        := 'PRO_CREATION_DATE';
      oExceptFields(7)        := 'PRO_NAME';

      --récupérations informations pour insertion
      if     (aNewProcName is not null)
         and (length(aNewProcName) > 0) then
        --récupération version+identifiant
        select INIT_ID_SEQ.nextval
             , nvl( (select max(PRO_VERSION) + 1
                       from WFL_PROCESSES
                      where PRO_NAME = aNewProcName), 1) PRO_VERSION
          into aNewProcessId
             , nNewVersion
          from dual;

        cProName  := aNewProcName;
      else
        --récupération identifiant
        select INIT_ID_SEQ.nextval
             , nvl( (select max(ALL_PROC.PRO_VERSION) + 1
                       from WFL_PROCESSES ALL_PROC
                          , WFL_PROCESSES THIS_PROC
                      where THIS_PROC.PRO_NAME = ALL_PROC.PRO_NAME
                        and THIS_PROC.WFL_PROCESSES_ID = aOldProcessId), 1) PRO_VERSION
             , nvl( (select PRO_NAME
                       from WFL_PROCESSES
                      where WFL_PROCESSES_ID = aOldProcessId), '') PRO_NAME
          into aNewProcessId
             , nNewVersion
             , cProName
          from dual;
      end if;

      --insertion record principal
      cFields                 :=
                     WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_PROCESSES'
                                                        , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_PROCESSES (
                WFL_PROCESSES_ID,
                PRO_NAME,
                PRO_VERSION,
                C_WFL_PROC_STATUS,
                PRO_CREATION_DATE,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT ' ||
        aNewProcessId ||
        ',
                ''' ||
        cProName ||
        ''',' ||
        nNewVersion ||
        ',
                ''IN_PREPARE'',
                SYSDATE,
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_PROCESSES
         WHERE  WFL_PROCESSES_ID = :WFL_PROCESSES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_PROCESSES_ID';
      oListVars(1).pVarValue  := aOldProcessId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion descriptions processus
      oExceptFields.delete;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_PROCESSES_ID';
      cFieldsDescr            :=
               WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_PROCESSES_DESCR'
                                                  , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_PROCESSES_DESCR (
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFieldsDescr ||
        ')
         SELECT ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFieldsDescr ||
        '
         FROM   WFL_PROCESSES_DESCR
         WHERE  WFL_PROCESSES_ID = :WFL_PROCESSES_ID';
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --résultat correct, pas d'exceptions
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcess;

  /*************** CopyRecProcessEvents **************************************/
  function CopyRecProcessEvents(
    aNewProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aOldProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
  begin
    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_PROCESS_EVENTS_ID';
      oExceptFields(4)        := 'WFL_PROCESSES_ID';
      cFields                 :=
               WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_PROCESS_EVENTS'
                                                  , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_PROCESS_EVENTS (
                WFL_PROCESS_EVENTS_ID,
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT INIT_ID_SEQ.NEXTVAL,
                ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_PROCESS_EVENTS
         WHERE  WFL_PROCESSES_ID = :WFL_PROCESSES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_PROCESSES_ID';
      oListVars(1).pVarValue  := aOldProcessId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion correcte
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessEvents;

  /*************** CopyRecProcessObjects *************************************/
  function CopyRecProcessObjects(
    aNewProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aOldProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
  begin
    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_OBJECT_PROCESSES_ID';
      oExceptFields(4)        := 'WFL_PROCESSES_ID';
      cFields                 :=
             WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_OBJECT_PROCESSES'
                                                , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_OBJECT_PROCESSES (
                WFL_OBJECT_PROCESSES_ID,
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT INIT_ID_SEQ.NEXTVAL,
                ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_OBJECT_PROCESSES
         WHERE  WFL_PROCESSES_ID = :WFL_PROCESSES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_PROCESSES_ID';
      oListVars(1).pVarValue  := aOldProcessId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion correcte
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessObjects;

  /*************** CopyRecProcessPartAllow ***********************************/
  function CopyRecProcessPartAllow(
    aNewProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aOldProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
  begin
    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_PROCESSES_ID';
      cFields                 :=
           WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_PROCESS_PART_ALLOW'
                                              , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_PROCESS_PART_ALLOW (
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_PROCESS_PART_ALLOW
         WHERE  WFL_PROCESSES_ID = :WFL_PROCESSES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_PROCESSES_ID';
      oListVars(1).pVarValue  := aOldProcessId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion correcte
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessPartAllow;

  /*************** CopyRecProcessAttribute ***********************************/
  function CopyRecProcessAttribute(
    aNewProcessId   in     WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewAttributeId out    WFL_ATTRIBUTES.WFL_ATTRIBUTES_ID%type
  , aOldAttributeId in     WFL_ATTRIBUTES.WFL_ATTRIBUTES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
    cFieldsDescr  clob;
  begin
    aNewAttributeId  := 0;

    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_ATTRIBUTES_ID';
      oExceptFields(4)        := 'WFL_PROCESSES_ID';

      --récupération identifiant nouvel attribut
      select INIT_ID_SEQ.nextval
        into aNewAttributeId
        from dual;

      --insertion record principal
      cFields                 :=
                    WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ATTRIBUTES'
                                                       , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_ATTRIBUTES (
                WFL_ATTRIBUTES_ID,
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT ' ||
        aNewAttributeId ||
        ',
                ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_ATTRIBUTES
         WHERE  WFL_ATTRIBUTES_ID = :WFL_ATTRIBUTES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_ATTRIBUTES_ID';
      oListVars(1).pVarValue  := aOldAttributeId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion descriptions
      oExceptFields.delete(4);
      cFieldsDescr            :=
              WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ATTRIBUTES_DESCR'
                                                 , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_ATTRIBUTES_DESCR (
                WFL_ATTRIBUTES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFieldsDescr ||
        ')
         SELECT ' ||
        aNewAttributeId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFieldsDescr ||
        '
         FROM   WFL_ATTRIBUTES_DESCR
         WHERE  WFL_ATTRIBUTES_ID = :WFL_ATTRIBUTES_ID';
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --résultat correct, pas d'exceptions
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessAttribute;

  /*************** CopyRecProcessActivity ************************************/
  function CopyRecProcessActivity(
    aNewProcessId  in     WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewActivityId out    WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aOldActivityId in     WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
    cFieldsDescr  clob;
  begin
    aNewActivityId  := 0;

    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_ACTIVITIES_ID';
      oExceptFields(4)        := 'WFL_PROCESSES_ID';

      --récupération identifiant
      select INIT_ID_SEQ.nextval
        into aNewActivityId
        from dual;

      --insertion record principal
      cFields                 :=
                    WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ACTIVITIES'
                                                       , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_ACTIVITIES (
                WFL_ACTIVITIES_ID,
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT ' ||
        aNewActivityId ||
        ',
                ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_ACTIVITIES
         WHERE  WFL_ACTIVITIES_ID = :WFL_ACTIVITIES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_ACTIVITIES_ID';
      oListVars(1).pVarValue  := aOldActivityId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion descriptions
      oExceptFields.delete(4);
      cFieldsDescr            :=
              WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ACTIVITIES_DESCR'
                                                 , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_ACTIVITIES_DESCR (
                WFL_ACTIVITIES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFieldsDescr ||
        ')
         SELECT ' ||
        aNewActivityId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFieldsDescr ||
        '
         FROM   WFL_ACTIVITIES_DESCR
         WHERE  WFL_ACTIVITIES_ID = :WFL_ACTIVITIES_ID';
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --résultat correct, pas d'exceptions
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessActivity;

  /*************** CopyRecProcessActEvent ************************************/
  function CopyRecProcessActEvent(
    aNewActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aOldActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
  begin
    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_ACTIVITY_EVENTS_ID';
      oExceptFields(4)        := 'WFL_ACTIVITIES_ID';
      cFields                 :=
              WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ACTIVITY_EVENTS'
                                                 , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_ACTIVITY_EVENTS (
                WFL_ACTIVITY_EVENTS_ID,
                WFL_ACTIVITIES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT INIT_ID_SEQ.NEXTVAL,
                ' ||
        aNewActivityId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_ACTIVITY_EVENTS
         WHERE  WFL_ACTIVITIES_ID = :WFL_ACTIVITIES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_ACTIVITIES_ID';
      oListVars(1).pVarValue  := aOldActivityId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion correcte
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessActEvent;

  /*************** CopyRecProcessActPartProhibe ******************************/
  function CopyRecProcessActPartProhibe(
    aNewActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aOldActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
  begin
    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_ACTIVITIES_ID';
      cFields                 :=
        WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ACTIVITY_PART_PROHIBITED'
                                           , aExceptFields   => oExceptFields
                                            );
      cInsQry                 :=
        'INSERT INTO WFL_ACTIVITY_PART_PROHIBITED (
                WFL_ACTIVITIES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT ' ||
        aNewActivityId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_ACTIVITY_PART_PROHIBITED
         WHERE  WFL_ACTIVITIES_ID = :WFL_ACTIVITIES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_ACTIVITIES_ID';
      oListVars(1).pVarValue  := aOldActivityId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion correcte
      return 1;
    exception
      when others then
        return 0;
    end;
  end;

  /*************** CopyRecProcessActDeadline *********************************/
  function CopyRecProcessActDeadline(
    aNewProcessId  in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aOldActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
  begin
    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_DEADLINES_ID';
      oExceptFields(4)        := 'WFL_ACTIVITIES_ID';
      oExceptFields(5)        := 'WFL_PROCESSES_ID';
      cFields                 :=
                    WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_DEADLINES'
                                                       , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_DEADLINES (
                WFL_DEADLINES_ID,
                WFL_ACTIVITIES_ID,
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT INIT_ID_SEQ.NEXTVAL,
                ' ||
        aNewActivityId ||
        ',
                ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_DEADLINES
         WHERE  WFL_ACTIVITIES_ID = :WFL_ACTIVITIES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_ACTIVITIES_ID';
      oListVars(1).pVarValue  := aOldActivityId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion correcte
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessActDeadline;

  /*************** CopyRecProcessActAttribute ********************************/
  function CopyRecProcessActAttribute(
    aNewProcessId      in     WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewActivityId     in     WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aNewActAttributeId out    WFL_ACTIVITY_ATTRIBUTES.WFL_ACTIVITY_ATTRIBUTES_ID%type
  , aOldActAttributeId in     WFL_ACTIVITY_ATTRIBUTES.WFL_ACTIVITY_ATTRIBUTES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
    cFieldsDescr  clob;
  begin
    aNewActAttributeId  := 0;

    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_ACTIVITY_ATTRIBUTES_ID';
      oExceptFields(4)        := 'WFL_ACTIVITIES_ID';
      oExceptFields(5)        := 'WFL_PROCESSES_ID';

      --récupération identifiant
      select INIT_ID_SEQ.nextval
        into aNewActAttributeId
        from dual;

      --insertion record principal
      cFields                 :=
           WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ACTIVITY_ATTRIBUTES'
                                              , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_ACTIVITY_ATTRIBUTES (
                WFL_ACTIVITY_ATTRIBUTES_ID,
                WFL_ACTIVITIES_ID,
                WFL_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT ' ||
        aNewActAttributeId ||
        ',
                ' ||
        aNewActivityId ||
        ',
                ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_ACTIVITY_ATTRIBUTES
         WHERE  WFL_ACTIVITY_ATTRIBUTES_ID = :WFL_ACTIVITY_ATTRIBUTES_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_ACTIVITY_ATTRIBUTES_ID';
      oListVars(1).pVarValue  := aOldActAttributeId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion descriptions
      oExceptFields.delete;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_ACTIVITY_ATTRIBUTES_ID';
      cFieldsDescr            :=
        WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_ACTIVITY_ATTRIBUTES_DESCR'
                                           , aExceptFields   => oExceptFields
                                            );
      cInsQry                 :=
        'INSERT INTO WFL_ACTIVITY_ATTRIBUTES_DESCR (
                WFL_ACTIVITY_ATTRIBUTES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFieldsDescr ||
        ')
         SELECT ' ||
        aNewActAttributeId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFieldsDescr ||
        '
         FROM   WFL_ACTIVITY_ATTRIBUTES_DESCR
         WHERE  WFL_ACTIVITY_ATTRIBUTES_ID = :WFL_ACTIVITY_ATTRIBUTES_ID';
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --résultat correct, pas d'exceptions
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessActAttribute;

  /*************** CopyRecProcessActTransition *******************************/
  function CopyRecProcessActTransition(
    aNewProcessId      in     WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aNewFromActivityId in     WFL_TRANSITIONS.WFL_FROM_ACTIVITIES_ID%type
  , aNewToActivityId   in     WFL_TRANSITIONS.WFL_TO_ACTIVITIES_ID%type
  , aNewTransitionId   out    WFL_TRANSITIONS.WFL_TRANSITIONS_ID%type
  , aOldTransitionId   in     WFL_TRANSITIONS.WFL_TRANSITIONS_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
    cInsQry       clob;
    oListVars     WFL_WORKFLOW_TYPES.TCurrencyVars default WFL_WORKFLOW_TYPES.TCurrencyVars();
    cFields       clob;
    cFieldsDescr  clob;
  begin
    aNewTransitionId  := 0;

    begin
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_TRANSITIONS_ID';
      oExceptFields(4)        := 'WFL_FROM_ACTIVITIES_ID';
      oExceptFields(5)        := 'WFL_TO_ACTIVITIES_ID';
      oExceptFields(6)        := 'WFL_FROM_PROCESSES_ID';
      oExceptFields(7)        := 'WFL_TO_PROCESSES_ID';

      --récupération identifiant
      select INIT_ID_SEQ.nextval
        into aNewTransitionId
        from dual;

      --insertion record principal
      cFields                 :=
                   WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_TRANSITIONS'
                                                      , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_TRANSITIONS (
                WFL_TRANSITIONS_ID,
                WFL_FROM_ACTIVITIES_ID,
                WFL_TO_ACTIVITIES_ID,
                WFL_FROM_PROCESSES_ID,
                WFL_TO_PROCESSES_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFields ||
        ')
         SELECT ' ||
        aNewTransitionId ||
        ',
                ' ||
        aNewFromActivityId ||
        ',
                ' ||
        aNewToActivityId ||
        ',
                ' ||
        aNewProcessId ||
        ',
                ' ||
        aNewProcessId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFields ||
        '
         FROM   WFL_TRANSITIONS
         WHERE  WFL_TRANSITIONS_ID = :WFL_TRANSITIONS_ID';
      oListVars.extend;
      oListVars(1).pVarName   := 'WFL_TRANSITIONS_ID';
      oListVars(1).pVarValue  := aOldTransitionId;
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --insertion descriptions
      oExceptFields.delete;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields.extend;
      oExceptFields(1)        := 'A_DATECRE';
      oExceptFields(2)        := 'A_IDCRE';
      oExceptFields(3)        := 'WFL_TRANSITIONS_ID';
      cFieldsDescr            :=
             WFL_WORKFLOW_UTILS.GetFieldsToInsert(aTableName      => 'WFL_TRANSITIONS_DESCR'
                                                , aExceptFields   => oExceptFields);
      cInsQry                 :=
        'INSERT INTO WFL_TRANSITIONS_DESCR (
                WFL_TRANSITIONS_ID,
                A_DATECRE,
                A_IDCRE,
                ' ||
        cFieldsDescr ||
        ')
         SELECT ' ||
        aNewTransitionId ||
        ',
                SYSDATE,
                PCS.PC_PUBLIC.GETUSERINI,
                ' ||
        cFieldsDescr ||
        '
         FROM   WFL_TRANSITIONS_DESCR
         WHERE  WFL_TRANSITIONS_ID = :WFL_TRANSITIONS_ID';
      WFL_WORKFLOW_UTILS.ExecuteQuerySql(aStatement => cInsQry, aListVars => oListVars);
      --résultat correct, pas d'exceptions
      return 1;
    exception
      when others then
        return 0;
    end;
  end CopyRecProcessActTransition;
end WFL_PROCESSES_FUNCTIONS;
