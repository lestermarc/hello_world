--------------------------------------------------------
--  DDL for Package Body FAL_LIB_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_CALCULATION" 
is
  cTypeRate integer := PCS.PC_CONFIG.GetConfig('FAL_TYPE_RATE');

  /**
  * function pGetTaskPrice
  * Description
  *   Retourne le montant d'une opération externe en fonction d'une quantité.
  * @created sma 14.05.2014
  * @lastUpdate age 04.09.2014
  * @private
  * @param iQty           : Quantité de l'opération
  * @param iQtyRef        : Quantité de référence
  * @param iAmount        : Montant
  * @param iDivisorAmount : Diviseur. Si 1, la Quantité de l'opération est divisée par la Quantité de référence, sinon elle est multipliée.
  */
  function pGetTaskPrice(iQty in DOC_POSITION.POS_BASIS_QUANTITY%type, iQtyRef in number, iAmount in number, iDivisorAmount in number)
    return number
  is
  begin
    if iDivisorAmount = 1 then
      return (iQty / iQtyRef) * iAmount;
    else
      return iQty * iQtyRef * iAmount;
    end if;
  end pGetTaskPrice;

  /**
  * procedure GetComplementaryPurchaseData
  * Description : Recherche des données complémentaires d'achat par défaut
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iGcoGoodId : Bien
  * @param   iGetWasteQtyFromNom : Recherche des qté déchets sur la nomenclature
  * @param   ioComplDataManufactureID : Donnée compl. de fabrication
  * @param   ioSchedulePlanID : Gamme opératoire
  * @param   ioNomenclatureID : Nomenclature
  * @param   ioDefaultDatas : Donnée complémentaire par défaut
  * @param   ioStandardLotQuantity : Qté lot standard
  * @param   ioRejectPourcent : %age de rebut
  * @param   ioFixedRejectQuantity : Qté fixe rebut
  * @param   ioTrashPourcent : %age déchet
  * @param   ioFixedTrashQuantity : qté fixe : déchet
  * @param   ioRejectReferenceQuantity : qté référence rebut
  * @param   ioTrashReferenceQuantity in out number
  * @param   ioFounded : Trouvée
  */
  procedure GetComplementaryPurchaseData(
    iGcoGoodId                in     number
  , ioComplDataPurchaseID     in out number
  , ioStandardLotQuantity     in out number
  , ioRejectPourcent          in out number
  , ioFixedRejectQuantity     in out number
  , ioRejectReferenceQuantity in out number
  )
  is
  begin
    for tplComplData in (select GCO_COMPL_DATA_PURCHASE_ID
                              , CPU_ECONOMICAL_QUANTITY
                              , CDA_CONVERSION_FACTOR
                              , CPU_PERCENT_TRASH
                              , CPU_FIXED_QUANTITY_TRASH
                              , CPU_QTY_REFERENCE_TRASH
                           from GCO_COMPL_DATA_PURCHASE
                          where GCO_GOOD_ID = iGcoGoodId
                            and CPU_DEFAULT_SUPPLIER = 1) loop
      ioComplDataPurchaseID      := tplComplData.GCO_COMPL_DATA_PURCHASE_ID;
      ioStandardLotQuantity      := nvl(tplComplData.CPU_ECONOMICAL_QUANTITY * tplComplData.CDA_CONVERSION_FACTOR, 0);

      if ioStandardLotQuantity = 0 then
        ioStandardLotQuantity  := 1;
      end if;

      ioRejectPourcent           := tplComplData.CPU_PERCENT_TRASH;
      ioFixedRejectQuantity      := tplComplData.CPU_FIXED_QUANTITY_TRASH;
      ioRejectReferenceQuantity  := tplComplData.CPU_QTY_REFERENCE_TRASH;
      exit;
    end loop;
  end GetComplementaryPurchaseData;

  /**
  * procedure GetComplementaryManufData
  * Description : Recherche des données complémentaires de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iGcoGoodId : Bien
  * @param   iDicFabConditionId : Condition de fabrication / Sous-traitance
  * @param   iDefaultData : Recherche des données complémentaires par défaut
  * @param   iIncludeWasteQtyOfNom : Recherche des quantités déchets de la nomenclature
  * @param   iPpsNomenclatureId : Id de la nomenclature
  * @param   ioComplDataManufactureID : Donnée compl. de fabrication
  * @param   ioSchedulePlanID : Gamme opératoire
  * @param   ioNomenclatureID : Nomenclature
  * @param   ioDefaultDatas : Donnée complémentaire par défaut
  * @param   ioStandardLotQuantity : Qté lot standard
  * @param   ioRejectPourcent : %age de rebut
  * @param   ioFixedRejectQuantity : Qté fixe rebut
  * @param   ioTrashPourcent : %age déchet
  * @param   ioFixedTrashQuantity : qté fixe : déchet
  * @param   ioRejectReferenceQuantity : qté référence rebut
  * @param   ioTrashReferenceQuantity in out number
  * @param   ioFounded : Trouvée
  */
  procedure GetComplementaryManufData(
    iGcoGoodId                in     number
  , iDicFabConditionId        in     varchar2 default null
  , iDefaultData              in     integer default 0
  , iIncludeWasteQtyOfNom     in     integer default 0
  , iPpsNomenclatureId        in     number default null
  , ioComplDataManufactureID  in out number
  , ioSchedulePlanID          in out number
  , ioNomenclatureID          in out number
  , ioDefaultDatas            in out integer
  , ioStandardLotQuantity     in out number
  , ioRejectPourcent          in out number
  , ioFixedRejectQuantity     in out number
  , ioRejectReferenceQuantity in out number
  , ioTrashPourcent           in out number
  , ioFixedTrashQuantity      in out number
  , ioTrashReferenceQuantity  in out number
  , ioFounded                 in out integer
  )
  is
  begin
    ioFounded  := 0;

    for tplComplData in (select   GCO_COMPL_DATA_MANUFACTURE_ID
                                , FAL_SCHEDULE_PLAN_ID
                                , PPS_NOMENCLATURE_ID
                                , CMA_LOT_QUANTITY
                                , CMA_PERCENT_TRASH
                                , CMA_FIXED_QUANTITY_TRASH
                                , CMA_PERCENT_WASTE
                                , CMA_FIXED_QUANTITY_WASTE
                                , CMA_QTY_REFERENCE_LOSS
                                , CMA_DEFAULT
                                , case(PPS_NOMENCLATURE_ID - iPpsNomenclatureId)
                                    when 0 then(2 + CMA_DEFAULT)
                                    else CMA_DEFAULT
                                  end ORDER_FIELD
                             from GCO_COMPL_DATA_MANUFACTURE
                            where (PPS_NOMENCLATURE_ID = iPpsNomenclatureId)
                               or (    GCO_GOOD_ID = iGcoGoodId
                                   and (    (    iDefaultData = 0
                                             and (    (    DIC_FAB_CONDITION_ID is null
                                                       and iDicFabConditionId is null)
                                                  or DIC_FAB_CONDITION_ID = iDicFabConditionId)
                                            )
                                        or (    iDefaultData = 1
                                            and CMA_DEFAULT = 1)
                                       )
                                  )
                         order by ORDER_FIELD desc
                                , A_DATECRE desc) loop
      ioComplDataManufactureID   := tplComplData.GCO_COMPL_DATA_MANUFACTURE_ID;
      ioSchedulePlanID           := tplComplData.FAL_SCHEDULE_PLAN_ID;
      ioNomenclatureID           := nvl(iPpsNomenclatureId, tplComplData.PPS_NOMENCLATURE_ID);
      ioDefaultDatas             := nvl(tplComplData.CMA_DEFAULT, 0);
      ioStandardLotQuantity      := nvl(tplComplData.CMA_LOT_QUANTITY, 0);

      if ioStandardLotQuantity = 0 then
        ioStandardLotQuantity  := 1;
      end if;

      ioRejectPourcent           := tplComplData.CMA_PERCENT_TRASH;
      ioFixedRejectQuantity      := tplComplData.CMA_FIXED_QUANTITY_TRASH;
      ioTrashPourcent            := tplComplData.CMA_PERCENT_WASTE;
      ioFixedTrashQuantity       := tplComplData.CMA_FIXED_QUANTITY_WASTE;
      ioRejectReferenceQuantity  := tplComplData.CMA_QTY_REFERENCE_LOSS;

      if iIncludeWasteQtyOfNom = 1 then
        FAL_PRECALC_TOOLS.GetWasteQtiesFromNomenclature(tplComplData.PPS_NOMENCLATURE_ID
                                                      , null
                                                      , iGcoGoodId
                                                      , ioTrashPourcent
                                                      , ioTrashReferenceQuantity
                                                      , ioFixedTrashQuantity
                                                       );
      end if;

      ioFounded                  := 1;
      exit;
    end loop;
  end GetComplementaryManufData;

  /**
  * procedure GetComplementarySubcPData
  * Description : Recherche des données complémentaires de sous-traitance
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iGcoGoodId : Bien
  * @param   iDicFabConditionId : Condition de fabrication / Sous-traitance
  * @param   iDateReference : Date de validité
  * @param   iIncludeWasteQtyOfNom : Recherche des quantités déchets de la nomenclature
  * @param   ioComplDataSubcontractID : Donnée compl. de sous-traitance
  * @param   ioSchedulePlanID : Gamme opératoire
  * @param   ioNomenclatureID : Nomenclature
  * @param   ioDefaultDatas : Donnée complémentaire par défaut
  * @param   ioStandardLotQuantity : Qté lot standard
  * @param   ioRejectPourcent : %age de rebut
  * @param   ioFixedRejectQuantity : Qté fixe rebut
  * @param   ioTrashPourcent : %age déchet
  * @param   ioFixedTrashQuantity : qté fixe : déchet
  * @param   ioRejectReferenceQuantity : qté référence rebut
  * @param   ioTrashReferenceQuantity in out number
  * @param   ioFounded : Trouvée
  * @param   ioGcoGcoGoodId : Service lié
  * @param   ioScsAmount : montant
  * @param   ioScsQtyRefAmount : Qté ref montant
  * @param   ioScsDivisorAmount : Diviseur
  * @param   ioScsQtyRefWork : Qté ref travail
  * @param   ioPacSupplierPartner : Fournisseur
  */
  procedure GetComplementarySubcPData(
    iGcoGoodId                in     number
  , iDicFabConditionId        in     varchar2 default null
  , iDateReference            in     date default null
  , iIncludeWasteQtyOfNom     in     integer default 0
  , ioComplDataSubcontractID  in out number
  , ioSchedulePlanID          in out number
  , ioNomenclatureID          in out number
  , ioDefaultDatas            in out integer
  , ioStandardLotQuantity     in out number
  , ioRejectPourcent          in out number
  , ioFixedRejectQuantity     in out number
  , ioRejectReferenceQuantity in out number
  , ioTrashPourcent           in out number
  , ioFixedTrashQuantity      in out number
  , ioTrashReferenceQuantity  in out number
  , ioFounded                 in out integer
  , ioGcoGcoGoodId            in out number
  , ioScsAmount               in out number
  , ioScsQtyRefAmount         in out integer
  , ioScsDivisorAmount        in out integer
  , ioScsQtyRefWork           in out number
  , ioPacSupplierPartner      in out number
  )
  is
  begin
    ioFounded  := 0;

    for tplComplData in (select GCO_COMPL_DATA_SUBCONTRACT_ID
                              , PPS_NOMENCLATURE_ID
                              , CSU_DEFAULT_SUBCONTRACTER
                              , CSU_LOT_QUANTITY
                              , CSU_PERCENT_TRASH
                              , CSU_FIXED_QUANTITY_TRASH
                              , CSU_QTY_REFERENCE_TRASH
                              , GCO_GCO_GOOD_ID
                              , CSU_AMOUNT
                              , nvl(CSU_LOT_QUANTITY, 1) SCS_QTY_REF_WORK
                              , PAC_SUPPLIER_PARTNER_ID
                           from GCO_COMPL_DATA_SUBCONTRACT
                          where GCO_GOOD_ID = iGcoGoodId
                            and GCO_COMPL_DATA_SUBCONTRACT_ID =
                                                        FAL_I_LIB_MRP_CALCULATION.GetSubContractPComplData(iGcoGoodId, iDicFabConditionID, null, iDateReference) ) loop
      ioComplDataSubContractID   := tplComplData.GCO_COMPL_DATA_SUBCONTRACT_ID;
      ioSchedulePlanID           := FAL_LIB_SUBCONTRACTP.GetSchedulePlanID;
      ioNomenclatureID           := tplComplData.PPS_NOMENCLATURE_ID;
      ioDefaultDatas             := nvl(tplComplData.CSU_DEFAULT_SUBCONTRACTER, 0);
      ioStandardLotQuantity      := nvl(tplComplData.CSU_LOT_QUANTITY, 0);

      if ioStandardLotQuantity = 0 then
        ioStandardLotQuantity  := 1;
      end if;

      ioRejectPourcent           := tplComplData.CSU_PERCENT_TRASH;
      ioFixedRejectQuantity      := tplComplData.CSU_FIXED_QUANTITY_TRASH;
      ioRejectReferenceQuantity  := tplComplData.CSU_QTY_REFERENCE_TRASH;
      ioFounded                  := 1;

      if iIncludeWasteQtyOfNom = 1 then
        FAL_PRECALC_TOOLS.GetWasteQtiesFromNomenclature(tplComplData.PPS_NOMENCLATURE_ID
                                                      , null
                                                      , iGcoGoodId
                                                      , ioTrashPourcent
                                                      , ioTrashReferenceQuantity
                                                      , ioFixedTrashQuantity
                                                       );
      end if;

      ioGcoGcoGoodId             := tplComplData.GCO_GCO_GOOD_ID;
      ioScsAmount                := tplComplData.CSU_AMOUNT;
      ioScsQtyRefAmount          := 1;
      ioScsDivisorAmount         := 0;
      ioScsQtyRefWork            := tplComplData.SCS_QTY_REF_WORK;
      ioPacSupplierPartner       := tplComplData.PAC_SUPPLIER_PARTNER_ID;
      exit;
    end loop;
  end GetComplementarySubcPData;

  /**
  * function GetProductDefaultNomenclature
  * Description : Recherche de la nomenclature par défaut du produit
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  */
  function GetProductDefaultNomenclature(iGoodId number)
    return number
  is
    lnPpsNomenclatureId number;
  begin
    select PPS_NOMENCLATURE_ID
      into lnPpsNomenclatureId
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = iGoodId
       and PPS_NOMENCLATURE.C_TYPE_NOM in('2', '3', '4')
       and NOM_DEFAULT = 1;

    return lnPpsNomenclatureId;
  exception
    when others then
      return null;
  end GetProductDefaultNomenclature;

  /**
  * procedure GetPreCalcProductComplementaryDatas
  * Description : Recherche des données complémentaires appropriées pour un produit
  *               donné pré-calculé, quelque soit son niveau dans la nomenclature
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iFatherGoodId : Produit père (Composé)
  * @param   iPpsNomenclatureId : nomenclature
  * @param   iCSupplyMode : Mode d'approvisionnement
  * @param   iDicFabConditionId : Condition de fabrication / Sous-traitance
  * @param   iDateReference : Date référence
  * @param   iFirstLevel : Produit calculé / ou composant
  * @param   iCKindCom : Genre de lien de nomenclature, pseudo, dérivé, composant, fournit
  * @param   ioComplDataManufactureID : Donnée compl. de fabrication
  * @param   ioComplDataPurchaseID : Donnée compl. d'achat
  * @param   ioComplDataSubcontractID : Donnée compl de sous-traitance
  * @param   ioSchedulePlanID : Gamme opératoire
  * @param   ioNomenclatureID : Nomenclature
  * @param   ioDefaultDatas : Donnée complémentaire par défaut
  * @param   ioStandardLotQuantity : Qté lot standard
  * @param   ioRejectPourcent : %age de rebut
  * @param   ioFixedRejectQuantity : Qté fixe rebut
  * @param   ioRejectReferenceQuantity : qté référence rebut
  * @param   ioTrashPourcent : %age déchet
  * @param   ioFixedTrashQuantity : qté fixe : déchet
  * @param   ioTrashReferenceQuantity in out number
  * @param   ioGcoGcoGoodId : Service lié
  * @param   ioScsAmount : montant
  * @param   ioScsQtyRefAmount : Qté ref montant
  * @param   ioScsDivisorAmount : Diviseur
  * @param   ioScsQtyRefWork : Qté ref travail
  * @param   ioPacSupplierPartner : Fournisseur
  */
  procedure GetProductComplementaryDatas(
    iGcoGoodId                in     number
  , iFatherGoodId             in     number default null
  , iPpsNomenclatureId        in     number default null
  , iCSupplyMode              in     varchar2
  , iDicFabConditionId        in     varchar2 default null
  , iDateReference            in     date default null
  , iFirstLevel               in     integer default 1
  , iCKindCom                 in     integer default kcComposant
  , ioComplDataManufactureID  in out number
  , ioComplDataPurchaseID     in out number
  , ioComplDataSubcontractID  in out number
  , ioSchedulePlanID          in out number
  , ioNomenclatureID          in out number
  , ioDefaultDatas            in out integer
  , ioStandardLotQuantity     in out number
  , ioRejectPourcent          in out number
  , ioFixedRejectQuantity     in out number
  , ioRejectReferenceQuantity in out number
  , ioTrashPourcent           in out number
  , ioFixedTrashQuantity      in out number
  , ioTrashReferenceQuantity  in out number
  , ioGcoGcoGoodId            in out number
  , ioScsAmount               in out number
  , ioScsQtyRefAmount         in out integer
  , ioScsDivisorAmount        in out integer
  , ioScsQtyRefWork           in out number
  , ioPacSupplierPartner      in out number
  )
  is
    liFounded              integer;
    liIncludeWasteQtyOfNom integer;
  begin
    -- Initialisation valeurs par défaut
    ioComplDataManufactureID   := null;
    ioComplDataPurchaseID      := null;
    ioComplDataSubcontractID   := null;
    ioSchedulePlanID           := null;
    ioNomenclatureID           := null;
    ioDefaultDatas             := 0;
    ioStandardLotQuantity      := 1;
    ioRejectPourcent           := 0;
    ioFixedRejectQuantity      := 0;
    ioRejectReferenceQuantity  := 0;
    ioTrashPourcent            := 0;
    ioFixedTrashQuantity       := 0;
    ioTrashReferenceQuantity   := 0;
    liFounded                  := 0;
    ioGcoGcoGoodId             := null;
    ioScsAmount                := 0;
    ioScsQtyRefAmount          := 1;
    ioScsDivisorAmount         := 0;
    ioScsQtyRefWork            := 1;
    ioPacSupplierPartner       := null;

    -- Recherche pour le produit calculé composé
    if iFirstLevel = 1 then
      -- Si produit acheté, fabriqué ou assemblé sur tâche --> recherche des données complémentaires de fabrication
      if    iCSupplyMode = csmPurchasedPdt
         or iCSupplyMode = csmManufacturedPdt
         or iCSupplyMode = csmPRPPdt then
        GetComplementaryManufData(iGcoGoodId                  => iGcoGoodId
                                , iDicFabConditionId          => iDicFabConditionId
                                , iDefaultData                => 0
                                , iIncludeWasteQtyOfNom       => 0
                                , iPpsNomenclatureId          => null
                                , ioComplDataManufactureID    => ioComplDataManufactureID
                                , ioSchedulePlanID            => ioSchedulePlanID
                                , ioNomenclatureID            => ioNomenclatureID
                                , ioDefaultDatas              => ioDefaultDatas
                                , ioStandardLotQuantity       => ioStandardLotQuantity
                                , ioRejectPourcent            => ioRejectPourcent
                                , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                , ioTrashPourcent             => ioTrashPourcent
                                , ioFixedTrashQuantity        => ioFixedTrashQuantity
                                , ioTrashReferenceQuantity    => ioTrashReferenceQuantity
                                , ioFounded                   => liFounded
                                 );
      -- Si produit sous-traité --> recherche des données complémentaires de sous-traitance
      elsif iCSupplyMode = csmSubcontractPurchasePdt then
        GetComplementarySubcPData(iGcoGoodId                  => iGcoGoodId
                                , iDicFabConditionId          => iDicFabConditionId
                                , iDateReference              => iDateReference
                                , ioComplDataSubcontractID    => ioComplDataSubcontractID
                                , ioSchedulePlanID            => ioSchedulePlanID
                                , ioNomenclatureID            => ioNomenclatureID
                                , ioDefaultDatas              => ioDefaultDatas
                                , ioStandardLotQuantity       => ioStandardLotQuantity
                                , ioRejectPourcent            => ioRejectPourcent
                                , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                , ioTrashPourcent             => ioTrashPourcent
                                , ioFixedTrashQuantity        => ioFixedTrashQuantity
                                , ioTrashReferenceQuantity    => ioTrashReferenceQuantity
                                , ioFounded                   => liFounded
                                , ioGcoGcoGoodId              => ioGcoGcoGoodId
                                , ioScsAmount                 => ioScsAmount
                                , ioScsQtyRefAmount           => ioScsQtyRefAmount
                                , ioScsDivisorAmount          => ioScsDivisorAmount
                                , ioScsQtyRefWork             => ioScsQtyRefWork
                                , ioPacSupplierPartner        => ioPacSupplierPartner
                                 );
      end if;

      -- Si non trouvée -> recherche des données complémentaires d'achat et de la nomenclature par défaut du produit
      if liFounded = 0 then
        GetComplementaryPurchaseData(iGcoGoodId                  => iGcoGoodId
                                   , ioComplDataPurchaseID       => ioComplDataPurchaseID
                                   , ioStandardLotQuantity       => ioStandardLotQuantity
                                   , ioRejectPourcent            => ioRejectPourcent
                                   , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                   , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                    );
        ioNomenclatureId  := GetProductDefaultNomenclature(iGcoGoodId);
      end if;
    -- Recherche pour les composants de produits calculés
    else
      -- Pseudo
      if icKindCom = kcPseudo then
        if nvl(iPpsNomenclatureId, 0) = 0 then
          liIncludeWasteQtyOfNom  := 1;
        else
          liIncludeWasteQtyOfNom  := 0;
        end if;

        -- Produit non sous-traité
        if iCSupplyMode <> csmSubcontractPurchasePdt then
          GetComplementaryManufData(iGcoGoodId                  => iGcoGoodId
                                  , iDicFabConditionId          => null
                                  , iDefaultData                => 1
                                  , iIncludeWasteQtyOfNom       => liIncludeWasteQtyOfNom
                                  , iPpsNomenclatureId          => iPpsNomenclatureId
                                  , ioComplDataManufactureID    => ioComplDataManufactureID
                                  , ioSchedulePlanID            => ioSchedulePlanID
                                  , ioNomenclatureID            => ioNomenclatureID
                                  , ioDefaultDatas              => ioDefaultDatas
                                  , ioStandardLotQuantity       => ioStandardLotQuantity
                                  , ioRejectPourcent            => ioRejectPourcent
                                  , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                  , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                  , ioTrashPourcent             => ioTrashPourcent
                                  , ioFixedTrashQuantity        => ioFixedTrashQuantity
                                  , ioTrashReferenceQuantity    => ioTrashReferenceQuantity
                                  , ioFounded                   => liFounded
                                   );
        -- Produit sous-traité
        else
          GetComplementarySubcPData(iGcoGoodId                  => iGcoGoodId
                                  , iDicFabConditionId          => iDicFabConditionId
                                  , iDateReference              => iDateReference
                                  , iIncludeWasteQtyOfNom       => liIncludeWasteQtyOfNom
                                  , ioComplDataSubcontractID    => ioComplDataSubcontractID
                                  , ioSchedulePlanID            => ioSchedulePlanID
                                  , ioNomenclatureID            => ioNomenclatureID
                                  , ioDefaultDatas              => ioDefaultDatas
                                  , ioStandardLotQuantity       => ioStandardLotQuantity
                                  , ioRejectPourcent            => ioRejectPourcent
                                  , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                  , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                  , ioTrashPourcent             => ioTrashPourcent
                                  , ioFixedTrashQuantity        => ioFixedTrashQuantity
                                  , ioTrashReferenceQuantity    => ioTrashReferenceQuantity
                                  , ioFounded                   => liFounded
                                  , ioGcoGcoGoodId              => ioGcoGcoGoodId
                                  , ioScsAmount                 => ioScsAmount
                                  , ioScsQtyRefAmount           => ioScsQtyRefAmount
                                  , ioScsDivisorAmount          => ioScsDivisorAmount
                                  , ioScsQtyRefWork             => ioScsQtyRefWork
                                  , ioPacSupplierPartner        => ioPacSupplierPartner
                                   );
        end if;

        -- Si non trouvée -> recherche de la nomenclature par défaut du produit
        if     liFounded = 0
           and nvl(iPpsNomenclatureId, 0) = 0 then
          ioNomenclatureId  := GetProductDefaultNomenclature(iGcoGoodId);
        end if;
      -- Composant et fournit par le sous-traitant
      elsif    icKindCom = kcComposant
            or icKindCom = kcSuppliedBySubcontractor then
        -- Si produit acheté ou fournit par le sous-traitant, recherche infos de déchets
        -- de consommation sur la donnée complémentaire du père
        if    icSupplyMode = csmPurchasedPdt
           or icKindCom = kcSuppliedBySubcontractor then
          GetComplementaryManufData(iGcoGoodId                  => iFatherGoodId
                                  , iDicFabConditionId          => null
                                  , iDefaultData                => 1
                                  , iIncludeWasteQtyOfNom       => 1
                                  , iPpsNomenclatureId          => null
                                  , ioComplDataManufactureID    => ioComplDataManufactureID
                                  , ioSchedulePlanID            => ioSchedulePlanID
                                  , ioNomenclatureID            => ioNomenclatureID
                                  , ioDefaultDatas              => ioDefaultDatas
                                  , ioStandardLotQuantity       => ioStandardLotQuantity
                                  , ioRejectPourcent            => ioRejectPourcent
                                  , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                  , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                  , ioTrashPourcent             => ioTrashPourcent
                                  , ioFixedTrashQuantity        => ioFixedTrashQuantity
                                  , ioTrashReferenceQuantity    => ioTrashReferenceQuantity
                                  , ioFounded                   => liFounded
                                   );
          ioRejectReferenceQuantity  := 1;
          ioFixedRejectQuantity      := 0;
          ioRejectPourcent           := 0;
        -- Composant non acheté et non fournit par le sous traitant
        else
          if nvl(iPpsNomenclatureId, 0) = 0 then
            liIncludeWasteQtyOfNom  := 1;
          else
            liIncludeWasteQtyOfNom  := 0;
          end if;

          -- produit non-sous traité
          if iCSupplyMode <> csmSubcontractPurchasePdt then
            GetComplementaryManufData(iGcoGoodId                  => iGcoGoodId
                                    , iDicFabConditionId          => null
                                    , iDefaultData                => 1
                                    , iIncludeWasteQtyOfNom       => liIncludeWasteQtyOfNom
                                    , iPpsNomenclatureId          => iPpsNomenclatureId
                                    , ioComplDataManufactureID    => ioComplDataManufactureID
                                    , ioSchedulePlanID            => ioSchedulePlanID
                                    , ioNomenclatureID            => ioNomenclatureID
                                    , ioDefaultDatas              => ioDefaultDatas
                                    , ioStandardLotQuantity       => ioStandardLotQuantity
                                    , ioRejectPourcent            => ioRejectPourcent
                                    , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                    , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                    , ioTrashPourcent             => ioTrashPourcent
                                    , ioFixedTrashQuantity        => ioFixedTrashQuantity
                                    , ioTrashReferenceQuantity    => ioTrashReferenceQuantity
                                    , ioFounded                   => liFounded
                                     );
          -- Produit sous-traité
          else
            GetComplementarySubcPData(iGcoGoodId                  => iGcoGoodId
                                    , iDicFabConditionId          => iDicFabConditionId
                                    , iDateReference              => iDateReference
                                    , iIncludeWasteQtyOfNom       => liIncludeWasteQtyOfNom
                                    , ioComplDataSubcontractID    => ioComplDataSubcontractID
                                    , ioSchedulePlanID            => ioSchedulePlanID
                                    , ioNomenclatureID            => ioNomenclatureID
                                    , ioDefaultDatas              => ioDefaultDatas
                                    , ioStandardLotQuantity       => ioStandardLotQuantity
                                    , ioRejectPourcent            => ioRejectPourcent
                                    , ioFixedRejectQuantity       => ioFixedRejectQuantity
                                    , ioRejectReferenceQuantity   => ioRejectReferenceQuantity
                                    , ioTrashPourcent             => ioTrashPourcent
                                    , ioFixedTrashQuantity        => ioFixedTrashQuantity
                                    , ioTrashReferenceQuantity    => ioTrashReferenceQuantity
                                    , ioFounded                   => liFounded
                                    , ioGcoGcoGoodId              => ioGcoGcoGoodId
                                    , ioScsAmount                 => ioScsAmount
                                    , ioScsQtyRefAmount           => ioScsQtyRefAmount
                                    , ioScsDivisorAmount          => ioScsDivisorAmount
                                    , ioScsQtyRefWork             => ioScsQtyRefWork
                                    , ioPacSupplierPartner        => ioPacSupplierPartner
                                     );
          end if;

          -- Si non trouvée -> recherche de la nomenclature par défaut du produit
          if     liFounded = 0
             and nvl(iPpsNomenclatureId, 0) = 0 then
            ioNomenclatureId  := GetProductDefaultNomenclature(iGcoGoodId);
          end if;
        end if;
      end if;
    end if;
  end GetProductComplementaryDatas;

  /**
  * Description :
  *   Recherche le prix d'une opération externe (sous-traitance)
  */
  function getPriceOpExt(
    iGoodId             in number
  , iThirdId            in number
  , iStepNumber         in FAL_LIST_STEP_LINK.SCS_STEP_NUMBER%type
  , iSchedulePlanId     in FAL_LIST_STEP_LINK.FAL_SCHEDULE_PLAN_ID%type
  , iQuantity           in number
  , iDateRef            in date
  , iInclDiscountCharge in number default 0
  )
    return number
  is
    lnUnitPrice             number;
    lnDiscountCharge        number                                         := 0;
    lnSubcontractCharge     number                                         := 0;
    lbFound                 boolean                                        := false;
    lvConfig                PCS.PC_CBASE.CBACVALUE%type                    := PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_INIT_PRICE');
    lnCurrencyId            PCS.PC_CURR.PC_CURR_ID%type                    := ACS_FUNCTION.GetLocalCurrencyId;
    lnGaugeId               DOC_GAUGE.DOC_GAUGE_ID%type;
    lnTariffId              PTC_TARIFF.PTC_TARIFF_ID%type;
    lnQtyRef                FAL_LIST_STEP_LINK.SCS_QTY_REF_AMOUNT%type;
    lnScsAmount             FAL_LIST_STEP_LINK.SCS_AMOUNT%type;
    lnDivisorAmount         FAL_LIST_STEP_LINK.SCS_DIVISOR_AMOUNT%type;
    lvDicTariff             PTC_TARIFF.DIC_TARIFF_ID%type;
    lnThirdId               PAC_THIRD.PAC_THIRD_ID%type;
    lnThirdTariffID         PAC_THIRD.PAC_THIRD_ID%type;
    lnFalScheduleStepId     FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type;
    lnDummyThirdTariffID    PAC_THIRD.PAC_THIRD_ID%type;
    lnDummyThirdAciID       PAC_THIRD.PAC_THIRD_ID%type;
    lnDummyThirdDeliveryID  PAC_THIRD.PAC_THIRD_ID%type;
    lvDummyRoundType        PTC_TARIFF.C_ROUND_TYPE%type;
    lnDummyRoundAmount      PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    lnDummyPosNetTariff     PTC_TARIFF.TRF_NET_TARIFF%type                 := 0;
    lnDummyPosSpecialTariff PTC_TARIFF.TRF_SPECIAL_TARIFF%type             := 0;
    lnDummyPosTariffUnit    PTC_TARIFF.TRF_UNIT%type                       := 0;
    lnAmountEUR             number;
    lnAmountConvert         number;
  begin
    -- Recherche du gabarit
    lnGaugeId             := FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('FAL_PRECALC_DEFAULT_GAUGE') );

    -- Récupération de l'id du partenaire
    if iThirdId is not null then
      lnThirdId  := iThirdId;
    else
      begin
        select PAC_SUPPLIER_PARTNER_ID
          into lnThirdId
          from GCO_COMPL_DATA_PURCHASE
         where CPU_DEFAULT_SUPPLIER = 1
           and GCO_GOOD_ID = iGoodId;
      exception
        when no_data_found then
          lnThirdId  := 0;
      end;
    end if;

    -- Recherche de la monnaie du partenaire
    lnCurrencyId          := DOC_DOCUMENT_FUNCTIONS.GetAdminDomainCurrencyId('1', lnThirdId);
    lnDummyThirdTariffID  := lnThirdId;
    -- Recherche les partenaires par défaut d'un tiers
    DOC_DOCUMENT_FUNCTIONS.GetThirdPartners(aThirdID           => lnThirdId
                                          , aGaugeID           => lnGaugeId
                                          , aAdminDomain       => '1'
                                          , aThirdAciID        => lnDummyThirdAciID
                                          , aThirdDeliveryID   => lnDummyThirdDeliveryID
                                          , aThirdTariffID     => lnThirdTariffID
                                           );

    -- Récupération des informations de l'opérations
    select SCS_QTY_REF_AMOUNT
         , nvl(SCS_AMOUNT, 0)
         , SCS_DIVISOR_AMOUNT
         , FAL_SCHEDULE_STEP_ID
      into lnQtyRef
         , lnScsAmount
         , lnDivisorAmount
         , lnFalScheduleStepId
      from FAL_LIST_STEP_LINK
     where FAL_SCHEDULE_PLAN_ID = iSchedulePlanId
       and SCS_STEP_NUMBER = iStepNumber;

    -- Cascade de recherche du prix uitaire
    if     lvConfig in('0', '1')
       and (iStepNumber is not null) then
      -- Recherche du montant de l'opération. Si la Qté de référence (SCS_QTY_REF_AMOUNT) = 0, la valeur unitaires = 0.
      -- La cascade ne doit pas continuer car le montant est présent dans la taxe.
      lnUnitPrice  := pGetTaskPrice(iQuantity, lnQtyRef, lnScsAmount, lnDivisorAmount) / FAL_TOOLS.nvlA(iQuantity, 1);
      lbFound      :=    lnUnitPrice > 0
                      or (    lnQtyRef = 0
                          and lnScsAmount <> 0);
    end if;

    if     lvConfig in('0', '2')
       and not lbFound then
      -- Recherche du tarif achat
      PTC_FIND_TARIFF.GetTariff(iGoodId
                              , lnDummyThirdTariffID
                              , null
                              , lnCurrencyId
                              , lvDicTariff
                              , iQuantity
                              , iDateRef
                              , 'A_PAYER'
                              , 'UNIQUE'
                              , lnTariffId
                              , lnCurrencyId
                              , lnDummyPosNetTariff
                              , lnDummyPosSpecialTariff
                               );

      if lnTariffId is not null then
        -- Prix unitaire en unité de stockage.
        lnUnitPrice  :=
          PTC_FIND_TARIFF.GetTariffPrice(lnTariffId, iQuantity, lvDummyRoundType, lnDummyRoundAmount, lnDummyPosTariffUnit) /
          PTC_FIND_TARIFF.GetPurchaseConvertFactor(iGoodId, lnThirdTariffID);
        lbFound      := true;

        if lnCurrencyId <> ACS_FUNCTION.GetLocalCurrencyId then
          ACS_FUNCTION.ConvertAmount(aAmount          => lnUnitPrice
                                   , aFromFinCurrId   => lnCurrencyId
                                   , aToFinCurrId     => ACS_FUNCTION.GetLocalCurrencyId
                                   , aDate            => iDateRef
                                   , aExchangeRate    => 0
                                   , aBasePrice       => 0
                                   , aRound           => 0
                                   , aAmountEUR       => lnAmountEUR
                                   , aAmountConvert   => lnAmountConvert
                                   , aRateType        => cTypeRate
                                    );
          lnUnitPrice  := lnAmountConvert;
        end if;

        -- Taxes et remises du document à ajouter au tarif d'achat uniquement si iInclDiscountCharge = 1
        if iInclDiscountCharge = 1 then
          lnDiscountCharge  :=
            PTC_FIND_TARIFF.GetFullPrice(aGoodId              => iGoodId
                                       , aQuantity            => iQuantity
                                       , aThirdId             => lnThirdTariffID
                                       , aRecordId            => null
                                       , aGaugeId             => lnGaugeId
                                       , aCurrencyId          => lnCurrencyId
                                       , aTariffType          => null
                                       , aTarifficationMode   => null
                                       , aDicTariffId         => lvDicTariff
                                       , aDateRef             => iDateRef
                                       , aChargeType          => '2'
                                       , aPositionId          => null
                                       , aDocumentId          => null
                                       , aBlnCharge           => 1
                                       , aBlnDiscount         => 1
                                       , aGivenPrice          => lnUnitPrice
                                        ) -
            lnUnitPrice * iQuantity;
        end if;
      end if;
    end if;

    if    (lvConfig = '3')
       or not lbFound then
      -- Recherche du prix de revient fixe
      lnUnitPrice  := GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(iGoodId, lnThirdTariffID, '3', iDateRef);
    end if;

    -- Le montant de l'opération est ajouté comme taxe si :
    -- - config DOC_SUBCONTRACT_INIT_PRICE = 2 et config DOC_SUBCONTRACT_OP_CHARGE not null
    -- - config DOC_SUBCONTRACT_INIT_PRICE = 0 ou 1 et Qté de référence (SCS_QTY_REF_AMOUNT) = 0.
    if     PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_OP_CHARGE') is not null
       and (    (lvConfig = '2')
            or (    lvConfig in('0', '1')
                and lnQtyRef = 0) ) then
      if lnQtyRef = 0 then
        lnSubcontractCharge  := lnScsAmount;
      else
        lnSubcontractCharge  := pGetTaskPrice(iQuantity, lnQtyRef, lnScsAmount, lnDivisorAmount);
      end if;
    end if;

    return lnUnitPrice * iQuantity + lnDiscountCharge + lnSubcontractCharge;
  end getPriceOpExt;

  /**
  * fonction getSavedRubricSeqForWIPTotal
  * Description
  *    formatage de la liste des séquences sauvegardées pour total (Structures de calcul)
  */
  function getSavedRubricSeqForWIPTotal(iFalAdvCalRateStructId in FAL_ADV_CALC_RATE_STRUCT.FAL_ADV_CALC_RATE_STRUCT_ID%type)
    return varchar2
  as
    lResult varchar2(2000) := '';
  begin
    for ltplSeq in (select   to_char(ARS.ARS_SEQUENCE) ARS_SEQUENCE
                        from FAL_ADV_CALC_TOTAL_RATE ATR
                           , FAL_ADV_CALC_RATE_STRUCT ARS
                       where ATR.FAL_ADV_CALC_RATE_STRUCT_ID = iFalAdvCalRateStructId
                         and ATR.FAL_ADV_CALC_RATE_STRUCT1_ID = ARS.FAL_ADV_CALC_RATE_STRUCT_ID
                    order by ARS.ARS_SEQUENCE) loop
      lResult  := lResult || ',' || ltplSeq.ARS_SEQUENCE;
    end loop;

    return substr(lResult, 2);
  end getSavedRubricSeqForWIPTotal;
end FAL_LIB_CALCULATION;
