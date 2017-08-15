--------------------------------------------------------
--  DDL for Package Body DOC_CURRENCY_MIGRATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_CURRENCY_MIGRATION" 
is
  /**
  * Description
  *           procedure d'épuration des documents liquidés par exercice de stock
  */
  procedure PurgeExerciseDocuments(Exercise_id in number)
  is
    cursor ExerciseDocuments(Exercise_Id number)
    is
      select doc_document_id
        from doc_document
       where stm_functions.GetExerciseId(dmt_date_document) = Exercise_id
         and c_document_status = '04';

    current_document_id number(12);
  begin
    open ExerciseDocuments(Exercise_id);

    fetch ExerciseDocuments
     into current_document_id;

    while ExerciseDocuments%found loop
      begin
        savepoint onedoc;

        delete from doc_position_detail
              where doc_document_id = current_document_id;

        delete from doc_delay_history
              where doc_position_detail_id in(select doc_position_detail_id
                                                from doc_position_detail
                                               where doc_position_detail.doc_document_id = current_document_id);

        delete from doc_position_charge
              where doc_document_id = current_document_id;

        delete from doc_position
              where doc_document_id = current_document_id;

        delete from doc_vat_det_account
              where doc_foot_id = current_document_id;

        delete from doc_foot
              where doc_document_id = current_document_id;

        delete from doc_document
              where doc_document_id = current_document_id;
      exception
        when others then
          rollback to savepoint onedoc;
      end;

      fetch ExerciseDocuments
       into current_document_id;
    end loop;
  end;

  /**
  * Description : Procedure globale de migration des documents vers une nouvelle monnaie de base
  */
  procedure ConvertDocuments(old_currency_id in number, new_currency_id in number, exchange_rate in number, base_price in number, step in number)
  is
    cursor document
    is
      select doc_document_id
        from doc_document
       where nvl(a_recstatus, 0) = 0;

    cursor detail_cursor
    is
      select doc_position_detail_id
        from doc_position_detail
       where nvl(a_recstatus, 0) = 0;

    cursor position
    is
      select doc_position_id
        from doc_position
       where nvl(a_recstatus, 0) = 0;

    cursor position_charge
    is
      select doc_position_charge_id
        from doc_position_charge
       where nvl(a_recstatus, 0) = 0;

    cursor foot_charge
    is
      select doc_foot_charge_id
        from doc_foot_charge
       where nvl(a_recstatus, 0) = 0;

    cursor payment_date
    is
      select doc_payment_date_id
        from doc_payment_date
       where nvl(a_recstatus, 0) = 0;

    cursor foot
    is
      select doc_foot_id
        from doc_foot
       where nvl(a_recstatus, 0) = 0;

    cursor vat_detail
    is
      select doc_document_id
           , acs_tax_code_id
           , vda_liable_amount_b liable_amount
           , vda_vat_base_amount vat_amount
        from v_doc_vat_det_account;

    vat_tuple     vat_detail%rowtype;
    doc_id        number(12);
    vIndex        integer;
    current_id    number(12);
    totalModified number(1);
  begin
    if step = 0 then
      vIndex  := 0;

      open detail_cursor;

      fetch detail_cursor
       into current_id;

      while detail_cursor%found loop
        update doc_position_detail
           set pde_movement_value = ACS_FUNCTION.RoundNear(pde_movement_value * base_price / exchange_rate, 0.01)
             , a_recstatus = nvl(a_recstatus, 0) + 1
         where doc_position_detail_id = current_id;

        if vIndex <= commit_step then
          vIndex  := vIndex + 1;
        else
          commit;
          vIndex  := 0;
        end if;

        fetch detail_cursor
         into current_id;
      end loop;

      commit;

      close detail_cursor;
    elsif step = 1 then
      open position;

      fetch position
       into current_id;

      vIndex  := 0;

      while position%found loop
        update doc_position
           set (POS_GROSS_VALUE_B, POS_GROSS_VALUE_INCL_B, POS_NET_VALUE_EXCL_B, POS_NET_VALUE_INCL_B, POS_VAT_BASE_AMOUNT, A_RECSTATUS) =
                 (select decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, POS_GROSS_VALUE
                              , ACS_FUNCTION.RoundNear(POS_GROSS_VALUE_B * base_price / exchange_rate, 0.01)
                               ) POS_GROSS_VALUE_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, POS_GROSS_VALUE_INCL
                              , ACS_FUNCTION.RoundNear(POS_GROSS_VALUE_INCL_B * base_price / exchange_rate, 0.01)
                               ) POS_GROSS_VALUE_INCL_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, POS_NET_VALUE_EXCL
                              , ACS_FUNCTION.RoundNear(POS_NET_VALUE_EXCL_B * base_price / exchange_rate, 0.01)
                               ) POS_NET_VALUE_EXCL_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, POS_NET_VALUE_INCL
                              , ACS_FUNCTION.RoundNear(POS_NET_VALUE_INCL_B * base_price / exchange_rate, 0.01)
                               ) POS_NET_VALUE_INCL_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, POS_VAT_AMOUNT
                              , ACS_FUNCTION.RoundNear(POS_VAT_BASE_AMOUNT * base_price / exchange_rate, 0.01)
                               ) POS_VAT_BASE_AMOUNT
                       , nvl(doc_position.a_recstatus, 0) + 1
                    from DOC_DOCUMENT
                   where DOC_DOCUMENT_ID = doc_position.DOC_DOCUMENT_ID)
         where doc_position_id = current_id;

        fetch position
         into current_id;

        if vIndex >= commit_step then
          vIndex  := 0;
          commit;
        else
          vIndex  := vIndex + 1;
        end if;
      end loop;

      commit;

      close position;
    -- Taxes de position
    elsif step = 2 then
      open position_charge;

      fetch position_charge
       into current_id;

      vIndex  := 0;

      while position_charge%found loop
        update doc_position_charge
           set (PCH_AMOUNT_B, PCH_CALC_AMOUNT_B, PCH_LIABLED_AMOUNT_B, PCH_FIXED_AMOUNT_B, A_RECSTATUS) =
                 (select decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PCH_AMOUNT
                              , ACS_FUNCTION.RoundNear(PCH_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) PCH_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PCH_CALC_AMOUNT
                              , ACS_FUNCTION.RoundNear(PCH_CALC_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) PCH_CALC_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PCH_LIABLED_AMOUNT
                              , ACS_FUNCTION.RoundNear(PCH_LIABLED_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) PCH_LIABLED_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PCH_FIXED_AMOUNT
                              , ACS_FUNCTION.RoundNear(PCH_FIXED_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) PCH_FIXED_AMOUNT_B
                       , nvl(doc_position_charge.A_RECSTATUS, 0) + 1
                    from DOC_DOCUMENT
                   where DOC_DOCUMENT_ID = doc_position_charge.DOC_DOCUMENT_ID)
         where doc_position_charge_id = current_id;

        fetch position_charge
         into current_id;

        if vIndex >= commit_step then
          vIndex  := 0;
          commit;
        else
          vIndex  := vIndex + 1;
        end if;
      end loop;

      commit;

      close position_charge;
    -- taxes de pied
    elsif step = 3 then
      open foot_charge;

      fetch foot_charge
       into current_id;

      vIndex  := 0;

      while foot_charge%found loop
        update doc_foot_charge
           set (FCH_EXCL_AMOUNT_B, FCH_INCL_AMOUNT_B, FCH_CALC_AMOUNT_B, FCH_LIABLED_AMOUNT_B, FCH_FIXED_AMOUNT_B, FCH_VAT_BASE_AMOUNT, A_RECSTATUS) =
                 (select decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, FCH_EXCL_AMOUNT
                              , ACS_FUNCTION.RoundNear(FCH_EXCL_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) FCH_EXCL_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, FCH_INCL_AMOUNT
                              , ACS_FUNCTION.RoundNear(FCH_INCL_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) FCH_INCL_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, FCH_CALC_AMOUNT
                              , ACS_FUNCTION.RoundNear(FCH_CALC_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) FCH_CALC_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, FCH_LIABLED_AMOUNT
                              , ACS_FUNCTION.RoundNear(FCH_LIABLED_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) FCH_LIABLED_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, FCH_FIXED_AMOUNT
                              , ACS_FUNCTION.RoundNear(FCH_FIXED_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) FCH_FIXED_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, FCH_VAT_AMOUNT
                              , ACS_FUNCTION.RoundNear(FCH_VAT_BASE_AMOUNT * base_price / exchange_rate, 0.01)
                               ) FCH_VAT_BASE_AMOUNT
                       , nvl(doc_foot_charge.A_RECSTATUS, 0) + 1
                    from DOC_DOCUMENT
                   where DOC_DOCUMENT_ID = doc_foot_charge.DOC_FOOT_ID)
         where doc_foot_charge_id = current_id;

        fetch foot_charge
         into current_id;

        if vIndex >= commit_step then
          vIndex  := 0;
          commit;
        else
          vIndex  := vIndex + 1;
        end if;
      end loop;

      commit;

      close foot_charge;
    -- décompte TVA
    elsif step = 4 then
      open vat_detail;

      fetch vat_detail
       into vat_tuple;

      vIndex  := 0;

      while vat_detail%found loop
        update doc_vat_det_account
           set vda_liable_amount_b = vat_tuple.liable_amount
             , vda_vat_base_amount = vat_tuple.vat_amount
             , vda_corr_amount_b = ACS_FUNCTION.RoundNear(vda_corr_amount_b * base_price / exchange_rate, 0.01)
             , a_recstatus = nvl(a_recstatus, 0) + 1
         where doc_foot_id = vat_tuple.doc_document_id
           and acs_tax_code_id = vat_tuple.acs_tax_code_id;

        fetch vat_detail
         into vat_tuple;

        if vIndex >= commit_step then
          vIndex  := 0;
          commit;
        else
          vIndex  := vIndex + 1;
        end if;
      end loop;

      commit;

      close vat_detail;
    -- échéances de paiement
    elsif step = 5 then
      open payment_date;

      fetch payment_date
       into current_id;

      vIndex  := 0;

      while payment_date%found loop
        update doc_payment_date
           set (PAD_DATE_AMOUNT_B, PAD_DISCOUNT_AMOUNT_B, PAD_NET_DATE_AMOUNT_B, PAD_AMOUNT_PROV_LC, A_RECSTATUS) =
                 (select decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PAD_DATE_AMOUNT
                              , ACS_FUNCTION.RoundNear(PAD_DATE_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) PAD_DATE_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PAD_DISCOUNT_AMOUNT
                              , ACS_FUNCTION.RoundNear(PAD_DISCOUNT_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) PAD_DISCOUNT_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PAD_NET_DATE_AMOUNT
                              , ACS_FUNCTION.RoundNear(PAD_NET_DATE_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) PAD_NET_DATE_AMOUNT_B
                       , decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, PAD_AMOUNT_PROV_FC
                              , ACS_FUNCTION.RoundNear(PAD_AMOUNT_PROV_LC * base_price / exchange_rate, 0.01)
                               ) PAD_AMOUNT_PROV_LC
                       , nvl(doc_payment_date.A_RECSTATUS, 0) + 1
                    from DOC_DOCUMENT
                   where DOC_DOCUMENT_ID = doc_payment_date.DOC_FOOT_ID)
         where doc_payment_date_id = current_id;

        fetch payment_date
         into current_id;

        if vIndex >= commit_step then
          vIndex  := 0;
          commit;
        else
          vIndex  := vIndex + 1;
        end if;
      end loop;

      commit;
    -- pieds (champs non totaux)
    elsif step = 6 then
      open foot;

      fetch foot
       into current_id;

      vIndex  := 0;

      while foot%found loop
        update doc_foot
           set (FOO_PAID_AMOUNT_B, A_RECSTATUS) =
                 (select decode(ACS_FINANCIAL_CURRENCY_ID
                              , new_currency_id, FOO_PAID_AMOUNT
                              , ACS_FUNCTION.RoundNear(FOO_PAID_AMOUNT_B * base_price / exchange_rate, 0.01)
                               ) FOO_PAID_AMOUNT_B
                       , nvl(doc_foot.A_RECSTATUS, 0) + 1
                    from DOC_DOCUMENT
                   where DOC_DOCUMENT_ID = doc_foot.DOC_FOOT_ID)
         where doc_foot_id = current_id;

        fetch foot
         into current_id;

        if vIndex >= commit_step then
          vIndex  := 0;
          commit;
        else
          vIndex  := vIndex + 1;
        end if;
      end loop;

      commit;
    -- pied (totaux)
    elsif step = 7 then
      begin
        -- ouverture d'un curseur sur tous les documents de la société
        open document;

        fetch document
         into current_id;

        vIndex  := 0;

        -- parcour de tous les documents l'un après l'autre
        while document%found loop
          -- mise à jour des totaux des pieds de document
          doc_functions.UpdateFootTotals(current_id, totalModified);

          -- document suivant
          fetch document
           into current_id;

          if vIndex >= commit_step then
            vIndex  := 0;
            commit;
          else
            vIndex  := vIndex + 1;
          end if;
        end loop;

        close document;

        commit;
      end;
    -- Taux de change
    elsif step = 8 then
      open document;

      fetch document
       into current_id;

      while document%found loop
        update doc_document
           set dmt_text_3 = (select CURRENCY
                               from v_acs_financial_currency
                              where acs_financial_currency_id = old_currency_id)
             , dmt_rate_of_exchange =
                 decode(ACS_FINANCIAL_CURRENCY_ID
                      , new_currency_id, 1
                      ,   -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                        decode(new_currency_id
                             ,   -- nouvelle monnaie différente de la monnaie du document
                               ACS_FUNCTION.GetEuroCurrency, decode
                                                             (ACS_FUNCTION.IsFinCurrInEuro(ACS_FINANCIAL_CURRENCY_ID, sysdate)
                                                            ,   -- nouvelle monaie est l'Euro
                                                              1, 1
                                                            ,   -- monnaie document est monnaie IN --> taux de change à 1
                                                              decode(exchange_rate
                                                                   ,   -- monnaie document pas monnaie IN
                                                                     0, 1
                                                                   ,   -- si le taux passé en paramètre est à 0 -> taux de change = 1
                                                                     decode(DMT_RATE_OF_EXCHANGE
                                                                          , 0, 1 /(exchange_rate / base_price)
                                                                          ,   -- document dans l'ancienne monnaie de base -> inverse du taux
                                                                            (DMT_RATE_OF_EXCHANGE / DMT_BASE_PRICE
                                                                            ) /
                                                                            (exchange_rate / base_price
                                                                            )   -- cas 2 monnaie non euro --> rapport de taux de change
                                                                           )
                                                                    )
                                                             )
                             , decode(DMT_RATE_OF_EXCHANGE
                                    ,   -- nouvelle monnaie non euro
                                      0, 1 /(exchange_rate / base_price)
                                    ,   -- document dans l'ancienne monnaie de base -> inverse du taux
                                      decode(DMT_BASE_PRICE
                                           ,   -- document monnaie étrangère différente nouvelle monnaie
                                             0, 0
                                           , (DMT_RATE_OF_EXCHANGE / DMT_BASE_PRICE) /(exchange_rate / base_price)
                                            )
                                     )
                              )
                       )
             , dmt_base_price =
                 decode(ACS_FINANCIAL_CURRENCY_ID
                      , new_currency_id, 1
                      ,   -- nouvelle monnaie de base = monnaie document --> taux de change = 1
                        decode(new_currency_id
                             ,   -- nouvelle monnaie différente de la monnaie du document
                               ACS_FUNCTION.GetEuroCurrency, decode
                                                                (ACS_FUNCTION.IsFinCurrInEuro(ACS_FINANCIAL_CURRENCY_ID, sysdate)
                                                               ,   -- nouvelle monaie est l'Euro
                                                                 1, 1
                                                               ,   -- monnaie document est monnaie IN --> taux de change à 0
                                                                 decode(DMT_RATE_OF_EXCHANGE
                                                                      ,   -- monnaie document pas monnaie IN
                                                                        0, 1
                                                                      ,   -- document dans l'ancienne monnaie de base -> diviseur = 1
                                                                        decode(DMT_BASE_PRICE
                                                                             , 0, 1
                                                                             , 1   -- si le diviseur passé en paramètre est 0 -> taux de change = 1, sinon -> 1
                                                                              )
                                                                       )
                                                                )
                             , decode(DMT_RATE_OF_EXCHANGE
                                    ,   -- nouvelle monnaie non euro
                                      0, 1
                                    ,   -- document dans l'ancienne monnaie de base
                                      decode(DMT_BASE_PRICE,   -- document monnaie étrangère différente nouvelle monnaie
                                             0, 1, 1)
                                     )
                              )
                       )
             , acs_acs_financial_currency_id = new_currency_id
             , A_RECSTATUS = 1
         where doc_document_id = current_id
           and nvl(A_RECSTATUS, 0) = 0;

        -- document suivant
        fetch document
         into current_id;

        if vIndex >= commit_step then
          vIndex  := 0;
          commit;
        else
          vIndex  := vIndex + 1;
        end if;
      end loop;

      close document;

      commit;
    end if;
  end;

  /**
  * Description : Procedure de conversion des valeurs des mouvements de stock
  */
  procedure ConvertStm(old_currency_id in number, new_currency_id in number, exchange_rate in number, base_price in number)
  is
    vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF, false, null, null, 'STM_STOCK_MOVEMENT_ID');

    for tplMovement in (select STM_STOCK_MOVEMENT_ID
                             , SMO_MOVEMENT_PRICE
                             , SMO_MOVEMENT_QUANTITY
                             , SMO_REFERENCE_UNIT_PRICE
                             , A_RECSTATUS
                          from STM_STOCK_MOVEMENT
                         where nvl(A_RECSTATUS, 0) = 0) loop
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplMovement.STM_STOCK_MOVEMENT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                    , 'SMO_MOVEMENT_PRICE'
                                    , ACS_FUNCTION.RoundNear(tplMovement.SMO_MOVEMENT_PRICE * base_price / exchange_rate, 0.01)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                    , 'SMO_UNIT_PRICE'
                                    , ACS_FUNCTION.RoundNear(tplMovement.SMO_MOVEMENT_PRICE * base_price / exchange_rate, 0.01) /
                                      case
                                        when nvl(tplMovement.SMO_MOVEMENT_QUANTITY, 0) = 0 then 1
                                        else tplMovement.SMO_MOVEMENT_QUANTITY
                                      end
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                    , 'SMO_REFERENCE_UNIT_PRICE'
                                    , ACS_FUNCTION.RoundNear(tplMovement.SMO_REFERENCE_UNIT_PRICE * base_price / exchange_rate, 0.01)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'A_RECSTATUS', nvl(tplMovement.A_RECSTATUS, 0) + 1);
      FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
    end loop;

    FWK_I_MGT_ENTITY.Release(vCRUD_DEF);

    update STM_ABC_RESULT
       set ART_VALUE =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(art_value, old_currency_id, new_currency_id, trunc(sysdate), exchange_rate, base_price, 0)
                                  , 0.01
                                   )
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;
  end;

  /**
  * Description : Procedure de conversion des valeurs des mouvements de stock
  */
  procedure ConvertPTC(old_currency_id in number, new_currency_id in number, exchange_rate in number, base_price in number)
  is
  begin
    update PTC_CALC_COSTPRICE
       set CCP_ADDED_VALUE =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(CCP_ADDED_VALUE
                                                                    , old_currency_id
                                                                    , new_currency_id
                                                                    , trunc(sysdate)
                                                                    , exchange_rate
                                                                    , base_price
                                                                    , 0
                                                                     )
                                  , 0.01
                                   )
         , A_RECSTATUS = 1
     where nvl(A_RECSTATUS, 0) = 0;

    -- si la quantité cumulée = 0 on converti directement le prix, sinon on calcule le prix par division de la valeur cumulée par la quantité cumulée
    update PTC_CALC_COSTPRICE
       set CPR_PRICE =
             decode(CCP_ADDED_QUANTITY
                  , 0, ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(CPR_PRICE
                                                                              , old_currency_id
                                                                              , new_currency_id
                                                                              , trunc(sysdate)
                                                                              , exchange_rate
                                                                              , base_price
                                                                              , 0
                                                                               )
                                            , 0.01
                                             )
                  , CCP_ADDED_VALUE / CCP_ADDED_QUANTITY
                   )
         , A_RECSTATUS = 1
     where nvl(A_RECSTATUS, 0) = 0;

    update PTC_FIXED_COSTPRICE
       set CPR_PRICE =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(CPR_PRICE, old_currency_id, new_currency_id, trunc(sysdate), exchange_rate, base_price, 0)
                                  , 0.01
                                   )
         , A_RECSTATUS = 1
     where nvl(A_RECSTATUS, 0) = 0;

    update PTC_CHARGE
       set CRG_FIXED_AMOUNT =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(CRG_FIXED_AMOUNT
                                                                    , old_currency_id
                                                                    , new_currency_id
                                                                    , trunc(sysdate)
                                                                    , exchange_rate
                                                                    , base_price
                                                                    , 0
                                                                     )
                                  , 0.01
                                   )
         , A_RECSTATUS = 1
     where C_CALCULATION_MODE in('0', '1', '6')
       and nvl(A_RECSTATUS, 0) = 0;

    update PTC_CHARGE
       set CRG_EXCEEDED_AMOUNT_FROM =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(CRG_EXCEEDED_AMOUNT_FROM
                                                                    , old_currency_id
                                                                    , new_currency_id
                                                                    , trunc(sysdate)
                                                                    , exchange_rate
                                                                    , base_price
                                                                    , 0
                                                                     )
                                  , 0.01
                                   )
         , CRG_EXCEEDED_AMOUNT_TO =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(CRG_EXCEEDED_AMOUNT_TO
                                                                    , old_currency_id
                                                                    , new_currency_id
                                                                    , trunc(sysdate)
                                                                    , exchange_rate
                                                                    , base_price
                                                                    , 0
                                                                     )
                                  , 0.01
                                   )
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 2
     where C_CALCULATION_MODE in('1', '3', '5')
       and nvl(A_RECSTATUS, 0) in(0, 1);

    update PTC_DISCOUNT
       set DNT_FIXED_AMOUNT =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(DNT_FIXED_AMOUNT
                                                                    , old_currency_id
                                                                    , new_currency_id
                                                                    , trunc(sysdate)
                                                                    , exchange_rate
                                                                    , base_price
                                                                    , 0
                                                                     )
                                  , 0.01
                                   )
         , A_RECSTATUS = 1
     where C_CALCULATION_MODE in('0', '1', '6')
       and nvl(A_RECSTATUS, 0) = 0;

    update PTC_DISCOUNT
       set DNT_EXCEEDING_AMOUNT_FROM =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(DNT_EXCEEDING_AMOUNT_FROM
                                                                    , old_currency_id
                                                                    , new_currency_id
                                                                    , trunc(sysdate)
                                                                    , exchange_rate
                                                                    , base_price
                                                                    , 0
                                                                     )
                                  , 0.01
                                   )
         , DNT_EXCEEDING_AMOUNT_TO =
             ACS_FUNCTION.RoundNear(ACS_FUNCTION.ConvertAmountForView(DNT_EXCEEDING_AMOUNT_TO
                                                                    , old_currency_id
                                                                    , new_currency_id
                                                                    , trunc(sysdate)
                                                                    , exchange_rate
                                                                    , base_price
                                                                    , 0
                                                                     )
                                  , 0.01
                                   )
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 2
     where C_CALCULATION_MODE in('1', '3', '5')
       and nvl(A_RECSTATUS, 0) in(0, 1);
  end;

  /**
  * Description : Procedure de conversion des valeurs des tables PPS
  *               nomenclatures
  */
  procedure ConvertPPS(old_currency_id in number, new_currency_id in number, exchange_rate in number, base_price in number)
  is
  begin
    update PPS_RATE_MACHINE
       set RMA_DIRECT_COST = ACS_FUNCTION.RoundNear(RMA_DIRECT_COST * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    update PPS_RATE_LABOUR
       set RLA_DIRECT_COST = ACS_FUNCTION.RoundNear(RLA_DIRECT_COST * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;
  end;

  /**
  * Description : Procedure de conversion des valeurs des tables GCO  biens
  */
  procedure ConvertGCO(old_currency_id in number, new_currency_id in number, exchange_rate in number, base_price in number)
  is
  begin
    update gco_good_calc_data
       set GOO_ADDED_VALUE_COST_PRICE = ACS_FUNCTION.RoundNear(GOO_ADDED_VALUE_COST_PRICE * base_price / exchange_rate, 0.01);

    -- si la quantité cumulée = 0 on converti directement le prix, sinon on calcule le prix par division de la valeur cumulée par la quantité cumulée
    update gco_good_calc_data
       set GOO_BASE_COST_PRICE =
             decode(GOO_ADDED_QTY_COST_PRICE
                  , 0, ACS_FUNCTION.RoundNear(GOO_BASE_COST_PRICE * base_price / exchange_rate, 0.01)
                  , GOO_ADDED_VALUE_COST_PRICE / GOO_ADDED_QTY_COST_PRICE
                   )
         , A_RECSTATUS = 1;
  end;

  /**
  * Description : Procedure de conversion des valeurs des tables ASA service après-vente
  */
  procedure ConvertASA(old_currency_id in number, new_currency_id in number, exchange_rate in number, base_price in number)
  is
  begin
    update ASA_RECORD
       set ARE_SALE_PRICE_T_MB = ACS_FUNCTION.RoundNear(ARE_SALE_PRICE_T_MB * base_price / exchange_rate, 0.01)
         , ARE_MIN_DEVIS_MB = ACS_FUNCTION.RoundNear(ARE_MIN_DEVIS_MB * base_price / exchange_rate, 0.01)
         , ARE_COST_PRICE_S = ACS_FUNCTION.RoundNear(ARE_COST_PRICE_S * base_price / exchange_rate, 0.01)
         , ARE_COST_PRICE_W = ACS_FUNCTION.RoundNear(ARE_COST_PRICE_W * base_price / exchange_rate, 0.01)
         , ARE_COST_PRICE_C = ACS_FUNCTION.RoundNear(ARE_COST_PRICE_C * base_price / exchange_rate, 0.01)
         , ARE_COST_PRICE_T = ACS_FUNCTION.RoundNear(ARE_COST_PRICE_T * base_price / exchange_rate, 0.01)
         , ARE_SALE_PRICE_S = ACS_FUNCTION.RoundNear(ARE_SALE_PRICE_S * base_price / exchange_rate, 0.01)
         , ARE_SALE_PRICE_W = ACS_FUNCTION.RoundNear(ARE_SALE_PRICE_W * base_price / exchange_rate, 0.01)
         , ARE_SALE_PRICE_C = ACS_FUNCTION.RoundNear(ARE_SALE_PRICE_C * base_price / exchange_rate, 0.01);

    commit;

    update ASA_RECORD_COMP
       set ARC_COST_PRICE = ACS_FUNCTION.RoundNear(ARC_COST_PRICE * base_price / exchange_rate, 0.01)
         , ARC_SALE_PRICE = ACS_FUNCTION.RoundNear(ARC_SALE_PRICE * base_price / exchange_rate, 0.01);

    commit;

    update ASA_RECORD_TASK
       set RET_AMOUNT = ACS_FUNCTION.RoundNear(RET_AMOUNT * base_price / exchange_rate, 0.01)
         , RET_SALE_AMOUNT = ACS_FUNCTION.RoundNear(RET_SALE_AMOUNT * base_price / exchange_rate, 0.01);

    commit;

    update ASA_REP_TYPE
       set RET_COST_PRICE_S = ACS_FUNCTION.RoundNear(RET_COST_PRICE_S * base_price / exchange_rate, 0.01)
         , RET_COST_PRICE_W = ACS_FUNCTION.RoundNear(RET_COST_PRICE_W * base_price / exchange_rate, 0.01)
         , RET_COST_PRICE_C = ACS_FUNCTION.RoundNear(RET_COST_PRICE_C * base_price / exchange_rate, 0.01)
         , RET_COST_PRICE_T = ACS_FUNCTION.RoundNear(RET_COST_PRICE_T * base_price / exchange_rate, 0.01)
         , RET_SALE_PRICE_S = ACS_FUNCTION.RoundNear(RET_SALE_PRICE_S * base_price / exchange_rate, 0.01)
         , RET_SALE_PRICE_W = ACS_FUNCTION.RoundNear(RET_SALE_PRICE_W * base_price / exchange_rate, 0.01)
         , RET_SALE_PRICE_C = ACS_FUNCTION.RoundNear(RET_SALE_PRICE_C * base_price / exchange_rate, 0.01)
         , RET_SALE_PRICE_T = ACS_FUNCTION.RoundNear(RET_SALE_PRICE_T * base_price / exchange_rate, 0.01)
         , RET_FREE_CURRENCY1 = ACS_FUNCTION.RoundNear(RET_FREE_CURRENCY1 * base_price / exchange_rate, 0.01)
         , RET_FREE_CURRENCY2 = ACS_FUNCTION.RoundNear(RET_FREE_CURRENCY2 * base_price / exchange_rate, 0.01)
         , RET_FREE_CURRENCY3 = ACS_FUNCTION.RoundNear(RET_FREE_CURRENCY3 * base_price / exchange_rate, 0.01)
         , RET_FREE_CURRENCY4 = ACS_FUNCTION.RoundNear(RET_FREE_CURRENCY4 * base_price / exchange_rate, 0.01)
         , RET_FREE_CURRENCY5 = ACS_FUNCTION.RoundNear(RET_FREE_CURRENCY5 * base_price / exchange_rate, 0.01);

    commit;

    update ASA_REP_TYPE_GOOD
       set RTG_COST_PRICE_S = ACS_FUNCTION.RoundNear(RTG_COST_PRICE_S * base_price / exchange_rate, 0.01)
         , RTG_COST_PRICE_W = ACS_FUNCTION.RoundNear(RTG_COST_PRICE_W * base_price / exchange_rate, 0.01)
         , RTG_COST_PRICE_C = ACS_FUNCTION.RoundNear(RTG_COST_PRICE_C * base_price / exchange_rate, 0.01)
         , RTG_COST_PRICE_T = ACS_FUNCTION.RoundNear(RTG_COST_PRICE_T * base_price / exchange_rate, 0.01)
         , RTG_SALE_PRICE_S = ACS_FUNCTION.RoundNear(RTG_SALE_PRICE_S * base_price / exchange_rate, 0.01)
         , RTG_SALE_PRICE_W = ACS_FUNCTION.RoundNear(RTG_SALE_PRICE_W * base_price / exchange_rate, 0.01)
         , RTG_SALE_PRICE_C = ACS_FUNCTION.RoundNear(RTG_SALE_PRICE_C * base_price / exchange_rate, 0.01)
         , RTG_SALE_PRICE_T = ACS_FUNCTION.RoundNear(RTG_SALE_PRICE_T * base_price / exchange_rate, 0.01);

    commit;

    update ASA_REP_TYPE_TASK
       set RTT_AMOUNT = ACS_FUNCTION.RoundNear(RTT_AMOUNT * base_price / exchange_rate, 0.01)
         , RTT_SALE_AMOUNT = ACS_FUNCTION.RoundNear(RTT_SALE_AMOUNT * base_price / exchange_rate, 0.01);

    commit;
  end;

  /**
  * Description : Procedure de conversion des valeurs des tables FAL fabrication
  */
  procedure ConvertFAL(old_currency_id in number, new_currency_id in number, exchange_rate in number, base_price in number)
  is
  begin
    update FAL_AFFECT
       set FAF_UNITARY_AMOUNT = ACS_FUNCTION.RoundNear(FAF_UNITARY_AMOUNT * base_price / exchange_rate, 0.01)
         , FAF_TOTAL_AMOUNT = ACS_FUNCTION.RoundNear(FAF_TOTAL_AMOUNT * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_FACTORY_IN
       set IN_PRICE = ACS_FUNCTION.RoundNear(IN_PRICE * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_FACTORY_IN_HIST
       set IN_PRICE = ACS_FUNCTION.RoundNear(IN_PRICE * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_FACTORY_OUT
       set OUT_PRICE = ACS_FUNCTION.RoundNear(OUT_PRICE * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_FACTORY_OUT_HIST
       set OUT_PRICE = ACS_FUNCTION.RoundNear(OUT_PRICE * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_LIST_STEP_LINK
       set SCS_AMOUNT = ACS_FUNCTION.RoundNear(SCS_AMOUNT * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_LOT_MATERIAL_LINK
       set LOM_PRICE = ACS_FUNCTION.RoundNear(LOM_PRICE * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_LOT_MAT_LINK_HIST
       set LOM_PRICE = ACS_FUNCTION.RoundNear(LOM_PRICE * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_LOT_PROGRESS
       set FLP_AMOUNT = ACS_FUNCTION.RoundNear(FLP_AMOUNT * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_LOT_PROGRESS_FOG
       set PFG_AMOUNT = ACS_FUNCTION.RoundNear(PFG_AMOUNT * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_LOT_PROGRESS_HIST
       set FLP_AMOUNT = ACS_FUNCTION.RoundNear(FLP_AMOUNT * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_TASK_LINK
       set SCS_AMOUNT = ACS_FUNCTION.RoundNear(SCS_AMOUNT * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_TASK_LINK
       set TAL_CST_UNIT_PRICE_B = ACS_FUNCTION.RoundNear(TAL_CST_UNIT_PRICE_B * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_TASK_LINK_HIST
       set SCS_AMOUNT = ACS_FUNCTION.RoundNear(SCS_AMOUNT * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;

    update FAL_FACTORY_RATE
       set FFR_RATE1 = ACS_FUNCTION.RoundNear(FFR_RATE1 * base_price / exchange_rate, 0.01)
         , FFR_RATE2 = ACS_FUNCTION.RoundNear(FFR_RATE2 * base_price / exchange_rate, 0.01)
         , FFR_RATE3 = ACS_FUNCTION.RoundNear(FFR_RATE3 * base_price / exchange_rate, 0.01)
         , FFR_RATE4 = ACS_FUNCTION.RoundNear(FFR_RATE4 * base_price / exchange_rate, 0.01)
         , FFR_RATE5 = ACS_FUNCTION.RoundNear(FFR_RATE5 * base_price / exchange_rate, 0.01)
         , A_RECSTATUS = nvl(A_RECSTATUS, 0) + 1
     where nvl(A_RECSTATUS, 0) = 0;

    commit;
  end;
end DOC_CURRENCY_MIGRATION;
