--------------------------------------------------------
--  DDL for Package Body FAL_CMD_SUPPLIER_PARTNER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_CMD_SUPPLIER_PARTNER" 
is
  -- Configurations
  cProgressMvtCpt integer := PCS.PC_CONFIG.GetConfig('FAL_PROGRESS_MVT_CPT');

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_SUBCONTRACT.updateOpAtPosRecept instead.
  */
  procedure MAJ_TASK_RECEPTION(
    prmDOC_DOCUMENT_ID           in number
  , Operation_Lot                in number
  , qte_realise                  in number
  , mnt_realise                  in number
  , aPDE_BALANCE_QUANTITY_PARENT    DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type
  , aDOC_POSITION_DETAIL_ID         number
  , aPDE_FINAL_QUANTITY             number
  )
  is
  begin
    FAL_PRC_SUBCONTRACTO.updateOpAtPosRecept(iDocumentID            => prmDOC_DOCUMENT_ID
                                           , iScheduleStepID        => Operation_Lot
                                           , iDocPosDetailID        => aDOC_POSITION_DETAIL_ID
                                           , iDocPosID              => null
                                           , iPdeBalanceQtyParent   => aPDE_BALANCE_QUANTITY_PARENT
                                           , iQty                   => qte_realise
                                           , iAmount                => mnt_realise
                                           , iPdeFinalQty           => aPDE_FINAL_QUANTITY
                                           , iDocGaugeReceiptId     => null
                                            );
  end MAJ_TASK_RECEPTION;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_SUBCONTRACT.updateCstDelay instead.
  */
  procedure Modif_delai_CST(prmDOC_POSITION_DETAIL_ID number)
  is
  begin
    FAL_PRC_SUBCONTRACTO.updateCstDelay(iDocPosDetailID => prmDOC_POSITION_DETAIL_ID);
  end Modif_delai_CST;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_SUBCONTRACT.updateCstDelay instead.
  */
  procedure Modif_delai_CST(prmDOC_POSITION_DETAIL_ID in number, aDoWarning in integer, aMessage in out varchar2)
  is
  begin
    FAL_PRC_SUBCONTRACTO.updateCstDelay(iDocPosDetailID => prmDOC_POSITION_DETAIL_ID, iDoWarning => aDoWarning, iMessage => aMessage);
  end Modif_delai_CST;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_SUBCONTRACT.updateOpAtPosBalance instead.
  */
  procedure MAJ_op_solde_position(
    ADocumentNumber             DOC_DOCUMENT.DMT_NUMBER%type
  , ADocumentDate               DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , ABalanceQuantity            number
  , AOperation_lot           in number
  , inDOC_POSITION_DETAIL_ID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , inPDE_ST_PT_REJECT       in DOC_POSITION_DETAIL.PDE_ST_PT_REJECT%type
  , inPDE_ST_CPT_REJECT      in DOC_POSITION_DETAIL.PDE_ST_CPT_REJECT%type
  )
  is
  begin
    FAL_PRC_SUBCONTRACTO.updateOpAtPosBalance(iDocumentNumber      => ADocumentNumber
                                            , iDocumentDate        => ADocumentDate
                                            , iBalanceQty          => ABalanceQuantity
                                            , iScheduleStepID      => AOperation_lot
                                            , iDocPosDetailID      => inDOC_POSITION_DETAIL_ID
                                            , iDocPosID            => null
                                            , iPdeStPtReject       => inPDE_ST_PT_REJECT
                                            , iPdeStCptReject      => inPDE_ST_CPT_REJECT
                                            , iDocGaugeReceiptId   => null
                                             );
  end MAJ_op_solde_position;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_SUBCONTRACT.updateOpAtPosGeneration instead.
  */
  procedure MAJ_OP_generation(Id_operation number, Qte_Aexpedier number, Date_doc date)
  is
  begin
    FAL_PRC_SUBCONTRACTO.updateOpAtPosGeneration(iScheduleStepID => Id_operation, iSendingQty => Qte_Aexpedier, iDocumentDate => Date_doc);
  end MAJ_OP_generation;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_SUBCONTRACT.updateOpAtPosDelete instead.
  */
  procedure MAJ_OP_generation_suppression(Id_operation number, Qte_Solde number)
  is
  begin
    FAL_PRC_SUBCONTRACTO.updateOpAtPosDelete(iScheduleStepID => Id_operation, iBalanceQty => Qte_Solde);
  end MAJ_OP_generation_suppression;
end FAL_CMD_SUPPLIER_PARTNER;
