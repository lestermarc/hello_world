--------------------------------------------------------
--  DDL for Package Body FAL_TIME_STAMPING_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_TIME_STAMPING_TOOLS" 
is
  -- Séparateur utilisé dans la référence GAL
  cGalSeparator                  constant varchar2(1)   := nvl(PCS.PC_CONFIG.GetConfig('FAL_SEPAR_ORIGIN_REF_SEQ'), '/');
  -- Configurations
  cCombinedRefSeparator          constant varchar2(1)   := nvl(PCS.PC_CONFIG.GetConfig('FAL_SEPAR_ORIGIN_REF_SEQ'), '/');
  cDefaultPfgStatus              constant varchar2(2)   := nvl(PCS.PC_CONFIG.GetConfig('FAL_DEFAULT_PFG_STATUS'), '20');
  cWorkUnit                      constant varchar2(2)   := upper(PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') );
  cDurationProc                  constant varchar2(64)  := PCS.PC_CONFIG.GetConfig('FAL_TIS_DURATION_PROC');
  cProgressMode                  constant integer       := PCS.PC_CONFIG.GetConfig('FAL_PROGRESS_MODE');
  cMultiOpMode                   constant integer       := PCS.PC_CONFIG.GetConfig('FAL_TIS_MULTI_OP_MODE');
  cCheckProdGrouping             constant integer       := nvl(PCS.PC_CONFIG.GetConfig('FAL_TIS_CHECK_PROD_GROUPING'), 1);
  momNone                        constant integer       := 1;
  momParallel                    constant integer       := 2;
  momSequential                  constant integer       := 3;
  -- Messages d'erreur retournés à l'interface
  emRefLotNotFound               constant varchar2(255)
                                            := PCS.PC_FUNCTIONS.TranslateWord('Le lot de fabrication spécifié dans la référence combinée n''a pas été trouvé.');
  emRefTaskNotFound              constant varchar2(255)
                            := PCS.PC_FUNCTIONS.TranslateWord('La tâche ou le dossier de fabrication spécifié dans la référence combinée n''a pas été trouvé.');
  emRefTaskLinkNotFound          constant varchar2(255)
                                                   := PCS.PC_FUNCTIONS.TranslateWord('L''opération spécifiée dans la référence combinée n''a pas été trouvée.');
  emMalformedRef                 constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('La référence combinée est incomplète ou incorrecte.');
  emIncorrectRefOrigin           constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('L''origine spécifiée dans la référence combinée est incorrecte.');
  emTisTypeCantBeNull            constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('Le type de timbrage est obligatoire.');
  emGroupEndRequiredBeforeTask   constant varchar2(255)
                                 := PCS.PC_FUNCTIONS.TranslateWord('Impossible de saisir un timbrage d''opération avant d''interrompre ou terminer le groupe.');
  emDifferentOriginsProhibited   constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('Impossible de grouper des opérations d''origines différentes.');
  emDiffProductsCantBeGrouped    constant varchar2(255)
                                        := PCS.PC_FUNCTIONS.TranslateWord('En production les opérations sur des produits différents ne peuvent être groupées.');
  emInternalTaskOnlyCanBeGrouped constant varchar2(255)
                                             := PCS.PC_FUNCTIONS.TranslateWord('En gestion à l''affaire seules les opérations internes peuvent être groupées.');
  emCombinedRefCantBeNull        constant varchar2(255)
                                                    := PCS.PC_FUNCTIONS.TranslateWord('La référence combinée ne peut être nulle à la saisie d''une opération.');
  emEndRequiredBeforeStart       constant varchar2(255)
                       := PCS.PC_FUNCTIONS.TranslateWord('Impossible de saisir une nouvelle opération avant d''interrompre ou terminer l''opération en cours.');
  emStopCurrentBefore            constant varchar2(255)
                                             := PCS.PC_FUNCTIONS.TranslateWord('Veuillez d''abord interrompre ou terminer l''opération ou le groupe en cours.');
  emWarningGroupingInProgress    constant varchar2(255)
                                                    := PCS.PC_FUNCTIONS.TranslateWord('Attention vous n''avez pas terminé de saisir les opérations du groupe.');
  emNoItemToInterrupt            constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('Aucune opération ou groupe en cours à interrompre.');
  emNoItemToEnd                  constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('Aucune opération ou groupe en cours à terminer.');
  emStartWorkBeforeEnd           constant varchar2(255)
                            := PCS.PC_FUNCTIONS.TranslateWord('Vous devez d''abord effectuer un début de travail avant de terminer l''opération ou le groupe.');
  emErrorTaskInProgressOtherOp   constant varchar2(255)
                                                    := PCS.PC_FUNCTIONS.TranslateWord('Impossible de travailler sur la même opération qu''un autre opérateur.');
  emErrorGrpTaskStartedOtherOp   constant varchar2(255)
    := PCS.PC_FUNCTIONS.TranslateWord
        ('Cette opération ou groupe est déjà en cours de réglage ou de travail par un autre opérateur. Veuillez attendre son interruption par %operator ou saisir une autre référence.'
        );
  emWarningTaskInterrupOtherOp   constant varchar2(255)
    := PCS.PC_FUNCTIONS.TranslateWord
             ('Attention : Cette opération a déjà été commencée par un autre opérateur, vous pouvez néanmoins travailler dessus puisqu''elle a été interrompue.');
  emWarningMyGroupInterOtherOp   constant varchar2(255)
    := PCS.PC_FUNCTIONS.TranslateWord
                              ('Attention : Ce groupe a été repris par un autre opérateur, vous pouvez néanmoins travailler dessus puisqu''il a été interrompu.');
  emWarningGroupInterrupOtherOp  constant varchar2(255)
    := PCS.PC_FUNCTIONS.TranslateWord
        ('Attention : Cette opération a été regroupée par un autre opérateur, vous pouvez néanmoins travailler sur ce groupe puisqu''il a été interrompu (le groupe complet sera repris).'
        );

  /**
   * function ParseLotRef
   * Description
   *   ParseLotRef
   */
  function ParseLotRef(aLotRef in varchar2)
    return FAL_LOT.FAL_LOT_ID%type
  is
    vResult FAL_LOT.FAL_LOT_ID%type;
  begin
    -- Recherche du lot en fonction de la référence complète.
    -- Si erreur, retourne null.
    begin
      select FAL_LOT_ID
        into vResult
        from FAL_LOT
       where LOT_REFCOMPL = aLotRef;

      return vResult;
    exception
      when others then
        return null;
    end;
  end ParseLotRef;

  /**
   * function ParseFTaskLinkRef
   * Description
   *   ParseFTaskLinkRef
   */
  function ParseFTaskLinkRef(aLotId in FAL_LOT.FAL_LOT_ID%type, aTaskLinkRef in varchar2)
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  is
    vResult FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    -- Recherche de l'opération en fonction du lot et du numéro de séquence.
    -- Si erreur, retourne null.
    begin
      select FAL_SCHEDULE_STEP_ID
        into vResult
        from FAL_TASK_LINK
       where FAL_LOT_ID = aLotId
         and SCS_STEP_NUMBER = aTaskLinkRef;

      return vResult;
    exception
      when others then
        return null;
    end;
  end ParseFTaskLinkRef;

  /**
   * function UpdateFalLinks
   * Description
   *   UpdateFalLinks
   */
  function UpdateFalLinks(aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING, aLotRef in varchar2, aTaskLinkRef in varchar2)
    return varchar2
  is
    vLotId        FAL_LOT.FAL_LOT_ID%type                   := null;
    vTaskLinkId   FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type   := null;
    vErrorMessage varchar2(4000);
  begin
    --if aTimeStamping.TIS_GROUP_ID is not null then
      -- Recherche du lot
    if aLotRef is not null then
      vLotId  := ParseLotRef(aLotRef);

      if nvl(vLotId, 0) <= 0 then
        vErrorMessage  := emRefLotNotFound;
      else
        -- Recherche de l'opération du lot
        if aTaskLinkRef is not null then
          vTaskLinkId  := ParseFTaskLinkRef(vLotId, aTaskLinkRef);

          if nvl(vTaskLinkId, 0) <= 0 then
            vErrorMessage  := emRefTaskLinkNotFound;
          end if;
        end if;
      end if;
    end if;

    --end if;
    aTimeStamping.TIS_LOT_REFCOMPL   := aLotRef;
    aTimeStamping.TIS_TASK_LINK_SEQ  := aTaskLinkRef;
    aTimeStamping.TIS_TASK_LINK_ID   := vTaskLinkId;
    return vErrorMessage;
  end UpdateFalLinks;

  /**
   * function ParseTaskRef
   * Description
   *   ParseTaskRef
   */
  function ParseTaskRef(aTaskRef in varchar2)
    return GAL_TASK.GAL_TASK_ID%type
  is
    vResult       GAL_TASK.GAL_TASK_ID%type;
    vProjectCode  GAL_PROJECT.PRJ_CODE%type;
    vTaskCode     GAL_TASK.TAS_CODE%type;
    vSeparatorPos integer;
  begin
    -- Recherche du dossier de fabrication en fonction de la référence.
    -- Si erreur, retourne null.
    begin
      -- Décomposition de la référence complète
      vSeparatorPos  := instr(aTaskRef, cGalSeparator);
      vProjectCode   := substr(aTaskRef, 1, vSeparatorPos - 1);
      vTaskCode      := substr(aTaskRef, vSeparatorPos + 1);

      -- Recherche de l'ID
      select TAS.GAL_TASK_ID
        into vResult
        from GAL_TASK TAS
           , GAL_PROJECT PRJ
       where PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
         and PRJ.PRJ_CODE = vProjectCode
         and TAS.TAS_CODE = vTaskCode;

      return vResult;
    exception
      when others then
        return null;
    end;
  end ParseTaskRef;

  /**
   * function ParseGTaskLinkRef
   * Description
   *   ParseGTaskLinkRef
   */
  function ParseGTaskLinkRef(aTaskId in GAL_TASK.GAL_TASK_ID%type, aTaskLinkRef in varchar2)
    return GAL_TASK_LINK.GAL_TASK_LINK_ID%type
  is
    vResult GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
  begin
    -- Recherche de l'opération en fonction du dossier de fabrication et du
    -- numéro de séquence.
    -- Si erreur, retourne null.
    begin
      select GAL_TASK_LINK_ID
        into vResult
        from GAL_TASK_LINK
       where GAL_TASK_ID = aTaskId
         and SCS_STEP_NUMBER = aTaskLinkRef;

      return vResult;
    exception
      when others then
        return null;
    end;
  end ParseGTaskLinkRef;

  /**
   * function UpdateGalLinks
   * Description
   *   UpdateGalLinks
   */
  function UpdateGalLinks(aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING, aTaskRef in varchar2, aTaskLinkRef in varchar2)
    return varchar2
  is
    vTaskId       GAL_TASK.GAL_TASK_ID%type             := null;
    vTaskLinkId   GAL_TASK_LINK.GAL_TASK_LINK_ID%type   := null;
    vTaskRef      varchar2(100)                         := aTaskRef;
    vTaskLinkRef  varchar2(10)                          := aTaskLinkRef;
    vErrorMessage varchar2(4000);
  begin
    -- Recherche du dossier de fabrication
    --if aTimeStamping.TIS_GROUP_ID is not null then
    if vTaskRef is not null then
      if upper(vTaskRef) = 'I' then
        vTaskRef      := aTaskLinkRef;
        vTaskLinkRef  := null;
      else
        vTaskId  := ParseTaskRef(vTaskRef);

        if nvl(vTaskId, 0) <= 0 then
          vErrorMessage  := emRefTaskNotFound;
        else
          -- Recherche de l'opération du dossier de fabrication
          if vTaskLinkRef is not null then
            vTaskLinkId  := ParseGTaskLinkRef(vTaskId, vTaskLinkRef);

            if nvl(vTaskLinkId, 0) <= 0 then
              vErrorMessage  := emRefTaskLinkNotFound;
            end if;
          end if;
        end if;
      end if;
    end if;

    --end if;
    aTimeStamping.TIS_GAL_REFCOMPL   := vTaskRef;
    aTimeStamping.TIS_TASK_LINK_SEQ  := vTaskLinkRef;
    aTimeStamping.TIS_TASK_LINK_ID   := vTaskLinkId;
    return vErrorMessage;
  end UpdateGalLinks;

  /**
   * procedure ParseCombinedRef
   * Description
   *   Analyse de la référence combinée
   */
  procedure ParseCombinedRef(
    aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aFocusField   in out        varchar2
  , aErrorCode    in out        integer
  , aErrorMessage in out        varchar2
  )
  is
    vProgressOrigin varchar(255);
    vRefCompl       varchar(255);
    vTaskLinkSeq    varchar(255);
    vSep1Pos        integer;
    vSep2Pos        integer;
  begin
    -- On réinitialise les références et l'origine
    aTimeStamping.TIS_LOT_REFCOMPL   := null;
    aTimeStamping.TIS_GAL_REFCOMPL   := null;
    aTimeStamping.TIS_TASK_LINK_SEQ  := null;
    aTimeStamping.TIS_TASK_LINK_ID   := null;

    -- Si la référence combinée n'est pas vide, on recherche les nouvelles valeurs
    if aTimeStamping.TIS_VCOMBINED_REF is not null then
      -- Analyse de la référence combinée
      vSep1Pos         := instr(aTimeStamping.TIS_VCOMBINED_REF, cCombinedRefSeparator);
      vSep2Pos         := instr(aTimeStamping.TIS_VCOMBINED_REF, cCombinedRefSeparator, -1);
      vProgressOrigin  := substr(aTimeStamping.TIS_VCOMBINED_REF, 1, vSep1Pos - 1);
      vRefCompl        := substr(aTimeStamping.TIS_VCOMBINED_REF, vSep1Pos + 1, vSep2Pos - 1 - vSep1Pos);
      vTaskLinkSeq     := substr(aTimeStamping.TIS_VCOMBINED_REF, vSep2Pos + 1);

      if length(vProgressOrigin) = 2 then
        aTimeStamping.C_PROGRESS_ORIGIN  := vProgressOrigin;
      end if;

      if    vProgressOrigin is null
         or vRefCompl is null
         or vTaskLinkSeq is null then
        -- Référence incomplète
        aErrorCode     := 762;
        aErrorMessage  := emMalformedRef;
      else
        -- Selon l'origine de l'opération,
        case aTimeStamping.C_PROGRESS_ORIGIN
          when poProduction then
            -- on met à jour les références FAL
            aErrorMessage  := UpdateFalLinks(aTimeStamping, vRefCompl, vTaskLinkSeq);

            if aErrorMessage is not null then
              aErrorCode  := 684;
            end if;
          when poProject then
            -- on met à jour les références GAL
            aErrorMessage  := UpdateGalLinks(aTimeStamping, vRefCompl, vTaskLinkSeq);

            if aErrorMessage is not null then
              aErrorCode  := 685;
            end if;
          else
            -- on spécifie une erreur si l'origine est inconnue
            aTimeStamping.C_PROGRESS_ORIGIN  := null;
            aErrorCode                       := 753;
            aErrorMessage                    := emIncorrectRefOrigin;
        end case;
      end if;
    end if;
  end ParseCombinedRef;

  /**
   * function GenerateGroupTimeStampings
   * Description
   *   Génération des timbrages d'un groupe lors de sa reprise par un
   *   utilisateur différent.
   */
  procedure GenerateGroupTimeStampings(aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
  is
    cursor crGroupTasks
    is
      select TIS.FAL_TIME_STAMPING_ID
           , TIS.C_PROGRESS_ORIGIN
           , TIS.TIS_DIC_OPERATOR_ID
           , TIS.TIS_REF_FACTORY_FLOOR
           , TIS.TIS_REF_FACTORY_FLOOR2
           , TIS.TIS_LOT_REFCOMPL
           , TIS.TIS_GAL_REFCOMPL
           , TIS.TIS_TASK_LINK_SEQ
           , TIS.TIS_TASK_LINK_ID
           , TIS.TIS_GROUP_ID
           , TIS.TIS_GROUP_TASK_COUNT
           , TIS.TIS_GROUP_TASK_BAL_COUNT
           , TIS.TIS_STAMPING_DATE
           , TIS.A_IDCRE
           , VFI.VFI_MEMO_01 TIS_VCOMBINED_REF
--            , VFI.VFI_INTEGER_01 TIS_VGROUP_TASK_COUNT
      from   FAL_TIME_STAMPING TIS
           , COM_VFIELDS_RECORD VFI
       where TIS.TIS_GROUP_ID = aTimeStamping.TIS_GROUP_ID
         and TIS.C_TIS_STATUS = FAL_TIME_STAMPING_FCT.ssProcessed
         and TIS.TIS_TASK_LINK_SEQ is not null
         and (    (     (   TIS.TIS_LOT_REFCOMPL is null
                         or (TIS.TIS_LOT_REFCOMPL <> aTimeStamping.TIS_LOT_REFCOMPL) )
                   and (   TIS.TIS_GAL_REFCOMPL is null
                        or (TIS.TIS_GAL_REFCOMPL <> aTimeStamping.TIS_GAL_REFCOMPL) )
                  )
              or TIS.TIS_TASK_LINK_SEQ <> aTimeStamping.TIS_TASK_LINK_SEQ
             )
         and TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
         and not exists(
               select FAL_TIME_STAMPING_ID
                 from FAL_TIME_STAMPING SUB_TIS
                where SUB_TIS.TIS_GROUP_ID = TIS.TIS_GROUP_ID
                  and SUB_TIS.C_TIS_STATUS <> '50'
                  and SUB_TIS.TIS_STAMPING_DATE >= TIS.TIS_STAMPING_DATE
                  and SUB_TIS.FAL_TIME_STAMPING_ID <> TIS.FAL_TIME_STAMPING_ID
                  and SUB_TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
                  and (   TIS.TIS_LOT_REFCOMPL is null
                       or (TIS.TIS_LOT_REFCOMPL = SUB_TIS.TIS_LOT_REFCOMPL) )
                  and (   TIS.TIS_GAL_REFCOMPL is null
                       or (TIS.TIS_GAL_REFCOMPL = SUB_TIS.TIS_GAL_REFCOMPL) )
                  and TIS.TIS_TASK_LINK_SEQ = SUB_TIS.TIS_TASK_LINK_SEQ
                  and SUB_TIS.TIS_GROUP_ID = TIS.TIS_GROUP_ID)
         and VFI.VFI_TABNAME = 'FAL_TIME_STAMPING'
         and VFI.VFI_REC_ID = TIS.FAL_TIME_STAMPING_ID;

    vTimeStampingId FAL_TIME_STAMPING.FAL_TIME_STAMPING_ID%type;
--     vTaskCount      FAL_TIME_STAMPING.TIS_GROUP_TASK_COUNT%type;
  begin
    for tlpGroupTask in crGroupTasks loop
      insert into FAL_TIME_STAMPING
                  (FAL_TIME_STAMPING_ID
                 , C_TIS_TYPE
                 , C_TIS_STATUS
                 , C_PROGRESS_ORIGIN
                 , TIS_DIC_OPERATOR_ID
                 , TIS_REF_FACTORY_FLOOR
                 , TIS_REF_FACTORY_FLOOR2
                 , TIS_LOT_REFCOMPL
                 , TIS_GAL_REFCOMPL
                 , TIS_TASK_LINK_SEQ
                 , TIS_TASK_LINK_ID
                 , TIS_GROUP_ID
                 , TIS_GROUP_TASK_COUNT
                 , TIS_GROUP_TASK_BAL_COUNT
                 , TIS_STAMPING_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aTimeStamping.C_TIS_TYPE
                 , FAL_TIME_STAMPING_FCT.ssProcessed
                 , nvl(aTimeStamping.C_PROGRESS_ORIGIN, tlpGroupTask.C_PROGRESS_ORIGIN)
                 , aTimeStamping.TIS_DIC_OPERATOR_ID
                 , nvl(aTimeStamping.TIS_REF_FACTORY_FLOOR, tlpGroupTask.TIS_REF_FACTORY_FLOOR)
                 , nvl(aTimeStamping.TIS_REF_FACTORY_FLOOR2, tlpGroupTask.TIS_REF_FACTORY_FLOOR2)
                 , tlpGroupTask.TIS_LOT_REFCOMPL
                 , tlpGroupTask.TIS_GAL_REFCOMPL
                 , tlpGroupTask.TIS_TASK_LINK_SEQ
                 , tlpGroupTask.TIS_TASK_LINK_ID
                 , tlpGroupTask.TIS_GROUP_ID
                 , tlpGroupTask.TIS_GROUP_TASK_COUNT
                 , 0
                 , sysdate
                 , sysdate
                 , nvl(aTimeStamping.A_IDCRE, PCS.PC_I_LIB_SESSION.GetUserIni)
                  )
        returning FAL_TIME_STAMPING_ID
             into vTimeStampingId;

      insert into COM_VFIELDS_RECORD
                  (COM_VFIELDS_RECORD_ID
                 , VFI_TABNAME
                 , VFI_REC_ID
                 , VFI_DESCODES_01
                 , VFI_CHAR_01
                 , VFI_INTEGER_01
                 , VFI_MEMO_01
                 , VFI_CHAR_02
                 , VFI_CHAR_03
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , 'FAL_TIME_STAMPING'
                 , vTimeStampingId
                 , aTimeStamping.C_TIS_TYPE
                 , aTimeStamping.TIS_DIC_OPERATOR_ID
                 , tlpGroupTask.TIS_GROUP_TASK_COUNT
                 , tlpGroupTask.TIS_VCOMBINED_REF
                 , nvl(aTimeStamping.TIS_REF_FACTORY_FLOOR, tlpGroupTask.TIS_REF_FACTORY_FLOOR)
                 , nvl(aTimeStamping.TIS_REF_FACTORY_FLOOR2, tlpGroupTask.TIS_REF_FACTORY_FLOOR2)
                 , sysdate
                 , nvl(aTimeStamping.A_IDCRE, PCS.PC_I_LIB_SESSION.GetUserIni)
                  );
--       vTaskCount  := tlpGroupTask.TIS_GROUP_TASK_COUNT;
    end loop;

    -- Mise à jour de la date afin qu'elle soit supérieur à celle des timnbrage
    -- qu'on vient de créer.
    aTimeStamping.TIS_STAMPING_DATE  := sysdate;
--     aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := 1;
--     aTimeStamping.TIS_GROUP_TASK_COUNT      := vTaskCount;
  end GenerateGroupTimeStampings;

  /**
   * function ManageMultiOp
   * Description
   *   Gestion du mode multi-utilisateur selon la config FAL_TIS_MULTI_OP_MODE
   */
  procedure ManageMultiOp(
    aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aFocusField   in out        varchar2
  , aErrorCode    in out        integer
  , aErrorMessage in out        varchar2
  , aProcessing   in            integer default 0
  )
  is
    vLastTimeStamping FAL_TIME_STAMPING_MNGT.TTIME_STAMPING;
  begin
    if     (cMultiOpMode <> momParallel)
       and aTimeStamping.C_TIS_TYPE in(stStartAdj, stStartWrk)
       and (   aTimeStamping.TIS_GROUP_ID is not null
            or aTimeStamping.TIS_TASK_LINK_SEQ is not null) then
      vLastTimeStamping  := FAL_TIME_STAMPING_MNGT.GetLastOtherOpTimeStamping(aTimeStamping);

      if vLastTimeStamping.FAL_TIME_STAMPING_ID is not null then
        case cMultiOpMode
          when momNone then
            aErrorCode     := 442;
            aErrorMessage  := emErrorTaskInProgressOtherOp;
            aFocusField    := 'TIS_VCOMBINED_REF';
          when momSequential then
            if vLastTimeStamping.C_TIS_TYPE in(stStartAdj, stStartWrk) then
              aErrorCode     := 445;
              aErrorMessage  := replace(emErrorGrpTaskStartedOtherOp, '%operator', vLastTimeStamping.TIS_DIC_OPERATOR_ID);
              aFocusField    := 'TIS_VCOMBINED_REF';
            elsif aProcessing = 0 then
              if vLastTimeStamping.TIS_GROUP_ID is null then
                aErrorCode     := 443;
                aErrorMessage  := emWarningTaskInterrupOtherOp;
              elsif aTimeStamping.TIS_GROUP_ID = vLastTimeStamping.TIS_GROUP_ID then
                aErrorCode     := 444;
                aErrorMessage  := emWarningMyGroupInterOtherOp;
              else
                aErrorCode     := 445;
                aErrorMessage  := emWarningGroupInterrupOtherOp;
--                 aTimeStamping.TIS_GROUP_ID              := vLastTimeStamping.TIS_GROUP_ID;
--                 aTimeStamping.TIS_GROUP_TASK_COUNT      := vLastTimeStamping.TIS_GROUP_TASK_COUNT;
--                 aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := vLastTimeStamping.TIS_GROUP_TASK_COUNT;
              end if;
            elsif vLastTimeStamping.TIS_GROUP_ID is not null then
              if aTimeStamping.TIS_GROUP_ID = vLastTimeStamping.TIS_GROUP_ID then
                aTimeStamping.TIS_VCOMBINED_REF         := null;
                aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := 1;
              else
                aTimeStamping.TIS_GROUP_ID              := vLastTimeStamping.TIS_GROUP_ID;
                aTimeStamping.TIS_GROUP_TASK_COUNT      := vLastTimeStamping.TIS_GROUP_TASK_COUNT;
                GenerateGroupTimeStampings(aTimeStamping);
                aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := 1;
              end if;
            end if;
        end case;
      end if;
    end if;
  end ManageMultiOp;

  /**
   * procedure InitGroupInfos
   * Description
   *   Initialisation des infos de regroupement
   */
  procedure InitGroupInfos(aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING, aLastTimeStamping in FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
  is
  begin
    -- Si le solde d'opération à grouper n'est pas à zéro, on recopie les données
    if nvl(aLastTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) > 0 then
      aTimeStamping.TIS_DIC_OPERATOR_ID       := aLastTimeStamping.TIS_DIC_OPERATOR_ID;
      aTimeStamping.C_TIS_TYPE                := aLastTimeStamping.C_TIS_TYPE;
      aTimeStamping.TIS_GROUP_ID              := aLastTimeStamping.TIS_GROUP_ID;
      aTimeStamping.TIS_GROUP_TASK_COUNT      := aLastTimeStamping.TIS_GROUP_TASK_COUNT;
      aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := aLastTimeStamping.TIS_GROUP_TASK_BAL_COUNT;
    end if;
  end InitGroupInfos;

  /**
   * procedure ClearGroupInfos
   * Description
   *   Effacement des infos de regroupement
   */
  procedure ClearGroupInfos(aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
  is
  begin
    -- Remise à zéro des infos de regroupement
    aTimeStamping.TIS_GROUP_ID              := null;
    aTimeStamping.TIS_GROUP_TASK_COUNT      := null;
    aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := null;
  end ClearGroupInfos;

  /**
   * procedure GroupTaskAdded
   * Description
   *   Gestiop des infos de regroupement (compteru, etc.) après l'ajout d'une
   *   opération au groupe.
   */
  procedure GroupTaskAdded(aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
  is
  begin
    -- On décrémente le solde d'opérations à grouper
    aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := aTimeStamping.TIS_GROUP_TASK_BAL_COUNT - 1;
  end GroupTaskAdded;

  /**
   * procedure SelectNextStampToDo
   * Description
   *   Sélection du prochain timbrage à effectuer pour l'opérateur sélectionné.
   */
  procedure SelectNextStampToDo(
    aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aFocusField   in out        varchar2
  , aErrorCode    in out        integer
  , aErrorMessage in out        varchar2
  )
  is
    vLastTimeStamping FAL_TIME_STAMPING_MNGT.TTIME_STAMPING;
  begin
    -- Si l'opérateur n'est pas null, on recherche le prochain timbrage qu'il
    -- devrait effectuer.
    if aTimeStamping.TIS_DIC_OPERATOR_ID is not null then
      vLastTimeStamping  := FAL_TIME_STAMPING_MNGT.GetLastTimeStamping(aTimeStamping);

      -- Si l'on est pas en début de réglage ou de travail, pas de gestion de
      -- compteur regroupement => pas de report de valeur de champs
      if vLastTimeStamping.C_TIS_TYPE in(stStartAdj, stStartWrk) then
        -- Initialisation des données de regroupement
        InitGroupInfos(aTimeStamping, vLastTimeStamping);
      end if;

      -- Si l'on est dans un regroupement, on se positionne directement sur la réf
      if nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) > 0 then
        aFocusField  := 'TIS_VCOMBINED_REF';
      else
        -- Sinon on détermine le type du prochain timbrage
        case vLastTimeStamping.C_TIS_TYPE
          when stStartAdj then
            aTimeStamping.C_TIS_TYPE  := stStartWrk;
          when stStartWrk then
            aTimeStamping.C_TIS_TYPE  := stEnd;
            aFocusField               := 'TIS_VPRODUCT_QTY';
          else
            if cProgressMode = 1 then
              aTimeStamping.C_TIS_TYPE  := stStartAdj;
            else
              aTimeStamping.C_TIS_TYPE  := stStartWrk;
            end if;
        end case;

        aTimeStamping.C_PROGRESS_ORIGIN  := vLastTimeStamping.C_PROGRESS_ORIGIN;
      end if;

      -- Gestion des infos de groupe ou de la réf combinée
      if vLastTimeStamping.C_TIS_TYPE <> stEnd then
        if vLastTimeStamping.TIS_GROUP_ID is not null then
          aTimeStamping.TIS_GROUP_ID  := vLastTimeStamping.TIS_GROUP_ID;
        else
          aTimeStamping.TIS_VCOMBINED_REF  := vLastTimeStamping.TIS_VCOMBINED_REF;
        end if;
      end if;
    end if;
  end SelectNextStampToDo;

  /**
   * procedure CheckTimeStampingType
   * Description
   *   Contrôle du type de timbrage.
   */
  procedure CheckTimeStampingType(
    aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aFocusField   in out        varchar2
  , aErrorCode    in out        integer
  , aErrorMessage in out        varchar2
  , aCheckRefNull in            boolean default false
  )
  is
    vLastTimeStamping FAL_TIME_STAMPING_MNGT.TTIME_STAMPING;
  begin
    -- Le type de timbrage est obligatoire
    if aTimeStamping.C_TIS_TYPE is null then
      aErrorCode     := 471;
      aErrorMessage  := emTisTypeCantBeNull;
    end if;

    -- Vérification uniquement si l'on a un opérateur
    if aTimeStamping.TIS_DIC_OPERATOR_ID is not null then
      -- Recherche des timbrages ouverts de l'opérateur
      vLastTimeStamping  := FAL_TIME_STAMPING_MNGT.GetLastTimeStamping(aTimeStamping);

      -- Contrôle du regroupement
      if     (aTimeStamping.TIS_GROUP_TASK_BAL_COUNT > 0)
         and aTimeStamping.TIS_VCOMBINED_REF is not null then
        CanGroupTimeStamping(aTimeStamping, vLastTimeStamping, aFocusField, aErrorCode, aErrorMessage);
      end if;

      -- Contrôle et mise à jour des infos de groupe vs référence op
      if vLastTimeStamping.C_TIS_TYPE in(stStartAdj, stStartWrk) then   --, stInterrupt) then
        if vLastTimeStamping.TIS_GROUP_ID is not null then
          if     nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) <= 0
             and aTimeStamping.TIS_VCOMBINED_REF is not null then
            aErrorCode     := 495;
            aErrorMessage  := emGroupEndRequiredBeforeTask;
          else
            aTimeStamping.TIS_GROUP_ID  := vLastTimeStamping.TIS_GROUP_ID;

            if aTimeStamping.TIS_VCOMBINED_REF is null then
              if     aCheckRefNull
                 and (aTimeStamping.TIS_GROUP_TASK_BAL_COUNT > 0)
                 and (aTimeStamping.C_TIS_TYPE = vLastTimeStamping.C_TIS_TYPE) then
                aErrorCode     := 418;
                aErrorMessage  := emCombinedRefCantBeNull;
                aFocusField    := 'TIS_VCOMBINED_REF';
              end if;
            else
              aTimeStamping.C_PROGRESS_ORIGIN  := vLastTimeStamping.C_PROGRESS_ORIGIN;
            end if;
          end if;
        elsif aTimeStamping.TIS_VCOMBINED_REF <> vLastTimeStamping.TIS_VCOMBINED_REF then
          aErrorCode     := 435;
          aErrorMessage  := emEndRequiredBeforeStart;
        elsif     aCheckRefNull
              and aTimeStamping.TIS_VCOMBINED_REF is null then
          aErrorCode     := 418;
          aErrorMessage  := emCombinedRefCantBeNull;
          aFocusField    := 'TIS_VCOMBINED_REF';
        end if;
      elsif vLastTimeStamping.C_TIS_TYPE = stInterrupt then
        if     vLastTimeStamping.TIS_GROUP_ID is not null
           and aTimeStamping.TIS_VCOMBINED_REF is null then
          aTimeStamping.TIS_GROUP_ID  := vLastTimeStamping.TIS_GROUP_ID;
        end if;

        if aTimeStamping.TIS_VCOMBINED_REF is not null then
          aTimeStamping.TIS_GROUP_ID  := null;
        end if;
      elsif     aCheckRefNull
            and aTimeStamping.TIS_VCOMBINED_REF is null then
        aErrorCode     := 418;
        aErrorMessage  := emCombinedRefCantBeNull;
        aFocusField    := 'TIS_VCOMBINED_REF';
      end if;

      case aTimeStamping.C_TIS_TYPE
        when stStartAdj then
          if vLastTimeStamping.C_TIS_TYPE = stStartAdj then
            if (nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) <= 0) then
              aErrorCode     := 472;
              aErrorMessage  := emStopCurrentBefore;
            end if;
          elsif     (vLastTimeStamping.C_TIS_TYPE = stStartWrk)
                and (aTimeStamping.TIS_GROUP_TASK_BAL_COUNT > 0) then
            aErrorCode     := 427;
            aErrorMessage  := emWarningGroupingInProgress;
          end if;
        when stStartWrk then
          if vLastTimeStamping.C_TIS_TYPE = stStartWrk then
            if (nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) <= 0) then
              aErrorCode     := 475;
              aErrorMessage  := emStopCurrentBefore;
            end if;
          elsif     (vLastTimeStamping.C_TIS_TYPE = stStartAdj)
                and (aTimeStamping.TIS_GROUP_TASK_BAL_COUNT > 0) then
            aErrorCode     := 428;
            aErrorMessage  := emWarningGroupingInProgress;
          end if;
        when stInterrupt then
          if vLastTimeStamping.C_TIS_TYPE not in(stStartAdj, stStartWrk) then
            aErrorCode     := 465;
            aErrorMessage  := emNoItemToInterrupt;
          elsif aTimeStamping.TIS_GROUP_TASK_BAL_COUNT > 0 then
            aErrorCode     := 429;
            aErrorMessage  := emWarningGroupingInProgress;
          end if;
        when stEnd then
          if vLastTimeStamping.C_TIS_TYPE not in(stStartAdj, stStartWrk) then
            aErrorCode     := 468;
            aErrorMessage  := emNoItemToEnd;
          elsif aTimeStamping.TIS_GROUP_TASK_BAL_COUNT > 0 then
            aErrorCode     := 428;
            aErrorMessage  := emWarningGroupingInProgress;
          end if;

          if vLastTimeStamping.C_TIS_TYPE = stStartAdj then
            aErrorCode     := 438;
            aErrorMessage  := emStartWorkBeforeEnd;
          end if;
      end case;
    end if;
  end CheckTimeStampingType;

  /**
   * procedure CanGroupTimeStamping
   * Description
   *   Contrôle de l'autorisation de regroupement des timbrages.
   */
  procedure CanGroupTimeStamping(
    aTimeStamping     in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aLastTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aFocusField       in out        varchar2
  , aErrorCode        in out        integer
  , aErrorMessage     in out        varchar2
  )
  is
    cursor crGalTaskInfos
    is
      select TAL.C_TASK_TYPE
           , TAS.GAL_FATHER_TASK_ID
        from GAL_TASK_LINK TAL
           , GAL_TASK TAS
       where TAL.GAL_TASK_LINK_ID = aTimeStamping.TIS_TASK_LINK_ID
         and TAS.GAL_TASK_ID = TAL.GAL_TASK_ID;

    tplGalTaskInfos crGalTaskInfos%rowtype;

    cursor crFalTaskInfos
    is
      select LOT.GCO_GOOD_ID
           , LLOT.GCO_GOOD_ID GCO_LAST_GOOD_ID
        from FAL_TASK_LINK TAL
           , FAL_LOT LOT
           , FAL_TASK_LINK LTAL
           , FAL_LOT LLOT
       where TAL.FAL_SCHEDULE_STEP_ID = aTimeStamping.TIS_TASK_LINK_ID
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
         and LTAL.FAL_SCHEDULE_STEP_ID = aLastTimeStamping.TIS_TASK_LINK_ID
         and LLOT.FAL_LOT_ID = LTAL.FAL_LOT_ID;

    tplFalTaskInfos crFalTaskInfos%rowtype;
  begin
    if aTimeStamping.C_PROGRESS_ORIGIN <> aLastTimeStamping.C_PROGRESS_ORIGIN then
      aErrorCode     := 415;
      aErrorMessage  := emDifferentOriginsProhibited;
    elsif aTimeStamping.C_PROGRESS_ORIGIN = poProduction then
      if cCheckProdGrouping = 1 then
        -- Contrôles spécifiques FAL
        open crFalTaskInfos;

        fetch crFalTaskInfos
         into tplFalTaskInfos;

        if    not crFalTaskInfos%found
           or (tplFalTaskInfos.GCO_GOOD_ID <> tplFalTaskInfos.GCO_LAST_GOOD_ID) then
          aErrorCode     := 417;
          aErrorMessage  := emDiffProductsCantBeGrouped;
        end if;

        close crFalTaskInfos;
      end if;
    elsif aTimeStamping.C_PROGRESS_ORIGIN = poProject then
      -- Contrôles spécifiques GAL
      open crGalTaskInfos;

      fetch crGalTaskInfos
       into tplGalTaskInfos;

      if    not crGalTaskInfos%found
         or (tplGalTaskInfos.C_TASK_TYPE = '2') then
        --or tplGalTaskInfos.GAL_FATHER_TASK_ID is null then
        aErrorCode     := 418;
        aErrorMessage  := emInternalTaskOnlyCanBeGrouped;
      end if;

      close crGalTaskInfos;
    end if;
  end CanGroupTimeStamping;

  /**
   * procedure ArchiveTimeStampings
   * Description
   *   Archivage du timbrage (à condition que ce soit un timbrage de fin) et de
   *   tous les timbrages liés.
   */
  procedure ArchiveTimeStampings(aTimeStamping in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
  is
  begin
    -- Si c'est un timbrage de fin de groupe ou d'opération,
    -- on archive tous les timbrages liés à ce groupe ou opération.
    if aTimeStamping.C_TIS_TYPE = stEnd then
      aTimeStamping.C_TIS_STATUS  := FAL_TIME_STAMPING_FCT.ssArchived;

      update FAL_TIME_STAMPING
         set C_TIS_STATUS = aTimeStamping.C_TIS_STATUS
       where C_TIS_STATUS = FAL_TIME_STAMPING_FCT.ssProcessed
         and (   TIS_DIC_OPERATOR_ID = aTimeStamping.TIS_DIC_OPERATOR_ID
              or cMultiOpMode = momSequential)
         and nvl(TIS_GROUP_ID, -1) = nvl(aTimeStamping.TIS_GROUP_ID, -1)
         and (   TIS_GROUP_ID is not null
              or     (   TIS_LOT_REFCOMPL is null
                      or (TIS_LOT_REFCOMPL = aTimeStamping.TIS_LOT_REFCOMPL) )
                 and (   TIS_GAL_REFCOMPL is null
                      or (TIS_GAL_REFCOMPL = aTimeStamping.TIS_GAL_REFCOMPL) )
                 and (   TIS_TASK_LINK_SEQ is null
                      or (TIS_TASK_LINK_SEQ = aTimeStamping.TIS_TASK_LINK_SEQ) )
             );
    end if;
  end ArchiveTimeStampings;

  /**
   * procedure GenerateFogRecord
   * Description
   *   Génération d'un enregistrement dans le brouillard.
   */
  procedure GenerateFogRecord(
    aTimeStamping  in FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aAdjustingTime in FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type default 0
  , aWorkTime      in FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type default 0
  )
  is
    vAdjustingTime FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type;
    vWorkTime      FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type;
  begin
    -- Gestion de la config FAL_PROGRESS_MODE
    if cProgressMode = 1 then
      vAdjustingTime  := aAdjustingTime;
      vWorkTime       := aWorkTime;
    else
      vAdjustingTime  := 0;
      vWorkTime       := nvl(aWorkTime, 0) + nvl(aAdjustingTime, 0);
    end if;

    -- Conversion si nécessaire en fonction de la valeur de PPS_WORK_UNIT
    if aTimeStamping.C_PROGRESS_ORIGIN = poProduction then
      if cWorkUnit = 'M' then
        vAdjustingTime  := vAdjustingTime * 60;
        vWorkTime       := vWorkTime * 60;
      end if;
    end if;

    -- Insertion dans le brouillard
    insert into FAL_LOT_PROGRESS_FOG
                (FAL_LOT_PROGRESS_FOG_ID
               , C_PFG_STATUS
               , C_PROGRESS_ORIGIN
               , PFG_DIC_OPERATOR_ID
               , PFG_REF_FACTORY_FLOOR
               , PFG_REF_FACTORY_FLOOR2
               , PFG_LOT_REFCOMPL
               , PFG_GAL_REFCOMPL
               , PFG_SEQ
               , PFG_DATE
               , PFG_ADJUSTING_TIME
               , PFG_WORK_TIME
               , PFG_PRODUCT_QTY
               , PFG_PT_REFECT_QTY
               , PFG_CPT_REJECT_QFY
               , PFG_PRODUCT_QTY_UOP
               , PFG_PT_REJECT_QTY_UOP
               , PFG_CPT_REJECT_QTY_UOP
               , PFG_DIC_REBUT_ID
               , PFG_LABEL_CONTROL
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , cDefaultPfgStatus
               , nvl(aTimeStamping.C_PROGRESS_ORIGIN, '10')
               , aTimeStamping.TIS_DIC_OPERATOR_ID
               , aTimeStamping.TIS_REF_FACTORY_FLOOR
               , aTimeStamping.TIS_REF_FACTORY_FLOOR2
               , aTimeStamping.TIS_LOT_REFCOMPL
               , aTimeStamping.TIS_GAL_REFCOMPL
               , aTimeStamping.TIS_TASK_LINK_SEQ
               , aTimeStamping.TIS_STAMPING_DATE
               , vAdjustingTime
               , vWorkTime
               , nvl(aTimeStamping.TIS_PRODUCT_QTY, 0)
               , aTimeStamping.TIS_PT_REJECT_QTY
               , aTimeStamping.TIS_CPT_REJECT_QTY
               , aTimeStamping.TIS_PRODUCT_QTY_UOP
               , aTimeStamping.TIS_PT_REJECT_QTY_UOP
               , aTimeStamping.TIS_CPT_REJECT_QTY_UOP
               , aTimeStamping.TIS_VDIC_REBUT_ID
               , aTimeStamping.TIS_VLABEL_CONTROL
               , sysdate
               , aTimeStamping.A_IDCRE
                );
  end GenerateFogRecord;

  /**
   * procedure GenerateFalFogRecords
   * Description
   *   Génération des enregistrements dans le brouillard en répartissant les
   *   durées et quantités pour des opérations de lot.
   */
  procedure GenerateFalFogRecords(
    aTimeStamping  in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aAdjustingTime in            FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type default 0
  , aWorkTime      in            FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type default 0
  )
  is
    cursor crTaskLinks(aTimeStamping in FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
    is
      select   TIS.FAL_TIME_STAMPING_ID
             , TIS.C_PROGRESS_ORIGIN
             , TIS.TIS_LOT_REFCOMPL
             , TIS.TIS_TASK_LINK_SEQ
             , TAL.TAL_AVALAIBLE_QTY
             , TAL.TAL_DUE_QTY
             , LOT.GCO_GOOD_ID
          from FAL_TIME_STAMPING TIS
             , FAL_TASK_LINK TAL
             , FAL_LOT LOT
         where TIS.TIS_DIC_OPERATOR_ID = aTimeStamping.TIS_DIC_OPERATOR_ID
           and TIS.TIS_STAMPING_DATE <= aTimeStamping.TIS_STAMPING_DATE
           and TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
           and (   aTimeStamping.TIS_LOT_REFCOMPL is null
                or (TIS.TIS_LOT_REFCOMPL = aTimeStamping.TIS_LOT_REFCOMPL) )
           and (   aTimeStamping.TIS_TASK_LINK_SEQ is null
                or (TIS.TIS_TASK_LINK_SEQ = aTimeStamping.TIS_TASK_LINK_SEQ) )
           and TIS.TIS_TASK_LINK_SEQ is not null
           and nvl(TIS.TIS_GROUP_ID, -1) = nvl(aTimeStamping.TIS_GROUP_ID, -1)
           and not exists(
                 select FAL_TIME_STAMPING_ID
                   from FAL_TIME_STAMPING SUB_TIS
                  where SUB_TIS.TIS_DIC_OPERATOR_ID = TIS.TIS_DIC_OPERATOR_ID
                    and SUB_TIS.C_TIS_STATUS <> '50'
                    and SUB_TIS.TIS_STAMPING_DATE >= TIS.TIS_STAMPING_DATE
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> TIS.FAL_TIME_STAMPING_ID
                    and SUB_TIS.TIS_STAMPING_DATE <= aTimeStamping.TIS_STAMPING_DATE
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
                    and (   SUB_TIS.TIS_LOT_REFCOMPL is null
                         or (TIS.TIS_LOT_REFCOMPL = SUB_TIS.TIS_LOT_REFCOMPL) )
                    and (   SUB_TIS.TIS_TASK_LINK_SEQ is null
                         or (TIS.TIS_TASK_LINK_SEQ = SUB_TIS.TIS_TASK_LINK_SEQ) )
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> TIS.FAL_TIME_STAMPING_ID
                    and (   SUB_TIS.TIS_GROUP_ID is null
                         or (SUB_TIS.TIS_GROUP_ID <> TIS.TIS_GROUP_ID) ) )
           and TAL.FAL_SCHEDULE_STEP_ID = TIS.TIS_TASK_LINK_ID(+)
           and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID(+)
      order by TIS.TIS_STAMPING_DATE asc
             , TIS.FAL_TIME_STAMPING_ID asc;

    tplTaskLink                 crTaskLinks%rowtype;

    type TTaskLinks is table of crTaskLinks%rowtype;

    vTaskLinks                  TTaskLinks;
    vProgressOrigin             FAL_TIME_STAMPING.C_PROGRESS_ORIGIN%type;
    vLotRefCompl                FAL_TIME_STAMPING.TIS_LOT_REFCOMPL%type;
    vTaskLinkSeq                FAL_TIME_STAMPING.TIS_TASK_LINK_SEQ%type;
    vTotalProductQty            FAL_TIME_STAMPING.TIS_PRODUCT_QTY%type;
    vTotalPtRejectQty           FAL_TIME_STAMPING.TIS_PT_REJECT_QTY%type;
    vTotalCptRejectQty          FAL_TIME_STAMPING.TIS_CPT_REJECT_QTY%type;
    vTotalQty                   FAL_TIME_STAMPING.TIS_PRODUCT_QTY%type;
    vBalProductQty              FAL_TIME_STAMPING.TIS_PRODUCT_QTY%type;
    vBalPtRejectQty             FAL_TIME_STAMPING.TIS_PT_REJECT_QTY%type;
    vBalCptRejectQty            FAL_TIME_STAMPING.TIS_CPT_REJECT_QTY%type;
    vBalQty                     FAL_TIME_STAMPING.TIS_PRODUCT_QTY%type;
    vBalAdjustingTime           FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type;
    vBalWorkTime                FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type;
    vAdjustingTime              FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type;
    vWorkTime                   FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type;
    vTotalAvbleQty              FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type           := 0;
    vTotalDueQty                FAL_TASK_LINK.TAL_DUE_QTY%type                 := 0;
    vTotalAvbleOrDueQty         FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type           := 0;
    vTalAvbleOrDueQty           FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type;
    vQty                        FAL_TIME_STAMPING.TIS_PRODUCT_QTY%type;
    vFactor                     number(16, 8);
    vIndex                      integer;
    vRoundFormat                number(15, 4);
    cAvailableQtyField constant integer                                        := 1;
    cDueQtyField       constant integer                                        := 2;
  begin
    open crTaskLinks(aTimeStamping);

    fetch crTaskLinks
    bulk collect into vTaskLinks;

    close crTaskLinks;

    if vTaskLinks.count = 0 then
      raise_application_error(-20321, 'Last time stamping not found!');
    else
      -- Recherche du nombre de décimales gérées par le produit pour l'arrondi
      -- des quantités (toutes les opérations portent sur le même produit)
      vRoundFormat                      := 1 / power(10, nvl(GCO_FUNCTIONS.GetNumberOfDecimal(vTaskLinks(vTaskLinks.first).GCO_GOOD_ID), 0) );

      -- Calcul de la quantité totale des opérations
      for vForIndex in vTaskLinks.first .. vTaskLinks.last loop
        vTotalAvbleQty  := vTotalAvbleQty + nvl(vTaskLinks(vForIndex).TAL_AVALAIBLE_QTY, 0);
        vTotalDueQty    := vTotalDueQty + nvl(vTaskLinks(vForIndex).TAL_DUE_QTY, 0);
      end loop;

      -- Sauvegarde
      vProgressOrigin                   := aTimeStamping.C_PROGRESS_ORIGIN;
      vLotRefCompl                      := aTimeStamping.TIS_LOT_REFCOMPL;
      vTaskLinkSeq                      := aTimeStamping.TIS_TASK_LINK_SEQ;
      -- Totaux timbrage
      vTotalProductQty                  := aTimeStamping.TIS_PRODUCT_QTY;
      vTotalPtRejectQty                 := aTimeStamping.TIS_PT_REJECT_QTY;
      vTotalCptRejectQty                := aTimeStamping.TIS_CPT_REJECT_QTY;
      vTotalQty                         := nvl(vTotalProductQty, 0) + nvl(vTotalPtRejectQty, 0) + nvl(vTotalCptRejectQty, 0);
      -- Totaux timbrage restant à attribuer à des avancements
      vBalProductQty                    := vTotalProductQty;
      vBalPtRejectQty                   := vTotalPtRejectQty;
      vBalCptRejectQty                  := vTotalCptRejectQty;
      vBalQty                           := vTotalQty;
      vBalAdjustingTime                 := aAdjustingTime;
      vBalWorkTime                      := aWorkTime;

      for vQtyField in cAvailableQtyField .. cDueQtyField loop
        -- Si les quantités dispo sont toutes à 0, on passe directement à la
        -- répartition selon les quantités soldes
        if    (vQtyField = cDueQtyField)
           or (vTotalAvbleQty > 0) then
          -- Total des quantités opérations selon l'index de passage
          case vQtyField
            when cAvailableQtyField then
              vTotalAvbleOrDueQty  := vTotalAvbleQty;
            when cDueQtyField then
              vTotalAvbleOrDueQty  := vTotalDueQty;
          end case;

          vIndex  := vTaskLinks.first;

          -- Tant qu'il reste des opérations à traiter et des quantités ou durées à attribuer
          while vIndex <= vTaskLinks.last
           and (   vBalProductQty > 0
                or vBalPtRejectQty > 0
                or vBalCptRejectQty > 0
                or vBalAdjustingTime > 0
                or vBalWorkTime > 0) loop
            -- Si l'on est en répartition selon quantités dispo et que la
            -- quantité dispo est à 0, on n'attribue rien
            if    (vQtyField = cDueQtyField)
               or (nvl(vTaskLinks(vIndex).TAL_AVALAIBLE_QTY, 0) > 0) then
              -- Assignation des infos de l'opération courante dans le record
              aTimeStamping.C_PROGRESS_ORIGIN  := vTaskLinks(vIndex).C_PROGRESS_ORIGIN;
              aTimeStamping.TIS_LOT_REFCOMPL   := vTaskLinks(vIndex).TIS_LOT_REFCOMPL;
              aTimeStamping.TIS_TASK_LINK_SEQ  := vTaskLinks(vIndex).TIS_TASK_LINK_SEQ;

              if     vIndex = vTaskLinks.last
                 and (vQtyField = cDueQtyField) then
                -- Si c'est la dernière opération, on attribue tout ce qu'il reste
                aTimeStamping.TIS_PRODUCT_QTY     := vBalProductQty;
                aTimeStamping.TIS_PT_REJECT_QTY   := vBalPtRejectQty;
                aTimeStamping.TIS_CPT_REJECT_QTY  := vBalCptRejectQty;
                vAdjustingTime                    := vBalAdjustingTime;
                vWorkTime                         := vBalWorkTime;
              else
                -- Sinon on attribue la quantité produite au max de la quantité demandée,
                -- et les déchets et durée proportionnellement (selon la quantité produite
                -- ou la quantité disponible ou solde si la quantité produite est 0)

                -- Quantité demandée pour l'opération
                case vQtyField
                  when cAvailableQtyField then
                    vTalAvbleOrDueQty  := nvl(vTaskLinks(vIndex).TAL_AVALAIBLE_QTY, 0);
                  when cDueQtyField then
                    vTalAvbleOrDueQty  := nvl(vTaskLinks(vIndex).TAL_DUE_QTY, 0);
                end case;

                -- Si des quantités ont été saisies pour le timbrage
                if vTotalQty > 0 then
                  -- On attribue à l'opération la quantité requise dans la limite de la quantité attribuable
                  vQty                              := least(vBalQty, vTalAvbleOrDueQty);

                  -- On calcule le facteur quantité attribuée sur quantité totale pour la répartition des rebuts
                  -- On utilise les quantités demandées si les quantités réalisées sont nulles
                  if nvl(vQty, 0) = 0 then
                    vFactor  := vTalAvbleOrDueQty / nvl(FAL_TOOLS.nifz(vTotalAvbleOrDueQty), 1);
                  else
                    vFactor  := vQty / vTotalQty;
                  end if;

                  -- On répartit les rebuts selon le facteur dans la limite attribuable ('4' = arrondi supérieur)
                  aTimeStamping.TIS_PT_REJECT_QTY   := least(vBalPtRejectQty, ACS_FUNCTION.PcsRound(vFactor * vTotalPtRejectQty, '4', vRoundFormat) );
                  aTimeStamping.TIS_CPT_REJECT_QTY  := least(vBalCptRejectQty, ACS_FUNCTION.PcsRound(vFactor * vTotalCptRejectQty, '4', vRoundFormat) );
                  -- On calcule la quantité "bonne" réalisée
                  aTimeStamping.TIS_PRODUCT_QTY     :=
                     least(vBalProductQty, greatest(0, vTalAvbleOrDueQty - nvl(aTimeStamping.TIS_PT_REJECT_QTY, 0) - nvl(aTimeStamping.TIS_CPT_REJECT_QTY, 0) ) );

                  -- Répartition des temps de réglage et de travail
                  if     nvl(vBalProductQty, 0) = nvl(aTimeStamping.TIS_PRODUCT_QTY, 0)
                     and nvl(vBalPtRejectQty, 0) = nvl(aTimeStamping.TIS_PT_REJECT_QTY, 0)
                     and nvl(vBalCptRejectQty, 0) = nvl(aTimeStamping.TIS_CPT_REJECT_QTY, 0) then
                    -- Si toutes les quantités ont été attribuées, on attribue tout le temps restant
                    vAdjustingTime  := vBalAdjustingTime;
                    vWorkTime       := vBalWorkTime;
                  else
                    -- Sinon répartition selon le facteur somme des quantités attribuées à l'opération sur somme des quantités totales à attribuer
                    vFactor         := vQty / vTotalQty;
                    -- On attribue selon le facteur dans la limite attribuable
                    vAdjustingTime  := least(vBalAdjustingTime, vFactor * aAdjustingTime);
                    vWorkTime       := least(vBalWorkTime, vFactor * aWorkTime);
                  end if;
                else
                  -- Pas de quantités saisies, seulement un avancement en travail/réglage
                  -- On répartit les temps de réglage et de travail selon les quantités demandées
                  -- Si la quantité dispo totale est nulle (voir début boucle for),
                  -- on répartit selon les quantités soldes, et en dernier recours
                  -- selon le nombre d'opérations.
                  if vTotalAvbleOrDueQty > 0 then
                    vFactor  := vTalAvbleOrDueQty / vTotalAvbleOrDueQty;
                  else
                    vFactor  := 1 / vTaskLinks.count;
                  end if;

                  vAdjustingTime  := least(vBalAdjustingTime, vFactor * aAdjustingTime);
                  vWorkTime       := least(vBalWorkTime, vFactor * aWorkTime);
                end if;
              end if;

              -- Génération d'un enregistrement dans le brouillard
              if    (vAdjustingTime > 0)
                 or (vWorkTime > 0)
                 or (aTimeStamping.TIS_PRODUCT_QTY > 0)
                 or (aTimeStamping.TIS_PT_REJECT_QTY > 0)
                 or (aTimeStamping.TIS_CPT_REJECT_QTY > 0) then
                GenerateFogRecord(aTimeStamping => aTimeStamping, aAdjustingTime => vAdjustingTime, aWorkTime => vWorkTime);
              end if;

              -- Mise à jour des quantités et durée restant à attribuer
              vBalProductQty                   := vBalProductQty - aTimeStamping.TIS_PRODUCT_QTY;
              vBalPtRejectQty                  := vBalPtRejectQty - aTimeStamping.TIS_PT_REJECT_QTY;
              vBalCptRejectQty                 := vBalCptRejectQty - aTimeStamping.TIS_CPT_REJECT_QTY;
              vBalQty                          := nvl(vBalProductQty, 0) + nvl(vBalPtRejectQty, 0) + nvl(vBalCptRejectQty, 0);
              vBalAdjustingTime                := vBalAdjustingTime - vAdjustingTime;
              vBalWorkTime                     := vBalWorkTime - vWorkTime;
              -- Mise à jour de la quantité solde pour le second passage
              vTaskLinks(vIndex).TAL_DUE_QTY   :=
                             vTaskLinks(vIndex).TAL_DUE_QTY - aTimeStamping.TIS_PRODUCT_QTY - aTimeStamping.TIS_PT_REJECT_QTY - aTimeStamping.TIS_CPT_REJECT_QTY;
            end if;

            vIndex  := vIndex + 1;
          end loop;
        end if;
      end loop;

      -- Restauration
      aTimeStamping.TIS_PRODUCT_QTY     := vTotalProductQty;
      aTimeStamping.TIS_PT_REJECT_QTY   := vTotalPtRejectQty;
      aTimeStamping.TIS_CPT_REJECT_QTY  := vTotalCptRejectQty;
      aTimeStamping.TIS_LOT_REFCOMPL    := vLotRefCompl;
      aTimeStamping.TIS_TASK_LINK_SEQ   := vTaskLinkSeq;
      aTimeStamping.C_PROGRESS_ORIGIN   := vProgressOrigin;
    end if;
  end GenerateFalFogRecords;

  /**
   * procedure GenerateGalFogRecords
   * Description
   *   Génération des enregistrements dans le brouillard en répartissant les
   *   durées et quantités pour des opérations d'OF ou des codes indirects.
   */
  procedure GenerateGalFogRecords(
    aTimeStamping  in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aAdjustingTime in            FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type default 0
  , aWorkTime      in            FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type default 0
  )
  is
    cursor crTaskLinks(aTimeStamping in FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
    is
      select   TIS.FAL_TIME_STAMPING_ID
             , TIS.C_PROGRESS_ORIGIN
             , TIS.TIS_GAL_REFCOMPL
             , TIS.TIS_TASK_LINK_SEQ
             , TIS.TIS_TASK_LINK_ID
             , TAL.TAL_DUE_TSK
          from FAL_TIME_STAMPING TIS
             , GAL_TASK_LINK TAL
         where TIS.TIS_DIC_OPERATOR_ID = aTimeStamping.TIS_DIC_OPERATOR_ID
           and TIS.TIS_STAMPING_DATE <= aTimeStamping.TIS_STAMPING_DATE
           and TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
           and (   aTimeStamping.TIS_GAL_REFCOMPL is null
                or (TIS.TIS_GAL_REFCOMPL = aTimeStamping.TIS_GAL_REFCOMPL) )
           and (   aTimeStamping.TIS_TASK_LINK_SEQ is null
                or (TIS.TIS_TASK_LINK_SEQ = aTimeStamping.TIS_TASK_LINK_SEQ) )
           and TIS.TIS_GAL_REFCOMPL is not null
           and nvl(TIS.TIS_GROUP_ID, -1) = nvl(aTimeStamping.TIS_GROUP_ID, -1)
           and not exists(
                 select FAL_TIME_STAMPING_ID
                   from FAL_TIME_STAMPING SUB_TIS
                  where SUB_TIS.TIS_DIC_OPERATOR_ID = TIS.TIS_DIC_OPERATOR_ID
                    and SUB_TIS.C_TIS_STATUS <> '50'
                    and SUB_TIS.TIS_STAMPING_DATE >= TIS.TIS_STAMPING_DATE
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> TIS.FAL_TIME_STAMPING_ID
                    and SUB_TIS.TIS_STAMPING_DATE <= aTimeStamping.TIS_STAMPING_DATE
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
                    and (   SUB_TIS.TIS_GAL_REFCOMPL is null
                         or (TIS.TIS_GAL_REFCOMPL = SUB_TIS.TIS_GAL_REFCOMPL) )
                    and (   SUB_TIS.TIS_TASK_LINK_SEQ is null
                         or (TIS.TIS_TASK_LINK_SEQ = SUB_TIS.TIS_TASK_LINK_SEQ) )
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> TIS.FAL_TIME_STAMPING_ID
                    and (   SUB_TIS.TIS_GROUP_ID is null
                         or (SUB_TIS.TIS_GROUP_ID <> TIS.TIS_GROUP_ID) ) )
           and TAL.GAL_TASK_LINK_ID = TIS.TIS_TASK_LINK_ID
      order by TIS.TIS_STAMPING_DATE asc
             , TIS.FAL_TIME_STAMPING_ID asc;

    tplTaskLink       crTaskLinks%rowtype;

    type TTaskLinks is table of crTaskLinks%rowtype;

    vTaskLinks        TTaskLinks;
    vProgressOrigin   FAL_TIME_STAMPING.C_PROGRESS_ORIGIN%type;
    vGalRefCompl      FAL_TIME_STAMPING.TIS_GAL_REFCOMPL%type;
    vTaskLinkSeq      FAL_TIME_STAMPING.TIS_TASK_LINK_SEQ%type;
    vTaskLinkId       FAL_TIME_STAMPING.TIS_TASK_LINK_ID%type;
    vBalAdjustingTime FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type;
    vBalWorkTime      FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type;
    vAdjustingTime    FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type;
    vWorkTime         FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type;
    vTotalDueTsk      GAL_TASK_LINK.TAL_DUE_TSK%type                 := 0;
    vFactor           number(16, 8);
    vIndex            integer;
  begin
    open crTaskLinks(aTimeStamping);

    fetch crTaskLinks
    bulk collect into vTaskLinks;

    close crTaskLinks;

    if vTaskLinks.count = 0 then
      raise_application_error(-20322, 'Last time stamping not found!');
    else
      -- Calcul de la quantité totale des opérations (si une quantité est nulle, le résutlat est nul)
      for vForIndex in vTaskLinks.first .. vTaskLinks.last loop
        vTotalDueTsk  := vTotalDueTsk + vTaskLinks(vForIndex).TAL_DUE_TSK;
      end loop;

      -- Sauvegarde
      vProgressOrigin                  := aTimeStamping.C_PROGRESS_ORIGIN;
      vGalRefCompl                     := aTimeStamping.TIS_GAL_REFCOMPL;
      vTaskLinkSeq                     := aTimeStamping.TIS_TASK_LINK_SEQ;
      vTaskLinkId                      := aTimeStamping.TIS_TASK_LINK_ID;
      -- Totaux timbrage restant à attribuer à des avancements
      vBalAdjustingTime                := aAdjustingTime;
      vBalWorkTime                     := aWorkTime;
      vIndex                           := vTaskLinks.first;

      -- Tant qu'il reste des opérations à traiter et des durées à attribuer
      while vIndex <= vTaskLinks.last
       and (   vBalAdjustingTime > 0
            or vBalWorkTime > 0) loop
        -- Assignation des infos de l'opération courante dans le record
        aTimeStamping.C_PROGRESS_ORIGIN  := vTaskLinks(vIndex).C_PROGRESS_ORIGIN;
        aTimeStamping.TIS_GAL_REFCOMPL   := vTaskLinks(vIndex).TIS_GAL_REFCOMPL;
        aTimeStamping.TIS_TASK_LINK_SEQ  := vTaskLinks(vIndex).TIS_TASK_LINK_SEQ;
        aTimeStamping.TIS_TASK_LINK_ID   := vTaskLinks(vIndex).TIS_TASK_LINK_ID;

        if vIndex = vTaskLinks.last then
          -- Si c'est la dernière opération, on attribue tout ce qu'il reste
          vAdjustingTime  := vBalAdjustingTime;
          vWorkTime       := vBalWorkTime;
        else
          -- Sinon on attribue les durées proportionnellement (selon les heures prévues
          -- ou le nombre de tâches si des heures prévues n'ont pas été saisies)
          if vTotalDueTsk > 0 then
            vFactor  := vTaskLinks(vIndex).TAL_DUE_TSK / vTotalDueTsk;
          else
            vFactor  := 1 / vTaskLinks.count;
          end if;

          vAdjustingTime  := least(vBalAdjustingTime, vFactor * aAdjustingTime);
          vWorkTime       := least(vBalWorkTime, vFactor * aWorkTime);
        end if;

        -- Génération d'un enregistrement dans le brouillard
        GenerateFogRecord(aTimeStamping => aTimeStamping, aAdjustingTime => vAdjustingTime, aWorkTime => vWorkTime);
        -- Mise à jour des durées restant à attribuer
        vBalAdjustingTime                := vBalAdjustingTime - vAdjustingTime;
        vBalWorkTime                     := vBalWorkTime - vWorkTime;
        vIndex                           := vIndex + 1;
      end loop;

      -- Restauration
      aTimeStamping.TIS_GAL_REFCOMPL   := vGalRefCompl;
      aTimeStamping.TIS_TASK_LINK_SEQ  := vTaskLinkSeq;
      aTimeStamping.TIS_TASK_LINK_ID   := vTaskLinkId;
      aTimeStamping.C_PROGRESS_ORIGIN  := vProgressOrigin;
    end if;
  end GenerateGalFogRecords;

  /**
   * procedure GenerateFogRecords
   * Description
   *   Génération des enregistrements dans le brouillard en répartissant les
   *   durées et quantités le cas échéant.
   */
  procedure GenerateFogRecords(
    aTimeStamping  in out nocopy FAL_TIME_STAMPING_MNGT.TTIME_STAMPING
  , aAdjustingTime in            FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type default 0
  , aWorkTime      in            FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type default 0
  )
  is
  begin
    -- Selon le type de gestion (opération seule ou regroupement d'opérations)
    if aTimeStamping.TIS_GROUP_ID is null then
      -- Gestion par opération
      -- Génération d'un enregistrement dans le brouillard
      GenerateFogRecord(aTimeStamping => aTimeStamping, aAdjustingTime => aAdjustingTime, aWorkTime => aWorkTime);
    else
      -- Gestion par regroupement selon l'origine
      case aTimeStamping.C_PROGRESS_ORIGIN
        when poProduction then
          GenerateFalFogRecords(aTimeStamping => aTimeStamping, aAdjustingTime => aAdjustingTime, aWorkTime => aWorkTime);
        when poProject then
          GenerateGalFogRecords(aTimeStamping => aTimeStamping, aAdjustingTime => aAdjustingTime, aWorkTime => aWorkTime);
      end case;
    end if;
  end GenerateFogRecords;

  /**
   * function CalculateDurationConstRemove
   * Description
   *   Calcule la durée en heures entre deux date en tenant compte d'une pause
   *   fixe à une heure donnée (on considère que les dates sont sur la même journée).
   */
  function CalculateDurationConstRemove(aBeginDate date, aEndDate date, aLastTimeStampingId number, aTimeStampingId number)
    return number
  is
    vResult number(15, 4);
  begin
    -- Si les date de début et de fin sont de part et d'autre de l'heure donnée
    -- (on considère que les dates sont sur la même journée)
    if     trunc(aBeginDate, 'DD') = trunc(aEndDate, 'DD')
       and FAL_TIME_STAMPING_MNGT.cDurationWhenRemove between to_char(aBeginDate, 'HH24:MI:SS') and to_char(aEndDate, 'HH24:MI:SS') then
      -- On enlève une durée fixe à la durée calculée
      vResult  := (aEndDate - aBeginDate) * 24 - FAL_TIME_STAMPING_MNGT.cDurationToRemove;
    else
      -- Sinon on calcule seulement la différence
      vResult  := (aEndDate - aBeginDate) * 24;
    end if;

    -- Renvoi de la durée calculée
    return vResult;
  end CalculateDurationConstRemove;

  /**
   * function CalculateDuration
   * Description
   *   Calcule la durée en heures entre deux date en tenant compte de la
   *   configuration FAL_TIS_DURATION_PROC.
   */
  function CalculateDuration(aTimeStamping in FAL_TIME_STAMPING_MNGT.TTIME_STAMPING, aLastTimeStamping in FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
    return number
  is
    vResult number(15, 4);
  begin
    -- Exécution de la procédure spécifiées par FAL_TIS_DURATION_PROC
    execute immediate 'begin :Result :=  ' || cDurationProc || '(:BeginDate, :EndDate, :LastTimeStampingId, :TimeStampingId); end;'
                using out    vResult
                    , in     aLastTimeStamping.TIS_STAMPING_DATE
                    , in     aTimeStamping.TIS_STAMPING_DATE
                    , in     aLastTimeStamping.FAL_TIME_STAMPING_ID
                    , in     aTimeStamping.FAL_TIME_STAMPING_ID;

    return vResult;
  end CalculateDuration;

  /**
   * function RequireEmptyProgress
   * Description
   *   Détermnine si l'opération du timbrage passé en paramètre nécessite un
   *   avancement avec quantités à zéro ou non (pour le premier timbrage d'une
   *   opération).
   */
  function RequireEmptyProgress(aTimeStamping in FAL_TIME_STAMPING_MNGT.TTIME_STAMPING)
    return boolean
  is
    cursor crLotProgresses(aFalTaskLinkId FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type)
    is
      select FAL_LOT_PROGRESS_ID
        from FAL_LOT_PROGRESS
       where FAL_SCHEDULE_STEP_ID = aFalTaskLinkId;

    tplLotProgress crLotProgresses%rowtype;
    vResult        boolean;
  begin
    -- En production (renvoie toujours false en Affaires)
    if aTimeStamping.C_PROGRESS_ORIGIN = FAL_TIME_STAMPING_TOOLS.poProduction then
      -- Recherche de l'existence d'avancements pour cette opération
      open crLotProgresses(aTimeStamping.TIS_TASK_LINK_ID);

      fetch crLotProgresses
       into tplLotProgress;

      -- Si aucun avancement, alors générer un avancement nul est nécessaire
      vResult  := crLotProgresses%notfound;

      close crLotProgresses;
    else
      vResult  := false;
    end if;

    return vResult;
  end RequireEmptyProgress;
end FAL_TIME_STAMPING_TOOLS;
