--------------------------------------------------------
--  DDL for Package Body DOC_DISCOUNT_CHARGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DISCOUNT_CHARGE" 
is
  /**
  * Description  : création des remises et taxes de position
  */
  procedure CreatePositionCharge(
    position_id      in     doc_position.doc_position_id%type
  , dateref          in     date
  , quantityref      in     doc_position.pos_basis_quantity%type
  , currency_id      in     acs_financial_currency.acs_financial_currency_id%type
  , rate_of_exchange in     doc_document.dmt_rate_of_exchange%type
  , base_price       in     doc_document.dmt_base_price%type
  , lang_id          in     doc_document.pc_lang_id%type
  , created          out    numBoolean
  , aChargeAmount    out    doc_position.pos_charge_amount%type
  , aDiscountAmount  out    doc_position.pos_discount_amount%type
  )
  is
    position_tuple          doc_position%rowtype;
    is_already_charges      number(1);
    charge_type             PTC_CHARGE.C_CHARGE_TYPE%type;
    admin_domain            DOC_GAUGE.C_ADMIN_DOMAIN%type;
    numchanged              integer;
    templist                varchar2(20000);
    chargelist              varchar2(20000);
    discountlist            varchar2(20000);
    pchAmount               DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    pchBalanceAmount        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    liabledAmount           DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    cascadeAmount           DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    unitLiabledAmount       DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    FinancialID             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    DivisionID              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CpnID                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CdaID                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PfID                    ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PjID                    ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    blnCharge               number(1);
    blnDiscount             number(1);
    lNewPositionChargeId    DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type;

    cursor crDiscountCharge(astrChargeList varchar2, astrDiscountList varchar2, lang_id number)
    is
      select   DNT.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(DID_DESCR, DNT_NAME) DESCR
             , DNT_NAME PTC_NAME
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , cast(null as varchar2(4000) ) SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE CHARGE_TYPE
             , DNT_EXCLUSIVE EXCLUSIF
             , decode(C_DISCOUNT_KIND, 'TOT', null, DNT_PRCS_USE) PRCS_USE
          from PTC_DISCOUNT DNT
             , PTC_DISCOUNT_DESCR DID
             , (select column_value as PTC_DISCOUNT_ID
                  from table(PCS.idListToTable(astrDiscountList) ) ) DNT_LST
         where DNT.PTC_DISCOUNT_ID = DNT_LST.PTC_DISCOUNT_ID
           and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
           and DID.PC_LANG_ID(+) = lang_id
      union
      select   0 PTC_DISCOUNT_ID
             , CRG.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(CHD_DESCR, CRG_NAME) DESCR
             , CRG_NAME PTC_NAME
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE CHARGE_TYPE
             , CRG_EXCLUSIVE EXCLUSIF
             , decode(C_CHARGE_KIND, 'TOT', null, CRG_PRCS_USE) PRCS_USE
          from PTC_CHARGE CRG
             , PTC_CHARGE_DESCRIPTION CHD
             , (select column_value as PTC_CHARGE_ID
                  from table(PCS.idListToTable(astrChargeList) ) ) CRG_LST
         where CRG.PTC_CHARGE_ID = CRG_LST.PTC_CHARGE_ID
           and CRG.PTC_CHARGE_ID = CHD.PTC_CHARGE_ID(+)
           and CHD.PC_LANG_ID(+) = lang_id
      order by SERIES_CALC
             , PTC_NAME;

    blnFound                number(1);
    vGestValueQuantity      DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    vQuantity               DOC_POSITION.POS_FINAL_QUANTITY%type;
    vFinancial              DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical             DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl              DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vAccountInfo            ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    exclusiveDiscountId     PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    exclusiveDiscountAmount DOC_POSITION.POS_DISCOUNT_AMOUNT%type             default 0;
    exclusiveChargeId       PTC_CHARGE.PTC_CHARGE_ID%type;
    exclusiveChargeAmount   DOC_POSITION.POS_CHARGE_AMOUNT%type               default 0;
  begin
    created          := 0;
    aChargeAmount    := 0;
    aDiscountAmount  := 0;
    -- création des taxes liées aux opérations de fabrication
    CreateOperationPositionCharge(aPositionId => position_id, aCreated => created, aChargeAmount => aChargeAmount);

    -- pointeur sur la position a traîter
    select *
      into position_tuple
      from doc_position
     where doc_position_id = position_id;

    -- Si le position est au tarif net, il ne faut pas créer ou copier les remises et taxes
    if (nvl(position_tuple.POS_NET_TARIFF, 0) = 1) then
      created  := 0;
    else
      -- recherche d'info dans le gabarit
      select decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
           , C_ADMIN_DOMAIN
           , GAS_CHARGE
           , GAS_DISCOUNT
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
           , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
        into charge_type
           , admin_domain
           , blnCharge
           , blnDiscount
           , vFinancial
           , vAnalytical
           , vInfoCompl
        from doc_gauge GAU
           , doc_gauge_structured GAS
       where GAU.doc_gauge_id = position_tuple.doc_gauge_id
         and GAS.doc_gauge_id = GAU.doc_gauge_id;

      -- recherche des remises/taxes
      PTC_FIND_DISCOUNT_CHARGE.TESTDETDISCOUNTCHARGE(nvl(position_tuple.DOC_GAUGE_ID, 0)
                                                   , nvl(nvl(position_tuple.PAC_THIRD_TARIFF_ID, position_tuple.PAC_THIRD_ID), 0)
                                                   , nvl(position_tuple.DOC_RECORD_ID, 0)
                                                   , nvl(position_tuple.GCO_GOOD_ID, 0)
                                                   , charge_type
                                                   , dateref
                                                   , blnCharge
                                                   , blnDiscount   -- blncharge
                                                   , numchanged   -- blndiscount
                                                    );
      -- récupération de la liste des taxes
      templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'DET');
      chargelist    := templist;

      while length(templist) > 1987 loop
        templist    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'DET');
        chargelist  := chargeList || templist;
      end loop;

      -- récupération de la liste des remises
      templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'DET');
      discountlist  := templist;

      while length(templist) > 1987 loop
        templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'DET');
        discountlist  := discountlist || templist;
      end loop;

      -- recherche du montant soumis en fonction du type de position (HT ou TTC)
      select decode(GAP_INCLUDE_TAX_TARIFF, 0, position_tuple.POS_GROSS_VALUE, 1, position_tuple.POS_GROSS_VALUE_INCL)
           , decode(GAP_INCLUDE_TAX_TARIFF, 0, position_tuple.POS_GROSS_VALUE, 1, position_tuple.POS_GROSS_VALUE_INCL)
           , decode(GAP_INCLUDE_TAX_TARIFF, 0, position_tuple.POS_GROSS_UNIT_VALUE, 1, position_tuple.POS_GROSS_UNIT_VALUE_INCL)
           , nvl(GAP_VALUE_QUANTITY, 0)
        into LiabledAmount
           , CascadeAmount
           , unitLiabledAmount
           , vGestValueQuantity
        from DOC_GAUGE_POSITION
       where DOC_GAUGE_POSITION_ID = position_tuple.DOC_GAUGE_POSITION_ID;

      -- ouverture d'un query sur les infos des remises/taxes
      for tplDiscountCharge in crDiscountCharge(chargelist, discountlist, lang_id) loop
        -- Remises/taxes cascade
        if tplDiscountCharge.SERIES_CALC = 1 then
          LiabledAmount  := CascadeAmount;

          ----
          -- Recalcul le montant soumis unitaire lorsque la charge est en cascade.
          -- En effet, dans ce cas la, il ne faut pas prendre le montant unitaire
          -- de la position.
          --
          if (vGestValueQuantity = 1) then
            if (position_tuple.POS_VALUE_QUANTITY <> 0) then
              unitLiabledAmount  := CascadeAmount / position_tuple.POS_VALUE_QUANTITY;
            else
              unitLiabledAmount  := CascadeAmount;
            end if;
          else
            if (position_tuple.POS_FINAL_QUANTITY <> 0) then
              unitLiabledAmount  := CascadeAmount / position_tuple.POS_FINAL_QUANTITY;
            else
              unitLiabledAmount  := CascadeAmount;
            end if;
          end if;
        end if;

        -- Recherche de la quantité à prendre en compte.
        if (vGestValueQuantity = 1) then
          vQuantity  := position_tuple.POS_VALUE_QUANTITY;
        else
          vQuantity  := position_tuple.POS_FINAL_QUANTITY;
        end if;

        -- traitement des taxes
        if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
          PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   -- Id de la taxe à calculer
                                 , tplDiscountCharge.descr   -- Nom de la taxe
                                 , unitLiabledAmount   -- Montant unitaire soumis à la taxe en monnaie document
                                 , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                 , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                 , vQuantity   -- Pour les taxes de type détail, quantité de la position
                                 , nvl(quantityRef, vQuantity)   -- quantité de référence pour les tests d'applicabilité
                                 , position_tuple.GCO_GOOD_ID   -- Identifiant du bien
                                 , nvl(position_tuple.PAC_THIRD_TARIFF_ID, position_tuple.PAC_THIRD_ID)   -- Identifiant du tiers tarification
                                 , position_tuple.DOC_POSITION_ID   -- Identifiant de la position pour les taxes détaillées de type 8 (plsql)
                                 , null   -- Identifiant du document pour les taxes de type total de type 8 (plsql)
                                 , currency_id   -- Id de la monnaie du montant soumis
                                 , rate_of_exchange   -- Taux de change
                                 , base_price   -- Diviseur
                                 , dateref   -- Date de référence
                                 , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                 , tplDiscountCharge.rate   -- Taux
                                 , tplDiscountCharge.fraction   -- Fraction
                                 , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                 , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de remise)
                                 , tplDiscountCharge.quantity_from   -- Quantité de
                                 , tplDiscountCharge.quantity_to   -- Quantité a
                                 , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                 , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                 , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                 , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                 , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                 , tplDiscountCharge.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                 , tplDiscountCharge.automatic_calc
                                 -- Calculation auto ou à partir de sql_Extern_item
          ,                        tplDiscountCharge.sql_extern_item   -- Commande sql de recherche du montant soumis à la calculation
                                 , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                 , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                 , tplDiscountCharge.unit_detail   -- Détail unitaire
                                 , tplDiscountCharge.original   -- Origine de la taxe (1 = création, 0 = modification)
                                 , 0   -- taxe de position simple obligatoirement non cumulative
                                 , pchAmount   -- Montant de la taxe
                                 , blnFound   -- Taxe trouvée
                                  );

          -- Si gestion des comptes financiers ou analytiques
          if     (blnFound = 1)
             and (    (vFinancial = 1)
                  or (vAnalytical = 1) ) then
            -- Utilise les comptes de la taxe
            FinancialID                         := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
            DivisionID                          := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
            CpnId                               := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
            CdaId                               := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
            PfId                                := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
            PjId                                := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
            vAccountInfo.DEF_HRM_PERSON         := null;
            vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
            vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
            vAccountInfo.DEF_DIC_IMP_FREE1      := null;
            vAccountInfo.DEF_DIC_IMP_FREE2      := null;
            vAccountInfo.DEF_DIC_IMP_FREE3      := null;
            vAccountInfo.DEF_DIC_IMP_FREE4      := null;
            vAccountInfo.DEF_DIC_IMP_FREE5      := null;
            vAccountInfo.DEF_TEXT1              := null;
            vAccountInfo.DEF_TEXT2              := null;
            vAccountInfo.DEF_TEXT3              := null;
            vAccountInfo.DEF_TEXT4              := null;
            vAccountInfo.DEF_TEXT5              := null;
            vAccountInfo.DEF_NUMBER1            := null;
            vAccountInfo.DEF_NUMBER2            := null;
            vAccountInfo.DEF_NUMBER3            := null;
            vAccountInfo.DEF_NUMBER4            := null;
            vAccountInfo.DEF_NUMBER5            := null;
            vAccountInfo.DEF_DATE1              := null;
            vAccountInfo.DEF_DATE2              := null;
            vAccountInfo.DEF_DATE3              := null;
            vAccountInfo.DEF_DATE4              := null;
            vAccountInfo.DEF_DATE5              := null;
            -- recherche des comptes
            ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_CHARGE_ID
                                                     , '30'
                                                     , admin_domain
                                                     , DateRef
                                                     , position_tuple.DOC_GAUGE_ID
                                                     , position_tuple.DOC_DOCUMENT_ID
                                                     , position_id
                                                     , position_tuple.DOC_RECORD_ID
                                                     , position_tuple.PAC_THIRD_ACI_ID
                                                     , position_tuple.ACS_FINANCIAL_ACCOUNT_ID
                                                     , position_tuple.ACS_DIVISION_ACCOUNT_ID
                                                     , position_tuple.ACS_CPN_ACCOUNT_ID
                                                     , position_tuple.ACS_CDA_ACCOUNT_ID
                                                     , position_tuple.ACS_PF_ACCOUNT_ID
                                                     , position_tuple.ACS_PJ_ACCOUNT_ID
                                                     , FinancialID
                                                     , DivisionId
                                                     , CpnId
                                                     , CdaId
                                                     , PfId
                                                     , PjId
                                                     , vAccountInfo
                                                      );

            if (vAnalytical = 0) then
              CpnID  := null;
              CdaID  := null;
              PjID   := null;
              PfID   := null;
            end if;
          end if;
        -- traitement des remises
        else
          PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   -- Id de la remise à calculer
                                   , unitLiabledAmount   -- Montant unitaire soumis à la remise en monnaie document
                                   , liabledAmount   -- Montant soumis à la remise en monnaie document
                                   , liabledAmount   -- Montant soumis à la remise en monnaie document
                                   , vQuantity   -- Pour les remises de type détail, quantité de la position
                                   , nvl(quantityRef, vQuantity)   -- quantité de référence pour les tests d'applicabilité
                                   , position_tuple.DOC_POSITION_ID   -- Identifiant de la position pour les remises détaillées de type 8 (plsql)
                                   , null   -- Identifiant du document pour les remises de type total de type 8 (plsql)
                                   , currency_id   -- Id de la monnaie du montant soumis
                                   , rate_of_exchange   -- Taux de change
                                   , base_price   -- Diviseur
                                   , dateref   -- Date de référence
                                   , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                   , tplDiscountCharge.rate   -- Taux
                                   , tplDiscountCharge.fraction   -- Fraction
                                   , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                   , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de taxe)
                                   , tplDiscountCharge.quantity_from   -- Quantité de
                                   , tplDiscountCharge.quantity_to   -- Quantité a
                                   , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                   , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                   , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                   , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                   , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                   , tplDiscountCharge.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                   , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                   , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                   , tplDiscountCharge.unit_detail   -- Détail unitaire
                                   , tplDiscountCharge.original   -- Origine de la remise (1 = création, 0 = modification)
                                   , 0   -- remise de position simple obligatoirement non cumulative
                                   , pchAmount   -- Montant de la remise
                                   , blnFound   -- Remise trouvée
                                    );

          -- Si gestion des comptes financiers ou analytiques
          if     (blnFound = 1)
             and (    (vFinancial = 1)
                  or (vAnalytical = 1) ) then
            -- Utilise les comptes de la remise
            FinancialID                         := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
            DivisionID                          := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
            CpnId                               := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
            CdaId                               := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
            PfId                                := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
            PjId                                := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
            vAccountInfo.DEF_HRM_PERSON         := null;
            vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
            vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
            vAccountInfo.DEF_DIC_IMP_FREE1      := null;
            vAccountInfo.DEF_DIC_IMP_FREE2      := null;
            vAccountInfo.DEF_DIC_IMP_FREE3      := null;
            vAccountInfo.DEF_DIC_IMP_FREE4      := null;
            vAccountInfo.DEF_DIC_IMP_FREE5      := null;
            vAccountInfo.DEF_TEXT1              := null;
            vAccountInfo.DEF_TEXT2              := null;
            vAccountInfo.DEF_TEXT3              := null;
            vAccountInfo.DEF_TEXT4              := null;
            vAccountInfo.DEF_TEXT5              := null;
            vAccountInfo.DEF_NUMBER1            := null;
            vAccountInfo.DEF_NUMBER2            := null;
            vAccountInfo.DEF_NUMBER3            := null;
            vAccountInfo.DEF_NUMBER4            := null;
            vAccountInfo.DEF_NUMBER5            := null;
            -- recherche des comptes
            ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_DISCOUNT_ID
                                                     , '20'
                                                     , admin_domain
                                                     , DateRef
                                                     , position_tuple.DOC_GAUGE_ID
                                                     , position_tuple.DOC_DOCUMENT_ID
                                                     , position_id
                                                     , position_tuple.DOC_RECORD_ID
                                                     , position_tuple.PAC_THIRD_ACI_ID
                                                     , position_tuple.ACS_FINANCIAL_ACCOUNT_ID
                                                     , position_tuple.ACS_DIVISION_ACCOUNT_ID
                                                     , position_tuple.ACS_CPN_ACCOUNT_ID
                                                     , position_tuple.ACS_CDA_ACCOUNT_ID
                                                     , position_tuple.ACS_PF_ACCOUNT_ID
                                                     , position_tuple.ACS_PJ_ACCOUNT_ID
                                                     , FinancialID
                                                     , DivisionId
                                                     , CpnId
                                                     , CdaId
                                                     , PfId
                                                     , PjId
                                                     , vAccountInfo
                                                      );

            if (vAnalytical = 0) then
              CpnID  := null;
              CdaID  := null;
              PjID   := null;
              PfID   := null;
            end if;
          end if;
        end if;

        -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
        if blnFound = 1 then
          -- valeur de retour de la procedure indiquant qu'au moins une remise/taxe a été créée
          created               := 1;

          if    tplDiscountCharge.TRANSFERT_PROP = 0
             or position_tuple.POS_BASIS_QUANTITY = 0 then
            pchBalanceAmount  := pchAmount;
          else
            pchBalanceAmount  := (position_tuple.POS_BALANCE_QUANTITY / position_tuple.POS_BASIS_QUANTITY) * pchAmount;
          end if;

          lNewPositionChargeId  := GetNewId;

          -- création de la remise/taxe
          insert into DOC_POSITION_CHARGE
                      (DOC_POSITION_CHARGE_ID
                     , DOC_POSITION_ID
                     , C_CHARGE_ORIGIN
                     , C_FINANCIAL_CHARGE
                     , PCH_NAME
                     , PCH_DESCRIPTION
                     , PCH_AMOUNT
                     , PCH_BALANCE_AMOUNT
                     , PCH_CALC_AMOUNT
                     , PCH_LIABLED_AMOUNT
                     , PCH_FIXED_AMOUNT_B
                     , PCH_EXCEEDED_AMOUNT_FROM
                     , PCH_EXCEEDED_AMOUNT_TO
                     , PCH_MIN_AMOUNT
                     , PCH_MAX_AMOUNT
                     , PCH_QUANTITY_FROM
                     , PCH_QUANTITY_TO
                     , C_ROUND_TYPE
                     , PCH_ROUND_AMOUNT
                     , C_CALCULATION_MODE
                     , PCH_TRANSFERT_PROP
                     , PCH_MODIFY
                     , PCH_UNIT_DETAIL
                     , PCH_IN_SERIES_CALCULATION
                     , PCH_AUTOMATIC_CALC
                     , PCH_IS_MULTIPLICATOR
                     , PCH_EXCLUSIVE
                     , PCH_STORED_PROC
                     , PCH_SQL_EXTERN_ITEM
                     , PTC_DISCOUNT_ID
                     , PTC_CHARGE_ID
                     , PCH_RATE
                     , PCH_EXPRESS_IN
                     , PCH_CUMULATIVE
                     , PCH_DISCHARGED
                     , PCH_PRCS_USE
                     , DOC_DOC_POSITION_CHARGE_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_DIVISION_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                     , HRM_PERSON_ID
                     , FAM_FIXED_ASSETS_ID
                     , C_FAM_TRANSACTION_TYP
                     , PCH_IMP_TEXT_1
                     , PCH_IMP_TEXT_2
                     , PCH_IMP_TEXT_3
                     , PCH_IMP_TEXT_4
                     , PCH_IMP_TEXT_5
                     , PCH_IMP_NUMBER_1
                     , PCH_IMP_NUMBER_2
                     , PCH_IMP_NUMBER_3
                     , PCH_IMP_NUMBER_4
                     , PCH_IMP_NUMBER_5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                     , PCH_IMP_DATE_1
                     , PCH_IMP_DATE_2
                     , PCH_IMP_DATE_3
                     , PCH_IMP_DATE_4
                     , PCH_IMP_DATE_5
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (lNewPositionChargeId
                     , position_tuple.DOC_POSITION_ID
                     , 'AUTO'
                     , decode(tplDiscountCharge.PTC_CHARGE_ID, 0, '02', '03')
                     , tplDiscountCharge.PTC_NAME
                     , tplDiscountCharge.Descr
                     , pchAmount
                     , pchBalanceAmount
                     , pchAmount
                     , LiabledAmount
                     , tplDiscountCharge.FIXED_AMOUNT_B
                     , tplDiscountCharge.EXCEEDED_AMOUNT_FROM
                     , tplDiscountCharge.EXCEEDED_AMOUNT_TO
                     , tplDiscountCharge.MIN_AMOUNT
                     , tplDiscountCharge.MAX_AMOUNT
                     , tplDiscountCharge.QUANTITY_FROM
                     , tplDiscountCharge.QUANTITY_TO
                     , tplDiscountCharge.C_ROUND_TYPE
                     , tplDiscountCharge.ROUND_AMOUNT
                     , tplDiscountCharge.C_CALCULATION_MODE
                     , tplDiscountCharge.TRANSFERT_PROP
                     , tplDiscountCharge.MODIF
                     , tplDiscountCharge.UNIT_DETAIL
                     , tplDiscountCharge.IN_SERIES_CALCULATION
                     , tplDiscountCharge.AUTOMATIC_CALC
                     , tplDiscountCharge.IS_MULTIPLICATOR
                     , tplDiscountCharge.EXCLUSIF
                     , tplDiscountCharge.STORED_PROC
                     , tplDiscountCharge.SQL_EXTERN_ITEM
                     , zvl(tplDiscountCharge.PTC_DISCOUNT_ID, null)
                     , zvl(tplDiscountCharge.PTC_CHARGE_ID, null)
                     , tplDiscountCharge.RATE
                     , tplDiscountCharge.FRACTION
                     , 0   -- remise/taxe non cumulée
                     , 0   -- ne provenant de décharge
                     , tplDiscountCharge.PRCS_USE
                     , null
                     , FinancialId
                     , DivisionId
                     , CpnId
                     , CdaId
                     , PfId
                     , PjId
                     , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                     , vAccountInfo.FAM_FIXED_ASSETS_ID
                     , vAccountInfo.C_FAM_TRANSACTION_TYP
                     , vAccountInfo.DEF_TEXT1
                     , vAccountInfo.DEF_TEXT2
                     , vAccountInfo.DEF_TEXT3
                     , vAccountInfo.DEF_TEXT4
                     , vAccountInfo.DEF_TEXT5
                     , to_number(vAccountInfo.DEF_NUMBER1)
                     , to_number(vAccountInfo.DEF_NUMBER2)
                     , to_number(vAccountInfo.DEF_NUMBER3)
                     , to_number(vAccountInfo.DEF_NUMBER4)
                     , to_number(vAccountInfo.DEF_NUMBER5)
                     , vAccountInfo.DEF_DIC_IMP_FREE1
                     , vAccountInfo.DEF_DIC_IMP_FREE2
                     , vAccountInfo.DEF_DIC_IMP_FREE3
                     , vAccountInfo.DEF_DIC_IMP_FREE4
                     , vAccountInfo.DEF_DIC_IMP_FREE5
                     , vAccountInfo.DEF_DATE1
                     , vAccountInfo.DEF_DATE2
                     , vAccountInfo.DEF_DATE3
                     , vAccountInfo.DEF_DATE4
                     , vAccountInfo.DEF_DATE5
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          select aChargeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, 0, pchAmount)
            into aChargeAmount
            from dual;

          select aDiscountAmount + decode(tplDiscountCharge.PTC_DISCOUNT_ID, 0, 0, pchAmount)
            into aDiscountAmount
            from dual;

          select CascadeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, -pchAmount, pchAmount)
            into CascadeAmount
            from dual;

          if     tplDiscountCharge.PTC_DISCOUNT_ID <> 0
             and tplDiscountCharge.EXCLUSIF = 1
             and (   abs(pchAmount) > abs(exclusiveDiscountAmount)
                  or exclusiveDiscountId is null) then
            exclusiveDiscountAmount  := pchAmount;
            exclusiveDiscountId      := lNewPositionChargeId;
          end if;

          if     tplDiscountCharge.PTC_CHARGE_ID <> 0
             and tplDiscountCharge.EXCLUSIF = 1
             and (   abs(pchAmount) > abs(exclusiveChargeAmount)
                  or exclusiveChargeId is null) then
            exclusiveChargeAmount  := pchAmount;
            exclusiveChargeId      := lNewPositionChargeId;
          end if;
        end if;
      end loop;

      -- Si on a des remises exclusives, effacement des remises différentes de la plus grande remise exclusive
      if exclusiveDiscountId is not null then
        delete from DOC_POSITION_CHARGE
              where DOC_POSITION_CHARGE_ID <> exclusiveDiscountId
                and PTC_DISCOUNT_ID is not null
                and DOC_POSITION_ID = position_id;

        aDiscountAmount  := exclusiveDiscountAmount;
      end if;

      -- Si on a des taxes exclusives, effacement des taxes différentes de la plus grande taxe exclusive
      if exclusiveChargeId is not null then
        delete from DOC_POSITION_CHARGE
              where DOC_POSITION_CHARGE_ID <> exclusiveChargeId
                and PTC_CHARGE_ID is not null
                and DOC_POSITION_ID = position_id;

        aChargeAmount  := exclusiveChargeAmount;
      end if;

      update DOC_POSITION
         set POS_CREATE_POSITION_CHARGE = 0
           , POS_UPDATE_POSITION_CHARGE = 0
       where DOC_POSITION_ID = position_id;
    end if;
  end CreatePositionCharge;

  /**
  * Description  : création des remises et taxes de position
  */
  procedure CreatePositionCharge(
    position_id      in     doc_position.doc_position_id%type
  , dateref          in     date
  , currency_id      in     acs_financial_currency.acs_financial_currency_id%type
  , rate_of_exchange in     doc_document.dmt_rate_of_exchange%type
  , base_price       in     doc_document.dmt_base_price%type
  , lang_id          in     doc_document.pc_lang_id%type
  , created          out    numBoolean
  , aChargeAmount    out    doc_position.pos_charge_amount%type
  , aDiscountAmount  out    doc_position.pos_discount_amount%type
  )
  is
  begin
    CreatePositionCharge(position_id, dateref, null, currency_id, rate_of_exchange, base_price, lang_id, created, aChargeAmount, aDiscountAmount);
  end CreatePositionCharge;

  /**
  *    Description  : création des remises et taxes par groupe de biens
  */
  procedure CreateGroupPositionCharge(
    aDocumentId     in     doc_document.doc_document_id%type
  , aDateref        in     date
  , aCurrencyId     in     acs_financial_currency.acs_financial_currency_id%type
  , aRateOfExchange in     doc_document.dmt_rate_of_exchange%type
  , aBasePrice      in     doc_document.dmt_base_price%type
  , aLangId         in     doc_document.pc_lang_id%type
  , aCreated        out    numBoolean
  )
  is
    cursor crDocumentGoodGroup(cDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   DMT.DOC_GAUGE_ID
             , DMT.PAC_THIRD_ID
             , DMT.PAC_THIRD_ACI_ID
             , DMT.PAC_THIRD_TARIFF_ID
             , DMT.DOC_RECORD_ID
             , GOO.DIC_PTC_GOOD_GROUP_ID
             , sum(POS.POS_FINAL_QUANTITY) POS_FINAL_QUANTITY
             , sum(POS.POS_VALUE_QUANTITY) POS_VALUE_QUANTITY
             , avg(POS.POS_GROSS_UNIT_VALUE) POS_GROSS_UNIT_VALUE
             , sum(POS.POS_GROSS_VALUE) POS_GROSS_VALUE
             , avg(POS.POS_GROSS_UNIT_VALUE_INCL) POS_GROSS_UNIT_VALUE_INCL
             , sum(POS.POS_GROSS_VALUE_INCL) POS_GROSS_VALUE_INCL
             , max(DOC_GAUGE_POSITION_ID) DOC_GAUGE_POSITION_ID
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , GCO_GOOD GOO
         where DMT.DOC_DOCUMENT_ID = cDocumentId
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and GOO.DIC_PTC_GOOD_GROUP_ID is not null
           and POS.POS_CUMULATIVE_CHARGE = 1
           and POS.POS_NET_TARIFF = 0
           and (   POS.DOC_DOC_POSITION_ID is null
                or not exists(select DOC_POSITION_ID
                                from DOC_POSITION
                               where DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                                 and C_GAUGE_TYPE_POS in('7', '8', '10') ) )
      group by DMT.DOC_GAUGE_ID
             , DMT.PAC_THIRD_ID
             , DMT.PAC_THIRD_ACI_ID
             , DMT.PAC_THIRD_TARIFF_ID
             , DMT.DOC_RECORD_ID
             , GOO.DIC_PTC_GOOD_GROUP_ID;

    cursor crGroupPosition(cDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type, cGoodGroupId GCO_GOOD.DIC_PTC_GOOD_GROUP_ID%type)
    is
      select   POS.DOC_POSITION_ID
             , POS.POS_GROSS_VALUE
             , POS.POS_GROSS_VALUE_INCL
             , POS.POS_GROSS_UNIT_VALUE
             , POS.POS_GROSS_UNIT_VALUE_INCL
             , POS.POS_VALUE_QUANTITY
             , POS.POS_FINAL_QUANTITY
             , POS.GCO_GOOD_ID
             , POS.PAC_THIRD_ID
             , POS.PAC_THIRD_ACI_ID
             , POS.PAC_THIRD_TARIFF_ID
             , POS.DOC_GAUGE_ID
             , POS.DOC_RECORD_ID
             , POS.ACS_FINANCIAL_ACCOUNT_ID
             , POS.ACS_DIVISION_ACCOUNT_ID
             , POS.ACS_CPN_ACCOUNT_ID
             , POS.ACS_CDA_ACCOUNT_ID
             , POS.ACS_PF_ACCOUNT_ID
             , POS.ACS_PJ_ACCOUNT_ID
             , POS.DOC_GAUGE_POSITION_ID
             , POS.POS_PARENT_CHARGE
          from DOC_POSITION POS
             , GCO_GOOD GOO
         where GOO.DIC_PTC_GOOD_GROUP_ID = cGoodGroupId
           and POS.DOC_DOCUMENT_ID = cDocumentId
           and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
           and POS.POS_CUMULATIVE_CHARGE = 1
           and POS.POS_NET_TARIFF = 0
      order by POS.POS_NUMBER;

    cursor crDiscountCharge(astrChargeList varchar2, astrDiscountList varchar2, lang_id number)
    is
      select   DNT.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(DID_DESCR, DNT_NAME) DESCR
             , DNT_NAME PTC_NAME
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , cast(null as varchar2(4000) ) SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE CHARGE_TYPE
             , DNT_EXCLUSIVE EXCLUSIF
             , decode(C_DISCOUNT_KIND, 'TOT', null, DNT_PRCS_USE) PRCS_USE
          from PTC_DISCOUNT DNT
             , PTC_DISCOUNT_DESCR DID
             , (select column_value as PTC_DISCOUNT_ID
                  from table(PCS.idListToTable(astrDiscountList) ) ) DNT_LST
         where DNT.PTC_DISCOUNT_ID = DNT_LST.PTC_DISCOUNT_ID
           and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
           and DID.PC_LANG_ID(+) = lang_id
      union
      select   0 PTC_DISCOUNT_ID
             , CRG.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(CHD_DESCR, CRG_NAME) DESCR
             , CRG_NAME PTC_NAME
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE CHARGE_TYPE
             , CRG_EXCLUSIVE EXCLUSIF
             , decode(C_CHARGE_KIND, 'TOT', null, CRG_PRCS_USE) PRCS_USE
          from PTC_CHARGE CRG
             , PTC_CHARGE_DESCRIPTION CHD
             , (select column_value as PTC_CHARGE_ID
                  from table(PCS.idListToTable(astrChargeList) ) ) CRG_LST
         where CRG.PTC_CHARGE_ID = CRG_LST.PTC_CHARGE_ID
           and CRG.PTC_CHARGE_ID = CHD.PTC_CHARGE_ID(+)
           and CHD.PC_LANG_ID(+) = lang_id
      order by SERIES_CALC
             , PTC_NAME;

    charge_type         PTC_CHARGE.C_CHARGE_TYPE%type;
    admin_domain        DOC_GAUGE.C_ADMIN_DOMAIN%type;
    numchanged          integer;
    templist            varchar2(20000);
    chargelist          varchar2(20000);
    discountlist        varchar2(20000);
    pchAmount           DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    liabledAmount       DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    testLiabledAmount   DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    unitLiabledAmount   DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    FinancialID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    DivisionID          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CpnID               ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CdaID               ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PfID                ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PjID                ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    blnCharge           number(1);
    blnDiscount         number(1);
    blnFound            number(1);
    vGestValueQuantity  DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    vValueQuantity      DOC_POSITION.POS_VALUE_QUANTITY%type;
    vFinalQuantity      DOC_POSITION.POS_FINAL_QUANTITY%type;
    vQuantity           DOC_POSITION.POS_FINAL_QUANTITY%type;
    vFinancial          DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical         DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl          DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vAccountInfo        ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    exclusiveDiscountId PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    exclusiveChargeId   PTC_CHARGE.PTC_CHARGE_ID%type;
  begin
    aCreated  := 0;

    if PCS.PC_CONFIG.GetConfig('PTC_CUMULATIVE_DISCOUNT_CHARGE') = '1' then
      -- recherch d'info dans le gabarit
      select decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
           , C_ADMIN_DOMAIN
           , GAS_CHARGE
           , GAS_DISCOUNT
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
           , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
        into charge_type
           , admin_domain
           , blnCharge
           , blnDiscount
           , vFinancial
           , vAnalytical
           , vInfoCompl
        from doc_document DMT
           , doc_gauge GAU
           , doc_gauge_structured GAS
       where GAU.doc_gauge_id = DMT.doc_gauge_id
         and GAS.doc_gauge_id = GAU.doc_gauge_id
         and DMT.doc_document_id = aDocumentId;

      if    blnCharge = 1
         or blnDiscount = 1 then
        for tplDocumentGoodGroup in crDocumentGoodGroup(aDocumentId) loop
          -- recherche des remises/taxes
          PTC_FIND_DISCOUNT_CHARGE.TESTGRPDISCOUNTCHARGE(nvl(tplDocumentGoodGroup.DOC_GAUGE_ID, 0)
                                                       , nvl(nvl(tplDocumentGoodGroup.PAC_THIRD_TARIFF_ID, tplDocumentGoodGroup.PAC_THIRD_ID), 0)
                                                       , nvl(tplDocumentGoodGroup.DOC_RECORD_ID, 0)
                                                       , tplDocumentGoodGroup.DIC_PTC_GOOD_GROUP_ID
                                                       , charge_type
                                                       , aDateref
                                                       , blnCharge
                                                       ,   --blncharge
                                                         blnDiscount
                                                       ,   --blndiscount
                                                         numchanged
                                                        );
          -- récupération de la liste des taxes
          templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'GRP');
          chargelist    := templist;

          while length(templist) > 1987 loop
            templist    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'GRP');
            chargelist  := chargeList || templist;
          end loop;

          -- récupération de la liste des remises
          templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'GRP');
          discountlist  := templist;

          while length(templist) > 1987 loop
            templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'GRP');
            discountlist  := discountlist || templist;
          end loop;

          if    nvl(chargeList, ',0,') <> ',0,'
             or nvl(discountList, ',0,') <> ',0,' then
            for tplDiscountCharge in crDiscountCharge(chargeList, discountList, aLangId) loop
              -- Assignation de la variable de la quantité cumulée
              select sum(POS_VALUE_QUANTITY)
                   , sum(POS_FINAL_QUANTITY)
                into vValueQuantity
                   , vFinalQuantity
                from DOC_POSITION POS
                   , GCO_GOOD GOO
               where POS.DOC_DOCUMENT_ID = aDocumentId
                 and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
                 and GOO.DIC_PTC_GOOD_GROUP_ID = tplDocumentGoodGroup.DIC_PTC_GOOD_GROUP_ID
                 and (   POS.DOC_DOC_POSITION_ID is null
                      or not exists(select DOC_POSITION_ID
                                      from DOC_POSITION
                                     where DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                                       and C_GAUGE_TYPE_POS in('7', '10') ) );

              for tplGroupPosition in crGroupPosition(aDocumentId, tplDocumentGoodGroup.DIC_PTC_GOOD_GROUP_ID) loop
                if tplGroupPosition.POS_PARENT_CHARGE = 0 then
                  -- recherche du montant soumis en fonction du type de position (HT ou TTC)
                  select decode(GAP_INCLUDE_TAX_TARIFF, 0, tplGroupPosition.POS_GROSS_VALUE, 1, tplGroupPosition.POS_GROSS_VALUE_INCL)
                       , decode(GAP_INCLUDE_TAX_TARIFF, 0, tplDocumentGoodGroup.POS_GROSS_VALUE, 1, tplDocumentGoodGroup.POS_GROSS_VALUE_INCL)
                       , decode(GAP_INCLUDE_TAX_TARIFF, 0, tplDocumentGoodGroup.POS_GROSS_UNIT_VALUE, 1, tplDocumentGoodGroup.POS_GROSS_UNIT_VALUE_INCL)
                       , decode(nvl(GAP_VALUE_QUANTITY, 0), 0, vValueQuantity, 1, vFinalQuantity)
                    into liabledAmount
                       , testLiabledAmount
                       , unitLiabledAmount
                       , vQuantity
                    from DOC_GAUGE_POSITION
                   where DOC_GAUGE_POSITION_ID = tplGroupPosition.DOC_GAUGE_POSITION_ID;

                  -- traitement des taxes
                  if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
                    PTC_FUNCTIONS.CalcCharge
                                           (tplDiscountCharge.PTC_CHARGE_ID   -- Id de la taxe à calculer
                                          , tplDiscountCharge.descr   -- Nom de la taxe
                                          , unitLiabledAmount   -- Montant unitaire soumis à la taxe en monnaie document
                                          , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                          , testLiabledAmount   -- Montant soumis du groupe de biens à la taxe en monnaie document
                                          , vQuantity   -- Pour les taxes de type détail, quantité de la position
                                          , tplGroupPosition.GCO_GOOD_ID   -- Identifiant du bien
                                          , nvl(tplGroupPosition.PAC_THIRD_TARIFF_ID, tplGroupPosition.PAC_THIRD_ID)   -- Identifiant du tiers
                                          , tplGroupPosition.DOC_POSITION_ID   -- Identifiant de la position pour les taxes détaillées de type 8 (plsql)
                                          , null   -- Identifiant du document pour les taxes de type total de type 8 (plsql)
                                          , aCurrencyId   -- Id de la monnaie du montant soumis
                                          , aRateOfExchange   -- Taux de change
                                          , aBasePrice   -- Diviseur
                                          , aDateref   -- Date de référence
                                          , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                          , tplDiscountCharge.rate   -- Taux
                                          , tplDiscountCharge.fraction   -- Fraction
                                          , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                          , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de remise)
                                          , tplDiscountCharge.quantity_from   -- Quantité de
                                          , tplDiscountCharge.quantity_to   -- Quantité a
                                          , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                          , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                          , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                          , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                          , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                          , tplDiscountCharge.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                          , tplDiscountCharge.automatic_calc   -- Calculation auto ou à partir de sql_Extern_item
                                          , tplDiscountCharge.sql_extern_item   -- Commande sql de recherche du montant soumis à la calculation
                                          , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                          , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                          , tplDiscountCharge.unit_detail   -- Détail unitaire
                                          , tplDiscountCharge.original   -- Origine de la taxe (1 = création, 0 = modification)
                                          , 0   -- taxe de groupe -> 0 en mode création car la qté sert à sélectionner la remise et non à calculer
                                          , pchAmount   -- Montant de la taxe
                                          , blnFound   -- Taxe trouvée
                                           );

                    -- Si gestion des comptes financiers ou analytiques
                    if     (blnFound = 1)
                       and (    (vFinancial = 1)
                            or (vAnalytical = 1) ) then
                      -- Utilise les comptes de la taxe
                      FinancialID                         := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                      DivisionID                          := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                      CpnId                               := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                      CdaId                               := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                      PfId                                := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                      PjId                                := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                      vAccountInfo.DEF_HRM_PERSON         := null;
                      vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                      vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                      vAccountInfo.DEF_DIC_IMP_FREE1      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE2      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE3      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE4      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE5      := null;
                      vAccountInfo.DEF_TEXT1              := null;
                      vAccountInfo.DEF_TEXT2              := null;
                      vAccountInfo.DEF_TEXT3              := null;
                      vAccountInfo.DEF_TEXT4              := null;
                      vAccountInfo.DEF_TEXT5              := null;
                      vAccountInfo.DEF_NUMBER1            := null;
                      vAccountInfo.DEF_NUMBER2            := null;
                      vAccountInfo.DEF_NUMBER3            := null;
                      vAccountInfo.DEF_NUMBER4            := null;
                      vAccountInfo.DEF_NUMBER5            := null;
                      vAccountInfo.DEF_DATE1              := null;
                      vAccountInfo.DEF_DATE2              := null;
                      vAccountInfo.DEF_DATE3              := null;
                      vAccountInfo.DEF_DATE4              := null;
                      vAccountInfo.DEF_DATE5              := null;
                      -- recherche des comptes
                      ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_CHARGE_ID
                                                               , '30'
                                                               , admin_domain
                                                               , aDateRef
                                                               , tplGroupPosition.DOC_GAUGE_ID
                                                               , aDocumentId
                                                               , tplGroupPosition.DOC_POSITION_ID
                                                               , tplGroupPosition.DOC_RECORD_ID
                                                               , tplGroupPosition.PAC_THIRD_ACI_ID
                                                               , tplGroupPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_DIVISION_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_CPN_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_CDA_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_PF_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_PJ_ACCOUNT_ID
                                                               , FinancialID
                                                               , DivisionId
                                                               , CpnId
                                                               , CdaId
                                                               , PfId
                                                               , PjId
                                                               , vAccountInfo
                                                                );

                      if (vAnalytical = 0) then
                        CpnID  := null;
                        CdaID  := null;
                        PjID   := null;
                        PfID   := null;
                      end if;
                    end if;
                  -- traitement des remises
                  else
                    PTC_FUNCTIONS.CalcDiscount
                                             (tplDiscountCharge.PTC_DISCOUNT_ID   -- Id de la remise à calculer
                                            , unitLiabledAmount   -- Montant unitaire soumis à la remise en monnaie document
                                            , liabledAmount   -- Montant soumis à la remise en monnaie document
                                            , testLiabledAmount   -- Montant soumis du groupe de biens à la taxe en monnaie document
                                            , vQuantity   -- Pour les remises de type détail, quantité de la position
                                            , tplGroupPosition.DOC_POSITION_ID   -- Identifiant de la position pour les remises détaillées de type 8 (plsql)
                                            , null   -- Identifiant du document pour les remises de type total de type 8 (plsql)
                                            , aCurrencyId   -- Id de la monnaie du montant soumis
                                            , aRateOfExchange   -- Taux de change
                                            , aBasePrice   -- Diviseur
                                            , aDateref   -- Date de référence
                                            , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                            , tplDiscountCharge.rate   -- Taux
                                            , tplDiscountCharge.fraction   -- Fraction
                                            , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                            , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de taxe)
                                            , tplDiscountCharge.quantity_from   -- Quantité de
                                            , tplDiscountCharge.quantity_to   -- Quantité a
                                            , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                            , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                            , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                            , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                            , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                            , tplDiscountCharge.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                            , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                            , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                            , tplDiscountCharge.unit_detail   -- Détail unitaire
                                            , tplDiscountCharge.original   -- Origine de la remise (1 = création, 0 = modification)
                                            , 0   -- remise de groupe -> 0 en mode création car la qté sert à sélectionner la remise et non à calculer
                                            , pchAmount   -- Montant de la remise
                                            , blnFound   -- Remise trouvée
                                             );

                    -- Si gestion des comptes financiers ou analytiques
                    if     (blnFound = 1)
                       and (    (vFinancial = 1)
                            or (vAnalytical = 1) ) then
                      -- Utilise les comptes de la remise
                      FinancialID                         := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                      DivisionID                          := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                      CpnId                               := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                      CdaId                               := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                      PfId                                := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                      PjId                                := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                      vAccountInfo.DEF_HRM_PERSON         := null;
                      vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                      vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                      vAccountInfo.DEF_DIC_IMP_FREE1      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE2      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE3      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE4      := null;
                      vAccountInfo.DEF_DIC_IMP_FREE5      := null;
                      vAccountInfo.DEF_TEXT1              := null;
                      vAccountInfo.DEF_TEXT2              := null;
                      vAccountInfo.DEF_TEXT3              := null;
                      vAccountInfo.DEF_TEXT4              := null;
                      vAccountInfo.DEF_TEXT5              := null;
                      vAccountInfo.DEF_NUMBER1            := null;
                      vAccountInfo.DEF_NUMBER2            := null;
                      vAccountInfo.DEF_NUMBER3            := null;
                      vAccountInfo.DEF_NUMBER4            := null;
                      vAccountInfo.DEF_NUMBER5            := null;
                      vAccountInfo.DEF_DATE1              := null;
                      vAccountInfo.DEF_DATE2              := null;
                      vAccountInfo.DEF_DATE3              := null;
                      vAccountInfo.DEF_DATE4              := null;
                      vAccountInfo.DEF_DATE5              := null;
                      -- recherche des comptes
                      ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_DISCOUNT_ID
                                                               , '20'
                                                               , admin_domain
                                                               , aDateRef
                                                               , tplGroupPosition.DOC_GAUGE_ID
                                                               , aDocumentId
                                                               , tplGroupPosition.DOC_POSITION_ID
                                                               , tplGroupPosition.DOC_RECORD_ID
                                                               , tplGroupPosition.PAC_THIRD_ACI_ID
                                                               , tplGroupPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_DIVISION_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_CPN_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_CDA_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_PF_ACCOUNT_ID
                                                               , tplGroupPosition.ACS_PJ_ACCOUNT_ID
                                                               , FinancialID
                                                               , DivisionId
                                                               , CpnId
                                                               , CdaId
                                                               , PfId
                                                               , PjId
                                                               , vAccountInfo
                                                                );

                      if (vAnalytical = 0) then
                        CpnID  := null;
                        CdaID  := null;
                        PjID   := null;
                        PfID   := null;
                      end if;
                    end if;
                  end if;

                  -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
                  if blnFound = 1 then
                    -- valeur de retour de la procedure indiquant qu'au moins une remise/taxe a été créée
                    aCreated  := 1;

                    -- création de la remise/taxe
                    insert into DOC_POSITION_CHARGE
                                (DOC_POSITION_CHARGE_ID
                               , DOC_POSITION_ID
                               , C_CHARGE_ORIGIN
                               , C_FINANCIAL_CHARGE
                               , PCH_NAME
                               , PCH_DESCRIPTION
                               , PCH_AMOUNT
                               , PCH_BALANCE_AMOUNT
                               , PCH_CALC_AMOUNT
                               , PCH_LIABLED_AMOUNT
                               , PCH_FIXED_AMOUNT_B
                               , PCH_EXCEEDED_AMOUNT_FROM
                               , PCH_EXCEEDED_AMOUNT_TO
                               , PCH_MIN_AMOUNT
                               , PCH_MAX_AMOUNT
                               , PCH_QUANTITY_FROM
                               , PCH_QUANTITY_TO
                               , C_ROUND_TYPE
                               , PCH_ROUND_AMOUNT
                               , C_CALCULATION_MODE
                               , PCH_TRANSFERT_PROP
                               , PCH_MODIFY
                               , PCH_UNIT_DETAIL
                               , PCH_IN_SERIES_CALCULATION
                               , PCH_AUTOMATIC_CALC
                               , PCH_IS_MULTIPLICATOR
                               , PCH_EXCLUSIVE
                               , PCH_STORED_PROC
                               , PCH_SQL_EXTERN_ITEM
                               , PTC_DISCOUNT_ID
                               , PTC_CHARGE_ID
                               , PCH_RATE
                               , PCH_EXPRESS_IN
                               , PCH_CUMULATIVE
                               , PCH_DISCHARGED
                               , PCH_PRCS_USE
                               , DOC_DOC_POSITION_CHARGE_ID
                               , ACS_FINANCIAL_ACCOUNT_ID
                               , ACS_DIVISION_ACCOUNT_ID
                               , ACS_CPN_ACCOUNT_ID
                               , ACS_CDA_ACCOUNT_ID
                               , ACS_PF_ACCOUNT_ID
                               , ACS_PJ_ACCOUNT_ID
                               , HRM_PERSON_ID
                               , FAM_FIXED_ASSETS_ID
                               , C_FAM_TRANSACTION_TYP
                               , PCH_IMP_TEXT_1
                               , PCH_IMP_TEXT_2
                               , PCH_IMP_TEXT_3
                               , PCH_IMP_TEXT_4
                               , PCH_IMP_TEXT_5
                               , PCH_IMP_NUMBER_1
                               , PCH_IMP_NUMBER_2
                               , PCH_IMP_NUMBER_3
                               , PCH_IMP_NUMBER_4
                               , PCH_IMP_NUMBER_5
                               , DIC_IMP_FREE1_ID
                               , DIC_IMP_FREE2_ID
                               , DIC_IMP_FREE3_ID
                               , DIC_IMP_FREE4_ID
                               , DIC_IMP_FREE5_ID
                               , PCH_IMP_DATE_1
                               , PCH_IMP_DATE_2
                               , PCH_IMP_DATE_3
                               , PCH_IMP_DATE_4
                               , PCH_IMP_DATE_5
                               , A_DATECRE
                               , A_IDCRE
                                )
                         values (init_id_seq.nextval
                               , tplGroupPosition.DOC_POSITION_ID
                               , 'AUTO'
                               , decode(tplDiscountCharge.PTC_CHARGE_ID, 0, '02', '03')
                               , tplDiscountCharge.PTC_NAME
                               , tplDiscountCharge.Descr
                               , pchAmount
                               , pchAmount
                               , pchAmount
                               , LiabledAmount
                               , tplDiscountCharge.FIXED_AMOUNT_B
                               , tplDiscountCharge.EXCEEDED_AMOUNT_FROM
                               , tplDiscountCharge.EXCEEDED_AMOUNT_TO
                               , tplDiscountCharge.MIN_AMOUNT
                               , tplDiscountCharge.MAX_AMOUNT
                               , tplDiscountCharge.QUANTITY_FROM
                               , tplDiscountCharge.QUANTITY_TO
                               , tplDiscountCharge.C_ROUND_TYPE
                               , tplDiscountCharge.ROUND_AMOUNT
                               , tplDiscountCharge.C_CALCULATION_MODE
                               , tplDiscountCharge.TRANSFERT_PROP
                               , tplDiscountCharge.MODIF
                               , tplDiscountCharge.UNIT_DETAIL
                               , tplDiscountCharge.IN_SERIES_CALCULATION
                               , tplDiscountCharge.AUTOMATIC_CALC
                               , tplDiscountCharge.IS_MULTIPLICATOR
                               , tplDiscountCharge.EXCLUSIF
                               , tplDiscountCharge.STORED_PROC
                               , tplDiscountCharge.SQL_EXTERN_ITEM
                               , zvl(tplDiscountCharge.PTC_DISCOUNT_ID, null)
                               , zvl(tplDiscountCharge.PTC_CHARGE_ID, null)
                               , tplDiscountCharge.RATE
                               , tplDiscountCharge.FRACTION
                               , 1   -- remise/taxe cumulée
                               , 0   -- ne provenant de décharge
                               , tplDiscountCharge.PRCS_USE
                               , null
                               , FinancialId
                               , DivisionId
                               , CpnId
                               , CdaId
                               , PfId
                               , PjId
                               , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                               , vAccountInfo.FAM_FIXED_ASSETS_ID
                               , vAccountInfo.C_FAM_TRANSACTION_TYP
                               , vAccountInfo.DEF_TEXT1
                               , vAccountInfo.DEF_TEXT2
                               , vAccountInfo.DEF_TEXT3
                               , vAccountInfo.DEF_TEXT4
                               , vAccountInfo.DEF_TEXT5
                               , to_number(vAccountInfo.DEF_NUMBER1)
                               , to_number(vAccountInfo.DEF_NUMBER2)
                               , to_number(vAccountInfo.DEF_NUMBER3)
                               , to_number(vAccountInfo.DEF_NUMBER4)
                               , to_number(vAccountInfo.DEF_NUMBER5)
                               , vAccountInfo.DEF_DIC_IMP_FREE1
                               , vAccountInfo.DEF_DIC_IMP_FREE2
                               , vAccountInfo.DEF_DIC_IMP_FREE3
                               , vAccountInfo.DEF_DIC_IMP_FREE4
                               , vAccountInfo.DEF_DIC_IMP_FREE5
                               , vAccountInfo.DEF_DATE1
                               , vAccountInfo.DEF_DATE2
                               , vAccountInfo.DEF_DATE3
                               , vAccountInfo.DEF_DATE4
                               , vAccountInfo.DEF_DATE5
                               , sysdate
                               , PCS.PC_I_LIB_SESSION.GetUserIni
                                );

                    -- Si on a des remises exclusives, effacement des remises différentes de la plus grande remise exclusive
                    select max(DOC_POSITION_CHARGE_ID)
                      into exclusiveDiscountId
                      from DOC_POSITION_CHARGE
                     where PCH_EXCLUSIVE = 1
                       and PTC_DISCOUNT_ID is not null
                       and DOC_POSITION_ID = tplGroupPosition.DOC_POSITION_ID
                       and C_CHARGE_ORIGIN in('AUTO', 'MAN')
                       and PCH_AMOUNT =
                             (select max(PCH_AMOUNT)
                                from DOC_POSITION_CHARGE
                               where PCH_EXCLUSIVE = 1
                                 and DOC_POSITION_ID = tplGroupPosition.DOC_POSITION_ID
                                 and C_CHARGE_ORIGIN in('AUTO', 'MAN')
                                 and PTC_DISCOUNT_ID is not null);

                    if exclusiveDiscountId is not null then
                      delete from DOC_POSITION_CHARGE
                            where DOC_POSITION_CHARGE_ID <> exclusiveDiscountId
                              and PTC_DISCOUNT_ID is not null
                              and DOC_POSITION_ID = tplGroupPosition.DOC_POSITION_ID
                              and C_CHARGE_ORIGIN in('AUTO', 'MAN');
                    end if;

                    -- Si on a des taxes exclusives, effacement des taxes différentes de la plus grande taxe exclusive
                    select max(DOC_POSITION_CHARGE_ID)
                      into exclusiveChargeId
                      from DOC_POSITION_CHARGE
                     where PCH_EXCLUSIVE = 1
                       and PTC_CHARGE_ID is not null
                       and DOC_POSITION_ID = tplGroupPosition.DOC_POSITION_ID
                       and C_CHARGE_ORIGIN in('AUTO', 'MAN')
                       and PCH_AMOUNT =
                             (select max(PCH_AMOUNT)
                                from DOC_POSITION_CHARGE
                               where PCH_EXCLUSIVE = 1
                                 and DOC_POSITION_ID = tplGroupPosition.DOC_POSITION_ID
                                 and C_CHARGE_ORIGIN in('AUTO', 'MAN')
                                 and PTC_CHARGE_ID is not null);

                    if exclusiveChargeId is not null then
                      delete from DOC_POSITION_CHARGE
                            where DOC_POSITION_CHARGE_ID <> exclusiveChargeId
                              and PTC_CHARGE_ID is not null
                              and DOC_POSITION_ID = tplGroupPosition.DOC_POSITION_ID
                              and C_CHARGE_ORIGIN in('AUTO', 'MAN');
                    end if;

                    -- maj du flag de rcalcul des remises/taxes de positions et indirectement des montants de la position
                    update DOC_POSITION
                       set POS_UPDATE_POSITION_CHARGE = 1
                     where DOC_POSITION_ID = tplGroupPosition.DOC_POSITION_ID;
                  end if;
                end if;
              end loop;
            end loop;
          end if;
        end loop;
      end if;
    end if;
  end CreateGroupPositionCharge;

  /**
  * Description
  *   Création de la taxe de position  "générique" à utiliser pour la ventilation du prix de l'opération
  */
  procedure CreateOperationPositionCharge(
    aPositionId   in     doc_position.doc_position_id%type
  , aForceRedo    in     number default 0
  , aCreated      out    numBoolean
  , aChargeAmount out    doc_position.pos_charge_amount%type
  )
  is
    vFalScheduleStepId DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type;
    vScsAmount         FAL_TASK_LINK.SCS_AMOUNT%type;
    vPosQuantity       DOC_POSITION.POS_FINAL_QUANTITY%type;
    vRecPositionCharge DOC_POSITION_CHARGE%rowtype;
    vAccountInfo       ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vNbOpCharge        number(1);
    vFalLotId          FAL_LOT.FAL_LOT_ID%type;
    lnQtyRef           FAL_TASK_LINK.SCS_QTY_REF_AMOUNT%type;
    lnScsAmount        FAL_TASK_LINK.SCS_AMOUNT%type;

    cursor crOperationCharge(cPositionId DOC_POSITION.DOC_POSITION_ID%type, cChargeName PTC_CHARGE.CRG_NAME%type)
    is
      select GAU.C_ADMIN_DOMAIN
           , CRG.CRG_NAME
           , CHD.CHD_DESCR
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DOC_GAUGE_ID
           , nvl(POS.DOC_RECORD_ID, DMT.DOC_RECORD_ID) DOC_RECORD_ID
           , DMT.PAC_THIRD_ID
           , DMT.PAC_THIRD_ACI_ID
           , DMT.PAC_THIRD_TARIFF_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.PC_LANG_ID
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
           , CRG_IN_SERIE_CALCULATION
           , CRG.CRG_MODIFY
           , decode(C_CHARGE_KIND, 'TOT', null, CRG_PRCS_USE) PRCS_USE
           , CRG.PTC_CHARGE_ID
           , CRG.ACS_FINANCIAL_ACCOUNT_ID
           , CRG.ACS_DIVISION_ACCOUNT_ID
           , CRG.ACS_CPN_ACCOUNT_ID
           , CRG.ACS_CDA_ACCOUNT_ID
           , CRG.ACS_PF_ACCOUNT_ID
           , CRG.ACS_PJ_ACCOUNT_ID
           , 0 CRG_EXCLUSIVE
           , POS.ACS_FINANCIAL_ACCOUNT_ID POS_ACS_FINANCIAL_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID POS_ACS_DIVISION_ACCOUNT_ID
           , POS.ACS_CPN_ACCOUNT_ID POS_ACS_CPN_ACCOUNT_ID
           , POS.ACS_CDA_ACCOUNT_ID POS_ACS_CDA_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID POS_ACS_PF_ACCOUNT_ID
           , POS.ACS_PJ_ACCOUNT_ID POS_ACS_PJ_ACCOUNT_ID
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , PTC_CHARGE CRG
           , PTC_CHARGE_DESCRIPTION CHD
       where POS.DOC_POSITION_ID = cPositionId
         and CRG.CRG_NAME = cChargeName
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and CHD.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
         and CHD.PC_LANG_ID(+) = DMT.PC_LANG_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

    tplOperationCharge crOperationCharge%rowtype;
  begin
    aChargeAmount  := 0;
    aCreated       := 0;

    select max(nvl(DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID, (select max(FAL_SCHEDULE_STEP_ID)
                                                                from FAL_TASK_LINK
                                                               where FAL_LOT_ID = DOC_POSITION.FAL_LOT_ID) ) )
         , sum(PDE_FINAL_QUANTITY)
         , max(nvl(DOC_POSITION.FAL_LOT_ID, (select max(FAL_LOT_ID)
                                               from FAL_TASK_LINK
                                              where FAL_SCHEDULE_STEP_ID = DOC_POSITION.FAL_SCHEDULE_STEP_ID) ) )
      into vFalScheduleStepId
         , vPosQuantity
         , vFalLotId
      from DOC_POSITION_DETAIL
         , DOC_POSITION
     where DOC_POSITION_DETAIL.DOC_POSITION_ID = DOC_POSITION.DOC_POSITION_ID
       and DOC_POSITION.DOC_POSITION_ID = aPositionId;

    -- Récupération des informations de l'opérations
    select nvl(max(SCS_QTY_REF_AMOUNT), 0)
         , nvl(max(SCS_AMOUNT), 0) SCS_AMOUNT
      into lnQtyRef
         , lnScsAmount
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = vFalScheduleStepId;

    -- si la config gére la ventilation du prix des opération
    if     PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_OP_CHARGE') is not null
       and (    (PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_INIT_PRICE') = '2')
            or (    PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_INIT_PRICE') in('0', '1')
                and lnQtyRef = 0)
           )
       and vFalLotId is not null then
      -- Recherche s'il existe déjà une ancienne taxe
      select count(*)
        into vNbOpCharge
        from DOC_POSITION_CHARGE
       where DOC_POSITION_ID = aPositionId
         and C_CHARGE_ORIGIN = 'OP';

      -- si on a un lien sur une opération au niveau d'un détail de position
      if     (   vNbOpCharge = 0
              or aForceRedo = 1)
         and vFalScheduleStepId is not null then
        if lnQtyRef = 0 then
          -- Montant fixe
          vScsAmount  := lnScsAmount;
        else
          vScsAmount  := nvl(FAL_I_LIB_SUBCONTRACTO.GetOperationPrice(vFalScheduleStepId, vPosQuantity), 0);
        end if;

        if aForceRedo = 1 then
          -- suppression des anciennes taxes
          delete from DOC_POSITION_CHARGE
                where DOC_POSITION_ID = aPositionId
                  and C_CHARGE_ORIGIN = 'OP';
        end if;

        -- on ne crée pas la taxe si le montant est à 0
        if vScsAmount <> 0 then
          open crOperationCharge(aPositionId, PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_OP_CHARGE') );

          fetch crOperationCharge
           into tplOperationCharge;

          if crOperationCharge%found then
            vRecPositionCharge.PCH_FIXED_AMOUNT_B         := vScsAmount;

            -- calcul du montant fixe en monnaie document
            select ACS_FUNCTION.ConvertAmountForView(vScsAmount
                                                   , ACS_FUNCTION.GetLocalCurrencyId
                                                   , tplOperationCharge.ACS_FINANCIAL_CURRENCY_ID
                                                   , tplOperationCharge.DMT_DATE_DOCUMENT
                                                   , tplOperationCharge.DMT_BASE_PRICE
                                                   , tplOperationCharge.DMT_RATE_OF_EXCHANGE
                                                   , 0
                                                   , 5   -- cours logistique
                                                    )
              into vRecPositionCharge.PCH_AMOUNT
              from dual;

            -- Si gestion des comptes financiers ou analytiques
            if    (tplOperationCharge.GAS_FINANCIAL = 1)
               or (tplOperationCharge.GAS_ANALYTICAL = 1) then
              -- Utilise les comptes de la taxe
              vRecPositionCharge.ACS_FINANCIAL_ACCOUNT_ID  := tplOperationCharge.ACS_FINANCIAL_ACCOUNT_ID;
              vRecPositionCharge.ACS_DIVISION_ACCOUNT_ID   := tplOperationCharge.ACS_DIVISION_ACCOUNT_ID;
              vRecPositionCharge.ACS_CPN_ACCOUNT_ID        := tplOperationCharge.ACS_CPN_ACCOUNT_ID;
              vRecPositionCharge.ACS_CDA_ACCOUNT_ID        := tplOperationCharge.ACS_CDA_ACCOUNT_ID;
              vRecPositionCharge.ACS_PF_ACCOUNT_ID         := tplOperationCharge.ACS_PF_ACCOUNT_ID;
              vRecPositionCharge.ACS_PJ_ACCOUNT_ID         := tplOperationCharge.ACS_PJ_ACCOUNT_ID;
              vAccountInfo.DEF_HRM_PERSON                  := null;
              vAccountInfo.FAM_FIXED_ASSETS_ID             := null;
              vAccountInfo.C_FAM_TRANSACTION_TYP           := null;
              vAccountInfo.DEF_DIC_IMP_FREE1               := null;
              vAccountInfo.DEF_DIC_IMP_FREE2               := null;
              vAccountInfo.DEF_DIC_IMP_FREE3               := null;
              vAccountInfo.DEF_DIC_IMP_FREE4               := null;
              vAccountInfo.DEF_DIC_IMP_FREE5               := null;
              vAccountInfo.DEF_TEXT1                       := null;
              vAccountInfo.DEF_TEXT2                       := null;
              vAccountInfo.DEF_TEXT3                       := null;
              vAccountInfo.DEF_TEXT4                       := null;
              vAccountInfo.DEF_TEXT5                       := null;
              vAccountInfo.DEF_NUMBER1                     := null;
              vAccountInfo.DEF_NUMBER2                     := null;
              vAccountInfo.DEF_NUMBER3                     := null;
              vAccountInfo.DEF_NUMBER4                     := null;
              vAccountInfo.DEF_NUMBER5                     := null;
              vAccountInfo.DEF_DATE1                       := null;
              vAccountInfo.DEF_DATE2                       := null;
              vAccountInfo.DEF_DATE3                       := null;
              vAccountInfo.DEF_DATE4                       := null;
              vAccountInfo.DEF_DATE5                       := null;
              -- recherche des comptes
              ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplOperationCharge.PTC_CHARGE_ID
                                                       , '30'
                                                       , tplOperationCharge.C_ADMIN_DOMAIN
                                                       , tplOperationCharge.DMT_DATE_DOCUMENT
                                                       , tplOperationCharge.DOC_GAUGE_ID
                                                       , tplOperationCharge.DOC_DOCUMENT_ID
                                                       , aPositionId
                                                       , tplOperationCharge.DOC_RECORD_ID
                                                       , tplOperationCharge.PAC_THIRD_ACI_ID
                                                       , tplOperationCharge.POS_ACS_FINANCIAL_ACCOUNT_ID
                                                       , tplOperationCharge.POS_ACS_DIVISION_ACCOUNT_ID
                                                       , tplOperationCharge.POS_ACS_CPN_ACCOUNT_ID
                                                       , tplOperationCharge.POS_ACS_CDA_ACCOUNT_ID
                                                       , tplOperationCharge.POS_ACS_PF_ACCOUNT_ID
                                                       , tplOperationCharge.POS_ACS_PJ_ACCOUNT_ID
                                                       , vRecPositionCharge.ACS_FINANCIAL_ACCOUNT_ID
                                                       , vRecPositionCharge.ACS_DIVISION_ACCOUNT_ID
                                                       , vRecPositionCharge.ACS_CPN_ACCOUNT_ID
                                                       , vRecPositionCharge.ACS_CDA_ACCOUNT_ID
                                                       , vRecPositionCharge.ACS_PF_ACCOUNT_ID
                                                       , vRecPositionCharge.ACS_PJ_ACCOUNT_ID
                                                       , vAccountInfo
                                                        );

              if (tplOperationCharge.GAS_ANALYTICAL = 0) then
                vRecPositionCharge.ACS_CPN_ACCOUNT_ID  := null;
                vRecPositionCharge.ACS_CDA_ACCOUNT_ID  := null;
                vRecPositionCharge.ACS_PJ_ACCOUNT_ID   := null;
                vRecPositionCharge.ACS_PF_ACCOUNT_ID   := null;
              end if;
            end if;   -- initialisation des comptes

            -- calcul du montant fixe en monnaie de base
            select ACS_FUNCTION.ConvertAmountForView(vRecPositionCharge.PCH_AMOUNT
                                                   , tplOperationCharge.ACS_FINANCIAL_CURRENCY_ID
                                                   , ACS_FUNCTION.GetLocalCurrencyId
                                                   , tplOperationCharge.DMT_DATE_DOCUMENT
                                                   , tplOperationCharge.DMT_RATE_OF_EXCHANGE
                                                   , tplOperationCharge.DMT_BASE_PRICE
                                                   , 0
                                                    )
              into vRecPositionCharge.PCH_FIXED_AMOUNT_B
              from dual;

            vRecPositionCharge.DOC_POSITION_ID            := aPositionId;
            vRecPositionCharge.C_CHARGE_ORIGIN            := 'OP';
            vRecPositionCharge.C_FINANCIAL_CHARGE         := '03';
            vRecPositionCharge.PCH_NAME                   := tplOperationCharge.CRG_NAME;
            vRecPositionCharge.PCH_DESCRIPTION            := tplOperationCharge.CHD_DESCR;
            vRecPositionCharge.C_CALCULATION_MODE         := '0';
            vRecPositionCharge.PCH_IN_SERIES_CALCULATION  := tplOperationCharge.CRG_IN_SERIE_CALCULATION;
            vRecPositionCharge.PCH_MODIFY                 := tplOperationCharge.CRG_MODIFY;
            vRecPositionCharge.PCH_PRCS_USE               := tplOperationCharge.PRCS_USE;
            vRecPositionCharge.PCH_EXCLUSIVE              := tplOperationCharge.CRG_EXCLUSIVE;
            vRecPositionCharge.PTC_CHARGE_ID              := tplOperationCharge.PTC_CHARGE_ID;
            vRecPositionCharge.HRM_PERSON_ID              := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON);
            vRecPositionCharge.FAM_FIXED_ASSETS_ID        := vAccountInfo.FAM_FIXED_ASSETS_ID;
            vRecPositionCharge.C_FAM_TRANSACTION_TYP      := vAccountInfo.C_FAM_TRANSACTION_TYP;
            vRecPositionCharge.PCH_IMP_TEXT_1             := vAccountInfo.DEF_TEXT1;
            vRecPositionCharge.PCH_IMP_TEXT_2             := vAccountInfo.DEF_TEXT2;
            vRecPositionCharge.PCH_IMP_TEXT_3             := vAccountInfo.DEF_TEXT3;
            vRecPositionCharge.PCH_IMP_TEXT_4             := vAccountInfo.DEF_TEXT4;
            vRecPositionCharge.PCH_IMP_TEXT_5             := vAccountInfo.DEF_TEXT5;
            vRecPositionCharge.PCH_IMP_NUMBER_1           := to_number(vAccountInfo.DEF_NUMBER1);
            vRecPositionCharge.PCH_IMP_NUMBER_2           := to_number(vAccountInfo.DEF_NUMBER2);
            vRecPositionCharge.PCH_IMP_NUMBER_3           := to_number(vAccountInfo.DEF_NUMBER3);
            vRecPositionCharge.PCH_IMP_NUMBER_4           := to_number(vAccountInfo.DEF_NUMBER4);
            vRecPositionCharge.PCH_IMP_NUMBER_5           := to_number(vAccountInfo.DEF_NUMBER5);
            vRecPositionCharge.DIC_IMP_FREE1_ID           := vAccountInfo.DEF_DIC_IMP_FREE1;
            vRecPositionCharge.DIC_IMP_FREE2_ID           := vAccountInfo.DEF_DIC_IMP_FREE2;
            vRecPositionCharge.DIC_IMP_FREE3_ID           := vAccountInfo.DEF_DIC_IMP_FREE3;
            vRecPositionCharge.DIC_IMP_FREE4_ID           := vAccountInfo.DEF_DIC_IMP_FREE4;
            vRecPositionCharge.DIC_IMP_FREE5_ID           := vAccountInfo.DEF_DIC_IMP_FREE5;
            vRecPositionCharge.PCH_IMP_DATE_1             := vAccountInfo.DEF_DATE1;
            vRecPositionCharge.PCH_IMP_DATE_2             := vAccountInfo.DEF_DATE2;
            vRecPositionCharge.PCH_IMP_DATE_3             := vAccountInfo.DEF_DATE3;
            vRecPositionCharge.PCH_IMP_DATE_4             := vAccountInfo.DEF_DATE4;
            vRecPositionCharge.PCH_IMP_DATE_5             := vAccountInfo.DEF_DATE5;
            DOC_DISCOUNT_CHARGE.InsertPositionCharge(vRecPositionCharge);
            -- Récuperer le montant de la taxe
            aChargeAmount                                 := nvl(vRecPositionCharge.PCH_AMOUNT, 0);
            aCreated                                      := 1;
          else
            raise_application_error
              (-20000
             , replace
                 (PCS.PC_FUNCTIONS.TranslateWord
                          ('PCS - La taxe générique "[TAXNAME]" définie pour les opérations de sous-traitance n''existe pas (config DOC_SUBCONTRACT_OP_CHARGE).')
                , '[TAXNAME]'
                , PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_OP_CHARGE')
                 )
              );
          end if;

          close crOperationCharge;
        end if;
      end if;
    end if;
  end CreateOperationPositionCharge;

-----------------------------------------------------------------------------------------------------------------------------
/**
* Description
*          procedure de recalcul des montants de remise/taxe pour une position
*/
  procedure CalculatePositionCharge(
    position_id                   in     doc_position.doc_position_id%type
  , dateref                       in     date
  , currency_id                   in     acs_financial_currency.acs_financial_currency_id%type
  , rate_of_exchange              in     doc_document.dmt_rate_of_exchange%type
  , base_price                    in     doc_document.dmt_base_price%type
  , aChargeAmount                 out    doc_position.pos_charge_amount%type
  , aDiscountAmount               out    doc_position.pos_discount_amount%type
  , aApplicateQuantityConstraints in     number default 1
  , aApplicateAmountConstraints   in     number default 1
  )
  is
    pchAmount          DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    pchBalanceParent   DOC_POSITION_CHARGE.PCH_BALANCE_AMOUNT%type;
    liabledAmount      DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    cascadeAmount      DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    unitLiabledAmount  DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    position_tuple     doc_position%rowtype;
    blnFound           number(1);
    lnCreated          numBoolean;

    cursor crPositionCharges(position_id number)
    is
      select   DOC_POSITION_CHARGE_ID
             , C_CHARGE_ORIGIN
             , nvl(PTC_DISCOUNT_ID, 0) PTC_DISCOUNT_ID
             , nvl(PTC_CHARGE_ID, 0) PTC_CHARGE_ID
             , nvl(PCH_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 0 ORIGINAL
             , PCH_DESCRIPTION DESCR
             , PCH_NAME PTC_NAME
             , C_CALCULATION_MODE
             , PCH_RATE RATE
             , PCH_EXPRESS_IN FRACTION
             , PCH_FIXED_AMOUNT_B FIXED_AMOUNT_B
             , PCH_FIXED_AMOUNT FIXED_AMOUNT
             , PCH_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , PCH_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , PCH_MIN_AMOUNT MIN_AMOUNT
             , PCH_MAX_AMOUNT MAX_AMOUNT
             , PCH_QUANTITY_FROM QUANTITY_FROM
             , PCH_QUANTITY_TO QUANTITY_TO
             , PCH_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , PCH_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , PCH_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , PCH_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(PCH_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , PCH_TRANSFERT_PROP TRANSFERT_PROP
             , PCH_MODIFY MODIF
             , PCH_UNIT_DETAIL UNIT_DETAIL
             , PCH_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , PCH_CUMULATIVE CUMULATIVE
             , PCH_AMOUNT
             , PCH_TRANSFERT_PROP
             , DOC_DOC_POSITION_CHARGE_ID
          from DOC_POSITION_CHARGE
         where DOC_POSITION_ID = position_id
      order by SERIES_CALC
             , descr;

    vGestValueQuantity DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    vQuantity          DOC_POSITION.POS_FINAL_QUANTITY%type;
    lnOpChargeAmount   doc_position.pos_charge_amount%type;
  begin
    aChargeAmount    := 0;
    aDiscountAmount  := 0;

    -- pointeur sur la position a traîter
    select *
      into position_tuple
      from doc_position
     where doc_position_id = position_id;

    -- Re-création des taxes liées aux opérations de fabrication
    -- création des taxes liées aux opérations de fabrication
    -- Remarque : le montant taxe en sortie (lnOpChargeAmount) ne doit pas être utilisé
    --            car le curseur ci-dessus ne fait pas de filtre sur ce genre de taxe (Opération)
    CreateOperationPositionCharge(aPositionId => position_id, aCreated => lnCreated, aChargeAmount => lnOpChargeAmount);

    -- recherche du montant soumis en fonction du type de position (HT ou TTC)
    select decode(GAP_INCLUDE_TAX_TARIFF, 0, position_tuple.POS_GROSS_VALUE, 1, position_tuple.POS_GROSS_VALUE_INCL)
         , decode(GAP_INCLUDE_TAX_TARIFF, 0, position_tuple.POS_GROSS_VALUE, 1, position_tuple.POS_GROSS_VALUE_INCL)
         , decode(GAP_INCLUDE_TAX_TARIFF, 0, position_tuple.POS_GROSS_UNIT_VALUE, 1, position_tuple.POS_GROSS_UNIT_VALUE_INCL)
         , nvl(GAP_VALUE_QUANTITY, 0)
      into LiabledAmount
         , CascadeAmount
         , unitLiabledAmount
         , vGestValueQuantity
      from DOC_GAUGE_POSITION
     where DOC_GAUGE_POSITION_ID = position_tuple.DOC_GAUGE_POSITION_ID;

    -- Remises/taxes non cascade
    for tplPositionCharges in crPositionCharges(position_id) loop
      if tplPositionCharges.SERIES_CALC = 1 then
        LiabledAmount  := CascadeAmount;

        ----
        -- Recalcul le montant soumis unitaire lorsque la charge est en cascade.
        -- En effet, dans ce cas la, il ne faut pas prendre le montant unitaire
        -- de la position.
        --
        if (vGestValueQuantity = 1) then
          if (position_tuple.POS_VALUE_QUANTITY <> 0) then
            unitLiabledAmount  := CascadeAmount / position_tuple.POS_VALUE_QUANTITY;
          else
            unitLiabledAmount  := CascadeAmount;
          end if;
        else
          if (position_tuple.POS_FINAL_QUANTITY <> 0) then
            unitLiabledAmount  := CascadeAmount / position_tuple.POS_FINAL_QUANTITY;
          else
            unitLiabledAmount  := CascadeAmount;
          end if;
        end if;
      end if;

      -- Recherche de la quantité à prendre en compte.
      if (vGestValueQuantity = 1) then
        vQuantity  := position_tuple.POS_VALUE_QUANTITY;
      else
        vQuantity  := position_tuple.POS_FINAL_QUANTITY;
      end if;

      -- On ne fait aucun recalcul pour les remises/taxes issues des opérations de fabrication et les marges matières
      -- précieuses
      if (',' || tplPositionCharges.C_CHARGE_ORIGIN || ',') in(',OP,', ',PMM,') then
        pchAmount  := tplPositionCharges.PCH_AMOUNT;
      ----
      -- Mise à jour, éventuelle, du montant solde de la charge parent. La mise à jour doit s'effectuer uniquement
      -- si la charge courante est liées à une charge père.
      -- on fait une double condition avec le transfert proportionnel afin de pouvoir lancer un vrai recalcul en décochant cette case de transfert proportionnel
      elsif     tplPositionCharges.DOC_DOC_POSITION_CHARGE_ID is not null
            and tplPositionCharges.PCH_TRANSFERT_PROP = 1 then
        select decode(vQuantity, 0, 0, decode(POS.POS_BASIS_QUANTITY, 0, 0, vQuantity *(PCH.PCH_AMOUNT / POS.POS_BASIS_QUANTITY) ) )
             , decode(POS.POS_UPDATE_QTY_PRICE
                    -- règle de 3
               ,      1, decode(POS.POS_BASIS_QUANTITY, 0, 0, PCH_AMOUNT *(POS.POS_BALANCE_QUANTITY / POS.POS_BASIS_QUANTITY) )
                    -- calcul par soustraction
               ,      decode(POS.POS_BALANCE_QUANTITY
                           , POS.POS_FINAL_QUANTITY, PCH_AMOUNT
                           , PCH_BALANCE_AMOUNT +
                             tplPositionCharges.PCH_AMOUNT -
                             decode(vQuantity, 0, 0, decode(POS.POS_BASIS_QUANTITY, 0, 0, vQuantity *(PCH.PCH_AMOUNT / POS.POS_BASIS_QUANTITY) ) )
                            )
                     )
          into pchAmount
             , pchBalanceParent
          from DOC_POSITION_CHARGE PCH
             , DOC_POSITION POS
         where PCH.DOC_POSITION_CHARGE_ID = tplPositionCharges.DOC_DOC_POSITION_CHARGE_ID
           and POS.DOC_POSITION_ID = PCH.DOC_POSITION_ID;

        -- Ajout de l'ancien montant de la charge et retrait du nouveau montant au montant solde de la charge.
        update DOC_POSITION_CHARGE
           set PCH_BALANCE_AMOUNT = pchBalanceParent
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_CHARGE_ID = tplPositionCharges.DOC_DOC_POSITION_CHARGE_ID;

        update DOC_POSITION_CHARGE
           set PCH_AMOUNT =
                     (select decode(GAS_BALANCE_STATUS, 0, pchamount, pchAmount * decode(POS_FINAL_QUANTITY, 0, 0, POS_BALANCE_QUANTITY / POS_FINAL_QUANTITY) )
                        from DOC_POSITION POS
                           , DOC_GAUGE_STRUCTURED GAS
                       where POS.DOC_POSITION_ID = DOC_POSITION_CHARGE.DOC_POSITION_ID
                         and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID)
             , PCH_FIXED_AMOUNT = decode(C_CALCULATION_MODE, '0', pchAmount, '1', pchAmount, '6', pchAmount, 0)
             , PCH_BALANCE_AMOUNT = (select decode(GAS.GAS_BALANCE_STATUS, 0, 0, pchAmount)
                                       from DOC_POSITION POS
                                          , DOC_GAUGE_STRUCTURED GAS
                                      where POS.DOC_POSITION_ID = DOC_POSITION_CHARGE.DOC_POSITION_ID
                                        and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID)
             , PCH_CALC_AMOUNT = pchAmount
             , PCH_LIABLED_AMOUNT = LiabledAmount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_CHARGE_ID = tplPositionCharges.DOC_POSITION_CHARGE_ID;
      else
        -- traitement des taxes
        if tplPositionCharges.PTC_CHARGE_ID <> 0 then
          PTC_FUNCTIONS.CalcCharge(tplPositionCharges.PTC_CHARGE_ID   -- Id de la taxe à calculer
                                 , tplPositionCharges.descr   -- Nom de la taxe
                                 , unitLiabledAmount   -- Montant unitaire soumis à la taxe en monnaie document
                                 , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                 , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                 , vQuantity   -- Pour les taxes de type détail, quantité de la position
                                 , position_tuple.GCO_GOOD_ID   -- Identifiant du bien
                                 , nvl(position_tuple.PAC_THIRD_TARIFF_ID, position_tuple.PAC_THIRD_ID)   -- Identifiant du tiers tarification
                                 , position_tuple.DOC_POSITION_ID   -- Identifiant de la position pour les taxes détaillées de type 8 (plsql)
                                 , null   -- Identifiant du document pour les taxes de type total de type 8 (plsql)
                                 , currency_id   -- Id de la monnaie du montant soumis
                                 , rate_of_exchange   -- Taux de change
                                 , base_price   -- Diviseur
                                 , dateref   -- Date de référence
                                 , tplPositionCharges.C_CALCULATION_MODE   -- Mode de calcul
                                 , tplPositionCharges.rate   -- Taux
                                 , tplPositionCharges.fraction   -- Fraction
                                 , tplPositionCharges.fixed_amount_b   -- Montant fixe en monnaie de base
                                 , tplPositionCharges.fixed_amount   -- Montant fixe en monnaie document
                                 , tplPositionCharges.quantity_from   -- Quantité de
                                 , tplPositionCharges.quantity_to   -- Quantité a
                                 , tplPositionCharges.min_amount   -- Montant minimum de remise/taxe
                                 , tplPositionCharges.max_amount   -- Montant maximum de remise/taxe
                                 , tplPositionCharges.exceeded_amount_from   -- Montant de dépassement de
                                 , tplPositionCharges.exceeded_amount_to   -- Montant de dépassement à
                                 , tplPositionCharges.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                 , tplPositionCharges.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                 , tplPositionCharges.automatic_calc   -- Calculation auto ou à partir de sql_Extern_item
                                 , tplPositionCharges.sql_extern_item   -- Commande sql de recherche du montant soumis à la calculation
                                 , tplPositionCharges.c_round_type   -- Type d'arrondi
                                 , tplPositionCharges.round_amount   -- Montant d'arrondi
                                 , tplPositionCharges.unit_detail   -- Détail unitaire
                                 , tplPositionCharges.original   -- Origine de la taxe (1 = création, 0 = modification)
                                 , tplPositionCharges.cumulative   -- Origine de la taxe (1 = création, 0 = modification)
                                 , pchAmount   -- Montant de la taxe
                                 , blnFound   -- Taxe trouvée
                                 , aApplicateQuantityConstraints   -- Teste l'applicabilité dans les plages de quantité
                                 , aApplicateAmountConstraints   -- Teste l'applicabilité dans les plages de montants
                                  );
        -- traitement des remises
        else
          PTC_FUNCTIONS.CalcDiscount(tplPositionCharges.PTC_DISCOUNT_ID   -- Id de la remise à calculer
                                   , unitLiabledAmount   -- Montant unitaire soumis à la remise en monnaie document
                                   , liabledAmount   -- Montant soumis à la remise en monnaie document
                                   , liabledAmount   -- Montant soumis à la remise en monnaie document
                                   , vQuantity   -- Pour les remises de type détail, quantité de la position
                                   , position_tuple.DOC_POSITION_ID   -- Identifiant de la position pour les remises détaillées de type 8 (plsql)
                                   , null   -- Identifiant du document pour les remises de type total de type 8 (plsql)
                                   , currency_id   -- Id de la monnaie du montant soumis
                                   , rate_of_exchange   -- Taux de change
                                   , base_price   -- Diviseur
                                   , dateref   -- Date de référence
                                   , tplPositionCharges.C_CALCULATION_MODE   -- Mode de calcul
                                   , tplPositionCharges.rate   -- Taux
                                   , tplPositionCharges.fraction   -- Fraction
                                   , tplPositionCharges.fixed_amount_b   -- Montant fixe en monnaie de base
                                   , tplPositionCharges.fixed_amount   -- Montant fixe en monnaie document
                                   , tplPositionCharges.quantity_from   -- Quantité de
                                   , tplPositionCharges.quantity_to   -- Quantité a
                                   , tplPositionCharges.min_amount   -- Montant minimum de remise/taxe
                                   , tplPositionCharges.max_amount   -- Montant maximum de remise/taxe
                                   , tplPositionCharges.exceeded_amount_from   -- Montant de dépassement de
                                   , tplPositionCharges.exceeded_amount_to   -- Montant de dépassement à
                                   , tplPositionCharges.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                   , tplPositionCharges.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                   , tplPositionCharges.c_round_type   -- Type d'arrondi
                                   , tplPositionCharges.round_amount   -- Montant d'arrondi
                                   , tplPositionCharges.unit_detail   -- Détail unitaire
                                   , tplPositionCharges.original   -- Origine de la remise (1 = création, 0 = modification)
                                   , tplPositionCharges.cumulative   -- Origine de la remise (1 = création, 0 = modification)
                                   , pchAmount   -- Montant de la remise
                                   , blnFound   -- Remise trouvée
                                   , aApplicateQuantityConstraints   -- Teste l'applicabilité dans les plages de quantité
                                   , aApplicateAmountConstraints   -- Teste l'applicabilité dans les plages de montants
                                    );
        end if;

        -- traitement spécial des type 8 en recalcul
        if pchAmount is null then
          pchAmount  := 0;
        end if;

        update DOC_POSITION_CHARGE
           set PCH_AMOUNT = pchAmount
             , PCH_BALANCE_AMOUNT =
                         (select decode(GAS.GAS_BALANCE_STATUS, 0, 0, pchAmount * decode(POS_FINAL_QUANTITY, 0, 0, POS_BALANCE_QUANTITY / POS_FINAL_QUANTITY) )
                            from DOC_POSITION POS
                               , DOC_GAUGE_STRUCTURED GAS
                           where POS.DOC_POSITION_ID = DOC_POSITION_CHARGE.DOC_POSITION_ID
                             and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID)
             , PCH_CALC_AMOUNT = pchAmount
             , PCH_LIABLED_AMOUNT = LiabledAmount
             , PCH_RATE = tplPositionCharges.rate
             , PCH_EXPRESS_IN = tplPositionCharges.fraction
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_CHARGE_ID = tplPositionCharges.DOC_POSITION_CHARGE_ID;
      end if;

      select aChargeAmount + decode(tplPositionCharges.PTC_CHARGE_ID, 0, 0, pchAmount)
        into aChargeAmount
        from dual;

      select aDiscountAmount + decode(tplPositionCharges.PTC_DISCOUNT_ID, 0, 0, pchAmount)
        into aDiscountAmount
        from dual;

      select CascadeAmount + decode(tplPositionCharges.PTC_CHARGE_ID, 0, -pchAmount, pchAmount)
        into CascadeAmount
        from dual;
    end loop;

    update DOC_POSITION
       set POS_UPDATE_POSITION_CHARGE = 0
     where DOC_POSITION_ID = position_Id;
  end CalculatePositionCharge;

  /**
  * Description
  *    Cette procedure fait appel soir à CreatePositionCharge soit à CalculatePositionCharge en fonction
  *    du flag POS_CREATE_POSITION_CHARGE
  */
  procedure AutomaticPositionCharge(
    aPositionId     in     doc_position.doc_position_id%type
  , aDateref        in     date
  , aCurrencyId     in     acs_financial_currency.acs_financial_currency_id%type
  , aRateOfExchange in     doc_document.dmt_rate_of_exchange%type
  , aBasePrice      in     doc_document.dmt_base_price%type
  , aLangId         in     doc_document.pc_lang_id%type
  , aCreatedUpdated out    numBoolean
  , aChargeAmount   out    doc_position.pos_charge_amount%type
  , aDiscountAmount out    doc_position.pos_discount_amount%type
  )
  is
    mustCreatePositionCharge DOC_POSITION.POS_CREATE_POSITION_CHARGE%type;
    mustUpdatePositionCharge DOC_POSITION.POS_UPDATE_POSITION_CHARGE%type;
    gaugeTypePos             DOC_POSITION.C_GAUGE_TYPE_POS%type;
    createCharge             number(1)                                      default 0;
  begin
    -- recherche des flags de gestion des remises/taxes de position
    select POS_CREATE_POSITION_CHARGE
         , POS_UPDATE_POSITION_CHARGE
         , C_GAUGE_TYPE_POS
         , nvl(POS_CHARGE_AMOUNT, 0)
         , nvl(POS_DISCOUNT_AMOUNT, 0)
      into mustCreatePositionCharge
         , mustUpdatePositionCharge
         , gaugeTypePos
         , aChargeAmount
         , aDiscountAmount
      from DOC_POSITION
     where DOC_POSITION_ID = aPositionId;

    -- appel de la bonne fonction suivant les flags
    if mustCreatePositionCharge = 1 then
      CreatePositionCharge(aPositionId, aDateref, aCurrencyId, aRateOfExchange, aBasePrice, aLangId, aCreatedUpdated, aChargeAmount, aDiscountAmount);
    --elsif mustUpdatePositionCharge = 1 and gaugeTypePos in ('1','2','3','7','8','10','91')  then
    elsif mustUpdatePositionCharge = 1 then
      CalculatePositionCharge(aPositionId
                            , aDateref
                            , aCurrencyId
                            , aRateOfExchange
                            , aBasePrice
                            , aChargeAmount
                            , aDiscountAmount
                            , PCS.PC_CONFIG.GetConfig('PTC_DC_DET_TEST_QTY_RECALC')
                            , PCS.PC_CONFIG.GetConfig('PTC_DC_DET_TEST_AMOUNT_RECALC')
                             );
      aCreatedUpdated  := 1;
    end if;
  end AutomaticPositionCharge;

  /**
  * Description
  *         procedure de copie des remises/taxes d'une position parent
  */
  procedure CopyPositionCharge(
    position_id      in     doc_position.doc_position_id%type
  , parent_id        in     doc_position.doc_position_id%type
  , dateref          in     date
  , currency_id      in     acs_financial_currency.acs_financial_currency_id%type
  , rate_of_exchange in     doc_document.dmt_rate_of_exchange%type
  , base_price       in     doc_document.dmt_base_price%type
  , aBalance         in     numBoolean
  , aOperationCharge in     numBoolean
  , created          out    numBoolean
  , aChargeAmount    out    doc_position.pos_charge_amount%type
  , aDiscountAmount  out    doc_position.pos_discount_amount%type
  , aConvertAmount   in     number default 0
  )
  is
    cursor crParentCharges(aPositionId number, aOperationCharge numBoolean)
    is
      select   pch.DOC_POSITION_CHARGE_ID
             , nvl(pch.PTC_DISCOUNT_ID, 0) PTC_DISCOUNT_ID
             , nvl(pch.PTC_CHARGE_ID, 0) PTC_CHARGE_ID
             , nvl(pch.PCH_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , aConvertAmount ORIGINAL
             , C_CHARGE_ORIGIN
             , decode(PCH.PTC_DISCOUNT_ID, null, CRG.C_CHARGE_KIND, DNT.C_DISCOUNT_KIND) C_CHARGE_KIND
             , pch.PCH_DESCRIPTION DESCR
             , pch.PCH_NAME PTC_NAME
             , pch.PCH_AMOUNT
             , pch.PCH_BALANCE_AMOUNT
             , pch.PCH_LIABLED_AMOUNT
             , pch.C_CALCULATION_MODE
             , pch.PCH_RATE RATE
             , pch.PCH_EXPRESS_IN FRACTION
             , PCH_FIXED_AMOUNT_B FIXED_AMOUNT_B
             , decode(nvl(aConvertAmount, 0), 1, pch.PCH_FIXED_AMOUNT_B, pch.PCH_FIXED_AMOUNT) FIXED_AMOUNT
             , pch.PCH_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , pch.PCH_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , pch.PCH_MIN_AMOUNT MIN_AMOUNT
             , pch.PCH_MAX_AMOUNT MAX_AMOUNT
             , pch.PCH_QUANTITY_FROM QUANTITY_FROM
             , pch.PCH_QUANTITY_TO QUANTITY_TO
             , pch.PCH_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , pch.PCH_STORED_PROC STORED_PROC
             , pch.C_ROUND_TYPE
             , pch.PCH_ROUND_AMOUNT ROUND_AMOUNT
             , pch.PCH_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(pch.PCH_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , pch.PCH_TRANSFERT_PROP TRANSFERT_PROP
             , pch.PCH_MODIFY MODIF
             , pch.PCH_PRCS_USE PRCS_USE
             , pch.PCH_UNIT_DETAIL UNIT_DETAIL
             , pch.PCH_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , pch.PCH_CUMULATIVE CUMULATIVE
             ,
               /**
               * Règle :
               *
               *   Si les comptes sont géré ou visible sur le parent.
               *     On reprend les comptes du parent mais si les comptes sont null, on
               *     reprend de la remise ou de la taxe.
               *   Sinon
               *     On reprend les comptes de la remise ou de la taxe.
               */
               decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0)
                    ,   -- Compte visible ou gestion de l'imputation financière ?
                      0, decode(PCH.PTC_DISCOUNT_ID, null, CRG.ACS_FINANCIAL_ACCOUNT_ID, DNT.ACS_FINANCIAL_ACCOUNT_ID)
                    , decode(PCH.PTC_DISCOUNT_ID
                           , null, nvl(PCH.ACS_FINANCIAL_ACCOUNT_ID, CRG.ACS_FINANCIAL_ACCOUNT_ID)
                           , nvl(PCH.ACS_FINANCIAL_ACCOUNT_ID, DNT.ACS_FINANCIAL_ACCOUNT_ID)
                            )
                     ) ACS_FINANCIAL_ACCOUNT_ID
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0)
                    ,   -- Compte visible ou gestion de l'imputation financière ?
                      0, decode(PCH.PTC_DISCOUNT_ID, null, CRG.ACS_DIVISION_ACCOUNT_ID, DNT.ACS_DIVISION_ACCOUNT_ID)
                    , decode(PCH.PTC_DISCOUNT_ID
                           , null, nvl(PCH.ACS_DIVISION_ACCOUNT_ID, CRG.ACS_DIVISION_ACCOUNT_ID)
                           , nvl(PCH.ACS_DIVISION_ACCOUNT_ID, DNT.ACS_DIVISION_ACCOUNT_ID)
                            )
                     ) ACS_DIVISION_ACCOUNT_ID
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0)
                    ,   -- Compte visible ou gestion de l'imputation analytique ?
                      0, decode(PCH.PTC_DISCOUNT_ID, null, CRG.ACS_CPN_ACCOUNT_ID, DNT.ACS_CPN_ACCOUNT_ID)
                    , decode(PCH.PTC_DISCOUNT_ID
                           , null, nvl(PCH.ACS_CPN_ACCOUNT_ID, CRG.ACS_CPN_ACCOUNT_ID)
                           , nvl(PCH.ACS_CPN_ACCOUNT_ID, DNT.ACS_CPN_ACCOUNT_ID)
                            )
                     ) ACS_CPN_ACCOUNT_ID
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0)
                    ,   -- Compte visible ou gestion de l'imputation analytique ?
                      0, decode(PCH.PTC_DISCOUNT_ID, null, CRG.ACS_CDA_ACCOUNT_ID, DNT.ACS_CDA_ACCOUNT_ID)
                    , decode(PCH.PTC_DISCOUNT_ID
                           , null, nvl(PCH.ACS_CDA_ACCOUNT_ID, CRG.ACS_CDA_ACCOUNT_ID)
                           , nvl(PCH.ACS_CDA_ACCOUNT_ID, DNT.ACS_CDA_ACCOUNT_ID)
                            )
                     ) ACS_CDA_ACCOUNT_ID
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0)
                    ,   -- Compte visible ou gestion de l'imputation analytique ?
                      0, decode(PCH.PTC_DISCOUNT_ID, null, CRG.ACS_PF_ACCOUNT_ID, DNT.ACS_PF_ACCOUNT_ID)
                    , decode(PCH.PTC_DISCOUNT_ID, null, nvl(PCH.ACS_PF_ACCOUNT_ID, CRG.ACS_PF_ACCOUNT_ID), nvl(PCH.ACS_PF_ACCOUNT_ID, DNT.ACS_PF_ACCOUNT_ID) )
                     ) ACS_PF_ACCOUNT_ID
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0)
                    ,   -- Compte visible ou gestion de l'imputation analytique ?
                      0, decode(PCH.PTC_DISCOUNT_ID, null, CRG.ACS_PJ_ACCOUNT_ID, DNT.ACS_PJ_ACCOUNT_ID)
                    , decode(PCH.PTC_DISCOUNT_ID, null, nvl(PCH.ACS_PJ_ACCOUNT_ID, CRG.ACS_PJ_ACCOUNT_ID), nvl(PCH.ACS_PJ_ACCOUNT_ID, DNT.ACS_PJ_ACCOUNT_ID) )
                     ) ACS_PJ_ACCOUNT_ID
             , pch.HRM_PERSON_ID
             , pch.FAM_FIXED_ASSETS_ID
             , pch.C_FAM_TRANSACTION_TYP
             , pch.PCH_IMP_TEXT_1
             , pch.PCH_IMP_TEXT_2
             , pch.PCH_IMP_TEXT_3
             , pch.PCH_IMP_TEXT_4
             , pch.PCH_IMP_TEXT_5
             , pch.PCH_IMP_NUMBER_1
             , pch.PCH_IMP_NUMBER_2
             , pch.PCH_IMP_NUMBER_3
             , pch.PCH_IMP_NUMBER_4
             , pch.PCH_IMP_NUMBER_5
             , pch.DIC_IMP_FREE1_ID
             , pch.DIC_IMP_FREE2_ID
             , pch.DIC_IMP_FREE3_ID
             , pch.DIC_IMP_FREE4_ID
             , pch.DIC_IMP_FREE5_ID
             , pch.PCH_IMP_DATE_1
             , pch.PCH_IMP_DATE_2
             , pch.PCH_IMP_DATE_3
             , pch.PCH_IMP_DATE_4
             , pch.PCH_IMP_DATE_5
          from DOC_POSITION_CHARGE pch
             , DOC_POSITION POS
             , DOC_GAUGE_STRUCTURED GAS
             , ptc_discount dnt
             , ptc_charge crg
         where PCH.DOC_POSITION_ID = aPositionId
           and POS.DOC_POSITION_ID = PCH.DOC_POSITION_ID
           and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
           and nvl(PCH.C_CHARGE_ORIGIN, 'AUTO') not in('PM', 'PMM')   -- exclure les taxe matières précieuses
           and not(    aOperationCharge = 0
                   and nvl(PCH.C_CHARGE_ORIGIN, 'AUTO') = 'OP')   -- exclure les taxe opération sous-traitance si demandé
           and dnt.ptc_discount_id(+) = pch.ptc_discount_id
           and crg.ptc_charge_id(+) = pch.ptc_charge_id
      order by SERIES_CALC
             , PTC_NAME;

    tplParentCharges     crParentCharges%rowtype;
    tplParentPosition    doc_position%rowtype;
    tplPosition          doc_position%rowtype;
    pchAmount            DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    liabledAmount        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    cascadeAmount        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    unitLiabledAmount    DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    lChargeRoundAmount   DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    lDiscountRoundAmount DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    blnFound             number(1);
    FinancialID          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    DivisionID           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CpnID                ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CdaID                ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PfID                 ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PjID                 ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    admin_domain         DOC_GAUGE.C_ADMIN_DOMAIN%type;
    -- Flags sur les données gêrées
    HrmPerson            number(1);
    FamFixed             number(1);
    Text1                number(1);
    Text2                number(1);
    Text3                number(1);
    Text4                number(1);
    Text5                number(1);
    Number1              number(1);
    Number2              number(1);
    Number3              number(1);
    Number4              number(1);
    Number5              number(1);
    DicFree1             number(1);
    DicFree2             number(1);
    DicFree3             number(1);
    DicFree4             number(1);
    DicFree5             number(1);
    Date1                number(1);
    Date2                number(1);
    Date3                number(1);
    Date4                number(1);
    Date5                number(1);
    vIsMultiplicator     number(1);
    vGestValueQuantity   DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    vQuantity            DOC_POSITION.POS_FINAL_QUANTITY%type;
    vFinancial           DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical          DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vBalance             DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type;
    vInfoCompl           DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vAccountInfo         ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
  begin
    aChargeAmount    := 0;
    aDiscountAmount  := 0;

    open crParentCharges(parent_id, aOperationCharge);

    fetch crParentCharges
     into tplParentCharges;

    if crParentCharges%found then
      created  := 1;

      -- pointeur sur la position parent
      select *
        into tplParentPosition
        from doc_position
       where doc_position_id = parent_id;

      -- pointeur sur la position a traîter
      select *
        into tplPosition
        from doc_position
       where doc_position_id = position_id;

      -- Si le position est au tarif net, il ne faut pas créer ou copier les remises et taxes
      if (nvl(tplPosition.POS_NET_TARIFF, 0) = 1) then
        created  := 0;
      else
        -- recherch d'info dans le gabarit
        select C_ADMIN_DOMAIN
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
             , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
             , GAS_BALANCE_STATUS
          into admin_domain
             , vFinancial
             , vAnalytical
             , vInfoCompl
             , vBalance
          from doc_gauge GAU
             , doc_gauge_structured GAS
         where GAU.doc_gauge_id = tplPosition.doc_gauge_id
           and GAS.doc_gauge_id = GAU.doc_gauge_id;

        -- recherche du montant soumis en fonction du type de position (HT ou TTC)
        select decode(GAP_INCLUDE_TAX_TARIFF, 0, tplPosition.POS_GROSS_VALUE, 1, tplPosition.POS_GROSS_VALUE_INCL)
             , decode(GAP_INCLUDE_TAX_TARIFF, 0, tplPosition.POS_GROSS_VALUE, 1, tplPosition.POS_GROSS_VALUE_INCL)
             , decode(GAP_INCLUDE_TAX_TARIFF, 0, tplPosition.POS_GROSS_UNIT_VALUE, 1, tplPosition.POS_GROSS_UNIT_VALUE_INCL)
             , nvl(GAP_VALUE_QUANTITY, 0)
          into LiabledAmount
             , CascadeAmount
             , unitLiabledAmount
             , vGestValueQuantity
          from DOC_GAUGE_POSITION
         where DOC_GAUGE_POSITION_ID = tplPosition.DOC_GAUGE_POSITION_ID;

        -- Remises/taxes non cascade
        while crParentCharges%found loop
          if tplParentCharges.SERIES_CALC = 1 then
            LiabledAmount  := CascadeAmount;

            ----
            -- Recalcul le montant soumis unitaire lorsque la charge est en cascade.
            --   En effet, dans ce cas la, il ne faut pas prendre le montant unitaire
            --   de la position.
            --
            if (vGestValueQuantity = 1) then
              if (tplPosition.POS_VALUE_QUANTITY <> 0) then
                unitLiabledAmount  := CascadeAmount / tplPosition.POS_VALUE_QUANTITY;
              else
                unitLiabledAmount  := CascadeAmount;
              end if;
            else
              if (tplPosition.POS_FINAL_QUANTITY <> 0) then
                unitLiabledAmount  := CascadeAmount / tplPosition.POS_FINAL_QUANTITY;
              else
                unitLiabledAmount  := CascadeAmount;
              end if;
            end if;
          end if;

          -- Recherche de la quantité à prendre en compte.
          if (vGestValueQuantity = 1) then
            vQuantity  := tplPosition.POS_VALUE_QUANTITY;
          else
            vQuantity  := tplPosition.POS_FINAL_QUANTITY;
          end if;

          -- Transfert proportionnel
          if     tplParentCharges.TRANSFERT_PROP = 1
             and tplParentCharges.C_CHARGE_KIND <> 'DOR' then
            if vGestValueQuantity = 1 then
              -- décharge_complète
              if     (tplPosition.POS_FINAL_QUANTITY = tplParentPosition.POS_FINAL_QUANTITY)
                 and (tplPosition.POS_VALUE_QUANTITY = tplParentPosition.POS_VALUE_QUANTITY) then
                pchAmount  := tplParentCharges.PCH_AMOUNT;
              -- solde
              elsif     aBalance = 1
                    and tplPosition.POS_UPDATE_QTY_PRICE = 0
                    and tplPosition.POS_VALUE_QUANTITY = tplParentPosition.POS_BALANCE_QTY_VALUE then
                pchAmount  := tplParentCharges.PCH_BALANCE_AMOUNT;
              -- décharge partielle
              else
                pchAmount  :=
                  ACS_FUNCTION.PcsRound( (tplParentCharges.PCH_AMOUNT * tplPosition.POS_VALUE_QUANTITY) / tplParentPosition.POS_VALUE_QUANTITY
                                      , tplParentCharges.c_round_type
                                      , tplParentCharges.round_amount
                                       );
              end if;
            else
              -- décharge_complète
              if tplPosition.pos_final_quantity = tplParentPosition.pos_final_quantity then
                pchAmount  := tplParentCharges.pch_amount;
              -- solde
              elsif     tplPosition.pos_final_quantity = tplParentPosition.pos_balance_quantity
                    and tplPosition.POS_UPDATE_QTY_PRICE = 0 then
                pchAmount  := tplParentCharges.pch_balance_amount;
              -- décharge partielle
              else
                pchAmount  :=
                  ACS_FUNCTION.PcsRound( (tplParentCharges.PCH_AMOUNT * tplPosition.pos_final_quantity) / tplParentPosition.pos_final_quantity
                                      , tplParentCharges.c_round_type
                                      , tplParentCharges.round_amount
                                       );
              end if;
            end if;
          -- recalcul des remises/taxes
          else
            -- traitement des taxes
            if tplParentCharges.PTC_CHARGE_ID <> 0 then
              -- On ne multiplie pas par la quantité quand on copie avec transfert proportionnel
              vIsMultiplicator  := (1 - tplParentCharges.transfert_prop) * tplParentCharges.is_multiplicator;
              PTC_FUNCTIONS.CalcCharge(tplParentCharges.PTC_CHARGE_ID   -- Id de la taxe à calculer
                                     , tplParentCharges.descr   -- Nom de la taxe
                                     , unitLiabledAmount   -- Montant unitaire soumis à la taxe en monnaie document
                                     , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                     , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                     , vQuantity   -- Pour les taxes de type détail, quantité de la position
                                     , tplPosition.GCO_GOOD_ID   -- Identifiant du bien
                                     , nvl(tplPosition.PAC_THIRD_TARIFF_ID, tplPosition.PAC_THIRD_ID)   -- Identifiant du tiers tarification
                                     , tplPosition.DOC_POSITION_ID   -- Identifiant de la position pour les taxes détaillées de type 8 (plsql)
                                     , null   -- Identifiant du document pour les taxes de type total de type 8 (plsql)
                                     , currency_id   -- Id de la monnaie du montant soumis
                                     , rate_of_exchange   -- Taux de change
                                     , base_price   -- Diviseur
                                     , dateref   -- Date de référence
                                     , tplParentCharges.C_CALCULATION_MODE   -- Mode de calcul
                                     , tplParentCharges.rate   -- Taux
                                     , tplParentCharges.fraction   -- Fraction
                                     , tplParentCharges.fixed_amount_b   -- Montant fixe en monnaie de base
                                     , tplParentCharges.fixed_amount   -- Montant fixe en monnaie document
                                     , tplParentCharges.quantity_from   -- Quantité de
                                     , tplParentCharges.quantity_to   -- Quantité a
                                     , tplParentCharges.min_amount   -- Montant minimum de remise/taxe
                                     , tplParentCharges.max_amount   -- Montant maximum de remise/taxe
                                     , tplParentCharges.exceeded_amount_from   -- Montant de dépassement de
                                     , tplParentCharges.exceeded_amount_to   -- Montant de dépassement à
                                     , tplParentCharges.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                     , vIsMultiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                     , tplParentCharges.automatic_calc   -- Calculation auto ou à partir de sql_Extern_item
                                     , tplParentCharges.sql_extern_item   -- Commande sql de recherche du montant soumis à la calculation
                                     , tplParentCharges.c_round_type   -- Type d'arrondi
                                     , tplParentCharges.round_amount   -- Montant d'arrondi
                                     , tplParentCharges.unit_detail   -- Détail unitaire
                                     , tplParentCharges.original   -- Origine de la taxe (1 = création, 0 = modification)
                                     , tplParentCharges.cumulative   -- Origine de la taxe (1 = création, 0 = modification)
                                     , pchAmount   -- Montant de la taxe
                                     , blnFound   -- Taxe trouvée
                                     , PCS.PC_CONFIG.GetConfig('PTC_DC_DET_TEST_QTY_RECALC')
                                     , PCS.PC_CONFIG.GetConfig('PTC_DC_DET_TEST_AMOUNT_RECALC')
                                      );
            -- traitement des remises
            else
              -- On ne multiplie pas par la quantité quand on copie avec transfert proportionnel
              vIsMultiplicator  := (1 - tplParentCharges.transfert_prop) * tplParentCharges.is_multiplicator;
              PTC_FUNCTIONS.CalcDiscount(tplParentCharges.PTC_DISCOUNT_ID   -- Id de la remise à calculer
                                       , unitLiabledAmount   -- Montant unitaire soumis à la remise en monnaie document
                                       , liabledAmount   -- Montant soumis à la remise en monnaie document
                                       , liabledAmount   -- Montant soumis à la remise en monnaie document
                                       , vQuantity   -- Pour les remises de type détail, quantité de la position
                                       , tplPosition.DOC_POSITION_ID   -- Identifiant de la position pour les remises détaillées de type 8 (plsql)
                                       , null   -- Identifiant du document pour les remises de type total de type 8 (plsql)
                                       , currency_id   -- Id de la monnaie du montant soumis
                                       , rate_of_exchange   -- Taux de change
                                       , base_price   -- Diviseur
                                       , dateref   -- Date de référence
                                       , tplParentCharges.C_CALCULATION_MODE   -- Mode de calcul
                                       , tplParentCharges.rate   -- Taux
                                       , tplParentCharges.fraction   -- Fraction
                                       , tplParentCharges.fixed_amount_b   -- Montant fixe en monnaie de base
                                       , tplParentCharges.fixed_amount   -- Montant fixe en monnaie document
                                       , tplParentCharges.quantity_from   -- Quantité de
                                       , tplParentCharges.quantity_to   -- Quantité a
                                       , tplParentCharges.min_amount   -- Montant minimum de remise/taxe
                                       , tplParentCharges.max_amount   -- Montant maximum de remise/taxe
                                       , tplParentCharges.exceeded_amount_from   -- Montant de dépassement de
                                       , tplParentCharges.exceeded_amount_to   -- Montant de dépassement à
                                       , tplParentCharges.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                       , vIsMultiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                       , tplParentCharges.c_round_type   -- Type d'arrondi
                                       , tplParentCharges.round_amount   -- Montant d'arrondi
                                       , tplParentCharges.unit_detail   -- Détail unitaire
                                       , tplParentCharges.original   -- Origine de la remise (1 = création, 0 = modification)
                                       , tplParentCharges.cumulative   -- Origine de la remise (1 = création, 0 = modification)
                                       , pchAmount   -- Montant de la remise
                                       , blnFound   -- Remise trouvée
                                       , PCS.PC_CONFIG.GetConfig('PTC_DC_DET_TEST_QTY_RECALC')
                                       , PCS.PC_CONFIG.GetConfig('PTC_DC_DET_TEST_AMOUNT_RECALC')
                                        );
            end if;
          end if;

          /**
          * Mise à jour du solde restant sur la charge de position déchargée.
          */
          if     (aBalance = 1)
             and nvl(tplParentPosition.POS_UPDATE_QTY_PRICE, 0) = 0
             and (tplParentCharges.TRANSFERT_PROP = 1) then
            update DOC_POSITION_CHARGE
               set PCH_BALANCE_AMOUNT = PCH_BALANCE_AMOUNT - pchAmount
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where DOC_POSITION_CHARGE_ID = tplParentCharges.DOC_POSITION_CHARGE_ID;
          elsif     (aBalance = 1)
                and tplParentPosition.POS_UPDATE_QTY_PRICE = 1
                and (tplParentCharges.TRANSFERT_PROP = 1) then
            update DOC_POSITION_CHARGE
               set PCH_BALANCE_AMOUNT =
                                   PCH_AMOUNT
                                   *( (tplParentPosition.POS_BALANCE_QUANTITY - tplPosition.POS_FINAL_QUANTITY) / tplParentPosition.POS_FINAL_QUANTITY)
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where DOC_POSITION_CHARGE_ID = tplParentCharges.DOC_POSITION_CHARGE_ID;
          end if;

          -- Recherche des comptes

          -- traitement des taxes
          if tplParentCharges.PTC_CHARGE_ID <> 0 then
            -- Si gestion des comptes financiers ou analytiques
            if    (vFinancial = 1)
               or (vAnalytical = 1) then
              -- Reprend les comptes éventuels du parent ou de la taxe
              FinancialID  := tplParentCharges.ACS_FINANCIAL_ACCOUNT_ID;
              DivisionID   := tplParentCharges.ACS_DIVISION_ACCOUNT_ID;
              CpnID        := tplParentCharges.ACS_CPN_ACCOUNT_ID;
              CdaID        := tplParentCharges.ACS_CDA_ACCOUNT_ID;
              PfID         := tplParentCharges.ACS_PF_ACCOUNT_ID;
              PjID         := tplParentCharges.ACS_PJ_ACCOUNT_ID;

              if (vInfoCompl = 1) then
                vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(tplParentCharges.HRM_PERSON_ID);
                vAccountInfo.FAM_FIXED_ASSETS_ID    := tplParentCharges.FAM_FIXED_ASSETS_ID;
                vAccountInfo.C_FAM_TRANSACTION_TYP  := tplParentCharges.C_FAM_TRANSACTION_TYP;
                vAccountInfo.DEF_DIC_IMP_FREE1      := tplParentCharges.DIC_IMP_FREE1_ID;
                vAccountInfo.DEF_DIC_IMP_FREE2      := tplParentCharges.DIC_IMP_FREE2_ID;
                vAccountInfo.DEF_DIC_IMP_FREE3      := tplParentCharges.DIC_IMP_FREE3_ID;
                vAccountInfo.DEF_DIC_IMP_FREE4      := tplParentCharges.DIC_IMP_FREE4_ID;
                vAccountInfo.DEF_DIC_IMP_FREE5      := tplParentCharges.DIC_IMP_FREE5_ID;
                vAccountInfo.DEF_TEXT1              := tplParentCharges.PCH_IMP_TEXT_1;
                vAccountInfo.DEF_TEXT2              := tplParentCharges.PCH_IMP_TEXT_2;
                vAccountInfo.DEF_TEXT3              := tplParentCharges.PCH_IMP_TEXT_3;
                vAccountInfo.DEF_TEXT4              := tplParentCharges.PCH_IMP_TEXT_4;
                vAccountInfo.DEF_TEXT5              := tplParentCharges.PCH_IMP_TEXT_5;
                vAccountInfo.DEF_NUMBER1            := to_char(tplParentCharges.PCH_IMP_NUMBER_1);
                vAccountInfo.DEF_NUMBER2            := to_char(tplParentCharges.PCH_IMP_NUMBER_2);
                vAccountInfo.DEF_NUMBER3            := to_char(tplParentCharges.PCH_IMP_NUMBER_3);
                vAccountInfo.DEF_NUMBER4            := to_char(tplParentCharges.PCH_IMP_NUMBER_4);
                vAccountInfo.DEF_NUMBER5            := to_char(tplParentCharges.PCH_IMP_NUMBER_5);
                vAccountInfo.DEF_DATE1              := tplParentCharges.PCH_IMP_DATE_1;
                vAccountInfo.DEF_DATE2              := tplParentCharges.PCH_IMP_DATE_2;
                vAccountInfo.DEF_DATE3              := tplParentCharges.PCH_IMP_DATE_3;
                vAccountInfo.DEF_DATE4              := tplParentCharges.PCH_IMP_DATE_4;
                vAccountInfo.DEF_DATE5              := tplParentCharges.PCH_IMP_DATE_5;
              else
                vAccountInfo.DEF_HRM_PERSON         := null;
                vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vAccountInfo.DEF_TEXT1              := null;
                vAccountInfo.DEF_TEXT2              := null;
                vAccountInfo.DEF_TEXT3              := null;
                vAccountInfo.DEF_TEXT4              := null;
                vAccountInfo.DEF_TEXT5              := null;
                vAccountInfo.DEF_NUMBER1            := null;
                vAccountInfo.DEF_NUMBER2            := null;
                vAccountInfo.DEF_NUMBER3            := null;
                vAccountInfo.DEF_NUMBER4            := null;
                vAccountInfo.DEF_NUMBER5            := null;
                vAccountInfo.DEF_DATE1              := null;
                vAccountInfo.DEF_DATE2              := null;
                vAccountInfo.DEF_DATE3              := null;
                vAccountInfo.DEF_DATE4              := null;
                vAccountInfo.DEF_DATE5              := null;
              end if;

              -- recherche des comptes
              ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplParentCharges.PTC_CHARGE_ID
                                                       , '30'
                                                       , admin_domain
                                                       , DateRef
                                                       , tplPosition.DOC_GAUGE_ID
                                                       , tplPosition.DOC_DOCUMENT_ID
                                                       , position_id
                                                       , tplPosition.DOC_RECORD_ID
                                                       , tplPosition.PAC_THIRD_ACI_ID
                                                       , tplPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                       , tplPosition.ACS_DIVISION_ACCOUNT_ID
                                                       , tplPosition.ACS_CPN_ACCOUNT_ID
                                                       , tplPosition.ACS_CDA_ACCOUNT_ID
                                                       , tplPosition.ACS_PF_ACCOUNT_ID
                                                       , tplPosition.ACS_PJ_ACCOUNT_ID
                                                       , FinancialID
                                                       , DivisionID
                                                       , CpnID
                                                       , CdaID
                                                       , PfID
                                                       , PjID
                                                       , vAccountInfo
                                                        );

              if (vAnalytical = 0) then
                CpnID  := null;
                CdaID  := null;
                PjID   := null;
                PfID   := null;
              end if;
            end if;
          else   -- Traitement des remises
            -- Si gestion des comptes financiers ou analytiques
            if    (vFinancial = 1)
               or (vAnalytical = 1) then
              -- Reprend les comptes éventuels du parent ou de la remise
              FinancialID  := tplParentCharges.ACS_FINANCIAL_ACCOUNT_ID;
              DivisionID   := tplParentCharges.ACS_DIVISION_ACCOUNT_ID;
              CpnID        := tplParentCharges.ACS_CPN_ACCOUNT_ID;
              CdaID        := tplParentCharges.ACS_CDA_ACCOUNT_ID;
              PfID         := tplParentCharges.ACS_PF_ACCOUNT_ID;
              PjID         := tplParentCharges.ACS_PJ_ACCOUNT_ID;

              if (vInfoCompl = 1) then
                vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(tplParentCharges.HRM_PERSON_ID);
                vAccountInfo.FAM_FIXED_ASSETS_ID    := tplParentCharges.FAM_FIXED_ASSETS_ID;
                vAccountInfo.C_FAM_TRANSACTION_TYP  := tplParentCharges.C_FAM_TRANSACTION_TYP;
                vAccountInfo.DEF_DIC_IMP_FREE1      := tplParentCharges.DIC_IMP_FREE1_ID;
                vAccountInfo.DEF_DIC_IMP_FREE2      := tplParentCharges.DIC_IMP_FREE2_ID;
                vAccountInfo.DEF_DIC_IMP_FREE3      := tplParentCharges.DIC_IMP_FREE3_ID;
                vAccountInfo.DEF_DIC_IMP_FREE4      := tplParentCharges.DIC_IMP_FREE4_ID;
                vAccountInfo.DEF_DIC_IMP_FREE5      := tplParentCharges.DIC_IMP_FREE5_ID;
                vAccountInfo.DEF_TEXT1              := tplParentCharges.PCH_IMP_TEXT_1;
                vAccountInfo.DEF_TEXT2              := tplParentCharges.PCH_IMP_TEXT_2;
                vAccountInfo.DEF_TEXT3              := tplParentCharges.PCH_IMP_TEXT_3;
                vAccountInfo.DEF_TEXT4              := tplParentCharges.PCH_IMP_TEXT_4;
                vAccountInfo.DEF_TEXT5              := tplParentCharges.PCH_IMP_TEXT_5;
                vAccountInfo.DEF_NUMBER1            := to_char(tplParentCharges.PCH_IMP_NUMBER_1);
                vAccountInfo.DEF_NUMBER2            := to_char(tplParentCharges.PCH_IMP_NUMBER_2);
                vAccountInfo.DEF_NUMBER3            := to_char(tplParentCharges.PCH_IMP_NUMBER_3);
                vAccountInfo.DEF_NUMBER4            := to_char(tplParentCharges.PCH_IMP_NUMBER_4);
                vAccountInfo.DEF_NUMBER5            := to_char(tplParentCharges.PCH_IMP_NUMBER_5);
                vAccountInfo.DEF_DATE1              := tplParentCharges.PCH_IMP_DATE_1;
                vAccountInfo.DEF_DATE2              := tplParentCharges.PCH_IMP_DATE_2;
                vAccountInfo.DEF_DATE3              := tplParentCharges.PCH_IMP_DATE_3;
                vAccountInfo.DEF_DATE4              := tplParentCharges.PCH_IMP_DATE_4;
                vAccountInfo.DEF_DATE5              := tplParentCharges.PCH_IMP_DATE_5;
              else
                vAccountInfo.DEF_HRM_PERSON         := null;
                vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vAccountInfo.DEF_TEXT1              := null;
                vAccountInfo.DEF_TEXT2              := null;
                vAccountInfo.DEF_TEXT3              := null;
                vAccountInfo.DEF_TEXT4              := null;
                vAccountInfo.DEF_TEXT5              := null;
                vAccountInfo.DEF_NUMBER1            := null;
                vAccountInfo.DEF_NUMBER2            := null;
                vAccountInfo.DEF_NUMBER3            := null;
                vAccountInfo.DEF_NUMBER4            := null;
                vAccountInfo.DEF_NUMBER5            := null;
                vAccountInfo.DEF_DATE1              := null;
                vAccountInfo.DEF_DATE2              := null;
                vAccountInfo.DEF_DATE3              := null;
                vAccountInfo.DEF_DATE4              := null;
                vAccountInfo.DEF_DATE5              := null;
              end if;

              -- recherche des comptes
              ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplParentCharges.PTC_DISCOUNT_ID
                                                       , '20'
                                                       , admin_domain
                                                       , DateRef
                                                       , tplPosition.DOC_GAUGE_ID
                                                       , tplPosition.DOC_DOCUMENT_ID
                                                       , position_id
                                                       , tplPosition.DOC_RECORD_ID
                                                       , tplPosition.PAC_THIRD_ACI_ID
                                                       , tplPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                       , tplPosition.ACS_DIVISION_ACCOUNT_ID
                                                       , tplPosition.ACS_CPN_ACCOUNT_ID
                                                       , tplPosition.ACS_CDA_ACCOUNT_ID
                                                       , tplPosition.ACS_PF_ACCOUNT_ID
                                                       , tplPosition.ACS_PJ_ACCOUNT_ID
                                                       , FinancialID
                                                       , DivisionID
                                                       , CpnID
                                                       , CdaID
                                                       , PfID
                                                       , PjID
                                                       , vAccountInfo
                                                        );

              if (vAnalytical = 0) then
                CpnID  := null;
                CdaID  := null;
                PjID   := null;
                PfID   := null;
              end if;
            end if;
          end if;

          -- recherche des données complémentaires obligatoires ou interdites
          DOC_INFO_COMPL.GetUsedInfoCompl(tplPosition.DOC_DOCUMENT_ID
                                        , HrmPerson
                                        , FamFixed
                                        , Text1
                                        , Text2
                                        , Text3
                                        , Text4
                                        , Text5
                                        , Number1
                                        , Number2
                                        , Number3
                                        , Number4
                                        , Number5
                                        , DicFree1
                                        , DicFree2
                                        , DicFree3
                                        , DicFree4
                                        , DicFree5
                                        , Date1
                                        , Date2
                                        , Date3
                                        , Date4
                                        , Date5
                                         );

          -- création de la remise/taxe
          insert into DOC_POSITION_CHARGE
                      (DOC_POSITION_CHARGE_ID
                     , DOC_POSITION_ID
                     , C_CHARGE_ORIGIN
                     , C_FINANCIAL_CHARGE
                     , PCH_NAME
                     , PCH_DESCRIPTION
                     , PCH_AMOUNT
                     , PCH_BALANCE_AMOUNT
                     , PCH_CALC_AMOUNT
                     , PCH_LIABLED_AMOUNT
                     , PCH_FIXED_AMOUNT_B
                     , PCH_EXCEEDED_AMOUNT_FROM
                     , PCH_EXCEEDED_AMOUNT_TO
                     , PCH_MIN_AMOUNT
                     , PCH_MAX_AMOUNT
                     , PCH_QUANTITY_FROM
                     , PCH_QUANTITY_TO
                     , C_ROUND_TYPE
                     , PCH_ROUND_AMOUNT
                     , C_CALCULATION_MODE
                     , PCH_TRANSFERT_PROP
                     , PCH_MODIFY
                     , PCH_UNIT_DETAIL
                     , PCH_IN_SERIES_CALCULATION
                     , PCH_AUTOMATIC_CALC
                     , PCH_IS_MULTIPLICATOR
                     , PCH_STORED_PROC
                     , PCH_SQL_EXTERN_ITEM
                     , PTC_DISCOUNT_ID
                     , PTC_CHARGE_ID
                     , PCH_RATE
                     , PCH_EXPRESS_IN
                     , PCH_CUMULATIVE
                     , PCH_DISCHARGED
                     , PCH_PRCS_USE
                     , DOC_DOC_POSITION_CHARGE_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_DIVISION_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                     , HRM_PERSON_ID
                     , FAM_FIXED_ASSETS_ID
                     , C_FAM_TRANSACTION_TYP
                     , PCH_IMP_TEXT_1
                     , PCH_IMP_TEXT_2
                     , PCH_IMP_TEXT_3
                     , PCH_IMP_TEXT_4
                     , PCH_IMP_TEXT_5
                     , PCH_IMP_NUMBER_1
                     , PCH_IMP_NUMBER_2
                     , PCH_IMP_NUMBER_3
                     , PCH_IMP_NUMBER_4
                     , PCH_IMP_NUMBER_5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                     , PCH_IMP_DATE_1
                     , PCH_IMP_DATE_2
                     , PCH_IMP_DATE_3
                     , PCH_IMP_DATE_4
                     , PCH_IMP_DATE_5
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , tplPosition.DOC_POSITION_ID
                     , nvl(tplParentCharges.C_CHARGE_ORIGIN, 'AUTO')
                     , decode(tplParentCharges.PTC_CHARGE_ID, 0, '02', '03')
                     , tplParentCharges.PTC_NAME
                     , tplParentCharges.Descr
                     , pchAmount
                     , decode(vBalance, 1, pchAmount, 0)
                     , pchAmount
                     , LiabledAmount
                     , tplParentCharges.FIXED_AMOUNT_B
                     ,   -- Attention, a revoir dans le cas de monnaie différente [ou de transfert proportionnel partiel]
                       tplParentCharges.EXCEEDED_AMOUNT_FROM
                     , tplParentCharges.EXCEEDED_AMOUNT_TO
                     , tplParentCharges.MIN_AMOUNT
                     , tplParentCharges.MAX_AMOUNT
                     , tplParentCharges.QUANTITY_FROM
                     , tplParentCharges.QUANTITY_TO
                     , tplParentCharges.C_ROUND_TYPE
                     , tplParentCharges.ROUND_AMOUNT
                     , tplParentCharges.C_CALCULATION_MODE
                     , tplParentCharges.TRANSFERT_PROP
                     , tplParentCharges.MODIF
                     , tplParentCharges.UNIT_DETAIL
                     , tplParentCharges.IN_SERIES_CALCULATION
                     , tplParentCharges.AUTOMATIC_CALC
                     , tplParentCharges.IS_MULTIPLICATOR
                     , tplParentCharges.STORED_PROC
                     , tplParentCharges.SQL_EXTERN_ITEM
                     , zvl(tplParentCharges.PTC_DISCOUNT_ID, null)
                     , zvl(tplParentCharges.PTC_CHARGE_ID, null)
                     , tplParentCharges.RATE
                     , tplParentCharges.FRACTION
                     , tplParentCharges.CUMULATIVE
                     , aBalance
                     , tplParentCharges.PRCS_USE
                     , decode(aBalance, 1, tplParentCharges.DOC_POSITION_CHARGE_ID, null)
                     , FinancialId
                     , DivisionId
                     , CpnId
                     , CdaId
                     , PfId
                     , PjId
                     , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                     , vAccountInfo.FAM_FIXED_ASSETS_ID
                     , vAccountInfo.C_FAM_TRANSACTION_TYP
                     , vAccountInfo.DEF_TEXT1
                     , vAccountInfo.DEF_TEXT2
                     , vAccountInfo.DEF_TEXT3
                     , vAccountInfo.DEF_TEXT4
                     , vAccountInfo.DEF_TEXT5
                     , to_number(vAccountInfo.DEF_NUMBER1)
                     , to_number(vAccountInfo.DEF_NUMBER2)
                     , to_number(vAccountInfo.DEF_NUMBER3)
                     , to_number(vAccountInfo.DEF_NUMBER4)
                     , to_number(vAccountInfo.DEF_NUMBER5)
                     , vAccountInfo.DEF_DIC_IMP_FREE1
                     , vAccountInfo.DEF_DIC_IMP_FREE2
                     , vAccountInfo.DEF_DIC_IMP_FREE3
                     , vAccountInfo.DEF_DIC_IMP_FREE4
                     , vAccountInfo.DEF_DIC_IMP_FREE5
                     , vAccountInfo.DEF_DATE1
                     , vAccountInfo.DEF_DATE2
                     , vAccountInfo.DEF_DATE3
                     , vAccountInfo.DEF_DATE4
                     , vAccountInfo.DEF_DATE5
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          select aChargeAmount + decode(tplParentCharges.PTC_CHARGE_ID, 0, 0, pchAmount)
            into aChargeAmount
            from dual;

          select aDiscountAmount + decode(tplParentCharges.PTC_DISCOUNT_ID, 0, 0, pchAmount)
            into aDiscountAmount
            from dual;

          select CascadeAmount + decode(tplParentCharges.PTC_CHARGE_ID, 0, -pchAmount, pchAmount)
            into CascadeAmount
            from dual;

          fetch crParentCharges
           into tplParentCharges;
        end loop;
      end if;
    else
      created  := 0;
    end if;

    close crParentCharges;

    if roundPositionAmount(position_id, dateref, currency_id) then
      select nvl(sum(PCH_AMOUNT), 0)
        into lChargeRoundAmount
        from DOC_POSITION_CHARGE PCH
           , PTC_CHARGE CRG
       where PCH.DOC_POSITION_ID = position_id
         and CRG.PTC_CHARGE_ID = PCH.PTC_CHARGE_ID
         and CRG.C_CHARGE_KIND = 'POR';

      aChargeAmount    := aChargeAmount + lChargeRoundAmount;

      select nvl(sum(PCH_AMOUNT), 0)
        into lDiscountRoundAmount
        from DOC_POSITION_CHARGE PCH
           , PTC_DISCOUNT DNT
       where PCH.DOC_POSITION_ID = position_id
         and DNT.PTC_DISCOUNT_ID = PCH.PTC_DISCOUNT_ID
         and DNT.C_DISCOUNT_KIND = 'POR';

      aDiscountAmount  := aDiscountAmount + lDiscountRoundAmount;
    end if;

    update DOC_POSITION
       set POS_UPDATE_POSITION_CHARGE = 0
         , POS_CREATE_POSITION_CHARGE = 0
     where DOC_POSITION_ID = position_Id;
  end CopyPositionCharge;

  /**
  * Description
  *      Applique l'arrondi "Swisscom" sur la position
  */
  function roundPositionAmount(
    aPositionId in doc_position.doc_position_id%type
  , aDateRef    in date
  , aCurrencyId in acs_financial_currency.acs_financial_currency_id%type
  , aLangId     in doc_document.pc_lang_id%type default null
  )
    return boolean
  is
    cursor crDiscountCharge(astrChargeList varchar2, astrDiscountList varchar2, aLangId number)
    is
      select   DNT.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(DID_DESCR, DNT_NAME) DESCR
             , DNT_NAME PTC_NAME
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , cast(null as varchar2(4000) ) SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE vChargeType
             , DNT_EXCLUSIVE EXCLUSIF
             , DNT_PRCS_USE PRCS_USE
          from PTC_DISCOUNT DNT
             , PTC_DISCOUNT_DESCR DID
             , (select column_value as PTC_DISCOUNT_ID
                  from table(PCS.idListToTable(astrDiscountList) ) ) DNT_LST
         where DNT.PTC_DISCOUNT_ID = DNT_LST.PTC_DISCOUNT_ID
           and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
           and DID.PC_LANG_ID(+) = aLangId
      union
      select   0 PTC_DISCOUNT_ID
             , CRG.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(CHD_DESCR, CRG_NAME) DESCR
             , CRG_NAME PTC_NAME
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE vChargeType
             , CRG_EXCLUSIVE EXCLUSIF
             , CRG_PRCS_USE PRCS_USE
          from PTC_CHARGE CRG
             , PTC_CHARGE_DESCRIPTION CHD
             , (select column_value as PTC_CHARGE_ID
                  from table(PCS.idListToTable(astrChargeList) ) ) CRG_LST
         where CRG.PTC_CHARGE_ID = CRG_LST.PTC_CHARGE_ID
           and CRG.PTC_CHARGE_ID = CHD.PTC_CHARGE_ID(+)
           and CHD.PC_LANG_ID(+) = aLangId
      order by SERIES_CALC
             , PTC_NAME;

    vTplPosition       doc_position%rowtype;
    vChargeType        PTC_CHARGE.C_CHARGE_TYPE%type;
    vAdminDomain       DOC_GAUGE.C_ADMIN_DOMAIN%type;
    vNumChanged        integer;
    vChargeList        varchar2(200);
    vDiscountList      varchar2(200);
    vPchAmount         DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vLiabledAmount     DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vChargeAmount      DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vDiscountAmount    DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vDifference        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vFinancialId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivisionId        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCpnId             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCdaId             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPfId              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPjId              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPositionChargeId  DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type;
    vGestValueQuantity DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    vQuantity          DOC_POSITION.POS_FINAL_QUANTITY%type;
    vFinancial         DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical        DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl         DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vTblAccountInfo    ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    lLangId            DOC_DOCUMENT.PC_LANG_ID%type;
    lResult            boolean                                           := false;
  begin
    -- ne s'applique que sur les document en francs suisses
    if ACS_FUNCTION.GetCurrencyName(aCurrencyId) = 'CHF' then
      -- pointeur sur la position a traîter
      select *
        into vTplPosition
        from doc_position
       where doc_position_id = aPositionId;

      -- recherche d'info dans le gabarit
      select decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
           , C_ADMIN_DOMAIN
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
           , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
        into vChargeType
           , vAdminDomain
           , vFinancial
           , vAnalytical
           , vInfoCompl
        from doc_gauge GAU
           , doc_gauge_structured GAS
       where GAU.doc_gauge_id = vTplPosition.doc_gauge_id
         and GAS.doc_gauge_id = GAU.doc_gauge_id;

      -- recherche des remises/taxes
      PTC_FIND_DISCOUNT_CHARGE.TESTPORDISCOUNTCHARGE(nvl(vTplPosition.DOC_GAUGE_ID, 0)
                                                   , nvl(nvl(vTplPosition.PAC_THIRD_TARIFF_ID, vTplPosition.PAC_THIRD_ID), 0)
                                                   , nvl(vTplPosition.DOC_RECORD_ID, 0)
                                                   , nvl(vTplPosition.GCO_GOOD_ID, 0)
                                                   , vChargeType
                                                   , aDateRef
                                                   , vNumChanged   -- vBlnDiscount
                                                    );
      -- récupération de la liste des taxes
      vChargeList    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'POR');
      -- récupération de la liste des remises
      vDiscountList  := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'POR');

      if    vChargeList is not null
         or vDiscountList is not null then
        -- recherche une remise/taxes déjà existante
        select max(DOC_POSITION_CHARGE_ID)
          into vPositionChargeId
          from DOC_POSITION_CHARGE
         where DOC_POSITION_ID = aPositionId
           and C_CALCULATION_MODE = '10';

        -- recherche des montants de remise/taxe
        select nvl(sum(decode(PTC_CHARGE_ID, null, 0, PCH_AMOUNT) ), 0)
             , nvl(sum(decode(PTC_DISCOUNT_ID, null, 0, PCH_AMOUNT) ), 0)
          into vChargeAmount
             , vDiscountAmount
          from DOC_POSITION_CHARGE
         where DOC_POSITION_ID = aPositionId;

        -- mise à 0 de la remise/taxe existante
        update DOC_POSITION_CHARGE
           set PCH_AMOUNT = 0
         where DOC_POSITION_CHARGE_ID = vPositionChargeId;

        -- recherche des montants de remise/taxe
        select nvl(sum(decode(PTC_CHARGE_ID, null, 0, PCH_AMOUNT) ), 0)
             , nvl(sum(decode(PTC_DISCOUNT_ID, null, 0, PCH_AMOUNT) ), 0)
          into vChargeAmount
             , vDiscountAmount
          from DOC_POSITION_CHARGE
         where DOC_POSITION_ID = aPositionId;

        -- mise à jour des montants sur la position
        UpdatePosAmountsDiscountCharge(aPositionId, aDateRef, vTplPosition.POS_INCLUDE_TAX_TARIFF, vChargeAmount, vDiscountAmount);

        -- pointeur sur la position a traîter (rafraichissement)
        select *
          into vTplPosition
          from doc_position
         where doc_position_id = aPositionId;

        if aLangId is not null then
          lLangId  := aLangId;
        else
          lLangId  := FWK_I_LIB_ENTITY.getvarchar2fieldfrompk('DOC_DOCUMENT', 'PC_LANG_ID', vTplPosition.DOC_DOCUMENT_ID);
        end if;

        -- recherche du montant soumis en fonction du type de position (HT ou TTC)
        select decode(GAP_INCLUDE_TAX_TARIFF, 0, vTplPosition.POS_NET_VALUE_EXCL, 1, vTplPosition.POS_NET_VALUE_INCL)
          into vLiabledAmount
          from DOC_GAUGE_POSITION
         where DOC_GAUGE_POSITION_ID = vTplPosition.DOC_GAUGE_POSITION_ID;

        vDifference  := ACS_FUNCTION.PcsRound(vLiabledAmount, '1') - vLiabledAmount;

        if vDifference <> 0 then
          lResult  := true;

          -- ouverture d'un query sur les infos  des remises/taxes
          for tplDiscountCharge in crDiscountCharge(vChargeList, vDiscountList, lLangId) loop
            -- traitement des taxes
            if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
              vPchAmount  := vDifference;

              -- Si gestion des comptes financiers ou analytiques
              if     (vPositionchargeId is null)
                 and (    (vFinancial = 1)
                      or (vAnalytical = 1) ) then
                -- Utilise les comptes de la taxe
                vFinancialId                           := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                vDivisionId                            := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                vCpnId                                 := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                vCdaId                                 := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                vPfId                                  := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                vPjId                                  := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                vTblAccountInfo.DEF_HRM_PERSON         := null;
                vTblAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vTblAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vTblAccountInfo.DEF_TEXT1              := null;
                vTblAccountInfo.DEF_TEXT2              := null;
                vTblAccountInfo.DEF_TEXT3              := null;
                vTblAccountInfo.DEF_TEXT4              := null;
                vTblAccountInfo.DEF_TEXT5              := null;
                vTblAccountInfo.DEF_NUMBER1            := null;
                vTblAccountInfo.DEF_NUMBER2            := null;
                vTblAccountInfo.DEF_NUMBER3            := null;
                vTblAccountInfo.DEF_NUMBER4            := null;
                vTblAccountInfo.DEF_NUMBER5            := null;
                vTblAccountInfo.DEF_DATE1              := null;
                vTblAccountInfo.DEF_DATE2              := null;
                vTblAccountInfo.DEF_DATE3              := null;
                vTblAccountInfo.DEF_DATE4              := null;
                vTblAccountInfo.DEF_DATE5              := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_CHARGE_ID
                                                         , '30'
                                                         , vAdminDomain
                                                         , aDateRef
                                                         , vTplPosition.DOC_GAUGE_ID
                                                         , vTplPosition.DOC_DOCUMENT_ID
                                                         , aPositionId
                                                         , vTplPosition.DOC_RECORD_ID
                                                         , vTplPosition.PAC_THIRD_ACI_ID
                                                         , vTplPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                         , vTplPosition.ACS_DIVISION_ACCOUNT_ID
                                                         , vTplPosition.ACS_CPN_ACCOUNT_ID
                                                         , vTplPosition.ACS_CDA_ACCOUNT_ID
                                                         , vTplPosition.ACS_PF_ACCOUNT_ID
                                                         , vTplPosition.ACS_PJ_ACCOUNT_ID
                                                         , vFinancialId
                                                         , vDivisionId
                                                         , vCpnId
                                                         , vCdaId
                                                         , vPfId
                                                         , vPjId
                                                         , vTblAccountInfo
                                                          );

                if (vAnalytical = 0) then
                  vCpnId  := null;
                  vCdaId  := null;
                  vPjId   := null;
                  vPfId   := null;
                end if;
              end if;
            -- traitement des remises
            else
              vPchAmount  := -vDifference;

              -- Si gestion des comptes financiers ou analytiques
              if     (vPositionchargeId is null)
                 and (    (vFinancial = 1)
                      or (vAnalytical = 1) ) then
                -- Utilise les comptes de la remise
                vFinancialId                           := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                vDivisionId                            := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                vCpnId                                 := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                vCdaId                                 := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                vPfId                                  := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                vPjId                                  := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                vTblAccountInfo.DEF_HRM_PERSON         := null;
                vTblAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vTblAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vTblAccountInfo.DEF_TEXT1              := null;
                vTblAccountInfo.DEF_TEXT2              := null;
                vTblAccountInfo.DEF_TEXT3              := null;
                vTblAccountInfo.DEF_TEXT4              := null;
                vTblAccountInfo.DEF_TEXT5              := null;
                vTblAccountInfo.DEF_NUMBER1            := null;
                vTblAccountInfo.DEF_NUMBER2            := null;
                vTblAccountInfo.DEF_NUMBER3            := null;
                vTblAccountInfo.DEF_NUMBER4            := null;
                vTblAccountInfo.DEF_NUMBER5            := null;
                vTblAccountInfo.DEF_DATE1              := null;
                vTblAccountInfo.DEF_DATE2              := null;
                vTblAccountInfo.DEF_DATE3              := null;
                vTblAccountInfo.DEF_DATE4              := null;
                vTblAccountInfo.DEF_DATE5              := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_DISCOUNT_ID
                                                         , '20'
                                                         , vAdminDomain
                                                         , aDateRef
                                                         , vTplPosition.DOC_GAUGE_ID
                                                         , vTplPosition.DOC_DOCUMENT_ID
                                                         , aPositionId
                                                         , vTplPosition.DOC_RECORD_ID
                                                         , vTplPosition.PAC_THIRD_ACI_ID
                                                         , vTplPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                         , vTplPosition.ACS_DIVISION_ACCOUNT_ID
                                                         , vTplPosition.ACS_CPN_ACCOUNT_ID
                                                         , vTplPosition.ACS_CDA_ACCOUNT_ID
                                                         , vTplPosition.ACS_PF_ACCOUNT_ID
                                                         , vTplPosition.ACS_PJ_ACCOUNT_ID
                                                         , vFinancialId
                                                         , vDivisionId
                                                         , vCpnId
                                                         , vCdaId
                                                         , vPfId
                                                         , vPjId
                                                         , vTblAccountInfo
                                                          );

                if (vAnalytical = 0) then
                  vCpnId  := null;
                  vCdaId  := null;
                  vPjId   := null;
                  vPfId   := null;
                end if;
              end if;
            end if;

            -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
            if vPositionchargeId is null then
              -- création de la remise/taxe
              insert into DOC_POSITION_CHARGE
                          (DOC_POSITION_CHARGE_ID
                         , DOC_POSITION_ID
                         , C_CHARGE_ORIGIN
                         , C_FINANCIAL_CHARGE
                         , PCH_NAME
                         , PCH_DESCRIPTION
                         , PCH_AMOUNT
                         , PCH_BALANCE_AMOUNT
                         , PCH_CALC_AMOUNT
                         , PCH_LIABLED_AMOUNT
                         , PCH_FIXED_AMOUNT_B
                         , PCH_EXCEEDED_AMOUNT_FROM
                         , PCH_EXCEEDED_AMOUNT_TO
                         , PCH_MIN_AMOUNT
                         , PCH_MAX_AMOUNT
                         , PCH_QUANTITY_FROM
                         , PCH_QUANTITY_TO
                         , C_ROUND_TYPE
                         , PCH_ROUND_AMOUNT
                         , C_CALCULATION_MODE
                         , PCH_TRANSFERT_PROP
                         , PCH_MODIFY
                         , PCH_UNIT_DETAIL
                         , PCH_IN_SERIES_CALCULATION
                         , PCH_AUTOMATIC_CALC
                         , PCH_IS_MULTIPLICATOR
                         , PCH_EXCLUSIVE
                         , PCH_STORED_PROC
                         , PCH_SQL_EXTERN_ITEM
                         , PTC_DISCOUNT_ID
                         , PTC_CHARGE_ID
                         , PCH_RATE
                         , PCH_EXPRESS_IN
                         , PCH_CUMULATIVE
                         , PCH_DISCHARGED
                         , PCH_PRCS_USE
                         , DOC_DOC_POSITION_CHARGE_ID
                         , ACS_FINANCIAL_ACCOUNT_ID
                         , ACS_DIVISION_ACCOUNT_ID
                         , ACS_CPN_ACCOUNT_ID
                         , ACS_CDA_ACCOUNT_ID
                         , ACS_PF_ACCOUNT_ID
                         , ACS_PJ_ACCOUNT_ID
                         , HRM_PERSON_ID
                         , FAM_FIXED_ASSETS_ID
                         , C_FAM_TRANSACTION_TYP
                         , PCH_IMP_TEXT_1
                         , PCH_IMP_TEXT_2
                         , PCH_IMP_TEXT_3
                         , PCH_IMP_TEXT_4
                         , PCH_IMP_TEXT_5
                         , PCH_IMP_NUMBER_1
                         , PCH_IMP_NUMBER_2
                         , PCH_IMP_NUMBER_3
                         , PCH_IMP_NUMBER_4
                         , PCH_IMP_NUMBER_5
                         , DIC_IMP_FREE1_ID
                         , DIC_IMP_FREE2_ID
                         , DIC_IMP_FREE3_ID
                         , DIC_IMP_FREE4_ID
                         , DIC_IMP_FREE5_ID
                         , PCH_IMP_DATE_1
                         , PCH_IMP_DATE_2
                         , PCH_IMP_DATE_3
                         , PCH_IMP_DATE_4
                         , PCH_IMP_DATE_5
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (init_id_seq.nextval
                         , vTplPosition.DOC_POSITION_ID
                         , 'AUTO'
                         , decode(tplDiscountCharge.PTC_CHARGE_ID, 0, '02', '03')
                         , tplDiscountCharge.PTC_NAME
                         , tplDiscountCharge.Descr
                         , vPchAmount
                         , vPchAmount
                         , vPchAmount
                         , vLiabledAmount
                         , tplDiscountCharge.FIXED_AMOUNT_B
                         , tplDiscountCharge.EXCEEDED_AMOUNT_FROM
                         , tplDiscountCharge.EXCEEDED_AMOUNT_TO
                         , tplDiscountCharge.MIN_AMOUNT
                         , tplDiscountCharge.MAX_AMOUNT
                         , tplDiscountCharge.QUANTITY_FROM
                         , tplDiscountCharge.QUANTITY_TO
                         , tplDiscountCharge.C_ROUND_TYPE
                         , tplDiscountCharge.ROUND_AMOUNT
                         , tplDiscountCharge.C_CALCULATION_MODE
                         , tplDiscountCharge.TRANSFERT_PROP
                         , 0   -- PCH_MODIFY
                         , tplDiscountCharge.UNIT_DETAIL
                         , 1
                         , tplDiscountCharge.AUTOMATIC_CALC
                         , tplDiscountCharge.IS_MULTIPLICATOR
                         , tplDiscountCharge.EXCLUSIF
                         , tplDiscountCharge.STORED_PROC
                         , tplDiscountCharge.SQL_EXTERN_ITEM
                         , zvl(tplDiscountCharge.PTC_DISCOUNT_ID, null)
                         , zvl(tplDiscountCharge.PTC_CHARGE_ID, null)
                         , tplDiscountCharge.RATE
                         , tplDiscountCharge.FRACTION
                         , 0   -- remise/taxe non cumulée
                         , 0   -- ne provenant de décharge
                         , tplDiscountCharge.PRCS_USE
                         , null
                         , vFinancialId
                         , vDivisionId
                         , vCpnId
                         , vCdaId
                         , vPfId
                         , vPjId
                         , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vTblAccountInfo.DEF_HRM_PERSON)
                         , vTblAccountInfo.FAM_FIXED_ASSETS_ID
                         , vTblAccountInfo.C_FAM_TRANSACTION_TYP
                         , vTblAccountInfo.DEF_TEXT1
                         , vTblAccountInfo.DEF_TEXT2
                         , vTblAccountInfo.DEF_TEXT3
                         , vTblAccountInfo.DEF_TEXT4
                         , vTblAccountInfo.DEF_TEXT5
                         , to_number(vTblAccountInfo.DEF_NUMBER1)
                         , to_number(vTblAccountInfo.DEF_NUMBER2)
                         , to_number(vTblAccountInfo.DEF_NUMBER3)
                         , to_number(vTblAccountInfo.DEF_NUMBER4)
                         , to_number(vTblAccountInfo.DEF_NUMBER5)
                         , vTblAccountInfo.DEF_DIC_IMP_FREE1
                         , vTblAccountInfo.DEF_DIC_IMP_FREE2
                         , vTblAccountInfo.DEF_DIC_IMP_FREE3
                         , vTblAccountInfo.DEF_DIC_IMP_FREE4
                         , vTblAccountInfo.DEF_DIC_IMP_FREE5
                         , vTblAccountInfo.DEF_DATE1
                         , vTblAccountInfo.DEF_DATE2
                         , vTblAccountInfo.DEF_DATE3
                         , vTblAccountInfo.DEF_DATE4
                         , vTblAccountInfo.DEF_DATE5
                         , sysdate
                         , PCS.PC_I_LIB_SESSION.GetUserIni
                          );
            -- remise/taxe déjà existante
            else
              -- mise à 0 de la remise/taxe existante
              update DOC_POSITION_CHARGE
                 set PCH_AMOUNT = vPchAmount
               where DOC_POSITION_CHARGE_ID = vPositionchargeId;
            end if;
          end loop;
        -- pas de différence
        else
          -- supression de la remis/taxe d'arrondi
          delete from DOC_POSITION_CHARGE
                where DOC_POSITION_ID = aPositionId
                  and C_CALCULATION_MODE = '10';
        end if;

        -- recherche des montants de remise/taxe
        select nvl(sum(decode(PTC_CHARGE_ID, null, 0, PCH_AMOUNT) ), 0)
             , nvl(sum(decode(PTC_DISCOUNT_ID, null, 0, PCH_AMOUNT) ), 0)
          into vChargeAmount
             , vDiscountAmount
          from DOC_POSITION_CHARGE
         where DOC_POSITION_ID = aPositionId;

        -- mise à jour des montants sur la position
        UpdatePosAmountsDiscountCharge(aPositionId, aDateRef, vTplPosition.POS_INCLUDE_TAX_TARIFF, vChargeAmount, vDiscountAmount);

        update DOC_POSITION
           set POS_CREATE_POSITION_CHARGE = 0
             , POS_UPDATE_POSITION_CHARGE = 0
         where DOC_POSITION_ID = aPositionId;
      end if;
    end if;

    return lResult;
  end roundPositionAmount;

  /**
  * Description
  *      Applique l'arrondi "Swisscom" sur la position
  */
  procedure roundPositionAmount(
    aPositionId in doc_position.doc_position_id%type
  , aDateRef    in date
  , aCurrencyId in acs_financial_currency.acs_financial_currency_id%type
  , aLangId     in doc_document.pc_lang_id%type default null
  )
  is
    lExists boolean;
  begin
    lExists  := roundPositionAmount(aPositionId, aDateRef, aCurrencyId, aLangId);
  end roundPositionAmount;

  /**
  * procedure UpdatePosAmountsDiscountCharge
  *
  * Description : Màj des montants de la position après la création des remises/taxes
  *
  */
  procedure UpdatePosAmountsDiscountCharge(
    Pos_ID           DOC_POSITION.DOC_POSITION_ID%type
  , DateRef          DOC_DOCUMENT.DMT_DATE_VALUE%type
  , IncludeTaxTariff DOC_GAUGE_POSITION.GAP_INCLUDE_TAX_TARIFF%type
  , ChargeAmount     DOC_POSITION.POS_CHARGE_AMOUNT%type
  , DiscountAmount   DOC_POSITION.POS_DISCOUNT_AMOUNT%type
  )
  is
    vGrossValueExcl DOC_POSITION.POS_GROSS_VALUE%type;
    vGrossValueIncl DOC_POSITION.POS_GROSS_VALUE_INCL%type;
    vTaxCode        DOC_POSITION.ACS_TAX_CODE_ID%type;
    vDateDelivery   DOC_POSITION.POS_DATE_DELIVERY%type;
    vNetValueExcl   DOC_POSITION.POS_NET_VALUE_EXCL%type;
    vNetValueIncl   DOC_POSITION.POS_NET_VALUE_INCL%type;
    vVatAmount      DOC_POSITION.POS_VAT_AMOUNT%type;
  begin
    select POS.POS_GROSS_VALUE
         , POS.POS_GROSS_VALUE_INCL
         , POS.ACS_TAX_CODE_ID
         , POS.POS_DATE_DELIVERY
      into vGrossValueExcl
         , vGrossValueIncl
         , vTaxCode
         , vDateDelivery
      from DOC_POSITION POS
     where DOC_POSITION_ID = Pos_ID;

    if IncludeTaxTariff = 1 then   -- TTC
      vNetValueIncl  := vGrossValueIncl + ChargeAmount - DiscountAmount;
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => vTaxCode
                               , aRefDate         => nvl(vDateDelivery, DateRef)
                               , aIncludedVat     => 'I'
                               , aRoundAmount     => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                    , '0') )
                               , aNetAmountExcl   => vNetValueExcl
                               , aNetAmountIncl   => vNetValueIncl
                               , aVatAmount       => vVatAmount
                                );

      update DOC_POSITION
         set POS_CHARGE_AMOUNT = ChargeAmount
           , POS_DISCOUNT_AMOUNT = DiscountAmount
           , POS_NET_VALUE_INCL = POS_GROSS_VALUE_INCL + ChargeAmount - DiscountAmount
           , POS_NET_UNIT_VALUE_INCL = (POS_GROSS_VALUE_INCL + ChargeAmount - DiscountAmount) / decode(POS_BASIS_QUANTITY, 0, 1, POS_BASIS_QUANTITY)
           , POS_NET_VALUE_EXCL = vNetValueExcl
           , POS_NET_UNIT_VALUE = vNetValueExcl / decode(POS_BASIS_QUANTITY, 0, 1, POS_BASIS_QUANTITY)
           , POS_VAT_AMOUNT = vVatAmount
           , POS_RECALC_AMOUNTS = 0
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_POSITION_ID = Pos_ID;
    else   -- HT
      vNetValueExcl  := vGrossValueExcl + ChargeAmount - DiscountAmount;
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => vTaxCode
                               , aRefDate         => nvl(vDateDelivery, DateRef)
                               , aIncludedVat     => 'E'
                               , aRoundAmount     => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                    , '0') )
                               , aNetAmountExcl   => vNetValueExcl
                               , aNetAmountIncl   => vNetValueIncl
                               , aVatAmount       => vVatAmount
                                );

      update DOC_POSITION
         set POS_CHARGE_AMOUNT = ChargeAmount
           , POS_DISCOUNT_AMOUNT = DiscountAmount
           , POS_NET_VALUE_EXCL = POS_GROSS_VALUE + ChargeAmount - DiscountAmount
           , POS_NET_UNIT_VALUE = (POS_GROSS_VALUE + ChargeAmount - DiscountAmount) / decode(POS_BASIS_QUANTITY, 0, 1, POS_BASIS_QUANTITY)
           , POS_NET_VALUE_INCL = vNetValueIncl
           , POS_NET_UNIT_VALUE_INCL = vNetValueIncl / decode(POS_BASIS_QUANTITY, 0, 1, POS_BASIS_QUANTITY)
           , POS_VAT_AMOUNT = vVatAmount
           , POS_RECALC_AMOUNTS = 0
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_POSITION_ID = Pos_ID;
    end if;

    -- Mise à jour des montants de budget qui dépendent du montant net
    DOC_BUDGET_FUNCTIONS.UpdatePosBudgetAmounts(Pos_ID);
    -- Maj des prix des mouvements sur les détails de position
    DOC_FUNCTIONS.PosUpdateDetailMovementPrice(Pos_ID);
  end UpdatePosAmountsDiscountCharge;

  /**
  * Description  : création des remises et taxes de marge matières précieuses
  */
  procedure CreatePreciousMatMargin(
    aPositionId       in     doc_position.doc_position_id%type
  , aPreciousGoodId   in     gco_good.gco_good_id%type
  , aLiabledAmount    in     doc_position_charge.pch_liabled_amount%type
  , aDescription      in     doc_position_charge.pch_description%type
  , aDateref          in     date
  , aQuantityref      in     doc_position.pos_basis_quantity%type
  , aCurrencyId       in     acs_financial_currency.acs_financial_currency_id%type
  , aRateOfExchange   in     doc_document.dmt_rate_of_exchange%type
  , aBasePrice        in     doc_document.dmt_base_price%type
  , aLangId           in     doc_document.pc_lang_id%type
  , aChargeNameList   in     varchar2
  , aDiscountNameList in     varchar2
  , aChargeAmount     out    doc_position.pos_charge_amount%type
  , aDiscountAmount   out    doc_position.pos_discount_amount%type
  )
  is
    cursor crDiscountCharge(cChargeList varchar2, cDiscountList varchar2, cLangId number)
    is
      select   DNT.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(DID_DESCR, DNT_NAME) DESCR
             , DNT_NAME PTC_NAME
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , cast(null as varchar2(4000) ) SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE CHARGE_TYPE
             , DNT_EXCLUSIVE EXCLUSIF
             , DNT_PRCS_USE PRCS_USE
          from PTC_DISCOUNT DNT
             , PTC_DISCOUNT_DESCR DID
             , (select column_value as PTC_DISCOUNT_ID
                  from table(PCS.idListToTable(cDiscountList) ) ) DNT_LST
         where DNT.PTC_DISCOUNT_ID = DNT_LST.PTC_DISCOUNT_ID
           and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
           and DID.PC_LANG_ID(+) = cLangId
      union
      select   0 PTC_DISCOUNT_ID
             , CRG.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(CHD_DESCR, CRG_NAME) DESCR
             , CRG_NAME PTC_NAME
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE CHARGE_TYPE
             , CRG_EXCLUSIVE EXCLUSIF
             , CRG_PRCS_USE PRCS_USE
          from PTC_CHARGE CRG
             , PTC_CHARGE_DESCRIPTION CHD
             , (select column_value as PTC_CHARGE_ID
                  from table(PCS.idListToTable(cChargeList) ) ) CRG_LST
         where CRG.PTC_CHARGE_ID = CRG_LST.PTC_CHARGE_ID
           and CRG.PTC_CHARGE_ID = CHD.PTC_CHARGE_ID(+)
           and CHD.PC_LANG_ID(+) = cLangId
      order by SERIES_CALC
             , PTC_NAME;

    tplPosition              doc_position%rowtype;
    vChargeType              PTC_CHARGE.C_CHARGE_TYPE%type;
    vAdminDomain             DOC_GAUGE.C_ADMIN_DOMAIN%type;
    vNumChanged              integer;
    vTempList                varchar2(32000);
    vChargeList              varchar2(32000);
    vDiscountList            varchar2(32000);
    vPchAmount               DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vLiabledAmount           DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vCascadeAmount           DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vUnitLiabledAmount       DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vFinancialId             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivisionId              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCpnID                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCdaID                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPfID                    ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPjID                    ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vBlnFound                number(1);
    vGestValueQuantity       DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    vQuantity                DOC_POSITION.POS_FINAL_QUANTITY%type;
    vFinancial               DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical              DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl               DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vAccountInfo             ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vExclusiveDiscountId     PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    vExclusiveDiscountAmount DOC_POSITION.POS_DISCOUNT_AMOUNT%type            default 0;
    vExclusiveChargeId       PTC_CHARGE.PTC_CHARGE_ID%type;
    vExclusiveChargeAmount   DOC_POSITION.POS_CHARGE_AMOUNT%type              default 0;
  begin
    aChargeAmount    := 0;
    aDiscountAmount  := 0;

    -- pointeur sur la position a traîter
    select *
      into tplPosition
      from doc_position
     where doc_position_id = aPositionId;

    -- recherche d'info dans le gabarit
    select decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
         , C_ADMIN_DOMAIN
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
         , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
      into vChargeType
         , vAdminDomain
         , vFinancial
         , vAnalytical
         , vInfoCompl
      from doc_gauge GAU
         , doc_gauge_structured GAS
     where GAU.doc_gauge_id = tplPosition.doc_gauge_id
       and GAS.doc_gauge_id = GAU.doc_gauge_id;

    -- recherche des remises/taxes
    PTC_FIND_DISCOUNT_CHARGE.TESTPMMDISCOUNTCHARGE(nvl(tplPosition.DOC_GAUGE_ID, 0)
                                                 , nvl(nvl(tplPosition.PAC_THIRD_TARIFF_ID, tplPosition.PAC_THIRD_ID), 0)
                                                 , nvl(tplPosition.DOC_RECORD_ID, 0)
                                                 , nvl(aPreciousGoodId, 0)
                                                 , vChargeType
                                                 , aDateRef
                                                 , vNumChanged   -- vBlnDiscount
                                                  );

    -- Utiliser la liste des taxes passées en param si renseignée
    if aChargeNameList is not null then
      -- Macro [NOT_USED] pour indiquer que les taxes ne doivent pas être crées
      if aChargeNameList = '[NOT_USED]' then
        vChargeList  := null;
      else
        vChargeList  := ',';

        -- Convertir la liste des noms de taxes en liste d'ids
        for ltplCrg in (select PTC_CHARGE_ID
                          from PTC_CHARGE
                         where instr(';' || aChargeNameList || ';', ';' || CRG_NAME || ';') > 0) loop
          vChargeList  := vChargeList || ltplCrg.PTC_CHARGE_ID || ',';
        end loop;
      end if;
    else
      -- récupération de la liste des taxes
      vTempList    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'PMM');
      vChargeList  := vTempList;

      while length(vTempList) > 1987 loop
        vTempList    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'PMM');
        vChargeList  := vChargeList || vTempList;
      end loop;
    end if;

    -- Utiliser la liste des taxes passées en param si renseignée
    if aDiscountNameList is not null then
      -- Macro [NOT_USED] pour indiquer que les remises ne doivent pas être crées
      if aDiscountNameList = '[NOT_USED]' then
        vDiscountList  := null;
      else
        vDiscountList  := ',';

        -- Convertir la liste des noms de remises en liste d'ids
        for lptlDnt in (select PTC_DISCOUNT_ID
                          from PTC_DISCOUNT
                         where instr(';' || aDiscountNameList || ';', ';' || DNT_NAME || ';') > 0) loop
          vDiscountList  := vDiscountList || lptlDnt.PTC_DISCOUNT_ID || ',';
        end loop;
      end if;
    else
      -- récupération de la liste des remises
      vTempList      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'PMM');
      vDiscountList  := vTempList;

      while length(vTempList) > 1987 loop
        vTempList      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'PMM');
        vDiscountList  := vDiscountList || vTempList;
      end loop;
    end if;

    -- recherche du montant soumis en fonction du type de position (HT ou TTC)
    vLiabledAmount   := aLiabledAmount;
    vCascadeAmount   := aLiabledAmount;

    if nvl(aQuantityRef, 0) = 0 then
      vUnitLiabledAmount  := aLiabledAmount;
    else
      vUnitLiabledAmount  := aLiabledAmount / aQuantityRef;
    end if;

    -- ouverture d'un query sur les infos des remises/taxes
    for tplDiscountCharge in crDiscountCharge(vChargeList, vDiscountList, aLangid) loop
      -- Remises/taxes cascade
      if tplDiscountCharge.SERIES_CALC = 1 then
        vLiabledAmount  := vCascadeAmount;
      end if;

      -- traitement des taxes
      if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
        PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   -- Id de la taxe à calculer
                               , tplDiscountCharge.descr   -- Nom de la taxe
                               , vUnitLiabledAmount   -- Montant unitaire soumis à la taxe en monnaie document
                               , vLiabledAmount   -- Montant soumis à la taxe en monnaie document
                               , vLiabledAmount   -- Montant soumis à la taxe en monnaie document
                               , aQuantityRef   -- Pour les taxes de type détail, quantité de la position
                               , aQuantityRef   -- quantité de référence pour les tests d'applicabilité
                               , aPreciousGoodId   -- Identifiant du bien
                               , nvl(tplPosition.PAC_THIRD_TARIFF_ID, tplPosition.PAC_THIRD_ID)   -- Identifiant du tiers tarification
                               , tplPosition.DOC_POSITION_ID   -- Identifiant de la position pour les taxes détaillées de type 8 (plsql)
                               , null   -- Identifiant du document pour les taxes de type total de type 8 (plsql)
                               , aCurrencyId   -- Id de la monnaie du montant soumis
                               , aRateOfExchange   -- Taux de change
                               , aBasePrice   -- Diviseur
                               , aDateRef   -- Date de référence
                               , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                               , tplDiscountCharge.rate   -- Taux
                               , tplDiscountCharge.fraction   -- Fraction
                               , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                               , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de remise)
                               , tplDiscountCharge.quantity_from   -- Quantité de
                               , tplDiscountCharge.quantity_to   -- Quantité a
                               , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                               , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                               , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                               , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                               , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                               , tplDiscountCharge.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                               , tplDiscountCharge.automatic_calc   -- Calculation auto ou à partir de sql_Extern_item
                               , tplDiscountCharge.sql_extern_item   -- Commande sql de recherche du montant soumis à la calculation
                               , tplDiscountCharge.c_round_type   -- Type d'arrondi
                               , tplDiscountCharge.round_amount   -- Montant d'arrondi
                               , tplDiscountCharge.unit_detail   -- Détail unitaire
                               , tplDiscountCharge.original   -- Origine de la taxe (1 = création, 0 = modification)
                               , 0   -- taxe de position simple obligatoirement non cumulative
                               , vPchAmount   -- Montant de la taxe
                               , vBlnFound   -- Taxe trouvée
                                );

        -- Si gestion des comptes financiers ou analytiques
        if     (vBlnFound = 1)
           and (    (vFinancial = 1)
                or (vAnalytical = 1) ) then
          -- Utilise les comptes de la taxe
          vFinancialID                        := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
          vDivisionID                         := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
          vCpnId                              := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
          vCdaId                              := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
          vPfId                               := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
          vPjId                               := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
          vAccountInfo.DEF_HRM_PERSON         := null;
          vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
          vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
          vAccountInfo.DEF_DIC_IMP_FREE1      := null;
          vAccountInfo.DEF_DIC_IMP_FREE2      := null;
          vAccountInfo.DEF_DIC_IMP_FREE3      := null;
          vAccountInfo.DEF_DIC_IMP_FREE4      := null;
          vAccountInfo.DEF_DIC_IMP_FREE5      := null;
          vAccountInfo.DEF_TEXT1              := null;
          vAccountInfo.DEF_TEXT2              := null;
          vAccountInfo.DEF_TEXT3              := null;
          vAccountInfo.DEF_TEXT4              := null;
          vAccountInfo.DEF_TEXT5              := null;
          vAccountInfo.DEF_NUMBER1            := null;
          vAccountInfo.DEF_NUMBER2            := null;
          vAccountInfo.DEF_NUMBER3            := null;
          vAccountInfo.DEF_NUMBER4            := null;
          vAccountInfo.DEF_NUMBER5            := null;
          vAccountInfo.DEF_DATE1              := null;
          vAccountInfo.DEF_DATE2              := null;
          vAccountInfo.DEF_DATE3              := null;
          vAccountInfo.DEF_DATE4              := null;
          vAccountInfo.DEF_DATE5              := null;
          -- recherche des comptes
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_CHARGE_ID
                                                   , '30'
                                                   , vAdminDomain
                                                   , aDateRef
                                                   , tplPosition.DOC_GAUGE_ID
                                                   , tplPosition.DOC_DOCUMENT_ID
                                                   , aPositionId
                                                   , tplPosition.DOC_RECORD_ID
                                                   , tplPosition.PAC_THIRD_ACI_ID
                                                   , tplPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                   , tplPosition.ACS_DIVISION_ACCOUNT_ID
                                                   , tplPosition.ACS_CPN_ACCOUNT_ID
                                                   , tplPosition.ACS_CDA_ACCOUNT_ID
                                                   , tplPosition.ACS_PF_ACCOUNT_ID
                                                   , tplPosition.ACS_PJ_ACCOUNT_ID
                                                   , vFinancialId
                                                   , vDivisionId
                                                   , vCpnId
                                                   , vCdaId
                                                   , vPfId
                                                   , vPjId
                                                   , vAccountInfo
                                                    );

          if (vAnalytical = 0) then
            vCpnID  := null;
            vCdaID  := null;
            vPjID   := null;
            vPfID   := null;
          end if;
        end if;
      -- traitement des remises
      else
        PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   -- Id de la remise à calculer
                                 , vUnitLiabledAmount   -- Montant unitaire soumis à la remise en monnaie document
                                 , vLiabledAmount   -- Montant soumis à la remise en monnaie document
                                 , vLiabledAmount   -- Montant soumis à la remise en monnaie document
                                 , vQuantity   -- Pour les remises de type détail, quantité de la position
                                 , aQuantityRef   -- quantité de référence pour les tests d'applicabilité
                                 , tplPosition.DOC_POSITION_ID   -- Identifiant de la position pour les remises détaillées de type 8 (plsql)
                                 , null   -- Identifiant du document pour les remises de type total de type 8 (plsql)
                                 , aCurrencyId   -- Id de la monnaie du montant soumis
                                 , aRateOfExchange   -- Taux de change
                                 , aBasePrice   -- Diviseur
                                 , aDateRef   -- Date de référence
                                 , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                 , tplDiscountCharge.rate   -- Taux
                                 , tplDiscountCharge.fraction   -- Fraction
                                 , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                 , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de taxe)
                                 , tplDiscountCharge.quantity_from   -- Quantité de
                                 , tplDiscountCharge.quantity_to   -- Quantité a
                                 , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                 , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                 , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                 , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                 , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                 , tplDiscountCharge.is_multiplicator   -- Pour le montant fixe, multiplier par quantité ?
                                 , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                 , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                 , tplDiscountCharge.unit_detail   -- Détail unitaire
                                 , tplDiscountCharge.original   -- Origine de la remise (1 = création, 0 = modification)
                                 , 0   -- remise de position simple obligatoirement non cumulative
                                 , vPchAmount   -- Montant de la remise
                                 , vBlnFound   -- Remise trouvée
                                  );

        -- Si gestion des comptes financiers ou analytiques
        if     (vBlnFound = 1)
           and (    (vFinancial = 1)
                or (vAnalytical = 1) ) then
          -- Utilise les comptes de la remise
          vFinancialId                        := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
          vDivisionId                         := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
          vCpnId                              := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
          vCdaId                              := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
          vPfId                               := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
          vPjId                               := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
          vAccountInfo.DEF_HRM_PERSON         := null;
          vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
          vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
          vAccountInfo.DEF_DIC_IMP_FREE1      := null;
          vAccountInfo.DEF_DIC_IMP_FREE2      := null;
          vAccountInfo.DEF_DIC_IMP_FREE3      := null;
          vAccountInfo.DEF_DIC_IMP_FREE4      := null;
          vAccountInfo.DEF_DIC_IMP_FREE5      := null;
          vAccountInfo.DEF_TEXT1              := null;
          vAccountInfo.DEF_TEXT2              := null;
          vAccountInfo.DEF_TEXT3              := null;
          vAccountInfo.DEF_TEXT4              := null;
          vAccountInfo.DEF_TEXT5              := null;
          vAccountInfo.DEF_NUMBER1            := null;
          vAccountInfo.DEF_NUMBER2            := null;
          vAccountInfo.DEF_NUMBER3            := null;
          vAccountInfo.DEF_NUMBER4            := null;
          vAccountInfo.DEF_NUMBER5            := null;
          vAccountInfo.DEF_DATE1              := null;
          vAccountInfo.DEF_DATE2              := null;
          vAccountInfo.DEF_DATE3              := null;
          vAccountInfo.DEF_DATE4              := null;
          vAccountInfo.DEF_DATE5              := null;
          -- recherche des comptes
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_DISCOUNT_ID
                                                   , '20'
                                                   , vAdminDomain
                                                   , aDateRef
                                                   , tplPosition.DOC_GAUGE_ID
                                                   , tplPosition.DOC_DOCUMENT_ID
                                                   , aPositionId
                                                   , tplPosition.DOC_RECORD_ID
                                                   , tplPosition.PAC_THIRD_ACI_ID
                                                   , tplPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                   , tplPosition.ACS_DIVISION_ACCOUNT_ID
                                                   , tplPosition.ACS_CPN_ACCOUNT_ID
                                                   , tplPosition.ACS_CDA_ACCOUNT_ID
                                                   , tplPosition.ACS_PF_ACCOUNT_ID
                                                   , tplPosition.ACS_PJ_ACCOUNT_ID
                                                   , vFinancialID
                                                   , vDivisionId
                                                   , vCpnId
                                                   , vCdaId
                                                   , vPfId
                                                   , vPjId
                                                   , vAccountInfo
                                                    );

          if (vAnalytical = 0) then
            vCpnID  := null;
            vCdaID  := null;
            vPjID   := null;
            vPfID   := null;
          end if;
        end if;
      end if;

      -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
      if vBlnFound = 1 then
        -- création de la remise/taxe
        insert into DOC_POSITION_CHARGE
                    (DOC_POSITION_CHARGE_ID
                   , DOC_POSITION_ID
                   , C_CHARGE_ORIGIN
                   , C_FINANCIAL_CHARGE
                   , PCH_NAME
                   , PCH_DESCRIPTION
                   , PCH_AMOUNT
                   , PCH_BALANCE_AMOUNT
                   , PCH_CALC_AMOUNT
                   , PCH_LIABLED_AMOUNT
                   , PCH_FIXED_AMOUNT_B
                   , PCH_EXCEEDED_AMOUNT_FROM
                   , PCH_EXCEEDED_AMOUNT_TO
                   , PCH_MIN_AMOUNT
                   , PCH_MAX_AMOUNT
                   , PCH_QUANTITY_FROM
                   , PCH_QUANTITY_TO
                   , C_ROUND_TYPE
                   , PCH_ROUND_AMOUNT
                   , C_CALCULATION_MODE
                   , PCH_TRANSFERT_PROP
                   , PCH_MODIFY
                   , PCH_UNIT_DETAIL
                   , PCH_IN_SERIES_CALCULATION
                   , PCH_AUTOMATIC_CALC
                   , PCH_IS_MULTIPLICATOR
                   , PCH_EXCLUSIVE
                   , PCH_STORED_PROC
                   , PCH_SQL_EXTERN_ITEM
                   , PTC_DISCOUNT_ID
                   , PTC_CHARGE_ID
                   , PCH_RATE
                   , PCH_EXPRESS_IN
                   , PCH_CUMULATIVE
                   , PCH_DISCHARGED
                   , PCH_PRCS_USE
                   , DOC_DOC_POSITION_CHARGE_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACS_PJ_ACCOUNT_ID
                   , HRM_PERSON_ID
                   , FAM_FIXED_ASSETS_ID
                   , C_FAM_TRANSACTION_TYP
                   , PCH_IMP_TEXT_1
                   , PCH_IMP_TEXT_2
                   , PCH_IMP_TEXT_3
                   , PCH_IMP_TEXT_4
                   , PCH_IMP_TEXT_5
                   , PCH_IMP_NUMBER_1
                   , PCH_IMP_NUMBER_2
                   , PCH_IMP_NUMBER_3
                   , PCH_IMP_NUMBER_4
                   , PCH_IMP_NUMBER_5
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , PCH_IMP_DATE_1
                   , PCH_IMP_DATE_2
                   , PCH_IMP_DATE_3
                   , PCH_IMP_DATE_4
                   , PCH_IMP_DATE_5
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (init_id_seq.nextval
                   , tplPosition.DOC_POSITION_ID
                   , 'PMM'
                   , decode(tplDiscountCharge.PTC_CHARGE_ID, 0, '02', '03')
                   , tplDiscountCharge.PTC_NAME
                   , tplDiscountCharge.Descr || ' - ' || aDescription
                   , vPchAmount
                   , vPchAmount
                   , vPchAmount
                   , vLiabledAmount
                   , tplDiscountCharge.FIXED_AMOUNT_B
                   , tplDiscountCharge.EXCEEDED_AMOUNT_FROM
                   , tplDiscountCharge.EXCEEDED_AMOUNT_TO
                   , tplDiscountCharge.MIN_AMOUNT
                   , tplDiscountCharge.MAX_AMOUNT
                   , tplDiscountCharge.QUANTITY_FROM
                   , tplDiscountCharge.QUANTITY_TO
                   , tplDiscountCharge.C_ROUND_TYPE
                   , tplDiscountCharge.ROUND_AMOUNT
                   , tplDiscountCharge.C_CALCULATION_MODE
                   , tplDiscountCharge.TRANSFERT_PROP
                   , tplDiscountCharge.MODIF
                   , tplDiscountCharge.UNIT_DETAIL
                   , tplDiscountCharge.IN_SERIES_CALCULATION
                   , tplDiscountCharge.AUTOMATIC_CALC
                   , tplDiscountCharge.IS_MULTIPLICATOR
                   , tplDiscountCharge.EXCLUSIF
                   , tplDiscountCharge.STORED_PROC
                   , tplDiscountCharge.SQL_EXTERN_ITEM
                   , zvl(tplDiscountCharge.PTC_DISCOUNT_ID, null)
                   , zvl(tplDiscountCharge.PTC_CHARGE_ID, null)
                   , tplDiscountCharge.RATE
                   , tplDiscountCharge.FRACTION
                   , 0   -- remise/taxe non cumulée
                   , 0   -- ne provenant de décharge
                   , tplDiscountCharge.PRCS_USE
                   , null
                   , vFinancialId
                   , vDivisionId
                   , vCpnId
                   , vCdaId
                   , vPfId
                   , vPjId
                   , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                   , vAccountInfo.FAM_FIXED_ASSETS_ID
                   , vAccountInfo.C_FAM_TRANSACTION_TYP
                   , vAccountInfo.DEF_TEXT1
                   , vAccountInfo.DEF_TEXT2
                   , vAccountInfo.DEF_TEXT3
                   , vAccountInfo.DEF_TEXT4
                   , vAccountInfo.DEF_TEXT5
                   , to_number(vAccountInfo.DEF_NUMBER1)
                   , to_number(vAccountInfo.DEF_NUMBER2)
                   , to_number(vAccountInfo.DEF_NUMBER3)
                   , to_number(vAccountInfo.DEF_NUMBER4)
                   , to_number(vAccountInfo.DEF_NUMBER5)
                   , vAccountInfo.DEF_DIC_IMP_FREE1
                   , vAccountInfo.DEF_DIC_IMP_FREE2
                   , vAccountInfo.DEF_DIC_IMP_FREE3
                   , vAccountInfo.DEF_DIC_IMP_FREE4
                   , vAccountInfo.DEF_DIC_IMP_FREE5
                   , vAccountInfo.DEF_DATE1
                   , vAccountInfo.DEF_DATE2
                   , vAccountInfo.DEF_DATE3
                   , vAccountInfo.DEF_DATE4
                   , vAccountInfo.DEF_DATE5
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        select aChargeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, 0, vPchAmount)
          into aChargeAmount
          from dual;

        select aDiscountAmount + decode(tplDiscountCharge.PTC_DISCOUNT_ID, 0, 0, vPchAmount)
          into aDiscountAmount
          from dual;

        select vCascadeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, -vPchAmount, vPchAmount)
          into vCascadeAmount
          from dual;

        if     tplDiscountCharge.PTC_DISCOUNT_ID <> 0
           and tplDiscountCharge.EXCLUSIF = 1
           and (   abs(vPchAmount) > abs(vExclusiveDiscountAmount)
                or vExclusiveDiscountId is null) then
          vExclusiveDiscountAmount  := vPchAmount;

          select init_id_seq.currval
            into vExclusiveDiscountId
            from dual;
        end if;

        if     tplDiscountCharge.PTC_CHARGE_ID <> 0
           and tplDiscountCharge.EXCLUSIF = 1
           and (   abs(vPchAmount) > abs(vExclusiveChargeAmount)
                or vExclusiveChargeId is null) then
          vExclusiveChargeAmount  := vPchAmount;

          select init_id_seq.currval
            into vExclusiveChargeId
            from dual;
        end if;
      end if;
    end loop;

    -- Si on a des remises exclusives, effacement des remises différentes de la plus grande remise exclusive
    if vExclusiveDiscountId is not null then
      delete from DOC_POSITION_CHARGE
            where DOC_POSITION_CHARGE_ID <> vExclusiveDiscountId
              and PTC_DISCOUNT_ID is not null
              and DOC_POSITION_ID = aPositionId
              and C_CHARGE_ORIGIN = 'PMM';

      aDiscountAmount  := vExclusiveDiscountAmount;
    end if;

    -- Si on a des taxes exclusives, effacement des taxes différentes de la plus grande taxe exclusive
    if vExclusiveChargeId is not null then
      delete from DOC_POSITION_CHARGE
            where DOC_POSITION_CHARGE_ID <> vExclusiveChargeId
              and PTC_CHARGE_ID is not null
              and DOC_POSITION_ID = aPositionId
              and C_CHARGE_ORIGIN = 'PMM';

      aChargeAmount  := vExclusiveChargeAmount;
    end if;
  end;

  /**
  * Description
  *   création d'une remise/taxe de position
  *   si l'id n'est pas renseigné, la procédure le renseigne automatiquement
  *   les champs A_DATECRE et A_IDCRE sont renseignés automatiquement
  */
  procedure InsertPositionCharge(aRecPositionCharge in out DOC_POSITION_CHARGE%rowtype)
  is
  begin
    -- initialisation de la taxe qui n'auraient pas été données par l'utilisateur
    -- Attention PCH_EXCEEDED_AMOUNT_FROM , a revoir dans le cas de monnaie différente [ou de transfert proportionnel partiel]
    select nvl(aRecPositionCharge.DOC_POSITION_CHARGE_ID, init_id_seq.nextval)
         , nvl(aRecPositionCharge.C_CHARGE_ORIGIN, 'MAN')
         , nvl(aRecPositionCharge.PCH_BALANCE_AMOUNT, aRecPositionCharge.PCH_AMOUNT)
         , nvl(aRecPositionCharge.PCH_CALC_AMOUNT, aRecPositionCharge.PCH_AMOUNT)
         , nvl(aRecPositionCharge.PCH_LIABLED_AMOUNT, 0)
         , nvl(aRecPositionCharge.PCH_FIXED_AMOUNT_B, 0)
         , nvl(aRecPositionCharge.PCH_EXCEEDED_AMOUNT_FROM, 0)
         , nvl(aRecPositionCharge.PCH_EXCEEDED_AMOUNT_TO, 0)
         , nvl(aRecPositionCharge.PCH_MIN_AMOUNT, 0)
         , nvl(aRecPositionCharge.PCH_MAX_AMOUNT, 0)
         , nvl(aRecPositionCharge.PCH_QUANTITY_FROM, 0)
         , nvl(aRecPositionCharge.PCH_QUANTITY_TO, 0)
         , nvl(aRecPositionCharge.C_ROUND_TYPE, '0')
         , nvl(aRecPositionCharge.PCH_ROUND_AMOUNT, 0)
         , nvl(aRecPositionCharge.PCH_TRANSFERT_PROP, 0)
         , nvl(aRecPositionCharge.PCH_MODIFY, 0)
         , nvl(aRecPositionCharge.PCH_UNIT_DETAIL, 0)
         , nvl(aRecPositionCharge.PCH_AUTOMATIC_CALC, 1)
         , nvl(aRecPositionCharge.PCH_IS_MULTIPLICATOR, 0)
         , nvl(aRecPositionCharge.PCH_EXCLUSIVE, 0)
         , nvl(aRecPositionCharge.PCH_RATE, 0)
         , nvl(aRecPositionCharge.PCH_EXPRESS_IN, 0)
         , nvl(aRecPositionCharge.PCH_CUMULATIVE, 0)
         , nvl(aRecPositionCharge.PCH_DISCHARGED, 0)
         , nvl(aRecPositionCharge.A_DATECRE, sysdate)
         , nvl(aRecPositionCharge.A_IDCRE, PCS.PC_I_LIB_SESSION.GetUserIni)
      into aRecPositionCharge.DOC_POSITION_CHARGE_ID
         , aRecPositionCharge.C_CHARGE_ORIGIN
         , aRecPositionCharge.PCH_BALANCE_AMOUNT
         , aRecPositionCharge.PCH_CALC_AMOUNT
         , aRecPositionCharge.PCH_LIABLED_AMOUNT
         , aRecPositionCharge.PCH_FIXED_AMOUNT_B
         , aRecPositionCharge.PCH_EXCEEDED_AMOUNT_FROM
         , aRecPositionCharge.PCH_EXCEEDED_AMOUNT_TO
         , aRecPositionCharge.PCH_MIN_AMOUNT
         , aRecPositionCharge.PCH_MAX_AMOUNT
         , aRecPositionCharge.PCH_QUANTITY_FROM
         , aRecPositionCharge.PCH_QUANTITY_TO
         , aRecPositionCharge.C_ROUND_TYPE
         , aRecPositionCharge.PCH_ROUND_AMOUNT
         , aRecPositionCharge.PCH_TRANSFERT_PROP
         , aRecPositionCharge.PCH_MODIFY
         , aRecPositionCharge.PCH_UNIT_DETAIL
         , aRecPositionCharge.PCH_AUTOMATIC_CALC
         , aRecPositionCharge.PCH_IS_MULTIPLICATOR
         , aRecPositionCharge.PCH_EXCLUSIVE
         , aRecPositionCharge.PCH_RATE
         , aRecPositionCharge.PCH_EXPRESS_IN
         , aRecPositionCharge.PCH_CUMULATIVE
         , aRecPositionCharge.PCH_DISCHARGED
         , aRecPositionCharge.A_DATECRE
         , aRecPositionCharge.A_IDCRE
      from dual;

    -- création de la remise/taxe
    insert into DOC_POSITION_CHARGE
         values aRecPositionCharge;
  end InsertPositionCharge;

--------------------------------------------------------------------------------------------------------------------------
  /**
  * Description  : création des remises et taxes de pied
  */
  procedure CreateFootCharge(
    document_id      in     doc_document.doc_document_id%type
  , dateref          in     date
  , currency_id      in     acs_financial_currency.acs_financial_currency_id%type
  , rate_of_exchange in     doc_document.dmt_rate_of_exchange%type
  , base_price       in     doc_document.dmt_base_price%type
  , lang_id          in     doc_document.pc_lang_id%type
  , created          out    numBoolean
  )
  is
    tplFoot                 doc_foot%rowtype;
    is_already_charges      number(1);
    charge_type             PTC_CHARGE.C_CHARGE_TYPE%type;
    admin_domain            DOC_GAUGE.C_ADMIN_DOMAIN%type;
    numchanged              integer;
    templist                varchar2(20000);
    chargelist              varchar2(20000);
    discountlist            varchar2(20000);
    fchAmount               DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    liabledAmount           DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    CascadeAmount           DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    FinancialID             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    DivisionID              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CpnID                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CdaID                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PfID                    ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PjID                    ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    blnCharge               number(1);
    blnDiscount             number(1);
    gauge_id                DOC_GAUGE.DOC_GAUGE_ID%type;
    record_id               DOC_RECORD.DOC_RECORD_ID%type;

    cursor crDiscountCharge(astrChargeList varchar2, astrDiscountList varchar2, lang_id number)
    is
      select   1 FCH_TO_CREATE
             , cast(null as number(12) ) DOC_FOOT_CHARGE_ID
             , dnt.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(DID.DID_DESCR, DNT_NAME) DESCR
             , DNT_NAME PTC_NAME
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , cast(null as varchar2(4000) ) SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE CHARGE_TYPE
             , DNT_EXCLUSIVE EXCLUSIF
             , cast(null as number(12) ) ACS_TAX_CODE_ID
             , cast(null as number(12) ) FCH_EXCL_AMOUNT
          from PTC_DISCOUNT dnt
             , PTC_DISCOUNT_DESCR did
             , (select column_value as PTC_DISCOUNT_ID
                  from table(PCS.idListToTable(astrDiscountList) ) ) DNT_LST
         where DNT.PTC_DISCOUNT_ID = DNT_LST.PTC_DISCOUNT_ID
           and dnt.PTC_DISCOUNT_ID = did.PTC_DISCOUNT_ID(+)
           and did.PC_LANG_ID(+) = lang_id
      union
      select   1 FCH_TO_CREATE
             , cast(null as number(12) ) DOC_FOOT_CHARGE_ID
             , 0 PTC_DISCOUNT_ID
             , crg.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(CHD.CHD_DESCR, CRG_NAME) DESCR
             , CRG_NAME PTC_NAME
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE CHARGE_TYPE
             , CRG_EXCLUSIVE EXCLUSIF
             , cast(null as number(12) ) ACS_TAX_CODE_ID
             , cast(null as number(12) ) FCH_EXCL_AMOUNT
          from PTC_CHARGE crg
             , PTC_CHARGE_DESCRIPTION chd
             , (select column_value as PTC_CHARGE_ID
                  from table(PCS.idListToTable(astrChargeList) ) ) CRG_LST
         where CRG.PTC_CHARGE_ID = CRG_LST.PTC_CHARGE_ID
           and crg.PTC_CHARGE_ID = chd.PTC_CHARGE_ID(+)
           and chd.PC_LANG_ID(+) = lang_id
      union
      select   0 FCH_TO_CREATE
             , DOC_FOOT_CHARGE_ID
             , nvl(PTC_DISCOUNT_ID, 0) PTC_DISCOUNT_ID
             , nvl(PTC_CHARGE_ID, 0) PTC_CHARGE_ID
             , nvl(FCH_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , FCH_DESCRIPTION DESCR
             , FCH_NAME PTC_NAME
             , C_CALCULATION_MODE
             , FCH_RATE RATE
             , FCH_EXPRESS_IN FRACTION
             , FCH_FIXED_AMOUNT_B FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               FCH_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , FCH_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , FCH_MIN_AMOUNT MIN_AMOUNT
             , FCH_MAX_AMOUNT MAX_AMOUNT
             , 0 QUANTITY_FROM
             , 0 QUANTITY_TO
             , sysdate DATE_FROM
             , sysdate DATE_TO
             , FCH_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , FCH_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , FCH_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , FCH_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(FCH_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , FCH_TRANSFERT_PROP TRANSFERT_PROP
             , FCH_MODIFY MODIF
             , 0 UNIT_DETAIL
             , FCH_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , '' CHARGE_TYPE
             , FCH_EXCLUSIVE EXCLUSIF
             , ACS_TAX_CODE_ID
             , FCH_EXCL_AMOUNT
          from DOC_FOOT_CHARGE
         where DOC_FOOT_ID = document_id
           and DOC_FOOT_CHARGE_SRC_ID is not null
      order by SERIES_CALC
             , PTC_NAME;

    ChargeID                DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type;
    blnFound                number(1);
    TypeCharge              number(1);
    SubmissionType          DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
    MovementType            DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
    VatDetAccountId         DOC_DOCUMENT.ACS_VAT_DET_ACCOUNT_ID%type;
    VatAmount               DOC_FOOT_CHARGE.FCH_VAT_AMOUNT%type;
    TaxCodeId               ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    vFinancial              DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical             DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl              DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vAccountInfo            ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    exclusiveDiscountId     PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    exclusiveDiscountAmount DOC_POSITION.POS_DISCOUNT_AMOUNT%type             default 0;
    exclusiveChargeId       PTC_CHARGE.PTC_CHARGE_ID%type;
    exclusiveChargeAmount   DOC_POSITION.POS_CHARGE_AMOUNT%type               default 0;
    DmtDateValue            DOC_DOCUMENT.DMT_DATE_VALUE%type;
    DmtDateDelivery         DOC_DOCUMENT.DMT_DATE_DELIVERY%type;
    vFootCreated            boolean                                           default true;
    lTTC                    number(1);
  begin
    -- Détermine si le document est TTC ou HT
    lTTC     := DOC_FUNCTIONS.IsDocumentTTC(document_id);

    begin
      -- pointeur sur le pied de document a traîter
      select *
        into tplFoot
        from doc_foot
       where doc_foot_id = document_id;
    exception
      when no_data_found then
        vFootCreated  := false;
    end;

    created  := 0;

    if vFootCreated then
      -- contrôle qu'il n'y ait pas déjà de remises/taxes
      select count(*)
        into is_already_charges
        from DOC_FOOT_CHARGE
       where DOC_FOOT_ID = document_id
         and DOC_FOOT_CHARGE_SRC_ID is null
         and nvl(C_CHARGE_ORIGIN, 'MAN') not in('PM', 'PMM')
         and C_FINANCIAL_CHARGE in('02', '03');   -- exclu les frais

      -- si on a pas déjà de remises/taxes, on passe dans le processus de création
      if is_already_charges = 0 then
        -- recherch d'info dans le gabarit
        select decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
             , C_ADMIN_DOMAIN
             , GAS_CHARGE
             , GAS_DISCOUNT
             , DOC.DOC_GAUGE_ID
             , DOC.DOC_RECORD_ID
             , DOC.DIC_TYPE_SUBMISSION_ID
             , GAS.DIC_TYPE_MOVEMENT_ID
             , DOC.ACS_VAT_DET_ACCOUNT_ID
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
             , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
             , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
             , DOC.DMT_DATE_VALUE
             , DOC.DMT_DATE_DELIVERY
          into charge_type
             , admin_domain
             , blnCharge
             , blnDiscount
             , gauge_id
             , record_id
             , SubmissionType
             , MovementType
             , VatDetAccountId
             , vFinancial
             , vAnalytical
             , vInfoCompl
             , DmtDateValue
             , DmtDateDelivery
          from doc_document doc
             , doc_gauge GAU
             , doc_gauge_structured GAS
         where doc.doc_document_id = document_id
           and GAU.doc_gauge_id = DOC.doc_gauge_id
           and GAS.doc_gauge_id = GAU.doc_gauge_id;

        -- recherche des remises/taxes
        PTC_FIND_DISCOUNT_CHARGE.TESTTOTDISCOUNTCHARGE(nvl(gauge_id, 0)
                                                     , nvl(nvl(tplFoot.PAC_THIRD_TARIFF_ID, tplFoot.PAC_THIRD_ID), 0)
                                                     , nvl(record_id, 0)
                                                     , charge_type
                                                     , dateref
                                                     , blnCharge
                                                     ,   --blncharge
                                                       blnDiscount
                                                     ,   --blndiscount
                                                       numchanged
                                                      );
        -- récupération de la liste des taxes
        templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'TOT');
        chargelist    := templist;

        while length(templist) > 1987 loop
          templist    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'TOT');
          chargelist  := chargeList || templist;
        end loop;

        -- récupération de la liste des remises
        templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'TOT');
        discountlist  := templist;

        while length(templist) > 1987 loop
          templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'TOT');
          discountlist  := discountlist || templist;
        end loop;

        -- montant soumis
        select nvl(max(FOO_GOOD_TOT_AMOUNT_EXCL), 0)
             , nvl(max(FOO_GOOD_TOT_AMOUNT_EXCL), 0)
          into liabledamount
             , CascadeAmount
          from V_DOC_FOOT_POSITION
         where DOC_FOOT_ID = document_id;

        -- ouverture d'un query sur les infos des remises/taxes
        for tplDiscountCharge in crDiscountCharge(chargelist, discountlist, lang_id) loop
          -- Remises/taxes cascade
          if tplDiscountCharge.SERIES_CALC = 1 then
            LiabledAmount  := CascadeAmount;
          end if;

          if tplDiscountCharge.FCH_TO_CREATE = 1 then
            -- traitement des taxes
            if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
              PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   -- Id de la taxe à calculer
                                     , tplDiscountCharge.descr   -- Nom de la taxe
                                     , 0   -- Montant unitaire soumis à la taxe en monnaie document
                                     , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                     , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                     , 0   -- Pour les taxes de type détail, quantité de la position
                                     , null   -- Identifiant du bien
                                     , nvl(tplFoot.PAC_THIRD_TARIFF_ID, tplFoot.PAC_THIRD_ID)   -- Identifiant du tiers tarification
                                     , null   -- Identifiant de la position pour les taxes détaillées de type 8 (plsql)
                                     , document_id   -- Identifiant du document pour les taxes de type total de type 8 (plsql)
                                     , currency_id   -- Id de la monnaie du montant soumis
                                     , rate_of_exchange   -- Taux de change
                                     , base_price   -- Diviseur
                                     , dateref   -- Date de référence
                                     , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                     , tplDiscountCharge.rate   -- Taux
                                     , tplDiscountCharge.fraction   -- Fraction
                                     , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                     , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de remise)
                                     , 0   -- Quantité de
                                     , 0   -- Quantité a
                                     , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                     , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                     , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                     , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                     , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                     , 0   -- Pour le montant fixe, multiplier par quantité ?
                                     , tplDiscountCharge.automatic_calc   -- Calculation auto ou à partir de sql_Extern_item
                                     , tplDiscountCharge.sql_extern_item   -- Commande sql de recherche du montant soumis à la calculation
                                     , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                     , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                     , 0   -- Détail unitaire
                                     , tplDiscountCharge.original   -- Origine de la taxe (1 = création, 0 = modification)
                                     , 0   -- cumul à 0 pour les taxes de pied
                                     , fchAmount   -- Montant de la taxe
                                     , blnFound   -- Taxe trouvée
                                      );

              -- Si gestion des comptes financiers ou analytiques
              if     (blnFound = 1)
                 and (    (vFinancial = 1)
                      or (vAnalytical = 1) ) then
                -- Utilise les comptes de la taxe
                FinancialID                         := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                DivisionID                          := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                CpnId                               := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                CdaId                               := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                PfId                                := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                PjId                                := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                vAccountInfo.DEF_HRM_PERSON         := null;
                vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vAccountInfo.DEF_TEXT1              := null;
                vAccountInfo.DEF_TEXT2              := null;
                vAccountInfo.DEF_TEXT3              := null;
                vAccountInfo.DEF_TEXT4              := null;
                vAccountInfo.DEF_TEXT5              := null;
                vAccountInfo.DEF_NUMBER1            := null;
                vAccountInfo.DEF_NUMBER2            := null;
                vAccountInfo.DEF_NUMBER3            := null;
                vAccountInfo.DEF_NUMBER4            := null;
                vAccountInfo.DEF_NUMBER5            := null;
                vAccountInfo.DEF_DATE1              := null;
                vAccountInfo.DEF_DATE2              := null;
                vAccountInfo.DEF_DATE3              := null;
                vAccountInfo.DEF_DATE4              := null;
                vAccountInfo.DEF_DATE5              := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_CHARGE_ID
                                                         , '30'
                                                         , admin_domain
                                                         , DateRef
                                                         , gauge_id
                                                         , document_id
                                                         , null
                                                         , record_id
                                                         , tplFoot.PAC_THIRD_ACI_ID
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , FinancialID
                                                         , DivisionId
                                                         , CpnId
                                                         , CdaId
                                                         , PfId
                                                         , PjId
                                                         , vAccountInfo
                                                          );

                if (vAnalytical = 0) then
                  CpnID  := null;
                  CdaID  := null;
                  PjID   := null;
                  PfID   := null;
                end if;
              end if;

              typeCharge  := 4;
            -- traitement des remises
            else
              PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   -- Id de la remise à calculer
                                       , 0   -- Montant unitaire soumis à la remise en monnaie document
                                       , liabledAmount   -- Montant soumis à la remise en monnaie document
                                       , liabledAmount   -- Montant soumis à la remise en monnaie document
                                       , 0   -- Pour les remises de type détail, quantité de la position
                                       , null   -- Identifiant de la position pour les remises détaillées de type 8 (plsql)
                                       , document_id   -- Identifiant du document pour les remises de type total de type 8 (plsql)
                                       , currency_id   -- Id de la monnaie du montant soumis
                                       , rate_of_exchange   -- Taux de change
                                       , base_price   -- Diviseur
                                       , dateref   -- Date de référence
                                       , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                       , tplDiscountCharge.rate   -- Taux
                                       , tplDiscountCharge.fraction   -- Fraction
                                       , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                       , 0   -- Montant fixe en monnaie document (le montant fixe en monnaie document n'est pas utilisé en création de taxe(
                                       , 0   -- Quantité de
                                       , 0   -- Quantité a
                                       , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                       , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                       , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                       , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                       , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                       , 0   -- Pour le montant fixe, multiplier par quantité ?
                                       , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                       , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                       , 0   -- Détail unitaire
                                       , tplDiscountCharge.original   -- Origine de la remise (1 = création, 0 = modification)
                                       , 0   -- cumul à 0 pour les remises de pied
                                       , fchAmount   -- Montant de la remise
                                       , blnFound   -- Remise trouvée
                                        );

              -- Si gestion des comptes financiers ou analytiques
              -- Remise/taxe à créér = Oui
              if     (blnFound = 1)
                 and (    (vFinancial = 1)
                      or (vAnalytical = 1) ) then
                -- Utilise les comptes de la remise
                FinancialID                         := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                DivisionID                          := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                CpnId                               := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                CdaId                               := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                PfId                                := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                PjId                                := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                vAccountInfo.DEF_HRM_PERSON         := null;
                vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vAccountInfo.DEF_TEXT1              := null;
                vAccountInfo.DEF_TEXT2              := null;
                vAccountInfo.DEF_TEXT3              := null;
                vAccountInfo.DEF_TEXT4              := null;
                vAccountInfo.DEF_TEXT5              := null;
                vAccountInfo.DEF_NUMBER1            := null;
                vAccountInfo.DEF_NUMBER2            := null;
                vAccountInfo.DEF_NUMBER3            := null;
                vAccountInfo.DEF_NUMBER4            := null;
                vAccountInfo.DEF_NUMBER5            := null;
                vAccountInfo.DEF_DATE1              := null;
                vAccountInfo.DEF_DATE2              := null;
                vAccountInfo.DEF_DATE3              := null;
                vAccountInfo.DEF_DATE4              := null;
                vAccountInfo.DEF_DATE5              := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_DISCOUNT_ID
                                                         , '20'
                                                         , admin_domain
                                                         , DateRef
                                                         , gauge_id
                                                         , document_id
                                                         , null
                                                         , record_id
                                                         , tplFoot.PAC_THIRD_ACI_ID
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , FinancialID
                                                         , DivisionId
                                                         , CpnId
                                                         , CdaId
                                                         , PfId
                                                         , PjId
                                                         , vAccountInfo
                                                          );

                if (vAnalytical = 0) then
                  CpnID  := null;
                  CdaID  := null;
                  PjID   := null;
                  PfID   := null;
                end if;
              end if;

              typeCharge  := 3;
            end if;
          else
            -- FCH_TO_CREATE = 0
              -- Reprendre le code TVA de la charge source
            TaxCodeId  := tplDiscountCharge.ACS_TAX_CODE_ID;
            fchAmount  := tplDiscountCharge.FCH_EXCL_AMOUNT;
          end if;

          -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
          if blnFound = 1 then
            if (tplDiscountCharge.FCH_TO_CREATE = 1) then
              -- valeur de retour de la procedure indiquant qu'au moins une remise/taxe a été créée
              created    := 1;
              -- Recherche du code Taxe
              TaxCodeId  :=
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(TypeCharge
                                                      , tplFoot.PAC_THIRD_VAT_ID
                                                      , 0
                                                      , tplDiscountCharge.PTC_DISCOUNT_ID
                                                      , tplDiscountCharge.PTC_CHARGE_ID
                                                      , admin_domain
                                                      , SubmissionType
                                                      , MovementType
                                                      , VatDetAccountId
                                                       );
            end if;

            -- Garantit qu'aucun montant de remise/taxe soit à NULL pour évité une
            -- erreur EOracleError ORA-01400: cannot insert NULL into
            if fchAmount is null then
              fchAmount  := 0;
            end if;

            if LiabledAmount is null then
              LiabledAmount  := 0;
            end if;

            -- Calcul du montant TVA
            VatAmount  :=
              ACS_FUNCTION.CalcVatAmount(fchAmount
                                       , TaxCodeId
                                       , 'E'
                                       , nvl(DmtDateDelivery, DmtDateValue)
                                       , to_number(nvl(2 /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/, '0') )
                                        );

            if tplDiscountCharge.FCH_TO_CREATE = 1 then
              select INIT_ID_SEQ.nextval
                into ChargeID
                from dual;

              -- création de la remise/taxe
              insert into DOC_FOOT_CHARGE
                          (DOC_FOOT_CHARGE_ID
                         , DOC_FOOT_ID
                         , C_CHARGE_ORIGIN
                         , C_FINANCIAL_CHARGE
                         , FCH_NAME
                         , FCH_DESCRIPTION
                         , FCH_EXCL_AMOUNT
                         , FCH_INCL_AMOUNT
                         , FCH_BALANCE_AMOUNT
                         , FCH_CALC_AMOUNT
                         , FCH_LIABLED_AMOUNT
                         , FCH_FIXED_AMOUNT_B
                         , FCH_VAT_AMOUNT
                         , FCH_EXCEEDED_AMOUNT_FROM
                         , FCH_EXCEEDED_AMOUNT_TO
                         , FCH_MIN_AMOUNT
                         , FCH_MAX_AMOUNT
                         , C_ROUND_TYPE
                         , FCH_ROUND_AMOUNT
                         , C_CALCULATION_MODE
                         , FCH_TRANSFERT_PROP
                         , FCH_MODIFY
                         , FCH_IN_SERIES_CALCULATION
                         , FCH_AUTOMATIC_CALC
                         , FCH_IS_MULTIPLICATOR
                         , FCH_EXCLUSIVE
                         , FCH_STORED_PROC
                         , FCH_SQL_EXTERN_ITEM
                         , PTC_DISCOUNT_ID
                         , PTC_CHARGE_ID
                         , FCH_RATE
                         , FCH_EXPRESS_IN
                         , DOC_DOC_FOOT_CHARGE_ID
                         , ACS_TAX_CODE_ID
                         , ACS_FINANCIAL_ACCOUNT_ID
                         , ACS_DIVISION_ACCOUNT_ID
                         , ACS_CPN_ACCOUNT_ID
                         , ACS_CDA_ACCOUNT_ID
                         , ACS_PF_ACCOUNT_ID
                         , ACS_PJ_ACCOUNT_ID
                         , HRM_PERSON_ID
                         , FAM_FIXED_ASSETS_ID
                         , C_FAM_TRANSACTION_TYP
                         , FCH_IMP_TEXT_1
                         , FCH_IMP_TEXT_2
                         , FCH_IMP_TEXT_3
                         , FCH_IMP_TEXT_4
                         , FCH_IMP_TEXT_5
                         , FCH_IMP_NUMBER_1
                         , FCH_IMP_NUMBER_2
                         , FCH_IMP_NUMBER_3
                         , FCH_IMP_NUMBER_4
                         , FCH_IMP_NUMBER_5
                         , DIC_IMP_FREE1_ID
                         , DIC_IMP_FREE2_ID
                         , DIC_IMP_FREE3_ID
                         , DIC_IMP_FREE4_ID
                         , DIC_IMP_FREE5_ID
                         , FCH_IMP_DATE_1
                         , FCH_IMP_DATE_2
                         , FCH_IMP_DATE_3
                         , FCH_IMP_DATE_4
                         , FCH_IMP_DATE_5
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (ChargeID
                         , document_id
                         , 'AUTO'
                         , decode(tplDiscountCharge.PTC_CHARGE_ID, 0, '02', '03')
                         , tplDiscountCharge.PTC_NAME
                         , tplDiscountCharge.Descr
                         , decode(lTTC, 0, fchAmount, 1, fchAmount - VatAmount)
                         , decode(lTTC, 0, fchAmount + VatAmount, 1, fchAmount)
                         , fchAmount
                         , fchAmount
                         , LiabledAmount
                         , tplDiscountCharge.FIXED_AMOUNT_B
                         , VatAmount
                         , tplDiscountCharge.EXCEEDED_AMOUNT_FROM
                         , tplDiscountCharge.EXCEEDED_AMOUNT_TO
                         , tplDiscountCharge.MIN_AMOUNT
                         , tplDiscountCharge.MAX_AMOUNT
                         , tplDiscountCharge.C_ROUND_TYPE
                         , tplDiscountCharge.ROUND_AMOUNT
                         , tplDiscountCharge.C_CALCULATION_MODE
                         , tplDiscountCharge.TRANSFERT_PROP
                         , tplDiscountCharge.MODIF
                         , tplDiscountCharge.IN_SERIES_CALCULATION
                         , tplDiscountCharge.AUTOMATIC_CALC
                         , tplDiscountCharge.IS_MULTIPLICATOR
                         , tplDiscountCharge.EXCLUSIF
                         , tplDiscountCharge.STORED_PROC
                         , tplDiscountCharge.SQL_EXTERN_ITEM
                         , zvl(tplDiscountCharge.PTC_DISCOUNT_ID, null)
                         , zvl(tplDiscountCharge.PTC_CHARGE_ID, null)
                         , tplDiscountCharge.RATE
                         , tplDiscountCharge.FRACTION
                         , null
                         , TaxCodeId
                         , FinancialId
                         , DivisionId
                         , CpnId
                         , CdaId
                         , PfId
                         , PjId
                         , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                         , vAccountInfo.FAM_FIXED_ASSETS_ID
                         , vAccountInfo.C_FAM_TRANSACTION_TYP
                         , vAccountInfo.DEF_TEXT1
                         , vAccountInfo.DEF_TEXT2
                         , vAccountInfo.DEF_TEXT3
                         , vAccountInfo.DEF_TEXT4
                         , vAccountInfo.DEF_TEXT5
                         , to_number(vAccountInfo.DEF_NUMBER1)
                         , to_number(vAccountInfo.DEF_NUMBER2)
                         , to_number(vAccountInfo.DEF_NUMBER3)
                         , to_number(vAccountInfo.DEF_NUMBER4)
                         , to_number(vAccountInfo.DEF_NUMBER5)
                         , vAccountInfo.DEF_DIC_IMP_FREE1
                         , vAccountInfo.DEF_DIC_IMP_FREE2
                         , vAccountInfo.DEF_DIC_IMP_FREE3
                         , vAccountInfo.DEF_DIC_IMP_FREE4
                         , vAccountInfo.DEF_DIC_IMP_FREE5
                         , vAccountInfo.DEF_DATE1
                         , vAccountInfo.DEF_DATE2
                         , vAccountInfo.DEF_DATE3
                         , vAccountInfo.DEF_DATE4
                         , vAccountInfo.DEF_DATE5
                         , sysdate
                         , PCS.PC_I_LIB_SESSION.GetUserIni
                          );
            else
              -- Modification de la remise/taxe (issue de la décharge)
              update DOC_FOOT_CHARGE
                 set FCH_EXCL_AMOUNT = decode(lTTC, 0, fchAmount, 1, fchAmount - VatAmount)
                   , FCH_INCL_AMOUNT = decode(lTTC, 0, fchAmount + VatAmount, 1, fchAmount)
                   , FCH_BALANCE_AMOUNT = fchAmount
                   , FCH_CALC_AMOUNT = fchAmount
                   , FCH_LIABLED_AMOUNT = LiabledAmount
                   , FCH_VAT_AMOUNT = VatAmount
               where DOC_FOOT_CHARGE_ID = tplDiscountCharge.DOC_FOOT_CHARGE_ID;

              ChargeID  := tplDiscountCharge.DOC_FOOT_CHARGE_ID;
            end if;

            select CascadeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, -fchAmount, fchAmount)
              into CascadeAmount
              from dual;

            if     tplDiscountCharge.PTC_DISCOUNT_ID <> 0
               and tplDiscountCharge.EXCLUSIF = 1
               and (   abs(fchAmount) > abs(exclusiveDiscountAmount)
                    or exclusiveDiscountId is null) then
              exclusiveDiscountAmount  := fchAmount;
              exclusiveDiscountId      := ChargeID;
            end if;

            if     tplDiscountCharge.PTC_CHARGE_ID <> 0
               and tplDiscountCharge.EXCLUSIF = 1
               and (   abs(fchAmount) > abs(exclusiveChargeAmount)
                    or exclusiveChargeId is null) then
              exclusiveChargeAmount  := fchAmount;
              exclusiveChargeId      := ChargeID;
            end if;
          end if;
        end loop;

        -- Si on a des remises exclusives, effacement des remises différentes de la plus grande remise exclusive
        if exclusiveDiscountId is not null then
          for tplFootCharges in (select DOC_FOOT_CHARGE_ID
                                   from DOC_FOOT_CHARGE
                                  where DOC_FOOT_ID = document_id
                                    and PTC_DISCOUNT_ID is not null
                                    and DOC_FOOT_CHARGE_ID <> exclusiveDiscountId) loop
            DOC_DELETE.DeleteFootCharge(tplFootCharges.DOC_FOOT_CHARGE_ID);
          end loop;
        end if;

        -- Si on a des taxes exclusives, effacement des taxes différentes de la plus grande taxe exclusive
        if exclusiveChargeId is not null then
          for tplFootCharges in (select DOC_FOOT_CHARGE_ID
                                   from DOC_FOOT_CHARGE
                                  where DOC_FOOT_ID = document_id
                                    and PTC_CHARGE_ID is not null
                                    and DOC_FOOT_CHARGE_ID <> exclusiveChargeId) loop
            DOC_DELETE.DeleteFootCharge(tplFootCharges.DOC_FOOT_CHARGE_ID);
          end loop;
        end if;
      else
        -- erreur PCS dans le cas ou la procedure est appelée alors qu'il y a déjà des remises/taxes
        raise_application_error(-20041, 'PCS - Discount/Charge already defined for this document footer');
      end if;

      begin
        update DOC_DOCUMENT
           set dmt_recalc_foot_charge = 0
             , DMT_CREATE_FOOT_CHARGE = 0
         where DOC_DOCUMENT_ID = document_id;
      end;
--     else
--       raise_application_error(-20045, PCS.PC_FUNCTIONS.TranslateWord('PCS - No foot created for this document!'));
    end if;
  end CreateFootCharge;

-----------------------------------------------------------------------------------------------------------------------------
/**
* Description  : calcul des remises et taxes de pied
*/
  procedure CalculateFootCharge(
    document_id                 in doc_document.doc_document_id%type
  , dateref                     in date
  , currency_id                 in acs_financial_currency.acs_financial_currency_id%type
  , rate_of_exchange            in doc_document.dmt_rate_of_exchange%type
  , base_price                  in doc_document.dmt_base_price%type
  , aApplicateAmountConstraints in number default 1
  )
  is
    cursor crDiscountCharge(document_id number)
    is
      select   nvl(PTC_DISCOUNT_ID, 0) PTC_DISCOUNT_ID
             , nvl(PTC_CHARGE_ID, 0) PTC_CHARGE_ID
             , nvl(FCH_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 0 ORIGINAL
             , FCH_DESCRIPTION DESCR
             , FCH_NAME PTC_NAME
             , C_FINANCIAL_CHARGE
             , FCH_EXCL_AMOUNT
             , C_CALCULATION_MODE
             , FCH_RATE RATE
             , FCH_EXPRESS_IN FRACTION
             , FCH_FIXED_AMOUNT_B FIXED_AMOUNT_B
             , FCH_FIXED_AMOUNT FIXED_AMOUNT
             , FCH_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , FCH_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , FCH_MIN_AMOUNT MIN_AMOUNT
             , FCH_MAX_AMOUNT MAX_AMOUNT
             , FCH_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , FCH_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , FCH_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , FCH_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(FCH_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , FCH_TRANSFERT_PROP TRANSFERT_PROP
             , FCH_MODIFY MODIF
             , FCH_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , ACS_TAX_CODE_ID
             , DOC_FOOT_CHARGE_ID
             , FCH_FROZEN
          from DOC_FOOT_CHARGE
         where DOC_FOOT_ID = document_id
           and C_FINANCIAL_CHARGE in('02', '03')
      order by SERIES_CALC
             , descr;

    tplFoot       doc_foot%rowtype;
    blnFound      number(1);
    fchAmount     DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    VatAmount     DOC_FOOT_CHARGE.FCH_VAT_AMOUNT%type;
    liabledAmount DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    cascadeAmount DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    datVatDate    DOC_DOCUMENT.DMT_DATE_DELIVERY%type;
    lTTC          number(1);
  begin
    -- Détermine si le document est TTC ou HT
    lTTC  := DOC_FUNCTIONS.IsDocumentTTC(document_id);

    -- Recherche des dates du document pour le calcul de la TVA
    select nvl(DMT_DATE_DELIVERY, DMT_DATE_VALUE)
      into datVatDate
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = document_id;

    -- pointeur sur la position a traîter
    select *
      into tplFoot
      from doc_foot
     where doc_foot_id = document_id;

    -- montant soumis
    if lTTC = 0 then   -- HT
      select nvl(max(FOO_GOOD_TOT_AMOUNT_EXCL), 0)
           , nvl(max(FOO_GOOD_TOT_AMOUNT_EXCL), 0)
        into liabledamount
           , cascadeamount
        from V_DOC_FOOT_POSITION
       where DOC_FOOT_ID = document_id;
    else
      select nvl(max(FOO_GOOD_TOTAL_AMOUNT), 0)
           , nvl(max(FOO_GOOD_TOTAL_AMOUNT), 0)
        into liabledamount
           , cascadeamount
        from V_DOC_FOOT_POSITION
       where DOC_FOOT_ID = document_id;
    end if;

    -- ouverture d'un query sur les infos des remises/taxes
    for tplDiscountCharge in crDiscountCharge(document_id) loop
      -- Remises/taxes cascade
      if tplDiscountCharge.SERIES_CALC = 1 then
        LiabledAmount  := CascadeAmount;
      end if;

      if tplDiscountCharge.FCH_FROZEN = 0 then
        -- traitement des taxes
        if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
          --raise_application_error(-20000,to_char(tplDiscountCharge.fixed_amount)||'/'||to_char(tplDiscountCharge.fixed_amount_b));
          PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   -- Id de la taxe à calculer
                                 , tplDiscountCharge.descr   -- Nom de la taxe
                                 , 0   -- Montant unitaire soumis à la taxe en monnaie document
                                 , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                 , liabledAmount   -- Montant soumis à la taxe en monnaie document
                                 , 0   -- Pour les taxes de type détail, quantité de la position
                                 , null   -- Identifiant du bien
                                 , nvl(tplFoot.PAC_THIRD_TARIFF_ID, tplFoot.PAC_THIRD_ID)   -- Identifiant du tiers tarification
                                 , null   -- Identifiant de la position pour les taxes détaillées de type 8 (plsql)
                                 , document_id   -- Identifiant du document pour les taxes de type total de type 8 (plsql)
                                 , currency_id   -- Id de la monnaie du montant soumis
                                 , rate_of_exchange   -- Taux de change
                                 , base_price   -- Diviseur
                                 , dateref   -- Date de référence
                                 , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                 , tplDiscountCharge.rate   -- Taux
                                 , tplDiscountCharge.fraction   -- Fraction
                                 , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                 , tplDiscountCharge.fixed_amount   -- Montant fixe en monnaie document
                                 , 0   -- Quantité de
                                 , 0   -- Quantité a
                                 , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                 , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                 , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                 , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                 , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                 , 0   -- Pour le montant fixe, multiplier par quantité ?
                                 , tplDiscountCharge.automatic_calc   -- Calculation auto ou à partir de sql_Extern_item
                                 , tplDiscountCharge.sql_extern_item   -- Commande sql de recherche du montant soumis à la calculation
                                 , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                 , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                 , 0   -- Détail unitaire
                                 , tplDiscountCharge.original   -- Origine de la taxe (1 = création, 0 = modification)
                                 , 0   -- taxe de pied obligatoirement non cumulative
                                 , fchAmount   -- Montant de la taxe
                                 , blnFound   -- Taxe trouvée
                                 , 1   -- Teste l'applicabilité dans les plages de quantité
                                 , aApplicateAmountConstraints   -- Teste l'applicabilité dans les plages de montants
                                  );
        -- traitement des remises
        elsif tplDiscountCharge.PTC_DISCOUNT_ID <> 0 then
          PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   -- Id de la remise à calculer
                                   , 0   -- Montant unitaire soumis à la remise en monnaie document
                                   , liabledAmount   -- Montant soumis à la remise en monnaie document
                                   , liabledAmount   -- Montant soumis à la remise en monnaie document
                                   , 0   -- Pour les remises de type détail, quantité de la position
                                   , null   -- Identifiant de la position pour les remises détaillées de type 8 (plsql)
                                   , document_id   -- Identifiant du document pour les remises de type total de type 8 (plsql)
                                   , currency_id   -- Id de la monnaie du montant soumis
                                   , rate_of_exchange   -- Taux de change
                                   , base_price   -- Diviseur
                                   , dateref   -- Date de référence
                                   , tplDiscountCharge.C_CALCULATION_MODE   -- Mode de calcul
                                   , tplDiscountCharge.rate   -- Taux
                                   , tplDiscountCharge.fraction   -- Fraction
                                   , tplDiscountCharge.fixed_amount_b   -- Montant fixe en monnaie de base
                                   , tplDiscountCharge.fixed_amount   -- Montant fixe en monnaie document
                                   , 0   -- Quantité de
                                   , 0   -- Quantité a
                                   , tplDiscountCharge.min_amount   -- Montant minimum de remise/taxe
                                   , tplDiscountCharge.max_amount   -- Montant maximum de remise/taxe
                                   , tplDiscountCharge.exceeded_amount_from   -- Montant de dépassement de
                                   , tplDiscountCharge.exceeded_amount_to   -- Montant de dépassement à
                                   , tplDiscountCharge.stored_proc   -- Procedure stockée de calcul de remise/taxe
                                   , 0   -- Pour le montant fixe, multiplier par quantité ?
                                   , tplDiscountCharge.c_round_type   -- Type d'arrondi
                                   , tplDiscountCharge.round_amount   -- Montant d'arrondi
                                   , 0   -- Détail unitaire
                                   , tplDiscountCharge.original   -- Origine de la remise (1 = création, 0 = modification)
                                   , 0   -- Remise de pied obligatoirement non cumulative
                                   , fchAmount   -- Montant de la remise
                                   , blnFound   -- Remise trouvée
                                   , 1   -- Teste l'applicabilité dans les plages de quantité
                                   , aApplicateAmountConstraints   -- Teste l'applicabilité dans les plages de montants
                                    );
        end if;

        ----
        -- Garantit qu'aucun montant de remise/taxe soit à NULL pour évité une
        --   erreur EOracleError ORA-01400: cannot insert NULL into
        --
        if fchAmount is null then
          fchAmount  := 0;
        end if;

        if LiabledAmount is null then
          LiabledAmount  := 0;
        end if;

        -- Calcul du montant TVA
        if lTTC = 0 then   -- HT
          VatAmount  :=
            ACS_FUNCTION.CalcVatAmount(fchAmount
                                     , tplDiscountCharge.ACS_TAX_CODE_ID
                                     , 'E'
                                     , datVatDate
                                     , to_number(nvl(2 /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/, '0') )
                                      );

          -- création de la remise/taxe
          update DOC_FOOT_CHARGE
             set FCH_EXCL_AMOUNT = fchAmount
               , FCH_INCL_AMOUNT = fchAmount + VatAmount
               , FCH_BALANCE_AMOUNT = fchAmount
               , FCH_CALC_AMOUNT = fchAmount
               , FCH_LIABLED_AMOUNT = LiabledAmount
               , FCH_VAT_AMOUNT = VatAmount
               , FCH_RATE = tplDiscountCharge.rate
               , FCH_EXPRESS_IN = tplDiscountCharge.fraction
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_FOOT_CHARGE_ID = tplDiscountCharge.DOC_FOOT_CHARGE_ID;
        else
          VatAmount  :=
            ACS_FUNCTION.CalcVatAmount(fchAmount
                                     , tplDiscountCharge.ACS_TAX_CODE_ID
                                     , 'I'
                                     , datVatDate
                                     , to_number(nvl(2 /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/, '0') )
                                      );

          -- création de la remise/taxe
          update DOC_FOOT_CHARGE
             set FCH_EXCL_AMOUNT = fchAmount - VatAmount
               , FCH_INCL_AMOUNT = fchAmount
               , FCH_BALANCE_AMOUNT = fchAmount
               , FCH_CALC_AMOUNT = fchAmount
               , FCH_LIABLED_AMOUNT = LiabledAmount
               , FCH_VAT_AMOUNT = VatAmount
               , FCH_RATE = tplDiscountCharge.rate
               , FCH_EXPRESS_IN = tplDiscountCharge.fraction
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_FOOT_CHARGE_ID = tplDiscountCharge.DOC_FOOT_CHARGE_ID;
        end if;
      else   -- taxe gelée
        fchAmount  := tplDiscountCharge.FCH_EXCL_AMOUNT;
      end if;

      select CascadeAmount + decode(tplDiscountCharge.C_FINANCIAL_CHARGE, '03', fchAmount, '02', -fchAmount, 0)
        into CascadeAmount
        from dual;
    end loop;

    begin
      update DOC_DOCUMENT
         set dmt_recalc_foot_charge = 0
       where DOC_DOCUMENT_ID = document_id;
    end;
  end CalculateFootCharge;

  /**
  * Description
  *    Cette procedure fait appel soit à CreateFootCharge soit à CalculateFootCharge en fonction
  *    des DMT_RECALC_FOOT_CHARGE et DMT_CREATE_FOOT_CHARGE
  */
  procedure AutomaticFootCharge(
    document_id      in     doc_document.doc_document_id%type
  , dateref          in     date
  , currency_id      in     acs_financial_currency.acs_financial_currency_id%type
  , rate_of_exchange in     doc_document.dmt_rate_of_exchange%type
  , base_price       in     doc_document.dmt_base_price%type
  , lang_id          in     doc_document.pc_lang_id%type
  , created          out    numBoolean
  )
  is
    mustCreateFootCharge    DOC_DOCUMENT.DMT_CREATE_FOOT_CHARGE%type;
    mustDischargeFootCharge DOC_DOCUMENT.DMT_DISCHARGE_FOOT_CHARGE%type;
    recalcFootCharge        DOC_DOCUMENT.DMT_RECALC_FOOT_CHARGE%type;
    DocCreateMode           DOC_DOCUMENT.C_DOC_CREATE_MODE%type;
    createCharge            number(1)                                     default 0;
    changed                 number(1);
    cfgDischFootCharge      varchar2(10);
    lDischarged             boolean                                       := false;
  begin
    -- recalcul des totaux de document si nécessaire
    DOC_FUNCTIONS.UpdateFootTotals(document_id, changed);

    -- recherche des flags de gestion des remises/taxes de pied
    select DMT_RECALC_FOOT_CHARGE
         , DMT_CREATE_FOOT_CHARGE
         , DMT_DISCHARGE_FOOT_CHARGE
         , C_DOC_CREATE_MODE
      into recalcFootCharge
         , mustCreateFootCharge
         , mustDischargeFootCharge
         , DocCreateMode
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = document_id;

    -- décharger les remises/taxes de tous les docs source de décharge
    if     (substr(DocCreateMode, 1, 1) = '3')
       and (mustDischargeFootCharge = 1) then
      --  Rechercher la config indiquant comment on doit procéder pour les charges de pied en décharge
      -- Décharge périodique
      if DocCreateMode in('320', '325') then
        select nvl(PCS.PC_CONFIG.GETCONFIG('DOC_PERIODIC_DISCH_FOOT_CHARGE'), '1')
          into cfgDischFootCharge
          from dual;
      elsif DocCreateMode in('390') then
        -- dans le cadre de l'échéancier, on force le mode décharge
        cfgDischFootCharge  := '0';
      else
        -- Autre décharge
        select nvl(PCS.PC_CONFIG.GETCONFIG('DOC_MANUAL_DISCH_FOOT_CHARGE'), '3')
          into cfgDischFootCharge
          from dual;
      end if;

      if cfgDischFootCharge in('1', '2') then
        GenerateDischFootCharge(document_id, lDischarged);

        -- Màj du flag pour le recalcul s'il y a eu décharge
        -- très important en cas de décharge partielle
        if lDischarged then
          recalcFootCharge  := 1;
        end if;
      elsif cfgDischFootCharge in('0') then
        for ltplInvoiceExpiry in (select INX.DOC_INVOICE_EXPIRY_ID
                                       , INX.DOC_DOCUMENT_ID
                                       , DMT_SRC.DMT_ONLY_AMOUNT_BILL_BOOK
                                    from DOC_INVOICE_EXPIRY INX
                                       , DOC_DOCUMENT DMT
                                       , DOC_DOCUMENT DMT_SRC
                                   where INX.DOC_INVOICE_EXPIRY_ID = DMT.DOC_INVOICE_EXPIRY_ID
                                     and DMT.DOC_DOCUMENT_ID = document_id
                                     and DMT_SRC.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
                                     and DMT_SRC.DMT_ONLY_AMOUNT_BILL_BOOK = 0) loop
          DuplicateFootCharge(ltplInvoiceExpiry.DOC_DOCUMENT_ID   -- gèle les remises/taxes de pied
                            , document_id
                            , 1   -- gèle les remises/taxes de pied
                            , ltplInvoiceExpiry.DOC_INVOICE_EXPIRY_ID
                             );
        end loop;
      end if;

      -- Configuration : DOC_..._DISCH_FOOT_CHARGE
      --   0 : Echéancier (pas dans la config))
      --   1 : Les remises/taxes pied sont reprises des documents déchargés
      --   2 : Les remises/taxes pied sont reprises des documents déchargés + Initialisation des remises/taxes pied (comme en création document)
      --   3 : Initialisation des remises/taxes pied (comme en création document)
      if cfgDischFootCharge in('0', '1') then
        mustCreateFootCharge  := 0;
      else
        mustCreateFootCharge  := 1;
      end if;

      -- Màj du flag pour la décharge des charges de pied à NON
      -- Màj du flag pour la création des charges de pied en fonction de la config
      update DOC_DOCUMENT
         set DMT_DISCHARGE_FOOT_CHARGE = 0
           , DMT_CREATE_FOOT_CHARGE = mustCreateFootCharge
       where DOC_DOCUMENT_ID = document_id;
    end if;

    -- appel de la bonne fonction suivant les flags
    if mustCreateFootCharge = 1 then
      CreateFootCharge(document_id, dateref, currency_id, rate_of_exchange, base_price, lang_id, createCharge);

      -- Recalcul s'il y a eu décharge d'abord et ensuite création
      -- très important pour les remises/taxes qui sont flaguées cascade
      if lDischarged then
        CalculateFootCharge(document_id, dateref, currency_id, rate_of_exchange, base_price, PCS.PC_CONFIG.GetConfig('PTC_DC_TOT_TEST_AMOUNT_RECALC') );
      end if;
    elsif recalcFootCharge = 1 then
      CalculateFootCharge(document_id, dateref, currency_id, rate_of_exchange, base_price, PCS.PC_CONFIG.GetConfig('PTC_DC_TOT_TEST_AMOUNT_RECALC') );
    end if;

    created  := createCharge;
  end AutomaticFootCharge;

  /**
  * Description
  *     Duplication des remises,taxes et frais de pied du document
  */
  procedure DuplicateFootCharge(
    SourceFootID     in doc_foot.doc_foot_id%type
  , TargetFootID     in doc_foot.doc_foot_id%type
  , aFrozen          in number default 0
  , aInvoiceExpiryId in doc_invoice_expiry.doc_invoice_expiry_id%type default null
  )
  is
    cursor crFootChargeInfo(SrcFootID DOC_FOOT.DOC_FOOT_ID%type, TrgFootID DOC_FOOT.DOC_FOOT_ID%type)
    is
      select INIT_ID_SEQ.nextval DOC_FOOT_CHARGE_ID
           , FCH.C_FINANCIAL_CHARGE C_FINANCIAL_CHARGE
           , nvl(GAS_TRG.GAS_VAT, 0) GAS_VAT
           , FCH.ACS_TAX_CODE_ID
           , FCH.PTC_CHARGE_ID PTC_CHARGE_ID
           , FCH.PTC_DISCOUNT_ID PTC_DISCOUNT_ID
           , decode(nvl(GAS_TRG.GAS_VISIBLE_COUNT, 0) + nvl(GAS_TRG.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_TARGET_FINANCIAL
           , decode(nvl(GAS_TRG.GAS_VISIBLE_COUNT, 0) + nvl(GAS_TRG.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_TARGET_ANAL
           , decode(FCH.C_FINANCIAL_CHARGE, '02', FCH.PTC_DISCOUNT_ID, '03', FCH.PTC_CHARGE_ID, cast(null as number(12) ) ) CHARGE_ID
           /**
           * Règle :
           *
           *   Si les comptes sont géré ou visible sur le parent.
           *     On reprend les comptes du parent mais si les comptes sont null, on
           *     reprend de la remise ou de la taxe.
           *   Sinon
           *     On reprend les comptes de la remise ou de la taxe.
           */
      ,      decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_FINANCIAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation financière ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_FINANCIAL_ACCOUNT_ID, '02', DNT.ACS_FINANCIAL_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_FINANCIAL_ACCOUNT_ID, CRG.ACS_FINANCIAL_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_FINANCIAL_ACCOUNT_ID, DNT.ACS_FINANCIAL_ACCOUNT_ID)
                         , FCH.ACS_FINANCIAL_ACCOUNT_ID
                          )
                   ) ACS_FINANCIAL_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_FINANCIAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation financière ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_DIVISION_ACCOUNT_ID, '02', DNT.ACS_DIVISION_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_DIVISION_ACCOUNT_ID, CRG.ACS_DIVISION_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_DIVISION_ACCOUNT_ID, DNT.ACS_DIVISION_ACCOUNT_ID)
                         , FCH.ACS_DIVISION_ACCOUNT_ID
                          )
                   ) ACS_DIVISION_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_CPN_ACCOUNT_ID, '02', DNT.ACS_CPN_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_CPN_ACCOUNT_ID, CRG.ACS_CPN_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_CPN_ACCOUNT_ID, DNT.ACS_CPN_ACCOUNT_ID)
                         , FCH.ACS_CPN_ACCOUNT_ID
                          )
                   ) ACS_CPN_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_CDA_ACCOUNT_ID, '02', DNT.ACS_CDA_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_CDA_ACCOUNT_ID, CRG.ACS_CDA_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_CDA_ACCOUNT_ID, DNT.ACS_CDA_ACCOUNT_ID)
                         , FCH.ACS_CDA_ACCOUNT_ID
                          )
                   ) ACS_CDA_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_PF_ACCOUNT_ID, '02', DNT.ACS_PF_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_PF_ACCOUNT_ID, CRG.ACS_PF_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_PF_ACCOUNT_ID, DNT.ACS_PF_ACCOUNT_ID)
                         , FCH.ACS_PF_ACCOUNT_ID
                          )
                   ) ACS_PF_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_PJ_ACCOUNT_ID, '02', DNT.ACS_PJ_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_PJ_ACCOUNT_ID, CRG.ACS_PJ_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_PJ_ACCOUNT_ID, DNT.ACS_PJ_ACCOUNT_ID)
                         , FCH.ACS_PJ_ACCOUNT_ID
                          )
                   ) ACS_PJ_ACCOUNT_ID
           , FCH.HRM_PERSON_ID
           , FCH.FAM_FIXED_ASSETS_ID
           , FCH.C_FAM_TRANSACTION_TYP
           , FCH.FCH_IMP_TEXT_1
           , FCH.FCH_IMP_TEXT_2
           , FCH.FCH_IMP_TEXT_3
           , FCH.FCH_IMP_TEXT_4
           , FCH.FCH_IMP_TEXT_5
           , FCH.FCH_IMP_NUMBER_1
           , FCH.FCH_IMP_NUMBER_2
           , FCH.FCH_IMP_NUMBER_3
           , FCH.FCH_IMP_NUMBER_4
           , FCH.FCH_IMP_NUMBER_5
           , FCH.DIC_IMP_FREE1_ID
           , FCH.DIC_IMP_FREE2_ID
           , FCH.DIC_IMP_FREE3_ID
           , FCH.DIC_IMP_FREE4_ID
           , FCH.DIC_IMP_FREE5_ID
           , FCH.FCH_IMP_DATE_1
           , FCH.FCH_IMP_DATE_2
           , FCH.FCH_IMP_DATE_3
           , FCH.FCH_IMP_DATE_4
           , FCH.FCH_IMP_DATE_5
           , FCH.FCH_DESCRIPTION FCH_DESCRIPTION
           , FCH.FCH_RATE FCH_RATE
           , FCH.FCH_EXPRESS_IN FCH_EXPRESS_IN
           , sysdate A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
           , FCH.C_ROUND_TYPE C_ROUND_TYPE
           , FCH.C_CALCULATION_MODE C_CALCULATION_MODE
           , FCH.DOC_DOC_FOOT_CHARGE_ID DOC_DOC_FOOT_CHARGE_ID
           , FCH.FCH_TRANSFERT_PROP FCH_TRANSFERT_PROP
           , FCH.FCH_MODIFY FCH_MODIFY
           , FCH.FCH_IN_SERIES_CALCULATION FCH_IN_SERIES_CALCULATION
           , FCH.FCH_BALANCE_AMOUNT FCH_BALANCE_AMOUNT
           , FCH.FCH_NAME FCH_NAME
           , FCH.FCH_FIXED_AMOUNT FCH_FIXED_AMOUNT
           , FCH.FCH_FIXED_AMOUNT_B FCH_FIXED_AMOUNT_B
           , FCH.FCH_FIXED_AMOUNT_E FCH_FIXED_AMOUNT_E
           , FCH.FCH_EXCEEDED_AMOUNT_FROM FCH_EXCEEDED_AMOUNT_FROM
           , FCH.FCH_EXCEEDED_AMOUNT_TO FCH_EXCEEDED_AMOUNT_TO
           , FCH.FCH_MIN_AMOUNT FCH_MIN_AMOUNT
           , FCH.FCH_MAX_AMOUNT FCH_MAX_AMOUNT
           , FCH.FCH_IS_MULTIPLICATOR FCH_IS_MULTIPLICATOR
           , FCH.FCH_ROUND_AMOUNT FCH_ROUND_AMOUNT
           , FCH.FCH_STORED_PROC FCH_STORED_PROC
           , FCH.FCH_AUTOMATIC_CALC FCH_AUTOMATIC_CALC
           , FCH.FCH_SQL_EXTERN_ITEM FCH_SQL_EXTERN_ITEM
           , FCH.FCH_EXCL_AMOUNT FCH_EXCL_AMOUNT
           , FCH.FCH_EXCL_AMOUNT_B FCH_EXCL_AMOUNT_B
           , FCH.FCH_EXCL_AMOUNT_E FCH_EXCL_AMOUNT_E
           , FCH.FCH_INCL_AMOUNT FCH_INCL_AMOUNT
           , FCH.FCH_INCL_AMOUNT_B FCH_INCL_AMOUNT_B
           , FCH.FCH_INCL_AMOUNT_E FCH_INCL_AMOUNT_E
           , FCH.FCH_VAT_AMOUNT FCH_VAT_AMOUNT
           , FCH.FCH_VAT_BASE_AMOUNT FCH_VAT_BASE_AMOUNT
           , FCH.FCH_VAT_AMOUNT_E FCH_VAT_AMOUNT_E
           , DOC_TRG.PAC_THIRD_ID PAC_THIRD_ID
           , DOC_TRG.PAC_THIRD_ACI_ID PAC_THIRD_ACI_ID
           , DOC_TRG.PAC_THIRD_TARIFF_ID PAC_THIRD_TARIFF_ID
           , DOC_TRG.PAC_THIRD_VAT_ID
           , DOC_TRG.DOC_RECORD_ID DOC_RECORD_ID
           , DOC_TRG.DOC_GAUGE_ID DOC_GAUGE_ID
           , DOC_TRG.DMT_DATE_DOCUMENT DMT_DATE_DOCUMENT
           , GAU_TRG.C_ADMIN_DOMAIN C_ADMIN_DOMAIN
           , GAU_TRG.GAU_USE_MANAGED_DATA GAU_USE_MANAGED_DATA
           , nvl(DOC_TRG.DMT_DATE_DELIVERY, DOC_TRG.DMT_DATE_VALUE) DMT_DATE_VAT
           , DOC_TRG.DIC_TYPE_SUBMISSION_ID
           , GAS_TRG.DIC_TYPE_MOVEMENT_ID
           , DOC_TRG.ACS_VAT_DET_ACCOUNT_ID
           , GAS_TRG.GAS_CHARGE
           , GAS_TRG.GAS_DISCOUNT
           , GAS_TRG.GAS_TAXE
        from DOC_FOOT_CHARGE FCH
           , PTC_DISCOUNT DNT
           , PTC_CHARGE CRG
           , DOC_DOCUMENT DOC_TRG
           , DOC_DOCUMENT DOC_SRC
           , DOC_GAUGE GAU_TRG
           , DOC_GAUGE_STRUCTURED GAS_TRG
           , DOC_GAUGE_STRUCTURED GAS_SRC
       where FCH.DOC_FOOT_ID = SrcFootID
         and DOC_TRG.DOC_DOCUMENT_ID = TrgFootID
         and DOC_TRG.DOC_GAUGE_ID = GAU_TRG.DOC_GAUGE_ID
         and GAU_TRG.DOC_GAUGE_ID = GAS_TRG.DOC_GAUGE_ID
         and DOC_SRC.DOC_DOCUMENT_ID = FCH.DOC_FOOT_ID
         and GAS_SRC.DOC_GAUGE_ID = DOC_SRC.DOC_GAUGE_ID
         and nvl(FCH.C_CHARGE_ORIGIN, 'AUTO') not in('PM', 'PMM', 'OP')   -- exclure les remises matières précieuses et opérations sous-traitance
         and DNT.PTC_DISCOUNT_ID(+) = FCH.PTC_DISCOUNT_ID
         and CRG.PTC_CHARGE_ID(+) = FCH.PTC_CHARGE_ID;

    FinAccountID DOC_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID%type;
    DivAccountID DOC_DOCUMENT.ACS_DIVISION_ACCOUNT_ID%type;
    CPNAccountID DOC_DOCUMENT.ACS_CPN_ACCOUNT_ID%type;
    CDAAccountID DOC_DOCUMENT.ACS_CDA_ACCOUNT_ID%type;
    PFAccountID  DOC_DOCUMENT.ACS_PF_ACCOUNT_ID%type;
    PJAccountID  DOC_DOCUMENT.ACS_PJ_ACCOUNT_ID%type;
    taxCodeID    DOC_FOOT_CHARGE.ACS_TAX_CODE_ID%type;
    vatAmount    DOC_FOOT_CHARGE.FCH_VAT_AMOUNT%type;
    ElementType  varchar2(2);
    vAccountInfo ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    typeCharge   number(1);
  begin
    for tplFootChargeInfo in crFootChargeInfo(SourceFootID, TargetFootID) loop
      if    (    tplFootChargeInfo.C_FINANCIAL_CHARGE = '01'
             and tplFootChargeInfo.GAS_TAXE = 1)   -- le tuple est un frais et le gabarit gère les frais
         or (    tplFootChargeInfo.C_FINANCIAL_CHARGE = '02'
             and tplFootChargeInfo.GAS_DISCOUNT = 1)   -- le tuple est une remise et le gabarit gère les remises
         or (    tplFootChargeInfo.C_FINANCIAL_CHARGE = '03'
             and tplFootChargeInfo.GAS_CHARGE = 1) then   -- le tuple est une taxe et le gabarit gère les taxes
        ----
        -- Recherche le code TVA de la charge de pied
        --
        if (tplFootChargeInfo.GAS_VAT = 1) then
          if (tplFootChargeInfo.ACS_TAX_CODE_ID is null) then
            if (tplFootChargeInfo.C_FINANCIAL_CHARGE = '01') then   -- Frais
              typeCharge  := 5;
            elsif(tplFootChargeInfo.C_FINANCIAL_CHARGE = '02') then   -- Remise
              typeCharge  := 3;
            else   -- Taxe
              typeCharge  := 4;
            end if;

            -- Recherche du code Taxe
            taxCodeID  :=
              ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(typeCharge
                                                    , tplFootChargeInfo.PAC_THIRD_VAT_ID
                                                    , 0
                                                    , tplFootChargeInfo.PTC_DISCOUNT_ID
                                                    , tplFootChargeInfo.PTC_CHARGE_ID
                                                    , tplFootChargeInfo.C_ADMIN_DOMAIN
                                                    , tplFootChargeInfo.DIC_TYPE_SUBMISSION_ID
                                                    , tplFootChargeInfo.DIC_TYPE_MOVEMENT_ID
                                                    , tplFootChargeInfo.ACS_VAT_DET_ACCOUNT_ID
                                                     );
            -- Calcul du montant TVA
            vatAmount  :=
              ACS_FUNCTION.CalcVatAmount(tplFootChargeInfo.FCH_EXCL_AMOUNT
                                       , taxCodeID
                                       , 'E'
                                       , tplFootChargeInfo.DMT_DATE_VAT
                                       , to_number(nvl(2 /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/, '0') )
                                        );
          else
            taxCodeID  := tplFootChargeInfo.ACS_TAX_CODE_ID;
            vatAmount  := tplFootChargeInfo.FCH_VAT_AMOUNT;
          end if;
        else
          taxCodeID  := null;
          vatAmount  := 0;
        end if;

        -- Si gestion des comptes financiers ou analytiques
        if    (tplFootChargeInfo.GAS_TARGET_FINANCIAL = 1)
           or (tplFootChargeInfo.GAS_TARGET_ANAL = 1) then
          -- Initialisation des comptes depuis la source
          FinAccountID  := tplFootChargeInfo.ACS_FINANCIAL_ACCOUNT_ID;
          DivAccountID  := tplFootChargeInfo.ACS_DIVISION_ACCOUNT_ID;
          CPNAccountID  := tplFootChargeInfo.ACS_CPN_ACCOUNT_ID;
          CDAAccountID  := tplFootChargeInfo.ACS_CDA_ACCOUNT_ID;
          PFAccountID   := tplFootChargeInfo.ACS_PF_ACCOUNT_ID;
          PJAccountID   := tplFootChargeInfo.ACS_PJ_ACCOUNT_ID;

          if (tplFootChargeInfo.GAU_USE_MANAGED_DATA = 1) then
            vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(tplFootChargeInfo.HRM_PERSON_ID);
            vAccountInfo.FAM_FIXED_ASSETS_ID    := tplFootChargeInfo.FAM_FIXED_ASSETS_ID;
            vAccountInfo.C_FAM_TRANSACTION_TYP  := tplFootChargeInfo.C_FAM_TRANSACTION_TYP;
            vAccountInfo.DEF_DIC_IMP_FREE1      := tplFootChargeInfo.DIC_IMP_FREE1_ID;
            vAccountInfo.DEF_DIC_IMP_FREE2      := tplFootChargeInfo.DIC_IMP_FREE2_ID;
            vAccountInfo.DEF_DIC_IMP_FREE3      := tplFootChargeInfo.DIC_IMP_FREE3_ID;
            vAccountInfo.DEF_DIC_IMP_FREE4      := tplFootChargeInfo.DIC_IMP_FREE4_ID;
            vAccountInfo.DEF_DIC_IMP_FREE5      := tplFootChargeInfo.DIC_IMP_FREE5_ID;
            vAccountInfo.DEF_TEXT1              := tplFootChargeInfo.FCH_IMP_TEXT_1;
            vAccountInfo.DEF_TEXT2              := tplFootChargeInfo.FCH_IMP_TEXT_2;
            vAccountInfo.DEF_TEXT3              := tplFootChargeInfo.FCH_IMP_TEXT_3;
            vAccountInfo.DEF_TEXT4              := tplFootChargeInfo.FCH_IMP_TEXT_4;
            vAccountInfo.DEF_TEXT5              := tplFootChargeInfo.FCH_IMP_TEXT_5;
            vAccountInfo.DEF_NUMBER1            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_1);
            vAccountInfo.DEF_NUMBER2            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_2);
            vAccountInfo.DEF_NUMBER3            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_3);
            vAccountInfo.DEF_NUMBER4            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_4);
            vAccountInfo.DEF_NUMBER5            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_5);
            vAccountInfo.DEF_DATE1              := tplFootChargeInfo.FCH_IMP_DATE_1;
            vAccountInfo.DEF_DATE2              := tplFootChargeInfo.FCH_IMP_DATE_2;
            vAccountInfo.DEF_DATE3              := tplFootChargeInfo.FCH_IMP_DATE_3;
            vAccountInfo.DEF_DATE4              := tplFootChargeInfo.FCH_IMP_DATE_4;
            vAccountInfo.DEF_DATE5              := tplFootChargeInfo.FCH_IMP_DATE_5;
          else
            vAccountInfo.DEF_HRM_PERSON         := null;
            vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
            vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
            vAccountInfo.DEF_DIC_IMP_FREE1      := null;
            vAccountInfo.DEF_DIC_IMP_FREE2      := null;
            vAccountInfo.DEF_DIC_IMP_FREE3      := null;
            vAccountInfo.DEF_DIC_IMP_FREE4      := null;
            vAccountInfo.DEF_DIC_IMP_FREE5      := null;
            vAccountInfo.DEF_TEXT1              := null;
            vAccountInfo.DEF_TEXT2              := null;
            vAccountInfo.DEF_TEXT3              := null;
            vAccountInfo.DEF_TEXT4              := null;
            vAccountInfo.DEF_TEXT5              := null;
            vAccountInfo.DEF_NUMBER1            := null;
            vAccountInfo.DEF_NUMBER2            := null;
            vAccountInfo.DEF_NUMBER3            := null;
            vAccountInfo.DEF_NUMBER4            := null;
            vAccountInfo.DEF_NUMBER5            := null;
            vAccountInfo.DEF_DATE1              := null;
            vAccountInfo.DEF_DATE2              := null;
            vAccountInfo.DEF_DATE3              := null;
            vAccountInfo.DEF_DATE4              := null;
            vAccountInfo.DEF_DATE5              := null;
          end if;

          -- Type Remise / Taxe / Frais
          select decode(tplFootChargeInfo.C_FINANCIAL_CHARGE, '01', '50', '02', '20', '03', '30')
            into ElementType
            from dual;

          -- Recherche des comptes finance et analytique
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplFootChargeInfo.CHARGE_ID
                                                   , ElementType
                                                   , tplFootChargeInfo.C_ADMIN_DOMAIN
                                                   , tplFootChargeInfo.DMT_DATE_DOCUMENT
                                                   , tplFootChargeInfo.DOC_GAUGE_ID
                                                   , TargetFootID
                                                   , null
                                                   , tplFootChargeInfo.DOC_RECORD_ID
                                                   , tplFootChargeInfo.PAC_THIRD_ACI_ID
                                                   , null
                                                   , null
                                                   , null
                                                   , null
                                                   , null
                                                   , null
                                                   , FinAccountID
                                                   , DivAccountID
                                                   , CPNAccountID
                                                   , CDAAccountID
                                                   , PFAccountID
                                                   , PJAccountID
                                                   , vAccountInfo
                                                    );

          -- Si le gabarit cible ne gère l'imputation analytique
          if (tplFootChargeInfo.GAS_TARGET_ANAL = 0) then
            CPNAccountID  := null;
            CDAAccountID  := null;
            PFAccountID   := null;
            PJAccountID   := null;
          end if;
        end if;

        insert into DOC_FOOT_CHARGE
                    (DOC_FOOT_CHARGE_ID
                   , DOC_FOOT_ID
                   , C_CHARGE_ORIGIN
                   , C_FINANCIAL_CHARGE
                   , ACS_TAX_CODE_ID
                   , PTC_CHARGE_ID
                   , PTC_DISCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , DOC_INVOICE_EXPIRY_ID
                   , FCH_DESCRIPTION
                   , FCH_RATE
                   , FCH_EXPRESS_IN
                   , A_DATECRE
                   , A_IDCRE
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , C_ROUND_TYPE
                   , C_CALCULATION_MODE
                   , DOC_DOC_FOOT_CHARGE_ID
                   , FCH_TRANSFERT_PROP
                   , FCH_MODIFY
                   , FCH_IN_SERIES_CALCULATION
                   , FCH_BALANCE_AMOUNT
                   , FCH_NAME
                   , FCH_FIXED_AMOUNT
                   , FCH_FIXED_AMOUNT_B
                   , FCH_FIXED_AMOUNT_E
                   , FCH_EXCEEDED_AMOUNT_FROM
                   , FCH_EXCEEDED_AMOUNT_TO
                   , FCH_MIN_AMOUNT
                   , FCH_MAX_AMOUNT
                   , FCH_IS_MULTIPLICATOR
                   , FCH_ROUND_AMOUNT
                   , FCH_STORED_PROC
                   , FCH_AUTOMATIC_CALC
                   , FCH_SQL_EXTERN_ITEM
                   , FCH_EXCL_AMOUNT
                   , FCH_EXCL_AMOUNT_B
                   , FCH_EXCL_AMOUNT_E
                   , FCH_INCL_AMOUNT
                   , FCH_INCL_AMOUNT_B
                   , FCH_INCL_AMOUNT_E
                   , FCH_VAT_AMOUNT
                   , FCH_VAT_BASE_AMOUNT
                   , FCH_VAT_AMOUNT_E
                   , FCH_FROZEN
                   , HRM_PERSON_ID
                   , FAM_FIXED_ASSETS_ID
                   , C_FAM_TRANSACTION_TYP
                   , FCH_IMP_TEXT_1
                   , FCH_IMP_TEXT_2
                   , FCH_IMP_TEXT_3
                   , FCH_IMP_TEXT_4
                   , FCH_IMP_TEXT_5
                   , FCH_IMP_NUMBER_1
                   , FCH_IMP_NUMBER_2
                   , FCH_IMP_NUMBER_3
                   , FCH_IMP_NUMBER_4
                   , FCH_IMP_NUMBER_5
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , FCH_IMP_DATE_1
                   , FCH_IMP_DATE_2
                   , FCH_IMP_DATE_3
                   , FCH_IMP_DATE_4
                   , FCH_IMP_DATE_5
                    )
             values (tplFootChargeInfo.DOC_FOOT_CHARGE_ID
                   , TargetFootID   -- DOC_FOOT_ID
                   , 'AUTO'
                   , tplFootChargeInfo.C_FINANCIAL_CHARGE
                   , taxCodeID
                   , tplFootChargeInfo.PTC_CHARGE_ID
                   , tplFootChargeInfo.PTC_DISCOUNT_ID
                   , decode(FinAccountID, 0, null, FinAccountID)
                   , decode(DivAccountID, 0, null, DivAccountID)
                   , aInvoiceExpiryId
                   , tplFootChargeInfo.FCH_DESCRIPTION
                   , tplFootChargeInfo.FCH_RATE
                   , tplFootChargeInfo.FCH_EXPRESS_IN
                   , tplFootChargeInfo.A_DATECRE
                   , tplFootChargeInfo.A_IDCRE
                   , decode(CPNAccountID, 0, null, CPNAccountID)
                   , decode(CDAAccountID, 0, null, CDAAccountID)
                   , decode(PJAccountID, 0, null, PJAccountID)
                   , decode(PFAccountID, 0, null, PFAccountID)
                   , tplFootChargeInfo.C_ROUND_TYPE
                   , tplFootChargeInfo.C_CALCULATION_MODE
                   , tplFootChargeInfo.DOC_DOC_FOOT_CHARGE_ID
                   , tplFootChargeInfo.FCH_TRANSFERT_PROP
                   , tplFootChargeInfo.FCH_MODIFY
                   , tplFootChargeInfo.FCH_IN_SERIES_CALCULATION
                   , tplFootChargeInfo.FCH_BALANCE_AMOUNT
                   , tplFootChargeInfo.FCH_NAME
                   , tplFootChargeInfo.FCH_FIXED_AMOUNT
                   , tplFootChargeInfo.FCH_FIXED_AMOUNT_B
                   , tplFootChargeInfo.FCH_FIXED_AMOUNT_E
                   , tplFootChargeInfo.FCH_EXCEEDED_AMOUNT_FROM
                   , tplFootChargeInfo.FCH_EXCEEDED_AMOUNT_TO
                   , tplFootChargeInfo.FCH_MIN_AMOUNT
                   , tplFootChargeInfo.FCH_MAX_AMOUNT
                   , tplFootChargeInfo.FCH_IS_MULTIPLICATOR
                   , tplFootChargeInfo.FCH_ROUND_AMOUNT
                   , tplFootChargeInfo.FCH_STORED_PROC
                   , tplFootChargeInfo.FCH_AUTOMATIC_CALC
                   , tplFootChargeInfo.FCH_SQL_EXTERN_ITEM
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT_B
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT_E
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT + vatAmount
                   , tplFootChargeInfo.FCH_INCL_AMOUNT_B
                   , tplFootChargeInfo.FCH_INCL_AMOUNT_E
                   , vatAmount
                   , tplFootChargeInfo.FCH_VAT_BASE_AMOUNT
                   , tplFootChargeInfo.FCH_VAT_AMOUNT_E
                   , aFrozen
                   , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                   , vAccountInfo.FAM_FIXED_ASSETS_ID
                   , vAccountInfo.C_FAM_TRANSACTION_TYP
                   , vAccountInfo.DEF_TEXT1
                   , vAccountInfo.DEF_TEXT2
                   , vAccountInfo.DEF_TEXT3
                   , vAccountInfo.DEF_TEXT4
                   , vAccountInfo.DEF_TEXT5
                   , to_number(vAccountInfo.DEF_NUMBER1)
                   , to_number(vAccountInfo.DEF_NUMBER2)
                   , to_number(vAccountInfo.DEF_NUMBER3)
                   , to_number(vAccountInfo.DEF_NUMBER4)
                   , to_number(vAccountInfo.DEF_NUMBER5)
                   , vAccountInfo.DEF_DIC_IMP_FREE1
                   , vAccountInfo.DEF_DIC_IMP_FREE2
                   , vAccountInfo.DEF_DIC_IMP_FREE3
                   , vAccountInfo.DEF_DIC_IMP_FREE4
                   , vAccountInfo.DEF_DIC_IMP_FREE5
                   , vAccountInfo.DEF_DATE1
                   , vAccountInfo.DEF_DATE2
                   , vAccountInfo.DEF_DATE3
                   , vAccountInfo.DEF_DATE4
                   , vAccountInfo.DEF_DATE5
                    );
      end if;
    end loop;

    declare
      newLinkID DOC_DOCUMENT_LINK.DOC_DOCUMENT_LINK_ID%type;
    begin
      select INIT_ID_SEQ.nextval
        into newLinkID
        from dual;

      -- Màj table de lien copie/décharge charges de pied
      insert into DOC_DOCUMENT_LINK
                  (DOC_DOCUMENT_LINK_ID
                 , DOC_DOCUMENT_ID
                 , DOC_DOCUMENT_SRC_ID
                 , DLK_COUNT
                 , C_DOCUMENT_LINK
                 , A_DATECRE
                 , A_IDCRE
                  )
        select newLinkID
             , TargetFootID
             , SourceFootID
             , count(*)
             , 'FCH-COPY'   -- Copy foot charge
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from DOC_FOOT_CHARGE
         where DOC_FOOT_ID = TargetFootID;
    end;

    begin
      update DOC_DOCUMENT
         set dmt_recalc_foot_charge = 0
           , DMT_CREATE_FOOT_CHARGE = (select decode(count(*), 0, 1, 0)
                                         from DOC_FOOT_CHARGE
                                        where DOC_FOOT_ID = TargetFootID)
       where DOC_DOCUMENT_ID = TargetFootID;
    end;
  end DuplicateFootCharge;

  /**
  * procedure CopyDischFootCharge
  * Description
  *     Copie ou décharge les remises,taxes et frais de pied d'un document
  */
  procedure CopyDischFootCharge(
    SourceFootID       in     doc_foot.doc_foot_id%type
  , TargetFootID       in     doc_foot.doc_foot_id%type
  , aChargeOrigin      in     doc_foot_charge.c_charge_origin%type default 'COPY'
  , aOnlyAmountCharges in     integer default 0
  , oGenerated         out    boolean
  )
  is
    cursor crFootChargeInfo(SrcFootID DOC_FOOT.DOC_FOOT_ID%type, TrgFootID DOC_FOOT.DOC_FOOT_ID%type)
    is
      select INIT_ID_SEQ.nextval DOC_FOOT_CHARGE_ID
           , FCH.C_FINANCIAL_CHARGE C_FINANCIAL_CHARGE
           , nvl(GAS_TRG.GAS_VAT, 0) GAS_VAT
           , FCH.ACS_TAX_CODE_ID
           , FCH.PTC_CHARGE_ID PTC_CHARGE_ID
           , FCH.PTC_DISCOUNT_ID PTC_DISCOUNT_ID
           , decode(nvl(GAS_TRG.GAS_VISIBLE_COUNT, 0) + nvl(GAS_TRG.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_TARGET_FINANCIAL
           , decode(nvl(GAS_TRG.GAS_VISIBLE_COUNT, 0) + nvl(GAS_TRG.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_TARGET_ANAL
           , decode(FCH.C_FINANCIAL_CHARGE, '02', FCH.PTC_DISCOUNT_ID, '03', FCH.PTC_CHARGE_ID, cast(null as number(12) ) ) CHARGE_ID
           /**
           * Règle :
           *
           *   Si les comptes sont géré ou visible sur le parent.
           *     On reprend les comptes du parent mais si les comptes sont null, on
           *     reprend de la remise ou de la taxe.
           *   Sinon
           *     On reprend les comptes de la remise ou de la taxe.
           */
      ,      decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_FINANCIAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation financière ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_FINANCIAL_ACCOUNT_ID, '02', DNT.ACS_FINANCIAL_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_FINANCIAL_ACCOUNT_ID, CRG.ACS_FINANCIAL_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_FINANCIAL_ACCOUNT_ID, DNT.ACS_FINANCIAL_ACCOUNT_ID)
                         , FCH.ACS_FINANCIAL_ACCOUNT_ID
                          )
                   ) ACS_FINANCIAL_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_FINANCIAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation financière ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_DIVISION_ACCOUNT_ID, '02', DNT.ACS_DIVISION_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_DIVISION_ACCOUNT_ID, CRG.ACS_DIVISION_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_DIVISION_ACCOUNT_ID, DNT.ACS_DIVISION_ACCOUNT_ID)
                         , FCH.ACS_DIVISION_ACCOUNT_ID
                          )
                   ) ACS_DIVISION_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_CPN_ACCOUNT_ID, '02', DNT.ACS_CPN_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_CPN_ACCOUNT_ID, CRG.ACS_CPN_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_CPN_ACCOUNT_ID, DNT.ACS_CPN_ACCOUNT_ID)
                         , FCH.ACS_CPN_ACCOUNT_ID
                          )
                   ) ACS_CPN_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_CDA_ACCOUNT_ID, '02', DNT.ACS_CDA_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_CDA_ACCOUNT_ID, CRG.ACS_CDA_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_CDA_ACCOUNT_ID, DNT.ACS_CDA_ACCOUNT_ID)
                         , FCH.ACS_CDA_ACCOUNT_ID
                          )
                   ) ACS_CDA_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_PF_ACCOUNT_ID, '02', DNT.ACS_PF_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_PF_ACCOUNT_ID, CRG.ACS_PF_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_PF_ACCOUNT_ID, DNT.ACS_PF_ACCOUNT_ID)
                         , FCH.ACS_PF_ACCOUNT_ID
                          )
                   ) ACS_PF_ACCOUNT_ID
           , decode(nvl(GAS_SRC.GAS_VISIBLE_COUNT, 0) + nvl(GAS_SRC.GAS_ANAL_CHARGE, 0)
                  ,   -- Compte visible ou gestion de l'imputation analytique ?
                    0, decode(FCH.C_FINANCIAL_CHARGE, '03', CRG.ACS_PJ_ACCOUNT_ID, '02', DNT.ACS_PJ_ACCOUNT_ID, cast(null as number(12) ) )
                  , decode(FCH.C_FINANCIAL_CHARGE
                         , '03', nvl(FCH.ACS_PJ_ACCOUNT_ID, CRG.ACS_PJ_ACCOUNT_ID)
                         , '02', nvl(FCH.ACS_PJ_ACCOUNT_ID, DNT.ACS_PJ_ACCOUNT_ID)
                         , FCH.ACS_PJ_ACCOUNT_ID
                          )
                   ) ACS_PJ_ACCOUNT_ID
           , FCH.HRM_PERSON_ID
           , FCH.FAM_FIXED_ASSETS_ID
           , FCH.C_FAM_TRANSACTION_TYP
           , FCH.FCH_IMP_TEXT_1
           , FCH.FCH_IMP_TEXT_2
           , FCH.FCH_IMP_TEXT_3
           , FCH.FCH_IMP_TEXT_4
           , FCH.FCH_IMP_TEXT_5
           , FCH.FCH_IMP_NUMBER_1
           , FCH.FCH_IMP_NUMBER_2
           , FCH.FCH_IMP_NUMBER_3
           , FCH.FCH_IMP_NUMBER_4
           , FCH.FCH_IMP_NUMBER_5
           , FCH.DIC_IMP_FREE1_ID
           , FCH.DIC_IMP_FREE2_ID
           , FCH.DIC_IMP_FREE3_ID
           , FCH.DIC_IMP_FREE4_ID
           , FCH.DIC_IMP_FREE5_ID
           , FCH_IMP_DATE_1
           , FCH_IMP_DATE_2
           , FCH_IMP_DATE_3
           , FCH_IMP_DATE_4
           , FCH_IMP_DATE_5
           , FCH.FCH_DESCRIPTION FCH_DESCRIPTION
           , FCH.FCH_RATE FCH_RATE
           , FCH.FCH_EXPRESS_IN FCH_EXPRESS_IN
           , sysdate A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
           , FCH.C_ROUND_TYPE C_ROUND_TYPE
           , FCH.C_CALCULATION_MODE C_CALCULATION_MODE
           , FCH.DOC_DOC_FOOT_CHARGE_ID DOC_DOC_FOOT_CHARGE_ID
           , FCH.FCH_TRANSFERT_PROP FCH_TRANSFERT_PROP
           , FCH.FCH_MODIFY FCH_MODIFY
           , FCH.FCH_IN_SERIES_CALCULATION FCH_IN_SERIES_CALCULATION
           , FCH.FCH_BALANCE_AMOUNT FCH_BALANCE_AMOUNT
           , FCH.FCH_NAME FCH_NAME
           , FCH.FCH_FIXED_AMOUNT FCH_FIXED_AMOUNT
           , FCH.FCH_FIXED_AMOUNT_B FCH_FIXED_AMOUNT_B
           , FCH.FCH_FIXED_AMOUNT_E FCH_FIXED_AMOUNT_E
           , FCH.FCH_EXCEEDED_AMOUNT_FROM FCH_EXCEEDED_AMOUNT_FROM
           , FCH.FCH_EXCEEDED_AMOUNT_TO FCH_EXCEEDED_AMOUNT_TO
           , FCH.FCH_MIN_AMOUNT FCH_MIN_AMOUNT
           , FCH.FCH_MAX_AMOUNT FCH_MAX_AMOUNT
           , FCH.FCH_IS_MULTIPLICATOR FCH_IS_MULTIPLICATOR
           , FCH.FCH_EXCLUSIVE FCH_EXCLUSIVE
           , FCH.FCH_ROUND_AMOUNT FCH_ROUND_AMOUNT
           , FCH.FCH_STORED_PROC FCH_STORED_PROC
           , FCH.FCH_AUTOMATIC_CALC FCH_AUTOMATIC_CALC
           , FCH.FCH_SQL_EXTERN_ITEM FCH_SQL_EXTERN_ITEM
           , FCH.FCH_EXCL_AMOUNT FCH_EXCL_AMOUNT
           , FCH.FCH_EXCL_AMOUNT_B FCH_EXCL_AMOUNT_B
           , FCH.FCH_EXCL_AMOUNT_E FCH_EXCL_AMOUNT_E
           , FCH.FCH_INCL_AMOUNT FCH_INCL_AMOUNT
           , FCH.FCH_INCL_AMOUNT_B FCH_INCL_AMOUNT_B
           , FCH.FCH_INCL_AMOUNT_E FCH_INCL_AMOUNT_E
           , FCH.FCH_VAT_AMOUNT FCH_VAT_AMOUNT
           , FCH.FCH_VAT_BASE_AMOUNT FCH_VAT_BASE_AMOUNT
           , FCH.FCH_VAT_AMOUNT_E FCH_VAT_AMOUNT_E
           , DOC_TRG.PAC_THIRD_ID PAC_THIRD_ID
           , DOC_TRG.PAC_THIRD_ACI_ID PAC_THIRD_ACI_ID
           , DOC_TRG.PAC_THIRD_TARIFF_ID PAC_THIRD_TARIFF_ID
           , DOC_TRG.PAC_THIRD_VAT_ID
           , DOC_TRG.DOC_RECORD_ID DOC_RECORD_ID
           , DOC_TRG.DOC_GAUGE_ID DOC_GAUGE_ID
           , DOC_TRG.DMT_DATE_DOCUMENT DMT_DATE_DOCUMENT
           , GAU_TRG.C_ADMIN_DOMAIN C_ADMIN_DOMAIN
           , GAU_TRG.GAU_USE_MANAGED_DATA GAU_USE_MANAGED_DATA
           , nvl(DOC_TRG.DMT_DATE_DELIVERY, DOC_TRG.DMT_DATE_VALUE) DMT_DATE_VAT
           , DOC_TRG.DIC_TYPE_SUBMISSION_ID
           , GAS_TRG.DIC_TYPE_MOVEMENT_ID
           , DOC_TRG.ACS_VAT_DET_ACCOUNT_ID
           , FCH.DOC_FOOT_CHARGE_ID DOC_FOOT_CHARGE_SRC_ID
           , GAS_TRG.GAS_CHARGE
           , GAS_TRG.GAS_DISCOUNT
           , GAS_TRG.GAS_TAXE
        from DOC_FOOT_CHARGE FCH
           , PTC_DISCOUNT DNT
           , PTC_CHARGE CRG
           , DOC_DOCUMENT DOC_TRG
           , DOC_DOCUMENT DOC_SRC
           , DOC_GAUGE GAU_TRG
           , DOC_GAUGE_STRUCTURED GAS_TRG
           , DOC_GAUGE_STRUCTURED GAS_SRC
       where FCH.DOC_FOOT_ID = SrcFootID
         and DOC_TRG.DOC_DOCUMENT_ID = TrgFootID
         and DOC_TRG.DOC_GAUGE_ID = GAU_TRG.DOC_GAUGE_ID
         and GAU_TRG.DOC_GAUGE_ID = GAS_TRG.DOC_GAUGE_ID
         and DOC_SRC.DOC_DOCUMENT_ID = FCH.DOC_FOOT_ID
         and GAS_SRC.DOC_GAUGE_ID = DOC_SRC.DOC_GAUGE_ID
         -- exclure les remises matières précieuses et opérations sous-traitance
         and nvl(FCH.C_CHARGE_ORIGIN, 'AUTO') not in('PM', 'PMM', 'OP')
         and DNT.PTC_DISCOUNT_ID(+) = FCH.PTC_DISCOUNT_ID
         and CRG.PTC_CHARGE_ID(+) = FCH.PTC_CHARGE_ID
         -- si en décharge, exclure les remises taxes déjà déchargées
         and (     (aChargeOrigin = 'DISCH')
              and nvl(FCH.FCH_DISCHARGED, 0) = 0)
         -- toutes les charges ou bien celles de type montant seulement
         and (   aOnlyAmountCharges = 0
              or FCH.C_CALCULATION_MODE in('0', '1') );

    FinAccountID            DOC_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID%type;
    DivAccountID            DOC_DOCUMENT.ACS_DIVISION_ACCOUNT_ID%type;
    CPNAccountID            DOC_DOCUMENT.ACS_CPN_ACCOUNT_ID%type;
    CDAAccountID            DOC_DOCUMENT.ACS_CDA_ACCOUNT_ID%type;
    PFAccountID             DOC_DOCUMENT.ACS_PF_ACCOUNT_ID%type;
    PJAccountID             DOC_DOCUMENT.ACS_PJ_ACCOUNT_ID%type;
    taxCodeID               DOC_FOOT_CHARGE.ACS_TAX_CODE_ID%type;
    vatAmount               DOC_FOOT_CHARGE.FCH_VAT_AMOUNT%type;
    ElementType             varchar2(2);
    vAccountInfo            ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    typeCharge              number(1);
    exclusiveDiscountId     PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    exclusiveDiscountAmount DOC_POSITION.POS_DISCOUNT_AMOUNT%type        default 0;
    exclusiveChargeId       PTC_CHARGE.PTC_CHARGE_ID%type;
    exclusiveChargeAmount   DOC_POSITION.POS_CHARGE_AMOUNT%type          default 0;
    lGenerated              number(1);
  begin
    for tplFootChargeInfo in crFootChargeInfo(SourceFootID, TargetFootID) loop
      if    (    tplFootChargeInfo.C_FINANCIAL_CHARGE = '01'
             and tplFootChargeInfo.GAS_TAXE = 1)   -- le tuple est un frais et le gabarit gère les frais
         or (    tplFootChargeInfo.C_FINANCIAL_CHARGE = '02'
             and tplFootChargeInfo.GAS_DISCOUNT = 1)   -- le tuple est une remise et le gabarit gère les remises
         or (    tplFootChargeInfo.C_FINANCIAL_CHARGE = '03'
             and tplFootChargeInfo.GAS_CHARGE = 1) then   -- le tuple est une taxe et le gabarit gère les taxes
        ----
        -- Recherche le code TVA de la charge de pied
        --
        if (tplFootChargeInfo.GAS_VAT = 1) then
          if (tplFootChargeInfo.ACS_TAX_CODE_ID is null) then
            if (tplFootChargeInfo.C_FINANCIAL_CHARGE = '01') then   -- Frais
              typeCharge  := 5;
            elsif(tplFootChargeInfo.C_FINANCIAL_CHARGE = '02') then   -- Remise
              typeCharge  := 3;
            else   -- Taxe
              typeCharge  := 4;
            end if;

            -- Recherche du code Taxe
            taxCodeID  :=
              ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(typeCharge
                                                    , tplFootChargeInfo.PAC_THIRD_VAT_ID
                                                    , 0
                                                    , tplFootChargeInfo.PTC_DISCOUNT_ID
                                                    , tplFootChargeInfo.PTC_CHARGE_ID
                                                    , tplFootChargeInfo.C_ADMIN_DOMAIN
                                                    , tplFootChargeInfo.DIC_TYPE_SUBMISSION_ID
                                                    , tplFootChargeInfo.DIC_TYPE_MOVEMENT_ID
                                                    , tplFootChargeInfo.ACS_VAT_DET_ACCOUNT_ID
                                                     );
            -- Calcul du montant TVA
            vatAmount  :=
              ACS_FUNCTION.CalcVatAmount(tplFootChargeInfo.FCH_EXCL_AMOUNT
                                       , taxCodeID
                                       , 'E'
                                       , tplFootChargeInfo.DMT_DATE_VAT
                                       , to_number(nvl(2 /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/, '0') )
                                        );
          else
            taxCodeID  := tplFootChargeInfo.ACS_TAX_CODE_ID;
            vatAmount  := tplFootChargeInfo.FCH_VAT_AMOUNT;
          end if;
        else
          taxCodeID  := null;
          vatAmount  := 0;
        end if;

        -- Si gestion des comptes financiers ou analytiques
        if    (tplFootChargeInfo.GAS_TARGET_FINANCIAL = 1)
           or (tplFootChargeInfo.GAS_TARGET_ANAL = 1) then
          -- Initialisation des comptes depuis la source
          FinAccountID  := tplFootChargeInfo.ACS_FINANCIAL_ACCOUNT_ID;
          DivAccountID  := tplFootChargeInfo.ACS_DIVISION_ACCOUNT_ID;
          CPNAccountID  := tplFootChargeInfo.ACS_CPN_ACCOUNT_ID;
          CDAAccountID  := tplFootChargeInfo.ACS_CDA_ACCOUNT_ID;
          PFAccountID   := tplFootChargeInfo.ACS_PF_ACCOUNT_ID;
          PJAccountID   := tplFootChargeInfo.ACS_PJ_ACCOUNT_ID;

          if (tplFootChargeInfo.GAU_USE_MANAGED_DATA = 1) then
            vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(tplFootChargeInfo.HRM_PERSON_ID);
            vAccountInfo.FAM_FIXED_ASSETS_ID    := tplFootChargeInfo.FAM_FIXED_ASSETS_ID;
            vAccountInfo.C_FAM_TRANSACTION_TYP  := tplFootChargeInfo.C_FAM_TRANSACTION_TYP;
            vAccountInfo.DEF_DIC_IMP_FREE1      := tplFootChargeInfo.DIC_IMP_FREE1_ID;
            vAccountInfo.DEF_DIC_IMP_FREE2      := tplFootChargeInfo.DIC_IMP_FREE2_ID;
            vAccountInfo.DEF_DIC_IMP_FREE3      := tplFootChargeInfo.DIC_IMP_FREE3_ID;
            vAccountInfo.DEF_DIC_IMP_FREE4      := tplFootChargeInfo.DIC_IMP_FREE4_ID;
            vAccountInfo.DEF_DIC_IMP_FREE5      := tplFootChargeInfo.DIC_IMP_FREE5_ID;
            vAccountInfo.DEF_TEXT1              := tplFootChargeInfo.FCH_IMP_TEXT_1;
            vAccountInfo.DEF_TEXT2              := tplFootChargeInfo.FCH_IMP_TEXT_2;
            vAccountInfo.DEF_TEXT3              := tplFootChargeInfo.FCH_IMP_TEXT_3;
            vAccountInfo.DEF_TEXT4              := tplFootChargeInfo.FCH_IMP_TEXT_4;
            vAccountInfo.DEF_TEXT5              := tplFootChargeInfo.FCH_IMP_TEXT_5;
            vAccountInfo.DEF_NUMBER1            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_1);
            vAccountInfo.DEF_NUMBER2            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_2);
            vAccountInfo.DEF_NUMBER3            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_3);
            vAccountInfo.DEF_NUMBER4            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_4);
            vAccountInfo.DEF_NUMBER5            := to_char(tplFootChargeInfo.FCH_IMP_NUMBER_5);
            vAccountInfo.DEF_DATE1              := tplFootChargeInfo.FCH_IMP_DATE_1;
            vAccountInfo.DEF_DATE2              := tplFootChargeInfo.FCH_IMP_DATE_2;
            vAccountInfo.DEF_DATE3              := tplFootChargeInfo.FCH_IMP_DATE_3;
            vAccountInfo.DEF_DATE4              := tplFootChargeInfo.FCH_IMP_DATE_4;
            vAccountInfo.DEF_DATE5              := tplFootChargeInfo.FCH_IMP_DATE_5;
          else
            vAccountInfo.DEF_HRM_PERSON         := null;
            vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
            vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
            vAccountInfo.DEF_DIC_IMP_FREE1      := null;
            vAccountInfo.DEF_DIC_IMP_FREE2      := null;
            vAccountInfo.DEF_DIC_IMP_FREE3      := null;
            vAccountInfo.DEF_DIC_IMP_FREE4      := null;
            vAccountInfo.DEF_DIC_IMP_FREE5      := null;
            vAccountInfo.DEF_TEXT1              := null;
            vAccountInfo.DEF_TEXT2              := null;
            vAccountInfo.DEF_TEXT3              := null;
            vAccountInfo.DEF_TEXT4              := null;
            vAccountInfo.DEF_TEXT5              := null;
            vAccountInfo.DEF_NUMBER1            := null;
            vAccountInfo.DEF_NUMBER2            := null;
            vAccountInfo.DEF_NUMBER3            := null;
            vAccountInfo.DEF_NUMBER4            := null;
            vAccountInfo.DEF_NUMBER5            := null;
            vAccountInfo.DEF_DATE1              := null;
            vAccountInfo.DEF_DATE2              := null;
            vAccountInfo.DEF_DATE3              := null;
            vAccountInfo.DEF_DATE4              := null;
            vAccountInfo.DEF_DATE5              := null;
          end if;

          -- Type Remise / Taxe / Frais
          select decode(tplFootChargeInfo.C_FINANCIAL_CHARGE, '01', '50', '02', '20', '03', '30')
            into ElementType
            from dual;

          -- Recherche des comptes finance et analytique
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplFootChargeInfo.CHARGE_ID
                                                   , ElementType
                                                   , tplFootChargeInfo.C_ADMIN_DOMAIN
                                                   , tplFootChargeInfo.DMT_DATE_DOCUMENT
                                                   , tplFootChargeInfo.DOC_GAUGE_ID
                                                   , TargetFootID
                                                   , null
                                                   , tplFootChargeInfo.DOC_RECORD_ID
                                                   , tplFootChargeInfo.PAC_THIRD_ACI_ID
                                                   , null
                                                   , null
                                                   , null
                                                   , null
                                                   , null
                                                   , null
                                                   , FinAccountID
                                                   , DivAccountID
                                                   , CPNAccountID
                                                   , CDAAccountID
                                                   , PFAccountID
                                                   , PJAccountID
                                                   , vAccountInfo
                                                    );

          -- Si le gabarit cible ne gère l'imputation analytique
          if (tplFootChargeInfo.GAS_TARGET_ANAL = 0) then
            CPNAccountID  := null;
            CDAAccountID  := null;
            PFAccountID   := null;
            PJAccountID   := null;
          end if;
        end if;

        insert into DOC_FOOT_CHARGE
                    (DOC_FOOT_CHARGE_ID
                   , DOC_FOOT_ID
                   , DOC_FOOT_CHARGE_SRC_ID
                   , C_CHARGE_ORIGIN
                   , C_FINANCIAL_CHARGE
                   , ACS_TAX_CODE_ID
                   , PTC_CHARGE_ID
                   , PTC_DISCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , FCH_DESCRIPTION
                   , FCH_RATE
                   , FCH_EXPRESS_IN
                   , A_DATECRE
                   , A_IDCRE
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , C_ROUND_TYPE
                   , C_CALCULATION_MODE
                   , DOC_DOC_FOOT_CHARGE_ID
                   , FCH_TRANSFERT_PROP
                   , FCH_MODIFY
                   , FCH_IN_SERIES_CALCULATION
                   , FCH_BALANCE_AMOUNT
                   , FCH_NAME
                   , FCH_FIXED_AMOUNT
                   , FCH_FIXED_AMOUNT_B
                   , FCH_FIXED_AMOUNT_E
                   , FCH_EXCEEDED_AMOUNT_FROM
                   , FCH_EXCEEDED_AMOUNT_TO
                   , FCH_MIN_AMOUNT
                   , FCH_MAX_AMOUNT
                   , FCH_IS_MULTIPLICATOR
                   , FCH_EXCLUSIVE
                   , FCH_ROUND_AMOUNT
                   , FCH_STORED_PROC
                   , FCH_AUTOMATIC_CALC
                   , FCH_SQL_EXTERN_ITEM
                   , FCH_EXCL_AMOUNT
                   , FCH_EXCL_AMOUNT_B
                   , FCH_EXCL_AMOUNT_E
                   , FCH_INCL_AMOUNT
                   , FCH_INCL_AMOUNT_B
                   , FCH_INCL_AMOUNT_E
                   , FCH_VAT_AMOUNT
                   , FCH_VAT_BASE_AMOUNT
                   , FCH_VAT_AMOUNT_E
                   , HRM_PERSON_ID
                   , FAM_FIXED_ASSETS_ID
                   , C_FAM_TRANSACTION_TYP
                   , FCH_IMP_TEXT_1
                   , FCH_IMP_TEXT_2
                   , FCH_IMP_TEXT_3
                   , FCH_IMP_TEXT_4
                   , FCH_IMP_TEXT_5
                   , FCH_IMP_NUMBER_1
                   , FCH_IMP_NUMBER_2
                   , FCH_IMP_NUMBER_3
                   , FCH_IMP_NUMBER_4
                   , FCH_IMP_NUMBER_5
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , FCH_IMP_DATE_1
                   , FCH_IMP_DATE_2
                   , FCH_IMP_DATE_3
                   , FCH_IMP_DATE_4
                   , FCH_IMP_DATE_5
                    )
             values (tplFootChargeInfo.DOC_FOOT_CHARGE_ID
                   , TargetFootID   -- DOC_FOOT_ID
                   , tplFootChargeInfo.DOC_FOOT_CHARGE_SRC_ID
                   , aChargeOrigin
                   , tplFootChargeInfo.C_FINANCIAL_CHARGE
                   , taxCodeID
                   , tplFootChargeInfo.PTC_CHARGE_ID
                   , tplFootChargeInfo.PTC_DISCOUNT_ID
                   , decode(FinAccountID, 0, null, FinAccountID)
                   , decode(DivAccountID, 0, null, DivAccountID)
                   , tplFootChargeInfo.FCH_DESCRIPTION
                   , tplFootChargeInfo.FCH_RATE
                   , tplFootChargeInfo.FCH_EXPRESS_IN
                   , tplFootChargeInfo.A_DATECRE
                   , tplFootChargeInfo.A_IDCRE
                   , decode(CPNAccountID, 0, null, CPNAccountID)
                   , decode(CDAAccountID, 0, null, CDAAccountID)
                   , decode(PJAccountID, 0, null, PJAccountID)
                   , decode(PFAccountID, 0, null, PFAccountID)
                   , tplFootChargeInfo.C_ROUND_TYPE
                   , tplFootChargeInfo.C_CALCULATION_MODE
                   , tplFootChargeInfo.DOC_DOC_FOOT_CHARGE_ID
                   , tplFootChargeInfo.FCH_TRANSFERT_PROP
                   , tplFootChargeInfo.FCH_MODIFY
                   , tplFootChargeInfo.FCH_IN_SERIES_CALCULATION
                   , tplFootChargeInfo.FCH_BALANCE_AMOUNT
                   , tplFootChargeInfo.FCH_NAME
                   , tplFootChargeInfo.FCH_FIXED_AMOUNT
                   , tplFootChargeInfo.FCH_FIXED_AMOUNT_B
                   , tplFootChargeInfo.FCH_FIXED_AMOUNT_E
                   , tplFootChargeInfo.FCH_EXCEEDED_AMOUNT_FROM
                   , tplFootChargeInfo.FCH_EXCEEDED_AMOUNT_TO
                   , tplFootChargeInfo.FCH_MIN_AMOUNT
                   , tplFootChargeInfo.FCH_MAX_AMOUNT
                   , tplFootChargeInfo.FCH_IS_MULTIPLICATOR
                   , tplFootChargeInfo.FCH_EXCLUSIVE
                   , tplFootChargeInfo.FCH_ROUND_AMOUNT
                   , tplFootChargeInfo.FCH_STORED_PROC
                   , tplFootChargeInfo.FCH_AUTOMATIC_CALC
                   , tplFootChargeInfo.FCH_SQL_EXTERN_ITEM
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT_B
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT_E
                   , tplFootChargeInfo.FCH_EXCL_AMOUNT + vatAmount
                   , tplFootChargeInfo.FCH_INCL_AMOUNT_B
                   , tplFootChargeInfo.FCH_INCL_AMOUNT_E
                   , vatAmount
                   , tplFootChargeInfo.FCH_VAT_BASE_AMOUNT
                   , tplFootChargeInfo.FCH_VAT_AMOUNT_E
                   , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                   , vAccountInfo.FAM_FIXED_ASSETS_ID
                   , vAccountInfo.C_FAM_TRANSACTION_TYP
                   , vAccountInfo.DEF_TEXT1
                   , vAccountInfo.DEF_TEXT2
                   , vAccountInfo.DEF_TEXT3
                   , vAccountInfo.DEF_TEXT4
                   , vAccountInfo.DEF_TEXT5
                   , to_number(vAccountInfo.DEF_NUMBER1)
                   , to_number(vAccountInfo.DEF_NUMBER2)
                   , to_number(vAccountInfo.DEF_NUMBER3)
                   , to_number(vAccountInfo.DEF_NUMBER4)
                   , to_number(vAccountInfo.DEF_NUMBER5)
                   , vAccountInfo.DEF_DIC_IMP_FREE1
                   , vAccountInfo.DEF_DIC_IMP_FREE2
                   , vAccountInfo.DEF_DIC_IMP_FREE3
                   , vAccountInfo.DEF_DIC_IMP_FREE4
                   , vAccountInfo.DEF_DIC_IMP_FREE5
                   , vAccountInfo.DEF_DATE1
                   , vAccountInfo.DEF_DATE2
                   , vAccountInfo.DEF_DATE3
                   , vAccountInfo.DEF_DATE4
                   , vAccountInfo.DEF_DATE5
                    );

        -- Remise Exclusive
        if     tplFootChargeInfo.PTC_DISCOUNT_ID is not null
           and tplFootChargeInfo.FCH_EXCLUSIVE = 1
           and (   abs(tplFootChargeInfo.FCH_EXCL_AMOUNT) > abs(exclusiveDiscountAmount)
                or exclusiveDiscountId is null) then
          exclusiveDiscountAmount  := tplFootChargeInfo.FCH_EXCL_AMOUNT;
          exclusiveDiscountId      := tplFootChargeInfo.DOC_FOOT_CHARGE_ID;
        end if;

        -- Taxe Exclusive
        if     tplFootChargeInfo.PTC_CHARGE_ID <> 0
           and tplFootChargeInfo.FCH_EXCLUSIVE = 1
           and (   abs(tplFootChargeInfo.FCH_EXCL_AMOUNT) > abs(exclusiveChargeAmount)
                or exclusiveChargeId is null) then
          exclusiveChargeAmount  := tplFootChargeInfo.FCH_EXCL_AMOUNT;
          exclusiveChargeId      := tplFootChargeInfo.DOC_FOOT_CHARGE_ID;
        end if;

        -- Si en décharge et la charge de type montant, Màj la charge parent
        if     (aChargeOrigin = 'DISCH')
           and (tplFootChargeInfo.C_CALCULATION_MODE = '0') then
          update DOC_FOOT_CHARGE
             set FCH_DISCHARGED = 1
           where DOC_FOOT_CHARGE_ID = tplFootChargeInfo.DOC_FOOT_CHARGE_SRC_ID;
        end if;
      end if;
    end loop;

    -- Si on a des remises exclusives, effacement des remises différentes de la plus grande remise exclusive
    if exclusiveDiscountId is not null then
      for tplFootCharges in (select DOC_FOOT_CHARGE_ID
                               from DOC_FOOT_CHARGE
                              where DOC_FOOT_ID = TargetFootID
                                and PTC_DISCOUNT_ID is not null
                                and DOC_FOOT_CHARGE_ID <> exclusiveDiscountId) loop
        DOC_DELETE.DeleteFootCharge(tplFootCharges.DOC_FOOT_CHARGE_ID);
      end loop;
    end if;

    -- Si on a des taxes exclusives, effacement des taxes différentes de la plus grande taxe exclusive
    if exclusiveChargeId is not null then
      for tplFootCharges in (select DOC_FOOT_CHARGE_ID
                               from DOC_FOOT_CHARGE
                              where DOC_FOOT_ID = TargetFootID
                                and PTC_CHARGE_ID is not null
                                and DOC_FOOT_CHARGE_ID <> exclusiveChargeId) loop
        DOC_DELETE.DeleteFootCharge(tplFootCharges.DOC_FOOT_CHARGE_ID);
      end loop;
    end if;

    declare
      newLinkID     DOC_DOCUMENT_LINK.DOC_DOCUMENT_LINK_ID%type;
      intLinkExists integer;
    begin
      select count(DOC_DOCUMENT_LINK_ID)
        into intLinkExists
        from DOC_DOCUMENT_LINK
       where DOC_DOCUMENT_ID = TargetFootID
         and DOC_DOCUMENT_SRC_ID = SourceFootID
         and C_DOCUMENT_LINK = 'FCH-' || aChargeOrigin;

      if intLinkExists = 0 then
        select INIT_ID_SEQ.nextval
          into newLinkID
          from dual;

        -- Màj table de lien copie/décharge charges de pied
        insert into DOC_DOCUMENT_LINK
                    (DOC_DOCUMENT_LINK_ID
                   , DOC_DOCUMENT_ID
                   , DOC_DOCUMENT_SRC_ID
                   , DLK_COUNT
                   , C_DOCUMENT_LINK
                   , A_DATECRE
                   , A_IDCRE
                    )
          select newLinkID
               , TargetFootID
               , SourceFootID
               , count(FCH.DOC_FOOT_CHARGE_ID)
               , 'FCH-' || aChargeOrigin
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from DOC_FOOT_CHARGE FCH
               , DOC_FOOT_CHARGE FCH_SRC
           where FCH.DOC_FOOT_ID = TargetFootID
             and FCH_SRC.DOC_FOOT_ID = SourceFootID
             --and FCH.C_CALCULATION_MODE = '0'
             and FCH.DOC_FOOT_CHARGE_SRC_ID = FCH_SRC.DOC_FOOT_CHARGE_ID;
      end if;
    end;

    declare
      a integer;
      b integer;
    begin
      update    DOC_DOCUMENT
            set DMT_RECALC_FOOT_CHARGE = (select decode(count(*), 0, 0, 1)
                                            from DOC_FOOT_CHARGE
                                           where DOC_FOOT_ID = TargetFootID)
              , DMT_CREATE_FOOT_CHARGE = (select decode(count(*), 0, 1, 0)
                                            from DOC_FOOT_CHARGE
                                           where DOC_FOOT_ID = TargetFootID)
          where DOC_DOCUMENT_ID = TargetFootID
      returning DMT_RECALC_FOOT_CHARGE
           into lGenerated;

      oGenerated  := Byte2Bool(lGenerated);
    end;
  end CopyDischFootCharge;

  /**
  * Description
  *   création d'une remise/taxe de pied
  *   si l'id n'est pas renseigné, la procédure le renseigne automatiquement
  *   les champs A_DATECRE et A_IDCRE sont renseignés automatiquement
  */
  procedure InsertFootCharge(aRecFootCharge in out DOC_FOOT_CHARGE%rowtype)
  is
  begin
    -- initialisation de la taxe qui n'auraient pas été données par l'utilisateur
    select nvl(aRecFootCharge.DOC_FOOT_CHARGE_ID, init_id_seq.nextval)
         , nvl(aRecFootCharge.C_CHARGE_ORIGIN, 'MAN')
         , nvl(aRecFootCharge.FCH_BALANCE_AMOUNT, aRecFootCharge.FCH_EXCL_AMOUNT)
         , nvl(aRecFootCharge.FCH_CALC_AMOUNT, aRecFootCharge.FCH_EXCL_AMOUNT)
         , nvl(aRecFootCharge.FCH_LIABLED_AMOUNT, 0)
         , nvl(aRecFootCharge.FCH_FIXED_AMOUNT_B, 0)
         , nvl(aRecFootCharge.FCH_VAT_AMOUNT, 0)
         , nvl(aRecFootCharge.FCH_EXCEEDED_AMOUNT_FROM, 0)
         , nvl(aRecFootCharge.FCH_EXCEEDED_AMOUNT_TO, 0)
         , nvl(aRecFootCharge.FCH_MIN_AMOUNT, 0)
         , nvl(aRecFootCharge.FCH_MAX_AMOUNT, 0)
         , nvl(aRecFootCharge.C_ROUND_TYPE, '0')
         , nvl(aRecFootCharge.FCH_ROUND_AMOUNT, 0)
         , nvl(aRecFootCharge.FCH_TRANSFERT_PROP, 0)
         , nvl(aRecFootCharge.FCH_MODIFY, 0)
         , nvl(aRecFootCharge.FCH_AUTOMATIC_CALC, 1)
         , nvl(aRecFootCharge.FCH_IS_MULTIPLICATOR, 0)
         , nvl(aRecFootCharge.FCH_EXCLUSIVE, 0)
         , nvl(aRecFootCharge.FCH_RATE, 0)
         , nvl(aRecFootCharge.FCH_EXPRESS_IN, 0)
         , nvl(aRecFootCharge.A_DATECRE, sysdate)
         , nvl(aRecFootCharge.A_IDCRE, PCS.PC_I_LIB_SESSION.GetUserIni)
      into aRecFootCharge.DOC_FOOT_CHARGE_ID
         , aRecFootCharge.C_CHARGE_ORIGIN
         , aRecFootCharge.FCH_BALANCE_AMOUNT
         , aRecFootCharge.FCH_CALC_AMOUNT
         , aRecFootCharge.FCH_LIABLED_AMOUNT
         , aRecFootCharge.FCH_FIXED_AMOUNT_B
         , aRecFootCharge.FCH_VAT_AMOUNT
         , aRecFootCharge.FCH_EXCEEDED_AMOUNT_FROM
         , aRecFootCharge.FCH_EXCEEDED_AMOUNT_TO
         , aRecFootCharge.FCH_MIN_AMOUNT
         , aRecFootCharge.FCH_MAX_AMOUNT
         , aRecFootCharge.C_ROUND_TYPE
         , aRecFootCharge.FCH_ROUND_AMOUNT
         , aRecFootCharge.FCH_TRANSFERT_PROP
         , aRecFootCharge.FCH_MODIFY
         , aRecFootCharge.FCH_AUTOMATIC_CALC
         , aRecFootCharge.FCH_IS_MULTIPLICATOR
         , aRecFootCharge.FCH_EXCLUSIVE
         , aRecFootCharge.FCH_RATE
         , aRecFootCharge.FCH_EXPRESS_IN
         , aRecFootCharge.A_DATECRE
         , aRecFootCharge.A_IDCRE
      from dual;

    -- création de la remise/taxe
    insert into DOC_FOOT_CHARGE
         values aRecFootCharge;
  end InsertFootCharge;

  /**
  * procedure GenerateDischFootCharge
  * Description
  *     Décharge des remises,taxes et frais de pied des docs source selon les positions déchargées
  */
  procedure GenerateDischFootCharge(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, oGenerated out boolean)
  is
    -- Controle si le lien de décharge des foot_charge existe entre les 2 documents
    cursor crLinkExists(cDocID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, cDocSrcID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select count(DOC_DOCUMENT_LINK_ID)
        from DOC_DOCUMENT_LINK
       where DOC_DOCUMENT_ID = cDocID
         and DOC_DOCUMENT_SRC_ID = cDocSrcID
         and C_DOCUMENT_LINK = 'FCH-DISCH';

    DocSrcID       DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    intCountDocSrc integer;
    intLinkExists  integer;
  begin
    oGenerated  := false;

    -- Recherche le nbr de docs déchargés
    select count(distinct PDE_SRC.DOC_DOCUMENT_ID)
      into intCountDocSrc
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION_DETAIL PDE_SRC
     where PDE.DOC_DOCUMENT_ID = aDocumentID
       and PDE.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
       and PDE.DOC_GAUGE_RECEIPT_ID is not null;

    -- Réchercher ID du document source
    if intCountDocSrc = 0 then
      -- Pas de positions déchargées
      -- Recherche id doc source dans la copie entete document
      select DOC_DOCUMENT_SRC_ID
        into DocSrcID
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentID;
    end if;

    -- Réchercher ID du document source
    if intCountDocSrc = 1 then
      -- Une seule position déchargée
      -- Recherche id doc source
      select distinct PDE_SRC.DOC_DOCUMENT_ID
                 into DocSrcID
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION_DETAIL PDE_SRC
                where PDE.DOC_DOCUMENT_ID = aDocumentID
                  and PDE.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
                  and PDE.DOC_GAUGE_RECEIPT_ID is not null;
    end if;

    -- Plusieurs positions déchargées de plusieurs documents
    if intCountDocSrc > 1 then
      -- Plusieurs documents source
      -- Rechercher tous les documents source
      for tplDocSrc in (select distinct PDE_SRC.DOC_DOCUMENT_ID
                                   from DOC_POSITION_DETAIL PDE
                                      , DOC_POSITION_DETAIL PDE_SRC
                                  where PDE.DOC_DOCUMENT_ID = aDocumentID
                                    and PDE.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
                                    and PDE.DOC_GAUGE_RECEIPT_ID is not null) loop
        -- Vérifier si le lien existe entre les 2 documents
        open crLinkExists(aDocumentID, tplDocSrc.DOC_DOCUMENT_ID);

        fetch crLinkExists
         into intLinkExists;

        close crLinkExists;

        -- Pas de lien entre les 2 documents
        if intLinkExists = 0 then
          -- Décharger les charges pied de type montant des docs source
          DOC_DISCOUNT_CHARGE.CopyDischFootCharge(tplDocSrc.DOC_DOCUMENT_ID, aDocumentID, 'DISCH', 1, oGenerated);   -- aOnlyAmountCharges = 1
        end if;
      end loop;
    else
      -- Un seul document source
      if DocSrcID is not null then
        -- Vérifier si le lien existe entre les 2 documents
        open crLinkExists(aDocumentID, DocSrcID);

        fetch crLinkExists
         into intLinkExists;

        close crLinkExists;

        -- Pas de lien entre les 2 documents
        if intLinkExists = 0 then
          -- Décharger toutes les charges du document source
          DOC_DISCOUNT_CHARGE.CopyDischFootCharge(DocSrcID, aDocumentID, 'DISCH', 0, oGenerated);   -- aOnlyAmountCharges = 0
        end if;
      end if;
    end if;
  end GenerateDischFootCharge;

  /**
  * Description
  *      Applique l'arrondi "Swisscom" sur le document
  */
  procedure roundDocumentAmount(
    aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDateRef    in date
  , aCurrencyId in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aLangId     in DOC_DOCUMENT.PC_LANG_ID%type
  )
  is
    cursor crDiscountCharge(astrChargeList varchar2, astrDiscountList varchar2, aLangId number)
    is
      select   DNT.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(DID_DESCR, DNT_NAME) DESCR
             , DNT_NAME PTC_NAME
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , cast(null as varchar2(4000) ) SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE vChargeType
             , DNT_EXCLUSIVE EXCLUSIF
             , 0 PRCS_USE
          from PTC_DISCOUNT DNT
             , PTC_DISCOUNT_DESCR DID
             , (select column_value as PTC_DISCOUNT_ID
                  from table(PCS.idListToTable(astrDiscountList) ) ) DNT_LST
         where DNT.PTC_DISCOUNT_ID = DNT_LST.PTC_DISCOUNT_ID
           and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
           and DID.PC_LANG_ID(+) = aLangId
      union
      select   0 PTC_DISCOUNT_ID
             , CRG.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) SERIES_CALC
             , 1 ORIGINAL
             , nvl(CHD_DESCR, CRG_NAME) DESCR
             , CRG_NAME PTC_NAME
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE vChargeType
             , CRG_EXCLUSIVE EXCLUSIF
             , 0 PRCS_USE
          from PTC_CHARGE CRG
             , PTC_CHARGE_DESCRIPTION CHD
             , (select column_value as PTC_CHARGE_ID
                  from table(PCS.idListToTable(astrChargeList) ) ) CRG_LST
         where CRG.PTC_CHARGE_ID = CRG_LST.PTC_CHARGE_ID
           and CRG.PTC_CHARGE_ID = CHD.PTC_CHARGE_ID(+)
           and CHD.PC_LANG_ID(+) = aLangId
      order by SERIES_CALC
             , PTC_NAME;

    vTplDocument       DOC_DOCUMENT%rowtype;
    vTplFoot           DOC_FOOT%rowtype;
    vChargeType        PTC_CHARGE.C_CHARGE_TYPE%type;
    vAdminDomain       DOC_GAUGE.C_ADMIN_DOMAIN%type;
    vChanged           integer;
    vChargeList        varchar2(200);
    vDiscountList      varchar2(200);
    vPchAmount         DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vLiabledAmount     DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vUnitLiabledAmount DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vChargeAmount      DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vDiscountAmount    DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vDifference        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vFinancialId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivisionId        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCpnId             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCdaId             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPfId              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPjId              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vFootChargeId      DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type;
    vGestValueQuantity DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    vQuantity          DOC_POSITION.POS_FINAL_QUANTITY%type;
    vFinancial         DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical        DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl         DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vTblAccountInfo    ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vTaxCodeID         ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    vDicTypeMovement   DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
    vTTC               number(1);
  begin
    -- ne s'applique que sur les document en francs suisses
    if ACS_FUNCTION.GetCurrencyName(aCurrencyId) = 'CHF' then
      vTTC           := DOC_FUNCTIONS.IsDocumentTTC(aDocumentId);

      -- pointeur sur le pied du document a traîter
      select *
        into vTplDocument
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentId;

      -- recherche d'info dans le gabarit
      select decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
           , C_ADMIN_DOMAIN
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
           , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
           , DIC_TYPE_MOVEMENT_ID
        into vChargeType
           , vAdminDomain
           , vFinancial
           , vAnalytical
           , vInfoCompl
           , vDicTypeMovement
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = vTplDocument.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

      -- recherche des remises/taxes
      PTC_FIND_DISCOUNT_CHARGE.TESTDORDISCOUNTCHARGE(nvl(vTplDocument.DOC_GAUGE_ID, 0)
                                                   , nvl(nvl(vTplDocument.PAC_THIRD_TARIFF_ID, vTplDocument.PAC_THIRD_ID), 0)
                                                   , nvl(vTplDocument.DOC_RECORD_ID, 0)
                                                   , vChargeType
                                                   , aDateRef
                                                   , vChanged   -- vBlnDiscount
                                                    );
      -- récupération de la liste des taxes
      vChargeList    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'DOR');
      -- récupération de la liste des remises
      vDiscountList  := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'DOR');

      if    vChargeList is not null
         or vDiscountList is not null then
        -- recherche une remise/taxes déjà existante
        select max(DOC_FOOT_CHARGE_ID)
          into vFootChargeId
          from DOC_FOOT_CHARGE
         where DOC_FOOT_ID = aDocumentId
           and C_CALCULATION_MODE = '10';

        removeDocumentRoundAmount(aDocumentId);

        -- pointeur sur le pied du document a traîter (rafraichissement)
        select *
          into vTplFoot
          from DOC_FOOT
         where DOC_FOOT_ID = aDocumentId;

        -- recherche du montant à arrondir
        vLiabledAmount  := vTplFoot.FOO_DOCUMENT_TOTAL_AMOUNT;
        vDifference     := ACS_FUNCTION.PcsRound(vLiabledAmount, '1') - vLiabledAmount;

        if vDifference <> 0 then
          -- ouverture d'un query sur les infos des remises/taxes
          for tplDiscountCharge in crDiscountCharge(vChargeList, vDiscountList, aLangId) loop
            -- traitement des taxes
            if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
              vPchAmount  := vDifference;

              -- Si gestion des comptes financiers ou analytiques
              if     (vFootChargeId is null)
                 and (    (vFinancial = 1)
                      or (vAnalytical = 1) ) then
                -- Utilise les comptes de la taxe
                vFinancialId                           := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                vDivisionId                            := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                vCpnId                                 := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                vCdaId                                 := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                vPfId                                  := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                vPjId                                  := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                vTblAccountInfo.DEF_HRM_PERSON         := null;
                vTblAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vTblAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vTblAccountInfo.DEF_TEXT1              := null;
                vTblAccountInfo.DEF_TEXT2              := null;
                vTblAccountInfo.DEF_TEXT3              := null;
                vTblAccountInfo.DEF_TEXT4              := null;
                vTblAccountInfo.DEF_TEXT5              := null;
                vTblAccountInfo.DEF_NUMBER1            := null;
                vTblAccountInfo.DEF_NUMBER2            := null;
                vTblAccountInfo.DEF_NUMBER3            := null;
                vTblAccountInfo.DEF_NUMBER4            := null;
                vTblAccountInfo.DEF_NUMBER5            := null;
                vTblAccountInfo.DEF_DATE1              := null;
                vTblAccountInfo.DEF_DATE2              := null;
                vTblAccountInfo.DEF_DATE3              := null;
                vTblAccountInfo.DEF_DATE4              := null;
                vTblAccountInfo.DEF_DATE5              := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_CHARGE_ID
                                                         , '30'
                                                         , vAdminDomain
                                                         , aDateRef
                                                         , vTplDocument.DOC_GAUGE_ID
                                                         , vTplDocument.DOC_DOCUMENT_ID
                                                         , null
                                                         , vTplDocument.DOC_RECORD_ID
                                                         , vTplDocument.PAC_THIRD_ACI_ID
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , vFinancialId
                                                         , vDivisionId
                                                         , vCpnId
                                                         , vCdaId
                                                         , vPfId
                                                         , vPjId
                                                         , vTblAccountInfo
                                                          );

                if (vAnalytical = 0) then
                  vCpnId  := null;
                  vCdaId  := null;
                  vPjId   := null;
                  vPfId   := null;
                end if;
              end if;
            -- traitement des remises
            else
              vPchAmount  := -vDifference;

              -- Si gestion des comptes financiers ou analytiques
              if     (vFootChargeId is null)
                 and (    (vFinancial = 1)
                      or (vAnalytical = 1) ) then
                -- Utilise les comptes de la remise
                vFinancialId                           := tplDiscountCharge.ACS_FINANCIAL_ACCOUNT_ID;
                vDivisionId                            := tplDiscountCharge.ACS_DIVISION_ACCOUNT_ID;
                vCpnId                                 := tplDiscountCharge.ACS_CPN_ACCOUNT_ID;
                vCdaId                                 := tplDiscountCharge.ACS_CDA_ACCOUNT_ID;
                vPfId                                  := tplDiscountCharge.ACS_PF_ACCOUNT_ID;
                vPjId                                  := tplDiscountCharge.ACS_PJ_ACCOUNT_ID;
                vTblAccountInfo.DEF_HRM_PERSON         := null;
                vTblAccountInfo.FAM_FIXED_ASSETS_ID    := null;
                vTblAccountInfo.C_FAM_TRANSACTION_TYP  := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE1      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE2      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE3      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE4      := null;
                vTblAccountInfo.DEF_DIC_IMP_FREE5      := null;
                vTblAccountInfo.DEF_TEXT1              := null;
                vTblAccountInfo.DEF_TEXT2              := null;
                vTblAccountInfo.DEF_TEXT3              := null;
                vTblAccountInfo.DEF_TEXT4              := null;
                vTblAccountInfo.DEF_TEXT5              := null;
                vTblAccountInfo.DEF_NUMBER1            := null;
                vTblAccountInfo.DEF_NUMBER2            := null;
                vTblAccountInfo.DEF_NUMBER3            := null;
                vTblAccountInfo.DEF_NUMBER4            := null;
                vTblAccountInfo.DEF_NUMBER5            := null;
                vTblAccountInfo.DEF_DATE1              := null;
                vTblAccountInfo.DEF_DATE2              := null;
                vTblAccountInfo.DEF_DATE3              := null;
                vTblAccountInfo.DEF_DATE4              := null;
                vTblAccountInfo.DEF_DATE5              := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscountCharge.PTC_DISCOUNT_ID
                                                         , '20'
                                                         , vAdminDomain
                                                         , aDateRef
                                                         , vTplDocument.DOC_GAUGE_ID
                                                         , vTplDocument.DOC_DOCUMENT_ID
                                                         , null
                                                         , vTplDocument.DOC_RECORD_ID
                                                         , vTplDocument.PAC_THIRD_ACI_ID
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , null
                                                         , vFinancialId
                                                         , vDivisionId
                                                         , vCpnId
                                                         , vCdaId
                                                         , vPfId
                                                         , vPjId
                                                         , vTblAccountInfo
                                                          );

                if (vAnalytical = 0) then
                  vCpnId  := null;
                  vCdaId  := null;
                  vPjId   := null;
                  vPfId   := null;
                end if;
              end if;
            end if;

            -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
            if vFootChargeId is null then
              -- Recherche du code Taxe
              vTaxCodeId  :=
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(vChargeType
                                                      , vTplDocument.PAC_THIRD_VAT_ID
                                                      , 0
                                                      , tplDiscountCharge.PTC_DISCOUNT_ID
                                                      , tplDiscountCharge.PTC_CHARGE_ID
                                                      , vAdminDomain
                                                      , vTplDocument.DIC_TYPE_SUBMISSION_ID
                                                      , vDicTypeMovement
                                                      , vTplDocument.ACS_VAT_DET_ACCOUNT_ID
                                                       );

              insert into DOC_FOOT_CHARGE
                          (DOC_FOOT_CHARGE_ID
                         , DOC_FOOT_ID
                         , C_CHARGE_ORIGIN
                         , C_FINANCIAL_CHARGE
                         , ACS_TAX_CODE_ID
                         , PTC_CHARGE_ID
                         , PTC_DISCOUNT_ID
                         , ACS_FINANCIAL_ACCOUNT_ID
                         , ACS_DIVISION_ACCOUNT_ID
                         , FCH_DESCRIPTION
                         , FCH_RATE
                         , FCH_EXPRESS_IN
                         , ACS_CPN_ACCOUNT_ID
                         , ACS_CDA_ACCOUNT_ID
                         , ACS_PF_ACCOUNT_ID
                         , ACS_PJ_ACCOUNT_ID
                         , C_ROUND_TYPE
                         , FCH_ROUND_AMOUNT
                         , C_CALCULATION_MODE
                         , FCH_TRANSFERT_PROP
                         , FCH_MODIFY
                         , FCH_IN_SERIES_CALCULATION
                         , FCH_BALANCE_AMOUNT
                         , FCH_NAME
                         , FCH_FIXED_AMOUNT_B
                         , FCH_EXCEEDED_AMOUNT_FROM
                         , FCH_EXCEEDED_AMOUNT_TO
                         , FCH_MIN_AMOUNT
                         , FCH_MAX_AMOUNT
                         , FCH_IS_MULTIPLICATOR
                         , FCH_EXCLUSIVE
                         , FCH_STORED_PROC
                         , FCH_AUTOMATIC_CALC
                         , FCH_SQL_EXTERN_ITEM
                         , FCH_EXCL_AMOUNT
                         , FCH_INCL_AMOUNT
                         , FCH_VAT_AMOUNT
                         , HRM_PERSON_ID
                         , FAM_FIXED_ASSETS_ID
                         , C_FAM_TRANSACTION_TYP
                         , FCH_IMP_TEXT_1
                         , FCH_IMP_TEXT_2
                         , FCH_IMP_TEXT_3
                         , FCH_IMP_TEXT_4
                         , FCH_IMP_TEXT_5
                         , FCH_IMP_NUMBER_1
                         , FCH_IMP_NUMBER_2
                         , FCH_IMP_NUMBER_3
                         , FCH_IMP_NUMBER_4
                         , FCH_IMP_NUMBER_5
                         , DIC_IMP_FREE1_ID
                         , DIC_IMP_FREE2_ID
                         , DIC_IMP_FREE3_ID
                         , DIC_IMP_FREE4_ID
                         , DIC_IMP_FREE5_ID
                         , FCH_IMP_DATE_1
                         , FCH_IMP_DATE_2
                         , FCH_IMP_DATE_3
                         , FCH_IMP_DATE_4
                         , FCH_IMP_DATE_5
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (INIT_ID_SEQ.nextval
                         , aDocumentId   -- DOC_FOOT_ID
                         , 'AUTO'
                         , decode(tplDiscountCharge.PTC_CHARGE_ID, 0, '02', '03')
                         , vTaxCodeID
                         , zvl(tplDiscountCharge.PTC_CHARGE_ID, null)
                         , zvl(tplDiscountCharge.PTC_DISCOUNT_ID, null)
                         , vFinancialId
                         , vDivisionId
                         , tplDiscountCharge.Descr
                         , tplDiscountCharge.RATE
                         , tplDiscountCharge.FRACTION
                         , vCpnId
                         , vCdaId
                         , vPfId
                         , vPjId
                         , tplDiscountCharge.C_ROUND_TYPE
                         , tplDiscountCharge.ROUND_AMOUNT
                         , tplDiscountCharge.C_CALCULATION_MODE
                         , 0   -- FCH_TRANSFERT_PROP
                         , 0   -- FCH_MODIFY
                         , 1   -- IN_SERIES_CALCULATION
                         , 0   -- FCH_BALANCE_AMOUNT
                         , tplDiscountCharge.PTC_NAME
                         , 0   -- FCH_FIXED_AMOUNT_B
                         , tplDiscountCharge.EXCEEDED_AMOUNT_FROM
                         , tplDiscountCharge.EXCEEDED_AMOUNT_TO
                         , tplDiscountCharge.MIN_AMOUNT
                         , tplDiscountCharge.MAX_AMOUNT
                         , 0   -- FCH_IS_MULTIPLICATOR
                         , 0   -- FCH_EXCLUSIVE
                         , null   -- FCH_STORED_PROC
                         , tplDiscountCharge.AUTOMATIC_CALC   -- FCH_AUTOMATIC_CALC
                         , tplDiscountCharge.SQL_EXTERN_ITEM   -- FCH_SQL_EXTERN_ITEM
                         , decode(vTTC, 0, vPchAmount)
                         , decode(vTTC, 1, vPchAmount)
                         , 0   --vatAmount
                         , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vTblAccountInfo.DEF_HRM_PERSON)
                         , vTblAccountInfo.FAM_FIXED_ASSETS_ID
                         , vTblAccountInfo.C_FAM_TRANSACTION_TYP
                         , vTblAccountInfo.DEF_TEXT1
                         , vTblAccountInfo.DEF_TEXT2
                         , vTblAccountInfo.DEF_TEXT3
                         , vTblAccountInfo.DEF_TEXT4
                         , vTblAccountInfo.DEF_TEXT5
                         , to_number(vTblAccountInfo.DEF_NUMBER1)
                         , to_number(vTblAccountInfo.DEF_NUMBER2)
                         , to_number(vTblAccountInfo.DEF_NUMBER3)
                         , to_number(vTblAccountInfo.DEF_NUMBER4)
                         , to_number(vTblAccountInfo.DEF_NUMBER5)
                         , vTblAccountInfo.DEF_DIC_IMP_FREE1
                         , vTblAccountInfo.DEF_DIC_IMP_FREE2
                         , vTblAccountInfo.DEF_DIC_IMP_FREE3
                         , vTblAccountInfo.DEF_DIC_IMP_FREE4
                         , vTblAccountInfo.DEF_DIC_IMP_FREE5
                         , vTblAccountInfo.DEF_DATE1
                         , vTblAccountInfo.DEF_DATE2
                         , vTblAccountInfo.DEF_DATE3
                         , vTblAccountInfo.DEF_DATE4
                         , vTblAccountInfo.DEF_DATE5
                         , sysdate
                         , PCS.PC_I_LIB_SESSION.GetUserIni
                          );
            -- remise/taxe déjà existante
            else
              -- mise à 0 de la remise/taxe existante
              update DOC_FOOT_CHARGE
                 set FCH_EXCL_AMOUNT = decode(vTTC, 0, vPchAmount)
                   , FCH_INCL_AMOUNT = decode(vTTC, 1, vPchAmount)
               where DOC_FOOT_CHARGE_ID = vFootChargeId;
            end if;
          end loop;
        -- pas de différence
        else
          -- supression de la remis/taxe d'arrondi
          delete from DOC_FOOT_CHARGE
                where DOC_FOOT_ID = aDocumentId
                  and C_CALCULATION_MODE = '10';
        end if;

        -- mise à jour des montants sur la position
        DOC_FUNCTIONS.UpdateFootTotals(aDocumentId, vChanged);

        update DOC_DOCUMENT
           set DMT_CREATE_FOOT_CHARGE = 0
             , DMT_RECALC_FOOT_CHARGE = 0
         where DOC_DOCUMENT_ID = aDocumentId;
      end if;
    end if;
  end roundDocumentAmount;

  /**
  * Description
  *      Supprime l'arrondi "Swisscom"
  */
  procedure removeDocumentRoundAmount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vChanged integer;
  begin
    -- mise à 0 de la remise/taxe existante
    update DOC_FOOT_CHARGE
       set FCH_EXCL_AMOUNT = 0
         , FCH_INCL_AMOUNT = 0
     where DOC_FOOT_ID = aDocumentId
       and C_CALCULATION_MODE = '10';

    -- mise à jour des montants sur la position
    DOC_FUNCTIONS.UpdateFootTotals(aDocumentId, vChanged);
  end removeDocumentRoundAmount;
end DOC_DISCOUNT_CHARGE;
