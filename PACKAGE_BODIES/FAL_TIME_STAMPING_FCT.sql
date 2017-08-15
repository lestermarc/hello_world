--------------------------------------------------------
--  DDL for Package Body FAL_TIME_STAMPING_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_TIME_STAMPING_FCT" 
is
  /**
   * procedure InitTimeStamping
   * Description
   *   Initialisation du timbrage
   */
  procedure InitTimeStamping(
    aTimeStampingId     in     FAL_TIME_STAMPING.FAL_TIME_STAMPING_ID%type
  , aLastTimeStampingId in     FAL_TIME_STAMPING.FAL_TIME_STAMPING_ID%type
  , aReqActions         out    varchar2
  , aFocusField         out    varchar2
  , aErrorCode          out    integer
  , aErrorMessage       out    varchar2
  )
  is
    vTimeStamping     FAL_TIME_STAMPING_MNGT.TTIME_STAMPING;
    vLastTimeStamping FAL_TIME_STAMPING_MNGT.TTIME_STAMPING;
  begin
    aErrorCode                  := 0;
    vTimeStamping               := FAL_TIME_STAMPING_MNGT.GetTimeStamping(aTimeStampingId);
    -- Gestion de statut : 10 -> Nouveau timbrage
    vTimeStamping.C_TIS_STATUS  := ssNewStamping;
    -- Report de la valeur du champ Opérateur et du nombre d'opérations
    -- restantes du timbrage précédent
    vLastTimeStamping           :=
                         FAL_TIME_STAMPING_MNGT.GetLastTimeStamping(aTimeStamping   => vTimeStamping
                                                                  , aAllOperators   => 1);
    -- Initialisation du timbrage
    FAL_TIME_STAMPING_MNGT.InitTimeStamping(aTimeStamping       => vTimeStamping
                                          , aLastTimeStamping   => vLastTimeStamping
                                          , aFocusField         => aFocusField
                                          , aErrorCode          => aErrorCode
                                          , aErrorMessage       => aErrorMessage
                                           );
    -- Mise à jour physique des champs
    FAL_TIME_STAMPING_MNGT.UpdateTimeStamping(aTimeStamping => vTimeStamping);
  end InitTimeStamping;

  /**
   * procedure ValidTimeStamping
   * Description
   *   Validation du timbrage
   */
  procedure ValidTimeStamping(
    aTimeStampingId in     FAL_TIME_STAMPING.FAL_TIME_STAMPING_ID%type
  , aReqActions     out    varchar2
  , aFocusField     out    varchar2
  , aErrorCode      out    integer
  , aErrorMessage   out    varchar2
  )
  is
    vTimeStamping FAL_TIME_STAMPING_MNGT.TTIME_STAMPING;
  begin
    aErrorCode     := 0;
    vTimeStamping  := FAL_TIME_STAMPING_MNGT.GetTimeStamping(aTimeStampingId);

    if vTimeStamping.FAL_TIME_STAMPING_ID is null then
      aErrorCode     := -1;
      aErrorMessage  := 'System error 313786';
    else
      -- Si le timbrage a déjà été traité, on arrête le traitement
      if vTimeStamping.C_TIS_STATUS = ssProcessed then
        aErrorCode     := 267;
        aErrorMessage  := 'Input already processed';
      else
        -- Sinon, validation

        -- Vérifications
        FAL_TIME_STAMPING_MNGT.CheckTimeStamping(aTimeStamping   => vTimeStamping
                                               , aFocusField     => aFocusField
                                               , aErrorCode      => aErrorCode
                                               , aErrorMessage   => aErrorMessage
                                                );

        if aErrorCode <> 0 then
          -- Gestion de statut
          vTimeStamping.C_TIS_STATUS  := ssCheckError;
        else
          -- Mise à jour des champs de gestion de groupe
          FAL_TIME_STAMPING_MNGT.ManageGrouping(aTimeStamping => vTimeStamping);
          -- Traitement d'importation (mise à jour des tables métier) à partir
          -- des données la table principale.
          -- ......
          FAL_TIME_STAMPING_MNGT.ProcessTimeStamping(aTimeStamping   => vTimeStamping
                                                   , aFocusField     => aFocusField
                                                   , aErrorCode      => aErrorCode
                                                   , aErrorMessage   => aErrorMessage
                                                    );

          if aErrorCode <> 0 then
            -- Gestion de statut
            vTimeStamping.C_TIS_STATUS  := ssProcessError;
          else
            -- Gestion de statut
            vTimeStamping.C_TIS_STATUS  := ssProcessed;
            FAL_TIME_STAMPING_TOOLS.GroupTaskAdded(aTimeStamping => vTimeStamping);
            FAL_TIME_STAMPING_TOOLS.ArchiveTimeStampings(aTimeStamping => vTimeStamping);
          end if;
        end if;

        -- Mise à jour effective de la table de timbrage et des champs virtuels
        FAL_TIME_STAMPING_MNGT.UpdateTimeStamping(aTimeStamping => vTimeStamping);
      end if;
    end if;

    -- Application du traitement du brouillard
    if vTimeStamping.C_TIS_STATUS in(ssProcessed, ssArchived) then
      -- Commit des modifications avant l'application du traitement du brouillard
      commit;
      FAL_SUIVI_OPERATION.ApplyDayBook;
    end if;
  end ValidTimeStamping;

  /**
   * procedure FieldChanged
   * Description
   *   Procédure d'événement de sortie d'un champ virtuel
   */
  procedure FieldChanged(
    aTimeStampingId in     FAL_TIME_STAMPING.FAL_TIME_STAMPING_ID%type
  , aFieldName      in     varchar2
  , aFieldModified  in     integer
  , aFocusField     out    varchar2
  , aErrorCode      out    integer
  , aErrorMessage   out    varchar2
  )
  is
    vTimeStamping FAL_TIME_STAMPING_MNGT.TTIME_STAMPING;
  begin
    aErrorCode  := 0;

    if aFieldModified = 1 then
      vTimeStamping  := FAL_TIME_STAMPING_MNGT.GetTimeStamping(aTimeStampingId);

      if vTimeStamping.FAL_TIME_STAMPING_ID is null then
        aErrorCode     := -1;
        aErrorMessage  := 'System error 687642';
      else
        if aFieldName = 'TIS_VDIC_OPERATOR_ID' then
          -- Gestion du changement d'opérateur
          FAL_TIME_STAMPING_MNGT.OperatorChanged(aTimeStamping   => vTimeStamping
                                               , aFocusField     => aFocusField
                                               , aErrorCode      => aErrorCode
                                               , aErrorMessage   => aErrorMessage
                                                );
        elsif aFieldName = 'TIS_VCOMBINED_REF' then
          -- Gestion du changement de référence combinée
          FAL_TIME_STAMPING_MNGT.CombinedRefChanged(aTimeStamping   => vTimeStamping
                                                  , aFocusField     => aFocusField
                                                  , aErrorCode      => aErrorCode
                                                  , aErrorMessage   => aErrorMessage
                                                   );
        elsif aFieldName = 'C_TIS_VTYPE' then
          -- Gestion du changement de type
          FAL_TIME_STAMPING_MNGT.TypeChanged(aTimeStamping   => vTimeStamping
                                           , aFocusField     => aFocusField
                                           , aErrorCode      => aErrorCode
                                           , aErrorMessage   => aErrorMessage
                                            );
        end if;

        -- Mise à jour effective de la table de timbrage et des champs virtuels
        FAL_TIME_STAMPING_MNGT.UpdateTimeStamping(aTimeStamping => vTimeStamping);
      end if;
    end if;
  end FieldChanged;
end FAL_TIME_STAMPING_FCT;
