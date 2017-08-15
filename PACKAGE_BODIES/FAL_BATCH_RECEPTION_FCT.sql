--------------------------------------------------------
--  DDL for Package Body FAL_BATCH_RECEPTION_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_BATCH_RECEPTION_FCT" 
is
  -- Statuts des enregistrements temporaires C_BRC_STATUS
  bsToReceive     constant FAL_BATCH_RECEPTION.C_BRC_STATUS%type   := '10';   -- A réceptionner
  bsReceived      constant FAL_BATCH_RECEPTION.C_BRC_STATUS%type   := '20';   -- Réceptionné sans erreur
  bsReceptError   constant FAL_BATCH_RECEPTION.C_BRC_STATUS%type   := '30';   -- Erreur lors de la réception
  bsReceptAborted constant FAL_BATCH_RECEPTION.C_BRC_STATUS%type   := '40';   -- Abandon par procédure indiv
  -- Mode de l'assistant
  bmReception     constant integer                                 := 0;   -- Mode réception
  bmBalance       constant integer                                 := 1;   -- Mode solde
  -- Destinations des composants C_COMPO_DEST
  cdReject        constant FAL_BATCH_RECEPTION.C_COMPO_DEST%type   := '10';   -- Déchets
  cdStock         constant FAL_BATCH_RECEPTION.C_COMPO_DEST%type   := '20';   -- A retourner en stock
  -- Statuts de lot C_LOT_STATUS
  lsLaunched               FAL_LOT.C_LOT_STATUS%type               := '2';   -- Lancé
  -- Type de lot C_FAB_TYPE
  ftSubcontract            FAL_LOT.C_FAB_TYPE%type                 := '4';   -- Soust-traitance
  -- Configuration
  cCalcRecept     constant varchar2(10)                            := PCS.PC_CONFIG.GetConfig('FAL_CALC_RECEPT');

  /**
   * procedure CalcBatchStats
   * Description
   *   Applique le profil passé en paramètre (le premier paramètre non nul) et
   *   calcule les données pour la mise à jour des gammes
   */
  procedure CalcBatchStats(aProfileID in number default null, aClobProfile in clob default null)
  is
    vClobProfile clob;
    aXmlProfile  xmltype;
    vOptions     TBRCOptions;
  begin
    if aProfileID is not null then
      vOptions  := GetBRCProfileValues(PCS.COM_PROFILE_FUNCTIONS.GetXMLProfile(aProfileID) );
    elsif aClobProfile is not null then
      vOptions  := GetBRCProfileValues(xmltype.CreateXML(aClobProfile) );
    end if;

    ApplyBRCOptions(vOptions);
    CalcBatchValues(vOptions.BRC_SELECTION
                  , vOptions.BRC_DATE
                  , case
                      when vOptions.BRC_MODE = bmBalance then 0
                      else vOptions.BRC_AUTO_BATCH_BALANCE
                    end
                  , case
                      when vOptions.BRC_MODE = bmBalance then 1
                      else vOptions.BRC_BATCH_BALANCE
                    end
                  , vOptions.BRC_C_COMPO_DEST
                  , vOptions.STM_COMPO_STOCK_ID
                  , vOptions.STM_COMPO_LOCATION_ID
                  , vOptions.BRC_ONLY_WITH_RECEIVABLE_QTY
                  , case
                      when vOptions.BRC_MODE = bmBalance then 1
                      else 0
                    end
                   );
  end CalcBatchStats;

  /**
   * procedure ApplyBRCOptions
   * Description
   *   Applique les options du profil (sélection des produits et lots)
   */
  procedure ApplyBRCOptions(aOptions in TBRCOptions)
  is
  begin
    SelectProducts(aBRC_PRODUCT_FROM             => aOptions.BRC_PRODUCT_FROM
                 , aBRC_PRODUCT_TO               => aOptions.BRC_PRODUCT_TO
                 , aBRC_GOOD_CATEGORY_FROM       => aOptions.BRC_GOOD_CATEGORY_FROM
                 , aBRC_GOOD_CATEGORY_TO         => aOptions.BRC_GOOD_CATEGORY_TO
                 , aBRC_GOOD_FAMILY_FROM         => aOptions.BRC_GOOD_FAMILY_FROM
                 , aBRC_GOOD_FAMILY_TO           => aOptions.BRC_GOOD_FAMILY_TO
                 , aBRC_ACCOUNTABLE_GROUP_FROM   => aOptions.BRC_ACCOUNTABLE_GROUP_FROM
                 , aBRC_ACCOUNTABLE_GROUP_TO     => aOptions.BRC_ACCOUNTABLE_GROUP_TO
                 , aBRC_GOOD_LINE_FROM           => aOptions.BRC_GOOD_LINE_FROM
                 , aBRC_GOOD_LINE_TO             => aOptions.BRC_GOOD_LINE_TO
                 , aBRC_GOOD_GROUP_FROM          => aOptions.BRC_GOOD_GROUP_FROM
                 , aBRC_GOOD_GROUP_TO            => aOptions.BRC_GOOD_GROUP_TO
                 , aBRC_GOOD_MODEL_FROM          => aOptions.BRC_GOOD_MODEL_FROM
                 , aBRC_GOOD_MODEL_TO            => aOptions.BRC_GOOD_MODEL_TO
                  );
    SelectBatches(aBRC_OPEN__DTE_FROM     => aOptions.BRC_OPEN__DTE_FROM
                , aBRC_OPEN__DTE_TO       => aOptions.BRC_OPEN__DTE_TO
                , aBRC_JOB_PROGRAM_FROM   => aOptions.BRC_JOB_PROGRAM_FROM
                , aBRC_JOB_PROGRAM_TO     => aOptions.BRC_JOB_PROGRAM_TO
                , aBRC_ORDER_FROM         => aOptions.BRC_ORDER_FROM
                , aBRC_ORDER_TO           => aOptions.BRC_ORDER_TO
                , aBRC_C_PRIORITY_FROM    => aOptions.BRC_C_PRIORITY_FROM
                , aBRC_C_PRIORITY_TO      => aOptions.BRC_C_PRIORITY_TO
                , aBRC_FAMILY_FROM        => aOptions.BRC_FAMILY_FROM
                , aBRC_FAMILY_TO          => aOptions.BRC_FAMILY_TO
                , aBRC_RECORD_FROM        => aOptions.BRC_RECORD_FROM
                , aBRC_RECORD_TO          => aOptions.BRC_RECORD_TO
                 );
  end;

  /**
   * procedure SelectProduct
   * Description
   *   Sélectionne le produit
  *
  */
  procedure SelectProduct(aGCO_GOOD_ID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    -- Sélection de l'ID de la gamme à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aGCO_GOOD_ID
               , 'GCO_GOOD_ID'
                );
  end SelectProduct;

  /**
   * procedure SelectProducts
   * Description
   *   Sélectionne les produits selon les filtres
   */
  procedure SelectProducts(
    aBRC_PRODUCT_FROM           in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aBRC_PRODUCT_TO             in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aBRC_GOOD_CATEGORY_FROM     in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aBRC_GOOD_CATEGORY_TO       in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aBRC_GOOD_FAMILY_FROM       in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aBRC_GOOD_FAMILY_TO         in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aBRC_ACCOUNTABLE_GROUP_FROM in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aBRC_ACCOUNTABLE_GROUP_TO   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aBRC_GOOD_LINE_FROM         in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aBRC_GOOD_LINE_TO           in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aBRC_GOOD_GROUP_FROM        in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aBRC_GOOD_GROUP_TO          in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aBRC_GOOD_MODEL_FROM        in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , aBRC_GOOD_MODEL_TO          in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    -- Sélection des ID de gammes à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct GOO.GCO_GOOD_ID
                    , 'GCO_GOOD_ID'
                 from GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , GCO_GOOD_CATEGORY CAT
                where GOO.GOO_MAJOR_REFERENCE between nvl(aBRC_PRODUCT_FROM, GOO.GOO_MAJOR_REFERENCE) and nvl(aBRC_PRODUCT_TO, GOO.GOO_MAJOR_REFERENCE)
                  and PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                  and (   cCalcRecept = '1'
                       or GOO.C_MANAGEMENT_MODE <> '1')
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and (    (    aBRC_GOOD_CATEGORY_FROM is null
                            and aBRC_GOOD_CATEGORY_TO is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(aBRC_GOOD_CATEGORY_FROM, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(aBRC_GOOD_CATEGORY_TO, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    aBRC_GOOD_FAMILY_FROM is null
                            and aBRC_GOOD_FAMILY_TO is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(aBRC_GOOD_FAMILY_FROM, GOO.DIC_GOOD_FAMILY_ID) and nvl(aBRC_GOOD_FAMILY_TO, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    aBRC_ACCOUNTABLE_GROUP_FROM is null
                            and aBRC_ACCOUNTABLE_GROUP_TO is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(aBRC_ACCOUNTABLE_GROUP_FROM, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(aBRC_ACCOUNTABLE_GROUP_TO, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    aBRC_GOOD_LINE_FROM is null
                            and aBRC_GOOD_LINE_TO is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(aBRC_GOOD_LINE_FROM, GOO.DIC_GOOD_LINE_ID) and nvl(aBRC_GOOD_LINE_TO, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    aBRC_GOOD_GROUP_FROM is null
                            and aBRC_GOOD_GROUP_TO is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(aBRC_GOOD_GROUP_FROM, GOO.DIC_GOOD_GROUP_ID) and nvl(aBRC_GOOD_GROUP_TO, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    aBRC_GOOD_MODEL_FROM is null
                            and aBRC_GOOD_MODEL_TO is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(aBRC_GOOD_MODEL_FROM, GOO.DIC_GOOD_MODEL_ID) and nvl(aBRC_GOOD_MODEL_TO, GOO.DIC_GOOD_MODEL_ID)
                      );
  end SelectProducts;

  /**
   * procedure SelectBatch
   * Description
   *   Sélectionne un lot à réceptionner
   */
  procedure SelectBatch(aFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection de l'ID du lot à réceptionner
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aFAL_LOT_ID
               , 'FAL_LOT_ID'
                );
  end SelectBatch;

  /**
   * procedure SelectBatches
   * Description
   *   Sélectionne les lots à réceptionner
   */
  procedure SelectBatches(
    aBRC_OPEN__DTE_FROM   in FAL_LOT.LOT_OPEN__DTE%type
  , aBRC_OPEN__DTE_TO     in FAL_LOT.LOT_OPEN__DTE%type
  , aBRC_JOB_PROGRAM_FROM in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aBRC_JOB_PROGRAM_TO   in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aBRC_ORDER_FROM       in FAL_ORDER.ORD_REF%type
  , aBRC_ORDER_TO         in FAL_ORDER.ORD_REF%type
  , aBRC_C_PRIORITY_FROM  in FAL_LOT.C_PRIORITY%type
  , aBRC_C_PRIORITY_TO    in FAL_LOT.C_PRIORITY%type
  , aBRC_FAMILY_FROM      in DIC_FAMILY.DIC_FAMILY_ID%type
  , aBRC_FAMILY_TO        in DIC_FAMILY.DIC_FAMILY_ID%type
  , aBRC_RECORD_FROM      in DOC_RECORD.RCO_TITLE%type
  , aBRC_RECORD_TO        in DOC_RECORD.RCO_TITLE%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection des ID de lots à réceptionner
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_ID
                    , 'FAL_LOT_ID'
                 from FAL_LOT LOT
                    , FAL_JOB_PROGRAM JOP
                    , FAL_ORDER ORD
                    , DOC_RECORD RCO
                where LOT.GCO_GOOD_ID in(select COM_LIST_ID_TEMP_ID
                                           from COM_LIST_ID_TEMP
                                          where LID_CODE = 'GCO_GOOD_ID')
                  and LOT.LOT_OPEN__DTE is not null
                  and nvl(LOT.C_FAB_TYPE, '0') <> ftSubcontract
                  and LOT.C_LOT_STATUS = lsLaunched
                  and (    (    aBRC_OPEN__DTE_FROM is null
                            and aBRC_OPEN__DTE_TO is null)
                       or LOT.LOT_OPEN__DTE between nvl(aBRC_OPEN__DTE_FROM, LOT.LOT_OPEN__DTE) and nvl(aBRC_OPEN__DTE_TO, LOT.LOT_OPEN__DTE)
                      )
                  and LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                  and (    (    aBRC_JOB_PROGRAM_FROM is null
                            and aBRC_JOB_PROGRAM_TO is null)
                       or JOP.JOP_REFERENCE between nvl(aBRC_JOB_PROGRAM_FROM, JOP.JOP_REFERENCE) and nvl(aBRC_JOB_PROGRAM_TO, JOP.JOP_REFERENCE)
                      )
                  and LOT.FAL_ORDER_ID = ORD.FAL_ORDER_ID
                  and (    (    aBRC_ORDER_FROM is null
                            and aBRC_ORDER_TO is null)
                       or ORD.ORD_REF between nvl(aBRC_ORDER_FROM, ORD.ORD_REF) and nvl(aBRC_ORDER_TO, ORD.ORD_REF)
                      )
                  and (    (    aBRC_C_PRIORITY_FROM is null
                            and aBRC_C_PRIORITY_TO is null)
                       or LOT.C_PRIORITY between nvl(aBRC_C_PRIORITY_FROM, LOT.C_PRIORITY) and nvl(aBRC_C_PRIORITY_TO, LOT.C_PRIORITY)
                      )
                  and (    (    aBRC_FAMILY_FROM is null
                            and aBRC_FAMILY_TO is null)
                       or LOT.DIC_FAMILY_ID between nvl(aBRC_FAMILY_FROM, LOT.DIC_FAMILY_ID) and nvl(aBRC_FAMILY_TO, LOT.DIC_FAMILY_ID)
                      )
                  and LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (    (    aBRC_RECORD_FROM is null
                            and aBRC_RECORD_TO is null)
                       or RCO.RCO_TITLE between nvl(aBRC_RECORD_FROM, RCO.RCO_TITLE) and nvl(aBRC_RECORD_TO, RCO.RCO_TITLE)
                      );
  end SelectBatches;

  /**
   * procedure CalcBatchValues
   * Description
   *   Crée les enregistrements temporaires et calcule les données à utiliser
   *   pour la mise à jour des gammes
   */
  procedure CalcBatchValues(
    aDefaultSelection       in FAL_BATCH_RECEPTION.BRC_SELECTION%type
  , aDefaultDate            in FAL_BATCH_RECEPTION.BRC_DATE%type
  , aAutoBatchBalance       in integer
  , aDefaultBatchBalance    in FAL_BATCH_RECEPTION.BRC_BATCH_BALANCE%type
  , aDefaultCompoDest       in FAL_BATCH_RECEPTION.C_COMPO_DEST%type
  , aDefaultCompoStockId    in FAL_BATCH_RECEPTION.STM_COMPO_STOCK_ID%type
  , aDefaultCompoLocationId in FAL_BATCH_RECEPTION.STM_COMPO_LOCATION_ID%type
  , aOnlyWithReceivableQty  in integer default 0
  , aExcludeWithInProdQty   in integer default 0
  )
  is
    vRejectStockId    FAL_LOT.STM_STOCK_ID%type;
    vRejectLocationId FAL_LOT.STM_LOCATION_ID%type;
  begin
    -- Recherchde des stocks rebut par défaut
    vRejectStockId     := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_TRASH');
    vRejectLocationId  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_TRASH', vRejectStockId);

    -- Suppression des enregistrements précédents non-traités
    delete from FAL_BATCH_RECEPTION
          where C_BRC_STATUS = bsToReceive;

    -- Insertion des enregistrements à traiter
    insert into FAL_BATCH_RECEPTION
                (FAL_BATCH_RECEPTION_ID
               , FAL_LOT_ID
               , C_BRC_STATUS
               , BRC_SELECTION
               , BRC_PRODUCT_QTY
               , BRC_REJECT_QTY
               , BRC_DISMOUNTED_QTY
               , BRC_DATE
               , BRC_BATCH_BALANCE
               , STM_PRODUCT_STOCK_ID
               , STM_PRODUCT_LOCATION_ID
               , STM_REJECT_STOCK_ID
               , STM_REJECT_LOCATION_ID
               , C_COMPO_DEST
               , STM_COMPO_STOCK_ID
               , STM_COMPO_LOCATION_ID
                )
      select INIT_TEMP_ID_SEQ.nextval   -- FAL_BATCH_RECEPTION_ID
           , LOT.FAL_LOT_ID
           , bsToReceive
           , aDefaultSelection
           , LOT.LOT_MAX_RELEASABLE_QTY
           , LOT.LOT_PT_REJECT_QTY
           , LOT.LOT_CPT_REJECT_QTY
           , aDefaultDate
           , case
               when(aAutoBatchBalance = 1)
               and (LOT.LOT_MAX_RELEASABLE_QTY >= LOT.LOT_INPROD_QTY) then 1
               when(aAutoBatchBalance = 1)
               and (LOT.LOT_MAX_RELEASABLE_QTY < LOT.LOT_INPROD_QTY) then 0
               else aDefaultBatchBalance
             end BRC_BATCH_BALANCE
           , LOT.STM_STOCK_ID
           , LOT.STM_LOCATION_ID
           , vRejectStockId
           , vRejectLocationId
           , aDefaultCompoDest
           , aDefaultCompoStockId
           , aDefaultCompoLocationId
        from FAL_LOT LOT
       where LOT.FAL_LOT_ID in(select COM_LIST_ID_TEMP_ID
                                 from COM_LIST_ID_TEMP
                                where LID_CODE = 'FAL_LOT_ID')
         and (   aOnlyWithReceivableQty = 0
              or LOT.LOT_MAX_RELEASABLE_QTY > 0
              or LOT.LOT_PT_REJECT_QTY > 0
              or LOT.LOT_CPT_REJECT_QTY > 0)
         and (   aExcludeWithInProdQty = 0
              or LOT.LOT_INPROD_QTY = 0);
  end CalcBatchValues;

  /**
   * procedure InitNewValues
   * Description
   *   Initialise un champ de la table temporaire selon un autre champ ou une
   *   formule
   */
  procedure InitNewValues(aSrcFieldName in varchar2, aDestFieldName in varchar2)
  is
    vSqlCommand varchar2(100);
  begin
    vSqlCommand  := 'update FAL_BATCH_RECEPTION set ' || aDestFieldName || ' = ' || aSrcFieldName;

    execute immediate vSqlCommand;
  end InitNewValues;

  /**
   * procedure ProcessBatchReceptions
   * Description
   *   Réceptionne les lots à partir des données des enregistrements temporaires
   */
  procedure ProcessBatchReceptions(
    aBRC_GLOBAL_BEFORE_PROC in     varchar2 default null
  , aBRC_DETAIL_BEFORE_PROC in     varchar2 default null
  , aBRC_DETAIL_AFTER_PROC  in     varchar2 default null
  , aSuccessfulCount        out    integer
  , aTotalCount             out    integer
  )
  is
    cursor crBatchesValues
    is
      select   BRC.FAL_BATCH_RECEPTION_ID
             , BRC.FAL_LOT_ID
             , nvl(BRC.BRC_PRODUCT_QTY, 0) BRC_PRODUCT_QTY
             , nvl(BRC.BRC_REJECT_QTY, 0) BRC_REJECT_QTY
             , nvl(BRC.BRC_DISMOUNTED_QTY, 0) BRC_DISMOUNTED_QTY
             , BRC.C_COMPO_DEST
             , BRC.BRC_DATE
             , BRC.BRC_BATCH_BALANCE
             , BRC.STM_PRODUCT_STOCK_ID
             , BRC.STM_PRODUCT_LOCATION_ID
             , BRC.STM_REJECT_STOCK_ID
             , BRC.STM_REJECT_LOCATION_ID
             , BRC.STM_COMPO_STOCK_ID
             , BRC.STM_COMPO_LOCATION_ID
          from FAL_BATCH_RECEPTION BRC
             , FAL_LOT LOT
         where BRC.BRC_SELECTION = 1
           and BRC.C_BRC_STATUS = bsToReceive
           and LOT.FAL_LOT_ID = BRC.FAL_LOT_ID
      order by BRC.FAL_LOT_ID;

    vBRC_GLOBAL_PROC        varchar2(255);
    vBRC_DETAIL_BEFORE_PROC varchar2(255);
    vBRC_DETAIL_AFTER_PROC  varchar2(255);
    vResult                 integer;
    vProcResult             integer        := 1;
    vReturnCompoIsScrap     integer(1);
    vSqlMsg                 varchar2(4000);
    liAutoInitCharact       integer        := 0;
  begin
    -- Recherche des procédures stockées si elles n'ont pas été passées en pramètre
    vBRC_GLOBAL_PROC         := nvl(aBRC_GLOBAL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_BRC_GLOBAL_PROC') );
    vBRC_DETAIL_BEFORE_PROC  := nvl(aBRC_DETAIL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_BRC_DETAIL_BEFORE_PROC') );
    vBRC_DETAIL_AFTER_PROC   := nvl(aBRC_DETAIL_AFTER_PROC, PCS.PC_CONFIG.GetConfig('FAL_BRC_DETAIL_AFTER_PROC') );
    -- Purge des lots vérouillés par des sessions inactives et initialisation des compteurs
    FAL_BATCH_RESERVATION.PurgeInactiveBatchReservation;
    aSuccessfulCount         := 0;
    aTotalCount              := 0;

    -- Execution de la procédure stockée globale
    if vBRC_GLOBAL_PROC is not null then
      begin
        execute immediate 'begin :Result :=  ' || vBRC_GLOBAL_PROC || '; end;'
                    using out vProcResult;

        if vProcResult < 1 then
          vSqlMsg  :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a interrompu le traitement. Valeur retournée :') || ' '
                    || to_char(vProcResult);
        end if;
      exception
        when others then
          begin
            vSqlMsg  :=
                     PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a généré une erreur :') || chr(13) || chr(10)
                     || DBMS_UTILITY.FORMAT_ERROR_STACK;
          end;
      end;
    end if;

    if vSqlMsg is not null then
      -- Abandon du traitement pour tous les enregistrements sélectionnés
      -- Supression des résultats des tentatives de réception précédentes
      delete from FAL_BATCH_RECEPTION
            where FAL_LOT_ID in(select FAL_LOT_ID
                                  from FAL_BATCH_RECEPTION
                                 where BRC_SELECTION = 1
                                   and C_BRC_STATUS = bsToReceive)
              and FAL_BATCH_RECEPTION_ID not in(select FAL_BATCH_RECEPTION_ID
                                                  from FAL_BATCH_RECEPTION
                                                 where BRC_SELECTION = 1
                                                   and C_BRC_STATUS = bsToReceive);

      -- Mise à jour des statuts et des détails de l'abandon dans la table temporaire
      update FAL_BATCH_RECEPTION
         set BRC_SELECTION = 0
           , C_BRC_STATUS = bsReceptAborted
           , BRC_ERROR_MESSAGE = vSqlMsg
       where BRC_SELECTION = 1
         and C_BRC_STATUS = bsToReceive;
    else
      -- Pour chaque élément sélectionné de la table temporaire
      for tplBatchValues in crBatchesValues loop
        begin
          -- Incrémentation du compteur total
          aTotalCount  := aTotalCount + 1;

          -- Supression des résultats des tentatives de réception précédentes
          delete from FAL_BATCH_RECEPTION
                where FAL_LOT_ID = tplBatchValues.FAL_LOT_ID
                  and FAL_BATCH_RECEPTION_ID <> tplBatchValues.FAL_BATCH_RECEPTION_ID;

          -- Execution de la procédure stockée de pré-traitement
          if vBRC_DETAIL_BEFORE_PROC is not null then
            begin
              execute immediate 'begin :Result :=  ' || vBRC_DETAIL_BEFORE_PROC || '(:FAL_BATCH_RECEPTION_ID); end;'
                          using out vProcResult, in tplBatchValues.FAL_BATCH_RECEPTION_ID;

              if vProcResult < 1 then
                vSqlMsg  :=
                  PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a interrompu le traitement. Valeur retournée :') ||
                  ' ' ||
                  to_char(vProcResult);
              end if;
            exception
              when others then
                begin
                  vProcResult  := 0;
                  vSqlMsg      :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a généré une erreur :') ||
                    chr(13) ||
                    chr(10) ||
                    DBMS_UTILITY.FORMAT_ERROR_STACK;
                end;
            end;
          end if;

          if vSqlMsg is null then
            -- Determination de la destination des composants
            case tplBatchValues.C_COMPO_DEST
              when cdReject then
                vReturnCompoIsScrap  := 1;
              when cdStock then
                vReturnCompoIsScrap  := 0;
              else
                vReturnCompoIsScrap  := 0;
            end case;

            -- Réception du lot
            vResult  := FAL_BATCH_FUNCTIONS.rtOkStart;
            FAL_BATCH_FUNCTIONS.Recept(aFalLotId                => tplBatchValues.FAL_LOT_ID
                                     , aSessionId               => DBMS_SESSION.unique_session_id
                                     , aFinishedProductQty      => tplBatchValues.BRC_PRODUCT_QTY
                                     , aRejectQty               => tplBatchValues.BRC_REJECT_QTY
                                     , aDismountedQty           => tplBatchValues.BRC_DISMOUNTED_QTY
                                     , aStockId                 => tplBatchValues.STM_PRODUCT_STOCK_ID
                                     , aLocationId              => tplBatchValues.STM_PRODUCT_LOCATION_ID
                                     , aRejectStockId           => tplBatchValues.STM_REJECT_STOCK_ID
                                     , aRejectLocationId        => tplBatchValues.STM_REJECT_LOCATION_ID
                                     , aCompoStockId            => tplBatchValues.STM_COMPO_STOCK_ID
                                     , aCompoLocationId         => tplBatchValues.STM_COMPO_LOCATION_ID
                                     , aCompoRejectStockId      => tplBatchValues.STM_COMPO_STOCK_ID
                                     , aCompoRejectLocationId   => tplBatchValues.STM_COMPO_LOCATION_ID
                                     , aDate                    => tplBatchValues.BRC_DATE
                                     , BatchBalance             => tplBatchValues.BRC_BATCH_BALANCE
                                     , AnswerYesAllQuestions    => 1
                                     , ReturnCompoIsScrap       => vReturnCompoIsScrap
                                     , aReleaseBatch            => 1
                                     , ioAutoInitCharact        => liAutoInitCharact
                                     , aResult                  => vResult
                                      );

            if vResult <> FAL_BATCH_FUNCTIONS.rtOkFinished then
              -- On spécifie que l'erreur s'est produite lors de l'appel de la
              -- réception et qu'il ne faut pas mettre à jour le statut par la suite
              vSqlMsg  := 'C_LOT_RECEPT_ERROR';

              -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
              update FAL_BATCH_RECEPTION
                 set BRC_SELECTION = 0
                   , C_BRC_STATUS = bsReceptError
                   , BRC_ERROR_MESSAGE = null
               where FAL_BATCH_RECEPTION_ID = tplBatchValues.FAL_BATCH_RECEPTION_ID;
            end if;
          end if;
        exception
          when others then
            -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
            vSqlMsg  :=
               PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la réception du lot :') || chr(13) || chr(10)
               || DBMS_UTILITY.FORMAT_ERROR_STACK;
        end;

        if vSqlMsg is null then
          begin
            -- Execution de la procédure stockée de post-traitement
            if vBRC_DETAIL_AFTER_PROC is not null then
              execute immediate 'begin :Result :=  ' || vBRC_DETAIL_AFTER_PROC || '(:FAL_BATCH_RECEPTION_ID); end;'
                          using out vProcResult, in tplBatchValues.FAL_BATCH_RECEPTION_ID;

              if vProcResult < 1 then
                vSqlMsg  :=
                  PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a signalé un problème. Valeur retournée') ||
                  ' ' ||
                  to_char(vProcResult);
              end if;
            end if;
          exception
            when others then
              begin
                vProcResult  := 0;
                vSqlMsg      :=
                  PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a généré une erreur :') ||
                  chr(13) ||
                  chr(10) ||
                  DBMS_UTILITY.FORMAT_ERROR_STACK;
              end;
          end;
        end if;

        if vSqlMsg is null then
          -- Mise à jour du statut dans la table temporaire
          update FAL_BATCH_RECEPTION
             set BRC_SELECTION = 0
               , C_BRC_STATUS = bsReceived
               , BRC_ERROR_MESSAGE = null
           where FAL_BATCH_RECEPTION_ID = tplBatchValues.FAL_BATCH_RECEPTION_ID;

          -- Incrémentation du compteur de réceptions terminées sans erreur
          aSuccessfulCount  := aSuccessfulCount + 1;
        else
          -- Il ne faut mettre à jour le statut que si l'erreur s'est produite en dehors de l'appel de la réception
          if vSqlMsg <> 'C_LOT_RECEPT_ERROR' then
            -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
            update FAL_BATCH_RECEPTION
               set BRC_SELECTION = 0
                 , C_BRC_STATUS = bsReceptAborted
                 , BRC_ERROR_MESSAGE = vSqlMsg
             where FAL_BATCH_RECEPTION_ID = tplBatchValues.FAL_BATCH_RECEPTION_ID;
          end if;

          -- Remise à zero des erreurs pour l'enregistrement suivant
          vSqlMsg  := null;
        end if;
      end loop;
    end if;
  end ProcessBatchReceptions;

  /**
   * procedure DeleteBRCItems
   * Description
   *   Supprime les enregistrements temporaires déterminés par les paramètres
   */
  procedure DeleteBRCItems(aC_BRC_STATUS in FAL_BATCH_RECEPTION.C_BRC_STATUS%type, aOnlySelected in integer default 0)
  is
  begin
    -- Suppression des enregistrements séléctionnés du statut précisé
    delete from FAL_BATCH_RECEPTION
          where C_BRC_STATUS = aC_BRC_STATUS
            and (   aOnlySelected = 0
                 or BRC_SELECTION = 1);
  end DeleteBRCItems;

  /**
   * function GetBRCProfileValues
   * Description
   *   Extrait les valeurs des options d'un profil xml.
   */
  function GetBRCProfileValues(aXmlProfile xmltype)
    return TBRCOptions
  is
    vOptions TBRCOptions;
  begin
    begin
      -- Initialiser les valeurs du record sortant avec les valeurs stockées dans le xml du profil
      select nvl(extractvalue(aXmlProfile, '//BRC_MODE'), 0)
           , extractvalue(aXmlProfile, '//BRC_GLOBAL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//BRC_DETAIL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//BRC_DETAIL_AFTER_PROC')
           , extractvalue(aXmlProfile, '//BRC_SELECTION')
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(aXmlProfile, '//BRC_DATE') )
           , extractvalue(aXmlProfile, '//BRC_AUTO_BATCH_BALANCE')
           , extractvalue(aXmlProfile, '//BRC_BATCH_BALANCE')
           , extractvalue(aXmlProfile, '//BRC_C_COMPO_DEST')
           , extractvalue(aXmlProfile, '//STM_COMPO_STOCK_ID')
           , extractvalue(aXmlProfile, '//STM_COMPO_LOCATION_ID')
           , extractvalue(aXmlProfile, '//BRC_ONLY_WITH_RECEIVABLE_QTY')
           , extractvalue(aXmlProfile, '//BRC_PRODUCT_FROM')
           , extractvalue(aXmlProfile, '//BRC_PRODUCT_TO')
           , extractvalue(aXmlProfile, '//BRC_GOOD_CATEGORY_FROM')
           , extractvalue(aXmlProfile, '//BRC_GOOD_CATEGORY_TO')
           , extractvalue(aXmlProfile, '//BRC_GOOD_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//BRC_GOOD_FAMILY_TO')
           , extractvalue(aXmlProfile, '//BRC_ACCOUNTABLE_GROUP_FROM')
           , extractvalue(aXmlProfile, '//BRC_ACCOUNTABLE_GROUP_TO')
           , extractvalue(aXmlProfile, '//BRC_GOOD_LINE_FROM')
           , extractvalue(aXmlProfile, '//BRC_GOOD_LINE_TO')
           , extractvalue(aXmlProfile, '//BRC_GOOD_GROUP_FROM')
           , extractvalue(aXmlProfile, '//BRC_GOOD_GROUP_TO')
           , extractvalue(aXmlProfile, '//BRC_GOOD_MODEL_FROM')
           , extractvalue(aXmlProfile, '//BRC_GOOD_MODEL_TO')
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(aXmlProfile, '//BRC_OPEN__DTE_FROM') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(aXmlProfile, '//BRC_OPEN__DTE_TO') )
           , extractvalue(aXmlProfile, '//BRC_JOB_PROGRAM_FROM')
           , extractvalue(aXmlProfile, '//BRC_JOB_PROGRAM_TO')
           , extractvalue(aXmlProfile, '//BRC_ORDER_FROM')
           , extractvalue(aXmlProfile, '//BRC_ORDER_TO')
           , extractvalue(aXmlProfile, '//BRC_C_PRIORITY_FROM')
           , extractvalue(aXmlProfile, '//BRC_C_PRIORITY_TO')
           , extractvalue(aXmlProfile, '//BRC_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//BRC_FAMILY_TO')
           , extractvalue(aXmlProfile, '//BRC_RECORD_FROM')
           , extractvalue(aXmlProfile, '//BRC_RECORD_TO')
        into vOptions
        from dual;
    exception
      when others then
        raise_application_error(-20801, PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant l''extraction des valeurs du profil!') );
    end;

    return vOptions;
  end GetBRCProfileValues;
end FAL_BATCH_RECEPTION_FCT;
