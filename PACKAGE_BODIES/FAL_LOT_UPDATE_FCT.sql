--------------------------------------------------------
--  DDL for Package Body FAL_LOT_UPDATE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LOT_UPDATE_FCT" 
is
  /**
   * procedure CalcLotValues
   * Description
   *   Crée les enregistrements temporaires et calcule les données à utiliser
   *   pour la mise à jour des lots
   */
  procedure CalcLotValues
  is
  begin
    -- Suppression des enregistrements précédents non-traités
    delete from FAL_LOT_UPDATE
          where C_LUP_STATUS = '10';

    -- Insertion des enregistrements à traiter
    insert into FAL_LOT_UPDATE
                (FAL_LOT_UPDATE_ID
               , FAL_LOT_ID
               , FAL_SCHEDULE_PLAN_ID
               , C_LUP_STATUS
                )
      select PCS.INIT_TEMP_ID_SEQ.nextval   -- FAL_LOT_UPDATE_ID
           , LOT.FAL_LOT_ID
           , LOT.FAL_SCHEDULE_PLAN_ID
           , '10'   -- C_LUP_STATUS
        from FAL_LOT LOT
       where LOT.FAL_LOT_ID in(select COM_LIST_ID_TEMP_ID
                                 from COM_LIST_ID_TEMP
                                where LID_CODE = 'FAL_LUP_LOT_ID')
         and LOT.C_LOT_STATUS = '1' /* Planifié */;
  end CalcLotValues;

  /**
   * procedure UpdateLots
   * Description
   *   Met à jour des lots à partir des données des enregistrements temporaires
   */
  procedure UpdateLots(aPlanType in integer)
  is
    cursor crLotsValues
    is
      select   LUP.FAL_LOT_UPDATE_ID
             , LUP.FAL_LOT_ID
             , LUP.FAL_SCHEDULE_PLAN_ID
             , LOT.LOT_PLAN_BEGIN_DTE
             , LOT.LOT_PLAN_END_DTE
             , LOT.LOT_TOLERANCE
             , LOT.LOT_TOTAL_QTY
             , LOT.C_SCHEDULE_PLANNING
          from FAL_LOT_UPDATE LUP
             , FAL_LOT LOT
         where LUP.LUP_SELECTION = 1
           and LUP.C_LUP_STATUS = '10'
           and LOT.FAL_LOT_ID = LUP.FAL_LOT_ID
      order by LUP.FAL_LOT_ID;

    vProcResult   integer                           := 1;
    vSqlCode      varchar2(10);
    vSqlMsg       varchar2(4000);
    vLotDateRef   FAL_LOT.LOT_PLAN_BEGIN_DTE%type;
    vLotBeginDate FAL_LOT.LOT_PLAN_BEGIN_DTE%type;
    vLotEndDate   FAL_LOT.LOT_PLAN_END_DTE%type;
    vLotDuration  FAL_LOT.LOT_PLAN_LEAD_TIME%type;
  begin
    -- Purge des lots vérouillés par des sessions inactives
    FAL_BATCH_RESERVATION.PurgeInactiveBatchReservation;

    -- Pour chaque élément sélectionné de la table temporaire
    for tplLotValues in crLotsValues loop
      begin
        -- Vérification que le lot pas verrouillé et verrouillage du lot
        FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID           => tplLotValues.FAL_LOT_ID
                                             , aLT1_ORACLE_SESSION   => DBMS_SESSION.unique_session_id
                                             , aErrorMsg             => vSqlMsg
                                              );

        if vSqlMsg is not null then
          vSqlCode  := '405';
        else
          begin
            -- Suppression et regénération des opérations
            FAL_TASK_GENERATOR.CALL_TASK_GENERATOR(iFAL_SCHEDULE_PLAN_ID   => tplLotValues.FAL_SCHEDULE_PLAN_ID
                                                 , iFAL_LOT_ID             => tplLotValues.FAL_LOT_ID
                                                 , iLOT_TOTAL_QTY          => tplLotValues.LOT_TOTAL_QTY
                                                 , iC_SCHEDULE_PLANNING    => tplLotValues.C_SCHEDULE_PLANNING
                                                 , iCONTEXTE               => FAL_TASK_GENERATOR.ctxtBatchCreation
                                                 , iSequence               => null
                                                  );
          exception
            -- En cas d'exception, spécification du code et du message erreur
            when others then
              begin
                vSqlCode  := '100';
                vSqlMsg   :=
                  PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la re-génération des opérations :') ||
                  chr(13) ||
                  chr(10) ||
                  DBMS_UTILITY.FORMAT_ERROR_STACK;
              end;
          end;

          if vSqlCode is null then
            begin
              -- Recherche de la date de référence pour la re-planification
              case aPlanType
                -- Planification date début
              when FAL_PLANIF.ctDateDebut then
                  vLotDateRef  := tplLotValues.LOT_PLAN_BEGIN_DTE;
                -- Planification date fin
              when FAL_PLANIF.ctDateFin then
                  vLotDateRef  := tplLotValues.LOT_PLAN_END_DTE;
              end case;

              -- Re-planification du lot
              FAL_PLANIF.PLANIF_LOT_CREATE(PrmFAL_LOT_ID              => tplLotValues.FAL_LOT_ID
                                         , PrmLOT_TOLERANCE           => tplLotValues.LOT_TOLERANCE
                                         , DatePlanification          => vLotDateRef
                                         , SelonDateDebut             => aPlanType
                                         , MAJReqLiensComposantsLot   => FAL_PLANIF.ctAvecMAJLienCompoLot
                                         , MAJ_Reseaux_Requise        => FAL_PLANIF.ctSansMAJReseau
                                         , LotBeginDate               => vLotBeginDate
                                         , LotEndDate                 => vLotEndDate
                                         , LotDuration                => vLotDuration
                                          );

              -- Mise à jour des données du lot
              update FAL_LOT
                 set LOT_PLAN_BEGIN_DTE = vLotBeginDate
                   , LOT_PLAN_END_DTE = vLotEndDate
                   , LOT_PLAN_LEAD_TIME = vLotDuration
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.USERINI
                   , A_DATEMOD = sysdate
               where FAL_LOT_ID = tplLotValues.FAL_LOT_ID;
            exception
              -- En cas d'exception, spécification du code et du message erreur
              when others then
                begin
                  vSqlCode  := '200';
                  vSqlMsg   :=
                    PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la re-planification du lot :') ||
                    chr(13) ||
                    chr(10) ||
                    DBMS_UTILITY.FORMAT_ERROR_STACK;
                end;
            end;

            if vSqlCode is null then
              begin
                -- Mise à jour des réseaux
                FAL_NETWORK.MiseAJourReseaux(tplLotValues.FAL_LOT_ID, FAL_NETWORK.ncPlannificationLot, null);
              exception
                -- En cas d'exception, spécification du code et du message erreur
                when others then
                  begin
                    vSqlCode  := '300';
                    vSqlMsg   :=
                      PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la mise à jour des réseaux :') ||
                      chr(13) ||
                      chr(10) ||
                      DBMS_UTILITY.FORMAT_ERROR_STACK;
                  end;
              end;
            end if;
          end if;
        end if;
      exception
        -- En cas d'exception, spécification du code et du message erreur
        when others then
          begin
            vSqlCode  := '400';
            vSqlMsg   :=
              PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la mise à jour du lot :') ||
              chr(13) ||
              chr(10) ||
              DBMS_UTILITY.FORMAT_ERROR_STACK;
          end;
      end;

      if vSqlCode is null then
        -- Mise à jour du statut dans la table temporaire
        update FAL_LOT_UPDATE
           set LUP_SELECTION = 0
             , C_LUP_STATUS = '20'
         where FAL_LOT_UPDATE_ID = tplLotValues.FAL_LOT_UPDATE_ID;
      else
        -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
        update FAL_LOT_UPDATE
           set LUP_SELECTION = 0
             , C_LUP_STATUS = '30'
             , C_LUP_ERROR_CODE = vSqlCode
             , LUP_ERROR_MESSAGE = vSqlMsg
         where FAL_LOT_UPDATE_ID = tplLotValues.FAL_LOT_UPDATE_ID;
      end if;

      -- Déverrouillage du lot
      FAL_BATCH_RESERVATION.ReleaseReservedbatches(DBMS_SESSION.unique_session_id);
    end loop;
  end UpdateLots;

  /**
   * procedure DeleteLupItems
   * Description
   *   Supprime les enregistrements temporaires déterminés par les paramètres
   */
  procedure DeleteLupItems(aC_LUP_STATUS in FAL_LOT_UPDATE.C_LUP_STATUS%type, aOnlySelected in integer default 0)
  is
  begin
    -- Suppression des enregistrements séléctionnés du statut précisé
    delete from FAL_LOT_UPDATE
          where C_LUP_STATUS = aC_LUP_STATUS
            and (   aOnlySelected = 0
                 or LUP_SELECTION = 1);
  end DeleteLupItems;
end FAL_LOT_UPDATE_FCT;
