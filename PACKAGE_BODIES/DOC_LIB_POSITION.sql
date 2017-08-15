--------------------------------------------------------
--  DDL for Package Body DOC_LIB_POSITION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_POSITION" 
is
  /**
  * Description
  *    retourne les stocks et les emplacements d'un bien dans le cadre d'une position ou d'un détail de position de document
  */
  procedure getStockAndLocation(
    inGoodID                 in     number   -- Bien
  , inThirdID                in     number   -- Tiers
  , inMovementKindID         in     number   -- Genre de mouvement
  , ivAdminDomain            in     varchar2
  , inGoodStockID            in     number   -- Stock du bien (données complémentaires)
  , inGoodLocationID         in     number   -- Emplacement du bien (données complémentaires)
  , inParentStockID          in     number   -- Stock parent
  , inParentLocationID       in     number   -- Emplacement parent
  , inParentTargetStockID    in     number   -- Stock cible parent
  , inParentTargetLocationID in     number   -- Emplacement cible parent
  , inInitStock              in     number   -- Initialisation du stock et de l'emplacement
  , inInitStockMovement      in     number   -- Utilisation du stock du genre de mouvement
  , inTransfertStockParent   in     number   -- Transfert stock et emplacement depuis le parent
  , inSourceSupplierID       in     number   -- Sous-traitant permettant l'initialisation du stock source
  , inTargetSupplierID       in     number   -- Sous-traitant permettant l'initialisation du stock cible
  , ionStockID               in out number   -- Stock recherché
  , ionLocationID            in out number   -- Emplacement recherché
  , ionTargetStockID         in out number   -- Stock cible recherché
  , ionTargetLocationID      in out number   -- Emplacement cible recherché
  )
  is
    lnStockID              STM_STOCK.STM_STOCK_ID%type;
    lnLocationID           STM_LOCATION.STM_LOCATION_ID%type;
    lnTargetStockID        STM_STOCK.STM_STOCK_ID%type;
    lnTargetLocationID     STM_LOCATION.STM_LOCATION_ID%type;
    lnMovementKindID       STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lnLinkedMovementKindID STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lbStockManagement      boolean;
    lbFindFirstLocation    boolean;
  begin
    /* Pas d'initialisation des stocks et emplacements. */
    if (nvl(inInitStock, 0) = 0) then
      /* Vide les stocks et emplacements initiaux. */
      ionStockID           := 0;
      ionLocationID        := 0;
      ionTargetStockID     := 0;
      ionTargetLocationID  := 0;
    else
      ionStockID           := nvl(ionStockID, 0);
      ionLocationID        := nvl(ionLocationID, 0);
      ionTargetStockID     := nvl(ionTargetStockID, 0);
      ionTargetLocationID  := nvl(ionTargetLocationID, 0);
      lbStockManagement    := GCO_I_LIB_FUNCTIONS.IsStockManagement(inGoodID);

      if not lbStockManagement then                                 /* Bien sans gestion de stock */
                                      /* Recherche du stock DEFAULT. */
        ionStockID     := STM_I_LIB_STOCK.GetDefaultStock;
        ionLocationID  := 0;

        if (nvl(inMovementKindID, 0) <> 0) then   /* Genre de mouvement existant */
          begin
            /* Recherche le mouvement lié au mouvement */
            select STM_STM_MOVEMENT_KIND_ID
              into lnLinkedMovementKindID
              from STM_MOVEMENT_KIND
             where STM_MOVEMENT_KIND_ID = inMovementKindID;

            if (nvl(lnLinkedMovementKindID, 0) <> 0) then
              ionTargetStockID     := ionStockID;
              ionTargetLocationID  := 0;
            else
              ionTargetStockID     := 0;
              ionTargetLocationID  := 0;
            end if;
          exception
            when no_data_found then
              ionTargetStockID     := 0;
              ionTargetLocationID  := 0;
          end;
        else   /* Genre de mouvement inexistant */
          ionTargetStockID     := 0;
          ionTargetLocationID  := 0;
        end if;
      end if;

      /* Tous les stocks et emplacements sont renseignés. */
      if     (ionStockID <> 0)
         and (ionLocationID <> 0)
         and (ionTargetStockID <> 0)
         and (ionTargetLocationID <> 0) then
        /* Fin de traitement */
        null;
      elsif not lbStockManagement then   /* Bien sans gestion de stock */
                                         /* Fin de traitement */
        null;
      else
        lnLocationID         := 0;
        lnTargetStockID      := 0;
        lnTargetLocationID   := 0;
        lbFindFirstLocation  := false;

        /* Recherche du stock et de l'emplacement source. */

        /* Initialise le stock et l'emplacement source avec le stock du sous-traitant */
        if inSourceSupplierID is not null then
          STM_LIB_STOCK.getSubCStockAndLocation(inSourceSupplierID, ionStockID, ionLocationID);
        elsif     STM_I_LIB_MOVEMENT.IsPreciousMatMovement(inMovementKindID) = 1
              and ivAdminDomain in(DOC_LIB_DOCUMENT.cAdminDomainSale, DOC_LIB_DOCUMENT.cAdminDomainPurchase)
              and GCO_I_LIB_ALLOY.IsGoodLinkedToAlloy(inGoodID) = 1 then
          ionStockID     := nvl(PAC_THIRD_ALLOY_FUNCTIONS.GetMetalAccount(inThirdID, ivAdminDomain), 0);
          ionLocationId  := STM_I_LIB_STOCK.GetDefaultLocation(ionStockID);
        end if;

        /* Stock initial inexistant. */
        if (ionStockID = 0) then
          /* Utilisation du stock des genres de mouvement et genre de mouvement
             existant. */
          if     (nvl(inInitStockMovement, 0) = 1)
             and (nvl(inMovementKindID, 0) <> 0) then
            /* Recherche du stock du genre de mouvement source. */
            select STM_STOCK_ID
              into lnStockID
              from STM_MOVEMENT_KIND
             where STM_MOVEMENT_KIND_ID = inMovementKindID;
          else
            /* Stock parent existant et transfert stock autorisé dans le flux. */
            if     (nvl(inParentStockID, 0) <> 0)
               and (nvl(inTransfertStockParent, 0) = 1) then
              lnStockID     := inParentStockID;
              lnLocationID  := inParentLocationID;
            else
              lnStockID     := inGoodStockID;
              lnLocationID  := inGoodLocationID;
            end if;
          end if;

          ionStockID  := lnStockID;

          if     (ionLocationID = 0)
             and (nvl(lnLocationID, 0) = 0) then
            lbFindFirstLocation  := true;
          elsif     (ionLocationID = 0)
                and (nvl(lnLocationID, 0) <> 0) then
            ionLocationID  := lnLocationID;
          else
            /* Nous sommes dans le cas ou le stock initial n'est pas définit
               au contraire de l'emplacement initial. Il existe deux possibilité :

               1. Le stock recherché prime sur l'emplacement et on écrase
                  l'emplacement initial par le premier emplacement du stock recherché.
               2. L'emplacement prime sur le stock recherché et on recherche le stock
                  de l'emplacement initial.

               Le choix que je fait est le 1. (à discuter)  */
            lbFindFirstLocation  := true;
          end if;
        elsif(ionLocationID = 0) then
          /* Le stock initial est définit, mais pas l'emplacement. On demande
             l'initialisation par le premier emplacement du stock. */
          lbFindFirstLocation  := true;
        end if;

        /* Demande de recherche le premier emplacement du stock spécifié. */
        if     lbFindFirstLocation
           and (nvl(ionStockID, 0) <> 0) then
          /* Recherche du premier emplacement d'un stock particulier ( classement ). */
          ionLocationId  := STM_I_LIB_STOCK.GetDefaultLocation(ionStockID);
        end if;

        /* Recherche du stock et de l'emplacement cible. */
        lbFindFirstLocation  := false;

        /* Initialise le stock et l'emplacement cible avec le stock du sous-traitant */
        if inTargetSupplierID is not null then
          STM_LIB_STOCK.getSubCStockAndLocation(inTargetSupplierID, ionTargetStockID, ionTargetLocationID);
        end if;

        /* Stock cible initial inexistant. */
        if (ionTargetStockID = 0) then
          /* Genre de mouvement existant. */
          if (inMovementKindID <> 0) then
            /* Recherche de l'ID du mouvement de destination du transfert. */
            select STM_STM_MOVEMENT_KIND_ID
              into lnMovementKindID
              from STM_MOVEMENT_KIND
             where STM_MOVEMENT_KIND_ID = inMovementKindID;

            /* Un mouvement lié existe. */
            if (nvl(lnMovementKindID, 0) <> 0) then
              /* Recherche du stock du genre de mouvement cible liés au genre de
                mouvement source. */
              select STM_STOCK_ID
                into lnTargetStockID
                from STM_MOVEMENT_KIND
               where STM_MOVEMENT_KIND_ID = lnMovementKindID;

              if (nvl(lnTargetStockID, 0) = 0) then
                /* Un genre de mouvement de destination de transfert a été trouvé et
                  aucun stock n'est définit sur ce genre de mouvement. On initialise
                  le stock cible (de transfert) avec si il existe le stock du parent
                  (pour autant que le parent soit lié à un genre de mouvement de
                  transfert, donc que le stock cible du parent est <> de 0)
                  sinon le stock du bien. */
                if     (nvl(inParentStockID, 0) <> 0)
                   and (nvl(inParentTargetStockID, 0) <> 0) then
                  lnTargetStockID     := inParentStockID;
                  lnTargetLocationID  := inParentLocationID;
                else
                  lnTargetStockID     := inGoodStockID;
                  lnTargetLocationID  := inGoodLocationID;
                end if;
              end if;
            end if;
          end if;

          ionTargetStockID  := lnTargetStockID;

          if     (ionTargetLocationID = 0)
             and (nvl(lnTargetLocationID, 0) = 0) then
            lbFindFirstLocation  := true;
          elsif     (ionTargetLocationID = 0)
                and (nvl(lnTargetLocationID, 0) <> 0) then
            ionTargetLocationID  := lnTargetLocationID;
          else
            /* Nous sommes dans le cas ou le stock initial n'est pas définit
               au contraire de l'emplacement initial. Il existe deux possibilité :

              1. Le stock recherché prime sur l'emplacement et on écrase
                 l'emplacement initial par le premier emplacement du stock recherché.
              2. L'emplacement prime sur le stock recherché et on recherche le stock
                 de l'emplacement initial.

              Le choix que je fait est le 1. (à discuter)  */
            lbFindFirstLocation  := true;
          end if;
        elsif(ionTargetLocationID = 0) then
          /* Le stock cible initial est définit, mais pas l'emplacement. On demande
            l'initialisation par le premier emplacement du stock. */
          lbFindFirstLocation  := true;
        end if;

        /* Demande de recherche le premier emplacement du stock spécifié. */
        if     lbFindFirstLocation
           and (nvl(ionTargetStockID, 0) <> 0) then
          /* Recherche du premier emplacement d'un stock particulier ( classement ). */
          ionTargetLocationID  := STM_I_LIB_STOCK.GetDefaultLocation(ionTargetStockID);
        end if;
      end if;
    end if;

    /* Vide les valeurs des ID des stocks et emplacements trouvés si elles
       ont une valeur 0. */
    if (ionStockID = 0) then
      ionStockID  := null;
    end if;

    if (ionLocationID = 0) then
      ionLocationID  := null;
    end if;

    if (ionTargetStockID = 0) then
      ionTargetStockID  := null;
    end if;

    if (ionTargetLocationID = 0) then
      ionTargetLocationID  := null;
    end if;
  end GetStockAndLocation;

  /**
  * function IsCptStkOutage
  * Description
  *   Indique s'il y a une rupture de stock (méthode générique)
  */
  function IsCptStkOutage(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lnGaugeID        DOC_GAUGE.DOC_GAUGE_ID%type;
    lnScheduleStepID DOC_POSITION.FAL_SCHEDULE_STEP_ID%type;
    lnLotID          DOC_POSITION.FAL_LOT_ID%type;
    lnResult         number                                   default 0;
  begin
    select DMT.DOC_GAUGE_ID
         , POS.FAL_SCHEDULE_STEP_ID
         , POS.FAL_LOT_ID
      into lnGaugeID
         , lnScheduleStepID
         , lnLotID
      from DOC_POSITION POS
         , DOC_DOCUMENT DMT
     where POS.DOC_POSITION_ID = iPositionID
       and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

    -- Sous-traitance d'achat
    if DOC_LIB_SUBCONTRACTP.IsGaugeSubcontractP(lnGaugeID) = 1 then
      lnResult  := DOC_LIB_SUBCONTRACTP.IsBatchCptStkOutage(iPositionID => iPositionID);
    -- Sous-traitance opératoire
    elsif     (lnScheduleStepID is not null)
          and (lnLotID is null) then
      lnResult  := DOC_LIB_SUBCONTRACTO.IsBatchCptStkOutage(iPositionID => iPositionID);
    end if;

    return lnResult;
  end IsCptStkOutage;

  /**
  * function pGetPosDischarged
  * Description
  *   Retourne pour une position document, la qté déchargée directement ou indirectement par un document issu d'un échéancier
  * @created fpe 24.02.2014
  * @updated
  * @public
  * @param iPositionID : Id de la position
  * @return voir desciption
  */
  function pGetPosDischarged(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_POSITION.POS_BASIS_QUANTITY%type
  is
    lSumDischarged DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type   := 0;
  begin
    for ltplDetail in (select nvl(PDESON.PDE_BASIS_QUANTITY, 0) PDE_BASIS_QUANTITY
                            , POSSON.DOC_INVOICE_EXPIRY_ID
                            , POSSON.DOC_POSITION_ID
                            , DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosRetDeposit(POSSON.DOC_POSITION_ID) IsPosRetDeposit
                         from DOC_POSITION POSPAR
                            , DOC_POSITION_DETAIL PDEPAR
                            , DOC_POSITION_DETAIL PDESON
                            , DOC_POSITION POSSON
                            , DOC_DOCUMENT DMTSON
                        where POSPAR.DOC_POSITION_ID = iPositionId
                          and PDEPAR.DOC_POSITION_ID = POSPAR.DOC_POSITION_ID
                          and PDESON.DOC_DOC_POSITION_DETAIL_ID = PDEPAR.DOC_POSITION_DETAIL_ID
                          and POSSON.DOC_POSITION_ID = PDESON.DOC_POSITION_ID
                          and DMTSON.DOC_DOCUMENT_ID = PDESON.DOC_DOCUMENT_ID
                          and DMTSON.GAL_CURRENCY_RISK_VIRTUAL_ID is not null) loop
      if ltplDetail.DOC_INVOICE_EXPIRY_ID is not null then
        lSumDischarged  := lSumDischarged + ltplDetail.PDE_BASIS_QUANTITY;
      else
        lSumDischarged  := lSumDischarged + pGetPosDischarged(ltplDetail.DOC_POSITION_ID);
      end if;
    end loop;

    return lSumDischarged;
  end pGetPosDischarged;

  /**
  * Description
  *   Retourne la qté solde non liée à des positions enfant couvertes en risque de change
  */
  function GetChangeRiskBalanceQty(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lPosBasisQuantity    DOC_POSITION.POS_BASIS_QUANTITY%type;
    lDocInvoiceExpiryId  DOC_POSITION.DOC_INVOICE_EXPIRY_ID%type;
    lPosBalanceQuantity  DOC_POSITION.POS_BASIS_QUANTITY%type;
    lPosQuantityBalanced DOC_POSITION.POS_QUANTITY_BAlANCED%type;
    lDocumentId          DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lCGaugeTypePos       DOC_POSITION.C_GAUGE_TYPE_POS%type;
    lDmtCurrRateForced   DOC_DOCUMENT.DMT_CURR_RATE_FORCED%type;
    lCDocumentStatus     DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    lGasBalanceStatus    DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type;
  begin
    select POS.POS_BASIS_QUANTITY
         , POS.DOC_INVOICE_EXPIRY_ID
         , POS.POS_BALANCE_QUANTITY
         , POS.POS_QUANTITY_BALANCED
         , POS.C_GAUGE_TYPE_POS
         , DMT.DOC_DOCUMENT_ID
         , nvl(DMT.DMT_CURR_RATE_FORCED, 0)
         , DMT.C_DOCUMENT_STATUS
         , GAS.GAS_BALANCE_STATUS
      into lPosBasisQuantity
         , lDocInvoiceExpiryId
         , lPosBalanceQuantity
         , lPosQuantityBalanced
         , lCGaugeTypePos
         , lDocumentId
         , lDmtCurrRateForced
         , lCDocumentStatus
         , lGasBalanceStatus
      from DOC_POSITION POS
         , DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
     where POS.DOC_POSITION_ID = iPositionID
       and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID;

    -- la commande avec échéancier est complétement facturée
    if DOC_INVOICE_EXPIRY_FUNCTIONS.IsFinalInvoiceGenerated(lDocumentId) then
      return 0;
    -- document sans risque de change
    elsif lDmtCurrRateForced = 0 then
      return 0;
    -- Document de vente en multi-couverture
    elsif DOC_I_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(lDocumentId) = 1 then
      return 0;
    -- document annulé
    elsif lCDocumentStatus = '05' then
      return 0;
    -- position récapitulation
    elsif lCGaugeTypePos = '6' then
      return 0;
    -- position soldée
    elsif     lPosBalanceQuantity = 0
          and lPosQuantityBalanced <> 0 then
      return 0;
    -- si position d'accompte
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosDeposit(iPositionID) = 1 then
      return lPosBasisQuantity;
    -- si note de credit (sur acompte,sur facture) en provenance d'un échéancier on ne consomme ni ne libère de tranche, car seront utilisées par la suite
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosCreditNotExpiry4_5(iPositionID) = 2 then
      return(-1 * lPosBasisQuantity);
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosCreditNotExpiry4_5(iPositionID) = 1 then
      return 0;
    -- Note de crédit de type sur contrat -> doit libérer la tranche
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosCreditNotExpiry6(iPositionID) = 1 then
      return(-1 * lPosBasisQuantity);
    -- document gérant une libération de solde non gérée par un échéancier libère toujours la tranche
    elsif DOC_I_LIB_POSITION.IsPosFromCreditNoteOutOfExpiry(iPositionID) = 1 then
      return(-1 * lPosBasisQuantity);
    -- si on est en face d'une reprise d'accompte
    --   ici le montant de la pos est négatif et il doit être pris en compte (Facture finale)
    --   la consommation de la tranche a été effectuée par l'accompte et doit le rester
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosRetDeposit(iPositionID) = 1 then
      return lPosBasisQuantity;
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosRetCreditNote5(iPositionID) = 2 then
      return lPosBasisQuantity;
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosRetCreditNote5(iPositionID) = 1 then
      return 0;
    -- position déchargée d'un document échéancier sans décharge
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosDischargedFromOnlyAmount(iPositionID) = 1 then
      return 0;
    -- position déchargée d'un document échéancier avec décharge mais pas générée par l'échéancier
    elsif     DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosDischargedFromBillBook(iPositionID) = 1
          and lDocInvoiceExpiryId is null then
      return 0;
    -- position générée sur un échéancier sans décharge -- CTL HMO
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosFromOnlyAmount(iPositionID) = 1 then
      return lPosBasisQuantity;
    --échéancier avec décharge
    elsif DOC_INVOICE_EXPIRY_FUNCTIONS.IsDocOnlyDischargedBillBook(lDocumentId) then
      return lPosBasisQuantity;
    -- si on ne gère pas le statut soldé -- HMO cf FPE
    elsif lGasBalanceStatus = 0 then
      return lPosBasisQuantity;
    else
      return lPosBalanceQuantity;
    end if;
  end GetChangeRiskBalanceQty;

  /**
  * Description
  *   Liste des erreurs suite au contrôle des données stock sur les positions. DOC_PRC_POSITION.PositionsStockControl.
  *   Retourne un texte pour afficher sous forme de message d'erreur utilisateur,
  */
  function GetPositionStkCtrlErrorList(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  is
    lResult         varchar2(1000);
    lCR             varchar2(1);
    lComponentSpace varchar2(10);
  begin
    -- pour toutes les position en erreur
    for ltplPosition in (select   POS_NUMBER
                                , C_DOC_POS_ERROR
                                , DOC_DOC_POSITION_ID
                                , IsCptError(DOC_POSITION_ID) CPT_ERROR
                             from DOC_POSITION
                            where DOC_DOCUMENT_ID = iDocumentId
                              and C_DOC_POS_ERROR is not null
                         order by POS_NUMBER) loop
      -- Si liste trop longue, on tronque
      if    lResult is null
         or length(lResult) < 900 then
        if     ltplPosition.CPT_ERROR = 0
           and ltplPosition.DOC_DOC_POSITION_ID is null then
          lComponentSpace  := '';
        elsif ltplPosition.DOC_DOC_POSITION_ID is not null then
          lComponentSpace  := rpad(' ', 9, ' ');
        end if;

        lResult  :=
          lResult ||
          lCR ||
          lComponentSpace ||
          PCS.PC_FUNCTIONS.TranslateWord('Position') ||
          ' ' ||
          ltplPosition.POS_NUMBER ||
          ' : ' ||
          PCS.PC_FUNCTIONS.GetDescodeDescr('C_DOC_POS_ERROR', ltplPosition.C_DOC_POS_ERROR);
        lCR      := CO.cLineBreak;
      else
        exit;
      end if;
    end loop;

    return lResult;
  end GetPositionStkCtrlErrorList;

  /**
  * Description
  *    contrôle que le document n'ait pas de position en manco
  */
  function isStockOutage(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    result DOC_POSITION.POS_STOCK_OUTAGE%type;
  begin
    -- Mise à jour des flags avant de contrôler
    DOC_FUNCTIONS.FLAGPOSITIONMANCO(iPositionId, null);

    -- Recherche si au moins une position est en rupture de stock
    select max(nvl(POS_STOCK_OUTAGE, 0) )
      into result
      from DOC_POSITION
     where DOC_POSITION_ID = iPositionId
       and POS_STOCK_OUTAGE = 1;

    return result;
  end isStockOutage;

  /**
  * Description
  *    Renvoie l'erreur si il y a une erreur sur un des composant de la position PT
  */
  function IsCptError(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lDocPosError DOC_POSITION.C_DOC_POS_ERROR%type;
  begin
    -- recherche du code erreur
    select min(C_DOC_POS_ERROR)
      into lDocPosError
      from DOC_POSITION
     where DOC_DOC_POSITION_ID = iPositionId;

    return Bool2Byte(lDocPosError is not null);
  end IsCptError;

  /**
  * Description
  *    Fonction vérifiant la présence d'au moins une valeur de caractérisation lié à une position d'un document
  */
  function HasCharactValue(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return integer
  is
    lExists integer;
  begin
    select count(1)
      into lExists
      from dual
     where exists(
             select 1
               from DOC_POSITION_DETAIL
              where DOC_POSITION_ID = iPositionId
                and (   PDE_CHARACTERIZATION_VALUE_1 is not null
                     or PDE_CHARACTERIZATION_VALUE_2 is not null
                     or PDE_CHARACTERIZATION_VALUE_3 is not null
                     or PDE_CHARACTERIZATION_VALUE_4 is not null
                     or PDE_CHARACTERIZATION_VALUE_5 is not null
                    ) );

    return lExists;
  end HasCharactValue;

  /**
  * Description
  *   Initialisation de la date de péremption
  */
  function InitExpiryDate(iCharId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, iPositionId in number default null)
    return varchar2
  is
    function GetExternalExpiryDate(iPositionId in number, iGoodID in number)
      return varchar2
    is
      lResult varchar2(8);
    begin
      execute immediate 'select ' || DOC_I_LIB_CONSTANT.gcCfgInitExpiryDateProc || '(:POSITIONID, :IGOODID) from dual'
                   into lResult
                  using iPositionId, iGoodId;

      return lResult;
    exception
      when others then
        ra
          (PCS.PC_FUNCTIONS.TranslateWord
                              ('DOCPCS - Erreur lors de l''exécution de la procedure individualisée renseignée dans la configuration DOC_INIT_EXPIRY_DATE_PROC.')
          );
    end GetExternalExpiryDate;
  begin
    case DOC_I_LIB_CONSTANT.gcCfgInitExpiryDate
      when 0 then   -- Initialisation standard : date du jour + marge de péremption
        return GCO_I_LIB_CHARACTERIZATION.CalcTimeLimit(iCharId);
      when 1 then   -- pas d'initialisation
        return null;
      when 2 then   -- Date de fabrication + délai de péremption
        -- Pas encore géré
        return null;
      when 3 then   -- Initialisation selon procedure indiv.
        return GetExternalExpiryDate(FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'GCO_GOOD_ID', iCharId), iPositionId);
    end case;
  end InitExpiryDate;

   /**
  * function IsPosFromCreditNoteOutOfExpiry
  * Description
  *   Retourne pour une poisiotn si elle doit libérer du solde de la tranche de couverture (config du gabarit en remove) !!Ne pas utiliser dans un test pour un document issu de l'échéancier!!
  */
  function IsPosFromCreditNoteOutOfExpiry(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lTest number(1);
  begin
    if    DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosCreditNotExpiry4_5(iPositionID) = 1
       or DOC_INVOICE_EXPIRY_FUNCTIONS.IsPosCreditNotExpiry6(iPositionID) = 1 then
      return 0;
    else
      select case
               when nvl(GAS.C_DOC_JOURNAL_CALCULATION, 'ADD') = 'ADD' then 0
               else 1
             end MULTIPLY_FACTOR
        into lTest
        from DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_POSITION POS
       where POS.DOC_POSITION_ID = iPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;

      return lTest;
    end if;
  end IsPosFromCreditNoteOutOfExpiry;

  /**
  * Description
  *   Table function that return a list of active document positions for the good and version asked
  */
  function GetVersionInProgress(iGoodId in DOC_POSITION.GCO_GOOD_ID%type, iVersion in DOC_POSITION_DETAIL.PDE_VERSION%type)
    return ID_TABLE_TYPE
  is
    lResult ID_TABLE_TYPE;
  begin
    select POS.DOC_POSITION_ID
    bulk collect into lResult
      from DOC_POSITION POS
         , DOC_POSITION_DETAIL PDE
     where POS.GCO_GOOD_ID = iGoodId
       and (   PDE.PDE_VERSION = iVersion
            or iVersion is null
            or PDE.PDE_VERSION is null)
       and PDE.DOC_POSITION_ID(+) = POS.DOC_POSITION_ID
       and C_DOC_POS_STATUS in(DOC_LIB_CONSTANT.gcDocPosStatusToConfirm, DOC_LIB_CONSTANT.gcDocPosStatusPartial);

    return lResult;
  end GetVersionInProgress;

  /**
  * Description
  *   Return 1 if ther is something of the current version in active document positions
  */
  function IsVersionInProgress(iGoodId in DOC_POSITION.GCO_GOOD_ID%type, iVersion in DOC_POSITION_DETAIL.PDE_VERSION%type)
    return number
  is
    lResult pls_integer;
  begin
    select sign(count(*) )
      into lResult
      from table(DOC_LIB_POSITION.GetVersionInProgress(iGoodId, iVersion) );

    return lResult;
  end IsVersionInProgress;

  /**
  * Description
  *   Retourne le numéro de position
  */
  function GetPosNumber(iPosDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return number
  is
    lnResult DOC_POSITION.POS_NUMBER%type;
  begin
    select DOC_POSITION.POS_NUMBER
      into lnResult
      from DOC_POSITION_DETAIL
         , DOC_POSITION
     where DOC_POSITION_DETAIL.DOC_POSITION_ID = DOC_POSITION.DOC_POSITION_ID
       and DOC_POSITION_DETAIL_ID = iPosDetailId;

    return lnResult;
  exception
    when no_data_found then
      return null;
  end GetPosNumber;
end DOC_LIB_POSITION;
