--------------------------------------------------------
--  DDL for Package Body FAL_PRC_TASK_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_TASK_LINK" 
is
  /*
  * Description
  *   Effacement des données la table COM_LIST_ID_TEMP liées au processus de sélection des critères
  */
  procedure ClearSelectData
  is
  begin
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_TASK_LINK_BATCH');
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_TASK_LINK_PRODUCT');
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_TASK_LINK_RESOURCE');
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_TASK_LINK_PROP');
  end;

  /**
  * Description
  *     Définit si un critère de sélection existe dans la table
  */
  function CriterionExist(iCode in COM_LIST_ID_TEMP.LID_CODE%type, iTable in PCS.PC_TABLE.TABNAME%type, iJobId in COM_LIST.LIS_JOB_ID%type)
    return number
  is
    lnResult number(1);
  begin
    if iTable = 'COM_LIST' then
      select nvl(max(1), 0)
        into lnResult
        from COM_LIST
       where LIS_CODE = iCode
         and LIS_JOB_ID = iJobId;
    else
      select nvl(max(1), 0)
        into lnResult
        from COM_LIST_ID_TEMP
       where LID_CODE = iCode;
    end if;

    return lnResult;
  end CriterionExist;

    /**
  * Description
  *     Définit si un critère de sélection concernant les propositions existe dans la table
  */
  function CriterionPropExist(
    iCode     in COM_LIST_ID_TEMP.LID_CODE%type
  , iTable    in PCS.PC_TABLE.TABNAME%type
  , iJobId    in COM_LIST.LIS_JOB_ID%type
  , iPropType in varchar2
  )
    return number
  is
    lnResult number(1);
  begin
    if iTable = 'COM_LIST' then
      select nvl(max(1), 0)
        into lnResult
        from COM_LIST
       where LIS_CODE = iCode
         and LIS_JOB_ID = iJobId;
    else
      select nvl(max(1), 0)
        into lnResult
        from COM_LIST_ID_TEMP
       where LID_CODE = iCode
         and COM_LIST_ID_TEMP_ID in(select distinct LOT.FAL_LOT_PROP_ID
                                               from FAL_LOT_PROP LOT
                                              where (    (    iPropType = 'MRP'
                                                          and FAL_PIC_ID is null)
                                                     or (    iPropType = 'PDP'
                                                         and FAL_PIC_ID is not null) ) );
    end if;

    return lnResult;
  end CriterionPropExist;

  /**
  * Description : Sélectionne un lot
  */
  procedure SelectFalLot(iLotId in FAL_LOT.FAL_LOT_ID%type default null)
  is
  begin
    ClearSelectData;
    SelectBatches(iLotId => iLotId, iSAVBatch => 1);
    SelectProducts;
    SelectResources;
    DOC_I_PRC_SUBCONTRACTO.UpdateFlagSelected;
  end SelectFalLot;

  /**
  * Description
  *     Sélectionne les lots de fabrications pour affichage
  */
  procedure SelectBatches(
    iJobProgramFrom in FAL_JOB_PROGRAM.JOP_REFERENCE%type default null
  , iJobProgramTo   in FAL_JOB_PROGRAM.JOP_REFERENCE%type default null
  , iOrderFrom      in FAL_ORDER.ORD_REF%type default null
  , iOrderTo        in FAL_ORDER.ORD_REF%type default null
  , iLotId          in FAL_LOT.FAL_LOT_ID%type default null
  , iPriorityFrom   in FAL_LOT.C_PRIORITY%type default null
  , iPriorityTo     in FAL_LOT.C_PRIORITY%type default null
  , iFamilyFrom     in DIC_FAMILY.DIC_FAMILY_ID%type default null
  , iFamilyTo       in DIC_FAMILY.DIC_FAMILY_ID%type default null
  , iRecordFrom     in DOC_RECORD.RCO_TITLE%type default null
  , iRecordTo       in DOC_RECORD.RCO_TITLE%type default null
  , iSTDBatch       in integer default 1
  , iSAVBatch       in integer default 0
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_TASK_LINK_BATCH';

    -- Sélection des ID de lots à afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_ID
                    , 'FAL_TASK_LINK_BATCH'
                 from FAL_LOT LOT
                    , FAL_JOB_PROGRAM JOP
                    , FAL_ORDER ORD
                    , DOC_RECORD RCO
                where LOT.C_LOT_STATUS in('1', '2')
                  and LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                  and (    (    iJobProgramFrom is null
                            and iJobProgramTo is null)
                       or JOP.JOP_REFERENCE between nvl(iJobProgramFrom, JOP.JOP_REFERENCE) and nvl(iJobProgramTo, JOP.JOP_REFERENCE)
                      )
                  and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
                  and (    (    iOrderFrom is null
                            and iOrderTo is null)
                       or ORD.ORD_REF between nvl(iOrderFrom, ORD.ORD_REF) and nvl(iOrderTo, ORD.ORD_REF) )
                  and (   iLotId = 0
                       or LOT.FAL_LOT_ID = iLotId)
                  and (    (    iPriorityFrom is null
                            and iPriorityTo is null)
                       or LOT.C_PRIORITY between nvl(iPriorityFrom, LOT.C_PRIORITY) and nvl(iPriorityTo, LOT.C_PRIORITY)
                      )
                  and (    (    iFamilyFrom is null
                            and iFamilyTo is null)
                       or LOT.DIC_FAMILY_ID between nvl(iFamilyFrom, LOT.DIC_FAMILY_ID) and nvl(iFamilyTo, LOT.DIC_FAMILY_ID)
                      )
                  and RCO.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
                  and (    (    iRecordFrom is null
                            and iRecordTo is null)
                       or RCO.RCO_TITLE between nvl(iRecordFrom, RCO.RCO_TITLE) and nvl(iRecordTo, RCO.RCO_TITLE) )
                  and (     (   iSTDBatch = 1
                             or iSAVBatch = 1)
                       and nvl(LOT.C_FAB_TYPE, '0') <> '4')
                  and (    (    iSTDBatch = 0
                            and iSAVBatch = 1
                            and nvl(LOT.C_FAB_TYPE, '0') = '3')
                       or (    iSTDBatch = 0
                           and iSAVBatch = 0
                           and RCO.GAL_PROJECT_ID is not null)
                       or (    iSTDBatch = 0
                           and iSAVBatch = 1
                           and (   RCO.GAL_PROJECT_ID is not null
                                or nvl(LOT.C_FAB_TYPE, '0') = '3') )
                       or (    iSTDBatch = 1
                           and iSAVBatch = 0
                           and RCO.GAL_PROJECT_ID is null
                           and nvl(LOT.C_FAB_TYPE, '0') = '0')
                       or (    iSTDBatch = 1
                           and iSAVBatch = 1
                           and RCO.GAL_PROJECT_ID is null
                           and nvl(LOT.C_FAB_TYPE, '0') in('0', '3') )
                       or (    iSTDBatch = 1
                           and iSAVBatch = 0
                           and nvl(LOT.C_FAB_TYPE, '0') = '0')
                       or (    iSTDBatch = 1
                           and iSAVBatch = 1)
                      );

    if     (   iJobProgramFrom is not null
            or iJobProgramTo is not null
            or iOrderFrom is not null
            or iOrderTo is not null
            or iLotId is not null
            or iPriorityFrom is not null
            or iPriorityTo is not null
            or iFamilyFrom is not null
            or iFamilyTo is not null
            or iRecordFrom is not null
            or iRecordTo is not null
           )
       and CriterionExist('FAL_TASK_LINK_BATCH', 'COM_LIST_ID_TEMP', 0) = 0 then
      -- Si au moins un critère est sélectionné mais que la requête ne retourne
      -- aucun élément, ajouter un ligne fictive dans le COM_LIST_ID_TEMP
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct 0
                      , 'FAL_TASK_LINK_BATCH'
                   from dual;
    end if;
  end selectBatches;

  /**
  * Description
  *     Sélectionne les produits pour affichage
  */
  procedure SelectProducts(
    iProductFrom          in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , iProductTo            in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , iCategoryFrom         in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type default null
  , iCategoryTo           in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type default null
  , iFamilyFrom           in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type default null
  , iFamilyTo             in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type default null
  , iAccountableGroupFrom in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type default null
  , iAccountableGroupTo   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type default null
  , iLineFrom             in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type default null
  , iLineTo               in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type default null
  , iGroupFrom            in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type default null
  , iGroupTo              in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type default null
  , iModelFrom            in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type default null
  , iModelTo              in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type default null
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_TASK_LINK_PRODUCT';

    -- Sélection des ID de produits à afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct GOO.GCO_GOOD_ID
                    , 'FAL_TASK_LINK_PRODUCT'
                 from GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , GCO_GOOD_CATEGORY CAT
                where PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and GOO.GOO_MAJOR_REFERENCE between nvl(iProductFrom, GOO.GOO_MAJOR_REFERENCE) and nvl(iProductTo, GOO.GOO_MAJOR_REFERENCE)
                  and (    (    iCategoryFrom is null
                            and iCategoryTo is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(iCategoryFrom, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(iCategoryTo, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    iFamilyFrom is null
                            and iFamilyTo is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(iFamilyFrom, GOO.DIC_GOOD_FAMILY_ID) and nvl(iFamilyTo, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    iAccountableGroupFrom is null
                            and iAccountableGroupTo is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(iAccountableGroupFrom, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(iAccountableGroupTo, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    iLineFrom is null
                            and iLineTo is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(iLineFrom, GOO.DIC_GOOD_LINE_ID) and nvl(iLineTo, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    iGroupFrom is null
                            and iGroupTo is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(iGroupFrom, GOO.DIC_GOOD_GROUP_ID) and nvl(iGroupTo, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    iModelFrom is null
                            and iModelTo is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(iModelFrom, GOO.DIC_GOOD_MODEL_ID) and nvl(iModelTo, GOO.DIC_GOOD_MODEL_ID)
                      );

    if     (   iProductFrom is not null
            or iProductTo is not null
            or iCategoryFrom is not null
            or iCategoryTo is not null
            or iFamilyFrom is not null
            or iFamilyTo is not null
            or iAccountableGroupFrom is not null
            or iAccountableGroupTo is not null
            or iLineFrom is not null
            or iLineTo is not null
            or iGroupFrom is not null
            or iGroupTo is not null
            or iModelFrom is not null
            or iModelTo is not null
           )
       and CriterionExist('FAL_TASK_LINK_PRODUCT', 'COM_LIST_ID_TEMP', 0) = 0 then
      -- Si au moins un critère est sélectionné mais que la requête ne retourne
      -- aucun élément, ajouter un ligne fictive dans le COM_LIST_ID_TEMP
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct 0
                      , 'FAL_TASK_LINK_PRODUCT'
                   from dual;
    end if;
  end SelectProducts;

  /**
  * Description
  *     Sélectionne les ressources pour affichage
  */
  procedure SelectResources(iSupplierFrom in varchar2 default null, iSupplierTo in varchar2 default null)
  is
  begin
    -- Suppression des anciennes valeurs ilots, machine et fournisseurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_TASK_LINK_RESOURCE';

    -- Sélection des ID de fournisseurs avec au moins une opération
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct PAC.PAC_SUPPLIER_PARTNER_ID
                    , 'FAL_TASK_LINK_RESOURCE'
                 from PAC_SUPPLIER_PARTNER PAC
                    , PAC_PERSON PER
                    , FAL_TASK_LINK FTL
                where PAC.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                  and FTL.PAC_SUPPLIER_PARTNER_ID = PAC.PAC_SUPPLIER_PARTNER_ID
                  and PAC.C_PARTNER_STATUS in('1', '2')
                  and PER.PER_NAME between nvl(iSupplierFrom, PER.PER_NAME) and nvl(iSupplierTo, PER.PER_NAME);

    if     (   iSupplierFrom is not null
            or iSupplierTo is not null)
       and CriterionExist('FAL_TASK_LINK_RESOURCE', 'COM_LIST_ID_TEMP', 0) = 0 then
      -- Si au moins un critère est sélectionné mais que la requête ne retourne
      -- aucun élément, ajouter un ligne fictive dans le COM_LIST_ID_TEMP
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct 0
                      , 'FAL_TASK_LINK_RESOURCE'
                   from dual;
    end if;
  end SelectResources;

  /**
  * Description
  *     Sélectionne les propositions
  */
  procedure SelectPropositions(
    iType            in varchar2 default null
  , iRecordFrom      in varchar2 default null
  , iRecordTo        in varchar2 default null
  , iStockFrom       in varchar2 default null
  , iStockTo         in varchar2 default null
  , iDicPropFreeFrom in varchar2 default null
  , iDicPropFreeTo   in varchar2 default null
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_TASK_LINK_PROP'
            and COM_LIST_ID_TEMP_ID in(select distinct LOT.FAL_LOT_PROP_ID
                                                  from FAL_LOT_PROP LOT
                                                 where (    (    iType = 'MRP'
                                                             and FAL_PIC_ID is null)
                                                        or (    iType = 'PDP'
                                                            and FAL_PIC_ID is not null) ) );

    -- Sélection des ID de propositions à afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_PROP_ID
                    , 'FAL_TASK_LINK_PROP'
                 from FAL_LOT_PROP LOT
                    , GCO_PRODUCT PDT
                    , DOC_RECORD RCO
                    , STM_STOCK STO
                where LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and LOT.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                  and PDT.C_SUPPLY_MODE <> 4
                  and (    (    iType = 'MRP'
                            and FAL_PIC_ID is null)
                       or (    iType = 'PDP'
                           and FAL_PIC_ID is not null) )
                  and LOT.STM_STOCK_ID = STO.STM_STOCK_ID(+)
                  and (    (    iStockFrom is null
                            and iStockTo is null)
                       or STO.STO_DESCRIPTION between nvl(iStockFrom, STO.STO_DESCRIPTION) and nvl(iStockTo, STO.STO_DESCRIPTION)
                      )
                  and (    (    iRecordFrom is null
                            and iRecordTo is null)
                       or RCO.RCO_TITLE between nvl(iRecordFrom, RCO.RCO_TITLE) and nvl(iRecordTo, RCO.RCO_TITLE) )
                  and (    (    iDicPropFreeFrom is null
                            and iDicPropFreeTo is null)
                       or LOT.DIC_LOT_PROP_FREE_ID between nvl(iDicPropFreeFrom, LOT.DIC_LOT_PROP_FREE_ID) and nvl(iDicPropFreeTo, LOT.DIC_LOT_PROP_FREE_ID)
                      );
  end SelectPropositions;

  /**
  * Description
  *     Sélectionne les propositions de type MRP
  */
  procedure SelectMRPPropositions(
    iRecordFrom      in varchar2 default null
  , iRecordTo        in varchar2 default null
  , iStockFrom       in varchar2 default null
  , iStockTo         in varchar2 default null
  , iDicPropFreeFrom in varchar2 default null
  , iDicPropFreeTo   in varchar2 default null
  )
  is
  begin
    SelectPropositions('MRP', iRecordFrom, iRecordTo, iStockFrom, iStockTo, iDicPropFreeFrom, iDicPropFreeTo);
  end SelectMRPPropositions;

  /**
  * Description
  *     Sélectionne les propositions de type PDP
  */
  procedure SelectPDPPropositions(
    iRecordFrom      in varchar2 default null
  , iRecordTo        in varchar2 default null
  , iStockFrom       in varchar2 default null
  , iStockTo         in varchar2 default null
  , iDicPropFreeFrom in varchar2 default null
  , iDicPropFreeTo   in varchar2 default null
  )
  is
  begin
    SelectPropositions('PDP', iRecordFrom, iRecordTo, iStockFrom, iStockTo, iDicPropFreeFrom, iDicPropFreeTo);
  end SelectPDPPropositions;

  /**
  * Description: Update available quantity of operations of a batch
  */
  procedure UpdateAvailQtyOp(iBatchId FAL_TASK_LINK.FAL_LOT_ID%type, iTaskId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null)
  is
    cursor crOpe
    is
      select   FAL_SCHEDULE_STEP_ID
          from FAL_TASK_LINK FTL
             , FAL_LOT LOT
         where FTL.FAL_LOT_ID = iBatchId
           and FTL.FAL_LOT_ID = LOT.FAL_LOT_ID
           and LOT.C_LOT_STATUS = '2'
           and (   iTaskId is null
                or FTL.FAL_SCHEDULE_STEP_ID = iTaskId)
      order by SCS_STEP_NUMBER;

    lCrudDef      FWK_I_TYP_DEFINITION.t_crud_def;
    lnNewAvailQty FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type;
  begin
    for tplOpe in crOpe loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_FAL_ENTITY.gcFalTaskLink, iot_crud_definition => lCrudDef, iv_primary_col => 'FAL_SCHEDULE_STEP_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCrudDef, 'FAL_SCHEDULE_STEP_ID', tplOpe.FAL_SCHEDULE_STEP_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCrudDef, 'TAL_AVALAIBLE_QTY', FAL_LIB_TASK_LINK.GetAvailQty(tplOpe.FAL_SCHEDULE_STEP_ID) );
      FWK_I_MGT_ENTITY.UpdateEntity(lCrudDef);
      FWK_I_MGT_ENTITY.Release(lCrudDef);
    end loop;
  end UpdateAvailQtyOp;

  /**
  * Description : Delete the reversed track done on the operation
  */
  procedure DeleteReversedTrack(iTaskId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
  is
    lCrudDef FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplProgressTrack in (select   FAL_LOT_PROGRESS_ID
                                 from FAL_LOT_PROGRESS
                                where FAL_SCHEDULE_STEP_ID = iTaskId
                                  and FLP_REVERSAL = 1
                             order by FAL_LOT_PROGRESS_ID desc) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_FAL_ENTITY.gcFalLotProgress
                         , iot_crud_definition   => lCrudDef
                         , ib_initialize         => false
                         , in_main_id            => tplProgressTrack.FAL_LOT_PROGRESS_ID
                          );
      FWK_I_MGT_ENTITY.DeleteEntity(lCrudDef);
      FWK_I_MGT_ENTITY.Release(lCrudDef);
    end loop;
  end DeleteReversedTrack;
end FAL_PRC_TASK_LINK;
