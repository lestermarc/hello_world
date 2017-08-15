--------------------------------------------------------
--  DDL for Package Body FAL_PRC_FAL_DOC_PROP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_FAL_DOC_PROP" 
is
  -- ID unique de la session utilisé dans toutes les procédures de (dé)réservation
  cSessionId constant FAL_LOT1.LT1_ORACLE_SESSION%type   := DBMS_SESSION.unique_session_id;

  /**
  * procedure UpdatePropCounters
  * Description : Mise à jour des compteurs des numéros de propositions
  * @created ECA
  * @lastUpdate
  * @private
  * @param
  */
  procedure UpdatePropCounters
  is
  begin
    -- C_PROP_TYPE = 1 et   C_SUPPLY_MODE = 1
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_DOC_PROP', '1', '1') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('1', '1');
    end if;

    -- C_PROP_TYPE = 2 et   C_SUPPLY_MODE = 1
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_DOC_PROP', '2', '1') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('2', '1');
    end if;

    -- C_PROP_TYPE = 4 et   C_SUPPLY_MODE = 2
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_DOC_PROP', '4', '2') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('4', '2');
    end if;

    -- C_PROP_TYPE = 5 et   C_SUPPLY_MODE = 1
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_DOC_PROP', '5', '1') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('5', '1');
    end if;

    -- C_PROP_TYPE = 5 et   C_SUPPLY_MODE = 2
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_DOC_PROP', '5', '2') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('5', '2');
    end if;

    -- C_PROP_TYPE = 3 et   C_SUPPLY_MODE = 1
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_DOC_PROP', '3', '1') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('3', '1');
    end if;
  end UpdatePropCounters;

  /**
  * procedure DeleteFAL_DOC_PROP
  * Description : Suppression des propositions d'appro logistique qui ne sont
  *               ni demandes d'appro, ni issues du pic, ni en consultation,
  *               ni issues du calcul DRP
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iGCO_GOOD_ID : Produit (Si null, pour tous)
  * @param   iListOfStockId : Liste des stock du CB (pour restriction de la suppression)
  * @param   iDeletePropMode : Mode suppresion proposition
  * @param   iDeleteRequestMode : Mode suppression demande d'appro
  * @param   iUpdateRequestvalueMode : Mode Mise à jour demande d'appro
  * @param   iPropOrigin : Origine de la proposition
  * @param   iDeleteWithDate : Suppression proposition plan directeur postérieur à
  * @param   iDate : Date pour suppression à partir de
  */
  procedure DeleteFAL_DOC_PROP(
    iGCO_GOOD_ID            in number
  , iListOfStockId          in varchar2 default null
  , iDeletePropMode         in integer default 0
  , iDeleteRequestMode      in integer default 0
  , iUpdateRequestvalueMode in integer default 0
  , iPropOrigin             in integer default 0
  , iDeleteWithdate         in integer default 0
  , iDate                   in date default null
  )
  is
    type T_TABLE_ID is table of number;

    T_FAL_DOC_PROP_ID T_TABLE_ID;
    vQuery            varchar2(2000);
  begin
    -- Propositions standards
    if iPropOrigin = FAL_PRC_FAL_PROP_COMMON.STD_PROP then
      vQuery  :=
        ' SELECT FDP.FAL_DOC_PROP_ID ' ||
        '   FROM FAL_DOC_PROP FDP ' ||
        '  WHERE NOT EXISTS (SELECT 1 ' ||
        '                      FROM FAL_DOC_CONSULT FDC ' ||
        '                     WHERE FDC.FAL_DOC_PROP_ID = FDP.FAL_DOC_PROP_ID) ' ||
        '    AND FDP.FAL_PIC_ID IS NULL ' ||
        '    AND FDP.FAL_PIC_LINE_ID IS NULL ' ||
        '    AND FDP.FAL_SUPPLY_REQUEST_ID IS NULL ' ||
        '    AND FDP.STM_DISTRIBUTION_UNIT_ID IS NULL ';
    -- Propositions issues des demandes d'appro
    elsif iPropOrigin = FAL_PRC_FAL_PROP_COMMON.REQUEST_PROP then
      vQuery  :=
        ' SELECT FDP.FAL_DOC_PROP_ID ' ||
        '   FROM FAL_DOC_PROP FDP ' ||
        '  WHERE NOT EXISTS (SELECT 1 ' ||
        '                      FROM FAL_DOC_CONSULT FDC ' ||
        '                     WHERE FDC.FAL_DOC_PROP_ID = FDP.FAL_DOC_PROP_ID) ' ||
        '    AND FDP.FAL_PIC_ID IS NULL ' ||
        '    AND FDP.FAL_PIC_LINE_ID IS NULL ' ||
        '    AND FDP.FAL_SUPPLY_REQUEST_ID IS NOT NULL ' ||
        '    AND FDP.STM_DISTRIBUTION_UNIT_ID IS NULL ';
    -- Propositions issues des demandes de réapprovisionnement
    elsif iPropOrigin = FAL_PRC_FAL_PROP_COMMON.DRA_PROP then
      vQuery  :=
        ' select DOC.FAL_DOC_PROP_ID ' ||
        '   from FAL_DOC_PROP DOC ' ||
        '      , FAL_PROP_DEF DEF  ' ||
        '  where DEF.C_PREFIX_PROP = DOC.C_PREFIX_PROP  ' ||
        '    and C_PROP_TYPE = ''5'' ';
    -- Propositions issues du plan directeur
    elsif iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDA_PROP then
      vQuery  :=
        ' select FDP.FAL_DOC_PROP_ID ' ||
        '   from FAL_DOC_PROP FDP ' ||
        '  where FDP.FAL_SUPPLY_REQUEST_ID is null ' ||
        '    and (FDP.FAL_PIC_ID is not null or FDP.FAL_PIC_LINE_ID is not null )' ||
        '    and (:DeleteWithdate = 0 ' ||
        '          or (:DeleteWithdate = 1 and FDP.FDP_BASIS_DELAY > :iDate)) ' ||
        '    and not exists (select 1 ' ||
        '                      from FAL_DOC_CONSULT FDC ' ||
        '                     where FDC. FAL_DOC_PROP_ID = FDP.FAL_DOC_PROP_ID) ' ||
        '    and FDP.STM_DISTRIBUTION_UNIT_ID is null ';
    -- Propositions de fabrication issues du plan directeur
    elsif    iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDF_PROP
          or iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDAST_PROP
          or iPropOrigin = FAL_PRC_FAL_PROP_COMMON.POAST_PROP then
      return;
    end if;

    -- Restriction produit
    if nvl(iGCO_GOOD_ID, 0) <> 0 then
      vQuery  := vQuery || '    AND GCO_GOOD_ID = ' || iGCO_GOOD_ID;
    end if;

    -- Restriction Stocks destination
    if    nvl(iListOfStockId, '') <> ''
       or nvl(iListOfStockId, '') is not null then
      vQuery  := vQuery || '    AND STM_STM_STOCK_ID in(' || iListOfStockId || ')';
    end if;

    -- Sélection des propositions
    if iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDA_PROP then
      execute immediate vQuery
      bulk collect into T_FAL_DOC_PROP_ID
                  using iDeleteWithDate, iDeleteWithDate, iDate;
    else
      execute immediate vQuery
      bulk collect into T_FAL_DOC_PROP_ID;
    end if;

    -- Suppression des propositions sélectionnées
    if T_FAL_DOC_PROP_ID.count > 0 then
      for i in T_FAL_DOC_PROP_ID.first .. T_FAL_DOC_PROP_ID.last loop
        DeleteOneDOCProposition(T_FAL_DOC_PROP_ID(i), iDeletePropMode, iDeleteRequestMode, iUpdateRequestValueMode);
      end loop;
    end if;
  end DeleteFAL_DOC_PROP;

  /**
  * procedure DeleteOneDOcProposition
  * Description : Suppression d'une proposition logistique
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPropID : proposition à supprimer
  * @param   aDeleteProp : Suppression ou non de la proposition
  * @param   aDeleteRequest : Suppression ou non de la demande d'approvisionnement
  * @param   aUpdateRequestValue : modification du status de la demande d'approvisionnement
  */
  procedure DeleteOneDOCProposition(aPropID in number, aDeleteProp in integer, aDeleteRequest in integer, aUpdateRequestvalue in integer)
  is
    aSupply    FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    aNeed      FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
    aRequestID number;

    -- Lecture des FAL_NETWORK_SUPPLY associés à la proposition d'appro DOC donnée
    cursor GetSupplyFromDOCPropositionFU(aDocPropositionID in number)
    is
      select     FAL_NETWORK_SUPPLY_ID
            from FAL_NETWORK_SUPPLY
           where FAL_DOC_PROP_ID = aDocPropositionID
      for update;

    -- Lecture des FAL_NETWORK_NEED associés à la proposition d'appro DOC donnée
    cursor GetNeedFromDOCPropositionFU(aDocPropositionID in number)
    is
      select     FAL_NETWORK_NEED_ID
            from FAL_NETWORK_NEED
           where FAL_DOC_PROP_ID = aDocPropositionID
      for update;
  begin
    -- Parcourir les FAL_NETWOK_SUPPLY associés à la proposition courante
    open GetSupplyFromDOCPropositionFU(aPropID);

    loop
      fetch GetSupplyFromDOCPropositionFU
       into aSupply;

      -- S'assurer qu'il y a un record
      exit when GetSupplyFromDOCPropositionFU%notfound;
      -- Suppression Attributions Appro-Stock
      FAL_NETWORK.Attribution_Suppr_ApproStock(aSupply);
      -- Suppression Attributions Appro-Besoin
      FAL_NETWORK.Attribution_Suppr_ApproBesoin(aSupply);

      -- Suppression du FAL_NETWORK_SUPPLY courant
      delete      FAL_NETWORK_SUPPLY
            where current of GetSupplyFromDOCPropositionFU;
    end loop;

    -- Refermer le curseur sur FAL_NETWORK_SUPPLY
    close GetSupplyFromDOCPropositionFU;

    -- Parcourir les FAL_NETWORK_NEED associés à la proposition courante
    open GetNeedFromDOCPropositionFU(aPropID);

    loop
      fetch GetNeedFromDOCPropositionFU
       into aNeed;

      -- S'assurer qu'il y a un record
      exit when GetNeedFromDOCPropositionFU%notfound;
      -- Suppression Attributions Besoin-Stock
      FAL_NETWORK.Attribution_Suppr_BesoinStock(aNeed);
      -- Suppression Attributions Besoin-Appro
      FAL_NETWORK.Attribution_Suppr_BesoinAppro(aNeed);

      -- Suppression du FAL_NETWORK_NEED courant
      delete      FAL_NETWORK_NEED
            where current of GetNeedFromDOCPropositionFU;
    end loop;

    -- Refermer le curseur sur FAL_NETWORK_NEED
    close GetNeedFromDOCPropositionFU;

    -- Si la destruction de la demande éventuellement associée est demandée, récupérer l'ID de la demande associée
    aRequestID  := null;

    if    (aDeleteRequest = FAL_PRC_FAL_PROP_COMMON.DELETE_REQUEST)
       or (nvl(aUpdateRequestvalue, 0) <> FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST) then
      select max(FAL_SUPPLY_REQUEST_ID)
        into aRequestID
        from FAL_DOC_PROP
       where FAL_DOC_PROP_ID = aPropID;
    end if;

    -- Destruction de la proposition de document si souhaité
    if aDeleteProp = FAL_PRC_FAL_PROP_COMMON.DELETE_PROP then
      -- Destruction de tout FAL_DOC_CONSULT ayant pour FAL_DOC_PROP_ID le aPropID
      delete from FAL_DOC_CONSULT
            where FAL_DOC_PROP_ID = aPropID;

      delete from FAL_DOC_PROP
            where FAL_DOC_PROP_ID = aPropID;
    end if;

    -- Si la modif de la demande éventuellement associée est demandée la modifier
    if nvl(aUpdateRequestvalue, 0) <> FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST then
      -- Updater la Request
      update FAL_SUPPLY_REQUEST
         set C_REQUEST_STATUS = aUpdateRequestvalue
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_DOC_PROP_ID = aPropID
          or (FAL_SUPPLY_REQUEST_ID = nvl(aRequestId, 0) );
    end if;

    -- Si la destruction de la demande éventuellement associée est demandée la détruire
    if aDeleteRequest = FAL_PRC_FAL_PROP_COMMON.DELETE_REQUEST then
      -- Détruire la Request
      delete from FAL_SUPPLY_REQUEST
            where FAL_DOC_PROP_ID = aPropID
               or (FAL_SUPPLY_REQUEST_ID = nvl(aRequestId, 0) );
    end if;
  end DeleteOneDOCProposition;

  /**
  * procedure   : PurgeInactiveReservations
  * Description : Gestion du multi user sur les POA, update des POA de session Oracle Invalides
  *
  * @created ECA
  * @lastUpdate
  */
  procedure PurgeInactiveReservations
  is
    cursor crOracleSession
    is
      select distinct FDP_ORACLE_SESSION
                 from FAL_DOC_PROP;
  begin
    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.FDP_ORACLE_SESSION) = 0 then
        update FAL_DOC_PROP
           set FDP_ORACLE_SESSION = null
             , FDP_SELECT = 0
         where FDP_ORACLE_SESSION = tplOracleSession.FDP_ORACLE_SESSION;
      end if;
    end loop;
  end;

  /**
  * procedure : ReleaseLogisticsProcurement
  * Description : Suppression de toutes les réservations faites pour la session en cours
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   aSessionId    Session ORACLE qui a fait la réservation
  */
  procedure ReleaseLogisticsProcurement(aSessionId FAL_DOC_PROP.FDP_ORACLE_SESSION%type default null)
  is
  begin
    update FAL_DOC_PROP
       set FDP_ORACLE_SESSION = null
         , FDP_SELECT = 0
         , FDP_SESSION_VALUE = null
     where FDP_ORACLE_SESSION = nvl(aSessionId, cSessionId);

    PurgeInactiveReservations;
  end;

  /**
  * procedure : SelectProposition
  * Description : Test par une indiv si la proposition doit être sélectionnée.
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   iPropFilterFunction    Nom d'une fonction PL qui test si on garde la proposition ou non dans le filtre.
  *                                 Si elle retourne null ou 0, on ne prend pas la proposition. On la prend dans tous les autres cas.
  * @param   iFalDocPropId          Id de la proposition à tester.
  * @return  True si on prend la proposition dans le filtre, False sinon.
  */
  function SelectProposition(iPropFilterFunction varchar2, iFalDocPropId number)
    return boolean
  is
    lnFilterResult number;
  begin
    if iPropFilterFunction is null then
      return true;
    else
      execute immediate 'select ' || iPropFilterFunction || '(:iFalDocPropId) from dual'
                   into lnFilterResult
                  using iFalDocPropId;

      return nvl(lnFilterResult, 0) > 0;
    end if;
  end;

  /**
  * procedure   : ReserveLogisticsProcurement
  * Description : Réservation des approvisionnements logistiques
  *
  * @created CLG
  * @lastUpdate
  * @param   iSession : Session Oracle
  */
  procedure ReserveLogisticsProcurement(
    iSession               in     FAL_DOC_PROP.FDP_ORACLE_SESSION%type
  , iGcoGoodId             in     number
  , iPartnerId             in     number
  , iStockId               in     number
  , iGoodCategoryIdFrom    in     number
  , iGoodCategoryIdTo      in     number
  , iFinancialCurrencyId   in     number
  , iDocRecordIdFrom       in     number
  , iDocRecordIdFromTo     in     number
  , iFinalDelayMin         in     date
  , iFinalDelayMax         in     date
  , iBasisDelayMin         in     date
  , iBasisDelayMax         in     date
  , iRequirementsConfirmed in     integer
  , iCPrefixProp           in     FAL_DOC_PROP.C_PREFIX_PROP%type
  , iDicProdFreeId         in     FAL_DOC_PROP.DIC_DOC_PROP_FREE_ID%type
  , iDicGoodFamilyIdFrom   in     GCO_GOOD.DIC_GOOD_FAMILY_ID%type
  , iDicGoodFamilyIdTo     in     GCO_GOOD.DIC_GOOD_FAMILY_ID%type
  , iDicAccountGroupIdFrom in     GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type
  , iDicAccountGroupIdTo   in     GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type
  , iDicGoodLineIdFrom     in     GCO_GOOD.DIC_GOOD_LINE_ID%type
  , iDicGoodLineIdTo       in     GCO_GOOD.DIC_GOOD_LINE_ID%type
  , iDicGoodGroupIdFrom    in     GCO_GOOD.DIC_GOOD_GROUP_ID%type
  , iDicGoodGroupIdTo      in     GCO_GOOD.DIC_GOOD_GROUP_ID%type
  , iDicGoodModelIdFrom    in     GCO_GOOD.DIC_GOOD_MODEL_ID%type
  , iDicGoodModelIdTo      in     GCO_GOOD.DIC_GOOD_MODEL_ID%type
  , iManageWithEquivBlock  in     integer
  , iPropFilterFunction    in     varchar2
  , ioPropAlreadySelected  in out integer
  )
  is
    cursor crPropositions(
      aGoodCategoryWordingFrom GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
    , aGoodCategoryWordingTo   GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
    , aRcoTitleFrom            DOC_RECORD.RCO_TITLE%type
    , aRcoTitleTo              DOC_RECORD.RCO_TITLE%type
    )
    is
      select FAL_DOC_PROP_ID
           , FDP_ORACLE_SESSION
        from FAL_DOC_PROP FDP
       where (   nvl(iPartnerId, 0) = 0
              or PAC_SUPPLIER_PARTNER_ID = iPartnerId)
         and (   nvl(iStockId, 0) = 0
              or STM_STM_STOCK_ID = iStockId)
         and (   iCPrefixProp is null
              or PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetUserLangId) = iCPrefixProp)
         and (   iFinalDelayMin is null
              or FDP_FINAL_DELAY >= iFinalDelayMin)
         and (   iFinalDelayMax is null
              or FDP_FINAL_DELAY <= iFinalDelayMax)
         and (   iBasisDelayMin is null
              or FDP_BASIS_DELAY >= iBasisDelayMin)
         and (   iBasisDelayMax is null
              or FDP_BASIS_DELAY <= iBasisDelayMax)
         and (   iDicProdFreeId is null
              or DIC_DOC_PROP_FREE_ID = iDicProdFreeId)
         and (   nvl(iFinancialCurrencyId, 0) = 0
              or ACS_FINANCIAL_CURRENCY_ID = iFinancialCurrencyId)
         and (    (    nvl(iDocRecordIdFrom, 0) = 0
                   and nvl(iDocRecordIdFromTo, 0) = 0)
              or exists(select DOC_RECORD_ID
                          from DOC_RECORD
                         where RCO_TITLE between nvl(aRcoTitleFrom, aRcoTitleTo) and nvl(aRcoTitleTo, aRcoTitleFrom)
                           and DOC_RECORD_ID = FDP.DOC_RECORD_ID)
             )
         and FDP.C_PREFIX_PROP <> 'DRA'
         and not exists(select 1
                          from FAL_DOC_CONSULT FDC
                         where FDC.FAL_DOC_PROP_ID = FDP.FAL_DOC_PROP_ID)
         and (   iRequirementsConfirmed = 0
              or exists(
                   select FNN.FAL_NETWORK_NEED_ID
                     from FAL_NETWORK_SUPPLY FNS
                        , FAL_NETWORK_LINK FNL
                        , FAL_NETWORK_NEED FNN
                    where FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                      and FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                      and FNN.FAL_DOC_PROP_ID is null
                      and FNN.FAL_LOT_MAT_LINK_PROP_ID is null
                      and FNS.FAL_DOC_PROP_ID = FDP.FAL_DOC_PROP_ID)
             )
         and (    (    nvl(iGcoGoodId, 0) = 0
                   and exists(
                         select GOO.GCO_GOOD_ID
                           from GCO_GOOD GOO
                          where GOO.GCO_GOOD_ID = FDP.GCO_GOOD_ID
                            and (   nvl(iGoodCategoryIdFrom, 0) = 0
                                 or (select GCO_GOOD_CATEGORY_WORDING
                                       from GCO_GOOD_CATEGORY
                                      where GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID) >= aGoodCategoryWordingFrom)
                            and (   nvl(iGoodCategoryIdTo, 0) = 0
                                 or (select GCO_GOOD_CATEGORY_WORDING
                                       from GCO_GOOD_CATEGORY
                                      where GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID) <= aGoodCategoryWordingTo)
                            and (   iDicGoodFamilyIdFrom is null
                                 or DIC_GOOD_FAMILY_ID >= iDicGoodFamilyIdFrom)
                            and (   iDicGoodFamilyIdTo is null
                                 or DIC_GOOD_FAMILY_ID <= iDicGoodFamilyIdTo)
                            and (   iDicAccountGroupIdFrom is null
                                 or DIC_ACCOUNTABLE_GROUP_ID >= iDicAccountGroupIdFrom)
                            and (   iDicAccountGroupIdTo is null
                                 or DIC_ACCOUNTABLE_GROUP_ID <= iDicAccountGroupIdTo)
                            and (   iDicGoodLineIdFrom is null
                                 or DIC_GOOD_LINE_ID >= iDicGoodLineIdFrom)
                            and (   iDicGoodLineIdTo is null
                                 or DIC_GOOD_LINE_ID <= iDicGoodLineIdTo)
                            and (   iDicGoodGroupIdFrom is null
                                 or DIC_GOOD_GROUP_ID >= iDicGoodGroupIdFrom)
                            and (   iDicGoodGroupIdTo is null
                                 or DIC_GOOD_GROUP_ID <= iDicGoodGroupIdTo)
                            and (   iDicGoodModelIdFrom is null
                                 or DIC_GOOD_MODEL_ID >= iDicGoodModelIdFrom)
                            and (   iDicGoodModelIdTo is null
                                 or DIC_GOOD_MODEL_ID <= iDicGoodModelIdTo) )
                  )
              or FDP.GCO_GOOD_ID = iGcoGoodId
             )
         and (    (iManageWithEquivBlock = 0)
              or (    iManageWithEquivBlock = 1
                  and (select PDT_BLOCK_EQUI
                         from GCO_PRODUCT
                        where GCO_GOOD_ID = FDP.GCO_GOOD_ID) = 1) );

    lvGoodCategoryWordingFrom GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
    lvGoodCategoryWordingTo   GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
    lvRcoTitleFrom            DOC_RECORD.RCO_TITLE%type;
    lvRcoTitleTo              DOC_RECORD.RCO_TITLE%type;
  begin
    PurgeInactiveReservations;
    ioPropAlreadySelected  := 0;

    if nvl(iDocRecordIdFrom, 0) > 0 then
      select RCO_TITLE
        into lvRcoTitleFrom
        from DOC_RECORD
       where DOC_RECORD_ID = iDocRecordIdFrom;
    end if;

    if nvl(iDocRecordIdFromTo, 0) > 0 then
      select RCO_TITLE
        into lvRcoTitleTo
        from DOC_RECORD
       where DOC_RECORD_ID = iDocRecordIdFromTo;
    end if;

    if nvl(iGoodCategoryIdFrom, 0) > 0 then
      select GCO_GOOD_CATEGORY_WORDING
        into lvGoodCategoryWordingFrom
        from GCO_GOOD_CATEGORY
       where GCO_GOOD_CATEGORY_ID = iGoodCategoryIdFrom;
    end if;

    if nvl(iGoodCategoryIdTo, 0) > 0 then
      select GCO_GOOD_CATEGORY_WORDING
        into lvGoodCategoryWordingTo
        from GCO_GOOD_CATEGORY
       where GCO_GOOD_CATEGORY_ID = iGoodCategoryIdTo;
    end if;

    for tplPropositions in crPropositions(lvGoodCategoryWordingFrom, lvGoodCategoryWordingTo, lvRcoTitleFrom, lvRcoTitleTo) loop
      if SelectProposition(iPropFilterFunction, tplPropositions.FAL_DOC_PROP_ID) then
        if nvl(tplPropositions.FDP_ORACLE_SESSION, iSession) = iSession then
          update FAL_DOC_PROP FDP
             set FDP_ORACLE_SESSION = iSession
               , FDP_SELECT = 0
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_DOC_PROP_ID = tplPropositions.FAL_DOC_PROP_ID;
        else
          ioPropAlreadySelected  := ioPropAlreadySelected + 1;
        end if;
      end if;
    end loop;
  end ReserveLogisticsProcurement;
end FAL_PRC_FAL_DOC_PROP;
