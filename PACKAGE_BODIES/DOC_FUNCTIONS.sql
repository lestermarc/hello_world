--------------------------------------------------------
--  DDL for Package Body DOC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_FUNCTIONS" 
is
  -- Donne le cumul des positions précédente et de la position courante
  -- pour la colonne POS_BASIS_QUANTITY
  function CumulPosBasisQuantity(aPositionId number)
    return number
  is
    result number(15, 5);
  begin
    select sum(nvl(POS1.POS_BASIS_QUANTITY, 0) )
      into result
      from DOC_POSITION POS1
         , DOC_POSITION POS2
     where POS2.DOC_POSITION_ID = apositionId
       and POS1.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
       and POS1.POS_NUMBER <= POS2.POS_NUMBER;

    return result;
  end CumulPosBasisQuantity;

  -- Donne le cumul des positions précédente et de la position courante
  -- pour la colonne POS_GROSS_VALUE
  function CumulPosGrossValue(aPositionId number)
    return number
  is
    result number(15, 5);
  begin
    select sum(nvl(POS1.POS_GROSS_VALUE, 0) )
      into result
      from DOC_POSITION POS1
         , DOC_POSITION POS2
     where POS2.DOC_POSITION_ID = apositionId
       and POS1.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
       and POS1.POS_NUMBER <= POS2.POS_NUMBER;

    return result;
  end CumulPosGrossValue;

  --  Donne le cumul des positions précédente et de la position courante
  --  pour la formule  POS_UNIT_COST_PRICE*POS_BASIS_QUANTITY
  function CumulPosCostValue(aPositionId number)
    return number
  is
    result number(15, 5);
  begin
    select sum(nvl(POS1.POS_UNIT_COST_PRICE, 0) * nvl(POS1.POS_BASIS_QUANTITY, 0) )
      into result
      from DOC_POSITION POS1
         , DOC_POSITION POS2
     where POS2.DOC_POSITION_ID = apositionId
       and POS1.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
       and POS1.POS_NUMBER <= POS2.POS_NUMBER;

    return result;
  end CumulPosCostValue;

  -- Description : Mise à jour des totaux du pied du document passé en paramètre
  procedure UpdateFootTotals(foot_id in number, aChanged out number)
  is
    cursor position_totals(document_id number)
    is
      select *
        from V_DOC_FOOT_POSITION
       where DOC_DOCUMENT_ID = document_id;

    pos             position_totals%rowtype;

    cursor foot_charge_totals(foot_id number)
    is
      select *
        from V_DOC_FOOT_CHARGE
       where DOC_DOCUMENT_ID = foot_id;

    fch             foot_charge_totals%rowtype;
    lAmountChanged  number(1);
    lBalanceChanged number(1);
    lAmount         number;
  begin
    select nvl(DMT_RECALC_TOTAL, 0)
      into lAmountChanged
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = foot_id;

    aChanged  := lAmountChanged;

    if lAmountChanged = 1 then
      open position_totals(foot_id);

      fetch position_totals
       into pos;

      open foot_charge_totals(foot_id);

      fetch foot_charge_totals
       into fch;

      select FOO_GOOD_TOT_AMOUNT_EXCL
        into lAmount
        from DOC_FOOT
       where DOC_FOOT_ID = foot_id;

      -- Mise à jour du pied de document sans les poids
      update DOC_FOOT
         set FOO_DOCUMENT_TOTAL_AMOUNT =
                nvl(POS.FOO_GOOD_TOTAL_AMOUNT, 0) + nvl(FCH.FOO_COST_TOTAL_AMOUNT, 0) + nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT, 0)
                - nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT, 0)
           , FOO_GOOD_TOTAL_AMOUNT = nvl(POS.FOO_GOOD_TOTAL_AMOUNT, 0)
           , FOO_TOTAL_VAT_AMOUNT = nvl(POS.FOO_TOT_POS_AMOUNT, 0) + nvl(FCH.FOO_TOT_FCH_AMOUNT, 0)
           , FOO_CHARGE_TOTAL_AMOUNT = nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT, 0)
           , FOO_DISCOUNT_TOTAL_AMOUNT = nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT, 0)
           , FOO_COST_TOTAL_AMOUNT = nvl(FCH.FOO_COST_TOTAL_AMOUNT, 0)
           , FOO_GOOD_TOT_AMOUNT_EXCL = nvl(POS.FOO_GOOD_TOT_AMOUNT_EXCL, 0)
           , FOO_CHARG_TOT_AMOUNT_EXCL = nvl(FCH.FOO_CHARG_TOT_AMOUNT_EXCL, 0)
           , FOO_DISC_TOT_AMOUNT_EXCL = nvl(FCH.FOO_DISC_TOT_AMOUNT_EXCL, 0)
           , FOO_COST_TOT_AMOUNT_EXCL = nvl(FCH.FOO_COST_TOT_AMOUNT_EXCL, 0)
           , FOO_TOTAL_NET_WEIGHT = decode(PCS.PC_CONFIG.GetConfig('DOC_UPDATE_FOOT_WEIGHT'), '1', POS.FOO_TOTAL_NET_WEIGHT, FOO_TOTAL_NET_WEIGHT)
           , FOO_TOTAL_GROSS_WEIGHT = decode(PCS.PC_CONFIG.GetConfig('DOC_UPDATE_FOOT_WEIGHT'), '1', POS.FOO_TOTAL_GROSS_WEIGHT, FOO_TOTAL_GROSS_WEIGHT)
           , FOO_TOTAL_RATE_FACTOR = nvl(POS.FOO_TOTAL_RATE_FACTOR, 0)
           , FOO_TOTAL_BASIS_QUANTITY = nvl(POS.FOO_TOTAL_BASIS_QUANTITY, 0)
           , FOO_TOTAL_INTERM_QUANTITY = nvl(POS.FOO_TOTAL_INTERM_QUANTITY, 0)
           , FOO_TOTAL_FINAL_QUANTITY = nvl(POS.FOO_TOTAL_FINAL_QUANTITY, 0)
           , FOO_DOCUMENT_TOT_AMOUNT_B =
               nvl(POS.FOO_GOOD_TOTAL_AMOUNT_B, 0) +
               nvl(FCH.FOO_COST_TOTAL_AMOUNT_B, 0) +
               nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT_B, 0) -
               nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT_B, 0)
           , FOO_DOCUMENT_TOT_AMOUNT_E =
               nvl(POS.FOO_GOOD_TOTAL_AMOUNT_E, 0) +
               nvl(FCH.FOO_COST_TOTAL_AMOUNT_E, 0) +
               nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT_E, 0) -
               nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT_E, 0)
           , FOO_GOOD_TOT_AMOUNT_B = nvl(POS.FOO_GOOD_TOTAL_AMOUNT_B, 0)
           , FOO_GOOD_TOT_AMOUNT_E = nvl(POS.FOO_GOOD_TOTAL_AMOUNT_E, 0)
           , FOO_TOT_VAT_AMOUNT_B = nvl(POS.FOO_TOT_POS_AMOUNT_B, 0) + nvl(FCH.FOO_TOT_FCH_AMOUNT_B, 0)
           , FOO_TOT_VAT_AMOUNT_E = nvl(POS.FOO_TOT_POS_AMOUNT_E, 0) + nvl(FCH.FOO_TOT_FCH_AMOUNT_E, 0)
           , FOO_TOT_VAT_AMOUNT_V = nvl(POS.FOO_TOT_POS_AMOUNT_V, 0) + nvl(FCH.FOO_TOT_FCH_AMOUNT_V, 0)
           , FOO_CHARGE_TOT_AMOUNT_B = nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT_B, 0)
           , FOO_CHARGE_TOT_AMOUNT_E = nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT_E, 0)
           , FOO_DISCOUNT_TOT_AMOUNT_B = nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT_B, 0)
           , FOO_DISCOUNT_TOT_AMOUNT_E = nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT_E, 0)
           , FOO_COST_TOT_AMOUNT_B = nvl(FCH.FOO_COST_TOTAL_AMOUNT_B, 0)
           , FOO_COST_TOT_AMOUNT_E = nvl(FCH.FOO_COST_TOTAL_AMOUNT_E, 0)
           , FOO_GOOD_TOT_AMOUNT_EX_B = nvl(POS.FOO_GOOD_TOT_AMOUNT_EXCL_B, 0)
           , FOO_GOOD_TOT_AMOUNT_EX_E = nvl(POS.FOO_GOOD_TOT_AMOUNT_EXCL_E, 0)
           , FOO_CHARG_TOT_AMOUNT_EX_B = nvl(FCH.FOO_CHARG_TOT_AMOUNT_EXCL_B, 0)
           , FOO_CHARG_TOT_AMOUNT_EX_E = nvl(FCH.FOO_CHARG_TOT_AMOUNT_EXCL_E, 0)
           , FOO_DISC_TOT_AMOUNT_EX_B = nvl(FCH.FOO_DISC_TOT_AMOUNT_EXCL_B, 0)
           , FOO_DISC_TOT_AMOUNT_EX_E = nvl(FCH.FOO_DISC_TOT_AMOUNT_EXCL_E, 0)
           , FOO_COST_TOT_AMOUNT_EX_B = nvl(FCH.FOO_COST_TOT_AMOUNT_EXCL_B, 0)
           , FOO_COST_TOT_AMOUNT_EX_E = nvl(FCH.FOO_COST_TOT_AMOUNT_EXCL_E, 0)
           , FOO_RECEIVED_AMOUNT =
               decode(sign(nvl(ACJ_JOB_TYPE_S_CAT_PMT_ID, 0) )
                    , 1, decode(nvl(FOO_RECEIVED_AMOUNT, FOO_DOCUMENT_TOTAL_AMOUNT)
                              , FOO_DOCUMENT_TOTAL_AMOUNT, nvl(POS.FOO_GOOD_TOTAL_AMOUNT, 0) +
                                 nvl(FCH.FOO_COST_TOTAL_AMOUNT, 0) +
                                 nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT, 0) -
                                 nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT, 0)
                              , FOO_RECEIVED_AMOUNT
                               )
                    , FOO_RECEIVED_AMOUNT
                     )
           , FOO_PAID_AMOUNT =
               decode(sign(nvl(ACJ_JOB_TYPE_S_CAT_PMT_ID, 0) )
                    , 1, decode(nvl(FOO_PAID_AMOUNT, FOO_DOCUMENT_TOTAL_AMOUNT)
                              , FOO_DOCUMENT_TOTAL_AMOUNT, nvl(POS.FOO_GOOD_TOTAL_AMOUNT, 0) +
                                 nvl(FCH.FOO_COST_TOTAL_AMOUNT, 0) +
                                 nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT, 0) -
                                 nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT, 0)
                              , FOO_PAID_AMOUNT
                               )
                    , FOO_PAID_AMOUNT
                     )
           , FOO_PAID_BALANCED_AMOUNT =
               decode(sign(nvl(ACJ_JOB_TYPE_S_CAT_PMT_ID, 0) )
                    , 1,(nvl(POS.FOO_GOOD_TOTAL_AMOUNT, 0) + nvl(FCH.FOO_COST_TOTAL_AMOUNT, 0) + nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT, 0) ) -
                       nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT, 0) -
                       (decode(nvl(FOO_PAID_AMOUNT, FOO_DOCUMENT_TOTAL_AMOUNT)
                             , FOO_DOCUMENT_TOTAL_AMOUNT, nvl(POS.FOO_GOOD_TOTAL_AMOUNT, 0) +
                                nvl(FCH.FOO_COST_TOTAL_AMOUNT, 0) +
                                nvl(FCH.FOO_CHARGE_TOTAL_AMOUNT, 0) -
                                nvl(FCH.FOO_DISCOUNT_TOTAL_AMOUNT, 0)
                             , FOO_PAID_AMOUNT
                              )
                       )
                    , FOO_PAID_BALANCED_AMOUNT
                     )
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_DOCUMENT_ID = foot_id;

      close position_totals;

      close foot_charge_totals;

      begin
        update DOC_DOCUMENT
           set DMT_RECALC_TOTAL = 0
         where DOC_DOCUMENT_ID = foot_id;
      end;
    end if;
  end UpdateFootTotals;

  -- Description : Mise à jour des totaux du pied du document passé en paramètre
  procedure UpdateBalanceTotal(iFootId in number)
  is
    cursor lcurPos(lDocumentId number)
    is
      select FOO_HEDGE_BALANCE_AMOUNT
        from V_DOC_FOOT_POSITION
       where DOC_DOCUMENT_ID = lDocumentId;

    ltplPos  lcurPos%rowtype;

    cursor lcurFch(lDocumentId number)
    is
      select FOO_FCH_TOT_AMOUNT_EXCL
        from V_DOC_FOOT_CHARGE
       where DOC_DOCUMENT_ID = lDocumentId;

    ltplFch  lcurFch%rowtype;
    lChanged number(1);
    lHedge   number(1);
  begin
    select sign(GAL_CURRENCY_RISK_VIRTUAL_ID)
      into lHedge
      from DOC_DOCUMENT DMT
     where DOC_DOCUMENT_ID = iFootId;

    -- mise à jour uniquement du montant solde
    if     lHedge = 1
       and DOC_I_LIB_DOCUMENT.IsCurrencyRiskProblem(iFootId) = 0 then
      open lcurPos(iFootId);

      open lcurFch(iFootId);

      fetch lcurPos
       into ltplPos;

      fetch lcurFch
       into ltplFch;

      -- Mise à jour du pied de document sans les poids
      update DOC_FOOT
         set FOO_CURR_RISK_BAL_POS_AMOUNT = nvl(ltplPos.FOO_HEDGE_BALANCE_AMOUNT, 0) - DOC_INVOICE_EXPIRY_FUNCTIONS.GetCurrRiskDischargedAmount(iFootId)
           , FOO_CURR_RISK_BAL_FCH_AMOUNT =
               decode(FOO_GOOD_TOT_AMOUNT_EXCL
                    , 0, 0
                    , nvl(ltplFch.FOO_FCH_TOT_AMOUNT_EXCL, 0) *
                      (nvl(ltplPos.FOO_HEDGE_BALANCE_AMOUNT, 0) - DOC_INVOICE_EXPIRY_FUNCTIONS.GetCurrRiskDischargedAmount(iFootId)
                      ) /
                      FOO_GOOD_TOT_AMOUNT_EXCL
                     )
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_DOCUMENT_ID = iFootId;

      close lcurPos;

      close lcurFch;

      -- CTRL HMO
      update DOC_POSITION_DETAIL
         set PDE_CURR_RISK_DISCHARGE_DONE = 1
       where DOC_DOCUMENT_ID = iFootId;
    end if;
  end UpdateBalanceTotal;

  function Decharge(vPositionId number, gauge_type varchar2)
    return varchar2
  is
    type pereTyp is record(
      dmt_doc       varchar2(30)
    , detail_id     number
    , doc_detail_id number
    , gauge         varchar2(10)
    , vdate         date
    );

    pos_det pereTyp;
    retour  varchar2(30);
  begin
    if vPositionId > 0 then
      -- il y a une décharge
      -- recherche du document,de l'éventuel position déchargée, du type gauge et de la date
      select doc.DMT_NUMBER
           , det.DOC_POSITION_DETAIL_ID
           , det.DOC_DOC_POSITION_DETAIL_ID
           , doc.DIC_GAUGE_TYPE_DOC_ID
           , doc.DMT_DATE_DOCUMENT
        into pos_det
        from doc_position_detail det
           , doc_position pos
           , doc_document doc
       where det.DOC_POSITION_ID = pos.DOC_POSITION_ID
         and pos.DOC_DOCUMENT_ID = doc.DOC_DOCUMENT_ID
         and DET.DOC_POSITION_DETAIL_ID = vPositionId;

      if pos_det.gauge <> gauge_type then
          -- si le type gauge est différent de celui passé en paramètre
        -- nouvelle recherche récursive
        retour  := Decharge(pos_det.DOC_DETAIL_ID, gauge_type);

        if retour = ' ' then
          -- si il n'y a pas d'autre décharge
          -- retour du dernier dmt_number
          retour  := pos_det.dmt_doc;
        end if;
      else
        -- si le type gauge est égal à celui passé en paramètre
        -- retour de son dmt_number
        retour  := pos_det.dmt_doc;
      end if;
    else
      -- si il n'y a pas de position déchargée
      retour  := ' ';
    end if;

    return retour;
  end Decharge;

  -- Retourne le nombre de jours entre aujourd'hui et le document déchargé du type (gauge_type)
  -- par la position passée en paramètre (vPositionId)
  function nb_jours(vPositionId number, gauge_type varchar2)
    return number
  is
    type pereTyp is record(
      dmt_doc       varchar2(30)
    , detail_id     number
    , doc_detail_id number
    , gauge         varchar2(10)
    , vdate         date
    );

    pos_det pereTyp;
    retour  number(10);
  begin
    if vPositionId > 0 then
      -- il y a une décharge
      -- recherche du document,de l'éventuel position déchargée, du type gauge et de la date
      select doc.DMT_NUMBER
           , det.DOC_POSITION_DETAIL_ID
           , det.DOC_DOC_POSITION_DETAIL_ID
           , doc.DIC_GAUGE_TYPE_DOC_ID
           , doc.DMT_DATE_DOCUMENT
        into pos_det
        from doc_position_detail det
           , doc_position pos
           , doc_document doc
       where det.DOC_POSITION_ID = pos.DOC_POSITION_ID
         and pos.DOC_DOCUMENT_ID = doc.DOC_DOCUMENT_ID
         and DET.DOC_POSITION_DETAIL_ID = vPositionId;

      if pos_det.gauge <> gauge_type then
          -- si le type gauge est différent de celui passé en paramètre
        -- nouvelle recherche récursive
        retour  := nb_jours(pos_det.DOC_DETAIL_ID, gauge_type);

        if retour = -1 then
          -- si il n'y a pas d'autre décharge
          -- retour du calcul du nombre de jours
          retour  := sysdate - pos_det.vdate;
        end if;
      else
        -- si le type gauge est égal à celui passé en paramètre
          -- retour du calcul du nombre de jours
        retour  := sysdate - pos_det.vdate;
      end if;
    else
      -- si il n'y a pas de position déchargée
      retour  := -1;
    end if;

    return retour;
  end nb_jours;

  -- Retourne le nombre de jours + 1, entre la date de la position source et le nombre de jours
  -- retourné par la function nb_jours()
  function CalDate(vdate date, nb_jour number)
    return number
  is
    nb_j number(10);
  begin
    nb_j  := sysdate - vdate;

    if nb_jour < 0 then
      nb_j  := null;
    else
      nb_j  := nb_jour - nb_j + 1;
    end if;

    return nb_j;
  end CalDate;

  function Decharge_id(vPositionId number, gauge_type varchar2)
    return number
  is
    type pereTyp is record(
      dmt_doc       varchar2(30)
    , detail_id     number
    , doc_detail_id number
    , gauge         varchar2(10)
    , vdate         date
    );

    pos_det pereTyp;
    retour  number(10);
  begin
    if vPositionId > 0 then
      -- il y a une décharge
      -- recherche du document,de l'éventuel position déchargée, du type gauge et de la date
      select doc.DMT_NUMBER
           , det.DOC_POSITION_DETAIL_ID
           , det.DOC_DOC_POSITION_DETAIL_ID
           , doc.DIC_GAUGE_TYPE_DOC_ID
           , doc.DMT_DATE_DOCUMENT
        into pos_det
        from doc_position_detail det
           , doc_position pos
           , doc_document doc
       where det.DOC_POSITION_ID = pos.DOC_POSITION_ID
         and pos.DOC_DOCUMENT_ID = doc.DOC_DOCUMENT_ID
         and DET.DOC_POSITION_DETAIL_ID = vPositionId;

      if pos_det.gauge <> gauge_type then
          -- si le type gauge est différent de celui passé en paramètre
        -- nouvelle recherche récursive
        retour  := Decharge_id(pos_det.DOC_DETAIL_ID, gauge_type);

        if retour = 0 then
          -- si il n'y a pas d'autre décharge
          -- retour du calcul du nombre de jours
          retour  := pos_det.detail_id;
        end if;
      else
        -- si le type gauge est égal à celui passé en paramètre
          -- retour du calcul du nombre de jours
        retour  := pos_det.detail_id;
      end if;
    else
      -- si il n'y a pas de position déchargée
      retour  := 0;
    end if;

    return retour;
  end Decharge_id;

  function Delay_Before(v_position_detail_id number, v_delay_history_id number)
    return number
  is
    type RecTyp is record(
      w_delay_history_id number
    );

    pos_det RecTyp;
    retour  number(10);
  begin
    if v_position_detail_id > 0 then
      select   max(his.DOC_DELAY_HISTORY_ID)
          into pos_det
          from doc_delay_history his
         where his.DOC_POSITION_DETAIL_ID = v_position_detail_id
           and his.DOC_DELAY_HISTORY_ID < v_delay_history_id
      group by his.DOC_POSITION_DETAIL_ID;

      retour  := pos_det.w_delay_history_id;
    end if;

    return retour;
  end Delay_Before;

  -- Recherche du montant ouvert pour la limite de crédit
  function GetTotAmountForCreditLimit(aPac_third_id number, aDocument_id number, aPartner_type varchar2)
    return number
  is
    vAmount               number                          default 0;
    vC_ADMIN_DOMAIN       DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lnFchDischargedAmount number                          default 0;
  begin
    -- Recherche du domaine par rapport au document
    if aDocument_id <> 0 then
      select GAU.C_ADMIN_DOMAIN
        into vC_ADMIN_DOMAIN
        from DOC_GAUGE GAU
           , DOC_DOCUMENT DMT
       where DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and DMT.DOC_DOCUMENT_ID = aDocument_id;
    -- Recherche du domaine par rapport au type de partenaire
    else
      -- Définition du domaine par rapport au tiers
      if aPartner_Type = 'S' then
        vC_ADMIN_DOMAIN  := '1';
      else
        vC_ADMIN_DOMAIN  := '2';
      end if;
    end if;

    -- Recherche du montant en tennant compte du domaine par rapport au type de partenaire
    select nvl(sum(FOO.FOO_DOCUMENT_TOT_AMOUNT_B * decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) ), 0)
      into vAmount
      from DOC_FOOT FOO
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
         , DOC_DOCUMENT DMT
     where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
       and (   DMT.DMT_PROTECTED = 0
            or DMT.DOC_DOCUMENT_ID = aDocument_id)   -- documents non protégés, mais en tenant compte quand même du document en cours
       and DMT.PAC_THIRD_ACI_ID = aPac_third_id   -- pour le tiers
       and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN   -- pour le code domaine
       and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and GAS.GAS_CALCUL_CREDIT_LIMIT = 1   -- gabarit pris en compte dans le calcul de la limite
       and DMT.C_DOCUMENT_STATUS in
             (decode(GAS.GAS_CREDIT_LIMIT_STATUS_01, 1, '01'), decode(GAS.GAS_CREDIT_LIMIT_STATUS_02, 1, '02'), decode(GAS.GAS_CREDIT_LIMIT_STATUS_04, 1, '04') );   -- status pris en compte

    -- Rechercher les montants pour les documents qui ont un statut '03'
    -- Le montant ouvert est calculé :
    -- Total document TTC MB - Somme[(Qté finale pos - Qté solde pos) * (Valeur nette TTC pos MB / Quté finale pos)]
    select vAmount + sum(DOC_AMOUNT - POS_AMOUNT)
      into vAmount
      from (select nvl(max(FOO.FOO_DOCUMENT_TOT_AMOUNT_B * decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) ), 0) DOC_AMOUNT
                 , nvl(sum( (POS.POS_FINAL_QUANTITY - POS.POS_BALANCE_QUANTITY) *
                           (POS.POS_NET_VALUE_INCL_B / POS.POS_FINAL_QUANTITY) *
                           decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1)
                          )
                     , 0
                      ) POS_AMOUNT
              from DOC_FOOT FOO
                 , DOC_GAUGE GAU
                 , DOC_GAUGE_STRUCTURED GAS
                 , DOC_DOCUMENT DMT
                 , DOC_POSITION POS
                 , DOC_POSITION POS_PT
             where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
               and (   DMT.DMT_PROTECTED = 0
                    or DMT.DOC_DOCUMENT_ID = aDocument_id)
               and DMT.PAC_THIRD_ACI_ID = aPac_third_id
               and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
               and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
               and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
               and GAS.GAS_CALCUL_CREDIT_LIMIT = 1
               and GAS.GAS_CREDIT_LIMIT_STATUS_03 = 1
               and DMT.C_DOCUMENT_STATUS = '03'
               and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
               and POS.DOC_DOC_POSITION_ID = POS_PT.DOC_POSITION_ID(+)
               and (   POS.C_GAUGE_TYPE_POS in('7', '8', '91', '10', '21')
                    or (    POS.C_GAUGE_TYPE_POS = '1'
                        and (   POS.DOC_DOC_POSITION_ID is null
                             or POS_PT.C_GAUGE_TYPE_POS = '9') )
                   )
               and POS.POS_FINAL_QUANTITY <> 0);

    -- Liste des remises/taxes de pied dont le document est au statut "soldé partiellement"
    for ltplFootCharge in (select   FCH.DOC_FOOT_CHARGE_ID
                               from DOC_FOOT FOO
                                  , DOC_GAUGE GAU
                                  , DOC_GAUGE_STRUCTURED GAS
                                  , DOC_DOCUMENT DMT
                                  , DOC_FOOT_CHARGE FCH
                              where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
                                and (   DMT.DMT_PROTECTED = 0
                                     or DMT.DOC_DOCUMENT_ID = aDocument_id)
                                and DMT.PAC_THIRD_ACI_ID = aPac_third_id
                                and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
                                and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                                and GAS.GAS_CALCUL_CREDIT_LIMIT = 1
                                and GAS.GAS_CREDIT_LIMIT_STATUS_03 = 1
                                and DMT.C_DOCUMENT_STATUS = '03'
                                and FOO.DOC_FOOT_ID = FCH.DOC_FOOT_ID
                           order by FCH.DOC_FOOT_CHARGE_ID) loop
      -- Additionner le montant de la remise/taxes sur les documents fils
      select lnFchDischargedAmount +
             nvl(sum(decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) * case
                       when FCH.C_FINANCIAL_CHARGE = '02' then -1
                       else 1
                     end * nvl(FCH.FCH_INCL_AMOUNT_B, 0) ), 0) as FCH_AMOUNT
        into lnFchDischargedAmount
        from DOC_FOOT FOO
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_DOCUMENT DMT
           , DOC_FOOT_CHARGE FCH
       where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
         and FOO.DOC_FOOT_ID = FCH.DOC_FOOT_ID
         and FCH.DOC_FOOT_CHARGE_SRC_ID = ltplFootCharge.DOC_FOOT_CHARGE_ID
         and (   DMT.DMT_PROTECTED = 0
              or DMT.DOC_DOCUMENT_ID = aDocument_id)
         and DMT.PAC_THIRD_ACI_ID = aPac_third_id
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAS.GAS_CALCUL_CREDIT_LIMIT = 1;
    end loop;

    vAmount  := vAmount - lnFchDischargedAmount;
    return vAmount;
  end GetTotAmountForCreditLimit;

  /**
  * function GetAmountCreditLimitGroup
  * Description :
  *   Retourne le montant ouvert des documents pour un group définit par le même compte auxiliaire
  */
  function GetAmountCreditLimitGroup(aAuxAccount_ID number, aDocument_ID number, aPartner_type varchar2)
    return number
  is
    vAmount               number                          default 0;
    vC_ADMIN_DOMAIN       DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lnFchDischargedAmount number                          default 0;
  begin
    -- Recherche du domaine par rapport au document
    if aDocument_ID <> 0 then
      select GAU.C_ADMIN_DOMAIN
        into vC_ADMIN_DOMAIN
        from DOC_GAUGE GAU
           , DOC_DOCUMENT DMT
       where DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and DMT.DOC_DOCUMENT_ID = aDocument_id;
    -- Recherche du domaine par rapport au type de partenaire
    else
      -- Définition du domaine par rapport au tiers
      if aPartner_Type = 'S' then
        vC_ADMIN_DOMAIN  := '1';
      else
        vC_ADMIN_DOMAIN  := '2';
      end if;
    end if;

    if vC_ADMIN_DOMAIN = '2' then
      -- Recherche du montant en tennant compte du domaine par rapport au type de partenaire
      select nvl(sum(FOO.FOO_DOCUMENT_TOT_AMOUNT_B * decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) ), 0)
        into vAmount
        from DOC_FOOT FOO
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_DOCUMENT DMT
           , PAC_CUSTOM_PARTNER CUS
       where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
         and (   DMT.DMT_PROTECTED = 0
              or DMT.DOC_DOCUMENT_ID = aDocument_id)   -- documents non protégés, mais en tenant compte quand même du document en cours
         and DMT.PAC_THIRD_ACI_ID = CUS.PAC_CUSTOM_PARTNER_ID   -- pour le tiers
         and CUS.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN   -- pour le code domaine
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAS.GAS_CALCUL_CREDIT_LIMIT = 1   -- gabarit pris en compte dans le calcul de la limite
         and DMT.C_DOCUMENT_STATUS in
               (decode(GAS.GAS_CREDIT_LIMIT_STATUS_01, 1, '01')
              , decode(GAS.GAS_CREDIT_LIMIT_STATUS_02, 1, '02')
              , decode(GAS.GAS_CREDIT_LIMIT_STATUS_04, 1, '04')
               );   -- status pris en compte

      -- Rechercher les montants pour les documents qui ont un statut '03'
      -- Le montant ouvert est calculé :
      -- Total document TTC MB - Somme[(Qté finale pos - Qté solde pos) * (Valeur nette TTC pos MB / Quté finale pos)]
      select vAmount +
             nvl( (sum(FOO.FOO_DOCUMENT_TOT_AMOUNT_B * decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) ) -
                   sum( (POS.POS_FINAL_QUANTITY - POS.POS_BALANCE_QUANTITY) *
                       (POS.POS_NET_VALUE_INCL_B / POS.POS_FINAL_QUANTITY) *
                       decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1)
                      )
                  )
               , 0
                )
        into vAmount
        from DOC_FOOT FOO
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION POS_PT
           , PAC_CUSTOM_PARTNER CUS
       where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
         and (   DMT.DMT_PROTECTED = 0
              or DMT.DOC_DOCUMENT_ID = aDocument_id)
         and DMT.PAC_THIRD_ACI_ID = CUS.PAC_CUSTOM_PARTNER_ID   -- pour le tiers
         and CUS.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAS.GAS_CALCUL_CREDIT_LIMIT = 1
         and GAS.GAS_CREDIT_LIMIT_STATUS_03 = 1
         and DMT.C_DOCUMENT_STATUS = '03'
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.DOC_DOC_POSITION_ID = POS_PT.DOC_POSITION_ID(+)
         and (   POS.C_GAUGE_TYPE_POS in('7', '8', '91', '10', '21')
              or (    POS.C_GAUGE_TYPE_POS = '1'
                  and (   POS.DOC_DOC_POSITION_ID is null
                       or POS_PT.C_GAUGE_TYPE_POS = '9') )
             )
         and POS.POS_FINAL_QUANTITY <> 0;

      -- Liste des remises/taxes de pied dont le document est au statut "soldé partiellement"
      for ltplFootCharge in (select   FCH.DOC_FOOT_CHARGE_ID
                                 from DOC_FOOT FOO
                                    , DOC_GAUGE GAU
                                    , DOC_GAUGE_STRUCTURED GAS
                                    , DOC_DOCUMENT DMT
                                    , DOC_FOOT_CHARGE FCH
                                    , PAC_CUSTOM_PARTNER CUS
                                where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
                                  and (   DMT.DMT_PROTECTED = 0
                                       or DMT.DOC_DOCUMENT_ID = aDocument_id)
                                  and DMT.PAC_THIRD_ACI_ID = CUS.PAC_CUSTOM_PARTNER_ID   -- pour le tiers
                                  and CUS.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
                                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                  and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
                                  and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                                  and GAS.GAS_CALCUL_CREDIT_LIMIT = 1
                                  and GAS.GAS_CREDIT_LIMIT_STATUS_03 = 1
                                  and DMT.C_DOCUMENT_STATUS = '03'
                                  and FOO.DOC_FOOT_ID = FCH.DOC_FOOT_ID
                             order by FCH.DOC_FOOT_CHARGE_ID) loop
        -- Additionner le montant de la remise/taxes sur les documents fils
        select lnFchDischargedAmount +
               nvl(sum(decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) * case
                         when FCH.C_FINANCIAL_CHARGE = '02' then -1
                         else 1
                       end * nvl(FCH.FCH_INCL_AMOUNT_B, 0) ), 0) as FCH_AMOUNT
          into lnFchDischargedAmount
          from DOC_FOOT FOO
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_DOCUMENT DMT
             , DOC_FOOT_CHARGE FCH
             , PAC_CUSTOM_PARTNER CUS
         where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
           and FOO.DOC_FOOT_ID = FCH.DOC_FOOT_ID
           and FCH.DOC_FOOT_CHARGE_SRC_ID = ltplFootCharge.DOC_FOOT_CHARGE_ID
           and (   DMT.DMT_PROTECTED = 0
                or DMT.DOC_DOCUMENT_ID = aDocument_id)
           and DMT.PAC_THIRD_ACI_ID = CUS.PAC_CUSTOM_PARTNER_ID   -- pour le tiers
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
           and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
           and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and GAS.GAS_CALCUL_CREDIT_LIMIT = 1;
      end loop;
    else
      -- Recherche du montant en tennant compte du domaine par rapport au type de partenaire
      select nvl(sum(FOO.FOO_DOCUMENT_TOT_AMOUNT_B * decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) ), 0)
        into vAmount
        from DOC_FOOT FOO
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_DOCUMENT DMT
           , PAC_SUPPLIER_PARTNER SUP
       where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
         and (   DMT.DMT_PROTECTED = 0
              or DMT.DOC_DOCUMENT_ID = aDocument_id)   -- documents non protégés, mais en tenant compte quand même du document en cours
         and DMT.PAC_THIRD_ACI_ID = SUP.PAC_SUPPLIER_PARTNER_ID   -- pour le tiers
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN   -- pour le code domaine
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAS.GAS_CALCUL_CREDIT_LIMIT = 1   -- gabarit pris en compte dans le calcul de la limite
         and DMT.C_DOCUMENT_STATUS in
               (decode(GAS.GAS_CREDIT_LIMIT_STATUS_01, 1, '01')
              , decode(GAS.GAS_CREDIT_LIMIT_STATUS_02, 1, '02')
              , decode(GAS.GAS_CREDIT_LIMIT_STATUS_04, 1, '04')
               );   -- status pris en compte

      -- Rechercher les montants pour les documents qui ont un statut '03'
      -- Le montant ouvert est calculé :
      -- Total document TTC MB - Somme[(Qté finale pos - Qté solde pos) * (Valeur nette TTC pos MB / Quté finale pos)]
      select vAmount +
             nvl( (sum(FOO.FOO_DOCUMENT_TOT_AMOUNT_B * decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) ) -
                   sum( (POS.POS_FINAL_QUANTITY - POS.POS_BALANCE_QUANTITY) *
                       (POS.POS_NET_VALUE_INCL_B / POS.POS_FINAL_QUANTITY) *
                       decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1)
                      )
                  )
               , 0
                )
        into vAmount
        from DOC_FOOT FOO
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION POS_PT
           , PAC_SUPPLIER_PARTNER SUP
       where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
         and (   DMT.DMT_PROTECTED = 0
              or DMT.DOC_DOCUMENT_ID = aDocument_id)
         and DMT.PAC_THIRD_ACI_ID = SUP.PAC_SUPPLIER_PARTNER_ID   -- pour le tiers
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAS.GAS_CALCUL_CREDIT_LIMIT = 1
         and GAS.GAS_CREDIT_LIMIT_STATUS_03 = 1
         and DMT.C_DOCUMENT_STATUS = '03'
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.DOC_DOC_POSITION_ID = POS_PT.DOC_POSITION_ID(+)
         and (   POS.C_GAUGE_TYPE_POS in('7', '8', '91', '10', '21')
              or (    POS.C_GAUGE_TYPE_POS = '1'
                  and (   POS.DOC_DOC_POSITION_ID is null
                       or POS_PT.C_GAUGE_TYPE_POS = '9') )
             )
         and POS.POS_FINAL_QUANTITY <> 0;

      -- Liste des remises/taxes de pied dont le document est au statut "soldé partiellement"
      for ltplFootCharge in (select   FCH.DOC_FOOT_CHARGE_ID
                                 from DOC_FOOT FOO
                                    , DOC_GAUGE GAU
                                    , DOC_GAUGE_STRUCTURED GAS
                                    , DOC_DOCUMENT DMT
                                    , DOC_FOOT_CHARGE FCH
                                    , PAC_SUPPLIER_PARTNER SUP
                                where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
                                  and (   DMT.DMT_PROTECTED = 0
                                       or DMT.DOC_DOCUMENT_ID = aDocument_id)
                                  and DMT.PAC_THIRD_ACI_ID = SUP.PAC_SUPPLIER_PARTNER_ID   -- pour le tiers
                                  and SUP.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
                                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                  and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
                                  and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                                  and GAS.GAS_CALCUL_CREDIT_LIMIT = 1
                                  and GAS.GAS_CREDIT_LIMIT_STATUS_03 = 1
                                  and DMT.C_DOCUMENT_STATUS = '03'
                                  and FOO.DOC_FOOT_ID = FCH.DOC_FOOT_ID
                             order by FCH.DOC_FOOT_CHARGE_ID) loop
        -- Additionner le montant de la remise/taxes sur les documents fils
        select lnFchDischargedAmount +
               nvl(sum(decode(GAS.C_DOC_CREDITLIMIT_MODE, 'ADD', 1, -1) * case
                         when FCH.C_FINANCIAL_CHARGE = '02' then -1
                         else 1
                       end * nvl(FCH.FCH_INCL_AMOUNT_B, 0) ), 0) as FCH_AMOUNT
          into lnFchDischargedAmount
          from DOC_FOOT FOO
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_DOCUMENT DMT
             , DOC_FOOT_CHARGE FCH
             , PAC_SUPPLIER_PARTNER SUP
         where DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
           and FOO.DOC_FOOT_ID = FCH.DOC_FOOT_ID
           and FCH.DOC_FOOT_CHARGE_SRC_ID = ltplFootCharge.DOC_FOOT_CHARGE_ID
           and (   DMT.DMT_PROTECTED = 0
                or DMT.DOC_DOCUMENT_ID = aDocument_id)
           and DMT.PAC_THIRD_ACI_ID = SUP.PAC_SUPPLIER_PARTNER_ID   -- pour le tiers
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = aAuxAccount_ID
           and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and GAU.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
           and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and GAS.GAS_CALCUL_CREDIT_LIMIT = 1;
      end loop;
    end if;

    -- Montant de la limite de crédit
    vAmount  := vAmount - lnFchDischargedAmount;
    return vAmount;
  end GetAmountCreditLimitGroup;

  /**
  * Description : met à jour la colonne POS_STOCK_OUTAGE de la position
  *               pour les positions qui font un mvt d'extourne du parent
  */
  procedure FlagPosMancoExtMvt(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aPositionList in ID_TABLE_TYPE)
  is
    cursor crPosSrcQty(cTgtDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, cTgtPositionList in ID_TABLE_TYPE)
    is
      select   POS_SRC.DOC_DOCUMENT_ID
             , POS_SRC.GCO_GOOD_ID
             , POS_SRC.STM_STOCK_ID
             , PDE_SRC.STM_LOCATION_ID
             , sum(decode(GAR.GAR_EXTOURNE_MVT, 1, decode(PDE_TGT.STM_LOCATION_ID, PDE_SRC.STM_LOCATION_ID, 0, 1), 0) *
                   decode(MOK.C_MOVEMENT_SORT, 'ENT', 1, 'SOR', -1, 0) *
                   PDE_TGT.PDE_MOVEMENT_QUANTITY +
                   PDE_TGT.PDE_BALANCE_QUANTITY_PARENT *(POS_TGT.POS_CONVERT_FACTOR / POS_SRC.POS_CONVERT_FACTOR)
                  ) PDE_EXTOURNE_QUANTITY
             , decode(nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0), 0, nvl(GAR.GAR_EXTOURNE_MVT, 0), MOK.MOK_TRANSFER_ATTRIB) MOK_TRANSFER_ATTRIB
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V1
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V2
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V3
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V4
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 5
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V5
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 1) CH_ID1
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 2) CH_ID2
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 3) CH_ID3
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 4) CH_ID4
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 5) CH_ID5
          from DOC_POSITION POS_TGT
             , DOC_POSITION_DETAIL PDE_TGT
             , (select distinct column_value DOC_POSITION_ID
                           from table(PCS.IdTableTypeToTable(cTgtPositionList) ) ) POS_EXT
             , DOC_POSITION POS_SRC
             , DOC_POSITION_DETAIL PDE_SRC
             , GCO_PRODUCT PDT
             , STM_MOVEMENT_KIND MOK
             , DOC_GAUGE_RECEIPT GAR
         where POS_TGT.DOC_DOCUMENT_ID = cTgtDocumentID
           and POS_TGT.DOC_POSITION_ID = POS_EXT.DOC_POSITION_ID
           and POS_TGT.POS_GENERATE_MOVEMENT = 0
           and POS_TGT.DOC_POSITION_ID = PDE_TGT.DOC_POSITION_ID
           and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
           and PDE_TGT.DOC_GAUGE_RECEIPT_ID = GAR.DOC_GAUGE_RECEIPT_ID(+)
           and POS_SRC.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+)
           and PDE_SRC.DOC_POSITION_ID = POS_SRC.DOC_POSITION_ID
           and POS_SRC.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
           and PDT.PDT_STOCK_MANAGEMENT(+) = 1
      group by POS_SRC.DOC_DOCUMENT_ID
             , POS_SRC.GCO_GOOD_ID
             , PDE_SRC.STM_LOCATION_ID
             , POS_SRC.STM_STOCK_ID
             , decode(nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0), 0, nvl(GAR.GAR_EXTOURNE_MVT, 0), MOK.MOK_TRANSFER_ATTRIB)
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS_SRC.GCO_GOOD_ID
                                              , 5
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE_SRC.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 1)
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 2)
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 3)
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 4)
             , GCO_FUNCTIONS.getStkCharPosId(POS_SRC.GCO_GOOD_ID, 5);

    cursor crPosToUpdate(
      cDocSrcID   in number
    , cDocTgtID   in number
    , cGoodID     in number
    , cLocationID in number
    , cCH_ID1     in number
    , cCH_ID2     in number
    , cCH_ID3     in number
    , cCH_ID4     in number
    , cCH_ID5     in number
    , cCH_V1      in varchar2
    , cCH_V2      in varchar2
    , cCH_V3      in varchar2
    , cCH_V4      in varchar2
    , cCH_V5      in varchar2
    )
    is
      select   POS_TGT.DOC_POSITION_ID
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION_DETAIL PDE_TGT
             , DOC_POSITION POS
             , DOC_POSITION POS_TGT
             , STM_MOVEMENT_KIND MOK
             , GCO_PRODUCT PDT
         where POS.DOC_DOCUMENT_ID = cDocSrcID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and POS.GCO_GOOD_ID = cGoodID
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and POS.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
           and POS_TGT.DOC_DOCUMENT_ID = cDocTgtID
           and POS_TGT.DOC_POSITION_ID = PDE_TGT.DOC_POSITION_ID
           and PDE.DOC_POSITION_DETAIL_ID = PDE_TGT.DOC_DOC_POSITION_DETAIL_ID
           and (   PDE.STM_LOCATION_ID = cLocationID
                or cLocationID is null)
           and nvl(nvl(cCH_ID1, PDE.GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID2, PDE.GCO_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID3, PDE.GCO2_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO2_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID4, PDE.GCO3_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO3_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID5, PDE.GCO4_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO4_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_V1, PDE.PDE_CHARACTERIZATION_VALUE_1), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_1, 'null')
           and nvl(nvl(cCH_V2, PDE.PDE_CHARACTERIZATION_VALUE_2), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_2, 'null')
           and nvl(nvl(cCH_V3, PDE.PDE_CHARACTERIZATION_VALUE_3), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_3, 'null')
           and nvl(nvl(cCH_V4, PDE.PDE_CHARACTERIZATION_VALUE_4), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_4, 'null')
           and nvl(nvl(cCH_V5, PDE.PDE_CHARACTERIZATION_VALUE_5), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_5, 'null')
      group by POS_TGT.DOC_POSITION_ID;

    vUpdatePosList ID_TABLE_TYPE                                := ID_TABLE_TYPE();
    vStockQuantity STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    blnExists      boolean;
    iIndex         binary_integer;
  begin
    -- Controler sur les documents source les qtés pour la rupture de stock
    for tplPosSrcQty in crPosSrcQty(aDocumentID, aPositionList) loop
      vStockQuantity  :=
        STM_FUNCTIONS.GetRealStockQuantity(aGoodId           => tplPosSrcQty.GCO_GOOD_ID
                                         , aStockId          => null
                                         , aLocationId       => tplPosSrcQty.STM_LOCATION_ID
                                         , aCharac1Id        => tplPosSrcQty.CH_ID1
                                         , aCharac2Id        => tplPosSrcQty.CH_ID2
                                         , aCharac3Id        => tplPosSrcQty.CH_ID3
                                         , aCharac4Id        => tplPosSrcQty.CH_ID4
                                         , aCharac5Id        => tplPosSrcQty.CH_ID5
                                         , aCharVal1         => tplPosSrcQty.CH_V1
                                         , aCharVal2         => tplPosSrcQty.CH_V2
                                         , aCharVal3         => tplPosSrcQty.CH_V3
                                         , aCharVal4         => tplPosSrcQty.CH_V4
                                         , aCharVal5         => tplPosSrcQty.CH_V5
                                         , aTransfer         => tplPosSrcQty.MOK_TRANSFER_ATTRIB
                                         , iCheckStockCond   => 0
                                          );

      -- Liste des positions pères qui sont en rupture
      if     tplPosSrcQty.PDE_EXTOURNE_QUANTITY > vStockQuantity
         and DOC_I_LIB_ALLOY.StockDeficitControl(tplPosSrcQty.STM_STOCK_ID, tplPosSrcQty.GCO_GOOD_ID) > 0 then
        for tplPosUpdate in crPosToUpdate(tplPosSrcQty.DOC_DOCUMENT_ID
                                        , aDocumentID
                                        , tplPosSrcQty.GCO_GOOD_ID
                                        , tplPosSrcQty.STM_LOCATION_ID
                                        , tplPosSrcQty.CH_ID1
                                        , tplPosSrcQty.CH_ID2
                                        , tplPosSrcQty.CH_ID3
                                        , tplPosSrcQty.CH_ID4
                                        , tplPosSrcQty.CH_ID5
                                        , tplPosSrcQty.CH_V1
                                        , tplPosSrcQty.CH_V2
                                        , tplPosSrcQty.CH_V3
                                        , tplPosSrcQty.CH_V4
                                        , tplPosSrcQty.CH_V5
                                         ) loop
          blnExists  := false;
          iIndex     := vUpdatePosList.first;

          -- Balayer la liste pour vérifier si l'id de la position y figure déjà
          loop
            exit when iIndex is null
                  or blnExists;

            if vUpdatePosList(iIndex) = tplPosUpdate.DOC_POSITION_ID then
              blnExists  := true;
            end if;

            iIndex  := vUpdatePosList.next(iIndex);
          end loop;

          -- Ajouter l'id de la position si pas déjà dans la liste
          if not blnExists then
            vUpdatePosList.extend;
            vUpdatePosList(vUpdatePosList.last)  := tplPosUpdate.DOC_POSITION_ID;
          end if;
        end loop;
      end if;
    end loop;

    if vUpdatePosList.count > 0 then
      -- Màj du flag de rupture sur les positions filles
      for tplUpdate in (select POS.DOC_POSITION_ID
                          from DOC_POSITION POS
                             , (select distinct column_value DOC_POSITION_ID
                                           from table(PCS.IdTableTypeToTable(vUpdatePosList) ) ) POS_UPD
                         where POS.DOC_DOCUMENT_ID = aDocumentID
                           and POS.DOC_POSITION_ID = POS_UPD.DOC_POSITION_ID
                           and POS.STM_MOVEMENT_KIND_ID is not null
                           and POS.C_GAUGE_TYPE_POS not in('7', '8', '9', '10') ) loop
        DOC_I_PRC_POSITION.SetPositionError(tplUpdate.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorStockOutage);
      end loop;
    end if;
  end FlagPosMancoExtMvt;

  /**
  * Description : met à jour la colonne POS_STOCK_OUTAGE de la position
  *               passée en paramètre en fonction de la qté en stock au
  *               moment de l'appel.
  */
  procedure FlagPositionManco(position_id in number, document_id in number)
  is
    cursor crPosQty(cDocumentID in number, cPositionID in number)
    is
      select   sum(decode(MOK.C_MOVEMENT_SORT, 'ENT', -1, 'SOR', 1, 0) * PDE.PDE_MOVEMENT_QUANTITY) CUM_QTE
             , POS.DOC_DOCUMENT_ID
             , POS.GCO_GOOD_ID
             , PDE.PDE_GENERATE_MOVEMENT
             , POS.STM_STOCK_ID
             , PDE.STM_LOCATION_ID
             , PDE.FAL_LOT_ID
             , MOK.STM_STM_MOVEMENT_KIND_ID
             , decode(nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0), 0, nvl(GAR.GAR_EXTOURNE_MVT, 0), MOK.C_ATTRIB_TRSF_KIND) C_ATTRIB_TRSF_KIND
             , nvl(GAR.GAR_EXTOURNE_MVT, 0) GAR_EXTOURNE_MVT
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V1
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V2
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V3
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V4
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 5
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               ) CH_V5
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 1) CH_ID1
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 2) CH_ID2
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 3) CH_ID3
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 4) CH_ID4
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 5) CH_ID5
             , nvl(PDT.PDT_STOCK_MANAGEMENT, 0) STOCK_MANAGEMENT
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , STM_MOVEMENT_KIND MOK
             , DOC_GAUGE_RECEIPT GAR
             , GCO_PRODUCT PDT
             , (select distinct GCO_GOOD_ID
                           from DOC_POSITION
                          where DOC_DOCUMENT_ID = cDocumentID
                            and DOC_POSITION_ID = nvl(cPositionID, DOC_POSITION_ID) ) GOOD
         where POS.DOC_DOCUMENT_ID = cDocumentID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and nvl(PDE.PDE_GENERATE_MOVEMENT, 0) = 0
           and POS.GCO_GOOD_ID = GOOD.GCO_GOOD_ID
           and POS.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and PDE.DOC_GAUGE_RECEIPT_ID = GAR.DOC_GAUGE_RECEIPT_ID(+)
           and POS.C_GAUGE_TYPE_POS not in('7', '8', '9', '10')
      group by POS.DOC_DOCUMENT_ID
             , POS.GCO_GOOD_ID
             , PDE.PDE_GENERATE_MOVEMENT
             , POS.STM_STOCK_ID
             , PDE.STM_LOCATION_ID
             , PDE.FAL_LOT_ID
             , MOK.STM_STM_MOVEMENT_KIND_ID
             , MOK.C_MOVEMENT_SORT
             , decode(nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0), 0, nvl(GAR.GAR_EXTOURNE_MVT, 0), MOK.C_ATTRIB_TRSF_KIND)
             , nvl(GAR.GAR_EXTOURNE_MVT, 0)
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosValue(POS.GCO_GOOD_ID
                                              , 5
                                              , PDE.PDE_CHARACTERIZATION_VALUE_1
                                              , PDE.PDE_CHARACTERIZATION_VALUE_2
                                              , PDE.PDE_CHARACTERIZATION_VALUE_3
                                              , PDE.PDE_CHARACTERIZATION_VALUE_4
                                              , PDE.PDE_CHARACTERIZATION_VALUE_5
                                               )
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 1)
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 2)
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 3)
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 4)
             , GCO_FUNCTIONS.getStkCharPosId(POS.GCO_GOOD_ID, 5)
             , nvl(PDT.PDT_STOCK_MANAGEMENT, 0);

    cursor crPosToUpdate(
      cDocumentID in number
    , cGoodID     in number
    , cLocationID in number
    , cCH_ID1     in number
    , cCH_ID2     in number
    , cCH_ID3     in number
    , cCH_ID4     in number
    , cCH_ID5     in number
    , cCH_V1      in varchar2
    , cCH_V2      in varchar2
    , cCH_V3      in varchar2
    , cCH_V4      in varchar2
    , cCH_V5      in varchar2
    )
    is
      select   POS.DOC_POSITION_ID
             , POS.POS_NUMBER
             , sum(decode(PDT.PDT_STOCK_MANAGEMENT, 1, 1, 0) *
                   decode(GAR.GAR_EXTOURNE_MVT, 1, decode(PDE.STM_LOCATION_ID, PDE_PARENT.STM_LOCATION_ID, 0, 1), 1) *
                   decode(MOK.C_MOVEMENT_SORT, 'ENT', -1, 'SOR', 1, 0) *
                   PDE.PDE_MOVEMENT_QUANTITY
                  ) POS_QTY
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION_DETAIL PDE_PARENT
             , DOC_POSITION POS
             , DOC_POSITION POS_PARENT
             , STM_MOVEMENT_KIND MOK
             , STM_MOVEMENT_KIND MOK_PARENT
             , DOC_GAUGE_RECEIPT GAR
             , GCO_PRODUCT PDT
         where POS.DOC_DOCUMENT_ID = cDocumentID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and POS.GCO_GOOD_ID = cGoodID
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
           and PDE_PARENT.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_DOC_POSITION_DETAIL_ID
           and POS_PARENT.DOC_POSITION_ID(+) = PDE_PARENT.DOC_POSITION_ID
           and MOK_PARENT.STM_MOVEMENT_KIND_ID(+) = POS_PARENT.STM_MOVEMENT_KIND_ID
           and PDE.DOC_GAUGE_RECEIPT_ID = GAR.DOC_GAUGE_RECEIPT_ID(+)
           and (   PDE.STM_LOCATION_ID = cLocationID
                or cLocationID is null)
           and nvl(nvl(cCH_ID1, PDE.GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID2, PDE.GCO_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID3, PDE.GCO2_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO2_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID4, PDE.GCO3_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO3_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_ID5, PDE.GCO4_GCO_CHARACTERIZATION_ID), -1) = nvl(PDE.GCO4_GCO_CHARACTERIZATION_ID, -1)
           and nvl(nvl(cCH_V1, PDE.PDE_CHARACTERIZATION_VALUE_1), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_1, 'null')
           and nvl(nvl(cCH_V2, PDE.PDE_CHARACTERIZATION_VALUE_2), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_2, 'null')
           and nvl(nvl(cCH_V3, PDE.PDE_CHARACTERIZATION_VALUE_3), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_3, 'null')
           and nvl(nvl(cCH_V4, PDE.PDE_CHARACTERIZATION_VALUE_4), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_4, 'null')
           and nvl(nvl(cCH_V5, PDE.PDE_CHARACTERIZATION_VALUE_5), 'null') = nvl(PDE.PDE_CHARACTERIZATION_VALUE_5, 'null')
           and POS.STM_MOVEMENT_KIND_ID is not null
           and POS.C_GAUGE_TYPE_POS not in('7', '8', '9', '10')
           and POS.C_DOC_POS_ERROR is null   -- les positions présentant déjà une autre erreur ne sont pas contrôlée
      group by POS.DOC_POSITION_ID
             , POS.POS_NUMBER
      order by POS.POS_NUMBER;

    tplPosQty          crPosQty%rowtype;
    vDocumentID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vStockQuantity     STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    vOutage            DOC_POSITION.POS_STOCK_OUTAGE%type;
    vListExtournePosID ID_TABLE_TYPE                                := ID_TABLE_TYPE();
    blnExists          boolean;
    iIndex             binary_integer;
    lnGaugeID          DOC_GAUGE.DOC_GAUGE_ID%type;
    lnComponentFound   number                                       := 0;
  begin
    if position_id is not null then
      update DOC_POSITION
         set POS_STOCK_OUTAGE = 0
       where DOC_POSITION_ID = position_id;

      select DOC_DOCUMENT_ID
        into vDocumentID
        from DOC_POSITION
       where DOC_POSITION_ID = position_id;

      -- Détermine si la position spécifiée est liée à des positions composants qui demande la vérification de la
      -- rupture
      select count(*)
        into lnComponentFound
        from dual
       where exists(select POS.DOC_POSITION_ID
                      from DOC_POSITION POS
                     where DOC_DOC_POSITION_ID = position_id
                       and POS.STM_MOVEMENT_KIND_ID is not null);
    else
      -- Ne plus faire ici car associé avec plusieurs contrôles
--       update DOC_POSITION
--          set POS_STOCK_OUTAGE = 0
--        where DOC_DOCUMENT_ID = document_id;
      vDocumentID  := document_id;
    end if;

    -- Traitement de la rupture sur tous les composants de la position courante
    if lnComponentFound = 1 then
      for ltplCpt in (select POS.DOC_POSITION_ID
                        from DOC_POSITION POS
                       where POS.DOC_DOC_POSITION_ID = position_id
                         and POS.STM_MOVEMENT_KIND_ID is not null) loop
        FlagPositionManco(position_id => ltplCpt.DOC_POSITION_ID, document_id => null);
      end loop;
    end if;

    -- Recherche la quantité disponible de la position en tenant compte des autres positions du document.
    --
    --    Si la quantité de la position change, il faut redéfinir le flag de rupture sur toute les positions d'un
    --    même bien/emplacement/caractérisation du document
    for tplPosQty in crPosQty(vDocumentID, position_id) loop
      if tplPosQty.FAL_LOT_ID is null then
        -- Recherche la quantité réellement en stock pour le bien, l'emplacement et les caractérisations du détail de
        -- position courant.
        vStockQuantity  :=
          STM_FUNCTIONS.GetRealStockQuantity(aGoodId           => tplPosQty.GCO_GOOD_ID
                                           , aStockId          => null
                                           , aLocationId       => tplPosQty.STM_LOCATION_ID
                                           , aCharac1Id        => tplPosQty.CH_ID1
                                           , aCharac2Id        => tplPosQty.CH_ID2
                                           , aCharac3Id        => tplPosQty.CH_ID3
                                           , aCharac4Id        => tplPosQty.CH_ID4
                                           , aCharac5Id        => tplPosQty.CH_ID5
                                           , aCharVal1         => tplPosQty.CH_V1
                                           , aCharVal2         => tplPosQty.CH_V2
                                           , aCharVal3         => tplPosQty.CH_V3
                                           , aCharVal4         => tplPosQty.CH_V4
                                           , aCharVal5         => tplPosQty.CH_V5
                                           , aTransfer         => tplPosQty.C_ATTRIB_TRSF_KIND
                                           , iCheckStockCond   => 0
                                            );

        -- Liste des positions à màj le flag de rupture
        for tplPosToUpdate in crPosToUpdate(vDocumentID
                                          , tplPosQty.GCO_GOOD_ID
                                          , tplPosQty.STM_LOCATION_ID
                                          , tplPosQty.CH_ID1
                                          , tplPosQty.CH_ID2
                                          , tplPosQty.CH_ID3
                                          , tplPosQty.CH_ID4
                                          , tplPosQty.CH_ID5
                                          , tplPosQty.CH_V1
                                          , tplPosQty.CH_V2
                                          , tplPosQty.CH_V3
                                          , tplPosQty.CH_V4
                                          , tplPosQty.CH_V5
                                           ) loop
          -- Rupture
          if     (tplPosQty.STOCK_MANAGEMENT = 1)
             and (tplPosQty.CUM_QTE <> 0)
             and (tplPosToUpdate.POS_QTY > 0)
             and (tplPosToUpdate.POS_QTY > vStockQuantity)
             and DOC_I_LIB_ALLOY.StockDeficitControl(tplPosQty.STM_STOCK_ID, tplPosQty.GCO_GOOD_ID) > 0 then
            -- Position en rupture de stock
            vOutage  := 1;
          else
            vOutage  := 0;

            -- Ajouter la position à la liste des positions à controler par
            -- rapport au mouvement d'extourne du père en décharge
            if     (tplPosQty.GAR_EXTOURNE_MVT = 1)
               and (tplPosQty.STOCK_MANAGEMENT = 1) then
              blnExists  := false;
              iIndex     := vListExtournePosID.first;

              -- Balayer la liste pour vérifier si l'id de la position y figure déjà
              loop
                exit when iIndex is null
                      or blnExists;

                if vListExtournePosID(iIndex) = tplPosToUpdate.DOC_POSITION_ID then
                  blnExists  := true;
                end if;

                iIndex  := vListExtournePosID.next(iIndex);
              end loop;

              -- Ajouter l'id de la position si pas déjà dans la liste
              if not blnExists then
                vListExtournePosID.extend;
                vListExtournePosID(vListExtournePosID.last)  := tplPosToUpdate.DOC_POSITION_ID;
              end if;
            end if;
          end if;

          -- Màj du flag de rupture de stock
          if vOutage = 1 then
            DOC_I_PRC_POSITION.SetPositionError(tplPosToUpdate.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorStockOutage);
          end if;

          -- Décremente la qté réelle en stock
          if     (tplPosQty.STOCK_MANAGEMENT = 1)
             and (tplPosToUpdate.POS_QTY > 0) then
            vStockQuantity  := vStockQuantity - tplPosToUpdate.POS_QTY;
          end if;
        end loop;
      else
        -- Recherche du gabarit
        select DOC_GAUGE_ID
          into lnGaugeID
          from DOC_DOCUMENT
         where DOC_DOCUMENT_ID = vDocumentID;

        -- Le ctrl de la rupture de stock des positions doit se faire uniquement pour le BRAST ou FFAST
        if    (DOC_LIB_SUBCONTRACTP.IsSUPRSGauge(iGaugeId => lnGaugeID) = 1)
           or (DOC_LIB_SUBCONTRACTP.IsSUPIGauge(iGaugeId => lnGaugeID) = 1) then
          -- Liste des positions à màj le flag de rupture
          for tplPosToUpdate in crPosToUpdate(vDocumentID
                                            , tplPosQty.GCO_GOOD_ID
                                            , tplPosQty.STM_LOCATION_ID
                                            , tplPosQty.CH_ID1
                                            , tplPosQty.CH_ID2
                                            , tplPosQty.CH_ID3
                                            , tplPosQty.CH_ID4
                                            , tplPosQty.CH_ID5
                                            , tplPosQty.CH_V1
                                            , tplPosQty.CH_V2
                                            , tplPosQty.CH_V3
                                            , tplPosQty.CH_V4
                                            , tplPosQty.CH_V5
                                             ) loop
            if FAL_I_LIB_SUBCONTRACTP.HasPositionMissingParts(tplPosToUpdate.DOC_POSITION_ID) = 1 then
              if    position_id is null
                 or position_id = tplPosToUpdate.DOC_POSITION_ID then
                DOC_PRC_POSITION.SetPositionError(tplPosToUpdate.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorStockOutage);
              end if;
            end if;
          end loop;
        end if;
      end if;
    end loop;

    -- Liste de positions à ctrl la rupture de stock sur le mvt d'extourne du père
    if vListExtournePosID.count > 0 then
      FlagPosMancoExtMvt(aDocumentID => vDocumentID, aPositionList => vListExtournePosID);
    end if;
  end FlagPositionManco;

  /**
  * Description
  *   Renvoie 1 si une des position de stock liées à la posiiton ou au document
  *   est en cours d'inventaire, donc bloquée
  */
  function IsStockInventoring(aPositionId in number, aDocumentId in number)
    return number
  is
    result   number(1);
    nbPosMvt integer;
  begin
    if aPositionId is not null then
      select sign(count(*) )
        into result
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
       where POS.DOC_POSITION_ID = aPositionId
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and STM_FUNCTIONS.getPositionStatus(PDE.GCO_GOOD_ID
                                           , PDE.STM_LOCATION_ID
                                           , PDE.GCO_CHARACTERIZATION_ID
                                           , PDE.GCO_GCO_CHARACTERIZATION_ID
                                           , PDE.GCO2_GCO_CHARACTERIZATION_ID
                                           , PDE.GCO3_GCO_CHARACTERIZATION_ID
                                           , PDE.GCO4_GCO_CHARACTERIZATION_ID
                                           , PDE.PDE_CHARACTERIZATION_VALUE_1
                                           , PDE.PDE_CHARACTERIZATION_VALUE_2
                                           , PDE.PDE_CHARACTERIZATION_VALUE_3
                                           , PDE.PDE_CHARACTERIZATION_VALUE_4
                                           , PDE.PDE_CHARACTERIZATION_VALUE_5
                                            ) = '03'
         and POS.STM_MOVEMENT_KIND_ID is not null
         and POS.POS_GENERATE_MOVEMENT = 0;
    else
      -- test si au moins un des gabarit position a des mouvements de stock
      select count(*)
        into nbPosMvt
        from doc_document dmt
           , doc_gauge_position gap
       where dmt.doc_document_id = aDocumentId
         and gap.doc_gauge_id = dmt.doc_gauge_id
         and gap.stm_movement_kind_id is not null;

      if nbPosMvt > 0 then
        select sign(count(*) )
          into result
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
         where POS.DOC_DOCUMENT_ID = aDocumentId
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and STM_FUNCTIONS.getPositionStatus(PDE.GCO_GOOD_ID
                                             , PDE.STM_LOCATION_ID
                                             , PDE.GCO_CHARACTERIZATION_ID
                                             , PDE.GCO_GCO_CHARACTERIZATION_ID
                                             , PDE.GCO2_GCO_CHARACTERIZATION_ID
                                             , PDE.GCO3_GCO_CHARACTERIZATION_ID
                                             , PDE.GCO4_GCO_CHARACTERIZATION_ID
                                             , PDE.PDE_CHARACTERIZATION_VALUE_1
                                             , PDE.PDE_CHARACTERIZATION_VALUE_2
                                             , PDE.PDE_CHARACTERIZATION_VALUE_3
                                             , PDE.PDE_CHARACTERIZATION_VALUE_4
                                             , PDE.PDE_CHARACTERIZATION_VALUE_5
                                              ) = '03'
           and POS.STM_MOVEMENT_KIND_ID is not null
           and POS.POS_GENERATE_MOVEMENT = 0;

        -- mouvement de transfert
        if result = 0 then
          select sign(count(*) )
            into result
            from DOC_POSITION_DETAIL PDE
               , DOC_POSITION POS
           where POS.DOC_DOCUMENT_ID = aDocumentId
             and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
             and STM_FUNCTIONS.getPositionStatus(PDE.GCO_GOOD_ID
                                               , PDE.STM_STM_LOCATION_ID
                                               , PDE.GCO_CHARACTERIZATION_ID
                                               , PDE.GCO_GCO_CHARACTERIZATION_ID
                                               , PDE.GCO2_GCO_CHARACTERIZATION_ID
                                               , PDE.GCO3_GCO_CHARACTERIZATION_ID
                                               , PDE.GCO4_GCO_CHARACTERIZATION_ID
                                               , PDE.PDE_CHARACTERIZATION_VALUE_1
                                               , PDE.PDE_CHARACTERIZATION_VALUE_2
                                               , PDE.PDE_CHARACTERIZATION_VALUE_3
                                               , PDE.PDE_CHARACTERIZATION_VALUE_4
                                               , PDE.PDE_CHARACTERIZATION_VALUE_5
                                                ) = '03'
             and PDE.STM_STM_LOCATION_ID is not null
             and POS.STM_MOVEMENT_KIND_ID is not null
             and POS.POS_GENERATE_MOVEMENT = 0;
        end if;
      else
        result  := 0;
      end if;
    end if;

    return result;
  end IsStockInventoring;

  /**
  * Description : met à jour la quantité solde et le statut de la position
  *               courante.
  */
  procedure UpdateBalancePosition(APositionID in number, AQuantity in number, AValueQuantity in number, ABalancedQuantity in number)
  is
  begin
    if APositionID is not null then
      update DOC_POSITION
         set POS_BALANCE_QUANTITY =
               decode(sign(POS_BASIS_QUANTITY)
                    , -1, greatest(least( (POS_BALANCE_QUANTITY - AQuantity - ABalancedQuantity), 0), POS_FINAL_QUANTITY)
                    , least(greatest( (POS_BALANCE_QUANTITY - AQuantity - ABalancedQuantity), 0), POS_FINAL_QUANTITY)
                     )
           , POS_BALANCE_QTY_VALUE =(POS_BALANCE_QTY_VALUE - AValueQuantity)
           , C_DOC_POS_STATUS =
               decode(decode(sign(POS_BASIS_QUANTITY)
                           , -1, greatest(least( (POS_BALANCE_QUANTITY - AQuantity - ABalancedQuantity), 0), POS_FINAL_QUANTITY)
                           , least(greatest( (POS_BALANCE_QUANTITY - AQuantity - ABalancedQuantity), 0), POS_FINAL_QUANTITY)
                            )
                    , 0, '04'
                    , decode(decode(sign(POS_BASIS_QUANTITY)
                                  , -1, greatest(least( (POS_BALANCE_QUANTITY - AQuantity - ABalancedQuantity), 0), POS_FINAL_QUANTITY)
                                  , least(greatest( (POS_BALANCE_QUANTITY - AQuantity - ABalancedQuantity), 0), POS_FINAL_QUANTITY)
                                   )
                           , POS_FINAL_QUANTITY, '02'
                           , '03'
                            )
                     )
       where DOC_POSITION_ID = APositionID;
    end if;
  end UpdateBalancePosition;

  /**
  * procedure MajDocumentStatus
  * Description : mise à jour du status d'un document
  *   Cette méthode est conservée dans un souci de compatibilité avec les packages indivs des clients
  */

  /**
  * Description : mise à jour du status d'un document
  */
  procedure UpdateDocumentStatus(aDocumentID in number, aCancelDocument in number default 0)
  is
  begin
    DOC_PRC_DOCUMENT.UpdateDocumentStatus(aDocumentId, aCancelDocument);
  end UpdateDocumentStatus;

  /**
  * Description
  *      mise à jour des prix des mouvements sur les détails de position d'un document
  * @created Fabrice Perotto
  * @version 18/07/2001
  * @public
  * @param aDocumentId  : id du document à mettre à jour
  */
  procedure DocUpdateDetailMovementPrice(aDocumentId in number)
  is
    cursor document_position(aDocumentId in number)
    is
      select   DOC_POSITION_ID
          from DOC_POSITION
         where DOC_DOCUMENT_ID = aDocumentId
           and C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '71', '81', '91', '101')
      order by C_GAUGE_TYPE_POS desc;   -- L'order by garantit le traitement des positions composants avant le produit terminé.

    positionId doc_position.doc_position_id%type;
  begin
    open document_position(aDocumentId);

    fetch document_position
     into positionId;

    while document_position%found loop
      PosUpdateDetailMovementPrice(positionId);

      fetch document_position
       into positionId;
    end loop;

    close document_position;
  end DocUpdateDetailMovementPrice;

  /**
  * Description
  *      mise à jour des prix des mouvements sur les détails de position d'une position de document
  * @created Fabrice Perotto
  * @version 18/07/2001
  * @public
  * @param aPositionId  : id de la position à mettre à jour
  */
  procedure PosUpdateDetailMovementPrice(aPositionId in number)
  is
    cursor position_cursor(aPositionId number)
    is
      select   PDE.DOC_POSITION_DETAIL_ID
             , PDE.DOC_POSITION_ID
             , PDE.DOC_GAUGE_ID
             , POS.DOC_RECORD_ID
             , PDE.DOC_DOC_POSITION_DETAIL_ID
             , PDE.DOC2_DOC_POSITION_DETAIL_ID
             , PDE.PDE_MOVEMENT_QUANTITY
             , PDE.PDE_FINAL_QUANTITY
             , PDE.PDE_FINAL_QUANTITY_SU
             , PDE.FAL_SCHEDULE_STEP_ID
             , PDE.DOC_GAUGE_RECEIPT_ID
             , PDE.DOC_GAUGE_COPY_ID
             , POS.GCO_GOOD_ID
             , POS.STM_MOVEMENT_KIND_ID
             , POS.POS_FINAL_QUANTITY
             , POS.POS_FINAL_QUANTITY_SU
             , POS.POS_UNIT_COST_PRICE
             , POS.POS_NET_UNIT_VALUE
             , POS.POS_NET_VALUE_EXCL
             , POS.POS_NET_VALUE_EXCL_B
             , POS.DOC_DOC_POSITION_ID
             , POS.C_GAUGE_TYPE_POS
             , POS.POS_CONVERT_FACTOR
             , GOO.C_MANAGEMENT_MODE
             , DMT.PAC_THIRD_ID
             , DMT.PAC_THIRD_TARIFF_ID
             , DMT.ACS_FINANCIAL_CURRENCY_ID
             , DMT.DMT_DATE_DOCUMENT
             , DMT.DMT_RATE_OF_EXCHANGE
             , DMT.DMT_BASE_PRICE
             , GAP.GAP_VALUE
             , GAP.GAP_STOCK_MVT
             , GAU.C_ADMIN_DOMAIN
             , (select count(*)
                  from DOC_POSITION_DETAIL PDE_COUNT
                 where PDE_COUNT.DOC_POSITION_ID = POS.DOC_POSITION_ID) DETAIL_COUNT
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , DOC_GAUGE_POSITION GAP
             , DOC_GAUGE GAU
             , GCO_GOOD GOO
         where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = aPositionId
           and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '71', '81', '91', '101')
           and POS.POS_GENERATE_MOVEMENT = 0
      order by PDE.DOC_POSITION_ID;

    position_tuple     position_cursor%rowtype;

    cursor position8_cursor(aPositionId number)
    is
      select   PDE.DOC_POSITION_DETAIL_ID
             , PDE.DOC_POSITION_ID
             , PDE.DOC_GAUGE_ID
             , POS.DOC_RECORD_ID
             , PDE.DOC_DOC_POSITION_DETAIL_ID
             , PDE.DOC2_DOC_POSITION_DETAIL_ID
             , PDE.PDE_MOVEMENT_QUANTITY
             , PDE.PDE_FINAL_QUANTITY
             , PDE.PDE_FINAL_QUANTITY_SU
             , PDE.FAL_SCHEDULE_STEP_ID
             , PDE.DOC_GAUGE_RECEIPT_ID
             , PDE.DOC_GAUGE_COPY_ID
             , POS.GCO_GOOD_ID
             , POS.STM_MOVEMENT_KIND_ID
             , POS.POS_FINAL_QUANTITY
             , POS.POS_FINAL_QUANTITY_SU
             , POS.POS_UNIT_COST_PRICE
             , POS.POS_NET_UNIT_VALUE
             , POS.POS_NET_VALUE_EXCL
             , POS.POS_NET_VALUE_EXCL_B
             , POS.DOC_DOC_POSITION_ID
             , POS.C_GAUGE_TYPE_POS
             , POS.POS_CONVERT_FACTOR
             , GOO.C_MANAGEMENT_MODE
             , DMT.PAC_THIRD_TARIFF_ID
             , DMT.ACS_FINANCIAL_CURRENCY_ID
             , DMT.DMT_DATE_DOCUMENT
             , DMT.DMT_RATE_OF_EXCHANGE
             , DMT.DMT_BASE_PRICE
             , GAP.GAP_VALUE
             , GAP.GAP_STOCK_MVT
             , GAU.C_ADMIN_DOMAIN
             , (select count(*)
                  from DOC_POSITION_DETAIL PDE_COUNT
                 where PDE_COUNT.DOC_POSITION_ID = POS.DOC_POSITION_ID) DETAIL_COUNT
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , DOC_GAUGE_POSITION GAP
             , DOC_GAUGE GAU
             , GCO_GOOD GOO
         where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = aPositionId
           and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and POS.C_GAUGE_TYPE_POS = '8'
           and POS.POS_GENERATE_MOVEMENT = 0
      order by PDE.DOC_POSITION_ID;

    position8_tuple    position8_cursor%rowtype;
    unitCostPrice      doc_position.pos_unit_cost_price%type;
    mvtPrice           doc_position_detail.pde_movement_value%type;
    initPrice          number(1);
    transCostPrice     number(1);
    vManagementMode    GCO_GOOD.C_MANAGEMENT_MODE%type;
    vExcludeAmount     DOC_POSITION_CHARGE.PCH_AMOUNT%type           default 0;
    vExcludeAmountUnit DOC_POSITION.POS_NET_UNIT_VALUE%type          default 0;
  begin
    -- ouverture du curseur et positionnement sur le premier tuple
    open position_cursor(aPositionId);

    fetch position_cursor
     into position_tuple;

    if position_cursor%found then
      -- initialisation des variables (valeurs utilisées en création standard)
      transCostPrice  := 0;
      initPrice       := 1;

      -- recherche d'informations dans le flux de décharge ou de copie
      if position_tuple.DOC_GAUGE_RECEIPT_ID is not null then
        select GAR_INIT_COST_PRICE
             , GAR_INIT_PRICE_MVT
          into transCostPrice
             , initPrice
          from DOC_GAUGE_RECEIPT
         where DOC_GAUGE_RECEIPT_ID = position_tuple.DOC_GAUGE_RECEIPT_ID;
      elsif position_tuple.DOC_GAUGE_COPY_ID is not null then
        select GAC_INIT_COST_PRICE
             , GAC_INIT_PRICE_MVT
          into transCostPrice
             , initPrice
          from DOC_GAUGE_COPY
         where DOC_GAUGE_COPY_ID = position_tuple.DOC_GAUGE_COPY_ID;
      end if;

      -- Initialisation du prix de revient unitaire
      if transCostPrice = 0 then
        -- Recherche du prix de revient unitaire
        unitCostPrice  :=
          GCO_FUNCTIONS.GetCostPriceWithManagementMode(position_tuple.GCO_GOOD_ID
                                                     , nvl(position_tuple.PAC_THIRD_TARIFF_ID, position_tuple.PAC_THIRD_ID)
                                                     , position_tuple.C_MANAGEMENT_MODE
                                                      );

        /* La mise à jour du prix de revient ne doit pas se faire si le bien est
           géré au prix de revient fixe et que le nouveau prix de revient du bien
           est à 0. */
        if     (position_tuple.C_MANAGEMENT_MODE = '3')
           and (unitCostPrice = 0) then
          unitCostPrice  := position_tuple.POS_UNIT_COST_PRICE;
        else
          update DOC_POSITION
             set POS_UNIT_COST_PRICE = unitCostPrice
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_POSITION_ID = position_tuple.DOC_POSITION_ID;
        end if;
      else
        unitCostPrice  := position_tuple.POS_UNIT_COST_PRICE;
      end if;

      -- pour chaque détail de la position
      while position_cursor%found loop
        -- Maj du prix du mouvement
        if     initPrice = 1
           and position_tuple.stm_movement_kind_id is not null
           and (   position_tuple.gap_stock_mvt = 1
                or position_tuple.doc2_doc_position_detail_id is not null) then
          mvtPrice  := DOC_POSITION_DETAIL_FUNCTIONS.CalcPdeMvtValue(position_tuple.DOC_POSITION_DETAIL_ID);

          ----
          -- Mise à jour de l'écart du prix d'achat. L'écart est arrondi avec la méthode d'arrondi finance de la
          -- monnaie de base.
          --
          -- Les forumles de calcul de l'écart sont les suivantes :
          --
          -- US : Unité de stockage
          -- PR : Prix de revient
          -- B  : Exprimé en monnaie de base
          --
          -- Si Quantité position US = 0
          --   Ecart d'achat = Prix net position B
          --   Ecart d'achat applicable = Prix net position B / Nombre de détail de la position
          -- Sinon
          --   Prix net unitaire position US = Prix net position B / Quantité position US
          -- Prix net détail = Prix net unitaire position US * Quantité détail US
          -- Ecart d'achat = Prix net détail - (PR unitaire position * Quantité détail US)
          -- Ecart d'achat = (Prix net unitaire position US * Quantité détail US) - (PR unitaire position * Quantité détail US)
          -- Ecart d'achat applicable = Arrondi monnaie local de Ecart d'achat
          --
          --
          update DOC_POSITION_DETAIL
             set PDE_MOVEMENT_VALUE = mvtPrice
               , PDE_GAP_PURCHASE_PRICE =
                   decode(position_tuple.POS_FINAL_QUANTITY_SU
                        , 0, position_tuple.POS_NET_VALUE_EXCL_B / position_tuple.DETAIL_COUNT
                        , ACS_FUNCTION.RoundAmount( ( (position_tuple.POS_NET_VALUE_EXCL_B / position_tuple.POS_FINAL_QUANTITY_SU) *
                                                     position_tuple.PDE_FINAL_QUANTITY_SU
                                                    ) -
                                                   (unitCostPrice * position_tuple.PDE_FINAL_QUANTITY_SU)
                                                 , ACS_FUNCTION.GetLocalCurrencyId
                                                  )
                         )
           where DOC_POSITION_DETAIL_ID = position_tuple.DOC_POSITION_DETAIL_ID;
        elsif position_tuple.stm_movement_kind_id is not null then
          ----
          -- Mise à jour de l'écart du prix d'achat.
          --
          -- Voir commentaires ci-dessus
          --
          update DOC_POSITION_DETAIL
             set PDE_GAP_PURCHASE_PRICE =
                   decode(position_tuple.POS_FINAL_QUANTITY_SU
                        , 0, position_tuple.POS_NET_VALUE_EXCL_B / position_tuple.DETAIL_COUNT
                        , ACS_FUNCTION.RoundAmount( ( (position_tuple.POS_NET_VALUE_EXCL_B / position_tuple.POS_FINAL_QUANTITY_SU) *
                                                     position_tuple.PDE_FINAL_QUANTITY_SU
                                                    ) -
                                                   (unitCostPrice * position_tuple.PDE_FINAL_QUANTITY_SU)
                                                 , ACS_FUNCTION.GetLocalCurrencyId
                                                  )
                         )
           where DOC_POSITION_DETAIL_ID = position_tuple.DOC_POSITION_DETAIL_ID;
        end if;

        fetch position_cursor
         into position_tuple;
      end loop;

      close position_cursor;
    end if;

    ----
    -- Ouverture du curseur sur les détails de la position 8 et positionnement
    -- sur le premier tuple
    --
    open position8_cursor(aPositionId);

    fetch position8_cursor
     into position8_tuple;

    if position8_cursor%found then
      -- initialisation des variables (valeurs utilisées en création standard)
      transCostPrice  := 0;
      initPrice       := 1;

      -- Recherche d'informations dans le flux de décharge ou de copie
      if position8_tuple.DOC_GAUGE_RECEIPT_ID is not null then
        select GAR_INIT_COST_PRICE
             , GAR_INIT_PRICE_MVT
          into transCostPrice
             , initPrice
          from DOC_GAUGE_RECEIPT
         where DOC_GAUGE_RECEIPT_ID = position8_tuple.DOC_GAUGE_RECEIPT_ID;
      elsif position8_tuple.DOC_GAUGE_COPY_ID is not null then
        select GAC_INIT_COST_PRICE
             , GAC_INIT_PRICE_MVT
          into transCostPrice
             , initPrice
          from DOC_GAUGE_COPY
         where DOC_GAUGE_COPY_ID = position8_tuple.DOC_GAUGE_COPY_ID;
      end if;

      -- Initialisation du prix de revient unitaire
      if transCostPrice = 0 then
        ----
        -- Recherche la somme des prix de revient unitaire des composants
        --
        select sum(nvl(POS.POS_UNIT_COST_PRICE, 0) * nvl(POS.POS_UTIL_COEFF, 1) )
          into unitCostPrice
          from DOC_POSITION POS
         where POS.DOC_DOC_POSITION_ID = position8_tuple.DOC_POSITION_ID;

        ----
        -- Initialisation du prix de revient unitaire sur la position 8
        --
        update DOC_POSITION
           set POS_UNIT_COST_PRICE = unitCostPrice
         where DOC_POSITION_ID = position8_tuple.DOC_POSITION_ID;
      else
        unitCostPrice  := position8_tuple.POS_UNIT_COST_PRICE;
      end if;
    end if;

    ----
    -- Traitement des détails de la position 8 en vue de la mise à jour du prix
    -- du mouvement.
    --
    while position8_cursor%found loop
      -- Maj du prix du mouvement
      if     initPrice = 1
         and position8_tuple.STM_MOVEMENT_KIND_ID is not null
         and (   position8_tuple.GAP_STOCK_MVT = 1
              or position8_tuple.DOC2_DOC_POSITION_DETAIL_ID is not null) then
        -- Document de vente
        if position8_tuple.C_ADMIN_DOMAIN = '2' then
          mvtPrice  := unitCostPrice * position8_tuple.PDE_FINAL_QUANTITY_SU;
        else   -- Document d'achat et autres
          if (position8_tuple.POS_FINAL_QUANTITY = 0) then
            mvtPrice  := position8_tuple.POS_NET_VALUE_EXCL;
          else
            if position8_tuple.PDE_FINAL_QUANTITY = 0 then
              mvtPrice  := position8_tuple.POS_NET_UNIT_VALUE;
            else
              mvtPrice  := position8_tuple.PDE_FINAL_QUANTITY * position8_tuple.POS_NET_UNIT_VALUE;
            end if;
          end if;

          -- si le document est en monnaie étrangère, on converti le prix du mouvement
          if position8_tuple.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId then
            mvtPrice  :=
              ACS_FUNCTION.ConvertAmountForView(mvtPrice
                                              , position8_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , ACS_FUNCTION.GetLocalCurrencyId
                                              , position8_tuple.DMT_DATE_DOCUMENT
                                              , position8_tuple.DMT_RATE_OF_EXCHANGE
                                              , position8_tuple.DMT_BASE_PRICE
                                              , 0
                                               );
          end if;
        end if;

        ----
        -- Mise à jour de l'écart du prix d'achat.
        --
        -- Voir commentaires plus haut
        --
        update DOC_POSITION_DETAIL
           set PDE_MOVEMENT_VALUE = mvtPrice
             , PDE_GAP_PURCHASE_PRICE =
                 decode(position8_tuple.POS_FINAL_QUANTITY_SU
                      , 0, position8_tuple.POS_NET_VALUE_EXCL_B / position_tuple.DETAIL_COUNT
                      , ACS_FUNCTION.RoundAmount( ( (position8_tuple.POS_NET_VALUE_EXCL_B / position8_tuple.POS_FINAL_QUANTITY_SU) *
                                                   position8_tuple.PDE_FINAL_QUANTITY_SU
                                                  ) -
                                                 (unitCostPrice * position8_tuple.PDE_FINAL_QUANTITY_SU)
                                               , ACS_FUNCTION.GetLocalCurrencyId
                                                )
                       )
         where DOC_POSITION_DETAIL_ID = position8_tuple.DOC_POSITION_DETAIL_ID;
      elsif position_tuple.stm_movement_kind_id is not null then
        ----
        -- Mise à jour de l'écart du prix d'achat.
        --
        -- Voir commentaires plus haut
        --
        update DOC_POSITION_DETAIL
           set PDE_GAP_PURCHASE_PRICE =
                 decode(position8_tuple.POS_FINAL_QUANTITY_SU
                      , 0, position8_tuple.POS_NET_VALUE_EXCL_B / position_tuple.DETAIL_COUNT
                      , ACS_FUNCTION.RoundAmount( ( (position8_tuple.POS_NET_VALUE_EXCL_B / position8_tuple.POS_FINAL_QUANTITY_SU) *
                                                   position8_tuple.PDE_FINAL_QUANTITY_SU
                                                  ) -
                                                 (unitCostPrice * position8_tuple.PDE_FINAL_QUANTITY_SU)
                                               , ACS_FUNCTION.GetLocalCurrencyId
                                                )
                       )
         where DOC_POSITION_DETAIL_ID = position8_tuple.DOC_POSITION_DETAIL_ID;
      end if;

      fetch position8_cursor
       into position8_tuple;
    end loop;

    close position8_cursor;
  end PosUpdateDetailMovementPrice;

  /**
  * Description
  *     RETOURNE LA PDE_QUANTITY_BALANCE_PARENT POUR UNE POSITION
  */
  function DocSituationBalanceParent(posDetId doc_position.doc_position_id%type)
    return number
  is
    result DOC_POSITION.POS_FINAL_QUANTITY%type;
  begin
    select nvl(sum(pde.pde_balance_quantity_parent), 0)
      into result
      from doc_position_detail pde
     where pde.doc_doc_position_detail_id = posDetId;

    return result;
  exception
    when no_data_found then
      return 0;
  end DocSituationBalanceParent;

  /**
  * Description
  *     RETOURNE LA PDE_FINAL_QUANTITY POUR UNE POSITION
  */
  function DocSituationFinalQtySon(posDetId doc_position.doc_position_id%type)
    return number
  is
    result DOC_POSITION.POS_FINAL_QUANTITY%type;
  begin
    select nvl(sum(pde.pde_final_quantity), 0)
      into result
      from doc_position_detail pde
     where pde.doc_doc_position_detail_id = posDetId;

    return result;
  exception
    when no_data_found then
      return 0;
  end DocSituationFinalQtySon;

  /**
  * Description
  *       Procedure d'insertion des historiques de modification des documents
  */
  procedure CreateHistoryInformation(
    aDocumentId      in number
  , aPositionId      in number
  , aDocNumber       in varchar2
  , aUpdateType      in varchar2
  , aUpdateDescr     in varchar2
  , aFreeDescription in varchar2
  , aDocumentStatus  in varchar2
  , aPositionStatus  in varchar2
  )
  is
    pragma autonomous_transaction;
    docNumber      DOC_DOCUMENT.DMT_NUMBER%type;
    documentStatus DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    positionStatus DOC_POSITION.C_DOC_POS_STATUS%type;
  begin
    -- Recherche du numéro et du status du document, si ces derniers ne sont pas passés en paramètre
    if     (   aDocNumber is null
            or aDocumentStatus is null)
       and aDocumentId is not null then
      begin
        select nvl(aDocNumber, DMT_NUMBER)
             , nvl(aDocumentStatus, C_DOCUMENT_STATUS)
          into docNumber
             , documentStatus
          from DOC_DOCUMENT
         where DOC_DOCUMENT_ID = aDocumentId;
      exception
        when no_data_found then
          docNumber       := aDocNumber;
          documentStatus  := aDocumentStatus;
      end;
    else
      docNumber       := aDocNumber;
      documentStatus  := aDocumentStatus;
    end if;

    -- Recherche du status de la position si ce dernier n'est pas passé en paramètre
    if     aPositionStatus is null
       and aPositionId is not null then
      begin
        select C_DOC_POS_STATUS
          into positionStatus
          from DOC_POSITION
         where DOC_POSITION_ID = aPositionId;
      exception
        when others then
          null;
      end;
    else
      positionStatus  := aPositionStatus;
    end if;

    -- Insertion des données dans la table d'historique des modifications
    insert into DOC_UPDATE_HISTORY
                (DOC_UPDATE_HISTORY_ID
               , DOC_DOCUMENT_ID
               , DOC_POSITION_ID
               , C_DOCUMENT_STATUS
               , C_DOC_POS_STATUS
               , DMT_NUMBER
               , DUH_TYPE
               , DUH_DESCRIPTION
               , DUH_FREE
               , DUH_USER
               , DUH_MACHINE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , aDocumentId
               , aPositionId
               , documentStatus
               , positionStatus
               , nvl(docNumber, 'UNKNOWN')
               , aUpdateType
               , aUpdateDescr
               , aFreeDescription
               , user
               , userenv('TERMINAL')
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    commit;   /* Car on utilise une transaction autonome */
  end CreateHistoryInformation;

  /**
  * Description
  *   Fonction indiquant si un détail de position a déjà été déchargé (complètement ou partiellement)
  */
  function PosAlreadyDischarged(aPosDetId in number, aChildExcludeId in number)
    return number
  is
    result number(1);
  begin
    select sign(nvl(max(doc_position_detail_id), 0) )
      into result
      from doc_position_detail
     where doc_doc_position_detail_id = aPosDetId
       and doc_position_detail_id <> nvl(aChildExcludeId, 0);

    return result;
  end PosAlreadyDischarged;

  /**
  * Description
  *   Fonction indiquant si le document parent a déjà été en partie ou complètement déchargé
  */
  function DocAlreadyDischarged(aPosDetId in number, aChildExcludeId in number)
    return number
  is
    result number(1);
  begin
    select sign(nvl(max(doc_position_detail_id), 0) )
      into result
      from doc_position_detail
     where doc_doc_position_detail_id in(select pde2.doc_position_detail_id
                                           from doc_position_detail pde1
                                              , doc_position_detail pde2
                                          where pde1.doc_position_detail_id = aPosDetId
                                            and pde2.doc_document_id = pde1.doc_document_id)
       and doc_position_detail_id not in(select pde2.doc_position_detail_id
                                           from doc_position_detail pde1
                                              , doc_position_detail pde2
                                          where pde1.doc_position_detail_id = aChildExcludeId
                                            and pde2.doc_document_id = pde1.doc_document_id);

    return result;
  end DocAlreadyDischarged;

  /**
  * Description
  *    Modifie les status d'un document dans le but de le reconfirmer
  *    Attention, cela peut créer plusieurs documents en comptabilité
  */
  procedure ReactiveDocument(aDocumentId in number)
  is
  begin
    update DOC_DOCUMENT main
       set C_DOCUMENT_STATUS = '01'
         , DMT_FINANCIAL_CHARGING = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_DOCUMENT_ID = aDocumentId
       and exists(select DOC_GAUGE_ID
                    from DOC_GAUGE
                   where DOC_GAUGE_ID = main.DOC_GAUGE_ID
                     and GAU_CONFIRM_STATUS = 1);
  end ReactiveDocument;

  /**
  * function CheckMandatoryCharact
  * Description
  *    Fonction visible uniquement dans le package body
  *    permettant de vérifier si la saisie d'une valeur de caractéisation
  *    est obligatoire ou non
  * @created FP
  * @created 03/10/2002
  * @lastUpdate
  * @private
  * @param aCharactId : id de la caractérisation à tester
  * @param aMvtSort   : ENT ou SOR ou vide selon le mouvement de stock lié à la position à tester
  * @return True -> valeur obligatoire  False -> Valeur facultative
  */
  function CheckMandatoryCharact(aCharactId in number, aMvtSort in varchar2)
    return boolean
  is
    charactType   varchar2(10);
    stkManagement number(1);
    result        boolean      := false;
  begin
    -- Mvt de sortie, la caractérisation est toujours obligatoire
    if (aMvtSort = 'SOR') then
      result  := true;
    -- Pas de mvt, la caractérisation est obligatoire ou pas en fonction de la config DOC_ACCEPT_EMPTY_CHARACT_VALUE
    elsif(aMvtSort is null) then
      if PCS.PC_CONFIG.GetBooleanConfig('DOC_ACCEPT_EMPTY_CHARACT_VALUE') then
        result  := false;
      else
        result  := true;
      end if;
    elsif aMvtSort = 'ENT' then
      -- recherche le type de caractérisation et si elle est gérée en stock
      select C_CHARACT_TYPE
           , decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) CHA_STOCK_MANAGEMENT
        into charactType
           , stkManagement
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where GCO_CHARACTERIZATION_ID = aCharactId
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID;

      -- Pour les entrées de pièce et de lot non gérée en stock,
      -- la valeur de caractérisation n'est pas obligatoire
      if     stkManagement = 0
         and (   charactType in('3', '4')
              or PCS.PC_CONFIG.GetBooleanConfig('DOC_ACCEPT_EMPTY_CHARACT_VALUE') ) then
        result  := false;
      else
        result  := true;
      end if;
    end if;

    return result;
  end CheckMandatoryCharact;

  /**
  * Description
  *    Vérifie l'intégrité des caractérisations d'un document
  */
  procedure CheckCharacterizationParity(aDocumentId in number, aReturnId out number, aTestNA in number default 1)
  is
    -- curseur sur les détails à vérifier
    --  il faut que le gabarit gère les caractérisations
    --  que la quantité du detail soit différente de 0
    --  et que le champ gco_characterization_id soit renseigné
    cursor crCharacterizedDetails(cDocumentId number)
    is
      select pde.doc_position_id
           , pde.doc_position_detail_id
           , pde.gco_characterization_id
           , pde.gco_gco_characterization_id
           , pde.gco2_gco_characterization_id
           , pde.gco3_gco_characterization_id
           , pde.gco4_gco_characterization_id
           , decode(upper(pde.pde_characterization_value_1), 'N/A', decode(aTestNA, 1, null, pde_characterization_value_1), pde_characterization_value_1)
                                                                                                                                   pde_characterization_value_1
           , decode(upper(pde.pde_characterization_value_2), 'N/A', decode(aTestNA, 1, null, pde_characterization_value_2), pde_characterization_value_2)
                                                                                                                                   pde_characterization_value_2
           , decode(upper(pde.pde_characterization_value_3), 'N/A', decode(aTestNA, 1, null, pde_characterization_value_3), pde_characterization_value_3)
                                                                                                                                   pde_characterization_value_3
           , decode(upper(pde.pde_characterization_value_4), 'N/A', decode(aTestNA, 1, null, pde_characterization_value_4), pde_characterization_value_4)
                                                                                                                                   pde_characterization_value_4
           , decode(upper(pde.pde_characterization_value_5), 'N/A', decode(aTestNA, 1, null, pde_characterization_value_5), pde_characterization_value_5)
                                                                                                                                   pde_characterization_value_5
           , pos.stm_movement_kind_id
           , mok.c_movement_sort
           , gau.c_admin_domain
           , gas.gas_all_characterization
        from doc_position_detail pde
           , doc_position pos
           , doc_document dmt
           , doc_gauge_structured gas
           , doc_gauge gau
           , stm_movement_kind mok
       where pde.doc_document_id = cDocumentId
         and pde.gco_characterization_id is not null
         and pde_final_quantity <> 0
         and pos.doc_position_id = pde.doc_position_id
         and dmt.doc_document_id = pos.doc_document_id
         and gas.doc_gauge_id = dmt.doc_gauge_id
         and gau.doc_gauge_id = gas.doc_gauge_id
         and gas.gas_characterization = 1
         and mok.stm_movement_kind_id(+) = pos.stm_movement_kind_id;

    tplCharacterizedDetail crCharacterizedDetails%rowtype;
    charactMissing         number(1);
    movementSort           STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
  begin
    -- Initialisation de la valeur de retour
    aReturnId  := 0;

    -- Recherche si il y a un problème potentiel
    select DMT_CHARACTERIZATION_MISSING
      into charactMissing
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    -- Le flag étant mis à 1 automatiquement par trigger en cas d'erreur, il ne peut pas y
    -- avoir de problème s'il est à 0, à moins qu'on l'ait mis manuellement à 0
    -- donc pour être plus rapide, on ne teste qu'en cas de problème potentiel
    if charactMissing = 1 then
      -- ouverture d'un curseur sur les details à vérifier
      open crCharacterizedDetails(aDocumentId);

      fetch crCharacterizedDetails
       into tplCharacterizedDetail;

      -- tant qu'il y a des details à vérifier et qu'aucun problème
      -- n'a été détecté
      while crCharacterizedDetails%found
       and aReturnId = 0 loop
        if tplCharacterizedDetail.stm_movement_kind_id is null then
          if     tplCharacterizedDetail.gas_all_characterization = 1
             and PCS.PC_CONFIG.GetConfig('DOC_CHARACTERIZATION_MODE') = '1' then
            if tplCharacterizedDetail.c_admin_domain = '1' then
              movementSort  := 'ENT';
            elsif     (tplCharacterizedDetail.c_admin_domain = '2')
                  and not PCS.PC_CONFIG.GetBooleanConfig('DOC_ACCEPT_EMPTY_CHARACT_VALUE') then
              movementSort  := 'SOR';
            else
              movementSort  := null;
            end if;
          else
            movementSort  := null;
          end if;
        else
          movementSort  := tplCharacterizedDetail.c_movement_sort;
        end if;

        -- tests d'intégrité des caractérisations
        if    (    tplCharacterizedDetail.gco_characterization_id is not null
               and tplCharacterizedDetail.pde_characterization_value_1 is null
               and CheckMandatoryCharact(tplCharacterizedDetail.gco_characterization_id, movementSort)
              )
           or (    tplCharacterizedDetail.gco_gco_characterization_id is not null
               and tplCharacterizedDetail.pde_characterization_value_2 is null
               and CheckMandatoryCharact(tplCharacterizedDetail.gco_gco_characterization_id, movementSort)
              )
           or (    tplCharacterizedDetail.gco2_gco_characterization_id is not null
               and tplCharacterizedDetail.pde_characterization_value_3 is null
               and CheckMandatoryCharact(tplCharacterizedDetail.gco2_gco_characterization_id, movementSort)
              )
           or (    tplCharacterizedDetail.gco3_gco_characterization_id is not null
               and tplCharacterizedDetail.pde_characterization_value_4 is null
               and CheckMandatoryCharact(tplCharacterizedDetail.gco3_gco_characterization_id, movementSort)
              )
           or (    tplCharacterizedDetail.gco4_gco_characterization_id is not null
               and tplCharacterizedDetail.pde_characterization_value_5 is null
               and CheckMandatoryCharact(tplCharacterizedDetail.gco4_gco_characterization_id, movementSort)
              ) then
          aReturnId  := tplCharacterizedDetail.doc_position_detail_id;
        end if;

        fetch crCharacterizedDetails
         into tplCharacterizedDetail;
      end loop;

      if aReturnId <> 0 then
        --raise_application_error(-20000,'error');
        -- Activation du flag d'erreur, et création d'un message d'erreur
        update doc_document
           set dmt_characterization_missing = 1
             , dmt_error_message = PCS.PC_FUNCTIONS.TranslateWord('Valeur(s) de caractérisation manquante(s)')
         where doc_document_id = aDocumentId;
      else
        -- Attention, on reset le message d'erreur ce qui pourrait en effacer un autre qui n'a
        -- rien à voir avec les caractérisations
        update doc_document
           set dmt_characterization_missing = 0
             , dmt_error_message = null
         where doc_document_id = aDocumentId;
      end if;

      close crCharacterizedDetails;
    end if;
  exception
    when no_data_found then
      null;
  end CheckCharacterizationParity;

  /**
  * Description
  *    Vérifie l'intégrité des caractérisations d'un détail de caractérisation
  *    et flag le document (DMT_CHARACTERIZATION_MISSING) si il y a un probleme
  *    Procedure devant être appelée depuis un trigger
  */
  procedure CheckDetailCharParity(
    aDocumentId in number
  , aPositionId in number
  , aChar1Id    in number
  , aChar2Id    in number
  , aChar3Id    in number
  , aChar4Id    in number
  , aChar5Id    in number
  , aCharValue1 in varchar2
  , aCharValue2 in varchar2
  , aCharValue3 in varchar2
  , aCharValue4 in varchar2
  , aCharValue5 in varchar2
  )
  is
    movementSort        stm_movement_kind.c_movement_sort%type;
    allCharacterization DOC_GAUGE_STRUCTURED.GAS_ALL_CHARACTERIZATION%type;
    adminDomain         DOC_GAUGE.C_ADMIN_DOMAIN%type;
    movementKindId      STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
  begin
    -- recherche du genre de mouvement
    select mok.c_movement_sort
         , gas.gas_all_characterization
         , gau.c_admin_domain
         , pos.stm_movement_kind_id
      into movementSort
         , allCharacterization
         , adminDomain
         , movementKindId
      from doc_position pos
         , stm_movement_kind mok
         , doc_gauge gau
         , doc_gauge_structured gas
     where doc_position_id = aPositionId
       and pos.stm_movement_kind_id = mok.stm_movement_kind_id(+)
       and gau.doc_gauge_id = pos.doc_gauge_id
       and gas.doc_gauge_id = gau.doc_gauge_id;

    -- Recherche du genre de mouvement
    if movementKindId is null then
      if     allCharacterization = 1
         and PCS.PC_CONFIG.GetConfig('DOC_CHARACTERIZATION_MODE') = '1' then
        if adminDomain = '1' then
          movementSort  := 'ENT';
        elsif adminDomain = '2' then
          movementSort  := 'SOR';
        else
          movementSort  := null;
        end if;
      else
        movementSort  := null;
      end if;
    else
      movementSort  := movementSort;
    end if;

    -- test si la caractérisation est vide et qu'elle devrait être obligatoire
    if    (    aChar1Id is not null
           and (   aCharValue1 is null
                or upper(aCharValue1) = 'N/A')
           and CheckMandatoryCharact(aChar1Id, movementSort) )
       or (    aChar2Id is not null
           and (   aCharValue2 is null
                or upper(aCharValue2) = 'N/A')
           and CheckMandatoryCharact(aChar2Id, movementSort) )
       or (    aChar3Id is not null
           and (   aCharValue3 is null
                or upper(aCharValue3) = 'N/A')
           and CheckMandatoryCharact(aChar3Id, movementSort) )
       or (    aChar4Id is not null
           and (   aCharValue4 is null
                or upper(aCharValue4) = 'N/A')
           and CheckMandatoryCharact(aChar4Id, movementSort) )
       or (    aChar5Id is not null
           and (   aCharValue5 is null
                or upper(aCharValue5) = 'N/A')
           and CheckMandatoryCharact(aChar5Id, movementSort) ) then
      update doc_document
         set dmt_characterization_missing = 1
       where doc_document_id = aDocumentId
         and dmt_characterization_missing = 0;
    end if;
  end CheckDetailCharParity;

  /**
  * procedure CheckDetailInstallation
  * Description
  *    Vérifie que les installations (DOC_RECORD_ID) soient renseignées
  */
  procedure CheckDetailInstallation(aDocumentID in number, aReturnId out number)
  is
  begin
    select min(PDE.DOC_POSITION_DETAIL_ID)
      into aReturnId
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where POS.DOC_DOCUMENT_ID = aDocumentID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and POS.C_GAUGE_TYPE_POS = '1'
       and (select count(*)
              from GCO_COMPL_DATA_EXTERNAL_ASA
             where GCO_GOOD_ID = POS.GCO_GOOD_ID) > 0
       and PDE.DOC_RECORD_ID is null;
  end CheckDetailInstallation;

  /**
  * procedure AppendZeroAmmountCorrection
  * Description
  *    Correction lorsque le montant monnaie document = 0 ET montant monnaie base <> 0
  */
  procedure AppendZeroAmmountCorrection(aDocumentId in number, aZeroAmountModified out number)
  is
    DocAmount        DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    DocAmount_B      DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type;
    CorrectionAmount DOC_FOOT.FOO_DOC_TOT_AMT_COR_B%type;
    footChargeId     DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type;
    positionId       DOC_POSITION.DOC_POSITION_ID%type;

    -- procédure interne retournant soit l'id de la remise/taxe de pied soit de la position
    -- sur laquelle on va reporter la correction TVA
    procedure GetReportId(aDocumentId in number, aFootChargeId out number, aPositionId out number)
    is
    begin
      -- recherche de la remise/taxe de pied ayant le plus grand montant (en valeur absolue)
      -- pour un compte TVA donné
      select max(FCH.DOC_FOOT_CHARGE_ID)
        into aFootChargeId
        from DOC_FOOT_CHARGE FCH
       where FCH.DOC_FOOT_ID = aDocumentId
         and FCH.FCH_EXCL_AMOUNT <> 0
         and abs(FCH.FCH_EXCL_AMOUNT) = (select max(abs(FCH2.FCH_EXCL_AMOUNT) )
                                           from DOC_FOOT_CHARGE FCH2
                                          where FCH2.DOC_FOOT_ID = aDocumentId);

      -- si on a pas trouvé de remise/taxe de pied
      if aFootChargeId is null then
        -- recherche de la position ayant le plus grand montant (en valeur absolue)
        -- pour un compte TVA donné
        select max(POS.DOC_POSITION_ID)
          into aPositionId
          from DOC_POSITION POS
         where POS.DOC_DOCUMENT_ID = aDocumentId
           and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '5', '7', '8', '9', '10', '71', '81', '91', '101', '21')
           and abs(POS.POS_NET_VALUE_EXCL) =
                 (select max(abs(POS2.POS_NET_VALUE_EXCL) )
                    from DOC_POSITION POS2
                   where POS2.DOC_DOCUMENT_ID = aDocumentId
                     and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '5', '7', '8', '9', '10', '71', '81', '91', '101', '21') );
      end if;
    end GetReportId;
  begin
    aZeroAmountModified  := 0;

    select FOO_DOCUMENT_TOTAL_AMOUNT
         , FOO_DOCUMENT_TOT_AMOUNT_B
         , (FOO_DOCUMENT_TOTAL_AMOUNT - FOO_DOCUMENT_TOT_AMOUNT_B) CORR_AMOUNT
      into DocAmount
         , DocAmount_B
         , CorrectionAmount
      from DOC_FOOT
     where DOC_FOOT_ID = aDocumentId;

    -- Appliquer une correction au montant du document si
    -- Montant document monnaie du document = 0 ET Montant document monnaie de Base <> 0
    if     (DocAmount = 0)
       and (DocAmount_B <> 0) then
      -- Recherche l'élément (position, foot_charge) sur lquel on va appliquer la correction
      GetReportId(aDocumentId, footChargeId, positionId);

      -- correction sur une remise/taxe/frais de pied
      if footChargeId is not null then
        -- Aporter la correction au frais/remise/taxe de pied qui a le plus grand montant
        update DOC_FOOT_CHARGE
           set FCH_EXCL_AMOUNT_B = FCH_EXCL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * CorrectionAmount
             , FCH_INCL_AMOUNT_B = FCH_INCL_AMOUNT_B + decode(C_FINANCIAL_CHARGE, '02', -1, 1) * CorrectionAmount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_FOOT_CHARGE_ID = footChargeId;

        -- Indique sur le pied de document quel à été l'élément pour la correction du montant en monnaie de base
        update DOC_FOOT
           set DOC_POSITION_ID = positionId
             , DOC_FOOT_CHARGE_ID = footChargeId
             , FOO_DOC_TOT_AMT_COR_B = CorrectionAmount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_FOOT_ID = aDocumentId;

        -- Màj du flag sur le document indiquant qu'il faut recalculer les montants totaux
        update DOC_DOCUMENT
           set DMT_RECALC_TOTAL = 1
         where DOC_DOCUMENT_ID = aDocumentId;

        aZeroAmountModified  := 1;
      elsif positionId is not null then
        -- Mise à jour de la position de report d'erreur
        update DOC_POSITION
           set POS_NET_VALUE_EXCL_B = POS_NET_VALUE_EXCL_B + CorrectionAmount
             , POS_NET_VALUE_INCL_B = POS_NET_VALUE_INCL_B + CorrectionAmount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_ID = positionId;

        -- Indique sur le pied de document quel à été l'élément pour la correction du montant en monnaie de base
        update DOC_FOOT
           set DOC_POSITION_ID = positionId
             , DOC_FOOT_CHARGE_ID = footChargeId
             , FOO_DOC_TOT_AMT_COR_B = CorrectionAmount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_FOOT_ID = aDocumentId;

        -- Màj du flag sur le document indiquant qu'il faut recalculer les montants totaux
        update DOC_DOCUMENT
           set DMT_RECALC_TOTAL = 1
         where DOC_DOCUMENT_ID = aDocumentId;

        aZeroAmountModified  := 1;
      end if;
    end if;
  end AppendZeroAmmountCorrection;

  /**
  * procedure RemoveZeroAmmountCorrection
  * Description
  *     Procedure de suppression du montant de correction
  *      lorsque le montant monnaie document = 0 ET montant monnaie base <> 0
  */
  procedure RemoveZeroAmmountCorrection(aDocumentId in number)
  is
    DocAmount        DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    DocAmount_B      DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type;
    CorrectionAmount DOC_FOOT.FOO_DOC_TOT_AMT_COR_B%type;
    footChargeId     DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type;
    positionId       DOC_POSITION.DOC_POSITION_ID%type;
  begin
    select DOC_POSITION_ID
         , DOC_FOOT_CHARGE_ID
         , FOO_DOC_TOT_AMT_COR_B
      into positionId
         , footChargeId
         , CorrectionAmount
      from DOC_FOOT
     where DOC_FOOT_ID = aDocumentId;

    -- Retirer la correction sur le document
    -- Montant document monnaie du document = 0 ET Montant document monnaie de Base <> 0
    if    (footChargeId is not null)
       or (positionId is not null) then
      -- Retirer la correction sur une remise/taxe/frais de pied
      if footChargeId is not null then
        -- Aporter la correction au frais/remise/taxe de pied qui a le plus grand montant
        update DOC_FOOT_CHARGE
           set FCH_EXCL_AMOUNT_B = FCH_EXCL_AMOUNT_B - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * CorrectionAmount
             , FCH_INCL_AMOUNT_B = FCH_INCL_AMOUNT_B - decode(C_FINANCIAL_CHARGE, '02', -1, 1) * CorrectionAmount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_FOOT_CHARGE_ID = footChargeId;

        -- Effacer sur le pied de document la référence sur l'élement de la correction
        update DOC_FOOT
           set DOC_POSITION_ID = null
             , DOC_FOOT_CHARGE_ID = null
             , FOO_DOC_TOT_AMT_COR_B = null
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_FOOT_ID = aDocumentId;
      elsif positionId is not null then
        -- Mise à jour de la position de report d'erreur
        update DOC_POSITION
           set POS_NET_VALUE_EXCL_B = POS_NET_VALUE_EXCL_B - CorrectionAmount
             , POS_NET_VALUE_INCL_B = POS_NET_VALUE_INCL_B - CorrectionAmount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_ID = positionId;

        -- Effacer sur le pied de document la référence sur l'élement de la correction
        update DOC_FOOT
           set DOC_POSITION_ID = null
             , DOC_FOOT_CHARGE_ID = null
             , FOO_DOC_TOT_AMT_COR_B = null
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_FOOT_ID = aDocumentId;
      end if;
    end if;
  end RemoveZeroAmmountCorrection;

  /**
  * Description
  *   Retourne le nombre de ventes entre deux date pour un bien, un stock, un emplacement
  */
  function SalesBetween2Dates(aGoodId in GCO_GOOD.GCO_GOOD_ID%type, aLocationId in STM_LOCATION.STM_LOCATION_ID%type, aDateFrom in date, aDateTo in date)
    return number
  is
    result DOC_POSITION.POS_FINAL_QUANTITY%type;
  begin
    select nvl(sum(decode(c_gauge_title, '8', 1, '9', -1) * PDE.PDE_FINAL_QUANTITY), 0)
      into result
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
         , DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
     where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
       and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and POS.GCO_GOOD_ID = aGoodId
       and GAS.C_GAUGE_TITLE in('8', '9')
       and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '9', '10')
       and DMT.DMT_DATE_DOCUMENT between nvl(aDateFrom, DMT_DATE_DOCUMENT) and nvl(aDateTo, DMT_DATE_DOCUMENT)
       and PDE.STM_LOCATION_ID = nvl(aLocationId, PDE.STM_LOCATION_ID);

    return result;
  end SalesBetween2Dates;

  /**
  * Description
  *   Retourne le nombre de ventes entre deux date pour un bien, un stock, un emplacement
  */
  function GrpSalesBetween2Dates(
    aPrgNAme    in GCO_PRODUCT_GROUP.PRG_NAME%type
  , aLocationId in STM_LOCATION.STM_LOCATION_ID%type
  , aDateFrom   in date
  , aDateTo     in date
  )
    return number
  is
    result DOC_POSITION.POS_FINAL_QUANTITY%type;
  begin
    select nvl(sum(decode(c_gauge_title, '8', 1, '9', -1) * PDE.PDE_FINAL_QUANTITY), 0)
      into result
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
         , DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
         , GCO_GOOD GOO
         , GCO_PRODUCT_GROUP PRG
     where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
       and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
       and GOO.GCO_PRODUCT_GROUP_ID = PRG.GCO_PRODUCT_GROUP_ID
       and PRG.PRG_NAME = aPrgName
       and GAS.C_GAUGE_TITLE in('8', '9')
       and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '9', '10')
       and DMT.DMT_DATE_DOCUMENT between nvl(aDateFrom, DMT_DATE_DOCUMENT) and nvl(aDateTo, DMT_DATE_DOCUMENT)
       and PDE.STM_LOCATION_ID = nvl(aLocationId, PDE.STM_LOCATION_ID);

    return result;
  end GrpSalesBetween2Dates;

  procedure SetValue(AFromValue in number, AToValue in out number)
  is
  begin
    AToValue  := AFromValue;
  end SetValue;

  procedure SetValue(AFromValue in varchar2, AToValue in out varchar2)
  is
  begin
    AToValue  := AFromValue;
  end SetValue;

  procedure SetValue(AFromValue in date, AToValue in out date)
  is
  begin
    AToValue  := AFromValue;
  end SetValue;

  function SetPOS_IMG(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    vPosPT   DOC_POSITION.DOC_DOC_POSITION_ID%type;
    vHasCPT  number;
    vShowCPT number;
  begin
    select DOC_DOC_POSITION_ID
         , decode(C_DOC_POS_STATUS, '04', 1, 0)
      into vPosPT
         , vShowCPT
      from DOC_POSITION
     where DOC_POSITION_ID = aPositionId;

    -- position parent
    if VPosPT is null then
      -- position parent non liquidée
      if vShowCPT = 0 then
        return 1;
      else
        select count(*)
          into vHasCPT
          from DOC_POSITION
         where DOC_DOC_POSITION_ID = aPositionId
           and (   C_DOC_POS_STATUS = '02'
                or C_DOC_POS_STATUS = '03')
           and C_GAUGE_TYPE_POS = '1';

        if vHasCPT = 0 then
          return 1;   -- position sans composant
        else
          return 2;   -- position avec composant
        end if;
      end if;
    else
      return 0;   -- position composant
    end if;
  end SetPOS_IMG;

  /**
  * procedure ExecuteExternProc
  * Description
  *   Execution de procédures externes utilisateur (pour les procédures définies dans le gabarit)
  */
  procedure ExecuteExternProc(aParamID number, aProcStatement in varchar2, aResultText out varchar2)
  is
    ProcsList    varchar2(260);
    tmpMethod    varchar2(100);
    SqlStatement varchar2(250);
    iContinue    integer;
  begin
    ProcsList  := upper(trim(aProcStatement) );

    if ProcsList is not null then
      iContinue  := 1;

      -- Rajouter un point virgule à la fin du string si pas déjà présent
      if substr(ProcsList, length(ProcsList), 1) <> ';' then
        ProcsList  := ProcsList || ';';
      end if;

      -- Tant qu'il y a des procédures/fonctions à éxecuter
      while(iContinue = 1)
       and (trim(ProcsList) is not null) loop
        -- copier le nom de la 1ere méthode de la liste à executer
        tmpMethod  := substr(ProcsList, 1, instr(ProcsList, ';') - 1);
        -- efface cette 1ere méthode de la liste
        ProcsList  := substr(ProcsList, instr(ProcsList, ';') + 1);

        -- la méthode à éxecuter est une procédure
        if instr(tmpMethod, 'PROCEDURE ') > 0 then
          -- effacer le mot 'PROCEDURE ' de la procédure à éxecuter
          tmpMethod     := trim(replace(tmpMethod, 'PROCEDURE ', '') );
          -- Procédure à executer
          SqlStatement  := 'begin ' || tmpMethod || '(:PARAM_ID); end;';

          -- Execution de la procédure
          execute immediate SqlStatement
                      using aParamID;
        -- la méthode à éxecuter est une fonction
        else
          -- effacer le mot 'FUNCTION ' de la fonction à éxecuter
          tmpMethod     := trim(replace(tmpMethod, 'FUNCTION ', '') );
          -- Fonction à executer
          SqlStatement  := 'select ' || tmpMethod || '(:PARAM_ID) FROM DUAL';

          -- Execution de la fonction
          execute immediate SqlStatement
                       into aResultText
                      using aParamID;

          -- La fonction utilisateur demande d'arreter le traitement
          if instr(upper(aResultText), '[ABORT]') > 0 then
            iContinue  := 0;
          end if;
        end if;
      end loop;
    end if;
  exception
    when others then
      aResultText  := '[ABORT] - PCS Error during the execution of an external procedure';
  end ExecuteExternProc;

  /**
  * Description
  *   retourne un si on a affaire à un document TTC
  */
  function isDocumentTTC(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lResult number(1);
  begin
    -- Recherche si au moins un gabarit position est geré TTC
    select DOC_I_LIB_GAUGE.isGaugeTTC(DOC_GAUGE_ID)
      into lResult
      from DOC_DOCUMENT DOC
     where DOC.DOC_DOCUMENT_ID = aDocumentId;

    return lResult;
  end isDocumentTTC;
end DOC_FUNCTIONS;
