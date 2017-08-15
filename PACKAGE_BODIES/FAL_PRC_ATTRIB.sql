--------------------------------------------------------
--  DDL for Package Body FAL_PRC_ATTRIB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_ATTRIB" 
is
  procedure ProcessusMajReseauBesoinY0(iNetworkNeedID in FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type, iQty in FAL_NETWORK_LINK.FLN_QTY%type)
  is
  begin
    update FAL_NETWORK_NEED
       set FAN_FREE_QTY = FAN_FREE_QTY + iQty
         , FAN_NETW_QTY = FAN_NETW_QTY - iQty
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_NETWORK_NEED_ID = iNetworkNeedID;
  end ProcessusMajReseauBesoinY0;

  procedure ProcessusMajReseauApproY0(iNetworkSupplyID in FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type, iQty in FAL_NETWORK_LINK.FLN_QTY%type)
  is
  begin
    update FAL_NETWORK_SUPPLY
       set FAN_FREE_QTY = FAN_FREE_QTY + iQty
         , FAN_NETW_QTY = FAN_NETW_QTY - iQty
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_NETWORK_SUPPLY_ID = iNetworkSupplyID;
  end ProcessusMajReseauApproY0;

  procedure ProcessusMajReseauBesoin2Y0(iNetworkNeedID in FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type, iQty in FAL_NETWORK_LINK.FLN_QTY%type)
  is
  begin
    update FAL_NETWORK_NEED
       set FAN_FREE_QTY = FAN_FREE_QTY + iQty
         , FAN_STK_QTY = FAN_STK_QTY - iQty
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_NETWORK_NEED_ID = iNetworkNeedID;
  end ProcessusMajReseauBesoin2Y0;

  procedure ProcessusMajReseauAppro2Y0(iNetworkSupplyID in FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type, iQty in FAL_NETWORK_LINK.FLN_QTY%type)
  is
  begin
    update FAL_NETWORK_SUPPLY
       set
           -- Ajout de NVL (Modif mineure)
           FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(iQty, 0)
         , FAN_STK_QTY = nvl(FAN_STK_QTY, 0) - nvl(iQty, 0)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_NETWORK_SUPPLY_ID = iNetworkSupplyID;
  end ProcessusMajReseauAppro2Y0;

  procedure ProcessusMaj1PositionDeStockY0(iStockPositionID in FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type, iQty in FAL_NETWORK_LINK.FLN_QTY%type)
  is
    -- DJ20000516-0001
    ValSPO_AVAILABLE_QUANTITY STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    ValSPO_ASSIGN_QUANTITY    STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY%type;
  -- DJ20000516-0001
  begin
    -- DJ20000516-0001
    select SPO_AVAILABLE_QUANTITY
         , SPO_ASSIGN_QUANTITY
      into ValSPO_AVAILABLE_QUANTITY
         , ValSPO_ASSIGN_QUANTITY
      from STM_STOCK_POSITION
     where STM_STOCK_POSITION_ID = iStockPositionID;

    if nvl(ValSPO_ASSIGN_QUANTITY, 0) - iQty < 0 then
      raise_application_error(-20102, 'PCS - SPO_ASSIGN_QUANTITY Must be Equal or Greater than Zero!');
    end if;

    -- DJ20000516-0001
    update STM_STOCK_POSITION
       set SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) + nvl(iQty, 0)
         , SPO_ASSIGN_QUANTITY = nvl(SPO_ASSIGN_QUANTITY, 0) - nvl(iQty, 0)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where STM_STOCK_POSITION_ID = iStockPositionID;
  end ProcessusMaj1PositionDeStockY0;

  /**
  * procedure deleteAttrib
  * Description
  *    Cette fonction permet de supprimer des attributions entre les
  *    différents élément en paramètres
  */
  procedure deleteAttrib(
    iNetworkLinkID   in FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
  , iNetworkNeedID   in FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
  , iNetworkSupplyID in FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type
  , iStockPositionID in FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type
  , iLocationID      in FAL_NETWORK_LINK.STM_LOCATION_ID%type
  , iQty             in FAL_NETWORK_LINK.FLN_QTY%type
  , iDoDeleteNullQty in boolean default true
  )
  as
  begin
    -- Suppression attribution besoin - stock
    if     iNetworkNeedID is not null
       and iStockPositionID is not null then
      ProcessusMajReseauBesoin2Y0(iNetworkNeedID, iQty);
      ProcessusMaj1PositionDeStockY0(iStockPositionID, iQty);
    -- Suppression Attribution Approvisionnement - Stock
    elsif     iNetworkSupplyID is not null
          and iLocationID is not null then
      ProcessusMajreseauAppro2Y0(iNetworkSupplyID, iQty);
    -- Suppression attribution besoin - Appro
    elsif     iNetworkNeedID is not null
          and iNetworkSupplyID is not null then
      ProcessusMajReseauBesoinY0(iNetworkNeedID, iQty);
      ProcessusMajreseauApproY0(iNetworkSupplyID, iQty);
    -- Suppression attribution besoin - ?
    elsif     iNetworkNeedID is not null
          and iStockPositionID is null
          and iNetworkSupplyID is null
          and iLocationID is null then
      -- Suppression de l'attribution
      delete      FAL_NETWORK_LINK
            where FAL_NETWORK_LINK_ID = iNetworkLinkID;

      update FAL_NETWORK_NEED
         set FAN_FREE_QTY = FAN_BALANCE_QTY - (select sum(FLN_QTY)
                                                 from FAL_NETWORK_LINK
                                                where FAL_NETWORK_NEED_ID = iNetworkNeedID)
           , FAN_NETW_QTY = (select sum(FLN_QTY)
                               from FAL_NETWORK_LINK
                              where FAL_NETWORK_NEED_ID = iNetworkNeedID
                                and STM_STOCK_POSITION_ID is null
                                and STM_LOCATION_ID is null)
           , FAN_STK_QTY = (select sum(FLN_QTY)
                              from FAL_NETWORK_LINK
                             where FAL_NETWORK_NEED_ID = iNetworkNeedID
                               and (   STM_STOCK_POSITION_ID is not null
                                    or STM_LOCATION_ID is not null) )
       where FAL_NETWORK_NEED_ID = iNetworkNeedID;
    -- Suppression attribution Appro - ?
    elsif     iNetworkSupplyID is not null
          and iStockPositionID is null
          and iNetworkNeedID is null
          and iLocationID is null then
      -- Suppression de l'attribution
      delete      FAL_NETWORK_LINK
            where FAL_NETWORK_LINK_ID = iNetworkLinkID;

      update FAL_NETWORK_SUPPLY
         set FAN_FREE_QTY = FAN_BALANCE_QTY - (select sum(FLN_QTY)
                                                 from FAL_NETWORK_LINK
                                                where FAL_NETWORK_SUPPLY_ID = iNetworkSupplyID)
           , FAN_NETW_QTY = (select sum(FLN_QTY)
                               from FAL_NETWORK_LINK
                              where FAL_NETWORK_SUPPLY_ID = iNetworkSupplyID
                                and STM_STOCK_POSITION_ID is null
                                and STM_LOCATION_ID is null)
           , FAN_STK_QTY = (select sum(FLN_QTY)
                              from FAL_NETWORK_LINK
                             where FAL_NETWORK_SUPPLY_ID = iNetworkSupplyID
                               and (   STM_STOCK_POSITION_ID is not null
                                    or STM_LOCATION_ID is not null) )
       where FAL_NETWORK_SUPPLY_ID = iNetworkSupplyID;
    end if;

    -- Suppression de l'attribution
    delete      FAL_NETWORK_LINK
          where FAL_NETWORK_LINK_ID = iNetworkLinkID;

    -- Suppression de la position si tous ces compteurs sont à 0
    if     iStockPositionID is not null
       and iDoDeleteNullQty then
      STM_I_PRC_STOCK_POSITION.DeleteNullPosition(iStockPositionID);
    end if;
  end deleteAttrib;

  /**
  * procedure RefreshStockNetworkLink
  * Description
  *    Rafraichit les attributions liées aux besoins associés au détail de caractérisation courant
  */
  procedure RefreshStockNetworkLink(
    iElementNumberId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iDeleteLink      in number default 0
  , iRefreshLink     in number default 0
  )
  is
    cursor crNetworkLinks
    is
      select   FNL.FAL_NETWORK_LINK_ID
             , FNL.FAL_NETWORK_NEED_ID
             , FNN.DOC_POSITION_DETAIL_ID
             , FNN.GCO_GOOD_ID
          from FAL_NETWORK_LINK FNL
             , STM_STOCK_POSITION SPO
             , FAL_NETWORK_NEED FNN
         where FNL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID
           and FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
           and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = iElementNumberId
      order by FNN.FAN_BEG_PLAN asc;

    type TNetworkLinks is table of crNetworkLinks%rowtype;

    tblNetworkLinks TNetworkLinks;
    vErrorCode      varchar2(4000);
  begin
    -- Si pas de suppression ou réactualisation, sortie
    if     iDeleteLink = 0
       and iRefreshLink = 0 then
      return;
    end if;

    -- Stockage du résultat
    open crNetworkLinks;

    fetch crNetworkLinks
    bulk collect into tblNetworkLinks;

    begin
      -- Pour chaque Attribution besoin -> stock concerné
      if tblNetworkLinks.count > 0 then
        -- Suppression des attributions si demandé
        if iDeleteLink = 1 then
          for i in tblNetworkLinks.first .. tblNetworkLinks.last loop
            -- Suppression
            FAL_NETWORK.LockAndDeleteLink(tblNetworkLinks(i).FAL_NETWORK_LINK_ID, vErrorCode);
          end loop;
        end if;

        -- Réactualisation besoins par besoins, si demandé
        if iRefreshLink = 1 then
          for i in tblNetworkLinks.first .. tblNetworkLinks.last loop
            if tblNetworkLinks(i).DOC_POSITION_DETAIL_ID is not null then
              -- Si besoin logistique : Réactualisation besoin logistique pour le besoin sélectionné
              FAL_REDO_ATTRIBS.ReactAttribsByDocOrPos(null, null, tblNetworkLinks(i).DOC_POSITION_DETAIL_ID);
            else
              -- Si besoin fabrication : Réactualisation besoin Fabrication pour le besoin sélectionné
              FAL_REDO_ATTRIBS.GenereAttribBesoinFabSurStock(PrmGCO_GOOD_ID               => tblNetworkLinks(i).GCO_GOOD_ID
                                                           , PrmLstStock                  => null
                                                           , iUseMasterPlanRequirements   => 1
                                                           , iFalLotId                    => null
                                                           , iSubContractPNeed            => 0
                                                           , iNetworkNeedId               => tblNetworkLinks(i).FAL_NETWORK_NEED_ID
                                                            );
            end if;
          end loop;
        end if;
      end if;

      close crNetworkLinks;
    exception
      when others then
        close crNetworkLinks;

        raise;
    end;
  end RefreshStockNetworkLink;
end FAL_PRC_ATTRIB;
