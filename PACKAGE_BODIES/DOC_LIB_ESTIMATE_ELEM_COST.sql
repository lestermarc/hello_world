--------------------------------------------------------
--  DDL for Package Body DOC_LIB_ESTIMATE_ELEM_COST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_ESTIMATE_ELEM_COST" 
is
  /**
  * Description
  *    fonction de calcul du pourcentage d'une marge en fonction d'un prix
  *    de vente et d'un prix de revient et d'une quantité.
  *    Le retour est en pourcent (80 et non 0.8)
  */
  function p_calc_margin_rate(in_sale_price in number, in_cost_price in number, in_quantity in number)
    return number
  as
  begin
    if    (in_cost_price = 0)
       or (in_quantity = 0) then
      return 0;
    else
      return ( (in_sale_price -(in_cost_price * in_quantity) ) /(in_cost_price * in_quantity) ) * 100;
    end if;
  end p_calc_margin_rate;

  /**
  * Description
  *    fonction de calcul du montant d'une marge en fonction d'un prix
  *    de vente, d'une quantité et d'un prix de revient.
  */
  function p_calc_margin_amount(in_sale_price in number, in_cost_price in number, in_quantity in number)
    return number
  as
  begin
    return in_sale_price -(in_cost_price * in_quantity);
  end p_calc_margin_amount;

  /**
  * Description
  *    fonction appliquant un pourcentage de marge à un prix. Si null, on considère que la marge vaut 0
  */
  function p_apply_margin_rate(in_price in number, in_margin_rate in number)
    return number
  as
    ln_price number;
  begin
    ln_price  := (1 +(nvl(in_margin_rate, 0) / 100) ) * in_price;
    return ln_price;
  end p_apply_margin_rate;

  /**
  * Description
  *    Cette fonction retourne la clef primaire, le prix de vente réel et le flag option des
  *    éléments de coût des positions non optionnelles du devis dont la clef primaire est
  *    transmise en paramètre
  */
  function getMandatoryPosID(inDocEstimateID in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
    return ttPosInfos
  as
    lttMandatoryPosList ttPosInfos;
  begin
    select   dec.DOC_ESTIMATE_ELEMENT_COST_ID
           , dec.DEC_SALE_PRICE
           , dep.DEP_OPTION
    bulk collect into lttMandatoryPosList
        from DOC_ESTIMATE_ELEMENT_COST dec
           , DOC_ESTIMATE_POS DEP
       where dec.DOC_ESTIMATE_POS_ID = DEP.DOC_ESTIMATE_POS_ID
         and dec.DOC_ESTIMATE_ID = inDocEstimateID
         and dec.DOC_ESTIMATE_POS_ID is not null
         and dep.DEP_OPTION = 0
    order by dec.DEC_SALE_PRICE;

    return lttMandatoryPosList;
  end getMandatoryPosID;

  /**
  * Description
  *    Cette fonction retourne la clef primaire, le prix de vente réel et le flag option des
  *    éléments de coût des positions optionnelles du devis dont la clef primaire est
  *    transmise en paramètre
  */
  function getOptionalPosID(inDocEstimateID in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
    return ttPosInfos
  as
    lttOptionalPosList ttPosInfos;
  begin
    select   dec.DOC_ESTIMATE_ELEMENT_COST_ID
           , dec.DEC_SALE_PRICE
           , dep.DEP_OPTION
    bulk collect into lttOptionalPosList
        from DOC_ESTIMATE_ELEMENT_COST dec
           , DOC_ESTIMATE_POS DEP
       where dec.DOC_ESTIMATE_POS_ID = DEP.DOC_ESTIMATE_POS_ID
         and dec.DOC_ESTIMATE_ID = inDocEstimateID
         and dec.DOC_ESTIMATE_POS_ID is not null
         and dep.DEP_OPTION = 1
    order by dec.DEC_SALE_PRICE;

    return lttOptionalPosList;
  end getOptionalPosID;

  /**
  * Description
  *    fonction de calcul du prix unitaire théorique
  */
  function calc_unit_sale_price_th(
    in_dec_cost_price       in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_unit_margin_rate in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE_TH%type
  is
    ln_dec_unit_sale_price_th DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE_TH%type;
  begin
    ln_dec_unit_sale_price_th  := p_apply_margin_rate(in_price => in_dec_cost_price, in_margin_rate => in_dec_unit_margin_rate);
    return ln_dec_unit_sale_price_th;
  end calc_unit_sale_price_th;

  /**
  * Description
  *    fonction de calcul du prix unitaire réel
  */
  function calc_unit_sale_price(
    in_dec_cost_price       in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_unit_margin_rate in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  is
    ln_dec_unit_sale_price DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type;
  begin
    ln_dec_unit_sale_price  := calc_unit_sale_price_th(in_dec_cost_price => in_dec_cost_price, in_dec_unit_margin_rate => in_dec_unit_margin_rate);
    return ln_dec_unit_sale_price;
  end calc_unit_sale_price;

  /**
  * Description
  *    fonction de calcul du montant de la marge unitaire.
  */
  function calc_unit_margin_amount(
    in_dec_cost_price      in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_unit_sale_price in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_AMOUNT%type
  as
  begin
    return p_calc_margin_amount(in_sale_price => in_dec_unit_sale_price, in_cost_price => in_dec_cost_price, in_quantity => 1);
  end calc_unit_margin_amount;

  /**
  * Description
  *    fonction de calcul du pourcentage de la marge unitaire.
  */
  function calc_unit_margin_rate(
    in_dec_cost_price      in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_unit_sale_price in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type
  as
  begin
    return p_calc_margin_rate(in_sale_price => in_dec_unit_sale_price, in_cost_price => in_dec_cost_price, in_quantity => 1);
  end calc_unit_margin_rate;

  /**
  * Description
  *    fonction de calcul du prix de vente via unité
  */
  function calc_sale_price_th(
    in_dec_unit_sale_price in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  , in_dec_quantity        in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE_TH%type
  as
  begin
    return in_dec_unit_sale_price * in_dec_quantity;
  end calc_sale_price_th;

  /**
  * Description
  *    fonction de calcul du prix de vente réel
  */
  function calc_sale_price(
    in_dec_unit_sale_price in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  , in_dec_quantity        in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type
  as
    ln_dec_sale_price DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type;
  begin
    ln_dec_sale_price  := calc_sale_price_th(in_dec_unit_sale_price => in_dec_unit_sale_price, in_dec_quantity => in_dec_quantity);
    return ln_dec_sale_price;
  end calc_sale_price;

  /**
  * Description
  *    fonction de calcul du montant de la marge
  */
  function calc_margin_amount(
    in_dec_sale_price in DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type
  , in_dec_quantity   in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  , in_dec_cost_price in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT%type
  as
    ln_dec_margin_amount DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT%type;
  begin
    ln_dec_margin_amount  := in_dec_sale_price -(in_dec_quantity * in_dec_cost_price);
    return ln_dec_margin_amount;
  end calc_margin_amount;

  /**
  * Description
  *    fonction de calcul du montant de la marge corrigée
  */
  function calc_margin_amount_corr(
    in_dec_sale_price_corr in DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE_CORR%type
  , in_dec_quantity        in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  , in_dec_cost_price      in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT_CORR%type
  as
  begin
    return p_calc_margin_amount(in_sale_price => in_dec_sale_price_corr, in_cost_price => in_dec_cost_price, in_quantity => in_dec_quantity);
  end calc_margin_amount_corr;

  /**
  * Description
  *    fonction de calcul du pourcentage de la marge
  */
  function calc_margin_rate(
    in_dec_sale_price in DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type
  , in_dec_cost_price in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_quantity   in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_RATE%type
  as
  begin
    return p_calc_margin_rate(in_sale_price => in_dec_sale_price, in_cost_price => in_dec_cost_price, in_quantity => in_dec_quantity);
  end calc_margin_rate;

  /**
  * Description
  *    fonction de calcul du pourcentage de la marge corrigée
  */
  function calc_margin_rate_corr(
    in_dec_sale_price_corr in DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE_CORR%type
  , in_dec_cost_price      in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_quantity        in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_RATE%type
  as
  begin
    return p_calc_margin_rate(in_sale_price => in_dec_sale_price_corr, in_cost_price => in_dec_cost_price, in_quantity => in_dec_quantity);
  end calc_margin_rate_corr;

  /**
  * Description
  *    fonction de calcul de la somme des prix de revient des lignes de composants
  *    pour une ligne de devis.
  */
  function calc_sum_cost_prices(in_doc_estimate_pos_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type)
    return DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  as
    lnDecCostPricesSum DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
  begin
    /* Somme des prix de revient unitaires * la quantité des lignes de composants rattachés à la position */
    select nvl(sum( (dec.DEC_COST_PRICE * dec.DEC_QUANTITY) ), 0)
      into lnDecCostPricesSum
      from DOC_ESTIMATE_ELEMENT_COST dec inner join DOC_ESTIMATE_ELEMENT DED on dec.DOC_ESTIMATE_ELEMENT_ID = DED.DOC_ESTIMATE_ELEMENT_ID
     where DED.DOC_ESTIMATE_POS_ID = in_doc_estimate_pos_id;

    return lnDecCostPricesSum;
  end calc_sum_cost_prices;

  /**
  * Description
  *    fonction de calcul de la somme des prix de vente théoriques des positions de composants
  *    pour une position de devis. Si une marge a été définie pour la position de devis, celle-ci
  *    est appliquée au prix de vente théorique de la position de devis.
  */
  function calc_sum_unit_sale_price_th(
    in_doc_estimate_pos_id  in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type
  , in_dec_unit_margin_rate in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE_TH%type
  as
    lnDecUnitSalePriceThSum DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE_TH%type;
  begin
    /* Somme des prix de vente réelles des lignes de composants rattachés à la position */
    select nvl(sum(dec.DEC_SALE_PRICE_TH), 0)
      into lnDecUnitSalePriceThSum
      from DOC_ESTIMATE_ELEMENT_COST dec inner join DOC_ESTIMATE_ELEMENT DED on dec.DOC_ESTIMATE_ELEMENT_ID = DED.DOC_ESTIMATE_ELEMENT_ID
     where DED.DOC_ESTIMATE_POS_ID = in_doc_estimate_pos_id;

    return lnDecUnitSalePriceThSum;
  end calc_sum_unit_sale_price_th;

  /**
  * Description
  *    fonction de calcul de la somme des prix de vente réels des positions de composants
  *    pour une position de devis. Si une marge a été d‚finie pour la position de devis, celle-ci
  *    est appliquée au prix de vente réel de la position de devis.
  */
  function calc_sum_unit_sale_price(
    in_doc_estimate_pos_id  in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type
  , in_dec_unit_margin_rate in DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  as
    lnDecUnitSalePriceSum DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type;
  begin
    /* Somme des prix de vente unitaires réels des lignes de composants rattachés à la position */
    select nvl(sum(dec.DEC_SALE_PRICE), 0)
      into lnDecUnitSalePriceSum
      from DOC_ESTIMATE_ELEMENT_COST dec inner join DOC_ESTIMATE_ELEMENT DED on dec.DOC_ESTIMATE_ELEMENT_ID = DED.DOC_ESTIMATE_ELEMENT_ID
     where DED.DOC_ESTIMATE_POS_ID = in_doc_estimate_pos_id;

    return lnDecUnitSalePriceSum;
  end calc_sum_unit_sale_price;

  /**
  * Description
  *    fonction de calcul du prix de revient unitaire de l'ensemble du devis
  */
  function calc_foot_cost_price(in_doc_estimate_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
    return DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  as
    lnFootCostPrice DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
--     ln_foot_cost_price DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
  begin
    -- Somme des prix de revient unitaire * la quantité des positions du devis (sans les positions de composants).
    select sum( (DEC_COST_PRICE * DEC_QUANTITY) )
      into lnFootCostPrice
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ID = in_doc_estimate_id
       and DOC_ESTIMATE_POS_ID is not null;

    return lnFootCostPrice;
  end calc_foot_cost_price;

  /**
  * Description
  *    fonction de calcul du prix de vente réel de l'ensemble du devis
  */
  function calc_foot_sale_price(in_doc_estimate_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
    return DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type
  as
    lnFootSalePrice DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type;
--     ln_foot_sale_price DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type;
  begin
    -- Somme des prix de ventes des positions du devis (sans les positions de composants).
    select sum( (DEC_SALE_PRICE) )
      into lnFootSalePrice
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ID = in_doc_estimate_id
       and DOC_ESTIMATE_POS_ID is not null;

    return lnFootSalePrice;
  end calc_foot_sale_price;

  /**
  * Description
  *    fonction de calcul du prix de vente corrigé de l'ensemble du devis
  */
  function calc_foot_sale_price_corr(in_doc_estimate_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
    return DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE_CORR%type
  as
    lnDecSalePriceCorr DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE_CORR%type;
  begin
    -- Somme des prix de ventes corrigés des positions du devis (sans les positions de composants).
    select sum( (DEC_SALE_PRICE_CORR) )
      into lnDecSalePriceCorr
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ID = in_doc_estimate_id
       and DOC_ESTIMATE_POS_ID is not null;

    return lnDecSalePriceCorr;
  end calc_foot_sale_price_corr;

  /**
  * Description
  *    fonction de calcul du montant de la marge de l'ensemble du devis
  */
  function calc_foot_margin_amount(in_doc_estimate_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT%type
  as
    lnFootMarginAmount DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT%type;
--     ln_foot_margin_amount DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT%type;
  begin
    -- Somme des montants des marges des lignes du devis (sans les positions de composants).
    select sum( (DEC_MARGIN_AMOUNT) )
      into lnFootMarginAmount
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ID = in_doc_estimate_id
       and DOC_ESTIMATE_POS_ID is not null;

    return lnFootMarginAmount;
  end calc_foot_margin_amount;

  /**
  * Description
  *    fonction de calcul du pourcentage de la marge de l'ensemble du devis
  */
  function calc_foot_margin_rate(
    in_dec_sale_price in DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type
  , in_dec_cost_price in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_quantity   in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type   -- inutile, mais déjà utilisé dans delphi
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_RATE%type
  as
  begin
    return p_calc_margin_rate(in_sale_price => in_dec_sale_price, in_cost_price => in_dec_cost_price, in_quantity => 1);
  end calc_foot_margin_rate;

  /**
  * Description
  *    fonction de calcul du montant de la marge corrigée de l'ensemble du devis
  */
  function calc_foot_margin_amount_corr(in_doc_estimate_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT_CORR%type
  as
    lnFootMarginAmountCorr DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_AMOUNT_CORR%type;
  begin
    select sum( (DEC_MARGIN_AMOUNT_CORR) )
      into lnFootMarginAmountCorr
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ID = in_doc_estimate_id
       and DOC_ESTIMATE_POS_ID is not null;

    return lnFootMarginAmountCorr;
  end calc_foot_margin_amount_corr;

  /**
  * Description
  *    fonction de calcul du pourcentage de la marge corrigée de l'ensemble du devis
  */
  function calc_foot_margin_rate_corr(
    in_dec_sale_price_corr in DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE_CORR%type
  , in_dec_cost_price      in DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type
  , in_dec_quantity        in DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type   -- inutile, mais déjà utilisé dans delphi
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_MARGIN_RATE_CORR%type
  as
  begin
    return p_calc_margin_rate(in_sale_price => in_dec_sale_price_corr, in_cost_price => in_dec_cost_price, in_quantity => 1);
  end calc_foot_margin_rate_corr;

  /**
  * Description
  *     fonction retournant "true" si la position dont la clef primaire est transmise en paramètre
  *     contient des enfants.
  */
  function has_children(in_doc_estimate_pos_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type)
    return boolean
  as
  begin
    return GetChildrenNumber(inEstimatePosID => in_doc_estimate_pos_id) > 0;
  end has_children;

  /**
  * Description
  *     Cette fonction retourne le nombre de positions "enfant" de la position dont la clef primaire
  *     est transmise en paramètre.
  */
  function GetChildrenNumber(inEstimatePosID in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type)
    return number
  as
    lnChildrenNumber number default 0;
  begin
    select count(DOC_ESTIMATE_ELEMENT_COST_ID)
      into lnChildrenNumber
      from DOC_ESTIMATE_ELEMENT_COST dec inner join DOC_ESTIMATE_ELEMENT DED on dec.DOC_ESTIMATE_ELEMENT_ID = DED.DOC_ESTIMATE_ELEMENT_ID
     where DED.DOC_ESTIMATE_POS_ID = inEstimatePosID;

    return lnChildrenNumber;
  end GetChildrenNumber;

  /**
  * Description
  *    Cette fonction contrôle s'il y a des champs qui ont été modifiés
  */
  function IsElementCostModified(iotEstimateElementCost in fwk_i_typ_definition.t_crud_def)
    return boolean
  is
    lbModified boolean := false;
  begin
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_COST_PRICE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_GLOBAL_MARGIN_AMOUNT')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_MARGIN_AMOUNT')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_MARGIN_AMOUNT_CORR')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_MARGIN_RATE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_MARGIN_RATE_CORR')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_QUANTITY')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_REF_QTY')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_CONVERSION_FACTOR')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_SALE_PRICE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_SALE_PRICE_CORR')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_SALE_PRICE_TH')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_UNIT_MARGIN_AMOUNT')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_UNIT_MARGIN_RATE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_UNIT_SALE_PRICE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_UNIT_SALE_PRICE_TH') then
      lbModified  := true;
    end if;

    return lbModified;
  end IsElementCostModified;

  /**
  * Description
  *    Retourne la quantité du composant calculée en fonction de la quantité de référence et du facteur de conversion.
  *    Exemple : 10 [kg] (Qté de référence) = 5000 [Pièces] (facteur de conversion)
  */
  function calc_comp_quantity(
    iRefQty          in DOC_ESTIMATE_ELEMENT_COST.DEC_REF_QTY%type
  , iConverionFactor in DOC_ESTIMATE_ELEMENT_COST.DEC_CONVERSION_FACTOR%type
  )
    return DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  as
    lQuantity DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type;
  begin
    lQuantity  := iRefQty / nvl(iConverionFactor, 1);
    return lQuantity;
  exception
    when zero_divide then
      /* Le facteur de conversion est à 0. On considère donc qu'il vaut 1 */
      return iRefQty;
  end calc_comp_quantity;
end DOC_LIB_ESTIMATE_ELEM_COST;
