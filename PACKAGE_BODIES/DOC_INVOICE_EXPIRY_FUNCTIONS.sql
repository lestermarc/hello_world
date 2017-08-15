--------------------------------------------------------
--  DDL for Package Body DOC_INVOICE_EXPIRY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INVOICE_EXPIRY_FUNCTIONS" 
is
  gCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type;
  gCashFlowSelComName PCS.PC_COMP.COM_NAME%type;

  /**
  * function pIsDetail
  * Description
  *    Indique si une échéance a des détails
  * @created fp 21.05.2008
  * @lastUpdate
  * @public
  * @param aInvoiceExpiryId
  * @return 1 si des détails sont trouvés
  */
  function pIsDetail(aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return number
  is
    vIsDetail number(1);
  begin
    -- recherche s'il y a des détail d'échéancier
    select sign(count(*) )
      into vIsDetail
      from DOC_INVOICE_EXPIRY_DETAIL
     where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

    return vIsDetail;
  end pIsDetail;

  /**
  * Description
  *    Applique la bonne méthode d'arrondi
  */
  function RoundInvoiceAmount(
    aAmount          in DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type
  , aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  )
    return DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type
  is
    vResult DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type;
  begin
    -- une seule passe
    for tplRound in (select INX.C_ROUND_TYPE INX_ROUND_TYPE
                          , INX.INX_ROUND_AMOUNT
                          , GAS.C_ROUND_TYPE GAS_ROUND_TYPE
                          , GAS.GAS_ROUND_AMOUNT
                          , GAP.C_ROUND_APPLICATION
                          , DMT.ACS_FINANCIAL_CURRENCY_ID
                       from DOC_INVOICE_EXPIRY INX
                          , DOC_GAUGE_STRUCTURED GAS
                          , DOC_GAUGE_POSITION GAP
                          , DOC_DOCUMENT DMT
                      where INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                        and GAS.DOC_GAUGE_ID = INX.DOC_GAUGE_ID
                        and DMT.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
                        and GAP.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                        and GAP.C_GAUGE_TYPE_POS = '1'
                        and GAP.GAP_DEFAULT = 1) loop
      vResult  := ACS_FUNCTION.PcsRound(aAmount, tplRound.INX_ROUND_TYPE, tplRound.INX_ROUND_AMOUNT);
      vResult  :=
        DOC_POSITION_FUNCTIONS.roundPositionAmount(vResult
                                                 , tplRound.ACS_FINANCIAL_CURRENCY_ID
                                                 , tplRound.C_ROUND_APPLICATION
                                                 , '0'
                                                 , 0
                                                 , tplRound.GAS_ROUND_TYPE
                                                 , tplRound.GAS_ROUND_AMOUNT
                                                  );
    end loop;

    return vResult;
  end RoundInvoiceAmount;

  /**
  * procedure pGetTotBalanceDepositAmount
  * Description
  *    Retourne de montant total de solde d'accompte
  * @created fp 27.10.2006
  * @lastUpdate
  * @private
  * @param aDocumentId : id du document
  * @param aSliceRetNetAmountExcl out : montant net HT
  * @param aSliceRetNetAmountExcl_b out : montant net HT monnaie de base
  * @param aSliceRetNetAmountIncl out : montant net TTC
  * @param aSliceRetNetAmountIncl_b out : montant net TTC monnaie de base
  */
  procedure pGetTotBalanceDepositAmount(
    aDocumentId                  DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSliceRetNetAmountExcl   out DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type
  , aSliceRetNetAmountExcl_b out DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL_B%type
  , aSliceRetNetAmountIncl   out DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_INCL%type
  , aSliceRetNetAmountIncl_b out DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_INCL_B%type
  )
  is
  begin
    select sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '1', INX_NET_VALUE_EXCL, '5', -INX_NET_VALUE_EXCL, 0) ) -
           sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '2', INX_RET_DEPOSIT_NET_EXCL, 0) )
         , sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '1', INX_NET_VALUE_EXCL_B, '5', -INX_NET_VALUE_EXCL_B, 0) ) -
           sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '2', INX_RET_DEPOSIT_NET_EXCL_B, 0) )
         , sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '1', INX_NET_VALUE_INCL, '5', -INX_NET_VALUE_INCL, 0) ) -
           sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '2', INX_RET_DEPOSIT_NET_INCL, 0) )
         , sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '1', INX_NET_VALUE_INCL_B, '5', -INX_NET_VALUE_INCL_B, 0) ) -
           sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '2', INX_RET_DEPOSIT_NET_INCL_B, 0) )
      into aSliceRetNetAmountExcl
         , aSliceRetNetAmountExcl_b
         , aSliceRetNetAmountIncl
         , aSliceRetNetAmountIncl_b
      from DOC_INVOICE_EXPIRY INX
     where INX.DOC_DOCUMENT_ID = aDocumentId
       and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '2', '5');
  end pGetTotBalanceDepositAmount;

  /**
  * Description
  *    Création de l'échéancier d'un document
  */
  procedure createDocumentBillBook(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aForce in number default 0)
  is
    -- curseur sur les conditions de paiement échéancier
    cursor crDocPaymentCondition(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aForce number)
    is
      select   CDE.CDE_PART
             , CDE.CDE_ACCOUNT
             , CDE.DOC_GAUGE_ID
             , CDE.GCO_GOOD_ID
             , CDE.CDE_DAY
             , CDE.C_CALC_METHOD
             , CDE.C_TIME_UNIT
             , CDE.CDE_END_MONTH
             , CDE.C_INVOICE_EXPIRY_DOC_TYPE
             , CDE.PAC_PAC_PAYMENT_CONDITION_ID
             , nvl(CDE.C_ROUND_TYPE, '0') CDE_ROUND_TYPE
             , nvl(CDE.CDE_ROUND_AMOUNT, 0) CDE_ROUND_AMOUNT
             , CDE_AMOUNT_LC
             , GCO_FUNCTIONS.GetDescription2(CDE.GCO_GOOD_ID, DMT.PC_LANG_ID, 1, '01') DES_SHORT_DESCRIPTION
             , GCO_FUNCTIONS.GetDescription2(CDE.GCO_GOOD_ID, DMT.PC_LANG_ID, 2, '01') DES_LONG_DESCRIPTION
             , FOO_GOOD_TOT_AMOUNT_EXCL FOO_DOC_TOTAL_AMOUNT_EXCL
             , FOO_GOOD_TOT_AMOUNT_EX_B FOO_DOC_TOTAL_AMOUNT_EXCL_B
             , 0 FOO_GOOD_TOTAL_AMOUNT_EXCL   -- FOO.FOO_GOOD_TOTAL_AMOUNT_EXCL, mais ce champ n'existe pas
             , 0 FOO_GOOD_TOTAL_AMOUNT_EXCL_B   -- FOO.FOO_GOOD_TOT_AMOUNT_EXCL B, mais ce champ n'existe pas
             , GAS.C_ROUND_TYPE GAS_ROUND_TYPE
             , GAS.GAS_ROUND_AMOUNT
             , GAP.C_ROUND_APPLICATION
             , DMT.ACS_FINANCIAL_CURRENCY_ID
             , DMT.DMT_DATE_DOCUMENT
             , DMT.DMT_TARIFF_DATE
             , DMT.PAC_THIRD_ID
          from DOC_DOCUMENT DMT
             , DOC_FOOT FOO
             , PAC_PAYMENT_CONDITION PAD
             , PAC_CONDITION_DETAIL CDE
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
         where DMT.DOC_DOCUMENT_ID = aDocumentId
           and DMT.DMT_INVOICE_EXPIRY = 1
           and DMT.DMT_CREATE_INVOICE_EXPIRY = 1
           and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and PAD.PAC_PAYMENT_CONDITION_ID = DMT.PAC_PAYMENT_CONDITION_ID
           and PAD.C_PAYMENT_CONDITION_KIND = '02'
           and CDE.PAC_PAYMENT_CONDITION_ID = PAD.PAC_PAYMENT_CONDITION_ID
           and GAS.DOC_GAUGE_ID = CDE.DOC_GAUGE_ID
           and GAP.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and GAP.C_GAUGE_TYPE_POS = '1'
           and GAP.GAP_DEFAULT = 1
      order by decode(C_INVOICE_EXPIRY_DOC_TYPE, '3', 1, 0)   -- la facture finale doit être traitée en dernier
             , CDE.CDE_DAY
             , CDE.CDE_PART;

    vDocNetTotalAmountExcl    DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotalAmountExcl_b  DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vDocNetTotalAmountIncl    DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotalAmountIncl_b  DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vDocNetTotAmountAddExcl   DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotAmountAddExcl_b DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vDocNetTotAmountAddIncl   DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotAmountAddIncl_b DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vSliceRetNetAmountExcl    DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
    vSliceRetNetAmountExcl_b  DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL_B%type;
    vSliceRetNetAmountIncl    DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_INCL%type;
    vSliceRetNetAmountIncl_b  DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_INCL_B%type;
    vSliceNetAmountExcl       DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type           := 0;
    vSliceNetAmountExcl_b     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL_B%type         := 0;
    vSliceNetAmountIncl       DOC_INVOICE_EXPIRY.INX_NET_VALUE_INCL%type           := 0;
    vSliceNetAmountIncl_b     DOC_INVOICE_EXPIRY.INX_NET_VALUE_INCL_B%type         := 0;
    vDefNetTotalAmount        DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDefNetTotalAmount_b      DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vInputType                DOC_DOCUMENT.C_INVOICE_EXPIRY_INPUT_TYPE%type;
    vTotalProportion          PAC_CONDITION_DETAIL.CDE_ACCOUNT%type;
    vCorrectionId             DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    vRoundType                DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type;
    vRoundAmount              DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type;
    vNbPosLinked              pls_integer;
    vNbPosLinkable            pls_integer;
  begin
    -- recherche du total des proportions
    select sum(CDE_ACCOUNT)
         , max(GAS.C_ROUND_TYPE)
         , max(GAS_ROUND_AMOUNT)
         , max(FOO_GOOD_TOT_AMOUNT_EXCL)
         , max(FOO_GOOD_TOT_AMOUNT_EX_B)
         , max(C_INVOICE_EXPIRY_INPUT_TYPE)
      into vTotalProportion
         , vRoundType
         , vRoundAmount
         , vDocNetTotalAmountExcl
         , vDocNetTotalAmountExcl_b
         , vInputType
      from DOC_DOCUMENT DMT
         , PAC_CONDITION_DETAIL PAD
         , DOC_GAUGE_STRUCTURED GAS
         , DOC_FOOT FOO
     where DMT.DOC_DOCUMENT_Id = aDocumentId
       and PAD.PAC_PAYMENT_CONDITION_ID = DMT.PAC_PAYMENT_CONDITION_ID
       and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID;

    -- suppression des anciennes échéances
    if aForce = 1 then
      delete from DOC_INVOICE_EXPIRY
            where DOC_DOCUMENT_Id = aDocumentId;

      update DOC_DOCUMENT
         set DMT_CREATE_INVOICE_EXPIRY = (select GAS_INVOICE_EXPIRY
                                            from DOC_GAUGE_STRUCTURED
                                           where DOC_GAUGE_ID = DOC_DOCUMENT.DOC_GAUGE_ID)
       where DOC_DOCUMENT_ID = aDocumentId;
    end if;

    for tplDocPaymentCondition in crDocPaymentCondition(aDocumentId, aForce) loop
      declare
        vProportion         number;
        vDateCalculated     date;
        vDateAdapted        date;
        vPaymentConditionId PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
      begin
        if vInputType = '1' then
          if tplDocPaymentCondition.C_INVOICE_EXPIRY_DOC_TYPE in('3') then
            -- calcul de la tranche "Facture finale par différence
            vSliceNetAmountExcl    := vDocNetTotalAmountExcl - nvl(vDefNetTotalAmount, 0);
            vSliceNetAmountExcl_b  := vDocNetTotalAmountExcl_b - nvl(vDefNetTotalAmount_b, 0);
            vProportion            := tplDocPaymentCondition.CDE_ACCOUNT;
          elsif tplDocPaymentCondition.CDE_AMOUNT_LC is not null then
            -- tranche NET HT en monnaie de base
            vSliceNetAmountExcl_b  := tplDocPaymentCondition.CDE_AMOUNT_LC;

            -- calcul du montant de tranche NET HT en monnaie document
            if tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId then
              vSliceNetAmountExcl  :=
                ACS_FUNCTION.ConvertAmountForView(vSliceNetAmountExcl_b
                                                , tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID
                                                , ACS_FUNCTION.GetLocalCurrencyId
                                                , nvl(tplDocPaymentCondition.DMT_TARIFF_DATE, tplDocPaymentCondition.DMT_DATE_DOCUMENT)
                                                , 0
                                                , 0
                                                , 0
                                                , 5
                                                 );   -- Cours logistique
            else
              vSliceNetAmountExcl  := vSliceNetAmountExcl_b;
            end if;
          else
            vProportion            := tplDocPaymentCondition.CDE_ACCOUNT;
            -- calcul du montant de tranche NET HT
            -- arrondi du montant selon règles gabarit cible
            vSliceNetAmountExcl    :=
              ACS_FUNCTION.PCSRound(tplDocPaymentCondition.FOO_DOC_TOTAL_AMOUNT_EXCL * tplDocPaymentCondition.CDE_ACCOUNT / vTotalProportion
                                  , tplDocPaymentCondition.CDE_ROUND_TYPE
                                  , tplDocPaymentCondition.CDE_ROUND_AMOUNT
                                   );
            vSliceNetAmountExcl    :=
              DOC_POSITION_FUNCTIONS.roundPositionAmount(vSliceNetAmountExcl
                                                       , tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID
                                                       , tplDocPaymentCondition.C_ROUND_APPLICATION
                                                       , '0'
                                                       , 0
                                                       , tplDocPaymentCondition.GAS_ROUND_TYPE
                                                       , tplDocPaymentCondition.GAS_ROUND_AMOUNT
                                                        );
            -- calcul du montant de tranche NET HT en monnaie de base
            vSliceNetAmountExcl_b  :=
              ACS_FUNCTION.ConvertAmountForView(vSliceNetAmountExcl
                                              , ACS_FUNCTION.GetLocalCurrencyId
                                              , tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID
                                              , nvl(tplDocPaymentCondition.DMT_TARIFF_DATE, tplDocPaymentCondition.DMT_DATE_DOCUMENT)
                                              , 0
                                              , 0
                                              , 0
                                              , 5
                                               );   -- Cours logistique
          --vSliceNetAmountIncl     pas calculable de façon simple (sans pertes de performance notables)
          --vSliceNetAmountIncl_b   pas calculable de façon simple (sans pertes de performance notables)
          end if;
        elsif vInputType = '2' then
          case
            when tplDocPaymentCondition.C_INVOICE_EXPIRY_DOC_TYPE in('3') then
              -- calcul de la tranche "Facture finale par différence
              vSliceNetAmountExcl    := vDocNetTotalAmountExcl - nvl(vDefNetTotalAmount, 0);
              vSliceNetAmountExcl_b  := vDocNetTotalAmountExcl_b - nvl(vDefNetTotalAmount_b, 0);
              vProportion            := null;
            else
              -- saisie en montants
              if nvl(tplDocPaymentCondition.CDE_ACCOUNT, 0) = 0 then
                -- tranche NET HT en monnaie de base
                vSliceNetAmountExcl_b  := nvl(tplDocPaymentCondition.CDE_AMOUNT_LC, 0);

                -- calcul du montant de tranche NET HT en monnaie document
                if tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId then
                  vSliceNetAmountExcl  :=
                    ACS_FUNCTION.ConvertAmountForView(vSliceNetAmountExcl_b
                                                    , tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID
                                                    , ACS_FUNCTION.GetLocalCurrencyId
                                                    , nvl(tplDocPaymentCondition.DMT_TARIFF_DATE, tplDocPaymentCondition.DMT_DATE_DOCUMENT)
                                                    , 0
                                                    , 0
                                                    , 0
                                                    , 5
                                                     );   -- Cours logistique
                else
                  vSliceNetAmountExcl  := vSliceNetAmountExcl_b;
                end if;
              --vSliceNetAmountIncl     pas calculable de façon simple (sans pertes de performance notables)
              --vSliceNetAmountIncl_b   pas calculable de façon simple (sans pertes de performance notables)
              else
                -- calcul du montant de tranche NET HT
                -- arrondi du montant selon règles gabarit cible
                vSliceNetAmountExcl    :=
                  ACS_FUNCTION.PCSRound(tplDocPaymentCondition.FOO_DOC_TOTAL_AMOUNT_EXCL * tplDocPaymentCondition.CDE_ACCOUNT / 100
                                      , tplDocPaymentCondition.CDE_ROUND_TYPE
                                      , tplDocPaymentCondition.CDE_ROUND_AMOUNT
                                       );
                vSliceNetAmountExcl    :=
                  DOC_POSITION_FUNCTIONS.roundPositionAmount(vSliceNetAmountExcl
                                                           , tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID
                                                           , tplDocPaymentCondition.C_ROUND_APPLICATION
                                                           , '0'
                                                           , 0
                                                           , tplDocPaymentCondition.GAS_ROUND_TYPE
                                                           , tplDocPaymentCondition.GAS_ROUND_AMOUNT
                                                            );
                -- calcul du montant de tranche NET HT en monnaie de base
                vSliceNetAmountExcl_b  :=
                  ACS_FUNCTION.ConvertAmountForView(vSliceNetAmountExcl
                                                  , ACS_FUNCTION.GetLocalCurrencyId
                                                  , tplDocPaymentCondition.ACS_FINANCIAL_CURRENCY_ID
                                                  , nvl(tplDocPaymentCondition.DMT_TARIFF_DATE, tplDocPaymentCondition.DMT_DATE_DOCUMENT)
                                                  , 0
                                                  , 0
                                                  , 0
                                                  , 5
                                                   );   -- Cours logistique
                vProportion            := tplDocPaymentCondition.CDE_ACCOUNT;
              end if;
          end case;
        end if;

        if tplDocPaymentCondition.C_INVOICE_EXPIRY_DOC_TYPE in('3') then
          -- calcul de la tranche "Facture finale par différence
          pGetTotBalanceDepositAmount(aDocumentId, vSliceRetNetAmountExcl, vSliceRetNetAmountExcl_b, vSliceRetNetAmountIncl, vSliceRetNetAmountIncl_b);
        elsif tplDocPaymentCondition.C_INVOICE_EXPIRY_DOC_TYPE in('2') then
          vSliceRetNetAmountExcl    := getGlobalRetDepositAmount(vSliceNetAmountExcl, aDocumentId);
          vSliceRetNetAmountExcl_b  := getGlobalRetDepositAmount(vSliceNetAmountExcl_b, aDocumentId);
          vSliceRetNetAmountIncl    := getGlobalRetDepositAmount(vSliceNetAmountIncl, aDocumentId);
          vSliceRetNetAmountIncl_b  := getGlobalRetDepositAmount(vSliceNetAmountIncl_b, aDocumentId);
        else
          vSliceRetNetAmountExcl    := null;
          vSliceRetNetAmountExcl_b  := null;
          vSliceRetNetAmountIncl    := null;
          vSliceRetNetAmountIncl_b  := null;
        end if;

        if tplDocPaymentCondition.C_INVOICE_EXPIRY_DOC_TYPE in('2') then
          vDefNetTotalAmount    := vDefNetTotalAmount + nvl(vSliceNetAmountExcl, 0);
          vDefNetTotalAmount_b  := vDefNetTotalAmount_b + nvl(vSliceNetAmountExcl_b, 0);
        end if;

        if tplDocPaymentCondition.PAC_PAC_PAYMENT_CONDITION_ID is null then
          vPaymentConditionId  := DOC_DOCUMENT_FUNCTIONS.getPaymentCondition(tplDocPaymentCondition.PAC_THIRD_ID, tplDocPaymentCondition.DOC_GAUGE_ID);
        else
          vPaymentConditionId  := tplDocPaymentCondition.PAC_PAC_PAYMENT_CONDITION_ID;
        end if;

        -- calcul de la date de l'échéance
        ACT_EXPIRY_MANAGEMENT.CalcDatesOfExpiry(tplDocPaymentCondition.DMT_DATE_DOCUMENT
                                              , tplDocPaymentCondition.CDE_DAY
                                              , tplDocPaymentCondition.CDE_END_MONTH
                                              , tplDocPaymentCondition.C_CALC_METHOD
                                              , tplDocPaymentCondition.C_TIME_UNIT
                                              , vDateCalculated
                                              , vDateAdapted
                                               );

        -- cet id correspond à l'id de DOC_INVOICE_EXPIRY_ID et en même temps
        -- représentera une fois sorti de la boucle, l'id de la tranche la plus importante
        select INIT_ID_SEQ.nextval
          into vCorrectionId
          from dual;

        -- insertion dans la table des tranches d'échéancier
        insert into DOC_INVOICE_EXPIRY
                    (DOC_INVOICE_EXPIRY_ID
                   , DOC_DOCUMENT_ID
                   , C_INVOICE_EXPIRY_DOC_TYPE
                   , DOC_GAUGE_ID
                   , INX_SLICE
                   , INX_WORDING
                   , INX_DESCRIPTION
                   , INX_PROPORTION
                   , INX_NET_VALUE_EXCL
                   --, INX_NET_VALUE_EXCL_B
        ,            INX_NET_VALUE_INCL
                   --, INX_NET_VALUE_INCL_B
        ,            INX_RET_DEPOSIT_NET_INCL
                   , INX_RET_DEPOSIT_NET_EXCL
                   --, INX_RET_DEPOSIT_NET_INCL_B
                   --, INX_RET_DEPOSIT_NET_EXCL_B
        ,            C_ROUND_TYPE
                   , INX_ROUND_AMOUNT
                   , PAC_PAYMENT_CONDITION_ID
                   , GCO_GOOD_ID
                   , INX_ISSUING_DATE
                   , INX_INVOICING_DATE
                   , INX_INVOICE_GENERATED
                   , DOC_RECORD_ID
                   , INX_END_TASK_DATE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vCorrectionId
                   , aDocumentId
                   , tplDocPaymentCondition.C_INVOICE_EXPIRY_DOC_TYPE
                   , tplDocPaymentCondition.DOC_GAUGE_ID
                   , tplDocPaymentCondition.CDE_PART   -- INX_SLICE
                   , tplDocPaymentCondition.DES_SHORT_DESCRIPTION   --INX_WORDING
                   , tplDocPaymentCondition.DES_LONG_DESCRIPTION   --INX_DECRIPTION
                   , vProportion   -- INX_PROPORTION
                   , vSliceNetAmountExcl   -- tplDocPaymentCondition INX_NET_VALUE_EXCL
                   --, vSliceNetAmountExcl_b   --INX_NET_VALUE_EXCL_B
        ,            vSliceNetAmountIncl   --INX_NET_VALUE_INCL
                   --, vSliceNetAmountIncl_b   --INX_NET_VALUE_INCL_B
        ,            vSliceRetNetAmountIncl
                   , vSliceRetNetAmountExcl
                   --, vSliceRetNetAmountIncl_b
                   --, vSliceRetNetAmountExcl_b
        ,            tplDocPaymentCondition.CDE_ROUND_TYPE
                   , tplDocPaymentCondition.CDE_ROUND_AMOUNT
                   , vPaymentConditionId
                   , tplDocPaymentCondition.GCO_GOOD_ID
                   , vDateCalculated   -- INX_ISSUING_DATE
                   , null   -- INX_IVOICING_DATE
                   , 0   -- INX_INVOICE_GENERATED
                   , null   -- DOC_RECORD_ID
                   , null   -- INX_END_TASK_DATE
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- cumul du montant de toutes les tranches
        vDocNetTotAmountAddExcl    := vDocNetTotAmountAddExcl + nvl(vSliceNetAmountExcl, 0) - nvl(vSliceRetNetAmountExcl, 0);
        vDocNetTotAmountAddExcl_b  := vDocNetTotAmountAddExcl_b + nvl(vSliceNetAmountExcl_b, 0) - nvl(vSliceRetNetAmountExcl_b, 0);
        vDocNetTotAmountAddIncl    := vDocNetTotAmountAddIncl + nvl(vSliceNetAmountIncl, 0) - nvl(vSliceRetNetAmountIncl, 0);
        vDocNetTotAmountAddIncl_b  := vDocNetTotAmountAddIncl_b + nvl(vSliceNetAmountIncl_b, 0) - nvl(vSliceRetNetAmountIncl_b, 0);
      end;
    end loop;

    -- test si différence d'arrondi
    if vDocNetTotAmountAddExcl <> vDocNetTotalAmountExcl then
      update DOC_INVOICE_EXPIRY
         set INX_NET_VALUE_EXCL = INX_NET_VALUE_EXCL +(vDocNetTotalAmountExcl - vDocNetTotAmountAddExcl)
       where DOC_INVOICE_EXPIRY_ID = vCorrectionId;
    end if;

    -- Reset du flag de création de l'échéancier
    update DOC_DOCUMENT
       set DMT_CREATE_INVOICE_EXPIRY = 0
     where DOC_DOCUMENT_Id = aDocumentId;
  end createDocumentBillBook;

  /**
  * Description
  *    Création de l'échéancier d'un document
  */
  procedure createBillBook(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aForce in number default 0)
  is
    vNbPosLinked   pls_integer;
    vNbPosLinkable pls_integer;
  begin
    createDocumentBillBook(aDocumentId, aForce);
  end createBillBook;

  /**
  * Description
  *    Calcule les montants en fonction des proportions actuelles de l'échéancier
  */
  procedure calculateDocumentBillBook(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aForceRetDeposit number default 0)
  is
    -- curseur sur les conditions de paiement échéancier
    cursor crDocInvoiceExpiry(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   INX.DOC_INVOICE_EXPIRY_ID
             , INX.INX_PROPORTION
             , FOO_GOOD_TOT_AMOUNT_EXCL FOO_DOC_TOTAL_AMOUNT_EXCL
             , FOO_GOOD_TOT_AMOUNT_EX_B FOO_DOC_TOTAL_AMOUNT_EXCL_B
             , 0 FOO_GOOD_TOTAL_AMOUNT_EXCL   -- FOO.FOO_GOOD_TOTAL_AMOUNT_EXCL, mais ce champ n'existe pas
             , 0 FOO_GOOD_TOTAL_AMOUNT_EXCL_B   -- FOO.FOO_GOOD_TOT_AMOUNT_EXCL B, mais ce champ n'existe pas
             , INX_NET_VALUE_EXCL
             , INX_NET_VALUE_EXCL_B
             , nvl(INX_RET_DEPOSIT_NET_EXCL, 0) INX_RET_DEPOSIT_NET_EXCL
             , nvl(INX_RET_DEPOSIT_NET_EXCL_B, 0) INX_RET_DEPOSIT_NET_EXCL_B
             , nvl(INX_RET_DEPOSIT_NET_INCL, 0) INX_RET_DEPOSIT_NET_INCL
             , nvl(INX_RET_DEPOSIT_NET_INCL_B, 0) INX_RET_DEPOSIT_NET_INCL_B
             , INX.C_ROUND_TYPE INX_ROUND_TYPE
             , INX.INX_ROUND_AMOUNT
             , GAS.C_ROUND_TYPE GAS_ROUND_TYPE
             , GAS.GAS_ROUND_AMOUNT
             , GAP.C_ROUND_APPLICATION
             , DMT.ACS_FINANCIAL_CURRENCY_ID
             , DMT.DMT_TARIFF_DATE
             , DMT.DMT_DATE_DOCUMENT
             , INX.C_INVOICE_EXPIRY_DOC_TYPE
             , INX.INX_INVOICE_GENERATED
          from DOC_DOCUMENT DMT
             , DOC_FOOT FOO
             , DOC_INVOICE_EXPIRY INX
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
         where DMT.DOC_DOCUMENT_ID = aDocumentId
           and DMT.DMT_INVOICE_EXPIRY = 1
           and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and INX.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and GAS.DOC_GAUGE_ID = INX.DOC_GAUGE_ID
           and GAP.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and GAP.C_GAUGE_TYPE_POS = '1'
           and GAP.GAP_DEFAULT = 1
      order by decode(INX.C_INVOICE_EXPIRY_DOC_TYPE, '3', 1, 0)
             , INX.INX_PROPORTION;

    vDocNetTotalAmountExcl    DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotalAmountExcl_b  DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vFrozenNetTotalAmount     DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vFrozenNetTotalAmount_b   DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vDefNetTotalAmount        DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDefNetTotalAmount_b      DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vDocNetTotalAmountIncl    DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotalAmountIncl_b  DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vDocNetTotAmountAddExcl   DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotAmountAddExcl_b DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vDocNetTotAmountAddIncl   DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type              := 0;
    vDocNetTotAmountAddIncl_b DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type              := 0;
    vSliceNetAmountExcl       DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type           := 0;
    vSliceNetAmountExcl_b     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL_B%type         := 0;
    vSliceNetAmountIncl       DOC_INVOICE_EXPIRY.INX_NET_VALUE_INCL%type           := 0;
    vSliceNetAmountIncl_b     DOC_INVOICE_EXPIRY.INX_NET_VALUE_INCL_B%type         := 0;
    vSliceRetNetAmountExcl    DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type     := 0;
    vSliceRetNetAmountExcl_b  DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL_B%type   := 0;
    vSliceRetNetAmountIncl    DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_INCL%type     := 0;
    vSliceRetNetAmountIncl_b  DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_INCL_B%type   := 0;
    vTotalProportion          PAC_CONDITION_DETAIL.CDE_ACCOUNT%type;
    vCorrectionId             DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    vInputType                DOC_DOCUMENT.C_INVOICE_EXPIRY_INPUT_TYPE%type;
    vRoundType                DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type;
    vRoundAmount              DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type;
    vNbPosLinked              pls_integer;
    vNbPosLinkable            pls_integer;
    vUpdate                   boolean;
    vFinalExists              number(1);
  begin
    select C_INVOICE_EXPIRY_INPUT_TYPE
      into vInputType
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    -- recherche informations globales au document
    select sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '6', 0, '5', 0, '4', 0, decode(INX_INVOICE_GENERATED, 0, nvl(INX_PROPORTION, 0), 0) ) )
         , max(GAS.C_ROUND_TYPE)
         , max(GAS_ROUND_AMOUNT)
         , max(FOO_GOOD_TOT_AMOUNT_EXCL)
         , max(FOO_GOOD_TOT_AMOUNT_EX_B)
         , nvl(sum(decode(C_INVOICE_EXPIRY_DOC_TYPE
                        , '6', 0
                        , '5', 0
                        , '4', 0
                        , '3', 0
                        , decode(INX_INVOICE_GENERATED, 1, INX_NET_VALUE_EXCL, decode(INX_PROPORTION, null, INX_NET_VALUE_EXCL, 0) )
                         )
                  )
             , 0
              ) INX_NET_FROZEN_EXCL
         , nvl(sum(decode(C_INVOICE_EXPIRY_DOC_TYPE
                        , '6', 0
                        , '5', 0
                        , '4', 0
                        , '3', 0
                        , decode(INX_INVOICE_GENERATED, 1, INX_NET_VALUE_EXCL_B, decode(INX_PROPORTION, null, INX_NET_VALUE_EXCL_B, 0) )
                         )
                  )
             , 0
              ) INX_NET_FROZEN_EXCL_B
         , max(C_INVOICE_EXPIRY_INPUT_TYPE)
         , max(decode(C_INVOICE_EXPIRY_DOC_TYPE, '3', 1, 0) ) INX_FINAL_EXISTS
      into vTotalProportion
         , vRoundType
         , vRoundAmount
         , vDocNetTotalAmountExcl
         , vDocNetTotalAmountExcl_b
         , vFrozenNetTotalAmount
         , vFrozenNetTotalAmount_b
         , vInputType
         , vFinalExists
      from DOC_DOCUMENT DMT
         , DOC_INVOICE_EXPIRY INX
         , DOC_GAUGE_STRUCTURED GAS
         , DOC_FOOT FOO
     where DMT.DOC_DOCUMENT_Id = aDocumentId
       and INX.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
       and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID;

    -- Pour lancer un recalcul il faut qu'on ait une facture finale, sinon on ne fait rien
    if vFinalExists = 1 then
      -- pour chaque échéance
      for tplDocInvoiceExpiry in crDocInvoiceExpiry(aDocumentId) loop
        -- Proportion
        if vInputType = '1' then
          -- calcul du montant de tranche NET HT
          -- arrondi du montant selon règles gabarit cible
          case
            -- facture finales (report du solde)
          when     tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('3')
               and tplDocInvoiceExpiry.INX_INVOICE_GENERATED = 0 then
              -- calcul de la tranche "Facture finale par différence
              vSliceNetAmountExcl    := vDocNetTotalAmountExcl - nvl(vDefNetTotalAmount, 0);
              vSliceNetAmountExcl_b  := vDocNetTotalAmountExcl_b - nvl(vDefNetTotalAmount_b, 0);
              vUpdate                := true;
            -- note de crédit sur facture
          when tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('6') then
              vSliceNetAmountExcl       := 0;
              vSliceNetAmountExcl_b     := 0;
              vSliceRetNetAmountExcl    := null;
              vSliceRetNetAmountExcl_b  := null;
              --vDefNetTotalAmount        := vDefNetTotalAmount + tplDocInvoiceExpiry.INX_NET_VALUE_EXCL;
              --vDefNetTotalAmount_b      := vDefNetTotalAmount_b + tplDocInvoiceExpiry.INX_NET_VALUE_EXCL_B;
              vUpdate                   := false;
            -- note de crédit sur acompte
          when tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('4', '5') then
              vSliceNetAmountExcl       := -nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL, 0);
              vSliceNetAmountExcl_b     := -nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL_B, 0);
              vSliceRetNetAmountExcl    := null;
              vSliceRetNetAmountExcl_b  := null;
              vUpdate                   := false;
            -- acompte ou facture partielle non générés
          when     nvl(tplDocInvoiceExpiry.INX_PROPORTION, 0) <> 0
               and tplDocInvoiceExpiry.INX_INVOICE_GENERATED = 0 then
              vSliceNetAmountExcl    :=
                ACS_FUNCTION.PcsRound( (vDocNetTotalAmountExcl - vFrozenNetTotalAmount) * tplDocInvoiceExpiry.INX_PROPORTION / vTotalProportion
                                    , tplDocInvoiceExpiry.INX_ROUND_TYPE
                                    , tplDocInvoiceExpiry.INX_ROUND_AMOUNT
                                     );
              vSliceNetAmountExcl    :=
                DOC_POSITION_FUNCTIONS.roundPositionAmount(vSliceNetAmountExcl
                                                         , tplDocInvoiceExpiry.ACS_FINANCIAL_CURRENCY_ID
                                                         , tplDocInvoiceExpiry.C_ROUND_APPLICATION
                                                         , '0'
                                                         , 0
                                                         , tplDocInvoiceExpiry.GAS_ROUND_TYPE
                                                         , tplDocInvoiceExpiry.GAS_ROUND_AMOUNT
                                                          );
              -- calcul du montant de tranche NET HT en monnaie de base
              vSliceNetAmountExcl_b  :=
                ACS_FUNCTION.ConvertAmountForView(vSliceNetAmountExcl
                                                , ACS_FUNCTION.GetLocalCurrencyId
                                                , tplDocInvoiceExpiry.ACS_FINANCIAL_CURRENCY_ID
                                                , nvl(tplDocInvoiceExpiry.DMT_TARIFF_DATE, tplDocInvoiceExpiry.DMT_DATE_DOCUMENT)
                                                , 0
                                                , 0
                                                , 0
                                                , 5
                                                 );   -- Cours logistique

              if tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5', '6') then
                vSliceRetNetAmountExcl    := null;
                vSliceRetNetAmountExcl_b  := null;
              else
                vSliceRetNetAmountExcl    := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL, 0);
                vSliceRetNetAmountExcl_b  := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL_B, 0);
              end if;

              vUpdate                := true;
            -- documents déjà générés
          else
              vSliceNetAmountExcl       := nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL, 0);
              vSliceNetAmountExcl_b     := nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL_B, 0);
              vSliceRetNetAmountExcl    := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL, 0);
              vSliceRetNetAmountExcl_b  := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL_B, 0);
              vUpdate                   := false;
          end case;
          --vSliceNetAmountIncl     pas calculable de façon simple (sans pertes de performance notables)
          --vSliceNetAmountIncl_b   pas calculable de façon simple (sans pertes de performance notables)
        -- Montant / %
        elsif vInputType = '2' then
          case
            -- document final, mode solde
          when     tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('3')
               and tplDocInvoiceExpiry.INX_INVOICE_GENERATED = 0 then
              -- calcul de la tranche "Facture finale par différence
              vSliceNetAmountExcl    := vDocNetTotalAmountExcl - nvl(vDocNetTotAmountAddExcl, 0);
              vSliceNetAmountExcl_b  := vDocNetTotalAmountExcl_b - nvl(vDocNetTotAmountAddExcl_b, 0);
              vUpdate                := true;
            -- note de crédit sur facture
          when tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('6') then
              vSliceNetAmountExcl       := 0;
              vSliceNetAmountExcl_b     := 0;
              vSliceRetNetAmountExcl    := 0;
              vSliceRetNetAmountExcl_b  := 0;
              --vDefNetTotalAmount        := vDefNetTotalAmount + tplDocInvoiceExpiry.INX_NET_VALUE_EXCL;
              --vDefNetTotalAmount_b      := vDefNetTotalAmount_b + tplDocInvoiceExpiry.INX_NET_VALUE_EXCL_B;
              vUpdate                   := false;
            -- note de crédit sur acompte
          when tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('4', '5') then
              vSliceNetAmountExcl       := -nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL, 0);
              vSliceNetAmountExcl_b     := -nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL_B, 0);
              vSliceRetNetAmountExcl    := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL, 0);
              vSliceRetNetAmountExcl_b  := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL_B, 0);
              vUpdate                   := false;
            -- acompte ou facture partielle non générés
          when     nvl(tplDocInvoiceExpiry.INX_PROPORTION, 0) <> 0
               and tplDocInvoiceExpiry.INX_INVOICE_GENERATED = 0 then
              -- calcul du montant de tranche NET HT
              -- arrondi du montant selon règles gabarit cible
              vSliceNetAmountExcl       :=
                ACS_FUNCTION.PcsRound( (vDocNetTotalAmountExcl) * tplDocInvoiceExpiry.INX_PROPORTION / 100
                                    , tplDocInvoiceExpiry.INX_ROUND_TYPE
                                    , tplDocInvoiceExpiry.INX_ROUND_AMOUNT
                                     );
              vSliceNetAmountExcl       :=
                DOC_POSITION_FUNCTIONS.roundPositionAmount(vSliceNetAmountExcl
                                                         , tplDocInvoiceExpiry.ACS_FINANCIAL_CURRENCY_ID
                                                         , tplDocInvoiceExpiry.C_ROUND_APPLICATION
                                                         , '0'
                                                         , 0
                                                         , tplDocInvoiceExpiry.GAS_ROUND_TYPE
                                                         , tplDocInvoiceExpiry.GAS_ROUND_AMOUNT
                                                          );
              -- calcul du montant de tranche NET HT en monnaie de base
              vSliceNetAmountExcl_b     :=
                ACS_FUNCTION.ConvertAmountForView(vSliceNetAmountExcl
                                                , ACS_FUNCTION.GetLocalCurrencyId
                                                , tplDocInvoiceExpiry.ACS_FINANCIAL_CURRENCY_ID
                                                , nvl(tplDocInvoiceExpiry.DMT_TARIFF_DATE, tplDocInvoiceExpiry.DMT_DATE_DOCUMENT)
                                                , 0
                                                , 0
                                                , 0
                                                , 5
                                                 );   -- Cours logistique
              vSliceRetNetAmountExcl    := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL, 0);
              vSliceRetNetAmountExcl_b  := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL_B, 0);
              --vSliceNetAmountIncl     pas calculable de façon simple (sans pertes de performance notables)
              --vSliceNetAmountIncl_b   pas calculable de façon simple (sans pertes de performance notables)
              vUpdate                   := true;
            -- documents déjà générés
          else
              vSliceNetAmountExcl       := nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL, 0);
              vSliceNetAmountExcl_b     := nvl(tplDocInvoiceExpiry.INX_NET_VALUE_EXCL_B, 0);
              vSliceRetNetAmountExcl    := tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL;
              vSliceRetNetAmountExcl_b  := tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL_B;
              vUpdate                   := false;
          end case;
        end if;

        if tplDocInvoiceExpiry.INX_INVOICE_GENERATED = 0 then
          if tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('3') then
            pGetTotBalanceDepositAmount(aDocumentId, vSliceRetNetAmountExcl, vSliceRetNetAmountExcl_b, vSliceRetNetAmountIncl, vSliceRetNetAmountIncl_b);
          elsif tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('2') then
            if nvl(tplDocInvoiceExpiry.INX_PROPORTION, aForceRetDeposit) <> 0 then
              vSliceRetNetAmountExcl    := getGlobalRetDepositAmount(vSliceNetAmountExcl, aDocumentId, tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID);
              vSliceRetNetAmountExcl_b  := getGlobalRetDepositAmount(vSliceNetAmountExcl_b, aDocumentId, tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID);
              vSliceRetNetAmountIncl    := getGlobalRetDepositAmount(vSliceNetAmountIncl, aDocumentId, tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID);
              vSliceRetNetAmountIncl_b  := getGlobalRetDepositAmount(vSliceNetAmountIncl_b, aDocumentId, tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID);
            else
              vSliceRetNetAmountExcl    := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL, 0);
              vSliceRetNetAmountExcl_b  := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL_B, 0);
              vSliceRetNetAmountIncl    := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_INCL, 0);
              vSliceRetNetAmountIncl_b  := nvl(tplDocInvoiceExpiry.INX_RET_DEPOSIT_NET_INCL_B, 0);
            end if;
          else
            vSliceRetNetAmountExcl    := null;
            vSliceRetNetAmountExcl_b  := null;
            vSliceRetNetAmountIncl    := null;
            vSliceRetNetAmountIncl_b  := null;
          end if;
        end if;

        if tplDocInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('2', '4', '5') then
          vDefNetTotalAmount    := vDefNetTotalAmount + nvl(vSliceNetAmountExcl, 0);
          vDefNetTotalAmount_b  := vDefNetTotalAmount_b + nvl(vSliceNetAmountExcl_b, 0);
        end if;

        if tplDocInvoiceExpiry.INX_INVOICE_GENERATED = 0 then
          if vUpdate then
            -- insertion dans la table des tranches d'échéancier
            update DOC_INVOICE_EXPIRY
               set INX_NET_VALUE_EXCL = vSliceNetAmountExcl
                 --, INX_NET_VALUE_EXCL_B = vSliceNetAmountExcl_B
            ,      INX_NET_VALUE_INCL = vSliceNetAmountIncl
                 --, INX_NET_VALUE_INCL_B = vSliceNetAmountIncl_B
            ,      INX_RET_DEPOSIT_NET_INCL = vSliceRetNetAmountIncl
                 , INX_RET_DEPOSIT_NET_EXCL = vSliceRetNetAmountExcl
                 --, INX_RET_DEPOSIT_NET_INCL_B = vSliceRetNetAmountIncl_b
                 --, INX_RET_DEPOSIT_NET_EXCL_B = vSliceRetNetAmountExcl_b
            ,      A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where DOC_INVOICE_EXPIRY_ID = tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID;
          else
            -- insertion dans la table des tranches d'échéancier
            update DOC_INVOICE_EXPIRY
               set INX_RET_DEPOSIT_NET_INCL = vSliceRetNetAmountIncl
                 , INX_RET_DEPOSIT_NET_EXCL = vSliceRetNetAmountExcl
                 --, INX_RET_DEPOSIT_NET_INCL_B = vSliceRetNetAmountIncl_b
                 --, INX_RET_DEPOSIT_NET_EXCL_B = vSliceRetNetAmountExcl_b
            ,      A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where DOC_INVOICE_EXPIRY_ID = tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID;
          end if;
        end if;

        -- cumul du montant de toutes les tranches
        vDocNetTotAmountAddExcl    := vDocNetTotAmountAddExcl + nvl(vSliceNetAmountExcl, 0) - nvl(vSliceRetNetAmountExcl, 0);
        vDocNetTotAmountAddExcl_b  := vDocNetTotAmountAddExcl_b + nvl(vSliceNetAmountExcl_b, 0) - nvl(vSliceRetNetAmountExcl_b, 0);
        vDocNetTotAmountAddIncl    := vDocNetTotAmountAddIncl + nvl(vSliceNetAmountIncl, 0) - nvl(vSliceRetNetAmountIncl, 0);
        vDocNetTotAmountAddIncl_b  := vDocNetTotAmountAddIncl_b + nvl(vSliceNetAmountIncl_b, 0) - nvl(vSliceRetNetAmountIncl_b, 0);
        vCorrectionId              := tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID;
        DOC_FUNCTIONS.CreateHistoryInformation(null
                                             , null   -- DOC_POSITION_ID
                                             , tplDocInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                             , 'BILL_BOOK'   -- DUH_TYPE
                                             , 'subtot'
                                             , vDocNetTotAmountAddExcl
                                             , null   -- status document
                                             , null   -- status position
                                              );
      end loop;

      -- test si différence d'arrondi
      if vDocNetTotAmountAddExcl <> vDocNetTotalAmountExcl then
        update DOC_INVOICE_EXPIRY
           set INX_NET_VALUE_EXCL = nvl(INX_NET_VALUE_EXCL, 0) +(vDocNetTotalAmountExcl - vDocNetTotAmountAddExcl)
         where DOC_INVOICE_EXPIRY_ID = vCorrectionId;
      end if;
/* pas implémentable de suite
    -- test si différence d'arrondi en monnaie de base
    if vDocNetTotAmountAddExcl_b <> vDocNetTotalAmountExcl_b then
      update DOC_INVOICE_EXPIRY
         set INX_NET_VALUE_EXCL_B = nvl(INX_NET_VALUE_EXCL_B, 0)
                                    +(vDocNetTotalAmountExcl_b - vDocNetTotAmountAddExcl_b)
       where DOC_INVOICE_EXPIRY_ID = vCorrectionId;
    end if;
    -- test si différence d'arrondi
    if vDocNetTotAmountAddIncl <> vDocNetTotalAmountIncl then
      update DOC_INVOICE_EXPIRY
         set INX_NET_VALUE_INCL_B = nvl(INX_NET_VALUE_INCL_B,0) +(vDocNetTotalAmountIncl - vDocNetTotAmountAddIncl)
       where DOC_INVOICE_EXPIRY_ID = vCorrectionId;
    end if;

    -- test si différence d'arrondi en monnaie de base
    if vDocNetTotAmountAddIncl_b <> vDocNetTotalAmountIncl_b then
      update DOC_INVOICE_EXPIRY
         set INX_NET_VALUE_INCL_B = nvl(INX_NET_VALUE_INCL_B,0) +(vDocNetTotalAmountIncl_b - vDocNetTotAmountAddIncl_b)
       where DOC_INVOICE_EXPIRY_ID = vCorrectionId;
    end if;
*/
    end if;
  end calculateDocumentBillBook;

  /**
  * Description
  *    Contrôle de cohérence de l'échéancier
  */
  procedure validateDocumentBillBook(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aErrorMessage out varchar2)
  is
    vCount pls_integer;
  begin
    -- teste qu'on ait pas de reprise d'acompte négative
    select count(*)
      into vCount
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = aDocumentId
       and nvl(INX_RET_DEPOSIT_NET_EXCL, 0) < 0;

    if vCount > 0 then
      aErrorMessage  := PCS.PC_FUNCTIONS.TranslateWord('Reprise d''acompte négative interdite');
    end if;

    -- teste qu'on ait pas plus d'une facture finale
    select count(*)
      into vCount
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = aDocumentId
       and C_INVOICE_EXPIRY_DOC_TYPE = '3';

    if vCount <> 1 then
      aErrorMessage  := PCS.PC_FUNCTIONS.TranslateWord('Une et une seule facture finale est autorisée.');
    end if;
  end;

  /**
  * procedure generateBillBookDocumentHeader
  * Description
  *    création de l'entête des documents liés à  l'échéancier
  * @created fp 01.09.2006
  * @lastUpdate
  * @private
  * @param
  */
  procedure generateBillBookDocumentHeader(
    aDocumentId         in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSrcDocumentId      in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId    in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aPaymentConditionId in     PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type
  , aGaugeId            in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aThirdId            in     PAC_THIRD.PAC_THIRD_ID%type
  , aRepresentativeId   in     PAC_REPRESENTATIVE.PAC_REPRESENTATIVE_ID%type
  , aMode               in     varchar2
  , aDocumentDate       in     date
  , aValueDate          in     date
  , aCopyFootCharge     in     number default 0
  )
  is
  begin
    -- initialisation de la company finance car le fait de travailler en multi-schéma provoque des effets de bord
    -- La variable ne doit pas être réinitialisée dans la méthode de création
    DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO     := 0;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INVOICE_EXPIRY_ID   := aInvoiceExpiryId;

    if aPaymentConditionId is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := aPaymentConditionId;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FOOT_CHARGE        := aCopyFootCharge;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.FROZE_COPY_FOOT_CHARGE  := aCopyFootCharge;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE      := 1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE          := aValueDate;
    -- création de l'entête du document
    Doc_Document_Generate.GenerateDocument(aNewDocumentID      => aDocumentID
                                         , aMode               => aMode   -- copie document échéancier
                                         , aGaugeID            => aGaugeId
                                         , aThirdID            => aThirdId
                                         , aRepresentativeID   => aRepresentativeID
                                         , aDocDate            => aDocumentDate
                                         , aSrcDocumentID      => aSrcDocumentId
                                          );

    -- mise à jour du flag de création des remises/taxes de pied
    update DOC_DOCUMENT
       set DMT_CREATE_FOOT_CHARGE = 0
     where DOC_DOCUMENT_ID = aDocumentId;
  end generateBillBookDocumentHeader;

  /**
  * procedure ventilateBalanceDocAmountOnPos
  * Description
  *    applique la ventilation du document source une position en montant
  * @created fp 19.09.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param aNewDocumentId : id du nouveau document
  * @param aAmountPositionId : id de la position montant
  * @param aSourceDocumentId : id du document source
  */
  procedure ventilateBalanceDocAmountOnPos(
    aNewDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAmountPositionId in DOC_POSITION.DOC_POSITION_ID%type
  , aSourceDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSimulation       in number default 0
  )
  is
    cursor crOriginalVentilation(aCrDocumentId number, aCrSimulation number)
    is
      select poi_amount   -- / total poi_percent
           , DOC_RECORD_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , DIC_IMP_FREE1_ID
           , DIC_IMP_FREE2_ID
           , DIC_IMP_FREE3_ID
           , DIC_IMP_FREE4_ID
           , DIC_IMP_FREE5_ID
           , C_FAM_TRANSACTION_TYP
           , FAM_FIXED_ASSETS_ID
           , HRM_PERSON_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , POI_IMF_NUMBER_1
           , POI_IMF_NUMBER_2
           , POI_IMF_NUMBER_3
           , POI_IMF_NUMBER_4
           , POI_IMF_NUMBER_5
           , POI_IMF_TEXT_1
           , POI_IMF_TEXT_2
           , POI_IMF_TEXT_3
           , POI_IMF_TEXT_4
           , POI_IMF_TEXT_5
        from (select (select nvl(sum(pos_gross_value), 0) / 100
                        from doc_position
                       where doc_document_id = aCrDocumentId
                         and C_GAUGE_TYPE_POS not in('6')
                         and C_DOC_POS_STATUS <> '05'
                         and poi_amount <> 0) total
                   , poi_amount
                   , DOC_RECORD_ID
                   , ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , C_FAM_TRANSACTION_TYP
                   , FAM_FIXED_ASSETS_ID
                   , HRM_PERSON_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , POI_IMF_NUMBER_1
                   , POI_IMF_NUMBER_2
                   , POI_IMF_NUMBER_3
                   , POI_IMF_NUMBER_4
                   , POI_IMF_NUMBER_5
                   , POI_IMF_TEXT_1
                   , POI_IMF_TEXT_2
                   , POI_IMF_TEXT_3
                   , POI_IMF_TEXT_4
                   , POI_IMF_TEXT_5
                from (select   sum(decode(pos_gross_value
                                        , 0, 0
                                        , a.poi_amount *
                                          ( (pos_gross_value - DOC_INVOICE_EXPIRY_FUNCTIONS.getPosDischargedAmount(a.doc_position_id, aCrSimulation) ) /
                                           pos_gross_value
                                          )
                                         )
                                  ) poi_amount
                             , a.DOC_RECORD_ID
                             , a.ACS_PJ_ACCOUNT_ID
                             , a.ACS_PF_ACCOUNT_ID
                             , a.ACS_FINANCIAL_ACCOUNT_ID
                             , a.DIC_IMP_FREE1_ID
                             , a.DIC_IMP_FREE2_ID
                             , a.DIC_IMP_FREE3_ID
                             , a.DIC_IMP_FREE4_ID
                             , a.DIC_IMP_FREE5_ID
                             , a.C_FAM_TRANSACTION_TYP
                             , a.FAM_FIXED_ASSETS_ID
                             , a.HRM_PERSON_ID
                             , a.ACS_CDA_ACCOUNT_ID
                             , a.ACS_CPN_ACCOUNT_ID
                             , a.ACS_DIVISION_ACCOUNT_ID
                             , a.POI_IMF_NUMBER_1
                             , a.POI_IMF_NUMBER_2
                             , a.POI_IMF_NUMBER_3
                             , a.POI_IMF_NUMBER_4
                             , a.POI_IMF_NUMBER_5
                             , a.POI_IMF_TEXT_1
                             , a.POI_IMF_TEXT_2
                             , a.POI_IMF_TEXT_3
                             , a.POI_IMF_TEXT_4
                             , a.POI_IMF_TEXT_5
                          from doc_position_imputation a
                             , doc_position b
                         where a.doc_document_id = aCrDocumentId
                           and b.pos_imputation = 1
                           and b.doc_position_id = a.doc_position_id
                           and b.C_DOC_POS_STATUS <> '05'
                           and a.poi_amount <> 0
                      group by a.DOC_RECORD_ID
                             , a.ACS_PJ_ACCOUNT_ID
                             , a.ACS_PF_ACCOUNT_ID
                             , a.ACS_FINANCIAL_ACCOUNT_ID
                             , a.DIC_IMP_FREE1_ID
                             , a.DIC_IMP_FREE2_ID
                             , a.DIC_IMP_FREE3_ID
                             , a.DIC_IMP_FREE4_ID
                             , a.DIC_IMP_FREE5_ID
                             , a.C_FAM_TRANSACTION_TYP
                             , a.FAM_FIXED_ASSETS_ID
                             , a.HRM_PERSON_ID
                             , a.ACS_CDA_ACCOUNT_ID
                             , a.ACS_CPN_ACCOUNT_ID
                             , a.ACS_DIVISION_ACCOUNT_ID
                             , a.POI_IMF_NUMBER_1
                             , a.POI_IMF_NUMBER_2
                             , a.POI_IMF_NUMBER_3
                             , a.POI_IMF_NUMBER_4
                             , a.POI_IMF_NUMBER_5
                             , a.POI_IMF_TEXT_1
                             , a.POI_IMF_TEXT_2
                             , a.POI_IMF_TEXT_3
                             , a.POI_IMF_TEXT_4
                             , a.POI_IMF_TEXT_5
                      union all
                      select   decode(sum(pos_gross_value - DOC_INVOICE_EXPIRY_FUNCTIONS.getPosDischargedAmount(DOC_POSITION_ID, aCrSimulation) )
                                    , 0, 1
                                    , sum(pos_gross_value - DOC_INVOICE_EXPIRY_FUNCTIONS.getPosDischargedAmount(DOC_POSITION_ID, aCrSimulation) )
                                     ) poi_amount
                             , DOC_RECORD_ID
                             , ACS_PJ_ACCOUNT_ID
                             , ACS_PF_ACCOUNT_ID
                             , ACS_FINANCIAL_ACCOUNT_ID
                             , DIC_IMP_FREE1_ID
                             , DIC_IMP_FREE2_ID
                             , DIC_IMP_FREE3_ID
                             , DIC_IMP_FREE4_ID
                             , DIC_IMP_FREE5_ID
                             , C_FAM_TRANSACTION_TYP
                             , FAM_FIXED_ASSETS_ID
                             , HRM_PERSON_ID
                             , ACS_CDA_ACCOUNT_ID
                             , ACS_CPN_ACCOUNT_ID
                             , ACS_DIVISION_ACCOUNT_ID
                             , null POS_IMF_NUMBER_1
                             , POS_IMF_NUMBER_2
                             , POS_IMF_NUMBER_3
                             , POS_IMF_NUMBER_4
                             , POS_IMF_NUMBER_5
                             , POS_IMF_TEXT_1
                             , POS_IMF_TEXT_2
                             , POS_IMF_TEXT_3
                             , POS_IMF_TEXT_4
                             , POS_IMF_TEXT_5
                          from doc_position
                         where doc_document_id = aCrDocumentId
                           and pos_imputation = 0
                           and pos_gross_value <> 0
                           and C_DOC_POS_STATUS <> '05'
                           and c_gauge_type_pos not in('6')
                      group by DOC_RECORD_ID
                             , ACS_PJ_ACCOUNT_ID
                             , ACS_PF_ACCOUNT_ID
                             , ACS_FINANCIAL_ACCOUNT_ID
                             , DIC_IMP_FREE1_ID
                             , DIC_IMP_FREE2_ID
                             , DIC_IMP_FREE3_ID
                             , DIC_IMP_FREE4_ID
                             , DIC_IMP_FREE5_ID
                             , C_FAM_TRANSACTION_TYP
                             , FAM_FIXED_ASSETS_ID
                             , HRM_PERSON_ID
                             , ACS_CDA_ACCOUNT_ID
                             , ACS_CPN_ACCOUNT_ID
                             , ACS_DIVISION_ACCOUNT_ID
                             --, POS_NUMBER
                      ,        POS_IMF_NUMBER_2
                             , POS_IMF_NUMBER_3
                             , POS_IMF_NUMBER_4
                             , POS_IMF_NUMBER_5
                             , POS_IMF_TEXT_1
                             , POS_IMF_TEXT_2
                             , POS_IMF_TEXT_3
                             , POS_IMF_TEXT_4
                             , POS_IMF_TEXT_5) );
  begin
    for tplOriginalVentilation in crOriginalVentilation(aSourceDocumentId, aSimulation) loop
      declare
        vTplDocPositionImputation DOC_POSITION_IMPUTATION%rowtype;
        vAmountAlreadyDone        DOC_POSITION.DOC_POSITION_ID%type;
      begin
        select INIT_ID_SEQ.nextval
          into vTplDocPositionImputation.DOC_POSITION_IMPUTATION_ID
          from dual;

        vTplDocPositionImputation.DOC_DOCUMENT_ID           := aNewDocumentID;   -- DOC_DOCUMENT_ID
        vTplDocPositionImputation.DOC_POSITION_ID           := aAmountPositionId;   -- DOC_POSITION_ID
        vTplDocPositionImputation.DOC_POSITION_CHARGE_ID    := null;   -- DOC_POSITION_CHARGE_ID
        vTplDocPositionImputation.DOC_FOOT_CHARGE_ID        := null;   -- DOC_FOOT_CHARGE_ID
        vTplDocPositionImputation.DOC_RECORD_ID             := tplOriginalVentilation.DOC_RECORD_ID;   -- DOC_RECORD_ID
        vTplDocPositionImputation.POI_RATIO                 := tplOriginalVentilation.POI_AMOUNT;   -- - vAmountAlreadyDone;   -- POI_RATIO
        vTplDocPositionImputation.ACS_FINANCIAL_ACCOUNT_ID  := tplOriginalVentilation.ACS_FINANCIAL_ACCOUNT_ID;   -- ACS_FINANCIAL_ACCOUNT_ID
        vTplDocPositionImputation.ACS_DIVISION_ACCOUNT_ID   := tplOriginalVentilation.ACS_DIVISION_ACCOUNT_ID;   -- ACS_DIVISION_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PJ_ACCOUNT_ID         := tplOriginalVentilation.ACS_PJ_ACCOUNT_ID;   -- ACS_PJ_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PF_ACCOUNT_ID         := tplOriginalVentilation.ACS_PF_ACCOUNT_ID;   -- ACS_PF_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CDA_ACCOUNT_ID        := tplOriginalVentilation.ACS_CDA_ACCOUNT_ID;   -- ACS_CDA_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CPN_ACCOUNT_ID        := tplOriginalVentilation.ACS_CPN_ACCOUNT_ID;   -- ACS_CPN_ACCOUNT_ID
        vTplDocPositionImputation.DIC_IMP_FREE1_ID          := tplOriginalVentilation.DIC_IMP_FREE1_ID;   -- DIC_IMP_FREE1_ID
        vTplDocPositionImputation.DIC_IMP_FREE2_ID          := tplOriginalVentilation.DIC_IMP_FREE2_ID;   -- DIC_IMP_FREE2_ID
        vTplDocPositionImputation.DIC_IMP_FREE3_ID          := tplOriginalVentilation.DIC_IMP_FREE3_ID;   -- DIC_IMP_FREE3_ID
        vTplDocPositionImputation.DIC_IMP_FREE4_ID          := tplOriginalVentilation.DIC_IMP_FREE4_ID;   -- DIC_IMP_FREE4_ID
        vTplDocPositionImputation.DIC_IMP_FREE5_ID          := tplOriginalVentilation.DIC_IMP_FREE5_ID;   -- DIC_IMP_FREE5_ID
        vTplDocPositionImputation.POI_IMF_NUMBER_1          := tplOriginalVentilation.POI_IMF_NUMBER_1;   -- POI_IMF_NUMBER_1
        vTplDocPositionImputation.POI_IMF_NUMBER_2          := tplOriginalVentilation.POI_IMF_NUMBER_2;   -- POI_IMF_NUMBER_2
        vTplDocPositionImputation.POI_IMF_NUMBER_3          := tplOriginalVentilation.POI_IMF_NUMBER_3;   -- POI_IMF_NUMBER_3
        vTplDocPositionImputation.POI_IMF_NUMBER_4          := tplOriginalVentilation.POI_IMF_NUMBER_4;   -- POI_IMF_NUMBER_4
        vTplDocPositionImputation.POI_IMF_NUMBER_5          := tplOriginalVentilation.POI_IMF_NUMBER_5;   -- POI_IMF_NUMBER_5
        vTplDocPositionImputation.POI_IMF_TEXT_1            := tplOriginalVentilation.POI_IMF_TEXT_1;   -- POI_IMF_TEXT_1
        vTplDocPositionImputation.POI_IMF_TEXT_2            := tplOriginalVentilation.POI_IMF_TEXT_2;   -- POI_IMF_TEXT_2
        vTplDocPositionImputation.POI_IMF_TEXT_3            := tplOriginalVentilation.POI_IMF_TEXT_3;   -- POI_IMF_TEXT_3
        vTplDocPositionImputation.POI_IMF_TEXT_4            := tplOriginalVentilation.POI_IMF_TEXT_4;   -- POI_IMF_TEXT_4
        vTplDocPositionImputation.POI_IMF_TEXT_5            := tplOriginalVentilation.POI_IMF_TEXT_5;   -- POI_IMF_TEXT_5
        vTplDocPositionImputation.C_FAM_TRANSACTION_TYP     := tplOriginalVentilation.C_FAM_TRANSACTION_TYP;   -- C_FAM_TRANSACTION_TYP
        vTplDocPositionImputation.FAM_FIXED_ASSETS_ID       := tplOriginalVentilation.FAM_FIXED_ASSETS_ID;   -- FAM_FIXED_ASSETS_ID
        vTplDocPositionImputation.HRM_PERSON_ID             := tplOriginalVentilation.HRM_PERSON_ID;   -- HRM_PERSON_ID
        vTplDocPositionImputation.A_DATECRE                 := sysdate;   -- A_DATECRE
        vTplDocPositionImputation.A_IDCRE                   := PCS.PC_I_LIB_SESSION.GetUserIni;   -- A_IDCRE
        DOC_IMPUTATION_FUNCTIONS.insertPositionImputation(vTplDocPositionImputation, aSimulation);

        if aSimulation = 0 then
          update DOC_POSITION
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aAmountPositionId;
        else
          update DOC_ESTIMATED_POS_CASH_FLOW
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aAmountPositionId;
        end if;

        -- ventilation des montants
        if aSimulation = 0 then
          DOC_IMPUTATION_FUNCTIONS.imputePosition(aAmountPositionId);
        else
          DOC_IMPUTATION_FUNCTIONS.imputeEstimatedPosition(aAmountPositionId);
        end if;
      end;
    end loop;

    -- Si une seule ventilation ramène les comptes sur la position
    DOC_IMPUTATION_FUNCTIONS.simplifyVentilation(aPositionId => aAmountPositionId, aSimulation => aSimulation);
  end ventilateBalanceDocAmountOnPos;

  /**
  * procedure ventilateDocAmountOnPos
  * Description
  *    applique la ventilation du document source une position en montant
  * @created fp 19.09.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param aNewDocumentId : id du nouveau document
  * @param aAmountPositionId : id de la position montant
  * @param aSourceDocumentId : id du document source
  */
  procedure ventilateDocAmountOnPos(
    aNewDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAmountPositionId in DOC_POSITION.DOC_POSITION_ID%type
  , aSourceDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSimulation       in number default 0
  )
  is
    cursor crOriginalVentilation(aCrDocumentId number)
    is
      select decode(total, 0, 0, poi_amount / total) poi_percent
           , DOC_RECORD_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , DIC_IMP_FREE1_ID
           , DIC_IMP_FREE2_ID
           , DIC_IMP_FREE3_ID
           , DIC_IMP_FREE4_ID
           , DIC_IMP_FREE5_ID
           , C_FAM_TRANSACTION_TYP
           , FAM_FIXED_ASSETS_ID
           , HRM_PERSON_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , POI_IMF_NUMBER_1
           , POI_IMF_NUMBER_2
           , POI_IMF_NUMBER_3
           , POI_IMF_NUMBER_4
           , POI_IMF_NUMBER_5
           , POI_IMF_TEXT_1
           , POI_IMF_TEXT_2
           , POI_IMF_TEXT_3
           , POI_IMF_TEXT_4
           , POI_IMF_TEXT_5
        from (select (select nvl(sum(POS_GROSS_VALUE), 0) / 100
                        from doc_position
                       where doc_document_id = aCrDocumentId
                         and C_DOC_POS_STATUS <> '05'
                         and C_GAUGE_TYPE_POS not in('6')
                         and poi_amount <> 0) total
                   , poi_amount
                   , DOC_RECORD_ID
                   , ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , C_FAM_TRANSACTION_TYP
                   , FAM_FIXED_ASSETS_ID
                   , HRM_PERSON_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , POI_IMF_NUMBER_1
                   , POI_IMF_NUMBER_2
                   , POI_IMF_NUMBER_3
                   , POI_IMF_NUMBER_4
                   , POI_IMF_NUMBER_5
                   , POI_IMF_TEXT_1
                   , POI_IMF_TEXT_2
                   , POI_IMF_TEXT_3
                   , POI_IMF_TEXT_4
                   , POI_IMF_TEXT_5
                from (select   sum(POI.poi_amount) poi_amount
                             , POI.DOC_RECORD_ID
                             , POI.ACS_PJ_ACCOUNT_ID
                             , POI.ACS_PF_ACCOUNT_ID
                             , POI.ACS_FINANCIAL_ACCOUNT_ID
                             , POI.DIC_IMP_FREE1_ID
                             , POI.DIC_IMP_FREE2_ID
                             , POI.DIC_IMP_FREE3_ID
                             , POI.DIC_IMP_FREE4_ID
                             , POI.DIC_IMP_FREE5_ID
                             , POI.C_FAM_TRANSACTION_TYP
                             , POI.FAM_FIXED_ASSETS_ID
                             , POI.HRM_PERSON_ID
                             , POI.ACS_CDA_ACCOUNT_ID
                             , POI.ACS_CPN_ACCOUNT_ID
                             , POI.ACS_DIVISION_ACCOUNT_ID
                             , POI.POI_IMF_NUMBER_1
                             , POI.POI_IMF_NUMBER_2
                             , POI.POI_IMF_NUMBER_3
                             , POI.POI_IMF_NUMBER_4
                             , POI.POI_IMF_NUMBER_5
                             , POI.POI_IMF_TEXT_1
                             , POI.POI_IMF_TEXT_2
                             , POI.POI_IMF_TEXT_3
                             , POI.POI_IMF_TEXT_4
                             , POI.POI_IMF_TEXT_5
                          from doc_position_imputation POI
                             , DOC_POSITION POS
                         where POI.doc_document_id = aCrDocumentId
                           and POS.doc_position_id = poi.DOC_POSITION_ID
                           and POS.C_DOC_POS_STATUS <> '05'
                           and POI.doc_position_id is not null
                           and POI.poi_amount <> 0
                      group by POI.DOC_RECORD_ID
                             , POI.ACS_PJ_ACCOUNT_ID
                             , POI.ACS_PF_ACCOUNT_ID
                             , POI.ACS_FINANCIAL_ACCOUNT_ID
                             , POI.DIC_IMP_FREE1_ID
                             , POI.DIC_IMP_FREE2_ID
                             , POI.DIC_IMP_FREE3_ID
                             , POI.DIC_IMP_FREE4_ID
                             , POI.DIC_IMP_FREE5_ID
                             , POI.C_FAM_TRANSACTION_TYP
                             , POI.FAM_FIXED_ASSETS_ID
                             , POI.HRM_PERSON_ID
                             , POI.ACS_CDA_ACCOUNT_ID
                             , POI.ACS_CPN_ACCOUNT_ID
                             , POI.ACS_DIVISION_ACCOUNT_ID
                             , POI.POI_IMF_NUMBER_1
                             , POI.POI_IMF_NUMBER_2
                             , POI.POI_IMF_NUMBER_3
                             , POI.POI_IMF_NUMBER_4
                             , POI.POI_IMF_NUMBER_5
                             , POI.POI_IMF_TEXT_1
                             , POI.POI_IMF_TEXT_2
                             , POI.POI_IMF_TEXT_3
                             , POI.POI_IMF_TEXT_4
                             , POI.POI_IMF_TEXT_5
                      union all
                      select   sum(POI.poi_amount) poi_amount
                             , POI.DOC_RECORD_ID
                             , POI.ACS_PJ_ACCOUNT_ID
                             , POI.ACS_PF_ACCOUNT_ID
                             , POI.ACS_FINANCIAL_ACCOUNT_ID
                             , POI.DIC_IMP_FREE1_ID
                             , POI.DIC_IMP_FREE2_ID
                             , POI.DIC_IMP_FREE3_ID
                             , POI.DIC_IMP_FREE4_ID
                             , POI.DIC_IMP_FREE5_ID
                             , POI.C_FAM_TRANSACTION_TYP
                             , POI.FAM_FIXED_ASSETS_ID
                             , POI.HRM_PERSON_ID
                             , POI.ACS_CDA_ACCOUNT_ID
                             , POI.ACS_CPN_ACCOUNT_ID
                             , POI.ACS_DIVISION_ACCOUNT_ID
                             , POI.POI_IMF_NUMBER_1
                             , POI.POI_IMF_NUMBER_2
                             , POI.POI_IMF_NUMBER_3
                             , POI.POI_IMF_NUMBER_4
                             , POI.POI_IMF_NUMBER_5
                             , POI.POI_IMF_TEXT_1
                             , POI.POI_IMF_TEXT_2
                             , POI.POI_IMF_TEXT_3
                             , POI.POI_IMF_TEXT_4
                             , POI.POI_IMF_TEXT_5
                          from doc_position_imputation POI
                             , doc_position POS
                         where POI.doc_document_id = aCrDocumentId
                           and pos.doc_position_id = poi.doc_position_id
                           and pos.c_doc_pos_status <> '05'
                           and POI.doc_foot_charge_id is not null
                           and POI.poi_amount <> 0
                      group by POI.DOC_RECORD_ID
                             , POI.ACS_PJ_ACCOUNT_ID
                             , POI.ACS_PF_ACCOUNT_ID
                             , POI.ACS_FINANCIAL_ACCOUNT_ID
                             , POI.DIC_IMP_FREE1_ID
                             , POI.DIC_IMP_FREE2_ID
                             , POI.DIC_IMP_FREE3_ID
                             , POI.DIC_IMP_FREE4_ID
                             , POI.DIC_IMP_FREE5_ID
                             , POI.C_FAM_TRANSACTION_TYP
                             , POI.FAM_FIXED_ASSETS_ID
                             , POI.HRM_PERSON_ID
                             , POI.ACS_CDA_ACCOUNT_ID
                             , POI.ACS_CPN_ACCOUNT_ID
                             , POI.ACS_DIVISION_ACCOUNT_ID
                             , POI.POI_IMF_NUMBER_1
                             , POI.POI_IMF_NUMBER_2
                             , POI.POI_IMF_NUMBER_3
                             , POI.POI_IMF_NUMBER_4
                             , POI.POI_IMF_NUMBER_5
                             , POI.POI_IMF_TEXT_1
                             , POI.POI_IMF_TEXT_2
                             , POI.POI_IMF_TEXT_3
                             , POI.POI_IMF_TEXT_4
                             , POI.POI_IMF_TEXT_5
                      union all
                      select   sum(pos_gross_value) poi_amount
                             , DOC_RECORD_ID
                             , ACS_PJ_ACCOUNT_ID
                             , ACS_PF_ACCOUNT_ID
                             , ACS_FINANCIAL_ACCOUNT_ID
                             , DIC_IMP_FREE1_ID
                             , DIC_IMP_FREE2_ID
                             , DIC_IMP_FREE3_ID
                             , DIC_IMP_FREE4_ID
                             , DIC_IMP_FREE5_ID
                             , C_FAM_TRANSACTION_TYP
                             , FAM_FIXED_ASSETS_ID
                             , HRM_PERSON_ID
                             , ACS_CDA_ACCOUNT_ID
                             , ACS_CPN_ACCOUNT_ID
                             , ACS_DIVISION_ACCOUNT_ID
                             , null POS_IMF_NUMBER_1
                             , POS_IMF_NUMBER_2
                             , POS_IMF_NUMBER_3
                             , POS_IMF_NUMBER_4
                             , POS_IMF_NUMBER_5
                             , POS_IMF_TEXT_1
                             , POS_IMF_TEXT_2
                             , POS_IMF_TEXT_3
                             , POS_IMF_TEXT_4
                             , POS_IMF_TEXT_5
                          from doc_position
                         where doc_document_id = aCrDocumentId
                           and pos_imputation = 0
                           and pos_gross_value <> 0
                           and C_DOC_POS_STATUS <> '05'
                           and c_gauge_type_pos not in('6')
                      group by DOC_RECORD_ID
                             , ACS_PJ_ACCOUNT_ID
                             , ACS_PF_ACCOUNT_ID
                             , ACS_FINANCIAL_ACCOUNT_ID
                             , DIC_IMP_FREE1_ID
                             , DIC_IMP_FREE2_ID
                             , DIC_IMP_FREE3_ID
                             , DIC_IMP_FREE4_ID
                             , DIC_IMP_FREE5_ID
                             , C_FAM_TRANSACTION_TYP
                             , FAM_FIXED_ASSETS_ID
                             , HRM_PERSON_ID
                             , ACS_CDA_ACCOUNT_ID
                             , ACS_CPN_ACCOUNT_ID
                             , ACS_DIVISION_ACCOUNT_ID
                             --, POS_NUMBER
                      ,        POS_IMF_NUMBER_2
                             , POS_IMF_NUMBER_3
                             , POS_IMF_NUMBER_4
                             , POS_IMF_NUMBER_5
                             , POS_IMF_TEXT_1
                             , POS_IMF_TEXT_2
                             , POS_IMF_TEXT_3
                             , POS_IMF_TEXT_4
                             , POS_IMF_TEXT_5) );
  begin
    for tplOriginalVentilation in crOriginalVentilation(aSourceDocumentId) loop
      declare
        vTplDocPositionImputation DOC_POSITION_IMPUTATION%rowtype;
      begin
        select INIT_ID_SEQ.nextval
          into vTplDocPositionImputation.DOC_POSITION_IMPUTATION_ID
          from dual;

        vTplDocPositionImputation.DOC_DOCUMENT_ID           := aNewDocumentID;   -- DOC_DOCUMENT_ID
        vTplDocPositionImputation.DOC_POSITION_ID           := aAmountPositionId;   -- DOC_POSITION_ID
        vTplDocPositionImputation.DOC_POSITION_CHARGE_ID    := null;   -- DOC_POSITION_CHARGE_ID
        vTplDocPositionImputation.DOC_FOOT_CHARGE_ID        := null;   -- DOC_FOOT_CHARGE_ID
        vTplDocPositionImputation.DOC_RECORD_ID             := tplOriginalVentilation.DOC_RECORD_ID;   -- DOC_RECORD_ID
        vTplDocPositionImputation.POI_RATIO                 := tplOriginalVentilation.POI_PERCENT;   -- POI_RATIO
        vTplDocPositionImputation.ACS_FINANCIAL_ACCOUNT_ID  := tplOriginalVentilation.ACS_FINANCIAL_ACCOUNT_ID;   -- ACS_FINANCIAL_ACCOUNT_ID
        vTplDocPositionImputation.ACS_DIVISION_ACCOUNT_ID   := tplOriginalVentilation.ACS_DIVISION_ACCOUNT_ID;   -- ACS_DIVISION_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PJ_ACCOUNT_ID         := tplOriginalVentilation.ACS_PJ_ACCOUNT_ID;   -- ACS_PJ_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PF_ACCOUNT_ID         := tplOriginalVentilation.ACS_PF_ACCOUNT_ID;   -- ACS_PF_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CDA_ACCOUNT_ID        := tplOriginalVentilation.ACS_CDA_ACCOUNT_ID;   -- ACS_CDA_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CPN_ACCOUNT_ID        := tplOriginalVentilation.ACS_CPN_ACCOUNT_ID;   -- ACS_CPN_ACCOUNT_ID
        vTplDocPositionImputation.DIC_IMP_FREE1_ID          := tplOriginalVentilation.DIC_IMP_FREE1_ID;   -- DIC_IMP_FREE1_ID
        vTplDocPositionImputation.DIC_IMP_FREE2_ID          := tplOriginalVentilation.DIC_IMP_FREE2_ID;   -- DIC_IMP_FREE2_ID
        vTplDocPositionImputation.DIC_IMP_FREE3_ID          := tplOriginalVentilation.DIC_IMP_FREE3_ID;   -- DIC_IMP_FREE3_ID
        vTplDocPositionImputation.DIC_IMP_FREE4_ID          := tplOriginalVentilation.DIC_IMP_FREE4_ID;   -- DIC_IMP_FREE4_ID
        vTplDocPositionImputation.DIC_IMP_FREE5_ID          := tplOriginalVentilation.DIC_IMP_FREE5_ID;   -- DIC_IMP_FREE5_ID
        vTplDocPositionImputation.POI_IMF_NUMBER_1          := tplOriginalVentilation.POI_IMF_NUMBER_1;   -- POI_IMF_NUMBER_1
        vTplDocPositionImputation.POI_IMF_NUMBER_2          := tplOriginalVentilation.POI_IMF_NUMBER_2;   -- POI_IMF_NUMBER_2
        vTplDocPositionImputation.POI_IMF_NUMBER_3          := tplOriginalVentilation.POI_IMF_NUMBER_3;   -- POI_IMF_NUMBER_3
        vTplDocPositionImputation.POI_IMF_NUMBER_4          := tplOriginalVentilation.POI_IMF_NUMBER_4;   -- POI_IMF_NUMBER_4
        vTplDocPositionImputation.POI_IMF_NUMBER_5          := tplOriginalVentilation.POI_IMF_NUMBER_5;   -- POI_IMF_NUMBER_5
        vTplDocPositionImputation.POI_IMF_TEXT_1            := tplOriginalVentilation.POI_IMF_TEXT_1;   -- POI_IMF_TEXT_1
        vTplDocPositionImputation.POI_IMF_TEXT_2            := tplOriginalVentilation.POI_IMF_TEXT_2;   -- POI_IMF_TEXT_2
        vTplDocPositionImputation.POI_IMF_TEXT_3            := tplOriginalVentilation.POI_IMF_TEXT_3;   -- POI_IMF_TEXT_3
        vTplDocPositionImputation.POI_IMF_TEXT_4            := tplOriginalVentilation.POI_IMF_TEXT_4;   -- POI_IMF_TEXT_4
        vTplDocPositionImputation.POI_IMF_TEXT_5            := tplOriginalVentilation.POI_IMF_TEXT_5;   -- POI_IMF_TEXT_5
        vTplDocPositionImputation.C_FAM_TRANSACTION_TYP     := tplOriginalVentilation.C_FAM_TRANSACTION_TYP;   -- C_FAM_TRANSACTION_TYP
        vTplDocPositionImputation.FAM_FIXED_ASSETS_ID       := tplOriginalVentilation.FAM_FIXED_ASSETS_ID;   -- FAM_FIXED_ASSETS_ID
        vTplDocPositionImputation.HRM_PERSON_ID             := tplOriginalVentilation.HRM_PERSON_ID;   -- HRM_PERSON_ID
        vTplDocPositionImputation.A_DATECRE                 := sysdate;   -- A_DATECRE
        vTplDocPositionImputation.A_IDCRE                   := PCS.PC_I_LIB_SESSION.GetUserIni;   -- A_IDCRE
        DOC_IMPUTATION_FUNCTIONS.insertPositionImputation(vTplDocPositionImputation, aSimulation);

        if aSimulation = 0 then
          update DOC_POSITION
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aAmountPositionId;
        else
          update DOC_ESTIMATED_POS_CASH_FLOW
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aAmountPositionId;
        end if;

        -- ventilation des montants
        if aSimulation = 0 then
          DOC_IMPUTATION_FUNCTIONS.imputePosition(aAmountPositionId);
        else
          DOC_IMPUTATION_FUNCTIONS.imputeEstimatedPosition(aAmountPositionId);
        end if;
      end;
    end loop;

    -- Si une seule ventilation ramène les comptes sur la position
    DOC_IMPUTATION_FUNCTIONS.simplifyVentilation(aPositionId => aAmountPositionId, aSimulation => aSimulation);
  end ventilateDocAmountOnPos;

  /**
  * procedure ventilatePosAmountOnPos
  * Description
  *    applique la ventilation du document source sur une position en montant
  * @created fp 23.10.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param aNewDocumentId : id du nouveau document
  * @param aAmountPositionId : id de la position montant
  * @param aSourcePositionId : id du document source
  */
  procedure ventilatePosAmountOnPos(
    aNewDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAmountPositionId in DOC_POSITION.DOC_POSITION_ID%type
  , aSourcePositionId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSimulation       in number default 0
  )
  is
    cursor crOriginalVentilation(aCrPositionId number)
    is
      (select POI.POI_RATIO
            , POI.DOC_RECORD_ID
            , POI.ACS_PJ_ACCOUNT_ID
            , POI.ACS_PF_ACCOUNT_ID
            , POI.ACS_FINANCIAL_ACCOUNT_ID
            , POI.DIC_IMP_FREE1_ID
            , POI.DIC_IMP_FREE2_ID
            , POI.DIC_IMP_FREE3_ID
            , POI.DIC_IMP_FREE4_ID
            , POI.DIC_IMP_FREE5_ID
            , POI.C_FAM_TRANSACTION_TYP
            , POI.FAM_FIXED_ASSETS_ID
            , POI.HRM_PERSON_ID
            , POI.ACS_CDA_ACCOUNT_ID
            , POI.ACS_CPN_ACCOUNT_ID
            , POI.ACS_DIVISION_ACCOUNT_ID
            , POI.POI_IMF_NUMBER_1
            , POI.POI_IMF_NUMBER_2
            , POI.POI_IMF_NUMBER_3
            , POI.POI_IMF_NUMBER_4
            , POI.POI_IMF_NUMBER_5
            , POI.POI_IMF_TEXT_1
            , POI.POI_IMF_TEXT_2
            , POI.POI_IMF_TEXT_3
            , POI.POI_IMF_TEXT_4
            , POI.POI_IMF_TEXT_5
         from DOC_POSITION_IMPUTATION POI
            , DOC_POSITION POS
        where POI.DOC_POSITION_ID = aCrPositionId
          and POS.DOC_POSITION_Id = POI.DOC_POSITION_ID
          and POS.C_DOC_POS_STATUS <> '05'
          and POS.POS_IMPUTATION = 1
       union all
       select 1 POI_RATIO
            , DOC_RECORD_ID
            , ACS_PJ_ACCOUNT_ID
            , ACS_PF_ACCOUNT_ID
            , ACS_FINANCIAL_ACCOUNT_ID
            , DIC_IMP_FREE1_ID
            , DIC_IMP_FREE2_ID
            , DIC_IMP_FREE3_ID
            , DIC_IMP_FREE4_ID
            , DIC_IMP_FREE5_ID
            , C_FAM_TRANSACTION_TYP
            , FAM_FIXED_ASSETS_ID
            , HRM_PERSON_ID
            , ACS_CDA_ACCOUNT_ID
            , ACS_CPN_ACCOUNT_ID
            , ACS_DIVISION_ACCOUNT_ID
            , POS_NUMBER
            , POS_IMF_NUMBER_2
            , POS_IMF_NUMBER_3
            , POS_IMF_NUMBER_4
            , POS_IMF_NUMBER_5
            , POS_IMF_TEXT_1
            , POS_IMF_TEXT_2
            , POS_IMF_TEXT_3
            , POS_IMF_TEXT_4
            , POS_IMF_TEXT_5
         from DOC_POSITION POS
        where POS.DOC_POSITION_ID = aCrPositionId
          and POS.C_DOC_POS_STATUS <> '05'
          and POS.POS_IMPUTATION = 0)
      union all
      (select POI.POI_RATIO
            , POI.DOC_RECORD_ID
            , POI.ACS_PJ_ACCOUNT_ID
            , POI.ACS_PF_ACCOUNT_ID
            , POI.ACS_FINANCIAL_ACCOUNT_ID
            , POI.DIC_IMP_FREE1_ID
            , POI.DIC_IMP_FREE2_ID
            , POI.DIC_IMP_FREE3_ID
            , POI.DIC_IMP_FREE4_ID
            , POI.DIC_IMP_FREE5_ID
            , POI.C_FAM_TRANSACTION_TYP
            , POI.FAM_FIXED_ASSETS_ID
            , POI.HRM_PERSON_ID
            , POI.ACS_CDA_ACCOUNT_ID
            , POI.ACS_CPN_ACCOUNT_ID
            , POI.ACS_DIVISION_ACCOUNT_ID
            , POI.POI_IMF_NUMBER_1
            , POI.POI_IMF_NUMBER_2
            , POI.POI_IMF_NUMBER_3
            , POI.POI_IMF_NUMBER_4
            , POI.POI_IMF_NUMBER_5
            , POI.POI_IMF_TEXT_1
            , POI.POI_IMF_TEXT_2
            , POI.POI_IMF_TEXT_3
            , POI.POI_IMF_TEXT_4
            , POI.POI_IMF_TEXT_5
         from DOC_EST_POS_IMP_CASH_FLOW POI
            , DOC_ESTIMATED_POS_CASH_FLOW POS
        where POI.DOC_POSITION_ID = aCrPositionId
          and POS.DOC_POSITION_ID = POI.DOC_POSITION_ID
          and POS.POS_IMPUTATION = 1
       union all
       select 1 POI_RATIO
            , DOC_RECORD_ID
            , ACS_PJ_ACCOUNT_ID
            , ACS_PF_ACCOUNT_ID
            , ACS_FINANCIAL_ACCOUNT_ID
            , DIC_IMP_FREE1_ID
            , DIC_IMP_FREE2_ID
            , DIC_IMP_FREE3_ID
            , DIC_IMP_FREE4_ID
            , DIC_IMP_FREE5_ID
            , C_FAM_TRANSACTION_TYP
            , FAM_FIXED_ASSETS_ID
            , HRM_PERSON_ID
            , ACS_CDA_ACCOUNT_ID
            , ACS_CPN_ACCOUNT_ID
            , ACS_DIVISION_ACCOUNT_ID
            , POS_NUMBER
            , POS_IMF_NUMBER_2
            , POS_IMF_NUMBER_3
            , POS_IMF_NUMBER_4
            , POS_IMF_NUMBER_5
            , POS_IMF_TEXT_1
            , POS_IMF_TEXT_2
            , POS_IMF_TEXT_3
            , POS_IMF_TEXT_4
            , POS_IMF_TEXT_5
         from DOC_ESTIMATED_POS_CASH_FLOW POS
        where POS.DOC_POSITION_ID = aCrPositionId
          and POS.POS_IMPUTATION = 0);
  begin
    for tplOriginalVentilation in crOriginalVentilation(aSourcePositionId) loop
      declare
        vTplDocPositionImputation DOC_POSITION_IMPUTATION%rowtype;
      begin
        select INIT_ID_SEQ.nextval
          into vTplDocPositionImputation.DOC_POSITION_IMPUTATION_ID
          from dual;

        vTplDocPositionImputation.DOC_DOCUMENT_ID           := aNewDocumentID;   -- DOC_DOCUMENT_ID
        vTplDocPositionImputation.DOC_POSITION_ID           := aAmountPositionId;   -- DOC_POSITION_ID
        vTplDocPositionImputation.DOC_POSITION_CHARGE_ID    := null;   -- DOC_POSITION_CHARGE_ID
        vTplDocPositionImputation.DOC_FOOT_CHARGE_ID        := null;   -- DOC_FOOT_CHARGE_ID
        vTplDocPositionImputation.DOC_RECORD_ID             := tplOriginalVentilation.DOC_RECORD_ID;   -- DOC_RECORD_ID
        vTplDocPositionImputation.POI_RATIO                 := tplOriginalVentilation.POI_RATIO;   -- POI_RATIO
        vTplDocPositionImputation.ACS_FINANCIAL_ACCOUNT_ID  := tplOriginalVentilation.ACS_FINANCIAL_ACCOUNT_ID;   -- ACS_FINANCIAL_ACCOUNT_ID
        vTplDocPositionImputation.ACS_DIVISION_ACCOUNT_ID   := tplOriginalVentilation.ACS_DIVISION_ACCOUNT_ID;   -- ACS_DIVISION_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PJ_ACCOUNT_ID         := tplOriginalVentilation.ACS_PJ_ACCOUNT_ID;   -- ACS_PJ_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PF_ACCOUNT_ID         := tplOriginalVentilation.ACS_PF_ACCOUNT_ID;   -- ACS_PF_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CDA_ACCOUNT_ID        := tplOriginalVentilation.ACS_CDA_ACCOUNT_ID;   -- ACS_CDA_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CPN_ACCOUNT_ID        := tplOriginalVentilation.ACS_CPN_ACCOUNT_ID;   -- ACS_CPN_ACCOUNT_ID
        vTplDocPositionImputation.DIC_IMP_FREE1_ID          := tplOriginalVentilation.DIC_IMP_FREE1_ID;   -- DIC_IMP_FREE1_ID
        vTplDocPositionImputation.DIC_IMP_FREE2_ID          := tplOriginalVentilation.DIC_IMP_FREE2_ID;   -- DIC_IMP_FREE2_ID
        vTplDocPositionImputation.DIC_IMP_FREE3_ID          := tplOriginalVentilation.DIC_IMP_FREE3_ID;   -- DIC_IMP_FREE3_ID
        vTplDocPositionImputation.DIC_IMP_FREE4_ID          := tplOriginalVentilation.DIC_IMP_FREE4_ID;   -- DIC_IMP_FREE4_ID
        vTplDocPositionImputation.DIC_IMP_FREE5_ID          := tplOriginalVentilation.DIC_IMP_FREE5_ID;   -- DIC_IMP_FREE5_ID
        vTplDocPositionImputation.POI_IMF_NUMBER_1          := tplOriginalVentilation.POI_IMF_NUMBER_1;   -- POI_IMF_NUMBER_1
        vTplDocPositionImputation.POI_IMF_NUMBER_2          := tplOriginalVentilation.POI_IMF_NUMBER_2;   -- POI_IMF_NUMBER_2
        vTplDocPositionImputation.POI_IMF_NUMBER_3          := tplOriginalVentilation.POI_IMF_NUMBER_3;   -- POI_IMF_NUMBER_3
        vTplDocPositionImputation.POI_IMF_NUMBER_4          := tplOriginalVentilation.POI_IMF_NUMBER_4;   -- POI_IMF_NUMBER_4
        vTplDocPositionImputation.POI_IMF_NUMBER_5          := tplOriginalVentilation.POI_IMF_NUMBER_5;   -- POI_IMF_NUMBER_5
        vTplDocPositionImputation.POI_IMF_TEXT_1            := tplOriginalVentilation.POI_IMF_TEXT_1;   -- POI_IMF_TEXT_1
        vTplDocPositionImputation.POI_IMF_TEXT_2            := tplOriginalVentilation.POI_IMF_TEXT_2;   -- POI_IMF_TEXT_2
        vTplDocPositionImputation.POI_IMF_TEXT_3            := tplOriginalVentilation.POI_IMF_TEXT_3;   -- POI_IMF_TEXT_3
        vTplDocPositionImputation.POI_IMF_TEXT_4            := tplOriginalVentilation.POI_IMF_TEXT_4;   -- POI_IMF_TEXT_4
        vTplDocPositionImputation.POI_IMF_TEXT_5            := tplOriginalVentilation.POI_IMF_TEXT_5;   -- POI_IMF_TEXT_5
        vTplDocPositionImputation.C_FAM_TRANSACTION_TYP     := tplOriginalVentilation.C_FAM_TRANSACTION_TYP;   -- C_FAM_TRANSACTION_TYP
        vTplDocPositionImputation.FAM_FIXED_ASSETS_ID       := tplOriginalVentilation.FAM_FIXED_ASSETS_ID;   -- FAM_FIXED_ASSETS_ID
        vTplDocPositionImputation.HRM_PERSON_ID             := tplOriginalVentilation.HRM_PERSON_ID;   -- HRM_PERSON_ID
        vTplDocPositionImputation.A_DATECRE                 := sysdate;   -- A_DATECRE
        vTplDocPositionImputation.A_IDCRE                   := PCS.PC_I_LIB_SESSION.GetUserIni;   -- A_IDCRE
        DOC_IMPUTATION_FUNCTIONS.insertPositionImputation(vTplDocPositionImputation, aSimulation);

        if aSimulation = 1 then
          update DOC_ESTIMATED_POS_CASH_FLOW
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aAmountPositionId;
        else
          update DOC_POSITION
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aAmountPositionId;
        end if;
      end;
    end loop;

    -- ventilation des montants
    if aSimulation = 0 then
      DOC_IMPUTATION_FUNCTIONS.imputePosition(aAmountPositionId);
    else
      DOC_IMPUTATION_FUNCTIONS.imputeEstimatedPosition(aAmountPositionId);
    end if;

    -- Si une seule ventilation ramène les comptes sur la position
    DOC_IMPUTATION_FUNCTIONS.simplifyVentilation(aPositionId => aAmountPositionId, aSimulation => aSimulation);
  end ventilatePosAmountOnPos;

  /**
  * procedure ventilateDocRecordOnDepositPos
  * Description
  *    reprend la répartition des dossiers du document source
  *    mais les comptes liés au bien "Acompte"
  *    Utilisé dans le cas de l'échéancier global
  * @created fp 23.10.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param aNewDocumentId : id du nouveau document
  * @param aDepositPositionId : id de la position d'accompte
  * @param aSourceDocumentId : id du document source
  */
  procedure ventilateDocRecordOnDepositPos(
    aNewDocumentId     in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDepositPositionId in DOC_POSITION.DOC_POSITION_ID%type
  , aSourceDocumentId  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSimulation        in number default 0
  )
  is
    cursor crOriginalVentilation(aCrDocumentId number, aCrNewPositionId number)
    is
      select decode(total, 0, 0, poi_amount / total) poi_percent
           , DOC_RECORD_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , DIC_IMP_FREE1_ID
           , DIC_IMP_FREE2_ID
           , DIC_IMP_FREE3_ID
           , DIC_IMP_FREE4_ID
           , DIC_IMP_FREE5_ID
           , C_FAM_TRANSACTION_TYP
           , FAM_FIXED_ASSETS_ID
           , HRM_PERSON_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , POS_NUMBER
           , POS_IMF_NUMBER_2
           , POS_IMF_NUMBER_3
           , POS_IMF_NUMBER_4
           , POS_IMF_NUMBER_5
           , POS_IMF_TEXT_1
           , POS_IMF_TEXT_2
           , POS_IMF_TEXT_3
           , POS_IMF_TEXT_4
           , POS_IMF_TEXT_5
        from (select (select sum(nvl(pos_gross_value, 0) ) / 100
                        from doc_position
                       where DOC_DOCUMENT_ID = aCrDocumentId
                         and C_DOC_POS_STATUS <> '05'
                         and C_GAUGE_TYPE_POS not in('6') ) total
                   , poi_amount
                   , DOC_RECORD_ID
                   , ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , C_FAM_TRANSACTION_TYP
                   , FAM_FIXED_ASSETS_ID
                   , HRM_PERSON_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , POS_NUMBER
                   , POS_IMF_NUMBER_2
                   , POS_IMF_NUMBER_3
                   , POS_IMF_NUMBER_4
                   , POS_IMF_NUMBER_5
                   , POS_IMF_TEXT_1
                   , POS_IMF_TEXT_2
                   , POS_IMF_TEXT_3
                   , POS_IMF_TEXT_4
                   , POS_IMF_TEXT_5
                from (select   sum(poi.poi_amount) poi_amount
                             , POI.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , POS.POS_NUMBER
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                          from doc_position_imputation poi
                             , doc_position pos_poi
                             , doc_position pos
                         where poi.doc_document_id = aCrDocumentId
                           and pos_poi.doc_position_id = poi.doc_position_id
                           and pos_poi.c_doc_pos_status <> '05'
                           and pos.doc_position_id = aCrNewPositionId
                           and pos.c_doc_pos_status <> '05'
                           and poi_amount <> 0
                      group by POI.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , POS.POS_NUMBER
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                      union all
                      select   sum(poi.poi_amount) poi_amount
                             , POI.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , POS.POS_NUMBER
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                          from doc_position_imputation poi
                             , doc_position pos
                         where poi.doc_document_id = aCrDocumentId
                           and poi.doc_foot_charge_id is not null
                           and pos.doc_position_id = aCrNewPositionId
                           and pos.c_doc_pos_status <> '05'
                           and poi_amount <> 0
                      group by POI.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , POS.POS_NUMBER
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                      union all
                      select   sum(parent.pos_gross_value) poi_amount
                             , parent.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , null POS_IMF_NUMBER_1
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                          from DOC_POSITION parent
                             , DOC_POSITION POS
                         where parent.DOC_DOCUMENT_ID = aCrDocumentId
                           and parent.POS_IMPUTATION = 0
                           and parent.POS_GROSS_VALUE <> 0
                           and parent.C_GAUGE_TYPE_POS not in('6')
                           and POS.C_DOC_POS_STATUS <> '05'
                           and POS.DOC_POSITION_ID = aCrNewPositionId
                      group by parent.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             --, POS_NUMBER
                      ,        POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5) )
      union all
      select decode(total, 0, 0, poi_amount / total) poi_percent
           , DOC_RECORD_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , DIC_IMP_FREE1_ID
           , DIC_IMP_FREE2_ID
           , DIC_IMP_FREE3_ID
           , DIC_IMP_FREE4_ID
           , DIC_IMP_FREE5_ID
           , C_FAM_TRANSACTION_TYP
           , FAM_FIXED_ASSETS_ID
           , HRM_PERSON_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , POS_NUMBER
           , POS_IMF_NUMBER_2
           , POS_IMF_NUMBER_3
           , POS_IMF_NUMBER_4
           , POS_IMF_NUMBER_5
           , POS_IMF_TEXT_1
           , POS_IMF_TEXT_2
           , POS_IMF_TEXT_3
           , POS_IMF_TEXT_4
           , POS_IMF_TEXT_5
        from (select (select sum(nvl(pos_gross_value, 0) ) / 100
                        from doc_position
                       where DOC_DOCUMENT_ID = aCrDocumentId
                         and C_DOC_POS_STATUS <> '05'
                         and C_GAUGE_TYPE_POS not in('6') ) total
                   , poi_amount
                   , DOC_RECORD_ID
                   , ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , C_FAM_TRANSACTION_TYP
                   , FAM_FIXED_ASSETS_ID
                   , HRM_PERSON_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , POS_NUMBER
                   , POS_IMF_NUMBER_2
                   , POS_IMF_NUMBER_3
                   , POS_IMF_NUMBER_4
                   , POS_IMF_NUMBER_5
                   , POS_IMF_TEXT_1
                   , POS_IMF_TEXT_2
                   , POS_IMF_TEXT_3
                   , POS_IMF_TEXT_4
                   , POS_IMF_TEXT_5
                from (select   sum(poi.poi_amount) poi_amount
                             , POI.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , POS.POS_NUMBER
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                          from DOC_POSITION_IMPUTATION poi
                             , DOC_ESTIMATED_POS_CASH_FLOW pos
                         where poi.doc_document_id = aCrDocumentId
                           and nvl(poi.doc_position_id, poi.doc_foot_charge_id) is not null
                           and pos.doc_position_id = aCrNewPositionId
                           and poi_amount <> 0
                      group by POI.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , POS.POS_NUMBER
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                      union all
                      select   sum(parent.pos_gross_value) poi_amount
                             , parent.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             , null POS_IMF_NUMBER_1
                             , POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5
                          from DOC_POSITION parent
                             , DOC_ESTIMATED_POS_CASH_FLOW POS
                         where parent.DOC_DOCUMENT_ID = aCrDocumentId
                           and parent.POS_IMPUTATION = 0
                           and parent.POS_GROSS_VALUE <> 0
                           and parent.C_GAUGE_TYPE_POS not in('6')
                           and POS.DOC_POSITION_ID = aCrNewPositionId
                      group by parent.DOC_RECORD_ID
                             , POS.ACS_PJ_ACCOUNT_ID
                             , POS.ACS_PF_ACCOUNT_ID
                             , POS.ACS_FINANCIAL_ACCOUNT_ID
                             , POS.DIC_IMP_FREE1_ID
                             , POS.DIC_IMP_FREE2_ID
                             , POS.DIC_IMP_FREE3_ID
                             , POS.DIC_IMP_FREE4_ID
                             , POS.DIC_IMP_FREE5_ID
                             , POS.C_FAM_TRANSACTION_TYP
                             , POS.FAM_FIXED_ASSETS_ID
                             , POS.HRM_PERSON_ID
                             , POS.ACS_CDA_ACCOUNT_ID
                             , POS.ACS_CPN_ACCOUNT_ID
                             , POS.ACS_DIVISION_ACCOUNT_ID
                             --, POS_NUMBER
                      ,        POS.POS_IMF_NUMBER_2
                             , POS.POS_IMF_NUMBER_3
                             , POS.POS_IMF_NUMBER_4
                             , POS.POS_IMF_NUMBER_5
                             , POS.POS_IMF_TEXT_1
                             , POS.POS_IMF_TEXT_2
                             , POS.POS_IMF_TEXT_3
                             , POS.POS_IMF_TEXT_4
                             , POS.POS_IMF_TEXT_5) );
  begin
    for tplOriginalVentilation in crOriginalVentilation(aSourceDocumentId, aDepositPositionId) loop
      declare
        vTplDocPositionImputation DOC_POSITION_IMPUTATION%rowtype;
      begin
        select INIT_ID_SEQ.nextval
          into vTplDocPositionImputation.DOC_POSITION_IMPUTATION_ID
          from dual;

        vTplDocPositionImputation.DOC_DOCUMENT_ID           := aNewDocumentID;   -- DOC_DOCUMENT_ID
        vTplDocPositionImputation.DOC_POSITION_ID           := aDepositPositionID;   -- DOC_POSITION_ID
        vTplDocPositionImputation.DOC_POSITION_CHARGE_ID    := null;   -- DOC_POSITION_CHARGE_ID
        vTplDocPositionImputation.DOC_FOOT_CHARGE_ID        := null;   -- DOC_FOOT_CHARGE_ID
        vTplDocPositionImputation.DOC_RECORD_ID             := tplOriginalVentilation.DOC_RECORD_ID;   -- DOC_RECORD_ID
        vTplDocPositionImputation.POI_RATIO                 := tplOriginalVentilation.POI_PERCENT;   -- POI_RATIO
        vTplDocPositionImputation.ACS_FINANCIAL_ACCOUNT_ID  := tplOriginalVentilation.ACS_FINANCIAL_ACCOUNT_ID;   -- ACS_FINANCIAL_ACCOUNT_ID
        vTplDocPositionImputation.ACS_DIVISION_ACCOUNT_ID   := tplOriginalVentilation.ACS_DIVISION_ACCOUNT_ID;   -- ACS_DIVISION_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PJ_ACCOUNT_ID         := tplOriginalVentilation.ACS_PJ_ACCOUNT_ID;   -- ACS_PJ_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PF_ACCOUNT_ID         := tplOriginalVentilation.ACS_PF_ACCOUNT_ID;   -- ACS_PF_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CDA_ACCOUNT_ID        := tplOriginalVentilation.ACS_CDA_ACCOUNT_ID;   -- ACS_CDA_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CPN_ACCOUNT_ID        := tplOriginalVentilation.ACS_CPN_ACCOUNT_ID;   -- ACS_CPN_ACCOUNT_ID
        vTplDocPositionImputation.DIC_IMP_FREE1_ID          := tplOriginalVentilation.DIC_IMP_FREE1_ID;   -- DIC_IMP_FREE1_ID
        vTplDocPositionImputation.DIC_IMP_FREE2_ID          := tplOriginalVentilation.DIC_IMP_FREE2_ID;   -- DIC_IMP_FREE2_ID
        vTplDocPositionImputation.DIC_IMP_FREE3_ID          := tplOriginalVentilation.DIC_IMP_FREE3_ID;   -- DIC_IMP_FREE3_ID
        vTplDocPositionImputation.DIC_IMP_FREE4_ID          := tplOriginalVentilation.DIC_IMP_FREE4_ID;   -- DIC_IMP_FREE4_ID
        vTplDocPositionImputation.DIC_IMP_FREE5_ID          := tplOriginalVentilation.DIC_IMP_FREE5_ID;   -- DIC_IMP_FREE5_ID
        vTplDocPositionImputation.POI_IMF_NUMBER_1          := tplOriginalVentilation.POS_NUMBER;   -- POI_IMF_NUMBER_1
        vTplDocPositionImputation.POI_IMF_NUMBER_2          := tplOriginalVentilation.POS_IMF_NUMBER_2;   -- POI_IMF_NUMBER_2
        vTplDocPositionImputation.POI_IMF_NUMBER_3          := tplOriginalVentilation.POS_IMF_NUMBER_3;   -- POI_IMF_NUMBER_3
        vTplDocPositionImputation.POI_IMF_NUMBER_4          := tplOriginalVentilation.POS_IMF_NUMBER_4;   -- POI_IMF_NUMBER_4
        vTplDocPositionImputation.POI_IMF_NUMBER_5          := tplOriginalVentilation.POS_IMF_NUMBER_5;   -- POI_IMF_NUMBER_5
        vTplDocPositionImputation.POI_IMF_TEXT_1            := tplOriginalVentilation.POS_IMF_TEXT_1;   -- POI_IMF_TEXT_1
        vTplDocPositionImputation.POI_IMF_TEXT_2            := tplOriginalVentilation.POS_IMF_TEXT_2;   -- POI_IMF_TEXT_2
        vTplDocPositionImputation.POI_IMF_TEXT_3            := tplOriginalVentilation.POS_IMF_TEXT_3;   -- POI_IMF_TEXT_3
        vTplDocPositionImputation.POI_IMF_TEXT_4            := tplOriginalVentilation.POS_IMF_TEXT_4;   -- POI_IMF_TEXT_4
        vTplDocPositionImputation.POI_IMF_TEXT_5            := tplOriginalVentilation.POS_IMF_TEXT_5;   -- POI_IMF_TEXT_5
        vTplDocPositionImputation.C_FAM_TRANSACTION_TYP     := tplOriginalVentilation.C_FAM_TRANSACTION_TYP;   -- C_FAM_TRANSACTION_TYP
        vTplDocPositionImputation.FAM_FIXED_ASSETS_ID       := tplOriginalVentilation.FAM_FIXED_ASSETS_ID;   -- FAM_FIXED_ASSETS_ID
        vTplDocPositionImputation.HRM_PERSON_ID             := tplOriginalVentilation.HRM_PERSON_ID;   -- HRM_PERSON_ID
        vTplDocPositionImputation.A_DATECRE                 := sysdate;   -- A_DATECRE
        vTplDocPositionImputation.A_IDCRE                   := PCS.PC_I_LIB_SESSION.GetUserIni;   -- A_IDCRE
        DOC_IMPUTATION_FUNCTIONS.insertPositionImputation(vTplDocPositionImputation, aSimulation);

        if aSimulation = 0 then
          update DOC_POSITION
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aDepositPositionId;
        else
          update DOC_ESTIMATED_POS_CASH_FLOW
             set POS_IMPUTATION = 1
           where DOC_POSITION_ID = aDepositPositionId;
        end if;
      end;
    end loop;

    if aSimulation = 0 then
      -- ventilation des montants
      DOC_IMPUTATION_FUNCTIONS.imputePosition(aDepositPositionId);
    else
      -- ventilation des montants
      DOC_IMPUTATION_FUNCTIONS.imputeEstimatedPosition(aDepositPositionId);
    end if;

    -- Si une seule ventilation ramène les comptes sur la position
    DOC_IMPUTATION_FUNCTIONS.simplifyVentilation(aPositionId => aDepositPositionId, aSimulation => aSimulation);
  end ventilateDocRecordOnDepositPos;

  /**
  * procedure ventilatePosRecordOnDepositPos
  * Description
  *    reprend la répartition des dossiers du document source
  *    mais les comptes liés au bien "Acompte"
  *    Utilisé dans le cas de l'échéancier global
  * @created fp 23.10.2006
  * @lastUpdate fp 19.08.2008
  * @private
  * @param aNewDocumentId : id du nouveau document
  * @param aDepositPositionId : id de la position d'accompte
  * @param aSourceDocumentId : id du document source
  */
  procedure ventilatePosRecordOnDepositPos(
    aNewDocumentId     in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDepositPositionId in DOC_POSITION.DOC_POSITION_ID%type
  , aSourcePositionId  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSimulation        in number default 0
  )
  is
    cursor crOriginalVentilation(aCrPositionId number, aCrNewPositionId number)
    is
      select POI_RATIO
           , POI.DOC_RECORD_ID
           , POS.ACS_PJ_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID
           , POS.ACS_FINANCIAL_ACCOUNT_ID
           , POS.DIC_IMP_FREE1_ID
           , POS.DIC_IMP_FREE2_ID
           , POS.DIC_IMP_FREE3_ID
           , POS.DIC_IMP_FREE4_ID
           , POS.DIC_IMP_FREE5_ID
           , POS.C_FAM_TRANSACTION_TYP
           , POS.FAM_FIXED_ASSETS_ID
           , POS.HRM_PERSON_ID
           , POS.ACS_CDA_ACCOUNT_ID
           , POS.ACS_CPN_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID
           , POS.POS_NUMBER
           , POS.POS_IMF_NUMBER_2
           , POS.POS_IMF_NUMBER_3
           , POS.POS_IMF_NUMBER_4
           , POS.POS_IMF_NUMBER_5
           , POS.POS_IMF_TEXT_1
           , POS.POS_IMF_TEXT_2
           , POS.POS_IMF_TEXT_3
           , POS.POS_IMF_TEXT_4
           , POS.POS_IMF_TEXT_5
        from doc_position_imputation poi
           , doc_position pos_poi
           , doc_position pos
       where poi.doc_position_id = aCrPositionId
         and pos_poi.doc_position_id = poi.doc_position_id
         and pos_poi.c_doc_pos_status <> '05'
         and pos.doc_position_id = aCrNewPositionId
         and pos.c_doc_pos_status <> '05'
      union all
      select 1 POI_RATIO
           , POI.DOC_RECORD_ID
           , POS.ACS_PJ_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID
           , POS.ACS_FINANCIAL_ACCOUNT_ID
           , POS.DIC_IMP_FREE1_ID
           , POS.DIC_IMP_FREE2_ID
           , POS.DIC_IMP_FREE3_ID
           , POS.DIC_IMP_FREE4_ID
           , POS.DIC_IMP_FREE5_ID
           , POS.C_FAM_TRANSACTION_TYP
           , POS.FAM_FIXED_ASSETS_ID
           , POS.HRM_PERSON_ID
           , POS.ACS_CDA_ACCOUNT_ID
           , POS.ACS_CPN_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID
           , POS.POS_NUMBER
           , POS.POS_IMF_NUMBER_2
           , POS.POS_IMF_NUMBER_3
           , POS.POS_IMF_NUMBER_4
           , POS.POS_IMF_NUMBER_5
           , POS.POS_IMF_TEXT_1
           , POS.POS_IMF_TEXT_2
           , POS.POS_IMF_TEXT_3
           , POS.POS_IMF_TEXT_4
           , POS.POS_IMF_TEXT_5
        from doc_position poi
           , doc_position pos
       where poi.doc_position_id = aCrPositionId
         and poi.c_doc_pos_status <> '05'
         and pos.doc_position_id = aCrNewPositionId
         and pos.c_doc_pos_status <> '05'
         and poi.pos_imputation = 0
      union all
      select POI_RATIO
           , POI.DOC_RECORD_ID
           , POS.ACS_PJ_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID
           , POS.ACS_FINANCIAL_ACCOUNT_ID
           , POS.DIC_IMP_FREE1_ID
           , POS.DIC_IMP_FREE2_ID
           , POS.DIC_IMP_FREE3_ID
           , POS.DIC_IMP_FREE4_ID
           , POS.DIC_IMP_FREE5_ID
           , POS.C_FAM_TRANSACTION_TYP
           , POS.FAM_FIXED_ASSETS_ID
           , POS.HRM_PERSON_ID
           , POS.ACS_CDA_ACCOUNT_ID
           , POS.ACS_CPN_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID
           , POS.POS_NUMBER
           , POS.POS_IMF_NUMBER_2
           , POS.POS_IMF_NUMBER_3
           , POS.POS_IMF_NUMBER_4
           , POS.POS_IMF_NUMBER_5
           , POS.POS_IMF_TEXT_1
           , POS.POS_IMF_TEXT_2
           , POS.POS_IMF_TEXT_3
           , POS.POS_IMF_TEXT_4
           , POS.POS_IMF_TEXT_5
        from doc_position_imputation poi
           , DOC_ESTIMATED_POS_CASH_FLOW pos
       where poi.doc_position_id = aCrPositionId
         and pos.doc_position_id = aCrNewPositionId
      union all
      select 1 POI_RATIO
           , POI.DOC_RECORD_ID
           , POS.ACS_PJ_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID
           , POS.ACS_FINANCIAL_ACCOUNT_ID
           , POS.DIC_IMP_FREE1_ID
           , POS.DIC_IMP_FREE2_ID
           , POS.DIC_IMP_FREE3_ID
           , POS.DIC_IMP_FREE4_ID
           , POS.DIC_IMP_FREE5_ID
           , POS.C_FAM_TRANSACTION_TYP
           , POS.FAM_FIXED_ASSETS_ID
           , POS.HRM_PERSON_ID
           , POS.ACS_CDA_ACCOUNT_ID
           , POS.ACS_CPN_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID
           , POS.POS_NUMBER
           , POS.POS_IMF_NUMBER_2
           , POS.POS_IMF_NUMBER_3
           , POS.POS_IMF_NUMBER_4
           , POS.POS_IMF_NUMBER_5
           , POS.POS_IMF_TEXT_1
           , POS.POS_IMF_TEXT_2
           , POS.POS_IMF_TEXT_3
           , POS.POS_IMF_TEXT_4
           , POS.POS_IMF_TEXT_5
        from doc_position poi
           , DOC_ESTIMATED_POS_CASH_FLOW pos
       where poi.doc_position_id = aCrPositionId
         and pos.doc_position_id = aCrNewPositionId
         and poi.pos_imputation = 0;

    vIsVentilation pls_integer;
  begin
    for tplOriginalVentilation in crOriginalVentilation(aSourcePositionId, aDepositPositionId) loop
      declare
        vTplDocPositionImputation DOC_POSITION_IMPUTATION%rowtype;
      begin
        select INIT_ID_SEQ.nextval
          into vTplDocPositionImputation.DOC_POSITION_IMPUTATION_ID
          from dual;

        vTplDocPositionImputation.DOC_DOCUMENT_ID           := aNewDocumentID;   -- DOC_DOCUMENT_ID
        vTplDocPositionImputation.DOC_POSITION_ID           := aDepositPositionID;   -- DOC_POSITION_ID
        vTplDocPositionImputation.DOC_POSITION_CHARGE_ID    := null;   -- DOC_POSITION_CHARGE_ID
        vTplDocPositionImputation.DOC_FOOT_CHARGE_ID        := null;   -- DOC_FOOT_CHARGE_ID
        vTplDocPositionImputation.DOC_RECORD_ID             := tplOriginalVentilation.DOC_RECORD_ID;   -- DOC_RECORD_ID
        vTplDocPositionImputation.POI_RATIO                 := tplOriginalVentilation.POI_RATIO;   -- POI_RATIO
        vTplDocPositionImputation.ACS_FINANCIAL_ACCOUNT_ID  := tplOriginalVentilation.ACS_FINANCIAL_ACCOUNT_ID;   -- ACS_FINANCIAL_ACCOUNT_ID
        vTplDocPositionImputation.ACS_DIVISION_ACCOUNT_ID   := tplOriginalVentilation.ACS_DIVISION_ACCOUNT_ID;   -- ACS_DIVISION_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PJ_ACCOUNT_ID         := tplOriginalVentilation.ACS_PJ_ACCOUNT_ID;   -- ACS_PJ_ACCOUNT_ID
        vTplDocPositionImputation.ACS_PF_ACCOUNT_ID         := tplOriginalVentilation.ACS_PF_ACCOUNT_ID;   -- ACS_PF_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CDA_ACCOUNT_ID        := tplOriginalVentilation.ACS_CDA_ACCOUNT_ID;   -- ACS_CDA_ACCOUNT_ID
        vTplDocPositionImputation.ACS_CPN_ACCOUNT_ID        := tplOriginalVentilation.ACS_CPN_ACCOUNT_ID;   -- ACS_CPN_ACCOUNT_ID
        vTplDocPositionImputation.DIC_IMP_FREE1_ID          := tplOriginalVentilation.DIC_IMP_FREE1_ID;   -- DIC_IMP_FREE1_ID
        vTplDocPositionImputation.DIC_IMP_FREE2_ID          := tplOriginalVentilation.DIC_IMP_FREE2_ID;   -- DIC_IMP_FREE2_ID
        vTplDocPositionImputation.DIC_IMP_FREE3_ID          := tplOriginalVentilation.DIC_IMP_FREE3_ID;   -- DIC_IMP_FREE3_ID
        vTplDocPositionImputation.DIC_IMP_FREE4_ID          := tplOriginalVentilation.DIC_IMP_FREE4_ID;   -- DIC_IMP_FREE4_ID
        vTplDocPositionImputation.DIC_IMP_FREE5_ID          := tplOriginalVentilation.DIC_IMP_FREE5_ID;   -- DIC_IMP_FREE5_ID
        vTplDocPositionImputation.POI_IMF_NUMBER_1          := tplOriginalVentilation.POS_NUMBER;   -- POI_IMF_NUMBER_1
        vTplDocPositionImputation.POI_IMF_NUMBER_2          := tplOriginalVentilation.POS_IMF_NUMBER_2;   -- POI_IMF_NUMBER_2
        vTplDocPositionImputation.POI_IMF_NUMBER_3          := tplOriginalVentilation.POS_IMF_NUMBER_3;   -- POI_IMF_NUMBER_3
        vTplDocPositionImputation.POI_IMF_NUMBER_4          := tplOriginalVentilation.POS_IMF_NUMBER_4;   -- POI_IMF_NUMBER_4
        vTplDocPositionImputation.POI_IMF_NUMBER_5          := tplOriginalVentilation.POS_IMF_NUMBER_5;   -- POI_IMF_NUMBER_5
        vTplDocPositionImputation.POI_IMF_TEXT_1            := tplOriginalVentilation.POS_IMF_TEXT_1;   -- POI_IMF_TEXT_1
        vTplDocPositionImputation.POI_IMF_TEXT_2            := tplOriginalVentilation.POS_IMF_TEXT_2;   -- POI_IMF_TEXT_2
        vTplDocPositionImputation.POI_IMF_TEXT_3            := tplOriginalVentilation.POS_IMF_TEXT_3;   -- POI_IMF_TEXT_3
        vTplDocPositionImputation.POI_IMF_TEXT_4            := tplOriginalVentilation.POS_IMF_TEXT_4;   -- POI_IMF_TEXT_4
        vTplDocPositionImputation.POI_IMF_TEXT_5            := tplOriginalVentilation.POS_IMF_TEXT_5;   -- POI_IMF_TEXT_5
        vTplDocPositionImputation.C_FAM_TRANSACTION_TYP     := tplOriginalVentilation.C_FAM_TRANSACTION_TYP;   -- C_FAM_TRANSACTION_TYP
        vTplDocPositionImputation.FAM_FIXED_ASSETS_ID       := tplOriginalVentilation.FAM_FIXED_ASSETS_ID;   -- FAM_FIXED_ASSETS_ID
        vTplDocPositionImputation.HRM_PERSON_ID             := tplOriginalVentilation.HRM_PERSON_ID;   -- HRM_PERSON_ID
        vTplDocPositionImputation.A_DATECRE                 := sysdate;   -- A_DATECRE
        vTplDocPositionImputation.A_IDCRE                   := PCS.PC_I_LIB_SESSION.GetUserIni;   -- A_IDCRE
        DOC_IMPUTATION_FUNCTIONS.insertPositionImputation(vTplDocPositionImputation, aSimulation);

        if aSimulation = 0 then
          update    DOC_POSITION
                set POS_IMPUTATION = 1
              where DOC_POSITION_ID = aDepositPositionId
          returning POS_IMPUTATION
               into vIsVentilation;
        else
          update    DOC_ESTIMATED_POS_CASH_FLOW
                set POS_IMPUTATION = 1
              where DOC_POSITION_ID = aDepositPositionId
          returning POS_IMPUTATION
               into vIsVentilation;
        end if;
      end;
    end loop;

    -- ventilation des montants
    if vIsVentilation = 1 then
      if aSimulation = 0 then
        DOC_IMPUTATION_FUNCTIONS.imputePosition(aDepositPositionId);
      else
        DOC_IMPUTATION_FUNCTIONS.imputeEstimatedPosition(aDepositPositionId);
      end if;

      -- Si une seule ventilation ramène les comptes sur la position
      DOC_IMPUTATION_FUNCTIONS.simplifyVentilation(aPositionId => aDepositPositionId, aSimulation => aSimulation);
    else
      if aSimulation = 0 then
        update DOC_POSITION
           set DOC_RECORD_ID = (select DOC_RECORD_ID
                                  from DOC_POSITION
                                 where DOC_POSITION_ID = aSourcePositionId)
         where DOC_POSITION_ID = aDepositPositionId;
      else
        update DOC_ESTIMATED_POS_CASH_FLOW
           set DOC_RECORD_ID = (select DOC_RECORD_ID
                                  from DOC_POSITION
                                 where DOC_POSITION_ID = aSourcePositionId)
         where DOC_POSITION_ID = aDepositPositionId;
      end if;
    end if;
  end ventilatePosRecordOnDepositPos;

  /**
  * procedure dischargeDetail
  * Description
  *    décharge d'un détail dans la facture finale
  * @created fp 07.09.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param ANewDocumentID : Id du document cible
  * @param aInvoiceExpiryId : id de l'échéancier
  * @param ADetailID      : Id du détail à décharger
  * @param aGaugeFlowId      : Id du flux
  * @param aDischargeAmount      : Forcer le montant à décharger
  * @param aDischargeQuantity : quantité à décharger (en cas de décharge partielles ou supérieures à la quantité d'origine)
  * @param out aErrorCode : code d'erreur si problème
  */
  procedure dischargeDetail(
    aNewDocumentID     in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId   in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aDetailID          in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aGaugeFlowId       in     DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type
  , aDischargeAmount   in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type default null
  , aDischargeQuantity in out DOC_INVOICE_EXPIRY_DETAIL.IED_DISCHARGE_QUANTITY%type
  , aErrorCode         out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
  is
    cursor crDischargePositionDetail(
      aCrDetailID          in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aCrNewDocumentId     in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aCrDischargeAmount   in DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
    , aCrDischargeQuantity in number
    )
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , decode(aCrDischargeAmount
                           , null, least(nvl(aCrDischargeQuantity, PDE.PDE_BALANCE_QUANTITY), PDE.PDE_BALANCE_QUANTITY)
                           , decode(POS.POS_NET_VALUE_EXCL, 0, 0, aCrDischargeAmount / POS.POS_NET_VALUE_EXCL)
                            ) DCD_QUANTITY
                    , decode(aCrDischargeAmount
                           , null, ACS_FUNCTION.RoundNear(least(nvl(aCrDischargeQuantity, PDE.PDE_BALANCE_QUANTITY), PDE.PDE_BALANCE_QUANTITY) *
                                                          POS.POS_CONVERT_FACTOR
                                                        , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                        , 1
                                                         )
                           , decode(POS.POS_NET_VALUE_EXCL, 0, 0, aCrDischargeAmount / POS.POS_NET_VALUE_EXCL)
                            ) DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, NEW_DMT.DOC_GAUGE_ID, NEW_DMT.PAC_THIRD_ID) as DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , NEW_DMT.DOC_GAUGE_ID NEW_GAUGE_ID
                    , NEW_DMT.PAC_THIRD_ID NEW_THIRD_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_GAUGE GAU
                    , DOC_DOCUMENT NEW_DMT
                where PDE.DOC_POSITION_DETAIL_ID = aCrDetailID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                  and NEW_DMT.DOC_DOCUMENT_ID = aCrNewDocumentId;

    cursor crDischargePositionDetailCPT(
      aCrNewDocumentID     in number
    , aCrPositionID        in number
    , aCrTgtGaugeID        in number
    , aCrThirdID           in number
    , aCrDischargeQuantity in number
    )
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , (nvl(aCrDischargeQuantity, DCD.DCD_QUANTITY) * nvl(POS.POS_UTIL_COEFF, 1) ) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(nvl(aCrDischargeQuantity, DCD.DCD_QUANTITY) * nvl(POS.POS_UTIL_COEFF, 1) * POS.POS_CONVERT_FACTOR
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aCrTgtGaugeID, aCrThirdID) as DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , POS.POS_NUMBER
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID = aCrPositionID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and DCD.NEW_DOCUMENT_ID = aCrNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    vSourcePositionId          DOC_POSITION.DOC_POSITION_ID%type;
    vStrTypePos                DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    vPTPositionID              DOC_POSITION.DOC_POSITION_ID%type;
    vNewID                     DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vQuantityCPT               DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    vQuantityCPT_SU            DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
    vGreatestSumQuantityCPT    DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    vGreatestSumQuantityCPT_SU DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
    vInputData                 varchar2(32000);
    vTargetPositionId          DOC_POSITION.DOC_POSITION_ID%type;
    vDischargeInfoCode         varchar2(10);
  begin
    -- Si on décharge tout ou qu'il reste un solde à décharger
    if    aDischargeQuantity is null
       or aDischargeQuantity <> 0 then
      /* Détail de position à décharger */
      for tplDischargePositionDetail in crDischargePositionDetail(aDetailID, aNewDocumentId, aDischargeAmount, aDischargeQuantity) loop
        select init_id_seq.nextval
          into vNewID
          from dual;

        insert into V_DOC_POS_DET_COPY_DISCHARGE
                    (DOC_POS_DET_COPY_DISCHARGE_ID
                   , DOC_POSITION_DETAIL_ID
                   , NEW_DOCUMENT_ID
                   , CRG_SELECT
                   , DOC_GAUGE_FLOW_ID
                   , DOC_POSITION_ID
                   , DOC_DOC_POSITION_ID
                   , DOC_DOC_POSITION_DETAIL_ID
                   , DOC2_DOC_POSITION_DETAIL_ID
                   , DOC_INVOICE_EXPIRY_ID
                   , GCO_GOOD_ID
                   , STM_LOCATION_ID
                   , GCO_CHARACTERIZATION_ID
                   , GCO_GCO_CHARACTERIZATION_ID
                   , GCO2_GCO_CHARACTERIZATION_ID
                   , GCO3_GCO_CHARACTERIZATION_ID
                   , GCO4_GCO_CHARACTERIZATION_ID
                   , STM_STM_LOCATION_ID
                   , DIC_PDE_FREE_TABLE_1_ID
                   , DIC_PDE_FREE_TABLE_2_ID
                   , DIC_PDE_FREE_TABLE_3_ID
                   , FAL_SCHEDULE_STEP_ID
                   , DOC_RECORD_ID
                   , DOC_DOCUMENT_ID
                   , PAC_THIRD_ID
                   , DOC_GAUGE_ID
                   , DOC_GAUGE_RECEIPT_ID
                   , DOC_GAUGE_COPY_ID
                   , C_GAUGE_TYPE_POS
                   , DIC_DELAY_UPDATE_TYPE_ID
                   , PDE_BASIS_DELAY
                   , PDE_INTERMEDIATE_DELAY
                   , PDE_FINAL_DELAY
                   , PDE_SQM_ACCEPTED_DELAY
                   , PDE_BASIS_QUANTITY
                   , PDE_INTERMEDIATE_QUANTITY
                   , PDE_FINAL_QUANTITY
                   , PDE_BALANCE_QUANTITY
                   , PDE_BALANCE_QUANTITY_PARENT
                   , PDE_BASIS_QUANTITY_SU
                   , PDE_INTERMEDIATE_QUANTITY_SU
                   , PDE_FINAL_QUANTITY_SU
                   , PDE_MOVEMENT_QUANTITY
                   , PDE_MOVEMENT_VALUE
                   , PDE_CHARACTERIZATION_VALUE_1
                   , PDE_CHARACTERIZATION_VALUE_2
                   , PDE_CHARACTERIZATION_VALUE_3
                   , PDE_CHARACTERIZATION_VALUE_4
                   , PDE_CHARACTERIZATION_VALUE_5
                   , PDE_DELAY_UPDATE_TEXT
                   , PDE_DECIMAL_1
                   , PDE_DECIMAL_2
                   , PDE_DECIMAL_3
                   , PDE_TEXT_1
                   , PDE_TEXT_2
                   , PDE_TEXT_3
                   , PDE_DATE_1
                   , PDE_DATE_2
                   , PDE_DATE_3
                   , PDE_GENERATE_MOVEMENT
                   , DCD_QUANTITY
                   , DCD_QUANTITY_SU
                   , DCD_BALANCE_FLAG
                   , POS_CONVERT_FACTOR
                   , POS_CONVERT_FACTOR_CALC
                   , POS_GROSS_UNIT_VALUE
                   , POS_GROSS_UNIT_VALUE_INCL
                   , POS_UNIT_OF_MEASURE_ID
                   , DCD_DEPLOYED_COMPONENTS
                   , DCD_VISIBLE
                   , C_PDE_CREATE_MODE
                   , DCD_FORCE_AMOUNT
                   , POS_NET_VALUE_EXCL
                   , A_DATECRE
                   , A_IDCRE
                   , PDE_ST_PT_REJECT
                   , PDE_ST_CPT_REJECT
                    )
             values (vNewID
                   , tplDischargePositionDetail.DOC_POSITION_DETAIL_ID
                   , ANewDocumentID
                   , tplDischargePositionDetail.CRG_SELECT
                   , aGaugeFlowId
                   , tplDischargePositionDetail.DOC_POSITION_ID
                   , tplDischargePositionDetail.DOC_DOC_POSITION_ID
                   , tplDischargePositionDetail.DOC_DOC_POSITION_DETAIL_ID
                   , tplDischargePositionDetail.DOC2_DOC_POSITION_DETAIL_ID
                   , aInvoiceExpiryId
                   , tplDischargePositionDetail.GCO_GOOD_ID
                   , tplDischargePositionDetail.STM_LOCATION_ID
                   , tplDischargePositionDetail.GCO_CHARACTERIZATION_ID
                   , tplDischargePositionDetail.GCO_GCO_CHARACTERIZATION_ID
                   , tplDischargePositionDetail.GCO2_GCO_CHARACTERIZATION_ID
                   , tplDischargePositionDetail.GCO3_GCO_CHARACTERIZATION_ID
                   , tplDischargePositionDetail.GCO4_GCO_CHARACTERIZATION_ID
                   , tplDischargePositionDetail.STM_STM_LOCATION_ID
                   , tplDischargePositionDetail.DIC_PDE_FREE_TABLE_1_ID
                   , tplDischargePositionDetail.DIC_PDE_FREE_TABLE_2_ID
                   , tplDischargePositionDetail.DIC_PDE_FREE_TABLE_3_ID
                   , tplDischargePositionDetail.FAL_SCHEDULE_STEP_ID
                   , tplDischargePositionDetail.DOC_RECORD_ID
                   , tplDischargePositionDetail.DOC_DOCUMENT_ID
                   , tplDischargePositionDetail.PAC_THIRD_ID
                   , tplDischargePositionDetail.DOC_GAUGE_ID
                   , tplDischargePositionDetail.DOC_GAUGE_RECEIPT_ID
                   , tplDischargePositionDetail.DOC_GAUGE_COPY_ID
                   , tplDischargePositionDetail.C_GAUGE_TYPE_POS
                   , tplDischargePositionDetail.DIC_DELAY_UPDATE_TYPE_ID
                   , tplDischargePositionDetail.PDE_BASIS_DELAY
                   , tplDischargePositionDetail.PDE_INTERMEDIATE_DELAY
                   , tplDischargePositionDetail.PDE_FINAL_DELAY
                   , tplDischargePositionDetail.PDE_SQM_ACCEPTED_DELAY
                   , tplDischargePositionDetail.PDE_BASIS_QUANTITY
                   , tplDischargePositionDetail.PDE_INTERMEDIATE_QUANTITY
                   , tplDischargePositionDetail.PDE_FINAL_QUANTITY
                   , tplDischargePositionDetail.PDE_BALANCE_QUANTITY
                   , tplDischargePositionDetail.PDE_BALANCE_QUANTITY_PARENT
                   , tplDischargePositionDetail.PDE_BASIS_QUANTITY_SU
                   , tplDischargePositionDetail.PDE_INTERMEDIATE_QUANTITY_SU
                   , tplDischargePositionDetail.PDE_FINAL_QUANTITY_SU
                   , tplDischargePositionDetail.PDE_MOVEMENT_QUANTITY
                   , tplDischargePositionDetail.PDE_MOVEMENT_VALUE
                   , tplDischargePositionDetail.PDE_CHARACTERIZATION_VALUE_1
                   , tplDischargePositionDetail.PDE_CHARACTERIZATION_VALUE_2
                   , tplDischargePositionDetail.PDE_CHARACTERIZATION_VALUE_3
                   , tplDischargePositionDetail.PDE_CHARACTERIZATION_VALUE_4
                   , tplDischargePositionDetail.PDE_CHARACTERIZATION_VALUE_5
                   , tplDischargePositionDetail.PDE_DELAY_UPDATE_TEXT
                   , tplDischargePositionDetail.PDE_DECIMAL_1
                   , tplDischargePositionDetail.PDE_DECIMAL_2
                   , tplDischargePositionDetail.PDE_DECIMAL_3
                   , tplDischargePositionDetail.PDE_TEXT_1
                   , tplDischargePositionDetail.PDE_TEXT_2
                   , tplDischargePositionDetail.PDE_TEXT_3
                   , tplDischargePositionDetail.PDE_DATE_1
                   , tplDischargePositionDetail.PDE_DATE_2
                   , tplDischargePositionDetail.PDE_DATE_3
                   , tplDischargePositionDetail.PDE_GENERATE_MOVEMENT
                   , decode(aDischargeQuantity
                          , null, tplDischargePositionDetail.DCD_QUANTITY
                          , least(aDischargeQuantity, tplDischargePositionDetail.DCD_QUANTITY)
                           )
                   , decode(aDischargeQuantity
                          , null, tplDischargePositionDetail.DCD_QUANTITY_SU
                          , least(aDischargeQuantity, tplDischargePositionDetail.DCD_QUANTITY_SU)
                           )
                   , tplDischargePositionDetail.DCD_BALANCE_FLAG
                   , tplDischargePositionDetail.POS_CONVERT_FACTOR
                   , tplDischargePositionDetail.POS_CONVERT_FACTOR
                   , tplDischargePositionDetail.POS_GROSS_UNIT_VALUE
                   , tplDischargePositionDetail.POS_GROSS_UNIT_VALUE_INCL
                   , tplDischargePositionDetail.DIC_UNIT_OF_MEASURE_ID
                   , tplDischargePositionDetail.DCD_DEPLOYED_COMPONENTS
                   , 0   -- DCD_VISIBLE
                   , '390'   -- aCreateMode (décharge échéancier)
                   , decode(aDischargeAmount, null, 0, 1)   -- DCD_FORCE_AMOUNT
                   , aDischargeAmount   -- POS_NET_VALUE_EXCL
                   , tplDischargePositionDetail.NEW_A_DATECRE
                   , tplDischargePositionDetail.NEW_A_IDCRE
                   , tplDischargePositionDetail.PDE_ST_PT_REJECT
                   , tplDischargePositionDetail.PDE_ST_CPT_REJECT
                    );

        -- si on a une quantité précisée, on la décrémente de la qté déchargée
        if aDischargeQuantity is not null then
          aDischargeQuantity  := aDischargeQuantity - least(aDischargeQuantity, tplDischargePositionDetail.DCD_QUANTITY);
        end if;

        vSourcePositionId  := tplDischargePositionDetail.DOC_POSITION_ID;
        vPTPositionID      := tplDischargePositionDetail.DOC_POSITION_ID;
        vStrTypePos        := tplDischargePositionDetail.C_GAUGE_TYPE_POS;

        /* Traitment des pos cpt si il s'agit d0un posiiton kit ou assemblage */
        if (vStrTypePos in('7', '8', '9', '10') ) then
          vGreatestSumQuantityCPT     := 0;
          vGreatestSumQuantityCPT_SU  := 0;

          for tplDischargePositionDetailCPT in crDischargePositionDetailCPT(ANewDocumentID
                                                                          , vPTPositionID
                                                                          , tplDischargePositionDetail.NEW_GAUGE_ID
                                                                          , tplDischargePositionDetail.NEW_THIRD_ID
                                                                          , aDischargeQuantity
                                                                           ) loop
            vQuantityCPT     := tplDischargePositionDetailCPT.DCD_QUANTITY;
            vQuantityCPT_SU  := tplDischargePositionDetailCPT.DCD_QUANTITY_SU;

            /* Stock la plus grande quantité des composants après application du
               coefficient d'utilisation */
            if (nvl(tplDischargePositionDetailCPT.POS_UTIL_COEFF, 0) = 0) then
              vGreatestSumQuantityCPT     := greatest(vGreatestSumQuantityCPT, 0);
              vGreatestSumQuantityCPT_SU  := greatest(vGreatestSumQuantityCPT_SU, 0);
            else
              vGreatestSumQuantityCPT     := greatest(vGreatestSumQuantityCPT, vQuantityCPT / tplDischargePositionDetailCPT.POS_UTIL_COEFF);
              vGreatestSumQuantityCPT_SU  := greatest(vGreatestSumQuantityCPT_SU, vQuantityCPT_SU / tplDischargePositionDetailCPT.POS_UTIL_COEFF);
            end if;

            insert into V_DOC_POS_DET_COPY_DISCHARGE
                        (DOC_POSITION_DETAIL_ID
                       , NEW_DOCUMENT_ID
                       , CRG_SELECT
                       , DOC_GAUGE_FLOW_ID
                       , DOC_POSITION_ID
                       , DOC_DOC_POSITION_ID
                       , DOC_DOC_POSITION_DETAIL_ID
                       , DOC2_DOC_POSITION_DETAIL_ID
                       , DOC_INVOICE_EXPIRY_ID
                       , GCO_GOOD_ID
                       , STM_LOCATION_ID
                       , GCO_CHARACTERIZATION_ID
                       , GCO_GCO_CHARACTERIZATION_ID
                       , GCO2_GCO_CHARACTERIZATION_ID
                       , GCO3_GCO_CHARACTERIZATION_ID
                       , GCO4_GCO_CHARACTERIZATION_ID
                       , STM_STM_LOCATION_ID
                       , DIC_PDE_FREE_TABLE_1_ID
                       , DIC_PDE_FREE_TABLE_2_ID
                       , DIC_PDE_FREE_TABLE_3_ID
                       , FAL_SCHEDULE_STEP_ID
                       , DOC_RECORD_ID
                       , DOC_DOCUMENT_ID
                       , PAC_THIRD_ID
                       , DOC_GAUGE_ID
                       , DOC_GAUGE_RECEIPT_ID
                       , DOC_GAUGE_COPY_ID
                       , C_GAUGE_TYPE_POS
                       , DIC_DELAY_UPDATE_TYPE_ID
                       , PDE_BASIS_DELAY
                       , PDE_INTERMEDIATE_DELAY
                       , PDE_FINAL_DELAY
                       , PDE_SQM_ACCEPTED_DELAY
                       , PDE_BASIS_QUANTITY
                       , PDE_INTERMEDIATE_QUANTITY
                       , PDE_FINAL_QUANTITY
                       , PDE_BALANCE_QUANTITY
                       , PDE_BALANCE_QUANTITY_PARENT
                       , PDE_BASIS_QUANTITY_SU
                       , PDE_INTERMEDIATE_QUANTITY_SU
                       , PDE_FINAL_QUANTITY_SU
                       , PDE_MOVEMENT_QUANTITY
                       , PDE_MOVEMENT_VALUE
                       , PDE_CHARACTERIZATION_VALUE_1
                       , PDE_CHARACTERIZATION_VALUE_2
                       , PDE_CHARACTERIZATION_VALUE_3
                       , PDE_CHARACTERIZATION_VALUE_4
                       , PDE_CHARACTERIZATION_VALUE_5
                       , PDE_DELAY_UPDATE_TEXT
                       , PDE_DECIMAL_1
                       , PDE_DECIMAL_2
                       , PDE_DECIMAL_3
                       , PDE_TEXT_1
                       , PDE_TEXT_2
                       , PDE_TEXT_3
                       , PDE_DATE_1
                       , PDE_DATE_2
                       , PDE_DATE_3
                       , PDE_GENERATE_MOVEMENT
                       , DCD_QUANTITY
                       , DCD_QUANTITY_SU
                       , DCD_BALANCE_FLAG
                       , POS_CONVERT_FACTOR
                       , POS_CONVERT_FACTOR_CALC
                       , POS_GROSS_UNIT_VALUE
                       , POS_GROSS_UNIT_VALUE_INCL
                       , POS_UNIT_OF_MEASURE_ID
                       , POS_UTIL_COEFF
                       , DCD_VISIBLE
                       , C_PDE_CREATE_MODE
                       , A_DATECRE
                       , A_IDCRE
                       , PDE_ST_PT_REJECT
                       , PDE_ST_CPT_REJECT
                        )
                 values (tplDischargePositionDetailCPT.DOC_POSITION_DETAIL_ID
                       , ANewDocumentID
                       , tplDischargePositionDetailCPT.CRG_SELECT
                       , aGaugeFlowId
                       , tplDischargePositionDetailCPT.DOC_POSITION_ID
                       , tplDischargePositionDetailCPT.DOC_DOC_POSITION_ID
                       , tplDischargePositionDetailCPT.DOC_DOC_POSITION_DETAIL_ID
                       , tplDischargePositionDetailCPT.DOC2_DOC_POSITION_DETAIL_ID
                       , aInvoiceExpiryId
                       , tplDischargePositionDetailCPT.GCO_GOOD_ID
                       , tplDischargePositionDetailCPT.STM_LOCATION_ID
                       , tplDischargePositionDetailCPT.GCO_CHARACTERIZATION_ID
                       , tplDischargePositionDetailCPT.GCO_GCO_CHARACTERIZATION_ID
                       , tplDischargePositionDetailCPT.GCO2_GCO_CHARACTERIZATION_ID
                       , tplDischargePositionDetailCPT.GCO3_GCO_CHARACTERIZATION_ID
                       , tplDischargePositionDetailCPT.GCO4_GCO_CHARACTERIZATION_ID
                       , tplDischargePositionDetailCPT.STM_STM_LOCATION_ID
                       , tplDischargePositionDetailCPT.DIC_PDE_FREE_TABLE_1_ID
                       , tplDischargePositionDetailCPT.DIC_PDE_FREE_TABLE_2_ID
                       , tplDischargePositionDetailCPT.DIC_PDE_FREE_TABLE_3_ID
                       , tplDischargePositionDetailCPT.FAL_SCHEDULE_STEP_ID
                       , tplDischargePositionDetailCPT.DOC_RECORD_ID
                       , tplDischargePositionDetailCPT.DOC_DOCUMENT_ID
                       , tplDischargePositionDetailCPT.PAC_THIRD_ID
                       , tplDischargePositionDetailCPT.DOC_GAUGE_ID
                       , tplDischargePositionDetailCPT.DOC_GAUGE_RECEIPT_ID
                       , tplDischargePositionDetailCPT.DOC_GAUGE_COPY_ID
                       , tplDischargePositionDetailCPT.C_GAUGE_TYPE_POS
                       , tplDischargePositionDetailCPT.DIC_DELAY_UPDATE_TYPE_ID
                       , tplDischargePositionDetailCPT.PDE_BASIS_DELAY
                       , tplDischargePositionDetailCPT.PDE_INTERMEDIATE_DELAY
                       , tplDischargePositionDetailCPT.PDE_FINAL_DELAY
                       , tplDischargePositionDetailCPT.PDE_SQM_ACCEPTED_DELAY
                       , tplDischargePositionDetailCPT.PDE_BASIS_QUANTITY
                       , tplDischargePositionDetailCPT.PDE_INTERMEDIATE_QUANTITY
                       , tplDischargePositionDetailCPT.PDE_FINAL_QUANTITY
                       , tplDischargePositionDetailCPT.PDE_BALANCE_QUANTITY
                       , tplDischargePositionDetailCPT.PDE_BALANCE_QUANTITY_PARENT
                       , tplDischargePositionDetailCPT.PDE_BASIS_QUANTITY_SU
                       , tplDischargePositionDetailCPT.PDE_INTERMEDIATE_QUANTITY_SU
                       , tplDischargePositionDetailCPT.PDE_FINAL_QUANTITY_SU
                       , tplDischargePositionDetailCPT.PDE_MOVEMENT_QUANTITY
                       , tplDischargePositionDetailCPT.PDE_MOVEMENT_VALUE
                       , tplDischargePositionDetailCPT.PDE_CHARACTERIZATION_VALUE_1
                       , tplDischargePositionDetailCPT.PDE_CHARACTERIZATION_VALUE_2
                       , tplDischargePositionDetailCPT.PDE_CHARACTERIZATION_VALUE_3
                       , tplDischargePositionDetailCPT.PDE_CHARACTERIZATION_VALUE_4
                       , tplDischargePositionDetailCPT.PDE_CHARACTERIZATION_VALUE_5
                       , tplDischargePositionDetailCPT.PDE_DELAY_UPDATE_TEXT
                       , tplDischargePositionDetailCPT.PDE_DECIMAL_1
                       , tplDischargePositionDetailCPT.PDE_DECIMAL_2
                       , tplDischargePositionDetailCPT.PDE_DECIMAL_3
                       , tplDischargePositionDetailCPT.PDE_TEXT_1
                       , tplDischargePositionDetailCPT.PDE_TEXT_2
                       , tplDischargePositionDetailCPT.PDE_TEXT_3
                       , tplDischargePositionDetailCPT.PDE_DATE_1
                       , tplDischargePositionDetailCPT.PDE_DATE_2
                       , tplDischargePositionDetailCPT.PDE_DATE_3
                       , tplDischargePositionDetailCPT.PDE_GENERATE_MOVEMENT
                       , vQuantityCPT
                       , vQuantityCPT_SU
                       , tplDischargePositionDetailCPT.DCD_BALANCE_FLAG
                       , tplDischargePositionDetailCPT.POS_CONVERT_FACTOR
                       , tplDischargePositionDetailCPT.POS_CONVERT_FACTOR
                       , tplDischargePositionDetailCPT.POS_GROSS_UNIT_VALUE
                       , tplDischargePositionDetailCPT.POS_GROSS_UNIT_VALUE_INCL
                       , tplDischargePositionDetailCPT.DIC_UNIT_OF_MEASURE_ID
                       , tplDischargePositionDetailCPT.POS_UTIL_COEFF
                       , 0   -- DCD_VISIBLE
                       , '390'   -- aCreateMode (décharge échéancier)
                       , tplDischargePositionDetailCPT.NEW_A_DATECRE
                       , tplDischargePositionDetailCPT.NEW_A_IDCRE
                       , tplDischargePositionDetailCPT.PDE_ST_PT_REJECT
                       , tplDischargePositionDetailCPT.PDE_ST_CPT_REJECT
                        );
          end loop;

          /**
          * Redéfinit la quantité du produit terminé en fonction de la quantité
          * des composants.
          *
          *   Selon la règle suivante (facture des livraisons CPT) :
          *
          *   Si toutes les quantités des composants sont à 0 alors on initialise
          *   la quantité du produit terminé avec 0, sinon on conserve la quantité
          *   initiale (quantité solde).
          */
          if (vGreatestSumQuantityCPT = 0) then
            update DOC_POS_DET_COPY_DISCHARGE
               set DCD_QUANTITY = 0
                 , DCD_QUANTITY_SU = 0
             where DOC_POS_DET_COPY_DISCHARGE_ID = vNewID;
          end if;
        end if;
      end loop;

      -- si pas d'erreur précédement
      if aErrorCode is null then
        DOC_COPY_DISCHARGE.SetLastDocPosNumber(aNewDocumentId);
        -- décharge des documents
        DOC_COPY_DISCHARGE.DischargePosition(vSourcePositionId, aNewDocumentID, null, null, aGaugeFlowId, vInputData, vTargetPositionId, vDischargeInfoCode);
      end if;

      -- suppression de la position à décharger
      delete from DOC_POS_DET_COPY_DISCHARGE
            where NEW_DOCUMENT_ID = aNewDocumentID;
    end if;
  end dischargeDetail;

  /**
  * procedure DischargeDetailCascade
  * Description
  *    méthode de décharge récursive de position
  * @created fp 11.09.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param aSourcePositionId : id de la position source à décharger en facture finale
  * @param aInvoiceExpiryId : id de l'échéancier
  * @param aTargetDocumentId : id du document final
  * @param aDischargeAmount : forcer le monant de décharge
  * @param aDischargeQuantity : quantité à décharger (en cas de décharge partielles ou supérieures à la quantité d'origine)
  * @param out aErrorCode : code d'erreur si problème
  */
  procedure dischargeDetailCascade(
    aSourceDetailId    in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aInvoiceExpiryId   in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aTargetDocumentId  in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDischargeAmount   in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type default null
  , aDischargeQuantity in out DOC_INVOICE_EXPIRY_DETAIL.IED_DISCHARGE_QUANTITY%type
  , aErrorCode         out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
  is
    cursor crDetail2Discharge(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE_BALANCE_QUANTITY
           , PDE_FINAL_QUANTITY
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = aCrDetailId;

    cursor crDischargedDetails(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select DOC_POSITION_DETAIL_ID
        from DOC_POSITION_DETAIL
       where DOC_DOC_POSITION_DETAIL_ID = aCrDetailId;

    vGaugeFlowId DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    for tplDetail2Discharge in crDetail2Discharge(aSourceDetailId) loop
      -- recherche si le détail courant a déjà été déchargé et, si oui, décharge des fils
      if tplDetail2Discharge.PDE_BALANCE_QUANTITY < tplDetail2Discharge.PDE_FINAL_QUANTITY then
        for tplDischargedDetails in crDischargedDetails(aSourceDetailId) loop
          -- appel de la procédure en cascade
          dischargeDetailCascade(tplDischargedDetails.DOC_POSITION_DETAIL_ID
                               , aInvoiceExpiryId
                               , aTargetDocumentId
                               , aDischargeAmount
                               , aDischargeQuantity
                               , aErrorCode
                                );
          -- sortie de la sous-boucle en cas d'erreur
          exit when aErrorCode is not null;
        end loop;
      end if;

      -- sortie de la boucle en cas d'erreur
      exit when aErrorCode is not null;

      -- décharge du détail courant si il reste un solde sur le détail
      if tplDetail2Discharge.PDE_BALANCE_QUANTITY > 0 then
--********************************Extraire dans doc_lib_gauge ******************************************
        -- recherche du flux par défaut
        select DOC_I_LIB_GAUGE.GetFlowID(GAU.C_ADMIN_DOMAIN, DMT.PAC_THIRD_ID)
          into vGaugeFlowId
          from DOC_POSITION_DETAIL PDE
             , DOC_DOCUMENT DMT
             , DOC_GAUGE GAU
         where PDE.DOC_POSITION_DETAIL_ID = aSourceDetailId
           and DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
           and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;

        -- décharge du détail courant
        dischargeDetail(aTargetDocumentId, aInvoiceExpiryId, aSourceDetailId, vGaugeFlowId, aDischargeAmount, aDischargeQuantity, aErrorCode);
      end if;
    end loop;
  end dischargeDetailCascade;

  /**
  * procedure dischargeDocumentCascade
  * Description
  *    décharge de toutes les positions du document, en cascade
  * @created fp 11.09.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param aSourceDocumentId : id du document source à décharger en facture finale
  * @param aTargetDocumentId : id du document final
  * @param aInvoiceExpiryId : id de l'échéancier
  * @param out aErrorCode : code d'erreur si problème
  */
  procedure dischargeDocumentCascade(
    aSourceDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aTargetDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  )
  is
    cursor crPositions2Discharge(aCrDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   PDE.DOC_POSITION_DETAIL_ID
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
         where POS.DOC_DOCUMENT_ID = aCrDocumentId
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and POS.C_GAUGE_TYPE_POS in('1', '3', '5', '7', '8', '91', '10')
           and POS.C_DOC_POS_STATUS <> '05'
      order by POS.POS_NUMBER
             , PDE.DOC_POSITION_DETAIL_ID;

    vErrorCode         DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type;
    vDischargeQuantity number;
  begin
    for tplPosition2Discharge in crPositions2discharge(aSourceDocumentId) loop
      dischargeDetailCascade(aSourceDetailId      => tplPosition2Discharge.DOC_POSITION_DETAIL_ID
                           , aTargetDocumentId    => aTargetDocumentId
                           , aInvoiceExpiryId     => aInvoiceExpiryId
                           , aDischargeQuantity   => vDischargeQuantity
                           , aErrorCode           => vErrorCode
                            );
    end loop;
  end dischargeDocumentCascade;

  /**
  * function getDepositRecoverAmount
  * Description
  *    retourne la somme des montants de reprise d'acompte pour un document
  * @created fp 08.04.2008
  * @lastUpdate
  * @private
  * @param aDocumentId : id du document
  * @return voir description
  */
  function getDepositRecoverAmount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_POSITION.POS_NET_VALUE_EXCL%type
  is
    vResult DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
  begin
    -- Il faut qu'on ait qu'un detail par position,
    -- ce qui est le cas des positions acompte de l'échéancier
    select nvl(sum(POS.POS_NET_VALUE_EXCL), 0)
      into vResult
      from DOC_POSITION POS
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION_DETAIL PDE2
         , DOC_POSITION POS2
         , DOC_INVOICE_EXPIRY INX2
     where POS.DOC_DOCUMENT_ID = aDocumentId
       and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and PDE2.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
       and POS2.DOC_POSITION_ID = PDE2.DOC_POSITION_ID
       and INX2.DOC_INVOICE_EXPIRY_ID = POS2.DOC_INVOICE_EXPIRY_ID
       and INX2.C_INVOICE_EXPIRY_DOC_TYPE = '1';

    return vResult;
  end getDepositRecoverAmount;

  /**
  * Description
  *    retourne la somme des montants des positions créées par décharge
  */
  function getDepositAmountDischarged(aPositionId DOC_POSITION.DOC_POSITION_ID%type, aSimulation in number default 0)
    return DOC_POSITION.POS_NET_VALUE_EXCL%type
  is
    vResult DOC_POSITION.POS_NET_VALUE_EXCL%type;
  begin
    if aSimulation = 0 then
      -- Il faut qu'on ait qu'un detail par position,
      -- ce qui est le cas des positions acompte de l'échéancier
      select nvl(sum(POS_NET_VALUE_EXCL), 0)
        into vResult
        from DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
           , DOC_POSITION_DETAIL PDE_FATHER
       where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and PDE.DOC_DOC_POSITION_DETAIL_ID = PDE_FATHER.DOC_POSITION_DETAIL_ID
         and PDE_FATHER.DOC_POSITION_ID = aPositionId;
    else
      select nvl(sum(POS_NET_VALUE_EXCL), 0)
        into vResult
        from DOC_ESTIMATED_POS_CASH_FLOW POS
       where POS.DOC_DOC_POSITION_ID = aPositionId;
    end if;

    return vResult;
  end getDepositAmountDischarged;

  /**
  * Description
  *    retourne le solde d'accompte disponible
  */
  function getBalanceDepositAmount(
    aInvoiceExpiryDetailId DOC_INVOICE_EXPIRY_DETAIL.DOC_INVOICE_EXPIRY_DETAIL_ID%type
  , aPositionId            DOC_POSITION.DOC_POSITION_ID%type
  )
    return DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type
  is
    vLinkedAmount DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type;
    vGlobalAmount DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type   := 0;
  begin
    -- retourne le solde d'accompte pour les accomptes liées
    select nvl(sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '1', nvl(IED_NET_VALUE_EXCL, 0), '5', nvl(-IED_NET_VALUE_EXCL, 0), 0) ), 0) -
           nvl(sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '2', nvl(IED_RET_DEPOSIT_NET_EXCL, 0), 0) ), 0)
      into vLinkedAmount
      from DOC_INVOICE_EXPIRY INX
         , DOC_INVOICE_EXPIRY_DETAIL IED
     where IED.DOC_POSITION_ID = aPositionId
       and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
       and not IED.DOC_INVOICE_EXPIRY_DETAIL_ID = aInvoiceExpiryDetailId
       and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '2', '5');

    return greatest(vLinkedAmount + vGlobalAmount, 0);
  end getBalanceDepositAmount;

  /**
  * Description
  *    retourne le solde d'accompte disponible
  */
  function getPosTotalDepositAmount(aPositionId DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type
  is
    vResult DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type;
  begin
    select sum(IED_NET_VALUE_EXCL)
      into vResult
      from DOC_INVOICE_EXPIRY INX
         , DOC_INVOICE_EXPIRY_DETAIL IED
     where IED.DOC_POSITION_ID = aPositionId
       and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
       and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1');

    return vResult;
  end getPosTotalDepositAmount;

  /**
  * procedure dischargeGlobalDepositPos
  * Description
  *    Génération des positions négatives de reprise d'acomptes (et aussi NC sur accompte)
  * @created fp 17.10.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param  aNewDocumentId : id du document facture finale
  * @param  aSourceDocumentId : id du document d'origine de l'échéancier
  * @param  aLinkedPositionId : id de la position liée (uniquement en cas d'échéancier liés aux positions)
  * @param  aDischargeAmount : montant à décharger (ne renseigner que pour des décharge partielles,
  *                            sinon c'est le solde qui est déchargé)
  */
  function dischargeGlobalDepositPos(
    aNewDocumentId    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId  in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aSourceDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aLinkedPositionId in     DOC_POSITION.DOC_POSITION_ID%type
  , aDischargeAmount  in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type default null
  , aSimulation       in     number default 0
  , aErrorCode        out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
    return DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
  is
    cursor crDepositPositions(
      aCrDocumentId       in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aCrLinkedPositionId in DOC_POSITION.DOC_POSITION_ID%type
    , aCrDischargeAmount     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
    )
    is
      select   PDE.DOC_POSITION_DETAIL_ID
             , PDE.DOC_POSITION_ID
             , POS_NET_VALUE_EXCL + getDepositAmountDischarged(PDE.DOC_POSITION_ID) BALANCE_AMOUNT
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_FINAL_QUANTITY
             , POS.POS_NET_VALUE_EXCL
             , INX.C_INVOICE_EXPIRY_DOC_TYPE
             , DMT.DMT_NUMBER
             , DMT.PC_LANG_ID
             , SRC_DMT.DMT_ONLY_AMOUNT_BILL_BOOK
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , DOC_INVOICE_EXPIRY INX
             , DOC_DOCUMENT DMT
             , DOC_DOCUMENT SRC_DMT
         where POS.DOC_INVOICE_EXPIRY_ID in(
                 select DOC_INVOICE_EXPIRY_ID
                   from DOC_INVOICE_EXPIRY
                  where DOC_DOCUMENT_ID = aCrDocumentId
                    and (    (    aCrDischargeAmount is null
                              and C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5') )
                         or C_INVOICE_EXPIRY_DOC_TYPE = '1') )
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and INX.DOC_INVOICE_EXPIRY_ID = POS.DOC_INVOICE_EXPIRY_ID
           and PDE_BALANCE_QUANTITY > 0
           and (   POS.DOC_INVOICE_EXPIRY_DETAIL_ID is null
                or aCrLinkedPositionId is null)
           and POS.C_DOC_POS_STATUS in('02', '03')
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SRC_DMT.DOC_DOCUMENT_ID = aCrDocumentId
      order by INX.C_INVOICE_EXPIRY_DOC_TYPE
             , INX.INX_SLICE
             , POS.POS_NUMBER;

    cursor crSimDepositPositions(
      aCrDocumentId       in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aCrLinkedPositionId in DOC_POSITION.DOC_POSITION_ID%type
    , aCrDischargeAmount     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
    )
    is
      select   POS.DOC_POSITION_ID
             , INX.DOC_INVOICE_EXPIRY_ID
             , POS_NET_VALUE_EXCL + getDepositAmountDischarged(POS.DOC_POSITION_ID, aSimulation) BALANCE_AMOUNT
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_FINAL_QUANTITY
             , POS.POS_NET_VALUE_EXCL
             , INX.C_INVOICE_EXPIRY_DOC_TYPE
             , SRC_DMT.DMT_ONLY_AMOUNT_BILL_BOOK
             , INX.INX_SLICE
             , POS.POS_NUMBER
          from DOC_ESTIMATED_POS_CASH_FLOW POS
             , DOC_INVOICE_EXPIRY INX
             , DOC_DOCUMENT SRC_DMT
         where POS.DOC_INVOICE_EXPIRY_ID in(
                 select DOC_INVOICE_EXPIRY_ID
                   from DOC_INVOICE_EXPIRY
                  where DOC_DOCUMENT_ID = aCrDocumentId
                    and (    (    aCrDischargeAmount is null
                              and C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5') )
                         or C_INVOICE_EXPIRY_DOC_TYPE = '1') )
           and INX.DOC_INVOICE_EXPIRY_ID = POS.DOC_INVOICE_EXPIRY_ID
           and POS_NET_VALUE_EXCL + getDepositAmountDischarged(POS.DOC_POSITION_ID, aSimulation) > 0
           and (   POS.DOC_INVOICE_EXPIRY_DETAIL_ID is null
                or aCrLinkedPositionId is null)
           and SRC_DMT.DOC_DOCUMENT_ID = aCrDocumentId
      union all
      select   PDE.DOC_POSITION_ID
             , INX.DOC_INVOICE_EXPIRY_ID
             , POS_NET_VALUE_EXCL + getDepositAmountDischarged(PDE.DOC_POSITION_ID) + getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) BALANCE_AMOUNT
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_FINAL_QUANTITY
             , POS.POS_NET_VALUE_EXCL
             , C_INVOICE_EXPIRY_DOC_TYPE
             , SRC_DMT.DMT_ONLY_AMOUNT_BILL_BOOK
             , INX.INX_SLICE
             , POS.POS_NUMBER
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , DOC_INVOICE_EXPIRY INX
             , DOC_DOCUMENT DMT
             , DOC_DOCUMENT SRC_DMT
         where POS.DOC_INVOICE_EXPIRY_ID in(
                 select DOC_INVOICE_EXPIRY_ID
                   from DOC_INVOICE_EXPIRY
                  where DOC_DOCUMENT_ID = aCrDocumentId
                    and (    (    aCrDischargeAmount is null
                              and C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5') )
                         or C_INVOICE_EXPIRY_DOC_TYPE = '1') )
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and INX.DOC_INVOICE_EXPIRY_ID = POS.DOC_INVOICE_EXPIRY_ID
           and POS_NET_VALUE_EXCL + getDepositAmountDischarged(POS.DOC_POSITION_ID) + getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) > 0
           and (   POS.DOC_INVOICE_EXPIRY_DETAIL_ID is null
                or aCrLinkedPositionId is null)
           and POS.C_DOC_POS_STATUS in('01', '02', '03')
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SRC_DMT.DOC_DOCUMENT_ID = aCrDocumentId
      order by C_INVOICE_EXPIRY_DOC_TYPE
             , INX_SLICE
             , POS_NUMBER;

    vBalanceDischargeAmount DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vDischargeQuantity      number;
  begin
    -- initilaisation du solde à décharger
    vBalanceDischargeAmount  := aDischargeAmount;

    if aSimulation = 0 then
      -- pour chaque détail de position déchargeable (1 position = 1 detail)
      for tplDepositPosition in crDepositPositions(aSourceDocumentId, aLinkedPositionId, aDischargeAmount) loop
        -- décharge complète de positions non-déchargées partiellement (facture finale)
        if     aDischargeAmount is null
           and tplDepositPosition.POS_BALANCE_QUANTITY = tplDepositPosition.POS_FINAL_QUANTITY then
          dischargeDetailCascade(aSourceDetailId      => tplDepositPosition.DOC_POSITION_DETAIL_ID
                               , aInvoiceExpiryId     => aInvoiceExpiryId
                               , aTargetDocumentId    => aNewDocumentId
                               , aDischargeQuantity   => vDischargeQuantity
                               , aErrorCode           => aErrorCode
                                );
        -- décharge complète de positions déchargées partiellement (facture finale)
        -- décharger le solde du montant
        elsif aDischargeAmount is null then
          dischargeDetailCascade(aSourceDetailId      => tplDepositPosition.DOC_POSITION_DETAIL_ID
                               , aInvoiceExpiryId     => aInvoiceExpiryId
                               , aTargetDocumentId    => aNewDocumentId
                               , aDischargeAmount     => tplDepositPosition.POS_NET_VALUE_EXCL + getDepositAmountDischarged(tplDepositPosition.DOC_POSITION_ID)
                               , aDischargeQuantity   => vDischargeQuantity
                               , aErrorCode           => aErrorCode
                                );
        -- décharge partielle (facture partielle)
        else
          -- si on veut décharger plus que l'accompte pointé par le curseur,
          -- on décharge tout l'accompte
          if vBalanceDischargeAmount >= tplDepositPosition.BALANCE_AMOUNT then
            dischargeDetailCascade(aSourceDetailId      => tplDepositPosition.DOC_POSITION_DETAIL_ID
                                 , aInvoiceExpiryId     => aInvoiceExpiryId
                                 , aTargetDocumentId    => aNewDocumentId
                                 , aDischargeAmount     => tplDepositPosition.BALANCE_AMOUNT
                                 , aDischargeQuantity   => vDischargeQuantity
                                 , aErrorCode           => aErrorCode
                                  );
            vBalanceDischargeAmount  := vBalanceDischargeAmount - tplDepositPosition.BALANCE_AMOUNT;
          -- si le montant de l'accompte pointé par le curseur est supérieur au solde à décharger
          -- alors on décharge le solde à décharger
          elsif vBalanceDischargeAmount <> 0 then
            dischargeDetailCascade(aSourceDetailId      => tplDepositPosition.DOC_POSITION_DETAIL_ID
                                 , aInvoiceExpiryId     => aInvoiceExpiryId
                                 , aTargetDocumentId    => aNewDocumentId
                                 , aDischargeQuantity   => vDischargeQuantity
                                 , aDischargeAmount     => vBalanceDischargeAmount
                                 , aErrorCode           => aErrorCode
                                  );
            vBalanceDischargeAmount  := 0;
          end if;
        end if;

        commit;   -- on conserve l'atomicité qu'on a dans le soft, c'est à dire qu'on Commit à chaque position
      end loop;
    -- Simulation
    else
      -- pour chaque détail de position déchargeable (1 position = 1 detail)
      for tplDepositPosition in crSimDepositPositions(aSourceDocumentId, aLinkedPositionId, aDischargeAmount) loop
        -- reprise d'accompte négative
        declare
          vDepositGoodId     GCO_GOOD.GCO_GOOD_ID%type;
          vGaugeId           DOC_GAUGE.DOC_GAUGE_ID%type;
          vDepositAmount     DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
          vDepositPositionId DOC_POSITION.DOC_POSITION_ID%type;
        begin
          Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
          Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO    := 0;
          Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID  := aInvoiceExpiryId;
          Doc_Position_Initialize.PositionInfo.DOC_DOC_POSITION_ID    := tplDepositPosition.DOC_POSITION_ID;
          Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE         := 1;
          Doc_Position_Initialize.PositionInfo.SIMULATION             := aSimulation;

          -- décharge complète de positions non-déchargées partiellement (facture finale)
          if     aDischargeAmount is null
             and tplDepositPosition.POS_BALANCE_QUANTITY = tplDepositPosition.POS_FINAL_QUANTITY then
            vDepositAmount  := -tplDepositPosition.POS_NET_VALUE_EXCL;
          -- décharge complète de positions déchargées partiellement (facture finale)
          -- décharger le solde du montant
          elsif aDischargeAmount is null then
            vDepositAmount  := -tplDepositPosition.BALANCE_AMOUNT;
          -- décharge partielle (facture partielle)
          else
            -- si on veut décharger plus que l'accompte pointé par le curseur,
            -- on décharge tout l'accompte
            if vBalanceDischargeAmount >= tplDepositPosition.BALANCE_AMOUNT then
              vDepositAmount           := tplDepositPosition.BALANCE_AMOUNT;
              vBalanceDischargeAmount  := vBalanceDischargeAmount - tplDepositPosition.BALANCE_AMOUNT;
            -- si le montant de l'accompte pointé par le curseur est supérieur au solde à décharger
            -- alors on décharge le solde à décharger
            elsif vBalanceDischargeAmount <> 0 then
              vDepositAmount           := vBalanceDischargeAmount;
              vBalanceDischargeAmount  := 0;
            end if;
          end if;

          select max(GCO_GOOD_ID)
            into vDepositGoodId
            from DOC_INVOICE_EXPIRY
           where DOC_DOCUMENT_ID = (select DOC_DOCUMENT_ID
                                      from DOC_INVOICE_EXPIRY
                                     where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId)
             and C_INVOICE_EXPIRY_DOC_TYPE = '1';

          select DOC_GAUGE_ID
            into vGaugeId
            from DOC_INVOICE_EXPIRY
           where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

          if vGaugeId is not null then
            Doc_Position_Generate.GeneratePosition(aPositionID       => vDepositPositionId
                                                 , aDocumentID       => aInvoiceExpiryId   -- -1
                                                 , aGaugeId          => vGaugeId
                                                 , aPosCreateMode    => '190'
                                                 , aTypePos          => '1'
                                                 , aGoodID           => vDepositGoodId
                                                 , aBasisQuantity    => -1
                                                 , aGoodPrice        => vDepositAmount
                                                 , aGenerateDetail   => 0
                                                 , aTargetTable      => 'DOC_ESTIMATED_POS_CASH_FLOW'
                                                  );
            ventilatePosAmountOnPos(aNewDocumentId, vDepositPositionId, tplDepositPosition.DOC_POSITION_ID, aSimulation);
          else
            aErrorCode  := '021';
          end if;

          exit when vBalanceDischargeAmount = 0;
        end;
      end loop;
    end if;

    -- retourne le montant déchargé
    return aDischargeAmount - vBalanceDischargeAmount;
  end dischargeGlobalDepositPos;

  /**
  * procedure dischargeLinkedDepositPos
  * Description
  *    Génération des positions négatives de reprise d'acomptes (et aussi NC sur accompte)
  * @created fp 17.10.2006
  * @lastUpdate fp 20.02.2007
  * @private
  * @param  aNewDocumentId : id du document facture finale
  * @param  aSourceDocumentId : id du document d'origine de l'échéancier
  * @param  aLinkedPositionId : id de la position liée (uniquement en cas d'échéancier liés aux positions)
  * @param  aDischargeAmount : montant à décharger (ne renseigner que pour des décharge partielles,
  *                            sinon c'est le solde qui est déchargé)
  * @return montant déchargé
  */
  function dischargeLinkedDepositPos(
    aNewDocumentId    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId  in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aSourceDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aLinkedPositionId in     DOC_POSITION.DOC_POSITION_ID%type
  , aDischargeAmount  in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type default null
  , aSimulation       in     number default 0
  , aErrorCode        out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
    return DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
  is
    cursor crDepositPositions(
      aCrDocumentId       in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aCrLinkedPositionId in DOC_POSITION.DOC_POSITION_ID%type
    , aCrDischargeAmount     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
    )
    is
      select   PDE.DOC_POSITION_DETAIL_ID
             , PDE.DOC_POSITION_ID
             , POS.POS_NET_VALUE_EXCL + getDepositAmountDischarged(PDE.DOC_POSITION_ID) BALANCE_AMOUNT
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_FINAL_QUANTITY
             , POS.POS_NET_VALUE_EXCL
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , DOC_INVOICE_EXPIRY INX
             , DOC_INVOICE_EXPIRY_DETAIL IED
         where POS.DOC_INVOICE_EXPIRY_DETAIL_ID in(
                 select DOC_INVOICE_EXPIRY_DETAIL_ID
                   from DOC_INVOICE_EXPIRY INX
                      , DOC_INVOICE_EXPIRY_DETAIL IED
                  where INX.DOC_DOCUMENT_ID = aCrDocumentId
                    and IED.DOC_INVOICE_EXPIRY_ID = INX.DOC_INVOICE_EXPIRY_ID
                    and IED.DOC_POSITION_ID = aCrLinkedPositionId
                    and (    (    aCrDischargeAmount is null
                              and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5', '6') )
                         or INX.C_INVOICE_EXPIRY_DOC_TYPE = '1') )
           and IED.DOC_INVOICE_EXPIRY_DETAIL_ID = POS.DOC_INVOICE_EXPIRY_DETAIL_ID
           and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and PDE_BALANCE_QUANTITY > 0
           and POS.C_DOC_POS_STATUS in('02', '03')
      order by INX.C_INVOICE_EXPIRY_DOC_TYPE
             , INX.INX_SLICE
             , POS.POS_NUMBER;

    cursor crSimDepositPositions(
      aCrDocumentId       in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aCrLinkedPositionId in DOC_POSITION.DOC_POSITION_ID%type
    , aCrDischargeAmount     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
    )
    is
      select   POS.DOC_POSITION_ID
             , POS.POS_NET_VALUE_EXCL + getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) BALANCE_AMOUNT
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_FINAL_QUANTITY
             , POS.POS_NET_VALUE_EXCL
             , INX.C_INVOICE_EXPIRY_DOC_TYPE
             , INX.DOC_INVOICE_EXPIRY_ID
             , INX.INX_SLICE
             , POS.POS_NUMBER
          from DOC_ESTIMATED_POS_CASH_FLOW POS
             , DOC_INVOICE_EXPIRY INX
             , DOC_INVOICE_EXPIRY_DETAIL IED
         where POS.DOC_INVOICE_EXPIRY_DETAIL_ID in(
                 select DOC_INVOICE_EXPIRY_DETAIL_ID
                   from DOC_INVOICE_EXPIRY INX
                      , DOC_INVOICE_EXPIRY_DETAIL IED
                  where INX.DOC_DOCUMENT_ID = aCrDocumentId
                    and IED.DOC_INVOICE_EXPIRY_ID = INX.DOC_INVOICE_EXPIRY_ID
                    and IED.DOC_POSITION_ID = nvl(aCrLinkedPositionId, IED.DOC_POSITION_ID)
                    and (    (    aCrDischargeAmount is null
                              and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5', '6') )
                         or INX.C_INVOICE_EXPIRY_DOC_TYPE = '1') )
           and IED.DOC_INVOICE_EXPIRY_DETAIL_ID = POS.DOC_INVOICE_EXPIRY_DETAIL_ID
           and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
           and POS.POS_NET_VALUE_EXCL + getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) > 0
      union all
      select   PDE.DOC_POSITION_ID
             , POS.POS_NET_VALUE_EXCL + getDepositAmountDischarged(PDE.DOC_POSITION_ID) + getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) BALANCE_AMOUNT
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_FINAL_QUANTITY
             , POS.POS_NET_VALUE_EXCL
             , INX.C_INVOICE_EXPIRY_DOC_TYPE
             , INX.DOC_INVOICE_EXPIRY_ID
             , INX.INX_SLICE
             , POS.POS_NUMBER
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , DOC_INVOICE_EXPIRY INX
             , DOC_INVOICE_EXPIRY_DETAIL IED
         where POS.DOC_INVOICE_EXPIRY_DETAIL_ID in(
                 select DOC_INVOICE_EXPIRY_DETAIL_ID
                   from DOC_INVOICE_EXPIRY INX
                      , DOC_INVOICE_EXPIRY_DETAIL IED
                  where INX.DOC_DOCUMENT_ID = aCrDocumentId
                    and IED.DOC_INVOICE_EXPIRY_ID = INX.DOC_INVOICE_EXPIRY_ID
                    and IED.DOC_POSITION_ID = nvl(aCrLinkedPositionId, IED.DOC_POSITION_ID)
                    and (    (    aCrDischargeAmount is null
                              and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5', '6') )
                         or INX.C_INVOICE_EXPIRY_DOC_TYPE = '1') )
           and IED.DOC_INVOICE_EXPIRY_DETAIL_ID = POS.DOC_INVOICE_EXPIRY_DETAIL_ID
           and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and POS.POS_NET_VALUE_EXCL + getDepositAmountDischarged(PDE.DOC_POSITION_ID) + getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) > 0
           and POS.C_DOC_POS_STATUS in('01', '02', '03')
      order by C_INVOICE_EXPIRY_DOC_TYPE
             , INX_SLICE
             , POS_NUMBER;

    vBalanceDischargeAmount DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vDischargeAmount        DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vTest                   number;
    vDischargeQuantity      number;
  begin
    -- initilaisation du solde à décharger
    vBalanceDischargeAmount  := aDischargeAmount;

    if aSimulation = 0 then
      -- pour chaque détail de position déchargeable (1 position = 1 detail)
      for tplDepositPosition in crDepositPositions(aSourceDocumentId, aLinkedPositionId, aDischargeAmount) loop
        -- si on veut décharger plus que l'accompte pointé par le curseur,
        -- on décharge tout l'accompte
        if vBalanceDischargeAmount >= tplDepositPosition.BALANCE_AMOUNT then
          DischargeDetailCascade(aSourceDetailId      => tplDepositPosition.DOC_POSITION_DETAIL_ID
                               , aInvoiceExpiryId     => aInvoiceExpiryId
                               , aTargetDocumentId    => aNewDocumentId
                               , aDischargeAmount     => tplDepositPosition.BALANCE_AMOUNT
                               , aDischargeQuantity   => vDischargeQuantity
                               , aErrorCode           => aErrorCode
                                );
          vBalanceDischargeAmount  := vBalanceDischargeAmount - tplDepositPosition.BALANCE_AMOUNT;
        -- si le montant de l'accompte pointé par le curseur est supérieur au solde à décharger
        -- alors on décharge le solde à décharger
        elsif vBalanceDischargeAmount <> 0 then
          DischargeDetailCascade(aSourceDetailId      => tplDepositPosition.DOC_POSITION_DETAIL_ID
                               , aInvoiceExpiryId     => aInvoiceExpiryId
                               , aTargetDocumentId    => aNewDocumentId
                               , aDischargeAmount     => vBalanceDischargeAmount
                               , aDischargeQuantity   => vDischargeQuantity
                               , aErrorCode           => aErrorCode
                                );
          vBalanceDischargeAmount  := 0;
        end if;

        -- sortie en cas d'erreur
        exit when aErrorCode is not null;
        commit;   -- on conserve l'atomicité qu'on a dans le soft, c'est à dire qu'on Commit à chaque position
      end loop;
    else
      -- pour chaque détail de position déchargeable (1 position = 1 detail)
      for tplDepositPosition in crSimDepositPositions(aSourceDocumentId, aLinkedPositionId, aDischargeAmount) loop
        -- reprise d'accompte négative
        declare
          vDepositGoodId     GCO_GOOD.GCO_GOOD_ID%type;
          vGaugeId           DOC_GAUGE.DOC_GAUGE_ID%type;
          vDepositPositionId DOC_POSITION.DOC_POSITION_Id%type;
        begin
          Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
          Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO    := 0;
          Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID  := aInvoiceExpiryId;
          Doc_Position_Initialize.PositionInfo.DOC_DOC_POSITION_ID    := tplDepositPosition.DOC_POSITION_ID;
          Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE         := 1;
          Doc_Position_Initialize.PositionInfo.USE_POS_NET_TARIFF     := 1;
          Doc_Position_Initialize.PositionInfo.POS_NET_TARIFF         := 1;
          Doc_Position_Initialize.PositionInfo.SIMULATION             := aSimulation;

          -- si on veut décharger plus que l'accompte pointé par le curseur,
          -- on décharge tout l'accompte
          if nvl(vBalanceDischargeAmount, tplDepositPosition.BALANCE_AMOUNT) >= tplDepositPosition.BALANCE_AMOUNT then
            vDischargeAmount         := tplDepositPosition.BALANCE_AMOUNT;
            vBalanceDischargeAmount  := vBalanceDischargeAmount - tplDepositPosition.BALANCE_AMOUNT;
          -- si le montant de l'accompte pointé par le curseur est supérieur au solde à décharger
          -- alors on décharge le solde à décharger
          elsif vBalanceDischargeAmount <> 0 then
            vDischargeAmount         := vBalanceDischargeAmount;
            vBalanceDischargeAmount  := 0;
          else
            exit;
          end if;

          select distinct max(GCO_GOOD_ID)
                     into vDepositGoodId
                     from DOC_INVOICE_EXPIRY
                    where DOC_DOCUMENT_ID = (select DOC_DOCUMENT_Id
                                               from DOC_INVOICE_EXPIRY
                                              where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId)
                      and C_INVOICE_EXPIRY_DOC_TYPE = '1';

          select DOC_GAUGE_ID
            into vGaugeId
            from DOC_INVOICE_EXPIRY
           where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

          Doc_Position_Generate.GeneratePosition(aPositionID       => vDepositPositionId
                                               , aDocumentID       => aNewDocumentId   -- -1
                                               , aGaugeId          => vGaugeId
                                               , aPosCreateMode    => '190'
                                               , aTypePos          => '1'
                                               , aGoodID           => vDepositGoodId
                                               , aBasisQuantity    => -1
                                               , aGoodPrice        => vDischargeAmount
                                               , aGenerateDetail   => 0
                                               , aTargetTable      => 'DOC_ESTIMATED_POS_CASH_FLOW'
                                                );
          ventilatePosAmountOnPos(aNewDocumentId, vDepositPositionId, tplDepositPosition.DOC_POSITION_ID, aSimulation);
        end;
      end loop;
    end if;

    -- retourne le montant déchargé
    return nvl(aDischargeAmount - vBalanceDischargeAmount, 0);
  end dischargeLinkedDepositPos;

  /**
  * procedure dischargeDepositPos
  * Description
  *    Génération des positions négatives de la facture finale correspondant aux accomptes déjà versés (et NC d'accomptes)
  * @created fp 06.09.2006
  * @lastUpdate fp 10.10.2006
  * @private
  * @param  aNewDocumentId : id du document facture finale
  * @param  aSourceDocumentId : id du document d'origine de l'échéancier
  * @param  aLinkedPositionId : id de la position liée (uniquement en cas d'échéancier liés aux positions)
  * @param  aDischargeAmount : montant à décharger (ne renseigner que pour des décharge partielles,
  *                            sinon c'est le solde qui est déchargé)
  */
  procedure dischargeDepositPos(
    aNewDocumentId    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId  in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aSourceDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aLinkedPositionId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aDischargeAmount  in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type default null
  , aSimulation       in     number default 0
  , aErrorCode        out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
  is
    vDischargeDone         boolean                                      := false;
    vDischargedAmount      DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type   := 0;
    vDischargedAmountAdded DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type   := 0;
  begin
    -- si on a une position, on essaie d'abord de décharger un acompte lié à la position
    if    aLinkedPositionId is not null
       or aDischargeAmount is null then
      vDischargedAmount       :=
                   dischargeLinkedDepositPos(aNewDocumentId, aInvoiceExpiryId, aSourceDocumentId, aLinkedPositionId, aDischargeAmount, aSimulation, aErrorCode);
      vDischargeDone          :=(vDischargedAmount = aDischargeAmount);
      vDischargedAmountAdded  := vDischargedAmount;
    end if;

    -- si on a pas effectué de décharge liée à la position, on tente une décharge sur un accompte global
    if     (   not vDischargeDone
            or aDischargeAmount is null)
       and aErrorCode is null then
      vDischargedAmount       :=
        dischargeGlobalDepositPos(aNewDocumentId
                                , aInvoiceExpiryId
                                , aSourceDocumentId
                                , aLinkedPositionId
                                , aDischargeAmount - vDischargedAmount
                                , aSimulation
                                , aErrorCode
                                 );
      vDischargedAmountAdded  := vDischargedAmountAdded + vDischargedAmount;
    end if;

    if     aErrorCode is null
       and aDischargeAmount is not null
       and vDischargedAmountAdded < aDischargeAmount then
      aErrorCode  := '020';
    end if;
  end dischargeDepositPos;

  /**
  * procedure dischargeSimBalanceDeposit
  * Description
  *    Génération des positions négatives de la facture finale correspondant aux accomptes déjà versés (et NC d'accomptes)
  * @created fp 10.09.2008
  * @lastUpdate
  * @private
  * @param  aNewDocumentId : id du document facture finale
  * @param  aSourceDocumentId : id du document d'origine de l'échéancier
  */
  procedure dischargeSimBalanceDeposit(
    aNewDocumentId    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId  in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aSourceDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aErrorCode        out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
  is
    cursor crPosition2Discharge(aCrSrcDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   DOC_POSITION_ID
             , DOC_INVOICE_EXPIRY_DETAIL_ID
             , POS_NET_VALUE_EXCL +
               DOC_INVOICE_EXPIRY_FUNCTIONS.getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) +
               DOC_INVOICE_EXPIRY_FUNCTIONS.getDepositAmountDischarged(POS.DOC_POSITION_ID) POS_BALANCE_AMOUNT
          from DOC_POSITION POS
         where DOC_INVOICE_EXPIRY_ID in(select DOC_INVOICE_EXPIRY_ID
                                          from DOC_INVOICE_EXPIRY
                                         where DOC_DOCUMENT_ID = aCrSrcDocumentId
                                           and C_INVOICE_EXPIRY_DOC_TYPE = '1'
                                           and DOC_GAUGE_ID = POS.DOC_GAUGE_ID)
           and POS_NET_VALUE_EXCL +
               DOC_INVOICE_EXPIRY_FUNCTIONS.getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) +
               DOC_INVOICE_EXPIRY_FUNCTIONS.getDepositAmountDischarged(POS.DOC_POSITION_ID) > 0
      union all
      select   DOC_POSITION_ID
             , DOC_INVOICE_EXPIRY_DETAIL_ID
             , POS_NET_VALUE_EXCL + DOC_INVOICE_EXPIRY_FUNCTIONS.getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) POS_BALANCE_AMOUNT
          from DOC_ESTIMATED_POS_CASH_FLOW POS
         where DOC_INVOICE_EXPIRY_ID in(select DOC_INVOICE_EXPIRY_ID
                                          from DOC_INVOICE_EXPIRY
                                         where DOC_DOCUMENT_ID = aCrSrcDocumentId
                                           and C_INVOICE_EXPIRY_DOC_TYPE = '1'
                                           and DOC_GAUGE_ID = POS.DOC_GAUGE_ID)
           and POS_NET_VALUE_EXCL + DOC_INVOICE_EXPIRY_FUNCTIONS.getDepositAmountDischarged(POS.DOC_POSITION_ID, 1) > 0
      order by DOC_INVOICE_EXPIRY_DETAIL_ID nulls last
             , DOC_POSITION_ID;

    vDischargedAmount number;
  begin
    for tplPosition2Discharge in crPosition2Discharge(aSourceDocumentId) loop
      if tplPosition2Discharge.DOC_INVOICE_EXPIRY_DETAIL_ID is not null then
        declare
          vPositionId DOC_POSITION.DOC_POSITION_ID%type;
        begin
          select DOC_POSITION_ID
            into vPositionId
            from DOC_INVOICE_EXPIRY_DETAIL
           where DOC_INVOICE_EXPIRY_DETAIL_ID = tplPosition2Discharge.DOC_INVOICE_EXPIRY_DETAIL_ID;

          vDischargedAmount  :=
            dischargeLinkedDepositPos(aNewDocumentId, aInvoiceExpiryId, aSourceDocumentId, vPositionId, tplPosition2Discharge.POS_BALANCE_AMOUNT, 1, aErrorCode);
        end;
      else
        vDischargedAmount  :=
                  dischargeGlobalDepositPos(aNewDocumentId, aInvoiceExpiryId, aSourceDocumentId, null, tplPosition2Discharge.POS_BALANCE_AMOUNT, 1, aErrorCode);
      end if;
    end loop;
  end dischargeSimBalanceDeposit;

  /**
  * procedure unbalanceDetailCascade
  * Description
  *    méthode de "désoldage" récursive de déatil de position (échéancier "montant seulement")
  * @created fp 19.02.2007
  * @lastUpdate
  * @private
  * @param aSourcePositionId : id de la position source à décharger en facture finale
  */
  procedure unbalanceDetailCascade(aSourceDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
  is
    cursor crDetail2UnBalance(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE_BALANCE_QUANTITY
           , PDE_FINAL_QUANTITY
           , DOC_POSITION_ID
           , DOC_DOCUMENT_ID
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = aCrDetailId;

    cursor crBalancedDetails(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select DOC_POSITION_DETAIL_ID
           , PDE_FINAL_QUANTITY
        from DOC_POSITION_DETAIL
       where DOC_DOC_POSITION_DETAIL_ID = aCrDetailId
         and PDE_BALANCE_QUANTITY > 0;

    vGaugeFlowId   DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    vDischargedQty DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type   := 0;
  begin
    for tplDetail2UnBalance in crDetail2UnBalance(aSourceDetailId) loop
      -- "désoldage" des positions déchargées
      for tplBalancedDetails in crBalancedDetails(aSourceDetailId) loop
        -- appel de la procédure en cascade
        unbalanceDetailCascade(tplBalancedDetails.DOC_POSITION_DETAIL_ID);
        -- cumul de la quantité déchargée
        vDischargedQty  := vDischargedQty + tplBalancedDetails.PDE_FINAL_QUANTITY;
      end loop;

      -- sodle de la position courante si il reste un solde sur le détail
      update DOC_POSITION_DETAIL
         set PDE_BALANCE_QUANTITY = PDE_FINAL_QUANTITY - vDischargedQty
       where DOC_POSITION_DETAIL_ID = aSourceDetailId;

      -- maj de la position
      update DOC_POSITION
         set (POS_BALANCE_QUANTITY, C_DOC_POS_STATUS) =
               (select sum(PDE_BALANCE_QUANTITY)
                     , decode(sum(PDE_BALANCE_QUANTITY), 0, '04', POS_FINAL_QUANTITY, '02', '03')
                  from DOC_POSITION_DETAIL
                 where DOC_POSITION_ID = DOC_POSITION.DOC_POSITION_ID)
           , POS_BALANCED = 0
           , POS_DATE_BALANCED = null
       where DOC_POSITION_ID = tplDetail2UnBalance.DOC_POSITION_ID;

      -- maj status document
      DOC_PRC_DOCUMENT.UpdateDocumentStatus(tplDetail2UnBalance.DOC_DOCUMENT_ID);
    end loop;
  end unbalanceDetailCascade;

  /**
  * procedure balanceDetailCascade
  * Description
  *    méthode de solde récursive de position (échéancier "montant seulement")
  * @created fp 10.10.2006
  * @lastUpdate
  * @private
  * @param aSourcePositionId : id de la position source à décharger en facture finale
  */
  procedure balanceDetailCascade(aSourceDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, aBalanceDate in date default sysdate)
  is
    cursor crDetail2Balance(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE_BALANCE_QUANTITY
           , PDE_FINAL_QUANTITY
           , DOC_POSITION_ID
           , DOC_DOCUMENT_ID
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = aCrDetailId;

    cursor crBalancedDetails(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select DOC_POSITION_DETAIL_ID
        from DOC_POSITION_DETAIL
       where DOC_DOC_POSITION_DETAIL_ID = aCrDetailId
         and PDE_BALANCE_QUANTITY > 0;

    vGaugeFlowId DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    for tplDetail2Balance in crDetail2Balance(aSourceDetailId) loop
      -- recherche si le détail courant a déjà été déchargé et, si oui, décharge des fils
      if    (    sign(tplDetail2Balance.PDE_FINAL_QUANTITY) = 1
             and tplDetail2Balance.PDE_BALANCE_QUANTITY < tplDetail2Balance.PDE_FINAL_QUANTITY)
         or (    sign(tplDetail2Balance.PDE_FINAL_QUANTITY) = -1
             and tplDetail2Balance.PDE_BALANCE_QUANTITY > tplDetail2Balance.PDE_FINAL_QUANTITY) then
        for tplBalancedDetails in crBalancedDetails(aSourceDetailId) loop
          -- appel de la procédure en cascade
          balanceDetailCascade(tplBalancedDetails.DOC_POSITION_DETAIL_ID, aBalanceDate);
        end loop;
      end if;

      -- sodle de la position courante si il reste un solde sur le détail
      if     tplDetail2Balance.PDE_BALANCE_QUANTITY >= 0
         and not DOC_LIB_DOCUMENT.IsDocumentDischarged(tplDetail2Balance.DOC_DOCUMENT_ID) then
        -- décharge du détail courant
        DOC_POSITION_FUNCTIONS.balancePosition(aPositionId => tplDetail2Balance.DOC_POSITION_ID, aBalanceMvt => 0, aDateBalanced => aBalanceDate);
      end if;
    end loop;
  end balanceDetailCascade;

  /**
  * Description
  *    solde de toutes les positions du document, en cascade
  */
  procedure balanceDocumentCascade(aSourceDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aBalance in number default 1)
  is
    cursor crPositions2Balance(aCrDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   DOC_POSITION_DETAIL_ID
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , DOC_DOCUMENT DMT
         where POS.DOC_DOCUMENT_ID = aCrDocumentId
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and (   aBalance = 1
                or (    aBalance = 0
                    and not exists(select DOC_POSITION_DETAIL_ID
                                     from DOC_POSITION_DETAIL
                                    where DOC_DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID)
                    and POS.POS_DATE_BALANCED = DMT.DMT_DATE_BALANCED
                   )
               )
           and POS.C_GAUGE_TYPE_POS in('1', '3', '5', '7', '8', '91', '10')
      order by POS.POS_NUMBER
             , PDE.DOC_POSITION_DETAIL_ID;

    lBalanceDate date := sysdate;
  begin
    for tplPosition2Balance in crPositions2balance(aSourceDocumentId) loop
      if aBalance = 1 then
        balanceDetailCascade(tplPosition2Balance.DOC_POSITION_DETAIL_ID, lBalanceDate);
      else
        unbalanceDetailCascade(tplPosition2Balance.DOC_POSITION_DETAIL_ID);
      end if;
    end loop;

    if aBalance = 1 then
      -- il faut être sûr que la date de solde du document soit exactement la même que celle des positions
      update DOC_DOCUMENT
         set DMT_DATE_BALANCED = lBalanceDate
       where DOC_DOCUMENT_ID = aSourceDocumentId;
    else
      update DOC_DOCUMENT
         set DMT_DATE_BALANCED = null
       where DOC_DOCUMENT_ID = aSourceDocumentId;
    end if;
  end balanceDocumentCascade;

  /**
  * Description
  *    Test si les condition sont remplies pour générer le document final
  */
  function canGenerateFinalDocument(aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return number
  is
    vNbBadDocs pls_integer;
  begin
    -- vérifie si tous les autres documents de l'échéancier sont générés
    select count(*)
      into vNbBadDocs
      from DOC_INVOICE_EXPIRY INX1
         , DOC_INVOICE_EXPIRY INX2
     where INX1.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryID
       and INX1.C_INVOICE_EXPIRY_DOC_TYPE = '3'
       and INX2.DOC_DOCUMENT_ID = INX1.DOC_DOCUMENT_ID
       and INX2.C_INVOICE_EXPIRY_DOC_TYPE <> '3'
       and INX2.INX_INVOICE_GENERATED = 0;

    if vNbBadDocs = 0 then
      -- vérifie si tous les autres documents de l'échéancier sont confirmés
      select count(*)
        into vNbBadDocs
        from DOC_INVOICE_EXPIRY INX1
           , DOC_INVOICE_EXPIRY INX2
           , DOC_DOCUMENT DMT
       where INX1.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryID
         and INX1.C_INVOICE_EXPIRY_DOC_TYPE = '3'
         and INX2.DOC_DOCUMENT_ID = INX1.DOC_DOCUMENT_ID
         and INX2.C_INVOICE_EXPIRY_DOC_TYPE <> '3'
         and DMT.DOC_INVOICE_EXPIRY_ID = INX2.DOC_INVOICE_EXPIRY_ID
         and DMT.C_DOCUMENT_STATUS < '02';
    end if;

    return abs(sign(vNbBadDocs) - 1);
  end canGenerateFinalDocument;

  /**
  * Description
  *    création d'un document d'accompte
  */
  procedure generateDepositDocumentPos(
    aNewDocumentId           DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSourceDocumentId        DOC_INVOICE_EXPIRY.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId         DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aWording                 DOC_INVOICE_EXPIRY.INX_WORDING%type
  , aDescription             DOC_INVOICE_EXPIRY.INX_DESCRIPTION%type
  , aGoodId                  DOC_INVOICE_EXPIRY.GCO_GOOD_ID%type
  , aGoodPrice               DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
  , aDateRef                 date
  , aErrorCode        out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  , aSimulation       in     number default 0
  , aGaugeId          in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  )
  is
    vSqlErrm     varchar2(4000);
    vTargetTable varchar2(30)   := 'DOC_POSITION';
  begin
    if (aSimulation = 1) then
      vTargetTable  := 'DOC_ESTIMATED_POS_CASH_FLOW';
    end if;

    -- si pas de détails d'échéancier
    if pIsDetail(aInvoiceExpiryId) = 0 then
      declare
        vPositionId DOC_POSITION.DOC_POSITION_ID%type;
      begin
        -- Initialisation des données de la position que l'on va créer
        Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
        Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO        := 0;
        Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID      := aInvoiceExpiryId;
        Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
        Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION      := aWording;
        Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
        Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION       := aDescription;
        Doc_Position_Initialize.PositionInfo.USE_POS_NET_TARIFF         := 1;
        Doc_Position_Initialize.PositionInfo.POS_NET_TARIFF             := 1;
        Doc_Position_Initialize.PositionInfo.SIMULATION                 := aSimulation;
        Doc_Position_Initialize.PositionInfo.USE_DOC_RECORD_ID          := 1;
        Doc_Position_Initialize.PositionInfo.DOC_RECORD_ID              := null;
        -- création d'une position de document
        Doc_Position_Generate.GeneratePosition(aPositionID       => vPositionID
                                             , aDocumentID       => aNewDocumentID
                                             , aPosCreateMode    => '190'
                                             , aTypePos          => '1'
                                             , aGoodID           => aGoodId
                                             , aBasisQuantity    => 1.0
                                             , aGoodPrice        => aGoodPrice
                                             , aGenerateDetail   => 1
                                             , aTargetTable      => vTargetTable
                                             , aGaugeId          => aGaugeId
                                              );
        -- ventilation comptable
        ventilateDocRecordOnDepositPos(aNewDocumentID, vPositionId, aSourceDocumentId, aSimulation);
      end;
    else
      -- pour chaque détail
      for tplInvoiceExpiryDetail in (select   IED.DOC_INVOICE_EXPIRY_DETAIL_ID
                                            , IED_DISCHARGE_QUANTITY
                                            , IED.IED_RET_DEPOSIT_NET_EXCL
                                            , IED_NET_VALUE_EXCL
                                            , IED_NET_VALUE_INCL
                                            , IED_WORDING
                                            , IED_DESCRIPTION
                                            , PDE.DOC_POSITION_DETAIL_ID
                                            , IED.DOC_POSITION_ID
                                         from DOC_INVOICE_EXPIRY_DETAIL IED
                                            , DOC_POSITION POS
                                            , DOC_POSITION_DETAIL PDE
                                        where IED.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                          and POS.DOC_POSITION_ID = IED.DOC_POSITION_ID
                                          and PDE.DOC_POSITION_ID = IED.DOC_POSITION_ID
                                          and (   nvl(IED_DISCHARGE_QUANTITY, 0) <> 0
                                               or nvl(IED_RET_DEPOSIT_NET_EXCL, 0) <> 0
                                               or nvl(IED_NET_VALUE_EXCL, 0) <> 0)
                                     order by POS.POS_NUMBER
                                            , PDE.DOC_POSITION_DETAIL_ID) loop
        declare
          vPositionId DOC_POSITION.DOC_POSITION_ID%type;
        begin
          -- Initialisation des données de la position que l'on va créer
          Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
          Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO           := 0;
          Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID         := aInvoiceExpiryId;
          Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_DETAIL_ID  := tplInvoiceExpiryDetail.DOC_INVOICE_EXPIRY_DETAIL_ID;
          Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION     := 1;
          Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION         := tplInvoiceExpiryDetail.IED_WORDING;
          Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION      := 1;
          Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION          := tplInvoiceExpiryDetail.IED_DESCRIPTION;
          Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE                := 1;
          Doc_Position_Initialize.PositionInfo.USE_POS_NET_TARIFF            := 1;
          Doc_Position_Initialize.PositionInfo.POS_NET_TARIFF                := 1;
          Doc_Position_Initialize.PositionInfo.SIMULATION                    := aSimulation;
          Doc_Position_Initialize.PositionInfo.USE_DOC_RECORD_ID             := 1;
          Doc_Position_Initialize.PositionInfo.DOC_RECORD_ID                 := null;
          -- création d'une position de document
          Doc_Position_Generate.GeneratePosition(aPositionID       => vPositionID
                                               , aDocumentID       => aNewDocumentID
                                               , aGaugeId          => aGaugeId
                                               , aPosCreateMode    => '190'
                                               , aTypePos          => '1'
                                               , aGoodID           => aGoodId
                                               , aBasisQuantity    => 1.0
                                               , aGoodPrice        => tplInvoiceExpiryDetail.IED_NET_VALUE_EXCL
                                               , aGenerateDetail   => 1
                                               , aTargetTable      => vTargetTable
                                                );
          -- ventilation comptable
          ventilatePosRecordOnDepositPos(aNewDocumentID, vPositionId, tplInvoiceExpiryDetail.DOC_POSITION_ID, aSimulation);
        end;
      end loop;
    end if;

    if aSimulation = 0 then
      -- mise à jour du flag "Document d'échéancier généré"
      update DOC_INVOICE_EXPIRY
         set INX_INVOICING_DATE = decode(aErrorCode, null, aDateRef, null)
           , C_DOC_INVOICE_EXPIRY_ERROR = aErrorCode
           , INX_INVOICE_GENERATED = decode(aErrorCode, null, 1, 0)
       where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;
    end if;
  exception
    when others then
      if (aSimulation = 0) then
        vSqlErrm    := DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_call_stack;

        -- mise à jour du flag erreur ('erreur PLSQL lors de la génération du document')
        update DOC_INVOICE_EXPIRY
           set C_DOC_INVOICE_EXPIRY_ERROR = '050'
             , INX_ERROR_MESSAGE = vSqlErrm
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        aErrorCode  := '050';
        commit;
      else
        -- mise à jour du flag "Document d'échéancier généré"
        update DOC_INVOICE_EXPIRY
           set INX_INVOICING_DATE = null
             , C_DOC_INVOICE_EXPIRY_ERROR = null
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        aErrorCode  := '000';
        raise;
      end if;
  end generateDepositDocumentPos;

  /**
  * Description
  *    création d'un document d'accompte
  */
  procedure generateDepositDocument(
    aInvoiceExpiryId in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aDateRef         in     date
  , aDateValue       in     date
  , aDocumentId      out    DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aErrorCode       out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  , aSimulation      in     number default 0
  )
  is
    vSqlErrm varchar2(4000);
  begin
    -- pour l'échéance à traiter
    for tplInvoiceExpiry in (select INX.DOC_INVOICE_EXPIRY_ID
                                  , INX.DOC_DOCUMENT_ID
                                  , INX.DOC_GAUGE_ID
                                  , DMT.PAC_THIRD_ID
                                  , DMT.PC_LANG_ID
                                  , DMT.DMT_NUMBER
                                  , DMT.PAC_REPRESENTATIVE_ID
                                  , INX.INX_DESCRIPTION
                                  , INX.INX_WORDING
                                  , INX.GCO_GOOD_ID
                                  , INX.INX_NET_VALUE_EXCL
                                  , INX.PAC_PAYMENT_CONDITION_ID
                               from DOC_INVOICE_EXPIRY INX
                                  , DOC_DOCUMENT DMT
                              where INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5', '6')
                                and INX.INX_INVOICE_GENERATED = 0
                                and DMT.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID) loop
      if (aSimulation = 0) then
        -- création de l'entête du document
        generateBillBookDocumentHeader(aDocumentId           => aDocumentId
                                     , aSrcDocumentId        => tplInvoiceExpiry.DOC_DOCUMENT_ID
                                     , aInvoiceExpiryId      => tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                     , aPaymentConditionId   => tplInvoiceExpiry.PAC_PAYMENT_CONDITION_ID
                                     , aGaugeId              => tplInvoiceExpiry.DOC_GAUGE_ID
                                     , aThirdId              => tplInvoiceExpiry.PAC_THIRD_ID
                                     , aRepresentativeId     => tplInvoiceExpiry.PAC_REPRESENTATIVE_ID
                                     , aMode                 => '390'
                                     , aDocumentDate         => aDateRef
                                     , aValueDate            => nvl(aDateValue, trunc(sysdate) )
                                      );
      else
        aDocumentId  := tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID;
      end if;

      if aSimulation = 0 then
        commit;   -- on conserve l'atomicité qu'on a dans le soft, c'est à dire qu'on Commit à chaque position
      end if;

      generateDepositDocumentPos(aNewDocumentId      => aDocumentId
                               , aSourceDocumentId   => tplInvoiceExpiry.DOC_DOCUMENT_ID
                               , aInvoiceExpiryId    => aInvoiceExpiryId
                               , aGaugeId            => tplInvoiceExpiry.DOC_GAUGE_ID
                               , aWording            => tplInvoiceExpiry.INX_WORDING
                               , aDescription        => tplInvoiceExpiry.INX_DESCRIPTION
                               , aGoodId             => tplInvoiceExpiry.GCO_GOOD_ID
                               , aGoodPrice          => tplInvoiceExpiry.INX_NET_VALUE_EXCL
                               , aDateRef            => aDateRef
                               , aErrorCode          => aErrorCode
                               , aSimulation         => aSimulation
                                );

      if (aSimulation = 0) then
        DOC_FINALIZE.FinalizeDocument(aDocumentId);
      end if;

      if aSimulation = 0 then
        commit;   -- on conserve l'atomicité qu'on a dans le soft, c'est à dire qu'on Commit à chaque position
      end if;
    end loop;
  exception
    when others then
      if aSimulation = 0 then
        vSqlErrm    := DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_call_stack;

        -- mise à jour du flag erreur ('erreur PLSQL lors de la génération du document')
        update DOC_INVOICE_EXPIRY
           set C_DOC_INVOICE_EXPIRY_ERROR = '050'
             , INX_ERROR_MESSAGE = vSqlErrm
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        aErrorCode  := '050';
        commit;
      end if;
  end generateDepositDocument;

  /**
  * function getSimDischargedQuantity
  * Description
  *
  * @created fp 12.09.2008
  * @lastUpdate
  * @public
  * @param
  * @return
  */
  function getSimDischargedQuantity(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_POSITION.POS_BASIS_QUANTITY%type
  is
    vResult DOC_POSITION.POS_BASIS_QUANTITY%type;
  begin
    select nvl(sum(POS_BASIS_QUANTITY), 0)
      into vResult
      from DOC_ESTIMATED_POS_CASH_FLOW
     where DOC_DOC_POSITION_ID = aPositionId;

    return vResult;
  end getSimDischargedQuantity;

  /**
  * procedure simulateDischargeDetail
  * Description
  *    décharge d'un détail dans la facture finale
  * @created fp 07.09.2006
  * @lastUpdate fp 28.11.2006
  * @private
  * @param aInvoiceExpiryId : id de l'échéancier
  * @param aGaugeId : gabarit cible
  * @param ADetailID      : Id du détail à décharger
  * @param aGaugeFlowId      : Id du flux
  * @param aDischargeAmount      : Forcer le montant à décharger
  * @param aDischargeQuantity : quantité à décharger (en cas de décharge partielles ou supérieures à la quantité d'origine)
  * @param out aErrorCode : code d'erreur si problème
  */
  procedure simulateDischargeDetail(
    aInvoiceExpiryId   in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aDetailID          in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aGaugeFlowId       in     DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type
  , aDischargeAmount   in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type default null
  , aDischargeQuantity in     DOC_INVOICE_EXPIRY_DETAIL.IED_DISCHARGE_QUANTITY%type default null
  , aErrorCode         out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
  is
    cursor crDischargePositionDetail(
      aCrDetailID          in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aCrNewGaugeId        in DOC_GAUGE.DOC_GAUGE_ID%type
    , aCrDischargeAmount   in DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
    , aCrDischargeQuantity in number
    )
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , decode(aCrDischargeAmount
                           , null, least(nvl(aCrDischargeQuantity, PDE.PDE_BALANCE_QUANTITY), PDE.PDE_BALANCE_QUANTITY)
                           , decode(POS.POS_NET_VALUE_EXCL, 0, 0, aCrDischargeAmount / POS.POS_NET_VALUE_EXCL)
                            ) -
                      getSimDischargedQuantity(POS.DOC_POSITION_ID) DCD_QUANTITY
                    , decode(aCrDischargeAmount
                           , null, ACS_FUNCTION.RoundNear(least(nvl(aCrDischargeQuantity, PDE.PDE_BALANCE_QUANTITY), PDE.PDE_BALANCE_QUANTITY) *
                                                          POS.POS_CONVERT_FACTOR
                                                        , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                        , 1
                                                         )
                           , decode(POS.POS_NET_VALUE_EXCL, 0, 0, aCrDischargeAmount / POS.POS_NET_VALUE_EXCL)
                            ) DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aCrNewGaugeId, DMT.PAC_THIRD_ID) as DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , aCrNewGaugeId NEW_GAUGE_ID
                    , DMT.PAC_THIRD_ID NEW_THIRD_ID
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_GAUGE GAU
                where PDE.DOC_POSITION_DETAIL_ID = aCrDetailID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);

    cursor crDischargePositionDetailCPT(
      aCrPositionID        in number
    , aCrNewPtPositionID   in number
    , aCrTgtGaugeID        in number
    , aCrThirdID           in number
    , aCrDischargeQuantity in number
    )
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , (nvl(aCrDischargeQuantity, DCD.POS_BASIS_QUANTITY) * nvl(POS.POS_UTIL_COEFF, 1) ) - getSimDischargedQuantity(POS.DOC_POSITION_ID)
                                                                                                                                                   DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(nvl(aCrDischargeQuantity, DCD.POS_BASIS_QUANTITY) * nvl(POS.POS_UTIL_COEFF, 1) * POS.POS_CONVERT_FACTOR
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aCrTgtGaugeID, aCrThirdID) as DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , POS.POS_NUMBER
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_ESTIMATED_POS_CASH_FLOW DCD
                    , DOC_GAUGE GAU
                where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID = aCrPositionID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                  and DCD.DOC_POSITION_ID = aCrNewPtPositionId
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    vSourcePositionId          DOC_POSITION.DOC_POSITION_ID%type;
    vStrTypePos                DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    vPTPositionID              DOC_POSITION.DOC_POSITION_ID%type;
    vNewID                     DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vGaugeid                   DOC_GAUGE.DOC_GAUGE_ID%type;
    vSourceDocumentId          DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vQuantityCPT               DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    vQuantityCPT_SU            DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
    vGreatestSumQuantityCPT    DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    vGreatestSumQuantityCPT_SU DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
    vInputData                 varchar2(32000);
    vTargetPositionId          DOC_POSITION.DOC_POSITION_ID%type;
    vDischargeInfoCode         varchar2(10);
    vTargetTable               varchar2(30)                                                    := 'DOC_ESTIMATED_POS_CASH_FLOW';
  begin
    select DOC_GAUGE_ID
      into vGaugeId
      from DOC_INVOICE_EXPIRY
     where DOC_INVOICE_EXPIRY_ID = ainvoiceExpiryId;

    /* Détail de position à décharger */
    for tplDischargePositionDetail in crDischargePositionDetail(aDetailID, vGaugeId, aDischargeAmount, aDischargeQuantity) loop
      -- Erreur si on tente de décharger plus que le contenu du document source
      if     aDischargeQuantity is not null
         and aDischargeQuantity > tplDischargePositionDetail.DCD_QUANTITY then
        aErrorCode  := '030';
        exit;
      end if;

      select init_id_seq.nextval
        into vNewID
        from dual;

      -- Initialisation des données de la position que l'on va créer
      Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
      Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO    := 0;
      Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID  := aInvoiceExpiryId;
      Doc_Position_Initialize.PositionInfo.DOC_DOC_POSITION_ID    := tplDischargePositionDetail.DOC_POSITION_ID;
      Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE         := 1;
      Doc_Position_Initialize.PositionInfo.SIMULATION             := 1;
      -- création d'une position de document
      Doc_Position_Generate.GeneratePosition(aPositionID       => vNewID
                                           , aDocumentID       => aInvoiceExpiryId
                                           , aGaugeId          => vGaugeId
                                           , aPosCreateMode    => '190'
                                           , aTypePos          => tplDischargePositionDetail.C_GAUGE_TYPE_POS
                                           , aGoodID           => tplDischargePositionDetail.GCO_GOOD_ID
                                           , aBasisQuantity    => tplDischargePositionDetail.DCD_QUANTITY   --aDischargeQuantity
                                           , aGoodPrice        => tplDischargePositionDetail.POS_GROSS_UNIT_VALUE   --aDischargeAmount
                                           , aGenerateDetail   => 1
                                           , aTargetTable      => vTargetTable
                                            );
      -- ventilation comptable selon parent
      ventilatePosAmountOnPos(aInvoiceExpiryId, vNewID, tplDischargePositionDetail.DOC_POSITION_ID, 1);
      vSourcePositionId                                           := tplDischargePositionDetail.DOC_POSITION_ID;
      vStrTypePos                                                 := tplDischargePositionDetail.C_GAUGE_TYPE_POS;

      /* Traitment des pos cpt si il s'agit d0un posiiton kit ou assemblage */
      if (vStrTypePos in('7', '8', '9', '10') ) then
        vPtPositionId               := vNewId;
        vGreatestSumQuantityCPT     := 0;
        vGreatestSumQuantityCPT_SU  := 0;

        for tplDischargePositionDetailCPT in crDischargePositionDetailCPT(vSourcePositionId
                                                                        , vPTPositionID
                                                                        , tplDischargePositionDetail.NEW_GAUGE_ID
                                                                        , tplDischargePositionDetail.NEW_THIRD_ID
                                                                        , aDischargeQuantity
                                                                         ) loop
          vQuantityCPT                                                := tplDischargePositionDetailCPT.DCD_QUANTITY;
          vQuantityCPT_SU                                             := tplDischargePositionDetailCPT.DCD_QUANTITY_SU;

          /* Stock la plus grande quantité des composants après application du
             coefficient d'utilisation */
          if (nvl(tplDischargePositionDetailCPT.POS_UTIL_COEFF, 0) = 0) then
            vGreatestSumQuantityCPT     := greatest(vGreatestSumQuantityCPT, 0);
            vGreatestSumQuantityCPT_SU  := greatest(vGreatestSumQuantityCPT_SU, 0);
          else
            vGreatestSumQuantityCPT     := greatest(vGreatestSumQuantityCPT, vQuantityCPT / tplDischargePositionDetailCPT.POS_UTIL_COEFF);
            vGreatestSumQuantityCPT_SU  := greatest(vGreatestSumQuantityCPT_SU, vQuantityCPT_SU / tplDischargePositionDetailCPT.POS_UTIL_COEFF);
          end if;

          -- Initialisation des données de la position que l'on va créer
          Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
          Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO    := 0;
          Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID  := aInvoiceExpiryId;
          Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE         := 1;
          Doc_Position_Initialize.PositionInfo.SIMULATION             := 1;
          -- création d'une position de document
          Doc_Position_Generate.GeneratePosition(aPositionID       => vNewID
                                               , aDocumentID       => -1
                                               , aGaugeId          => vGaugeId
                                               , aPosCreateMode    => '190'
                                               , aTypePos          => tplDischargePositionDetailCPT.C_GAUGE_TYPE_POS
                                               , aGoodID           => tplDischargePositionDetailCPT.GCO_GOOD_ID
                                               , aBasisQuantity    => vQuantityCPT
                                               , aGoodPrice        => tplDischargePositionDetailCPT.POS_GROSS_UNIT_VALUE
                                               , aGenerateDetail   => 1
                                               , aTargetTable      => vTargetTable
                                                );
          -- ventilation comptable selon parent
          ventilatePosAmountOnPos(aInvoiceExpiryId, vNewID, tplDischargePositionDetailCPT.DOC_POSITION_ID, 1);
        end loop;
      end if;
    end loop;
  end simulateDischargeDetail;

  /**
  * procedure simulateDischargeCascade
  * Description
  *
  * @created fp 05.07.2007
  * @lastUpdate
  * @public
  * @param
  */
  procedure simulateDischargeCascade(
    aSourceDetailId    in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , ainvoiceExpiryId   in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aDischargeAmount   in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type default null
  , aDischargeQuantity in     DOC_INVOICE_EXPIRY_DETAIL.IED_DISCHARGE_QUANTITY%type default null
  , aErrorCode         out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
  is
    cursor crDetail2Discharge(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE_BALANCE_QUANTITY
           , PDE_FINAL_QUANTITY
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = aCrDetailId;

    cursor crDischargedDetails(aCrDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select DOC_POSITION_DETAIL_ID
        from DOC_POSITION_DETAIL
       where DOC_DOC_POSITION_DETAIL_ID = aCrDetailId
         and PDE_BALANCE_QUANTITY > 0;

    vGaugeFlowId DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    for tplDetail2Discharge in crDetail2Discharge(aSourceDetailId) loop
      -- recherche si le détail courant a déjà été déchargé et, si oui, décharge des fils
      if tplDetail2Discharge.PDE_BALANCE_QUANTITY < tplDetail2Discharge.PDE_FINAL_QUANTITY then
        for tplDischargedDetails in crDischargedDetails(aSourceDetailId) loop
          -- appel de la procédure en cascade
          simulateDischargeCascade(tplDischargedDetails.DOC_POSITION_DETAIL_ID, aInvoiceExpiryId, aDischargeAmount, aDischargeQuantity, aErrorCode);
          -- sortie de la sous-boucle en cas d'erreur
          exit when aErrorCode is not null;
        end loop;
      end if;

      -- sortie de la boucle en cas d'erreur
      exit when aErrorCode is not null;

      -- décharge du détail courant si il reste un solde sur le détail
      if tplDetail2Discharge.PDE_BALANCE_QUANTITY > 0 then
--********************************Extraire dans doc_lib_gauge ******************************************
        -- recherche du flux par défaut
        select DOC_I_LIB_GAUGE.GetFlowID(GAU.C_ADMIN_DOMAIN, DMT.PAC_THIRD_ID)
          into vGaugeFlowId
          from DOC_POSITION_DETAIL PDE
             , DOC_DOCUMENT DMT
             , DOC_GAUGE GAU
         where PDE.DOC_POSITION_DETAIL_ID = aSourceDetailId
           and DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
           and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;

        -- décharge du détail courant
        simulateDischargeDetail(aInvoiceExpiryId, aSourceDetailId, vGaugeFlowId, aDischargeAmount, aDischargeQuantity, aErrorCode);
      end if;
    end loop;
  end simulateDischargeCascade;

  /**
  * procedure SimulateDischarge
  * Description
  *    Création virtuelle de positions simulant la décharge du document final
  * @created fp 05.07.2007
  * @lastUpdate
  * @public
  * @param
  */
  procedure SimulateDischarge(aSourceDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, ainvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
  is
    cursor crPositions2Discharge(aCrDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   DOC_POSITION_DETAIL_ID
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
         where POS.DOC_DOCUMENT_ID = aCrDocumentId
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and POS.C_GAUGE_TYPE_POS in('1', '3', '5', '7', '8', '91', '10')
      order by POS.POS_NUMBER
             , PDE.DOC_POSITION_DETAIL_ID;

    vErrorCode DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type;
  begin
    for tplPosition2Discharge in crPositions2discharge(aSourceDocumentId) loop
      simulatedischargeCascade(aSourceDetailId    => tplPosition2Discharge.DOC_POSITION_DETAIL_ID, aInvoiceExpiryId => aInvoiceExpiryId
                             , aErrorCode         => vErrorCode);
    end loop;
  end SimulateDischarge;

  /**
  * Description
  *    création d'un document de facture finale
  */
  procedure generateFinalInvoiceDocPos(
    aNewDocumentId    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSourceDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId  in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aWording          in     DOC_INVOICE_EXPIRY.INX_WORDING%type
  , aDescription      in     DOC_INVOICE_EXPIRY.INX_DESCRIPTION%type
  , aGoodId           in     DOC_INVOICE_EXPIRY.GCO_GOOD_ID%type
  , aGoodPrice        in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
  , aOnlyAmount       in     number
  , aBalanceParent    in     number
  , aDateRef          in     date
  , aErrorCode        out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  , aSimulation       in     number default 0
  , aGaugeId          in     DOC_DOCUMENT.DOC_GAUGE_ID%type default null
  )
  is
    vPositionId  DOC_POSITION.DOC_POSITION_ID%type;
    vSqlErrm     varchar2(4000);
    vTargetTable varchar2(30)                        := 'DOC_POSITION';
  begin
    if (aSimulation = 1) then
      vTargetTable  := 'DOC_ESTIMATED_POS_CASH_FLOW';
    end if;

    if aOnlyAmount = 0 then
      if aSimulation = 0 then
        -- décharge de toutes les positions pas encore facturées
        dischargeDocumentCascade(aSourceDocumentId, aNewDocumentId, aInvoiceExpiryId);
      else
        simulateDischarge(aSourceDocumentId, aInvoiceExpiryId);
      end if;
    elsif aOnlyAmount = 1 then
      -- solde en cascade de toutes les position du document d'origine
      if     aSimulation = 0
         and (   aBalanceParent = 1
              or ( (    aBalanceParent = 2
                    and FWK_I_LIB_ENTITY.getvarchar2fieldfrompk('DOC_DOCUMENT', 'C_DOCUMENT_STATUS', aSourceDocumentId) = '02') )
             ) then
        balanceDocumentCascade(aSourceDocumentId, 1);
      end if;

      --** création d'une position valeur avec le montant solde
      -- Initialisation des données de la position que l'on va créer
      Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
      Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO        := 0;
      Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID      := aInvoiceExpiryId;
      Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
      Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION      := aWording;
      Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
      Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION       := aDescription;
      Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE             := 1;
      Doc_Position_Initialize.PositionInfo.SIMULATION                 := aSimulation;
      Doc_Position_Initialize.PositionInfo.USE_DOC_RECORD_ID          := 1;
      Doc_Position_Initialize.PositionInfo.DOC_RECORD_ID              := null;

      -- création d'une position de document
      begin
        Doc_Position_Generate.GeneratePosition(aPositionID       => vPositionID
                                             , aDocumentID       => aNewDocumentId
                                             , aGaugeId          => aGaugeId
                                             , aPosCreateMode    => '190'
                                             , aTypePos          => '1'
                                             , aGoodID           => aGoodId
                                             , aBasisQuantity    => 1.0
                                             , aGoodPrice        => aGoodPrice
                                             , aGenerateDetail   => 1
                                             , aTargetTable      => vTargetTable
                                              );
        -- ventilation comptable
        ventilateBalanceDocAmountOnPos(aNewDocumentId, vPositionId, aSourceDocumentId, aSimulation);
      exception
        when others then
          raise_application_error(-20000, aInvoiceExpiryId);
      end;
    end if;

    if aSimulation = 0 then
      -- prise en compte des accomptes déjà versés
      dischargeDepositPos(aNewDocumentId      => aNewDocumentId
                        , aInvoiceExpiryId    => aInvoiceExpiryId
                        , aSourceDocumentId   => aSourceDocumentId
                        , aErrorCode          => aErrorCode
                         );
    else
      dischargeSimBalanceDeposit(aNewDocumentId, aInvoiceExpiryId, aSourceDocumentId, aErrorCode);
    end if;

    if (aSimulation = 0) then
      -- mise à jour du flag "Document d'échéancier généré"
      update DOC_INVOICE_EXPIRY
         set INX_INVOICING_DATE = decode(aErrorCode, null, aDateRef, null)
           , C_DOC_INVOICE_EXPIRY_ERROR = aErrorCode
           , INX_INVOICE_GENERATED = decode(aErrorCode, null, 1, 0)
       where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;
    end if;
  exception
    when others then
      if (aSimulation = 0) then
        vSqlErrm    := DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_call_stack;

        -- mise à jour du flag erreur ('erreur PLSQL lors de la génération du document')
        update DOC_INVOICE_EXPIRY
           set C_DOC_INVOICE_EXPIRY_ERROR = '050'
             , INX_ERROR_MESSAGE = vSqlErrm
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        aErrorCode  := '050';
        commit;
      end if;
  end generateFinalInvoiceDocPos;

  function getPositionSimulatedQty(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_POSITION.POS_NET_VALUE_EXCL%type
  is
    vResult DOC_POSITION.POS_NET_VALUE_EXCL%type;
  begin
    select sum(POS_BASIS_QUANTITY)
      into vResult
      from DOC_POSITION
     where DOC_INVOICE_EXPIRY_DETAIL_ID =
                         (select DOC_INVOICE_EXPIRY_DETAIL_ID IED
                            from DOC_INVOICE_EXPIRY_DETAIL IED
                               , DOC_INVOICE_EXPIRY INX
                           where INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
                             and IED.DOC_POSITION_ID = aPositionId
                             and C_INVOICE_EXPIRY_DOC_TYPE = '2');

    return nvl(vResult, 0);
  end getPositionSimulatedQty;

  /**
  * Description
  *    création d'un document de facture partielle (seule l'entête est créée)
  */
  procedure generatePartialInvoiceDocPos(
    aNewDocumentId    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSourceDocumentId in     DOC_INVOICE_EXPIRY.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId  in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aWording          in     DOC_INVOICE_EXPIRY.INX_WORDING%type
  , aDescription      in     DOC_INVOICE_EXPIRY.INX_DESCRIPTION%type
  , aGoodId           in     DOC_INVOICE_EXPIRY.GCO_GOOD_ID%type
  , aGoodPrice        in     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
  , aRetDeposit       in     DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type
  , aOnlyAmount       in     number
  , aDateRef          in     date
  , aErrorCode        out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  , aSimulation       in     number default 0
  , aGaugeId          in     DOC_GAUGE.DOC_GAUGE_ID%type
  )
  is
    vSqlErrm     varchar2(4000);
    vTargetTable varchar2(30)   := 'DOC_POSITION';
  begin
    if (aSimulation = 1) then
      vTargetTable  := 'DOC_ESTIMATED_POS_CASH_FLOW';
    end if;

    -- si pas de détails d'échéancier
    if pIsDetail(aInvoiceExpiryId) = 0 then
      if aOnlyAmount = 1 then
        declare
          vPositionId DOC_POSITION.DOC_POSITION_ID%type;
        begin
          -- Initialisation des données de la position que l'on va créer
          Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
          Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO        := 0;
          Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID      := aInvoiceExpiryId;
          Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
          Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION      := aWording;
          Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
          Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION       := aDescription;
          Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE             := 1;
          Doc_Position_Initialize.PositionInfo.SIMULATION                 := aSimulation;
          Doc_Position_Initialize.PositionInfo.USE_DOC_RECORD_ID          := 1;
          Doc_Position_Initialize.PositionInfo.DOC_RECORD_ID              := null;
          -- création d'une position de document
          Doc_Position_Generate.GeneratePosition(aPositionID       => vPositionID
                                               , aDocumentID       => aNewDocumentID
                                               , aGaugeId          => aGaugeId
                                               , aPosCreateMode    => '190'
                                               , aTypePos          => '1'
                                               , aGoodID           => aGoodID
                                               , aBasisQuantity    => 1.0
                                               , aGoodPrice        => aGoodPrice
                                               , aGenerateDetail   => 1
                                               , aTargetTable      => vTargetTable
                                                );
          ventilateDocAmountOnPos(aNewDocumentId, vPositionId, aSourceDocumentId, aSimulation);
        exception
          when others then
            raise_application_error(-20000
                                  , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur à la génération de l''échéance (ID : [ID])' || '/' || aGoodID)
                                          , '[ID]'
                                          , aInvoiceExpiryId
                                           )
                                   );
        end;
      else   -- décharge sans montant
        -- Seulement en cas de simulation
        if aSimulation = 1 then
          declare
            vTotBalanceAmount DOC_POSITION.POS_NET_VALUE_EXCL%type;
          begin
            select sum(nvl(POS.POS_NET_UNIT_VALUE *(POS.POS_BALANCE_QUANTITY - getPositionSimulatedQty(POS.DOC_POSITION_ID) ), 0) )
              into vTotBalanceAmount
              from DOC_POSITION POS
             where DOC_DOCUMENT_ID = aSourceDocumentId
               and POS.C_GAUGE_TYPE_POS in('1', '3', '5', '7', '8', '91', '10');

            for tplPosition in (select   POS.DOC_POSITION_ID
                                       , POS.POS_BALANCE_QUANTITY - DOC_INVOICE_EXPIRY_FUNCTIONS.getPositionSimulatedQty(POS.DOC_POSITION_ID)
                                                                                                                                           POS_BALANCE_QUANTITY
                                       , POS.POS_NET_UNIT_VALUE
                                       , POS.GCO_GOOD_ID
                                       , POS.POS_REFERENCE
                                       , POS.POS_SHORT_DESCRIPTION
                                       , POS.POS_LONG_DESCRIPTION
                                    from DOC_POSITION POS
                                   where DOC_DOCUMENT_ID = aSourceDocumentId
                                     and POS.C_GAUGE_TYPE_POS in('1', '3', '5', '7', '8', '91', '10')
                                order by POS.POS_NUMBER) loop
              declare
                vPositionId DOC_POSITION.DOC_POSITION_ID%type;
                vPrice      DOC_POSITION.POS_GROSS_UNIT_VALUE%type   := 0;
              begin
                -- Initialisation des données de la position que l'on va créer
                Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
                Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO        := 0;
                Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID      := aInvoiceExpiryId;
                Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
                Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION      := tplPosition.POS_SHORT_DESCRIPTION;
                Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
                Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION       := tplPosition.POS_LONG_DESCRIPTION;
                Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE             := 1;
                Doc_Position_Initialize.PositionInfo.SIMULATION                 := aSimulation;

                if vTotBalanceAmount <> 0 then
                  vPrice  := ( (tplPosition.POS_BALANCE_QUANTITY * tplPosition.POS_NET_UNIT_VALUE) * aGoodPrice) / vTotBalanceAmount;
                end if;

                -- création d'une position de document
                Doc_Position_Generate.GeneratePosition(aPositionID       => vPositionID
                                                     , aDocumentID       => aNewDocumentID
                                                     , aGaugeId          => aGaugeId
                                                     , aPosCreateMode    => '190'
                                                     , aTypePos          => '1'
                                                     , aGoodID           => tplPosition.GCO_GOOD_ID
                                                     , aBasisQuantity    => 1.0
                                                     , aGoodPrice        => vPrice
                                                     , aGenerateDetail   => 1
                                                     , aTargetTable      => vTargetTable
                                                      );
                ventilatePosAmountOnPos(aNewDocumentId, vPositionId, tplPosition.DOC_POSITION_ID, aSimulation);
              end;
            end loop;
          end;
        end if;
      end if;

      -- Reprise d'accomptes déjà versés
      if    aRetDeposit <> 0
         or aRetDeposit is null then
        dischargeDepositPos(aNewDocumentId, aInvoiceExpiryId, aSourceDocumentId, null, aRetDeposit, aSimulation, aErrorCode);
      end if;
    --échéancier avec détails
    else
      -- pour chaque détail
      for tplInvoiceExpiryDetail in (select   IED.DOC_INVOICE_EXPIRY_DETAIL_ID
                                            , IED.IED_NET_VALUE_EXCL
                                            , IED_DISCHARGE_QUANTITY
                                            , IED.IED_RET_DEPOSIT_NET_EXCL
                                            , IED.IED_DESCRIPTION
                                            , IED.IED_WORDING
                                            , decode(POS_FINAL_QUANTITY, 0, 0, POS_NET_VALUE_EXCL * IED_DISCHARGE_QUANTITY / POS_FINAL_QUANTITY)
                                                                                                                                             POS_NET_VALUE_EXCL
                                            , decode(POS_FINAL_QUANTITY, 0, 0, POS_NET_VALUE_INCL * IED_DISCHARGE_QUANTITY / POS_FINAL_QUANTITY)
                                                                                                                                             POS_NET_VALUE_INCL
                                            , IED.DOC_POSITION_ID
                                            , PDE.DOC_POSITION_DETAIL_ID
                                            , PDE.GCO_GOOD_ID
                                         from DOC_INVOICE_EXPIRY_DETAIL IED
                                            , DOC_POSITION POS
                                            , DOC_POSITION_DETAIL PDE
                                        where IED.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                          and POS.DOC_POSITION_ID = IED.DOC_POSITION_ID
                                          and PDE.DOC_POSITION_ID = IED.DOC_POSITION_ID
                                          and (   nvl(IED_DISCHARGE_QUANTITY, 0) <> 0
                                               or nvl(IED_RET_DEPOSIT_NET_EXCL, 0) <> 0
                                               or nvl(IED_NET_VALUE_EXCL, 0) <> 0)
                                     order by POS.POS_NUMBER
                                            , PDE.DOC_POSITION_DETAIL_ID) loop
        declare
          vPositionId        DOC_POSITION.DOC_POSITION_ID%type;
          vRecordId          number(12);
          vDischargeQuantity number;
        begin
          if aOnlyAmount = 1 then
            begin
              -- Initialisation des données de la position que l'on va créer
              Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
              Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO           := 0;
              Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID         := aInvoiceExpiryId;
              Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_DETAIL_ID  := tplInvoiceExpiryDetail.DOC_INVOICE_EXPIRY_DETAIL_ID;
              Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION     := 1;
              Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION         := tplInvoiceExpiryDetail.IED_WORDING;
              Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION      := 1;
              Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION          := tplInvoiceExpiryDetail.IED_DESCRIPTION;
              Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE                := 1;
              Doc_Position_Initialize.PositionInfo.SIMULATION                    := aSimulation;
              Doc_Position_Initialize.PositionInfo.USE_DOC_RECORD_ID             := 1;
              Doc_Position_Initialize.PositionInfo.DOC_RECORD_ID                 := null;
              -- création d'une position de document
              Doc_Position_Generate.GeneratePosition(aPositionID       => vPositionID
                                                   , aDocumentID       => aNewDocumentID
                                                   , aGaugeId          => aGaugeId
                                                   , aPosCreateMode    => '190'
                                                   , aTypePos          => '1'
                                                   , aGoodID           => aGoodId
                                                   , aBasisQuantity    => 1.0
                                                   , aGoodPrice        => tplInvoiceExpiryDetail.IED_NET_VALUE_EXCL
                                                   , aGenerateDetail   => 1
                                                   , aTargetTable      => vTargetTable
                                                    );

              if aSimulation = 0 then
                select DOC_RECORD_ID
                  into vRecordId
                  from DOC_POSITION
                 where DOC_POSITION_ID = vPositionID;
              else
                select DOC_RECORD_ID
                  into vRecordId
                  from DOC_ESTIMATED_POS_CASH_FLOW
                 where DOC_POSITION_ID = vPositionID;
              end if;

              -- ventilation comptable
              ventilatePosAmountOnPos(aNewDocumentId, vPositionId, tplInvoiceExpiryDetail.DOC_POSITION_ID, aSimulation);
--             exception
--               when others then

            --                 raise_application_error(-20000, aInvoiceExpiryId||DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_call_stack);
            end;
          else
            if aSimulation = 0 then
              vDischargeQuantity  := tplInvoiceExpiryDetail.IED_DISCHARGE_QUANTITY;
              -- décharge des positions sélectionnées
              dischargeDetailCascade(tplInvoiceExpiryDetail.DOC_POSITION_DETAIL_ID, aInvoiceExpiryId, aNewDocumentID, null, vDischargeQuantity, aErrorCode);

              if vDischargeQuantity <> 0 then
                aErrorCode  := '030';
                exit when aErrorCode is not null;
              end if;
            else
              -- Initialisation des données de la position que l'on va créer
              Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
              Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO    := 0;
              Doc_Position_Initialize.PositionInfo.DOC_INVOICE_EXPIRY_ID  := aInvoiceExpiryId;
              Doc_Position_Initialize.PositionInfo.DOC_DOC_POSITION_ID    := tplInvoiceExpiryDetail.DOC_POSITION_ID;
              Doc_Position_Initialize.PositionInfo.USE_GOOD_PRICE         := 1;
              Doc_Position_Initialize.PositionInfo.SIMULATION             := aSimulation;
              --Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION     := 1;
              --Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION         := ;
              --Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION      := 1;
              --Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION          :=  ;
              -- création d'une position de document
              Doc_Position_Generate.GeneratePosition(aPositionID       => vPositionID
                                                   , aDocumentID       => aInvoiceExpiryId   -- -1
                                                   , aGaugeId          => aGaugeId
                                                   , aPosCreateMode    => '190'
                                                   , aTypePos          => '1'
                                                   , aGoodID           => tplInvoiceExpiryDetail.GCO_GOOD_ID
                                                   , aBasisQuantity    => tplInvoiceExpiryDetail.IED_DISCHARGE_QUANTITY
                                                   , aGoodPrice        => tplInvoiceExpiryDetail.IED_NET_VALUE_EXCL *
                                                                          (1 / tplInvoiceExpiryDetail.IED_DISCHARGE_QUANTITY
                                                                          )
                                                   , aGenerateDetail   => 0
                                                   , aTargetTable      => vTargetTable
                                                    );
              -- ventilation comptable selon parent
              ventilatePosAmountOnPos(aNewDocumentId, vPositionId, tplInvoiceExpiryDetail.DOC_POSITION_ID, aSimulation);
            end if;

            exit when aErrorCode is not null;
          end if;

          -- Reprise d'accomptes déjà versés
          if nvl(tplInvoiceExpiryDetail.IED_RET_DEPOSIT_NET_EXCL, 0) <> 0 then
            dischargeDepositPos(aNewDocumentId
                              , aInvoiceExpiryId
                              , aSourceDocumentId
                              , tplInvoiceExpiryDetail.DOC_POSITION_ID
                              , tplInvoiceExpiryDetail.IED_RET_DEPOSIT_NET_EXCL
                              , aSimulation
                              , aErrorCode
                               );
          end if;

          -- Reprise d'accomptes déjà versés
          exit when aErrorCode is not null;
        end;
      end loop;
    end if;

    if (aSimulation = 0) then
      -- mise à jour du flag "Document d'échéancier généré"
      update DOC_INVOICE_EXPIRY
         set INX_INVOICING_DATE = decode(aErrorCode, null, aDateRef, null)
           , C_DOC_INVOICE_EXPIRY_ERROR = aErrorCode
           , INX_INVOICE_GENERATED = decode(aErrorCode, null, 1, 0)
       where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;
    end if;
  exception
    when others then
      if (aSimulation = 0) then
        vSqlErrm    := DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_call_stack;

        -- mise à jour du flag erreur ('erreur PLSQL lors de la génération du document')
        update DOC_INVOICE_EXPIRY
           set C_DOC_INVOICE_EXPIRY_ERROR = '050'
             , INX_ERROR_MESSAGE = vSqlErrm
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        aErrorCode  := '050';
        commit;
      end if;
  end generatePartialInvoiceDocPos;

  /**
  * Description
  *    Vérification des prérequis à la généreration de la facture finale
  */
  function checkFinalInvoicePreRequisite(iInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return varchar2
  is
    lDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type   := GetInvoiceExpiryParentDoc(iInvoiceExpiryId);
    lResult     varchar2(2)                         := '00';
  begin
    -- Si on est sur un échéancier sans décharge et que rien n'a été déchargé au moment de la génération de la facture finale
    -- on retourne un code '01' dans le but de proposer de solder le document parent de l'échéancier
    if     IsDocumentOnlyAmountBillBook(lDocumentId)
       and not DOC_LIB_DOCUMENT.IsDocumentDischarged(lDocumentId) then
      lResult  := '01';
    end if;

    return lResult;
  end checkFinalInvoicePreRequisite;

  /**
  * Description
  *    création d'un document de facture finale
  */
  procedure generateFinalInvoiceDocument(
    aInvoiceExpiryId in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aOnlyAmount      in     DOC_DOCUMENT.DMT_ONLY_AMOUNT_BILL_BOOK%type
  , aDateRef         in     date
  , aDateValue       in     date
  , aBalanceParent   in     number
  , aDocumentId      in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aErrorCode       out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  , aSimulation      in     number default 0
  )
  is
    vPositionId DOC_POSITION.DOC_POSITION_ID%type;
    vSqlErrm    varchar2(4000);
  begin
    -- !!! Astuce !! Pas de boucle, seulement l'échéance à traiter
    for tplInvoiceExpiry in (select INX.DOC_INVOICE_EXPIRY_ID
                                  , INX.DOC_DOCUMENT_ID
                                  , INX.DOC_GAUGE_ID
                                  , DMT.PAC_THIRD_ID
                                  , DMT.PC_LANG_ID
                                  , DMT.DMT_NUMBER
                                  , DMT.PAC_REPRESENTATIVE_ID
                                  , DMT.DMT_ONLY_AMOUNT_BILL_BOOK
                                  , INX.GCO_GOOD_ID
                                  , INX.INX_NET_VALUE_EXCL
                                  , INX.INX_RET_DEPOSIT_NET_EXCL
                                  , INX.PAC_PAYMENT_CONDITION_ID
                                  , INX.INX_DESCRIPTION
                                  , INX.INX_WORDING
                               from DOC_INVOICE_EXPIRY INX
                                  , DOC_DOCUMENT DMT
                              where INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                and DMT.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
                                and INX.INX_INVOICE_GENERATED = 0) loop
      if (aSimulation = 0) then
        -- création de l'entête du document
        generateBillBookDocumentHeader(aDocumentId
                                     , tplInvoiceExpiry.DOC_DOCUMENT_ID
                                     , tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                     , tplInvoiceExpiry.PAC_PAYMENT_CONDITION_ID
                                     , tplInvoiceExpiry.DOC_GAUGE_ID
                                     , tplInvoiceExpiry.PAC_THIRD_ID
                                     , tplInvoiceExpiry.PAC_REPRESENTATIVE_ID
                                     , '390'
                                     , aDateRef
                                     , nvl(aDateValue, trunc(sysdate) )
                                     , 1   -- copie des remises/taxes de pied
                                      );
        -- reset du numéro de position de la décharge
        DOC_COPY_DISCHARGE.SetLastPosNumber(0);
      end if;

      generateFinalInvoiceDocPos(aNewDocumentId      => aDocumentId
                               , aSourceDocumentId   => tplInvoiceExpiry.DOC_DOCUMENT_ID
                               , aGaugeId            => tplInvoiceExpiry.DOC_GAUGE_ID
                               , aInvoiceExpiryId    => tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                               , aWording            => tplInvoiceExpiry.INX_WORDING
                               , aDescription        => tplInvoiceExpiry.INX_DESCRIPTION
                               , aGoodId             => tplInvoiceExpiry.GCO_GOOD_ID
                               , aGoodPrice          => tplInvoiceExpiry.INX_NET_VALUE_EXCL
                               , aBalanceParent      => aBalanceParent
                               , aOnlyAmount         => aOnlyAmount
                               , aDateRef            => aDateRef
                               , aErrorCode          => aErrorCode
                               , aSimulation         => aSimulation
                                );
      exit when aErrorCode is not null;

      if (aSimulation = 0) then
        -- Finalisation du document
        DOC_FINALIZE.FinalizeDocument(aDocumentId);
        -- Maj du status du document échéancier
        DOC_PRC_DOCUMENT.UpdateDocumentStatus(tplInvoiceExpiry.DOC_DOCUMENT_ID);
      end if;

      if aSimulation = 0 then
        commit;   -- on conserve l'atomicité qu'on a dans le soft, c'est à dire qu'on Commit à chaque position
      end if;
    end loop;
  exception
    when others then
      if (aSimulation = 0) then
        vSqlErrm    := DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_call_stack;

        -- mise à jour du flag erreur ('erreur PLSQL lors de la génération du document')
        update DOC_INVOICE_EXPIRY
           set C_DOC_INVOICE_EXPIRY_ERROR = '050'
             , INX_ERROR_MESSAGE = vSqlErrm
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        aErrorCode  := '050';
        commit;
      end if;
  end generateFinalInvoiceDocument;

  /**
  * Description
  *    création d'un document de facture partielle (seule l'entête est créée)
  */
  procedure generatePartialInvoiceDocument(
    aInvoiceExpiryId in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aOnlyAmount      in     DOC_DOCUMENT.DMT_ONLY_AMOUNT_BILL_BOOK%type
  , aDateRef         in     date
  , aDateValue       in     date
  , aDocumentId      in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aErrorCode       out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  , aSimulation      in     number default 0
  )
  is
    vSqlErrm varchar2(4000);
  begin
    -- !!! Astuce !! Pas de boucle, seulement l'échéance à traiter
    for tplInvoiceExpiry in (select INX.DOC_INVOICE_EXPIRY_ID
                                  , INX.DOC_DOCUMENT_ID
                                  , INX.DOC_GAUGE_ID
                                  , DMT.PAC_THIRD_ID
                                  , DMT.PC_LANG_ID
                                  , DMT.DMT_NUMBER
                                  , DMT.PAC_REPRESENTATIVE_ID
                                  , INX.INX_DESCRIPTION
                                  , INX.INX_WORDING
                                  , INX.GCO_GOOD_ID
                                  , INX.INX_NET_VALUE_EXCL
                                  , INX.PAC_PAYMENT_CONDITION_ID
                                  , INX.INX_RET_DEPOSIT_NET_EXCL
                               from DOC_INVOICE_EXPIRY INX
                                  , DOC_DOCUMENT DMT
                              where INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                and DMT.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
                                and INX.INX_INVOICE_GENERATED = 0) loop
      if (aSimulation = 0) then
        -- création de l'entête du document
        generateBillBookDocumentHeader(aDocumentId
                                     , tplInvoiceExpiry.DOC_DOCUMENT_ID
                                     , tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                     , tplInvoiceExpiry.PAC_PAYMENT_CONDITION_ID
                                     , tplInvoiceExpiry.DOC_GAUGE_ID
                                     , tplInvoiceExpiry.PAC_THIRD_ID
                                     , tplInvoiceExpiry.PAC_REPRESENTATIVE_ID
                                     , '390'
                                     , aDateRef
                                     , nvl(aDateValue, trunc(sysdate) )
                                     , 1   -- copie des remises/taxes de pied
                                      );
        -- reset du numéro de position de la décharge
        DOC_COPY_DISCHARGE.SetLastPosNumber(0);
      end if;

      generatePartialInvoiceDocPos(aNewDocumentId      => aDocumentId
                                 , aSourceDocumentId   => tplInvoiceExpiry.DOC_DOCUMENT_ID
                                 , aGaugeId            => tplInvoiceExpiry.DOC_GAUGE_ID
                                 , aInvoiceExpiryId    => tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                 , aWording            => tplInvoiceExpiry.INX_WORDING
                                 , aDescription        => tplInvoiceExpiry.INX_DESCRIPTION
                                 , aGoodId             => tplInvoiceExpiry.GCO_GOOD_ID
                                 , aGoodPrice          => tplInvoiceExpiry.INX_NET_VALUE_EXCL
                                 , aRetDeposit         => tplInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL
                                 , aOnlyAmount         => aOnlyAmount
                                 , aDateRef            => aDateRef
                                 , aErrorCode          => aErrorCode
                                 , aSimulation         => aSimulation
                                  );
      exit when aErrorCode is not null;

      if (aSimulation = 0) then
        -- Finalisation du document
        DOC_FINALIZE.FinalizeDocument(aDocumentId);
        commit;   -- on conserve l'atomicité qu'on a dans le soft, c'est à dire qu'on Commit à chaque position
      end if;
    end loop;

    if (aSimulation = 0) then
      if    aDocumentId is null
         or aErrorCode is not null then
        -- mise à jour du flag erreur ('document déjà généré')
        update DOC_INVOICE_EXPIRY
           set C_DOC_INVOICE_EXPIRY_ERROR = nvl(aErrorCode, '010')
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        if aSimulation = 0 then
          commit;   -- on conserve l'atomicité qu'on a dans le soft, c'est à dire qu'on Commit à chaque position
        end if;
      end if;
    end if;
  exception
    when others then
      if (aSimulation = 0) then
        vSqlErrm    := DBMS_UTILITY.format_error_stack || DBMS_UTILITY.format_call_stack;

        -- mise à jour du flag erreur ('erreur PLSQL lors de la génération du document')
        update DOC_INVOICE_EXPIRY
           set C_DOC_INVOICE_EXPIRY_ERROR = '050'
             , INX_ERROR_MESSAGE = vSqlErrm
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        aErrorCode  := '050';
        commit;
      end if;
  end generatePartialInvoiceDocument;

  /**
  * procedure checkDocumentDate
  * Description
  *
  * @created fp 09.09.2011
  * @lastUpdate
  * @public
  * @param
  */
  procedure checkDocumentDate(
    iGaugeId      in     DOC_GAUGE.DOC_GAUGE_ID%type
  , iDateRef      in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , oErrorCode    out    varchar2
  , oErrorMessage out    varchar2
  )
  is
    lConfirmFail varchar2(1000);
    lCtrlOK      pls_integer;
  begin
    -- Contrôle de la date excepté en mode "Conctrôle uniquement à la confirmation"
    for ltplGauge in (select C_CONTROLE_DATE_DOCUM
                        from DOC_GAUGE_STRUCTURED
                       where DOC_GAUGE_ID = iGaugeId
                         and C_START_CONTROL_DATE in('1', '3') ) loop
      DOC_DOCUMENT_FUNCTIONS.ValidateDocumentDate(iDateRef, ltplGauge.C_CONTROLE_DATE_DOCUM, oErrorCode, oErrorMessage, lConfirmFail, lCtrlOK);

      if oErrorCode is not null then
        oErrorCode  := '011';
      end if;
    end loop;
  end checkDocumentDate;

  /**
  * Description
  *    création d'un document d'échéancier
  */
  procedure generateInvoiceDocument(
    aInvoiceExpiryId in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aDateRef         in     date default null
  , aDateValue       in     date default null
  , aBalanceParent   in     number default 0
  , aDocumentId      in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aCheckAmount     in     number default 0
  , aSimulation      in     number default 0
  )
  is
    vDateRef      date;
    vErrorCode    varchar2(100);
    vErrorMessage varchar2(1000);
  begin
    vDateRef  := trunc(sysdate);

    -- si on a un problème de parité avec les montants de l'échéancier et le document source et qu'on a demandé le contrôle, on ne génère pas le document
    if    aCheckAmount = 0
       or (checkDocumentBillBookAmount(GetInvoiceExpiryFatherDocId(aInvoiceExpiryId) ) = 0) then
      for tplInvoiceExpiry in (select INX.INX_INVOICE_GENERATED
                                    , INX.C_INVOICE_EXPIRY_DOC_TYPE
                                    , INX_VALUE_DATE
                                    , INX_ISSUING_DATE
                                    , INX_SLICE
                                    , INX.DOC_GAUGE_ID
                                    , nvl(DMT.DMT_ONLY_AMOUNT_BILL_BOOK, 0) DMT_ONLY_AMOUNT_BILL_BOOK
                                    , DMT_NUMBER
                                    , DMT.DOC_DOCUMENT_ID
                                    , DMT.GAL_CURRENCY_RISK_VIRTUAL_ID
                                    , PCS.PC_I_LIB_SESSION.getComName COM_NAME
                                 from DOC_INVOICE_EXPIRY INX
                                    , DOC_DOCUMENT DMT
                                where INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                  and DMT.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID) loop
        -- Check expiry parity before creating the document
        checkInvoiceExpiryPolicy(aInvoiceExpiryId
                               , tplInvoiceExpiry.DMT_ONLY_AMOUNT_BILL_BOOK
                               , tplInvoiceExpiry.DMT_NUMBER
                               , 1   -- Generation context
                               , vErrorMessage
                                );

        if vErrormessage is not null then
          if aSimulation = 1 then
            LogDocumentError(tplInvoiceExpiry.DMT_NUMBER, vErrormessage);
          else
            ra(vErrorMessage, null, -20999);
          end if;
        else
          begin
            checkDocumentDate(tplInvoiceExpiry.DOC_GAUGE_ID, vDateRef, vErrorCode, vErrorMessage);

            if     (vErrormessage is not null)
               and (aSimulation = 1) then
              LogDocumentError(tplInvoiceExpiry.DMT_NUMBER, vErrormessage);
            end if;

            if vErrorMessage is null then
              case
                -- Accomptes
              when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '1' then
                  generateDepositDocument(aInvoiceExpiryId   => aInvoiceExpiryId
                                        , aDateRef           => vDateRef
                                        , aDatevalue         => vDateRef
                                        , aDocumentId        => aDocumentId
                                        , aErrorCode         => vErrorCode
                                        , aSimulation        => aSimulation
                                         );
                -- Facture partielle
              when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '2' then
                  generatePartialInvoiceDocument(aInvoiceExpiryId   => aInvoiceExpiryId
                                               , aOnlyAmount        => tplInvoiceExpiry.DMT_ONLY_AMOUNT_BILL_BOOK
                                               , aDateRef           => vDateRef
                                               , aDatevalue         => vDateRef
                                               , aDocumentId        => aDocumentId
                                               , aErrorCode         => vErrorCode
                                               , aSimulation        => aSimulation
                                                );
                -- Facture finale
              when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '3' then
                  generateFinalInvoiceDocument(aInvoiceExpiryId   => aInvoiceExpiryId
                                             , aOnlyAmount        => tplInvoiceExpiry.DMT_ONLY_AMOUNT_BILL_BOOK
                                             , aDateRef           => vDateRef
                                             , aDatevalue         => vDateRef
                                             , aBalanceParent     => aBalanceParent
                                             , aDocumentId        => aDocumentId
                                             , aErrorCode         => vErrorCode
                                             , aSimulation        => aSimulation
                                              );
                -- Note de crédit sur facture
              when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '4' then
                  generateDepositDocument(aInvoiceExpiryId   => aInvoiceExpiryId
                                        , aDateRef           => vDateRef
                                        , aDatevalue         => vDateRef
                                        , aDocumentId        => aDocumentId
                                        , aErrorCode         => vErrorCode
                                        , aSimulation        => aSimulation
                                         );
                -- NC sur acompte
              when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '5' then
                  generateDepositDocument(aInvoiceExpiryId   => aInvoiceExpiryId
                                        , aDateRef           => vDateRef
                                        , aDatevalue         => vDateRef
                                        , aDocumentId        => aDocumentId
                                        , aErrorCode         => vErrorCode
                                        , aSimulation        => aSimulation
                                         );
                -- NC sur global
              when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '6' then
                  generateDepositDocument(aInvoiceExpiryId   => aInvoiceExpiryId
                                        , aDateRef           => vDateRef
                                        , aDatevalue         => vDateRef
                                        , aDocumentId        => aDocumentId
                                        , aErrorCode         => vErrorCode
                                        , aSimulation        => aSimulation
                                         );
              end case;

              if     (vErrorCode is not null)
                 and (aSimulation = 1) then
                LogDocumentError(tplInvoiceExpiry.DMT_NUMBER, PCS.PC_FUNCTIONS.GetDescodeDescr('C_DOC_INVOICE_EXPIRY_ERROR', vErrorCode) );
              end if;

              -- Uniquement pour les factures finales, si on le demande et qu'il n'y a pas d'erreur, on solde le document porteur de l'échéancier
              -- le mode 2 est qu'on ne solde le document que s'il n'eat pas déchargé partiellement
              if     (vErrorCode is null)
                 and tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '3' then
                if    (aBalanceParent = 1)
                   or (     (aBalanceParent = 2)
                       and FWK_I_LIB_ENTITY.getvarchar2fieldfrompk('DOC_DOCUMENT', 'C_DOCUMENT_STATUS', tplInvoiceExpiry.DOC_DOCUMENT_ID) = '02'
                      ) then
                  DOC_DOCUMENT_FUNCTIONS.balanceDocument(aDocumentId => tplInvoiceExpiry.DOC_DOCUMENT_ID);
                end if;
              end if;

              -- si le document gère les risques de change, on mets à jour le montant solde du parent
              if     aSimulation = 0
                 and tplInvoiceExpiry.GAL_CURRENCY_RISK_VIRTUAL_ID is not null then
                -- mise à jour des montant de risque de change
                DOC_FUNCTIONS.UpdateBalanceTotal(tplInvoiceExpiry.DOC_DOCUMENT_ID);
              end if;

              if aSimulation = 0 then
                commit;   -- conserve l'atomicité qu'on a dans le soft
              end if;
            -- Date du jour pas OK par rapport au controle de date
            else
              if aSimulation = 0 then
                -- mise à jour du flag "Document d'échéancier généré"
                update DOC_INVOICE_EXPIRY
                   set INX_INVOICING_DATE = decode(vErrorCode, null, vDateRef, null)
                     , C_DOC_INVOICE_EXPIRY_ERROR = vErrorCode
                     , INX_INVOICE_GENERATED = decode(vErrorCode, null, 1, 0)
                 where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;
              end if;
            end if;
          exception
            when others then
              if     (vErrorCode is not null)
                 and (aSimulation = 1) then
                LogDocumentError(tplInvoiceExpiry.DMT_NUMBER, PCS.PC_FUNCTIONS.GetDescodeDescr('C_DOC_INVOICE_EXPIRY_ERROR', vErrorCode) );
              else
                ra
                  (replace
                     (replace
                        (replace
                           (PCS.PC_FUNCTIONS.translateWord
                              ('Erreur lors de la génération du document depuis l''échéance "[INX_SLICE]" du document "[DMT_NUMBER]" dans la société "[COM_NAME]". Détail :'
                              )
                          , '[COM_NAME]'
                          , tplInvoiceExpiry.COM_NAME
                           )
                       , '[INX_SLICE]'
                       , tplInvoiceExpiry.INX_SLICE
                        )
                    , '[DMT_NUMBER]'
                    , tplInvoiceExpiry.DMT_NUMBER
                     ) ||
                   chr(10) ||
                   sqlerrm ||
                   chr(10) ||
                   DBMS_UTILITY.format_error_stack
                 , null
                 , -20900
                  );
              end if;
          end;
        end if;
      end loop;
    end if;

    if (aSimulation = 0) then
      -- supression du document en cas d'erreur
      if vErrorCode is not null then
        DOC_DOCUMENT_FUNCTIONS.DocumentProtect(aDocumentId, 0);
        DOC_DELETE.DeleteDocument(aDocumentId, 0);
        aDocumentId  := null;
        commit;
      end if;
    else
      aDocumentId  := -1;
    end if;
  end generateInvoiceDocument;

  function pControlRegroupDocAmount(
    aInvoiceExpiryDocType in DOC_INVOICE_EXPIRY.C_INVOICE_EXPIRY_DOC_TYPE%type
  , aGaugeId              in DOC_INVOICE_EXPIRY.DOC_GAUGE_ID%type
  , aThirdId              in DOC_DOCUMENT.PAC_THIRD_ID%type
  , aPaymentConditionId   in DOC_INVOICE_EXPIRY.PAC_PAYMENT_CONDITION_ID%type
  )
    return boolean
  is
  begin
    for ltplInvoiceExpiry in (select distinct INX.DOC_DOCUMENT_ID
                                            , DMT.DMT_NUMBER
                                         from DOC_INVOICE_EXPIRY INX
                                            , DOC_DOCUMENT DMT
                                            , COM_LIST_ID_TEMP LID
                                        where INX.C_INVOICE_EXPIRY_DOC_TYPE = aInvoiceExpiryDocType
                                          and LID_CODE = 'DOC_BILL_BOOK_SELECTION'
                                          and LID_FREE_NUMBER_1 = 1
                                          and COM_LIST_ID_TEMP_ID = INX.DOC_INVOICE_EXPIRY_ID
                                          and DMT.PAC_THIRD_ID = aThirdId
                                          and INX.PAC_PAYMENT_CONDITION_ID = aPaymentConditionId
                                          and INX.DOC_GAUGE_ID = aGaugeId
                                     order by DMT.DMT_NUMBER) loop
      -- à la moindre différence entre le total document source et le total échéancier, on retourne une erreur
      if checkDocumentBillBookAmount(ltplInvoiceExpiry.DOC_DOCUMENT_ID) <> 0 then
        return false;
      end if;
    end loop;

    -- si le contrôle s'est bien passé on retourne OK
    return true;
  end pControlRegroupDocAmount;

  /**
  * Description
  *    création d'un document par regroupement d'échéanciers
  */
  procedure generateInvoiceDocumentRegroup(
    aInvoiceExpiryDocType in     DOC_INVOICE_EXPIRY.C_INVOICE_EXPIRY_DOC_TYPE%type
  , aGaugeId              in     DOC_INVOICE_EXPIRY.DOC_GAUGE_ID%type
  , aThirdId              in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , aPaymentConditionId   in     DOC_INVOICE_EXPIRY.PAC_PAYMENT_CONDITION_ID%type
  , aDateRef              in     date
  , aDateValue            in     date
  , aCheckAmount          in     number default 1
  , aBalanceParent        in     number default 0
  , aDocumentId           out    DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
  is
    vDateRef   date;
    vErrorCode DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type;
    vFirst     boolean                                              := true;
  begin
    -- Normaly aDateRef and aDateValue are null -> DEVLOG-15611
    -- si on a un problème de parité avec les montants de l'échéancier le total document pour au moins un document source,
    -- et qu'on a demandé le contrôle, on ne génère pas le document
    if    aCheckAmount = 0
       or pControlRegroupDocAmount(aInvoiceExpiryDocType, aGaugeId, aThirdId, aPaymentConditionId) then
      for tplInvoiceExpiry in (select   INX.DOC_INVOICE_EXPIRY_ID
                                      , INX.DOC_GAUGE_ID
                                      , INX.INX_INVOICE_GENERATED
                                      , INX.C_INVOICE_EXPIRY_DOC_TYPE
                                      , INX.INX_WORDING
                                      , INX.INX_DESCRIPTION
                                      , DMT.DMT_ONLY_AMOUNT_BILL_BOOK
                                      , DMT.DOC_DOCUMENT_ID
                                      , INX.GCO_GOOD_ID
                                      , INX.INX_NET_VALUE_EXCL
                                      , INX.INX_RET_DEPOSIT_NET_EXCL
                                      , DMT.DMT_NUMBER
                                      , DMT.PC_LANG_ID
                                   from DOC_INVOICE_EXPIRY INX
                                      , DOC_DOCUMENT DMT
                                      , COM_LIST_ID_TEMP LID
                                  where INX.C_INVOICE_EXPIRY_DOC_TYPE = aInvoiceExpiryDocType
                                    and DMT.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
                                    and LID_CODE = 'DOC_BILL_BOOK_SELECTION'
                                    and LID_FREE_NUMBER_1 = 1
                                    and COM_LIST_ID_TEMP_ID = INX.DOC_INVOICE_EXPIRY_ID
                                    and DMT.PAC_THIRD_ID = aThirdId
                                    and INX.PAC_PAYMENT_CONDITION_ID = aPaymentConditionId
                                    and INX.DOC_GAUGE_ID = aGaugeId
                               order by DMT_NUMBER) loop
        declare
          vTextPositionId DOC_POSITION.DOC_POSITION_ID%type;
        begin
          if vFirst then
            -- création de l'entête du document
            generateBillBookDocumentHeader(aDocumentId
                                         , tplInvoiceExpiry.DOC_DOCUMENT_ID
                                         , null   --DOC_INVOICE_EXPIRY_ID
                                         , aPaymentConditionId
                                         , aGaugeId
                                         , aThirdId
                                         , null   -- pas de reprise du représentant en mode regroupement
                                         , '390'
                                         , vDateRef
                                         , vDateRef
                                         , 0   -- pas de copie des remises/taxes de pied, elle seront reprise une à une pour chaque document
                                          );
            vFirst  := false;
          end if;

          -- Initialisation des données de la position que l'on va créer
          Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
          Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO  := 0;
          Doc_Position_Initialize.PositionInfo.USE_POS_BODY_TEXT    := 1;
          Doc_Position_Initialize.PositionInfo.POS_BODY_TEXT        :=
                         replace(PCS.PC_FUNCTIONS.TranslateWord('Selon [DMT_NUMBER]', tplInvoiceExpiry.PC_LANG_ID), '[DMT_NUMBER]', tplInvoiceExpiry.DMT_NUMBER);
          -- création d'une position de document
          Doc_Position_Generate.GeneratePosition(aPositionID       => vTextPositionID
                                               , aDocumentID       => aDocumentID
                                               , aPosCreateMode    => '190'
                                               , aPosCreateType    => 'INSERT'
                                               , aTypePos          => '4'
                                               , aGenerateDetail   => 1
                                                );

          if tplInvoiceExpiry.INX_INVOICE_GENERATED = 0 then
            case
              -- Accomptes et notes de crédit
            when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('1', '4', '5', '6') then
                generateDepositDocumentPos(aNewDocumentId      => aDocumentId
                                         , aSourceDocumentId   => tplInvoiceExpiry.DOC_DOCUMENT_ID
                                         , aInvoiceExpiryId    => tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                         , aWording            => tplInvoiceExpiry.INX_WORDING
                                         , aDescription        => tplInvoiceExpiry.INX_DESCRIPTION
                                         , aGoodId             => tplInvoiceExpiry.GCO_GOOD_ID
                                         , aGoodPrice          => tplInvoiceExpiry.INX_NET_VALUE_EXCL
                                         , aDateRef            => vDateRef
                                         , aErrorCode          => vErrorCode
                                          );
              -- Facture partielle
            when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '2' then
                generatePartialInvoiceDocPos(aNewDocumentId      => aDocumentID
                                           , aSourceDocumentId   => tplInvoiceExpiry.DOC_DOCUMENT_ID
                                           , aGaugeId            => tplInvoiceExpiry.DOC_GAUGE_ID
                                           , aInvoiceExpiryId    => tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                           , aWording            => tplInvoiceExpiry.INX_WORDING
                                           , aDescription        => tplInvoiceExpiry.INX_DESCRIPTION
                                           , aGoodId             => tplInvoiceExpiry.GCO_GOOD_ID
                                           , aGoodPrice          => tplInvoiceExpiry.INX_NET_VALUE_EXCL
                                           , aRetDeposit         => tplInvoiceExpiry.INX_RET_DEPOSIT_NET_EXCL
                                           , aOnlyAmount         => tplInvoiceExpiry.DMT_ONLY_AMOUNT_BILL_BOOK
                                           , aDateRef            => vDateRef
                                           , aErrorCode          => vErrorCode
                                            );
                DOC_DISCOUNT_CHARGE.DuplicateFootCharge(tplInvoiceExpiry.DOC_DOCUMENT_ID, aDocumentID, 1   -- gèle les remises/taxes de pied
                                                                                                        );
              -- Facture finale
            when tplInvoiceExpiry.C_INVOICE_EXPIRY_DOC_TYPE = '3' then
                generateFinalInvoiceDocPos(aNewDocumentId      => aDocumentID
                                         , aSourceDocumentId   => tplInvoiceExpiry.DOC_DOCUMENT_ID
                                         , aInvoiceExpiryId    => tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                                         , aWording            => tplInvoiceExpiry.INX_WORDING
                                         , aDescription        => tplInvoiceExpiry.INX_DESCRIPTION
                                         , aGoodId             => tplInvoiceExpiry.GCO_GOOD_ID
                                         , aGoodPrice          => tplInvoiceExpiry.INX_NET_VALUE_EXCL
                                         , aBalanceParent      => aBalanceParent
                                         , aOnlyAmount         => tplInvoiceExpiry.DMT_ONLY_AMOUNT_BILL_BOOK
                                         , aDateRef            => vDateRef
                                         , aErrorCode          => vErrorCode
                                          );
                DOC_DISCOUNT_CHARGE.DuplicateFootCharge(tplInvoiceExpiry.DOC_DOCUMENT_ID, aDocumentID, 1   -- gèle les remises/taxes de pied
                                                                                                        );
            end case;

            DOC_PRC_DOCUMENT.UpdateDocumentStatus(tplInvoiceExpiry.DOC_DOCUMENT_ID);
          end if;
        end;
      end loop;

      -- supression du document en cas d'erreur
      if vErrorCode is not null then
        DOC_DOCUMENT_FUNCTIONS.DocumentProtect(aDocumentId, 0);
        DOC_DELETE.DeleteDocument(aDocumentId, 0);
        aDocumentId  := null;
      else
        -- Finalisation du document
        DOC_FINALIZE.FinalizeDocument(aDocumentId);
      end if;
    end if;

    commit;
  end generateInvoiceDocumentRegroup;

  /**
  * Description
  *   Génère la simulation des échéances jusqu'à une date donnée
  */
  procedure simulateCashAtDate(
    vComName            in PCS.PC_COMP.COM_NAME%type
  , vCashFlowComName    in PCS.PC_COMP.COM_NAME%type
  , iCashFlowAnalysisId in ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
  , dDateRef            in date
  )
  is
    vDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    gCashFlowAnalysisId  := iCashFlowAnalysisId;
    gCashFlowSelComName  := vComName;

    delete from DOC_ESTIMATED_POS_CASH_FLOW;

    delete from DOC_EST_POS_IMP_CASH_FLOW;

    --Prise en compte des document dont la cible est la société de la trésorerie
    for tplInvoice2Simulate in (select   INX.DOC_INVOICE_EXPIRY_ID
                                       , INX.INX_ISSUING_DATE
                                       , INX.DOC_DOCUMENT_ID
                                       , INX.INX_SLICE
                                    from DOC_INVOICE_EXPIRY INX
                                       , DOC_DOCUMENT DOC
                                   where INX.INX_ISSUING_DATE <= dDateRef
                                     and INX.INX_INVOICE_GENERATED = 0
                                     and DOC.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
                                     and (    (DOC.COM_NAME_ACI = vCashFlowComName)
                                          or (     (DOC.COM_NAME_ACI is null)
                                              and (vCashFlowComName = vComName) ) )
                                order by INX_ISSUING_DATE
                                       , decode(C_INVOICE_EXPIRY_DOC_TYPE, '4', '3', '3', '4', '1')
                                       , INX_SLICE
                                       , DOC_INVOICE_EXPIRY_ID) loop
      vDocumentId  := -1;
      vDocumentId  := tplInvoice2Simulate.DOC_INVOICE_EXPIRY_ID;
      generateInvoiceDocument(aInvoiceExpiryId   => tplInvoice2Simulate.DOC_INVOICE_EXPIRY_ID
                            , aDateRef           => tplInvoice2Simulate.INX_ISSUING_DATE
                            , aDateValue         => tplInvoice2Simulate.INX_ISSUING_DATE
                            , aDocumentId        => vDocumentid
                            , aSimulation        => 1
                             );
    end loop;

    gCashFlowAnalysisId  := null;
    gCashFlowSelComName  := null;
  end simulateCashAtDate;

  /**
  * Description
  *    retourne le montant de reprise d'acompte en fonction de la quantité du détail
  */
  function getRetDepositAmount(
    aQuantity   in DOC_INVOICE_EXPIRY_DETAIL.IED_DISCHARGE_QUANTITY%type
  , aPositionId in DOC_POSITION.DOC_POSITION_ID%type
  , aMode       in pls_integer default 0
  )
    return DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type
  is
    vLinkedResult DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type;
    vGlobalResult DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type;
  begin
    -- somme à reprendre des accomptes liés
    select nvl(decode(avg(POS.POS_FINAL_QUANTITY)
                    , 0, 0
                    , sum(nvl(decode(INX.C_INVOICE_EXPIRY_DOC_TYPE, '1', IED.IED_NET_VALUE_EXCL, '5', -IED.IED_NET_VALUE_EXCL), 0) ) *
                      aQuantity /
                      avg(POS.POS_FINAL_QUANTITY)
                     )
             , 0
              )
      into vLinkedResult
      from DOC_INVOICE_EXPIRY_DETAIL IED
         , DOC_POSITION POS
         , DOC_INVOICE_EXPIRY INX
     where POS.DOC_POSITION_ID = aPositionId
       and IED.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
       and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '5');

    -- somme à reprendre des accomptes globaux
    select nvl(decode(avg(POS.POS_FINAL_QUANTITY)
                    , 0, 0
                    , sum(nvl(decode(INX.C_INVOICE_EXPIRY_DOC_TYPE, '1', INX.INX_NET_VALUE_EXCL, '5', -INX.INX_NET_VALUE_EXCL), 0) * aQuantity) *
                      (avg(POS_NET_VALUE_EXCL /(POS_FINAL_QUANTITY *(FOO.FOO_DOCUMENT_TOTAL_AMOUNT - FOO.FOO_TOTAL_VAT_AMOUNT) ) )
                      )
                     )
             , 0
              )
      into vGlobalResult
      from DOC_POSITION POS
         , DOC_FOOT FOO
         , DOC_INVOICE_EXPIRY INX
     where POS.DOC_POSITION_ID = aPositionId
       and FOO.DOC_FOOT_ID = POS.DOC_DOCUMENT_ID
       and INX.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '5')
       and not exists(select DOC_INVOICE_EXPIRY_DETAIL_ID
                        from DOC_INVOICE_EXPIRY_DETAIL
                       where DOC_INVOICE_EXPIRY_Id = INX.DOC_INVOICE_EXPIRY_ID);

    case
      when aMode = 0 then
        return vLinkedResult + vGlobalResult;
      when aMode = 1 then
        return vLinkedResult;
      when aMode = 2 then
        return vGlobalResult;
    end case;
  end getRetDepositAmount;

  /**
  * Description
  *    retourne le montant de reprise d'acompte en fonction de la quantité du détail
  */
  function getRetDepositOnlyAmount(
    aAmount          in DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type
  , aPositionId      in DOC_POSITION.DOC_POSITION_ID%type
  , aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  )
    return DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type
  is
    vLinkedResult DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type;
    vGlobalResult DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type;
  begin
    -- somme à reprendre des accomptes liés
    select nvl(decode(avg(POS.POS_FINAL_QUANTITY)
                    , 0, 0
                    , sum(nvl(decode(INX.C_INVOICE_EXPIRY_DOC_TYPE, '1', IED.IED_NET_VALUE_EXCL, '5', -IED.IED_NET_VALUE_EXCL), 0) * aAmount) /
                      avg(POS.POS_NET_VALUE_EXCL)
                     )
             , 0
              )
      into vLinkedResult
      from DOC_INVOICE_EXPIRY_DETAIL IED
         , DOC_POSITION POS
         , DOC_INVOICE_EXPIRY INX
     where POS.DOC_POSITION_ID = aPositionId
       and IED.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
       and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '5');

    -- somme à reprendre des accomptes globaux
    select nvl(decode(avg(FOO.FOO_GOOD_TOT_AMOUNT_EXCL)
                    , 0, 0
                    , sum(nvl(decode(INX.C_INVOICE_EXPIRY_DOC_TYPE, '1', INX.INX_NET_VALUE_EXCL, '5', -INX.INX_NET_VALUE_EXCL), 0) * aAmount) /
                      avg(FOO_DOCUMENT_TOTAL_AMOUNT - FOO.FOO_TOTAL_VAT_AMOUNT)
                     )
             , 0
              )
      into vGlobalResult
      from DOC_POSITION POS
         , DOC_FOOT FOO
         , DOC_INVOICE_EXPIRY INX
     where POS.DOC_POSITION_ID = aPositionId
       and FOO.DOC_FOOT_ID = POS.DOC_DOCUMENT_ID
       and INX.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '5')
       and not exists(select DOC_INVOICE_EXPIRY_DETAIL_ID
                        from DOC_INVOICE_EXPIRY_DETAIL
                       where DOC_INVOICE_EXPIRY_Id = INX.DOC_INVOICE_EXPIRY_ID);

    return RoundInvoiceAmount(vLinkedResult + vGlobalResult, aInvoiceExpiryId);
  end getRetDepositOnlyAmount;

  /**
  * Description
  *    Recherche des montants déjà déchargés en mode "Montant"
  */
  function getPosDischargedAmount(aPositionId in DOC_POSITION.DOC_POSITION_ID%type, aSimulation in number default 0)
    return DOC_POSITION.POS_GROSS_VALUE%type
  is
    vResult DOC_POSITION.POS_GROSS_VALUE%type;
  begin
    if aSimulation = 0 then
      select nvl(sum(nvl(POS_GROSS_VALUE, 0) ), 0)
        into vResult
        from DOC_POSITION POS
           , DOC_INVOICE_EXPIRY_DETAIL IED
           , DOC_INVOICE_EXPIRY INX
       where IED.DOC_POSITION_ID = aPositionId
         and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
         and INX.C_INVOICE_EXPIRY_DOC_TYPE = '2'
         and POS.DOC_INVOICE_EXPIRY_DETAIL_ID = IED.DOC_INVOICE_EXPIRY_DETAIL_ID
         and POS.C_DOC_POS_STATUS <> '05';
    else
      select nvl(sum(nvl(POS_GROSS_VALUE, 0) ), 0)
        into vResult
        from DOC_ESTIMATED_POS_CASH_FLOW POS
           , DOC_INVOICE_EXPIRY_DETAIL IED
           , DOC_INVOICE_EXPIRY INX
       where IED.DOC_POSITION_ID = aPositionId
         and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
         and INX.C_INVOICE_EXPIRY_DOC_TYPE = '2'
         and POS.DOC_INVOICE_EXPIRY_DETAIL_ID = IED.DOC_INVOICE_EXPIRY_DETAIL_ID;
    end if;

    return vResult;
  end getPosDischargedAmount;

  /**
  * Description
  *    retourne le montant de reprise d'acompte en fonction de la quantité du détail
  */
  function getGlobalRetDepositAmount(
    aAmount          in DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type
  , aDocumentId      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  )
    return DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type
  is
    vResult DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type   := 0;
  begin
    -- Si pas de détails
    if    aInvoiceExpiryId is null
       or pIsDetail(aInvoiceExpiryId) = 0 then
      -- somme à reprendre des accomptes globaux
      select nvl(decode(avg(FOO.FOO_DOCUMENT_TOTAL_AMOUNT - FOO.FOO_TOTAL_VAT_AMOUNT)
                      , 0, 0
                      , sum(nvl(decode(INX.C_INVOICE_EXPIRY_DOC_TYPE, '1', INX.INX_NET_VALUE_EXCL, '5', -INX.INX_NET_VALUE_EXCL), 0) * aAmount) /
                        avg(FOO.FOO_DOCUMENT_TOTAL_AMOUNT - FOO.FOO_TOTAL_VAT_AMOUNT)
                       )
               , 0
                )
        into vResult
        from DOC_INVOICE_EXPIRY INX
           , DOC_FOOT FOO
       where INX.DOC_DOCUMENT_ID = aDocumentId
         and FOO.DOC_FOOT_ID = INX.DOC_DOCUMENT_ID
         and INX.C_INVOICE_EXPIRY_DOC_TYPE in('1', '5')
         and not exists(select DOC_INVOICE_EXPIRY_DETAIL_ID
                          from DOC_INVOICE_EXPIRY_DETAIL
                         where DOC_INVOICE_EXPIRY_Id = INX.DOC_INVOICE_EXPIRY_ID);
    else
      for tplInvoiceDetail in (select *
                                 from DOC_INVOICE_EXPIRY_DETAIL
                                where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId) loop
        declare
          vDetRetAmount DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type;
        begin
          if not IsDocumentOnlyAmountBillBook(aDocumentId) then
            vDetRetAmount  := getRetDepositAmount(tplInvoiceDetail.IED_DISCHARGE_QUANTITY, tplInvoiceDetail.DOC_POSITION_ID);
          else
            vDetRetAmount  := getRetDepositOnlyAmount(tplInvoiceDetail.IED_NET_VALUE_EXCL, tplInvoiceDetail.DOC_POSITION_ID, aInvoiceExpiryId);
          end if;

          update DOC_INVOICE_EXPIRY_DETAIL
             set IED_RET_DEPOSIT_NET_EXCL = vDetRetAmount
           where DOC_INVOICE_EXPIRY_DETAIL_ID = tplInvoiceDetail.DOC_INVOICE_EXPIRY_DETAIL_ID;

          vResult  := vResult + nvl(vDetRetAmount, 0);
        end;
      end loop;
    end if;

    return vResult;
  end getGlobalRetDepositAmount;

  /**
  * Description
  *    vérifie si le total de l'échéancier correspond bien à la valeur nette HT du document
  */
  function checkDocumentBillBookAmount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type
  is
    vDocNetTotalAmountExcl   DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type   := 0;
    vDocNetTotalAmountExcl_b DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type   := 0;
    vExpNetTotalAmount       DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type   := 0;
    vExpNetTotalAmount_b     DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type   := 0;
    vInvoiceExpiry           number(1);
  begin
    -- recherche du total des proportions
    select FOO_GOOD_TOT_AMOUNT_EXCL
         , FOO_GOOD_TOT_AMOUNT_EX_B
         , DMT_INVOICE_EXPIRY
      into vDocNetTotalAmountExcl
         , vDocNetTotalAmountExcl_b
         , vInvoiceExpiry
      from DOC_FOOT FOO
         , DOC_DOCUMENT DMT
     where FOO.DOC_FOOT_ID = aDocumentId
       and DMT.DOC_DOCUMENT_ID = FOO.DOC_FOOT_ID;

    -- Contrôle seulement si le document est lié à un échéancier
    if vInvoiceExpiry = 1 then
      select sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '4', -INX_NET_VALUE_EXCL, '5', -INX_NET_VALUE_EXCL, '6', 0, INX_NET_VALUE_EXCL) -
                 nvl(INX_RET_DEPOSIT_NET_EXCL, 0)
                )
           , sum(decode(C_INVOICE_EXPIRY_DOC_TYPE, '4', -INX_NET_VALUE_EXCL_B, '5', -INX_NET_VALUE_EXCL_B, '6', 0, INX_NET_VALUE_EXCL_B) -
                 nvl(INX_RET_DEPOSIT_NET_EXCL_B, 0)
                )
        into vExpNetTotalAmount
           , vExpNetTotalAmount_b
        from DOC_INVOICE_EXPIRY
       where DOC_DOCUMENT_ID = aDocumentId;

      return vDocNetTotalAmountExcl - vExpNetTotalAmount;
    else
      return 0;
    end if;
  end checkDocumentBillBookAmount;

  /**
  * Description
  *    Check one invoice expiry policies
  */
  procedure checkInvoiceExpiryPolicy(
    aInvoiceExpiryId in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aOnlyAmount      in     DOC_DOCUMENT.DMT_ONLY_AMOUNT_BILL_BOOK%type
  , aDocNumber       in     DOC_DOCUMENT.DMT_NUMBER%type default null
  , aGenerationMode  in     number default 0
  , aErrorMessage    out    varchar2
  )
  is
    vComName PCS.PC_COMP.COM_NAME%type   := PCS.PC_I_LIB_SESSION.getComName;
  begin
    for tplInvoice in (select *
                         from DOC_INVOICE_EXPIRY
                        where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId) loop
      -- Vérifie que l'échéance n'ait pas déjà été générée
      if     aGenerationMode = 1
         and tplInvoice.INX_INVOICE_GENERATED = 1 then
        if aDocNumber is null then
          aErrorMessage  := replace(PCS.PC_FUNCTIONS.TranslateWord('L''échéance "[INX_SLICE]" a déjà été générée.'), '[INX_SLICE]', tplInvoice.INX_SLICE);
        else
          aErrorMessage  :=
            replace(replace(PCS.PC_FUNCTIONS.TranslateWord('L''échéance "[INX_SLICE]" du document "[DMT_NUMBER]" a déjà été générée.')
                          , '[INX_SLICE]'
                          , tplInvoice.INX_SLICE
                           )
                  , '[DMT_NUMBER]'
                  , aDocNumber
                   );
        end if;
      -- Vérifie que les accomptes ou les échéances d'un échéancier sans décharge possèdent un bien
      elsif     (   tplInvoice.C_INVOICE_EXPIRY_DOC_TYPE = '1'
                 or aOnlyAmount = 1)
            and tplInvoice.GCO_GOOD_ID is null then
        if aDocNumber is null then
          aErrorMessage  := replace(PCS.PC_FUNCTIONS.TranslateWord('L''échéance "[INX_SLICE]" ne contient pas de bien.'), '[INX_SLICE]', tplInvoice.INX_SLICE);
        else
          aErrorMessage  :=
            replace
              (replace
                 (replace
                    (PCS.PC_FUNCTIONS.TranslateWord('L''échéance "[INX_SLICE]" du document "[DMT_NUMBER]" de la société "[COM_NAME]" ne contient pas de bien.')
                   , '[INX_SLICE]'
                   , tplInvoice.INX_SLICE
                    )
                , '[COM_NAME]'
                , vComName
                 )
             , '[DMT_NUMBER]'
             , aDocNumber
              );
        end if;
      -- Vérifie que les biens utilisés pour les accomptes soient gérés avec 4 décimales
      elsif tplInvoice.C_INVOICE_EXPIRY_DOC_TYPE = '1' then
        -- le bien lié doit impérativement être géré avec 4 décimales, sinon les décharges ne se feront pas proportionnelement
        if GCO_LIB_FUNCTIONS.GetNumberOfDecimal(tplInvoice.GCO_GOOD_ID) <> 4 then
          aErrorMessage  :=
            replace
              (replace
                 (replace
                    (replace
                       (replace
                          (PCS.PC_FUNCTIONS.TranslateWord
                             ('Le bien [GOO_MAJOR_REFERENCE] de l''échéance "[INX_SLICE]" du document "[DMT_NUMBER]" de la société "[COM_NAME]" doit être géré avec 4 décimales. [CRLF]Ceci afin d''assurer des proportions correctes lors des reprises d''accomptes.'
                             )
                         , '[INX_SLICE]'
                         , tplInvoice.INX_SLICE
                          )
                      , '[COM_NAME]'
                      , vComName
                       )
                   , '[DMT_NUMBER]'
                   , aDocNumber
                    )
                , '[GOO_MAJOR_REFERENCE]'
                , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tplInvoice.GCO_GOOD_ID)
                 )
             , '[CRLF]'
             , co.cLineBreak
              );
        end if;
      end if;
    end loop;
  end checkInvoiceExpiryPolicy;

  /**
  * Description
  *    vérifie la parité de l'échéancier
  */
  function checkDocumentBillBookPolicy(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vErrorMessage varchar2(1000);
  begin
    checkDocumentBillBookPolicy(aDocumentId, vErrorMessage);

    if vErrorMessage is not null then
      return 0;
    else
      return 1;
    end if;
  end checkDocumentBillBookPolicy;

  /**
  * Description
  *    vérifie la parité de l'échéancier
  */
  procedure checkDocumentBillBookPolicy(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aErrorMessage out varchar2)
  is
    vNbFinalInvoice pls_integer;
    vTplDocument    DOC_DOCUMENT%rowtype;
  begin
    select *
      into vTplDocument
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    -- recherche qu'on ait une et une seule échéance de type '3' (facture finale)
    select count(*)
      into vNbFinalInvoice
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = aDocumentId
       and C_INVOICE_EXPIRY_DOC_TYPE = '3';

    if vNbFinalInvoice = 0 then
      aErrorMessage  :=
        replace(PCS.PC_FUNCTIONS.TranslateWord('L''échéancier du document [DMT_NUMBER] ne contient pas de facture finale')
              , '[DMT_NUMBER]'
              , vTplDocument.DMT_NUMBER
               );
    elsif vNbFinalInvoice > 1 then
      aErrorMessage  :=
        replace(PCS.PC_FUNCTIONS.TranslateWord('L''échéancier du document [DMT_NUMBER] ne peut contenir plus d''une facture finale.')
              , '[DMT_NUMBER]'
              , vTplDocument.DMT_NUMBER
               );
    end if;

    if aErrorMessage is null then
      -- check the expiries
      for tplExpiries in (select DOC_INVOICE_EXPIRY_ID
                            from DOC_INVOICE_EXPIRY
                           where DOC_DOCUMENT_ID = aDocumentId) loop
        checkInvoiceExpiryPolicy(tplExpiries.DOC_INVOICE_EXPIRY_ID, vTplDocument.DMT_ONLY_AMOUNT_BILL_BOOK, null, 0   -- not in generation context
                               , aErrorMessage);

        if aErrorMessage is not null then
          aErrorMessage  :=
            replace(PCS.PC_FUNCTIONS.TranslateWord('Le contrôle du détail de l''échéancier du document [DMT_NUMBER] a échoué.')
                  , '[DMT_NUMBER]'
                  , vTplDocument.DMT_NUMBER
                   ) ||
            chr(10) ||
            aErrorMessage;
        end if;

        exit when aErrorMessage is not null;
      end loop;
    end if;
  end checkDocumentBillBookPolicy;

  /**
  * Description
  *    contrôle le montant du document fils
  */
  function checkSubDocumentAmount(
    aDocumentId      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aDeltaMode       in varchar2 default 'AMOUNT'
  )
    return number
  is
    vExpiryAmount             DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vRetDepositAmount         DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
    vPosRetDepositTotalAmount DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    vPosTotalAmount           DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    vFchTotalAmount           DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    vDocumentTotalAmount      DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
  begin
    -- recherche des montants directement dans l'échéancier
    select nvl(INX_NET_VALUE_EXCL, 0)
         , nvl(INX_RET_DEPOSIT_NET_EXCL, 0)
      into vExpiryAmount
         , vRetDepositAmount
      from DOC_INVOICE_EXPIRY
     where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

    if aDeltaMode = 'AMOUNT' then
      -- sous-total positions
      begin
        select nvl(FOO_GOOD_TOT_AMOUNT_EXCL, 0)
          into vPosTotalAmount
          from V_DOC_POS_TOT_INVOICE_EXPIRY
         where DOC_DOCUMENT_ID = aDocumentId
           and DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;
      exception
        when no_data_found then
          vPosTotalAmount  := 0;
      end;

      -- sous-total foot_charge
      begin
        select nvl(FOO_EXCL_AMOUNT, 0)
          into vFchTotalAmount
          from V_DOC_FCH_TOT_INVOICE_EXPIRY
         where DOC_DOCUMENT_ID = aDocumentId
           and DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;
      exception
        when no_data_found then
          vFchTotalAmount  := 0;
      end;

      -- total des montants liés à l'échéancier
      vDocumentTotalAmount  := nvl(vPosTotalAmount, 0) + nvl(vFchTotalAmount, 0);
      return vExpiryAmount - vRetDepositAmount - vDocumentTotalAmount;
    else
      -- sous-total acomptes/ reprises d'acomptes positions
      begin
        select -nvl(FOO_GOOD_TOT_AMOUNT_EXCL, 0)
          into vPosRetDepositTotalAmount
          from V_DOC_POS_TOT_INX_RET_AMOUNT
         where DOC_DOCUMENT_ID = aDocumentId
           and DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;
      exception
        when no_data_found then
          vPosRetDepositTotalAmount  := 0;
      end;

      return vRetDepositAmount - vPosRetDepositTotalAmount;
    end if;
  exception
    when no_data_found then
      -- Document sans pied donc sans échéancier
      return 0;
  end checkSubDocumentAmount;

  /**
  * procedure checkSubDocumentAmount
  * Description
  *    contrôle pour tous les échéancier liés au document,
  *    la parité des montants avec l'échéancier père
  * @created fp 13.09.2006
  * @lastUpdate fp 06.03.2007
  * @public
  * @param aDocumentId : id du document à contrôler
  * @param aInvoiceExpiryId (out) : id de l'échéance à corriger
  * @param aDelta (out) montant  de différence
  * @return 1 si OK
  */
  procedure checkSubDocumentAmount(
    aDocumentId      in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId out    number
  , aDeltaAmount     out    number
  , aDeltaRet        out    number
  )
  is
    vDiffAmount DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vDiffRet    DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
  begin
    aDeltaAmount  := 0;
    aDeltaRet     := 0;

    for tplInvoiceExpiry in (select distinct DOC_INVOICE_EXPIRY_ID
                                        from (select DOC_INVOICE_EXPIRY_ID
                                                from DOC_POSITION
                                               where DOC_DOCUMENT_ID = aDocumentId
                                                 and DOC_INVOICE_EXPIRY_ID is not null
                                              union all
                                              select DOC_INVOICE_EXPIRY_ID
                                                from DOC_FOOT_CHARGE
                                               where DOC_FOOT_ID = aDocumentId
                                                 and DOC_INVOICE_EXPIRY_ID is not null) ) loop
      vDiffAmount  := checkSubDocumentAmount(aDocumentId, tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID, 'AMOUNT');
      vDiffRet     := checkSubDocumentAmount(aDocumentId, tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID, 'RET');

      if    vDiffAmount <> 0
         or vDiffRet <> 0 then
        aDeltaAmount      := aDeltaAmount + vDiffAmount;
        aDeltaRet         := aDeltaRet + vDiffRet;
        aInvoiceExpiryId  := tplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID;
        exit;
      end if;
    end loop;
  end checkSubDocumentAmount;

  /**
  * Description
  *    contrôle le montant du document fils
  */
  function checkSubDocumentAmount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDeltaMode in varchar2 default 'AMOUNT')
    return number
  is
    vInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    vDeltaAmount     DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vDeltaRet        DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
  begin
    checkSubDocumentAmount(aDocumentId, vInvoiceExpiryId, vDeltaAmount, vDeltaRet);

    if aDeltaMode = 'AMOUNT' then
      return vDeltaAmount;
    elsif aDeltaMode = 'GLOBAL' then
      return abs(nvl(vDeltaAmount, 0) ) + abs(nvl(vDeltaRet, 0) );
    else
      return vDeltaRet;
    end if;
  end checkSubDocumentAmount;

  /**
  * Description
  *    recherche le montant de différence de reprise d'acompte déchargé
  */
  function getSubDocumentRetDepositDiff(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type
  is
    vResult DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
  begin
    select nvl(avg(INX1.INX_RET_DEPOSIT_NET_EXCL), 0) - nvl(sum(-POS1.POS_NET_VALUE_EXCL), 0)
      into vResult
      from DOC_POSITION POS1
         , DOC_POSITION_DETAIL PDE1
         , DOC_INVOICE_EXPIRY INX1
         , DOC_POSITION_DETAIL PDE2
         , DOC_POSITION POS2
         , DOC_INVOICE_EXPIRY INX2
     where POS1.DOC_DOCUMENT_Id = aDocumentId
       and INX1.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
       and PDE1.DOC_POSITION_Id = POS1.DOC_POSITION_ID
       and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC_DOC_POSITION_DETAIL_ID
       and POS2.DOC_POSITION_ID = PDE2.DOC_POSITION_ID
       and POS2.DOC_INVOICE_EXPIRY_ID = INX2.DOC_INVOICE_EXPIRY_ID
       and INX1.DOC_DOCUMENT_ID = INX2.DOC_DOCUMENT_ID
       and INX2.C_INVOICE_EXPIRY_DOC_TYPE = '1';

    return vResult;
  end getSubDocumentRetDepositDiff;

  /**
  * Description
  *    mets à jour le montant de l'échéance liée
  *    en fonction du montant du document fils
  *    et recalcule les échéances
  */
  procedure correctInvoiceExpiryAmount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
  is
    vDiffAmount           DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vRetDepositDiff       DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
    vExpiryDocumentId     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vInvoicingDate        DOC_INVOICE_EXPIRY.INX_INVOICING_DATE%type;
    vNewAmount            number;
    vInvoiceExpiryDocType DOC_INVOICE_EXPIRY.C_INVOICE_EXPIRY_DOC_TYPE%type;
  begin
    vDiffAmount      := checkSubDocumentAmount(aDocumentId, aInvoiceExpiryId, 'AMOUNT');
    vRetDepositDiff  := checkSubDocumentAmount(aDocumentId, aInvoiceExpiryId, 'RET');

    if    vDiffAmount <> 0
       or vRetDepositDiff <> 0 then
      -- recherche de la date du document
      select DMT_DATE_VALUE
        into vInvoicingDate
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentId;

      -- maj du montant de l'échéance
      update    DOC_INVOICE_EXPIRY
            set INX_NET_VALUE_EXCL = nvl(INX_NET_VALUE_EXCL, 0) - vDiffAmount
              , INX_RET_DEPOSIT_NET_EXCL = nvl(INX_RET_DEPOSIT_NET_EXCL, 0) - vRetDepositDiff
              , INX_INVOICING_DATE = vInvoicingDate
              , INX_PROPORTION = null
          where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
      returning DOC_DOCUMENT_ID
              , INX_NET_VALUE_EXCL
              , C_INVOICE_EXPIRY_DOC_TYPE
           into vExpiryDocumentId
              , vNewAmount
              , vInvoiceExpiryDocType;

      if vInvoiceExpiryDocType <> '3' then
        -- recalcule de l'échéancier lié
        calculateDocumentBillBook(vExpiryDocumentId);
      end if;
    end if;
  end correctInvoiceExpiryAmount;

  /**
  * Description
  *    Met à jour le montant de l'échéancier avec le montant du document généré
  */
  procedure updateSourceExpiryAmount(aInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
  is
  begin
    -- recherche du montant du document
    for tplInvoiceExpiry in (select FOO.FOO_GOOD_TOT_AMOUNT_EXCL INX_NET_VALUE_EXCL
                                  , FOO.FOO_GOOD_TOT_AMOUNT_EX_B INX_NET_VALUE_EXCL_B
                                  , INX.DOC_DOCUMENT_ID
                               from DOC_FOOT FOO
                                  , DOC_DOCUMENT DMT
                                  , DOC_INVOICE_EXPIRY INX
                              where DMT.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
                                and INX.DOC_INVOICE_EXPIRY_ID = DMT.DOC_INVOICE_EXPIRY_ID
                                and INX.C_INVOICE_EXPIRY_DOC_TYPE <> '3') loop
      -- maj de montants de l'échéancier
      update DOC_INVOICE_EXPIRY
         set INX_NET_VALUE_EXCL = tplInvoiceExpiry.INX_NET_VALUE_EXCL
       --, INX_NET_VALUE_EXCL_B = tplInvoiceExpiry.INX_NET_VALUE_EXCL_B
      where  DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

      CalculateDocumentBillBook(tplInvoiceExpiry.DOC_DOCUMENT_ID);
    end loop;
  end updateSourceExpiryAmount;

  /**
  * Description
  *   Mise à jour du flag INX_INVOICE_GENERATED selon le nombre de positions générées
  */
  procedure UpdateInvoiceGeneratedFlag(iInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
  is
  begin
    if iInvoiceExpiryId is not null then
      update DOC_INVOICE_EXPIRY
         set INX_INVOICE_GENERATED = sign(INX_NB_POS_GEN)
       where DOC_INVOICE_EXPIRY_ID = iInvoiceExpiryId;
    end if;
  end UpdateInvoiceGeneratedFlag;

  /**
  * Description
  *   Indique si le document possède un échéancier
  */
  function IsLinked2Expiry(iDocumentId in DOC_INVOICE_EXPIRY.DOC_DOCUMENT_ID%type)
    return number
  is
    vIsLinked2Expiry number(1);
  begin
    -- test si le document possède un échéancier
    select sign(nvl(max(DOC_INVOICE_EXPIRY_ID), 0) )
      into vIsLinked2Expiry
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = iDocumentId;

    return vIsLinked2Expiry;
  end IsLinked2Expiry;

  /**
  * Description
  *    recherche le document "échéancier" père en fonction des liens de décharge
  */
  function getRootDocumentId(aDocumentId in DOC_INVOICE_EXPIRY.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  is
    vResult DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- recherche des documents pères
    for tplDischargedDet in (select distinct PDE2.DOC_DOCUMENT_ID
                                        from DOC_POSITION_DETAIL PDE1
                                           , DOC_POSITION_DETAIL PDE2
                                       where PDE1.DOC_DOCUMENT_ID = aDocumentId
                                         and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC_DOC_POSITION_DETAIL_ID) loop
      -- test si le document père trouvé est lié à un échéancier
      if IsLinked2Expiry(tplDischargedDet.DOC_DOCUMENT_ID) = 1 then
        -- si il est lié, on renvoie l'id du document trouvé
        vResult  := tplDischargedDet.DOC_DOCUMENT_ID;
      else
        -- s'il n'est pas lié, on regarde si le document trouvé a un parent lié
        vResult  := getRootDocumentId(aDocumentId => tplDischargedDet.DOC_DOCUMENT_ID);
      end if;

      if vResult is not null then
        return vResult;
      end if;
    end loop;

    return null;
  end getRootDocumentId;

  /**
  * Description
  *    test si la position est liée directement ou indirectement au document passé en paramètre
  */
  function isLinked2Root(aPositionId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDocumentId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return number
  is
    vResult     number(1);
    vPositionId DOC_POSITION.DOC_POSITION_ID%type;
    vDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- recherche du document parent de la position
    select PDE2.DOC_POSITION_ID
         , PDE2.DOC_DOCUMENT_ID
      into vPositionId
         , vDocumentId
      from DOC_POSITION_DETAIL PDE1
         , DOC_POSITION_DETAIL PDE2
     where PDE1.DOC_POSITION_ID = aPositionId
       and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC_DOC_POSITION_DETAIL_ID;

    if aDocumentId = vDocumentId then
      -- si le document parent correspond au document recherché alors la fonction a réussi
      return 1;
    else
      --si le document parent à lui aussi un parent, on continue la recherche
      return isLinked2Root(vPositionId, aDocumentId);
    end if;
  exception
    when no_data_found then
      return 0;
  end isLinked2Root;

  /**
  * Description
  *    recherche l'id de l'échéance d'origine
  */
  function getDepositRootLink(aPositionId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  is
    vResult DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
  begin
    -- recherche du document parent de la position
    select max(POS2.DOC_INVOICE_EXPIRY_ID)
      into vResult
      from DOC_POSITION_DETAIL PDE1
         , DOC_POSITION_DETAIL PDE2
         , DOC_POSITION POS2
         , DOC_INVOICE_EXPIRY INX2
     where PDE1.DOC_POSITION_ID = aPositionId
       and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC_DOC_POSITION_DETAIL_ID
       and POS2.DOC_POSITION_ID = PDE2.DOC_POSITION_ID
       and INX2.DOC_INVOICE_EXPIRY_ID = POS2.DOC_INVOICE_EXPIRY_ID
       and INX2.C_INVOICE_EXPIRY_DOC_TYPE in('1', '5');

    return vResult;
  end getDepositRootLink;

  /**
  * Description
  *    lie un document déchargé à une échéance
  */
  procedure linkDocument2InvoiceExpiry(
    aDocumentId      in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInvoiceExpiryId in     DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
  , aErrorCode       out    DOC_INVOICE_EXPIRY.C_DOC_INVOICE_EXPIRY_ERROR%type
  )
  is
    vLinkedExpiryDocumentId DOC_DOCUMENT.DOC_DOCUMENT_Id%type;
    vActualInvoiceExpiryId  DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    vDepositRecoverAmount   DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
    vCumulRetAmount         DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type   := 0;

    -- Contrôle que les quantités du document à lier
    -- correspondent aux quantités des détails de l'échéancier
    function verifyDetQuantity(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
      return boolean
    is
      vTest             pls_integer;
      vExpiryDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    begin
      -- recherche l'id du document de l'échéancier
      select DOC_DOCUMENT_ID
        into vExpiryDocumentId
        from DOC_INVOICE_EXPIRY
       where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

      -- ne teste que les facture partielles avec décharge
      if     GetInvoiceExpiryType(aInvoiceExpiryId) = '2'
         and not IsDocumentOnlyAmountBillBook(vExpiryDocumentId) then
        -- doit retourner 0 si OK
        -- liste des positions du document avec les qtés moins le détail de l'échéancier
        select count(*)
          into vTest
          from (select   POS_FATHER.POS_NUMBER
                       , sum(PDE_SON.PDE_BASIS_QUANTITY) POS_BASIS_QUANTITY
                    from DOC_POSITION_DETAIL PDE_SON
                       , DOC_POSITION POS_SON
                       , DOC_POSITION_DETAIL PDE_FATHER
                       , DOC_POSITION POS_FATHER
                       , DOC_INVOICE_EXPIRY INX
                   where PDE_SON.DOC_DOCUMENT_ID = aDocumentId
                     and POS_SON.DOC_POSITION_ID = PDE_SON.DOC_POSITION_ID
                     and INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                     and PDE_FATHER.DOC_POSITION_DETAIL_ID = PDE_SON.DOC_DOC_POSITION_DETAIL_ID
                     and POS_FATHER.DOC_POSITION_ID = PDE_FATHER.DOC_POSITION_ID
                     and DOC_INVOICE_EXPIRY_FUNCTIONS.isLinked2Root(POS_SON.DOC_POSITION_ID, INX.DOC_DOCUMENT_ID) = 1
                     and PDE_SON.PDE_BASIS_QUANTITY <> 0
                group by POS_FATHER.POS_NUMBER
                minus
                select POS_NUMBER
                     , IED_DISCHARGE_QUANTITY
                  from DOC_INVOICE_EXPIRY_DETAIL IED
                     , DOC_POSITION POS
                 where IED.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                   and POS.DOC_POSITION_ID = IED.DOC_POSITION_ID);

        if vTest = 0 then
          -- doit retourner 0 si OK
          -- détail de l'échéancier moins liste des positions du document avec les qtés
          select count(*)
            into vTest
            from (select POS_NUMBER
                       , IED_DISCHARGE_QUANTITY
                    from DOC_INVOICE_EXPIRY_DETAIL IED
                       , DOC_POSITION POS
                   where IED.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                     and POS.DOC_POSITION_ID = IED.DOC_POSITION_ID
                  minus
                  select   POS_FATHER.POS_NUMBER
                         , sum(PDE_SON.PDE_BASIS_QUANTITY) POS_BASIS_QUANTITY
                      from DOC_POSITION_DETAIL PDE_SON
                         , DOC_POSITION POS_SON
                         , DOC_POSITION_DETAIL PDE_FATHER
                         , DOC_POSITION POS_FATHER
                         , DOC_INVOICE_EXPIRY INX
                     where PDE_SON.DOC_DOCUMENT_ID = aDocumentId
                       and POS_SON.DOC_POSITION_ID = PDE_SON.DOC_POSITION_ID
                       and INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                       and PDE_FATHER.DOC_POSITION_DETAIL_ID = PDE_SON.DOC_DOC_POSITION_DETAIL_ID
                       and POS_FATHER.DOC_POSITION_ID = PDE_FATHER.DOC_POSITION_ID
                       and DOC_INVOICE_EXPIRY_FUNCTIONS.isLinked2Root(POS_SON.DOC_POSITION_ID, INX.DOC_DOCUMENT_ID) = 1
                       and PDE_SON.PDE_BASIS_QUANTITY <> 0
                  group by POS_FATHER.POS_NUMBER);

          return(vTest = 0);
        else
          return false;
        end if;
      else   -- si on a pas affaire à une facture partielle
        return true;
      end if;
    end verifyDetQuantity;
  begin
    savepoint spStartPoint;

    -- Contrôle que les quantités du document à lier
    -- correspondent aux quantités des détails de l'échéancier
    if verifyDetQuantity(aDocumentId, aInvoiceExpiryId) then
      -- Supression des liens
      update DOC_POSITION POS
         set POS.DOC_INVOICE_EXPIRY_ID = null
       where POS.DOC_DOCUMENT_ID = aDocumentId;

      if nvl(aInvoiceExpiryId, 0) <> 0 then
        -- recherche du document lié à l'échéance
        select DOC_DOCUMENT_ID
             , INX_RET_DEPOSIT_NET_EXCL
          into vLinkedExpiryDocumentId
             , vDepositRecoverAmount
          from DOC_INVOICE_EXPIRY
         where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

        -- teste si le lien actuel est identique au lien que l'on veut recréer
        begin
          select distinct DOC_INVOICE_EXPIRY_ID
                     into vActualInvoiceExpiryId
                     from DOC_POSITION
                    where DOC_DOCUMENT_ID = aDocumentId;
        exception
          when too_many_rows then
            vActualInvoiceExpiryId  := aInvoiceExpiryId;
        end;

        if nvl(vActualInvoiceExpiryId, 0) <> aInvoiceExpiryId then
          -- mise à jour du lien pour les positions déchargées
          update DOC_POSITION POS
             set POS.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
           where POS.DOC_DOCUMENT_ID = aDocumentId
             and POS.DOC_INVOICE_EXPIRY_ID is null
             and isLinked2Root(POS.DOC_POSITION_ID, vLinkedExpiryDocumentId) = 1;

          -- mise à jour du lien pour les positions d'acompte déchargées indirectement
          update DOC_POSITION POS
             set POS.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
           where POS.DOC_DOCUMENT_ID = aDocumentId
             and POS.DOC_INVOICE_EXPIRY_ID is null
             and exists(
                   select INX2.DOC_INVOICE_EXPIRY_ID
                     from DOC_POSITION_DETAIL PDE1
                        , DOC_POSITION_DETAIL PDE2
                        , DOC_POSITION POS2
                        , DOC_INVOICE_EXPIRY INX2
                    where PDE1.DOC_POSITION_ID = POS.DOC_POSITION_ID
                      and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC_DOC_POSITION_DETAIL_ID
                      and POS2.DOC_POSITION_ID = PDE2.DOC_POSITION_ID
                      and INX2.DOC_INVOICE_EXPIRY_ID = POS2.DOC_INVOICE_EXPIRY_ID
                      and INX2.C_INVOICE_EXPIRY_DOC_TYPE = '1'
                      and INX2.DOC_DOCUMENT_Id = vLinkedExpiryDocumentId);

          -- reprise d'acompte automatique, à condition qu'aucune décharge d'acompte n'ait déjà été effectuée sur le document
          if getDepositRecoverAmount(aDocumentId) = 0 then
            for tplInvoiceExpiryDetail in (select   IED.DOC_INVOICE_EXPIRY_DETAIL_ID
                                                  , getRetDepositAmount(IED_DISCHARGE_QUANTITY, IED.DOC_POSITION_ID, 1) IED_RET_DEPOSIT_NET_EXCL
                                                  , IED.DOC_POSITION_ID
                                               from DOC_INVOICE_EXPIRY_DETAIL IED
                                                  , DOC_POSITION POS
                                                  , DOC_POSITION_DETAIL PDE
                                              where IED.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
                                                and POS.DOC_POSITION_ID = IED.DOC_POSITION_ID
                                                and PDE.DOC_POSITION_ID = IED.DOC_POSITION_ID
                                                and (   nvl(IED_DISCHARGE_QUANTITY, 0) <> 0
                                                     or nvl(IED_RET_DEPOSIT_NET_EXCL, 0) <> 0
                                                     or nvl(IED_NET_VALUE_EXCL, 0) <> 0
                                                    )
                                           order by POS.POS_NUMBER
                                                  , PDE.DOC_POSITION_DETAIL_ID) loop
              vCumulRetAmount  := vCumulRetAmount + tplInvoiceExpiryDetail.IED_RET_DEPOSIT_NET_EXCL;
              dischargeDepositPos(aDocumentId
                                , aInvoiceExpiryId
                                , vLinkedExpiryDocumentId
                                , tplInvoiceExpiryDetail.DOC_POSITION_ID   --aLinkedPositionId
                                , tplInvoiceExpiryDetail.IED_RET_DEPOSIT_NET_EXCL
                                , 0
                                , aErrorCode
                                 );
            end loop;

            -- décharge des reprises d'acompte manquantes
            dischargeDepositPos(aDocumentId
                              , aInvoiceExpiryId
                              , vLinkedExpiryDocumentId
                              , null   --aLinkedPositionId
                              , vDepositRecoverAmount - vCumulRetAmount   -- - getDepositRecoverAmount(aDocumentId)
                              , 0
                              , aErrorCode
                               );

            if aErrorCode is null then
              DOC_FINALIZE.FinalizeDocument(aDocumentId);
            else
              rollback to spStartPoint;
            end if;
          end if;
        end if;
      end if;
    else
      aErrorCode  := '040';
      rollback to spStartPoint;
    end if;
  end linkDocument2InvoiceExpiry;

  /**
  * Description
  *    contrôle s'il manque un lien d'échéancier
  */
  function testInvoiceExpiryLink(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aForceTest number default 0)
    return number
  is
    lGaugeId DOC_DOCUMENT.DOC_GAUGE_ID%type   := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_GAUGE_ID', aDocumentId);
  begin
    -- si le document fait de l'ACI
    if    DOC_I_LIB_GAUGE.WillGenerateFinancialMoves(lGaugeId) = 1
       or aForceTest = 1 then
      -- recherche s'il existe des détails déchargés non lié à un échéancier
      for tplDocSource in (select distinct PDE2.DOC_DOCUMENT_ID
                                         , DMT2.DMT_NUMBER
                                         , DMT2.DMT_INVOICE_EXPIRY
                                         , INX2.C_INVOICE_EXPIRY_DOC_TYPE
                                      from DOC_GAUGE_STRUCTURED GAS1
                                         , DOC_DOCUMENT DMT1
                                         , DOC_POSITION POS1
                                         , DOC_POSITION_DETAIL PDE1
                                         , DOC_POSITION_DETAIL PDE2
                                         , DOC_INVOICE_EXPIRY INX2
                                         , DOC_DOCUMENT DMT2
                                     where PDE1.DOC_DOCUMENT_ID = aDocumentId
                                       and POS1.DOC_POSITION_ID = PDE1.DOC_POSITION_ID
                                       and POS1.DOC_INVOICE_EXPIRY_ID is null
                                       and DMT1.DOC_DOCUMENT_Id = POS1.DOC_DOCUMENT_ID
                                       and GAS1.DOC_GAUGE_ID = DMT1.DOC_GAUGE_ID
                                       and (   GAS1.GAS_CHECK_INVOICE_EXPIRY_LINK = 1
                                            or aForceTest = 1)
                                       and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC_DOC_POSITION_DETAIL_ID
                                       and INX2.DOC_DOCUMENT_ID(+) = PDE2.DOC_DOCUMENT_ID
                                       and DMT2.DOC_DOCUMENT_ID = PDE2.DOC_DOCUMENT_ID) loop
        if     tplDocSource.DMT_INVOICE_EXPIRY = 1
           and tplDocSource.C_INVOICE_EXPIRY_DOC_TYPE in('2', '3') then
          return 0;
        elsif tplDocSource.C_INVOICE_EXPIRY_DOC_TYPE is null then
          if testInvoiceExpiryLink(tplDocSource.DOC_DOCUMENT_ID, 1) = 0 then
            return 0;
          end if;
        end if;
      end loop;

      -- si rien ne correspond à la sélection, c'est OK
      return 1;
    else
      -- dans le cas d'un document de générant pas de mouvements financiers, le test est automatiquement bon
      return 1;
    end if;
  end testInvoiceExpiryLink;

  /**
  * Description
  *    gèle les montants (vide le champ proportion pour toutes les échéances)
  */
  procedure frozeAmount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    update DOC_INVOICE_EXPIRY
       set INX_PROPORTION = null
     where DOC_DOCUMENT_ID = aDocumentId;
  end frozeAmount;

  /**
  * Description
  *    vérifie si des échéances avec proportion existent encore
  */
  function stillExistProportion(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vResult pls_integer;
  begin
    select sign(count(*) )
      into vResult
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = aDocumentId;

    return vResult;
  end stillExistProportion;

  /**
  * Description
  *    remplissage de la table DOC_INVOICE_EXPIRY_DETAIL
  */
  procedure initInvoiceExpiryDetail(aInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
  is
  begin
    -- insertion de toutes les position non-encore présente dans le détail avec initialisation
    -- quantités à 0
    insert into DOC_INVOICE_EXPIRY_DETAIL
                (DOC_INVOICE_EXPIRY_DETAIL_ID
               , DOC_INVOICE_EXPIRY_ID
               , IED_DISCHARGE_QUANTITY
               , DOC_POSITION_ID
               , IED_WORDING
               , IED_DESCRIPTION
               , IED_RET_DEPOSIT_NET_EXCL
               , IED_RET_DEPOSIT_NET_INCL
               , IED_NET_VALUE_EXCL
               , IED_NET_VALUE_INCL
               , A_DATECRE
               , A_IDCRE
                )
      select init_id_seq.nextval   --DOC_INVOICE_EXPIRY_DETAIL_ID
           , aInvoiceExpiryId   --DOC_INVOICE_EXPIRY_ID
           , 0   --IED_DISCHARGE_QUANTITY
           , POS.DOC_POSITION_ID
           , INX_WORDING   --IED_WORDING
           , INX_DESCRIPTION   -- IED_DESCRIPTION
           , 0   --IED_RET_DEPOSIT_NET_EXCL
           , 0   --IED_RET_DEPOSIT_NET_INCL
           , 0   --IED_NET_VALUE_EXCL
           , 0   --IED_NET_VALUE_INCL
           , sysdate   --A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   --A_IDCRE
        from DOC_POSITION POS
           , DOC_INVOICE_EXPIRY INX
       where POS.DOC_DOCUMENT_ID = (select DOC_DOCUMENT_ID
                                      from DOC_INVOICE_EXPIRY
                                     where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId)
         and INX.DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
         and not exists(select DOC_POSITION_ID
                          from DOC_INVOICE_EXPIRY_DETAIL
                         where DOC_POSITION_ID = POS.DOC_POSITION_ID
                           and DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId);
  end initInvoiceExpiryDetail;

  /**
  * Description
  *    Purge de la table DOC_INVOICE_EXPIRY_DETAIL
  */
  procedure purgeInvoiceExpiryDetail(aInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
  is
  begin
    -- suppression de toutes les positions non sélectionnées dans le détail
    delete from DOC_INVOICE_EXPIRY_DETAIL
          where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
            and IED_DISCHARGE_QUANTITY = 0
            and IED_NET_VALUE_EXCL = 0
            and IED_NET_VALUE_INCL = 0
            and IED_RET_DEPOSIT_NET_EXCL = 0
            and IED_RET_DEPOSIT_NET_INCL = 0;
  end purgeInvoiceExpiryDetail;

  /**
  * Description
  *    Vérification des montant entre l'échéancier et les détail
  */
  function checkDetailParity(aInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return number
  is
    vDetValue    DOC_INVOICE_EXPIRY_DETAIL.IED_NET_VALUE_EXCL%type;
    vDetRetValue DOC_INVOICE_EXPIRY_DETAIL.IED_RET_DEPOSIT_NET_EXCL%type;
    vValue       DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type;
    vRetValue    DOC_INVOICE_EXPIRY.INX_RET_DEPOSIT_NET_EXCL%type;
    vNbDetail    pls_integer;
  begin
    -- Somme des détails
    select sum(nvl(IED_NET_VALUE_EXCL, 0) )
         , sum(nvl(IED_RET_DEPOSIT_NET_EXCL, 0) )
         , count(*)
      into vDetValue
         , vDetRetValue
         , vNbDetail
      from DOC_INVOICE_EXPIRY_DETAIL
     where DOC_INVOICE_EXPIRY_ID = ainvoiceExpiryId;

    -- Si aucun détail n'est présent, on considère que c'est OK
    if vNbDetail = 0 then
      return 1;
    else
      -- Montant échéancier
      select nvl(INX_NET_VALUE_EXCL, 0)
           , nvl(INX_RET_DEPOSIT_NET_EXCL, 0)
        into vValue
           , vRetValue
        from DOC_INVOICE_EXPIRY
       where DOC_INVOICE_EXPIRY_ID = ainvoiceExpiryId;

      -- comparaison des montants
      if     vDetValue = vValue
         and vDetRetValue = vRetValue then
        return 1;
      else
        return 0;
      end if;
    end if;
  end checkDetailParity;

  /**
  * Description
  *    Maj du montant du détail d'échéance en fonction de la somme des détails
  */
  procedure updateExpiryAmountFromDetail(aInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
  is
    vNbModified pls_integer;
    vDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- nombre de  détails saisis
    select count(*)
      into vNbModified
      from DOC_INVOICE_EXPIRY_DETAIL
     where (   nvl(IED_NET_VALUE_EXCL, 0) <> 0
            or nvl(IED_DISCHARGE_QUANTITY, 0) <> 0
            or nvl(IED_RET_DEPOSIT_NET_EXCL, 0) <> 0)
       and DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId;

    -- si on a des détails saisis
    if vNbModified > 0 then
      -- maj de la position d'échéancier
      update    DOC_INVOICE_EXPIRY
            set (INX_PROPORTION, INX_NET_VALUE_EXCL, INX_RET_DEPOSIT_NET_EXCL) =
                  (select avg(decode(IED_NET_VALUE_EXCL, null, DOC_INVOICE_EXPIRY.INX_PROPORTION, null) )
                        , sum(nvl(decode(nvl(IED.IED_DISCHARGE_QUANTITY, 0)
                                       , 0, IED_NET_VALUE_EXCL
                                       , decode(POS_FINAL_QUANTITY, 0, 0, POS_NET_VALUE_EXCL * IED_DISCHARGE_QUANTITY / POS_FINAL_QUANTITY)
                                        )
                                , 0
                                 )
                             )
                        , decode(sum(nvl(IED_RET_DEPOSIT_NET_EXCL, 0) ), 0, null, sum(nvl(IED_RET_DEPOSIT_NET_EXCL, 0) ) )
                     from DOC_INVOICE_EXPIRY_DETAIL IED
                        , DOC_POSITION POS
                    where IED.DOC_INVOICE_EXPIRY_ID = DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID
                      and POS.DOC_POSITION_ID(+) = IED.DOC_POSITION_ID)
          where DOC_INVOICE_EXPIRY_ID = aInvoiceExpiryId
      returning DOC_DOCUMENT_ID
           into vDocumentId;

      -- recalcul de l'échéancier
      calculateDocumentBillBook(vDocumentId);
    end if;
  end updateExpiryAmountFromDetail;

  /**
  * Description
  *    fonction indiquant si au moins une des échéances a généré un document
  */
  function IsOneGenerated(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_Id%type)
    return number
  is
    vNbGenerated pls_integer;
  begin
    select count(*)
      into vNbGenerated
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = aDocumentId
       and INX_INVOICE_GENERATED = 1;

    return sign(vNbGenerated);
  end IsOneGenerated;

  /**
  * Description
  *    fonction indiquant si toutes les échéances ont généré un document
  */
  function IsAllGenerated(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_Id%type)
    return number
  is
    vNbNotGenerated pls_integer;
  begin
    select count(*)
      into vNbNotGenerated
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = aDocumentId
       and INX_INVOICE_GENERATED = 0;

    return abs(sign(vNbNotGenerated) - 1);
  end IsAllGenerated;

  /**
  * Description
  *    procedure de génération des documents échéancier depuis le générateur
  */
  procedure serialGeneration(aDateRef in date, aDateValue in date)
  is
    cursor crExpirytoGen
    is
      select   INX.DOC_INVOICE_EXPIRY_ID
             , INX.INX_VALUE_DATE
          from COM_LIST_ID_TEMP LID
             , DOC_INVOICE_EXPIRY INX
         where LID_CODE = 'DOC_BILL_BOOK_SELECTION'
           and LID_FREE_NUMBER_1 = 1
           and COM_LIST_ID_TEMP_ID = INX.DOC_INVOICE_EXPIRY_ID
      order by decode(C_INVOICE_EXPIRY_DOC_TYPE, '3', '1', '0' || C_INVOICE_EXPIRY_DOC_TYPE);

    vDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- curseur sur toutes les échéances sélectionnées
    for tplExpiryToGen in crExpiryToGen loop
      -- génération du document d'echéancier
      generateInvoiceDocument(aInvoiceExpiryId   => tplExpiryToGen.DOC_INVOICE_EXPIRY_ID
                            , aDateRef           => aDateRef
                            , aDateValue         => nvl(tplExpiryToGen.INX_VALUE_DATE, aDateValue)
                            , aDocumentId        => vDocumentId
                             );   -- , aDateGen);

      -- si OK entrer le document dans la liste des documents générés
      if vDocumentId is not null then
        insert into COM_LIST_ID_TEMP
                    (COM_LIST_ID_TEMP_ID
                   , LID_CODE
                    )
             values (vDocumentId
                   , 'DOC_GENERATED'
                    );
      -- si KO, mettre l'échéance dans la liste des erreurs
      else
        insert into COM_LIST_ID_TEMP
                    (COM_LIST_ID_TEMP_ID
                   , LID_CODE
                   , LID_FREE_NUMBER_1
                    )
             values (init_id_seq.nextval
                   , 'INX_ERROR'
                   , tplExpiryToGen.DOC_INVOICE_EXPIRY_ID
                    );
      end if;
    end loop;
  end serialGeneration;

  /**
  * Description
  *    retourne le gabarit par défaut en fonction du type de document échéancier
  */
  function getDefaultGauge(aAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type, aInvoiceExpiryDocType DOC_INVOICE_EXPIRY.C_INVOICE_EXPIRY_DOC_TYPE%type)
    return DOC_GAUGE.DOC_GAUGE_ID%type
  is
    vResult DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    select GIE.DOC_GAUGE_ID
      into vResult
      from DOC_GAUGE_INVOICE_EXPIRY GIE
         , DOC_GAUGE GAU
     where GIE.C_INVOICE_EXPIRY_DOC_TYPE = aInvoiceExpiryDocType
       and GAU.DOC_GAUGE_ID = GIE.DOC_GAUGE_ID
       and GAU.C_ADMIN_DOMAIN = aAdminDomain
       and GIE.GIE_DEFAULT = 1;

    return vResult;
  exception
    -- pas d'erreur si aucun gabarit par défaut n'est trouvé
    when no_data_found then
      return null;
  end getDefaultGauge;

  /**
  * Description
  *    retourne le nombre de gabarit possibles pour un type de document
  */
  function isOnlyOneDefault(aAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type, aInvoiceExpiryDocType DOC_INVOICE_EXPIRY.C_INVOICE_EXPIRY_DOC_TYPE%type)
    return pls_integer
  is
    vNbDefault pls_integer;
    vNbTot     pls_integer;
    vResult    pls_integer;
  begin
    select sum(GIE.GIE_DEFAULT)
         , count(*)
      into vNbDefault
         , vNbTot
      from DOC_GAUGE_INVOICE_EXPIRY GIE
         , DOC_GAUGE GAU
     where GIE.C_INVOICE_EXPIRY_DOC_TYPE = aInvoiceExpiryDocType
       and GAU.DOC_GAUGE_ID = GIE.DOC_GAUGE_Id
       and GAU.C_ADMIN_DOMAIN = aAdminDomain;

    if     vNbDefault = 1
       and vNbTot = 1 then
      return 1;
    else
      return 0;
    end if;
  end isOnlyOneDefault;

  /**
  * Description
  *    Indique si le document est généré par un échéancier
  */
  function IsDocLinkedToBillBook(aDocumentId in number)
    return pls_integer
  is
    vResult pls_integer;
  begin
    -- recherche si au moins une position du document est liée à un échéancier
    select sign(max(DOC_INVOICE_EXPIRY_ID) )
      into vResult
      from DOC_POSITION
     where DOC_DOCUMENT_ID = aDocumentId;

    -- si pas de lien on vérifie encore dans les remises et taxes de pied
    if vResult = 0 then
      -- recherche si au moins une remise/taxe de pied est liée à un échéancier
      select sign(max(DOC_INVOICE_EXPIRY_ID) )
        into vResult
        from DOC_FOOT_CHARGE
       where DOC_FOOT_ID = aDocumentId;
    end if;

    return vResult;
  end IsDocLinkedToBillBook;

  /**
  * Description
  *    retourne le solde en % par rapport au 100% pour un échéancier de type %
  */
  function getPercentBalance(aDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type default null)
    return DOC_INVOICE_EXPIRY.INX_PROPORTION%type
  is
    vResult DOC_INVOICE_EXPIRY.INX_PROPORTION%type;
  begin
    select 100 - sum(nvl(INX_PROPORTION, 0) )
      into vResult
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = aDocumentId
       and (   DOC_INVOICE_EXPIRY_ID <> aInvoiceExpiryId
            or aInvoiceExpiryId is null)
       and C_INVOICE_EXPIRY_DOC_TYPE in('1', '2', '3');

    return vResult;
  end getPercentBalance;

  /**
  * Description
  *    Procedure permettant de cloner un échéancier
  */
  procedure cloneBillBook(aSourceDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aTargetDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vCheckSum number(4);
  begin
    select count(*)
      into vCheckSum
      from (select DOC_GAUGE_ID
                 , PAC_PAYMENT_CONDITION_ID
                 , ACS_FINANCIAL_CURRENCY_ID
              from DOC_DOCUMENT
             where DOC_DOCUMENT_ID = aSourceDocumentId
            minus
            select DOC_GAUGE_ID
                 , PAC_PAYMENT_CONDITION_ID
                 , ACS_FINANCIAL_CURRENCY_ID
              from DOC_DOCUMENT
             where DOC_DOCUMENT_ID = aTargetDocumentId);

    if vCheckSum = 0 then
      select count(*)
        into vCheckSum
        from (select FOO_DOCUMENT_TOTAL_AMOUNT
                   , FOO_GOOD_TOTAL_AMOUNT
                   , FOO_TOTAL_VAT_AMOUNT
                   , FOO_CHARGE_TOTAL_AMOUNT
                   , FOO_DISCOUNT_TOTAL_AMOUNT
                   , FOO_COST_TOTAL_AMOUNT
                   , FOO_GOOD_TOT_AMOUNT_EXCL
                   , FOO_CHARG_TOT_AMOUNT_EXCL
                   , FOO_DISC_TOT_AMOUNT_EXCL
                   , FOO_COST_TOT_AMOUNT_EXCL
                   , FOO_TOTAL_NET_WEIGHT
                   , FOO_TOTAL_GROSS_WEIGHT
                   , FOO_TOTAL_RATE_FACTOR
                   , FOO_TOTAL_BASIS_QUANTITY
                   , FOO_TOTAL_INTERM_QUANTITY
                   , FOO_TOTAL_FINAL_QUANTITY
                from DOC_FOOT
               where DOC_FOOT_ID = aSourceDocumentId
              minus
              select FOO_DOCUMENT_TOTAL_AMOUNT
                   , FOO_GOOD_TOTAL_AMOUNT
                   , FOO_TOTAL_VAT_AMOUNT
                   , FOO_CHARGE_TOTAL_AMOUNT
                   , FOO_DISCOUNT_TOTAL_AMOUNT
                   , FOO_COST_TOTAL_AMOUNT
                   , FOO_GOOD_TOT_AMOUNT_EXCL
                   , FOO_CHARG_TOT_AMOUNT_EXCL
                   , FOO_DISC_TOT_AMOUNT_EXCL
                   , FOO_COST_TOT_AMOUNT_EXCL
                   , FOO_TOTAL_NET_WEIGHT
                   , FOO_TOTAL_GROSS_WEIGHT
                   , FOO_TOTAL_RATE_FACTOR
                   , FOO_TOTAL_BASIS_QUANTITY
                   , FOO_TOTAL_INTERM_QUANTITY
                   , FOO_TOTAL_FINAL_QUANTITY
                from DOC_FOOT
               where DOC_FOOT_ID = aTargetDocumentId);

      if vCheckSum = 0 then
        select count(*)
          into vCheckSum
          from (select C_GAUGE_TYPE_POS
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , ACS_TAX_CODE_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_DIVISION_ACCOUNT_ID
                     , POS_NUMBER
                     , POS_VAT_AMOUNT
                     , POS_VAT_BASE_AMOUNT
                     , POS_GROSS_UNIT_VALUE
                     , POS_NET_UNIT_VALUE
                     , POS_NET_UNIT_VALUE_INCL
                     , POS_REF_UNIT_VALUE
                     , POS_GROSS_VALUE
                     , POS_NET_VALUE_EXCL
                     , POS_NET_VALUE_INCL
                     , POS_BASIS_QUANTITY
                     , POS_INTERMEDIATE_QUANTITY
                     , POS_FINAL_QUANTITY
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , POS_IMF_TEXT_1
                     , POS_IMF_TEXT_2
                     , POS_IMF_TEXT_3
                     , POS_IMF_TEXT_4
                     , POS_IMF_TEXT_5
                     , POS_IMF_NUMBER_2
                     , POS_IMF_NUMBER_3
                     , POS_IMF_NUMBER_4
                     , POS_IMF_NUMBER_5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                  from DOC_POSITION
                 where DOC_DOCUMENT_ID = aSourceDocumentId
                minus
                select C_GAUGE_TYPE_POS
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , ACS_TAX_CODE_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_DIVISION_ACCOUNT_ID
                     , POS_NUMBER
                     , POS_VAT_AMOUNT
                     , POS_VAT_BASE_AMOUNT
                     , POS_GROSS_UNIT_VALUE
                     , POS_NET_UNIT_VALUE
                     , POS_NET_UNIT_VALUE_INCL
                     , POS_REF_UNIT_VALUE
                     , POS_GROSS_VALUE
                     , POS_NET_VALUE_EXCL
                     , POS_NET_VALUE_INCL
                     , POS_BASIS_QUANTITY
                     , POS_INTERMEDIATE_QUANTITY
                     , POS_FINAL_QUANTITY
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , POS_IMF_TEXT_1
                     , POS_IMF_TEXT_2
                     , POS_IMF_TEXT_3
                     , POS_IMF_TEXT_4
                     , POS_IMF_TEXT_5
                     , POS_IMF_NUMBER_2
                     , POS_IMF_NUMBER_3
                     , POS_IMF_NUMBER_4
                     , POS_IMF_NUMBER_5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                  from DOC_POSITION
                 where DOC_DOCUMENT_ID = aTargetDocumentId);

        if vCheckSum = 0 then
          select count(*)
            into vCheckSum
            from DOC_INVOICE_EXPIRY
           where DOC_DOCUMENT_ID = aTargetDocumentId
             and INX_INVOICE_GENERATED = 1;

          if vCheckSum = 0 then
            delete from DOC_INVOICE_EXPIRY
                  where DOC_DOCUMENT_ID = aTargetDocumentId;

            for tplSourceExpiry in (select *
                                      from DOC_INVOICE_EXPIRY
                                     where DOC_DOCUMENT_ID = aSourceDocumentId) loop
              declare
                vOldExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
              begin
                vOldExpiryId                           := tplSourceExpiry.DOC_INVOICE_EXPIRY_ID;
                tplSourceExpiry.DOC_INVOICE_EXPIRY_ID  := getNewId;
                tplSourceExpiry.DOC_DOCUMENT_ID        := aTargetDocumentId;
                tplSourceExpiry.INX_INVOICE_GENERATED  := 0;
                tplSourceExpiry.INX_INVOICING_DATE     := null;
                tplSourceExpiry.INX_NB_POS_GEN         := 0;
                tplSourceExpiry.A_DATECRE              := sysdate;
                tplSourceExpiry.A_IDCRE                := PCS.PC_I_LIB_SESSION.GetUserIni;
                tplSourceExpiry.A_DATEMOD              := null;
                tplSourceExpiry.A_IDMOD                := null;

                insert into DOC_INVOICE_EXPIRY
                     values tplSourceExpiry;

                for tplSourceExpiryDetail in (select *
                                                from DOC_INVOICE_EXPIRY_DETAIL
                                               where DOC_INVOICE_EXPIRY_ID = vOldExpiryId) loop
                  select POS1.DOC_POSITION_ID
                    into tplSourceExpiryDetail.DOC_POSITION_ID
                    from DOC_POSITION POS1
                   where POS1.DOC_DOCUMENT_ID = aTargetDocumentId
                     and POS1.POS_NUMBER = (select POS2.POS_NUMBER
                                              from DOC_POSITION POS2
                                             where POS2.DOC_POSITION_ID = tplSourceExpiryDetail.DOC_POSITION_ID);

                  tplSourceExpiryDetail.DOC_INVOICE_EXPIRY_DETAIL_ID  := getNewId;
                  tplSourceExpiryDetail.DOC_INVOICE_EXPIRY_ID         := tplSourceExpiry.DOC_INVOICE_EXPIRY_ID;
                  tplSourceExpiryDetail.A_DATECRE                     := sysdate;
                  tplSourceExpiryDetail.A_IDCRE                       := PCS.PC_I_LIB_SESSION.GetUserIni;
                  tplSourceExpiryDetail.A_DATEMOD                     := null;
                  tplSourceExpiryDetail.A_IDMOD                       := null;

                  insert into DOC_INVOICE_EXPIRY_DETAIL
                       values tplSourceExpiryDetail;
                end loop;
              end;
            end loop;
          else
            ra(PCS.PC_FUNCTIONS.translateWord('PCS - Des échéances ont déjà été générées. Impossible de cloner l''échéancier source') );
          end if;
        else
          ra(PCS.PC_FUNCTIONS.translateWord('PCS - Les champs importants de DOC_POSITION ne sont pas identiques. Impossible de cloner l''échéancier source') );
        end if;
      else
        ra(PCS.PC_FUNCTIONS.translateWord('PCS - Les champs importants de DOC_FOOT ne sont pas identiques. Impossible de cloner l''échéancier source') );
      end if;
    else
      ra(PCS.PC_FUNCTIONS.translateWord('PCS - Les champs importants de DOC_DOCUMENT ne sont pas identiques') );
    end if;
  end cloneBillBook;

  /**
  * Description
  *    Procedure permettant de cloner un échéancier
  */
  procedure cloneBillBook(aSourceDocument in DOC_DOCUMENT.DMT_NUMBER%type, aTargetDocument in DOC_DOCUMENT.DMT_NUMBER%type)
  is
    vSourceDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vTargetDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select DOC_DOCUMENT_ID
      into vSourceDocumentId
      from DOC_DOCUMENT
     where DMT_NUMBER = aSourceDocument;

    select DOC_DOCUMENT_ID
      into vTargetDocumentId
      from DOC_DOCUMENT
     where DMT_NUMBER = aTargetDocument;

    cloneBillBook(vSourceDocumentId, vTargetDocumentId);
  end cloneBillBook;

  procedure LogDocumentError(iDocNumber in DOC_DOCUMENT.DMT_NUMBER%type, iErrMsg in varchar2)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    begin
      --Initialisation entité COM_LIST_ID_TEMP
      fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_com_entity.gcComListIdTemp
                         , iot_crud_definition   => lt_crud_def
                         , in_schema_call        => fwk_i_typ_definition.SCHEMA_PCS
                          );
      -- Affectation des valeurs
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LID_CODE', 'CF_LOG_ERR');
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LID_FREE_NUMBER_1', gCashFlowAnalysisId);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LID_DESCRIPTION', gCashFlowSelComName || ' / ' || iDocNumber);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LID_FREE_MEMO_1', iErrMsg);
      --Ajout du record
      fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
      --Libèration entité
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    exception
      when others then
        fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20001
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'LogDocumentError'
                                           );
    end;
  end LogDocumentError;

  /**
  * function IsDetailFromBillBook
  * Description
  *   Indique si le détail de position provient via un flux de décharge d'un document échéancier
  * @created fp 23.03.2012
  * @lastUpdate
  * @public
  * @param iDetailId : détzail de position document logistique à tester
  * @return 0 ou 1
  */
  function IsDetailFromBillBook(iDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return number
  is
    lParentDetailId       DOC_POSITION_DETAIL.DOC_DOC_POSITION_DETAIL_ID%type;
    lPaymentConditionKind PAC_PAYMENT_CONDITION.C_PAYMENT_CONDITION_KIND%type;
  begin
    -- si pas de parent on sort tou de suite sans lancer de select
    if iDetailId is null then
      return 0;
    end if;

    select DET.DOC_DOC_POSITION_DETAIL_ID
         , PCO.C_PAYMENT_CONDITION_KIND
      into lParentDetailId
         , lPaymentConditionKind
      from DOC_POSITION_DETAIL DET
         , DOC_DOCUMENT DMT
         , PAC_PAYMENT_CONDITION PCO
     where DET.DOC_POSITION_DETAIL_ID = iDetailId
       and DMT.DOC_DOCUMENT_ID = DET.DOC_DOCUMENT_ID
       and PCO.PAC_PAYMENT_CONDITION_ID(+) = DMT.PAC_PAYMENT_CONDITION_ID;

    if lPaymentConditionKind = '02' then
      return 1;
    elsif lParentDetailId is not null then
      return IsDetailFromBillBook(lParentDetailId);
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return -1;
    when too_many_rows then
      return -2;
    when others then
      return -3;
  end IsDetailFromBillBook;

  /**
  * Description
  *    Indique si le document contrôle les liens avec l'échéancier
  */
  function IsLinkControl(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
  begin
    return FWK_I_LIB_ENTITY.getBooleanFieldFromPk('DOC_INVOICE_EXPIRY'
                                                , 'GAS_CHECK_INVOICE_EXPIRY_LINK'
                                                , FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_GAUGE_ID', iDocumentId)
                                                 );
  end IsLinkControl;

  /**
  * Description
  *   Recherche le document père de l'échéance
  */
  function GetInvoiceExpiryFatherDocId(iInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return DOC_INVOICE_EXPIRY.DOC_DOCUMENT_ID%type
  is
  begin
    return FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_INVOICE_EXPIRY', 'DOC_DOCUMENT_ID', iInvoiceExpiryId);
  end GetInvoiceExpiryFatherDocId;

  /**
  * Description
  *   Recherche le type de l'échéance
  */
  function GetInvoiceExpiryType(iInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return DOC_INVOICE_EXPIRY.C_INVOICE_EXPIRY_DOC_TYPE%type
  is
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('DOC_INVOICE_EXPIRY', 'C_INVOICE_EXPIRY_DOC_TYPE', iInvoiceExpiryId);
  end GetInvoiceExpiryType;

  /**
  * Description
  *    Recherche le "type de document échéancier" d'un document
  */
  function GetInvoiceExpiryDocType(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_INVOICE_EXPIRY.C_INVOICE_EXPIRY_DOC_TYPE%type
  is
  begin
    return GetInvoiceExpiryType(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_INVOICE_EXPIRY_ID', iDocumentId) );
  end GetInvoiceExpiryDocType;

  /**
  * Description
  *    Recherche le document d'origine de l'échéancier
  */
  function GetInvoiceExpiryParentDoc(iInvoiceExpiryId in DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type)
    return DOC_INVOICE_EXPIRY.DOC_DOCUMENT_ID%type
  is
  begin
    return FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_INVOICE_EXPIRY', 'DOC_DOCUMENT_ID', iInvoiceExpiryId);
  end GetInvoiceExpiryParentDoc;

  /**
  * Description
  *   Determine si le document doit être soldé car le document père est lié à un échéancier sans décharge
  */
  function ExpiryForcePosBalance(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return boolean
  is
    vExists pls_integer;
  begin
    for ltplPositionDetail in (select DOC_POSITION_DETAIL_ID
                                 from DOC_POSITION_DETAIL PDE
                                where PDE.DOC_POSITION_ID = iPositionId) loop
      if     IsDetailFromBillBook(ltplPositionDetail.DOC_POSITION_DETAIL_ID) = 1
         and IsPosDischargedFromOnlyAmount(iPositionId) = 1 then
        return true;
      end if;
    end loop;

    return false;
  end ExpiryForcePosBalance;

  /**
  * Description
  *   Indique si le document possède un échéancier sans décharge
  */
  function IsDocumentOnlyAmountBillBook(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
  begin
    return FWK_I_LIB_ENTITY.getBooleanFieldFromPk('DOC_DOCUMENT', 'DMT_ONLY_AMOUNT_BILL_BOOK', iDocumentId);
  end IsDocumentOnlyAmountBillBook;

  /**
   * Description
   *   Indique si le document possède un échéancier avec décharge
   */
  function IsDocOnlyDischargedBillBook(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    lNumber number;
  begin
    select count(DOC_DOCUMENT_ID)
      into lNumber
      from DOC_INVOICE_EXPIRY
     where DOC_DOCUMENT_ID = iDocumentId;

    if lNumber = 0 then
      return false;
    else
      if IsDocumentOnlyAmountBillBook(iDocumentId) then
        return false;
      else
        return true;
      end if;
    end if;
  end IsDocOnlyDischargedBillBook;

  /**
  * Description
  *   Indique si la facture finale de l'échéancier du document a été générée
  */
  function IsFinalInvoiceGenerated(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    lGenerated number(1);
  begin
    select nvl(INX_INVOICE_GENERATED, 0)
      into lGenerated
      from DOC_INVOICE_EXPIRY INX1
     where INX1.DOC_DOCUMENT_ID = iDocumentId
       and INX1.C_INVOICE_EXPIRY_DOC_TYPE = '3';

    return(lGenerated = 1);
  exception
    when no_data_found then
      return false;
    --ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - L''échéancier n''a pas de facture finale !') );
    when too_many_rows then
      ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - L''échéancier a plus d''une facture finale !') );
  end IsFinalInvoiceGenerated;

  /**
  * Description
  *    retourne true si document issu d'un échéancier
  */
  function IsBillBookChild(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    lDocFatherID          DOC_DOCUMENT.DOC_DOCUMENT_ID%type                := null;
    lDocFatherIDDischarge DOC_DOCUMENT.DOC_DOCUMENT_ID%type                := null;
    lCurrRiskVirtualID    DOC_DOCUMENT.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
  begin
    -- Rechercher le père du document échéancier (échéancier avec ou sans décharge )
    lDocFatherID           := GetInvoiceExpiryParentDoc(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_INVOICE_EXPIRY_ID', iDocumentId) );
    lDocFatherIDDischarge  := getRootDocumentId(aDocumentId => iDocumentId);

    -- Document qui vient d'un échéancier  (avec ou sasn décharge) ou document  déchargé à partir d'un échéancier
    -- 1 er cas -> facture issue d'un échéancier, 2ème cas document autre que facture (CC échéancée décharge en BL)
    if    lDocFatherID is not null
       or lDocFatherIDDischarge is not null then
      -- le père est multi couvert et c'est une facture issu de l'échéancier traitement comme document normal, car c'est ce document qui commence à consommer ds tranches
      if     (DOC_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(lDocFatherID) = 1)
         and lDocFatherID is not null then
        return false;
      end if;

      begin
        --pour les documents issus d'un échéancier par décharge (BL par exemple) qui ont une, on ne passe par par la procedure standard, car il ne consomme pas de tranche donc on retourne true              INTO lCurrRiskVirtualID
        select nvl(GAL_CURRENCY_RISK_VIRTUAL_ID, 0)
          into lCurrRiskVirtualID
          from DOC_DOCUMENT
         where DOC_DOCUMENT_ID = lDocFatherID;
      exception
        when no_data_found then
          begin
            select nvl(GAL_CURRENCY_RISK_VIRTUAL_ID, 0)
              into lCurrRiskVirtualID
              --pour les documents issus d'un échéancier par décharge (BL par exemple) qui ont une, on ne passe par par la procedure standard, car il ne consomme pas de tranche donc on retourne true              INTO lCurrRiskVirtualID
            from   DOC_DOCUMENT
             where DOC_DOCUMENT_ID = lDocFatherIDDischarge;
          exception
            when no_data_found then
              lCurrRiskVirtualID  := 0;
          end;
      end;

      if lCurrRiskVirtualID = 0 then
        return false;
      end if;

      return true;
    else
      return false;   -- document normaux et la commande échéancée elle -même
    end if;
  end IsBillBookChild;

  /**
  * Description
  *   Renvoie les données de la tranche virtuelle du document d'origine de l'échéancier
  */
  procedure GetRootDocCurrRiskData(
    iDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oRiskId     out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , oRiskType   out    GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type
  , oRiskRate   out    GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type
  , oRiskBase   out    GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type
  , oRiskForced out    DOC_DOCUMENT.DMT_CURR_RISK_FORCED%type
  , oErrorCode  out    number
  )
  is
    lCurrencyID      GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type;
    lOrigCurrencyID  GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type;
    lInvoiceExpiryId DOC_DOCUMENT.DOC_INVOICE_EXPIRY_ID%type;
    lRateOfExchange  DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    lBasePrice       DOC_DOCUMENT.DMT_BASE_PRICE%type;
  begin
    begin
      -- recherche des infos si le document est généré depuisun échéancier -> document générés non groupés
      select DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.DOC_INVOICE_EXPIRY_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , ORIG.ACS_FINANCIAL_CURRENCY_ID
           , ORIG.GAL_CURRENCY_RISK_VIRTUAL_ID
           , ORIG.C_CURR_RATE_COVER_TYPE
           , ORIG.DMT_RATE_OF_EXCHANGE
           , ORIG.DMT_BASE_PRICE
           , ORIG.DMT_CURR_RISK_FORCED
        into lCurrencyId
           , lInvoiceExpiryId
           , lRateOfExchange
           , lBasePrice
           , lOrigCurrencyId
           , oRiskId
           , oRiskType
           , oRiskRate
           , oRiskBase
           , oRiskForced
        from DOC_DOCUMENT DMT
           , DOC_INVOICE_EXPIRY INX
           , DOC_DOCUMENT ORIG
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and INX.DOC_INVOICE_EXPIRY_ID = DMT.DOC_INVOICE_EXPIRY_ID
         and ORIG.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID;
    exception
      when no_data_found then
        begin
          -- recherche des infos si le document est généré depuisun échéancier -> document générés groupées -> Ne peut exister que si il n'y a pas de couverture sur le document (interdit sur un document couvert par le générateur d'échéances en lot)
          select DMT.ACS_FINANCIAL_CURRENCY_ID
               , DMT.DOC_INVOICE_EXPIRY_ID
               , DMT.DMT_RATE_OF_EXCHANGE
               , DMT.DMT_BASE_PRICE
               , ORIG.ACS_FINANCIAL_CURRENCY_ID
               , ORIG.GAL_CURRENCY_RISK_VIRTUAL_ID
               , ORIG.C_CURR_RATE_COVER_TYPE
               , ORIG.DMT_RATE_OF_EXCHANGE
               , ORIG.DMT_BASE_PRICE
               , ORIG.DMT_CURR_RISK_FORCED
            into lCurrencyId
               , lInvoiceExpiryId
               , lRateOfExchange
               , lBasePrice
               , lOrigCurrencyId
               , oRiskId
               , oRiskType
               , oRiskRate
               , oRiskBase
               , oRiskForced
            from DOC_DOCUMENT DMT
               , DOC_INVOICE_EXPIRY INX
               , DOC_DOCUMENT ORIG
           where DMT.DOC_DOCUMENT_ID = iDocumentID
             and INX.DOC_INVOICE_EXPIRY_ID = (select max(DOC_INVOICE_EXPIRY_ID)
                                                from doc_position
                                               where doc_document_id = iDocumentID)
             and ORIG.DOC_DOCUMENT_ID = (select doc_document_id
                                           from doc_invoice_expiry
                                          where doc_invoice_expiry_id = (select max(DOC_INVOICE_EXPIRY_ID)
                                                                           from doc_position
                                                                          where doc_document_id = iDocumentID) );
        exception
          when no_data_found then
            -- document déchargés
            begin
              select DMT.ACS_FINANCIAL_CURRENCY_ID
                   , DMT.DOC_INVOICE_EXPIRY_ID
                   , DMT.DMT_RATE_OF_EXCHANGE
                   , DMT.DMT_BASE_PRICE
                   , ORIG.ACS_FINANCIAL_CURRENCY_ID
                   , ORIG.GAL_CURRENCY_RISK_VIRTUAL_ID
                   , ORIG.C_CURR_RATE_COVER_TYPE
                   , ORIG.DMT_RATE_OF_EXCHANGE
                   , ORIG.DMT_BASE_PRICE
                   , ORIG.DMT_CURR_RISK_FORCED
                into lCurrencyId
                   , lInvoiceExpiryId
                   , lRateOfExchange
                   , lBasePrice
                   , lOrigCurrencyId
                   , oRiskId
                   , oRiskType
                   , oRiskRate
                   , oRiskBase
                   , oRiskForced
                from DOC_DOCUMENT DMT
                   , DOC_DOCUMENT ORIG
               where DMT.DOC_DOCUMENT_ID = iDocumentID
                 and ORIG.DOC_DOCUMENT_ID = (select max(PDE2.DOC_DOCUMENT_ID)
                                               from DOC_POSITION_DETAIL PDE1
                                                  , DOC_POSITION_DETAIL PDE2
                                              where PDE1.DOC_DOCUMENT_ID = iDocumentID
                                                and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC_DOC_POSITION_DETAIL_ID);
            exception
              when no_data_found then
                begin
                  -- document copiés
                  select DMT.ACS_FINANCIAL_CURRENCY_ID
                       , DMT.DOC_INVOICE_EXPIRY_ID
                       , DMT.DMT_RATE_OF_EXCHANGE
                       , DMT.DMT_BASE_PRICE
                       , ORIG.ACS_FINANCIAL_CURRENCY_ID
                       , ORIG.GAL_CURRENCY_RISK_VIRTUAL_ID
                       , ORIG.C_CURR_RATE_COVER_TYPE
                       , ORIG.DMT_RATE_OF_EXCHANGE
                       , ORIG.DMT_BASE_PRICE
                       , ORIG.DMT_CURR_RISK_FORCED
                    into lCurrencyId
                       , lInvoiceExpiryId
                       , lRateOfExchange
                       , lBasePrice
                       , lOrigCurrencyId
                       , oRiskId
                       , oRiskType
                       , oRiskRate
                       , oRiskBase
                       , oRiskForced
                    from DOC_DOCUMENT DMT
                       , DOC_DOCUMENT ORIG
                   where DMT.DOC_DOCUMENT_ID = iDocumentID
                     and ORIG.DOC_DOCUMENT_ID = (select max(PDE2.DOC_DOCUMENT_ID)
                                                   from DOC_POSITION_DETAIL PDE1
                                                      , DOC_POSITION_DETAIL PDE2
                                                  where PDE1.DOC_DOCUMENT_ID = iDocumentID
                                                    and PDE2.DOC_POSITION_DETAIL_ID = PDE1.DOC2_DOC_POSITION_DETAIL_ID);
                exception
                  when no_data_found then
                    oErrorCode  := 10;
                end;
            end;
        end;
    end;

    -- tranche sur parent
    if oRiskId is not null then
      oErrorCode  := 1;
    -- monnaie parent différente
    elsif lCurrencyId <> lOrigCurrencyId then
      oErrorCode  := 2;
    -- les documents issus de l'échéancier/Décharge dans le flux  n'ont pas le même taux
    elsif    (lRateOfExchange <> oRiskRate)
          or (lBasePrice <> oRiskBase) then
      oErrorCode  := 3;
    end if;
  end GetRootDocCurrRiskData;

  /**
  * Description
  *   Indique si la position a été déchargée depuis un document porteur d'un échéancier sans décharge
  */
  function IsPosDischargedFromOnlyAmount(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
  begin
    for ltplParent in (select distinct PDE_PARENT.DOC_POSITION_ID DOC_POSITION_ID
                                     , nvl(DMT_PARENT.DMT_ONLY_AMOUNT_BILL_BOOK, 0) DMT_ONLY_AMOUNT_BILL_BOOK
                                  from DOC_POSITION_DETAIL PDE
                                     , DOC_POSITION_DETAIL PDE_PARENT
                                     , DOC_DOCUMENT DMT_PARENT
                                 where PDE.DOC_POSITION_ID = iPositionId
                                   and PDE_PARENT.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
                                   and DMT_PARENT.DOC_DOCUMENT_ID = PDE_PARENT.DOC_DOCUMENT_ID) loop
      if ltplParent.DMT_ONLY_AMOUNT_BILL_BOOK = 1 then
        return 1;
      else
        return IsPosDischargedFromOnlyAmount(ltplParent.DOC_POSITION_ID);
      end if;
    end loop;

    return 0;
  end IsPosDischargedFromOnlyAmount;

  /**
  * Description
  *   Indique si la position a été déchargée depuis un document porteur d'un échéancier sans décharge
  */
  function IsPosDischargedFromBillBook(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
  begin
    for ltplParent in (select distinct PDE_PARENT.DOC_POSITION_ID DOC_POSITION_ID
                                     , nvl(DMT_PARENT.DMT_INVOICE_EXPIRY, 0) DMT_INVOICE_EXPIRY
                                  from DOC_POSITION_DETAIL PDE
                                     , DOC_POSITION_DETAIL PDE_PARENT
                                     , DOC_DOCUMENT DMT_PARENT
                                 where PDE.DOC_POSITION_ID = iPositionId
                                   and PDE_PARENT.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
                                   and DMT_PARENT.DOC_DOCUMENT_ID = PDE_PARENT.DOC_DOCUMENT_ID) loop
      if ltplParent.DMT_INVOICE_EXPIRY = 1 then
        return 1;
      else
        return IsPosDischargedFromBillBook(ltplParent.DOC_POSITION_ID);
      end if;
    end loop;

    return 0;
  end IsPosDischargedFromBillBook;

  /**
  * Description
  *   Indique si la position appartient à un document porteur d'un échéancier sans décharge
  */
  function IsPosFromOnlyAmount(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
  begin
    return Bool2Byte(IsDocumentOnlyAmountBillBook(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION', 'DOC_DOCUMENT_ID', iPositionId) ) );
  end IsPosFromOnlyAmount;

  /**
  * Description
  *   Indique si la position représente une reprise d'accompte
  */
  function IsPosRetDeposit(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lExpiryId       DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    lFatherDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    select max(DOC_DOC_POSITION_DETAIL_ID)
      into lFatherDetailID
      from DOC_POSITION_DETAIL
     where DOC_POSITION_ID = iPositionId;

    -- si position provient d'une décharge
    if lFatherDetailId is not null then
      lExpiryId  :=
        FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION'
                                            , 'DOC_INVOICE_EXPIRY_ID'
                                            , FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL', 'DOC_POSITION_ID', lFatherDetailId)
                                             );

      -- si échéancier type acompte
      if     lExpiryId is not null
         and GetInvoiceExpiryType(lExpiryId) = '1' then
        return 1;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  end IsPosRetDeposit;

  /**
  * Description
  *   Indique si la position représente une reprise de note de crédit
  */
  function IsPosRetCreditNote5(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lExpiryId       DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    lFatherDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    lDocDocumentID  DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select max(DOC_DOC_POSITION_DETAIL_ID)
      into lFatherDetailID
      from DOC_POSITION_DETAIL
     where DOC_POSITION_ID = iPositionId;

    -- si position provient d'une décharge
    if lFatherDetailId is not null then
      lExpiryId  :=
        FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION'
                                            , 'DOC_INVOICE_EXPIRY_ID'
                                            , FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL', 'DOC_POSITION_ID', lFatherDetailId)
                                             );

      -- si échéancier type acompte
      if     lExpiryId is not null
         and GetInvoiceExpiryType(lExpiryId) in('5') then
        select doc_document_id
          into lDocDocumentID
          from doc_invoice_expiry
         where doc_invoice_expiry_id = lExpiryId;

        if DOC_I_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(lDocDocumentID) = 1 then
          return 2;
        else
          return 1;
        end if;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  end IsPosRetCreditNote5;

  /**
  * Description
  *   Indique si la position représente une reprise d'accompte
  */
  function IsPosDeposit(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lExpiryId       DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    lFatherDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    select max(DOC_DOC_POSITION_DETAIL_ID)
      into lFatherDetailID
      from DOC_POSITION_DETAIL
     where DOC_POSITION_ID = iPositionId;

    -- si position provient d'une décharge
    if lFatherDetailId is null then
      lExpiryId  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION', 'DOC_INVOICE_EXPIRY_ID', iPositionId);

      -- si échéancier type acompte
      if     lExpiryId is not null
         and GetInvoiceExpiryType(lExpiryId) = '1' then
        return 1;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  end IsPosDeposit;

  /**
  * Description
  *   Indique si la position représente une note de crédit depuis un échaéncier -> risuqe de chnage, on ne modifie pas la tranche car on doit rester couvert
  CTRL HMO
  */
  function IsPosCreditNotExpiry4_5(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lExpiryId       DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    lFatherDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    lDocDocumentID  DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select max(DOC_DOC_POSITION_DETAIL_ID)
      into lFatherDetailID
      from DOC_POSITION_DETAIL
     where DOC_POSITION_ID = iPositionId;

    -- si position provient d'une décharge
    if lFatherDetailId is null then
      lExpiryId  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION', 'DOC_INVOICE_EXPIRY_ID', iPositionId);

      -- si échéancier type note de crédit sur acompte ou sur facture
      if     lExpiryId is not null
         and (GetInvoiceExpiryType(lExpiryId) in('5', '4') ) then
        select doc_document_id
          into lDocDocumentID
          from doc_invoice_expiry
         where doc_invoice_expiry_id = lExpiryId;

        if DOC_I_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(lDocDocumentID) = 1 then
          return 2;
        else
          return 1;
        end if;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  end IsPosCreditNotExpiry4_5;

  /**
     * Description
     *   Indique si la position représente une note de crédit depuis un échaéncier -> risuqe de chnage, on ne modifie pas la tranche car on doit rester couvert
     CTRL HMO
     */
  function IsPosCreditNotExpiry6(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lExpiryId       DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
    lFatherDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    select max(DOC_DOC_POSITION_DETAIL_ID)
      into lFatherDetailID
      from DOC_POSITION_DETAIL
     where DOC_POSITION_ID = iPositionId;

    -- si position provient d'une décharge
    if lFatherDetailId is null then
      lExpiryId  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION', 'DOC_INVOICE_EXPIRY_ID', iPositionId);

      -- si échéancier type note de crédit sur acompte
      if     lExpiryId is not null
         and (GetInvoiceExpiryType(lExpiryId) in('6') ) then
        return 1;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  end IsPosCreditNotExpiry6;

  /**
  * Description
  *   Pour les documents avec échéancier sans décharge, retourne le montant solde pour le risque de change
  */
  function GetCurrRiskDischargedAmount(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lResult                    DOC_INVOICE_EXPIRY.INX_NET_VALUE_EXCL%type   := 0;
    lvAdminDomain              DOC_GAUGE.C_ADMIN_DOMAIN%type                := 0;
    gcGAL_CUR_SALE_MULTI_COVER boolean                                      := PCS.PC_CONFIG.GetBooleanConfig('GAL_CUR_SALE_MULTI_COVER');
  begin
    if IsFinalInvoiceGenerated(iDocumentId) then
      return 0;
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.GetInvoiceExpiryDocType(iDocumentId) = 3 then
      begin
        -- Infos du gabarit
        select GAU.C_ADMIN_DOMAIN
          into lvAdminDomain
          from DOC_DOCUMENT DMT
             , DOC_GAUGE GAU
         where DMT.DOC_DOCUMENT_ID = iDocumentID
           and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;
      exception
        when no_data_found then
          null;
      end;

      if    not gcGAL_CUR_SALE_MULTI_COVER
         or (    gcGAL_CUR_SALE_MULTI_COVER
             and lvAdminDomain <> '2') then
        for ltplExpiry in (select decode(GCV.C_GAL_RISK_TYPE, '4', INX_NET_VALUE_EXCL_B, INX_NET_VALUE_EXCL) INX_AMOUNT
                                , INX.C_INVOICE_EXPIRY_DOC_TYPE
                             from DOC_INVOICE_EXPIRY INX
                                , DOC_DOCUMENT DMT
                                , GAL_CURRENCY_RISK_VIRTUAL GCV
                            where INX.DOC_DOCUMENT_ID =
                                         GetInvoiceExpiryParentDoc(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_INVOICE_EXPIRY_ID', iDocumentId) )
                              and DMT.DOC_INVOICE_EXPIRY_ID = INX.DOC_INVOICE_EXPIRY_ID
                              and INX_INVOICE_GENERATED = 1
                              and DMT.GAL_CURRENCY_RISK_VIRTUAL_ID = GCV.GAL_CURRENCY_RISK_VIRTUAL_ID) loop
          if ltplExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('4') then
            lResult  := lResult + ltplExpiry.INX_AMOUNT;
          end if;
        end loop;
      end if;

      return lResult;
    else
      -- si on a affaire à un échéancier sans décharge
      if (DOC_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(iDocumentId) = 0) then
        for ltplExpiry in (select decode(GCV.C_GAL_RISK_TYPE
                                       , '4', INX_NET_VALUE_EXCL_B - nvl(INX_RET_DEPOSIT_NET_EXCL_B, 0)
                                       , INX_NET_VALUE_EXCL - nvl(INX_RET_DEPOSIT_NET_EXCL, 0)
                                        ) INX_AMOUNT
                                , INX.C_INVOICE_EXPIRY_DOC_TYPE
                                , INX.DOC_INVOICE_EXPIRY_ID
                             from DOC_INVOICE_EXPIRY INX
                                , DOC_DOCUMENT DMT
                                , GAL_CURRENCY_RISK_VIRTUAL GCV
                            where INX.DOC_DOCUMENT_ID = iDocumentId
                              and DMT.DOC_INVOICE_EXPIRY_ID = INX.DOC_INVOICE_EXPIRY_ID
                              and INX_INVOICE_GENERATED = 1
                              and DMT.GAL_CURRENCY_RISK_VIRTUAL_ID = GCV.GAL_CURRENCY_RISK_VIRTUAL_ID) loop
          -- accompte
          -- facture partielle
          -- facture finale
          if ltplExpiry.C_INVOICE_EXPIRY_DOC_TYPE in('1', '2', '3') then
            lResult  := lResult + ltplExpiry.INX_AMOUNT;
          end if;
        end loop;

        return lResult;
      else
        return 0;
      end if;
    end if;

    return 0;
  end GetCurrRiskDischargedAmount;

  /* function GetLastRiskVirtualFor4_5_6MC
     * Description
     *   Recherche le dernier documet de type facture ou acompte émis
     * @param iDocumentId : identifiant document
    * @param iDocumentId : type de document échéancés à chercher (1, acompte, 2 facture)
     * @return voir description
     */
  function GetLastRiskVirtualFor4_5_6MC(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iType in number)
    return DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  is
    lDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    if iType = 1 then
      select max(DOC_DOCUMENT_ID)
        into lDocumentId
        from DOC_POSITION
       where DOC_INVOICE_EXPIRY_ID in(
               select DOC_INVOICE_expiry_id
                 from DOC_INVOICE_EXPIRY I
                where DOC_DOCUMENT_ID =
                        DOc_INVOICE_EXPIRY_FUNCTIONS.GetInvoiceExpiryParentDoc(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT'
                                                                                                                   , 'DOC_INVOICE_EXPIRY_ID'
                                                                                                                   , iDocumentId
                                                                                                                    )
                                                                              )
                  and INX_INVOICE_GENERATED = 1
                  and C_INVOICE_EXPIRY_doc_TYPE = '1');
    else
      select max(DOC_DOCUMENT_ID)
        into lDocumentId
        from DOC_POSITION
       where DOC_INVOICE_EXPIRY_ID in(
               select DOC_INVOICE_expiry_id
                 from DOC_INVOICE_EXPIRY I
                where DOC_DOCUMENT_ID =
                        DOc_INVOICE_EXPIRY_FUNCTIONS.GetInvoiceExpiryParentDoc(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT'
                                                                                                                   , 'DOC_INVOICE_EXPIRY_ID'
                                                                                                                   , iDocumentId
                                                                                                                    )
                                                                              )
                  and INX_INVOICE_GENERATED = 1
                  and C_INVOICE_EXPIRY_doc_TYPE in('2', '3') );
    end if;

    return lDocumentId;
  end GetLastRiskVirtualFor4_5_6MC;
end DOC_INVOICE_EXPIRY_FUNCTIONS;
