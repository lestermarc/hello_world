--------------------------------------------------------
--  DDL for Package Body FAL_OUT_COMPONENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_OUT_COMPONENT" 
is
  /**
  * procedure CreateNewComponent
  * Description
  *    Création dynamique d'un composant inexistant dans la nomenclature du lot
  * @author CLE
  */
  function CreateNewComponent(aFAL_LOT_ID number, aGCO_GOOD_ID number, aSTM_STOCK_ID number, aSTM_LOCATION_ID number, aFOC_QUANTITY number)
    return number
  is
    pragma autonomous_transaction;
    nFalLotMaterialLinkId number;
  begin
    nFalLotMaterialLinkId  := FAL_COMPONENT_FUNCTIONS.CreateNewComponent(aFAL_LOT_ID, aGCO_GOOD_ID, aSTM_STOCK_ID, aSTM_LOCATION_ID, aFOC_QUANTITY);
    commit;
    return nFalLotMaterialLinkId;
  end;

  /**
  * procedure ExecuteExternalProc
  * Description
  *    Appel d'une procédure d'individualisée. Appelé à la fin du traitement d'une ligne code barre
  *    (d'un enregistrement de la table FAL_OUT_COMPO_BARCODE)
  * @param     iFalOutCompoBarcodeId       l'Id de la table FAL_OUT_COMPO_BARCODE
  * @param     aFalLotMaterialLinkId       l'Id du composant de lot qui vient d'être traité
  * @author CLE
  */
  procedure ExecuteExternalProc(iFalOutCompoBarcodeId in number, aFalLotMaterialLinkId number)
  is
    vSqlCmd         varchar2(32000);
    nFalFactoryInId number;
  begin
    -- Recherche de la dernière entrée atelier du composant en cours
    select max(FAL_FACTORY_IN_ID)
      into nFalFactoryInId
      from FAL_FACTORY_IN
     where FAL_LOT_MATERIAL_LINK_ID = aFalLotMaterialLinkId;

    vSqlCmd  :=
            PCS.PC_FUNCTIONS.GetSql(aTableName   => 'FAL_OUT_COMPO_BARCODE', aGroup => 'customer_specific_proc', aSqlId => 'specific_procedure'
                                  , aHeader      => false);
    vSqlCmd  := FAL_TOOLS.RemoveCompanyOwner(vSqlCmd);

    if PCS.PC_LIB_SQL.IsSqlEmpty(vSqlCmd) = 0 then
      execute immediate vSqlCmd
                  using in iFalOutCompoBarcodeId, in nFalFactoryInId;
    end if;
  end;

  /**
  * Procedure ProcessOutComponent
  * Description : Procèdure de sortie de composants code barre
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     aFAL_OUT_COMPO_BARCODE_ID       ID sortie composant code barre.
  * @param     aGCO_CHARACTERIZATION_ID        ID Caract. 1
  * @param     aGCO_GCO_CHARACTERIZATION_ID    ID Caract. 2
  * @param     aGCO2_GCO_CHARACTERIZATION_ID   ID Caract. 3
  * @param     aGCO3_GCO_CHARACTERIZATION_ID   ID Caract. 4
  * @param     aGCO4_GCO_CHARACTERIZATION_ID   ID Caract. 5
  * @param     aSTM_LOCATION_ID                Emplacement de stock
  * @param     aGCO_GOOD_ID                    Produit
  * @param     aSTM_STOCK_ID                   Stock
  * @param     aFAL_LOT_ID                     lot de fabrication
  * @param     aFAL_LOT_MATERIAL_LINK_ID       Composant du lot
  * @param     aFOC_QUANTITY                   Qté de composant
  * @param     aFOC_DATE                       Date sortie
  * @param     aFOC_PRICE                      Prix composant
  * @param     aFOC_CHARACTERIZATION_VALUE_1   Valeur caract. 1
  * @param     aFOC_CHARACTERIZATION_VALUE_2   Valeur caract. 2
  * @param     aFOC_CHARACTERIZATION_VALUE_3   Valeur caract. 3
  * @param     aFOC_CHARACTERIZATION_VALUE_4   Valeur caract. 4
  * @param     aFOC_CHARACTERIZATION_VALUE_5   Valeur caract. 5
  * @param     aFOC_LOM_SEQ                    Séquence composant.
  * @param     aFOC_LOT_REFCOMPL               Référence complète lot de fabrication.
  * @param     aFOC_GOO_MAJOR_REFERENCE        Référence principale produit
  * @param     aDIC_OPERATOR_ID                Opérateur
  */
  procedure ProcessOutComponent(
    aFAL_OUT_COMPO_BARCODE_ID     number
  , aGCO_CHARACTERIZATION_ID      number
  , aGCO_GCO_CHARACTERIZATION_ID  number
  , aGCO2_GCO_CHARACTERIZATION_ID number
  , aGCO3_GCO_CHARACTERIZATION_ID number
  , aGCO4_GCO_CHARACTERIZATION_ID number
  , aSTM_LOCATION_ID              number
  , aGCO_GOOD_ID                  number
  , aSTM_STOCK_ID                 number
  , aFAL_LOT_ID                   number
  , aFAL_LOT_MATERIAL_LINK_ID     number
  , aFOC_QUANTITY                 number
  , aFOC_DATE                     date
  , aFOC_PRICE                    number
  , aFOC_CHARACTERIZATION_VALUE_1 varchar2
  , aFOC_CHARACTERIZATION_VALUE_2 varchar2
  , aFOC_CHARACTERIZATION_VALUE_3 varchar2
  , aFOC_CHARACTERIZATION_VALUE_4 varchar2
  , aFOC_CHARACTERIZATION_VALUE_5 varchar2
  , aFOC_LOM_SEQ                  number
  , aFOC_LOT_REFCOMPL             varchar2
  , aFOC_GOO_MAJOR_REFERENCE      varchar2
  , aDIC_OPERATOR_ID              varchar2
  )
  is
    lvOutCompoError               varchar2(10);
    liFocAccept                   integer;
    aSTM_STOCK_POSITION_ID        number;
    aMATERIAL_LINK_ID             number;
    aTEMP_MATERIAL_LINK_ID        number;
    aLOM_PRICE                    number;
    aPreparedStockMovements       FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements;
    aCreatedFAL_COMPONENT_LINK_ID number;
    aCHARACT_ID1                  number;
    aCHARACT_ID2                  number;
    aCHARACT_ID3                  number;
    aCHARACT_ID4                  number;
    aCHARACT_ID5                  number;
    aCHARACT_VALUE1               varchar2(30);
    aCHARACT_VALUE2               varchar2(30);
    aCHARACT_VALUE3               varchar2(30);
    aCHARACT_VALUE4               varchar2(30);
    aCHARACT_VALUE5               varchar2(30);
    aSPO_PIECE                    varchar2(30);
    aSPO_VERSION                  varchar2(30);
    aSPO_SET                      varchar2(30);
    aSPO_CHRONOLOGICAL            varchar2(30);
    aErrorCode                    varchar2(255);
    aErrorMsg                     varchar2(255);
    aNeedQty                      number;
  begin
    -- Purge des enregistrements temporaire qui auraient pu subsister
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeAllTemporaryTable(DBMS_SESSION.unique_session_id);
    -- Contrôle des données pour la sortie de composants
    FAL_OUT_COMPO_BARCODE_CONTROL.ControlOutCompoBarcodeTable(aFAL_OUT_COMPO_BARCODE_ID);

    begin
      select C_OUT_COMPO_ERROR
           , nvl(FOC_ACCEPT, 0)
        into lvOutCompoError
           , liFocAccept
        from FAL_OUT_COMPO_BARCODE
       where FAL_OUT_COMPO_BARCODE_ID = aFAL_OUT_COMPO_BARCODE_ID;

      /* Si le code d'erreur est null ou à '10' (Qté saisie inférieure au besoin) ou '09' (Qté saisie supérieure au besoin) avec "acceptation",
         on continue. Sinon, on retourne le code d'erreur. */
      if not(    (lvOutCompoError is null)
             or (lvOutCompoError = '10')
             or (    lvOutCompoError = '09'
                 and liFocAccept = 1) ) then
        return;
      end if;
    exception
      when others then
        FAL_OUT_COMPO_BARCODE_CONTROL.UpdateBarcodeRecordError(aFAL_OUT_COMPO_BARCODE_ID
                                                             , '00'
                                                             , aFAL_OUT_COMPO_BARCODE_ID || ' - ' || DBMS_UTILITY.FORMAT_ERROR_STACK
                                                              );
        return;
    end;

    -- Récupération de l'ID de la position de stock ainsi que des valeurs de caractérisation
    begin
      select SPO.STM_STOCK_POSITION_ID
           , SPO.GCO_CHARACTERIZATION_ID
           , SPO.GCO_GCO_CHARACTERIZATION_ID
           , SPO.GCO2_GCO_CHARACTERIZATION_ID
           , SPO.GCO3_GCO_CHARACTERIZATION_ID
           , SPO.GCO4_GCO_CHARACTERIZATION_ID
           , SPO.SPO_CHARACTERIZATION_VALUE_1
           , SPO.SPO_CHARACTERIZATION_VALUE_2
           , SPO.SPO_CHARACTERIZATION_VALUE_3
           , SPO.SPO_CHARACTERIZATION_VALUE_4
           , SPO.SPO_CHARACTERIZATION_VALUE_5
           , SPO.SPO_PIECE
           , SPO.SPO_SET
           , SPO.SPO_VERSION
           , SPO.SPO_CHRONOLOGICAL
        into aSTM_STOCK_POSITION_ID
           , aCHARACT_ID1
           , aCHARACT_ID2
           , aCHARACT_ID3
           , aCHARACT_ID4
           , aCHARACT_ID5
           , aCHARACT_VALUE1
           , aCHARACT_VALUE2
           , aCHARACT_VALUE3
           , aCHARACT_VALUE4
           , aCHARACT_VALUE5
           , aSPO_PIECE
           , aSPO_SET
           , aSPO_VERSION
           , aSPO_CHRONOLOGICAL
        from STM_STOCK_POSITION SPO
       where SPO.STM_STOCK_POSITION_ID =
               (select max(STM_STOCK_POSITION_ID)
                  from STM_STOCK_POSITION
                 where GCO_GOOD_ID = aGCO_GOOD_ID
                   and STM_STOCK_ID = aSTM_STOCK_ID
                   and STM_LOCATION_ID = aSTM_LOCATION_ID
                   and (    (    aFOC_CHARACTERIZATION_VALUE_1 is null
                             and GCO_CHARACTERIZATION_ID is null)
                        or SPO_CHARACTERIZATION_VALUE_1 = aFOC_CHARACTERIZATION_VALUE_1
                       )
                   and (    (    aFOC_CHARACTERIZATION_VALUE_2 is null
                             and GCO_GCO_CHARACTERIZATION_ID is null)
                        or SPO_CHARACTERIZATION_VALUE_2 = aFOC_CHARACTERIZATION_VALUE_2
                       )
                   and (    (    aFOC_CHARACTERIZATION_VALUE_3 is null
                             and GCO2_GCO_CHARACTERIZATION_ID is null)
                        or SPO_CHARACTERIZATION_VALUE_3 = aFOC_CHARACTERIZATION_VALUE_3
                       )
                   and (    (    aFOC_CHARACTERIZATION_VALUE_4 is null
                             and GCO3_GCO_CHARACTERIZATION_ID is null)
                        or SPO_CHARACTERIZATION_VALUE_4 = aFOC_CHARACTERIZATION_VALUE_4
                       )
                   and (    (    aFOC_CHARACTERIZATION_VALUE_5 is null
                             and GCO4_GCO_CHARACTERIZATION_ID is null)
                        or SPO_CHARACTERIZATION_VALUE_5 = aFOC_CHARACTERIZATION_VALUE_5
                       ) );
    exception
      when no_data_found then
        begin
          FAL_OUT_COMPO_BARCODE_CONTROL.UpdateBarcodeRecordError(aFAL_OUT_COMPO_BARCODE_ID, ocErrorBetwComputAndPhysicStk);
          return;
        end;
    end;

    -- Si on a pas trouvé la position de stock, on retourne l'erreur 06
    if aSTM_STOCK_POSITION_ID = 0 then
      FAL_OUT_COMPO_BARCODE_CONTROL.UpdateBarcodeRecordError(aFAL_OUT_COMPO_BARCODE_ID, ocErrorBetwComputAndPhysicStk);
      return;
    end if;

    savepoint spBeforeCompOutput;
    -- Initialisation de la liste des mouvements de stock à déclencher par la suite
    aPreparedStockMovements  := FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements();
    aMATERIAL_LINK_ID        := nvl(aFAL_LOT_MATERIAL_LINK_ID, 0);

    if aMATERIAL_LINK_ID = 0 then
      -- Création dynamique d'un composant inexistant dans la nomenclature du lot
      aMATERIAL_LINK_ID  := CreateNewComponent(aFAL_LOT_ID, aGCO_GOOD_ID, aSTM_STOCK_ID, aSTM_LOCATION_ID, aFOC_QUANTITY);
    end if;

    select LOM_NEED_QTY
      into aNeedQty
      from FAL_LOT_MATERIAL_LINK
     where FAL_LOT_MATERIAL_LINK_ID = aMATERIAL_LINK_ID;

    -- Création composants temporaire pour réservation sur stock
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aFalLotId               => aFAL_LOT_ID
                                                  , aFalLotMaterialLinkId   => aMATERIAL_LINK_ID
                                                  , aSessionId              => DBMS_SESSION.unique_session_id
                                                  , aContext                => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBarCodeComponentOutput
                                                  , aQtySup                 => greatest(aFOC_QUANTITY - aNeedQty, 0)
                                                   );

    begin
      select FAL_LOT_MAT_LINK_TMP_ID
        into aTEMP_MATERIAL_LINK_ID
        from FAL_LOT_MAT_LINK_TMP
       where FAL_LOT_MATERIAL_LINK_ID = aMATERIAL_LINK_ID
         and LOM_SESSION = DBMS_SESSION.unique_session_id;
    exception
      when others then
        aTEMP_MATERIAL_LINK_ID  := 0;
    end;

    -- Réservation sur stock (les attribs éventuelles ont été préalablement supprimée dans un traitement antérieur!)
    FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkStockAvalaible(DBMS_SESSION.unique_session_id, aTEMP_MATERIAL_LINK_ID, aSTM_STOCK_POSITION_ID, aFOC_QUANTITY);

    -- Récupération du lien créé
    begin
      select FCL.FAL_COMPONENT_LINK_ID
        into aCreatedFAL_COMPONENT_LINK_ID
        from FAL_COMPONENT_LINK FCL
       where FCL_SESSION = DBMS_SESSION.unique_session_id
         and FAL_LOT_MAT_LINK_TMP_ID = aTEMP_MATERIAL_LINK_ID;
    exception
      -- si la réservation n'est pas Ok
      when no_data_found then
        begin
          rollback to savepoint spBeforeCompOutput;
          FAL_OUT_COMPO_BARCODE_CONTROL.UpdateBarcodeRecordError(aFAL_OUT_COMPO_BARCODE_ID, ocErrorBetwComputAndPhysicStk);
          return;
        end;
    end;

    -- MAJ des liens composants lot pseudo selon les compos rattachés
    FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION                => DBMS_SESSION.unique_session_id
                                                         , aFAL_LOT_ID                 => aFAL_LOT_ID
                                                         , aFAL_LOT_MATERIAL_LINK_ID   => aMATERIAL_LINK_ID
                                                         , aContext                    => FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput
                                                          );
    -- MAJ de la quantité max réceptionnable du lot
    FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(aFAL_LOT_ID, -1);
    -- MAJ de l'ordre selon le lot en cours
    FAL_ORDER_FUNCTIONS.UpdateOrder(null, aFAL_LOT_ID);
    -- Créations des entrées atelier pour le lot
    FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID                 => aFAL_LOT_ID
                                                    , aFCL_SESSION                => DBMS_SESSION.unique_session_id
                                                    , aPreparedStockMovement      => aPreparedStockMovements
                                                    , aOUT_DATE                   => sysdate
                                                    , aMovementKind               => FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier
                                                    , aC_IN_ORIGINE               => '7'
                                                    , aFAL_LOT_MATERIAL_LINK_ID   => aMATERIAL_LINK_ID
                                                     );
    -- Déclencher les mouvements de stock préalablement préparés
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(aPreparedStockMovements, aErrorCode, aErrorMsg, FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault, 1);
    -- Mise à jour Réseaux
    FAL_NETWORK.MiseAJourReseaux(aFAL_LOT_ID, FAL_NETWORK.ncSortieComposant, '');

    -- Traitement erreurs lors du passage des mouvements de stock
    if aErrorCode is not null then
      if aErrorCode = 'excUnAuthorizedMvt' then
        lvOutCompoError  := ocUnAuthorizedMvt;
      else
        lvOutCompoError  := ocErrorOnMvtExecution;
      end if;

      -- MAJ Erreur sortie composant code barre
      rollback to savepoint spBeforeCompOutput;
      FAL_OUT_COMPO_BARCODE_CONTROL.UpdateBarcodeRecordError(aFAL_OUT_COMPO_BARCODE_ID, lvOutCompoError, aErrorMsg);
      return;
    end if;

    -- Mise à jour des Entrées Atelier avec les positions de stock créées
    -- dans le stock Atelier par les mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(aPreparedStockMovements);
    -- Appel de procédure d'individualisation
    ExecuteExternalProc(aFAL_OUT_COMPO_BARCODE_ID, aFAL_LOT_MATERIAL_LINK_ID);

    -- Suppression du composant sur lequel les traitements ont été appliqué correctement
    delete from FAL_OUT_COMPO_BARCODE
          where FAL_OUT_COMPO_BARCODE_ID = aFAL_OUT_COMPO_BARCODE_ID;

    -- Purge des enregistrements temporaire créés
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeLotMatLinkTmpTable(DBMS_SESSION.unique_session_id);
    FAL_COMPONENT_LINK_FCT.PurgeComponentLinkTable(DBMS_SESSION.unique_session_id);
  end;

  /**
  * Procedure ProcessOutComponent
  * Description : Sortie de composants code barre
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     iCompoBarcodeId       ID sortie composant code barre
  */
  procedure ProcessOutComponent(iCompoBarcodeId in number)
  is
    cursor crOutCompoBarcode
    is
      select   GCO_CHARACTERIZATION_ID
             , GCO_GCO_CHARACTERIZATION_ID
             , GCO2_GCO_CHARACTERIZATION_ID
             , GCO3_GCO_CHARACTERIZATION_ID
             , GCO4_GCO_CHARACTERIZATION_ID
             , STM_LOCATION_ID
             , GCO_GOOD_ID
             , STM_STOCK_ID
             , FAL_LOT_ID
             , FAL_LOT_MATERIAL_LINK_ID
             , FOC_QUANTITY
             , FOC_DATE
             , FOC_PRICE
             , FOC_CHARACTERIZATION_VALUE_1
             , FOC_CHARACTERIZATION_VALUE_2
             , FOC_CHARACTERIZATION_VALUE_3
             , FOC_CHARACTERIZATION_VALUE_4
             , FOC_CHARACTERIZATION_VALUE_5
             , FOC_LOM_SEQ
             , FOC_LOT_REFCOMPL
             , FOC_GOO_MAJOR_REFERENCE
             , DIC_OPERATOR_ID
             , FOC_ACCEPT
          from FAL_OUT_COMPO_BARCODE
         where FAL_OUT_COMPO_BARCODE_ID = iCompoBarcodeId
      order by GCO_GOOD_ID;

    tplOutCompoBarcode crOutCompoBarcode%rowtype;
  begin
    open crOutCompoBarcode;

    fetch crOutCompoBarcode
     into tplOutCompoBarcode;

    if crOutCompoBarcode%found then
      ProcessOutComponent(iCompoBarcodeId
                        , tplOutCompoBarcode.GCO_CHARACTERIZATION_ID
                        , tplOutCompoBarcode.GCO_GCO_CHARACTERIZATION_ID
                        , tplOutCompoBarcode.GCO2_GCO_CHARACTERIZATION_ID
                        , tplOutCompoBarcode.GCO3_GCO_CHARACTERIZATION_ID
                        , tplOutCompoBarcode.GCO4_GCO_CHARACTERIZATION_ID
                        , tplOutCompoBarcode.STM_LOCATION_ID
                        , tplOutCompoBarcode.GCO_GOOD_ID
                        , tplOutCompoBarcode.STM_STOCK_ID
                        , tplOutCompoBarcode.FAL_LOT_ID
                        , tplOutCompoBarcode.FAL_LOT_MATERIAL_LINK_ID
                        , tplOutCompoBarcode.FOC_QUANTITY
                        , tplOutCompoBarcode.FOC_DATE
                        , tplOutCompoBarcode.FOC_PRICE
                        , tplOutCompoBarcode.FOC_CHARACTERIZATION_VALUE_1
                        , tplOutCompoBarcode.FOC_CHARACTERIZATION_VALUE_2
                        , tplOutCompoBarcode.FOC_CHARACTERIZATION_VALUE_3
                        , tplOutCompoBarcode.FOC_CHARACTERIZATION_VALUE_4
                        , tplOutCompoBarcode.FOC_CHARACTERIZATION_VALUE_5
                        , tplOutCompoBarcode.FOC_LOM_SEQ
                        , tplOutCompoBarcode.FOC_LOT_REFCOMPL
                        , tplOutCompoBarcode.FOC_GOO_MAJOR_REFERENCE
                        , tplOutCompoBarcode.DIC_OPERATOR_ID
                         );
    end if;

    close crOutCompoBarcode;
  end;
end;
