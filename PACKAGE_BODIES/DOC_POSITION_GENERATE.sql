--------------------------------------------------------
--  DDL for Package Body DOC_POSITION_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_POSITION_GENERATE" 
is
  /**
  *  procedure ResetPositionInfo
  *  Description
  *    Efface et réinitialise les données de la variable de type
  *    TPositionInfo passée en param
  */
  procedure ResetPositionInfo(aPositionInfo in out DOC_POSITION_INITIALIZE.TPositionInfo)
  is
    tmpPositionInfo DOC_POSITION_INITIALIZE.TPositionInfo;
  begin
    aPositionInfo  := tmpPositionInfo;
  end ResetPositionInfo;

  /**
  *  procedure GeneratePosition
  *  Description
  *    Méthode générale pour la création d'une position
  */
  procedure GeneratePosition(
    aPositionID             in out DOC_POSITION.DOC_POSITION_ID%type
  , aDocumentID             in     DOC_POSITION.DOC_DOCUMENT_ID%type
  , aPosCreateMode          in     varchar2 default null
  , aPosCreateType          in     varchar2 default null
  , aTypePos                in     DOC_POSITION.C_GAUGE_TYPE_POS%type default null
  , aGapID                  in     DOC_POSITION.DOC_GAUGE_POSITION_ID%type default null
  , aGoodID                 in     DOC_POSITION.GCO_GOOD_ID%type default null
  , aPTPositionID           in     DOC_POSITION.DOC_DOC_POSITION_ID%type default null
  , aSrcPositionID          in     DOC_POSITION.DOC_POSITION_ID%type default null
  , aTmpPosID               in     DOC_TMP_POSITION_DETAIL.DOC_POSITION_ID%type default null
  , aTmpPdeID               in     DOC_TMP_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , aInterfaceID            in     DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aInterfacePosID         in     DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type default null
  , aInterfacePosNbr        in     DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type default null
  , aBasisQuantity          in     DOC_POSITION.POS_BASIS_QUANTITY%type default null
  , aBasisQuantitySU        in     DOC_POSITION.POS_BASIS_QUANTITY_SU%type default null
  , aValueQuantity          in     DOC_POSITION.POS_VALUE_QUANTITY%type default null
  , aBalanceQty             in     DOC_POSITION.POS_BALANCE_QUANTITY%type default null
  , aBalanceQtyValue        in     DOC_POSITION.POS_BALANCE_QTY_VALUE%type default null
  , aRecordID               in     DOC_POSITION.DOC_RECORD_ID%type default null
  , aRepresentativeID       in     DOC_POSITION.PAC_REPRESENTATIVE_ID%type default null
  , aForceStockLocation     in     integer default 0
  , aStockID                in     DOC_POSITION.STM_STOCK_ID%type default null
  , aLocationID             in     DOC_POSITION.STM_LOCATION_ID%type default null
  , aTraStockID             in     DOC_POSITION.STM_STM_STOCK_ID%type default null
  , aTraLocationID          in     DOC_POSITION.STM_STM_LOCATION_ID%type default null
  , aUnitCostPrice          in     DOC_POSITION.POS_UNIT_COST_PRICE%type default null
  , aGoodPrice              in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type default null
  , aFalScheduleStepID      in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type default null
  , aPcAppltxtID            in     DOC_POSITION.PC_APPLTXT_ID%type default null
  , aPosBodyText            in     DOC_POSITION.POS_BODY_TEXT%type default null
  , aGenerateDetail         in     integer default 1
  , aGenerateCPT            in     integer default 0
  , aGenerateDiscountCharge in     integer default 1
  , aNomenclatureID         in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type default null
  , aBasisDelay             in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aInterDelay             in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aFinalDelay             in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aCharactValue_1         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type default null
  , aCharactValue_2         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2%type default null
  , aCharactValue_3         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3%type default null
  , aCharactValue_4         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4%type default null
  , aCharactValue_5         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5%type default null
  , aGaugeId                in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  , aLitigID                in     DOC_LITIG.DOC_LITIG_ID%type default null
  , aDebug                  in     number default 1
  , aTargetTable            in     varchar2 default 'DOC_POSITION'
  , aUserInitProc           in     varchar2 default null
  , aManufacturedGoodID     in     DOC_POSITION.GCO_GOOD_ID%type default null
  , aGcoComplDataID         in     DOC_POSITION.GCO_COMPL_DATA_ID%type default null
  )
  is
    errorMsg varchar2(2000);
  begin
    GeneratePosition(aPositionID               => aPositionID
                   , aErrorMsg                 => errorMsg
                   , aDocumentID               => aDocumentID
                   , aPosCreateMode            => aPosCreateMode
                   , aPosCreateType            => aPosCreateType
                   , aTypePos                  => aTypePos
                   , aGapID                    => aGapID
                   , aGoodID                   => aGoodID
                   , aPTPositionID             => aPTPositionID
                   , aSrcPositionID            => aSrcPositionID
                   , aTmpPosID                 => aTmpPosID
                   , aTmpPdeID                 => aTmpPdeID
                   , aInterfaceID              => aInterfaceID
                   , aInterfacePosID           => aInterfacePosID
                   , aInterfacePosNbr          => aInterfacePosNbr
                   , aBasisQuantity            => aBasisQuantity
                   , aBasisQuantitySU          => aBasisQuantitySU
                   , aValueQuantity            => aValueQuantity
                   , aBalanceQty               => aBalanceQty
                   , aBalanceQtyValue          => aBalanceQtyValue
                   , aRecordID                 => aRecordID
                   , aRepresentativeID         => aRepresentativeID
                   , aForceStockLocation       => aForceStockLocation
                   , aStockID                  => aStockID
                   , aLocationID               => aLocationID
                   , aTraStockID               => aTraStockID
                   , aTraLocationID            => aTraLocationID
                   , aUnitCostPrice            => aUnitCostPrice
                   , aGoodPrice                => aGoodPrice
                   , aFalScheduleStepID        => aFalScheduleStepID
                   , aPcAppltxtID              => aPcAppltxtID
                   , aPosBodyText              => aPosBodyText
                   , aGenerateDetail           => aGenerateDetail
                   , aGenerateCPT              => aGenerateCPT
                   , aGenerateDiscountCharge   => aGenerateDiscountCharge
                   , aNomenclatureID           => aNomenclatureID
                   , aBasisDelay               => aBasisDelay
                   , aInterDelay               => aInterDelay
                   , aFinalDelay               => aFinalDelay
                   , aCharactValue_1           => aCharactValue_1
                   , aCharactValue_2           => aCharactValue_2
                   , aCharactValue_3           => aCharactValue_3
                   , aCharactValue_4           => aCharactValue_4
                   , aCharactValue_5           => aCharactValue_5
                   , aGaugeId                  => aGaugeId
                   , aLitigID                  => aLitigID
                   , aDebug                    => aDebug
                   , aTargetTable              => aTargetTable
                   , aUserInitProc             => aUserInitProc
                   , aManufacturedGoodID       => aManufacturedGoodID
                   , aGcoComplDataID           => aGcoComplDataID
                    );
  end GeneratePosition;

  /**
  *  procedure GeneratePosition
  *  Description
  *    Méthode générale pour la création d'une position
  */
  procedure GeneratePosition(
    aPositionID             in out DOC_POSITION.DOC_POSITION_ID%type
  , aErrorMsg               out    varchar2
  , aDocumentID             in     DOC_POSITION.DOC_DOCUMENT_ID%type
  , aPosCreateMode          in     varchar2 default null
  , aPosCreateType          in     varchar2 default null
  , aTypePos                in     DOC_POSITION.C_GAUGE_TYPE_POS%type default null
  , aGapID                  in     DOC_POSITION.DOC_GAUGE_POSITION_ID%type default null
  , aGoodID                 in     DOC_POSITION.GCO_GOOD_ID%type default null
  , aPTPositionID           in     DOC_POSITION.DOC_DOC_POSITION_ID%type default null
  , aSrcPositionID          in     DOC_POSITION.DOC_POSITION_ID%type default null
  , aTmpPosID               in     DOC_TMP_POSITION_DETAIL.DOC_POSITION_ID%type default null
  , aTmpPdeID               in     DOC_TMP_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , aInterfaceID            in     DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aInterfacePosID         in     DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type default null
  , aInterfacePosNbr        in     DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type default null
  , aBasisQuantity          in     DOC_POSITION.POS_BASIS_QUANTITY%type default null
  , aBasisQuantitySU        in     DOC_POSITION.POS_BASIS_QUANTITY_SU%type default null
  , aValueQuantity          in     DOC_POSITION.POS_VALUE_QUANTITY%type default null
  , aBalanceQty             in     DOC_POSITION.POS_BALANCE_QUANTITY%type default null
  , aBalanceQtyValue        in     DOC_POSITION.POS_BALANCE_QTY_VALUE%type default null
  , aRecordID               in     DOC_POSITION.DOC_RECORD_ID%type default null
  , aRepresentativeID       in     DOC_POSITION.PAC_REPRESENTATIVE_ID%type default null
  , aForceStockLocation     in     integer default 0
  , aStockID                in     DOC_POSITION.STM_STOCK_ID%type default null
  , aLocationID             in     DOC_POSITION.STM_LOCATION_ID%type default null
  , aTraStockID             in     DOC_POSITION.STM_STM_STOCK_ID%type default null
  , aTraLocationID          in     DOC_POSITION.STM_STM_LOCATION_ID%type default null
  , aUnitCostPrice          in     DOC_POSITION.POS_UNIT_COST_PRICE%type default null
  , aGoodPrice              in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type default null
  , aFalScheduleStepID      in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type default null
  , aPcAppltxtID            in     DOC_POSITION.PC_APPLTXT_ID%type default null
  , aPosBodyText            in     DOC_POSITION.POS_BODY_TEXT%type default null
  , aGenerateDetail         in     integer default 1
  , aGenerateCPT            in     integer default 0
  , aGenerateDiscountCharge in     integer default 1
  , aNomenclatureID         in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type default null
  , aBasisDelay             in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aInterDelay             in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aFinalDelay             in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aCharactValue_1         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type default null
  , aCharactValue_2         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2%type default null
  , aCharactValue_3         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3%type default null
  , aCharactValue_4         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4%type default null
  , aCharactValue_5         in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5%type default null
  , aGaugeId                in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  , aLitigID                in     DOC_LITIG.DOC_LITIG_ID%type default null
  , aDebug                  in     number default 1
  , aTargetTable            in     varchar2 default 'DOC_POSITION'
  , aUserInitProc           in     varchar2 default null
  , aManufacturedGoodID     in     DOC_POSITION.GCO_GOOD_ID%type default null
  , aGcoComplDataID         in     DOC_POSITION.GCO_COMPL_DATA_ID%type default null
  )
  is
    NewDetailID             DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    tmpGaugeType            DOC_GAUGE.C_GAUGE_TYPE%type;
    tmpAutoAttrib           DOC_GAUGE_STRUCTURED.GAS_AUTO_ATTRIBUTION%type;
    tmpWeightMat            DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    tmpIncludeBudgetControl DOC_GAUGE_STRUCTURED.GAS_INCLUDE_BUDGET_CONTROL%type;
    vCode                   number(3);
    tmpTypePos              number;
    vInfoCode               varchar2(30);
    vCount                  integer;
    vInputIdList            varchar2(2000);
  begin
    -- Réinitialise les données de la varibale globale contenant les infos pour la création de la position
    if DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO = 1 then
      ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);

      -- Si en copie ou décharge, effacer les données de la table DOC_POS_DET_COPY_DISCHARGE
      if     upper(aPosCreateType) in('COPY', 'DISCHARGE')
         and (aSrcPositionID is not null) then
        delete from V_DOC_POS_DET_COPY_DISCHARGE
              where NEW_DOCUMENT_ID = aDocumentID
                and DOC_POSITION_ID = nvl(DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID, aSrcPositionID);
      end if;
    end if;

    -- Récupérer le variables passées en param si on n'ont pas encore été
    -- initialisées avant l'appel de la procédure GeneratePosition
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID            := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID, aPositionID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID            := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID, aDocumentID);
    DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE          := nvl(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE, aPosCreateMode);
    DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE                := upper(nvl(DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE, aPosCreateType) );
    DOC_POSITION_INITIALIZE.PositionInfo.C_GAUGE_TYPE_POS           := nvl(DOC_POSITION_INITIALIZE.PositionInfo.C_GAUGE_TYPE_POS, aTypePos);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_POSITION_ID      := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_POSITION_ID, aGapID);
    DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID                := nvl(DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID, aGoodID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOC_POSITION_ID        := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOC_POSITION_ID, aPTPositionID);
    DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID     := nvl(DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID, aSrcPositionID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_TMP_POS_ID             := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_TMP_POS_ID, aTmpPosID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_TMP_PDE_ID             := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_TMP_PDE_ID, aTmpPdeID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_ID           := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_ID, aInterfaceID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_POSITION_ID  := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_POSITION_ID, aInterfacePosID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOP_POS_NUMBER             := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOP_POS_NUMBER, aInterfacePosNbr);
    DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY         := nvl(DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY, aBasisQuantity);
    DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY_SU      := nvl(DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY_SU, aBasisQuantitySU);
    DOC_POSITION_INITIALIZE.PositionInfo.POS_VALUE_QUANTITY         := nvl(DOC_POSITION_INITIALIZE.PositionInfo.POS_VALUE_QUANTITY, aValueQuantity);
    DOC_POSITION_INITIALIZE.PositionInfo.POS_BALANCE_QUANTITY       := nvl(DOC_POSITION_INITIALIZE.PositionInfo.POS_BALANCE_QUANTITY, aBalanceQty);
    DOC_POSITION_INITIALIZE.PositionInfo.POS_BALANCE_QTY_VALUE      := nvl(DOC_POSITION_INITIALIZE.PositionInfo.POS_BALANCE_QTY_VALUE, aBalanceQtyValue);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_RECORD_ID              := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_RECORD_ID, aRecordID);
    DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPRESENTATIVE_ID      := nvl(DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPRESENTATIVE_ID, aRepresentativeID);
    DOC_POSITION_INITIALIZE.PositionInfo.FORCE_STOCK_LOCATION       := nvl(DOC_POSITION_INITIALIZE.PositionInfo.FORCE_STOCK_LOCATION, aForceStockLocation);
    DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID               := nvl(DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID, aStockID);
    DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID            := nvl(DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID, aLocationID);
    DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID           := nvl(DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID, aTraStockID);
    DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID        := nvl(DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID, aTraLocationID);
    DOC_POSITION_INITIALIZE.PositionInfo.POS_UNIT_COST_PRICE        := nvl(DOC_POSITION_INITIALIZE.PositionInfo.POS_UNIT_COST_PRICE, aUnitCostPrice);
    DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE                 := nvl(DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE, aGoodPrice);
    DOC_POSITION_INITIALIZE.PositionInfo.FAL_SCHEDULE_STEP_ID       := nvl(DOC_POSITION_INITIALIZE.PositionInfo.FAL_SCHEDULE_STEP_ID, aFalScheduleStepID);
    DOC_POSITION_INITIALIZE.PositionInfo.PC_APPLTXT_ID              := nvl(DOC_POSITION_INITIALIZE.PositionInfo.PC_APPLTXT_ID, aPcAppltxtID);
    DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT              := nvl(DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT, aPosBodyText);
    DOC_POSITION_INITIALIZE.PositionInfo.PPS_NOMENCLATURE_ID        := nvl(DOC_POSITION_INITIALIZE.PositionInfo.PPS_NOMENCLATURE_ID, aNomenclatureID);
    DOC_POSITION_INITIALIZE.PositionInfo.DOC_LITIG_ID               := nvl(DOC_POSITION_INITIALIZE.PositionInfo.DOC_LITIG_ID, aLitigID);
    DOC_POSITION_INITIALIZE.PositionInfo.CREATE_DETAIL              := aGenerateDetail;
    DOC_POSITION_INITIALIZE.PositionInfo.CREATE_POS_CPT             := aGenerateCPT;
    DOC_POSITION_INITIALIZE.PositionInfo.CREATE_DISCOUNT_CHARGE     := aGenerateDiscountCharge;
    DOC_POSITION_INITIALIZE.PositionInfo.A_DEBUG                    := nvl(DOC_POSITION_INITIALIZE.PositionInfo.A_DEBUG, aDebug);
    DOC_POSITION_INITIALIZE.PositionInfo.USER_INIT_PROCEDURE        := nvl(DOC_POSITION_INITIALIZE.PositionInfo.USER_INIT_PROCEDURE, aUserInitProc);
    DOC_POSITION_INITIALIZE.PositionInfo.GCO_MANUFACTURED_GOOD_ID   := nvl(DOC_POSITION_INITIALIZE.PositionInfo.GCO_MANUFACTURED_GOOD_ID, aManufacturedGoodID);
    DOC_POSITION_INITIALIZE.PositionInfo.GCO_COMPL_DATA_ID          := nvl(DOC_POSITION_INITIALIZE.PositionInfo.GCO_COMPL_DATA_ID, aGcoComplDataID);

    -- Quantité
    if DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY  := 1;
    end if;

    -- Quantité valeur
    if DOC_POSITION_INITIALIZE.PositionInfo.POS_VALUE_QUANTITY is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_VALUE_QUANTITY  := 1;
    end if;

    -- Qté solde
    if DOC_POSITION_INITIALIZE.PositionInfo.POS_BALANCE_QUANTITY is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BALANCE_QUANTITY  := 1;
    end if;

    -- Qté solde valeur
    if DOC_POSITION_INITIALIZE.PositionInfo.POS_BALANCE_QTY_VALUE is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BALANCE_QTY_VALUE  := 1;
    end if;

    -- Dossier
    if DOC_POSITION_INITIALIZE.PositionInfo.DOC_RECORD_ID is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_RECORD_ID  := 1;
    end if;

    -- Représentant
    if DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPRESENTATIVE_ID is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
    end if;

    -- Stock et emplacement de stock
    if    (DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID is not null)
       or (DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID is not null) then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK  := 1;
    end if;

    -- Stock et emplacement de stock Transfert
    if    (DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID is not null)
       or (DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID is not null) then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK  := 1;
    end if;

    -- Prix de revient unitaire
    if DOC_POSITION_INITIALIZE.PositionInfo.POS_UNIT_COST_PRICE is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UNIT_COST_PRICE  := 1;
    end if;

    -- Prix position
    if DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE is not null then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE  := 1;
    end if;

    -- Texte de la position
    if    (DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT is not null)
       or (DOC_POSITION_INITIALIZE.PositionInfo.PC_APPLTXT_ID is not null) then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT  := 1;
    end if;

    -- Rechercher l'id du gabarit pour un éventuel appel d'une procédure indiv d'initialisation
    if aGaugeId is null then
      select DOC_GAUGE_ID
        into DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_ID
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentID;
    else
      DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_ID  := aGaugeId;
    end if;

    begin
      vCode  := to_number(nvl(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE, '0') );
    exception
      when others then
        vCode  := 0;
    end;

    -- Création -> codes 100 ... 199
    if vCode between 100 and 199 then
      DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE  := 'INSERT';
    -- Copie -> codes 200 ... 299
    elsif vCode between 200 and 299 then
      DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE  := 'COPY';
    -- Décharge -> codes 300 ... 399
    elsif vCode between 300 and 399 then
      DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE  := 'DISCHARGE';
    end if;

    -- Initialisation si besoin des données de la position
    if    (DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE is not null)
       or (DOC_POSITION_INITIALIZE.PositionInfo.USER_INIT_PROCEDURE is not null) then
      DOC_POSITION_INITIALIZE.CallInitProc;
    end if;

    -- Création de position
    if DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE = 'INSERT' then
      -- Arrêter l'execution de cette procédure si code d'erreur
      if DOC_POSITION_INITIALIZE.PositionInfo.A_ERROR = 1 then
        aErrorMsg  := DOC_POSITION_INITIALIZE.PositionInfo.A_ERROR_MESSAGE;

        if DOC_POSITION_INITIALIZE.PositionInfo.A_DEBUG = 1 then
          raise_application_error(-20000, DOC_POSITION_INITIALIZE.PositionInfo.A_ERROR_MESSAGE);
        else
          return;
        end if;
      end if;

      -- Contrôle et initialisation si besoin des données de la position
      DOC_POSITION_INITIALIZE.ControlInitPositionData;

      -- Arrêter l'execution de cette procédure si code d'erreur
      if DOC_POSITION_INITIALIZE.PositionInfo.A_ERROR = 1 then
        aErrorMsg  := DOC_POSITION_INITIALIZE.PositionInfo.A_ERROR_MESSAGE;

        --raise_application_error(-20000, 'pos_create  a_debug = ' || DOC_POSITION_INITIALIZE.PositionInfo.A_DEBUG);
        if DOC_POSITION_INITIALIZE.PositionInfo.A_DEBUG = 1 then
          raise_application_error(-20000, DOC_POSITION_INITIALIZE.PositionInfo.A_ERROR_MESSAGE);
        else
          return;
        end if;
      end if;

      -- Insertion de la position dans la table DOC_POSITION
      InsertPosition(DOC_POSITION_INITIALIZE.PositionInfo, aTargetTable);
      -- Récupere l'ID de la position
      aPositionID  := DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID;

      -- Création du détail de position
      if     DOC_POSITION_INITIALIZE.PositionInfo.CREATE_DETAIL = 1
         and aTargettable = 'DOC_POSITION' then
        NewDetailID  := null;
        DOC_DETAIL_GENERATE.GenerateDetail(aDetailID            => NewDetailID
                                         , aPositionID          => DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID
                                         , aPdeCreateMode       => DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE
                                         , aPdeCreateType       => DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE
                                         , aSrcPositionID       => DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID
                                         , aTmpPdeID            => DOC_POSITION_INITIALIZE.PositionInfo.DOC_TMP_PDE_ID
                                         , aQuantity            => DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY
                                         , aBasisDelay          => aBasisDelay
                                         , aInterDelay          => aInterDelay
                                         , aFinalDelay          => aFinalDelay
                                         , aLocationID          => aLocationID
                                         , aTraLocationID       => aTraLocationID
                                         , aCharactValue_1      => aCharactValue_1
                                         , aCharactValue_2      => aCharactValue_2
                                         , aCharactValue_3      => aCharactValue_3
                                         , aCharactValue_4      => aCharactValue_4
                                         , aCharactValue_5      => aCharactValue_5
                                         , aInterfaceID         => aInterfaceID
                                         , aInterfacePosID      => aInterfacePosID
                                         , aInterfacePosNbr     => aInterfacePosNbr
                                         , aFalScheduleStepID   => aFalScheduleStepID
                                         , aLitigID             => aLitigID
                                          );
        -- Màj du flag de rupture de stock
        DOC_FUNCTIONS.FlagPositionManco(aPositionID, null);
      end if;

      -- Type de position que l'on vient de créér
      tmpTypePos   := to_number(DOC_POSITION_INITIALIZE.PositionInfo.C_GAUGE_TYPE_POS);

      -- Attributions....
      -- Recherche les infos au niveau du gabarit pour les attributions auto.
      select GAU.C_GAUGE_TYPE
           , GAS.GAS_AUTO_ATTRIBUTION
           , GAS.GAS_WEIGHT_MAT
           , GAS_INCLUDE_BUDGET_CONTROL
        into tmpGaugeType
           , tmpAutoAttrib
           , tmpWeightMat
           , tmpIncludeBudgetControl
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

      -- Traitement des poids matières précieuses
      if (tmpWeightMat = 1) then
        DOC_POSITION_ALLOY_FUNCTIONS.GeneratePositionMat(DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID);
      end if;

      -- Mise à jour du prix unitaire en monnaie de base de l'opération selon le prix unitaire de la position
      FAL_SUIVI_OPERATION.UpdateOperationAmount(iDocPositionId => DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID);

      -- teste si les conditions sont remplies pour créer automatiquement les attributions
      if     tmpGaugeType = '1'
         and tmpAutoAttrib = 1
         and DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY > 0 then
        -- création des attributions pour la positions créée
        FAL_REDO_ATTRIBS.ReDoAttribsByDocOrPOS(null, aPositionID);
      end if;

      -- Création des positions composants (71,81,91,101)
      if     (DOC_POSITION_INITIALIZE.PositionInfo.CREATE_POS_CPT = 1)
         and (to_number(DOC_POSITION_INITIALIZE.PositionInfo.C_GAUGE_TYPE_POS) in(7, 8, 9, 10) )
         and (DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE = 'INSERT')
         and (DOC_POSITION_INITIALIZE.PositionInfo.PPS_NOMENCLATURE_ID is not null) then
        declare
          tmpPosInfo DOC_POSITION_INITIALIZE.TPositionInfo;
        begin
          tmpPosInfo  := DOC_POSITION_INITIALIZE.PositionInfo;
          GenerateCptPositions(tmpPosInfo);
          -- Màj des montants/poids de la position PT
          DOC_POSITION_FUNCTIONS.UpdatePositionPTAmounts(aPositionID);
        end;
      end if;

      -- Création des remises et taxes de position
      if DOC_POSITION_INITIALIZE.PositionInfo.Simulation = 0 then
        if     (DOC_POSITION_INITIALIZE.PositionInfo.CREATE_DISCOUNT_CHARGE = 1)
           and (tmpTypePos in(1, 2, 3, 7, 8, 91, 10, 21) ) then
          DOC_POSITION_FUNCTIONS.UpdateChargeAndAmount(aPositionID);
        else
          -- Màj des flags pour pas que l'on crée des remises/taxes
          -- Ceci à cause du trigger insert/update DOC_POS_BIUD_UPDATE_FLAGS
          update DOC_POSITION
             set POS_CREATE_POSITION_CHARGE = 0
               , POS_UPDATE_POSITION_CHARGE = 0
               , POS_RECALC_AMOUNTS = 0
           where DOC_POSITION_ID = aPositionID;
        end if;
      end if;

      -- Mise à jour des montants de budget si cela n'a pas déjà été fait
      if     DOC_POSITION_INITIALIZE.PositionInfo.Simulation = 0
         and (PCS.PC_CONFIG.GetConfig('DOC_ENABLE_BUDGET') = '1')
         and (DOC_POSITION_INITIALIZE.PositionInfo.USE_BUDGET_AMOUNTS = 0)
         and (tmpIncludeBudgetControl = 1) then
        DOC_BUDGET_FUNCTIONS.UpdatePosBudgetAmounts(aPositionID);
      end if;
    -- Copie de position
    elsif DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE = 'COPY' then
      -- Vérifier si on fait l'insertion dans DOC_POS_DET_COPY_DISCHARGE
      -- dans la procédure d'initialisation
      select count(*)
        into vCount
        from V_DOC_POS_DET_COPY_DISCHARGE
       where NEW_DOCUMENT_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
         and DOC_POSITION_ID = DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID;

      -- Si pas de données dans DOC_POS_DET_COPY_DISCHARGE, effectuer l'insert standard
      if vCount = 0 then
        DOC_POSITION_INITIALIZE.InsertCopyPosDetail(aTgtDocumentID   => DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
                                                  , aSrcPositionID   => DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID
                                                   );
      end if;

      -- Màj la variable de package contenant le dernier n° de position utilisé pour ce document
      DOC_COPY_DISCHARGE.SETLASTDOCPOSNUMBER(DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID);
      -- Copie de la position
      DOC_COPY_DISCHARGE.CopyPosition(aSourcePositionId      => DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID
                                    , aTargetDocumentId      => DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
                                    , aPdtSourcePositionId   => null
                                    , aPdtTargetPositionId   => null
                                    , aFlowId                => null
                                    , aInputIdList           => vInputIdList
                                    , aTargetPositionId      => DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID
                                    , aCopyInfoCode          => vInfoCode
                                     );

      -- Effacer les données liées à la position copiée
      delete from V_DOC_POS_DET_COPY_DISCHARGE
            where NEW_DOCUMENT_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
              and DOC_POSITION_ID = DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID;

      -- Récupere l'ID de la position
      aPositionID  := DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID;
    elsif DOC_POSITION_INITIALIZE.PositionInfo.CREATE_TYPE = 'DISCHARGE' then
      -- Vérifier si on fait l'insertion dans DOC_POS_DET_COPY_DISCHARGE
      -- dans la procédure d'initialisation
      select count(*)
        into vCount
        from V_DOC_POS_DET_COPY_DISCHARGE
       where NEW_DOCUMENT_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
         and DOC_POSITION_ID = DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID;

      -- Si pas de données dans DOC_POS_DET_COPY_DISCHARGE, effectuer l'insert standard
      if vCount = 0 then
        DOC_POSITION_INITIALIZE.InsertDischargePosDetail(aTgtDocumentID   => DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
                                                       , aSrcPositionID   => DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID
                                                        );
      end if;

      -- Màj la variable de package contenant le dernier n° de position utilisé pour ce document
      DOC_COPY_DISCHARGE.SETLASTDOCPOSNUMBER(DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID);
      -- Décharge de la position
      DOC_COPY_DISCHARGE.DischargePosition(aSourcePositionId      => DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID
                                         , aTargetDocumentId      => DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
                                         , aPdtSourcePositionId   => null
                                         , aPdtTargetPositionId   => null
                                         , aFlowId                => null
                                         , aInputIdList           => vInputIdList
                                         , aTargetPositionId      => DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID
                                         , aDischargeInfoCode     => vInfoCode
                                          );

      -- Effacer les données liées à la position déchargée
      delete from V_DOC_POS_DET_COPY_DISCHARGE
            where NEW_DOCUMENT_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID
              and DOC_POSITION_ID = DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID;

      -- Récupere l'ID de la position
      aPositionID  := DOC_POSITION_INITIALIZE.PositionInfo.DOC_POSITION_ID;
    end if;

    -- Effacer le record des informations de la position
    ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
  exception
    when others then
      -- Effacer le record des informations de la position
      ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
      PCS.RA(sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  end GeneratePosition;

  /**
  *  procedure GenerateCptPositions
  *  Description
  *    Création des positions composants
  */
  procedure GenerateCptPositions(aPT_PositionInfo in DOC_POSITION_INITIALIZE.TPositionInfo, aTargetTable in varchar2 default 'DOC_POSITION')
  is
    -- Curseur sur les composants de la nomenclature
    cursor crComponents(cNomenclatureID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    is
      select   COM_SEQ
             , COM_UTIL_COEFF
             , GCO_GOOD_ID
             , STM_LOCATION_ID
             , C_KIND_COM
             , PPS_PPS_NOMENCLATURE_ID
             , PPS_NOM_BOND_ID
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = cNomenclatureID
           and C_TYPE_COM = '1'
      order by COM_SEQ;

    tplComponents      crComponents%rowtype;
    NewPosCpt_ID       DOC_POSITION.DOC_POSITION_ID%type;
    tmpNomenclatureID  PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    tmpCptGAP_ID       DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type;
    tmpCptGaugeTypePos DOC_POSITION.C_GAUGE_TYPE_POS%type;
  begin
    -- Rechercher le gabarit lié à la position PT
    select DOC_DOC_GAUGE_POSITION_ID
      into tmpCptGAP_ID
      from DOC_GAUGE_POSITION
     where DOC_GAUGE_POSITION_ID = aPT_PositionInfo.DOC_GAUGE_POSITION_ID;

    -- La position 7,8,9 ou 10 n'a pas de gabarit position lié
    if tmpCptGAP_ID is null then
      -- Il faut créer les cpt avec le type de position 71,81,91 ou 101
      tmpCptGaugeTypePos  := aPT_PositionInfo.C_GAUGE_TYPE_POS || '1';
    else
      -- Gabarit 7,8,9 ou 10 possède un gabarit position lié
      tmpCptGaugeTypePos  := '';
    end if;

    open crComponents(aPT_PositionInfo.PPS_NOMENCLATURE_ID);

    fetch crComponents
     into tplComponents;

    while crComponents%found loop
      NewPosCpt_ID  := null;

      -- Composant de type "Composant"
      if tplComponents.C_KIND_COM = '1' then
        -- Effacer le record des informations de la position
        ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
        -- Ne pas effacer les données pré-initialisées
        DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO   := 0;
        -- Coefficient d'utilisation du composant
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF    := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF        := tplComponents.COM_UTIL_COEFF;
        -- Type de position de la position CPT
        DOC_POSITION_INITIALIZE.PositionInfo.C_GAUGE_TYPE_POS_CPT  := aPT_PositionInfo.C_GAUGE_TYPE_POS || '1';
        -- Génération de la position Composant
        GeneratePosition(aPositionID               => NewPosCpt_ID
                       , aDocumentID               => aPT_PositionInfo.DOC_DOCUMENT_ID
                       , aPosCreateMode            => aPT_PositionInfo.C_POS_CREATE_MODE
                       , aPosCreateType            => aPT_PositionInfo.CREATE_TYPE
                       , aTypePos                  => tmpCptGaugeTypePos
                       , aGapID                    => tmpCptGAP_ID
                       , aGoodID                   => tplComponents.GCO_GOOD_ID
                       , aPTPositionID             => aPT_PositionInfo.DOC_POSITION_ID
                       , aBasisQuantity            => aPT_PositionInfo.POS_BASIS_QUANTITY
                       , aValueQuantity            => aPT_PositionInfo.POS_VALUE_QUANTITY
                       , aRecordID                 => aPT_PositionInfo.DOC_RECORD_ID
                       , aRepresentativeID         => aPT_PositionInfo.PAC_REPRESENTATIVE_ID
                       , aGenerateDetail           => 1
                       , aGenerateDiscountCharge   => aPT_PositionInfo.CREATE_DISCOUNT_CHARGE
                       , aFalScheduleStepID        => aPT_PositionInfo.FAL_SCHEDULE_STEP_ID
                       , aTargetTable              => aTargetTable
                        );
      -- Composant de type "Pseudo"
      elsif tplComponents.C_KIND_COM = '3' then
        -- Rechercher les composants de la nomenclature du composant courant

        -- Utiliser la nomenclature définie dans le composant en cours
        if tplComponents.PPS_PPS_NOMENCLATURE_ID is not null then
          tmpNomenclatureID  := tplComponents.PPS_PPS_NOMENCLATURE_ID;
        else
          -- Recherche la nomenclature à utiliser en fonction de la configuration DOC_INITIAL_NOM_VERSION
          tmpNomenclatureID  := DOC_POSITION_FUNCTIONS.GetInitialNomenclature(tplComponents.GCO_GOOD_ID);
        end if;

        -- Génerer les CPT si le composant en cours possède une nomenclature
        if tmpNomenclatureID is not null then
          declare
            tmpPT_PosInfo DOC_POSITION_INITIALIZE.TPositionInfo;
          begin
            tmpPT_PosInfo                      := aPT_PositionInfo;
            tmpPT_PosInfo.PPS_NOMENCLATURE_ID  := tmpNomenclatureID;
            GenerateCptPositions(tmpPT_PosInfo);
          end;
        end if;
      end if;

      -- Composant suivant
      fetch crComponents
       into tplComponents;
    end loop;

    close crComponents;
  end GenerateCptPositions;

  /**
  *  procedure CopyCptPositions
  *  Description
  *    Copie des positions composants
  */
  procedure CopyCptPositions(aPT_PositionInfo in DOC_POSITION_INITIALIZE.TPositionInfo, aTargetTable in varchar2 default 'DOC_POSITION')
  is
    NewPosCpt_ID DOC_POSITION.DOC_POSITION_ID%type;
  begin
    for tplPosCpt in (select   DOC_POSITION_ID
                          from DOC_POSITION
                         where DOC_DOC_POSITION_ID = aPT_PositionInfo.SOURCE_DOC_POSITION_ID
                      order by POS_NUMBER) loop
      NewPosCpt_ID  := null;
      -- copie position
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID               => NewPosCpt_ID
                                           , aDocumentID               => aPT_PositionInfo.DOC_DOCUMENT_ID
                                           , aPosCreateMode            => aPT_PositionInfo.C_POS_CREATE_MODE
                                           , aPosCreateType            => aPT_PositionInfo.CREATE_TYPE
                                           , aPTPositionID             => aPT_PositionInfo.DOC_POSITION_ID
                                           , aSrcPositionID            => tplPosCpt.DOC_POSITION_ID
                                           , aGenerateDetail           => 1
                                           , aGenerateDiscountCharge   => aPT_PositionInfo.CREATE_DISCOUNT_CHARGE
                                           , aFalScheduleStepID        => aPT_PositionInfo.FAL_SCHEDULE_STEP_ID
                                           , aTargetTable              => aTargetTable
                                            );
    end loop;
  end CopyCptPositions;

  /**
  *  procedure InsertPosition
  *  Description
  *    Insertion dans la table DOC_POSITION des données du record en param
  */
  procedure InsertPosition(aPositionInfo in out DOC_POSITION_INITIALIZE.TPositionInfo, aTargetTable in varchar2 default 'DOC_POSITION')
  is
  begin
    if aTargetTable = 'DOC_POSITION' then
--      ra(aPositionInfo.POS_EFFECTIVE_DIC_TARIFF_ID||'/'||aPositionInfo.DIC_TARIFF_ID,'FPEROTTO');
      insert into DOC_POSITION
                  (DOC_POSITION_ID
                 , DOC_DOCUMENT_ID
                 , DOC_GAUGE_POSITION_ID
                 , C_GAUGE_TYPE_POS
                 , C_DOC_POS_STATUS
                 , GCO_GOOD_ID
                 , PAC_THIRD_ID
                 , PAC_THIRD_ACI_ID
                 , PAC_THIRD_DELIVERY_ID
                 , PAC_THIRD_TARIFF_ID
                 , DOC_GAUGE_ID
                 , POS_NUMBER
                 , STM_MOVEMENT_KIND_ID
                 , DOC_DOC_POSITION_ID
                 , POS_INCLUDE_TAX_TARIFF
                 , POS_TRANSFERT_PROPRIETOR
                 , A_DATECRE
                 , A_IDCRE
                 , DIC_DIC_UNIT_OF_MEASURE_ID
                 , DOC_RECORD_ID
                 , DOC_DOC_RECORD_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , STM_STM_STOCK_ID
                 , STM_STM_LOCATION_ID
                 , ACS_TAX_CODE_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , HRM_PERSON_ID
                 , FAM_FIXED_ASSETS_ID
                 , C_FAM_TRANSACTION_TYP
                 , POS_IMF_TEXT_1
                 , POS_IMF_TEXT_2
                 , POS_IMF_TEXT_3
                 , POS_IMF_TEXT_4
                 , POS_IMF_TEXT_5
                 , POS_IMF_NUMBER_2
                 , POS_IMF_NUMBER_3
                 , POS_IMF_NUMBER_4
                 , POS_IMF_NUMBER_5
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , POS_REFERENCE
                 , POS_SECONDARY_REFERENCE
                 , POS_SHORT_DESCRIPTION
                 , POS_LONG_DESCRIPTION
                 , POS_FREE_DESCRIPTION
                 , POS_EAN_CODE
                 , POS_EAN_UCC14_CODE
                 , POS_HIBC_PRIMARY_CODE
                 , POS_BODY_TEXT
                 , PC_APPLTXT_ID
                 , DIC_UNIT_OF_MEASURE_ID
                 , A_DATEMOD
                 , A_IDMOD
                 , A_RECLEVEL
                 , A_RECSTATUS
                 , A_CONFIRM
                 , POS_NOM_TEXT
                 , DIC_POS_FREE_TABLE_1_ID
                 , DIC_POS_FREE_TABLE_2_ID
                 , DIC_POS_FREE_TABLE_3_ID
                 , POS_DECIMAL_1
                 , POS_DECIMAL_2
                 , POS_DECIMAL_3
                 , POS_TEXT_1
                 , POS_TEXT_2
                 , POS_TEXT_3
                 , POS_DATE_1
                 , POS_DATE_2
                 , POS_DATE_3
                 , PAC_REPRESENTATIVE_ID
                 , PAC_REPR_ACI_ID
                 , PAC_REPR_DELIVERY_ID
                 , CML_POSITION_ID
                 , CML_EVENTS_ID
                 , ASA_RECORD_ID
                 , ASA_RECORD_COMP_ID
                 , ASA_RECORD_TASK_ID
                 , FAL_SUPPLY_REQUEST_ID
                 , PAC_PERSON_ID
                 , C_POS_DELIVERY_TYP
                 , POS_RATE_FACTOR
                 , POS_NET_TARIFF
                 , POS_SPECIAL_TARIFF
                 , POS_FLAT_RATE
                 , POS_TARIFF_UNIT
                 , POS_TARIFF_SET
                 , POS_DISCOUNT_RATE
                 , POS_DISCOUNT_UNIT_VALUE
                 , POS_NET_WEIGHT
                 , POS_GROSS_WEIGHT
                 , POS_UTIL_COEFF
                 , POS_CONVERT_FACTOR
                 , POS_CONVERT_FACTOR2
                 , POS_PARTNER_NUMBER
                 , POS_PARTNER_REFERENCE
                 , POS_DATE_PARTNER_DOCUMENT
                 , POS_PARTNER_POS_NUMBER
                 , POS_EFFECTIVE_DIC_TARIFF_ID
                 , DIC_TARIFF_ID
                 , POS_TARIFF_DATE
                 , POS_BALANCE_QUANTITY
                 , POS_VALUE_QUANTITY
                 , POS_BALANCE_QTY_VALUE
                 , DOC_EXTRACT_COMMISSION_ID
                 , POS_BASIS_QUANTITY
                 , POS_INTERMEDIATE_QUANTITY
                 , POS_FINAL_QUANTITY
                 , POS_BASIS_QUANTITY_SU
                 , POS_INTERMEDIATE_QUANTITY_SU
                 , POS_FINAL_QUANTITY_SU
                 , POS_TARIFF_INITIALIZED
                 , POS_UNIT_COST_PRICE
                 , POS_GROSS_UNIT_VALUE
                 , POS_GROSS_UNIT_VALUE_INCL
                 , POS_GROSS_UNIT_VALUE2
                 , POS_REF_UNIT_VALUE
                 , POS_DISCOUNT_AMOUNT
                 , POS_CHARGE_AMOUNT
                 , POS_VAT_AMOUNT
                 , POS_NET_UNIT_VALUE
                 , POS_NET_UNIT_VALUE_INCL
                 , POS_GROSS_VALUE
                 , POS_GROSS_VALUE_INCL
                 , POS_NET_VALUE_EXCL
                 , POS_NET_VALUE_INCL
                 , POS_CALC_BUDGET_AMOUNT_MB
                 , POS_EFFECT_BUDGET_AMOUNT_MB
                 , C_POS_CREATE_MODE
                 , POS_CREATE_POSITION_CHARGE
                 , POS_UPDATE_POSITION_CHARGE
                 , POS_RECALC_AMOUNTS
                 , ASA_INTERVENTION_DETAIL_ID
                 , DOC_INVOICE_EXPIRY_ID
                 , DOC_INVOICE_EXPIRY_DETAIL_ID
                 , PAC_THIRD_CDA_ID
                 , PAC_THIRD_VAT_ID
                 , POS_ADDENDUM_SRC_POS_ID
                 , POS_ADDENDUM_QTY_BALANCED
                 , POS_ADDENDUM_VALUE_QTY
                 , FAL_LOT_ID
                 , GCO_MANUFACTURED_GOOD_ID
                 , C_DOC_LOT_TYPE
                 , GCO_COMPL_DATA_ID
                  )
        select aPositionInfo.DOC_POSITION_ID
             , aPositionInfo.DOC_DOCUMENT_ID
             , aPositionInfo.DOC_GAUGE_POSITION_ID
             , aPositionInfo.C_GAUGE_TYPE_POS
             , aPositionInfo.C_DOC_POS_STATUS
             , aPositionInfo.GCO_GOOD_ID
             , aPositionInfo.PAC_THIRD_ID
             , aPositionInfo.PAC_THIRD_ACI_ID
             , aPositionInfo.PAC_THIRD_DELIVERY_ID
             , aPositionInfo.PAC_THIRD_TARIFF_ID
             , aPositionInfo.DOC_GAUGE_ID
             , aPositionInfo.POS_NUMBER
             , aPositionInfo.STM_MOVEMENT_KIND_ID
             , aPositionInfo.DOC_DOC_POSITION_ID
             , aPositionInfo.POS_INCLUDE_TAX_TARIFF
             , aPositionInfo.POS_TRANSFERT_PROPRIETOR
             , aPositionInfo.A_DATECRE
             , aPositionInfo.A_IDCRE
             , aPositionInfo.DIC_DIC_UNIT_OF_MEASURE_ID
             , aPositionInfo.DOC_RECORD_ID
             , aPositionInfo.DOC_DOC_RECORD_ID
             , aPositionInfo.STM_STOCK_ID
             , aPositionInfo.STM_LOCATION_ID
             , aPositionInfo.STM_STM_STOCK_ID
             , aPositionInfo.STM_STM_LOCATION_ID
             , aPositionInfo.ACS_TAX_CODE_ID
             , aPositionInfo.ACS_FINANCIAL_ACCOUNT_ID
             , aPositionInfo.ACS_DIVISION_ACCOUNT_ID
             , aPositionInfo.ACS_CPN_ACCOUNT_ID
             , aPositionInfo.ACS_PF_ACCOUNT_ID
             , aPositionInfo.ACS_PJ_ACCOUNT_ID
             , aPositionInfo.ACS_CDA_ACCOUNT_ID
             , aPositionInfo.HRM_PERSON_ID
             , aPositionInfo.FAM_FIXED_ASSETS_ID
             , aPositionInfo.C_FAM_TRANSACTION_TYP
             , aPositionInfo.POS_IMF_TEXT_1
             , aPositionInfo.POS_IMF_TEXT_2
             , aPositionInfo.POS_IMF_TEXT_3
             , aPositionInfo.POS_IMF_TEXT_4
             , aPositionInfo.POS_IMF_TEXT_5
             , aPositionInfo.POS_IMF_NUMBER_2
             , aPositionInfo.POS_IMF_NUMBER_3
             , aPositionInfo.POS_IMF_NUMBER_4
             , aPositionInfo.POS_IMF_NUMBER_5
             , aPositionInfo.DIC_IMP_FREE1_ID
             , aPositionInfo.DIC_IMP_FREE2_ID
             , aPositionInfo.DIC_IMP_FREE3_ID
             , aPositionInfo.DIC_IMP_FREE4_ID
             , aPositionInfo.DIC_IMP_FREE5_ID
             , aPositionInfo.POS_REFERENCE
             , aPositionInfo.POS_SECONDARY_REFERENCE
             , aPositionInfo.POS_SHORT_DESCRIPTION
             , aPositionInfo.POS_LONG_DESCRIPTION
             , aPositionInfo.POS_FREE_DESCRIPTION
             , aPositionInfo.POS_EAN_CODE
             , aPositionInfo.POS_EAN_UCC14_CODE
             , aPositionInfo.POS_HIBC_PRIMARY_CODE
             , aPositionInfo.POS_BODY_TEXT
             , aPositionInfo.PC_APPLTXT_ID
             , aPositionInfo.DIC_UNIT_OF_MEASURE_ID
             , aPositionInfo.A_DATEMOD
             , aPositionInfo.A_IDMOD
             , aPositionInfo.A_RECLEVEL
             , aPositionInfo.A_RECSTATUS
             , aPositionInfo.A_CONFIRM
             , aPositionInfo.POS_NOM_TEXT
             , aPositionInfo.DIC_POS_FREE_TABLE_1_ID
             , aPositionInfo.DIC_POS_FREE_TABLE_2_ID
             , aPositionInfo.DIC_POS_FREE_TABLE_3_ID
             , aPositionInfo.POS_DECIMAL_1
             , aPositionInfo.POS_DECIMAL_2
             , aPositionInfo.POS_DECIMAL_3
             , aPositionInfo.POS_TEXT_1
             , aPositionInfo.POS_TEXT_2
             , aPositionInfo.POS_TEXT_3
             , aPositionInfo.POS_DATE_1
             , aPositionInfo.POS_DATE_2
             , aPositionInfo.POS_DATE_3
             , aPositionInfo.PAC_REPRESENTATIVE_ID
             , aPositionInfo.PAC_REPR_ACI_ID
             , aPositionInfo.PAC_REPR_DELIVERY_ID
             , aPositionInfo.CML_POSITION_ID
             , aPositionInfo.CML_EVENTS_ID
             , aPositionInfo.ASA_RECORD_ID
             , aPositionInfo.ASA_RECORD_COMP_ID
             , aPositionInfo.ASA_RECORD_TASK_ID
             , aPositionInfo.FAL_SUPPLY_REQUEST_ID
             , aPositionInfo.PAC_PERSON_ID
             , aPositionInfo.C_POS_DELIVERY_TYP
             , aPositionInfo.POS_RATE_FACTOR
             , nvl(aPositionInfo.POS_NET_TARIFF, 0)
             , nvl(aPositionInfo.POS_SPECIAL_TARIFF, 0)
             , nvl(aPositionInfo.POS_FLAT_RATE, 0)
             , aPositionInfo.POS_TARIFF_UNIT
             , aPositionInfo.POS_TARIFF_SET
             , aPositionInfo.POS_DISCOUNT_RATE
             , aPositionInfo.POS_DISCOUNT_UNIT_VALUE
             , aPositionInfo.POS_NET_WEIGHT
             , aPositionInfo.POS_GROSS_WEIGHT
             , aPositionInfo.POS_UTIL_COEFF
             , aPositionInfo.POS_CONVERT_FACTOR
             , aPositionInfo.POS_CONVERT_FACTOR2
             , aPositionInfo.POS_PARTNER_NUMBER
             , aPositionInfo.POS_PARTNER_REFERENCE
             , aPositionInfo.POS_DATE_PARTNER_DOCUMENT
             , aPositionInfo.POS_PARTNER_POS_NUMBER
             , aPositionInfo.POS_EFFECTIVE_DIC_TARIFF_ID
             , aPositionInfo.DIC_TARIFF_ID
             , aPositionInfo.POS_TARIFF_DATE
             , aPositionInfo.POS_BALANCE_QUANTITY
             , aPositionInfo.POS_VALUE_QUANTITY
             , aPositionInfo.POS_BALANCE_QTY_VALUE
             , aPositionInfo.DOC_EXTRACT_COMMISSION_ID
             , aPositionInfo.POS_BASIS_QUANTITY
             , aPositionInfo.POS_INTERMEDIATE_QUANTITY
             , aPositionInfo.POS_FINAL_QUANTITY
             , aPositionInfo.POS_BASIS_QUANTITY_SU
             , aPositionInfo.POS_INTERMEDIATE_QUANTITY_SU
             , aPositionInfo.POS_FINAL_QUANTITY_SU
             , aPositionInfo.POS_TARIFF_INITIALIZED
             , aPositionInfo.POS_UNIT_COST_PRICE
             , aPositionInfo.POS_GROSS_UNIT_VALUE
             , aPositionInfo.POS_GROSS_UNIT_VALUE_INCL
             , aPositionInfo.POS_GROSS_UNIT_VALUE2
             , aPositionInfo.POS_REF_UNIT_VALUE
             , aPositionInfo.POS_DISCOUNT_AMOUNT
             , aPositionInfo.POS_CHARGE_AMOUNT
             , aPositionInfo.POS_VAT_AMOUNT
             , aPositionInfo.POS_NET_UNIT_VALUE
             , aPositionInfo.POS_NET_UNIT_VALUE_INCL
             , aPositionInfo.POS_GROSS_VALUE
             , aPositionInfo.POS_GROSS_VALUE_INCL
             , aPositionInfo.POS_NET_VALUE_EXCL
             , aPositionInfo.POS_NET_VALUE_INCL
             , aPositionInfo.POS_CALC_BUDGET_AMOUNT_MB
             , aPositionInfo.POS_EFFECT_BUDGET_AMOUNT_MB
             , nvl(aPositionInfo.C_POS_CREATE_MODE, '999')
             , 0
             , 0
             , 0
             , aPositionInfo.ASA_INTERVENTION_DETAIL_ID
             , aPositionInfo.DOC_INVOICE_EXPIRY_ID
             , aPositionInfo.DOC_INVOICE_EXPIRY_DETAIL_ID
             , aPositionInfo.PAC_THIRD_CDA_ID
             , aPositionInfo.PAC_THIRD_VAT_ID
             , aPositionInfo.POS_ADDENDUM_SRC_POS_ID
             , aPositionInfo.POS_ADDENDUM_QTY_BALANCED
             , aPositionInfo.POS_ADDENDUM_VALUE_QTY
             , aPositionInfo.FAL_LOT_ID
             , aPositionInfo.GCO_MANUFACTURED_GOOD_ID
             , aPositionInfo.C_DOC_LOT_TYPE
             , aPositionInfo.GCO_COMPL_DATA_ID
          from dual;
    elsif aTargetTable = 'DOC_ESTIMATED_POS_CASH_FLOW' then
      insert into DOC_ESTIMATED_POS_CASH_FLOW
                  (DOC_POSITION_ID
                 , DOC_DOCUMENT_ID
                 , DOC_GAUGE_POSITION_ID
                 , C_GAUGE_TYPE_POS
                 , C_DOC_POS_STATUS
                 , GCO_GOOD_ID
                 , PAC_THIRD_ID
                 , PAC_THIRD_ACI_ID
                 , PAC_THIRD_DELIVERY_ID
                 , PAC_THIRD_TARIFF_ID
                 , DOC_GAUGE_ID
                 , POS_NUMBER
                 , STM_MOVEMENT_KIND_ID
                 , DOC_DOC_POSITION_ID
                 , POS_INCLUDE_TAX_TARIFF
                 , POS_TRANSFERT_PROPRIETOR
                 , A_DATECRE
                 , A_IDCRE
                 , DIC_DIC_UNIT_OF_MEASURE_ID
                 , DOC_RECORD_ID
                 , DOC_DOC_RECORD_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , STM_STM_STOCK_ID
                 , STM_STM_LOCATION_ID
                 , ACS_TAX_CODE_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , HRM_PERSON_ID
                 , FAM_FIXED_ASSETS_ID
                 , C_FAM_TRANSACTION_TYP
                 , POS_IMF_TEXT_1
                 , POS_IMF_TEXT_2
                 , POS_IMF_TEXT_3
                 , POS_IMF_TEXT_4
                 , POS_IMF_TEXT_5
                 , POS_IMF_NUMBER_2
                 , POS_IMF_NUMBER_3
                 , POS_IMF_NUMBER_4
                 , POS_IMF_NUMBER_5
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , POS_REFERENCE
                 , POS_SECONDARY_REFERENCE
                 , POS_SHORT_DESCRIPTION
                 , POS_LONG_DESCRIPTION
                 , POS_FREE_DESCRIPTION
                 , POS_EAN_CODE
                 , POS_EAN_UCC14_CODE
                 , POS_HIBC_PRIMARY_CODE
                 , POS_BODY_TEXT
                 , PC_APPLTXT_ID
                 , DIC_UNIT_OF_MEASURE_ID
                 , A_DATEMOD
                 , A_IDMOD
                 , A_RECLEVEL
                 , A_RECSTATUS
                 , A_CONFIRM
                 , POS_NOM_TEXT
                 , DIC_POS_FREE_TABLE_1_ID
                 , DIC_POS_FREE_TABLE_2_ID
                 , DIC_POS_FREE_TABLE_3_ID
                 , POS_DECIMAL_1
                 , POS_DECIMAL_2
                 , POS_DECIMAL_3
                 , POS_TEXT_1
                 , POS_TEXT_2
                 , POS_TEXT_3
                 , POS_DATE_1
                 , POS_DATE_2
                 , POS_DATE_3
                 , PAC_REPRESENTATIVE_ID
                 , PAC_REPR_ACI_ID
                 , PAC_REPR_DELIVERY_ID
                 , CML_POSITION_ID
                 , CML_EVENTS_ID
                 , ASA_RECORD_ID
                 , ASA_RECORD_COMP_ID
                 , ASA_RECORD_TASK_ID
                 , FAL_SUPPLY_REQUEST_ID
                 , PAC_PERSON_ID
                 , C_POS_DELIVERY_TYP
                 , POS_RATE_FACTOR
                 , POS_NET_TARIFF
                 , POS_SPECIAL_TARIFF
                 , POS_FLAT_RATE
                 , POS_TARIFF_UNIT
                 , POS_TARIFF_SET
                 , POS_DISCOUNT_RATE
                 , POS_DISCOUNT_UNIT_VALUE
                 , POS_NET_WEIGHT
                 , POS_GROSS_WEIGHT
                 , POS_UTIL_COEFF
                 , POS_CONVERT_FACTOR
                 , POS_CONVERT_FACTOR2
                 , POS_PARTNER_NUMBER
                 , POS_PARTNER_REFERENCE
                 , POS_DATE_PARTNER_DOCUMENT
                 , POS_PARTNER_POS_NUMBER
                 , DIC_TARIFF_ID
                 , POS_TARIFF_DATE
                 , POS_BALANCE_QUANTITY
                 , POS_VALUE_QUANTITY
                 , POS_BALANCE_QTY_VALUE
                 , DOC_EXTRACT_COMMISSION_ID
                 , POS_BASIS_QUANTITY
                 , POS_INTERMEDIATE_QUANTITY
                 , POS_FINAL_QUANTITY
                 , POS_BASIS_QUANTITY_SU
                 , POS_INTERMEDIATE_QUANTITY_SU
                 , POS_FINAL_QUANTITY_SU
                 , POS_TARIFF_INITIALIZED
                 , POS_UNIT_COST_PRICE
                 , POS_GROSS_UNIT_VALUE
                 , POS_GROSS_UNIT_VALUE_INCL
                 , POS_GROSS_UNIT_VALUE2
                 , POS_REF_UNIT_VALUE
                 , POS_DISCOUNT_AMOUNT
                 , POS_CHARGE_AMOUNT
                 , POS_VAT_AMOUNT
                 , POS_NET_UNIT_VALUE
                 , POS_NET_UNIT_VALUE_INCL
                 , POS_GROSS_VALUE
                 , POS_GROSS_VALUE_INCL
                 , POS_NET_VALUE_EXCL
                 , POS_NET_VALUE_INCL
                 , POS_CALC_BUDGET_AMOUNT_MB
                 , POS_EFFECT_BUDGET_AMOUNT_MB
                 , C_POS_CREATE_MODE
                 , POS_CREATE_POSITION_CHARGE
                 , POS_UPDATE_POSITION_CHARGE
                 , POS_RECALC_AMOUNTS
                 , ASA_INTERVENTION_DETAIL_ID
                 , DOC_INVOICE_EXPIRY_ID
                 , DOC_INVOICE_EXPIRY_DETAIL_ID
                 , PAC_THIRD_CDA_ID
                 , PAC_THIRD_VAT_ID
                 , POS_ADDENDUM_SRC_POS_ID
                 , POS_ADDENDUM_QTY_BALANCED
                 , POS_ADDENDUM_VALUE_QTY
                 , FAL_LOT_ID
                 , GCO_MANUFACTURED_GOOD_ID
                 , C_DOC_LOT_TYPE
                 , GCO_COMPL_DATA_ID
                  )
        select aPositionInfo.DOC_POSITION_ID
             , aPositionInfo.DOC_DOCUMENT_ID
             , aPositionInfo.DOC_GAUGE_POSITION_ID
             , aPositionInfo.C_GAUGE_TYPE_POS
             , aPositionInfo.C_DOC_POS_STATUS
             , aPositionInfo.GCO_GOOD_ID
             , aPositionInfo.PAC_THIRD_ID
             , aPositionInfo.PAC_THIRD_ACI_ID
             , aPositionInfo.PAC_THIRD_DELIVERY_ID
             , aPositionInfo.PAC_THIRD_TARIFF_ID
             , aPositionInfo.DOC_GAUGE_ID
             , aPositionInfo.POS_NUMBER
             , aPositionInfo.STM_MOVEMENT_KIND_ID
             , aPositionInfo.DOC_DOC_POSITION_ID
             , aPositionInfo.POS_INCLUDE_TAX_TARIFF
             , aPositionInfo.POS_TRANSFERT_PROPRIETOR
             , aPositionInfo.A_DATECRE
             , aPositionInfo.A_IDCRE
             , aPositionInfo.DIC_DIC_UNIT_OF_MEASURE_ID
             , aPositionInfo.DOC_RECORD_ID
             , aPositionInfo.DOC_DOC_RECORD_ID
             , aPositionInfo.STM_STOCK_ID
             , aPositionInfo.STM_LOCATION_ID
             , aPositionInfo.STM_STM_STOCK_ID
             , aPositionInfo.STM_STM_LOCATION_ID
             , aPositionInfo.ACS_TAX_CODE_ID
             , aPositionInfo.ACS_FINANCIAL_ACCOUNT_ID
             , aPositionInfo.ACS_DIVISION_ACCOUNT_ID
             , aPositionInfo.ACS_CPN_ACCOUNT_ID
             , aPositionInfo.ACS_PF_ACCOUNT_ID
             , aPositionInfo.ACS_PJ_ACCOUNT_ID
             , aPositionInfo.ACS_CDA_ACCOUNT_ID
             , aPositionInfo.HRM_PERSON_ID
             , aPositionInfo.FAM_FIXED_ASSETS_ID
             , aPositionInfo.C_FAM_TRANSACTION_TYP
             , aPositionInfo.POS_IMF_TEXT_1
             , aPositionInfo.POS_IMF_TEXT_2
             , aPositionInfo.POS_IMF_TEXT_3
             , aPositionInfo.POS_IMF_TEXT_4
             , aPositionInfo.POS_IMF_TEXT_5
             , aPositionInfo.POS_IMF_NUMBER_2
             , aPositionInfo.POS_IMF_NUMBER_3
             , aPositionInfo.POS_IMF_NUMBER_4
             , aPositionInfo.POS_IMF_NUMBER_5
             , aPositionInfo.DIC_IMP_FREE1_ID
             , aPositionInfo.DIC_IMP_FREE2_ID
             , aPositionInfo.DIC_IMP_FREE3_ID
             , aPositionInfo.DIC_IMP_FREE4_ID
             , aPositionInfo.DIC_IMP_FREE5_ID
             , aPositionInfo.POS_REFERENCE
             , aPositionInfo.POS_SECONDARY_REFERENCE
             , aPositionInfo.POS_SHORT_DESCRIPTION
             , aPositionInfo.POS_LONG_DESCRIPTION
             , aPositionInfo.POS_FREE_DESCRIPTION
             , aPositionInfo.POS_EAN_CODE
             , aPositionInfo.POS_EAN_UCC14_CODE
             , aPositionInfo.POS_HIBC_PRIMARY_CODE
             , aPositionInfo.POS_BODY_TEXT
             , aPositionInfo.PC_APPLTXT_ID
             , aPositionInfo.DIC_UNIT_OF_MEASURE_ID
             , aPositionInfo.A_DATEMOD
             , aPositionInfo.A_IDMOD
             , aPositionInfo.A_RECLEVEL
             , aPositionInfo.A_RECSTATUS
             , aPositionInfo.A_CONFIRM
             , aPositionInfo.POS_NOM_TEXT
             , aPositionInfo.DIC_POS_FREE_TABLE_1_ID
             , aPositionInfo.DIC_POS_FREE_TABLE_2_ID
             , aPositionInfo.DIC_POS_FREE_TABLE_3_ID
             , aPositionInfo.POS_DECIMAL_1
             , aPositionInfo.POS_DECIMAL_2
             , aPositionInfo.POS_DECIMAL_3
             , aPositionInfo.POS_TEXT_1
             , aPositionInfo.POS_TEXT_2
             , aPositionInfo.POS_TEXT_3
             , aPositionInfo.POS_DATE_1
             , aPositionInfo.POS_DATE_2
             , aPositionInfo.POS_DATE_3
             , aPositionInfo.PAC_REPRESENTATIVE_ID
             , aPositionInfo.PAC_REPR_ACI_ID
             , aPositionInfo.PAC_REPR_DELIVERY_ID
             , aPositionInfo.CML_POSITION_ID
             , aPositionInfo.CML_EVENTS_ID
             , aPositionInfo.ASA_RECORD_ID
             , aPositionInfo.ASA_RECORD_COMP_ID
             , aPositionInfo.ASA_RECORD_TASK_ID
             , aPositionInfo.FAL_SUPPLY_REQUEST_ID
             , aPositionInfo.PAC_PERSON_ID
             , aPositionInfo.C_POS_DELIVERY_TYP
             , aPositionInfo.POS_RATE_FACTOR
             , nvl(aPositionInfo.POS_NET_TARIFF, 0)
             , nvl(aPositionInfo.POS_SPECIAL_TARIFF, 0)
             , nvl(aPositionInfo.POS_FLAT_RATE, 0)
             , aPositionInfo.POS_TARIFF_UNIT
             , aPositionInfo.POS_TARIFF_SET
             , aPositionInfo.POS_DISCOUNT_RATE
             , aPositionInfo.POS_DISCOUNT_UNIT_VALUE
             , aPositionInfo.POS_NET_WEIGHT
             , aPositionInfo.POS_GROSS_WEIGHT
             , aPositionInfo.POS_UTIL_COEFF
             , aPositionInfo.POS_CONVERT_FACTOR
             , aPositionInfo.POS_CONVERT_FACTOR2
             , aPositionInfo.POS_PARTNER_NUMBER
             , aPositionInfo.POS_PARTNER_REFERENCE
             , aPositionInfo.POS_DATE_PARTNER_DOCUMENT
             , aPositionInfo.POS_PARTNER_POS_NUMBER
             , aPositionInfo.DIC_TARIFF_ID
             , aPositionInfo.POS_TARIFF_DATE
             , aPositionInfo.POS_BALANCE_QUANTITY
             , aPositionInfo.POS_VALUE_QUANTITY
             , aPositionInfo.POS_BALANCE_QTY_VALUE
             , aPositionInfo.DOC_EXTRACT_COMMISSION_ID
             , aPositionInfo.POS_BASIS_QUANTITY
             , aPositionInfo.POS_INTERMEDIATE_QUANTITY
             , aPositionInfo.POS_FINAL_QUANTITY
             , aPositionInfo.POS_BASIS_QUANTITY_SU
             , aPositionInfo.POS_INTERMEDIATE_QUANTITY_SU
             , aPositionInfo.POS_FINAL_QUANTITY_SU
             , aPositionInfo.POS_TARIFF_INITIALIZED
             , aPositionInfo.POS_UNIT_COST_PRICE
             , aPositionInfo.POS_GROSS_UNIT_VALUE
             , aPositionInfo.POS_GROSS_UNIT_VALUE_INCL
             , aPositionInfo.POS_GROSS_UNIT_VALUE2
             , aPositionInfo.POS_REF_UNIT_VALUE
             , aPositionInfo.POS_DISCOUNT_AMOUNT
             , aPositionInfo.POS_CHARGE_AMOUNT
             , aPositionInfo.POS_VAT_AMOUNT
             , aPositionInfo.POS_NET_UNIT_VALUE
             , aPositionInfo.POS_NET_UNIT_VALUE_INCL
             , aPositionInfo.POS_GROSS_VALUE
             , aPositionInfo.POS_GROSS_VALUE_INCL
             , aPositionInfo.POS_NET_VALUE_EXCL
             , aPositionInfo.POS_NET_VALUE_INCL
             , aPositionInfo.POS_CALC_BUDGET_AMOUNT_MB
             , aPositionInfo.POS_EFFECT_BUDGET_AMOUNT_MB
             , nvl(aPositionInfo.C_POS_CREATE_MODE
                 , case aPositionInfo.CREATE_TYPE
                     when 'INSERT' then '910'
                     when 'COPY' then '920'
                     when 'DISCHARGE' then '930'
                     else '999'
                   end
                  ) as C_POS_CREATE_MODE
             , 0
             , 0
             , 0
             , aPositionInfo.ASA_INTERVENTION_DETAIL_ID
             , aPositionInfo.DOC_INVOICE_EXPIRY_ID
             , aPositionInfo.DOC_INVOICE_EXPIRY_DETAIL_ID
             , aPositionInfo.PAC_THIRD_CDA_ID
             , aPositionInfo.PAC_THIRD_VAT_ID
             , aPositionInfo.POS_ADDENDUM_SRC_POS_ID
             , aPositionInfo.POS_ADDENDUM_QTY_BALANCED
             , aPositionInfo.POS_ADDENDUM_VALUE_QTY
             , aPositionInfo.FAL_LOT_ID
             , aPositionInfo.GCO_MANUFACTURED_GOOD_ID
             , aPositionInfo.C_DOC_LOT_TYPE
             , aPositionInfo.GCO_COMPL_DATA_ID
          from dual;
    end if;
  end InsertPosition;
end DOC_POSITION_GENERATE;
