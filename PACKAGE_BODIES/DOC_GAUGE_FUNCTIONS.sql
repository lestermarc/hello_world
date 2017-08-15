--------------------------------------------------------
--  DDL for Package Body DOC_GAUGE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_GAUGE_FUNCTIONS" 
is
  /**********************************************************************
  * Description : Recherche l'ID du Flux actif selon un domaine et un tiers
  */
  function GetFlowID(AdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type, ThirdID in PAC_THIRD.PAC_THIRD_ID%type)
    return DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type
  is
  begin
    return DOC_LIB_GAUGE.GetFlowID(AdminDomain, ThirdID);
  end GetFlowID;

  /**********************************************************************
  * Description : Recherche l'ID des flux potentiels selon un domaine et un tiers (Actif ou archivé)
  */
  function GetAllPotentialFlow(
    aAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aThirdID     in PAC_THIRD.PAC_THIRD_ID%type
  )
    return varchar2
  is
  begin
    return DOC_LIB_GAUGE.GetAllPotentialFlow(aAdminDomain, aThirdID);
  end GetAllPotentialFlow;

  /**********************************************************************
  * Description : Recherche l'ID des flux ayant un lien entre la source et la destination spécifiées
  */
  function GetAllFlow(
    aGaugeSrc    in DOC_GAUGE.DOC_GAUGE_ID%type
  , aGaugeDst    in DOC_GAUGE.DOC_GAUGE_ID%type
  , aReceiptLink in number
  )
    return varchar2
  is
  begin
    return DOC_LIB_GAUGE.GetAllFlow(aGaugeSrc, aGaugeDst, aReceiptLink);
  end getAllFlow;

  /**********************************************************************
  * Description : Indique le détail de position passé en paramètre peut être déchargé, en fonction du gabarit source et cible
  */
  function CanReceipt(
    aGaugeSrc    in DOC_GAUGE.DOC_GAUGE_ID%type
  , aGaugeDst    in DOC_GAUGE.DOC_GAUGE_ID%type
  , aPosDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  )
    return number
  is
  begin
    return DOC_LIB_GAUGE.CanReceipt(aGaugeSrc, aGaugeDst, aPosDetailId);
  end CanReceipt;

  /**********************************************************************
  * Description : Indique le détail de position passé en paramètre peut être copié, en fonction du gabarit source et cible
  */
  function CanCopy(
    aGaugeSrc    in DOC_GAUGE.DOC_GAUGE_ID%type
  , aGaugeDst    in DOC_GAUGE.DOC_GAUGE_ID%type
  , aPosDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  )
    return number
  is
  begin
    return DOC_LIB_GAUGE.CanCopy(aGaugeSrc, aGaugeDst, aPosDetailId);
  end CanCopy;

  /**********************************************************************
  * Description : Recherche l'ID du DOC_GAUGE_RECEIPT
  */
  function GetGaugeReceiptID(
    SourceGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , TargetGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , ThirdID       in PAC_THIRD.PAC_THIRD_ID%type
  )
    return DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  is
  begin
    return DOC_LIB_GAUGE.GetGaugeReceiptID(SourceGaugeID, TargetGaugeID, ThirdID);
  end GetGaugeReceiptID;

  /**********************************************************************
  * Description : Recherche l'ID du DOC_GAUGE_COPY
  */
  function GetGaugeCopyID(
    SourceGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , TargetGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , ThirdID       in PAC_THIRD.PAC_THIRD_ID%type
  )
    return DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  is
  begin
    return DOC_LIB_GAUGE.GetGaugeCopyID(SourceGaugeID, TargetGaugeID, ThirdID);
  end GetGaugeCopyID;

  /**********************************************************************
  * Description : Recherche un flag sur le gabarit récéptionnable
  */
  function GetGaugeReceiptFlag(ReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type, FieldName in varchar2)
    return number
  is
  begin
    return DOC_LIB_GAUGE.GetGaugeReceiptFlag(ReceiptID, FieldName);
  end GetGaugeReceiptFlag;

/***********************************************************************/
/* Description : Recherche un flag sur le gabarit copiable             */
  function GetGaugeCopyFlag(CopyID in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type, FieldName in varchar2)
    return number
  is
  begin
    return DOC_LIB_GAUGE.GetGaugeCopyFlag(CopyID, FieldName);
  end GetGaugeCopyFlag;

/***********************************************************************/
/* Description : Recherche du nombre de copies supplémentaires         */
  function GetCopySupp(
    aGaugeId   DOC_GAUGE.DOC_GAUGE_ID%type
  , aDmtNumber DOC_DOCUMENT.DMT_NUMBER%type
  , aFormNb    number
  , aTarget    varchar2
  )
    return number
  is
  begin
    return DOC_LIB_GAUGE.GetCopySupp(aGaugeId, aDmtNumber, aFormNb, aTarget);
  end GetCopySupp;

  /*
  * Description : Recherche l'ID du DOC_GAUGE_RECEIPT
  */
  function IsGaugeReceiptable(aTestGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
    result number(1);
  begin
    return DOC_LIB_GAUGE.IsGaugeReceiptable(aTestGaugeID);
  end IsGaugeReceiptable;

  /**
  * function GetGaugeSrcListDischarge
  * Description
  *    Renvoi la liste de tous les gabarits déchargeables (source) pour le
  *    gabarit passé en paramètre (gabarit cible)
  */
  function GetGaugeSrcListDischarge(
    aGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , aFlowID  in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type default null
  , aThirdID in PAC_THIRD.PAC_THIRD_ID%type default null
  )
    return ID_TABLE_TYPE
  is
  begin
    return DOC_LIB_GAUGE.GetGaugeSrcListDischarge(aGaugeID, aFlowID, aThirdID);
  end GetGaugeSrcListDischarge;
end DOC_GAUGE_FUNCTIONS;
