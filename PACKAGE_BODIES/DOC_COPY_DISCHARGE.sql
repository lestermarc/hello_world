--------------------------------------------------------
--  DDL for Package Body DOC_COPY_DISCHARGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_COPY_DISCHARGE" 
is
  /**
  * Description
  *     Assignation du dernier numéro de position
  */
  procedure SetLastPosNumber(aPosNumber in number)
  is
  begin
    LAST_POSITION_NUMBER  := aPosNumber;
  end SetLastPosNumber;

  /**
  * Description
  *     Assignation du dernier numéro de position d'après le document en cours
  */
  procedure SetLastDocPosNumber(aDocumentId in number)
  is
  begin
    select nvl(max(POS_NUMBER), 0)
      into LAST_POSITION_NUMBER
      from DOC_POSITION
     where DOC_DOCUMENT_ID = aDocumentId;
  end SetLastDocPosNumber;

  /**
  * Description
  *    Renvoie la valeur du prochain numéro de position et incrément la variable globale LAST_POSITION_NUMBER
  */
  function GetNextPosNumber(aFirstNo in number, aStep in number)
    return number
  is
  begin
    -- si le dernier numéro n'est pas initialisé, on part avec la variable aFirstNo
    if    LAST_POSITION_NUMBER is null
       or LAST_POSITION_NUMBER = 0 then
      LAST_POSITION_NUMBER  := aFirstNo;
    -- si le dernier numéro est initialisé, on incrémente la dernière valeur avec aStep
    else
      LAST_POSITION_NUMBER  := LAST_POSITION_NUMBER + aStep;
    end if;

    return LAST_POSITION_NUMBER;
  end GetNextPosNumber;

  function getCharValue(atblChar in GCO_CHARACTERIZATION_FUNCTIONS.TtblCharValue, aKey GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  is
    i GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type   := 0;
  begin
    i  := atblChar.first;
    return atblChar(aKey).value;
  exception
    when no_data_found then
      return null;
  end getCharValue;

  /**
  * Description
  *   return true if the father position detail has a characterisation value
  */
  function IsFatherWithChar(
    iPositionDetailId   in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , iCharacterizationId in DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type
  )
    return number
  is
    lId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    select DOC_POSITION_DETAIL_ID
      into lId
      from DOC_POSITION_DETAIL
     where DOC_POSITION_DETAIL_ID = iPositionDetailId
       and (    (    GCO_CHARACTERIZATION_ID = iCharacterizationId
                 and PDE_CHARACTERIZATION_VALUE_1 is not null)
            or (    GCO_GCO_CHARACTERIZATION_ID = iCharacterizationId
                and PDE_CHARACTERIZATION_VALUE_2 is not null)
            or (    GCO2_GCO_CHARACTERIZATION_ID = iCharacterizationId
                and PDE_CHARACTERIZATION_VALUE_3 is not null)
            or (    GCO3_GCO_CHARACTERIZATION_ID = iCharacterizationId
                and PDE_CHARACTERIZATION_VALUE_4 is not null)
            or (    GCO4_GCO_CHARACTERIZATION_ID = iCharacterizationId
                and PDE_CHARACTERIZATION_VALUE_5 is not null)
           );

    return 1;
  exception
    when no_data_found then
      return 0;
  end IsFatherWithChar;

  /**
  * function pCanAutoInitializeChar
  * Description
  *    Tell if the movement context if appropriate for autoinitialization of the characterization value
  *    (function created to avoid redundance)
  * @created fpe 21.05.2014
  * @updated
  * @private
  * @param iMovementSort     : movement sort
  * @param iStockMgt         : is characterization with stock management
  * @return true/false
  */
  function pCanAutoInitializeChar(iMovementSort in STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type, iStockMgt in GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type)
    return boolean
  is
  begin
    return(    (    iMovementSort = 'ENT'
                and iStockMgt = 1)
           or (    iMovementSort = 'SOR'
               and iStockMgt = 0) );
  end;

  /**
  * function pShouldInitCharValue
  * Description
  *   Indicate if it may be possible to initialize the valeu of the characterization
  *   regardinf the characterization type (function created to avoid redundance)
  * @created fpe 21.05.2014
  * @updated
  * @private
  * @param iCharId            : characterization identifyer
  * @param iCharType          : type of the characterization (C_CHARACT_TYPE)
  * @param iDischargeQuantity : quantity to discharge
  * @return true/false
  */
  function pShouldInitCharValue(
    iCharId            in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharType          in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , iDischargeQuantity in DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type
  )
    return boolean
  is
  begin
    return     (iCharId is not null)
           and not(    iCharType in
                         (GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                        , GCO_I_LIB_CONSTANT.gcCharacTypePiece
                        , GCO_I_LIB_CONSTANT.gcCharacTypeSet
                        , GCO_I_LIB_CONSTANT.gcCharacTypeChrono
                         )
                   /* pas de reprise du no de série/version/lot/chrono si la qté est à 0 */
                   and iDischargeQuantity = 0
                  );
  end pShouldInitCharValue;

  /**
  * function pInitCharValue
  * Description
  *   Initialization of the characterization value (function created to avoid redundance)
  * @created fpe 21.05.2014
  * @updated
  * @private
  * @param iSourceCharId     : source characterization identifyer
  * @param iSourceCharValue  : source charcaterization value
  * @param iTargetCharId     : target characterization identifyer
  * @param iTargetGoodId     : target good identifyer
  * @param iTargetPositionId : target position identifyer
  * @param iMovementSort     : movement sort
  * @param iStockMgt         : is characterization with stock management
  * @param iCharType         : type of the characterization (C_CHARACT_TYPE)
  * @return the value of the characterization
  */
  function pInitCharValue(
    iSourceCharId     in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iSourceCharValue  in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , iTargetCharId     in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iTargetGoodId     in GCO_CHARACTERIZATION.GCO_GOOD_ID%type
  , iTargetPositionId in DOC_POSITION.DOC_POSITION_ID%type
  , iMovementSort     in STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type
  , iStockMgt         in GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type
  , iCharType         in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  )
    return DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  is
  begin
    if iTargetCharId is not null then
      if iSourceCharId is not null then
        return iSourceCharValue;
      elsif pCanAutoInitializeChar(iMovementSort, iStockMgt) then
        if iCharType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
          return GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(iCharacterizationID => iTargetCharId, iDocPositionId => iTargetPositionId);
        elsif iCharType = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
          return GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(iCharacterizationID   => iTargetCharId
                                                                  , iBasisTime            => sysdate
                                                                  , iContext              => 'DOC_POSITION'
                                                                  , iElementId            => iTargetPositionId
                                                                   );
        elsif     iCharType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
              and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(iTargetGoodId) = 1 then
          return GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => iTargetGoodId);
        else
          return null;
        end if;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end pInitCharValue;

  /**
  * function pCharRetrieveForbidden
  * Description
  *   Check if the context forbid the initialization of the characterization
  *   (function created to avoid redundance)
  * @created fpe 21.05.2014
  * @updated
  * @private
  * @param iSourceGaugeID     : source gauge identifyer
  * @param iTargetGaugeID     : target gauge identifyer
  * @param iCharType          : type of the characterization (C_CHARACT_TYPE)
  * @return true if it's forbidden otherwise false
  */
  function pCharRetrieveForbidden(
    iSourceGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , iTargetGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , iCharType      in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  )
    return boolean
  is
  begin
    return not(    (iTargetGaugeID <> iSourceGaugeID)
               or (     (iCharType <> GCO_I_LIB_CONSTANT.gcCharacTypePiece)
                   and   /* Pas de gestion de pièce */
                       not(    iCharType = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                           and (   STM_I_LIB_CONSTANT.gcCfgSetSglNumberingGood
                                or STM_I_LIB_CONSTANT.gcCfgSetSglNumberingComp)
                          )
                  )
              );   /* Pas de gestion de lot unique */
  end pCharRetrieveForbidden;

  function pInitDetailCharValue(
    iTgtGoodID       in GCO_CHARACTERIZATION.GCO_GOOD_ID%type
  , iTgtCharID       in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iTgtCharStockMgt in GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type
  , iTgtCharType     in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , iTgtPositionID   in DOC_POSITION.DOC_POSITION_ID%type
  , iMovementSort    in STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type
  , iSrcGoodID       in GCO_CHARACTERIZATION.GCO_GOOD_ID%type
  , iSrcCharID1      in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iSrcCharID2      in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iSrcCharID3      in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iSrcCharID4      in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iSrcCharID5      in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iSrcCharValue1   in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , iSrcCharValue2   in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2%type
  , iSrcCharValue3   in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3%type
  , iSrcCharValue4   in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4%type
  , iSrcCharValue5   in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5%type
  )
    return DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  is
    lvCharValue DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
  begin
    lvCharValue  := null;

    -- ID de caractérisation renseigné ET même bien source et cible
    if     (iTgtCharID is not null)
       and (iTgtGoodID = iSrcGoodID) then
      -- Chercher la valeur de caractérisation correspondant à l'id de celle-ci
      case iTgtCharID
        when iSrcCharID1 then
          lvCharValue  := iSrcCharValue1;
        when iSrcCharID2 then
          lvCharValue  := iSrcCharValue2;
        when iSrcCharID3 then
          lvCharValue  := iSrcCharValue3;
        when iSrcCharID4 then
          lvCharValue  := iSrcCharValue4;
        when iSrcCharID5 then
          lvCharValue  := iSrcCharValue5;
        else
          lvCharValue  := null;
      end case;

      -- Si la valeur de caractérisation n'est pas encore renseignée
      --  et si initialisation automatique de la valeur de caractérisation est autorisée
      if     (lvCharValue is null)
         and pCanAutoInitializeChar(iMovementSort, iTgtCharStockMgt) then
        -- Caractérisation de type : Lot
        if iTgtCharType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
          lvCharValue  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(iCharacterizationID => iTgtCharID, iDocPositionId => iTgtPositionID);
        -- Caractérisation de type : Chronologique
        elsif iTgtCharType = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
          lvCharValue  :=
            GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(iCharacterizationID   => iTgtCharID
                                                             , iBasisTime            => sysdate
                                                             , iContext              => 'DOC_POSITION'
                                                             , iElementId            => iTgtPositionID
                                                              );
        -- Caractérisation de type : Version
        elsif     iTgtCharType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
              and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(iTgtGoodID) = 1 then
          lvCharValue  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => iTgtGoodID);
        end if;
      end if;
    end if;

    return lvCharValue;
  end pInitDetailCharValue;

  /**
  * Procedure DischargePositionDetail
  * Description
  *       Décharge des détail de position (procedure appelée
  *       par la procedure DischargePosition
  * @author Fabrice Perotto
  * @created 30.05.2001
  * @lastUpdate vje 25.04.2008
  * @private
  * @Param aSourcePositionId id de la position parent,
  * @Param aTargetPositionId id de la position enfant (nouveau document),
  * @Param aTargetGoodId id du bien de la position cible,
  * @Param aTargetDocumentId Id du nouveau document,
  * @Param aSourceGaugeId Id du gabarit du document parent,
  * @Param aTargetGaugeId Id du gabarit du nouveau document,
  * @Param aConvertFactor Facteur de conversion sur la postion fille.
  * @Param aSourceCurrencyId Monnaie du document parent,
  * @Param aTargetCurrencyId Monnaie du nouveau document
  * @Param aTargetAdminDomain valeur de C_ADMIN_DOMAIN du gabarit du document cible,
  * @Param aGaugeReceiptId ID du gabarit de décharge,
  * @Param aDateRef Date de référence,
  * @Param aFlowId ID du flux,
  * @Param aInitQteMvt flag d'initialisation de la quantité mouvement,
  * @Param aInitPriceMvt flag d'initialisation du prix du mouvement,
  * @Param aTransfertStock flag d'initialisation du transfert de stock,
  * @Param aTransfertQuantity flag d'initialisation du transfert de quantité,
  * @Param aSourceGestDelay flag indiquant si le document source gère les délais,
  * @Param aGestDelay flag indiquant si le document cible gère les délais,
  * @Param aDelayUpdateType valeur de DIC_DELAY_UPDATE_TYPE,
  * @Param aSourceGestChar flag indiquant si le document source gère les caractérisations,
  * @Param aGestChar flag indiquant si le nouveau document gère les caractérisation,
  * @Param aMvtUtility flag utilisation mouvement de stock,
  * @Param aTargetUnitCostPrice prix de revient unitaire dans le document cible,
  * @Param aTargetNetUnitValue prix net unitaire cible,
  * @Param aMovementKindId id du genre de mouvement de stock cible,
  * @Param aTypePos valeur C_GAUGE_TYPE_POS cible
  * @Param aPosStockId ID du stock,
  * @Param aPosLocationId  ID emplacement de stock,
  * @Param aPosTargetTransLocationId Id enplacement stock de transfert,
  * @Param aPositionQuantity quantité de la position liée,
  * @Param aBalanceValueParent valeur solde parent,
  * @Param aBalanceStatus status solde,
  * @Param aGoodNumberOfDecimal nombre de décimal du bien,
  * @Param aCDANumberOfDecimal nombre de décimales du bien dans les données complémentaires,
  * @Param aInputIdList valeur de retour, liste des détails de position dont on doit saisir des informations manuellement;
  * @param aDischargeInfoCode out : code d'erreur ou d'avertissement en cas de problème
  */
  procedure DischargePositionDetail(
    aSourcePositionId            in     number
  , aTargetPositionId            in     number
  , aTargetGoodId                in     number
  , aTargetDocumentId            in     number
  , aSourceGaugeId               in     number
  , aTargetGaugeId               in     number
  , aConvertFactor               in     number
  , aConvertFactorQty            in     number
  , aSourceCurrencyId            in     number
  , aTargetCurrencyId            in     number
  , aTargetAdminDomain           in     varchar2
  , aGaugeReceiptId              in     number
  , aDateRef                     in     date
  , aFlowId                      in     number
  , aInitQteMvt                  in     number
  , aInitPriceMvt                in     number
  , aTransfertMovementDate       in     number
  , aTransfertStock              in     number
  , aTransfertQuantity           in     number
  , aSourceGestDelay             in     number
  , aGestDelay                   in     number
  , aDelayUpdateType             in     varchar2
  , aSourceGestChar              in     number
  , aGestChar                    in     number
  , aMvtUtility                  in     number
  , aTargetUnitCostPrice         in     number
  , aTargetNetUnitValue          in     number
  , aMovementKindId              in     number
  , aTypePos                     in     number
  , aPosStockId                  in     number
  , aPosLocationId               in     number
  , aPosTargetTransLocationId    in     number
  , aPositionQuantity            in     number
  , aBalanceValueParent          in     number
  , aBalanceStatus               in     number
  , aGoodNumberOfDecimal         in     number
  , aCDANumberOfDecimal          in     number
  , aCummulBalanceQuantityParent in out number
  , aInputIdList                 in out varchar2
  , aDischargeInfoCode           in out varchar2
  )
  is
    type tDetail is record(
      PDE_BASIS_QUANTITY           DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type
    , PDE_MOVEMENT_QUANTITY        DOC_POSITION_DETAIL.PDE_MOVEMENT_QUANTITY%type
    , PDE_BASIS_QUANTITY_SU        DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY_SU%type
    , PDE_CHARACTERIZATION_VALUE_1 DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
    , PDE_CHARACTERIZATION_VALUE_2 DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2%type
    , PDE_CHARACTERIZATION_VALUE_3 DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3%type
    , PDE_CHARACTERIZATION_VALUE_4 DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4%type
    , PDE_CHARACTERIZATION_VALUE_5 DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5%type
    );

    type ttblDetail is table of tDetail
      index by binary_integer;

    -- curseur sur les détail de positions à décharger
    cursor SourceDetail(aPositionId number, newDocumentId number)
    is
      select   pde.doc_position_detail_id
             , pde.doc_position_id
             , pde.doc2_doc_position_detail_id
             , dcd.gco_good_id
             , dcd.gco_characterization_id
             , dcd.gco_gco_characterization_id
             , dcd.gco2_gco_characterization_id
             , dcd.gco3_gco_characterization_id
             , dcd.gco4_gco_characterization_id
             , dcd.pde_characterization_value_1
             , dcd.pde_characterization_value_2
             , dcd.pde_characterization_value_3
             , dcd.pde_characterization_value_4
             , dcd.pde_characterization_value_5
             , dcd.dcd_quantity
             , nvl(dcd.dcd_quantity_su, dcd.dcd_quantity) dcd_quantity_su
             , dcd.dcd_balance_flag
             , DCD.DCD_USE_STOCK_LOCATION_ID
             , dcd.dcd_use_parent_charact
             , DCD.STM_LOCATION_ID DCD_STM_LOCATION_ID
             , DCD.STM_STM_LOCATION_ID DCD_STM_STM_LOCATION_ID
             , pde.pde_balance_quantity
             , pde.pde_balance_quantity_parent
             , pde.pde_movement_date
             , dcd.pde_basis_delay
             , dcd.pde_intermediate_delay
             , dcd.pde_final_delay
             , dcd.pde_sqm_accepted_delay
             , dcd.dic_pde_free_table_1_id
             , dcd.dic_pde_free_table_2_id
             , dcd.dic_pde_free_table_3_id
             , dcd.pde_decimal_1
             , dcd.pde_decimal_2
             , dcd.pde_decimal_3
             , dcd.pde_text_1
             , dcd.pde_text_2
             , dcd.pde_text_3
             , dcd.pde_date_1
             , dcd.pde_date_2
             , dcd.pde_date_3
             , dcd.fal_schedule_step_id
             , dcd.doc_record_id
             , dcd.dic_delay_update_type_id
             , dcd.pde_delay_update_text
             , dcd.pos_convert_factor_calc
             , dcd.pos_convert_factor
             , dcd.fal_network_link_id
             , dcd.dcd_update_parent_delay
             , nvl(DCD.C_PDE_CREATE_MODE, '301') C_PDE_CREATE_MODE
             , gau.c_gauge_type
             , PDE.GCO_GOOD_ID POS_GOOD_ID
             , PDE.DOC_PDE_LITIG_ID
             , DMT.GAL_CURRENCY_RISK_VIRTUAL_ID
             , DMT.DOC_DOCUMENT_ID
             , PDE.FAL_LOT_ID
             , POS.C_DOC_LOT_TYPE
             , dcd.PDE_ST_PT_REJECT
             , dcd.PDE_ST_CPT_REJECT
          from doc_position_detail pde
             , doc_pos_det_copy_discharge dcd
             , doc_gauge gau
             , DOC_DOCUMENT DMT
             , DOC_POSITION POS
         where dcd.doc_position_id = aPositionId
           and dcd.crg_select = 1
           and dcd.new_document_id = newDocumentId
           and pde.doc_position_detail_id = dcd.doc_position_detail_id
           and gau.doc_gauge_id = pde.doc_gauge_id
           and POS.DOC_POSITION_ID = DCD.DOC_POSITION_ID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
      order by dcd.doc_pos_det_copy_discharge_id;

    SourceDetail_tuple          SourceDetail%rowtype;
    BasisQuantityDetail         doc_position_detail.pde_basis_quantity%type;
    BasisQuantityDetailSU       doc_position_detail.pde_basis_quantity_SU%type;
    BalanceQuantityParentTarget doc_position_detail.pde_balance_quantity_parent%type;
    BalanceQuantityParentSource doc_position_detail.pde_balance_quantity_parent%type;
    MovementValue               doc_position_detail.pde_movement_value%type;
    MovementDate                doc_position_detail.pde_movement_date%type;
    TargetLocationId            STM_LOCATION.STM_LOCATION_ID%type;
    TargetTransLocationId       STM_LOCATION.STM_LOCATION_ID%type;
    TargetGestPiece             number(1)                                              default 0;
    MovementSort                stm_movement_kind.c_movement_sort%type;
    TargetCharac1Id             gco_characterization.gco_characterization_id%type;
    TargetCharac2Id             gco_characterization.gco_characterization_id%type;
    TargetCharac3Id             gco_characterization.gco_characterization_id%type;
    TargetCharac4Id             gco_characterization.gco_characterization_id%type;
    TargetCharac5Id             gco_characterization.gco_characterization_id%type;
    TargetCharacType1           gco_characterization.c_charact_type%type;
    TargetCharacType2           gco_characterization.c_charact_type%type;
    TargetCharacType3           gco_characterization.c_charact_type%type;
    TargetCharacType4           gco_characterization.c_charact_type%type;
    TargetCharacType5           gco_characterization.c_charact_type%type;
    targetCharStk1              gco_characterization.cha_stock_management%type;
    targetCharStk2              gco_characterization.cha_stock_management%type;
    targetCharStk3              gco_characterization.cha_stock_management%type;
    targetCharStk4              gco_characterization.cha_stock_management%type;
    targetCharStk5              gco_characterization.cha_stock_management%type;
    ValueQuantityUsed           doc_position.pos_balance_qty_value%type;
    gestParentDelay             number(1);
    vSmartLink                  boolean;
    vOldFatherDetail            doc_position_detail.doc_position_detail_id%type;
    vRecordNumber               number(12);
    vBalanceFlags               number(12);
    vFinalQuantities            doc_position_detail.pde_final_quantity%type;
    vDischargeQuantities        doc_position_detail.pde_final_quantity%type;
    vBalancedQuantities         doc_position_detail.pde_balance_quantity_parent%type;
    vAllCharacterization        DOC_GAUGE_STRUCTURED.GAS_ALL_CHARACTERIZATION%type;
    stmReelLocationID           STM_LOCATION.STM_LOCATION_ID%type;
    pdtStockAllocBatch          GCO_PRODUCT.PDT_STOCK_ALLOC_BATCH%type;
    vTargetGestInstall          number(1)                                              := 0;
    vSourceGestInstall          number(1)                                              := 0;
    vAutoChar                   DOC_GAUGE_STRUCTURED.GAS_AUTO_CHARACTERIZATION%type    := 0;
    vTplDetail                  V_DOC_POSITION_DETAIL_IO%rowtype;
    lvCDocLotType               DOC_GAUGE_POSITION.C_DOC_LOT_TYPE%type;
  begin
    aCummulBalanceQuantityParent  := 0;
    vOldFatherDetail              := 0;
    vSmartLink                    := false;

    -- Recherche les flags indiquant si l'on gère les installation (source et cible )
    begin
      select nvl(TGT.GAS_INSTALLATION_MGM, 0)
           , nvl(SRC.GAS_INSTALLATION_MGM, 0)
           , nvl(TGT.GAS_AUTO_CHARACTERIZATION, 0)
        into vTargetGestInstall
           , vSourceGestInstall
           , vAutoChar
        from DOC_GAUGE_STRUCTURED TGT
           , DOC_GAUGE_STRUCTURED SRC
       where TGT.DOC_GAUGE_ID = aTargetGaugeId
         and SRC.DOC_GAUGE_ID = aSourceGaugeId;
    exception
      when no_data_found then
        null;
    end;

    -- recherche des id de caractérisation
    if    (aGestChar = 1)
       or aMovementKindId is not null then
      if aMovementKindId is null then
        MovementSort  := '';

        select max(GAS.GAS_ALL_CHARACTERIZATION)
          into vAllCharacterization
          from DOC_GAUGE_STRUCTURED GAS
             , DOC_POSITION POS
         where POS.DOC_POSITION_ID = aTargetPositionId
           and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID;

        /* Gestion des caractérisations non morphologique dans les documents sans
           mouvements de stock. On recherche le type de mouvement en fonction du
           domaine. */
        if     (PCS.PC_CONFIG.GetConfig('DOC_CHARACTERIZATION_MODE') = '1')
           and (vAllCharacterization = 1) then
          if (aTargetAdminDomain = '1') then   /* Achat */
            MovementSort  := 'ENT';
          elsif(aTargetAdminDomain = '2') then   /* Vente */
            MovementSort  := 'SOR';
          end if;
        end if;
      else
        select max(c_movement_sort)
          into MovementSort
          from stm_movement_kind
         where stm_movement_kind_id = aMovementKindId;
      end if;

      -- recherche des id de caractérisations du nouveau détail de position
      GCO_CHARACTERIZATION_FUNCTIONS.GetListOfCharacterization(aTargetGoodId
                                                             , aGestChar
                                                             , MovementSort
                                                             , aTargetAdminDomain
                                                             , TargetCharac1Id
                                                             , TargetCharac2Id
                                                             , TargetCharac3Id
                                                             , TargetCharac4Id
                                                             , TargetCharac5Id
                                                             , targetCharacType1
                                                             , targetCharacType2
                                                             , targetCharacType3
                                                             , targetCharacType4
                                                             , targetCharacType5
                                                             , targetCharStk1
                                                             , targetCharStk2
                                                             , targetCharStk3
                                                             , targetCharStk4
                                                             , targetCharStk5
                                                             , TargetGestPiece
                                                              );
    end if;

    -- Rechercher le type de lt sur le gabarit position de la position cible
    select max(GAP.C_DOC_LOT_TYPE)
      into lvCDocLotType
      from DOC_GAUGE_POSITION GAP
         , DOC_POSITION POS
     where POS.DOC_POSITION_ID = aTargetPositionId
       and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID;

    open SourceDetail(aSourcePositionId, aTargetDocumentId);

    fetch SourceDetail
     into SourceDetail_tuple;

    while Sourcedetail%found loop
      declare
        vtblDetail    ttblDetail;
        tblCharValues GCO_CHARACTERIZATION_FUNCTIONS.TtblCharValue;
      begin
        vRecordNumber                               := 0;
        vBalanceFlags                               := 0;
        vFinalQuantities                            := 0;
        vDischargeQuantities                        := 0;
        vBalancedQuantities                         := 0;
        SOURCE_DETAIL_ID                            := SourceDetail_tuple.DOC_POSITION_DETAIL_ID;

        -- Initialisation caractérisation 1
        if TargetCharac1Id is not null then
          tblCharValues(TargetCharac1Id).value  :=
            pInitDetailCharValue(iTgtGoodID         => aTargetGoodId
                               , iTgtCharID         => TargetCharac1Id
                               , iTgtCharStockMgt   => targetCharStk1
                               , iTgtCharType       => targetCharacType1
                               , iTgtPositionID     => aTargetPositionId
                               , iMovementSort      => MovementSort
                               , iSrcGoodID         => SourceDetail_tuple.POS_GOOD_ID
                               , iSrcCharID1        => SourceDetail_tuple.GCO_CHARACTERIZATION_ID
                               , iSrcCharID2        => SourceDetail_tuple.GCO_GCO_CHARACTERIZATION_ID
                               , iSrcCharID3        => SourceDetail_tuple.GCO2_GCO_CHARACTERIZATION_ID
                               , iSrcCharID4        => SourceDetail_tuple.GCO3_GCO_CHARACTERIZATION_ID
                               , iSrcCharID5        => SourceDetail_tuple.GCO4_GCO_CHARACTERIZATION_ID
                               , iSrcCharValue1     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1
                               , iSrcCharValue2     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2
                               , iSrcCharValue3     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3
                               , iSrcCharValue4     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4
                               , iSrcCharValue5     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5
                                );
        end if;

        -- Initialisation caractérisation 2
        if TargetCharac2Id is not null then
          tblCharValues(TargetCharac2Id).value  :=
            pInitDetailCharValue(iTgtGoodID         => aTargetGoodId
                               , iTgtCharID         => TargetCharac2Id
                               , iTgtCharStockMgt   => targetCharStk2
                               , iTgtCharType       => targetCharacType2
                               , iTgtPositionID     => aTargetPositionId
                               , iMovementSort      => MovementSort
                               , iSrcGoodID         => SourceDetail_tuple.POS_GOOD_ID
                               , iSrcCharID1        => SourceDetail_tuple.GCO_CHARACTERIZATION_ID
                               , iSrcCharID2        => SourceDetail_tuple.GCO_GCO_CHARACTERIZATION_ID
                               , iSrcCharID3        => SourceDetail_tuple.GCO2_GCO_CHARACTERIZATION_ID
                               , iSrcCharID4        => SourceDetail_tuple.GCO3_GCO_CHARACTERIZATION_ID
                               , iSrcCharID5        => SourceDetail_tuple.GCO4_GCO_CHARACTERIZATION_ID
                               , iSrcCharValue1     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1
                               , iSrcCharValue2     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2
                               , iSrcCharValue3     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3
                               , iSrcCharValue4     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4
                               , iSrcCharValue5     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5
                                );
        end if;

        -- Initialisation caractérisation 3
        if TargetCharac3Id is not null then
          tblCharValues(TargetCharac3Id).value  :=
            pInitDetailCharValue(iTgtGoodID         => aTargetGoodId
                               , iTgtCharID         => TargetCharac3Id
                               , iTgtCharStockMgt   => targetCharStk3
                               , iTgtCharType       => targetCharacType3
                               , iTgtPositionID     => aTargetPositionId
                               , iMovementSort      => MovementSort
                               , iSrcGoodID         => SourceDetail_tuple.POS_GOOD_ID
                               , iSrcCharID1        => SourceDetail_tuple.GCO_CHARACTERIZATION_ID
                               , iSrcCharID2        => SourceDetail_tuple.GCO_GCO_CHARACTERIZATION_ID
                               , iSrcCharID3        => SourceDetail_tuple.GCO2_GCO_CHARACTERIZATION_ID
                               , iSrcCharID4        => SourceDetail_tuple.GCO3_GCO_CHARACTERIZATION_ID
                               , iSrcCharID5        => SourceDetail_tuple.GCO4_GCO_CHARACTERIZATION_ID
                               , iSrcCharValue1     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1
                               , iSrcCharValue2     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2
                               , iSrcCharValue3     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3
                               , iSrcCharValue4     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4
                               , iSrcCharValue5     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5
                                );
        end if;

        -- Initialisation caractérisation 4
        if TargetCharac4Id is not null then
          tblCharValues(TargetCharac4Id).value  :=
            pInitDetailCharValue(iTgtGoodID         => aTargetGoodId
                               , iTgtCharID         => TargetCharac4Id
                               , iTgtCharStockMgt   => targetCharStk4
                               , iTgtCharType       => targetCharacType4
                               , iTgtPositionID     => aTargetPositionId
                               , iMovementSort      => MovementSort
                               , iSrcGoodID         => SourceDetail_tuple.POS_GOOD_ID
                               , iSrcCharID1        => SourceDetail_tuple.GCO_CHARACTERIZATION_ID
                               , iSrcCharID2        => SourceDetail_tuple.GCO_GCO_CHARACTERIZATION_ID
                               , iSrcCharID3        => SourceDetail_tuple.GCO2_GCO_CHARACTERIZATION_ID
                               , iSrcCharID4        => SourceDetail_tuple.GCO3_GCO_CHARACTERIZATION_ID
                               , iSrcCharID5        => SourceDetail_tuple.GCO4_GCO_CHARACTERIZATION_ID
                               , iSrcCharValue1     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1
                               , iSrcCharValue2     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2
                               , iSrcCharValue3     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3
                               , iSrcCharValue4     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4
                               , iSrcCharValue5     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5
                                );
        end if;

        -- Initialisation caractérisation 5
        if TargetCharac5Id is not null then
          tblCharValues(TargetCharac5Id).value  :=
            pInitDetailCharValue(iTgtGoodID         => aTargetGoodId
                               , iTgtCharID         => TargetCharac5Id
                               , iTgtCharStockMgt   => targetCharStk5
                               , iTgtCharType       => targetCharacType5
                               , iTgtPositionID     => aTargetPositionId
                               , iMovementSort      => MovementSort
                               , iSrcGoodID         => SourceDetail_tuple.POS_GOOD_ID
                               , iSrcCharID1        => SourceDetail_tuple.GCO_CHARACTERIZATION_ID
                               , iSrcCharID2        => SourceDetail_tuple.GCO_GCO_CHARACTERIZATION_ID
                               , iSrcCharID3        => SourceDetail_tuple.GCO2_GCO_CHARACTERIZATION_ID
                               , iSrcCharID4        => SourceDetail_tuple.GCO3_GCO_CHARACTERIZATION_ID
                               , iSrcCharID5        => SourceDetail_tuple.GCO4_GCO_CHARACTERIZATION_ID
                               , iSrcCharValue1     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1
                               , iSrcCharValue2     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2
                               , iSrcCharValue3     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3
                               , iSrcCharValue4     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4
                               , iSrcCharValue5     => SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5
                                );
        end if;

        if (vOldFatherDetail <> SourceDetail_tuple.doc_position_detail_id) then
          /* Réinitialise le flag de mise à jour intelligente de la quantité soldée sur le parent. */
          vSmartLink  := false;

          begin
            select count(*)
                 , sum(nvl(dcd.dcd_balance_flag, 0) )
                 , avg(nvl(dcd.pde_final_quantity, 0) )
                 , sum(nvl(dcd.dcd_quantity, 0) )
                 , avg(nvl(dcd.pde_balance_quantity, 0) ) - sum(nvl(dcd.dcd_quantity, 0) )
              into vRecordNumber
                 , vBalanceFlags
                 , vFinalQuantities
                 , vDischargeQuantities
                 , vBalancedQuantities
              from doc_pos_det_copy_discharge dcd
             where dcd.new_document_id = aTargetDocumentId
               and dcd.doc_position_detail_id = SourceDetail_tuple.doc_position_detail_id
               and dcd.crg_select = 1;
          exception
            when no_data_found then
              vRecordNumber         := 0;
              vBalanceFlags         := 0;
              vFinalQuantities      := 0;
              vDischargeQuantities  := 0;
              vBalancedQuantities   := 0;
          end;
        end if;

        if     (vRecordNumber > 1)
           and (vBalanceFlags > 0) then
          /* Active le flag de mise à jour intelligente de la quantité soldée sur le parent. */
          vSmartLink  := true;
        end if;

        -- Emplacements du détail
        if nvl(SourceDetail_tuple.DCD_USE_STOCK_LOCATION_ID, 0) = 1 then
          TargetLocationID       := nvl(SourceDetail_tuple.DCD_STM_LOCATION_ID, aPosLocationId);
          TargetTransLocationID  := nvl(SourceDetail_tuple.DCD_STM_STM_LOCATION_ID, aPosTargetTransLocationId);
        else
          if     aTransfertStock = 1
             and aMvtUtility = 0 then
            TargetLocationid       := nvl(SourceDetail_tuple.DCD_STM_LOCATION_ID, aPosLocationId);
            TargetTransLocationID  := aPosTargetTransLocationId;
          else
            TargetLocationid       := aPosLocationId;
            TargetTransLocationID  := aPosTargetTransLocationId;
          end if;
        end if;

        vtblDetail(1).PDE_CHARACTERIZATION_VALUE_1  := null;
        vtblDetail(1).PDE_CHARACTERIZATION_VALUE_2  := null;
        vtblDetail(1).PDE_CHARACTERIZATION_VALUE_3  := null;
        vtblDetail(1).PDE_CHARACTERIZATION_VALUE_4  := null;
        vtblDetail(1).PDE_CHARACTERIZATION_VALUE_5  := null;

        if     (SourceDetail_tuple.dcd_use_parent_charact = 1)
           and tblCharValues.count > 0 then
          -- Initialisation des valeurs de caractérisation
          if pShouldInitCharValue(TargetCharac1Id, TargetCharacType1, SourceDetail_tuple.dcd_quantity) then
            if     not pCharRetrieveForbidden(iSourceGaugeID => aSourceGaugeId, iTargetGaugeID => aTargetGaugeId, iCharType => TargetCharacType1)
               and getCharValue(tblCharValues, TargetCharac1Id) is not null then
              vtblDetail(1).PDE_CHARACTERIZATION_VALUE_1  := getCharValue(tblCharValues, TargetCharac1Id);
            end if;
          end if;

          if pShouldInitCharValue(TargetCharac2Id, TargetCharacType2, SourceDetail_tuple.dcd_quantity) then
            if     not pCharRetrieveForbidden(iSourceGaugeID => aSourceGaugeId, iTargetGaugeID => aTargetGaugeId, iCharType => TargetCharacType2)
               and getCharValue(tblCharValues, TargetCharac2Id) is not null then
              vtblDetail(1).PDE_CHARACTERIZATION_VALUE_2  := getCharValue(tblCharValues, TargetCharac2Id);
            end if;
          end if;

          if pShouldInitCharValue(TargetCharac3Id, TargetCharacType3, SourceDetail_tuple.dcd_quantity) then
            if     not pCharRetrieveForbidden(iSourceGaugeID => aSourceGaugeId, iTargetGaugeID => aTargetGaugeId, iCharType => TargetCharacType3)
               and getCharValue(tblCharValues, TargetCharac3Id) is not null then
              vtblDetail(1).PDE_CHARACTERIZATION_VALUE_3  := getCharValue(tblCharValues, TargetCharac3Id);
            end if;
          end if;

          if pShouldInitCharValue(TargetCharac4Id, TargetCharacType4, SourceDetail_tuple.dcd_quantity) then
            if     not pCharRetrieveForbidden(iSourceGaugeID => aSourceGaugeId, iTargetGaugeID => aTargetGaugeId, iCharType => TargetCharacType4)
               and getCharValue(tblCharValues, TargetCharac4Id) is not null then
              vtblDetail(1).PDE_CHARACTERIZATION_VALUE_4  := getCharValue(tblCharValues, TargetCharac4Id);
            end if;
          end if;

          if pShouldInitCharValue(TargetCharac5Id, TargetCharacType5, SourceDetail_tuple.dcd_quantity) then
            if     not pCharRetrieveForbidden(iSourceGaugeID => aSourceGaugeId, iTargetGaugeID => aTargetGaugeId, iCharType => TargetCharacType5)
               and getCharValue(tblCharValues, TargetCharac5Id) is not null then
              vtblDetail(1).PDE_CHARACTERIZATION_VALUE_5  := getCharValue(tblCharValues, TargetCharac5Id);
            end if;
          end if;
        -- pas de reprise des caractérisations sur le père et
        -- mouvement de sortie avec qté positive
        end if;

        -- flag de retour indiquant qu'il faut saisir des valeurs de caracterisation dans l'interface
        --if aGestDelay = 1 or
        if     (SourceDetail_tuple.DCD_QUANTITY <> 0)
           and (    (    (    nvl(vtblDetail(1).PDE_CHARACTERIZATION_VALUE_1, 'N/A') = 'N/A'
                          and TargetCharac1Id is not null)
                     or (    nvl(vtblDetail(1).PDE_CHARACTERIZATION_VALUE_2, 'N/A') = 'N/A'
                         and TargetCharac2Id is not null)
                     or (    nvl(vtblDetail(1).PDE_CHARACTERIZATION_VALUE_3, 'N/A') = 'N/A'
                         and TargetCharac3Id is not null)
                     or (    nvl(vtblDetail(1).PDE_CHARACTERIZATION_VALUE_4, 'N/A') = 'N/A'
                         and TargetCharac4Id is not null)
                     or (    nvl(vtblDetail(1).PDE_CHARACTERIZATION_VALUE_5, 'N/A') = 'N/A'
                         and TargetCharac5Id is not null)
                    )
                or (     (PCS.PC_CONFIG.GetConfig('DOC_SHOW_FORM_DISCHARGE_DETAIL') = '2')
                    and (coalesce(TargetCharac1Id, TargetCharac2Id, TargetCharac3Id, TargetCharac4Id, TargetCharac5Id) is not null)
                   )
               ) then
          if aInputIdList is null then
            aInputIdList  := ',' || to_char(aTargetPositionId) || ',';
          else
            aInputIdList  := aInputIdList || to_char(aTargetPositionId) || ',';
          end if;
        end if;

        ---
        -- Quantité de base du détail courant
        -- Si transfert quantité alors
        --   Si gesion de pièce alors
        --     quantité de base du détail = 1 * le signe de la quantité à copier
        --     quantité de base du détail en us = 1 * le signe de la quantité à copier
        --   Sinon
        --     quantité de base du détail = quantité à copier * facteur de conversion parent /
        --                                  facteur de conversion
        --     quantité de base du détail en us = quantité à copier * facteur de conversion parent
        -- Sinon
        --   quantité de base du détail = 0
        --   quantité de base du détail en us = 0
        --
        -- (us = unité de stockage)
        --
        if (aTransfertQuantity = 1) then
          if (TargetGestPiece = 1) then
            -- Pour le traitement des détails de position avec gestion des numéros de série, la facteur de conversion est
            -- toujours de 1.
            declare
              i pls_integer;
            begin
              if SourceDetail_tuple.DCD_QUANTITY <> 0 then
                for i in 1 .. abs(SourceDetail_tuple.DCD_QUANTITY) loop
                  vtblDetail(i).PDE_BASIS_QUANTITY     := 1 * sign(SourceDetail_tuple.DCD_QUANTITY);
                  vtblDetail(i).PDE_BASIS_QUANTITY_SU  := 1 * sign(SourceDetail_tuple.DCD_QUANTITY);

                  if aInitQteMvt = 1 then
                    vtblDetail(i).PDE_MOVEMENT_QUANTITY  := 1 * sign(SourceDetail_tuple.DCD_QUANTITY);
                  end if;

                  if     i > 1
                     and (    vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1 is null
                          and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2 is null
                          and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3 is null
                          and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4 is null
                          and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5 is null
                         ) then
                    -- Ne pas reprendre la valeur de type N° de série lors du split du détail
                    if targetCharacType1 <> '3' then
                      vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1  := vtblDetail(1).PDE_CHARACTERIZATION_VALUE_1;
                    end if;

                    if targetCharacType2 <> '3' then
                      vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2  := vtblDetail(1).PDE_CHARACTERIZATION_VALUE_2;
                    end if;

                    if targetCharacType3 <> '3' then
                      vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3  := vtblDetail(1).PDE_CHARACTERIZATION_VALUE_3;
                    end if;

                    if targetCharacType4 <> '3' then
                      vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4  := vtblDetail(1).PDE_CHARACTERIZATION_VALUE_4;
                    end if;

                    if targetCharacType5 <> '3' then
                      vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5  := vtblDetail(1).PDE_CHARACTERIZATION_VALUE_5;
                    end if;
                  end if;
                end loop;
              else
                vtblDetail(1).PDE_BASIS_QUANTITY     := 0;
                vtblDetail(1).PDE_BASIS_QUANTITY_SU  := 0;
                vtblDetail(1).PDE_MOVEMENT_QUANTITY  := 0;
              end if;
            end;
          else
            /**
            * Détermine s'il faut convertir la quantité. C'est le cas si le facteur
            * de conversion parent est différent du facteur de conversion fils.
            * Attention, il faut aussi tenir compte du fait que la conversion ne
            * doit pas se faire lorsque l'utilisateur a intentionnellement modifié
            * le facteur dans le grid de décharge (par l'intermédaire de la
            * modification de la quantité en unité de stockage).
            */
            if (SourceDetail_tuple.POS_CONVERT_FACTOR <> aConvertFactorQty) then
              vtblDetail(1).PDE_BASIS_QUANTITY  := SourceDetail_tuple.DCD_QUANTITY * SourceDetail_tuple.POS_CONVERT_FACTOR / aConvertFactorQty;
              vtblDetail(1).PDE_BASIS_QUANTITY  := ACS_FUNCTION.RoundNear(vtblDetail(1).PDE_BASIS_QUANTITY, 1 / power(10, aCDANumberOfDecimal), 0);
            else
              vtblDetail(1).PDE_BASIS_QUANTITY  := SourceDetail_tuple.DCD_QUANTITY;
            end if;

            vtblDetail(1).PDE_BASIS_QUANTITY_SU  := ACS_FUNCTION.RoundNear(SourceDetail_tuple.DCD_QUANTITY_SU, 1 / power(10, aGoodNumberOfDecimal), 1);

            if aInitQteMvt = 1 then
              vtblDetail(1).PDE_MOVEMENT_QUANTITY  := vtblDetail(1).PDE_BASIS_QUANTITY_SU;
            end if;
          end if;
        else
          vtblDetail(1).PDE_BASIS_QUANTITY     := 0;
          vtblDetail(1).PDE_BASIS_QUANTITY_SU  := 0;
          vtblDetail(1).PDE_MOVEMENT_QUANTITY  := 0;
        end if;

        ---
        -- Valeur du mouvement
        --
        MovementValue                               := 0;

        if     (aInitPriceMvt = 1)
           and not(aTypePos in('9', '10') ) then
          if (aTargetAdminDomain = '2') then   -- Domaine vente
            MovementValue  := aTargetUnitCostprice * vtblDetail(1).PDE_BASIS_QUANTITY_SU;
          else
            MovementValue  := vtblDetail(1).PDE_BASIS_QUANTITY_SU * aTargetNetUnitValue;

            if aTargetCurrencyId <> acs_function.GetLocalCurrencyId then
              -- Conversion prix du mouvement en monnaie de base
              MovementValue  := ACS_FUNCTION.ConvertAmountForView(MovementValue, aTargetCurrencyId, acs_function.GetLocalCurrencyId, aDateRef, 0, 0, 0, 1);
            end if;
          end if;
        end if;

        ---
        -- Date du mouvement
        if aTransfertMovementDate = 1 then
          movementDate  := SourceDetail_tuple.pde_movement_date;
        else
          movementDate  := aDateRef;
        end if;

        if vSmartLink then
          BalanceQuantityParentTarget  := 0;
          BalanceQuantityParentSource  := 0;

          /* Premier record de l'ensemble des records de même père. */
          if (vOldFatherDetail <> SourceDetail_tuple.doc_position_detail_id) then
            /**
            * Initialisation de la quantité soldée sur le parent ou sujet à un
            * dépassement de quantité. Définit selon le calcul suivant :
            *
            * Quantité soldée sur le parent := Quantité final du détail père -
            *                                  somme de Quantité des quantités à décharger.
            */
            BalanceQuantityParentTarget  := vBalancedQuantities;
            BalanceQuantityParentSource  := vBalancedQuantities;
          end if;
        else
          ---
          -- Quantité soldée sur parent (balanced quantity parent)
          -- Si solde du parent ou dépassement de quantité alors
          --   quantité soldé sur parent = ( quantité solde du parent - quantité à décharger ) *
          --                               facteur de conversion parent / facteur de conversion
          --   quantité soldé sur parent en unité parent = ( quantité solde du parent - quantité à décharger )
          -- Sinon
          --   quantité soldé sur parent = 0
          --   quantité soldé sur parent en unité parent = 0
          BalanceQuantityParentTarget  := 0;
          BalanceQuantityParentSource  := 0;

          if    (SourceDetail_tuple.DCD_BALANCE_FLAG = 1)
             or (abs(SourceDetail_tuple.PDE_BALANCE_QUANTITY) < abs(SourceDetail_tuple.DCD_QUANTITY) ) then
            if     (SourceDetail_tuple.POS_CONVERT_FACTOR <> aConvertFactor)
               and (SourceDetail_tuple.POS_CONVERT_FACTOR = SourceDetail_tuple.POS_CONVERT_FACTOR_CALC) then
              BalanceQuantityParentTarget  :=
                            (SourceDetail_tuple.PDE_BALANCE_QUANTITY - SourceDetail_tuple.DCD_QUANTITY) * SourceDetail_tuple.POS_CONVERT_FACTOR
                            / aConvertFactor;
            else
              BalanceQuantityParentTarget  :=(SourceDetail_tuple.PDE_BALANCE_QUANTITY - SourceDetail_tuple.DCD_QUANTITY);
            end if;

            BalanceQuantityParentSource  :=(SourceDetail_tuple.PDE_BALANCE_QUANTITY - SourceDetail_tuple.DCD_QUANTITY);
          end if;
        end if;

        /* Cummul la quantité soldée sur détail de position parent. */
        aCummulBalanceQuantityParent                := aCummulBalanceQuantityParent + BalanceQuantityParentSource;

        ---
        -- Recherche de la quantité valeur utilisé pour le détail courant
        --
        if ( (abs(aBalanceValueParent) - abs(SourceDetail_tuple.DCD_QUANTITY) ) > 0) then
          ValueQuantityUsed  := SourceDetail_tuple.DCD_QUANTITY;
        else
          ValueQuantityUsed  := aBalanceValueParent;
        end if;

        if     (aSourceGestDelay = 1)
           and (SourceDetail_tuple.DCD_UPDATE_PARENT_DELAY = 1) then
          gestParentDelay  := 1;
        else
          gestParentDelay  := 0;
        end if;

        ---
        -- Mise à jour du détail parent (délais)
        --
        update DOC_POSITION_DETAIL
           set DIC_DELAY_UPDATE_TYPE_ID = decode(gestParentDelay, 1, SourceDetail_tuple.DIC_DELAY_UPDATE_TYPE_ID, DIC_DELAY_UPDATE_TYPE_ID)
             , PDE_DELAY_UPDATE_TEXT = decode(gestParentDelay, 1, SourceDetail_tuple.PDE_DELAY_UPDATE_TEXT, PDE_DELAY_UPDATE_TEXT)
             , PDE_BASIS_DELAY = decode(gestParentDelay, 1, SourceDetail_tuple.PDE_BASIS_DELAY, PDE_BASIS_DELAY)
             , PDE_INTERMEDIATE_DELAY = decode(gestParentDelay, 1, SourceDetail_tuple.PDE_INTERMEDIATE_DELAY, PDE_INTERMEDIATE_DELAY)
             , PDE_FINAL_DELAY = decode(gestParentDelay, 1, SourceDetail_tuple.PDE_FINAL_DELAY, PDE_FINAL_DELAY)
             , PDE_SQM_ACCEPTED_DELAY = decode(gestParentDelay, 1, SourceDetail_tuple.PDE_SQM_ACCEPTED_DELAY, PDE_SQM_ACCEPTED_DELAY)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_DETAIL_ID = SourceDetail_tuple.DOC_POSITION_DETAIL_ID;

        -- Traitement de l'éventuel splitting du détail de position en cours de décharge.
        declare
          i pls_integer := 1;
        begin
          while i <= vtblDetail.count loop
            vTplDetail.DOC_GAUGE_FLOW_ID             := aFlowId;
            vTplDetail.DOC_POSITION_ID               := aTargetPositionId;
            vTplDetail.DOC_DOC_POSITION_DETAIL_ID    := SourceDetail_tuple.DOC_POSITION_DETAIL_ID;
            vTplDetail.DOC2_DOC_POSITION_DETAIL_ID   := nvl(SourceDetail_tuple.DOC2_DOC_POSITION_DETAIL_ID, SourceDetail_tuple.DOC_POSITION_DETAIL_ID);

            if aGestDelay = 1 then
              vTplDetail.PDE_BASIS_DELAY         := SourceDetail_tuple.PDE_BASIS_DELAY;
              vTplDetail.PDE_INTERMEDIATE_DELAY  := SourceDetail_tuple.PDE_INTERMEDIATE_DELAY;
              vTplDetail.PDE_FINAL_DELAY         := SourceDetail_tuple.PDE_FINAL_DELAY;
            else
              vTplDetail.PDE_BASIS_DELAY         := null;
              vTplDetail.PDE_INTERMEDIATE_DELAY  := null;
              vTplDetail.PDE_FINAL_DELAY         := null;
            end if;

            vTplDetail.PDE_INTERMEDIATE_QUANTITY     := vtblDetail(i).PDE_BASIS_QUANTITY;
            vTplDetail.PDE_FINAL_QUANTITY            := vtblDetail(i).PDE_BASIS_QUANTITY;
            vTplDetail.PDE_BASIS_QUANTITY_SU         := vtblDetail(i).PDE_BASIS_QUANTITY_SU;
            vTplDetail.PDE_INTERMEDIATE_QUANTITY_SU  := vtblDetail(i).PDE_BASIS_QUANTITY_SU;
            vTplDetail.PDE_FINAL_QUANTITY_SU         := vtblDetail(i).PDE_BASIS_QUANTITY_SU;

            if aBalanceStatus = 1 then
              vTplDetail.PDE_BALANCE_QUANTITY  := vtblDetail(i).PDE_BASIS_QUANTITY;
            else
              vTplDetail.PDE_BALANCE_QUANTITY  := 0;
            end if;

            vTplDetail.PDE_BALANCE_QUANTITY_PARENT   := BalanceQuantityParentTarget;

            if aInitQteMvt = 1 then
              vTplDetail.PDE_MOVEMENT_QUANTITY  := vtblDetail(i).PDE_MOVEMENT_QUANTITY;
            else
              vTplDetail.PDE_MOVEMENT_QUANTITY  := 0;
            end if;

            vTplDetail.PDE_MOVEMENT_VALUE            := MovementValue;
            vTplDetail.PDE_MOVEMENT_DATE             := MovementDate;
            vTplDetail.PDE_CHARACTERIZATION_VALUE_1  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1;
            vTplDetail.PDE_CHARACTERIZATION_VALUE_2  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2;
            vTplDetail.PDE_CHARACTERIZATION_VALUE_3  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3;
            vTplDetail.PDE_CHARACTERIZATION_VALUE_4  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4;
            vTplDetail.PDE_CHARACTERIZATION_VALUE_5  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5;
            vTplDetail.GCO_CHARACTERIZATION_ID       := TargetCharac1Id;
            vTplDetail.GCO_GCO_CHARACTERIZATION_ID   := TargetCharac2Id;
            vTplDetail.GCO2_GCO_CHARACTERIZATION_ID  := TargetCharac3Id;
            vTplDetail.GCO3_GCO_CHARACTERIZATION_ID  := TargetCharac4Id;
            vTplDetail.GCO4_GCO_CHARACTERIZATION_ID  := TargetCharac5Id;
            vTplDetail.STM_LOCATION_ID               := TargetLocationId;
            vTplDetail.STM_STM_LOCATION_ID           := TargetTransLocationID;
            vTplDetail.DIC_PDE_FREE_TABLE_1_ID       := SourceDetail_tuple.DIC_PDE_FREE_TABLE_1_ID;
            vTplDetail.DIC_PDE_FREE_TABLE_2_ID       := SourceDetail_tuple.DIC_PDE_FREE_TABLE_2_ID;
            vTplDetail.DIC_PDE_FREE_TABLE_3_ID       := SourceDetail_tuple.DIC_PDE_FREE_TABLE_3_ID;
            vTplDetail.PDE_DECIMAL_1                 := SourceDetail_tuple.PDE_DECIMAL_1;
            vTplDetail.PDE_DECIMAL_2                 := SourceDetail_tuple.PDE_DECIMAL_2;
            vTplDetail.PDE_DECIMAL_3                 := SourceDetail_tuple.PDE_DECIMAL_3;
            vTplDetail.PDE_TEXT_1                    := SourceDetail_tuple.PDE_TEXT_1;
            vTplDetail.PDE_TEXT_2                    := SourceDetail_tuple.PDE_TEXT_2;
            vTplDetail.PDE_TEXT_3                    := SourceDetail_tuple.PDE_TEXT_3;
            vTplDetail.PDE_DATE_1                    := SourceDetail_tuple.PDE_DATE_1;
            vTplDetail.PDE_DATE_2                    := SourceDetail_tuple.PDE_DATE_2;
            vTplDetail.PDE_DATE_3                    := SourceDetail_tuple.PDE_DATE_3;
            vTplDetail.FAL_SCHEDULE_STEP_ID          := SourceDetail_tuple.FAL_SCHEDULE_STEP_ID;

            -- Reprendre l'id du lot si la "Gestion du lot" du gabarit position cible est "001 - Sous-traitance d'achat"
            if lvCDocLotType = '001' then
              vTplDetail.FAL_LOT_ID  := SourceDetail_tuple.FAL_LOT_ID;
            else
              vTplDetail.FAL_LOT_ID  := null;
            end if;

            -- Ne pas reprendre l'id de l'opération si la "Gestion du lot" du gabarit position source est "001 - Sous-traitance d'achat
            -- mais pas le gabarit position cible. En principe dans le cas du retour marchandise du sous-traitant. }
            if     (SourceDetail_tuple.C_DOC_LOT_TYPE = '001')
               and lvCDocLotType is null then
              vTplDetail.FAL_SCHEDULE_STEP_ID  := null;
            end if;

            vTplDetail.PDE_BASIS_QUANTITY            := vtblDetail(i).PDE_BASIS_QUANTITY;
            vTplDetail.PDE_INTERMEDIATE_QUANTITY     := vtblDetail(i).PDE_BASIS_QUANTITY;
            vTplDetail.PDE_FINAL_QUANTITY            := vtblDetail(i).PDE_BASIS_QUANTITY;
            vTplDetail.PDE_BASIS_QUANTITY_SU         := vtblDetail(i).PDE_BASIS_QUANTITY_SU;
            vTplDetail.PDE_INTERMEDIATE_QUANTITY_SU  := vtblDetail(i).PDE_BASIS_QUANTITY_SU;
            vTplDetail.PDE_FINAL_QUANTITY_SU         := vtblDetail(i).PDE_BASIS_QUANTITY_SU;

            if     vTargetGestInstall = 1
               and vSourceGestInstall = 1 then
              vTplDetail.DOC_RECORD_ID  := SourceDetail_tuple.DOC_RECORD_ID;
            else
              vTplDetail.DOC_RECORD_ID  := null;
            end if;

            vTplDetail.DOC_DOCUMENT_ID               := aTargetDocumentId;
            vTplDetail.DOC_GAUGE_RECEIPT_ID          := aGaugeReceiptId;
            vTplDetail.DOC_GAUGE_COPY_ID             := null;

            if aGestDelay = 1 then
              if SourceDetail_tuple.DCD_UPDATE_PARENT_DELAY = 1 then
                vTplDetail.DIC_DELAY_UPDATE_TYPE_ID  := aDelayUpdateType;
                vTplDetail.PDE_DELAY_UPDATE_TEXT     := null;
              else
                vTplDetail.DIC_DELAY_UPDATE_TYPE_ID  := SourceDetail_tuple.DIC_DELAY_UPDATE_TYPE_ID;
                vTplDetail.PDE_DELAY_UPDATE_TEXT     := SourceDetail_tuple.PDE_DELAY_UPDATE_TEXT;
              end if;
            else
              vTplDetail.DIC_DELAY_UPDATE_TYPE_ID  := null;
              vTplDetail.PDE_DELAY_UPDATE_TEXT     := null;
            end if;

            vTplDetail.PDE_GENERATE_MOVEMENT         := 0;
            vTplDetail.PDE_BALANCE_PARENT            := SourceDetail_tuple.DCD_BALANCE_FLAG;
            vTplDetail.C_PDE_CREATE_MODE             := SourceDetail_tuple.C_PDE_CREATE_MODE;
            vTplDetail.DOC_PDE_LITIG_ID              := SourceDetail_tuple.DOC_PDE_LITIG_ID;
            vTplDetail.A_DATECRE                     := sysdate;
            vTplDetail.A_IDCRE                       := PCS.PC_I_LIB_SESSION.GetUserIni;
            vTplDetail.PDE_ST_PT_REJECT              := SourceDetail_tuple.PDE_ST_PT_REJECT;
            vTplDetail.PDE_ST_CPT_REJECT             := SourceDetail_tuple.PDE_ST_CPT_REJECT;

            -- Traitement des détails de position avec caratérisation. Valable uniquement si le facteur de conversion est à 1. Donc
            -- que les quantités en unité de stockage sont identique aux quantités en unité de gestion.
            if     (vTplDetail.PDE_BASIS_QUANTITY > 0)
               and (aConvertFactor = 1)
               and (   TargetCharac1Id is not null
                    or TargetCharac2Id is not null
                    or TargetCharac3Id is not null
                    or TargetCharac4Id is not null
                    or TargetCharac5Id is not null
                   )
               and vTplDetail.PDE_CHARACTERIZATION_VALUE_1 is null
               and vTplDetail.PDE_CHARACTERIZATION_VALUE_2 is null
               and vTplDetail.PDE_CHARACTERIZATION_VALUE_3 is null
               and vTplDetail.PDE_CHARACTERIZATION_VALUE_4 is null
               and vTplDetail.PDE_CHARACTERIZATION_VALUE_5 is null then
              declare
                vQuantity        DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
                vBalanceQuantity DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
              begin
                vQuantity         := vtblDetail(i).PDE_BASIS_QUANTITY;
                vBalanceQuantity  := null;

                while nvl(vBalanceQuantity, 1) > 0
                 and (nvl(vBalanceQuantity, 0) <> vQuantity) loop
                  vtblDetail(i).PDE_BASIS_QUANTITY         := vQuantity;
                  vQuantity                                := nvl(vBalanceQuantity, vQuantity);

                  if MovementSort = 'SOR' then
                    -- Recherche les valeurs des caractérisations qui sont automatiquement reprises en fonction des disponibilités
                    -- en stock.
                    GCO_I_LIB_CHARACTERIZATION.getAutoCharFromStock(aTargetGoodId
                                                                  , TargetCharac1Id
                                                                  , TargetCharac2Id
                                                                  , TargetCharac3Id
                                                                  , TargetCharac4Id
                                                                  , TargetCharac5Id
                                                                  , TargetLocationId
                                                                  , null   --aThirdId
                                                                  , vQuantity
                                                                  , sysdate   -- aDateRef         date document
                                                                  , vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1
                                                                  , vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2
                                                                  , vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3
                                                                  , vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4
                                                                  , vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5
                                                                  , vAutoChar
                                                                  , vBalanceQuantity
                                                                   );
                  else   -- MovementSort = 'ENT'
                    -- Recherche les valeurs de caractérisations chronologiques dont nous avons encore besoin.
                    if     (targetCharStk1 = 1)
                       and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1 is null then
                      if targetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1  :=
                                                GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac1Id, sysdate, 'DOC_POSITION', aTargetPositionId);
                      elsif     targetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                            and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1 then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
                      end if;
                    end if;

                    if     (targetCharStk2 = 1)
                       and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2 is null then
                      if targetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2  :=
                                                GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac2Id, sysdate, 'DOC_POSITION', aTargetPositionId);
                      elsif     targetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                            and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1 then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
                      end if;
                    end if;

                    if     (targetCharStk3 = 1)
                       and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3 is null then
                      if targetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3  :=
                                                GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac3Id, sysdate, 'DOC_POSITION', aTargetPositionId);
                      elsif     targetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                            and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1 then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
                      end if;
                    end if;

                    if     (targetCharStk4 = 1)
                       and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4 is null then
                      if targetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4  :=
                                                GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac4Id, sysdate, 'DOC_POSITION', aTargetPositionId);
                      elsif     targetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                            and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1 then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
                      end if;
                    end if;

                    if     (targetCharStk5 = 1)
                       and vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5 is null then
                      if targetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5  :=
                                                GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac5Id, sysdate, 'DOC_POSITION', aTargetPositionId);
                      elsif     targetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                            and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1 then
                        vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
                      end if;
                    end if;

                    -- On utilise, pour les caractérisations chronologiques en entrée, toute la quantité initiale du détail courant.
                    vBalanceQuantity  := 0;
                  end if;

                  vTplDetail.PDE_BASIS_QUANTITY            := vQuantity - vBalanceQuantity;
                  vTplDetail.PDE_INTERMEDIATE_QUANTITY     := vQuantity - vBalanceQuantity;
                  vTplDetail.PDE_FINAL_QUANTITY            := vQuantity - vBalanceQuantity;
                  vTplDetail.PDE_BASIS_QUANTITY_SU         := vQuantity - vBalanceQuantity;
                  vTplDetail.PDE_INTERMEDIATE_QUANTITY_SU  := vQuantity - vBalanceQuantity;
                  vTplDetail.PDE_FINAL_QUANTITY_SU         := vQuantity - vBalanceQuantity;

                  if aBalanceStatus = 1 then
                    vTplDetail.PDE_BALANCE_QUANTITY  := vTplDetail.PDE_BASIS_QUANTITY;
                  else
                    vTplDetail.PDE_BALANCE_QUANTITY  := 0;
                  end if;

                  vTplDetail.PDE_BALANCE_QUANTITY_PARENT   := BalanceQuantityParentTarget;

                  if aInitQteMvt = 1 then
                    vTplDetail.PDE_MOVEMENT_QUANTITY  := vQuantity - vBalanceQuantity;
                  end if;

                  vTplDetail.PDE_CHARACTERIZATION_VALUE_1  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_1;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_2  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_2;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_3  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_3;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_4  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_4;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_5  := vtblDetail(i).PDE_CHARACTERIZATION_VALUE_5;

                  if vTplDetail.PDE_BASIS_QUANTITY > 0 then
                    -- Les délais du détail sont traités dans le trigger DOC_V_PDE_IOI_QUANTITY s'ils ne sont pas repris du parent ici
                    vTplDetail.DOC_POSITION_DETAIL_ID  := getNewId;

                    insert into V_DOC_POSITION_DETAIL_IO
                         values vTplDetail;

                    -- uniquement sur la première position et si il y  a insertion
                    BalanceQuantityParentTarget        := 0;
                  end if;

                  vBalanceQuantity                         := nvl(vBalanceQuantity, 0);

                  if     vBalanceQuantity > 0
                     and vBalanceQuantity <> vtblDetail(i).PDE_BASIS_QUANTITY then
                    i  := i + 1;
                  end if;
                end loop;

                if     vBalanceQuantity > 0
                   and (vBalanceQuantity = vQuantity) then
                  vTplDetail.PDE_BASIS_QUANTITY            := vBalanceQuantity;
                  vTplDetail.PDE_INTERMEDIATE_QUANTITY     := vBalanceQuantity;
                  vTplDetail.PDE_FINAL_QUANTITY            := vBalanceQuantity;
                  vTplDetail.PDE_BASIS_QUANTITY_SU         := vBalanceQuantity;
                  vTplDetail.PDE_INTERMEDIATE_QUANTITY_SU  := vBalanceQuantity;
                  vTplDetail.PDE_FINAL_QUANTITY_SU         := vBalanceQuantity;

                  if aBalanceStatus = 1 then
                    vTplDetail.PDE_BALANCE_QUANTITY  := vBalanceQuantity;
                  else
                    vTplDetail.PDE_BALANCE_QUANTITY  := 0;
                  end if;

                  vTplDetail.PDE_BALANCE_QUANTITY_PARENT   := BalanceQuantityParentTarget;

                  if aInitQteMvt = 1 then
                    vTplDetail.PDE_MOVEMENT_QUANTITY  := vBalanceQuantity;
                  end if;

                  vTplDetail.PDE_CHARACTERIZATION_VALUE_1  := null;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_2  := null;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_3  := null;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_4  := null;
                  vTplDetail.PDE_CHARACTERIZATION_VALUE_5  := null;
                  -- Les délais du détail sont traités dans le trigger DOC_V_PDE_IOI_QUANTITY s'ils ne sont pas repris du parent ici
                  vTplDetail.DOC_POSITION_DETAIL_ID        := getNewId;

                  insert into V_DOC_POSITION_DETAIL_IO
                       values vTplDetail;

                  vBalanceQuantity                         := 0;
                end if;
              end;
            else
              -- Les délais du détail sont traités dans le trigger DOC_V_PDE_IOI_QUANTITY s'ils ne sont pas repris du parent ici
              vTplDetail.DOC_POSITION_DETAIL_ID  := getNewId;

              insert into V_DOC_POSITION_DETAIL_IO
                   values vTplDetail;
            end if;

            -- uniquement sur la première position
            BalanceQuantityParentTarget              := 0;
            i                                        := i + 1;
          end loop;
        end;

        --
        -- Sauvegarde des attributions avant mise a jour du detail de position pere. Attention, le traitement doit se
        -- faire uniquement si le bien cible est égal au bien source. Aucun traitement ne doit se faire sur le
        -- composé d'une position kit ou assemblage.
        --
        -- Cas 1 CF -> BR : Transformation d'une attribution besoin/appro en besoin/stock - Partie sauvegarde
        -- Cas 2 CF -> CF : Deplacement d'une attribution besoin/appro1 sur besoin/appro2 - Partie sauvegarde
        -- Cas 3 CC -> CC : Deplacement d'une attribution besoin1/appro sur besoin2/appro ou besoin1/stock sur
        -- besoin2/stock - Partie sauvegarde
        --
        if     SourceDetail_tuple.POS_GOOD_ID = aTargetGoodId
           and not(aTypePos in('7', '8', '9', '10') ) then
          -- Garantit la suppression des données de la table temporaire même si la table est en delete on commit.
          delete from FAL_TMP_REPORT_ATTRIB;

          -- Recherche l'emplacement reel associée au détail de position courant. Je n'utilise pas les variables qui ont
          -- été utilisé lors de l'insert du détail de position courante car il se peut que des triggers interviennent
          -- sur les données initiales.
          select STM_LOCATION_ID
            into stmReelLocationID
            from DOC_POSITION_DETAIL
           where DOC_POSITION_DETAIL_ID = vTplDetail.DOC_POSITION_DETAIL_ID;

          if (SourceDetail_tuple.C_GAUGE_TYPE = '1') then   -- le détail source des de type Besoin
            -- Chargement attributions sur stock
            -- Chargement de la table temporaire de report d'attribution. On stock le lien et éventuellement
            -- les positions de stock si on décharge un besoin sur un autre besoin.
            --
            insert into FAL_TMP_REPORT_ATTRIB
                        (FAL_TMP_REPORT_ATTRIB_ID
                       , FAL_NETWORK_LINK_ID
                       , FAL_NETWORK_NEED_ID
                       , FAL_NETWORK_SUPPLY_ID
                       , STM_STOCK_POSITION_ID
                       , STM_LOCATION_ID
                       , FRA_QTY
                       , FRA_NEED_DELAY
                       , A_DATECRE
                       , A_IDCRE
                        )
              select init_id_seq.nextval   -- FAL_TMP_REPORT_ATTRIB_ID
                   , FLN.FAL_NETWORK_LINK_ID   -- FAL_NETWORK_LINK_ID
                   , FAN.FAL_NETWORK_NEED_ID   -- FAL_NETWORK_NEED_ID
                   , null   -- FAL_NETWORK_SUPPLY_ID
                   , FLN.STM_STOCK_POSITION_ID   -- STM_STOCK_POSITION_ID
                   , FLN.STM_LOCATION_ID   -- STM_LOCATION_ID
                   , FLN.FLN_QTY   -- FRA_QTY
                   , FLN.FLN_NEED_DELAY   -- FRA_NEED_DELAY
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_NETWORK_LINK FLN
                   , FAL_NETWORK_NEED FAN
                   , STM_STOCK_POSITION STO
               where FAN.DOC_POSITION_DETAIL_ID = SourceDetail_tuple.DOC_POSITION_DETAIL_ID
                 and FLN.FAL_NETWORK_NEED_ID = FAN.FAL_NETWORK_NEED_ID
                 and STO.STM_STOCK_POSITION_ID = FLN.STM_STOCK_POSITION_ID;

            -- Chargement attributions sur appro
            -- Chargement de la table temporaire de report d'attribution. On stock le lien et éventuellement
            -- les approvisionnements si on décharge un besoin sur un autre besoin.
            --
            insert into FAL_TMP_REPORT_ATTRIB
                        (FAL_TMP_REPORT_ATTRIB_ID
                       , FAL_NETWORK_LINK_ID
                       , FAL_NETWORK_NEED_ID
                       , FAL_NETWORK_SUPPLY_ID
                       , STM_STOCK_POSITION_ID
                       , STM_LOCATION_ID
                       , FRA_QTY
                       , FRA_NEED_DELAY
                       , A_DATECRE
                       , A_IDCRE
                        )
              select init_id_seq.nextval   -- FAL_TMP_REPORT_ATTRIB_ID
                   , FLN.FAL_NETWORK_LINK_ID   -- FAL_NETWORK_LINK_ID
                   , FAN.FAL_NETWORK_NEED_ID   -- FAL_NETWORK_NEED_ID
                   , FAS.FAL_NETWORK_SUPPLY_ID   -- FAL_NETWORK_SUPPLY_ID
                   , null   -- STM_STOCK_POSITION_ID
                   , stmReelLocationID   -- STM_LOCATION_ID
                   , FLN.FLN_QTY   -- FRA_QTY
                   , FLN.FLN_NEED_DELAY   -- FRA_NEED_DELAY
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_NETWORK_LINK FLN
                   , FAL_NETWORK_NEED FAN
                   , FAL_NETWORK_SUPPLY FAS
               where FAN.DOC_POSITION_DETAIL_ID = SourceDetail_tuple.DOC_POSITION_DETAIL_ID
                 and FLN.FAL_NETWORK_NEED_ID = FAN.FAL_NETWORK_NEED_ID
                 and FAS.FAL_NETWORK_SUPPLY_ID = FLN.FAL_NETWORK_SUPPLY_ID;
          elsif(SourceDetail_tuple.C_GAUGE_TYPE = '2') then   -- le détail source et de type Appro
            -- Chargement de la table temporaire de report d'attribution. On stock le lien et éventuellement
            -- les approvisionnements si on déchage un appro sur un autre appro.
            --
            insert into FAL_TMP_REPORT_ATTRIB
                        (FAL_TMP_REPORT_ATTRIB_ID
                       , FAL_NETWORK_LINK_ID
                       , FAL_NETWORK_NEED_ID
                       , FAL_NETWORK_SUPPLY_ID
                       , STM_STOCK_POSITION_ID
                       , STM_LOCATION_ID
                       , FRA_QTY
                       , FRA_NEED_DELAY
                       , A_DATECRE
                       , A_IDCRE
                        )
              select init_id_seq.nextval   -- FAL_TMP_REPORT_ATTRIB_ID
                   , FLN.FAL_NETWORK_LINK_ID   -- FAL_NETWORK_LINK_ID
                   , FAN.FAL_NETWORK_NEED_ID   -- FAL_NETWORK_NEED_ID
                   , FAS.FAL_NETWORK_SUPPLY_ID   -- FAL_NETWORK_SUPPLY_ID
                   , FLN.STM_STOCK_POSITION_ID   -- STM_STOCK_POSITION_ID
                   , decode(FLN.STM_STOCK_POSITION_ID, null, stmReelLocationID, FLN.STM_LOCATION_ID)   -- STM_LOCATION_ID
                   , FLN.FLN_QTY   -- FRA_QTY
                   , FLN.FLN_NEED_DELAY   -- FRA_NEED_DELAY
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_NETWORK_LINK FLN
                   , FAL_NETWORK_NEED FAN
                   , FAL_NETWORK_SUPPLY FAS
               where FAS.DOC_POSITION_DETAIL_ID = SourceDetail_tuple.DOC_POSITION_DETAIL_ID
                 and FLN.FAL_NETWORK_SUPPLY_ID = FAS.FAL_NETWORK_SUPPLY_ID
                 and FAN.FAL_NETWORK_NEED_ID = FLN.FAL_NETWORK_NEED_ID;
          end if;
        end if;

        ---
        -- Mise à jour du détail parent (quantité solde) et retrait éventuel des attributions.
        --
        -- A voir pour déplacer avec la mise à jour des attrib dans trigger Instead OF
        --
        update DOC_POSITION_DETAIL
           set PDE_BALANCE_QUANTITY =
                 decode(SourceDetail_tuple.DCD_BALANCE_FLAG
                      , 1, 0
                      , decode(sign(PDE_BASIS_QUANTITY)
                             , -1, greatest(least( (PDE_BALANCE_QUANTITY - SourceDetail_tuple.DCD_QUANTITY), 0), PDE_FINAL_QUANTITY)
                             , least(greatest( (PDE_BALANCE_QUANTITY - SourceDetail_tuple.DCD_QUANTITY - BalanceQuantityParentSource), 0), PDE_FINAL_QUANTITY)
                              )
                       )
             , FAL_NETWORK_LINK_ID = SourceDetail_tuple.FAL_NETWORK_LINK_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_DETAIL_ID = SourceDetail_tuple.DOC_POSITION_DETAIL_ID;

        --
        -- Transformation ou deplacement des attributions apres la mise à jour du detail de position pere.
        -- Attention, le traitement doit se faire uniquement si le bien cible est égal au bien source.
        --
        -- Cas 1 CF -> BR : Transformation d'une attribution besoin/appro en besoin/stock - Partie repartition
        -- Cas 2 CF -> CF : Deplacement d'une attribution besoin/appro1 sur besoin/appro2 - Partie repartition
        -- Cas 3 CC -> CC : Deplacement d'une attribution besoin1/appro sur besoin2/appro ou besoin1/stock sur
        -- besoin2/stock - Partie repartition
        --
        -- Déplace les attributions besoin/appro ou besoin/stock incrites dans la table temporaire de report d'attribution sur
        -- des attributions besoin/stock d'après les positions de stock généré par la position courante ou des attributions
        -- besoin/appro d'apres les besoins ou appros générés par le detail de position courant.   }
        if SourceDetail_tuple.POS_GOOD_ID = aTargetGoodId then
          FAL_I_PRC_REPORT_ATTRIB.MoveAttributionLink(aTargetPositionId, vTplDetail.DOC_POSITION_DETAIL_ID);
        end if;

        /* Mémorise le précédent détail père. */
        vOldFatherDetail                            := SourceDetail_tuple.doc_position_detail_id;

        if SourceDetail_tuple.GAL_CURRENCY_RISK_VIRTUAL_ID is not null then
          DOC_PRC_DOCUMENT.AddDocToListParent(iDocumentId => SourceDetail_tuple.doc_document_id);
        end if;

        fetch SourceDetail
         into SourceDetail_tuple;
      end;
    end loop;

    SOURCE_DETAIL_ID              := null;

    close SourceDetail;
  end DischargePositionDetail;

  /**
  * Procedure MajParentDetail
  * Description
  *     mise à jour du détail parent lors d'une décharge
  * @author Fabrice Perotto
  * @created 08.03.2001
  * @private
  * @param aSourceDetailId id position detail parent
  * @param aSourcePositionId id position parent
  * @param aDischargeQuantity quantité à décharger
  * @param aValueQuantity quantité valeur
  * @param aBalancedQuantity quantité solde
  * @param aBalancePosition flag de solde de la position
  * @param aUpdateDelay flag de mise à jour du délai sur le parent
  * @param aDelayUpdateType valeur de dic_delay_update_type_id
  * @param aDelayUpdateText texte de mise à jour du délai
  * @param aBasisDelay délai de base
  * @param aIntermediateDelay délai intermédiaire
  * @param aFinalDelay délai final
  */
  procedure MajParentDetail(
    aSourceDetailId    in number
  , aSourcePositionId  in number
  , aDischargeQuantity in number
  , aValueQuantity     in number
  , aBalancedQuantity  in number
  , aBalancePosition   in number
  , aUpdateDelay       in number
  , aDelayUpdateType   in varchar2
  , aDelayUpdateText   in varchar2
  , aBasisDelay        in date
  , aIntermediateDelay in date
  , aFinalDelay        in date
  )
  is
  begin
    -- mise à jour du détail
    update doc_position_detail
       set pde_balance_quantity =
             decode(aBalancePosition
                  , 1, 0
                  , decode(sign(pde_basis_quantity)
                         , -1, greatest(least( (PDE_BALANCE_QUANTITY - aDischargeQuantity), 0), PDE_FINAL_QUANTITY)
                         , least(greatest( (PDE_BALANCE_QUANTITY - aDischargeQuantity - aBalancedQuantity), 0), PDE_FINAL_QUANTITY)
                          )
                   )
         , dic_delay_update_type_id = decode(aUpdateDelay, 1, aDelayUpdateType, dic_delay_update_type_id)
         , pde_delay_update_text = decode(aUpdateDelay, 1, aDelayUpdateText, pde_delay_update_text)
         , pde_basis_delay = decode(aUpdateDelay, 1, aBasisDelay, pde_basis_delay)
         , pde_intermediate_delay = decode(aUpdateDelay, 1, aIntermediateDelay, pde_intermediate_delay)
         , pde_final_delay = decode(aUpdateDelay, 1, aFinalDelay, pde_final_delay)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where doc_position_detail_id = aSourceDetailId;

    -- mise à jour de la position
    DOC_FUNCTIONS.UpdateBalancePosition(aSourcePositionId, aDischargeQuantity, aValueQuantity, aBalancedQuantity);
  end MajParentDetail;

  /**
  * Procedure CopyPositionDetail
  * Description
  *       Copie des détail de position (procedure appelée
  *       par la procedure copyPosition
  * @created fp 30.05.2001 adapted for copy on 12.06.2001
  * @lastUpdate vje 25.04.2008
  * @private
  * @Param aSourcePositionId id de la position parent,
  * @Param aTargetPositionId id de la position enfant (nouveau document),
  * @Param aTargetGoodId id du bien de la position cible,
  * @Param aTargetDocumentId Id du nouveau document,
  * @Param aSourceGaugeId Id du gabarit du document parent,
  * @Param aTargetGaugeId Id du gabarit du nouveau document,
  * @Param aConvertFactor Facteur de conversion sur la postion fille,
  * @Param aSourceCurrencyId Monnaie du document parent,
  * @Param aTargetCurrencyId Monnaie du nouveau document
  * @Param aTargetAdminDomain valeur de C_ADMIN_DOMAIN du gabarit du document cible,
  * @Param aGaugeReceiptId ID du gabarit de décharge,
  * @Param aDateRef Date de référence,
  * @Param aFlowId ID du flux,
  * @Param aInitQteMvt flag d'initialisation de la quantité mouvement,
  * @Param aInitPriceMvt flag d'initialisation du prix du mouvement,
  * @Param aTransfertStock flag d'initialisation du transfert de stock,
  * @Param aTransfertQuantity flag d'initialisation du transfert de quantité,
  * @Param aSourceGestDelay flag indiquant si le document source gère les délais,
  * @Param aGestDelay flag indiquant si le document cible gère les délais,
  * @Param aDelayUpdateType valeur de DIC_DELAY_UPDATE_TYPE,
  * @Param aSourceGestChar flag indiquant si le document source gère les caractérisations,
  * @Param aGestChar flag indiquant si le nouveau document gère les caractérisation,
  * @Param aForceCharact flag indiquant si on force la reprise des caractérisations,
  * @Param aMvtUtility flag utilisation mouvement de stock,
  * @Param aTargetUnitCostPrice prix de revient unitaire dans le document cible,
  * @Param aTargetNetUnitValue prix net unitaire cible,
  * @Param aMovementKindId id du genre de mouvement de stock cible,
  * @Param aTypePos valeur C_GAUGE_TYPE_POS cible
  * @Param aPosStockId ID du stock,
  * @Param aPosLocationId  ID emplacement de stock,
  * @Param aPosTargetTransLocationId Id enplacement stock de transfert,
  * @Param aPositionQuantity quantité de la position liée,
  * @Param aBalanceValueParent valeur solde parent,
  * @Param aBalanceStatus status solde,
  * @Param aGoodNumberOfDecimal nombre de décimal du bien,
  * @Param aCDANumberOfDecimal nombre de décimales du bien dans les données complémentaires,
  * @Param aInputIdList valeur de retour, liste des détails de position dont on doit saisir des informations manuellement;
  * @param aCopyInfoCode out      : Code d'erreur ou d'avertissement en cas de problème
  * @param aComplDataId données complémentaires de sous-traitance (permet la création du lot de sous-traitance)
  */
  procedure CopyPositionDetail(
    aSourcePositionId         in     number
  , aTargetPositionId         in     number
  , aTargetGoodId             in     number
  , aTargetDocumentId         in     number
  , aSourceGaugeId            in     number
  , aTargetGaugeId            in     number
  , aConvertFactor            in     number
  , aSourceCurrencyId         in     number
  , aTargetCurrencyId         in     number
  , aTargetAdminDomain        in     varchar2
  , aGaugeCopyId              in     number
  , aDateRef                  in     date
  , aFlowId                   in     number
  , aInitQteMvt               in     number
  , aInitPriceMvt             in     number
  , aTransfertStock           in     number
  , aTransfertQuantity        in     number
  , aSourceGestDelay          in     number
  , aGestDelay                in     number
  , aDelayUpdateType          in     varchar2
  , aSourceGestChar           in     number
  , aGestChar                 in     number
  , aForceCharact             in     number
  , aMvtUtility               in     number
  , aTargetUnitCostPrice      in     number
  , aTargetNetUnitValue       in     number
  , aMovementKindId           in     number
  , aTypePos                  in     number
  , aPosStockId               in     number
  , aPosLocationId            in     number
  , aPosTargetTransLocationId in     number
  , aPositionQuantity         in     number
  , aBalanceValueParent       in     number
  , aBalanceStatus            in     number
  , aGoodNumberOfDecimal      in     number
  , aCDANumberOfDecimal       in     number
  , aInputIdList              in out varchar2
  , aCopyInfoCode             in out varchar2
  , aComplDataId              in     number
  )
  is
    -- curseur sur les détail de positions à copier
    cursor SourceDetail(aPositionId number, newDocumentId number)
    is
      select   pde.doc_position_detail_id
             , pde.doc_position_id
             , pde.doc2_doc_position_detail_id
             , dcd.gco_good_id
             , dcd.gco_characterization_id
             , dcd.gco_gco_characterization_id
             , dcd.gco2_gco_characterization_id
             , dcd.gco3_gco_characterization_id
             , dcd.gco4_gco_characterization_id
             , dcd.pde_characterization_value_1
             , dcd.pde_characterization_value_2
             , dcd.pde_characterization_value_3
             , dcd.pde_characterization_value_4
             , dcd.pde_characterization_value_5
             , dcd.dcd_quantity
             , DCD.DCD_QUANTITY_SU
             , DCD.DCD_USE_STOCK_LOCATION_ID
             , DCD.STM_LOCATION_ID DCD_STM_LOCATION_ID
             , DCD.STM_STM_LOCATION_ID DCD_STM_STM_LOCATION_ID
             , pde.pde_balance_quantity
             , pde.pde_balance_quantity_parent
             , pde.pde_movement_date
             , PDE.PDE_ADDENDUM_SRC_PDE_ID
             , dcd.pde_basis_delay
             , dcd.pde_intermediate_delay
             , dcd.pde_final_delay
             , dcd.pde_sqm_accepted_delay
             , dcd.dic_pde_free_table_1_id
             , dcd.dic_pde_free_table_2_id
             , dcd.dic_pde_free_table_3_id
             , dcd.pde_decimal_1
             , dcd.pde_decimal_2
             , dcd.pde_decimal_3
             , dcd.pde_text_1
             , dcd.pde_text_2
             , dcd.pde_text_3
             , dcd.pde_date_1
             , dcd.pde_date_2
             , dcd.pde_date_3
             , dcd.doc_record_id
             , dcd.dic_delay_update_type_id
             , dcd.pde_delay_update_text
             , dcd.pos_convert_factor
             , nvl(DCD.C_PDE_CREATE_MODE, '201') C_PDE_CREATE_MODE
             , PDE.DOC_PDE_LITIG_ID
             , PDE.GCO_MANUFACTURED_GOOD_ID
             , PDE.FAL_LOT_ID
          from doc_position_detail pde
             , doc_pos_det_copy_discharge dcd
         where dcd.doc_position_id = aPositionId
           and dcd.crg_select = 1
           and dcd.new_document_id = newDocumentId
           and pde.doc_position_detail_id = dcd.doc_position_detail_id
      order by dcd.doc_pos_det_copy_discharge_id;

    SourceDetail_tuple    SourceDetail%rowtype;
    BasisQuantityDetail   doc_position_detail.pde_basis_quantity%type;
    BasisQuantityDetailSU doc_position_detail.pde_basis_quantity_SU%type;
    MovementValue         doc_position_detail.pde_movement_value%type;
    MovementDate          doc_position_detail.pde_movement_date%type;
    TargetLocationId      STM_LOCATION.STM_LOCATION_ID%type;
    TargetTransLocationId STM_LOCATION.STM_LOCATION_ID%type;
    TargetGestPiece       number(1)                                               default 0;
    MovementSort          stm_movement_kind.c_movement_sort%type;
    TargetCharac1Id       gco_characterization.gco_characterization_id%type;
    TargetCharac2Id       gco_characterization.gco_characterization_id%type;
    TargetCharac3Id       gco_characterization.gco_characterization_id%type;
    TargetCharac4Id       gco_characterization.gco_characterization_id%type;
    TargetCharac5Id       gco_characterization.gco_characterization_id%type;
    TargetCharacType1     gco_characterization.c_charact_type%type;
    TargetCharacType2     gco_characterization.c_charact_type%type;
    TargetCharacType3     gco_characterization.c_charact_type%type;
    TargetCharacType4     gco_characterization.c_charact_type%type;
    TargetCharacType5     gco_characterization.c_charact_type%type;
    CharValue1            doc_position_detail.pde_characterization_value_1%type;
    CharValue2            doc_position_detail.pde_characterization_value_1%type;
    CharValue3            doc_position_detail.pde_characterization_value_1%type;
    CharValue4            doc_position_detail.pde_characterization_value_1%type;
    CharValue5            doc_position_detail.pde_characterization_value_1%type;
    targetCharStk1        gco_characterization.cha_stock_management%type;
    targetCharStk2        gco_characterization.cha_stock_management%type;
    targetCharStk3        gco_characterization.cha_stock_management%type;
    targetCharStk4        gco_characterization.cha_stock_management%type;
    targetCharStk5        gco_characterization.cha_stock_management%type;
    ValueQuantityUsed     doc_position.pos_balance_qty_value%type;
    mokVerifyChar         stm_movement_kind.mok_verify_characterization%type;
    blnSetGoodUnique      boolean;
    blnSetCompUnique      boolean;
    blnVersionGoodUnique  boolean;
    blnVersionCompUnique  boolean;
    blnPropCarac          boolean;
    blnVerifStock         boolean;
    vSqmEval              number;
    vAllCharacterization  DOC_GAUGE_STRUCTURED.GAS_ALL_CHARACTERIZATION%type;
    vDateDocument         DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;   -- date du document
    vThird                DOC_POSITION.PAC_THIRD_ID%type;
    vGood                 DOC_POSITION.GCO_GOOD_ID%type;
    vPosStatus            DOC_POSITION.C_DOC_POS_STATUS%type;
    vExpValue             SQM_PENALTY.SPE_EXPECTED_VALUE%type;
    vEffValue             SQM_PENALTY.SPE_EFFECTIVE_VALUE%type;
    vAxisValue            SQM_PENALTY.SPE_INIT_VALUE%type;
    datBASIS_DELAY        DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    datINTER_DELAY        DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type;
    datFINAL_DELAY        DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
    aPosDetID             DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vTargetGestInstall    number(1);
    vSourceGestInstall    number(1);
    lnLotId               FAL_LOT.FAL_LOT_ID%type;
    lvError               varchar2(4000);
    lGacBond              DOC_GAUGE_COPY.GAC_BOND%type;
  begin
    -- Recherche les flags indiquant si l'on gère les installation (source et cible )
    begin
      select nvl(TGT.GAS_INSTALLATION_MGM, 0)
           , nvl(SRC.GAS_INSTALLATION_MGM, 0)
        into vTargetGestInstall
           , vSourceGestInstall
        from DOC_GAUGE_STRUCTURED TGT
           , DOC_GAUGE_STRUCTURED SRC
       where TGT.DOC_GAUGE_ID = aSourceGaugeId
         and SRC.DOC_GAUGE_ID = aTargetGaugeId;
    exception
      when no_data_found then
        vTargetGestInstall  := 0;
        vSourceGestInstall  := 0;
    end;

    -- recherche des id de caractérisation
    if    (aGestChar = 1)
       or aMovementKindId is not null then
      if aMovementKindId is null then
        MovementSort   := '';
        mokVerifyChar  := 1;

        select max(GAS.GAS_ALL_CHARACTERIZATION)
          into vAllCharacterization
          from DOC_GAUGE_STRUCTURED GAS
             , DOC_POSITION POS
         where POS.DOC_POSITION_ID = aTargetPositionId
           and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID;

        /* Gestion des caractérisations non morphologique dans les documents sans
           mouvements de stock. On recherche le type de mouvement en fonction du
           domaine. */
        if     (PCS.PC_CONFIG.GetConfig('DOC_CHARACTERIZATION_MODE') = '1')
           and (vAllCharacterization = 1) then
          if (aTargetAdminDomain = '1') then   /* Achat */
            MovementSort  := 'ENT';
          elsif(aTargetAdminDomain = '2') then   /* Vente */
            MovementSort  := 'SOR';
          end if;
        end if;
      else
        select max(c_movement_sort)
             , nvl(max(mok_verify_characterization), 1)
          into MovementSort
             , mokVerifyChar
          from stm_movement_kind
         where stm_movement_kind_id = aMovementKindId;
      end if;

      -- recherche des id de caractérisations du nouveau détail de position
      GCO_CHARACTERIZATION_FUNCTIONS.GetListOfCharacterization(aTargetGoodId
                                                             , aGestChar
                                                             , MovementSort
                                                             , aTargetAdminDomain
                                                             , TargetCharac1Id
                                                             , TargetCharac2Id
                                                             , TargetCharac3Id
                                                             , TargetCharac4Id
                                                             , TargetCharac5Id
                                                             , targetCharacType1
                                                             , targetCharacType2
                                                             , targetCharacType3
                                                             , targetCharacType4
                                                             , targetCharacType5
                                                             , targetCharStk1
                                                             , targetCharStk2
                                                             , targetCharStk3
                                                             , targetCharStk4
                                                             , targetCharStk5
                                                             , TargetGestPiece
                                                              );
    -- raise_application_error(-20000,to_char(aTargetGoodId)||'/'||MovementSort||'/'||aTargetAdminDomain);
    end if;

    /* Détermine si l'une des caractérisations est avec une gestion des numéros
       de lot et que la configuration ne demande pas une unicité de numéro
       par mandat ou bien. */
    blnSetGoodUnique      :=(upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_GOOD') ) = 'TRUE');
    blnSetCompUnique      :=(upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_COMP') ) = 'TRUE');
    /* Détermine si l'une des caractérisations est avec une gestion des numéros
       de version et que la configuration ne demande pas une unicité de numéro
       par mandat ou bien. */
    blnVersionGoodUnique  :=(upper(PCS.PC_CONFIG.GetConfig('STM_VERSION_SGL_NUMBERING_GOOD') ) = 'TRUE');
    blnVersionCompUnique  :=(upper(PCS.PC_CONFIG.GetConfig('STM_VERSION_SGL_NUMBERING_COMP') ) = 'TRUE');

    -- Rechercher la valeur du champ du flux de copie "Etablir lien"
    select nvl(max(GAC_BOND), 1)
      into lGacBond
      from DOC_GAUGE_COPY
     where DOC_GAUGE_COPY_ID = aGaugeCopyId;

    open SourceDetail(aSourcePositionId, aTargetDocumentId);

    fetch SourceDetail
     into SourceDetail_tuple;

    while Sourcedetail%found loop
      /* Initialisation du flag de proposition des caractérisations.
         Autorise la reprise des valeurs uniquement si le gabarit source <>
         du gabarit cible ou que l'on ne gère pas les numéros de série et les
         lots unique. */
      blnPropCarac   :=
           (mokVerifyChar = 0)
        or (     (TargetCharacType1 <> GCO_I_LIB_CONSTANT.gcCharacTypePiece)   -- Pas de gestion de pièce
            and   /* Pas de gestion de lot unique */
                not(    TargetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                    and (   blnSetGoodUnique
                         or blnSetCompUnique) )
            and   /* Pas de gestion de version unique */
                not(    TargetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                    and (   blnVersionGoodUnique
                         or blnVersionCompUnique) )
           )
        or STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType1, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1) =
                                                                                                                       STM_I_LIB_CONSTANT.gcEleNumStatusReturned;
      /* Initialisation du flag de contrôle de stock
         Si ce flag est à True, on devra aller vérifier dans le stock que la caractérisation n'existe pas
      */
      blnVerifStock  :=
        (    Movementsort = 'ENT'
         and (   targetCharStk1 = 1
              or SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1 is not null)
         and TargetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
        );   /* Si gestion de pièce en entrée*/

      if     (TargetCharac1Id is not null)
         and not(    TargetCharacType1 in
                       (GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                      , GCO_I_LIB_CONSTANT.gcCharacTypePiece
                      , GCO_I_LIB_CONSTANT.gcCharacTypeSet
                      , GCO_I_LIB_CONSTANT.gcCharacTypeChrono
                       )
                 and SourceDetail_tuple.dcd_quantity = 0
                )   /* pas de reprise du no de série/lot/version/chrono si la qté est à 0 */
                 then
        if    (aForceCharact = 1)
           or (    SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1 is not null
               and blnPropCarac
               -- pour un retour NC d'un no de série sgs, onne le reprend pas si le status de l'élément est 03 ou 04 (déjà retourné)
               and not(    movementSort = 'ENT'
                       and TargetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
                       and targetCharStk1 = 0
                       and STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType1, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1) in
                                                                          (STM_I_LIB_CONSTANT.gcEleNumStatusReserved, STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
                      )
               and not(    blnVerifStock
                       and STM_FUNCTIONS.IsCharInStock(aTargetGoodId, targetCharacType1, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1) )
              ) then
          CharValue1  := SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1;
        elsif     targetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
              and (    (    MovementSort = 'ENT'
                        and targetCharStk1 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk1 = 0) ) then
          CharValue1  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac1Id, sysdate, 'DOC_POSITION', aTargetPositionId);
        elsif     targetCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
              and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1
              and (    (    MovementSort = 'ENT'
                        and targetCharStk1 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk1 = 0) ) then
          CharValue1  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
        elsif SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_1 is not null then
          aCopyInfoCode  := TargetCharacType1 || '0';   -- code de retour indiquant que la valeur de caractérisation n'a pas pu être reprise
        end if;
      end if;

      blnPropCarac   :=
           (mokVerifyChar = 0)
        or (     (TargetCharacType2 <> GCO_I_LIB_CONSTANT.gcCharacTypePiece)
            and   /* Pas de gestion de pièce */
                not(    TargetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                    and (   blnSetGoodUnique
                         or blnSetCompUnique) )
            and   /* Pas de gestion de lot unique */
                not(    TargetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                    and (   blnVersionGoodUnique
                         or blnVersionCompUnique) )
           )   /* Pas de gestion de version unique */
        or STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType2, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2) =
                                                                                                                       STM_I_LIB_CONSTANT.gcEleNumStatusReturned;
      blnVerifStock  :=
        (    Movementsort = 'ENT'
         and (   targetCharStk2 = 1
              or SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2 is not null)
         and TargetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
        );   /* Si gestion de pièce en entrée*/

      if     (TargetCharac2Id is not null)
         and not(    TargetCharacType2 in
                       (GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                      , GCO_I_LIB_CONSTANT.gcCharacTypePiece
                      , GCO_I_LIB_CONSTANT.gcCharacTypeSet
                      , GCO_I_LIB_CONSTANT.gcCharacTypeChrono
                       )
                 and SourceDetail_tuple.dcd_quantity = 0
                )   /* pas de reprise du no de série/lot/version/chrono si la qté est à 0 */
                 then
        if    (aForceCharact = 1)
           or (    SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2 is not null
               and blnPropCarac
               -- pour un retour NC d'un no de série sgs, onne le reprend pas si le status de l'élément est 03 ou 04 (déjà retourné)
               and not(    movementSort = 'ENT'
                       and TargetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
                       and targetCharStk2 = 0
                       and STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType2, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2) in
                                                                          (STM_I_LIB_CONSTANT.gcEleNumStatusReserved, STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
                      )
               and not(    blnVerifStock
                       and STM_FUNCTIONS.IsCharInStock(aTargetGoodId, targetCharacType2, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2) )
              ) then
          CharValue2  := SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2;
        elsif     targetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
              and (    (    MovementSort = 'ENT'
                        and targetCharStk2 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk2 = 0) ) then
          CharValue2  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac2Id, sysdate, 'DOC_POSITION', aTargetPositionId);
        elsif     targetCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
              and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1
              and (    (    MovementSort = 'ENT'
                        and targetCharStk2 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk2 = 0) ) then
          CharValue2  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
        elsif SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_2 is not null then
          aCopyInfoCode  := TargetCharacType2 || '0';   -- code de retour indiquant que la valeur de caractérisation n'a pas pu être reprise
        end if;
      end if;

      blnPropCarac   :=
           (mokVerifyChar = 0)
        or (     (TargetCharacType3 <> GCO_I_LIB_CONSTANT.gcCharacTypePiece)
            and   /* Pas de gestion de pièce */
                not(    TargetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                    and (   blnSetGoodUnique
                         or blnSetCompUnique) )
            and   /* Pas de gestion de lot unique */
                not(    TargetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                    and (   blnVersionGoodUnique
                         or blnVersionCompUnique) )
           )   /* Pas de gestion de version unique */
        or STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType3, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3) =
                                                                                                                       STM_I_LIB_CONSTANT.gcEleNumStatusReturned;
      blnVerifStock  :=
        (    Movementsort = 'ENT'
         and (   targetCharStk3 = 1
              or SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3 is not null)
         and TargetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
        );   /* Si gestion de pièce en entrée*/

      if     (TargetCharac3Id is not null)
         and not(    TargetCharacType3 in
                       (GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                      , GCO_I_LIB_CONSTANT.gcCharacTypePiece
                      , GCO_I_LIB_CONSTANT.gcCharacTypeSet
                      , GCO_I_LIB_CONSTANT.gcCharacTypeChrono
                       )
                 and SourceDetail_tuple.dcd_quantity = 0
                )   /* pas de reprise du no de série/lot/version/chrono si la qté est à 0 */
                 then
        if    (aForceCharact = 1)
           or (    SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3 is not null
               and blnPropCarac
               -- pour un retour NC d'un no de série sgs, onne le reprend pas si le status de l'élément est 03 ou 04 (déjà retourné)
               and not(    movementSort = 'ENT'
                       and TargetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
                       and targetCharStk3 = 0
                       and STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType3, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3) in
                                                                          (STM_I_LIB_CONSTANT.gcEleNumStatusReserved, STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
                      )
               and not(    blnVerifStock
                       and STM_FUNCTIONS.IsCharInStock(aTargetGoodId, targetCharacType3, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3) )
              ) then
          CharValue3  := SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3;
        elsif     targetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
              and (    (    MovementSort = 'ENT'
                        and targetCharStk3 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk3 = 0) ) then
          CharValue3  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac3Id, sysdate, 'DOC_POSITION', aTargetPositionId);
        elsif     targetCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
              and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1
              and (    (    MovementSort = 'ENT'
                        and targetCharStk3 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk3 = 0) ) then
          CharValue3  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
        elsif SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_3 is not null then
          aCopyInfoCode  := TargetCharacType3 || '0';   -- code de retour indiquant que la valeur de caractérisation n'a pas pu être reprise
        end if;
      end if;

      blnPropCarac   :=
           (mokVerifyChar = 0)
        or (     (TargetCharacType4 <> GCO_I_LIB_CONSTANT.gcCharacTypePiece)
            and   /* Pas de gestion de pièce */
                not(    TargetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                    and (   blnSetGoodUnique
                         or blnSetCompUnique) )
            and   /* Pas de gestion de lot unique */
                not(    TargetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                    and (   blnVersionGoodUnique
                         or blnVersionCompUnique) )
           )   /* Pas de gestion de version unique */
        or STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType4, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4) =
                                                                                                                       STM_I_LIB_CONSTANT.gcEleNumStatusReturned;
      blnVerifStock  :=(    Movementsort = 'ENT'
                        and targetCharStk4 = 1
                        and TargetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypePiece);   /* Si gestion de pièce en entrée*/

      if     (TargetCharac4Id is not null)
         and not(    TargetCharacType4 in
                       (GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                      , GCO_I_LIB_CONSTANT.gcCharacTypePiece
                      , GCO_I_LIB_CONSTANT.gcCharacTypeSet
                      , GCO_I_LIB_CONSTANT.gcCharacTypeChrono
                       )
                 and SourceDetail_tuple.dcd_quantity = 0
                )   /* pas de reprise du no de série/lot/version/chrono si la qté est à 0 */
                 then
        if    (aForceCharact = 1)
           or (    SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4 is not null
               and blnPropCarac
               -- pour un retour NC d'un no de série sgs, onne le reprend pas si le status de l'élément est 03 ou 04 (déjà retourné)
               and not(    movementSort = 'ENT'
                       and TargetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
                       and targetCharStk4 = 0
                       and STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType4, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4) in
                                                                          (STM_I_LIB_CONSTANT.gcEleNumStatusReserved, STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
                      )
               -- on ne le reprend pas si on doit vérifier l'existance en stock et qu'il y a du stock
               and not(    blnVerifStock
                       and STM_FUNCTIONS.IsCharInStock(aTargetGoodId, targetCharacType4, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4) )
              ) then
          CharValue4  := SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4;
        elsif     targetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
              and (    (    MovementSort = 'ENT'
                        and targetCharStk4 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk4 = 0) ) then
          CharValue4  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac4Id, sysdate, 'DOC_POSITION', aTargetPositionId);
        elsif     targetCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
              and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1
              and (    (    MovementSort = 'ENT'
                        and targetCharStk4 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk4 = 0) ) then
          CharValue4  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
        elsif SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_4 is not null then
          aCopyInfoCode  := TargetCharacType4 || '0';   -- code de retour indiquant que la valeur de caractérisation n'a pas pu être reprise
        end if;
      end if;

      blnPropCarac   :=
           (mokVerifyChar = 0)
        or (     (TargetCharacType5 <> GCO_I_LIB_CONSTANT.gcCharacTypePiece)
            and   /* Pas de gestion de pièce */
                not(    TargetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                    and (   blnSetGoodUnique
                         or blnSetCompUnique) )
            and   /* Pas de gestion de lot unique */
                not(    TargetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                    and (   blnVersionGoodUnique
                         or blnVersionCompUnique) )
           )   /* Pas de gestion de version unique */
        or STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType5, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5) =
                                                                                                                       STM_I_LIB_CONSTANT.gcEleNumStatusReturned;
      blnVerifStock  :=(    Movementsort = 'ENT'
                        and targetCharStk5 = 1
                        and TargetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypePiece);   /* Si gestion de pièce en entrée*/

      if     (TargetCharac5Id is not null)
         and not(    TargetCharacType5 in
                       (GCO_I_LIB_CONSTANT.gcCharacTypeVersion
                      , GCO_I_LIB_CONSTANT.gcCharacTypePiece
                      , GCO_I_LIB_CONSTANT.gcCharacTypeSet
                      , GCO_I_LIB_CONSTANT.gcCharacTypeChrono
                       )
                 and SourceDetail_tuple.dcd_quantity = 0
                )   /* pas de reprise du no de série/lot/version/chrono si la qté est à 0 */
                 then
        if    (aForceCharact = 1)
           or (    SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5 is not null
               and blnPropCarac
               -- pour un retour NC d'un no de série sgs, onne le reprend pas si le status de l'élément est 03 ou 04 (déjà retourné)
               and not(    movementSort = 'ENT'
                       and TargetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypePiece
                       and targetCharStk5 = 0
                       and STM_FUNCTIONS.GetElementNumberStatus(aTargetGoodId, TargetCharacType5, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5) in
                                                                          (STM_I_LIB_CONSTANT.gcEleNumStatusReserved, STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
                      )
               and not(    blnVerifStock
                       and STM_FUNCTIONS.IsCharInStock(aTargetGoodId, targetCharacType5, SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5) )
              ) then
          CharValue5  := SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5;
        elsif     targetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
              and (    (    MovementSort = 'ENT'
                        and targetCharStk5 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk5 = 0) ) then
          CharValue5  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(TargetCharac5Id, sysdate, 'DOC_POSITION', aTargetPositionId);
        elsif     targetCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
              and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aTargetGoodId) = 1
              and (    (    MovementSort = 'ENT'
                        and targetCharStk5 = 1)
                   or (    MovementSort = 'SOR'
                       and targetCharStk5 = 0) ) then
          CharValue5  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aTargetGoodId);
        elsif SourceDetail_tuple.PDE_CHARACTERIZATION_VALUE_5 is not null then
          aCopyInfoCode  := TargetCharacType5 || '0';   -- code de retour indiquant que la valeur de caractérisation n'a pas pu être reprise
        end if;
      end if;

      -- flag de retour indiquant qu'il faut saisir des valeurs de caracterisation dans l'interface
      --if aGestDelay = 1 or
      if     (SourceDetail_tuple.DCD_QUANTITY <> 0)
         and (    (    (    nvl(CharValue1, 'N/A') = 'N/A'
                        and TargetCharac1Id is not null)
                   or (    nvl(CharValue2, 'N/A') = 'N/A'
                       and TargetCharac2Id is not null)
                   or (    nvl(CharValue3, 'N/A') = 'N/A'
                       and TargetCharac3Id is not null)
                   or (    nvl(CharValue4, 'N/A') = 'N/A'
                       and TargetCharac4Id is not null)
                   or (    nvl(CharValue5, 'N/A') = 'N/A'
                       and TargetCharac5Id is not null)
                  )
              or (     (PCS.PC_CONFIG.GetConfig('DOC_SHOW_FORM_DISCHARGE_DETAIL') = '2')
                  and (coalesce(TargetCharac1Id, TargetCharac2Id, TargetCharac3Id, TargetCharac4Id, TargetCharac5Id) is not null)
                 )
             ) then
        if aInputIdList is null then
          aInputIdList  := ',' || to_char(aTargetPositionId) || ',';
        else
          aInputIdList  := aInputIdList || to_char(aTargetPositionId) || ',';
        end if;
      end if;

      ---
      -- Quantité de base du détail courant
      -- Si transfert quantité alors
      --   Si gesion de pièce alors
      --     quantité de base du détail = 1 * le signe de la quantité à copier
      --     quantité de base du détail en us = 1 * le signe de la quantité à copier
      --   Sinon
      --     quantité de base du détail = quantité à copier * facteur de conversion parent /
      --                                  facteur de conversion
      --     quantité de base du détail en us = quantité à copier * facteur de conversion parent
      -- Sinon
      --   quantité de base du détail = 0
      --   quantité de base du détail en us = 0
      --
      -- (us = unité de stockage)
      --
      if (aTransfertQuantity = 1) then
        if (TargetGestPiece = 1) then
          BasisQuantityDetail    := 1 * sign(SourceDetail_tuple.DCD_QUANTITY);
          BasisQuantityDetailSU  := 1 * sign(SourceDetail_tuple.DCD_QUANTITY);
        else
          ---
          -- Détermine s'il faut convertir la quantité. C'est le cas si le facteur
          -- de conversion parent est différent du facteur de conversion modifié.
          --
          if (SourceDetail_tuple.POS_CONVERT_FACTOR <> aConvertFactor) then
            BasisQuantityDetail  := SourceDetail_tuple.DCD_QUANTITY * SourceDetail_tuple.POS_CONVERT_FACTOR / aConvertFactor;
            BasisQuantityDetail  := ACS_FUNCTION.RoundNear(BasisQuantityDetail, 1 / power(10, aCDANumberOfDecimal), 0);
          else
            BasisQuantityDetail  := SourceDetail_tuple.DCD_QUANTITY;
          end if;

          if aConvertFactor = 1 then
            BasisQuantityDetailSU  := BasisQuantityDetail;
          else
            -- Si la quantité en unité de stockage n'est pas définie, on la calcul, sinon on la reprend,. }
            if nvl(SourceDetail_tuple.DCD_QUANTITY_SU, 0) = 0 then
              BasisQuantityDetailSU  := SourceDetail_tuple.DCD_QUANTITY * aConvertFactor;
              BasisQuantityDetailSU  := ACS_FUNCTION.RoundNear(BasisQuantityDetailSU, 1 / power(10, aGoodNumberOfDecimal), 1);
            else
              BasisQuantityDetailSU  := ACS_FUNCTION.RoundNear(SourceDetail_tuple.DCD_QUANTITY_SU, 1 / power(10, aGoodNumberOfDecimal), 1);
            end if;
          end if;
        end if;
      else
        BasisQuantityDetail    := 0;
        BasisQuantityDetailSU  := 0;
      end if;

      -- Qté à 0 pour les copies en mode 205 ou 206
      -- Date du mouvement transférée uniquement pour les créations en mode 205 ou 206
      if SourceDetail_tuple.C_PDE_CREATE_MODE in('205', '206') then
        BasisQuantityDetail    := 0;
        BasisQuantityDetailSU  := 0;
        movementDate           := SourceDetail_tuple.pde_movement_date;
      else
        movementDate  := null;
      end if;

      ---
      -- Valeur du mouvement
      --
      MovementValue  := 0;

      if     (aInitPriceMvt = 1)
         and not(aTypePos in('9', '10') ) then
        if (aTargetAdminDomain = '2') then   -- Domaine vente
          MovementValue  := aTargetUnitCostprice * BasisQuantityDetailSU;
        else
          MovementValue  := BasisQuantityDetailSU * aTargetNetUnitValue;

          if aTargetCurrencyId <> acs_function.GetLocalCurrencyId then
            -- Conversion prix du mouvement en monnaie de base
            MovementValue  := ACS_FUNCTION.ConvertAmountForView(MovementValue, aTargetCurrencyId, acs_function.GetLocalCurrencyId, aDateRef, 0, 0, 0, 1);
          end if;
        end if;
      end if;

      -- Emplacements du détail
      if nvl(SourceDetail_tuple.DCD_USE_STOCK_LOCATION_ID, 0) = 1 then
        TargetLocationID       := nvl(SourceDetail_tuple.DCD_STM_LOCATION_ID, aPosLocationId);
        TargetTransLocationID  := nvl(SourceDetail_tuple.DCD_STM_STM_LOCATION_ID, aPosTargetTransLocationId);
      else
        if     aTransfertStock = 1
           and aMvtUtility = 0 then
          TargetLocationid       := nvl(SourceDetail_tuple.DCD_STM_LOCATION_ID, aPosLocationId);
          TargetTransLocationID  := aPosTargetTransLocationId;
        else
          TargetLocationid       := aPosLocationId;
          TargetTransLocationID  := aPosTargetTransLocationId;
        end if;
      end if;

      select C_SQM_EVAL_TYPE
        into vSqmEval
        from DOC_GAUGE_POSITION GAP
           , DOC_POSITION POS
       where GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and DOC_POSITION_ID = aTargetPositionId;

      select init_id_seq.nextval
        into aPosDetID
        from dual;

      insert into DOC_POSITION_DETAIL
                  (DOC_POSITION_DETAIL_ID
                 , DOC_GAUGE_FLOW_ID
                 , DOC_POSITION_ID
                 , DOC_DOC_POSITION_DETAIL_ID
                 , DOC2_DOC_POSITION_DETAIL_ID
                 , PDE_BASIS_DELAY
                 , PDE_INTERMEDIATE_DELAY
                 , PDE_FINAL_DELAY
                 , PDE_SQM_ACCEPTED_DELAY
                 , PDE_BASIS_QUANTITY
                 , PDE_INTERMEDIATE_QUANTITY
                 , PDE_FINAL_QUANTITY
                 , PDE_BASIS_QUANTITY_SU
                 , PDE_INTERMEDIATE_QUANTITY_SU
                 , PDE_FINAL_QUANTITY_SU
                 , PDE_BALANCE_QUANTITY
                 , PDE_BALANCE_QUANTITY_PARENT
                 , PDE_MOVEMENT_QUANTITY
                 , PDE_MOVEMENT_VALUE
                 , PDE_MOVEMENT_DATE
                 , PDE_CHARACTERIZATION_VALUE_1
                 , PDE_CHARACTERIZATION_VALUE_2
                 , PDE_CHARACTERIZATION_VALUE_3
                 , PDE_CHARACTERIZATION_VALUE_4
                 , PDE_CHARACTERIZATION_VALUE_5
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , STM_LOCATION_ID
                 , STM_STM_LOCATION_ID
                 , DIC_PDE_FREE_TABLE_1_ID
                 , DIC_PDE_FREE_TABLE_2_ID
                 , DIC_PDE_FREE_TABLE_3_ID
                 , PDE_DECIMAL_1
                 , PDE_DECIMAL_2
                 , PDE_DECIMAL_3
                 , PDE_TEXT_1
                 , PDE_TEXT_2
                 , PDE_TEXT_3
                 , PDE_DATE_1
                 , PDE_DATE_2
                 , PDE_DATE_3
                 , FAL_SCHEDULE_STEP_ID
                 , DOC_RECORD_ID
                 , DOC_DOCUMENT_ID
                 , DOC_GAUGE_RECEIPT_ID
                 , DOC_GAUGE_COPY_ID
                 , DIC_DELAY_UPDATE_TYPE_ID
                 , PDE_GENERATE_MOVEMENT
                 , C_PDE_CREATE_MODE
                 , PDE_ADDENDUM_QTY_BALANCED
                 , PDE_ADDENDUM_SRC_PDE_ID
                 , DOC_PDE_LITIG_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aPosDetID   -- DOC_POSITION_DETAIL_ID,
                 , aFlowId   -- DOC_GAUGE_FLOW_ID,
                 , aTargetPositionId   -- DOC_POSITION_ID
                 , null   -- DOC_DOC_POSITION_DETAIL_ID,
                 , decode(lGacBond, 1, SourceDetail_tuple.DOC_POSITION_DETAIL_ID, null)   -- DOC2_DOC_POSITION_DETAIL_ID
                 , decode(aGestDelay, 1, nvl(SourceDetail_tuple.PDE_BASIS_DELAY, trunc(sysdate) ) )   -- PDE_BASIS_DELAY,
                 , decode(aGestDelay, 1, nvl(SourceDetail_tuple.PDE_INTERMEDIATE_DELAY, trunc(sysdate) ) )   -- PDE_INTERMEDIATE_DELAY,
                 , decode(aGestDelay, 1, nvl(SourceDetail_tuple.PDE_FINAL_DELAY, trunc(sysdate) ) )   -- PDE_FINAL_DELAY,
                 , decode(vSqmEval
                        , 1, nvl(SourceDetail_tuple.PDE_SQM_ACCEPTED_DELAY, nvl(SourceDetail_tuple.PDE_INTERMEDIATE_DELAY, trunc(sysdate) ) )
                         )   -- PDE_SQM_ACCEPTED_DELAY,
                 , BasisQuantityDetail   -- PDE_BASIS_QUANTITY,
                 , BasisQuantityDetail   -- PDE_INTERMEDIATE_QUANTITY,
                 , BasisQuantityDetail   -- PDE_FINAL_QUANTITY
                 , BasisQuantityDetailSU   -- PDE_BASIS_QUANTITY_SU,
                 , BasisQuantityDetailSU   -- PDE_INTERMEDIATE_QUANTITY_SU,
                 , BasisQuantityDetailSU   -- PDE_FINAL_QUANTITY_SU,
                 , decode(aBalanceStatus, 1, BasisQuantityDetail, 0)   -- PDE_BALANCE_QUANTITY,
                 , 0   -- PDE_BALANCE_QUANTITY_PARENT,
                 , decode(aInitQteMvt, 1, BasisQuantityDetailSU, 0)   -- PDE_MOVEMENT_QUANTITY,
                 , MovementValue   -- PDE_MOVEMENT_VALUE,
                 , MovementDate   -- PDE_MOVEMENT_DATE
                 , CharValue1   -- PDE_CHARACTERIZATION_VALUE_1,
                 , CharValue2   -- PDE_CHARACTERIZATION_VALUE_2,
                 , CharValue3   -- PDE_CHARACTERIZATION_VALUE_3,
                 , CharValue4   -- PDE_CHARACTERIZATION_VALUE_4,
                 , CharValue5   -- PDE_CHARACTERIZATION_VALUE_5,
                 , TargetCharac1Id   -- GCO_CHARACTERIZATION_ID,
                 , TargetCharac2Id   -- GCO_GCO_CHARACTERIZATION_ID,
                 , TargetCharac3Id   -- GCO2_GCO_CHARACTERIZATION_ID,
                 , TargetCharac4Id   -- GCO3_GCO_CHARACTERIZATION_ID,
                 , TargetCharac5Id   -- GCO4_GCO_CHARACTERIZATION_ID,
                 , TargetLocationId   -- STM_LOCATION_ID,
                 , TargetTransLocationID   -- STM_STM_LOCATION_ID,
                 , SourceDetail_tuple.DIC_PDE_FREE_TABLE_1_ID   -- DIC_PDE_FREE_TABLE_1_ID,
                 , SourceDetail_tuple.DIC_PDE_FREE_TABLE_2_ID   -- DIC_PDE_FREE_TABLE_2_ID,
                 , SourceDetail_tuple.DIC_PDE_FREE_TABLE_3_ID   -- DIC_PDE_FREE_TABLE_3_ID,
                 , SourceDetail_tuple.PDE_DECIMAL_1   -- PDE_DECIMAL_1,
                 , SourceDetail_tuple.PDE_DECIMAL_2   -- PDE_DECIMAL_2,
                 , SourceDetail_tuple.PDE_DECIMAL_3   -- PDE_DECIMAL_3,
                 , SourceDetail_tuple.PDE_TEXT_1   -- PDE_TEXT_1,
                 , SourceDetail_tuple.PDE_TEXT_2   -- PDE_TEXT_2,
                 , SourceDetail_tuple.PDE_TEXT_3   -- PDE_TEXT_3,
                 , SourceDetail_tuple.PDE_DATE_1   -- PDE_DATE_1,
                 , SourceDetail_tuple.PDE_DATE_2   -- PDE_DATE_2,
                 , SourceDetail_tuple.PDE_DATE_3   -- PDE_DATE_3,
                 , null   -- FAL_SCHEDULE_STEP_ID (ne doit pas être repris en copie)
                 , decode(vTargetGestInstall, 1, decode(vSourceGestInstall, 1, SourceDetail_tuple.DOC_RECORD_ID, null) )   -- DOC_RECORD_ID
                 , aTargetDocumentId   -- DOC_DOCUMENT_ID,
                 , null   -- DOC_GAUGE_RECEIPT_ID,
                 , aGaugeCopyId   -- DOC_GAUGE_COPY_ID,
                 , decode(aGestDelay, 1, aDelayUpdateType, null)   -- DIC_DELAY_UPDATE_TYPE_ID,
                 , 0   -- PDE_GENERATE_MOVEMENT
                 , SourceDetail_tuple.C_PDE_CREATE_MODE
                 , decode(SourceDetail_tuple.C_PDE_CREATE_MODE, '215', SourceDetail_tuple.PDE_BALANCE_QUANTITY, null)   -- PDE_ADDENDUM_QTY_BALANCED
                 , decode(SourceDetail_tuple.C_PDE_CREATE_MODE, '215', SourceDetail_tuple.PDE_ADDENDUM_SRC_PDE_ID, null)   -- PDE_ADDENDUM_SRC_PDE_ID
                 , SourceDetail_tuple.DOC_PDE_LITIG_ID
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );

      ---
      -- Recherche de la quantité valeur utilisé pour le détail courant
      --
      if ( (abs(aBalanceValueParent) - abs(SourceDetail_tuple.DCD_QUANTITY) ) > 0) then
        ValueQuantityUsed  := SourceDetail_tuple.DCD_QUANTITY;
      else
        ValueQuantityUsed  := aBalanceValueParent;
      end if;

      -- Si le produit fabriqué est renseigné (Sous-traitance d'achat) sur le détail source, il faut lancer
      -- le traitement de la création du lot de fabrication pour autant que le document courant
      -- soit une CAST (commande d'achat sous-traitance).
      if     (SourceDetail_tuple.GCO_MANUFACTURED_GOOD_ID is not null)
         and (aComplDataId is not null)
         and (SourceDetail_tuple.FAL_LOT_ID is not null)
         and (DOC_LIB_SUBCONTRACTP.IsSUPOGauge(aSourceGaugeId) = 1)
         and (DOC_LIB_SUBCONTRACTP.IsSUPOGauge(aTargetGaugeId) = 1) then
        lnLotId  := null;
        lvError  := null;
        FAL_PRC_SUBCONTRACTP.GenerateBatch(iPositionDetailId => aPosDetID, oLotId => lnLotId, oError => lvError);

        -- Erreur durant la création du lot
        if lvError is not null then
          raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur à la création du lot de sous-traitance !') || co.cLineBreak || lvError);
        else
          -- Recalcul du prix de la position en fonction de la création du lot
          DOC_POSITION_FUNCTIONS.ReinitPositionPrice(aPositionId => aTargetPositionId);
        end if;
      end if;

      fetch SourceDetail
       into SourceDetail_tuple;

      /**
      * DSA - Evaluation partenaires
      * Création des notes selon les axes qualités actifs applicables en copie
      */
      if PCS.PC_CONFIG.GETCONFIG('SQM_QUALITY_MGM') = '1' then
        select *
          into SQM_INIT_METHOD.DetailInfo
          from doc_position_detail
         where doc_position_detail_id = aPosDetID;

        -- Recherche date du document selon config et autres données de la position
        select decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ), 'DOC', DMT.DMT_DATE_DOCUMENT, 'VAL', DMT.DMT_DATE_VALUE, DMT.DMT_DATE_DOCUMENT)
             , DMT.PAC_THIRD_ID
             , POS.GCO_GOOD_ID
             , POS.C_DOC_POS_STATUS
          into vDateDocument
             , vThird
             , vGood
             , vPosStatus
          from DOC_POSITION POS
             , DOC_DOCUMENT DMT
         where POS.DOC_POSITION_ID = aTargetPositionId
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

        -- Curseur sur les axes qualité applicables en copie
        for cr_axis in (select SQM_FUNCTIONS.GetFirstFitScale(SAX.SQM_AXIS_ID, vDateDocument, vGood) SCALE_ID
                             , SAX.SQM_AXIS_ID SQM_AXIS_ID
                          from DOC_POSITION POS
                             , SQM_AXIS SAX
                             , DOC_GAUGE_RECEIPT_S_AXIS GRA
                             , DOC_GAUGE_POSITION GAP
                         where POS.DOC_POSITION_ID = aTargetPositionId
                           and SQM_FUNCTIONS.IsVerified(SAX.PC_SQLST_ID, vGood) = 1   -- Condition d'application de l'axe vérifiée
                           and GRA.SQM_AXIS_ID = SAX.SQM_AXIS_ID   -- Axe défini au niveau du flux
                           and GRA.DOC_GAUGE_COPY_ID = aGaugeCopyId
                           and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                           and GAP.C_SQM_EVAL_TYPE = '1'   -- Gabarit position gère la qualité
                           and SAX.C_AXIS_STATUS = 'ACT'   -- Axe actif
                                                        ) loop
          if cr_axis.SCALE_ID is not null then
            vExpValue   := null;
            vEffValue   := null;
            vAxisValue  := null;
            SQM_INIT_METHOD.CalcAxisValue(cr_axis.SQM_AXIS_ID, vExpValue, vEffValue, vAxisValue);

            insert into SQM_PENALTY
                        (SQM_PENALTY_ID
                       , SQM_SCALE_ID
                       , DOC_POSITION_DETAIL_ID
                       , DOC_POSITION_ID
                       , PAC_THIRD_ID
                       , GCO_GOOD_ID
                       , SQM_AXIS_ID
                       , C_PENALTY_STATUS
                       , SPE_DATE_REFERENCE
                       , SPE_CALC_PENALTY
                       , SPE_INIT_VALUE
                       , SPE_EXPECTED_VALUE
                       , SPE_EFFECTIVE_VALUE
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , cr_axis.SCALE_ID
                       , aPosDetID
                       , aTargetPositionId
                       , vThird
                       , vGood
                       , cr_axis.SQM_AXIS_ID
                       , decode(vPosStatus, '01', 'PROV', 'CONF')
                       , vDateDocument
                       , SQM_FUNCTIONS.CalcPenalty(cr_axis.SCALE_ID, vAxisValue)
                       , vAxisValue
                       , vExpValue
                       , vEffValue
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          end if;
        end loop;
      end if;
    end loop;

    close SourceDetail;
  end CopyPositionDetail;

  /**
  * Description
  *    Mise à jour des liens parent enfant sur les nouveaux détails créés
  */
  procedure UpdateParentLinks(aNewDocumentId in number, aChildPositionId in number, aParentPositionId in number, aResult out number)
  is
    cursor child(apositionId number)
    is
      select   doc_position_detail_id
             , pde_final_quantity
             , pde_basis_quantity
          from doc_position_detail
         where doc_position_id = apositionId
           and doc_doc_position_detail_id is null
      order by pde_final_quantity desc;

    child_tuple  child%rowtype;

    cursor parent(aPositionId number, aDocumentId number, aChildPositionId number)
    is
      select   dcd.doc_position_detail_id
             , dcd.doc2_doc_position_detail_id
             , nvl(avg(dcd.dcd_quantity), 0) - nvl(sum(pde.pde_final_quantity), 0) qty_dispo
             , avg(dcd.dcd_quantity) dc
             , sum(pde.pde_final_quantity) tp
             , count(*) nb
          from doc_pos_det_copy_discharge dcd
             , doc_position_detail pde
         where dcd.doc_position_id = aPositionId
           and dcd.new_document_id = aDocumentId
           and pde.doc_doc_position_detail_id = dcd.doc_position_detail_id
           and pde.doc_position_id = aChildPositionId
      group by dcd.doc_position_detail_id
             , dcd.doc2_doc_position_detail_id
        having nvl(avg(dcd.dcd_quantity), 0) - nvl(sum(pde.pde_final_quantity), 0) <> 0
      order by 2 desc;

    parent_tuple parent%rowtype;
    result       boolean;
  begin
    result  := true;

    -- curseur sur les enfants non-liés
    open child(aChildPositionId);

    fetch child
     into child_tuple;

    -- parcoure tous les détails enfants dans l'ordre décroissant de la quantité
    while child%found loop
      open parent(aParentPositionId, aNewDocumentId, aChildPositionId);

      fetch parent
       into parent_tuple;

      update doc_position_detail
         set doc_doc_position_detail_id = parent_tuple.doc_position_detail_id
           , doc2_doc_position_detail_id = nvl(parent_tuple.doc2_doc_position_detail_id, parent_tuple.doc_position_detail_id)
       where doc_position_detail_id = child_tuple.doc_position_detail_id;

      result  :=     result
                 and (parent_tuple.qty_dispo >= child_tuple.pde_final_quantity);

      close parent;

      fetch child
       into child_tuple;
    end loop;

    close child;

    -- valeur de retour
    if result then
      aResult  := 1;
    else
      aResult  := 0;
    end if;
  end UpdateParentLinks;

  /**
  * Description
  *    Mise à jour des liens parent enfant sur les nouveaux détails créés. Valable pour l'ensemble des positions
  *    composants.
  */
  procedure UpdateParentLinksCPT(aNewDocumentID in number, aChildPTPositionID in number, aResult out number)
  is
    cursor PTchild(aPositionPTID number)
    is
      select   POS.DOC_POSITION_ID
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
         where POS.DOC_DOC_POSITION_ID = aPositionPTID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and PDE.DOC_DOC_POSITION_DETAIL_ID is null
      group by POS.DOC_POSITION_ID;

    PTchild_tuple       PTchild%rowtype;

    cursor child(aPositionID number)
    is
      select   DOC_POSITION_DETAIL_ID
             , PDE_FINAL_QUANTITY
             , PDE_BASIS_QUANTITY
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = aPositionID
           and DOC_DOC_POSITION_DETAIL_ID is null
      order by PDE_FINAL_QUANTITY desc;

    child_tuple         child%rowtype;

    cursor parent(aPositionID number, aDocumentID number, aChildPositionID number)
    is
      select   DCD.DOC_POSITION_DETAIL_ID
             , DCD.DOC2_DOC_POSITION_DETAIL_ID
             , nvl(avg(DCD.DCD_QUANTITY), 0) - nvl(sum(PDE.PDE_FINAL_QUANTITY), 0) QTY_DISPO
             , avg(DCD.DCD_QUANTITY) DC
             , sum(PDE.PDE_FINAL_QUANTITY) TP
             , count(*) NB
          from DOC_POS_DET_COPY_DISCHARGE DCD
             , DOC_POSITION_DETAIL PDE
         where DCD.DOC_POSITION_ID = aPositionID
           and DCD.NEW_DOCUMENT_ID = aDocumentID
           and PDE.DOC_DOC_POSITION_DETAIL_ID = DCD.DOC_POSITION_DETAIL_ID
           and PDE.DOC_POSITION_ID = aChildPositionID
      group by DCD.DOC_POSITION_DETAIL_ID
             , DCD.DOC2_DOC_POSITION_DETAIL_ID
        having nvl(avg(DCD.DCD_QUANTITY), 0) - nvl(sum(PDE.PDE_FINAL_QUANTITY), 0) <> 0
      order by 2 desc;

    parent_tuple        parent%rowtype;
    result              boolean;
    posParentPositionID DOC_POSITION.DOC_POSITION_ID%type;
  begin
    result  := true;

    -- curseur sur les positions composants enfants non-liés
    open PTchild(aChildPTPositionId);

    fetch PTchild
     into PTchild_tuple;

    -- parcoure tous les détails enfants dans l'ordre décroissant de la quantité
    while PTchild%found loop
      -- recherche le position composant parent
      select max(PDE_FATHER.DOC_POSITION_ID)
        into posParentPositionID
        from DOC_POSITION_DETAIL PDE_SON
           , DOC_POSITION_DETAIL PDE_FATHER
       where PDE_SON.DOC_POSITION_ID = PTchild_tuple.DOC_POSITION_ID
         and PDE_FATHER.DOC_POSITION_DETAIL_ID = PDE_SON.DOC_DOC_POSITION_DETAIL_ID;

      -- curseur sur les enfants non-liés
      open child(PTchild_tuple.DOC_POSITION_ID);

      fetch child
       into child_tuple;

      -- parcoure tous les détails enfants dans l'ordre décroissant de la quantité
      while child%found loop
        open parent(posParentPositionID, aNewDocumentID, PTchild_tuple.DOC_POSITION_ID);

        fetch parent
         into parent_tuple;

        update DOC_POSITION_DETAIL
           set DOC_DOC_POSITION_DETAIL_ID = parent_tuple.DOC_POSITION_DETAIL_ID
             , DOC2_DOC_POSITION_DETAIL_ID = nvl(parent_tuple.DOC2_DOC_POSITION_DETAIL_ID, parent_tuple.DOC_POSITION_DETAIL_ID)
         where DOC_POSITION_DETAIL_ID = child_tuple.DOC_POSITION_DETAIL_ID;

        result  :=     result
                   and (parent_tuple.QTY_DISPO >= child_tuple.PDE_FINAL_QUANTITY);

        close parent;

        fetch child
         into child_tuple;
      end loop;

      close child;

      fetch PTchild
       into PTchild_tuple;
    end loop;

    close PTchild;

    -- valeur de retour
    if result then
      aResult  := 1;
    else
      aResult  := 0;
    end if;
  end UpdateParentLinksCPT;

  /**
  * function GetBalanceParentFlag
  * Description
  *   retourne la valeur du flag "Solder parent" en fonction des codes relicats et du flux
  *   Attention : cette fonction tient compte du flag du flux autorisant ou pas le solde du parent
  * @created NGV 04.10.2013
  * @lastUpdate
  * @public
  * @param iSrcPositionID : id position à décharger
  * @param iTgtGaugeID    : id du gabarit du document cible
  * @param iTgtThirdID    : id du tiers du document cible
  * @return
  */
  function GetBalanceParentFlag(
    iSrcPositionID in DOC_POSITION.DOC_POSITION_ID%type
  , iTgtGaugeID    in DOC_GAUGE.DOC_GAUGE_ID%type
  , iTgtThirdID    in DOC_DOCUMENT.PAC_THIRD_ID%type
  )
    return number
  is
    lnResult           number(1);
    lnSrcGaugeID       DOC_GAUGE.DOC_GAUGE_ID%type;
    lnFlowID           DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    lnReceiptID        DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type;
    lnGarBalanceParent DOC_GAUGE_RECEIPT.GAR_BALANCE_PARENT%type;
  begin
    lnResult            := 0;

    -- Rechercher le flux de décharge sur le détail parent ainsi que l'id du gabarit du document source
    select max(PDE.DOC_GAUGE_FLOW_ID)
         , max(DMT.DOC_GAUGE_ID)
      into lnFlowID
         , lnSrcGaugeID
      from DOC_POSITION_DETAIL PDE
         , DOC_DOCUMENT DMT
     where PDE.DOC_POSITION_ID = iSrcPositionID
       and PDE.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

    -- Rechercher le flux de décharge
    lnReceiptID         :=
                  DOC_I_LIB_GAUGE.GetGaugeReceiptID(iSourceGaugeId   => lnSrcGaugeID, iTargetGaugeId => iTgtGaugeID, iThirdID => iTgtThirdID
                                                  , iFlowID          => lnFlowID);
    -- Rechercher la valeur du flag du flux de décharge indiquant si on peut solder le parent
    lnGarBalanceParent  := DOC_I_LIB_GAUGE.GetGaugeReceiptFlag(iReceiptID => lnReceiptID, iFieldName => 'GAR_BALANCE_PARENT');

    if lnGarBalanceParent = 1 then
      select decode(GAU.C_ADMIN_DOMAIN
                  , '2', decode(decode(POS.C_POS_DELIVERY_TYP
                                     , null, decode(DMT.C_DMT_DELIVERY_TYP
                                                  , null, decode(nvl(PDT.C_PRODUCT_DELIVERY_TYP, '0'), '0', CUS.C_DELIVERY_TYP, PDT.C_PRODUCT_DELIVERY_TYP)
                                                  , DMT.C_DMT_DELIVERY_TYP
                                                   )
                                     , POS.C_POS_DELIVERY_TYP
                                      )
                              , '1', 0
                              , '3', 0
                              , '5', 0
                              , '2', 1
                              , '4', 1
                              , '6', 1
                              , 0
                               )
                  , 0
                   )
        into lnResult
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , GCO_PRODUCT PDT
           , PAC_CUSTOM_PARTNER CUS
       where POS.DOC_POSITION_ID = iSrcPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and CUS.PAC_CUSTOM_PARTNER_ID = DMT.PAC_THIRD_ID
         and PDT.GCO_GOOD_ID = POS.GCO_GOOD_ID;
    end if;

    return lnResult;
  exception
    when no_data_found then
      return 0;
  end GetBalanceParentFlag;

  /**
  * Description
  *        Création des positions du nouveau document en fonction des données dans DOC_POS_DET_COPY_DISCHARGE
  */
  procedure DischargeNewDocument(aNewDocumentId in number, aFlowId in number)
  is
    -- curseur sur les positions à décharger sur le nouveau document
    cursor positions(aNewDocumentId number)
    is
      select   DOC_POSITION_ID
          from DOC_POS_DET_COPY_DISCHARGE
         where NEW_DOCUMENT_ID = aNewDocumentId
           and CRG_SELECT = 1
           and DOC_DOC_POSITION_ID is null
      group by DOC_POSITION_ID
      order by min(DOC_POS_DET_COPY_DISCHARGE_ID);

    currentPositionId DOC_POSITION.DOC_POSITION_ID%type;
    InputData         varchar2(32000);
    TargetPositionId  DOC_POSITION.DOC_POSITION_ID%type;
    DischargeInfoCode varchar2(10);
  begin
    -- Assignation du dernier numéro de position d'après le document en cours
    DOC_COPY_DISCHARGE.SetLastDocPosNumber(aNewDocumentId);

    open Positions(aNewDocumentId);

    fetch Positions
     into currentPositionId;

    -- pour chaque position à décharger sur le nouveau document
    while Positions%found loop
      --appel de la décharge de position
      DischargePosition(currentPositionId, aNewDocumentId, null, null, aFlowId, InputData, TargetPositionId, DischargeInfoCode);

      fetch Positions
       into currentPositionId;
    --commit;
    end loop;

    close Positions;

    -- Création des positions litige, si document final cible des litiges
    DOC_LITIG_FUNCTIONS.GenerateLitigPos(aNewDocumentID);
  end DischargeNewDocument;

  /**
  * Description
  *   procedure globale de décharge d'une position
  */
  procedure DischargePosition(
    aSourcePositionId    in     number
  , aTargetDocumentId    in     number
  , aPdtSourcePositionId in     number
  , aPdtTargetPositionId in     number
  , aFlowId              in     number
  , aInputIdList         in out varchar2
  , aTargetPositionId    out    number
  , aDischargeInfoCode   out    varchar2
  )
  is
    -- curseur sur la position à décharger
    cursor SourcePosition(position_id number, NewDocumentId number)
    is
      select   POS.DOC_DOCUMENT_ID
             , DMT.DMT_NUMBER
             , DMT.PAC_THIRD_ID
             , DCD.DOC_DOC_POSITION_ID
             , sum(decode(POS.C_GAUGE_TYPE_POS, '5', 1, DCD.DCD_QUANTITY) ) DCD_QUANTITY
             , sum(decode(POS.C_GAUGE_TYPE_POS, '5', 1, DCD.DCD_QUANTITY_SU) ) DCD_QUANTITY_SU
             , DCD.DOC_GAUGE_FLOW_ID
             , DCD.DOC_INVOICE_EXPIRY_ID
             , POS.DOC_RECORD_ID
             , POS.DOC_DOC_RECORD_ID
             , POS.PAC_PERSON_ID
             , DMT.PAC_THIRD_VAT_ID
             , POS.ASA_RECORD_ID
             , POS.DOC_GAUGE_ID
             , POS.DOC_GAUGE_POSITION_ID
             , POS.C_GAUGE_TYPE_POS
             , POS.ACS_FINANCIAL_ACCOUNT_ID
             , POS.ACS_DIVISION_ACCOUNT_ID
             , POS.ACS_CPN_ACCOUNT_ID
             , POS.ACS_CDA_ACCOUNT_ID
             , POS.ACS_PF_ACCOUNT_ID
             , POS.ACS_PJ_ACCOUNT_ID
             , POS.DIC_UNIT_OF_MEASURE_ID
             , GOO.DIC_UNIT_OF_MEASURE_ID GOO_UNIT_OF_MEASURE_ID
             , GOO.GOO_NUMBER_OF_DECIMAL
             , DCD.POS_CONVERT_FACTOR_CALC
             , POS.POS_CONVERT_FACTOR
             , DCD.GCO_GOOD_ID
             , POS.GCO_GOOD_ID POS_GOOD_ID
             , DCD.POS_CONVERT_FACTOR GOO_CONVERT_FACTOR
             , decode(POS.C_GAUGE_TYPE_POS, '5', 1, POS.POS_BALANCE_QUANTITY) POS_BALANCE_QUANTITY
             , POS.POS_NET_TARIFF
             , POS.POS_SPECIAL_TARIFF
             , POS.POS_FLAT_RATE
             , POS.DIC_TARIFF_ID
             , POS.POS_EFFECTIVE_DIC_TARIFF_ID
             , POS.POS_TARIFF_UNIT
             , POS.POS_TARIFF_SET
             , POS.POS_TARIFF_INITIALIZED
             , nvl(POS.POS_TARIFF_DATE, nvl(DMT.DMT_TARIFF_DATE, DMT.DMT_DATE_DOCUMENT) ) POS_TARIFF_DATE
             , POS.POS_UPDATE_TARIFF
             , POS.POS_DISCOUNT_RATE
             , POS.POS_REF_UNIT_VALUE
             , POS.POS_UNIT_COST_PRICE
             , DCD.POS_GROSS_UNIT_VALUE_INCL
             , POS.POS_BALANCE_QTY_VALUE
             , DCD.POS_GROSS_UNIT_VALUE
             , POS.POS_GROSS_UNIT_VALUE2
             , POS.POS_NET_UNIT_VALUE
             , decode(POS.C_GAUGE_TYPE_POS, '5', 1, POS.POS_FINAL_QUANTITY) POS_FINAL_QUANTITY
             , POS.POS_BASIS_QUANTITY
             , POS.POS_CALC_BUDGET_AMOUNT_MB
             , POS.POS_EFFECT_BUDGET_AMOUNT_MB
             , POS.STM_STOCK_ID
             , POS.STM_STM_STOCK_ID
             , POS.STM_LOCATION_ID
             , POS.STM_STM_LOCATION_ID
             , POS.POS_GROSS_VALUE_B
             , POS.POS_UTIL_COEFF
             , POS.POS_GROSS_WEIGHT
             , POS.POS_NET_WEIGHT
             , POS.PAC_REPRESENTATIVE_ID
             , POS.PAC_REPR_ACI_ID
             , POS.PAC_REPR_DELIVERY_ID
             , POS.POS_REFERENCE
             , POS.POS_SECONDARY_REFERENCE
             , nvl(DCD.POS_SHORT_DESCRIPTION, POS.POS_SHORT_DESCRIPTION) POS_SHORT_DESCRIPTION
             , nvl(DCD.POS_LONG_DESCRIPTION, POS.POS_LONG_DESCRIPTION) POS_LONG_DESCRIPTION
             , POS.POS_FREE_DESCRIPTION
             , POS.POS_BODY_TEXT
             , POS.POS_EAN_CODE
             , POS.POS_EAN_UCC14_CODE
             , POS.POS_HIBC_PRIMARY_CODE
             , POS.POS_CONVERT_FACTOR2
             , POS.DIC_POS_FREE_TABLE_1_ID
             , POS.DIC_POS_FREE_TABLE_2_ID
             , POS.DIC_POS_FREE_TABLE_3_ID
             , POS.POS_DECIMAL_1
             , POS.POS_DECIMAL_2
             , POS.POS_DECIMAL_3
             , POS.POS_TEXT_1
             , POS.POS_TEXT_2
             , POS.POS_TEXT_3
             , POS.POS_DATE_1
             , POS.POS_DATE_2
             , POS.POS_DATE_3
             , POS.POS_PARTNER_NUMBER
             , POS.POS_PARTNER_REFERENCE
             , POS.POS_DATE_PARTNER_DOCUMENT
             , POS.POS_PARTNER_POS_NUMBER
             , POS.PC_APPLTXT_ID
             , POS.STM_MOVEMENT_KIND_ID
             , POS.ASA_RECORD_COMP_ID
             , POS.ASA_RECORD_TASK_ID
             , POS.HRM_PERSON_ID
             , POS.FAM_FIXED_ASSETS_ID
             , POS.C_FAM_TRANSACTION_TYP
             , POS.POS_IMF_TEXT_1
             , POS.POS_IMF_TEXT_2
             , POS.POS_IMF_TEXT_3
             , POS.POS_IMF_TEXT_4
             , POS.POS_IMF_TEXT_5
             , POS.POS_IMF_NUMBER_2
             , POS.POS_IMF_NUMBER_3
             , POS.POS_IMF_NUMBER_4
             , POS.POS_IMF_NUMBER_5
             , POS.DIC_IMP_FREE1_ID
             , POS.DIC_IMP_FREE2_ID
             , POS.DIC_IMP_FREE3_ID
             , POS.DIC_IMP_FREE4_ID
             , POS.DIC_IMP_FREE5_ID
             , POS.POS_IMF_DATE_1
             , POS.POS_IMF_DATE_2
             , POS.POS_IMF_DATE_3
             , POS.POS_IMF_DATE_4
             , POS.POS_IMF_DATE_5
             , POS.POS_DATE_DELIVERY
             , GAP.GAP_TRANSFERT_PROPRIETOR
             , GAP.C_DOC_LOT_TYPE
             , nvl(DCD.C_PDE_CREATE_MODE, '301') C_PDE_CREATE_MODE
             , POS.POS_IMPUTATION
             , POS.FAL_LOT_ID
             , DCD.DCD_FORCE_AMOUNT
             , DCD.POS_GROSS_VALUE
             , DCD.POS_NET_VALUE_EXCL
             , DCD.DOC_GAUGE_RECEIPT_ID
             , DCD.DOC_GAUGE_COPY_ID
             , POS.GCO_MANUFACTURED_GOOD_ID
          from DOC_POS_DET_COPY_DISCHARGE DCD
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , DOC_GAUGE_POSITION GAP
             , GCO_GOOD GOO
         where DCD.DOC_POSITION_ID = position_id
           and POS.DOC_POSITION_ID = DCD.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and GOO.GCO_GOOD_ID(+) = DCD.GCO_GOOD_ID
           and DCD.CRG_SELECT = 1
           and DCD.NEW_DOCUMENT_ID = newDocumentId
           and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
      group by POS.DOC_DOCUMENT_ID
             , DMT.DMT_NUMBER
             , DMT.PAC_THIRD_ID
             , DCD.DOC_DOC_POSITION_ID
             , DCD.DOC_INVOICE_EXPIRY_ID
             , POS.DOC_RECORD_ID
             , DCD.DOC_GAUGE_FLOW_ID
             , POS.DOC_DOC_RECORD_ID
             , POS.PAC_PERSON_ID
             , DMT.PAC_THIRD_VAT_ID
             , POS.ASA_RECORD_ID
             , POS.DOC_GAUGE_ID
             , POS.DOC_GAUGE_POSITION_ID
             , POS.C_GAUGE_TYPE_POS
             , POS.ACS_FINANCIAL_ACCOUNT_ID
             , POS.ACS_DIVISION_ACCOUNT_ID
             , POS.ACS_CPN_ACCOUNT_ID
             , POS.ACS_CDA_ACCOUNT_ID
             , POS.ACS_PF_ACCOUNT_ID
             , POS.ACS_PJ_ACCOUNT_ID
             , POS.DIC_UNIT_OF_MEASURE_ID
             , GOO.DIC_UNIT_OF_MEASURE_ID
             , GOO.GOO_NUMBER_OF_DECIMAL
             , DCD.POS_CONVERT_FACTOR_CALC
             , POS.POS_CONVERT_FACTOR
             , DCD.GCO_GOOD_ID
             , POS.GCO_GOOD_ID
             , DCD.POS_SHORT_DESCRIPTION
             , DCD.POS_LONG_DESCRIPTION
             , DCD.POS_CONVERT_FACTOR
             , decode(POS.C_GAUGE_TYPE_POS, '5', 1, POS.POS_BALANCE_QUANTITY)
             , POS.POS_NET_TARIFF
             , POS.POS_SPECIAL_TARIFF
             , POS.POS_FLAT_RATE
             , POS.POS_EFFECTIVE_DIC_TARIFF_ID
             , POS.DIC_TARIFF_ID
             , POS.POS_TARIFF_UNIT
             , POS.POS_TARIFF_SET
             , POS.POS_TARIFF_INITIALIZED
             , nvl(POS.POS_TARIFF_DATE, nvl(DMT.DMT_TARIFF_DATE, DMT.DMT_DATE_DOCUMENT) )
             , POS.POS_UPDATE_TARIFF
             , POS.POS_DISCOUNT_RATE
             , POS.POS_REF_UNIT_VALUE
             , POS.POS_UNIT_COST_PRICE
             , DCD.POS_GROSS_UNIT_VALUE_INCL
             , POS.POS_BALANCE_QTY_VALUE
             , DCD.POS_GROSS_UNIT_VALUE
             , POS.POS_GROSS_UNIT_VALUE2
             , POS.POS_NET_UNIT_VALUE
             , decode(POS.C_GAUGE_TYPE_POS, '5', 1, POS.POS_FINAL_QUANTITY)
             , POS.POS_BASIS_QUANTITY
             , POS.POS_CALC_BUDGET_AMOUNT_MB
             , POS.POS_EFFECT_BUDGET_AMOUNT_MB
             , POS.STM_STOCK_ID
             , POS.STM_STM_STOCK_ID
             , POS.STM_LOCATION_ID
             , POS.STM_STM_LOCATION_ID
             , POS.POS_GROSS_VALUE_B
             , POS.POS_UTIL_COEFF
             , POS.POS_GROSS_WEIGHT
             , POS.POS_NET_WEIGHT
             , POS.PAC_REPRESENTATIVE_ID
             , POS.PAC_REPR_ACI_ID
             , POS.PAC_REPR_DELIVERY_ID
             , POS.POS_REFERENCE
             , POS.POS_SECONDARY_REFERENCE
             , POS.POS_SHORT_DESCRIPTION
             , POS.POS_LONG_DESCRIPTION
             , POS.POS_FREE_DESCRIPTION
             , POS.POS_BODY_TEXT
             , POS.POS_EAN_CODE
             , POS.POS_EAN_UCC14_CODE
             , POS.POS_HIBC_PRIMARY_CODE
             , POS.POS_CONVERT_FACTOR2
             , POS.DIC_POS_FREE_TABLE_1_ID
             , POS.DIC_POS_FREE_TABLE_2_ID
             , POS.DIC_POS_FREE_TABLE_3_ID
             , POS.POS_DECIMAL_1
             , POS.POS_DECIMAL_2
             , POS.POS_DECIMAL_3
             , POS.POS_TEXT_1
             , POS.POS_TEXT_2
             , POS.POS_TEXT_3
             , POS.POS_DATE_1
             , POS.POS_DATE_2
             , POS.POS_DATE_3
             , POS.POS_PARTNER_NUMBER
             , POS.POS_PARTNER_REFERENCE
             , POS.POS_DATE_PARTNER_DOCUMENT
             , POS.POS_PARTNER_POS_NUMBER
             , POS.PC_APPLTXT_ID
             , POS.STM_MOVEMENT_KIND_ID
             , POS.ASA_RECORD_COMP_ID
             , POS.ASA_RECORD_TASK_ID
             , POS.HRM_PERSON_ID
             , POS.FAM_FIXED_ASSETS_ID
             , POS.C_FAM_TRANSACTION_TYP
             , POS.POS_IMF_TEXT_1
             , POS.POS_IMF_TEXT_2
             , POS.POS_IMF_TEXT_3
             , POS.POS_IMF_TEXT_4
             , POS.POS_IMF_TEXT_5
             , POS.POS_IMF_NUMBER_2
             , POS.POS_IMF_NUMBER_3
             , POS.POS_IMF_NUMBER_4
             , POS.POS_IMF_NUMBER_5
             , POS.DIC_IMP_FREE1_ID
             , POS.DIC_IMP_FREE2_ID
             , POS.DIC_IMP_FREE3_ID
             , POS.DIC_IMP_FREE4_ID
             , POS.DIC_IMP_FREE5_ID
             , POS.POS_IMF_DATE_1
             , POS.POS_IMF_DATE_2
             , POS.POS_IMF_DATE_3
             , POS.POS_IMF_DATE_4
             , POS.POS_IMF_DATE_5
             , POS.POS_DATE_DELIVERY
             , POS.FAL_LOT_ID
             , GAP.GAP_TRANSFERT_PROPRIETOR
             , GAP.C_DOC_LOT_TYPE
             , nvl(DCD.C_PDE_CREATE_MODE, '301')
             , POS.POS_IMPUTATION
             , DCD.DCD_FORCE_AMOUNT
             , DCD.POS_GROSS_VALUE
             , DCD.POS_NET_VALUE_EXCL
             , DCD.DOC_GAUGE_RECEIPT_ID
             , DCD.DOC_GAUGE_COPY_ID
             , POS.GCO_MANUFACTURED_GOOD_ID;

    -- curseur sur les composants de la position (uniquement assemblage)
    cursor ComponentPosition(aProductPositionId number, aDocumentID number)
    is
      select   DOC_POSITION_ID
          from DOC_POS_DET_COPY_DISCHARGE
         where DOC_DOC_POSITION_ID = aProductPositionId
           and CRG_SELECT = 1
           and NEW_DOCUMENT_ID = aDocumentID
      group by DOC_POSITION_ID
      order by min(DOC_POS_DET_COPY_DISCHARGE_ID);

    -- curseur d'information sur les différents types de gabarit liés à la position
    cursor gauge_position(gaugeId number, gaugeTypePos varchar2, gaugeDesignation varchar2)
    is
      -- recherche du gabarit position du nouveau document
      select   DOC_GAUGE_POSITION_ID
             , STM_MOVEMENT_KIND_ID
             , C_ADMIN_DOMAIN
             , nvl(GAP.DIC_TYPE_MOVEMENT_ID, GAS.DIC_TYPE_MOVEMENT_ID)
             , GAS_INCREMENT_NBR
             , GAS_FIRST_NO
             , GAS_BALANCE_STATUS
             , GAS_VAT
             , GAS_INCLUDE_BUDGET_CONTROL
             , GAU_CONFIRM_STATUS
             , GAP_MVT_UTILITY
             , GAP_VALUE_QUANTITY
             , GAP_INCLUDE_TAX_TARIFF
             , GAP_DELAY
             , GAS_CHARACTERIZATION
             , C_GAUGE_INIT_PRICE_POS
             , C_ROUND_APPLICATION
             , DIC_DELAY_UPDATE_TYPE_ID
             , GAP_INIT_STOCK_PLACE
             , GAP.STM_STOCK_ID
             , GAP.STM_LOCATION_ID
             , GAP.STM_STM_STOCK_ID
             , GAP.STM_STM_LOCATION_ID
             , GAP_VALUE
             , GAP_WEIGHT
             , GAP_FORCED_TARIFF
             , DIC_TARIFF_ID
             , GAS.GAS_RECORD_IMPUTATION
             , nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
             , GAS.GAS_PROC_VALIDATE_POS
             , GAS.GAS_PROC_AFTER_VALIDATE_POS
             , GAP.C_DOC_LOT_TYPE
             , GAP_SUBCONTRACTP_STOCK
             , GAP_STM_SUBCONTRACTP_STOCK
          from DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
         where GAU.DOC_GAUGE_ID = gaugeId
           and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and GAP.C_GAUGE_TYPE_POS = gaugeTypePos
           and GAP.GAP_DESIGNATION = gaugeDesignation
      order by GAP.GAP_DEFAULT desc;

    SourcePosition_tuple        SourcePosition%rowtype;
    GaugeReceipt_tuple          doc_gauge_receipt%rowtype;
    TargetDocument_tuple        doc_document%rowtype;
    ComponentPositionId         doc_position.doc_position_id%type;
    SourceCurrencyId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TargetPositionId            doc_position.doc_position_id%type;
    TargetGaugePositionId       DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type;
    TargetMovementKindId        STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    TargetStockId               STM_STOCK.STM_STOCK_ID%type;
    TargetStock2Id              STM_STOCK.STM_STOCK_ID%type;
    TargetLocationId            STM_LOCATION.STM_LOCATION_ID%type;
    TargetLocation2Id           STM_LOCATION.STM_LOCATION_ID%type;
    TargetRecordId              DOC_RECORD.DOC_RECORD_ID%type;
    TargetDocDocRecordId        DOC_RECORD.DOC_RECORD_ID%type;
    TargetPersonId              PAC_PERSON.PAC_PERSON_ID%type;
    TargetTaxCodeId             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceFinAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceDivAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceCpnAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceCdaAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourcePfAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourcePjAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetFinAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetDivAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetCpnAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetCdaAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetPfAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetPjAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    LinkMovementKindID          STM_MOVEMENT_KIND.STM_STM_MOVEMENT_KIND_ID%type;
    ConvertFactor               DOC_POSITION.POS_CONVERT_FACTOR%type;
    vPriceConvertFactor         DOC_POSITION.POS_CONVERT_FACTOR%type;
    vQtyConvertFactor           DOC_POSITION.POS_CONVERT_FACTOR%type;
    ModifiedConvertFactor       DOC_POSITION.POS_CONVERT_FACTOR%type;
    ConvertFactor2              DOC_POSITION.POS_CONVERT_FACTOR2%type;
    DicUnitOfMeasureId          DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type;
    DicDicUnitOfMeasureId       DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type;
    NetWeight                   DOC_POSITION.POS_NET_WEIGHT%type;
    GrossWeight                 DOC_POSITION.POS_GROSS_WEIGHT%type;
    UtilCoef                    DOC_POSITION.POS_UTIL_COEFF%type;
    reference                   DOC_POSITION.POS_REFERENCE%type;
    SecondaryReference          DOC_POSITION.POS_SECONDARY_REFERENCE%type;
    ShortDescription            DOC_POSITION.POS_SHORT_DESCRIPTION%type;
    LongDescription             DOC_POSITION.POS_LONG_DESCRIPTION%type;
    FreeDescription             DOC_POSITION.POS_FREE_DESCRIPTION%type;
    BodyText                    DOC_POSITION.POS_BODY_TEXT%type;
    EANCode                     DOC_POSITION.POS_EAN_CODE%type;
    EANUCC14Code                DOC_POSITION.POS_EAN_UCC14_CODE%type;
    HIBCPrimaryCode             DOC_POSITION.POS_HIBC_PRIMARY_CODE%type;
    PriceCurrencyId             ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    RefUnitValue                DOC_POSITION.POS_REF_UNIT_VALUE%type;
    UnitCostPrice               DOC_POSITION.POS_UNIT_COST_PRICE%type;
    GrossUnitValue              DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    GrossUnitValue2             DOC_POSITION.POS_GROSS_UNIT_VALUE2%type;
    GrossUnitValueIncl          DOC_POSITION.POS_GROSS_UNIT_VALUE_INCL%type;
    GrossValue                  DOC_POSITION.POS_GROSS_VALUE%type;
    GrossValueIncl              DOC_POSITION.POS_GROSS_VALUE_INCL%type;
    NetUnitValue                DOC_POSITION.POS_NET_UNIT_VALUE%type;
    NetUnitvalueIncl            DOC_POSITION.POS_NET_UNIT_VALUE_INCL%type;
    NetValueExcl                DOC_POSITION.POS_NET_VALUE_EXCL%type;
    NetValueIncl                DOC_POSITION.POS_NET_VALUE_INCL%type;
    CalcBudgetAmount            DOC_POSITION.POS_CALC_BUDGET_AMOUNT_MB%type;
    EffectBudgetAmount          DOC_POSITION.POS_EFFECT_BUDGET_AMOUNT_MB%type;
    DeliveryDate                DOC_POSITION.POS_DATE_DELIVERY%type;
    VatRate                     DOC_POSITION.POS_VAT_RATE%type;
    VatLiabledRate              DOC_POSITION.POS_VAT_LIABLED_RATE%type;
    VatLiabledAmount            DOC_POSITION.POS_VAT_LIABLED_AMOUNT%type;
    VatTotalAmount              DOC_POSITION.POS_VAT_TOTAL_AMOUNT%type;
    VatDeductibleRate           DOC_POSITION.POS_VAT_DEDUCTIBLE_RATE%type;
    VatAmount                   DOC_POSITION.POS_VAT_AMOUNT%type;
    PosNetTariff                DOC_POSITION.POS_NET_TARIFF%type;
    PosSpecialTariff            DOC_POSITION.POS_SPECIAL_TARIFF%type;
    PosFlatRate                 DOC_POSITION.POS_FLAT_RATE%type;
    PosTariffUnit               DOC_POSITION.POS_TARIFF_UNIT%type;
    PosTariffSet                DOC_POSITION.POS_TARIFF_SET%type;
    PosTariffInitialized        DOC_POSITION.POS_TARIFF_INITIALIZED%type;
    PosUpdateTariff             DOC_POSITION.POS_UPDATE_TARIFF%type;
    DiscountUnitValue           DOC_POSITION.POS_DISCOUNT_UNIT_VALUE%type;
    DiscountRate                DOC_POSITION.POS_DISCOUNT_RATE%type;
    PositionStatus              DOC_POSITION.C_DOC_POS_STATUS%type;
    RoundType                   varchar2(1);
    RoundAmount                 number(18, 5);
    ChargeCreated               number(1);
    ChargeAmount                DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    DiscountAmount              DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    TargetAdminDomain           DOC_GAUGE.C_ADMIN_DOMAIN%type;
    SourceAdminDomain           DOC_GAUGE.C_ADMIN_DOMAIN%type;
    ConfirmStatus               DOC_GAUGE.GAU_CONFIRM_STATUS%type;
    TargetTypeMovement          DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
    PosIncrement                DOC_GAUGE_STRUCTURED.GAS_INCREMENT_NBR%type;
    PosFirstNo                  DOC_GAUGE_STRUCTURED.GAS_FIRST_NO%type;
    BalanceStatus               DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type;
    GestVat                     DOC_GAUGE_STRUCTURED.GAS_VAT%type;
    IncludeBudgetControl        DOC_GAUGE_STRUCTURED.GAS_INCLUDE_BUDGET_CONTROL%type;
    InitMovement                DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type;
    GestValueQuantity           DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    GapWeight                   DOC_GAUGE_POSITION.GAP_WEIGHT%type;
    GapForcedTariff             DOC_GAUGE_POSITION.GAP_FORCED_TARIFF%type;
    vDicTariffId                DOC_GAUGE_POSITION.DIC_TARIFF_ID%type;
    vEffectiveDicTariffId       DOC_GAUGE_POSITION.DIC_TARIFF_ID%type;
    IncludeTaxTariff            DOC_GAUGE_POSITION.GAP_INCLUDE_TAX_TARIFF%type;
    SourceValueManagement       DOC_GAUGE_POSITION.GAP_VALUE%type;
    GaugeInitPricePos           DOC_GAUGE_POSITION.C_GAUGE_INIT_PRICE_POS%type;
    SourceGestDelay             DOC_GAUGE_POSITION.GAP_DELAY%type;
    GestDelay                   DOC_GAUGE_POSITION.GAP_DELAY%type;
    DelayUpdateType             DOC_GAUGE_POSITION.DIC_DELAY_UPDATE_TYPE_ID%type;
    InitStockAndLocation        DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type;
    GapStockID                  DOC_GAUGE_POSITION.STM_STOCK_ID%type;
    GapLocationID               DOC_GAUGE_POSITION.STM_LOCATION_ID%type;
    GapStockID2                 DOC_GAUGE_POSITION.STM_STM_STOCK_ID%type;
    GapLocationID2              DOC_GAUGE_POSITION.STM_STM_LOCATION_ID%type;
    ValueManagement             DOC_GAUGE_POSITION.GAP_VALUE%type;
    ParentGestChar              DOC_GAUGE_STRUCTURED.GAS_CHARACTERIZATION%type;
    GestChar                    DOC_GAUGE_STRUCTURED.GAS_CHARACTERIZATION%type;
    SourceGaugeDesignation      DOC_GAUGE_POSITION.GAP_DESIGNATION%type;
    cdaReference                GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    cdaSecondaryReference       GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    cdaEanCode                  GCO_GOOD.GOO_EAN_CODE%type;
    cdaEanUCC14Code             GCO_GOOD.GOO_EAN_UCC14_CODE%type;
    cdaHIBCPrimaryCode          GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
    cdaShortDescription         GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    cdaLongDescription          GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    cdaFreeDescription          GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    cdaDicUnitOfMeasureId       DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type;
    cdaConvertFactor            GCO_COMPL_DATA_SALE.CDA_CONVERSION_FACTOR%type;
    cdaNumberOfDecimal          GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    goodNumberOfDecimal         GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    cdaBodyText                 DOC_POSITION.POS_BODY_TEXT%type;
    cdaStockId                  STM_STOCK.STM_STOCK_ID%type;
    cdaLocationId               STM_LOCATION.STM_LOCATION_ID%type;
    cdaQuantity                 DOC_POSITION.POS_BASIS_QUANTITY%type;
    basisQuantity               DOC_POSITION.POS_BASIS_QUANTITY%type;
    intermediateQuantity        DOC_POSITION.POS_INTERMEDIATE_QUANTITY%type;
    finalQuantity               DOC_POSITION.POS_FINAL_QUANTITY%type;
    basisQuantitySU             DOC_POSITION.POS_BASIS_QUANTITY_SU%type;
    intermediateQuantitySU      DOC_POSITION.POS_INTERMEDIATE_QUANTITY_SU%type;
    finalQuantitySU             DOC_POSITION.POS_FINAL_QUANTITY_SU%type;
    valueQuantity               DOC_POSITION.POS_VALUE_QUANTITY%type;
    balanceQuantityValue        DOC_POSITION.POS_BALANCE_QTY_VALUE%type;
    AlreadyLoadComplData        number(1);
    AlreadyLoadDecimalComplData number(1);
    -- Flags sur les données gêrées
    HrmPerson                   number(1);
    FamFixed                    number(1);
    Text1                       number(1);
    Text2                       number(1);
    Text3                       number(1);
    Text4                       number(1);
    Text5                       number(1);
    Number1                     number(1);
    Number2                     number(1);
    Number3                     number(1);
    Number4                     number(1);
    Number5                     number(1);
    DicFree1                    number(1);
    DicFree2                    number(1);
    DicFree3                    number(1);
    DicFree4                    number(1);
    DicFree5                    number(1);
    Date1                       number(1);
    Date2                       number(1);
    Date3                       number(1);
    Date4                       number(1);
    Date5                       number(1);
    BalanceQuantityParentSource doc_position_detail.pde_balance_quantity_parent%type;
    vFinancial                  DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical                 DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl                  DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vInfoCompl_DOC_RECORD       integer                                                 default 0;
    vAccountInfo                ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    dmtNumberFather             DOC_DOCUMENT.DMT_NUMBER%type;
    gasWeightMat                DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    srcWeightMat                DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    posCreateMat                DOC_POSITION.POS_CREATE_MAT%type;
    cGaugeType                  DOC_GAUGE.C_GAUGE_TYPE%type;
    gasAutoAttrib               DOC_GAUGE_STRUCTURED.GAS_AUTO_ATTRIBUTION%type;
    gasRecordImputation         DOC_GAUGE_STRUCTURED.GAS_RECORD_IMPUTATION%type;
    srcRecordImputation         DOC_GAUGE_STRUCTURED.GAS_RECORD_IMPUTATION%type;
    nbAttribs                   number;
    vGapRoundApplication        DOC_GAUGE_POSITION.C_ROUND_APPLICATION%type;
    vTmpErrorMsg                varchar2(2000);
    vGasProvValidatePos         DOC_GAUGE_STRUCTURED.GAS_PROC_VALIDATE_POS%type;
    vGasProcAfterValidatePos    DOC_GAUGE_STRUCTURED.GAS_PROC_AFTER_VALIDATE_POS%type;
    lvCDocLotType               DOC_GAUGE_POSITION.C_DOC_LOT_TYPE%type;
    lnGapSubcontractStock       DOC_GAUGE_POSITION.GAP_SUBCONTRACTP_STOCK%type;
    lnGapStmSubcontractStock    DOC_GAUGE_POSITION.GAP_STM_SUBCONTRACTP_STOCK%type;
    lnSourceSupplierID          PAC_THIRD.PAC_THIRD_ID%type;
    lnTargetSupplierID          PAC_THIRD.PAC_THIRD_ID%type;
    lvGaugeTypePosPT            DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    lbProcessingCPT             boolean;
    lnLocalCurrency             ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lnConvertAmount             number(1);
  begin
    savepoint spDischargePosition;
    aDischargeInfoCode           := '00';   -- traîtement OK
    RefUnitValue                 := 0;
    UnitCostPrice                := 0;
    GrossUnitValue               := 0;
    GrossUnitValue2              := 0;
    GrossUnitValueIncl           := 0;
    GrossValue                   := 0;
    GrossValueIncl               := 0;
    NetUnitValue                 := 0;
    NetUnitvalueIncl             := 0;
    NetValueExcl                 := 0;
    NetValueIncl                 := 0;
    CalcBudgetAmount             := 0;
    EffectBudgetAmount           := 0;
    DeliveryDate                 := null;
    VatRate                      := 0;
    VatLiabledRate               := 0;
    VatLiabledAmount             := 0;
    VatTotalAmount               := 0;
    VatDeductibleRate            := 0;
    VatAmount                    := 0;
    DiscountUnitValue            := 0;
    ChargeAmount                 := 0;
    DiscountAmount               := 0;
    AlreadyLoadComplData         := 0;
    AlreadyLoadDecimalComplData  := 0;
    posCreateMat                 := 0;
    lbProcessingCPT              := false;

    -- pointeur sur la position source
    open SourcePosition(aSourcePositionId, aTargetDocumentId);

    fetch SourcePosition
     into SourcePosition_tuple;

    -- pointeur sur le document cible
    select *
      into TargetDocument_tuple
      from doc_document
     where doc_document_id = aTargetDocumentId;

    -- recherche divers informations document source
    select ACS_FINANCIAL_CURRENCY_ID
         , C_ADMIN_DOMAIN
         , GAS_CHARACTERIZATION
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
         , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
         , nvl(GAS_WEIGHT_MAT, 0)
         , nvl(GAS_RECORD_IMPUTATION, 0)
      into SourceCurrencyId
         , SourceAdminDomain
         , ParentGestChar
         , vFinancial
         , vAnalytical
         , vInfoCompl
         , srcWeightMat
         , srcRecordImputation
      from DOC_DOCUMENT DOC
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
     where DOC.DOC_DOCUMENT_ID = SourcePosition_tuple.DOC_DOCUMENT_ID
       and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    -- Vérifier si le type DOC_RECORD est géré dans les info compl du gabarit du
    -- document cible
    if vInfoCompl = 1 then
      select nvl(max(1), 0)
        into vInfoCompl_DOC_RECORD
        from DOC_GAUGE_MANAGED_DATA GMA
       where DOC_GAUGE_ID = TargetDocument_tuple.DOC_GAUGE_ID
         and C_DATA_TYP = 'DOC_RECORD';
    end if;

    begin
      -- pointeur sur le gabarit de décharge
      if SourcePosition_tuple.doc_gauge_receipt_id > 0 then
        select gar.*
          into GaugeReceipt_tuple
          from doc_gauge_receipt gar
         where gar.doc_gauge_receipt_id = SourcePosition_tuple.doc_gauge_receipt_id;
      else
        select gar.*
          into GaugeReceipt_tuple
          from doc_gauge_receipt gar
             , doc_gauge_flow_docum gad
         where gad.doc_gauge_flow_id = SourcePosition_tuple.doc_gauge_flow_id
           and gar.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
           and gad.doc_gauge_id = TargetDocument_tuple.doc_gauge_id
           and gar.doc_doc_gauge_id = SourcePosition_tuple.doc_gauge_id;
      end if;
    exception
      when no_data_found then
        raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Aucun flux de décharge trouvé!') || co.cLineBreak || sqlerrm);
    end;

    -- Décharge d'une position PT avec les composants de type 1 (position liée)
    -- vérifier qu'il y ai au moins un cpt sélectionné
    if SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
      declare
        vCountPos    integer;
        vSelectedPos integer;
      begin
        select count(*) COUNT_POS
             , sum(nvl(CRG_SELECT, 0) ) SELECTED_POS
          into vCountPos
             , vSelectedPos
          from DOC_POS_DET_COPY_DISCHARGE
         where NEW_DOCUMENT_ID = aTargetDocumentId
           and DOC_DOC_POSITION_ID = aSourcePositionId
           and C_GAUGE_TYPE_POS = '1';

        if     (vCountPos > 0)
           and (vSelectedPos = 0) then
          raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Aucune position composant sélectionnée!') || co.cLineBreak || sqlerrm);
        end if;
      end;
    end if;

    -- recherche du dossier
    select decode(GaugeReceipt_tuple.GAR_TRANSFERT_RECORD, 0, TargetDocument_tuple.DOC_RECORD_ID, SourcePosition_tuple.DOC_RECORD_ID)
      into TargetRecordId
      from dual;

    -- recherche de valeurs sur le gabarit de la position source
    select gap_value
         , gap_delay
         , gap_designation
      into SourceValueManagement
         , SourceGestDelay
         , SourceGaugeDesignation
      from DOC_GAUGE_POSITION
     where DOC_GAUGE_POSITION_ID = SourcePosition_tuple.doc_gauge_position_id;

    -- recherche du gabarit position du nouveau document
    open gauge_position(TargetDocument_tuple.DOC_GAUGE_ID, SourcePosition_tuple.c_gauge_type_pos, SourceGaugeDesignation);

    --if SourcePosition_tuple.DOC_DOC_POSITION_ID is not null then
    --  raise_application_error(-20000,'Gabarit cible : ' || TargetDocument_tuple.DOC_GAUGE_ID || ' /' || 'Type de position : ' || SourcePosition_tuple.c_gauge_type_pos || ' / ' || SourceGaugeDesignation);
    --end if;
    fetch gauge_position
     into TargetGaugePositionId
        , TargetMovementKindId
        , TargetAdminDomain
        , TargetTypeMovement
        , PosIncrement
        , PosFirstNo
        , BalanceStatus
        , GestVat
        , IncludeBudgetControl
        , ConfirmStatus
        , InitMovement
        , GestValueQuantity
        , IncludeTaxTariff
        , GestDelay
        , GestChar
        , GaugeInitPricePos
        , vGapRoundApplication
        , DelayUpdateType
        , InitStockAndLocation
        , GapStockID
        , GapLocationID
        , GapStockID2
        , GapLocationID2
        , ValueManagement
        , GapWeight
        , GapForcedTariff
        , vDicTariffId
        , gasRecordImputation
        , gasWeightMat
        , vGasProvValidatePos
        , vGasProcAfterValidatePos
        , lvCDocLotType
        , lnGapSubcontractStock
        , lnGapStmSubcontractStock;

    ---
    -- Control de la cohérence des types de position entre la position père et
    -- la position fille. En effet, il faut absolument que la règle suivante
    -- soit définie : La description et la case à cocher par défaut doivent être
    -- identique sur les deux gabarits position (père et fils).
    if not gauge_position%found then
      -- Ferme tous les curseurs ouverts avant l'exception.
      close gauge_position;

      close SourcePosition;

      raise_application_error(-20100
                            , PCS.PC_FUNCTIONS.TranslateWord('Décharge impossible') ||
                              co.cLineBreak ||
                              PCS.PC_FUNCTIONS.TranslateWord('Contrôler l''égalité entre les descriptions des gabarits positions père et fils') ||
                              co.cLineBreak ||
                              'Document père : ' ||
                              SourcePosition_tuple.DMT_NUMBER ||
                              co.cLineBreak ||
                              'Document fils : ' ||
                              TargetDocument_tuple.DMT_NUMBER
                             );
    end if;

    close gauge_position;

    -- Sous-traitance d'achat
    -- Décharge d'une position dont la gestion du lot est "Sous-traitance d'achat" sur gabarit pos source et null sur gabarit pos cible
    --   Dans ce cas, il faut utiliser le produit fabriqué de la pos source comme bien dans la pos cible (si changement de bien autorisé dans le flux)
    if     (SourcePosition_tuple.C_DOC_LOT_TYPE = '001')
       and (lvCDocLotType is null)
       and (SourcePosition_tuple.POS_GOOD_ID = SourcePosition_tuple.GCO_GOOD_ID)
       and (SourcePosition_tuple.GCO_MANUFACTURED_GOOD_ID is not null)
       and (GaugeReceipt_tuple.GAR_GOOD_CHANGING = 1) then
      SourcePosition_tuple.GCO_GOOD_ID  := SourcePosition_tuple.GCO_MANUFACTURED_GOOD_ID;
    end if;

    if GestVat = 1 then
      -- Recherche du code Taxe
      TargetTaxCodeId  :=
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(1
                                              , TargetDocument_tuple.PAC_THIRD_VAT_ID
                                              , SourcePosition_tuple.GCO_GOOD_ID
                                              , 0
                                              , 0
                                              , TargetAdminDomain
                                              , TargetDocument_tuple.DIC_TYPE_SUBMISSION_ID
                                              , TargetTypeMovement
                                              , TargetDocument_tuple.ACS_VAT_DET_ACCOUNT_ID
                                               );
    end if;

    -- Si gestion ou initialisation des comptes financiers ou analytiques sur le document source
    -- et pas de changement de tiers et domaine cible indentique au domaine source
    -- alors on reprend les comptes de la position source.
    if     (    (vFinancial = 1)
            or (vAnalytical = 1) )
       and (SourcePosition_tuple.PAC_THIRD_ID = TargetDocument_tuple.PAC_THIRD_ID)
       and (SourceAdminDomain = TargetAdminDomain) then
      SourceFinAccountId  := SourcePosition_tuple.ACS_FINANCIAL_ACCOUNT_ID;
      SourceDivAccountId  := SourcePosition_tuple.ACS_DIVISION_ACCOUNT_ID;
      SourceCpnAccountId  := SourcePosition_tuple.ACS_CPN_ACCOUNT_ID;
      SourceCdaAccountId  := SourcePosition_tuple.ACS_CDA_ACCOUNT_ID;
      SourcePfAccountId   := SourcePosition_tuple.ACS_PF_ACCOUNT_ID;
      SourcePjAccountId   := SourcePosition_tuple.ACS_PJ_ACCOUNT_ID;

      if (vInfoCompl = 1) then
        -- recherche du DOC_DOC_RECORD_ID et PAC_PERSON_ID
        -- Effacer les données du champ DOC_DOC_RECORD_ID si le gabarit ne géré pas
        -- le type DOC_RECORD dans les informations complémentaires
        select case
                 when vInfoCompl_DOC_RECORD = 1 then nvl(SourcePosition_tuple.DOC_DOC_RECORD_ID, nvl(TargetRecordId, TargetDocument_tuple.DOC_RECORD_ID) )
                 else null
               end
             , nvl(SourcePosition_tuple.PAC_PERSON_ID, TargetDocument_tuple.PAC_THIRD_ID)
          into TargetDocDocRecordId
             , TargetPersonId
          from dual;

        vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(SourcePosition_tuple.HRM_PERSON_ID);
        vAccountInfo.FAM_FIXED_ASSETS_ID    := SourcePosition_tuple.FAM_FIXED_ASSETS_ID;
        vAccountInfo.C_FAM_TRANSACTION_TYP  := SourcePosition_tuple.C_FAM_TRANSACTION_TYP;
        vAccountInfo.DEF_DIC_IMP_FREE1      := SourcePosition_tuple.DIC_IMP_FREE1_ID;
        vAccountInfo.DEF_DIC_IMP_FREE2      := SourcePosition_tuple.DIC_IMP_FREE2_ID;
        vAccountInfo.DEF_DIC_IMP_FREE3      := SourcePosition_tuple.DIC_IMP_FREE3_ID;
        vAccountInfo.DEF_DIC_IMP_FREE4      := SourcePosition_tuple.DIC_IMP_FREE4_ID;
        vAccountInfo.DEF_DIC_IMP_FREE5      := SourcePosition_tuple.DIC_IMP_FREE5_ID;
        vAccountInfo.DEF_TEXT1              := SourcePosition_tuple.POS_IMF_TEXT_1;
        vAccountInfo.DEF_TEXT2              := SourcePosition_tuple.POS_IMF_TEXT_2;
        vAccountInfo.DEF_TEXT3              := SourcePosition_tuple.POS_IMF_TEXT_3;
        vAccountInfo.DEF_TEXT4              := SourcePosition_tuple.POS_IMF_TEXT_4;
        vAccountInfo.DEF_TEXT5              := SourcePosition_tuple.POS_IMF_TEXT_5;
        vAccountInfo.DEF_NUMBER2            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_2);
        vAccountInfo.DEF_NUMBER3            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_3);
        vAccountInfo.DEF_NUMBER4            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_4);
        vAccountInfo.DEF_NUMBER5            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_5);
        vAccountInfo.DEF_DATE1              := SourcePosition_tuple.POS_IMF_DATE_1;
        vAccountInfo.DEF_DATE2              := SourcePosition_tuple.POS_IMF_DATE_2;
        vAccountInfo.DEF_DATE3              := SourcePosition_tuple.POS_IMF_DATE_3;
        vAccountInfo.DEF_DATE4              := SourcePosition_tuple.POS_IMF_DATE_4;
        vAccountInfo.DEF_DATE5              := SourcePosition_tuple.POS_IMF_DATE_5;
      end if;
    else
      SourceFinAccountId  := null;
      SourceDivAccountId  := null;
      SourceCpnAccountId  := null;
      SourceCdaAccountId  := null;
      SourcePfAccountId   := null;
      SourcePjAccountId   := null;
    end if;

    if SourcePosition_tuple.C_GAUGE_TYPE_POS = '5' then   -- Position valeur
      -- recherche des comptes non définis
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(null
                                             , '40'
                                             , TargetAdminDomain
                                             , TargetDocument_tuple.DMT_DATE_DOCUMENT
                                             , null
                                             , TargetDocument_tuple.DOC_GAUGE_ID
                                             , aTargetDocumentId
                                             , aTargetPositionId
                                             , TargetRecordId
                                             , TargetDocument_tuple.PAC_THIRD_ACI_ID
                                             , SourceFinAccountId
                                             , SourceDivAccountId
                                             , SourceCpnAccountId
                                             , SourceCdaAccountId
                                             , SourcePfAccountId
                                             , SourcePjAccountId
                                             , TargetFinAccountId
                                             , TargetDivAccountId
                                             , TargetCpnAccountId
                                             , TargetCdaAccountId
                                             , TargetPfAccountId
                                             , TargetPjAccountId
                                             , vAccountInfo
                                              );
    else
      -- recherche des comptes non définis
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(SourcePosition_tuple.GCO_GOOD_ID
                                             , '10'
                                             , TargetAdminDomain
                                             , TargetDocument_tuple.DMT_DATE_DOCUMENT
                                             , SourcePosition_tuple.GCO_GOOD_ID
                                             , TargetDocument_tuple.DOC_GAUGE_ID
                                             , aTargetDocumentId
                                             , aTargetPositionId
                                             , TargetRecordId
                                             , TargetDocument_tuple.PAC_THIRD_ACI_ID
                                             , SourceFinAccountId
                                             , SourceDivAccountId
                                             , SourceCpnAccountId
                                             , SourceCdaAccountId
                                             , SourcePfAccountId
                                             , SourcePjAccountId
                                             , TargetFinAccountId
                                             , TargetDivAccountId
                                             , TargetCpnAccountId
                                             , TargetCdaAccountId
                                             , TargetPfAccountId
                                             , TargetPjAccountId
                                             , vAccountInfo
                                              );
    end if;

    ---
    -- Recherche des données complémentaires si changement de bien ou pas de
    -- reprise des description.
    if    (SourcePosition_tuple.POS_GOOD_ID <> SourcePosition_tuple.GCO_GOOD_ID)
       or (SourcePosition_tuple.PAC_THIRD_ID <> TargetDocument_tuple.PAC_THIRD_ID)
       or (GaugeReceipt_tuple.GAR_TRANSFERT_DESCR = 0) then
      if TargetAdminDomain = '2' then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '2'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   /* aOperationID */
                                                , 0   /* aTransProprietor */
                                                , null   /* aComplDataID */
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      elsif TargetAdminDomain in('1', '5') then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '1'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   -- aOperationID
                                                , 0   -- aTransProprietor
                                                , null   -- aComplDataID
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      end if;

      -- Si le transfert des descriptions est actif et que l'on a un changement de tiers. Il faut
      -- reprendre la donnée complémentaire du nouveau tiers et si la valeur n'existe pas sur la donnée
      -- complémentaire, la reprendre de la position père.
      if     (GaugeReceipt_tuple.GAR_TRANSFERT_DESCR = 1)
         and (SourcePosition_tuple.PAC_THIRD_ID <> TargetDocument_tuple.PAC_THIRD_ID) then
        reference           := nvl(cdaReference, SourcePosition_tuple.POS_REFERENCE);
        SecondaryReference  := nvl(cdaSecondaryReference, SourcePosition_tuple.POS_SECONDARY_REFERENCE);
        ShortDescription    := nvl(cdaShortDescription, SourcePosition_tuple.POS_SHORT_DESCRIPTION);
        LongDescription     := nvl(cdaLongDescription, SourcePosition_tuple.POS_LONG_DESCRIPTION);
        FreeDescription     := nvl(cdaFreeDescription, SourcePosition_tuple.POS_FREE_DESCRIPTION);
        BodyText            := nvl(cdaBodyText, SourcePosition_tuple.POS_BODY_TEXT);
        EANCode             := nvl(cdaEanCode, SourcePosition_tuple.POS_EAN_CODE);
        EANUCC14Code        := nvl(cdaEanUCC14Code, SourcePosition_tuple.POS_EAN_UCC14_CODE);
        HIBCPrimaryCode     := nvl(cdaHIBCPrimaryCode, SourcePosition_tuple.POS_HIBC_PRIMARY_CODE);
      else
        -- Sinon, on utilise la nouvelle donnée complémentaire.
        reference           := cdaReference;
        SecondaryReference  := cdaSecondaryReference;
        ShortDescription    := cdaShortDescription;
        LongDescription     := cdaLongDescription;
        FreeDescription     := cdaFreeDescription;
        BodyText            := cdaBodyText;
        EANCode             := cdaEanCode;
        EANUCC14Code        := cdaEanUCC14Code;
        HIBCPrimaryCode     := cdaHIBCPrimaryCode;
      end if;

      -- Recherche du facteur de conversion et unité de mesure
      if SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8', '9', '10', '71', '81', '91', '101') then
        ConvertFactor          := 1;
        ModifiedConvertFactor  := 0;
        DicUnitOfMeasureId     := SourcePosition_tuple.GOO_UNIT_OF_MEASURE_ID;
      else
        if (SourcePosition_tuple.POS_CONVERT_FACTOR_CALC <> cdaConvertFactor) then
          ConvertFactor          := SourcePosition_tuple.POS_CONVERT_FACTOR_CALC;
          ModifiedConvertFactor  := 1;
        else
          ConvertFactor          := cdaConvertFactor;
          ModifiedConvertFactor  := 0;
        end if;

        DicUnitOfMeasureId  := cdaDicUnitOfMeasureId;
      end if;

      ModifiedConvertFactor  := 0;
      vPriceConvertFactor    := cdaConvertFactor;
      vQtyConvertFactor      := cdaConvertFactor;
      ConvertFactor2         := cdaConvertFactor;
      DicDicUnitOfMeasureId  := SourcePosition_tuple.GOO_UNIT_OF_MEASURE_ID;
    else
      ---
      -- Pas de changement de bien et transfert description
      ---
      reference              := SourcePosition_tuple.POS_REFERENCE;
      SecondaryReference     := SourcePosition_tuple.POS_SECONDARY_REFERENCE;
      ShortDescription       := SourcePosition_tuple.POS_SHORT_DESCRIPTION;
      LongDescription        := SourcePosition_tuple.POS_LONG_DESCRIPTION;
      FreeDescription        := SourcePosition_tuple.POS_FREE_DESCRIPTION;
      BodyText               := SourcePosition_tuple.POS_BODY_TEXT;
      EANCode                := SourcePosition_tuple.POS_EAN_CODE;
      EANUCC14Code           := SourcePosition_tuple.POS_EAN_UCC14_CODE;
      HIBCPrimaryCode        := SourcePosition_tuple.POS_HIBC_PRIMARY_CODE;

      ---
      -- Reprend le facteur de conversion s'il a été modifié par l'utilisateur
      ---
      if (SourcePosition_tuple.POS_CONVERT_FACTOR_CALC <> SourcePosition_tuple.POS_CONVERT_FACTOR) then
        ConvertFactor          := SourcePosition_tuple.POS_CONVERT_FACTOR_CALC;
        ModifiedConvertFactor  := 1;
      else
        ConvertFactor          := SourcePosition_tuple.POS_CONVERT_FACTOR;
        ModifiedConvertFactor  := 0;
      end if;

      vQtyConvertFactor      := SourcePosition_tuple.POS_CONVERT_FACTOR;
      vPriceConvertFactor    := SourcePosition_tuple.POS_CONVERT_FACTOR;
      ConvertFactor2         := nvl(SourcePosition_tuple.POS_CONVERT_FACTOR2, SourcePosition_tuple.POS_CONVERT_FACTOR);
      DicUnitOfMeasureId     := SourcePosition_tuple.DIC_UNIT_OF_MEASURE_ID;
      DicDicUnitOfMeasureId  := SourcePosition_tuple.GOO_UNIT_OF_MEASURE_ID;
    end if;

    --**
    -- Détermine s'il faut convertir la quantité en fonction du facteur de
    -- conversion. C'est le cas si l'unité de mesure du parent est différent de
    -- celle du fils et que le tranfert de la quantité est demandée et qu'il y a
    -- changement de bien ou pas de reprise des descriptions. Attention, il faut
    -- aussi tenir compte du fait que la conversion ne doit pas se faire lorsque
    -- l'utilisateur a intentionnellement modifié le facteur dans le grid de
    -- décharge (par l'intermédaire de la modification de la quantité en unité de
    -- stockage).
    --**
    if     (SourcePosition_tuple.DIC_UNIT_OF_MEASURE_ID <> DicUnitOfMeasureId)
       and (GaugeReceipt_tuple.GAR_TRANSFERT_QUANTITY = 1)
       and (    (SourcePosition_tuple.POS_GOOD_ID <> SourcePosition_tuple.GCO_GOOD_ID)
            or (SourcePosition_tuple.PAC_THIRD_ID <> TargetDocument_tuple.PAC_THIRD_ID)
            or (GaugeReceipt_tuple.GAR_TRANSFERT_DESCR = 0)
           )
       and (ModifiedConvertFactor = 0)
       and (SourcePosition_tuple.POS_CONVERT_FACTOR <> vQtyConvertFactor) then
      ---
      -- On doit rechercher le nombre de décimal des données complémentaires si
      -- il n'a pas déjà été recherché.
      ---
      if (AlreadyLoadComplData = 0) then
        if TargetAdminDomain = '2' then
          GCO_I_LIB_COMPL_DATA.GetCDANumberOfDecimal(SourcePosition_tuple.GCO_GOOD_ID
                                                   , 'SALE'
                                                   , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                   , TargetDocument_tuple.PC_LANG_ID
                                                   , cdaNumberOfDecimal
                                                    );
          AlreadyLoadDecimalComplData  := 1;
        elsif TargetAdminDomain in('1', '5') then
          GCO_I_LIB_COMPL_DATA.GetCDANumberOfDecimal(SourcePosition_tuple.GCO_GOOD_ID
                                                   , 'PURCHASE'
                                                   , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                   , TargetDocument_tuple.PC_LANG_ID
                                                   , cdaNumberOfDecimal
                                                    );
          AlreadyLoadDecimalComplData  := 1;
        end if;
      end if;

      BasisQuantity           := SourcePosition_tuple.DCD_QUANTITY * SourcePosition_tuple.POS_CONVERT_FACTOR / vQtyConvertFactor;   -- Facteur de conversion du fils
      BasisQuantity           := ACS_FUNCTION.RoundNear(BasisQuantity, 1 / power(10, cdaNumberOfDecimal), 0);
      IntermediateQuantity    := BasisQuantity;
      FinalQuantity           := BasisQuantity;
      BasisQuantitySU         := SourcePosition_tuple.DCD_QUANTITY_SU;
      IntermediateQuantitySU  := SourcePosition_tuple.DCD_QUANTITY_SU;
      FinalQuantitySU         := SourcePosition_tuple.DCD_QUANTITY_SU;
    elsif(GaugeReceipt_tuple.GAR_TRANSFERT_QUANTITY = 0) then
      BasisQuantity           := 0;
      IntermediateQuantity    := 0;
      FinalQuantity           := 0;
      BasisQuantitySU         := 0;
      IntermediateQuantitySU  := 0;
      FinalQuantitySU         := 0;
    else
      BasisQuantity           := SourcePosition_tuple.DCD_QUANTITY;
      IntermediateQuantity    := SourcePosition_tuple.DCD_QUANTITY;
      FinalQuantity           := SourcePosition_tuple.DCD_QUANTITY;
      BasisQuantitySU         := SourcePosition_tuple.DCD_QUANTITY_SU;
      IntermediateQuantitySU  := SourcePosition_tuple.DCD_QUANTITY_SU;
      FinalQuantitySU         := SourcePosition_tuple.DCD_QUANTITY_SU;
    end if;

    -- Initialisation de la Qté valeur
    if GestValueQuantity = 1 then
      select decode(sign(BasisQuantity)
                  , -1, greatest(BasisQuantity, SourcePosition_tuple.POS_BALANCE_QTY_VALUE)
                  , least(BasisQuantity, SourcePosition_tuple.POS_BALANCE_QTY_VALUE)
                   )
        into valueQuantity
        from dual;
    else
      valueQuantity  := BasisQuantity;
    end if;

    -- Recherche de la date de livraison
    -- si le transfert du taux de TVA est activé
    if GaugeReceipt_tuple.GAR_TRANSFERT_VAT_RATE = 1 then
      -- Recherche de la date de livraison de la position source
      DeliveryDate  := SourcePosition_tuple.POS_DATE_DELIVERY;

      if DeliveryDate is null then
        -- Si nulle, recherche de la date de livraison du document source
        -- ou de la date valeur du document source
        select nvl(DMT.DMT_DATE_DELIVERY, DMT.DMT_DATE_VALUE)
          into DeliveryDate
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = SourcePosition_tuple.DOC_DOCUMENT_ID;
      end if;
    end if;

    -- Recherche des prix si on a pas le transfert des prix dans le flux
    if GaugeReceipt_tuple.GAR_TRANSFERT_PRICE = 1 then
      PosNetTariff           := SourcePosition_tuple.POS_NET_TARIFF;
      PosSpecialTariff       := SourcePosition_tuple.POS_SPECIAL_TARIFF;
      PosFlatRate            := SourcePosition_tuple.POS_FLAT_RATE;
      vDicTariffID           := SourcePosition_tuple.DIC_TARIFF_ID;
      vEffectiveDicTariffID  := SourcePosition_tuple.POS_EFFECTIVE_DIC_TARIFF_ID;
      PosUpdateTariff        := SourcePosition_tuple.POS_UPDATE_TARIFF;
      PosTariffUnit          := SourcePosition_tuple.POS_TARIFF_UNIT;
      PosTariffInitialized   := SourcePosition_tuple.POS_TARIFF_INITIALIZED;
      DiscountRate           := nvl(SourcePosition_tuple.POS_DISCOUNT_RATE, 0);

      if     SourcePosition_tuple.C_GAUGE_TYPE_POS in('1', '7', '10', '81', '91')
         and PAC_FUNCTIONS.IsTariffBySet(nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID), TargetAdminDomain) = 1 then
        PosTariffSet  := SourcePosition_tuple.POS_TARIFF_SET;
      end if;

      if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = SourceCurrencyId then
        if SourcePosition_tuple.POS_CONVERT_FACTOR = vPriceConvertFactor then
          RefUnitValue  := SourcePosition_tuple.POS_REF_UNIT_VALUE;
        else
          RefUnitValue  := SourcePosition_tuple.POS_REF_UNIT_VALUE * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR;
        end if;
      else
        if SourcePosition_tuple.POS_CONVERT_FACTOR = vPriceConvertFactor then
          RefUnitValue  :=
            ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_REF_UNIT_VALUE
                                            , SourceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   -- Cours logistique
        else
          RefUnitValue  :=
            ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_REF_UNIT_VALUE * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR
                                            , SourceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   -- Cours logistique
        end if;
      end if;

      if IncludeTaxTariff = 1 then   -- TTC
        GrossUnitValue     := 0;
        GrossUnitValue2    := 0;

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = SourceCurrencyId then
          if SourcePosition_tuple.POS_CONVERT_FACTOR = vPriceConvertFactor then
            GrossUnitValueIncl  := SourcePosition_tuple.POS_GROSS_UNIT_VALUE_INCL;
          else
            GrossUnitValueIncl  := SourcePosition_tuple.POS_GROSS_UNIT_VALUE_INCL * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR;
          end if;
        else
          if SourcePosition_tuple.POS_CONVERT_FACTOR = vPriceConvertFactor then
            GrossUnitValueIncl  :=
              ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE_INCL
                                              , SourceCurrencyId
                                              , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                              , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                              , TargetDocument_tuple.DMT_BASE_PRICE
                                              , 0
                                              , 5
                                               );   -- Cours logistique
          else
            GrossUnitValueIncl  :=
              ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE_INCL * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR
                                              , SourceCurrencyId
                                              , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                              , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                              , TargetDocument_tuple.DMT_BASE_PRICE
                                              , 0
                                              , 5
                                               );   -- Cours logistique
          end if;
        end if;

        -- Demande d'inversion du montant unitaire de la position.
        if GaugeReceipt_tuple.GAR_INVERT_AMOUNT = 1 then
          GrossUnitValueIncl  := -GrossUnitValueIncl;
        end if;

        DiscountUnitValue  := GrossUnitValueIncl * DiscountRate / 100;
        GrossValue         := 0;

        if SourcePosition_tuple.DCD_FORCE_AMOUNT = 1 then
          if GaugeReceipt_tuple.GAR_INVERT_AMOUNT = 1 then
            GrossValueIncl  := -SourcePosition_tuple.POS_GROSS_VALUE;
          else
            GrossValueIncl  := SourcePosition_tuple.POS_GROSS_VALUE;
          end if;
        else
          GrossValueIncl  := valueQuantity *(GrossUnitValueIncl - DiscountUnitValue);
        end if;

        NetValueIncl       := GrossValueIncl;
        ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                 , aRefDate          => nvl(DeliveryDate, nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE) )
                                 , aIncludedVat      => 'I'
                                 , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                       , '0') )
                                 , aNetAmountExcl    => NetValueExcl
                                 , aNetAmountIncl    => NetValueIncl
                                 , aLiabledRate      => VatLiabledRate
                                 , aLiabledAmount    => VatLiabledAmount
                                 , aTaxeRate         => VatRate
                                 , aVatTotalAmount   => VatTotalAmount
                                 , aDeductibleRate   => VatDeductibleRate
                                 , aVatAmount        => VatAmount
                                  );

        if BasisQuantity <> 0 then
          NetUnitValue  := NetValueExcl / BasisQuantity;
        else
          NetUnitValue  := NetValueExcl;
        end if;
      else   -- HT
        GrossUnitValueIncl  := 0;

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = SourceCurrencyId then
          if SourcePosition_tuple.POS_CONVERT_FACTOR = vPriceConvertFactor then
            GrossUnitValue   := SourcePosition_tuple.POS_GROSS_UNIT_VALUE;
            GrossUnitValue2  := SourcePosition_tuple.POS_GROSS_UNIT_VALUE2;
          else
            GrossUnitValue   := SourcePosition_tuple.POS_GROSS_UNIT_VALUE * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR;
            GrossUnitValue2  := SourcePosition_tuple.POS_GROSS_UNIT_VALUE2 * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR;
          end if;
        else
          if SourcePosition_tuple.POS_CONVERT_FACTOR = vPriceConvertFactor then
            GrossUnitValue   :=
              ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE
                                              , SourceCurrencyId
                                              , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                              , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                              , TargetDocument_tuple.DMT_BASE_PRICE
                                              , 0
                                              , 5
                                               );   -- Cours logistique
            GrossUnitValue2  :=
              ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE2
                                              , SourceCurrencyId
                                              , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                              , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                              , TargetDocument_tuple.DMT_BASE_PRICE
                                              , 0
                                              , 5
                                               );   -- Cours logistique
          else
            GrossUnitValue   :=
              ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR
                                              , SourceCurrencyId
                                              , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                              , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                              , TargetDocument_tuple.DMT_BASE_PRICE
                                              , 0
                                              , 5
                                               );   -- Cours logistique
            GrossUnitValue2  :=
              ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE2 * vPriceConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR
                                              , SourceCurrencyId
                                              , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                              , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                              , TargetDocument_tuple.DMT_BASE_PRICE
                                              , 0
                                              , 5
                                               );   -- Cours logistique
          end if;
        end if;

        -- Demande d'inversion du montant unitaire de la position.
        if GaugeReceipt_tuple.GAR_INVERT_AMOUNT = 1 then
          GrossUnitValue  := -GrossUnitValue;
        end if;

        DiscountUnitValue   := GrossUnitValue * DiscountRate / 100;

        if SourcePosition_tuple.DCD_FORCE_AMOUNT = 1 then
          if GaugeReceipt_tuple.GAR_INVERT_AMOUNT = 1 then
            GrossValue  := -SourcePosition_tuple.POS_NET_VALUE_EXCL;
          else
            GrossValue  := SourcePosition_tuple.POS_NET_VALUE_EXCL;
          end if;
        else
          GrossValue  := valueQuantity *(GrossUnitValue - DiscountUnitValue);
        end if;

        GrossValueIncl      := 0;
        NetValueExcl        := GrossValue;

        if BasisQuantity <> 0 then
          NetUnitValue  := NetValueExcl / BasisQuantity;
        else
          NetUnitValue  := NetValueExcl;
        end if;

        ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                 , aRefDate          => nvl(DeliveryDate, nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE) )
                                 , aIncludedVat      => 'E'
                                 , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                       , '0') )
                                 , aNetAmountExcl    => NetValueExcl
                                 , aNetAmountIncl    => NetValueIncl
                                 , aLiabledRate      => VatLiabledRate
                                 , aLiabledAmount    => VatLiabledAmount
                                 , aTaxeRate         => VatRate
                                 , aVatTotalAmount   => VatTotalAmount
                                 , aDeductibleRate   => VatDeductibleRate
                                 , aVatAmount        => VatAmount
                                  );
      end if;

      -- Montants budget uniquement en décharge si la config est activée et que la valeur unitaire ne change pas
      if     (PCS.PC_CONFIG.GetConfig('DOC_ENABLE_BUDGET') = '1')
         and (IncludeBudgetControl = 1)
         and (NetUnitValue = SourcePosition_tuple.POS_NET_UNIT_VALUE)
         and (TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = SourceCurrencyId) then
        -- Reprise proportionnelle des montants
        if SourcePosition_tuple.POS_BASIS_QUANTITY = 0 then
          CalcBudgetAmount    := SourcePosition_tuple.POS_CALC_BUDGET_AMOUNT_MB;
          EffectBudgetAmount  := SourcePosition_tuple.POS_EFFECT_BUDGET_AMOUNT_MB;
        else
          CalcBudgetAmount    := SourcePosition_tuple.POS_CALC_BUDGET_AMOUNT_MB / SourcePosition_tuple.POS_BASIS_QUANTITY * BasisQuantity;
          EffectBudgetAmount  := SourcePosition_tuple.POS_EFFECT_BUDGET_AMOUNT_MB / SourcePosition_tuple.POS_BASIS_QUANTITY * BasisQuantity;
        end if;
      end if;

      -- Si la config budget est activée et qu'un montant budget effectif a été défini manuellement
      if     (PCS.PC_CONFIG.GetConfig('DOC_ENABLE_BUDGET') = '1')
         and (IncludeBudgetControl = 1)
         and (SourcePosition_tuple.POS_CALC_BUDGET_AMOUNT_MB <> SourcePosition_tuple.POS_EFFECT_BUDGET_AMOUNT_MB) then
        -- on garde le montant budget effectif défini manuellement
        EffectBudgetAmount  := SourcePosition_tuple.POS_EFFECT_BUDGET_AMOUNT_MB;
      end if;
    -- pas de transfert du prix
    else
      PriceCurrencyId        := TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID;
      DiscountRate           := 0;
      DiscountUnitValue      := 0;

      if     GapForcedTariff = 0
         and GaugeInitPricePos in('1', '2') then
        select nvl(TargetDocument_tuple.DIC_TARIFF_ID, vDicTariffId)
          into vDicTariffId
          from dual;
      end if;

      if     SourcePosition_tuple.C_GAUGE_TYPE_POS in('1', '7', '10', '81', '91')
         and PAC_FUNCTIONS.IsTariffBySet(nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID), TargetAdminDomain) = 1 then
        if TargetAdminDomain = '1' then
          select DIC_TARIFF_SET_PURCHASE_ID
            into PosTariffSet
            from GCO_GOOD
           where GCO_GOOD_ID = SourcePosition_tuple.GCO_GOOD_ID;
        else
          select DIC_TARIFF_SET_SALE_ID
            into PosTariffSet
            from GCO_GOOD
           where GCO_GOOD_ID = SourcePosition_tuple.GCO_GOOD_ID;
        end if;
      end if;

      vEffectiveDicTariffId  := vDicTariffId;

      if IncludeTaxTariff = 1 then   -- TTC
        GrossUnitValueIncl  :=
          nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => SourcePosition_tuple.GCO_GOOD_ID
                                         , iTypePrice           => GaugeInitPricePos
                                         , iThirdId             => nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                         , iRecordId            => TargetDocument_tuple.DOC_RECORD_ID
                                         , iFalScheduleStepId   => null
                                         , ioDicTariff          => vEffectiveDicTariffId
                                         , iQuantity            => FinalQuantity
                                         , iDateRef             => nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                         , ioRoundType          => roundtype
                                         , ioRoundAmount        => roundAmount
                                         , ioCurrencyId         => PriceCurrencyId
                                         , oNet                 => PosNetTariff
                                         , oSpecial             => PosSpecialTariff
                                         , oFlatRate            => PosFlatRate
                                         , oTariffUnit          => PosTariffUnit
                                         , iDicTariff2          => TargetDocument_tuple.DIC_TARIFF_ID
                                          ) *
              ConvertFactor
            , 0
             );

        -- Demande d'inversion du montant unitaire de la position.
        if GaugeReceipt_tuple.GAR_INVERT_AMOUNT = 1 then
          GrossUnitValueIncl  := -GrossUnitValueIncl;
        end if;

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID <> PriceCurrencyId then
          GrossUnitValueIncl  :=
            ACS_FUNCTION.ConvertAmountForView(GrossUnitValueIncl
                                            , PriceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   -- Cours logistique
        end if;

        ----
        -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT).
        -- En principe c'est une position de type '81' mais dans le cas des positions non liées, cela peut être une position
        -- de type '1'.
        --
        lvGaugeTypePosPT    := null;

        -- Détermine le type de position du composé par le composant courant
        if SourcePosition_tuple.DOC_DOC_POSITION_ID is not null then
          select POS.C_GAUGE_TYPE_POS
            into lvGaugeTypePosPT
            from DOC_POSITION POS
           where POS.DOC_POSITION_ID = SourcePosition_tuple.DOC_DOC_POSITION_ID;
        end if;

        if (nvl(lvGaugeTypePosPT, '0') = '8') then
          ----
          -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT)
          --
          GrossUnitValue2     := GrossUnitValueIncl;
          GrossUnitValue      := 0;
          GrossUnitValueIncl  := 0;
          NetUnitValue        := 0;
          NetUnitValueIncl    := 0;
          DiscountUnitValue   := 0;
          GrossValue          := 0;
          GrossValueIncl      := 0;
          NetValueIncl        := 0;
          NetValueExcl        := 0;
          VatAmount           := 0;
        else
          GrossValue      := 0;
          GrossValueIncl  := valueQuantity * GrossUnitValueIncl;
          NetValueIncl    := GrossValueIncl;
          ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                   , aRefDate          => nvl(DeliveryDate, nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE) )
                                   , aIncludedVat      => 'I'
                                   , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                         , '0') )
                                   , aNetAmountExcl    => NetValueExcl
                                   , aNetAmountIncl    => NetValueIncl
                                   , aLiabledRate      => VatLiabledRate
                                   , aLiabledAmount    => VatLiabledAmount
                                   , aTaxeRate         => VatRate
                                   , aVatTotalAmount   => VatTotalAmount
                                   , aDeductibleRate   => VatDeductibleRate
                                   , aVatAmount        => VatAmount
                                    );

          if BasisQuantity <> 0 then
            NetUnitValue  := NetValueExcl / BasisQuantity;
          else
            NetUnitValue  := NetValueExcl;
          end if;

          if GaugeInitPricePos in('1', '2') then
            PosTariffInitialized  := GrossUnitValueIncl;
          end if;
        end if;
      else   -- HT
        GrossUnitValue    :=
          nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => SourcePosition_tuple.GCO_GOOD_ID
                                         , iTypePrice           => GaugeInitPricePos
                                         , iThirdId             => nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                         , iRecordId            => TargetDocument_tuple.DOC_RECORD_ID
                                         , iFalScheduleStepId   => null
                                         , ioDicTariff          => vEffectiveDicTariffId
                                         , iQuantity            => FinalQuantity
                                         , iDateRef             => nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                         , ioRoundType          => roundtype
                                         , ioRoundAmount        => roundAmount
                                         , ioCurrencyId         => PriceCurrencyId
                                         , oNet                 => PosNetTariff
                                         , oSpecial             => PosSpecialTariff
                                         , oFlatRate            => PosFlatRate
                                         , oTariffUnit          => PosTariffUnit
                                         , iDicTariff2          => TargetDocument_tuple.DIC_TARIFF_ID
                                          ) *
              ConvertFactor
            , 0
             );

        -- Demande d'inversion du montant unitaire de la position.
        if GaugeReceipt_tuple.GAR_INVERT_AMOUNT = 1 then
          GrossUnitValue  := -GrossUnitValue;
        end if;

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID <> PriceCurrencyId then
          GrossUnitValue  :=
            ACS_FUNCTION.ConvertAmountForView(GrossUnitValue
                                            , PriceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   -- Cours logistique
        end if;

        ----
        -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT).
        -- En principe c'est une position de type '81' mais dans le cas des positions non liées, cela peut être une position
        -- de type '1'.
        --
        lvGaugeTypePosPT  := null;

        -- Détermine le type de position du composé par le composant courant
        if SourcePosition_tuple.DOC_DOC_POSITION_ID is not null then
          select POS.C_GAUGE_TYPE_POS
            into lvGaugeTypePosPT
            from DOC_POSITION POS
           where POS.DOC_POSITION_ID = SourcePosition_tuple.DOC_DOC_POSITION_ID;
        end if;

        if (nvl(lvGaugeTypePosPT, '0') = '8') then
          ----
          -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT)
          --
          GrossUnitValue2     := GrossUnitValue;
          GrossUnitValue      := 0;
          GrossUnitValueIncl  := 0;
          NetUnitValue        := 0;
          NetUnitValueIncl    := 0;
          DiscountUnitValue   := 0;
          GrossValue          := 0;
          GrossValueIncl      := 0;
          NetValueIncl        := 0;
          NetValueExcl        := 0;
          VatAmount           := 0;
        else
          GrossUnitValue2  := GrossUnitValue;
          GrossValue       := valueQuantity * GrossUnitValue;
          GrossValueIncl   := 0;
          NetValueExcl     := GrossValue;

          if BasisQuantity <> 0 then
            NetUnitValue  := NetValueExcl / BasisQuantity;
          else
            NetUnitValue  := NetValueExcl;
          end if;

          ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                   , aRefDate          => nvl(DeliveryDate, nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE) )
                                   , aIncludedVat      => 'E'
                                   , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                         , '0') )
                                   , aNetAmountExcl    => NetValueExcl
                                   , aNetAmountIncl    => NetValueIncl
                                   , aLiabledRate      => VatLiabledRate
                                   , aLiabledAmount    => VatLiabledAmount
                                   , aTaxeRate         => VatRate
                                   , aVatTotalAmount   => VatTotalAmount
                                   , aDeductibleRate   => VatDeductibleRate
                                   , aVatAmount        => VatAmount
                                    );

          if GaugeInitPricePos in('1', '2') then
            PosTariffInitialized  := GrossUnitValue;
          end if;
        end if;
      end if;

      if GaugeInitPricePos in('1', '2') then
        PosUpdateTariff  := 0;
      end if;
    end if;

    -- Valeur unitaire nette. Modification temporaire en attente de l'intégration
    -- de la quantité valeur.
    if (BasisQuantity <> 0) then
      NetUnitValueIncl  := NetValueIncl / BasisQuantity;
    end if;

    -- initialisation du prix de revient unitaire
    -- si le domaine gabarit n'a pas changé
    if TargetAdminDomain = SourceAdminDomain then
      if GaugeReceipt_tuple.GAR_INIT_COST_PRICE = 1 then
        UnitCostPrice  := SourcePosition_tuple.pos_unit_cost_price * ConvertFactor / SourcePosition_tuple.POS_CONVERT_FACTOR;
      else
        UnitCostPrice  :=
          nvl(GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(SourcePosition_tuple.GCO_GOOD_ID
                                                           , nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                                            )
            , 0
             );
      end if;
    else
      if GaugeReceipt_tuple.GAR_INIT_COST_PRICE = 1 then
        select decode(SourcePosition_tuple.POS_FINAL_QUANTITY, 0, 0, SourcePosition_tuple.POS_GROSS_VALUE_B / SourcePosition_tuple.POS_FINAL_QUANTITY) *
               ConvertFactor /
               SourcePosition_tuple.POS_CONVERT_FACTOR
          into UnitCostPrice
          from dual;
      else
        UnitCostPrice  :=
          nvl(GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(SourcePosition_tuple.GCO_GOOD_ID
                                                           , nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                                            )
            , 0
             );
      end if;
    end if;

    -- Initialisation des poids.

    /* Reprise des poids */
    /* Seulement si le flag de gestion des poids est activé et que la quantité déchargée est différente de 0 */
    if     gapWeight = 1
       and BasisQuantity <> 0 then
      /* position Kit et assemblage */
      if SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        -- Cumul du poids des composants
        select sum(POS_GROSS_WEIGHT)
             , sum(POS_NET_WEIGHT)
          into grossWeight
             , netWeight
          from DOC_POSITION
         where DOC_DOC_POSITION_ID = aSourcePositionId;
      else
        grossWeight  := SourcePosition_tuple.POS_GROSS_WEIGHT;
        netWeight    := SourcePosition_tuple.POS_NET_WEIGHT;
      end if;

      -- Règle de trois par rapport à la quantité sélectionnée
      if     SourcePosition_tuple.POS_FINAL_QUANTITY <> 0
         and SourcePosition_tuple.POS_FINAL_QUANTITY <> BasisQuantity then
        grossWeight  := abs( (grossWeight * BasisQuantity) / SourcePosition_tuple.POS_FINAL_QUANTITY);
        netWeight    := abs( (netWeight * BasisQuantity) / SourcePosition_tuple.POS_FINAL_QUANTITY);
      end if;
    end if;

    -- Status de la position
    if SourcePosition_tuple.C_GAUGE_TYPE_POS in('4', '5', '6') then
      PositionStatus  := '04';
    else
      if    ConfirmStatus = 1
         or DOC_LIB_DOCUMENT.IsCreditLimit(aTargetDocumentId) then
        if TargetDocument_tuple.C_DOCUMENT_STATUS in('02', '03') then
          PositionStatus  := '02';
        else
          PositionStatus  := '01';
        end if;
      else
        if BalanceStatus = 1 then
          PositionStatus  := '02';
        else
          PositionStatus  := '04';
        end if;
      end if;
    end if;

    --raise_application_error(-20000,'targetlocation : '||to_char(cdaLocationId)||'/'||to_char(SourcePosition_tuple.stm_location_id));
    if     (AlreadyLoadComplData = 0)
       and (GaugeReceipt_tuple.GAR_TRANSFERT_STOCK = 0) then
      if TargetAdminDomain = '2' then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '2'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   -- aOperationID
                                                , 0   -- aTransProprietor
                                                , null   -- aComplDataID
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      elsif TargetAdminDomain in('1', '5') then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '1'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   -- aOperationID
                                                , 0   -- aTransProprietor
                                                , null   -- aComplDataID
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      end if;
-- NUNO GOMES VIEIRA
--    else
--      cdaStockId     := 0;
--      cdaLocationId  := 0;
    end if;

    TargetStockId                := GapStockId;
    TargetLocationId             := GapLocationId;
    TargetStock2Id               := GapStockId2;
    TargetLocation2Id            := GapLocationId2;
    lnSourceSupplierID           := null;
    lnTargetSupplierID           := null;

    -- Reprise du stock et emplacement de transfert si la position a le stock propriétaire
    -- et qu'il y a la reprise du stock dans le flux
    if     (GaugeReceipt_tuple.gar_transfert_stock = 1)
       and (SourcePosition_tuple.gap_transfert_proprietor = 1) then
      TargetStock2Id     := SourcePosition_tuple.stm_stm_stock_id;   /* Stock cible parent */
      TargetLocation2Id  := SourcePosition_tuple.stm_stm_location_id;   /* Emplacement cible parent */
    elsif(lnGapSubcontractStock = 1) then   -- Demande d'initialisation du stock source avec le stock du sous-traitant
      lnSourceSupplierID  := TargetDocument_tuple.PAC_THIRD_CDA_ID;
    elsif(lnGapStmSubcontractStock = 1) then   -- Demande d'initialisation du stock cible avec le stock du sous-traitant
      lnTargetSupplierID  := TargetDocument_tuple.PAC_THIRD_CDA_ID;
    end if;

    DOC_LIB_POSITION.getStockAndLocation(SourcePosition_tuple.GCO_GOOD_ID   /* Bien */
                                       , TargetDocument_tuple.PAC_THIRD_ID
                                       , TargetMovementKindId   /* Genre de mouvement */
                                       , TargetAdminDomain
                                       , cdaStockId   /* Stock du bien (données complémentaires) */
                                       , cdaLocationId   /* Emplacement du bien (données complémentaires) */
                                       , SourcePosition_tuple.stm_stock_id   /* Stock parent */
                                       , SourcePosition_tuple.stm_location_id   /* Emplacement parent */
                                       , SourcePosition_tuple.stm_stm_stock_id   /* Stock cible parent */
                                       , SourcePosition_tuple.stm_stm_location_id   /* Emplacement cible parent */
                                       , InitStockAndLocation   /* Initialisation du stock et de l'emplacement */
                                       , InitMovement   /* Utilisation du stock du genre de mouvement */
                                       , GaugeReceipt_tuple.gar_transfert_stock   /* Transfert stock et emplacement depuis le parent */
                                       , lnSourceSupplierID   /* Sous-traitant permettant l'initialisation du stock source */
                                       , lnTargetSupplierID   /* Sous-traitant permettant l'initialisation du stock cible */
                                       , TargetStockId   /* Stock recherché */
                                       , TargetLocationId   /* Emplacement recherché */
                                       , TargetStock2Id   /* Stock cible recherché */
                                       , TargetLocation2Id   /* Emplacement cible recherché */
                                        );

    ---
    -- Définit les mêmes stock et emplacement source et cible dans le cas des
    -- positions Assemblage pour autant que le mouvement lié à la position
    -- soit de type transfert.
    --
    if     SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8')
       and TargetMovementKindId is not null
       and GapStockId2 is null then
      -- Recherche le mouvement lié au mouvement de la position
      select STM_STM_MOVEMENT_KIND_ID
        into LinkMovementKindID
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = TargetMovementKindId;

      if LinkMovementKindID is not null then
        TargetStock2Id     := TargetStockId;
        TargetLocation2Id  := TargetLocationId;
      end if;
    end if;

    -- recherche du coef d'utilisation des composants
    if SourcePosition_tuple.DOC_DOC_POSITION_ID is not null then
      UtilCoef  := SourcePosition_tuple.POS_UTIL_COEFF;
    end if;

    -- recherche des données complémentaires obligatoires ou interdites
    DOC_INFO_COMPL.GetUsedInfoCompl(aTargetDocumentId
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

    ----
    -- Définission du flag de création des poids matières précieuses
    --
    if (gasWeightMat = 1) then
      posCreateMat  := 1;   -- Matières à créer
    else
      posCreateMat  := 0;   -- Matières pas gérées
    end if;

    -- recherche de la valeur de la nouvelle position
    select init_id_seq.nextval
      into aTargetPositionId
      from dual;

    insert into DOC_POSITION
                (DOC_POSITION_ID
               , DOC_DOCUMENT_ID
               , DOC_DOC_POSITION_ID
               , PAC_REPRESENTATIVE_ID
               , PAC_REPR_ACI_ID
               , PAC_REPR_DELIVERY_ID
               , C_GAUGE_TYPE_POS
               , C_DOC_POS_STATUS
               , GCO_GOOD_ID
               , DOC_GAUGE_POSITION_ID
               , DOC_RECORD_ID
               , DOC_DOC_RECORD_ID
               , PAC_PERSON_ID
               , ASA_RECORD_ID
               , ASA_RECORD_COMP_ID
               , ASA_RECORD_TASK_ID
               , STM_STOCK_ID
               , STM_STM_STOCK_ID
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , STM_MOVEMENT_KIND_ID
               , ACS_TAX_CODE_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , DOC_INVOICE_EXPIRY_ID
               , POS_NUMBER
               , POS_GENERATE_MOVEMENT
               , POS_STOCK_OUTAGE
               , POS_REFERENCE
               , POS_SECONDARY_REFERENCE
               , POS_SHORT_DESCRIPTION
               , POS_LONG_DESCRIPTION
               , POS_FREE_DESCRIPTION
               , POS_BODY_TEXT
               , POS_NOM_TEXT
               , DIC_UNIT_OF_MEASURE_ID
               , DIC_DIC_UNIT_OF_MEASURE_ID
               , POS_EAN_CODE
               , POS_EAN_UCC14_CODE
               , POS_HIBC_PRIMARY_CODE
               , POS_CONVERT_FACTOR
               , POS_CONVERT_FACTOR2
               , POS_NET_WEIGHT
               , POS_GROSS_WEIGHT
               , POS_BASIS_QUANTITY
               , POS_INTERMEDIATE_QUANTITY
               , POS_FINAL_QUANTITY
               , POS_VALUE_QUANTITY
               , POS_BALANCE_QUANTITY
               , POS_BALANCE_QTY_VALUE
               , POS_BASIS_QUANTITY_SU
               , POS_INTERMEDIATE_QUANTITY_SU
               , POS_FINAL_QUANTITY_SU
               , POS_INCLUDE_TAX_TARIFF
               , POS_REF_UNIT_VALUE
               , POS_UNIT_COST_PRICE
               , POS_GROSS_UNIT_VALUE
               , POS_GROSS_UNIT_VALUE2
               , POS_GROSS_UNIT_VALUE_INCL
               , POS_GROSS_VALUE
               , POS_GROSS_VALUE_INCL
               , POS_NET_UNIT_VALUE
               , POS_NET_UNIT_VALUE_INCL
               , POS_NET_VALUE_EXCL
               , POS_NET_VALUE_INCL
               , POS_CALC_BUDGET_AMOUNT_MB
               , POS_EFFECT_BUDGET_AMOUNT_MB
               , POS_DATE_DELIVERY
               , POS_VAT_RATE
               , POS_VAT_LIABLED_RATE
               , POS_VAT_LIABLED_AMOUNT
               , POS_VAT_TOTAL_AMOUNT
               , POS_VAT_DEDUCTIBLE_RATE
               , POS_VAT_AMOUNT
               , POS_NET_TARIFF
               , POS_SPECIAL_TARIFF
               , POS_FLAT_RATE
               , DIC_TARIFF_ID
               , POS_EFFECTIVE_DIC_TARIFF_ID
               , POS_TARIFF_UNIT
               , POS_TARIFF_SET
               , POS_TARIFF_INITIALIZED
               , POS_UPDATE_TARIFF
               , POS_MODIFY_RATE
               , PC_APPLTXT_ID
               , POS_DISCOUNT_UNIT_VALUE
               , POS_DISCOUNT_RATE
               , POS_UTIL_COEFF
               , POS_PARENT_CHARGE
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
               , POS_PARTNER_NUMBER
               , POS_PARTNER_REFERENCE
               , POS_DATE_PARTNER_DOCUMENT
               , POS_PARTNER_POS_NUMBER
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
               , POS_IMF_DATE_1
               , POS_IMF_DATE_2
               , POS_IMF_DATE_3
               , POS_IMF_DATE_4
               , POS_IMF_DATE_5
               , POS_CREATE_MAT
               , POS_PRICE_TRANSFERED
               , POS_TARIFF_DATE
               , C_POS_CREATE_MODE
               , C_DOC_LOT_TYPE
               , FAL_LOT_ID
               , GCO_MANUFACTURED_GOOD_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (aTargetPositionId   -- DOC_POSITION_ID
               , aTargetDocumentId   -- DOC_DOCUMENT_ID
               , aPdtTargetPositionId   -- DOC_DOC_POSITION_ID
               , decode(GaugeReceipt_tuple.gar_transfert_represent
                      , 0, TargetDocument_tuple.PAC_REPRESENTATIVE_ID
                      , nvl(SourcePosition_tuple.PAC_REPRESENTATIVE_ID, TargetDocument_tuple.PAC_REPRESENTATIVE_ID)
                       )   -- PAC_REPRESENTATIVE_ID
               , decode(GaugeReceipt_tuple.gar_transfert_represent
                      , 0, TargetDocument_tuple.PAC_REPR_ACI_ID
                      , nvl(SourcePosition_tuple.PAC_REPR_ACI_ID, TargetDocument_tuple.PAC_REPR_ACI_ID)
                       )   -- PAC_REPR_ACI_ID
               , decode(GaugeReceipt_tuple.gar_transfert_represent
                      , 0, TargetDocument_tuple.PAC_REPR_DELIVERY_ID
                      , nvl(SourcePosition_tuple.PAC_REPR_DELIVERY_ID, TargetDocument_tuple.PAC_REPR_DELIVERY_ID)
                       )   -- PAC_REPR_DELIVERY_ID
               , SourcePosition_tuple.c_gauge_type_pos   -- C_GAUGE_TYPE_POS
               , PositionStatus   -- C_DOC_POS_STATUS
               , SourcePosition_tuple.GCO_GOOD_ID   -- GCO_GOOD_ID
               , TargetGaugePositionId   -- DOC_GAUGE_POSITION_ID
               , TargetRecordId   -- DOC_RECORD_ID
               , TargetDocDocRecordId   -- DOC_DOC_RECORD_ID
               , TargetPersonId   -- PAC_PERSON_ID
               , SourcePosition_tuple.ASA_RECORD_ID   -- ASA_RECORD_ID
               , SourcePosition_tuple.ASA_RECORD_COMP_ID
               , SourcePosition_tuple.ASA_RECORD_TASK_ID
               , TargetStockId   -- STM_STOCK_ID
               , TargetStock2Id   -- STM_STM_STOCK_ID
               , TargetLocationId   -- STM_LOCATION_ID
               , TargetLocation2Id   -- STM_STM_LOCATION_ID
               , TargetMovementKindId   -- STM_MOVEMENT_KIND_ID
               , TargetTaxCodeId   -- ACS_TAX_CODE_ID
               , TargetFinAccountId   -- ACS_FINANCIAL_ACCOUNT_ID
               , TargetDivAccountId   -- ACS_DIVISION_ACCOUNT_ID
               , TargetCpnAccountId   -- ACS_CPN_ACCOUNT_ID
               , TargetCdaAccountId   -- ACS_CDA_ACCOUNT_ID
               , TargetPfAccountId   -- ACS_PF_ACCOUNT_ID
               , TargetPjAccountId   -- ACS_PJ_ACCOUNT_ID
               , SourcePosition_tuple.DOC_INVOICE_EXPIRY_ID
               , GetNextPosNumber(PosFirstNo, PosIncrement)   -- POS_NUMBER
               , 0   -- POS_GENERATE_MOVEMENT
               , 0   -- POS_STOCK_OUTAGE
               , reference   -- POS_REFERENCE
               , SecondaryReference   -- POS_SECONDARY_REFERENCE
               , ShortDescription   -- POS_SHORT_DESCRIPTION
               , LongDescription   -- POS_LONG_DESCRIPTION
               , FreeDescription   -- POS_FREE_DESCRIPTION
               , BodyText   -- POS_BODY_TEXT
               , 0   -- POS_NOM_TEXT
               , DicUnitOfMeasureId   -- DIC_UNIT_OF_MEASURE_ID
               , DicDicUnitOfMeasureId   -- DIC_DIC_UNIT_OF_MEASURE_ID
               , EanCode   -- POS_EAN_CODE
               , EanUCC14Code   -- POS_EAN_UCC14_CODE
               , HIBCPrimaryCode   -- POS_HIBC_PRIMARY_CODE
               , nvl(ConvertFactor, 1)   -- POS_CONVERT_FACTOR
               , nvl(ConvertFactor2, 1)   -- POS_CONVERT_FACTOR2
               , NetWeight   -- POS_NET_WEIGHT
               , GrossWeight   -- POS_GROSS_WEIGHT
               , BasisQuantity   -- POS_BASIS_QUANTITY
               , IntermediateQuantity   -- POS_INTERMEDIATE_QUANTITY
               , FinalQuantity   -- POS_FINAL_QUANTITY
               , valueQuantity   -- POS_VALUE_QUANTITY
               , decode(BalanceStatus, 1, BasisQuantity, 0)   -- POS_BALANCE_QUANTITY
               , decode(BalanceStatus, 1, valueQuantity, 0)   -- POS_BALANCE_QTY_VALUE
               , BasisQuantitySU   -- POS_BASIS_QUANTITY_SU
               , IntermediateQuantitySU   -- POS_INTERMEDIATE_QUANTITY_SU
               , FinalQuantitySU   -- POS_FINAL_QUANTITY_SU
               , IncludeTaxTariff   -- POS_INCLUDE_TAX_TARIFF
               , RefUnitValue   -- POS_REF_UNIT_VALUE
               , UnitCostPrice   -- POS_UNIT_COST_PRICE
               , GrossUnitValue   -- POS_GROSS_UNIT_VALUE
               , GrossUnitValue2   -- POS_GROSS_UNIT_VALUE2
               , GrossUnitValueIncl   -- POS_GROSS_UNIT_VALUE_INCL
               , GrossValue   -- POS_GROSS_VALUE
               , GrossValueIncl   -- POS_GROSS_VALUE_INCL
               , NetUnitValue   -- POS_NET_UNIT_VALUE
               , NetUnitValueIncl   -- POS_NET_UNIT_VALUE_INCL
               , NetValueExcl   -- POS_NET_VALUE_EXCL
               , NetValueIncl   -- POS_NET_VALUE_INCL
               , CalcBudgetAmount   --POS_CALC_BUDGET_AMOUNT_MB
               , EffectBudgetAmount   --POS_EFFECT_BUDGET_AMOUNT_MB
               , DeliveryDate   -- POS_DATE_DELIVERY
               , VatRate   -- POS_VAT_RATE
               , VatLiabledRate   -- POS_VAT_LIABLED_RATE
               , VatLiabledAmount   -- POS_VAT_LIABLED_AMOUNT
               , VatTotalAmount   -- POS_VAT_TOTAL_AMOUNT
               , VatDeductibleRate   -- POS_VAT_DEDUCTIBLE_RATE
               , VatAmount   -- POS_VAT_AMOUNT
               , nvl(PosNetTariff, 0)   -- POS_NET_TARIFF
               , nvl(PosSpecialTariff, 0)   -- POS_SPECIAL_TARIFF
               , nvl(PosFlatRate, 0)   -- POS_FLAT_RATE
               , vDicTariffId   -- DIC_TARIFF_ID
               , vEffectiveDicTariffID   -- POS_EFFECTIVE_DIC_TARIFF_ID
               , PosTariffUnit   -- POS_TARIFF_UNIT
               , PosTariffSet   -- POS_TARIFF_SET
               , decode(vDicTariffId, null, 0, decode(IncludeTaxTariff, 1, GrossUnitValueIncl, GrossUnitValue) ) *
                 decode(GaugeReceipt_tuple.GAR_TRANSFERT_PRICE, 1, 1, 0, PosTariffUnit)   -- POS_TARIFF_INITIALIZED
               , PosUpdateTariff   -- POS_UPDATE_TARIFF
               , 1   -- POS_MODIFY_RATE
               , SourcePosition_tuple.PC_APPLTXT_ID   -- PC_APPLTXT_ID
               , DiscountUnitValue   -- POS_DISCOUNT_UNIT_VALUE
               , DiscountRate   -- POS_DISCOUNT_RATE
               , UtilCoef   -- POS_UTIL_COEFF
               , GaugeReceipt_tuple.GAR_TRANSFERT_REMISE_TAXE
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA
                      , 1, SourcePosition_tuple.DIC_POS_FREE_TABLE_1_ID
                      , TargetDocument_tuple.DIC_POS_FREE_TABLE_1_ID
                       )   -- DIC_POS_FREE_TABLE_1_ID
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA
                      , 1, SourcePosition_tuple.DIC_POS_FREE_TABLE_2_ID
                      , TargetDocument_tuple.DIC_POS_FREE_TABLE_2_ID
                       )   -- DIC_POS_FREE_TABLE_2_ID
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA
                      , 1, SourcePosition_tuple.DIC_POS_FREE_TABLE_3_ID
                      , TargetDocument_tuple.DIC_POS_FREE_TABLE_3_ID
                       )   -- DIC_POS_FREE_TABLE_3_ID
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DECIMAL_1, TargetDocument_tuple.DMT_DECIMAL_1)   -- POS_DECIMAL_1
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DECIMAL_2, TargetDocument_tuple.DMT_DECIMAL_2)   -- POS_DECIMAL_2
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DECIMAL_3, TargetDocument_tuple.DMT_DECIMAL_3)   -- POS_DECIMAL_3
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_TEXT_1, TargetDocument_tuple.DMT_TEXT_1)   -- POS_TEXT_1
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_TEXT_2, TargetDocument_tuple.DMT_TEXT_2)   -- POS_TEXT_2
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_TEXT_3, TargetDocument_tuple.DMT_TEXT_3)   -- POS_TEXT_3
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DATE_1, TargetDocument_tuple.DMT_DATE_1)   -- POS_DATE_1
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DATE_2, TargetDocument_tuple.DMT_DATE_2)   -- POS_DATE_2
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DATE_3, TargetDocument_tuple.DMT_DATE_3)   -- POS_DATE_3
               , nvl(SourcePosition_tuple.POS_PARTNER_NUMBER, TargetDocument_tuple.DMT_PARTNER_NUMBER)
               , nvl(SourcePosition_tuple.POS_PARTNER_REFERENCE, TargetDocument_tuple.DMT_PARTNER_REFERENCE)
               , nvl(SourcePosition_tuple.POS_DATE_PARTNER_DOCUMENT, TargetDocument_tuple.DMT_DATE_PARTNER_DOCUMENT)
               , SourcePosition_tuple.POS_PARTNER_POS_NUMBER
               , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
               , vAccountInfo.FAM_FIXED_ASSETS_ID
               , vAccountInfo.C_FAM_TRANSACTION_TYP
               , vAccountInfo.DEF_TEXT1
               , vAccountInfo.DEF_TEXT2
               , vAccountInfo.DEF_TEXT3
               , vAccountInfo.DEF_TEXT4
               , vAccountInfo.DEF_TEXT5
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
               , posCreateMat   -- POS_CREATE_MAT
               , GaugeReceipt_tuple.GAR_TRANSFERT_PRICE
               , decode(GaugeReceipt_tuple.GAR_TRANSFERT_PRICE, 1, SourcePosition_tuple.POS_TARIFF_DATE)
               , SourcePosition_tuple.C_PDE_CREATE_MODE
               , lvCDocLotType
               , case
                   when lvCDocLotType = '001' then SourcePosition_tuple.FAL_LOT_ID
                   else null
                 end
               , SourcePosition_tuple.GCO_MANUFACTURED_GOOD_ID
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    DischargePositionDetail(aSourcePositionId
                          , aTargetPositionId
                          , SourcePosition_tuple.GCO_GOOD_ID
                          , aTargetDocumentId
                          , SourcePosition_tuple.DOC_GAUGE_ID
                          , TargetDocument_tuple.DOC_GAUGE_ID
                          , ConvertFactor
                          , vQtyConvertFactor
                          , SourceCurrencyId
                          , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                          , TargetAdminDomain
                          , GaugeReceipt_tuple.DOC_GAUGE_RECEIPT_ID
                          , TargetDocument_tuple.DMT_DATE_DOCUMENT
                          , SourcePosition_tuple.doc_gauge_flow_id
                          , GaugeReceipt_tuple.GAR_INIT_QTY_MVT
                          , GaugeReceipt_tuple.GAR_INIT_PRICE_MVT
                          , GaugeReceipt_tuple.GAR_TRANSFERT_MOVEMENT_DATE
                          , GaugeReceipt_tuple.GAR_TRANSFERT_STOCK
                          , GaugeReceipt_tuple.GAR_TRANSFERT_QUANTITY
                          , SourceGestDelay
                          , GestDelay
                          , DelayUpdateType
                          , ParentGestChar
                          , GestChar
                          , InitMovement
                          ,   --gap_mvt_utility,
                            UnitCostPrice
                          , NetUnitValue
                          , TargetMovementKindId
                          , SourcePosition_tuple.C_GAUGE_TYPE_POS
                          , TargetStockId
                          , TargetLocationId
                          , TargetLocation2Id
                          , SourcePosition_tuple.DCD_QUANTITY
                          , SourcePosition_tuple.POS_BALANCE_QTY_VALUE
                          , BalanceStatus
                          , SourcePosition_tuple.GOO_NUMBER_OF_DECIMAL
                          , cdaNumberOfDecimal
                          , BalanceQuantityParentSource
                          , aInputIdList
                          , aDischargeInfoCode
                           );

    ----
    -- Traitement des poids matières précieuses
    --
    if     (srcWeightMat = 1)
       and (gasWeightMat = 1)
       and (GaugeReceipt_tuple.GAR_TRANSFERT_PRECIOUS_MAT = 1) then
      DOC_POSITION_ALLOY_FUNCTIONS.CreatePositionMatFromParent(aTargetPositionID, aSourcePositionId, 'DISCHARGE');
    elsif(gasWeightMat = 1) then
      DOC_POSITION_ALLOY_FUNCTIONS.GeneratePositionMat(aTargetPositionId);
    end if;

    -- remise et taxes (seulement pour ceratins types de positions
    if SourcePosition_tuple.C_GAUGE_TYPE_POS not in('4', '5', '71', '81', '9', '101') then
      if     GaugeReceipt_tuple.GAR_TRANSFERT_REMISE_TAXE = 1
         and SourcePosition_tuple.POS_NET_TARIFF = 0 then
        lnLocalCurrency  := ACS_FUNCTION.GetLocalCurrencyId;

        if     (TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID <> SourceCurrencyId)
           and (   TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = lnLocalCurrency
                or SourceCurrencyId = lnLocalCurrency) then
          -- Si changement de monnaie entre le document source et le cible, il faut convertir les remises/taxes en montant fixe de la position père
          -- Attention, uniquement si une des monnaies est la monnaie de base.
          -- Exemple : FF en CHF et ND en EUR ou l'inverse mais pas: FF en EUR et ND en USD.
          lnConvertAmount  := 1;
        else
          -- Dans le cas contraire, les montants fixes des remises/taxes de position sont repris tel quel.
          lnConvertAmount  := 0;
        end if;

        -- copie des remises/taxes du parent
        DOC_DISCOUNT_CHARGE.CopyPositionCharge(aTargetPositionId
                                             , aSourcePositionId
                                             , TargetDocument_tuple.DMT_DATE_DOCUMENT
                                             , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                             , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                             , TargetDocument_tuple.DMT_BASE_PRICE
                                             , 1   -- mettre à jour le montant solde sur taxe parent
                                             , 1   -- copier les opération de sous-traitance
                                             , ChargeCreated
                                             , ChargeAmount
                                             , DiscountAmount
                                             , lnConvertAmount
                                              );
      else
        -- création des remises/taxes depuis la base
        DOC_DISCOUNT_CHARGE.CreatePositionCharge(aTargetPositionId
                                               , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                               , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                               , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                               , TargetDocument_tuple.DMT_BASE_PRICE
                                               , TargetDocument_tuple.PC_LANG_ID
                                               , ChargeCreated
                                               , ChargeAmount
                                               , DiscountAmount
                                                );
      end if;
    end if;

    -- si des remises/taxes ont été créées ou copiées, on recalcul les montants sur le document
    if ChargeCreated = 1 then
      DOC_POSITION_FUNCTIONS.UpdatePosAmountsDiscountCharge(aTargetPositionId
                                                          , nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE)
                                                          , IncludeTaxTariff
                                                          , ChargeAmount
                                                          , DiscountAmount
                                                           );
    end if;

    -- Mise à jour des montants de budget si cela n'a pas déjà été fait
    if     (PCS.PC_CONFIG.GetConfig('DOC_ENABLE_BUDGET') = '1')
       and (CalcBudgetAmount = 0)
       and (IncludeBudgetControl = 1) then
      DOC_BUDGET_FUNCTIONS.UpdatePosBudgetAmounts(aTargetPositionId);
    end if;

    -- Création des éventuelles imputations position
    if     (SourcePosition_tuple.POS_IMPUTATION = 1)
       and (srcRecordImputation = 1)
       and (gasRecordImputation = 1) then
      DOC_IMPUTATION_FUNCTIONS.CopyPositionImputations(aTargetDocumentId, aTargetPositionId, SourcePosition_tuple.DOC_DOCUMENT_ID, aSourcePositionId);
    end if;

    ---
    -- Mise à jour de la position parent (quantité solde, statut)
    --
    DOC_FUNCTIONS.UpdateBalancePosition(aSourcePositionId, SourcePosition_tuple.DCD_QUANTITY, valueQuantity, BalanceQuantityParentSource);

    -- Composants positions kit et assemblage
    if SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
      open ComponentPosition(aSourcePositionId, aTargetDocumentId);

      fetch ComponentPosition
       into ComponentPositionId;

      lbProcessingCPT  := ComponentPosition%found;

      while ComponentPosition%found loop
        DischargePosition(ComponentPositionId
                        , aTargetDocumentId
                        , aSourcePositionId
                        , aTargetPositionId
                        , SourcePosition_tuple.doc_gauge_flow_id
                        , aInputIdList
                        , TargetPositionId
                        , aDischargeInfoCode
                         );

        fetch ComponentPosition
         into ComponentPositionId;
      end loop;

      -- Mise à jour du composé lorsque l'on traite un type de position avec valeur PT égal somme CPT.
      if     (SourcePosition_tuple.C_GAUGE_TYPE_POS = '8')
         and lbProcessingCPT then
        DOC_POSITION_FUNCTIONS.UpdatePositionPTAmounts(aTargetPositionId);
      end if;
    end if;

    -- pas de maj sur les positions composants
    if aPdtSourcePositionId is null then
      DOC_PRC_DOCUMENT.UpdateDocumentStatus(SourcePosition_tuple.DOC_DOCUMENT_ID);
    end if;

    -- Attributions....
    -- Recherche les infos au niveau du gabarit pour les attributions auto.
    select GAU.C_GAUGE_TYPE
         , nvl(GAS.GAS_AUTO_ATTRIBUTION, 0)
      into cGaugeType
         , gasAutoAttrib
      from DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
     where GAU.DOC_GAUGE_ID = TargetDocument_tuple.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;

    -- teste si les conditions sont remplies pour créer automatiquement les attributions
    if     cGaugeType = '1'
       and gasAutoAttrib = 1 then
      -- Vérifie qu'aucune attribution n'existe la position courante avant d'effectuer la création des attributions
      -- automatique. Cela permet de conserver les attributions issues d'un transfert d'attribution.
      select count(*)
        into nbAttribs
        from FAL_NETWORK_LINK FLN
           , FAL_NETWORK_NEED FAN
           , DOC_POSITION_DETAIL PDE
       where FAN.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
         and FLN.FAL_NETWORK_NEED_ID = FAN.FAL_NETWORK_NEED_ID
         and PDE.DOC_POSITION_ID = aTargetPositionId;

      if nbAttribs = 0 then
        -- création des attributions pour la positions créée
        FAL_REDO_ATTRIBS.ReDoAttribsByDocOrPOS(null, aTargetPositionId);
      end if;
    end if;

    -- Copie des pièces jointes
    if GaugeReceipt_tuple.GAR_TRSF_LINKED_FILES = 1 then
      COM_FUNCTIONS.DuplicateImageFiles('DOC_POSITION', aSourcePositionId, aTargetPositionId);
    end if;

    -- Mise à jour du prix unitaire en monnaie de base de l'opération selon le prix unitaire de la position
    FAL_SUIVI_OPERATION.UpdateOperationAmount(iDocPositionId => aTargetPositionId, iDocGaugeReceiptId => GaugeReceipt_tuple.DOC_GAUGE_RECEIPT_ID);

--     if (vGasProvValidatePos is not null) then
--       -- Remarque : Les exceptions ont déjà été traitées dans la méthode ExecuteExternProc
--       DOC_FUNCTIONS.ExecuteExternProc(aTargetPositionId, vGasProvValidatePos, vTmpErrorMsg);
--       if vTmpErrorMsg is not null then
--         rollback to savepoint spDischargePosition;
--       end if;
--     end if;
    close SourcePosition;
  end DischargePosition;

  /**
  * Description
  *        Création des positions du nouveau document en fonction des données dans DOC_POS_DET_COPY_DISCHARGE
  */
  procedure CopyNewDocument(aNewDocumentId in number, aFlowId in number)
  is
    -- curseur sur les positions à copier sur le nouveau document
    cursor positions(aNewDocumentId number)
    is
      select   DOC_POSITION_ID
          from DOC_POS_DET_COPY_DISCHARGE
         where NEW_DOCUMENT_ID = aNewDocumentId
           and CRG_SELECT = 1
      group by DOC_POSITION_ID
      order by min(DOC_POS_DET_COPY_DISCHARGE_ID);

    currentPositionId DOC_POSITION.DOC_POSITION_ID%type;
    InputData         varchar2(32000);
    TargetPositionId  DOC_POSITION.DOC_POSITION_ID%type;
    CopyInfoCode      varchar2(10);
  begin
    open Positions(aNewDocumentId);

    fetch Positions
     into currentPositionId;

    -- pour chaque position à copier sur le nouveau document
    while Positions%found loop
      --appel de la copie de position
      CopyPosition(currentPositionId, aNewDocumentId, null, null, aFlowId, InputData, TargetPositionId, CopyInfoCode);

      fetch Positions
       into currentPositionId;

      commit;
    end loop;

    close Positions;

    -- Création des positions litige, si document final cible des litiges
    DOC_LITIG_FUNCTIONS.GenerateLitigPos(aNewDocumentID);
  end CopyNewDocument;

  /**
  * Description
  *   procedure globale de copie d'une position
  */
  procedure CopyPosition(
    aSourcePositionId    in     number
  , aTargetDocumentId    in     number
  , aPdtSourcePositionId in     number
  , aPdtTargetPositionId in     number
  , aFlowId              in     number
  , aInputIdList         in out varchar2
  , aTargetPositionId    out    number
  , aCopyInfoCode        out    varchar2
  )
  is
    -- curseur sur la position à copier
    cursor SourcePosition(position_id number, NewDocumentId number)
    is
      select   POS.DOC_DOCUMENT_ID
             , DCD.DOC_DOC_POSITION_ID
             , DMT.PAC_THIRD_ID
             , sum(decode(POS.C_GAUGE_TYPE_POS, '5', 1, DCD.DCD_QUANTITY) ) DCD_QUANTITY
             , POS.DOC_RECORD_ID
             , POS.DOC_DOC_RECORD_ID
             , DCD.DOC_GAUGE_FLOW_ID
             , POS.PAC_PERSON_ID
             , DMT.PAC_THIRD_VAT_ID
             , POS.ASA_RECORD_ID
             , POS.ASA_RECORD_COMP_ID
             , POS.ASA_RECORD_TASK_ID
             , POS.DOC_GAUGE_ID
             , POS.DOC_GAUGE_POSITION_ID
             , POS.C_GAUGE_TYPE_POS
             , POS.ACS_FINANCIAL_ACCOUNT_ID
             , POS.ACS_DIVISION_ACCOUNT_ID
             , POS.ACS_CPN_ACCOUNT_ID
             , POS.ACS_CDA_ACCOUNT_ID
             , POS.ACS_PF_ACCOUNT_ID
             , POS.ACS_PJ_ACCOUNT_ID
             , POS.DIC_UNIT_OF_MEASURE_ID
             , GOO.DIC_UNIT_OF_MEASURE_ID GOO_UNIT_OF_MEASURE_ID
             , GOO.GOO_NUMBER_OF_DECIMAL
             , POS.POS_CONVERT_FACTOR
             , DCD.GCO_GOOD_ID
             , POS.GCO_GOOD_ID POS_GOOD_ID
             , DCD.POS_CONVERT_FACTOR GOO_CONVERT_FACTOR
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_NET_TARIFF
             , POS.POS_SPECIAL_TARIFF
             , POS.POS_FLAT_RATE
             , POS.POS_EFFECTIVE_DIC_TARIFF_ID
             , POS.DIC_TARIFF_ID
             , POS.POS_TARIFF_UNIT
             , POS.POS_TARIFF_SET
             , POS.POS_TARIFF_INITIALIZED
             , nvl(POS.POS_TARIFF_DATE, nvl(DMT.DMT_TARIFF_DATE, DMT.DMT_DATE_DOCUMENT) ) POS_TARIFF_DATE
             , POS.POS_UPDATE_TARIFF
             , POS.POS_DISCOUNT_RATE
             , POS.POS_REF_UNIT_VALUE
             , POS.POS_UNIT_COST_PRICE
             , DCD.POS_GROSS_UNIT_VALUE_INCL
             , POS.POS_BALANCE_QTY_VALUE
             , DCD.POS_GROSS_UNIT_VALUE
             , POS.POS_GROSS_UNIT_VALUE2
             , POS.POS_FINAL_QUANTITY
             , POS.POS_BASIS_QUANTITY
             , POS.POS_CALC_BUDGET_AMOUNT_MB
             , POS.POS_EFFECT_BUDGET_AMOUNT_MB
             , POS.POS_VALUE_QUANTITY
             , POS.STM_STOCK_ID
             , POS.STM_STM_STOCK_ID
             , POS.STM_LOCATION_ID
             , POS.STM_STM_LOCATION_ID
             , POS.POS_GROSS_VALUE_B
             , POS.POS_UTIL_COEFF
             , POS.POS_GROSS_WEIGHT
             , POS.POS_NET_WEIGHT
             , POS.PAC_REPRESENTATIVE_ID
             , POS.PAC_REPR_ACI_ID
             , POS.PAC_REPR_DELIVERY_ID
             , POS.POS_REFERENCE
             , POS.POS_SECONDARY_REFERENCE
             , nvl(DCD.POS_SHORT_DESCRIPTION, POS.POS_SHORT_DESCRIPTION) POS_SHORT_DESCRIPTION
             , nvl(DCD.POS_LONG_DESCRIPTION, POS.POS_LONG_DESCRIPTION) POS_LONG_DESCRIPTION
             , POS.POS_FREE_DESCRIPTION
             , POS.POS_BODY_TEXT
             , POS.POS_EAN_CODE
             , POS.POS_EAN_UCC14_CODE
             , POS.POS_HIBC_PRIMARY_CODE
             , POS.POS_CONVERT_FACTOR2
             , POS.DIC_POS_FREE_TABLE_1_ID
             , POS.DIC_POS_FREE_TABLE_2_ID
             , POS.DIC_POS_FREE_TABLE_3_ID
             , POS.POS_DECIMAL_1
             , POS.POS_DECIMAL_2
             , POS.POS_DECIMAL_3
             , POS.POS_TEXT_1
             , POS.POS_TEXT_2
             , POS.POS_TEXT_3
             , POS.POS_DATE_1
             , POS.POS_DATE_2
             , POS.POS_DATE_3
             , POS.POS_PARTNER_NUMBER
             , POS.POS_PARTNER_REFERENCE
             , POS.POS_DATE_PARTNER_DOCUMENT
             , POS.POS_PARTNER_POS_NUMBER
             , POS.PC_APPLTXT_ID
             , POS.STM_MOVEMENT_KIND_ID
             , POS.HRM_PERSON_ID
             , POS.FAM_FIXED_ASSETS_ID
             , POS.C_FAM_TRANSACTION_TYP
             , POS.POS_IMF_TEXT_1
             , POS.POS_IMF_TEXT_2
             , POS.POS_IMF_TEXT_3
             , POS.POS_IMF_TEXT_4
             , POS.POS_IMF_TEXT_5
             , POS.POS_IMF_NUMBER_2
             , POS.POS_IMF_NUMBER_3
             , POS.POS_IMF_NUMBER_4
             , POS.POS_IMF_NUMBER_5
             , POS.DIC_IMP_FREE1_ID
             , POS.DIC_IMP_FREE2_ID
             , POS.DIC_IMP_FREE3_ID
             , POS.DIC_IMP_FREE4_ID
             , POS.DIC_IMP_FREE5_ID
             , POS.POS_IMF_DATE_1
             , POS.POS_IMF_DATE_2
             , POS.POS_IMF_DATE_3
             , POS.POS_IMF_DATE_4
             , POS.POS_IMF_DATE_5
             , POS.POS_DATE_DELIVERY
             , GAP.GAP_TRANSFERT_PROPRIETOR
             , nvl(DCD.C_PDE_CREATE_MODE, '201') C_PDE_CREATE_MODE
             , POS.POS_IMPUTATION
             , POS.POS_ADDENDUM_SRC_POS_ID
             , DCD.DOC_GAUGE_RECEIPT_ID
             , DCD.DOC_GAUGE_COPY_ID
             , POS.GCO_MANUFACTURED_GOOD_ID
             , POS.GCO_COMPL_DATA_ID
             , POS.FAL_LOT_ID
          from DOC_POS_DET_COPY_DISCHARGE DCD
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , GCO_GOOD GOO
             , DOC_GAUGE_POSITION GAP
         where DCD.DOC_POSITION_ID = position_id
           and POS.DOC_POSITION_ID = DCD.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and GOO.GCO_GOOD_ID(+) = DCD.GCO_GOOD_ID
           and DCD.CRG_SELECT = 1
           and DCD.NEW_DOCUMENT_ID = newDocumentId
           and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
      group by POS.DOC_DOCUMENT_ID
             , DCD.DOC_DOC_POSITION_ID
             , DMT.PAC_THIRD_ID
             , POS.ASA_RECORD_ID
             , POS.ASA_RECORD_COMP_ID
             , POS.ASA_RECORD_TASK_ID
             , POS.DOC_RECORD_ID
             , POS.DOC_DOC_RECORD_ID
             , DCD.DOC_GAUGE_FLOW_ID
             , POS.PAC_PERSON_ID
             , DMT.PAC_THIRD_VAT_ID
             , POS.DOC_GAUGE_ID
             , POS.DOC_GAUGE_POSITION_ID
             , POS.C_GAUGE_TYPE_POS
             , POS.ACS_FINANCIAL_ACCOUNT_ID
             , POS.ACS_DIVISION_ACCOUNT_ID
             , POS.ACS_CPN_ACCOUNT_ID
             , POS.ACS_CDA_ACCOUNT_ID
             , POS.ACS_PF_ACCOUNT_ID
             , POS.ACS_PJ_ACCOUNT_ID
             , POS.DIC_UNIT_OF_MEASURE_ID
             , GOO.DIC_UNIT_OF_MEASURE_ID
             , GOO.GOO_NUMBER_OF_DECIMAL
             , POS.POS_CONVERT_FACTOR
             , DCD.GCO_GOOD_ID
             , POS.GCO_GOOD_ID
             , DCD.POS_SHORT_DESCRIPTION
             , DCD.POS_LONG_DESCRIPTION
             , DCD.POS_CONVERT_FACTOR
             , POS.POS_BALANCE_QUANTITY
             , POS.POS_NET_TARIFF
             , POS.POS_SPECIAL_TARIFF
             , POS.POS_FLAT_RATE
             , POS.POS_EFFECTIVE_DIC_TARIFF_ID
             , POS.DIC_TARIFF_ID
             , POS.POS_TARIFF_UNIT
             , POS.POS_TARIFF_SET
             , POS.POS_TARIFF_INITIALIZED
             , nvl(POS.POS_TARIFF_DATE, nvl(DMT.DMT_TARIFF_DATE, DMT.DMT_DATE_DOCUMENT) )
             , POS.POS_UPDATE_TARIFF
             , POS.POS_DISCOUNT_RATE
             , POS.POS_REF_UNIT_VALUE
             , POS.POS_UNIT_COST_PRICE
             , DCD.POS_GROSS_UNIT_VALUE_INCL
             , POS.POS_BALANCE_QTY_VALUE
             , DCD.POS_GROSS_UNIT_VALUE
             , POS.POS_GROSS_UNIT_VALUE2
             , POS.POS_FINAL_QUANTITY
             , POS.POS_BASIS_QUANTITY
             , POS.POS_CALC_BUDGET_AMOUNT_MB
             , POS.POS_EFFECT_BUDGET_AMOUNT_MB
             , POS.POS_VALUE_QUANTITY
             , POS.STM_STOCK_ID
             , POS.STM_STM_STOCK_ID
             , POS.STM_LOCATION_ID
             , POS.STM_STM_LOCATION_ID
             , POS.POS_GROSS_VALUE_B
             , POS.POS_UTIL_COEFF
             , POS.POS_GROSS_WEIGHT
             , POS.POS_NET_WEIGHT
             , POS.PAC_REPRESENTATIVE_ID
             , POS.PAC_REPR_ACI_ID
             , POS.PAC_REPR_DELIVERY_ID
             , POS.POS_REFERENCE
             , POS.POS_SECONDARY_REFERENCE
             , POS.POS_SHORT_DESCRIPTION
             , POS.POS_LONG_DESCRIPTION
             , POS.POS_FREE_DESCRIPTION
             , POS.POS_BODY_TEXT
             , POS.POS_EAN_CODE
             , POS.POS_EAN_UCC14_CODE
             , POS.POS_HIBC_PRIMARY_CODE
             , POS.POS_CONVERT_FACTOR2
             , POS.DIC_POS_FREE_TABLE_1_ID
             , POS.DIC_POS_FREE_TABLE_2_ID
             , POS.DIC_POS_FREE_TABLE_3_ID
             , POS.POS_DECIMAL_1
             , POS.POS_DECIMAL_2
             , POS.POS_DECIMAL_3
             , POS.POS_TEXT_1
             , POS.POS_TEXT_2
             , POS.POS_TEXT_3
             , POS.POS_DATE_1
             , POS.POS_DATE_2
             , POS.POS_DATE_3
             , POS.POS_PARTNER_NUMBER
             , POS.POS_PARTNER_REFERENCE
             , POS.POS_DATE_PARTNER_DOCUMENT
             , POS.POS_PARTNER_POS_NUMBER
             , POS.PC_APPLTXT_ID
             , POS.STM_MOVEMENT_KIND_ID
             , POS.HRM_PERSON_ID
             , POS.FAM_FIXED_ASSETS_ID
             , POS.C_FAM_TRANSACTION_TYP
             , POS.POS_IMF_TEXT_1
             , POS.POS_IMF_TEXT_2
             , POS.POS_IMF_TEXT_3
             , POS.POS_IMF_TEXT_4
             , POS.POS_IMF_TEXT_5
             , POS.POS_IMF_NUMBER_2
             , POS.POS_IMF_NUMBER_3
             , POS.POS_IMF_NUMBER_4
             , POS.POS_IMF_NUMBER_5
             , POS.DIC_IMP_FREE1_ID
             , POS.DIC_IMP_FREE2_ID
             , POS.DIC_IMP_FREE3_ID
             , POS.DIC_IMP_FREE4_ID
             , POS.DIC_IMP_FREE5_ID
             , POS.POS_IMF_DATE_1
             , POS.POS_IMF_DATE_2
             , POS.POS_IMF_DATE_3
             , POS.POS_IMF_DATE_4
             , POS.POS_IMF_DATE_5
             , POS.POS_DATE_DELIVERY
             , GAP.GAP_TRANSFERT_PROPRIETOR
             , nvl(DCD.C_PDE_CREATE_MODE, '201')
             , POS.POS_IMPUTATION
             , POS.POS_ADDENDUM_SRC_POS_ID
             , DCD.DOC_GAUGE_RECEIPT_ID
             , DCD.DOC_GAUGE_COPY_ID
             , POS.GCO_MANUFACTURED_GOOD_ID
             , POS.GCO_COMPL_DATA_ID
             , POS.FAL_LOT_ID;

    -- curseur sur les composants de la position (uniquement assemblage)
    cursor ComponentPosition(aProductPositionId number, aDocumentID number)
    is
      select   DOC_POSITION_ID
          from DOC_POS_DET_COPY_DISCHARGE
         where DOC_DOC_POSITION_ID = aProductPositionId
           and CRG_SELECT = 1
           and NEW_DOCUMENT_ID = aDocumentID
      group by DOC_POSITION_ID
      order by min(DOC_POS_DET_COPY_DISCHARGE_ID);

    -- curseur d'information sur les différents types de gabarit liés à la position
    cursor gauge_position(gaugeId number, gaugeTypePos varchar2, gaugeDesignation varchar2)
    is
      -- recherche du gabarit position du nouveau document
      select   DOC_GAUGE_POSITION_ID
             , STM_MOVEMENT_KIND_ID
             , C_ADMIN_DOMAIN
             , nvl(GAP.DIC_TYPE_MOVEMENT_ID, GAS.DIC_TYPE_MOVEMENT_ID)
             , GAS_INCREMENT_NBR
             , GAS_FIRST_NO
             , GAS_BALANCE_STATUS
             , GAS_VAT
             , GAS_INCLUDE_BUDGET_CONTROL
             , GAU_CONFIRM_STATUS
             , GAP_MVT_UTILITY
             , GAP_VALUE_QUANTITY
             , GAP_INCLUDE_TAX_TARIFF
             , GAP_DELAY
             , GAS_CHARACTERIZATION
             , C_GAUGE_INIT_PRICE_POS
             , DIC_DELAY_UPDATE_TYPE_ID
             , GAP_INIT_STOCK_PLACE
             , GAP.STM_STOCK_ID
             , GAP.STM_LOCATION_ID
             , GAP.STM_STM_STOCK_ID
             , GAP.STM_STM_LOCATION_ID
             , GAP_VALUE
             , GAP_WEIGHT
             , GAP_FORCED_TARIFF
             , DIC_TARIFF_ID
             , GAS.GAS_RECORD_IMPUTATION
             , nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
             , GAP.C_DOC_LOT_TYPE
             , GAP_SUBCONTRACTP_STOCK
             , GAP_STM_SUBCONTRACTP_STOCK
          from DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
         where GAU.DOC_GAUGE_ID = GAUGEID
           and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and GAP.C_GAUGE_TYPE_POS = gaugeTypePos
           and GAP.GAP_DESIGNATION = gaugeDesignation
      order by GAP.GAP_DEFAULT desc;

    SourcePosition_tuple        SourcePosition%rowtype;
    GaugeCopy_tuple             doc_gauge_copy%rowtype;
    TargetDocument_tuple        doc_document%rowtype;
    ComponentPositionId         doc_position.doc_position_id%type;
    SourceCurrencyId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TargetPositionId            doc_position.doc_position_id%type;
    TargetGaugePositionId       DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type;
    TargetMovementKindId        STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    TargetStockId               STM_STOCK.STM_STOCK_ID%type;
    TargetStock2Id              STM_STOCK.STM_STOCK_ID%type;
    TargetLocationId            STM_LOCATION.STM_LOCATION_ID%type;
    TargetLocation2Id           STM_LOCATION.STM_LOCATION_ID%type;
    TargetRecordId              DOC_RECORD.DOC_RECORD_ID%type;
    TargetDocDocRecordId        DOC_RECORD.DOC_RECORD_ID%type;
    TargetPersonId              PAC_PERSON.PAC_PERSON_ID%type;
    TargetTaxCodeId             ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceFinAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceDivAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceCpnAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourceCdaAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourcePfAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SourcePjAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetFinAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetDivAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetCpnAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetCdaAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetPfAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    TargetPjAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    LinkMovementKindID          STM_MOVEMENT_KIND.STM_STM_MOVEMENT_KIND_ID%type;
    ConvertFactor               DOC_POSITION.POS_CONVERT_FACTOR%type;
    ConvertFactor2              DOC_POSITION.POS_CONVERT_FACTOR2%type;
    DicUnitOfMeasureId          DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type;
    DicDicUnitOfMeasureId       DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type;
    NetWeight                   DOC_POSITION.POS_NET_WEIGHT%type;
    GrossWeight                 DOC_POSITION.POS_GROSS_WEIGHT%type;
    UtilCoef                    DOC_POSITION.POS_UTIL_COEFF%type;
    reference                   DOC_POSITION.POS_REFERENCE%type;
    SecondaryReference          DOC_POSITION.POS_SECONDARY_REFERENCE%type;
    ShortDescription            DOC_POSITION.POS_SHORT_DESCRIPTION%type;
    LongDescription             DOC_POSITION.POS_LONG_DESCRIPTION%type;
    FreeDescription             DOC_POSITION.POS_FREE_DESCRIPTION%type;
    BodyText                    DOC_POSITION.POS_BODY_TEXT%type;
    EANCode                     DOC_POSITION.POS_EAN_CODE%type;
    EANUCC14Code                DOC_POSITION.POS_EAN_UCC14_CODE%type;
    HIBCPrimaryCode             DOC_POSITION.POS_HIBC_PRIMARY_CODE%type;
    PriceCurrencyId             ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    RefUnitValue                DOC_POSITION.POS_REF_UNIT_VALUE%type;
    UnitCostPrice               DOC_POSITION.POS_UNIT_COST_PRICE%type;
    GrossUnitValue              DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    GrossUnitValue2             DOC_POSITION.POS_GROSS_UNIT_VALUE2%type;
    GrossUnitValueIncl          DOC_POSITION.POS_GROSS_UNIT_VALUE_INCL%type;
    GrossValue                  DOC_POSITION.POS_GROSS_VALUE%type;
    GrossValueIncl              DOC_POSITION.POS_GROSS_VALUE_INCL%type;
    NetUnitValue                DOC_POSITION.POS_NET_UNIT_VALUE%type;
    NetUnitvalueIncl            DOC_POSITION.POS_NET_UNIT_VALUE_INCL%type;
    NetValueExcl                DOC_POSITION.POS_NET_VALUE_EXCL%type;
    NetValueIncl                DOC_POSITION.POS_NET_VALUE_INCL%type;
    VatRate                     DOC_POSITION.POS_VAT_RATE%type;
    VatLiabledRate              DOC_POSITION.POS_VAT_LIABLED_RATE%type;
    VatLiabledAmount            DOC_POSITION.POS_VAT_LIABLED_AMOUNT%type;
    VatTotalAmount              DOC_POSITION.POS_VAT_TOTAL_AMOUNT%type;
    VatDeductibleRate           DOC_POSITION.POS_VAT_DEDUCTIBLE_RATE%type;
    VatAmount                   DOC_POSITION.POS_VAT_AMOUNT%type;
    PosNetTariff                DOC_POSITION.POS_NET_TARIFF%type;
    PosSpecialTariff            DOC_POSITION.POS_SPECIAL_TARIFF%type;
    PosFlatRate                 DOC_POSITION.POS_FLAT_RATE%type;
    PosTariffUnit               DOC_POSITION.POS_TARIFF_UNIT%type;
    PosTariffSet                DOC_POSITION.POS_TARIFF_SET%type;
    PosUpdateTariff             DOC_POSITION.POS_UPDATE_TARIFF%type;
    PosTariffInitialized        DOC_POSITION.POS_TARIFF_INITIALIZED%type;
    DiscountUnitValue           DOC_POSITION.POS_DISCOUNT_UNIT_VALUE%type;
    DiscountRate                DOC_POSITION.POS_DISCOUNT_RATE%type;
    PositionStatus              DOC_POSITION.C_DOC_POS_STATUS%type;
    RoundType                   varchar2(1);
    RoundAmount                 number(18, 5);
    ChargeCreated               number(1);
    ChargeAmount                DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    DiscountAmount              DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    TargetAdminDomain           DOC_GAUGE.C_ADMIN_DOMAIN%type;
    SourceAdminDomain           DOC_GAUGE.C_ADMIN_DOMAIN%type;
    ConfirmStatus               DOC_GAUGE.GAU_CONFIRM_STATUS%type;
    TargetTypeMovement          DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
    PosIncrement                DOC_GAUGE_STRUCTURED.GAS_INCREMENT_NBR%type;
    PosFirstNo                  DOC_GAUGE_STRUCTURED.GAS_FIRST_NO%type;
    BalanceStatus               DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type;
    GestVat                     DOC_GAUGE_STRUCTURED.GAS_VAT%type;
    IncludeBudgetControl        DOC_GAUGE_STRUCTURED.GAS_INCLUDE_BUDGET_CONTROL%type;
    ForceTransfertCharact       DOC_GAUGE_COPY.GAC_TRANSFERT_CHARACT%type;
    GapWeight                   DOC_GAUGE_POSITION.GAP_WEIGHT%type;
    GapForcedTariff             DOC_GAUGE_POSITION.GAP_FORCED_TARIFF%type;
    DicTariffId                 DOC_GAUGE_POSITION.DIC_TARIFF_ID%type;
    InitMovement                DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type;
    GestValueQuantity           DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    IncludeTaxTariff            DOC_GAUGE_POSITION.GAP_INCLUDE_TAX_TARIFF%type;
    SourceValueManagement       DOC_GAUGE_POSITION.GAP_VALUE%type;
    GaugeInitPricePos           DOC_GAUGE_POSITION.C_GAUGE_INIT_PRICE_POS%type;
    SourceGestDelay             DOC_GAUGE_POSITION.GAP_DELAY%type;
    GestDelay                   DOC_GAUGE_POSITION.GAP_DELAY%type;
    DelayUpdateType             DOC_GAUGE_POSITION.DIC_DELAY_UPDATE_TYPE_ID%type;
    InitStockAndLocation        DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type;
    GapStockID                  DOC_GAUGE_POSITION.STM_STOCK_ID%type;
    GapLocationID               DOC_GAUGE_POSITION.STM_LOCATION_ID%type;
    GapStockID2                 DOC_GAUGE_POSITION.STM_STM_STOCK_ID%type;
    GapLocationID2              DOC_GAUGE_POSITION.STM_STM_LOCATION_ID%type;
    ValueManagement             DOC_GAUGE_POSITION.GAP_VALUE%type;
    ParentGestChar              DOC_GAUGE_STRUCTURED.GAS_CHARACTERIZATION%type;
    GestChar                    DOC_GAUGE_STRUCTURED.GAS_CHARACTERIZATION%type;
    SourceGaugeDesignation      DOC_GAUGE_POSITION.GAP_DESIGNATION%type;
    cdaReference                GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    cdaSecondaryReference       GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    cdaEanCode                  GCO_GOOD.GOO_EAN_CODE%type;
    cdaEanUCC14Code             GCO_GOOD.GOO_EAN_UCC14_CODE%type;
    cdaHIBCPrimaryCode          GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
    cdaShortDescription         GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    cdaLongDescription          GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    cdaFreeDescription          GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    cdaDicUnitOfMeasureId       DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type;
    cdaConvertFactor            GCO_COMPL_DATA_SALE.CDA_CONVERSION_FACTOR%type;
    cdaNumberOfDecimal          GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    goodNumberOfDecimal         GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    cdaBodyText                 DOC_POSITION.POS_BODY_TEXT%type;
    cdaStockId                  STM_STOCK.STM_STOCK_ID%type;
    cdaLocationId               STM_LOCATION.STM_LOCATION_ID%type;
    cdaQuantity                 DOC_POSITION.POS_BASIS_QUANTITY%type;
    basisQuantity               DOC_POSITION.POS_BASIS_QUANTITY%type;
    intermediateQuantity        DOC_POSITION.POS_INTERMEDIATE_QUANTITY%type;
    finalQuantity               DOC_POSITION.POS_FINAL_QUANTITY%type;
    valueQuantity               DOC_POSITION.POS_VALUE_QUANTITY%type;
    balanceQuantityValue        DOC_POSITION.POS_BALANCE_QTY_VALUE%type;
    AlreadyLoadComplData        number(1);
    AlreadyLoadDecimalComplData number(1);
    -- Flags sur les données gêrées
    HrmPerson                   number(1);
    FamFixed                    number(1);
    Text1                       number(1);
    Text2                       number(1);
    Text3                       number(1);
    Text4                       number(1);
    Text5                       number(1);
    Number1                     number(1);
    Number2                     number(1);
    Number3                     number(1);
    Number4                     number(1);
    Number5                     number(1);
    DicFree1                    number(1);
    DicFree2                    number(1);
    DicFree3                    number(1);
    DicFree4                    number(1);
    DicFree5                    number(1);
    Date1                       number(1);
    Date2                       number(1);
    Date3                       number(1);
    Date4                       number(1);
    Date5                       number(1);
    vFinancial                  DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    vAnalytical                 DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    vInfoCompl                  DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    vInfoCompl_DOC_RECORD       integer                                                 default 0;
    vAccountInfo                ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    cGaugeType                  DOC_GAUGE.C_GAUGE_TYPE%type;
    gasAutoAttrib               DOC_GAUGE_STRUCTURED.GAS_AUTO_ATTRIBUTION%type;
    gasRecordImputation         DOC_GAUGE_STRUCTURED.GAS_RECORD_IMPUTATION%type;
    srcRecordImputation         DOC_GAUGE_STRUCTURED.GAS_RECORD_IMPUTATION%type;
    gasWeightMat                DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    srcWeightMat                DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    posCreateMat                DOC_POSITION.POS_CREATE_MAT%type                        default 0;
    vEffectiveDicTariffId       DOC_GAUGE_POSITION.DIC_TARIFF_ID%type;
    lvCDocLotType               DOC_GAUGE_POSITION.C_DOC_LOT_TYPE%type;
    lnGapSubcontractStock       DOC_GAUGE_POSITION.GAP_SUBCONTRACTP_STOCK%type;
    lnGapStmSubcontractStock    DOC_GAUGE_POSITION.GAP_STM_SUBCONTRACTP_STOCK%type;
    lnSourceSupplierID          PAC_THIRD.PAC_THIRD_ID%type;
    lnTargetSupplierID          PAC_THIRD.PAC_THIRD_ID%type;
    lvGaugeTypePosPT            DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    lbProcessingCPT             boolean;
    nFalLotId                   FAL_LOT.FAL_LOT_ID%type;
    lnLocalCurrency             ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lnConvertAmount             number(1);
  begin
    aCopyInfoCode                := '00';   -- traîtement OK
    RefUnitValue                 := 0;
    UnitCostPrice                := 0;
    GrossUnitValue               := 0;
    GrossUnitValue2              := 0;
    GrossUnitValueIncl           := 0;
    GrossValue                   := 0;
    GrossValueIncl               := 0;
    NetUnitValue                 := 0;
    NetUnitvalueIncl             := 0;
    NetValueExcl                 := 0;
    NetValueIncl                 := 0;
    VatRate                      := 0;
    VatLiabledRate               := 0;
    VatLiabledAmount             := 0;
    VatTotalAmount               := 0;
    VatDeductibleRate            := 0;
    VatAmount                    := 0;
    DiscountUnitValue            := 0;
    ChargeAmount                 := 0;
    DiscountAmount               := 0;
    AlreadyLoadComplData         := 0;
    AlreadyLoadDecimalComplData  := 0;
    lbProcessingCPT              := false;

    -- pointeur sur la position source
    open SourcePosition(aSourcePositionId, aTargetDocumentId);

    fetch SourcePosition
     into SourcePosition_tuple;

    -- pointeur sur le document cible
    select *
      into TargetDocument_tuple
      from doc_document
     where doc_document_id = aTargetDocumentId;

    -- recherche divers informations document source
    select ACS_FINANCIAL_CURRENCY_ID
         , C_ADMIN_DOMAIN
         , GAS_CHARACTERIZATION
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
         , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
         , nvl(GAS_WEIGHT_MAT, 0)
         , nvl(GAS_RECORD_IMPUTATION, 0)
      into SourceCurrencyId
         , SourceAdminDomain
         , ParentGestChar
         , vFinancial
         , vAnalytical
         , vInfoCompl
         , srcWeightMat
         , srcRecordImputation
      from DOC_DOCUMENT DOC
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
     where DOC.DOC_DOCUMENT_ID = SourcePosition_tuple.DOC_DOCUMENT_ID
       and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    -- Vérifier si le type DOC_RECORD est géré dans les info compl du gabarit du
    -- document cible
    if vInfoCompl = 1 then
      select nvl(max(1), 0)
        into vInfoCompl_DOC_RECORD
        from DOC_GAUGE_MANAGED_DATA GMA
       where DOC_GAUGE_ID = TargetDocument_tuple.DOC_GAUGE_ID
         and C_DATA_TYP = 'DOC_RECORD';
    end if;

    -- pointeur sur le gabarit de copie
    begin
      -- pointeur sur le gabarit de décharge
      if SourcePosition_tuple.doc_gauge_copy_id > 0 then
        select gac.*
          into GaugeCopy_tuple
          from doc_gauge_copy gac
         where gac.doc_gauge_copy_id = SourcePosition_tuple.doc_gauge_copy_id;
      else
        select gac.*
          into GaugeCopy_tuple
          from doc_gauge_copy gac
             , doc_gauge_flow_docum gad
         where gad.doc_gauge_flow_id = SourcePosition_tuple.doc_gauge_flow_id
           and gac.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
           and gad.doc_gauge_id = TargetDocument_tuple.doc_gauge_id
           and gac.doc_doc_gauge_id = SourcePosition_tuple.doc_gauge_id;
      end if;
    exception
      when no_data_found then
        raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Aucun flux de copie trouvé!') || co.cLineBreak || sqlerrm);
    end;

    -- recherche du dossier
    select decode(GaugeCopy_tuple.GAC_TRANSFERT_RECORD, 0, TargetDocument_tuple.DOC_RECORD_ID, SourcePosition_tuple.DOC_RECORD_ID)
      into TargetRecordId
      from dual;

    -- recherche de valeurs sur le gabarit de la position source
    select gap_value
         , gap_delay
         , gap_designation
      into SourceValueManagement
         , SourceGestDelay
         , SourceGaugeDesignation
      from DOC_GAUGE_POSITION
     where DOC_GAUGE_POSITION_ID = SourcePosition_tuple.doc_gauge_position_id;

    -- recherche du gabarit position du nouveau document
    open gauge_position(TargetDocument_tuple.DOC_GAUGE_ID, SourcePosition_tuple.c_gauge_type_pos, SourceGaugeDesignation);

    fetch gauge_position
     into TargetGaugePositionId
        , TargetMovementKindId
        , TargetAdminDomain
        , TargetTypeMovement
        , PosIncrement
        , PosFirstNo
        , BalanceStatus
        , GestVat
        , IncludeBudgetControl
        , ConfirmStatus
        , InitMovement
        , GestValueQuantity
        , IncludeTaxTariff
        , GestDelay
        , GestChar
        , GaugeInitPricePos
        , DelayUpdateType
        , InitStockAndLocation
        , GapStockID
        , GapLocationID
        , GapStockID2
        , GapLocationID2
        , ValueManagement
        , GapWeight
        , GapForcedTariff
        , DicTariffId
        , gasRecordImputation
        , gasWeightMat
        , lvCDocLotType
        , lnGapSubcontractStock
        , lnGapStmSubcontractStock;

    close gauge_position;

    if GestVat = 1 then
      -- Recherche du code Taxe
      TargetTaxCodeId  :=
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(1
                                              , TargetDocument_tuple.PAC_THIRD_VAT_ID
                                              , SourcePosition_tuple.GCO_GOOD_ID
                                              , 0
                                              , 0
                                              , TargetAdminDomain
                                              , TargetDocument_tuple.DIC_TYPE_SUBMISSION_ID
                                              , TargetTypeMovement
                                              , TargetDocument_tuple.ACS_VAT_DET_ACCOUNT_ID
                                               );
    end if;

    -- Si gestion ou initialisation des comptes financiers ou analytiques sur le document source
    -- et pas de changement de tiers et domaine cible indentique au domaine source
    -- alors on reprend les comptes de la position source.
    if     (    (vFinancial = 1)
            or (vAnalytical = 1) )
       and (SourcePosition_tuple.PAC_THIRD_ID = TargetDocument_tuple.PAC_THIRD_ID)
       and (SourceAdminDomain = TargetAdminDomain) then
      SourceFinAccountId  := SourcePosition_tuple.ACS_FINANCIAL_ACCOUNT_ID;
      SourceDivAccountId  := SourcePosition_tuple.ACS_DIVISION_ACCOUNT_ID;
      SourceCpnAccountId  := SourcePosition_tuple.ACS_CPN_ACCOUNT_ID;
      SourceCdaAccountId  := SourcePosition_tuple.ACS_CDA_ACCOUNT_ID;
      SourcePfAccountId   := SourcePosition_tuple.ACS_PF_ACCOUNT_ID;
      SourcePjAccountId   := SourcePosition_tuple.ACS_PJ_ACCOUNT_ID;

      if (vInfoCompl = 1) then
        -- recherche du DOC_DOC_RECORD_ID et PAC_PERSON_ID
        -- Effacer les données du champ DOC_DOC_RECORD_ID si le gabarit ne géré pas
        -- le type DOC_RECORD dans les informations complémentaires
        select case
                 when vInfoCompl_DOC_RECORD = 1 then nvl(SourcePosition_tuple.DOC_DOC_RECORD_ID, nvl(TargetRecordId, TargetDocument_tuple.DOC_RECORD_ID) )
                 else null
               end
             , nvl(SourcePosition_tuple.PAC_PERSON_ID, TargetDocument_tuple.PAC_THIRD_ID)
          into TargetDocDocRecordId
             , TargetPersonId
          from dual;

        vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(SourcePosition_tuple.HRM_PERSON_ID);
        vAccountInfo.FAM_FIXED_ASSETS_ID    := SourcePosition_tuple.FAM_FIXED_ASSETS_ID;
        vAccountInfo.C_FAM_TRANSACTION_TYP  := SourcePosition_tuple.C_FAM_TRANSACTION_TYP;
        vAccountInfo.DEF_DIC_IMP_FREE1      := SourcePosition_tuple.DIC_IMP_FREE1_ID;
        vAccountInfo.DEF_DIC_IMP_FREE2      := SourcePosition_tuple.DIC_IMP_FREE2_ID;
        vAccountInfo.DEF_DIC_IMP_FREE3      := SourcePosition_tuple.DIC_IMP_FREE3_ID;
        vAccountInfo.DEF_DIC_IMP_FREE4      := SourcePosition_tuple.DIC_IMP_FREE4_ID;
        vAccountInfo.DEF_DIC_IMP_FREE5      := SourcePosition_tuple.DIC_IMP_FREE5_ID;
        vAccountInfo.DEF_TEXT1              := SourcePosition_tuple.POS_IMF_TEXT_1;
        vAccountInfo.DEF_TEXT2              := SourcePosition_tuple.POS_IMF_TEXT_2;
        vAccountInfo.DEF_TEXT3              := SourcePosition_tuple.POS_IMF_TEXT_3;
        vAccountInfo.DEF_TEXT4              := SourcePosition_tuple.POS_IMF_TEXT_4;
        vAccountInfo.DEF_TEXT5              := SourcePosition_tuple.POS_IMF_TEXT_5;
        vAccountInfo.DEF_NUMBER2            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_2);
        vAccountInfo.DEF_NUMBER3            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_3);
        vAccountInfo.DEF_NUMBER4            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_4);
        vAccountInfo.DEF_NUMBER5            := to_char(SourcePosition_tuple.POS_IMF_NUMBER_5);
        vAccountInfo.DEF_DATE1              := SourcePosition_tuple.POS_IMF_DATE_1;
        vAccountInfo.DEF_DATE2              := SourcePosition_tuple.POS_IMF_DATE_2;
        vAccountInfo.DEF_DATE3              := SourcePosition_tuple.POS_IMF_DATE_3;
        vAccountInfo.DEF_DATE4              := SourcePosition_tuple.POS_IMF_DATE_4;
        vAccountInfo.DEF_DATE5              := SourcePosition_tuple.POS_IMF_DATE_5;
      end if;
    else
      SourceFinAccountId  := null;
      SourceDivAccountId  := null;
      SourceCpnAccountId  := null;
      SourceCdaAccountId  := null;
      SourcePfAccountId   := null;
      SourcePjAccountId   := null;
    end if;

    if SourcePosition_tuple.C_GAUGE_TYPE_POS = '5' then   /* Position valeur */
      -- recherche des comptes non définis
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(null
                                             , '40'
                                             , TargetAdminDomain
                                             , TargetDocument_tuple.DMT_DATE_DOCUMENT
                                             , null
                                             , TargetDocument_tuple.DOC_GAUGE_ID
                                             , aTargetDocumentId
                                             , aTargetPositionId
                                             , TargetRecordId
                                             , TargetDocument_tuple.PAC_THIRD_ACI_ID
                                             , SourceFinAccountId
                                             , SourceDivAccountId
                                             , SourceCpnAccountId
                                             , SourceCdaAccountId
                                             , SourcePfAccountId
                                             , SourcePjAccountId
                                             , TargetFinAccountId
                                             , TargetDivAccountId
                                             , TargetCpnAccountId
                                             , TargetCdaAccountId
                                             , TargetPfAccountId
                                             , TargetPjAccountId
                                             , vAccountInfo
                                              );
    else
      -- recherche des comptes non définis
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(SourcePosition_tuple.GCO_GOOD_ID
                                             , '10'
                                             , TargetAdminDomain
                                             , TargetDocument_tuple.DMT_DATE_DOCUMENT
                                             , SourcePosition_tuple.GCO_GOOD_ID
                                             , TargetDocument_tuple.DOC_GAUGE_ID
                                             , aTargetDocumentId
                                             , aTargetPositionId
                                             , TargetRecordId
                                             , TargetDocument_tuple.PAC_THIRD_ACI_ID
                                             , SourceFinAccountId
                                             , SourceDivAccountId
                                             , SourceCpnAccountId
                                             , SourceCdaAccountId
                                             , SourcePfAccountId
                                             , SourcePjAccountId
                                             , TargetFinAccountId
                                             , TargetDivAccountId
                                             , TargetCpnAccountId
                                             , TargetCdaAccountId
                                             , TargetPfAccountId
                                             , TargetPjAccountId
                                             , vAccountInfo
                                              );
    end if;

    ---
    -- Recherche des données complémentaires si changement de bien ou pas de
    -- reprise des description.
    if    (SourcePosition_tuple.POS_GOOD_ID <> SourcePosition_tuple.GCO_GOOD_ID)
       or (GaugeCopy_tuple.GAC_TRANSFERT_DESCR = 0) then
      if TargetAdminDomain = '2' then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '2'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   -- aOperationID
                                                , 0   -- aTransProprietor
                                                , null   -- aComplDataID
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      elsif TargetAdminDomain in('1', '5') then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '1'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   -- aOperationID
                                                , 0   -- aTransProprietor
                                                , null   -- aComplDataID
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      end if;

      reference              := cdaReference;
      SecondaryReference     := cdaSecondaryReference;
      ShortDescription       := cdaShortDescription;
      LongDescription        := cdaLongDescription;
      FreeDescription        := cdaFreeDescription;
      BodyText               := cdaBodyText;
      EANCode                := cdaEanCode;
      EANUCC14Code           := cdaEanUCC14Code;
      HIBCPrimaryCode        := cdaHIBCPrimaryCode;

      -- Recherche du facteur de conversion
      if SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8', '9', '10', '71', '81', '91', '101') then
        ConvertFactor       := 1;
        DicUnitOfMeasureId  := SourcePosition_tuple.GOO_UNIT_OF_MEASURE_ID;
      else
        ConvertFactor       := cdaConvertFactor;
        DicUnitOfMeasureId  := cdaDicUnitOfMeasureId;
      end if;

      ConvertFactor2         := cdaConvertFactor;
      DicDicUnitOfMeasureId  := SourcePosition_tuple.GOO_UNIT_OF_MEASURE_ID;
    else   -- Transfert description
      reference              := SourcePosition_tuple.POS_REFERENCE;
      SecondaryReference     := SourcePosition_tuple.POS_SECONDARY_REFERENCE;
      ShortDescription       := SourcePosition_tuple.POS_SHORT_DESCRIPTION;
      LongDescription        := SourcePosition_tuple.POS_LONG_DESCRIPTION;
      FreeDescription        := SourcePosition_tuple.POS_FREE_DESCRIPTION;
      BodyText               := SourcePosition_tuple.POS_BODY_TEXT;
      EANCode                := SourcePosition_tuple.POS_EAN_CODE;
      EANUCC14Code           := SourcePosition_tuple.POS_EAN_UCC14_CODE;
      HIBCPrimaryCode        := SourcePosition_tuple.POS_HIBC_PRIMARY_CODE;
      ConvertFactor          := SourcePosition_tuple.POS_CONVERT_FACTOR;
      ConvertFactor2         := nvl(SourcePosition_tuple.POS_CONVERT_FACTOR2, SourcePosition_tuple.POS_CONVERT_FACTOR);
      DicUnitOfMeasureId     := SourcePosition_tuple.DIC_UNIT_OF_MEASURE_ID;
      DicDicUnitOfMeasureId  := SourcePosition_tuple.GOO_UNIT_OF_MEASURE_ID;
    end if;

    ---
    -- Détermine s'il faut convertir la quantité. C'est le cas si le facteur
    -- de conversion parent est différent du facteur de conversion du fils.
    --
    if     (GaugeCopy_tuple.GAC_TRANSFERT_QUANTITY = 1)
       and (SourcePosition_tuple.POS_CONVERT_FACTOR <> ConvertFactor) then
      ---
      -- On doit rechercher le nombre de décimal des données complémentaires si
      -- il n'a pas déjà été recherché.
      --
      if (AlreadyLoadComplData = 0) then
        if TargetAdminDomain = '2' then
          GCO_I_LIB_COMPL_DATA.GetCDANumberOfDecimal(SourcePosition_tuple.GCO_GOOD_ID
                                                   , 'SALE'
                                                   , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                   , TargetDocument_tuple.PC_LANG_ID
                                                   , cdaNumberOfDecimal
                                                    );
          AlreadyLoadDecimalComplData  := 1;
        elsif TargetAdminDomain in('1', '5') then
          GCO_I_LIB_COMPL_DATA.GetCDANumberOfDecimal(SourcePosition_tuple.GCO_GOOD_ID
                                                   , 'PURCHASE'
                                                   , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                   , TargetDocument_tuple.PC_LANG_ID
                                                   , cdaNumberOfDecimal
                                                    );
          AlreadyLoadDecimalComplData  := 1;
        end if;
      end if;

      BasisQuantity         :=
        ACS_FUNCTION.RoundNear(SourcePosition_tuple.DCD_QUANTITY * SourcePosition_tuple.POS_CONVERT_FACTOR / ConvertFactor, 1 / power(10, cdaNumberOfDecimal)
                             , 0);
      IntermediateQuantity  := BasisQuantity;
      FinalQuantity         := BasisQuantity;
    elsif(GaugeCopy_tuple.GAC_TRANSFERT_QUANTITY = 1) then
      BasisQuantity         := SourcePosition_tuple.DCD_QUANTITY;
      IntermediateQuantity  := SourcePosition_tuple.DCD_QUANTITY;
      FinalQuantity         := SourcePosition_tuple.DCD_QUANTITY;
    else
      BasisQuantity         := 0;
      IntermediateQuantity  := 0;
      FinalQuantity         := 0;
    end if;

    -- Initialisation de la Qté valeur
    if GestValueQuantity = 1 then
      valueQuantity  := least(abs(SourcePosition_tuple.pos_value_quantity), abs(BasisQuantity) );
    else
      valueQuantity  := BasisQuantity;
    end if;

    -- Qtés à 0 pour les copies en mode 205 ou 206
    if SourcePosition_tuple.C_PDE_CREATE_MODE in('205', '206') then
      BasisQuantity         := 0;
      IntermediateQuantity  := 0;
      FinalQuantity         := 0;
      valueQuantity         := 0;
    end if;

    -- Convertit éventuellement le prix si on le transfert des prix dans le flux
    if GaugeCopy_tuple.GAC_TRANSFERT_PRICE = 1 then
      PosNetTariff           := SourcePosition_tuple.POS_NET_TARIFF;
      PosSpecialTariff       := SourcePosition_tuple.POS_SPECIAL_TARIFF;
      PosFlatRate            := SourcePosition_tuple.POS_FLAT_RATE;
      vEffectiveDicTariffId  := SourcePosition_tuple.POS_EFFECTIVE_DIC_TARIFF_ID;
      DicTariffID            := SourcePosition_tuple.DIC_TARIFF_ID;
      PosUpdateTariff        := SourcePosition_tuple.POS_UPDATE_TARIFF;
      PosTariffUnit          := SourcePosition_tuple.POS_TARIFF_UNIT;
      PosTariffInitialized   := SourcePosition_tuple.POS_TARIFF_INITIALIZED;
      DiscountRate           := nvl(SourcePosition_tuple.POS_DISCOUNT_RATE, 0);

      if     SourcePosition_tuple.C_GAUGE_TYPE_POS in('1', '7', '10', '81', '91')
         and PAC_FUNCTIONS.IsTariffBySet(nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID), TargetAdminDomain) = 1 then
        PosTariffSet  := SourcePosition_tuple.POS_TARIFF_SET;
      end if;

      if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = SourceCurrencyId then
        RefUnitValue  := SourcePosition_tuple.POS_REF_UNIT_VALUE;
      else
        RefUnitValue  :=
          ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_REF_UNIT_VALUE
                                          , SourceCurrencyId
                                          , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                          , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                          , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                          , TargetDocument_tuple.DMT_BASE_PRICE
                                          , 0
                                          , 5
                                           );   /* Cours logistique */
      end if;

      if IncludeTaxTariff = 1 then   -- TTC
        GrossUnitValue     := 0;
        GrossUnitValue2    := 0;

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = SourceCurrencyId then
          GrossUnitValueIncl  := SourcePosition_tuple.POS_GROSS_UNIT_VALUE_INCL;
        else
          GrossUnitValueIncl  :=
            ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE_INCL
                                            , SourceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   /* Cours logistique */
        end if;

        DiscountUnitValue  := GrossUnitValueIncl * DiscountRate / 100;
        GrossValue         := 0;
        GrossValueIncl     := valueQuantity *(GrossUnitValueIncl - DiscountUnitValue);
        NetValueIncl       := GrossValueIncl;
        ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                 , aRefDate          => nvl(SourcePosition_tuple.POS_DATE_DELIVERY
                                                          , nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE)
                                                           )
                                 , aIncludedVat      => 'I'
                                 , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                       , '0') )
                                 , aNetAmountExcl    => NetValueExcl
                                 , aNetAmountIncl    => NetValueIncl
                                 , aLiabledRate      => VatLiabledRate
                                 , aLiabledAmount    => VatLiabledAmount
                                 , aTaxeRate         => VatRate
                                 , aVatTotalAmount   => VatTotalAmount
                                 , aDeductibleRate   => VatDeductibleRate
                                 , aVatAmount        => VatAmount
                                  );

        if BasisQuantity <> 0 then
          NetUnitValue  := NetValueExcl / BasisQuantity;
        else
          NetUnitValue  := NetValueExcl;
        end if;
      else   -- HT
        GrossUnitValueIncl  := 0;

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = SourceCurrencyId then
          GrossUnitValue   := SourcePosition_tuple.POS_GROSS_UNIT_VALUE;
          GrossUnitValue2  := SourcePosition_tuple.POS_GROSS_UNIT_VALUE2;
        else
          GrossUnitValue   :=
            ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE
                                            , SourceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   /* Cours logistique */
          GrossUnitValue2  :=
            ACS_FUNCTION.ConvertAmountForView(SourcePosition_tuple.POS_GROSS_UNIT_VALUE2
                                            , SourceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   /* Cours logistique */
        end if;

        DiscountUnitValue   := GrossUnitValue * DiscountRate / 100;
        GrossValue          := valueQuantity *(GrossUnitValue - DiscountUnitValue);
        GrossValueIncl      := 0;
        NetValueExcl        := GrossValue;

        if BasisQuantity <> 0 then
          NetUnitValue  := NetValueExcl / BasisQuantity;
        else
          NetUnitValue  := NetValueExcl;
        end if;

        ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                 , aRefDate          => nvl(SourcePosition_tuple.POS_DATE_DELIVERY
                                                          , nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE)
                                                           )
                                 , aIncludedVat      => 'E'
                                 , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                       , '0') )
                                 , aNetAmountExcl    => NetValueExcl
                                 , aNetAmountIncl    => NetValueIncl
                                 , aLiabledRate      => VatLiabledRate
                                 , aLiabledAmount    => VatLiabledAmount
                                 , aTaxeRate         => VatRate
                                 , aVatTotalAmount   => VatTotalAmount
                                 , aDeductibleRate   => VatDeductibleRate
                                 , aVatAmount        => VatAmount
                                  );
      end if;
    -- pas de transfert du prix
    else
      PriceCurrencyId        := TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID;
      DiscountRate           := 0;
      DiscountUnitValue      := 0;

      if     GapForcedTariff = 0
         and GaugeInitPricePos in('1', '2') then
        select nvl(TargetDocument_tuple.DIC_TARIFF_ID, dicTariffId)
          into dicTariffId
          from dual;
      end if;

      vEffectiveDicTariffId  := dicTariffId;

      if     SourcePosition_tuple.C_GAUGE_TYPE_POS in('1', '7', '10', '81', '91')
         and PAC_FUNCTIONS.IsTariffBySet(nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID), TargetAdminDomain) = 1 then
        if TargetAdminDomain = '1' then
          select DIC_TARIFF_SET_PURCHASE_ID
            into PosTariffSet
            from GCO_GOOD
           where GCO_GOOD_ID = SourcePosition_tuple.GCO_GOOD_ID;
        else
          select DIC_TARIFF_SET_SALE_ID
            into PosTariffSet
            from GCO_GOOD
           where GCO_GOOD_ID = SourcePosition_tuple.GCO_GOOD_ID;
        end if;
      end if;

      if IncludeTaxTariff = 1 then   -- TTC
        GrossUnitValueIncl  :=
          nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => SourcePosition_tuple.GCO_GOOD_ID
                                         , iTypePrice           => GaugeInitPricePos
                                         , iThirdId             => nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                         , iRecordId            => TargetDocument_tuple.DOC_RECORD_ID
                                         , iFalScheduleStepId   => null
                                         , ioDicTariff          => vEffectiveDicTariffId
                                         , iQuantity            => FinalQuantity
                                         , iDateRef             => nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                         , ioRoundType          => roundtype
                                         , ioRoundAmount        => roundAmount
                                         , ioCurrencyId         => PriceCurrencyId
                                         , oNet                 => PosNetTariff
                                         , oSpecial             => PosSpecialTariff
                                         , oFlatRate            => PosFlatRate
                                         , oTariffUnit          => PosTariffUnit
                                         , iDicTariff2          => TargetDocument_tuple.DIC_TARIFF_ID
                                          ) *
              ConvertFactor
            , 0
             );

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID <> PriceCurrencyId then
          GrossUnitValueIncl  :=
            ACS_FUNCTION.ConvertAmountForView(GrossUnitValueIncl
                                            , PriceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   /* Cours logistique */
        end if;

        ----
        -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT).
        -- En principe c'est une position de type '81' mais dans le cas des positions non liées, cela peut être une position
        -- de type '1'.
        --
        lvGaugeTypePosPT    := null;

        -- Détermine le type de position du composé par le composant courant
        if SourcePosition_tuple.DOC_DOC_POSITION_ID is not null then
          select POS.C_GAUGE_TYPE_POS
            into lvGaugeTypePosPT
            from DOC_POSITION POS
           where POS.DOC_POSITION_ID = SourcePosition_tuple.DOC_DOC_POSITION_ID;
        end if;

        if (nvl(lvGaugeTypePosPT, '0') = '8') then
          ----
          -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT)
          --
          GrossUnitValue2     := GrossUnitValueIncl;
          GrossUnitValue      := 0;
          GrossUnitValueIncl  := 0;
          NetUnitValue        := 0;
          NetUnitValueIncl    := 0;
          DiscountUnitValue   := 0;
          GrossValue          := 0;
          GrossValueIncl      := 0;
          NetValueIncl        := 0;
          NetValueExcl        := 0;
          VatAmount           := 0;
        else
          GrossValue      := 0;
          GrossValueIncl  := valueQuantity * GrossUnitValueIncl;
          NetValueIncl    := GrossValueIncl;
          ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                   , aRefDate          => nvl(SourcePosition_tuple.POS_DATE_DELIVERY
                                                            , nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE)
                                                             )
                                   , aIncludedVat      => 'I'
                                   , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                         , '0') )
                                   , aNetAmountExcl    => NetValueExcl
                                   , aNetAmountIncl    => NetValueIncl
                                   , aLiabledRate      => VatLiabledRate
                                   , aLiabledAmount    => VatLiabledAmount
                                   , aTaxeRate         => VatRate
                                   , aVatTotalAmount   => VatTotalAmount
                                   , aDeductibleRate   => VatDeductibleRate
                                   , aVatAmount        => VatAmount
                                    );

          if BasisQuantity <> 0 then
            NetUnitValue  := NetValueExcl / BasisQuantity;
          else
            NetUnitValue  := NetValueExcl;
          end if;

          if GaugeInitPricePos in('1', '2') then
            PosTariffInitialized  := GrossUnitValueIncl;
          end if;
        end if;
      else   -- HT
        GrossUnitValue    :=
          nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => SourcePosition_tuple.GCO_GOOD_ID
                                         , iTypePrice           => GaugeInitPricePos
                                         , iThirdId             => nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                         , iRecordId            => TargetDocument_tuple.DOC_RECORD_ID
                                         , iFalScheduleStepId   => null
                                         , ioDicTariff          => vEffectiveDicTariffId
                                         , iQuantity            => FinalQuantity
                                         , iDateRef             => nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                         , ioRoundType          => roundtype
                                         , ioRoundAmount        => roundAmount
                                         , ioCurrencyId         => PriceCurrencyId
                                         , oNet                 => PosNetTariff
                                         , oSpecial             => PosSpecialTariff
                                         , oFlatRate            => PosFlatRate
                                         , oTariffUnit          => PosTariffUnit
                                         , iDicTariff2          => TargetDocument_tuple.DIC_TARIFF_ID
                                          ) *
              ConvertFactor
            , 0
             );

        if TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID <> PriceCurrencyId then
          GrossUnitValue  :=
            ACS_FUNCTION.ConvertAmountForView(GrossUnitValue
                                            , PriceCurrencyId
                                            , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                            , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                            , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                            , TargetDocument_tuple.DMT_BASE_PRICE
                                            , 0
                                            , 5
                                             );   /* Cours logistique */
        end if;

        ----
        -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT).
        -- En principe c'est une position de type '81' mais dans le cas des positions non liées, cela peut être une position
        -- de type '1'.
        --
        lvGaugeTypePosPT  := null;

        -- Détermine le type de position du composé par le composant courant
        if SourcePosition_tuple.DOC_DOC_POSITION_ID is not null then
          select POS.C_GAUGE_TYPE_POS
            into lvGaugeTypePosPT
            from DOC_POSITION POS
           where POS.DOC_POSITION_ID = SourcePosition_tuple.DOC_DOC_POSITION_ID;
        end if;

        if (nvl(lvGaugeTypePosPT, '0') = '8') then
          ----
          -- Traitement d'une position composant lié à un produit terminé de type 8 (Assemblage valeur PT somme CPT)
          --
          GrossUnitValue2     := GrossUnitValue;
          GrossUnitValue      := 0;
          GrossUnitValueIncl  := 0;
          NetUnitValue        := 0;
          NetUnitValueIncl    := 0;
          DiscountUnitValue   := 0;
          GrossValue          := 0;
          GrossValueIncl      := 0;
          NetValueIncl        := 0;
          NetValueExcl        := 0;
          VatAmount           := 0;
        else
          GrossUnitValue2  := GrossUnitValue;
          GrossValue       := valueQuantity * GrossUnitValue;
          GrossValueIncl   := 0;
          NetValueExcl     := GrossValue;

          if BasisQuantity <> 0 then
            NetUnitValue  := NetValueExcl / BasisQuantity;
          else
            NetUnitValue  := NetValueExcl;
          end if;

          ACS_FUNCTION.CalcVatAmount(aTaxCodeId        => TargetTaxCodeId
                                   , aRefDate          => nvl(SourcePosition_tuple.POS_DATE_DELIVERY
                                                            , nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE)
                                                             )
                                   , aIncludedVat      => 'E'
                                   , aRoundAmount      => to_number(nvl(2   /*PCS.PC_CONFIG.GetConfig('DOC_ROUND_POSITION')*/
                                                                         , '0') )
                                   , aNetAmountExcl    => NetValueExcl
                                   , aNetAmountIncl    => NetValueIncl
                                   , aLiabledRate      => VatLiabledRate
                                   , aLiabledAmount    => VatLiabledAmount
                                   , aTaxeRate         => VatRate
                                   , aVatTotalAmount   => VatTotalAmount
                                   , aDeductibleRate   => VatDeductibleRate
                                   , aVatAmount        => VatAmount
                                    );

          if GaugeInitPricePos in('1', '2') then
            PosTariffInitialized  := GrossUnitValue;
          end if;
        end if;
      end if;

      if GaugeInitPricePos in('1', '2') then
        PosUpdateTariff  := 0;
      end if;
    end if;

    -- Prix à 0 pour les copies en mode 205 ou 206
    if SourcePosition_tuple.C_PDE_CREATE_MODE in('205', '206') then
      PosNetTariff          := 0;
      PosSpecialTariff      := 0;
      PosFlatRate           := 0;
      DicTariffID           := null;
      PosUpdateTariff       := null;
      PosTariffUnit         := null;
      PosTariffInitialized  := 0;
      DiscountRate          := 0;
      PosTariffSet          := null;
      GrossUnitValue        := 0;
      GrossUnitValue2       := 0;
      GrossUnitValueIncl    := 0;
      DiscountUnitValue     := 0;
      NetValueIncl          := 0;
      NetValueExcl          := 0;
      VatLiabledRate        := 0;
      VatLiabledAmount      := 0;
      VatRate               := 0;
      VatTotalAmount        := 0;
      VatDeductibleRate     := 0;
      VatAmount             := 0;
    end if;

    /* Valeur unitaire nette. Modification temporaire en attente de l'intégration
       de la quantité valeur. */
    if (BasisQuantity <> 0) then
      NetUnitValueIncl  := NetValueIncl / BasisQuantity;
    end if;

    -- initialisation du prix de revient unitaire
    -- si le domaine gabarit n'a pas changé
    if TargetAdminDomain = SourceAdminDomain then
      if GaugeCopy_tuple.GAC_INIT_COST_PRICE = 1 then
        UnitCostPrice  := SourcePosition_tuple.pos_unit_cost_price;
      else
        UnitCostPrice  :=
          nvl(GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(SourcePosition_tuple.GCO_GOOD_ID
                                                           , nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                                            )
            , 0
             );
      end if;
    else
      if GaugeCopy_tuple.GAC_INIT_COST_PRICE = 1 then
        select decode(SourcePosition_tuple.POS_FINAL_QUANTITY, 0, 0, SourcePosition_tuple.POS_GROSS_VALUE_B / SourcePosition_tuple.POS_FINAL_QUANTITY)
          into UnitCostPrice
          from dual;
      else
        UnitCostPrice  :=
          nvl(GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(SourcePosition_tuple.GCO_GOOD_ID
                                                           , nvl(TargetDocument_tuple.PAC_THIRD_TARIFF_ID, TargetDocument_tuple.PAC_THIRD_ID)
                                                            )
            , 0
             );
      end if;
    end if;

    /* Initialisation des poids. */

    /* Reprise des poids */
    /* Seulement si le flag de gestion des poids est activé et que la quantité déchargée est différente de 0 */
    if     gapWeight = 1
       and BasisQuantity <> 0 then
      /* position Kit et assemblage */
      if SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        -- Cumul du poids des composants
        select sum(POS_GROSS_WEIGHT)
             , sum(POS_NET_WEIGHT)
          into grossWeight
             , netWeight
          from DOC_POSITION
         where DOC_DOC_POSITION_ID = aSourcePositionId;
      else
        grossWeight  := SourcePosition_tuple.POS_GROSS_WEIGHT;
        netWeight    := SourcePosition_tuple.POS_NET_WEIGHT;
      end if;

      -- Règle de trois par rapport à la quantité sélectionnée
      if     SourcePosition_tuple.POS_FINAL_QUANTITY <> 0
         and SourcePosition_tuple.POS_FINAL_QUANTITY <> BasisQuantity then
        grossWeight  := abs( (grossWeight * BasisQuantity) / SourcePosition_tuple.POS_FINAL_QUANTITY);
        netWeight    := abs( (netWeight * BasisQuantity) / SourcePosition_tuple.POS_FINAL_QUANTITY);
      end if;
    end if;

    -- Status de la position
    if SourcePosition_tuple.C_GAUGE_TYPE_POS in('4', '5', '6') then
      PositionStatus  := '04';
    else
      if    ConfirmStatus = 1
         or DOC_LIB_DOCUMENT.IsCreditLimit(aTargetDocumentId) then
        if TargetDocument_tuple.C_DOCUMENT_STATUS in('02', '03') then
          PositionStatus  := '02';
        else
          PositionStatus  := '01';
        end if;
      else
        if BalanceStatus = 1 then
          PositionStatus  := '02';
        else
          PositionStatus  := '04';
        end if;
      end if;
    end if;

    --raise_application_error(-20000,'targetlocation : '||to_char(cdaLocationId)||'/'||to_char(SourcePosition_tuple.stm_location_id));
    if     (AlreadyLoadComplData = 0)
       and (GaugeCopy_tuple.GAC_TRANSFERT_STOCK = 0) then
      if TargetAdminDomain = '2' then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '2'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   -- aOperationID
                                                , 0   -- aTransProprietor
                                                , null   -- aComplDataID
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      elsif TargetAdminDomain in('1', '5') then
        GCO_I_LIB_COMPL_DATA.GetComplementaryData(SourcePosition_tuple.GCO_GOOD_ID
                                                , '1'
                                                , TargetDocument_tuple.PAC_THIRD_CDA_ID
                                                , TargetDocument_tuple.PC_LANG_ID
                                                , null   -- aOperationID
                                                , 0   -- aTransProprietor
                                                , null   -- aComplDataID
                                                , cdaStockId
                                                , cdaLocationId
                                                , cdaReference
                                                , cdaSecondaryReference
                                                , cdaShortDescription
                                                , cdaLongDescription
                                                , cdaFreeDescription
                                                , cdaEanCode
                                                , cdaEanUCC14Code
                                                , cdaHIBCPrimaryCode
                                                , cdaDicUnitOfMeasureId
                                                , cdaConvertFactor
                                                , cdaNumberOfDecimal
                                                , cdaQuantity
                                                 );
        AlreadyLoadComplData         := 1;
        AlreadyLoadDecimalComplData  := 1;
      end if;
    end if;

    TargetStockId                := GapStockId;
    TargetLocationId             := GapLocationId;
    TargetStock2Id               := GapStockId2;
    TargetLocation2Id            := GapLocationId2;
    lnSourceSupplierID           := null;
    lnTargetSupplierID           := null;

    -- Reprise du stock et emplacement de transfert si la position a le stock propriétaire
    -- et qu'il y a la reprise du stock dans le flux
    if     (GaugeCopy_tuple.gac_transfert_stock = 1)
       and (SourcePosition_tuple.gap_transfert_proprietor = 1) then
      TargetStock2Id     := SourcePosition_tuple.stm_stm_stock_id;   /* Stock cible parent */
      TargetLocation2Id  := SourcePosition_tuple.stm_stm_location_id;   /* Emplacement cible parent */
    elsif(lnGapSubcontractStock = 1) then   -- Demande d'initialisation du stock source avec le stock du sous-traitant
      lnSourceSupplierID  := TargetDocument_tuple.PAC_THIRD_CDA_ID;
    elsif(lnGapStmSubcontractStock = 1) then   -- Demande d'initialisation du stock cible avec le stock du sous-traitant
      lnTargetSupplierID  := TargetDocument_tuple.PAC_THIRD_CDA_ID;
    end if;

    DOC_LIB_POSITION.getStockAndLocation(SourcePosition_tuple.GCO_GOOD_ID   /* Bien */
                                       , TargetDocument_tuple.PAC_THIRD_ID
                                       , TargetMovementKindId   /* Genre de mouvement */
                                       , TargetAdminDomain
                                       , cdaStockId   /* Stock du bien (données complémentaires) */
                                       , cdaLocationId   /* Emplacement du bien (données complémentaires) */
                                       , SourcePosition_tuple.stm_stock_id   /* Stock parent */
                                       , SourcePosition_tuple.stm_location_id   /* Emplacement parent */
                                       , SourcePosition_tuple.stm_stm_stock_id   /* Stock cible parent */
                                       , SourcePosition_tuple.stm_stm_location_id   /* Emplacement cible parent */
                                       , InitStockAndLocation   /* Initialisation du stock et de l'emplacement */
                                       , InitMovement   /* Utilisation du stock du genre de mouvement */
                                       , GaugeCopy_tuple.gac_transfert_stock   /* Transfert stock et emplacement depuis le parent */
                                       , lnSourceSupplierID   /* Sous-traitant permettant l'initialisation du stock source */
                                       , lnTargetSupplierID   /* Sous-traitant permettant l'initialisation du stock cible */
                                       , TargetStockId   /* Stock recherché */
                                       , TargetLocationId   /* Emplacement recherché */
                                       , TargetStock2Id   /* Stock cible recherché */
                                       , TargetLocation2Id   /* Emplacement cible recherché */
                                        );

    ---
    -- Définit les mêmes stock et emplacement source et cible dans le cas des
    -- positions Assemblage pour autant que le mouvement lié à la position
    -- soit de type transfert.
    --

    -- Recherche le mouvement lié au mouvement de la position
    if TargetMovementKindId is not null then
      select STM_STM_MOVEMENT_KIND_ID
        into LinkMovementKindID
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = TargetMovementKindId;
    end if;

    if     SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8')
       and LinkMovementKindID is not null then
      TargetStock2Id     := TargetStockId;
      TargetLocation2Id  := TargetLocationId;
    end if;

    -- Forcer la reprise des caractérisations
    -- si le flag de transfert est actif et que l'on a
    --  affaire à un mouvement de transfert ou que le domaine d'administration soit différent (vente-achat)
    if     (GaugeCopy_tuple.GAC_TRANSFERT_CHARACT = 1)
       and (    (    (nvl(LinkMovementKindID, 0) <> 0)
                 or (TargetAdminDomain <> SourceAdminDomain) )
            or (    DOC_I_LIB_GAUGE.IsGaugeReceiptable(TargetDocument_tuple.DOC_GAUGE_ID) = 0
                and TargetMovementKindId is null)
           ) then
      ForceTransfertCharact  := 1;
    else
      ForceTransfertCharact  := 0;
    end if;

    -- recherche du coef d'utilisation des composants position kit
    if SourcePosition_tuple.DOC_DOC_POSITION_ID is not null then
      UtilCoef  := SourcePosition_tuple.POS_UTIL_COEFF;
    end if;

    -- recherche des données complémentaires obligatoires ou interdites
    DOC_INFO_COMPL.GetUsedInfoCompl(aTargetDocumentId
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

    ----
    -- Définission du flag de création des poids matières précieuses
    --
    if (gasWeightMat = 1) then
      posCreateMat  := 1;   -- Matières à créer
    else
      posCreateMat  := 0;   -- Matières pas gérées
    end if;

    -- recherche de la valeur de la nouvelle position
    select init_id_seq.nextval
      into aTargetPositionId
      from dual;

    -- Copie du fal_lot_id dans le cas de copie de BRAST ou BRCAST en FFAST
    if     DOC_I_LIB_SUBCONTRACTP.IsSUPRSGauge(SourcePosition_tuple.DOC_GAUGE_ID) = 1
       and DOC_I_LIB_SUBCONTRACTP.IsSUPIGauge(TargetDocument_tuple.DOC_GAUGE_ID) = 1 then
      nFalLotId  := SourcePosition_tuple.FAL_LOT_ID;
    else
      nFalLotId  := null;
    end if;

    insert into DOC_POSITION
                (DOC_POSITION_ID
               , DOC_DOCUMENT_ID
               , DOC_DOC_POSITION_ID
               , PAC_REPRESENTATIVE_ID
               , PAC_REPR_ACI_ID
               , PAC_REPR_DELIVERY_ID
               , C_GAUGE_TYPE_POS
               , C_DOC_POS_STATUS
               , GCO_GOOD_ID
               , DOC_GAUGE_POSITION_ID
               , DOC_RECORD_ID
               , DOC_DOC_RECORD_ID
               , PAC_PERSON_ID
               , ASA_RECORD_ID
               , ASA_RECORD_COMP_ID
               , ASA_RECORD_TASK_ID
               , STM_STOCK_ID
               , STM_STM_STOCK_ID
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , STM_MOVEMENT_KIND_ID
               , ACS_TAX_CODE_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , POS_NUMBER
               , POS_GENERATE_MOVEMENT
               , POS_STOCK_OUTAGE
               , POS_REFERENCE
               , POS_SECONDARY_REFERENCE
               , POS_SHORT_DESCRIPTION
               , POS_LONG_DESCRIPTION
               , POS_FREE_DESCRIPTION
               , POS_BODY_TEXT
               , POS_NOM_TEXT
               , DIC_UNIT_OF_MEASURE_ID
               , DIC_DIC_UNIT_OF_MEASURE_ID
               , POS_EAN_CODE
               , POS_EAN_UCC14_CODE
               , POS_HIBC_PRIMARY_CODE
               , POS_CONVERT_FACTOR
               , POS_CONVERT_FACTOR2
               , POS_NET_WEIGHT
               , POS_GROSS_WEIGHT
               , POS_BASIS_QUANTITY
               , POS_INTERMEDIATE_QUANTITY
               , POS_FINAL_QUANTITY
               , POS_VALUE_QUANTITY
               , POS_BALANCE_QUANTITY
               , POS_BALANCE_QTY_VALUE
               , POS_BASIS_QUANTITY_SU
               , POS_INTERMEDIATE_QUANTITY_SU
               , POS_FINAL_QUANTITY_SU
               , POS_INCLUDE_TAX_TARIFF
               , POS_REF_UNIT_VALUE
               , POS_UNIT_COST_PRICE
               , POS_GROSS_UNIT_VALUE
               , POS_GROSS_UNIT_VALUE2
               , POS_GROSS_UNIT_VALUE_INCL
               , POS_GROSS_VALUE
               , POS_GROSS_VALUE_INCL
               , POS_NET_UNIT_VALUE
               , POS_NET_UNIT_VALUE_INCL
               , POS_NET_VALUE_EXCL
               , POS_NET_VALUE_INCL
               , POS_DATE_DELIVERY
               , POS_VAT_RATE
               , POS_VAT_LIABLED_RATE
               , POS_VAT_LIABLED_AMOUNT
               , POS_VAT_TOTAL_AMOUNT
               , POS_VAT_DEDUCTIBLE_RATE
               , POS_VAT_AMOUNT
               , POS_NET_TARIFF
               , POS_SPECIAL_TARIFF
               , POS_FLAT_RATE
               , POS_EFFECTIVE_DIC_TARIFF_ID
               , DIC_TARIFF_ID
               , POS_TARIFF_UNIT
               , POS_TARIFF_SET
               , POS_TARIFF_INITIALIZED
               , POS_UPDATE_TARIFF
               , POS_MODIFY_RATE
               , PC_APPLTXT_ID
               , POS_DISCOUNT_UNIT_VALUE
               , POS_DISCOUNT_RATE
               , POS_UTIL_COEFF
               , POS_PARENT_CHARGE
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
               , POS_PARTNER_NUMBER
               , POS_PARTNER_REFERENCE
               , POS_DATE_PARTNER_DOCUMENT
               , POS_PARTNER_POS_NUMBER
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
               , POS_IMF_DATE_1
               , POS_IMF_DATE_2
               , POS_IMF_DATE_3
               , POS_IMF_DATE_4
               , POS_IMF_DATE_5
               , POS_TARIFF_DATE
               , C_POS_CREATE_MODE
               , POS_ADDENDUM_SRC_POS_ID
               , POS_ADDENDUM_QTY_BALANCED
               , POS_ADDENDUM_VALUE_QTY
               , POS_CREATE_MAT
               , C_DOC_LOT_TYPE
               , GCO_MANUFACTURED_GOOD_ID
               , GCO_COMPL_DATA_ID
               , FAL_LOT_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (aTargetPositionId   -- DOC_POSITION_ID
               , aTargetDocumentId   -- DOC_DOCUMENT_ID
               , aPdtTargetPositionId   -- DOC_DOC_POSITION_ID
               , decode(GaugeCopy_tuple.gac_transfert_represent
                      , 0, TargetDocument_tuple.PAC_REPRESENTATIVE_ID
                      , nvl(SourcePosition_tuple.PAC_REPRESENTATIVE_ID, TargetDocument_tuple.PAC_REPRESENTATIVE_ID)
                       )   -- PAC_REPRESENTATIVE_ID
               , decode(GaugeCopy_tuple.gac_transfert_represent
                      , 0, TargetDocument_tuple.PAC_REPR_ACI_ID
                      , nvl(SourcePosition_tuple.PAC_REPR_ACI_ID, TargetDocument_tuple.PAC_REPR_ACI_ID)
                       )   -- PAC_REPR_ACI_ID
               , decode(GaugeCopy_tuple.gac_transfert_represent
                      , 0, TargetDocument_tuple.PAC_REPR_DELIVERY_ID
                      , nvl(SourcePosition_tuple.PAC_REPR_DELIVERY_ID, TargetDocument_tuple.PAC_REPR_DELIVERY_ID)
                       )   -- PAC_REPR_DELIVERY_ID
               , SourcePosition_tuple.c_gauge_type_pos   -- C_GAUGE_TYPE_POS
               , PositionStatus   -- C_DOC_POS_STATUS
               , SourcePosition_tuple.GCO_GOOD_ID   -- GCO_GOOD_ID
               , TargetGaugePositionId   -- DOC_GAUGE_POSITION_ID
               , TargetRecordId   -- DOC_RECORD_ID
               , TargetDocDocRecordId   -- DOC_DOC_RECORD_ID
               , TargetPersonId   -- PAC_PERSON_ID
               , SourcePosition_tuple.ASA_RECORD_ID   -- ASA_RECORD_ID
               , SourcePosition_tuple.ASA_RECORD_COMP_ID
               , SourcePosition_tuple.ASA_RECORD_TASK_ID
               , TargetStockId   -- STM_STOCK_ID
               , TargetStock2Id   -- STM_STM_STOCK_ID
               , TargetLocationId   -- STM_LOCATION_ID
               , TargetLocation2Id   -- STM_STM_LOCATION_ID
               , TargetMovementKindId   -- STM_MOVEMENT_KIND_ID
               , TargetTaxCodeId   -- ACS_TAX_CODE_ID
               , TargetFinAccountId   -- ACS_FINANCIAL_ACCOUNT_ID
               , TargetDivAccountId   -- ACS_DIVISION_ACCOUNT_ID
               , TargetCpnAccountId   -- ACS_CPN_ACCOUNT_ID
               , TargetCdaAccountId   -- ACS_CDA_ACCOUNT_ID
               , TargetPfAccountId   -- ACS_PF_ACCOUNT_ID
               , TargetPjAccountId   -- ACS_PJ_ACCOUNT_ID
               , GetNextPosNumber(PosFirstNo, PosIncrement)   -- POS_NUMBER
               , 0   -- POS_GENERATE_MOVEMENT
               , 0   -- POS_STOCK_OUTAGE
               , reference   -- POS_REFERENCE
               , SecondaryReference   -- POS_SECONDARY_REFERENCE
               , ShortDescription   -- POS_SHORT_DESCRIPTION
               , LongDescription   -- POS_LONG_DESCRIPTION
               , FreeDescription   -- POS_FREE_DESCRIPTION
               , BodyText   -- POS_BODY_TEXT
               , 0   -- POS_NOM_TEXT
               , DicUnitOfMeasureId   -- DIC_UNIT_OF_MEASURE_ID
               , DicDicUnitOfMeasureId   -- DIC_DIC_UNIT_OF_MEASURE_ID
               , EanCode   -- POS_EAN_CODE
               , EanUCC14Code   -- POS_EAN_UCC14_CODE
               , HIBCPrimaryCode   -- POS_HIBC_PRIMARY_CODE
               , nvl(ConvertFactor, 1)   -- POS_CONVERT_FACTOR
               , nvl(ConvertFactor2, 1)   -- POS_CONVERT_FACTOR2
               , NetWeight   -- POS_NET_WEIGHT
               , GrossWeight   -- POS_GROSS_WEIGHT
               , BasisQuantity   -- POS_BASIS_QUANTITY
               , IntermediateQuantity   -- POS_INTERMEDIATE_QUANTITY
               , FinalQuantity   -- POS_FINAL_QUANTITY
               , valueQuantity   -- POS_VALUE_QUANTITY
               , decode(BalanceStatus, 1, BasisQuantity, 0)   -- POS_BALANCE_QUANTITY
               , decode(BalanceStatus, 1, valueQuantity, 0)   -- POS_BALANCE_QTY_VALUE
               , ACS_FUNCTION.RoundNear(BasisQuantity * ConvertFactor, 1 / power(10, SourcePosition_tuple.GOO_NUMBER_OF_DECIMAL), 1)   -- POS_BASIS_QUANTITY_SU
               , ACS_FUNCTION.RoundNear(IntermediateQuantity * ConvertFactor, 1 / power(10, SourcePosition_tuple.GOO_NUMBER_OF_DECIMAL), 1)   -- POS_INTERMEDIATE_QUANTITY_SU
               , ACS_FUNCTION.RoundNear(FinalQuantity * ConvertFactor, 1 / power(10, SourcePosition_tuple.GOO_NUMBER_OF_DECIMAL), 1)   -- POS_FINAL_QUANTITY_SU
               , IncludeTaxTariff   -- POS_INCLUDE_TAX_TARIFF
               , RefUnitValue   -- POS_REF_UNIT_VALUE
               , UnitCostPrice   -- POS_UNIT_COST_PRICE
               , GrossUnitValue   -- POS_GROSS_UNIT_VALUE
               , GrossUnitValue2   -- POS_GROSS_UNIT_VALUE2
               , GrossUnitValueIncl   -- POS_GROSS_UNIT_VALUE_INCL
               , GrossValue   -- POS_GROSS_VALUE
               , GrossValueIncl   -- POS_GROSS_VALUE_INCL
               , NetUnitValue   -- POS_NET_UNIT_VALUE
               , NetUnitValueIncl   -- POS_NET_UNIT_VALUE_INCL
               , NetValueExcl   -- POS_NET_VALUE_EXCL
               , NetValueIncl   -- POS_NET_VALUE_INCL
               , SourcePosition_tuple.POS_DATE_DELIVERY   -- POS_DATE_DELIVERY
               , VatRate   -- POS_VAT_RATE
               , VatLiabledRate   -- POS_VAT_LIABLED_RATE
               , VatLiabledAmount   -- POS_VAT_LIABLED_AMOUNT
               , VatTotalAmount   -- POS_VAT_TOTAL_AMOUNT
               , VatDeductibleRate   -- POS_VAT_DEDUCTIBLE_RATE
               , VatAmount   -- POS_VAT_AMOUNT
               , nvl(PosNetTariff, 0)   -- POS_NET_TARIFF
               , nvl(PosSpecialTariff, 0)   -- POS_SPECIAL_TARIFF
               , nvl(PosFlatRate, 0)   -- POS_FLAT_RATE
               , vEffectiveDicTariffId
               , dicTariffId
               , PosTariffUnit
               , PosTariffSet
               , decode(dicTariffId, null, 0, decode(IncludeTaxTariff, 1, GrossUnitValueIncl, GrossUnitValue) ) * PosTariffUnit   -- POS_TARIFF_INITIALIZED
               , PosUpdateTariff
               , 1   -- POS_MODIFY_RATE
               , SourcePosition_tuple.PC_APPLTXT_ID   -- PC_APPLTXT_ID
               , DiscountUnitValue   -- POS_DISCOUNT_UNIT_VALUE
               , DiscountRate   -- POS_DISCOUNT_RATE
               , UtilCoef   -- POS_UTIL_COEFF
               , GaugeCopy_tuple.GAC_TRANSFERT_REMISE_TAXE
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA
                      , 1, SourcePosition_tuple.DIC_POS_FREE_TABLE_1_ID
                      , TargetDocument_tuple.DIC_POS_FREE_TABLE_1_ID
                       )   -- DIC_POS_FREE_TABLE_1_ID
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA
                      , 1, SourcePosition_tuple.DIC_POS_FREE_TABLE_2_ID
                      , TargetDocument_tuple.DIC_POS_FREE_TABLE_2_ID
                       )   -- DIC_POS_FREE_TABLE_2_ID
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA
                      , 1, SourcePosition_tuple.DIC_POS_FREE_TABLE_3_ID
                      , TargetDocument_tuple.DIC_POS_FREE_TABLE_3_ID
                       )   -- DIC_POS_FREE_TABLE_3_ID
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DECIMAL_1, TargetDocument_tuple.DMT_DECIMAL_1)   -- POS_DECIMAL_1
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DECIMAL_2, TargetDocument_tuple.DMT_DECIMAL_2)   -- POS_DECIMAL_2
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DECIMAL_3, TargetDocument_tuple.DMT_DECIMAL_3)   -- POS_DECIMAL_3
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_TEXT_1, TargetDocument_tuple.DMT_TEXT_1)   -- POS_TEXT_1
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_TEXT_2, TargetDocument_tuple.DMT_TEXT_2)   -- POS_TEXT_2
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_TEXT_3, TargetDocument_tuple.DMT_TEXT_3)   -- POS_TEXT_3
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DATE_1, TargetDocument_tuple.DMT_DATE_1)   -- POS_DATE_1
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DATE_2, TargetDocument_tuple.DMT_DATE_2)   -- POS_DATE_2
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_FREE_DATA, 1, SourcePosition_tuple.POS_DATE_3, TargetDocument_tuple.DMT_DATE_3)   -- POS_DATE_3
               , nvl(SourcePosition_tuple.POS_PARTNER_NUMBER, TargetDocument_tuple.DMT_PARTNER_NUMBER)
               , nvl(SourcePosition_tuple.POS_PARTNER_REFERENCE, TargetDocument_tuple.DMT_PARTNER_REFERENCE)
               , nvl(SourcePosition_tuple.POS_DATE_PARTNER_DOCUMENT, TargetDocument_tuple.DMT_DATE_PARTNER_DOCUMENT)
               , SourcePosition_tuple.POS_PARTNER_POS_NUMBER
               , ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
               , vAccountInfo.FAM_FIXED_ASSETS_ID
               , vAccountInfo.C_FAM_TRANSACTION_TYP
               , vAccountInfo.DEF_TEXT1
               , vAccountInfo.DEF_TEXT2
               , vAccountInfo.DEF_TEXT3
               , vAccountInfo.DEF_TEXT4
               , vAccountInfo.DEF_TEXT5
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
               , decode(GaugeCopy_tuple.GAC_TRANSFERT_PRICE, 1, SourcePosition_tuple.POS_TARIFF_DATE)
               , SourcePosition_tuple.C_PDE_CREATE_MODE
               , decode(SourcePosition_tuple.C_PDE_CREATE_MODE, '215', SourcePosition_tuple.POS_ADDENDUM_SRC_POS_ID, null)   -- POS_ADDENDUM_SRC_POS_ID
               , decode(SourcePosition_tuple.C_PDE_CREATE_MODE, '215', SourcePosition_tuple.POS_BALANCE_QUANTITY, null)   -- POS_ADDENDUM_QTY_BALANCED
               , decode(SourcePosition_tuple.C_PDE_CREATE_MODE, '215', SourcePosition_tuple.POS_BALANCE_QTY_VALUE, null)   -- POS_ADDENDUM_VALUE_QTY
               , posCreateMat   -- POS_CREATE_MAT
               , lvCDocLotType
               , SourcePosition_tuple.GCO_MANUFACTURED_GOOD_ID
               , SourcePosition_tuple.GCO_COMPL_DATA_ID
               , nFalLotId
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                );

    CopyPositionDetail(aSourcePositionId
                     , aTargetPositionId
                     , SourcePosition_tuple.GCO_GOOD_ID
                     , aTargetDocumentId
                     , SourcePosition_tuple.DOC_GAUGE_ID
                     , TargetDocument_tuple.DOC_GAUGE_ID
                     , ConvertFactor
                     , SourceCurrencyId
                     , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                     , TargetAdminDomain
                     , GaugeCopy_tuple.DOC_GAUGE_COPY_ID
                     , TargetDocument_tuple.DMT_DATE_DOCUMENT
                     , SourcePosition_tuple.doc_gauge_flow_id
                     , GaugeCopy_tuple.GAC_INIT_QTY_MVT
                     , GaugeCopy_tuple.GAC_INIT_PRICE_MVT
                     , GaugeCopy_tuple.GAC_TRANSFERT_STOCK
                     , GaugeCopy_tuple.GAC_TRANSFERT_QUANTITY
                     , SourceGestDelay
                     , GestDelay
                     , DelayUpdateType
                     , ParentGestChar
                     , GestChar
                     , ForceTransfertCharact
                     , InitMovement
                     , UnitCostPrice
                     , NetUnitValue
                     , TargetMovementKindId
                     , SourcePosition_tuple.C_GAUGE_TYPE_POS
                     , TargetStockId
                     , TargetLocationId
                     , TargetLocation2Id
                     , SourcePosition_tuple.DCD_QUANTITY
                     , SourcePosition_tuple.POS_BALANCE_QTY_VALUE
                     , BalanceStatus
                     , SourcePosition_tuple.GOO_NUMBER_OF_DECIMAL
                     , cdaNumberOfDecimal
                     , aInputIdList
                     , aCopyInfoCode
                     , SourcePosition_tuple.GCO_COMPL_DATA_ID
                      );

    ----
    -- Traitement des poids matières précieuses
    --
    if     (srcWeightMat = 1)
       and (gasWeightMat = 1)
       and (GaugeCopy_tuple.GAC_TRANSFERT_PRECIOUS_MAT = 1) then
      DOC_POSITION_ALLOY_FUNCTIONS.CreatePositionMatFromParent(aTargetPositionID, aSourcePositionId, 'COPY');
    elsif(gasWeightMat = 1) then
      DOC_POSITION_ALLOY_FUNCTIONS.GeneratePositionMat(aTargetPositionId);
    end if;

    -- remise et taxes (seulement pour certains types)
    -- Les remises/taxes ne doivent être ni crées ni reprises du parent dans
    -- les modes de copie 205 et 206
    if     SourcePosition_tuple.C_GAUGE_TYPE_POS not in('4', '5', '71', '81', '9', '101')
       and SourcePosition_tuple.C_PDE_CREATE_MODE not in('205', '206') then
      if GaugeCopy_tuple.GAC_TRANSFERT_REMISE_TAXE = 1 then
        lnLocalCurrency  := ACS_FUNCTION.GetLocalCurrencyId;

        if     (TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID <> SourceCurrencyId)
           and (   TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID = lnLocalCurrency
                or SourceCurrencyId = lnLocalCurrency) then
          -- Si changement de monnaie entre le document source et le cible, il faut convertir les remises/taxes en montant fixe de la position père
          -- Attention, uniquement si une des monnaies est la monnaie locale.
          -- Exemple : FF en CHF et ND en EUR ou l'inverse mais pas: FF en EUR et ND en USD.
          lnConvertAmount  := 1;
        else
          -- Dans le cas contraire, les montants fixes des remises/taxes de position sont repris tel quel.
          lnConvertAmount  := 0;
        end if;

        -- copie des remises/taxes du parent
        DOC_DISCOUNT_CHARGE.CopyPositionCharge(aTargetPositionId
                                             , aSourcePositionId
                                             , TargetDocument_tuple.DMT_DATE_DOCUMENT
                                             , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                             , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                             , TargetDocument_tuple.DMT_BASE_PRICE
                                             , 0   -- NE PAS mettre à jour le montant solde sur taxe parent
                                             , 1   -- reprendre les taxes opération de sous-traitance
                                             , ChargeCreated
                                             , ChargeAmount
                                             , DiscountAmount
                                             , lnConvertAmount
                                              );
      else
        -- création des remises/taxes depuis la base
        DOC_DISCOUNT_CHARGE.CreatePositionCharge(aTargetPositionId
                                               , nvl(TargetDocument_tuple.DMT_TARIFF_DATE, TargetDocument_tuple.DMT_DATE_DOCUMENT)
                                               , TargetDocument_tuple.ACS_FINANCIAL_CURRENCY_ID
                                               , TargetDocument_tuple.DMT_RATE_OF_EXCHANGE
                                               , TargetDocument_tuple.DMT_BASE_PRICE
                                               , TargetDocument_tuple.PC_LANG_ID
                                               , ChargeCreated
                                               , ChargeAmount
                                               , DiscountAmount
                                                );
      end if;
    end if;

    -- si des remises/taxes ont été créées ou copiées, on recalcul les montants sur le document
    if ChargeCreated = 1 then
      DOC_POSITION_FUNCTIONS.UpdatePosAmountsDiscountCharge(aTargetPositionId
                                                          , nvl(TargetDocument_tuple.DMT_DATE_DELIVERY, TargetDocument_tuple.DMT_DATE_VALUE)
                                                          , IncludeTaxTariff
                                                          , ChargeAmount
                                                          , DiscountAmount
                                                           );
    end if;

    -- Mise à jour des montants de budget
    if     (PCS.PC_CONFIG.GetConfig('DOC_ENABLE_BUDGET') = '1')
       and (IncludeBudgetControl = 1) then
      DOC_BUDGET_FUNCTIONS.UpdatePosBudgetAmounts(aTargetPositionId);
    end if;

    -- Création des éventuelles imputations position
    if     (SourcePosition_tuple.POS_IMPUTATION = 1)
       and (srcRecordImputation = 1)
       and (gasRecordImputation = 1) then
      DOC_IMPUTATION_FUNCTIONS.CopyPositionImputations(aTargetDocumentId, aTargetPositionId, SourcePosition_tuple.DOC_DOCUMENT_ID, aSourcePositionId);
    end if;

    -- Composants positions Kit et Assemblage
    if SourcePosition_tuple.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
      open ComponentPosition(aSourcePositionId, aTargetDocumentId);

      fetch ComponentPosition
       into ComponentPositionId;

      lbProcessingCPT  := ComponentPosition%found;

      while ComponentPosition%found loop
        CopyPosition(ComponentPositionId
                   , aTargetDocumentId
                   , aSourcePositionId
                   , aTargetPositionId
                   , SourcePosition_tuple.DOC_GAUGE_FLOW_ID
                   , aInputIdList
                   , TargetPositionId
                   , aCopyInfoCode
                    );

        fetch ComponentPosition
         into ComponentPositionId;
      end loop;

      -- Mise à jour du composé lorsque l'on traite un type de position avec valeur PT égal somme CPT.
      if     (SourcePosition_tuple.C_GAUGE_TYPE_POS = '8')
         and lbProcessingCPT then
        DOC_POSITION_FUNCTIONS.UpdatePositionPTAmounts(aTargetPositionId);
      end if;
    end if;

    -- Attributions....
    -- Recherche les infos au niveau du gabarit pour les attributions auto.
    select GAU.C_GAUGE_TYPE
         , nvl(GAS.GAS_AUTO_ATTRIBUTION, 0)
      into cGaugeType
         , gasAutoAttrib
      from DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
     where GAU.DOC_GAUGE_ID = TargetDocument_tuple.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;

    -- teste si les conditions sont remplies pour créer automatiquement les attributions
    if     cGaugeType = '1'
       and gasAutoAttrib = 1 then
      -- création des attributions pour la positions créée
      FAL_REDO_ATTRIBS.ReDoAttribsByDocOrPOS(null, aTargetPositionId);
    end if;

    -- Copie des pièces jointes
    if GaugeCopy_tuple.GAC_TRSF_LINKED_FILES = 1 then
      COM_FUNCTIONS.DuplicateImageFiles('DOC_POSITION', aSourcePositionId, aTargetPositionId);
    end if;

    close SourcePosition;
  end CopyPosition;
end DOC_COPY_DISCHARGE;
