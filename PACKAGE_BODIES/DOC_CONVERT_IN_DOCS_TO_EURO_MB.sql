--------------------------------------------------------
--  DDL for Package Body DOC_CONVERT_IN_DOCS_TO_EURO_MB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_CONVERT_IN_DOCS_TO_EURO_MB" 
is
  /**
  * procedure RemoveCorrectionAmount
  * Description
  *     Procedure de suppression des montants de corrections contenus dans DOC_VAT_DET_ACCOUNT
  *     (VDA_CORR_AMOUNT... et VDA_ROUND_AMOUNT)
  */
  procedure RemoveVatCorrectionAmount(aDocumentId in number, aRemoveRound in number default 1, aRemoveCorr in number default 1)
  is
    cursor vatCorrection(aDocId number)
    is
      select VDA.DOC_VAT_DET_ACCOUNT_ID
           , VDA.VDA_VAT_AMOUNT
           , VDA.VDA_VAT_BASE_AMOUNT
           , VDA.VDA_VAT_AMOUNT_E
           , VDA.VDA_VAT_AMOUNT_V
           , nvl(VDA.VDA_ROUND_AMOUNT, 0) VDA_ROUND_AMOUNT
           , ACS_FUNCTION.ConvertAmountForView(VDA_VAT_AMOUNT + nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                             , DMT.ACS_FINANCIAL_CURRENCY_ID
                                             , ACS_FUNCTION.GetLocalCurrencyId
                                             , DMT.DMT_DATE_DOCUMENT
                                             , DMT.DMT_RATE_OF_EXCHANGE
                                             , DMT.DMT_BASE_PRICE
                                             , 0
                                              ) -
             VDA_VAT_BASE_AMOUNT VDA_ROUND_AMOUNT_B
           , ACS_FUNCTION.ConvertAmountEurForView(VDA_VAT_AMOUNT + nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                                , DMT.ACS_FINANCIAL_CURRENCY_ID
                                                , ACS_FUNCTION.GetEurocurrency
                                                , DMT.DMT_DATE_DOCUMENT
                                                , DMT.DMT_RATE_OF_EXCHANGE
                                                , DMT.DMT_BASE_PRICE
                                                , 0
                                                 ) -
             VDA_VAT_AMOUNT_E VDA_ROUND_AMOUNT_E
           , ACS_FUNCTION.ConvertAmountForView(nvl(VDA_VAT_AMOUNT + VDA.VDA_ROUND_AMOUNT, 0)
                                             , DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                                             , ACS_FUNCTION.GetLocalCurrencyId
                                             , DMT.DMT_DATE_DOCUMENT
                                             , DMT.DMT_VAT_EXCHANGE_RATE
                                             , DMT.DMT_VAT_BASE_PRICE
                                             , 0
                                              ) -
             VDA_VAT_AMOUNT_V VDA_ROUND_AMOUNT_V
           , nvl(VDA.VDA_CORR_AMOUNT, 0) VDA_CORR_AMOUNT
           , nvl(VDA.VDA_CORR_AMOUNT_B, 0) VDA_CORR_AMOUNT_B
           , nvl(VDA.VDA_CORR_AMOUNT_E, 0) VDA_CORR_AMOUNT_E
           , nvl(VDA.VDA_CORR_AMOUNT_V, 0) VDA_CORR_AMOUNT_V
           , VDA.DOC_POSITION_ID
           , VDA.DOC_FOOT_CHARGE_ID
           , GAP.GAP_INCLUDE_TAX_TARIFF
           , GAP.GAP_VALUE_QUANTITY
        from DOC_DOCUMENT DMT
           , DOC_VAT_DET_ACCOUNT VDA
           , DOC_POSITION POS
           , DOC_GAUGE_POSITION GAP
       where DMT.DOC_DOCUMENT_ID = aDocId
         and VDA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
         and ( (   VDA.DOC_POSITION_ID is not null
                or VDA.DOC_FOOT_CHARGE_ID is not null) )
         and VDA.DOC_POSITION_ID = POS.DOC_POSITION_ID(+)
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID(+);

    vatCorrection_tuple vatCorrection%rowtype;
  begin
    -- ouverture du curseur sur les détails TVA
    open vatCorrection(aDocumentId);

    fetch vatCorrection
     into vatCorrection_tuple;

    -- pour chaque détail...
    while vatCorrection%found loop
      -- Test sur le genre de montant à retirer
      if    (    vatCorrection_tuple.VDA_ROUND_AMOUNT <> 0
             and aRemoveRound = 1)
         or (    vatCorrection_tuple.VDA_CORR_AMOUNT +
                 vatCorrection_tuple.VDA_CORR_AMOUNT_B +
                 vatCorrection_tuple.VDA_CORR_AMOUNT_E +
                 vatCorrection_tuple.VDA_CORR_AMOUNT_V <> 0
             and aRemoveCorr = 1
            ) then
        -- Suppression de la correction sur les taxes de pieds de document
        if vatCorrection_tuple.DOC_FOOT_CHARGE_ID is not null then
          update DOC_FOOT_CHARGE
             set FCH_VAT_AMOUNT =
                            FCH_VAT_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                             (vatCorrection_tuple.VDA_ROUND_AMOUNT + vatCorrection_tuple.VDA_CORR_AMOUNT
                                             )
               , FCH_VAT_BASE_AMOUNT =
                   FCH_VAT_BASE_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                         (vatCorrection_tuple.VDA_ROUND_AMOUNT_B + vatCorrection_tuple.VDA_CORR_AMOUNT_B
                                         )
               , FCH_VAT_AMOUNT_E =
                      FCH_VAT_AMOUNT_E - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                         (vatCorrection_tuple.VDA_ROUND_AMOUNT_E + vatCorrection_tuple.VDA_CORR_AMOUNT_E
                                         )
               , FCH_VAT_AMOUNT_V =
                      FCH_VAT_AMOUNT_V - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                         (vatCorrection_tuple.VDA_ROUND_AMOUNT_V + vatCorrection_tuple.VDA_CORR_AMOUNT_V
                                         )
               , FCH_INCL_AMOUNT =
                           FCH_INCL_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                             (vatCorrection_tuple.VDA_ROUND_AMOUNT + vatCorrection_tuple.VDA_CORR_AMOUNT
                                             )
               , FCH_INCL_AMOUNT_B =
                     FCH_INCL_AMOUNT_B - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                         (vatCorrection_tuple.VDA_ROUND_AMOUNT_B + vatCorrection_tuple.VDA_CORR_AMOUNT_B
                                         )
               , FCH_INCL_AMOUNT_E =
                     FCH_INCL_AMOUNT_E - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                         (vatCorrection_tuple.VDA_ROUND_AMOUNT_E + vatCorrection_tuple.VDA_CORR_AMOUNT_E
                                         )
               , FCH_INCL_AMOUNT_V =
                     FCH_INCL_AMOUNT_V - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                         (vatCorrection_tuple.VDA_ROUND_AMOUNT_V + vatCorrection_tuple.VDA_CORR_AMOUNT_V
                                         )
           where DOC_FOOT_CHARGE_ID = vatCorrection_tuple.DOC_FOOT_CHARGE_ID;
        -- Suppression de la correction sur les positions de document
        elsif vatCorrection_tuple.DOC_POSITION_ID is not null then
          -- positions en mode TTC
          if vatCorrection_tuple.GAP_INCLUDE_TAX_TARIFF = 1 then
            update DOC_POSITION
               set POS_VAT_AMOUNT = POS_VAT_AMOUNT - vatCorrection_tuple.VDA_ROUND_AMOUNT - vatCorrection_tuple.VDA_CORR_AMOUNT
                 , POS_VAT_BASE_AMOUNT = POS_VAT_BASE_AMOUNT - vatCorrection_tuple.VDA_ROUND_AMOUNT_B - vatCorrection_tuple.VDA_CORR_AMOUNT_B
                 , POS_VAT_AMOUNT_E = POS_VAT_AMOUNT_E - vatCorrection_tuple.VDA_ROUND_AMOUNT_E - vatCorrection_tuple.VDA_CORR_AMOUNT_E
                 , POS_VAT_AMOUNT_V = POS_VAT_AMOUNT_V - vatCorrection_tuple.VDA_ROUND_AMOUNT_V - vatCorrection_tuple.VDA_CORR_AMOUNT_V
                 , POS_NET_VALUE_EXCL = POS_NET_VALUE_EXCL + vatCorrection_tuple.VDA_ROUND_AMOUNT + vatCorrection_tuple.VDA_CORR_AMOUNT
                 , POS_NET_VALUE_EXCL_B = POS_NET_VALUE_EXCL_B + vatCorrection_tuple.VDA_ROUND_AMOUNT_B + vatCorrection_tuple.VDA_CORR_AMOUNT_B
                 , POS_NET_VALUE_EXCL_E = POS_NET_VALUE_EXCL_E + vatCorrection_tuple.VDA_ROUND_AMOUNT_E + vatCorrection_tuple.VDA_CORR_AMOUNT_E
                 , POS_NET_VALUE_EXCL_V = POS_NET_VALUE_EXCL_V + vatCorrection_tuple.VDA_ROUND_AMOUNT_V + vatCorrection_tuple.VDA_CORR_AMOUNT_V
                 , POS_NET_UNIT_VALUE =
                     (POS_NET_VALUE_EXCL + vatCorrection_tuple.VDA_ROUND_AMOUNT + vatCorrection_tuple.VDA_CORR_AMOUNT) /
                     decode(vatCorrection_tuple.GAP_VALUE_QUANTITY, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
             where DOC_POSITION_ID = vatCorrection_tuple.DOC_POSITION_ID
               and decode(vatCorrection_tuple.GAP_VALUE_QUANTITY, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY) <> 0;
          -- positions en mode HT
          else
            update DOC_POSITION
               set POS_VAT_AMOUNT = POS_VAT_AMOUNT - vatCorrection_tuple.VDA_ROUND_AMOUNT - vatCorrection_tuple.VDA_CORR_AMOUNT
                 , POS_VAT_BASE_AMOUNT = POS_VAT_BASE_AMOUNT - vatCorrection_tuple.VDA_ROUND_AMOUNT_B - vatCorrection_tuple.VDA_CORR_AMOUNT_B
                 , POS_VAT_AMOUNT_E = POS_VAT_AMOUNT_E - vatCorrection_tuple.VDA_ROUND_AMOUNT_E - vatCorrection_tuple.VDA_CORR_AMOUNT_E
                 , POS_VAT_AMOUNT_V = POS_VAT_AMOUNT_V - vatCorrection_tuple.VDA_ROUND_AMOUNT_V - vatCorrection_tuple.VDA_CORR_AMOUNT_V
                 , POS_NET_VALUE_INCL = POS_NET_VALUE_INCL - vatCorrection_tuple.VDA_ROUND_AMOUNT - vatCorrection_tuple.VDA_CORR_AMOUNT
                 , POS_NET_VALUE_INCL_B = POS_NET_VALUE_INCL_B - vatCorrection_tuple.VDA_ROUND_AMOUNT_B - vatCorrection_tuple.VDA_CORR_AMOUNT_B
                 , POS_NET_VALUE_INCL_E = POS_NET_VALUE_INCL_E - vatCorrection_tuple.VDA_ROUND_AMOUNT_E - vatCorrection_tuple.VDA_CORR_AMOUNT_E
                 , POS_NET_VALUE_INCL_V = POS_NET_VALUE_INCL_V - vatCorrection_tuple.VDA_ROUND_AMOUNT_V - vatCorrection_tuple.VDA_CORR_AMOUNT_V
                 , POS_NET_UNIT_VALUE =
                     (POS_NET_VALUE_INCL - vatCorrection_tuple.VDA_ROUND_AMOUNT - vatCorrection_tuple.VDA_CORR_AMOUNT) /
                     decode(vatCorrection_tuple.GAP_VALUE_QUANTITY, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
             where DOC_POSITION_ID = vatCorrection_tuple.DOC_POSITION_ID
               and decode(vatCorrection_tuple.GAP_VALUE_QUANTITY, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY) <> 0;
          end if;
        end if;

        -- Supression des valeurs dans les détails TVA
        -- Maj du montant soumis uniquement en mode TTC
        -- Cette opération doit obligatoirement figurer à la fin du traîtement
        -- sinon on a des conflits avec les triggers
        update DOC_VAT_DET_ACCOUNT VDA
           set VDA.VDA_ROUND_AMOUNT = 0
             , VDA.VDA_LIABLE_AMOUNT =
                             VDA.VDA_LIABLE_AMOUNT + decode(vatCorrection_tuple.GAP_INCLUDE_TAX_TARIFF
                                                          , 1, nvl(VDA_ROUND_AMOUNT, 0) + nvl(VDA_CORR_AMOUNT, 0)
                                                          , 0
                                                           )
             , VDA.VDA_LIABLE_AMOUNT_B =
                  VDA.VDA_LIABLE_AMOUNT_B + decode(vatCorrection_tuple.GAP_INCLUDE_TAX_TARIFF
                                                 , 1, vatCorrection_tuple.VDA_ROUND_AMOUNT_B + VDA_CORR_AMOUNT_B
                                                 , 0
                                                  )
             , VDA.VDA_LIABLE_AMOUNT_E =
                  VDA.VDA_LIABLE_AMOUNT_E + decode(vatCorrection_tuple.GAP_INCLUDE_TAX_TARIFF
                                                 , 1, vatCorrection_tuple.VDA_ROUND_AMOUNT_E + VDA_CORR_AMOUNT_E
                                                 , 0
                                                  )
             , VDA.VDA_LIABLE_AMOUNT_V =
                  VDA.VDA_LIABLE_AMOUNT_V + decode(vatCorrection_tuple.GAP_INCLUDE_TAX_TARIFF
                                                 , 1, vatCorrection_tuple.VDA_ROUND_AMOUNT_V + VDA_CORR_AMOUNT_V
                                                 , 0
                                                  )
             , VDA.VDA_VAT_AMOUNT = VDA.VDA_VAT_AMOUNT - nvl(VDA_ROUND_AMOUNT, 0) - nvl(VDA_CORR_AMOUNT, 0)
             , VDA.VDA_VAT_BASE_AMOUNT = VDA.VDA_VAT_BASE_AMOUNT - vatCorrection_tuple.VDA_ROUND_AMOUNT_B - VDA_CORR_AMOUNT_B
             , VDA.VDA_VAT_AMOUNT_E = VDA.VDA_VAT_AMOUNT_E - vatCorrection_tuple.VDA_ROUND_AMOUNT_E - VDA_CORR_AMOUNT_E
             , VDA.VDA_VAT_AMOUNT_V = VDA.VDA_VAT_AMOUNT_V - vatCorrection_tuple.VDA_ROUND_AMOUNT_V - VDA_CORR_AMOUNT_V
             , VDA.DOC_POSITION_ID = null
             , VDA.DOC_FOOT_CHARGE_ID = null
         where VDA.DOC_VAT_DET_ACCOUNT_ID = vatCorrection_tuple.DOC_VAT_DET_ACCOUNT_ID;
      end if;

      -- détail suivant
      fetch vatCorrection
       into vatCorrection_tuple;
    end loop;

    close vatCorrection;
  end RemoveVatCorrectionAmount;

  procedure ConvertAllInDocuments
  is
    cursor inDocuments
    is
      select doc_document_id
        from doc_document
       where acs_function.isFinCurrInEuro(acs_financial_currency_id, sysdate) = 1;

    documentId number(12);
  begin
    open inDocuments;

    fetch inDocuments
     into documentId;

    while inDocuments%found loop
      ConvertInDocument(documentId);

      fetch inDocuments
       into documentId;
    end loop;

    close inDocuments;
  end;

  procedure ConvertInDocument(aDocumentId in number)
  is
    euroRate      acs_financial_currency.fin_euro_rate%type;
    total_eur     doc_foot.foo_document_total_amount%type;
    total_vat_eur doc_foot.foo_total_vat_amount%type;
    parity_total  doc_foot.foo_document_total_amount%type;
    parity_vat    doc_foot.foo_total_vat_amount%type;
    parity_id     number(12);
    totalModified number(1);
  begin
    if acs_function.getEuroCurrency <> acs_function.getLocalCurrencyId then
      raise_application_error(-20080, 'PCS - This package can''t be used if EURO is not local currency. Work with package "DOC_CONVERT_IN_DOCS_TO_EURO".');
    end if;

    -- recherche du cours par rapport à l'euro
    select cur.fin_euro_rate
      into euroRate
      from doc_document dmt
         , acs_financial_currency cur
     where cur.acs_financial_currency_id = dmt.acs_financial_currency_id
       and dmt.doc_document_id = aDocumentId;

    RemoveVatCorrectionAmount(aDocumentId, 1, 0);

    -- mise à jour de l'id de la monnaie du document
    update doc_document
       set acs_financial_currency_id = acs_function.GetEuroCurrency
         , dmt_rate_of_exchange = 0
         , dmt_base_price = 0
         , dmt_rate_euro = 0
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_document_id = aDocumentId;

    -- conversion de doc_position et des tables liées
    ConvertInPositionsDocument(aDocumentId, euroRate);
    -- conversion des remises/taxes de pied
    ConvertInFootCharges(aDocumentId, euroRate);
    -- recalcul des totaux du document
    doc_functions.UpdateFootTotals(aDocumentId, totalModified);
    ConvertInPaymentDate(aDocumentId, euroRate);

    -- conversion du montant de correction
    update DOC_VAT_DET_ACCOUNT
       set VDA_CORR_AMOUNT = acs_function.roundnear(VDA_CORR_AMOUNT_E, 0.01)
     where DOC_FOOT_ID = aDocumentId;

    -- mise à jour de la monnaie du document
    -- marque le document comme étant traité
    update doc_document
       set acs_financial_currency_id = acs_function.getEuroCurrency
         , a_recstatus = 4
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_document_id = aDocumentId;
  end;

  procedure ConvertInPositionsDocument(aDocumentId in number, aEuroRate in number)
  is
    cursor inPositions(documentId number)
    is
      select doc_position_id
        from doc_position
       where doc_document_id = documentId;

    positionId number(12);
  begin
    open inPositions(aDocumentId);

    fetch inPositions
     into positionId;

    while inPositions%found loop
      ConvertInPositionCharges(positionId, aEuroRate);

      -- conversion des montants de position
      update doc_position
         set pos_discount_amount = acs_function.roundnear(pos_discount_amount / aEuroRate, 0.01)
           , pos_charge_amount = acs_function.roundnear(pos_charge_amount / aEuroRate, 0.01)
           , pos_gross_unit_value = pos_gross_value_b / decode(pos_basis_quantity, 0, 1, pos_basis_quantity)
           , pos_gross_unit_value_incl = pos_gross_value_incl_b / decode(pos_basis_quantity, 0, 1, pos_basis_quantity)
           , pos_net_unit_value = pos_net_value_excl_b / decode(pos_basis_quantity, 0, 1, pos_basis_quantity)
           , pos_net_unit_value_incl = pos_net_value_incl_b / decode(pos_basis_quantity, 0, 1, pos_basis_quantity)
           , pos_ref_unit_value = acs_function.roundnear(pos_ref_unit_value / aEuroRate, 0.01)
           , pos_gross_value = pos_gross_value_b
           , pos_gross_value_incl = pos_gross_value_incl_b
           , pos_net_value_excl = pos_net_value_excl_b
           , pos_net_value_incl = pos_net_value_incl_b
           , pos_vat_amount = pos_net_value_incl_b - pos_net_value_excl_b
           ,
             --pos_vat_amount            = pos_vat_base_amount,
             a_datemod = sysdate
           , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
       where doc_position_id = positionId;

      fetch inPositions
       into positionId;
    end loop;

    close inPositions;
  end;

  procedure ConvertInPositionCharges(aPositionId in number, aEuroRate in number)
  is
  begin
    -- mise à jour des remises/taxes de position
    update doc_position_charge
       set pch_amount = pch_amount_b
         , pch_calc_amount = pch_calc_amount_b
         , pch_liabled_amount = pch_liabled_amount_b
         , pch_fixed_amount = pch_fixed_amount_b
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_position_id = aPositionId;
  end;

  procedure ConvertInFootCharges(aDocumentId in number, aEuroRate in number)
  is
  begin
    -- mise à jour des remises/taxes de pied
    update doc_foot_charge
       set fch_incl_amount = fch_incl_amount_b
         , fch_excl_amount = fch_excl_amount_b
         ,
           --fch_vat_amount      = fch_vat_base_amount,
           fch_vat_amount = fch_incl_amount_b - fch_excl_amount_b
         , fch_calc_amount = fch_calc_amount_b
         , fch_liabled_amount = fch_liabled_amount_b
         , fch_fixed_amount = fch_fixed_amount_b
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_foot_id = aDocumentId;
  end;

  procedure ConvertInPaymentDate(aDocumentId in number, aEuroRate in number)
  is
  begin
    -- mise à jour du montant brut et de l'escompte
    update doc_payment_date
       set pad_date_amount = pad_date_amount_b
         , pad_discount_amount = pad_discount_amount_b
         , pad_net_date_amount = pad_net_date_amount_b
         , pad_amount_prov_fc = pad_amount_prov_lc
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_foot_id = aDocumentId;
  end;
end DOC_CONVERT_IN_DOCS_TO_EURO_MB;
