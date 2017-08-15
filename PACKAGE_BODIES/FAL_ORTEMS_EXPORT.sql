--------------------------------------------------------
--  DDL for Package Body FAL_ORTEMS_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ORTEMS_EXPORT" 
is
  cOrtAdjusting       constant integer      := to_number(PCS.PC_CONFIG.GetConfig('FAL_ORT_ADJUSTING') );
  bWorkInMinutes      constant boolean      :=(PCS.PC_Config.GetConfig('PPS_WORK_UNIT') = 'M');
  cUseOpenTimeMachine constant boolean      :=(PCS.PC_Config.GetConfig('FAL_USE_OPEN_TIME_MACHINE') <> '0');
  cPpsRateDay         constant integer      := to_number(PCS.PC_CONFIG.GetConfig('PPS_RATE_DAY') );
  cInitLatestEndDate  constant integer      := to_number(PCS.PC_CONFIG.GetConfig('FAL_ORT_INIT_LATEST_END_DATE') );
  cSubcField          constant varchar2(30) := PCS.PC_Config.GetConfig('FAL_ORT_SUBCONTRACT_FIELD');
  cOrtSupplierDelay   constant integer      := to_number(PCS.PC_CONFIG.GetConfig('FAL_ORT_SUPPLIER_DELAY') );

  /**
  * procedure : ExecuteProc
  * Description : Exécution de la procédure passée en paramètre
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param     aSchemaName : Nom du schéma Ortems
  * @param     aProcName   : Nom de la procédure à exécuter
  */
  procedure ExecuteProc(aSchemaName varchar2, aProcName varchar2)
  is
  begin
    if aProcName is not null then
      execute immediate ' begin ' || aProcName || '(:aSchemaName); end;'
                  using aSchemaName;
    end if;
  end;

/******************************************************************************************

                               EXPORTATION DES DONNEES STATIQUES

******************************************************************************************/
  function IsMachine(aFAL_FACTORY_FLOOR_ID number)
    return boolean
  is
    result number;
  begin
    select nvl(FAC_IS_MACHINE, 0)
      into result
      from FAL_FACTORY_FLOOR
     where FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID;

    return(result = 1);
  end;

/******************************************************************************************
                          PROCESSUS  création des Zones (B.ZONE)
******************************************************************************************/
  procedure Creation_Zone(aSchemaName varchar2, FacReference varchar2)
  is
    vQuery varchar2(32000);
  begin
    vQuery  := ' insert into ' || aSchemaName || '.B_ZONE (NOZONE, LIBZONE) values(:vNOZONE, :vLIBZONE) ';

    execute immediate vQuery
                using trim(substr(FacReference, 1, 10) ), trim(substr(FacReference, 1, 15) );
  exception
    when dup_val_on_index then
      null;
  end;

/******************************************************************************************
                    PROCESSUS  création des Sections (B.SECT)
******************************************************************************************/
  procedure Creation_Section(aSchemaName varchar2, aSection FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID%type)
  is
    vQuery varchar2(32000);
  begin
    vQuery  :=
      ' insert into ' ||
      aSchemaName ||
      '.B_SECT             ' ||
      '       (CODESECTI   ' ||
      '      , DESIGSECT)  ' ||
      ' values(:vCODESECTI ' ||
      '      , :vDESIGSECT)';

    execute immediate vQuery
                using trim(substr(aSection, 1, 5) ), aSection;
  exception
    when dup_val_on_index then
      null;
  end;

  procedure PurgeTable(aSchemaName varchar2, aTableName varchar2, aSelectQuery varchar2 default null)
  is
    vQuery varchar2(32000);
  begin
    vQuery  := ' delete from ' || aSchemaName || '.' || aTableName || ' TALIAS' || aSelectQuery;

    execute immediate vQuery;
  exception
    when others then
      raise_application_error(-20000, 'Error deleting table ' || aTableName || chr(10) || DBMS_UTILITY.FORMAT_ERROR_STACK);
  end;

  /**
  * procedure deleteObsoleteData
  * Description : Suppression dans Ortems des données suivantes :
  *      - des machines hors service et des machines qui ne sont plus sur le même îlot que dans PCS
  *      - des îlots qui n’ont plus de machine (dans Ortems)
  *      - des opérateurs hors service ou non présents dans PCS
  *      - des qualifications (groupes d’opérateurs) hors service ou non présents dans PCS
  *
  * @created CLE
  * @lastUpdate
  * @public
  *
  * @param   aSchemaName : Nom du schéma Ortems
  */
  procedure deleteObsoleteData(aSchemaName varchar2)
  is
    vSelectQuery varchar2(32000);
  begin
    -- Requête de sélection ds machines à supprimer
    vSelectQuery  :=
      '     where ( not exists( ' ||
      '                   select FAL_FACTORY_FLOOR_ID ' ||
      '                     from FAL_FACTORY_FLOOR FFF1 ' ||
      '                    where trim(substr(FAC_REFERENCE, 1, 10) ) = TALIAS.MACHINE ' ||
      '                      and (nvl(FAC_IS_MACHINE, 0) = 1 or nvl(FAC_IS_BLOCK, 0) = 1)' ||
      '                      and nvl( (select trim(substr(FAC_REFERENCE, 1, 10) ) ' ||
      '                                  from FAL_FACTORY_FLOOR ' ||
      '                                 where FAL_FACTORY_FLOOR_ID = FFF1.FAL_FAL_FACTORY_FLOOR_ID) ' ||
      '                            , trim(substr(FAC_REFERENCE, 1, 10) ) ' ||
      '                             ) = TALIAS.ILOT) ' ||
      '             and not exists(select PAC_PERSON_ID ' ||
      '                              from PAC_PERSON ' ||
      '                             where trim(substr(PER_NAME, 1, 10) ) = TALIAS.MACHINE) ';

    if cSubcField is not null then
      vSelectQuery  :=
        vSelectQuery ||
        '           and not exists(select PAC_SUPPLIER_PARTNER_ID ' ||
        '                            from PAC_SUPPLIER_PARTNER ' ||
        '                           where trim(substr(' ||
        cSubcField ||
        ', 1, 10) ) = TALIAS.MACHINE) ';
    end if;

    vSelectQuery  :=
      vSelectQuery ||
      '             and MACHINE <> ''STAND-BY'' ' ||
      '            ) ' ||
      '         or MACHINE in(select trim(substr(FAC_REFERENCE, 1, 10) ) ' ||
      '                         from FAL_FACTORY_FLOOR ' ||
      '                        where (nvl(FAC_IS_MACHINE, 0) = 1 or nvl(FAC_IS_BLOCK, 0) = 1) ' ||
      '                          and FAC_OUT_OF_ORDER = 1) ' ||
      '         or ILOT in( ' ||
      '              select trim(substr(FAC_REFERENCE, 1, 10) ) ' ||
      '                from FAL_FACTORY_FLOOR ' ||
      '               where trim(substr(FAC_REFERENCE, 1, 10) ) = TALIAS.ILOT ' ||
      '                 and decode(FAC_INFINITE_FLOOR, 0, ''2'', 1, ''4'') <> (select TYPEILOT ' ||
      '                                                                          from ' ||
      aSchemaName ||
      '.B_ILOT ' ||
      '                                                                         where ILOT = TALIAS.ILOT) )';
    PurgeTable(aSchemaName, 'EFF_MACH', vSelectQuery);
    PurgeTable(aSchemaName, 'EFF_MACH2', vSelectQuery);
    PurgeTable(aSchemaName, 'EFF_QUAL_MACH', vSelectQuery);
    PurgeTable(aSchemaName, 'EFF_QUAL_MACH2', vSelectQuery);
    PurgeTable(aSchemaName, 'B_REPART', vSelectQuery);
    PurgeTable(aSchemaName, 'CHARGE_MACH', vSelectQuery);
    PurgeTable(aSchemaName, 'CHARGE_MACH2', vSelectQuery);
    PurgeTable(aSchemaName, 'B_AFOP', vSelectQuery);
    PurgeTable(aSchemaName, 'B_AFQU', vSelectQuery);
    PurgeTable(aSchemaName, 'P_CEX_MACH', vSelectQuery);
    PurgeTable(aSchemaName, 'MACH_PLAN_CAP', vSelectQuery);
    PurgeTable(aSchemaName, 'P_CEFF_MACH', vSelectQuery);
    PurgeTable(aSchemaName, 'B_MACH', vSelectQuery);
    -- Requête de sélection des îlots à supprimer
    vSelectQuery  := '     where ( select count(*) ' || '      from ' || aSchemaName || '.B_MACH ' || '     where ILOT = TALIAS.ILOT) = 0 ';
    PurgeTable(aSchemaName, 'B_ILOT', vSelectQuery);
    -- Requête de sélection des opérateurs à supprimer
    vSelectQuery  :=
      '    where not exists(select FAL_FACTORY_FLOOR_ID ' ||
      '                       from FAL_FACTORY_FLOOR FFF1 ' ||
      '                      where trim(substr(FAC_REFERENCE, 1, 10) ) = TALIAS.MATRICULE ' ||
      '                        and nvl(FAC_IS_PERSON, 0) = 1) ' ||
      '       or MATRICULE in(select trim(substr(FAC_REFERENCE, 1, 10) ) ' ||
      '                         from FAL_FACTORY_FLOOR ' ||
      '                        where nvl(FAC_IS_PERSON, 0) = 1 ' ||
      '                          and FAC_OUT_OF_ORDER = 1) ';
    PurgeTable(aSchemaName, 'B_AFOP', vSelectQuery);
    PurgeTable(aSchemaName, 'P_CEX_OPRT', vSelectQuery);
    PurgeTable(aSchemaName, 'E_OPERAT', vSelectQuery);
    PurgeTable(aSchemaName, 'E_OPERAT2', vSelectQuery);
    PurgeTable(aSchemaName, 'CHARGE_OPRT', vSelectQuery);
    PurgeTable(aSchemaName, 'CHARGE_OPRT2', vSelectQuery);
    PurgeTable(aSchemaName, 'B_OPRT', vSelectQuery);
    -- Requête de sélection des qualifications à supprimer
    vSelectQuery  :=
      '    where not exists(select FAL_FACTORY_FLOOR_ID ' ||
      '                       from FAL_FACTORY_FLOOR FFF1 ' ||
      '                      where trim(substr(FAC_REFERENCE, 1, 10) ) = TALIAS.QUALIF ' ||
      '                        and nvl(FAC_IS_OPERATOR, 0) = 1) ' ||
      '       or QUALIF in(select trim(substr(FAC_REFERENCE, 1, 10) ) ' ||
      '                         from FAL_FACTORY_FLOOR ' ||
      '                        where nvl(FAC_IS_OPERATOR, 0) = 1 ' ||
      '                          and FAC_OUT_OF_ORDER = 1) ';
    PurgeTable(aSchemaName, 'EFF_QUAL_MACH2', vSelectQuery);
    PurgeTable(aSchemaName, 'EFF_QUAL_MACH', vSelectQuery);
    PurgeTable(aSchemaName, 'EFF_QUAL2', vSelectQuery);
    PurgeTable(aSchemaName, 'EFF_QUAL', vSelectQuery);
    PurgeTable(aSchemaName, 'P_QUAL', vSelectQuery);
    PurgeTable(aSchemaName, 'B_AFQU', vSelectQuery);
    PurgeTable(aSchemaName, 'B_OPRT', vSelectQuery);
    PurgeTable(aSchemaName, 'B_QUAL', vSelectQuery);
  end;

  procedure deleteObsoleteZone(aSchemaName varchar2)
  is
    vQuery varchar2(32000);
  begin
    vQuery  := ' delete from ' || aSchemaName || '.B_ZONE ' || ' where NOZONE not in(select distinct NOZONE ' || ' from ' || aSchemaName || '.B_MACH)';

    execute immediate vQuery;
  end;

/******************************************************************************************
                          PROCESSUS  création des Ilots (B.ILOT)
******************************************************************************************/
  procedure CreateBlock(
    iSchemaName in varchar2
  , iName       in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , iWording    in FAL_FACTORY_FLOOR.FAC_DESCRIBE%type
  , iTypeIlot   in char
  )
  is
    vQuery   varchar2(32000);
    ModeIlot char(1);
  begin
    if cOrtAdjusting = 2 then
      ModeIlot  := '2';
    else
      ModeIlot  := '1';
    end if;

    vQuery  :=
      ' insert into ' ||
      iSchemaName ||
      '.B_ILOT           ' ||
      '       (ILOT      ' ||
      '      , TYPEILOT  ' ||
      '      , LIBILOT   ' ||
      '      , MODEILOT  ' ||
      '      , STATILOT  ' ||
      '      , TYPSUIVIL ' ||
      '      , ILOT_CNX) ' ||
      ' values(:ILOT     ' ||
      '      , :TYPEILOT ' ||
      '      , :LIBILOT  ' ||
      '      , :MODEILOT ' ||
      '      , ''O''     ' ||
      '      , ''0''     ' ||
      '      , 0)        ';

    execute immediate vQuery
                using trim(substr(iName, 1, 10) ), iTypeIlot, trim(substr(iWording, 1, 50) ), ModeIlot;
  exception
    when dup_val_on_index then
      null;
  end;

  function MachineExists(aSchemaName varchar2, aMachineGruppe varchar2, aMachine varchar2)
    return boolean
  is
    vQuery  varchar2(32000);
    vResult integer;
  begin
    vQuery  := 'select count(*) from ' || aSchemaName || '.B_MACH ' || ' where ILOT = :ILOT ' || '   and MACHINE = :MACHINE ';

    execute immediate vQuery
                 into vResult
                using trim(substr(aMachineGruppe, 1, 10) ), trim(substr(aMachine, 1, 10) );

    return(vResult > 0);
  end;

  procedure UpdateMachine(
    aSchemaName    varchar2
  , aMachineGruppe FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aMachine       FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aZone          FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aWording       FAL_FACTORY_FLOOR.FAC_DESCRIBE%type
  , aCalendarHebd  varchar2
  , aSection       FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID%type
  )
  is
    vQuery varchar2(32000);
  begin
    vQuery  :=
      'update ' ||
      aSchemaName ||
      '.B_MACH ' ||
      '   set NOCALHEBD = :NOCALHEBD ' ||
      '     , NOZONE = :NOZONE ' ||
      '     , LIBMACH = :LIBMACH ' ||
      '     , CODESECTI = :CODESECTI ' ||
      ' where MACHINE = :MACHINE ' ||
      '   and ILOT = :ILOT ';

    execute immediate vQuery
                using aCalendarHebd
                    , trim(substr(aZone, 1, 10) )
                    , trim(substr(aWording, 1, 50) )
                    , trim(substr(aSection, 1, 5) )
                    , trim(substr(aMachine, 1, 10) )
                    , trim(substr(aMachineGruppe, 1, 10) );
  exception
    when ex.PARENT_KEY_NOT_FOUND then
      if instr(DBMS_UTILITY.FORMAT_ERROR_STACK, 'FK3_B_MACH') <> 0 then
        RAISE_APPLICATION_ERROR(-20000, 'Calendar ''' || aCalendarHebd || ''' doesn''t exist.');
      else
        raise;
      end if;
    when others then
      raise;
  end;

  procedure CreateMachine(
    iSchemaName    in varchar2
  , iMachineGruppe in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , iMachine       in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , iZone          in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , iWording       in FAL_FACTORY_FLOOR.FAC_DESCRIBE%type
  , iCalendarHebd  in varchar2
  , iSection       in FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID%type default null
  )
  is
    vQuery varchar2(32000);
  begin
    vQuery  :=
      'insert into ' ||
      iSchemaName ||
      '.B_MACH ( ILOT,  MACHINE,  NOCALHEBD,  NOZONE,  LIBMACH, TYPECHGT, MACH_MODEMACH, CODESECTI) ' ||
      '  values(:ILOT, :MACHINE, :NOCALHEBD, :NOZONE, :LIBMACH, 2,        ''NR'',       :CODESECTI)';

    execute immediate vQuery
                using trim(substr(iMachineGruppe, 1, 10) )
                    , trim(substr(iMachine, 1, 10) )
                    , iCalendarHebd
                    , trim(substr(iZone, 1, 10) )
                    , trim(substr(iWording, 1, 50) )
                    , trim(substr(iSection, 1, 5) );
  exception
    when ex.PARENT_KEY_NOT_FOUND then
      if instr(DBMS_UTILITY.FORMAT_ERROR_STACK, 'FK3_B_MACH') <> 0 then
        RAISE_APPLICATION_ERROR(-20000, 'Calendar ''' || iCalendarHebd || ''' doesn''t exist.');
      else
        raise;
      end if;
    when others then
      raise;
  end;

  procedure CreateOrUpdateMachine(
    aSchemaName    varchar2
  , aMachineGruppe FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aMachine       FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aZone          FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aWording       FAL_FACTORY_FLOOR.FAC_DESCRIBE%type
  , aCalendarDescr varchar2
  , aCTeam         FAL_FACTORY_FLOOR.C_TEAM%type default '1'
  , aSection       FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID%type default null
  )
  is
    aCalendarHebd varchar2(10);
  begin
    aCalendarHebd  := upper(aCalendarDescr);

    if MachineExists(aSchemaName, aMachineGruppe, aMachine) then
      UpdateMachine(aSchemaName      => aSchemaName
                  , aMachineGruppe   => aMachineGruppe
                  , aMachine         => aMachine
                  , aZone            => aZone
                  , aWording         => aWording
                  , aCalendarHebd    => aCalendarHebd
                  , aSection         => aSection
                   );
    else
      CreateMachine(iSchemaName      => aSchemaName
                  , iMachineGruppe   => aMachineGruppe
                  , iMachine         => aMachine
                  , iZone            => aZone
                  , iWording         => aWording
                  , iCalendarHebd    => aCalendarHebd
                  , iSection         => aSection
                   );
    end if;
  end;

  function GetZoneOrSection(aValueId number, aFieldName varchar2, aSearchInSubcontract integer default 0)
    return FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID%type
  is
    vQuery     varchar2(32000);
    aTableName varchar2(20);
    aResult    FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID%type;
  begin
    if aSearchInSubcontract = 1 then
      aTableName  := 'PAC_PERSON';
    else
      aTableName  := 'FAL_FACTORY_FLOOR';
    end if;

    vQuery  := ' select ' || aFieldName || '   from ' || aTableName || '  where ' || aTableName || '_ID = :FIELD_VALUE_ID ';

    execute immediate vQuery
                 into aResult
                using aValueId;

    return aResult;
  exception
    when others then
      return null;
  end;

  /**
  * procedure ExportZonesAndBlocks
  * Description : Exportation des zones et îlots
  *
  * @created CLE
  * @lastUpdate
  * @public
  *
  * @param   aSchemaName : Nom du schéma Ortems
  */
  procedure ExportZonesAndBlocks(aSchemaName varchar2)
  is
    -- Sélection des ateliers qui représentent un îlot (FAC_IS_BLOCK = 1)
    cursor crIlot
    is
      select FAC_REFERENCE
           , FAC_DESCRIBE
           , decode(FAC_INFINITE_FLOOR, 1, '4', '2') TYPE_ILOT
        from FAL_FACTORY_FLOOR
       where nvl(FAC_IS_BLOCK, 0) = 1
         and FAC_OUT_OF_ORDER = 0;

    type TSubcontract is record(
      name          PAC_PERSON.PER_NAME%type
    , zone          PAC_PERSON.PER_NAME%type
    , CalendarDescr varchar2(20)
    );

    type TTabSubcontract is table of TSubcontract
      index by binary_integer;

    TabSubcontract TTabSubcontract;
    lvSqlQuery     varchar2(32000);
    cZoneSubc      varchar2(50);
  begin
    -- Pour chaque Atelier qui représente un ilot
    for tplIlot in crIlot loop
      CreateBlock(aSchemaName, tplIlot.FAC_REFERENCE, tplIlot.FAC_DESCRIBE, tplIlot.TYPE_ILOT);
    end loop;

    -- Sélection des sous-traitants qui apparaissent dans la liste des opérations
    lvSqlQuery  :=
      'select nvl([NAME_FIELD], PER.PER_NAME) Name
           , nvl(nvl([ZONE_FIELD], [NAME_FIELD]), PER.PER_NAME) Zone
           , trim(substr(FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendarDescr(TAL.PAC_SUPPLIER_PARTNER_ID), 1, 10) ) CalendarDescr
        from FAL_TASK_LINK TAL
           , PAC_PERSON PER
           , PAC_SUPPLIER_PARTNER SUP
       where TAL.PAC_SUPPLIER_PARTNER_ID is not null
         and TAL.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
         and TAL.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and exists(select FAL_LOT_ID
                      from FAL_LOT
                     where FAL_LOT_ID = TAL.FAL_LOT_ID
                       and C_LOT_STATUS in(''1'', ''2'') )
      union
      select nvl([NAME_FIELD], PER.PER_NAME) Name
           , nvl(nvl([ZONE_FIELD], [NAME_FIELD]), PER.PER_NAME) Zone
           , trim(substr(FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendarDescr(TAL.PAC_SUPPLIER_PARTNER_ID), 1, 10) ) CalendarDescr
        from FAL_TASK_LINK_PROP TAL
           , PAC_PERSON PER
           , PAC_SUPPLIER_PARTNER SUP
       where TAL.PAC_SUPPLIER_PARTNER_ID is not null
         and TAL.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
         and TAL.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID';
    -- Gestion de la configuration définissant le champ de regroupement des sous-traitants dans la même zone
    cZoneSubc   := PCS.PC_Config.GetConfig('FAL_ORT_ZONE_SUBCONTRACT');

    if cZoneSubc is null then
      lvSqlQuery  := replace(lvSqlQuery, '[ZONE_FIELD]', '[NAME_FIELD]');
    else
      lvSqlQuery  := replace(lvSqlQuery, '[ZONE_FIELD]', 'PER.' || cZoneSubc);
    end if;

    -- Gestion de la configuration définissant le champ utilisé pour définir les sous-traitants (pour géré l'unicité sur 10 caractères sans changer le PER_NAME)
    if cSubcField is null then
      lvSqlQuery  := replace(lvSqlQuery, '[NAME_FIELD]', 'PER.PER_NAME');
    else
      lvSqlQuery  := replace(lvSqlQuery, '[NAME_FIELD]', 'SUP.' || cSubcField);
    end if;

    execute immediate lvSqlQuery
    bulk collect into TabSubcontract;

    -- Création des îlots à capacité infinie.
    -- (pour les sous-traitants qui apparaissent dans les opérations)
    if TabSubcontract.count > 0 then
      for i in TabSubcontract.first .. TabSubcontract.last loop
        Creation_Zone(aSchemaName, TabSubcontract(i).zone);
        CreateBlock(aSchemaName, TabSubcontract(i).name, TabSubcontract(i).name, '4');   -- 4 = Ilot à capacité infini
        CreateOrUpdateMachine(aSchemaName      => aSchemaName
                            , aMachineGruppe   => TabSubcontract(i).name
                            , aMachine         => TabSubcontract(i).name
                            , aZone            => TabSubcontract(i).zone
                            , aWording         => TabSubcontract(i).name
                            , aCalendarDescr   => TabSubcontract(i).CalendarDescr
                            , aCTeam           => '1'
                             );
      end loop;
    end if;
  end;

  procedure CreateQualification(aSchemaName varchar2)
  is
    type TrecOperator is record(
      FacReference      varchar2(10)
    , FacDescribe       varchar2(15)
    , FacResourceNumber integer
    , CntOperator       integer
    );

    type TcrOperator is ref cursor;

    lvQuery     varchar2(32000);
    crOperator  TcrOperator;
    tplOperator TrecOperator;
  begin
    open crOperator for '
      select trim(substr(FAC_REFERENCE, 1, 10)) FAC_REFERENCE
           , trim(substr(FAC_DESCRIBE, 1, 15)) FAC_DESCRIBE
           , FAC_RESOURCE_NUMBER
           , (select count(*)
                from FAL_FACTORY_FLOOR
               where FAL_GRP_FACTORY_FLOOR_ID = FFF1.FAL_FACTORY_FLOOR_ID
                 and FAC_OUT_OF_ORDER = 0) CNT_OPRT
        from FAL_FACTORY_FLOOR FFF1
       where FAC_IS_OPERATOR = 1
         and FAC_OUT_OF_ORDER = 0  ';

    fetch crOperator
     into tplOperator;

    while crOperator%found loop
      lvQuery  :=
        '
        declare
          lvFacReference      varchar2(10);
          lvFacDescribe       varchar2(15);
          liFacResourceNumber integer;
          liCntOperator       integer;
        begin
          lvFacReference       := :vFacReference;
          lvFacDescribe        := :vFacDescribe;
          liFacResourceNumber  := :iFacResourceNumber;
          liCntOperator        := :iCntOperator;
          update [CPY].B_QUAL
             set LIBQUAL = lvFacDescribe
               , NOMIN = decode(liCntOperator, 0, 0, 1)
               , NB_OPER = decode(liCntOperator, 0, liFacResourceNumber, liCntOperator)
               , CAP_GENE = decode(liCntOperator, 0, liFacResourceNumber, liCntOperator)
           where QUALIF = lvFacReference;
           if sql%notfound then
             insert into [CPY].B_QUAL
                   (QUALIF
                  , LIBQUAL
                  , COEF_HIER
                  , NOMIN
                  , NB_OPER
                  , CAP_GENE
                  , QUAL_FAM_CODE)
            values(lvFacReference
                 , lvFacDescribe
                 , 100
                 , decode(liCntOperator, 0, 0, 1)
                 , decode(liCntOperator, 0, liFacResourceNumber, liCntOperator)
                 , decode(liCntOperator, 0, liFacResourceNumber, liCntOperator)
                 , ''DEFAULT'');
           end if;
        end;';

      execute immediate replace(lvQuery, '[CPY]', aSchemaName)
                  using in tplOperator.FacReference, in tplOperator.FacDescribe, in tplOperator.FacResourceNumber, in tplOperator.CntOperator;

      fetch crOperator
       into tplOperator;
    end loop;

    close crOperator;
  end;

  procedure CreateOperator(aSchemaName varchar2)
  is
    type trec_query1 is record(
      fac_reference varchar2(10)
    , qualif        varchar2(10)
    , fac_describe  varchar2(15)
    , calendar      varchar2(10)
    );

    type tcur_query1 is ref cursor;

    lv_query1   varchar2(32000);
    lcur_query1 tcur_query1;
    tpl_query1  trec_query1;
    ln_result   integer;
    lvCalendar  varchar2(10);
  begin
    lv_query1  :=
      'select trim(substr(FAC_REFERENCE, 1, 10)) FAC_REFERENCE  ' ||
      '            , (select trim(substr(FAC_REFERENCE, 1, 10))   ' ||
      '                 from FAL_FACTORY_FLOOR ' ||
      '                where FAL_FACTORY_FLOOR_ID = FFF1.FAL_GRP_FACTORY_FLOOR_ID) QUALIF ' ||
      '            , trim(substr(FAC_DESCRIBE, 1, 15)) FAC_DESCRIBE  ';
    lv_query1  := lv_query1 || ' , upper(trim(substr(FAL_SCHEDULE_FUNCTIONS.GetFloorCalendarDescr(FFF1.FAL_FACTORY_FLOOR_ID), 1, 10) ) ) CALENDAR  ';
    lv_query1  := lv_query1 || '  from FAL_FACTORY_FLOOR FFF1 ' || ' where FAC_IS_PERSON = 1 ' || '   and FAC_OUT_OF_ORDER = 0';

    open lcur_query1 for lv_query1;

    fetch lcur_query1
     into tpl_query1;

    while lcur_query1%found loop
      execute immediate '
           declare
              lv_qualif varchar2(10);
              lv_fac_describe varchar2(15);
              lv_calendar varchar2(10);
              lv_fac_reference varchar2(10);
           begin
           lv_qualif:= :qualif;
           lv_fac_describe := :fac_describe;
           lv_calendar := :calendar;
           lv_fac_reference :=  :fac_reference; ' ||
                        'update ' ||
                        aSchemaName ||
                        '.B_OPRT BO ' ||
                        '   set BO.QUALIF = lv_QUALIF ' ||
                        '     , BO.NOM = lv_FAC_DESCRIBE ' ||
                        '     , BO.PRENOM = lv_FAC_DESCRIBE ' ||
                        '     , BO.NOCALHEBD = lv_CALENDAR ' ||
                        ' where BO.MATRICULE = lv_FAC_REFERENCE ; ' ||
                        ' if sql%notfound then :result := 0; else :result:= 1; end if; end;'
                  using in tpl_query1.qualif, in tpl_query1.fac_describe, in tpl_query1.calendar, in tpl_query1.fac_reference, out ln_result;

      if ln_result = 0 then
        execute immediate 'insert into ' ||
                          aSchemaName ||
                          '.B_OPRT BO (matricule, qualif, nom, prenom, nocalhebd) ' ||
                          'values (:matricule, :qualif, :fac_describe, :fac_describe, :calendar)'
                    using in tpl_query1.fac_reference, in tpl_query1.qualif, in tpl_query1.fac_describe, in tpl_query1.fac_describe, in tpl_query1.calendar;
      end if;

      fetch lcur_query1
       into tpl_query1;
    end loop;

    close lcur_query1;
  exception
    when others then
      lvCalendar  := tpl_query1.calendar;

      close lcur_query1;

      if instr(DBMS_UTILITY.FORMAT_ERROR_STACK, 'FK2_B_OPRT') <> 0 then
        RAISE_APPLICATION_ERROR(-20000, 'Calendar ''' || lvCalendar || ''' doesn''t exist.');
      else
        raise;
      end if;
  end;

  procedure Export_Machines(NomSchema varchar2)
  is
    -- ateliers qui représentent une machine et qui n'est pas opérateur
    -- UNION îlots qui n'ont pas de machine associée et qui ne sont pas opérateur, on crée une machine
    cursor crFalFactoryFloor
    is
      select a.fal_factory_floor_id
           , a.fac_reference machine
           , a.fac_describe wording
           , b.fac_reference ilot
           , a.c_team
           , trim(substr(FAL_SCHEDULE_FUNCTIONS.GetFloorCalendarDescr(a.fal_factory_floor_id), 1, 10) ) CalendarDescr
        from fal_factory_floor a
           , fal_factory_floor b
       where nvl(a.fac_is_machine, 0) = 1
         and a.fal_fal_factory_floor_id = b.fal_factory_floor_id
         and a.fac_out_of_order = 0
      union
      select fal_factory_floor_id
           , fac_reference machine
           , fac_describe wording
           , fac_reference ilot
           , c_team
           , trim(substr(FAL_SCHEDULE_FUNCTIONS.GetFloorCalendarDescr(fal_factory_floor_id), 1, 10) ) CalendarDescr
        from fal_factory_floor
       where nvl(fac_is_block, 0) = 1
         and fac_out_of_order = 0
         and (   fac_infinite_floor = 1
              or fal_factory_floor_id not in(select fal_fal_factory_floor_id
                                               from fal_factory_floor
                                              where fal_fal_factory_floor_id is not null) );

    aSection FAL_FACTORY_FLOOR.DIC_FLOOR_FREE_CODE_ID%type;
    aZone    FAL_FACTORY_FLOOR.FAC_REFERENCE%type;
  begin
    -- Pour chaque atelier qui représente une machine et qui n'est pas opérateur
    -- ET pour chaque îlot qui n'a pas de machine associée et qui n'est pas opérateur, on crée une machine
    for tplFalFactoryFloor in crFalFactoryFloor loop
      aSection  := null;

      if PCS.PC_Config.GetConfig('FAL_ORT_SECTION') is not null then
        aSection  := GetZoneOrSection(tplFalFactoryFloor.fal_factory_floor_id, PCS.PC_Config.GetConfig('FAL_ORT_SECTION') );

        if aSection is not null then
          Creation_Section(NomSchema, aSection);
        end if;
      end if;

      aZone     := null;

      if PCS.PC_Config.GetConfig('FAL_ORT_ZONE') is not null then
        aZone  := GetZoneOrSection(tplFalFactoryFloor.fal_factory_floor_id, PCS.PC_Config.GetConfig('FAL_ORT_ZONE') );
      end if;

      aZone     := nvl(aZone, tplFalFactoryFloor.Ilot);
      Creation_Zone(NomSchema, aZone);
      CreateOrUpdateMachine(aSchemaName      => NomSchema
                          , aMachineGruppe   => tplFalFactoryFloor.Ilot
                          , aMachine         => tplFalFactoryFloor.Machine
                          , aCTeam           => tplFalFactoryFloor.c_team
                          , aSection         => aSection
                          , aWording         => tplFalFactoryFloor.wording
                          , aZone            => aZone
                          , aCalendarDescr   => tplFalFactoryFloor.CalendarDescr
                           );
    end loop;

    if PCS.PC_Config.GetConfig('FAL_ORT_EXPORT_OPERATOR') = 'True' then
      CreateQualification(NomSchema);
      CreateOperator(NomSchema);
    end if;
  end;

  procedure Creation_Outils(
    NomSchema             varchar2
  , GooMajorReference     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , GooSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  )
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'INSERT INTO ' || NomSchema || '.B_OUTI(CODOUTILL, LIBOUTIL)';
    BuffSQL         := BuffSQL || 'VALUES(:vCODOUTILL, :vLIBOUTIL)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCODOUTILL', trim(substr(GooMajorReference, 1, 15) ) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vLIBOUTIL', trim(substr(GooSecondaryReference, 1, 20) ) );
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when dup_val_on_index then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  procedure CreateAdustingTool(aSchemaName varchar2)
  is
    vQuery varchar2(32000);
  begin
    vQuery  :=
      ' insert into ' ||
      aSchemaName ||
      '.B_OUTI            ' ||
      '       (CODOUTILL     ' ||
      '      , LIBOUTIL)   ' ||
      ' values(:CODOUTILL   ' ||
      '      , :LIBOUTIL) ';

    execute immediate vQuery
                using ctAdustingTool, ctAdustingToolDescr;
  exception
    when dup_val_on_index then
      null;
  end;

/******************************************************************************************
                PROCESSUS  création des Ressources limitées (B_LIMI)
******************************************************************************************/
  procedure Creation_Ressource_Limitee(
    NomSchema             varchar2
  , GooMajorReference     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , GooSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , TlsRate               PPS_TOOLS.TLS_RATE%type
  )
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    NbreRess       number;
  begin
    if nvl(TlsRate, 0) <= 0 then
      NbreRess  := 1;
    else
      NbreRess  := TlsRate;
    end if;

    BuffSQL         := 'INSERT INTO ' || NomSchema || '.B_LIMI(CODELIMI, LIBLIMI, NBLIMI)';
    BuffSQL         := BuffSQL || 'VALUES(:vCODELIMI, :vLIBLIMI, :vNBLIMI)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCODELIMI', trim(substr(GooMajorReference, 1, 20) ) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vLIBLIMI', trim(substr(GooSecondaryReference, 1, 15) ) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vNBLIMI', NbreRess);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when dup_val_on_index then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  procedure Export_Outils(NomSchema varchar2)
  is
    -- Déclaration des curseurs
    cursor CUR_TOOLS
    is
      select GOO_MAJOR_REFERENCE
           , GOO_SECONDARY_REFERENCE
           , TLS_RATE
        from PPS_TOOLS PT
           , GCO_GOOD GG
       where PT.GCO_GOOD_ID = GG.GCO_GOOD_ID;
  begin
    -- Ca ne sert à rien de rentrer dans la boucle si aucune des deux conditions
    -- ci-dessous n'est respectée.
    if    (PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_FUNCTION') is null)
       or (PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_IN_LIMITED_RESS') = 'True') then
      for CurTools in CUR_TOOLS loop
        if (PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_FUNCTION') is null) then
          Creation_Outils(NomSchema, CurTools.GOO_MAJOR_REFERENCE, CurTools.GOO_SECONDARY_REFERENCE);
        end if;

        if PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_IN_LIMITED_RESS') = 'True' then
          Creation_Ressource_Limitee(NomSchema, CurTools.GOO_MAJOR_REFERENCE, CurTools.GOO_SECONDARY_REFERENCE, CurTools.TLS_RATE);
        end if;
      end loop;
    end if;
  end;

  procedure Creation_Parametre(
    NomSchema      varchar2
  , TypeMat        DIC_GCO_CHAR_CODE_TYPE.DIC_GCO_CHAR_CODE_TYPE_ID%type
  , DccDescription DIC_GCO_CHAR_CODE_TYPE.DCC_DESCRIPTION%type
  )
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'INSERT INTO ' || NomSchema || '.B_TYPM(TYPEMAT, LIBTYPMAT)';
    BuffSQL         := BuffSQL || 'VALUES(:vTYPEMAT, :vLIBTYPMAT)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vTYPEMAT', TypeMat);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vLIBTYPMAT', trim(substr(DccDescription, 1, 15) ) );
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when dup_val_on_index then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  procedure Creation_Valeur_Parametre(
    iSchemaName varchar2
  , iTypeMat    DIC_GCO_CHAR_CODE_TYPE.DIC_GCO_CHAR_CODE_TYPE_ID%type
  , iLibParam   GCO_FREE_CODE.FCO_CHA_CODE%type
  , iParam      DIC_FREE_TASK_CODE.DIC_FREE_TASK_CODE_ID%type
  )
  is
    lvSqlQuery varchar2(2000);
  begin
    lvSqlQuery  := ' insert into [CPY].B_PARM(TYPEMAT, PARAMETRE, LIBPARAM) ' || '    values(:TYPEMAT, :PARAMETRE, :LIBPARAM)';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iTypeMat, trim(substr(nvl(iParam, iLibParam), 1, 15) ), trim(substr(iLibParam, 1, 50) );
  exception
    when dup_val_on_index then
      null;
  end;

  procedure Creation_Parametres_Discrets(NomSchema varchar2)
  is
  begin
    if    (cOrtAdjusting = 3)
       or (cOrtAdjusting = 5) then
      for tplParam in (select distinct DGCCT.DIC_GCO_CHAR_CODE_TYPE_ID
                                     , DCC_DESCRIPTION
                                  from DIC_GCO_CHAR_CODE_TYPE DGCCT
                                     , FAL_FACTORY_PARAMETER FFP
                                 where DGCCT.DIC_GCO_CHAR_CODE_TYPE_ID = FFP.DIC_GCO_CHAR_CODE_TYPE_ID) loop
        Creation_Parametre(NomSchema, tplParam.DIC_GCO_CHAR_CODE_TYPE_ID, tplParam.DCC_DESCRIPTION);

        for tplFreeCode in (select FCO_CHA_CODE
                              from GCO_FREE_CODE
                             where DIC_GCO_CHAR_CODE_TYPE_ID = tplParam.DIC_GCO_CHAR_CODE_TYPE_ID
                               and FCO_CHA_CODE is not null) loop
          Creation_Valeur_Parametre(iSchemaName   => NomSchema
                                  , iTypeMat      => tplParam.DIC_GCO_CHAR_CODE_TYPE_ID
                                  , iLibParam     => tplFreeCode.FCO_CHA_CODE
                                  , iParam        => null
                                   );
        end loop;
      end loop;
    else   -- FAL_ORT_ADJUSTING = 4
      Creation_Parametre(NomSchema, 'CODEOP', 'CODEOP');

      for tplFreeTaskCode in (select GT1_DESCRIBE
                                   , DIC_FREE_TASK_CODE_ID
                                from DIC_FREE_TASK_CODE) loop
        Creation_Valeur_Parametre(iSchemaName   => NomSchema
                                , iTypeMat      => 'CODEOP'
                                , iLibParam     => tplFreeTaskCode.GT1_DESCRIBE
                                , iParam        => tplFreeTaskCode.DIC_FREE_TASK_CODE_ID
                                 );
      end loop;
    end if;
  end;

  function GetCalendarPrefixFromBCal(NomSchema varchar2)
    return varchar2
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    result         varchar2(2);
  begin
    BuffSQL         := 'SELECT NOCALHEBD FROM ' || NomSchema || '.B_CAL ';
    BuffSQL         := BuffSQL || ' WHERE NOCALHEBD = ''01'' ';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 1, result, 2);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    if DBMS_SQL.FETCH_ROWS(Cursor_Handle) > 0 then
      DBMS_SQL.column_value(Cursor_Handle, 1, result);
    else
      result  := '1';
    end if;

    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
    return result;
  end;

  function GetCalendarPrefix(NomSchema varchar2)
    return varchar2
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    result         varchar2(2);
  begin
    BuffSQL         := 'SELECT NOCALHEBD FROM ' || NomSchema || '.B_MACH ';
    BuffSQL         := BuffSQL || ' WHERE NOCALHEBD IS NOT NULL ';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 1, result, 2);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    if DBMS_SQL.FETCH_ROWS(Cursor_Handle) > 0 then
      DBMS_SQL.column_value(Cursor_Handle, 1, result);
    else
      result  := GetCalendarPrefixFromBCal(NomSchema);
    end if;

    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);

    if substr(trim(result), 1, 1) = '0' then
      return '0';
    else
      return null;
    end if;
  end;

  procedure Export_Donnees_Statiques(NomSchema varchar2)
  is
  begin
    CalendarPrefix  := GetCalendarPrefix(NomSchema);
    deleteObsoleteData(NomSchema);
    commit;
    ExportZonesAndBlocks(NomSchema);
    Export_Machines(NomSchema);
    deleteObsoleteZone(NomSchema);
    Export_Outils(NomSchema);

    -- Si les temps de réglage se font par les matrices, on crée les paramètres discrets
    if cOrtAdjusting in(3, 4, 5) then
      Creation_Parametres_Discrets(NomSchema);
    end if;
  end;

/******************************************************************************************

                               EXPORTATION DES DONNEES DYNAMIQUES

******************************************************************************************/
  procedure Purge_Ortems(NomSchema varchar2)
  is
    vQuery varchar2(32000);
  begin
    PurgeTable(NomSchema, 'CHARGE_ILOT');
    PurgeTable(NomSchema, 'CHARGE_ILOT2');
    PurgeTable(NomSchema, 'CHARGE_MACH');
    PurgeTable(NomSchema, 'CHARGE_MACH2');
    PurgeTable(NomSchema, 'CHARGE_OPRT');
    PurgeTable(NomSchema, 'CHARGE_OPRT2');
    PurgeTable(NomSchema, 'CHARGE_SECT');
    PurgeTable(NomSchema, 'CHARGE_SECT2');
    PurgeTable(NomSchema, 'CHARGE_SER_ILOT');
    PurgeTable(NomSchema, 'CHARGE_SER_ILOT2');
    PurgeTable(NomSchema, 'E_ALIM_STOC2');
    PurgeTable(NomSchema, 'ENC_EXEMPL2');
    PurgeTable(NomSchema, 'ENC_CAD_QUAL2');
    PurgeTable(NomSchema, 'ENC_CAD_LIMI2');
    PurgeTable(NomSchema, 'ENC_CAD2');
    PurgeTable(NomSchema, 'BT_QUAL2');
    PurgeTable(NomSchema, 'BT_LIMI2');
    PurgeTable(NomSchema, 'BT_PARM2');
    PurgeTable(NomSchema, 'BT_ART2');
    PurgeTable(NomSchema, 'E_RSV_RES2');
    PurgeTable(NomSchema, 'E_NOME2');
    PurgeTable(NomSchema, 'B_PREN2');
    PurgeTable(NomSchema, 'BT_BT2');
    PurgeTable(NomSchema, 'B_BM2');
    PurgeTable(NomSchema, 'B_BT2');
    PurgeTable(NomSchema, 'E_OF_VER2');
    PurgeTable(NomSchema, 'E_OF_E_OF2');
    PurgeTable(NomSchema, 'E_OF_TYPV2');
    PurgeTable(NomSchema, 'E_OF2');
    PurgeTable(NomSchema, 'B_STOC_NRJ');
    PurgeTable(NomSchema, 'ENC_NRJ_CAD');
    PurgeTable(NomSchema, 'ENC_NRJ_MACH');
    PurgeTable(NomSchema, 'B_NRJ_CADE');
    PurgeTable(NomSchema, 'B_NRJ_MACH');
    PurgeTable(NomSchema, 'B_NRJ');
    PurgeTable(NomSchema, 'E_ALIM_STOC');
    PurgeTable(NomSchema, 'E_REG');
    PurgeTable(NomSchema, 'E_COP');
    PurgeTable(NomSchema, 'ENC_EXEMPL');
    PurgeTable(NomSchema, 'ENC_CAD_QUAL');
    PurgeTable(NomSchema, 'ENC_CAD_LIMI');
    PurgeTable(NomSchema, 'ENC_CAD');
    PurgeTable(NomSchema, 'BT_QUAL');
    PurgeTable(NomSchema, 'BT_LIMI');
    PurgeTable(NomSchema, 'BT_PARM');
    PurgeTable(NomSchema, 'BT_ART');
    PurgeTable(NomSchema, 'E_RSV_RES');
    PurgeTable(NomSchema, 'E_SPLI');
    PurgeTable(NomSchema, 'E_NOME');
    PurgeTable(NomSchema, 'B_PREN');
    PurgeTable(NomSchema, 'BT_BT');
    PurgeTable(NomSchema, 'B_BM');
    PurgeTable(NomSchema, 'B_BT');
    PurgeTable(NomSchema, 'E_OF_VER');
    PurgeTable(NomSchema, 'E_OF_E_OF');
    PurgeTable(NomSchema, 'E_OF_TYPV');
    PurgeTable(NomSchema, 'E_SER');
    PurgeTable(NomSchema, 'B_OF_SER');
    PurgeTable(NomSchema, 'E_OF');
    PurgeTable(NomSchema, 'ILOT_ENCOURS');
    PurgeTable(NomSchema, 'MACH_ENCOURS');
    PurgeTable(NomSchema, 'S_ART');
    PurgeTable(NomSchema, 'E_ACHAT');
    PurgeTable(NomSchema, 'B_BES');
    PurgeTable(NomSchema, 'B_CALP');
    PurgeTable(NomSchema, 'B_EVT');
    PurgeTable(NomSchema, 'INFO_MACH');
    PurgeTable(NomSchema, 'INFO_ART');
    PurgeTable(NomSchema, 'INFO_SER');
    PurgeTable(NomSchema, 'INFO_OF');
    PurgeTable(NomSchema, 'B_PROF');
    PurgeTable(NomSchema, 'B_PHM');
    PurgeTable(NomSchema, 'OF_TYPV');
    PurgeTable(NomSchema, 'B_OF');
    PurgeTable(NomSchema, 'B_SER');
    PurgeTable(NomSchema, 'E_MAJ_ACHAT');
    PurgeTable(NomSchema, 'E_ACHAT');
    PurgeTable(NomSchema, 'ART_MARQ');
    PurgeTable(NomSchema, 'B_STOC');
    PurgeTable(NomSchema, 'B_NOME');
    PurgeTable(NomSchema, 'I_NOME');
    PurgeTable(NomSchema, 'B_PARTC');
    PurgeTable(NomSchema, 'B_PART');
    PurgeTable(NomSchema, 'B_VER_ART');
    PurgeTable(NomSchema, 'E_CPP');
    PurgeTable(NomSchema, 'E_ART_PERI');
    PurgeTable(NomSchema, 'E_ART_PERI2');
    PurgeTable(NomSchema, 'B_ART');
    PurgeTable(NomSchema, 'B_EMPL');
    PurgeTable(NomSchema, 'B_GRM');
    PurgeTable(NomSchema, 'RSV_RES');
    PurgeTable(NomSchema, 'B_SPLI');
    PurgeTable(NomSchema, 'B_PREC');
    PurgeTable(NomSchema, 'B_PHMA');
    PurgeTable(NomSchema, 'B_PHM');
    PurgeTable(NomSchema, 'B_PHAS');
    vQuery  := ' delete from ' || NomSchema || '.B_GAMM WHERE  NOMG <> ''MP''';

    execute immediate vQuery;

    PurgeTable(NomSchema, 'B_OPLI');
    PurgeTable(NomSchema, 'CADE_LIMI');
    PurgeTable(NomSchema, 'B_AFCA');
    PurgeTable(NomSchema, 'B_CADE');
    PurgeTable(NomSchema, 'B_OPE');
    PurgeTable(NomSchema, 'B_GRPR');
    PurgeTable(NomSchema, 'B_LC_ECH');
    PurgeTable(NomSchema, 'B_LC');
    PurgeTable(NomSchema, 'B_CNX_MACH');
    PurgeTable(NomSchema, 'B_CAPA_MACH');
    PurgeTable(NomSchema, 'B_PRIL');
    PurgeTable(NomSchema, 'B_GPMA');
    PurgeTable(NomSchema, 'B_TYMA');
    PurgeTable(NomSchema, 'B_GPE');
    PurgeTable(NomSchema, 'B_TYP');
    PurgeTable(NomSchema, 'B_UTIL');
  end;

  /**
  * procedure CreationSerie
  * Description
  *   Création d'une série (pour un article ou une référence client)
  * @author CLE
  * @param   NomSchema    Schéma d'export Ortems
  * @param   Serie        Article ou référence client
  * @param   aClass       Classe de série avancée (null si c'est un article, valeur de constante ctClass pour une référence client)
  */
  procedure CreationSerie(
    NomSchema     varchar2
  , Serie         GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aClass        varchar2 default null
  , aCustomerName varchar2 default null
  , aDelay        date default null
  )
  is
  begin
    execute immediate 'insert into ' ||
                      NomSchema ||
                      '.B_SER(SERIE, CODE_CLASS, SER_CODECLIEN, SER_FPLUSTARD) values(:SERIE, :CODE_CLASS, :SER_CODECLIEN, :SER_FPLUSTARD)'
                using Serie, aClass, aCustomerName, aDelay;
  exception
    when dup_val_on_index then
      null;
  end;

  /**
  * procedure GetProductReference
  * Description
  *   Récupération de la référence principale d'un produit
  *   S'ils n'existent pas encore dans Ortems, création de l'article et de la série pour ce produit
  * @author CLE
  * @param aSchemaName   Schéma d'export Ortems
  * @param aGcoGoodId    Id du produit
  */
  function GetProductReference(aSchemaName varchar2, aGcoGoodId number)
    return GCO_GOOD.GOO_MAJOR_REFERENCE%type
  is
    GooMajorReference     GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    GooSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    ProdExistsInOrtems    integer;
  begin
    execute immediate 'select GOO_MAJOR_REFERENCE ' ||
                      '     , GOO_SECONDARY_REFERENCE ' ||
                      '     , (select count(*) ' ||
                      '          from ' ||
                      aSchemaName ||
                      '.B_ART ' ||
                      '         where CODEARTIC = GOOD.GOO_MAJOR_REFERENCE) PRODUCT_IN_ORTEMS ' ||
                      '  from GCO_GOOD GOOD ' ||
                      ' where GCO_GOOD_ID = :GCO_GOOD_ID '
                 into GooMajorReference
                    , GooSecondaryReference
                    , ProdExistsInOrtems
                using aGcoGoodId;

    if ProdExistsInOrtems = 0 then
      -- Création de l'article dans Ortems
      execute immediate 'insert into ' ||
                        aSchemaName ||
                        '.B_ART(CODEARTIC, LIBARTIC, PCB, TYPEMATI, ART_FAB_CODEGROUP) ' ||
                        ' values(:CODEARTIC, :LIBARTIC, 1, ''PF'', ''00'')'
                  using GooMajorReference, GooSecondaryReference;

      CreationSerie(aSchemaName, GooMajorReference);
    end if;

    return GooMajorReference;
  end;

  /**
  * procedure CreateAdvanceSerieClass
  * Description
  *   Création d'une classe de série avancée (pour les besoins initiaux - référence client)
  * @author CLE
  * @param   NomSchema    Schéma d'export Ortems
  */
  procedure CreateAdvanceSerieClass(NomSchema varchar2)
  is
  begin
    execute immediate 'insert into ' || NomSchema || '.B_CLASS_SER(CODE_CLASS, DESC_CLASS) values(:CODE_CLASS, :DESC_CLASS)'
                using ctClass, PCS.PC_FUNCTIONS.TranslateWord('Besoin initial (commande client)');
  exception
    when dup_val_on_index then
      null;
  end;

  /**
  * procedure CreateBatchAdvancedSerie
  * Description
  *   Création d'une série avancée d'OF (lien entre la référence client et l'OF)
  * @author CLE
  * @param   NomSchema    Schéma d'export Ortems
  * @param   Batch        OF (référence complète du lot)
  * @param   Serie        Référence client besoin initial
  */
  procedure CreateBatchAdvancedSerie(NomSchema varchar2, Batch varchar2, Serie varchar2)
  is
  begin
    execute immediate 'insert into ' || NomSchema || '.B_OF_SER(NOF, SERIE) values(:NOF, :SERIES)'
                using Batch, Serie;
  exception
    when dup_val_on_index then
      null;
  end;

  /**
  * procedure InitialRequirementManagement
  * Description
  *   Gestion des besoins initiaux :
  *       - Export des références clients dans les séries Ortems
  *       - Création d'une série avancée d'OF (lien entre la référence client et l'OF)
  *   La recherche du besoin initial se fait à partir de l'Id du lot, en allant chercher les Id d'appro de celui-ci.
  *  (Attention : on peut avoir plusieurs Id d'appro si le lot à des détails lots en caractérisation morphologique)
  * @author CLE
  * @param   NomSchema       Schéma d'export Ortems
  * @param   varLotRefCompl  Référence complète du lot
  * @param   LotOrPropId     Id de lot ou de proposition
  */
  function InitialRequirementManagement(NomSchema varchar2, varLotRefCompl varchar2, LotOrPropId number)
    return date
  is
    lvPosDetailIdList  varchar2(4000);
    lvPositionDetailId varchar2(4000);
    lvDmtNumber        DOC_DOCUMENT.DMT_NUMBER%type;
    ldBasisDelay       DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    lvCustomerName     varchar2(30);
    ldDelayMin         DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
  begin
    ldDelayMin  := null;

    for tplRequirements in (select substr(FAL_TOOLS.get_besoin_origine(FAL_NETWORK_SUPPLY_ID, '##', 2), 1, 4000) DetailPosIdList
                              from FAL_NETWORK_SUPPLY
                             where FAL_LOT_ID = LotOrPropId
                                or FAL_LOT_PROP_ID = LotOrPropId) loop
      lvPosDetailIdList  := tplRequirements.DetailPosIdList;

      if instr(lvPosDetailIdList, '...') > 0 then
        lvPosDetailIdList  := substr(lvPosDetailIdList, 4, 4000);
      end if;

      loop
        lvPositionDetailId  := substr(lvPosDetailIdList, 1, instr(lvPosDetailIdList, '##') - 1);
        exit when lvPositionDetailId is null;

        begin
          select DOC.DMT_NUMBER
               , POS.PDE_BASIS_DELAY
               , substr(PP.PER_SHORT_NAME, 1, 30)
            into lvDmtNumber
               , ldBasisDelay
               , lvCustomerName
            from DOC_POSITION_DETAIL POS
               , DOC_DOCUMENT DOC
               , PAC_PERSON PP
           where POS.DOC_POSITION_DETAIL_ID = to_number(lvPositionDetailId)
             and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
             and PP.PAC_PERSON_ID = DOC.PAC_THIRD_ID;

          ldDelayMin         := nvl(least(ldDelayMin, ldBasisDelay), ldBasisDelay);
          CreationSerie(NomSchema, lvDmtNumber, ctClass, lvCustomerName, ldBasisDelay);
          CreateBatchAdvancedSerie(NomSchema, varLotRefCompl, lvDmtNumber);
          lvPosDetailIdList  := substr(lvPosDetailIdList, length(lvPositionDetailId) + 3, 4000);
        exception
          when no_data_found then
            return null;
        end;
      end loop;
    end loop;

    return ldDelayMin;
  end;

  /**
  * procedure CreateProcessPlan
  * Description
  *   Création de la gamme dans Ortems
  * @author CLE
  * @param   aSchemaName             Schéma d'export Ortems
  * @param   aLotRefCompl            OF (référence complète du lot)
  * @param   aOrborescentProcess     Indique si la gamme doit être de type arborescente
  * @param   aParallelExists         Indique si l'OF a au moins une opération parralèle
  */
  procedure CreateProcessPlan(aSchemaName varchar2, aLotRefCompl varchar2, aOrborescentProcess boolean, aParallelExists boolean)
  is
    vTypeGam varchar2(1);
  begin
    if aOrborescentProcess then
      vTypeGam  := '4';
    elsif aParallelExists then
      vTypeGam  := '2';
    else
      vTypeGam  := '1';
    end if;

    execute immediate 'insert into ' || aSchemaName || '.B_GAMM(NOMG, LIBGAM, TYPEGAM, STATGAMME) values(:NOMG, :LIBGAM, :TYPEGAM, ''O'')'
                using trim(substr(aLotRefCompl, 1, 30) ), trim(substr(aLotRefCompl, 1, 25) ), vTypeGam;
  end;

  function GetToolCode(GcoGoodId number)
    return varchar2
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    result         varchar2(15);
  begin
    result          := null;
    BuffSql         := ' BEGIN ';
    BuffSql         := BuffSql || PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_FUNCTION') || '(:GcoGoodId, :Result);';
    BuffSql         := BuffSql || ' END;';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSql, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, ':GcoGoodId', GcoGoodId);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, ':Result', '_______________');   -- passage de 15 caractères, sinon ça ne marche pas !?
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.VARIABLE_VALUE(Cursor_Handle, ':Result', result);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
    return result;
  end;

  /**
  * procedure GetBlockAndMachine
  * Description : Récupération du nom de l'îlot, de la machine et du type de capacité (infinie ou non) de la ressource d'une opération
  *
  * @created CLE
  * @lastUpdate
  * @public
  *
  * @param    iCTaskType      : type de tâche (interne/externe)
  * @param    iFactoryFloorId : ID de l'atelier
  * @param    iSupplierId     : ID du fournisseur
  * @return   oBlock          : nom de l'îlot pour Ortems
  * @return   oMachine        : nom de la machine
  * @return   oInfiniteFloor  : capacité infinie (1 ou 0)
  */
  procedure GetBlockAndMachine(
    iCTaskType      in     FAL_TASK_LINK.C_TASK_TYPE%type
  , iFactoryFloorId in     number
  , iSupplierId     in     number
  , oBlock          out    varchar2
  , oMachine        out    varchar2
  , oInfiniteFloor  out    integer
  )
  is
    cursor crFactoryFloor
    is
      select trim(substr(decode(FFF1.FAL_FAL_FACTORY_FLOOR_ID, null, null, FFF1.FAC_REFERENCE), 1, 10) ) MACHINE
           , nvl(FFF2.FAC_INFINITE_FLOOR, FFF1.FAC_INFINITE_FLOOR) FAC_INFINITE_FLOOR
           , trim(substr(nvl(FFF2.FAC_REFERENCE, FFF1.FAC_REFERENCE), 1, 10) ) ILOT
        from FAL_FACTORY_FLOOR FFF1
           , FAL_FACTORY_FLOOR FFF2
       where FFF1.FAL_FAL_FACTORY_FLOOR_ID = FFF2.FAL_FACTORY_FLOOR_ID(+)
         and FFF1.FAL_FACTORY_FLOOR_ID = iFactoryFloorId;

    lvSqlQuery varchar2(200);
  begin
    if iCTaskType = '1' then
      -- Tâche interne
      open crFactoryFloor;

      fetch crFactoryFloor
       into oMachine
          , oInfiniteFloor
          , oBlock;

      close crFactoryFloor;
    else
      oBlock          := null;

      -- Tâche externe
      if cSubcField is not null then
        lvSqlQuery  := 'select trim(substr(' || cSubcField || ', 1, 10) ) from PAC_SUPPLIER_PARTNER where PAC_SUPPLIER_PARTNER_ID = :SupplierId';

        execute immediate lvSqlQuery
                     into oBlock
                    using iSupplierId;
      end if;

      if oBlock is null then
        lvSqlQuery  := 'select trim(substr(PER_NAME, 1, 10) ) from PAC_PERSON where PAC_PERSON_ID = :SupplierId';

        execute immediate lvSqlQuery
                     into oBlock
                    using iSupplierId;
      end if;

      oMachine        := oBlock;
      oInfiniteFloor  := 1;
    end if;
  end;

/************************************************************************************
          PROCESSUS  Création Opération Générique
************************************************************************************/
  procedure CreateGenericOperation(
    aSchemaName                  varchar2
  , FalScheduleStepId            number   -- Lien tâche
  , ScsShortDescr                FAL_TASK_LINK.SCS_SHORT_DESCR%type   -- Description courte
  , ScsFreeDescr                 FAL_TASK_LINK.SCS_FREE_DESCR%type   -- Description libre
  , PpsTools1Id                  number   -- Outil 1
  , ScsWorkTime                  FAL_TASK_LINK.SCS_WORK_TIME%type   -- Travail
  , ScsQtyRefWork                FAL_TASK_LINK.SCS_QTY_REF_WORK%type   -- Qté référence travail
  , FalFactoryFloorId            number   -- Atelier
  , CTaskType                    FAL_TASK_LINK.C_TASK_TYPE%type   -- Type de tâche
  , PacSupplierPartnerId         number   -- Fournisseur
  , ScsQtyFixAdjusting           FAL_TASK_LINK.SCS_QTY_FIX_ADJUSTING%type   -- Qté fixe réglage
  , ScsAdjustingTime             FAL_TASK_LINK.SCS_ADJUSTING_TIME%type   -- Réglage
  , TalDueQty                    FAL_TASK_LINK.TAL_DUE_QTY%type   -- Qté Solde
  , ScsPlanProp                  FAL_TASK_LINK.SCS_PLAN_PROP%type   -- Durée proportionnelle
  , ScsPlanRate                  FAL_TASK_LINK.SCS_PLAN_RATE%type   -- Nb unites de cadencement
  , varGcoGoodId                 number
  , DicFreeTaskCodeId            FAL_TASK_LINK.DIC_FREE_TASK_CODE_ID%type   -- Code libre 1
  , ScsTransfertTime             FAL_TASK_LINK.SCS_TRANSFERT_TIME%type   -- Temps de transfert
  , TalBeginPlanDate             FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE%type
  , TalEndPlanDate               FAL_TASK_LINK.TAL_END_PLAN_DATE%type
  , TalBeginRealDate             FAL_TASK_LINK.TAL_BEGIN_REAL_DATE%type
  , TalEndRealDate               FAL_TASK_LINK.TAL_END_REAL_DATE%type
  , TalSubcontractQty            FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type
  , TalReleaseQty                FAL_TASK_LINK.TAL_RELEASE_QTY%type
  , TalTskBalance                FAL_TASK_LINK.TAL_TSK_BALANCE%type
  , aTypeAffect                  varchar2
  , ScsOpenTimeMachine           number
  , DurationOfRealization in out number
  , IsAdjustingOperation  in out boolean
  , NewQtyRefWork         in out number
  , aDoCreateLMU          in out integer
  )
  is
    cursor CUR_PPS_TOOLS(PpsTools1Id number)
    is
      select trim(substr(GOO_MAJOR_REFERENCE, 1, 15) )
        from GCO_GOOD
       where GCO_GOOD_ID = PpsTools1Id;

    vQuery            varchar2(32000);
    FacInfiniteFloor  FAL_FACTORY_FLOOR.FAC_INFINITE_FLOOR%type;
    varLotRefcompl    FAL_LOT.LOT_REFCOMPL%type;
    varScsStepNumber  FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    varIlot           varchar2(10);
    varCodOutill      varchar2(15);
    varMachine        varchar2(10);
    varDurChang       number;
    varDurPrep        number;
    varDurReal        number;
    varTempsTech      number;
    varTHM            number;
    OperationDuration number;
  begin
    IsAdjustingOperation   := false;
    NewQtyRefWork          := null;
    DurationOfRealization  := null;
    -- Recherche de l'îlot (ILOT) et de la machine (MACHINE)
    GetBlockAndMachine(CTaskType, FalFactoryFloorId, PacSupplierPartnerId, varIlot, varMachine, FacInfiniteFloor);

    -- Recherche du Code Outil (CODOUTILL)
    if PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_FUNCTION') is null then
      open CUR_PPS_TOOLS(PpsTools1Id);

      fetch CUR_PPS_TOOLS
       into varCodOutill;

      close CUR_PPS_TOOLS;
    else
      varCodOutill  := GetToolCode(varGcoGoodId);
      Creation_Outils(aSchemaName, varCodOutill, varCodOutill);
    end if;

    if cOrtAdjusting = 2 then
      varCodOutill  := nvl(varCodOutill, ctAdustingTool);
    end if;

    -- Calcul de la durée de changement d'outil
    if CTaskType = '1' then   -- Opération interne
      -- Les opérations qui n'ont que du réglage dans PCS (travail = 0) sont exportées
      -- dans Ortems comme des opérations "standard". Le réglage est exporté en durée de
      -- réalisation et l'opération est en temps technologique. D'où le ScsWorkTime <> 0
      if     (    (cOrtAdjusting = 2)
              or (cOrtAdjusting = 3) )
         and (FacInfiniteFloor = 0)
         and (nvl(ScsWorkTime, 0) <> 0) then
        if nvl(ScsQtyFixAdjusting, 0) = 0 then
          varDurChang  := nvl(ScsAdjustingTime, 0);
        else
          varDurChang  := FAL_TOOLS.RoundSuccInt(nvl(TalDueQty, 0) / ScsQtyFixAdjusting) * nvl(ScsAdjustingTime, 0);
        end if;
      else
        varDurChang  := 0;
      end if;
    else   -- Opération externe
      varDurChang  := 0;
    end if;

    -- Calcul de la durée de préparation
    if    (     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
           and (DicFreeTaskCodeId = ctOpePreparation) )
       or (     (nvl(ScsWorkTime, 0) = 0)
           and (CTaskType = '1') )
       or (FacInfiniteFloor = 1)
       or (    cOrtAdjusting <> 1
           and cOrtAdjusting <> 5)
       or (     (TalBeginRealDate is not null)
           and (TalEndRealDate is null)
           and (    (nvl(TalReleaseQty, 0) = 0)
                or     (nvl(TalReleaseQty, 0) > 0)
                   and (lower(PCS.PC_Config.GetConfig('FAL_WORK_BALANCE') ) = 'true') )
          ) then
      varDurPrep  := 0;
    else   -- On reprend dans Ortems les temps de réglage en temps de préparation
      if nvl(ScsQtyFixAdjusting, 0) = 0 then
        varDurPrep  := nvl(ScsAdjustingTime, 0);
      else
        varDurPrep  := FAL_TOOLS.RoundSuccInt(nvl(TalDueQty, 0) / ScsQtyFixAdjusting) * nvl(ScsAdjustingTime, 0);
      end if;
    end if;

    -- Calcul de la durée de réalisation
    if CTaskType = '1' then   -- Opération interne
      if     (TalBeginRealDate is not null)
         and (TalEndRealDate is null)
         and nvl(TalReleaseQty, 0) = 0 then
        varDurReal     := nvl(TalTskBalance, 0);
        NewQtyRefWork  := TalDueQty;

        if     (ScsPlanRate = 0)
           and nvl(ScsWorkTime, 0) = 0 then
          IsAdjustingOperation  := true;
        end if;
      else
        if DicFreeTaskCodeId = ctOpePreparation then
          varDurReal            := nvl(ScsAdjustingTime, 0);
          IsAdjustingOperation  := true;
        elsif(FacInfiniteFloor = 1) then
          OperationDuration  :=
            FAL_OPERATION_FUNCTIONS.GetDuration(ScsPlanRate             => ScsPlanRate
                                              , ScsPlanProp             => ScsPlanProp
                                              , aQty                    => TalDueQty
                                              , ScsQtyRefWork           => ScsQtyRefWork
                                              , aFalFactoryFloorId      => FalFactoryFloorId
                                              , aPacSupplierPartnerId   => PacSupplierPartnerId
                                              , aTalBeginPlanDate       => TalBeginPlanDate
                                               );

          if bWorkInMinutes then
            OperationDuration  := OperationDuration * 60;
          end if;

          varDurReal         := greatest(OperationDuration, TalTskBalance);

          if     (ScsPlanRate = 0)
             and nvl(ScsWorkTime, 0) = 0 then
            IsAdjustingOperation  := true;
          end if;
        else   -- FacInfiniteFloor = 0 OU Opération d'injection
          if nvl(ScsWorkTime, 0) = 0 then
            if nvl(ScsQtyFixAdjusting, 0) = 0 then
              varDurReal  := nvl(ScsAdjustingTime, 0);
            else
              varDurReal  := FAL_TOOLS.RoundSuccInt(nvl(TalDueQty, 0) / ScsQtyFixAdjusting) * nvl(ScsAdjustingTime, 0);
            end if;

            IsAdjustingOperation  := true;
          else
            varDurReal  := nvl(ScsWorkTime, 0);
          end if;
        end if;
      end if;

      -- Utilisation du temps d'ouverture machine. On calcule la durée de réalisation en foncton de ce temps et de la capacité jour de l'atelier
      if     cUseOpenTimeMachine
         and (ScsOpenTimeMachine > 0) then
        varDurReal  := varDurReal * FAL_TOOLS.GetDayCapacity(FalFactoryFloorId) / ScsOpenTimeMachine;
      end if;

      if bWorkInMinutes then
        varDurReal  := varDurReal / 60;
      end if;
    end if;

    -- Opération externe
    if CTaskType = '2' then
      if     (    (TalBeginRealDate is not null)
              or nvl(TalSubcontractQty, 0) > 0)
         and (TalEndRealDate is null)
         and (TalBeginPlanDate < sysdate) then
        varDurReal  :=
          FAL_PLANIF.GetDurationInMinutes(FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(PacSupplierPartnerId)
                                        , null
                                        , PacSupplierPartnerId
                                        , sysdate
                                        , nvl(TalEndPlanDate, sysdate)
                                         ) /
          60;
      else
        if ScsPlanProp = 1 then
          varDurReal  := (TalDueQty / ScsQtyRefWork) * ScsPlanRate * cPpsRateDay;
        else
          varDurReal  := ScsPlanRate * cPpsRateDay;
        end if;

        -- Calcul de la durée
        varDurReal  := FAL_PLANIF.GetDurationInMinutes(null, PacSupplierPartnerId, varDurReal, TalBeginPlanDate) / 60;
      end if;
    end if;

    -- Temps hors machine pour les opérations de préparation (= temps de transfert)
    varTHM                 := nvl(ScsTransfertTime, 0);

    if bWorkInMinutes then
      varDurChang  := varDurChang / 60;
      varDurPrep   := varDurPrep / 60;
      varTHM       := varTHM / 60;
    end if;

    -- Les temps sont calculés en Heure, on les multiplie par 100 pour travailler en centième
    -- d'heure dans Ortems
    varDurChang            := least(100 * varDurChang, 999999);
    varDurPrep             := greatest(least(100 * varDurPrep, 999999), 0);
    varDurReal             := greatest(least(100 * varDurReal, 9999999), 1);
    varTHM                 := 100 * nvl(varTHM, 0);

    -- Recherche du Temps technologique (TEMPSTECH)
    if    (CTaskType = '2')
       or (FacInfiniteFloor = 1)
       or IsAdjustingOperation then
      varTempsTech  := 1;
    else
      varTempsTech  := 0;
    end if;

    if    IsAdjustingOperation
       or (FacInfiniteFloor = 1)
       or (    CTaskType = '1'   -- Opération interne
           and (TalBeginRealDate is not null)
           and (TalEndRealDate is null)
           and nvl(TalReleaseQty, 0) = 0) then
      DurationOfRealization  := VarDurReal;
    end if;

    if     CTaskType = '1'
       and FacInfiniteFloor = 0 then
      aDoCreateLMU  := 1;
    else
      aDoCreateLMU  := 0;
    end if;

    vQuery                 :=
      ' insert into ' ||
      aSchemaName ||
      '.B_OPE(OPE          ' ||
      '     , ILOT         ' ||
      '     , CODOUTILL    ' ||
      '     , MACHINE      ' ||
      '     , CODEBASET    ' ||
      '     , DESCRIPT1    ' ||
      '     , DURCHANG     ' ||
      '     , DURPREP      ' ||
      '     , DURREAL      ' ||
      '     , LIBOP        ' ||
      '     , TEMPSTECH    ' ||
      '     , UNITE        ' ||
      '     , UNITEPREP    ' ||
      '     , UNITECHGT    ' ||
      '     , INTERUPT     ' ||
      '     , OPE_STANDARD ' ||
      '     , EFFECTMIN    ' ||
      '     , THM          ' ||
      '     , EFFECSTAN    ' ||
      '     , OPE_AFFECT)  ' ||
      'values(:OPE         ' ||
      '     , :ILOT        ' ||
      '     , :CODOUTILL   ' ||
      '     , :MACHINE     ' ||
      '     , :CODEBASET   ' ||
      '     , :DESCRIPT1   ' ||
      '     , :DURCHANG    ' ||
      '     , :DURPREP     ' ||
      '     , :DURREAL     ' ||
      '     , :LIBOP       ' ||
      '     , :TEMPSTECH   ' ||
      '     , ''C''        ' ||
      '     , ''C''        ' ||
      '     , ''C''        ' ||
      '     , 1            ' ||
      '     , 1            ' ||
      '     , 0            ' ||
      '     , :THM         ' ||
      '     , 0            ' ||
      '     , :OPE_AFFECT)';

    execute immediate vQuery
                using FalScheduleStepId
                    , varIlot
                    , varCodOutill
                    , varMachine
                    , greatest(nvl(NewQtyRefWork, ScsQtyRefWork), 1)
                    , trim(substr(ScsFreeDescr, 1, 50) )
                    , varDurChang
                    , varDurPrep
                    , varDurReal
                    , trim(substr(ScsShortDescr, 1, 15) )
                    , varTempsTech
                    , varTHM
                    , aTypeAffect;
  exception
    when ex.PARENT_KEY_NOT_FOUND then
      if instr(DBMS_UTILITY.FORMAT_ERROR_STACK, 'FK1_B_OPE') <> 0 then
        if nvl(FalScheduleStepId, 0) <> 0 then
          select lot_refcompl
               , scs_step_number
            into VarLotRefcompl
               , VarScsStepNumber
            from fal_lot fl
               , fal_task_link ftl
           where fl.fal_lot_id = ftl.fal_lot_id
             and ftl.fal_schedule_step_id = FalScheduleStepId
          union
          select fl.c_prefix_prop || fl.lot_number
               , scs_step_number
            from fal_lot_prop fl
               , fal_task_link_prop ftl
           where fl.fal_lot_prop_id = ftl.fal_lot_prop_id
             and ftl.fal_task_link_prop_id = FalScheduleStepId;
        end if;

        RAISE_APPLICATION_ERROR(-20000
                              , 'Machine group ''' || varIlot || ''' doesn''t exist (operation ' || VarScsStepNumber || ', batch no. ' || VarLotRefcompl || ').'
                               );
      else
        raise;
      end if;
    when others then
      if nvl(FalScheduleStepId, 0) <> 0 then
        select lot_refcompl
             , scs_step_number
          into VarLotRefcompl
             , VarScsStepNumber
          from fal_lot fl
             , fal_task_link ftl
         where fl.fal_lot_id = ftl.fal_lot_id
           and ftl.fal_schedule_step_id = FalScheduleStepId
        union
        select fl.c_prefix_prop || fl.lot_number
             , scs_step_number
          from fal_lot_prop fl
             , fal_task_link_prop ftl
         where fl.fal_lot_prop_id = ftl.fal_lot_prop_id
           and ftl.fal_task_link_prop_id = FalScheduleStepId;

        if (VarIlot is null) then
          Raise_Application_Error(-20000, 'No workshop for operation ' || VarScsStepNumber || ', batch no. ' || VarLotRefcompl);
        else
          Raise_Application_Error(-20000
                                , 'Problem for operation ' || VarScsStepNumber || ', batch no. ' || VarLotRefcompl || chr(10) || DBMS_UTILITY.FORMAT_ERROR_STACK
                                 );
        end if;
      end if;

      raise;
  end;

/*************************************************************************************
           PROCESSUS  Création Liste Machine Utilisable (B_CADE)
*************************************************************************************/
  procedure Creation_LMU(
    NomSchema            varchar2
  , FalScheduleStepId    number
  , Ilot                 varchar2
  , Machine              varchar2
  , varDurReal           number
  , FTLU_ScsQtyRefWork   FAL_TASK_LINK_USE.SCS_QTY_REF_WORK%type
  , FTLU_ScsPriority     FAL_TASK_LINK_USE.SCS_PRIORITY%type
  , FTLU_ScsExceptMach   FAL_TASK_LINK_USE.SCS_EXCEPT_MACH%type
  , NbreOperateursReg    FAL_TASK_LINK.SCS_NUM_ADJUST_OPERATOR%type
  , NbreOperateursTr     FAL_TASK_LINK.SCS_NUM_WORK_OPERATOR%type
  , IsAdjustingOperation boolean
  )
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         :=
      'INSERT INTO ' ||
      NomSchema ||
      '.B_CADE(OPE, ILOT, MACHINE, CADE_DURREAL, CADE_CODEBASET, CADE_PRIORITE, CADE_EXCEPTION, CADE_UNITE, CADE_EFFECSTAN, CADE_EFFECTMIN) ';
    BuffSQL         :=
      BuffSQL ||
      'VALUES(:vOPE, :vILOT, :vMACHINE, :vCADE_DURREAL, :vCADE_CODEBASET, :vCADE_PRIORITE, :vCADE_EXCEPTION, :vCADE_UNITE, :vCADE_EFFECSTAN, :vCADE_EFFECTMIN)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vOPE', FalScheduleStepId);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vILOT', trim(Ilot) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vMACHINE', trim(Machine) );

    if VarDurReal < 1 then
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_DURREAL', 1);
    else
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_DURREAL', VarDurReal);
    end if;

    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_CODEBASET', nvl(FTLU_ScsQtyRefWork, 1) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_PRIORITE', nvl(FTLU_ScsPriority, 0) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_EXCEPTION', nvl(FTLU_ScsExceptMach, 0) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_UNITE', 'C');

    if    IsAdjustingOperation
       or (VarDurReal = 0) then
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_EFFECSTAN', NbreOperateursReg);
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_EFFECTMIN', 0);
    else
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_EFFECSTAN', NbreOperateursTr);
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCADE_EFFECTMIN', NbreOperateursReg);
    end if;

    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when dup_val_on_index then
      null;
    when ex.PARENT_KEY_NOT_FOUND then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);

      if instr(DBMS_UTILITY.FORMAT_ERROR_STACK, 'FK2_B_CADE') <> 0 then
        RAISE_APPLICATION_ERROR(-20000, 'Machine ''' || Machine || ''' doesn''t exist.');
      else
        raise;
      end if;
    when others then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
      raise;
  end;

/*************************************************************************************
       PROCESSUS  Creation Qualification par Machine (B_AFQU)
*************************************************************************************/
  procedure Create_Qualif_par_Machine(NomSchema varchar2, Ilot varchar2, Machine varchar2, Qualif varchar2, TypeAffectation number, NbreRessources number)
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'INSERT INTO ' || NomSchema || '.B_AFQU(QUALIF, ILOT, MACHINE, AFQU_CODEAFFEC, AFQU_EFFECTMIN, AFQU_EFFECTREG, AFQU_EFFECTMAX) ';
    BuffSQL         := BuffSQL || 'VALUES(:vQUALIF, :vILOT, :vMACHINE, :vAFQU_CODEAFFEC, :vAFQU_EFFECTMIN, :vAFQU_EFFECTREG, :vAFQU_EFFECTMAX)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vQUALIF', Qualif);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vILOT', trim(Ilot) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vMACHINE', trim(Machine) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vAFQU_CODEAFFEC', TypeAffectation);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vAFQU_EFFECTMIN', 0);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vAFQU_EFFECTREG', 0);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vAFQU_EFFECTMAX', NbreRessources);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when dup_val_on_index then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

/*************************************************************************************
       PROCESSUS  Creation Qualification par Machine Utilisable (B_AFCA)
*************************************************************************************/
  procedure Creation_Qualification_par_LMU(
    aSchemaName          varchar2
  , FalScheduleStepId    number
  , Ilot                 varchar2
  , Machine              varchar2
  , Qualif               varchar2
  , TypeOperation        FAL_TASK_LINK.DIC_FREE_TASK_CODE_ID%type
  , NbreOperateursReg    FAL_TASK_LINK.SCS_NUM_ADJUST_OPERATOR%type
  , NbreOperateursTr     FAL_TASK_LINK.SCS_NUM_WORK_OPERATOR%type
  , NbreRessources       number
  , aWorkTime            number
  , IsAdjustingOperation boolean
  )
  is
    vQuery           varchar2(32000);
    TypeAffectation  number;
    EffectMinFab     number;
    EffectReglage    number;
    varLotRefcompl   FAL_LOT.LOT_REFCOMPL%type;
    varScsStepNumber FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    if    (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
       or (aWorkTime = 0)
       or IsAdjustingOperation then
      TypeAffectation  := 0;   -- Fabrication

      if    (TypeOperation = ctOpePreparation)
         or (aWorkTime = 0)
         or IsAdjustingOperation then
        EffectMinFab  := NbreOperateursReg;
      else
        EffectMinFab  := NbreOperateursTr;
      end if;

      EffectReglage    := 0;
    else
      if NbreOperateursReg = 0 then
        TypeAffectation  := 0;   -- Fabrication
      elsif NbreOperateursTr = 0 then
        TypeAffectation  := 1;   -- Réglage
      else
        TypeAffectation  := 2;   -- Fabrication + Réglage
      end if;

      EffectMinFab   := NbreOperateursTr;
      EffectReglage  := NbreOperateursReg;
    end if;

    vQuery  :=
      ' insert into ' ||
      aSchemaName ||
      '  .B_AFCA(OPE, ILOT, MACHINE, QUALIF, AFCA_CODEAFFEC, AFCA_EFFECTMIN, AFCA_EFFECTREG, AFCA_EFFECTMAX) ' ||
      '   values(:vOPE, :vILOT, :vMACHINE, :vQUALIF, :vAFCA_CODEAFFEC, :vAFCA_EFFECTMIN, :vAFCA_EFFECTREG, :vAFCA_EFFECTMAX)';

    execute immediate vQuery
                using FalScheduleStepId, trim(Ilot), trim(Machine), Qualif, TypeAffectation, EffectMinFab, EffectReglage, NbreRessources;

    Create_Qualif_par_Machine(aSchemaName, Ilot, Machine, Qualif, TypeAffectation, NbreRessources);
  exception
    when dup_val_on_index then
      null;
    when others then
      if nvl(FalScheduleStepId, 0) <> 0 then
        select lot_refcompl
             , scs_step_number
          into VarLotRefcompl
             , VarScsStepNumber
          from fal_lot fl
             , fal_task_link ftl
         where fl.fal_lot_id = ftl.fal_lot_id
           and ftl.fal_schedule_step_id = FalScheduleStepId
        union
        select fl.c_prefix_prop || fl.lot_number
             , scs_step_number
          from fal_lot_prop fl
             , fal_task_link_prop ftl
         where fl.fal_lot_prop_id = ftl.fal_lot_prop_id
           and ftl.fal_task_link_prop_id = FalScheduleStepId;

        Raise_Application_Error(-20000
                              , 'Error inserting LMU Qualification (B_AFCA) for operation ' ||
                                VarScsStepNumber ||
                                ', batch no. ' ||
                                VarLotRefcompl ||
                                chr(10) ||
                                DBMS_UTILITY.FORMAT_ERROR_STACK
                               );
      end if;

      raise;
  end;

  procedure Creation_LMU_et_Qualif(
    NomSchema              varchar2
  , FalScheduleStepId      number   -- Opération
  , FTLU_FalFactoryFloorId number   -- Machine
  , FTLU_ScsWorkTime       FAL_TASK_LINK_USE.SCS_WORK_TIME%type
  , FTLU_ScsQtyRefWork     FAL_TASK_LINK_USE.SCS_QTY_REF_WORK%type
  , FTLU_ScsPriority       FAL_TASK_LINK_USE.SCS_PRIORITY%type
  , FTLU_ScsExceptMach     FAL_TASK_LINK_USE.SCS_EXCEPT_MACH%type
  , OperatorId             number
  , CreateQualif           boolean
  , TypeOeration           FAL_TASK_LINK.DIC_FREE_TASK_CODE_ID%type
  , NbreOperateursReg      FAL_TASK_LINK.SCS_NUM_ADJUST_OPERATOR%type
  , NbreOperateursTr       FAL_TASK_LINK.SCS_NUM_WORK_OPERATOR%type
  , DurationOfRealization  number
  , IsAdjustingOperation   boolean
  , NewQtyRefWork          number
  , ScsOpenTimeMachine     number
  )
  is
    cursor CUR_FAL_FACTORY_FLOOR(FalFactoryFloorId number)
    is
      select FAC_REFERENCE
           , FAC_RESOURCE_NUMBER
        from FAL_FACTORY_FLOOR
       where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId;

    cursor CUR_ILOT(FalFactoryFloorId number)
    is
      select substr(ILOT.FAC_REFERENCE, 1, 10)
        from FAL_FACTORY_FLOOR ILOT
           , FAL_FACTORY_FLOOR MACHINE
       where ILOT.FAL_FACTORY_FLOOR_ID = MACHINE.FAL_FAL_FACTORY_FLOOR_ID
         and MACHINE.FAL_FACTORY_FLOOR_ID = FalFactoryFloorId;

    Ilot              varchar2(10);
    Machine           FAL_FACTORY_FLOOR.FAC_REFERENCE%type;
    varDurReal        number;
    Qualif            FAL_FACTORY_FLOOR.FAC_REFERENCE%type;
    FacResourceNumber FAL_FACTORY_FLOOR.FAC_RESOURCE_NUMBER%type;
  begin
    open CUR_FAL_FACTORY_FLOOR(FTLU_FalFactoryFloorId);

    fetch CUR_FAL_FACTORY_FLOOR
     into Machine
        , FacResourceNumber;

    close CUR_FAL_FACTORY_FLOOR;

    open CUR_ILOT(FTLU_FalFactoryFloorId);

    fetch CUR_ILOT
     into Ilot;

    -- Si on a pas trouvé d'îlot, la machine est sur un îlot de même nom que la machine
    if CUR_ILOT%notfound then
      Ilot  := substr(Machine, 1, 10);
    end if;

    close CUR_ILOT;

    -- Calcul de la durée de réalisation
    varDurReal  := nvl(FTLU_ScsWorkTime, 0);

    -- Utilisation du temps d'ouverture machine. On calcule la durée de réalisation en foncton de ce temps et de la capacité jour de l'atelier
    if     cUseOpenTimeMachine
       and (ScsOpenTimeMachine > 0) then
      varDurReal  := varDurReal * FAL_TOOLS.GetDayCapacity(FTLU_FalFactoryFloorId) / ScsOpenTimeMachine;
    end if;

    if bWorkInMinutes then
      varDurReal  := varDurReal / 60;
    end if;

    -- Les temps sont calculés en Heure, on les multiplie par 100 pour travailler en centième
    -- d'heure dans Ortems
    varDurReal  := 100 * varDurReal;
    Creation_LMU(NomSchema
               , FalScheduleStepId   -- Opération
               , Ilot
               , substr(Machine, 1, 10)
               , nvl(DurationOfRealization, varDurReal)
               , nvl(NewQtyRefWork, FTLU_ScsQtyRefWork)
               , FTLU_ScsPriority
               , FTLU_ScsExceptMach
               , NbreOperateursReg
               , NbreOperateursTr
               , IsAdjustingOperation
                );

    if     (CreateQualif = true)
       and (OperatorId is not null) then
      open CUR_FAL_FACTORY_FLOOR(OperatorId);

      fetch CUR_FAL_FACTORY_FLOOR
       into Qualif
          , FacResourceNumber;

      close CUR_FAL_FACTORY_FLOOR;

      Creation_Qualification_par_LMU(NomSchema
                                   , FalScheduleStepId
                                   , Ilot
                                   , substr(Machine, 1, 10)
                                   , substr(Qualif, 1, 10)
                                   , TypeOeration
                                   , NbreOperateursReg
                                   , NbreOperateursTr
                                   , FacResourceNumber
                                   , nvl(DurationOfRealization, varDurReal)
                                   , IsAdjustingOperation
                                    );
    end if;
  end;

/*************************************************************************************
           PROCESSUS  Création phase (B_PHAS)
*************************************************************************************/
  procedure Creation_Phase(
    aSchemaName       varchar2
  , varLotRefcompl    FAL_LOT.LOT_REFCOMPL%type   -- Gamme
  , ScsStepNumber     char   -- Numéro de phase (Séquence)
  , FalScheduleStepId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type   -- Opération générique
  , ScsShortDescr     FAL_TASK_LINK.SCS_SHORT_DESCR%type   -- Libellé de la phase (Description courte)
  )
  is
    vQuery varchar2(32000);
  begin
    vQuery  :=
      ' insert into ' ||
      aSchemaName ||
      '.B_PHAS            ' ||
      '       (NOMG       ' ||
      '      , NOPHASE    ' ||
      '      , OPE        ' ||
      '      , LIBPHASE   ' ||
      '      , INTENSITE) ' ||
      ' values(:vNOMG     ' ||
      '      , :vNOPHASE  ' ||
      '      , :vOPE      ' ||
      '      , :vLIBPHASE ' ||
      '      , 100)       ';

    execute immediate vQuery
                using trim(substr(varLotRefcompl, 1, 30) ), ScsStepNumber, FalScheduleStepId, trim(substr(ScsShortDescr, 1, 15) );
  end;

  /**
   * procedure : CreateOperationLink
   * Description : Création des liens entre opérations (lien phase Ortems (B_PREC)
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     aSchemaName           : Nom du schéma Ortems
   * @param     aGamme                : Gamme des opérations
   * @param     aStartPhase           : Phase (opération) de départ
   * @param     aStopPhase            : Phase d'arrivée
   * @param     aCRelationType        : Type de lien entre opérations
   * @param     aScsDelay             : Délai
   * @param     aDicFreeTaskCodeId    : Code libre de l'opération d'arrivée
   * @param     aOpePrecDePreparation : Défini si l'opération de départ est une opération de préparation
   * @param     aPreviousWorkDone     : Travail effectué sur l'opération de départ
   */
  procedure CreateOperationLink(
    aSchemaName           varchar2
  , aGamme                FAL_LOT.LOT_REFCOMPL%type
  , aStartPhase           char   -- Phase de départ
  , aStopPhase            char   -- Phase d'arrivée (Séquence)
  , aCRelationType        FAL_TASK_LINK.C_RELATION_TYPE%type   -- Code relation
  , aScsDelay             FAL_TASK_LINK.SCS_DELAY%type   -- Retard
  , aDicFreeTaskCodeId    FAL_TASK_LINK.DIC_FREE_TASK_CODE_ID%type
  , aOpePrecDePreparation boolean
  , aPreviousWorkDone     FAL_TASK_LINK.TAL_ACHIEVED_TSK%type default 0
  )
  is
    vQuery     varchar2(32000);
    vTypePrec  char(1);
    vPropPrec  char(2);
    vTauxCheva FAL_TASK_LINK.SCS_DELAY%type;
  begin
    vTauxCheva  := 0;
    vPropPrec   := null;

    -- Initialisation du type de précédence (TYPEPREC) et de la Propriété de la précédence (PROPPREC)
    if    (     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
           and aDicFreeTaskCodeId = ctOpeInjection
           and aOpePrecDePreparation)
       or aCRelationType = '3' then
      vTypePrec  := 'S';   -- Lien solide
    elsif aCRelationType = '1' then
      vTypePrec  := 'T';   -- Successeur (précédence totale)
    elsif aCRelationType = '2' then
      -- Parallèle (chevauchement), taux de chevauchement à partir d'une durée
      vTypePrec  := 'O';
      vPropPrec  := 'OH';
    elsif aCRelationType = '4' then
      -- Parallèle - chevauchement par quantité, sans contrainte de fin
      vTypePrec   := 'O';
      vPropPrec   := 'DQ';
      vTauxCheva  := 1;
    elsif aCRelationType = '5' then
      vTypePrec  := 'D';   -- Synchronisation début-début
      vPropPrec  := 'OH';
    end if;

    if vPropPrec = 'OH' then
      -- Calcul pour un taux de chevauchement à partir d'une durée
      vTauxCheva  := greatest( (aScsDelay - aPreviousWorkDone) * 100, 0);
    end if;

    vQuery      :=
      ' insert into ' ||
      aSchemaName ||
      '.B_PREC(NOMG        ' ||
      '      , NOPHASE     ' ||
      '      , B_P_NOMG    ' ||
      '      , B_P_NOPHASE ' ||
      '      , TYPEPREC    ' ||
      '      , PROPPREC    ' ||
      '      , TAUXCHEVA)  ' ||
      ' values(:NOMG       ' ||
      '      , :NOPHASE    ' ||
      '      , :B_P_NOMG   ' ||
      '      , :B_P_NOPHASE' ||
      '      , :TYPEPREC   ' ||
      '      , :PROPPREC   ' ||
      '      , :TAUXCHEVA) ';

    execute immediate vQuery
                using trim(substr(aGamme, 1, 30) ), aStartPhase, trim(substr(aGamme, 1, 30) ), aStopPhase, vTypePrec, vPropPrec, vTauxCheva;
  end;

/*************************************************************************************
           PROCESSUS  Création version (B_VER_ART)
*************************************************************************************/
  procedure Creation_Version(NomSchema varchar2, Article varchar2, VersionArticle varchar2, varLotRefCompl FAL_LOT.LOT_REFCOMPL%type)
  is   -- Gamme
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'INSERT INTO ' || NomSchema || '.B_VER_ART(CODEARTIC, VER_ART, VER_EFFET_DEBUT, VER_EFFET_FIN, NOMG, LOI_CALCUL) ';
    BuffSQL         := BuffSQL || 'VALUES(:vCODEARTIC, :vVER_ART, :vVER_EFFET_DEBUT, :vVER_EFFET_FIN, :vNOMG, :vLOI_CALCUL)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCODEARTIC', Article);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vVER_ART', VersionArticle);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vVER_EFFET_DEBUT', to_date('01/01/1995', 'DD/MM/YYYY') );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vVER_EFFET_FIN', to_date('01/01/2050', 'DD/MM/YYYY') );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vNOMG', trim(substr(varLotRefCompl, 1, 30) ) );
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vLOI_CALCUL', 'C');
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when others then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  /**
  * procedure CreateParameterValue
  * Description
  *   Création valeur de paramètre (B_PART)
  * @author CLE
  * @param   aSchemaName       Schéma d'export Ortems
  * @param   aProduct          Produit (nom de l'article)
  * @param   aProductVersion   Version d'article
  * @param   aProcessPlanName  Gamme opératoire
  * @param   aPhase            Phase de l'opération
  * @param   aTypeMat          Matrice de paramètre
  * @param   aParameter        Paramètre
  */
  procedure CreateParameterValue(
    aSchemaName      varchar2
  , aProduct         varchar2
  , aProductVersion  varchar2
  , aProcessPlanName varchar2
  , aPhase           char
  , aTypeMat         varchar2
  , aParameter       varchar2
  )
  is
    vQuery varchar2(32000);
  begin
    if aParameter is not null then
      vQuery  :=
        ' insert into ' ||
        aSchemaName ||
        '.B_PART(CODEARTIC       ' ||
        '      , VER_ART         ' ||
        '      , VER_EFFET_DEBUT ' ||
        '      , VER_EFFET_FIN   ' ||
        '      , NOMG            ' ||
        '      , NOPHASE         ' ||
        '      , TYPEMAT         ' ||
        '      , B_P_TYPEMAT     ' ||
        '      , PARAMETRE)      ' ||
        'values(:CODEARTIC       ' ||
        '     , :VER_ART         ' ||
        '     , to_date(''01/01/1995'', ''DD/MM/YYYY'') ' ||
        '     , to_date(''01/01/2050'', ''DD/MM/YYYY'') ' ||
        '     , :NOMG            ' ||
        '     , :NOPHASE         ' ||
        '     , :TYPEMAT         ' ||
        '     , :B_P_TYPEMAT     ' ||
        '     , :PARAMETRE)';

      execute immediate vQuery
                  using aProduct
                      , aProductVersion
                      , trim(substr(aProcessPlanName, 1, 30) )
                      , aPhase
                      , trim(substr(aTypeMat, 1, 15) )
                      , trim(substr(aTypeMat, 1, 15) )
                      , trim(substr(aParameter, 1, 15) );
    end if;
  end;

  /**
  * procedure GetParticularity
  * Description
  *   Recherche de l'information à afficher dans le champ "particularité" des OF Ortems
  * @author CLE
  * @param   LotOrPropId  Id de lot ou de proposition
  * @param   aIsBatch     Indique si on est sur un lot ou une proposition
  */
  function GetParticularity(aFalLotOrPropId number, aIsBatch boolean)
    return varchar2
  is
    vParticularity varchar2(40);
  begin
    vParticularity  := null;

    if to_number(PCS.PC_Config.GetConfig('FAL_ORT_VIEW_PARTIC') ) = 1 then
      if aIsBatch then
        -- On va chercher le besoin initial
        select max(trim(substr(DMT_NUMBER, 1, 40) ) )
          into vParticularity
          from DOC_DOCUMENT DD
             , FAL_ORDER FO
             , FAL_LOT FL
         where FO.DOC_DOCUMENT_ID = DD.DOC_DOCUMENT_ID
           and FL.FAL_ORDER_ID = FO.FAL_ORDER_ID
           and FAL_LOT_ID = aFalLotOrPropId;

        -- Si Null, on prend le besoin initial 1
        if vParticularity is null then
          vParticularity  := trim(substr(FAL_TOOLS.GetInitNeedListFromLotID(aFalLotOrPropId, ', '), 1, 40) );
        end if;
      else
        -- Recherche du besoin initial de la proposition
        vParticularity  := trim(substr(FAL_TOOLS.GetInitNeedListFromLotPropID(aFalLotOrPropId, ', '), 1, 40) );
      end if;

      if instr(vParticularity, '$$$', 1) <> 0 then
        vParticularity  := substr(vParticularity, 1, instr(vParticularity, '$$$', 1) - 1);
      end if;
    elsif to_number(PCS.PC_Config.GetConfig('FAL_ORT_VIEW_PARTIC') ) = 2 then
      --No de la commande fournisseur définissant le délai au plus tôt au lieu de du besoin initial
      select max(trim(substr(DOC1.DMT_NUMBER || '/' || DOC2.POS_NUMBER, 1, 40) ) )
        into vParticularity
        from DOC_DOCUMENT DOC1
           , DOC_POSITION DOC2
           , DOC_POSITION_DETAIL DOC3
           , FAL_NETWORK_SUPPLY FAL1
           , (select max(FNL.FAL_NETWORK_SUPPLY_ID) FAL_NETWORK_SUPPLY_ID
                from FAL_NETWORK_LINK FNL
                   , FAL_NETWORK_NEED FNN
                   , FAL_NETWORK_SUPPLY FNS
                   , (select max(FLN_SUPPLY_DELAY) FLN_SUPPLY_DELAY
                        from FAL_NETWORK_LINK FNL
                           , FAL_NETWORK_NEED FNN
                           , FAL_NETWORK_SUPPLY FNS
                       where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                         and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                         and FNS.DOC_POSITION_DETAIL_ID is not null
                         and (   FNN.FAL_LOT_ID = aFalLotOrPropId
                              or FNN.FAL_LOT_PROP_ID = aFalLotOrPropId) ) R1
               where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                 and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                 and FNS.DOC_POSITION_DETAIL_ID is not null
                 and (   FNN.FAL_LOT_ID = aFalLotOrPropId
                      or FNN.FAL_LOT_PROP_ID = aFalLotOrPropId)
                 and FNL.FLN_SUPPLY_DELAY = R1.FLN_SUPPLY_DELAY) R0
       where DOC1.DOC_DOCUMENT_ID = DOC2.DOC_DOCUMENT_ID
         and DOC2.DOC_POSITION_ID = DOC3.DOC_POSITION_ID
         and DOC3.DOC_POSITION_DETAIL_ID = FAL1.DOC_POSITION_DETAIL_ID
         and FAL1.FAL_NETWORK_SUPPLY_ID = R0.FAL_NETWORK_SUPPLY_ID;
    end if;

    return vParticularity;
  end;

/*************************************************************************************
           PROCESSUS  Création OF (B_OF)
*************************************************************************************/
  procedure CreateBatch(
    aSchemaName         varchar2
  , varLotRefCompl      FAL_LOT.LOT_REFCOMPL%type
  , varLotShortDescr    FAL_LOT.LOT_SHORT_DESCR%type
  , varFalLotId         number
  , Article             varchar2
  , VersionArticle      varchar2
  , Delai               FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type
  , varLotInprodQty     FAL_LOT.LOT_INPROD_QTY%type
  , CodeGestion         varchar2   -- Code gestion (F pour les OF, P pour les POF)
  , LotPlanBasisEndDate FAL_LOT.LOT_PLAN_END_DTE%type
  , aCFabType           FAL_LOT.C_FAB_TYPE%type
  )
  is
    vQuery        varchar2(32000);
    Particularity varchar2(40);
    ldDelayMin    date;
  begin
    Particularity  := trim(substr(GetParticularity(varFalLotId,(CodeGestion = 'F') ), 1, 40) );
    vQuery         :=
      ' insert into ' ||
      aSchemaName ||
      '.B_OF(NOF               ' ||
      '    , LIBEOF            ' ||
      '    , OF_CH_DESC1       ' ||
      '    , SERIE             ' ||
      '    , CODEARTIC         ' ||
      '    , VER_ART           ' ||
      '    , VER_EFFET_DEBUT   ' ||
      '    , VER_EFFET_FIN     ' ||
      '    , NOMG              ' ||
      '    , DPLUSTOT          ' ||
      '    , FPLUSTARD         ' ||
      '    , QTE               ' ||
      '    , ETATOF            ' ||
      '    , CODEGEST          ' ||
      '    , PRIORITE          ' ||
      '    , CODEGROUP         ' ||
      '    , PARTIC            ' ||
      '    , FREE1)            ' ||
      'values(:NOF             ' ||
      '     , :LIBEOF          ' ||
      '     , :OF_CH_DESC1     ' ||
      '     , :SERIE           ' ||
      '     , :CODEARTIC       ' ||
      '     , :VER_ART         ' ||
      '     , :VER_EFFET_DEBUT ' ||
      '     , :VER_EFFET_FIN   ' ||
      '     , :NOMG            ' ||
      '     , :DPLUSTOT        ' ||
      '     , :FPLUSTARD       ' ||
      '     , :QTE             ' ||
      '     , ''S''            ' ||
      '     , :CODEGEST        ' ||
      '     , 1                ' ||
      '     , ''00''           ' ||
      '     , :PARTIC          ' ||
      '     , nvl(:FREE1, ''0'')) ';

    execute immediate vQuery
                using trim(substr(varLotRefCompl, 1, 30) )
                    , trim(substr(varLotShortDescr, 1, 25) )
                    , varFalLotId
                    , Article
                    , Article
                    , VersionArticle
                    , to_date('01/01/1995', 'DD/MM/YYYY')
                    , to_date('01/01/2050', 'DD/MM/YYYY')
                    , trim(substr(varLotRefCompl, 1, 30) )
                    , nvl(Delai, sysdate)
                    , nvl(LotPlanBasisEndDate, sysdate)
                    , varLotInprodQty
                    , CodeGestion
                    , Particularity
                    , aCFabType;

    if cInitLatestEndDate = 2 then
      ldDelayMin  := InitialRequirementManagement(aSchemaName, varLotRefCompl, varFalLotId);

      if ldDelayMin is not null then
        execute immediate 'update ' || aSchemaName || '.B_OF set FPLUSTARD = :FPLUSTARD where NOF = :NOF '
                    using ldDelayMin, trim(substr(varLotRefCompl, 1, 30) );
      end if;
    end if;
  exception
    when others then
      Raise_Application_Error(-20000, 'Problem for batch no. ' || varLotRefCompl || chr(10) || DBMS_UTILITY.FORMAT_ERROR_STACK);
  end;

/*************************************************************************************
           PROCESSUS  Création Réservation de ressource limitée (RSV_RES)
*************************************************************************************/
  procedure Creation_Reservation_Ressource(NomSchema varchar2, CodeRessource varchar2, Gamme varchar2, PhaseDepart char, PhaseArrivee char, NbreTools number)
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'INSERT INTO ' || NomSchema || '.RSV_RES(CODELIMI, B_P_NOMG, B_P_NOPHASE, NOMG, NOPHASE, RSV_NBLIMI) ';
    BuffSQL         := BuffSQL || 'VALUES(:vCODELIMI, :vB_P_NOMG, :vB_P_NOPHASE, :vNOMG, :vNOPHASE, :vRSV_NBLIMI) ';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCODELIMI', CodeRessource);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vB_P_NOMG', Gamme);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vB_P_NOPHASE', PhaseArrivee);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vNOMG', Gamme);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vNOPHASE', PhaseDepart);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vRSV_NBLIMI', NbreTools);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when others then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

/*************************************************************************************
   PROCESSUS  Besoins en Ressources Limitées par Opération (B_OPLI)
*************************************************************************************/
  procedure Creation_Besoin_Ress_Limi_Ope(aSchemaName varchar2, FalScheduleStepId number, CodeRessource varchar2, NbreTools number)
  is
    vQuery varchar2(32000);
  begin
    vQuery  :=
      ' insert into ' ||
      aSchemaName ||
      '.B_OPLI              ' ||
      '       (OPE          ' ||
      '      , CODELIMI     ' ||
      '      , OPE_NBLIMI)  ' ||
      ' values(:vOPE        ' ||
      '      , :vCODELIMI   ' ||
      '      , :vOPE_NBLIMI)';

    execute immediate vQuery
                using FalScheduleStepId, CodeRessource, NbreTools;
  end;

  function Add_Tools_On_String(ToolsString varchar2, ToolsId number)
    return varchar2
  is
    result           varchar2(500);
    DebutToolsString varchar2(500);
    FinToolsString   varchar2(500);
    NbreTools        number;
  begin
    result  := ToolsString;

    if ToolsId is not null then
      if instr(ToolsString, 'ID' || ToolsId || ';') <> 0 then
        DebutToolsString  := substr(ToolsString, 1, instr(ToolsString, 'ID' || ToolsId || ';') - 1);
        FinToolsString    := substr(ToolsString, instr(ToolsString, 'ID' || ToolsId || ';') + length('ID' || ToolsId || ';') );
        NbreTools         := substr(FinToolsString, 1, instr(FinToolsString, ';') - 1) + 1;
        result            := DebutToolsString || 'ID' || ToolsId || ';' || NbreTools || substr(FinToolsString, instr(FinToolsString, ';') );
      else
        result  := ToolsString || 'ID' || ToolsId || ';1;';
      end if;
    end if;

    return result;
  end;

  procedure Reservation_Ress_Limitees(
    NomSchema         varchar2
  , Gamme             varchar2
  , FalScheduleStepId number   -- Opération
  , FalTaskLinkPropId number
  , PhaseDepart       char
  , PhaseArrivee      char
  )
  is
    -- Déclaration des curseurs

    -- Attention : Les deux curseurs ci-dessous doivent retourner les mêmes enregistrements
    --             en raison du fetch dans la même variable.
    cursor CUR_TOOLS_OPE(FalScheduleStepId number)
    is
      select PPS_TOOLS1_ID
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
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = FalScheduleStepId;

    cursor CUR_TOOLS_PROP(FalTaskLinkPropId number)
    is
      select PPS_TOOLS1_ID
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
        from FAL_TASK_LINK_PROP
       where FAL_TASK_LINK_PROP_ID = FalTaskLinkPropId;

    cursor crTool(ToolId number)
    is
      select nvl(TLS_PLANNING_CODE, 0) PLANNING_CODE
           , substr(GOO_MAJOR_REFERENCE, 1, 20) MAJOR_REFERENCE
        from PPS_TOOLS PT
           , GCO_GOOD GG
       where PT.GCO_GOOD_ID = GG.GCO_GOOD_ID
         and PT.GCO_GOOD_ID = ToolId;

    -- Déclaration des variables
    CurTOOLS    CUR_TOOLS_OPE%rowtype;
    ToolsString varchar2(500);
    ToolsId     number;
    NbreTools   number;
    tplTool     crTool%rowtype;
  begin
    if FalTaskLinkPropId is null then
      open CUR_TOOLS_OPE(FalScheduleStepId);

      fetch CUR_TOOLS_OPE
       into CurTOOLS;

      close CUR_TOOLS_OPE;
    else
      open CUR_TOOLS_PROP(FalTaskLinkPropId);

      fetch CUR_TOOLS_PROP
       into CurTOOLS;

      close CUR_TOOLS_PROP;
    end if;

    ToolsString  := '';
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS1_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS2_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS3_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS4_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS5_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS6_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS7_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS8_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS9_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS10_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS11_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS12_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS13_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS14_ID);
    ToolsString  := Add_Tools_On_String(ToolsString, CurTOOLS.PPS_TOOLS15_ID);

    while substr(ToolsString, 1, 2) = 'ID' loop
      ToolsId      := substr(ToolsString, 3, instr(ToolsString, ';') - 3);
      ToolsString  := substr(ToolsString, instr(ToolsString, ';') + 1);
      NbreTools    := substr(ToolsString, 1, instr(ToolsString, ';') - 1);
      ToolsString  := substr(ToolsString, instr(ToolsString, ';') + 1);

      open crTool(ToolsId);

      fetch crTool
       into tplTool;

      close crTool;

      if (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1') then
        Creation_Reservation_Ressource(NomSchema, tplTool.MAJOR_REFERENCE, Gamme, PhaseDepart, PhaseArrivee, NbreTools);
      elsif tplTool.PLANNING_CODE = 1 then
        Creation_Besoin_Ress_Limi_Ope(NomSchema, nvl(FalScheduleStepId, FalTaskLinkPropId), tplTool.MAJOR_REFERENCE, NbreTools);
      end if;
    end loop;
  end;

  function CheckDelay(GcoGoodId number)
    return integer
  is
  begin
    if GetDelay(GcoGoodId) <> -1 then
      return 1;
    else
      return 0;
    end if;
  end checkDelay;

  function GetDelay(GcoGoodId number)
    return number
  is
    cursor CUR_FREE_DATA(GcoGoodId number)
    is
      select FCO_NUM_CODE
        from GCO_FREE_CODE
       where upper(DIC_GCO_NUMBER_CODE_TYPE_ID) = 'ORT_DELAY'
         and GCO_GOOD_ID = GcoGoodId;

    result number;
  begin
    result  := null;

    open CUR_FREE_DATA(GcoGoodId);

    fetch CUR_FREE_DATA
     into result;

    close CUR_FREE_DATA;

    if result is null then
      result  := nvl(to_number(PCS.PC_Config.GetConfig('FAL_ORT_DELAY') ), 0);
    end if;

    return result;
  end;

/* Initialisation du délai. Si au moins un des composants du lot est attribué à une commande
   fournisseur, le délai est égal au plus grand des Fln_Supply_Delay. Sinon (délai pour CF = NULL)
   Le délai est égal à (Lot_Plan_Begin_Dte) - (Config -> Fal_Ort_Delay)
   Si config FAL_ORT_SUPPLIER_DELAY = 2 (<> 1), on tient compte des propositions
   d'achat pour la recherche du délai.
*/
  function GetSupplierDelayForLot(FalLotId number, aScsStepNumber FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return date
  is
    ldMaxSupplyDelay FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type;
  begin
    select max(FNL.FLN_SUPPLY_DELAY)
      into ldMaxSupplyDelay
      from FAL_NETWORK_LINK FNL
         , FAL_NETWORK_NEED FNN
         , FAL_NETWORK_SUPPLY FNS
     where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
       and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
       and FNN.FAL_LOT_ID = FalLotId
       and (    (    cOrtSupplierDelay = 1
                 and FNS.DOC_POSITION_DETAIL_ID is not null)
            or (    cOrtSupplierDelay = 2
                and (   FNS.DOC_POSITION_DETAIL_ID is not null
                     or FNS.FAL_DOC_PROP_ID is not null) )
           )
       and FNN.GCO_GOOD_ID in(
             select GCO_GOOD_ID
               from FAL_LOT_MATERIAL_LINK
              where FAL_LOT_ID = FalLotId
                and (    (    aScsStepNumber is null
                          and (   LOM_TASK_SEQ is null
                               or LOM_TASK_SEQ = (select min(SCS_STEP_NUMBER)
                                                    from FAL_TASK_LINK
                                                   where FAL_LOT_ID = FalLotId) ) )
                     or (    aScsStepNumber is not null
                         and (aScsStepNumber = nvl(LOM_TASK_SEQ, 0) ) )
                    ) );

    return ldMaxSupplyDelay;
  end;

/* Initialisation du délai. Si au moins un des composants du lot est attribué à une commande
   fournisseur, le délai est égal au plus grand des Fln_Supply_Delay. Sinon (délai pour CF = NULL)
   Le délai est égal à (Lot_Plan_Begin_Dte) - (Config -> Fal_Ort_Delay)
   Si config FAL_ORT_SUPPLIER_DELAY = 2 (<> 1), on tient compte des propositions
   d'achat pour la recherche du délai.
*/
  function GetSupplierDelayForProp(FalLotPropId number, aScsStepNumber FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return date
  is
    ldMaxSupplyDelay FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type;
  begin
    select max(FNL.FLN_SUPPLY_DELAY)
      into ldMaxSupplyDelay
      from FAL_NETWORK_LINK FNL
         , FAL_NETWORK_NEED FNN
         , FAL_NETWORK_SUPPLY FNS
     where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
       and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
       and FNN.FAL_LOT_PROP_ID = FalLotPropId
       and (    (    cOrtSupplierDelay = 1
                 and FNS.DOC_POSITION_DETAIL_ID is not null)
            or (    cOrtSupplierDelay = 2
                and (   FNS.DOC_POSITION_DETAIL_ID is not null
                     or FNS.FAL_DOC_PROP_ID is not null) )
           )
       and FNN.GCO_GOOD_ID in(
             select GCO_GOOD_ID
               from FAL_LOT_MAT_LINK_PROP
              where FAL_LOT_PROP_ID = FalLotPropId
                and (    (    aScsStepNumber is null
                          and (   LOM_TASK_SEQ is null
                               or LOM_TASK_SEQ = (select min(SCS_STEP_NUMBER)
                                                    from FAL_TASK_LINK_PROP
                                                   where FAL_LOT_PROP_ID = FalLotPropId) ) )
                     or (    aScsStepNumber is not null
                         and (aScsStepNumber = nvl(LOM_TASK_SEQ, 0) ) )
                    ) );

    return ldMaxSupplyDelay;
  end;

  procedure AddEventModifyQty(aSchemaName varchar2, NumeroOF varchar2, NumeroPhase char, QteSolde number)
  is
    vQuery varchar2(32000);
  begin
    vQuery  :=
      ' insert into ' ||
      aSchemaName ||
      '.B_EVT (EVT_KEY      ' ||
      '      , EVENT        ' ||
      '      , EVT_DATEG    ' ||
      '      , EVT_NOF      ' ||
      '      , EVT_NOPHASE  ' ||
      '      , EVT_FRACTION ' ||
      '      , EVT_TYPERECAL' ||
      '      , EVT_DUR_TEMPS' ||
      '      , EVT_MARQUEUR)' ||
      ' values(0            ' ||
      '      , ''MOP''      ' ||
      '      , sysdate      ' ||
      '      , :EVT_NOF     ' ||
      '      , :EVT_NOPHASE ' ||
      '      , 0            ' ||
      '      , ''2''        ' ||
      '      , :EVT_DUR_TEMPS' ||
      '      , 0) ';

    execute immediate vQuery
                using NumeroOF, NumeroPhase, QteSolde;
  end;

  procedure ExportBatches(
    NomSchema              varchar2
  , aExportPlannedBatches  integer
  , aExportLaunchedBatches integer
  , FalJobProgramId        number   -- Prog de Fabrication
  , FalOrderId             number   -- Ordre
  , FalLotId               number   -- Lot de fabrication
  , LotPlanBeginDte        date   -- Date max
  , LotPlanEndDte          date   -- Date min
  , DicFamilyId            DIC_FAMILY.DIC_FAMILY_ID%type   -- Code famille
  , DocRecordId            number   -- Dossier
  , GcoGoodId              number   -- Produit
  , DicAccountableGroupId  DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type   -- Groupe de responsable
  , GcoGoodCategoryId      number   -- Catégorie
  , DicFloorFreeCodeId     DIC_FLOOR_FREE_CODE.DIC_FLOOR_FREE_CODE_ID%type   -- Code libre 1
  , DicFloorFreeCode2Id    DIC_FLOOR_FREE_CODE2.DIC_FLOOR_FREE_CODE2_ID%type   -- Code libre 2
  )
  is
    cursor crBatch
    is
      select   FL.FAL_LOT_ID
             , FL.LOT_REFCOMPL
             , FL.GCO_GOOD_ID
             , FL.LOT_INPROD_QTY
             , FL.LOT_PLAN_BEGIN_DTE
             , nvl(FL.LOT_BASIS_END_DTE, FL.LOT_PLAN_END_DTE) LOT_END_DATE
             , FL.LOT_BASIS_BEGIN_DTE
             , FL.LOT_SHORT_DESCR
             , FL.C_LOT_STATUS
             , FL.LOT_ORT_MARKERS
             , FL.C_FAB_TYPE
             , (select count(*)
                  from FAL_TASK_LINK
                 where FAL_LOT_ID = FL.FAL_LOT_ID
                   and (   DIC_FREE_TASK_CODE_ID = ctOpePreparation
                        or DIC_FREE_TASK_CODE_ID = ctOpeInjection
                        or C_RELATION_TYPE in('3', '4', '5') ) ) ARBORESCENT_PROCESS_NEED
             , (select count(*)
                  from FAL_TASK_LINK
                 where FAL_LOT_ID = FL.FAL_LOT_ID
                   and C_RELATION_TYPE = '2') CNT_PARALLEL
          from FAL_LOT FL
         where C_SCHEDULE_PLANNING <> '1'
           and (    (    nvl(aExportPlannedBatches, 0) = 1
                     and FL.C_LOT_STATUS = '1')
                or (    nvl(aExportLaunchedBatches, 0) = 1
                    and FL.C_LOT_STATUS = '2') )
           and (   nvl(FalJobProgramId, 0) = 0
                or FL.FAL_JOB_PROGRAM_ID = FalJobProgramId)
           and (   nvl(FalOrderId, 0) = 0
                or FL.FAL_ORDER_ID = FalOrderId)
           and (   nvl(FalLotId, 0) = 0
                or FL.FAL_LOT_ID = FalLotId)
           and (   nvl(GcoGoodId, 0) = 0
                or FL.GCO_GOOD_ID = GcoGoodId)
           and (   DicFamilyId is null
                or FL.DIC_FAMILY_ID = DicFamilyId)
           and (   nvl(DocRecordId, 0) = 0
                or FL.DOC_RECORD_ID = DocRecordId)
           and (   LotPlanEndDte is null
                or trunc(FL.LOT_PLAN_END_DTE) >= trunc(LotPlanEndDte) )
           and (   LotPlanBeginDte is null
                or trunc(FL.LOT_PLAN_BEGIN_DTE) <= trunc(LotPlanBeginDte) )
           and nvl(FL.LOT_INPROD_QTY, 0) > 0
           and exists(select FAL_SCHEDULE_STEP_ID
                        from FAL_TASK_LINK
                       where FAL_LOT_ID = FL.FAL_LOT_ID
                         and TAL_DUE_QTY > 0)
           and (   GcoGoodCategoryId is null
                or exists(select GCO_GOOD_ID
                            from GCO_GOOD
                           where GCO_GOOD_ID = FL.GCO_GOOD_ID
                             and GCO_GOOD_CATEGORY_ID = GcoGoodCategoryId) )
           and (   DicAccountableGroupId is null
                or exists(select GCO_GOOD_ID
                            from GCO_GOOD
                           where GCO_GOOD_ID = FL.GCO_GOOD_ID
                             and DIC_ACCOUNTABLE_GROUP_ID = DicAccountableGroupId) )
           and (    (    DicFloorFreeCodeId is null
                     and DicFloorFreeCode2Id is null)
                or exists(
                     select FAL_FACTORY_FLOOR_ID
                       from FAL_FACTORY_FLOOR
                      where (   DicFloorFreeCodeId is null
                             or DIC_FLOOR_FREE_CODE_ID = DicFloorFreeCodeId)
                        and (   DicFloorFreeCode2Id is null
                             or DIC_FLOOR_FREE_CODE2_ID = DicFloorFreeCode2Id)
                        and FAL_FACTORY_FLOOR_ID in(select FAL_FACTORY_FLOOR_ID
                                                      from FAL_TASK_LINK
                                                     where FAL_LOT_ID = FL.FAL_LOT_ID) )
               )
      order by FL.LOT_PLAN_BEGIN_DTE;

    cursor crBatchOperation(varFalLotId number)
    is
      select   FAL_SCHEDULE_STEP_ID
             , SCS_SHORT_DESCR
             , SCS_FREE_DESCR
             , PPS_TOOLS1_ID
             , SCS_WORK_TIME
             , decode(nvl(SCS_QTY_REF_WORK, 0), 0, 1, SCS_QTY_REF_WORK) SCS_QTY_REF_WORK
             , FAL_FACTORY_FLOOR_ID
             , C_TASK_TYPE
             , PAC_SUPPLIER_PARTNER_ID
             , SCS_QTY_FIX_ADJUSTING
             , SCS_ADJUSTING_TIME
             , TAL_DUE_QTY
             , SCS_PLAN_PROP
             , nvl(SCS_PLAN_RATE, 0) SCS_PLAN_RATE
             , lpad(SCS_STEP_NUMBER, 4, '0') SCS_STEP_NUMBER
             , C_RELATION_TYPE
             , nvl(SCS_DELAY, 0) SCS_DELAY
             , nvl(TAL_ACHIEVED_TSK, 0) TAL_ACHIEVED_TSK
             , decode(TAL_BEGIN_REAL_DATE, null, TAL_ORT_PRIORITY, 999) TAL_ORT_PRIORITY
             , TAL_TSK_BALANCE
             , TAL_BEGIN_REAL_DATE
             , TAL_END_REAL_DATE
             , C_OPERATION_TYPE
             , TAL_BEGIN_PLAN_DATE
             , TAL_END_PLAN_DATE
             , TAL_CONFIRM_DATE
             , TAL_ORT_MARKERS
             , substr(TAL_CONFIRM_DESCR, 1, 15) TAL_CONFIRM_DESCR
             , DIC_FREE_TASK_CODE_ID
             , FAL_FAL_FACTORY_FLOOR_ID
             , nvl(SCS_NUM_ADJUST_OPERATOR, 0) SCS_NUM_ADJUST_OPERATOR
             , decode(FAL_FAL_FACTORY_FLOOR_ID, null, 0, nvl(SCS_NUM_WORK_OPERATOR, 0) ) SCS_NUM_WORK_OPERATOR
             , SCS_TRANSFERT_TIME
             , SCS_STEP_NUMBER TAL_SEQ_SCS_STEP_NUMBER
             , TAL_SUBCONTRACT_QTY
             , TAL_RELEASE_QTY
             , nvl(SCS_OPEN_TIME_MACHINE, 0) SCS_OPEN_TIME_MACHINE
             , nvl(TAL_ORT_IS_FRACTIONED, 0) TAL_ORT_IS_FRACTIONED
             , nvl(TAL_NUM_UNITS_ALLOCATED, 0) TAL_NUM_UNITS_ALLOCATED
             , (select count(*)
                  from FAL_TASK_LINK_USE
                 where FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID) CNT_LMU
          from FAL_TASK_LINK TAL
         where FAL_LOT_ID = varFalLotId
           and TAL_DUE_QTY > 0
      order by SCS_STEP_NUMBER;

    cursor crParameters(aFalLotId number, aGcoGoodId number)
    is
      select lpad(TAL.SCS_STEP_NUMBER, 4, '0') SCS_STEP_NUMBER
           , (select DIC_GCO_CHAR_CODE_TYPE_ID
                from DIC_GCO_CHAR_CODE_TYPE
               where DIC_GCO_CHAR_CODE_TYPE_ID = PARAM.DIC_GCO_CHAR_CODE_TYPE_ID) DIC_GCO_CHAR_CODE_TYPE_ID
           , (select FCO_CHA_CODE
                from GCO_FREE_CODE
               where GCO_GOOD_ID = aGcoGoodId
                 and DIC_GCO_CHAR_CODE_TYPE_ID = PARAM.DIC_GCO_CHAR_CODE_TYPE_ID) FCO_CHA_CODE
           , TAL.DIC_FREE_TASK_CODE_ID
        from FAL_TASK_LINK TAL
           , FAL_FACTORY_PARAMETER PARAM
       where TAL.FAL_FACTORY_FLOOR_ID = PARAM.FAL_FACTORY_FLOOR_ID
         and TAL.FAL_LOT_ID = aFalLotId
         and TAL.TAL_DUE_QTY > 0
         and PARAM.FFP_ACTIF = 1
         and (    (    cOrtAdjusting = 4
                   and DIC_GCO_CHAR_CODE_TYPE_ID = 'CODEOP')
              or cOrtAdjusting <> 4);

    cursor crLMU(FalScheduleStepId number, FalFactoryFloorId number)
    is
      select FAL_FACTORY_FLOOR_ID
           , SCS_QTY_REF_WORK
           , SCS_WORK_TIME
           , SCS_PRIORITY
           , SCS_EXCEPT_MACH
        from FAL_TASK_LINK_USE ftlu
       where FAL_SCHEDULE_STEP_ID = FalScheduleStepId
         and (   (select FAL_FAL_FACTORY_FLOOR_ID
                    from FAL_FACTORY_FLOOR
                   where FAL_FACTORY_FLOOR_ID = ftlu.FAL_FACTORY_FLOOR_ID) = FalFactoryFloorId
              or (select FAL_FAL_FACTORY_FLOOR_ID
                    from FAL_FACTORY_FLOOR
                   where FAL_FACTORY_FLOOR_ID = ftlu.FAL_FACTORY_FLOOR_ID) = (select FAL_FAL_FACTORY_FLOOR_ID
                                                                                from FAL_FACTORY_FLOOR
                                                                               where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId)
             );

    VersionArticle        varchar2(10);
    Article               varchar2(30);
    lcPhase               char(4);
    lvBeginBeginPhases    varchar2(100);
    Delai_CF              FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type;
    Delai_ORT             FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type;
    CreateQualif          boolean;
    OpePrecDePreparation  boolean;
    hasLMU                boolean;
    DurationOfRealization number;
    IsAdjustingOperation  boolean;
    NewQtyRefWork         number;
    aDoCreateLMU          integer;
    vPreviousWorkDone     number;
  begin
    BatchOpeFractionedId  := TBatchOpeFractionedId();

    --  Pour chaque lot de fabrication
    for tplBatch in crBatch loop
      NbreLots                         := NbreLots + 1;
      ListeLots(NbreLots).RefComplete  := tplBatch.LOT_REFCOMPL;
      ListeLots(NbreLots).Marqueurs    := tplBatch.LOT_ORT_MARKERS;
      Article                          := GetProductReference(NomSchema, tplBatch.GCO_GOOD_ID);
      CreateProcessPlan(NomSchema, tplBatch.LOT_REFCOMPL,(tplBatch.ARBORESCENT_PROCESS_NEED > 0),(tplBatch.CNT_PARALLEL > 0) );
      lcPhase                          := '0000';
      lvBeginBeginPhases               := '';
      OpePrecDePreparation             := false;
      vPreviousWorkDone                := 0;

      -- Pour chaque opération du lot
      for tplBatchOperation in crBatchOperation(tplBatch.FAL_LOT_ID) loop
        -- Le tableau ci-dessous sert à affecter la priorité et les marqueurs aux opérations
        -- dans la table Ortems B_BT après le lancement dans l'en-cours
        NbreOp                                      := NbreOp + 1;
        ListeOperations(NbreOp).NumeroOF            := tplBatch.LOT_REFCOMPL;
        ListeOperations(NbreOp).NumeroPhase         := tplBatchOperation.SCS_STEP_NUMBER;
        ListeOperations(NbreOp).Priorite            := greatest(least(nvl(tplBatchOperation.TAL_ORT_PRIORITY, 0), 999), 0);
        ListeOperations(NbreOp).DateDebut           := tplBatchOperation.TAL_BEGIN_PLAN_DATE;
        ListeOperations(NbreOp).ExternOpeConfirmed  :=     (tplBatchOperation.C_TASK_TYPE = '2')
                                                       and (tplBatchOperation.TAL_CONFIRM_DATE is not null);
        ListeOperations(NbreOp).Marqueurs           := tplBatchOperation.TAL_ORT_MARKERS;
        ListeOperations(NbreOp).CTaskType           := tplBatchOperation.C_TASK_TYPE;
        ListeOperations(NbreOp).DescrConfirm        := tplBatchOperation.TAL_CONFIRM_DESCR;
        ListeOperations(NbreOp).aWork               := tplBatchOperation.SCS_WORK_TIME;
        ListeOperations(NbreOp).CFabType            := tplBatch.C_FAB_TYPE;

        /* Lorsque le temps de travail de l'opération est inférieur au 1/100 de fraction, Ortems arrondi cette valeur à l'unité supérieur
           qui est le centième d'heure. Pour corriger cette erreur, on multiplie le travail et la quantité ref travail par 1000 */
        if tplBatchOperation.SCS_WORK_TIME < 0.9999 then
          tplBatchOperation.SCS_WORK_TIME     := tplBatchOperation.SCS_WORK_TIME * 1000;
          tplBatchOperation.SCS_QTY_REF_WORK  := tplBatchOperation.SCS_QTY_REF_WORK * 1000;
        end if;

        if     (tplBatchOperation.C_TASK_TYPE = 1)
           and (nvl(tplBatchOperation.TAL_SEQ_SCS_STEP_NUMBER, 0) > 0) then
          ListeOperations(NbreOp).SupplierDelay  := GetSupplierDelayForLot(tplBatch.FAL_LOT_ID, tplBatchOperation.TAL_SEQ_SCS_STEP_NUMBER);
        else
          ListeOperations(NbreOp).SupplierDelay  := null;
        end if;

        if     (tplBatchOperation.TAL_NUM_UNITS_ALLOCATED > 1)
           and (tplBatchOperation.TAL_NUM_UNITS_ALLOCATED <= tplBatchOperation.CNT_LMU) then
          -- Sauvegarde de l'Id des opérations à fractionner
          BatchOpeFractionedId.extend;
          BatchOpeFractionedId(BatchOpeFractionedId.last)  := tplBatchOperation.FAL_SCHEDULE_STEP_ID;
        end if;

        if     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
           and (tplBatchOperation.DIC_FREE_TASK_CODE_ID = ctOpePreparation) then
          update FAL_TASK_LINK_USE
             set SCS_WORK_TIME = tplBatchOperation.SCS_ADJUSTING_TIME
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_SCHEDULE_STEP_ID = tplBatchOperation.FAL_SCHEDULE_STEP_ID;
        end if;

        CreateGenericOperation(NomSchema
                             , tplBatchOperation.FAL_SCHEDULE_STEP_ID
                             , tplBatchOperation.SCS_SHORT_DESCR
                             , tplBatchOperation.SCS_FREE_DESCR
                             , tplBatchOperation.PPS_TOOLS1_ID
                             , tplBatchOperation.SCS_WORK_TIME
                             , tplBatchOperation.SCS_QTY_REF_WORK
                             , tplBatchOperation.FAL_FACTORY_FLOOR_ID
                             , tplBatchOperation.C_TASK_TYPE
                             , tplBatchOperation.PAC_SUPPLIER_PARTNER_ID
                             , tplBatchOperation.SCS_QTY_FIX_ADJUSTING
                             , tplBatchOperation.SCS_ADJUSTING_TIME
                             , tplBatchOperation.TAL_DUE_QTY
                             , tplBatchOperation.SCS_PLAN_PROP
                             , tplBatchOperation.SCS_PLAN_RATE
                             , tplBatch.GCO_GOOD_ID
                             , tplBatchOperation.DIC_FREE_TASK_CODE_ID
                             , tplBatchOperation.SCS_TRANSFERT_TIME
                             , tplBatchOperation.TAL_BEGIN_PLAN_DATE
                             , tplBatchOperation.TAL_END_PLAN_DATE
                             , tplBatchOperation.TAL_BEGIN_REAL_DATE
                             , tplBatchOperation.TAL_END_REAL_DATE
                             , tplBatchOperation.TAL_SUBCONTRACT_QTY
                             , tplBatchOperation.TAL_RELEASE_QTY
                             , tplBatchOperation.TAL_TSK_BALANCE
                             , case tplBatch.C_FAB_TYPE
                                 when '4' then 'F'
                                 else 'M'
                               end
                             , tplBatchOperation.SCS_OPEN_TIME_MACHINE
                             , DurationOfRealization
                             , IsAdjustingOperation
                             , NewQtyRefWork
                             , aDoCreateLMU
                              );
        -- CreateQualif détermine s'il faudra créer les qualifications par LMU
        CreateQualif                                := false;

        if (PCS.PC_Config.GetConfig('FAL_ORT_EXPORT_OPERATOR') = 'True') then
          if    (     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
                 and (    (tplBatchOperation.DIC_FREE_TASK_CODE_ID = ctOpePreparation)
                      or (tplBatchOperation.DIC_FREE_TASK_CODE_ID = ctOpeInjection) )
                )
             or (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') <> '1') then
            CreateQualif  := true;
          end if;
        end if;

        hasLMU                                      := false;

        if aDoCreateLMU = 1 then
          -- Pour chaque machine utilisable de l'opération du lot
          for tplLMU in crLMU(tplBatchOperation.FAL_SCHEDULE_STEP_ID, tplBatchOperation.FAL_FACTORY_FLOOR_ID) loop
            hasLMU  := true;

            /* Lorsque le temps de travail de l'opération est inférieur au 1/100 de fraction, Ortems arrondi cette valeur à l'unité supérieur
               qui est le centième d'heure. Pour corriger cette erreur, on multiplie le travail et la quantité ref travail par 1000 */
            if tplLMU.SCS_WORK_TIME < 0.9999 then
              tplLMU.SCS_WORK_TIME     := tplLMU.SCS_WORK_TIME * 1000;
              tplLMU.SCS_QTY_REF_WORK  := tplLMU.SCS_QTY_REF_WORK * 1000;
            end if;

            Creation_LMU_et_Qualif(NomSchema
                                 , tplBatchOperation.FAL_SCHEDULE_STEP_ID   -- Opération
                                 , tplLMU.FAL_FACTORY_FLOOR_ID   -- Machine
                                 , tplLMU.SCS_WORK_TIME
                                 , tplLMU.SCS_QTY_REF_WORK
                                 , tplLMU.SCS_PRIORITY
                                 , tplLMU.SCS_EXCEPT_MACH
                                 , tplBatchOperation.FAL_FAL_FACTORY_FLOOR_ID   -- Opérateur
                                 , CreateQualif
                                 , tplBatchOperation.DIC_FREE_TASK_CODE_ID
                                 , tplBatchOperation.SCS_NUM_ADJUST_OPERATOR
                                 , tplBatchOperation.SCS_NUM_WORK_OPERATOR
                                 , DurationOfRealization
                                 , IsAdjustingOperation
                                 , NewQtyRefWork
                                 , tplBatchOperation.SCS_OPEN_TIME_MACHINE
                                  );
          end loop;

          -- Il n'existe pas de machine utilisable sur l'opération ET ...
          if     not hasLMU
             and (PCS.PC_Config.GetConfig('FAL_ORT_EXPORT_OPERATOR') = 'True')
             and (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') <> '1')
             and tplBatchOperation.FAL_FAL_FACTORY_FLOOR_ID is not null then
            if not IsMachine(tplBatchOperation.FAL_FACTORY_FLOOR_ID) then
              -- Pour chaque Machine Utilisable de l'îlot
              for tplLMU in (select FAL_FACTORY_FLOOR_ID
                               from FAL_FACTORY_FLOOR
                              where FAL_FAL_FACTORY_FLOOR_ID = tplBatchOperation.FAL_FACTORY_FLOOR_ID) loop
                hasLMU  := true;
                Creation_LMU_et_Qualif(NomSchema
                                     , tplBatchOperation.FAL_SCHEDULE_STEP_ID   -- Opération
                                     , tplLMU.FAL_FACTORY_FLOOR_ID   -- Machine
                                     , tplBatchOperation.SCS_WORK_TIME
                                     , tplBatchOperation.SCS_QTY_REF_WORK
                                     , 0   -- Priorité
                                     , 0   -- Machine exceptionnelle
                                     , tplBatchOperation.FAL_FAL_FACTORY_FLOOR_ID   -- Opérateur
                                     , true   -- Création des qualifs
                                     , tplBatchOperation.DIC_FREE_TASK_CODE_ID
                                     , tplBatchOperation.SCS_NUM_ADJUST_OPERATOR
                                     , tplBatchOperation.SCS_NUM_WORK_OPERATOR
                                     , DurationOfRealization
                                     , IsAdjustingOperation
                                     , NewQtyRefWork
                                     , tplBatchOperation.SCS_OPEN_TIME_MACHINE
                                      );
              end loop;
            end if;

            -- Si on a toujours pas créé de LMU, on en crée une qui correspond à la machine de l'opération
            if not hasLMU then
              Creation_LMU_et_Qualif(NomSchema
                                   , tplBatchOperation.FAL_SCHEDULE_STEP_ID   -- Opération
                                   , tplBatchOperation.FAL_FACTORY_FLOOR_ID   -- Machine
                                   , tplBatchOperation.SCS_WORK_TIME
                                   , tplBatchOperation.SCS_QTY_REF_WORK
                                   , 0   -- Priorité
                                   , 0   -- Machine exceptionnelle
                                   , tplBatchOperation.FAL_FAL_FACTORY_FLOOR_ID   -- Opérateur
                                   , true   -- Création des qualifs
                                   , tplBatchOperation.DIC_FREE_TASK_CODE_ID
                                   , tplBatchOperation.SCS_NUM_ADJUST_OPERATOR
                                   , tplBatchOperation.SCS_NUM_WORK_OPERATOR
                                   , DurationOfRealization
                                   , IsAdjustingOperation
                                   , NewQtyRefWork
                                   , tplBatchOperation.SCS_OPEN_TIME_MACHINE
                                    );
            end if;
          end if;
        end if;

        Creation_Phase(NomSchema
                     , tplBatch.LOT_REFCOMPL   -- Gamme
                     , tplBatchOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                     , tplBatchOperation.FAL_SCHEDULE_STEP_ID   -- Opération générique
                     , tplBatchOperation.SCS_SHORT_DESCR   -- Libellé de la phase (Description courte)
                      );

        if lcPhase <> '0000' then
          CreateOperationLink(aSchemaName             => NomSchema
                            , aGamme                  => tplBatch.LOT_REFCOMPL   -- Gamme
                            , aStartPhase             => lcPhase   -- Phase de départ
                            , aStopPhase              => tplBatchOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                            , aCRelationType          => tplBatchOperation.C_RELATION_TYPE   -- Type de précédence
                            , aScsDelay               => tplBatchOperation.SCS_DELAY   -- Seuil (Retard)
                            , aDicFreeTaskCodeId      => tplBatchOperation.DIC_FREE_TASK_CODE_ID
                            , aOpePrecDePreparation   => OpePrecDePreparation
                            , aPreviousWorkDone       => vPreviousWorkDone
                             );
        end if;

        if (PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_IN_LIMITED_RESS') = 'True') then
          if (     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
              and (tplBatchOperation.DIC_FREE_TASK_CODE_ID = ctOpeInjection)
              and OpePrecDePreparation) then
            Reservation_Ress_Limitees(NomSchema
                                    , tplBatch.LOT_REFCOMPL   -- Gamme
                                    , tplBatchOperation.FAL_SCHEDULE_STEP_ID   -- Opération
                                    , null   -- FAL_TASK_LINK_PROP_ID
                                    , lcPhase   -- Phase de départ
                                    , tplBatchOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                                     );
          elsif(PCS.PC_Config.GetConfig('FAL_ORT_INDIV') <> '1') then
            Reservation_Ress_Limitees(NomSchema
                                    , tplBatch.LOT_REFCOMPL   -- Gamme
                                    , tplBatchOperation.FAL_SCHEDULE_STEP_ID   -- Opération
                                    , null   -- FAL_TASK_LINK_PROP_ID
                                    , tplBatchOperation.SCS_STEP_NUMBER   -- Phase de départ
                                    , tplBatchOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                                     );
          end if;
        end if;

        if tplBatchOperation.DIC_FREE_TASK_CODE_ID = ctOpePreparation then
          OpePrecDePreparation  := true;
        else
          OpePrecDePreparation  := false;
        end if;

        -- Pour les OF lancés, modification des quantités des opérations qui n'ont pas le même solde que la quantité en prod.
        if     (tplBatch.C_LOT_STATUS = '2')
           and (tplBatch.LOT_INPROD_QTY <> nvl(tplBatchOperation.TAL_DUE_QTY, 0) ) then
          AddEventModifyQty(NomSchema, tplBatch.LOT_REFCOMPL, tplBatchOperation.SCS_STEP_NUMBER, tplBatchOperation.TAL_DUE_QTY);
        end if;

        if tplBatchOperation.C_RELATION_TYPE in('1', '2') then
          loop
            exit when lvBeginBeginPhases is null;

            -- Création des liens entre les opérations précédentes de relation début-début et l'opération en cours de type précédence totale
            if substr(lvBeginBeginPhases, 2, 4) <> '0000' then
              CreateOperationLink(aSchemaName             => NomSchema
                                , aGamme                  => tplBatch.LOT_REFCOMPL   -- Gamme
                                , aStartPhase             => substr(lvBeginBeginPhases, 2, 4)   -- Phase de départ
                                , aStopPhase              => tplBatchOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                                , aCRelationType          => tplBatchOperation.C_RELATION_TYPE   -- Type de précédence
                                , aScsDelay               => tplBatchOperation.SCS_DELAY   -- Seuil (Retard)
                                , aDicFreeTaskCodeId      => tplBatchOperation.DIC_FREE_TASK_CODE_ID
                                , aOpePrecDePreparation   => OpePrecDePreparation
                                 );
            end if;

            lvBeginBeginPhases  := substr(lvBeginBeginPhases, 6, 100);
          end loop;
        elsif tplBatchOperation.C_RELATION_TYPE in('4', '5') then
          lvBeginBeginPhases  := lvBeginBeginPhases || ';' || lcPhase;
        end if;

        lcPhase                                     := tplBatchOperation.SCS_STEP_NUMBER;
        vPreviousWorkDone                           := tplBatchOperation.TAL_ACHIEVED_TSK;
      end loop;

      -- La version est égale aux 10 derniers caractères de Fal_Lot_Id
      VersionArticle                   := ltrim(substr(lpad(tplBatch.FAL_LOT_ID, 12), 3, 10) );
      Creation_Version(NomSchema, Article, VersionArticle, tplBatch.LOT_REFCOMPL);

      -- Si les temps de réglage se font par matrice
      if    (cOrtAdjusting = 3)
         or (cOrtAdjusting = 4)
         or (cOrtAdjusting = 5) then
        for tplParameters in crParameters(tplBatch.FAL_LOT_ID, tplBatch.GCO_GOOD_ID) loop
          CreateParameterValue(aSchemaName        => NomSchema
                             , aProduct           => Article
                             , aProductVersion    => VersionArticle
                             , aProcessPlanName   => tplBatch.LOT_REFCOMPL
                             , aPhase             => tplParameters.SCS_STEP_NUMBER
                             , aTypeMat           => case cOrtAdjusting
                                 when 4 then 'CODEOP'
                                 else tplParameters.DIC_GCO_CHAR_CODE_TYPE_ID
                               end
                             , aParameter         => case cOrtAdjusting
                                 when 4 then tplParameters.DIC_FREE_TASK_CODE_ID
                                 else tplParameters.FCO_CHA_CODE
                               end
                              );
        end loop;
      end if;

      Delai_CF                         := GetSupplierDelayForLot(tplBatch.FAL_LOT_ID, null);

      if CheckDelay(tplBatch.GCO_GOOD_ID) = 1 then
        Delai_ORT  := nvl(tplBatch.LOT_BASIS_BEGIN_DTE, tplBatch.LOT_PLAN_BEGIN_DTE) - GetDelay(tplBatch.GCO_GOOD_ID);
      else
        Delai_ORT  := sysdate;
      end if;

      if Delai_CF is null then
        Delai_CF  := Delai_ORT;
      end if;

      CreateBatch(NomSchema
                , tplBatch.LOT_REFCOMPL
                , tplBatch.LOT_SHORT_DESCR
                , tplBatch.FAL_LOT_ID
                , Article
                , VersionArticle
                , greatest(Delai_ORT, Delai_CF, sysdate - 720)
                , tplBatch.LOT_INPROD_QTY
                , 'F'   -- Code gestion
                , tplBatch.LOT_END_DATE
                , tplBatch.C_FAB_TYPE
                 );
    end loop;
  end;

  procedure ExportPropositions(
    NomSchema             varchar2
  , LotPlanBeginDte       date   -- Date max
  , LotPlanEndDte         date   -- Date min
  , DicFamilyId           DIC_FAMILY.DIC_FAMILY_ID%type   -- Code famille
  , DocRecordId           number   -- Dossier
  , GcoGoodId             number   -- Produit
  , DicAccountableGroupId DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type   -- Groupe de responsable
  , GcoGoodCategoryId     number   -- Catégorie
  , DicFloorFreeCodeId    DIC_FLOOR_FREE_CODE.DIC_FLOOR_FREE_CODE_ID%type   -- Code libre 1
  , DicFloorFreeCode2Id   DIC_FLOOR_FREE_CODE2.DIC_FLOOR_FREE_CODE2_ID%type   -- Code libre 2
  )
  is
    cursor crPropositions
    is
      select FLP.FAL_LOT_PROP_ID
           , FLP.GCO_GOOD_ID
           , FLP.LOT_TOTAL_QTY
           , FLP.LOT_PLAN_BEGIN_DTE
           , FLP.LOT_PLAN_END_DTE
           , FLP.LOT_SHORT_DESCR
           , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', FLP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || '-' || FLP.LOT_NUMBER PROP_REFCOMPL
           , FLP.LOT_ORT_MARKERS
           , FLP.C_FAB_TYPE
           , (select count(*)
                from FAL_TASK_LINK_PROP
               where FAL_LOT_PROP_ID = FLP.FAL_LOT_PROP_ID
                 and (   DIC_FREE_TASK_CODE_ID = ctOpePreparation
                      or DIC_FREE_TASK_CODE_ID = ctOpeInjection
                      or C_RELATION_TYPE in('3', '4', '5') ) ) ARBORESCENT_PROCESS_NEED
           , (select count(*)
                from FAL_TASK_LINK_PROP
               where FAL_LOT_PROP_ID = FLP.FAL_LOT_PROP_ID
                 and C_RELATION_TYPE = '2') CNT_PARALLEL
        from FAL_LOT_PROP FLP
       where C_SCHEDULE_PLANNING <> '1'
         and (   nvl(GcoGoodId, 0) = 0
              or FLP.GCO_GOOD_ID = GcoGoodId)
         and (   nvl(DocRecordId, 0) = 0
              or FLP.DOC_RECORD_ID = DocRecordId)
         and (   DicFamilyId is null
              or FLP.DIC_FAMILY_ID = DicFamilyId)
         and (   LotPlanEndDte is null
              or trunc(FLP.LOT_PLAN_END_DTE) >= trunc(LotPlanEndDte) )
         and (   LotPlanBeginDte is null
              or trunc(FLP.LOT_PLAN_BEGIN_DTE) <= trunc(LotPlanBeginDte) )
         and (   GcoGoodCategoryId is null
              or exists(select GCO_GOOD_ID
                          from GCO_GOOD
                         where GCO_GOOD_ID = FLP.GCO_GOOD_ID
                           and GCO_GOOD_CATEGORY_ID = GcoGoodCategoryId) )
         and (   DicAccountableGroupId is null
              or exists(select GCO_GOOD_ID
                          from GCO_GOOD
                         where GCO_GOOD_ID = FLP.GCO_GOOD_ID
                           and DIC_ACCOUNTABLE_GROUP_ID = DicAccountableGroupId) )
         and (    (    DicFloorFreeCodeId is null
                   and DicFloorFreeCode2Id is null)
              or exists(
                   select FAL_FACTORY_FLOOR_ID
                     from FAL_FACTORY_FLOOR
                    where (   DicFloorFreeCodeId is null
                           or DIC_FLOOR_FREE_CODE_ID = DicFloorFreeCodeId)
                      and (   DicFloorFreeCode2Id is null
                           or DIC_FLOOR_FREE_CODE2_ID = DicFloorFreeCode2Id)
                      and FAL_FACTORY_FLOOR_ID in(select FAL_FACTORY_FLOOR_ID
                                                    from FAL_TASK_LINK_PROP
                                                   where FAL_LOT_PROP_ID = FLP.FAL_LOT_PROP_ID) )
             );

    cursor crPropOperation(varFalLotPropId number)
    is
      select   FAL_TASK_LINK_PROP_ID
             , SCS_SHORT_DESCR
             , SCH_FREE_DESCR
             , PPS_TOOLS1_ID
             , SCS_WORK_TIME
             , decode(nvl(SCS_QTY_REF_WORK, 0), 0, 1, SCS_QTY_REF_WORK) SCS_QTY_REF_WORK
             , FAL_FACTORY_FLOOR_ID
             , C_TASK_TYPE
             , PAC_SUPPLIER_PARTNER_ID
             , SCS_QTY_FIX_ADJUSTING
             , SCS_ADJUSTING_TIME
             , TAL_DUE_QTY
             , SCS_PLAN_PROP
             , nvl(SCS_PLAN_RATE, 0) SCS_PLAN_RATE
             , lpad(SCS_STEP_NUMBER, 4, '0') SCS_STEP_NUMBER
             , C_RELATION_TYPE
             , nvl(SCS_DELAY, 0) SCS_DELAY
             , TAL_ORT_PRIORITY
             , TAL_TSK_BALANCE
             , C_OPERATION_TYPE
             , TAL_BEGIN_PLAN_DATE
             , TAL_END_PLAN_DATE
             , TAL_CONFIRM_DATE
             , TAL_ORT_MARKERS
             , substr(TAL_CONFIRM_DESCR, 1, 15) TAL_CONFIRM_DESCR
             , DIC_FREE_TASK_CODE_ID
             , FAL_FAL_FACTORY_FLOOR_ID
             , nvl(SCS_NUM_ADJUST_OPERATOR, 0) SCS_NUM_ADJUST_OPERATOR
             , decode(FAL_FAL_FACTORY_FLOOR_ID, null, 0, nvl(SCS_NUM_WORK_OPERATOR, 0) ) SCS_NUM_WORK_OPERATOR
             , SCS_TRANSFERT_TIME
             , SCS_STEP_NUMBER TAL_SEQ_SCS_STEP_NUMBER
             , nvl(SCS_OPEN_TIME_MACHINE, 0) SCS_OPEN_TIME_MACHINE
          from FAL_TASK_LINK_PROP
         where FAL_LOT_PROP_ID = varFalLotPropId
           and TAL_DUE_QTY > 0
      order by FAL_LOT_PROP_ID
             , SCS_STEP_NUMBER;

    cursor crParameters(aFalLotPropId number, aGcoGoodId number)
    is
      select lpad(TAL.SCS_STEP_NUMBER, 4, '0') SCS_STEP_NUMBER
           , (select DIC_GCO_CHAR_CODE_TYPE_ID
                from DIC_GCO_CHAR_CODE_TYPE
               where DIC_GCO_CHAR_CODE_TYPE_ID = PARAM.DIC_GCO_CHAR_CODE_TYPE_ID) DIC_GCO_CHAR_CODE_TYPE_ID
           , (select FCO_CHA_CODE
                from GCO_FREE_CODE
               where GCO_GOOD_ID = aGcoGoodId
                 and DIC_GCO_CHAR_CODE_TYPE_ID = PARAM.DIC_GCO_CHAR_CODE_TYPE_ID) FCO_CHA_CODE
           , TAL.DIC_FREE_TASK_CODE_ID
        from FAL_TASK_LINK_PROP TAL
           , FAL_FACTORY_PARAMETER PARAM
       where TAL.FAL_FACTORY_FLOOR_ID = PARAM.FAL_FACTORY_FLOOR_ID
         and TAL.FAL_LOT_PROP_ID = aFalLotPropId
         and TAL.TAL_DUE_QTY > 0
         and PARAM.FFP_ACTIF = 1
         and (    (    cOrtAdjusting = 4
                   and DIC_GCO_CHAR_CODE_TYPE_ID = 'CODEOP')
              or cOrtAdjusting <> 4);

    cursor crLMU(FalTaskLinkPropId number, FalFactoryFloorId number)
    is
      select FAL_FACTORY_FLOOR_ID
           , SCS_QTY_REF_WORK
           , SCS_WORK_TIME
           , SCS_PRIORITY
           , SCS_EXCEPT_MACH
        from FAL_TASK_LINK_PROP_USE ftlu
       where FAL_TASK_LINK_PROP_ID = FalTaskLinkPropId
         and (   (select FAL_FAL_FACTORY_FLOOR_ID
                    from FAL_FACTORY_FLOOR
                   where FAL_FACTORY_FLOOR_ID = ftlu.FAL_FACTORY_FLOOR_ID) = FalFactoryFloorId
              or (select FAL_FAL_FACTORY_FLOOR_ID
                    from FAL_FACTORY_FLOOR
                   where FAL_FACTORY_FLOOR_ID = ftlu.FAL_FACTORY_FLOOR_ID) = (select FAL_FAL_FACTORY_FLOOR_ID
                                                                                from FAL_FACTORY_FLOOR
                                                                               where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId)
             );

    VersionArticle        varchar2(10);
    Article               varchar2(30);
    lcPhase               char(4);
    lvBeginBeginPhases    varchar2(100);
    Delai_CF              FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type;
    Delai_ORT             FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type;
    CreateQualif          boolean;
    OpePrecDePreparation  boolean;
    hasLMU                boolean;
    DurationOfRealization number;
    IsAdjustingOperation  boolean;
    NewQtyRefWork         number;
    aDoCreateLMU          integer;
  begin
    for tplProposition in crPropositions loop
      NbreLots                         := NbreLots + 1;
      ListeLots(NbreLots).RefComplete  := tplProposition.PROP_REFCOMPL;
      ListeLots(NbreLots).Marqueurs    := tplProposition.LOT_ORT_MARKERS;
      Article                          := GetProductReference(NomSchema, tplProposition.GCO_GOOD_ID);
      CreateProcessPlan(NomSchema, tplProposition.PROP_REFCOMPL,(tplProposition.ARBORESCENT_PROCESS_NEED > 0),(tplProposition.CNT_PARALLEL > 0) );
      lcPhase                          := '0000';
      lvBeginBeginPhases               := '';
      OpePrecDePreparation             := false;

      -- Pour chaque opération du lot
      for tplPropOperation in crPropOperation(tplProposition.FAL_LOT_PROP_ID) loop
        -- Le tableau ci-dessous sert à affecter la priorité et les marqueurs aux opérations
        -- dans la table Ortems B_BT après le lancement dans l'en-cours
        NbreOp                                      := NbreOp + 1;
        ListeOperations(NbreOp).NumeroOF            := tplProposition.PROP_REFCOMPL;
        ListeOperations(NbreOp).NumeroPhase         := tplPropOperation.SCS_STEP_NUMBER;
        ListeOperations(NbreOp).Priorite            := greatest(least(nvl(tplPropOperation.TAL_ORT_PRIORITY, 0), 999), 0);
        ListeOperations(NbreOp).DateDebut           := tplPropOperation.TAL_BEGIN_PLAN_DATE;
        ListeOperations(NbreOp).ExternOpeConfirmed  :=     (tplPropOperation.C_TASK_TYPE = '2')
                                                       and (tplPropOperation.TAL_CONFIRM_DATE is not null);
        ListeOperations(NbreOp).Marqueurs           := tplPropOperation.TAL_ORT_MARKERS;
        ListeOperations(NbreOp).CTaskType           := tplPropOperation.C_TASK_TYPE;
        ListeOperations(NbreOp).DescrConfirm        := tplPropOperation.TAL_CONFIRM_DESCR;
        ListeOperations(NbreOp).aWork               := tplPropOperation.SCS_WORK_TIME;
        ListeOperations(NbreOp).CFabType            := tplProposition.C_FAB_TYPE;

        /* Lorsque le temps de travail de l'opération est inférieur au 1/100 de fraction, Ortems arrondi cette valeur à l'unité supérieur
           qui est le centième d'heure. Pour corriger cette erreur, on multiplie le travail et la quantité ref travail par 1000 */
        if tplPropOperation.SCS_WORK_TIME < 0.9999 then
          tplPropOperation.SCS_WORK_TIME     := tplPropOperation.SCS_WORK_TIME * 1000;
          tplPropOperation.SCS_QTY_REF_WORK  := tplPropOperation.SCS_QTY_REF_WORK * 1000;
        end if;

        if     (tplPropOperation.C_TASK_TYPE = 1)
           and (nvl(tplPropOperation.TAL_SEQ_SCS_STEP_NUMBER, 0) > 0) then
          ListeOperations(NbreOp).SupplierDelay  := GetSupplierDelayForProp(tplProposition.FAL_LOT_PROP_ID, tplPropOperation.TAL_SEQ_SCS_STEP_NUMBER);
        else
          ListeOperations(NbreOp).SupplierDelay  := null;
        end if;

        if     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
           and (tplPropOperation.DIC_FREE_TASK_CODE_ID = ctOpePreparation) then
          update FAL_TASK_LINK_PROP_USE
             set SCS_WORK_TIME = tplPropOperation.SCS_ADJUSTING_TIME
           where FAL_TASK_LINK_PROP_ID = tplPropOperation.FAL_TASK_LINK_PROP_ID;
        end if;

        CreateGenericOperation(NomSchema
                             , tplPropOperation.FAL_TASK_LINK_PROP_ID
                             , tplPropOperation.SCS_SHORT_DESCR
                             , tplPropOperation.SCH_FREE_DESCR
                             , tplPropOperation.PPS_TOOLS1_ID
                             , tplPropOperation.SCS_WORK_TIME
                             , tplPropOperation.SCS_QTY_REF_WORK
                             , tplPropOperation.FAL_FACTORY_FLOOR_ID
                             , tplPropOperation.C_TASK_TYPE
                             , tplPropOperation.PAC_SUPPLIER_PARTNER_ID
                             , tplPropOperation.SCS_QTY_FIX_ADJUSTING
                             , tplPropOperation.SCS_ADJUSTING_TIME
                             , tplPropOperation.TAL_DUE_QTY
                             , tplPropOperation.SCS_PLAN_PROP
                             , tplPropOperation.SCS_PLAN_RATE
                             , tplProposition.GCO_GOOD_ID
                             , tplPropOperation.DIC_FREE_TASK_CODE_ID
                             , tplPropOperation.SCS_TRANSFERT_TIME
                             , tplPropOperation.TAL_BEGIN_PLAN_DATE
                             , tplPropOperation.TAL_END_PLAN_DATE
                             , null   -- TAL_BEGIN_REAL_DATE
                             , null   -- TAL_END_REAL_DATE
                             , null   -- TAL_SUBCONTRACT_QTY
                             , null   -- TAL_RELEASE_QTY
                             , tplPropOperation.TAL_TSK_BALANCE
                             , case tplProposition.C_FAB_TYPE
                                 when '4' then 'F'
                                 else 'M'
                               end
                             , tplPropOperation.SCS_OPEN_TIME_MACHINE
                             , DurationOfRealization
                             , IsAdjustingOperation
                             , NewQtyRefWork
                             , aDoCreateLMU
                              );
        -- CreateQualif détermine s'il faudra créer les qualifications par LMU
        CreateQualif                                := false;

        if (PCS.PC_Config.GetConfig('FAL_ORT_EXPORT_OPERATOR') = 'True') then
          if    (     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
                 and (    (tplPropOperation.DIC_FREE_TASK_CODE_ID = ctOpePreparation)
                      or (tplPropOperation.DIC_FREE_TASK_CODE_ID = ctOpeInjection) )
                )
             or (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') <> '1') then
            CreateQualif  := true;
          end if;
        end if;

        hasLMU                                      := false;

        if aDoCreateLMU = 1 then
          -- Pour chaque machine utilisable de l'opération du lot
          for tplLMU in crLMU(tplPropOperation.FAL_TASK_LINK_PROP_ID, tplPropOperation.FAL_FACTORY_FLOOR_ID) loop
            hasLMU  := true;

            /* Lorsque le temps de travail de l'opération est inférieur au 1/100 de fraction, Ortems arrondi cette valeur à l'unité supérieur
               qui est le centième d'heure. Pour corriger cette erreur, on multiplie le travail et la quantité ref travail par 1000 */
            if tplLMU.SCS_WORK_TIME < 0.9999 then
              tplLMU.SCS_WORK_TIME     := tplLMU.SCS_WORK_TIME * 1000;
              tplLMU.SCS_QTY_REF_WORK  := tplLMU.SCS_QTY_REF_WORK * 1000;
            end if;

            Creation_LMU_et_Qualif(NomSchema
                                 , tplPropOperation.FAL_TASK_LINK_PROP_ID   -- Opération
                                 , tplLMU.FAL_FACTORY_FLOOR_ID   -- Machine
                                 , tplLMU.SCS_WORK_TIME
                                 , tplLMU.SCS_QTY_REF_WORK
                                 , tplLMU.SCS_PRIORITY
                                 , tplLMU.SCS_EXCEPT_MACH
                                 , tplPropOperation.FAL_FAL_FACTORY_FLOOR_ID   -- Opérateur
                                 , CreateQualif
                                 , tplPropOperation.DIC_FREE_TASK_CODE_ID
                                 , tplPropOperation.SCS_NUM_ADJUST_OPERATOR
                                 , tplPropOperation.SCS_NUM_WORK_OPERATOR
                                 , DurationOfRealization
                                 , IsAdjustingOperation
                                 , NewQtyRefWork
                                 , tplPropOperation.SCS_OPEN_TIME_MACHINE
                                  );
          end loop;

          -- Si aucune LMU n'a été créée et qu'il faut affecter des opérateurs,
          -- on crée les LMU de l'îlot ou une machine utilisable correspondant
          -- à la machine de l'opération
          if     not hasLMU
             and (PCS.PC_Config.GetConfig('FAL_ORT_EXPORT_OPERATOR') = 'True')
             and (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') <> '1')
             and tplPropOperation.FAL_FAL_FACTORY_FLOOR_ID is not null then
            if not IsMachine(tplPropOperation.FAL_FACTORY_FLOOR_ID) then
              -- Pour chaque Machine Utilisable de l'îlot
              for tplLMU in (select FAL_FACTORY_FLOOR_ID
                               from FAL_FACTORY_FLOOR
                              where FAL_FAL_FACTORY_FLOOR_ID = tplPropOperation.FAL_FACTORY_FLOOR_ID) loop
                hasLMU  := true;
                Creation_LMU_et_Qualif(NomSchema
                                     , tplPropOperation.FAL_TASK_LINK_PROP_ID   -- Opération
                                     , tplLMU.FAL_FACTORY_FLOOR_ID   -- Machine
                                     , tplPropOperation.SCS_WORK_TIME
                                     , tplPropOperation.SCS_QTY_REF_WORK
                                     , 0   -- Priorité
                                     , 0   -- Machine exceptionnelle
                                     , tplPropOperation.FAL_FAL_FACTORY_FLOOR_ID   -- Opérateur
                                     , true   -- Création des qualifs
                                     , tplPropOperation.DIC_FREE_TASK_CODE_ID
                                     , tplPropOperation.SCS_NUM_ADJUST_OPERATOR
                                     , tplPropOperation.SCS_NUM_WORK_OPERATOR
                                     , DurationOfRealization
                                     , IsAdjustingOperation
                                     , NewQtyRefWork
                                     , tplPropOperation.SCS_OPEN_TIME_MACHINE
                                      );
              end loop;
            end if;

            -- Si on a toujours pas créé de LMU, on en crée une qui correspond à la machine de l'opération
            if not hasLMU then
              Creation_LMU_et_Qualif(NomSchema
                                   , tplPropOperation.FAL_TASK_LINK_PROP_ID   -- Opération
                                   , tplPropOperation.FAL_FACTORY_FLOOR_ID   -- Machine
                                   , tplPropOperation.SCS_WORK_TIME
                                   , tplPropOperation.SCS_QTY_REF_WORK
                                   , 0   -- Priorité
                                   , 0   -- Machine exceptionnelle
                                   , tplPropOperation.FAL_FAL_FACTORY_FLOOR_ID   -- Opérateur
                                   , true   -- Création des qualifs
                                   , tplPropOperation.DIC_FREE_TASK_CODE_ID
                                   , tplPropOperation.SCS_NUM_ADJUST_OPERATOR
                                   , tplPropOperation.SCS_NUM_WORK_OPERATOR
                                   , DurationOfRealization
                                   , IsAdjustingOperation
                                   , NewQtyRefWork
                                   , tplPropOperation.SCS_OPEN_TIME_MACHINE
                                    );
            end if;
          end if;
        end if;

        Creation_Phase(NomSchema
                     , tplProposition.PROP_REFCOMPL   -- Gamme
                     , tplPropOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                     , tplPropOperation.FAL_TASK_LINK_PROP_ID   -- Opération générique
                     , tplPropOperation.SCS_SHORT_DESCR   -- Libellé de la phase (Description courte)
                      );

        if lcPhase <> '0000' then
          CreateOperationLink(aSchemaName             => NomSchema
                            , aGamme                  => tplProposition.PROP_REFCOMPL   -- Gamme
                            , aStartPhase             => lcPhase   -- Phase de départ
                            , aStopPhase              => tplPropOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                            , aCRelationType          => tplPropOperation.C_RELATION_TYPE   -- Type de précédence
                            , aScsDelay               => tplPropOperation.SCS_DELAY   -- Seuil (Retard)
                            , aDicFreeTaskCodeId      => tplPropOperation.DIC_FREE_TASK_CODE_ID
                            , aOpePrecDePreparation   => OpePrecDePreparation
                             );
        end if;

        if (PCS.PC_Config.GetConfig('FAL_ORT_TOOLS_IN_LIMITED_RESS') = 'True') then
          if (     (PCS.PC_Config.GetConfig('FAL_ORT_INDIV') = '1')
              and (tplPropOperation.DIC_FREE_TASK_CODE_ID = ctOpeInjection)
              and OpePrecDePreparation) then
            Reservation_Ress_Limitees(NomSchema
                                    , tplProposition.PROP_REFCOMPL   -- Gamme
                                    , null   -- FAL_SCHEDULE_STEP_ID
                                    , tplPropOperation.FAL_TASK_LINK_PROP_ID   -- Opération
                                    , lcPhase   -- Phase de départ
                                    , tplPropOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                                     );
          elsif(PCS.PC_Config.GetConfig('FAL_ORT_INDIV') <> '1') then
            Reservation_Ress_Limitees(NomSchema
                                    , tplProposition.PROP_REFCOMPL   -- Gamme
                                    , null   -- FAL_SCHEDULE_STEP_ID
                                    , tplPropOperation.FAL_TASK_LINK_PROP_ID   -- Opération
                                    , tplPropOperation.SCS_STEP_NUMBER   -- Phase de départ
                                    , tplPropOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                                     );
          end if;
        end if;

        if tplPropOperation.DIC_FREE_TASK_CODE_ID = ctOpePreparation then
          OpePrecDePreparation  := true;
        else
          OpePrecDePreparation  := false;
        end if;

        if tplPropOperation.C_RELATION_TYPE in('1', '2') then
          loop
            exit when lvBeginBeginPhases is null;
            -- Création des liens entre les opérations précédentes de relation début-début et l'opération en cours de type précédence totale
            CreateOperationLink(aSchemaName             => NomSchema
                              , aGamme                  => tplProposition.PROP_REFCOMPL   -- Gamme
                              , aStartPhase             => substr(lvBeginBeginPhases, 2, 4)   -- Phase de départ
                              , aStopPhase              => tplPropOperation.SCS_STEP_NUMBER   -- Numéro de phase (Séquence)
                              , aCRelationType          => tplPropOperation.C_RELATION_TYPE   -- Type de précédence
                              , aScsDelay               => tplPropOperation.SCS_DELAY   -- Seuil (Retard)
                              , aDicFreeTaskCodeId      => tplPropOperation.DIC_FREE_TASK_CODE_ID
                              , aOpePrecDePreparation   => OpePrecDePreparation
                               );
            lvBeginBeginPhases  := substr(lvBeginBeginPhases, 6, 100);
          end loop;
        elsif tplPropOperation.C_RELATION_TYPE in('4', '5') then
          lvBeginBeginPhases  := lvBeginBeginPhases || ';' || lcPhase;
        end if;

        lcPhase                                     := tplPropOperation.SCS_STEP_NUMBER;
      end loop;

      -- La version est égale aux 10 derniers caractères de Fal_Lot_Prop_Id
      VersionArticle                   := ltrim(substr(lpad(tplProposition.FAL_LOT_PROP_ID, 12), 3, 10) );
      Creation_Version(NomSchema, Article, VersionArticle, tplProposition.PROP_REFCOMPL);   -- Gamme

      -- Si les temps de réglage se font par matrice
      if    (cOrtAdjusting = 3)
         or (cOrtAdjusting = 4)
         or (cOrtAdjusting = 5) then
        for tplParameters in crParameters(tplProposition.FAL_LOT_PROP_ID, tplProposition.GCO_GOOD_ID) loop
          CreateParameterValue(aSchemaName        => NomSchema
                             , aProduct           => Article
                             , aProductVersion    => VersionArticle
                             , aProcessPlanName   => tplProposition.PROP_REFCOMPL
                             , aPhase             => tplParameters.SCS_STEP_NUMBER
                             , aTypeMat           => case cOrtAdjusting
                                 when 4 then 'CODEOP'
                                 else tplParameters.DIC_GCO_CHAR_CODE_TYPE_ID
                               end
                             , aParameter         => case cOrtAdjusting
                                 when 4 then tplParameters.DIC_FREE_TASK_CODE_ID
                                 else tplParameters.FCO_CHA_CODE
                               end
                              );
        end loop;
      end if;

      Delai_CF                         := GetSupplierDelayForProp(tplProposition.FAL_LOT_PROP_ID, null);

      if CheckDelay(tplProposition.GCO_GOOD_ID) = 1 then
        Delai_ORT  := tplProposition.LOT_PLAN_BEGIN_DTE - GetDelay(tplProposition.GCO_GOOD_ID);
      else
        Delai_ORT  := sysdate;
      end if;

      if Delai_CF is null then
        Delai_CF  := Delai_ORT;
      end if;

      CreateBatch(NomSchema
                , tplProposition.PROP_REFCOMPL
                , tplProposition.LOT_SHORT_DESCR
                , tplProposition.FAL_LOT_PROP_ID
                , Article
                , VersionArticle
                , greatest(Delai_CF, Delai_ORT, sysdate - 720)
                , tplProposition.LOT_TOTAL_QTY
                , 'P'   -- Code gestion
                , tplProposition.LOT_PLAN_END_DTE
                , tplProposition.C_FAB_TYPE
                 );
    end loop;
  end;

  /**
  * procédure CreateBatchLinks
  * Description
  *   Création des liens entre OF
  * @author CLE
  * @param   iSchemaName    Schéma d'export Ortems
  * @param   iFromBatch     OF de départ
  * @param   iToBatch       OF d'arrivée
  * @param   iFromPhase     Phase de départ
  * @param   iToPhase       Phase d'arrivée
  */
  procedure CreateBatchLinks(iSchemaName in varchar2, iFromBatch in varchar2, iToBatch in varchar2, iFromPhase in char, iToPhase in char)
  is
    lvSqlQuery varchar2(32000);
  begin
    -- PROF_TYPEPREC = 'T' (précédence totale)
    lvSqlQuery  :=
      ' insert into [CPY].B_PROF ' ||
      '       ( NOF,  NOMG,  NOPHASE,  B_O_NOF,  B_P_NOMG,  B_P_NOPHASE,  PROF_TYPEPREC,  PROF_PROPPREC) ' ||
      ' values(:NOF, :NOMG, :NOPHASE, :B_O_NOF, :B_P_NOMG, :B_P_NOPHASE,  ''T'',          ''NN'')';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iFromBatch, iFromBatch, iFromPhase, iToBatch, iToBatch, iToPhase;
  exception
    when others then
      null;
  end;

  /**
  * procédure ExportBatchLinks
  * Description
  *   Création des liens entre OF en se basant sur le réseau d'attribution.
  *   Si le composant est lié à une opération, le lien se fera directement sur cette opération de l'OF du composé.
  *   Dans tous les autres cas, il se fera sur la première opération de l'OF du composé.
  *   (en partant à chaque fois de la dernière opération du composant)
  * @author CLE
  * @param   iSchemaName    Schéma d'export Ortems
  */
  procedure ExportBatchLinks(iSchemaName in varchar2)
  is
    cursor crBatchAllocation(FalLotId number)
    is
      select FNS.FAL_LOT_ID
           , FNS.FAL_LOT_PROP_ID
        from FAL_NETWORK_LINK FNL
           , FAL_NETWORK_NEED FNN
           , FAL_NETWORK_SUPPLY FNS
       where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
         and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
         and (   FNS.FAL_LOT_ID is not null
              or FNS.FAL_LOT_PROP_ID is not null)
         and (   FNN.FAL_LOT_PROP_ID = FalLotId
              or FNN.FAL_LOT_ID = FalLotId);

    type TOrtemsBatch is record(
      BatchOrPropId  number
    , BatchReference varchar2(30)
    , ToPhase        char(4)
    );

    type TTabOrtemsBatches is table of TOrtemsBatch
      index by binary_integer;

    TabOrtemsBatches    TTabOrtemsBatches;
    lvSqlQuery          varchar2(32000);
    lvBatchOrPropOrigin FAL_LOT.LOT_REFCOMPL%type;
    lcFromPhase         char(4);
    lcToPhase           char(4);
    lcCompoLinkPhase    char(4);
    lnGoodComponentId   number;
  begin
    lvSqlQuery  :=
      'select OF_CH_DESC1
            , NOF
            , (select min(NOPHASE)
                 from [CPY].B_PHAS
                where NOMG = BOF.NOF) TO_PHASE
        from [CPY].B_OF BOF';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
    bulk collect into TabOrtemsBatches;

    if TabOrtemsBatches.count > 0 then
      for i in TabOrtemsBatches.first .. TabOrtemsBatches.last loop
        for tplBatchAllocation in crBatchAllocation(TabOrtemsBatches(i).BatchOrPropId) loop
          if tplBatchAllocation.FAL_LOT_ID is not null then
            select FL.LOT_REFCOMPL
                 , (select lpad(nvl(max(SCS_STEP_NUMBER), 0), 4, '0')
                      from FAL_TASK_LINK
                     where FAL_LOT_ID = tplBatchAllocation.FAL_LOT_ID)
                 , (select lpad(nvl(max(FTL.SCS_STEP_NUMBER), 0), 4, '0')
                      from FAL_LOT_MATERIAL_LINK FLML
                         , FAL_TASK_LINK FTL
                     where FTL.FAL_LOT_ID = FLML.FAL_LOT_ID
                       and FTL.SCS_STEP_NUMBER = FLML.LOM_TASK_SEQ
                       and FLML.FAL_LOT_ID = TabOrtemsBatches(i).BatchOrPropId
                       and FLML.GCO_GOOD_ID = FL.GCO_GOOD_ID)
              into lvBatchOrPropOrigin
                 , lcFromPhase
                 , lcCompoLinkPhase
              from FAL_LOT FL
             where FL.FAL_LOT_ID = tplBatchAllocation.FAL_LOT_ID;
          else
            select PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', FLP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || '-' || FLP.LOT_NUMBER
                 , (select lpad(nvl(max(SCS_STEP_NUMBER), 0), 4, '0')
                      from FAL_TASK_LINK_PROP
                     where FAL_LOT_PROP_ID = tplBatchAllocation.FAL_LOT_PROP_ID)
                 , (select lpad(nvl(max(FTL.SCS_STEP_NUMBER), 0), 4, '0')
                      from FAL_LOT_MAT_LINK_PROP FLML
                         , FAL_TASK_LINK_PROP FTL
                     where FTL.FAL_LOT_PROP_ID = FLML.FAL_LOT_PROP_ID
                       and FTL.SCS_STEP_NUMBER = FLML.LOM_TASK_SEQ
                       and FLML.FAL_LOT_PROP_ID = TabOrtemsBatches(i).BatchOrPropId
                       and FLML.GCO_GOOD_ID = FLP.GCO_GOOD_ID)
              into lvBatchOrPropOrigin
                 , lcFromPhase
                 , lcCompoLinkPhase
              from FAL_LOT_PROP FLP
             where FLP.FAL_LOT_PROP_ID = tplBatchAllocation.FAL_LOT_PROP_ID;
          end if;

          lcToPhase  := greatest(TabOrtemsBatches(i).ToPhase, lcCompoLinkPhase);

          if     (lvBatchOrPropOrigin <> TabOrtemsBatches(i).BatchReference)
             and (lcFromPhase <> '0000')
             and (lcToPhase <> '0000') then
            CreateBatchLinks(iSchemaName   => iSchemaName
                           , iFromBatch    => lvBatchOrPropOrigin
                           , iToBatch      => TabOrtemsBatches(i).BatchReference
                           , iFromPhase    => lcFromPhase
                           , iToPhase      => lcToPhase
                            );
          end if;
        end loop;
      end loop;
    end if;
  end;

  procedure Creation_Marqueur(
    NomSchema      varchar2
  , Desigmarq      varchar2
  , varLotRefCompl varchar2
  , NumeroPhase    char
  , BEDesigmarq    varchar2
  , Codetatm       varchar2
  , BE2Desigmarq   varchar2
  , BECodetatm     varchar2
  , DatePrev       date
  , Operation      integer
  )
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    if Operation = 1 then
      BuffSQL  := 'INSERT INTO ' || NomSchema || '.B_BM(BT_NOPHASE, BT_FRACTION, DESIGMARQ, NOM_ENC, ';
      BuffSQL  := BuffSQL || 'E_NOF, B_E_DESIGMARQ, CODETATM, B_E2_DESIGMARQ, B_E_CODETATM, BM_DATE_PREV) ';
      BuffSQL  := BuffSQL || 'VALUES(:vBT_NOPHASE, :vBT_FRACTION, :vDESIGMARQ, :vNOM_ENC, :vE_NOF, ';
      BuffSQL  := BuffSQL || ':vB_E_DESIGMARQ, :vCODETATM, :vB_E2_DESIGMARQ, :vB_E_CODETATM, :vDATE_PREV)';
    else
      BuffSQL  := 'INSERT INTO ' || NomSchema || '.E_OF_TYPV(DESIGMARQ, NOM_ENC, E_NOF, B_E_DESIGMARQ, ';
      BuffSQL  := BuffSQL || 'CODETATM, B_E2_DESIGMARQ, B_E_CODETATM, OF_DATE_PREV) ';
      BuffSQL  := BuffSQL || 'VALUES(:vDESIGMARQ, :vNOM_ENC, :vE_NOF, :vB_E_DESIGMARQ, ';
      BuffSQL  := BuffSQL || ':vCODETATM, :vB_E2_DESIGMARQ, :vB_E_CODETATM, :vDATE_PREV)';
    end if;

    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);

    if Operation = 1 then
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vBT_NOPHASE', NumeroPhase);
      DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vBT_FRACTION', 0);
    end if;

    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vDESIGMARQ', Desigmarq);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vNOM_ENC', 'ENCOURS');
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vE_NOF', varLotRefCompl);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vB_E_DESIGMARQ', BEDesigmarq);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCODETATM', Codetatm);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vB_E2_DESIGMARQ', BE2Desigmarq);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vB_E_CODETATM', BECodetatm);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vDATE_PREV', DatePrev);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when others then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  procedure CreateMarker(NomSchema varchar2, DesigMarq varchar2)
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'INSERT INTO ' || NomSchema || '.B_TYPV(DESIGMARQ) ';
    BuffSQL         := BuffSQL || 'VALUES(:vDESIGMARQ)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vDESIGMARQ', DesigMarq);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when others then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  procedure CreateMarkerStatus(NomSchema varchar2, DesigMarq varchar2, CodeAtm varchar2, LibEtat varchar2)
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := 'INSERT INTO ' || NomSchema || '.B_ETAM(DESIGMARQ, CODETATM, LIBETAT) ';
    BuffSQL         := BuffSQL || 'VALUES(:vDESIGMARQ, :vCODETATM, :vLIBETAT)';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.native);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vDESIGMARQ', DesigMarq);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vCODETATM', CodeAtm);
    DBMS_SQL.BIND_VARIABLE(Cursor_Handle, 'vLIBETAT', LibEtat);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  exception
    when others then
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  function GetNextValue(Marqueurs in out FAL_TASK_LINK.TAL_ORT_MARKERS%type)
    return varchar2
  is
    result varchar2(20);
  begin
    result     := substr(Marqueurs, 1, instr(Marqueurs, '|', 1) - 1);
    Marqueurs  := substr(Marqueurs, length(result) + 2, length(Marqueurs) );

    if Marqueurs = '' then
      Marqueurs  := null;
    end if;

    return result;
  end;

  procedure Gestion_des_Marqueurs(
    NomSchema      varchar2
  , varLotRefCompl varchar2
  , TalOrtMarkers  varchar2
  , aIsOperation   integer
  , ScsStepNumber  char default null
  , aWork          number default 0
  , CTaskType      FAL_TASK_LINK.C_TASK_TYPE%type default '0'
  )
  is
    Desigmarq    varchar2(10);
    BEDesigmarq  varchar2(10);
    Codetatm     varchar2(5);
    BE2Desigmarq varchar2(10);
    BECodetatm   varchar2(5);
    DatePrev     date;
    Marqueurs    FAL_TASK_LINK.TAL_ORT_MARKERS%type;
  begin
    Marqueurs  := TalOrtMarkers;

    loop
      Desigmarq     := GetNextValue(Marqueurs);
      BEDesigmarq   := GetNextValue(Marqueurs);
      Codetatm      := GetNextValue(Marqueurs);
      BE2Desigmarq  := GetNextValue(Marqueurs);
      BECodetatm    := GetNextValue(Marqueurs);
      DatePrev      := to_date(GetNextValue(Marqueurs), 'DD/MM/YY');
      Creation_Marqueur(NomSchema, Desigmarq, varLotRefCompl, ScsStepNumber, BEDesigmarq, Codetatm, BE2Desigmarq, BECodetatm, DatePrev, aIsOperation);
      exit when Marqueurs is null;
    end loop;

    -- Opération interne sans travail. On la marque en opération spéciale de réglage.
    if     (nvl(aWork, 0) = 0)
       and (CTaskType = '1') then
      Creation_Marqueur(NomSchema
                      , ctAdjOperationMarker
                      , varLotRefCompl
                      , ScsStepNumber
                      , ctAdjOperationMarker
                      , ctAdjOpeMarkerStatus   -- Codetatm
                      , ctAdjOperationMarker
                      , ctAdjOpeMarkerStatus   -- BECodetatm
                      , null   -- DatePrev
                      , 1   -- Operation
                       );
    end if;
  end;

  procedure SetPriority(
    aSchemaName   varchar2
  , aBatchNumber  varchar2
  , aPhase        varchar2
  , aPriority     integer
  , aCFabType     fal_lot.c_fab_type%type
  , aWedgingDate  date
  , aWedgingDescr varchar2
  )
  is
    vQuery       varchar2(32000);
    iAffectForce integer;
  begin
    if    aPriority > 0
       or aCFabType = '4' then
      iAffectForce  := 1;
    else
      iAffectForce  := 0;
    end if;

    vQuery  :=
      'update ' ||
      aSchemaName ||
      '.B_BT ' ||
      '   set BT_PRIORITE      = :BT_PRIORITE ' ||
      '     , BT_AFFECTFORCE   = :BT_AFFECTFORCE ' ||
      '     , BT_DATE_CAL      = :BT_DATE_CAL ' ||
      '     , BT_PROP_DATE_CAL = :BT_PROP_DATE_CAL ' ||
      ' where E_NOF = :E_NOF ' ||
      '   and BT_NOPHASE = :BT_NOPHASE ';

    execute immediate vQuery
                using aPriority, iAffectForce, aWedgingDate, aWedgingDescr, aBatchNumber, aPhase;
  end;

  /**
  * procédure UpdatePriorityWithFixedDate
  * Description
  *   Mise à jour 0 des priorités des opérations qui ont une opération précédente avec une date de calage
  *   supérieure à la date figée.
  * @author CLE
  * @param   iSchemaName    Schéma d'export Ortems
  * @param   iEndFixedDate  Date de fin de la période figée (sysdate + config FAL_ORT_FIX_DELAY)
  */
  procedure UpdatePriorityWithFixedDate(iSchemaName in varchar2, iEndFixedDate in date)
  is
    lvQuery varchar2(32000);
  begin
    lvQuery  :=
      ' update [CPY].B_BT OPE ' ||
      '    set BT_PRIORITE = 0 ' ||
      '      , BT_AFFECTFORCE = 0 ' ||
      '  where exists(select E_NOF ' ||
      '                 from [CPY].B_BT ' ||
      '                where E_NOF = OPE.E_NOF ' ||
      '                  and BT_NOPHASE < OPE.BT_NOPHASE ' ||
      '                  and nvl(BT_DATE_CAL, sysdate) > :iEndFixedDate)';

    execute immediate replace(lvQuery, '[CPY]', iSchemaName)
                using iEndFixedDate;
  end;

  /**
  * procédure UpdateOperations
  * Description
  *   Mise à jour des opérations dans l'en-cours (table B_BT)
  *     - priorité
  *     - marqueurs
  *     - calage
  * @author CLE
  * @param   aSchemaName    Schéma d'export Ortems
  */
  procedure UpdateOperations(aSchemaName varchar2)
  is
    iOp            integer;
    dWedgingDate   date;
    vWedgingDescr  varchar2(15);
    ldEndFixedDate date;
    liPriority     integer;
  begin
    ldEndFixedDate  := sysdate + to_number(PCS.PC_Config.GetConfig('FAL_ORT_FIX_DELAY') );

    for iOp in 1 .. NbreOp loop
      if ListeOperations(iOp).ExternOpeConfirmed then
        /* Opération externe confirmée, on cale la date début */
        dWedgingDate   := ListeOperations(iOp).DateDebut;
        vWedgingDescr  := ListeOperations(iOp).DescrConfirm;
      elsif     (ListeOperations(iOp).CTaskType = '1')
            and (ListeOperations(iOp).SupplierDelay is not null) then
        /* Opération interne avec composant liée dépendant d'un fournisseur, on cale au plus grand délai fournisseur */
        dWedgingDate   := ListeOperations(iOp).SupplierDelay;
        vWedgingDescr  := substr(Pcs.PC_Functions.TranslateWord('Délai appro'), 1, 15);
      else
        dWedgingDate   := null;
        vWedgingDescr  := null;
      end if;

      -- Si la date de calage est supérieure à la date de fin de la période figée, on supprime la priorité
      if nvl(dWedgingDate, sysdate) > ldEndFixedDate then
        liPriority  := 0;
      else
        liPriority  := ListeOperations(iOp).Priorite;
      end if;

      SetPriority(aSchemaName
                , ListeOperations(iOp).NumeroOF
                , ListeOperations(iOp).NumeroPhase
                , liPriority
                , ListeOperations(iOp).CFabType
                , dWedgingDate
                , vWedgingDescr
                 );

      -- Gestion des marqueurs sur les Opérations
      if    (ListeOperations(iOp).Marqueurs is not null)
         or (    nvl(ListeOperations(iOp).aWork, 0) = 0
             and ListeOperations(iOp).CTaskType = '1') then
        Gestion_des_Marqueurs(NomSchema        => aSchemaName
                            , varLotRefCompl   => ListeOperations(iOp).NumeroOF
                            , TalOrtMarkers    => ListeOperations(iOp).Marqueurs
                            , aIsOperation     => 1
                            , ScsStepNumber    => ListeOperations(iOp).NumeroPhase
                            , aWork            => ListeOperations(iOp).aWork
                            , CTaskType        => ListeOperations(iOp).CTaskType
                             );
      end if;
    end loop;

    UpdatePriorityWithFixedDate(aSchemaName, ldEndFixedDate);

    -- Gestion des marqueurs sur les Lots
    for iOp in 1 .. NbreLots loop
      if ListeLots(iOp).Marqueurs is not null then
        Gestion_des_Marqueurs(NomSchema        => aSchemaName
                            , varLotRefCompl   => ListeLots(iOp).RefComplete
                            , TalOrtMarkers    => ListeLots(iOp).Marqueurs
                            , aIsOperation     => 0
                             );
      end if;
    end loop;
  end;

  /**
  * procedure : LaunchOrtems
  * Description : Lancement Ortems
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param     aSchemaName : Nom du schéma Ortems
  */
  procedure LaunchOrtems(aSchemaName varchar2)
  is
    nErrLanc number;
  begin
    execute immediate ' begin ' || aSchemaName || '.LANCEMENT(''S'', :nErrLanc); end;'
                using in out nErrLanc;

    DBMS_OUTPUT.put_line('Nb d''erreurs au lancement Ortems : ' || nErrLanc);
  end;

  /**
  * procedure : ExecuteTracking
  * Description : Exécution de la procédure Ortems de lancememt du suivi
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param     aSchemaName : Nom du schéma Ortems
  */
  procedure ExecuteTracking(aSchemaName varchar2)
  is
    nAck number;
  begin
    execute immediate ' begin ' || aSchemaName || '.SUIVI(:nAck); end;'
                using in out nAck;

    DBMS_OUTPUT.put_line('suivi (ack) : ' || nAck);
  end;

  function PlanningIsOpen(NomSchema varchar2)
    return boolean
  is
    iOpenPlanning integer;
  begin
    execute immediate ' select count(*) ' ||
                      '   from ' ||
                      NomSchema ||
                      '.ENCOURS ' ||
                      '  where NOM_ENC = ''ENCOURS''       ' ||
                      '    and PROPRIETAIRE is not null    '
                 into iOpenPlanning;

    return(iOpenPlanning > 0);
  end;

  /**
   * procedure : GetLogicalPhase
   * Description : Recherche de la plus grande phase logique de toutes les opérations d'un OF dans la table Ortems B_BT
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName  : Nom du schéma Ortems
   * @param     iLotRefcompl : Référence de l'OF
   * @return    max de la phase logique
   */
  function GetLogicalPhase(iSchemaName in varchar2, iLotRefcompl in varchar2)
    return integer
  is
    liMaxLogicalPhase integer;
  begin
    execute immediate ' select max(PHASE_LOGIQUE) ' || '   from ' || iSchemaName || '.B_BT ' || '  where E_NOF = :E_NOF'
                 into liMaxLogicalPhase
                using iLotRefcompl;

    return liMaxLogicalPhase;
  end;

  /**
   * procedure : CreateOperationLinks
   * Description : Création des liens entre opérations pour les nouvelles fractions d'opération
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iLotRefcompl   : Référence de l'OF
   * @param     iScsStepNumber : Phase de l'opération
   * @param     iFracNumber    : Numéro de fraction
   * @param     iCopyStartLink : La création des liens se fait par copie de la fraction 0.
   *                             - iCopyStartLink = 0, copie des liens de fin d'opération
   *                             - iCopyStartLink = 1, copie des liens de début d'opération
   */
  procedure CreateOperationLinks(iSchemaName varchar2, iLotRefcompl varchar2, iScsStepNumber integer, iFracNumber integer, iCopyStartLink integer)
  is
    lvSqlQuery varchar2(32000);
  begin
    lvSqlQuery  :=
      ' insert into [CPY].B_PREN( ' ||
      '          B_B_NOM_ENC ' ||
      '        , B_B_E_NOF ' ||
      '        , B_B_BT_NOPHASE ' ||
      '        , B_B_BT_FRACTION ' ||
      '        , NOM_ENC ' ||
      '        , E_NOF ' ||
      '        , BT_NOPHASE ' ||
      '        , BT_FRACTION ' ||
      '        , BT_TYPEPREC ' ||
      '        , NUMLIEN ' ||
      '        , NATURE_LIEN ' ||
      '        , NUMLIEN_AR ' ||
      '        , BT_PROPPREC ' ||
      '        , BT_LIENMAT ' ||
      '        , BT_LIENCNX ' ||
      '        , BT_TAUXCHEVA ' ||
      '        , QTE_ALIM ' ||
      '        , QTE_CONSO ' ||
      '        , BT_ACTIF ' ||
      '        , STAT ' ||
      '        , CNTER) ' ||
      '       (select  ' ||
      '          B_B_NOM_ENC ' ||
      '        , B_B_E_NOF ' ||
      '        , B_B_BT_NOPHASE ' ||
      '        , decode(:CopyStartLink, 1, B_B_BT_FRACTION, :B_B_BT_FRACTION) ' ||
      '        , NOM_ENC ' ||
      '        , E_NOF ' ||
      '        , BT_NOPHASE ' ||
      '        , decode(:CopyStartLink, 1, :BT_FRACTION, BT_FRACTION) ' ||
      '        , BT_TYPEPREC ' ||
      '        , NUMLIEN ' ||
      '        , NATURE_LIEN ' ||
      '        , NUMLIEN_AR ' ||
      '        , BT_PROPPREC ' ||
      '        , BT_LIENMAT ' ||
      '        , BT_LIENCNX ' ||
      '        , BT_TAUXCHEVA ' ||
      '        , QTE_ALIM ' ||
      '        , QTE_CONSO ' ||
      '        , BT_ACTIF ' ||
      '        , STAT ' ||
      '        , CNTER ' ||
      '         from [CPY].B_PREN  ' ||
      '        where NOM_ENC = ''ENCOURS'' ' ||
      '          and B_B_NOM_ENC = ''ENCOURS'' ' ||
      '          and ( (    :CopyStartLink = 1  ' ||
      '                 and E_NOF = :E_NOF ' ||
      '                 and BT_NOPHASE = :BT_NOPHASE ' ||
      '                 and BT_FRACTION = 0) ' ||
      '             or (    :CopyStartLink = 0  ' ||
      '                 and B_B_E_NOF = :B_B_E_NOF ' ||
      '                 and B_B_BT_NOPHASE = :B_B_BT_NOPHASE ' ||
      '                 and B_B_BT_FRACTION = 0) ) ) ';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iCopyStartLink
                    , iFracNumber
                    , iCopyStartLink
                    , iFracNumber
                    , iCopyStartLink
                    , iLotRefcompl
                    , iScsStepNumber
                    , iCopyStartLink
                    , iLotRefcompl
                    , iScsStepNumber;
  end;

  /**
   * procedure : DeleteObsoleteLinks
   * Description : Suppression des liens obsolètes (pour la fraction 0)
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iLotRefcompl   : Référence du lot
   * @param     iScsStepNumber : Phase de l'opération
   */
  procedure DeleteObsoleteLinks(iSchemaName varchar2, iLotRefcompl varchar2, iScsStepNumber integer)
  is
  begin
    execute immediate 'delete from ' ||
                      iSchemaName ||
                      '.B_PREN where NOM_ENC = ''ENCOURS'' ' ||
                      '          and B_B_NOM_ENC = ''ENCOURS'' ' ||
                      '          and ( (    E_NOF = :E_NOF ' ||
                      '                 and BT_NOPHASE = :BT_NOPHASE ' ||
                      '                 and BT_FRACTION = 0) ' ||
                      '             or (    B_B_E_NOF = :B_B_E_NOF ' ||
                      '                 and B_B_BT_NOPHASE = :B_B_BT_NOPHASE ' ||
                      '                 and B_B_BT_FRACTION = 0) ) '
                using iLotRefcompl, iScsStepNumber, iLotRefcompl, iScsStepNumber;
  end;

  /**
   * procedure : DeleteOriginalOperation
   * Description : Suppression de la fraction 0 de l'opération
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iTableName     : Nom de la table dans laquelle effectuer la suppression
   * @param     iLotRefcompl   : Référence du lot
   * @param     iScsStepNumber : Phase de l'opération
   */
  procedure DeleteOriginalOperation(iSchemaName varchar2, iTableName varchar2, iLotRefcompl varchar2, iScsStepNumber integer)
  is
  begin
    execute immediate 'delete from ' ||
                      iSchemaName ||
                      '.' ||
                      iTableName ||
                      ' where NOM_ENC = ''ENCOURS''
                         and E_NOF = :E_NOF
                         and BT_NOPHASE = :BT_NOPHASE
                         and BT_FRACTION = 0 '
                using iLotRefcompl, iScsStepNumber;
  end;

  /**
   * procedure : CreateLMU
   * Description : Création de la liste de machine utilisable pour les nouvelles fractions
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iLotRefcompl   : Référence du lot
   * @param     iScsStepNumber : Phase de l'opération
   * @param     iFracNumber    : Numéro de fraction
   */
  procedure CreateLMU(iSchemaName varchar2, iLotRefcompl varchar2, iScsStepNumber integer, iFracNumber integer)
  is
    lvSqlQuery varchar2(32000);
  begin
    lvSqlQuery  :=
      'insert into [CPY].ENC_CAD ' ||
      '         (NOM_ENC ' ||
      '        , E_NOF ' ||
      '        , BT_NOPHASE ' ||
      '        , BT_FRACTION ' ||
      '        , ILOT ' ||
      '        , MACHINE ' ||
      '        , ENC_CAD_DURREAL ' ||
      '        , ENC_CAD_PRIORITE   ' ||   -- 1
      '        , ENC_CAD_EFFECTSTAN ' ||
      '        , ENC_CAD_EFFECTMIN ' ||
      '        , ENC_CAD_EFFECTMAX ' ||
      '        , ENC_CAD_MONTEE_CAD ' ||
      '        , ENC_CAD_QTE_FCT ' ||
      '        , ENC_CAD_DURE_INIT   ' ||
      '        , ENC_CAD_CODEBASET ' ||
      '        , ENC_CAD_CODEBASET_CHARGE ' ||
      '        , ENC_CAD_DURREAL_CHARGE ' ||
      '        , ENC_CAD_MODE_CHARGE ' ||
      '        , ENC_CAD_CST_CHARGE ' ||
      '        , ENC_CAD_CSMINIMAL ' ||
      '        , ENC_CAD_CSINITIAL ' ||
      '         ) ' ||
      '   select NOM_ENC ' ||
      '        , E_NOF ' ||
      '        , BT_NOPHASE ' ||
      '        , :BT_FRACTION ' ||
      '        , ILOT ' ||
      '        , MACHINE ' ||
      '        , ENC_CAD_DURREAL ' ||
      '        , 1 ' ||
      '        , ENC_CAD_EFFECTSTAN ' ||
      '        , ENC_CAD_EFFECTMIN ' ||
      '        , ENC_CAD_EFFECTMAX ' ||
      '        , ENC_CAD_MONTEE_CAD ' ||
      '        , ENC_CAD_QTE_FCT ' ||
      '        , ENC_CAD_DURE_INIT   ' ||   -- TODO à voir comment est calculé ce truc (et revoir le temps restant de B_BT)
      '        , ENC_CAD_CODEBASET ' ||
      '        , ENC_CAD_CODEBASET_CHARGE ' ||
      '        , ENC_CAD_DURREAL_CHARGE ' ||
      '        , ENC_CAD_MODE_CHARGE ' ||
      '        , ENC_CAD_CST_CHARGE ' ||
      '        , ENC_CAD_CSMINIMAL ' ||
      '        , ENC_CAD_CSINITIAL   ' ||   -- TODO pas sûr
      '     from [CPY].ENC_CAD ' ||
      '    where NOM_ENC = ''ENCOURS'' ' ||
      '      and E_NOF = :E_NOF ' ||
      '      and BT_NOPHASE = :BT_NOPHASE ' ||
      '      and BT_FRACTION = 0 ';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iFracNumber, iLotRefcompl, iScsStepNumber;
  end;

  /**
   * procedure : CreateQualifRequirements
   * Description : Création des besoins en qualif pour les LMU
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iLotRefcompl   : Référence du lot
   * @param     iScsStepNumber : Phase de l'opération
   * @param     iFracNumber    : Numéro de fraction
   */
  procedure CreateQualifRequirements(iSchemaName varchar2, iLotRefcompl varchar2, iScsStepNumber integer, iFracNumber integer)
  is
    lvSqlQuery varchar2(32000);
  begin
    lvSqlQuery  :=
      ' insert into [CPY].ENC_CAD_QUAL ' ||
      '                 (NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , BT_FRACTION ' ||
      '                , ILOT ' ||
      '                , MACHINE ' ||
      '                , QUALIF ' ||
      '                , CAD_Q_EFFECTMIN ' ||
      '                , CAD_Q_EFFECTMAX ' ||
      '                , CAD_Q_EFFECTREG ' ||
      '                , CAD_Q_CODEAFFEC ' ||
      '                 ) ' ||
      '           select NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , :BT_FRACTION ' ||
      '                , ILOT ' ||
      '                , MACHINE ' ||
      '                , QUALIF ' ||
      '                , CAD_Q_EFFECTMIN ' ||
      '                , CAD_Q_EFFECTMAX ' ||
      '                , CAD_Q_EFFECTREG ' ||
      '                , CAD_Q_CODEAFFEC ' ||
      '             from [CPY].ENC_CAD_QUAL ' ||
      '            where NOM_ENC = ''ENCOURS'' ' ||
      '              and E_NOF = :E_NOF ' ||
      '              and BT_NOPHASE = :BT_NOPHASE ' ||
      '              and BT_FRACTION = 0 ';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iFracNumber, iLotRefcompl, iScsStepNumber;
  end;

  /**
   * procedure : CreateParamValuesPerWorkTicket
   * Description : Création des valeurs de paramètres par bon de travail
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iLotRefcompl   : Référence du lot
   * @param     iScsStepNumber : Phase de l'opération
   * @param     iFracNumber    : Numéro de fraction
   */
  procedure CreateParamValuesPerWorkTicket(iSchemaName varchar2, iLotRefcompl varchar2, iScsStepNumber integer, iFracNumber integer)
  is
    lvSqlQuery varchar2(32000);
  begin
    lvSqlQuery  :=
      ' insert into [CPY].BT_PARM ' ||
      '                 (NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , BT_FRACTION ' ||
      '                , TYPEMAT ' ||
      '                , PARAMETRE ' ||
      '                 ) ' ||
      '           select NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , :BT_FRACTION ' ||
      '                , TYPEMAT ' ||
      '                , PARAMETRE ' ||
      '             from [CPY].BT_PARM ' ||
      '            where NOM_ENC = ''ENCOURS'' ' ||
      '              and E_NOF = :E_NOF ' ||
      '              and BT_NOPHASE = :BT_NOPHASE ' ||
      '              and BT_FRACTION = 0 ';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iFracNumber, iLotRefcompl, iScsStepNumber;
  end;

  /**
   * procedure : CreateContParamPerWorkTicket
   * Description : Création des valeurs de paramètres continus par bon de travail
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iLotRefcompl   : Référence du lot
   * @param     iScsStepNumber : Phase de l'opération
   * @param     iFracNumber    : Numéro de fraction
   */
  procedure CreateContParamPerWorkTicket(iSchemaName varchar2, iLotRefcompl varchar2, iScsStepNumber integer, iFracNumber integer)
  is
    lvSqlQuery varchar2(32000);
  begin
    lvSqlQuery  :=
      ' insert into [CPY].BT_PARMC ' ||
      '                 (NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , BT_FRACTION ' ||
      '                , TYPEMAT ' ||
      '                , PARMC_VAL ' ||
      '                 ) ' ||
      '           select NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , :BT_FRACTION ' ||
      '                , TYPEMAT ' ||
      '                , PARMC_VAL ' ||
      '             from [CPY].BT_PARMC ' ||
      '            where NOM_ENC = ''ENCOURS'' ' ||
      '              and E_NOF = :E_NOF ' ||
      '              and BT_NOPHASE = :BT_NOPHASE ' ||
      '              and BT_FRACTION = 0 ';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iFracNumber, iLotRefcompl, iScsStepNumber;
  end;

  /**
   * procedure : CreateWorkMarking
   * Description : Création des marquages des bons de travaux
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName    : Nom du schéma Ortems
   * @param     iLotRefcompl   : Référence du lot
   * @param     iScsStepNumber : Phase de l'opération
   * @param     iFracNumber    : Numéro de fraction
   */
  procedure CreateWorkMarking(iSchemaName varchar2, iLotRefcompl varchar2, iScsStepNumber integer, iFracNumber integer)
  is
    lvSqlQuery varchar2(32000);
  begin
    lvSqlQuery  :=
      ' insert into [CPY].B_BM ' ||
      '                 (NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , BT_FRACTION ' ||
      '                , DESIGMARQ ' ||
      '                , B_E_DESIGMARQ ' ||
      '                , CODETATM ' ||
      '                , B_E2_DESIGMARQ ' ||
      '                , B_E_CODETATM ' ||
      '                , BM_DATE_PREV ' ||
      '                 ) ' ||
      '           select NOM_ENC ' ||
      '                , E_NOF ' ||
      '                , BT_NOPHASE ' ||
      '                , :BT_FRACTION ' ||
      '                , DESIGMARQ ' ||
      '                , B_E_DESIGMARQ ' ||
      '                , CODETATM ' ||
      '                , B_E2_DESIGMARQ ' ||
      '                , B_E_CODETATM ' ||
      '                , BM_DATE_PREV ' ||
      '             from [CPY].B_BM ' ||
      '            where NOM_ENC = ''ENCOURS'' ' ||
      '              and E_NOF = :E_NOF ' ||
      '              and BT_NOPHASE = :BT_NOPHASE ' ||
      '              and BT_FRACTION = 0 ';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iFracNumber, iLotRefcompl, iScsStepNumber;
  end;

  /**
   * procedure : AddFractionnedOperation
   * Description : Création des fractions des opérations dans la table Ortems B_BT
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName        : Nom du schéma Ortems
   * @param     iFracNumber        : Numéro de fraction
   * @param     iFacReference      : Machine
   * @param     iFracQty           : uantité de la fraction
   * @param     iQty               : Quantité restant sur l'opération
   * @param     iLotInProdQty      : Quantité en production de l'OF
   * @param     iLogicalPhase      : Phase logique
   * @param     iPriority          : Priorité
   * @param     iFalScheduleStepId : Id de l'opération
   */
  procedure AddFractionnedOperation(
    iSchemaName        varchar2
  , iFracNumber        integer
  , iFacReference      varchar2
  , iFracQty           number
  , iOperationQty      number
  , iBatchQty          number
  , iLogicalPhase      integer
  , iPriority          integer
  , iFalScheduleStepId integer
  )
  is
    lvSqlQuery varchar2(32000);
  begin
    lvSqlQuery  :=
      'insert into [CPY].B_BT( ' ||
      '                NOM_ENC                , E_NOF               , BT_NOPHASE ' ||
      '              , BT_FRACTION            , ILOT                , MACHINE ' ||
      '              , B_I_ILOT               , CODE_GPE            , TYP_PIECE ' ||
      '              , UTIL                   , CODOUTILL           , LC ' ||
      '              , ECHELON                , B_L_LC              , B_L_ECHELON ' ||
      '              , B_M_ILOT               , B_M_MACHINE         , BT_QTE ' ||
      '              , BT_DURREAL             , BT_CODEBASET        , BT_QTEREAL ' ||
      '              , BT_QTEREST             , BT_TEMPSPASS        , BT_TEMPSREST ' ||
      '              , BT_DATEFIN             , BT_DATE_CAL         , BT_DATE_CAL_SF ' ||
      '              , BT_DATE_CAL_MP         , BT_COEF_T           , BT_COEF_QTE ' ||
      '              , BT_LIBPHASE            , BT_TEMPSTECH        , BT_AFFECTFORCE ' ||
      '              , BT_ETATOP              , BT_AFFECT           , BT_THM ' ||
      '              , BT_THM_AV              , BT_INTERUPT         , BT_EFFECTSTAN ' ||
      '              , BT_EFFECTMIN           , BT_EFFECTMAX        , BT_MONTEE_CADENCE ' ||
      '              , BT_DURPREP             , BT_DURCHANG         , BT_TEMPSCYCL ' ||
      '              , BT_QTE_FCT             , BT_OPE              , BT_OPEDESCR ' ||
      '              , BT_INTENSITE           , BT_FINPLUSTARD      , BT_DATEG ' ||
      '              , PHASE_LOGIQUE          , BT_PROP_DATE_CAL    , BT_DATE_DATE_CAL ' ||
      '              , CHGT_PARAM             , RANG_GPE_RESS       , PHASE_PROD ' ||
      '              , BT_DATE_DEB_PROD       , BT_PRIORITE         , BT_MEM ' ||
      '              , BT_DISPO               , BT_INTENSITE_QTE    , BT_ROLE ' ||
      '              , BT_ART_CAL_MP          , BT_ART_CAL_SF       , CALAGETOT ' ||
      '              , POTENTIEL              , NATURE              , STATUS_POTENTIEL ' ||
      '              , FORCER_ACTIF_POTENTIEL , DATE_DEB_ENCOURS    , BT_DATE_CAL_SAUVE ' ||
      '              , LBE_PARAM_LOCAUX       , LBE_MARGE_AVANCE    , LBE_CTRL_AVANCE ' ||
      '              , LBE_MARGE_RETARD       , LBE_CTRL_RETARD     , LBE_FIGE ' ||
      '              , LBE_STATUT             , LBE_SPECIF          , BT_PREMSUIVI ' ||
      '              , BT_NUMORDRE            , BT_CODEBASET_CHARGE , BT_DURREAL_CHARGE ' ||
      '              , BT_MODE_CHARGE         , BT_CST_CHARGE       , BT_CSMANAGEMENT ' ||
      '              , BT_CSUNITMODE          , BT_CSMINIMAL        , BT_CSINITIAL ' ||
      '              , BT_CSFREEZE            , BT_COEF_FRAC        , BT_DATE_DEB_OBJ ' ||
      '              , BT_DATE_FIN_OBJ        , BT_DATE_DEB_PLUSTOT , BT_DELAI ' ||
      '              , BT_DATE_DEB_PLA_REF    , BT_DATE_FIN_PLA_REF , BT_STATUT_MATIERE ' ||
      '              , BT_PUN                 , BT_PUN_STATUT       , BT_PUN_DATE_DEB ' ||
      '              , BT_PUN_DATE_FIN        , BT_PUN_DURCHANG     , DATE_PLA ' ||
      '              , DURLCREST              , DURLCRESTI) ' ||
      '         select NOM_ENC                 , E_NOF               , BT_NOPHASE ' ||
      '              , :BT_FRACTION            , ILOT                , nvl(:MACHINE, MACHINE) ' ||
      '              , B_I_ILOT                , CODE_GPE            , TYP_PIECE ' ||
      '              , UTIL                    , CODOUTILL           , LC ' ||
      '              , ECHELON                 , B_L_LC              , B_L_ECHELON ' ||
      '              , B_M_ILOT                , B_M_MACHINE         , :BT_QTE ' ||
      '              , BT_DURREAL              , BT_CODEBASET        , BT_QTEREAL ' ||
      '              , :BT_QTEREST             , BT_TEMPSPASS        , BT_TEMPSREST * :FRAC_COEF ' ||
      '              , BT_DATEFIN              , BT_DATE_CAL         , BT_DATE_CAL_SF ' ||
      '              , BT_DATE_CAL_MP          , BT_COEF_T           , :BT_COEF_QTE ' ||
      '              , BT_LIBPHASE             , BT_TEMPSTECH        , BT_AFFECTFORCE ' ||
      '              , BT_ETATOP               , BT_AFFECT           , BT_THM ' ||
      '              , BT_THM_AV               , BT_INTERUPT         , BT_EFFECTSTAN ' ||
      '              , BT_EFFECTMIN            , BT_EFFECTMAX        , BT_MONTEE_CADENCE ' ||
      '              , BT_DURPREP              , BT_DURCHANG         , BT_TEMPSCYCL ' ||
      '              , BT_QTE_FCT              , BT_OPE              , BT_OPEDESCR ' ||
      '              , BT_INTENSITE            , BT_FINPLUSTARD      , BT_DATEG ' ||
      '              , :PHASE_LOGIQUE          , BT_PROP_DATE_CAL    , BT_DATE_DATE_CAL ' ||
      '              , CHGT_PARAM              , RANG_GPE_RESS       , decode(:BT_FRACTION, 1, 1, 0) ' ||
      '              , BT_DATE_DEB_PROD        , nvl(:BT_PRIORITE, BT_PRIORITE), BT_MEM ' ||
      '              , BT_DISPO                , BT_INTENSITE_QTE    , BT_ROLE ' ||
      '              , BT_ART_CAL_MP           , BT_ART_CAL_SF       , CALAGETOT ' ||
      '              , POTENTIEL               , NATURE              , STATUS_POTENTIEL ' ||
      '              , FORCER_ACTIF_POTENTIEL  , DATE_DEB_ENCOURS    , BT_DATE_CAL_SAUVE ' ||
      '              , LBE_PARAM_LOCAUX        , LBE_MARGE_AVANCE    , LBE_CTRL_AVANCE ' ||
      '              , LBE_MARGE_RETARD        , LBE_CTRL_RETARD     , LBE_FIGE ' ||
      '              , LBE_STATUT              , LBE_SPECIF          , BT_PREMSUIVI ' ||
      '              , BT_NUMORDRE             , BT_CODEBASET_CHARGE , BT_DURREAL_CHARGE ' ||
      '              , BT_MODE_CHARGE          , BT_CST_CHARGE       , BT_CSMANAGEMENT ' ||
      '              , BT_CSUNITMODE           , BT_CSMINIMAL        , 0 ' ||   -- BT_CSINITIAL
      '              , BT_CSFREEZE             , :BT_COEF_FRAC       , BT_DATE_DEB_OBJ ' ||
      '              , BT_DATE_FIN_OBJ         , BT_DATE_DEB_PLUSTOT , BT_DELAI ' ||
      '              , BT_DATE_DEB_PLA_REF     , BT_DATE_FIN_PLA_REF , BT_STATUT_MATIERE ' ||
      '              , BT_PUN                  , BT_PUN_STATUT       , BT_PUN_DATE_DEB ' ||
      '              , BT_PUN_DATE_FIN         , BT_PUN_DURCHANG     , DATE_PLA ' ||
      '              , DURLCREST               , DURLCRESTI ' ||
      '           from [CPY].B_BT  ' ||
      '          where BT_OPE = :BT_OPE ' ||
      '            and BT_FRACTION = 0 ';

    execute immediate replace(lvSqlQuery, '[CPY]', iSchemaName)
                using iFracNumber   -- BT_FRACTION
                    , iFacReference   -- MACHINE
                    , iFracQty   -- BT_QTE
                    , iFracQty   -- BT_QTEREST
                    , iFracQty / iOperationQty   -- BT_TEMPSREST (= BT_TEMPSREST * :FRAC_COEF)
                    , iFracQty / iBatchQty   -- BT_COEF_QTE
                    , iLogicalPhase   -- PHASE_LOGIQUE
                    , iFracNumber   -- PHASE_PROD (= decode(:BT_FRACTION, 1, 1, 0) )
                    , iPriority   -- BT_PRIORITE
                    , iFracQty / iOperationQty   -- BT_COEF_FRAC
                    , iFalScheduleStepId;   -- BT_OPE
  end;

  /**
   * procedure : CreateOperationFractions
   * Description : Création des fractions des opérations
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     aSchemaName : Nom du schéma Ortems
   */
  procedure CreateOperationFractions(aSchemaName varchar2)
  is
    cursor crFractionedOperation(aFalScheduelStepId number)
    is
      select   TAL.TAL_NUM_UNITS_ALLOCATED
             , TAL.TAL_DUE_QTY
             , nvl(LMU_PRIORITY, 0) LMU_PRIORITY
             , (select trim(substr(FAC_REFERENCE, 1, 10) )
                  from FAL_FACTORY_FLOOR
                 where FAL_FACTORY_FLOOR_ID = LMU.FAL_FACTORY_FLOOR_ID) FAC_REFERENCE
             , LOT.LOT_INPROD_QTY
             , LOT.LOT_REFCOMPL
             , TAL.SCS_STEP_NUMBER
          from FAL_LOT LOT
             , FAL_TASK_LINK TAL
             , FAL_TASK_LINK_USE LMU
         where TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
           and LMU.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID
           and TAL.FAL_SCHEDULE_STEP_ID = aFalScheduelStepId
      order by nvl(LMU.LMU_FRAC_NUMBER, 0) desc;

    tplFractionedOperation crFractionedOperation%rowtype;
    i                      integer;
    lvLotRefcompl          FAL_LOT.LOT_REFCOMPL%type;
    liScsStepNumber        integer;
    liFracNumber           integer;
    liFraction             integer;
    lnFracQty              number;
    lnDueQty               number;
    lnOperationQty         number;
    lnBatchQty             number;
    liPriority             integer;
    lvFacReference         varchar2(10);
  begin
    if BatchOpeFractionedId.count > 0 then
      -- Pour chaque opération à fractionner (Ressources affectées > 0)
      for i in BatchOpeFractionedId.first .. BatchOpeFractionedId.last loop
        open crFractionedOperation(BatchOpeFractionedId(i) );

        fetch crFractionedOperation
         into tplFractionedOperation;

        liFracNumber     := 0;
        liFraction       := tplFractionedOperation.TAL_NUM_UNITS_ALLOCATED;
        lnDueQty         := tplFractionedOperation.TAL_DUE_QTY;
        lnOperationQty   := tplFractionedOperation.TAL_DUE_QTY;
        lvLotRefcompl    := tplFractionedOperation.LOT_REFCOMPL;
        liScsStepNumber  := tplFractionedOperation.SCS_STEP_NUMBER;
        lnBatchQty       := tplFractionedOperation.LOT_INPROD_QTY;

        loop
          exit when liFraction = 0;
          liFracNumber    := liFracNumber + 1;
          lnFracQty       := trunc(lnDueQty / liFraction);
          lnDueQty        := lnDueQty - lnFracQty;
          lvFacReference  := null;
          liPriority      := null;

          if crFractionedOperation%found then
            lvFacReference  := tplFractionedOperation.FAC_REFERENCE;
            liPriority      := tplFractionedOperation.LMU_PRIORITY;

            fetch crFractionedOperation
             into tplFractionedOperation;
          end if;

          -- Création de la fraction de l'opération
          AddFractionnedOperation(iSchemaName          => aSchemaName
                                , iFracNumber          => liFracNumber
                                , iFacReference        => lvFacReference
                                , iFracQty             => lnFracQty
                                , iOperationQty        => lnOperationQty
                                , iBatchQty            => lnBatchQty
                                , iLogicalPhase        => GetLogicalPhase(aSchemaName, lvLotRefcompl) + 1
                                , iPriority            => liPriority
                                , iFalScheduleStepId   => BatchOpeFractionedId(i)
                                 );
          -- Création des liens entre opérations
          CreateOperationLinks(aSchemaName, lvLotRefcompl, liScsStepNumber, liFracNumber, 1);
          CreateOperationLinks(aSchemaName, lvLotRefcompl, liScsStepNumber, liFracNumber, 0);
          -- Création de la liste de machine utilisable pour les nouvelles fractions
          CreateLMU(aSchemaName, lvLotRefcompl, liScsStepNumber, liFracNumber);
          -- Création des besoins en qualif pour les LMU
          CreateQualifRequirements(aSchemaName, lvLotRefcompl, liScsStepNumber, liFracNumber);
          -- Création des valeurs de paramètres par bon de travail
          CreateParamValuesPerWorkTicket(aSchemaName, lvLotRefcompl, liScsStepNumber, liFracNumber);
          -- Création des valeurs de paramètres continus par bon de travail
          CreateContParamPerWorkTicket(aSchemaName, lvLotRefcompl, liScsStepNumber, liFracNumber);
          -- Création des marquages des bons de travaux
          CreateWorkMarking(aSchemaName, lvLotRefcompl, liScsStepNumber, liFracNumber);
          liFraction      := liFraction - 1;
        end loop;

        close crFractionedOperation;

        -- Suppression des liens obsolètes (pour la fraction 0)
        DeleteObsoleteLinks(aSchemaName, lvLotRefcompl, liScsStepNumber);
        -- Suppression des marquages des bons de travaux
        DeleteOriginalOperation(aSchemaName, 'B_BM', lvLotRefcompl, liScsStepNumber);
        -- Suppression de la fraction 0 dans les valeurs de paramètres continus par bon de travail (BT_PARMC)
        DeleteOriginalOperation(aSchemaName, 'BT_PARMC', lvLotRefcompl, liScsStepNumber);
        -- Suppression de la fraction 0 dans les valeurs de paramètres par bon de travail (BT_PARM)
        DeleteOriginalOperation(aSchemaName, 'BT_PARM', lvLotRefcompl, liScsStepNumber);
        -- Suppression de la fraction 0 dans les besoins en qualif pour les LMU (ENC_CAD_QUAL)
        DeleteOriginalOperation(aSchemaName, 'ENC_CAD_QUAL', lvLotRefcompl, liScsStepNumber);
        -- Suppression de la fraction 0 dans les LMU (ENC_CAD)
        DeleteOriginalOperation(aSchemaName, 'ENC_CAD', lvLotRefcompl, liScsStepNumber);
        -- Suppression de la fraction 0 de l opération
        DeleteOriginalOperation(aSchemaName, 'B_BT', lvLotRefcompl, liScsStepNumber);
      end loop;
    end if;
  end;

  function GetBatchCount(aSchemaName varchar2, aSearchPropositions boolean default false)
    return integer
  is
    vQuery      varchar2(32000);
    iBatchCount integer;
  begin
    vQuery  := ' select count(*) ' || ' from ' || aSchemaName || '.B_OF ';

    if aSearchPropositions then
      vQuery  := vQuery || '  where CODEGEST = ''P''';
    else
      vQuery  := vQuery || '  where CODEGEST = ''F''';
    end if;

    execute immediate vQuery
                 into iBatchCount;

    return iBatchCount;
  end;

  /**
   * procedure : PurgeLogTable
   * Description : Suppression des enregistrements de la table journal antérieurs à 2 mois en arrière
   *
   * @created CLE
   * @lastUpdate
   * @public
   * @param     iSchemaName : Nom du schéma Ortems
   */
  procedure PurgeLogTable(iSchemaName varchar2)
  is
  begin
    execute immediate ' delete from ' || iSchemaName || '.JOURNAL where DATE_ERR < SYSDATE-60';
  end;

  procedure Exportation_OF_et_POF(
    NomSchema                     varchar2
  , aExportPropositions           integer
  , aExportPlannedBatches         integer
  , aExportLaunchedBatches        integer
  , FalJobProgramId               number   -- Prog de Fabrication
  , FalOrderId                    number   -- Ordre
  , FalLotId                      number   -- Lot de fabrication
  , LotPlanBeginDte               date   -- Date max
  , LotPlanEndDte                 date   -- Date min
  , DicFamilyId                   DIC_FAMILY.DIC_FAMILY_ID%type   -- Code famille
  , DocRecordId                   number   -- Dossier
  , GcoGoodId                     number   -- Produit
  , DicAccountableGroupId         DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type   -- Groupe de responsable
  , GcoGoodCategoryId             number   -- Catégorie
  , DicFloorFreeCodeId            DIC_FLOOR_FREE_CODE.DIC_FLOOR_FREE_CODE_ID%type   -- Code libre 1
  , DicFloorFreeCode2Id           DIC_FLOOR_FREE_CODE2.DIC_FLOOR_FREE_CODE2_ID%type   -- Code libre 2
  , NbreLotExportes        in out integer
  , NbrePOFExportees       in out integer
  , Resultat               in out integer
  )
  is
    -- Déclaration des variables
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    vErrLanc       number;
  begin
    if PlanningIsOpen(NomSchema) then
      Resultat  := -1;
      DBMS_OUTPUT.put_line('Exportation impossible. Vous devez fermer le planning Ortems avant de lancer l''exportation.');
    else
      Resultat  := 1;
      Purge_Ortems(NomSchema);
      PurgeLogTable(NomSchema);
      Export_Donnees_Statiques(NomSchema);
      CreateMarker(NomSchema, ctAdjOperationMarker);
      CreateMarkerStatus(NomSchema, ctAdjOperationMarker, ctAdjOpeMarkerStatus, 'Setting operat.');

      if cOrtAdjusting = 2 then
        CreateAdustingTool(NomSchema);
      end if;

      CreateAdvanceSerieClass(NomSchema);

      if    (aExportPlannedBatches = 1)
         or (aExportLaunchedBatches = 1) then
        ExportBatches(NomSchema
                    , aExportPlannedBatches
                    , aExportLaunchedBatches
                    , FalJobProgramId   -- Prog de Fabrication
                    , FalOrderId   -- Ordre
                    , FalLotId   -- Lot de fabrication
                    , LotPlanBeginDte   -- Date max
                    , LotPlanEndDte   -- Date min
                    , DicFamilyId   -- Code famille
                    , DocRecordId   -- Dossier
                    , GcoGoodId   -- Produit
                    , DicAccountableGroupId   -- Groupe de responsable
                    , GcoGoodCategoryId   -- Catégorie
                    , DicFloorFreeCodeId   -- Code libre 1
                    , DicFloorFreeCode2Id   -- Code libre 2
                     );
        NbreLotExportes  := GetBatchCount(NomSchema);
      end if;

      if aExportPropositions = 1 then
        ExportPropositions(NomSchema
                         , LotPlanBeginDte   -- Date max
                         , LotPlanEndDte   -- Date min
                         , DicFamilyId   -- Code famille
                         , DocRecordId   -- Dossier
                         , GcoGoodId   -- Produit
                         , DicAccountableGroupId   -- Groupe de responsable
                         , GcoGoodCategoryId   -- Catégorie
                         , DicFloorFreeCodeId   -- Code libre 1
                         , DicFloorFreeCode2Id   -- Code libre 2
                          );
        NbrePOFExportees  := GetBatchCount(NomSchema, true);
      end if;

      ExportBatchLinks(NomSchema);
      ExecuteProc(NomSchema, PCS.PC_Config.GetConfig('FAL_ORT_PROC_ON_EXPORT') );
      LaunchOrtems(NomSchema);
      UpdateOperations(NomSchema);
      ExecuteTracking(NomSchema);

      if PCS.PC_Config.GetBooleanConfig('FAL_ORT_USE_FRACTION') then
        CreateOperationFractions(NomSchema);
      end if;

      -- On conserve la date du dernier export des données dynamiques
      update FAL_ORT_SCHEMA
         set FOS_EXPORT_LOT_DATE = sysdate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FOS_SCHEMA_NAME = NomSchema;

      DBMS_OUTPUT.put_line(NbreLotExportes || ' lots exportés.');
      DBMS_OUTPUT.put_line(NbrePOFExportees || ' propositions exportées.');
    end if;
  end;

  procedure Suppression_Totale(NomSchema varchar2)
  is
  begin
    Purge_Ortems(NomSchema);
    PurgeTable(NomSchema, 'PARM_MACH');
    PurgeTable(NomSchema, 'TYPMC_ILOT');
    PurgeTable(NomSchema, 'TYPM_MACH');
    PurgeTable(NomSchema, 'TYPM_ILOT');
    PurgeTable(NomSchema, 'B_MTPAC3');
    PurgeTable(NomSchema, 'B_MTPAC2');
    PurgeTable(NomSchema, 'B_MTPAC');
    PurgeTable(NomSchema, 'B_MTPA2');
    PurgeTable(NomSchema, 'B_MTPA');
    PurgeTable(NomSchema, 'P_CEFF_MACH');
    PurgeTable(NomSchema, 'P_QUAL');
    PurgeTable(NomSchema, 'P_CEX_OPRT');
    PurgeTable(NomSchema, 'B_ETAM');
    PurgeTable(NomSchema, 'B_TYPV');
    PurgeTable(NomSchema, 'P_CEX_MACH');
    PurgeTable(NomSchema, 'MACH_PLAN_CAP');
    PurgeTable(NomSchema, 'B_AFQU');
    PurgeTable(NomSchema, 'B_MTPA3');
    PurgeTable(NomSchema, 'B_PARM');
    PurgeTable(NomSchema, 'B_TYPM');
    PurgeTable(NomSchema, 'B_MTR');
    PurgeTable(NomSchema, 'B_OUTI');
    PurgeTable(NomSchema, 'B_AFOP');
    PurgeTable(NomSchema, 'B_MACH_LEAD');
    PurgeTable(NomSchema, 'B_MACH');
    PurgeTable(NomSchema, 'B_ILOT');
    PurgeTable(NomSchema, 'B_TRAN');
    PurgeTable(NomSchema, 'B_ZONE');
    PurgeTable(NomSchema, 'B_SECT');
    PurgeTable(NomSchema, 'B_LIMI');
    PurgeTable(NomSchema, 'B_OPRT');
    PurgeTable(NomSchema, 'B_QUAL');
  end;
end;
