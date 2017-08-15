--------------------------------------------------------
--  DDL for Package Body FAL_ACCOUNTING_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ACCOUNTING_FUNCTIONS" 
is
  /**
  * procedure   : InsertMatElementCost
  * Description : G�n�ration des co�ts mati�re en cours
  *               et r�alis� pour un ordre de fabrication
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  * @param   aFAL_LOT_ID : Lot de fabrication
  * @param   aFAL_LOT_MATERIAL_LINK_ID : Composant
  * @param   aSMO_MOVEMENT_PRICE : montant
  * @param   aSTM_STOCK_MOVEMENT_ID : ID du mouvement initiateur du co�t
  * @param   aMvtKindType : Genre de mouvement.
  * @param   aMvtKindSens : Sens du mouvement.
  * @param   aMvtQty : Qt� du mouvement
  */
  procedure InsertMatElementCost(
    aFAL_LOT_ID               number
  , aFAL_LOT_MATERIAL_LINK_ID number
  , aSMO_MOVEMENT_PRICE       number
  , aSTM_STOCK_MOVEMENT_ID    number
  , aMvtKindType              integer
  , aMvtKindSens              varchar2
  , aMvtQty                   number
  )
  is
    aFEC_CURRENT_AMOUNT     number;
    aFEC_COMPLETED_AMOUNT   number;
    aFEC_CURRENT_QUANTITY   number;
    aFEC_COMPLETED_QUANTITY number;
    aErrorMsg               varchar2(255);
  begin
    if     PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2')
       and nvl(aSMO_MOVEMENT_PRICE, 0) <> 0 then
      -- D�termination du signe de l'�l�ment de co�t
      case aMvtKindType
        when FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier then
          if aMvtKindSens = FAL_STOCK_MOVEMENT_FUNCTIONS.mksIN then
            aFEC_CURRENT_AMOUNT      := aSMO_MOVEMENT_PRICE;
            aFEC_COMPLETED_AMOUNT    := 0;
            aFEC_CURRENT_QUANTITY    := aMvtQty;
            aFEC_COMPLETED_QUANTITY  := 0;
          else
            return;
          end if;
        when FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet then
          if aMvtKindSens = FAL_STOCK_MOVEMENT_FUNCTIONS.mksOUT then
            aFEC_CURRENT_AMOUNT      := -aSMO_MOVEMENT_PRICE;
            aFEC_COMPLETED_AMOUNT    := aSMO_MOVEMENT_PRICE;
            aFEC_CURRENT_QUANTITY    := -aMvtQty;
            aFEC_COMPLETED_QUANTITY  := aMvtQty;
          else
            return;
          end if;
        when FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock then
          if aMvtKindSens = FAL_STOCK_MOVEMENT_FUNCTIONS.mksOUT then
            aFEC_CURRENT_AMOUNT      := -aSMO_MOVEMENT_PRICE;
            aFEC_COMPLETED_AMOUNT    := 0;
            aFEC_CURRENT_QUANTITY    := -aMvtQty;
            aFEC_COMPLETED_QUANTITY  := 0;
          else
            return;
          end if;
        when FAL_STOCK_MOVEMENT_FUNCTIONS.mktComposantConsomme then
          if aMvtKindSens = FAL_STOCK_MOVEMENT_FUNCTIONS.mksOUT then
            aFEC_CURRENT_AMOUNT      := -aSMO_MOVEMENT_PRICE;
            aFEC_COMPLETED_AMOUNT    := aSMO_MOVEMENT_PRICE;
            aFEC_CURRENT_QUANTITY    := -aMvtQty;
            aFEC_COMPLETED_QUANTITY  := aMvtQty;
          else
            return;
          end if;
        when FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitTermine then
          return;
        when FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionRebut then
          return;
        when FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitDerive then
          if aMvtKindSens = FAL_STOCK_MOVEMENT_FUNCTIONS.mksIN then
            aFEC_CURRENT_AMOUNT      := 0;
            aFEC_COMPLETED_AMOUNT    := -aSMO_MOVEMENT_PRICE;
            aFEC_CURRENT_QUANTITY    := 0;
            aFEC_COMPLETED_QUANTITY  := aMvtQty;
          else
            return;
          end if;
        else
          aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Type de mouvement inconnu : ') || aMvtKindType;
          raise_application_error(-20060, aErrorMsg);
          return;
      end case;

      -- Insertion de l'�l�ment de co�t
      insert into FAL_ELEMENT_COST
                  (FAL_ELEMENT_COST_ID
                 , FAL_LOT_ID
                 , FAL_LOT_MATERIAL_LINK_ID
                 , C_COST_ELEMENT_TYPE
                 , FEC_CURRENT_AMOUNT
                 , FEC_COMPLETED_AMOUNT
                 , STM_STOCK_MOVEMENT_ID
                 , FEC_CURRENT_QUANTITY
                 , FEC_COMPLETED_QUANTITY
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aFAL_LOT_ID
                 , aFAL_LOT_MATERIAL_LINK_ID
                 , 'MAT'
                 , aFEC_CURRENT_AMOUNT
                 , aFEC_COMPLETED_AMOUNT
                 , aSTM_STOCK_MOVEMENT_ID
                 , aFEC_CURRENT_QUANTITY
                 , aFEC_COMPLETED_QUANTITY
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  );
    end if;
  end InsertMatElementCost;

  /**
  * procedure   : InsertReversalMatElementCost
  * Description : G�n�ration des co�ts mati�re en cours pour un mouvement
  *               d'extourne d'un mouvement origine (Eclatement d'of)
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  * @param   aSTM_STOCK_MOVEMENT_ID : Mouvement extourn�
  * @param   aMvtQty : Qt� de l'extourne
  */
  procedure InsertReversalMatElementCost(aSTM_STOCK_MOVEMENT_ID number, aMvtQty number)
  is
    aFAL_LOT_ID                 number;
    aFAL_LOT_MATERIAL_LINK_ID   number;
    aSMO_UNIT_PRICE             number;
    aSTM2_STM_STOCK_MOVEMENT_ID number;
    aSMO_MOVEMENT_PRICE         number;
    aSMO_MOVEMENT_QUANTITY      number;
  begin
    if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
      -- R�cup�ration des informations du mouvement d'origine
      select FEC.FAL_LOT_ID
           , FEC.FAL_LOT_MATERIAL_LINK_ID
           , SMO2.STM_STOCK_MOVEMENT_ID
           , SMO2.SMO_MOVEMENT_PRICE
           , SMO2.SMO_MOVEMENT_QUANTITY
        into aFAL_LOT_ID
           , aFAL_LOT_MATERIAL_LINK_ID
           , aSTM2_STM_STOCK_MOVEMENT_ID
           , aSMO_MOVEMENT_PRICE
           , aSMO_MOVEMENT_QUANTITY
        from FAL_ELEMENT_COST FEC
           , STM_STOCK_MOVEMENT SMO
           , STM_STOCK_MOVEMENT SMO2
       where FEC.C_COST_ELEMENT_TYPE = 'MAT'
         and SMO.STM_STOCK_MOVEMENT_ID = aSTM_STOCK_MOVEMENT_ID
         and SMO.STM_STOCK_MOVEMENT_ID = FEC.STM_STOCK_MOVEMENT_ID
         and SMO.STM2_STM_STOCK_MOVEMENT_ID = SMO2.STM_STOCK_MOVEMENT_ID;

      -- Insertion de l'�l�ment de co�t
      insert into FAL_ELEMENT_COST
                  (FAL_ELEMENT_COST_ID
                 , FAL_LOT_ID
                 , FAL_LOT_MATERIAL_LINK_ID
                 , C_COST_ELEMENT_TYPE
                 , FEC_CURRENT_AMOUNT
                 , FEC_COMPLETED_AMOUNT
                 , STM_STOCK_MOVEMENT_ID
                 , FEC_CURRENT_QUANTITY
                 , FEC_COMPLETED_QUANTITY
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aFAL_LOT_ID
                 , aFAL_LOT_MATERIAL_LINK_ID
                 , 'MAT'
                 , aSMO_MOVEMENT_PRICE
                 , 0
                 , aSTM2_STM_STOCK_MOVEMENT_ID
                 , aSMO_MOVEMENT_QUANTITY
                 , 0
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  );
    end if;
  exception
    when others then
      raise;
  end InsertReversalMatElementCost;

  /**
  * procedure   : InsertWorkElementCost
  * Description : G�n�ration des co�ts travail en cours
  *               et r�alis� pour un ordre de fabrication
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  * @param   aFAL_ACI_TIME_HIST_ID : ID historique descente d'heure
  */
  procedure InsertCurrentWorkElementCost(aFAL_ACI_TIME_HIST_ID number)
  is
    vTIH_WORK_TIME_MACH_QTY        number;
    vTIH_WORK_TIME_MACH_RATE       number;
    vTIH_WORK_TIME_OPER_QTY        number;
    vTIH_WORK_TIME_OPER_RATE       number;
    vTIH_ADJ_TIME_MACH_QTY         number;
    vTIH_ADJ_TIME_MACH_RATE        number;
    vTIH_ADJ_TIME_OPER_QTY         number;
    vTIH_ADJ_TIME_OPER_RATE        number;
    vTIH_WORK_TIME_MACH_ADD_AMOUNT number;
    vFAL_LOT_ID                    number;
    vFAL_SCHEDULE_STEP_ID          number;
    vAdjTimeOperAmount             number;
    vAdjTimeMachAmount             number;
    vWorkTimeOperAmount            number;
    vWorkTimeMachAmount            number;
  begin
    if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
      -- R�cup�ration des donn�es
      select nvl(TIH.TIH_WORK_TIME_MACH_QTY, 0)
           , nvl(TIH.TIH_WORK_TIME_MACH_RATE, 0)
           , nvl(TIH.TIH_WORK_TIME_OPER_QTY, 0)
           , nvl(TIH.TIH_WORK_TIME_OPER_RATE, 0)
           , nvl(TIH.TIH_ADJ_TIME_MACH_QTY, 0)
           , nvl(TIH.TIH_ADJ_TIME_MACH_RATE, 0)
           , nvl(TIH.TIH_ADJ_TIME_OPER_QTY, 0)
           , nvl(TIH.TIH_ADJ_TIME_OPER_RATE, 0)
           , nvl(TIH.TIH_WORK_TIME_MACH_ADD_AMOUNT, 0)
           , FLP.FAL_LOT_ID
           , FLP.FAL_SCHEDULE_STEP_ID
        into vTIH_WORK_TIME_MACH_QTY
           , vTIH_WORK_TIME_MACH_RATE
           , vTIH_WORK_TIME_OPER_QTY
           , vTIH_WORK_TIME_OPER_RATE
           , vTIH_ADJ_TIME_MACH_QTY
           , vTIH_ADJ_TIME_MACH_RATE
           , vTIH_ADJ_TIME_OPER_QTY
           , vTIH_ADJ_TIME_OPER_RATE
           , vTIH_WORK_TIME_MACH_ADD_AMOUNT
           , vFAL_LOT_ID
           , vFAL_SCHEDULE_STEP_ID
        from FAL_ACI_TIME_HIST TIH
           , FAL_LOT_PROGRESS FLP
           , FAL_TASK_LINK TAL
       where TIH.FAL_ACI_TIME_HIST_ID = aFAL_ACI_TIME_HIST_ID
         and FLP.FAL_ACI_TIME_HIST_ID = TIH.FAL_ACI_TIME_HIST_ID
         and FLP.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID
         and TAL.C_TASK_TYPE <> '2';

      -- Recalcul, car les montants de cette table sont arrondis � 2 d�cimales
      vAdjTimeOperAmount   := vTIH_ADJ_TIME_OPER_QTY * vTIH_ADJ_TIME_OPER_RATE;
      vAdjTimeMachAmount   := vTIH_ADJ_TIME_MACH_QTY * vTIH_ADJ_TIME_MACH_RATE;
      vWorkTimeOperAmount  := vTIH_WORK_TIME_OPER_QTY * vTIH_WORK_TIME_OPER_RATE;
      vWorkTimeMachAmount  := vTIH_WORK_TIME_MACH_ADD_AMOUNT +(vTIH_WORK_TIME_MACH_QTY * vTIH_WORK_TIME_MACH_RATE);

      -- Insertion des l'�l�ments de co�t correspondants
      if (vAdjTimeOperAmount + vAdjTimeMachAmount + vWorkTimeOperAmount + vWorkTimeMachAmount) <> 0 then
        -- Travail main d'oeuvre
        if (vAdjTimeOperAmount + vWorkTimeOperAmount) <> 0 then
          insert into FAL_ELEMENT_COST
                      (FAL_ELEMENT_COST_ID
                     , FAL_LOT_ID
                     , FAL_SCHEDULE_STEP_ID
                     , FAL_ACI_TIME_HIST_ID
                     , C_COST_ELEMENT_TYPE
                     , FEC_CURRENT_QUANTITY
                     , FEC_COMPLETED_QUANTITY
                     , FEC_CURRENT_AMOUNT
                     , FEC_COMPLETED_AMOUNT
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , vFAL_LOT_ID
                     , vFAL_SCHEDULE_STEP_ID
                     , aFAL_ACI_TIME_HIST_ID
                     , 'TMO'
                     , (vTIH_ADJ_TIME_OPER_QTY + vTIH_WORK_TIME_OPER_QTY)
                     , 0
                     , (vAdjTimeOperAmount + vWorkTimeOperAmount)
                     , 0
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;

        -- Travail Machine
        if (vAdjTimeMachAmount + vWorkTimeMachAmount) <> 0 then
          insert into FAL_ELEMENT_COST
                      (FAL_ELEMENT_COST_ID
                     , FAL_LOT_ID
                     , FAL_SCHEDULE_STEP_ID
                     , FAL_ACI_TIME_HIST_ID
                     , C_COST_ELEMENT_TYPE
                     , FEC_CURRENT_QUANTITY
                     , FEC_COMPLETED_QUANTITY
                     , FEC_CURRENT_AMOUNT
                     , FEC_COMPLETED_AMOUNT
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , vFAL_LOT_ID
                     , vFAL_SCHEDULE_STEP_ID
                     , aFAL_ACI_TIME_HIST_ID
                     , 'TMA'
                     , (vTIH_ADJ_TIME_MACH_QTY + vTIH_WORK_TIME_MACH_QTY)
                     , 0
                     , (vAdjTimeMachAmount + vWorkTimeMachAmount)
                     , 0
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;

        -- MAJ du Flag sur l'historique des temps remont�s en ACI, comme comptabilis�
        -- en en-cours
        update FAL_ACI_TIME_HIST
           set TIH_ENTERED_INTO_WIP = 1
         where FAL_ACI_TIME_HIST_ID = aFAL_ACI_TIME_HIST_ID;
      end if;
    end if;
  exception
    when no_data_found then
      null;
    when others then
      raise;
  end InsertCurrentWorkElementCost;

  /**
  * procedure   : InsertRealizedWorkElementCost
  * Description : G�n�ration des co�ts travail r�alis�
  *               pour les r�ception d'of
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  * @param   aFAL_LOT_ID : Lot de fabrication
  * @param   aRECEIPT_QTY : Quantit� r�ception
  * @param   aREJECT_RECEIPT_QTY : Quantit� r�ception rebut
  * @param   aDISMOUNTING_QTY : Quantit� d�mont�e
  */
  procedure InsertRealizedWorkElementCost(aFAL_LOT_ID number, aRECEIPT_QTY number, aREJECT_RECEIPT_QTY number, aDISMOUNTING_QTY number)
  is
    -- S�lection des �l�ments de co�t travail "en-cours", � reporter sur le r�alis�
    cursor crCurrentCost
    is
      select   sum(FEC.FEC_CURRENT_AMOUNT) FEC_CURRENT_AMOUNT
             , sum(FEC.FEC_CURRENT_QUANTITY) FEC_QUANTITY
             , nvl(LOT.LOT_INPROD_QTY, 0) + nvl(LOT_PT_REJECT_QTY, 0) + nvl(LOT_CPT_REJECT_QTY, 0) BATCH_REMAIN_QTY
             , FEC.FAL_SCHEDULE_STEP_ID
             , FEC.C_COST_ELEMENT_TYPE
          from FAL_ELEMENT_COST FEC
             , FAL_LOT LOT
         where FEC.FAL_LOT_ID = aFAL_LOT_ID
           and FEC.FAL_SCHEDULE_STEP_ID is not null
           and FEC.FAL_LOT_ID = LOT.FAL_LOT_ID
      group by FEC.FAL_SCHEDULE_STEP_ID
             , FEC.C_COST_ELEMENT_TYPE
             , nvl(LOT.LOT_INPROD_QTY, 0) + nvl(LOT_PT_REJECT_QTY, 0) + nvl(LOT_CPT_REJECT_QTY, 0);

    vFEC_COMPLETED_AMOUNT number;
    vRealizedQty          number;
    vReceiptQTY           number;
  begin
    if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
      -- Qt� de la r�ception (rebut, rebut PT, ou d�montage (RebutCPT) )
      vReceiptQTY  :=
        case
          when nvl(aRECEIPT_QTY, 0) <> 0 then aRECEIPT_QTY
          when nvl(aREJECT_RECEIPT_QTY, 0) <> 0 then aREJECT_RECEIPT_QTY
          when nvl(aDISMOUNTING_QTY, 0) <> 0 then aDISMOUNTING_QTY
          else 0
        end;

      if vReceiptQTY <> 0 then
        -- Pour chaque �l�ment de co�t Travail machine ou Travail main d'oeuvre.
        for tplCurrentCost in crCurrentCost loop
          -- Montant r�alis�
          if (tplCurrentCost.BATCH_REMAIN_QTY + vReceiptQTY) <> 0 then
            vFEC_COMPLETED_AMOUNT  := (tplCurrentCost.FEC_CURRENT_AMOUNT /(tplCurrentCost.BATCH_REMAIN_QTY + vReceiptQTY) ) * vReceiptQTY;
          else
            vFEC_COMPLETED_AMOUNT  := tplCurrentCost.FEC_CURRENT_AMOUNT;
          end if;

          -- Quantit� r�alis�e
          if (tplCurrentCost.BATCH_REMAIN_QTY + vReceiptQTY) <> 0 then
            vRealizedQty  := (tplCurrentCost.FEC_QUANTITY /(tplCurrentCost.BATCH_REMAIN_QTY + vReceiptQTY) ) * vReceiptQTY;
          else
            vRealizedQty  := tplCurrentCost.FEC_QUANTITY;
          end if;

          if    (vFEC_COMPLETED_AMOUNT <> 0)
             or (vRealizedQty <> 0) then
            insert into FAL_ELEMENT_COST
                        (FAL_ELEMENT_COST_ID
                       , FAL_LOT_ID
                       , FAL_SCHEDULE_STEP_ID
                       , C_COST_ELEMENT_TYPE
                       , FEC_CURRENT_AMOUNT
                       , FEC_COMPLETED_AMOUNT
                       , FEC_CURRENT_QUANTITY
                       , FEC_COMPLETED_QUANTITY
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (GetNewId
                       , aFAL_LOT_ID
                       , tplCurrentCost.FAL_SCHEDULE_STEP_ID
                       , tplCurrentCost.C_COST_ELEMENT_TYPE
                       , -vFEC_COMPLETED_AMOUNT
                       , vFEC_COMPLETED_AMOUNT
                       , -vRealizedQty
                       , vRealizedQty
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GETUSERINI
                        );
          end if;
        end loop;
      end if;
    end if;
  end InsertRealizedWorkElementCost;

  /**
  * procedure   : CheckCurrentEleCost
  * Description : Proc�dure ex�cut�e au solde de l'of qui v�rifie le respect des
  *               r�gles de gestion au solde de l'of, c-a-d tous les avancements
  *               on �t� remont�s en ACI ainsi que les documents li�s confirm�s.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_ID : Lot de fabrication
  * @param   aErrorMsg : Message d'erreur �ventuel
  */
  procedure CheckCurrentEleCost(aFAL_LOT_ID in number, aErrorMsg in out integer)
  is
    cursor crElementCost
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_COST_ELEMENT_TYPE
             , sum(nvl(FEC_CURRENT_AMOUNT, 0) ) FEC_CURRENT_AMOUNT
             , sum(nvl(FEC_CURRENT_QUANTITY, 0) ) FEC_CURRENT_QUANTITY
          from FAL_ELEMENT_COST
         where C_COST_ELEMENT_TYPE <> 'MAT'
           and FAL_LOT_ID = aFAL_LOT_ID
      group by FAL_SCHEDULE_STEP_ID
             , C_COST_ELEMENT_TYPE;

    NbProgress           integer;
    vAccountedQty        number;
    vTotalsubcontractQty number;
  begin
    if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
      -- Existe-t-il des avancements pour lesquels les �l�ments de co�ts n'ont pas
      -- encore �t� g�n�r�s?
      select count(*)
        into NbProgress
        from FAL_LOT_PROGRESS FLP
           , FAL_TASK_LINK TAL
       where FLP.FAL_LOT_ID = aFAL_LOT_ID
         and FLP.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID
         and FLP.FAL_ACI_TIME_HIST_ID is null
         and TAL.C_TASK_TYPE <> '2'
         and (   FLP.FLP_ADJUSTING_TIME <> 0
              or FLP.FLP_WORK_TIME <> 0
              or FLP.FLP_AMOUNT <> 0);

      if NbProgress > 0 then
        aErrorMsg  := FAL_BATCH_FUNCTIONS.rtErrBalanceCurrentEleCost;
        return;
      else
        aErrorMsg  := FAL_BATCH_FUNCTIONS.rtOkBalanceCurrentEleCost;
      end if;

      -- Manque t'il encore des �l�ments de co�ts � venir pour des op�rations de sous traitance
      -- avec des quantit�s en-cours. (Factures sous-traitances non-confirm�es).
      begin
        select nvl(FEC1.FEC_QTY, 0)
             , nvl(TAL1.TAL_QTY, 0)
          into vAccountedQty
             , vTotalsubcontractQty
          from (select nvl(sum(FEC.FEC_CURRENT_QUANTITY), 0) + nvl(sum(FEC.FEC_COMPLETED_QUANTITY), 0) FEC_QTY
                  from FAL_ELEMENT_COST FEC
                 where FEC.FAL_LOT_ID = aFAL_LOT_ID
                   and FEC.C_COST_ELEMENT_TYPE = 'SST') FEC1
             , (select sum(nvl(TAL.TAL_SUBCONTRACT_QTY, 0) + nvl(TAL.TAL_RELEASE_QTY, 0) ) TAL_QTY
                  from FAL_TASK_LINK TAL
                 where TAL.FAL_LOT_ID = aFAL_LOT_ID
                   and TAL.C_TASK_TYPE = '2'
                   and TAL.C_OPERATION_TYPE = '1'
                   and exists(select 1
                                from DOC_POSITION_DETAIL PDE
                               where PDE.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID) ) TAL1;
      exception
        when no_data_found then
          aErrorMsg  := FAL_BATCH_FUNCTIONS.rtOkUnConfirmedDoc;
      end;

      if vAccountedQty < vTotalsubcontractQty then
        aErrorMsg  := FAL_BATCH_FUNCTIONS.rtErrUnConfirmedDoc;
        return;
      else
        aErrorMsg  := FAL_BATCH_FUNCTIONS.rtOkUnConfirmedDoc;
      end if;
    else
      aErrorMsg  := null;
    end if;
  end CheckCurrentEleCost;

  /**
  * procedure   : BalanceCurrentEleCost
  * Description : Proc�dure ex�cut�e au solde de l'of qui effectue le
  *               report sur le r�alis� des �l�ments de co�ts travails restants
  *               �ventuellement. (Remont�s en ACI depuis la derni�re r�ception).
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_ID : Lot de fabrication
  */
  procedure BalanceCurrentEleCost(aFAL_LOT_ID in number)
  is
    cursor crElementCost
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_COST_ELEMENT_TYPE
             , sum(nvl(FEC_CURRENT_AMOUNT, 0) ) FEC_CURRENT_AMOUNT
             , sum(nvl(FEC_CURRENT_QUANTITY, 0) ) FEC_CURRENT_QUANTITY
          from FAL_ELEMENT_COST
         where C_COST_ELEMENT_TYPE <> 'MAT'
           and FAL_LOT_ID = aFAL_LOT_ID
      group by FAL_SCHEDULE_STEP_ID
             , C_COST_ELEMENT_TYPE;
  begin
    if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
      -- Mise � jour du r�alis� avec les �ventuels nouveaux co�ts travail en-cours
      -- apparuts depuis la derni�re r�ception
      for tplElementCost in crElementCost loop
        if nvl(tplElementCost.FEC_CURRENT_AMOUNT, 0) > 0 then
          insert into FAL_ELEMENT_COST
                      (FAL_ELEMENT_COST_ID
                     , FAL_LOT_ID
                     , FAL_SCHEDULE_STEP_ID
                     , C_COST_ELEMENT_TYPE
                     , FEC_CURRENT_AMOUNT
                     , FEC_COMPLETED_AMOUNT
                     , FEC_CURRENT_QUANTITY
                     , FEC_COMPLETED_QUANTITY
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , aFAL_LOT_ID
                     , tplElementCost.FAL_SCHEDULE_STEP_ID
                     , tplElementCost.C_COST_ELEMENT_TYPE
                     , -tplElementCost.FEC_CURRENT_AMOUNT
                     , tplElementCost.FEC_CURRENT_AMOUNT
                     , -tplElementCost.FEC_CURRENT_QUANTITY
                     , tplElementCost.FEC_CURRENT_QUANTITY
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GETUSERINI
                      );
        end if;
      end loop;
    end if;
  end BalanceCurrentEleCost;

  /**
  * procedure   : InsertCurrentSubctrctEleCost
  * Description : G�n�ration des co�ts travail en cours
  *               et r�alis� pour la sous traitance
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_ID : Lot de fabrication
  * @param   aFAL_SCHEDULE_STEP_ID : Op�ration
  * @param   aAmount : Montant
  */
  procedure InsertCurrentSubctrctEleCost(aFAL_LOT_ID number, aFAL_SCHEDULE_STEP_ID number, aSTM_STOCK_MOVEMENT_ID number, aAmount number, aQty number)
  is
  begin
    if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
      if nvl(aAmount, 0) <> 0 then
        insert into FAL_ELEMENT_COST
                    (FAL_ELEMENT_COST_ID
                   , FAL_LOT_ID
                   , FAL_SCHEDULE_STEP_ID
                   , STM_STOCK_MOVEMENT_ID
                   , C_COST_ELEMENT_TYPE
                   , FEC_CURRENT_QUANTITY
                   , FEC_COMPLETED_QUANTITY
                   , FEC_CURRENT_AMOUNT
                   , FEC_COMPLETED_AMOUNT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , aFAL_LOT_ID
                   , aFAL_SCHEDULE_STEP_ID
                   , aSTM_STOCK_MOVEMENT_ID
                   , 'SST'
                   , aQty
                   , 0
                   , aAmount
                   , 0
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    end if;
  end InsertCurrentSubctrctEleCost;

  /**
  * function   : ExistsInPRF
  * Description : Teste l'existance des diff�rents �l�ments du calcul dans un PRF
  *               Compta indus existant, "actif" "futur" ou "r�el"
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_SCHEDULE_PLAN_ID : Gamme op�ratoire
  * @param   aPPS_NOMENCLATURE_ID : Nomenclature
  * @param   aFAL_ADV_STRUCT_CALC_ID : Structure de calcul
  * @param   aGCO_COMPL_DATA_MANUFACTURE : Donn�e compl�mentaire de fabrication
  * @param   aGCO_COMPL_DATA_PURCHASE : Donn�e compl�mentaire d'achat
  * @param   aGCO_COMPL_DATA_SUBCONTRACT_ID : Donn�e compl�mentaire de sous-traitance
  */
  function ExistsInPRF(
    aFAL_SCHEDULE_PLAN_ID          number default null
  , aPPS_NOMENCLATURE_ID           number default null
  , aFAL_ADV_STRUCT_CALC_ID        number default null
  , aGCO_COMPL_DATA_MANUFACTURE_ID number default null
  , aGCO_COMPL_DATA_PURCHASE_ID    number default null
  , aGCO_COMPL_DATA_SUBCONTRACT_ID number default null
  )
    return integer
  is
    aresult integer;
  begin
    if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
      if     nvl(aFAL_SCHEDULE_PLAN_ID, 0) = 0
         and nvl(aPPS_NOMENCLATURE_ID, 0) = 0
         and nvl(aFAL_ADV_STRUCT_CALC_ID, 0) = 0
         and nvl(aGCO_COMPL_DATA_MANUFACTURE_ID, 0) = 0
         and nvl(aGCO_COMPL_DATA_PURCHASE_ID, 0) = 0
         and nvl(aGCO_COMPL_DATA_SUBCONTRACT_ID, 0) = 0 then
        return 0;
      else
        select count(*)
          into aresult
          from PTC_FIXED_COSTPRICE PTC
         where C_COSTPRICE_STATUS in('ACT', 'FUT', 'REE')
           and CPR_MANUFACTURE_ACCOUNTING = 1
           and (   nvl(aFAL_SCHEDULE_PLAN_ID, 0) = 0
                or PTC.FAL_SCHEDULE_PLAN_ID = aFAL_SCHEDULE_PLAN_ID)
           and (   nvl(aPPS_NOMENCLATURE_ID, 0) = 0
                or PTC.PPS_NOMENCLATURE_ID = aPPS_NOMENCLATURE_ID)
           and (   nvl(aFAL_ADV_STRUCT_CALC_ID, 0) = 0
                or PTC.FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID)
           and (   nvl(aGCO_COMPL_DATA_MANUFACTURE_ID, 0) = 0
                or PTC.GCO_COMPL_DATA_MANUFACTURE_ID = aGCO_COMPL_DATA_MANUFACTURE_ID)
           and (   nvl(aGCO_COMPL_DATA_PURCHASE_ID, 0) = 0
                or PTC.GCO_COMPL_DATA_PURCHASE_ID = aGCO_COMPL_DATA_PURCHASE_ID)
           and (   nvl(aGCO_COMPL_DATA_SUBCONTRACT_ID, 0) = 0
                or PTC.GCO_COMPL_DATA_SUBCONTRACT_ID = aGCO_COMPL_DATA_SUBCONTRACT_ID);

        return aresult;
      end if;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end;

  /**
  * procedure   : UpdateBatchPRFCI
  * Description : Mise � jour du PRFCI sur un lot de fabrication (� son lancement)
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iFalLotId   Lot de fabrication
  */
  procedure UpdateBatchPRFCI(iFalLotId in number)
  is
  begin
    update FAL_LOT
       set PTC_FIXED_COSTPRICE_ID = PTC_FUNCTIONS.GetAccountingFixedCostprice(GCO_GOOD_ID)
     where FAL_LOT_ID = iFalLotId;
  end UpdateBatchPRFCI;
end;
