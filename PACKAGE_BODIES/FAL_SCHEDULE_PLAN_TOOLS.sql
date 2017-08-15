--------------------------------------------------------
--  DDL for Package Body FAL_SCHEDULE_PLAN_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_SCHEDULE_PLAN_TOOLS" 
is
  /**
  * Description
  *   Lie une gamme opératoire à un bien et une nomenclature (GCO_COMPL_DATA_MANUFACTURE)
  */
  procedure LinkSchedulePlanWithGood(
    aGoodId         GCO_GOOD.GCO_GOOD_ID%type
  , aSchedulePlanId FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  , aNomenclatureId PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type default null
  , aSourceGoodId   GCO_GOOD.GCO_GOOD_ID%type
  )
  is
    nomId         PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    sourceNomId   PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    sourceComplId GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;
    noSourceCompl boolean                                                         := false;

    cursor crNomenclature(cGoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   PPS_NOMENCLATURE_ID
          from PPS_NOMENCLATURE
         where GCO_GOOD_ID = cGoodID
           and C_TYPE_NOM = '2'
      order by NOM_DEFAULT desc;

    cursor crComplDataSource(cSourceGoodID GCO_GOOD.GCO_GOOD_ID%type, cSourceNomId PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    is
      select   GCO_COMPL_DATA_MANUFACTURE_ID
          from GCO_COMPL_DATA_MANUFACTURE CDM
         where GCO_GOOD_ID = cSourceGoodId
           and PPS_NOMENCLATURE_ID = cSourceNomId
      order by CMA_DEFAULT desc;

    cma_exists    number;
  begin
    if aNomenclatureId is null then
      open crNomenclature(aGoodId);

      fetch crNomenclature
       into nomId;

      close crNomenclature;
    else
      nomId  := aNomenclatureId;
    end if;

    -- si une nomenclature a été trouvée ou passée en paramètre
    if nomId is not null then
      if aSourceGoodId is not null then
        open crNomenclature(aSourceGoodId);

        fetch crNomenclature
         into sourceNomId;

        close crNomenclature;

        open crComplDataSource(aSourceGoodId, sourceNomId);

        fetch crComplDataSource
         into sourceComplId;

        close crComplDataSource;

        if sourceComplId is not null then
          begin
            select GCO_COMPL_DATA_MANUFACTURE_ID
              into cma_exists
              from GCO_COMPL_DATA_MANUFACTURE
             where GCO_GOOD_ID = aGoodId
               and nvl(DIC_FAB_CONDITION_ID, '-1') in(select nvl(DIC_FAB_CONDITION_ID, '-1')
                                                        from GCO_COMPL_DATA_MANUFACTURE
                                                       where GCO_COMPL_DATA_MANUFACTURE_ID = sourceComplId);
          exception
            when others then
              cma_exists  := 0;
          end;

          if cma_exists = 0 then
            insert into GCO_COMPL_DATA_MANUFACTURE
                        (GCO_COMPL_DATA_MANUFACTURE_ID
                       , C_QTY_SUPPLY_RULE
                       , C_TIME_SUPPLY_RULE
                       , DIC_UNIT_OF_MEASURE_ID
                       , STM_STOCK_ID
                       , STM_LOCATION_ID
                       , GCO_SUBSTITUTION_LIST_ID
                       , GCO_GOOD_ID
                       , GCO_QUALITY_PRINCIPLE_ID
                       , CDA_COMPLEMENTARY_REFERENCE
                       , CDA_COMPLEMENTARY_EAN_CODE
                       , CDA_SHORT_DESCRIPTION
                       , CDA_LONG_DESCRIPTION
                       , CDA_FREE_DESCRIPTION
                       , CDA_COMMENT
                       , CDA_NUMBER_OF_DECIMAL
                       , CDA_CONVERSION_FACTOR
                       , A_DATECRE
                       , A_IDCRE
                       , CMA_AUTOMATIC_GENERATING_PROP
                       , CMA_ECONOMICAL_QUANTITY
                       , CMA_FIXED_DELAY
                       , CMA_MANUFACTURING_DELAY
                       , CMA_PERCENT_TRASH
                       , CMA_FIXED_QUANTITY_TRASH
                       , CMA_PERCENT_WASTE
                       , CMA_FIXED_QUANTITY_WASTE
                       , CMA_QTY_REFERENCE_LOSS
                       , FAL_SCHEDULE_PLAN_ID
                       , PPS_OPERATION_PROCEDURE_ID
                       , CMA_LOT_QUANTITY
                       , CMA_PLAN_NUMBER
                       , CMA_PLAN_VERSION
                       , CMA_MULTIMEDIA_PLAN
                       , PPS_NOMENCLATURE_ID
                       , DIC_FAB_CONDITION_ID
                       , CMA_DEFAULT
                       , CMA_SCHEDULE_TYPE
                       , DIC_COMPLEMENTARY_DATA_ID
                       , PPS_RANGE_ID
                       , CDA_FREE_ALPHA_1
                       , CDA_FREE_ALPHA_2
                       , CDA_FREE_DEC_1
                       , CDA_FREE_DEC_2
                       , C_ECONOMIC_CODE
                       , CMA_SHIFT
                       , CMA_FIX_DELAY
                       , CMA_MODULO_QUANTITY
                       , CMA_AUTO_RECEPT
                       , CDA_COMPLEMENTARY_UCC14_CODE
                        )
              select GetNewId
                   , C_QTY_SUPPLY_RULE
                   , C_TIME_SUPPLY_RULE
                   , DIC_UNIT_OF_MEASURE_ID
                   , STM_STOCK_ID
                   , STM_LOCATION_ID
                   , GCO_SUBSTITUTION_LIST_ID
                   , aGoodId
                   , GCO_QUALITY_PRINCIPLE_ID
                   , CDA_COMPLEMENTARY_REFERENCE
                   , CDA_COMPLEMENTARY_EAN_CODE
                   , CDA_SHORT_DESCRIPTION
                   , CDA_LONG_DESCRIPTION
                   , CDA_FREE_DESCRIPTION
                   , CDA_COMMENT
                   , CDA_NUMBER_OF_DECIMAL
                   , CDA_CONVERSION_FACTOR
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                   , CMA_AUTOMATIC_GENERATING_PROP
                   , CMA_ECONOMICAL_QUANTITY
                   , CMA_FIXED_DELAY
                   , CMA_MANUFACTURING_DELAY
                   , CMA_PERCENT_TRASH
                   , CMA_FIXED_QUANTITY_TRASH
                   , CMA_PERCENT_WASTE
                   , CMA_FIXED_QUANTITY_WASTE
                   , CMA_QTY_REFERENCE_LOSS
                   , aSchedulePlanId
                   , PPS_OPERATION_PROCEDURE_ID
                   , CMA_LOT_QUANTITY
                   , CMA_PLAN_NUMBER
                   , CMA_PLAN_VERSION
                   , CMA_MULTIMEDIA_PLAN
                   , nomId
                   , DIC_FAB_CONDITION_ID
                   , CMA_DEFAULT
                   , CMA_SCHEDULE_TYPE
                   , DIC_COMPLEMENTARY_DATA_ID
                   , PPS_RANGE_ID
                   , CDA_FREE_ALPHA_1
                   , CDA_FREE_ALPHA_2
                   , CDA_FREE_DEC_1
                   , CDA_FREE_DEC_2
                   , C_ECONOMIC_CODE
                   , CMA_SHIFT
                   , CMA_FIX_DELAY
                   , CMA_MODULO_QUANTITY
                   , CMA_AUTO_RECEPT
                   , CDA_COMPLEMENTARY_UCC14_CODE
                from GCO_COMPL_DATA_MANUFACTURE
               where GCO_COMPL_DATA_MANUFACTURE_ID = sourceComplId;
          else
            update GCO_COMPL_DATA_MANUFACTURE
               set GCO_GOOD_ID = aGoodId
                 , A_DATECRE = sysdate
                 , A_IDCRE = PCS.PC_I_LIB_SESSION.GetUserIni
                 , FAL_SCHEDULE_PLAN_ID = aSchedulePlanId
                 , PPS_NOMENCLATURE_ID = NomId
             where GCO_COMPL_DATA_MANUFACTURE_ID = cma_exists;
          end if;

          update GCO_GOOD
             set GCO_DATA_MANUFACTURE = 1
           where GCO_GOOD_ID = aGoodId;
        else
          noSourceCompl  := true;
        end if;
      end if;

      -- si il n'y a pas de bien source ou si le bien source n'a pas de données complémentaires de fabrication
      if    aSourceGoodId is null
         or noSourceCompl then
        -- Recherche d'une donnée complémentaire existante
        begin
          select GCO_COMPL_DATA_MANUFACTURE_ID
            into cma_exists
            from GCO_COMPL_DATA_MANUFACTURE
           where GCO_GOOD_ID = aGoodId;
        exception
          when others then
            cma_exists  := 0;
        end;

        -- Insertion s'il n'en existe pas
        if cma_exists = 0 then
          insert into GCO_COMPL_DATA_MANUFACTURE
                      (GCO_COMPL_DATA_MANUFACTURE_ID
                     , DIC_FAB_CONDITION_ID
                     , C_QTY_SUPPLY_RULE
                     , C_TIME_SUPPLY_RULE
                     , C_ECONOMIC_CODE
                     , DIC_UNIT_OF_MEASURE_ID
                     , GCO_GOOD_ID
                     , PPS_NOMENCLATURE_ID
                     , FAL_SCHEDULE_PLAN_ID
                     , CDA_NUMBER_OF_DECIMAL
                     , CMA_LOT_QUANTITY
                     , CMA_MANUFACTURING_DELAY
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , (select min(DIC_FAB_CONDITION_ID)
                          from DIC_FAB_CONDITION)
                     , '1'   -- C_QTY_SUPPLY_RULE
                     , '1'   -- C_TIME_SUPPLY_RULE
                     , '1'   -- C_ECONOMIC_CODE
                     , (select DIC_UNIT_OF_MEASURE_ID
                          from GCO_GOOD
                         where GCO_GOOD_ID = aGoodId)
                     , aGoodId
                     , nomId
                     , aSchedulePlanId
                     , (select GOO_NUMBER_OF_DECIMAL
                          from GCO_GOOD
                         where GCO_GOOD_ID = aGoodId)
                     , 1   -- CMA_LOT_QUANTITY
                     , 1   -- CMA_MANUFACTURING_DELAY
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        else
          -- Mise à jour s'il en existe déjà une
          update GCO_COMPL_DATA_MANUFACTURE
             set GCO_GOOD_ID = aGoodId
               , A_DATECRE = sysdate
               , A_IDCRE = PCS.PC_I_LIB_SESSION.GetUserIni
               , FAL_SCHEDULE_PLAN_ID = aSchedulePlanId
               , PPS_NOMENCLATURE_ID = NomId
           where GCO_COMPL_DATA_MANUFACTURE_ID = cma_exists;
        end if;

        update GCO_GOOD
           set GCO_DATA_MANUFACTURE = 1
         where GCO_GOOD_ID = aGoodId;
      end if;
    end if;
  end LinkSchedulePlanWithGood;

  /**
  * function GetDefaultSchedulePlan
  * Description
  *   retourne la gamme opératoire par défaut d'un bien
  * @created fp 08.11.2004
  * @lastUpdate
  * @public
  * @param aGoodId
  * @return
  */
  function GetDefaultSchedulePlan(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  is
    result FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type;
  begin
    select FAL_SCHEDULE_PLAN_ID
      into result
      from GCO_COMPL_DATA_MANUFACTURE
     where GCO_GOOD_ID = aGoodId
       and CMA_DEFAULT = 1;

    return result;
  exception
    when no_data_found then
      return null;
  end GetDefaultSchedulePlan;

  /**
  * Description
  *   Copie d'une gamme opératoire
  */
  procedure DuplicateSchedulePlan(
    aSourceSchedulePlanId in     FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  , aNewReference         in     FAL_SCHEDULE_PLAN.SCH_REF%type
  , aNewSchedulePlanId    out    FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  )
  is
  begin
    FAL_PRC_SCHEDULE_PLAN.duplicateSchedulePlan(iSrcSchedulePlanID   => aSourceSchedulePlanId, iNewRef => aNewReference
                                              , oNewSchedulePlanID   => aNewSchedulePlanId);
  end DuplicateSchedulePlan;

  procedure DupOperationOfGammeOnGamme(
    inFAL_SCHEDULE_PLAN_ORG in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  , inFAL_SCHEDULE_PLAN_FIN in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  )
  is
  begin
    FAL_PRC_SCHEDULE_PLAN.dupOperationOfGammeOnGamme(iSrcSchedulePlanID => inFAL_SCHEDULE_PLAN_ORG, iNewSchedulePlanID => inFAL_SCHEDULE_PLAN_FIN);
  end DupOperationOfGammeOnGamme;

  -- Procédure d'insertion de l'historique
  procedure INSERT_HISTO(
    aFAL_SCHEDULE_PLAN_ID FAL_SCHEDULE_PLAN_HISTO.FAL_SCHEDULE_PLAN_ID%type
  , aSCS_STEP_NUMBER      FAL_SCHEDULE_PLAN_HISTO.SCS_STEP_NUMBER%type
  , aFAL_TASK_ID          FAL_SCHEDULE_PLAN_HISTO.FAL_TASK_ID%type
  , aC_HISTO_STATUS       FAL_SCHEDULE_PLAN_HISTO.C_HISTO_STATUS%type
  , aHIS_OLD_VALUE        FAL_SCHEDULE_PLAN_HISTO.HIS_OLD_VALUE%type
  , aHIS_NEW_VALUE        FAL_SCHEDULE_PLAN_HISTO.HIS_NEW_VALUE%type
  )
  is
  begin
    insert into FAL_SCHEDULE_PLAN_HISTO
                (FAL_SCHEDULE_PLAN_HISTO_ID
               , FAL_SCHEDULE_PLAN_ID
               , SCS_STEP_NUMBER
               , FAL_TASK_ID
               , C_HISTO_STATUS
               , HIS_OLD_VALUE
               , HIS_NEW_VALUE
               , A_IDCRE
               , A_DATECRE
                )
         values (GetNewId
               , aFAL_SCHEDULE_PLAN_ID
               , aSCS_STEP_NUMBER
               , aFAL_TASK_ID
               , aC_HISTO_STATUS
               , aHIS_OLD_VALUE
               , aHIS_NEW_VALUE
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );
  end;

  /**
  * function GetHistoUpdatedData
  * Description
  *   Renvoi la valeur modifiée pour la gamme opératoire
  */
  function GetHistoUpdatedData(iHistoStatus in FAL_SCHEDULE_PLAN_HISTO.C_HISTO_STATUS%type, iValue in FAL_SCHEDULE_PLAN_HISTO.HIS_OLD_VALUE%type)
    return varchar2
  is
    lvTextValue FAL_SCHEDULE_PLAN_HISTO.HIS_OLD_VALUE%type;
  begin
    lvTextValue  := iValue;

    -- 04 - Modif. Opération
    if iHistoStatus = '04' then
      -- Valeur : FAL_TASK_ID
      select max(TAS_REF)
        into lvTextValue
        from FAL_TASK
       where FAL_TASK_ID = iValue;
    -- 05 - Modif. Type de lien
    elsif iHistoStatus = '05' then
      -- Valeur : C_OPERATION_TYPE
      lvTextValue  := iValue || ' - ' || COM_FUNCTIONS.GetDescodeDescr(aName => 'C_OPERATION_TYPE', aValue => iValue);
    -- 06 - Modif. Procédure opératoire
    -- 07 - Modif. Procédure de contrôle
    elsif iHistoStatus in('06', '07') then
      -- Valeur : PPS_OPERATION_PROCEDURE_ID
      select max(OPP_REFERENCE)
        into lvTextValue
        from PPS_OPERATION_PROCEDURE
       where PPS_OPERATION_PROCEDURE_ID = iValue;
    -- 08 - Modif. Outil 1
    -- 09 - Modif. Outil 2
    -- 12 - Modif. Service
    -- 31 - Modif. Outil 3 à 43 - Modif. Outil 15
    elsif    iHistoStatus in('08', '09', '12')
          or (iHistoStatus between '31' and '43') then
      -- Valeur : GCO_GOOD_ID (PPS_TOOLS ou GCO_SERVICE)
      select max(GOO_MAJOR_REFERENCE)
        into lvTextValue
        from GCO_GOOD
       where GCO_GOOD_ID = iValue;
    -- 10 - Modif. Atelier
    -- 21 - Modification de l'opérateur
    elsif iHistoStatus in('10', '21') then
      -- Valeur : FAL_FACTORY_FLOOR_ID
      select max(FAC_REFERENCE)
        into lvTextValue
        from FAL_FACTORY_FLOOR
       where FAL_FACTORY_FLOOR_ID = iValue;
    -- 11 - Modif. Atelier
    elsif iHistoStatus = '11' then
      -- Valeur : PAC_SUPPLIER_PARTNER_ID
      select max(PER_NAME)
        into lvTextValue
        from PAC_PERSON
       where PAC_PERSON_ID = iValue;
    -- 47 - Modification code planification
    elsif iHistoStatus = '47' then
      -- Valeur : C_SCHEDULE_PLANNING
      lvTextValue  := iValue || ' - ' || COM_FUNCTIONS.GetDescodeDescr(aName => 'C_SCHEDULE_PLANNING', aValue => iValue);
    end if;

    return lvTextValue;
  end GetHistoUpdatedData;
end;
