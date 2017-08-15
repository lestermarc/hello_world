--------------------------------------------------------
--  DDL for Package Body DOC_PRC_PARITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_PARITY" 
is
  /**
  * Description
  *    remise à jour des quantités provisoires en stock
  */
  procedure RestoreProvQty(iCommit in boolean := false)
  is
    cursor positionToUpdate
    is
      select *
        from V_DOC_COMPARE_PROV;

    positionToUpdate_tuple positionToUpdate%rowtype;
    stockId                STM_STOCK.STM_STOCK_ID%type;
    lError                 boolean                       := false;
  begin
    open positionToUpdate;

    fetch positionToUpdate
     into positionToUpdate_tuple;

    while positionToUpdate%found loop
      begin
        if positionToUpdate_tuple.Action = 'I' then
          select STM_STOCK_ID
            into stockId
            from STM_LOCATION
           where STM_LOCATION_ID = positionToUpdate_tuple.STM_LOCATION_ID;

          insert into stm_stock_position
                      (STM_STOCK_POSITION_ID
                     , C_POSITION_STATUS
                     , SPO_STOCK_QUANTITY
                     , SPO_ASSIGN_QUANTITY
                     , SPO_PROVISORY_INPUT
                     , SPO_PROVISORY_OUTPUT
                     , SPO_AVAILABLE_QUANTITY
                     , SPO_THEORETICAL_QUANTITY
                     , SPO_ALTERNATIV_QUANTITY_1
                     , SPO_ALTERNATIV_QUANTITY_2
                     , SPO_ALTERNATIV_QUANTITY_3
                     , GCO_GOOD_ID
                     , STM_LOCATION_ID
                     , STM_STOCK_ID
                     , SPO_CHARACTERIZATION_VALUE_1
                     , SPO_CHARACTERIZATION_VALUE_2
                     , SPO_CHARACTERIZATION_VALUE_3
                     , SPO_CHARACTERIZATION_VALUE_4
                     , SPO_CHARACTERIZATION_VALUE_5
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , A_DATECRE
                     , A_IDCRE
                     , A_RECSTATUS
                      )
               values (init_id_seq.nextval
                     , '01'
                     , 0
                     , 0
                     , positionToUpdate_tuple.SPR_PROVISORY_INPUT
                     , positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
                     , -positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
                     , positionToUpdate_tuple.SPR_PROVISORY_INPUT - positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
                     , 0
                     , 0
                     , 0
                     , positionToUpdate_tuple.GCO_GOOD_ID
                     , positionToUpdate_tuple.STM_LOCATION_ID
                     , stockId
                     , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_1
                     , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_2
                     , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_3
                     , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_4
                     , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_5
                     , positionToUpdate_tuple.GCO_CHARACTERIZATION_ID
                     , positionToUpdate_tuple.GCO_GCO_CHARACTERIZATION_ID
                     , positionToUpdate_tuple.GCO2_GCO_CHARACTERIZATION_ID
                     , positionToUpdate_tuple.GCO3_GCO_CHARACTERIZATION_ID
                     , positionToUpdate_tuple.GCO4_GCO_CHARACTERIZATION_ID
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni2
                     , '7'
                      );
        elsif positionToUpdate_tuple.Action in('U', 'D') then
          -- mise à jour des compteurs avec les qté provisoires corrigées
          update stm_stock_position
             set SPO_PROVISORY_INPUT = positionToUpdate_tuple.SPR_PROVISORY_INPUT
               , SPO_PROVISORY_OUTPUT = positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
               , SPO_AVAILABLE_QUANTITY = SPO_STOCK_QUANTITY - SPO_ASSIGN_QUANTITY - positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
               , SPO_THEORETICAL_QUANTITY =
                             SPO_STOCK_QUANTITY - SPO_ASSIGN_QUANTITY - positionToUpdate_tuple.SPR_PROVISORY_OUTPUT + positionToUpdate_tuple.SPR_PROVISORY_INPUT
               , A_RECSTATUS = '7'
           where GCO_GOOD_ID = positionToUpdate_tuple.GCO_GOOD_ID
             and STM_LOCATION_ID = positionToUpdate_tuple.STM_LOCATION_ID
             and nvl(SPO_CHARACTERIZATION_VALUE_1, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_1, 0)
             and nvl(SPO_CHARACTERIZATION_VALUE_2, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_2, 0)
             and nvl(SPO_CHARACTERIZATION_VALUE_3, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_3, 0)
             and nvl(SPO_CHARACTERIZATION_VALUE_4, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_4, 0)
             and nvl(SPO_CHARACTERIZATION_VALUE_5, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_5, 0)
             and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_CHARACTERIZATION_ID, 0)
             and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_GCO_CHARACTERIZATION_ID, 0)
             and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO2_GCO_CHARACTERIZATION_ID, 0)
             and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO3_GCO_CHARACTERIZATION_ID, 0)
             and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO4_GCO_CHARACTERIZATION_ID, 0);

          -- eventuellement effacement de la position si elle est à 0
          if positionToUpdate_tuple.Action = 'D' then
            delete from STM_STOCK_POSITION
                  where GCO_GOOD_ID = positionToUpdate_tuple.GCO_GOOD_ID
                    and STM_LOCATION_ID = positionToUpdate_tuple.STM_LOCATION_ID
                    and nvl(SPO_CHARACTERIZATION_VALUE_1, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_1, 0)
                    and nvl(SPO_CHARACTERIZATION_VALUE_2, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_2, 0)
                    and nvl(SPO_CHARACTERIZATION_VALUE_3, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_3, 0)
                    and nvl(SPO_CHARACTERIZATION_VALUE_4, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_4, 0)
                    and nvl(SPO_CHARACTERIZATION_VALUE_5, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_5, 0)
                    and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_CHARACTERIZATION_ID, 0)
                    and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_GCO_CHARACTERIZATION_ID, 0)
                    and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO2_GCO_CHARACTERIZATION_ID, 0)
                    and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO3_GCO_CHARACTERIZATION_ID, 0)
                    and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO4_GCO_CHARACTERIZATION_ID, 0)
                    and SPO_STOCK_QUANTITY = 0
                    and SPO_ASSIGN_QUANTITY = 0
                    and SPO_PROVISORY_OUTPUT = 0
                    and SPO_PROVISORY_INPUT = 0
                    and SPO_AVAILABLE_QUANTITY = 0;
          end if;
        end if;
      exception
        when others then
          if iCommit then
            lError  := true;
          else
            raise;
          end if;
      end;

      fetch positionToUpdate
       into positionToUpdate_tuple;
    end loop;

    close positionToUpdate;

    if iCommit then
      commit;
    end if;

    if lError then
      ra('PCS - Some errors encountered during the process! Not all problems resolved');
    end if;
  end RestoreProvQty;

  /**
  * Description
  *    remise à jour des quantités provisoires en stock pour un bien
  */
  procedure RestoreProvQtyGood(iGoodId in number)
  is
    cursor positionToUpdate(cGoodID number)
    is
      select *
        from V_DOC_COMPARE_PROV
       where GCO_GOOD_ID = cGoodId;

    positionToUpdate_tuple positionToUpdate%rowtype;
    stockId                STM_STOCK.STM_STOCK_ID%type;
  begin
    open positionToUpdate(iGoodId);

    fetch positionToUpdate
     into positionToUpdate_tuple;

    while positionToUpdate%found loop
      if positionToUpdate_tuple.Action = 'I' then
        select STM_STOCK_ID
          into stockId
          from STM_LOCATION
         where STM_LOCATION_ID = positionToUpdate_tuple.STM_LOCATION_ID;

        insert into stm_stock_position
                    (STM_STOCK_POSITION_ID
                   , C_POSITION_STATUS
                   , SPO_STOCK_QUANTITY
                   , SPO_ASSIGN_QUANTITY
                   , SPO_PROVISORY_INPUT
                   , SPO_PROVISORY_OUTPUT
                   , SPO_AVAILABLE_QUANTITY
                   , SPO_THEORETICAL_QUANTITY
                   , SPO_ALTERNATIV_QUANTITY_1
                   , SPO_ALTERNATIV_QUANTITY_2
                   , SPO_ALTERNATIV_QUANTITY_3
                   , GCO_GOOD_ID
                   , STM_LOCATION_ID
                   , STM_STOCK_ID
                   , SPO_CHARACTERIZATION_VALUE_1
                   , SPO_CHARACTERIZATION_VALUE_2
                   , SPO_CHARACTERIZATION_VALUE_3
                   , SPO_CHARACTERIZATION_VALUE_4
                   , SPO_CHARACTERIZATION_VALUE_5
                   , GCO_CHARACTERIZATION_ID
                   , GCO_GCO_CHARACTERIZATION_ID
                   , GCO2_GCO_CHARACTERIZATION_ID
                   , GCO3_GCO_CHARACTERIZATION_ID
                   , GCO4_GCO_CHARACTERIZATION_ID
                   , A_DATECRE
                   , A_IDCRE
                   , A_RECSTATUS
                    )
             values (init_id_seq.nextval
                   , '01'
                   , 0
                   , 0
                   , positionToUpdate_tuple.SPR_PROVISORY_INPUT
                   , positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
                   , -positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
                   , positionToUpdate_tuple.SPR_PROVISORY_INPUT - positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
                   , 0
                   , 0
                   , 0
                   , positionToUpdate_tuple.GCO_GOOD_ID
                   , positionToUpdate_tuple.STM_LOCATION_ID
                   , stockId
                   , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_1
                   , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_2
                   , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_3
                   , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_4
                   , positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_5
                   , positionToUpdate_tuple.GCO_CHARACTERIZATION_ID
                   , positionToUpdate_tuple.GCO_GCO_CHARACTERIZATION_ID
                   , positionToUpdate_tuple.GCO2_GCO_CHARACTERIZATION_ID
                   , positionToUpdate_tuple.GCO3_GCO_CHARACTERIZATION_ID
                   , positionToUpdate_tuple.GCO4_GCO_CHARACTERIZATION_ID
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni2
                   , '7'
                    );
      elsif positionToUpdate_tuple.Action in('U', 'D') then
        -- mise à jour des compteurs avec les qté provisoires corrigées
        update stm_stock_position
           set SPO_PROVISORY_INPUT = positionToUpdate_tuple.SPR_PROVISORY_INPUT
             , SPO_PROVISORY_OUTPUT = positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
             , SPO_AVAILABLE_QUANTITY = SPO_STOCK_QUANTITY - SPO_ASSIGN_QUANTITY - positionToUpdate_tuple.SPR_PROVISORY_OUTPUT
             , SPO_THEORETICAL_QUANTITY =
                             SPO_STOCK_QUANTITY - SPO_ASSIGN_QUANTITY - positionToUpdate_tuple.SPR_PROVISORY_OUTPUT + positionToUpdate_tuple.SPR_PROVISORY_INPUT
             , A_RECSTATUS = '7'
         where GCO_GOOD_ID = positionToUpdate_tuple.GCO_GOOD_ID
           and STM_LOCATION_ID = positionToUpdate_tuple.STM_LOCATION_ID
           and nvl(SPO_CHARACTERIZATION_VALUE_1, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_1, 0)
           and nvl(SPO_CHARACTERIZATION_VALUE_2, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_2, 0)
           and nvl(SPO_CHARACTERIZATION_VALUE_3, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_3, 0)
           and nvl(SPO_CHARACTERIZATION_VALUE_4, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_4, 0)
           and nvl(SPO_CHARACTERIZATION_VALUE_5, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_5, 0)
           and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_CHARACTERIZATION_ID, 0)
           and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_GCO_CHARACTERIZATION_ID, 0)
           and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO2_GCO_CHARACTERIZATION_ID, 0)
           and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO3_GCO_CHARACTERIZATION_ID, 0)
           and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO4_GCO_CHARACTERIZATION_ID, 0);

        -- eventuellement effacement de la position si elle est à 0
        if positionToUpdate_tuple.Action = 'D' then
          delete from STM_STOCK_POSITION
                where GCO_GOOD_ID = positionToUpdate_tuple.GCO_GOOD_ID
                  and STM_LOCATION_ID = positionToUpdate_tuple.STM_LOCATION_ID
                  and nvl(SPO_CHARACTERIZATION_VALUE_1, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_1, 0)
                  and nvl(SPO_CHARACTERIZATION_VALUE_2, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_2, 0)
                  and nvl(SPO_CHARACTERIZATION_VALUE_3, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_3, 0)
                  and nvl(SPO_CHARACTERIZATION_VALUE_4, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_4, 0)
                  and nvl(SPO_CHARACTERIZATION_VALUE_5, 0) = nvl(positionToUpdate_tuple.PDE_CHARACTERIZATION_VALUE_5, 0)
                  and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO_GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO2_GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO3_GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(positionToUpdate_tuple.GCO4_GCO_CHARACTERIZATION_ID, 0)
                  and SPO_STOCK_QUANTITY = 0
                  and SPO_ASSIGN_QUANTITY = 0
                  and SPO_PROVISORY_OUTPUT = 0
                  and SPO_PROVISORY_INPUT = 0
                  and SPO_AVAILABLE_QUANTITY = 0;
        end if;
      end if;

      fetch positionToUpdate
       into positionToUpdate_tuple;
    end loop;

    close positionToUpdate;
  end RestoreProvQtyGood;

  /**
  * Description
  *    Reconstruction du décompte TVA
  */
  procedure recalcVatDetAccount(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iRecalcPositionVat in number, iControlDocument in number := 1)
  is
    lnOk        number(1);
    lvErrorText varchar2(2000);
  begin
    if (iControlDocument = 1) then
      -- Contrôle de l'état du document pour permettre sa modification.
      DOC_PRC_DOCUMENT.ControlUpdateDocument(iDocumentId, lvErrorText);
    end if;

    if (lvErrorText is not null) then
      ra(lvErrorText);
    else
      if iRecalcPositionVat = 0 then
        -- Protection du document dans une transaction autonome
        DOC_PRC_DOCUMENT.DocumentProtect_AutoTrans(iDocumentId   => iDocumentId
                                                 , iProtect      => 1
                                                 , iSessionID    => DBMS_SESSION.unique_session_id
                                                 , iManageVat    => 1
                                                 , oUpdated      => lnOk
                                                  );

        if (lnOk = 1) then
          -- Supprime le décompte et le recrée.
          DOC_PRC_VAT.ResetVatDetAccount(iDocumentId);
          -- Finalization du document
          DOC_FINALIZE.FinalizeDocument(iDocumentId);
        end if;
      else   -- iRecalcPositionVat = 1
        declare
          modified      number(1);
          chargeCreated number(1);

          cursor crDocPositions(cDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
          is
            select DOC_POSITION_ID
              from DOC_POSITION
             where DOC_DOCUMENT_ID = cDocumentId;

          cursor crdocInfo(cDocumentId in number)
          is
            select DMT.DMT_DATE_DOCUMENT
                 , DMT.ACS_FINANCIAL_CURRENCY_ID
                 , DMT.DMT_RATE_OF_EXCHANGE
                 , DMT.DMT_BASE_PRICE
                 , DMT.PC_LANG_ID
                 , nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
                 , nvl(GAS.GAS_COST, 0) GAS_COST
                 , nvl(GAS.GAS_CASH_MULTIPLE_TRANSACTION, 0) GAS_CASH_MULTIPLE_TRANSACTION
              from DOC_DOCUMENT DMT
                 , DOC_GAUGE_STRUCTURED GAS
             where DMT.DOC_DOCUMENT_ID = cDocumentId
               and GAS.DOC_GAUGE_ID(+) = DMT.DOC_GAUGE_ID;
        begin
          -- Protection du document dans une transaction autonome
          DOC_PRC_DOCUMENT.DocumentProtect_AutoTrans(iDocumentId   => iDocumentId
                                                   , iProtect      => 1
                                                   , iSessionID    => DBMS_SESSION.unique_session_id
                                                   , iManageVat    => 1
                                                   , oUpdated      => lnOk
                                                    );

          if (lnOk = 1) then
            -- préparation des flag de recalcul des positions du document
            update DOC_POSITION
               set POS_RECALC_AMOUNTS = 1
             where DOC_DOCUMENT_ID = iDocumentId;

            for tplDocPosition in crDocPositions(iDocumentId) loop
              DOC_POSITION_FUNCTIONS.UpdateChargeAndAmount(tplDocPosition.DOC_POSITION_ID);
            end loop;

            -- mise à jour des tarifs par assortiment
            DOC_TARIFF_SET.DocUpdatePriceForTariffSet(iDocumentId);
            -- recalcul des totaux du document
            DOC_FUNCTIONS.UpdateFootTotals(iDocumentId, modified);
            -- calcul des positions de récapitulation
            DOC_POSITION_FUNCTIONS.CalcRecapPos(iDocumentId);
            -- calcul des remises/taxes de groupe (calcul des totaux de pied automatiques)
            DOC_DOCUMENT_FUNCTIONS.CreateGroupChargeAndUpdatePos(iDocumentId);

            -- calcul ou création des remises/taxes
            for tplDocInfo in crdocInfo(iDocumentId) loop
              -- Gestion des poids matières précieuses
              if (tplDocInfo.GAS_WEIGHT_MAT = 1) then
                ----
                -- Génération des matières précieuses du pied. Voir graphe Fin Positions
                -- figurant dans l'analyse Facturation des matières précieuses. }
                --
                DOC_FOOT_ALLOY_FUNCTIONS.GenerateFootMat(iDocumentId);
                -- Création des taxes matières précieuses sur position
                DOC_POSITION_ALLOY_FUNCTIONS.generatePreciousMatCharge(iDocumentId, modified);
                -- recalcul des montants des positions sur les positions touchées par les taxes matières précieuses
                DOC_DOCUMENT_FUNCTIONS.RecalcModifPosChargeAndAmount(iDocumentId);
                -- Création des remises matières précieuses sur pied
                DOC_FOOT_ALLOY_FUNCTIONS.generatePreciousMatDiscount(iDocumentId, modified);
              end if;

              DOC_DISCOUNT_CHARGE.AutomaticFootCharge(iDocumentId
                                                    , tplDocInfo.DMT_DATE_DOCUMENT
                                                    , tplDocInfo.ACS_FINANCIAL_CURRENCY_ID
                                                    , tplDocInfo.DMT_RATE_OF_EXCHANGE
                                                    , tplDocInfo.DMT_BASE_PRICE
                                                    , tplDocInfo.PC_LANG_ID
                                                    , chargeCreated
                                                     );

              -- Gestion des autres coûts
              if (tpldocInfo.GAS_COST = 1) then
                if DOC_OTHER_COST_FUNCTIONS.generateOtherCostCharge(iDocumentId, modified) = 1 then
                  -- recalcul des montants des positions sur les positions touchées par les taxes matières précieuses
                  DOC_DOCUMENT_FUNCTIONS.RecalcModifPosChargeAndAmount(iDocumentId);
                end if;
              end if;

              exit;
            end loop;

            -- suppression des anciens décompte TVA
            delete from DOC_VAT_DET_ACCOUNT
                  where DOC_FOOT_ID = iDocumentId;

            -- Finalization du document
            DOC_FINALIZE.FinalizeDocument(iDocumentId);
          end if;
        end;
      end if;
    end if;
  end recalcVatDetAccount;
end DOC_PRC_PARITY;
