--------------------------------------------------------
--  DDL for Package Body DOC_LIB_SUBCONTRACTP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_SUBCONTRACTP" 
is
  /**
  * function GetProcessCheck
  * Description
  *   Renvoie la liste des gabarits pour le teste du flux
  *   de sous-traitance
  *
  */
  function GetProcessCheck(ivInLine varchar2)
    return TProcessCheckTable pipelined
  is
    ltRecProcessCheck tProcessCheckRecord;
  begin
    for tplReceipt in (select distinct column_value DOC_GAUGE_ID
                                     , rownum
                                  from table(PCS.CHARLISTTOTABLE(ivInLine, '/') )
                              order by 2 asc) loop
      ltRecProcessCheck.DOC_GAUGE_ID  := tplReceipt.DOC_GAUGE_ID;
      pipe row(ltRecProcessCheck);
    end loop;
  end GetProcessCheck;

  /**
  * Description
  *   test if position is ok for Subcontracting purchases
  */
  function ControlDocPdeBeforeGenerate(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return varchar2
  is
    -- test if the source detail has not already been used
    function controlAlreadyLinked
      return boolean
    is
      lTemp DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    begin
      select DOC_POSITION_DETAIL_ID
        into lTemp
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = iPositionDetailId
         and FAL_LOT_ID is null;

      return true;
    exception
      when no_data_found then
        return false;
    end controlAlreadyLinked;

    -- test if the source detail don't belong to a multi-detail position
    function controlNoMultiDetail
      return boolean
    is
      lnbSisters pls_integer;
    begin
      select count(*)
        into lnbSisters
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION_DETAIL PDE2
       where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId
         and PDE2.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and PDE2.DOC_POSITION_DETAIL_ID <> PDE.DOC_POSITION_DETAIL_ID;

      if lnbSisters = 0 then
        return true;
      else
        return false;
      end if;
    end controlNoMultiDetail;

    -- test if the source detail belongs to a subcontracting purchase gauge
    function controlIsSubcontractGauge
      return boolean
    is
      lTemp DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    begin
      select DOC_POSITION_DETAIL_ID
        into lTemp
        from DOC_POSITION_DETAIL PDE
       where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId
         and IsSUPOGauge(PDE.DOC_GAUGE_ID) = 1;

      return true;
    exception
      when no_data_found then
        return false;
    end controlIsSubcontractGauge;

    -- test if the source detail belongs to a subcontracting purchase gauge
    function controlHasGoodDefSubCData
      return boolean
    is
      lSupplierId DOC_POSITION_DETAIL.PAC_THIRD_ID%type;
      lGoodId     DOC_POSITION_DETAIL.GCO_GOOD_ID%type;
    begin
      select PDE.PAC_THIRD_ID
           , PDE.GCO_MANUFACTURED_GOOD_ID
        into lSupplierId
           , lGoodId
        from DOC_POSITION_DETAIL PDE
       where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId;

      return PPS_I_LIB_FUNCTIONS.IsDefaultSubCNomenclatureId(lGoodId, lSupplierId) is not null;
    end controlHasGoodDefSubCData;

    -- contrôle les données de sous-traitance
    function ControlSubcontractComplData
      return varchar2
    is
      lComplDataId DOC_POSITION.GCO_COMPL_DATA_ID%type;
    begin
      select POS.GCO_COMPL_DATA_ID
        into lComplDataId
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
       where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID;

      return PPS_I_LIB_FUNCTIONS.checkSubcontractPComplData(lComplDataId);
    end ControlSubcontractComplData;
  begin
    -- must be completed later
    if not controlAlreadyLinked then
      return PCS.PC_FUNCTIONS.TranslateWord('Traitement impossible car cette position a déjà généré un OF de sous-traitance.');
    elsif not controlNoMultiDetail then
      return PCS.PC_FUNCTIONS.TranslateWord('Traitement impossible car ce detail appartient à une position qui a plusieurs détails.');
    elsif not controlIsSubcontractGauge then
      return PCS.PC_FUNCTIONS.TranslateWord('Traitement impossible car ce gabarit n''est pas de type "commande de sous-traitance d''achat".');
    else
      return ControlSubcontractComplData;
    end if;
  end ControlDocPdeBeforeGenerate;

  /**
  * Description
  *   test if position detail is ok for Subcontracting purchases batch delete
  */
  function ControlDocPdeBeforeDelete(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return varchar2
  is
  begin
    return null;
  end ControlDocPdeBeforeDelete;

  /**
  * Description
  *   test if compl data is OK
  */
  procedure checkComplData(
    iComplDataId        in     GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type
  , iSupplierId         in     GCO_COMPL_DATA_SUBCONTRACT.PAC_SUPPLIER_PARTNER_ID%type default null
  , iManufacturedGoodId in     GCO_COMPL_DATA_SUBCONTRACT.GCO_GOOD_ID%type default null
  , iServiceId          in     GCO_COMPL_DATA_SUBCONTRACT.GCO_GCO_GOOD_ID%type default null
  , oError              out    varchar2
  )
  is
    ltplComplData GCO_COMPL_DATA_SUBCONTRACT%rowtype;
  begin
    -- get complementary datas tuple
    select *
      into ltplComplData
      from GCO_COMPL_DATA_SUBCONTRACT
     where GCO_COMPL_DATA_SUBCONTRACT_ID = iComplDataId;

    -- check if parts list (nomenclature) exists
    if ltplComplData.PPS_NOMENCLATURE_ID is null then
      oError  := PCS.PC_FUNCTIONS.TranslateWord('La donnée complémentaire de sous-traitance n''a pas de nomenclature liée.');
    -- check if it's the right good
    elsif ltplComplData.GCO_GOOD_ID <> nvl(iManufacturedGoodId, ltplComplData.GCO_GOOD_ID) then
      oError  := PCS.PC_FUNCTIONS.TranslateWord('Le bien de la donnée complémentaire de sous-traitance ne correspond pas au bien fabriqué de la position.');
    -- check if the service is not null
    elsif ltplComplData.GCO_GCO_GOOD_ID is null then
      oError  := PCS.PC_FUNCTIONS.TranslateWord('Aucun service n''est renseigné dans la donnée complémentaire de sous-traitance.');
    -- check if it's the right service
    elsif ltplComplData.GCO_GCO_GOOD_ID <> nvl(iServiceId, ltplComplData.GCO_GCO_GOOD_ID) then
      oError  :=
             PCS.PC_FUNCTIONS.TranslateWord('Le service lié des données complémentaires de sous-traitance ne correspond pas au bien principal de la position.');
    -- check if it's the right supplier
    elsif ltplComplData.PAC_SUPPLIER_PARTNER_ID <> nvl(iSupplierId, ltplComplData.PAC_SUPPLIER_PARTNER_ID) then
      oError  :=
        PCS.PC_FUNCTIONS.TranslateWord
                                 ('Le sous-traitant des données complémentaires de sous-traitance ne correspond pas au tiers de la commande de sous-traitance.');
    end if;
  exception
    when others then
      oError  := sqlerrm;
  end checkComplData;

  /**
  * function pValidateSubContractGauge
  * Description
  *   Internal function, if given Gauge is not null return it if of the good type
  * @created fp 20.01.2011
  * @lastUpdate sma 17.02.2012
  * @public
  * @param
  * @return
  */
  function pValidateSubContractGauge(iGaugeId in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type default null, iGaugeTitle in DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type)
    return number
  is
    lResult DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type;
  begin
    -- retrieve the gauge in the default subcontract flow which match with the gauge title
    select max(GAD.DOC_GAUGE_ID)
      into lResult
      from DOC_GAUGE_FLOW_DOCUM GAD
         , DOC_GAUGE_STRUCTURED GAS
         , table(DOC_LIB_GAUGE.GetPossibleFlows(iAdminDomain => cAdminDomainSubContract, iThirdId => null) ) FLO
     where GAD.DOC_GAUGE_FLOW_ID = FLO.column_value
       and GAD.DOC_GAUGE_ID = iGaugeId
       and GAS.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
       and GAS.C_GAUGE_TITLE = iGaugeTitle
       and IsGaugeSubcontractP(iGaugeId) = 1;

    return sign(nvl(lResult, 0) );
  end pValidateSubContractGauge;

  /**
  * Description
  *   Retourne les id des gabarits pour un fournisseur et un type de gabarits
  */
  function GetSubContractGauge(
    iSubContracterId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null
  , iGaugeTitle      in DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type
  )
    return ID_TABLE_TYPE pipelined
  is
    lFlowId DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    lFlowId  := DOC_LIB_GAUGE.GetFlowID(iAdminDomain => cAdminDomainSubContract, iThirdID => iSubContracterId);

    -- retrieve the gauge in the default subcontract flow which match with the gauge title
    for ltplGaugeID in (select GAD.DOC_GAUGE_ID
                          from DOC_GAUGE_FLOW_DOCUM GAD
--                             , DOC_GAUGE_RECEIPT GAR
                        ,      DOC_GAUGE_STRUCTURED GAS
                         where GAD.DOC_GAUGE_FLOW_ID = lFlowId
--                           and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAR.DOC_GAUGE_FLOW_DOCUM_ID
                           and GAS.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
                           and GAS.C_GAUGE_TITLE = iGaugeTitle
                           and IsGaugeSubcontractP(GAD.DOC_GAUGE_ID) = 1) loop
      pipe row(ltplGaugeID.DOC_GAUGE_ID);
    end loop;
  end GetSubContractGauge;

  /**
  * Description
  *   return SUPO (CAST in french) gauge id for a customer
  */
  function GetSUPOGaugeId(iSubContracterId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null)
    return ID_TABLE_TYPE pipelined
  is
  begin
    for tplGaugeId in (select *
                         from table(GetSubContractGauge(iSubContracterId => iSubContracterId, iGaugeTitle => '1') ) ) loop
      pipe row(tplGaugeId.column_value);
    end loop;
  end GetSUPOGaugeId;

  /**
  * Description
  *   return 1 if given gauge is SUPO (CAST in french)
  */
  function IsSUPOGauge(iGaugeId in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type)
    return number
  is
  begin
    return pValidateSubContractGauge(iGaugeId => iGaugeId, iGaugeTitle => '1');
  end IsSUPOGauge;

  /**
  * Description
  *   return SUPRS (BRAST in french) gauge id for a customer
  */
  function GetSUPRSGaugeId(iSubContracterId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null)
    return ID_TABLE_TYPE pipelined
  is
  begin
    for tplGaugeId in (select *
                         from table(GetSubContractGauge(iSubContracterId => iSubContracterId, iGaugeTitle => '3') ) ) loop
      pipe row(tplGaugeId.column_value);
    end loop;
  end GetSUPRSGaugeId;

  /**
  * Description
  *   return 1 if given gauge is SUPRS (BRAST in french)
  */
  function IsSUPRSGauge(iGaugeId in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type)
    return number
  is
  begin
    return pValidateSubContractGauge(iGaugeId => iGaugeId, iGaugeTitle => '3');
  end IsSUPRSGauge;

  /**
  * Description
  *   return SUPI (FFAST in french) gauge id for a customer
  */
  function GetSUPIGaugeId(iSubContracterId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null)
    return ID_TABLE_TYPE pipelined
  is
  begin
    for tplGaugeId in (select *
                         from table(GetSubContractGauge(iSubContracterId => iSubContracterId, iGaugeTitle => '4') ) ) loop
      pipe row(tplGaugeId.column_value);
    end loop;
  end GetSUPIGaugeId;

  /**
  * Description
  *   return 1 if given gauge is SUPI (FFAST in french)
  */
  function IsSUPIGauge(iGaugeId in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type)
    return number
  is
  begin
    return pValidateSubContractGauge(iGaugeId => iGaugeId, iGaugeTitle => '4');
  end IsSUPIGauge;

  /**
  * Description
  *   return SUPO (CAST in french) lags delay
  */
  procedure getSUPOLags(
    iControlDelay       in     GCO_COMPL_DATA_SUBCONTRACT.CSU_CONTROL_DELAY%type
  , iSubcontractDelay   in     GCO_COMPL_DATA_SUBCONTRACT.CSU_SUBCONTRACTING_DELAY%type
  , iEconomicalQuantity in     GCO_COMPL_DATA_SUBCONTRACT.CSU_ECONOMICAL_QUANTITY%type
  , iFixDelay           in     GCO_COMPL_DATA_SUBCONTRACT.CSU_FIX_DELAY%type
  , iLotQuantity        in     GCO_COMPL_DATA_SUBCONTRACT.CSU_LOT_QUANTITY%type
  , iBasisQuantity      in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type
  , oBasisLag           out    number
  , oInterLag           out    number
  , oFinalLag           out    number
  )
  is
    lnTotalDuration GCO_COMPL_DATA_SUBCONTRACT.CSU_SUBCONTRACTING_DELAY%type;
    lnQuantity      DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type;
  begin
    if nvl(iBasisQuantity, 0) > 0 then
      lnQuantity  := iBasisQuantity;
    else
      lnQuantity  := nvl(iLotQuantity, 1);   /* Quantité utilisée pour initialiser la qté de la commande. */
    end if;

    if nvl(lnQuantity, 0) > 0 then
      oBasisLag        := 0;

      -- Durée fixe
      if (nvl(iFixDelay, 0) = 1) then
        ----
        -- Calcul de la durée totale
        -- Durée total = Durée d'achat sous-traitance + Durée de contrôle
        --
        lnTotalDuration  := nvl(iSubcontractDelay, 0) + nvl(iControlDelay, 0);
      else   -- Durée proportionnelle
        ----
        -- Calcul de la durée totale
        -- Durée total = ( ( Quantité d'achat ST / Quantité standard ) * Durée d'achat sous-traitance ) + Durée de contrôle
        --
        lnTotalDuration  := ( (lnQuantity / nvl(iLotQuantity, lnQuantity) ) * nvl(iSubcontractDelay, 0) ) + nvl(iControlDelay, 0);
      end if;

      -- Durée total = Délai de commande + Durée totale
      lnTotalDuration  := oBasisLag + lnTotalDuration;
      -- Ecart intermédiaire (Délai intermédiaire) = Durée total - Durée de contrôle
      oInterLag        := lnTotalDuration - nvl(iControlDelay, 0);
      -- Ecart final (Délai de disponibilité (CAST)) = Durée de contrôle
      oFinalLag        := nvl(iControlDelay, 0);
    end if;
  end getSUPOLags;

  /**
  * procedure pSubcontractBranchManyRecept
  * Description
  *   Test de la branche du flux de sous-traintance pour avertir l'utilisateur
  *   en cas de multiple réception de lot de fabrication
  *
  */
  procedure pSubcontractBranchManyRecept(iFlowId in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type, iPath in varchar2, iListWarning in out varchar2)
  is
    lnReceiptCount number;
  begin
    -- Compte le nombre de réception pour cette branche de flux
    select count(1) countReceipt
      into lnReceiptCount
      from table(GetProcessCheck(iPath) ) GAU
         , DOC_GAUGE_POSITION GAP
         , STM_MOVEMENT_KIND MOK
     where GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID(+)
       and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+)
       and GAP.C_GAUGE_TYPE_POS(+) = 1
       and GAP.C_DOC_LOT_TYPE(+) = '001'
       and MOK.MOK_BATCH_RECEIPT = 1;

    if lnReceiptCount > 1 then
      for tplFlowDocum in (select GAD.DOC_GAUGE_FLOW_DOCUM_ID
                             from table(GetProcessCheck(iPath) ) GAU
                                , DOC_GAUGE_POSITION GAP
                                , STM_MOVEMENT_KIND MOK
                                , DOC_GAUGE_FLOW_DOCUM GAD
                            where GAD.DOC_GAUGE_FLOW_ID = iFlowId
                              and GAD.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                              and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID(+)
                              and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+)
                              and GAP.C_GAUGE_TYPE_POS(+) = 1
                              and GAP.C_DOC_LOT_TYPE(+) = '001'
                              and MOK.MOK_BATCH_RECEIPT = 1) loop
        --Récupérer le document du flux pour monter l'erreur
        if    (iListWarning is null)
           or (instr(iListWarning, tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID) = 0) then
          iListWarning  := iListWarning || tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID || ',';
        end if;
      end loop;
    end if;
  end;

  /**
  * function checkSubcontractFlowManyRecept
  * Description
  *   Test du flux de sous-traintance pour avertir l'utilisateur
  *   en cas de multiple réception de lot de fabrication
  *
  */
  function checkSubcontractFlowManyRecept(iFlowId in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type)
    return varchar2
  is
    -- Liste des flux de documents possédant une erreur
    lvFlowDocumId varchar2(4000) := '';
    -- Branche du flux (liste des gabarits du flux)
    lvPath        varchar2(4000) := null;
  begin
    for tplFlow in (select GAD.DOC_GAUGE_ID
                         , GAU.GAU_DESCRIBE
                      from DOC_GAUGE_FLOW_DOCUM GAD
                         , DOC_GAUGE GAU
                     where GAU.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
                       and GAD.DOC_GAUGE_FLOW_ID = iFlowId
                       and GAD_ORIGIN_DOC = 1) loop
      for tplBranch in (select     level
                                 , v.father
                                 , v.son
                                 , sys_connect_by_path(v.father, '/') || '/' || v.son gauge_path
                              from (select GAD.DOC_GAUGE_ID son
                                         , GAR.DOC_DOC_GAUGE_ID father
                                      from DOC_GAUGE_FLOW_DOCUM GAD
                                         , DOC_GAUGE_RECEIPT GAR
                                     where GAD.DOC_GAUGE_FLOW_ID = iFlowId
                                       and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAR.DOC_GAUGE_FLOW_DOCUM_ID) v
                        start with v.father = tplFlow.DOC_GAUGE_ID
                        connect by nocycle prior v.son = v.father) loop
        if    (lvPath is null)
           or (instr(tplBranch.gauge_path, lvPath) > 0) then
          lvPath  := tplBranch.gauge_path;
        else
          -- Test de la branche du flux
          pSubcontractBranchManyRecept(iFlowId, lvPath, lvFlowDocumId);
          lvPath  := tplBranch.gauge_path;
        end if;
      end loop;
    end loop;

    -- Test de la branche du flux
    pSubcontractBranchManyRecept(iFlowId, lvPath, lvFlowDocumId);
    return lvFlowDocumId;
  end checkSubcontractFlowManyRecept;

  /**
  * procedure pSubcontractBranchNoRecept
  * Description
  *   Test de la branche du flux de sous-traintance pour avertir l'utilisateur
  *   en cas d'absence de réception de lot de fabrication
  *
  */
  procedure pSubcontractBranchNoRecept(iFlowId in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type, iPath in varchar2, iListWarning in out varchar2)
  is
    lnReceiptCount number;
  begin
    -- Compte le nombre de réception pour cette branche de flux
    select count(1) countReceipt
      into lnReceiptCount
      from table(GetProcessCheck(iPath) ) GAU
         , DOC_GAUGE_POSITION GAP
         , STM_MOVEMENT_KIND MOK
     where GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID(+)
       and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+)
       and GAP.C_GAUGE_TYPE_POS(+) = 1
       and GAP.C_DOC_LOT_TYPE(+) = '001'
       and MOK.MOK_BATCH_RECEIPT = 1;

    if lnReceiptCount = 0 then
      for tplFlowDocum in (select GAD.DOC_GAUGE_FLOW_DOCUM_ID
                             from table(GetProcessCheck(iPath) ) GAU
                                , DOC_GAUGE_POSITION GAP
                                , DOC_GAUGE_FLOW_DOCUM GAD
                            where GAD.DOC_GAUGE_FLOW_ID = iFlowId
                              and GAD.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                              and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID(+)
                              and GAP.STM_MOVEMENT_KIND_ID is not null
                              and GAP.C_GAUGE_TYPE_POS(+) = 1
                              and GAP.C_DOC_LOT_TYPE(+) = '001') loop
        --Récupérer le document du flux pour monter l'erreur
        if    (iListWarning is null)
           or (instr(iListWarning, tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID) = 0) then
          iListWarning  := iListWarning || tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID || ',';
        end if;
      end loop;
    end if;
  end;

  /**
  * function checkSubcontractFlowNoRecept
  * Description
  *   Test du flux de sous-traintance pour avertir l'utilisateur
  *   en cas d'absence de réception de lot de fabrication
  *
  */
  function checkSubcontractFlowNoRecept(iFlowId in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type)
    return varchar2
  is
    lnReceiptCount number;
    lvFlowDocumId  varchar2(4000) := '';
    lvPath         varchar2(4000) := null;
  begin
    for tplFlow in (select GAD.DOC_GAUGE_ID
                         , GAU.GAU_DESCRIBE
                      from DOC_GAUGE_FLOW_DOCUM GAD
                         , DOC_GAUGE GAU
                     where GAU.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
                       and GAD.DOC_GAUGE_FLOW_ID = iFlowId
                       and GAD_ORIGIN_DOC = 1) loop
      for tplBranch in (select     level
                                 , v.father
                                 , v.son
                                 , sys_connect_by_path(v.father, '/') || '/' || v.son gauge_path
                              from (select GAD.DOC_GAUGE_ID son
                                         , GAR.DOC_DOC_GAUGE_ID father
                                      from DOC_GAUGE_FLOW_DOCUM GAD
                                         , DOC_GAUGE_RECEIPT GAR
                                     where GAD.DOC_GAUGE_FLOW_ID = iFlowId
                                       and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAR.DOC_GAUGE_FLOW_DOCUM_ID) v
                        start with v.father = tplFlow.DOC_GAUGE_ID
                        connect by nocycle prior v.son = v.father) loop
        if    (lvPath is null)
           or (instr(tplBranch.gauge_path, lvPath) > 0) then
          lvPath  := tplBranch.gauge_path;
        else
          -- Test de la branche du flux
          pSubcontractBranchNoRecept(iFlowId, lvPath, lvFlowDocumId);
          lvPath  := tplBranch.gauge_path;
        end if;
      end loop;
    end loop;

    -- Test de la branche du flux
    pSubcontractBranchNoRecept(iFlowId, lvPath, lvFlowDocumId);
    return lvFlowDocumId;
  end checkSubcontractFlowNoRecept;

  /**
  * function GetTotalCompDelivQty
  * Description
  *   Renvoi la qté totale (provisoire + définitive) d'un composant d'un lot envoyé au sous-traitant
  */
  function GetTotalCompDelivQty(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iLocationID      in STM_LOCATION.STM_LOCATION_ID%type default null
  , iC_DOC_LINK_TYPE in DOC_LINK.C_DOC_LINK_TYPE%type default '01'
  )
    return number
  is
    lnQty number default 0;
  begin
    select nvl(sum(PDE.PDE_FINAL_QUANTITY), 0)
      into lnQty
      from DOC_LINK LNK
         , DOC_POSITION_DETAIL PDE
     where LNK.C_DOC_LINK_TYPE = iC_DOC_LINK_TYPE
       and LNK.FAL_LOT_MATERIAL_LINK_ID = iFalLotMatLinkID
       and PDE.DOC_POSITION_DETAIL_ID = LNK.DOC_PDE_TARGET_ID
       and (   PDE.STM_LOCATION_ID = iLocationID
            or iLocationID is null);

    return lnQty;
  end GetTotalCompDelivQty;

  /**
  * function GetCompDelivQty
  * Description
  *   Renvoi la qté d'un composant d'un lot envoyé au sous-traitant
  */
  function GetCompDelivQty(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iLocationID      in STM_LOCATION.STM_LOCATION_ID%type default null
  , iProvQty         in number default 0
  , iC_DOC_LINK_TYPE in DOC_LINK.C_DOC_LINK_TYPE%type
  )
    return number
  is
    lnQty number default 0;
  begin
    select nvl(sum(PDE.PDE_FINAL_QUANTITY), 0)
      into lnQty
      from DOC_LINK LNK
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where LNK.C_DOC_LINK_TYPE = iC_DOC_LINK_TYPE
       and LNK.FAL_LOT_MATERIAL_LINK_ID = iFalLotMatLinkID
       and PDE.DOC_POSITION_DETAIL_ID = LNK.DOC_PDE_TARGET_ID
       and (   PDE.STM_LOCATION_ID = iLocationID
            or iLocationID is null)
       and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and (    (    iProvQty = 1
                 and POS.C_DOC_POS_STATUS = '01')
            or (    iProvQty = 0
                and POS.C_DOC_POS_STATUS in('02', '03', '04') ) );

    return lnQty;
  end GetCompDelivQty;

  /**
  * function IsGaugeSubcontractP
  * Description
  *   Renvoi 1 si le gabarit est flagué sous-traitance d'achat
  */
  function IsGaugeSubcontractP(iGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
    lnResult number(1);
  begin
    select nvl(max(1), 0)
      into lnResult
      from DOC_GAUGE_STRUCTURED GAS
         , DOC_GAUGE_POSITION GAP
     where GAS.DOC_GAUGE_ID = iGaugeID
       and GAP.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and GAP.C_DOC_LOT_TYPE = '001';

    return lnResult;
  end IsGaugeSubcontractP;

  /**
  * function IsDocumentSubcontractP
  * Description
  *   Renvoi 1 si le document est flagué sous-traitance d'achat
  */
  function IsDocumentSubcontractP(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
  begin
    return IsGaugeSubcontractP(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_GAUGE_ID', iDocumentId) );
  end IsDocumentSubcontractP;

  /**
  * function IsPositionSubcontractP
  * Description
  *    Renvoi 1 si le document de la position est flagué sous-traitance d'achat
  */
  function IsPositionSubcontractP(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  as
    lIsPositionSubcontractP number;
  begin
    select sign(DOC_POSITION_ID)
      into lIsPositionSubcontractP
      from DOC_POSITION
     where DOC_POSITION_ID = iPositionID
       and C_DOC_LOT_TYPE = '001'
       and FAL_LOT_ID is not null
       and C_GAUGE_TYPE_POS = '1';

    return lIsPositionSubcontractP;
  exception
    when no_data_found then
      return 0;
  end IsPositionSubcontractP;

  /**
  * function IsBatchCptStkOutage
  * Description
  *   Indique s'il y a une rupture de stock (dans le stock STT) pour
  *     un ou plusieurs composants du lot de fabrication
  */
  function IsBatchCptStkOutage(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    cursor lcrComp
    is
      select   LOM.GCO_GOOD_ID
          from DOC_POSITION POS
             , FAL_LOT LOT
             , FAL_LOT_MATERIAL_LINK LOM
         where POS.DOC_POSITION_ID = iPositionID
           and POS.FAL_LOT_ID = LOT.FAL_LOT_ID
           and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
           and LOM.C_KIND_COM = 1   -- Genre de lien composant uniquement
           and LOM.FAL_LOT_MATERIAL_LINK_ID not in(select FAL_LOT_MATERIAL_LINK_ID
                                                     from FAL_FACTORY_IN)
      order by LOM.LOM_SEQ;

    ltplComp           lcrComp%rowtype;
    lnDocumentID       DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnSupplierID       STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type;
    lnStockID          STM_STOCK.STM_STOCK_ID%type;
    lnLocationID       STM_LOCATION.STM_LOCATION_ID%type;
    lnCptTotalQty      FAL_LOT_MATERIAL_LINK.LOM_BOM_REQ_QTY%type;
    lnCptTotalAttibQty FAL_LOT_MATERIAL_LINK.LOM_BOM_REQ_QTY%type;
    lnCountUsedCpt     number;
    lnStkAvailableQty  STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    lnSUPRSGauge       number(1)                                        := 0;
    lnSUPIGauge        number(1)                                        := 0;
    lnResult           number(1)                                        := 0;
    lnGenerateMovement DOC_POSITION.POS_GENERATE_MOVEMENT%type;
  begin
    -- Rechercher le fournisseur du document
    select DMT.DOC_DOCUMENT_ID
         , DMT.PAC_THIRD_ID
         , DOC_LIB_SUBCONTRACTP.IsSUPRSGauge(DMT.DOC_GAUGE_ID)
         , DOC_LIB_SUBCONTRACTP.IsSUPIGauge(DMT.DOC_GAUGE_ID)
         , nvl(POS_GENERATE_MOVEMENT, 0)
      into lnDocumentID
         , lnSupplierID
         , lnSUPRSGauge
         , lnSUPIGauge
         , lnGenerateMovement
      from DOC_DOCUMENT DMT
         , DOC_POSITION POS
     where POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
       and POS.DOC_POSITION_ID = iPositionID;

    -- Le contrôle de la rupture de stock des cpt à la réception, se fait uniquement sur le BRAST ou la FFAST si les mouvements ne sont pas
    -- déjà généré.
    if     (    (lnSUPRSGauge = 1)
            or (lnSUPIGauge = 1) )
       and (lnGenerateMovement = 0) then
      -- Rechercher le Stock sous-traitant du fournisseur
      STM_LIB_STOCK.getSubCStockAndLocation(iSupplierId => lnSupplierID, oStockId => lnStockID, oLocationId => lnLocationID);

      if     (lnStockID is not null)
         and (lnLocationID is not null) then
        open lcrComp;

        fetch lcrComp
         into ltplComp;

        -- Liste des composants du lot de la position courante
        --   en excluant tous ceux qui ont déjà été transférés dans le stock atelier
        while(lnResult = 0)
         and (lcrComp%found) loop
          -- Rechercher la qté dispo en stock STT pour le composant
          select nvl(sum(SPO_AVAILABLE_QUANTITY + SPO_PROVISORY_INPUT), 0)
            into lnStkAvailableQty
            from STM_STOCK_POSITION SPO
           where SPO.GCO_GOOD_ID(+) = ltplComp.GCO_GOOD_ID
             and SPO.STM_STOCK_ID(+) = lnStockID
             and SPO.STM_LOCATION_ID(+) = lnLocationID;

          -- Rechercher la qté totale nécessaire pour le composant pour toutes les
          --  positions du document courant
          select   sum(least(POS.POS_BASIS_QUANTITY * LOM.LOM_UTIL_COEF, nvl(LOM.LOM_BOM_REQ_QTY, 0) ) )
                 , count(LOM.GCO_GOOD_ID)
                 , sum(nvl( (select sum(FLN.FLN_QTY)
                               from FAL_NETWORK_NEED FAN
                                  , FAL_NETWORK_LINK FLN
                              where FAN.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
                                and FAN.FAL_NETWORK_NEED_ID = FLN.FAL_NETWORK_NEED_ID), 0) ) TOT_ATTRIB_QTY
              into lnCptTotalQty
                 , lnCountUsedCpt
                 , lnCptTotalAttibQty
              from DOC_POSITION POS
                 , FAL_LOT LOT
                 , FAL_LOT_MATERIAL_LINK LOM
             where POS.DOC_DOCUMENT_ID = lnDocumentID
               and POS.FAL_LOT_ID = LOT.FAL_LOT_ID
               and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
               and LOM.GCO_GOOD_ID = ltplComp.GCO_GOOD_ID
               and LOM.FAL_LOT_MATERIAL_LINK_ID not in(select FAL_LOT_MATERIAL_LINK_ID
                                                         from FAL_FACTORY_IN)
          group by LOM.GCO_GOOD_ID;

          -- La qté totale pour ce composant est supérieure à (qté attribuée + qté en stock)
          if lnCptTotalQty >(lnCptTotalAttibQty + lnStkAvailableQty) then
            -- Si le cpt n'est utilisé qu'une seule fois (il s'agit de la pos courante)
            --  ou que la qté dispo en stock = 0, il y a forcement rupture de stock
            if    (lnCountUsedCpt = 1)
               or (lnStkAvailableQty = 0) then
              lnResult  := 1;
            else
              -- Si le cpt est utilisé plusieurs fois, il faut effectuer un décompte
              -- des qtés pour controler si la rupture a lieu déjà sur cette position
              for ltplGood in (select   least(POS.POS_BASIS_QUANTITY * LOM.LOM_UTIL_COEF, nvl(LOM.LOM_BOM_REQ_QTY, 0) ) as LOM_QTY
                                      , POS.DOC_POSITION_ID
                                      , nvl( (select sum(FLN.FLN_QTY)
                                                from FAL_NETWORK_NEED FAN
                                                   , FAL_NETWORK_LINK FLN
                                               where FAN.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
                                                 and FAN.FAL_NETWORK_NEED_ID = FLN.FAL_NETWORK_NEED_ID)
                                          , 0
                                           ) ATTRIB_QTY
                                   from DOC_POSITION POS
                                      , FAL_LOT LOT
                                      , FAL_LOT_MATERIAL_LINK LOM
                                  where POS.DOC_DOCUMENT_ID = lnDocumentID
                                    and POS.FAL_LOT_ID = LOT.FAL_LOT_ID
                                    and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
                                    and LOM.GCO_GOOD_ID = ltplComp.GCO_GOOD_ID
                                    and LOM.FAL_LOT_MATERIAL_LINK_ID not in(select FAL_LOT_MATERIAL_LINK_ID
                                                                              from FAL_FACTORY_IN)
                               order by POS.POS_NUMBER
                                      , LOM.LOM_SEQ) loop
                -- Position courante et que la qté dispo est inférieure à la qté du cpt
                if     (iPositionID = ltplGood.DOC_POSITION_ID)
                   and (lnStkAvailableQty <(ltplGood.LOM_QTY - ltplGood.ATTRIB_QTY) ) then
                  -- Rupture
                  lnResult  := 1;
                end if;

                -- Soustraire la qté nécessaire pour le cpt courant
                lnStkAvailableQty  := lnStkAvailableQty -(ltplGood.LOM_QTY - ltplGood.ATTRIB_QTY);
              end loop;
            end if;
          end if;

          fetch lcrComp
           into ltplComp;
        end loop;

        close lcrComp;
      end if;
    end if;

    return lnResult;
  end IsBatchCptStkOutage;

  /**
  * function IsBatchGoodCharactMissing
  * Description
  *   Indique si des valeurs de caractérisation sont manquantes sur le bien du
  *     lot de fabrication
  */
  function IsBatchGoodCharactMissing(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lnLotId        DOC_POSITION_DETAIL.FAL_LOT_ID%type;
    lnNbChar       number(1);
    lnPosQTy       DOC_POSITION.POS_FINAL_QUANTITY%type   := 0;
    lnPartialQty   DOC_POSITION.POS_FINAL_QUANTITY%type   := 0;
    lnDetailQty    DOC_POSITION.POS_FINAL_QUANTITY%type   := 0;
    lnSUBCPGauge   number(1)                              := 0;
    lnBatchReceipt number(1)                              := 0;
  begin
    -- Si la position n'est pas en statut 'à confirmer', pas de contrôle de manco de caractérisaiton.
    if FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'DOC_POSITION', iv_column_name => 'C_DOC_POS_STATUS', it_pk_value => iPositionID) <> '01' then
      return 0;
    end if;

    -- Le manco de détails lot n'est vérifié QUE pour les documents de sous-traitance Achats provoquant la réception à la confirmation
    if doReceive(iPositionId => iPositionID) = 0 then
      return 0;
    end if;

    -- il doit y avoir une position et un detail tout autre distribution est fausse
    select GCO_I_LIB_CHARACTERIZATION.NbCharInStock(POS.GCO_MANUFACTURED_GOOD_ID)
         , POS.POS_FINAL_QUANTITY
         , PDE.FAL_LOT_ID
         , sign(DOC_LIB_SUBCONTRACTP.IsSUPRSGauge(POS.DOC_GAUGE_ID) + DOC_LIB_SUBCONTRACTP.IsSUPIGauge(POS.DOC_GAUGE_ID) )
         , MOK.MOK_BATCH_RECEIPT
      into lnNbChar
         , lnPosQTy
         , lnLotId
         , lnSUBCPGauge
         , lnBatchReceipt
      from DOC_POSITION POS
         , DOC_POSITION_DETAIL PDE
         , STM_MOVEMENT_KIND MOK
     where POS.DOC_POSITION_ID = iPositionId
       and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID;

    -- si on a des caracterisation
    -- qu'on est en sous-traitance d'achat
    -- que le genre de mouvement lié provoque la réception
    -- et qu'on a un lot de fabrication lié
    if     lnNbChar > 0
       and lnSUBCPGauge = 1
       and lnBatchReceipt = 1
       and lnLotId is not null then
      -- Vérifier s'il y a des valeurs de caract manquantes pour le PT
      -- Le contrôle s'effectue uniquement sur le gabarit BRAST ou FFAST
      select nvl(sum(case
                       when(    FAD.GCO_CHARACTERIZATION_ID is not null
                            and FAD_CHARACTERIZATION_VALUE_1 is null)
                        or (    FAD.GCO_GCO_CHARACTERIZATION_ID is not null
                            and FAD_CHARACTERIZATION_VALUE_2 is null)
                        or (    FAD.GCO2_GCO_CHARACTERIZATION_ID is not null
                            and FAD_CHARACTERIZATION_VALUE_3 is null)
                        or (    FAD.GCO3_GCO_CHARACTERIZATION_ID is not null
                            and FAD_CHARACTERIZATION_VALUE_4 is null)
                        or (    FAD.GCO4_GCO_CHARACTERIZATION_ID is not null
                            and FAD_CHARACTERIZATION_VALUE_5 is null) then FAD_BALANCE_QTY
                       else 0
                     end
                    )
               , 0
                )
           , nvl(sum(FAD_BALANCE_QTY), 0)
        into lnPartialQty
           , lnDetailQty
        from FAL_LOT LOT
           , FAL_LOT_DETAIL FAD
       where LOT.FAL_LOT_ID = lnLotId
         and LOT.FAL_LOT_ID = FAD.FAL_LOT_ID
         and FAD_BALANCE_QTY <> 0;

      -- Si la somme qté des détail lot moins les saisies partielles correspond au moins à la qté de la position , il n'y a pas de mancos
      if lnPosQty <=(lnDetailQty - lnPartialQty) then
        return 0;
      else
        return 1;
      end if;
    else
      -- pas de rupture
      return 0;
    end if;
  end IsBatchGoodCharactMissing;

  /**
  * Description
  *   Retourne 1 si un apparaige est nécessaire sur le PT du lot de fabrication
  */
  function IsBatchGoodAlignementNeeded(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  as
    lLotID DOC_POSITION.FAL_LOT_ID%type;
  begin
    if FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'DOC_POSITION', iv_column_name => 'C_DOC_POS_STATUS', it_pk_value => iPositionID) = '01' then
      /* Récupération de l'ID du lot de la position du document */
      lLotID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'DOC_POSITION', iv_column_name => 'FAL_LOT_ID', it_pk_value => iPositionID);

      /* Si le produit fabriqué du lot de fabrication et géré avec une caractérisation */
      if    (FAL_I_LIB_BATCH.isPieceChar(iLotID => lLotID) = 1)
         or (FAL_I_LIB_BATCH.isLotChar(iLotID => lLotID) = 1)
         or (FAL_I_LIB_BATCH.isVersionChar(iLotID => lLotID) = 1)
         or (FAL_I_LIB_BATCH.isChronoChar(iLotID => lLotID) = 1) then
        /* Si au moins un des composants non fourni par le sous-traitant est lui aussi géré avec une caractérisation */
        if    (FAL_I_LIB_BATCH.hasFPCptPieceChar(iLotID => lLotID) = 1)
           or (FAL_I_LIB_BATCH.hasFPCptLotChar(iLotID => lLotID) = 1)
           or (FAL_I_LIB_BATCH.hasFPCptVersionChar(iLotID => lLotID) = 1)
           or (FAL_I_LIB_BATCH.hasFPCptChronoChar(iLotID => lLotID) = 1) then
          return 1;
        end if;
      end if;
    end if;

    return 0;
  end IsBatchGoodAlignementNeeded;

  /**
  * Description
  *   Retourne 1 si un apparaige est manquant sur le PT du lot de fabrication de la position
  */
  function IsPositionPairingMissing(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  as
    lPairingIsMissing number;
  begin
    -- Le manco d'appairage n'est vérifié QUE pour les documents de sous-traitance Achats provoquant la réception à la confirmation
    if doReceive(iPositionId => iPositionID) = 0 then
      return 0;
    end if;

    -- Vérifie que la quantité de la position (SU) ne soit pas supérieure à la quantité appairée non réceptionnée de de chaque composants de lot.
    select count('x')
      into lPairingIsMissing
      from dual
     where exists(
             select   'x'
                 from FAL_LOT_MATERIAL_LINK lom
                    , FAL_LOT lot
                    , DOC_POSITION pos
                where pos.DOC_POSITION_ID = iPositionID
                  and pos.C_DOC_POS_STATUS = '01'
                  and pos.C_DOC_LOT_TYPE = '001'
                  and pos.FAL_LOT_ID is not null
                  and lot.FAL_LOT_ID = pos.FAL_LOT_ID
                  and lom.FAL_LOT_ID = lot.FAL_LOT_ID
                  and lom.C_TYPE_COM = FAL_BATCH_FUNCTIONS.cptActive
                  and lom.C_KIND_COM = FAL_BATCH_FUNCTIONS.ckComponent
                  and lom.LOM_STOCK_MANAGEMENT = 1
                  and (   GCO_I_LIB_CHARACTERIZATION.IsPieceChar(lom.GCO_GOOD_ID) = 1
                       or GCO_I_LIB_CHARACTERIZATION.IsLotChar(lom.GCO_GOOD_ID) = 1
                       or GCO_I_LIB_CHARACTERIZATION.IsVersionChar(lom.GCO_GOOD_ID) = 1
                       or GCO_I_LIB_CHARACTERIZATION.IsChronoChar(lom.GCO_GOOD_ID) = 1
                      )
                  and (   FAL_I_LIB_BATCH.isPieceChar(pos.FAL_LOT_ID) = 1
                       or FAL_I_LIB_BATCH.isLotChar(pos.FAL_LOT_ID) = 1
                       or FAL_I_LIB_BATCH.isVersionChar(pos.FAL_LOT_ID) = 1
                       or FAL_I_LIB_BATCH.isChronoChar(pos.FAL_LOT_ID) = 1
                      )
             group by lom.GCO_GOOD_ID
                    , lot.FAL_LOT_ID
               having sum(pos.POS_FINAL_QUANTITY_SU * LOM_UTIL_COEF / LOM_REF_QTY) >
                        nvl( (select nvl(sum(ldl.LDL_QTY), 0)
                                from FAL_LOT_DETAIL fad
                                   , FAL_LOT_DETAIL_LINK ldl
                                   , STM_STOCK_POSITION spo
                               where fad.FAL_LOT_ID = lot.FAL_LOT_ID
                                 and spo.GCO_GOOD_ID = lom.GCO_GOOD_ID
                                 and spo.STM_STOCK_ID = FAL_LIB_SUBCONTRACTP.GetStockSubcontractP(iFalLotId => fad.FAL_LOT_ID)
                                 and spo.STM_STOCK_POSITION_ID = ldl.STM_STOCK_POSITION_ID
                                 and ldl.FAL_LOT_DETAIL_ID = fad.FAL_LOT_DETAIL_ID
                                 and ldl.FAL_FACTORY_IN_ID is null)
                          , 0
                           ) );

    return lPairingIsMissing;
  end IsPositionPairingMissing;

  /**
  * Description
  *   Retourne 1 si un apparaige est manquant sur le document STT
  */
  function isDocumentAlignementMissing(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  as
  begin
    for ltplPos in (select DOC_POSITION_ID
                      from DOC_POSITION
                     where DOC_DOCUMENT_ID = iDocumentID
                       and C_DOC_POS_STATUS = '01'
                       and C_DOC_LOT_TYPE = '001'
                       and FAL_LOT_ID is not null) loop
      if IsPositionPairingMissing(iPositionID => ltplPos.DOC_POSITION_ID) = 1 then
        return 1;
      end if;
    end loop;

    return 0;
  end isDocumentAlignementMissing;

  /**
  * function GetCompDelivQty
  * Description
  *   Renvoi la qté d'un composant livré ou prochainement livré au sous-traitant CST -> BLST
  */
  function GetCompDelivQty(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iLocationID      in STM_LOCATION.STM_LOCATION_ID%type default null
  , iProvQty         in number default 0
  )
    return number
  is
  begin
    return DOC_LIB_SUBCONTRACT.GetCompQty(iFalLotMatLinkID => iFalLotMatLinkID, iLocationID => iLocationID, iProvQty => iProvQty, iC_DOC_LINK_TYPE => '01');
  end GetCompDelivQty;

  /**
  * function GetCompReturnQty
  * Description
  *   Renvoi la qté d'un composant retourné ou prochainement retourné par le sous-traitant CST -> BLRST
  */
  function GetCompReturnQty(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iLocationID      in STM_LOCATION.STM_LOCATION_ID%type default null
  , iProvQty         in number default 0
  )
    return number
  is
  begin
    return DOC_LIB_SUBCONTRACT.GetCompQty(iFalLotMatLinkID => iFalLotMatLinkID, iLocationID => iLocationID, iProvQty => iProvQty, iC_DOC_LINK_TYPE => '02');
  end GetCompReturnQty;

  /**
  * Description
  *   Retourne le gabarit utilisé lors de la génération des BLST - Livraison des composants de la sous-traitance d'achat.
  */
  function getDeliveryGaugeID
    return DOC_GAUGE.DOC_GAUGE_ID%type
  as
  begin
    /* Lecture de la config contenant le gabarit BLST */
    return FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTP_DELIV_GAUGE') );
  end getDeliveryGaugeID;

  /**
  * Description
  *   Retourne le gabarit utilisé lors de la génération des BLRST - Retour des composants de la sous-traitance d'achat.
  */
  function getReturnGaugeID
    return DOC_GAUGE.DOC_GAUGE_ID%type
  as
  begin
    /* Lecture de la config contenant le gabarit BLRST */
    return FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTP_RETURN_GAUGE') );
  end getReturnGaugeID;

  /**
  * Description
  *   Indique si le gabarit utilisé pour un document de transfert en sous-traitance d'achat.
  */
  function isDeliveryGauge(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
  begin
    if (getDeliveryGaugeID = iGaugeId) then
      return 1;
    else
      return 0;
    end if;
  end isDeliveryGauge;

  /**
  * Description
  *   Indique si le gabarit utilisé pour un document de retour de sous-traitance d'achat.
  */
  function isReturnGauge(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
  begin
    if (getReturnGaugeID = iGaugeId) then
      return 1;
    else
      return 0;
    end if;
  end isReturnGauge;

  /**
  * Description
  *    Indique si la confirmation du document (ou du document de la position) transmis implique la réception de l'OF de sous-traitance Achat lié.
  *    Les conditions sont réunies si
  *      - Le gabarit est un gabarit de sous-traitance achat (C_DOC_LOT_TYPE = '001' sur DOC_GAUGE_POSITION)
  *      - Le document provoque des réceptions d'OF (MOK_BATCH_RECEIPT = 1 sur type de mouvement lié à au moins un position)
  *      - Aucun parent du document ne provoque des réceptions d'OF
  *      - Le document est un Bulletin de réception STA (BRAST) ou une Facture Fournisseur STA (FFAST). }
  */
  function doReceive(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null, iPositionId in DOC_POSITION.DOC_POSITION_ID%type default null)
    return integer
  as
    lnDocId   DOC_POSITION.DOC_DOCUMENT_ID%type;
    lnGaugeId DOC_POSITION.DOC_GAUGE_ID%type;
  begin
    if iPositionId is not null then
      select DOC_DOCUMENT_ID
           , DOC_GAUGE_ID
        into lnDocId
           , lnGaugeId
        from DOC_POSITION
       where DOC_POSITION_ID = iPositionID;
    else
      select DOC_DOCUMENT_ID
           , DOC_GAUGE_ID
        into lnDocId
           , lnGaugeId
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = iDocumentId;
    end if;

    -- Réception OF sous-traitance Achat à la confirmation si :
    --    - Le gabarit est un gabarit de sous-traitance achat (C_DOC_LOT_TYPE = '001' sur DOC_GAUGE_POSITION)
    --    - Le document provoque des réceptions d'OF (MOK_BATCH_RECEIPT = 1 sur type de mouvement lié à au moins un position)
    --    - Aucun parent du document ne provoque des réceptions d'OF
    --    - Le document est un Bulletin de réception STA (BRAST) ou une Facture Fournisseur STA (FFAST). }
    if     DOC_LIB_SUBCONTRACTP.IsGaugeSubcontractP(lnGaugeId) = 1
       and DOC_LIB_SUBCONTRACT.isDocumentBatchReceipt(lnDocId) = 1
       and DOC_LIB_SUBCONTRACT.isDocumentFathersBatchReceipt(lnDocId) = 0
       and (   DOC_LIB_SUBCONTRACTP.IsSUPRSGauge(lnGaugeId) = 1   -- BRAST
            or DOC_LIB_SUBCONTRACTP.IsSUPIGauge(lnGaugeId) = 1) then
      return 1;
    else
      return 0;
    end if;
  end doReceive;
end DOC_LIB_SUBCONTRACTP;
