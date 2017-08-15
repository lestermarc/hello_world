--------------------------------------------------------
--  DDL for Package Body FAL_ORTEMS_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ORTEMS_IMPORT" 
is
  cDefaultStockID    constant number := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');
  cDefaultLocationID constant number := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', cDefaultStockID);
  cDefaultServiceId  constant number := FAL_TOOLS.GetConfigDefaultService;
  cPpsRateDay        constant number := to_number(PCS.PC_Config.GetConfig('PPS_RATE_DAY') );

  /**
  * procédure GetEndFixedDate
  * Description
  *   Retourne la date fin de la période figée
  * @author CLE
  * @param   aSchemaName    Schéma d'export Ortems
  */
  function GetEndFixedDate(aSchemaName varchar2)
    return date
  is
    ldBeginFixedDate date;
  begin
    execute immediate ' select max(DATE_DEB_HOR) from ' || aSchemaName || '.ENCOURS where NOM_ENC = ''ENCOURS'''
                 into ldBeginFixedDate;

    return ldBeginFixedDate + to_number(PCS.PC_Config.GetConfig('FAL_ORT_FIX_DELAY') );
  end;

  procedure UpdateOperation(
    aFalTaskLinkId         varchar2
  , aBeginPlanDate         FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE%type
  , aEndPlanDate           FAL_TASK_LINK.TAL_END_PLAN_DATE%type
  , aFacReference          varchar2
  , aPriority              FAL_TASK_LINK.TAL_ORT_PRIORITY%type
  , aRemainingTime         number
  , aIsBatchOperation      boolean
  , aWedgingDate           date
  , aWedgingDescr          FAL_TASK_LINK.TAL_CONFIRM_DESCR%type
  , iIsFractionedOperation integer
  )
  is
    cursor crFactoryFloor(aFactoryFloorId number)
    is
      select FAC.FAL_FACTORY_FLOOR_ID
           , FAC.FAC_INFINITE_FLOOR
           , (select decode(nvl(FAC_IS_MACHINE, 0), 1, FAL_FAL_FACTORY_FLOOR_ID, FAL_FACTORY_FLOOR_ID) FACTORY_FLOOR_ID
                from FAL_FACTORY_FLOOR
               where FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID) NEW_MACHINE_GROUP
           , (select decode(nvl(FAC_IS_MACHINE, 0), 1, FAL_FAL_FACTORY_FLOOR_ID, FAL_FACTORY_FLOOR_ID) FACTORY_FLOOR_ID
                from FAL_FACTORY_FLOOR
               where FAL_FACTORY_FLOOR_ID = aFactoryFloorId) OLD_MACHINE_GROUP
        from FAL_FACTORY_FLOOR FAC
       where rtrim(substr(FAC_REFERENCE, 1, 10) ) = aFacReference;

    tplFactoryFloor     crFactoryFloor%rowtype;
    iPriority           integer;
    vCTaskType          FAL_TASK_LINK.C_TASK_TYPE%type;
    dConfirmDate        date;
    vConfirmDescr       FAL_TASK_LINK.TAL_CONFIRM_DESCR%type;
    nFactoryFloorId     number;
    nSupplierPartnerId  number;
    nScsPlanRate        number;
    iIsInfiniteCapacity integer;
    cSubcField          varchar2(30);
    vSqlQuery           varchar2(2000);
  begin
    iIsInfiniteCapacity  := 0;
    dConfirmDate         := null;
    vConfirmDescr        := null;
    cSubcField           := PCS.PC_Config.GetConfig('FAL_ORT_SUBCONTRACT_FIELD');
    vSqlQuery            :=
      'select max(SUP.PAC_SUPPLIER_PARTNER_ID) ' ||
      '  from PAC_PERSON PER ' ||
      '     , PAC_SUPPLIER_PARTNER SUP ' ||
      ' where PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID ' ||
      '   and rtrim(substr([FIELD_NAME], 1, 10) ) = :aFacReference ';

    if cSubcField is null then
      vSqlQuery  := replace(vSqlQuery, '[FIELD_NAME]', 'PER.PER_NAME');
    else
      vSqlQuery  := replace(vSqlQuery, '[FIELD_NAME]', 'nvl(SUP.' || cSubcField || ', PER.PER_NAME)');
    end if;

    execute immediate vSqlQuery
                 into nSupplierPartnerId
                using aFacReference;

    if nSupplierPartnerId is not null then
      -- C'est un sous-traitant
      vCTaskType           := '2';
      nFactoryFloorId      := null;
      iPriority            := null;
      iIsInfiniteCapacity  := 1;
    else
      -- C'est un atelier
      if aIsBatchOperation then
        select FAL_FACTORY_FLOOR_ID
          into nFactoryFloorId
          from FAL_TASK_LINK
         where FAL_SCHEDULE_STEP_ID = aFalTaskLinkId;
      else
        select FAL_FACTORY_FLOOR_ID
          into nFactoryFloorId
          from FAL_TASK_LINK_PROP
         where FAL_TASK_LINK_PROP_ID = aFalTaskLinkId;
      end if;

      open crFactoryFloor(nFactoryFloorId);

      fetch crFactoryFloor
       into tplFactoryFloor;

      nFactoryFloorId     := tplFactoryFloor.FAL_FACTORY_FLOOR_ID;
      nSupplierPartnerId  := null;
      vCTaskType          := '1';
      iPriority           := aPriority;

      if tplFactoryFloor.OLD_MACHINE_GROUP <> tplFactoryFloor.NEW_MACHINE_GROUP then
        -- Si l'opération a changé d'îlot, suppression des LMU
        if aIsBatchOperation then
          delete from FAL_TASK_LINK_USE
                where FAL_SCHEDULE_STEP_ID = aFalTaskLinkId;
        else
          delete from FAL_TASK_LINK_PROP_USE
                where FAL_TASK_LINK_PROP_ID = aFalTaskLinkId;
        end if;
      end if;

      if     (tplFactoryFloor.FAC_INFINITE_FLOOR = 1)
         and ( (aRemainingTime / 3600) > FAL_OPERATION_FUNCTIONS.GetJobDuration(aFalTaskLinkId) ) then
        iIsInfiniteCapacity  := 1;
      end if;

      close crFactoryFloor;
    end if;

    if iIsInfiniteCapacity = 1 then
      -- Durée restante en minutes
      nScsPlanRate  :=(aRemainingTime / 60);
      -- Durée restante en jour/fraction de jours ouvrés
      nScsPlanRate  := FAL_PLANIF.GetDurationInOpenDay(nFactoryFloorId, nSupplierPartnerId, aBeginPlanDate, nScsPlanRate, 1);
    end if;

    -- Pour Ortems, une opération avec une date calage > SYSDATE - 2 ans est calée
    -- On enlève 720 jours pour garder une marge. Il aurait été beaucoup mieux si
    -- Ortems avait utilisé un booléen pour déterminer si une date est calée ou non !
    if aWedgingDate >(sysdate - 720) then
      dConfirmDate   := aWedgingDate;
      vConfirmDescr  := aWedgingDescr || ' (Ortems)';
    end if;

    if aIsBatchOperation then
      if iIsInfiniteCapacity = 1 then
        -- Suppression des LMU
        delete from FAL_TASK_LINK_USE
              where FAL_SCHEDULE_STEP_ID = aFalTaskLinkId;
      end if;

      -- Mise à jour de l'opération de lot
      update FAL_TASK_LINK
         set TAL_BEGIN_PLAN_DATE = aBeginPlanDate
           , TAL_END_PLAN_DATE = aEndPlanDate
           , C_TASK_TYPE = vCTaskType
           , FAL_FACTORY_FLOOR_ID = nFactoryFloorId
           , FAL_FAL_FACTORY_FLOOR_ID = decode(vCTaskType, '2', null, FAL_FAL_FACTORY_FLOOR_ID)
           , PAC_SUPPLIER_PARTNER_ID = nSupplierPartnerId
           , SCS_PLAN_RATE = nScsPlanRate
           , SCS_PLAN_PROP = decode(iIsInfiniteCapacity, 1, 0, SCS_PLAN_PROP)
           , TAL_TASK_MANUF_TIME = decode(vCTaskType, '2', nScsPlanRate, TAL_TASK_MANUF_TIME)
           , GCO_GCO_GOOD_ID = decode(vCTaskType, '1', null, nvl(GCO_GCO_GOOD_ID, cDefaultServiceId) )
           , TAL_ORT_PRIORITY = iPriority
           , TAL_CONFIRM_DATE = case vCTaskType
                                 when '2' then decode(dConfirmDate, null, TAL_CONFIRM_DATE, dConfirmDate)
                                 else null
                               end
           , TAL_CONFIRM_DESCR = case vCTaskType
                                  when '2' then decode(vConfirmDescr, null, TAL_CONFIRM_DESCR, vConfirmDescr)
                                  else null
                                end
           , TAL_ORT_IS_FRACTIONED = iIsFractionedOperation
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = aFalTaskLinkId;

      -- Mise à jour des documents liés au sous-traitant
      if nSupplierPartnerId is not null then
        FAL_PRC_SUBCONTRACTO.UpdateSubcontractDelay(iFalTaskLinkId => aFalTaskLinkId, iNewDelay => aEndPlanDate, iUpdatedDelay => 'FINAL');
      end if;
    else
      if iIsInfiniteCapacity = 1 then
        -- Suppression des LMU
        delete from FAL_TASK_LINK_PROP_USE
              where FAL_TASK_LINK_PROP_ID = aFalTaskLinkId;
      end if;

      -- Mise à jour de l'opération de proposition
      update FAL_TASK_LINK_PROP
         set TAL_BEGIN_PLAN_DATE = aBeginPlanDate
           , TAL_END_PLAN_DATE = aEndPlanDate
           , C_TASK_TYPE = vCTaskType
           , FAL_FACTORY_FLOOR_ID = nFactoryFloorId
           , FAL_FAL_FACTORY_FLOOR_ID = decode(vCTaskType, '2', null, FAL_FAL_FACTORY_FLOOR_ID)
           , PAC_SUPPLIER_PARTNER_ID = nSupplierPartnerId
           , SCS_PLAN_RATE = nScsPlanRate
           , SCS_PLAN_PROP = decode(iIsInfiniteCapacity, 1, 0, SCS_PLAN_PROP)
           , TAL_TASK_MANUF_TIME = decode(vCTaskType, '2', nScsPlanRate, TAL_TASK_MANUF_TIME)
           , GCO_GOOD_ID = decode(vCTaskType, '1', null, nvl(GCO_GOOD_ID, cDefaultServiceId) )
           , TAL_ORT_PRIORITY = iPriority
           , TAL_CONFIRM_DATE = case vCTaskType
                                 when '2' then decode(dConfirmDate, null, TAL_CONFIRM_DATE, dConfirmDate)
                                 else null
                               end
           , TAL_CONFIRM_DESCR = case vCTaskType
                                  when '2' then decode(vConfirmDescr, null, TAL_CONFIRM_DESCR, vConfirmDescr)
                                  else null
                                end
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_TASK_LINK_PROP_ID = aFalTaskLinkId;
    end if;
  end;

  procedure ManageFractionedOperation(aScheduleStepId number, aMachine varchar2, aFractionNumber integer, aFractionCoef number, aPriority integer)
  is
    iCntLmu integer;
  begin
    select count(*)
      into iCntLmu
      from FAL_TASK_LINK_USE LMU
     where FAL_SCHEDULE_STEP_ID = aScheduleStepId
       and (select trim(substr(FAC_REFERENCE, 1, 10) )
              from FAL_FACTORY_FLOOR
             where FAL_FACTORY_FLOOR_ID = LMU.FAL_FACTORY_FLOOR_ID) = aMachine;

    if iCntLmu > 0 then
      update FAL_TASK_LINK_USE LMU
         set LMU_FRAC_NUMBER = aFractionNumber
           , LMU_FRAC_COEF = nvl(LMU_FRAC_COEF, 0) + aFractionCoef
           , LMU_PRIORITY = aPriority
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = aScheduleStepId
         and (select trim(substr(FAC_REFERENCE, 1, 10) )
                from FAL_FACTORY_FLOOR
               where FAL_FACTORY_FLOOR_ID = LMU.FAL_FACTORY_FLOOR_ID) = aMachine;
    else
      insert into FAL_TASK_LINK_USE
                  (FAL_TASK_LINK_USE_ID
                 , FAL_FACTORY_FLOOR_ID
                 , FAL_SCHEDULE_STEP_ID
                 , SCS_QTY_REF_WORK
                 , SCS_WORK_TIME
                 , SCS_PRIORITY
                 , SCS_EXCEPT_MACH
                 , LMU_FRAC_NUMBER
                 , LMU_FRAC_COEF
                 , LMU_PRIORITY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_TEMP_ID_SEQ.nextval
             , (select FAL_FACTORY_FLOOR_ID
                  from FAL_FACTORY_FLOOR
                 where trim(substr(FAC_REFERENCE, 1, 10) ) = aMachine)
             , aScheduleStepId
             , TSK.SCS_QTY_REF_WORK
             , TSK.SCS_WORK_TIME
             , 100
             , 0
             , aFractionNumber
             , afractionCoef
             , aPriority
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from FAL_TASK_LINK TSK
         where FAL_SCHEDULE_STEP_ID = aScheduleStepId;
    end if;
  end;

  /**
  * procédure UpdateOperations
  * Description
  *   Mise à jour des opérations d'OF et de propositions
  * @author CLE
  * @param   NomSchema        Schéma d'export Ortems
  * @param   DateFinPerFigee
  */
  procedure UpdateOperations(aSchemaName varchar2, DateFinPerFigee date)
  is
    cursor CUR_FAL_TASK_LINK(FalScheduleStepId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    is
      select TAL_BEGIN_PLAN_DATE
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = FalScheduleStepId;

    type TOperation is record(
      BtOpe             varchar2(30)
    , DatePla           date
    , BtDatefin         date
    , Ilot              varchar2(10)
    , Machine           varchar2(10)
    , DateCalage        date
    , LibelleCalage     varchar2(50)
    , BtTempsRest       number
    , BtFraction        integer
    , BtCoefFrac        number
    , iIsBatchOperation integer
    , iIsPropOperation  integer
    );

    type TTabOperations is table of TOperation
      index by binary_integer;

    TabOperations          TTabOperations;
    i                      integer;
    vSqlQuery              varchar2(4000);
    iPriority              integer;
    vMachine               varchar2(10);
    vFacReference          varchar2(10);
    iIsFractionedOperation integer;
    CntMachFract           integer;
  begin
    -- Mise à NULL de la priorité des opérations
    update FAL_TASK_LINK
       set TAL_ORT_PRIORITY = null
         , TAL_ORT_MARKERS = null
         , TAL_ORT_IS_FRACTIONED = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni;

    update FAL_TASK_LINK_USE
       set LMU_FRAC_NUMBER = null
         , LMU_FRAC_COEF = null
         , LMU_PRIORITY = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where nvl(LMU_FRAC_NUMBER, 0) <> 0;

    update FAL_TASK_LINK_PROP
       set TAL_ORT_PRIORITY = null
         , TAL_ORT_MARKERS = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni;

    /* Dans Ortems, le temps de réglage (temps de changement de paramètres) est bien séparé de l'opération elle-même. Pour remonter la date début dans PCS,
       on a besoin de la date début de changement de paramètres d'Ortems. Il faut, dans le Planning, activer l'option "Réglages" dans la boîte de dialogue du
       menu "Fichier / Configurer les réglages". On retrouve alors la date de début du réglage dans la table  E_Reg, champ D_Deb_Chg avec :
          (B_Bt -> e_nof = E_Reg -> b_b_e_nof)
       ET (B_Bt -> bt_nophase) = (E_Reg -> b_b_bt_nophase) */
    vSqlQuery      :=
      'select distinct  bb.bt_ope                          ' ||
      '     , decode(nvl(er.duree_chg, 0), 0, bb.date_pla, nvl(er.d_deb_chg, bb.date_pla) ) date_pla ' ||
      '       , bb.bt_datefin                              ' ||
      '       , bb.ilot                                    ' ||
      '       , bb.machine                                 ' ||
      '       , bb.bt_date_cal                             ' ||
      '       , bb.bt_prop_date_cal                        ' ||
      '       , bb.bt_tempsrest                            ' ||
      '       , bb.bt_fraction                             ' ||
      '       , bb.bt_coef_frac                            ' ||
      '       , (select count(*)                           ' ||
      '            from fal_task_link                      ' ||
      '           where fal_schedule_step_id = bb.bt_ope)  ' ||
      '           is_batch_operation                       ' ||
      '       , (select count(*)                           ' ||
      '            from fal_task_link_prop                 ' ||
      '           where fal_task_link_prop_id = bb.bt_ope) ' ||
      '           is_prop_operation                        ' ||
      '    from [CPY].b_bt bb                              ' ||
      '       , [CPY].e_reg er                             ' ||
      '   where bb.e_nof = er.b_b_e_nof(+)                 ' ||
      '     and bb.bt_nophase = er.b_b_bt_nophase(+)       ' ||
      'order by ilot                                       ' ||
      '       , machine                                    ' ||
      '       , date_pla';
    vSqlQuery      := replace(vSqlQuery, '[CPY]', aSchemaName);

    execute immediate vSqlQuery
    bulk collect into TabOperations;

    vFacReference  := null;
    vMachine       := null;

    if TabOperations.count > 0 then
      for i in TabOperations.first .. TabOperations.last loop
        iIsFractionedOperation  := 0;
        CntMachFract            := 0;

        if TabOperations(i).BtFraction > 0 then
          execute immediate ' select max(bt_datefin)         ' ||
                            '      , sum(bt_tempsrest)       ' ||
                            '      , count(distinct machine) ' ||
                            '  from ' ||
                            aSchemaName ||
                            '.b_bt ' ||
                            'where bt_ope = :bt_ope '
                       into TabOperations(i).BtDatefin
                          , TabOperations(i).BtTempsRest
                          , CntMachFract
                      using TabOperations(i).BtOpe;
        end if;

        if    (vMachine is null)
           or (vMachine <> TabOperations(i).Machine) then
          vMachine   := TabOperations(i).Machine;
          iPriority  := 999;
        end if;

        if TabOperations(i).DatePla < DateFinPerFigee then
          vFacReference  := TabOperations(i).Machine;
          iPriority      := iPriority - 1;

          if     (TabOperations(i).iIsBatchOperation > 0)
             and (CntMachFract > 1) then
            -- On ne gère les fractions d'opérations que si elles sont réparties sur au moins deux machines différentes
            iIsFractionedOperation  := 1;
            vFacReference           := TabOperations(i).Ilot;
          end if;
        else
          iPriority      := null;
          vFacReference  := TabOperations(i).Ilot;
        end if;

        if    (TabOperations(i).iIsBatchOperation > 0)
           or (TabOperations(i).iIsPropOperation > 0) then
          if TabOperations(i).BtFraction <= 1 then
            UpdateOperation(TabOperations(i).BtOpe
                          , TabOperations(i).DatePla
                          , TabOperations(i).BtDatefin
                          , vFacReference
                          , iPriority
                          , TabOperations(i).BtTempsRest
                          , (TabOperations(i).iIsBatchOperation > 0)
                          , TabOperations(i).DateCalage
                          , TabOperations(i).LibelleCalage
                          , iIsFractionedOperation
                           );
          end if;

          if iIsFractionedOperation = 1 then
            ManageFractionedOperation(TabOperations(i).BtOpe, vMachine, TabOperations(i).BtFraction, TabOperations(i).BtCoefFrac, iPriority);
          end if;
        end if;
      end loop;
    end if;
  end;

  procedure Import_Marqueurs_Operation(NomSchema varchar2)
  is
    -- Déclaration des variables
    BuffSQL         varchar2(2000);
    Cursor_Handle   integer;
    Execute_Cursor  integer;
    varDesigmarq    varchar2(10);
    varBEDesigmarq  varchar2(10);
    varCodetatm     varchar2(5);
    varBE2Desigmarq varchar2(10);
    varBECodetatm   varchar2(5);
    varBmDatePrev   date;
    varBtOpe        varchar2(24);
  begin
    BuffSQL         := 'SELECT  DESIGMARQ, ';
    BuffSQL         := BuffSQL || 'B_E_DESIGMARQ, ';
    BuffSQL         := BuffSQL || 'CODETATM, ';
    BuffSQL         := BuffSQL || 'B_E2_DESIGMARQ, ';
    BuffSQL         := BuffSQL || 'B_E_CODETATM, ';
    BuffSQL         := BuffSQL || 'BM_DATE_PREV, ';
    BuffSQL         := BuffSQL || 'BT_OPE ';
    BuffSQL         := BuffSQL || 'FROM ' || NomSchema || '.B_BM, ';
    BuffSQL         := BuffSQL || NomSchema || '.B_BT ';
    BuffSQL         := BuffSQL || 'WHERE B_BM.NOM_ENC = B_BT.NOM_ENC ';
    BuffSQL         := BuffSQL || '  AND B_BM.E_NOF = B_BT.E_NOF ';
    BuffSQL         := BuffSQL || '  AND B_BM.BT_NOPHASE = B_BT.BT_NOPHASE ';
    BuffSQL         := BuffSQL || '  AND B_BM.BT_FRACTION = B_BT.BT_FRACTION ';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 1, varDesigmarq, 10);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 2, varBEDesigmarq, 10);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 3, varCodetatm, 5);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 4, varBE2Desigmarq, 10);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 5, varBECodetatm, 5);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 6, varBmDatePrev);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 7, varBtOpe, 24);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    loop
      if DBMS_SQL.FETCH_ROWS(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, varDesigmarq);
        DBMS_SQL.column_value(Cursor_Handle, 2, varBEDesigmarq);
        DBMS_SQL.column_value(Cursor_Handle, 3, varCodetatm);
        DBMS_SQL.column_value(Cursor_Handle, 4, varBE2Desigmarq);
        DBMS_SQL.column_value(Cursor_Handle, 5, varBECodetatm);
        DBMS_SQL.column_value(Cursor_Handle, 6, varBmDatePrev);
        DBMS_SQL.column_value(Cursor_Handle, 7, varBtOpe);

        -- Le marqueur ctAdjOperationMarker n'est utilisé que pour différencier les
        -- opérations de réglage (qui n'ont pas de travail dans PCS des autres. On
        -- ne le réimporte pas, c'est à l'export, uniquemment pour ce type d'opération
        -- qu'il est mis en place.
        if varDesigmarq <> FAL_ORTEMS_EXPORT.ctAdjOperationMarker then
          update FAL_TASK_LINK
             set TAL_ORT_MARKERS =
                   TAL_ORT_MARKERS ||
                   varDesigmarq ||
                   '|' ||
                   varBEDesigmarq ||
                   '|' ||
                   varCodetatm ||
                   '|' ||
                   varBE2Desigmarq ||
                   '|' ||
                   varBECodetatm ||
                   '|' ||
                   to_char(to_date(varBmDatePrev, 'DD/MM/YY') ) ||
                   '|'
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_SCHEDULE_STEP_ID = varBtOpe;

          update FAL_TASK_LINK_PROP
             set TAL_ORT_MARKERS =
                   TAL_ORT_MARKERS ||
                   varDesigmarq ||
                   '|' ||
                   varBEDesigmarq ||
                   '|' ||
                   varCodetatm ||
                   '|' ||
                   varBE2Desigmarq ||
                   '|' ||
                   varBECodetatm ||
                   '|' ||
                   to_char(to_date(varBmDatePrev, 'DD/MM/YY') ) ||
                   '|'
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_TASK_LINK_PROP_ID = varBtOpe;
        end if;
      else
        exit;
      end if;
    end loop;

    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  procedure Import_Marqueurs_Lot(NomSchema varchar2)
  is
    -- Déclaration des variables
    BuffSQL         varchar2(2000);
    Cursor_Handle   integer;
    Execute_Cursor  integer;
    varDesigmarq    varchar2(10);
    varBEDesigmarq  varchar2(10);
    varCodetatm     varchar2(5);
    varBE2Desigmarq varchar2(10);
    varBECodetatm   varchar2(5);
    varOfDatePrev   date;
    EOfChDes1       varchar2(15);
  begin
    update FAL_LOT
       set LOT_ORT_MARKERS = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni;

    update FAL_LOT_PROP
       set LOT_ORT_MARKERS = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni;

    BuffSQL         := 'SELECT  DESIGMARQ, ';
    BuffSQL         := BuffSQL || 'B_E_DESIGMARQ, ';
    BuffSQL         := BuffSQL || 'CODETATM, ';
    BuffSQL         := BuffSQL || 'B_E2_DESIGMARQ, ';
    BuffSQL         := BuffSQL || 'B_E_CODETATM, ';
    BuffSQL         := BuffSQL || 'OF_DATE_PREV, ';
    BuffSQL         := BuffSQL || 'E_OF_CH_DESC1 ';
    BuffSQL         := BuffSQL || 'FROM ' || NomSchema || '.E_OF_TYPV, ';
    BuffSQL         := BuffSQL || NomSchema || '.E_OF ';
    BuffSQL         := BuffSQL || 'WHERE E_OF_TYPV.NOM_ENC = E_OF.NOM_ENC ';
    BuffSQL         := BuffSQL || '  AND E_OF_TYPV.E_NOF = E_OF.E_NOF ';
    Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 1, varDesigmarq, 10);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 2, varBEDesigmarq, 10);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 3, varCodetatm, 5);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 4, varBE2Desigmarq, 10);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 5, varBECodetatm, 5);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 6, varOfDatePrev);
    DBMS_SQL.DEFINE_COLUMN(Cursor_Handle, 7, EOfChDes1, 15);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    loop
      if DBMS_SQL.FETCH_ROWS(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, varDesigmarq);
        DBMS_SQL.column_value(Cursor_Handle, 2, varBEDesigmarq);
        DBMS_SQL.column_value(Cursor_Handle, 3, varCodetatm);
        DBMS_SQL.column_value(Cursor_Handle, 4, varBE2Desigmarq);
        DBMS_SQL.column_value(Cursor_Handle, 5, varBECodetatm);
        DBMS_SQL.column_value(Cursor_Handle, 6, varOfDatePrev);
        DBMS_SQL.column_value(Cursor_Handle, 7, EOfChDes1);

        update FAL_LOT
           set LOT_ORT_MARKERS =
                 LOT_ORT_MARKERS ||
                 varDesigmarq ||
                 '|' ||
                 varBEDesigmarq ||
                 '|' ||
                 varCodetatm ||
                 '|' ||
                 varBE2Desigmarq ||
                 '|' ||
                 varBECodetatm ||
                 '|' ||
                 to_char(to_date(varOfDatePrev, 'DD/MM/YY') ) ||
                 '|'
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_LOT_ID = EOfChDes1;

        update FAL_LOT_PROP
           set LOT_ORT_MARKERS =
                 LOT_ORT_MARKERS ||
                 varDesigmarq ||
                 '|' ||
                 varBEDesigmarq ||
                 '|' ||
                 varCodetatm ||
                 '|' ||
                 varBE2Desigmarq ||
                 '|' ||
                 varBECodetatm ||
                 '|' ||
                 to_char(to_date(varOfDatePrev, 'DD/MM/YY') ) ||
                 '|'
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_LOT_PROP_ID = EOfChDes1;
      else
        exit;
      end if;
    end loop;

    DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
  end;

  /**
  * procedure UpdateBatches
  * Description
  *   Mise à jour des dates des OF et propositions
  *   Mise à jour réseaux
  *   Mise à jour des liens composants
  *   Création d'un historique d'OF de planification Ortems
  * @author CLE
  * @param   aSchemaName    Schéma d'export Ortems
  */
  procedure UpdateBatches(aSchemaName varchar2)
  is
    cursor crBatchOrtems
    is
      select FAL_LOT_ID
           , LOT_PLAN_BEGIN_DTE
           , LOT_PLAN_END_DTE
           , LOT_REFCOMPL
           , 'F' TYPE_BATCH
           , C_FAB_TYPE
        from FAL_LOT;

    type TcrBatchOrtems is table of crBatchOrtems%rowtype;

    vSqlQuery        varchar2(2000);
    iBatch           integer;
    tplBatchOrtems   TcrBatchOrtems;
    Cursor_Handle    integer;
    Execute_Cursor   integer;
    varEOfChDesc1    varchar2(30);
    varEOfDateDebPla date;
    varEOfDateFinPla date;
    varENof          varchar2(30);
  begin
    vSqlQuery  :=
      'select E_OF_CH_DESC1 ' ||
      ' , E_OF_DATE_DEB_PLA  ' ||
      ' , E_OF_DATE_FIN_PLA  ' ||
      ' , E_NOF ' ||
      ' , E_CODEGEST ' ||
      ' , FREE1 ' ||
      ' from ' ||
      aSchemaName ||
      '.E_OF ';

    execute immediate vSqlQuery
    bulk collect into tplBatchOrtems;

    if tplBatchOrtems.count > 0 then
      for iBatch in tplBatchOrtems.first .. tplBatchOrtems.last loop
        if tplBatchOrtems(iBatch).TYPE_BATCH = 'F' then
          -- OF "Ferme" = lot PCS
          if tplBatchOrtems(iBatch).C_FAB_TYPE = '4' then
            -- OF de type sous-traitance
            FAL_PRC_SUBCONTRACTP.UpdateSubcontractDelay(tplBatchOrtems(iBatch).LOT_PLAN_BEGIN_DTE, tplBatchOrtems(iBatch).FAL_LOT_ID);
          end if;

          update FAL_LOT
             set LOT_PLAN_BEGIN_DTE = tplBatchOrtems(iBatch).LOT_PLAN_BEGIN_DTE
               , LOT_PLAN_END_DTE = tplBatchOrtems(iBatch).LOT_PLAN_END_DTE
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_LOT_ID = tplBatchOrtems(iBatch).FAL_LOT_ID;

          -- Mise à jour de l'historique de lot de fabrication.
          FAL_PLANIF.StorePlanifOrigin(tplBatchOrtems(iBatch).FAL_LOT_ID
                                     , '22'
                                     , tplBatchOrtems(iBatch).LOT_PLAN_BEGIN_DTE
                                     , tplBatchOrtems(iBatch).LOT_PLAN_END_DTE
                                      );
          -- Mise a jour Date reseaux appro
          FAL_NETWORK.ReseauApproFAL_MAJ(aLotID               => tplBatchOrtems(iBatch).FAL_LOT_ID
                                       , aDefaultStockID      => null
                                       , aDefaultLocationID   => null
                                       , aUpdateType          => 2
                                       , aStockPositionID     => null
                                        );
          FAL_PLANIF.MAJ_LiensComposantsLot(tplBatchOrtems(iBatch).FAL_LOT_ID, tplBatchOrtems(iBatch).LOT_PLAN_END_DTE);
          -- Mise à Jour Date Réseaux Besoin
          FAL_NETWORK.ReseauBesoinFAL_MAJ(tplBatchOrtems(iBatch).FAL_LOT_ID, cDefaultStockID, cDefaultLocationID, 2,   -- aUpdateType  (1 : Mise à jour complète, 2 : Mise à jour Date)
                                          0);   -- aAllowDelete (Si > 0, alors Si Composant.LOM_NEED_QTY = 0 alors suppression du record de Fal_Network_Need)
        else
          -- OF "Prévisionnel" = Proposition
          update FAL_LOT_PROP
             set LOT_PLAN_BEGIN_DTE = tplBatchOrtems(iBatch).LOT_PLAN_BEGIN_DTE
               , LOT_PLAN_END_DTE = tplBatchOrtems(iBatch).LOT_PLAN_END_DTE
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_LOT_PROP_ID = tplBatchOrtems(iBatch).FAL_LOT_ID;

          -- Mise a jour Date reseaux appro
          FAL_NETWORK.ReseauApproPropositionFAL_MAJ(aFAL_LOT_PROP_ID => tplBatchOrtems(iBatch).FAL_LOT_ID, aContext => FAL_NETWORK.ncPlanificationLotProp);
          FAL_PLANIF.MAJ_LiensComposantsProp(tplBatchOrtems(iBatch).FAL_LOT_ID, tplBatchOrtems(iBatch).LOT_PLAN_END_DTE);
          -- Mise à Jour Date Réseaux Besoin
          FAL_NETWORK.ReseauBesoinPropositionFAL_MAJ(tplBatchOrtems(iBatch).FAL_LOT_ID);
        end if;
      end loop;
    end if;
  end;

  /**
  * fonction PlanningIsSaved
  * Description
  *   Retourne True si le planning est sauvé, False sinon.
  *   Un planning est sauvé si les dates des OF ne sont plus à null.
  * @author CLE
  * @param   NomSchema    Schéma d'export Ortems
  * @return  numéro de version d'Ortems
  */
  function PlanningIsSaved(aSchemaName varchar2)
    return boolean
  is
    vQuery     varchar2(32000);
    iCntRecord integer;
  begin
    vQuery  := ' select count(*) from ' || aSchemaName || '.E_OF where E_OF_DATE_DEB_PLA is null  ';

    execute immediate vQuery
                 into iCntRecord;

    return(iCntRecord = 0);
  end;

  /**
  * procédure Import_Ortems_To_PCS
  * Description
  *   Mise à jour du schéma société PCS avec les données Ortems
  * @author CLE
  * @param   NomSchema    Schéma d'export Ortems
  * @param   Resultat     in out, retourne -1 si le planning n'a pas été sauvé, 1 dans les autres cas
  */
  procedure Import_Ortems_To_PCS(NomSchema varchar2, Resultat in out number)
  is
    DateFinPerFigee date;
  begin
    DateFinPerFigee  := GetEndFixedDate(NomSchema);

    if PlanningIsSaved(NomSchema) then
      Resultat  := 1;
      UpdateOperations(NomSchema, DateFinPerFigee);
      Import_Marqueurs_Operation(NomSchema);
      Import_Marqueurs_Lot(NomSchema);
      UpdateBatches(NomSchema);
      FAL_ORTEMS_EXPORT.ExecuteProc(NomSchema, PCS.PC_Config.GetConfig('FAL_ORT_PROC_ON_IMPORT') );

      -- On conserve la date de la dernière mise à jour
      update FAL_ORT_SCHEMA
         set FOS_UPDATE_DATA_DATE = sysdate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FOS_SCHEMA_NAME = NomSchema;
    else
      Resultat  := -1;
      DBMS_OUTPUT.PUT_LINE('Importation impossible. Vous devez valider l''en-cours dans Ortems avant de lancer l''importation.');
    end if;
  end;
end;
