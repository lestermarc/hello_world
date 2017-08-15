--------------------------------------------------------
--  DDL for Package Body STM_PRC_KLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_KLS" 
is
  /**
  * Description
  *   Mise à jour du buffer KLS
  */
  procedure manageBuffer(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
  begin
    -- Traitement uniquement si la config KLS est active
    -- et si la quantité du mouvement est à 0
    if (iotMovementRecord.SMO_MOVEMENT_QUANTITY <> 0) then
      if (PCS.PC_CONFIG.GetConfig('STM_KLS_ACTIVATE') = '1') then
        standardProcess(iotMovementRecord => iotMovementRecord);
      elsif     (PCS.PC_CONFIG.GetConfig('STM_KLS_ACTIVATE') = '2')
            and (PCS.PC_CONFIG.GetConfig('STM_KLS_BUFFER_FILL_PROC') is not null) then
        gCurrentStockMovement  := iotMovementRecord;

        execute immediate 'begin ' || PCS.PC_CONFIG.GetConfig('STM_KLS_BUFFER_FILL_PROC') || '; end;';

        gCurrentStockMovement  := null;
      end if;
    end if;
  end manageBuffer;

   /**
  * procedure RedoBuffer
  * Description
  *   Mise à jour du buffer KLS en fonction du mouvement de stock
  * @created fp 14.03.2011
  * @lastUpdate
  * @public
  * @param iMvtId  : id du mouvement de stock dont il faut regénérer l'entrée KLS
  */
  procedure redoBuffer(iMvtId in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type)
  is
  begin
    for ltplMvt in (select *
                      from STM_STOCK_MOVEMENT
                     where STM_STOCK_MOVEMENT_ID = iMvtId) loop
      -- Update KLS buffer
      manageBuffer(ltplMvt);
    end loop;
  end RedoBuffer;

  /**
  * Description
  *   Fonctionnement standard
  */
  procedure standardProcess(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lMovementSort   varchar2(1);
    lDefaultStockId GCO_PRODUCT.STM_STOCK_ID%type;
    lMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lOrderNo        varchar2(30);
    lPlanifDate     date;
    lImputation     varchar2(30);
    lStockId        STM_STOCK.STM_STOCK_ID%type;
  begin
    -- recherche de l'id du stock selon la configuration
    lStockId  := STM_FUNCTIONS.GetPublicStockId(PCS.PC_CONFIG.GetConfig('STM_KLS_STOCK') );

    -- recherche de l'id stock par défaut du bien.
    begin
      select stm_stock_id
        into lDefaultStockId
        from gco_product
       where gco_good_id = iotMovementRecord.GCO_GOOD_ID;
    --
    exception
      -- S'il s'agit d'un service ou pseudo-bien, le gco_product n'est pas identifié
      when no_data_found then
        lDefaultStockId  := null;
    end;

    -- comparaison des stocks id
    if     (lDefaultStockId is not null)
       and   -- Stock par défaut existe
           (lStockId = lDefaultStockId)
       and   -- Stock config = stock par défaut
           (lStockId = iotMovementRecord.STM_STOCK_ID) then   -- Stock config = stock du mouvement
      -- recherche le type afin de savoir si on a affaire . une entrée ou une sortie
      -- et si le genre de mouvement est utilisé dans la mise à jour KLS
      select max(decode(c_movement_sort, 'ENT', 'E', 'SOR', 'S') )
        into lMovementSort
        from stm_movement_kind
       where stm_movement_kind_id = iotMovementRecord.STM_MOVEMENT_KIND_ID
         and mok_export_mvt = 1;

      if lMovementSort is not null then
        -- recherche de la référence article
        select max(GOO_MAJOR_REFERENCE)
          into lMajorReference
          from GCO_GOOD
         where GCO_GOOD_ID = iotMovementRecord.GCO_GOOD_ID;

        -- recherche du numéro d'ordre
        if iotMovementRecord.DOC_POSITION_DETAIL_ID is null then
          lOrderNo     := to_char(iotMovementRecord.STM_STOCK_MOVEMENT_ID);
          lPlanifDate  := iotMovementRecord.SMO_MOVEMENT_DATE;

          -- recherche de la description de l'vImputation
          select max(GOO_MAJOR_REFERENCE)
            into lImputation
            from FAL_LOT
               , GCO_GOOD
           where FAL_LOT.LOT_REFCOMPL = iotMovementRecord.SMO_WORDING
             and FAL_LOT.GCO_GOOD_ID = GCO_GOOD.GCO_GOOD_ID;
        else
          -- recherche du numéro de document et de la date de planification
          select b.DMT_NUMBER
               , b.DMT_DATE_DOCUMENT
            into lOrderNo
               , lPlanifDate
            from doc_position_detail a
               , doc_document b
           where a.DOC_POSITION_DETAIL_ID = iotMovementRecord.DOC_POSITION_DETAIL_ID
             and b.DOC_DOCUMENT_ID = a.DOC_DOCUMENT_ID;

          -- recherche de la description de l'vImputation
          select substr(max(PER_NAME), 1, 30)
            into lImputation
            from PAC_PERSON
           where PAC_PERSON_ID = iotMovementRecord.PAC_THIRD_ID;
        end if;

        if iotMovementRecord.ASA_INTERVENTION_DETAIL_ID is not null then
          select max(MIS_NUMBER)
            into lOrderNo
            from ASA_MISSION MIS
               , ASA_INTERVENTION ITR
               , ASA_INTERVENTION_DETAIL AID
           where MIS.ASA_MISSION_ID = ITR.ASA_MISSION_ID
             and ITR.ASA_INTERVENTION_ID = AID.ASA_INTERVENTION_ID
             and AID.ASA_INTERVENTION_DETAIL_ID = iotMovementRecord.ASA_INTERVENTION_DETAIL_ID;
        end if;

        insert into STM_KLS_BUFFER
                    (STM_KLS_BUFFER_ID
                   , KLS_EXPORT
                   , KLS_MOVEMENT_TYPE
                   , KLS_ORDER
                   , KLS_MAJOR_REFERENCE
                   , KLS_LOT
                   , KLS_QUANTITY
                   , STM_STOCK_MOVEMENT_ID
                   , KLS_PLANIF_DATE
                   , KLS_IMPUTATION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (init_id_seq.nextval
                   , 0
                   , lMovementSort
                   , lOrderNo
                   , lMajorReference
                   , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                   , iotMovementRecord.SMO_MOVEMENT_QUANTITY
                   , iotMovementRecord.STM_STOCK_MOVEMENT_ID
                   , lPlanifDate
                   , lImputation
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    end if;
  end standardProcess;

  /**
  * Description
  *   Exemple d'individualisation basée sur le fonctionnement standard
  */
  procedure sampleProcess
  is
    lMovementSort   varchar2(1);
    lDefaultStockId GCO_PRODUCT.STM_STOCK_ID%type;
    lMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lOrderNo        varchar2(30);
    lPlanifDate     date;
    lImputation     varchar2(30);
    lStockId        STM_STOCK.STM_STOCK_ID%type;
  begin
    -- recherche de l'id du stock selon la configuration
    lStockId  := STM_FUNCTIONS.GetPublicStockId(PCS.PC_CONFIG.GetConfig('STM_KLS_STOCK') );

    -- recherche de l'id stock par défaut du bien.
    begin
      select stm_stock_id
        into lDefaultStockId
        from gco_product
       where gco_good_id = STM_PRC_KLS.gCurrentStockMovement.GCO_GOOD_ID;
    --
    exception
      -- S'il s'agit d'un service ou pseudo-bien, le gco_product n'est pas identifié
      when no_data_found then
        lDefaultStockId  := null;
    end;

    -- comparaison des stocks id
    if     (lDefaultStockId is not null)
       and   -- Stock par défaut existe
           (lStockId = lDefaultStockId)
       and   -- Stock config = stock par défaut
           (lStockId = STM_PRC_KLS.gCurrentStockMovement.STM_STOCK_ID) then   -- Stock config = stock du mouvement
      -- recherche le type afin de savoir si on a affaire . une entrée ou une sortie
      -- et si le genre de mouvement est utilisé dans la mise à jour KLS
      select max(decode(c_movement_sort, 'ENT', 'E', 'SOR', 'S') )
        into lMovementSort
        from stm_movement_kind
       where stm_movement_kind_id = STM_PRC_KLS.gCurrentStockMovement.STM_MOVEMENT_KIND_ID
         and mok_export_mvt = 1;

      if lMovementSort is not null then
        -- recherche de la référence article
        select max(GOO_MAJOR_REFERENCE)
          into lMajorReference
          from GCO_GOOD
         where GCO_GOOD_ID = STM_PRC_KLS.gCurrentStockMovement.GCO_GOOD_ID;

        -- recherche du numéro d'ordre
        if STM_PRC_KLS.gCurrentStockMovement.DOC_POSITION_DETAIL_ID is null then
          lOrderNo     := to_char(STM_PRC_KLS.gCurrentStockMovement.STM_STOCK_MOVEMENT_ID);
          lPlanifDate  := STM_PRC_KLS.gCurrentStockMovement.SMO_MOVEMENT_DATE;

          -- recherche de la description de l'vImputation
          select max(GOO_MAJOR_REFERENCE)
            into lImputation
            from FAL_LOT
               , GCO_GOOD
           where FAL_LOT.LOT_REFCOMPL = STM_PRC_KLS.gCurrentStockMovement.SMO_WORDING
             and FAL_LOT.GCO_GOOD_ID = GCO_GOOD.GCO_GOOD_ID;
        else
          -- recherche du numéro de document et de la date de planification
          select b.DMT_NUMBER
               , b.DMT_DATE_DOCUMENT
            into lOrderNo
               , lPlanifDate
            from doc_position_detail a
               , doc_document b
           where a.DOC_POSITION_DETAIL_ID = STM_PRC_KLS.gCurrentStockMovement.DOC_POSITION_DETAIL_ID
             and b.DOC_DOCUMENT_ID = a.DOC_DOCUMENT_ID;

          -- recherche de la description de l'vImputation
          select substr(max(PER_NAME), 1, 30)
            into lImputation
            from PAC_PERSON
           where PAC_PERSON_ID = STM_PRC_KLS.gCurrentStockMovement.PAC_THIRD_ID;
        end if;

        insert into STM_KLS_BUFFER
                    (STM_KLS_BUFFER_ID
                   , KLS_EXPORT
                   , KLS_MOVEMENT_TYPE
                   , KLS_ORDER
                   , KLS_MAJOR_REFERENCE
                   , KLS_LOT
                   , KLS_QUANTITY
                   , STM_STOCK_MOVEMENT_ID
                   , KLS_PLANIF_DATE
                   , KLS_IMPUTATION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (init_id_seq.nextval
                   , 0
                   , lMovementSort
                   , lOrderNo
                   , lMajorReference
                   , STM_PRC_KLS.gCurrentStockMovement.SMO_CHARACTERIZATION_VALUE_1
                   , STM_PRC_KLS.gCurrentStockMovement.SMO_MOVEMENT_QUANTITY
                   , STM_PRC_KLS.gCurrentStockMovement.STM_STOCK_MOVEMENT_ID
                   , lPlanifDate
                   , lImputation
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    end if;
  end sampleProcess;
end STM_PRC_KLS;
