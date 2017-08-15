--------------------------------------------------------
--  DDL for Package Body STM_PRC_MOVEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_MOVEMENT" 
is
  /**
  * Description
  *   Set extourner id in the first movement of an extourne
  */
  procedure UpdateReverseLink(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
  begin
    if nvl(iotMovementRecord.STM2_STM_STOCK_MOVEMENT_ID, 0) <> 0 then
      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_STM_ENTITY.gcStmStockMovement
                           , iot_crud_definition   => ltCRUD_DEF
                           , iv_primary_col        => 'STM_STOCK_MOVEMENT_ID'
                            );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', iotMovementRecord.STM2_STM_STOCK_MOVEMENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM2_STM_STOCK_MOVEMENT_ID', iotMovementRecord.STM_STOCK_MOVEMENT_ID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;
    end if;
  end UpdateReverseLink;

  /**
  * procedure pGenerateReportMovement
  * Description
  *   procedure de génération du mouvement de report d'exercice
  * @author FP
  * @created 15.01.2002
  * @lastUpdate
  * @private
  * @param
  * @param
  */
  procedure pGenerateReportMovement(
    iBaseMovementKindId  in number
  , iWording             in varchar2
  , iGoodId              in number
  , iStockId             in number
  , iLocationId          in number
  , iThirdId             in number
  , iThirdAciId          in number
  , iThirdDeliveryId     in number
  , iThirdTariffId       in number
  , iRecordId            in number
  , iAltQty1             in number
  , iAltQty2             in number
  , iAltQty3             in number
  , iChar1Id             in number
  , iChar2Id             in number
  , iChar3Id             in number
  , iChar4Id             in number
  , iChar5Id             in number
  , iCharValue1          in varchar2
  , iCharValue2          in varchar2
  , iCharValue3          in varchar2
  , iCharValue4          in varchar2
  , iCharValue5          in varchar2
  , iMvtQty              in number
  , iMvtPrice            in number
  , iDocQty              in number
  , iDocPrice            in number
  , iMvtDate             in date
  , iValueDate           in STM_STOCK_MOVEMENT.SMO_VALUE_DATE%type
  , iUnitPrice           in number
  , iRefUnitPrice        in number
  , iDocPositionId       in number
  , iDocPositionDetailId in number
  , iFinancialAccountId  in number
  , iDivisionAccountId   in number
  , iAFinancialAccountId in number
  , iADivisionAccountId  in number
  , iCPNAccountId        in number
  , iACPNAccountId       in number
  , iCDAAccountId        in number
  , iACDAAccountId       in number
  , iPFAccountId         in number
  , iAPFAccountId        in number
  , iPJAccountId         in number
  , iAPJAccountId        in number
  , iFamFixedAssetsId    in STM_STOCK_MOVEMENT.FAM_FIXED_ASSETS_ID%type
  , iFamTransactionTyp   in STM_STOCK_MOVEMENT.C_FAM_TRANSACTION_TYP%type
  , iHrmPersonId         in STM_STOCK_MOVEMENT.HRM_PERSON_ID%type
  , iDicImpfree1Id       in STM_STOCK_MOVEMENT.DIC_IMP_FREE1_ID%type
  , iDicImpfree2Id       in STM_STOCK_MOVEMENT.DIC_IMP_FREE2_ID%type
  , iDicImpfree3Id       in STM_STOCK_MOVEMENT.DIC_IMP_FREE3_ID%type
  , iDicImpfree4Id       in STM_STOCK_MOVEMENT.DIC_IMP_FREE4_ID%type
  , iDicImpfree5Id       in STM_STOCK_MOVEMENT.DIC_IMP_FREE5_ID%type
  , iImpText1            in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_1%type
  , iImpText2            in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_2%type
  , iImpText3            in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_3%type
  , iImpText4            in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_4%type
  , iImpText5            in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_5%type
  , iImpNumber1          in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_1%type
  , iImpNumber2          in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_2%type
  , iImpNumber3          in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_3%type
  , iImpNumber4          in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_4%type
  , iImpNumber5          in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_5%type
  , iExtourneMvt         in number
  , iOrderKey            in STM_STOCK_MOVEMENT.SMO_MOVEMENT_ORDER_KEY%type default null
  , iDocFootAlloyID      in STM_STOCK_MOVEMENT.DOC_FOOT_ALLOY_ID%type default null
  , iIntervDetID         in STM_STOCK_MOVEMENT.ASA_INTERVENTION_DETAIL_ID%type default null
  , iFalFactoryInId      in FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type default null
  , iFalFactoryOutId     in FAL_FACTORY_OUT.FAL_FACTORY_OUT_ID%type default null
  , iSmoPrcsValue        in STM_STOCK_MOVEMENT.SMO_PRCS_VALUE%type default null
  , iFalHistoLotId       in STM_STOCK_MOVEMENT.FAL_HISTO_LOT_ID%type default null
  , iDocPositionAlloyID  in STM_STOCK_MOVEMENT.DOC_POSITION_ALLOY_ID%type default null
  , iDicRebutId          in STM_STOCK_MOVEMENT.DIC_REBUT_ID%type default null
  , iFalLotId            in FAL_LOT.FAL_LOT_ID%type default null
  )
  is
    lReportMovementKindId STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lBaseMovementSort     STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMvtQty               STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lDocQty               STM_STOCK_MOVEMENT.SMO_DOCUMENT_QUANTITY%type;
    lMvtPrice             STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    lDocPrice             STM_STOCK_MOVEMENT.SMO_DOCUMENT_PRICE%type;
    lActiveExerciseId     STM_EXERCISE.STM_EXERCISE_ID%type;
    lFirstPeriodId        STM_PERIOD.STM_PERIOD_ID%type;
    lStartExerciseDate    date;
    lFinancialCharging    STM_STOCK_MOVEMENT.SMO_FINANCIAL_CHARGING%type;
    lReportMovementId     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    -- recherche de l'exercice actif
    select STM_EXERCISE_ID
         , EXE_STARTING_EXERCISE
      into lActiveExerciseId
         , lStartExerciseDate
      from STM_EXERCISE
     where C_EXERCISE_STATUS = '02';

    -- si le mouvement est généré dans un autre exercice que l'exercice actif
    if lActiveExerciseId <> STM_FUNCTIONS.GetExerciseId(iMvtDate) then
      -- recherche du genre de mouvement de report d'exercice
      select STM_MOVEMENT_KIND_id
        into lReportMovementKindId
        from STM_MOVEMENT_KIND
       where c_movement_sort = 'ENT'
         and c_movement_type = 'EXE'
         and c_movement_code = '004';

      -- si le mouvement à reporter n'est pas du genre report d'exercice
      if iBaseMovementKindId <> lReportMovementKindId then
        -- recherche de la première période de l'exercice actif
        select STM_PERIOD_ID
          into lFirstPeriodId
          from STM_PERIOD
         where STM_EXERCISE_ID = lActiveExerciseId
           and PER_NUMBER = 1;

        -- inversion du signe qté et montant pour les sorties
        select decode(c_movement_sort, 'ENT', iMvtQty, 'SOR', -iMvtQty)
             , decode(c_movement_sort, 'ENT', iDocQty, 'SOR', -iDocQty)
             , decode(c_movement_sort, 'ENT', iMvtPrice, 'SOR', -iMvtPrice)
             , decode(c_movement_sort, 'ENT', iDocPrice, 'SOR', -iDocPrice)
             , MOK_FINANCIAL_IMPUTATION
          into lMvtQty
             , lDocQty
             , lMvtPrice
             , lDocPrice
             , lFinancialCharging
          from STM_MOVEMENT_KIND
         where STM_MOVEMENT_KIND_id = iBaseMovementKindId;

        -- insertion du mouvement de report
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lReportMovementId
                                        , iGoodId                => iGoodId
                                        , iMovementKindId        => lReportMovementKindId
                                        , iExerciseId            => lActiveExerciseId
                                        , iPeriodId              => lFirstPeriodId
                                        , iMvtDate               => lStartExerciseDate
                                        , iValueDate             => lStartExerciseDate
                                        , iStockId               => iStockId
                                        , iLocationId            => iLocationId
                                        , iThirdId               => iThirdId
                                        , iThirdAciId            => iThirdAciId
                                        , iThirdDeliveryId       => iThirdDeliveryId
                                        , iThirdTariffId         => iThirdTariffId
                                        , iRecordId              => iRecordId
                                        , iChar1Id               => iChar1Id
                                        , iChar2Id               => iChar2Id
                                        , iChar3Id               => iChar3Id
                                        , iChar4Id               => iChar4Id
                                        , iChar5Id               => iChar5Id
                                        , iCharValue1            => iCharValue1
                                        , iCharValue2            => iCharValue2
                                        , iCharValue3            => iCharValue3
                                        , iCharValue4            => iCharValue4
                                        , iCharValue5            => iCharValue5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => iWording
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => lMvtQty
                                        , iMvtPrice              => lMvtPrice
                                        , iDocQty                => lDocQty
                                        , iDocPrice              => lDocPrice
                                        , iUnitPrice             => iUnitPrice
                                        , iRefUnitPrice          => iRefUnitPrice
                                        , iAltQty1               => iAltQty1
                                        , iAltQty2               => iAltQty2
                                        , iAltQty3               => iAltQty3
                                        , iDocPositionDetailId   => iDocPositionDetailId
                                        , iDocPositionId         => iDocPositionId
                                        , iFinancialAccountId    => iFinancialAccountId
                                        , iDivisionAccountId     => iDivisionAccountId
                                        , iAFinancialAccountId   => iAFinancialAccountId
                                        , iADivisionAccountId    => iADivisionAccountId
                                        , iCPNAccountId          => iCPNAccountId
                                        , iACPNAccountId         => iACPNAccountId
                                        , iCDAAccountId          => iCDAAccountId
                                        , iACDAAccountId         => iACDAAccountId
                                        , iPFAccountId           => iPFAccountId
                                        , iAPFAccountId          => iAPFAccountId
                                        , iPJAccountId           => iPJAccountId
                                        , iAPJAccountId          => iAPJAccountId
                                        , iFamFixedAssetsId      => iFamFixedAssetsId
                                        , iFamTransactionTyp     => iFamTransactionTyp
                                        , iHrmPersonId           => iHrmPersonId
                                        , iDicImpfree1Id         => iDicImpfree1Id
                                        , iDicImpfree2Id         => iDicImpfree2Id
                                        , iDicImpfree3Id         => iDicImpfree3Id
                                        , iDicImpfree4Id         => iDicImpfree4Id
                                        , iDicImpfree5Id         => iDicImpfree5Id
                                        , iImpText1              => iImpText1
                                        , iImpText2              => iImpText2
                                        , iImpText3              => iImpText3
                                        , iImpText4              => iImpText4
                                        , iImpText5              => iImpText5
                                        , iImpNumber1            => iImpNumber1
                                        , iImpNumber2            => iImpNumber2
                                        , iImpNumber3            => iImpNumber3
                                        , iImpNumber4            => iImpNumber4
                                        , iImpNumber5            => iImpNumber5
                                        , iFinancialCharging     => lFinancialCharging
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => iExtourneMvt
                                        , iRecStatus             => 9
                                        , iOrderKey              => iOrderKey
                                        , iDocFootAlloyID        => iDocFootAlloyID
                                        , iIntervDetID           => iIntervDetID
                                        , iFalFactoryInId        => iFalFactoryInId
                                        , iFalFactoryOutId       => iFalFactoryOutId
                                        , iSmoPrcsValue          => iSmoPrcsValue
                                        , iFalHistoLotId         => iFalHistoLotId
                                        , iDocPositionAlloyID    => iDocPositionAlloyID
                                        , iDicRebutId            => iDicRebutId
                                        , iFalLotId              => iFalLotId
                                         );
      end if;
    end if;
  end pGenerateReportMovement;

  /**
  * Description
  *    procedure de génération des mouvements de stock
  *    cette procédure gère également l'appel de la génération du mouvement de report
  */
  procedure GenerateMovement(
    ioStockMovementId    in out STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iGoodId              in     STM_STOCK_MOVEMENT.GCO_GOOD_ID%type default null
  , iMovementKindId      in     STM_STOCK_MOVEMENT.STM_MOVEMENT_KIND_ID%type default null
  , iExerciseId          in     STM_STOCK_MOVEMENT.STM_EXERCISE_ID%type default null
  , iPeriodId            in     STM_STOCK_MOVEMENT.STM_PERIOD_ID%type default null
  , iMvtDate             in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type default null
  , iValueDate           in     STM_STOCK_MOVEMENT.SMO_VALUE_DATE%type default null
  , iStockId             in     STM_STOCK_MOVEMENT.STM_STOCK_ID%type default null
  , iLocationId          in     STM_STOCK_MOVEMENT.STM_LOCATION_ID%type default null
  , iThirdId             in     STM_STOCK_MOVEMENT.PAC_THIRD_ID%type default null
  , iThirdAciId          in     STM_STOCK_MOVEMENT.PAC_THIRD_ACI_ID%type default null
  , iThirdDeliveryId     in     STM_STOCK_MOVEMENT.PAC_THIRD_DELIVERY_ID%type default null
  , iThirdTariffId       in     STM_STOCK_MOVEMENT.PAC_THIRD_TARIFF_ID%type default null
  , iRecordId            in     STM_STOCK_MOVEMENT.DOC_RECORD_ID%type default null
  , iChar1Id             in     STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type default null
  , iChar2Id             in     STM_STOCK_MOVEMENT.GCO_GCO_CHARACTERIZATION_ID%type default null
  , iChar3Id             in     STM_STOCK_MOVEMENT.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , iChar4Id             in     STM_STOCK_MOVEMENT.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , iChar5Id             in     STM_STOCK_MOVEMENT.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , iCharValue1          in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue2          in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type default null
  , iCharValue3          in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type default null
  , iCharValue4          in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type default null
  , iCharValue5          in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type default null
  , iMovement2Id         in     STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type default null
  , iMovement3Id         in     STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type default null
  , iWording             in     STM_STOCK_MOVEMENT.SMO_WORDING%type default null
  , iExternalDocument    in     STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type default null
  , iExternalPartner     in     STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type default null
  , iMvtQty              in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type default null
  , iMvtPrice            in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type default null
  , iDocQty              in     STM_STOCK_MOVEMENT.SMO_DOCUMENT_QUANTITY%type default null
  , iDocPrice            in     STM_STOCK_MOVEMENT.SMO_DOCUMENT_PRICE%type default null
  , iUnitPrice           in     STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type default null
  , iRefUnitPrice        in     STM_STOCK_MOVEMENT.SMO_REFERENCE_UNIT_PRICE%type default null
  , iAltQty1             in     STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_1%type default null
  , iAltQty2             in     STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_2%type default null
  , iAltQty3             in     STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_3%type default null
  , iDocPositionDetailId in     STM_STOCK_MOVEMENT.DOC_POSITION_DETAIL_ID%type default null
  , iDocPositionId       in     STM_STOCK_MOVEMENT.DOC_POSITION_ID%type default null
  , iFinancialAccountId  in     STM_STOCK_MOVEMENT.ACS_FINANCIAL_ACCOUNT_ID%type default null
  , iDivisionAccountId   in     STM_STOCK_MOVEMENT.ACS_DIVISION_ACCOUNT_ID%type default null
  , iAFinancialAccountId in     STM_STOCK_MOVEMENT.ACS_ACS_FINANCIAL_ACCOUNT_ID%type default null
  , iADivisionAccountId  in     STM_STOCK_MOVEMENT.ACS_ACS_DIVISION_ACCOUNT_ID%type default null
  , iCPNAccountId        in     STM_STOCK_MOVEMENT.ACS_CPN_ACCOUNT_ID%type default null
  , iACPNAccountId       in     STM_STOCK_MOVEMENT.ACS_ACS_CPN_ACCOUNT_ID%type default null
  , iCDAAccountId        in     STM_STOCK_MOVEMENT.ACS_CDA_ACCOUNT_ID%type default null
  , iACDAAccountId       in     STM_STOCK_MOVEMENT.ACS_ACS_CDA_ACCOUNT_ID%type default null
  , iPFAccountId         in     STM_STOCK_MOVEMENT.ACS_PF_ACCOUNT_ID%type default null
  , iAPFAccountId        in     STM_STOCK_MOVEMENT.ACS_ACS_PF_ACCOUNT_ID%type default null
  , iPJAccountId         in     STM_STOCK_MOVEMENT.ACS_PJ_ACCOUNT_ID%type default null
  , iAPJAccountId        in     STM_STOCK_MOVEMENT.ACS_ACS_PJ_ACCOUNT_ID%type default null
  , iFamFixedAssetsId    in     STM_STOCK_MOVEMENT.FAM_FIXED_ASSETS_ID%type default null
  , iFamTransactionTyp   in     STM_STOCK_MOVEMENT.C_FAM_TRANSACTION_TYP%type default null
  , iHrmPersonId         in     STM_STOCK_MOVEMENT.HRM_PERSON_ID%type default null
  , iDicImpfree1Id       in     STM_STOCK_MOVEMENT.DIC_IMP_FREE1_ID%type default null
  , iDicImpfree2Id       in     STM_STOCK_MOVEMENT.DIC_IMP_FREE2_ID%type default null
  , iDicImpfree3Id       in     STM_STOCK_MOVEMENT.DIC_IMP_FREE3_ID%type default null
  , iDicImpfree4Id       in     STM_STOCK_MOVEMENT.DIC_IMP_FREE4_ID%type default null
  , iDicImpfree5Id       in     STM_STOCK_MOVEMENT.DIC_IMP_FREE5_ID%type default null
  , iImpText1            in     STM_STOCK_MOVEMENT.SMO_IMP_TEXT_1%type default null
  , iImpText2            in     STM_STOCK_MOVEMENT.SMO_IMP_TEXT_2%type default null
  , iImpText3            in     STM_STOCK_MOVEMENT.SMO_IMP_TEXT_3%type default null
  , iImpText4            in     STM_STOCK_MOVEMENT.SMO_IMP_TEXT_4%type default null
  , iImpText5            in     STM_STOCK_MOVEMENT.SMO_IMP_TEXT_5%type default null
  , iImpNumber1          in     STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_1%type default null
  , iImpNumber2          in     STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_2%type default null
  , iImpNumber3          in     STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_3%type default null
  , iImpNumber4          in     STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_4%type default null
  , iImpNumber5          in     STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_5%type default null
  , iFinancialCharging   in     STM_STOCK_MOVEMENT.SMO_FINANCIAL_CHARGING%type default null
  , iUpdateProv          in     STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type default null
  , iExtourneMvt         in     STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type default null
  , iRecStatus           in     STM_STOCK_MOVEMENT.A_RECSTATUS%type default null
  , iOrderKey            in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_ORDER_KEY%type default null
  , iDocFootAlloyID      in     STM_STOCK_MOVEMENT.DOC_FOOT_ALLOY_ID%type default null
  , iInventoryMvt        in     number default 0
  , iIntervDetID         in     STM_STOCK_MOVEMENT.ASA_INTERVENTION_DETAIL_ID%type default null
  , iFalFactoryInId      in     FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type default null
  , iFalFactoryOutId     in     FAL_FACTORY_OUT.FAL_FACTORY_OUT_ID%type default null
  , iSmoPrcsValue        in     STM_STOCK_MOVEMENT.SMO_PRCS_VALUE%type default null
  , iTargetPrice         in     STM_STOCK_MOVEMENT.SMO_TARGET_PRICE%type default null
  , iFalHistoLotId       in     STM_STOCK_MOVEMENT.FAL_HISTO_LOT_ID%type default null
  , iDocPositionAlloyID  in     STM_STOCK_MOVEMENT.DOC_POSITION_ALLOY_ID%type default null
  , iDicRebutId          in     STM_STOCK_MOVEMENT.DIC_REBUT_ID%type default null
  , iFalLotId            in     FAL_LOT.FAL_LOT_ID%type default null
  , iSmoLinkId1          in     STM_STOCK_MOVEMENT.SMO_LINK_ID_1%type default null
  , iSmoLinkName1        in     STM_STOCK_MOVEMENT.SMO_LINK_NAME_1%type default null
  )
  is
    lDicImpfree1Id STM_STOCK_MOVEMENT.DIC_IMP_FREE1_ID%type;
    lDicImpfree2Id STM_STOCK_MOVEMENT.DIC_IMP_FREE2_ID%type;
    lDicImpfree3Id STM_STOCK_MOVEMENT.DIC_IMP_FREE3_ID%type;
    lDicImpfree4Id STM_STOCK_MOVEMENT.DIC_IMP_FREE4_ID%type;
    lDicImpfree5Id STM_STOCK_MOVEMENT.DIC_IMP_FREE5_ID%type;
    lSmoImpText1   STM_STOCK_MOVEMENT.SMO_IMP_TEXT_1%type;
    lSmoImpText2   STM_STOCK_MOVEMENT.SMO_IMP_TEXT_2%type;
    lSmoImpText3   STM_STOCK_MOVEMENT.SMO_IMP_TEXT_3%type;
    lSmoImpText4   STM_STOCK_MOVEMENT.SMO_IMP_TEXT_4%type;
    lSmoImpText5   STM_STOCK_MOVEMENT.SMO_IMP_TEXT_5%type;
    lMvtDate       STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type   default null;
  begin
    -- si on a donné un ID pour le mouvement on l'utilise, sinon on en affecte un à
    -- partir de la sequence init_id_seq
    select nvl(ioStockMovementId, init_id_seq.nextval)
         , rtrim(iDicImpfree1Id)   -- DIC_IMP_FREE1_ID,
         , rtrim(iDicImpfree2Id)   -- DIC_IMP_FREE2_ID,
         , rtrim(iDicImpfree3Id)   -- DIC_IMP_FREE3_ID,
         , rtrim(iDicImpfree4Id)   -- DIC_IMP_FREE4_ID,
         , rtrim(iDicImpfree5Id)   -- DIC_IMP_FREE5_ID,
         , iImpText1   -- SMO_IMP_TEXT_1,
         , iImpText2   -- SMO_IMP_TEXT_2,
         , iImpText3   -- SMO_IMP_TEXT_3,
         , iImpText4   -- SMO_IMP_TEXT_4,
         , iImpText5   -- SMO_IMP_TEXT_5,
      into ioStockMovementId
         , lDicImpfree1Id   -- DIC_IMP_FREE1_ID,
         , lDicImpfree2Id   -- DIC_IMP_FREE2_ID,
         , lDicImpfree3Id   -- DIC_IMP_FREE3_ID,
         , lDicImpfree4Id   -- DIC_IMP_FREE4_ID,
         , lDicImpfree5Id   -- DIC_IMP_FREE5_ID,
         , lSmoImpText1   -- SMO_IMP_TEXT_1,
         , lSmoImpText2   -- SMO_IMP_TEXT_2,
         , lSmoImpText3   -- SMO_IMP_TEXT_3,
         , lSmoImpText4   -- SMO_IMP_TEXT_4,
         , lSmoImpText5   -- SMO_IMP_TEXT_5,
      from dual;

    lMvtDate  := trunc(STM_LIB_EXERCISE.GetActiveDate(iMvtDate) );

    declare
      ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmStockMovement, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', ioStockMovementId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', iGoodId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_MOVEMENT_KIND_ID', iMovementKindId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_EXERCISE_ID', STM_I_LIB_EXERCISE.GetExerciseId(lMvtDate) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_PERIOD_ID', STM_I_LIB_EXERCISE.GetPeriodId(lMvtDate) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_ID', iStockId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_LOCATION_ID', iLocationId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_ID', iThirdId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_ACI_ID', iThirdAciId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_DELIVERY_ID', iThirdDeliveryId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_TARIFF_ID', iThirdTariffId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_RECORD_ID', iRecordId);
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltCRUD_DEF, 'ACS_ACCOUNT_ID');   -- null
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_CHARACTERIZATION_ID', iChar1Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GCO_CHARACTERIZATION_ID', iChar2Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO2_GCO_CHARACTERIZATION_ID', iChar3Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO3_GCO_CHARACTERIZATION_ID', iChar4Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO4_GCO_CHARACTERIZATION_ID', iChar5Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_1', iCharValue1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_2', iCharValue2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_3', iCharValue3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_4', iCharValue4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_5', iCharValue5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STM_STOCK_MOVEMENT_ID', iMovement2Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM2_STM_STOCK_MOVEMENT_ID', iMovement3Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_MOVEMENT_DATE', lMvtDate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_VALUE_DATE', trunc(nvl(iValueDate, lMvtDate) ) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_WORDING', iWording);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_EXTERNAL_DOCUMENT', iExternalDocument);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_EXTERNAL_PARTNER', iExternalPartner);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_MOVEMENT_QUANTITY', iMvtQty);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_MOVEMENT_PRICE', iMvtPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_DOCUMENT_QUANTITY', iDocQty);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_DOCUMENT_PRICE', iDocPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_UNIT_PRICE', iUnitPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_REFERENCE_UNIT_PRICE', iRefUnitPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_MVT_ALTERNATIV_QTY_1', iAltQty1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_MVT_ALTERNATIV_QTY_2', iAltQty2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_MVT_ALTERNATIV_QTY_3', iAltQty3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_POSITION_DETAIL_ID', iDocPositionDetailId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_POSITION_ID', iDocPositionId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_ACCOUNT_ID', iFinancialAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_DIVISION_ACCOUNT_ID', iDivisionAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ACS_FINANCIAL_ACCOUNT_ID', iAFinancialAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ACS_DIVISION_ACCOUNT_ID', iADivisionAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_CPN_ACCOUNT_ID', iCPNAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ACS_CPN_ACCOUNT_ID', iACPNAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_CDA_ACCOUNT_ID', iCDAAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ACS_CDA_ACCOUNT_ID', iACDAAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_PF_ACCOUNT_ID', iPFAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ACS_PF_ACCOUNT_ID', iAPFAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_PJ_ACCOUNT_ID', iPJAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ACS_PJ_ACCOUNT_ID', iAPJAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAM_FIXED_ASSETS_ID', iFamFixedAssetsId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_FAM_TRANSACTION_TYP', iFamTransactionTyp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'HRM_PERSON_ID', iHrmPersonId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_IMP_FREE1_ID', lDicImpfree1Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_IMP_FREE2_ID', lDicImpfree2Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_IMP_FREE3_ID', lDicImpfree3Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_IMP_FREE4_ID', lDicImpfree4Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_IMP_FREE5_ID', lDicImpfree5Id);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_TEXT_1', lSmoImpText1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_TEXT_2', lSmoImpText2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_TEXT_3', lSmoImpText3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_TEXT_4', lSmoImpText4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_TEXT_5', lSmoImpText5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_NUMBER_1', iImpNumber1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_NUMBER_2', iImpNumber2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_NUMBER_3', iImpNumber3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_NUMBER_4', iImpNumber4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_IMP_NUMBER_5', iImpNumber5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_FINANCIAL_CHARGING', iFinancialCharging);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_UPDATE_PROV', iUpdateProv);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_EXTOURNE_MVT', iExtourneMvt);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_PRCS_UPDATED', 0);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_MOVEMENT_ORDER_KEY', nvl(iOrderKey, ioStockMovementId) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_RECSTATUS', iRecStatus);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_FOOT_ALLOY_ID', iDocFootAlloyID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_INTERVENTION_DETAIL_ID', iIntervDetID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_FACTORY_IN_ID', iFalFactoryInId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_FACTORY_OUT_ID', iFalFactoryOutId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_PRCS_VALUE', iSmoPrcsValue);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_TARGET_PRICE', iTargetPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_HISTO_LOT_ID', iFalHistoLotId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_POSITION_ALLOY_ID', iDocPositionAlloyID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_REBUT_ID', iDicRebutId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_LOT_ID', iFalLotId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_LINK_ID_1', iSmoLinkId1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SMO_LINK_NAME_1', iSmoLinkName1);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end;

    STM_PRC_MOVEMENT.pGenerateReportMovement(iBaseMovementKindId    => iMovementKindId
                                           , iWording               => iWording
                                           , iGoodId                => iGoodId
                                           , iStockId               => iStockId
                                           , iLocationId            => iLocationId
                                           , iThirdId               => iThirdId
                                           , iThirdAciId            => iThirdAciId
                                           , iThirdDeliveryId       => iThirdDeliveryId
                                           , iThirdTariffId         => iThirdTariffId
                                           , iRecordId              => iRecordId
                                           , iAltQty1               => iAltQty1
                                           , iAltQty2               => iAltQty2
                                           , iAltQty3               => iAltQty3
                                           , iChar1Id               => iChar1Id
                                           , iChar2Id               => iChar2Id
                                           , iChar3Id               => iChar3Id
                                           , iChar4Id               => iChar4Id
                                           , iChar5Id               => iChar5Id
                                           , iCharValue1            => iCharValue1
                                           , iCharValue2            => iCharValue2
                                           , iCharValue3            => iCharValue3
                                           , iCharValue4            => iCharValue4
                                           , iCharValue5            => iCharValue5
                                           , iMvtQty                => iMvtQty
                                           , iMvtPrice              => iMvtPrice
                                           , iDocQty                => iDocQty
                                           , iDocPrice              => iDocPrice
                                           , iMvtDate               => STM_LIB_EXERCISE.GetActiveDate(iMvtDate)
                                           , iValueDate             => nvl(iValueDate, iMvtDate)
                                           , iUnitPrice             => iUnitPrice
                                           , iRefUnitPrice          => iRefUnitPrice
                                           , iDocPositionId         => iDocPositionId
                                           , iDocPositionDetailId   => iDocPositionDetailId
                                           , iFinancialAccountId    => iFinancialAccountId
                                           , iDivisionAccountId     => iDivisionAccountId
                                           , iAFinancialAccountId   => iAFinancialAccountId
                                           , iADivisionAccountId    => iADivisionAccountId
                                           , iCPNAccountId          => iCPNAccountId
                                           , iACPNAccountId         => iACPNAccountId
                                           , iCDAAccountId          => iCDAAccountId
                                           , iACDAAccountId         => iACDAAccountId
                                           , iPFAccountId           => iPFAccountId
                                           , iAPFAccountId          => iAPFAccountId
                                           , iPJAccountId           => iPJAccountId
                                           , iAPJAccountId          => iAPJAccountId
                                           , iFamFixedAssetsId      => iFamFixedAssetsId
                                           , iFamTransactionTyp     => iFamTransactionTyp
                                           , iHrmPersonId           => iHrmPersonId
                                           , iDicImpfree1Id         => lDicImpfree1Id
                                           , iDicImpfree2Id         => lDicImpfree2Id
                                           , iDicImpfree3Id         => lDicImpfree3Id
                                           , iDicImpfree4Id         => lDicImpfree4Id
                                           , iDicImpfree5Id         => lDicImpfree5Id
                                           , iImpText1              => lSmoImpText1
                                           , iImpText2              => lSmoImpText2
                                           , iImpText3              => lSmoImpText3
                                           , iImpText4              => lSmoImpText4
                                           , iImpText5              => lSmoImpText5
                                           , iImpNumber1            => iImpNumber1
                                           , iImpNumber2            => iImpNumber2
                                           , iImpNumber3            => iImpNumber3
                                           , iImpNumber4            => iImpNumber4
                                           , iImpNumber5            => iImpNumber5
                                           , iExtourneMvt           => iExtourneMvt
                                           , iDocFootAlloyID        => iDocFootAlloyID
                                           , iIntervDetID           => iIntervDetID
                                           , iFalFactoryInId        => iFalFactoryInId
                                           , iFalFactoryOutId       => iFalFactoryOutId
                                           , iSmoPrcsValue          => iSmoPrcsValue
                                           , iFalHistoLotId         => iFalHistoLotId
                                           , iDicRebutId            => iDicRebutId
                                           , iFalLotId              => iFalLotId
                                            );
  end GenerateMovement;

  /**
  * Description
  *   Génèration des mouvements de début d'exercice afin de mettre à jour
  *   les tables d'évolution de stock.
  */
  procedure stm_newexstkmvt
  is
    -- Cette procedure doit être appelée à chaque ouverture d'exercice. Elle génère les mouvement
    -- de début d'exercice afin de mettre à jour les tables d'évolution de stock.
    -- Aucun paramètre n'est demandé
    lCounter           integer;
    lExerciseId        stm_exercise.stm_exercise_id%type;
    lPeriodId          stm_period.stm_period_id%type;
    lNextExerId        stm_exercise.stm_exercise_id%type;
    lFirstPeriodId     stm_period.stm_period_id%type;
    lMovementKindId    STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_id%type;
    lStockPositionId   stm_stock_position.stm_stock_position_id%type;
    lExerStartingDate  stm_exercise.exe_starting_exercise%type;
    lPrice             stm_stock_movement.smo_unit_price%type;
    lOldGoodId         gco_good.gco_good_id%type                        := 0;
    lPriceType         gco_good.c_management_mode%type;
    lReportMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lFinancialCharging STM_STOCK_MOVEMENT.SMO_FINANCIAL_CHARGING%type;

    -- ce curseur contientla liste des id des positions qui doivent engendré un mouvement de début d'exercice
    -- Sélection de toutes les positions
    cursor lcurStockPositions(iExerciseToActivate number)
    is
      select STM_STOCK_POSITION_ID
           , GCO_GOOD_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_CHARACTERIZATION_ID
           , GCO_GCO_CHARACTERIZATION_ID
           , GCO2_GCO_CHARACTERIZATION_ID
           , GCO3_GCO_CHARACTERIZATION_ID
           , GCO4_GCO_CHARACTERIZATION_ID
           , SPO_CHARACTERIZATION_VALUE_1
           , SPO_CHARACTERIZATION_VALUE_2
           , SPO_CHARACTERIZATION_VALUE_3
           , SPO_CHARACTERIZATION_VALUE_4
           , SPO_CHARACTERIZATION_VALUE_5
           , SPO_STOCK_QUANTITY
           , SPO_ALTERNATIV_QUANTITY_1
           , SPO_ALTERNATIV_QUANTITY_2
           , SPO_ALTERNATIV_QUANTITY_3
        from STM_STOCK_POSITION MAIN
       where (   SPO_STOCK_QUANTITY <> 0
              or SPO_ALTERNATIV_QUANTITY_1 <> 0
              or SPO_ALTERNATIV_QUANTITY_2 <> 0
              or SPO_ALTERNATIV_QUANTITY_3 <> 0)
         and not exists(
               select stm_stock_movement_id
                 from stm_stock_movement
                where GCO_GOOD_ID = main.gco_good_id
                  and stm_stock_id = main.stm_stock_id
                  and nvl(stm_location_id, 0) = nvl(main.stm_location_id, 0)
                  and nvl(smo_characterization_value_1, 'xxx') = nvl(main.spo_characterization_value_1, 'xxx')
                  and nvl(smo_characterization_value_2, 'xxx') = nvl(main.spo_characterization_value_2, 'xxx')
                  and nvl(smo_characterization_value_3, 'xxx') = nvl(main.spo_characterization_value_3, 'xxx')
                  and nvl(smo_characterization_value_4, 'xxx') = nvl(main.spo_characterization_value_4, 'xxx')
                  and nvl(smo_characterization_value_5, 'xxx') = nvl(main.spo_characterization_value_5, 'xxx')
                  and STM_MOVEMENT_KIND_id = (select STM_MOVEMENT_KIND_id
                                                from STM_MOVEMENT_KIND
                                               where MOK_ABBREVIATION = 'RepExer')
                  and STM_EXERCISE_ID = iExerciseToActivate);

    type ttStockPosition is table of lcurStockPositions%rowtype;

    lttStockPosition   ttStockPosition;

    cursor lcurOpenableExercise
    is
      select   stm_exercise.stm_exercise_id
          from stm_exercise
         where stm_exercise.c_exercise_status = '01'
      order by stm_exercise.exe_starting_exercise;
  begin
    -- Recherche de l'exercice et de la p'riode active
    select max(stm_exercise.stm_exercise_id)
         , max(stm_period.stm_period_id)
      into lExerciseId
         , lPeriodId
      from stm_exercise
         , stm_period
     where stm_exercise.c_exercise_status = '02'
       and stm_period.stm_exercise_id = stm_exercise.stm_exercise_id
       and stm_period.c_period_status = '02';

    -- si on a un exercice actif, on recherche le suivant
    if lExerciseId is not null then
      select a.stm_exercise_id
        into lNextExerId
        from stm_exercise a
           , stm_exercise b
       where b.stm_exercise_id = lExerciseId
         and a.exe_starting_exercise = b.exe_ending_exercise + 1;
    else
      -- si on a pas d'exercice actif, on prend le premier des exercices activables
      open lcurOpenableExercise;

      fetch lcurOpenableExercise
       into lNextExerId;

      close lcurOpenableExercise;
    end if;

    -- si il y a un exercice à activer
    if lNextExerId is not null then
      -- Recherche de la date début de l'exercice à activer                      12.03.98 sk
      select exe_starting_exercise
        into lExerStartingDate
        from stm_exercise
       where stm_exercise_id = lNextExerId;

      -- recherche de kl'id de la premiSre p'riode de l'exercice . activer
      select stm_period_id
        into lFirstPeriodId
        from stm_period
       where stm_exercise_id = lNextExerId
         and per_number = 1;

      -- recherche du type de mouvement qui correspond . une entr'e d'but exercice
      select STM_MOVEMENT_KIND_id
           , mok_financial_imputation
        into lMovementKindId
           , lFinancialCharging
        from STM_MOVEMENT_KIND
       where c_movement_sort = 'ENT'
         and c_movement_type = 'EXE'
         and c_movement_code = '004';

      -- mise à jour du flag indiquant que l'exercice est en cours d'ouverture
      update STM_EXERCISE
         set EXE_OPENING = 1
       where STM_EXERCISE_ID = lNextExerId;

      -- ouverture du curseur
      open lcurStockPositions(lNextExerId);

      -- positionnement sur le premier tuple du curseur
      fetch lcurStockPositions
      bulk collect into lttStockPosition;

      -- fermeture du curseur
      close lcurStockPositions;

      if lttStockPosition.count > 0 then
        -- boucle sur les valeurs du curseur
        for lCounter in lttStockPosition.first .. lttStockPosition.last loop
          if lOldGoodId <> lttStockPosition(lCounter).GCO_GOOD_ID then
            lPrice  := GCO_LIB_PRICE.GetCostPriceWithManagementMode(iGCO_GOOD_ID => lttStockPosition(lCounter).GCO_GOOD_ID, iDateRef => lExerStartingDate);
          end if;

          select INIT_ID_SEQ.nextval
            into lReportMovementId
            from dual;

          -- insertion de la postion point'e dans la table des mouvements de stock
          -- cette insertion va d'clancher les triggers relatifs . cette table
          STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lReportMovementId
                                          , iGoodId                => lttStockPosition(lCounter).GCO_GOOD_ID
                                          , iMovementKindId        => lMovementKindId
                                          , iExerciseId            => lNextExerId
                                          , iPeriodId              => lFirstPeriodId
                                          , iMvtDate               => lExerStartingDate
                                          , iValueDate             => lExerStartingDate
                                          , iStockId               => lttStockPosition(lCounter).STM_STOCK_ID
                                          , iLocationId            => lttStockPosition(lCounter).STM_LOCATION_ID
                                          , iThirdId               => null
                                          , iThirdAciId            => null
                                          , iThirdDeliveryId       => null
                                          , iThirdTariffId         => null
                                          , iRecordId              => null
                                          , iChar1Id               => lttStockPosition(lCounter).GCO_CHARACTERIZATION_ID
                                          , iChar2Id               => lttStockPosition(lCounter).GCO_GCO_CHARACTERIZATION_ID
                                          , iChar3Id               => lttStockPosition(lCounter).GCO2_GCO_CHARACTERIZATION_ID
                                          , iChar4Id               => lttStockPosition(lCounter).GCO3_GCO_CHARACTERIZATION_ID
                                          , iChar5Id               => lttStockPosition(lCounter).GCO4_GCO_CHARACTERIZATION_ID
                                          , iCharValue1            => lttStockPosition(lCounter).SPO_CHARACTERIZATION_VALUE_1
                                          , iCharValue2            => lttStockPosition(lCounter).SPO_CHARACTERIZATION_VALUE_2
                                          , iCharValue3            => lttStockPosition(lCounter).SPO_CHARACTERIZATION_VALUE_3
                                          , iCharValue4            => lttStockPosition(lCounter).SPO_CHARACTERIZATION_VALUE_4
                                          , iCharValue5            => lttStockPosition(lCounter).SPO_CHARACTERIZATION_VALUE_5
                                          , iMovement2Id           => null
                                          , iMovement3Id           => null
                                          , iWording               => 'Exercise opening'
                                          , iExternalDocument      => null
                                          , iExternalPartner       => null
                                          , iMvtQty                => lttStockPosition(lCounter).SPO_STOCK_QUANTITY
                                          , iMvtPrice              => lttStockPosition(lCounter).SPO_STOCK_QUANTITY * lPrice
                                          , iDocQty                => 0
                                          , iDocPrice              => 0
                                          , iUnitPrice             => lPrice
                                          , iRefUnitPrice          => lPrice
                                          , iAltQty1               => lttStockPosition(lCounter).SPO_ALTERNATIV_QUANTITY_1
                                          , iAltQty2               => lttStockPosition(lCounter).SPO_ALTERNATIV_QUANTITY_2
                                          , iAltQty3               => lttStockPosition(lCounter).SPO_ALTERNATIV_QUANTITY_3
                                          , iDocPositionDetailId   => null
                                          , iDocPositionId         => null
                                          , iFinancialAccountId    => null
                                          , iDivisionAccountId     => null
                                          , iAFinancialAccountId   => null
                                          , iADivisionAccountId    => null
                                          , iCPNAccountId          => null
                                          , iACPNAccountId         => null
                                          , iCDAAccountId          => null
                                          , iACDAAccountId         => null
                                          , iPFAccountId           => null
                                          , iAPFAccountId          => null
                                          , iPJAccountId           => null
                                          , iAPJAccountId          => null
                                          , iFamFixedAssetsId      => null
                                          , iFamTransactionTyp     => null
                                          , iHrmPersonId           => null
                                          , iDicImpfree1Id         => null
                                          , iDicImpfree2Id         => null
                                          , iDicImpfree3Id         => null
                                          , iDicImpfree4Id         => null
                                          , iDicImpfree5Id         => null
                                          , iImpText1              => null
                                          , iImpText2              => null
                                          , iImpText3              => null
                                          , iImpText4              => null
                                          , iImpText5              => null
                                          , iImpNumber1            => null
                                          , iImpNumber2            => null
                                          , iImpNumber3            => null
                                          , iImpNumber4            => null
                                          , iImpNumber5            => null
                                          , iFinancialCharging     => lFinancialCharging
                                          , iUpdateProv            => 0
                                          , iExtourneMvt           => 0
                                          , iRecStatus             => null
                                           );

          if mod(lCounter, 100) = 0 then
            commit;
          end if;

          lOldGoodId  := lttStockPosition(lCounter).GCO_GOOD_ID;
        end loop;
      end if;

      -- mise à jour du flag indiquant que l'ouverture de l'exercice est terminée
      update STM_EXERCISE
         set EXE_OPENING = 0
       where STM_EXERCISE_ID = lNextExerId;

      commit;
    end if;
  end stm_newexstkmvt;

  /**
  * Description
  *   procedure de création des informations de tracabilité liée au mouvements de transformation
  */
  procedure AddTrsfTracability(
    iMovementId in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , iCharId1    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId2    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId3    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId4    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId5    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iOldChar1   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iNewChar1   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iOldChar2   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iNewChar2   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iOldChar3   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iNewChar3   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iOldChar4   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iNewChar4   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iOldChar5   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iNewChar5   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  )
  is
    lOldPiece    STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldSet      STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldVersion  STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldChrono   STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewPiece    STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewSet      STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewVersion  STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewChrono   STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldStdChar1 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldStdChar2 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldStdChar3 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldStdChar4 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lOldStdChar5 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewStdChar1 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewStdChar2 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewStdChar3 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewStdChar4 STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lNewStdChar5 STM_ELEMENT_NUMBER.SEM_VALUE%type;
  begin
    -- Dénormalisation des anciennes valeur de caractérisation
    GCO_FUNCTIONS.ClassifyCharacterizations(iCharId1
                                          , iCharId2
                                          , iCharId3
                                          , iCharId4
                                          , iCharId5
                                          , iOldChar1
                                          , iOldChar2
                                          , iOldChar3
                                          , iOldChar4
                                          , iOldChar5
                                          , lOldPiece
                                          , lOldSet
                                          , lOldVersion
                                          , lOldChrono
                                          , lOldStdChar1
                                          , lOldStdChar2
                                          , lOldStdChar3
                                          , lOldStdChar4
                                          , lOldStdChar5
                                           );
    -- Dénormalisation des nouvelles valeur de caractérisation
    GCO_FUNCTIONS.ClassifyCharacterizations(iCharId1
                                          , iCharId2
                                          , iCharId3
                                          , iCharId4
                                          , iCharId5
                                          , iNewChar1
                                          , iNewChar2
                                          , iNewChar3
                                          , iNewChar4
                                          , iNewChar5
                                          , lNewPiece
                                          , lNewSet
                                          , lNewVersion
                                          , lNewChrono
                                          , lNewStdChar1
                                          , lNewStdChar2
                                          , lNewStdChar3
                                          , lNewStdChar4
                                          , lNewStdChar5
                                           );

    if    lNewPiece is not null
       or lNewSet is not null
       or lNewVersion is not null
       or lNewChrono is not null
       or lNewStdChar1 is not null
       or lNewStdChar2 is not null
       or lNewStdChar3 is not null
       or lNewStdChar4 is not null
       or lNewStdChar5 is not null then
      insert into FAL_TRACABILITY
                  (FAL_TRACABILITY_ID
                 , C_TRACABILITY_SOURCE
                 , HIS_FREE_TEXT
                 , STM_STOCK_MOVEMENT_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , HIS_PT_PIECE
                 , HIS_PT_LOT
                 , HIS_PT_VERSION
                 , HIS_CHRONOLOGY_PT
                 , HIS_PT_STD_CHAR_1
                 , HIS_PT_STD_CHAR_2
                 , HIS_PT_STD_CHAR_3
                 , HIS_PT_STD_CHAR_4
                 , HIS_PT_STD_CHAR_5
                 , HIS_CPT_PIECE
                 , HIS_CPT_LOT
                 , HIS_CPT_VERSION
                 , HIS_CHRONOLOGY_CPT
                 , HIS_CPT_STD_CHAR_1
                 , HIS_CPT_STD_CHAR_2
                 , HIS_CPT_STD_CHAR_3
                 , HIS_CPT_STD_CHAR_4
                 , HIS_CPT_STD_CHAR_5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , 'STM'
                 , PCS.PC_FUNCTIONS.TranslateWord('Transformation de caractérisation')
                 , iMovementId
                 , iGoodId
                 , iGoodId
                 , lNewPiece
                 , lNewSet
                 , lNewVersion
                 , lNewChrono
                 , lNewStdChar1
                 , lNewStdChar2
                 , lNewStdChar3
                 , lNewStdChar4
                 , lNewStdChar5
                 , lOldPiece
                 , lOldSet
                 , lOldVersion
                 , lOldChrono
                 , lOldStdChar1
                 , lOldStdChar2
                 , lOldStdChar3
                 , lOldStdChar4
                 , lOldStdChar5
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end AddTrsfTracability;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure pReverseMvt(
    iSTM_STOCK_MOVEMENT_ID in     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iTransfertMvt          in     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type default null
  , iNewMvt                out    STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iMvtQty                in     number
  , iUpdateProv            in     STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type default null
  , iCharValue1            in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue2            in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue3            in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue4            in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue5            in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iMvtDate               in     date
  , iValueDate             in     date default null
  , iPositionDetailId      in     STM_STOCK_MOVEMENT.DOC_POSITION_DETAIL_ID%type default null
  , iWording               in     STM_STOCK_MOVEMENT.SMO_WORDING%type default null
  )
  is
    ltplOriginMovement  STM_STOCK_MOVEMENT%rowtype;
    ltplReverseMovement STM_STOCK_MOVEMENT%rowtype;
  begin
    -- Récupération des infos du mouvement d'origine
    select *
      into ltplOriginMovement
      from STM_STOCK_MOVEMENT
     where STM_STOCK_MOVEMENT_ID = iSTM_STOCK_MOVEMENT_ID;

    iNewMvt                                         := getNewId;
    -- initialisation des données du nouveau mouvement
    ltplReverseMovement                             := ltplOriginMovement;
    ltplReverseMovement.STM_STOCK_MOVEMENT_ID       := iNewMvt;
    ltplReverseMovement.STM_STM_STOCK_MOVEMENT_ID   := iTransfertMvt;
    ltplReverseMovement.SMO_EXTOURNE_MVT            := 1;
    ltplReverseMovement.A_IDCRE                     := pcs.PC_I_LIB_SESSION.GetUserIni;
    ltplReverseMovement.A_DATECRE                   := sysdate;
    ltplReverseMovement.A_IDMOD                     := null;
    ltplReverseMovement.A_DATEMOD                   := null;

    -- en cas de solde, il arrive qu'on doive forcer cette valeur
    if iUpdateProv is not null then
      ltplReverseMovement.SMO_UPDATE_PROV  := iUpdateProv;
    end if;

    -- il arrive qu'après avoir utilisé l'assistant de caractérisation, on doive extourner des mouvements
    -- dont les valeurs de caractérisation soient N/A. Dans ce cas les bonne valeurs sont passées en paramètre
    if iCharValue1 is not null then
      ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_1  := iCharValue1;
      ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_2  := iCharValue2;
      ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_3  := iCharValue3;
      ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_4  := iCharValue4;
      ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_5  := iCharValue5;
    end if;

    -- Extourne Complète
    if nvl(iMvtQty, 0) = 0 then
      ltplReverseMovement.SMO_MOVEMENT_QUANTITY     := -ltplOriginMovement.SMO_MOVEMENT_QUANTITY;
      ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_1  := -ltplOriginMovement.SMO_MVT_ALTERNATIV_QTY_1;
      ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_2  := -ltplOriginMovement.SMO_MVT_ALTERNATIV_QTY_2;
      ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_3  := -ltplOriginMovement.SMO_MVT_ALTERNATIV_QTY_3;
      ltplReverseMovement.SMO_MOVEMENT_PRICE        := -ltplOriginMovement.SMO_MOVEMENT_PRICE;
      ltplReverseMovement.SMO_PRCS_VALUE            := -ltplOriginMovement.SMO_PRCS_VALUE;
      ltplReverseMovement.SMO_DOCUMENT_QUANTITY     := -ltplOriginMovement.SMO_DOCUMENT_QUANTITY;
      ltplReverseMovement.SMO_DOCUMENT_PRICE        := -ltplOriginMovement.SMO_DOCUMENT_PRICE;
    -- extourne partielle
    else
      ltplReverseMovement.SMO_MOVEMENT_QUANTITY  := -iMvtQty;

      if ltplOriginMovement.SMO_MOVEMENT_QUANTITY <> 0 then
        ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_1  := -(ltplOriginMovement.SMO_MVT_ALTERNATIV_QTY_1 * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY);
        ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_2  := -(ltplOriginMovement.SMO_MVT_ALTERNATIV_QTY_2 * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY);
        ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_3  := -(ltplOriginMovement.SMO_MVT_ALTERNATIV_QTY_3 * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY);
        ltplReverseMovement.SMO_MOVEMENT_PRICE        := -(ltplOriginMovement.SMO_MOVEMENT_PRICE * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY);
        ltplReverseMovement.SMO_PRCS_VALUE            := -(ltplOriginMovement.SMO_PRCS_VALUE * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY);
        ltplReverseMovement.SMO_DOCUMENT_QUANTITY     := -(ltplOriginMovement.SMO_DOCUMENT_QUANTITY * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY);
        ltplReverseMovement.SMO_DOCUMENT_PRICE        := -(ltplOriginMovement.SMO_DOCUMENT_PRICE * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY);
      else
        return;
      end if;
    end if;

    ltplReverseMovement.STM2_STM_STOCK_MOVEMENT_ID  := iSTM_STOCK_MOVEMENT_ID;   -- STM2_STM_STOCK_MOVEMENT_ID (liaison avec le mouvement extourné)

    -- override du libellé
    if iWording is not null then
      ltplReverseMovement.SMO_WORDING  := iWording;
    end if;

    -- override de la référence à un détail de position
    if iPositionDetailId is not null then
      ltplReverseMovement.DOC_POSITION_DETAIL_ID  := iPositionDetailId;
    end if;

    -- sauf pour les mouvements issus d'un document logistique, l'order key doit être égale à l'id du mouvement (DEVLOG-16209)
    if ltplReverseMovement.DOC_POSITION_DETAIL_ID is null then
      ltplReverseMovement.SMO_MOVEMENT_ORDER_KEY  := ltplReverseMovement.STM_STOCK_MOVEMENT_ID;
      ltplReverseMovement.SMO_VALUE_DATE          := ltplReverseMovement.SMO_MOVEMENT_DATE;
    end if;

    begin
      if nvl(ltplReverseMovement.STM_STOCK_MOVEMENT_ID, 0) <> 0 then
        -- création du nouveau mouvement
        GenerateMovement(ioStockMovementId      => ltplReverseMovement.STM_STOCK_MOVEMENT_ID
                       , iGoodId                => ltplReverseMovement.GCO_GOOD_ID
                       , iMovementKindId        => ltplReverseMovement.STM_MOVEMENT_KIND_ID
                       , iMvtDate               => iMvtDate
                       , iValueDate             => nvl(iValueDate, ltplReverseMovement.SMO_VALUE_DATE)
                       , iStockId               => ltplReverseMovement.STM_STOCK_ID
                       , iLocationId            => ltplReverseMovement.STM_LOCATION_ID
                       , iThirdId               => ltplReverseMovement.PAC_THIRD_ID
                       , iThirdAciId            => ltplReverseMovement.PAC_THIRD_ACI_ID
                       , iThirdDeliveryId       => ltplReverseMovement.PAC_THIRD_DELIVERY_ID
                       , iThirdTariffId         => ltplReverseMovement.PAC_THIRD_TARIFF_ID
                       , iRecordId              => ltplReverseMovement.DOC_RECORD_ID
                       , iChar1Id               => ltplReverseMovement.GCO_CHARACTERIZATION_ID
                       , iChar2Id               => ltplReverseMovement.GCO_GCO_CHARACTERIZATION_ID
                       , iChar3Id               => ltplReverseMovement.GCO2_GCO_CHARACTERIZATION_ID
                       , iChar4Id               => ltplReverseMovement.GCO3_GCO_CHARACTERIZATION_ID
                       , iChar5Id               => ltplReverseMovement.GCO4_GCO_CHARACTERIZATION_ID
                       , iCharValue1            => ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_1
                       , iCharValue2            => ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_2
                       , iCharValue3            => ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_3
                       , iCharValue4            => ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_4
                       , iCharValue5            => ltplReverseMovement.SMO_CHARACTERIZATION_VALUE_5
                       , iMovement2Id           => ltplReverseMovement.STM_STM_STOCK_MOVEMENT_ID
                       , iMovement3Id           => ltplReverseMovement.STM2_STM_STOCK_MOVEMENT_ID
                       , iWording               => ltplReverseMovement.SMO_WORDING
                       , iExternalDocument      => ltplReverseMovement.SMO_EXTERNAL_DOCUMENT
                       , iExternalPartner       => ltplReverseMovement.SMO_EXTERNAL_PARTNER
                       , iMvtQty                => ltplReverseMovement.SMO_MOVEMENT_QUANTITY
                       , iMvtPrice              => ltplReverseMovement.SMO_MOVEMENT_PRICE
                       , iDocQty                => ltplReverseMovement.SMO_DOCUMENT_QUANTITY
                       , iDocPrice              => ltplReverseMovement.SMO_DOCUMENT_PRICE
                       , iUnitPrice             => ltplReverseMovement.SMO_UNIT_PRICE
                       , iRefUnitPrice          => ltplReverseMovement.SMO_REFERENCE_UNIT_PRICE
                       , iAltQty1               => ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_1
                       , iAltQty2               => ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_2
                       , iAltQty3               => ltplReverseMovement.SMO_MVT_ALTERNATIV_QTY_3
                       , iDocPositionDetailId   => ltplReverseMovement.DOC_POSITION_DETAIL_ID
                       , iDocPositionId         => ltplReverseMovement.DOC_POSITION_ID
                       , iFinancialAccountId    => ltplReverseMovement.ACS_FINANCIAL_ACCOUNT_ID
                       , iDivisionAccountId     => ltplReverseMovement.ACS_DIVISION_ACCOUNT_ID
                       , iAFinancialAccountId   => ltplReverseMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID
                       , iADivisionAccountId    => ltplReverseMovement.ACS_ACS_DIVISION_ACCOUNT_ID
                       , iCPNAccountId          => ltplReverseMovement.ACS_CPN_ACCOUNT_ID
                       , iACPNAccountId         => ltplReverseMovement.ACS_ACS_CPN_ACCOUNT_ID
                       , iCDAAccountId          => ltplReverseMovement.ACS_CDA_ACCOUNT_ID
                       , iACDAAccountId         => ltplReverseMovement.ACS_ACS_CDA_ACCOUNT_ID
                       , iPFAccountId           => ltplReverseMovement.ACS_PF_ACCOUNT_ID
                       , iAPFAccountId          => ltplReverseMovement.ACS_ACS_PF_ACCOUNT_ID
                       , iPJAccountId           => ltplReverseMovement.ACS_PJ_ACCOUNT_ID
                       , iAPJAccountId          => ltplReverseMovement.ACS_ACS_PJ_ACCOUNT_ID
                       , iFamFixedAssetsId      => ltplReverseMovement.FAM_FIXED_ASSETS_ID
                       , iFamTransactionTyp     => ltplReverseMovement.C_FAM_TRANSACTION_TYP
                       , iHrmPersonId           => ltplReverseMovement.HRM_PERSON_ID
                       , iDicImpfree1Id         => ltplReverseMovement.DIC_IMP_FREE1_ID
                       , iDicImpfree2Id         => ltplReverseMovement.DIC_IMP_FREE2_ID
                       , iDicImpfree3Id         => ltplReverseMovement.DIC_IMP_FREE3_ID
                       , iDicImpfree4Id         => ltplReverseMovement.DIC_IMP_FREE4_ID
                       , iDicImpfree5Id         => ltplReverseMovement.DIC_IMP_FREE5_ID
                       , iImpText1              => ltplReverseMovement.SMO_IMP_TEXT_1
                       , iImpText2              => ltplReverseMovement.SMO_IMP_TEXT_2
                       , iImpText3              => ltplReverseMovement.SMO_IMP_TEXT_3
                       , iImpText4              => ltplReverseMovement.SMO_IMP_TEXT_4
                       , iImpText5              => ltplReverseMovement.SMO_IMP_TEXT_5
                       , iImpNumber1            => ltplReverseMovement.SMO_IMP_NUMBER_1
                       , iImpNumber2            => ltplReverseMovement.SMO_IMP_NUMBER_2
                       , iImpNumber3            => ltplReverseMovement.SMO_IMP_NUMBER_3
                       , iImpNumber4            => ltplReverseMovement.SMO_IMP_NUMBER_4
                       , iImpNumber5            => ltplReverseMovement.SMO_IMP_NUMBER_5
                       , iFinancialCharging     => ltplReverseMovement.SMO_FINANCIAL_CHARGING
                       , iUpdateProv            => ltplReverseMovement.SMO_UPDATE_PROV
                       , iExtourneMvt           => ltplReverseMovement.SMO_EXTOURNE_MVT
                       , iRecStatus             => ltplReverseMovement.A_RECSTATUS
                       , iOrderKey              => ltplReverseMovement.SMO_MOVEMENT_ORDER_KEY
                       , iDocFootAlloyID        => ltplReverseMovement.DOC_FOOT_ALLOY_ID
                       , iInventoryMvt          => 0   -- InventoryMvt        in     number default 0
                       , iIntervDetID           => ltplReverseMovement.ASA_INTERVENTION_DETAIL_ID
                       , iSmoPrcsValue          => ltplReverseMovement.SMO_PRCS_VALUE
                        );
        -- mise à jour du lien d'extourne
        UpdateReverseLink(ltplReverseMovement);

        if     ltplReverseMovement.DOC_POSITION_ID is not null
           and ltplReverseMovement.DOC_POSITION_ALLOY_ID is null then
          -- Si le gabarit prévoit des mouvements de type matières précieuses
          if     DOC_I_LIB_ALLOY.IsAlloyMvtOnPos(ltplReverseMovement.DOC_POSITION_ID) > 0
             and ltplOriginMovement.SMO_MOVEMENT_QUANTITY <> 0 then
            -- curseur sur les mouvements matières précieuses effectués par la position
            for ltplAlloyToExtourne in (select   SMO.STM_STOCK_MOVEMENT_ID
                                               , SMO.SMO_MOVEMENT_QUANTITY * iMvtQty / ltplOriginMovement.SMO_MOVEMENT_QUANTITY SMO_MOVEMENT_QUANTITY
                                            from STM_STOCK_MOVEMENT SMO
                                           where SMO.DOC_POSITION_ALLOY_ID is not null
                                             and SMO.DOC_POSITION_ID = ltplReverseMovement.DOC_POSITION_ID
                                             and STM_I_LIB_MOVEMENT.IsPreciousMatMovement(SMO.STM_MOVEMENT_KIND_ID) = 1
                                             and SMO.SMO_EXTOURNE_MVT = 0
                                        order by SMO.GCO_GOOD_ID
                                               , SMO.SMO_CHARACTERIZATION_VALUE_1
                                               , SMO.SMO_CHARACTERIZATION_VALUE_2
                                               , SMO.SMO_CHARACTERIZATION_VALUE_3
                                               , SMO.SMO_CHARACTERIZATION_VALUE_4
                                               , SMO.SMO_CHARACTERIZATION_VALUE_5) loop
              STM_PRC_MOVEMENT.GenerateReversalMvt(iSTM_STOCK_MOVEMENT_ID   => ltplAlloyToExtourne.STM_STOCK_MOVEMENT_ID
                                                 , iMvtQty                  => ltplAlloyToExtourne.SMO_MOVEMENT_QUANTITY
                                                 , iUpdateProv              => 0
                                                 , iMvtDate                 => iMvtDate
                                                 , iValueDate               => iValueDate
                                                  );
            end loop;
          end if;
        end if;
      end if;
    end;
  end pReverseMvt;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure CloneMvt(iSTM_STOCK_MOVEMENT_ID in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type, iNewMvt out STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type)
  is
    ltplOriginMovement STM_STOCK_MOVEMENT%rowtype;
    ltpClonedMovement  STM_STOCK_MOVEMENT%rowtype;
  begin
    -- Récupération des infos du mouvement d'origine
    select *
      into ltplOriginMovement
      from STM_STOCK_MOVEMENT
     where STM_STOCK_MOVEMENT_ID = iSTM_STOCK_MOVEMENT_ID;

    iNewMvt                                  := getNewId;
    -- initialisation des données du nouveau mouvement
    ltpClonedMovement                        := ltplOriginMovement;
    ltpClonedMovement.STM_STOCK_MOVEMENT_ID  := iNewMvt;
    ltpClonedMovement.A_IDCRE                := pcs.PC_I_LIB_SESSION.GetUserIni;
    ltpClonedMovement.A_DATECRE              := sysdate;
    ltpClonedMovement.A_IDMOD                := null;
    ltpClonedMovement.A_DATEMOD              := null;

    begin
      if nvl(ltpClonedMovement.STM_STOCK_MOVEMENT_ID, 0) <> 0 then
        -- création du nouveau mouvement
        GenerateMovement(ltpClonedMovement.STM_STOCK_MOVEMENT_ID
                       , ltpClonedMovement.GCO_GOOD_ID
                       , ltpClonedMovement.STM_MOVEMENT_KIND_ID
                       , ltpClonedMovement.STM_EXERCISE_ID
                       , ltpClonedMovement.STM_PERIOD_ID
                       , ltpClonedMovement.SMO_MOVEMENT_DATE
                       , ltpClonedMovement.SMO_VALUE_DATE
                       , ltpClonedMovement.STM_STOCK_ID
                       , ltpClonedMovement.STM_LOCATION_ID
                       , ltpClonedMovement.PAC_THIRD_ID
                       , ltpClonedMovement.PAC_THIRD_ACI_ID
                       , ltpClonedMovement.PAC_THIRD_DELIVERY_ID
                       , ltpClonedMovement.PAC_THIRD_TARIFF_ID
                       , ltpClonedMovement.DOC_RECORD_ID
                       , ltpClonedMovement.GCO_CHARACTERIZATION_ID
                       , ltpClonedMovement.GCO_GCO_CHARACTERIZATION_ID
                       , ltpClonedMovement.GCO2_GCO_CHARACTERIZATION_ID
                       , ltpClonedMovement.GCO3_GCO_CHARACTERIZATION_ID
                       , ltpClonedMovement.GCO4_GCO_CHARACTERIZATION_ID
                       , ltpClonedMovement.SMO_CHARACTERIZATION_VALUE_1
                       , ltpClonedMovement.SMO_CHARACTERIZATION_VALUE_2
                       , ltpClonedMovement.SMO_CHARACTERIZATION_VALUE_3
                       , ltpClonedMovement.SMO_CHARACTERIZATION_VALUE_4
                       , ltpClonedMovement.SMO_CHARACTERIZATION_VALUE_5
                       , ltpClonedMovement.STM_STM_STOCK_MOVEMENT_ID
                       , ltpClonedMovement.STM2_STM_STOCK_MOVEMENT_ID
                       , ltpClonedMovement.SMO_WORDING
                       , ltpClonedMovement.SMO_EXTERNAL_DOCUMENT
                       , ltpClonedMovement.SMO_EXTERNAL_PARTNER
                       , ltpClonedMovement.SMO_MOVEMENT_QUANTITY
                       , ltpClonedMovement.SMO_MOVEMENT_PRICE
                       , ltpClonedMovement.SMO_DOCUMENT_QUANTITY
                       , ltpClonedMovement.SMO_DOCUMENT_PRICE
                       , ltpClonedMovement.SMO_UNIT_PRICE
                       , ltpClonedMovement.SMO_REFERENCE_UNIT_PRICE
                       , ltpClonedMovement.SMO_MVT_ALTERNATIV_QTY_1
                       , ltpClonedMovement.SMO_MVT_ALTERNATIV_QTY_2
                       , ltpClonedMovement.SMO_MVT_ALTERNATIV_QTY_3
                       , ltpClonedMovement.DOC_POSITION_DETAIL_ID
                       , ltpClonedMovement.DOC_POSITION_ID
                       , ltpClonedMovement.ACS_FINANCIAL_ACCOUNT_ID
                       , ltpClonedMovement.ACS_DIVISION_ACCOUNT_ID
                       , ltpClonedMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID
                       , ltpClonedMovement.ACS_ACS_DIVISION_ACCOUNT_ID
                       , ltpClonedMovement.ACS_CPN_ACCOUNT_ID
                       , ltpClonedMovement.ACS_ACS_CPN_ACCOUNT_ID
                       , ltpClonedMovement.ACS_CDA_ACCOUNT_ID
                       , ltpClonedMovement.ACS_ACS_CDA_ACCOUNT_ID
                       , ltpClonedMovement.ACS_PF_ACCOUNT_ID
                       , ltpClonedMovement.ACS_ACS_PF_ACCOUNT_ID
                       , ltpClonedMovement.ACS_PJ_ACCOUNT_ID
                       , ltpClonedMovement.ACS_ACS_PJ_ACCOUNT_ID
                       , ltpClonedMovement.FAM_FIXED_ASSETS_ID
                       , ltpClonedMovement.C_FAM_TRANSACTION_TYP
                       , ltpClonedMovement.HRM_PERSON_ID
                       , ltpClonedMovement.DIC_IMP_FREE1_ID
                       , ltpClonedMovement.DIC_IMP_FREE2_ID
                       , ltpClonedMovement.DIC_IMP_FREE3_ID
                       , ltpClonedMovement.DIC_IMP_FREE4_ID
                       , ltpClonedMovement.DIC_IMP_FREE5_ID
                       , ltpClonedMovement.SMO_IMP_TEXT_1
                       , ltpClonedMovement.SMO_IMP_TEXT_2
                       , ltpClonedMovement.SMO_IMP_TEXT_3
                       , ltpClonedMovement.SMO_IMP_TEXT_4
                       , ltpClonedMovement.SMO_IMP_TEXT_5
                       , ltpClonedMovement.SMO_IMP_NUMBER_1
                       , ltpClonedMovement.SMO_IMP_NUMBER_2
                       , ltpClonedMovement.SMO_IMP_NUMBER_3
                       , ltpClonedMovement.SMO_IMP_NUMBER_4
                       , ltpClonedMovement.SMO_IMP_NUMBER_5
                       , ltpClonedMovement.SMO_FINANCIAL_CHARGING
                       , ltpClonedMovement.SMO_UPDATE_PROV
                       , ltpClonedMovement.SMO_EXTOURNE_MVT
                       , ltpClonedMovement.A_RECSTATUS
                       , ltpClonedMovement.SMO_MOVEMENT_ORDER_KEY
                       , ltpClonedMovement.DOC_FOOT_ALLOY_ID
                       , 0   -- InventoryMvt        in     number default 0
                       , ltpClonedMovement.ASA_INTERVENTION_DETAIL_ID
                        );
      end if;
--     exception
--       when others then
--         raise_application_error(-20900
--                               , pcs.pc_functions.TranslateWord('Erreur lors du clonage du mouvement de stock')
--                                );
    end;
  end CloneMvt;

  /**
  * Description
  *   Procédure d'extourne du mouvement passé en paramètre
  */
  procedure GenerateReversalMvt(
    iSTM_STOCK_MOVEMENT_ID in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iMvtQty                in number default null
  , iDisableKLSExport      in integer default 0
  , iUpdateProv            in STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type default null
  , iCharValue1            in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue2            in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue3            in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue4            in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue5            in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , iMvtDate               in date default trunc(sysdate)
  , iValueDate             in date default null
  , iPositionDetailId      in STM_STOCK_MOVEMENT.DOC_POSITION_DETAIL_ID%type default null
  , iWording               in STM_STOCK_MOVEMENT.SMO_WORDING%type default null
  )
  is
    lTransferMvtId STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type;
    lMovementSort  STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lNewMvt        STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lNewMvt2       STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    select nvl(SMO.STM_STM_STOCK_MOVEMENT_ID, 0)
         , MOK.C_MOVEMENT_SORT
      into lTransferMvtId
         , lMovementSort
      from STM_STOCK_MOVEMENT SMO
         , STM_MOVEMENT_KIND MOK
     where SMO.STM_STOCK_MOVEMENT_ID = iSTM_STOCK_MOVEMENT_ID
       and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID;

    -- Si mouvement de transfert et le "premier mouvement" est une entrée
    -- alors extourne du second mouvement en premier
    if     (lTransferMvtId <> 0)
       and (lMovementSort = 'ENT') then
      pReverseMvt(iSTM_STOCK_MOVEMENT_ID   => lTransferMvtId
                , iTransfertMvt            => lNewMvt
                , iNewMvt                  => lNewMvt2
                , iMvtQty                  => iMvtQty
                , iUpdateProv              => iUpdateProv
                , iMvtDate                 => iMvtDate
                , iPositionDetailId        => iPositionDetailId
                , iWording                 => iWording
                 );

      if iDisableKLSExport = 1 then
        FAL_STOCK_MOVEMENT_FUNCTIONS.UpdateKLSBuffer(lNewMvt2);
      end if;
    end if;

    pReverseMvt(iSTM_STOCK_MOVEMENT_ID   => iSTM_STOCK_MOVEMENT_ID
              , iTransfertMvt            => null
              , iNewMvt                  => lNewMvt
              , iMvtQty                  => iMvtQty
              , iUpdateProv              => iUpdateProv
              , iMvtDate                 => iMvtDate
              , iPositionDetailId        => iPositionDetailId
              , iWording                 => iWording
               );

    if iDisableKLSExport = 1 then
      FAL_STOCK_MOVEMENT_FUNCTIONS.UpdateKLSBuffer(lNewMvt);
    end if;

    -- Si mouvement de transfert et le "premier mouvement" est une entrée
    -- alors extourne du second mouvement en second
    if     (lTransferMvtId <> 0)
       and (lMovementSort = 'SOR') then
      pReverseMvt(iSTM_STOCK_MOVEMENT_ID   => lTransferMvtId
                , iTransfertMvt            => lNewMvt
                , iNewMvt                  => lNewMvt2
                , iMvtQty                  => iMvtQty
                , iUpdateProv              => iUpdateProv
                , iMvtDate                 => iMvtDate
                , iPositionDetailId        => iPositionDetailId
                , iWording                 => iWording
                 );

      if iDisableKLSExport = 1 then
        FAL_STOCK_MOVEMENT_FUNCTIONS.UpdateKLSBuffer(lNewMvt2);
      end if;
    end if;
  end GenerateReversalMvt;

  /**
  * for a given movement rexecute updates without inserting movement
  * @created fp 28.10.2009
  * @lastUpdate
  * @public
  * @param
  */
  procedure RedoStockMovement(iStockMovementId in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type)
  is
  begin
    declare
      ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmStockMovement, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY.load(ltCRUD_DEF, iStockMovementId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_CONFIRM', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end;
  end RedoStockMovement;

  /**
  * Description
  *   Set transgert id in the first movement of a tranfert
  */
  procedure UpdateTransfertLink(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
  begin
    if nvl(iotMovementRecord.STM_STM_STOCK_MOVEMENT_ID, 0) <> 0 then
      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_STM_ENTITY.gcStmStockMovement
                           , iot_crud_definition   => ltCRUD_DEF
                           , iv_primary_col        => 'STM_STOCK_MOVEMENT_ID'
                            );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', iotMovementRecord.STM_STM_STOCK_MOVEMENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STM_STOCK_MOVEMENT_ID', iotMovementRecord.STM_STOCK_MOVEMENT_ID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;
    end if;
  end UpdateTransfertLink;

  /**
  * Description
  *   Store original values of movement
  */
  procedure InitOriginalValues(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
  begin
    iotMovementRecord.SMO_MOVEMENT_PRICE_ORIG        := iotMovementRecord.SMO_MOVEMENT_PRICE;
    iotMovementRecord.SMO_UNIT_PRICE_ORIG            := iotMovementRecord.SMO_UNIT_PRICE;
    iotMovementRecord.SMO_REFERENCE_UNIT_PRICE_ORIG  := iotMovementRecord.SMO_REFERENCE_UNIT_PRICE;
    iotMovementRecord.SMO_PRCS_VALUE_ORIG            := iotMovementRecord.SMO_PRCS_VALUE;
  end InitOriginalValues;

  /**
  * Description
  *   Init default values of movement
  */
  procedure InitDefaultValues(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
  begin
    -- initialise le champ d'extourne si donné à null
    if iotMovementRecord.SMO_EXTOURNE_MVT is null then
      iotMovementRecord.SMO_EXTOURNE_MVT  := sign(nvl(iotMovementRecord.STM2_STM_STOCK_MOVEMENT_ID, 0) );
    end if;

    -- Pour les mouvements sur stock virtuel, on ne met pas à jour le PRCS (DEVLOG-15892)
    if STM_LIB_STOCK.IsVirtual(iotMovementRecord.STM_STOCK_ID) = 1 then
      iotMovementRecord.SMO_UPDATE_PRCS  := 0;
    end if;
  end InitDefaultValues;

  /**
  * Description
  *   Init id du lot pour les mouvements fabrication
  */
  procedure InitLotId(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lcMovementKindId STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lnResult         number(1);
  begin
    -- Le lot est spécifié dans les mouvements uniquement quand le mouvement
    -- est de type 'Fabrication'
    lcMovementKindId  := iotMovementRecord.STM_MOVEMENT_KIND_ID;

    -- Mouvement de type fabrication
    begin
      select 1
        into lnResult
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = lcMovementKindId
         and C_MOVEMENT_TYPE = 'FAC';   -- Fabrication
    exception
      when no_data_found then
        iotMovementRecord.FAL_LOT_ID  := null;
    end;
  end InitLotId;

  /**
  * procedure AddNonAllowedMvt
  * Description
  *   Ajout d'un type de mvt dans la table des mvts non-autorisés
  */
  procedure AddNonAllowedMvt(
    iMovementKindID  in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , iStockID         in STM_STOCK.STM_STOCK_ID%type default null
  , iQualityStatusID in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type default null
  )
  is
    ltNonAllowedMvt FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmNonAllowedMovements, ltNonAllowedMvt, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNonAllowedMvt, 'STM_MOVEMENT_KIND_ID', iMovementKindID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNonAllowedMvt, 'STM_STOCK_ID', iStockID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNonAllowedMvt, 'GCO_QUALITY_STATUS_ID', iQualityStatusID);
    FWK_I_MGT_ENTITY.InsertEntity(ltNonAllowedMvt);
    FWK_I_MGT_ENTITY.Release(ltNonAllowedMvt);
  end AddNonAllowedMvt;

  /**
  * procedure DeleteNonAllowedMvt
  * Description
  *   Effacement d'un type de mvt non-autorisé
  */
  procedure DeleteNonAllowedMvt(
    iMovementKindID  in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , iStockID         in STM_STOCK.STM_STOCK_ID%type default null
  , iQualityStatusID in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type default null
  )
  is
    ltNonAllowedMvt FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmNonAllowedMovements, ltNonAllowedMvt, true);

    for ltplNonAllowedMvt in (select   STM_NON_ALLOWED_MOVEMENTS_ID
                                  from STM_NON_ALLOWED_MOVEMENTS
                                 where STM_MOVEMENT_KIND_ID = iMovementKindID
                                   and nvl(iStockID, -1) = nvl(STM_STOCK_ID, -1)
                                   and nvl(iQualityStatusID, -1) = nvl(GCO_QUALITY_STATUS_ID, -1)
                              order by STM_NON_ALLOWED_MOVEMENTS_ID) loop
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNonAllowedMvt, 'STM_NON_ALLOWED_MOVEMENTS_ID', ltplNonAllowedMvt.STM_NON_ALLOWED_MOVEMENTS_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltNonAllowedMvt);
    end loop;

    FWK_I_MGT_ENTITY.Release(ltNonAllowedMvt);
  end DeleteNonAllowedMvt;

  /**
  * function GetCharConcatUniqueKey
  * Description
  *   Retourne la concaténation des champs
  *     C_CHARACT_TYPE/CHA_CHARACTERIZATION_DESIGN/C_CHRONOLOGY_TYPE/C_UNIT_OF_TIME
  */
  function GetCharConcatUniqueKey(iCharID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return varchar2
  is
    lvCharUniqueKey varchar2(100) := null;
  begin
    if iCharID is not null then
      -- Concatener les valeurs de la caractérisation pour définir la Unique key
      select lpad(C_CHARACT_TYPE, 10, '0') ||
             '/' ||
             lpad(CHA_CHARACTERIZATION_DESIGN, 30, '0') ||
             '/' ||
             lpad(nvl(C_CHRONOLOGY_TYPE, '0'), 10, '0') ||
             '/' ||
             lpad(nvl(C_UNIT_OF_TIME, '0'), 10, '0') as CHAR_UNIQUE_KEY
        into lvCharUniqueKey
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = iCharID;
    end if;

    return lvCharUniqueKey;
  end;

  /**
  * function pGetMatchCharIndex
  * Description
  *   Retourne l'indice d'une caractérisatin sur un produit par rapport
  *     à la même caractérisation sur un 2eme produit
  */
  function pGetMatchCharIndex(
    iCharID  in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharID1 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharID2 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharID3 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharID4 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharID5 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  )
    return integer
  is
    lnIndex         integer       := 0;
    lvCharUniqueKey varchar2(100);
  begin
    -- Caractérisation pour laquelle on va rechercher l'indice sur un autre produit
    if iCharID is not null then
      -- Valeur unique pour la caractérisation courante (concaténation de champs)
      lvCharUniqueKey  := GetCharConcatUniqueKey(iCharID);

      -- Caractérisation correspond à la caractérisation 1 des params
      if lvCharUniqueKey = GetCharConcatUniqueKey(iCharID1) then
        lnIndex  := 1;
      -- Caractérisation correspond à la caractérisation 2 des params
      elsif lvCharUniqueKey = GetCharConcatUniqueKey(iCharID2) then
        lnIndex  := 2;
      -- Caractérisation correspond à la caractérisation 3 des params
      elsif lvCharUniqueKey = GetCharConcatUniqueKey(iCharID3) then
        lnIndex  := 3;
      -- Caractérisation correspond à la caractérisation 4 des params
      elsif lvCharUniqueKey = GetCharConcatUniqueKey(iCharID4) then
        lnIndex  := 4;
      -- Caractérisation correspond à la caractérisation 5 des params
      elsif lvCharUniqueKey = GetCharConcatUniqueKey(iCharID5) then
        lnIndex  := 5;
      end if;
    end if;

    return lnIndex;
  end pGetMatchCharIndex;

  -- Reprise des valeurs de caractérisation du produit source pour le produit cible
  procedure pInitCharValuesBetweenGoods(
    iFromCharValue1   in     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iFromCharValue2   in     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , iFromCharValue3   in     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , iFromCharValue4   in     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , iFromCharValue5   in     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  , iToChar1FromIndex in     integer
  , iToChar2FromIndex in     integer
  , iToChar3FromIndex in     integer
  , iToChar4FromIndex in     integer
  , iToChar5FromIndex in     integer
  , oToCharValue1     out    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , oToCharValue2     out    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , oToCharValue3     out    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , oToCharValue4     out    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , oToCharValue5     out    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  )
  is
  begin
    -- Init de la valeur de caract 1 du bien cible en fonction de l'indice de la caract du bien source
    case iToChar1FromIndex
      when 1 then
        oToCharValue1  := iFromCharValue1;
      when 2 then
        oToCharValue1  := iFromCharValue2;
      when 3 then
        oToCharValue1  := iFromCharValue3;
      when 4 then
        oToCharValue1  := iFromCharValue4;
      when 5 then
        oToCharValue1  := iFromCharValue5;
      else
        null;
    end case;

    -- Init de la valeur de caract 2 du bien cible en fonction de l'indice de la caract du bien source
    case iToChar2FromIndex
      when 1 then
        oToCharValue2  := iFromCharValue1;
      when 2 then
        oToCharValue2  := iFromCharValue2;
      when 3 then
        oToCharValue2  := iFromCharValue3;
      when 4 then
        oToCharValue2  := iFromCharValue4;
      when 5 then
        oToCharValue2  := iFromCharValue5;
      else
        null;
    end case;

    -- Init de la valeur de caract 3 du bien cible en fonction de l'indice de la caract du bien source
    case iToChar3FromIndex
      when 1 then
        oToCharValue3  := iFromCharValue1;
      when 2 then
        oToCharValue3  := iFromCharValue2;
      when 3 then
        oToCharValue3  := iFromCharValue3;
      when 4 then
        oToCharValue3  := iFromCharValue4;
      when 5 then
        oToCharValue3  := iFromCharValue5;
      else
        null;
    end case;

    -- Init de la valeur de caract 4 du bien cible en fonction de l'indice de la caract du bien source
    case iToChar4FromIndex
      when 1 then
        oToCharValue4  := iFromCharValue1;
      when 2 then
        oToCharValue4  := iFromCharValue2;
      when 3 then
        oToCharValue4  := iFromCharValue3;
      when 4 then
        oToCharValue4  := iFromCharValue4;
      when 5 then
        oToCharValue4  := iFromCharValue5;
      else
        null;
    end case;

    -- Init de la valeur de caract 5 du bien cible en fonction de l'indice de la caract du bien source
    case iToChar5FromIndex
      when 1 then
        oToCharValue5  := iFromCharValue1;
      when 2 then
        oToCharValue5  := iFromCharValue2;
      when 3 then
        oToCharValue5  := iFromCharValue3;
      when 4 then
        oToCharValue5  := iFromCharValue4;
      when 5 then
        oToCharValue5  := iFromCharValue5;
      else
        null;
    end case;
  end pInitCharValuesBetweenGoods;

  /**
  * procedure SynchronizeProductStock
  * Description
  *   Transfert du stock public d'un produit/version source sur un autre produit/version
  *     dans le cadre du versionning des produits
  */
  procedure SynchronizeProductStock(
    iFromGoodID  in GCO_GOOD.GCO_GOOD_ID%type
  , iFromVersion in STM_STOCK_POSITION.SPO_VERSION%type
  , iToGoodID    in GCO_GOOD.GCO_GOOD_ID%type
  , iToVersion   in STM_STOCK_POSITION.SPO_VERSION%type
  )
  is
    lFromCharID1        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lFromCharID2        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lFromCharID3        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lFromCharID4        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lFromCharID5        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lToVersionIndice    integer;
    lToCharID1          GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lToCharID2          GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lToCharID3          GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lToCharID4          GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lToCharID5          GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lToCharValue1       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lToCharValue2       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type;
    lToCharValue3       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type;
    lToCharValue4       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type;
    lToCharValue5       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type;
    lElementNumberId    STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lOutputKindId       STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lInputKindId        STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lInputStkMvtID      STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lOutputStkMvID      STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lExerciseId         STM_EXERCISE.STM_EXERCISE_ID%type;
    lPeriodId           STM_PERIOD.STM_PERIOD_ID%type;
    lMvtDate            date;
    lvMessage           varchar2(32000);
    lvWording           STM_STOCK_MOVEMENT.SMO_WORDING%type;
    lvFromGoodReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lvToGoodReference   GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lnToChar1FromIndex  integer;
    lnToChar2FromIndex  integer;
    lnToChar3FromIndex  integer;
    lnToChar4FromIndex  integer;
    lnToChar5FromIndex  integer;
  begin
    -- Rechercher les ids des caractérisation du bien cible
    GCO_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => iToGoodID
                                           , iNoStkChar     => 1
                                           , oCharactID_1   => lToCharID1
                                           , oCharactID_2   => lToCharID2
                                           , oCharactID_3   => lToCharID3
                                           , oCharactID_4   => lToCharID4
                                           , oCharactID_5   => lToCharID5
                                            );
    -- indice de la caracterisation portant le versioning
    lToVersionIndice     :=
      nvl(GCO_LIB_CHARACTERIZATION.GetVersioningIndice(iGoodID       => iToGoodID
                                                     , iCharact1Id   => lToCharID1
                                                     , iCharact2Id   => lToCharID2
                                                     , iCharact3Id   => lToCharID3
                                                     , iCharact4Id   => lToCharID4
                                                     , iCharact5Id   => lToCharID5
                                                      )
        , 0
         );

    -- S'il s'agit de 2 biens différents, contrôler que le jeu de caractérisations soit identique entre ces 2 biens
    if iFromGoodID <> iToGoodID then
      declare
        lnCharDiff integer;
      begin
        -- Vérifier si le jeu de caractérisations est identique
        --  à l'exception du type Version si demandé par la config
        select nvl(max(1), 0) as CHAR_DIFF
          into lnCharDiff
          from (select   count(*)
                    from (select GetCharConcatUniqueKey(CHA.GCO_CHARACTERIZATION_ID) as CHAR_UNIQUE_KEY
                            from GCO_CHARACTERIZATION CHA
                           where CHA.GCO_GOOD_ID = iToGoodID
                             and GCO_I_LIB_CHARACTERIZATION.canCopyCharVersion(iSrcGoodId   => iToGoodID
                                                                             , iTgtGoodId   => iFromGoodID
                                                                             , iCharType    => CHA.C_CHARACT_TYPE
                                                                              ) = 1
                          union all
                          select GetCharConcatUniqueKey(CHA.GCO_CHARACTERIZATION_ID) as CHAR_UNIQUE_KEY
                            from GCO_CHARACTERIZATION CHA
                           where CHA.GCO_GOOD_ID = iFromGoodID)
                group by CHAR_UNIQUE_KEY
                  having count(*) = 1);

        if lnCharDiff = 1 then
          lvMessage  := PCS.PC_FUNCTIONS.TranslateWord('Définition des caractérisations incompatible entre les 2 biens !');
          fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                            , iv_message       => lvMessage
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'SynchronizeProductStock'
                                             );
        end if;
      end;

      -- Rechercher les ids des caractérisation du bien source
      GCO_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => iFromGoodID
                                             , iNoStkChar     => 1
                                             , oCharactID_1   => lFromCharID1
                                             , oCharactID_2   => lFromCharID2
                                             , oCharactID_3   => lFromCharID3
                                             , oCharactID_4   => lFromCharID4
                                             , oCharactID_5   => lFromCharID5
                                              );
      -- Définition des index des caractérisations entre les 2 biens
      lnToChar1FromIndex  :=
        pGetMatchCharIndex(iCharID    => lToCharID1
                         , iCharID1   => lFromCharID1
                         , iCharID2   => lFromCharID2
                         , iCharID3   => lFromCharID3
                         , iCharID4   => lFromCharID4
                         , iCharID5   => lFromCharID5
                          );
      lnToChar2FromIndex  :=
        pGetMatchCharIndex(iCharID    => lToCharID2
                         , iCharID1   => lFromCharID1
                         , iCharID2   => lFromCharID2
                         , iCharID3   => lFromCharID3
                         , iCharID4   => lFromCharID4
                         , iCharID5   => lFromCharID5
                          );
      lnToChar3FromIndex  :=
        pGetMatchCharIndex(iCharID    => lToCharID3
                         , iCharID1   => lFromCharID1
                         , iCharID2   => lFromCharID2
                         , iCharID3   => lFromCharID3
                         , iCharID4   => lFromCharID4
                         , iCharID5   => lFromCharID5
                          );
      lnToChar4FromIndex  :=
        pGetMatchCharIndex(iCharID    => lToCharID4
                         , iCharID1   => lFromCharID1
                         , iCharID2   => lFromCharID2
                         , iCharID3   => lFromCharID3
                         , iCharID4   => lFromCharID4
                         , iCharID5   => lFromCharID5
                          );
      lnToChar5FromIndex  :=
        pGetMatchCharIndex(iCharID    => lToCharID5
                         , iCharID1   => lFromCharID1
                         , iCharID2   => lFromCharID2
                         , iCharID3   => lFromCharID3
                         , iCharID4   => lFromCharID4
                         , iCharID5   => lFromCharID5
                          );
    else
      -- Même bien
      lnToChar1FromIndex  := 1;
      lnToChar2FromIndex  := 2;
      lnToChar3FromIndex  := 3;
      lnToChar4FromIndex  := 4;
      lnToChar5FromIndex  := 5;
    end if;

    -- recherche du type de mouvement de entrée/sortie pour la transformation
    STM_I_LIB_MOVEMENT.GetTransformGoodMvtKind(oInMvtKindID => lInputKindId, oOutMvtKindID => lOutputKindId);

    -- Type de mvts pas définis
    if    (lInputKindId is null)
       or (lOutputKindId is null) then
      lvMessage  := PCS.PC_FUNCTIONS.TranslateWord('Les types de mouvement pour la transformation du bien ne sont pas définis !');
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lvMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'SynchronizeProductStock'
                                         );
    end if;

    -- Référence principale des 2 biens à traiter
    lvFromGoodReference  := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iFromGoodID);
    lvToGoodReference    := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iToGoodID);
    -- Recherche de la période courante
    lPeriodId            := STM_FUNCTIONS.GetPeriodId(sysdate);
    -- Recherche de l'exercice de la période courante
    lExerciseId          := STM_FUNCTIONS.GetPeriodExerciseId(lPeriodId);
    -- Date mouvement
    lMvtDate             := STM_FUNCTIONS.ValidatePeriodDate(lPeriodId, sysdate);
    -- Suppression des attributions du bien
    FAL_DELETE_ATTRIBS.Delete_All_Attribs(iFromGoodID, null, null, 0);

    -- Balayer toutes les positions de stock du bien/version à transformer
    for tplMove in (select   SPO.*
                           , SEM.GCO_QUALITY_STATUS_ID
                           , SEM.SEM_RETEST_DATE
                        from table(STM_LIB_STOCK_POSITION.GetVersionInProgress(iFromGoodID, iFromVersion) ) FLT
                           , STM_STOCK_POSITION SPO
                           , STM_ELEMENT_NUMBER SEM
                       where SPO.STM_STOCK_POSITION_ID = FLT.column_value
                         and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
                    order by SPO.STM_STOCK_POSITION_ID asc) loop
      begin
        -- Définition du libellé du mvt
        lvWording         := 'SynchronizeProductStock - ' || lvFromGoodReference;

        if tplMove.SPO_VERSION is not null then
          lvWording  := lvWording || '/' || tplMove.SPO_VERSION;
        end if;

        lvWording         := lvWording || ' -> ' || lvToGoodReference || '/' || iToVersion;
        -- recherche du type de mouvement de sortie
        lOutputStkMvID    := INIT_ID_SEQ.nextval;
        lInputStkMvtID    := INIT_ID_SEQ.nextval;
        -- génération du mouvement de sortie
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lOutputStkMvID
                                        , iGoodId                => tplMove.GCO_GOOD_ID
                                        , iMovementKindId        => lOutputKindId
                                        , iExerciseId            => lExerciseId
                                        , iPeriodId              => lPeriodId
                                        , iMvtDate               => lMvtDate
                                        , iValueDate             => lMvtDate
                                        , iStockId               => tplMove.STM_STOCK_ID
                                        , iLocationId            => tplMove.STM_LOCATION_ID
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => tplMove.GCO_CHARACTERIZATION_ID
                                        , iChar2Id               => tplMove.GCO_GCO_CHARACTERIZATION_ID
                                        , iChar3Id               => tplMove.GCO2_GCO_CHARACTERIZATION_ID
                                        , iChar4Id               => tplMove.GCO3_GCO_CHARACTERIZATION_ID
                                        , iChar5Id               => tplMove.GCO4_GCO_CHARACTERIZATION_ID
                                        , iCharValue1            => tplMove.SPO_CHARACTERIZATION_VALUE_1
                                        , iCharValue2            => tplMove.SPO_CHARACTERIZATION_VALUE_2
                                        , iCharValue3            => tplMove.SPO_CHARACTERIZATION_VALUE_3
                                        , iCharValue4            => tplMove.SPO_CHARACTERIZATION_VALUE_4
                                        , iCharValue5            => tplMove.SPO_CHARACTERIZATION_VALUE_5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => lvWording
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => tplMove.SPO_STOCK_QUANTITY
                                        , iMvtPrice              => 0
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => 0
                                        , iRefUnitPrice          => 0
                                        , iAltQty1               => 0
                                        , iAltQty2               => 0
                                        , iAltQty3               => 0
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => null
                                        , iOrderKey              => null
                                         );
        lToCharValue1     := null;
        lToCharValue2     := null;
        lToCharValue3     := null;
        lToCharValue4     := null;
        lToCharValue5     := null;
        -- Reprise des valeurs de caractérisation du produit source pour le produit cible
        pInitCharValuesBetweenGoods(iFromCharValue1     => tplMove.SPO_CHARACTERIZATION_VALUE_1
                                  , iFromCharValue2     => tplMove.SPO_CHARACTERIZATION_VALUE_2
                                  , iFromCharValue3     => tplMove.SPO_CHARACTERIZATION_VALUE_3
                                  , iFromCharValue4     => tplMove.SPO_CHARACTERIZATION_VALUE_4
                                  , iFromCharValue5     => tplMove.SPO_CHARACTERIZATION_VALUE_5
                                  , iToChar1FromIndex   => lnToChar1FromIndex
                                  , iToChar2FromIndex   => lnToChar2FromIndex
                                  , iToChar3FromIndex   => lnToChar3FromIndex
                                  , iToChar4FromIndex   => lnToChar4FromIndex
                                  , iToChar5FromIndex   => lnToChar5FromIndex
                                  , oToCharValue1       => lToCharValue1
                                  , oToCharValue2       => lToCharValue2
                                  , oToCharValue3       => lToCharValue3
                                  , oToCharValue4       => lToCharValue4
                                  , oToCharValue5       => lToCharValue5
                                   );

        -- Initialisation de la version sur le produit cible (en fonction de l'indice de la version)
        case lToVersionIndice
          when 1 then
            lToCharValue1  := iToVersion;
          when 2 then
            lToCharValue2  := iToVersion;
          when 3 then
            lToCharValue3  := iToVersion;
          when 4 then
            lToCharValue4  := iToVersion;
          when 5 then
            lToCharValue5  := iToVersion;
          else
            null;
        end case;

        -- génération du mouvement d'entrée
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lInputStkMvtID
                                        , iGoodId                => iToGoodID
                                        , iMovementKindId        => lInputKindId
                                        , iExerciseId            => lExerciseId
                                        , iPeriodId              => lPeriodId
                                        , iMvtDate               => lMvtDate
                                        , iValueDate             => lMvtDate
                                        , iStockId               => tplMove.STM_STOCK_ID
                                        , iLocationId            => tplMove.STM_LOCATION_ID
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => lToCharID1
                                        , iChar2Id               => lToCharID2
                                        , iChar3Id               => lToCharID3
                                        , iChar4Id               => lToCharID4
                                        , iChar5Id               => lToCharID5
                                        , iCharValue1            => lToCharValue1
                                        , iCharValue2            => lToCharValue2
                                        , iCharValue3            => lToCharValue3
                                        , iCharValue4            => lToCharValue4
                                        , iCharValue5            => lToCharValue5
                                        , iMovement2Id           => lOutputStkMvID
                                        , iMovement3Id           => null
                                        , iWording               => lvWording
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => tplMove.SPO_STOCK_QUANTITY
                                        , iMvtPrice              => 0
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => 0
                                        , iRefUnitPrice          => 0
                                        , iAltQty1               => 0
                                        , iAltQty2               => 0
                                        , iAltQty3               => 0
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => null
                                        , iOrderKey              => null
                                         );
        -- Mise à jour des éléments de caractérisation
        lElementNumberId  := STM_LIB_ELEMENT_NUMBER.GetDetailElementFromStockMov(lInputStkMvtID);
        STM_PRC_ELEMENT_NUMBER.ChangeStatus(lElementNumberId, tplMove.GCO_QUALITY_STATUS_ID);
        STM_PRC_ELEMENT_NUMBER.ChangeRetestDate(lElementNumberId, tplMove.SEM_RETEST_DATE);
      exception
        when others then
          lvMessage  := PCS.PC_FUNCTIONS.TranslateWord('Erreur durant la génération des mouvements de transformation des biens !');
          fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                            , iv_message       => lvMessage || chr(10) || lvWording
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'SynchronizeProductStock'
                                             );
      end;
    end loop;
  end SynchronizeProductStock;
end STM_PRC_MOVEMENT;
