--------------------------------------------------------
--  DDL for Package Body FAL_PRC_RETRIEVE_MANUF_PROP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_RETRIEVE_MANUF_PROP" 
is
  -- Configurations
  cfgFalCoupledGood          boolean :=(nvl(PCS.PC_CONFIG.GetConfig('FAL_COUPLED_GOOD'), '0') = '1');
  cfgFalInitialPlanification boolean :=(nvl(PCS.PC_CONFIG.GetConfig('FAL_INITIAL_PLANIFICATION'), '0') = '1');
  cOrtems                    boolean := PCS.PC_CONFIG.GetBooleanConfig('FAL_ORT');

  /**
  * procedure GetPropositionFromTable
  * Description : Récupération d'une proposition dans la table temporaire de travail
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iFallotPropTempId : proposition
  */
  function GetPropositionFromTable(iFalLotPropTempId in number)
    return TPropositions
  is
  begin
    if oTabSelectedProp.count > 0 then
      for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
        if oTabSelectedProp(i).FAL_LOT_PROP_TEMP_ID = iFalLotPropTempId then
          return oTabSelectedProp(i);
        end if;
      end loop;
    end if;
  end GetPropositionFromTable;

  /****
  * function FindFalOrder
  * Description : Sélection de l'ordre maximum d'un produit pour un programme donné.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iFalJobProgramId : Programme de fabrication
  */
  function FindFalOrder(iGcoGoodId in number, iFalJobProgramId in number)
    return number
  is
    lnFAL_ORDER_ID number;
  begin
    select max(FAL_ORDER_ID)
      into lnFAL_ORDER_ID
      from FAL_ORDER
     where GCO_GOOD_ID = iGcoGoodId
       and FAL_JOB_PROGRAM_ID = iFalJobProgramId;

    return LnFAL_ORDER_ID;
  exception
    when no_data_found then
      return null;
  end;

  /****
  * procedure MajComponentNetwork
  *
  * Description : Mise à jour réseaux composants
  *
  */
  procedure MajComponentNetwork(PropId FAL_LOT_PROP_TEMP.FAL_LOT_PROP_TEMP_ID%type, PrmFAL_LOT_ID number, PrmLOT_INPROD_QTY FAL_LOT.LOT_INPROD_QTY%type)
  is
    type TFAL_LOT_MATERIAL_LINK is record(
      FAL_LOT_MATERIAL_LINK_ID FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
    , GCO_GOOD_ID              FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type
    , LOM_NEED_QTY             FAL_LOT_MATERIAL_LINK.LOM_NEED_QTY%type
    );

    EnrFAL_LOT_MATERIAL_LINK TFAL_LOT_MATERIAL_LINK;

    type TFAL_NETWORK_NEED is record(
      FAL_NETWORK_NEED_ID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
    );

    EnrFAL_NETWORK_NEED      TFAL_NETWORK_NEED;

    type TFAL_NETWORK_NEED_Real is record(
      FAL_NETWORK_NEED_ID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
    , QTY                 FAL_NETWORK_NEED.FAN_FREE_QTY%type
    );

    EnrFAL_NETWORK_NEED_Real TFAL_NETWORK_NEED_Real;

    cursor CurFAL_LOT_MATERIAL_LINK(PrmFAL_LOT_ID number)
    is
      select   FAL_LOT_MATERIAL_LINK_ID
             , GCO_GOOD_ID
             , LOM_NEED_QTY
          from FAL_LOT_MATERIAL_LINK
         where FAL_LOT_ID = PrmFAL_LOT_ID
           and LOM_STOCK_MANAGEMENT = 1
           and C_KIND_COM = 1
           and LOM_NEED_QTY > 0
      order by GCO_GOOD_ID;

    cursor CFAL_NETWORK_LINK(PrmFAL_NETWORK_NEED_ID number)
    is
      select FAL_NETWORK_SUPPLY_ID
           , FAL_NETWORK_LINK_ID
           , STM_LOCATION_ID
           , STM_STOCK_POSITION_ID
           , FLN_QTY
           , FLN_NEED_DELAY
        from FAL_NETWORK_LINK
       where FAL_NETWORK_need_ID = PrmFAL_NETWORK_NEED_ID;

    EnrFAL_NETWORK_LINK      CFAL_NETWORK_LINK%rowtype;

    cursor CFAL_NETWORK_NEED
    is
      select FAL_NETWORK_NEED_ID
        from FAl_NETWORK_NEED
       where GCO_GOOD_ID = EnrFAL_LOT_MATERIAL_LINK.GCO_GOOD_ID
         and FAL_LOT_PROP_ID = PropId;

    cursor CTemp(PrmUSERCODE number)
    is
      select   FAL_NETWORK_SUPPLY_ID
             , FAL_NETWORK_LINK_ID
             , STM_LOCATION_ID
             , STM_STOCK_POSITION_ID
             , FLN_QTY
             , FLN_NEED_DELAY
          from FAL_NETWORK_LINK_TEMP
         where FAL_NETWORK_LINK_TEMP_ID = PrmUSERCODE
      order by FLN_NEED_DELAY;

    nUserCode                number;
    Q                        FAL_LOT.LOT_INPROD_QTY%type;
    A                        FAL_LOT.LOT_INPROD_QTY%type;
    FIN                      boolean;
    ValFAL_NETWORK_NEED_ID   number;
    my_ID                    number;
  begin
    -- Obtenir un userCode qui servira pour la création des enregs dans la table temporaire
    nUserCode  := GetNewId;

    -- pour chaque composant du lot liée
    open CurFAL_LOT_MATERIAL_LINK(PrmFAL_LOT_ID);   -- Boucle des composants

    loop
      fetch CurFAL_LOT_MATERIAL_LINK
       into EnrFAL_LOT_MATERIAL_LINK;

      exit when CurFAL_LOT_MATERIAL_LINK%notfound;

      open CFAL_NETWORK_NEED;

      loop   -- Boucle sur les besoins
        fetch CFAL_NETWORK_NEED
         into ValFAL_NETWORK_NEED_ID;

        exit when CFAL_NETWORK_NEED%notfound;

        open CFAL_NETWORK_LINK(ValFAL_NETWORK_NEED_ID);

        loop
          fetch CFAL_NETWORK_LINK
           into EnrFAL_NETWORK_LINK;

          exit when CFAL_NETWORK_LINK%notfound;

          insert into FAL_NETWORK_LINK_TEMP
                      (FAL_NETWORK_LINK_TEMP_ID
                     ,   -- UserCode en fait
                       FAL_NETWORK_LINK_ID
                     , FAL_NETWORK_SUPPLY_ID
                     , STM_LOCATION_ID
                     , STM_STOCK_POSITION_ID
                     , FLN_QTY
                     , FLN_NEED_DELAY
                      )
               values (nUserCode
                     , EnrFAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
                     , EnrFAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID
                     , EnrFAL_NETWORK_LINK.STM_LOCATION_ID
                     , EnrFAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                     , EnrFAL_NETWORK_LINK.FLN_QTY
                     , EnrFAL_NETWORK_LINK.FLN_NEED_DELAY
                      );
        end loop;   -- Boucle de recopie des Attribs dans la table temporaire

        close CFAL_NETWORK_LINK;

        -- SUPPRIMER LES ATTRIBS POUR LE FAL_NETWORK_NEED_ID;
        -- Suppression Attributions Besoin-Stock
        Fal_Network.Attribution_Suppr_BesoinStock(ValFAL_NETWORK_NEED_ID);
        -- Suppression Attributions Besoin-Appro
        Fal_Network.Attribution_Suppr_BesoinAppro(ValFAL_NETWORK_NEED_ID);
      end loop;   -- Fin Boucle sur les besoins

      close CFAL_NETWORK_NEED;

      /* Ceci est plus sensé et plus précis. (avant le where était sur le lot et le bien, mais si le lot avait plusieurs composants
         identiques cela pouvait poser des problèmes assez difficiles à éclaircir surtout si les coeffs d'utilisation sont différents)
         En effet un fal_lot_material_link_id ne peut pas avoir donné naissance à plusieurs needs
         donc le need que nous cherchons est nécessairement celui du lien composant que nous sommes
         en train de traiter.
         de plus j'assure ici (pour l'avenir) en indiquant le lot du composant donc blindé.*/
      select FAL_NETWORK_NEED_ID
           , FAN_FREE_QTY
        into EnrFAL_NETWORK_NEED_Real
        from FAL_NETWORK_NEED
       where FAL_LOT_ID = PrmFAL_LOT_ID
         and FAL_LOT_MATERIAL_LINK_ID = enrFAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID;

      Q    := EnrFAL_NETWORK_NEED_Real.Qty;
      -- Lecture de la table temporaire
      FIN  := false;

      open CTemp(nUserCode);

      loop
        fetch CTemp
         into EnrFAL_NETWORK_LINK;

        exit when(CTemp%notfound)
              or (FIN = true);

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

        -- Etape 3.
        if enrFAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID is not null then
          Fal_Network.CreateAttribBesoinAppro(EnrFAL_NETWORK_NEED_Real.FAL_NETWORK_NEED_ID, EnrFAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID, A);
        else
          Fal_Network.CreateAttribBesoinStock(EnrFAL_NETWORK_NEED_Real.FAL_NETWORK_NEED_ID
                                            , EnrFAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                                            , EnrFAL_NETWORK_LINK.STM_LOCATION_ID
                                            , A
                                             );
        end if;

        Q  := Q - A;
      end loop;   -- Fin de lecture des Attribs sauvegardée

      close Ctemp;

      -- Detruire les enregs de la table temporaire
      delete      FAL_NETWORK_LINK_TEMP
            where FAL_NETWORK_LINK_TEMP_ID = nUserCode;
    end loop;   -- fin de boucle des composants

    close CurFAL_LOT_MATERIAL_LINK;
  /* Rajouté suite au problème de reprise chez nouveaux clients. Les consultants crée à la main des propositions qui n'ont pas,
     par conséquent d'appro correspondante */
  exception
    when no_data_found then
      begin
        -- Detruire les enregs de la table temporaire
        delete      FAL_NETWORK_LINK_TEMP
              where FAL_NETWORK_LINK_TEMP_ID = nUserCode;
      end;
  end MajComponentNetwork;

  /**
  * procedure TransfertNetworkLink
  * Description : Mise à jour réseaux produits terminés pour les nons couplés
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  */
  procedure TransfertNetworkLink(
    iPropId        in FAL_LOT_PROP_TEMP.FAL_LOT_PROP_TEMP_id%type
  , iBatchId       in FAL_LOT.FAL_LOT_ID%type
  , iAskedQty      in FAL_LOT.LOT_ASKED_QTY%type
  , iCoupledGoodId in FAL_NETWORK_SUPPLY.GCO_GOOD_ID%type default null
  )
  is
    lnNetwLinkTmpId FAL_NETWORK_LINK_TEMP.FAL_NETWORK_LINK_TEMP_ID%type;
    lnBatchSupplyId FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    lnQtyToLink     FAL_LOT.LOT_ASKED_QTY%type;
  begin
    lnNetwLinkTmpId  := GetNewId;

    for tplSupply in (select FAL_NETWORK_SUPPLY_ID
                        from FAL_NETWORK_SUPPLY
                       where FAL_LOT_PROP_ID = iPropId
                         and (   iCoupledGoodId is null
                              or GCO_GOOD_ID = iCoupledGoodId) ) loop
      /* Enregistrement dans la table temporaire des liens attributions de la proposition */
      insert into FAL_NETWORK_LINK_TEMP
                  (FAL_NETWORK_LINK_TEMP_ID
                 , FAL_NETWORK_LINK_ID
                 , FAL_NETWORK_NEED_ID
                 , FAL_NETWORK_SUPPLY_ID
                 , STM_LOCATION_ID
                 , STM_STOCK_POSITION_ID
                 , FLN_QTY
                 , FLN_NEED_DELAY
                  )
        select lnNetwLinkTmpId
             , FAL_NETWORK_LINK_ID
             , FAL_NETWORK_NEED_ID
             , FAL_NETWORK_SUPPLY_ID
             , STM_LOCATION_ID
             , STM_STOCK_POSITION_ID
             , FLN_QTY
             , FLN_NEED_DELAY
          from FAL_NETWORK_LINK LNK
         where FAL_NETWORK_SUPPLY_ID = tplSupply.FAL_NETWORK_SUPPLY_ID;

      /* Suppression Attributions Appro-Stock */
      FAL_NETWORK.Attribution_Suppr_ApproStock(tplSupply.FAL_NETWORK_SUPPLY_ID);
      /* Suppression Attributions Appro-Besoin */
      FAL_NETWORK.Attribution_Suppr_ApproBesoin(tplSupply.FAL_NETWORK_SUPPLY_ID);
    end loop;

    lnQtyToLink      := iAskedQty;

    /* Parcours des liens de proposition sauvés et report sur l'appro du nouvel OF */
    for tplLinkSaved in (select   FAL_NETWORK_NEED_ID
                                , FAL_NETWORK_SUPPLY_ID
                                , STM_LOCATION_ID
                                , FLN_QTY
                             from FAL_NETWORK_LINK_TEMP
                            where FAL_NETWORK_LINK_TEMP_ID = lnNetwLinkTmpId
                         order by FLN_NEED_DELAY) loop
      /* Récupération de l'ID appro correspondant de l'OF nouvellement créé. S'il est caractérisé morpho, plusieurs appros peuvent être liés à cet OF.
         Il faut aller chercher celui avec la bonne caractérisation. */
      select FAL_NETWORK_SUPPLY_ID
        into lnBatchSupplyId
        from FAL_NETWORK_SUPPLY SUP_TARGET
           , (select FAN_CHAR_VALUE1
                   , FAN_CHAR_VALUE2
                   , FAN_CHAR_VALUE3
                   , FAN_CHAR_VALUE4
                   , FAN_CHAR_VALUE5
                from FAL_NETWORK_SUPPLY
               where FAL_NETWORK_SUPPLY_ID = tplLinkSaved.FAL_NETWORK_SUPPLY_ID) SUP_SRC
       where FAL_LOT_ID = iBatchId
         and (    (    iCoupledGoodId is null
                   and nvl(SUP_TARGET.FAN_CHAR_VALUE1, ' ') = nvl(SUP_SRC.FAN_CHAR_VALUE1, ' ')
                   and nvl(SUP_TARGET.FAN_CHAR_VALUE2, ' ') = nvl(SUP_SRC.FAN_CHAR_VALUE2, ' ')
                   and nvl(SUP_TARGET.FAN_CHAR_VALUE3, ' ') = nvl(SUP_SRC.FAN_CHAR_VALUE3, ' ')
                   and nvl(SUP_TARGET.FAN_CHAR_VALUE4, ' ') = nvl(SUP_SRC.FAN_CHAR_VALUE4, ' ')
                   and nvl(SUP_TARGET.FAN_CHAR_VALUE5, ' ') = nvl(SUP_SRC.FAN_CHAR_VALUE5, ' ')
                  )
              or GCO_GOOD_ID = iCoupledGoodId
             );

      if tplLinkSaved.FAL_NETWORK_NEED_ID is not null then
        FAL_NETWORK.CreateAttribBesoinAppro(tplLinkSaved.FAL_NETWORK_NEED_ID, lnBatchSupplyId, least(lnQtyToLink, tplLinkSaved.FLN_QTY) );
      else
        FAL_NETWORK.CreateAttribApproStock(lnBatchSupplyId, tplLinkSaved.STM_LOCATION_ID, least(lnQtyToLink, tplLinkSaved.FLN_QTY) );
      end if;

      if lnQtyToLink > tplLinkSaved.FLN_QTY then
        lnQtyToLink  := lnQtyToLink - tplLinkSaved.FLN_QTY;
      else
        exit;
      end if;
    end loop;

    -- Detruire les enregs de la table temporaire
    delete      FAL_NETWORK_LINK_TEMP
          where FAL_NETWORK_LINK_TEMP_ID = lnNetwLinkTmpId;
  end TransfertNetworkLink;

  /****
  * procedure MajPDTNetwork
  * Description : Mise à jour réseaux produits terminés.
  * @version 2011
  * @author ECA
  * @lastUpdate
  * @public
  * @param
  */
  procedure MajPDTNetwork(
    iFalLotPropId in FAL_LOT_PROP_TEMP.FAL_LOT_PROP_TEMP_id%type
  , iFalLotId     in FAL_LOT.FAL_LOT_ID%type
  , iAskedQty     in FAL_LOT.LOT_ASKED_QTY%type
  )
  is
  begin
    if FAL_COUPLED_GOOD.ExistsDetailForCoupledGood(iFalLotId) = 1 then
      for tplDetailLot in (select distinct GCO_GOOD_ID
                                      from FAL_LOT_DETAIL
                                     where FAL_LOT_ID = iFalLotId) loop
        TransfertNetworkLink(iPropId => iFalLotPropId, iBatchId => iFalLotId, iAskedQty => iAskedQty, iCoupledGoodId => tplDetailLot.GCO_GOOD_ID);
      end loop;
    else
      TransfertNetworkLink(iPropId => iFalLotPropId, iBatchId => iFalLotId, iAskedQty => iAskedQty);
    end if;
  end MajPDTNetwork;

  /****
  * procedure RetrieveComponentsOfProp
  *
  * Description :  Procédure de récupération des composants à partir des composants de la proposition
  *                Vers la table des liens composants lot
  * @version 2011
  * @author ECA
  * @lastUpdate
  * @public
  * @param   iFalLotPropId : proposition
  * @param   iFalLotId : Lot
  */
  procedure RetrieveComponentsOfProp(iFalLotPropId in number, iFalLotId in number, iCDischargeCom in GCO_COMPL_DATA_SUBCONTRACT.C_DISCHARGE_COM%type)
  is
  begin
    /* On pousse un composant vers FAL_LOT_MATERIAL_LINK. Ce n'est pas la peine de recalculer les quantités étant donné que l'utilisateur
      ne peut modifier la POF si l'indicateur de changement de composants est positionné à 1 (True) */
    -- Création du Lien composant
    insert into FAL_LOT_MATERIAL_LINK
                (FAL_LOT_MATERIAL_LINK_ID
               , LOM_SEQ
               , LOM_SUBSTITUT
               , LOM_STOCK_MANAGEMENT
               , LOM_SECONDARY_REF
               , LOM_SHORT_DESCR
               , C_KIND_COM
               , C_DISCHARGE_COM
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , FAL_LOT_ID
               , PC_YEAR_WEEK_ID
               , LOM_LONG_DESCR
               , LOM_FREE_DECR
               , LOM_POS
               , LOM_FRE_NUM
               , LOM_TEXT
               , LOM_FREE_TEXT
               , LOM_UTIL_COEF
               , LOM_BOM_REQ_QTY
               , LOM_ADJUSTED_QTY
               , LOM_FULL_REQ_QTY
               , LOM_CONSUMPTION_QTY
               , LOM_REJECTED_QTY
               , LOM_BACK_QTY
               , LOM_PT_REJECT_QTY
               , LOM_CPT_TRASH_QTY
               , LOM_CPT_RECOVER_QTY
               , LOM_CPT_REJECT_QTY
               , LOM_EXIT_RECEIPT
               , LOM_NEED_QTY
               , LOM_MAX_RECEIPT_QTY
               , LOM_MAX_FACT_QTY
               , LOM_INTERVAL
               , LOM_NEED_DATE
               , LOM_PRICE
               , A_DATECRE
               , A_IDCRE
               , C_TYPE_COM
               , C_CHRONOLOGY_TYPE
               , LOM_AVAILABLE_QTY
               , LOM_MISSING
               , LOM_TASK_SEQ
               , LOM_ADJUSTED_QTY_RECEIPT
               , LOM_REF_QTY
               , LOM_MARK_TOPO
               , LOM_QTY_REFERENCE_LOSS
               , LOM_FIXED_QUANTITY_WASTE
               , LOM_PERCENT_WASTE
               , LOM_WEIGHING
               , LOM_WEIGHING_MANDATORY
                )
      select GetNewId
           , LOM_SEQ
           , LOM_SUBSTITUT
           , LOM_STOCK_MANAGEMENT
           , LOM_SECONDARY_REF
           , LOM_SHORT_DESCR
           , C_KIND_COM
           -- Pour un OF de sous-traitance, le code de décharge doit être '2' ou '5'. On force à '2' si c'est une autre valeur.
      ,      case LOT.C_FAB_TYPE
               when FAL_BATCH_FUNCTIONS.btSubcontract then case
                                                            when iCDischargeCom is not null then iCDischargeCom
                                                            when LOM.C_DISCHARGE_COM = '5' then '5'
                                                            else '2'
                                                          end
               else C_DISCHARGE_COM
             end
           , GCO_GOOD_ID
           , GCO_GCO_GOOD_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , iFalLotId
           , PC_YEAR_WEEK_ID
           , LOM_LONG_DESCR
           , LOM_FREE_DECR
           , LOM_POS
           , LOM_FRE_NUM
           , LOM_TEXT
           , LOM_FREE_TEXT
           , LOM_UTIL_COEF
           , LOM_BOM_REQ_QTY
           , LOM_ADJUSTED_QTY
           , LOM_FULL_REQ_QTY
           , LOM_CONSUMPTION_QTY
           , LOM_REJECTED_QTY
           , LOM_BACK_QTY
           , LOM_PT_REJECT_QTY
           , LOM_CPT_TRASH_QTY
           , LOM_CPT_RECOVER_QTY
           , LOM_CPT_REJECT_QTY
           , LOM_EXIT_RECEIPT
           , LOM_NEED_QTY
           , LOM_MAX_RECEIPT_QTY
           , LOM_MAX_FACT_QTY
           , LOM_INTERVAL
           , LOM_NEED_DATE
           , LOM_PRICE
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , C_TYPE_COM
           , C_CHRONOLOGY_TYPE
           , LOM_AVAILABLE_QTY
           , LOM_MISSING
           , (select SCS_STEP_NUMBER
                from FAL_TASK_LINK
               where FAL_LOT_ID = iFalLotId
                 and TAL_SEQ_ORIGIN = LOM.LOM_TASK_SEQ)
           , LOM_ADJUSTED_QTY_RECEIPT
           , LOM_REF_QTY
           , LOM_MARK_TOPO
           , LOM_QTY_REFERENCE_LOSS
           , LOM_FIXED_QUANTITY_WASTE
           , LOM_PERCENT_WASTE
           , LOM_WEIGHING
           , LOM_WEIGHING_MANDATORY
        from FAL_LOT_MAT_LINK_PROP LOM
           , (select nvl(C_FAB_TYPE, '0') C_FAB_TYPE
                from FAL_LOT
               where FAL_LOT_ID = iFalLotId) LOT
       where FAL_LOT_PROP_ID = iFalLotPropId;
  end RetrieveComponentsOfProp;

  /**
  * procedure CreateComponent
  * Description : Générations de la nomenclature de l'of
  *
  * @version 2011
  * @author ECA
  * @lastUpdate
  * @public
  * @param   iFAL_LOT_PROP_ID : proposition
  * @param   iListFAL_LOT_PROP_ID : Liste proposition
  * @param   iRetrieveComponentsProp : Reprendre les composants de la proposition
  * @param   iFalLotId : Lot
  * @param   iLotPlanEndDate : Date fin planifiée
  */
  procedure CreateComponent(
    iFAL_LOT_PROP_ID        in FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , iListFAL_LOT_PROP_ID    in varchar
  , iRetrieveComponentsProp in boolean
  , iFalLotId               in number
  , iLotPlanEndDate         in date
  , iCDischargeCom          in GCO_COMPL_DATA_SUBCONTRACT.C_DISCHARGE_COM%type
  )
  is
  begin
    -- Re-génération des composants
    if not iRetrieveComponentsProp then
      FAL_COMPONENT.GenerateComponents(iFalLotId, iListFAL_LOT_PROP_ID, iCDischargeCom);
    -- Reprise des composants de la proposition
    else
      -- Récupérer les composants de la proposition
      RetrieveComponentsOfProp(iFAL_LOT_PROP_ID, iFalLotId, iCDischargeCom);

      -- Ajout sur le lot du Flag " Composants modifiés".
      update FAL_LOT
         set LOT_UPDATED_COMPONENTS = 1
       where FAL_LOT_ID = iFalLotId;
    end if;

    -- Planification date fin proposition. Attention, pas de planification ici pour les lots de sous-traitance.
    -- Elle se fait après la création de la CAST.
    if nvl(FAL_LIB_BATCH.getCFabType(iLotID => iFalLotId), FAL_BATCH_FUNCTIONS.btManufacturing) <> FAL_BATCH_FUNCTIONS.btSubcontract then
      -- Planification date fin proposition
      FAL_PLANIF.Planification_lot(iFalLotId, iLotPlanEndDate, 0   -- N'est pas selon date début
                                                                , 1   -- Avec  Maj liens composants
                                                                   , 0);   -- Sans Maj reseaux requise

      -- On met à jour l'historique de lot 'Reprise POF' avec les dates du lot après replanif.
      -- Les dates qu'on avait avant ne voulait rien dire s'il y avait fusion lors de la reprise.
      for tplBatch in (select LOT_PLAN_BEGIN_DTE
                            , LOT_PLAN_END_DTE
                            , LOT_INPROD_QTY
                         from FAL_LOT
                        where FAL_LOT_ID = iFalLotId) loop
        -- Mise à jour de la qté max réceptionable
        FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(iFalLotId, tplBatch.LOT_INPROD_QTY);

        -- Mise à jour de l'historique
        update FAL_HISTO_LOT
           set HIS_PLAN_BEGIN_DTE = tplbatch.LOT_PLAN_BEGIN_DTE
             , HIS_PLAN_END_DTE = tplBatch.LOT_PLAN_END_DTE
         where FAL_LOT5_ID = iFalLotId
           and C_EVEN_TYPE = '18';

        exit;
      end loop;
    end if;
  end CreateComponent;

  /**
  * procedure CreateBatch
  * Description : Création d'un nouvel OF repris.
  *
  * @version 2011
  * @author ECA
  * @lastUpdate
  * @public
  * @param   iFalLotProp : proposition
  * @param   iComplementarydata : donnée complémentaire
  * @param   ioFalLotId : lot
  * @param   iCFabtype : Type standard ou sous-traitance)
  */
  procedure CreateBatch(iFalLotProp in TPropositions, iComplementarydata in TComplementaryData, ioFalLotId in out number, iCFabType in integer default 0)
  is
  begin
    ioFalLotId  := GetNewId;
    FAL_BATCH_FUNCTIONS.InsertBatch(aFAL_LOT_ID                   => ioFalLotId
                                  , aFAL_ORDER_ID                 => iFalLotProp.FAL_ORDER_ID
                                  , aDIC_FAB_CONDITION_ID         => iFalLotProp.DIC_FAB_CONDITION_ID
                                  , aSTM_STOCK_ID                 => iFalLotProp.STM_STOCK_ID
                                  , aSTM_LOCATION_ID              => iFalLotProp.STM_LOCATION_ID
                                  , aLOT_PLAN_BEGIN_DTE           => iFalLotProp.LOT_PLAN_BEGIN_DTE
                                  , aLOT_PLAN_END_DTE             => iFalLotProp.LOT_PLAN_END_DTE
                                  , aLOT_ASKED_QTY                => iFalLotProp.LOT_ASKED_QTY
                                  , aPPS_NOMENCLATURE_ID          => iComplementarydata.PPS_NOMENCLATURE_ID
                                  , aFAL_SCHEDULE_PLAN_ID         => iComplementarydata.FAL_SCHEDULE_PLAN_ID
                                  , aC_SCHEDULE_PLANNING          => iComplementarydata.C_SCHEDULE_PLANNING
                                  , aGCO_GOOD_ID                  => iFalLotProp.GCO_GOOD_ID
                                  , aDOC_RECORD_ID                => iFalLotProp.DOC_RECORD_ID
                                  , aSTM_STM_STOCK_ID             => iFalLotProp.STM_STM_STOCK_ID
                                  , aSTM_STM_LOCATION_ID          => iFalLotProp.STM_STM_LOCATION_ID
                                  , aLOT_TOLERANCE                => iFalLotProp.LOT_TOLERANCE
                                  , aLOT_SHORT_DESCR              => nvl(iFalLotProp.LOT_SHORT_DESCR
                                                                       , PCS.PC_FUNCTIONS.TranslateWord('Lot créé par Reprise de POF')
                                                                        )
                                  , aLOT_REJECT_PLAN_QTY          => iFalLotProp.LOT_REJECT_PLAN_QTY
                                  , aLOT_PLAN_VERSION             => iComplementarydata.CMA_PLAN_VERSION
                                  , aLOT_PLAN_NUMBER              => iComplementarydata.CMA_PLAN_NUMBER
                                  , aGCO_QUALITY_PRINCIPLE_ID     => iComplementarydata.GCO_QUALITY_PRINCIPLE_ID
                                  , aPPS_OPERATION_PROCEDURE_ID   => iComplementarydata.PPS_OPERATION_PROCEDURE_ID
                                  , aFAL_FAL_SCHEDULE_PLAN_ID     => iComplementarydata.FAL_FAL_SCHEDULE_PLAN_ID
                                  , aLOT_VERSION_ORIGIN_NUM       => iComplementarydata.NOM_VERSION
                                  , aLOT_PLAN_LEAD_TIME           => iFalLotProp.LOT_PLAN_LEAD_TIME
                                  , aLOT_ORT_UPDATE_DELAY         => iFalLotProp.LOT_ORT_UPDATE_DELAY
                                  , aDIC_FAMILY_ID                => iFalLotProp.DIC_FAMILY_ID
                                  , aC_PRIORITY                   => iFalLotProp.C_PRIORITY
                                  , aC_FAB_TYPE                   => iCFabType
                                   );
  end CreateBatch;

  /**
  * procedure GetComplementaryData
  * Description : Recherche de la donnée complémentaire
  *
  * @created ECA
  * @lastUpdate AGE 18.06.2012
  * @public
  * @param   iGCO_GOOD_ID : bien
  * @param   iDIC_FAB_CONDITION_ID : Condition de fabrication
  * @param   iFAL_SCHEDULE_PLAN_ID : Gamme opératoire
  * @param   ioComplementaryData : Donnée complémentaire
  * @param   iCFabType : type de fabrication ou sous-traitance
  * @param   iPacSupplierPartnerId : Fournisseur
  * @param   iGcoGcoGoodId : Service lié
  */
  procedure GetComplementaryData(
    iGCO_GOOD_ID          in     number
  , iDIC_FAB_CONDITION_ID in     FAL_LOT_PROP_TEMP.DIC_FAB_CONDITION_ID%type
  , iFAL_SCHEDULE_PLAN_ID in     FAL_LOT_PROP_TEMP.FAL_SCHEDULE_PLAN_ID%type
  , ioComplementaryData   in out TComplementaryData
  , iCFabType             in     varchar2 default FAL_BATCH_FUNCTIONS.btManufacturing
  , iPacSupplierPartnerId in     number default null
  , iGcoGcoGoodId         in     number default null
  )
  is
    ltGcoComplDataSubcontract GCO_COMPL_DATA_SUBCONTRACT%rowtype;
  begin
    -- Recherche de la données complémentaire de fabrication
    if icFabType = FAL_BATCH_FUNCTIONS.btManufacturing then
      begin
        select a.GCO_COMPL_DATA_MANUFACTURE_ID
             , nvl(iFAL_SCHEDULE_PLAN_ID, a.FAL_SCHEDULE_PLAN_ID)
             , a.PPS_NOMENCLATURE_ID
             , a.CMA_LOT_QUANTITY
             , a.CMA_MANUFACTURING_delay
             , a.CMA_PERCENT_TRASH
             , a.CMA_FIXED_QUANTITY_TRASH
             , a.CMA_QTY_REFERENCE_LOSS
             , a.PPS_OPERATION_PROCEDURE_ID
             , a.GCO_QUALITY_PRINCIPLE_ID
             , a.CMA_PLAN_NUMBER
             , a.CMA_PLAN_VERSION
             , 1
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
          into ioComplementaryData
          from GCO_COMPL_DATA_MANUFACTURE a
         where a.GCO_GOOD_ID = iGCO_GOOD_ID
           and DIC_FAB_CONDITION_ID = iDIC_FAB_CONDITION_ID;
      exception
        when no_data_found then
          begin
            select a.GCO_COMPL_DATA_MANUFACTURE_ID
                 , nvl(FAL_SCHEDULE_PLAN_ID, a.FAL_SCHEDULE_PLAN_ID)
                 , a.PPS_NOMENCLATURE_ID
                 , a.CMA_LOT_QUANTITY
                 , a.CMA_MANUFACTURING_delay
                 , a.CMA_PERCENT_TRASH
                 , a.CMA_FIXED_QUANTITY_TRASH
                 , a.CMA_QTY_REFERENCE_LOSS
                 , a.PPS_OPERATION_PROCEDURE_ID
                 , a.GCO_QUALITY_PRINCIPLE_ID
                 , a.CMA_PLAN_NUMBER
                 , a.CMA_PLAN_VERSION
                 , 1
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
              into ioComplementaryData
              from GCO_COMPL_DATA_MANUFACTURE a
             where a.GCO_GOOD_ID = iGCO_GOOD_ID
               and a.CMA_DEFAULT = 1;
          exception
            when no_data_found then
              null;
          end;
      end;

      -- Recherche du code planification
      begin
        if ioComplementaryData.FAL_SCHEDULE_PLAN_ID is not null then
          select C_SCHEDULE_PLANNING
            into ioComplementaryData.C_SCHEDULE_PLANNING
            from FAL_SCHEDULE_PLAN
           where FAL_SCHEDULE_PLAN_ID = ioComplementaryData.FAL_SCHEDULE_PLAN_ID;
        else
          ioComplementaryData.C_SCHEDULE_PLANNING  := 1;
        end if;
      exception
        --Par défaut selon produit
        when no_data_found then
          ioComplementaryData.C_SCHEDULE_PLANNING  := 1;
      end;
    -- Recherche de la donnée complémentaire de sous-traitance
    else
      ltGcoComplDataSubcontract                          :=
        GCO_LIB_COMPL_DATA.GetDefaultSubCComplData(iGoodId         => iGCO_GOOD_ID
                                                 , iSupplierId     => iPacSupplierPartnerId
                                                 , iLinkedGoodId   => iGcoGcoGoodId
                                                 , iDateRef        => sysdate
                                                  );
      ioComplementaryData.GCO_COMPL_DATA_MANUFACTURE_ID  := null;
      ioComplementaryData.PPS_NOMENCLATURE_ID            := ltGcoComplDataSubcontract.PPS_NOMENCLATURE_ID;
      ioComplementaryData.CMA_LOT_QUANTITY               := ltGcoComplDataSubcontract.CSU_LOT_QUANTITY;
      ioComplementaryData.CMA_MANUFACTURING_DELAY        := ltGcoComplDataSubcontract.CSU_SUBCONTRACTING_DELAY;
      ioComplementaryData.CMA_PERCENT_TRASH              := ltGcoComplDataSubcontract.CSU_PERCENT_TRASH;
      ioComplementaryData.CMA_FIXED_QUANTITY_TRASH       := ltGcoComplDataSubcontract.CSU_FIXED_QUANTITY_TRASH;
      ioComplementaryData.CMA_QTY_REFERENCE_LOSS         := ltGcoComplDataSubcontract.CSU_QTY_REFERENCE_TRASH;
      ioComplementaryData.PPS_OPERATION_PROCEDURE_ID     := ltGcoComplDataSubcontract.PPS_OPERATION_PROCEDURE_ID;
      ioComplementaryData.GCO_QUALITY_PRINCIPLE_ID       := ltGcoComplDataSubcontract.GCO_QUALITY_PRINCIPLE_ID;
      ioComplementaryData.CMA_PLAN_NUMBER                := ltGcoComplDataSubcontract.CSU_PLAN_NUMBER;
      ioComplementaryData.CMA_PLAN_VERSION               := ltGcoComplDataSubcontract.CSU_PLAN_VERSION;
      ioComplementaryData.C_SCHEDULE_PLANNING            := '2';   -- selon opérations
      ioComplementaryData.FAL_SCHEDULE_PLAN_ID           := FAL_LIB_SUBCONTRACTP.GetSchedulePlanId;   -- Gamme générique pour la SSTA
      ioComplementaryData.GCO_GCO_GOOD_ID                := ltGcoComplDataSubcontract.GCO_GCO_GOOD_ID;
      ioComplementaryData.CSU_AMOUNT                     := ltGcoComplDataSubcontract.CSU_AMOUNT;
      ioComplementaryData.CSU_WEIGH                      := ltGcoComplDataSubcontract.CSU_WEIGH;
      ioComplementaryData.CSU_WEIGH_MANDATORY            := ltGcoComplDataSubcontract.CSU_WEIGH_MANDATORY;
      ioComplementaryData.CSU_SUBCONTRACTING_DELAY       := nvl(ltGcoComplDataSubcontract.CSU_SUBCONTRACTING_DELAY, 0);
      ioComplementaryData.CSU_FIX_DELAY                  := nvl(ltGcoComplDataSubcontract.CSU_FIX_DELAY, 0);
      ioComplementaryData.CSU_LOT_QUANTITY               := nvl(ltGcoComplDataSubcontract.CSU_LOT_QUANTITY, 1);
      ioComplementaryData.C_DISCHARGE_COM                := ltGcoComplDataSubcontract.C_DISCHARGE_COM;
    end if;

    -- Recherche de la gamme et version de la nomenclature
    begin
      select b.FAL_SCHEDULE_PLAN_ID
           , b.NOM_VERSION
        into ioComplementaryData.FAL_FAL_SCHEDULE_PLAN_ID
           , ioComplementaryData.NOM_VERSION
        from GCO_COMPL_DATA_MANUFACTURE a
           , PPS_NOMENCLATURE b
       where a.GCO_GOOD_ID = iGCO_GOOD_ID
         and DIC_FAB_CONDITION_ID = iDIC_FAB_CONDITION_ID
         and a.PPS_NOMENCLATURE_ID = b.PPS_NOMENCLATURE_ID;
    exception
      when no_data_found then
        null;
    end;
  end GetComplementaryData;

  /****
  * procedure CreateOrder
  * Description : Création d'un ordre de fabrication
  *
  * @created ECA
  * @lastUpdate ASE 16.09.2013
  * @private
  * @param   iGCoGoodId : bien
  * @param   iFalJobProgramId : Programme
  * @param   iDocRecordId : Dossier
  * @param   ioFalOrderId : Ordre créé
  */
  procedure CreateOrder(iGcoGoodId in number, iFalJobProgramId in number, iDocRecordId in number, ioFalOrderId in out number)
  is
  begin
    ioFalOrderId  :=
                FAL_ORDER_FUNCTIONS.CreateManufactureOrder(aFAL_JOB_PROGRAM_ID   => iFalJobProgramId, aGCO_GOOD_ID => iGcoGoodId
                                                         , aDOC_RECORD_ID        => iDocRecordId);
  end CreateOrder;

  /**
  * procedure CountSelPropWithCompReplact
  * Description : Recheche de propositions sélectionnées pour reprise, et qui ont
  *               fait l'objet d'un remplacement de composants (l'utilisateur doit
  *               être averti)
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iLPT_ORACLE_SESSION : Session
  * @param   ioSelectedProp : Nbre de propositions sélectionnées
  * @param   ioSelectedWithReplact : Nbre de propositions sélectionnées avec remplacement
  */
  procedure CountSelPropWithCompReplact(iLPT_ORACLE_SESSION in varchar2, ioSelectedProp in out integer, ioSelectedWithReplact in out integer)
  is
  begin
    ioSelectedProp         := 0;
    ioSelectedWithReplact  := 0;

    for tplTempPropositions in (select   count(*) NBPROP
                                       , nvl(LOT_CPT_CHANGE, 0) LOT_CPT_CHANGE
                                    from FAL_LOT_PROP_TEMP
                                   where FAD_SELECT = 1
                                group by nvl(LOT_CPT_CHANGE, 0) ) loop
      ioSelectedProp  := ioSelectedProp + tplTempPropositions.NBPROP;

      if tplTempPropositions.LOT_CPT_CHANGE = 1 then
        ioSelectedWithReplact  := ioSelectedWithReplact + tplTempPropositions.NBPROP;
      end if;
    end loop;
  end CountSelPropWithCompReplact;

  /***
  * procedure GetRcoTitle
  * Description  : obtention du tire d'un dossier
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param  iDoc_Record_id : Dossier
  */
  function GetRcoTitle(iDOC_RECORD_ID in number)
    return varchar2
  is
    lvRcoTitle DOC_RECORD.RCO_TITLE%type;
  begin
    select RCO_TITLE
      into lvRcoTitle
      from DOC_RECORD
     where DOC_RECORD_ID = iDOC_RECORD_ID;

    return lvRcoTitle;
  exception
    when others then
      return null;
  end GetRcoTitle;

  /***
  * procedure GetCatWording
  * Description  : obtention de la description d'un categorie
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param  iGoodCat: catégorie de bien
  */
  function GetCatWording(iGoodCat in number)
    return varchar2
  is
    lvGoodCatWording GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
  begin
    select GCO_GOOD_CATEGORY_WORDING
      into lvGoodCatWording
      from GCO_GOOD_CATEGORY
     where GCO_GOOD_CATEGORY_ID = iGoodCat;

    return lvGoodCatWording;
  exception
    when others then
      return null;
  end GetCatWording;

  /***
  * procedure DeleteObsoleteReservedProp
  * Description  : Suppression des enregs de la table FAL_LOT_PROP_TEMP de session
  *                oracle inactive.
  * @created ECA
  * @lastUpdate
  * @private
  */
  procedure DeleteObsoleteReservedProp
  is
  begin
    -- Suppression des éventuelles propositions temporaires sans session oracle
    delete from FAL_LOT_PROP_TEMP
          where LPT_ORACLE_SESSION is null;

    -- Suppression des propositions temporaires de session oracle invalide
    for tplOracleSession in (select distinct LPT_ORACLE_SESSION
                                        from FAL_LOT_PROP_TEMP) loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.LPT_ORACLE_SESSION) = 0 then
        delete from FAL_LOT_PROP_TEMP
              where LPT_ORACLE_SESSION = tplOracleSession.LPT_ORACLE_SESSION;
      end if;
    end loop;
  end DeleteObsoleteReservedProp;

  /***
  * procedure CheckSelectedPropositions
  * Description  : Recherche si des propositions corerspondantes aux critères de
  *                sélection, sont déjà en cours de sélection par d'autres users.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iGCO_GOOD_ID : Bien
  * @param   iGOOD_CATEGORY_WORDING_FROM : Catégorie de bien de
  * @param   iGOOD_CATEGORY_WORDING_TO  : Catégorie de bien à
  * @param   iDIC_GOOD_FAMILY_FROM : Famille de bien de
  * @param   iDIC_GOOD_FAMILY_TO : Famille de bien à
  * @param   iDIC_ACCOUNTABLE_GROUP_FROM : Groupe de resp. de
  * @param   iDIC_ACCOUNTABLE_GROUP_TO : Groupe de resp. à
  * @param   iDIC_GOOD_LINE_FROM : Ligne de produits de
  * @param   iDIC_GOOD_LINE_TO : Ligne de produits à
  * @param   iDIC_GOOD_GROUP_FROM : Groupe de produits de
  * @param   iDIC_GOOD_GROUP_TO : Groupe de produits à
  * @param   iDIC_GOOD_MODEL_FROM : Groupe de produits de
  * @param   iDIC_GOOD_MODEL_TO : Groupe de produits à
  * @param   iDIC_LOT_PROP_FREE : Code traitement
  * @param   iC_PREFIX_PROP : Préfixe
  * @param   iLOT_PLAN_BEGIN_DTE_MIN : Date debut plan min
  * @param   iLOT_PLAN_BEGIN_DTE_MAX : Date debut plan max
  * @param   iLOT_PLAN_END_DTE_MIN : Date fin plan min
  * @param   iLOT_PLAN_END_DTE_MAX Date fin plan max
  * @param   iDOC_RECORD_FROM : Dossier de
  * @param   iDOC_RECORD_TO : Dossier à
  * @param   iSTM_STOCK_ID : Stock
  * @param   iLPT_ORACLE_SESSION : Session Oracle
  * @param   iCFabType : Genre fabrication / Sous-traitance d'achat
  * @param   ioErrorMsg : Message avertissement
  */
  function CheckSelectedPropositions(
    iGCO_GOOD_ID                in number default null
  , iGOOD_CATEGORY_WORDING_FROM in number default null
  , iGOOD_CATEGORY_WORDING_TO   in number default null
  , iDIC_GOOD_FAMILY_FROM       in varchar2 default null
  , iDIC_GOOD_FAMILY_TO         in varchar2 default null
  , iDIC_ACCOUNTABLE_GROUP_FROM in varchar2 default null
  , iDIC_ACCOUNTABLE_GROUP_TO   in varchar2 default null
  , iDIC_GOOD_LINE_FROM         in varchar2 default null
  , iDIC_GOOD_LINE_TO           in varchar2 default null
  , iDIC_GOOD_GROUP_FROM        in varchar2 default null
  , iDIC_GOOD_GROUP_TO          in varchar2 default null
  , iDIC_GOOD_MODEL_FROM        in varchar2 default null
  , iDIC_GOOD_MODEL_TO          in varchar2 default null
  , iDIC_LOT_PROP_FREE          in varchar2 default null
  , iC_PREFIX_PROP              in varchar2 default null
  , iLOT_PLAN_BEGIN_DTE_MIN     in date default null
  , iLOT_PLAN_BEGIN_DTE_MAX     in date default null
  , iLOT_PLAN_END_DTE_MIN       in date default null
  , iLOT_PLAN_END_DTE_MAX       in date default null
  , iDOC_RECORD_FROM            in number default null
  , iDOC_RECORD_TO              in number default null
  , iSTM_STOCK_ID               in number default null
  , iLPT_ORACLE_SESSION         in varchar2 default null
  , iCFabType                   in varchar2 default null
  )
    return integer
  is
    liNbProp           integer;
    lvRcoTitleFrom     DOC_RECORD.RCO_TITLE%type;
    lvRcoTitleTo       DOC_RECORD.RCO_TITLE%type;
    lvGoodCategoryFrom GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
    lvGoodCategoryTo   GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
  begin
    lvRcoTitleFrom      := GetRcoTitle(iDOC_RECORD_FROM);
    lvRcoTitleTo        := GetRcoTitle(iDOC_RECORD_TO);
    lvGoodCategoryFrom  := GetCatWording(iGOOD_CATEGORY_WORDING_FROM);
    lvGoodCategoryTo    := GetCatWording(iGOOD_CATEGORY_WORDING_TO);

    select count(*)
      into liNbProp
      from FAL_LOT_PROP_TEMP FLP
     where FLP.FAL_LOT_PROP_TEMP_ID > 0
       and FLP.LPT_ORACLE_SESSION is not null
       and FLP.LPT_ORACLE_SESSION <> iLPT_ORACLE_SESSION
       and (   iDIC_LOT_PROP_FREE is null
            or FLP.DIC_LOT_PROP_FREE_ID = iDIC_LOT_PROP_FREE)
       and (   iC_PREFIX_PROP is null
            or FLP.C_PREFIX_PROP = iC_PREFIX_PROP)
       and (   nvl(iSTM_STOCK_ID, 0) = 0
            or FLP.STM_STOCK_ID = iSTM_STOCK_ID)
       and (nvl(iCFabType, '0') = nvl(FLP.C_FAB_TYPE, '0') )
       and (   trunc(iLOT_PLAN_BEGIN_DTE_MIN) is null
            or trunc(FLP.LOT_PLAN_BEGIN_DTE) >= trunc(iLOT_PLAN_BEGIN_DTE_MIN) )
       and (   trunc(iLOT_PLAN_BEGIN_DTE_MAX) is null
            or trunc(FLP.LOT_PLAN_BEGIN_DTE) <= trunc(iLOT_PLAN_BEGIN_DTE_MAX) )
       and (   trunc(iLOT_PLAN_END_DTE_MIN) is null
            or trunc(FLP.LOT_PLAN_END_DTE) >= trunc(iLOT_PLAN_END_DTE_MIN) )
       and (   trunc(iLOT_PLAN_END_DTE_MAX) is null
            or trunc(FLP.LOT_PLAN_END_DTE) <= trunc(iLOT_PLAN_END_DTE_MAX) )
       and (    (    nvl(iGCO_GOOD_ID, 0) = 0
                 and exists(
                       select GOO.GCO_GOOD_ID
                         from GCO_GOOD GOO
                        where GOO.GCO_GOOD_ID = FLP.GCO_GOOD_ID
                          and (   nvl(iGOOD_CATEGORY_WORDING_FROM, 0) = 0
                               or (select GCO_GOOD_CATEGORY_WORDING
                                     from GCO_GOOD_CATEGORY
                                    where GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID) >= lvGoodCategoryFrom)
                          and (   nvl(iGOOD_CATEGORY_WORDING_TO, 0) = 0
                               or (select GCO_GOOD_CATEGORY_WORDING
                                     from GCO_GOOD_CATEGORY
                                    where GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID) <= lvGoodCategoryTo)
                          and (   iDIC_GOOD_FAMILY_FROM is null
                               or DIC_GOOD_FAMILY_ID >= iDIC_GOOD_FAMILY_FROM)
                          and (   iDIC_GOOD_FAMILY_TO is null
                               or DIC_GOOD_FAMILY_ID <= iDIC_GOOD_FAMILY_TO)
                          and (   iDIC_ACCOUNTABLE_GROUP_FROM is null
                               or DIC_ACCOUNTABLE_GROUP_ID >= iDIC_ACCOUNTABLE_GROUP_FROM)
                          and (   iDIC_ACCOUNTABLE_GROUP_TO is null
                               or DIC_ACCOUNTABLE_GROUP_ID <= iDIC_ACCOUNTABLE_GROUP_TO)
                          and (   iDIC_GOOD_LINE_FROM is null
                               or DIC_GOOD_LINE_ID >= iDIC_GOOD_LINE_FROM)
                          and (   iDIC_GOOD_LINE_TO is null
                               or DIC_GOOD_LINE_ID <= iDIC_GOOD_LINE_TO)
                          and (   iDIC_GOOD_GROUP_FROM is null
                               or DIC_GOOD_GROUP_ID >= iDIC_GOOD_GROUP_FROM)
                          and (   iDIC_GOOD_GROUP_TO is null
                               or DIC_GOOD_GROUP_ID <= iDIC_GOOD_GROUP_TO)
                          and (   iDIC_GOOD_MODEL_FROM is null
                               or DIC_GOOD_MODEL_ID >= iDIC_GOOD_MODEL_FROM)
                          and (   iDIC_GOOD_MODEL_TO is null
                               or DIC_GOOD_MODEL_ID <= iDIC_GOOD_MODEL_TO) )
                )
            or FLP.GCO_GOOD_ID = iGCO_GOOD_ID
           )
       and (   lvRcoTitleFrom is null
            or (    lvRcoTitleFrom is not null
                and FLP.DOC_RECORD_ID in(select DOC_RECORD_ID
                                           from DOC_RECORD
                                          where RCO_TITLE >= lvRcoTitleFrom) ) )
       and (   lvRcoTitleTo is null
            or (    lvRcoTitleTo is not null
                and FLP.DOC_RECORD_ID in(select DOC_RECORD_ID
                                           from DOC_RECORD
                                          where RCO_TITLE <= lvRcoTitleTo) ) );

    return liNbProp;
  exception
    when others then
      return 0;
  end CheckSelectedPropositions;

  /**
  * procedure ReserveManufacturingProp
  * Description : Réservation des propositions de fabrication pour reprise éventuelle
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iGCO_GOOD_ID : Bien
  * @param   iGOOD_CATEGORY_WORDING_FROM : Catégorie de bien de
  * @param   iGOOD_CATEGORY_WORDING_TO  : Catégorie de bien à
  * @param   iDIC_GOOD_FAMILY_FROM : Famille de bien de
  * @param   iDIC_GOOD_FAMILY_TO : Famille de bien à
  * @param   iDIC_ACCOUNTABLE_GROUP_FROM : Groupe de resp. de
  * @param   iDIC_ACCOUNTABLE_GROUP_TO : Groupe de resp. à
  * @param   iDIC_GOOD_LINE_FROM : Ligne de produits de
  * @param   iDIC_GOOD_LINE_TO : Ligne de produits à
  * @param   iDIC_GOOD_GROUP_FROM : Groupe de produits de
  * @param   iDIC_GOOD_GROUP_TO : Groupe de produits à
  * @param   iDIC_GOOD_MODEL_FROM : Groupe de produits de
  * @param   iDIC_GOOD_MODEL_TO : Groupe de produits à
  * @param   iDIC_LOT_PROP_FREE : Code traitement
  * @param   iC_PREFIX_PROP : Préfixe
  * @param   iLOT_PLAN_BEGIN_DTE_MIN : Date debut plan min
  * @param   iLOT_PLAN_BEGIN_DTE_MAX : Date debut plan max
  * @param   iLOT_PLAN_END_DTE_MIN : Date fin plan min
  * @param   iLOT_PLAN_END_DTE_MAX Date fin plan max
  * @param   iDOC_RECORD_FROM : Dossier de
  * @param   iDOC_RECORD_TO : Dossier à
  * @param   iSTM_STOCK_ID : Stock
  * @param   iLPT_ORACLE_SESSION : Session Oracle
  * @param   iCFabType : Genre fabrication / Sous-traitance d'achat
  */
  procedure ReserveManufacturingProp(
    iGCO_GOOD_ID                in number default null
  , iGOOD_CATEGORY_WORDING_FROM in number default null
  , iGOOD_CATEGORY_WORDING_TO   in number default null
  , iDIC_GOOD_FAMILY_FROM       in varchar2 default null
  , iDIC_GOOD_FAMILY_TO         in varchar2 default null
  , iDIC_ACCOUNTABLE_GROUP_FROM in varchar2 default null
  , iDIC_ACCOUNTABLE_GROUP_TO   in varchar2 default null
  , iDIC_GOOD_LINE_FROM         in varchar2 default null
  , iDIC_GOOD_LINE_TO           in varchar2 default null
  , iDIC_GOOD_GROUP_FROM        in varchar2 default null
  , iDIC_GOOD_GROUP_TO          in varchar2 default null
  , iDIC_GOOD_MODEL_FROM        in varchar2 default null
  , iDIC_GOOD_MODEL_TO          in varchar2 default null
  , iDIC_LOT_PROP_FREE          in varchar2 default null
  , iC_PREFIX_PROP              in varchar2 default null
  , iLOT_PLAN_BEGIN_DTE_MIN     in date default null
  , iLOT_PLAN_BEGIN_DTE_MAX     in date default null
  , iLOT_PLAN_END_DTE_MIN       in date default null
  , iLOT_PLAN_END_DTE_MAX       in date default null
  , iDOC_RECORD_FROM            in number default null
  , iDOC_RECORD_TO              in number default null
  , iSTM_STOCK_ID               in number default null
  , iLPT_ORACLE_SESSION         in varchar2 default null
  , iCFabType                   in varchar2 default null
  )
  is
    lvRcoTitleFrom     DOC_RECORD.RCO_TITLE%type;
    lvRcoTitleTo       DOC_RECORD.RCO_TITLE%type;
    lvGoodCategoryFrom GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
    lvGoodCategoryTo   GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
  begin
    lvRcoTitleFrom      := GetRcoTitle(iDOC_RECORD_FROM);
    lvRcoTitleTo        := GetRcoTitle(iDOC_RECORD_TO);
    lvGoodCategoryFrom  := GetCatWording(iGOOD_CATEGORY_WORDING_FROM);
    lvGoodCategoryTo    := GetCatWording(iGOOD_CATEGORY_WORDING_TO);
    -- Suppression des propositions réservées de session oracle obsolete
    DeleteObsoleteReservedProp;

    -- Insertion dans la table temp des propositions correspondant aux critères
    -- de sélection et qui ne sont pas déjà utilisées par d'autres users
    insert into FAL_LOT_PROP_TEMP
                (FAL_LOT_PROP_TEMP_ID
               , FAD_CHARACTERIZATION_VALUE_1
               , FAD_CHARACTERIZATION_VALUE_2
               , FAD_CHARACTERIZATION_VALUE_3
               , FAD_CHARACTERIZATION_VALUE_4
               , FAD_CHARACTERIZATION_VALUE_5
               , LOT_NUMBER
               , LOT_ASKED_QTY
               , LOT_REJECT_PLAN_QTY
               , LOT_TOTAL_QTY
               , LOT_PLAN_BEGIN_DTE
               , LOT_PLAN_END_DTE
               , LOT_PLAN_LEAD_TIME
               , LOT_TOLERANCE
               , LOT_SECOND_REF
               , LOT_PSHORT_DESCR
               , LOT_PROP_CHANGE
               , FAD_SELECT
               , LOT_SHORT_DESCR
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , C_SCHEDULE_PLANNING
               , DIC_ACCOUNTABLE_GROUP_ID
               , DIC_FAB_CONDITION_ID
               , DIC_FAMILY_ID
               , C_PRIORITY
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , FAL_PIC_ID
               , FAL_SCHEDULE_PLAN_ID
               , FAL_FAL_SCHEDULE_PLAN_ID
               , GCO_GOOD_ID
               , STM_STOCK_ID
               , STM_STM_STOCK_ID
               , DOC_RECORD_ID
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAL_SUPPLY_REQUEST_ID
               , C_PREFIX_PROP
               , GCO_GOOD_CATEGORY_ID
               , DIC_LOT_PROP_FREE_ID
               , LPT_ORACLE_SESSION
               , SESSION_POF_ID
               , LOT_CPT_CHANGE
               , C_FAB_TYPE
               , PAC_SUPPLIER_PARTNER_ID
                )
      select FLP.FAL_LOT_PROP_ID
           , FLP.FAD_CHARACTERIZATION_VALUE_1
           , FLP.FAD_CHARACTERIZATION_VALUE_2
           , FLP.FAD_CHARACTERIZATION_VALUE_3
           , FLP.FAD_CHARACTERIZATION_VALUE_4
           , FLP.FAD_CHARACTERIZATION_VALUE_5
           , FLP.LOT_NUMBER
           , FLP.LOT_ASKED_QTY
           , FLP.LOT_REJECT_PLAN_QTY
           , FLP.LOT_TOTAL_QTY
           , FLP.LOT_PLAN_BEGIN_DTE
           , FLP.LOT_PLAN_END_DTE
           , FLP.LOT_PLAN_LEAD_TIME
           , FLP.LOT_TOLERANCE
           , FLP.LOT_SECOND_REF
           , FLP.LOT_PSHORT_DESCR
           , FLP.LOT_PROP_CHANGE
           , FLP.FAD_SELECT
           , FLP.LOT_SHORT_DESCR
           , sysdate
           , FLP.A_DATEMOD
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , FLP.A_IDMOD
           , FLP.A_RECLEVEL
           , FLP.A_RECSTATUS
           , FLP.A_CONFIRM
           , FLP.C_SCHEDULE_PLANNING
           , FLP.DIC_ACCOUNTABLE_GROUP_ID
           , FLP.DIC_FAB_CONDITION_ID
           , FLP.DIC_FAMILY_ID
           , FLP.C_PRIORITY
           , FLP.STM_LOCATION_ID
           , FLP.STM_STM_LOCATION_ID
           , FLP.FAL_PIC_ID
           , FLP.FAL_SCHEDULE_PLAN_ID
           , FLP.FAL_FAL_SCHEDULE_PLAN_ID
           , FLP.GCO_GOOD_ID
           , FLP.STM_STOCK_ID
           , FLP.STM_STM_STOCK_ID
           , FLP.DOC_RECORD_ID
           , FLP.GCO_CHARACTERIZATION1_ID
           , FLP.GCO_CHARACTERIZATION2_ID
           , FLP.GCO_CHARACTERIZATION3_ID
           , FLP.GCO_CHARACTERIZATION4_ID
           , FLP.GCO_CHARACTERIZATION5_ID
           , FLP.FAL_SUPPLY_REQUEST_ID
           , FLP.C_PREFIX_PROP
           , FLP.GCO_GOOD_CATEGORY_ID
           , FLP.DIC_LOT_PROP_FREE_ID
           , iLPT_ORACLE_SESSION
           , null
           , FLP.LOT_CPT_CHANGE
           , nvl(FLP.C_FAB_TYPE, nvl(iCFabType, '0') )
           , null
        from FAL_LOT_PROP FLP
           , FAL_LOT_PROP_TEMP FLPT
       where FLP.FAL_LOT_PROP_ID = FLPT.FAL_LOT_PROP_TEMP_ID(+)
         and FLPT.FAL_LOT_PROP_TEMP_ID is null
         and (   iDIC_LOT_PROP_FREE is null
              or FLP.DIC_LOT_PROP_FREE_ID = iDIC_LOT_PROP_FREE)
         and (   iC_PREFIX_PROP is null
              or FLP.C_PREFIX_PROP = iC_PREFIX_PROP)
         and (   nvl(iSTM_STOCK_ID, 0) = 0
              or FLP.STM_STOCK_ID = iSTM_STOCK_ID)
         and (nvl(iCFabType, '0') = nvl(FLP.C_FAB_TYPE, '0') )
         and (   trunc(iLOT_PLAN_BEGIN_DTE_MIN) is null
              or trunc(FLP.LOT_PLAN_BEGIN_DTE) >= trunc(iLOT_PLAN_BEGIN_DTE_MIN) )
         and (   trunc(iLOT_PLAN_BEGIN_DTE_MAX) is null
              or trunc(FLP.LOT_PLAN_BEGIN_DTE) <= trunc(iLOT_PLAN_BEGIN_DTE_MAX) )
         and (   trunc(iLOT_PLAN_END_DTE_MIN) is null
              or trunc(FLP.LOT_PLAN_END_DTE) >= trunc(iLOT_PLAN_END_DTE_MIN) )
         and (   trunc(iLOT_PLAN_END_DTE_MAX) is null
              or trunc(FLP.LOT_PLAN_END_DTE) <= trunc(iLOT_PLAN_END_DTE_MAX) )
         and (   lvRcoTitleFrom is null
              or (    lvRcoTitleFrom is not null
                  and FLP.DOC_RECORD_ID in(select DOC_RECORD_ID
                                             from DOC_RECORD
                                            where RCO_TITLE >= lvRcoTitleFrom) ) )
         and (   lvRcoTitleTo is null
              or (    lvRcoTitleTo is not null
                  and FLP.DOC_RECORD_ID in(select DOC_RECORD_ID
                                             from DOC_RECORD
                                            where RCO_TITLE <= lvRcoTitleTo) ) )
         and (    (    nvl(iGCO_GOOD_ID, 0) = 0
                   and exists(
                         select GOO.GCO_GOOD_ID
                           from GCO_GOOD GOO
                          where GOO.GCO_GOOD_ID = FLP.GCO_GOOD_ID
                            and (   nvl(iGOOD_CATEGORY_WORDING_FROM, 0) = 0
                                 or (select GCO_GOOD_CATEGORY_WORDING
                                       from GCO_GOOD_CATEGORY
                                      where GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID) >= lvGoodCategoryFrom)
                            and (   nvl(iGOOD_CATEGORY_WORDING_TO, 0) = 0
                                 or (select GCO_GOOD_CATEGORY_WORDING
                                       from GCO_GOOD_CATEGORY
                                      where GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID) <= lvGoodCategoryTo)
                            and (   iDIC_GOOD_FAMILY_FROM is null
                                 or DIC_GOOD_FAMILY_ID >= iDIC_GOOD_FAMILY_FROM)
                            and (   iDIC_GOOD_FAMILY_TO is null
                                 or DIC_GOOD_FAMILY_ID <= iDIC_GOOD_FAMILY_TO)
                            and (   iDIC_ACCOUNTABLE_GROUP_FROM is null
                                 or DIC_ACCOUNTABLE_GROUP_ID >= iDIC_ACCOUNTABLE_GROUP_FROM)
                            and (   iDIC_ACCOUNTABLE_GROUP_TO is null
                                 or DIC_ACCOUNTABLE_GROUP_ID <= iDIC_ACCOUNTABLE_GROUP_TO)
                            and (   iDIC_GOOD_LINE_FROM is null
                                 or DIC_GOOD_LINE_ID >= iDIC_GOOD_LINE_FROM)
                            and (   iDIC_GOOD_LINE_TO is null
                                 or DIC_GOOD_LINE_ID <= iDIC_GOOD_LINE_TO)
                            and (   iDIC_GOOD_GROUP_FROM is null
                                 or DIC_GOOD_GROUP_ID >= iDIC_GOOD_GROUP_FROM)
                            and (   iDIC_GOOD_GROUP_TO is null
                                 or DIC_GOOD_GROUP_ID <= iDIC_GOOD_GROUP_TO)
                            and (   iDIC_GOOD_MODEL_FROM is null
                                 or DIC_GOOD_MODEL_ID >= iDIC_GOOD_MODEL_FROM)
                            and (   iDIC_GOOD_MODEL_TO is null
                                 or DIC_GOOD_MODEL_ID <= iDIC_GOOD_MODEL_TO) )
                  )
              or FLP.GCO_GOOD_ID = iGCO_GOOD_ID
             );
  end ReserveManufacturingProp;

  /**
  * procedure ReleaseManufacturingProp
  * Description : Libérations des propositions de fabrication réservées pour une
  *               reprise
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iLPT_ORACLE_SESSION : Session
  */
  procedure ReleaseManufacturingProp(iLPT_ORACLE_SESSION in varchar2)
  is
  begin
    delete from FAL_LOT_PROP_TEMP
          where LPT_ORACLE_SESSION = iLPT_ORACLE_SESSION;
  end ReleaseManufacturingProp;

  /**
  * procedure ReadjustCoupledQty
  * Description :
  *      S'il y a fusion avec produit couplé, il est possible que la création des couplés du lot à partir de la quantité totale ne corresponde pas exactement
  *      à la somme de chaque couplé des propositions fusionnées (problème d'arrondi en fonction des Qté ref et Qté couplé). Il faut alors réajuster les quantités
  *      sur le lot pour pouvoir reporter corectement les attributions et respecter le résultat du calcul des besoins.
  * @created CLG
  * @lastUpdate
  * @public
  * @param   iListOfPropId : liste des propositions fusionnées
  * @param   iBatchId      : Id du lot nouvellement créé
  */
  procedure ReadjustCoupledQty(iListOfPropId varchar2, iBatchId FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    for tplCoupled in (select   GCO_GOOD_ID
                              , sum(FAN_BALANCE_QTY) COUPLED_QTY
                           from FAL_NETWORK_SUPPLY
                          where instr(',' || iListOfPropID || ',', ',' || FAL_LOT_PROP_ID || ',') <> 0
                       group by GCO_GOOD_ID) loop
      update FAL_LOT_DETAIL
         set FAD_QTY = tplCoupled.COUPLED_QTY
           , FAD_BALANCE_QTY = tplCoupled.COUPLED_QTY
           , GCG_TOTAL_QTY = tplCoupled.COUPLED_QTY
       where FAL_LOT_ID = iBatchId
         and GCO_GOOD_ID = tplCoupled.GCO_GOOD_ID
         and C_LOT_DETAIL in('2', '3');
    end loop;
  end;

  /**
  * procedure CreateBatchDetail
  * Description : Création des détails lot repris de propositions
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   iProp         : élements de la table de travail des propositions
  * @param   iFalLotId     : ID du nouvel OF
  * @param   iListOfPropId : liste des propositions fusionnées
  */
  procedure CreateBatchDetail(iProp in TPropositions, iFalLotId number, iListOfPropId varchar2)
  is
    type TSupply is record(
      FAN_BALANCE_QTY FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type
    , FAN_CHAR_VALUE1 FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
    , FAN_CHAR_VALUE2 FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE2%type
    , FAN_CHAR_VALUE3 FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE3%type
    , FAN_CHAR_VALUE4 FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE4%type
    , FAN_CHAR_VALUE5 FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE5%type
    );

    type TTabSupply is table of TSupply
      index by binary_integer;

    cursor crCharact
    is
      select   GCO_CHARACTERIZATION_ID
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = iProp.GCO_GOOD_ID
      order by GCO_CHARACTERIZATION_ID;

    type TTabMergedProp is table of FAL_LOT_PROP_TEMP%rowtype
      index by binary_integer;

    lTabSupply TTabSupply;
    N          integer;
    lnIdChar1  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIdChar2  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIdChar3  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIdChar4  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIdChar5  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    /* Si le produit est caractérisé morpho, il est possible qu'il y ait plusieurs propositions de créées avec différentes valeurs de caractérisations
       pour répondre à des besoins différents (position de document avec du Rouge, Bleu, ...). S'il y a fusion, Il faut reprendre ces caractérisations
       depuis les réseaux pour créer les détails lot sur le nouvel OF et pouvoir reprendre ensuite les attributions */
    execute immediate 'select FAN_BALANCE_QTY
                           , FAN_CHAR_VALUE1
                           , FAN_CHAR_VALUE2
                           , FAN_CHAR_VALUE3
                           , FAN_CHAR_VALUE4
                           , FAN_CHAR_VALUE5
                        from FAL_NETWORK_SUPPLY
                       where (FAL_LOT_PROP_ID in(' ||
                      nvl(iListOfPropID, iProp.FAL_LOT_PROP_TEMP_ID) ||
                      '))
                         and (   FAN_CHAR_VALUE1 is not null
                              or FAN_CHAR_VALUE2 is not null
                              or FAN_CHAR_VALUE3 is not null
                              or FAN_CHAR_VALUE4 is not null
                              or FAN_CHAR_VALUE5 is not null
                             )'
    bulk collect into lTabSupply;

    if lTabSupply.count > 0 then
      for i in lTabSupply.first .. lTabSupply.last loop
        N  := 0;

        for tplCharact in crCharact loop
          N  := N + 1;

          if N = 1 then
            lnIdChar1  := tplCharact.GCO_CHARACTERIZATION_ID;
          end if;

          if N = 2 then
            lnIdChar2  := tplCharact.GCO_CHARACTERIZATION_ID;
          end if;

          if N = 3 then
            lnIdChar3  := tplCharact.GCO_CHARACTERIZATION_ID;
          end if;

          if N = 4 then
            lnIdChar4  := tplCharact.GCO_CHARACTERIZATION_ID;
          end if;

          if N = 5 then
            lnIdChar5  := tplCharact.GCO_CHARACTERIZATION_ID;
          end if;
        end loop;

        insert into FAL_LOT_DETAIL
                    (FAL_LOT_DETAIL_ID
                   , FAL_LOT_ID
                   , FAD_LOT_REFCOMPL
                   , GCO_GOOD_ID
                   , FAD_QTY
                   , FAD_BALANCE_QTY
                   , GCG_TOTAL_QTY
                   , GCG_INCLUDE_GOOD
                   , FAD_RECEPT_SELECT
                   , FAD_RECEPT_QTY
                   , FAD_CANCEL_QTY
                   , FAD_RECEPT_INPROGRESS_QTY
                   , C_LOT_DETAIL
                   , GCO_CHARACTERIZATION_ID
                   , GCO_GCO_CHARACTERIZATION_ID
                   , GCO2_GCO_CHARACTERIZATION_ID
                   , GCO3_GCO_CHARACTERIZATION_ID
                   , GCO4_GCO_CHARACTERIZATION_ID
                   , FAD_CHARACTERIZATION_VALUE_1
                   , FAD_CHARACTERIZATION_VALUE_2
                   , FAD_CHARACTERIZATION_VALUE_3
                   , FAD_CHARACTERIZATION_VALUE_4
                   , FAD_CHARACTERIZATION_VALUE_5
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId   -- FAL_LOT_DETAIL_ID
                   , iFalLotId   -- FAL_LOT_ID
                   , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('FAL_LOT', 'LOT_REFCOMPL', iFalLotId)   -- FAD_LOT_REFCOMPL
                   , iProp.GCO_GOOD_ID   -- GCO_GOOD_ID
                   , lTabSupply(i).FAN_BALANCE_QTY
                   , lTabSupply(i).FAN_BALANCE_QTY
                   , 0   -- GCG_TOTAL_QTY
                   , 1   -- GCG_INCLUDE_GOOD
                   , 0   -- FAD_RECEPT_SELECT
                   , 0   -- FAD_RECEPT_QTY
                   , 0   -- FAD_CANCEL_QTY
                   , 0   -- FAD_RECEPT_INPROGRESS_QTY
                   , '1'   -- C_LOT_DETAIL = Caractérisé
                   , lnIdChar1
                   , lnIdChar2
                   , lnIdChar3
                   , lnIdChar4
                   , lnIdChar5
                   , lTabSupply(i).FAN_CHAR_VALUE1
                   , lTabSupply(i).FAN_CHAR_VALUE2
                   , lTabSupply(i).FAN_CHAR_VALUE3
                   , lTabSupply(i).FAN_CHAR_VALUE4
                   , lTabSupply(i).FAN_CHAR_VALUE5
                   , sysdate   -- A_DATECRE
                   , PCS.PC_INIT_SESSION.GetUserIni   -- A_IDCRE
                    );
      end loop;
    end if;
  end;

  /**
  * fonction UpdateOperation
  * Description : Mise à jour de
  *
  * @created CLG
  * @lastUpdate
  * @param   iPropId  : Id de la proposition reprise
  * @param   iBatchId : Id du nouvel OF
  */
  procedure UpdateOperation(
    iOpeId          FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iOrtPriority    FAL_TASK_LINK.TAL_ORT_PRIORITY%type
  , iFactoryFloorId FAL_TASK_LINK.FAL_FACTORY_FLOOR_ID%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, iOpeId, null, 'FAL_SCHEDULE_STEP_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_ORT_PRIORITY', iOrtPriority);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'FAL_FACTORY_FLOOR_ID', iFactoryFloorId);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateOperation;

  /**
  * fonction CheckOrtemsChangements
  * Description : Report sur les opérations de l'OF des modifications effectuées sur les opérations de la proposition par le planning Ortems
  *
  * @created CLG
  * @lastUpdate
  * @param   iPropId  : Id de la proposition reprise
  * @param   iBatchId : Id du nouvel OF
  */
  procedure CheckOrtemsChangements(iPropId FAL_LOT_PROP.FAL_LOT_PROP_ID%type, iBatchId FAL_LOT.FAL_LOT_ID%type)
  is
    lnBatchOpeId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    /* Chaque opération de proposition qui ont une priorité Ortems a été modifié dans le planning Ortems et est dans la période figée */
    for tplPropOp in (select TAL_ORT_PRIORITY
                           , FAL_FACTORY_FLOOR_ID
                           , TAL_SEQ_ORIGIN
                           , FAL_LIB_FACTORY_FLOOR.GetIsle(FAL_FACTORY_FLOOR_ID) FLOOR_ISLE_ID   -- îlot
                        from FAL_TASK_LINK_PROP PROP
                       where FAL_LOT_PROP_ID = iPropId
                         and nvl(TAL_ORT_PRIORITY, 0) > 0) loop
      /* Recherche une opération équivalente sur le nouvel OF (même séquence origine et même îlot, sinon la gamme a dû être modifiée, on ne fait pas les modifications) */
      select max(FAL_SCHEDULE_STEP_ID)
        into lnBatchOpeId
        from FAL_TASK_LINK
       where FAL_LOT_ID = iBatchId
         and TAL_SEQ_ORIGIN = tplPropOp.TAL_SEQ_ORIGIN
         and FAL_LIB_FACTORY_FLOOR.GetIsle(FAL_FACTORY_FLOOR_ID) = tplPropOp.FLOOR_ISLE_ID;

      if lnBatchOpeId is not null then
        UpdateOperation(lnBatchOpeId, tplPropOp.TAL_ORT_PRIORITY, tplPropOp.FAL_FACTORY_FLOOR_ID);
      end if;
    end loop;
  end CheckOrtemsChangements;

  /**
  * fonction CreateBatchFromProp
  * Description : Création d'un of depuis une proposition ou des propositions
  *               fusionnées
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   oProposition : Element de la table de travail des propositions
  * @param   iCGenerateProgramMode : Mode de génération des programmes
  * @param   iCGenerateLotMode : Mode de génération des lots
  * @param   iListOfPropID : Liste des propositions fusionnées
  * @param   iCFabType : Type de fabrication 0(fabrication) ou 4(sous-traitance)
  * @param   icGeneratePositionMode : Mode de génération des positions liées (sous-traitance)
  * @param   iGcoGcoGoodId : service lié
  */
  function CreateBatchFromProp(
    oProposition           in TPropositions
  , iCGenerateProgramMode  in varchar2 default cgpOneProgByProp
  , iCGenerateLotMode      in varchar2 default cglOneBatchByProp
  , iListOfPropID          in varchar2 default null
  , iCFabType              in varchar2 default FAL_BATCH_FUNCTIONS.btManufacturing
  , icGeneratePositionMode in varchar2 default null
  , iGcoGcoGoodId          in number default null
  )
    return number
  is
    type TTabMergedProp is table of FAL_LOT_PROP_TEMP%rowtype
      index by binary_integer;

    TabMergedProp       TTabMergedProp;
    lnFalLotId          number;
    ltComplementaryData TcomplementaryData;
    liOpGenContext      integer;
    lvProcName          varchar2(4000);
  begin
    -- Récupération des données complémentaires fabrication/sous-traitance
    GetComplementaryData(oProposition.GCO_GOOD_ID
                       , oProposition.DIC_FAB_CONDITION_ID
                       , oProposition.FAL_SCHEDULE_PLAN_ID
                       , ltComplementaryData
                       , icFabType
                       , oProposition.PAC_SUPPLIER_PARTNER_ID
                       , iGcoGcoGoodId
                        );
    -- Génération du lot de fabrication
    CreateBatch(oProposition, ltComplementaryData, lnFalLotId, iCFabType);

    -- Gestion des produits couplés
    if     cfgFalCoupledGood
       and icFabType <> FAL_BATCH_FUNCTIONS.btSubcontract
       and FAL_COUPLED_GOOD.ExistsCoupledForDataManuf(ltComplementaryData.GCO_COMPL_DATA_MANUFACTURE_ID) then
      FAL_COUPLED_GOOD.Generate_Detail_Lot(lnFalLotId, ltComplementaryData.GCO_COMPL_DATA_MANUFACTURE_ID, oProposition.LOT_ASKED_QTY);

      /* S'il y a fusion avec produit couplé, il est possible que la création des couplés du lot à partir de la quantité totale ne corresponde pas exactement
         à la somme de chaque couplé des propositions fusionnées (problème d'arrondi en fonction des Qté ref et Qté couplé). Il faut alors réajusté les quantités
         sur le lot pour pouvoir reporter corectement les attributions et respecter le résultat du calcul des besoins */
      if iListOfPropID is not null then
        ReadjustCoupledQty(iListOfPropID, lnFalLotId);
      end if;
    else
      -- Gestion des caractérisations
      CreateBatchDetail(oProposition, lnFalLotId, iListOfPropID);
    end if;

    -- Insertion de l'historique du lot
    FAL_BATCH_FUNCTIONS.CreateBatchHistory(aFAL_LOT_ID => lnFalLotId, aC_EVEN_TYPE => '18');

    -- Génération des opérations
    -- Contexte de génération
    if iCFabType = FAL_BATCH_FUNCTIONS.btSubcontract then
      liOpGenContext  := Fal_Task_Generator.ctxtSubcontracting;
    else
      liOpGenContext  := Fal_Task_Generator.ctxtBatchCreation;
    end if;

    if (nvl(ltComplementaryData.FAL_SCHEDULE_PLAN_ID, 0) <> 0) then
      FAL_TASK_GENERATOR.Call_Task_Generator(iFAL_SCHEDULE_PLAN_ID   => ltComplementaryData.FAL_SCHEDULE_PLAN_ID
                                           , iFAL_LOT_ID             => lnFalLotId
                                           , iLOT_TOTAL_QTY          => oProposition.LOT_TOTAL_QTY
                                           , iC_SCHEDULE_PLANNING    => ltComplementaryData.C_SCHEDULE_PLANNING
                                           , iContexte               => liOpGenContext
                                           , iPacSupplierPartnerId   => oProposition.PAC_SUPPLIER_PARTNER_ID
                                           , iGcoGcoGoodId           => ltComplementaryData.GCO_GCO_GOOD_ID
                                           , iScsAmount              => ltComplementaryData.CSU_AMOUNT
                                           , iScsQtyRefAmount        => 1
                                           , iScsDivisorAmount       => 0
                                           , iScsWeigh               => ltComplementaryData.CSU_WEIGH
                                           , iScsWeighMandatory      => ltComplementaryData.CSU_WEIGH_MANDATORY
                                           , iScsPlanRate            => ltComplementaryData.CSU_SUBCONTRACTING_DELAY
                                           , iScsPlanProp            => (case
                                                                           when nvl(ltComplementaryData.CSU_FIX_DELAY, 0) = 0 then 1
                                                                           else 0
                                                                         end)
                                           , iScsQtyRefWork          => ltComplementaryData.CSU_LOT_QUANTITY
                                            );

      /* Si des changements sur les propositions ont été effectuées dans le planning Ortems, on les reprend */
      if cOrtems then
        CheckOrtemsChangements(iPropId => oProposition.FAL_LOT_PROP_TEMP_ID, iBatchId => lnFalLotId);
      end if;
    end if;

    /* Génération ou reprise des composants. Si icGeneratePositionMode n'est pas null, l'appel vient de la reprise des POA (contexte sous-traitance)
       Si pas de fusion, conservation du remplacement et modifs manuelles possible */
    if    (    icGeneratePositionMode is null
           and (   iCGenerateLotMode = cglOneBatchByProp
                or iCGenerateProgramMode = cgpOneProgByProp
                or iCGenerateProgramMode = cgpExistingProgOrderByBatch)
          )
       or (    icGeneratePositionMode is not null
           and icGeneratePositionMode = FAL_PRC_RETRIEVE_SUBCP_PROP.cgpOnePosByProp) then
      CreateComponent(oProposition.FAL_LOT_PROP_TEMP_ID
                    , oProposition.FAL_LOT_PROP_TEMP_ID   -- Liste des ID des Pofs traités
                    , (oProposition.LOT_CPT_CHANGE = 1)   -- Il faut recopier ou non les composants de la proposition
                    , lnFalLotId
                    , oProposition.LOT_PLAN_END_DTE
                    , ltComplementaryData.C_DISCHARGE_COM
                     );
    else
      /* Si fusion, re-génération obligatoire */
      CreateComponent(null, iListOfPropID, false, lnFalLotId, oProposition.LOT_PLAN_END_DTE, ltComplementaryData.C_DISCHARGE_COM);
    end if;

    -- Planification de base
    if cfgFalInitialPlanification then
      FAL_BATCH_FUNCTIONS.DoBasisLotPlanification(lnFalLotId);
    end if;

    -- Mise à jour de l'ordre
    FAL_ORDER_FUNCTIONS.UpdateOrder(aFAL_ORDER_ID => oProposition.FAL_ORDER_ID);
    -- Mise à jour du programme
    FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(aFalJobProgramId => oProposition.FAL_JOB_PROGRAM_ID);
    -- Mise à jour réseau Produit Terminé
    FAL_NETWORK.MiseAJourReseaux(lnFalLotId, FAL_NETWORK.ncCreationLot, '');

    /* Sélection de la proposition (ou des prop. fusionnées  à l'origine du lot) pour mise à jour réseaux puis suppressions de ces propositions */
    execute immediate ' select * from FAL_LOT_PROP_TEMP where FAL_LOT_PROP_TEMP_ID in(' || nvl(iListOfPropID, oProposition.FAL_LOT_PROP_TEMP_ID) || ')'
    bulk collect into TabMergedProp;

    if TabMergedProp.count > 0 then
      for i in TabMergedProp.first .. TabMergedProp.last loop
        -- Mise à jour réseaux approvisionnements
        MajPDTNetwork(TabMergedProp(i).FAL_LOT_PROP_TEMP_ID, lnFalLotId, TabMergedProp(i).LOT_ASKED_QTY);
        -- Report des attribtions des composants de la proposition vers l'ordre de fabrication
        FAL_PRC_REPORT_ATTRIB.MoveCptAllocOnBatch(TabMergedProp(i).FAL_LOT_PROP_TEMP_ID, lnFalLotId);
        -- Suppression de la proposition traitée
        FAL_PRC_FAL_LOT_PROP.DeleteOneFABProposition(TabMergedProp(i).FAL_LOT_PROP_TEMP_ID
                                                   , FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                                   , FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                                   , FAL_PRC_FAL_PROP_COMMON.UPDATE_REQUEST_COMMANDEE
                                                    );

        -- Suppression de la proposition temporaire
        delete from FAL_LOT_PROP_TEMP
              where FAL_LOT_PROP_TEMP_ID = TabMergedProp(i).FAL_LOT_PROP_TEMP_ID;
      end loop;
    end if;

    FAL_NETWORK.MiseAJourReseaux(lnFalLotId, FAL_NETWORK.ncModificationLot, '');
    -- Exécution d'une procédure indiv en fin de création
    lvProcName  := PCS.PC_CONFIG.GetConfig('FAL_PROC_ON_END_CREATE_BATCH');

    if lvProcName is not null then
      execute immediate 'begin ' || lvProcName || '(:FAL_LOT_ID); ' || 'end;'
                  using in lnFalLotId;
    end if;

    return lnFalLotId;
  end CreateBatchFromProp;

  /**
  * procedure GenerateJobProgram
  * Description : procedure de génération des programmes de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iCGenerateProgramMode : Mode de génération des programmes
  * @param   iFalJobProgramId : Programme par défaut
  */
  procedure GenerateJobProgram(iCGenerateProgramMode in varchar2 default 1, iFalJobProgramId in number default null)
  is
    lvJopShortDescr   varchar2(50);
    lnFalJobProgramId number;
    lnDocRecordId     number;
  begin
    if oTabSelectedProp.count > 0 then
      -- Si un programme par proposition ou insertion dans un programme existant
      if    iCGenerateProgramMode = cgpOneProgByProp
         or iCGenerateProgramMode = cgpExistingProg
         or iCGenerateProgramMode = cgpExistingProgNewOrder
         or iCGenerateProgramMode = cgpExistingProgOrderByBatch then
        for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
          -- Création systématique du programme
          if iCGenerateProgramMode = cgpOneProgByProp then
            lnFalJobProgramId  :=
              FAL_PROGRAM_FUNCTIONS.CreateManufactureProgram(aJopShortDescr   => 'POF ' ||
                                                                                 FAL_TOOLS.GetRCO_TITLE(oTabSelectedProp(i).DOC_RECORD_ID) ||
                                                                                 ' ' ||
                                                                                 sysdate
                                                           , aDocRecordId     => oTabSelectedProp(i).DOC_RECORD_ID
                                                            );
          -- ou utilisation du paramètre
          else
            lnFalJobProgramId  := iFalJobProgramId;
          end if;

          -- Mise à jour de la proposition avec son futur programme
          oTabSelectedProp(i).FAL_JOB_PROGRAM_ID  := lnFalJobProgramId;
        end loop;
      -- Si création de programmes regroupés par groupe de produits, de responsables, ou dossier
      elsif    iCGenerateProgramMode = cgpGroupByDicGoodGroup
            or iCGenerateProgramMode = cgpGroupByDicAccountable
            or iCGenerateProgramMode = cgpGroupBydocRecord then
        -- Pour chaque groupe
        for tplGroupedPrograms in (select distinct GROUPFIELD
                                              from table(GetPropositionsTable)
                                          order by GROUPFIELD) loop
          -- Description du programme
          if    iCGenerateProgramMode = cgpGroupByDicGoodGroup
             or iCGenerateProgramMode = cgpGroupByDicAccountable then
            lvJopShortDescr  := 'POF ' || tplGroupedPrograms.GROUPFIELD || ' ' || sysdate;
            lnDocRecordId    := null;
          else
            lvJopShortDescr  := 'POF ' || FAL_TOOLS.GetRCO_TITLE(tplGroupedPrograms.GROUPFIELD) || ' ' || sysdate;
            lnDocRecordId    := tplGroupedPrograms.GROUPFIELD;
          end if;

          -- Création du programme
          lnFalJobProgramId  := FAL_PROGRAM_FUNCTIONS.CreateManufactureProgram(aJopShortDescr => lvJopShortDescr, aDocRecordId => lnDocRecordId);

          -- Mise à jour de la proposition son futur programme d'appartenance
          for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
            if     oTabSelectedProp(i).FAL_JOB_PROGRAM_ID is null
               and (    (oTabSelectedProp(i).GROUPFIELD = tplGroupedPrograms.GROUPFIELD)
                    or (    oTabSelectedProp(i).GROUPFIELD is null
                        and tplGroupedPrograms.GROUPFIELD is null)
                   ) then
              -- Mise à jour de la proposition avec son futur programme
              oTabSelectedProp(i).FAL_JOB_PROGRAM_ID  := lnFalJobProgramId;
            end if;
          end loop;
        end loop;
      end if;
    end if;
  end GenerateJobProgram;

  /**
  * procedure GenerateOrder
  * Description : procedure de génération des ordres de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iCGenerateProgramMode : Mode de génération des programmes
  * @param   iCGenerateLotMode : Mode de génération des lots
  */
  procedure GenerateOrder(iCGenerateProgramMode in varchar2 default 1, iCGenerateLotMode in varchar2 default 1)
  is
    lnFalOrderId  number;
    lnDocRecordId number;
  begin
    if oTabSelectedProp.count > 0 then
      -- Si un programme par proposition ( Donc un ordre )
      -- ou insertion dans un programme existant avec 1 lot par ordre
      -- alors création systématique du programme
      if    iCGenerateProgramMode = cgpOneProgByProp
         or iCGenerateProgramMode = cgpExistingProgOrderByBatch then
        for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
          -- création d'un nouvel ordre de fabrication
          CreateOrder(oTabSelectedProp(i).GCO_GOOD_ID, oTabSelectedProp(i).FAL_JOB_PROGRAM_ID, oTabSelectedProp(i).DOC_RECORD_ID, lnFalOrderId);
          -- Mise à jour de la proposition
          oTabSelectedProp(i).FAL_ORDER_ID  := lnFalOrderId;
        end loop;
      -- Si Insertion dans programme existant, recherche d'un ordre correspondant
      -- sinon création
      elsif iCGenerateProgramMode = cgpExistingProg then
        for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
          -- Recherche d'un ordre existant dans le programme
          lnFalOrderId                      := FindFalOrder(oTabSelectedProp(i).GCO_GOOD_ID, oTabSelectedProp(i).FAL_JOB_PROGRAM_ID);

          -- Sinon création d'un nouvel ordre de fabrication
          if lnFalOrderId is null then
            -- Création d'un nouvel ordre de fabrication
            CreateOrder(oTabSelectedProp(i).GCO_GOOD_ID, oTabSelectedProp(i).FAL_JOB_PROGRAM_ID, oTabSelectedProp(i).DOC_RECORD_ID, lnFalOrderId);
          end if;

          -- Mise à jour de la proposition
          oTabSelectedProp(i).FAL_ORDER_ID  := lnFalOrderId;
        end loop;
      -- Insertion dans programme existant avec création de nouveaux ordres par produits
      -- ou Regroupement pas Dossier, responsable, ou groupe de produit
      elsif    iCGenerateProgramMode = cgpExistingProgNewOrder
            or iCGenerateProgramMode = cgpGroupByDicGoodGroup
            or iCGenerateProgramMode = cgpGroupByDicAccountable
            or iCGenerateProgramMode = cgpGroupBydocRecord then
        -- Pour chaque groupe
        for tplGroupedPrograms in (select distinct FAL_JOB_PROGRAM_ID
                                                 , GCO_GOOD_ID
                                              from table(GetPropositionsTable) ) loop
          -- Création d'un nouvel ordre de fabrication
          if iCGenerateProgramMode = cgpGroupBydocRecord then
            begin
              select DOC_RECORD_ID
                into lnDocRecordId
                from FAL_JOB_PROGRAM
               where FAL_JOB_PROGRAM_ID = tplGroupedPrograms.FAL_JOB_PROGRAM_ID;
            exception
              when others then
                lnDocRecordId  := null;
            end;
          else
            lnDocRecordId  := null;
          end if;

          CreateOrder(tplGroupedPrograms.GCO_GOOD_ID, tplGroupedPrograms.FAL_JOB_PROGRAM_ID, lnDocRecordId, lnFalOrderId);

          -- Mise à jour des propositions avec l'ordre nouvellement créé
          for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
            if     oTabSelectedProp(i).FAL_JOB_PROGRAM_ID = tplGroupedPrograms.FAL_JOB_PROGRAM_ID
               and oTabSelectedProp(i).GCO_GOOD_ID = tplGroupedPrograms.GCO_GOOD_ID then
              oTabSelectedProp(i).FAL_ORDER_ID  := lnFalOrderId;
            end if;
          end loop;
        end loop;
      end if;
    end if;
  end GenerateOrder;

  /**
  * procedure GenerateBatches
  * Description : procedure de génération de lots de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iCGenerateProgramMode : Mode de génération des programmes
  * @param   iCGenerateLotMode : Mode de génération des lots
  * @param   iMergePropWhateverStock : Fusion même sis stock destination différents
  */
  procedure GenerateBatches(iCGenerateProgramMode in varchar2 default 1, iCGenerateLotMode in varchar2 default 1, iMergePropWhateverStock in integer default 1)
  is
    lvListOfProp        varchar2(32000);
    lblnFirstProp       boolean;
    ltMergedProposition TPropositions;
    lnFalLotId          number;
  begin
    if oTabSelectedProp.count > 0 then
      -- Si une proposition = 1 lot
      -- ou un programme par proposition
      -- ou insertion dans programme existant avec création systématique d'ordre
      -- Alors pas de fusion possible
      if    iCGenerateLotMode = cglOneBatchByProp
         or iCGenerateProgramMode = cgpOneProgByProp
         or iCGenerateProgramMode = cgpExistingProgOrderByBatch then
        for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
          -- Création du lot
          lnFalLotId  := CreateBatchFromProp(oTabSelectedProp(i), iCGenerateProgramMode, iCGenerateLotMode, null);
          FAL_PRC_FAL_PROP_COMMON.PushInfoUser('   . ' ||
                                               oTabSelectedProp(i).C_PREFIX_PROP ||
                                               oTabSelectedProp(i).LOT_NUMBER ||
                                               ' -> ' ||
                                               FAL_TOOLS.Format_Lot(lnFalLotId)
                                              );
        end loop;
      -- Sinon, fusion des lots
      else
        -- si Fusion même si stock destination différents
        if iMergePropWhateverStock = 1 then
          -- Pour chaque groupe
          for tplGroup in (select distinct FAL_JOB_PROGRAM_ID
                                         , FAL_ORDER_ID
                                         , GCO_GOOD_ID
                                         , GROUPFIELD
                                         , DIC_FAB_CONDITION_ID
                                      from table(GetPropositionsTable) ) loop
            -- RAZ des infos de fusion
            lblnFirstProp  := true;
            lvListOfProp   := null;

            -- Pour chaque propositions du groupe
            for tplPropToMerge in (select *
                                     from table(GetPropositionsTable)
                                    where GCO_GOOD_ID = tplGroup.GCO_GOOD_ID
                                      and FAL_JOB_PROGRAM_ID = tplGroup.FAL_JOB_PROGRAM_ID
                                      and FAL_ORDER_ID = tplGroup.FAL_ORDER_ID
                                      and (    (    DIC_FAB_CONDITION_ID is null
                                                and tplGroup.DIC_FAB_CONDITION_ID is null)
                                           or (DIC_FAB_CONDITION_ID = tplGroup.DIC_FAB_CONDITION_ID)
                                          )
                                      and (    (    GROUPFIELD is null
                                                and tplGroup.GROUPFIELD is null)
                                           or (GROUPFIELD = tplGroup.GROUPFIELD) ) ) loop
              FAL_PRC_FAL_PROP_COMMON.PushInfoUser('   . ' ||
                                                   PCS.PC_FUNCTIONS.TranslateWord('Fusion proposition') ||
                                                   ' : ' ||
                                                   tplPropToMerge.C_PREFIX_PROP ||
                                                   tplPropToMerge.LOT_NUMBER
                                                  );

              -- Récupération de la première proposition
              if lblnFirstProp then
                ltMergedProposition  := GetPropositionFromTable(tplPropToMerge.FAL_LOT_PROP_TEMP_ID);
                lblnFirstProp        := false;
              -- ou fusion dans la première proposition
              else
                ltMergedProposition.LOT_ASKED_QTY        := nvl(ltMergedProposition.LOT_ASKED_QTY, 0) + nvl(tplPropToMerge.LOT_ASKED_QTY, 0);
                ltMergedProposition.LOT_REJECT_PLAN_QTY  := nvl(ltMergedProposition.LOT_REJECT_PLAN_QTY, 0) + nvl(tplPropToMerge.LOT_REJECT_PLAN_QTY, 0);
                ltMergedProposition.LOT_TOTAL_QTY        := nvl(ltMergedProposition.LOT_TOTAL_QTY, 0) + nvl(tplPropToMerge.LOT_TOTAL_QTY, 0);

                if tplPropToMerge.LOT_ORT_UPDATE_DELAY = 1 then
                  ltMergedProposition.LOT_ORT_UPDATE_DELAY  := 1;
                end if;

                -- Fusion plus petit délai final
                if iCGenerateLotMode = cglMergeSmallestEndDelay then
                  if    ltMergedProposition.LOT_PLAN_END_DTE is null
                     or tplPropToMerge.LOT_PLAN_END_DTE < ltMergedProposition.LOT_PLAN_END_DTE then
                    ltMergedProposition.LOT_PLAN_END_DTE  := tplPropToMerge.LOT_PLAN_END_DTE;
                  end if;
                -- Fusion plus grand délai final
                elsif iCGenerateLotMode = cglMergeLargestEndDelay then
                  if    ltMergedProposition.LOT_PLAN_END_DTE is null
                     or tplPropToMerge.LOT_PLAN_END_DTE > ltMergedProposition.LOT_PLAN_END_DTE then
                    ltMergedProposition.LOT_PLAN_END_DTE  := tplPropToMerge.LOT_PLAN_END_DTE;
                  end if;
                end if;
              end if;

              -- Sauvegarde de la liste des propositions de la fusion
              lvListOfProp  := nvl(lvListOfProp, '0') || ',' || tplPropToMerge.FAL_LOT_PROP_TEMP_ID;
            end loop;

            -- Insertion du lot correspondant
            lnFalLotId     := CreateBatchFromProp(ltMergedProposition, iCGenerateProgramMode, iCGenerateLotMode, lvListOfProp);
            FAL_PRC_FAL_PROP_COMMON.PushInfoUser('      . ' || PCS.PC_FUNCTIONS.TranslateWord('Lot généré') || ' -> ' || FAL_TOOLS.Format_Lot(lnFalLotId) );
          end loop;
        -- Sinon Fusion que des props de même stock
        else
          -- Pour chaque groupe
          for tplGroup in (select distinct FAL_JOB_PROGRAM_ID
                                         , FAL_ORDER_ID
                                         , GCO_GOOD_ID
                                         , GROUPFIELD
                                         , DIC_FAB_CONDITION_ID
                                         , STM_STOCK_ID
                                      from table(GetPropositionsTable) ) loop
            -- RAZ des infos de fusion
            lblnFirstProp  := true;
            lvListOfProp   := null;

            -- Pour chaque propositions du groupe
            for tplPropToMerge in (select *
                                     from table(GetPropositionsTable)
                                    where GCO_GOOD_ID = tplGroup.GCO_GOOD_ID
                                      and FAL_JOB_PROGRAM_ID = tplGroup.FAL_JOB_PROGRAM_ID
                                      and FAL_ORDER_ID = tplGroup.FAL_ORDER_ID
                                      and STM_STOCK_ID = tplGroup.STM_STOCK_ID
                                      and (    (    DIC_FAB_CONDITION_ID is null
                                                and tplGroup.DIC_FAB_CONDITION_ID is null)
                                           or (DIC_FAB_CONDITION_ID = tplGroup.DIC_FAB_CONDITION_ID)
                                          )
                                      and (    (    GROUPFIELD is null
                                                and tplGroup.GROUPFIELD is null)
                                           or (GROUPFIELD = tplGroup.GROUPFIELD) ) ) loop
              FAL_PRC_FAL_PROP_COMMON.PushInfoUser('   . ' ||
                                                   PCS.PC_FUNCTIONS.TranslateWord('Fusion proposition') ||
                                                   ' : ' ||
                                                   tplPropToMerge.C_PREFIX_PROP ||
                                                   tplPropToMerge.LOT_NUMBER
                                                  );

              -- Récupération de la première proposition
              if lblnFirstProp then
                ltMergedProposition  := GetPropositionFromTable(tplPropToMerge.FAL_LOT_PROP_TEMP_ID);
                lblnFirstProp        := false;
              -- ou fusion dans la première proposition
              else
                ltMergedProposition.LOT_ASKED_QTY        := nvl(ltMergedProposition.LOT_ASKED_QTY, 0) + nvl(tplPropToMerge.LOT_ASKED_QTY, 0);
                ltMergedProposition.LOT_REJECT_PLAN_QTY  := nvl(ltMergedProposition.LOT_REJECT_PLAN_QTY, 0) + nvl(tplPropToMerge.LOT_REJECT_PLAN_QTY, 0);
                ltMergedProposition.LOT_TOTAL_QTY        := nvl(ltMergedProposition.LOT_TOTAL_QTY, 0) + nvl(tplPropToMerge.LOT_TOTAL_QTY, 0);

                if tplPropToMerge.LOT_ORT_UPDATE_DELAY = 1 then
                  ltMergedProposition.LOT_ORT_UPDATE_DELAY  := 1;
                end if;

                -- Fusion plus petit délai final
                if iCGenerateLotMode = cglMergeSmallestEndDelay then
                  if    ltMergedProposition.LOT_PLAN_END_DTE is null
                     or tplPropToMerge.LOT_PLAN_END_DTE < ltMergedProposition.LOT_PLAN_END_DTE then
                    ltMergedProposition.LOT_PLAN_END_DTE  := tplPropToMerge.LOT_PLAN_END_DTE;
                  end if;
                -- Fusion plus grand délai final
                elsif iCGenerateLotMode = cglMergeLargestEndDelay then
                  if    ltMergedProposition.LOT_PLAN_END_DTE is null
                     or tplPropToMerge.LOT_PLAN_END_DTE > ltMergedProposition.LOT_PLAN_END_DTE then
                    ltMergedProposition.LOT_PLAN_END_DTE  := tplPropToMerge.LOT_PLAN_END_DTE;
                  end if;
                end if;
              end if;

              -- Sauvegarde de la liste des propositions de la fusion
              lvListOfProp  := nvl(lvListOfProp, '0') || ',' || tplPropToMerge.FAL_LOT_PROP_TEMP_ID;
            end loop;

            -- Insertion du lot correspondant
            lnFalLotId     := CreateBatchFromProp(ltMergedProposition, iCGenerateProgramMode, iCGenerateLotMode, lvListOfProp);
            FAL_PRC_FAL_PROP_COMMON.PushInfoUser('      . ' || PCS.PC_FUNCTIONS.TranslateWord('Lot généré') || ' -> ' || FAL_TOOLS.Format_Lot(lnFalLotId) );
          end loop;
        end if;
      end if;
    end if;
  end GenerateBatches;

  /**
  * procedure RetrieveManufacturingProp
  * Description : Reprise des propositions sélectionnées
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iLPT_ORACLE_SESSION : Session
  * @param   iCGenerateProgramMode : Mode de génération programme
  * @param   iCGenerateLotMode : Mode de génération des lots
  * @param   iBatchGenOrderFields : ordre de traitement des propositions
  * @param   iFalJobProgramId : Programme de fabrication existant
  * @param   iMergePropWhateverStock : Fusion quelque soit le stock de destination
  */
  procedure RetrieveManufacturingProp(
    iLPT_ORACLE_SESSION     in varchar2
  , iCGenerateProgramMode   in varchar2 default 1
  , iCGenerateLotMode       in varchar2 default 1
  , iBatchGenOrderFields    in varchar2
  , iFalJobProgramId        in number
  , iMergePropWhateverStock in integer default 0
  )
  is
    lvQrySelectProp varchar2(2000);
  begin
    -- Suppression des informations de progression :
    delete from COM_LIST_ID_TEMP
          where LID_CODE = FAL_PRC_FAL_PROP_COMMON.cstProgressInfoCode;

    -- Construction de la requète de sélection des propositions
    lvQrySelectProp  :=
      ' select LPT.FAL_LOT_PROP_TEMP_ID ' ||
      '      , GOO.DIC_GOOD_GROUP_ID ' ||
      '      , LPT.DIC_ACCOUNTABLE_GROUP_ID ' ||
      '      , LPT.DOC_RECORD_ID ' ||
      '      , GOO.GOO_MAJOR_REFERENCE ' ||
      '      , LPT.DIC_FAB_CONDITION_ID ' ||
      '      , LPT.DIC_FAMILY_ID ' ||
      '      , LPT.C_PRIORITY ' ||
      '      , LPT.STM_STOCK_ID ' ||
      '      , LPT.STM_STM_STOCK_ID ' ||
      '      , LPT.STM_LOCATION_ID ' ||
      '      , LPT.STM_STM_LOCATION_ID ' ||
      '      , LPT.GCO_GOOD_ID ' ||
      '      , LPT.LOT_ASKED_QTY ' ||
      '      , LPT.LOT_REJECT_PLAN_QTY ' ||
      '      , LPT.LOT_TOTAL_QTY ' ||
      '      , LPT.LOT_ORT_UPDATE_DELAY ' ||
      '      , LPT.LOT_PLAN_END_DTE ' ||
      '      , LPT.LOT_PLAN_BEGIN_DTE ' ||
      '      , LOT_TOLERANCE ' ||
      '      , LOT_CPT_CHANGE ' ||
      '      , LOT_SHORT_DESCR ' ||
      '      , LOT_PLAN_LEAD_TIME ' ||
      '      , FAL_SCHEDULE_PLAN_ID ' ||
      '      , null FAL_JOB_PROGRAM_ID ' ||
      '      , null FAL_ORDER_ID ' ||
      '      , null PAC_SUPPLIER_PARTNER_ID ' ||
      '      , C_PREFIX_PROP ' ||
      '      , null GCO_GCO_GOOD_ID ' ||
      '      , GCO_CHARACTERIZATION1_ID    ' ||
      '      , GCO_CHARACTERIZATION2_ID    ' ||
      '      , GCO_CHARACTERIZATION3_ID    ' ||
      '      , GCO_CHARACTERIZATION4_ID    ' ||
      '      , GCO_CHARACTERIZATION5_ID    ' ||
      '      , FAD_CHARACTERIZATION_VALUE_1' ||
      '      , FAD_CHARACTERIZATION_VALUE_2' ||
      '      , FAD_CHARACTERIZATION_VALUE_3' ||
      '      , FAD_CHARACTERIZATION_VALUE_4' ||
      '      , FAD_CHARACTERIZATION_VALUE_5';

    if iCGenerateProgramMode = cgpGroupByDicGoodGroup then
      lvQrySelectProp  := lvQrySelectProp || ' , DIC_GOOD_GROUP_ID GROUPFIELD ';
    -- Groupt par responsable
    elsif iCGenerateProgramMode = cgpGroupByDicAccountable then
      lvQrySelectProp  := lvQrySelectProp || ' , LPT.DIC_ACCOUNTABLE_GROUP_ID GROUPFIELD ';
    -- Groupt par dossier
    elsif iCGenerateProgramMode = cgpGroupBydocRecord then
      lvQrySelectProp  := lvQrySelectProp || ' , DOC_RECORD_ID GROUPFIELD ';
    -- Dans prog existant
    elsif    iCGenerateProgramMode = cgpExistingProg
          or iCGenerateProgramMode = cgpExistingProgNewOrder then
      lvQrySelectProp  := lvQrySelectProp || ' , GOO_MAJOR_REFERENCE GROUPFIELD ';
    else
      lvQrySelectProp  := lvQrySelectProp || ' , GOO_MAJOR_REFERENCE GROUPFIELD ';
    end if;

    lvQrySelectProp  := lvQrySelectProp || ', LPT.LOT_NUMBER';
    lvQrySelectProp  :=
      lvQrySelectProp ||
      '   from FAL_LOT_PROP_TEMP LPT' ||
      '      , GCO_GOOD GOO' ||
      '  where LPT.FAD_SELECT = 1 ' ||
      '    and LPT.GCO_GOOD_ID = GOO.GCO_GOOD_ID ' ||
      '    and LPT.LPT_ORACLE_SESSION = :LPT_ORACLE_SESSION ' ||
      ' order by LPT.FAD_SELECT ';

    -- Ordre de reprise particulier des propositions (origine = paramètre d'objet LOT_GEN_ORDER_FIELDS)
    if iBatchGenOrderFields is not null then
      lvQrySelectProp  := lvQrySelectProp || ', ' || replace(iBatchGenOrderFields, ';', ',');
    else
      lvQrySelectProp  := lvQrySelectProp || ', GOO_MAJOR_REFERENCE, DIC_FAB_CONDITION_ID, STM_STOCK_ID';
    end if;

    -- Sélection des propositions à traiter
    execute immediate lvQrySelectProp
    bulk collect into oTabSelectedProp
                using iLPT_ORACLE_SESSION;

    -- Génération des programmes de fabrication
    FAL_PRC_FAL_PROP_COMMON.PushInfoUser(PCS.PC_FUNCTIONS.TranslateWord('Nbre de propositions sélectionnées') || ' : ' || oTabSelectedProp.count);
    GenerateJobProgram(iCGenerateProgramMode, iFalJobProgramId);
    -- Génération des ordres de fabrication
    GenerateOrder(iCGenerateProgramMode, iCGenerateLotMode);
    -- Génération des lots, par propositions ou fusionnés
    FAL_PRC_FAL_PROP_COMMON.PushInfoUser('');
    FAL_PRC_FAL_PROP_COMMON.PushInfoUser(PCS.PC_FUNCTIONS.TranslateWord('Génération des lots de fabrication') || '...');
    GenerateBatches(iCGenerateProgramMode, iCGenerateLotMode, iMergePropWhateverStock);
    FAL_PRC_FAL_PROP_COMMON.PushInfoUser('');
    FAL_PRC_FAL_PROP_COMMON.PushInfoUser(PCS.PC_FUNCTIONS.TranslateWord('Traitement terminé') );
  end RetrieveManufacturingProp;

  /**
  * procedure GetPropositionsTable
  * Description : Fonction pipelined, d'accès à la table de travail des propositions
  *               en cours de reprise
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iLPT_ORACLE_SESSION : Session
  */
  function GetPropositionsTable
    return TTabSelectedProp pipelined
  is
  begin
    if oTabSelectedProp.count > 0 then
      for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
        pipe row(oTabSelectedProp(i) );
      end loop;
    end if;
  end GetPropositionsTable;

  /**
  * procedure pUpdateBatchPropTasks
  * Description :
  *     Updates the batch proposition's tasks the identifier of which is
  *     transmitted in parameter according to iNewQty.
  * @created age 29.07.2015
  * @lastUpdate
  * @private
  * @param iBatchPropId : Identifier of the batch proposition
  * @param iNewQty      : New quantity
  */
  procedure pUpdateBatchPropTasks(iBatchPropId in FAL_LOT_PROP_TEMP.FAL_LOT_PROP_TEMP_ID%type, iNewQty in FAL_LOT_PROP_TEMP.LOT_TOTAL_QTY%type default null)
  as
  begin
    for ltplTask in (select FAL_TASK_LINK_PROP_ID
                       from FAL_TASK_LINK_PROP
                      where FAL_LOT_PROP_ID = iBatchPropId) loop
      update FAL_TASK_LINK_PROP
         set TAL_DUE_QTY = iNewQty
           , TAL_PLAN_RATE = (iNewQty / FAL_TOOLS.nvla(SCS_QTY_REF_WORK, 1) ) * nvl(SCS_PLAN_RATE, 0)
           , TAL_TSK_AD_BALANCE =(nvl(ceil(iNewQty / FAL_TOOLS.NIFZ(SCS_QTY_FIX_ADJUSTING) ), 1) * nvl(SCS_ADJUSTING_TIME, 0) )
           , TAL_TSK_W_BALANCE =( (iNewQty / SCS_QTY_REF_WORK) * nvl(SCS_WORK_TIME, 0) )
           , TAL_TSK_BALANCE =
               (nvl( (nvl(ceil(iNewQty / FAL_TOOLS.NIFZ(SCS_QTY_FIX_ADJUSTING) ), 1) * nvl(SCS_ADJUSTING_TIME, 0) ), 0) +
                nvl( ( (iNewQty / SCS_QTY_REF_WORK) * nvl(SCS_WORK_TIME, 0) ), 0)
               )
           , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where FAL_TASK_LINK_PROP_ID = ltplTask.FAL_TASK_LINK_PROP_ID;
    end loop;
  end pUpdateBatchPropTasks;

  /**
  * Description :
  *     Plan the batch proposition the identifier of which is transmitted in parameter.
  *     Warning ! If the iTempTotalQty parameter is not null and differs from the batch proposition total,
  *     quantity, batch prop's tasks will be updated according to iTempTotalQty prior to planification
  *     process.
  */
  procedure planBatchProp(
    iBatchPropId   in FAL_LOT_PROP_TEMP.FAL_LOT_PROP_TEMP_ID%type
  , iPlanDate      in date
  , iFromBeginDate in integer
  , iTempTotalQty  in FAL_LOT_PROP_TEMP.LOT_TOTAL_QTY%type default null
  )
  as
    lnDiffQty number;
  begin
    -- before processing to the batch proposition planning, if the total batch quantity has been updated on temporary data
    -- and if the process plan is not planned 'by product', we need to update the batch proposition quantities and the
    -- batch proposition's tasks according to this quantity in order to have a correct planning.
    select -nvl(max(LOT_TOTAL_QTY) - iTempTotalQty, 0) diff
      into lnDiffQty
      from FAL_LOT_PROP
     where FAL_LOT_PROP_ID = iBatchPropId
       and C_SCHEDULE_PLANNING <> '1'
       and LOT_TOTAL_QTY <> iTempTotalQty;

    if lnDiffQty <> 0 then
      update FAL_LOT_PROP
         set (LOT_ASKED_QTY, LOT_REJECT_PLAN_QTY, LOT_TOTAL_QTY, A_IDMOD, A_DATEMOD) =
               (select LOT_ASKED_QTY
                     , LOT_REJECT_PLAN_QTY
                     , LOT_TOTAL_QTY
                     , pcs.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                  from FAL_LOT_PROP_TEMP
                 where FAL_LOT_PROP_TEMP_ID = iBatchPropId)
       where FAL_LOT_PROP_ID = iBatchPropId;
      -- Updating batch proposition's task according to new quantity.
      pUpdateBatchPropTasks(iBatchPropId, iTempTotalQty);
    end if;
    -- calling batch proposition planning process.
    FAL_PLANIF.Planification_Lot_prop(PrmFAL_LOT_PROP_ID          => iBatchPropId
                                    , DatePlanification           => iPlanDate
                                    , SelonDateDebut              => iFromBeginDate
                                    , MAJReqLiensComposantsProp   => 1
                                    , MAJ_Reseaux_Requise         => 1
                                     );
    -- Updating begin and end date on temporary data accordind to updated dates in batch
    -- proposition after planning process.
    update FAL_LOT_PROP_TEMP
       set (LOT_PLAN_BEGIN_DTE, LOT_PLAN_END_DTE, A_IDMOD, A_DATEMOD) = (select LOT_PLAN_BEGIN_DTE
                                                                              , LOT_PLAN_END_DTE
                                                                              , pcs.PC_I_LIB_SESSION.GetUserIni
                                                                              , sysdate
                                                                           from FAL_LOT_PROP
                                                                          where FAL_LOT_PROP_ID = iBatchPropId)
     where FAL_LOT_PROP_TEMP_ID = iBatchPropId;
  end planBatchProp;
end;
