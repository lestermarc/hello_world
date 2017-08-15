--------------------------------------------------------
--  DDL for Package Body FAL_SUPPLY_REQUEST_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_SUPPLY_REQUEST_FUNCTIONS" 
is
  /**
  * procedure DeletePropForOneSupplyRequest
  * Description : Suppression des propositions d'une demande d'appro.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSupplyRequestID : demande d'appro à supprimer
  */
  procedure DeletePropForOneSupplyRequest(aSupplyRequestID in number)
  is
    aPropID number;

    -- Lecture de toutes les propositions d'approvisionnements FAB associée à la demande d'appro donnée
    cursor GetFABPropFromSupplyRequest(aSupplyrequestID in number)
    is
      select FAL_LOT_PROP_ID
        from FAL_LOT_PROP
       where FAL_SUPPLY_REQUEST_ID = aSupplyrequestID;

    -- Lecture de toutes les propositions d'approvisionnements FAB associée à la demande d'appro donnée
    cursor GetDOCPropFromSupplyRequest(aSupplyrequestID in number)
    is
      select *
        from FAL_DOC_PROP
       where FAL_SUPPLY_REQUEST_ID = aSupplyrequestID;
  begin
    -- Récupérer l'ID de la proposition de Lot associée
    aPropID  := null;

    for aRecord in GetFABPropFromSupplyRequest(aSupplyrequestID) loop
      aPropID  := aRecord.FAL_LOT_PROP_ID;
    end loop;

    if aPropID is not null then
      FAL_PRC_FAL_LOT_PROP.DeleteOneFABProposition(aPropID
                                                 , FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST
                                                  );
    end if;

    -- Récupérer l'ID de la proposition du doc associée
    aPropID  := null;

    for aRecord in GetDOCPropFromSupplyRequest(aSupplyrequestID) loop
      aPropID  := aRecord.FAL_DOC_PROP_ID;
      exit;
    end loop;

    if aPropID is not null then
      FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(aPropID
                                                 , FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST
                                                  );
    end if;
  end DeletePropForOneSupplyRequest;

  /**
  * procedure DeleteOneSupplyRequest
  * Description : Suppression d'une demande d'appro, et proposition associée.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSupplyRequestID : demande d'appro à supprimer
  */
  procedure DeleteOneSupplyRequest(aSupplyRequestID in number)
  is
    aPropID number;

    -- Lecture de toutes les propositions d'approvisionnements FAB associée à la demande d'appro donnée
    cursor GetFABPropFromSupplyRequest(aSupplyrequestID in number)
    is
      select FAL_LOT_PROP_ID
        from FAL_LOT_PROP
       where FAL_SUPPLY_REQUEST_ID = aSupplyrequestID;

    -- Lecture de toutes les propositions d'approvisionnements DOC associée à la demande d'appro donnée
    cursor GetDOCPropFromSupplyRequest(aSupplyrequestID in number)
    is
      select *
        from FAL_DOC_PROP
       where FAL_SUPPLY_REQUEST_ID = aSupplyrequestID;
  begin
    -- Récupérer l'ID de la proposition de Lot associée
    aPropID  := null;

    for aRecord in GetFABPropFromSupplyRequest(aSupplyrequestID) loop
      aPropID  := aRecord.FAL_LOT_PROP_ID;
    end loop;

    -- Suppression de la proposition de fabrication associée
    if aPropID is not null then
      FAL_PRC_FAL_LOT_PROP.DeleteOneFABProposition(aPropID
                                                 , FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST
                                                  );
    end if;

    -- Récupérer l'ID de la proposition du doc associée
    aPropID  := null;

    for aRecord in GetDOCPropFromSupplyRequest(aSupplyrequestID) loop
      aPropID  := aRecord.FAL_DOC_PROP_ID;
      exit;
    end loop;

    -- Suppression de la proposition d'achat.
    if aPropID is not null then
      FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(aPropID
                                                 , FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                                 , FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST
                                                  );
    end if;

    -- Suppression de la demande d'approvisionnement
    delete from FAL_SUPPLY_REQUEST
          where FAL_SUPPLY_REQUEST_ID = aSupplyRequestID;
  end DeleteOneSupplyRequest;

  /**
  * procedure UpdateSupplyRequestProject
  * Description
  *   Création ou mise à jour d'un dossier à partir du module Affaire
  * @created VJ 14.01.2005
  */
  procedure UpdateSupplyRequestProject(
    aGoodID      in     GCO_GOOD.GCO_GOOD_ID%type
  , aRecordID    in     DOC_RECORD.DOC_RECORD_ID%type
  , aNumber      in     FAL_SUPPLY_REQUEST.FSR_NUMBER%type
  , aTexte       in     FAL_SUPPLY_REQUEST.FSR_TEXTE%type
  , aAskedQty    in     FAL_SUPPLY_REQUEST.FSR_ASKED_QTY%type
  , aDelay       in     FAL_SUPPLY_REQUEST.FSR_DELAY%type
  , aLongDescr   in     FAL_SUPPLY_REQUEST.FSR_LONG_DESCR%type
  , aFreeDescr   in     FAL_SUPPLY_REQUEST.FSR_FREE_DESCR%type
  , outRequestId out    FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type
  )
  is
    cursor crStockAndLocation
    is
      select   STO.STM_STOCK_ID
             , nvl( (select LOC_CONFIG.STM_LOCATION_ID
                       from STM_LOCATION LOC_CONFIG
                      where LOC_CONFIG.LOC_DESCRIPTION = PCS.PC_CONFIG.GetConfig('GCO_DefltLOCATION_PROJECT')
                        and LOC_CONFIG.STM_STOCK_ID = STO.STM_STOCK_ID)
                 , LOC.STM_LOCATION_ID
                  ) STM_LOCATION_ID
          from STM_STOCK STO
             , STM_LOCATION LOC
         where STO.STO_DESCRIPTION = PCS.PC_CONFIG.GetConfig('GCO_DefltSTOCK_PROJECT')
           and LOC.STM_STOCK_ID = STO.STM_STOCK_ID
      order by LOC.LOC_CLASSIFICATION asc;

    tplStockAndLocation    crStockAndLocation%rowtype;
    falSupplyRequestID     FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type;
    cRequestStatus         FAL_SUPPLY_REQUEST.C_REQUEST_STATUS%type;
    fsrBasisDelay          FAL_SUPPLY_REQUEST.FSR_BASIS_DELAY%type;
    fsrIntermediateDelay   FAL_SUPPLY_REQUEST.FSR_INTERMEDIATE_DELAY%type;
    fsrFinalDelay          FAL_SUPPLY_REQUEST.FSR_DELAY%type;
    strBasisDelayMW        varchar2(10);
    strIntermediateDelayMW varchar2(10);
    strFinalDelayMW        varchar2(10);
    cdaStockID             STM_STOCK.STM_STOCK_ID%type;
    cdaLocationID          STM_LOCATION.STM_LOCATION_ID%type;
    gooStockID             STM_STOCK.STM_STOCK_ID%type;
    gooLocationID          STM_LOCATION.STM_LOCATION_ID%type;
    cfgStockID             STM_STOCK.STM_STOCK_ID%type;
    cfgLocationID          STM_LOCATION.STM_LOCATION_ID%type;
    pacSupplierPartnerID   PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    v_pacSupplierPartnerID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    dicFabConditionID      GCO_COMPL_DATA_MANUFACTURE.DIC_FAB_CONDITION_ID%type;
    cSupplyMode            GCO_PRODUCT.C_SUPPLY_MODE%type;
  begin
    outRequestId  := null;

    if PCS.PC_I_LIB_SESSION.GetUserId is not null then
      begin
        select FAL_SUPPLY_REQUEST_ID
          into falSupplyRequestID
          from FAL_SUPPLY_REQUEST
         where DOC_RECORD_ID = aRecordID
           and GCO_GOOD_ID = aGoodID
           and FSR_DELAY = aDelay
           and C_REQUEST_STATUS = '1';
      exception
        when no_data_found then
          falSupplyRequestID  := null;
      end;

      fsrBasisDelay         := trunc(aDelay);
      fsrIntermediateDelay  := fsrBasisDelay;
      fsrFinalDelay         := fsrBasisDelay;

      if falSupplyRequestID is null then
        select PDT.C_SUPPLY_MODE
          into cSupplyMode
          from GCO_PRODUCT PDT
         where PDT.GCO_GOOD_ID = aGoodID;

        if cSupplyMode = '1' then   -- Produit acheté
          begin
            select CPU.PAC_SUPPLIER_PARTNER_ID
              into v_pacSupplierPartnerID
              from GCO_COMPL_DATA_PURCHASE CPU
             where CPU.GCO_GOOD_ID = aGoodID
               and CPU.CPU_DEFAULT_SUPPLIER = 1;
          exception
            when no_data_found then
              v_pacSupplierPartnerID  := null;
          end;
        else
          v_pacSupplierPartnerID  := null;
        end if;
      end if;

      if PCS.PC_CONFIG.GetConfig('DOC_THREE_DELAY') = '1' then
        -- Calcul le délai de réception et le délai de commande avec le délai de disponibilité
        DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(1   -- 1 = Jour , 2 = Semaines , 3 = Mois
                                                , 0   -- Positionnement des délais pour showdelay 2 et 3
                                                , 'FINAL'   -- Quel a été le délai référence/modifié = "BASIS" , "INTER" ou "FINAL"
                                                , 0   -- Sens de calcul des autres délais (1=en avant 0=en arrière)
                                                , v_pacSupplierPartnerID   -- ID du tiers pour la recherche dans les données compl.
                                                , aGoodID   -- ID du bien pour la recherche dans les données compl.
                                                , null   -- ID Stock (position)
                                                , null   -- ID du stock de transfert (position)
                                                , 1   -- Domaine du document
                                                , 2   -- Type de gabarit
                                                , 0   -- Gabarit position -> Transfert stock propriétaire
                                                , strBasisDelayMW
                                                , strIntermediateDelayMW
                                                , strFinalDelayMW
                                                , fsrBasisDelay
                                                , fsrIntermediateDelay
                                                , fsrFinalDelay
                                                 );
      end if;

      if falSupplyRequestID is null then
        --
        -- Configuration FAL_REQUEST_MODE    Mode de Gestion des Demandes d'approvisionnement
        --
        -- 1 = Sans Validation
        -- Les demandes d'approvisionnements sont créées en statut 2 " Validé "
        --
        -- 2 = Avec Validation
        -- Les demandes d'approvisionnement sont créées en statut 1 " A valider "
        --
        -- Attention : étant donné l'impossibilité de déclencher le traitement de validation de la demande
        -- d'approvisionnement (les méthodes de validation sont en Delphi), la configuration ne sera pas prise en compte
        -- lors de la création de la DA. En effet, toutes les DA en provenance de GALEi devront être validée par
        -- un utilisateur.
        --
        -- if PCS.PC_CONFIG.GetConfig('FAL_REQUEST_MODE') = '2' then
        --   cRequestStatus  := '1';
        -- else
        --   cRequestStatus  := '2';
        -- end if;
        --
        --  (select lpad(nvl(max(to_number(FSR.FSR_NUMBER) ), 0) + 1, 6, '0')
        --     from FAL_SUPPLY_REQUEST FSR)   -- FSR_NUMBER
        --
        cRequestStatus  := '1';   -- A valider

        -- Recherche le stock et l'emplacement pour affaire dans les configurations.
        --   Si la configuration du stock ne retourne pas de stock valide, la configuration n'a pas d'influence sur la
        --   cascade de recherche. Si la configuration de l'emplacement ne retourne pas d'emplacement valide, c'est le
        --   premier emplacement dans l'ordre de classement de stock de la configuration GCO_DefltSTOCK_PROJECT.
        open crStockAndLocation;

        fetch crStockAndLocation
         into tplStockAndLocation;

        if crStockAndLocation%found then
          cfgStockID     := tplStockAndLocation.STM_STOCK_ID;
          cfgLocationID  := tplStockAndLocation.STM_LOCATION_ID;
        else
          cfgStockID     := null;
          cfgLocationID  := null;
        end if;

        -- Recherche les diverses informations inscritent dans les données complémentaires en fonction du mode
        -- d'approvisionnement. Notamment le fournisseur par défaut et la condition de fabrication par défaut du bien.
        --

        --select PDT.C_SUPPLY_MODE
            --  into cSupplyMode
            --  from GCO_PRODUCT PDT
            -- where PDT.GCO_GOOD_ID = aGoodID;
        if cSupplyMode = '1' then   -- Produit acheté
          dicFabConditionID  := null;

          begin
            select CPU.PAC_SUPPLIER_PARTNER_ID
                 , CPU.STM_STOCK_ID
                 , CPU.STM_LOCATION_ID
              into pacSupplierPartnerID
                 , cdaStockID
                 , cdaLocationID
              from GCO_COMPL_DATA_PURCHASE CPU
             where CPU.GCO_GOOD_ID = aGoodID
               and CPU.CPU_DEFAULT_SUPPLIER = 1;
          exception
            when no_data_found then
              pacSupplierPartnerID  := null;
              cdaStockID            := null;
              cdaLocationID         := null;
          end;
        elsif cSupplyMode = '2' then   -- Produit fabriqué
          pacSupplierPartnerID  := null;

          begin
            select CMA.DIC_FAB_CONDITION_ID
                 , CMA.STM_STOCK_ID
                 , CMA.STM_LOCATION_ID
              into dicFabConditionID
                 , cdaStockID
                 , cdaLocationID
              from GCO_COMPL_DATA_MANUFACTURE CMA
             where CMA.GCO_GOOD_ID = aGoodID
               and CMA.CMA_DEFAULT = 1;
          exception
            when no_data_found then
              dicFabConditionID  := null;
              cdaStockID         := null;
              cdaLocationID      := null;
          end;
        end if;

        if     cfgStockID is null
           and cdaStockID is null then
          GCO_FUNCTIONS.GetGoodStockLocation(aGoodID, gooStockID, gooLocationID);
        end if;

        insert into FAL_SUPPLY_REQUEST
                    (FAL_SUPPLY_REQUEST_ID
                   , GCO_GOOD_ID
                   , DOC_RECORD_ID
                   , PAC_SUPPLIER_PARTNER_ID
                   , DIC_FAB_CONDITION_ID
                   , STM_STOCK_ID
                   , STM_LOCATION_ID
                   , PC_USER1_ID
                   , PC_USER2_ID
                   , PC_USER3_ID
                   , C_REQUEST_STATUS
                   , FSR_NUMBER
                   , FSR_TEXTE
                   , FSR_ASKED_QTY
                   , FSR_REJECT_PLAN_QTY
                   , FSR_TOTAL_QTY
                   , FSR_BASIS_DELAY
                   , FSR_INTERMEDIATE_DELAY
                   , FSR_DELAY
                   , FSR_DATE
                   , FSR_LONG_DESCR
                   , FSR_FREE_DESCR
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId   -- DOC_RECORD_ID
                   , aGoodID   -- GCO_GOOD_ID
                   , aRecordID   -- DOC_RECORD_ID
                   , pacSupplierPartnerID   -- PAC_SUPPLIER_PARTNER_ID
                   , dicFabConditionID   -- DIC_FAB_CONDITION_ID
                   , nvl(nvl(cfgStockID, cdaStockID), gooStockID)   -- STM_STOCK_ID
                   , nvl(nvl(cfgLocationID, cdaLocationID), gooLocationID)   -- STM_LOCATION_ID
                   , PCS.PC_I_LIB_SESSION.GetUserId   -- PC_USER1_ID
                   , null   -- PC_USER2_ID
                   , decode(cRequestStatus, '2', PCS.PC_I_LIB_SESSION.GetUserId, null)   -- PC_USER3_ID
                   , cRequestStatus   -- C_REQUEST_STATUS
                   , aNumber   -- FSR_NUMBER
                   , aTexte   -- FSR_TEXTE
                   , aAskedQty   -- FSR_ASKED_QTY
                   , 0   -- FSR_REJECT_PLAN_QTY
                   , aAskedQty   -- FSR_TOTAL_QTY
                   , fsrBasisDelay   -- FSR_BASIS_DELAY
                   , fsrIntermediateDelay   -- FSR_INTERMEDIATE_DELAY
                   , fsrFinalDelay   -- FSR_DELAY
                   , sysdate   -- FSR_DATE
                   , aLongDescr   -- FSR_LONG_DESCR
                   , aFreeDescr   -- FSR_FREE_DESCR
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    )
          returning FAL_SUPPLY_REQUEST_ID
               into outRequestId;
      --select INIT_ID_SEQ.currval into outRequestId from dual;
      else
        update FAL_SUPPLY_REQUEST
           set FSR_ASKED_QTY = FSR_ASKED_QTY + aAskedQty
             , FSR_TOTAL_QTY = FSR_TOTAL_QTY + aAskedQty
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_SUPPLY_REQUEST_ID = falSupplyRequestID;

        outRequestId  := falSupplyRequestID;
      end if;
    end if;
  end UpdateSupplyRequestProject;

  /**
  * fonction GetSupplyRequestStatus
  * Description
  *   Recherche du statut de la demande d'approvisionnement lié à une tâche d'approvisionnement GALEi
  * @created VJ 25.01.2005
  * @lastUpdate
  * @public
  */
  function GetSupplyRequestStatus(aGalSupplyRequestID in FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type)
    return FAL_SUPPLY_REQUEST.C_REQUEST_STATUS%type
  is
    cRequestStatus FAL_SUPPLY_REQUEST.C_REQUEST_STATUS%type;
  begin
    begin
      select C_REQUEST_STATUS
        into cRequestStatus
        from FAL_SUPPLY_REQUEST
       where GAL_SUPPLY_REQUEST_ID = aGalSupplyRequestID;
    exception
      when no_data_found then
        cRequestStatus  := null;
    end;

    return cRequestStatus;
  end GetSupplyRequestStatus;

  /**
  * Procedure DeleteSupplyRequest
  * Description : Suppression d'une demande d'approvisionnement, avec contrôles métier préalables.
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iFAL_SUPPLY_REQUEST_ID : Demande d'approvisionnement
  * @param   ioDeleted : Effacée avec succès.
  * @param   ioTryToCancel : Essai d'annulation possible.
  * @param   ioIsGalSupplyRequest : Indique s'il s'agit d'une DA liées à une tâche d'appro d'affaire
  */
  procedure DeleteSupplyRequest(iFAL_SUPPLY_REQUEST_ID in number, ioDeleted in out integer, ioTryToCancel in out integer, ioIsGalSupplyRequest in out integer)
  is
    lvC_REQUEST_STATUS varchar2(10);
    lnDOC_RECORD_ID    number;
    lvC_RCO_TYPE       varchar2(10);
  begin
    ioDeleted             := 0;
    ioTryToCancel         := 0;
    ioIsGalSupplyRequest  := 0;
    lvC_REQUEST_STATUS    := null;
    lnDOC_RECORD_ID       := null;
    lvC_RCO_TYPE          := null;

    -- Informations annexes à la demande
    select FSR.C_REQUEST_STATUS
         , FSR.DOC_RECORD_ID
         , RCO.C_RCO_TYPE
      into lvC_REQUEST_STATUS
         , lnDOC_RECORD_ID
         , lvC_RCO_TYPE
      from FAL_SUPPLY_REQUEST FSR
         , DOC_RECORD RCO
     where FSR.FAL_SUPPLY_REQUEST_ID = iFAL_SUPPLY_REQUEST_ID
       and FSR.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+);

    -- La suppression d'une DA n'est possible que si elle est en statut "A valider"
    -- Contexte DA Avec Validation à effectuer
    if PCS.PC_CONFIG.GetConfig('FAL_REQUEST_MODE') = '2' then
      -- Demande à valider
      if lvC_REQUEST_STATUS = '1' then
        ioDeleted  := 1;
      -- Demande validée
      elsif lvC_REQUEST_STATUS = '2' then
        ioTryToCancel  := 1;
      -- Autres cas
      end if;
    else
      ioDeleted  := 1;
    end if;

    -- Une DA ne peut pas être supprimée si le dossier lié est de type "Tâche d'approvisionnement"
    if     lnDOC_RECORD_ID is not null
       and lvC_RCO_TYPE = '02' then
      ioDeleted             := 0;
      ioTryToCancel         := 0;
      ioIsGalSupplyRequest  := 1;
    end if;

    -- Suppression de la DA
    if ioDeleted = 1 then
      DeleteOneSupplyRequest(iFAL_SUPPLY_REQUEST_ID);
    end if;
  exception
    when others then
      raise;
  end DeleteSupplyRequest;

  /**
  * Procedure CancelSupplyRequest
  * Description : Annulation d'une demande d'approvisionnement
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iFAL_SUPPLY_REQUEST_ID : Demande d'approvisionnement
  */
  procedure CancelSupplyRequest(iFAL_SUPPLY_REQUEST_ID in number)
  is
  begin
    -- Suppression de la proposition associée
    DeletePropForOneSupplyRequest(iFAL_SUPPLY_REQUEST_ID);

    -- Mise à jour du statut
    update FAL_SUPPLY_REQUEST
       set C_REQUEST_STATUS = '4'
     where FAL_SUPPLY_REQUEST_ID = iFAL_SUPPLY_REQUEST_ID;
  end CancelSupplyRequest;

  /**
  * procedure MajApproOfOneProp
  * Description : Mise à jour demande d'appro d'une proposition.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPropID : Proposition
  * @param   aUpdateRequestValue : Status demande d'appro
  * @param   aFSR_DOC_ORDER
  */
  procedure MajApproOfOneProp(aPropID in number, aUpdateRequestValue in integer, aFSR_DOC_ORDER FAL_SUPPLY_REQUEST.FSR_DOC_ORDER%type)
  is
  begin
    update FAL_SUPPLY_REQUEST
       set C_REQUEST_STATUS = aUpdateRequestvalue
         , FSR_DOC_ORDER = aFSR_DOC_ORDER
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_SUPPLY_REQUEST_ID = (select FAL_SUPPLY_REQUEST_ID
                                      from FAL_DOC_PROP
                                     where FAL_DOC_PROP_ID = aPropID);
  end MajApproOfOneProp;

  /**
  * Procedure GetSupplyRequestDescr
  * Description : Recherche des descriptions de la demande d'approvisionnement
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iGoodId : Bien
  * @param   icSupplyMode : Mode d'approvisionnement
  * @param   iSupplierid : Fournisseur
  * @param   ioMajorReference : référence principale
  * @param   ioSecondaryReference : référence secondaire
  * @param   ioShortDescr : Description courte
  * @param   ioLongDescr : Description longue
  * @param   ioFreeDescr : Description libre
  */
  procedure GetSupplyRequestDescr(
    iGoodId              in     number
  , icSupplyMode         in     varchar2
  , iSupplierid          in     number
  , ioMajorReference     in out varchar2
  , ioSecondaryReference in out varchar2
  , ioShortDescr         in out varchar2
  , ioLongDescr          in out varchar2
  , ioFreeDescr          in out varchar2
  )
  is
  begin
    -- Si produit acheté, descriptions en provenance de la donnée complémentaire d'achat
    if icSupplyMode = '1' then
      for tplComplDataPurchase in (select   CDA_COMPLEMENTARY_REFERENCE
                                          , CDA_SECONDARY_REFERENCE
                                          , CDA_SHORT_DESCRIPTION
                                          , CDA_LONG_DESCRIPTION
                                          , CDA_FREE_DESCRIPTION
                                          , (case
                                               when CPU_DEFAULT_SUPPLIER = 1 then 0
                                               else 1
                                             end) orderField
                                       from GCO_COMPL_DATA_PURCHASE CDP
                                      where GCO_GOOD_ID = iGoodId
                                        and PAC_SUPPLIER_PARTNER_ID = iSupplierID
                                   order by orderField) loop
        ioMajorReference      := tplComplDataPurchase.CDA_COMPLEMENTARY_REFERENCE;
        ioSecondaryReference  := tplComplDataPurchase.CDA_SECONDARY_REFERENCE;
        ioShortDescr          := tplComplDataPurchase.CDA_SHORT_DESCRIPTION;
        ioLongDescr           := tplComplDataPurchase.CDA_LONG_DESCRIPTION;
        ioFreeDescr           := tplComplDataPurchase.CDA_FREE_DESCRIPTION;
        exit;
      end loop;
    -- Sinon descriptions produit
    else
      FAL_TOOLS.GetMajorSecShortFreeLong(iGoodId, ioMajorReference, ioSecondaryReference, ioShortDescr, ioFreeDescr, ioLongDescr);
    end if;
  end GetSupplyRequestDescr;

  /**
  * procedure GetSubcontractPFabConditionId
  * Description : Recherche de la liste des conditions de fabrication / Sous-traitance
  *               valides en fonction du mode d'approvisionement du produit
  *
  * @created eca 15.04.2011
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iCSupplyMode : Mode d'approvisionnement
  * @param   iDateRef : Date référence
  */
  function GetSubcontractPFabConditionId(iGcoGoodId in number, iCSupplyMode in varchar2, iDateRef in date default sysdate)
    return CHAR_TABLE_TYPE pipelined
  is
  begin
    -- produit sous-traité
    if iCSupplyMode = '4' then
      for tplDicFabConditionId in (select DFC.*
                                     from DIC_FAB_CONDITION DFC
                                        , GCO_COMPL_DATA_SUBCONTRACT CSU
                                    where DFC.DIC_FAB_CONDITION_ID = CSU.DIC_FAB_CONDITION_ID
                                      and CSU.GCO_GOOD_ID = iGcoGoodId
                                      and nvl(CSU.CSU_VALIDITY_DATE, trunc(iDateRef) ) <= trunc(iDateRef) ) loop
        pipe row(tplDicFabConditionId.DIC_FAB_CONDITION_ID);
      end loop;
    -- produit fabriqué
    else
      for tplDicFabConditionId in (select DFC.*
                                     from DIC_FAB_CONDITION DFC
                                        , GCO_COMPL_DATA_MANUFACTURE CDM
                                    where DFC.DIC_FAB_CONDITION_ID = CDM.DIC_FAB_CONDITION_ID
                                      and CDM.GCO_GOOD_ID = iGcoGoodId) loop
        pipe row(tplDicFabConditionId.DIC_FAB_CONDITION_ID);
      end loop;
    end if;
  end GetSubcontractPFabConditionId;

  /**
  * procedure GetSubcontractPSupplierId
  * Description : Recherche de la liste des fournisseurs
  *               valides en fonction du mode d'approvisionnement du produit
  *
  * @created eca 15.04.2011
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iCSupplyMode : Mode d'approvisionnement
  * @param   iDateRef : Date référence
  */
  function GetSubcontractPSupplierId(iGcoGoodId in number, iCSupplyMode in varchar2, iDateRef in date default sysdate)
    return ID_TABLE_TYPE pipelined
  is
  begin
    -- produit sous-traité
    if iCSupplyMode = '4' then
      for tplSupplierId in (select CSU.PAC_SUPPLIER_PARTNER_ID
                              from GCO_COMPL_DATA_SUBCONTRACT CSU
                             where CSU.GCO_GOOD_ID = iGcoGoodId
                               and nvl(CSU.CSU_VALIDITY_DATE, trunc(iDateRef) ) <= trunc(iDateRef) ) loop
        pipe row(tplSupplierId.PAC_SUPPLIER_PARTNER_ID);
      end loop;
    -- produit fabriqué
    else
      for tplSupplierId in (select SUP.PAC_SUPPLIER_PARTNER_ID
                              from PAC_SUPPLIER_PARTNER SUP
                             where SUP.C_PARTNER_STATUS = '1') loop
        pipe row(tplSupplierId.PAC_SUPPLIER_PARTNER_ID);
      end loop;
    end if;
  end GetSubcontractPSupplierId;

  /**
  * procedure GetSubcPSupplyRequestDelay
  * Description : Calcul des délais commande et disponibilité des demandes
  *               d'approvisionnement en produits sous-traités
  *
  * @created eca 15.04.2011
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iPacSupplierPartnerId : Fournisseur
  * @param   iDicFabConditionId : COndition de fabrication
  * @param   iAskedTotalQty : Qté totale
  * @param   iDateRef : Date référence
  * @param   iFromCommandDelay : Calcul depuis délai de commande (depuis délai de dispo sinon)
  * @param   ioDurationInDays : durée en jours
  * @param   ioCommandDelay : Délai de commande
  * @param   ioDispoDelay : Délai de disponibilité
  */
  procedure GetSubcPSupplyRequestDelay(
    iGcoGoodId            in     number
  , iPacSupplierPartnerId in     number default null
  , iDicFabConditionId    in     varchar2 default null
  , iAskedTotalQty        in     number default 0
  , iDateRef              in     date default sysdate
  , iFromCommandDelay     in     integer default 1
  , ioDurationInDays      in out number
  , ioCommandDelay        in out date
  , ioDispoDelay          in out date
  )
  is
    lnGcoComplDataSubcPID number;
    ltGcoComplDataSubcP   GCO_COMPL_DATA_SUBCONTRACT%rowtype;
    liFounded             integer;
    lnBasisLag            number;
    lnInterLag            number;
    lnFinalLag            number;
  begin
    -- Recherche de la donnée complémentaire correspondante
    FAL_LIB_MRP_CALCULATION.GetSubContractPComplData(iGcoGoodId, iDicFabConditionID, iPacSupplierPartnerID, liFounded, lnGcoComplDataSubcPID);

    -- Si non trouvée
    if liFounded = 0 then
      -- Recherche délai de dispo
      if iFromCommandDelay = 1 then
        ioCommandDelay  := nvl(ioCommandDelay, sysdate);
        ioDispoDelay    := ioCommandDelay;
      -- Recherche du délai de commande
      else
        ioDispoDelay    := nvl(ioDispoDelay, sysdate);
        ioCommandDelay  := ioDispoDelay;
      end if;
    -- Donnée complémentaire trouvée
    else
      ltGcoComplDataSubcP  := GCO_LIB_COMPL_DATA.GetSubCComplDataTuple(lnGcoComplDataSubcPID);
      -- Calcul des délais
      DOC_LIB_SUBCONTRACTP.getSUPOLags(ltGcoComplDataSubcP.CSU_CONTROL_DELAY
                                     , ltGcoComplDataSubcP.CSU_SUBCONTRACTING_DELAY
                                     , ltGcoComplDataSubcP.CSU_ECONOMICAL_QUANTITY
                                     , ltGcoComplDataSubcP.CSU_FIX_DELAY
                                     , ltGcoComplDataSubcP.CSU_LOT_QUANTITY
                                     , iAskedTotalQty
                                     , lnBasisLag
                                     , lnInterLag
                                     , lnFinalLag
                                      );
      -- Recherche délai de dispo
      ioDurationInDays     := lnInterLag + lnFinalLag;

      if iFromCommandDelay = 1 then
        ioCommandDelay  := nvl(ioCommandDelay, sysdate);
        ioDispoDelay    :=
          FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(null
                                                      , ltGcoComplDataSubcP.PAC_SUPPLIER_PARTNER_ID
                                                      , null
                                                      , null
                                                      , null
                                                      , null
                                                      , ioCommandDelay
                                                      , ioDurationInDays
                                                       );
      -- Recherche du délai de commande
      else
        ioDispoDelay    := nvl(ioDispoDelay, sysdate);
        ioCommandDelay  :=
          FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(null
                                                       , ltGcoComplDataSubcP.PAC_SUPPLIER_PARTNER_ID
                                                       , null
                                                       , null
                                                       , null
                                                       , null
                                                       , ioDispoDelay
                                                       , ioDurationInDays
                                                        );
      end if;
    end if;
  end GetSubcPSupplyRequestDelay;
end FAL_SUPPLY_REQUEST_FUNCTIONS;
