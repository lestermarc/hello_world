--------------------------------------------------------
--  DDL for Package Body DOC_PRC_POSITION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_POSITION" 
is
  /**
  * procedure GetUpdatedFields
  * Description
  *   Méthode permettant de recevoir les valeurs des champs qui sont modifié indirectement par une liste valeur de champs de référence
  *
  */
  procedure GetUpdatedFields(
    inSendPosition      in     DOC_POSITION%rowtype
  , inUpdate            in     number default 0
  , outReceivedPosition in out DOC_POSITION%rowtype
  , outErrorCode        in out varchar2
  , outErrorText        in out varchar2
  )
  is
    cursor GetPosInfo(aPosID DOC_POSITION.DOC_POSITION_ID%type)
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
           , DOC.C_DOCUMENT_STATUS
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
    data_C_DOCUMENT_STATUS         DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
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
    VATRounded                     integer;
    keepPosPrice                   integer;
  begin
    -- Modification de la quantity
    if    inSendPosition.POS_BASIS_QUANTITY is not null
       or inSendPosition.POS_GROSS_UNIT_VALUE is not null
       or inSendPosition.POS_GROSS_UNIT_VALUE_INCL is not null then
      -- Recherche les données de la position
      open GetPosInfo(inSendPosition.DOC_POSITION_ID);

      fetch GetPosInfo
       into SelectedPos;

      outReceivedPosition.POS_UNIT_COST_PRICE           := SelectedPos.POS_UNIT_COST_PRICE;
      outReceivedPosition.POS_REF_UNIT_VALUE            := SelectedPos.POS_REF_UNIT_VALUE;
      outReceivedPosition.POS_GROSS_UNIT_VALUE2         := SelectedPos.POS_GROSS_UNIT_VALUE2;
      outReceivedPosition.POS_GROSS_UNIT_VALUE          := nvl(inSendPosition.POS_GROSS_UNIT_VALUE, SelectedPos.POS_GROSS_UNIT_VALUE);
      outReceivedPosition.POS_GROSS_UNIT_VALUE_INCL     := nvl(inSendPosition.POS_GROSS_UNIT_VALUE_INCL, SelectedPos.POS_GROSS_UNIT_VALUE_INCL);
      outReceivedPosition.POS_NET_UNIT_VALUE            := SelectedPos.POS_NET_UNIT_VALUE;
      outReceivedPosition.POS_NET_UNIT_VALUE_INCL       := SelectedPos.POS_NET_UNIT_VALUE_INCL;
      outReceivedPosition.POS_DISCOUNT_UNIT_VALUE       := SelectedPos.POS_DISCOUNT_UNIT_VALUE;
      outReceivedPosition.POS_GROSS_VALUE               := SelectedPos.POS_GROSS_VALUE;
      outReceivedPosition.POS_GROSS_VALUE_INCL          := SelectedPos.POS_GROSS_VALUE_INCL;
      outReceivedPosition.POS_NET_VALUE_INCL            := SelectedPos.POS_NET_VALUE_INCL;
      outReceivedPosition.POS_UTIL_COEFF                := SelectedPos.POS_UTIL_COEFF;
      data_POS_CONVERT_FACTOR                           := SelectedPos.POS_CONVERT_FACTOR;
      data_POS_INCLUDE_TAX_TARIFF                       := SelectedPos.POS_INCLUDE_TAX_TARIFF;
      data_POS_CONVERT_FACTOR                           := SelectedPos.POS_CONVERT_FACTOR;
      data_GCO_GOOD_ID                                  := SelectedPos.GCO_GOOD_ID;
      data_DOC_RECORD_ID                                := SelectedPos.DOC_RECORD_ID;
      data_POS_CHARGE_AMOUNT                            := SelectedPos.POS_CHARGE_AMOUNT;
      data_POS_DISCOUNT_AMOUNT                          := SelectedPos.POS_DISCOUNT_AMOUNT;
      data_ACS_TAX_CODE_ID                              := SelectedPos.ACS_TAX_CODE_ID;
      data_POS_DISCOUNT_RATE                            := SelectedPos.POS_DISCOUNT_RATE;
      data_POS_GROSS_WEIGHT                             := SelectedPos.POS_GROSS_WEIGHT;
      data_POS_NET_WEIGHT                               := SelectedPos.POS_NET_WEIGHT;
      data_C_DOCUMENT_STATUS                            := SelectedPos.C_DOCUMENT_STATUS;
      data_PAC_THIRD_ID                                 := SelectedPos.PAC_THIRD_ID;
      data_PAC_THIRD_TARIFF_ID                          := SelectedPos.PAC_THIRD_TARIFF_ID;
      data_DOC_DIC_TARIFF_ID                            := SelectedPos.DOC_DIC_TARIFF_ID;
      data_DMT_DATE_DOCUMENT                            := SelectedPos.DMT_DATE_DOCUMENT;
      data_DMT_DATE_VALUE                               := SelectedPos.DMT_DATE_VALUE;
      data_DMT_DATE_DELIVERY                            := SelectedPos.DMT_DATE_DELIVERY;
      data_DMT_TARIFF_DATE                              := SelectedPos.DMT_TARIFF_DATE;
      data_ACS_FINANCIAL_CURRENCY_ID                    := SelectedPos.ACS_FINANCIAL_CURRENCY_ID;
      data_C_ADMIN_DOMAIN                               := SelectedPos.C_ADMIN_DOMAIN;
      data_GAP_WEIGHT                                   := SelectedPos.GAP_WEIGHT;
      data_C_GAUGE_INIT_PRICE_POS                       := SelectedPos.C_GAUGE_INIT_PRICE_POS;
      data_GAP_DIC_TARIFF_ID                            := SelectedPos.GAP_DIC_TARIFF_ID;
      data_GAP_FORCED_TARIFF                            := SelectedPos.GAP_FORCED_TARIFF;
      data_C_ROUND_APPLICATION                          := SelectedPos.C_ROUND_APPLICATION;
      data_GAS_BALANCE_STATUS                           := SelectedPos.GAS_BALANCE_STATUS;
      data_C_ROUND_TYPE                                 := SelectedPos.C_ROUND_TYPE;
      data_GAS_ROUND_AMOUNT                             := SelectedPos.GAS_ROUND_AMOUNT;
      data_GOO_NUMBER_OF_DECIMAL                        := SelectedPos.GOO_NUMBER_OF_DECIMAL;
      data_POS_GROSS_UNIT_VALUE2                        := SelectedPos.POS_GROSS_UNIT_VALUE2;

      -- Recherche l'ID de l'opération de fabrication
      select max(nvl(FAL_SCHEDULE_STEP_ID, 0) )
        into data_FAL_SCHEDULE_STEP_ID
        from DOC_POSITION_DETAIL
       where DOC_POSITION_ID = inSendPosition.DOC_POSITION_ID;

      -- Recherche le contexte d'application de l'arrondi TVA du code taxe.
      --
      --    0 :   Sans arrondi
      --    1 :   Arrondi finance
      --    2 :   Arrondi logistique
      --    3 :   Arrondi du décompte TVA
      --    sinon Sans arrondi'
      --
      VATRounded                                        := 2;   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
      outReceivedPosition.POS_VAT_AMOUNT                := 0;
      outReceivedPosition.POS_VAT_BASE_AMOUNT           := 0;
      outReceivedPosition.POS_NET_TARIFF                := 0;
      outReceivedPosition.POS_SPECIAL_TARIFF            := 0;
      outReceivedPosition.POS_FLAT_RATE                 := 0;
      outReceivedPosition.POS_BASIS_QUANTITY            := inSendPosition.POS_BASIS_QUANTITY;
      outReceivedPosition.POS_INTERMEDIATE_QUANTITY     := inSendPosition.POS_BASIS_QUANTITY;
      outReceivedPosition.POS_FINAL_QUANTITY            := inSendPosition.POS_BASIS_QUANTITY;
      -- Quantité en unité de stockage
      outReceivedPosition.POS_BASIS_QUANTITY_SU         :=
                ACS_FUNCTION.RoundNear(outReceivedPosition.POS_BASIS_QUANTITY * SelectedPos.POS_CONVERT_FACTOR, 1 / power(10, SelectedPos.GOO_NUMBER_OF_DECIMAL), 1);
      outReceivedPosition.POS_INTERMEDIATE_QUANTITY_SU  := outReceivedPosition.POS_BASIS_QUANTITY_SU;
      outReceivedPosition.POS_FINAL_QUANTITY_SU         := outReceivedPosition.POS_BASIS_QUANTITY_SU;

      ----
      -- Recherche la nouvelle quantité solde si elle est gérée
      --
      if (data_GAS_BALANCE_STATUS = 1) then
        outReceivedPosition.POS_BALANCE_QUANTITY   :=
                                                    SelectedPos.POS_BALANCE_QUANTITY
                                                    -(SelectedPos.POS_BASIS_QUANTITY - outReceivedPosition.POS_BASIS_QUANTITY);
        outReceivedPosition.POS_BALANCE_QTY_VALUE  :=
                                                   SelectedPos.POS_BALANCE_QTY_VALUE
                                                   -(SelectedPos.POS_BASIS_QUANTITY - outReceivedPosition.POS_BASIS_QUANTITY);
      else
        outReceivedPosition.POS_BALANCE_QUANTITY   := 0;
        outReceivedPosition.POS_BALANCE_QTY_VALUE  := 0;
      end if;

      close GetPosInfo;

      if data_POS_INCLUDE_TAX_TARIFF = 1 then   -- TTC
                                                --
        if inSendPosition.POS_GROSS_UNIT_VALUE_INCL is not null then
          -- Le prix unitaire est fournit. La procédure PosBasisQtyModifIncl ne permet actuellement pas le passage du prix unitaire.
          -- Seul la conservation du prix est possible. Il faut donc utiliser la demande de conservation du prix de la position et
          -- effectuer la mise à jour directe du prix sur la position. C'est une solution temporaire.
          update DOC_POSITION
             set POS_GROSS_UNIT_VALUE = nvl(outReceivedPosition.POS_GROSS_UNIT_VALUE_INCL, POS_GROSS_UNIT_VALUE_INCL)
           where DOC_POSITION_ID = inSendPosition.DOC_POSITION_ID;

          keepPosPrice  := 1;
        end if;

        -- Calcul des données lors de la modif de la qté en TTC
        DOC_POSITION_FUNCTIONS.PosBasisQtyModifIncl(inSendPosition.DOC_POSITION_ID
                                                  , outReceivedPosition.POS_BASIS_QUANTITY
                                                  , data_POS_CONVERT_FACTOR
                                                  , data_GCO_GOOD_ID
                                                  , data_DOC_RECORD_ID
                                                  , data_POS_CHARGE_AMOUNT
                                                  , data_POS_DISCOUNT_AMOUNT
                                                  , data_ACS_TAX_CODE_ID
                                                  , data_POS_DISCOUNT_RATE
                                                  , keepPosPrice
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
                                                  , outReceivedPosition.POS_UNIT_COST_PRICE
                                                  , outReceivedPosition.POS_REF_UNIT_VALUE
                                                  , outReceivedPosition.POS_GROSS_UNIT_VALUE_INCL
                                                  , outReceivedPosition.POS_NET_UNIT_VALUE
                                                  , outReceivedPosition.POS_NET_UNIT_VALUE_INCL
                                                  , outReceivedPosition.POS_DISCOUNT_UNIT_VALUE
                                                  , outReceivedPosition.POS_GROSS_VALUE_INCL
                                                  , outReceivedPosition.POS_NET_VALUE_INCL
                                                  , outReceivedPosition.POS_NET_VALUE_EXCL
                                                  , outReceivedPosition.POS_VAT_AMOUNT
                                                  , outReceivedPosition.POS_VAT_BASE_AMOUNT
                                                  , outReceivedPosition.POS_NET_TARIFF
                                                  , outReceivedPosition.POS_SPECIAL_TARIFF
                                                  , outReceivedPosition.POS_FLAT_RATE
                                                  , outReceivedPosition.DIC_TARIFF_ID
                                                  , outReceivedPosition.POS_TARIFF_UNIT
                                                   );
        outReceivedPosition.POS_GROSS_UNIT_VALUE  := 0;
        outReceivedPosition.POS_GROSS_VALUE       := 0;
      else   -- HT
        if inSendPosition.POS_GROSS_UNIT_VALUE is not null then
          -- Le prix unitaire est fournit. La procédure PosBasisQtyModifExcl ne permet actuellement pas le passage du prix unitaire.
          -- Seul la conservation du prix est possible. Il faut donc utiliser la demande de conservation du prix de la position et
          -- effectuer la mise à jour directe du prix sur la position. C'est une solution temporaire.
          update DOC_POSITION
             set POS_GROSS_UNIT_VALUE = nvl(outReceivedPosition.POS_GROSS_UNIT_VALUE, POS_GROSS_UNIT_VALUE)
           where DOC_POSITION_ID = inSendPosition.DOC_POSITION_ID;

          keepPosPrice  := 1;
        end if;

        -- Calcul des données lors de la modif de la qté en HT
        DOC_POSITION_FUNCTIONS.PosBasisQtyModifExcl(inSendPosition.DOC_POSITION_ID
                                                  , outReceivedPosition.POS_BASIS_QUANTITY
                                                  , data_POS_CONVERT_FACTOR
                                                  , data_GCO_GOOD_ID
                                                  , data_DOC_RECORD_ID
                                                  , data_POS_CHARGE_AMOUNT
                                                  , data_POS_DISCOUNT_AMOUNT
                                                  , data_ACS_TAX_CODE_ID
                                                  , data_POS_DISCOUNT_RATE
                                                  , keepPosPrice
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
                                                  , outReceivedPosition.POS_UNIT_COST_PRICE
                                                  , outReceivedPosition.POS_REF_UNIT_VALUE
                                                  , outReceivedPosition.POS_GROSS_UNIT_VALUE
                                                  , outReceivedPosition.POS_NET_UNIT_VALUE
                                                  , outReceivedPosition.POS_NET_UNIT_VALUE_INCL
                                                  , outReceivedPosition.POS_DISCOUNT_UNIT_VALUE
                                                  , outReceivedPosition.POS_GROSS_VALUE
                                                  , outReceivedPosition.POS_NET_VALUE_INCL
                                                  , outReceivedPosition.POS_NET_VALUE_EXCL
                                                  , outReceivedPosition.POS_VAT_AMOUNT
                                                  , outReceivedPosition.POS_VAT_BASE_AMOUNT
                                                  , outReceivedPosition.POS_NET_TARIFF
                                                  , outReceivedPosition.POS_SPECIAL_TARIFF
                                                  , outReceivedPosition.POS_FLAT_RATE
                                                  , outReceivedPosition.DIC_TARIFF_ID
                                                  , outReceivedPosition.POS_TARIFF_UNIT
                                                   );
        outReceivedPosition.POS_GROSS_UNIT_VALUE_INCL  := 0;
        outReceivedPosition.POS_GROSS_VALUE_INCL       := 0;
      end if;

      -- Gestion des poids
      if data_GAP_WEIGHT = 1 then
        select nvl(max(MEA_GROSS_WEIGHT), 0)
             , nvl(max(MEA_NET_WEIGHT), 0)
          into outReceivedPosition.POS_GROSS_WEIGHT
             , outReceivedPosition.POS_NET_WEIGHT
          from GCO_MEASUREMENT_WEIGHT
         where GCO_GOOD_ID = data_GCO_GOOD_ID;

        -- Si pas trouvé de poids, garder les anciens poids
        if outReceivedPosition.POS_GROSS_WEIGHT = 0 then
          outReceivedPosition.POS_GROSS_WEIGHT  := data_POS_GROSS_WEIGHT;
          outReceivedPosition.POS_NET_WEIGHT    := data_POS_NET_WEIGHT;
        else   -- Calcul avec les poids trouvés
          outReceivedPosition.POS_GROSS_WEIGHT  := outReceivedPosition.POS_BASIS_QUANTITY_SU * outReceivedPosition.POS_GROSS_WEIGHT;
          outReceivedPosition.POS_NET_WEIGHT    := outReceivedPosition.POS_BASIS_QUANTITY_SU * outReceivedPosition.POS_NET_WEIGHT;
        end if;
      end if;

      -- Commande de Modification de la position
      if inUpdate = 1 then
        update DOC_POSITION
           set POS_UNIT_COST_PRICE = nvl(outReceivedPosition.POS_UNIT_COST_PRICE, POS_UNIT_COST_PRICE)
             , POS_REF_UNIT_VALUE = nvl(outReceivedPosition.POS_REF_UNIT_VALUE, POS_REF_UNIT_VALUE)
             , POS_GROSS_UNIT_VALUE = nvl(outReceivedPosition.POS_GROSS_UNIT_VALUE, POS_GROSS_UNIT_VALUE)
             , POS_GROSS_UNIT_VALUE2 = nvl(outReceivedPosition.POS_GROSS_UNIT_VALUE2, POS_GROSS_UNIT_VALUE2)
             , POS_GROSS_VALUE = nvl(outReceivedPosition.POS_GROSS_VALUE, POS_GROSS_VALUE)
             , POS_GROSS_UNIT_VALUE_INCL = nvl(outReceivedPosition.POS_GROSS_UNIT_VALUE_INCL, POS_GROSS_UNIT_VALUE_INCL)
             , POS_GROSS_VALUE_INCL = nvl(outReceivedPosition.POS_GROSS_VALUE_INCL, POS_GROSS_VALUE_INCL)
             , POS_NET_UNIT_VALUE = nvl(outReceivedPosition.POS_NET_UNIT_VALUE, POS_NET_UNIT_VALUE)
             , POS_NET_UNIT_VALUE_INCL = nvl(outReceivedPosition.POS_NET_UNIT_VALUE_INCL, POS_NET_UNIT_VALUE_INCL)
             , POS_DISCOUNT_UNIT_VALUE = nvl(outReceivedPosition.POS_DISCOUNT_UNIT_VALUE, POS_DISCOUNT_UNIT_VALUE)
             , POS_NET_VALUE_INCL = nvl(outReceivedPosition.POS_NET_VALUE_INCL, POS_NET_VALUE_INCL)
             , POS_NET_VALUE_EXCL = nvl(outReceivedPosition.POS_NET_VALUE_EXCL, POS_NET_VALUE_EXCL)
             , POS_VAT_AMOUNT = nvl(outReceivedPosition.POS_VAT_AMOUNT, POS_VAT_AMOUNT)
             , POS_VAT_BASE_AMOUNT = nvl(outReceivedPosition.POS_VAT_BASE_AMOUNT, POS_VAT_BASE_AMOUNT)
             , POS_NET_TARIFF = nvl(outReceivedPosition.POS_NET_TARIFF, POS_NET_TARIFF)
             , POS_SPECIAL_TARIFF = nvl(outReceivedPosition.POS_SPECIAL_TARIFF, POS_SPECIAL_TARIFF)
             , POS_FLAT_RATE = nvl(outReceivedPosition.POS_FLAT_RATE, POS_FLAT_RATE)
             , POS_VALUE_QUANTITY = nvl(outReceivedPosition.POS_VALUE_QUANTITY, POS_VALUE_QUANTITY)
             , POS_BASIS_QUANTITY = nvl(outReceivedPosition.POS_BASIS_QUANTITY, POS_BASIS_QUANTITY)
             , POS_INTERMEDIATE_QUANTITY = nvl(outReceivedPosition.POS_INTERMEDIATE_QUANTITY, POS_INTERMEDIATE_QUANTITY)
             , POS_FINAL_QUANTITY = nvl(outReceivedPosition.POS_FINAL_QUANTITY, POS_FINAL_QUANTITY)
             , POS_BALANCE_QUANTITY = nvl(outReceivedPosition.POS_BALANCE_QUANTITY, POS_BALANCE_QUANTITY)
             , POS_BALANCE_QTY_VALUE = nvl(outReceivedPosition.POS_BALANCE_QTY_VALUE, POS_BALANCE_QTY_VALUE)
             , POS_BASIS_QUANTITY_SU = nvl(outReceivedPosition.POS_BASIS_QUANTITY_SU, POS_BASIS_QUANTITY_SU)
             , POS_INTERMEDIATE_QUANTITY_SU = nvl(outReceivedPosition.POS_INTERMEDIATE_QUANTITY_SU, POS_INTERMEDIATE_QUANTITY_SU)
             , POS_FINAL_QUANTITY_SU = nvl(outReceivedPosition.POS_FINAL_QUANTITY_SU, POS_FINAL_QUANTITY_SU)
             , POS_UTIL_COEFF = nvl(outReceivedPosition.POS_UTIL_COEFF, POS_UTIL_COEFF)
             , POS_GROSS_WEIGHT = nvl(outReceivedPosition.POS_GROSS_WEIGHT, POS_GROSS_WEIGHT)
             , POS_NET_WEIGHT = nvl(outReceivedPosition.POS_NET_WEIGHT, POS_NET_WEIGHT)
             , DIC_TARIFF_ID = nvl(outReceivedPosition.DIC_TARIFF_ID, DIC_TARIFF_ID)
             , POS_EFFECTIVE_DIC_TARIFF_ID = nvl(outReceivedPosition.DIC_TARIFF_ID, DIC_TARIFF_ID)
             , POS_TARIFF_UNIT = nvl(outReceivedPosition.POS_TARIFF_UNIT, POS_TARIFF_UNIT)
             , POS_TARIFF_INITIALIZED = decode(nvl(outReceivedPosition.DIC_TARIFF_ID, DIC_TARIFF_ID), null, 0, 1)
             , C_DOC_POS_STATUS =
                 decode(nvl(outReceivedPosition.POS_BALANCE_QUANTITY, POS_BALANCE_QUANTITY)
                      , 0, decode(data_C_DOCUMENT_STATUS, '01', '01', '04')
                      , nvl(outReceivedPosition.POS_BASIS_QUANTITY, POS_BASIS_QUANTITY), decode(data_C_DOCUMENT_STATUS, '01', '01', '02')
                      , '03'
                       )
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
         where DOC_POSITION_ID = inSendPosition.DOC_POSITION_ID;
      end if;
    end if;
  end GetUpdatedFields;

  /**
  * Description
  *   Mets à jour le descode d'erreur sur une position
  */
  procedure SetPositionError(iPositionId in DOC_POSITION.DOC_POSITION_ID%type, iError in DOC_POSITION.C_DOC_POS_ERROR%type)
  is
    ltPos FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPosition, ltPos, false);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', iPositionId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'C_DOC_POS_ERROR', iError);

    -- metre a jour le flag dans le cas d'une rupture de stock
    if iError in
         (DOC_I_LIB_CONSTANT.gcDocPosErrorStockOutage
        , DOC_I_LIB_CONSTANT.gcDocPosErrorReAnalyze
        , DOC_I_LIB_CONSTANT.gcDocPosErrorOutdated
        , DOC_I_LIB_CONSTANT.gcDocPosErrorComponent
         ) then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'POS_STOCK_OUTAGE', 1);
    end if;

    FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
    FWK_I_MGT_ENTITY.Release(ltPos);
  end SetPositionError;

  /**
  * Description
  *   report des erreurs composant sur le PT (donner un ou l'autre des paramètres)
  */
  procedure PostponeCptPositionError(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
  is
  begin
    if DOC_I_LIB_POSITION.IsCptError(iPositionId) = 1 then
      SetPositionError(iPositionId, DOC_I_LIB_CONSTANT.gcDocPosErrorComponent);
    end if;
  end PostponeCptPositionError;

  /**
  * Description
  *   report des erreurs composant sur le PT (donner un ou l'autre des paramètres)
  */
  procedure PostponeCptPositionsError(iDocumentId in DOC_POSITION.DOC_DOCUMENT_ID%type)
  is
  begin
    -- liste des positions parentes dont au moins un enfant a une erreur
    for ltplPosition in (select distinct DOC_DOC_POSITION_ID
                                    from DOC_POSITION
                                   where DOC_DOCUMENT_ID = iDocumentId
                                     and DOC_DOC_POSITION_ID is not null
                                     and C_DOC_POS_ERROR is not null) loop
      PostponeCptPositionError(ltplPosition.DOC_DOC_POSITION_ID);
    end loop;
  end PostponeCptPositionsError;

  /**
  * Description
  *   Reset des erreurs sur position (avant contrôle)
  */
  procedure ClearPositionsError(iDocumentId in DOC_POSITION.DOC_DOCUMENT_ID%type)
  is
    ltPos FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplPositions in (select DOC_POSITION_ID
                            from DOC_POSITION
                           where DOC_DOCUMENT_ID = iDocumentId
                             and C_DOC_POS_ERROR is not null) loop
      ClearPositionError(ltplPositions.DOC_POSITION_ID);
    end loop;
  end ClearPositionsError;

  /**
  * procedure ClearPositionError
  * Description
  *   Reset des erreurs sur position (avant contrôle)
  * @created fp 19.11.2013
  * @updated
  * @public
  * @param iPositionId : position
  */
  procedure ClearPositionError(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
  is
    ltPos FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPosition, ltPos, false);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltPos, 'C_DOC_POS_ERROR');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'POS_STOCK_OUTAGE', 0);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', iPositionId);
    FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
    FWK_I_MGT_ENTITY.Release(ltPos);
  end ClearPositionError;

  /**
  * Description
  *   Applique l'emplacement du détail de position sur la position si tout les détails de position portent sur le même emplacement.
  */
  procedure SyncPositionDetailLocation(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
  is
    ltPos              FWK_I_TYP_DEFINITION.t_crud_def;
    lnPosStockID       STM_STOCK.STM_STOCK_ID%type;
    lnPosLocationID    STM_LOCATION.STM_LOCATION_ID%type;
    lnPdeStockID       STM_STOCK.STM_STOCK_ID%type;
    lnPdeLocationID    STM_LOCATION.STM_LOCATION_ID%type;
    lnPosTraStockID    STM_STOCK.STM_STOCK_ID%type;
    lnPosTraLocationID STM_LOCATION.STM_LOCATION_ID%type;
    lnPdeTraStockID    STM_STOCK.STM_STOCK_ID%type;
    lnPdeTraLocationID STM_LOCATION.STM_LOCATION_ID%type;
    lnCanUpdate        number(1);
  begin
    -- Détermine si la position doit être synchronisée
    select PDE.CAN_UPDATE
         , nvl(POS.STM_LOCATION_ID, -1) POS_STM_LOCATION_ID
         , nvl(PDE.STM_LOCATION_ID, -1) PDE_STM_LOCATION_ID
         , nvl(POS.STM_STM_LOCATION_ID, -1) POS_STM_STM_LOCATION_ID
         , nvl(PDE.STM_STM_LOCATION_ID, -1) PDE_STM_STM_LOCATION_ID
      into lnCanUpdate
         , lnPosLocationID
         , lnPdeLocationID
         , lnPosTraLocationID
         , lnPdeTraLocationID
      from DOC_POSITION POS
         , (select case
                     when count(*) = 1 then 1
                     else 0
                   end CAN_UPDATE
                 , max(STM_LOCATION_ID) as STM_LOCATION_ID
                 , max(STM_STM_LOCATION_ID) as STM_STM_LOCATION_ID
              from (select   STM_LOCATION_ID
                           , STM_STM_LOCATION_ID
                        from DOC_POSITION_DETAIL
                       where DOC_POSITION_ID = iPositionId
                    group by STM_LOCATION_ID
                           , STM_STM_LOCATION_ID) ) PDE
     where POS.DOC_POSITION_ID = iPositionId;

    -- Modification de la position si :
    --
    --   un seul détail de position existe ou si tout les détail de position portent le même emplacement et
    --   une différence existe entre les emplacements de la position et les détails de position.
    --
    if     (lnCanUpdate = 1)
       and (    (lnPosLocationID <> lnPdeLocationID)
            or (lnPosTraLocationID <> lnPdeTraLocationID) ) then
      if (lnPosLocationID <> lnPdeLocationID) then
        select STM_STOCK_ID
          into lnPdeStockID
          from STM_LOCATION
         where STM_LOCATION_ID = lnPdeLocationID;
      end if;

      if (lnPosTraLocationID <> lnPdeTraLocationID) then
        select STM_STOCK_ID
          into lnPdeTraStockID
          from STM_LOCATION
         where STM_LOCATION_ID = lnPdeTraLocationID;
      end if;

      FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPosition, ltPos, false);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', iPositionId);

      if lnPdeStockID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'STM_STOCK_ID', lnPdeStockID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'STM_LOCATION_ID', lnPdeLocationID);
      end if;

      if lnPdeTraStockID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'STM_STM_STOCK_ID', lnPdeTraStockID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'STM_STM_LOCATION_ID', lnPdeTraLocationID);
      end if;

      FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
      FWK_I_MGT_ENTITY.release(ltPos);
    end if;
  end SyncPositionDetailLocation;

  /**
  * Description
  *   Contrôle du statut qualité.
  */
  function pVerifyQualityStatus(iDocumentId in DOC_POSITION.DOC_DOCUMENT_ID%type)
    return number
  is
    lError number(1) := 0;
  begin
    -- seul les positions ayant au moins une caractérisation et dont le bien possède une gestion des détails de caracterisation sont contrôlées
    for ltplPosition in (select   POS.DOC_POSITION_ID
                                , PDE.GCO_GOOD_ID
                                , POS.STM_MOVEMENT_KIND_ID
                                , PDE_PIECE
                                , PDE_SET
                                , PDE_VERSION
                             from DOC_POSITION_DETAIL PDE
                                , DOC_POSITION POS
                            where POS.DOC_DOCUMENT_ID = iDocumentId
                              and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                              and PDE.GCO_CHARACTERIZATION_ID is not null
                              and POS.STM_MOVEMENT_KIND_ID is not null
                              and GCO_I_LIB_CHARACTERIZATION.HasQualityStatusManagement(PDE.GCO_GOOD_ID) = 1
                              and POS.C_GAUGE_TYPE_POS not in('7', '8', '9', '10')
                              and POS.C_DOC_POS_ERROR is null   -- on ne contrôle pas si une erreur est déjà détectée
                         order by PDE.GCO_GOOD_ID
                                , PDE.DOC_POSITION_DETAIL_ID) loop
      declare
        lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
          := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => ltplPosition.GCO_GOOD_ID
                                                     , iPiece     => ltplPosition.PDE_PIECE
                                                     , iSet       => ltplPosition.PDE_SET
                                                     , iVersion   => ltplPosition.PDE_VERSION
                                                      );
      begin
        if STM_LIB_MOVEMENT.VerifyQualityStatus(iGoodId            => ltplPosition.GCO_GOOD_ID
                                              , iMovementKindId    => ltplPosition.STM_MOVEMENT_KIND_ID
                                              , iElementNumberId   => lElementNumberId
                                               ) is not null then
          lError  := 1;
          SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorQualityStatus);
        end if;
      end;
    end loop;

    return lError;
  end pVerifyQualityStatus;

  /**
  * Description
  *   Contrôle du statut qualité.
  */
  function pVerifyStorageConditions(iDocumentId in DOC_POSITION.DOC_DOCUMENT_ID%type)
    return number
  is
    lError number(1) := 0;
  begin
    -- Vérifie d'abord qu'on gère les conditions de stockage de façon globale
    if GCO_I_LIB_CONSTANT.gcCfgUseStorageCond then
      -- seul les positions ayant au moins une caractérisation et dont le bien possède une gestion des détails de caracterisation sont contrôlées
      for ltplPosition in (select   POS.DOC_POSITION_ID
                                  , PDE.GCO_GOOD_ID
                                  , POS.STM_MOVEMENT_KIND_ID
                                  , PDE.STM_LOCATION_ID
                               from DOC_POSITION_DETAIL PDE
                                  , DOC_POSITION POS
                              where POS.DOC_DOCUMENT_ID = iDocumentId
                                and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                                and POS.STM_MOVEMENT_KIND_ID is not null
                                and GCO_I_LIB_COMPL_DATA.IsStorageConditionCheck(PDE.GCO_GOOD_ID, null, PDE.STM_LOCATION_ID) = 1
                                and POS.C_GAUGE_TYPE_POS not in('7', '8', '9', '10')
                                and POS.C_DOC_POS_ERROR is null   -- on ne contrôle pas si une erreur est déjà détectée
                           order by PDE.GCO_GOOD_ID
                                  , PDE.DOC_POSITION_DETAIL_ID) loop
        declare
        begin
          if STM_LIB_MOVEMENT.VerifyStorageConditions(iGoodID           => ltplPosition.GCO_GOOD_ID
                                                    , iLocationId       => ltplPosition.STM_LOCATION_ID
                                                    , iMovementKindId   => ltplPosition.STM_MOVEMENT_KIND_ID
                                                     ) is not null then
            lError  := 1;
            SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorStorageCondition);
          end if;
        end;
      end loop;
    end if;

    return lError;
  end pVerifyStorageConditions;

  /**
  * Description
  *   Contrôle des produits périmés
  */
  function pIsOutdatedMvt(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null)
    return number
  is
    lError number(1) := 0;
  begin
    -- seul les positions ayant au moins une caractérisation et dont le bien possède une gestion des détails de caracterisation sont contrôlées
    for ltplPosition in (select   POS.DOC_POSITION_ID
                                , PDE.GCO_GOOD_ID
                                , POS.STM_MOVEMENT_KIND_ID
                                , PDE.PDE_CHRONOLOGICAL
                                , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
                             from DOC_POSITION_DETAIL PDE
                                , DOC_POSITION POS
                                , DOC_DOCUMENT DMT
                            where POS.DOC_DOCUMENT_ID = iDocumentId
                              and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                              and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                              and PDE.PDE_CHRONOLOGICAL is not null
                              and POS.STM_MOVEMENT_KIND_ID is not null
                              and GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(PDE.GCO_GOOD_ID) = 1
                              and POS.C_GAUGE_TYPE_POS not in('7', '8', '9', '10')
                              and POS.C_DOC_POS_ERROR is null   -- on ne contrôle pas si une erreur est déjà détectée
                         order by PDE.GCO_GOOD_ID
                                , PDE.DOC_POSITION_DETAIL_ID) loop
      declare
      begin
        if STM_LIB_MOVEMENT.IsOutdatedMvt(iGoodID           => ltplPosition.GCO_GOOD_ID
                                        , iMovementKindId   => ltplPosition.STM_MOVEMENT_KIND_ID
                                        , iTimeLimitDate    => ltplPosition.PDE_CHRONOLOGICAL
                                        , iMovementDate     => ltplPosition.SMO_MOVEMENT_DATE
                                        , iDocumentID       => iDocumentID
                                         ) = 1 then
          lError  := 1;
          SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorOutdated);
        end if;
      end;
    end loop;

    return lError;
  end pIsOutdatedMvt;

  /**
  * Description
  *   Contrôle des produits à réanalyser
  */
  function pIsRetestNeeded(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null)
    return number
  is
    lError number(1) := 0;
  begin
    -- seul les positions ayant au moins une caractérisation et dont le bien possède une gestion des détails de caracterisation sont contrôlées
    for ltplPosition in (select   POS.DOC_POSITION_ID
                                , PDE.GCO_GOOD_ID
                                , POS.STM_MOVEMENT_KIND_ID
                                , PDE.PDE_PIECE
                                , PDE.PDE_SET
                                , PDE.PDE_VERSION
                                , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
                             from DOC_POSITION_DETAIL PDE
                                , DOC_POSITION POS
                                , DOC_DOCUMENT DMT
                            where POS.DOC_DOCUMENT_ID = iDocumentId
                              and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                              and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                              and POS.STM_MOVEMENT_KIND_ID is not null
                              and (   PDE.PDE_PIECE is not null
                                   or PDE.PDE_SET is not null
                                   or PDE.PDE_VERSION is not null)
                              and GCO_I_LIB_CHARACTERIZATION.IsRetestManagement(PDE.GCO_GOOD_ID) = 1
                              and POS.C_GAUGE_TYPE_POS not in('7', '8', '9', '10')
                              and POS.C_DOC_POS_ERROR is null   -- on ne contrôle pas si une erreur est déjà détectée
                         order by PDE.GCO_GOOD_ID
                                , PDE.DOC_POSITION_DETAIL_ID) loop
      declare
        lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
          := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => ltplPosition.GCO_GOOD_ID
                                                     , iPiece     => ltplPosition.PDE_PIECE
                                                     , iSet       => ltplPosition.PDE_SET
                                                     , iVersion   => ltplPosition.PDE_VERSION
                                                      );
      begin
        if lElementNumberId is not null then
          declare
            lRetestDate STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type
                                                              := FWK_I_LIB_ENTITY.getDateFieldFromPk('STM_ELEMENT_NUMBER', 'SEM_RETEST_DATE', lElementNumberId);
          begin
            if STM_LIB_MOVEMENT.IsRetestNeeded(iGoodID           => ltplPosition.GCO_GOOD_ID
                                             , iMovementKindId   => ltplPosition.STM_MOVEMENT_KIND_ID
                                             , iMovementDate     => ltplPosition.SMO_MOVEMENT_DATE
                                             , iRetestDate       => lRetestDate
                                              ) = 1 then
              lError  := 1;
              SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorReAnalyze);
            end if;
          end;
        end if;
      end;
    end loop;

    return lError;
  end pIsRetestNeeded;

  /**
  * Description
  *   Procedure centrale de tous les contrôles d'intégrité mvt stock liés à une position
  *     - Ruptures de stock
  *     - Conditions de stockage
  *     - Status qualité
  *     - Péremption
  *     - Ré-analyse
  */
  procedure PositionStockControl(iPositionId in DOC_POSITION.DOC_POSITION_ID%type, oError out number)
  is
  begin
    oError  := 0;
    -- remise des flags d'erreur à 0 avant contrôle
    ClearPositionError(iPositionId);

    -- teste d'abord la rupture standard
    if DOC_I_LIB_POSITION.isStockOutage(iPositionId) = 1 then
      oError  := 1;
    else
      for ltplPosition in (select POS.DOC_POSITION_ID
                                , DMT.DOC_DOCUMENT_ID
                                , PDE.GCO_GOOD_ID
                                , POS.STM_MOVEMENT_KIND_ID
                                , PDE.STM_LOCATION_ID
                                , PDE.PDE_PIECE
                                , PDE.PDE_SET
                                , PDE.PDE_VERSION
                                , PDE.PDE_CHRONOLOGICAL
                                , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
                                , GCO_I_LIB_CHARACTERIZATION.HasQualityStatusManagement(PDE.GCO_GOOD_ID) QSMGNT
                                , GCO_I_LIB_CHARACTERIZATION.IsRetestManagement(PDE.GCO_GOOD_ID) RETEST
                                , GCO_I_LIB_COMPL_DATA.IsStorageConditionCheck(PDE.GCO_GOOD_ID, null, PDE.STM_LOCATION_ID) STCOND
                                , GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(PDE.GCO_GOOD_ID) OUTDATE
                             from DOC_POSITION POS
                                , DOC_POSITION_DETAIL PDE
                                , DOC_DOCUMENT DMT
                            where POS.DOC_POSITION_ID = iPositionId
                              and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                              and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID) loop
        -- on effectue tous les contrôles relatifs aux mouvements de stock pouvant êtres effectués
        case
          when ltplPosition.QSMGNT = 1 then
            declare
              lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
                := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => ltplPosition.GCO_GOOD_ID
                                                           , iPiece     => ltplPosition.PDE_PIECE
                                                           , iSet       => ltplPosition.PDE_SET
                                                           , iVersion   => ltplPosition.PDE_VERSION
                                                            );
            begin
              if STM_LIB_MOVEMENT.VerifyQualityStatus(iGoodId            => ltplPosition.GCO_GOOD_ID
                                                    , iMovementKindId    => ltplPosition.STM_MOVEMENT_KIND_ID
                                                    , iElementNumberId   => lElementNumberId
                                                     ) is not null then
                oError  := 1;
                SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorQualityStatus);
              end if;
            end;
          when ltplPosition.STCOND = 1
          and STM_LIB_MOVEMENT.VerifyStorageConditions(iGoodID           => ltplPosition.GCO_GOOD_ID
                                                     , iLocationId       => ltplPosition.STM_LOCATION_ID
                                                     , iMovementKindId   => ltplPosition.STM_MOVEMENT_KIND_ID
                                                      ) is not null then
            oError  := 1;
            SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorStorageCondition);
          when ltplPosition.RETEST = 1 then
            declare
              lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
                := STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => ltplPosition.GCO_GOOD_ID
                                                           , iPiece     => ltplPosition.PDE_PIECE
                                                           , iSet       => ltplPosition.PDE_SET
                                                           , iVersion   => ltplPosition.PDE_VERSION
                                                            );
            begin
              if lElementNumberId is not null then
                declare
                  lRetestDate STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type
                                                              := FWK_I_LIB_ENTITY.getDateFieldFromPk('STM_ELEMENT_NUMBER', 'SEM_RETEST_DATE', lElementNumberId);
                begin
                  if STM_LIB_MOVEMENT.IsRetestNeeded(iGoodID           => ltplPosition.GCO_GOOD_ID
                                                   , iMovementKindId   => ltplPosition.STM_MOVEMENT_KIND_ID
                                                   , iMovementDate     => ltplPosition.SMO_MOVEMENT_DATE
                                                   , iRetestDate       => lRetestDate
                                                    ) = 1 then
                    oError  := 1;
                    SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorReAnalyze);
                  end if;
                end;
              end if;
            end;

            oError  := 1;
          when ltplPosition.OUTDATE = 1
          and STM_LIB_MOVEMENT.IsOutdatedMvt(iGoodID           => ltplPosition.GCO_GOOD_ID
                                           , iMovementKindId   => ltplPosition.STM_MOVEMENT_KIND_ID
                                           , iTimeLimitDate    => ltplPosition.PDE_CHRONOLOGICAL
                                           , iMovementDate     => ltplPosition.SMO_MOVEMENT_DATE
                                           , iDocumentID       => ltplPosition.DOC_DOCUMENT_ID
                                            ) = 1 then
            oError  := 1;
            SetPositionError(ltplPosition.DOC_POSITION_ID, DOC_I_LIB_CONSTANT.gcDocPosErrorOutdated);
          else
            null;
        end case;

        exit when oError = 1;
      end loop;
    end if;

    -- mise à jour des erreur des éventueles positions composants
    PostponeCptPositionError(iPositionId);
  end PositionStockControl;

  /**
  * Description
  *   Procedure centrale de tous les contrôles d'intégrité mvt stock liés aux positions d'un document
  *     - Ruptures de stock
  *     - Conditions de stockage
  *     - Status qualité
  *     - Péremption
  *     - Ré-analyse
  */
  procedure PositionsStockControl(iDocumentId in DOC_POSITION.DOC_DOCUMENT_ID%type, oError out number)
  is
  begin
    -- remise des flags d'erreur à 0 avant contrôle
    ClearPositionsError(iDocumentId);
    -- on effectue tous les contrôles relatifs aux mouvements de stock pouvant êtres effectués
    oError  := 0;
    oError  := sign(oError + DOC_DOCUMENT_FUNCTIONS.isStockOutage(iDocumentId) );
    oError  := sign(oError + pVerifyQualityStatus(iDocumentId) );
    oError  := sign(oError + pVerifyStorageConditions(iDocumentId) );
    oError  := sign(oError + pIsOutdatedMvt(iDocumentId) );
    oError  := sign(oError + pIsRetestNeeded(iDocumentId) );

    -- si au moins une erreur a été trouvée, report des erreurs des positions composant sur la position maître
    if oError = 1 then
      PostponeCptPositionsError(iDocumentId);
    end if;
  end PositionsStockControl;

  /**
  * Description
  *   Mise à jour du statut qualité des détails de position en fonction des détails de caractérisations.
  */
  procedure SyncPositionQualityStatus(iDocumentId in DOC_POSITION.DOC_DOCUMENT_ID%type)
  is
    ltPosDet          FWK_I_TYP_DEFINITION.t_crud_def;
    lnElementNumberID STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lnQualityStatusID GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type;
  begin
    -- Seul les positions qui n'ont pas encore de mouvement généré ayant au moins une caractérisation et dont le bien possède une gestion
    -- des détails de caracterisation sont mise à jour
    for ltplPosition in (select   PDE.DOC_POSITION_DETAIL_ID
                                , PDE.GCO_GOOD_ID
                                , POS.STM_MOVEMENT_KIND_ID
                                , PDE_PIECE
                                , PDE_SET
                                , PDE_VERSION
                             from DOC_POSITION_DETAIL PDE
                                , DOC_POSITION POS
                            where POS.DOC_DOCUMENT_ID = iDocumentId
                              and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                              and PDE.GCO_CHARACTERIZATION_ID is not null
                              and POS.STM_MOVEMENT_KIND_ID is not null
                              and GCO_I_LIB_CHARACTERIZATION.HasQualityStatusManagement(PDE.GCO_GOOD_ID) = 1
                              and POS.POS_GENERATE_MOVEMENT = 0
                         order by PDE.GCO_GOOD_ID
                                , PDE.DOC_POSITION_DETAIL_ID) loop
      lnElementNumberID  :=
        STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => ltplPosition.GCO_GOOD_ID
                                                , iPiece     => ltplPosition.PDE_PIECE
                                                , iSet       => ltplPosition.PDE_SET
                                                , iVersion   => ltplPosition.PDE_VERSION
                                                 );

      if lnElementNumberID is not null then
        select GCO_QUALITY_STATUS_ID
          into lnQualityStatusID
          from STM_ELEMENT_NUMBER
         where STM_ELEMENT_NUMBER_ID = lnElementNumberID;
      end if;

      if lnQualityStatusID is not null then
        -- Mise à jour des détails de position avec le statut qualité du détail de caractérisation
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPositionDetail, ltPosDet, false);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPosDet, 'DOC_POSITION_DETAIL_ID', ltplPosition.DOC_POSITION_DETAIL_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPosDet, 'GCO_QUALITY_STATUS_ID', lnQualityStatusID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltPosDet);
        FWK_I_MGT_ENTITY.release(ltPosDet);
      end if;
    end loop;
  end SyncPositionQualityStatus;
end DOC_PRC_POSITION;
