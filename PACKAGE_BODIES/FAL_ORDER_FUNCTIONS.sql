--------------------------------------------------------
--  DDL for Package Body FAL_ORDER_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ORDER_FUNCTIONS" 
is
  /**
  * function GetNewOrdRef
  * Description
  *   Obtention d'une nouvelle référence d'ordre
  * @author CLE
  * @param      aFAL_JOB_PROGRAM_ID Programme d'apartenance de l'ordre
  * @param      aStartValue         Référence de l'ordre de départ
  * @return     Nouvel référence de l'ordre en fonction de la config FAL_ORDER_NUMBERING
  */
  function GetNewOrdRef(aFAL_JOB_PROGRAM_ID fal_job_program.fal_job_program_id%type, aStartValue integer default null)
    return fal_order.ord_ref%type
  is
    MaxOrdRef            fal_order.ord_ref%type;
    CfgFalOrderNumbering integer;
  begin
    CfgFalOrderNumbering  := to_number(PCS.PC_CONFIG.GetConfig('FAL_ORDER_NUMBERING') );

    if aStartValue is null then
      -- Sélection du plus grand ORD_REF des tables FAL_ORDER et FAL_ORDER_HIST
      select greatest( (select nvl(max(ORD_REF), 0)
                          from FAL_ORDER
                         where FAL_JOB_PROGRAM_ID = aFAL_JOB_PROGRAM_ID), (select nvl(max(ORD_REF), 0)
                                                                             from FAL_ORDER_HIST
                                                                            where FAL_JOB_PROGRAM_HIST_ID = aFAL_JOB_PROGRAM_ID) )
        into MaxOrdRef
        from dual;
    else
      MaxOrdRef  := aStartValue;
    end if;

    -- Incrémentation à la dizaine supérieure la plus proche
    if (MaxOrdRef mod CfgFalOrderNumbering) <> 0 then
      MaxOrdRef  := (round(MaxOrdRef / CfgFalOrderNumbering) * CfgFalOrderNumbering) + CfgFalOrderNumbering;
    else
      MaxOrdRef  := MaxOrdRef + CfgFalOrderNumbering;
    end if;

    if MaxOrdRef >= power(10, to_number(PCS.PC_CONFIG.GetConfig('FAL_ORD_REF_LENGTH') ) ) then
      raise_application_error(-20001, PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur de la configuration FAL_ORD_REF_LENGTH n''est pas assez élevée !') );
    end if;

    return MaxOrdRef;
  end;

  /**
  * procedure InsertOrder
  * Description
  *   Création d'un nouvel ordre de fabrication
  * @author CLE
  * @lastUpdate
  * @param      aFAL_ORDER_ID       Id de l'ordre
  * @param      aFAL_JOB_PROGRAM_ID Programme d'apartenance de l'ordre
  * @param      aORD_REF            Référence de l'ordre
  * @param      aGCO_GOOD_ID        Bien
  * @param      aDOC_RECORD_ID      Dossier
  * @param      aC_FAB_TYPE         Type de fabrication
  * @param      aORD_OSHORT_DESCR   Description courte
  * @param      aORD_OLONG_DESCR    Description longue
  * @param      aORD_OFREE_DESCR    Description libre
  * @return     True si pas de problème à la création de l'ordre, False sinon
  */
  function InsertOrder(
    aFAL_ORDER_ID            fal_order.fal_order_id%type
  , aFAL_JOB_PROGRAM_ID      fal_order.fal_job_program_id%type
  , aORD_REF                 fal_order.ord_ref%type
  , aGCO_GOOD_ID             fal_order.gco_good_id%type
  , aDOC_RECORD_ID           fal_order.doc_record_id%type
  , aC_FAB_TYPE              fal_order.C_FAB_TYPE%type
  , aPAC_SUPPLIER_PARTNER_ID fal_order.PAC_SUPPLIER_PARTNER_ID%type default null
  , aORD_OSHORT_DESCR        fal_order.ORD_OSHORT_DESCR%type default null
  , aORD_OLONG_DESCR         fal_order.ORD_OLONG_DESCR%type default null
  , aORD_OFREE_DESCR         fal_order.ORD_OFREE_DESCR%type default null
  )
    return boolean
  is
    aGOO_MAJOR_REFERENCE     gco_good.goo_major_reference%type;
    aGOO_SECONDARY_REFERENCE gco_good.goo_secondary_reference%type;
    aDES_SHORT_DESCRIPTION   gco_description.des_short_description%type;
    aDES_FREE_DESCRIPTION    gco_description.des_free_description%type;
    aDES_LONG_DESCRIPTION    gco_description.des_long_description%type;
  begin
    FAL_TOOLS.GetMajorSecShortFreeLong(aGCO_GOOD_ID
                                     , aGOO_MAJOR_REFERENCE
                                     , aGOO_SECONDARY_REFERENCE
                                     , aDES_SHORT_DESCRIPTION
                                     , aDES_FREE_DESCRIPTION
                                     , aDES_LONG_DESCRIPTION
                                      );

    insert into FAL_ORDER
                (FAL_ORDER_ID
               , FAL_JOB_PROGRAM_ID
               , ORD_REF
               , C_ORDER_STATUS
               , DOC_RECORD_ID
               , GCO_GOOD_ID
               , PAC_SUPPLIER_PARTNER_ID
               , ORD_SECOND_REF
               , ORD_PSHORT_DESCR
               , ORD_PLONG_DESCR
               , ORD_PFREE_DESCR
               , ORD_OSHORT_DESCR
               , ORD_OLONG_DESCR
               , ORD_OFREE_DESCR
               , ORD_PLANNED_QTY
               , ORD_STILL_TO_RELEASE_QTY
               , ORD_OPENED_QTY
               , ORD_MAX_RELEASABLE
               , ORD_RELEASED_QTY
               , DIC_FAMILY_ID
               , C_FAB_TYPE
               , A_DATECRE
               , A_IDCRE
                )
         values (aFAL_ORDER_ID
               , aFAL_JOB_PROGRAM_ID
               , aORD_REF
               , 1   -- C_ORDER_STATUS
               , aDOC_RECORD_ID
               , aGCO_GOOD_ID
               , aPAC_SUPPLIER_PARTNER_ID
               , aGOO_SECONDARY_REFERENCE
               , aDES_SHORT_DESCRIPTION
               , aDES_LONG_DESCRIPTION
               , aDES_FREE_DESCRIPTION
               , aORD_OSHORT_DESCR
               , aORD_OLONG_DESCR
               , aORD_OFREE_DESCR
               , 0   -- ORD_PLANNED_QTY
               , 0   -- ORD_STILL_TO_RELEASE_QTY
               , 0   -- ORD_OPENED_QTY
               , 0   -- ORD_MAX_RELEASABLE
               , 0   -- ORD_RELEASED_QTY
               , (select DIC_FAMILY_ID
                    from FAL_JOB_PROGRAM
                   where FAL_JOB_PROGRAM_ID = aFAL_JOB_PROGRAM_ID)
               , nvl(aC_FAB_TYPE, (select C_FAB_TYPE
                                     from FAL_JOB_PROGRAM
                                    where FAL_JOB_PROGRAM_ID = aFAL_JOB_PROGRAM_ID) )
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return true;
  exception
    when dup_val_on_index then
      return false;
  end;

  /**
  * function CreateManufactureOrder
  * Description
  *   Création d'un nouvel ordre de fabrication
  * @created CLE
  * @lastUpdate
  * @public
  * @param      aFAL_JOB_PROGRAM_ID Programme d'apartenance de l'ordre
  * @param      aGCO_GOOD_ID        Bien
  * @param      aDOC_RECORD_ID      Dossier
  * @param      aC_FAB_TYPE         Type de fabrication
  * @param      aORD_OSHORT_DESCR   Description courte
  * @param      aORD_OLONG_DESCR    Description longue
  * @param      aORD_OFREE_DESCR    Description libre
  * @return     Id de l'ordre créé
  */
  function CreateManufactureOrder(
    aFAL_JOB_PROGRAM_ID      fal_job_program.fal_job_program_id%type
  , aGCO_GOOD_ID             fal_order.gco_good_id%type
  , aDOC_RECORD_ID           fal_order.doc_record_id%type default null
  , aC_FAB_TYPE              fal_order.C_FAB_TYPE%type default '0'
  , aPAC_SUPPLIER_PARTNER_ID fal_order.PAC_SUPPLIER_PARTNER_ID%type default null
  , aORD_OSHORT_DESCR        fal_order.ORD_OSHORT_DESCR%type default null
  , aORD_OLONG_DESCR         fal_order.ORD_OLONG_DESCR%type default null
  , aORD_OFREE_DESCR         fal_order.ORD_OFREE_DESCR%type default null
  )
    return fal_order.fal_order_id%type
  is
    aFAL_ORDER_ID fal_order.fal_order_id%type;
    aORD_REF      fal_order.ord_ref%type;
  begin
    aFAL_ORDER_ID := GetNewId;
    aORD_REF  := null;

    loop
      aORD_REF  := GetNewOrdRef(aFAL_JOB_PROGRAM_ID, aORD_REF);
      exit when InsertOrder(aFAL_ORDER_ID
                          , aFAL_JOB_PROGRAM_ID
                          , aORD_REF
                          , aGCO_GOOD_ID
                          , aDOC_RECORD_ID
                          , aC_FAB_TYPE
                          , aPAC_SUPPLIER_PARTNER_ID
                          , aORD_OSHORT_DESCR
                          , aORD_OLONG_DESCR
                          , aORD_OFREE_DESCR
                           ) = true;
    end loop;

    return aFAL_ORDER_ID;
  end;

  /**
  * procedure CreateManufactureOrder
  * Description
  *   Création d'un nouvel ordre de fabrication
  * @created CLE
  * @lastUpdate
  * @public
  * @param      aFAL_JOB_PROGRAM_ID Programme d'apartenance de l'ordre
  * @param      aGCO_GOOD_ID        Bien
  * @param      aDOC_RECORD_ID      Dossier
  * @param      aC_FAB_TYPE         Type de fabrication
  * @param      aFAL_ORDER_ID       paramètre de sortie Id de l'ordre créé
  */
  procedure CreateManufactureOrder(
    aFAL_JOB_PROGRAM_ID             fal_job_program.fal_job_program_id%type
  , aGCO_GOOD_ID                    fal_order.gco_good_id%type
  , aDOC_RECORD_ID                  fal_order.doc_record_id%type default null
  , aC_FAB_TYPE                     fal_order.C_FAB_TYPE%type default '0'
  , aPAC_SUPPLIER_PARTNER_ID        fal_order.PAC_SUPPLIER_PARTNER_ID%type default null
  , aFAL_ORDER_ID            in out fal_order.fal_order_id%type
  )
  is
  begin
    aFAL_ORDER_ID  := CreateManufactureOrder(aFAL_JOB_PROGRAM_ID, aGCO_GOOD_ID, aDOC_RECORD_ID, aC_FAB_TYPE, aPAC_SUPPLIER_PARTNER_ID);
  end;

  /**
  * procedure UpdateOrder
  * Description
  *   Mise à jour ordre
  * @created CLE
  * @lastUpdate
  * @public
  * @param      aFAL_ORDER_ID    Id de l'ordre à mettre à jour
  * @param      aFAL_LOT_ID      Lot appartenant à l'ordre à mettre à jour
  * @param      aC_ORDER_STATUS  Nouveau statut de l'ordre
  */
  procedure UpdateOrder(
    aFAL_ORDER_ID   FAL_ORDER.FAL_ORDER_ID%type default null
  , aFAL_LOT_ID     FAL_LOT.FAL_LOT_ID%type default null
  , aC_ORDER_STATUS FAL_ORDER.C_ORDER_STATUS%type default null
  )
  is
    aORD_END_DATE       fal_order.ord_end_date%type;
    aORD_PLANNED_QTY    fal_order.ord_planned_qty%type;
    aORD_MAX_RELEASABLE fal_order.ord_max_releasable%type;
    aORD_OPENED_QTY     fal_order.ord_opened_qty%type;
    aORD_RELEASED_QTY   fal_order.ord_released_qty%type;
    nFAL_ORDER_ID       fal_order.fal_order_id%type;
    iPlannedBatches     integer;
    iLaunchedBatches    integer;
    iBalancedBatches    integer;
    iArchivedBatches    integer;
  begin
    begin
      select   sum(LOT_INPROD_QTY)
             , sum(LOT_MAX_RELEASABLE_QTY)
             , sum(LOT_RELEASE_QTY)
             , sum(LOT_RELEASED_QTY)
             , nvl(FAL_ORDER_ID, aFAL_ORDER_ID)
          into aORD_PLANNED_QTY
             , aORD_MAX_RELEASABLE
             , aORD_OPENED_QTY
             , aORD_RELEASED_QTY
             , nFAL_ORDER_ID
          from FAL_LOT LOT
         where (    nvl(aFAL_ORDER_ID, 0) <> 0
                and FAL_ORDER_ID = aFAL_ORDER_ID)
            or (    nvl(aFAL_ORDER_ID, 0) = 0
                and FAL_ORDER_ID = (select max(FAL_ORDER_ID)
                                      from FAL_LOT
                                     where FAL_LOT_ID = aFAL_LOT_ID) )
      group by FAL_ORDER_ID;
    exception
      when no_data_found then
        begin
          aORD_PLANNED_QTY     := 0;
          aORD_MAX_RELEASABLE  := 0;
          aORD_OPENED_QTY      := 0;
          aORD_RELEASED_QTY    := 0;
          nFAL_ORDER_ID        := aFAL_ORDER_ID;
        end;
    end;

    begin
      select PlannedBatches.numPlanned
           , LaunchedBatches.NumLaunched
           , BalancedBatches.NumBalanced
           , ArchivedBatches.numArchived
        into iPlannedBatches
           , iLaunchedBatches
           , iBalancedBatches
           , iArchivedBatches
        from (select count(*) as numPlanned
                from FAL_LOT
               where FAL_ORDER_ID = nFAL_ORDER_ID
                 and C_LOT_STATUS = '1') PlannedBatches
           , (select count(*) as numLaunched
                from FAL_LOT
               where FAL_ORDER_ID = nFAL_ORDER_ID
                 and C_LOT_STATUS = '2') LaunchedBatches
           , (select count(*) as NumBalanced
                from FAL_LOT
               where FAL_ORDER_ID = nFAL_ORDER_ID
                 and C_LOT_STATUS in('3', '5') ) BalancedBatches
           , (select count(*) as numArchived
                from FAL_LOT
               where FAL_ORDER_ID = nFAL_ORDER_ID
                 and C_LOT_STATUS = '6') ArchivedBatches;
    exception
      when no_data_found then
        begin
          iPlannedBatches   := 0;
          iLaunchedBatches  := 0;
          iArchivedBatches  := 0;
          iBalancedBatches  := 0;
        end;
    end;

    update FAL_ORDER
       set ORD_END_DATE = (select max(LOT_PLAN_END_DTE)
                             from FAL_LOT
                            where FAL_ORDER_ID = nFAL_ORDER_ID
                              and C_LOT_STATUS in('1', '2') )
         , ORD_PLANNED_QTY = aORD_PLANNED_QTY
         , ORD_OPENED_QTY = aORD_OPENED_QTY
         , ORD_STILL_TO_RELEASE_QTY = (select sum(LOT_INPROD_QTY)
                                         from FAL_LOT
                                        where FAL_ORDER_ID = nFAL_ORDER_ID
                                          and C_LOT_STATUS = '1')
         , ORD_MAX_RELEASABLE = aORD_MAX_RELEASABLE
         , ORD_RELEASED_QTY = aORD_RELEASED_QTY
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , C_ORDER_STATUS =
             (case
                when iLaunchedBatches > 0 then '2'
                when iPlannedBatches > 0 then '1'
                when iBalancedBatches > 0 then '3'
                when iArchivedBatches > 0 then '4'
                else decode(aC_ORDER_STATUS, null, C_ORDER_STATUS, aC_ORDER_STATUS)
              end
             )
     where FAL_ORDER_ID = nFAL_ORDER_ID;
  exception
    when no_data_found then
      null;
  end;

  /**
  * Procedure DeleteOrder
  * Description
  *   Suppression d'un ordre de fabrication (s'il ne possède plus de lots)
  * @author ECA
  * @public
  * @param     aFAL_ORDER_ID   Id de l'ordre
  * @return     True si l'ordre à pu être supprimé
  */
  function DeleteOrder(aFAL_ORDER_ID FAL_ORDER.FAL_ORDER_ID%type)
    return boolean
  is
    NbLots integer;
  begin
    select count(*)
      into NbLots
      from FAL_LOT
     where FAL_ORDER_ID = aFAL_ORDER_ID;

    if NbLots = 0 then
      delete from FAL_ORDER
            where FAL_ORDER_ID = aFAL_ORDER_ID;

      return true;
    else
      return false;
    end if;
  exception
    when others then
      return false;
  end;

  /**
  * Procedure DeleteOrderCascade
  * Description
  *   Suppression d'un ordre de fabrication, et des lots qu'il comporte
  * @author ECA
  * @public
  * @param     aFAL_ORDER_ID   Id de l'ordre
  */
  procedure DeleteOrderCascade(aFAL_ORDER_ID FAL_ORDER.FAL_ORDER_ID%type, aErrorCode in out varchar2)
  is
    cursor crBatches
    is
      select fal_lot_id
        from fal_lot
       where fal_order_id = aFAL_ORDER_ID;

    blnDeleted boolean;
  begin
    for tplBatches in crBatches loop
      FAL_BATCH_FUNCTIONS.DeleteBatch(tplBatches.FAL_LOT_ID);
    end loop;

    blnDeleted  := DeleteOrder(aFAL_ORDER_ID);
  exception
    when FAL_BATCH_FUNCTIONS.excNotPlannedBatch then
      aErrorCode  := 'excNotPlannedBatch';
    when FAL_BATCH_FUNCTIONS.excUsedInTracablity then
      aErrorCode  := 'excUsedInTracablity';
    when FAL_BATCH_FUNCTIONS.excUnknownBatch then
      aErrorCode  := 'excUnknownBatch';
    when others then
      raise;
  end;

  /**
  * function GetOrderRef
  * Description
  *   look for Order reference with given FAL_ORDER_ID
  * @created eca
  * @lastUpdate
  * @public
  * @param iFalOrderID : ID de l'ordre
  * @return
  */
  function GetOrderRef(iFalOrderID in number)
    return FAL_ORDER.ORD_REF%type
  is
    lResult FAL_ORDER.ORD_REF%type;
  begin
    select ORD_REF
      into lResult
      from FAL_ORDER
     where FAL_ORDER_ID = iFalOrderID;

    return lResult;
  exception
    when no_data_found then
      return null;
  end;
end;
