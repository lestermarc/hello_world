--------------------------------------------------------
--  DDL for Package Body FAL_TIME_STAMPING_MNGT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_TIME_STAMPING_MNGT" 
is
  /**
   * procedure AddError
   * Description
   *    Ajoute une erreur aux variables de gestion d'erreur.
   *    aFocusField n'est renseigné que s'il est nul.
   *    aErrorCode est renseigné s'il est nul ou que aErrorCodeValue est plus grave.
   *    aErrorMessage est concaténé.
   * @version 2003
   * @author JCH 11.06.2007
   * @lastUpdate
   * @private
   * @param aFocusField        : Variable à mettre à jour
   * @param aFocusFieldValue   : Variable à utiliser pour la mise à jour
   * @param aErrorCode         : Variable à mettre à jour
   * @param aErrorCodeValue    : Variable à utiliser pour la mise à jour
   * @param aErrorMessage      : Variable à mettre à jour
   * @param aErrorMessageValue : Variable à utiliser pour la mise à jour
   */
  procedure AddError(
    aFocusField        in out varchar2
  , aFocusFieldValue   in     varchar2
  , aErrorCode         in out integer
  , aErrorCodeValue    in     integer
  , aErrorMessage      in out varchar2
  , aErrorMessageValue in     varchar2
  )
  is
  begin
    -- aFocusField n'est renseigné que s'il est nul.
    if aFocusField is null then
      aFocusField  := aFocusFieldValue;
    end if;

    -- aErrorCode est renseigné s'il est nul
    if nvl(aErrorCode, 0) = 0 then
      aErrorCode  := aErrorCodeValue;
    --  ou que aErrorCodeValue est plus grave
    elsif     (aErrorCode > 0)
          and (aErrorCodeValue < 0) then
      aErrorCode  := aErrorCodeValue;
    end if;

    -- aErrorMessage est concaténé
    if aErrorMessage is null then
      aErrorMessage  := aErrorMessageValue;
    elsif aErrorMessageValue is not null then
      aErrorMessage  := aErrorMessage || chr(13) || chr(10) || aErrorMessageValue;
    end if;
  end AddError;

  /**
   * procedure InitTimeStamping
   * Description
   *   Initialise les données d'un nouveau timbrage, en particulier si l'on est
   *   en saisie de nouveau groupe.
   */
  procedure InitTimeStamping(
    aTimeStamping     in out nocopy TTIME_STAMPING
  , aLastTimeStamping in            TTIME_STAMPING
  , aFocusField       in out        varchar2
  , aErrorCode        in out        integer
  , aErrorMessage     in out        varchar2
  )
  is
  begin
    -- Si l'on est pas en début de réglage ou de travail, pas de gestion de
    -- compteur regroupement => pas de report de valeur de champs
    if aLastTimeStamping.C_TIS_TYPE in(FAL_TIME_STAMPING_TOOLS.stStartAdj, FAL_TIME_STAMPING_TOOLS.stStartWrk) then
      -- Initialisation des données de regroupement
      FAL_TIME_STAMPING_TOOLS.InitGroupInfos(aTimeStamping, aLastTimeStamping);

      -- Si l'on est dans un regroupement, on se positionne directement sur la réf
      if nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) > 0 then
        aFocusField  := 'TIS_VCOMBINED_REF';
      end if;
    end if;

    aTimeStamping.TIS_STAMPING_DATE  := sysdate;
  end InitTimeStamping;

  /**
   * function GetLastTimeStamping
   * Description
   *    Renvoie un record contenant les valeurs des champs et des champs virtuels
   *    du timbrage précédent.
   */
  function GetLastTimeStamping(aTimeStamping in TTIME_STAMPING, aAllOperators in integer default 0, aExcludeGrouping in integer default 0)
    return TTIME_STAMPING
  is
    cursor crLastOperStampings
    is
      select   TIS.FAL_TIME_STAMPING_ID
          from FAL_TIME_STAMPING TIS
         where TIS.C_TIS_STATUS = FAL_TIME_STAMPING_FCT.ssProcessed
           and (   aAllOperators = 1
                or TIS.TIS_DIC_OPERATOR_ID = aTimeStamping.TIS_DIC_OPERATOR_ID)
           and TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
           and TIS.TIS_STAMPING_DATE <= nvl(aTimeStamping.TIS_STAMPING_DATE, sysdate)
           and (   aExcludeGrouping = 0
                or aTimeStamping.TIS_GROUP_ID is null
                or nvl(TIS.TIS_GROUP_TASK_BAL_COUNT, 0) = 0)
      order by TIS.TIS_STAMPING_DATE desc
             , TIS.FAL_TIME_STAMPING_ID desc;

    tplLastOperStamping crLastOperStampings%rowtype;
  begin
    -- Recherhce du timbrage précédent
    open crLastOperStampings;

    fetch crLastOperStampings
     into tplLastOperStamping;

    -- Renvoi de record si trouvé
    if crLastOperStampings%found then
      close crLastOperStampings;

      return GetTimeStamping(tplLastOperStamping.FAL_TIME_STAMPING_ID);
    end if;

    close crLastOperStampings;

    return null;
  end GetLastTimeStamping;

  /**
   * function GetLastOtherOpTimeStamping
   * Description
   *    Renvoie un record contenant les valeurs des champs et des champs virtuels
   *    du dernier timbrage de l'opération du timbrage passé en paramètre.
   */
  function GetLastOtherOpTimeStamping(aTimeStamping in TTIME_STAMPING)
    return TTIME_STAMPING
  is
    cursor crLastOtherOpStampings
    is
      select   nvl(GRP_TIS.FAL_TIME_STAMPING_ID, TIS.FAL_TIME_STAMPING_ID) FAL_TIME_STAMPING_ID
          from FAL_TIME_STAMPING TIS
             , FAL_TIME_STAMPING GRP_TIS
         where TIS.TIS_DIC_OPERATOR_ID <> aTimeStamping.TIS_DIC_OPERATOR_ID
           and TIS.C_TIS_STATUS <> '50'
           and TIS.TIS_STAMPING_DATE <= aTimeStamping.TIS_STAMPING_DATE
           and TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
           and (   aTimeStamping.TIS_LOT_REFCOMPL is null
                or (TIS.TIS_LOT_REFCOMPL = aTimeStamping.TIS_LOT_REFCOMPL) )
           and (   aTimeStamping.TIS_GAL_REFCOMPL is null
                or (TIS.TIS_GAL_REFCOMPL = aTimeStamping.TIS_GAL_REFCOMPL) )
           and (   aTimeStamping.TIS_TASK_LINK_SEQ is null
                or (TIS.TIS_TASK_LINK_SEQ = aTimeStamping.TIS_TASK_LINK_SEQ) )
           and (   aTimeStamping.TIS_GROUP_ID is null
                or TIS.TIS_GROUP_ID = aTimeStamping.TIS_GROUP_ID)
           and TIS.TIS_TASK_LINK_SEQ is not null
           and GRP_TIS.TIS_DIC_OPERATOR_ID = TIS.TIS_DIC_OPERATOR_ID
           and GRP_TIS.C_TIS_STATUS <> '50'
           and GRP_TIS.TIS_STAMPING_DATE <= aTimeStamping.TIS_STAMPING_DATE
           and GRP_TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
           and (   GRP_TIS.TIS_LOT_REFCOMPL is null
                or (TIS.TIS_LOT_REFCOMPL = GRP_TIS.TIS_LOT_REFCOMPL) )
           and (   GRP_TIS.TIS_GAL_REFCOMPL is null
                or (TIS.TIS_GAL_REFCOMPL = GRP_TIS.TIS_GAL_REFCOMPL) )
           and (   GRP_TIS.TIS_TASK_LINK_SEQ is null
                or (TIS.TIS_TASK_LINK_SEQ = GRP_TIS.TIS_TASK_LINK_SEQ) )
           and (   TIS.TIS_GROUP_ID is null
                or GRP_TIS.TIS_GROUP_ID = TIS.TIS_GROUP_ID)
           and not exists(
                 select FAL_TIME_STAMPING_ID
                   from FAL_TIME_STAMPING SUB_TIS
                  where SUB_TIS.TIS_DIC_OPERATOR_ID in(aTimeStamping.TIS_DIC_OPERATOR_ID, GRP_TIS.TIS_DIC_OPERATOR_ID)
                    and SUB_TIS.C_TIS_STATUS <> '50'
                    and SUB_TIS.TIS_STAMPING_DATE <= aTimeStamping.TIS_STAMPING_DATE
                    and GRP_TIS.TIS_STAMPING_DATE <= SUB_TIS.TIS_STAMPING_DATE
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> aTimeStamping.FAL_TIME_STAMPING_ID
                    and SUB_TIS.FAL_TIME_STAMPING_ID <> GRP_TIS.FAL_TIME_STAMPING_ID
                    and (   SUB_TIS.TIS_LOT_REFCOMPL is null
                         or (SUB_TIS.TIS_LOT_REFCOMPL = GRP_TIS.TIS_LOT_REFCOMPL) )
                    and (   SUB_TIS.TIS_GAL_REFCOMPL is null
                         or (SUB_TIS.TIS_GAL_REFCOMPL = GRP_TIS.TIS_GAL_REFCOMPL) )
                    and (   SUB_TIS.TIS_TASK_LINK_SEQ is null
                         or (SUB_TIS.TIS_TASK_LINK_SEQ = GRP_TIS.TIS_TASK_LINK_SEQ) )
                    and (   SUB_TIS.TIS_GROUP_ID is null
                         or SUB_TIS.TIS_GROUP_ID = GRP_TIS.TIS_GROUP_ID) )
      order by nvl(GRP_TIS.TIS_STAMPING_DATE, TIS.TIS_STAMPING_DATE) desc
             , nvl(GRP_TIS.FAL_TIME_STAMPING_ID, TIS.FAL_TIME_STAMPING_ID) desc;

    tplLastOtherOpStamping crLastOtherOpStampings%rowtype;
  begin
    -- Recherhce du timbrage précédent
    open crLastOtherOpStampings;

    fetch crLastOtherOpStampings
     into tplLastOtherOpStamping;

    -- Renvoi de record si trouvé
    if crLastOtherOpStampings%found then
      close crLastOtherOpStampings;

      return GetTimeStamping(tplLastOtherOpStamping.FAL_TIME_STAMPING_ID);
    end if;

    close crLastOtherOpStampings;

    return null;
  end GetLastOtherOpTimeStamping;

  /**
   * procedure OperatorChanged
   * Description
   *   Gestion du changement d'opérateur, en particulier sélection du prochain
   *   timbrage à effectuer pour celui-ci.
   */
  procedure OperatorChanged(aTimeStamping in out nocopy TTIME_STAMPING, aFocusField in out varchar2, aErrorCode in out integer, aErrorMessage in out varchar2)
  is
    vFocusField   varchar2(30);
    vErrorCode    integer;
    vErrorMessage varchar2(4000);
  begin
    -- Gestion du changement d'opérateur
    -- Reset du compteur de regroupement si l'opérateur a changé
    FAL_TIME_STAMPING_TOOLS.ClearGroupInfos(aTimeStamping => aTimeStamping);

    -- Détermination du prochain timbrage à effectuer par l'opérateur s'il a
    -- été saisi
    if aTimeStamping.TIS_DIC_OPERATOR_ID is not null then
      FAL_TIME_STAMPING_TOOLS.SelectNextStampToDo(aTimeStamping   => aTimeStamping
                                                , aFocusField     => vFocusField
                                                , aErrorCode      => vErrorCode
                                                , aErrorMessage   => vErrorMessage
                                                 );
      AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
      vErrorCode     := 0;
      vErrorMessage  := null;
      -- Contrôle multi-opérateur
      -- Vérifie si l'opération est en cours de réalisation par un autre
      -- opérateur et selon la config.
      FAL_TIME_STAMPING_TOOLS.ManageMultiOp(aTimeStamping   => aTimeStamping, aFocusField => vFocusField, aErrorCode => vErrorCode
                                          , aErrorMessage   => vErrorMessage);
      AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
    end if;
  end OperatorChanged;

  /**
   * procedure CombinedRefChanged
   * Description
   *   Gestion du changement de référence combinée.
   */
  procedure CombinedRefChanged(aTimeStamping in out nocopy TTIME_STAMPING, aFocusField in out varchar2, aErrorCode in out integer, aErrorMessage in out varchar2)
  is
    vFocusField   varchar2(30);
    vErrorCode    integer;
    vErrorMessage varchar2(4000);
  begin
    -- Gestion du changement de référence combinée
    -- Recherche du lot/dossier de fab, de l'op, etc. si la référence combinée a changé
    FAL_TIME_STAMPING_TOOLS.ParseCombinedRef(aTimeStamping   => aTimeStamping
                                           , aFocusField     => vFocusField
                                           , aErrorCode      => vErrorCode
                                           , aErrorMessage   => vErrorMessage
                                            );
    AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
    vErrorCode     := 0;
    vErrorMessage  := null;

    -- Si l'on est pas en saisie de groupe, on met l'ID de groupe à null (car
    -- il a été initialisé avec celui du dernier groupe saisi lors du choix
    -- de l'opérateur).
    if nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) = 0 then
      aTimeStamping.TIS_GROUP_ID  := null;
    end if;

    -- Contrôle multi-opérateur
    -- Vérifie si l'opération est en cours de réalisation par un autre
    -- opérateur et selon la config.
    FAL_TIME_STAMPING_TOOLS.ManageMultiOp(aTimeStamping => aTimeStamping, aFocusField => vFocusField, aErrorCode => vErrorCode, aErrorMessage => vErrorMessage);
    AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
  end CombinedRefChanged;

  /**
   * procedure TypeChanged
   * Description
   *   Gestion du changement de type de timbrage, contrôle en particulier qu'il
   *   est autorisé.
   */
  procedure TypeChanged(aTimeStamping in out nocopy TTIME_STAMPING, aFocusField in out varchar2, aErrorCode in out integer, aErrorMessage in out varchar2)
  is
    vFocusField   varchar2(30);
    vErrorCode    integer;
    vErrorMessage varchar2(4000);
  begin
    -- Gestion du changement de type
    FAL_TIME_STAMPING_TOOLS.ClearGroupInfos(aTimeStamping => aTimeStamping);
    -- Vérification que le type de timbrage choisi est possible pour l'opérateur
    FAL_TIME_STAMPING_TOOLS.CheckTimeStampingType(aTimeStamping   => aTimeStamping
                                                , aFocusField     => vFocusField
                                                , aErrorCode      => vErrorCode
                                                , aErrorMessage   => vErrorMessage
                                                 );
    AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
    vErrorCode     := 0;
    vErrorMessage  := null;
    -- Contrôle d'opération ou groupe multi-opérateur
    FAL_TIME_STAMPING_TOOLS.ManageMultiOp(aTimeStamping => aTimeStamping, aFocusField => vFocusField, aErrorCode => vErrorCode, aErrorMessage => vErrorMessage);
    AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
  end TypeChanged;

  /**
   * procedure CheckTimeStamping
   * Description
   *   Contrôle du timbrage.
   */
  procedure CheckTimeStamping(aTimeStamping in out nocopy TTIME_STAMPING, aFocusField in out varchar2, aErrorCode in out integer, aErrorMessage in out varchar2)
  is
    vFocusField   varchar2(30);
    vErrorCode    integer;
    vErrorMessage varchar2(4000);
  begin
    if aTimeStamping.TIS_DIC_OPERATOR_ID is null then
      AddError(aFocusField, 'TIS_VDIC_OPERATOR_ID', aErrorCode, 935, aErrorMessage, PCS.PC_FUNCTIONS.TranslateWord('L''opérateur est obligatoire.') );
    end if;

    -- Recherche du lot/dossier de fab, de l'op, etc. à partir de la référence combinée
    FAL_TIME_STAMPING_TOOLS.ParseCombinedRef(aTimeStamping, vFocusField, vErrorCode, vErrorMessage);

    -- Warnings ne devant pas bloquer la validation
    if vErrorCode in(684, 685) then
      vErrorCode  := 0;
    end if;

    -- Gestion des erreurs
    AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
    vErrorCode     := 0;
    vErrorMessage  := null;
    -- Contrôle du type de timbrage
    FAL_TIME_STAMPING_TOOLS.CheckTimeStampingType(aTimeStamping, vFocusField, vErrorCode, vErrorMessage, true);

    -- Warnings ne devant pas bloquer la validation
    if vErrorCode in(426, 427, 428, 429) then
      vErrorCode  := 0;
    end if;

    -- Gestion des erreurs
    AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
    vErrorCode     := 0;
    vErrorMessage  := null;
    -- Contrôle d'opération ou groupe multi-opérateur
    FAL_TIME_STAMPING_TOOLS.ManageMultiOp(aTimeStamping   => aTimeStamping
                                        , aFocusField     => vFocusField
                                        , aErrorCode      => vErrorCode
                                        , aErrorMessage   => vErrorMessage
                                        , aProcessing     => 1
                                         );
    AddError(aFocusField, vFocusField, aErrorCode, vErrorCode, aErrorMessage, vErrorMessage);
    vErrorCode     := 0;
    vErrorMessage  := null;

    -- En production la quantité réalisée est obligatoire pour terminer un groupe ou une opération
    if     (aTimeStamping.C_TIS_TYPE = FAL_TIME_STAMPING_TOOLS.stEnd)
       and aTimeStamping.TIS_PRODUCT_QTY is null
       and (aTimeStamping.C_PROGRESS_ORIGIN = FAL_TIME_STAMPING_TOOLS.poProduction) then
      AddError(aFocusField
             , 'TIS_VPRODUCT_QTY'
             , aErrorCode
             , 965
             , aErrorMessage
             , PCS.PC_FUNCTIONS.TranslateWord('La quantité réalisée est obligatoire pour terminer une opération ou un groupe en production.')
              );
    end if;
  end CheckTimeStamping;

  /**
   * procedure ManageGrouping
   * Description
   *   Mise à jour des champs pour la gestion de groupe.
   */
  procedure ManageGrouping(aTimeStamping in out nocopy TTIME_STAMPING)
  is
  begin
    -- Mise à jour des champs
    aTimeStamping.TIS_STAMPING_DATE         := sysdate;
    aTimeStamping.TIS_GROUP_TASK_BAL_COUNT  := nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, aTimeStamping.TIS_GROUP_TASK_COUNT);

    -- Initialisation de l'ID de group avec l'ID de la ligne si c'est la
    -- première opération d'un regroupement
    if aTimeStamping.C_TIS_TYPE in(FAL_TIME_STAMPING_TOOLS.stStartAdj, FAL_TIME_STAMPING_TOOLS.stStartWrk) then
      if aTimeStamping.TIS_GROUP_TASK_COUNT > 0 then
        if aTimeStamping.TIS_GROUP_ID is null then
          aTimeStamping.TIS_GROUP_ID  := aTimeStamping.FAL_TIME_STAMPING_ID;
        end if;
      end if;
    end if;
  end ManageGrouping;

  /**
   * procedure ProcessTimeStamping
   * Description
   *    Traitement du timbrage.
   */
  procedure ProcessTimeStamping(
    aTimeStamping in out nocopy TTIME_STAMPING
  , aFocusField   in out        varchar2
  , aErrorCode    in out        integer
  , aErrorMessage in out        varchar2
  )
  is
    vLastTimeStamping TTIME_STAMPING;
  begin
    -- Recherche du timbrage précédent
    vLastTimeStamping  := GetLastTimeStamping(aTimeStamping => aTimeStamping, aExcludeGrouping => 1);

    if nvl(aTimeStamping.TIS_GROUP_TASK_BAL_COUNT, 0) = 0 then
      case vLastTimeStamping.C_TIS_TYPE
        when FAL_TIME_STAMPING_TOOLS.stStartAdj then
          -- Génération du/des enregistrements dans le brouillard
          FAL_TIME_STAMPING_TOOLS.GenerateFogRecords(aTimeStamping    => aTimeStamping
                                                   , aAdjustingTime   => FAL_TIME_STAMPING_TOOLS.CalculateDuration(aTimeStamping, vLastTimeStamping)
                                                    );
        when FAL_TIME_STAMPING_TOOLS.stStartWrk then
          -- Génération du/des enregistrements dans le brouillard
          FAL_TIME_STAMPING_TOOLS.GenerateFogRecords(aTimeStamping   => aTimeStamping
                                                   , aWorkTime       => FAL_TIME_STAMPING_TOOLS.CalculateDuration(aTimeStamping, vLastTimeStamping)
                                                    );
        when FAL_TIME_STAMPING_TOOLS.stInterrupt then
          null;
        else
          if aTimeStamping.C_TIS_TYPE in(FAL_TIME_STAMPING_TOOLS.stStartAdj, FAL_TIME_STAMPING_TOOLS.stStartWrk) then
            if FAL_TIME_STAMPING_TOOLS.RequireEmptyProgress(aTimeStamping) then
              -- Génération d'un enregistrement à avancement nul dans le brouillard
              FAL_TIME_STAMPING_TOOLS.GenerateFogRecord(aTimeStamping => aTimeStamping);
            end if;
          end if;
      end case;
    end if;
  end ProcessTimeStamping;

  /**
   * function GetTimeStamping
   * Description
   *    Renvoie un record contenant les valeurs des champs et des champs virtuels
   *    du timbrage dont l'ID est passé en paramètre.
   */
  function GetTimeStamping(aTimeStampingId in FAL_TIME_STAMPING.FAL_TIME_STAMPING_ID%type)
    return TTIME_STAMPING
  is
    -- Attention ce curseur doit correspondre exactement avec le type de record TTIME_STAMPING
    cursor crTimeStamping(aTimeStampingId FAL_TIME_STAMPING.FAL_TIME_STAMPING_ID%type)
    is
      select TIS.FAL_TIME_STAMPING_ID
           , VFI.VFI_DESCODES_01 C_TIS_TYPE
           , TIS.C_TIS_STATUS
           , TIS.C_PROGRESS_ORIGIN
           , VFI.VFI_CHAR_01 TIS_DIC_OPERATOR_ID
           , VFI.VFI_CHAR_02 TIS_REF_FACTORY_FLOOR
           , VFI.VFI_CHAR_03 TIS_REF_FACTORY_FLOOR2
           , TIS.TIS_LOT_REFCOMPL
           , TIS.TIS_GAL_REFCOMPL
           , TIS.TIS_TASK_LINK_SEQ
           , TIS.TIS_TASK_LINK_ID
           , TIS.TIS_GROUP_ID
           , VFI.VFI_INTEGER_01 TIS_GROUP_TASK_COUNT
           , TIS.TIS_GROUP_TASK_BAL_COUNT
           , TIS.TIS_STAMPING_DATE
           , VFI.VFI_FLOAT_01 TIS_PRODUCT_QTY
           , VFI.VFI_FLOAT_02 TIS_PT_REJECT_QTY
           , VFI.VFI_FLOAT_03 TIS_CPT_REJECT_QTY
           , TIS.TIS_PRODUCT_QTY_UOP
           , TIS.TIS_PT_REJECT_QTY_UOP
           , TIS.TIS_CPT_REJECT_QTY_UOP
           , TIS.A_DATECRE
           , TIS.A_DATEMOD
           , TIS.A_IDCRE
           , TIS.A_IDMOD
           , VFI.COM_VFIELDS_RECORD_ID
           , VFI.VFI_MEMO_01 TIS_VCOMBINED_REF
           , VFI.VFI_CHAR_04 TIS_VDIC_REBUT_ID
           , VFI.VFI_MEMO_02 TIS_VLABEL_CONTROL
        from FAL_TIME_STAMPING TIS
           , COM_VFIELDS_RECORD VFI
       where TIS.FAL_TIME_STAMPING_ID = aTimeStampingId
         and VFI.VFI_TABNAME = 'FAL_TIME_STAMPING'
         and VFI.VFI_REC_ID = TIS.FAL_TIME_STAMPING_ID;

    vTimeStamping TTIME_STAMPING;
  begin
    -- Recherche des valeurs des champs et des champs virtuels du timbrage
    open crTimeStamping(aTimeStampingId);

    fetch crTimeStamping
     into vTimeStamping;

    -- Renvoi du record demandé
    return vTimeStamping;
  end GetTimeStamping;

  /**
   * procedure UpdateTimeStamping
   * Description
   *    Met physiquement à jour les champs et les champs virtuels du timbrage.
   */
  procedure UpdateTimeStamping(aTimeStamping in TTIME_STAMPING)
  is
  begin
    -- Mise à jour des champs à partir des valeurs du record
    update FAL_TIME_STAMPING
       set C_TIS_TYPE = aTimeStamping.C_TIS_TYPE
         , C_TIS_STATUS = aTimeStamping.C_TIS_STATUS
         , C_PROGRESS_ORIGIN = aTimeStamping.C_PROGRESS_ORIGIN
         , TIS_DIC_OPERATOR_ID = aTimeStamping.TIS_DIC_OPERATOR_ID
         , TIS_REF_FACTORY_FLOOR = aTimeStamping.TIS_REF_FACTORY_FLOOR
         , TIS_REF_FACTORY_FLOOR2 = aTimeStamping.TIS_REF_FACTORY_FLOOR2
         , TIS_LOT_REFCOMPL = aTimeStamping.TIS_LOT_REFCOMPL
         , TIS_GAL_REFCOMPL = aTimeStamping.TIS_GAL_REFCOMPL
         , TIS_TASK_LINK_SEQ = aTimeStamping.TIS_TASK_LINK_SEQ
         , TIS_TASK_LINK_ID = aTimeStamping.TIS_TASK_LINK_ID
         , TIS_GROUP_ID = aTimeStamping.TIS_GROUP_ID
         , TIS_GROUP_TASK_COUNT = aTimeStamping.TIS_GROUP_TASK_COUNT
         , TIS_GROUP_TASK_BAL_COUNT = aTimeStamping.TIS_GROUP_TASK_BAL_COUNT
         , TIS_STAMPING_DATE = aTimeStamping.TIS_STAMPING_DATE
         , TIS_PRODUCT_QTY = aTimeStamping.TIS_PRODUCT_QTY
         , TIS_PT_REJECT_QTY = aTimeStamping.TIS_PT_REJECT_QTY
         , TIS_CPT_REJECT_QTY = aTimeStamping.TIS_CPT_REJECT_QTY
         , TIS_PRODUCT_QTY_UOP = aTimeStamping.TIS_PRODUCT_QTY_UOP
         , TIS_PT_REJECT_QTY_UOP = aTimeStamping.TIS_PT_REJECT_QTY_UOP
         , TIS_CPT_REJECT_QTY_UOP = aTimeStamping.TIS_CPT_REJECT_QTY_UOP
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_TIME_STAMPING_ID = aTimeStamping.FAL_TIME_STAMPING_ID;

    -- Mise à jour des champs virtuels à partir des valeurs du record
    update COM_VFIELDS_RECORD
       set VFI_DESCODES_01 = aTimeStamping.C_TIS_TYPE
         , VFI_CHAR_01 = aTimeStamping.TIS_DIC_OPERATOR_ID
         , VFI_INTEGER_01 = aTimeStamping.TIS_GROUP_TASK_COUNT
         , VFI_MEMO_01 = aTimeStamping.TIS_VCOMBINED_REF
         , VFI_CHAR_02 = aTimeStamping.TIS_REF_FACTORY_FLOOR
         , VFI_CHAR_03 = aTimeStamping.TIS_REF_FACTORY_FLOOR2
         , VFI_FLOAT_01 = aTimeStamping.TIS_PRODUCT_QTY
         , VFI_FLOAT_02 = aTimeStamping.TIS_PT_REJECT_QTY
         , VFI_FLOAT_03 = aTimeStamping.TIS_CPT_REJECT_QTY
         , VFI_CHAR_04 = aTimeStamping.TIS_VDIC_REBUT_ID
         , VFI_MEMO_02 = aTimeStamping.TIS_VLABEL_CONTROL
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where COM_VFIELDS_RECORD_ID = aTimeStamping.COM_VFIELDS_RECORD_ID;
  end UpdateTimeStamping;
end FAL_TIME_STAMPING_MNGT;
