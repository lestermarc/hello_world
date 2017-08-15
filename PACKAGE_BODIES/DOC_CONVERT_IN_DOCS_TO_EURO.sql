--------------------------------------------------------
--  DDL for Package Body DOC_CONVERT_IN_DOCS_TO_EURO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_CONVERT_IN_DOCS_TO_EURO" 
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
  end ConvertAllInDocuments;

  /**
  * Description
  *        conversion d'un documents en monnaie IN
  */
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
    if acs_function.getEuroCurrency = acs_function.getLocalCurrencyId then
      raise_application_error(-20080, 'PCS - This package can''t be used if EURO is local currency. Work with package "DOC_CONVERT_IN_DOCS_TO_EURO_MB".');
    end if;

    RemoveVatCorrectionAmount(aDocumentId, 1, 0);

    -- recherche du cours par rapport à l'euro
    select cur.fin_euro_rate
      into euroRate
      from doc_document dmt
         , acs_financial_currency cur
     where cur.acs_financial_currency_id = dmt.acs_financial_currency_id
       and dmt.doc_document_id = aDocumentId;

    -- mise à jour de l'id de la monnaie du document
    update doc_document
       set acs_financial_currency_id = acs_function.GetEuroCurrency
         , dmt_rate_euro = 0
     where doc_document_id = aDocumentId;

    -- stockage des totaux (document et TVA)
    select acs_function.RoundNear(foo_document_total_amount / euroRate, 0.01)
         , acs_function.RoundNear(foo_total_vat_amount / euroRate, 0.01)
      into total_eur
         , total_vat_eur
      from doc_foot
     where doc_foot_id = aDocumentId;

    -- conversion de doc_position et des tables liées
    ConvertInPositionsDocument(aDocumentId, euroRate);
    -- conversion des remises/taxes de pied
    ConvertInFootCharges(aDocumentId, euroRate);
    -- recalcul des totaux du document
    doc_functions.UpdateFootTotals(aDocumentId, totalModified);
    ConvertInPaymentDate(aDocumentId, total_eur, euroRate);

    -- conversion du montant de correction
    update DOC_VAT_DET_ACCOUNT
       set VDA_CORR_AMOUNT = acs_function.roundnear(VDA_CORR_AMOUNT / euroRate, 0.01)
     where DOC_FOOT_ID = aDocumentId;

    -- comparaison des montants
    select foo_document_total_amount - total_eur
      into parity_total
      from doc_foot
     where doc_foot_id = aDocumentId;

    -- si la parité n'est pas respectée sur le total du document
    if parity_total <> 0 then
      -- recherche de la position à adapter
      select max(doc_position_id)
        into parity_id
        from doc_position
       where doc_document_id = aDocumentId
         and c_doc_pos_status <> '05'
         and abs(pos_net_value_incl) = (select max(abs(pos_net_value_incl) )
                                          from doc_position
                                         where doc_document_id = aDocumentId
                                           and c_doc_pos_status <> '05');

      -- si position trouvée
      if parity_id is not null then
        update doc_position
           set pos_net_value_incl = pos_net_value_incl - parity_total
             , pos_net_value_excl = pos_net_value_excl - parity_total
             , pos_gross_value = decode(pos_include_tax_tariff, 0, pos_gross_value - parity_total, pos_gross_value)
             , a_recstatus = nvl(a_recstatus, 0) + 1
         where doc_position_id = parity_id;
      else
        -- si position non trouvée, recherche d'une remise/taxe de pied
        select max(doc_foot_charge_id)
          into parity_id
          from doc_foot_charge
         where doc_foot_id = aDocumentId
           and abs(fch_incl_amount) = (select max(abs(fch_incl_amount) )
                                         from doc_position
                                        where doc_document_id = aDocumentId);

        if parity_id is not null then
          update doc_foot_charge
             set fch_incl_amount = fch_incl_amount - parity_total
               , fch_excl_amount = fch_excl_amount - parity_total
               , a_recstatus = nvl(a_recstatus, 0) + 1
           where doc_foot_charge_id = parity_id;
        end if;
      end if;

      -- recalcul des totaux du document
      doc_functions.UpdateFootTotals(aDocumentId, totalModified);
    end if;

    select foo_total_vat_amount - total_vat_eur
      into parity_vat
      from doc_foot
     where doc_foot_id = aDocumentId;

    -- comparaison des totaux TVA
    if parity_vat <> 0 then
      -- recherche de la position à adapter
      select max(doc_position_id)
        into parity_id
        from doc_position
       where doc_document_id = aDocumentId
         and c_doc_pos_status <> '05'
         and abs(pos_vat_amount) > 0
         and abs(pos_net_value_incl) = (select max(abs(pos_net_value_incl) )
                                          from doc_position
                                         where doc_document_id = aDocumentId
                                           and c_doc_pos_status <> '05');

      -- si position trouvée
      if parity_id is not null then
        update doc_position
           set pos_vat_amount = pos_vat_amount - parity_vat
             , pos_gross_value = decode(pos_include_tax_tariff, 0, pos_gross_value + parity_vat, pos_gross_value)
             , pos_net_value_excl = pos_net_value_excl + parity_vat
             , a_recstatus = nvl(a_recstatus, 0) + 2
         where doc_position_id = parity_id;
      else
        -- si position non trouvée, recherche d'une remise/taxe de pied
        select max(doc_foot_charge_id)
          into parity_id
          from doc_foot_charge
         where doc_foot_id = aDocumentId
           and abs(fch_incl_amount) = (select max(abs(fch_incl_amount) )
                                         from doc_position
                                        where doc_document_id = aDocumentId);

        if parity_id is not null then
          update doc_foot_charge
             set fch_vat_amount = fch_vat_amount - parity_vat
               , fch_excl_amount = fch_excl_amount + parity_vat
               , a_recstatus = nvl(a_recstatus, 0) + 2
           where doc_foot_charge_id = parity_id;
        end if;
      end if;

      -- recalcul des totaux du document
      doc_functions.UpdateFootTotals(aDocumentId, totalModified);
    end if;

    -- à nouveau comparaison des totaux document  (arrêt du traitement si problèmes)
    select foo_document_total_amount - total_eur
      into parity_total
      from doc_foot
     where doc_foot_id = aDocumentId;

    if parity_total <> 0 then
      raise_application_error(-20000, 'parité total document pas OK : ' || to_char(parity_total) );
    end if;

    -- à nouveau comparaison des totaux tva  (arrêt du traitement si problèmes)
    select foo_total_vat_amount - total_vat_eur
      into parity_vat
      from doc_foot
     where doc_foot_id = aDocumentId;

    if parity_vat <> 0 then
      raise_application_error(-20000, 'parité TVA pas OK : ' || to_char(parity_vat) );
    end if;

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
           , pos_gross_unit_value = acs_function.roundnear(pos_gross_unit_value / aEuroRate, 0.01)
           , pos_gross_unit_value_incl = acs_function.roundnear(pos_gross_unit_value_incl / aEuroRate, 0.01)
           , pos_net_unit_value = acs_function.roundnear(pos_net_unit_value / aEuroRate, 0.01)
           , pos_net_unit_value_incl = acs_function.roundnear(pos_net_unit_value_incl / aEuroRate, 0.01)
           , pos_ref_unit_value = acs_function.roundnear(pos_ref_unit_value / aEuroRate, 0.01)
           , pos_gross_value = acs_function.roundnear(pos_gross_value / aEuroRate, 0.01)
           , pos_gross_value_incl = acs_function.roundnear(pos_gross_value_incl / aEuroRate, 0.01)
           , pos_net_value_excl = acs_function.roundnear(pos_net_value_excl / aEuroRate, 0.01)
           , pos_net_value_incl = acs_function.roundnear(pos_net_value_incl / aEuroRate, 0.01)
           , pos_vat_amount = acs_function.roundnear(pos_net_value_incl / aEuroRate, 0.01) - acs_function.roundnear(pos_net_value_excl / aEuroRate, 0.01)
           , a_datemod = sysdate
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
       set pch_amount = acs_function.roundnear(pch_amount / aEuroRate, 0.01)
         , pch_calc_amount = acs_function.roundnear(pch_calc_amount / aEuroRate, 0.01)
         , pch_liabled_amount = acs_function.roundnear(pch_liabled_amount / aEuroRate, 0.01)
         , pch_fixed_amount = acs_function.roundnear(pch_fixed_amount / aEuroRate, 0.01)
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_position_id = aPositionId;
  end;

  procedure ConvertInFootCharges(aDocumentId in number, aEuroRate in number)
  is
  begin
    -- mise à jour des remises/taxes de pied
    update doc_foot_charge
       set fch_incl_amount = acs_function.roundnear(fch_incl_amount / aEuroRate, 0.01)
         , fch_excl_amount = acs_function.roundnear(fch_excl_amount / aEuroRate, 0.01)
         , fch_vat_amount = acs_function.roundnear(fch_incl_amount / aEuroRate, 0.01) - acs_function.roundnear(fch_excl_amount / aEuroRate, 0.01)
         , fch_calc_amount = acs_function.roundnear(fch_calc_amount / aEuroRate, 0.01)
         , fch_liabled_amount = acs_function.roundnear(fch_liabled_amount / aEuroRate, 0.01)
         , fch_fixed_amount = acs_function.roundnear(fch_fixed_amount / aEuroRate, 0.01)
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_foot_id = aDocumentId;
  end;

  procedure ConvertInPaymentDate(aDocumentId in number, aDocumentTotal in number, aEuroRate in number)
  is
    parityId     number(12);
    parityAmount doc_payment_date.pad_date_amount%type;
  begin
    -- mise à jour du montant brut et de l'escompte
    update doc_payment_date
       set pad_date_amount = acs_function.roundnear(pad_date_amount / aEuroRate, 0.01)
         , pad_discount_amount = acs_function.roundnear(pad_discount_amount / aEuroRate, 0.01)
         ,
           --          pad_net_date_amount = acs_function.roundnear(pad_net_date_amount/aEuroRate,0.01),
           pad_amount_prov_fc = acs_function.roundnear(pad_amount_prov_fc / aEuroRate, 0.01)
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_foot_id = aDocumentId;

    select sum(pad_date_amount)
      into parityAmount
      from doc_payment_date
     where pad_net = 1;

    -- controle de parité entre le total du document et le total des tranches
    if parityAmount <> aDocumentTotal then
      update doc_payment_date
         set pad_date_amount = pad_date_amount + aDocumentTotal - parityAmount
           , a_datemod = sysdate
           , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
       where doc_foot_id = aDocumentId
         and pad_band_number = (select max(pad_band_number)
                                  from doc_payment_date
                                 where doc_foot_id = aDocumentId);
    end if;

    -- mise à jour des montants nets
    update doc_payment_date
       set pad_net_date_amount = pad_date_amount - pad_discount_amount
         , a_datemod = sysdate
         , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_foot_id = aDocumentId;
  end;
end DOC_CONVERT_IN_DOCS_TO_EURO;
