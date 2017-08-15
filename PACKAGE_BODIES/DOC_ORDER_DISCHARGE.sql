--------------------------------------------------------
--  DDL for Package Body DOC_ORDER_DISCHARGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_ORDER_DISCHARGE" 
is
  /**
  * Description
  *   1.Recherche des détails de même bien/tiers sur des commandes cadres
  *   2.Effectue un lien de décharge entre la CF et la commande cadre
  */
  procedure DischargeOrder(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    -- Recherche des détails du document courant pour lesquels ont doit faire un lien de décharge
    cursor crDetailList(cDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   POS.DOC_POSITION_ID
             , POS.GCO_GOOD_ID
             , POS.POS_FINAL_QUANTITY
             , PDE.DOC_POSITION_DETAIL_ID
             , PDE.PDE_FINAL_QUANTITY
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
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
         where POS.DOC_DOCUMENT_ID = cDocumentID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and PDE.DOC_DOC_POSITION_DETAIL_ID is null
           and POS.C_GAUGE_TYPE_POS = '1'
           and POS.C_DOC_POS_STATUS < '03'
      order by POS.POS_NUMBER
             , PDE.PDE_BASIS_DELAY
             , PDE.PDE_FINAL_QUANTITY desc;

    aParentDetail     ParentDetail;
    --
    vModified         number(1);
    vDOC_GAUGE_ID     DOC_GAUGE.DOC_GAUGE_ID%type;
    vPAC_THIRD_ID     DOC_DOCUMENT.PAC_THIRD_ID%type;
    vPAC_THIRD_ACI_ID DOC_DOCUMENT.PAC_THIRD_ACI_ID%type;
    vC_ADMIN_DOMAIN   DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lbFirstLoop       boolean;
    lbUpdated         boolean;
  begin
    lbFirstLoop  := true;
    lbUpdated    := false;

    -- Recherche l'ID du gabarit et le tiers du document courant
    select DMT.DOC_GAUGE_ID
         , DMT.PAC_THIRD_ID
         , DMT.PAC_THIRD_ACI_ID
         , GAU.C_ADMIN_DOMAIN
      into vDOC_GAUGE_ID
         , vPAC_THIRD_ID
         , vPAC_THIRD_ACI_ID
         , vC_ADMIN_DOMAIN
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
     where DMT.DOC_DOCUMENT_ID = aDocumentID
       and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    -- Rechercher tous les gabarits source (Commande cadre) selon le flux déchargeable
    for ltplGaugeSrc in (select   GAR.DOC_GAUGE_RECEIPT_ID
                                , GAD.DOC_GAUGE_FLOW_ID
                                , GAU_SRC.DOC_GAUGE_ID SRC_DOC_GAUGE_ID
                             from DOC_GAUGE GAU_SRC
                                , DOC_GAUGE_RECEIPT GAR
                                , DOC_GAUGE_FLOW_DOCUM GAD
                            where GAU_SRC.DIC_GAUGE_CATEG_ID in('Cmd_Cadre', 'PUR-MPO', 'SAL-OA')
                              and GAU_SRC.C_GAUGE_STATUS = '2'
                              and GAU_SRC.C_ADMIN_DOMAIN = vC_ADMIN_DOMAIN
                              and GAR.DOC_GAUGE_FLOW_DOCUM_ID = GAD.DOC_GAUGE_FLOW_DOCUM_ID
                              and GAR.DOC_GAUGE_RECEIPT_ID = DOC_LIB_GAUGE.GetGaugeReceiptID(GAU_SRC.DOC_GAUGE_ID, vDOC_GAUGE_ID, vPAC_THIRD_ID)
                         order by GAU_SRC.GAU_DESCRIBE) loop
      -- Enlever les arrondis TVA la 1ere fois uniquement
      if lbFirstLoop then
        -- Enlever les arrondis TVA
        DOC_PRC_VAT.RemoveVatCorrectionAmount(iDocumentId => aDocumentID, iRemoveRound => 1, iRemoveCorr => 0, oModified => vModified);
        -- Recalculer les montants du pied
        DOC_FUNCTIONS.UpdateFootTotals(foot_id => aDocumentID, aChanged => vModified);
        lbFirstLoop  := false;
        lbUpdated    := true;
      end if;

      -- Balayer chaque détail du document courant
      for tplDetailList in crDetailList(aDocumentID) loop
        -- Chercher du disponnible pour la position courante sur les détails parents
        open aParentDetail for
          select   PDE.DOC_DOCUMENT_ID
                 , PDE.DOC_POSITION_ID
                 , PDE.DOC_POSITION_DETAIL_ID
                 , PDE.DOC2_DOC_POSITION_DETAIL_ID
                 , PDE.PDE_BALANCE_QUANTITY
              from DOC_DOCUMENT DMT
                 , DOC_POSITION POS
                 , DOC_POSITION_DETAIL PDE
             where DMT.DOC_GAUGE_ID = ltplGaugeSrc.SRC_DOC_GAUGE_ID
               and DMT.PAC_THIRD_ID = vPAC_THIRD_ID
               and DMT.PAC_THIRD_ACI_ID = vPAC_THIRD_ACI_ID
               and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
               and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
               and POS.GCO_GOOD_ID = tplDetailList.GCO_GOOD_ID
               and POS.C_DOC_POS_STATUS in('02', '03')
               and PDE.PDE_BALANCE_QUANTITY > 0
               and nvl(PDE.GCO_CHARACTERIZATION_ID, -1) = nvl(tplDetailList.GCO_CHARACTERIZATION_ID, -1)
               and nvl(PDE.GCO_GCO_CHARACTERIZATION_ID, -1) = nvl(tplDetailList.GCO_GCO_CHARACTERIZATION_ID, -1)
               and nvl(PDE.GCO2_GCO_CHARACTERIZATION_ID, -1) = nvl(tplDetailList.GCO2_GCO_CHARACTERIZATION_ID, -1)
               and nvl(PDE.GCO3_GCO_CHARACTERIZATION_ID, -1) = nvl(tplDetailList.GCO3_GCO_CHARACTERIZATION_ID, -1)
               and nvl(PDE.GCO4_GCO_CHARACTERIZATION_ID, -1) = nvl(tplDetailList.GCO4_GCO_CHARACTERIZATION_ID, -1)
               and nvl(PDE.PDE_CHARACTERIZATION_VALUE_1, '-NULL-') = nvl(tplDetailList.PDE_CHARACTERIZATION_VALUE_1, '-NULL-')
               and nvl(PDE.PDE_CHARACTERIZATION_VALUE_2, '-NULL-') = nvl(tplDetailList.PDE_CHARACTERIZATION_VALUE_2, '-NULL-')
               and nvl(PDE.PDE_CHARACTERIZATION_VALUE_3, '-NULL-') = nvl(tplDetailList.PDE_CHARACTERIZATION_VALUE_3, '-NULL-')
               and nvl(PDE.PDE_CHARACTERIZATION_VALUE_4, '-NULL-') = nvl(tplDetailList.PDE_CHARACTERIZATION_VALUE_4, '-NULL-')
               and nvl(PDE.PDE_CHARACTERIZATION_VALUE_5, '-NULL-') = nvl(tplDetailList.PDE_CHARACTERIZATION_VALUE_5, '-NULL-')
          order by DMT.DOC_DOCUMENT_ID asc
                 , POS.POS_NUMBER asc
                 , PDE.PDE_BASIS_DELAY asc
                 , PDE.PDE_BALANCE_QUANTITY desc;

        -- Détails parents disponnibles
        CreateDischargeLink(aPositionID       => tplDetailList.DOC_POSITION_ID
                          , aDetailID         => tplDetailList.DOC_POSITION_DETAIL_ID
                          , aGaugeFlowID      => ltplGaugeSrc.DOC_GAUGE_FLOW_ID
                          , aGaugeReceiptID   => ltplGaugeSrc.DOC_GAUGE_RECEIPT_ID
                          , aParentDetail     => aParentDetail
                           );

        close aParentDetail;
      end loop;   -- Fin boucle des détails de position du document courant
    end loop;

    if lbUpdated then
      -- Enlever les arrondis TVA
      DOC_PRC_VAT.AppendVatCorrectionAmount(iDocumentId => aDocumentID, iAppendRound => 1, iAppendCorr => 0, oModified => vModified);
      -- Recalculer les montants du pied
      DOC_FUNCTIONS.UpdateFootTotals(foot_id => aDocumentID, aChanged => vModified);
    end if;
  end DischargeOrder;

  /**
  * Description
  *   C'est la méthode la plus importante du package, elle s'occupe
  *   de faire le lien de décharge sur le détail, màj les parents
  *   et si nécessaire elle splitte la position en plusieurs positions pour
  *   effectuer de multiples décharges
  */
  procedure CreateDischargeLink(
    aPositionID     in     DOC_POSITION.DOC_POSITION_ID%type
  , aDetailID       in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aGaugeFlowID    in     DOC_POSITION_DETAIL.DOC_GAUGE_FLOW_ID%type
  , aGaugeReceiptID in     DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type
  , aParentDetail   in out ParentDetail
  )
  is
    -- Liste des positions du document courant pour lequelles on doit trouver des détails parent pour la décharge
    cursor crPositionInfo(cPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    is
      select POS.DOC_POSITION_ID
           , POS.POS_FINAL_QUANTITY
        from DOC_POSITION POS
       where POS.DOC_POSITION_ID = cPositionID;

    tplPositionInfo crPositionInfo%rowtype;

    -- Recherche des détails du document courant pour lesquels ont doit faire un lien de décharge
    cursor crDetailInfo(cDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , PDE.GCO_GOOD_ID
           , PDE.PDE_FINAL_QUANTITY
           , PDE.PDE_BALANCE_QUANTITY
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
           , sign(nvl(POS.STM_MOVEMENT_KIND_ID, 0) ) as POS_GEN_MVT
           , GAS.GAS_BALANCE_STATUS
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
       where PDE.DOC_POSITION_DETAIL_ID = cDetailID
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

    tplDetailInfo   crDetailInfo%rowtype;
    tplParentDetail TParentDetailRow;
    NewPositionID   DOC_POSITION.DOC_POSITION_ID%type;
    NewDetailID     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    newPosAmount    DOC_POSITION.POS_GROSS_VALUE%type;
  begin
    NewPositionID  := aPositionID;
    NewDetailID    := aDetailID;

    fetch aParentDetail
     into tplParentDetail;

    -- S'il y encore des détails parents disponnibles, continuer la création du lien de décharge
    if aParentDetail%found then
      open crPositionInfo(NewPositionID);

      fetch crPositionInfo
       into tplPositionInfo;

      open crDetailInfo(NewDetailID);

      fetch crDetailInfo
       into tplDetailInfo;

      -- La position courante possède des détails qui ont déjà des liens de décharge
      if PositionHasLinkedDetail(aPositionID, tplParentDetail.DOC_POSITION_ID) = 1 then
        -- Copier la position
        CreatePositionByCopy(aPositionID => aPositionID, aQuantity => tplDetailInfo.PDE_FINAL_QUANTITY, aNewPosID => NewPositionID);
        -- Créer un détail par copie
        CreateDetailByCopy(aPositionID => NewPositionID, aDetailID => aDetailID, aPdeQty => tplDetailInfo.PDE_FINAL_QUANTITY, aNewDetailID => NewDetailID);

        -- Effacer le détail source
        delete from DOC_POSITION_DETAIL
              where DOC_POSITION_DETAIL_ID = aDetailID;

        -- Màj la qté de la position source
        DOC_POSITION_FUNCTIONS.UpdateQuantityPosition(aPositionID     => aPositionID
                                                    , aNewQuantity    => tplPositionInfo.POS_FINAL_QUANTITY - tplDetailInfo.PDE_FINAL_QUANTITY
                                                    , aKeepPosPrice   => 1
                                                     );

        -- Flags pour la mise à jour des montants
        update DOC_POSITION
           set POS_RECALC_AMOUNTS = 1
             , POS_CREATE_POSITION_CHARGE = 0
             , POS_UPDATE_POSITION_CHARGE = 0
         where DOC_POSITION_ID = aPositionId;

        -- Recalcul des montants de la position source
        DOC_POSITION_FUNCTIONS.UpdateAmountsDiscountCharge(aPositionID);

        close crPositionInfo;

        open crPositionInfo(NewPositionID);

        fetch crPositionInfo
         into tplPositionInfo;

        close crDetailInfo;

        open crDetailInfo(NewDetailID);

        fetch crDetailInfo
         into tplDetailInfo;
      end if;

      -- Màj de lien de décharge sur le détail courant
      UpdateDetailLink(aDetailID         => tplDetailInfo.DOC_POSITION_DETAIL_ID
                     , aGaugeReceiptID   => aGaugeReceiptID
                     , aGaugeFlowID      => aGaugeFlowID
                     , aDocDocPdeID      => tplParentDetail.DOC_POSITION_DETAIL_ID
                     , aDoc2PdeID        => nvl(tplParentDetail.DOC2_DOC_POSITION_DETAIL_ID, tplParentDetail.DOC_POSITION_DETAIL_ID)
                      );
      -- Màj de la qté solde et des differents statuts sur le parent
      UpdateParent(aDocumentID   => tplParentDetail.DOC_DOCUMENT_ID
                 , aPositionID   => tplParentDetail.DOC_POSITION_ID
                 , aDetailID     => tplParentDetail.DOC_POSITION_DETAIL_ID
                 , aQuantity     => least(tplParentDetail.PDE_BALANCE_QUANTITY, tplDetailInfo.PDE_FINAL_QUANTITY)
                  );

      if tplParentDetail.PDE_BALANCE_QUANTITY < tplDetailInfo.PDE_FINAL_QUANTITY then
        -- La qté solde du parent est insuffisante pour le détail fils
        -- Il faut donc splitter ce détail en plusieurs

        -- Modif de la qté du détail courant
        UpdateDetailQty(aDetailID        => tplDetailInfo.DOC_POSITION_DETAIL_ID
                      , aQuantity        => tplParentDetail.PDE_BALANCE_QUANTITY
                      , aPosGenMvt       => tplDetailInfo.POS_GEN_MVT
                      , aBalanceStatus   => tplDetailInfo.GAS_BALANCE_STATUS
                       );
        -- Création d'un nouveau détail avec la qté restante
        CreateDetailByCopy(aPositionID    => tplPositionInfo.DOC_POSITION_ID
                         , aDetailID      => tplDetailInfo.DOC_POSITION_DETAIL_ID
                         , aPdeQty        => tplDetailInfo.PDE_FINAL_QUANTITY - tplParentDetail.PDE_BALANCE_QUANTITY
                         , aNewDetailID   => NewDetailID
                          );
        -- Création d'un lien de décharge pour le détail passé en param
        CreateDischargeLink(aPositionID       => NewPositionID
                          , aDetailID         => NewDetailID
                          , aGaugeFlowID      => aGaugeFlowID
                          , aGaugeReceiptID   => aGaugeReceiptID
                          , aParentDetail     => aParentDetail
                           );
      end if;

      close crPositionInfo;

      close crDetailInfo;
    end if;
  end CreateDischargeLink;

  /**
  * Description
  *   Indique si la position contient des détails qui ont un lien de décharge
  */
  function PositionHasLinkedDetail(aPositionID in DOC_POSITION.DOC_POSITION_ID%type, aSrcPosID in DOC_POSITION.DOC_POSITION_ID%type)
    return integer
  is
    vRetValue integer;
  begin
    select sign(count(PDE.DOC_POSITION_DETAIL_ID) )
      into vRetValue
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION_DETAIL PDE_SRC
     where PDE.DOC_POSITION_ID = aPositionID
       and PDE.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
       and PDE_SRC.DOC_POSITION_ID <> aSrcPosID;

    return vRetValue;
  end PositionHasLinkedDetail;

  /**
  * Description
  *   Màj le lien de décharge sur le détail passé en param
  */
  procedure UpdateDetailLink(
    aDetailID       in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aGaugeReceiptID in DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type
  , aGaugeFlowID    in DOC_POSITION_DETAIL.DOC_GAUGE_FLOW_ID%type
  , aDocDocPdeID    in DOC_POSITION_DETAIL.DOC_DOC_POSITION_DETAIL_ID%type
  , aDoc2PdeID      in DOC_POSITION_DETAIL.DOC2_DOC_POSITION_DETAIL_ID%type
  )
  is
  begin
    update DOC_POSITION_DETAIL
       set DOC_GAUGE_RECEIPT_ID = aGaugeReceiptID
         , DOC_GAUGE_FLOW_ID = aGaugeFlowID
         , DOC_DOC_POSITION_DETAIL_ID = aDocDocPdeID
         , DOC2_DOC_POSITION_DETAIL_ID = aDoc2PdeID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_DETAIL_ID = aDetailID;
  end UpdateDetailLink;

  /**
  * Description
  *   Màj la qté solde et le statut de la position/document d'une position
  *   qui vient d'être déchargée par la procédure de création de lien de décharge
  */
  procedure UpdateParent(
    aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPositionID in DOC_POSITION.DOC_POSITION_ID%type
  , aDetailID   in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aQuantity   in DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type
  )
  is
  begin
    -- Màj de la qté solde du détail parent
    update DOC_POSITION_DETAIL
       set PDE_BALANCE_QUANTITY =
             decode(sign(PDE_FINAL_QUANTITY)
                  , -1, greatest(least( (PDE_BALANCE_QUANTITY - aQuantity), 0), PDE_FINAL_QUANTITY)
                  , least(greatest( (PDE_BALANCE_QUANTITY - aQuantity), 0), PDE_FINAL_QUANTITY)
                   )
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_DETAIL_ID = aDetailID;

    -- Màj de la qté slode de la position parente
    DOC_FUNCTIONS.UpdateBalancePosition(aPositionID, aQuantity, aQuantity, 0);
    -- Màj du statut du document parent
    DOC_PRC_DOCUMENT.UpdateDocumentStatus(aDocumentID);
  end UpdateParent;

  /**
  * Description
  *   Modifie la qté d'un détail
  */
  procedure UpdateDetailQty(
    aDetailID      in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aQuantity      in DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type
  , aPosGenMvt     in integer
  , aBalanceStatus in integer
  )
  is
  begin
    update DOC_POSITION_DETAIL
       set PDE_BASIS_QUANTITY_SU = (PDE_BASIS_QUANTITY_SU / PDE_BASIS_QUANTITY) * aQuantity
         , PDE_INTERMEDIATE_QUANTITY_SU = (PDE_INTERMEDIATE_QUANTITY_SU / PDE_INTERMEDIATE_QUANTITY) * aQuantity
         , PDE_FINAL_QUANTITY_SU = (PDE_FINAL_QUANTITY_SU / PDE_FINAL_QUANTITY) * aQuantity
         , PDE_BASIS_QUANTITY = aQuantity
         , PDE_INTERMEDIATE_QUANTITY = aQuantity
         , PDE_FINAL_QUANTITY = aQuantity
         , PDE_BALANCE_QUANTITY = case
                                   when aBalanceStatus = 1 then aQuantity
                                   else 0
                                 end
         , PDE_MOVEMENT_QUANTITY = case
                                    when aPosGenMvt = 1 then aQuantity
                                    else 0
                                  end
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_DETAIL_ID = aDetailID;
  end UpdateDetailQty;

  /**
  * Description
  *   Création d'une position par copie d'une autre position
  */
  procedure CreatePositionByCopy(
    aPositionID in     DOC_POSITION.DOC_POSITION_ID%type
  , aQuantity   in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , aNewPosID   out    DOC_POSITION.DOC_POSITION_ID%type
  )
  is
    SrcPosQuantity DOC_POSITION.POS_FINAL_QUANTITY%type;
    vDocumentID    DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select DOC_DOCUMENT_ID
         , POS_BASIS_QUANTITY
         , INIT_ID_SEQ.nextval
      into vDocumentID
         , SrcPosQuantity
         , aNewPosID
      from DOC_POSITION
     where DOC_POSITION_ID = aPositionID;

    DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => aNewPosID
                                         , aDocumentID       => vDocumentID
                                         , aPosCreateMode    => '125'
                                         , aSrcPositionID    => aPositionID
                                         , aBasisQuantity    => aQuantity
                                         , aGenerateDetail   => 0
                                          );
    -- Création des remises/taxes selon la copie
    CreatePositionChargeByCopy(aPositionID, aNewPosID, SrcPosQuantity, aQuantity);
    -- Maj des montants de la position
    DOC_POSITION_FUNCTIONS.UpdateAmountsDiscountCharge(aNewPosID);
  end CreatePositionByCopy;

  /**
  * Description
  *   Création d'un détail de position par copie d'un autre détail
  *   le détail créé est attaché à la même position que le détail source
  */
  procedure CreateDetailByCopy(
    aPositionID  in     DOC_POSITION.DOC_POSITION_ID%type
  , aDetailID    in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aPdeQty      in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type
  , aNewDetailID in out DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  )
  is
  begin
    select INIT_ID_SEQ.nextval
      into aNewDetailID
      from dual;

    DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => aNewDetailID
                                     , aPositionID      => aPositionID
                                     , aPdeCreateMode   => '125'
                                     , aQuantity        => aPdeQty
                                     , aSrcDetailID     => aDetailID
                                      );
  end CreateDetailByCopy;

  /**
  * Description
  *   Création des remises/taxes par copie des remises/taxes d'une autre position
  */
  procedure CreatePositionChargeByCopy(
    aSrcPositionID  in DOC_POSITION.DOC_POSITION_ID%type
  , aTgtPositionID  in DOC_POSITION.DOC_POSITION_ID%type
  , aSrcPosQuantity in DOC_POSITION.POS_BASIS_QUANTITY%type
  , aTgtPosQuantity in DOC_POSITION.POS_BASIS_QUANTITY%type
  )
  is
    type TPositionChargeInfo is record(
      DOC_POSITION_CHARGE_ID DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type
    , PCH_AMOUNT             DOC_POSITION_CHARGE.PCH_AMOUNT%type
    , PCH_AMOUNT_B           DOC_POSITION_CHARGE.PCH_AMOUNT_B%type
    , PCH_AMOUNT_E           DOC_POSITION_CHARGE.PCH_AMOUNT_E%type
    , PCH_CALC_AMOUNT        DOC_POSITION_CHARGE.PCH_CALC_AMOUNT%type
    , PCH_CALC_AMOUNT_B      DOC_POSITION_CHARGE.PCH_CALC_AMOUNT_B%type
    , PCH_CALC_AMOUNT_E      DOC_POSITION_CHARGE.PCH_CALC_AMOUNT_E%type
    , PCH_LIABLED_AMOUNT     DOC_POSITION_CHARGE.PCH_LIABLED_AMOUNT%type
    , PCH_LIABLED_AMOUNT_B   DOC_POSITION_CHARGE.PCH_LIABLED_AMOUNT_B%type
    , PCH_LIABLED_AMOUNT_E   DOC_POSITION_CHARGE.PCH_LIABLED_AMOUNT_E%type
    , PCH_FIXED_AMOUNT       DOC_POSITION_CHARGE.PCH_FIXED_AMOUNT%type
    , PCH_FIXED_AMOUNT_B     DOC_POSITION_CHARGE.PCH_FIXED_AMOUNT_B%type
    , PCH_FIXED_AMOUNT_E     DOC_POSITION_CHARGE.PCH_FIXED_AMOUNT_E%type
    );

    type typePositionChargeInfo is table of TPositionChargeInfo;

    tblPositionChargeInfo typePositionChargeInfo;
    i                     integer;
  begin
    insert into DOC_POSITION_CHARGE
                (DOC_POSITION_CHARGE_ID
               , DOC_POSITION_ID
               , PTC_CHARGE_ID
               , PTC_DISCOUNT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , C_FINANCIAL_CHARGE
               , PCH_DESCRIPTION
               , PCH_AMOUNT
               , PCH_RATE
               , PCH_EXPRESS_IN
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , ACS_PJ_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , DOC_DOC_POSITION_CHARGE_ID
               , C_CALCULATION_MODE
               , C_ROUND_TYPE
               , PCH_AMOUNT_B
               , PCH_AMOUNT_E
               , PCH_TRANSFERT_PROP
               , PCH_MODIFY
               , PCH_IN_SERIES_CALCULATION
               , PCH_BALANCE_AMOUNT
               , PCH_NAME
               , PCH_CALC_AMOUNT
               , PCH_CALC_AMOUNT_B
               , PCH_CALC_AMOUNT_E
               , PCH_LIABLED_AMOUNT
               , PCH_LIABLED_AMOUNT_B
               , PCH_LIABLED_AMOUNT_E
               , PCH_FIXED_AMOUNT
               , PCH_FIXED_AMOUNT_B
               , PCH_FIXED_AMOUNT_E
               , PCH_EXCEEDED_AMOUNT_FROM
               , PCH_EXCEEDED_AMOUNT_TO
               , PCH_MIN_AMOUNT
               , PCH_MAX_AMOUNT
               , PCH_IS_MULTIPLICATOR
               , PCH_ROUND_AMOUNT
               , PCH_STORED_PROC
               , PCH_AUTOMATIC_CALC
               , PCH_SQL_EXTERN_ITEM
               , PCH_QUANTITY_FROM
               , PCH_QUANTITY_TO
               , PCH_UNIT_DETAIL
               , DOC_DOCUMENT_ID
               , PAC_THIRD_ID
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , PAC_THIRD_TARIFF_ID
               , PCH_MODIFY_RATE
               , PCH_AMOUNT_V
               , FAM_FIXED_ASSETS_ID
               , HRM_PERSON_ID
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
               , C_FAM_TRANSACTION_TYP
               , DIC_IMP_FREE1_ID
               , DIC_IMP_FREE2_ID
               , DIC_IMP_FREE3_ID
               , DIC_IMP_FREE4_ID
               , DIC_IMP_FREE5_ID
               , PCH_EXCLUSIVE
               , PCH_DISCHARGED
               , PCH_CUMULATIVE
                )
      select INIT_ID_SEQ.nextval   -- DOC_POSITION_CHARGE_ID
           , aTgtPositionID
           , PTC_CHARGE_ID
           , PTC_DISCOUNT_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , C_FINANCIAL_CHARGE
           , PCH_DESCRIPTION
           , (PCH_AMOUNT / aSrcPosQuantity) * aTgtPosQuantity
           , PCH_RATE
           , PCH_EXPRESS_IN
           , sysdate   -- A_DATECRE
           , null   -- A_DATEMOD
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
           , null   -- A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , ACS_PJ_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , DOC_DOC_POSITION_CHARGE_ID
           , C_CALCULATION_MODE
           , C_ROUND_TYPE
           , (PCH_AMOUNT_B / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_AMOUNT_E / aSrcPosQuantity) * aTgtPosQuantity
           , PCH_TRANSFERT_PROP
           , PCH_MODIFY
           , PCH_IN_SERIES_CALCULATION
           , PCH_BALANCE_AMOUNT
           , PCH_NAME
           , (PCH_CALC_AMOUNT / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_CALC_AMOUNT_B / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_CALC_AMOUNT_E / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_LIABLED_AMOUNT / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_LIABLED_AMOUNT_B / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_LIABLED_AMOUNT_E / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_FIXED_AMOUNT / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_FIXED_AMOUNT_B / aSrcPosQuantity) * aTgtPosQuantity
           , (PCH_FIXED_AMOUNT_E / aSrcPosQuantity) * aTgtPosQuantity
           , PCH_EXCEEDED_AMOUNT_FROM
           , PCH_EXCEEDED_AMOUNT_TO
           , PCH_MIN_AMOUNT
           , PCH_MAX_AMOUNT
           , PCH_IS_MULTIPLICATOR
           , PCH_ROUND_AMOUNT
           , PCH_STORED_PROC
           , PCH_AUTOMATIC_CALC
           , PCH_SQL_EXTERN_ITEM
           , PCH_QUANTITY_FROM
           , PCH_QUANTITY_TO
           , PCH_UNIT_DETAIL
           , DOC_DOCUMENT_ID
           , PAC_THIRD_ID
           , PAC_THIRD_ACI_ID
           , PAC_THIRD_DELIVERY_ID
           , PAC_THIRD_TARIFF_ID
           , PCH_MODIFY_RATE
           , PCH_AMOUNT_V
           , FAM_FIXED_ASSETS_ID
           , HRM_PERSON_ID
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
           , C_FAM_TRANSACTION_TYP
           , DIC_IMP_FREE1_ID
           , DIC_IMP_FREE2_ID
           , DIC_IMP_FREE3_ID
           , DIC_IMP_FREE4_ID
           , DIC_IMP_FREE5_ID
           , PCH_EXCLUSIVE
           , PCH_DISCHARGED
           , PCH_CUMULATIVE
        from DOC_POSITION_CHARGE
       where DOC_POSITION_ID = aSrcPositionID;

    select SRC.DOC_POSITION_CHARGE_ID
         , TGT.PCH_AMOUNT
         , TGT.PCH_AMOUNT_B
         , TGT.PCH_AMOUNT_E
         , TGT.PCH_CALC_AMOUNT
         , TGT.PCH_CALC_AMOUNT_B
         , TGT.PCH_CALC_AMOUNT_E
         , TGT.PCH_LIABLED_AMOUNT
         , TGT.PCH_LIABLED_AMOUNT_B
         , TGT.PCH_LIABLED_AMOUNT_E
         , TGT.PCH_FIXED_AMOUNT
         , TGT.PCH_FIXED_AMOUNT_B
         , TGT.PCH_FIXED_AMOUNT_E
    bulk collect into tblPositionChargeInfo
      from DOC_POSITION_CHARGE TGT
         , DOC_POSITION_CHARGE SRC
     where TGT.DOC_POSITION_ID = aTgtPositionId
       and SRC.DOC_POSITION_ID = aSrcPositionId
       and (   TGT.PTC_DISCOUNT_ID = SRC.PTC_DISCOUNT_ID
            or TGT.PTC_CHARGE_ID = SRC.PTC_CHARGE_ID);

    -- Màj des montants des remises/taxes de la position source
    if tblPositionChargeInfo.count > 0 then
      for i in tblPositionChargeInfo.first .. tblPositionChargeInfo.last loop
        update DOC_POSITION_CHARGE
           set PCH_AMOUNT = PCH_AMOUNT - tblPositionChargeInfo(i).PCH_AMOUNT
             , PCH_AMOUNT_B = PCH_AMOUNT_B - tblPositionChargeInfo(i).PCH_AMOUNT_B
             , PCH_AMOUNT_E = PCH_AMOUNT_E - tblPositionChargeInfo(i).PCH_AMOUNT_E
             , PCH_CALC_AMOUNT = PCH_CALC_AMOUNT - tblPositionChargeInfo(i).PCH_CALC_AMOUNT
             , PCH_CALC_AMOUNT_B = PCH_CALC_AMOUNT_B - tblPositionChargeInfo(i).PCH_CALC_AMOUNT_B
             , PCH_CALC_AMOUNT_E = PCH_CALC_AMOUNT_E - tblPositionChargeInfo(i).PCH_CALC_AMOUNT_E
             , PCH_LIABLED_AMOUNT = PCH_LIABLED_AMOUNT - tblPositionChargeInfo(i).PCH_LIABLED_AMOUNT
             , PCH_LIABLED_AMOUNT_B = PCH_LIABLED_AMOUNT_B - tblPositionChargeInfo(i).PCH_LIABLED_AMOUNT_B
             , PCH_LIABLED_AMOUNT_E = PCH_LIABLED_AMOUNT_E - tblPositionChargeInfo(i).PCH_LIABLED_AMOUNT_E
             , PCH_FIXED_AMOUNT = PCH_FIXED_AMOUNT - tblPositionChargeInfo(i).PCH_FIXED_AMOUNT
             , PCH_FIXED_AMOUNT_B = PCH_FIXED_AMOUNT_B - tblPositionChargeInfo(i).PCH_FIXED_AMOUNT_B
             , PCH_FIXED_AMOUNT_E = PCH_FIXED_AMOUNT_E - tblPositionChargeInfo(i).PCH_FIXED_AMOUNT_E
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_CHARGE_ID = tblPositionChargeInfo(i).DOC_POSITION_CHARGE_ID;
      end loop;
    end if;

    update DOC_POSITION
       set POS_RECALC_AMOUNTS = 1
         , POS_CREATE_POSITION_CHARGE = 0
         , POS_UPDATE_POSITION_CHARGE = 0
     where DOC_POSITION_ID = aTgtPositionId;
  end CreatePositionChargeByCopy;
end DOC_ORDER_DISCHARGE;
