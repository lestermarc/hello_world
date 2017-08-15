--------------------------------------------------------
--  DDL for Package Body FAL_BREAKUP_LOT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_BREAKUP_LOT" 
is
  /**
  * procedure ReportBatchBasisPlanning
  * Description : Report de la planification de base de l'of source vers l'of destination
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSrcFalLotId : Lot source
  * @param   iDstFalLotId : Lot cible
  */
  procedure ReportBatchBasisPlanning(iSrcFalLotId in number, iDstFalLotId in number)
  is
  begin
    for tplSrcBatch in (select LOT_BASIS_LEAD_TIME
                             , LOT_BASIS_END_DTE
                             , LOT_BASIS_BEGIN_DTE
                          from FAL_LOT
                         where FAL_LOT_ID = iSrcFalLotId) loop
      update FAL_LOT
         set LOT_BASIS_LEAD_TIME = tplSrcBatch.LOT_BASIS_LEAD_TIME
           , LOT_BASIS_END_DTE = tplSrcBatch.LOT_BASIS_END_DTE
           , LOT_BASIS_BEGIN_DTE = tplSrcBatch.LOT_BASIS_BEGIN_DTE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = iDstFalLotId;
    end loop;
  end ReportBatchBasisPlanning;

  /**
  * procedure ReportTaskBasisPlanning
  * Description : Report de la planification de base des opérations de l'of
  *               source vers celle de l'of destination
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSrcFalLotId : Lot source
  * @param   iDstFalLotId : Lot cible
  */
  procedure ReportTaskBasisPlanning(iSrcFalLotId in number, iDstFalLotId in number)
  is
  begin
    for tplSrcBatch in (select TAL_BASIS_BEGIN_DATE
                             , TAL_BASIS_END_DATE
                             , TAL_TASK_BASIS_TIME
                             , TAL_SEQ_ORIGIN
                          from FAL_TASK_LINK
                         where FAL_LOT_ID = iSrcFalLotId) loop
      update FAL_TASK_LINK
         set TAL_BASIS_BEGIN_DATE = tplSrcBatch.TAL_BASIS_BEGIN_DATE
           , TAL_BASIS_END_DATE = tplSrcBatch.TAL_BASIS_END_DATE
           , TAL_TASK_BASIS_TIME = tplSrcBatch.TAL_TASK_BASIS_TIME
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = iDstFalLotId
         and TAL_SEQ_ORIGIN = tplSrcBatch.TAL_SEQ_ORIGIN;
    end loop;
  end ReportTaskBasisPlanning;

  /**
  * fonction GetLomNeedQty
  * Description : Calcul de la quantité besoin des composants temporaires
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLOM_REF_QTY : Qté ref nomenclature du composant origine
  * @param   aLOM_UTIL_COEF : Coef utilisation du composant origine
  * @param   aGCO_GOOD_ID : Produit du composant origine
  * @param   aQteToSwitch : Qté à transférer
  */
  function GetLomNeedQty(aLOM_REF_QTY number, aLOM_UTIL_COEF number, aGCO_GOOD_ID number, aQteToSwitch number)
    return number
  is
  begin
    if nvl(aLOM_REF_QTY, 0) > 0 then
      return FAL_TOOLS.ArrondiSuperieur(aQteToSwitch * aLOM_UTIL_COEF / aLOM_REF_QTY, aGCO_GOOD_ID);
    else
      return FAL_TOOLS.ArrondiSuperieur(aQteToSwitch * aLOM_UTIL_COEF, aGCO_GOOD_ID);
    end if;
  end GetLomNeedQty;

  /**
  * fonction GetLomAdjustedQty
  * Description : Calcul de la quantité sup inf des composants temporaires
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLOM_REF_QTY : Qté ref nomenclature du composant origine
  * @param   aLOM_UTIL_COEF : Coef utilisation du composant origine
  * @param   aGCO_GOOD_ID : Produit du composant origine
  * @param   aQteToSwitch : Qté à transférer
  * @param   aLOM_ADJUSTED_QTY : Qté sup/Inf du composant origine
  * @param   aLOM_ADJUSTED_QTY_RECEIPT : Qté sup/Inf réception du composant origine
  */
  function GetLomAdjustedQty(
    aLOM_REF_QTY              number
  , aLOM_UTIL_COEF            number
  , aGCO_GOOD_ID              number
  , aQteToSwitch              number
  , aLOM_ADJUSTED_QTY         number
  , aLOM_ADJUSTED_QTY_RECEIPT number
  )
    return number
  is
    aNeedQty number;
  begin
    aNeedQty  := GetLomNeedQty(aLOM_REF_QTY, aLOM_UTIL_COEF, aGCO_GOOD_ID, aQteToSwitch);

    if nvl(aLOM_ADJUSTED_QTY, 0) < 0 then
      if (nvl(aLOM_ADJUSTED_QTY_RECEIPT, 0) - nvl(aLOM_ADJUSTED_QTY, 0) ) > aNeedQty then
        return(-1 * aNeedQty);
      else
        return nvl(aLOM_ADJUSTED_QTY, 0) - nvl(aLOM_ADJUSTED_QTY_RECEIPT, 0);
      end if;
    else
      return 0;
    end if;
  end GetLomAdjustedQty;

  /**
  * fonction GetLomFullReqQty
  * Description : Calcul de la quantité besoin totale des composants temporaires
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLOM_REF_QTY : Qté ref nomenclature du composant origine
  * @param   aLOM_UTIL_COEF : Coef utilisation du composant origine
  * @param   aGCO_GOOD_ID : Produit du composant origine
  * @param   aQteToSwitch : Qté à transférer
  * @param   aLOM_ADJUSTED_QTY : Qté sup/Inf du composant origine
  * @param   aLOM_ADJUSTED_QTY_RECEIPT : Qté sup/Inf réception du composant origine
  */
  function GetLomFullReqQty(
    aLOM_REF_QTY              number
  , aLOM_UTIL_COEF            number
  , aGCO_GOOD_ID              number
  , aQteToSwitch              number
  , aLOM_ADJUSTED_QTY         number
  , aLOM_ADJUSTED_QTY_RECEIPT number
  )
    return number
  is
    aNeedQty     number;
    aAdjustedQty number;
  begin
    aNeedQty      := GetLomNeedQty(aLOM_REF_QTY, aLOM_UTIL_COEF, aGCO_GOOD_ID, aQteToSwitch);
    aAdjustedQty  := GetLomAdjustedQty(aLOM_REF_QTY, aLOM_UTIL_COEF, aGCO_GOOD_ID, aQteToSwitch, aLOM_ADJUSTED_QTY, aLOM_ADJUSTED_QTY_RECEIPT);
    return aNeedQty + aAdjustedQty;
  end GetLomFullReqQty;

  /**
  * Description : Récupération de la référence complète du lot de fabrication
  */
  function GetLOT_REFCOMPL(aLotID TTypeID)
    return FAL_LOT.LOT_REFCOMPL%type
  is
  begin
    -- wrapper
    return FAL_LIB_BATCH.GetLOT_REFCOMPL(aLotID);
  end GetLOT_REFCOMPL;

  /**
  * fonction GetMATERIAL_LINK_ID
  * Description : Récupération du composants de lot et de séquences = aux param.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLotId : Lot de fabrication
  * @param   aSeq : Séquence composant
  */
  function GetMATERIAL_LINK_ID(aLotID TTypeID, aSeq integer)
    return TTypeID
  is
    result TTypeID;
  begin
    select FAL_LOT_MATERIAL_LINK_ID
      into result
      from FAL_LOT_MATERIAL_LINK
     where FAL_LOT_ID = aLotID
       and LOM_SEQ = aSeq;

    return result;
  exception
    when no_data_found then
      return null;
  end GetMATERIAL_LINK_ID;

  /**
  * fonction GetLOT_TOTAL_QTY
  * Description :
  *    Récupération de la quantité totale du lot de fabrication
  * @created ECA
  * @lastUpdate age 20.02.2013
  * @private
  * @param : iLotID : ID Lot de fabrication
  * @return : Voir description
  */
  function GetLOT_TOTAL_QTY(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_LOT.LOT_TOTAL_QTY%type
  is
  begin
    return nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'LOT_TOTAL_QTY', it_pk_value => iLotID), 0);
  end GetLOT_TOTAL_QTY;

  /**
  * fonction GetLOT_INPROD_QTY
  * Description :
  *    Récupération de la quantité en fabrication du lot de fabrication
  * @created ECA
  * @lastUpdate AGE 20.02.2013
  * @private
  * @param : iLotID : ID Lot de fabrication
  * @return : Voir description
  */
  function GetLOT_INPROD_QTY(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_LOT.LOT_INPROD_QTY%type
  as
  begin
    return nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'LOT_INPROD_QTY', it_pk_value => iLotID), 0);
  end GetLOT_INPROD_QTY;

  /**
  * fonction GetIN_PRICE
  * Description :
  *    Récupération du prix d'une entrée atelier
  * @created ECA
  * @lastUpdate AGE 20.03.2013
  * @private
  * @param : aFactoryInID : ID d'une entrée atelier
  * @return : Voir description
  */
  function GetIN_PRICE(iFactoryInID FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type)
    return FAL_FACTORY_IN.IN_PRICE%type
  as
  begin
    return nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_FACTORY_IN', iv_column_name => 'IN_PRICE', it_pk_value => iFactoryInID), 0);
  end GetIN_PRICE;

  /**
  * fonction GetFAL_TASK_ID
  * Description : Récupération de la tache liée à une opération
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLotID : Id du lot de fabrication
  * @param   aOriginOpSeq : Séquence opération
  */
  function GetFAL_TASK_ID(aLotID TTypeID, aOriginOPSeq integer)
    return TTypeID
  is
    result TTypeID;
  begin
    select FAL_TASK_ID
      into result
      from FAL_TASK_LINK
     where FAL_LOT_ID = aLotID
       and SCS_STEP_NUMBER = aOriginOPSeq;

    return result;
  exception
    when no_data_found then
      return null;
  end GetFAL_TASK_ID;

  /**
  * fonction GetSeqTargetTask
  * Description : Fonction qui renvoie la séquence de l'opération cible suivant la configuration
  *               PPS_ASC_DESC
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_SCHEDULE_PLAN_ID : Gamme cible
  * @param   aSCS_STEP_NUMBER : Séquence op
  */
  function GetSeqTargetTask(aFAL_SCHEDULE_PLAN_ID number, aSCS_STEP_NUMBER integer)
    return integer
  is
    cursor CUR_FAL_TASK_LINK
    is
      select   SCS_STEP_NUMBER
             , C_OPERATION_TYPE
          from FAL_LIST_STEP_LINK
         where FAL_SCHEDULE_PLAN_ID = aFAL_SCHEDULE_PLAN_ID
           and SCS_STEP_NUMBER < aSCS_STEP_NUMBER
      order by SCS_STEP_NUMBER desc;

    CurFalTaskLink       CUR_FAL_TASK_LINK%rowtype;
    aResultOriginTaskSeq integer;
  begin
    -- Si la gestion des OPs secondaires est ascendante
    if PCS.PC_CONFIG.GETCONFIG('PPS_ASC_DSC') = '1' then
      aResultOriginTaskSeq  := aSCS_STEP_NUMBER;

      for CurFalTaskLink in CUR_FAL_TASK_LINK loop
        exit when CurFalTaskLink.C_OPERATION_TYPE <> '2';
        aResultOriginTaskSeq  := CurFalTaskLink.SCS_STEP_NUMBER;
      end loop;

      return aResultOriginTaskSeq;
    -- Si la gestion des OPs secondaires est en descendante
    else
      return aSCS_STEP_NUMBER;
    end if;
  end GetSeqTargetTask;

  /**
  * fonction GetSeqOriginTask
  * Description : Fonction qui renvoie la séquence de l'opération origine suivant la configuration
  *               PPS_ASC_DESC
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_ID : Lot de fabrication
  * @param   aSCS_STEP_NUMBER : Séquence origine
  */
  function GetSeqOriginTask(aFAL_LOT_ID number, aSCS_STEP_NUMBER integer)
    return integer
  is
    cursor CUR_FAL_TASK_LINK
    is
      select   SCS_STEP_NUMBER
             , C_OPERATION_TYPE
          from FAL_TASK_LINK
         where FAL_LOT_ID = aFAL_LOT_ID
           and SCS_STEP_NUMBER < aSCS_STEP_NUMBER
      order by SCS_STEP_NUMBER desc;

    CurFalTaskLink       CUR_FAL_TASK_LINK%rowtype;
    aResultOriginTaskSeq integer;
  begin
    -- Si pas d'op origine, alors on prends la première opération principale du lot
    if nvl(aSCS_STEP_NUMBER, 0) = 0 then
      begin
        select min(SCS_STEP_NUMBER)
          into aResultOriginTaskSeq
          from FAL_TASK_LINK
         where C_OPERATION_TYPE = '1'
           and FAL_LOT_ID = aFAL_LOT_ID;

        return aResultOriginTaskSeq;
      exception
        when no_data_found then
          return null;
      end;
    end if;

    -- Si la gestion des OPs secondaires est ascendante
    if PCS.PC_CONFIG.GETCONFIG('PPS_ASC_DSC') = 1 then
      aResultOriginTaskSeq  := aSCS_STEP_NUMBER;

      for CurFalTaskLink in CUR_FAL_TASK_LINK loop
        exit when CurFalTaskLink.C_OPERATION_TYPE <> '2';
        aResultOriginTaskSeq  := CurFalTaskLink.SCS_STEP_NUMBER;
      end loop;

      return aResultOriginTaskSeq;
    -- Sinon, si la gestion des OPs secondaires est descendante
    else
      return aSCS_STEP_NUMBER;
    end if;
  end GetSeqOriginTask;

  /**
  * fonction SplitComponents
  * Description : Création des liens composants cibles par rapport aux composants temporaires
  *               puis MAJ des liens composants origines par rapport aux composants temporaires
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSession       : Session oracle
  * @param   aLotOriginID   : Lot origine
  * @param   aLotTargetID   : Lot cible
  * @param   aTransferedQty : Quantité transférée
  */
  procedure SplitComponents(aSession in varchar2, aLotOriginID in TTypeID, aLotTargetID in TTypeID, aTransferedQty in TTypeQty)
  is
    -- Parcours des composants temporaires
    cursor Cur_Target_Components
    is
      select   LOM.*
             , nvl(LINKS.FCL_HOLD_QTY, 0) FCL_HOLD_QTY
          from FAL_LOT_MAT_LINK_TMP LOM
             , (select   FCL.FAL_LOT_MAT_LINK_TMP_ID
                       , sum(FCL.FCL_HOLD_QTY) FCL_HOLD_QTY
                    from FAL_COMPONENT_LINK FCL
                   where FCL.FCL_SESSION = aSession
                group by FCL.FAL_LOT_MAT_LINK_TMP_ID) LINKS
         where LOM.LOM_SESSION = aSession
           and LOM.FAL_LOT_MAT_LINK_TMP_ID = LINKS.FAL_LOT_MAT_LINK_TMP_ID(+)
      order by LOM.LOM_SEQ;

    -- Lecture des Composants du lot origine
    cursor Cur_Origin_Components(aMatLinkID in TTypeID)
    is
      select     *
            from FAL_LOT_MATERIAL_LINK
           where FAL_LOT_MATERIAL_LINK_ID = aMatLinkID
      for update;

    CurTargetComponents Cur_Target_Components%rowtype;
    CurOriginComponents Cur_Origin_Components%rowtype;
    QteBesoinNo         TTypeQty;
    QteSupInf           TTypeQty;
    QteBesoinTotal      TTypeQty;
    QteConso            TTypeQty;
    QteBesoinCPT        TTypeQty;
    QteMaxReceipt       TTypeQty;
    FecCurrentQty       TTypeQty;
    FecCurrentAmount    TTypeQty;
    lSplitRatio         number;
    lNewLinkId          TTypeId;
  begin
    -- Parcours des composants temporaires
    for CurTargetComponents in Cur_Target_Components loop
      -- Création du lien composant par rapport au composant temporaire.
      QteBesoinNo     := nvl(CurTargetComponents.LOM_NEED_QTY, 0);
      QteSupInf       := nvl(CurTargetComponents.LOM_ADJUSTED_QTY, 0);
      QteBesoinTotal  := QteBesoinNo + QteSupInf;
      QteConso        := nvl(CurTargetComponents.FCL_HOLD_QTY, 0);
      QteBesoinCPT    := 0;
      QteMaxReceipt   := 0;

      -- Calcul de la quantité besoin CPT
      if     (CurTargetComponents.C_TYPE_COM = '1')
         and (CurTargetComponents.C_KIND_COM = '1')
         and (CurTargetComponents.LOM_STOCK_MANAGEMENT = 1) then
        -- Qté besoin
        QteBesoinCPT  := QteBesoinTotal - QteConso;
      end if;

      -- Calcul de la quantité max réceptionnable
      QteMaxReceipt   :=
        FAL_COMPONENT_FUNCTIONS.getMaxReceptQty(aGCO_GOOD_ID            => FAL_TOOLS.GetGCO_GOOD_ID(CurTargetComponents.FAL_LOT_ID)
                                              , aLOT_INPROD_QTY         => GetLOT_INPROD_QTY(aLotTargetID)
                                              , aLOM_ADJUSTED_QTY       => QteSupInf
                                              , aLOM_CONSUMPTION_QTY    => QteConso
                                              , aLOM_REF_QTY            => CurTargetComponents.LOM_REF_QTY
                                              , aLOM_UTIL_COEF          => CurTargetComponents.LOM_UTIL_COEF
                                              , aLOM_STOCK_MANAGEMENT   => CurTargetComponents.LOM_STOCK_MANAGEMENT
                                              , aC_KIND_COM             => CurTargetComponents.C_KIND_COM
                                              , aC_TYPE_COM             => CurTargetComponents.C_TYPE_COM
                                               );
      lNewLinkId      := CurTargetComponents.FAL_LOT_MAT_LINK_TMP_ID;

      -- Création d'un lien composant lot
      insert into FAL_LOT_MATERIAL_LINK
                  (FAL_LOT_MATERIAL_LINK_ID
                 , FAL_LOT_ID
                 , C_TYPE_COM
                 , C_KIND_COM
                 , C_CHRONOLOGY_TYPE
                 , LOM_STOCK_MANAGEMENT
                 , C_DISCHARGE_COM
                 , LOM_SEQ
                 , LOM_TASK_SEQ
                 , LOM_POS
                 , GCO_GOOD_ID
                 , LOM_SECONDARY_REF
                 , LOM_SHORT_DESCR
                 , LOM_LONG_DESCR
                 , LOM_FREE_DECR
                 , LOM_NEED_DATE
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , LOM_PRICE
                 , LOM_UTIL_COEF
                 , LOM_REF_QTY
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
                 , LOM_ADJUSTED_QTY_RECEIPT
                 , LOM_MAX_FACT_QTY
                 , LOM_NEED_QTY
                 , LOM_MAX_RECEIPT_QTY
                 , LOM_AVAILABLE_QTY
                 , LOM_INTERVAL
                 , LOM_TEXT
                 , LOM_FREE_TEXT
                 , LOM_FRE_NUM
                 , LOM_SUBSTITUT
                 , LOM_MARK_TOPO
                 , LOM_QTY_REFERENCE_LOSS
                 , LOM_FIXED_QUANTITY_WASTE
                 , LOM_PERCENT_WASTE
                 , LOM_WEIGHING
                 , LOM_WEIGHING_MANDATORY
                 , A_IDCRE
                 , A_DATECRE
                  )
           values (lNewLinkId   -- FAL_LOT_MATERIAL_LINK_ID
                 , aLotTargetID   -- FAL_LOT_ID
                 , CurTargetComponents.C_TYPE_COM   -- C_TYPE_COM
                 , CurTargetComponents.C_KIND_COM   -- C_KIND_COM
                 , CurTargetComponents.C_CHRONOLOGY_TYPE
                 , CurTargetComponents.LOM_STOCK_MANAGEMENT   -- LOM_STOCK_MANAGEMENT
                 , CurTargetComponents.C_DISCHARGE_COM   -- C_DISCHARGE_COM
                 , CurTargetComponents.LOM_SEQ   -- LOM_SEQ
                 , CurTargetComponents.LOM_TASK_SEQ   -- LOM_TASK_SEQ
                 , CurTargetComponents.LOM_POS   -- LOM_POS
                 , CurTargetComponents.GCO_GOOD_ID   -- GCO_GOOD_ID
                 , CurTargetComponents.LOM_SECONDARY_REF   -- LOM_SECONDARY_REF
                 , CurTargetComponents.LOM_SHORT_DESCR   -- LOM_SHORT_DESCR
                 , CurTargetComponents.LOM_LONG_DESCR   -- LOM_LONG_DESCR
                 , CurTargetComponents.LOM_FREE_DECR   -- LOM_FREE_DECR
                 , null   -- LOM_NEED_DATE
                 , CurTargetComponents.STM_STOCK_ID   -- STM_STOCK_ID
                 , CurTargetComponents.STM_LOCATION_ID   -- STM_LOCATION_ID
                 , CurTargetComponents.LOM_PRICE   -- LOM_PRICE
                 , CurTargetComponents.LOM_UTIL_COEF   -- LOM_UTIL_COEF
                 , CurTargetComponents.LOM_REF_QTY   -- LOM_REF_QTY
                 , QteBesoinNo   -- LOM_BOM_REQ_QTY
                 , QteSupInf   -- LOM_ADJUSTED_QTY
                 , QteBesoinTotal   -- LOM_FULL_REQ_QTY
                 , QteConso   -- LOM_CONSUMPTION_QTY
                 , 0   -- LOM_REJECTED_QTY
                 , 0   -- LOM_BACK_QTY
                 , 0   -- LOM_PT_REJECT_QTY
                 , 0   -- LOM_CPT_TRASH_QTY
                 , 0   -- LOM_CPT_RECOVER_QTY
                 , 0   -- LOM_CPT_REJECT_QTY
                 , 0   -- LOM_EXIT_RECEIPT
                 , 0   -- LOM_ADJUSTED_QTY_RECEIPT
                 , 0   -- LOM_MAX_FACT_QTY
                 , QteBesoinCPT   -- LOM_NEED_QTY
                 , QteMaxReceipt   -- LOM_MAX_RECEIPT_QTY
                 , 0   -- LOM_AVAILABLE_QTY
                 , 0   -- LOM_INTERVAL
                 , CurTargetComponents.LOM_TEXT   -- LOM_TEXT
                 , CurTargetComponents.LOM_FREE_TEXT   -- LOM_FREE_TEXT
                 , CurTargetComponents.LOM_FRE_NUM   -- LOM_FRE_NUM
                 , CurTargetComponents.LOM_SUBSTITUT   -- LOM_SUBSTITUT
                 , CurTargetComponents.LOM_MARK_TOPO
                 , CurTargetComponents.LOM_QTY_REFERENCE_LOSS
                 , CurTargetComponents.LOM_FIXED_QUANTITY_WASTE
                 , CurTargetComponents.LOM_PERCENT_WASTE
                 , CurTargetComponents.LOM_WEIGHING
                 , CurTargetComponents.LOM_WEIGHING_MANDATORY
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                 , sysdate   -- A_DATECRE
                  );

      -- MAJ du composant du lot de fabrication origine
      open Cur_Origin_Components(CurTargetComponents.FAL_LOT_MATERIAL_LINK_ID);

      fetch Cur_Origin_Components
       into CurOriginComponents;

      -- S'assurer qu'il y ai un enregistrement...
      if Cur_Origin_Components%found then
        if nvl(CurOriginComponents.LOM_REF_QTY, 0) <> 0 then
          QteBesoinNo  :=
            FAL_TOOLS.ArrondiSuperieur( ( (GetLOT_TOTAL_QTY(aLotOriginID) - aTransferedQty) * CurOriginComponents.LOM_UTIL_COEF)
                                       / CurOriginComponents.LOM_REF_QTY
                                     , CurOriginComponents.GCO_GOOD_ID
                                      );
        else
          QteBesoinNo  :=
             FAL_TOOLS.ArrondiSuperieur( ( (GetLOT_TOTAL_QTY(aLotOriginID) - aTransferedQty) * CurOriginComponents.LOM_UTIL_COEF)
                                      , CurOriginComponents.GCO_GOOD_ID);
        end if;

        QteSupInf       := CurOriginComponents.LOM_ADJUSTED_QTY - nvl(CurTargetComponents.LOM_ADJUSTED_QTY, 0);
        QteBesoinTotal  := QteBesoinNo + QteSupInf;

        if CurOriginComponents.LOM_CONSUMPTION_QTY <> 0 then
          lSplitRatio  := nvl(CurTargetComponents.FCL_HOLD_QTY, 0) / CurOriginComponents.LOM_CONSUMPTION_QTY;
        else
          lSplitRatio  := 1;
        end if;

        QteConso        := CurOriginComponents.LOM_CONSUMPTION_QTY - nvl(CurTargetComponents.FCL_HOLD_QTY, 0);
        QteBesoinCPT    := 0;
        QteMaxReceipt   := 0;

        -- Calcul de la quantité besoin CPT
        if     (CurOriginComponents.C_TYPE_COM = '1')
           and (CurOriginComponents.C_KIND_COM = '1')
           and (CurOriginComponents.LOM_STOCK_MANAGEMENT = 1) then
          if QteSupInf < 0 then
            QteBesoinCPT  := QteBesoinTotal + CurOriginComponents.LOM_REJECTED_QTY + CurOriginComponents.LOM_BACK_QTY - QteConso;
          elsif(CurOriginComponents.LOM_REJECTED_QTY + CurOriginComponents.LOM_BACK_QTY - QteSupInf) < 0 then
            QteBesoinCPT  := QteBesoinTotal - QteConso;
          else
            QteBesoinCPT  := QteBesoinTotal + CurOriginComponents.LOM_REJECTED_QTY + CurOriginComponents.LOM_BACK_QTY - QteSupInf - QteConso;
          end if;
        end if;

        -- Calcul de la quantité max réceptionnable
        QteMaxReceipt   :=
          FAL_COMPONENT_FUNCTIONS.getMaxReceptQty(aGCO_GOOD_ID                => FAL_TOOLS.GetGCO_GOOD_ID(CurOriginComponents.FAL_LOT_ID)
                                                , aLOT_INPROD_QTY             => GetLOT_INPROD_QTY(aLotOriginID)
                                                , aLOM_ADJUSTED_QTY           => QteSupInf
                                                , aLOM_CONSUMPTION_QTY        => QteConso
                                                , aLOM_REF_QTY                => CurOriginComponents.LOM_REF_QTY
                                                , aLOM_UTIL_COEF              => CurOriginComponents.LOM_UTIL_COEF
                                                , aLOM_ADJUSTED_QTY_RECEIPT   => CurOriginComponents.LOM_ADJUSTED_QTY_RECEIPT
                                                , aLOM_BACK_QTY               => CurOriginComponents.LOM_BACK_QTY
                                                , aLOM_CPT_RECOVER_QTY        => CurOriginComponents.LOM_CPT_RECOVER_QTY
                                                , aLOM_CPT_REJECT_QTY         => CurOriginComponents.LOM_CPT_REJECT_QTY
                                                , aLOM_CPT_TRASH_QTY          => CurOriginComponents.LOM_CPT_TRASH_QTY
                                                , aLOM_EXIT_RECEIPT           => CurOriginComponents.LOM_EXIT_RECEIPT
                                                , aLOM_PT_REJECT_QTY          => CurOriginComponents.LOM_PT_REJECT_QTY
                                                , aLOM_REJECTED_QTY           => CurOriginComponents.LOM_REJECTED_QTY
                                                , aLOM_STOCK_MANAGEMENT       => CurOriginComponents.LOM_STOCK_MANAGEMENT
                                                , aC_KIND_COM                 => CurOriginComponents.C_KIND_COM
                                                , aC_TYPE_COM                 => CurOriginComponents.C_TYPE_COM
                                                 );

        -- MAJ du lien composant
        update FAL_LOT_MATERIAL_LINK
           set LOM_BOM_REQ_QTY = QteBesoinNo
             , LOM_ADJUSTED_QTY = QteSupInf
             , LOM_FULL_REQ_QTY = QteBesoinTotal
             , LOM_CONSUMPTION_QTY = QteConso
             , LOM_NEED_QTY = QteBesoinCPT
             , LOM_MAX_RECEIPT_QTY = QteMaxReceipt
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
         where current of Cur_Origin_Components;

--         AGE20131015 : Dans l'attente d'une gestion complète de l'éclatement des pesées, retour au fonctionnement "initial" (pesées restent sur lot source)
--         FAL_WEIGH_FUNCTION.FAL_WEIGH_SPLIT(iMatLinkID      => CurOriginComponents.FAL_LOT_MATERIAL_LINK_ID
--                                          , iNewMatLinkID   => lNewLinkId
--                                          , iSplitRatio     => lSplitRatio
--                                          , iSession        => aSession
--                                           );

        -- Fermeture du curseur
        close Cur_Origin_Components;
      end if;
    end loop;
  end SplitComponents;

  /**
  * Procedure SplitFalfactoryInOut
  * Description : Mise à jour des entrée-Sorties atelier du lot de fabrication origine
  *               et génération des entrées-sortie atelier pour le lot destination.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSession       : Session oracle
  * @param   aLotTargetID   : Lot Destination
  */
  procedure SplitFalfactoryInOut(aSession in varchar2, aLotTargetID in number, aReturnCode in out integer)
  is
    -- Lecture des Quantités saisies
    cursor Cur_Fal_Component_Link
    is
      select   FCL.*
             , LOM.LOM_SEQ
             , FIN.STM_STOCK_POSITION_ID FIN_STOCK_POSITION_ID
             , LOM.FAL_LOT_MATERIAL_LINK_ID
             , LOM.DIC_COMPONENT_MVT_ID
             , LOM.LOM_MVT_COMMENT
          from FAL_LOT_MAT_LINK_TMP LOM
             , FAL_COMPONENT_LINK FCL
             , FAL_FACTORY_IN FIN
         where LOM.LOM_SESSION = aSession
           and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
           and FCL.FAL_FACTORY_IN_ID = FIN.FAL_FACTORY_IN_ID
           and FCL.FCL_HOLD_QTY > 0
      order by LOM.LOM_SEQ;

    CurFalComponentLink            Cur_Fal_Component_Link%rowtype;
    aLotRefcompl                   FAL_LOT.LOT_REFCOMPL%type;
    aFactoryInPrice                FAL_FACTORY_IN.IN_PRICE%type;
    aLotMaterialLinkId             number;
    nIN_PRICE                      FAL_FACTORY_IN.IN_PRICE%type;
    nSTM_LOCATION_ID               FAL_FACTORY_IN.STM_LOCATION_ID%type;
    nGCO_CHARACTERIZATION_ID       FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
    nGCO_GCO_CHARACTERIZATION_ID   FAL_FACTORY_IN.GCO_GCO_CHARACTERIZATION_ID%type;
    nGCO2_GCO_CHARACTERIZATION_ID  FAL_FACTORY_IN.GCO2_GCO_CHARACTERIZATION_ID%type;
    nGCO3_GCO_CHARACTERIZATION_ID  FAL_FACTORY_IN.GCO3_GCO_CHARACTERIZATION_ID%type;
    nGCO4_GCO_CHARACTERIZATION_ID  FAL_FACTORY_IN.GCO4_GCO_CHARACTERIZATION_ID%type;
    vIN_CHARACTERIZATION_VALUE_1   FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
    vIN_CHARACTERIZATION_VALUE_2   FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_2%type;
    vIN_CHARACTERIZATION_VALUE_3   FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_3%type;
    vIN_CHARACTERIZATION_VALUE_4   FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_4%type;
    vIN_CHARACTERIZATION_VALUE_5   FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_5%type;
    nIN_FULL_TRACABILITY           FAL_FACTORY_IN.IN_FULL_TRACABILITY%type;
    nSTM_STOCK_MOVEMENT_ID         number;
    aErrorCode                     varchar2(4000);
    aErrorMsg                      varchar2(4000);
    aSTM_MOVEMENT_KIND_ID          number;
    nSTM_STOCK_ID                  number;
    nSTM_STOCK_POSITION_ID         number;
    aReversedSTM_STOCK_POSITION_ID number;
    aFloorSTM_LOCATION_ID          number;
    aFloorSTM_STOCK_ID             number;
    aELEMENT_NUMBER1_ID            number;
    aELEMENT_NUMBER2_ID            number;
    aELEMENT_NUMBER3_ID            number;
    lQualityStatusId               STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
  begin
    -- Préparation de la liste des mouvements de stock (et extournes) à effectuer
    FAL_STOCK_MOVEMENT_FUNCTIONS.InitPreparedStockMovement;
    -- Modification ou suppression des appairages dépendant des entrées atelier démontées
    FAL_LOT_DETAIL_FUNCTIONS.UpdateAlignementOnMvtComponent(aSession);

    -- Parcours des quantités saisies
    for CurFalComponentLink in Cur_Fal_Component_Link loop
      -- MAJ de l'entrée atelier du lot origine
      update FAL_FACTORY_IN
         set IN_OUT_QTE = IN_OUT_QTE + CurFalComponentLink.FCL_HOLD_QTY
           , IN_BALANCE = IN_IN_QTE -(IN_OUT_QTE + CurFalComponentLink.FCL_HOLD_QTY)
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where FAL_FACTORY_IN_ID = CurFalComponentLink.FAL_FACTORY_IN_ID;

      -- Création de la sortie atelier sur le lot origine
      aLotRefcompl           := GetLOT_REFCOMPL(CurFalComponentLink.FAL_LOT_ID);
      aFactoryInPrice        := GetIN_PRICE(CurFalComponentLink.FAL_FACTORY_IN_ID);

      insert into FAL_FACTORY_OUT
                  (FAL_FACTORY_OUT_ID
                 , FAL_LOT_ID
                 , OUT_LOT_REFCOMPL
                 , GCO_GOOD_ID
                 , OUT_DATE
                 , STM_LOCATION_ID
                 , C_OUT_ORIGINE
                 , C_OUT_TYPE
                 , OUT_CHARACTERIZATION_VALUE_1
                 , OUT_CHARACTERIZATION_VALUE_2
                 , OUT_CHARACTERIZATION_VALUE_3
                 , OUT_CHARACTERIZATION_VALUE_4
                 , OUT_CHARACTERIZATION_VALUE_5
                 , OUT_PRICE
                 , OUT_QTE
                 , A_IDCRE
                 , A_DATECRE
                  )
           values (GetNewId
                 , CurFalComponentLink.FAL_LOT_ID
                 , aLotRefcompl
                 , CurFalComponentLink.GCO_GOOD_ID
                 , sysdate
                 , null
                 , '8'   -- C_OUT_ORIGINE
                 , '5'   -- C_OUT_TYPE
                 , CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_1
                 , CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_2
                 , CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_3
                 , CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_4
                 , CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_5
                 , aFactoryInPrice
                 , CurFalComponentLink.FCL_HOLD_QTY
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );

      -- Création de l'entrée atelier sur le lot cible.
      aLotMaterialLinkId     := GetMATERIAL_LINK_ID(aLotTargetID, CurFalComponentLink.LOM_SEQ);
      aLotRefCompl           := GetLOT_REFCOMPL(aLotTargetID);
      -- Recherche du genre de mouvement d'entrée composant en atelier (depuis stock)
      aSTM_MOVEMENT_KIND_ID  := FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoWorkshopIn;

      begin
        select FIN.IN_FULL_TRACABILITY
             , FIN.IN_PRICE
             , LOC.STM_STOCK_ID
             , FIN.STM_LOCATION_ID
             , FIN.GCO_CHARACTERIZATION_ID
             , FIN.GCO_GCO_CHARACTERIZATION_ID
             , FIN.GCO2_GCO_CHARACTERIZATION_ID
             , FIN.GCO3_GCO_CHARACTERIZATION_ID
             , FIN.GCO4_GCO_CHARACTERIZATION_ID
             , FIN.IN_CHARACTERIZATION_VALUE_1
             , FIN.IN_CHARACTERIZATION_VALUE_2
             , FIN.IN_CHARACTERIZATION_VALUE_3
             , FIN.IN_CHARACTERIZATION_VALUE_4
             , FIN.IN_CHARACTERIZATION_VALUE_5
             , SMO.STM_STOCK_MOVEMENT_ID
          into nIN_FULL_TRACABILITY
             , nIN_PRICE
             , nSTM_STOCK_ID
             , nSTM_LOCATION_ID
             , nGCO_CHARACTERIZATION_ID
             , nGCO_GCO_CHARACTERIZATION_ID
             , nGCO2_GCO_CHARACTERIZATION_ID
             , nGCO3_GCO_CHARACTERIZATION_ID
             , nGCO4_GCO_CHARACTERIZATION_ID
             , vIN_CHARACTERIZATION_VALUE_1
             , vIN_CHARACTERIZATION_VALUE_2
             , vIN_CHARACTERIZATION_VALUE_3
             , vIN_CHARACTERIZATION_VALUE_4
             , vIN_CHARACTERIZATION_VALUE_5
             , nSTM_STOCK_MOVEMENT_ID
          from FAL_FACTORY_IN FIN
             , STM_STOCK_MOVEMENT SMO
             , STM_LOCATION LOC
         where FIN.FAL_FACTORY_IN_ID = CurFalComponentLink.FAL_FACTORY_IN_ID
           and FIN.FAL_FACTORY_IN_ID = SMO.FAL_FACTORY_IN_ID(+)
           and SMO.STM_MOVEMENT_KIND_ID = aSTM_MOVEMENT_KIND_ID
           and FIN.STM_LOCATION_ID = LOC.STM_LOCATION_ID
           and nvl(SMO.SMO_MOVEMENT_QUANTITY, 0) >= 0;

        -- Si la position n'existe plus en stock atelier on la recrée à null (pour contourner l'erreur de deadlock
        -- du à la transaction autonome de la procedure STM_POSITIONS.InsertNullPosition).
        select STM_LOCATION_ID
             , STM_STOCK_ID
          into aFloorSTM_LOCATION_ID
             , aFloorSTM_STOCK_ID
          from STM_LOCATION
         where LOC_DESCRIPTION = PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_FLOOR')
           and STM_STOCK_ID = (select max(STM_STOCK_ID)
                                 from STM_STOCK
                                where STO_DESCRIPTION = PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_FLOOR') );

        -- Récupération de la position de stock qui va être extournée
        FAL_STOCK_MOVEMENT_FUNCTIONS.GetStockPositionFromCharact(CurFalComponentLink.GCO_GOOD_ID
                                                               , aFloorSTM_STOCK_ID
                                                               , aFloorSTM_LOCATION_ID
                                                               , vIN_CHARACTERIZATION_VALUE_1
                                                               , vIN_CHARACTERIZATION_VALUE_2
                                                               , vIN_CHARACTERIZATION_VALUE_3
                                                               , vIN_CHARACTERIZATION_VALUE_4
                                                               , vIN_CHARACTERIZATION_VALUE_5
                                                               , aReversedSTM_STOCK_POSITION_ID
                                                                );

        -- Récupération de ses STM_ELEMENT_NUMBER
        begin
          select SPO.STM_ELEMENT_NUMBER_ID
               , SPO.STM_STM_ELEMENT_NUMBER_ID
               , SPO.STM2_STM_ELEMENT_NUMBER_ID
               , SEM.GCO_QUALITY_STATUS_ID
            into aELEMENT_NUMBER1_ID
               , aELEMENT_NUMBER2_ID
               , aELEMENT_NUMBER3_ID
               , lQualityStatusId
            from STM_STOCK_POSITION SPO
               , STM_ELEMENT_NUMBER SEM
           where SPO.STM_STOCK_POSITION_ID = aReversedSTM_STOCK_POSITION_ID
             and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+);
        exception
          when others then
            begin
              aELEMENT_NUMBER1_ID  := null;
              aELEMENT_NUMBER2_ID  := null;
              aELEMENT_NUMBER3_ID  := null;
            end;
        end;

        -- Effectuer l'extourne du mouvement origine.
        FAL_STOCK_MOVEMENT_FUNCTIONS.GenReversalMvt(nSTM_STOCK_MOVEMENT_ID, CurFalComponentLink.FCL_HOLD_QTY);
        -- Recherche de la postion correspondante en atelier
        FAL_STOCK_MOVEMENT_FUNCTIONS.GetStockPositionFromCharact(CurFalComponentLink.GCO_GOOD_ID
                                                               , aFloorSTM_STOCK_ID
                                                               , aFloorSTM_LOCATION_ID
                                                               , vIN_CHARACTERIZATION_VALUE_1
                                                               , vIN_CHARACTERIZATION_VALUE_2
                                                               , vIN_CHARACTERIZATION_VALUE_3
                                                               , vIN_CHARACTERIZATION_VALUE_4
                                                               , vIN_CHARACTERIZATION_VALUE_5
                                                               , aReversedSTM_STOCK_POSITION_ID
                                                                );

        -- Si non trouvée, alors on la recrée
        if nvl(aReversedSTM_STOCK_POSITION_ID, 0) = 0 then
          STM_I_PRC_STOCK_POSITION.InsertNullPosition(aFloorSTM_STOCK_ID
                                                    , aFloorSTM_LOCATION_ID
                                                    , CurFalComponentLink.GCO_GOOD_ID
                                                    , nGCO_CHARACTERIZATION_ID
                                                    , nGCO_GCO_CHARACTERIZATION_ID
                                                    , nGCO2_GCO_CHARACTERIZATION_ID
                                                    , nGCO3_GCO_CHARACTERIZATION_ID
                                                    , nGCO4_GCO_CHARACTERIZATION_ID
                                                    , vIN_CHARACTERIZATION_VALUE_1
                                                    , vIN_CHARACTERIZATION_VALUE_2
                                                    , vIN_CHARACTERIZATION_VALUE_3
                                                    , vIN_CHARACTERIZATION_VALUE_4
                                                    , vIN_CHARACTERIZATION_VALUE_5
                                                    , aELEMENT_NUMBER1_ID
                                                    , aELEMENT_NUMBER2_ID
                                                    , aELEMENT_NUMBER3_ID
                                                    , STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodID    => CurFalComponentLink.GCO_GOOD_ID
                                                                                              , iDetail1   => aELEMENT_NUMBER1_ID
                                                                                              , iDetail2   => aELEMENT_NUMBER2_ID
                                                                                              , iDetail3   => aELEMENT_NUMBER3_ID
                                                                                               )
                                                     );
        end if;

        -- Récupération de la position nouvellement rentrée en stock
        FAL_STOCK_MOVEMENT_FUNCTIONS.GetStockPositionFromCharact(CurFalComponentLink.GCO_GOOD_ID
                                                               , nSTM_STOCK_ID
                                                               , nSTM_LOCATION_ID
                                                               , vIN_CHARACTERIZATION_VALUE_1
                                                               , vIN_CHARACTERIZATION_VALUE_2
                                                               , vIN_CHARACTERIZATION_VALUE_3
                                                               , vIN_CHARACTERIZATION_VALUE_4
                                                               , vIN_CHARACTERIZATION_VALUE_5
                                                               , nSTM_STOCK_POSITION_ID
                                                                );
        -- Création des sorties atelier pour l'of destination ainsi que de ses mouvements associés
        FAL_COMPONENT_FUNCTIONS.CreateFactoryMovement(aFAL_LOT_ID                 => aLotTargetID
                                                    , aMATERIAL_LINK_ID           => aLotMaterialLinkId
                                                    , aGCO_GOOD_ID                => CurFalComponentLink.GCO_GOOD_ID
                                                    , aSTM_STOCK_POSITION_ID      => nSTM_STOCK_POSITION_ID
                                                    , aSTM_STOCK_ID               => null
                                                    , aSTM_LOCATION_ID            => nSTM_LOCATION_ID
                                                    , aOUT_QUANTITY               => CurFalComponentLink.FCL_HOLD_QTY
                                                    , aLOT_REFCOMPL               => aLotRefCompl
                                                    , aLOM_PRICE                  => nIN_PRICE
                                                    , aPreparedStockMovements     => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                    , aFAL_COMPONENT_LINK_ID      => null
                                                    , aOUT_DATE                   => sysdate
                                                    , aMvtKind                    => FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier
                                                    , aGCO_CHARACTERIZATION1_ID   => nGCO_CHARACTERIZATION_ID
                                                    , aGCO_CHARACTERIZATION2_ID   => nGCO_GCO_CHARACTERIZATION_ID
                                                    , aGCO_CHARACTERIZATION3_ID   => nGCO2_GCO_CHARACTERIZATION_ID
                                                    , aGCO_CHARACTERIZATION4_ID   => nGCO3_GCO_CHARACTERIZATION_ID
                                                    , aGCO_CHARACTERIZATION5_ID   => nGCO4_GCO_CHARACTERIZATION_ID
                                                    , aCHARACT_VALUE1             => vIN_CHARACTERIZATION_VALUE_1
                                                    , aCHARACT_VALUE2             => vIN_CHARACTERIZATION_VALUE_2
                                                    , aCHARACT_VALUE3             => vIN_CHARACTERIZATION_VALUE_3
                                                    , aCHARACT_VALUE4             => vIN_CHARACTERIZATION_VALUE_4
                                                    , aCHARACT_VALUE5             => vIN_CHARACTERIZATION_VALUE_5
                                                    , aC_IN_ORIGINE               => '6'   -- Eclatement
                                                    , aC_OUT_ORIGINE              => null
                                                    , aC_OUT_TYPE                 => null
                                                    , aFAL_NETWORK_LINK_ID        => null
                                                    , aContext                    => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                                    , aDIC_COMPONENT_MVT_ID       => CurFalComponentLink.DIC_COMPONENT_MVT_ID
                                                    , aLOM_MVT_COMMENT            => CurFalComponentLink.LOM_MVT_COMMENT
                                                    , aFAL_LOT_MAT_LINK_TMP_ID    => CurFalComponentLink.FAL_LOT_MAT_LINK_TMP_ID
                                                    , aFactoryInOriginId          => null
                                                    , aSessionId                  => aSession
                                                     );
      exception
        when no_data_found then
          begin
            aReturnCode  := cdenoOriginMovement;
          end;
        when others then
          raise;
      end;
    end loop;

    -- Génération des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                           , aErrorCode
                                                           , aErrorMsg
                                                           , FAL_STOCK_MOVEMENT_FUNCTIONS.ctxBatchSplitting
                                                           , 0
                                                            );
    -- Mise à jour des Entrées Atelier avec les positions de stock créées dans le stock Atelier par les mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements);
  end SplitFalfactoryInOut;

  function GetOperationId(aFalLotId FAL_LOT.FAL_LOT_ID%type, aSequence FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  is
    aFalScheduleStepId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    select FAL_SCHEDULE_STEP_ID
      into aFalScheduleStepId
      from FAL_TASK_LINK
     where FAL_LOT_ID = aFalLotId
       and SCS_STEP_NUMBER = aSequence;

    return aFalScheduleStepId;
  exception
    when no_data_found then
      raise_application_error(-20000, 'No operation with sequence ' || aSequence || ' for batch Id ' || aFalLotId);
  end;

  procedure UpdateBatchQty(aLotTargetId number, aLotOriginId number, aNewQty number, aQtySup number)
  is
    lError varchar2(4000);
  begin
    FAL_TASK_GENERATOR.UpdateBatchQty(aFalLotId      => aLotTargetId
                                    , aNewTotalQty   => aNewQty
                                    , oError         => lError
                                    , iContext       => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                     );

    update FAL_LOT_MATERIAL_LINK
       set LOM_BOM_REQ_QTY = LOM_BOM_REQ_QTY + aQtySup
         , LOM_ADJUSTED_QTY = LOM_ADJUSTED_QTY - aQtySup
     where FAL_LOT_ID = aLotOriginId
       and C_TYPE_COM = '1'
       and C_KIND_COM = '1'
       and LOM_STOCK_MANAGEMENT = 1;

    update FAL_LOT_MATERIAL_LINK
       set LOM_BOM_REQ_QTY = LOM_BOM_REQ_QTY - aQtySup
         , LOM_ADJUSTED_QTY = LOM_ADJUSTED_QTY + aQtySup
     where FAL_LOT_ID = aLotTargetId
       and C_TYPE_COM = '1'
       and C_KIND_COM = '1'
       and LOM_STOCK_MANAGEMENT = 1;

    update FAL_LOT
       set LOT_ASKED_QTY = aNewQty
         , LOT_TOTAL_QTY = LOT_REJECT_PLAN_QTY + aNewQty
         , LOT_INPROD_QTY = LOT_REJECT_PLAN_QTY + aNewQty
         , LOT_RELEASE_QTY = case C_LOT_STATUS
                              when '1' then 0
                              else LOT_REJECT_PLAN_QTY + aNewQty
                            end
     where FAL_LOT_ID = aLotTargetId;
  end;

  /**
  * Procedure SplitProcessTrack
  * Description : Report du suivi de fabrication
  * @created CLE
  * @lastUpdate age 06.11.2013
  * @public
  * @param iOriginOPSeq   : Séquence op origine
  * @param iLotOriginID   : Lot origine
  * @param iLotTargetID   : Lot cible
  * @param iTransferedQty : Qté transférée
  * @param iSession       : Session Oracle
  */
  procedure SplitProcessTrack(
    iOriginOPSeq         in FAL_TASK_LINK.SCS_STEP_NUMBER%type
  , iLotOriginID         in FAL_LOT.FAL_LOT_ID%type
  , iLotTargetID         in FAL_LOT.FAL_LOT_ID%type
  , iTransferedQty       in FAL_LOT.LOT_INPROD_QTY%type
  , iSession             in varchar2
  , iTransferRealisedQty in integer
  )
  is
    cursor crProgressTracking
    is
      /* Si le lot a déjà été éclaté, on a perdu le lien entre les documents de sous-traitance et l'opération. On ne peut donc plus remonter sur ces documents pour
         connaitre la quantité correspondant au montant facturé (PDE_BASIS_QUANTITY ci-dessous). On utilise alors FLP_SUBCONTRACT_QTY. Cette quantité sera mise à jour
         sur les suivis. Depuis PDE_BASIS_QUANTITY lors de l'éclatement sur un premier OF (avec opération directement lié aux documents), puis par éclatements successifs. */
      select   FLP_SEQ
             , nvl(FLP_PT_REJECT_QTY, 0) FLP_PT_REJECT_QTY
             , nvl(FLP_CPT_REJECT_QTY, 0) FLP_CPT_REJECT_QTY
             , nvl(FLP_PRODUCT_QTY, 0) FLP_PRODUCT_QTY
             , case nvl(FLP_SUBCONTRACT_QTY, 0)
                 when 0 then nvl( (select distinct nvl(DET.PDE_BASIS_QUANTITY_SU, DET.PDE_BASIS_QUANTITY) PDE_BASIS_QUANTITY
                                              from DOC_DOCUMENT DOC
                                                 , DOC_POSITION POS
                                                 , DOC_POSITION_DETAIL DET
                                                 , DOC_GAUGE GAU
                                             where POS.FAL_SCHEDULE_STEP_ID = FLP.FAL_SCHEDULE_STEP_ID
                                               and POS.DOC_POSITION_ID = DET.DOC_POSITION_ID
                                               and POS.C_GAUGE_TYPE_POS = '1'
                                               and GAU.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
                                               and instr(',A-FST,', ',' || GAU.DIC_GAUGE_TYPE_DOC_ID || ',') > 0
                                               and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                                               and DOC.DMT_NUMBER = FLP.FLP_LABEL_CONTROL
                                               and DET.PDE_MOVEMENT_VALUE = FLP.FLP_AMOUNT)
                               , 0
                                )
                 else FLP_SUBCONTRACT_QTY
               end PDE_BASIS_QUANTITY
             , FAL_LOT_PROGRESS_ID
             , FAL_SCHEDULE_STEP_ID
             , FLP_DATE1
             , FAL_FACTORY_FLOOR_ID
             , FAL_FAL_FACTORY_FLOOR_ID
             , FLP_RATE
             , FLP_ADJUSTING_RATE
             , PPS_OPERATION_PROCEDURE_ID
             , PPS_PPS_OPERATION_PROCEDURE_ID
             , PPS_TOOLS1_ID
             , PPS_TOOLS2_ID
             , PPS_TOOLS3_ID
             , PPS_TOOLS4_ID
             , PPS_TOOLS5_ID
             , PPS_TOOLS6_ID
             , PPS_TOOLS7_ID
             , PPS_TOOLS8_ID
             , PPS_TOOLS9_ID
             , PPS_TOOLS10_ID
             , PPS_TOOLS11_ID
             , PPS_TOOLS12_ID
             , PPS_TOOLS13_ID
             , PPS_TOOLS14_ID
             , PPS_TOOLS15_ID
             , DIC_OPERATOR_ID
             , DIC_REBUT_ID
             , DIC_WORK_TYPE_ID
             , nvl(FLP_SUP_QTY, 0) FLP_SUP_QTY
             , nvl(FLP_WORK_TIME, 0) FLP_WORK_TIME
             , nvl(FLP_ADJUSTING_TIME, 0) FLP_ADJUSTING_TIME
             , nvl(FLP_AMOUNT, 0) FLP_AMOUNT
             , FLP_EAN_CODE
             , nvl(FLP_PRODUCT_QTY_UOP, 0) FLP_PRODUCT_QTY_UOP
             , nvl(FLP_PT_REJECT_QTY_UOP, 0) FLP_PT_REJECT_QTY_UOP
             , nvl(FLP_CPT_REJECT_QTY_UOP, 0) FLP_CPT_REJECT_QTY_UOP
             , nvl(FLP_CONVERSION_FACTOR, 0) FLP_CONVERSION_FACTOR
             , FLP_LABEL_CONTROL
             , FLP_LABEL_REJECT
             , FLP_MANUAL
             , A_IDCRE
             , A_DATECRE
          from FAL_LOT_PROGRESS FLP
         where FAL_LOT_ID = iLotOriginID
           and FLP_REVERSAL = 0
      order by FLP_SEQ
             , FLP_PT_REJECT_QTY
             , FLP_CPT_REJECT_QTY
             , FLP_PRODUCT_QTY desc
             , PDE_BASIS_QUANTITY desc;

    type TcrProgressTracking is table of crProgressTracking%rowtype;

    tplProgressTracking     TcrProgressTracking;
    lCurrentOpeSeq          FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    lQtyToReport            number;
    lLotProgressID          number;
    lTargetQty              number;
    lRatio                  number;
    lErrorMsg               varchar2(4000);
    nLotTotalQtyBatchOrigin number;
    bIsSubContractInvoice   boolean;
    nProductQty             number;
    nQtySup                 number;
    nTransferedQty          number;
    bTransferQtySup         boolean;
  begin
    lCurrentOpeSeq           := 0;
    bIsSubContractInvoice    := false;

    -- Sauvegarde de tous les suivis effectués sur le lot d'origine
    open crProgressTracking;

    fetch crProgressTracking
    bulk collect into tplProgressTracking;

    close crProgressTracking;

    select min(FAL_LOT_PROGRESS_ID)
      into lLotProgressID
      from FAL_LOT_PROGRESS
     where FAL_LOT_ID = iLotOriginID;

    select nvl(sum(FLP_SUP_QTY), 0)
      into nQtySup
      from FAL_LOT_PROGRESS
     where FAL_LOT_ID = iLotOriginID
       and FLP_REVERSAL = 0
       and (    (    iTransferRealisedQty = 0
                 and FLP_SEQ < nvl(iOriginOpSeq, 0) )
            or (    iTransferRealisedQty = 1
                and FLP_SEQ <= nvl(iOriginOpSeq, 0) ) );

    -- Suppression de tous les suivis du lot d'origine
    FAL_SUIVI_OPERATION.DeleteProcessTracking(aFalLotId           => iLotOriginID
                                            , aFalLotProgressId   => lLotProgressID
                                            , aContext            => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                             );
    nLotTotalQtyBatchOrigin  := GetLOT_TOTAL_QTY(iLotID => iLotOriginID);
    bTransferQtySup          := false;

    -- Si la quantité à transférer est supérieure à la quantité du lot avant suivi,
    -- la quantité supplémentaire est transférée sur la cible
    if iTransferedQty > nLotTotalQtyBatchOrigin then
      nTransferedQty   := iTransferedQty - nQtySup;
      bTransferQtySup  := true;
      UpdateBatchQty(aLotTargetId => iLotTargetId, aLotOriginId => iLotOriginId, aNewQty => nTransferedQty, aQtySup => nQtySup);
    else
      nTransferedQty  := iTransferedQty;
    end if;

    nQtySup                  := 0;
    -- Mise à jour de la quantité des opérations du lot d'origine
    -- (cette mise à jour doit être faite entre la suppression des suivis et la re-création de ceux-ci)
    FAL_TASK_GENERATOR.UpdateBatchQty(aFalLotId      => iLotOriginID
                                    , aNewTotalQty   => nLotTotalQtyBatchOrigin - nTransferedQty
                                    , oError         => lErrorMsg
                                    , iContext       => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                     );

    if (tplProgressTracking.count > 0) then
      for i in tplProgressTracking.first .. tplProgressTracking.last loop
        if    (lCurrentOpeSeq <> tplProgressTracking(i).FLP_SEQ)
           or (bIsSubContractInvoice <>(     (tplProgressTracking(i).PDE_BASIS_QUANTITY > 0)
                                        and (tplProgressTracking(i).FLP_PRODUCT_QTY = 0) ) ) then
          lCurrentOpeSeq         := tplProgressTracking(i).FLP_SEQ;
          bIsSubContractInvoice  :=     (tplProgressTracking(i).PDE_BASIS_QUANTITY > 0)
                                    and (tplProgressTracking(i).FLP_PRODUCT_QTY = 0);

          -- Changement d'opération. Si la nouvelle opération est la dernière du lot ou précède l'opération d'origine du split, on reporte du suivi dessus.
          if    (    iTransferRealisedQty = 0
                 and (nvl(iOriginOpSeq, 0) > tplProgressTracking(i).FLP_SEQ) )
             or (    iTransferRealisedQty = 1
                 and (nvl(iOriginOpSeq, 0) >= tplProgressTracking(i).FLP_SEQ) ) then
            if bTransferQtySup then
              nQtySup       := nQtySup + tplProgressTracking(i).FLP_SUP_QTY;
              lQtyToReport  := nTransferedQty + nQtySup;
            else
              lQtyToReport  := nTransferedQty;
            end if;
          else
            lQtyToReport  := 0;
          end if;
        end if;

        -- PDE_BASIS_QUANTITY sert à reporter les suivis correspondant au prix de la sous-traitance (venant d'une FST).
        -- Ce type de suivi peut être d'une quantité de 0 mais il faut reporter le montant.
        if bIsSubContractInvoice then
          nProductQty  := tplProgressTracking(i).FLP_PRODUCT_QTY + tplProgressTracking(i).PDE_BASIS_QUANTITY;
        else
          nProductQty  := tplProgressTracking(i).FLP_PRODUCT_QTY;
        end if;

        /* La quantité du suivi est < que la quantité à reporter et ne contient pas de rebut --> Report intégral sur le lot cible */
        if     (lQtyToReport > 0)
           and (lQtyToReport >= nProductQty)
           and (tplProgressTracking(i).FLP_PT_REJECT_QTY = 0)
           and (tplProgressTracking(i).FLP_CPT_REJECT_QTY = 0) then
          -- Report du suivi sur le lot cible
          FAL_SUIVI_OPERATION.AddProcessTracking(aFalScheduleStepId            => GetOperationId(iLotTargetID, tplProgressTracking(i).FLP_SEQ)
                                               , aFlpDate1                     => tplProgressTracking(i).FLP_DATE1
                                               , aFlpProductQty                => tplProgressTracking(i).FLP_PRODUCT_QTY
                                               , aFlpPtRejectQty               => 0
                                               , aFlpCptRejectQty              => 0
                                               , aFlpSupQty                    => case bTransferQtySup
                                                   when true then tplProgressTracking(i).FLP_SUP_QTY
                                                   else 0
                                                 end
                                               , aFlpAdjustingTime             => tplProgressTracking(i).FLP_ADJUSTING_TIME
                                               , aFlpWorkTime                  => tplProgressTracking(i).FLP_WORK_TIME
                                               , aFlpAmount                    => tplProgressTracking(i).FLP_AMOUNT
                                               , aFalFactoryFloorId            => tplProgressTracking(i).FAL_FACTORY_FLOOR_ID
                                               , aFalFalFactoryFloorId         => tplProgressTracking(i).FAL_FAL_FACTORY_FLOOR_ID
                                               , aDicWorkTypeId                => tplProgressTracking(i).DIC_WORK_TYPE_ID
                                               , aDicOperatorId                => tplProgressTracking(i).DIC_OPERATOR_ID
                                               , aDicRebutId                   => tplProgressTracking(i).DIC_REBUT_ID
                                               , aFlpRate                      => tplProgressTracking(i).FLP_RATE
                                               , aFlpAdjustingRate             => tplProgressTracking(i).FLP_ADJUSTING_RATE
                                               , aFlpEanCode                   => tplProgressTracking(i).FLP_EAN_CODE
                                               , aPpsTools1Id                  => tplProgressTracking(i).PPS_TOOLS1_ID
                                               , aPpsTools2Id                  => tplProgressTracking(i).PPS_TOOLS2_ID
                                               , aPpsTools3Id                  => tplProgressTracking(i).PPS_TOOLS3_ID
                                               , aPpsTools4Id                  => tplProgressTracking(i).PPS_TOOLS4_ID
                                               , aPpsTools5Id                  => tplProgressTracking(i).PPS_TOOLS5_ID
                                               , aPpsTools6Id                  => tplProgressTracking(i).PPS_TOOLS6_ID
                                               , aPpsTools7Id                  => tplProgressTracking(i).PPS_TOOLS7_ID
                                               , aPpsTools8Id                  => tplProgressTracking(i).PPS_TOOLS8_ID
                                               , aPpsTools9Id                  => tplProgressTracking(i).PPS_TOOLS9_ID
                                               , aPpsTools10Id                 => tplProgressTracking(i).PPS_TOOLS10_ID
                                               , aPpsTools11Id                 => tplProgressTracking(i).PPS_TOOLS11_ID
                                               , aPpsTools12Id                 => tplProgressTracking(i).PPS_TOOLS12_ID
                                               , aPpsTools13Id                 => tplProgressTracking(i).PPS_TOOLS13_ID
                                               , aPpsTools14Id                 => tplProgressTracking(i).PPS_TOOLS14_ID
                                               , aPpsTools15Id                 => tplProgressTracking(i).PPS_TOOLS15_ID
                                               , aPpsOperationProcedureId      => tplProgressTracking(i).PPS_OPERATION_PROCEDURE_ID
                                               , aPpsPpsOperationProcedureId   => tplProgressTracking(i).PPS_PPS_OPERATION_PROCEDURE_ID
                                               , aFlpLabelControl              => null
                                               , aFlpLabelReject               => null
                                               , aFlpProductQtyUop             => tplProgressTracking(i).FLP_PRODUCT_QTY_UOP
                                               , aFlpPtRejectQtyUop            => 0
                                               , aFlpCptRejectQtyUop           => 0
                                               , aManualProgressTrack          => tplProgressTracking(i).FLP_MANUAL
                                               , aSessionId                    => iSession
                                               , aErrorMsg                     => lErrorMsg
                                               , aContext                      => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                               , aAIdcre                       => tplProgressTracking(i).A_IDCRE
                                               , aADatecre                     => tplProgressTracking(i).A_DATECRE
                                               , aFlpSubcontractQty            => tplProgressTracking(i).PDE_BASIS_QUANTITY
                                                );
          lQtyToReport  := lQtyToReport - nProductQty;
        /*    La quantité du suivi contient du rebut ou n'est pas < que la quantité à reporté. Il reste de la quantité à reporter. --> Répartition
              proportionnelle de la quantité et des temps.
           OU la quantité du suivi (y compris rebut) = 0. --> Répartition des temps */
        elsif     lQtyToReport > 0
              and (    (nProductQty > 0)
                   or (     (nProductQty + tplProgressTracking(i).FLP_PT_REJECT_QTY + tplProgressTracking(i).FLP_CPT_REJECT_QTY = 0)
                       and not bIsSubContractInvoice)
                  ) then
          -- Report du suivi au prorata des quantités sur les lots sources et cibles
          lTargetQty    := least(lQtyToReport, nProductQty);

          if (     (lQtyToReport > 0)
              and (nProductQty > 0) ) then
            lRatio  := lTargetQty /(nProductQty + tplProgressTracking(i).FLP_PT_REJECT_QTY + tplProgressTracking(i).FLP_CPT_REJECT_QTY);
          else
            lRatio  := nTransferedQty /(nLotTotalQtyBatchOrigin + nQtySup);
          end if;

          lQtyToReport  := lQtyToReport - lTargetQty;

          if bIsSubContractInvoice then
            lTargetQty  := 0;
          end if;

          -- Report sur le lot cible
          FAL_SUIVI_OPERATION.AddProcessTracking(aFalScheduleStepId            => GetOperationId(iLotTargetID, tplProgressTracking(i).FLP_SEQ)
                                               , aFlpDate1                     => tplProgressTracking(i).FLP_DATE1
                                               , aFlpProductQty                => lTargetQty
                                               , aFlpPtRejectQty               => 0
                                               , aFlpCptRejectQty              => 0
                                               , aFlpSupQty                    => case bTransferQtySup
                                                   when true then tplProgressTracking(i).FLP_SUP_QTY
                                                   else 0
                                                 end
                                               , aFlpAdjustingTime             => tplProgressTracking(i).FLP_ADJUSTING_TIME * lRatio
                                               , aFlpWorkTime                  => tplProgressTracking(i).FLP_WORK_TIME * lRatio
                                               , aFlpAmount                    => tplProgressTracking(i).FLP_AMOUNT * lRatio
                                               , aFalFactoryFloorId            => tplProgressTracking(i).FAL_FACTORY_FLOOR_ID
                                               , aFalFalFactoryFloorId         => tplProgressTracking(i).FAL_FAL_FACTORY_FLOOR_ID
                                               , aDicWorkTypeId                => tplProgressTracking(i).DIC_WORK_TYPE_ID
                                               , aDicOperatorId                => tplProgressTracking(i).DIC_OPERATOR_ID
                                               , aDicRebutId                   => tplProgressTracking(i).DIC_REBUT_ID
                                               , aFlpRate                      => tplProgressTracking(i).FLP_RATE
                                               , aFlpAdjustingRate             => tplProgressTracking(i).FLP_ADJUSTING_RATE
                                               , aFlpEanCode                   => tplProgressTracking(i).FLP_EAN_CODE
                                               , aPpsTools1Id                  => tplProgressTracking(i).PPS_TOOLS1_ID
                                               , aPpsTools2Id                  => tplProgressTracking(i).PPS_TOOLS2_ID
                                               , aPpsTools3Id                  => tplProgressTracking(i).PPS_TOOLS3_ID
                                               , aPpsTools4Id                  => tplProgressTracking(i).PPS_TOOLS4_ID
                                               , aPpsTools5Id                  => tplProgressTracking(i).PPS_TOOLS5_ID
                                               , aPpsTools6Id                  => tplProgressTracking(i).PPS_TOOLS6_ID
                                               , aPpsTools7Id                  => tplProgressTracking(i).PPS_TOOLS7_ID
                                               , aPpsTools8Id                  => tplProgressTracking(i).PPS_TOOLS8_ID
                                               , aPpsTools9Id                  => tplProgressTracking(i).PPS_TOOLS9_ID
                                               , aPpsTools10Id                 => tplProgressTracking(i).PPS_TOOLS10_ID
                                               , aPpsTools11Id                 => tplProgressTracking(i).PPS_TOOLS11_ID
                                               , aPpsTools12Id                 => tplProgressTracking(i).PPS_TOOLS12_ID
                                               , aPpsTools13Id                 => tplProgressTracking(i).PPS_TOOLS13_ID
                                               , aPpsTools14Id                 => tplProgressTracking(i).PPS_TOOLS14_ID
                                               , aPpsTools15Id                 => tplProgressTracking(i).PPS_TOOLS15_ID
                                               , aPpsOperationProcedureId      => tplProgressTracking(i).PPS_OPERATION_PROCEDURE_ID
                                               , aPpsPpsOperationProcedureId   => tplProgressTracking(i).PPS_PPS_OPERATION_PROCEDURE_ID
                                               , aFlpLabelControl              => null
                                               , aFlpLabelReject               => null
                                               , aFlpProductQtyUop             => lTargetQty * tplProgressTracking(i).FLP_CONVERSION_FACTOR
                                               , aFlpPtRejectQtyUop            => 0
                                               , aFlpCptRejectQtyUop           => 0
                                               , aManualProgressTrack          => tplProgressTracking(i).FLP_MANUAL
                                               , aSessionId                    => iSession
                                               , aErrorMsg                     => lErrorMsg
                                               , aContext                      => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                               , aAIdcre                       => tplProgressTracking(i).A_IDCRE
                                               , aADatecre                     => tplProgressTracking(i).A_DATECRE
                                               , aFlpSubcontractQty            => tplProgressTracking(i).PDE_BASIS_QUANTITY * lRatio
                                                );
            -- Report sur le lot source
          -- Report du suivi sur le lot source
          FAL_SUIVI_OPERATION.AddProcessTracking(aFalScheduleStepId            => tplProgressTracking(i).FAL_SCHEDULE_STEP_ID
                                               , aFlpDate1                     => tplProgressTracking(i).FLP_DATE1
                                               , aFlpProductQty                => tplProgressTracking(i).FLP_PRODUCT_QTY - lTargetQty
                                               , aFlpPtRejectQty               => tplProgressTracking(i).FLP_PT_REJECT_QTY
                                               , aFlpCptRejectQty              => tplProgressTracking(i).FLP_CPT_REJECT_QTY
                                               , aFlpSupQty                    => case bTransferQtySup
                                                   when true then 0
                                                   else tplProgressTracking(i).FLP_SUP_QTY
                                                 end
                                               , aFlpAdjustingTime             => tplProgressTracking(i).FLP_ADJUSTING_TIME *(1 - lRatio)
                                               , aFlpWorkTime                  => tplProgressTracking(i).FLP_WORK_TIME *(1 - lRatio)
                                               , aFlpAmount                    => tplProgressTracking(i).FLP_AMOUNT *(1 - lRatio)
                                               , aFalFactoryFloorId            => tplProgressTracking(i).FAL_FACTORY_FLOOR_ID
                                               , aFalFalFactoryFloorId         => tplProgressTracking(i).FAL_FAL_FACTORY_FLOOR_ID
                                               , aDicWorkTypeId                => tplProgressTracking(i).DIC_WORK_TYPE_ID
                                               , aDicOperatorId                => tplProgressTracking(i).DIC_OPERATOR_ID
                                               , aDicRebutId                   => tplProgressTracking(i).DIC_REBUT_ID
                                               , aFlpRate                      => tplProgressTracking(i).FLP_RATE
                                               , aFlpAdjustingRate             => tplProgressTracking(i).FLP_ADJUSTING_RATE
                                               , aFlpEanCode                   => tplProgressTracking(i).FLP_EAN_CODE
                                               , aPpsTools1Id                  => tplProgressTracking(i).PPS_TOOLS1_ID
                                               , aPpsTools2Id                  => tplProgressTracking(i).PPS_TOOLS2_ID
                                               , aPpsTools3Id                  => tplProgressTracking(i).PPS_TOOLS3_ID
                                               , aPpsTools4Id                  => tplProgressTracking(i).PPS_TOOLS4_ID
                                               , aPpsTools5Id                  => tplProgressTracking(i).PPS_TOOLS5_ID
                                               , aPpsTools6Id                  => tplProgressTracking(i).PPS_TOOLS6_ID
                                               , aPpsTools7Id                  => tplProgressTracking(i).PPS_TOOLS7_ID
                                               , aPpsTools8Id                  => tplProgressTracking(i).PPS_TOOLS8_ID
                                               , aPpsTools9Id                  => tplProgressTracking(i).PPS_TOOLS9_ID
                                               , aPpsTools10Id                 => tplProgressTracking(i).PPS_TOOLS10_ID
                                               , aPpsTools11Id                 => tplProgressTracking(i).PPS_TOOLS11_ID
                                               , aPpsTools12Id                 => tplProgressTracking(i).PPS_TOOLS12_ID
                                               , aPpsTools13Id                 => tplProgressTracking(i).PPS_TOOLS13_ID
                                               , aPpsTools14Id                 => tplProgressTracking(i).PPS_TOOLS14_ID
                                               , aPpsTools15Id                 => tplProgressTracking(i).PPS_TOOLS15_ID
                                               , aPpsOperationProcedureId      => tplProgressTracking(i).PPS_OPERATION_PROCEDURE_ID
                                               , aPpsPpsOperationProcedureId   => tplProgressTracking(i).PPS_PPS_OPERATION_PROCEDURE_ID
                                               , aFlpLabelControl              => tplProgressTracking(i).FLP_LABEL_CONTROL
                                               , aFlpLabelReject               => tplProgressTracking(i).FLP_LABEL_REJECT
                                               , aFlpProductQtyUop             => (tplProgressTracking(i).FLP_PRODUCT_QTY - lTargetQty) *
                                                                                  tplProgressTracking(i).FLP_CONVERSION_FACTOR
                                               , aFlpPtRejectQtyUop            => tplProgressTracking(i).FLP_PT_REJECT_QTY_UOP
                                               , aFlpCptRejectQtyUop           => tplProgressTracking(i).FLP_CPT_REJECT_QTY_UOP
                                               , aManualProgressTrack          => tplProgressTracking(i).FLP_MANUAL
                                               , aSessionId                    => iSession
                                               , aErrorMsg                     => lErrorMsg
                                               , aContext                      => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                               , aAIdcre                       => tplProgressTracking(i).A_IDCRE
                                               , aADatecre                     => tplProgressTracking(i).A_DATECRE
                                               , aFlpSubcontractQty            => tplProgressTracking(i).PDE_BASIS_QUANTITY *(1 - lRatio)
                                                );
        /* Sinon, report sur le lot source */
        else
          -- Report du suivi sur le lot source
          FAL_SUIVI_OPERATION.AddProcessTracking(aFalScheduleStepId            => tplProgressTracking(i).FAL_SCHEDULE_STEP_ID
                                               , aFlpDate1                     => tplProgressTracking(i).FLP_DATE1
                                               , aFlpProductQty                => tplProgressTracking(i).FLP_PRODUCT_QTY
                                               , aFlpPtRejectQty               => tplProgressTracking(i).FLP_PT_REJECT_QTY
                                               , aFlpCptRejectQty              => tplProgressTracking(i).FLP_CPT_REJECT_QTY
                                               , aFlpSupQty                    => tplProgressTracking(i).FLP_SUP_QTY
                                               , aFlpAdjustingTime             => tplProgressTracking(i).FLP_ADJUSTING_TIME
                                               , aFlpWorkTime                  => tplProgressTracking(i).FLP_WORK_TIME
                                               , aFlpAmount                    => tplProgressTracking(i).FLP_AMOUNT
                                               , aFalFactoryFloorId            => tplProgressTracking(i).FAL_FACTORY_FLOOR_ID
                                               , aFalFalFactoryFloorId         => tplProgressTracking(i).FAL_FAL_FACTORY_FLOOR_ID
                                               , aDicWorkTypeId                => tplProgressTracking(i).DIC_WORK_TYPE_ID
                                               , aDicOperatorId                => tplProgressTracking(i).DIC_OPERATOR_ID
                                               , aDicRebutId                   => tplProgressTracking(i).DIC_REBUT_ID
                                               , aFlpRate                      => tplProgressTracking(i).FLP_RATE
                                               , aFlpAdjustingRate             => tplProgressTracking(i).FLP_ADJUSTING_RATE
                                               , aFlpEanCode                   => tplProgressTracking(i).FLP_EAN_CODE
                                               , aPpsTools1Id                  => tplProgressTracking(i).PPS_TOOLS1_ID
                                               , aPpsTools2Id                  => tplProgressTracking(i).PPS_TOOLS2_ID
                                               , aPpsTools3Id                  => tplProgressTracking(i).PPS_TOOLS3_ID
                                               , aPpsTools4Id                  => tplProgressTracking(i).PPS_TOOLS4_ID
                                               , aPpsTools5Id                  => tplProgressTracking(i).PPS_TOOLS5_ID
                                               , aPpsTools6Id                  => tplProgressTracking(i).PPS_TOOLS6_ID
                                               , aPpsTools7Id                  => tplProgressTracking(i).PPS_TOOLS7_ID
                                               , aPpsTools8Id                  => tplProgressTracking(i).PPS_TOOLS8_ID
                                               , aPpsTools9Id                  => tplProgressTracking(i).PPS_TOOLS9_ID
                                               , aPpsTools10Id                 => tplProgressTracking(i).PPS_TOOLS10_ID
                                               , aPpsTools11Id                 => tplProgressTracking(i).PPS_TOOLS11_ID
                                               , aPpsTools12Id                 => tplProgressTracking(i).PPS_TOOLS12_ID
                                               , aPpsTools13Id                 => tplProgressTracking(i).PPS_TOOLS13_ID
                                               , aPpsTools14Id                 => tplProgressTracking(i).PPS_TOOLS14_ID
                                               , aPpsTools15Id                 => tplProgressTracking(i).PPS_TOOLS15_ID
                                               , aPpsOperationProcedureId      => tplProgressTracking(i).PPS_OPERATION_PROCEDURE_ID
                                               , aPpsPpsOperationProcedureId   => tplProgressTracking(i).PPS_PPS_OPERATION_PROCEDURE_ID
                                               , aFlpLabelControl              => tplProgressTracking(i).FLP_LABEL_CONTROL
                                               , aFlpLabelReject               => tplProgressTracking(i).FLP_LABEL_REJECT
                                               , aFlpProductQtyUop             => tplProgressTracking(i).FLP_PRODUCT_QTY_UOP
                                               , aFlpPtRejectQtyUop            => tplProgressTracking(i).FLP_PT_REJECT_QTY_UOP
                                               , aFlpCptRejectQtyUop           => tplProgressTracking(i).FLP_CPT_REJECT_QTY_UOP
                                               , aManualProgressTrack          => tplProgressTracking(i).FLP_MANUAL
                                               , aSessionId                    => iSession
                                               , aErrorMsg                     => lErrorMsg
                                               , aContext                      => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                               , aAIdcre                       => tplProgressTracking(i).A_IDCRE
                                               , aADatecre                     => tplProgressTracking(i).A_DATECRE
                                               , aFlpSubcontractQty            => tplProgressTracking(i).PDE_BASIS_QUANTITY
                                                );
        end if;
      end loop;
    end if;
  end SplitProcessTrack;

  /**
  * Procedure SplitFalTaskLink
  * Description : Mise à jour des opérations sur le lot cible et génération des opérations pour le lot destination.
  * @created CLE
  * @lastUpdate
  * @public
  * @param    aOriginOPSeq : Séquence op origine
  * @param    aLotOriginID : Lot origine
  * @param    aLotTargetID : Lot cible
  * @param    aTransferedQty : Qté transférée
  * @param    aGammeCibleId : ID Gamme Cible
  * @param    aTargetOPSeq : Séquence opération cible
  * @param    aSession     : Session Oracle
  */
  procedure SplitFalTaskLink(
    aOriginOPSeq         in integer
  , aLotOriginID         in TTypeID
  , aLotTargetID         in TTypeID
  , aTransferedQty       in TTypeQty
  , aGammeCibleId        in TTypeID
  , aTargetOPSeq         in integer
  , aSession             in varchar2
  , iTransferRealisedQty in integer
  )
  is
    cursor crOperationsOrigin
    is
      select FAL_SCHEDULE_STEP_ID
           , SCS_STEP_NUMBER
        from FAL_TASK_LINK
       where FAL_LOT_ID = aLotOriginID
         and (   nvl(aGammeCibleId, 0) = 0
              or (    nvl(aGammeCibleId, 0) <> 0
                  and (    (    iTransferRealisedQty = 0
                            and SCS_STEP_NUMBER < nvl(aOriginOpSeq, 0) )
                       or (    iTransferRealisedQty = 1
                           and SCS_STEP_NUMBER <= nvl(aOriginOpSeq, 0) )
                      )
                 )
             );

    FirstSeqOpeOrigin        FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    CSchedulePlanning        FAL_LOT.C_SCHEDULE_PLANNING%type;
    vLotTotalQtyBatchOrigin  FAL_LOT.LOT_TOTAL_QTY%type;
    lNewFAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lSplitRatio              number;
    lError                   varchar2(4000);
  begin
    vLotTotalQtyBatchOrigin  := GetLOT_TOTAL_QTY(iLotID => aLotOriginID);

    if vLotTotalQtyBatchOrigin <> 0 then
      lSplitRatio  := aTransferedQty / vLotTotalQtyBatchOrigin;
    else
      lSplitRatio  := 1;
    end if;

    -- Création des opérations sur le lot cible. Si la Gamme cible n'est pas nulle, on ne crée que
    -- les opérations qui précédent l'opération d'origine (celles sur lesquelles du suivi sera reporté)
    for tplOperationOrigin in crOperationsOrigin loop
      lNewFAL_SCHEDULE_STEP_ID  :=
        FAL_OPERATION_FUNCTIONS.CreateBatchOperation(iFalLotId        => aLotTargetID
                                                   , iQty             => aTransferedQty
                                                   , iFalTaskLinkId   => tplOperationOrigin.FAL_SCHEDULE_STEP_ID
                                                   , iSequence        => tplOperationOrigin.SCS_STEP_NUMBER
                                                    );
    end loop;

    -- Si la gamme cible existe, on crée les opérations de cette gamme, depuis l'opération définie par aTargetOPSeq
    if nvl(aGammeCibleId, 0) <> 0 then
      select C_SCHEDULE_PLANNING
        into CSchedulePlanning
        from FAL_LOT
       where FAL_LOT_ID = aLotTargetID;

      FAL_TASK_GENERATOR.CALL_TASK_GENERATOR(iFAL_SCHEDULE_PLAN_ID   => aGammeCibleId
                                           , iFAL_LOT_ID             => aLotTargetID
                                           , iLOT_TOTAL_QTY          => aTransferedQty
                                           , iC_SCHEDULE_PLANNING    => CSchedulePlanning
                                           , iContexte               => FAL_TASK_GENERATOR.ctxtBatchCreation
                                           , iSequence               => aTargetOPSeq
                                           , iRegenerateAll          => 0
                                            );

      update FAL_LOT
         set FAL_SCHEDULE_PLAN_ID = aGammeCibleId
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = aLotTargetID;
    end if;

    /* Mise à jour de la quantité disponible des opérations */
    FAL_PRC_TASK_LINK.UpdateAvailQtyOp(aLotTargetID);

    select min(SCS_STEP_NUMBER)
      into FirstSeqOpeOrigin
      from FAL_TASK_LINK
     where FAL_LOT_ID = aLotOriginID;

    -- Si la séquence origine (celle à partir de laquelle on split) est supérieure à la première séquence (ou égale si on transfert du réalisé), c'est qu'il y a du suivi à transférer
    if    (nvl(aOriginOpSeq, 0) > nvl(FirstSeqOpeOrigin, 0) )
       or (    iTransferRealisedQty = 1
           and (nvl(aOriginOpSeq, 0) = nvl(FirstSeqOpeOrigin, 0) ) ) then
      -- Report des suivis de fabrication
      SplitProcessTrack(iOriginOPSeq           => aOriginOPSeq
                      , iLotOriginID           => aLotOriginID
                      , iLotTargetID           => aLotTargetID
                      , iTransferedQty         => aTransferedQty
                      , iSession               => aSession
                      , iTransferRealisedQty   => iTransferRealisedQty
                       );
    else
      -- Mise à jour de la quantité des opérations du lot d'origine
      -- (cette mise à jour est faite dans SplitProcessTrack dans le cas de report de suivis)
      FAL_TASK_GENERATOR.UpdateBatchQty(aFalLotId      => aLotOriginID
                                      , aNewTotalQty   => vLotTotalQtyBatchOrigin - aTransferedQty
                                      , oError         => lError
                                      , iContext       => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                       );
    end if;
  end SplitFalTaskLink;

  /**
  * Procedure UpdateBatches
  * Description : Mise à jour des lots origine et lot cible
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aLotOriginID : Lot origine
  * @param    aLotTargetID : Lot cible
  * @param    aAskedQty : Qté demandée
  * @param    aRejectQty : Qté rebut
  */
  procedure UpdateBatches(aLotOriginID in TTypeID, aLotTargetID in TTypeID, aAskedQty in TTypeQty, aRejectQty in TTypeQty)
  is
    QteMaxRecept   TTypeQty;
    nAskedQty      number;
    nTransferedQty number;
    nQtySup        number;
  begin
    select nvl(sum(FLP_SUP_QTY), 0)
      into nQtySup
      from FAL_LOT_PROGRESS
     where FAL_LOT_ID = aLotTargetID
       and FLP_REVERSAL = 0;

    nAskedQty       := aAskedQty - nQtySup;
    nTransferedQty  := nAskedQty + aRejectQty;

    -- MAJ du lot origine
    update FAL_LOT
       set LOT_ASKED_QTY = greatest(0, LOT_ASKED_QTY - nAskedQty)
         , LOT_REJECT_PLAN_QTY = greatest(0, LOT_REJECT_PLAN_QTY - aRejectQty) - greatest(0, nAskedQty - LOT_ASKED_QTY)
         , LOT_TOTAL_QTY = greatest(0, LOT_ASKED_QTY - nAskedQty) + greatest(0, LOT_REJECT_PLAN_QTY - aRejectQty) - greatest(0, nAskedQty - LOT_ASKED_QTY)
         , LOT_RELEASE_QTY = case C_LOT_STATUS
                              when '2' then LOT_RELEASE_QTY - nTransferedQty
                              else LOT_RELEASE_QTY
                            end
         , LOT_INPROD_QTY = LOT_INPROD_QTY - nTransferedQty
         , LOT_MAX_RELEASABLE_QTY = FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aLotOriginID, LOT_INPROD_QTY - nTransferedQty)
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where FAL_LOT_ID = aLotOriginID;

    -- MAJ du lot cible
    QteMaxRecept    := FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aLotTargetID);

    update FAL_LOT
       set LOT_MAX_RELEASABLE_QTY = QteMaxRecept
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aLotTargetID;
  end UpdateBatches;

  /**
  * fonction UpdateHistoLot
  * Description : Mise a jour des historiques des lots cibles et origine
  *               PPS_ASC_DESC
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLotOriginID : Lot orgine
  * @param   aLotTargetID : Lot cible
  * @param   aTransferedQty : Qté transférée
  * @param   aOriginOPSeq : Séquence opération origine
  */
  procedure UpdateHistoLot(aLotOriginID in TTypeID, aLotTargetID in TTypeID, aTransferedQty in TTypeQty, aOriginOPSeq in integer)
  is
    -- Création du histo-lot origine
    procedure CreateOriginHistoLot
    is
      TacheID TTypeID;
    begin
      TacheID  := GetFAL_TASK_ID(aLotOriginID, aOriginOPSeq);

      -- Création du histo-Lot
      insert into FAL_HISTO_LOT
                  (FAL_HISTO_LOT_ID
                 , FAL_LOT5_ID
                 , HIS_REFCOMPL
                 , HIS_EVEN_DTE
                 , HIS_PLAN_BEGIN_DTE
                 , HIS_PLAN_END_DTE
                 , FAL_LOT4_ID
                 , FAL_LOT1_ID
                 , HIS_QTE
                 , HIS_INPROD_QTE
                 , FAL_TASK_ID
                 , C_EVEN_TYPE
                 , A_IDCRE
                 , A_DATECRE
                  )
        (select GetNewId   -- FAL_HISTO_LOT_ID
              , aLotOriginID   -- FAL_LOT5_ID
              , LOT_REFCOMPL   -- HIS_REFCOMPL
              , sysdate   -- HIS_EVEN_DTE
              , LOT_PLAN_BEGIN_DTE   -- HIS_PLAN_BEGIN_DTE
              , LOT_PLAN_END_DTE   -- HIS_PLAN_END_DTE
              , aLotTargetID   -- FAL_LOT4_ID
              , null   -- FAL_LOT1_ID
              , aTransferedQty   -- HIS_QTE
              , LOT_INPROD_QTY   -- HIS_INPROD_QTE
              , TacheID   -- FAL_TASK_ID
              , '7'   -- C_EVEN_TYPE
              , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
              , sysdate   -- A_DATECRE
           from FAL_LOT
          where FAL_LOT_ID = aLotOriginID);
    end;

    -- Création du histo-lot origine
    procedure CreateTargetHistoLot
    is
      TacheID TTypeID;
    begin
      TacheID  := GetFAL_TASK_ID(aLotTargetID, aOriginOPSeq);

      -- Création du histo-Lot
      insert into FAL_HISTO_LOT
                  (FAL_HISTO_LOT_ID
                 , FAL_LOT5_ID
                 , HIS_REFCOMPL
                 , HIS_EVEN_DTE
                 , HIS_PLAN_BEGIN_DTE
                 , HIS_PLAN_END_DTE
                 , FAL_LOT4_ID
                 , FAL_LOT1_ID
                 , HIS_QTE
                 , HIS_INPROD_QTE
                 , FAL_TASK_ID
                 , C_EVEN_TYPE
                 , A_IDCRE
                 , A_DATECRE
                  )
        (select GetNewId   -- FAL_HISTO_LOT_ID
              , aLotTargetID   -- FAL_LOT5_ID
              , LOT_REFCOMPL   -- HIS_REFCOMPL
              , sysdate   -- HIS_EVEN_DTE
              , LOT_PLAN_BEGIN_DTE   -- HIS_PLAN_BEGIN_DTE
              , LOT_PLAN_END_DTE   -- HIS_PLAN_END_DTE
              , null   -- FAL_LOT4_ID
              , aLotOriginID   -- FAL_LOT1_ID
              , aTransferedQty   -- HIS_QTE
              , LOT_INPROD_QTY   -- HIS_INPROD_QTE
              , TacheID   -- FAL_TASK_ID
              , case C_LOT_STATUS
                  when '1' then '5'
                  else '6'
                end   -- C_EVEN_TYPE
              , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
              , sysdate   -- A_DATECRE
           from FAL_LOT
          where FAL_LOT_ID = aLotTargetID);
    end;
  begin
    -- Création du histo-lot origine
    CreateOriginHistoLot;
    -- Création du histo-lot cible
    CreateTargetHistoLot;
  end UpdateHistoLot;

  /**
  * fonction GenDeferedAttribs
  * Description : Sauvegarde des attributions du lot origine
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLotOriginID : Lot orgine
  * @param   aLotTargetID : Lot cible
  */
  procedure GenDeferedAttribs(aLotOriginID in TTypeID, aUserCode in TTypeID)
  is
  begin
    -- Génération des attributions reportées
    insert into FAL_NETWORK_LINK_TEMP
                (FAL_NETWORK_LINK_TEMP_ID
               , FAL_NETWORK_LINK_ID
               , FAL_NETWORK_NEED_ID
               , FAL_NETWORK_SUPPLY_ID
               , STM_LOCATION_ID
               , STM_STOCK_POSITION_ID
               , FLN_QTY
               , FLN_MARGIN
               , FLN_NEED_DELAY
                )
      (select aUserCode   -- FAL_NETWORK_LINK_TEMP_ID
            , FAL_NETWORK_LINK_ID   -- FAL_NETWORK_LINK_ID
            , FAL_NETWORK_NEED_ID   -- FAL_NETWORK_NEED_ID
            , FAL_NETWORK_SUPPLY_ID   -- FAL_NETWORK_SUPPLY_ID
            , STM_LOCATION_ID   -- STM_LOCATION_ID
            , STM_STOCK_POSITION_ID   -- STM_STOCK_POSITION_ID
            , FLN_QTY   -- FLN_QTY
            , 0   -- FLN_MARGIN
            , FLN_NEED_DELAY   -- FLN_NEED_DELAY
         from FAL_NETWORK_LINK T_LINK
        where exists(select 1
                       from FAL_NETWORK_SUPPLY T_SUPPLY
                      where T_SUPPLY.FAL_NETWORK_SUPPLY_ID = T_LINK.FAL_NETWORK_SUPPLY_ID
                        and T_SUPPLY.FAL_LOT_ID = aLotOriginID) );
  end GenDeferedAttribs;

  /**
  * fonction DispatchAttribs
  * Description : Procedure de split automatique des attributions sauvegardées
  *               du lot origine.
  *
  ||
  ||
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aUserCode : ID des attributions à reporter
  * @param   aLotTargetID : nouvelle quantité demandée du lot origine
  */
  procedure DispatchAttribs(aUserCode in TTypeID, aNewQteDemandeeOrigine in TTypeQty)
  is
    cursor CUR_ATTRIBS_STOCK
    is
      select     FLN_QTY
            from FAL_NETWORK_LINK_TEMP
           where FAL_NETWORK_LINK_TEMP_ID = aUserCode
             and STM_LOCATION_ID is not null
        order by FLN_NEED_DELAY desc
      for update;

    cursor CUR_ATTRIBS_NEED
    is
      select     FLN_QTY
            from FAL_NETWORK_LINK_TEMP
           where FAL_NETWORK_LINK_TEMP_ID = aUserCode
             and FAL_NETWORK_NEED_ID is not null
        order by FLN_NEED_DELAY desc
      for update;

    CurAttribs    CUR_ATTRIBS_NEED%rowtype;
    QtyToDispatch TTypeQty;
    QteAttribuee  TTypeQty;
  begin
    select sum(FLN_QTY)
      into QteAttribuee
      from FAL_NETWORK_LINK_TEMP
     where FAL_NETWORK_LINK_TEMP_ID = aUserCode;

    QtyToDispatch  := QteAttribuee - aNewQteDemandeeOrigine;

    if QtyToDispatch > 0 then
      -- stock
      open CUR_ATTRIBS_STOCK;

      loop
        fetch CUR_ATTRIBS_STOCK
         into CurAttribs;

        exit when CUR_ATTRIBS_STOCK%notfound
              or (QtyToDispatch <= 0);

        if QtyToDispatch > CurAttribs.FLN_QTY then
          update FAL_NETWORK_LINK_TEMP
             set FLN_MARGIN = CurAttribs.FLN_QTY
           where current of CUR_ATTRIBS_STOCK;

          QtyToDispatch  := QtyToDispatch - CurAttribs.FLN_QTY;
        else
          update FAL_NETWORK_LINK_TEMP
             set FLN_MARGIN = QtyToDispatch
           where current of CUR_ATTRIBS_STOCK;

          QtyToDispatch  := 0;
        end if;
      end loop;

      close CUR_ATTRIBS_STOCK;
    end if;

    if QtyToDispatch > 0 then
      open CUR_ATTRIBS_NEED;

      loop
        fetch CUR_ATTRIBS_NEED
         into CurAttribs;

        exit when CUR_ATTRIBS_NEED%notfound
              or (QtyToDispatch <= 0);

        if QtyToDispatch > CurAttribs.FLN_QTY then
          update FAL_NETWORK_LINK_TEMP
             set FLN_MARGIN = CurAttribs.FLN_QTY
           where current of CUR_ATTRIBS_NEED;

          QtyToDispatch  := QtyToDispatch - CurAttribs.FLN_QTY;
        else
          update FAL_NETWORK_LINK_TEMP
             set FLN_MARGIN = QtyToDispatch
           where current of CUR_ATTRIBS_NEED;

          QtyToDispatch  := 0;
        end if;
      end loop;

      close CUR_ATTRIBS_NEED;
    end if;
  end DispatchAttribs;

  /**
  * fonction ProcessOnAttribs
  * Description : Procedure de split automatique des attributions réelles
  *               du lot origine et du lot cible.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aUserCode : ID des attributions à reporter
  * @param   aLotTargetID : nouvelle quantité demandée du lot origine
  */
  procedure ProcessOnAttribs(aLotTargetID in TTypeID, aUserCode in TTypeID)
  is
    -- Lecture des records de FAL_NETWORK_LINK_TEMP selon le UserCode
    cursor GetLinkTempRecord(UserCode in TTypeID)
    is
      select *
        from FAL_NETWORK_LINK_TEMP
       where FAL_NETWORK_LINK_TEMP_ID = UserCode
         and FLN_MARGIN > 0;

    -- Record de l'attribution concernée
    vLinkTemp GetLinkTempRecord%rowtype;
    SupplyID  FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    EndPlan   FAL_NETWORK_SUPPLY.FAN_END_PLAN%type;
  begin
    -- Ouverture du curseur
    open GetLinkTempRecord(aUserCode);

    loop
      fetch GetLinkTempRecord
       into vLinkTemp;

      -- S'assurer qu'il y ai un enregistrement ...
      exit when GetLinkTempRecord%notfound;

      -- Si tout la qté n'a pas été consommé
      if vLinkTemp.FLN_MARGIN < vLinkTemp.FLN_QTY then
        -- MAJ de l'attribution origine
        update FAL_NETWORK_LINK
           set FLN_QTY = FLN_QTY - vLinkTemp.FLN_MARGIN
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_NETWORK_LINK_ID = vLinkTemp.FAL_NETWORK_LINK_ID;
      else
        -- Suppression de l'attribution origine
        delete from FAL_NETWORK_LINK
              where FAL_NETWORK_LINK_ID = vLinkTemp.FAL_NETWORK_LINK_ID;
      end if;

      -- Si l'attribution est sur besoin
      if vLinkTemp.FAL_NETWORK_NEED_ID is not null then
        -- MAJ réseau origine du besoin
        update FAL_NETWORK_SUPPLY
           set FAN_FREE_QTY = FAN_FREE_QTY + vLinkTemp.FLN_MARGIN
             , FAN_NETW_QTY = FAN_NETW_QTY - vLinkTemp.FLN_MARGIN
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_NETWORK_SUPPLY_ID = vLinkTemp.FAL_NETWORK_SUPPLY_ID;
      -- Sinon c'est sur stock
      else
        -- MAJ réseau origine du stock
        update FAL_NETWORK_SUPPLY
           set FAN_FREE_QTY = FAN_FREE_QTY + vLinkTemp.FLN_MARGIN
             , FAN_STK_QTY = FAN_STK_QTY - vLinkTemp.FLN_MARGIN
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_NETWORK_SUPPLY_ID = vLinkTemp.FAL_NETWORK_SUPPLY_ID;
      end if;

      -- Récupération des infos liées à l'appro du lot cible correspondant à
      -- l'appro du lot d'origine de l'attribution en cours de traitement.
      select fns_target.FAL_NETWORK_SUPPLY_ID
           , fns_target.FAN_END_PLAN
        into SupplyID
           , EndPlan
        from FAL_NETWORK_SUPPLY fns_target
           , FAL_NETWORK_SUPPLY fns_origin
       where fns_origin.FAL_NETWORK_SUPPLY_ID = vLinkTemp.FAL_NETWORK_SUPPLY_ID
         and fns_target.FAL_LOT_ID = aLotTargetID
         and fns_target.STM_STOCK_ID = fns_origin.STM_STOCK_ID
         and nvl(fns_target.STM_LOCATION_ID, 0) = nvl(fns_origin.STM_LOCATION_ID, 0)
         and nvl(fns_target.FAN_CHAR_VALUE1, 0) = nvl(fns_origin.FAN_CHAR_VALUE1, 0)
         and nvl(fns_target.FAN_CHAR_VALUE2, 0) = nvl(fns_origin.FAN_CHAR_VALUE2, 0)
         and nvl(fns_target.FAN_CHAR_VALUE3, 0) = nvl(fns_origin.FAN_CHAR_VALUE3, 0)
         and nvl(fns_target.FAN_CHAR_VALUE4, 0) = nvl(fns_origin.FAN_CHAR_VALUE4, 0)
         and nvl(fns_target.FAN_CHAR_VALUE5, 0) = nvl(fns_origin.FAN_CHAR_VALUE5, 0);

      -- Création de l'attribution cible
      insert into FAL_NETWORK_LINK
                  (FAL_NETWORK_LINK_ID
                 , FAL_NETWORK_SUPPLY_ID
                 , FAL_NETWORK_NEED_ID
                 , FLN_SUPPLY_DELAY
                 , FLN_NEED_DELAY
                 , STM_STOCK_POSITION_ID
                 , STM_LOCATION_ID
                 , FLN_MARGIN
                 , FLN_QTY
                 , A_IDCRE
                 , A_DATECRE
                  )
           values (GetNewId   -- FAL_NETWORK_LINK_ID
                 , SupplyID   -- FAL_NETWORK_SUPPLY_ID
                 , vLinkTemp.FAL_NETWORK_NEED_ID   -- FAL_NETWORK_NEED_ID
                 , EndPlan   -- FLN_SUPPLY_DELAY
                 , vLinkTemp.FLN_NEED_DELAY   -- FLN_NEED_DELAY
                 , vLinkTemp.STM_STOCK_POSITION_ID   -- STM_STOCK_POSITION_ID
                 , vLinkTemp.STM_LOCATION_ID   -- STM_LOCATION_ID
                 , vLinkTemp.FLN_NEED_DELAY - EndPlan   -- FLN_MARGIN
                 , vLinkTemp.FLN_MARGIN   -- FLN_QTY
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                 , sysdate   -- A_DATECRE
                  );

      -- Si l'attribution est sur besoin
      if vLinkTemp.FAL_NETWORK_NEED_ID is not null then
        -- MAJ réseau cible du besoin
        update FAL_NETWORK_SUPPLY
           set FAN_FREE_QTY = FAN_FREE_QTY - vLinkTemp.FLN_MARGIN
             , FAN_NETW_QTY = FAN_NETW_QTY + vLinkTemp.FLN_MARGIN
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_NETWORK_SUPPLY_ID = SupplyID;
      -- Sinon c'est sur stock
      else
        -- MAJ réseau origine du stock
        update FAL_NETWORK_SUPPLY
           set FAN_FREE_QTY = FAN_FREE_QTY - vLinkTemp.FLN_MARGIN
             , FAN_STK_QTY = FAN_STK_QTY + vLinkTemp.FLN_MARGIN
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_NETWORK_SUPPLY_ID = SupplyID;
      end if;
    end loop;

    -- Fermeture du curseur
    close GetLinkTempRecord;
  end ProcessOnAttribs;

  /**
  * fonction CreateTargetBatch
  * Description : Création du lot cible. On commit dans une transaction autonome pour éviter des problèmes de lock.
  *               Le lot est créé de type "Eclatement en cours" (C_FAB_TYPE = 5) pour pouvoir être supprimé ensuite en cas
  *               de plantage (suppression des OF en cours d'éclatement qui sont réservés dans une session qui n'existe plus).
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param
  * @param
  */
  procedure CreateTargetBatch(
    aOriginBatch            in     number
  , aTargetBatchID          in out number
  , aStartdatePlanTarget    in     integer
  , aStartDateOfTargetBatch in     date
  , aEndDateOfTargetBatch   in     date
  , aAskedQty               in     number
  , aPlanifiedTrashQty      in     number
  , aTotalQty               in     number
  , aTargetGoodId           in     number
  , aTargetOrderId          in     number
  )
  is
    pragma autonomous_transaction;

    cursor crBatchOrigin
    is
      select *
        from fal_lot
       where fal_lot_id = aOriginBatch;

    tplBatchOrigin crBatchOrigin%rowtype;
    lnFalOrderId   number;
    lnGcoGoodId    number;
    lvLotSecondRef FAL_LOT.LOT_SECOND_REF%type;
    lvPShortDescr  FAL_LOT.LOT_PSHORT_DESCR%type;
    lvPFreeText    FAL_LOT.LOT_PFREE_TEXT%type;
    lvPText        FAL_LOT.LOT_PTEXT%type;
  begin
    open crBatchOrigin;

    fetch crBatchOrigin
     into tplBatchOrigin;

    close crBatchOrigin;

    aTargetBatchID  := GetNewId;

    if nvl(aTargetGoodId, 0) <> 0 then
      lnGcoGoodId     := aTargetGoodId;
      lvLotSecondRef  := null;
      lvPShortDescr   := null;
      lvPFreeText     := null;
      lvPText         := null;

      if nvl(aTargetOrderId, 0) = 0 then
        -- Création de l'ordre
        lnFalOrderId  := FAL_ORDER_FUNCTIONS.CreateManufactureOrder(aFAL_JOB_PROGRAM_ID => tplBatchOrigin.FAL_JOB_PROGRAM_ID, aGCO_GOOD_ID => aTargetGoodId);
      else
        lnFalOrderId  := aTargetOrderId;
      end if;
    else
      lnFalOrderId    := tplBatchOrigin.FAL_ORDER_ID;
      lnGcoGoodId     := tplBatchOrigin.GCO_GOOD_ID;
      lvLotSecondRef  := tplBatchOrigin.LOT_SECOND_REF;
      lvPShortDescr   := tplBatchOrigin.LOT_PSHORT_DESCR;
      lvPFreeText     := tplBatchOrigin.LOT_PFREE_TEXT;
      lvPText         := tplBatchOrigin.LOT_PTEXT;
    end if;

    FAL_BATCH_FUNCTIONS.InsertBatch(aFAL_LOT_ID                   => aTargetBatchID
                                  , aFAL_ORDER_ID                 => lnFalOrderId
                                  , aGCO_GOOD_ID                  => lnGcoGoodId
                                  , aLOT_PLAN_BEGIN_DTE           => (case
                                                                        when aStartdatePlanTarget = 1 then aStartDateOfTargetBatch
                                                                        else null
                                                                      end)
                                  , aLOT_PLAN_END_DTE             => (case
                                                                        when aStartdatePlanTarget = 0 then aEndDateOfTargetBatch
                                                                        else null
                                                                      end)
                                  , aLOT_ASKED_QTY                => aAskedQty
                                  , aLOT_REJECT_PLAN_QTY          => aPlanifiedTrashQty
                                  , aLOT_TOTAL_QTY                => aTotalQty
                                  , aLOT_INPROD_QTY               => aTotalQty
                                  , aDIC_FAB_CONDITION_ID         => tplBatchOrigin.DIC_FAB_CONDITION_ID
                                  , aSTM_STOCK_ID                 => tplBatchOrigin.STM_STOCK_ID
                                  , aSTM_LOCATION_ID              => tplBatchOrigin.STM_LOCATION_ID
                                  , aPPS_NOMENCLATURE_ID          => tplBatchOrigin.PPS_NOMENCLATURE_ID
                                  , aFAL_SCHEDULE_PLAN_ID         => tplBatchOrigin.FAL_SCHEDULE_PLAN_ID
                                  , aC_SCHEDULE_PLANNING          => tplBatchOrigin.C_SCHEDULE_PLANNING
                                  , aDOC_RECORD_ID                => tplBatchOrigin.DOC_RECORD_ID
                                  , aSTM_STM_STOCK_ID             => tplBatchOrigin.STM_STM_STOCK_ID
                                  , aSTM_STM_LOCATION_ID          => tplBatchOrigin.STM_STM_LOCATION_ID
                                  , aLOT_TOLERANCE                => 0
                                  , aDIC_FAMILY_ID                => tplBatchOrigin.DIC_FAMILY_ID
                                  , aC_PRIORITY                   => tplBatchOrigin.C_PRIORITY
                                  , aDIC_LOT_CODE2_ID             => tplBatchOrigin.DIC_LOT_CODE2_ID
                                  , aDIC_LOT_CODE3_ID             => tplBatchOrigin.DIC_LOT_CODE3_ID
                                  , aLOT_FREE_NUM1                => tplBatchOrigin.LOT_FREE_NUM1
                                  , aLOT_FREE_NUM2                => tplBatchOrigin.LOT_FREE_NUM2
                                  , aLOT_PLAN_VERSION             => tplBatchOrigin.LOT_PLAN_VERSION
                                  , aLOT_PLAN_NUMBER              => tplBatchOrigin.LOT_PLAN_NUMBER
                                  , aGCO_QUALITY_PRINCIPLE_ID     => tplBatchOrigin.GCO_QUALITY_PRINCIPLE_ID
                                  , aPPS_OPERATION_PROCEDURE_ID   => tplBatchOrigin.PPS_OPERATION_PROCEDURE_ID
                                  , aC_FAB_TYPE                   => '5'
                                  , aLOT_ORIGIN_REF               => tplBatchOrigin.FAL_LOT_ID
                                  , aPC_YEAR_WEEK_ID              => tplBatchOrigin.PC_YEAR_WEEK_ID
                                  , aPC__PC_YEAR_WEEK_ID          => tplBatchOrigin.PC__PC_YEAR_WEEK_ID
                                  , aPC_2_PC_YEAR_WEEK_ID         => tplBatchOrigin.PC_2_PC_YEAR_WEEK_ID
                                  , aPC_3_PC_YEAR_WEEK_ID         => tplBatchOrigin.PC_3_PC_YEAR_WEEK_ID
                                  , aC_LOT_STATUS                 => tplBatchOrigin.C_LOT_STATUS
                                  , aLOT_TO_BE_RELEASED           => tplBatchOrigin.LOT_TO_BE_RELEASED
                                  , aFAL_FAL_SCHEDULE_PLAN_ID     => tplBatchOrigin.FAL_FAL_SCHEDULE_PLAN_ID
                                  , aLOT_REF_QTY                  => tplBatchOrigin.LOT_REF_QTY
                                  , aLOT_VERSION_ORIGIN_NUM       => tplBatchOrigin.LOT_VERSION_ORIGIN_NUM
                                  , aLOT_SHORT_DESCR              => tplBatchOrigin.LOT_SHORT_DESCR
                                  , aLOT_LONG_DESCR               => tplBatchOrigin.LOT_LONG_DESCR
                                  , aLOT_FREE_DESCR               => tplBatchOrigin.LOT_FREE_DESCR
                                  , aLOT_OPEN__DTE                => tplBatchOrigin.LOT_OPEN__DTE
                                  , aLOT_MODIFY                   => tplBatchOrigin.LOT_MODIFY
                                  , aLOT_RELEASE_QTY              => (case
                                                                        when tplBatchOrigin.C_LOT_STATUS = '1' then 0
                                                                        else aTotalQty
                                                                      end)
                                  , aPTC_FIXED_COSTPRICE_ID       => tplBatchOrigin.PTC_FIXED_COSTPRICE_ID
                                  , aLOT_SECOND_REF               => lvLotSecondRef
                                  , aLOT_PSHORT_DESCR             => lvPShortDescr
                                  , aLOT_PFREE_TEXT               => lvPFreeText
                                  , aLOT_PTEXT                    => lvPText
                                   );
    -- Report de la planification de base du lot
    ReportBatchBasisPlanning(aOriginBatch, aTargetBatchID);
    commit;
  end;

  /**
  * Fonction BatchSplitting
  * Description : Eclatement de lot de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  */
  function BatchSplitting(
    aOriginBatch            in     number
  , aCLotStatus             in     varchar2
  , aStartdatePlanTarget    in     integer
  , aStartDateOfTargetBatch in     date
  , aEndDateOfTargetBatch   in     date
  , aAskedQty               in     number
  , aPlanifiedTrashQty      in     number
  , aOriginOperation        in     number
  , aSession                in     varchar2
  , aStartDatePlanOrigin    in     integer
  , aStartDateOfOriginBatch in     date
  , aEndDateOfOriginBatch   in     date
  , aBreakUpContext         in     integer
  , aNewOriginAskedQty      in     number
-- Variables utilisée uniquement en mode non-batch (interactions avec une interface)
  , aReturnCode             in out integer
  , aTargetBatchID          in out number
  , aOriginOPSeq            in out integer
  , aTargetOPSeq            in out integer
  , aSavedLinksID           in out number
--
  , aTargetProcessPlan             number default null
  , aTargetSequence                number default null
  , aBatchMode                     integer default 0
  , aAutoSelectAllCompo     in     integer default 0
  , aTargetGoodId           in     number default 0
  , aTargetOrderId          in     number default 0
  , iTransferRealisedQty    in     integer default 0
  )
    return integer
  is
    aExistingLotDetail   number;
    aExistingNetworkLink number;
    nTotalQty            number;
    aLotFreeOriginQty    number;
    aErrorMsg            varchar2(255);
  begin
    nTotalQty    := aAskedQty + aPlanifiedTrashQty;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < CdeBatchCreated)
       or aBatchMode = 1 then
      -- Suppression des enregistrements temporaires composants et liens composants de session égale ou invalide.
      FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeAllTemporaryTable(aSession);

      -- Création du lot de fabrication cible selon le lot origine
      begin
        CreateTargetBatch(aOriginBatch              => aOriginBatch
                        , aTargetBatchID            => aTargetBatchID
                        , aStartdatePlanTarget      => aStartdatePlanTarget
                        , aStartDateOfTargetBatch   => aStartDateOfTargetBatch
                        , aEndDateOfTargetBatch     => aEndDateOfTargetBatch
                        , aAskedQty                 => aAskedQty
                        , aPlanifiedTrashQty        => aPlanifiedTrashQty
                        , aTotalQty                 => nTotalQty
                        , aTargetGoodId             => aTargetGoodId
                        , aTargetOrderId            => aTargetOrderId
                         );
        -- Réservation du lot créé
        FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => aTargetBatchID, aLT1_ORACLE_SESSION => aSession, aErrorMsg => aErrorMsg);
      exception
        when FAL_BATCH_FUNCTIONS.excMissingFixedCostprice then
          aReturnCode  := cdenoPRFForBatch;
          return 0;
        when others then
          aReturnCode  := cdeErrorOnBatchSplitting;
          return 0;
      end;

      -- Point de sortie
      if aBatchMode = 0 then
        aReturnCode  := cdeBatchCreated;
        return 1;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeDisplayComponents)
       or aBatchMode = 1 then
      -- Génération des composants temporaires
      FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aFalLotId      => aOriginBatch
                                                    , aSessionId     => aSession
                                                    , aContext       => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                                    , aQtyToSwitch   => nTotalQty
                                                     );
      -- Génération des liens temporaires
      FAL_COMPONENT_LINK_FCT.GlobalComponentLinkGeneration(aFAL_LOT_ID                  => aOriginBatch
                                                         , aLOM_SESSION                 => aSession
                                                         , aContext                     => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                                         , aAutoSelectAllCompoOnSplit   => aAutoSelectAllCompo
                                                          );

      -- Si le lot origine est lancé, alors il est susceptible d'avoir des composants en atelier.
      if aCLotStatus = '2' then
        -- Point de sortie
        if aBatchMode = 0 then
          aReturnCode  := cdeDisplayComponents;
          return 1;
        end if;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeComponentSplitted)
       or aBatchMode = 1 then
      -- Split des composants
      SplitComponents(aSession, aOriginBatch, aTargetBatchID, nTotalQty);

      -- Point de sortie
      if aBatchMode = 0 then
        aReturnCode  := cdeComponentSplitted;
        return 1;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeDisplayBatchDetails)
       or aBatchMode = 1 then
      -- Split des entrées et sorties atelier
      SplitFalfactoryInOut(aSession, aTargetBatchId, aReturnCode);

      if aReturnCode = cdenoOriginMovement then
        return 0;
      end if;

      -- Si le lot de fabrication origine dispose de détails lot avec qté solde > 0
      begin
        select max(FAL_LOT_DETAIL_ID)
          into aExistingLotDetail
          from FAL_LOT_DETAIL
         where FAL_LOT_ID = aOriginBatch
           and FAD_BALANCE_QTY > 0;
      exception
        when no_data_found then
          aExistingLotDetail  := 0;
      end;

      if aExistingLotDetail <> 0 then
        -- Point de sortie
        if aBatchMode = 0 then
          aReturnCode  := cdeDisplayBatchDetails;
          return 1;
        end if;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeFalTaskLinksplitted)
       or aBatchMode = 1 then
      -- Détermination des séquences opération origine et cible
      aOriginOPSeq  := GetSeqOriginTask(aOriginBatch, aOriginOperation);
      aTargetOPSeq  := GetSeqTargetTask(aTargetProcessPlan, aTargetSequence);
      -- Traitement des opérations.
      SplitFalTaskLink(aOriginOPSeq           => aOriginOPSeq
                     , aLotOriginID           => aOriginBatch
                     , aLotTargetID           => aTargetBatchID
                     , aTransferedQty         => nTotalQty
                     , aGammeCibleId          => aTargetProcessPlan
                     , aTargetOPSeq           => aTargetOPSeq
                     , aSession               => aSession
                     , iTransferRealisedQty   => iTransferRealisedQty
                      );
      -- Report de la planification de base des opérations
      ReportTaskBasisPlanning(aOriginBatch, aTargetBatchID);

      -- Point de sortie
      if aBatchMode = 0 then
        aReturnCode  := cdeFalTaskLinksplitted;
        return 1;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeBatchesUpdated)
       or aBatchMode = 1 then
      -- Traitement des lots
      UpdateBatches(aLotOriginID => aOriginBatch, aLotTargetID => aTargetBatchID, aAskedQty => aAskedQty, aRejectQty => aPlanifiedTrashQty);

      -- Point de sortie
      if aBatchMode = 0 then
        aReturnCode  := cdeBatchesUpdated;
        return 1;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeTargetBatchPlanified)
       or aBatchMode = 1 then
      -- Planification du lot cible
      FAL_PLANIF.PLANIFICATION_LOT(PrmFAL_LOT_ID              => aTargetBatchID
                                 , DatePlanification          => (case
                                                                    when aStartDatePlanTarget = 1 then aStartDateOfTargetBatch
                                                                    else aEndDateOfTargetBatch
                                                                  end)
                                 , SelonDateDebut             => aStartdatePlanTarget
                                 , MAJReqLiensComposantsLot   => 1
                                 , MAJ_Reseaux_Requise        => 0
                                  );

      -- Point de sortie
      if aBatchMode = 0 then
        aReturnCode  := cdeTargetBatchPlanified;
        return 1;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeOriginBatchPlanified)
       or aBatchMode = 1 then
      -- Planification du lot Origine
      FAL_PLANIF.PLANIFICATION_LOT(PrmFAL_LOT_ID              => aOriginBatch
                                 , DatePlanification          => (case
                                                                    when aStartDatePlanOrigin = 1 then aStartDateOfOriginBatch
                                                                    else aEndDateOfOriginBatch
                                                                  end)
                                 , SelonDateDebut             => aStartdatePlanOrigin
                                 , MAJReqLiensComposantsLot   => 1
                                 , MAJ_Reseaux_Requise        => 0
                                  );

      -- Point de sortie
      if aBatchMode = 0 then
        aReturnCode  := cdeOriginBatchPlanified;
        return 1;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeBatchHistUpdated)
       or aBatchMode = 1 then
      -- Mise à jour des historiques de lots de fabrication
      UpdateHistoLot(aOriginBatch, aTargetBatchID, nTotalQty, aOriginOPSeq);

      -- Point de sortie
      if aBatchMode = 0 then
        aReturnCode  := cdeBatchHistUpdated;
        return 1;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeTargetNetworkUpdated)
       or aBatchMode = 1 then
      -- Mise à jour des réseaux du lot cible
      FAL_NETWORK.MiseAJourReseaux(aTargetBatchID, FAL_NETWORK.ncCreationLot, null);

      if aBatchMode = 0 then
        aReturnCode  := cdeTargetNetworkUpdated;
        return 1;
      end if;
    end if;

    -- Recherche d'attributions sur le lot origine
    begin
      aExistingNetworkLink  := 0;

      select max(FNL.FAL_NETWORK_LINK_ID)
        into aExistingNetworkLink
        from FAL_NETWORK_LINK FNL
       where exists(select 1
                      from FAL_NETWORK_SUPPLY FNS
                     where FNS.FAL_NETWORK_SUPPLY_ID = FNL.FAL_NETWORK_SUPPLY_ID
                       and FNS.FAL_LOT_ID = aOriginBatch);
    exception
      when no_data_found then
        aExistingNetworkLink  := 0;
    end;

    -- Si le lot origine possède des attributions, alors
    -- on reporte celles-ci partiellement sur le lot cible.
    if aExistingNetworkLink > 0 then
      -- Point d'entrée
      if    (    aBatchMode = 0
             and aBreakUpContext = ctxtBreakUpLot
             and aReturnCode < cdeLinksSaved)
         or aBatchMode = 1 then
        -- Sauvegarde des attributions du lot origine
        if nvl(aSavedLinksID, 0) = 0 then
          aSavedLinksID  := GetNewId;
          GenDeferedAttribs(aOriginBatch, aSavedLinksID);
        end if;

        -- Point de sortie
        if     aBatchMode = 0
           and aBreakUpContext = ctxtBreakUpLot then
          aReturnCode  := cdeLinksSaved;
          return 1;
        -- Ou split automatique des attributions sauvegardées
        else
          DispatchAttribs(aSavedLinksID, aNewOriginAskedQty);
        end if;
      end if;

      -- Point d'entrée
      if    (    aBatchMode = 0
             and aReturnCode < cdeLinksDefered)
         or aBatchMode = 1 then
        -- Traitements des attributions réelles du lot
        ProcessOnAttribs(aTargetBatchID, aSavedLinksID);

        -- Suppression des attributions précédemment sauvegardées.
        delete from FAL_NETWORK_LINK_TEMP
              where FAL_NETWORK_LINK_TEMP_ID = aSavedLinksID;

        -- Point de sortie
        if aBatchMode = 0 then
          aReturnCode  := cdeLinksDefered;
          return 1;
        end if;
      end if;
    end if;

    -- Point d'entrée
    if    (    aBatchMode = 0
           and aReturnCode < cdeOriginNetworkUpdated)
       or aBatchMode = 1 then
      -- Mise à jour des réseaux du lot Origine
      FAL_NETWORK.MiseAJourReseaux(aOriginBatch, FAL_NETWORK.ncModificationLot, null);

      if aBatchMode = 0 then
        aReturnCode  := cdeOriginNetworkUpdated;
        return 1;
      end if;
    end if;

    -- Suppression des enregistrements temporaires composants et liens composants créés
    CancelBatchSplitting(aSession, aSavedLinksID);
    -- Eclatement effectué avec succès
    aReturnCode  := cdeBatchSplittedWithSucces;

    -- Mise à jour du status du nouvel OF avec celui d'origine
    update FAL_LOT
       set C_FAB_TYPE = (select C_FAB_TYPE
                           from FAL_LOT
                          where FAL_LOT_ID = aOriginBatch)
     where FAL_LOT_ID = aTargetBatchID;

    -- MAJ de l'ordre
    FAL_ORDER_FUNCTIONS.UpdateOrder(null, aOriginBatch);

    if nvl(aTargetGoodId, 0) <> 0 then
      FAL_ORDER_FUNCTIONS.UpdateOrder(null, aTargetBatchID);
    end if;

    return 1;
  exception
    when others then
      aReturnCode  := cdeErrorOnBatchSplitting;
      raise;
      return 0;
  end BatchSplitting;

  procedure BatchSplitting(
    aOriginBatch            in     number
  , aCLotStatus             in     varchar2
  , aStartdatePlanTarget    in     integer
  , aStartDateOfTargetBatch in     date
  , aEndDateOfTargetBatch   in     date
  , aAskedQty               in     number
  , aPlanifiedTrashQty      in     number
  , aOriginOperation        in     number
  , aSession                in     varchar2
  , aStartDatePlanOrigin    in     integer
  , aStartDateOfOriginBatch in     date
  , aEndDateOfOriginBatch   in     date
  , aBreakUpContext         in     integer
  , aNewOriginAskedQty      in     number
-- Variables utilisée uniquement en mode non-batch (interactions avec une interface)
  , aReturnCode             in out integer
  , aTargetBatchID          in out number
  , aOriginOPSeq            in out integer
  , aTargetOPSeq            in out integer
  , aSavedLinksID           in out number
--
  , aTargetProcessPlan             number default null
  , aTargetSequence                number default null
  , aBatchMode                     integer default 0
  , aAutoSelectAllCompo     in     integer default 0
  , aTargetGoodId           in     number default 0
  , aTargetOrderId          in     number default 0
  , iTransferRealisedQty    in     integer default 0
  )
  is
    aResult integer;
  begin
    aresult  :=
      BatchSplitting(aOriginBatch
                   , aCLotStatus
                   , aStartdatePlanTarget
                   , aStartDateOfTargetBatch
                   , aEndDateOfTargetBatch
                   , aAskedQty
                   , aPlanifiedTrashQty
                   , aOriginOperation
                   , aSession
                   , aStartDatePlanOrigin
                   , aStartDateOfOriginBatch
                   , aEndDateOfOriginBatch
                   , aBreakUpContext
                   , aNewOriginAskedQty
                   , aReturnCode
                   , aTargetBatchID
                   , aOriginOPSeq
                   , aTargetOPSeq
                   , aSavedLinksID
                   , aTargetProcessPlan
                   , aTargetSequence
                   , aBatchMode
                   , aAutoSelectAllCompo
                   , aTargetGoodId
                   , aTargetOrderId
                   , iTransferRealisedQty
                    );
  exception
    when others then
      raise;
  end;

  /**
  * fonction CancelBatchSplitting
  * Description : Suppression des enregistrement temporaires créés lors de l'éclattement
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionID : Session Oracle
  * @param   aSavedNetwLinksID : ID des attributions temporaires
  */
  procedure CancelBatchSplitting(aSessionID varchar2, aSavedNetwLinksID number)
  is
  begin
    for tplComponentLinks in (select GCO_GOOD_ID
                                from FAL_LOT_MAT_LINK_TMP
                               where LOM_SESSION = aSessionId) loop
      FAL_BATCH_FUNCTIONS.DeleteNullReceptPositions(tplComponentLinks.GCO_GOOD_ID);
    end loop;

    -- Composants et liens temporaires
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeAllTemporaryTable(aSessionID);

    -- Attributions temporaires
    delete from FAL_NETWORK_LINK_TEMP
          where FAL_NETWORK_LINK_TEMP_ID = aSavedNetwLinksID;
  end;
end;
