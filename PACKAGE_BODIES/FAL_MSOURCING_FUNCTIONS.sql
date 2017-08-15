--------------------------------------------------------
--  DDL for Package Body FAL_MSOURCING_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_MSOURCING_FUNCTIONS" 
is
  /**
  * Function IsProductWithMultiSourcing
  * Description : indique si le produit est géré en multisourcing
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param iGcoGoodId : Produit
  * @return integer
  */
  function IsProductWithMultiSourcing(iGcoGoodId number)
    return integer
  is
    result integer;
  begin
    select nvl(PDT.PDT_MULTI_SOURCING, 0)
      into result
      from GCO_PRODUCT PDT
     where PDT.GCO_GOOD_ID = iGcoGoodId;

    return result;
  exception
    when others then
      return 0;
  end;

  /**
  * Function CalcRealized :  Fonction qui permet de recalculer les pourcentages de multi-sourcing
  *                          pour un produit donné, pour l'ensemble de ses fournisseurs.
  *
  */
  procedure CalcRealized(aSTM_EXERCISE_ID in STM_EXERCISE.STM_EXERCISE_ID%type, aGCO_GOOD_ID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    nSumBaseAmount number;
    nSumQuantity   number;
  begin
    begin
      select sum(FMS2.FMS_BASE_AMOUNT)
        into nSumBaseAmount
        from FAL_MULTI_SOURCING FMS2
       where FMS2.STM_EXERCISE_ID = aSTM_EXERCISE_ID
         and FMS2.GCO_GOOD_ID = aGCO_GOOD_ID;
    exception
      when others then
        begin
          nSumBaseAmount  := 0;
        end;
    end;

    begin
      select sum(FMS3.FMS_QUANTITY)
        into nSumQuantity
        from FAL_MULTI_SOURCING FMS3
       where FMS3.STM_EXERCISE_ID = aSTM_EXERCISE_ID
         and FMS3.GCO_GOOD_ID = aGCO_GOOD_ID;
    exception
      when others then
        nSumQuantity  := 0;
    end;

    update FAL_MULTI_SOURCING FMS
       set FMS.FMS_AMOUNT_PERCENT = decode(nSumBaseAmount, 0, 100,(FMS.FMS_BASE_AMOUNT / nSumBaseAmount * 100) )
         , FMS.FMS_QUANTITY_PERCENT = decode(nSumQuantity, 0, 100,(FMS.FMS_QUANTITY / nSumQuantity * 100) )
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where FMS.STM_EXERCISE_ID = aSTM_EXERCISE_ID
       and FMS.GCO_GOOD_ID = aGCO_GOOD_ID;
  end CalcRealized;

  /**
  * Function CreateFAL_MULTI_SOURCING : Création d'un enregistrement de Multi Sourcing
  *
  */
  procedure CreateFAL_MULTI_SOURCING(
    aSTM_EXERCISE_ID         in STM_EXERCISE.STM_EXERCISE_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aGCO_GOOD_ID             in GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID         in GCO_GOOD.GCO_GOOD_ID%type
  , aQuantity                in number
  , aAmount                  in number
  )
  is
    nFMS_AMOUNT_PERCENT   number;
    nFMS_QUANTITY_PERCENT number;
  begin
    -- Insertion de l'enregistrement
    insert into FAL_MULTI_SOURCING
                (FAL_MULTI_SOURCING_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , PAC_SUPPLIER_PARTNER_ID
               , STM_EXERCISE_ID
               , FMS_BASE_AMOUNT
               , FMS_QUANTITY
               , FMS_AMOUNT_PERCENT
               , FMS_QUANTITY_PERCENT
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , aGCO_GOOD_ID
               , aGCO_GCO_GOOD_ID
               , aPAC_SUPPLIER_PARTNER_ID
               , aSTM_EXERCISE_ID
               , aAmount
               , aQuantity
               , 0
               , 0
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    CalcRealized(aSTM_EXERCISE_ID, aGCO_GOOD_ID);
  end CreateFAL_MULTI_SOURCING;

  /**
  * Function UpdateFAL_MULTI_SOURCING : MAJ d'un enregistrement de Multi Sourcing
  *
  */
  procedure UpdateFAL_MULTI_SOURCING(
    aSTM_EXERCISE_ID       in STM_EXERCISE.STM_EXERCISE_ID%type
  , aGCO_GOOD_ID           in GCO_GOOD.GCO_GOOD_ID%type
  , aFAL_MULTI_SOURCING_ID    FAL_MULTI_SOURCING.FAL_MULTI_SOURCING_ID%type
  , aQuantity              in number
  , aAmount                in number
  )
  is
    nFMS_AMOUNT_PERCENT   number;
    nFMS_QUANTITY_PERCENT number;
  begin
    -- MAJ de l'enregistrement
    update FAL_MULTI_SOURCING FMS
       set FMS.FMS_BASE_AMOUNT = FMS.FMS_BASE_AMOUNT + aAmount
         , FMS.FMS_QUANTITY = FMS.FMS_QUANTITY + aQuantity
     where FMS.FAL_MULTI_SOURCING_ID = aFAL_MULTI_SOURCING_ID;

    -- Calcul du réalisé
    CalcRealized(aSTM_EXERCISE_ID, aGCO_GOOD_ID);
  end UpdateFAL_MULTI_SOURCING;

  /**
  * Function IsMultiSourcingDocument : Indique si le document est en multi-Sourcing
  *          (Gabarit.GAS_MSOURCING_MGM = 1)
  */
  function IsMultiSourcingDocument(aDOC_DOCUMENT_ID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    ntmpDOC_DOCUMENT_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select DOC_DOCUMENT_ID
      into ntmpDOC_DOCUMENT_ID
      from DOC_DOCUMENT DOC
         , DOC_GAUGE_STRUCTURED GAS
     where DOC.DOC_DOCUMENT_ID = aDOC_DOCUMENT_ID
       and DOC.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and GAS.GAS_MULTISOURCING_MGM = 1;

    return true;
  exception
    when no_data_found then
      return false;
  end IsMultiSourcingDocument;

  /**
  * Function GetMultiSourcingID : Renvoie l'ID d'un enregistrement de multisourcing
  *          correspondant aux paramètres passés, et 0 si inexistant
  */
  function GetMultiSourcingID(
    aSTM_EXERCISE_ID         in STM_EXERCISE.STM_EXERCISE_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aGCO_GOOD_ID             in GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID         in GCO_GOOD.GCO_GOOD_ID%type
  )
    return FAL_MULTI_SOURCING.FAL_MULTI_SOURCING_ID%type
  is
    nFAL_MULTI_SOURCING_ID FAL_MULTI_SOURCING.FAL_MULTI_SOURCING_ID%type;
  begin
    select FMS.FAL_MULTI_SOURCING_ID
      into nFAL_MULTI_SOURCING_ID
      from FAL_MULTI_SOURCING FMS
     where FMS.STM_EXERCISE_ID = aSTM_EXERCISE_ID
       and FMS.PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID
       and FMS.GCO_GOOD_ID = aGCO_GOOD_ID
       and (    (    aGCO_GCO_GOOD_ID is null
                 and FMS.GCO_GCO_GOOD_ID is null)
            or (    aGCO_GCO_GOOD_ID is not null
                and FMS.GCO_GCO_GOOD_ID = aGCO_GCO_GOOD_ID) );

    return nFAL_MULTI_SOURCING_ID;
  exception
    when no_data_found then
      return 0;
  end GetMultiSourcingID;

  /**
  * procedure UpdateMultiSourcingRealized
  */
  procedure UpdateMultiSourcingRealized(
    aDOC_DOCUMENT_ID     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDOC_POS_GCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type
  , aNewGCO_GCO_GOOD_ID  GCO_GOOD.GCO_GOOD_ID%type
  , aOldGCO_GCO_GOOD_ID  GCO_GOOD.GCO_GOOD_ID%type
  , aNewPDE_QTY          number
  , aOldPDE_QTY          number
  , aNewPosUnitAmountQty number
  , aOldPosUnitAmountQty number
  )
  is
    nSTM_EXERCISE_ID       STM_EXERCISE.STM_EXERCISE_ID%type;
    nPAC_THIRD_ID          DOC_DOCUMENT.PAC_THIRD_ID%type;
    nFAL_MULTI_SOURCING_ID FAL_MULTI_SOURCING.FAL_MULTI_SOURCING_ID%type;
  begin
    -- Récupération de l'exercice
    begin
      select nvl(STM_FUNCTIONS.GetExerciseId(DOC.DMT_DATE_VALUE), 0)
           , DOC.PAC_THIRD_ID
        into nSTM_EXERCISE_ID
           , nPAC_THIRD_ID
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED DGS
       where DOC.DOC_DOCUMENT_ID = aDOC_DOCUMENT_ID
         and DOC.DOC_GAUGE_ID = DGS.DOC_GAUGE_ID
         and DGS.GAS_MULTISOURCING_MGM = 1;
    exception
      when others then
        begin
          nSTM_EXERCISE_ID  := 0;
          nPAC_THIRD_ID     := 0;
        end;
    end;

    -- Si exercice du document trouvé
    if nSTM_EXERCISE_ID <> 0 then
      -- aNewGCO_GCO_GOOD_ID = NULL
      if aNewGCO_GCO_GOOD_ID is null then
        -- aNewGCO_GCO_GOOD_ID = NULL / aOldGCO_GCO_GOOD_ID = NULL
        if aOldGCO_GCO_GOOD_ID is null then
          nFAL_MULTI_SOURCING_ID  := GetMultiSourcingID(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aDOC_POS_GCO_GOOD_ID, null);

          if nFAL_MULTI_SOURCING_ID = 0 then
            CreateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aDOC_POS_GCO_GOOD_ID, null, aNewPDE_QTY, aNewPDE_QTY * aNewPosUnitAmountQty);
          else
            UpdateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID
                                   , aDOC_POS_GCO_GOOD_ID
                                   , nFAL_MULTI_SOURCING_ID
                                   , aNewPDE_QTY - aOldPDE_QTY
                                   , (aNewPDE_QTY * aNewPosUnitAmountQty) -(aOldPDE_QTY * aOldPosUnitAmountQty)
                                    );
          end if;
        else
          nFAL_MULTI_SOURCING_ID  := GetMultiSourcingID(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aOldGCO_GCO_GOOD_ID, aDOC_POS_GCO_GOOD_ID);

          if nFAL_MULTI_SOURCING_ID = 0 then
            nFAL_MULTI_SOURCING_ID  := GetMultiSourcingID(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aDOC_POS_GCO_GOOD_ID, null);

            if nFAL_MULTI_SOURCING_ID = 0 then
              CreateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aDOC_POS_GCO_GOOD_ID, null, aNewPDE_QTY, aNewPDE_QTY * aNewPosUnitAmountQty);
            else
              UpdateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID, aDOC_POS_GCO_GOOD_ID, nFAL_MULTI_SOURCING_ID, aNewPDE_QTY, aNewPDE_QTY * aNewPosUnitAmountQty);
            end if;
          else
            UpdateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID, aOldGCO_GCO_GOOD_ID, nFAL_MULTI_SOURCING_ID, -aOldPDE_QTY, -(aOldPDE_QTY * aOldPosUnitAmountQty) );
          end if;
        end if;   -- Fin if aOldGCO_GCO_GOOD_ID = NULL
      else
        if    (aOldGCO_GCO_GOOD_ID is null)
           or (aOldGCO_GCO_GOOD_ID <> aNewGCO_GCO_GOOD_ID) then
          if aOldGCO_GCO_GOOD_ID is null then
            nFAL_MULTI_SOURCING_ID  := GetMultiSourcingID(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aDOC_POS_GCO_GOOD_ID, null);

            if nFAL_MULTI_SOURCING_ID <> 0 then
              UpdateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID, aDOC_POS_GCO_GOOD_ID, nFAL_MULTI_SOURCING_ID, -aOldPDE_QTY, -(aOldPDE_QTY * aOldPosUnitAmountQty) );
            end if;
          else
            nFAL_MULTI_SOURCING_ID  := GetMultiSourcingID(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aOldGCO_GCO_GOOD_ID, aDOC_POS_GCO_GOOD_ID);

            if nFAL_MULTI_SOURCING_ID <> 0 then
              UpdateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID, aOldGCO_GCO_GOOD_ID, nFAL_MULTI_SOURCING_ID, -aOldPDE_QTY, -(aOldPDE_QTY * aOldPosUnitAmountQty) );
            end if;
          end if;

          nFAL_MULTI_SOURCING_ID  := GetMultiSourcingID(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aNewGCO_GCO_GOOD_ID, aDOC_POS_GCO_GOOD_ID);

          if nFAL_MULTI_SOURCING_ID = 0 then
            CreateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID
                                   , nPAC_THIRD_ID
                                   , aNewGCO_GCO_GOOD_ID
                                   , aDOC_POS_GCO_GOOD_ID
                                   , aNewPDE_QTY
                                   , aNewPDE_QTY * aNewPosUnitAmountQty
                                    );
          else
            UpdateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID, aNewGCO_GCO_GOOD_ID, nFAL_MULTI_SOURCING_ID, aNewPDE_QTY,(aNewPDE_QTY * aNewPosUnitAmountQty) );
          end if;
        else
          nFAL_MULTI_SOURCING_ID  := GetMultiSourcingID(nSTM_EXERCISE_ID, nPAC_THIRD_ID, aOldGCO_GCO_GOOD_ID, aDOC_POS_GCO_GOOD_ID);

          if nFAL_MULTI_SOURCING_ID = 0 then
            CreateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID
                                   , nPAC_THIRD_ID
                                   , aOldGCO_GCO_GOOD_ID
                                   , aDOC_POS_GCO_GOOD_ID
                                   , aNewPDE_QTY
                                   , aNewPDE_QTY * aNewPosUnitAmountQty
                                    );
          else
            UpdateFAL_MULTI_SOURCING(nSTM_EXERCISE_ID
                                   , aNewGCO_GCO_GOOD_ID
                                   , nFAL_MULTI_SOURCING_ID
                                   , aNewPDE_QTY - aOldPDE_QTY
                                   , (aNewPDE_QTY * aNewPosUnitAmountQty) -(aOldPDE_QTY * aOldPosUnitAmountQty)
                                    );
          end if;
        end if;
      end if;   -- Fin if aNewGCO_GCO_GOOD_ID = NULL
    end if;   -- Fin if nSTM_EXERCISE_ID <> 0
  end UpdateMultiSourcingRealized;

  /**
  * procedure GetMultiSourcingDCA
  */
  procedure GetMultiSourcingDCA(
    aGCO_GOOD_ID                in     GCO_GOOD.GCO_GOOD_ID%type
  , aSTM_EXERCISE_ID            in     STM_EXERCISE.STM_EXERCISE_ID%type
  , aGCO_GCO_GOOD_ID            in out GCO_GOOD.GCO_GOOD_ID%type
  , aPAC_SUPPLIER_PARTNER_ID    in out PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aGCO_COMPL_DATA_PURCHASE_ID in out GCO_COMPL_DATA_PURCHASE.GCO_COMPL_DATA_PURCHASE_ID%type
  )
  is
    cursor CUR_CPU_SELECTION(cSTM_EXERCISE_ID STM_EXERCISE.STM_EXERCISE_ID%type)
    is
      select   decode(PCS.PC_CONFIG.GETCONFIG('FAL_SOURCING_RULE')
                    , 1,(nvl(THEORICAL.CPU_PERCENT_SOURCING, 0) - nvl(REALIZED.FMS_AMOUNT_PERCENT, 0) )
                    , 2,(nvl(THEORICAL.CPU_PERCENT_SOURCING, 0) - nvl(REALIZED.FMS_QUANTITY_PERCENT, 0) )
                    , (nvl(THEORICAL.CPU_PERCENT_SOURCING, 0) - nvl(REALIZED.FMS_AMOUNT_PERCENT, 0) )
                     ) DIFFERENCE
             , THEORICAL.GCO_COMPL_DATA_PURCHASE_ID
             , THEORICAL.PAC_SUPPLIER_PARTNER_ID
             , THEORICAL.GCO_GCO_GOOD_ID
          from (select nvl(FMS.FMS_AMOUNT_PERCENT, 0) FMS_AMOUNT_PERCENT
                     , nvl(FMS.FMS_QUANTITY_PERCENT, 0) FMS_QUANTITY_PERCENT
                     , FMS.PAC_SUPPLIER_PARTNER_ID
                     , FMS.GCO_GCO_GOOD_ID
                  from FAL_MULTI_SOURCING FMS
                 where FMS.GCO_GOOD_ID = aGCO_GOOD_ID
                   and FMS.STM_EXERCISE_ID = cSTM_EXERCISE_ID) REALIZED
             , (select nvl(CPU_PERCENT_SOURCING, 0) CPU_PERCENT_SOURCING
                     , CPU.PAC_SUPPLIER_PARTNER_ID
                     , CPU.GCO_COMPL_DATA_PURCHASE_ID
                     , CPU.GCO_GCO_GOOD_ID
                     , CPU.CPU_DEFAULT_SUPPLIER
                  from GCO_COMPL_DATA_PURCHASE CPU
                 where CPU.GCO_GOOD_ID = aGCO_GOOD_ID) THEORICAL
         where THEORICAL.PAC_SUPPLIER_PARTNER_ID = REALIZED.PAC_SUPPLIER_PARTNER_ID(+)
           and (    (    THEORICAL.GCO_GCO_GOOD_ID is null
                     and REALIZED.GCO_GCO_GOOD_ID is null)
                or (    THEORICAL.GCO_GCO_GOOD_ID is not null
                    and THEORICAL.GCO_GCO_GOOD_ID = REALIZED.GCO_GCO_GOOD_ID)
               )
      order by decode(PCS.PC_CONFIG.GETCONFIG('FAL_SOURCING_RULE')
                    , 1,(nvl(THEORICAL.CPU_PERCENT_SOURCING, 0) - nvl(REALIZED.FMS_AMOUNT_PERCENT, 0) )
                    , 2,(nvl(THEORICAL.CPU_PERCENT_SOURCING, 0) - nvl(REALIZED.FMS_QUANTITY_PERCENT, 0) )
                    , (nvl(THEORICAL.CPU_PERCENT_SOURCING, 0) - nvl(REALIZED.FMS_AMOUNT_PERCENT, 0) )
                     ) desc
             , THEORICAL.CPU_DEFAULT_SUPPLIER desc;

    CurCpuSelection  CUR_CPU_SELECTION%rowtype;
    nResult          GCO_COMPL_DATA_PURCHASE.GCO_COMPL_DATA_PURCHASE_ID%type;
    nSTM_EXERCISE_ID STM_EXERCISE.STM_EXERCISE_ID%type;
  begin
    -- Récupération de l'exercice en cours
    if aSTM_EXERCISE_ID = 0 then
      begin
        nSTM_EXERCISE_ID  := STM_FUNCTIONS.getActiveExercise;
      exception
        when others then
          raise_application_error(-20300, 'PCS - Active exercise not founded!');
      end;
    else
      nSTM_EXERCISE_ID  := aSTM_EXERCISE_ID;
    end if;

    -- Choix de la DCA
    open CUR_CPU_SELECTION(nSTM_EXERCISE_ID);

    fetch CUR_CPU_SELECTION
     into CurCpuSelection;

    if CUR_CPU_SELECTION%notfound then
      aGCO_GCO_GOOD_ID             := 0;
      aPAC_SUPPLIER_PARTNER_ID     := 0;
      aGCO_COMPL_DATA_PURCHASE_ID  := 0;
    else
      aGCO_GCO_GOOD_ID             := CurCpuSelection.GCO_GCO_GOOD_ID;
      aPAC_SUPPLIER_PARTNER_ID     := CurCpuSelection.PAC_SUPPLIER_PARTNER_ID;
      aGCO_COMPL_DATA_PURCHASE_ID  := CurCpuSelection.GCO_COMPL_DATA_PURCHASE_ID;
    end if;

    close CUR_CPU_SELECTION;
  end GetMultiSourcingDCA;
end FAL_MSOURCING_FUNCTIONS;
