--------------------------------------------------------
--  DDL for Package Body FAL_LOT_PROGRESS_CUSTOM_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LOT_PROGRESS_CUSTOM_FCT" 
is
  -- Origines d'avancement
  poProduction          constant FAL_TIME_STAMPING.C_PROGRESS_ORIGIN%type   := '10';   -- Opération d'OF
  poProject             constant FAL_TIME_STAMPING.C_PROGRESS_ORIGIN%type   := '20';   -- Opération de DF
  -- Configurations
  cDefaultPfgStatus     constant varchar2(2)                                := nvl(PCS.PC_CONFIG.GetConfig('FAL_DEFAULT_PFG_STATUS'), '20');
  cProgressMode         constant integer                                    := PCS.PC_CONFIG.GetConfig('FAL_PROGRESS_MODE');
  cCombinedRefSeparator constant varchar2(1)                                := nvl(PCS.PC_CONFIG.GetConfig('FAL_SEPAR_ORIGIN_REF_SEQ'), '/');
  -- Messages d'erreur
  emRefLotNotFound      constant varchar2(255)
                                            := PCS.PC_FUNCTIONS.TranslateWord('Le lot de fabrication spécifié dans la référence combinée n''a pas été trouvé.');
  emRefTaskLinkNotFound constant varchar2(255)     := PCS.PC_FUNCTIONS.TranslateWord('L''opération spécifiée dans la référence combinée n''a pas été trouvée.');
  emMalformedRef        constant varchar2(255)                         := PCS.PC_FUNCTIONS.TranslateWord('La référence combinée est incomplète ou incorrecte.');
  emIncorrectRefOrigin  constant varchar2(255)             := PCS.PC_FUNCTIONS.TranslateWord('L''origine spécifiée dans la référence combinée est incorrecte.');
  emProjectNotSupported constant varchar2(255)
                                    := PCS.PC_FUNCTIONS.TranslateWord('Les suivis des opération du module de gestion à l''affaire ne peuvent être saisis ici.');

/**
   * procedure InitProgressInput
   * Description
   *   Initialisation de la saisie
   */
  procedure InitProgressInput(
    aLotProgressCustomId     in     FAL_LOT_PROGRESS_CUSTOM.FAL_LOT_PROGRESS_CUSTOM_ID%type
  , aLastLotProgressCustomId in     FAL_LOT_PROGRESS_CUSTOM.FAL_LOT_PROGRESS_CUSTOM_ID%type
  , aReqActions              out    varchar2
  , aFocusField              out    varchar2
  , aErrorCode               out    integer
  , aErrorMessage            out    varchar2
  )
  is
    vLotProgressCustom     TLOT_PROGRESS_CUSTOM;
    vLastLotProgressCustom TLOT_PROGRESS_CUSTOM;
  begin
    aErrorCode  := 0;

    begin
      -- Report de la valeur de l'opérateur de la saisie précédente
      if aLastLotProgressCustomId > 0 then
        vLotProgressCustom                       := GetLotProgressCustom(aLotProgressCustomId);
        vLastLotProgressCustom                   := GetLotProgressCustom(aLastLotProgressCustomId);
        -- Reprise de l'opérateur de la saisie précédente
        vLotProgressCustom.LPC_VDIC_OPERATOR_ID  := vLastLotProgressCustom.LPC_VDIC_OPERATOR_ID;

        if vLotProgressCustom.LPC_VDIC_OPERATOR_ID is not null then
          aFocusField  := 'LPC_VCOMBINED_REF';
        end if;

        -- Mise à jour effective des données
        UpdateLotProgressCustom(vLotProgressCustom);

        -- Suppression des données des champs virtuels de la saisie précédente
        delete from COM_VFIELDS_RECORD
              where COM_VFIELDS_RECORD_ID = vLastLotProgressCustom.COM_VFIELDS_RECORD_ID;
      end if;
    exception
      when others then
        begin
          aErrorCode     := 1;
          aErrorMessage  := PCS.PC_FUNCTIONS.TranslateWord('Erreur Oracle :') || chr(13) || sqlerrm;
        end;
    end;
  end InitProgressInput;

  /**
   * procedure ManagePreciousMat
   * Description
   *   Recherche du lot et de l'opération de la référence combinée.
   */
  procedure ManagePreciousMat(
    aLotProgressCustom in out nocopy TLOT_PROGRESS_CUSTOM
  , aReqActions        in out        varchar2
  , aFocusField        in out        varchar2
  , aErrorCode         in out        integer
  , aErrorMessage      in out        varchar2
  )
  is
    cursor crInfos(aTaskLinkId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    is
      select LOT.FAL_LOT_ID
           , LOT.GCO_GOOD_ID
           , LOT.LOT_REFCOMPL
           , TAL.SCS_WEIGH
           , TAL.SCS_WEIGH_MANDATORY
        from FAL_TASK_LINK TAL
           , FAL_LOT LOT
       where TAL.FAL_SCHEDULE_STEP_ID = aTaskLinkId
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID;

    tplInfos        crInfos%rowtype;
    blnFound        boolean;
    intWeighCount   integer;
    strWeighingMode varchar2(10);
    vFactoryFloorId FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
  begin
    open crInfos(aLotProgressCustom.LPC_TASK_LINK_ID);

    fetch crInfos
     into tplInfos;

    blnFound  := crInfos%found;

    close crInfos;

    -- Si la référence combinée est correcte (ie l'opération a été trouvée)
    if blnFound then
      -- Recherche de la valeur du paramètre d'objet WEIGHING_MODE
      select max(PARAM_VALUE)
        into strWeighingMode
        from (select trim(upper(substr(LINE, 1, instr(LINE, '=') - 1) ) ) PARAM_NAME
                   , trim(substr(LINE, instr(LINE, '=') + 1) ) PARAM_VALUE
                from (select EXTRACTLINE(PCS.PC_I_LIB_SESSION.GetObjectParams, no, ';') LINE
                        from PCS.PC_NUMBER
                       where no < 100)
               where LINE is not null)
       where PARAM_NAME = 'WEIGHING_MODE';

      -- Si le produit du lot est avec gestion des matière première, s'il est constitué d'au moins un alliage avec
      -- pesée réelle et si l'opération est en "Pesée matière précieuse"
      -- (pour autant que le paramètre d'objet WEIGHING_MODE soit différent de '3').
      if     (nvl(strWeighingMode, '0') <> '3')
         and (GCO_PRECIOUS_MAT_FUNCTIONS.IsProductWithPMatWithWeighing(tplInfos.GCO_GOOD_ID) = 1)
         and (tplInfos.SCS_WEIGH = 1) then
        -- Recherche des pesées existantes
        select count(FAL_WEIGH_ID)
          into intWeighCount
          from FAL_WEIGH
         where FAL_LOT_PROGRESS_FOG_ID = aLotProgressCustom.FAL_LOT_PROGRESS_FOG_ID;

        -- Affichage de l'objet de gestion des pesées si nécessaire
        if intWeighCount = 0 then
          -- Recherche de l'id de l'atelier
          select max(FAL_FACTORY_FLOOR_ID)
            into vFactoryFloorId
            from FAL_FACTORY_FLOOR
           where FAC_REFERENCE = aLotProgressCustom.LPC_VREF_FACTORY_FLOOR;

          -- Construction de la ligne de commande du call object
          aReqActions  :=
            aReqActions ||
            '[CALL_OBJECT] OBJ=FAL_WEIGHPO;OBJ_PARAMS=' ||
            '/LOT_REFCOMPL=' ||
            tplInfos.LOT_REFCOMPL ||
            '/FAL_SCHEDULE_STEP_ID=' ||
            aLotProgressCustom.LPC_TASK_LINK_ID ||
            '/DIC_OPERATOR_ID=' ||
            aLotProgressCustom.LPC_VDIC_OPERATOR_ID ||
            '/FAL_LOT_PROGRESS_FOG_ID=' ||
            aLotProgressCustom.FAL_LOT_PROGRESS_FOG_ID ||
            '/FLP_PROGRESS_QTY=' ||
            aLotProgressCustom.LPC_VPRODUCT_QTY;

          if vFactoryFloorId is not null then
            aReqActions  := aReqActions || '/FAL_FACTORY_FLOOR_ID=' || vFactoryFloorId;
          end if;

          if strWeighingMode is not null then
            aReqActions  := aReqActions || '/WEIGHING_MODE=' || strWeighingMode;
          end if;

          aReqActions  := aReqActions || ';RW=1|';

          -- Arrêt de la validation si la pesée est obligatoire, sinon l'enregistrement est validé que l'opérateur
          -- effectue ou annule la pesée.
          if tplInfos.SCS_WEIGH_MANDATORY = 1 then
            aErrorCode  := 861;
          end if;
        end if;
      end if;
    end if;
  end ManagePreciousMat;

  /**
   * procedure GenerateFogRecord
   * Description
   *   Génération d'un enregistrement dans le brouillard.
   */
  procedure GenerateFogRecord(
    aLotProgressCustom in out nocopy TLOT_PROGRESS_CUSTOM
  , aReqActions        in out        varchar2
  , aFocusField        in out        varchar2
  , aErrorCode         in out        integer
  , aErrorMessage      in out        varchar2
  )
  is
  begin
    -- Gestion de la config FAL_PROGRESS_MODE
    if cProgressMode = 0 then
      aLotProgressCustom.LPC_VWORK_TIME       := nvl(aLotProgressCustom.LPC_VWORK_TIME, 0) + nvl(aLotProgressCustom.LPC_VADJUSTING_TIME, 0);
      aLotProgressCustom.LPC_VADJUSTING_TIME  := null;
    end if;

    -- Insertion dans le brouillard
    insert into FAL_LOT_PROGRESS_FOG
                (FAL_LOT_PROGRESS_FOG_ID
               , C_PFG_STATUS
               , C_PROGRESS_ORIGIN
               , PFG_DIC_OPERATOR_ID
               , PFG_REF_FACTORY_FLOOR
               , PFG_LOT_REFCOMPL
               , PFG_SEQ
               , PFG_DATE
               , PFG_ADJUSTING_TIME
               , PFG_WORK_TIME
               , PFG_PRODUCT_QTY
               , PFG_PT_REFECT_QTY
               , PFG_CPT_REJECT_QFY
               , PFG_LABEL_CONTROL
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , cDefaultPfgStatus
               , poProduction
               , aLotProgressCustom.LPC_VDIC_OPERATOR_ID
               , aLotProgressCustom.LPC_VREF_FACTORY_FLOOR
               , aLotProgressCustom.LPC_LOT_REFCOMPL
               , aLotProgressCustom.LPC_TASK_LINK_SEQ
               , sysdate
               , aLotProgressCustom.LPC_VADJUSTING_TIME
               , aLotProgressCustom.LPC_VWORK_TIME
               , nvl(aLotProgressCustom.LPC_VPRODUCT_QTY, 0)
               , aLotProgressCustom.LPC_VPT_REJECT_QTY
               , aLotProgressCustom.LPC_VCPT_REJECT_QTY
               , aLotProgressCustom.LPC_VLABEL_CONTROL
               , sysdate
               , PCS.PC_I_LIB_SESSION.USERINI
                )
      returning FAL_LOT_PROGRESS_FOG_ID
           into aLotProgressCustom.FAL_LOT_PROGRESS_FOG_ID;
  end GenerateFogRecord;

  /**
   * procedure UpdateFogRecord
   * Description
   *   Miseà jour d'un enregistrement dans le brouillard.
   */
  procedure UpdateFogRecord(
    aLotProgressCustom in out nocopy TLOT_PROGRESS_CUSTOM
  , aReqActions        in out        varchar2
  , aFocusField        in out        varchar2
  , aErrorCode         in out        integer
  , aErrorMessage      in out        varchar2
  )
  is
  begin
    -- Gestion de la config FAL_PROGRESS_MODE
    if cProgressMode = 0 then
      aLotProgressCustom.LPC_VWORK_TIME       := nvl(aLotProgressCustom.LPC_VWORK_TIME, 0) + nvl(aLotProgressCustom.LPC_VADJUSTING_TIME, 0);
      aLotProgressCustom.LPC_VADJUSTING_TIME  := null;
    end if;

    -- Mise à jour du brouillard
    update FAL_LOT_PROGRESS_FOG
       set C_PFG_STATUS = cDefaultPfgStatus
         , C_PROGRESS_ORIGIN = poProduction
         , PFG_DIC_OPERATOR_ID = aLotProgressCustom.LPC_VDIC_OPERATOR_ID
         , PFG_REF_FACTORY_FLOOR = aLotProgressCustom.LPC_VREF_FACTORY_FLOOR
         , PFG_LOT_REFCOMPL = aLotProgressCustom.LPC_LOT_REFCOMPL
         , PFG_SEQ = aLotProgressCustom.LPC_TASK_LINK_SEQ
         , PFG_ADJUSTING_TIME = aLotProgressCustom.LPC_VADJUSTING_TIME
         , PFG_WORK_TIME = aLotProgressCustom.LPC_VWORK_TIME
         , PFG_PRODUCT_QTY = nvl(aLotProgressCustom.LPC_VPRODUCT_QTY, 0)
         , PFG_PT_REFECT_QTY = aLotProgressCustom.LPC_VPT_REJECT_QTY
         , PFG_CPT_REJECT_QFY = aLotProgressCustom.LPC_VCPT_REJECT_QTY
         , PFG_LABEL_CONTROL = aLotProgressCustom.LPC_VLABEL_CONTROL
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.USERINI;
  end UpdateFogRecord;

  /**
   * procedure ValidProgressInput
   * Description
   *   Validation de la saisie
   */
  procedure ValidProgressInput(
    aLotProgressCustom in out nocopy TLOT_PROGRESS_CUSTOM
  , aReqActions        in out        varchar2
  , aFocusField        in out        varchar2
  , aErrorCode         in out        integer
  , aErrorMessage      in out        varchar2
  )
  is
  begin
    -- Insertion dans le brouillard ou mise à jour de l'existant
    if aLotProgressCustom.FAL_LOT_PROGRESS_FOG_ID is null then
      GenerateFogRecord(aLotProgressCustom   => aLotProgressCustom
                      , aFocusField          => aFocusField
                      , aReqActions          => aReqActions
                      , aErrorCode           => aErrorCode
                      , aErrorMessage        => aErrorMessage
                       );
    else
      UpdateFogRecord(aLotProgressCustom   => aLotProgressCustom
                    , aFocusField          => aFocusField
                    , aReqActions          => aReqActions
                    , aErrorCode           => aErrorCode
                    , aErrorMessage        => aErrorMessage
                     );
    end if;

    -- Gestion des matières précieuses
    if aErrorCode = 0 then
      ManagePreciousMat(aLotProgressCustom   => aLotProgressCustom
                      , aFocusField          => aFocusField
                      , aReqActions          => aReqActions
                      , aErrorCode           => aErrorCode
                      , aErrorMessage        => aErrorMessage
                       );
    end if;
  end ValidProgressInput;

  /**
   * procedure ValidProgressInput
   * Description
   *   Validation de la saisie
   */
  procedure ValidProgressInput(
    aLotProgressCustomId in     FAL_LOT_PROGRESS_CUSTOM.FAL_LOT_PROGRESS_CUSTOM_ID%type
  , aReqActions          out    varchar2
  , aFocusField          out    varchar2
  , aErrorCode           out    integer
  , aErrorMessage        out    varchar2
  )
  is
    vLotProgressCustom TLOT_PROGRESS_CUSTOM;
  begin
    aErrorCode          := 0;
    vLotProgressCustom  := GetLotProgressCustom(aLotProgressCustomId);
    -- Validation de l'enregistrement
    ValidProgressInput(aLotProgressCustom   => vLotProgressCustom
                     , aFocusField          => aFocusField
                     , aReqActions          => aReqActions
                     , aErrorCode           => aErrorCode
                     , aErrorMessage        => aErrorMessage
                      );
    -- Mise à jour effective des données
    UpdateLotProgressCustom(vLotProgressCustom);
  end ValidProgressInput;

  /**
   * procedure ValidAndProcessProgressInput
   * Description
   *   Validation de la saisie et application du traitement du brouillard avec
   *   affichage de l'éventuel message d'erreur.
   */
  procedure ValidAndProcessProgressInput(
    aLotProgressCustomId in     FAL_LOT_PROGRESS_CUSTOM.FAL_LOT_PROGRESS_CUSTOM_ID%type
  , aReqActions          out    varchar2
  , aFocusField          out    varchar2
  , aErrorCode           out    integer
  , aErrorMessage        out    varchar2
  )
  is
    vLotProgressCustom TLOT_PROGRESS_CUSTOM;
    vError             integer;
    vErrorMsg          varchar(255);
    vFogMsgMode        integer;
  begin
    aErrorCode          := 0;
    vLotProgressCustom  := GetLotProgressCustom(aLotProgressCustomId);
    -- Validation de l'enregistrement
    ValidProgressInput(aLotProgressCustom   => vLotProgressCustom
                     , aFocusField          => aFocusField
                     , aReqActions          => aReqActions
                     , aErrorCode           => aErrorCode
                     , aErrorMessage        => aErrorMessage
                      );

    if aErrorCode = 0 then
      -- Application du traitement à l'enregistrement du brouillard
      FAL_SUIVI_OPERATION.ProcessDaybook(aFAL_LOT_PROGRESS_FOG_ID => vLotProgressCustom.FAL_LOT_PROGRESS_FOG_ID, aError => vError, aErrorMsg => vErrorMsg);

      -- Recherche de la valeur du paramètre d'objet FOG_MSG_MODE
      -- 0 : Aucun
      -- 1 : Informatif
      -- 2 : Bloquant
      select nvl(max(PARAM_VALUE), 1)
        into vFogMsgMode
        from (select trim(upper(substr(LINE, 1, instr(LINE, '=') - 1) ) ) PARAM_NAME
                   , trim(substr(LINE, instr(LINE, '=') + 1) ) PARAM_VALUE
                from (select EXTRACTLINE(PCS.PC_I_LIB_SESSION.GetObjectParams, no, ';') LINE
                        from PCS.PC_NUMBER
                       where no < 100)
               where LINE is not null)
       where PARAM_NAME = 'FOG_MSG_MODE';

      -- et mise à jour du message d'erreur avec la description du descode
      if     (vFogMsgMode > 0)
         and (vError <> 0) then
        -- Code erreur selon que le message est bloquant ou non
        if vFogMsgMode = 2 then
          aErrorCode  := abs(vError);
        end if;

        aErrorMessage  :=
          PCS.PC_FUNCTIONS.TranslateWord('Traitement du brouillard :') ||
          ' ' ||
          PCS.PC_FUNCTIONS.GetDescodeDescr('C_FOG_APPLY_ERROR', lpad(vError, 2, '0'), PCS.PC_I_LIB_SESSION.GetUserLangId);

        if vErrorMsg is not null then
          aErrorMessage  := aErrorMessage || co.cLineBreak || vErrorMsg;
        end if;
      end if;
    end if;

    -- Mise à jour effective des données
    UpdateLotProgressCustom(vLotProgressCustom);
  end ValidAndProcessProgressInput;

  /**
   * procedure ParseCombinedRef
   * Description
   *   Recherche du lot et de l'opération de la référence combinée.
   */
  procedure ParseCombinedRef(
    aLotProgressCustom in out nocopy TLOT_PROGRESS_CUSTOM
  , aFocusField        in out        varchar2
  , aErrorCode         in out        integer
  , aErrorMessage      in out        varchar2
  )
  is
    vProgressOrigin varchar(255);
    vRefCompl       varchar(255);
    vTaskLinkSeq    varchar(255);
    vSep1Pos        integer;
    vSep2Pos        integer;
    vLotId          FAL_LOT.FAL_LOT_ID%type;
    vTaskLinkId     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    -- On efface les anciennes valeurs
    aLotProgressCustom.LPC_LOT_REFCOMPL   := null;
    aLotProgressCustom.LPC_TASK_LINK_SEQ  := null;
    aLotProgressCustom.LPC_TASK_LINK_ID   := null;

    -- Si la référence combinée n'est pas vide, on recherche les nouvelles valeurs
    if aLotProgressCustom.LPC_VCOMBINED_REF is not null then
      -- Analyse de la référence combinée
      vSep1Pos         := instr(aLotProgressCustom.LPC_VCOMBINED_REF, cCombinedRefSeparator);
      vSep2Pos         := instr(aLotProgressCustom.LPC_VCOMBINED_REF, cCombinedRefSeparator, -1);
      vProgressOrigin  := substr(aLotProgressCustom.LPC_VCOMBINED_REF, 1, vSep1Pos - 1);
      vRefCompl        := substr(aLotProgressCustom.LPC_VCOMBINED_REF, vSep1Pos + 1, vSep2Pos - 1 - vSep1Pos);
      vTaskLinkSeq     := substr(aLotProgressCustom.LPC_VCOMBINED_REF, vSep2Pos + 1);

      if    vProgressOrigin is null
         or vRefCompl is null
         or vTaskLinkSeq is null then
        -- Référence incomplète
        aErrorCode     := 235;
        aErrorMessage  := emMalformedRef;
      else
        -- Selon l'origine de l'opération,
        case vProgressOrigin
          when poProduction then
            -- Recherche du lot
            if vRefCompl is not null then
              begin
                select FAL_LOT_ID
                  into vLotId
                  from FAL_LOT
                 where LOT_REFCOMPL = vRefCompl;

                -- Si le lot a été trouvé on sauvegarde sa réf
                aLotProgressCustom.LPC_LOT_REFCOMPL  := vRefCompl;
              exception
                when no_data_found then
                  aErrorCode     := 245;
                  aErrorMessage  := emRefLotNotFound;
              end;

              if aErrorCode = 0 then
                -- Recherche de l'opération du lot
                if vTaskLinkSeq is not null then
                  begin
                    select FAL_SCHEDULE_STEP_ID
                      into vTaskLinkId
                      from FAL_TASK_LINK
                     where FAL_LOT_ID = vLotId
                       and SCS_STEP_NUMBER = vTaskLinkSeq;

                    -- Si l'opération a été trouvée on sauvegarde sa sequence et son ID
                    aLotProgressCustom.LPC_TASK_LINK_SEQ  := vTaskLinkSeq;
                    aLotProgressCustom.LPC_TASK_LINK_ID   := vTaskLinkId;
                  exception
                    when no_data_found then
                      aErrorCode     := 255;
                      aErrorMessage  := emRefTaskLinkNotFound;
                  end;
                end if;
              end if;
            end if;
          when poProject then
            -- Les op GAL ne sont pas acceptées
            aErrorCode     := 220;
            aErrorMessage  := emProjectNotSupported;
          else
            -- on spécifie une erreur si l'origine est inconnue
            aErrorCode     := 225;
            aErrorMessage  := emIncorrectRefOrigin;
        end case;
      end if;
    end if;
  end;

  /**
   * procedure InitProgressInputValues
   * Description
   *   Initialisation des durées et quantités en fonction des données de
   *   l'opération.
   */
  procedure InitProgressInputValues(
    aLotProgressCustom in out nocopy TLOT_PROGRESS_CUSTOM
  , aFocusField        in out        varchar2
  , aErrorCode         in out        integer
  , aErrorMessage      in out        varchar2
  )
  is
    cursor crListStepLink(aTaskLinkId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    is
      select case nvl(TAL.SCS_QTY_FIX_ADJUSTING, 0)
               when 0 then TAL.TAL_TSK_AD_BALANCE
               else TAL.SCS_ADJUSTING_TIME * ceil(FAL_TOOLS.nifz(TAL.TAL_AVALAIBLE_QTY) / TAL.SCS_QTY_FIX_ADJUSTING)
             end LPC_ADJUSTING_TIME
           , TAL.SCS_WORK_TIME * FAL_TOOLS.nifz(TAL.TAL_AVALAIBLE_QTY) / nvl(TAL.SCS_QTY_REF_WORK, 1) LPC_WORK_TIME
           , FAL_TOOLS.nifz(TAL.TAL_AVALAIBLE_QTY) TAL_AVAILABLE_QTY
        from FAL_TASK_LINK TAL
           , FAL_LOT LOT
       where TAL.FAL_SCHEDULE_STEP_ID = aTaskLinkId
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID;

    tlpListStepLink crListStepLink%rowtype;
  begin
    -- Initialisation des valeur si l'opération a été trouvée
    if     (aErrorCode = 0)
       and aLotProgressCustom.LPC_TASK_LINK_ID is not null then
      open crListStepLink(aLotProgressCustom.LPC_TASK_LINK_ID);

      fetch crListStepLink
       into tlpListStepLink;

      if crListStepLink%found then
        -- Initialisation des temps opératoires
        aLotProgressCustom.LPC_VADJUSTING_TIME  := tlpListStepLink.LPC_ADJUSTING_TIME;
        aLotProgressCustom.LPC_VWORK_TIME       := tlpListStepLink.LPC_WORK_TIME;
        -- Initialisation de la quantité avec la quantité disponible
        aLotProgressCustom.LPC_VPRODUCT_QTY     := tlpListStepLink.TAL_AVAILABLE_QTY;
      end if;

      close crListStepLink;
    end if;
  end;

  /**
   * procedure CombinedRefChanged
   * Description
   *   Gestion du changement de référence combinée.
   */
  procedure CombinedRefChanged(
    aLotProgressCustom in out nocopy TLOT_PROGRESS_CUSTOM
  , aFocusField        in out        varchar2
  , aErrorCode         in out        integer
  , aErrorMessage      in out        varchar2
  )
  is
  begin
    -- Verification de la référence combinée et recherche de l'op
    ParseCombinedRef(aLotProgressCustom, aFocusField, aErrorCode, aErrorMessage);
    -- Initialisation des temps opératoires à partir de la gamme
    InitProgressInputValues(aLotProgressCustom, aFocusField, aErrorCode, aErrorMessage);
  end;

  /**
   * procedure FieldChanged
   * Description
   *   Procédure d'événement de sortie d'un champ virtuel
   */
  procedure FieldChanged(
    aLotProgressCustomId in     FAL_LOT_PROGRESS_CUSTOM.FAL_LOT_PROGRESS_CUSTOM_ID%type
  , aFieldName           in     varchar2
  , aFieldModified       in     integer
  , aFocusField          out    varchar2
  , aErrorCode           out    integer
  , aErrorMessage        out    varchar2
  )
  is
    vLotProgressCustom TLOT_PROGRESS_CUSTOM;
  begin
    aErrorCode  := 0;

    if aFieldModified = 1 then
      vLotProgressCustom  := GetLotProgressCustom(aLotProgressCustomId);

      if vLotProgressCustom.FAL_LOT_PROGRESS_CUSTOM_ID is null then
        aErrorCode     := -1;
        aErrorMessage  := 'System error 687642';
      else
        if aFieldName = 'LPC_VCOMBINED_REF' then
          -- Gestion du changement de référence combinée
          CombinedRefChanged(aLotProgressCustom => vLotProgressCustom, aFocusField => aFocusField, aErrorCode => aErrorCode, aErrorMessage => aErrorMessage);
        end if;

        -- Mise à jour effective de la table de saisie et des champs virtuels
        UpdateLotProgressCustom(aLotProgressCustom => vLotProgressCustom);
      end if;
    end if;
  end FieldChanged;

  /**
   * function GetLotProgressCustom
   * Description
   *    Renvoie un record contenant les valeurs des champs et des champs virtuels
   *    de la saisie dont l'ID est passé en paramètre.
   */
  function GetLotProgressCustom(aLotProgressCustomId in FAL_LOT_PROGRESS_CUSTOM.FAL_LOT_PROGRESS_CUSTOM_ID%type)
    return TLOT_PROGRESS_CUSTOM
  is
    -- Attention ce curseur doit correspondre exactement avec le type de record TLOT_PROGRESS_CUSTOM
    cursor crLotProgressCustom(aLotProgressCustomId FAL_LOT_PROGRESS_CUSTOM.FAL_LOT_PROGRESS_CUSTOM_ID%type)
    is
      select LPC.FAL_LOT_PROGRESS_CUSTOM_ID
           , LPC.LPC_LOT_REFCOMPL
           , LPC.LPC_TASK_LINK_SEQ
           , LPC.LPC_TASK_LINK_ID
           , LPC.FAL_LOT_PROGRESS_FOG_ID
           , VFI.COM_VFIELDS_RECORD_ID
           , VFI.VFI_CHAR_01 LPC_VDIC_OPERATOR_ID
           , VFI.VFI_MEMO_01 LPC_VCOMBINED_REF
           , VFI.VFI_FLOAT_01 LPC_VADJUSTING_TIME
           , VFI.VFI_FLOAT_02 LPC_VWORK_TIME
           , VFI.VFI_FLOAT_03 LPC_VPRODUCT_QTY
           , VFI.VFI_FLOAT_04 LPC_VPT_REJECT_QTY
           , VFI.VFI_FLOAT_05 LPC_VCPT_REJECT_QTY
           , VFI.VFI_CHAR_02 LPC_VREF_FACTORY_FLOOR
           , VFI.VFI_MEMO_02 LPC_VLABEL_CONTROL
        from FAL_LOT_PROGRESS_CUSTOM LPC
           , COM_VFIELDS_RECORD VFI
       where LPC.FAL_LOT_PROGRESS_CUSTOM_ID = aLotProgressCustomId
         and VFI.VFI_TABNAME = 'FAL_LOT_PROGRESS_CUSTOM'
         and VFI.VFI_REC_ID = LPC.FAL_LOT_PROGRESS_CUSTOM_ID;

    vLotProgressCustom TLOT_PROGRESS_CUSTOM;
  begin
    -- Recherche des valeurs des champs et des champs virtuels de la saisie
    open crLotProgressCustom(aLotProgressCustomId);

    fetch crLotProgressCustom
     into vLotProgressCustom;

    -- Renvoi du record demandé
    return vLotProgressCustom;
  end GetLotProgressCustom;

  /**
   * procedure UpdateLotProgressCustom
   * Description
   *    Met physiquement à jour les champs et les champs virtuels de la saisie.
   */
  procedure UpdateLotProgressCustom(aLotProgressCustom in TLOT_PROGRESS_CUSTOM)
  is
  begin
    -- Mise à jour des champs à partir des valeurs du record
    update FAL_LOT_PROGRESS_CUSTOM
       set LPC_LOT_REFCOMPL = aLotProgressCustom.LPC_LOT_REFCOMPL
         , LPC_TASK_LINK_SEQ = aLotProgressCustom.LPC_TASK_LINK_SEQ
         , LPC_TASK_LINK_ID = aLotProgressCustom.LPC_TASK_LINK_ID
         , FAL_LOT_PROGRESS_FOG_ID = aLotProgressCustom.FAL_LOT_PROGRESS_FOG_ID
     where FAL_LOT_PROGRESS_CUSTOM_ID = aLotProgressCustom.FAL_LOT_PROGRESS_CUSTOM_ID;

    -- Mise à jour des champs virtuels à partir des valeurs du record
    update COM_VFIELDS_RECORD
       set VFI_CHAR_01 = aLotProgressCustom.LPC_VDIC_OPERATOR_ID
         , VFI_MEMO_01 = aLotProgressCustom.LPC_VCOMBINED_REF
         , VFI_FLOAT_01 = aLotProgressCustom.LPC_VADJUSTING_TIME
         , VFI_FLOAT_02 = aLotProgressCustom.LPC_VWORK_TIME
         , VFI_FLOAT_03 = aLotProgressCustom.LPC_VPRODUCT_QTY
         , VFI_FLOAT_04 = aLotProgressCustom.LPC_VPT_REJECT_QTY
         , VFI_FLOAT_05 = aLotProgressCustom.LPC_VCPT_REJECT_QTY
         , VFI_CHAR_02 = aLotProgressCustom.LPC_VREF_FACTORY_FLOOR
         , VFI_MEMO_02 = aLotProgressCustom.LPC_VLABEL_CONTROL
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where COM_VFIELDS_RECORD_ID = aLotProgressCustom.COM_VFIELDS_RECORD_ID;
  end UpdateLotProgressCustom;
end FAL_LOT_PROGRESS_CUSTOM_FCT;
