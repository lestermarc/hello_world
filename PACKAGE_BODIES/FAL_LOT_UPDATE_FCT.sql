--------------------------------------------------------
--  DDL for Package Body FAL_LOT_UPDATE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LOT_UPDATE_FCT" 
is
  /**
   * procedure CalcLotValues
   * Description
   *   Cr�e les enregistrements temporaires et calcule les donn�es � utiliser
   *   pour la mise � jour des lots
   */
  procedure CalcLotValues
  is
  begin
    -- Suppression des enregistrements pr�c�dents non-trait�s
    delete from FAL_LOT_UPDATE
          where C_LUP_STATUS = '10';

    -- Insertion des enregistrements � traiter
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
         and LOT.C_LOT_STATUS = '1' /* Planifi� */;
  end CalcLotValues;

  /**
   * procedure UpdateLots
   * Description
   *   Met � jour des lots � partir des donn�es des enregistrements temporaires
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
    -- Purge des lots v�rouill�s par des sessions inactives
    FAL_BATCH_RESERVATION.PurgeInactiveBatchReservation;

    -- Pour chaque �l�ment s�lectionn� de la table temporaire
    for tplLotValues in crLotsValues loop
      begin
        -- V�rification que le lot pas verrouill� et verrouillage du lot
        FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID           => tplLotValues.FAL_LOT_ID
                                             , aLT1_ORACLE_SESSION   => DBMS_SESSION.unique_session_id
                                             , aErrorMsg             => vSqlMsg
                                              );

        if vSqlMsg is not null then
          vSqlCode  := '405';
        else
          begin
            -- Suppression et reg�n�ration des op�rations
            FAL_TASK_GENERATOR.CALL_TASK_GENERATOR(iFAL_SCHEDULE_PLAN_ID   => tplLotValues.FAL_SCHEDULE_PLAN_ID
                                                 , iFAL_LOT_ID             => tplLotValues.FAL_LOT_ID
                                                 , iLOT_TOTAL_QTY          => tplLotValues.LOT_TOTAL_QTY
                                                 , iC_SCHEDULE_PLANNING    => tplLotValues.C_SCHEDULE_PLANNING
                                                 , iCONTEXTE               => FAL_TASK_GENERATOR.ctxtBatchCreation
                                                 , iSequence               => null
                                                  );
          exception
            -- En cas d'exception, sp�cification du code et du message erreur
            when others then
              begin
                vSqlCode  := '100';
                vSqlMsg   :=
                  PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la re-g�n�ration des op�rations :') ||
                  chr(13) ||
                  chr(10) ||
                  DBMS_UTILITY.FORMAT_ERROR_STACK;
              end;
          end;

          if vSqlCode is null then
            begin
              -- Recherche de la date de r�f�rence pour la re-planification
              case aPlanType
                -- Planification date d�but
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

              -- Mise � jour des donn�es du lot
              update FAL_LOT
                 set LOT_PLAN_BEGIN_DTE = vLotBeginDate
                   , LOT_PLAN_END_DTE = vLotEndDate
                   , LOT_PLAN_LEAD_TIME = vLotDuration
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.USERINI
                   , A_DATEMOD = sysdate
               where FAL_LOT_ID = tplLotValues.FAL_LOT_ID;
            exception
              -- En cas d'exception, sp�cification du code et du message erreur
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
                -- Mise � jour des r�seaux
                FAL_NETWORK.MiseAJourReseaux(tplLotValues.FAL_LOT_ID, FAL_NETWORK.ncPlannificationLot, null);
              exception
                -- En cas d'exception, sp�cification du code et du message erreur
                when others then
                  begin
                    vSqlCode  := '300';
                    vSqlMsg   :=
                      PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la mise � jour des r�seaux :') ||
                      chr(13) ||
                      chr(10) ||
                      DBMS_UTILITY.FORMAT_ERROR_STACK;
                  end;
              end;
            end if;
          end if;
        end if;
      exception
        -- En cas d'exception, sp�cification du code et du message erreur
        when others then
          begin
            vSqlCode  := '400';
            vSqlMsg   :=
              PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la mise � jour du lot :') ||
              chr(13) ||
              chr(10) ||
              DBMS_UTILITY.FORMAT_ERROR_STACK;
          end;
      end;

      if vSqlCode is null then
        -- Mise � jour du statut dans la table temporaire
        update FAL_LOT_UPDATE
           set LUP_SELECTION = 0
             , C_LUP_STATUS = '20'
         where FAL_LOT_UPDATE_ID = tplLotValues.FAL_LOT_UPDATE_ID;
      else
        -- Mise � jour du statut et des d�tails de l'erreur dans la table temporaire
        update FAL_LOT_UPDATE
           set LUP_SELECTION = 0
             , C_LUP_STATUS = '30'
             , C_LUP_ERROR_CODE = vSqlCode
             , LUP_ERROR_MESSAGE = vSqlMsg
         where FAL_LOT_UPDATE_ID = tplLotValues.FAL_LOT_UPDATE_ID;
      end if;

      -- D�verrouillage du lot
      FAL_BATCH_RESERVATION.ReleaseReservedbatches(DBMS_SESSION.unique_session_id);
    end loop;
  end UpdateLots;

  /**
   * procedure DeleteLupItems
   * Description
   *   Supprime les enregistrements temporaires d�termin�s par les param�tres
   */
  procedure DeleteLupItems(aC_LUP_STATUS in FAL_LOT_UPDATE.C_LUP_STATUS%type, aOnlySelected in integer default 0)
  is
  begin
    -- Suppression des enregistrements s�l�ctionn�s du statut pr�cis�
    delete from FAL_LOT_UPDATE
          where C_LUP_STATUS = aC_LUP_STATUS
            and (   aOnlySelected = 0
                 or LUP_SELECTION = 1);
  end DeleteLupItems;
end FAL_LOT_UPDATE_FCT;
