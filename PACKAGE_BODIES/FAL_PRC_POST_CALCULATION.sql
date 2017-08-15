--------------------------------------------------------
--  DDL for Package Body FAL_PRC_POST_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_POST_CALCULATION" 
is
  /**
  * function ChildrenDocumentsFinished
  * Description : Vérification que les docs liés sont liquidés.
  *
  * @created ECA 07.03.2011
  * @lastUpdate
  * @public
  * @param   iDocPositionDetailid : Détail de position
  */
  function ChildrenDocumentsFinished(iDocPositionDetailId in number)
    return integer
  is
  begin
    for tplChildrenDocuments in (select DET.DOC_POSITION_DETAIL_ID
                                      , DOC.C_DOCUMENT_STATUS
                                   from DOC_DOCUMENT DOC
                                      , DOC_POSITION POS
                                      , DOC_POSITION_DETAIL DET
                                  where DET.DOC_DOC_POSITION_DETAIL_ID = iDocPositionDetailId
                                    and POS.DOC_POSITION_ID = DET.DOC_POSITION_ID
                                    and (   POS.C_GAUGE_TYPE_POS = '1'
                                         or POS.C_GAUGE_TYPE_POS = '2'
                                         or POS.C_GAUGE_TYPE_POS = '3')
                                    and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID) loop
      if tplChildrenDocuments.C_DOCUMENT_STATUS <> '04' then
        return 0;
      end if;
    end loop;

    return 1;
  end;

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
  * @param   iUnCalCulatedBatches : Lots non calculés
  * @param   iCalculableBatches : Lots calculables
  * @param   iBalancedBatches : Lot soldés fusion, réception
  * @param   iLaunchedBatches : Lot lancés, suspendus
  * @param   iLidCode : Code table de sélection COM_LIST
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
  , iUnCalculatedBatches   in integer default 0
  , iCalculableBatches     in integer default 0
  , iBalancedBatches       in integer default 0
  , iLaunchedBatches       in integer default 0
  , iLidCode               in varchar2 default null
  )
  is
  begin
    -- Suppression des lots déjà sélectionnés
    delete from COM_LIST_ID_TEMP
          where LID_CODE = iLidCode;

    -- Sélection des lots selons les critères définis
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select   LOT.FAL_LOT_ID
             , iLidCode
          from FAL_LOT LOT
             , DOC_RECORD RCO
             , DOC_DOCUMENT DOC
             , DOC_POSITION POS
             , GCO_GOOD GCO
             , GCO_SERVICE SER
             , GCO_GOOD GCOBATCH
         where LOT.C_FAB_TYPE = '4'
           and (    (    iBalancedBatches = 1
                     and LOT.C_LOT_STATUS in('3', '5') )
                or (    iLaunchedBatches = 1
                    and LOT.C_LOT_STATUS in('2', '4') ) )
           and LOT.GCO_GOOD_ID = GCOBATCH.GCO_GOOD_ID
           and LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
           and LOT.FAL_LOT_ID = POS.FAL_LOT_ID
           and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
           and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
           and POS.GCO_GOOD_ID = SER.GCO_GOOD_ID
           and DOC_LIB_SUBCONTRACTP.IsSUPOGauge(DOC.DOC_GAUGE_ID) = 1
           and (    (    iDmtNumberFrom is null
                     and iDmtNumberTo is null)
                or DOC.DMT_NUMBER between nvl(iDmtNumberFrom, DOC.DMT_NUMBER) and nvl(iDmtNumberTo, DOC.DMT_NUMBER)
               )
           and (    (    iDocRecordFrom is null
                     and iDocRecordTo is null)
                or RCO.RCO_TITLE between nvl(iDocRecordFrom, RCO.RCO_TITLE) and nvl(iDocRecordTo, RCO.RCO_TITLE)
               )
           and (    (    iGcoServiceFrom is null
                     and iGcoServiceTo is null)
                or GCO.GOO_MAJOR_REFERENCE between nvl(iGcoServiceFrom, GCO.GOO_MAJOR_REFERENCE) and nvl(iGcoServiceTo, GCO.GOO_MAJOR_REFERENCE)
               )
           and (    (    iGcoMajorReferenceFrom is null
                     and iGcoMajorReferenceTo is null)
                or GCOBATCH.GOO_MAJOR_REFERENCE between nvl(iGcoMajorReferenceFrom, GCOBATCH.GOO_MAJOR_REFERENCE)
                                                    and nvl(iGcoMajorReferenceTo, GCOBATCH.GOO_MAJOR_REFERENCE)
               )
           and (   iConfirmDateFrom is null
                or (    iConfirmDateFrom is not null
                    and trunc(LOT.LOT_OPEN__DTE) >= trunc(iConfirmDateFrom) ) )
           and (   iConfirmDateTo is null
                or (    iConfirmDateTo is not null
                    and trunc(LOT.LOT_OPEN__DTE) <= trunc(iConfirmDateTo) ) )
           and (   iUnCalculatedBatches = 0
                or (    iUnCalculatedBatches = 1
                    and IsCalculatedBatch(LOT.FAL_LOT_ID) = 0) )
           and (   iCalculableBatches = 0
                or (    iCalculableBatches = 1
                    and IsCalculableBatch(LOT.FAL_LOT_ID) = 1) )
      order by GCOBATCH.GOO_MAJOR_REFERENCE
             , LOT.LOT_REFCOMPL;
  end SelectSSTABatches;

/**
  * function IsCalculatedBatch
  * Description : recherche si le lot a déjà été post-calculé
  *
  * @created ECA 07.03.2011
  * @lastUpdate
  * @public
  * @param   iFalLotId : lot de fabrication
  */
  function IsCalculatedBatch(iFalLotId in integer)
    return integer
  is
    liIsCalculated number;
  begin
    select nvl(max(FAL_HISTO_LOT_ID), 0)
      into liIsCalculated
      from FAL_HISTO_LOT
     where C_EVEN_TYPE = '20'
       and FAL_LOT5_ID = iFalLotId;

    if liIsCalculated > 0 then
      return 1;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end IsCalculatedBatch;

  /**
  * function IsCalculableBatch
  * Description : recherche si le lot est calculable
  *
  * @created ECA 07.03.2011
  * @lastUpdate
  * @public
  * @param   iFalLotId : lot de fabrication
  */
  function IsCalculableBatch(iFalLotId in integer)
    return integer
  is
    iCalculableBatch      integer;
    iUnFinishedOperations integer;
  begin
    -- Recherche des opérations dont la Qté solde > 0. Si trouvées, le lot n'est pas calculable.
    select count(*)
      into iUnFinishedOperations
      from FAL_TASK_LINK
     where TAL_DUE_QTY > 0
       and FAL_LOT_ID = iFalLotId;

    if iUnFinishedOperations > 0 then
      return 0;
    end if;

    -- Vérifie que la sous-traitance à bien été facturée
    for tplSubContractBilling in (select DET.DOC_POSITION_DETAIL_ID
                                       , DOC.C_DOCUMENT_STATUS
                                    from DOC_DOCUMENT DOC
                                       , DOC_POSITION POS
                                       , DOC_GAUGE GAU
                                       , DOC_POSITION_DETAIL DET
                                   where DET.FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                                                       from FAL_TASK_LINK
                                                                      where FAL_LOT_ID = iFalLotId)
                                     and POS.DOC_POSITION_ID = DET.DOC_POSITION_ID
                                     and (   POS.C_GAUGE_TYPE_POS = '1'
                                          or POS.C_GAUGE_TYPE_POS = '2'
                                          or POS.C_GAUGE_TYPE_POS = '3')
                                     and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                                     and GAU.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
                                     and instr(',A-CST,', ',' || GAU.DIC_GAUGE_TYPE_DOC_ID || ',') > 0) loop
      if tplSubContractBilling.C_DOCUMENT_STATUS = '04' then
        iCalculableBatch  := ChildrenDocumentsFinished(tplSubContractBilling.DOC_POSITION_DETAIL_ID);

        if iCalculableBatch = 0 then
          return 0;
        end if;
      else
        return 0;
      end if;
    end loop;

    return 1;
  end IsCalculableBatch;
end FAL_PRC_POST_CALCULATION;
