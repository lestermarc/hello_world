--------------------------------------------------------
--  DDL for Package Body STM_PARITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PARITY" 
is
  /**
  * procedure pFillValueDateAndKey
  * Description
  *    rempli les nouveaux champs relatifs au PRCS dans les mouvements de stock
  * @created fp 15.03.2005
  * @lastUpdate
  * @public
  * @param aGoodID : id du bien à mettre à jour
  */
  procedure pFillValueDateAndKey(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iFullUpdate in PTC_RECALC_JOB.PRR_FULL_UPDATE%type)
  is
    cursor crGoodMovements(cGoodId number)
    is
      select   STM_STOCK_MOVEMENT_ID
             , DOC_POSITION_DETAIL_ID
             , SMO_MOVEMENT_DATE
             , SMO_VALUE_DATE
             , STM_MOVEMENT_KIND_ID
             , SMO_PRCS_UPDATED
             , SMO_EXTOURNE_MVT
             , STM2_STM_STOCK_MOVEMENT_ID
          from STM_STOCK_MOVEMENT
         where GCO_GOOD_ID = cGoodId
      order by STM_STOCK_MOVEMENT_ID;

    type ttblGoodMovements is table of crGoodMovements%rowtype;

    cursor crUnAffectedReceiptId(cGoodId number)
    is
      select PDE_SON.DOC_POSITION_DETAIL_ID
           , GRE.DOC_GAUGE_RECEIPT_ID
        from DOC_GAUGE_FLOW_DOCUM GFD
           , DOC_GAUGE_FLOW GFL
           , DOC_POSITION_DETAIL PDE_SON
           , DOC_POSITION_DETAIL PDE_FATHER
           , DOC_DOCUMENT DMT_SON
           , DOC_DOCUMENT DMT_FATHER
           , DOC_GAUGE_RECEIPT GRE
       where PDE_SON.GCO_GOOD_ID = cGoodID
         and PDE_SON.DOC_DOC_POSITION_DETAIL_ID is not null
         and PDE_SON.DOC_GAUGE_RECEIPT_ID is null
         and PDE_FATHER.DOC_POSITION_DETAIL_ID = PDE_SON.DOC_DOC_POSITION_DETAIL_ID
         and DMT_FATHER.DOC_DOCUMENT_ID = PDE_FATHER.DOC_DOCUMENT_ID
         and DMT_SON.DOC_DOCUMENT_ID = PDE_SON.DOC_DOCUMENT_ID
         and GRE.DOC_DOC_GAUGE_ID = DMT_FATHER.DOC_GAUGE_ID
         and GFL.DOC_GAUGE_FLOW_ID = PDE_SON.DOC_GAUGE_FLOW_ID
         and GFD.DOC_GAUGE_ID = DMT_SON.DOC_GAUGE_ID
         and GRE.DOC_GAUGE_FLOW_DOCUM_ID = GFD.DOC_GAUGE_FLOW_DOCUM_ID;

    tblGoodMovements ttblGoodMovements;
    i                pls_integer;
    keyMovementId    STM_STOCK_MOVEMENT.SMO_MOVEMENT_ORDER_KEY%type;
    valueDate        STM_STOCK_MOVEMENT.SMO_VALUE_DATE%type;
    lFirstUpdatePrcs STM_STOCK_MOVEMENT.SMO_UPDATE_PRCS%type;
    lFirstOrderKey   STM_STOCK_MOVEMENT.SMO_MOVEMENT_ORDER_KEY%type;
    lFirstValueDate  STM_STOCK_MOVEMENT.SMO_VALUE_DATE%type;
    lbContinue       boolean;
  begin
    if iFullUpdate = 1 then
      lbContinue  := true;
    else
      -- teste l'état du flag de mise à jour du PRCS sur le premier mouvement
      select SMO_PRCS_UPDATED
           , SMO_MOVEMENT_ORDER_KEY
           , SMO_VALUE_DATE
        into lFirstUpdatePrcs
           , lFirstOrderKey
           , lFirstValueDate
        from STM_STOCK_MOVEMENT
       where STM_STOCK_MOVEMENT_ID = (select min(STM_STOCK_MOVEMENT_ID)
                                        from STM_STOCK_MOVEMENT
                                       where GCO_GOOD_ID = iGoodId);

      -- si le premier mouvement n'a pas le flag SMO_PRCS_UPDATED initialisé,
      -- alors on lance la procédure
      lbContinue  :=    lFirstUpdatePrcs is null
                     or lFirstOrderKey is null
                     or lFirstValueDate is null;
    end if;

    if lbContinue then
      for tplUnAffectedReceiptId in crUnAffectedReceiptId(iGoodId) loop
        update DOC_POSITION_DETAIL
           set DOC_GAUGE_RECEIPT_ID = tplUnAffectedReceiptId.DOC_GAUGE_RECEIPT_ID
         where DOC_POSITION_DETAIL_ID = tplUnAffectedReceiptId.DOC_POSITION_DETAIL_ID;
      end loop;

      open crGoodMovements(iGoodId);

      -- insertion de toutes les info des mouvements dans un tableau
      fetch crGoodMovements
      bulk collect into tblGoodMovements;

      close crGoodMovements;

      -- si le tableau n'est pas vide
      if tblGoodMovements.count > 0 then
        -- pour chaque mouvement
        for i in tblGoodMovements.first .. tblGoodMovements.last loop
          begin
            -- recherche du mouvement parent correspondant
            -- si pas trouvé
            select parent.STM_STOCK_MOVEMENT_ID
                 , parent.SMO_VALUE_DATE
              into keyMovementId
                 , valueDate
              from DOC_POSITION_DETAIL PDE
                 , DOC_GAUGE_RECEIPT GAR
                 , STM_STOCK_MOVEMENT son
                 , STM_STOCK_MOVEMENT parent
                 , stm_movement_kind mok_son
                 , stm_movement_kind mok_parent
             where PDE.DOC_POSITION_DETAIL_ID = tblGoodMovements(i).DOC_POSITION_DETAIL_ID
               and SON.STM_STOCK_MOVEMENT_ID = tblGoodMovements(i).STM_STOCK_MOVEMENT_ID
               and parent.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
               and parent.smo_extourne_mvt = 0
               and son.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
               and GAR.DOC_GAUGE_RECEIPT_ID = PDE.DOC_GAUGE_RECEIPT_ID
               and GAR.GAR_TRANSFERT_MOVEMENT_DATE = 1
               and mok_parent.stm_movement_kind_id = parent.stm_movement_kind_id
               and mok_parent.C_MOVEMENT_TYPE <> 'EXE'
               and mok_son.stm_movement_kind_id = son.stm_movement_kind_id
               and mok_parent.C_MOVEMENT_SORT = mok_son.C_MOVEMENT_SORT
               and sign(son.smo_document_quantity) = sign(parent.smo_document_quantity);

            update STM_STOCK_MOVEMENT
               set SMO_PRCS_UPDATED = nvl(tblGoodMovements(i).SMO_PRCS_UPDATED, 0)
                 , SMO_MOVEMENT_ORDER_KEY = keyMovementId
                 , SMO_VALUE_DATE = valueDate
             where STM_STOCK_MOVEMENT_ID = tblGoodMovements(i).STM_STOCK_MOVEMENT_ID;

            update DOC_POSITION_DETAIL
               set PDE_MOVEMENT_DATE = valueDate
             where DOC_POSITION_DETAIL_ID = tblGoodMovements(i).DOC_POSITION_DETAIL_ID;
          exception
            when no_data_found then
              -- mouvement non extourné, cas général
              if tblGoodMovements(i).SMO_EXTOURNE_MVT = 0 then
                keyMovementId  := tblGoodMovements(i).STM_STOCK_MOVEMENT_ID;
              -- Extourne
              else
                if tblGoodMovements(i).DOC_POSITION_DETAIL_ID is not null then
                  keyMovementId  := tblGoodMovements(i).STM2_STM_STOCK_MOVEMENT_ID;
                else
                  -- Si non lié à un document alors key movement est le mouvement lui-même et la date valeur est la date du mouvement (DEVLOG-16209)
                  keyMovementId                       := tblGoodMovements(i).STM_STOCK_MOVEMENT_ID;
                  tblGoodMovements(i).SMO_VALUE_DATE  := tblGoodMovements(i).SMO_MOVEMENT_DATE;
                end if;
              end if;

              update STM_STOCK_MOVEMENT
                 set SMO_PRCS_UPDATED = nvl(tblGoodMovements(i).SMO_PRCS_UPDATED, 0)
                   , SMO_MOVEMENT_ORDER_KEY = keyMovementId
                   , SMO_VALUE_DATE = nvl(tblGoodMovements(i).SMO_VALUE_DATE, tblGoodMovements(i).SMO_MOVEMENT_DATE)
               where STM_STOCK_MOVEMENT_ID = tblGoodMovements(i).STM_STOCK_MOVEMENT_ID;
            when others then
              raise_application_error(-20000
                                    , 'DOC_POSITION_DETAIL_ID=' ||
                                      tblGoodMovements(i).DOC_POSITION_DETAIL_ID ||
                                      ', STM_STOCK_MOVEMENT_ID=' ||
                                      tblGoodMovements(i).STM_STOCK_MOVEMENT_ID ||
                                      chr(13) ||
                                      sqlerrm ||
                                      DBMS_UTILITY.Format_Error_Backtrace
                                     );
          end;
        end loop;
      end if;
    end if;
  end pFillValueDateAndKey;

  /**
  * procedure pUpdateFlags
  * Description
  *    Mise à jour sur les mouvements de stock du Flag de mise à jour du PRCS
  *    et du flag d'extourne
  * @created fp 24.10.2011
  * @lastUpdate fp 01.02.2012
  * @public
  * @param iGoodId : bien à traiter
  */
  procedure pUpdateFlags(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iUpdatePrcsFlag in boolean)
  is
    vCRUD_DEF       FWK_I_TYP_DEFINITION.t_crud_def;
    lUpdatePrcsFlag number(1);
  begin
    lUpdatePrcsFlag  := bool2byte(iUpdatePrcsFlag);

    update STM_STOCK_MOVEMENT
       set SMO_UPDATE_PRCS =
             case
               -- pas de mise à jour du PRCS pour les mouvements portant sur un stock virtuel
             when STM_LIB_STOCK.IsVirtual(STM_STOCK_ID) = 1 then 0
               -- Si pas de mise à jour demandée, pas de changement
             when lUpdatePrcsFlag = 0
             and SMO_UPDATE_PRCS is not null then SMO_UPDATE_PRCS
               -- Mise à jour du flag selon valeur actuelle
             else (select MOK_COSTPRICE_USE
                     from STM_MOVEMENT_KIND
                    where STM_MOVEMENT_KIND_ID = STM_STOCK_MOVEMENT.STM_MOVEMENT_KIND_ID)
             end
         , SMO_EXTOURNE_MVT = nvl(SMO_EXTOURNE_MVT, sign(nvl(STM2_STM_STOCK_MOVEMENT_ID, 0) ) )
     where GCO_GOOD_ID = iGoodId;
  end pUpdateFlags;

  /**
  * procedure pInitOriginalValues
  * Description
  *   Initialisation des valeurs originales pour les mouvements dont ces champs n'auraient
  *   pas encore été mis à jour. (code déplacé pour meilleure lisibilité)
  * @created fp 24.10.2011
  * @lastUpdate
  * @public
  * @param iGoodId : bien à traiter
  */
  procedure pInitOriginalValues(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
  is
    vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    update STM_STOCK_MOVEMENT
       set SMO_MOVEMENT_PRICE_ORIG = SMO_MOVEMENT_PRICE
         , SMO_UNIT_PRICE_ORIG = SMO_UNIT_PRICE
         , SMO_REFERENCE_UNIT_PRICE_ORIG = SMO_REFERENCE_UNIT_PRICE
         , SMO_PRCS_VALUE_ORIG = SMO_PRCS_VALUE
     where GCO_GOOD_ID = iGoodId
       and SMO_MOVEMENT_PRICE_ORIG is null;
  end pInitOriginalValues;

  /**
  * procedure pForceUpdatePrcsFlag
  * Description
  *    Réinitialisation du flag de mise à jour du PRCS afin que tous les mouvements
  *    soient traités dans le recalcul
  * @created fp 24.10.2011
  * @lastUpdate
  * @public
  * @param iGoodId : bien à traiter
  */
  procedure pForceUpdatePrcsFlag(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
  is
    vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- mise à jour du flag de recalcul
    -- sans utiliser le framework pour cause de performances
    update STM_STOCK_MOVEMENT
       set SMO_PRCS_UPDATED = 0
     where GCO_GOOD_ID = iGoodId;
  end pForceUpdatePrcsFlag;

  /**
  * procedure pUpdateDebitNotes
  * Description
  *   Mise à jour du prix du mouvement sur les détails de positions de notes de débit
  *   et sur les mouvements liés à ces notes de débit
  * @created fp 24.10.2011
  * @lastUpdate
  * @public
  * @param iGoodId : bien à traiter
  */
  procedure pUpdateDebitNotes(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
  is
    lMvtValue       STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    lInitPrice      number(1)                                    := 1;
    lTransCostPrice number(1)                                    := 0;
  begin
    for ltplDebitNoteMvt in (select SMO.STM_STOCK_MOVEMENT_ID
                                  , SMO.DOC_POSITION_DETAIL_ID
                                  , PDE.DOC_GAUGE_RECEIPT_ID
                                  , PDE.DOC_GAUGE_COPY_ID
                               from STM_STOCK_MOVEMENT SMO
                                  , DOC_POSITION_DETAIL PDE
                              where SMO.GCO_GOOD_ID = iGoodId
                                and PDE.DOC_POSITION_DETAIL_ID = SMO.DOC_POSITION_DETAIL_ID
                                and DOC_I_LIB_GAUGE.IsDebitNote(iDetailId => SMO.DOC_POSITION_DETAIL_ID) = 1) loop
      -- recherche d'informations dans le flux de décharge ou de copie
      if ltplDebitNoteMvt.DOC_GAUGE_RECEIPT_ID is not null then
        select GAR_INIT_PRICE_MVT
          into lInitPrice
          from DOC_GAUGE_RECEIPT
         where DOC_GAUGE_RECEIPT_ID = ltplDebitNoteMvt.DOC_GAUGE_RECEIPT_ID;
      elsif ltplDebitNoteMvt.DOC_GAUGE_COPY_ID is not null then
        select GAC_INIT_PRICE_MVT
          into lInitPrice
          from DOC_GAUGE_COPY
         where DOC_GAUGE_COPY_ID = ltplDebitNoteMvt.DOC_GAUGE_COPY_ID;
      end if;

      if lInitPrice = 1 then
        lMvtValue  := DOC_POSITION_DETAIL_FUNCTIONS.CalcPdeMvtValue(ltplDebitNoteMvt.DOC_POSITION_DETAIL_ID);
      else
        lMvtValue  := 0;
      end if;

      declare
        vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPositionDetail, vCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'DOC_POSITION_DETAIL_ID', ltplDebitNoteMvt.DOC_POSITION_DETAIL_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'PDE_MOVEMENT_VALUE', lMvtValue);
        FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
      end;

      declare
        vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', ltplDebitNoteMvt.STM_STOCK_MOVEMENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_MOVEMENT_PRICE', lMvtValue);
        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_VALUE', lMvtValue);
        FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
      end;
    end loop;
  end pUpdateDebitNotes;

  /**
  * procedure pGetCreditNoteMovementPrice
  * Description
  *   Recherche le prix du mouvement d'une note de crédit
  * @created fp 28.10.2011
  * @lastUpdate
  * @public
  * @param iDetailId : detail de position à traiter
  */
  function pGetCreditNoteMovementPrice(iDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type
  is
    lMvtValue       STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type   := 0;
    lUnitCostPrice  DOC_POSITION.POS_UNIT_COST_PRICE%type;
    lInitPrice      number(1)                                    := 1;
    lTransCostPrice number(1)                                    := 0;

    -- recherche du prix de revient untitaire d'un detail position
    function pGetUnitPrice(iDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
      return DOC_POSITION.POS_UNIT_COST_PRICE%type
    is
      lResult DOC_POSITION.POS_UNIT_COST_PRICE%type;
    begin
      select POS.POS_UNIT_COST_PRICE
        into lResult
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
       where PDE.DOC_POSITION_DETAIL_ID = iDetailId
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID;

      return lResult;
    end pGetUnitPrice;
  begin
    -- boucle sur une ligne
    for ltplCreditNoteMvt in (select PDE.DOC_GAUGE_RECEIPT_ID
                                   , PDE.DOC_GAUGE_COPY_ID
                                   , PDE.DOC_POSITION_ID
                                   , PDE.GCO_GOOD_ID
                                   , case
                                       when PDE.DOC_GAUGE_RECEIPT_ID is not null then PDE.DOC_DOC_POSITION_DETAIL_ID
                                       when PDE.DOC_GAUGE_COPY_ID is not null then PDE.DOC2_DOC_POSITION_DETAIL_ID
                                       else null
                                     end DOC_PARENT_POSITION_DETAIL_ID
                                   , nvl(PDE.PAC_THIRD_TARIFF_ID, PDE.PAC_THIRD_ID) PAC_THIRD_TARIFF_ID
                                   , GOO.C_MANAGEMENT_MODE
                                from DOC_POSITION_DETAIL PDE
                                   , GCO_GOOD GOO
                               where PDE.DOC_POSITION_DETAIL_ID = iDetailId
                                 and GOO.GCO_GOOD_ID = PDE.GCO_GOOD_ID) loop
      -- recherche d'informations dans le flux de décharge
      if ltplCreditNoteMvt.DOC_GAUGE_RECEIPT_ID is not null then
        select GAR_INIT_PRICE_MVT
             , GAR_INIT_COST_PRICE
          into lInitPrice
             , lTransCostPrice
          from DOC_GAUGE_RECEIPT
         where DOC_GAUGE_RECEIPT_ID = ltplCreditNoteMvt.DOC_GAUGE_RECEIPT_ID;
      -- recherche d'informations dans le flux de copie
      elsif ltplCreditNoteMvt.DOC_GAUGE_COPY_ID is not null then
        select GAC_INIT_PRICE_MVT
             , GAC_INIT_COST_PRICE
          into lInitPrice
             , lTransCostPrice
          from DOC_GAUGE_COPY
         where DOC_GAUGE_COPY_ID = ltplCreditNoteMvt.DOC_GAUGE_COPY_ID;
      -- création directe (sans copie/décharge)
      else
        -- Recherche du prix de revient unitaire
        lUnitCostPrice  :=
          GCO_FUNCTIONS.GetCostPriceWithManagementMode(ltplCreditNoteMvt.GCO_GOOD_ID
                                                     , ltplCreditNoteMvt.PAC_THIRD_TARIFF_ID
                                                     , ltplCreditNoteMvt.C_MANAGEMENT_MODE
                                                      );
      end if;

      -- si initialisation du prix
      if lInitPrice = 1 then
        -- Initialisation du prix de revient unitaire
        if lTransCostPrice = 0 then
          /* La mise à jour du prix de revient ne doit pas se faire si le bien est
             géré au prix de revient fixe et que le nouveau prix de revient du bien
             est à 0. */
          if     (ltplCreditNoteMvt.C_MANAGEMENT_MODE = '3')
             and (lUnitCostPrice = 0) then
            lUnitCostPrice  := pGetUnitPrice(iDetailId);   -- pas de changement
          else
            -- Recherche du prix de revient unitaire
            lUnitCostPrice  :=
              GCO_FUNCTIONS.GetCostPriceWithManagementMode(ltplCreditNoteMvt.GCO_GOOD_ID
                                                         , ltplCreditNoteMvt.PAC_THIRD_TARIFF_ID
                                                         , ltplCreditNoteMvt.C_MANAGEMENT_MODE
                                                          );
          end if;
        -- reprise du prix de revient depuis le document parent
        else
          lUnitCostPrice  := pGetUnitPrice(ltplCreditNoteMvt.DOC_PARENT_POSITION_DETAIL_ID);
        end if;
      end if;

      -- mise à jour du prix de revient de la positio(prix utilisé dans le calcul du prix du mouvement)
      update DOC_POSITION
         set POS_UNIT_COST_PRICE = lUnitCostPrice
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = ltplCreditNoteMvt.DOC_POSITION_ID
         and POS_UNIT_COST_PRICE <> lUnitCostPrice;

      -- calcul du prix du mouvement
      lMvtValue  := DOC_POSITION_DETAIL_FUNCTIONS.CalcPdeMvtValue(iDetailId);
    end loop;

    return lMvtValue;
  end pGetCreditNoteMovementPrice;

  /**
  * procedure pSetExtournePrcsValue
  * Description
  *    Initialisation, sur le mouvement d'extourne, de la valeur PRCS identique
  *    à celle du mouvement extourné
  * @created fp 25.10.2011
  * @lastUpdate
  * @public
  * @param iGoodId : bien à traiter
  */
  procedure pSetExtournePrcsValue(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
  is
    vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplExtourneMvt in (select SMO.STM_STOCK_MOVEMENT_ID
                                 , SMO.DOC_POSITION_DETAIL_ID
                                 , PDE.DOC_GAUGE_RECEIPT_ID
                                 , PDE.DOC_GAUGE_COPY_ID
                              from STM_STOCK_MOVEMENT SMO
                                 , DOC_POSITION_DETAIL PDE
                             where SMO.GCO_GOOD_ID = iGoodId
                               and SMO.SMO_EXTOURNE_MVT = 1) loop
      null;
    end loop;
  end pSetExtournePrcsValue;

  /**
  * Description
  *   recalcul du PRCS d'un bien en fonction de ses mouvements de stock (nouvelle méthode)
  */
  procedure majGoodPrcs2(
    aGoodId      in GCO_GOOD.GCO_GOOD_ID%type
  , aRecalcJobId in PTC_FIXED_COSTPRICE.PTC_RECALC_JOB_ID%type
  , aRecalcMode  in PTC_RECALC_JOB.C_PRCS_RECALC_MODE%type default null
  , aFullReset   in PTC_RECALC_JOB.PRR_FULL_UPDATE%type default null
  )
  is
    cursor crMovement(cGoodId GCO_GOOD.GCO_GOOD_ID%type, cPRCSMode number)
    is
      select   A.STM_STOCK_MOVEMENT_ID
             , nvl(A.STM_STM_STOCK_MOVEMENT_ID, 0) stm_stm_stock_movement_id
             , A.STM_STOCK_ID
             , B.STM_MOVEMENT_KIND_ID
             , C.GCO_GOOD_ID
             , C.C_MANAGEMENT_MODE
             , B.C_MOVEMENT_SORT
             , B.C_MOVEMENT_CODE
             , B.C_MOVEMENT_TYPE
             , A.SMO_MOVEMENT_QUANTITY
             , A.SMO_MOVEMENT_PRICE
             , A.SMO_TARGET_PRICE
             , A.SMO_EXTOURNE_MVT
             , A.STM2_STM_STOCK_MOVEMENT_ID
             , trunc(nvl(A.SMO_VALUE_DATE, A.SMO_MOVEMENT_DATE) ) SMO_VALUE_DATE
             , A.DOC_POSITION_DETAIL_ID
             , DP.DOC_POSITION_ID
             , A.SMO_UPDATE_PRCS
             , A.SMO_PRCS_BEFORE
             , A.SMO_PRCS_AFTER
             , A.SMO_PRCS_ADDED_QUANTITY_BEFORE
             , A.SMO_PRCS_ADDED_QUANTITY_AFTER
             , A.SMO_PRCS_ADDED_VALUE_BEFORE
             , A.SMO_PRCS_ADDED_VALUE_AFTER
             , A.SMO_PRCS_UPDATED
             , E.DOC_DOC_POSITION_DETAIL_ID
             , F.GAR_INIT_COST_PRICE
             , A.SMO_REFERENCE_UNIT_PRICE
          from STM_STOCK_MOVEMENT A
             , STM_MOVEMENT_KIND B
             , GCO_GOOD C
             , GCO_GOOD_CALC_DATA D
             , DOC_POSITION DP
             , DOC_POSITION_DETAIL E
             , DOC_GAUGE_RECEIPT F
         where A.STM_MOVEMENT_KIND_ID = B.STM_MOVEMENT_KIND_ID
           and C.GCO_GOOD_ID = A.GCO_GOOD_ID
           and C.GCO_GOOD_ID = D.GCO_GOOD_ID
           and A.DOC_POSITION_ID = DP.DOC_POSITION_ID(+)
           and E.DOC_POSITION_DETAIL_ID(+) = A.DOC_POSITION_DETAIL_ID
           and F.DOC_GAUGE_RECEIPT_ID(+) = E.DOC_GAUGE_RECEIPT_ID
           and C.GCO_GOOD_ID = cGoodId
           and (   cPRCSMode = '2'
                or a.DOC_POSITION_DETAIL_ID is null
                or (    not exists(
                          select DOC_POSITION_DETAIL_ID
                            from DOC_POSITION_DETAIL PDE
                               , DOC_POSITION POS
                               , DOC_GAUGE_STRUCTURED GAS
                           where PDE.DOC_POSITION_DETAIL_ID = a.DOC_POSITION_DETAIL_ID
                             and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                             and GAS.DOC_GAUGE_ID = PDE.DOC_GAUGE_ID
                             and GAS.C_GAUGE_TITLE in('2', '3')
                             and POS.C_DOC_POS_STATUS <> '04')
                    and not exists(
                          select PDE.DOC_POSITION_DETAIL_ID
                            from DOC_POSITION_DETAIL PDE
                               , DOC_POSITION POS
                               , DOC_GAUGE_STRUCTURED GAS
                               , DOC_POSITION_DETAIL PDESON
                               , DOC_POSITION POSSON
                           where PDE.DOC_POSITION_DETAIL_ID = a.DOC_POSITION_DETAIL_ID
                             and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                             and GAS.DOC_GAUGE_ID = PDE.DOC_GAUGE_ID
                             and GAS.C_GAUGE_TITLE in('2', '3')
                             and POS.C_DOC_POS_STATUS = '04'
                             and PDESON.DOC_DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                             and POSSON.DOC_POSITION_ID = PDESON.DOC_POSITION_ID
                             and POSSON.C_DOC_POS_STATUS <> '04')
                   )
               )
      order by nvl(A.SMO_VALUE_DATE, A.SMO_MOVEMENT_DATE)
             , SMO_MOVEMENT_ORDER_KEY
             , DOC_POSITION_ID
             , STM_STOCK_MOVEMENT_ID;

    vTplRecalcJob     PTC_RECALC_JOB%rowtype;
    vBidon1           number(20, 6);
    lPrcsBeforeRecalc PTC_RECALC_JOB_LOG.RJL_PRCS_BEFORE%type              := GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(aGoodId);
    lPrcsAfterRecalc  PTC_RECALC_JOB_LOG.RJL_PRCS_AFTER%type               := 0;
    vQtyBefore        GCO_GOOD_CALC_DATA.GOO_ADDED_QTY_COST_PRICE%type     := 0;
    vQtyAfter         GCO_GOOD_CALC_DATA.GOO_ADDED_QTY_COST_PRICE%type     := 0;
    vValueBefore      GCO_GOOD_CALC_DATA.GOO_ADDED_VALUE_COST_PRICE%type   := 0;
    vValueAfter       GCO_GOOD_CALC_DATA.GOO_ADDED_VALUE_COST_PRICE%type   := 0;
    vPrcsBefore       GCO_GOOD_CALC_DATA.GOO_BASE_COST_PRICE%type          := 0;
    vPrcsAfter        GCO_GOOD_CALC_DATA.GOO_BASE_COST_PRICE%type          := 0;
    vPrcsBeforeRecalc GCO_GOOD_CALC_DATA.GOO_BASE_COST_PRICE%type          := 0;
    vBlnRecalcMode    boolean                                              := false;
    vBlnClearMode     boolean                                              := false;
    lUpdatePrcsTra    STM_STOCK_MOVEMENT.SMO_UPDATE_PRCS%type;
    vScheduleStepId   DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type;
    vMvtUnitPrice     GCO_GOOD_CALC_DATA.GOO_BASE_COST_PRICE%type;
    vMvtUnitPrcsValue STM_STOCK_MOVEMENT.SMO_PRCS_VALUE%type;
    vLastValueDate    date;
    vManagementMode   GCO_GOOD.C_MANAGEMENT_MODE%type                      := GCO_FUNCTIONS.GetManagementMode(aGoodId);
    vFirstMove        boolean                                              := true;

    /**
    * procedure pResetPrcsUpdated
    * Description
    *   mise à 0 du flag SMO_PRCS_UPDATED
    * @created fp 24.10.2011
    * @lastUpdate
    * @public
    * @param iMovementId : id du mouvement à mettre à jour
    */
    procedure pResetPrcsUpdated(iMovementId in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type)
    is
      vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', iMovementId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_UPDATED', 0);
      FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
    end pResetPrcsUpdated;

    /**
    * procedure pGetExtournedMvtInfo
    * Description
    *   recherche d'informations sur le mouvement extourné
    * @created fp 25.10.2011
    * @lastUpdate
    * @public
    * @param iMovementId : id du mouvement d'extourne
    */
    procedure pGetExtournedMvtInfo(
      iOrigMovementId   in     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
    , iMovementQuantity in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
    , oMvtPrice         out    STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type
    , oMvtPrcsValue     out    STM_STOCK_MOVEMENT.SMO_PRCS_VALUE%type
    )
    is
    begin
      select -SMO_MOVEMENT_PRICE * -iMovementQuantity / SMO_MOVEMENT_QUANTITY
           , -SMO_PRCS_VALUE * -iMovementQuantity / SMO_MOVEMENT_QUANTITY
        into oMvtPrice
           , oMvtPrcsValue
        from STM_STOCK_MOVEMENT SMO
       where STM_STOCK_MOVEMENT_ID = iOrigMovementId;
    end pGetExtournedMvtInfo;

    /**
    * function pIsMovement
    * Description
    *
    * @created fp 03.12.2012
    * @lastUpdate
    * @public
    * @param
    * @return
    */
    function pIsMovement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
      return boolean
    is
      lCount pls_integer;
    begin
      select count(*)
        into lCount
        from STM_STOCK_MOVEMENT SMO
       where GCO_GOOD_ID = iGoodId;

      return lCount > 0;
    end pIsMovement;

    /**
    * procedure pLogInfo
    * Description
    *
    * @created fp 23.02.2012
    * @lastUpdate
    * @public
    * @param
    */
    procedure pLogInfo(
      iRecalcJobId in PTC_RECALC_JOB.PTC_RECALC_JOB_ID%type
    , iGoodId      in PTC_RECALC_JOB_LOG.GCO_GOOD_ID%type
    , iPRCSBefore  in PTC_RECALC_JOB_LOG.RJL_PRCS_BEFORE%type default null
    , iPRCSAfter   in PTC_RECALC_JOB_LOG.RJL_PRCS_AFTER%type default null
    , iError       in PTC_RECALC_JOB_LOG.RJL_ERROR%type default null
    )
    is
      vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcRecalcJobLog, vCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'PTC_RECALC_JOB_ID', iRecalcJobId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'GCO_GOOD_ID', iGoodId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'RJL_PRCS_BEFORE', iPRCSBefore);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'RJL_PRCS_AFTER', iPRCSAfter);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'RJL_ERROR', iError);
      FWK_I_MGT_ENTITY.InsertEntity(vCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
    end;
  begin
    if pIsMovement(aGoodId) then
      -- tuple du job de recalcul
      begin
        select *
          into vTplRecalcJob
          from PTC_RECALC_JOB
         where PTC_RECALC_JOB_ID = aRecalcJobId;

        if aRecalcMode is not null then
          vTplRecalcJob.C_PRCS_RECALC_MODE  := aRecalcMode;
        end if;

        if aFullReset is not null then
          vTplRecalcJob.PRR_FULL_UPDATE  := aFullReset;
        end if;
      exception
        when no_data_found then
          raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Mauvais ID de job de recalcul!') );
      end;

      -- si on met à jour les flag de mise à jour du PRCS sur les mouvements
      -- selon le flag dans les genres de mouvements
      pUpdateFlags(aGoodId, vTplRecalcJob.C_PRCS_RECALC_TYPE = '2');
      -- stockage des valeur originales des mouvements pour les mouvements ou ces valeurs sont non renseignées
      pInitOriginalValues(aGoodId);

      -- force le recalcul de tous les mouvements
      if vTplRecalcJob.PRR_FULL_UPDATE = 1 then
        pForceUpdatePrcsFlag(aGoodId);
      end if;

      -- mise à jour des prix note de débit
      pUpdateDebitNotes(aGoodId);

      -- end if;
      begin
        -- mise à jour, si besoin du champ de tri des mouvements
        pFillValueDateAndKey(aGoodId, vTplRecalcJob.PRR_FULL_UPDATE);

        -- Remise à 0 des compteurs PRCS, seulement si reinitialisation totale et mode "Recalcul PRCS"
        if     vTplRecalcJob.C_PRCS_RECALC_MODE = '2'
           and vTplRecalcJob.PRR_FULL_UPDATE = 1 then
          GCO_I_PRC_GOOD.resetCostprice(aGoodId);
        end if;

        -- pour tous les mouvements du bien
        for tplMovement in crMovement(aGoodId, vTplRecalcJob.C_PRCS_RECALC_MODE) loop
          declare
            vPrcsValue GCO_GOOD_CALC_DATA.GOO_BASE_COST_PRICE%type;
            vMvtPrice  STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
          begin
            -- en mode création PRF, à partir du moment ou on dépasse la date limite de recalcul,
            -- le PRF est déjà créé et le flag SMO_PRCS_UPDATED doit être remis à 0 pour les mouvements restants
            if vBlnClearMode then
              pResetPrcsUpdated(tplMovement.STM_STOCK_MOVEMENT_ID);
            else
              -- si on est pas en mode de recalculation et que l'on tombe sur le premier mouvement à recalculer
              if not vBlnRecalcMode then
                if    (nvl(tplMovement.SMO_PRCS_UPDATED, 0) = 0)
                   or vTplRecalcJob.PRR_FULL_UPDATE = 1
                   or (    vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3')
                       and tplMovement.SMO_VALUE_DATE > nvl(vTplRecalcJob.PRR_REFERENCE_DATE, sysdate) ) then
                  vBlnRecalcMode  := true;

                  if vTplRecalcJob.C_PRCS_RECALC_MODE = '2' then
                    -- mise à jour des compteurs PRCS selon avant dernier mouvement
                    update GCO_GOOD_CALC_DATA
                       set GOO_ADDED_QTY_COST_PRICE = vQtyBefore
                         , GOO_ADDED_VALUE_COST_PRICE = vValueBefore
                         , GOO_BASE_COST_PRICE = vPrcsBefore
                     where GCO_GOOD_ID = aGoodId;
                  end if;
                end if;

                vQtyBefore    := nvl(tplMovement.SMO_PRCS_ADDED_QUANTITY_BEFORE, 0);
                vValueBefore  := nvl(tplMovement.SMO_PRCS_ADDED_VALUE_BEFORE, 0);
                vPrcsBefore   := nvl(tplMovement.SMO_PRCS_BEFORE, 0);
                vQtyAfter     := nvl(tplMovement.SMO_PRCS_ADDED_QUANTITY_AFTER, 0);
                vValueAfter   := nvl(tplMovement.SMO_PRCS_ADDED_VALUE_AFTER, 0);
                vPrcsAfter    := nvl(tplMovement.SMO_PRCS_AFTER, 0);
              end if;

              --valeur du PRCS du dernier mouvement
              vPrcsBeforeRecalc  := nvl(tplMovement.SMO_PRCS_AFTER, 0);

              if     vBlnRecalcMode
                 and (    (    vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3')
                           and (tplMovement.SMO_VALUE_DATE <= nvl(vTplRecalcJob.PRR_REFERENCE_DATE, sysdate) ) )
                      or vTplRecalcJob.C_PRCS_RECALC_MODE = '2'
                     ) then
                -- Les mouvements de correction du PRF sont ignorés si on est en mode reset des mouvements de correction
                if     tplMovement.C_MOVEMENT_CODE = '014'
                   and vTplRecalcJob.PRR_USE_CORR_MVT = 0 then
                  -- Mise à jour des infos relatives au PRCS sur le mouvement (même si le mouvement n'influence pas le PRCS)
                  declare
                    vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
                  begin
                    FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplMovement.STM_STOCK_MOVEMENT_ID);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_BEFORE', vQtyAfter);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_AFTER', vQtyAfter);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_BEFORE', vValueAfter);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_AFTER', vValueAfter);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_BEFORE', vPrcsAfter);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_AFTER', vPrcsAfter);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_VALUE', vPrcsAfter * tplMovement.SMO_MOVEMENT_QUANTITY);
                    FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                                  , 'SMO_PRCS_UPDATED'
                                                  , case
                                                      when vTplRecalcJob.C_PRCS_RECALC_MODE = '1' then 1
                                                      when vTplRecalcJob.C_PRCS_RECALC_MODE = '3' then 1
                                                      else tplMovement.SMO_PRCS_UPDATED
                                                    end
                                                   );
                    FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
                    FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
                  end;
                -- Cas Normal (mouvement pris en compte)
                else
                  -- recherche du flag de mise à jour du PRCS sur le genre de mouvement de t4ransfert
                  if tplMovement.STM_STM_STOCK_MOVEMENT_ID <> 0 then
                    select SMO_UPDATE_PRCS
                      into lUpdatePrcsTra
                      from STM_STOCK_MOVEMENT
                     where STM_STOCK_MOVEMENT_ID = tplMovement.STM_STM_STOCK_MOVEMENT_ID;
                  end if;

                  -- Cas d'un nouvement d'extourne, on reprend les valeurs du mouvement extourné
                  if     tplMovement.SMO_EXTOURNE_MVT = 1
                     and tplMovement.STM2_STM_STOCK_MOVEMENT_ID is not null then
                    pGetExtournedMvtInfo(tplMovement.STM2_STM_STOCK_MOVEMENT_ID, tplMovement.SMO_MOVEMENT_QUANTITY, vMvtPrice, vPrcsValue);
                    -- mise à jour du PRCS, mais en calculant le prix du mouvement selon SMO_TARGET_PRICE
                    STM_COSTPRICE.GCO_Update_Costprice(aGoodId           => tplMovement.GCO_GOOD_ID
                                                     , aStockId          => tplMovement.STM_STOCK_ID
                                                     , aMovementKindId   => tplMovement.STM_MOVEMENT_KIND_ID
                                                     , aMoveQty          => tplMovement.SMO_MOVEMENT_QUANTITY
                                                     , aMoveValue        => vMvtPrice
                                                     , aPriceUpdated     => vBidon1
                                                     , aOldQtyPrcs       => vQtyBefore
                                                     , aOldValuePrcs     => vValueBefore
                                                     , aOldPrcs          => vPrcsBefore
                                                     , aNewQtyPrcs       => vQtyAfter
                                                     , aNewValuePrcs     => vValueAfter
                                                     , aNewPrcs          => vPrcsAfter
                                                     , aPrcsValue        => vPrcsValue
                                                     , aVirtual          => (vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') )
                                                     , aUpdateMvt        => true
                                                     , aUpdatePrcs       => tplMovement.SMO_UPDATE_PRCS
                                                     , aPosDetailId      => tplMovement.DOC_POSITION_DETAIL_ID
                                                      );

                    -- Mise à jour des infos relatives au PRCS sur le mouvement (même si le mouvement n'influence pas le PRCS)
                    declare
                      vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
                    begin
                      FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF, false);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplMovement.STM_STOCK_MOVEMENT_ID);

                      if tplMovement.SMO_MOVEMENT_QUANTITY <> 0 then
                        vMvtUnitPrice  := vMvtPrice / tplMovement.SMO_MOVEMENT_QUANTITY;
                      else
                        vMvtUnitPrice  := -vMvtPrice;
                      end if;

                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_UNIT_PRICE', vMvtUnitPrice);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_MOVEMENT_PRICE', vMvtPrice);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_VALUE', vPrcsValue);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                                    , 'SMO_REFERENCE_UNIT_PRICE'
                                                    , case
                                                        when tplMovement.DOC_POSITION_DETAIL_ID is null then vMvtUnitPrice
                                                        else tplMovement.SMO_REFERENCE_UNIT_PRICE
                                                      end
                                                     );
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_BEFORE', vQtyBefore);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_AFTER', vQtyAfter);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_BEFORE', vValueBefore);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_AFTER', vValueAfter);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_BEFORE', vPrcsBefore);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_AFTER', vPrcsAfter);
                      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                                    , 'SMO_PRCS_UPDATED'
                                                    , case
                                                        when vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') then 1
                                                        else tplMovement.SMO_PRCS_UPDATED
                                                      end
                                                     );
                      FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
                      FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
                    end;
                  -- cas d'un mouvement non-extourné (cas général)
                  else
                    -- mouvements de sortie ou transferts ou correction d'inventaire
                    -- mais pas si c'est le premier mouvement et que c'est un mouvement d'inventaire
                    if     (    (    tplMovement.C_MOVEMENT_SORT = 'SOR'
                                 and DOC_I_LIB_GAUGE.IsDebitNote(iDetailId => tplMovement.DOC_POSITION_DETAIL_ID) = 0)
                            or (    tplMovement.STM_STM_STOCK_MOVEMENT_ID <> 0
                                and tplMovement.SMO_UPDATE_PRCS = lUpdatePrcsTra)
                            or (    tplMovement.C_MOVEMENT_SORT = 'ENT'
                                and DOC_I_LIB_GAUGE.IsCreditNote(iDetailId => tplMovement.DOC_POSITION_DETAIL_ID) = 1)
                            or (tplMovement.C_MOVEMENT_CODE in('001', '002', '003') )
                           )
                       and not(    vFirstMove
                               and tplMovement.C_MOVEMENT_TYPE = 'INV') then
                      if tplMovement.SMO_UPDATE_PRCS = 1 then
                        -- Cas particulier de la correction manuel du PRCS avec prix forcé
                        if     tplMovement.C_MOVEMENT_CODE = '014'
                           and tplMovement.SMO_TARGET_PRICE is not null then
                          begin
                            if tplMovement.C_MOVEMENT_SORT = 'ENT' then
                              vMvtPrice  := (tplMovement.SMO_TARGET_PRICE * vQtyBefore - vValueBefore) / vQtyBefore;
                            else
                              vMvtPrice  := -(tplMovement.SMO_TARGET_PRICE * vQtyBefore - vValueBefore) / vQtyBefore;
                            end if;

                            vMvtUnitPrice  := vMvtPrice;
                            -- mise à jour du PRCS, mais en calculant le prix du mouvement selon SMO_TARGET_PRICE
                            STM_COSTPRICE.GCO_Update_Costprice(aGoodId           => tplMovement.GCO_GOOD_ID
                                                             , aStockId          => tplMovement.STM_STOCK_ID
                                                             , aMovementKindId   => tplMovement.STM_MOVEMENT_KIND_ID
                                                             , aMoveQty          => tplMovement.SMO_MOVEMENT_QUANTITY
                                                             , aMoveValue        => vMvtPrice
                                                             , aPriceUpdated     => vBidon1
                                                             , aOldQtyPrcs       => vQtyBefore
                                                             , aOldValuePrcs     => vValueBefore
                                                             , aOldPrcs          => vPrcsBefore
                                                             , aNewQtyPrcs       => vQtyAfter
                                                             , aNewValuePrcs     => vValueAfter
                                                             , aNewPrcs          => vPrcsAfter
                                                             , aPrcsValue        => vPrcsValue
                                                             , aVirtual          => (vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') )
                                                             , aUpdateMvt        => true
                                                             , aUpdatePrcs       => tplMovement.SMO_UPDATE_PRCS
                                                             , aPosDetailId      => tplMovement.DOC_POSITION_DETAIL_ID
                                                              );
                          end;
                        else   -- Cas normal
                          if DOC_I_LIB_GAUGE.IsCreditNote(iDetailId => tplMovement.DOC_POSITION_DETAIL_ID) = 1 then
                            vMvtPrice   := pGetCreditNoteMovementPrice(tplMovement.DOC_POSITION_DETAIL_ID);

                            if tplMovement.SMO_MOVEMENT_QUANTITY = 0 then
                              vMvtUnitPrice  := vMvtPrice;
                            else
                              vMvtUnitPrice  := vMvtPrice / tplMovement.SMO_MOVEMENT_QUANTITY;
                            end if;

                            vPrcsValue  := vMvtPrice;
                          else
                            vMvtUnitPrice  := GCO_FUNCTIONS.getCostPriceWithManagementMode(aGCO_GOOD_ID => aGoodId, aManagementMode => vManagementMode);
                            vMvtPrice      := tplMovement.SMO_MOVEMENT_QUANTITY * vMvtUnitPrice;
                            vPrcsValue     := null;
                          end if;

                          -- mise à jour du PRCS
                          STM_COSTPRICE.GCO_Update_Costprice(aGoodId           => tplMovement.GCO_GOOD_ID
                                                           , aStockId          => tplMovement.STM_STOCK_ID
                                                           , aMovementKindId   => tplMovement.STM_MOVEMENT_KIND_ID
                                                           , aMoveQty          => tplMovement.SMO_MOVEMENT_QUANTITY
                                                           , aMoveValue        => vMvtPrice
                                                           , aPriceUpdated     => vBidon1
                                                           , aOldQtyPrcs       => vQtyBefore
                                                           , aOldValuePrcs     => vValueBefore
                                                           , aOldPrcs          => vPrcsBefore
                                                           , aNewQtyPrcs       => vQtyAfter
                                                           , aNewValuePrcs     => vValueAfter
                                                           , aNewPrcs          => vPrcsAfter
                                                           , aPrcsValue        => vPrcsValue
                                                           , aVirtual          => (vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') )
                                                           , aUpdateMvt        => true
                                                           , aUpdatePrcs       => tplMovement.SMO_UPDATE_PRCS
                                                           , aPosDetailId      => tplMovement.DOC_POSITION_DETAIL_ID
                                                            );
                        end if;
                      end if;

                      -- valeur unitaire PRCS
                      vMvtUnitPrcsValue  := vPrcsAfter;

                      -- Mise à jour des infos relatives au PRCS sur le mouvement (même si le mouvement n'influence pas le PRCS)
                      declare
                        vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
                      begin
                        FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF, false);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplMovement.STM_STOCK_MOVEMENT_ID);

                        -- maj des prix seulement si on est en mode mise à jour du PRCS
                        if tplMovement.SMO_UPDATE_PRCS = 1 then
                          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_UNIT_PRICE', vMvtUnitPrice);
                          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_MOVEMENT_PRICE', vMvtUnitPrice * tplMovement.SMO_MOVEMENT_QUANTITY);
                          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                                        , 'SMO_REFERENCE_UNIT_PRICE'
                                                        , case
                                                            when tplMovement.DOC_POSITION_DETAIL_ID is null then vMvtUnitPrice
                                                            else tplMovement.SMO_REFERENCE_UNIT_PRICE
                                                          end
                                                         );
                          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_VALUE', vPrcsValue);
                        end if;

                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_BEFORE', vQtyBefore);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_AFTER', vQtyAfter);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_BEFORE', vValueBefore);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_AFTER', vValueAfter);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_BEFORE', vPrcsBefore);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_AFTER', vPrcsAfter);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                                      , 'SMO_PRCS_UPDATED'
                                                      , case
                                                          when vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') then 1
                                                          else tplMovement.SMO_PRCS_UPDATED
                                                        end
                                                       );
                        FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
                        FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
                      end;

                      -- Mise à jour du prix du mouvement sur le détail de position
                      update    DOC_POSITION_DETAIL
                            set PDE_MOVEMENT_VALUE = vMvtUnitPrice * tplMovement.SMO_MOVEMENT_QUANTITY
                          where DOC_POSITION_DETAIL_ID = tplMovement.DOC_POSITION_DETAIL_ID
                      returning FAL_SCHEDULE_STEP_ID
                           into vScheduleStepId;

                      if tplMovement.C_MANAGEMENT_MODE = '1' then
                        -- Mise à jour du prix de revient unitaire
                        if nvl(tplMovement.GAR_INIT_COST_PRICE, 0) = 0 then
                          update DOC_POSITION
                             set POS_UNIT_COST_PRICE = GCO_FUNCTIONS.GetCostPriceWithManagementMode(aGoodId)
                           where DOC_POSITION_ID = tplMovement.DOC_POSITION_ID
                             and tplMovement.C_MANAGEMENT_MODE = '1';
                        else   -- maj selon prix de revient père
                          update DOC_POSITION
                             set POS_UNIT_COST_PRICE =
                                       (select POS_UNIT_COST_PRICE
                                          from DOC_POSITION_DETAIL PDE
                                             , DOC_POSITION POS
                                         where PDE.DOC_POSITION_DETAIL_ID = tplMovement.DOC_DOC_POSITION_DETAIL_ID
                                           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID)
                           where DOC_POSITION_ID = tplMovement.DOC_POSITION_ID
                             and tplMovement.C_MANAGEMENT_MODE = '1';
                        end if;
                      end if;

                      -- mise à jour des éventuelles opérations de sous-traitance
                      update FAL_TASK_LINK
                         set TAL_RELEASE_QTY = tplMovement.SMO_MOVEMENT_QUANTITY
                           , TAL_CST_UNIT_PRICE_B = vMvtUnitPrice
                       where FAL_SCHEDULE_STEP_ID = vScheduleStepId;
                    else   -- mouvements d'entrée en stock ou sortie de note de débit
                      -- mise à jour du PRCS
                      if tplMovement.SMO_UPDATE_PRCS = 1 then
                        if     tplMovement.C_MOVEMENT_CODE = '014'
                           and tplMovement.SMO_TARGET_PRICE is not null then
                          begin
                            if tplMovement.C_MOVEMENT_SORT = 'ENT' then
                              vMvtPrice  := tplMovement.SMO_TARGET_PRICE * vQtyBefore - vValueBefore;
                            else
                              vMvtPrice  := -(tplMovement.SMO_TARGET_PRICE * vQtyBefore - vValueBefore);
                            end if;

                            -- mise à jour du PRCS, mais en calculant le prix du mouvement selon SMO_TARGET_PRICE
                            STM_COSTPRICE.GCO_Update_Costprice(aGoodId           => tplMovement.GCO_GOOD_ID
                                                             , aStockId          => tplMovement.STM_STOCK_ID
                                                             , aMovementKindId   => tplMovement.STM_MOVEMENT_KIND_ID
                                                             , aMoveQty          => tplMovement.SMO_MOVEMENT_QUANTITY
                                                             , aMoveValue        => vMvtPrice
                                                             , aPriceUpdated     => vBidon1
                                                             , aOldQtyPrcs       => vQtyBefore
                                                             , aOldValuePrcs     => vValueBefore
                                                             , aOldPrcs          => vPrcsBefore
                                                             , aNewQtyPrcs       => vQtyAfter
                                                             , aNewValuePrcs     => vValueAfter
                                                             , aNewPrcs          => vPrcsAfter
                                                             , aPrcsValue        => vPrcsValue
                                                             , aVirtual          => (vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') )
                                                             , aUpdateMvt        => true
                                                             , aUpdatePrcs       => tplMovement.SMO_UPDATE_PRCS
                                                             , aPosDetailId      => tplMovement.DOC_POSITION_DETAIL_ID
                                                              );
                          end;
                        else   -- cas normal
                          STM_COSTPRICE.GCO_Update_Costprice(aGoodId           => tplMovement.GCO_GOOD_ID
                                                           , aStockId          => tplMovement.STM_STOCK_ID
                                                           , aMovementKindId   => tplMovement.STM_MOVEMENT_KIND_ID
                                                           , aMoveQty          => tplMovement.SMO_MOVEMENT_QUANTITY
                                                           , aMoveValue        => tplMovement.SMO_MOVEMENT_PRICE
                                                           , aPriceUpdated     => vBidon1
                                                           , aOldQtyPrcs       => vQtyBefore
                                                           , aOldValuePrcs     => vValueBefore
                                                           , aOldPrcs          => vPrcsBefore
                                                           , aNewQtyPrcs       => vQtyAfter
                                                           , aNewValuePrcs     => vValueAfter
                                                           , aNewPrcs          => vPrcsAfter
                                                           , aPrcsValue        => vPrcsValue
                                                           , aVirtual          => (vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') )
                                                           , aUpdateMvt        => true
                                                           , aUpdatePrcs       => tplMovement.SMO_UPDATE_PRCS
                                                           , aPosDetailId      => tplMovement.DOC_POSITION_DETAIL_ID
                                                            );
                        end if;
                      end if;

                      -- valeur unitaire PRCS pour mouvement
                      vMvtUnitPrcsValue  := vPrcsAfter;

                      -- Mise à jour des montants sur le mouvement (même s'il n'influence pas le PRCS)
                      declare
                        vCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
                      begin
                        FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplMovement.STM_STOCK_MOVEMENT_ID);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_BEFORE', vQtyBefore);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_QUANTITY_AFTER', vQtyAfter);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_BEFORE', vValueBefore);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_ADDED_VALUE_AFTER', vValueAfter);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_BEFORE', vPrcsBefore);
                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_AFTER', vPrcsAfter);

                        -- maj des prix seulement si on est en mode mise à jour du PRCS
                        if tplMovement.SMO_UPDATE_PRCS = 1 then
                          -- en cas de mouvements de report d'exercice et si le bien est géré au PRCS , nise à jour du prix du mouvement
                          -- ceci pour garantir l'intégrité des évolutions de stock
                          if     tplMovement.C_MOVEMENT_CODE = '004'
                             and vManagementMode = '1' then
                            FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_MOVEMENT_PRICE', tplMovement.SMO_MOVEMENT_QUANTITY * vPrcsAfter);
                            FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_VALUE', tplMovement.SMO_MOVEMENT_QUANTITY * vPrcsAfter);
                          elsif     tplMovement.C_MOVEMENT_CODE = '014'
                                and tplMovement.SMO_TARGET_PRICE is not null then
                            FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_MOVEMENT_PRICE', vMvtPrice);
                            FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_VALUE', vMvtPrice);
                          else
                            FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_PRCS_VALUE', tplMovement.SMO_MOVEMENT_PRICE);
                          end if;

                          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                                        , 'SMO_REFERENCE_UNIT_PRICE'
                                                        , case
                                                            when tplMovement.DOC_POSITION_DETAIL_ID is null then vPrcsAfter
                                                            else tplMovement.SMO_REFERENCE_UNIT_PRICE
                                                          end
                                                         );
                        end if;

                        FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF
                                                      , 'SMO_PRCS_UPDATED'
                                                      , case
                                                          when vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') then 1
                                                          else tplMovement.SMO_PRCS_UPDATED
                                                        end
                                                       );
                        FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
                        FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
                      end;
                    end if;
                  end if;
                end if;
              elsif     vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3')
                    and tplMovement.SMO_VALUE_DATE > nvl(vTplRecalcJob.PRR_REFERENCE_DATE, sysdate) then
                -- Mode recalcul selon date, création de PRF
                insert into PTC_FIXED_COSTPRICE
                            (PTC_FIXED_COSTPRICE_ID
                           , C_COSTPRICE_STATUS
                           , GCO_GOOD_ID
                           , PAC_THIRD_ID
                           , CPR_DESCR
                           , CPR_PRICE
                           , CPR_DEFAULT
                           , FCP_START_DATE
                           , DIC_FIXED_COSTPRICE_DESCR_ID
                           , PTC_RECALC_JOB_ID
                           , CPR_PRICE_BEFORE_RECALC
                           , A_DATECRE
                           , A_IDCRE
                            )
                     values (init_id_seq.nextval
                           , 'ACT'
                           , aGoodId
                           , null
                           , PCS.PC_FUNCTIONS.TranslateWord('Recalcul PRCS') || ' / ' || to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS')
                           , vPrcsBefore
                           , 0
                           , vTplRecalcJob.PRR_REFERENCE_DATE
                           , vTplRecalcJob.DIC_FIXED_COSTPRICE_DESCR_ID
                           , vTplRecalcJob.PTC_RECALC_JOB_ID
                           , vPrcsBeforeRecalc
                           , sysdate
                           , PCS.PC_I_LIB_SESSION.GetUserIni
                            );

                -- Flag indiquant que le prix a été mis à jour à 0
                pResetPrcsUpdated(tplMovement.STM_STOCK_MOVEMENT_ID);
                vBlnClearMode  := true;   -- En mode recalcul selon date, si on dépasse la date butoir, on sort de la boucle
              end if;

              vValueBefore       := vValueAfter;
              vQtyBefore         := vQtyAfter;
              vPrcsBefore        := vPrcsAfter;
            end if;

            vLastValueDate  := tplMovement.SMO_VALUE_DATE;
          end;

          vFirstMove  := false;
        end loop;

        if     (   not vBlnRecalcMode
                or vLastValueDate <= nvl(vTplRecalcJob.PRR_REFERENCE_DATE, sysdate) )
           and vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '3') then
          -- Mode recalcul selon date, création de PRF
          insert into PTC_FIXED_COSTPRICE
                      (PTC_FIXED_COSTPRICE_ID
                     , C_COSTPRICE_STATUS
                     , GCO_GOOD_ID
                     , PAC_THIRD_ID
                     , CPR_DESCR
                     , CPR_PRICE
                     , CPR_DEFAULT
                     , FCP_START_DATE
                     , DIC_FIXED_COSTPRICE_DESCR_ID
                     , PTC_RECALC_JOB_ID
                     , CPR_PRICE_BEFORE_RECALC
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , 'ACT'
                     , aGoodId
                     , null
                     , PCS.PC_FUNCTIONS.TranslateWord('Recalcul PRCS') || ' / ' || to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS')
                     , vPrcsBefore
                     , 0
                     , vTplRecalcJob.PRR_REFERENCE_DATE
                     , vTplRecalcJob.DIC_FIXED_COSTPRICE_DESCR_ID
                     , vTplRecalcJob.PTC_RECALC_JOB_ID
                     , vPrcsBeforeRecalc
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;

        if vTplRecalcJob.C_PRCS_RECALC_MODE = '1' then
          -- lancement en mode recalcul PRCS
          majGoodPrcs2(aGoodId, aRecalcJobId, '2', 0);
        end if;

        if     vTplRecalcJob.C_PRCS_RECALC_MODE in('1', '2')
           and PCS.PC_CONFIG.GetBooleanConfig('PTC_DETAIL_RECALC_JOB') then
          lPrcsAfterRecalc  := GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(aGoodId);
          pLogInfo(iRecalcJobId => aRecalcJobId, iGoodId => aGoodId, iPRCSBefore => lPrcsBeforeRecalc, iPRCSAfter => lPrcsAfterRecalc);
        end if;
      end;
    else
      -- si pas de mouvements, pas de PRCS
      update GCO_GOOD_CALC_DATA
         set GOO_ADDED_QTY_COST_PRICE = 0
           , GOO_ADDED_VALUE_COST_PRICE = 0
           , GOO_BASE_COST_PRICE = 0
       where GCO_GOOD_ID = aGoodId;

      pLogInfo(iRecalcJobId => aRecalcJobId, iGoodId => aGoodId, iPRCSBefore => GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(aGoodId), iPRCSAfter => null);
    end if;
  exception
    when others then
      pLogInfo(iRecalcJobId => aRecalcJobId, iGoodId => aGoodId, iError => sqlerrm || chr(13) || DBMS_UTILITY.Format_Error_Backtrace);
  end majGoodPrcs2;

  /**
  * procedure removeDoubleElementsNumber
  * Description
  *   Suppression des numéros de série à double dans la table STM_ELEMENT_NUMBER
  * @created fp 10.11.2004
  * @lastUpdate
  * @public
  */
  procedure removeDoubleElementsNumber
  is
    cursor crDoubleUse
    is
      select   SEM.STM_ELEMENT_NUMBER_ID
             , SEM.GCO_GOOD_ID
             , SEM.C_ELEMENT_TYPE
             , SEM.SEM_VALUE
          from STM_ELEMENT_NUMBER SEM
             , (select   GCO_GOOD_ID
                       , C_ELEMENT_TYPE
                       , SEM_VALUE
                    from STM_ELEMENT_NUMBER
                group by GCO_GOOD_ID
                       , C_ELEMENT_TYPE
                       , SEM_VALUE
                  having count(GCO_GOOD_ID) > 1) DBL
         where SEM.GCO_GOOD_ID = DBL.GCO_GOOD_ID
           and SEM.C_ELEMENT_TYPE = DBL.C_ELEMENT_TYPE
           and SEM.SEM_VALUE = DBL.SEM_VALUE
      order by SEM.GCO_GOOD_ID
             , SEM.C_ELEMENT_TYPE
             , SEM.SEM_VALUE
             , nvl(SEM.A_DATEMOD, SEM.A_DATECRE) desc;

    tplOldValue crDoubleUse%rowtype;

    type ttblActual is table of crDoubleUse%rowtype;

    tblActual   ttblActual;
    i           integer;
    j           integer               := 0;
  begin
    open crDoubleUse;

    fetch crDoubleUse
    bulk collect into tblActual;

    close crDoubleUse;

    if tblActual.count > 0 then
      for i in tblActual.first .. tblActual.last loop
        if     tplOldValue.GCO_GOOD_ID = tblActual(i).GCO_GOOD_ID
           and tplOldValue.C_ELEMENT_TYPE = tblActual(i).C_ELEMENT_TYPE
           and tplOldValue.SEM_VALUE = tblActual(i).SEM_VALUE then
          STM_PRC_ELEMENT_NUMBER.DeleteDetail(iElementNumberID => tblActual(i).STM_ELEMENT_NUMBER_ID);
          j  := j + 1;
        end if;

        tplOldValue.GCO_GOOD_ID     := tblActual(i).GCO_GOOD_ID;
        tplOldValue.C_ELEMENT_TYPE  := tblActual(i).C_ELEMENT_TYPE;
        tplOldValue.SEM_VALUE       := tblActual(i).SEM_VALUE;
      end loop;
    end if;

    DBMS_OUTPUT.put_line(j || ' row(s) deleted');
  end removeDoubleElementsNumber;

  /**
  * Description
  *    Suppression des position à 0
  */
  procedure PurgeEmptyPositions
  is
    cursor crPositionsToDelete
    is
      select STM_STOCK_POSITION_ID
        from STM_STOCK_POSITION
       where SPO_STOCK_QUANTITY = 0
         and SPO_ASSIGN_QUANTITY = 0
         and SPO_PROVISORY_INPUT = 0
         and SPO_PROVISORY_OUTPUT = 0
         and SPO_AVAILABLE_QUANTITY = 0
         and SPO_THEORETICAL_QUANTITY = 0
         and SPO_ALTERNATIV_QUANTITY_1 = 0
         and SPO_ALTERNATIV_QUANTITY_2 = 0
         and SPO_ALTERNATIV_QUANTITY_3 = 0
         and C_POSITION_STATUS = '01';
  begin
    for tplPositionToDelete in crPositionsToDelete loop
      begin
        delete from STM_STOCK_POSITION
              where STM_STOCK_POSITION_ID = tplPositionToDelete.STM_STOCK_POSITION_ID;
      exception
        when ex.CHILD_RECORD_FOUND then
          null;
      end;
    end loop;
  end PurgeEmptyPositions;

  /**
  * Description
  *    Mise à jour des quantités des positions de stock en fct des mouvements pour un bien donné.
  */
  procedure restoreStockQuantity(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
  is
    -- curseur sur les positions de stock à corriger
    cursor crBadPos(cGoodId number)
    is
      select SPO.STM_STOCK_POSITION_ID
           , SPO.GCO_GOOD_ID
           , SPO.STM_STOCK_ID
           , SPO.STM_LOCATION_ID
           , SPO.SPO_CHARACTERIZATION_VALUE_1
           , SPO.SPO_CHARACTERIZATION_VALUE_2
           , SPO.SPO_CHARACTERIZATION_VALUE_3
           , SPO.SPO_CHARACTERIZATION_VALUE_4
           , SPO.SPO_CHARACTERIZATION_VALUE_5
           , SPO.SPO_STOCK_QUANTITY ACTUAL_QUANTITY
           , STQ.SPO_STOCK_QUANTITY THEORICAL_QUANTITY
        from STM_STOCK_POSITION SPO
           , (select   GCO_GOOD_ID
                     , SMO.STM_STOCK_ID
                     , SMO.STM_LOCATION_ID
                     , GCO_CHARACTERIZATION_VALUE_1 SMO_CHARACTERIZATION_VALUE_1
                     , GCO_CHARACTERIZATION_VALUE_2 SMO_CHARACTERIZATION_VALUE_2
                     , GCO_CHARACTERIZATION_VALUE_3 SMO_CHARACTERIZATION_VALUE_3
                     , GCO_CHARACTERIZATION_VALUE_4 SMO_CHARACTERIZATION_VALUE_4
                     , GCO_CHARACTERIZATION_VALUE_5 SMO_CHARACTERIZATION_VALUE_5
                     , sum(decode(C_MOVEMENT_SORT, 'ENT', SMO_MOVEMENT_QUANTITY, 'SOR', -SMO_MOVEMENT_QUANTITY) ) SPO_STOCK_QUANTITY
                  from STM_STOCK_MOVEMENT SMO
                     , STM_MOVEMENT_KIND MOK
                     , table(GCO_I_LIB_CHARACTERIZATION.GetStockCharacterizations(SMO.GCO_CHARACTERIZATION_ID
                                                                                , SMO.GCO_GCO_CHARACTERIZATION_ID
                                                                                , SMO.GCO2_GCO_CHARACTERIZATION_ID
                                                                                , SMO.GCO3_GCO_CHARACTERIZATION_ID
                                                                                , SMO.GCO4_GCO_CHARACTERIZATION_ID
                                                                                , SMO.SMO_CHARACTERIZATION_VALUE_1
                                                                                , SMO.SMO_CHARACTERIZATION_VALUE_2
                                                                                , SMO.SMO_CHARACTERIZATION_VALUE_3
                                                                                , SMO.SMO_CHARACTERIZATION_VALUE_4
                                                                                , SMO.SMO_CHARACTERIZATION_VALUE_5
                                                                                 )
                            ) CHA
                 where SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
                   and MOK.C_MOVEMENT_TYPE <> 'EXE'
                   and SMO.GCO_GOOD_ID = cGoodId
--                   and STM_EXERCISE_ID = STM_FUNCTIONS.getActiveExercise
              group by GCO_GOOD_ID
                     , SMO.STM_STOCK_ID
                     , SMO.STM_LOCATION_ID
                     , GCO_CHARACTERIZATION_VALUE_1
                     , GCO_CHARACTERIZATION_VALUE_2
                     , GCO_CHARACTERIZATION_VALUE_3
                     , GCO_CHARACTERIZATION_VALUE_4
                     , GCO_CHARACTERIZATION_VALUE_5) STQ
       where SPO.GCO_GOOD_ID = STQ.GCO_GOOD_ID
         and SPO.STM_STOCK_ID = STQ.STM_STOCK_ID
         and SPO.STM_LOCATION_ID = STQ.STM_LOCATION_ID
         and nvl(SPO_CHARACTERIZATION_VALUE_1, 'NULL') = nvl(STQ.SMO_CHARACTERIZATION_VALUE_1, 'NULL')
         and nvl(SPO_CHARACTERIZATION_VALUE_2, 'NULL') = nvl(STQ.SMO_CHARACTERIZATION_VALUE_2, 'NULL')
         and nvl(SPO_CHARACTERIZATION_VALUE_3, 'NULL') = nvl(STQ.SMO_CHARACTERIZATION_VALUE_3, 'NULL')
         and nvl(SPO_CHARACTERIZATION_VALUE_4, 'NULL') = nvl(STQ.SMO_CHARACTERIZATION_VALUE_4, 'NULL')
         and nvl(SPO_CHARACTERIZATION_VALUE_5, 'NULL') = nvl(STQ.SMO_CHARACTERIZATION_VALUE_5, 'NULL')
         and SPO.SPO_STOCK_QUANTITY <> STQ.SPO_STOCK_QUANTITY;

    cursor crMissing(cGoodId number)
    is
      select   SPO.GCO_GOOD_ID
             , SPO.STM_STOCK_ID
             , SPO.STM_LOCATION_ID
             , CHA.GCO_CHARACTERIZATION_ID
             , CHA.GCO_GCO_CHARACTERIZATION_ID
             , CHA.GCO2_GCO_CHARACTERIZATION_ID
             , CHA.GCO3_GCO_CHARACTERIZATION_ID
             , CHA.GCO4_GCO_CHARACTERIZATION_ID
             , CHA.GCO_CHARACTERIZATION_VALUE_1 SMO_CHARACTERIZATION_VALUE_1
             , CHA.GCO_CHARACTERIZATION_VALUE_2 SMO_CHARACTERIZATION_VALUE_2
             , CHA.GCO_CHARACTERIZATION_VALUE_3 SMO_CHARACTERIZATION_VALUE_3
             , CHA.GCO_CHARACTERIZATION_VALUE_4 SMO_CHARACTERIZATION_VALUE_4
             , CHA.GCO_CHARACTERIZATION_VALUE_5 SMO_CHARACTERIZATION_VALUE_5
             , sum(decode(C_MOVEMENT_SORT, 'ENT', SMO_MOVEMENT_QUANTITY, 'SOR', -SMO_MOVEMENT_QUANTITY) ) SPO_STOCK_QUANTITY
          from (select   GCO_GOOD_ID
                       , SMO.STM_STOCK_ID
                       , SMO.STM_LOCATION_ID
                       , CHA.GCO_CHARACTERIZATION_ID
                       , CHA.GCO_GCO_CHARACTERIZATION_ID
                       , CHA.GCO2_GCO_CHARACTERIZATION_ID
                       , CHA.GCO3_GCO_CHARACTERIZATION_ID
                       , CHA.GCO4_GCO_CHARACTERIZATION_ID
                       , GCO_CHARACTERIZATION_VALUE_1 SMO_CHARACTERIZATION_VALUE_1
                       , GCO_CHARACTERIZATION_VALUE_2 SMO_CHARACTERIZATION_VALUE_2
                       , GCO_CHARACTERIZATION_VALUE_3 SMO_CHARACTERIZATION_VALUE_3
                       , GCO_CHARACTERIZATION_VALUE_4 SMO_CHARACTERIZATION_VALUE_4
                       , GCO_CHARACTERIZATION_VALUE_5 SMO_CHARACTERIZATION_VALUE_5
                    from STM_STOCK_MOVEMENT SMO
                       , STM_MOVEMENT_KIND MOK
                       , table(GCO_I_LIB_CHARACTERIZATION.GetStockCharacterizations(SMO.GCO_CHARACTERIZATION_ID
                                                                                  , SMO.GCO_GCO_CHARACTERIZATION_ID
                                                                                  , SMO.GCO2_GCO_CHARACTERIZATION_ID
                                                                                  , SMO.GCO3_GCO_CHARACTERIZATION_ID
                                                                                  , SMO.GCO4_GCO_CHARACTERIZATION_ID
                                                                                  , SMO.SMO_CHARACTERIZATION_VALUE_1
                                                                                  , SMO.SMO_CHARACTERIZATION_VALUE_2
                                                                                  , SMO.SMO_CHARACTERIZATION_VALUE_3
                                                                                  , SMO.SMO_CHARACTERIZATION_VALUE_4
                                                                                  , SMO.SMO_CHARACTERIZATION_VALUE_5
                                                                                   )
                              ) CHA
                   where SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
                     and MOK.C_MOVEMENT_TYPE <> 'EXE'
                     and SMO.GCO_GOOD_ID = cGoodId
                     and STM_EXERCISE_ID = STM_FUNCTIONS.getActiveExercise
                group by GCO_GOOD_ID
                       , SMO.STM_STOCK_ID
                       , SMO.STM_LOCATION_ID
                       , CHA.GCO_CHARACTERIZATION_ID
                       , CHA.GCO_GCO_CHARACTERIZATION_ID
                       , CHA.GCO2_GCO_CHARACTERIZATION_ID
                       , CHA.GCO3_GCO_CHARACTERIZATION_ID
                       , CHA.GCO4_GCO_CHARACTERIZATION_ID
                       , CHA.GCO_CHARACTERIZATION_VALUE_1
                       , CHA.GCO_CHARACTERIZATION_VALUE_2
                       , CHA.GCO_CHARACTERIZATION_VALUE_3
                       , CHA.GCO_CHARACTERIZATION_VALUE_4
                       , CHA.GCO_CHARACTERIZATION_VALUE_5
                  having sum(decode(C_MOVEMENT_SORT, 'ENT', SMO_MOVEMENT_QUANTITY, 'SOR', -SMO_MOVEMENT_QUANTITY) ) <> 0
                minus
                select GCO_GOOD_ID
                     , STM_STOCK_ID
                     , STM_LOCATION_ID
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , SPO_CHARACTERIZATION_VALUE_1 SMO_CHARACTERIZATION_VALUE_1
                     , SPO_CHARACTERIZATION_VALUE_2 SMO_CHARACTERIZATION_VALUE_2
                     , SPO_CHARACTERIZATION_VALUE_3 SMO_CHARACTERIZATION_VALUE_3
                     , SPO_CHARACTERIZATION_VALUE_4 SMO_CHARACTERIZATION_VALUE_4
                     , SPO_CHARACTERIZATION_VALUE_5 SMO_CHARACTERIZATION_VALUE_5
                  from STM_STOCK_POSITION SPO
                 where SPO.GCO_GOOD_ID = cGoodId) SPO
             , STM_MOVEMENT_KIND MOK
             , STM_STOCK_MOVEMENT SMO
             , table(GCO_I_LIB_CHARACTERIZATION.GetStockCharacterizations(SMO.GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO_GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO2_GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO3_GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO4_GCO_CHARACTERIZATION_ID
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_1
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_2
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_3
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_4
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_5
                                                                         )
                    ) CHA
         where SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
           and MOK.C_MOVEMENT_TYPE <> 'EXE'
           and SMO.GCO_GOOD_ID = cGoodId
           and SPO.GCO_GOOD_ID = SMO.GCO_GOOD_ID
           and SPO.STM_LOCATION_ID = SMO.STM_LOCATION_ID
           and SPO.STM_STOCK_ID = SMO.STM_STOCK_ID
           and nvl(SPO.GCO_CHARACTERIZATION_ID, 0) = nvl(CHA.GCO_CHARACTERIZATION_ID, 0)
           and nvl(SPO.SMO_CHARACTERIZATION_VALUE_1, 'NULL') = nvl(CHA.GCO_CHARACTERIZATION_VALUE_1, 'NULL')
           and nvl(SPO.GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(CHA.GCO_GCO_CHARACTERIZATION_ID, 0)
           and nvl(SPO.SMO_CHARACTERIZATION_VALUE_2, 'NULL') = nvl(CHA.GCO_CHARACTERIZATION_VALUE_2, 'NULL')
           and nvl(SPO.GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(CHA.GCO2_GCO_CHARACTERIZATION_ID, 0)
           and nvl(SPO.SMO_CHARACTERIZATION_VALUE_3, 'NULL') = nvl(CHA.GCO_CHARACTERIZATION_VALUE_3, 'NULL')
           and nvl(SPO.GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(CHA.GCO3_GCO_CHARACTERIZATION_ID, 0)
           and nvl(SPO.SMO_CHARACTERIZATION_VALUE_4, 'NULL') = nvl(CHA.GCO_CHARACTERIZATION_VALUE_4, 'NULL')
           and nvl(SPO.GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(CHA.GCO4_GCO_CHARACTERIZATION_ID, 0)
           and nvl(SPO.SMO_CHARACTERIZATION_VALUE_5, 'NULL') = nvl(CHA.GCO_CHARACTERIZATION_VALUE_5, 'NULL')
      group by SPO.GCO_GOOD_ID
             , SPO.STM_STOCK_ID
             , SPO.STM_LOCATION_ID
             , CHA.GCO_CHARACTERIZATION_ID
             , CHA.GCO_GCO_CHARACTERIZATION_ID
             , CHA.GCO2_GCO_CHARACTERIZATION_ID
             , CHA.GCO3_GCO_CHARACTERIZATION_ID
             , CHA.GCO4_GCO_CHARACTERIZATION_ID
             , CHA.GCO_CHARACTERIZATION_VALUE_1
             , CHA.GCO_CHARACTERIZATION_VALUE_2
             , CHA.GCO_CHARACTERIZATION_VALUE_3
             , CHA.GCO_CHARACTERIZATION_VALUE_4
             , CHA.GCO_CHARACTERIZATION_VALUE_5
        having sum(decode(C_MOVEMENT_SORT, 'ENT', SMO_MOVEMENT_QUANTITY, 'SOR', -SMO_MOVEMENT_QUANTITY) ) <> 0;

    cursor crTooMuch(cGoodId number)
    is
      select GCO_GOOD_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , SPO_CHARACTERIZATION_VALUE_1 SMO_CHARACTERIZATION_VALUE_1
           , SPO_CHARACTERIZATION_VALUE_2 SMO_CHARACTERIZATION_VALUE_2
           , SPO_CHARACTERIZATION_VALUE_3 SMO_CHARACTERIZATION_VALUE_3
           , SPO_CHARACTERIZATION_VALUE_4 SMO_CHARACTERIZATION_VALUE_4
           , SPO_CHARACTERIZATION_VALUE_5 SMO_CHARACTERIZATION_VALUE_5
        from STM_STOCK_POSITION SPO
       where SPO.GCO_GOOD_ID = cGoodId
      minus
      select   GCO_GOOD_ID
             , SMO.STM_STOCK_ID
             , SMO.STM_LOCATION_ID
             , CHA.GCO_CHARACTERIZATION_VALUE_1 SMO_CHARACTERIZATION_VALUE_1
             , CHA.GCO_CHARACTERIZATION_VALUE_2 SMO_CHARACTERIZATION_VALUE_2
             , CHA.GCO_CHARACTERIZATION_VALUE_3 SMO_CHARACTERIZATION_VALUE_3
             , CHA.GCO_CHARACTERIZATION_VALUE_4 SMO_CHARACTERIZATION_VALUE_4
             , CHA.GCO_CHARACTERIZATION_VALUE_5 SMO_CHARACTERIZATION_VALUE_5
          from STM_STOCK_MOVEMENT SMO
             , STM_MOVEMENT_KIND MOK
             , table(GCO_I_LIB_CHARACTERIZATION.GetStockCharacterizations(SMO.GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO_GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO2_GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO3_GCO_CHARACTERIZATION_ID
                                                                        , SMO.GCO4_GCO_CHARACTERIZATION_ID
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_1
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_2
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_3
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_4
                                                                        , SMO.SMO_CHARACTERIZATION_VALUE_5
                                                                         )
                    ) CHA
         where SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
           and MOK.C_MOVEMENT_TYPE <> 'EXE'
           and SMO.GCO_GOOD_ID = cGoodId
           and STM_EXERCISE_ID = STM_FUNCTIONS.getActiveExercise
      group by GCO_GOOD_ID
             , SMO.STM_STOCK_ID
             , SMO.STM_LOCATION_ID
             , CHA.GCO_CHARACTERIZATION_VALUE_1
             , CHA.GCO_CHARACTERIZATION_VALUE_2
             , CHA.GCO_CHARACTERIZATION_VALUE_3
             , CHA.GCO_CHARACTERIZATION_VALUE_4
             , CHA.GCO_CHARACTERIZATION_VALUE_5
        having sum(decode(C_MOVEMENT_SORT, 'ENT', SMO_MOVEMENT_QUANTITY, 'SOR', -SMO_MOVEMENT_QUANTITY) ) <> 0;

    mvt_quantity     STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    vElementNumber1  STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    vElementNumber2  STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    vElementNumber3  STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lQualityStatusId STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
  begin
    -- Suppression des positions à 0
    PurgeEmptyPositions;

    -- pour chaque position à supprimer
    for tplTooMuch in crTooMuch(aGoodId) loop
      declare
        vPosId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
      begin
        select STM_STOCK_POSITION_ID
          into vPosId
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = tplTooMuch.GCO_GOOD_ID
           and STM_STOCK_ID = tplTooMuch.STM_STOCK_ID
           and STM_LOCATION_ID = tplTooMuch.STM_LOCATION_ID
           and SPO_CHARACTERIZATION_VALUE_1 = tplTooMuch.SMO_CHARACTERIZATION_VALUE_1
           and SPO_CHARACTERIZATION_VALUE_2 = tplTooMuch.SMO_CHARACTERIZATION_VALUE_2
           and SPO_CHARACTERIZATION_VALUE_3 = tplTooMuch.SMO_CHARACTERIZATION_VALUE_3
           and SPO_CHARACTERIZATION_VALUE_4 = tplTooMuch.SMO_CHARACTERIZATION_VALUE_4
           and SPO_CHARACTERIZATION_VALUE_5 = tplTooMuch.SMO_CHARACTERIZATION_VALUE_5;

        update STM_STOCK_POSITION
           set SPO_STOCK_QUANTITY = 0
         where STM_STOCK_POSITION_ID = vPosId;

        -- Si besoin est, effacement de la position de stock si celle-ci se retrouve à 0
        STM_PRC_STOCK_POSITION.DeleteNullPosition(vPosId);
      exception
        when no_data_found then
          null;
      end;
    end loop;

    -- pour chaque position à ajouter
    for tplMissing in crMissing(aGoodId) loop
      -- mise à jour de la table element_number et récupération des ID
      STM_I_PRC_STOCK_POSITION.GetElementNumber(iGoodId                   => tplMissing.GCO_GOOD_ID
                                              , iUpdateMode               => 'I'
                                              , iMovementSort             => 'ENT'
                                              , iCharacterizationId       => tplMissing.GCO_CHARACTERIZATION_ID
                                              , iCharacterization2Id      => tplMissing.GCO_GCO_CHARACTERIZATION_ID
                                              , iCharacterization3Id      => tplMissing.GCO2_GCO_CHARACTERIZATION_ID
                                              , iCharacterization4Id      => tplMissing.GCO3_GCO_CHARACTERIZATION_ID
                                              , iCharacterization5Id      => tplMissing.GCO4_GCO_CHARACTERIZATION_ID
                                              , iCharacterizationValue1   => tplMissing.SMO_CHARACTERIZATION_VALUE_1
                                              , iCharacterizationValue2   => tplMissing.SMO_CHARACTERIZATION_VALUE_2
                                              , iCharacterizationValue3   => tplMissing.SMO_CHARACTERIZATION_VALUE_3
                                              , iCharacterizationValue4   => tplMissing.SMO_CHARACTERIZATION_VALUE_4
                                              , iCharacterizationValue5   => tplMissing.SMO_CHARACTERIZATION_VALUE_5
                                              , iVerifyChar               => 0   --Verify_Char
                                              , iElementStatus            => null   -- element_status
                                              , ioElementNumberId1        => vElementNumber1
                                              , ioElementNumberId2        => vElementNumber2
                                              , ioElementNumberId3        => vElementNumber3
                                              , ioQualityStatusId         => lQualityStatusId
                                               );

      -- mise à jour de la position de stock
      insert into STM_STOCK_POSITION
                  (STM_STOCK_POSITION_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , STM_LAST_STOCK_MOVE_ID
                 , C_POSITION_STATUS
                 , GCO_GOOD_ID
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , SPO_CHARACTERIZATION_VALUE_1
                 , SPO_CHARACTERIZATION_VALUE_2
                 , SPO_CHARACTERIZATION_VALUE_3
                 , SPO_CHARACTERIZATION_VALUE_4
                 , SPO_CHARACTERIZATION_VALUE_5
                 , STM_ELEMENT_NUMBER_ID
                 , STM_STM_ELEMENT_NUMBER_ID
                 , STM2_STM_ELEMENT_NUMBER_ID
                 , SPO_STOCK_QUANTITY
                 , SPO_ASSIGN_QUANTITY
                 , SPO_AVAILABLE_QUANTITY
                 , SPO_PROVISORY_OUTPUT
                 , SPO_PROVISORY_INPUT
                 , SPO_THEORETICAL_QUANTITY
                 , SPO_ALTERNATIV_QUANTITY_1
                 , SPO_ALTERNATIV_QUANTITY_2
                 , SPO_ALTERNATIV_QUANTITY_3
                 , SPO_LAST_INVENTORY_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , tplMissing.STM_STOCK_ID
                 , tplMissing.STM_LOCATION_ID
                 , null   --STM_LAST_STOCK_MOVE_ID
                 , '01'   --C_POSITION_STATUS
                 , tplMissing.GCO_GOOD_ID
                 , tplMissing.GCO_CHARACTERIZATION_ID
                 , tplMissing.GCO_GCO_CHARACTERIZATION_ID
                 , tplMissing.GCO2_GCO_CHARACTERIZATION_ID
                 , tplMissing.GCO3_GCO_CHARACTERIZATION_ID
                 , tplMissing.GCO4_GCO_CHARACTERIZATION_ID
                 , tplMissing.SMO_CHARACTERIZATION_VALUE_1
                 , tplMissing.SMO_CHARACTERIZATION_VALUE_2
                 , tplMissing.SMO_CHARACTERIZATION_VALUE_3
                 , tplMissing.SMO_CHARACTERIZATION_VALUE_4
                 , tplMissing.SMO_CHARACTERIZATION_VALUE_5
                 , vElementNumber1
                 , vElementNumber2
                 , vElementNumber3
                 , tplMissing.SPO_STOCK_QUANTITY   --SPO_STOCK_QUANTITY
                 , 0   --SPO_ASSIGN_QUANTITY
                 , tplMissing.SPO_STOCK_QUANTITY   --SPO_AVAILABLE_QUANTITY
                 , 0   --SPO_PROVISORY_OUTPUT
                 , 0   --SPO_PROVISORY_INPUT
                 , tplMissing.SPO_STOCK_QUANTITY   --SPO_THEORETICAL_QUANTITY
                 , 0   --SPO_ALTERNATIV_QUANTITY_1
                 , 0   --SPO_ALTERNATIV_QUANTITY_2
                 , 0   --SPO_ALTERNATIV_QUANTITY_3
                 , null
                 , sysdate   --SPO_LAST_INVENTORY_DATE
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;

    -- pour chaque position à corriger
    for tplBadPos in crBadPos(aGoodId) loop
      -- calcul la quantité à corriger
      mvt_quantity  := tplBadPos.THEORICAL_QUANTITY - tplBadPos.ACTUAL_QUANTITY;

      -- mise à jour de la position de stock
      update STM_STOCK_POSITION
         set SPO_STOCK_QUANTITY =(SPO_STOCK_QUANTITY + mvt_quantity)
           , SPO_AVAILABLE_QUANTITY =(SPO_STOCK_QUANTITY + mvt_quantity - SPO_ASSIGN_QUANTITY)
           , SPO_THEORETICAL_QUANTITY =(SPO_STOCK_QUANTITY + mvt_quantity - SPO_ASSIGN_QUANTITY + SPO_PROVISORY_INPUT - SPO_PROVISORY_OUTPUT)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where STM_STOCK_POSITION_ID = tplBadPos.STM_STOCK_POSITION_ID;

      -- Si besoin est, effacement de la position de stock si celle-ci se retrouve à 0
      STM_PRC_STOCK_POSITION.DeleteNullPosition(tplBadPos.STM_STOCK_POSITION_ID);
    end loop;
  end restoreStockQuantity;

  /**
  * Description
  *   Méthode permettant de corriger des incohérences liées aux caractérisations
  *   dans les positions de stock
  *   1) ajout de l'id de caracterisation pour les réservation (positions provisoires dont la valeur de caracterisation n'est pas encore connue)
  */
  procedure StockPosCharParity
  is
  begin
    -- liste des positions dont les biens ont au moins une caracterisation  pour
    -- lesquelles les champs id de caractérisation ne sont pas renseignés
    for ltplBadPos1 in (select STM_STOCK_POSITION_ID
                             , GCO_GOOD_ID
                          from STM_STOCK_POSITION
                         where GCO_GOOD_ID in(select distinct GCO_GOOD_ID
                                                         from GCO_CHARACTERIZATION
                                                        where CHA_STOCK_MANAGEMENT = 1)
                           and GCO_CHARACTERIZATION_ID is null) loop
      declare
        lCharId1 GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
        lCharId2 GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
        lCharId3 GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
        lCharId4 GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
        lCharId5 GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      begin
        -- recherche de la liste des caractérisations gérées en stock
        GCO_I_LIB_CHARACTERIZATION.GetListOfStkChar(iGoodId      => ltplBadPos1.GCO_GOOD_ID
                                                  , oCharac1Id   => lCharId1
                                                  , oCharac2Id   => lCharId2
                                                  , oCharac3Id   => lCharId3
                                                  , oCharac4Id   => lCharId4
                                                  , oCharac5Id   => lCharId5
                                                   );

        -- mise à jour des id de caractérisation
        update STM_STOCK_POSITION
           set GCO_CHARACTERIZATION_ID = lCharId1
             , GCO_GCO_CHARACTERIZATION_ID = lCharId2
             , GCO2_GCO_CHARACTERIZATION_ID = lCharId3
             , GCO3_GCO_CHARACTERIZATION_ID = lCharId4
             , GCO4_GCO_CHARACTERIZATION_ID = lCharId5
         where STM_STOCK_POSITION_ID = ltplBadPos1.STM_STOCK_POSITION_ID;
      end;
    end loop;
  end StockPosCharParity;
end STM_PARITY;
