--------------------------------------------------------
--  DDL for Package Body FAL_TASK_GENERATOR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_TASK_GENERATOR" 
is
  cProgressTime boolean := PCS.PC_CONFIG.GetBooleanConfig('FAL_PROGRESS_TIME');

  /**
   * procedure UpdateBatchQty
   * Description
   *   Mise � jour des op. suite � une modification de la quantit� du lot
   * @author CLE
   * @lastUpdate age 20.06.2014
   * @Public
   */
  procedure UpdateBatchQty(aFalLotId FAL_LOT.FAL_LOT_ID%type, aNewTotalQty FAL_LOT.LOT_TOTAL_QTY%type, oError out varchar2, iContext in integer default 0)
  is
    lError         varchar2(4000);

    cursor crBatchOperations
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_OPERATION_TYPE
             , C_TASK_TYPE
             , TAL_AVALAIBLE_QTY
             , TAL_SUBCONTRACT_QTY
             , nvl(TAL_PLAN_QTY, 0) TAL_PLAN_QTY
             , nvl(TAL_DUE_QTY, 0) TAL_DUE_QTY
             , nvl(TAL_RELEASE_QTY, 0) TAL_RELEASE_QTY
             , nvl(TAL_R_METER, 0) TAL_R_METER
             , TAL_END_REAL_DATE
             , TAL_PLAN_RATE
             , nvl(SCS_QTY_REF_WORK, 1) SCS_QTY_REF_WORK
             , nvl(SCS_QTY_FIX_ADJUSTING, 0) SCS_QTY_FIX_ADJUSTING
             , TAL_DUE_TSK
             , nvl(SCS_WORK_TIME, 0) SCS_WORK_TIME
             , nvl(TAL_ACHIEVED_TSK, 0) TAL_ACHIEVED_TSK
             , nvl(TAL_ACHIEVED_AD_TSK, 0) TAL_ACHIEVED_AD_TSK
             , TAL_TSK_AD_BALANCE
             , TAL_TSK_W_BALANCE
             , SCS_DIVISOR_AMOUNT
             , nvl(SCS_PLAN_RATE, 0) SCS_PLAN_RATE
             , nvl(SCS_ADJUSTING_TIME, 0) SCS_ADJUSTING_TIME
             , TAL_TSK_BALANCE
             , SCS_QTY_REF_AMOUNT
             , SCS_AMOUNT
             , LOT.C_LOT_STATUS
             , LOT.LOT_TOTAL_QTY
          from FAL_TASK_LINK
             , (select C_LOT_STATUS
                     , LOT_TOTAL_QTY
                  from FAL_LOT
                 where FAL_LOT_ID = aFalLotId) LOT
         where FAL_LOT_ID = aFalLotId
      order by SCS_STEP_NUMBER;

    FoundPrincipal boolean;
    lTotalQtyCST   number;
    lDeltaQtyCST   number;
    lDeltaQty      number;
  begin
    FoundPrincipal  := false;
    lDeltaQtyCST    := 0;
    lTotalQtyCST    := aNewTotalQty;

    for tplBatchOperation in crBatchOperations loop
      --traitement du lien tache lot pseudo. On ne traite que la premi�re op�ration principale.
      if     (tplBatchOperation.C_OPERATION_TYPE = '1')
         and (not FoundPrincipal) then
        foundPrincipal  := true;
        lDeltaQty       :=(tplBatchOperation.LOT_TOTAL_QTY - aNewTotalQty);

        -- V�rification que le lot de fabrication est en statut lanc�
        -- Si c'est le cas alors on met � jour la quantit� dispo
        if tplBatchOperation.C_LOT_STATUS = '2' then
          if tplBatchOperation.C_TASK_TYPE = '2' then   -- op�ration externe maj des CST
            if lDeltaQty <= tplBatchOperation.TAL_AVALAIBLE_QTY then
              -- Qte Disponible
              tplBatchOperation.TAL_AVALAIBLE_QTY  := tplBatchOperation.TAL_AVALAIBLE_QTY - lDeltaQty;
            else
              lDeltaQty                            := lDeltaQty - tplBatchOperation.TAL_AVALAIBLE_QTY;
              lTotalQtyCST                         := tplBatchOperation.TAL_SUBCONTRACT_QTY - lDeltaQty;
              tplBatchOperation.TAL_AVALAIBLE_QTY  := 0;
            end if;
          else
            -- Qte Disponible
            tplBatchOperation.TAL_AVALAIBLE_QTY  := tplBatchOperation.TAL_AVALAIBLE_QTY - lDeltaQty;
          end if;
        end if;
      end if;

      -- Mise � jour "automatique" des CST demand�
      if     (iContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting)
         and (tplBatchOperation.C_TASK_TYPE = '2')
         and (PCS.PC_CONFIG.GetConfig('FAL_SUBCONTRACT_LAUNCH') = '1') then
        -- Mise � jour de la quantit� de la CST ou cr�ation d'une nouvelle position ou cr�ation d'une nouvelle CST
        DOC_PRC_SUBCONTRACTO.UpdateCST(tplBatchOperation.FAL_SCHEDULE_STEP_ID, lTotalQtyCST, lDeltaQtyCST, lError);

        if lError is not null then
          oError  := lError;
        elsif(lDeltaQtyCST <> 0) then
          -- Une modification ou g�n�ration de CST a �t� effectu�. Le choix des op�rations � traiter n'est pas demand�.
          -- Si la mise � jour de la CST c'est d�roul� sans erreur et que le choix des op�rations � traiter n'est pas demand�,
          -- l'en-cours et le disponible sont d�j� � jour dans la base de donn�e par la m�thode FAL_PRC_SUBCONTRACTO.updateOpAtPosGeneration.
          tplBatchOperation.TAL_SUBCONTRACT_QTY  := null;
          tplBatchOperation.TAL_AVALAIBLE_QTY    := null;
        end if;
      end if;

      -- Qte demand�e
      if tplBatchOperation.C_OPERATION_TYPE <> '4' then
        tplBatchOperation.TAL_PLAN_QTY  := aNewTotalQty;
      end if;

      -- Qte Solde
      tplBatchOperation.TAL_DUE_QTY      := tplBatchOperation.TAL_PLAN_QTY -(tplBatchOperation.TAL_RELEASE_QTY + tplBatchOperation.TAL_R_METER);

      if tplBatchOperation.TAL_DUE_QTY < 0 then
        tplBatchOperation.TAL_DUE_QTY  := 0;
      end if;

      -- Date fin R�elle
      if tplBatchOperation.TAL_DUE_QTY > 0 then
        tplBatchOperation.TAL_END_REAL_DATE  := null;
      end if;

      -- Cadencement
      tplBatchOperation.TAL_PLAN_RATE    := (tplBatchOperation.TAL_DUE_QTY / tplBatchOperation.SCS_QTY_REF_WORK) * tplBatchOperation.SCS_PLAN_RATE;

      -- Travail du
      if tplBatchOperation.SCS_QTY_FIX_ADJUSTING <> 0 then
        tplBatchOperation.TAL_DUE_TSK  :=
          (FAL_TOOLS.RoundSuccInt(tplBatchOperation.TAL_PLAN_QTY / tplBatchOperation.SCS_QTY_FIX_ADJUSTING) * tplBatchOperation.SCS_ADJUSTING_TIME
          ) +
          ( (tplBatchOperation.TAL_PLAN_QTY / tplBatchOperation.SCS_QTY_REF_WORK) * tplBatchOperation.SCS_WORK_TIME);
      else
        tplBatchOperation.TAL_DUE_TSK  :=
                 tplBatchOperation.SCS_ADJUSTING_TIME
                 +( (tplBatchOperation.TAL_PLAN_QTY / tplBatchOperation.SCS_QTY_REF_WORK) * tplBatchOperation.SCS_WORK_TIME);
      end if;

      -- Soldes travail et r�glage non modifi�s si la config avancement en temps est activ�e
      if not cProgressTime then
        -- Solde r�glage (s'il d�pend de la quantit�)
        if tplBatchOperation.SCS_QTY_FIX_ADJUSTING <> 0 then
          tplBatchOperation.TAL_TSK_AD_BALANCE  :=
                          FAL_TOOLS.RoundSuccInt(tplBatchOperation.TAL_DUE_QTY / tplBatchOperation.SCS_QTY_FIX_ADJUSTING)
                          * tplBatchOperation.SCS_ADJUSTING_TIME;
        end if;

        -- Solde travail
        tplBatchOperation.TAL_TSK_W_BALANCE  := (tplBatchOperation.TAL_DUE_QTY / tplBatchOperation.SCS_QTY_REF_WORK) * tplBatchOperation.SCS_WORK_TIME;
      end if;

      -- Solde travail Total
      tplBatchOperation.TAL_TSK_BALANCE  := nvl(tplBatchOperation.TAL_TSK_AD_BALANCE, 0) + nvl(tplBatchOperation.TAL_TSK_W_BALANCE, 0);

      update FAL_TASK_LINK
         set TAL_AVALAIBLE_QTY = greatest(0, coalesce(tplBatchOperation.TAL_AVALAIBLE_QTY, TAL_AVALAIBLE_QTY, 0) )   -- Mise � jour si besoin
           , TAL_PLAN_QTY = tplBatchOperation.TAL_PLAN_QTY
           , TAL_DUE_QTY = tplBatchOperation.TAL_DUE_QTY
           , TAL_SUBCONTRACT_QTY = coalesce(tplBatchOperation.TAL_SUBCONTRACT_QTY, TAL_SUBCONTRACT_QTY, 0)   -- Mise � jour si besoin
           , TAL_END_REAL_DATE = tplBatchOperation.TAL_END_REAL_DATE
           , TAL_PLAN_RATE = tplBatchOperation.TAL_PLAN_RATE
           , TAL_DUE_TSK = tplBatchOperation.TAL_DUE_TSK
           , TAL_TSK_AD_BALANCE = tplBatchOperation.TAL_TSK_AD_BALANCE
           , TAL_TSK_W_BALANCE = tplBatchOperation.TAL_TSK_W_BALANCE
           , TAL_TSK_BALANCE = tplBatchOperation.TAL_TSK_BALANCE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = tplBatchOperation.FAL_SCHEDULE_STEP_ID;
    end loop;

    /* Mise � jour de la quantit� disponible des op�rations */
    FAL_PRC_TASK_LINK.UpdateAvailQtyOp(aFalLotId);
  end;

  /**
  * procedure CALL_TASK_GENERATOR
  * Description
  *   G�n�ration des Op pour un lot de fabrication
  * @author CLE
  * @lastUpdate
  * @Public
  * @param     iFAL_SCHEDULE_PLAN_ID   Gamme op�ratoire
  * @param     iFAL_LOT_ID             Lot de fabrication
  * @param     iLOT_TOTAL_QTY          Qt� totale du lot
  * @param     iC_SCHEDULE_PLANNING    Type de plannification
  * @param     iContexte               context d'utilisation de la fonctions (cf ent�te)
  * @param     iSequence               s�quence op�ration
  * @param     iFAL_TASK_ID            T�che standard
  * @param     iSCS_WORK_TIME          Temps travail
  * @param     iRegenerateAll          re-g�n�ration compl�te de la gamme
  * @param     iPacSupplierPartnerId   fournisseur
  * @param     iGcoGcoGoodId           Bien li�
  * @param     iScsAmount              Montant
  * @param     iScsQtyRefAmount        Qt� r�f�rence montant
  * @param     iScsDivisorAmount       Diviseur
  * @param     iScsWeigh               Pes�e mati�re pr�cieuses
  * @param     iScsWeighMandatory      Pes�e obligatoire
  * @param     iScsPlanRate            Dur�e en jours
  * @param     iScsPlanProp            Dur�e proportionnelle ou fixe
  * @param     iScsQtyRefWork          Qt� de r�f�rence travail
  */
  procedure CALL_TASK_GENERATOR(
    iFAL_SCHEDULE_PLAN_ID in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  , iFAL_LOT_ID           in FAL_LOT.FAL_LOT_ID%type
  , iLOT_TOTAL_QTY        in FAL_LOT.LOT_TOTAL_QTY%type
  , iC_SCHEDULE_PLANNING  in FAL_LOT.C_SCHEDULE_PLANNING%type
  , iContexte             in integer
  , iDateLancement        in date default sysdate
  , iSequence             in FAL_LIST_STEP_LINK.SCS_STEP_NUMBER%type default null
  , iFAL_TASK_ID          in number default null
  , iSCS_WORK_TIME        in number default 0
  , iRegenerateAll        in integer default 1
  , iPacSupplierPartnerId in number default null
  , iGcoGcoGoodId         in number default null
  , iScsAmount            in number default 0
  , iScsQtyRefAmount      in integer default 0
  , iScsDivisorAmount     in integer default 0
  , iScsWeigh             in integer default 0
  , iScsWeighMandatory    in integer default 0
  , iScsPlanRate          in number default 1
  , iScsPlanProp          in integer default 0
  , iScsQtyRefWork        in integer default 1
  )
  is
    liSequence               FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    liIncrementvalue         integer;
    lNewFAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;

    -- Curseur sur les op�rations de gamme
    cursor crFalListStepLink
    is
      select   FAL_SCHEDULE_STEP_ID
          from FAL_LIST_STEP_LINK
         where FAL_SCHEDULE_PLAN_ID = iFAL_SCHEDULE_PLAN_ID
           and nvl(SCS_STEP_NUMBER, 0) >= nvl(iSequence, 0)
           and C_OPERATION_TYPE <> '3'
      order by SCS_STEP_NUMBER;
  begin
    -- Context SAV, on insert depuis une op�ration standard
    if iContexte = CtxtAfterSales then
      lNewFAL_SCHEDULE_STEP_ID  :=
        FAL_OPERATION_FUNCTIONS.CreateBatchOperation(iFalLotId      => iFAL_LOT_ID
                                                   , iQty           => iLOT_TOTAL_QTY
                                                   , iFalTaskId     => iFAL_TASK_ID
                                                   , iSequence      => iSequence
                                                   , iScsWorkTime   => iSCS_WORK_TIME
                                                   , iContext       => iContexte
                                                    );
    else
      liIncrementValue  := PCS.PC_CONFIG.GetConfig('PPS_Task_Numbering');

      if iRegenerateAll = 1 then
        -- Stockage du status du lot (traitement trigger FAL_TASK_LINK_BD_DOC_POS_DET)
        COM_I_LIB_LIST_ID_TEMP.setGlobalVar(iVarName => 'BATCH_STATUS', iValue => FAL_LIB_BATCH.getBatchStatus(iFAL_LOT_ID) );

        -- On efface la liste d'op�rations d�j� existante
        delete      FAL_TASK_LINK
              where FAL_LOT_ID = iFAL_LOT_ID;

        -- Supprimer le stockage du status du lot
        COM_I_LIB_LIST_ID_TEMP.clearGlobalVar(iVarName => 'BATCH_STATUS');
      end if;

      select max(SCS_STEP_NUMBER)
        into liSequence
        from FAL_TASK_LINK
       where FAL_LOT_ID = iFAL_LOT_ID;

      for tplFalListStepLink in crFalListStepLink loop
        liSequence                := liSequence + liIncrementvalue;
        lNewFAL_SCHEDULE_STEP_ID  :=
          FAL_OPERATION_FUNCTIONS.CreateBatchOperation(iFalLotId               => iFAL_LOT_ID
                                                     , iQty                    => iLOT_TOTAL_QTY
                                                     , iFalListStepLinkId      => tplFalListStepLink.FAL_SCHEDULE_STEP_ID
                                                     , iSequence               => liSequence
                                                     , iContext                => iContexte
                                                     , iPacSupplierPartnerId   => iPacSupplierPartnerId
                                                     , iGcoGcoGoodId           => iGcoGcoGoodId
                                                     , iScsAmount              => iScsAmount
                                                     , iScsQtyRefAmount        => iScsQtyRefAmount
                                                     , iScsDivisorAmount       => iScsDivisorAmount
                                                     , iScsWeigh               => iScsWeigh
                                                     , iScsWeighMandatory      => iScsWeighMandatory
                                                     , iScsPlanRate            => iScsPlanRate
                                                     , iScsPlanProp            => iScsPlanProp
                                                     , iScsQtyRefWork          => iScsQtyRefWork
                                                      );
      end loop;

      -- Si le lot est lanc�, mise � jour lien t�che lot pseudo. Qt� dispo = Qt� solde
      -- pour la premi�re op�ration principale du lot
      update FAL_TASK_LINK
         set TAL_AVALAIBLE_QTY = TAL_DUE_QTY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = iFAL_LOT_ID
         and SCS_STEP_NUMBER = (select min(SCS_STEP_NUMBER)
                                  from FAL_TASK_LINK
                                 where FAL_LOT_ID = iFAL_LOT_ID
                                   and C_OPERATION_TYPE = '1')
         and (select LOT_TO_BE_RELEASED
                from FAL_LOT
               where FAL_LOT_ID = iFAL_LOT_ID) = 1;
    end if;
  end;
end;
