--------------------------------------------------------
--  DDL for Package Body DOC_PRC_ESTIMATE_ELEM_COST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_ESTIMATE_ELEM_COST" 
is
  /**
  * Description
  *    Cette proc�dure met � jour le prix de vente corrig� de la position (T_CRUD_DEF)
  */
  procedure pUpdPosWithGlobalMargin(
    inAmount    in            DOC_ESTIMATE_ELEMENT_COST.DEC_GLOBAL_MARGIN_AMOUNT%type
  , iotCRUD_DEF in out nocopy fwk_i_typ_definition.t_crud_def
  )
  as
  begin
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotCRUD_DEF, 'DEC_SALE_PRICE_CORR',(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotCRUD_DEF, 'DEC_SALE_PRICE') + inAmount) );
  end pUpdPosWithGlobalMargin;

  /**
  * Description
  *    Cette fonction contr�le si un recalcul est n�cessaire pour la position r�capitulative
  *    du devis. Si oui, renvoie true.
  */
  function isRecalcRecapPosNeeded(iotEstimateElementCostCRUD_DEF in out nocopy fwk_i_typ_definition.t_crud_def)
    return boolean
  as
    lbIsRecalcNeeded boolean := false;
  begin
    /* Si la clef primaire de l'�l�ment n'est pas nulle */
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCostCRUD_DEF, 'DOC_ESTIMATE_ELEMENT_ID') then
      /* Si suppression ou modification du prix de vente r�el (Donc y.c. toutes les modifications qui
        impliquent la modif. du prix de vente r�el) */
      if    (iotEstimateElementCostCRUD_DEF.update_mode = FWK_I_TYP_DEFINITION.deleting)
         or (FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCostCRUD_DEF, 'DEC_SALE_PRICE') ) then
        lbIsRecalcNeeded  := true;
      end if;
    end if;

    return lbIsRecalcNeeded;
  end isRecalcRecapPosNeeded;

  /**
  * Description
  *    Cette fonction contr�le si un recalcul est n�cessaire pour les �l�ments de co�t du devis
  *    (position de pied). Si oui, renvoie true.
  */
  function isRecalcFootPosNeeded(iotEstimateElementCostCRUD_DEF in out nocopy fwk_i_typ_definition.t_crud_def)
    return boolean
  as
    lbIsRecalcNeeded boolean := false;
  begin
    /* Si la clef primaire de la position n'est pas nulle */
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCostCRUD_DEF, 'DOC_ESTIMATE_POS_ID') then
      /* Si suppression ou modification du prix de vente r�el (Donc y.c. toutes les modifications qui
        impliquent la modif. du prix de vente r�el) */
      if    (iotEstimateElementCostCRUD_DEF.update_mode = FWK_I_TYP_DEFINITION.deleting)
         or (FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCostCRUD_DEF, 'DEC_SALE_PRICE_TH') )
         or (FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCostCRUD_DEF, 'DEC_SALE_PRICE') ) then
        lbIsRecalcNeeded  := true;
      end if;
    /* Si la clef primaire de la position de pied n'est pas nulle */
    end if;

    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCostCRUD_DEF, 'DOC_ESTIMATE_FOOT_ID') then
      /* Si le montant de la marge globale � rajouter est modifi�e */
      if (FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCostCRUD_DEF, 'DEC_GLOBAL_MARGIN_AMOUNT') ) then
        lbIsRecalcNeeded  := true;
      end if;
    end if;

    return lbIsRecalcNeeded;
  end isRecalcFootPosNeeded;

  /**
  * Description
  *    proc�dure de recalcul des �l�ments de co�t devis
  */
  procedure recalc_element_cost(iot_estimate_element_cost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    /*--------------------------------------------------------------------------
    * Position de pied de devis. (Montants r�capitulatif de pieds de devis).
    * R�gles de calcul 20
    *-------------------------------------------------------------------------*/
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DOC_ESTIMATE_FOOT_ID') then
      /* Si pas suppression */
      if not(iot_estimate_element_cost.update_mode = FWK_I_TYP_DEFINITION.deleting) then
        calc_cost_pos_foot(iot_estimate_element_cost => iot_estimate_element_cost);
      end if;
    /*--------------------------------------------------------------------------
    * Position de composants (Composants ou main d'oeuvres). R�gle de calcul 11
    *-------------------------------------------------------------------------*/
    elsif not FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DOC_ESTIMATE_ELEMENT_ID') then
      /* Si pas suppression */
      if not(iot_estimate_element_cost.update_mode = FWK_I_TYP_DEFINITION.deleting) then
        calc_cost_pos_without_children(iot_estimate_element_cost => iot_estimate_element_cost);
      end if;
    /*--------------------------------------------------------------------------
    * Position de devis (avec ou sans enfants)
    *-------------------------------------------------------------------------*/
    elsif not FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DOC_ESTIMATE_POS_ID') then
      /* Si pas suppression */
      if not(iot_estimate_element_cost.update_mode = FWK_I_TYP_DEFINITION.deleting) then
        /*------------------------------------------------------------------------
        * Positon de devis avec enfants de type 9B ou 9C
        * (r�cap. des composants ou mains d'oeuvre des �l�m. de pos. ratach�s
        * � cette ligne). R�gle de calcul 17
        *-----------------------------------------------------------------------*/
        if (doc_lib_estimate_elem_cost.has_children(in_doc_estimate_pos_id   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                    , 'DOC_ESTIMATE_POS_ID'
                                                                                                                     )
                                                   )
           ) then
          -- Recalcul des montants de la position
          calc_cost_pos_with_children(iot_estimate_element_cost => iot_estimate_element_cost);
        /*------------------------------------------------------------------------
        * Position sans enfants de type 9A
        *-----------------------------------------------------------------------*/
        else
          -- Recalcul des montants de la position
          calc_cost_pos_without_children(iot_estimate_element_cost => iot_estimate_element_cost);
        end if;
      end if;
    end if;
  end recalc_element_cost;

  /**
  * Description
  *    proc�dure appliquant les r�gles de recalcul des positions de devis du type :
  *     - position contenant un produit fini ou semi-fini.
  *     - position de composants (de deux natures : composants mat�riels ou maind'oeuvre).
  */
  procedure calc_cost_pos_without_children(iot_estimate_element_cost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
/*
--------------------------------------------------------------------------------
Sur cr�ation/modification/supression d'une position de devis "standard" (prod. fini ou composant)
--------------------------------------------------------------------------------
 ********** Pour les deux types **********
--> Si le prix de revient (dec_cost_price) et/ou pourcentage de la marge unitaire (dec_unit_margin_rate) sont/est modifi�(s)
      o On recalcule le prix de vente unitaire th�orique (dec_unit_sale_price_th)
      o On recalcule le prix de vente unitaire r�el (dec_unit_sale_price) si pas modifi�

--> Si le prix de vente unitaire r�el (dec_unit_sale_price) est modifi�
      o On recalcule le montant de la marge unitaire (dec_unit_margin_amount)
      o On recalcule le prix de vente via unit� (dec_sale_price_th)
      o On recalcule le prix de vente r�el (dec sale_price) si pas modifi�

 ********** Si composant **********
--> Si la Quantit� de r�f�rence (dec_ref_qty) et/ou le facteur de conversion (dec_conversion_factor) est/sont modifi�(s)
      o On recalcule la quantit� (dec_quantity)

 ********** Pour les deux types **********
--> Si la quanit� (dec_quanity) est modifi�e
      o On recalcule le prix de vente via unit� (dec_sale_price_th)
      o On recalcule le prix de vente r�el (dec sale_price) si pas modifi�

-- > Si le prix de vente r�el (dec_sale_price) est modifi�
      o On recalcule le montant de la marge (dec_margin_amount)
      o On recalcule le pourcentage de la marge (dec_margin_rate) si pas modifi�

 ********** Si produit fini **********

--> Si le prix de vente corrig� (dec_sale_price_corr) a �t� modifi� et n'est pas null
      o On recalcule le montant de la marge corrig� (dec_margin_amount_corr)
      o On recalcule le pourcentage de la marge corrig�e (dec_margin_rate_corr)

--------------------------------------------------------------------------------
*/  -- Si le prix de revient (dec_cost_price) et/ou pourcentage de la marge unitaire (dec_unit_margin_rate) sont/est modifi�(s)
    if (    (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_COST_PRICE') )
        or (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_MARGIN_RATE') )
       ) then
      -- On recalcule le prix de vente unitaire th�orique (dec_unit_sale_price_th)
      FWK_I_MGT_ENTITY_DATA.setcolumn
            (iot_estimate_element_cost
           , 'DEC_UNIT_SALE_PRICE_TH'
           , doc_lib_estimate_elem_cost.calc_unit_sale_price_th(in_dec_cost_price         => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                              , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_UNIT_MARGIN_RATE'
                                                                                                                                  )
                                                               )
            );

      -- On recalcule le prix de vente unitaire r�el (dec_unit_sale_price) si pas modifi�
      if not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_SALE_PRICE') ) then
        FWK_I_MGT_ENTITY_DATA.setcolumn
               (iot_estimate_element_cost
              , 'DEC_UNIT_SALE_PRICE'
              , doc_lib_estimate_elem_cost.calc_unit_sale_price(in_dec_cost_price         => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                              , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_UNIT_MARGIN_RATE'
                                                                                                                                  )
                                                               )
               );
      end if;
    end if;

    -- Si le prix de vente unitaire r�el (dec_unit_sale_price) est modifi�
    if (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_SALE_PRICE') ) then
      -- On recalcule le montant de la marge unitaire (dec_unit_margin_amount)
      FWK_I_MGT_ENTITY_DATA.setcolumn
             (iot_estimate_element_cost
            , 'DEC_UNIT_MARGIN_AMOUNT'
            , doc_lib_estimate_elem_cost.calc_unit_margin_amount(in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                               , in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                  )
                                                                )
             );
      -- On recalcule le prix de vente via unit� (dec_sale_price_th)
      FWK_I_MGT_ENTITY_DATA.setcolumn
                  (iot_estimate_element_cost
                 , 'DEC_SALE_PRICE_TH'
                 , doc_lib_estimate_elem_cost.calc_sale_price_th(in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                  )
                                                               , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_QUANTITY'
                                                                                                                                  )
                                                                )
                  );

      -- On recalcule le prix de vente r�el (dec sale_price) si pas modifi�
      if not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE') ) then
        FWK_I_MGT_ENTITY_DATA.setcolumn
                    (iot_estimate_element_cost
                   , 'DEC_SALE_PRICE'
                   , doc_lib_estimate_elem_cost.calc_sale_price(in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                 )
                                                              , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                               )
                    );
      end if;
    end if;

    /********** Si composant **********/
    --> Si la Quantit� de r�f�rence (dec_ref_qty) et/ou le facteur de conversion (dec_conversion_factor) est/sont modifi�(s)
    if     (not FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DOC_ESTIMATE_ELEMENT_ID') )
       and (    (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_REF_QTY') )
            or (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_CONVERSION_FACTOR') )
           ) then
      --> On recalcule la quantit� (dec_quantity) si pas d�finie.
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_QUANTITY') then
      FWK_I_MGT_ENTITY_DATA.setcolumn
                        (iot_estimate_element_cost
                       , 'DEC_QUANTITY'
                       , DOC_LIB_ESTIMATE_ELEM_COST.calc_comp_quantity(iRefQty            => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_REF_QTY'
                                                                                                                                  )
                                                                     , iConverionFactor   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_CONVERSION_FACTOR'
                                                                                                                                  )
                                                                      )
                        );
      end if;
    end if;

/**********************************/

    -- Si la quanit� (dec_quanity) est modifi�e
    if (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_QUANTITY') ) then
      -- On recalcule le prix de vente via unit� (dec_sale_price_th)
      FWK_I_MGT_ENTITY_DATA.setcolumn
                 (iot_estimate_element_cost
                , 'DEC_SALE_PRICE_TH'
                , doc_lib_estimate_elem_cost.calc_sale_price_th(in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                 )
                                                              , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                               )
                 );

      -- On recalcule le prix de vente r�el (dec sale_price) si pas modifi�
      if not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE') ) then
        FWK_I_MGT_ENTITY_DATA.setcolumn
                    (iot_estimate_element_cost
                   , 'DEC_SALE_PRICE'
                   , doc_lib_estimate_elem_cost.calc_sale_price(in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                 )
                                                              , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                               )
                    );
      end if;
    end if;

    --> Si le prix de vente r�el (dec_sale_price) est modifi�
    if (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE') ) then
      -- On recalcule le montant de la marge (dec_margin_amount)
      FWK_I_MGT_ENTITY_DATA.setcolumn
                      (iot_estimate_element_cost
                     , 'DEC_MARGIN_AMOUNT'
                     , doc_lib_estimate_elem_cost.calc_margin_amount(in_dec_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_SALE_PRICE'
                                                                                                                                 )
                                                                   , in_dec_quantity     => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                                   , in_dec_cost_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_COST_PRICE'
                                                                                                                                 )
                                                                    )
                      );

      -- On recalcule le pourcentage de la marge (dec_margin_rate) si pas modifi�
      if not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_MARGIN_RATE') ) then
        FWK_I_MGT_ENTITY_DATA.setcolumn
                        (iot_estimate_element_cost
                       , 'DEC_MARGIN_RATE'
                       , doc_lib_estimate_elem_cost.calc_margin_rate(in_dec_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_SALE_PRICE'
                                                                                                                                 )
                                                                   , in_dec_cost_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_COST_PRICE'
                                                                                                                                 )
                                                                   , in_dec_quantity     => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                                    )
                        );
      end if;
    end if;

    -- Si ***** Produit fini ***** et prix de vente corrig� (dec_sale_price_corr) a �t� modifi� et n'est pas null
    if (     (FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DOC_ESTIMATE_ELEMENT_ID') )
        and (not(FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DEC_SALE_PRICE_CORR') ) )
        and (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE_CORR') )
       ) then
      -- On recalcule le montant de la marge corrig� (dec_margin_amount_corr)
      FWK_I_MGT_ENTITY_DATA.setcolumn
            (iot_estimate_element_cost
           , 'DEC_MARGIN_AMOUNT_CORR'
           , doc_lib_estimate_elem_cost.calc_margin_amount_corr(in_dec_sale_price_corr   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_SALE_PRICE_CORR'
                                                                                                                                 )
                                                              , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                              , in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_COST_PRICE'
                                                                                                                                 )
                                                               )
            );
      -- On recalcule le pourcentage de la marge corrig�e (dec_margin_rate_corr)
      FWK_I_MGT_ENTITY_DATA.setcolumn
               (iot_estimate_element_cost
              , 'DEC_MARGIN_RATE_CORR'
              , doc_lib_estimate_elem_cost.calc_margin_rate_corr(in_dec_sale_price_corr   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_SALE_PRICE_CORR'
                                                                                                                                  )
                                                               , in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                               , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_QUANTITY'
                                                                                                                                  )
                                                                )
               );
    end if;
  end calc_cost_pos_without_children;

  /**
  * Description
  *     Proc�dure appliquant les r�gles de recalcul des positions de devis r�capitulatives de deux types :
  *     - position contenant un produit fabriqu� (calcul d'apr�s les sous-positions de type composant (main d'oeuvre ou composants)
  *     - position sans cr�ation de produit. (calcul d'apr�s les sous-positions de type composant (main d'oeuvre uniquement)
  */
  procedure calc_cost_pos_with_children(iot_estimate_element_cost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
/*
--------------------------------------------------------------------------------
Sur cr�ation/modification/supression d'une position de devis r�capitulative
--------------------------------------------------------------------------------

--> Si le prix de revient et/ou le prix de vente th�orique unitaire et/ou le prix de vente unitaire r�el est/sont modifi�(s)
      o On recalcule le montant de la marge unitaire. (dec_unit_margin_amount)

--> Si le pourcentage de la marge unitaire (dec_unit_margin_rate) est modifi�  et n'est pas null
      o Application de cette marge sur le prix de vente unitaire th�orique (dec_unit_sale_price_th)
      o Application de cette marge sur le prix de vente unitaire r�el (dec_unit_sale_price) si pas modifi�
      o On recalcule le montant de la marge unitaire. (dec_unit_margin_amount)

--> Si la quantit� (dec_quantity) est modifi�e ou si la quantit� n'est pas nulle ET qu'un des montants unitaire, co�t ou marge sont modifi�
      o On recalcule le prix de vente via quantit� (dec_sale_price_th)
      o On recalcule le prix de vente r�el (dec_sale_price) si pas modifi�.
      o On recalcule le montant de la marge (dec_margin_amount)
      o On recalcule le pourcentage de la marge (dec_margin_rate) si pas modifi�

--> Si le prix de vente corrig� (dec_sale_price_corr) a �t� modifi� et n'est pas null
      o On recalcule le montant de la marge corrig� (dec_margin_amount_corr)
      o On recalcule le pourcentage de la marge corrig�e (dec_margin_rate_corr)

--------------------------------------------------------------------------------
*/  -- Si le prix de revient et/ou le prix de vente th�orique unitaire et/ou le prix de vente unitaire r�el est/sont modifi�(s)
    if (    (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_COST_PRICE') )
        or (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_SALE_PRICE_TH') )
        or (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_SALE_PRICE') )
       ) then
      -- On recalcule le montant de la marge unitaire. (dec_unit_margin_amount)
      FWK_I_MGT_ENTITY_DATA.setcolumn
             (iot_estimate_element_cost
            , 'DEC_UNIT_MARGIN_AMOUNT'
            , doc_lib_estimate_elem_cost.calc_unit_margin_amount(in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                               , in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                  )
                                                                )
             );
    end if;

    -- Si le pourcentage de la marge unitaire (dec_unit_margin_rate) est modifi� et n'est pas null
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_MARGIN_RATE')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DEC_UNIT_MARGIN_RATE') then
      /* Application de cette marge sur le prix de vente unitaire th�orique (dec_unit_sale_price_th)
      /!\ Il est volontaire ici de mettr le prix de vente unitaire th�orique recalcul� au lieu du prix de revient !
      On veut en effet ajouter au prix de vente th�orique la marge et non pas calculer le prix de vente en fonction
      d'une marge sur le prix de revient.    */
      FWK_I_MGT_ENTITY_DATA.setcolumn
        (iot_estimate_element_cost
       , 'DEC_UNIT_SALE_PRICE_TH'
       , doc_lib_estimate_elem_cost.calc_unit_sale_price_th
           (in_dec_cost_price         => DOC_LIB_ESTIMATE_ELEM_COST.calc_sum_unit_sale_price_th
                                                                  (in_doc_estimate_pos_id    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber
                                                                                                                                     (iot_estimate_element_cost
                                                                                                                                    , 'DOC_ESTIMATE_POS_ID'
                                                                                                                                     )
                                                                 , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber
                                                                                                                                     (iot_estimate_element_cost
                                                                                                                                    , 'DEC_UNIT_MARGIN_RATE'
                                                                                                                                     )
                                                                  )
          , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost, 'DEC_UNIT_MARGIN_RATE')
           )
        );

      /* Application de cette marge sur le prix de vente unitaire r�el (dec_unit_sale_price) si pas modifi�.
         /!\ Il est volontaire ici de mettr le prix de vente unitaire au lieu du prix de revient ! */
      if not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_SALE_PRICE') ) then
        FWK_I_MGT_ENTITY_DATA.setcolumn
          (iot_estimate_element_cost
         , 'DEC_UNIT_SALE_PRICE'
         , doc_lib_estimate_elem_cost.calc_unit_sale_price
             (in_dec_cost_price         => DOC_LIB_ESTIMATE_ELEM_COST.calc_sum_unit_sale_price
                                                                  (in_doc_estimate_pos_id    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber
                                                                                                                                     (iot_estimate_element_cost
                                                                                                                                    , 'DOC_ESTIMATE_POS_ID'
                                                                                                                                     )
                                                                 , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber
                                                                                                                                     (iot_estimate_element_cost
                                                                                                                                    , 'DEC_UNIT_MARGIN_RATE'
                                                                                                                                     )
                                                                  )
            , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost, 'DEC_UNIT_MARGIN_RATE')
             )
          );
      end if;

      -- On recalcule le montant de la marge unitaire. (dec_unit_margin_amount)
      FWK_I_MGT_ENTITY_DATA.setcolumn
              (iot_estimate_element_cost
             , 'DEC_UNIT_MARGIN_AMOUNT'
             , doc_lib_estimate_elem_cost.calc_unit_margin_amount(in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                  , 'DEC_COST_PRICE'
                                                                                                                                   )
                                                                , in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                  , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                   )
                                                                 )
              );
    end if;

    -- Si la quantit� (dec_quantity) est modifi�e ou si la quantit� n'est pas nulle ET qu'un des montants unitaire, cout ou marge sont modifi�
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_QUANTITY')
       or (    not FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DEC_QUANTITY')
           and (   FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_COST_PRICE')
                or FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_SALE_PRICE_TH')
                or FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_SALE_PRICE')
                or FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_UNIT_MARGIN_RATE')
               )
          ) then
      -- On recalcule le prix de vente via quantit� (dec_sale_price_th)
      FWK_I_MGT_ENTITY_DATA.setcolumn
                 (iot_estimate_element_cost
                , 'DEC_SALE_PRICE_TH'
                , doc_lib_estimate_elem_cost.calc_sale_price_th(in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                 )
                                                              , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                               )
                 );

      -- On recalcule le prix de vente r�el (dec_sale_price) si pas modifi�.
      if not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE') ) then
        FWK_I_MGT_ENTITY_DATA.setcolumn
                    (iot_estimate_element_cost
                   , 'DEC_SALE_PRICE'
                   , doc_lib_estimate_elem_cost.calc_sale_price(in_dec_unit_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_UNIT_SALE_PRICE'
                                                                                                                                 )
                                                              , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                               )
                    );
      end if;

      -- On recalcule le montant de la marge (dec_margin_amount)
      FWK_I_MGT_ENTITY_DATA.setcolumn
                       (iot_estimate_element_cost
                      , 'DEC_MARGIN_AMOUNT'
                      , doc_lib_estimate_elem_cost.calc_margin_amount(in_dec_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_SALE_PRICE'
                                                                                                                                  )
                                                                    , in_dec_quantity     => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_QUANTITY'
                                                                                                                                  )
                                                                    , in_dec_cost_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                                     )
                       );

      -- On recalcule le pourcentage de la marge (dec_margin_rate)
      if not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_MARGIN_RATE') ) then
        FWK_I_MGT_ENTITY_DATA.setcolumn
                        (iot_estimate_element_cost
                       , 'DEC_MARGIN_RATE'
                       , doc_lib_estimate_elem_cost.calc_margin_rate(in_dec_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_SALE_PRICE'
                                                                                                                                 )
                                                                   , in_dec_cost_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_COST_PRICE'
                                                                                                                                 )
                                                                   , in_dec_quantity     => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                                    )
                        );
      end if;
    end if;

    -- Si le prix de vente corrig� (dec_sale_price_corr) a �t� modifi� et n'est pas null
    if (     (not(FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DEC_SALE_PRICE_CORR') ) )
        and (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE_CORR') )
       ) then
      -- On recalcule le montant de la marge corrig� (dec_margin_amount_corr)
      FWK_I_MGT_ENTITY_DATA.setcolumn
            (iot_estimate_element_cost
           , 'DEC_MARGIN_AMOUNT_CORR'
           , doc_lib_estimate_elem_cost.calc_margin_amount_corr(in_dec_sale_price_corr   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_SALE_PRICE_CORR'
                                                                                                                                 )
                                                              , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_QUANTITY'
                                                                                                                                 )
                                                              , in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                , 'DEC_COST_PRICE'
                                                                                                                                 )
                                                               )
            );
      -- On recalcule le pourcentage de la marge corrig�e (dec_margin_rate_corr)
      FWK_I_MGT_ENTITY_DATA.setcolumn
               (iot_estimate_element_cost
              , 'DEC_MARGIN_RATE_CORR'
              , doc_lib_estimate_elem_cost.calc_margin_rate_corr(in_dec_sale_price_corr   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_SALE_PRICE_CORR'
                                                                                                                                  )
                                                               , in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                               , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_QUANTITY'
                                                                                                                                  )
                                                                )
               );
    end if;
  end calc_cost_pos_with_children;

  /**
  * Description
  *    proc�dure appliquant les r�gles de recalcul des positions de devis du type :
  *     - position de pied de devis
  */
  procedure calc_cost_pos_foot(iot_estimate_element_cost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
/*
--------------------------------------------------------------------------------
Sur cr�ation/modification/supression d'une position de pied de devis :
--------------------------------------------------------------------------------
--> Si le prix de vente (dec_sale_price) est modifi�
      o On recalcule le montant de la marge (dec_margin_amount)
      o On recalcule le pourcentage de la marge (dec_margin_rate)

--> Si le montant de la marge globale n'est pas nulle (dec_global_margin_amount) et que le prix de vente corrig� n'est pas modifi�
      o On recalcule le prix de vente corrig� (dec_sale_price_corr)
      o On recalcule le montant de la marge corrig�e  (dec_margin_amount_corr)
      o On recalcule le pourcentage de la marge corrig�e (dec_margin_rate_corr)
--> Sinon si le prix de vente corrig� (dec_sale_price_corr) est modifi�
      o On recalcule la marge globale (dec_global_margin_amount)(= prix de vente corrig� (dec_sale_price_corr) - prix de vente r�el (dec_sale_price))
--------------------------------------------------------------------------------
*/

    -- Si le prix de vente (dec_sale_price) est modifi�
    if (FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE') ) then
      -- On recalcule le montant de la marge (dec_margin_amount)
      FWK_I_MGT_ENTITY_DATA.setcolumn
                 (iot_estimate_element_cost
                , 'DEC_MARGIN_AMOUNT'
                , doc_lib_estimate_elem_cost.calc_foot_margin_amount(in_doc_estimate_id   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DOC_ESTIMATE_ID'
                                                                                                                                  )
                                                                    )
                 );
      -- On recalcule le pourcentage de la marge(dec_margin_rate)
      FWK_I_MGT_ENTITY_DATA.setcolumn
                    (iot_estimate_element_cost
                   , 'DEC_MARGIN_RATE'
                   , doc_lib_estimate_elem_cost.calc_foot_margin_rate(in_dec_sale_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_SALE_PRICE'
                                                                                                                                  )
                                                                    , in_dec_cost_price   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                                    , in_dec_quantity     => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_QUANTITY'
                                                                                                                                  )
                                                                     )
                    );
    end if;

    -- Si le montant de la marge globale n'est pas nulle (dec_global_margin_amount) et que le prix de vente corrig� n'est pas modifi�
    if     not(FWK_I_MGT_ENTITY_DATA.IsNull(iot_estimate_element_cost, 'DEC_GLOBAL_MARGIN_AMOUNT') )
       and not(FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE_CORR') ) then
      -- On recalcule le prix de vente corrig�
      FWK_I_MGT_ENTITY_DATA.setcolumn
               (iot_estimate_element_cost
              , 'DEC_SALE_PRICE_CORR'
              , doc_lib_estimate_elem_cost.calc_foot_sale_price_corr(in_doc_estimate_id   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DOC_ESTIMATE_ID'
                                                                                                                                  )
                                                                    )
               );
      -- On recalcule le montant de la marge corrig�e
      FWK_I_MGT_ENTITY_DATA.setcolumn
             (iot_estimate_element_cost
            , 'DEC_MARGIN_AMOUNT_CORR'
            , doc_lib_estimate_elem_cost.calc_foot_margin_amount_corr(in_doc_estimate_id   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                  , 'DOC_ESTIMATE_ID'
                                                                                                                                   )
                                                                     )
             );
      -- On recalcule le pourcentage de la marge corrig�e
      FWK_I_MGT_ENTITY_DATA.setcolumn
          (iot_estimate_element_cost
         , 'DEC_MARGIN_RATE_CORR'
         , doc_lib_estimate_elem_cost.calc_foot_margin_rate_corr(in_dec_sale_price_corr   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_SALE_PRICE_CORR'
                                                                                                                                  )
                                                               , in_dec_cost_price        => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_COST_PRICE'
                                                                                                                                  )
                                                               , in_dec_quantity          => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost
                                                                                                                                 , 'DEC_QUANTITY'
                                                                                                                                  )
                                                                )
          );
    /* Sinon si le prix de vente r�el global est modifi� */
    elsif FWK_I_MGT_ENTITY_DATA.IsModified(iot_estimate_element_cost, 'DEC_SALE_PRICE_CORR') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iot_estimate_element_cost
                                    , 'DEC_GLOBAL_MARGIN_AMOUNT'
                                    , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost, 'DEC_SALE_PRICE_CORR') -
                                      FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_estimate_element_cost, 'DEC_SALE_PRICE')
                                     );
    end if;
  end calc_cost_pos_foot;

  /**
  * Description
  *    Cette proc�dure va mettre � jour le prix de revient unitaire total et le prix de vente total du devis
  *    dont la clef primaire est transmise en param�tre.
  */
  procedure recalc_foot_pos(in_doc_estimate_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
  as
    ln_pos_foot_element_cost_id DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ELEMENT_COST_ID%type;
    ltCRUD_DEF                  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- R�cup�ration de la clef primaire de l'�l�ment de co�t concern� (pied du devis) :
    select DOC_ESTIMATE_ELEMENT_COST_ID
      into ln_pos_foot_element_cost_id
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ID = in_doc_estimate_id
       and DOC_ESTIMATE_FOOT_ID is not null;

    -- R�cup�ration de l'entit� de l'�l�ment de co�t
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_I_TYP_DOC_ENTITY.gcDocEstimateElementCost
                       , iot_crud_definition   => ltCRUD_DEF
                       , ib_initialize         => true
                       , in_main_id            => ln_pos_foot_element_cost_id
                       , in_schema_call        => fwk_i_typ_definition.SCHEMA_CURRENT
                        );
    -- Recalcul du prix de revient unitaire
    FWK_I_MGT_ENTITY_DATA.setcolumn
                              (ltCRUD_DEF
                             , 'DEC_COST_PRICE'
                             , doc_lib_estimate_elem_cost.calc_foot_cost_price(in_doc_estimate_id   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF
                                                                                                                                           , 'DOC_ESTIMATE_ID'
                                                                                                                                            )
                                                                              )
                              );
    -- Recalcul du prix de vente r�el
    FWK_I_MGT_ENTITY_DATA.setcolumn
                              (ltCRUD_DEF
                             , 'DEC_SALE_PRICE'
                             , doc_lib_estimate_elem_cost.calc_foot_sale_price(in_doc_estimate_id   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF
                                                                                                                                           , 'DOC_ESTIMATE_ID'
                                                                                                                                            )
                                                                              )
                              );
    FWK_I_MGT_ENTITY.UpdateEntity(iot_crud_definition => ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(iot_crud_definition => ltCRUD_DEF);
    /* Mise � jour du flag de recalcul du devis � 0 */
    DOC_PRC_ESTIMATE.UpdateEstimateFlag(inDocEstimateID => in_doc_estimate_id, inValue => 0);
  end recalc_foot_pos;

  /**
  * Description
  *    Cette proc�dure va mettre � jour le prix de revient, le prix de vente unitaire th�orique,
  *    et le prix de vente unitaire r�el de la position r�capitulative � laquelle la position, dont
  *    la clef primaire de l'�l�ment de co�t est transmis en param�tre, est rattach�e. Si la quantit�
  *    de cet �l�ment de co�t n'est pas nulle, les montant non unitaires seront aussi mis � jour !
  */
  procedure recalc_recap_pos(in_doc_estimate_pos_id in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type)
  as
    lnPosRecapElementCostId  DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ELEMENT_COST_ID%type;
    lnPosRecapChildrenNumber number;
    ltCRUD_DEF               FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- R�cup�ration de la clef primaire de l'�l�ment de co�t concern� (position r�capitulative du devis) :
    select DOC_ESTIMATE_ELEMENT_COST_ID
      into lnPosRecapElementCostId
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_POS_ID = in_doc_estimate_pos_id
       and DOC_ESTIMATE_ELEMENT_ID is null;

    -- R�cup�ration de l'entit� de l'�l�ment de co�t
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_I_TYP_DOC_ENTITY.gcDocEstimateElementCost
                       , iot_crud_definition   => ltCRUD_DEF
                       , ib_initialize         => true
                       , in_main_id            => lnPosRecapElementCostId
                       , in_schema_call        => fwk_i_typ_definition.SCHEMA_CURRENT
                        );
    /* Recherche du nombre d'enfants. */
    lnPosRecapChildrenNumber  := DOC_LIB_ESTIMATE_ELEM_COST.GetChildrenNumber(inEstimatePosID => in_doc_estimate_pos_id);

    /* Si elle n'en poss�de qu'un --> Remise � z�ro du montant de la marge unitaire (DEC_UNIT_MARGIN_RATE)
       En effet, vu qu'elle a d�sormais des enfants, les r�gles de calcul change et donc on remet � z�ro la
       marge dont la m�thode de calcul change. */
    if (lnPosRecapChildrenNumber = 1) then
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_DEF, 'DEC_UNIT_MARGIN_RATE');
    end if;

    -- Recalcul du prix de revient unitaire
    FWK_I_MGT_ENTITY_DATA.setcolumn
                      (ltCRUD_DEF
                     , 'DEC_COST_PRICE'
                     , doc_lib_estimate_elem_cost.calc_sum_cost_prices(in_doc_estimate_pos_id   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF
                                                                                                                                       , 'DOC_ESTIMATE_POS_ID'
                                                                                                                                        )
                                                                      )
                      );
    -- Recalcul du prix de vente unitaire th�orique
    FWK_I_MGT_ENTITY_DATA.setcolumn
             (ltCRUD_DEF
            , 'DEC_UNIT_SALE_PRICE_TH'
            , doc_lib_estimate_elem_cost.calc_sum_unit_sale_price_th(in_doc_estimate_pos_id    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF
                                                                                                                                      , 'DOC_ESTIMATE_POS_ID'
                                                                                                                                       )
                                                                   , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF
                                                                                                                                      , 'DEC_UNIT_MARGIN_RATE'
                                                                                                                                       )
                                                                    )
             );
    -- Recalcul du prix de vente unitaire r�el
    FWK_I_MGT_ENTITY_DATA.setcolumn
                (ltCRUD_DEF
               , 'DEC_UNIT_SALE_PRICE'
               , doc_lib_estimate_elem_cost.calc_sum_unit_sale_price(in_doc_estimate_pos_id    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF
                                                                                                                                      , 'DOC_ESTIMATE_POS_ID'
                                                                                                                                       )
                                                                   , in_dec_unit_margin_rate   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF
                                                                                                                                      , 'DEC_UNIT_MARGIN_RATE'
                                                                                                                                       )
                                                                    )
                );
    FWK_I_MGT_ENTITY.UpdateEntity(iot_crud_definition => ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(iot_crud_definition => ltCRUD_DEF);
    /* Mise � jour du flag de recalcul de la position recapitulative � 0 */
    DOC_PRC_ESTIMATE_POS.UpdatePositionFlag(inEstimateElementID => null, inEstimatePosID => in_doc_estimate_pos_id, inValue => 0);
  end recalc_recap_pos;

  /**
  * Description
  *    fonction appliquant la ventilation de la marge globale dans les prix de vente corrig�s des lignes du devis
  */
  procedure applyGlobalMarginAmount(inDocEstimateID in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type)
  as
    lnGlobalMarginAmount      DOC_ESTIMATE_ELEMENT_COST.DEC_GLOBAL_MARGIN_AMOUNT%type;
    lnTempAmountRest          DOC_ESTIMATE_ELEMENT_COST.DEC_GLOBAL_MARGIN_AMOUNT%type;
    lnTempAmount              DOC_ESTIMATE_ELEMENT_COST.DEC_GLOBAL_MARGIN_AMOUNT%type;
    lnMandatoryEstimatePosSum DOC_ESTIMATE_ELEMENT_COST.DEC_SALE_PRICE%type;
    ltCRUD_DEF                FWK_I_TYP_DEFINITION.t_crud_def;
    lttMandatoryPosList       DOC_LIB_ESTIMATE_ELEM_COST.ttPosInfos;
    lttOptionalPosList        DOC_LIB_ESTIMATE_ELEM_COST.ttPosInfos;
  begin
    /* R�cup�ration du montant de la marge globale de l'�l�ment de co�t du devis (pied) */
    select nvl(DEC_GLOBAL_MARGIN_AMOUNT, 0)
      into lnGlobalMarginAmount
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ID = inDocEstimateID
       and DOC_ESTIMATE_FOOT_ID is not null;

    /* Montant restant � ventiler */
    lnTempAmountRest     := lnGlobalMarginAmount;

    /* R�cup�ration du montant total des positions non optionelles */
    select   sum(dec.DEC_SALE_PRICE)
        into lnMandatoryEstimatePosSum
        from DOC_ESTIMATE_ELEMENT_COST dec
           , DOC_ESTIMATE_POS DEP
       where dec.DOC_ESTIMATE_POS_ID = DEP.DOC_ESTIMATE_POS_ID
         and dec.DOC_ESTIMATE_ID = inDocEstimateID
         and dec.DOC_ESTIMATE_POS_ID is not null
         and dep.DEP_OPTION = 0
    order by dec.DEC_SALE_PRICE;

    /* R�cup�ration des IDs des �l�ments de co�t des positions non optionnelles */
    lttMandatoryPosList  := DOC_LIB_ESTIMATE_ELEM_COST.getMandatoryPosID(inDocEstimateID => inDocEstimateID);

    /* Si des positions non optionnelles existent et que la somme de leur prix de vente > 0 */
    if     (lttMandatoryPosList.count > 0)
       and (lnMandatoryEstimatePosSum > 0) then
      /* Ventilation du montant dans les positions non optionnelles */
      for i in lttMandatoryPosList.first .. lttMandatoryPosList.last loop
        /* Calcul du montant  ventiler. Celui-ci d�pend est en pourcentage du montant de la position.
           La derni�re position contiendra le solde du montant � ventiler */
        lnTempAmount  := acs_function.PcsRound(aValue =>( (lttMandatoryPosList(i).DEC_SALE_PRICE / lnMandatoryEstimatePosSum) * lnGlobalMarginAmount) );
        FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_I_TYP_DOC_ENTITY.gcDocEstimateElementCost
                           , iot_crud_definition   => ltCRUD_DEF
                           , ib_initialize         => true
                           , in_main_id            => lttMandatoryPosList(i).DOC_ESTIMATE_ELEMENT_COST_ID
                           , in_schema_call        => fwk_i_typ_definition.SCHEMA_CURRENT
                            );

        /* Tant qu'on n'est pas sur la derni�re position */
        if i < lttMandatoryPosList.last then
          /* Mise � jour du prix de vente corrig� de la position */
          pUpdPosWithGlobalMargin(inAmount => lnTempAmount, iotCRUD_DEF => ltCRUD_DEF);
          /* Soustraction du montant au montant restant */
          lnTempAmountRest  := lnTempAmountRest - lnTempAmount;
        else
          /* Mise � jour du prix de vente corrig� de la position */
          pUpdPosWithGlobalMargin(inAmount => lnTempAmountRest, iotCRUD_DEF => ltCRUD_DEF);
        end if;

        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;
    end if;

    /* R�cup�ration des IDs des �l�ments de co�t des positions optionnelles */
    lttOptionalPosList   := DOC_LIB_ESTIMATE_ELEM_COST.getOptionalPosID(inDocEstimateID => inDocEstimateID);

    /* Si des positions optionnelles existent */
    if (lttOptionalPosList.count > 0) then
      /* Remise � 0 des montants corrig�s (= au prix de vente r�el), car le montant de
         la marge global ne doit pas ou plus �tre ventil� sur les positions optionnelles */
      for i in lttOptionalPosList.first .. lttOptionalPosList.last loop
        /* On ne ventile aucun montant dans ces positions */
        lnTempAmount  := 0;
        FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_I_TYP_DOC_ENTITY.gcDocEstimateElementCost
                           , iot_crud_definition   => ltCRUD_DEF
                           , ib_initialize         => true
                           , in_main_id            => lttOptionalPosList(i).DOC_ESTIMATE_ELEMENT_COST_ID
                           , in_schema_call        => fwk_i_typ_definition.SCHEMA_CURRENT
                            );
        pUpdPosWithGlobalMargin(inAmount => lnTempAmount, iotCRUD_DEF => ltCRUD_DEF);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;
    end if;
  end applyGlobalMarginAmount;

  /**
  * Description
  *    Mise � jour du statut du devis � modifi�, si au moins une offre existe d�j�
  */
  procedure UpdateEstimateStatus(iotEstimateElementCost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lEstimateId DOC_ESTIMATE.DOC_ESTIMATE_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ID');
  begin
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_POS_ID') then
      if DOC_LIB_ESTIMATE.ExistsEstimateOffer(lEstimateId) then
        -- devis au statut "modifi�"
        DOC_PRC_ESTIMATE.UpdateStatus(lEstimateId, '01');
      end if;
    end if;
  end UpdateEstimateStatus;

  /**
  * Description
  *    Recherche  et assigne le champ DOC_ESTIMATE_ID
  */
  procedure ResolveEstimateId(iotEstimateElementCost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_ID') then
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_FOOT_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotEstimateElementCost
                                      , 'DOC_ESTIMATE_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_FOOT_ID')
                                       );
      elsif not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_POS_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotEstimateElementCost
                                      , 'DOC_ESTIMATE_ID'
                                      , FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_ESTIMATE_POS'
                                                                            , 'DOC_ESTIMATE_ID'
                                                                            , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost
                                                                                                                  , 'DOC_ESTIMATE_POS_ID'
                                                                                                                   )
                                                                             )
                                       );
      elsif not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_ELEMENT_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn
             (iotEstimateElementCost
            , 'DOC_ESTIMATE_ID'
            , FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_ESTIMATE_POS'
                                                  , 'DOC_ESTIMATE_ID'
                                                  , FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_ESTIMATE_ELEMENT'
                                                                                        , 'DOC_ESTIMATE_POS_ID'
                                                                                        , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost
                                                                                                                              , 'DOC_ESTIMATE_ELEMENT_ID'
                                                                                                                               )
                                                                                         )
                                                   )
             );
      end if;
    end if;
  end ResolveEstimateId;

  /**
  * procedure InitPrice
  * Description
  *    proc�dure d'init du prix si pas d�fini
  */
  procedure InitPrice(iotEstimateElementCost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnPosID           DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type;
    lnElementID       DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ELEMENT_ID%type;
    lnThirdID         PAC_THIRD.PAC_THIRD_ID%type;
    lnGoodID          GCO_GOOD.GCO_GOOD_ID%type;
    lnFalTaskID       FAL_TASK.FAL_TASK_ID%type;
    ldDateRef         date;
    lnPrice           DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvElementType     DOC_ESTIMATE_ELEMENT.C_DOC_ESTIMATE_ELEMENT_TYPE%type;
    lvEstimateCode    DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type;
    lnMarginRate      DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
    lnAdjustingTime   DOC_ESTIMATE_TASK.DTK_ADJUSTING_TIME%type;
    lnQtyFixAdjusting DOC_ESTIMATE_TASK.DTK_QTY_FIX_ADJUSTING%type;
    lnWorkTime        DOC_ESTIMATE_TASK.DTK_WORK_TIME%type;
    lnQtyRefWork      DOC_ESTIMATE_TASK.DTK_QTY_REF_WORK%type;
    lnRate1           DOC_ESTIMATE_TASK.DTK_RATE1%type;
    lnRate2           DOC_ESTIMATE_TASK.DTK_RATE2%type;
    lnAmount          DOC_ESTIMATE_TASK.DTK_AMOUNT%type;
    lnQtyRefAMount    DOC_ESTIMATE_TASK.DTK_QTY_REF_AMOUNT%type;
    lnDivisorAmount   DOC_ESTIMATE_TASK.DTK_DIVISOR_AMOUNT%type;
  begin
    -- Si la quantit� (dec_quantity) n'a pas �t� sp�cifi�e et qu'on n'est pas sur un �l�ment de co�t du devis.
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DEC_QUANTITY')
       and FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_FOOT_ID') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotEstimateElementCost, 'DEC_QUANTITY', 1);
    end if;

    -- Si le prix n'a pas �t� sp�cifi�
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DEC_COST_PRICE') then
      lnPosID      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_POS_ID');
      lnElementID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ELEMENT_ID');

      -- Position de devis
      if lnPosID is not null then
        -- Infos pour la recherche du prix
        select DES.PAC_CUSTOM_PARTNER_ID
             , DEP.GCO_GOOD_ID
             , DEP.DEP_DELIVERY_DATE
             , DES.C_DOC_ESTIMATE_CODE
          into lnThirdID
             , lnGoodID
             , ldDateRef
             , lvEstimateCode
          from DOC_ESTIMATE_POS DEP
             , DOC_ESTIMATE DES
         where DEP.DOC_ESTIMATE_POS_ID = lnPosID
           and DEP.DOC_ESTIMATE_ID = DES.DOC_ESTIMATE_ID;

        -- echerche le prix de la position
        lnPrice       :=
          DOC_LIB_ESTIMATE_POS.InternalGetPosPrice(iGoodID     => lnGoodID
                                                 , iThirdID    => lnThirdID
                                                 , iDateRef    => ldDateRef
                                                 , iQuantity   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DEC_QUANTITY')
                                                  );
        lnMarginRate  :=
          DOC_LIB_ESTIMATE_POS.InternalGetPosMarginRate(iGoodID         => lnGoodID
                                                      , iThirdID        => lnThirdID
                                                      , iEstimateCode   => lvEstimateCode
                                                      , iDateRef        => ldDateRef
                                                      , iQuantity       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DEC_QUANTITY')
                                                       );
      -- Composant ou op�ration
      elsif lnElementID is not null then
        -- D�terminer s'il s'agit d'un composant ou d'une op�ration
        select DES.PAC_CUSTOM_PARTNER_ID
             , ECP.GCO_GOOD_ID
             , DEP.DEP_DELIVERY_DATE
             , DEP.DOC_ESTIMATE_POS_ID
             , DED.C_DOC_ESTIMATE_ELEMENT_TYPE
             , DTK.FAL_TASK_ID
             , DES.C_DOC_ESTIMATE_CODE
             , DTK.DTK_ADJUSTING_TIME
             , DTK.DTK_QTY_FIX_ADJUSTING
             , DTK.DTK_WORK_TIME
             , DTK.DTK_QTY_REF_WORK
             , DTK.DTK_RATE1
             , DTK.DTK_RATE2
             , DTK.DTK_AMOUNT
             , DTK.DTK_QTY_REF_AMOUNT
             , DTK.DTK_DIVISOR_AMOUNT
          into lnThirdID
             , lnGoodID
             , ldDateRef
             , lnPosID
             , lvElementType
             , lnFalTaskID
             , lvEstimateCode
             , lnAdjustingTime
             , lnQtyFixAdjusting
             , lnWorkTime
             , lnQtyRefWork
             , lnRate1
             , lnRate2
             , lnAmount
             , lnQtyRefAMount
             , lnDivisorAmount
          from DOC_ESTIMATE_ELEMENT DED
             , DOC_ESTIMATE_POS DEP
             , DOC_ESTIMATE DES
             , DOC_ESTIMATE_COMP ECP
             , DOC_ESTIMATE_TASK DTK
         where DED.DOC_ESTIMATE_ELEMENT_ID = lnElementID
           and DEP.DOC_ESTIMATE_POS_ID = DED.DOC_ESTIMATE_POS_ID
           and DEP.DOC_ESTIMATE_ID = DES.DOC_ESTIMATE_ID
           and DED.DOC_ESTIMATE_ELEMENT_ID = ECP.DOC_ESTIMATE_COMP_ID(+)
           and DED.DOC_ESTIMATE_ELEMENT_ID = DTK.DOC_ESTIMATE_TASK_ID(+);

        -- Composant
        if lvElementType = '01' then
          lnPrice       :=
            DOC_LIB_ESTIMATE_POS.InternalGetCompPrice(iGoodID     => lnGoodID
                                                    , iThirdID    => lnThirdID
                                                    , iDateRef    => ldDateRef
                                                    , iQuantity   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DEC_QUANTITY')
                                                     );
          lnMarginRate  :=
            DOC_LIB_ESTIMATE_POS.InternalGetCompMarginRate(iGoodID         => lnGoodID
                                                         , iThirdID        => lnThirdID
                                                         , iEstimateCode   => lvEstimateCode
                                                         , iDateRef        => ldDateRef
                                                         , iQuantity       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DEC_QUANTITY')
                                                          );
        -- Op�ration
        elsif lvElementType = '02' then
          declare
            lnQuantity DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type;
          begin
            -- Qt� pour la recherche du prix et de la marge
            -- En mode Gestion � l'affaire
            if lvEstimateCode = 'PRP' then
              -- Qt� op�ration (Temps)
              lnQuantity  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DEC_QUANTITY');
            end if;

            -- Qt� pour la recherche du prix et de la marge
            -- En mode Production
            if lvEstimateCode = 'MRP' then
              -- Qt� produit termin�
              select DEC_QUANTITY
                into lnQuantity
                from EV_DOC_ESTIMATE_POS
               where DOC_ESTIMATE_POS_ID = lnPosID;
            end if;

            lnPrice       :=
              DOC_LIB_ESTIMATE_POS.InternalGetTaskPrice(iTaskID            => lnFalTaskID
                                                      , iThirdID           => lnThirdID
                                                      , iEstimateCode      => lvEstimateCode
                                                      , iDateRef           => ldDateRef
                                                      , iQuantity          => lnQuantity
                                                      , iAdjustingTime     => lnAdjustingTime
                                                      , iQtyFixAdjusting   => lnQtyFixAdjusting
                                                      , iWorkTime          => lnWorkTime
                                                      , iQtyRefWork        => lnQtyRefWork
                                                      , iRate1             => lnRate1
                                                      , iRate2             => lnRate2
                                                      , iAmount            => lnAmount
                                                      , iQtyRefAMount      => lnQtyRefAMount
                                                      , iDivisorAmount     => lnDivisorAmount
                                                       );
            lnMarginRate  :=
              DOC_LIB_ESTIMATE_POS.InternalGetTaskMarginRate(iTaskID         => lnFalTaskID
                                                           , iThirdID        => lnThirdID
                                                           , iEstimateCode   => lvEstimateCode
                                                           , iDateRef        => ldDateRef
                                                           , iQuantity       => lnQuantity
                                                            );
          end;
        end if;
      end if;

      FWK_I_MGT_ENTITY_DATA.setcolumn(iotEstimateElementCost, 'DEC_COST_PRICE', lnPrice);

      -- Marge unitaire % ->  R�gles d'initialisations des marges
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DEC_UNIT_MARGIN_RATE') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotEstimateElementCost, 'DEC_UNIT_MARGIN_RATE', lnMarginRate);
      end if;
    end if;
  end InitPrice;

  /**
  * procedure RecalcPosMRPTasks
  * Description
  *   Recalcul des prix de toutes les op�rations d'une position de devis en mode gestion production (MRP)
  */
  procedure RecalcPosMRPTasks(iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type)
  is
  begin
    -- Mode de gestion Production (MRP)
    -- Liste des op�rations externes de la position
    for ltplTask in (select   DTK.DOC_ESTIMATE_TASK_ID
                         from EV_DOC_ESTIMATE DES
                            , EV_DOC_ESTIMATE_POS DEP
                            , EV_DOC_ESTIMATE_TASK DTK
                        where DEP.DOC_ESTIMATE_POS_ID = iEstimatePosID
                          and DES.DOC_ESTIMATE_ID = DEP.DOC_ESTIMATE_ID
                          and nvl(DES.C_DOC_ESTIMATE_CODE, 'PRP') = 'MRP'
                          and DEP.DOC_ESTIMATE_POS_ID = DTK.DOC_ESTIMATE_POS_ID
                     order by DTK.DED_NUMBER asc) loop
      RecalcTask(ltplTask.DOC_ESTIMATE_TASK_ID);
    end loop;
  end RecalcPosMRPTasks;

  /**
  * procedure RecalcTask
  * Description
  *   Recalcul des prix de de l'op�ration de devis courante
  */
  procedure RecalcTask(iEstimateTaskID in DOC_ESTIMATE_TASK.DOC_ESTIMATE_TASK_ID%type)
  is
    ltTask FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcEvDocEstimateTask, iot_crud_definition => ltTask, iv_primary_col => 'DOC_ESTIMATE_TASK_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'DOC_ESTIMATE_TASK_ID', iEstimateTaskID);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTask, 'DEC_COST_PRICE');
    FWK_I_MGT_ENTITY.UpdateEntity(ltTask);
    FWK_I_MGT_ENTITY.Release(ltTask);
  end RecalcTask;
end DOC_PRC_ESTIMATE_ELEM_COST;
