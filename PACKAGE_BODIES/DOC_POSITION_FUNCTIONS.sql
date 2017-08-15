--------------------------------------------------------
--  DDL for Package Body DOC_POSITION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_POSITION_FUNCTIONS" 
is
  /**
  * procedure UpdateQuantityPosition
  *
  * Description : Modifie la quantité d'une position en recalculant les prix et autres
  *
  */
  procedure UpdateQuantityPosition(
    aPositionID        in DOC_POSITION.DOC_POSITION_ID%type
  , aNewQuantity       in DOC_POSITION.POS_BASIS_QUANTITY%type
  , aKeepPosPrice      in integer
  , aGrossUnitValueCPT in DOC_POSITION.POS_GROSS_UNIT_VALUE2%type default null
  , aUpdateCPT         in boolean default false
  )
  is
    cursor GetPosInfo(aPosID DOC_POSITION.DOC_POSITION_ID%type, aNewQty DOC_POSITION.POS_BASIS_QUANTITY%type)
    is
      select POS.POS_UNIT_COST_PRICE
           , POS.POS_REF_UNIT_VALUE
           , POS.POS_GROSS_UNIT_VALUE
           , POS.POS_GROSS_UNIT_VALUE2
           , POS.POS_GROSS_VALUE
           , POS.POS_GROSS_UNIT_VALUE_INCL
           , POS.POS_GROSS_VALUE_INCL
           , POS.POS_NET_UNIT_VALUE
           , POS.POS_NET_UNIT_VALUE_INCL
           , POS.POS_DISCOUNT_UNIT_VALUE
           , POS.POS_NET_VALUE_INCL
           , POS.POS_NET_VALUE_EXCL
           , POS.POS_INCLUDE_TAX_TARIFF
           , POS.POS_BASIS_QUANTITY
           , POS.POS_BALANCE_QUANTITY
           , POS.POS_BALANCE_QTY_VALUE
           , POS.POS_CONVERT_FACTOR
           , POS.POS_UTIL_COEFF
           , POS.GCO_GOOD_ID
           , POS.DOC_RECORD_ID
           , POS.POS_CHARGE_AMOUNT
           , POS.POS_DISCOUNT_AMOUNT
           , POS.ACS_TAX_CODE_ID
           , POS.POS_DISCOUNT_RATE
           , POS.POS_GROSS_WEIGHT
           , POS.POS_NET_WEIGHT
           , POS.DOC_DOC_POSITION_ID
           , POS.C_DOC_POS_STATUS
           , DOC.PAC_THIRD_ID
           , DOC.PAC_THIRD_TARIFF_ID
           , DOC.DIC_TARIFF_ID DOC_DIC_TARIFF_ID
           , DOC.DMT_DATE_DOCUMENT
           , DOC.DMT_DATE_VALUE
           , nvl(POS.POS_DATE_DELIVERY, DOC.DMT_DATE_DELIVERY) DMT_DATE_DELIVERY
           , nvl(POS.POS_TARIFF_DATE, nvl(DOC.DMT_TARIFF_DATE, DOC.DMT_DATE_DOCUMENT) ) DMT_TARIFF_DATE
           , DOC.ACS_FINANCIAL_CURRENCY_ID
           , GAU.C_ADMIN_DOMAIN
           , GAP.GAP_WEIGHT
           , GAP.C_GAUGE_INIT_PRICE_POS
           , GAP.DIC_TARIFF_ID GAP_DIC_TARIFF_ID
           , GAP.GAP_FORCED_TARIFF
           , GAP.C_ROUND_APPLICATION
           , GAS.C_ROUND_TYPE
           , GAS.GAS_ROUND_AMOUNT
           , GAS.GAS_BALANCE_STATUS
           , GOO.GOO_NUMBER_OF_DECIMAL
        from DOC_POSITION POS
           , DOC_DOCUMENT DOC
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE_POSITION GAP
           , GCO_GOOD GOO
       where POS.DOC_POSITION_ID = aPosID
         and POS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and POS.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID;

    SelectedPos                    GetPosInfo%rowtype;

    cursor crComponents(aPositionIDPT DOC_POSITION.DOC_POSITION_ID%type)
    is
      select POS.DOC_POSITION_ID
           , POS.POS_GROSS_UNIT_VALUE2
        from DOC_POSITION POS
       where POS.DOC_DOC_POSITION_ID = aPositionIDPT;

    tplComponent                   crComponents%rowtype;
    -- Données du select qui seront utilisées qu'en lecture
    data_POS_INCLUDE_TAX_TARIFF    DOC_POSITION.POS_INCLUDE_TAX_TARIFF%type;
    data_POS_CONVERT_FACTOR        DOC_POSITION.POS_CONVERT_FACTOR%type;
    data_POS_UTIL_COEFF            DOC_POSITION.POS_UTIL_COEFF%type;
    data_GCO_GOOD_ID               DOC_POSITION.GCO_GOOD_ID%type;
    data_DOC_RECORD_ID             DOC_POSITION.DOC_RECORD_ID%type;
    data_POS_CHARGE_AMOUNT         DOC_POSITION.POS_CHARGE_AMOUNT%type;
    data_POS_DISCOUNT_AMOUNT       DOC_POSITION.POS_DISCOUNT_AMOUNT%type;
    data_ACS_TAX_CODE_ID           DOC_POSITION.ACS_TAX_CODE_ID%type;
    data_POS_DISCOUNT_RATE         DOC_POSITION.POS_DISCOUNT_RATE%type;
    data_POS_GROSS_WEIGHT          DOC_POSITION.POS_GROSS_WEIGHT%type;
    data_POS_NET_WEIGHT            DOC_POSITION.POS_NET_WEIGHT%type;
    data_FAL_SCHEDULE_STEP_ID      DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type;
    data_POS_GROSS_UNIT_VALUE2     DOC_POSITION.POS_GROSS_UNIT_VALUE2%type;
    data_DOC_DIC_TARIFF_ID         DOC_DOCUMENT.DIC_TARIFF_ID%type;
    data_PAC_THIRD_ID              DOC_DOCUMENT.PAC_THIRD_ID%type;
    data_PAC_THIRD_TARIFF_ID       DOC_DOCUMENT.PAC_THIRD_TARIFF_ID%type;
    data_DMT_DATE_DOCUMENT         DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    data_DMT_DATE_VALUE            DOC_DOCUMENT.DMT_DATE_VALUE%type;
    data_DMT_DATE_DELIVERY         DOC_DOCUMENT.DMT_DATE_DELIVERY%type;
    data_DMT_TARIFF_DATE           DOC_DOCUMENT.DMT_TARIFF_DATE%type;
    data_ACS_FINANCIAL_CURRENCY_ID DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    data_C_ADMIN_DOMAIN            DOC_GAUGE.C_ADMIN_DOMAIN%type;
    data_GAP_WEIGHT                DOC_GAUGE_POSITION.GAP_WEIGHT%type;
    data_C_GAUGE_INIT_PRICE_POS    DOC_GAUGE_POSITION.C_GAUGE_INIT_PRICE_POS%type;
    data_GAP_DIC_TARIFF_ID         DOC_GAUGE_POSITION.DIC_TARIFF_ID%type;
    data_GAP_FORCED_TARIFF         DOC_GAUGE_POSITION.GAP_FORCED_TARIFF%type;
    data_C_ROUND_APPLICATION       DOC_GAUGE_POSITION.C_ROUND_APPLICATION%type;
    data_C_ROUND_TYPE              DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type;
    data_GAS_ROUND_AMOUNT          DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type;
    data_GAS_BALANCE_STATUS        DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type;
    data_GOO_NUMBER_OF_DECIMAL     GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    -- Données pour la mise à jour de la position
    newPOS_UNIT_COST_PRICE         DOC_POSITION.POS_UNIT_COST_PRICE%type;
    newPOS_REF_UNIT_VALUE          DOC_POSITION.POS_REF_UNIT_VALUE%type;
    newPOS_GROSS_UNIT_VALUE        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    newPOS_GROSS_UNIT_VALUE2       DOC_POSITION.POS_GROSS_UNIT_VALUE2%type;
    newPOS_GROSS_VALUE             DOC_POSITION.POS_GROSS_VALUE%type;
    newPOS_GROSS_UNIT_VALUE_INCL   DOC_POSITION.POS_GROSS_UNIT_VALUE_INCL%type;
    newPOS_GROSS_VALUE_INCL        DOC_POSITION.POS_GROSS_VALUE_INCL%type;
    newPOS_NET_UNIT_VALUE          DOC_POSITION.POS_NET_UNIT_VALUE%type;
    newPOS_NET_UNIT_VALUE_INCL     DOC_POSITION.POS_NET_UNIT_VALUE_INCL%type;
    newPOS_DISCOUNT_UNIT_VALUE     DOC_POSITION.POS_DISCOUNT_UNIT_VALUE%type;
    newPOS_NET_VALUE_INCL          DOC_POSITION.POS_NET_VALUE_INCL%type;
    newPOS_NET_VALUE_EXCL          DOC_POSITION.POS_NET_VALUE_EXCL%type;
    newPOS_VAT_AMOUNT              DOC_POSITION.POS_VAT_AMOUNT%type;
    newPOS_VAT_BASE_AMOUNT         DOC_POSITION.POS_VAT_BASE_AMOUNT%type;
    newPOS_NET_TARIFF              DOC_POSITION.POS_NET_TARIFF%type;
    newPOS_SPECIAL_TARIFF          DOC_POSITION.POS_SPECIAL_TARIFF%type;
    newPOS_FLAT_RATE               DOC_POSITION.POS_FLAT_RATE%type;
    newPOS_VALUE_QUANTITY          DOC_POSITION.POS_VALUE_QUANTITY%type;
    newPOS_BASIS_QUANTITY          DOC_POSITION.POS_BASIS_QUANTITY%type;
    newPOS_INTERMEDIATE_QUANTITY   DOC_POSITION.POS_INTERMEDIATE_QUANTITY%type;
    newPOS_FINAL_QUANTITY          DOC_POSITION.POS_FINAL_QUANTITY%type;
    newPOS_BASIS_QUANTITY_SU       DOC_POSITION.POS_BASIS_QUANTITY_SU%type;
    newPOS_INTER_QUANTITY_SU       DOC_POSITION.POS_INTERMEDIATE_QUANTITY_SU%type;
    newPOS_FINAL_QUANTITY_SU       DOC_POSITION.POS_FINAL_QUANTITY_SU%type;
    newPOS_BALANCE_QUANTITY        DOC_POSITION.POS_BALANCE_QUANTITY%type;
    newPOS_BALANCE_QTY_VALUE       DOC_POSITION.POS_BALANCE_QTY_VALUE%type;
    newPOS_GROSS_WEIGHT            DOC_POSITION.POS_GROSS_WEIGHT%type;
    newPOS_NET_WEIGHT              DOC_POSITION.POS_NET_WEIGHT%type;
    newDIC_TARIFF_ID               DOC_POSITION.DIC_TARIFF_ID%type;
    newPOS_TARIFF_UNIT             DOC_POSITION.POS_TARIFF_UNIT%type;
    newPOS_UTIL_COEFF              DOC_POSITION.POS_UTIL_COEFF%type;
    posFinalQuantityPT             DOC_POSITION.POS_FINAL_QUANTITY%type;
    posGaugeTypePosPT              DOC_POSITION.C_GAUGE_TYPE_POS%type;
    posStatusPT                    DOC_POSITION.C_DOC_POS_STATUS%type;
    posPositionIDPT                DOC_POSITION.DOC_POSITION_ID%type;
    VATRounded                     integer;
    nProcessingCPT                 integer;
  begin
    nProcessingCPT                  := 0;

    -- Recherche les données des composants de la position courante s'il on traite un composé uniquement.
    open crComponents(aPositionID);

    fetch crComponents
     into tplComponent;

    -- Traitement de la quantité du composé sur tous ses composants
    while crComponents%found loop
      -- Mise à jour de la nouvelle quantité sur le composant courant
      UpdateQuantityPosition(tplComponent.DOC_POSITION_ID, aNewQuantity, aKeepPosPrice, tplComponent.POS_GROSS_UNIT_VALUE2, true);
      -- Indique le traitement des composants. Cela sera utilisé pour mettre à jour les montants des PT de type 8
      nProcessingCPT  := 1;

      -- Composant suivant
      fetch crComponents
       into tplComponent;
    end loop;

    close crComponents;

    -- Recherche les données de la position
    open GetPosInfo(aPositionID, aNewQuantity);

    fetch GetPosInfo
     into SelectedPos;

    newPOS_UNIT_COST_PRICE          := SelectedPos.POS_UNIT_COST_PRICE;
    newPOS_REF_UNIT_VALUE           := SelectedPos.POS_REF_UNIT_VALUE;
    newPOS_GROSS_UNIT_VALUE2        := SelectedPos.POS_GROSS_UNIT_VALUE2;
    newPOS_GROSS_UNIT_VALUE         := SelectedPos.POS_GROSS_UNIT_VALUE;
    newPOS_GROSS_UNIT_VALUE_INCL    := SelectedPos.POS_GROSS_UNIT_VALUE_INCL;
    newPOS_NET_UNIT_VALUE           := SelectedPos.POS_NET_UNIT_VALUE;
    newPOS_NET_UNIT_VALUE_INCL      := SelectedPos.POS_NET_UNIT_VALUE_INCL;
    newPOS_DISCOUNT_UNIT_VALUE      := SelectedPos.POS_DISCOUNT_UNIT_VALUE;
    newPOS_GROSS_VALUE              := SelectedPos.POS_GROSS_VALUE;
    newPOS_GROSS_VALUE_INCL         := SelectedPos.POS_GROSS_VALUE_INCL;
    newPOS_NET_VALUE_INCL           := SelectedPos.POS_NET_VALUE_INCL;
    newPOS_UTIL_COEFF               := SelectedPos.POS_UTIL_COEFF;
    data_POS_CONVERT_FACTOR         := SelectedPos.POS_CONVERT_FACTOR;
    data_POS_INCLUDE_TAX_TARIFF     := SelectedPos.POS_INCLUDE_TAX_TARIFF;
    data_POS_CONVERT_FACTOR         := SelectedPos.POS_CONVERT_FACTOR;
    data_GCO_GOOD_ID                := SelectedPos.GCO_GOOD_ID;
    data_DOC_RECORD_ID              := SelectedPos.DOC_RECORD_ID;
    data_POS_CHARGE_AMOUNT          := SelectedPos.POS_CHARGE_AMOUNT;
    data_POS_DISCOUNT_AMOUNT        := SelectedPos.POS_DISCOUNT_AMOUNT;
    data_ACS_TAX_CODE_ID            := SelectedPos.ACS_TAX_CODE_ID;
    data_POS_DISCOUNT_RATE          := SelectedPos.POS_DISCOUNT_RATE;
    data_POS_GROSS_WEIGHT           := SelectedPos.POS_GROSS_WEIGHT;
    data_POS_NET_WEIGHT             := SelectedPos.POS_NET_WEIGHT;
    data_PAC_THIRD_ID               := SelectedPos.PAC_THIRD_ID;
    data_PAC_THIRD_TARIFF_ID        := SelectedPos.PAC_THIRD_TARIFF_ID;
    data_DOC_DIC_TARIFF_ID          := SelectedPos.DOC_DIC_TARIFF_ID;
    data_DMT_DATE_DOCUMENT          := SelectedPos.DMT_DATE_DOCUMENT;
    data_DMT_DATE_VALUE             := SelectedPos.DMT_DATE_VALUE;
    data_DMT_DATE_DELIVERY          := SelectedPos.DMT_DATE_DELIVERY;
    data_DMT_TARIFF_DATE            := SelectedPos.DMT_TARIFF_DATE;
    data_ACS_FINANCIAL_CURRENCY_ID  := SelectedPos.ACS_FINANCIAL_CURRENCY_ID;
    data_C_ADMIN_DOMAIN             := SelectedPos.C_ADMIN_DOMAIN;
    data_GAP_WEIGHT                 := SelectedPos.GAP_WEIGHT;
    data_C_GAUGE_INIT_PRICE_POS     := SelectedPos.C_GAUGE_INIT_PRICE_POS;
    data_GAP_DIC_TARIFF_ID          := SelectedPos.GAP_DIC_TARIFF_ID;
    data_GAP_FORCED_TARIFF          := SelectedPos.GAP_FORCED_TARIFF;
    data_C_ROUND_APPLICATION        := SelectedPos.C_ROUND_APPLICATION;
    data_GAS_BALANCE_STATUS         := SelectedPos.GAS_BALANCE_STATUS;
    data_C_ROUND_TYPE               := SelectedPos.C_ROUND_TYPE;
    data_GAS_ROUND_AMOUNT           := SelectedPos.GAS_ROUND_AMOUNT;
    data_GOO_NUMBER_OF_DECIMAL      := SelectedPos.GOO_NUMBER_OF_DECIMAL;
    data_POS_GROSS_UNIT_VALUE2      := SelectedPos.POS_GROSS_UNIT_VALUE2;
    -- Recherche l'ID de l'opération de fabrication
    data_FAL_SCHEDULE_STEP_ID       := DOC_LIB_SUBCONTRACT.getSubcontractOperation(aPositionID);
    -- Recherche le contexte d'application de l'arrondi TVA du code taxe.
    --
    --    0 :   Sans arrondi
    --    1 :   Arrondi finance
    --    2 :   Arrondi logistique
    --    3 :   Arrondi du décompte TVA
    --    sinon Sans arrondi'
    --
    VATRounded                      := 2;   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
    newPOS_VAT_AMOUNT               := 0;
    newPOS_VAT_BASE_AMOUNT          := 0;
    newPOS_NET_TARIFF               := 0;
    newPOS_SPECIAL_TARIFF           := 0;
    newPOS_FLAT_RATE                := 0;

    if SelectedPos.DOC_DOC_POSITION_ID is not null then
      select POS.POS_FINAL_QUANTITY
           , POS.C_GAUGE_TYPE_POS
           , POS.C_DOC_POS_STATUS
        into posFinalQuantityPT
           , posGaugeTypePosPT
           , posStatusPT
        from DOC_POSITION POS
       where POS.DOC_POSITION_ID = SelectedPos.DOC_DOC_POSITION_ID;

      posPositionIDPT  := SelectedPos.DOC_DOC_POSITION_ID;

      if aUpdateCPT then   -- Modification de la quantité à partir du produit terminé.
        if (SelectedPos.C_DOC_POS_STATUS = '04') then
          ----
          -- Recalcul la quantité du composant et son coefficient selon la formule suivante :
          --
          --   Quantité CPT = Ancienne quantité CPT
          --   Coefficient = Quantité CPT / Quantité PT
          --
          newPOS_BASIS_QUANTITY  := SelectedPos.POS_BASIS_QUANTITY;
          newPOS_UTIL_COEFF      := aNewQuantity / posFinalQuantityPT;
        else
          ----
          -- Recalcul la quantité du composant selon la formule suivante :
          --
          --   Quantité CPT = Quantité PT * Coefficient
          --
          newPOS_BASIS_QUANTITY  := aNewQuantity * nvl(newPOS_UTIL_COEFF, 1);
        end if;
      else   -- Modification de la quantité à partir du composant.
        ----
        -- Recalcul la quantité du composant et son coefficient selon la formule suivante :
        --
        --   Quantité CPT = Nouvelle quantité CPT
        --   Coefficient = Quantité CPT / Quantité PT
        --
        newPOS_BASIS_QUANTITY  := aNewQuantity;
        newPOS_UTIL_COEFF      := aNewQuantity / posFinalQuantityPT;
      end if;
    else
      newPOS_BASIS_QUANTITY  := aNewQuantity;
    end if;

    -- Quantité en unité de stockage
    newPOS_BASIS_QUANTITY_SU        :=
                             ACS_FUNCTION.RoundNear(newPOS_BASIS_QUANTITY * SelectedPos.POS_CONVERT_FACTOR, 1 / power(10, SelectedPos.GOO_NUMBER_OF_DECIMAL), 1);
    newPOS_INTER_QUANTITY_SU        := newPOS_BASIS_QUANTITY_SU;
    newPOS_FINAL_QUANTITY_SU        := newPOS_BASIS_QUANTITY_SU;

    ----
    -- Recherche la nouvelle quantité solde si elle est gérée
    --
    if (data_GAS_BALANCE_STATUS = 1) then
      newPOS_BALANCE_QUANTITY   := SelectedPos.POS_BALANCE_QUANTITY -(SelectedPos.POS_BASIS_QUANTITY - newPOS_BASIS_QUANTITY);
      newPOS_BALANCE_QTY_VALUE  := SelectedPos.POS_BALANCE_QTY_VALUE -(SelectedPos.POS_BASIS_QUANTITY - newPOS_BASIS_QUANTITY);
    else
      newPOS_BALANCE_QUANTITY   := 0;
      newPOS_BALANCE_QTY_VALUE  := 0;
    end if;

    close GetPosInfo;

    if (nvl(posGaugeTypePosPT, '0') <> '8') then
      if data_POS_INCLUDE_TAX_TARIFF = 1 then   -- TTC
        -- Calcul des données lors de la modif de la qté en TTC
        PosBasisQtyModifIncl(aPositionID
                           , newPOS_BASIS_QUANTITY
                           , data_POS_CONVERT_FACTOR
                           , data_GCO_GOOD_ID
                           , data_DOC_RECORD_ID
                           , data_POS_CHARGE_AMOUNT
                           , data_POS_DISCOUNT_AMOUNT
                           , data_ACS_TAX_CODE_ID
                           , data_POS_DISCOUNT_RATE
                           , aKeepPosPrice
                           , VATRounded
                           , data_C_ADMIN_DOMAIN
                           , data_C_GAUGE_INIT_PRICE_POS
                           , data_GAP_DIC_TARIFF_ID
                           , data_DOC_DIC_TARIFF_ID
                           , data_GAP_FORCED_TARIFF
                           , data_C_ROUND_APPLICATION
                           , data_C_ROUND_TYPE
                           , data_GAS_ROUND_AMOUNT
                           , nvl(data_PAC_THIRD_TARIFF_ID, data_PAC_THIRD_ID)
                           , data_FAL_SCHEDULE_STEP_ID
                           , data_DMT_DATE_DOCUMENT
                           , data_DMT_DATE_VALUE
                           , data_DMT_DATE_DELIVERY
                           , data_DMT_TARIFF_DATE
                           , data_ACS_FINANCIAL_CURRENCY_ID
                           , newPOS_UNIT_COST_PRICE
                           , newPOS_REF_UNIT_VALUE
                           , newPOS_GROSS_UNIT_VALUE_INCL
                           , newPOS_NET_UNIT_VALUE
                           , newPOS_NET_UNIT_VALUE_INCL
                           , newPOS_DISCOUNT_UNIT_VALUE
                           , newPOS_GROSS_VALUE_INCL
                           , newPOS_NET_VALUE_INCL
                           , newPOS_NET_VALUE_EXCL
                           , newPOS_VAT_AMOUNT
                           , newPOS_VAT_BASE_AMOUNT
                           , newPOS_NET_TARIFF
                           , newPOS_SPECIAL_TARIFF
                           , newPOS_FLAT_RATE
                           , newDIC_TARIFF_ID
                           , newPOS_TARIFF_UNIT
                            );
        newPOS_GROSS_UNIT_VALUE  := 0;
        newPOS_GROSS_VALUE       := 0;
      else   -- HT
        -- Calcul des données lors de la modif de la qté en HT
        PosBasisQtyModifExcl(aPositionID
                           , newPOS_BASIS_QUANTITY
                           , data_POS_CONVERT_FACTOR
                           , data_GCO_GOOD_ID
                           , data_DOC_RECORD_ID
                           , data_POS_CHARGE_AMOUNT
                           , data_POS_DISCOUNT_AMOUNT
                           , data_ACS_TAX_CODE_ID
                           , data_POS_DISCOUNT_RATE
                           , aKeepPosPrice
                           , VATRounded
                           , data_C_ADMIN_DOMAIN
                           , data_C_GAUGE_INIT_PRICE_POS
                           , data_GAP_DIC_TARIFF_ID
                           , data_DOC_DIC_TARIFF_ID
                           , data_GAP_FORCED_TARIFF
                           , data_C_ROUND_APPLICATION
                           , data_C_ROUND_TYPE
                           , data_GAS_ROUND_AMOUNT
                           , nvl(data_PAC_THIRD_TARIFF_ID, data_PAC_THIRD_ID)
                           , data_FAL_SCHEDULE_STEP_ID
                           , data_DMT_DATE_DOCUMENT
                           , data_DMT_DATE_VALUE
                           , data_DMT_DATE_DELIVERY
                           , data_DMT_TARIFF_DATE
                           , data_ACS_FINANCIAL_CURRENCY_ID
                           , newPOS_UNIT_COST_PRICE
                           , newPOS_REF_UNIT_VALUE
                           , newPOS_GROSS_UNIT_VALUE
                           , newPOS_NET_UNIT_VALUE
                           , newPOS_NET_UNIT_VALUE_INCL
                           , newPOS_DISCOUNT_UNIT_VALUE
                           , newPOS_GROSS_VALUE
                           , newPOS_NET_VALUE_INCL
                           , newPOS_NET_VALUE_EXCL
                           , newPOS_VAT_AMOUNT
                           , newPOS_VAT_BASE_AMOUNT
                           , newPOS_NET_TARIFF
                           , newPOS_SPECIAL_TARIFF
                           , newPOS_FLAT_RATE
                           , newDIC_TARIFF_ID
                           , newPOS_TARIFF_UNIT
                            );
        newPOS_GROSS_UNIT_VALUE_INCL  := 0;
        newPOS_GROSS_VALUE_INCL       := 0;
      end if;
    else
      ----
      -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT)
      --
      if (aKeepPosPrice = 1) then
        newPOS_GROSS_UNIT_VALUE2  := data_POS_GROSS_UNIT_VALUE2;
      else
        newPOS_GROSS_UNIT_VALUE2  := nvl(aGrossUnitValueCPT, data_POS_GROSS_UNIT_VALUE2);
      end if;

      newPOS_GROSS_UNIT_VALUE       := 0;
      newPOS_GROSS_UNIT_VALUE_INCL  := 0;
      newPOS_NET_UNIT_VALUE         := 0;
      newPOS_NET_UNIT_VALUE_INCL    := 0;
      newPOS_DISCOUNT_UNIT_VALUE    := 0;
      newPOS_GROSS_VALUE            := 0;
      newPOS_GROSS_VALUE_INCL       := 0;
      newPOS_NET_VALUE_INCL         := 0;
      newPOS_NET_VALUE_EXCL         := 0;
      newPOS_VAT_AMOUNT             := 0;
      newPOS_VAT_BASE_AMOUNT        := 0;
    end if;

    -- Gestion des poids
    if data_GAP_WEIGHT = 1 then
      select nvl(max(MEA_GROSS_WEIGHT), 0)
           , nvl(max(MEA_NET_WEIGHT), 0)
        into newPOS_GROSS_WEIGHT
           , newPOS_NET_WEIGHT
        from GCO_MEASUREMENT_WEIGHT
       where GCO_GOOD_ID = data_GCO_GOOD_ID;

      -- Si pas trouvé de poids, garder les anciens poids
      if newPOS_GROSS_WEIGHT = 0 then
        newPOS_GROSS_WEIGHT  := data_POS_GROSS_WEIGHT;
        newPOS_NET_WEIGHT    := data_POS_NET_WEIGHT;
      else   -- Calcul avec les poids trouvés
        newPOS_GROSS_WEIGHT  := newPOS_BASIS_QUANTITY_SU * newPOS_GROSS_WEIGHT;
        newPOS_NET_WEIGHT    := newPOS_BASIS_QUANTITY_SU * newPOS_NET_WEIGHT;
      end if;
    end if;

    -- Commande de Modification de la position
    update DOC_POSITION
       set POS_UNIT_COST_PRICE = newPOS_UNIT_COST_PRICE
         , POS_REF_UNIT_VALUE = newPOS_REF_UNIT_VALUE
         , POS_GROSS_UNIT_VALUE = newPOS_GROSS_UNIT_VALUE
         , POS_GROSS_UNIT_VALUE_SU = case
                                      when data_POS_CONVERT_FACTOR <> 0 then newPOS_GROSS_UNIT_VALUE / data_POS_CONVERT_FACTOR
                                      else null
                                    end
         , POS_GROSS_UNIT_VALUE2 = newPOS_GROSS_UNIT_VALUE2
         , POS_GROSS_VALUE = newPOS_GROSS_VALUE
         , POS_GROSS_UNIT_VALUE_INCL = newPOS_GROSS_UNIT_VALUE_INCL
         , POS_GROSS_UNIT_VALUE_INCL_SU = case
                                           when data_POS_CONVERT_FACTOR <> 0 then newPOS_GROSS_UNIT_VALUE_INCL / data_POS_CONVERT_FACTOR
                                           else null
                                         end
         , POS_GROSS_VALUE_INCL = newPOS_GROSS_VALUE_INCL
         , POS_NET_UNIT_VALUE = newPOS_NET_UNIT_VALUE
         , POS_NET_UNIT_VALUE_INCL = newPOS_NET_UNIT_VALUE_INCL
         , POS_DISCOUNT_UNIT_VALUE = newPOS_DISCOUNT_UNIT_VALUE
         , POS_NET_VALUE_INCL = newPOS_NET_VALUE_INCL
         , POS_NET_VALUE_EXCL = newPOS_NET_VALUE_EXCL
         , POS_VAT_AMOUNT = newPOS_VAT_AMOUNT
         , POS_VAT_BASE_AMOUNT = newPOS_VAT_BASE_AMOUNT
         , POS_NET_TARIFF = newPOS_NET_TARIFF
         , POS_SPECIAL_TARIFF = newPOS_SPECIAL_TARIFF
         , POS_FLAT_RATE = newPOS_FLAT_RATE
         , POS_VALUE_QUANTITY = newPOS_BASIS_QUANTITY
         , POS_BASIS_QUANTITY = newPOS_BASIS_QUANTITY
         , POS_INTERMEDIATE_QUANTITY = newPOS_BASIS_QUANTITY
         , POS_FINAL_QUANTITY = newPOS_BASIS_QUANTITY
         , POS_BALANCE_QUANTITY = newPOS_BALANCE_QUANTITY
         , POS_BALANCE_QTY_VALUE = newPOS_BALANCE_QTY_VALUE
         , POS_BASIS_QUANTITY_SU = newPOS_BASIS_QUANTITY_SU
         , POS_INTERMEDIATE_QUANTITY_SU = newPOS_INTER_QUANTITY_SU
         , POS_FINAL_QUANTITY_SU = newPOS_FINAL_QUANTITY_SU
         , POS_UTIL_COEFF = newPOS_UTIL_COEFF
         , POS_GROSS_WEIGHT = newPOS_GROSS_WEIGHT
         , POS_NET_WEIGHT = newPOS_NET_WEIGHT
         , DIC_TARIFF_ID = newDIC_TARIFF_ID
         , POS_EFFECTIVE_DIC_TARIFF_ID = newDIC_TARIFF_ID
         , POS_TARIFF_UNIT = newPOS_TARIFF_UNIT
         , POS_TARIFF_INITIALIZED = decode(newDIC_TARIFF_ID, null, 0, 1)
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where DOC_POSITION_ID = aPositionID;

    -- Mise à jour du composé lorsque l'on traite un type de position avec valeur PT égal somme CPT.
    if     (nvl(posGaugeTypePosPT, '0') = '8')
       and (nProcessingCPT = 1) then
      UpdatePositionPTAmounts(aPositionID);
    end if;
  end UpdateQuantityPosition;

  /**
  * procedure PosBasisQtyModifIncl
  *
  * Description : Calcul des données lors de la modif de la qté en TTC
  *
  */
  procedure PosBasisQtyModifIncl(
    inPosID                in     DOC_POSITION.DOC_POSITION_ID%type
  , inBasisQty             in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , inPosConvertFactor     in     DOC_POSITION.POS_CONVERT_FACTOR%type
  , inGoodID               in     DOC_POSITION.GCO_GOOD_ID%type
  , inRecordID             in     DOC_POSITION.DOC_RECORD_ID%type
  , inChargeAmount         in     DOC_POSITION.POS_CHARGE_AMOUNT%type
  , inDiscountAmount       in     DOC_POSITION.POS_DISCOUNT_AMOUNT%type
  , inTaxCode              in     DOC_POSITION.ACS_TAX_CODE_ID%type
  , inDiscountRate         in     DOC_POSITION.POS_DISCOUNT_RATE%type
  , inKeepPosPrice         in     integer
  , inVATRounded           in     integer
  , inAdminDomain          in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , inGaugeInitPricePos    in     DOC_GAUGE_POSITION.C_GAUGE_INIT_PRICE_POS%type
  , inGapDicTarriffID      in     DOC_GAUGE_POSITION.DIC_TARIFF_ID%type
  , inDocDicTarriffID      in     DOC_DOCUMENT.DIC_TARIFF_ID%type
  , inGapForcedTariff      in     DOC_GAUGE_POSITION.GAP_FORCED_TARIFF%type
  , inRoundApplication     in     DOC_GAUGE_POSITION.C_ROUND_APPLICATION%type
  , inRoundType            in     DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type
  , inGasRoundAmount       in     DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type
  , inPacThirdID           in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , inFAL_SCHEDULE_STEP_ID in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type
  , inDmtDateDocument      in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , inDmtDateValue         in     DOC_DOCUMENT.DMT_DATE_VALUE%type
  , inDmtDateDelivery      in     DOC_DOCUMENT.DMT_DATE_DELIVERY%type
  , inDmtDateTariff        in     DOC_DOCUMENT.DMT_TARIFF_DATE%type
  , inACSFinCurID          in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , outUnitCostPrice       in out DOC_POSITION.POS_UNIT_COST_PRICE%type
  , outRefUnitVal          in out DOC_POSITION.POS_REF_UNIT_VALUE%type
  , outGrossUnitValIncl    in out DOC_POSITION.POS_GROSS_UNIT_VALUE_INCL%type
  , outNetUnitVal          in out DOC_POSITION.POS_NET_UNIT_VALUE%type
  , outNetUnitValIncl      in out DOC_POSITION.POS_NET_UNIT_VALUE_INCL%type
  , outDiscountUnitVal     in out DOC_POSITION.POS_DISCOUNT_UNIT_VALUE%type
  , outGrossValIncl        in out DOC_POSITION.POS_GROSS_VALUE_INCL%type
  , outNetValIncl          in out DOC_POSITION.POS_NET_VALUE_INCL%type
  , outNetValExcl          in out DOC_POSITION.POS_NET_VALUE_EXCL%type
  , outVatAmount           in out DOC_POSITION.POS_VAT_AMOUNT%type
  , outVatBaseAmount       in out DOC_POSITION.POS_VAT_BASE_AMOUNT%type
  , outNet                 in out DOC_POSITION.POS_NET_TARIFF%type
  , outSpecial             in out DOC_POSITION.POS_SPECIAL_TARIFF%type
  , outFlatRate            in out DOC_POSITION.POS_FLAT_RATE%type
  , outTariffId            in out DOC_POSITION.DIC_TARIFF_ID%type
  , outTariffUnit          in out DOC_POSITION.POS_TARIFF_UNIT%type
  )
  is
    UnitPrice       DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vRoundType      DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type;
    vGasRoundAmount DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type;
    vACSFinCurID    DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    vDicTariffId    PTC_TARIFF.DIC_TARIFF_ID%type;
    DocCurrencyID   DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    ExchangeRate    DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    BasePrice       DOC_DOCUMENT.DMT_BASE_PRICE%type;
    AmountEUR       number;
  begin
    vRoundType        := inRoundType;
    vGasRoundAmount   := inGasRoundAmount;
    vACSFinCurID      := inACSFinCurID;

    -- Recherche la monnaie du document
    select DOC.ACS_FINANCIAL_CURRENCY_ID
         , DOC.DMT_RATE_OF_EXCHANGE
         , DOC.DMT_BASE_PRICE
      into DocCurrencyID
         , ExchangeRate
         , BasePrice
      from DOC_POSITION POS
         , DOC_DOCUMENT DOC
     where POS.DOC_POSITION_ID = inPosID
       and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;

    -- Recherche prix de revient unitaire
    outUnitCostPrice  := GCO_FUNCTIONS.GetCostPriceWithManagementMode(inGoodID, inPacThirdID);

    -- Initialisation du prix
    if inGaugeInitPricePos <> '0' then
      -- Garder le prix actuel de la position
      if inKeepPosPrice = 1 then
        select POS_GROSS_UNIT_VALUE_INCL
          into UnitPrice
          from DOC_POSITION
         where DOC_POSITION_ID = inPosID;
      else
        if inGapForcedTariff = 1 then
          vDicTariffId  := inGapDicTarriffID;
        else
          vDicTariffId  := nvl(inDocDicTarriffID, inGapDicTarriffID);
        end if;

        -- Recherche prix unitaire position
        UnitPrice  :=
          nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => inGoodID
                                         , iTypePrice           => inGaugeInitPricePos
                                         , iThirdId             => inPacThirdID
                                         , iRecordId            => inRecordID
                                         , iFalScheduleStepId   => inFAL_SCHEDULE_STEP_ID
                                         , ioDicTariff          => vDicTariffId
                                         , iQuantity            => inBasisQty
                                         , iDateRef             => inDmtDateTariff
                                         , ioRoundType          => vRoundType
                                         , ioRoundAmount        => vGasRoundAmount
                                         , ioCurrencyId         => vACSFinCurID
                                         , oNet                 => outNet
                                         , oSpecial             => outSpecial
                                         , oFlatRate            => outFlatRate
                                         , oTariffUnit          => outTariffUnit
                                         , iDicTariff2          => inDocDicTarriffID
                                          ) *
              inPosConvertFactor
            , 0
             );

        -- Si le prix trouvé n'est pas dans la monnaie du document il faut faire une conversion
        if vACSFinCurID <> inACSFinCurID then
          -- Convertir le prix dans la monnaie du document
          -- Cours logistique
          ACS_FUNCTION.ConvertAmount(UnitPrice, vACSFinCurID, inACSFinCurID, inDmtDateTariff, ExchangeRate, BasePrice, 0, AmountEUR, UnitPrice, 5);
        end if;
      end if;

      -- Valeur unitaire reference
      outRefUnitVal        := UnitPrice;
      -- Valeur unitaire brute TTC
      outGrossUnitValIncl  := UnitPrice;

      -- Valeur unitaire remise
      if inDiscountRate = 0 then
        outDiscountUnitVal  := 0;
      else
        outDiscountUnitVal  := outGrossUnitValIncl * inDiscountRate / 100;
      end if;

      -- Valeur brute TTC
      outGrossValIncl      := inBasisQty *(outGrossUnitValIncl - outDiscountUnitVal);
      -- Valeur nette TTC
      outNetValIncl        := outGrossValIncl + inChargeAmount - inDiscountAmount;

      -- Valeur unitaire nette TTC
      if inBasisQty <> 0 then
        outNetUnitValIncl  := outNetValIncl / inBasisQty;
      else
        outNetUnitValIncl  := 0;
      end if;

      -- Calcul Montant TVA position et valeur nette HT
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => inTaxCode
                               , aRefDate         => nvl(inDmtDateDelivery, inDmtDateValue)
                               , aIncludedVat     => 'I'
                               , aRoundAmount     => inVATRounded
                               , aNetAmountExcl   => outNetValExcl
                               , aNetAmountIncl   => outNetValIncl
                               , aVatAmount       => outVatAmount
                                );

      -- Valeur unitaire HT
      if inBasisQty <> 0 then
        outNetUnitVal  := outNetValExcl / inBasisQty;
      else
        outNetUnitVal  := 0;
      end if;
    else
      -- Valeur brute TTC
      outGrossValIncl  := inBasisQty *(outGrossUnitValIncl - outDiscountUnitVal);
      -- Valeur nette TTC
      outNetValIncl    := outGrossValIncl + inChargeAmount - inDiscountAmount;

      --- Valeur unitaire nette TTC
      if (inBasisQty <> 0) then
        outNetUnitValIncl  := outNetValIncl / inBasisQty;
      else
        outNetUnitValIncl  := 0;
      end if;

      -- Calcul Montant TVA et valeur nette HT
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => inTaxCode
                               , aRefDate         => nvl(inDmtDateDelivery, inDmtDateValue)
                               , aIncludedVat     => 'I'
                               , aRoundAmount     => inVATRounded
                               , aNetAmountExcl   => outNetValExcl
                               , aNetAmountIncl   => outNetValIncl
                               , aVatAmount       => outVatAmount
                                );

      -- Valeur unitaire nette HT
      if inBasisQty <> 0 then
        outNetUnitVal  := outNetValExcl / inBasisQty;
      else
        outNetUnitVal  := 0;
      end if;
    end if;

    -- Convertion du Montant TVA -> Montant TVA en monnaie de base
    outVatBaseAmount  :=
                    ACS_FUNCTION.ConvertAmountForView(outVatAmount, DocCurrencyID, ACS_FUNCTION.GetLocalCurrencyId, inDmtDateTariff, ExchangeRate, BasePrice, 0);
  end PosBasisQtyModifIncl;

  /**
  * procedure PosBasisQtyModifExcl
  *
  * Description : Calcul des données lors de la modif de la qté en HT
  *
  */
  procedure PosBasisQtyModifExcl(
    inPosID                in     DOC_POSITION.DOC_POSITION_ID%type
  , inBasisQty             in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , inPosConvertFactor     in     DOC_POSITION.POS_CONVERT_FACTOR%type
  , inGoodID               in     DOC_POSITION.GCO_GOOD_ID%type
  , inRecordID             in     DOC_POSITION.DOC_RECORD_ID%type
  , inChargeAmount         in     DOC_POSITION.POS_CHARGE_AMOUNT%type
  , inDiscountAmount       in     DOC_POSITION.POS_DISCOUNT_AMOUNT%type
  , inTaxCode              in     DOC_POSITION.ACS_TAX_CODE_ID%type
  , inDiscountRate         in     DOC_POSITION.POS_DISCOUNT_RATE%type
  , inKeepPosPrice         in     integer
  , inVATRounded           in     integer
  , inAdminDomain          in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , inGaugeInitPricePos    in     DOC_GAUGE_POSITION.C_GAUGE_INIT_PRICE_POS%type
  , inGapDicTarriffID      in     DOC_GAUGE_POSITION.DIC_TARIFF_ID%type
  , inDocDicTarriffID      in     DOC_DOCUMENT.DIC_TARIFF_ID%type
  , inGapForcedTariff      in     DOC_GAUGE_POSITION.GAP_FORCED_TARIFF%type
  , inRoundApplication     in     DOC_GAUGE_POSITION.C_ROUND_APPLICATION%type
  , inRoundType            in     DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type
  , inGasRoundAmount       in     DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type
  , inPacThirdID           in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , inFAL_SCHEDULE_STEP_ID in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type
  , inDmtDateDocument      in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , inDmtDateValue         in     DOC_DOCUMENT.DMT_DATE_VALUE%type
  , inDmtDateDelivery      in     DOC_DOCUMENT.DMT_DATE_DELIVERY%type
  , inDmtDateTariff        in     DOC_DOCUMENT.DMT_TARIFF_DATE%type
  , inACSFinCurID          in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , outUnitCostPrice       in out DOC_POSITION.POS_UNIT_COST_PRICE%type
  , outRefUnitVal          in out DOC_POSITION.POS_REF_UNIT_VALUE%type
  , outGrossUnitVal        in out DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , outNetUnitVal          in out DOC_POSITION.POS_NET_UNIT_VALUE%type
  , outNetUnitValIncl      in out DOC_POSITION.POS_NET_UNIT_VALUE_INCL%type
  , outDiscountUnitVal     in out DOC_POSITION.POS_DISCOUNT_UNIT_VALUE%type
  , outGrossVal            in out DOC_POSITION.POS_GROSS_VALUE%type
  , outNetValIncl          in out DOC_POSITION.POS_NET_VALUE_INCL%type
  , outNetValExcl          in out DOC_POSITION.POS_NET_VALUE_EXCL%type
  , outVatAmount           in out DOC_POSITION.POS_VAT_AMOUNT%type
  , outVatBaseAmount       in out DOC_POSITION.POS_VAT_BASE_AMOUNT%type
  , outNet                 in out DOC_POSITION.POS_NET_TARIFF%type
  , outSpecial             in out DOC_POSITION.POS_SPECIAL_TARIFF%type
  , outFlatRate            in out DOC_POSITION.POS_FLAT_RATE%type
  , outTariffId            in out DOC_POSITION.DIC_TARIFF_ID%type
  , outTariffUnit          in out DOC_POSITION.POS_TARIFF_UNIT%type
  )
  is
    UnitPrice       DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vRoundType      DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type;
    vGasRoundAmount DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type;
    vACSFinCurID    DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    vDicTariffId    PTC_TARIFF.DIC_TARIFF_ID%type;
    DocCurrencyID   DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    ExchangeRate    DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    BasePrice       DOC_DOCUMENT.DMT_BASE_PRICE%type;
    AmountEUR       number;
  begin
    vRoundType        := inRoundType;
    vGasRoundAmount   := inGasRoundAmount;
    vACSFinCurID      := inACSFinCurID;

    -- Recherche la monnaie du document
    select DOC.ACS_FINANCIAL_CURRENCY_ID
         , DOC.DMT_RATE_OF_EXCHANGE
         , DOC.DMT_BASE_PRICE
      into DocCurrencyID
         , ExchangeRate
         , BasePrice
      from DOC_POSITION POS
         , DOC_DOCUMENT DOC
     where POS.DOC_POSITION_ID = inPosID
       and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;

    -- Recherche prix de revient unitaire
    outUnitCostPrice  := GCO_FUNCTIONS.GetCostPriceWithManagementMode(inGoodID, inPacThirdID);

    -- Initialisation du prix
    if inGaugeInitPricePos <> '0' then
      -- Garder le prix actuel de la position
      if inKeepPosPrice = 1 then
        select POS_GROSS_UNIT_VALUE
          into UnitPrice
          from DOC_POSITION
         where DOC_POSITION_ID = inPosID;
      else
        if inGapForcedTariff = 1 then
          vDicTariffId  := inGapDicTarriffID;
        else
          vDicTariffId  := nvl(inDocDicTarriffID, inGapDicTarriffID);
        end if;

        -- Recherche prix unitaire position
        UnitPrice  :=
          nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => inGoodID
                                         , iTypePrice           => inGaugeInitPricePos
                                         , iThirdId             => inPacThirdID
                                         , iRecordId            => inRecordID
                                         , iFalScheduleStepId   => inFAL_SCHEDULE_STEP_ID
                                         , ioDicTariff          => vDicTariffId
                                         , iQuantity            => inBasisQty
                                         , iDateRef             => inDmtDateTariff
                                         , ioRoundType          => vRoundType
                                         , ioRoundAmount        => vGasRoundAmount
                                         , ioCurrencyId         => vACSFinCurID
                                         , oNet                 => outNet
                                         , oSpecial             => outSpecial
                                         , oFlatRate            => outFlatRate
                                         , oTariffUnit          => outTariffUnit
                                         , iDicTariff2          => inDocDicTarriffID
                                          ) *
              inPosConvertFactor
            , 0
             );

        -- Si le prix trouvé n'est pas dans la monnaie du document il faut faire une conversion
        if vACSFinCurID <> inACSFinCurID then
          -- Convertir le prix dans la monnaie du document
          -- Cours logistique
          ACS_FUNCTION.ConvertAmount(UnitPrice, vACSFinCurID, inACSFinCurID, inDmtDateTariff, ExchangeRate, BasePrice, 0, AmountEUR, UnitPrice, 5);
        end if;

        UnitPrice  :=
          roundPositionAmount(aAmount              => UnitPrice
                            , aDocCurrencyId       => inACSFinCurID
                            , aRoundApplication    => inRoundApplication
                            , aTariffRoundType     => null
                            , aTariffRoundAmount   => 0
                            , aGaugeRoundType      => vRoundType
                            , aGaugeRoundAmount    => vGasRoundAmount
                             );
      end if;

      -- Valeur unitaire reference
      outRefUnitVal    := UnitPrice;
      -- Valeur unitaire brute HT
      outGrossUnitVal  := UnitPrice;

      -- Valeur unitaire remise
      if inDiscountRate = 0 then
        outDiscountUnitVal  := 0;
      else
        outDiscountUnitVal  := outGrossUnitVal * inDiscountRate / 100;
      end if;

      -- Valeur brute HT
      outGrossVal      := inBasisQty *(outGrossUnitVal - outDiscountUnitVal);
      -- Valeur nette HT
      outNetValExcl    := outGrossVal + inChargeAmount - inDiscountAmount;

      -- Valeur unitaire nette HT
      if inBasisQty <> 0 then
        outNetUnitVal  := outNetValExcl / inBasisQty;
      else
        outNetUnitVal  := 0;
      end if;

      -- Calcul Montant TVA position et valeur nette TTC
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => inTaxCode
                               , aRefDate         => nvl(inDmtDateDelivery, inDmtDateValue)
                               , aIncludedVat     => 'E'
                               , aRoundAmount     => inVATRounded
                               , aNetAmountExcl   => outNetValExcl
                               , aNetAmountIncl   => outNetValIncl
                               , aVatAmount       => outVatAmount
                                );

      -- Valeur unitaire TTC
      if inBasisQty <> 0 then
        outNetUnitValIncl  := outNetValIncl / inBasisQty;
      else
        outNetUnitValIncl  := 0;
      end if;
    else
      -- Valeur brute HT
      outGrossVal    := inBasisQty *(outGrossUnitVal - outDiscountUnitVal);
      -- Valeur nette HT
      outNetValExcl  := outGrossVal + inChargeAmount - inDiscountAmount;

      --- Valeur unitaire nette HT
      if (inBasisQty <> 0) then
        outNetUnitVal  := outNetValExcl / inBasisQty;
      else
        outNetUnitVal  := 0;
      end if;

      -- Calcul Montant TVA et valeur nette TTC
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => inTaxCode
                               , aRefDate         => nvl(inDmtDateDelivery, inDmtDateValue)
                               , aIncludedVat     => 'E'
                               , aRoundAmount     => inVATRounded
                               , aNetAmountExcl   => outNetValExcl
                               , aNetAmountIncl   => outNetValIncl
                               , aVatAmount       => outVatAmount
                                );

      -- Valeur unitaire nette HT
      if inBasisQty <> 0 then
        outNetUnitValIncl  := outNetValIncl / inBasisQty;
      else
        outNetUnitValIncl  := 0;
      end if;
    end if;

    -- Code tariff de retour
    outTariffId       := vDicTariffId;
    -- Convertion du Montant TVA -> Montant TVA en monnaie de base
    outVatBaseAmount  :=
                    ACS_FUNCTION.ConvertAmountForView(outVatAmount, DocCurrencyID, ACS_FUNCTION.GetLocalCurrencyId, inDmtDateTariff, ExchangeRate, BasePrice, 0);
  end PosBasisQtyModifExcl;

  /**
  * function GetNewPosNumber
  *
  * Description : Recherche un nuémro de position en tenant compte des
  *                 positions déjà existantes pour le document
  *
  */
  function GetNewPosNumber(Doc_ID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return integer
  is
    PositionNumber integer;
  begin
    /* Recherche le numéro de position à créér

       Si pas de numérotaion des positions alors
         N° Position = -1
       Sinon
         Recherche plus grand n° de position du document
           Si trouvé un n° de pos ( pos_number <> 0 ) alors
             Si "Pas d'increment" (GAS_INCREMENT_NBR) <> NULL Alors
               N° Position = n° de pos trouvé + "Pas d'increment"
             Sinon
               N° Position = n° de pos trouvé + 1
           Sinon ( pos_number <> 0 )
             N° Position = Premier N° du pas (DOC_GAUGE_STRUCTURED.GAS_FIRST_NO)
    */
    select decode(GAS.GAS_POSITION__NUMBERING
                , 0, -1
                ,   -- Pas de numérotation des positions
                  decode(MAX_POS_NBR.POS_NUMBER
                       , 0, nvl(GAS.GAS_FIRST_NO, 1)   -- Première position du document -> 1er N° du pas
                       , MAX_POS_NBR.POS_NUMBER + nvl(GAS.GAS_INCREMENT_NBR, 1)
                        )
                 )
      into PositionNumber
      from DOC_DOCUMENT DOC
         , DOC_GAUGE_STRUCTURED GAS
         , (select nvl(max(POS.POS_NUMBER), 0) POS_NUMBER
              from DOC_POSITION POS
             where POS.DOC_DOCUMENT_ID = Doc_ID) MAX_POS_NBR
     where DOC.DOC_DOCUMENT_ID = Doc_ID
       and DOC.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

    return PositionNumber;
  end GetNewPosNumber;

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
  begin
    DOC_DISCOUNT_CHARGE.UpdatePosAmountsDiscountCharge(Pos_ID, DateRef, IncludeTaxTariff, ChargeAmount, DiscountAmount);
  end UpdatePosAmountsDiscountCharge;

  /**
  * Description : Màj des montants de la position dépendant des remises/taxes
  */
  procedure UpdateAmountsDiscountCharge(aPositionId DOC_POSITION.DOC_POSITION_ID%type)
  is
    cursor crPositionInfo(cPositionId number)
    is
      select   sum(decode(PTC_DISCOUNT_ID, null, 0, PCH_AMOUNT) ) PCH_DISCOUNT_AMOUNT
             , sum(decode(PTC_CHARGE_ID, null, 0, PCH_AMOUNT) ) PCH_CHARGE_AMOUNT
             , DOC_DOCUMENT.DMT_DATE_DOCUMENT
             , DOC_DOCUMENT.DMT_DATE_VALUE
             , DOC_DOCUMENT.DMT_DATE_DELIVERY
             , DOC_POSITION.POS_INCLUDE_TAX_TARIFF
             , DOC_POSITION.POS_RECALC_AMOUNTS
          from DOC_DOCUMENT
             , DOC_POSITION
             , DOC_GAUGE_POSITION
             , DOC_POSITION_CHARGE
         where DOC_POSITION.DOC_POSITION_ID = cPositionId
           and DOC_DOCUMENT.DOC_DOCUMENT_ID = DOC_POSITION.DOC_DOCUMENT_ID
           and DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID = DOC_POSITION.DOC_GAUGE_POSITION_ID
           and DOC_POSITION_CHARGE.DOC_POSITION_ID(+) = DOC_POSITION.DOC_POSITION_ID
      group by DOC_DOCUMENT.DMT_DATE_DOCUMENT
             , DOC_DOCUMENT.DMT_DATE_VALUE
             , DOC_DOCUMENT.DMT_DATE_DELIVERY
             , DOC_POSITION.POS_INCLUDE_TAX_TARIFF
             , DOC_POSITION.POS_RECALC_AMOUNTS;

    tplPositionInfo crPositionInfo%rowtype;
  begin
    -- recherche d'infos sur la position et le document
    open crPositionInfo(aPositionId);

    fetch crPositionInfo
     into tplPositionInfo;

    if tplPositionInfo.POS_RECALC_AMOUNTS = 1 then
      -- Mise à jour des montants de la position
      UpdatePosAmountsDiscountCharge(aPositionId
                                   , nvl(tplPositionInfo.DMT_DATE_DELIVERY, tplPositionInfo.DMT_DATE_VALUE)
                                   , tplPositionInfo.POS_INCLUDE_TAX_TARIFF
                                   , nvl(tplPositionInfo.PCH_CHARGE_AMOUNT, 0)
                                   , nvl(tplPositionInfo.PCH_DISCOUNT_AMOUNT, 0)
                                    );
    end if;

    close crPositionInfo;
  end UpdateAmountsDiscountCharge;

  /**
  * Description
  *   Création/Calcul des remises et taxes d'une position et mise à jour des montants
  *   de la position
  */
  procedure UpdateChargeAndAmount(aPositionId in number, aForce in boolean default false)
  is
    cursor crPositionInfo(cPositionId number)
    is
      select DOC_DOCUMENT.DMT_DATE_DOCUMENT
           , DOC_DOCUMENT.DMT_DATE_VALUE
           , DOC_DOCUMENT.DMT_DATE_DELIVERY
           , nvl(DOC_POSITION.POS_TARIFF_DATE, DOC_DOCUMENT.DMT_TARIFF_DATE) DMT_TARIFF_DATE
           , DOC_POSITION.POS_INCLUDE_TAX_TARIFF
           , DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID
           , DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE
           , DOC_DOCUMENT.DMT_BASE_PRICE
           , DOC_DOCUMENT.PC_LANG_ID
           , DOC_POSITION.POS_RECALC_AMOUNTS
        from DOC_DOCUMENT
           , DOC_POSITION
           , DOC_GAUGE_POSITION
       where DOC_POSITION.DOC_POSITION_ID = cPositionId
         and DOC_DOCUMENT.DOC_DOCUMENT_ID = DOC_POSITION.DOC_DOCUMENT_ID
         and DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID = DOC_POSITION.DOC_GAUGE_POSITION_ID;

    tplPositionInfo crPositionInfo%rowtype;
    updateFlag      number(1);
    chargeAmount    DOC_POSITION.POS_CHARGE_AMOUNT%type;
    discountAmount  DOC_POSITION.POS_DISCOUNT_AMOUNT%type;
  begin
    -- recherche d'infos sur la position et le document
    open crPositionInfo(aPositionId);

    fetch crPositionInfo
     into tplPositionInfo;

    -- calcul des remises/taxes de position
    DOC_DISCOUNT_CHARGE.AutomaticPositionCharge(aPositionId
                                              , nvl(tplPositioninfo.DMT_TARIFF_DATE, tplPositionInfo.DMT_DATE_DOCUMENT)
                                              , tplPositionInfo.ACS_FINANCIAL_CURRENCY_ID
                                              , tplPositionInfo.DMT_RATE_OF_EXCHANGE
                                              , tplPositionInfo.DMT_BASE_PRICE
                                              , tplPositionInfo.PC_LANG_ID
                                              , updateFlag
                                              , chargeAmount
                                              , discountAmount
                                               );
    -- Synchronisation des dates des taxes de positions avec celle de la position
    DOC_IMPUTATION_FUNCTIONS.SynchronizePchImpDates(aPositionId);

    -- si des remises/taxes ont été créées ou recalculées
    -- on met à jour les montants dans la position
    if    updateFlag = 1
       or tplPositionInfo.POS_RECALC_AMOUNTS = 1
       or aForce then
      UpdatePosAmountsDiscountCharge(aPositionId
                                   , nvl(tplPositionInfo.DMT_DATE_DELIVERY, tplPositionInfo.DMT_DATE_VALUE)
                                   , tplPositionInfo.POS_INCLUDE_TAX_TARIFF
                                   , chargeAmount
                                   , discountAmount
                                    );
    end if;

    close crPositionInfo;
  end UpdateChargeAndAmount;

  /**
  * Description
  *   Nouvelle recherche du prix d'une position en fonction de la date passée en paramètre.
  *   Si cette date est nulle, on utilisera la date du document comme en standard.
  *   Les remises taxes
  */
  procedure ReinitPositionPrice(
    aPositionId      in number
  , aDateSeek        in date default null
  , aReinitUnitPrice in number default 1
  , aReInitCharge    in number default 0
  , aHistoryId       in number default null
  , aDocumentMode    in number default 0
  )
  is
    cursor crGeneralInfo(cPositionId DOC_POSITION.DOC_POSITION_ID%type)
    is
      select POS.GCO_GOOD_ID
           , POS.C_GAUGE_TYPE_POS
           , GAP.C_GAUGE_INIT_PRICE_POS
           , GAP.C_ROUND_APPLICATION
           , DMT.DOC_DOCUMENT_ID
           , DMT.PAC_THIRD_ID
           , DMT.PAC_THIRD_TARIFF_ID
           , nvl(POS.DOC_RECORD_ID, DMT.DOC_RECORD_ID) DOC_RECORD_ID
           , DMT.DIC_TARIFF_ID DMT_DIC_TARIFF_ID
           , POS.DIC_TARIFF_ID POS_DIC_TARIFF_ID
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.ACS_FINANCIAL_CURRENCY_ID DOC_CURRENCY_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.PC_LANG_ID
           , DMT.DMT_DATE_DOCUMENT
           , DMT_TARIFF_DATE
           , GAS.C_ROUND_TYPE
           , GAS.GAS_ROUND_AMOUNT
           , POS.POS_BASIS_QUANTITY_SU
           , POS.POS_BASIS_QUANTITY
           , POS.POS_NET_TARIFF
           , POS.POS_SPECIAL_TARIFF
           , POS.POS_FLAT_RATE
           , POS.POS_TARIFF_UNIT
           , POS.POS_INCLUDE_TAX_TARIFF
           , POS.DOC_DOC_POSITION_ID
           , POS.POS_CONVERT_FACTOR
           , DOC_LIB_SUBCONTRACT.getSubcontractOperation(POS.DOC_POSITION_ID) FAL_SCHEDULE_STEP_ID
        from DOC_POSITION POS
           , DOC_GAUGE_POSITION GAP
           , DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
       where POS.DOC_POSITION_ID = cPositionId
         and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;

    tplGeneralInfo      crGeneralInfo%rowtype;
    vGrossUnitValue     DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vGrossUnitValue2    DOC_POSITION.POS_GROSS_UNIT_VALUE2%type;
    vGrossUnitValueIncl DOC_POSITION.POS_GROSS_UNIT_VALUE_INCL%type;
    vGrossValue         DOC_POSITION.POS_GROSS_VALUE%type;
    vGrossValueIncl     DOC_POSITION.POS_GROSS_VALUE_INCL%type;
    vNetValueExcl       DOC_POSITION.POS_NET_VALUE_EXCL%type;
    vNetValueIncl       DOC_POSITION.POS_NET_VALUE_INCL%type;
    vRoundType          PTC_TARIFF.C_ROUND_TYPE%type;
    vRoundAmount        PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    vPtGaugeTypePos     DOC_POSITION.C_GAUGE_TYPE_POS%type;
    vHistoryDetailId    DOC_TARIFF_HISTORY_DETAIL.DOC_TARIFF_HISTORY_DETAIL_ID%type;
  begin
    open crGeneralInfo(aPositionId);

    fetch crGeneralInfo
     into tplGeneralInfo;

    -- recherche du type de position PT ('0' -> pas de position PT)
    select nvl(PT.C_GAUGE_TYPE_POS, '0')
      into vPtGaugeTypePos
      from DOC_POSITION POS
         , DOC_POSITION PT
     where POS.DOC_POSITION_ID = aPositionId
       and PT.DOC_POSITION_ID(+) = POS.DOC_DOC_POSITION_ID;

    -- Pour toutes les positions sauf les 8 qui sont calculées par addition des 81
    if tplGeneralInfo.C_GAUGE_TYPE_POS != '8' then
      -- mise à jour de l'historique
      if aHistoryId is not null then
        select init_id_seq.nextval
          into vHistoryDetailId
          from dual;

        insert into DOC_TARIFF_HISTORY_DETAIL
                    (DOC_TARIFF_HISTORY_DETAIL_ID
                   , DOC_TARIFF_HISTORY_ID
                   , DOC_POSITION_ID
                   , PHD_NUMBER
                   , PHD_GROSS_UNIT_VALUE_BEFORE
                   , PHD_NET_UNIT_VALUE_BEFORE
                   , PHD_CHARGE_AMOUNT_BEFORE
                   , PHD_DISCOUNT_AMOUNT_BEFORE
                   , PHD_VAT_AMOUNT_BEFORE
                   , PHD_GROSS_VALUE_BEFORE
                   , PHD_GROSS_VALUE_INCL_BEFORE
                   , PHD_NET_VALUE_EXCL_BEFORE
                   , PHD_NET_VALUE_INCL_BEFORE
                   , PHD_TARIFF_DATE_BEFORE
                    )
          select vHistoryDetailId
               , aHistoryId
               , DOC_POSITION_ID
               , POS_NUMBER
               , decode(vPtGaugeTypePos, '8', POS_GROSS_UNIT_VALUE2, POS_GROSS_UNIT_VALUE)
               , POS_NET_UNIT_VALUE
               , POS_CHARGE_AMOUNT
               , POS_DISCOUNT_AMOUNT
               , POS_VAT_AMOUNT
               , POS_GROSS_VALUE
               , POS_GROSS_VALUE_INCL
               , POS_NET_VALUE_EXCL
               , POS_NET_VALUE_INCL
               , nvl(pos.pos_tariff_date, nvl(dmt.dmt_tariff_date, dmt.dmt_date_document) )
            from DOC_POSITION POS
               , DOC_DOCUMENT DMT
           where POS.DOC_POSITION_ID = aPositionId
             and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID;
      end if;

      if aReInitUnitPrice = 1 then
        -- on recalcule le prix pour les positions sans produit terminé ('0' dans le test), sans composants
        -- et pour les composants des types 8 et 9
        if vPtGaugeTypePos in('0', '8', '9') then
          if tplGeneralInfo.POS_INCLUDE_TAX_TARIFF = 1 then   -- mode TTC
            declare
              lDicTariffId DOC_POSITION.DIC_TARIFF_ID%type   := nvl(tplGeneralInfo.POS_DIC_TARIFF_ID, tplGeneralInfo.DMT_DIC_TARIFF_ID);
            begin
              vGrossUnitValueIncl  :=
                nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => tplGeneralInfo.GCO_GOOD_ID
                                               , iTypePrice           => tplGeneralInfo.C_GAUGE_INIT_PRICE_POS
                                               , iThirdId             => nvl(tplGeneralInfo.PAC_THIRD_TARIFF_ID, tplGeneralInfo.PAC_THIRD_ID)
                                               , iRecordId            => tplGeneralInfo.DOC_RECORD_ID
                                               , iFalScheduleStepId   => tplGeneralInfo.FAL_SCHEDULE_STEP_ID
                                               , ioDicTariff          => lDicTariffId
                                               , iQuantity            => tplGeneralInfo.POS_BASIS_QUANTITY_SU
                                               , iDateRef             => nvl(aDateSeek, nvl(tplGeneralInfo.DMT_TARIFF_DATE, tplGeneralInfo.DMT_DATE_DOCUMENT) )
                                               , ioRoundType          => vRoundType
                                               , ioRoundAmount        => vRoundAmount
                                               , ioCurrencyId         => tplGeneralInfo.ACS_FINANCIAL_CURRENCY_ID
                                               , oNet                 => tplGeneralInfo.POS_NET_TARIFF
                                               , oSpecial             => tplGeneralInfo.POS_SPECIAL_TARIFF
                                               , oFlatRate            => tplGeneralInfo.POS_FLAT_RATE
                                               , oTariffUnit          => tplGeneralInfo.POS_TARIFF_UNIT
                                               , iDicTariff2          => tplGeneralInfo.DMT_DIC_TARIFF_ID
                                                )
                  , 0
                   );

              if tplGeneralInfo.POS_CONVERT_FACTOR <> 0 then
                vGrossUnitValueIncl  := vGrossUnitValueIncl * tplGeneralInfo.POS_CONVERT_FACTOR;
              end if;
            end;

            if tplGeneralInfo.ACS_FINANCIAL_CURRENCY_ID <> tplGeneralInfo.DOC_CURRENCY_ID then
              vGrossUnitValueIncl  :=
                ACS_FUNCTION.ConvertAmountForView(vGrossUnitValueIncl
                                                , tplGeneralInfo.ACS_FINANCIAL_CURRENCY_ID
                                                , tplGeneralInfo.DOC_CURRENCY_ID
                                                , nvl(aDateSeek, nvl(tplGeneralInfo.DMT_TARIFF_DATE, tplGeneralInfo.DMT_DATE_DOCUMENT) )
                                                , tplGeneralInfo.DMT_RATE_OF_EXCHANGE
                                                , tplGeneralInfo.DMT_BASE_PRICE
                                                , 0
                                                , 5
                                                 );   -- Cours logistique
            end if;

            -- Arrondi Gabarit
            vGrossUnitValueIncl  :=
              roundPositionAmount(vGrossUnitValueIncl
                                , tplGeneralInfo.DOC_CURRENCY_ID
                                , tplGeneralInfo.C_ROUND_APPLICATION
                                , vRoundType
                                , vRoundAmount
                                , tplGeneralInfo.C_ROUND_TYPE
                                , tplGeneralInfo.GAS_ROUND_AMOUNT
                                 );

            -- si on est dans le cas d'un composant d'une position PT '8', seul le champ POS_GR0SS_UNIT_VALUE2
            -- doit être renseigné
            if vPtGaugeTypePos = '8' then
              vGrossUnitValue2     := vGrossUnitValueIncl;
              vGrossUnitValueIncl  := 0;
              vGrossValueIncl      := 0;
              vNetValueIncl        := 0;
            else
              vGrossValueIncl   := tplGeneralInfo.POS_BASIS_QUANTITY * vGrossUnitValueIncl;
              vNetValueIncl     := vGrossValueIncl;
              vGrossUnitValue2  := 0;
            end if;

            update DOC_POSITION
               set POS_GROSS_UNIT_VALUE_INCL = vGrossUnitValueIncl
                 , POS_GROSS_UNIT_VALUE2 = vGrossUnitValue2
                 , POS_GROSS_VALUE_INCL = vGrossValueIncl
                 , POS_NET_VALUE_INCL = vNetValueIncl
                 , POS_TARIFF_INITIALIZED = vGrossUnitValueIncl
                 , POS_NET_TARIFF = nvl(tplGeneralInfo.POS_NET_TARIFF, 0)
                 , POS_SPECIAL_TARIFF = nvl(tplGeneralInfo.POS_SPECIAL_TARIFF, 0)
                 , POS_FLAT_RATE = nvl(tplGeneralInfo.POS_FLAT_RATE, 0)
                 , POS_TARIFF_UNIT = tplGeneralInfo.POS_TARIFF_UNIT
                 , POS_EFFECTIVE_DIC_TARIFF_ID = tplGeneralInfo.POS_DIC_TARIFF_ID
                 , POS_UPDATE_POSITION_CHARGE = 1
                 , POS_TARIFF_DATE =
                     decode(aDateSeek
                          , nvl(tplGeneralInfo.DMT_TARIFF_DATE, tplGeneralInfo.DMT_DATE_DOCUMENT), null
                          , aDateSeek
                           )   -- maj seulement si différent de l'entête
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 , A_DATEMOD = sysdate
             where DOC_POSITION_ID = aPositionId;
          else   -- mode HT
            declare
              lDicTariffId DOC_POSITION.DIC_TARIFF_ID%type   := nvl(tplGeneralInfo.POS_DIC_TARIFF_ID, tplGeneralInfo.DMT_DIC_TARIFF_ID);
            begin
              vGrossUnitValue  :=
                nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => tplGeneralInfo.GCO_GOOD_ID
                                               , iTypePrice           => tplGeneralInfo.C_GAUGE_INIT_PRICE_POS
                                               , iThirdId             => nvl(tplGeneralInfo.PAC_THIRD_TARIFF_ID, tplGeneralInfo.PAC_THIRD_ID)
                                               , iRecordId            => tplGeneralInfo.DOC_RECORD_ID
                                               , iFalScheduleStepId   => tplGeneralInfo.FAL_SCHEDULE_STEP_ID
                                               , ioDicTariff          => lDicTariffId
                                               , iQuantity            => tplGeneralInfo.POS_BASIS_QUANTITY_SU
                                               , iDateRef             => nvl(aDateSeek, nvl(tplGeneralInfo.DMT_TARIFF_DATE, tplGeneralInfo.DMT_DATE_DOCUMENT) )
                                               , ioRoundType          => vRoundType
                                               , ioRoundAmount        => vRoundAmount
                                               , ioCurrencyId         => tplGeneralInfo.ACS_FINANCIAL_CURRENCY_ID
                                               , oNet                 => tplGeneralInfo.POS_NET_TARIFF
                                               , oSpecial             => tplGeneralInfo.POS_SPECIAL_TARIFF
                                               , oFlatRate            => tplGeneralInfo.POS_FLAT_RATE
                                               , oTariffUnit          => tplGeneralInfo.POS_TARIFF_UNIT
                                               , iDicTariff2          => tplGeneralInfo.DMT_DIC_TARIFF_ID
                                                )
                  , 0
                   );

              if tplGeneralInfo.POS_CONVERT_FACTOR <> 0 then
                vGrossUnitValue  := vGrossUnitValue * tplGeneralInfo.POS_CONVERT_FACTOR;
              end if;
            end;

            if nvl(tplGeneralInfo.ACS_FINANCIAL_CURRENCY_ID, tplGeneralInfo.DOC_CURRENCY_ID) <> tplGeneralInfo.DOC_CURRENCY_ID then
              vGrossUnitValue  :=
                ACS_FUNCTION.ConvertAmountForView(vGrossUnitValue
                                                , tplGeneralInfo.ACS_FINANCIAL_CURRENCY_ID
                                                , tplGeneralInfo.DOC_CURRENCY_ID
                                                , nvl(aDateSeek, nvl(tplGeneralInfo.DMT_TARIFF_DATE, tplGeneralInfo.DMT_DATE_DOCUMENT) )
                                                , tplGeneralInfo.DMT_RATE_OF_EXCHANGE
                                                , tplGeneralInfo.DMT_BASE_PRICE
                                                , 0
                                                , 5
                                                 );   -- Cours logistique
            end if;

            -- Arrondi Gabarit
            vGrossUnitValue  :=
              roundPositionAmount(vGrossUnitValue
                                , tplGeneralInfo.DOC_CURRENCY_ID
                                , tplGeneralInfo.C_ROUND_APPLICATION
                                , vRoundType
                                , vRoundAmount
                                , tplGeneralInfo.C_ROUND_TYPE
                                , tplGeneralInfo.GAS_ROUND_AMOUNT
                                 );

            -- si on est dans le cas d'un composant d'une position PT '8', seul le champ POS_GR0SS_UNIT_VALUE2
            -- doit être renseigné
            if vPtGaugeTypePos = '8' then
              vGrossUnitValue2  := vGrossUnitValue;
              vGrossUnitValue   := 0;
              vGrossValue       := 0;
              vNetValueExcl     := 0;
            else
              vGrossValue    := tplGeneralInfo.POS_BASIS_QUANTITY * vGrossUnitValue;
              vNetValueExcl  := vGrossValue;
            end if;

            update DOC_POSITION
               set POS_GROSS_UNIT_VALUE = vGrossUnitValue
                 , POS_GROSS_UNIT_VALUE2 = vGrossUnitValue2
                 , POS_GROSS_VALUE = vGrossValue
                 , POS_NET_VALUE_EXCL = vNetValueExcl
                 , POS_NET_UNIT_VALUE = decode(nvl(tplGeneralInfo.POS_BASIS_QUANTITY, 0), 0, 0, vNetValueExcl / tplGeneralInfo.POS_BASIS_QUANTITY)
                 , POS_TARIFF_INITIALIZED = vGrossUnitValue
                 , POS_NET_TARIFF = nvl(tplGeneralInfo.POS_NET_TARIFF, 0)
                 , POS_SPECIAL_TARIFF = nvl(tplGeneralInfo.POS_SPECIAL_TARIFF, 0)
                 , POS_FLAT_RATE = nvl(tplGeneralInfo.POS_FLAT_RATE, 0)
                 , POS_TARIFF_UNIT = tplGeneralInfo.POS_TARIFF_UNIT
                 , POS_EFFECTIVE_DIC_TARIFF_ID = tplGeneralInfo.POS_DIC_TARIFF_ID
                 , POS_UPDATE_POSITION_CHARGE = 1
                 , POS_TARIFF_DATE =
                     decode(aDateSeek
                          , nvl(tplGeneralInfo.DMT_TARIFF_DATE, tplGeneralInfo.DMT_DATE_DOCUMENT), null
                          , aDateSeek
                           )   -- maj seulement si différent de l'entête
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 , A_DATEMOD = sysdate
             where DOC_POSITION_ID = aPositionId;
          end if;
        end if;
      end if;

      -- si on a demandé de réinitialiser les remises/taxes
      if aReinitCharge = 1 then
        delete from DOC_POSITION_CHARGE
              where DOC_POSITION_ID = aPositionId;

        update DOC_POSITION
           set POS_RECALC_AMOUNTS = 1
             , POS_CREATE_POSITION_CHARGE = 1
             , POS_UPDATE_POSITION_CHARGE = 0
         where DOC_POSITION_ID = aPositionId;
      end if;

      -- Mise à jour des montants de position
      DOC_POSITION_FUNCTIONS.UpdateChargeAndAmount(aPositionId);
    else   -- calcul des posiiton 8 par addition des positions ratachées (elle doivent avoir été préalablement calculées)
      DOC_POSITION_FUNCTIONS.CalculateAmountsPos8(aPositionId, aHistoryId);
    end if;

    -- mise à jour de l'historique
    if aHistoryId is not null then
      update DOC_TARIFF_HISTORY_DETAIL
         set (PHD_GROSS_UNIT_VALUE_AFTER, PHD_NET_UNIT_VALUE_AFTER, PHD_CHARGE_AMOUNT_AFTER, PHD_DISCOUNT_AMOUNT_AFTER, PHD_VAT_AMOUNT_AFTER
            , PHD_GROSS_VALUE_AFTER, PHD_GROSS_VALUE_INCL_AFTER, PHD_NET_VALUE_EXCL_AFTER, PHD_NET_VALUE_INCL_AFTER, PHD_TARIFF_DATE_AFTER) =
               (select decode(vPtGaugeTypePos, '8', POS_GROSS_UNIT_VALUE2, POS_GROSS_UNIT_VALUE)
                     , POS_NET_UNIT_VALUE
                     , POS_CHARGE_AMOUNT
                     , POS_DISCOUNT_AMOUNT
                     , POS_VAT_AMOUNT
                     , POS_GROSS_VALUE
                     , POS_GROSS_VALUE_INCL
                     , POS_NET_VALUE_EXCL
                     , POS_NET_VALUE_INCL
                     , nvl(pos.pos_tariff_date, nvl(dmt.dmt_tariff_date, dmt.dmt_date_document) )
                  from DOC_POSITION POS
                     , DOC_DOCUMENT DMT
                 where DOC_POSITION_ID = aPositionId
                   and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID)
       where DOC_TARIFF_HISTORY_DETAIL_ID = vHistoryDetailId;
    end if;

    -- Position composant de type 8
    -- lorsque l'on est pas en mode reinit de document, on recalcul directement la position 8 liée à la position composant
    if     aDocumentMode = 0
       and vPtGaugeTypePos = '8' then
      ReinitPositionPrice(tplGeneralInfo.DOC_DOC_POSITION_ID, aDateSeek, aReinitUnitPrice, aReInitCharge, aHistoryId, aDocumentMode);
    end if;

    close crGeneralInfo;
  end ReinitPositionPrice;

  /**
  * Description
  *     Mise à jour des positions 'RECAP'
  */
  procedure CalcRecapPos(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    -- Type de position
    gauge_type_pos            doc_position.c_gauge_type_pos%type;
    --Id de la position
    position_id               doc_position.doc_position_id%type;
    -- Variables de totalisation
    tot_basis_quantity        doc_position.pos_basis_quantity%type;
    tot_intermediate_quantity doc_position.pos_intermediate_quantity%type;
    tot_final_quantity        doc_position.pos_final_quantity%type;
    tot_discount_amount       doc_position.pos_discount_amount%type;
    tot_charge_amount         doc_position.pos_charge_amount%type;
    tot_vat_liabled_amount    doc_position.pos_vat_liabled_amount%type;
    tot_vat_total_amount      doc_position.pos_vat_total_amount%type;
    tot_vat_amount            doc_position.pos_vat_amount%type;
    tot_gross_unit_value      doc_position.pos_gross_unit_value%type;
    tot_net_unit_value        doc_position.pos_net_unit_value%type;
    tot_gross_value           doc_position.pos_gross_value%type;
    tot_net_value_excl        doc_position.pos_net_value_excl%type;
    tot_net_value_incl        doc_position.pos_net_value_incl%type;
    tot_net_weight            doc_position.pos_net_weight%type;
    tot_gross_weight          doc_position.pos_gross_weight%type;

    -- curseur sur les positions du document dans l'ordre des num‚ros de position
    cursor POSITION_CURSOR(doc_id number)
    is
      select   DOC_POSITION_ID
             , C_GAUGE_TYPE_POS
             , POS_BASIS_QUANTITY
             , POS_INTERMEDIATE_QUANTITY
             , POS_FINAL_QUANTITY
             , POS_DISCOUNT_AMOUNT
             , POS_CHARGE_AMOUNT
             , POS_VAT_LIABLED_AMOUNT
             , POS_VAT_TOTAL_AMOUNT
             , POS_VAT_AMOUNT
             , POS_GROSS_UNIT_VALUE
             , POS_NET_UNIT_VALUE
             , POS_GROSS_VALUE
             , POS_NET_VALUE_EXCL
             , POS_NET_VALUE_INCL
             , POS_NET_WEIGHT
             , POS_GROSS_WEIGHT
          from DOC_POSITION
         where DOC_DOCUMENT_ID = doc_id
           and C_DOC_POS_STATUS <> '05'   -- Exclure les positions annulées
      order by POS_NUMBER;

    POSITION_TUPLE            POSITION_CURSOR%rowtype;
  begin
    -- initialisation des compteurs de totalisation
    tot_basis_quantity         := 0;
    tot_intermediate_quantity  := 0;
    tot_final_quantity         := 0;
    tot_discount_amount        := 0;
    tot_charge_amount          := 0;
    tot_vat_liabled_amount     := 0;
    tot_vat_total_amount       := 0;
    tot_vat_amount             := 0;
    tot_gross_unit_value       := 0;
    tot_net_unit_value         := 0;
    tot_gross_value            := 0;
    tot_net_value_excl         := 0;
    tot_net_value_incl         := 0;
    tot_net_weight             := 0;
    tot_gross_weight           := 0;

    -- ouverture du curseur
    open POSITION_CURSOR(aDocumentID);

    -- premiŠre position
    fetch POSITION_CURSOR
     into position_tuple;

    while POSITION_CURSOR%found loop
      -- si on est sur une posituion de r‚cap, on la met … jour avec les totaux des lignes pr‚c‚dente
      if position_tuple.c_gauge_type_pos = '6' then
        update DOC_POSITION
           set POS_BASIS_QUANTITY = tot_basis_quantity
             , POS_INTERMEDIATE_QUANTITY = tot_intermediate_quantity
             , POS_FINAL_QUANTITY = tot_final_quantity
             , POS_DISCOUNT_AMOUNT = tot_discount_amount
             , POS_CHARGE_AMOUNT = tot_charge_amount
             , POS_VAT_LIABLED_AMOUNT = tot_vat_liabled_amount
             , POS_VAT_TOTAL_AMOUNT = tot_vat_total_amount
             , POS_VAT_AMOUNT = tot_vat_amount
             , POS_GROSS_UNIT_VALUE = tot_gross_unit_value
             , POS_NET_UNIT_VALUE = tot_net_unit_value
             , POS_GROSS_VALUE = tot_gross_value
             , POS_NET_VALUE_EXCL = tot_net_value_excl
             , POS_NET_VALUE_INCL = tot_net_value_incl
             , POS_NET_WEIGHT = tot_net_weight
             , POS_GROSS_WEIGHT = tot_gross_weight
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
         where DOC_POSITION_ID = position_tuple.doc_position_id;

        -- remise à zéro des compteurs de totalisation
        tot_basis_quantity         := 0;
        tot_intermediate_quantity  := 0;
        tot_final_quantity         := 0;
        tot_discount_amount        := 0;
        tot_charge_amount          := 0;
        tot_vat_liabled_amount     := 0;
        tot_vat_total_amount       := 0;
        tot_vat_amount             := 0;
        tot_gross_unit_value       := 0;
        tot_net_unit_value         := 0;
        tot_gross_value            := 0;
        tot_net_value_excl         := 0;
        tot_net_value_incl         := 0;
        tot_net_weight             := 0;
        tot_gross_weight           := 0;
      else
        -- cumul des positions
        tot_basis_quantity         := tot_basis_quantity + position_tuple.pos_basis_quantity;
        tot_intermediate_quantity  := tot_intermediate_quantity + position_tuple.pos_intermediate_quantity;
        tot_final_quantity         := tot_final_quantity + position_tuple.pos_final_quantity;
        tot_discount_amount        := tot_discount_amount + position_tuple.pos_discount_amount;
        tot_charge_amount          := tot_charge_amount + position_tuple.pos_charge_amount;
        tot_vat_liabled_amount     := tot_vat_liabled_amount + position_tuple.pos_vat_liabled_amount;
        tot_vat_total_amount       := tot_vat_total_amount + position_tuple.pos_vat_total_amount;
        tot_vat_amount             := tot_vat_amount + position_tuple.pos_vat_amount;
        tot_gross_unit_value       := tot_gross_unit_value + position_tuple.pos_gross_unit_value;
        tot_net_unit_value         := tot_net_unit_value + position_tuple.pos_net_unit_value;
        tot_gross_value            := tot_gross_value + position_tuple.pos_gross_value;
        tot_net_value_excl         := tot_net_value_excl + position_tuple.pos_net_value_excl;
        tot_net_value_incl         := tot_net_value_incl + position_tuple.pos_net_value_incl;
        tot_net_weight             := tot_net_weight + position_tuple.pos_net_weight;
        tot_gross_weight           := tot_gross_weight + position_tuple.pos_gross_weight;
      end if;

      -- position suivante
      fetch POSITION_CURSOR
       into position_tuple;
    end loop;

    -- fermeture du curseur des positions
    close POSITION_CURSOR;
  end CalcRecapPos;

  /**
  * procedure CheckPosPriceChangeRequest
  *
  * Description : Vérifie si le prix de la position a été changé par l'utilisateur
  *               et qu'il est different du prix normal du bien
  *               et s'il faut le garder selon config DOC_PRICE_CHANGE_REQUEST
  *
  */
  procedure CheckPosPriceChangeRequest(
    aPositionID in     DOC_POSITION.DOC_POSITION_ID%type
  , PosPrice    out    DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , GoodPrice   out    DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , AskUser     out    integer
  )
  is
    cursor GetPosInfo(aPosID DOC_POSITION.DOC_POSITION_ID%type)
    is
      select POS.POS_GROSS_UNIT_VALUE
           , POS.GCO_GOOD_ID
           , POS.DOC_RECORD_ID
           , POS.POS_CONVERT_FACTOR
           , DOC_LIB_SUBCONTRACT.getSubcontractOperation(POS.DOC_POSITION_ID) FAL_SCHEDULE_STEP_ID
           , POS.POS_BASIS_QUANTITY
           , DOC.DMT_DATE_DOCUMENT
           , DOC.DMT_TARIFF_DATE
           , DOC.ACS_FINANCIAL_CURRENCY_ID
           , DOC.DMT_RATE_OF_EXCHANGE
           , DOC.DMT_BASE_PRICE
           , DOC.DIC_TARIFF_ID DOC_DIC_TARIFF_ID
           , DOC.PAC_THIRD_ID
           , DOC.PAC_THIRD_TARIFF_ID
           , GAP.DIC_TARIFF_ID GAP_DIC_TARIFF_ID
           , GAP.GAP_FORCED_TARIFF
           , GAP.C_GAUGE_INIT_PRICE_POS
           , GAP.GAP_VALUE
           , GAP.C_ROUND_APPLICATION
           , GAS.C_ROUND_TYPE
           , GAS.GAS_ROUND_AMOUNT
           , POS.POS_GROSS_UNIT_VALUE2
           , POS_PT.C_GAUGE_TYPE_POS C_GAUGE_TYPE_POS_PT
        from DOC_POSITION POS
           , DOC_POSITION POS_PT
           , DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE_POSITION GAP
       where POS.DOC_POSITION_ID = aPosID
         and POS_PT.DOC_POSITION_ID(+) = POS.DOC_DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and POS.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID;

    CurrentPos      GetPosInfo%rowtype;
    KeepPosPrice    integer;
    strTariffId     DOC_POSITION.DIC_TARIFF_ID%type;
    intNet          DOC_POSITION.POS_NET_TARIFF%type;
    intSpecial      DOC_POSITION.POS_SPECIAL_TARIFF%type;
    intFlatRate     DOC_POSITION.POS_FLAT_RATE%type;
    numTariffUnit   DOC_POSITION.POS_TARIFF_UNIT%type;
    posQuantity     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type;
    DocCurrencyID   DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    tarifCurrencyID DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    AmountEUR       number;
  begin
    AskUser    := 0;
    PosPrice   := 0;
    GoodPrice  := 0;

    -- Vérifie la valeur de la config DOC_PRICE_CHANGE_REQUEST
    select to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_PRICE_CHANGE_REQUEST'), '0') )
      into KeepPosPrice
      from dual;

    -- La config indique que l'on peut garder le prix de l'utilisateur
    if KeepPosPrice = 1 then
      -- Recherche les données de la position
      open GetPosInfo(aPositionID);

      fetch GetPosInfo
       into CurrentPos;

      DocCurrencyID    := CurrentPos.ACS_FINANCIAL_CURRENCY_ID;
      tarifCurrencyID  := CurrentPos.ACS_FINANCIAL_CURRENCY_ID;

      if (CurrentPos.GAP_VALUE = 1) then
        PosPrice  := CurrentPos.POS_GROSS_UNIT_VALUE;
      end if;

      if (nvl(CurrentPos.C_GAUGE_TYPE_POS_PT, '0') = '8') then
        PosPrice  := CurrentPos.POS_GROSS_UNIT_VALUE2;
      end if;

      -- Initialisation du prix
      if     (CurrentPos.GAP_VALUE = 1)
         and (CurrentPos.C_GAUGE_INIT_PRICE_POS <> '0') then
        if CurrentPos.GAP_FORCED_TARIFF = 1 then
          strTariffId  := CurrentPos.GAP_DIC_TARIFF_ID;
        else
          strTariffId  := nvl(CurrentPos.DOC_DIC_TARIFF_ID, CurrentPos.GAP_DIC_TARIFF_ID);
        end if;

        select sum(PDE_BASIS_QUANTITY)
          into posQuantity
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = aPositionId;

        -- Recherche prix unitaire position
        GoodPrice  :=
          nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => CurrentPos.GCO_GOOD_ID
                                         , iTypePrice           => CurrentPos.C_GAUGE_INIT_PRICE_POS
                                         , iThirdId             => nvl(CurrentPos.PAC_THIRD_TARIFF_ID, CurrentPos.PAC_THIRD_ID)
                                         , iRecordId            => CurrentPos.DOC_RECORD_ID
                                         , iFalScheduleStepId   => CurrentPos.FAL_SCHEDULE_STEP_ID
                                         , ioDicTariff          => strTariffId
                                         , iQuantity            => posQuantity
                                         , iDateRef             => nvl(CurrentPos.DMT_TARIFF_DATE, CurrentPos.DMT_DATE_DOCUMENT)
                                         , ioRoundType          => CurrentPos.C_ROUND_TYPE
                                         , ioRoundAmount        => CurrentPos.GAS_ROUND_AMOUNT
                                         , ioCurrencyId         => tarifCurrencyID
                                         , oNet                 => intNet
                                         , oSpecial             => intSpecial
                                         , oFlatRate            => intFlatRate
                                         , oTariffUnit          => numTariffUnit
                                         , iDicTariff2          => CurrentPos.DOC_DIC_TARIFF_ID
                                          ) *
              CurrentPos.POS_CONVERT_FACTOR
            , 0
             );

        -- Si le prix trouvé n'est pas dans la monnaie du document il faut faire une conversion
        if tarifCurrencyID <> DocCurrencyID then
          -- Convertir le prix dans la monnaie du document
          -- Cours logistique
          ACS_FUNCTION.ConvertAmount(GoodPrice
                                   , tarifCurrencyID
                                   , DocCurrencyID
                                   , nvl(CurrentPos.DMT_TARIFF_DATE, CurrentPos.DMT_DATE_DOCUMENT)
                                   , CurrentPos.DMT_RATE_OF_EXCHANGE
                                   , CurrentPos.DMT_BASE_PRICE
                                   , 0
                                   , AmountEUR
                                   , GoodPrice
                                   , 5
                                    );
        end if;

        -- Arrondi Gabarit
        GoodPrice  :=
                    roundPositionAmount(GoodPrice, DocCurrencyID, CurrentPos.C_ROUND_APPLICATION, null, 0, CurrentPos.C_ROUND_TYPE, CurrentPos.GAS_ROUND_AMOUNT);

        if GoodPrice <> PosPrice then
          AskUser  := 1;
        end if;
      end if;

      close GetPosInfo;
    elsif KeepPosPrice = 2 then   -- Utilise toujours le prix initial
      -- Recherche les données de la position
      open GetPosInfo(aPositionID);

      fetch GetPosInfo
       into CurrentPos;

      PosPrice  := CurrentPos.POS_GROSS_UNIT_VALUE;

      if (nvl(CurrentPos.C_GAUGE_TYPE_POS_PT, '0') = '8') then
        PosPrice  := CurrentPos.POS_GROSS_UNIT_VALUE2;
      end if;

      close GetPosInfo;
    end if;
  end CheckPosPriceChangeRequest;

  /**
  *  procedure UpdatePositionPTAmounts
  *
  *  Description
  *    Màj des poids des positions PT et appel de la méthode
  *      CalculateAmountsPos8 pour le recalcul des montants position type 8
  */
  procedure UpdatePositionPTAmounts(PTPositionID in number)
  is
    GaugeTypePos DOC_POSITION.C_GAUGE_TYPE_POS%type;
    GapWeight    integer;
  begin
    -- Recherche des info sur la position PT
    select POS.C_GAUGE_TYPE_POS
         , GAP.GAP_WEIGHT
      into GaugeTypePos
         , GapWeight
      from DOC_POSITION POS
         , DOC_GAUGE_POSITION GAP
     where POS.DOC_POSITION_ID = PTPositionID
       and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID;

    -- Calcul des montants de la position PT avec la somme des CPT
    if GaugeTypePos = '8' then
      CalculateAmountsPos8(PTPositionID);
    end if;

    -- Calcul des poids
    if GapWeight = 1 then
      update DOC_POSITION
         set (POS_GROSS_WEIGHT, POS_NET_WEIGHT) = (select sum(POS_GROSS_WEIGHT) POS_GROSS_WEIGHT
                                                        , sum(POS_NET_WEIGHT) POS_NET_WEIGHT
                                                     from DOC_POSITION
                                                    where DOC_DOC_POSITION_ID = PTPositionID)
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_POSITION_ID = PTPositionID;
    end if;
  end UpdatePositionPTAmounts;

  /**
  *  procedure CalculateAmountsPos8
  *
  *  Description : Calcul des montants de la position de type 8 après la
  *                  création des positions 81
  */
  procedure CalculateAmountsPos8(aPTPositionID in number, aHistoryId in number default null)
  is
    CPTUnitCostPrice   DOC_POSITION.POS_UNIT_COST_PRICE%type;
    CPTGrossUnitValue  DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    ValueQty           DOC_POSITION.POS_VALUE_QUANTITY%type;
    ChargeAmount       DOC_POSITION.POS_CHARGE_AMOUNT%type;
    DiscountAmount     DOC_POSITION.POS_DISCOUNT_AMOUNT%type;
    TaxCodeID          DOC_POSITION.ACS_TAX_CODE_ID%type;
    DiscountRate       DOC_POSITION.POS_DISCOUNT_RATE%type;
    IncludeTaxTariff   DOC_POSITION.POS_INCLUDE_TAX_TARIFF%type;
    RefUnitValue       DOC_POSITION.POS_REF_UNIT_VALUE%type;
    GrossUnitValueIncl DOC_POSITION.POS_GROSS_UNIT_VALUE_INCL%type;
    GrossUnitValueExcl DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    DiscountUnitValue  DOC_POSITION.POS_DISCOUNT_UNIT_VALUE%type;
    GrossValueIncl     DOC_POSITION.POS_GROSS_VALUE_INCL%type;
    GrossValueExcl     DOC_POSITION.POS_GROSS_VALUE%type;
    NetValueIncl       DOC_POSITION.POS_NET_VALUE_INCL%type;
    NetValueExcl       DOC_POSITION.POS_NET_VALUE_EXCL%type;
    NetUnitValueIncl   DOC_POSITION.POS_NET_UNIT_VALUE_INCL%type;
    NetUnitValueExcl   DOC_POSITION.POS_NET_UNIT_VALUE%type;
    VatAmount          DOC_POSITION.POS_VAT_AMOUNT%type;
    DmtDate            DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    DmtTariffDate      DOC_DOCUMENT.DMT_TARIFF_DATE%type;
    DmtDateValue       DOC_DOCUMENT.DMT_DATE_VALUE%type;
    DmtDateDelivery    DOC_DOCUMENT.DMT_DATE_DELIVERY%type;
    vHistoryDetailId   DOC_TARIFF_HISTORY_DETAIL.DOC_TARIFF_HISTORY_DETAIL_ID%type;
  begin
    -- mise à jour de l'historique
    if aHistoryId is not null then
      begin
        -- recherche une précédentes mises à jour de la position concernant le job courant
        -- pour ne garder les valeurs "Avant"
        select DOC_TARIFF_HISTORY_DETAIL_ID
          into vHistoryDetailId
          from DOC_TARIFF_HISTORY_DETAIL
         where DOC_TARIFF_HISTORY_ID = aHistoryId
           and DOC_POSITION_ID = aPTPositionID;
      exception
        when no_data_found then
          select init_id_seq.nextval
            into vHistoryDetailId
            from dual;

          insert into DOC_TARIFF_HISTORY_DETAIL
                      (DOC_TARIFF_HISTORY_DETAIL_ID
                     , DOC_TARIFF_HISTORY_ID
                     , DOC_POSITION_ID
                     , PHD_NUMBER
                     , PHD_GROSS_UNIT_VALUE_BEFORE
                     , PHD_NET_UNIT_VALUE_BEFORE
                     , PHD_CHARGE_AMOUNT_BEFORE
                     , PHD_DISCOUNT_AMOUNT_BEFORE
                     , PHD_VAT_AMOUNT_BEFORE
                     , PHD_GROSS_VALUE_BEFORE
                     , PHD_GROSS_VALUE_INCL_BEFORE
                     , PHD_NET_VALUE_EXCL_BEFORE
                     , PHD_NET_VALUE_INCL_BEFORE
                     , PHD_TARIFF_DATE_BEFORE
                      )
            select vHistoryDetailId
                 , aHistoryId
                 , DOC_POSITION_ID
                 , POS_NUMBER
                 , POS_GROSS_UNIT_VALUE
                 , POS_NET_UNIT_VALUE
                 , POS_CHARGE_AMOUNT
                 , POS_DISCOUNT_AMOUNT
                 , POS_VAT_AMOUNT
                 , POS_GROSS_VALUE
                 , POS_GROSS_VALUE_INCL
                 , POS_NET_VALUE_EXCL
                 , POS_NET_VALUE_INCL
                 , nvl(pos.pos_tariff_date, nvl(dmt.dmt_tariff_date, dmt.dmt_date_document) )
              from DOC_POSITION POS
                 , DOC_DOCUMENT DMT
             where POS.DOC_POSITION_ID = aPtPositionId
               and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID;
      end;
    end if;

    -- Prix revient unitaire et Valeur unitaire
    select sum(POS_UNIT_COST_PRICE * POS_UTIL_COEFF) PRIX_REVIENT_UNIT
         , sum(POS_GROSS_UNIT_VALUE2 * POS_UTIL_COEFF) VALEUR_UNITAIRE
      into CPTUnitCostPrice
         , CPTGrossUnitValue
      from DOC_POSITION
     where DOC_DOC_POSITION_ID = aPTPositionID;

    -- Valeurs de la position PT
    select nvl(POS.POS_VALUE_QUANTITY, POS.POS_BASIS_QUANTITY) VALUE_QTY
         , POS.POS_CHARGE_AMOUNT
         , POS.POS_DISCOUNT_AMOUNT
         , POS.ACS_TAX_CODE_ID
         , POS.POS_DISCOUNT_RATE
         , POS.POS_INCLUDE_TAX_TARIFF
         , DOC.DMT_DATE_DOCUMENT
         , DOC.DMT_TARIFF_DATE
         , DOC.DMT_DATE_VALUE
         , nvl(POS.POS_DATE_DELIVERY, DOC.DMT_DATE_DELIVERY)
      into ValueQty
         , ChargeAmount
         , DiscountAmount
         , TaxCodeID
         , DiscountRate
         , IncludeTaxTariff
         , DmtDate
         , DmtTariffDate
         , DmtDateValue
         , DmtDateDelivery
      from DOC_POSITION POS
         , DOC_DOCUMENT DOC
     where POS.DOC_POSITION_ID = aPTPositionID
       and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;

    if IncludeTaxTariff = 1 then   -- TTC
      -- Valeur unitaire reference
      RefUnitValue        := CPTGrossUnitValue;
      -- Valeur unitaire brute TTC
      GrossUnitValueIncl  := CPTGrossUnitValue;

      -- Valeur unitaire remise
      if DiscountRate <> 0 then
        DiscountUnitValue  := GrossUnitValueIncl * DiscountRate / 100;
      else
        DiscountUnitValue  := 0;
      end if;

      -- Valeur brute TTC
      GrossValueIncl      := ValueQty *(GrossUnitValueIncl - DiscountUnitValue);
      -- Valeur nette TTC
      NetValueIncl        := GrossValueIncl + ChargeAmount - DiscountAmount;

      -- Valeur unitaire nette TTC
      if ValueQty <> 0 then
        NetUnitValueIncl  := NetValueIncl / ValueQty;
      else
        NetUnitValueIncl  := 0;
      end if;

      -- Calcul Montant TVA position et valeur nette HT
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => TaxCodeID
                               , aRefDate         => nvl(DmtDateDelivery, nvl(DmtTariffDate, DmtDateValue) )
                               , aIncludedVat     => 'I'
                               , aRoundAmount     => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                    , '0') )
                               , aNetAmountExcl   => NetValueExcl
                               , aNetAmountIncl   => NetValueIncl
                               , aVatAmount       => VatAmount
                                );

      -- Valeur unitaire nette HT
      if ValueQty <> 0 then
        NetUnitValueExcl  := NetValueExcl / ValueQty;
      else
        NetUnitValueExcl  := 0;
      end if;

      -- Màj de la position PT
      update DOC_POSITION
         set POS_UNIT_COST_PRICE = CPTUnitCostPrice
           , POS_REF_UNIT_VALUE = RefUnitValue
           , POS_GROSS_UNIT_VALUE_INCL = GrossUnitValueIncl
           , POS_DISCOUNT_UNIT_VALUE = DiscountUnitValue
           , POS_GROSS_VALUE_INCL = GrossValueIncl
           , POS_NET_VALUE_INCL = NetValueIncl
           , POS_NET_VALUE_EXCL = NetValueExcl
           , POS_NET_UNIT_VALUE_INCL = NetUnitValueIncl
           , POS_NET_UNIT_VALUE = NetUnitValueExcl
           , POS_VAT_AMOUNT = VatAmount
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_POSITION_ID = aPTPositionID;
    else   -- HT
      -- Valeur unitaire reference
      RefUnitValue        := CPTGrossUnitValue;
      -- Valeur unitaire brute HT
      GrossUnitValueExcl  := CPTGrossUnitValue;

      -- Valeur unitaire remise
      if DiscountRate <> 0 then
        DiscountUnitValue  := GrossUnitValueExcl * DiscountRate / 100;
      else
        DiscountUnitValue  := 0;
      end if;

      -- Valeur brute HT
      GrossValueExcl      := ValueQty *(GrossUnitValueExcl - DiscountUnitValue);
      -- Valeur nette HT
      NetValueExcl        := GrossValueExcl + ChargeAmount - DiscountAmount;

      -- Valeur unitaire nette HT
      if ValueQty <> 0 then
        NetUnitValueExcl  := NetValueExcl / ValueQty;
      else
        NetUnitValueExcl  := 0;
      end if;

      -- Calcul Montant TVA position et valeur nette TTC
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => TaxCodeID
                               , aRefDate         => nvl(DmtDateDelivery, nvl(DmtTariffDate, DmtDateValue) )
                               , aIncludedVat     => 'E'
                               , aRoundAmount     => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                    , '0') )
                               , aNetAmountExcl   => NetValueExcl
                               , aNetAmountIncl   => NetValueIncl
                               , aVatAmount       => VatAmount
                                );

      -- Valeur unitaire nette TTC
      if ValueQty <> 0 then
        NetUnitValueIncl  := NetValueIncl / ValueQty;
      else
        NetUnitValueIncl  := 0;
      end if;

      -- Màj de la position PT
      update DOC_POSITION
         set POS_UNIT_COST_PRICE = CPTUnitCostPrice
           , POS_REF_UNIT_VALUE = RefUnitValue
           , POS_GROSS_UNIT_VALUE = GrossUnitValueExcl
           , POS_DISCOUNT_UNIT_VALUE = DiscountUnitValue
           , POS_GROSS_VALUE = GrossValueExcl
           , POS_NET_VALUE_INCL = NetValueIncl
           , POS_NET_VALUE_EXCL = NetValueExcl
           , POS_NET_UNIT_VALUE_INCL = NetUnitValueIncl
           , POS_NET_UNIT_VALUE = NetUnitValueExcl
           , POS_VAT_AMOUNT = VatAmount
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_POSITION_ID = aPTPositionID;
    end if;

    -- mise à jour de l'historique
    if aHistoryId is not null then
      update DOC_TARIFF_HISTORY_DETAIL
         set (PHD_GROSS_UNIT_VALUE_AFTER, PHD_NET_UNIT_VALUE_AFTER, PHD_CHARGE_AMOUNT_AFTER, PHD_DISCOUNT_AMOUNT_AFTER, PHD_VAT_AMOUNT_AFTER
            , PHD_GROSS_VALUE_AFTER, PHD_GROSS_VALUE_INCL_AFTER, PHD_NET_VALUE_EXCL_AFTER, PHD_NET_VALUE_INCL_AFTER, PHD_TARIFF_DATE_AFTER) =
               (select POS_GROSS_UNIT_VALUE
                     , POS_NET_UNIT_VALUE
                     , POS_CHARGE_AMOUNT
                     , POS_DISCOUNT_AMOUNT
                     , POS_VAT_AMOUNT
                     , POS_GROSS_VALUE
                     , POS_GROSS_VALUE_INCL
                     , POS_NET_VALUE_EXCL
                     , POS_NET_VALUE_INCL
                     , nvl(pos.pos_tariff_date, nvl(dmt.dmt_tariff_date, dmt.dmt_date_document) )
                  from DOC_POSITION POS
                     , DOC_DOCUMENT DMT
                 where DOC_POSITION_ID = aPTPositionId
                   and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID)
       where DOC_TARIFF_HISTORY_DETAIL_ID = vHistoryDetailId;
    end if;
  end CalculateAmountsPos8;

  /**
  *  procedure GetPosUnitPrice
  *
  *  Description : Recherche le prix unitaire pour la position
  */
  procedure GetPosUnitPrice(
    aGoodID            in     DOC_POSITION.GCO_GOOD_ID%type
  , aQuantity          in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , aConvertFactor     in     DOC_POSITION.POS_CONVERT_FACTOR%type
  , aRecordID          in     DOC_POSITION.DOC_RECORD_ID%type
  , aFalScheduleStepID in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type
  , aDateRef           in     date
  , aAdminDomain       in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aThirdID           in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , aDmtTariffID       in     DOC_DOCUMENT.DIC_TARIFF_ID%type
  , aDocCurrencyID     in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aExchangeRate      in     DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aBasePrice         in     DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aRoundType         in     DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type
  , aRoundAmount       in     DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type
  , aGapTariffID       in     DOC_GAUGE_POSITION.DIC_TARIFF_ID%type
  , aForceTariff       in     DOC_GAUGE_POSITION.GAP_FORCED_TARIFF%type
  , aTypePrice         in     DOC_GAUGE_POSITION.C_GAUGE_INIT_PRICE_POS%type
  , aRoundApplication  in     DOC_GAUGE_POSITION.C_ROUND_APPLICATION%type
  , aUnitPrice         out    number
  , aTariffID          out    DOC_POSITION.DIC_TARIFF_ID%type
  , aNetTariff         out    DOC_POSITION.POS_NET_TARIFF%type
  , aSpecialTariff     out    DOC_POSITION.POS_SPECIAL_TARIFF%type
  , aFlatRate          out    DOC_POSITION.POS_FLAT_RATE%type
  , aTariffUnit        out    DOC_POSITION.POS_TARIFF_UNIT%type
  )
  is
    vCurrencyId    number;
    vThirdTariffID DIC_TARIFF.DIC_TARIFF_ID%type   default null;
    vAmountEUR     number;
    vRoundType     varchar2(10);
    vRoundAmount   number;
  begin
    -- Pas d'initialisation
    if    (aTypePrice = '0')
       or (aGoodID is null) then
      aUnitPrice  := 0;
    else
      vCurrencyId   := aDocCurrencyID;
      vRoundType    := aRoundType;
      vRoundAmount  := aRoundAmount;

      -- Définition du code tarif
      -- Le code tarif est forcé par le gabarit position
      if     (aForceTariff = 1)
         and (aGapTariffID is not null) then
        -- Code tarif du gabarit position
        aTariffID  := aGapTariffID;
      else
        if aThirdID is not null then
          -- Recherche le code tarif client/fournisseur
          select decode(aAdminDomain, '1', SUP.DIC_TARIFF_ID, '2', CUS.DIC_TARIFF_ID, '5', SUP.DIC_TARIFF_ID, nvl(CUS.DIC_TARIFF_ID, SUP.DIC_TARIFF_ID) )
            into vThirdTariffID
            from PAC_THIRD THI
               , PAC_CUSTOM_PARTNER CUS
               , PAC_SUPPLIER_PARTNER SUP
           where THI.PAC_THIRD_ID = aThirdID
             and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
             and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+);
        end if;

        -- Cascade utilisation Code tariff pour la recherche du prix
        -- 1. Code du document
        -- 2. Code du gabarit position
        -- 3. Code du tiers
        aTariffID  := nvl(aDmtTariffID, nvl(aGapTariffID, vThirdTariffID) );
      end if;

      -- Recherche du prix dans les tarifs
      aUnitPrice    :=
        nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => aGoodID
                                       , iTypePrice           => aTypePrice
                                       , iThirdId             => aThirdID
                                       , iRecordId            => aRecordID
                                       , iFalScheduleStepId   => aFalScheduleStepID
                                       , ioDicTariff          => aTariffID
                                       , iQuantity            => abs(aQuantity)
                                       , iDateRef             => aDateRef
                                       , ioRoundType          => vRoundType
                                       , ioRoundAmount        => vRoundAmount
                                       , ioCurrencyId         => vCurrencyId
                                       , oNet                 => aNetTariff
                                       , oSpecial             => aSpecialTariff
                                       , oFlatRate            => aFlatRate
                                       , oTariffUnit          => aTariffUnit
                                       , iDicTariff2          => aDmtTariffID
                                        ) *
            aConvertFactor
          , 0
           );

      -- Si la monnaie du tarif <> de la monnaie du document
      if vCurrencyId <> aDocCurrencyID then
        -- Convertir le prix dans la monnaie du document
        ACS_FUNCTION.ConvertAmount(aUnitPrice, vCurrencyId, aDocCurrencyID, aDateRef, aExchangeRate, aBasePrice, 0, vAmountEUR, aUnitPrice, 5);   -- Cours logistique
      end if;

      -- Arrondi Gabarit
      aUnitPrice    := roundPositionAmount(aUnitPrice, aDocCurrencyID, aRoundApplication, vRoundType, vRoundAmount, aRoundType, aRoundAmount);
    end if;
  end GetPosUnitPrice;

  ----
  -- Indique si le Parent a généré un mouvement
  -- Utilisé pour les positions de type 1,2,3,7,8,9,10
  --
  function IsFatherMvtGenerated(aPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return boolean
  is
    cursor crParentInfo(aPositionID DOC_POSITION.DOC_POSITION_ID%type)
    is
      select POS_FATHER.DOC_POSITION_ID
           , POS_FATHER.C_GAUGE_TYPE_POS
           , POS_FATHER.POS_GENERATE_MOVEMENT
           , PDE_FATHER.DOC_POSITION_DETAIL_ID
        from DOC_POSITION_DETAIL PDE_FATHER
           , DOC_POSITION POS_FATHER
       where PDE_FATHER.DOC_POSITION_DETAIL_ID = (select DOC_DOC_POSITION_DETAIL_ID
                                                    from DOC_POSITION_DETAIL
                                                   where DOC_POSITION_ID = aPositionID
                                                     and rownum = 1)
         and PDE_FATHER.DOC_POSITION_ID = POS_FATHER.DOC_POSITION_ID;

    tplParentInfo     crParentInfo%rowtype;
    nParentPositionID DOC_POSITION.DOC_POSITION_ID%type;
    nGenerateMovement DOC_POSITION.POS_GENERATE_MOVEMENT%type;
    result            boolean;
  begin
    result  := false;

    open crParentInfo(aPositionID);

    fetch crParentInfo
     into tplParentInfo;

    if crParentInfo%found then
      -- Retourne par défaut l'indication d'un mouvement généré sur le père
      -- de la position courante. Cas ou le type de position est différent
      -- de 9 et 10.
      result  := tplParentInfo.POS_GENERATE_MOVEMENT = 1;

      -- Si la position courante est de type 9 ou 10 (kit), il faut effectuer une
      -- nouvelle requête permettant de rechercher si les composants parents ont
      -- générés au moins un mouvement de stock. Nous sommes obligé de le faire,
      -- car les positions de type 9 et 10 ne générent jamais de mouvement, ce
      -- sont uniquement leurs composants (91 et 101) qui crées des mouvements de
      -- stock.
      if tplParentInfo.C_GAUGE_TYPE_POS in('9', '10') then
        select nvl(max(POS_GENERATE_MOVEMENT), 0)
          into nGenerateMovement
          from DOC_POSITION
         where DOC_DOC_POSITION_ID = tplParentInfo.DOC_POSITION_ID;

        result  := nGenerateMovement = 1;
      end if;
    end if;

    return result;
  end IsFatherMvtGenerated;

  /**
  *  Description
  *    Cette fonction va rechercher dans les données complémentaires
  *    la qté à utiliser pour la création de position
  */
  function GetPositionQuantity(
    aGoodID      in DOC_POSITION.GCO_GOOD_ID%type
  , aThirdID     in DOC_DOCUMENT.PAC_THIRD_ID%type
  , aAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type
  )
    return number
  is
    cursor crCDA_Purchase(aGoodID number, aThirdID number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , CPU_ECONOMICAL_QUANTITY
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
         where GCO_GOOD_ID = aGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = aThirdID
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CPU_ECONOMICAL_QUANTITY
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = aGoodID
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = aThirdID
      order by 1
             , 2
             , 4 desc;

    tplCDA_Purchase    crCDA_Purchase%rowtype;

    cursor crCDA_Sale(aGoodID number, aThirdID number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , CSA_QTY_CONDITIONING
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = aGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = aThirdID
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CSA_QTY_CONDITIONING
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = aGoodID
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = aThirdID
      order by 1
             , 2;

    tplCDA_Sale        crCDA_Sale%rowtype;

    cursor crCDA_SubContract(aGoodID number, aThirdID number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , CSU_LOT_QUANTITY
             , CSU_DEFAULT_SUBCONTRACTER
          from GCO_COMPL_DATA_SUBCONTRACT A
         where GCO_GOOD_ID = aGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = aThirdID
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CSU_LOT_QUANTITY
             , CSU_DEFAULT_SUBCONTRACTER
          from GCO_COMPL_DATA_SUBCONTRACT A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = aGoodID
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = aThirdID
      order by 1
             , 2
             , 4 desc;

    tplCDA_SubContract crCDA_SubContract%rowtype;
    Quantity           DOC_POSITION.POS_BASIS_QUANTITY%type;
  begin
    if aAdminDomain = '1' then   -- Achat
      open crCDA_Purchase(aGoodID, aThirdID);

      fetch crCDA_Purchase
       into tplCDA_Purchase;

      Quantity  := nvl(tplCDA_Purchase.CPU_ECONOMICAL_QUANTITY, 0);

      close crCDA_Purchase;
    elsif aAdminDomain = '2' then   -- Vente
      open crCDA_Sale(aGoodID, aThirdID);

      fetch crCDA_Sale
       into tplCDA_Sale;

      Quantity  := nvl(tplCDA_Sale.CSA_QTY_CONDITIONING, 0);

      close crCDA_Sale;
    elsif aAdminDomain = '5' then   -- Sous-traitance
      open crCDA_SubContract(aGoodID, aThirdID);

      fetch crCDA_SubContract
       into tplCDA_SubContract;

      Quantity  := nvl(tplCDA_SubContract.CSU_LOT_QUANTITY, 0);

      close crCDA_SubContract;
    else
      Quantity  := 0;
    end if;

    return Quantity;
  end GetPositionQuantity;

  /**
  * Description
  *   retourne la nouvelle date d'une position en fonction du mode d'interrogation
  */
  function getNewPositionDate(aPositionId in DOC_POSITION.DOC_POSITION_ID%type, aMode in number, aManualDate in date)
    return date
  is
    result date;
  begin
    case aMode
      -- aucun changement
    when 0 then
        return null;
      -- force la date passée en paramètre
    when 1 then
        return aManualDate;
      -- retourne la date valeur du document
    when 2 then
        select DMT.DMT_DATE_VALUE
          into result
          from DOC_POSITION POS
             , DOC_DOCUMENT DMT
         where POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = aPositionId;

        return result;
      -- initialise selon le délai le plus proche (petit)
    when 3 then
        select min(nvl(PDE_FINAL_DELAY, nvl(PDE_INTERMEDIATE_DELAY, PDE_BASIS_DELAY) ) )
          into result
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = aPositionId
           and PDE_BALANCE_QUANTITY > 0;

        return result;
      -- initialise selon le délai le plus éloigné (grand)
    when 4 then
        select min(nvl(PDE_FINAL_DELAY, nvl(PDE_INTERMEDIATE_DELAY, PDE_BASIS_DELAY) ) )
          into result
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = aPositionId
           and PDE_BALANCE_QUANTITY > 0;

        return result;
      else
        return null;
    end case;
  end getNewPositionDate;

  /**
  * Description
  *   Execution de l'arrondi position en tenant compte de la cascade d'arrondi complète
  */
  function roundPositionAmount(
    aAmount            in DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , aDocCurrencyId     in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aRoundApplication  in DOC_GAUGE_POSITION.C_ROUND_APPLICATION%type
  , aTariffRoundType   in PTC_TARIFF.C_ROUND_TYPE%type
  , aTariffRoundAmount in PTC_TARIFF.TRF_ROUND_AMOUNT%type
  , aGaugeRoundType    in DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type
  , aGaugeRoundAmount  in DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type
  )
    return DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  is
    vResult DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
  begin
    -- préinitialisation du résultat
    vResult  := aAmount;

    -- Arrondi monnaie logistique
    if aRoundApplication = '1' then
      select ACS_FUNCTION.PcsRound(vResult, C_ROUND_TYPE_DOC, FIN_ROUNDED_AMOUNT_DOC)
        into vResult
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aDocCurrencyId;
    -- Arrondi tarif + Arrondi monnaie logistique
    elsif aRoundApplication = '2' then
      -- Arrondi Tariff
      if aTariffRoundType is not null then
        vResult  := ACS_FUNCTION.PCSRound(vResult, aTariffRoundType, aTariffRoundAmount);
      end if;

      -- Arrondi logistique
      select ACS_FUNCTION.PcsRound(vResult, C_ROUND_TYPE_DOC, FIN_ROUNDED_AMOUNT_DOC)
        into vResult
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aDocCurrencyId;
    -- Arrondi tarif
    elsif aRoundApplication = '3' then
      if aTariffRoundType is not null then
        vResult  := ACS_FUNCTION.PCSRound(vResult, aTariffRoundType, aTariffRoundAmount);
      end if;
    end if;

    -- Arrondi gabarit
    if aGaugeRoundType is not null then
      vResult  := nvl(ACS_FUNCTION.PCSRound(vResult, aGaugeRoundType, aGaugeRoundAmount), 0);
    end if;

    return vResult;
  end roundPositionAmount;

  /**
  * function CalcPosMvtValue
  * Description
  *   Calcule et retourne la valeur du mouvement de la position dont l'ID est
  *   passé en paramètre (en monnaie de base).
  */
  function CalcPosMvtValue(aPositionId DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    vPosMvtValue number;
  begin
    select sum(DOC_POSITION_DETAIL_FUNCTIONS.CalcPdeMvtValue(PDE.DOC_POSITION_DETAIL_ID) )
      into vPosMvtValue
      from DOC_POSITION_DETAIL PDE
     where PDE.DOC_POSITION_ID = aPositionId;

    return vPosMvtValue;
  end CalcPosMvtValue;

  /**
  * Description
  *   Teste si un document peut être soldé
  */
  function canBalancePosition(aPositionId doc_document.doc_document_id%type, aBalanceMvt number default 0)
    return number
  is
    vDocId    DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vNbBadPos pls_integer;
  begin
    -- regarde si le statut du document ainsi que les flag du gabarit autorise le solde manuel
    select DMT.DOC_DOCUMENT_ID
      into vDocId
      from DOC_DOCUMENT DMT
         , DOC_POSITION POS
         , DOC_GAUGE_STRUCTURED GAS
     where DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and POS.DOC_POSITION_ID = aPositionID
       and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and (    (    aBalanceMvt = 0
                 and GAS.GAS_AUTH_BALANCE_NO_RETURN = 1)
            or (    aBalanceMvt = 1
                and GAS.GAS_AUTH_BALANCE_RETURN = 1) )
       and POS.C_DOC_POS_STATUS in('02', '03')
       and POS.POS_BALANCE_QUANTITY <> 0
       and (   aBalanceMvt = 0
            or DMT.DMT_FINANCIAL_CHARGING = 0);

    -- Si pas d'exception, c'est que le premier test est OK
    -- Recherche de positions empêchant le solde
    select count(*)
      into vNbBadPos
      from DOC_POSITION
         , DOC_POSITION_DETAIL
         , STM_MOVEMENT_KIND
     where DOC_POSITION.STM_MOVEMENT_KIND_ID = STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID
       and MOK_UPDATE_OP = 0
       and DOC_POSITION_DETAIL.DOC_POSITION_ID = DOC_POSITION.DOC_POSITION_ID
       and DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID is not null
       and DOC_POSITION.DOC_POSITION_ID = aPositionId;

    if vNbBadPos > 0 then
      return 0;
    else
      return 1;
    end if;
  exception
    when no_data_found then
      return 0;
  end canBalancePosition;

  /**
  * Description
  *   solder une position
  */
  procedure balancePosition(
    aPositionId      DOC_POSITION.DOC_POSITION_ID%type
  , aBalanceMvt      number default 0
  , aUpdateDocStatus number default 0
  , aWasteTransfert  number default 0
  , aKindBalanced    varchar2 default null
  , aDateBalanced    date default sysdate
  )
  is
    vDocId   DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lGaugeId DOC_POSITION.DOC_GAUGE_ID%type           := FWK_I_LIB_ENTITY.getNumberFieldFromPk(FWK_I_TYP_DOC_ENTITY.gcDocPosition, 'DOC_GAUGE_ID', aPositionId);
    lError   varchar2(1000);
    lnLotID  FAL_LOT.FAL_LOT_ID%type;
    lnTaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lnSUPO   number(1);
  begin
    -- On ne solde que les positions qui sont ni déjà annulées, ni déjà soldées (DEVLOG-16697)
    if FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(FWK_I_TYP_DOC_ENTITY.gcDocPosition, 'C_DOC_POS_STATUS', aPositionId) not in('04', '05') then
      -- Si il s'agit d'un solde avec extourne
      if aBalanceMvt = 1 then
        DOC_INIT_MOVEMENT.SoldePosExtourneMovements(aPositionId);
      end if;

      lnSUPO  := DOC_I_LIB_SUBCONTRACTP.isSUPOGauge(lGaugeId);

      -- Si on est dans le cas d'une CAST et que l'on a demandé le transfert des composants de l'OF lié en stock déchet
      if lnSUPO = 1 then
        if aWasteTransfert = 1 then
          -- transfert du produit terminé en stock déchet et consommation des composants
          if FAL_I_LIB_SUBCONTRACTP.HasPositionMissingParts(aPositionId) = 1 then
            ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - Réception en stock déchet impossible, il manque des composants en stock sous-traitant.'), null, -20900);
          else
            for ltplDetail in (select DOC_POSITION_DETAIL_ID
                                 from DOC_POSITION_DETAIL
                                where DOC_POSITION_ID = aPositionId
                                  and FAL_LOT_ID is not null) loop
              -- Stockage de l'ID de la position déclenchant la réception pour la stocker dans les mouvements de stock provoqué par cette réception }
              COM_I_LIB_LIST_ID_TEMP.setGlobalVar(iVarName => 'DOC_STT_RECEPT_POSITION_ID', iValue => aPositionId);
              FAL_PRC_SUBCONTRACTP.ReceiptBatch(ltplDetail.DOC_POSITION_DETAIL_ID, 1, lError);
              -- Supprimme l'ID de la position déclenchant la réception pour la stocker dans les mouvements de stock provoqué par cette réception
              COM_I_LIB_LIST_ID_TEMP.clearGlobalVar(iVarName => 'DOC_STT_RECEPT_POSITION_ID');

              if lError is not null then
                ra(lError, null, -20901);
              end if;
            end loop;
          end if;
        else
          for ltplDetail in (select FAL_LOT_ID
                                  , PDE_BASIS_QUANTITY - PDE_BALANCE_QUANTITY NEW_LOT_TOTAL_QTY
                                  , DOC_POSITION_DETAIL_ID
                               from DOC_POSITION_DETAIL
                              where DOC_POSITION_ID = aPositionId
                                and FAL_LOT_ID is not null) loop
            -- Mise à jour de la quantité du lot uniquement si la nouvelle quantité du lot > 0 (solde total de la CAST)
            if (ltplDetail.NEW_LOT_TOTAL_QTY > 0) then
              FAL_I_PRC_BATCH.UpdateBatchQuantity(iFalLotId   => ltplDetail.FAL_LOT_ID, iQty => ltplDetail.NEW_LOT_TOTAL_QTY, iLaunched => true
                                                , oError      => lError);

              if lError is not null then
                ra(lError, null, -20902);
              end if;
            end if;

            -- Solde de l'OF lié
            FAL_PRC_SUBCONTRACTP.BalanceBatch(ltplDetail.DOC_POSITION_DETAIL_ID, lError);

            if lError is not null then
              ra(lError, null, -20903);
            end if;
          end loop;
        end if;
      end if;

      -- maj détails de positions
      for tplDetail in (select PDE.DOC_POSITION_DETAIL_ID
                             , PDE.DOC_POSITION_ID
                             , PDE.FAL_LOT_ID
                             , PDE.FAL_SCHEDULE_STEP_ID
                             , PDE.DOC_GAUGE_RECEIPT_ID
                             , PDE.PDE_ST_PT_REJECT
                             , PDE.PDE_ST_CPT_REJECT
                             , pde.PDE_FINAL_QUANTITY_SU - (select nvl(sum(PDE_MOVEMENT_QUANTITY), 0)
                                                              from DOC_POSITION_DETAIL
                                                             where DOC2_DOC_POSITION_DETAIL_ID = pde.DOC_POSITION_DETAIL_ID) PDE_BALANCE_QTY_SU
                             , nvl(MOK.MOK_UPDATE_OP, 0) MOK_UPDATE_OP
                             , DMT_NUMBER
                             , DMT.DMT_DATE_DOCUMENT
                             , DMT.DOC_GAUGE_ID
                             , POS.C_DOC_LOT_TYPE
                             , DMT.PAC_THIRD_ID
                          from DOC_POSITION_DETAIL PDE
                             , DOC_POSITION POS
                             , DOC_DOCUMENT DMT
                             , STM_MOVEMENT_KIND MOK
                             , GCO_GOOD GOO
                         where PDE.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                           and PDE.DOC_POSITION_ID = aPositionId
                           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                           and MOK.STM_MOVEMENT_KIND_ID(+) = POS.STM_MOVEMENT_KIND_ID) loop
        -- Détermine le besoin d'effectuer la mise à jour du suivi opératoire
        if     (lnSUPO = 1)
           and (tplDetail.C_DOC_LOT_TYPE = '001')
           and tplDetail.FAL_SCHEDULE_STEP_ID is null
           and tplDetail.FAL_LOT_ID is not null then
          -- Sous-traitance d'achat
          select max(TAL.FAL_SCHEDULE_STEP_ID)
            into lnTaskID
            from FAL_TASK_LINK TAL
           where TAL.FAL_LOT_ID = tplDetail.FAL_LOT_ID;
        elsif     (tplDetail.MOK_UPDATE_OP = 0)
              and tplDetail.FAL_SCHEDULE_STEP_ID is not null then
          -- Sous-traitance opératoire
          lnTaskID  := tplDetail.FAL_SCHEDULE_STEP_ID;
        end if;

        -- Mise à jour du suivi opératoire
        if lnTaskID is not null then
          lnLotID  := tplDetail.FAL_LOT_ID;

          if lnLotID is null then
            select FAL_LOT_ID
              into lnLotID
              from FAL_TASK_LINK
             where FAL_SCHEDULE_STEP_ID = lnTaskID;
          end if;

          -- Réservation du lot
          FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => lnLotID, aErrorMsg => lError);

          if lError is not null then
            ra(lError, null, -20904);
          end if;

          -- mise à jour des opérations
          FAL_PRC_SUBCONTRACTO.updateOpAtPosBalance(iDocumentNumber      => tplDetail.DMT_NUMBER
                                                  , iDocumentDate        => tplDetail.DMT_DATE_DOCUMENT
                                                  , iBalanceQty          => tplDetail.PDE_BALANCE_QTY_SU
                                                  , iScheduleStepID      => lnTaskID
                                                  , iDocPosDetailID      => tplDetail.DOC_POSITION_DETAIL_ID
                                                  , iDocPosID            => tplDetail.DOC_POSITION_ID
                                                  , iPdeStPtReject       => tplDetail.PDE_ST_PT_REJECT
                                                  , iPdeStCptReject      => tplDetail.PDE_ST_CPT_REJECT
                                                  , iDocGaugeReceiptId   => tplDetail.DOC_GAUGE_RECEIPT_ID
                                                   );
          -- Liberation du lot
          FAL_BATCH_RESERVATION.ReleaseBatch(lnLotID);
        end if;

/*
      -- Sous-traitance d'achat : solde de l'OF lié
      if     tplDetail.C_DOC_LOT_TYPE = '001'
         and DOC_LIB_SUBCONTRACTP.IsSUPOGauge(tplDetail.DOC_GAUGE_ID) = 1 then
        FAL_PRC_SUBCONTRACTP.BalanceBatch(tplDetail.DOC_POSITION_DETAIL_ID, lError);

        if lError is not null then
          ra(lError);
        end if;
      end if;
*/

        -- maj détails de positions
        update DOC_POSITION_DETAIL
           set PDE_BALANCE_QUANTITY = 0
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_DETAIL_ID = tplDetail.DOC_POSITION_DETAIL_ID;
      end loop;

      -- maj position
      update    DOC_POSITION
            set POS_BALANCE_QUANTITY = 0
              , POS_BALANCE_QTY_VALUE = 0
              , POS_BALANCED = 1
              , C_DOC_POS_STATUS = '04'
              , POS_DATE_BALANCED = nvl(POS_DATE_BALANCED, aDateBalanced)
              , POS_QUANTITY_BALANCED = POS_BALANCE_QUANTITY
              , A_DATEMOD = sysdate
              , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
              , C_KIND_BALANCED = (case
                                    when aKindBalanced is not null then aKindBalanced
                                    when aBalanceMvt = 0 then '1'
                                    when aBalanceMvt = 1 then '2'
                                  end)
          where DOC_POSITION_ID = aPositionId
      returning DOC_DOCUMENT_ID
           into vDocId;

      -- Traitement éventuel des positions composants, uniquement pour le solde
      -- d'une position (le solde du document les a déjà pris en compte).
      update DOC_POSITION_DETAIL
         set PDE_BALANCE_QUANTITY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where DOC_POSITION_ID in(select DOC_POSITION_ID
                                  from DOC_POSITION
                                 where DOC_DOC_POSITION_ID = aPositionId);

      update DOC_POSITION
         set POS_BALANCE_QUANTITY = 0
           , POS_BALANCE_QTY_VALUE = 0
           , POS_BALANCED = 1
           , C_DOC_POS_STATUS = '04'
           , POS_DATE_BALANCED = nvl(POS_DATE_BALANCED, aDateBalanced)
           , POS_QUANTITY_BALANCED = POS_BALANCE_QUANTITY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , C_KIND_BALANCED =(case
                                 when aKindBalanced is not null then aKindBalanced
                                 when aBalanceMvt = 0 then '1'
                                 when aBalanceMvt = 1 then '2'
                               end)
       where DOC_POSITION_ID in(select DOC_POSITION_ID
                                  from DOC_POSITION
                                 where DOC_DOC_POSITION_ID = aPositionId);

      -- Si mise à jour du statut du document demandé
      if aUpdateDocStatus = 1 then
        DOC_PRC_DOCUMENT.UpdateDocumentStatus(vDocId);
      end if;
    end if;
  end balancePosition;

  /**
  * Description
  *   Annule une position
  */
  procedure CancelPositionStatus(aPositionID DOC_POSITION.DOC_POSITION_ID%type)
  is
  begin
    -- Mise à jour de l'opération liée aux détails de position d'une commande de sous-traitance opératoire
    for ltplDetail in (select nvl(PDE.FAL_SCHEDULE_STEP_ID, POS.FAL_SCHEDULE_STEP_ID) FAL_SCHEDULE_STEP_ID
                            , PDE.PDE_FINAL_QUANTITY_SU
                         from DOC_POSITION POS
                            , DOC_POSITION_DETAIL PDE
                            , DOC_GAUGE_STRUCTURED GAS
                        where POS.DOC_POSITION_ID = aPositionID
                          and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                          and POS.C_GAUGE_TYPE_POS <> '3'   -- no tools position
                          and POS.C_DOC_POS_STATUS in('01', '02', '03')
                          and POS.STM_MOVEMENT_KIND_ID is null
                          and POS.FAL_SCHEDULE_STEP_ID is not null
                          and GAS.C_GAUGE_TITLE = '1'   -- Purchase order
                          and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID) loop
      -- Appel de la procédure stockée de mise-à-jour opération suppression
      FAL_PRC_SUBCONTRACTO.updateOpAtPosDelete(ltplDetail.FAL_SCHEDULE_STEP_ID, ltplDetail.PDE_FINAL_QUANTITY_SU);
    end loop;

    -- maj détails de positions
    update DOC_POSITION_DETAIL
       set PDE_BALANCE_QUANTITY = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_ID = aPositionId;

    -- maj position
    update DOC_POSITION
       set POS_BALANCE_QUANTITY = 0
         , POS_BALANCE_QTY_VALUE = 0
         , POS_BALANCED = 1
         , C_DOC_POS_STATUS =
                 case
                   when C_GAUGE_TYPE_POS in('4', '5') then '05'
                   when C_DOC_POS_STATUS = '02' then '05'
                   when C_DOC_POS_STATUS = '03' then '04'
                   else C_DOC_POS_STATUS
                 end
         , POS_DATE_BALANCED = nvl(POS_DATE_BALANCED, sysdate)
         , POS_QUANTITY_BALANCED = POS_BALANCE_QUANTITY
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_ID = aPositionId;

    -- Traitement éventuel des positions composants, uniquement pour le solde
    -- d'une position (le solde du document les a déjà pris en compte).
    update DOC_POSITION_DETAIL
       set PDE_BALANCE_QUANTITY = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_ID in(select DOC_POSITION_ID
                                from DOC_POSITION
                               where DOC_DOC_POSITION_ID = aPositionId);

    update DOC_POSITION
       set POS_BALANCE_QUANTITY = 0
         , POS_BALANCE_QTY_VALUE = 0
         , POS_BALANCED = 1
         , C_DOC_POS_STATUS =
                 case
                   when C_GAUGE_TYPE_POS in('4', '5') then '05'
                   when C_DOC_POS_STATUS = '02' then '05'
                   when C_DOC_POS_STATUS = '03' then '04'
                   else C_DOC_POS_STATUS
                 end
         , POS_DATE_BALANCED = nvl(POS_DATE_BALANCED, sysdate)
         , POS_QUANTITY_BALANCED = POS_BALANCE_QUANTITY
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_DOC_POSITION_ID = aPositionId;
  end CancelPositionStatus;

  /**
  * Description
  *   Recherche la nomenclature à utiliser pour la création des composants des positions kits et assemblages.
  */
  function GetInitialNomenclature(aGoodID GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    vVersion          PPS_NOMENCLATURE.NOM_VERSION%type;
    ppsNomenclatureID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    ppsNomenclatureID  := null;

    select PCS.PC_CONFIG.GETCONFIG('DOC_INITIAL_NOM_VERSION')
      into vVersion
      from dual;

    if vVersion is null then
      -- Recherche la nomenclature sans version pour le bien spécifié
      begin
        select PPS_NOMENCLATURE_ID
          into ppsNomenclatureID
          from PPS_NOMENCLATURE PPS
         where PPS.GCO_GOOD_ID = aGoodID
           and PPS.C_TYPE_NOM = '2'
           and PPS.NOM_VERSION is null;
      exception
        when no_data_found then
          ppsNomenclatureID  := null;
      end;
    elsif vVersion <> '[DEFAULT]' then
      -- Recherche la nomenclature qui correspond à la version spécifiée dans la configuration
      begin
        select PPS_NOMENCLATURE_ID
          into ppsNomenclatureID
          from PPS_NOMENCLATURE PPS
         where PPS.GCO_GOOD_ID = aGoodID
           and PPS.C_TYPE_NOM = '2'
           and PPS.NOM_VERSION = vVersion;
      exception
        when no_data_found then
          ppsNomenclatureID  := null;
      end;
    end if;

    if ppsNomenclatureID is null then
      -- Recherche la nomenclature par défaut du bien
      begin
        select PPS_NOMENCLATURE_ID
          into ppsNomenclatureID
          from PPS_NOMENCLATURE PPS
         where PPS.GCO_GOOD_ID = aGoodID
           and PPS.C_TYPE_NOM = '2'
           and PPS.NOM_DEFAULT = 1;
      exception
        when no_data_found then
          ppsNomenclatureID  := null;
      end;
    end if;

    return ppsNomenclatureID;
  end GetInitialNomenclature;
end DOC_POSITION_FUNCTIONS;
