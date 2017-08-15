--------------------------------------------------------
--  DDL for Package Body DOC_PRC_VAT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_VAT" 
is
  function IsPositionTtc(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_POSITION.POS_INCLUDE_TAX_TARIFF%type
  is
    lResult       DOC_POSITION.POS_INCLUDE_TAX_TARIFF%type;
    cGaugeTypPos  DOC_POSITION.C_GAUGE_TYPE_POS%type;
    docDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select POS_INCLUDE_TAX_TARIFF
         , C_GAUGE_TYPE_POS
         , DOC_DOCUMENT_ID
      into lResult
         , cGaugeTypPos
         , docDocumentID
      from DOC_POSITION
     where DOC_POSITION_ID = iPositionId;

    -- Actuellement les positions valeurs ne peuvent pas être piloté par le champ POS_INCLUDE_TAX_TARIFF.
    -- On reprend l'information sur le document.
    if (cGaugeTypPos = '5') then
      -- Recherche si au moins un gabarit position du document est geré en TTC
      lResult  := DOC_FUNCTIONS.isDocumentTTC(docDocumentID);
    end if;

    return lResult;
  end IsPositionTtc;

  -- Procedure declanchee par trigger sur la table des positions
  procedure UpdatePositionVat(
    iFootId          number
  , iGaugeTypePos    varchar2
  , iTaxCodeId       number
  , iNetValueExcl    number
  , iNetValueExclb   number
  , iNetValueExclv   number
  , iVatRate         number
  , iVatTotalAmount  number
  , iVatTotalAmountb number
  , iVatTotalAmountv number
  , iVatAmount       number
  , iVatBaseAmount   number
  , iVatAmountv      number
  , iSign            number
  )
  is
  begin
    -- Traitement si on est sur un position bien ou valeur et qu'un code taxe existe
    if     iGaugeTypePos in('1', '2', '3', '5', '7', '8', '9', '10', '71', '81', '91', '101')
       and iTaxCodeId is not null then
      -- Mise à jour des récapitulatifs TVA
      UpdateVatAccount(iFootId
                     , iTaxCodeId
                     , iNetValueExcl
                     , iNetValueExclb
                     , iNetValueExclv
                     , iVatRate
                     , iVatTotalAmount
                     , iVatTotalAmountb
                     , iVatTotalAmountv
                     , iVatAmount
                     , iVatBaseAmount
                     , iVatAmountv
                     , iSign
                      );
    end if;
  end UpdatePositionVat;

-- Procedure de mise à jour des recapitulations TVA
  procedure UpdateVatAccount(
    iFootId          number
  , iTaxCodeId       number
  , iNetAmountExcl   number
  , iNetAmountExclb  number
  , iNetAmountExclv  number
  , iVatRate         number
  , iVatTotalAmount  number
  , iVatTotalAmountb number
  , iVatTotalAmountv number
  , iVatAmount       number
  , iVatBaseAmount   number
  , iVatAmountv      number
  , iSign            number
  )
  is
    lVatDetailedAccountId number(18);
    lTaxLiabledRate       number;
    lTaxDeductibleRate    number;
  begin
    -- Mise à jour uniquement si un code taxe existe
    if iTaxCodeId is not null then
      -- Recherche si on a déjà integré l'arrondi TVA
      select max(DOC_VAT_DET_ACCOUNT_ID)
        into lVatDetailedAccountId
        from DOC_VAT_DET_ACCOUNT
       where DOC_FOOT_ID = iFootId
         and ACS_TAX_CODE_ID = iTaxCodeId
         and VDA_VAT_RATE = iVatRate
         and (   DOC_POSITION_ID is not null
              or DOC_FOOT_CHARGE_ID is not null);

      -- Si un décompte avec mise à jour du montant d'arrondi existe on n'effecute
      -- pas l'ajout ou la modification du décompte courant.
      if lVatDetailedAccountId is null then
        -- Recherche si on a déjà une position pour le pied et le code taxe
        select max(DOC_VAT_DET_ACCOUNT_ID)
          into lVatDetailedAccountId
          from DOC_VAT_DET_ACCOUNT
         where DOC_FOOT_ID = iFootId
           and ACS_TAX_CODE_ID = iTaxCodeId
           and (   VDA_VAT_RATE is null
                or VDA_VAT_RATE = 0
                or VDA_VAT_RATE = iVatRate);

        -- Recherche des taux
        select TAX_LIABLED_RATE
             , TAX_DEDUCTIBLE_RATE
          into lTaxLiabledRate
             , lTaxDeductibleRate
          from ACS_TAX_CODE
         where ACS_TAX_CODE_ID = iTaxCodeId;

        -- S'il existe un detail TVA, on le met à jour
        if lVatDetailedAccountId is not null then
          -- Mise à jour du détail TVA existant
          update DOC_VAT_DET_ACCOUNT
             set VDA_NET_AMOUNT_EXCL = VDA_NET_AMOUNT_EXCL + iSign * nvl(iNetAmountExcl, 0)
               , VDA_LIABLE_AMOUNT = VDA_LIABLE_AMOUNT + iSign * nvl(iNetAmountExcl * lTaxLiabledRate / 100, 0)
               , VDA_LIABLE_AMOUNT_B = VDA_LIABLE_AMOUNT_B + iSign * nvl(iNetAmountExclb * lTaxLiabledRate / 100, 0)
               , VDA_LIABLE_AMOUNT_V = VDA_LIABLE_AMOUNT_V + iSign * nvl(iNetAmountExclv * lTaxLiabledRate / 100, 0)
               , VDA_VAT_TOTAL_AMOUNT = VDA_VAT_TOTAL_AMOUNT + iSign * nvl(iVatTotalAmount, 0)
               , VDA_VAT_TOTAL_AMOUNT_B = VDA_VAT_TOTAL_AMOUNT_B + iSign * nvl(iVatTotalAmountb, 0)
               , VDA_VAT_TOTAL_AMOUNT_V = VDA_VAT_TOTAL_AMOUNT_V + iSign * nvl(iVatTotalAmountv, 0)
               , VDA_VAT_AMOUNT = VDA_VAT_AMOUNT + iSign * nvl(iVatAmount, 0)
               , VDA_VAT_BASE_AMOUNT = VDA_VAT_BASE_AMOUNT + iSign * nvl(iVatBaseAmount, 0)
               , VDA_VAT_AMOUNT_V = VDA_VAT_AMOUNT_V + iSign * nvl(iVatAmountv, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_VAT_DET_ACCOUNT_ID = lVatDetailedAccountId;

          -- Suppression des récapitulatifs TVA à zéro
          delete from DOC_VAT_DET_ACCOUNT
                where VDA_LIABLE_AMOUNT = 0
                  and VDA_VAT_AMOUNT = 0
                  and nvl(VDA_CORR_AMOUNT, 0) = 0
                  and DOC_VAT_DET_ACCOUNT_ID = lVatDetailedAccountId;
        elsif    (iNetAmountExcl <> 0)
              or (iVatAmount <> 0) then
          -- Insertion d'un nouveau détail TVA
          insert into DOC_VAT_DET_ACCOUNT
                      (DOC_VAT_DET_ACCOUNT_ID
                     , DOC_FOOT_ID
                     , ACS_TAX_CODE_ID
                     , VDA_NET_AMOUNT_EXCL
                     , VDA_LIABLED_RATE
                     , VDA_LIABLE_AMOUNT
                     , VDA_LIABLE_AMOUNT_B
                     , VDA_LIABLE_AMOUNT_V
                     , VDA_VAT_RATE
                     , VDA_VAT_TOTAL_AMOUNT
                     , VDA_VAT_TOTAL_AMOUNT_B
                     , VDA_VAT_TOTAL_AMOUNT_V
                     , VDA_VAT_DEDUCTIBLE_RATE
                     , VDA_VAT_AMOUNT
                     , VDA_VAT_BASE_AMOUNT
                     , VDA_VAT_AMOUNT_V
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , iFootId
                     , iTaxCodeId
                     , iSign * nvl(iNetAmountExcl, 0)
                     , nvl(lTaxLiabledRate, 0)
                     , iSign * nvl(iNetAmountExcl * lTaxLiabledRate / 100, 0)
                     , iSign * nvl(iNetAmountExclb * lTaxLiabledRate / 100, 0)
                     , iSign * nvl(iNetAmountExclv * lTaxLiabledRate / 100, 0)
                     , nvl(iVatRate, 0)
                     , iSign * nvl(iVatTotalAmount, 0)
                     , iSign * nvl(iVatTotalAmountb, 0)
                     , iSign * nvl(iVatTotalAmountv, 0)
                     , nvl(lTaxDeductibleRate, 0)
                     , iSign * nvl(iVatAmount, 0)
                     , iSign * nvl(iVatBaseAmount, 0)
                     , iSign * nvl(iVatAmountv, 0)
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;
      end if;
    end if;
  end UpdateVatAccount;

  /**
  * Description
  *     Procedure de génération de la correction d'arrondi TVA
  */
  procedure AppendVatCorrectionAmount(iDocumentId in number, iAppendRound in number default 1, iAppendCorr in number default 1, oModified out number)
  is
    cursor lcurVatDetAccount(iDocId number)
    is
      select VDA.DOC_VAT_DET_ACCOUNT_ID
           , VDA.ACS_TAX_CODE_ID
           , VDA_NET_AMOUNT_EXCL
           , VDA.VDA_LIABLE_AMOUNT
           , VDA.VDA_LIABLED_RATE
           , VDA.VDA_VAT_RATE
           , VDA.VDA_VAT_TOTAL_AMOUNT
           , VDA.VDA_VAT_TOTAL_AMOUNT_B
           , VDA.VDA_VAT_TOTAL_AMOUNT_V
           , VDA.VDA_VAT_DEDUCTIBLE_RATE
           , nvl(VDA.VDA_CORR_AMOUNT, 0) VDA_CORR_AMOUNT
           , nvl(VDA.VDA_CORR_AMOUNT_B, 0) VDA_CORR_AMOUNT_B
           , nvl(VDA.VDA_CORR_AMOUNT_V, 0) VDA_CORR_AMOUNT_V
           , nvl(VDA.VDA_CORRECTED, 0) VDA_CORRECTED
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_DATE_VALUE
           , DMT.DMT_DATE_DELIVERY
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.DMT_VAT_EXCHANGE_RATE
           , DMT.DMT_VAT_BASE_PRICE
           , ACS_FUNCTION.GetEuroCurrency EURO_FINANCIAL_CURRENCY_ID
        from DOC_DOCUMENT DMT
           , DOC_VAT_DET_ACCOUNT VDA
       where DMT.DOC_DOCUMENT_ID = iDocId
         and VDA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
         and VDA.DOC_POSITION_ID is null
         and VDA.DOC_FOOT_CHARGE_ID is null;

    lTplVatDetAccount        lcurVatDetAccount%rowtype;
    lFootChargeId            DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type;
    lPositionId              DOC_POSITION.DOC_POSITION_ID%type;
    lIncludeTaxTariffInitial number(1);
    lIncludeTaxTariff        number(1);
    lValueQuantity           number(1);
    lVatAmountRound          DOC_VAT_DET_ACCOUNT.VDA_VAT_TOTAL_AMOUNT%type;
    lRoundAmount             DOC_VAT_DET_ACCOUNT.VDA_ROUND_AMOUNT%type;
    lRoundAmountb            DOC_VAT_DET_ACCOUNT.VDA_ROUND_AMOUNT%type;
    lRoundAmountv            DOC_VAT_DET_ACCOUNT.VDA_ROUND_AMOUNT%type;
    lFinRoundType            ACS_TAX_CODE.C_ROUND_TYPE%type;
    lFinRoundAmount          ACS_TAX_CODE.TAX_ROUNDED_AMOUNT%type;
    lDocRoundType            ACS_TAX_CODE.C_ROUND_TYPE_DOC%type;
    lDocRoundAmount          ACS_TAX_CODE.TAX_ROUNDED_AMOUNT_DOC%type;
    lFooRoundType            ACS_TAX_CODE.C_ROUND_TYPE_DOC_FOO%type;
    lFooRoundAmount          ACS_TAX_CODE.TAX_ROUNDED_AMOUNT_DOC_FOO%type;

    -- procédure interne retournant soit l'id de la remise/taxe de pied soit de la position
    -- sur laquelle on va reporter la correction TVA
    procedure GetReportId(iDocumentId in number, iTaxCodeId in number, iVatRate in number, oFootChargeId out number, oPositionId out number)
    is
      lFchVatAmount DOC_FOOT_CHARGE.FCH_VAT_TOTAL_AMOUNT%type;
      lPosVatAmount DOC_POSITION.POS_VAT_TOTAL_AMOUNT%type;
    begin
      -- recherche de la remise/taxe de pied ayant le plus grand montant (en valeur absolue)
      -- pour un compte TVA donné
      select max(FCH.DOC_FOOT_CHARGE_ID)
           , max(FCH.FCH_VAT_TOTAL_AMOUNT)
        into oFootChargeId
           , lFchVatAmount
        from DOC_FOOT_CHARGE FCH
       where FCH.DOC_FOOT_ID = iDocumentId
         and FCH.ACS_TAX_CODE_ID = iTaxCodeId
         and FCH.FCH_VAT_RATE = iVatRate
         and FCH.FCH_VAT_TOTAL_AMOUNT <> 0
         and abs(FCH.FCH_VAT_TOTAL_AMOUNT) =
                            (select max(abs(FCH2.FCH_VAT_TOTAL_AMOUNT) )
                               from DOC_FOOT_CHARGE FCH2
                              where FCH2.DOC_FOOT_ID = iDocumentId
                                and FCH2.FCH_VAT_RATE = iVatRate
                                and FCH2.ACS_TAX_CODE_ID = lTplVatDetAccount.ACS_TAX_CODE_ID);

      -- recherche de la position ayant le plus grand montant (en valeur absolue)
      -- pour un compte TVA donné
      select max(POS.DOC_POSITION_ID)
           , max(POS.POS_VAT_TOTAL_AMOUNT)
        into oPositionId
           , lPosVatAmount
        from DOC_POSITION POS
       where POS.DOC_DOCUMENT_ID = iDocumentId
         and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '5', '7', '8', '9', '10', '71', '81', '91', '101', '21')
         and POS.ACS_TAX_CODE_ID = iTaxCodeId
         and POS.POS_VAT_RATE = iVatRate
         and abs(POS.POS_VAT_TOTAL_AMOUNT) =
               (select max(abs(POS2.POS_VAT_TOTAL_AMOUNT) )
                  from DOC_POSITION POS2
                 where POS2.DOC_DOCUMENT_ID = iDocumentId
                   and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '5', '7', '8', '9', '10', '71', '81', '91', '101', '21')
                   and POS2.ACS_TAX_CODE_ID = iTaxCodeId
                   and POS2.POS_VAT_RATE = iVatRate);

      if     oPositionId is not null
         and oFootChargeId is not null then
        if lFchVatAmount >= lPosVatAmount then
          oPositionId  := null;
        else
          oFootChargeId  := null;
        end if;
      end if;
    end GetReportId;
  begin
    --initialisation valeur de retour
    oModified                 := 0;
    -- Recherche si au moins un gabarit position du document est geré en TTC
    lIncludeTaxTariffInitial  := DOC_FUNCTIONS.isDocumentTTC(iDocumentId);

    -- Faut-il effectuer la correction d'arrondi TVA uniquement sur un document HT ? Non, c'est le code TVA qui pilote la gestion d'arrondi
    -- if lIncludeTaxTariff = 0 then
    if true then
      open lcurVatDetAccount(iDocumentId);

      fetch lcurVatDetAccount
       into lTplVatDetAccount;

      -- pour chaque détail
      while lcurVatDetAccount%found loop
        -- Utilise par défaut l'indicateur TTC du document
        lIncludeTaxTariff  := lIncludeTaxTariffInitial;

        -- Mode correction manuelle
        if     iAppendCorr = 1
           and (   lTplVatDetAccount.VDA_CORR_AMOUNT <> 0
                or lTplVatDetAccount.VDA_CORR_AMOUNT_B <> 0
                or lTplVatDetAccount.VDA_CORR_AMOUNT_V <> 0
                or lTplVatDetAccount.VDA_CORRECTED <> 0
               ) then
          oModified  := 1;
          GetReportId(iDocumentId, lTplVatDetAccount.ACS_TAX_CODE_ID, lTplVatDetAccount.VDA_VAT_RATE, lFootChargeId, lPositionId);

          if lPositionId is not null then
            -- Recherche d'information dans le gabarit position
            select GAP_VALUE_QUANTITY
              into lValueQuantity
              from DOC_POSITION POS
                 , DOC_GAUGE_POSITION GAP
             where GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
               and POS.DOC_POSITION_ID = lPositionId;

            lIncludeTaxTariff  := IsPositionTtc(lPositionId);
          end if;

          -- mise à jour du décompte
          update DOC_VAT_DET_ACCOUNT VDA
             set VDA.VDA_VAT_TOTAL_AMOUNT = VDA.VDA_VAT_TOTAL_AMOUNT + lTplVatDetAccount.VDA_CORR_AMOUNT
               , VDA.VDA_VAT_TOTAL_AMOUNT_B = VDA.VDA_VAT_TOTAL_AMOUNT_B + lTplVatDetAccount.VDA_CORR_AMOUNT_B
               , VDA.VDA_VAT_TOTAL_AMOUNT_V = VDA.VDA_VAT_TOTAL_AMOUNT_V + lTplVatDetAccount.VDA_CORR_AMOUNT_V
               , VDA.VDA_VAT_AMOUNT = (VDA.VDA_VAT_TOTAL_AMOUNT + lTplVatDetAccount.VDA_CORR_AMOUNT) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
               , VDA.VDA_VAT_BASE_AMOUNT = (VDA.VDA_VAT_TOTAL_AMOUNT_B + lTplVatDetAccount.VDA_CORR_AMOUNT_B) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
               , VDA.VDA_VAT_AMOUNT_V = (VDA.VDA_VAT_TOTAL_AMOUNT_V + lTplVatDetAccount.VDA_CORR_AMOUNT_V) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
               , VDA.VDA_LIABLE_AMOUNT =
                           VDA.VDA_LIABLE_AMOUNT - decode(lIncludeTaxTariff
                                                        , 0, 0
                                                        , lTplVatDetAccount.VDA_CORR_AMOUNT * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                                                         )
               , VDA.VDA_LIABLE_AMOUNT_B =
                       VDA.VDA_LIABLE_AMOUNT_B - decode(lIncludeTaxTariff
                                                      , 0, 0
                                                      , lTplVatDetAccount.VDA_CORR_AMOUNT_B * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                                                       )
               , VDA.VDA_LIABLE_AMOUNT_V =
                       VDA.VDA_LIABLE_AMOUNT_V - decode(lIncludeTaxTariff
                                                      , 0, 0
                                                      , lTplVatDetAccount.VDA_CORR_AMOUNT_V * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                                                       )
               , VDA.VDA_NET_AMOUNT_EXCL = VDA.VDA_NET_AMOUNT_EXCL - decode(lIncludeTaxTariff, 0, 0, lTplVatDetAccount.VDA_CORR_AMOUNT)
               , VDA.DOC_POSITION_ID = lPositionId
               , VDA.DOC_FOOT_CHARGE_ID = lFootChargeId
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where VDA.DOC_VAT_DET_ACCOUNT_ID = lTplVatDetAccount.DOC_VAT_DET_ACCOUNT_ID;

          -- correction sur une remises/taxe de pied
          if lFootChargeId is not null then
            if lIncludeTaxTariff = 1 then   -- TTC
              update DOC_FOOT_CHARGE
                 set FCH_VAT_TOTAL_AMOUNT = FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT
                   , FCH_VAT_TOTAL_AMOUNT_B = FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_B
                   , FCH_VAT_TOTAL_AMOUNT_V = FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_V
                   , FCH_VAT_AMOUNT =
                       (FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT) *
                       lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE /
                       100
                   , FCH_VAT_BASE_AMOUNT =
                       (FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_B) *
                       lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE /
                       100
                   , FCH_VAT_AMOUNT_V =
                       (FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_V) *
                       lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE /
                       100
                   , FCH_VAT_LIABLED_AMOUNT =
                       FCH_VAT_LIABLED_AMOUNT -
                       decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                   , FCH_EXCL_AMOUNT = FCH_EXCL_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT
                   , FCH_EXCL_AMOUNT_B = FCH_EXCL_AMOUNT_B - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_B
                   , FCH_EXCL_AMOUNT_V = FCH_EXCL_AMOUNT_V - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_V
               where DOC_FOOT_CHARGE_ID = lFootChargeId;
            else   -- HT
              update DOC_FOOT_CHARGE
                 set FCH_VAT_TOTAL_AMOUNT = FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT
                   , FCH_VAT_TOTAL_AMOUNT_B = FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_B
                   , FCH_VAT_TOTAL_AMOUNT_V = FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_V
                   , FCH_VAT_AMOUNT =
                       (FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT) *
                       lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE /
                       100
                   , FCH_VAT_BASE_AMOUNT =
                       (FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_B) *
                       lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE /
                       100
                   , FCH_VAT_AMOUNT_V =
                       (FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_V) *
                       lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE /
                       100
                   , FCH_INCL_AMOUNT =
                          FCH_INCL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT / lTplVatDetAccount.VDA_LIABLED_RATE
                                            * 100
                   , FCH_INCL_AMOUNT_B =
                       FCH_INCL_AMOUNT_B
                       + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_B / lTplVatDetAccount.VDA_LIABLED_RATE * 100
                   , FCH_INCL_AMOUNT_V =
                       FCH_INCL_AMOUNT_V
                       + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lTplVatDetAccount.VDA_CORR_AMOUNT_V / lTplVatDetAccount.VDA_LIABLED_RATE * 100
               where DOC_FOOT_CHARGE_ID = lFootChargeId;
            end if;
          elsif lPositionId is not null then
            -- Mise à jour de la position de report d'erreur
            if (lIncludeTaxTariff = 1) then   /* Tarif TTC */
              update DOC_POSITION
                 set POS_VAT_TOTAL_AMOUNT = POS_VAT_TOTAL_AMOUNT + lTplVatDetAccount.VDA_CORR_AMOUNT
                   , POS_VAT_TOTAL_AMOUNT_B = POS_VAT_TOTAL_AMOUNT_B + lTplVatDetAccount.VDA_CORR_AMOUNT_B
                   , POS_VAT_TOTAL_AMOUNT_V = POS_VAT_TOTAL_AMOUNT_V + lTplVatDetAccount.VDA_CORR_AMOUNT_V
                   , POS_VAT_AMOUNT = (POS_VAT_TOTAL_AMOUNT + lTplVatDetAccount.VDA_CORR_AMOUNT) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                   , POS_VAT_BASE_AMOUNT = (POS_VAT_TOTAL_AMOUNT_B + lTplVatDetAccount.VDA_CORR_AMOUNT_B) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                   , POS_VAT_AMOUNT_V = (POS_VAT_TOTAL_AMOUNT_V + lTplVatDetAccount.VDA_CORR_AMOUNT_V) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                   , POS_VAT_LIABLED_AMOUNT = POS_VAT_LIABLED_AMOUNT - lTplVatDetAccount.VDA_CORR_AMOUNT * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                   , POS_NET_VALUE_EXCL = POS_NET_VALUE_EXCL - lTplVatDetAccount.VDA_CORR_AMOUNT
                   , POS_NET_VALUE_EXCL_B = POS_NET_VALUE_EXCL_B - lTplVatDetAccount.VDA_CORR_AMOUNT_B
                   , POS_NET_VALUE_EXCL_V = POS_NET_VALUE_EXCL_V - lTplVatDetAccount.VDA_CORR_AMOUNT_V
                   , POS_NET_UNIT_VALUE =
                       decode(decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                            , 0, POS_NET_VALUE_EXCL - lTplVatDetAccount.VDA_CORR_AMOUNT
                            , (POS_NET_VALUE_EXCL - lTplVatDetAccount.VDA_CORR_AMOUNT) / decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                             )
               where DOC_POSITION_ID = lPositionId;
            elsif(lIncludeTaxTariff = 0) then   /* Tarif HT */
              update DOC_POSITION
                 set POS_VAT_TOTAL_AMOUNT = POS_VAT_TOTAL_AMOUNT + lTplVatDetAccount.VDA_CORR_AMOUNT
                   , POS_VAT_TOTAL_AMOUNT_B = POS_VAT_TOTAL_AMOUNT_B + lTplVatDetAccount.VDA_CORR_AMOUNT_B
                   , POS_VAT_TOTAL_AMOUNT_V = POS_VAT_TOTAL_AMOUNT_V + lTplVatDetAccount.VDA_CORR_AMOUNT_V
                   , POS_VAT_AMOUNT = (POS_VAT_TOTAL_AMOUNT + lTplVatDetAccount.VDA_CORR_AMOUNT) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                   , POS_VAT_BASE_AMOUNT = (POS_VAT_TOTAL_AMOUNT_B + lTplVatDetAccount.VDA_CORR_AMOUNT_B) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                   , POS_VAT_AMOUNT_V = (POS_VAT_TOTAL_AMOUNT_V + lTplVatDetAccount.VDA_CORR_AMOUNT_V) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                   , POS_NET_VALUE_INCL = POS_NET_VALUE_INCL + lTplVatDetAccount.VDA_CORR_AMOUNT / lTplVatDetAccount.VDA_LIABLED_RATE * 100
                   , POS_NET_VALUE_INCL_B = POS_NET_VALUE_INCL_B + lTplVatDetAccount.VDA_CORR_AMOUNT_B / lTplVatDetAccount.VDA_LIABLED_RATE * 100
                   , POS_NET_VALUE_INCL_V = POS_NET_VALUE_INCL_V + lTplVatDetAccount.VDA_CORR_AMOUNT_V / lTplVatDetAccount.VDA_LIABLED_RATE * 100
                   , POS_NET_UNIT_VALUE_INCL =
                       decode(decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                            , 0, POS_NET_VALUE_INCL + lTplVatDetAccount.VDA_CORR_AMOUNT / lTplVatDetAccount.VDA_LIABLED_RATE * 100
                            , (POS_NET_VALUE_INCL + lTplVatDetAccount.VDA_CORR_AMOUNT / lTplVatDetAccount.VDA_LIABLED_RATE * 100) /
                              decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                             )
               where DOC_POSITION_ID = lPositionId;
            end if;
          end if;
        -- Correction automatique du montant TVA
        elsif iAppendRound = 1 then
          -- Recherche le type d'arrondi du décompte TVA en fonction du code TVA
          ACS_FUNCTION.GetRoundInfo(lTplVatDetAccount.ACS_TAX_CODE_ID
                                  , lFinRoundType
                                  , lFinRoundAmount
                                  , lDocRoundType
                                  , lDocRoundAmount
                                  , lFooRoundType
                                  , lFooRoundAmount
                                   );

          -- Aucun arrondi ne sera appliquer si le type d'arrondi du décompte TVA est à 0 (pas d'arrondi) et 3 (arrondi au plus près à 0.01).
          if    (lFooRoundType = '0')
             or (     (lFooRoundType = '3')
                 and (lFooRoundAmount = 0.01) ) then
            -- Aucune correction ne s'applique pour le code TVA courant. On utilise la somme des montants de TVA directement.
            lVatAmountRound  := lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT;
          else
            -- Calcul le montant de TVA en fonction des méthodes d'arrondi du code TVA
            lVatAmountRound  :=
              ACS_FUNCTION.CalcVatAmount(lTplVatDetAccount.VDA_NET_AMOUNT_EXCL
                                       , lTplVatDetAccount.ACS_TAX_CODE_ID
                                       , 'E'
                                       , lTplVatDetAccount.VDA_VAT_RATE
                                       , 3   -- Arrondi "Décompte TVA" document logistique demandé
                                        );
          end if;

          if (lVatAmountRound - lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT) <> 0 then
            oModified     := 1;
            -- Montant de correction en monnaie de document.
            lRoundAmount  :=(lVatAmountRound - lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT);

            -- Différents cas de monnaies
            -- cas n° 1 : CHF - CHF - CHF
            -- cas n° 2 : CHF - EUR - CHF
            -- cas n° 3 : CHF - EUR - EUR
            -- cas n° 4 : CHF - CHF - EUR
            -- cas n° 5 : CHF - USD - EUR

            -- cas n° 1 : CHF - CHF - CHF
            if     (ACS_FUNCTION.getlocalcurrencyid = lTplVatDetAccount.ACS_FINANCIAL_CURRENCY_ID)
               and (lTplVatDetAccount.ACS_FINANCIAL_CURRENCY_ID = lTplVatDetAccount.ACS_ACS_FINANCIAL_CURRENCY_ID) then
              lRoundAmountb  := lVatAmountRound - lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT_B;
              lRoundAmountv  := lRoundAmountb;
            -- cas n° 2 : CHF - EUR - CHF
            elsif     (acs_function.getlocalcurrencyid = lTplVatDetAccount.ACS_ACS_FINANCIAL_CURRENCY_ID)
                  and (lTplVatDetAccount.ACS_FINANCIAL_CURRENCY_ID <> lTplVatDetAccount.ACS_ACS_FINANCIAL_CURRENCY_ID) then
              -- Montant de l'arrondi en monnaie TVA
              lRoundAmountv  :=
                ACS_FUNCTION.ConvertAmountForView(lVatAmountRound
                                                , lTplVatDetAccount.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , lTplVatDetAccount.ACS_FINANCIAL_CURRENCY_ID
                                                , lTplVatDetAccount.DMT_DATE_DOCUMENT
                                                , lTplVatDetAccount.DMT_VAT_BASE_PRICE
                                                , lTplVatDetAccount.DMT_VAT_EXCHANGE_RATE
                                                , 0
                                                 ) -
                lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT_V;
              -- Montant de l'arrondi en monnaie de Base
              lRoundAmountb  := lRoundAmountv;
            -- cas n° 3 : CHF - EUR - EUR
            elsif     (acs_function.getlocalcurrencyid <> lTplVatDetAccount.acs_financial_currency_id)
                  and (lTplVatDetAccount.acs_financial_currency_id = lTplVatDetAccount.acs_acs_financial_currency_id) then
              -- Montant de l'arrondi en monnaie de Base
              lRoundAmountb  :=
                ACS_FUNCTION.ConvertAmountForView(lVatAmountRound
                                                , lTplVatDetAccount.ACS_FINANCIAL_CURRENCY_ID
                                                , acs_function.getlocalcurrencyid
                                                , lTplVatDetAccount.DMT_DATE_DOCUMENT
                                                , lTplVatDetAccount.DMT_VAT_EXCHANGE_RATE
                                                , lTplVatDetAccount.DMT_VAT_BASE_PRICE
                                                , 0
                                                 ) -
                lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT_B;
              -- Montant de l'arrondi en monnaie TVA
              lRoundAmountv  := lVatAmountRound - lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT_V;
            else
              -- cas n° 4 : CHF - CHF - EUR
              -- cas n° 5 : CHF - USD - EUR
                -- calcul du montant d'arrondi dans les autres monnaies
              lRoundAmountb  :=
                ACS_FUNCTION.ConvertAmountForView(lVatAmountRound
                                                , lTplVatDetAccount.ACS_FINANCIAL_CURRENCY_ID
                                                , ACS_FUNCTION.getlocalcurrencyid
                                                , lTplVatDetAccount.DMT_DATE_DOCUMENT
                                                , lTplVatDetAccount.DMT_RATE_OF_EXCHANGE
                                                , lTplVatDetAccount.DMT_BASE_PRICE
                                                , 0
                                                 );
              -- Montant en monnaie TVA
              lRoundAmountv  :=
                ACS_FUNCTION.ConvertAmountForView(lRoundAmountb
                                                , ACS_FUNCTION.getlocalcurrencyid
                                                , lTplVatDetAccount.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , lTplVatDetAccount.DMT_DATE_DOCUMENT
                                                , lTplVatDetAccount.DMT_VAT_EXCHANGE_RATE
                                                , lTplVatDetAccount.DMT_VAT_BASE_PRICE
                                                , 0
                                                 ) -
                lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT_V;
              -- Ce traitement est fait après la conversion en monnaie TVA
              -- car il me faut le montant en monnaie Base pour convertir en monnaie TVA
              lRoundAmountb  := lRoundAmountb - lTplVatDetAccount.VDA_VAT_TOTAL_AMOUNT_B;
            end if;

            -- recherche de la taxe de pied ou de la position sur laquelle on va reporter la modification
            -- on a automatiquement l'un ou l'autre sinon il n'y aurait pas de décompte
            GetReportId(iDocumentId, lTplVatDetAccount.ACS_TAX_CODE_ID, lTplVatDetAccount.VDA_VAT_RATE, lFootChargeId, lPositionId);

            if lPositionId is not null then
              -- Recherche d'information dans le gabarit position
              select GAP_VALUE_QUANTITY
                into lValueQuantity
                from DOC_POSITION POS
                   , DOC_GAUGE_POSITION GAP
               where GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                 and POS.DOC_POSITION_ID = lPositionId;

              lIncludeTaxTariff  := IsPositionTtc(lPositionId);
            end if;

            -- mise à jour du décompte
            update DOC_VAT_DET_ACCOUNT VDA
               set VDA.VDA_VAT_TOTAL_AMOUNT = VDA.VDA_VAT_TOTAL_AMOUNT + lRoundAmount
                 , VDA.VDA_VAT_TOTAL_AMOUNT_B = VDA.VDA_VAT_TOTAL_AMOUNT_B + lRoundAmountb
                 , VDA.VDA_VAT_TOTAL_AMOUNT_V = VDA.VDA_VAT_TOTAL_AMOUNT_V + lRoundAmountv
                 , VDA.VDA_VAT_AMOUNT = (VDA.VDA_VAT_TOTAL_AMOUNT + lRoundAmount) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                 , VDA.VDA_VAT_BASE_AMOUNT = (VDA.VDA_VAT_TOTAL_AMOUNT_B + lRoundAmountb) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                 , VDA.VDA_VAT_AMOUNT_V = (VDA.VDA_VAT_TOTAL_AMOUNT_V + lRoundAmountv) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                 , VDA.VDA_LIABLE_AMOUNT = VDA.VDA_LIABLE_AMOUNT - decode(lIncludeTaxTariff, 0, 0, lRoundAmount) * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                 , VDA.VDA_LIABLE_AMOUNT_B = VDA.VDA_LIABLE_AMOUNT_B - decode(lIncludeTaxTariff, 0, 0, lRoundAmountb) * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                 , VDA.VDA_LIABLE_AMOUNT_V = VDA.VDA_LIABLE_AMOUNT_V - decode(lIncludeTaxTariff, 0, 0, lRoundAmountv) * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                 , VDA.VDA_NET_AMOUNT_EXCL = VDA.VDA_NET_AMOUNT_EXCL - decode(lIncludeTaxTariff, 0, 0, lRoundAmount)
                 , VDA.VDA_ROUND_AMOUNT = lRoundAmount
                 , VDA.DOC_POSITION_ID = lPositionId
                 , VDA.DOC_FOOT_CHARGE_ID = lFootChargeId
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where VDA.DOC_VAT_DET_ACCOUNT_ID = lTplVatDetAccount.DOC_VAT_DET_ACCOUNT_ID;

            if lFootChargeId is not null then
              if lIncludeTaxTariff = 1 then   -- TTC
                update DOC_FOOT_CHARGE
                   set FCH_VAT_TOTAL_AMOUNT = FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmount
                     , FCH_VAT_TOTAL_AMOUNT_B = FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountb
                     , FCH_VAT_TOTAL_AMOUNT_V = FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountv
                     , FCH_VAT_AMOUNT =
                                  (FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmount) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE
                                  / 100
                     , FCH_VAT_BASE_AMOUNT =
                               (FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountb) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE
                               / 100
                     , FCH_VAT_AMOUNT_V =
                               (FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountv) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE
                               / 100
                     , FCH_VAT_LIABLED_AMOUNT =
                                        FCH_VAT_LIABLED_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmount * lTplVatDetAccount.VDA_LIABLED_RATE
                                                                 / 100
                     , FCH_EXCL_AMOUNT = FCH_EXCL_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmount
                     , FCH_EXCL_AMOUNT_B = FCH_EXCL_AMOUNT_B - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountb
                     , FCH_EXCL_AMOUNT_V = FCH_EXCL_AMOUNT_V - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountv
                 where DOC_FOOT_CHARGE_ID = lFootChargeId;
              else   -- HT
                update DOC_FOOT_CHARGE
                   set FCH_VAT_TOTAL_AMOUNT = FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmount
                     , FCH_VAT_TOTAL_AMOUNT_B = FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountb
                     , FCH_VAT_TOTAL_AMOUNT_V = FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountv
                     , FCH_VAT_AMOUNT =
                                  (FCH_VAT_TOTAL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmount) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE
                                  / 100
                     , FCH_VAT_BASE_AMOUNT =
                               (FCH_VAT_TOTAL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountb) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE
                               / 100
                     , FCH_VAT_AMOUNT_V =
                               (FCH_VAT_TOTAL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountv) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE
                               / 100
                     , FCH_INCL_AMOUNT = FCH_INCL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmount / lTplVatDetAccount.VDA_LIABLED_RATE * 100
                     , FCH_INCL_AMOUNT_B = FCH_INCL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountb / lTplVatDetAccount.VDA_LIABLED_RATE
                                                               * 100
                     , FCH_INCL_AMOUNT_V = FCH_INCL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * lRoundAmountv / lTplVatDetAccount.VDA_LIABLED_RATE
                                                               * 100
                 where DOC_FOOT_CHARGE_ID = lFootChargeId;
              end if;
            elsif lPositionId is not null then
              -- Mise à jour de la position de report d'erreur
              if (lIncludeTaxTariff = 1) then   /* Tarif TTC */
                update DOC_POSITION
                   set POS_VAT_TOTAL_AMOUNT = POS_VAT_TOTAL_AMOUNT + lRoundAmount
                     , POS_VAT_TOTAL_AMOUNT_B = POS_VAT_TOTAL_AMOUNT_B + lRoundAmountb
                     , POS_VAT_TOTAL_AMOUNT_V = POS_VAT_TOTAL_AMOUNT_V + lRoundAmountv
                     , POS_VAT_AMOUNT = (POS_VAT_TOTAL_AMOUNT + lRoundAmount) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                     , POS_VAT_BASE_AMOUNT = (POS_VAT_TOTAL_AMOUNT_B + lRoundAmountb) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                     , POS_VAT_AMOUNT_V = (POS_VAT_TOTAL_AMOUNT_V + lRoundAmountv) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                     , POS_VAT_LIABLED_AMOUNT = POS_VAT_LIABLED_AMOUNT - lRoundAmount * lTplVatDetAccount.VDA_LIABLED_RATE / 100
                     , POS_NET_VALUE_EXCL = POS_NET_VALUE_EXCL - lRoundAmount
                     , POS_NET_VALUE_EXCL_B = POS_NET_VALUE_EXCL_B - lRoundAmountb
                     , POS_NET_VALUE_EXCL_V = POS_NET_VALUE_EXCL_V - lRoundAmountv
                     , POS_NET_UNIT_VALUE =
                         decode(decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                              , 0, POS_NET_VALUE_EXCL - lRoundAmount
                              , (POS_NET_VALUE_EXCL - lRoundAmount) / decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                               )
                 where DOC_POSITION_ID = lPositionId;
              elsif(lIncludeTaxTariff = 0) then   /* Tarif HT */
                update DOC_POSITION
                   set POS_VAT_TOTAL_AMOUNT = POS_VAT_TOTAL_AMOUNT + lRoundAmount
                     , POS_VAT_TOTAL_AMOUNT_B = POS_VAT_TOTAL_AMOUNT_B + lRoundAmountb
                     , POS_VAT_TOTAL_AMOUNT_V = POS_VAT_TOTAL_AMOUNT_V + lRoundAmountv
                     , POS_VAT_AMOUNT = (POS_VAT_TOTAL_AMOUNT + lRoundAmount) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                     , POS_VAT_BASE_AMOUNT = (POS_VAT_TOTAL_AMOUNT_B + lRoundAmountb) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                     , POS_VAT_AMOUNT_V = (POS_VAT_TOTAL_AMOUNT_V + lRoundAmountv) * lTplVatDetAccount.VDA_VAT_DEDUCTIBLE_RATE / 100
                     , POS_NET_VALUE_INCL = POS_NET_VALUE_INCL + lRoundAmount
                     , POS_NET_VALUE_INCL_B = POS_NET_VALUE_INCL_B + lRoundAmountb
                     , POS_NET_VALUE_INCL_V = POS_NET_VALUE_INCL_V + lRoundAmountv
                     , POS_NET_UNIT_VALUE_INCL =
                         decode(decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                              , 0, POS_NET_VALUE_INCL + lRoundAmount
                              , (POS_NET_VALUE_INCL + lRoundAmount) / decode(lValueQuantity, 1, POS_VALUE_QUANTITY, POS_BASIS_QUANTITY)
                               )
                 where DOC_POSITION_ID = lPositionId;
              end if;
            end if;
          end if;
        end if;

        fetch lcurVatDetAccount
         into lTplVatDetAccount;

        lFootChargeId      := null;
        lPositionId        := null;
      end loop;

      close lcurVatDetAccount;
    end if;   -- lIncludeTaxTariff = 0

    if oModified = 1 then
      begin
        update DOC_DOCUMENT
           set DMT_RECALC_TOTAL = 1
         where DOC_DOCUMENT_ID = iDocumentId;
      end;
    end if;
  end AppendVatCorrectionAmount;

  /**
  * procedure RemoveCorrectionAmount
  * Description
  *     Procedure de suppression des montants de corrections contenus dans DOC_VAT_DET_ACCOUNT
  *     (VDA_CORR_AMOUNT... et VDA_ROUND_AMOUNT)
  */
  procedure RemoveVatCorrectionAmount(iDocumentId in number, iRemoveRound in number default 1, iRemoveCorr in number default 1, oModified out number)
  is
    cursor lcurVatCorrection(iDocId number)
    is
      select VDA.DOC_VAT_DET_ACCOUNT_ID
           , VDA.VDA_VAT_TOTAL_AMOUNT
           , VDA.VDA_VAT_TOTAL_AMOUNT_B
           , VDA.VDA_VAT_TOTAL_AMOUNT_V
           , VDA.VDA_LIABLED_RATE
           , VDA.VDA_VAT_DEDUCTIBLE_RATE
           , nvl(VDA.VDA_ROUND_AMOUNT, 0) VDA_ROUND_AMOUNT
           , round(decode(DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                        , ACS_FUNCTION.getLocalCurrencyId, ACS_FUNCTION.ConvertAmountForView(VDA_VAT_TOTAL_AMOUNT + nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                                                                           , ACS_FUNCTION.getlocalcurrencyid
                                                                                           , DMT.ACS_FINANCIAL_CURRENCY_ID
                                                                                           , DMT.DMT_DATE_DOCUMENT
                                                                                           , DMT.DMT_VAT_BASE_PRICE
                                                                                           , DMT.DMT_VAT_EXCHANGE_RATE
                                                                                           , 0
                                                                                            )
                        , decode(DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                               , DMT.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.ConvertAmountForView(VDA_VAT_TOTAL_AMOUNT + nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                                                                                , DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                                                                , ACS_FUNCTION.getlocalcurrencyid
                                                                                                , DMT.DMT_DATE_DOCUMENT
                                                                                                , DMT.DMT_VAT_EXCHANGE_RATE
                                                                                                , DMT.DMT_VAT_BASE_PRICE
                                                                                                , 0
                                                                                                 )
                               , ACS_FUNCTION.ConvertAmountForView(VDA_VAT_TOTAL_AMOUNT + nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                                                 , DMT.ACS_FINANCIAL_CURRENCY_ID
                                                                 , ACS_FUNCTION.getlocalcurrencyid
                                                                 , DMT.DMT_DATE_DOCUMENT
                                                                 , DMT.DMT_RATE_OF_EXCHANGE
                                                                 , DMT.DMT_BASE_PRICE
                                                                 , 0
                                                                  )
                                )
                         )
                 , 2
                  ) -
             VDA_VAT_TOTAL_AMOUNT_B VDA_ROUND_AMOUNT_B
           , decode(DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                  , DMT.ACS_FINANCIAL_CURRENCY_ID, VDA_VAT_TOTAL_AMOUNT + nvl(VDA.VDA_ROUND_AMOUNT, 0)
                  , ACS_FUNCTION.ConvertAmountForView(round(decode(DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                                 , ACS_FUNCTION.getLocalCurrencyId, ACS_FUNCTION.ConvertAmountForView
                                                                                                                               (VDA_VAT_TOTAL_AMOUNT +
                                                                                                                                nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                                                                                                              , ACS_FUNCTION.getlocalcurrencyid
                                                                                                                              , DMT.ACS_FINANCIAL_CURRENCY_ID
                                                                                                                              , DMT.DMT_DATE_DOCUMENT
                                                                                                                              , DMT.DMT_VAT_BASE_PRICE
                                                                                                                              , DMT.DMT_VAT_EXCHANGE_RATE
                                                                                                                              , 0
                                                                                                                               )
                                                                 , decode(DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                                        , DMT.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.ConvertAmountForView
                                                                                                                             (VDA_VAT_TOTAL_AMOUNT +
                                                                                                                              nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                                                                                                            , DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                                                                                            , ACS_FUNCTION.getlocalcurrencyid
                                                                                                                            , DMT.DMT_DATE_DOCUMENT
                                                                                                                            , DMT.DMT_VAT_BASE_PRICE
                                                                                                                            , DMT.DMT_VAT_EXCHANGE_RATE
                                                                                                                            , 0
                                                                                                                             )
                                                                        , ACS_FUNCTION.ConvertAmountForView(VDA_VAT_TOTAL_AMOUNT + nvl(VDA.VDA_ROUND_AMOUNT, 0)
                                                                                                          , DMT.ACS_FINANCIAL_CURRENCY_ID
                                                                                                          , ACS_FUNCTION.getlocalcurrencyid
                                                                                                          , DMT.DMT_DATE_DOCUMENT
                                                                                                          , DMT.DMT_RATE_OF_EXCHANGE
                                                                                                          , DMT.DMT_BASE_PRICE
                                                                                                          , 0
                                                                                                           )
                                                                         )
                                                                  )
                                                          , 2
                                                           )
                                                    , DMT.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , ACS_FUNCTION.getlocalcurrencyid
                                                    , DMT.DMT_DATE_DOCUMENT
                                                    , DMT.DMT_VAT_BASE_PRICE
                                                    , DMT.DMT_VAT_EXCHANGE_RATE
                                                    , 0
                                                     )
                   ) -
             VDA_VAT_TOTAL_AMOUNT_V VDA_ROUND_AMOUNT_V
           , nvl(VDA.VDA_CORR_AMOUNT, 0) VDA_CORR_AMOUNT
           , nvl(VDA.VDA_CORR_AMOUNT_B, 0) VDA_CORR_AMOUNT_B
           , nvl(VDA.VDA_CORR_AMOUNT_V, 0) VDA_CORR_AMOUNT_V
           , nvl(VDA.VDA_CORRECTED, 0) VDA_CORRECTED
           , POS.DOC_POSITION_ID
           , DFC.DOC_FOOT_CHARGE_ID
           , GAP.GAP_INCLUDE_TAX_TARIFF
           , POS.POS_INCLUDE_TAX_TARIFF
           , GAP.GAP_VALUE_QUANTITY
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.DMT_DATE_DOCUMENT
        from DOC_DOCUMENT DMT
           , DOC_VAT_DET_ACCOUNT VDA
           , DOC_POSITION POS
           , DOC_GAUGE_POSITION GAP
           , DOC_FOOT_CHARGE DFC
       where DMT.DOC_DOCUMENT_ID = iDocId
         and VDA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
         and ( (   POS.DOC_POSITION_ID is not null
                or DFC.DOC_FOOT_CHARGE_ID is not null) )
         and VDA.DOC_POSITION_ID = POS.DOC_POSITION_ID(+)
         and VDA.DOC_FOOT_CHARGE_ID = DFC.DOC_FOOT_CHARGE_ID(+)
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID(+);

    ltplVatCorrection        lcurVatCorrection%rowtype;
    lIncludeTaxTariffInitial number(1);
    lIncludeTaxTariff        number(1);
  begin
    --initialisation valeur de retour
    oModified  := 0;

    -- ouverture du curseur sur les détails TVA
    open lcurVatCorrection(iDocumentId);

    fetch lcurVatCorrection
     into ltplVatCorrection;

    if lcurVatCorrection%found then
      -- Recherche si au moins un gabarit position du document est geré en TTC
      lIncludeTaxTariffInitial  := DOC_FUNCTIONS.isDocumentTTC(iDocumentId);
    end if;

    -- pour chaque détail...
    while lcurVatCorrection%found loop
      oModified          := 1;
      -- Utilise par défaut l'indicateur TTC du document
      lIncludeTaxTariff  := lIncludeTaxTariffInitial;

      -- Test sur le genre de montant à retirer
      if    (    ltplVatCorrection.VDA_ROUND_AMOUNT <> 0
             and iRemoveRound = 1)
         or (     (   ltplVatCorrection.VDA_CORR_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_V <> 0
                   or ltplVatCorrection.VDA_CORRECTED <> 0
                  )
             and iRemoveCorr = 1
            ) then
        -- Suppression de la correction sur les taxes de pieds de document
        if ltplVatCorrection.DOC_FOOT_CHARGE_ID is not null then
          if lIncludeTaxTariff = 1 then   -- TTC
            update DOC_FOOT_CHARGE
               set FCH_VAT_TOTAL_AMOUNT =
                          FCH_VAT_TOTAL_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                                 (ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT
                                                 )
                 , FCH_VAT_TOTAL_AMOUNT_B =
                     FCH_VAT_TOTAL_AMOUNT_B
                     - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B)
                 , FCH_VAT_TOTAL_AMOUNT_V =
                     FCH_VAT_TOTAL_AMOUNT_V
                     - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V)
                 , FCH_VAT_AMOUNT =
                     (FCH_VAT_TOTAL_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT)
                     ) *
                     ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                     100
                 , FCH_VAT_BASE_AMOUNT =
                     (FCH_VAT_TOTAL_AMOUNT_B -
                      decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B)
                     ) *
                     ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                     100
                 , FCH_VAT_AMOUNT_V =
                     (FCH_VAT_TOTAL_AMOUNT_V -
                      decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V)
                     ) *
                     ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                     100
                 , FCH_VAT_LIABLED_AMOUNT =
                     FCH_VAT_LIABLED_AMOUNT +
                     decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                     (ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT * ltplVatCorrection.VDA_LIABLED_RATE / 100
                     )
                 , FCH_EXCL_AMOUNT =
                               FCH_EXCL_AMOUNT + decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                                 (ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT
                                                 )
                 , FCH_EXCL_AMOUNT_B =
                         FCH_EXCL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                             (ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B
                                             )
                 , FCH_EXCL_AMOUNT_V =
                         FCH_EXCL_AMOUNT_V + decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                             (ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V
                                             )
             where DOC_FOOT_CHARGE_ID = ltplVatCorrection.DOC_FOOT_CHARGE_ID;
          else   -- HT
            update DOC_FOOT_CHARGE
               set FCH_VAT_TOTAL_AMOUNT =
                          FCH_VAT_TOTAL_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                                                 (ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT
                                                 )
                 , FCH_VAT_TOTAL_AMOUNT_B =
                     FCH_VAT_TOTAL_AMOUNT_B
                     - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B)
                 , FCH_VAT_TOTAL_AMOUNT_V =
                     FCH_VAT_TOTAL_AMOUNT_V
                     - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V)
                 , FCH_VAT_AMOUNT =
                     (FCH_VAT_TOTAL_AMOUNT - decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT)
                     ) *
                     ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                     100
                 , FCH_VAT_BASE_AMOUNT =
                     (FCH_VAT_TOTAL_AMOUNT_B -
                      decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B)
                     ) *
                     ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                     100
                 , FCH_VAT_AMOUNT_V =
                     (FCH_VAT_TOTAL_AMOUNT_V -
                      decode(C_FINANCIAL_CHARGE, '02', -1, 1) *(ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V)
                     ) *
                     ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                     100
                 , FCH_INCL_AMOUNT =
                     FCH_INCL_AMOUNT -
                     decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                     (ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT) /
                     ltplVatCorrection.VDA_LIABLED_RATE *
                     100
                 , FCH_INCL_AMOUNT_B =
                     FCH_INCL_AMOUNT_B -
                     decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                     (ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B) /
                     ltplVatCorrection.VDA_LIABLED_RATE *
                     100
                 , FCH_INCL_AMOUNT_V =
                     FCH_INCL_AMOUNT_V -
                     decode(C_FINANCIAL_CHARGE, '02', -1, 1) *
                     (ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V) /
                     ltplVatCorrection.VDA_LIABLED_RATE *
                     100
             where DOC_FOOT_CHARGE_ID = ltplVatCorrection.DOC_FOOT_CHARGE_ID;
          end if;
        -- Suppression de la correction sur les positions de document
        elsif ltplVatCorrection.DOC_POSITION_ID is not null then
          lIncludeTaxTariff  := IsPositionTtc(ltplVatCorrection.DOC_POSITION_ID);

          update DOC_POSITION
             set POS_VAT_TOTAL_AMOUNT = POS_VAT_TOTAL_AMOUNT - ltplVatCorrection.VDA_ROUND_AMOUNT - ltplVatCorrection.VDA_CORR_AMOUNT
               , POS_VAT_TOTAL_AMOUNT_B = POS_VAT_TOTAL_AMOUNT_B - ltplVatCorrection.VDA_ROUND_AMOUNT_B - ltplVatCorrection.VDA_CORR_AMOUNT_B
               , POS_VAT_TOTAL_AMOUNT_V = POS_VAT_TOTAL_AMOUNT_V - ltplVatCorrection.VDA_ROUND_AMOUNT_V - ltplVatCorrection.VDA_CORR_AMOUNT_V
               , POS_VAT_AMOUNT =
                   (POS_VAT_TOTAL_AMOUNT - ltplVatCorrection.VDA_ROUND_AMOUNT - ltplVatCorrection.VDA_CORR_AMOUNT) *
                   ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                   100
               , POS_VAT_BASE_AMOUNT =
                   (POS_VAT_TOTAL_AMOUNT_B - ltplVatCorrection.VDA_ROUND_AMOUNT_B - ltplVatCorrection.VDA_CORR_AMOUNT_B) *
                   ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                   100
               , POS_VAT_AMOUNT_V =
                   (POS_VAT_TOTAL_AMOUNT_V - ltplVatCorrection.VDA_ROUND_AMOUNT_V - ltplVatCorrection.VDA_CORR_AMOUNT_V) *
                   ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                   100
               , POS_VAT_LIABLED_AMOUNT =
                   POS_VAT_LIABLED_AMOUNT +
                   decode(lIncludeTaxTariff, 1, ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT, 0) *
                   ltplVatCorrection.VDA_LIABLED_RATE /
                   100   -- TTC
               , POS_NET_VALUE_EXCL =
                              POS_NET_VALUE_EXCL + decode(lIncludeTaxTariff
                                                        , 1, ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT
                                                        , 0
                                                         )   -- TTC
               , POS_NET_VALUE_EXCL_B =
                        POS_NET_VALUE_EXCL_B + decode(lIncludeTaxTariff
                                                    , 1, ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B
                                                    , 0
                                                     )   -- TTC
               , POS_NET_VALUE_EXCL_V =
                        POS_NET_VALUE_EXCL_V + decode(lIncludeTaxTariff
                                                    , 1, ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V
                                                    , 0
                                                     )   -- TTC
               , POS_NET_VALUE_INCL =
                               POS_NET_VALUE_INCL - decode(lIncludeTaxTariff
                                                         , 0, ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT
                                                         , 0
                                                          )   -- HT
               , POS_NET_VALUE_INCL_B =
                         POS_NET_VALUE_INCL_B - decode(lIncludeTaxTariff
                                                     , 0, ltplVatCorrection.VDA_ROUND_AMOUNT_B + ltplVatCorrection.VDA_CORR_AMOUNT_B
                                                     , 0
                                                      )   -- HT
               , POS_NET_VALUE_INCL_V =
                         POS_NET_VALUE_INCL_V - decode(lIncludeTaxTariff
                                                     , 0, ltplVatCorrection.VDA_ROUND_AMOUNT_V + ltplVatCorrection.VDA_CORR_AMOUNT_V
                                                     , 0
                                                      )   -- HT
               , POS_NET_UNIT_VALUE =
                   decode(lIncludeTaxTariff
                        , 1,(POS_NET_VALUE_EXCL +(ltplVatCorrection.VDA_ROUND_AMOUNT + ltplVatCorrection.VDA_CORR_AMOUNT) ) /
                           decode(ltplVatCorrection.GAP_VALUE_QUANTITY
                                , 1, decode(POS_VALUE_QUANTITY, 0, 1, POS_VALUE_QUANTITY)
                                , decode(POS_BASIS_QUANTITY, 0, 1, POS_BASIS_QUANTITY)
                                 )
                        , 0, POS_NET_UNIT_VALUE
                         )
               , POS_NET_UNIT_VALUE_INCL =
                   decode(lIncludeTaxTariff
                        , 1, POS_NET_UNIT_VALUE_INCL
                        , 0,(POS_NET_VALUE_INCL -(ltplVatCorrection.VDA_ROUND_AMOUNT - ltplVatCorrection.VDA_CORR_AMOUNT) ) /
                           decode(ltplVatCorrection.GAP_VALUE_QUANTITY
                                , 1, decode(POS_VALUE_QUANTITY, 0, 1, POS_VALUE_QUANTITY)
                                , decode(POS_BASIS_QUANTITY, 0, 1, POS_BASIS_QUANTITY)
                                 )
                         )
           where DOC_POSITION_ID = ltplVatCorrection.DOC_POSITION_ID;
        end if;

        -- Supression des valeurs dans les détails TVA
        -- Maj du montant soumis uniquement en mode TTC
        -- Cette opération doit obligatoirement figurer à la fin du traîtement
        -- sinon on a des conflits avec les triggers
        update DOC_VAT_DET_ACCOUNT VDA
           set VDA.VDA_ROUND_AMOUNT = 0
             , VDA.VDA_LIABLE_AMOUNT =
                 VDA.VDA_LIABLE_AMOUNT +
                 decode(lIncludeTaxTariff, 1, nvl(VDA_ROUND_AMOUNT, 0) + nvl(VDA_CORR_AMOUNT, 0), 0) * ltplVatCorrection.VDA_LIABLED_RATE / 100
             , VDA.VDA_LIABLE_AMOUNT_B =
                 VDA.VDA_LIABLE_AMOUNT_B +
                 decode(lIncludeTaxTariff, 1, ltplVatCorrection.VDA_ROUND_AMOUNT_B + VDA_CORR_AMOUNT_B, 0) * ltplVatCorrection.VDA_LIABLED_RATE / 100
             , VDA.VDA_LIABLE_AMOUNT_V =
                 VDA.VDA_LIABLE_AMOUNT_V +
                 decode(lIncludeTaxTariff, 1, ltplVatCorrection.VDA_ROUND_AMOUNT_V + VDA_CORR_AMOUNT_V, 0) * ltplVatCorrection.VDA_LIABLED_RATE / 100
             , VDA.VDA_NET_AMOUNT_EXCL = VDA.VDA_NET_AMOUNT_EXCL + decode(lIncludeTaxTariff, 1, nvl(VDA_ROUND_AMOUNT, 0) + nvl(VDA_CORR_AMOUNT, 0), 0)
             , VDA.VDA_VAT_TOTAL_AMOUNT = VDA.VDA_VAT_TOTAL_AMOUNT - nvl(VDA_ROUND_AMOUNT, 0) - nvl(VDA_CORR_AMOUNT, 0)
             , VDA.VDA_VAT_TOTAL_AMOUNT_B = VDA.VDA_VAT_TOTAL_AMOUNT_B - ltplVatCorrection.VDA_ROUND_AMOUNT_B - nvl(VDA_CORR_AMOUNT_B, 0)
             , VDA.VDA_VAT_TOTAL_AMOUNT_V = VDA.VDA_VAT_TOTAL_AMOUNT_V - ltplVatCorrection.VDA_ROUND_AMOUNT_V - nvl(VDA_CORR_AMOUNT_V, 0)
             , VDA.VDA_VAT_AMOUNT =
                                (VDA.VDA_VAT_TOTAL_AMOUNT - nvl(VDA_ROUND_AMOUNT, 0) - nvl(VDA_CORR_AMOUNT, 0) ) * ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE
                                / 100
             , VDA.VDA_VAT_BASE_AMOUNT =
                 (VDA.VDA_VAT_TOTAL_AMOUNT_B - ltplVatCorrection.VDA_ROUND_AMOUNT_B - nvl(VDA_CORR_AMOUNT_B, 0) ) *
                 ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                 100
             , VDA.VDA_VAT_AMOUNT_V =
                 (VDA.VDA_VAT_TOTAL_AMOUNT_V - ltplVatCorrection.VDA_ROUND_AMOUNT_V - nvl(VDA_CORR_AMOUNT_V, 0) ) *
                 ltplVatCorrection.VDA_VAT_DEDUCTIBLE_RATE /
                 100
             , VDA.DOC_POSITION_ID = null
             , VDA.DOC_FOOT_CHARGE_ID = null
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where VDA.DOC_VAT_DET_ACCOUNT_ID = ltplVatCorrection.DOC_VAT_DET_ACCOUNT_ID;
      end if;

      -- détail suivant
      fetch lcurVatCorrection
       into ltplVatCorrection;
    end loop;

    if oModified = 1 then
      begin
        update DOC_DOCUMENT
           set DMT_RECALC_TOTAL = 1
         where DOC_DOCUMENT_ID = iDocumentId;
      end;
    end if;

    close lcurVatCorrection;
  end RemoveVatCorrectionAmount;

  /**
  * procedure AppendZeroTaxCode
  * Description
  *   Create record for tax code used in the document but with a sum of 0
  * @created fp 27.01.2010
  * @lastUpdate
  * @public
  * @param iDocumentId : document to threat
  */
  procedure AppendZeroTaxCode(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplVatDet2Add in (select *
                            from V_DOC_VAT_DET_ACCOUNT
                           where DOC_DOCUMENT_ID = iDocumentId
                             and VDA_VAT_TOTAL_AMOUNT = 0
                             and not exists(
                                           select DOC_VAT_DET_ACCOUNT_ID
                                             from DOC_VAT_DET_ACCOUNT
                                            where DOC_FOOT_ID = V_DOC_VAT_DET_ACCOUNT.DOC_DOCUMENT_ID
                                              and ACS_TAX_CODE_ID = V_DOC_VAT_DET_ACCOUNT.ACS_TAX_CODE_ID) ) loop
      -- Insertion d'un nouveau détail TVA
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocVatDetAccount, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_VAT_DET_ACCOUNT_ID', getNewId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_FOOT_ID', tplVatDet2Add.DOC_DOCUMENT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_TAX_CODE_ID', tplVatDet2Add.ACS_TAX_CODE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_NET_AMOUNT_EXCL', tplVatDet2Add.VDA_NET_AMOUNT_EXCL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_LIABLED_RATE', tplVatDet2Add.VDA_LIABLED_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_LIABLE_AMOUNT', tplVatDet2Add.VDA_LIABLE_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_LIABLE_AMOUNT_B', tplVatDet2Add.VDA_LIABLE_AMOUNT_B);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_LIABLE_AMOUNT_V', tplVatDet2Add.VDA_LIABLE_AMOUNT_V);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_RATE', tplVatDet2Add.VDA_VAT_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_TOTAL_AMOUNT', tplVatDet2Add.VDA_VAT_TOTAL_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_TOTAL_AMOUNT_B', tplVatDet2Add.VDA_VAT_TOTAL_AMOUNT_B);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_TOTAL_AMOUNT_V', tplVatDet2Add.VDA_VAT_TOTAL_AMOUNT_V);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_DEDUCTIBLE_RATE', tplVatDet2Add.VDA_VAT_DEDUCTIBLE_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_AMOUNT', tplVatDet2Add.VDA_VAT_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_BASE_AMOUNT', tplVatDet2Add.VDA_VAT_BASE_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VDA_VAT_AMOUNT_V', tplVatDet2Add.VDA_VAT_AMOUNT_V);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;
  end AppendZeroTaxCode;

  /**
  * Description
  *   Création des détails TVA si aucun détail n'est présent
  */
  procedure CheckVatDetAccount(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- ne rentre dans le traitement que si le document gère la TVA et qu'aucun détail n'est présent
    for ltplGauge in (select DMT.DOC_DOCUMENT_ID
                        from DOC_DOCUMENT DMT inner join DOC_GAUGE_STRUCTURED GAS on DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                       where GAS.GAS_VAT = 1
                         and DMT.DOC_DOCUMENT_ID = iDocumentId
                         and not exists(select 1
                                          from DOC_VAT_DET_ACCOUNT
                                         where DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID) ) loop
      ResetVatDetAccount(iDocumentId => ltplGauge.DOC_DOCUMENT_ID);
    end loop;
  end CheckVatDetAccount;

  /**
  * procedure ResetVatDetAccount
  * Description
  *    Remise à niveau de la table DOC_VAT_DET_ACCOUNT en fonction des positions
  *    et des taxes de pied
  * @created fp 23.08.2010
  * @lastUpdate
  * @public
  * @param  iDocumentId  : document to threat
  */
  procedure ResetVatDetAccount(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lDocCurrId DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    lDocCurrId  := DOC_DOCUMENT_FUNCTIONS.GetDocumentCurrency(iDocumentId);

    -- suppression des anciens décompte TVA
    delete from DOC_VAT_DET_ACCOUNT
          where DOC_FOOT_ID = iDocumentId;

    insert into DOC_VAT_DET_ACCOUNT
                (DOC_VAT_DET_ACCOUNT_ID
               , DOC_FOOT_ID
               , ACS_TAX_CODE_ID
               , VDA_NET_AMOUNT_EXCL
               , VDA_LIABLED_RATE
               , VDA_LIABLE_AMOUNT
               , VDA_LIABLE_AMOUNT_B
               , VDA_LIABLE_AMOUNT_V
               , VDA_LIABLE_AMOUNT_E
               , VDA_VAT_RATE
               , VDA_VAT_TOTAL_AMOUNT
               , VDA_VAT_TOTAL_AMOUNT_B
               , VDA_VAT_TOTAL_AMOUNT_V
               , VDA_VAT_DEDUCTIBLE_RATE
               , VDA_VAT_AMOUNT
               , VDA_VAT_BASE_AMOUNT
               , VDA_VAT_AMOUNT_V
               , VDA_VAT_AMOUNT_E
               , A_DATECRE
               , A_IDCRE
                )
      select init_id_seq.nextval
           , V.DOC_DOCUMENT_ID
           , V.ACS_TAX_CODE_ID
           , V.VDA_NET_AMOUNT_EXCL
           , V.VDA_LIABLED_RATE
           , V.VDA_LIABLE_AMOUNT
           , V.VDA_LIABLE_AMOUNT_B
           , V.VDA_LIABLE_AMOUNT_V
           , decode(lDocCurrId
                  , ACS_FUNCTION.GetEuroCurrency, VDA_LIABLE_AMOUNT
                  , decode(ACS_FUNCTION.GetLocalCurrencyId, ACS_FUNCTION.GetEuroCurrency, VDA_LIABLE_AMOUNT_B, 0)
                   )
           , V.VDA_VAT_RATE
           , V.VDA_VAT_TOTAL_AMOUNT
           , V.VDA_VAT_TOTAL_AMOUNT_B
           , V.VDA_VAT_TOTAL_AMOUNT_V
           , V.VDA_VAT_DEDUCTIBLE_RATE
           , V.VDA_VAT_AMOUNT
           , V.VDA_VAT_BASE_AMOUNT
           , V.VDA_VAT_AMOUNT_V
           , decode(lDocCurrId
                  , ACS_FUNCTION.GetEuroCurrency, VDA_VAT_AMOUNT
                  , decode(ACS_FUNCTION.GetLocalCurrencyId, ACS_FUNCTION.GetEuroCurrency, VDA_VAT_BASE_AMOUNT, 0)
                   )
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from V_DOC_VAT_DET_ACCOUNT V
       where DOC_DOCUMENT_ID = iDocumentId;
  end ResetVatDetAccount;
end DOC_PRC_VAT;
