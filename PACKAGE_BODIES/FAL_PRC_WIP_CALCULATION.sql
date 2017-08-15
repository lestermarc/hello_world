--------------------------------------------------------
--  DDL for Package Body FAL_PRC_WIP_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_WIP_CALCULATION" 
is
  /**
  * procedure SelectBatches
  * Description : Sélection des lots de fabrication à charger, pour un calcul des
  *               en-cours par groupe de lots
  * @created ECA 07.03.2011
  * @lastUpdate
  * @public
  * @param   iJopReferenceFrom : Programme de
  * @param   iJopReferenceTo : Programme à
  * @param   iJobProgramDocID : Commande du programme
  * @param   iOrderDocID : Commande de l'ordre
  * @param   iDocRecord : Dossier
  * @param   iDicAccountableGroupId : Groupe de responsable
  * @param   iGoodId : Bien
  * @param   iDicFamilyId : famille
  * @param   iCPriorityFrom : Priorité de
  * @param   iCPriorityTo : Priorité à
  * @param   iPlanEndDateFrom : Date fin de
  * @param   iPlanEndDateTo : Date fin à
  */
  procedure SelectBatches(
    iJopReferenceFrom      in varchar2 default null
  , iJopReferenceTo        in varchar2 default null
  , iJobProgramDocID       in number default null
  , iOrderDocID            in number default null
  , iDocRecordId           in number default null
  , iDicAccountableGroupId in varchar2 default null
  , iGoodId                in number default null
  , iDicFamilyId           in varchar2 default null
  , iCPriorityFrom         in varchar2 default null
  , iCPriorityTo           in varchar2 default null
  , iPlanEndDateFrom       in date default null
  , iPlanEndDateTo         in date default null
  )
  is
  begin
    -- suppression des lots déjà sélectionnés
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'WIP_SELECTED_BATCHES';

    -- Sélection des lots selons les critères définis
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select   LOT.FAL_LOT_ID
             , 'WIP_SELECTED_BATCHES'
          from FAL_LOT LOT
             , GCO_GOOD GCO
         where LOT.C_LOT_STATUS in('2', '4')
           and LOT.GCO_GOOD_ID = GCO.GCO_GOOD_ID
           -- Programme de ... à
           and (    (    iJopReferenceFrom is null
                     and iJopReferenceTo is null)
                or (LOT.FAL_JOB_PROGRAM_ID in(
                      select JOP.FAL_JOB_PROGRAM_ID
                        from FAL_JOB_PROGRAM JOP
                       where (   iJopReferenceFrom is null
                              or JOP.JOP_REFERENCE >= iJopReferenceFrom)
                         and (   iJopReferenceTo is null
                              or JOP.JOP_REFERENCE <= iJopReferenceTo) )
                   )
               )
           -- Commande du programme
           and (   nvl(iJobProgramDocID, 0) = 0
                or LOT.FAL_JOB_PROGRAM_ID in(select FAL_JOB_PROGRAM_ID
                                               from FAL_JOB_PROGRAM JOP
                                              where JOP.DOC_DOCUMENT_ID = iJobProgramDocID) )
           -- Commande de l'ordre
           and (   nvl(iOrderDocID, 0) = 0
                or LOT.FAL_ORDER_ID in(select FAL_ORDER_ID
                                         from FAL_ORDER ORD
                                        where ORD.DOC_DOCUMENT_ID = iOrderDocID) )
           -- Dossier
           and (   nvl(iDocRecordId, 0) = 0
                or LOT.DOC_RECORD_ID = iDocRecordId)
           -- Groupe de responsable
           and (   iDicAccountableGroupId is null
                or GCO.DIC_ACCOUNTABLE_GROUP_ID = iDicAccountableGroupId)
           -- Produit
           and (   nvl(iGoodId, 0) = 0
                or GCO.GCO_GOOD_ID = iGoodId)
           -- Famille
           and (   iDicFamilyId is null
                or LOT.DIC_FAMILY_ID = iDicFamilyId)
           -- Priorités de ... à
           and (   iCPriorityFrom is null
                or LOT.C_PRIORITY >= iCPriorityFrom)
           and (   iCPriorityTo is null
                or LOT.C_PRIORITY <= iCPriorityTo)
           -- Dates fin de ... à
           and (   iPlanEndDateFrom is null
                or LOT.LOT_PLAN_END_DTE >= iPlanEndDateFrom)
           and (   iPlanEndDateTo is null
                or LOT.LOT_PLAN_END_DTE <= iPlanEndDateTo)
      order by GCO.GOO_MAJOR_REFERENCE
             , LOT.LOT_REFCOMPL;
  end SelectBatches;

  /**
  * procedure SelectSSTABatches
  * Description : Sélection des lots de fabrication de sous-traitance d'achat à
  *               charger, pour un calcul de post-calculation par groupe
  *
  * @created ECA 07.03.2011
  * @lastUpdate
  * @public
  * @param   iGcoMajorReferenceFrom : Produit de
  * @param   iGcoMajorReferenceTo : Produit à
  * @param   iDmtNumberFrom : Document de
  * @param   iDmtNumberTo : Document à
  * @param   iDocRecordFrom : Dossier de
  * @param   iDocRecordTo Dossier à
  * @param   iGcoServiceFrom : Service lié de
  * @param   iGcoServiceTo : Service lié à
  * @param   iConfirmDateFrom : Date confirmation de
  * @param   iConfirmDateTo : Date confirmation à
  */
  procedure SelectSSTABatches(
    iGcoMajorReferenceFrom in varchar2 default null
  , iGcoMajorReferenceTo   in varchar2 default null
  , iDmtNumberFrom         in varchar2 default null
  , iDmtNumberTo           in varchar2 default null
  , iDocRecordFrom         in varchar2 default null
  , iDocRecordTo           in varchar2 default null
  , iGcoServiceFrom        in varchar2 default null
  , iGcoServiceTo          in varchar2 default null
  , iConfirmDateFrom       in date default null
  , iConfirmDateTo         in date default null
  )
  is
    lnDOC_GAUGE_ID number;
  begin
    FAL_I_PRC_POST_CALCULATION.SelectSSTABatches(iGcoMajorReferenceFrom   => iGcoMajorReferenceFrom
                                               , iGcoMajorReferenceTo     => iGcoMajorReferenceTo
                                               , iDmtNumberFrom           => iDmtNumberFrom
                                               , iDmtNumberTo             => iDmtNumberTo
                                               , iDocRecordFrom           => iDocRecordFrom
                                               , iDocRecordTo             => iDocRecordTo
                                               , iGcoServiceFrom          => iGcoServiceFrom
                                               , iGcoServiceTo            => iGcoServiceTo
                                               , iConfirmDateFrom         => iConfirmDateFrom
                                               , iConfirmDateTo           => iConfirmDateTo
                                               , iUnCalculatedBatches     => 0
                                               , iCalculableBatches       => 0
                                               , iBalancedBatches         => 0
                                               , iLaunchedBatches         => 1
                                               , iLidCode                 => 'WIP_SELECTED_BATCHES'
                                                );
  end SelectSSTABatches;

  /**
  * function SelectMaterialDatas
  * Description : Sélection des données pour le calcul des en-cours matière
  *
  * @Created ECA 29.05.2011
  * @lastUpdate
  * @Public
  * @param   iFalLotId : Lot de fabrication
  * @param   iComCodeSelection : Code de sélection dans la table COM
  */
  function SelectMaterialDatas(iFalLotId in number default null, iComCodeSelection varchar2 default null)
    return TTabSSTAMaterialData pipelined
  is
    vSQLQry varchar2(4000);
  begin
    vSQLQry  :=
      ' SELECT LOT.FAL_LOT_ID ' ||
      '      , LOM.GCO_GOOD_ID ' ||
      '      , LOM.LOM_NEED_QTY ' ||
      '      , LOM.FAL_LOT_MATERIAL_LINK_ID ' ||
      '      , 0 ' ||
      '      , LNK.FLN_QTY IN_QTE' ||
      '      , FACTOU.OUT_PRICE ' ||
      '      , FACTOU.OUT_QTE ' ||
      '      , GCO.GOO_NUMBER_OF_DECIMAL ' ||
      '      , GCO.DIC_GOOD_LINE_ID ' ||
      '      , GCO.DIC_GOOD_FAMILY_ID ' ||
      '      , GCO.DIC_GOOD_MODEL_ID ' ||
      '      , GCO.DIC_GOOD_GROUP_ID ' ||
      '      , GCF.DIC_FREE_TABLE_1_ID ' ||
      '      , GCF.DIC_FREE_TABLE_2_ID ' ||
      '      , GCF.DIC_FREE_TABLE_3_ID ' ||
      '      , GCF.DIC_FREE_TABLE_4_ID ' ||
      '      , GCF.DIC_FREE_TABLE_5_ID ' ||
      '      , FAL_PRECALC_TOOLS.GetGoodDisplayedRef(LOM.GCO_GOOD_ID) GCO_DESCRIPTION ' ||
      '      , LOM.C_KIND_COM ' ||
      '      , GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(LOM.GCO_GOOD_ID) IN_PRICE ' ||
      '      , NVL(LOT.LOT_RELEASED_QTY, 0) ' ||
      '      , NVL(LOT_REJECT_RELEASED_QTY, 0) ' ||
      '      , LOM.LOM_UTIL_COEF ' ||
      '      , LOM.LOM_REF_QTY  ' ||
      '      , LOM.LOM_FULL_REQ_QTY ' ||
      '   FROM FAL_LOT LOT ' ||
      '      , GCO_GOOD GCO ' ||
      '      , GCO_FREE_DATA GCF ' ||
      '      , FAL_LOT_MATERIAL_LINK LOM ' ||
      '      , (SELECT SUM (FLN_QTY) FLN_QTY ' ||
      '              , FNN.FAL_LOT_MATERIAL_LINK_ID ' ||
      '           FROM FAL_NETWORK_LINK FNL ' ||
      '              , FAL_NETWORK_NEED FNN ' ||
      '              , STM_STOCK_POSITION SPO ' ||
      '              , STM_STOCK STO ' ||
      '          WHERE FNN.FAL_LOT_MATERIAL_LINK_ID is not null ' ||
      '            AND FNN.FAL_NETWORK_NEED_ID = FNL.FAL_NETWORK_NEED_ID ' ||
      '            AND FNL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID ' ||
      '            AND SPO.STM_STOCK_ID = STO.STM_STOCK_ID ' ||
      '            AND STO.STO_SUBCONTRACT = 1 ' ||
      '            AND STO.PAC_SUPPLIER_PARTNER_ID IS NOT NULL ' ||
      '            AND ( (NVL (:iFalLotId, 0) <> 0 ' ||
      '                         AND FNN.FAL_LOT_ID = :iFalLotId) ' ||
      '                       OR (NVL (:iFalLotId, 0) = 0 ' ||
      '                           AND FNN.FAL_LOT_ID IN ' ||
      '                                  (SELECT COM.COM_LIST_ID_TEMP_ID ' ||
      '                                     FROM COM_LIST_ID_TEMP COM ' ||
      '                                    WHERE COM.LID_CODE = :iComCodeSelection))) ' ||
      '              group by FNN.FAL_LOT_MATERIAL_LINK_ID) LNK ' ||
      '      , (SELECT SUM (FOU.OUT_QTE * FOU.OUT_PRICE) OUT_PRICE ' ||
      '              , SUM (FOU.OUT_QTE) OUT_QTE ' ||
      '              , FOU.GCO_GOOD_ID ' ||
      '              , FOU.FAL_LOT_ID ' ||
      '           FROM FAL_FACTORY_OUT FOU ' ||
      '          WHERE FOU.C_OUT_TYPE IN (''1'', ''2'') ' ||
      '            AND ( (NVL (:iFalLotId, 0) <> 0 ' ||
      '                         AND FOU.FAL_LOT_ID = :iFalLotId) ' ||
      '                       OR (NVL (:iFalLotId, 0) = 0 ' ||
      '                           AND FOU.FAL_LOT_ID IN ' ||
      '                                  (SELECT COM.COM_LIST_ID_TEMP_ID ' ||
      '                                     FROM COM_LIST_ID_TEMP COM ' ||
      '                                    WHERE COM.LID_CODE = :iComCodeSelection))) ' ||
      '         GROUP BY FOU.GCO_GOOD_ID, FOU.FAL_LOT_ID) FACTOU ' ||
      '    WHERE ( (NVL (:iFalLotId, 0) <> 0 AND LOT.FAL_LOT_ID = :iFalLotId) ' ||
      '         OR (NVL (:iFalLotId, 0) = 0 ' ||
      '             AND LOT.FAL_LOT_ID IN (SELECT COM.COM_LIST_ID_TEMP_ID ' ||
      '                                      FROM COM_LIST_ID_TEMP COM ' ||
      '                                     WHERE COM.LID_CODE = :iComCodeSelection))) ' ||
      '        AND LOT.FAL_LOT_ID = LOM.FAL_LOT_ID ' ||
      '        AND LOM.GCO_GOOD_ID = GCO.GCO_GOOD_ID (+) ' ||
      '        AND LOM.GCO_GOOD_ID = GCF.GCO_GOOD_ID (+) ' ||
      '        AND LOM.FAL_LOT_ID = FACTOU.FAL_LOT_ID(+) ' ||
      '        AND LOM.GCO_GOOD_ID = FACTOU.GCO_GOOD_ID(+) ' ||
      '        AND LOM.C_TYPE_COM = ''1'' ' ||
      '        AND LOM.C_KIND_COM IN (''1'', ''4'') ' ||
      '        AND LOM.LOM_INCREASE_COST = 1 ' ||
      '        AND LOM.FAL_LOT_MATERIAL_LINK_ID = LNK.FAL_LOT_MATERIAL_LINK_ID (+) ' ||
      ' order by LOM.LOM_SEQ ';

    execute immediate vSQLQry
    bulk collect into oTabSSTAMaterialData
                using iFalLotId
                    , iFalLotId
                    , iFalLotId
                    , iComCodeSelection
                    , iFalLotId
                    , iFalLotId
                    , iFalLotId
                    , iComCodeSelection
                    , iFalLotId
                    , iFalLotId
                    , iFalLotId
                    , iComCodeSelection;

    -- pipe
    if oTabSSTAMaterialData.count > 0 then
      for i in oTabSSTAMaterialData.first .. oTabSSTAMaterialData.last loop
        -- Composant envoyé
        if oTabSSTAMaterialData(i).C_KIND_COM = '1' then
          -- Prix Encours : Prix selon mode de gestion
          oTabSSTAMaterialData(i).IN_PRICE      := nvl(oTabSSTAMaterialData(i).IN_QTE, 0) * oTabSSTAMaterialData(i).GCO_PRICE_WITH_MANAGT_MODE;
          -- Qté solde : Qté besoin - Qté attribuée (équivalente à sortie en atelier dans la fabrication en interne)
          oTabSSTAMaterialData(i).LOM_NEED_QTY  := oTabSSTAMaterialData(i).LOM_NEED_QTY - nvl(oTabSSTAMaterialData(i).IN_QTE, 0);
        -- Composant fourni par le sous-traitant
        elsif oTabSSTAMaterialData(i).C_KIND_COM = '4' then
          -- Qté réalisé : (Qté rebut récept + Qté réceptionnée) rapportée au composant
          oTabSSTAMaterialData(i).OUT_QTE       :=
            FAL_TOOLS.ArrondiSuperieur( (oTabSSTAMaterialData(i).LOT_RELEASED_QTY + oTabSSTAMaterialData(i).LOT_REJECT_RELEASED_QTY) *
                                       oTabSSTAMaterialData(i).LOM_UTIL_COEF /
                                       oTabSSTAMaterialData(i).LOM_REF_QTY
                                     , oTabSSTAMaterialData(i).GCO_GOOD_ID
                                     , oTabSSTAMaterialData(i).GOO_NUMBER_OF_DECIMAL
                                      );
          -- Prix réalisé : Prix selon mode de gestion
          oTabSSTAMaterialData(i).OUT_PRICE     := oTabSSTAMaterialData(i).OUT_QTE * oTabSSTAMaterialData(i).GCO_PRICE_WITH_MANAGT_MODE;
          -- Quantité solde
          oTabSSTAMaterialData(i).LOM_NEED_QTY  := oTabSSTAMaterialData(i).LOM_FULL_REQ_QTY - nvl(oTabSSTAMaterialData(i).OUT_QTE, 0);
        end if;

        pipe row(oTabSSTAMaterialData(i) );
      end loop;
    end if;
  end SelectMaterialDatas;

  /**
  * Description
  *    Sauvegarde de l'entête d'un calcul d'en-cours
  */
  procedure StoreBatchCalculHeader(
    oFalAdvBatchCalculId in out FAL_ADV_BC_S_CALC_OPTIONS.FAL_ADV_BATCH_CALCUL_ID%type
  , iFbcDateStart        in     FAL_ADV_BATCH_CALCUL.FBC_DATE_START%type
  , iFbcDateEnd          in     FAL_ADV_BATCH_CALCUL.FBC_DATE_END%type
  , iNumBatchCalculated  in     FAL_ADV_BATCH_CALCUL.FBC_NUM_BATCH_CALCULATED%type
  , iCCalculationKind    in     FAL_ADV_BATCH_CALCUL.C_CALCULATION_KIND%type
  , iFbcComment          in     FAL_ADV_BATCH_CALCUL.FBC_COMMENT%type
  , iFbcGroupResult      in     FAL_ADV_BATCH_CALCUL.FBC_GROUP_RESULT%type
  )
  as
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalAdvBatchCalcul, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FBC_DATE_START', iFbcDateStart);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FBC_DATE_END', iFbcDateEnd);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FBC_NUM_BATCH_CALCULATED', iNumBatchCalculated);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_CALCULATION_KIND', iCCalculationKind);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FBC_COMMENT', iFbcComment);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FBC_GROUP_RESULT', iFbcGroupResult);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    oFalAdvBatchCalculId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'FAL_ADV_BATCH_CALCUL_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end StoreBatchCalculHeader;

  /**
  * Description
  *    Sauvegarde d'un détail (lot) d'un calcul d'en-cours
  */
  procedure StoreBatchCalculDetails(
    iFalAdvBatchCalculId in FAL_ADV_BC_S_CALC_OPTIONS.FAL_ADV_BATCH_CALCUL_ID%type
  , iFalAdvCalcOptionId  in FAL_ADV_BC_S_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  )
  as
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalAdvBCSCalcOptions, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_ADV_BATCH_CALCUL_ID', iFalAdvBatchCalculId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_ADV_CALC_OPTIONS_ID', iFalAdvCalcOptionId);

    for ltplBatchInfos in (select lot.LOT_INPROD_QTY
                                , lot.LOT_RELEASED_QTY
                                , lot.LOT_REJECT_RELEASED_QTY
                                , lot.LOT_DISMOUNTED_QTY
                             from FAL_LOT lot
                                , FAL_ADV_CALC_OPTIONS cao
                            where cao.FAL_LOT_ID = lot.FAL_LOT_ID
                              and cao.FAL_ADV_CALC_OPTIONS_ID = iFalAdvCalcOptionId) loop
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_INPROD_QTY', ltplBatchInfos.LOT_INPROD_QTY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_RELEASED_QTY', ltplBatchInfos.LOT_RELEASED_QTY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_REJECT_RELEASED_QTY', ltplBatchInfos.LOT_REJECT_RELEASED_QTY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_DISMOUNTED_QTY', ltplBatchInfos.LOT_DISMOUNTED_QTY);
    end loop;

    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end StoreBatchCalculDetails;

  /**
  * Description
  *    Sauvegarde des rubriques de la structure de calcul utilisée par le calcul
  */
  procedure StoreCalculationRubrics(iFalAdvBatchCalculId in FAL_ADV_BATCH_CALCUL.FAL_ADV_BATCH_CALCUL_ID%type)
  as
    lCalcStrucId        FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type;
    ltAdvCalcRateStruct FWK_I_TYP_DEFINITION.t_crud_def;
    ltAdvCalcTotalRate  FWK_I_TYP_DEFINITION.t_crud_def;
    lCalcRateStruct1Id  FAL_ADV_CALC_TOTAL_RATE.FAL_ADV_CALC_RATE_STRUCT1_ID%type;
    lRateRubric         FAL_ADV_CALC_RATE_STRUCT.FAL_ADV_CALC_RATE_STRUCT1_ID%type;
    lAlreadyExists      number;
  begin
    -- Ne sauvegarder les rubriques de la structure que pour le premier lot du calcul.
    select count('x')
      into lAlreadyExists
      from dual
     where exists(select 'x'
                    from FAL_ADV_CALC_RATE_STRUCT
                   where FAL_ADV_BATCH_CALCUL_ID = iFalAdvBatchCalculId);

    if lAlreadyExists = 1 then
      return;
    end if;

    -- Récupération de l'id de la structure de calcul utilisée par le calcul
    select distinct (cao.FAL_ADV_STRUCT_CALC_ID)
               into lCalcStrucId
               from FAL_ADV_CALC_OPTIONS cao
                  , FAL_ADV_BC_S_CALC_OPTIONS lnk
                  , FAL_ADV_BATCH_CALCUL fbc
              where fbc.FAL_ADV_BATCH_CALCUL_ID = lnk.FAL_ADV_BATCH_CALCUL_ID
                and lnk.FAL_ADV_CALC_OPTIONS_ID = cao.FAL_ADV_CALC_OPTIONS_ID
                and fbc.FAL_ADV_BATCH_CALCUL_ID = iFalAdvBatchCalculId;

    -- Sauvegarde des rubriques
    for ltplFalAdvRateStruct in (select   *
                                     from FAL_ADV_RATE_STRUCT
                                    where FAL_ADV_STRUCT_CALC_ID = lCalcStrucId
                                 order by ARS_SEQUENCE asc) loop
      -- récupération de l'ID de la rubrique d'application du taux de même séquence que celle de la structure source
      begin
        select ARS.FAL_ADV_CALC_RATE_STRUCT_ID
          into lRateRubric
          from FAL_ADV_CALC_RATE_STRUCT ARS
         where ARS.ARS_SEQUENCE =
                               (select max(ARS2.ARS_SEQUENCE)
                                  from FAL_ADV_RATE_STRUCT ARS2
                                 where ARS2.FAL_ADV_STRUCT_CALC_ID = lCalcStrucId
                                   and ARS2.FAL_ADV_RATE_STRUCT_ID = ltplFalAdvRateStruct.FAL_ADV_RATE_STRUCT1_ID)
           and FAL_ADV_BATCH_CALCUL_ID = iFalAdvBatchCalculId
           and ARS.FAL_ADV_STRUCT_CALC_ID = lCalcStrucId;
      exception
        when no_data_found then
          lRateRubric  := null;
      end;

      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalAdvCalcRateStruct, ltAdvCalcRateStruct, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'FAL_ADV_BATCH_CALCUL_ID', iFalAdvBatchCalculId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'FAL_ADV_STRUCT_CALC_ID', lCalcStrucId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'FAL_ADV_CALC_RATE_STRUCT1_ID', lRateRubric);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'PC_COLORS_ID', ltplFalAdvRateStruct.PC_COLORS_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'DIC_FIXED_COSTPRICE_DESCR_ID', ltplFalAdvRateStruct.DIC_FIXED_COSTPRICE_DESCR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'DIC_FAL_RATE_DESCR_ID', ltplFalAdvRateStruct.DIC_FAL_RATE_DESCR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'C_RUBRIC_TYPE', ltplFalAdvRateStruct.C_RUBRIC_TYPE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'C_BASIS_RUBRIC', ltplFalAdvRateStruct.C_BASIS_RUBRIC);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'C_COST_ELEMENT_TYPE', ltplFalAdvRateStruct.C_COST_ELEMENT_TYPE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'C_COSTPRICE_STATUS', ltplFalAdvRateStruct.C_COSTPRICE_STATUS);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'ARS_SEQUENCE', ltplFalAdvRateStruct.ARS_SEQUENCE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'ARS_VISIBLE_LEVEL', ltplFalAdvRateStruct.ARS_VISIBLE_LEVEL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'ARS_RATE', ltplFalAdvRateStruct.ARS_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'ARS_PRF_LEVEL', ltplFalAdvRateStruct.ARS_PRF_LEVEL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'ARS_RATE_PROC', ltplFalAdvRateStruct.ARS_RATE_PROC);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcRateStruct, 'ARS_DEFAULT_PRF', ltplFalAdvRateStruct.ARS_DEFAULT_PRF);
      FWK_I_MGT_ENTITY.InsertEntity(ltAdvCalcRateStruct);

      -- Sauvegarde de ses éventuelles séquences pour total
      for ltplFalAdvTotalRate in (select   ARS.ARS_SEQUENCE
                                      from FAL_ADV_TOTAL_RATE ATR
                                         , FAL_ADV_RATE_STRUCT ARS
                                     where ATR.FAL_ADV_RATE_STRUCT_ID = ltplFalAdvRateStruct.FAL_ADV_RATE_STRUCT_ID
                                       and ATR.FAL_FAL_ADV_RATE_STRUCT_ID = ARS.FAL_ADV_RATE_STRUCT_ID(+)
                                  order by ATR.A_DATECRE) loop
        -- récupération de l'ID de la rubrique de même séquence que celle de la structure source
        begin
          select FAL_ADV_CALC_RATE_STRUCT_ID
            into lCalcRateStruct1Id
            from FAL_ADV_CALC_RATE_STRUCT
           where ARS_SEQUENCE = ltplFalAdvTotalRate.ARS_SEQUENCE
             and FAL_ADV_BATCH_CALCUL_ID = iFalAdvBatchCalculId
             and FAL_ADV_STRUCT_CALC_ID = lCalcStrucId;
        exception
          when no_data_found then
            lCalcRateStruct1Id  := null;
        end;

        FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalAdvCalcTotalRate, ltAdvCalcTotalRate, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcTotalRate
                                      , 'FAL_ADV_CALC_RATE_STRUCT_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltAdvCalcRateStruct, 'FAL_ADV_CALC_RATE_STRUCT_ID')
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcTotalRate, 'FAL_ADV_CALC_RATE_STRUCT1_ID', lCalcRateStruct1Id);
        FWK_I_MGT_ENTITY.InsertEntity(ltAdvCalcTotalRate);
        FWK_I_MGT_ENTITY.Release(ltAdvCalcTotalRate);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltAdvCalcRateStruct);
    end loop;
  end StoreCalculationRubrics;

  /**
  * Description
  *    Sauvegarde des taux ateliers
  */
  procedure StoreFactoryRates(iFalAdvBatchCalculId in FAL_ADV_BATCH_CALCUL.FAL_ADV_BATCH_CALCUL_ID%type)
  as
    ltAdvCalcFactRate    FWK_I_TYP_DEFINITION.t_crud_def;
    ltAdvCalcFactRateDec FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplFacRate in (select distinct FAL_FACTORY_FLOOR_ID
                                      , FAL_FACTORY_RATE_ID
                                      , FFR_VALIDITY_DATE
                                      , FFR_RATE1
                                      , FFR_RATE2
                                      , FFR_RATE3
                                      , FFR_RATE4
                                      , FFR_RATE5
                                   from (select FFR.FAL_FACTORY_FLOOR_ID
                                              , FFR.FAL_FACTORY_RATE_ID
                                              , FFR.FFR_VALIDITY_DATE
                                              , FFR.FFR_RATE1
                                              , FFR.FFR_RATE2
                                              , FFR.FFR_RATE3
                                              , FFR.FFR_RATE4
                                              , FFR.FFR_RATE5
                                           from FAL_FACTORY_RATE FFR
                                              , FAL_TASK_LINK TAL
                                              , COM_LIST_ID_TEMP LID
                                          where FFR.FAL_FACTORY_FLOOR_ID = TAL.FAL_FACTORY_FLOOR_ID
                                            and TAL.FAL_LOT_ID = LID.COM_LIST_ID_TEMP_ID
                                            and LID_CODE = 'WIP_SELECTED_BATCHES'
                                            and trunc(FFR.FFR_VALIDITY_DATE) =
                                                  (select max(trunc(FFR2.FFR_VALIDITY_DATE) )
                                                     from FAL_FACTORY_RATE FFR2
                                                    where trunc(FFR2.FFR_VALIDITY_DATE) <= trunc(sysdate)
                                                      and FFR2.FAL_FACTORY_FLOOR_ID = FFR.FAL_FACTORY_FLOOR_ID)
                                         union
                                         select FFR.FAL_FACTORY_FLOOR_ID
                                              , FFR.FAL_FACTORY_RATE_ID
                                              , FFR.FFR_VALIDITY_DATE
                                              , FFR.FFR_RATE1
                                              , FFR.FFR_RATE2
                                              , FFR.FFR_RATE3
                                              , FFR.FFR_RATE4
                                              , FFR.FFR_RATE5
                                           from FAL_FACTORY_RATE FFR
                                              , FAL_LOT_PROGRESS FLP
                                              , COM_LIST_ID_TEMP LID
                                          where FFR.FAL_FACTORY_FLOOR_ID = FLP.FAL_FACTORY_FLOOR_ID
                                            and FLP.FAL_LOT_ID = LID.COM_LIST_ID_TEMP_ID
                                            and LID_CODE = 'WIP_SELECTED_BATCHES'
                                            and trunc(FFR.FFR_VALIDITY_DATE) =
                                                  (select max(trunc(FFR2.FFR_VALIDITY_DATE) )
                                                     from FAL_FACTORY_RATE FFR2
                                                    where trunc(FFR2.FFR_VALIDITY_DATE) <= trunc(sysdate)
                                                      and FFR2.FAL_FACTORY_FLOOR_ID = FFR.FAL_FACTORY_FLOOR_ID)
                                         union
                                         select FFR.FAL_FACTORY_FLOOR_ID
                                              , FFR.FAL_FACTORY_RATE_ID
                                              , FFR.FFR_VALIDITY_DATE
                                              , FFR.FFR_RATE1
                                              , FFR.FFR_RATE2
                                              , FFR.FFR_RATE3
                                              , FFR.FFR_RATE4
                                              , FFR.FFR_RATE5
                                           from FAL_FACTORY_RATE FFR
                                              , FAL_TASK_LINK TAL
                                              , COM_LIST_ID_TEMP LID
                                          where FFR.FAL_FACTORY_FLOOR_ID = TAL.FAL_FAL_FACTORY_FLOOR_ID
                                            and TAL.FAL_LOT_ID = LID.COM_LIST_ID_TEMP_ID
                                            and LID_CODE = 'WIP_SELECTED_BATCHES'
                                            and trunc(FFR.FFR_VALIDITY_DATE) =
                                                  (select max(trunc(FFR2.FFR_VALIDITY_DATE) )
                                                     from FAL_FACTORY_RATE FFR2
                                                    where trunc(FFR2.FFR_VALIDITY_DATE) <= trunc(sysdate)
                                                      and FFR2.FAL_FACTORY_FLOOR_ID = FFR.FAL_FACTORY_FLOOR_ID)
                                         union
                                         select FFR.FAL_FACTORY_FLOOR_ID
                                              , FFR.FAL_FACTORY_RATE_ID
                                              , FFR.FFR_VALIDITY_DATE
                                              , FFR.FFR_RATE1
                                              , FFR.FFR_RATE2
                                              , FFR.FFR_RATE3
                                              , FFR.FFR_RATE4
                                              , FFR.FFR_RATE5
                                           from FAL_FACTORY_RATE FFR
                                              , FAL_LOT_PROGRESS FLP
                                              , COM_LIST_ID_TEMP LID
                                          where FFR.FAL_FACTORY_FLOOR_ID = FLP.FAL_FAL_FACTORY_FLOOR_ID
                                            and FLP.FAL_LOT_ID = LID.COM_LIST_ID_TEMP_ID
                                            and LID_CODE = 'WIP_SELECTED_BATCHES'
                                            and trunc(FFR.FFR_VALIDITY_DATE) =
                                                  (select max(trunc(FFR2.FFR_VALIDITY_DATE) )
                                                     from FAL_FACTORY_RATE FFR2
                                                    where trunc(FFR2.FFR_VALIDITY_DATE) <= trunc(sysdate)
                                                      and FFR2.FAL_FACTORY_FLOOR_ID = FFR.FAL_FACTORY_FLOOR_ID) )
                               order by FAL_FACTORY_FLOOR_ID asc
                                      , FFR_VALIDITY_DATE asc) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalAdvCalcFactoryRate, ltAdvCalcFactRate, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FAL_ADV_BATCH_CALCUL_ID', iFalAdvBatchCalculId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FAL_FACTORY_FLOOR_ID', ltplFacRate.FAL_FACTORY_FLOOR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FFR_RATE1', ltplFacRate.FFR_RATE1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FFR_RATE2', ltplFacRate.FFR_RATE2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FFR_RATE3', ltplFacRate.FFR_RATE3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FFR_RATE4', ltplFacRate.FFR_RATE4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FFR_RATE5', ltplFacRate.FFR_RATE5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRate, 'FFR_VALIDITY_DATE', ltplFacRate.FFR_VALIDITY_DATE);
      FWK_I_MGT_ENTITY.InsertEntity(ltAdvCalcFactRate);

      for ltplFacRateDec in (select distinct FRD.C_COST_TYPE
                                           , FRD.DIC_FACT_RATE_DESCR_ID
                                           , FRD.DIC_FACT_RATE_FREE1_ID
                                           , FRD.DIC_FACT_RATE_FREE2_ID
                                           , FRD.DIC_FACT_RATE_FREE3_ID
                                           , FRD.DIC_FACT_RATE_FREE4_ID
                                           , FRD.FRD_RATE
                                           , FRD.FRD_VALUE
                                           , FRD.FRD_RATE_NUMBER
                                        from FAL_FACT_RATE_DECOMP FRD
                                           , FAL_FACTORY_RATE FFR
                                       where FRD.FAL_FACTORY_RATE_ID = FFR.FAL_FACTORY_RATE_ID
                                         and FFR.FAL_FACTORY_FLOOR_ID = ltplFacRate.FAL_FACTORY_FLOOR_ID
                                         and trunc(FFR.FFR_VALIDITY_DATE) =
                                                (select max(trunc(FFR2.FFR_VALIDITY_DATE) )
                                                   from FAL_FACTORY_RATE FFR2
                                                  where trunc(FFR2.FFR_VALIDITY_DATE) <= sysdate
                                                    and FFR2.FAL_FACTORY_FLOOR_ID = ltplFacRate.FAL_FACTORY_FLOOR_ID) ) loop
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalAdvCalcFactRateDec, ltAdvCalcFactRateDec, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec
                                      , 'FAL_ADV_CALC_FACTORY_RATE_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltAdvCalcFactRate, 'FAL_ADV_CALC_FACTORY_RATE_ID')
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'C_COST_TYPE', ltplFacRateDec.C_COST_TYPE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'DIC_FACT_RATE_DESCR_ID', ltplFacRateDec.DIC_FACT_RATE_DESCR_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'DIC_FACT_RATE_FREE1_ID', ltplFacRateDec.DIC_FACT_RATE_FREE1_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'DIC_FACT_RATE_FREE2_ID', ltplFacRateDec.DIC_FACT_RATE_FREE2_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'DIC_FACT_RATE_FREE3_ID', ltplFacRateDec.DIC_FACT_RATE_FREE3_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'DIC_FACT_RATE_FREE4_ID', ltplFacRateDec.DIC_FACT_RATE_FREE4_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'FRD_RATE', ltplFacRateDec.FRD_RATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'FRD_VALUE', ltplFacRateDec.FRD_VALUE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltAdvCalcFactRateDec, 'FRD_RATE_NUMBER', ltplFacRateDec.FRD_RATE_NUMBER);
        FWK_I_MGT_ENTITY.InsertEntity(ltAdvCalcFactRateDec);
        FWK_I_MGT_ENTITY.Release(ltAdvCalcFactRateDec);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltAdvCalcFactRate);
    end loop;
  end StoreFactoryRates;
end FAL_PRC_WIP_CALCULATION;
