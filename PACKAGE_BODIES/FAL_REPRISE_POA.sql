--------------------------------------------------------
--  DDL for Package Body FAL_REPRISE_POA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_REPRISE_POA" 
is
  /**
  * procedure   : MAJ_RESEAUXPOA_PROD_TERMINES
  * Description : Mise à jour des réseaux pour les POA.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PropId : proposition
  * @param   aDOC_POSITION_DETAIL_ID : Détail position
  * @param   PrmLOT_INPROD_QTY : Qté en fabrication
  */
  procedure MAJ_RESEAUXPOA_PROD_TERMINES(
    PropId                  fal_lot_prop.fal_lot_prop_id%type
  , aDOC_POSITION_DETAIL_ID number
  , PrmLOT_INPROD_QTY       FAL_LOT.LOT_INPROD_QTY%type
  )
  is
    type TFAL_NETWORK_LINK is record(
      FAL_NETWORK_LINK_ID   FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
    , FAL_NETWORK_NEED_ID   FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID%type
    , STM_LOCATION_ID       FAL_NETWORK_LINK.STM_LOCATION_ID%type
    , STM_STOCK_POSITION_ID FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type
    , FLN_QTY               FAL_NETWORK_LINK.FLN_QTY%type
    , FLN_NEED_DELAY        FAL_NETWORK_LINK.FLN_NEED_DELAY%type
    );

    I                        integer;
    PrmFAL_NETWORK_SUPPLY_ID number;
    nUserCode                number;
    Q                        FAL_LOT.LOT_INPROD_QTY%type;
    A                        FAL_LOT.LOT_INPROD_QTY%type;
    FIN                      boolean;
    Id_reseauxApprocree      number;
    EnrFAL_NETWORK_LINK      TFAL_NETWORK_LINK;

    cursor C1(PrmFAL_NETWORK_SUPPLY_ID number)
    is
      select FAL_NETWORK_LINK_ID
           , FAL_NETWORK_NEED_ID
           , STM_LOCATION_ID
           , STM_STOCK_POSITION_ID
           , FLN_QTY
           , FLN_NEED_DELAY
        from FAL_NETWORK_LINK
       where FAL_NETWORK_SUPPLY_ID = PrmFAL_NETWORK_SUPPLY_ID;

    cursor C2(PrmUSERCODE number)
    is
      select   FAL_NETWORK_LINK_ID
             , FAL_NETWORK_NEED_ID
             , STM_LOCATION_ID
             , STM_STOCK_POSITION_ID
             , FLN_QTY
             , FLN_NEED_DELAY
          from FAL_NETWORK_LINK_TEMP
         where FAL_NETWORK_LINK_TEMP_ID = PrmUSERCODE
      order by FLN_NEED_DELAY;
  begin
    -- Obtenir un userCode qui servira pour la création des enregistrements dans la table temporaire
    nUserCode := GetNewId;

    -- Pour chaque Proposition Enregsitrement dans la table temporaire ATTRIBUTIONS PT Puis SUPPRESSION des PROPOSITION
    select FAL_NETWORK_SUPPLY_ID
      into PrmFAL_NETWORK_SUPPLY_ID
      from FAL_NETWORK_SUPPLY
     where FAL_DOC_PROP_ID = PropId;

    open C1(PrmFAL_NETWORK_SUPPLY_ID);

    fetch C1
     into EnrFAL_NETWORK_LINK;

    while C1%found loop
      insert into FAL_NETWORK_LINK_TEMP
                  (FAL_NETWORK_LINK_TEMP_ID
                 ,   -- UserCode en fait
                   FAL_NETWORK_LINK_ID
                 , FAL_NETWORK_NEED_ID
                 , STM_LOCATION_ID
                 , STM_STOCK_POSITION_ID
                 , FLN_QTY
                 , FLN_NEED_DELAY
                  )
           values (nUserCode
                 , EnrFAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
                 , EnrFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
                 , EnrFAL_NETWORK_LINK.STM_LOCATION_ID
                 , EnrFAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                 , EnrFAL_NETWORK_LINK.FLN_QTY
                 , EnrFAL_NETWORK_LINK.FLN_NEED_DELAY
                  );

      fetch C1
       into EnrFAL_NETWORK_LINK;
    end loop;   -- Boucle de recopie des Attribs dans la table temporaire

    close C1;

    -- Suppression Attributions Appro-Stock
    FAL_NETWORK.Attribution_Suppr_ApproStock(PrmFAL_NETWORK_SUPPLY_ID);
    -- Suppression Attributions Appro-Besoin
    FAL_NETWORK.Attribution_Suppr_ApproBesoin(PrmFAL_NETWORK_SUPPLY_ID);
    -- Assignation de la quantité
    Q    := PrmLOT_INPROD_QTY;
    -- Lecture de la table temporaire
    Fin  := false;

    open C2(nUserCode);

    fetch C2
     into EnrFAL_NETWORK_LINK;

    while(C2%found)
     and (FIN = false) loop   -- FG-19991109-1
      if Q > EnrFAL_NETWORK_LINK.FLN_QTY then
        A    := EnrFAL_NETWORK_LINK.FLN_QTY;
        Fin  := false;
      end if;

      if Q = EnrFAL_NETWORK_LINK.FLN_QTY then
        A    := EnrFAL_NETWORK_LINK.FLN_QTY;
        Fin  := true;
      end if;

      if Q < EnrFAL_NETWORK_LINK.FLN_QTY then
        A    := Q;
        Fin  := true;
      end if;

      -- Récupérer l'ID du réseauxApproCrée
      select FAL_NETWORK_SUPPLY_ID
        into Id_reseauxApprocree
        from FAL_NETWORK_SUPPLY
       where DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID;

      if enrFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID is not null then
        FAl_NETWORK.CreateAttribBesoinApproPOA(EnrFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID, Id_reseauxApprocree, A);
      else
        -- Que se passe t-il si ici la location est NULLE (Peut-elle l'être ?)
        FAl_NETWORK.CreateAttribApproStockPOA(Id_reseauxApprocree, EnrFAL_NETWORK_LINK.STM_LOCATION_ID, A);
      end if;

      Q  := Q - A;

      fetch C2
       into EnrFAL_NETWORK_LINK;
    end loop;

    close C2;

    -- Detruire les enregs de la table temporaire
    delete      FAL_NETWORK_LINK_TEMP
          where FAL_NETWORK_LINK_TEMP_ID = nUserCode;
  exception
    when no_data_found then
      begin
        -- Detruire les enregs de la table temporaire
        delete      FAL_NETWORK_LINK_TEMP
              where FAL_NETWORK_LINK_TEMP_ID = nUserCode;
      end;
    when others then
      begin
        -- Detruire les enregs de la table temporaire
        delete      FAL_NETWORK_LINK_TEMP
              where FAL_NETWORK_LINK_TEMP_ID = nUserCode;

        raise;
      end;
  end;

  /**
  * procedure UpdatePDEGenericPDT
  * Description : Une fois les POA Reprises, Mise à jour produit générique sur les détails position
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aDOC_DOCUMENT_ID : Document
  */
  procedure UpdatePDEGenericPDT(aDOC_DOCUMENT_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor CUR_POS_NETWORK_LINK
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , LOM.GCO_GCO_GOOD_ID LOM_GOOD_ID
                    , LOMPROP.GCO_GCO_GOOD_ID LOM_PROP_GOOD_ID
                 from DOC_DOCUMENT DOC
                    , DOC_GAUGE_STRUCTURED GAU
                    , DOC_POSITION POS
                    , DOC_POSITION_DETAIL PDE
                    , FAL_NETWORK_LINK FNL
                    , FAL_NETWORK_SUPPLY FNS
                    , FAL_NETWORK_NEED FNN
                    , FAL_LOT_MAT_LINK_PROP LOMPROP
                    , FAL_LOT_MATERIAL_LINK LOM
                    , GCO_PRODUCT PDT
                where DOC.DOC_DOCUMENT_ID = aDOC_DOCUMENT_ID
                  and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                  and PDE.DOC_POSITION_DETAIL_ID = FNS.DOC_POSITION_DETAIL_ID
                  and FNS.FAL_NETWORK_SUPPLY_ID = FNL.FAL_NETWORK_SUPPLY_ID
                  and FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                  and FNN.FAL_LOT_MAT_LINK_PROP_ID = LOMPROP.FAL_LOT_MAT_LINK_PROP_ID(+)
                  and FNN.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID(+)
                  and (    (    FNN.FAL_LOT_MAT_LINK_PROP_ID is not null
                            and LOMPROP.GCO_GCO_GOOD_ID is not null)
                       or (    FNN.FAL_LOT_MATERIAL_LINK_ID is not null
                           and LOM.GCO_GCO_GOOD_ID is not null)
                      )
                  and GAU.GAS_MULTISOURCING_MGM = 1
                  and (    (    POS.C_GAUGE_TYPE_POS = '1'
                            and POS.DOC_DOC_POSITION_ID is null)
                       or (POS.C_GAUGE_TYPE_POS = '91')
                       or (POS.C_GAUGE_TYPE_POS = '101') )
                  and PDT.PAC_SUPPLIER_PARTNER_ID is not null;

    CurPosNetworkLink CUR_POS_NETWORK_LINK%rowtype;
  begin
    for CurPosNetworkLink in CUR_POS_NETWORK_LINK loop
      if CurPosNetworkLink.LOM_GOOD_ID is not null then
        update DOC_POSITION_DETAIL
           set GCO_GCO_GOOD_ID = CurPosNetworkLink.LOM_GOOD_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_DETAIL_ID = CurPosNetworkLink.DOC_POSITION_DETAIL_ID;
      elsif CurPosNetworkLink.LOM_PROP_GOOD_ID is not null then
        update DOC_POSITION_DETAIL
           set GCO_GCO_GOOD_ID = CurPosNetworkLink.LOM_PROP_GOOD_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_DETAIL_ID = CurPosNetworkLink.DOC_POSITION_DETAIL_ID;
      end if;
    end loop;
  end UpdatePDEGenericPDT;

  /**
  * procedure   : UpdatePOAFinancialCurrency
  * Description : Reprise des POA, MAJ de la monnaie avant reprise si celle-ci n'est pas renseignée
  *
  * @created ECA
  * @lastUpdate
  * @param   aFDP_ORACLE_SESSION : Session Oracle des POA à updater.
  */
  procedure UpdatePOAFinancialCurrency(aFDP_ORACLE_SESSION FAL_DOC_PROP.FDP_ORACLE_SESSION%type)
  is
  begin
    update FAL_DOC_PROP
       set ACS_FINANCIAL_CURRENCY_ID = DOC_DOCUMENT_FUNCTIONS.GetThirdCurrencyId(DOC_GAUGE_ID, PAC_THIRD_ACI_ID)
     where FDP_ORACLE_SESSION = aFDP_ORACLE_SESSION
       and ACS_FINANCIAL_CURRENCY_ID is null
       and FDP_SELECT = 1;
  end UpdatePOAFinancialCurrency;
end;
