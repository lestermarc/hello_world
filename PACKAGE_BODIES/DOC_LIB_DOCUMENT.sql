--------------------------------------------------------
--  DDL for Package Body DOC_LIB_DOCUMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_DOCUMENT" 
is
  -- Configurations
  gcGAL_CUR_SALE_MULTI_COVER boolean := PCS.PC_CONFIG.GetBooleanConfig('GAL_CUR_SALE_MULTI_COVER');

  /**
  * Description : Recherche l'ID du Flux actif selon un domaine et un tiers
  */
  function GetDmtNumber(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DMT_NUMBER%type
  is
    lResult DOC_DOCUMENT.DMT_NUMBER%type;
  begin
    select DMT_NUMBER
      into lResult
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentId;

    return lResult;
  end GetDmtNumber;

  /**
  * Description
  *   renvoie le tiers du document
  */
  function GetPacThird(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.PAC_THIRD_ID%type
  is
    lResult DOC_DOCUMENT.PAC_THIRD_ID%type;
  begin
    select PAC_THIRD_ID
      into lResult
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentId;

    return lResult;
  end GetPacThird;

  /**
  * Description
  *   vérifie si on est dans une situation de document avec limite de crédit
  *   double vérification Gabarit/Tiers
  */
  function IsCreditLimit(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    lDocumentId         DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lPartnerType        varchar2(1);
    lPartnerCategory    PAC_CUSTOM_PARTNER.C_PARTNER_CATEGORY%type;
    lPartnerLimitType   PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type;
    lPartnerLimitAmount PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type;
    lGroupLimitType     PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type;
    lGroupLimitAmount   PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type;
  begin
    for ltplDocument in (select GAU.C_ADMIN_DOMAIN
                              , DMT.PAC_THIRD_ID
                              , DMT.ACS_FINANCIAL_CURRENCY_ID
                              , DMT.DMT_DATE_DOCUMENT
                           from DOC_DOCUMENT DMT
                              , DOC_GAUGE GAU
                          where DOC_DOCUMENT_ID = iDocumentId
                            and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID) loop
      -- recherche du type de partenaire
      if ltplDocument.C_ADMIN_DOMAIN in (cAdminDomainPurchase, cAdminDomainSubContract) then
        lPartnerType  := 'S';

        select nvl(C_PARTNER_CATEGORY, '0')
          into lPartnerCategory
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = ltplDocument.PAC_THIRD_ID;
      else
        lPartnerType  := 'C';

        select nvl(C_PARTNER_CATEGORY, '0')
          into lPartnerCategory
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = ltplDocument.PAC_THIRD_ID;
      end if;

      DOC_DOCUMENT_FUNCTIONS.GetCreditLimit(lPartnerType
                                          , ltplDocument.PAC_THIRD_ID
                                          , ltplDocument.ACS_FINANCIAL_CURRENCY_ID
                                          , ltplDocument.DMT_DATE_DOCUMENT
                                          , lPartnerCategory
                                          , lPartnerLimitType
                                          , lPartnerLimitAmount
                                          , lGroupLimitType
                                          , lGroupLimitAmount
                                           );

      -- S'il existe un contrôle sur la limite
      if    (lPartnerLimitType in('2', '3') )
         or (lGroupLimitType in('2', '3') ) then
        return true;
      else
        return false;
      end if;
    end loop;
  end IsCreditLimit;

  /**
  * procedure CtrlDocumentDate
  * Description
  *   Ctrl la validité de la date du document
  */
  procedure CtrlDocumentDate(
    iDocDate      in     date
  , ivDocMode     in     varchar2
  , iGaugeID      in     DOC_GAUGE.DOC_GAUGE_ID%type
  , oErrorCaption out    varchar2
  , oErrorText    out    varchar2
  , oFailReason   out    varchar2
  )
  is
    lvStartCtrl   DOC_GAUGE_STRUCTURED.C_START_CONTROL_DATE%type;
    lvCtrlDateDoc DOC_GAUGE_STRUCTURED.C_CONTROLE_DATE_DOCUM%type;
    lnOk          integer;
  begin
    oErrorCaption  := null;
    oErrorText     := null;
    oFailReason    := null;

    begin
      -- Rechercher les infos sur le gabarit
      select nvl(C_START_CONTROL_DATE, '0')
           , nvl(C_CONTROLE_DATE_DOCUM, '0')
        into lvStartCtrl
           , lvCtrlDateDoc
        from DOC_GAUGE_STRUCTURED
       where DOC_GAUGE_ID = iGaugeID;
    exception
      when no_data_found then
        lvStartCtrl    := '0';
        lvCtrlDateDoc  := '0';
    end;

    -- Champ Controle date document (C_START_CONTROL_DATE)
    -- Valeurs
    --   1 : Création/modification document
    --   2 : Confirmation document
    --   3 : Création/modification/confirmation document
    if    (     (upper(ivDocMode) = 'INSERT')
           and lvStartCtrl in('1', '3') )
       or (     (upper(ivDocMode) = 'UPDATE')
           and lvStartCtrl in('1', '3') )
       or (     (upper(ivDocMode) = 'CONFIRM')
           and lvStartCtrl in('2', '3') ) then
      DOC_DOCUMENT_FUNCTIONS.ValidateDocumentDate(aDate         => iDocDate
                                                , aCtrlType     => lvCtrlDateDoc
                                                , ErrorTitle    => oErrorCaption
                                                , ErrorMsg      => oErrorText
                                                , ConfirmFail   => oFailReason
                                                , CtrlOK        => lnOk
                                                 );
    end if;
  end CtrlDocumentDate;

  /**
  * procedure CtrlProjectRisk
  * Description
  *   Ctrl si le document est lié à une affaire avec risque de change
  *   Ctrl le nbre d'affaire liées au document
  */
  procedure CtrlProjectRisk(
    iDocumentID       in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oProjectID        out    GAL_PROJECT.GAL_PROJECT_ID%type
  , oProjectRiskManag out    number
  , oProjectCount     out    number
  )
  is
  begin
    GAL_I_LIB_PROJECT.GetLogisticRiskProjectID(iDocumentID => iDocumentID, oProjectID => oProjectID, oProjectCount => oProjectCount);

    if oProjectCount > 0 then
      oProjectRiskManag  := 1;
    else
      oProjectRiskManag  := 0;
    end if;
  end CtrlProjectRisk;

  /**
  * function IsOriginalDocument
  * Description
  *   Indique s'il s'agit d'un document d'origine (détail sans de lien de copie/décharge)
  */
  function IsOriginalDocument(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lnOriginalDocument number(1);
  begin
    select case
             when count(*) = 0 then 1
             else 0
           end as ORIGINAL_DOCUMENT
      into lnOriginalDocument
      from DOC_DOCUMENT DMT
         , DOC_POSITION POS
         , DOC_POSITION_DETAIL PDE
     where DMT.DOC_DOCUMENT_ID = iDocumentID
       and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and (   PDE.DOC_DOC_POSITION_DETAIL_ID is not null
            or PDE.DOC2_DOC_POSITION_DETAIL_ID is not null);

    return lnOriginalDocument;
  end IsOriginalDocument;

  /**
  * Description
  *   Indique si le document a un problème de parité lié aux risques de change
  */
  function IsCurrencyRiskProblem(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lResult number := 0;
  begin
    select count(*)
      into lResult
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentId
       and C_CONFIRM_FAIL_REASON in('130', '131', '132', '133', '134');

    return lResult;
  end IsCurrencyRiskProblem;

  /**
  * Description
  *   Recherche, pour un document en risque de change dont la tranche n'est pas encore liée,
  *   le montant total à tester
  */
  function GetCurrencyRiskTotalToTest(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lPosCumul             DOC_POSITION.POS_NET_VALUE_EXCL%type                          := 0;
    lChargeCumul          DOC_POSITION.POS_NET_VALUE_EXCL%type                          := 0;
    lRiskVirtualId        GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lRiskType             DOC_DOCUMENT.C_CURR_RATE_COVER_TYPE%type;
    lCurrentBalanceAmount DOC_FOOT.FOO_CURR_RISK_BAL_POS_AMOUNT%type;
  begin
    select GAL_CURRENCY_RISK_VIRTUAL_ID
         , nvl(C_CURR_RATE_COVER_TYPE, '00')
      into lRiskVirtualId
         , lRiskType
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentID;

      -- Positions
    /*  for ltplPosition in (select   PDE.DOC_DOC_POSITION_DETAIL_ID
                                  , PDE_BASIS_QUANTITY
                                  , avg(POS.DOC_POSITION_ID) DOC_POSITION_ID
                                  , avg(POS.POS_BASIS_QUANTITY) POS_BASIS_QUANTITY
                                  , avg(decode(lRiskType, '04', POS.POS_NET_VALUE_EXCL_B, POS.POS_NET_VALUE_EXCL)) POS_NET_VALUE_EXCL
                               from DOC_POSITION_DETAIL PDE
                                  , DOC_POSITION POS
                              where PDE.DOC_DOCUMENT_ID = iDocumentId
                                and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                                and POS.C_GAUGE_TYPE_POS <> '6'
                           group by PDE.DOC_POSITION_DETAIL_ID
                                  , PDE.DOC_DOC_POSITION_DETAIL_ID
                                  , PDE.PDE_BASIS_QUANTITY) loop
                                  */
                                  -- question à FPE -> pourquoi le groupe by??
    for ltplPosition in (select   PDE.DOC_DOC_POSITION_DETAIL_ID
                                , nvl(PDE_CURR_RISK_DISCHARGE_DONE, 0) PDE_CURR_RISK_DISCHARGE_DONE
                                , PDE_BALANCE_QUANTITY
                                , avg(POS.DOC_POSITION_ID) DOC_POSITION_ID
                                , avg(POS.POS_BASIS_QUANTITY) POS_BASIS_QUANTITY
                                , avg(decode(lRiskType, '04', POS.POS_NET_VALUE_EXCL_B, POS.POS_NET_VALUE_EXCL) ) POS_NET_VALUE_EXCL
                             from DOC_POSITION_DETAIL PDE
                                , DOC_POSITION POS
                            where PDE.DOC_DOCUMENT_ID = iDocumentId
                              and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                              and POS.C_DOC_POS_STATUS <> '05'
                              and POS.C_GAUGE_TYPE_POS <> '6'
                              and POS.POS_BASIS_QUANTITY <> 0
                         group by PDE.DOC_POSITION_DETAIL_ID
                                , PDE.DOC_DOC_POSITION_DETAIL_ID
                                , PDE.PDE_CURR_RISK_DISCHARGE_DONE
                                , PDE.PDE_BALANCE_QUANTITY) loop
      -- position issue d'une décharge et seulementà la décharge (hmo 02.2014)
      if     ltplPosition.DOC_DOC_POSITION_DETAIL_ID is not null
         and ltplPosition.PDE_CURR_RISK_DISCHARGE_DONE = 0
                                                          -- and lCurrentBalanceAmount = 0--(ltplPosition.A_DATEMOD-ltplPosition.A_DATECRE) <= 25/86400 then
      then
        for ltplDetParent in (select avg(POS.POS_BASIS_QUANTITY) POS_BASIS_QUANTITY
                                   , avg(decode(lRiskType, '04', POS.POS_NET_VALUE_EXCL_B, POS.POS_NET_VALUE_EXCL) ) POS_NET_VALUE_EXCL
                                from DOC_POSITION_DETAIL PDE
                                   , DOC_POSITION POS
                               where PDE.DOC_POSITION_DETAIL_ID = ltplPosition.DOC_DOC_POSITION_DETAIL_ID
                                 and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                                 and POS_BASIS_QUANTITY <> 0) loop
          -- recherche le delta entre la position père et la position fils si on a changé le montant lors de la décharge
          lPosCumul  :=
            lPosCumul +
            (ltplPosition.POS_NET_VALUE_EXCL / ltplPosition.POS_BASIS_QUANTITY) * ltplPosition.PDE_BALANCE_QUANTITY -
            (ltplDetParent.POS_NET_VALUE_EXCL / ltplDetParent.POS_BASIS_QUANTITY
            ) * ltplPosition.PDE_BALANCE_QUANTITY;
        end loop;
      -- nouvelle position
      elsif ltplPosition.POS_BASIS_QUANTITY <> 0 then
        lPosCumul  := lPosCumul + (ltplPosition.POS_NET_VALUE_EXCL * ltplPosition.PDE_BALANCE_QUANTITY) / ltplPosition.POS_BASIS_QUANTITY;
      end if;
    end loop;

    --Taxes de pied
    for ltplFootCharge in (select FCH.C_CALCULATION_MODE
                                , FCH.C_CHARGE_ORIGIN
                                , decode(FCH.C_FINANCIAL_CHARGE, '02', -1, 1) FCH_SIGN
                                , decode(FCH.C_FINANCIAL_CHARGE, '02', -1, 1) * decode(lRiskType, '04', FCH.FCH_EXCL_AMOUNT_B, FCH.FCH_EXCL_AMOUNT)
                                                                                                                                                FCH_EXCL_AMOUNT
                                , FCH.FCH_RATE
                                , FCH.FCH_EXPRESS_IN
                                , FCH.FCH_FROZEN
                                , FCH.DOC_FOOT_CHARGE_SRC_ID
                             from DOC_FOOT_CHARGE FCH
                            where FCH.DOC_FOOT_ID = iDocumentId) loop
      if ltplFootCharge.C_CHARGE_ORIGIN in('MAN', 'AUTO') then
        lChargeCumul  := lChargeCumul + ltplFootCharge.FCH_EXCL_AMOUNT;
      elsif ltplFootCharge.C_CALCULATION_MODE in('0', '1', '6', '8', '9', '10', '11') then
        declare
          lParentAmount DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT%type
                 := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_FOOT_CHARGE', 'FCH_EXCL_AMOUNT', ltplFootCharge.DOC_FOOT_CHARGE_SRC_ID)
                    * ltplFootCharge.FCH_SIGN;
        begin
          lChargeCumul  := lChargeCumul +(ltplFootCharge.FCH_EXCL_AMOUNT - lParentAmount);
        end;
      elsif ltplFootCharge.FCH_FROZEN = 0 then
        lChargeCumul  := lChargeCumul + lPosCumul * ltplFootCharge.FCH_RATE / ltplFootCharge.FCH_EXPRESS_IN;
      end if;
    end loop;

    select nvl(FOO_CURR_RISK_BAL_FCH_AMOUNT, 0) + nvl(FOO_CURR_RISK_BAL_POS_AMOUNT, 0) + DOC_INVOICE_EXPIRY_FUNCTIONS.GetCurrRiskDischargedAmount(iDocumentID)
      into lCurrentBalanceAmount
      from DOC_FOOT
     where DOC_FOOT_ID = iDocumentId;

    if lRiskVirtualId is null then
      -- pas de tranche liée, retourne le montant total
      return lPosCumul + lChargeCumul;
    else
      -- tranche liée, retourne le delta entre le montant total et le montant déjà consommé (montant actuel)
      return (lPosCumul + lChargeCumul) - lCurrentBalanceAmount;
    end if;
  end GetCurrencyRiskTotalToTest;

  /**
  * procedure CtrlDocumentCurrRiskAmount
  * Description
  *   Vérifie si le montant du document est couvert par la tranche passée en param
  */
  function CtrlDocumentCurrRiskAmount(
    iDocumentID        in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iCurrRiskVirtualID in GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  )
    return number
  is
    lnResult        number(1);
    lnAmount        number(20, 6);
    lnRiskForced    DOC_DOCUMENT.DMT_CURR_RISK_FORCED%type;
    lnDocPositionID DOC_POSITION.DOC_POSITION_ID%type;
  begin
    select max(doc_position_id)
      into lnDocPositionID
      from DOC_POSITION
     where DOC_DOCUMENT_ID = iDocumentID;

    -- Document de vente multi-couverture (pas de contrôle sur la couverture du montant) et pas de contrôle de couverture si on a à faire à des NC
    if    DOC_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(iDocumentID) = 1
       or DOC_INVOICE_EXPIRY_FUNCTIONS.GetInvoiceExpiryDocType(iDocumentId) in('4', '5', '6')
       or DOC_LIB_POSITION.IsPosFromCreditNoteOutOfExpiry(lnDocPositionID) = 1 then
      lnResult  := 1;
    else
      -- Vérifier si la couverture virtuelle a été forcée
      select nvl(max(DMT_CURR_RISK_FORCED), 0)
        into lnRiskForced
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = iDocumentID;

      -- Si la couverture virtuelle a été forcée, il ne faut pas effectuer le ctrl du montant
      if lnRiskForced = 1 then
        lnResult  := 1;
      else
        -- Appeler la méthode qui obtient le "delta" du montant à contrôler
        lnAmount  := DOC_LIB_DOCUMENT.GetCurrencyRiskTotalToTest(iDocumentID => iDocumentID);
        -- Contrôle si la tranche virtuelle dispose du solde necessaire pour couvrir ce montant
        lnResult  := GAL_LIB_PROJECT.CheckCurrencyRiskVirtual(iVirtualID => iCurrRiskVirtualID, iAmount => lnAmount);
      end if;
    end if;

    return lnResult;
  end CtrlDocumentCurrRiskAmount;

  /**
  * function pGetDocChildrenIDList
  * Description
  *    Retourne La liste des ID des documents enfants.
  * @created age 25.05.2012
  * @lastUpdate age 23.09.2013
  * @private
  * @param iRootDocumentID       : ID du document source de la recherche.
  * @param iMaxSearchLevel       : Niveau max. de recherche des documents enfants
  * @param iCurentRecursiveLevel : Niveau actuel
  * @param ioDocumentIdList      : Liste des ID des documents trouvé.
  * @param iUntilMvtDone         : Si 1, retourne les ID enfants jusqu'au document contenant au moins un position générant les mouvements pour la STO.
  * @return : Liste des ID des document enfants.
  */
  procedure pGetDocChildrenIDList(
    iRootDocumentID       in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iMaxSearchLevel       in     number default 10
  , iCurentRecursiveLevel in     number default 1
  , ioDocumentIdList      in out ID_TABLE_TYPE
  , iUntilMvtDoneSTO      in     number default 0
  , iExtTaskLinkID        in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  )
  as
    lLastDocId number(12) := -1;
  begin
    /* Pour chaque document enfant trouvé */
    for ltplChildrenDmtIds in (select doc_child.DOC_DOCUMENT_ID
                                    , doc_child.DMT_NUMBER
                                    , pde_father.DOC_POSITION_ID FATHER_POS_ID
                                    , pde_child.DOC_POSITION_ID CHILD_POS_ID
                                    , pos_child.C_DOC_POS_STATUS CHILD_POS_STATUS
                                 from DOC_DOCUMENT doc_child
                                    , DOC_POSITION pos_child
                                    , DOC_POSITION_DETAIL pde_child
                                    , DOC_POSITION_DETAIL pde_father
                                    , DOC_POSITION pos_father
                                    , DOC_DOCUMENT doc_father
                                where pos_child.DOC_DOCUMENT_ID = doc_child.DOC_DOCUMENT_ID
                                  and pde_child.DOC_POSITION_ID = pos_child.DOC_POSITION_ID
                                  and pde_child.DOC_DOC_POSITION_DETAIL_ID = pde_father.DOC_POSITION_DETAIL_ID
                                  and (   iExtTaskLinkID is null
                                       or pde_child.FAL_SCHEDULE_STEP_ID = iExtTaskLinkID)
                                  and pde_father.DOC_POSITION_ID = pos_father.DOC_POSITION_ID
                                  and pos_father.DOC_DOCUMENT_ID = doc_father.DOC_DOCUMENT_ID
                                  and doc_father.DOC_DOCUMENT_ID = iRootDocumentID) loop
      if     (    (iUntilMvtDoneSTO = 0)
              or (    DOC_I_LIB_SUBCONTRACTO.DoPositiontComponentsMvt(iPositionId => ltplChildrenDmtIds.FATHER_POS_ID) <> 1
                  and not(    DOC_I_LIB_SUBCONTRACTO.DoPositiontComponentsMvt(iPositionId => ltplChildrenDmtIds.CHILD_POS_ID) = 1
                          and ltplChildrenDmtIds.CHILD_POS_STATUS <> '01'
                         )
                 )
             )
         and lLastDocId <> ltplChildrenDmtIds.DOC_DOCUMENT_ID then
        ioDocumentIdList.extend(1);
        ioDocumentIdList(ioDocumentIdList.count)  := ltplChildrenDmtIds.DOC_DOCUMENT_ID;
        lLastDocId                                := ltplChildrenDmtIds.DOC_DOCUMENT_ID;

        /* tant que le niveau max n'est pas atteint, appel récursif 1 niveau plus profond */
        if (iCurentRecursiveLevel < iMaxSearchLevel) then
          pGetDocChildrenIDList(iRootDocumentID         => ltplChildrenDmtIds.DOC_DOCUMENT_ID
                              , iMaxSearchLevel         => iMaxSearchLevel
                              , iCurentRecursiveLevel   => iCurentRecursiveLevel + 1
                              , ioDocumentIdList        => ioDocumentIdList
                              , iUntilMvtDoneSTO        => iUntilMvtDoneSTO
                              , iExtTaskLinkID          => iExtTaskLinkID
                               );
        end if;
      end if;
    end loop;
  end pGetDocChildrenIDList;

  /**
  * Description
  *    Retourne La liste des ID des documents enfants. Si iUntilMvtDone vaut 1, retourne les ID des documents enfants jusqu'à ce qu'au moins une des
  *    positions enfants (y.c.) génère des mouvements pour la sous-traitance opératoire.
  */
  function getDocChildrenIDList(
    iRootDocumentID  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iMaxSearchLevel  in number default 10
  , iUntilMvtDoneSTO in number default 0
  , iExtTaskLinkID   in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  )
    return ID_TABLE_TYPE pipelined
  as
    lDocumentIdList ID_TABLE_TYPE := ID_TABLE_TYPE();
  begin
    pGetDocChildrenIDList(iRootDocumentID         => iRootDocumentID
                        , iMaxSearchLevel         => iMaxSearchLevel
                        , iCurentRecursiveLevel   => 1
                        , ioDocumentIdList        => lDocumentIdList
                        , iUntilMvtDoneSTO        => iUntilMvtDoneSTO
                        , iExtTaskLinkID          => iExtTaskLinkID
                         );

    if lDocumentIdList.count > 0 then
      for i in lDocumentIdList.first .. lDocumentIdList.last loop
        pipe row(lDocumentIdList(i) );
      end loop;
    end if;
  exception
    when NO_DATA_NEEDED then
      return;
  end getDocChildrenIDList;

  /**
  * Description
  *    Retourne la liste de tous les document parent d'un document
  *    Le document passé en paramètre fait partie de la liste si iIncludeSelf = 1
  */
  function getDocParentIdList(iChildDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iIncludeSelf in number default 1)
    return ID_TABLE_TYPE pipelined
  is
  begin
    for ltplParent in (select distinct DOC_DOCUMENT_ID
                                  from (select     DOC_DOCUMENT_ID
                                              from DOC_POSITION_DETAIL
                                        connect by prior DOC_DOC_POSITION_DETAIL_ID = DOC_POSITION_DETAIL_ID
                                        start with DOC_DOCUMENT_ID = iChildDocumentID) ) loop
      if    (iIncludeSelf = 1)
         or (     (iIncludeSelf = 0)
             and (ltplParent.DOC_DOCUMENT_ID <> iChildDocumentID) ) then
        pipe row(ltplParent.DOC_DOCUMENT_ID);
      end if;
    end loop;
  end getDocParentIdList;

  /**
  * Description
  *    Retourne la liste de tous les document parent d'une position
  */
  function getPosDocParentIdList(iChildPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return ID_TABLE_TYPE pipelined
  is
  begin
    for ltplCurrent in (select DOC_DOCUMENT_ID
                          from DOC_POSITION
                         where DOC_POSITION_ID = iChildPositionID) loop
      pipe row(ltplCurrent.DOC_DOCUMENT_ID);
    end loop;

    for ltplParent in (select distinct DOC_DOCUMENT_ID
                                  from (select     DOC_DOCUMENT_ID
                                              from DOC_POSITION_DETAIL
                                        connect by prior DOC_DOC_POSITION_DETAIL_ID = DOC_POSITION_DETAIL_ID
                                        start with DOC_POSITION_ID = iChildPositionID) ) loop
      pipe row(ltplParent.DOC_DOCUMENT_ID);
    end loop;
  end getPosDocParentIdList;

  /**
  * Description
  *   Indique si le document a au moins été déchargé une fois
  */
  function IsDocumentDischarged(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION_DETAIL PDE_SON
     where PDE.DOC_DOCUMENT_ID = iDocumentId
       and PDE_SON.DOC_DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
       and PDE.GCO_GOOD_ID is not null;

    return(lCount > 0);
  end IsDocumentDischarged;

  /**
  * Description
  *   Indique si le document a été totalement déchargé
  */
  function IsDocumentTotallyDischarged(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    -- si toute les positions ont un solde à 0 alors on considère le document comme entièrement déchargé
    select count(*)
      into lCount
      from DOC_POSITION_DETAIL PDE
     where PDE.DOC_DOCUMENT_ID = iDocumentId
       and PDE.PDE_BALANCE_QUANTITY <> 0
       and PDE.GCO_GOOD_ID is not null;

    return(lCount = 0);
  end IsDocumentTotallyDischarged;

  /**
  * function IsDocCurrRiskSaleMultiCover
  * Description
  *   Indique si le document réponds au conditions de multi-couverture pour le risque de change
  *     Les conditions sont :
  *        La config GAL_CUR_SALE_MULTI_COVER doit être à OUI
  *        Document du domaine vente
  *        Document qui n'effectue pas un transfert en finance
  */
  function IsDocCurrRiskSaleMultiCover(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lnResult      number(1);
    lvAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lnFinCharge   DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
  begin
    lnResult  := 0;

    -- Config GAL_CUR_SALE_MULTI_COVER indiquant la multi-couverture sur les docs vente sans transfert en finance
    if     (iDocumentID is not null)
       and (gcGAL_CUR_SALE_MULTI_COVER) then
      begin
        -- Infos du gabarit
        select GAU.C_ADMIN_DOMAIN
             , GAS.GAS_FINANCIAL_CHARGE
          into lvAdminDomain
             , lnFinCharge
          from DOC_DOCUMENT DMT
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
         where DMT.DOC_DOCUMENT_ID = iDocumentID
           and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

        -- Domaine Vente et pas de transfert en finance
        if     (lvAdminDomain = '2')
           and (lnFinCharge = 0) then
          lnResult  := 1;
        end if;
      exception
        when no_data_found then
          lnResult  := 0;
      end;
    end if;

    return lnResult;
  end IsDocCurrRiskSaleMultiCover;

  /**
  * function IsDocAdminDomainPur
  * Description
  *   Indique si le document est dans le domaine achat
  */
  function IsDocAdminDomainPur(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lnResult      number(1);
    lvAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type;
  begin
    lnResult  := 0;

    begin
      -- Infos du gabarit
      select GAU.C_ADMIN_DOMAIN
        into lvAdminDomain
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

      if lvAdminDomain = '1' then
        lnResult  := 1;
      end if;
    exception
      when no_data_found then
        lnResult  := 0;
    end;

    return lnResult;
  end IsDocAdminDomainPur;

  /**
  * function IsDocAdminDomainSal
  * Description
  *   Indique si le document est dans le domaine vente
  */
  function IsDocAdminDomainSal(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lnResult      number(1);
    lvAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type;
  begin
    lnResult  := 0;

    begin
      -- Infos du gabarit
      select GAU.C_ADMIN_DOMAIN
        into lvAdminDomain
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

      if lvAdminDomain = '2' then
        lnResult  := 1;
      end if;
    exception
      when no_data_found then
        lnResult  := 0;
    end;

    return lnResult;
  end IsDocAdminDomainSal;

  /**
  * procedure getThirdsDocument
  * Description
  *   Get Sold to/ Contract, Invoice, Tariff and Delivery partner
  */
  procedure getThirdsDocument(
    iPacThirdID          in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , iAdminDomain         in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , iGaugeID             in     DOC_GAUGE.DOC_GAUGE_ID%type
  , oPacThirdDeliveryID  out    DOC_DOCUMENT.PAC_THIRD_DELIVERY_ID%type
  , oPacThirdInvoicingID out    DOC_DOCUMENT.PAC_THIRD_ACI_ID%type
  , oPacThirdTariffID    out    DOC_DOCUMENT.PAC_THIRD_ID%type
  )
  is
    lPAC_THIRD_DELIVERY_ID DOC_DOCUMENT.PAC_THIRD_DELIVERY_ID%type;
    lPAC_THIRD_ACI_ID      DOC_DOCUMENT.PAC_THIRD_ACI_ID%type;
    lPAC_THIRD_TARIFF_ID   DOC_DOCUMENT.PAC_THIRD_ID%type;
  begin
    --1. Get from Object Parameters
    oPacThirdDeliveryID   := PCS.PC_I_LIB_SESSION.GetObjectParam('PAC_THIRD_DELIVERY_ID');
    oPacThirdInvoicingID  := PCS.PC_I_LIB_SESSION.GetObjectParam('PAC_THIRD_ACI_ID');
    oPacThirdTariffID     := PCS.PC_I_LIB_SESSION.GetObjectParam('PAC_THIRD_TARIFF_ID');

    --2. Get from Template
    if    (oPacThirdDeliveryID is null)
       or (oPacThirdInvoicingID is null)
       or (oPacThirdTariffID is null) then
      if (nvl(iGaugeID, 0) <> 0) then
        select GAU.PAC_THIRD_DELIVERY_ID
             , GAU.PAC_THIRD_ACI_ID
             , GAU.PAC_THIRD_ID
          into lPAC_THIRD_DELIVERY_ID
             , lPAC_THIRD_ACI_ID
             , lPAC_THIRD_TARIFF_ID
          from DOC_GAUGE GAU
         where DOC_GAUGE_ID = iGaugeID;
      end if;

      if (oPacThirdDeliveryID is null) then
        oPacThirdDeliveryID  := lPAC_THIRD_DELIVERY_ID;
      end if;

      if (oPacThirdInvoicingID is null) then
        oPacThirdInvoicingID  := lPAC_THIRD_ACI_ID;
      end if;

      if (oPacThirdTariffID is null) then
        oPacThirdTariffID  := lPAC_THIRD_TARIFF_ID;
      end if;

      --3. Get from Customer/ Supplier
      if    (oPacThirdDeliveryID is null)
         or (oPacThirdInvoicingID is null)
         or (oPacThirdTariffID is null) then
        select (case
                  when iAdminDomain in('1', '5') then SUP.PAC_PAC_THIRD_1_ID
                  when iAdminDomain in('2', '7') then CUS.PAC_PAC_THIRD_1_ID
                  else nvl(CUS.PAC_PAC_THIRD_1_ID, SUP.PAC_PAC_THIRD_1_ID)
                end
               ) PAC_THIRD_ACI_ID
             , (case
                  when iAdminDomain in('1', '5') then SUP.PAC_PAC_THIRD_2_ID
                  when iAdminDomain in('2', '7') then CUS.PAC_PAC_THIRD_2_ID
                  else nvl(CUS.PAC_PAC_THIRD_2_ID, SUP.PAC_PAC_THIRD_2_ID)
                end
               ) PAC_THIRD_TARIFF_ID
             , (case
                  when iAdminDomain in('1', '5') then SUP.PAC_SUPPLIER_PARTNER_ID
                  when iAdminDomain in('2', '7') then CUS.PAC_CUSTOM_PARTNER_ID
                  else nvl(CUS.PAC_CUSTOM_PARTNER_ID, SUP.PAC_SUPPLIER_PARTNER_ID)
                end
               ) PAC_THIRD_DELIVERY_ID
          into lPAC_THIRD_ACI_ID
             , lPAC_THIRD_TARIFF_ID
             , lPAC_THIRD_DELIVERY_ID
          from PAC_THIRD THI
             , PAC_CUSTOM_PARTNER CUS
             , PAC_SUPPLIER_PARTNER SUP
         where THI.PAC_THIRD_ID = iPacThirdID
           and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
           and CUS.C_PARTNER_STATUS(+) = '1'
           and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
           and SUP.C_PARTNER_STATUS(+) = '1';

        if (oPacThirdDeliveryID is null) then
          oPacThirdDeliveryID  := lPAC_THIRD_DELIVERY_ID;
        end if;

        if (oPacThirdInvoicingID is null) then
          oPacThirdInvoicingID  := nvl(lPAC_THIRD_ACI_ID, iPacThirdID);
        end if;

        if (oPacThirdTariffID is null) then
          oPacThirdTariffID  := nvl(lPAC_THIRD_TARIFF_ID, iPacThirdID);
        end if;
      end if;

      --4. Get for the Domain
      if     (oPacThirdDeliveryID is null)
         and (iAdminDomain in('2', '7') ) then
        oPacThirdDeliveryID  := iPacThirdID;
      end if;
    end if;
  end getThirdsDocument;
end DOC_LIB_DOCUMENT;
