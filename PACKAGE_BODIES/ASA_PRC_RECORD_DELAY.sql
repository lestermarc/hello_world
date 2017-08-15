--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_DELAY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_DELAY" 
is
  /**
  * function pSetFlagsUpdatedFields
  * Description
  *   Màj des flags des champs modifiés
  */
  function pSetFlagsUpdatedFields(
    iOldDelay  in     ASA_DELAY_HISTORY%rowtype
  , ioNewDelay in out ASA_DELAY_HISTORY%rowtype
  )
    return boolean
  is
    lDummyDate   date    default to_date('01.01.1888', 'dd.mm.yyyy');
    lDummyNumber number  default -99999999;
    lUpdated     boolean default false;
  begin
    -- Init à 0 du flag indiquant un changement du champ correspondant
    ioNewDelay.ADH_DATE_REG_REP       := 0;
    ioNewDelay.ADH_NB_DAYS_WAIT       := 0;
    ioNewDelay.ADH_NB_DAYS_WAIT_COMP  := 0;
    ioNewDelay.ADH_NB_DAYS_WAIT_MAX   := 0;
    ioNewDelay.ADH_DATE_START_REP     := 0;
    ioNewDelay.ADH_NB_DAYS            := 0;
    ioNewDelay.ADH_DATE_END_REP       := 0;
    ioNewDelay.ADH_NB_DAYS_CTRL       := 0;
    ioNewDelay.ADH_DATE_END_CTRL      := 0;
    ioNewDelay.ADH_NB_DAYS_EXP        := 0;
    ioNewDelay.ADH_DATE_START_EXP     := 0;
    ioNewDelay.ADH_NB_DAYS_SENDING    := 0;
    ioNewDelay.ADH_DATE_END_SENDING   := 0;
    ioNewDelay.ADH_REQ_DATE_C         := 0;
    ioNewDelay.ADH_CONF_DATE_C        := 0;
    ioNewDelay.ADH_UPD_DATE_C         := 0;
    ioNewDelay.ADH_REQ_DATE_S         := 0;
    ioNewDelay.ADH_CONF_DATE_S        := 0;
    ioNewDelay.ADH_UPD_DATE_S         := 0;

    -- Màj le flag à 1 si le champ a été changé
    if nvl(iOldDelay.ARE_DATE_REG_REP, lDummyDate) <> nvl(ioNewDelay.ARE_DATE_REG_REP, lDummyDate) then
      ioNewDelay.ADH_DATE_REG_REP  := 1;
    end if;

    if nvl(iOldDelay.ARE_NB_DAYS_WAIT, lDummyNumber) <> nvl(ioNewDelay.ARE_NB_DAYS_WAIT, lDummyNumber) then
      ioNewDelay.ADH_NB_DAYS_WAIT  := 1;
    end if;

    if nvl(iOldDelay.ARE_NB_DAYS_WAIT_COMP, lDummyNumber) <> nvl(ioNewDelay.ARE_NB_DAYS_WAIT_COMP, lDummyNumber) then
      ioNewDelay.ADH_NB_DAYS_WAIT_COMP  := 1;
    end if;

    if nvl(iOldDelay.ARE_NB_DAYS_WAIT_MAX, lDummyNumber) <> nvl(ioNewDelay.ARE_NB_DAYS_WAIT_MAX, lDummyNumber) then
      ioNewDelay.ADH_NB_DAYS_WAIT_MAX  := 1;
    end if;

    if nvl(iOldDelay.ARE_DATE_START_REP, lDummyDate) <> nvl(ioNewDelay.ARE_DATE_START_REP, lDummyDate) then
      ioNewDelay.ADH_DATE_START_REP  := 1;
    end if;

    if nvl(iOldDelay.ARE_NB_DAYS, lDummyNumber) <> nvl(ioNewDelay.ARE_NB_DAYS, lDummyNumber) then
      ioNewDelay.ADH_NB_DAYS  := 1;
    end if;

    if nvl(iOldDelay.ARE_DATE_END_REP, lDummyDate) <> nvl(ioNewDelay.ARE_DATE_END_REP, lDummyDate) then
      ioNewDelay.ADH_DATE_END_REP  := 1;
    end if;

    if nvl(iOldDelay.ARE_NB_DAYS_CTRL, lDummyNumber) <> nvl(ioNewDelay.ARE_NB_DAYS_CTRL, lDummyNumber) then
      ioNewDelay.ADH_NB_DAYS_CTRL  := 1;
    end if;

    if nvl(iOldDelay.ARE_DATE_END_CTRL, lDummyDate) <> nvl(ioNewDelay.ARE_DATE_END_CTRL, lDummyDate) then
      ioNewDelay.ADH_DATE_END_CTRL  := 1;
    end if;

    if nvl(iOldDelay.ARE_NB_DAYS_EXP, lDummyNumber) <> nvl(ioNewDelay.ARE_NB_DAYS_EXP, lDummyNumber) then
      ioNewDelay.ADH_NB_DAYS_EXP  := 1;
    end if;

    if nvl(iOldDelay.ARE_DATE_START_EXP, lDummyDate) <> nvl(ioNewDelay.ARE_DATE_START_EXP, lDummyDate) then
      ioNewDelay.ADH_DATE_START_EXP  := 1;
    end if;

    if nvl(iOldDelay.ARE_NB_DAYS_SENDING, lDummyNumber) <> nvl(ioNewDelay.ARE_NB_DAYS_SENDING, lDummyNumber) then
      ioNewDelay.ADH_NB_DAYS_SENDING  := 1;
    end if;

    if nvl(iOldDelay.ARE_DATE_END_SENDING, lDummyDate) <> nvl(ioNewDelay.ARE_DATE_END_SENDING, lDummyDate) then
      ioNewDelay.ADH_DATE_END_SENDING  := 1;
    end if;

    if nvl(iOldDelay.ARE_REQ_DATE_C, lDummyDate) <> nvl(ioNewDelay.ARE_REQ_DATE_C, lDummyDate) then
      ioNewDelay.ADH_REQ_DATE_C  := 1;
    end if;

    if nvl(iOldDelay.ARE_CONF_DATE_C, lDummyDate) <> nvl(ioNewDelay.ARE_CONF_DATE_C, lDummyDate) then
      ioNewDelay.ADH_CONF_DATE_C  := 1;
    end if;

    if nvl(iOldDelay.ARE_UPD_DATE_C, lDummyDate) <> nvl(ioNewDelay.ARE_UPD_DATE_C, lDummyDate) then
      ioNewDelay.ADH_UPD_DATE_C  := 1;
    end if;

    if nvl(iOldDelay.ARE_REQ_DATE_S, lDummyDate) <> nvl(ioNewDelay.ARE_REQ_DATE_S, lDummyDate) then
      ioNewDelay.ADH_REQ_DATE_S  := 1;
    end if;

    if nvl(iOldDelay.ARE_CONF_DATE_S, lDummyDate) <> nvl(ioNewDelay.ARE_CONF_DATE_S, lDummyDate) then
      ioNewDelay.ADH_CONF_DATE_S  := 1;
    end if;

    if nvl(iOldDelay.ARE_UPD_DATE_S, lDummyDate) <> nvl(ioNewDelay.ARE_UPD_DATE_S, lDummyDate) then
      ioNewDelay.ADH_UPD_DATE_S  := 1;
    end if;

    lUpdated                          :=
         (ioNewDelay.ADH_DATE_REG_REP = 1)
      or (ioNewDelay.ADH_NB_DAYS_WAIT = 1)
      or (ioNewDelay.ADH_NB_DAYS_WAIT_COMP = 1)
      or (ioNewDelay.ADH_NB_DAYS_WAIT_MAX = 1)
      or (ioNewDelay.ADH_DATE_START_REP = 1)
      or (ioNewDelay.ADH_NB_DAYS = 1)
      or (ioNewDelay.ADH_DATE_END_REP = 1)
      or (ioNewDelay.ADH_NB_DAYS_CTRL = 1)
      or (ioNewDelay.ADH_DATE_END_CTRL = 1)
      or (ioNewDelay.ADH_NB_DAYS_EXP = 1)
      or (ioNewDelay.ADH_DATE_START_EXP = 1)
      or (ioNewDelay.ADH_NB_DAYS_SENDING = 1)
      or (ioNewDelay.ADH_DATE_END_SENDING = 1)
      or (ioNewDelay.ADH_REQ_DATE_C = 1)
      or (ioNewDelay.ADH_CONF_DATE_C = 1)
      or (ioNewDelay.ADH_UPD_DATE_C = 1)
      or (ioNewDelay.ADH_REQ_DATE_S = 1)
      or (ioNewDelay.ADH_CONF_DATE_S = 1)
      or (ioNewDelay.ADH_UPD_DATE_S = 1);
    return lUpdated;
  end pSetFlagsUpdatedFields;

  /**
  * function pLoadLastDelays
  * Description
  *   Renvoi la dernière ligne d'historique pour le dossier SAV
  */
  function pLoadLastDelays(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return ASA_DELAY_HISTORY%rowtype
  is
    lOldDelay ASA_DELAY_HISTORY%rowtype;
  begin
    begin
      select *
        into lOldDelay
        from ASA_DELAY_HISTORY
       where ASA_RECORD_ID = iAsaRecordID
         and ADH_SEQ = (select max(ADH_SEQ)
                          from ASA_DELAY_HISTORY
                         where ASA_RECORD_ID = iAsaRecordID);
    exception
      when no_data_found then
        lOldDelay  := null;
    end;

    return lOldDelay;
  end pLoadLastDelays;

  /**
  * function pLoadCurrentDelays
  * Description
  *   Renvoi les délais actuels du dossier SAV
  */
  function pLoadCurrentDelays(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return ASA_DELAY_HISTORY%rowtype
  is
    lCurDelay ASA_DELAY_HISTORY%rowtype;
  begin
    begin
      select ASA_RECORD_ID
           , C_ASA_REP_STATUS
           , null as DIC_DELAY_UPDATE_TYPE_ID
           , null as ADH_DELAY_UPDATE_TEXT
           , ARE_DATE_REG_REP
           , ARE_NB_DAYS_WAIT
           , ARE_NB_DAYS_WAIT_COMP
           , ARE_NB_DAYS_WAIT_MAX
           , ARE_DATE_START_REP
           , ARE_NB_DAYS
           , ARE_DATE_END_REP
           , ARE_NB_DAYS_CTRL
           , ARE_DATE_END_CTRL
           , ARE_NB_DAYS_EXP
           , ARE_DATE_START_EXP
           , ARE_NB_DAYS_SENDING
           , ARE_DATE_END_SENDING
           , ARE_REQ_DATE_C
           , ARE_CONF_DATE_C
           , ARE_UPD_DATE_C
           , ARE_REQ_DATE_S
           , ARE_CONF_DATE_S
           , ARE_UPD_DATE_S
        into lCurDelay.ASA_RECORD_ID
           , lCurDelay.C_ASA_REP_STATUS
           , lCurDelay.DIC_DELAY_UPDATE_TYPE_ID
           , lCurDelay.ADH_DELAY_UPDATE_TEXT
           , lCurDelay.ARE_DATE_REG_REP
           , lCurDelay.ARE_NB_DAYS_WAIT
           , lCurDelay.ARE_NB_DAYS_WAIT_COMP
           , lCurDelay.ARE_NB_DAYS_WAIT_MAX
           , lCurDelay.ARE_DATE_START_REP
           , lCurDelay.ARE_NB_DAYS
           , lCurDelay.ARE_DATE_END_REP
           , lCurDelay.ARE_NB_DAYS_CTRL
           , lCurDelay.ARE_DATE_END_CTRL
           , lCurDelay.ARE_NB_DAYS_EXP
           , lCurDelay.ARE_DATE_START_EXP
           , lCurDelay.ARE_NB_DAYS_SENDING
           , lCurDelay.ARE_DATE_END_SENDING
           , lCurDelay.ARE_REQ_DATE_C
           , lCurDelay.ARE_CONF_DATE_C
           , lCurDelay.ARE_UPD_DATE_C
           , lCurDelay.ARE_REQ_DATE_S
           , lCurDelay.ARE_CONF_DATE_S
           , lCurDelay.ARE_UPD_DATE_S
        from ASA_RECORD
       where ASA_RECORD_ID = iAsaRecordID;
    exception
      when no_data_found then
        lCurDelay  := null;
    end;

    return lCurDelay;
  end pLoadCurrentDelays;

  /**
  * procedure InitAsaRecordDelay
  * Description
  *   Initialisation et recalcul des délais du dossier SAV
  *    cette procédure gère également l'appel de la génération du mouvement de report
  */
  procedure InitAsaRecordDelay(iotAsaRecord in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lARE_NB_DAYS         ASA_RECORD.ARE_NB_DAYS%type;
    lARE_NB_DAYS_WAIT    ASA_RECORD.ARE_NB_DAYS_WAIT%type;
    lARE_NB_DAYS_CTRL    ASA_RECORD.ARE_NB_DAYS_CTRL%type;
    lARE_NB_DAYS_EXP     ASA_RECORD.ARE_NB_DAYS_EXP%type;
    lARE_NB_DAYS_SENDING ASA_RECORD.ARE_NB_DAYS_SENDING%type;
    lStatus              ASA_RECORD.C_ASA_REP_STATUS%type;
    lStatusModified      boolean;
    lDate                date;
  begin
    lStatus          := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'C_ASA_REP_STATUS');
    lStatusModified  := FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'C_ASA_REP_STATUS');

    if     (lStatusModified)
       and (ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_NB_DAYS') )
       and (not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ASA_REP_TYPE_ID') ) then
      -- Renvoi le nbr de jours des differents champs en utilisant la cmd sql
      -- définie comme ASA_RECORD/INIT_NB_DAYS/INIT_NB_DAYS
      GetRecordNbDays(iRepTypeID       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ASA_REP_TYPE_ID')
                    , iGoodRepairID    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'GCO_ASA_TO_REPAIR_ID')
                    , iCustomerID      => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'PAC_CUSTOM_PARTNER_ID')
                    , iAsaRecordID     => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ASA_RECORD_ID')
                    , oNbDays          => lARE_NB_DAYS
                    , oNbDaysWait      => lARE_NB_DAYS_WAIT
                    , oNbDaysCtrl      => lARE_NB_DAYS_CTRL
                    , oNbDaysExp       => lARE_NB_DAYS_EXP
                    , oNbDaysSending   => lARE_NB_DAYS_SENDING
                     );

      -- Réparation - ARE_NB_DAYS
      -- Attente (Réparation) - ARE_NB_DAYS_WAIT
      -- Contrôle - ARE_NB_DAYS_CTRL
      -- Préparation expédition - ARE_NB_DAYS_EXP
      -- Livraison - ARE_NB_DAYS_SENDING

      -- Réparation - ARE_NB_DAYS
      if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ARE_NB_DAYS'), 0) <> nvl(lARE_NB_DAYS, 0) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NB_DAYS', nvl(lARE_NB_DAYS, 0) );
      end if;

      -- Attente (Réparation) - ARE_NB_DAYS_WAIT
      if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ARE_NB_DAYS_WAIT'), 0) <> nvl(lARE_NB_DAYS_WAIT, 0) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NB_DAYS_WAIT', nvl(lARE_NB_DAYS_WAIT, 0) );
      end if;

      -- Contrôle - ARE_NB_DAYS_CTRL
      if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ARE_NB_DAYS_CTRL'), 0) <> nvl(lARE_NB_DAYS_CTRL, 0) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NB_DAYS_CTRL', nvl(lARE_NB_DAYS_CTRL, 0) );
      end if;

      -- Préparation expédition - ARE_NB_DAYS_EXP
      if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ARE_NB_DAYS_EXP'), 0) <> nvl(lARE_NB_DAYS_EXP, 0) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NB_DAYS_EXP', nvl(lARE_NB_DAYS_EXP, 0) );
      end if;

      -- Livraison - ARE_NB_DAYS_SENDING
      if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ARE_NB_DAYS_SENDING'), 0) <>
                                                                                            nvl(lARE_NB_DAYS_SENDING, 0) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NB_DAYS_SENDING', nvl(lARE_NB_DAYS_SENDING, 0) );
      end if;
    end if;

    -- Attente (composants) - ARE_NB_DAYS_WAIT_COMP
    if     (lStatusModified)
       and (   ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_REG_DATE')
            or (    ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_NB_DAYS')
                and not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ASA_REP_TYPE_ID')
               )
           ) then
      declare
        lWaitComp ASA_RECORD.ARE_NB_DAYS_WAIT_COMP%type;
      begin
        -- Attente (composants)
        ASA_FUNCTIONS.InitNbDaysWaitComp(aRecordID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                            , 'ASA_RECORD_ID'
                                                                                             )
                                       , vMaxDelay   => lWaitComp
                                        );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NB_DAYS_WAIT_COMP', nvl(lWaitComp, 0) );
      end;
    end if;

    -- Attente (maximum) - ARE_NB_DAYS_WAIT_MAX
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS_WAIT_MAX') then
      if    (FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS_WAIT_MAX') )
         or (    not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS_WAIT')
             and FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS_WAIT')
            )
         or (    not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS_WAIT_COMP')
             and FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS_WAIT_COMP')
            ) then
        FWK_I_MGT_ENTITY_DATA.SetColumn
                                      (iotAsaRecord
                                     , 'ARE_NB_DAYS_WAIT_MAX'
                                     , greatest(nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                        , 'ARE_NB_DAYS_WAIT'
                                                                                         )
                                                  , 0
                                                   )
                                              , nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                        , 'ARE_NB_DAYS_WAIT_COMP'
                                                                                         )
                                                  , 0
                                                   )
                                               )
                                      );
      end if;
    end if;

    -- Enregistrement - ARE_DATE_REG_REP
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_REG_REP') then
      if     (lStatusModified)
         and (ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_REG_DATE') ) then
        -- Enregistrement = Date du jour
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_REG_REP', trunc(sysdate) );
      end if;
    end if;

    -- Date de réception - ARE_DATE_START_REP
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_START_REP') then
      if     (lStatusModified)
         and (ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_START_REP') ) then
        -- Date de réception = Date du jour
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_START_REP', trunc(sysdate) );
      elsif        (    not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_DATE_REG_REP')
                    and not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS_WAIT_MAX')
                   )
               and FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_REG_REP')
            or FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS_WAIT_MAX') then
        -- Date de réception = Début réparation + Attente (maximum)
        lDate  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate
                                     (aDate       => FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotAsaRecord
                                                                                       , 'ARE_DATE_REG_REP'
                                                                                        )
                                    , aCalcDays   => nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                             , 'ARE_NB_DAYS_WAIT_MAX'
                                                                                              )
                                                       , 0
                                                        )
                                     );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_START_REP', lDate);
      end if;
    end if;

    -- Fin réparation - ARE_DATE_END_REP
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_END_REP') then
      if     (lStatusModified)
         and (ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_END_REP') ) then
        -- Fin réparation = Date du jour
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_END_REP', trunc(sysdate) );
      elsif     (    not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_DATE_START_REP')
                 and not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS')
                )
            and (   FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_START_REP')
                 or FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS')
                ) then
        -- Fin réparation = Début réparation + Réparation
        lDate  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate
                                              (aDate       => FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotAsaRecord
                                                                                                , 'ARE_DATE_START_REP'
                                                                                                 )
                                             , aCalcDays   => nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                                      , 'ARE_NB_DAYS'
                                                                                                       )
                                                                , 0
                                                                 )
                                              );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_END_REP', lDate);
      end if;
    end if;

    -- Fin du contrôle - ARE_DATE_END_CTRL
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_END_CTRL') then
      if     (lStatusModified)
         and (ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_END_CTRL') ) then
        -- Fin du contrôle = Date du jour
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_END_CTRL', trunc(sysdate) );
      elsif     (    not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_DATE_END_REP')
                 and not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS_CTRL')
                )
            and (   FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_END_REP')
                 or FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS_CTRL')
                ) then
        -- Fin du contrôle = Fin réparation + Contrôle
        lDate  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate
                                         (aDate       => FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotAsaRecord
                                                                                           , 'ARE_DATE_END_REP'
                                                                                            )
                                        , aCalcDays   => nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                                 , 'ARE_NB_DAYS_CTRL'
                                                                                                  )
                                                           , 0
                                                            )
                                         );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_END_CTRL', lDate);
      end if;
    end if;

    -- Expédition - ARE_DATE_START_EXP
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_START_EXP') then
      if     (lStatusModified)
         and (ASA_LIB_RECORD.isStatusInConfig(lStatus, 'ASA_REP_STATUS_INIT_START_EXP') ) then
        -- Expédition = Date du jour
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_START_EXP', trunc(sysdate) );
      elsif     (    not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_DATE_END_CTRL')
                 and not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS_EXP')
                )
            and (   FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_END_CTRL')
                 or FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS_EXP')
                ) then
        -- Expédition = Fin du contrôle + Préparation expédition
        lDate  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate
                                          (aDate       => FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotAsaRecord
                                                                                            , 'ARE_DATE_END_CTRL'
                                                                                             )
                                         , aCalcDays   => nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                                  , 'ARE_NB_DAYS_EXP'
                                                                                                   )
                                                            , 0
                                                             )
                                          );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_START_EXP', lDate);
      end if;
    end if;

    -- Délai prévu - ARE_DATE_END_SENDING
    -- Ne pas toucher si flag modifié = oui
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_END_SENDING') then
      if     (    not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_DATE_START_EXP')
              and not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_NB_DAYS_SENDING')
             )
         and (   FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_START_EXP')
              or FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_NB_DAYS_SENDING')
             ) then
        -- Expédition = Fin du contrôle + Préparation expédition
        lDate  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate
                                      (aDate       => FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotAsaRecord
                                                                                        , 'ARE_DATE_START_EXP'
                                                                                         )
                                     , aCalcDays   => nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord
                                                                                              , 'ARE_NB_DAYS_SENDING'
                                                                                               )
                                                        , 0
                                                         )
                                      );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_DATE_END_SENDING', lDate);
      end if;
    end if;

    -- Délai confirmé - ARE_CONF_DATE_C
    -- Ne pas toucher si flag modifié = oui
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_CONF_DATE_C') then
      if     FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_CONF_DATE_C')
         and FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_END_SENDING') then
        -- Délai confirmé = Délai prévu
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord
                                      , 'ARE_CONF_DATE_C'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotAsaRecord, 'ARE_DATE_END_SENDING')
                                       );
      end if;
    end if;

    -- Délai modifié - ARE_UPD_DATE_C
    -- Ne pas toucher si flag modifié = oui
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_UPD_DATE_C') then
      if FWK_I_MGT_ENTITY_DATA.IsModified(iotAsaRecord, 'ARE_DATE_END_SENDING') then
        -- Délai modifié = Délai prévu
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord
                                      , 'ARE_UPD_DATE_C'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotAsaRecord, 'ARE_DATE_END_SENDING')
                                       );
      end if;
    end if;
  end InitAsaRecordDelay;

  /**
  * function GetRecordNbDays
  * Description
  *   Renvoi le nbr de jours des differents champs en utilisant la commande sql
  *     définie comme ASA_RECORD/INIT_NB_DAYS/INIT_NB_DAYS
  */
  procedure GetRecordNbDays(
    iRepTypeID     in     ASA_RECORD.ASA_REP_TYPE_ID%type
  , iGoodRepairID  in     ASA_RECORD.GCO_ASA_TO_REPAIR_ID%type
  , iCustomerID    in     ASA_RECORD.PAC_CUSTOM_PARTNER_ID%type
  , iAsaRecordID   in     ASA_RECORD.ASA_RECORD_ID%type
  , oNbDays        out    ASA_RECORD.ARE_NB_DAYS%type
  , oNbDaysWait    out    ASA_RECORD.ARE_NB_DAYS_WAIT%type
  , oNbDaysCtrl    out    ASA_RECORD.ARE_NB_DAYS_CTRL%type
  , oNbDaysExp     out    ASA_RECORD.ARE_NB_DAYS_EXP%type
  , oNbDaysSending out    ASA_RECORD.ARE_NB_DAYS_SENDING%type
  )
  is
    type TNbDays is ref cursor;

    crNbDays TNbDays;
    lvSql    varchar2(32000);
  begin
    lvSql  :=
      'select RTG_NB_DAYS, RTG_NB_DAYS_WAIT, RTG_NB_DAYS_CTRL, RTG_NB_DAYS_EXP, RTG_NB_DAYS_SENDING from (' ||
      upper(PCS.PC_FUNCTIONS.GetSql('ASA_RECORD', 'INIT_NB_DAYS', 'INIT_NB_DAYS')) ||
      ')';

    -- Remplacement du param ASA_REP_TYPE_ID par sa valeur
    if iRepTypeID is not null then
      lvSql  := replace(lvSql, ':ASA_REP_TYPE_ID', to_char(iRepTypeID) );
    else
      lvSql  := replace(lvSql, ':ASA_REP_TYPE_ID', 'NULL');
    end if;

    -- Remplacement du param GCO_GOOD_TO_REPAIR_ID par sa valeur
    if iGoodRepairID is not null then
      lvSql  := replace(lvSql, ':GCO_GOOD_TO_REPAIR_ID', to_char(iGoodRepairID) );
    else
      lvSql  := replace(lvSql, ':GCO_GOOD_TO_REPAIR_ID', 'NULL');
    end if;

    -- Remplacement du param PAC_CUSTOM_PARTNER_ID par sa valeur
    if iCustomerID is not null then
      lvSql  := replace(lvSql, ':PAC_CUSTOM_PARTNER_ID', to_char(iCustomerID) );
    else
      lvSql  := replace(lvSql, ':PAC_CUSTOM_PARTNER_ID', 'NULL');
    end if;

    -- Remplacement du param ASA_RECORD_ID par sa valeur
    if iAsaRecordID is not null then
      lvSql  := replace(lvSql, ':ASA_RECORD_ID', to_char(iAsaRecordID) );
    else
      lvSql  := replace(lvSql, ':ASA_RECORD_ID', 'NULL');
    end if;

    -- Remplacement du company owner
    lvSql  := replace(lvSql, '[' || 'CO].', '');
    -- Remplacement du company owner
    lvSql  := replace(lvSql, '[' || 'COMPANY_OWNER].', '');

    open crNbDays for lvSql;

    fetch crNbDays
     into oNbDays
        , oNbDaysWait
        , oNbDaysCtrl
        , oNbDaysExp
        , oNbDaysSending;

    close crNbDays;
  exception
    when others then
      null;
  end GetRecordNbDays;

  /**
  * procedure IsRecordModifiedDelay
  * Description
  *   Indique s'il y a un délai different sur le dossier SAV par rapport à la
  *     dernière ligne dans l'historique des délais
  */
  function IsRecordModifiedDelay(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lOldDelay     ASA_DELAY_HISTORY%rowtype;
    lCurDelay     ASA_DELAY_HISTORY%rowtype;
    lDelayUpdated boolean;
  begin
    -- Rechercher la dernière ligne d'historique pour le dossier SAV
    lOldDelay      := pLoadLastDelays(iAsaRecordID);
    -- Rechercher les délais actuels du dossier SAV
    lCurDelay      := pLoadCurrentDelays(iAsaRecordID);
    -- Màj des flags des champs modifiés
    lDelayUpdated  := pSetFlagsUpdatedFields(lOldDelay, lCurDelay);
    return lDelayUpdated;
  end IsRecordModifiedDelay;

  /**
  * procedure InitDelayHistory
  * Description
  *   Init du tuple d'historique des délais pour un dossier SAV en fonction
  *     des délais définis sur le dossier et de la dernière ligne d'historique
  */
  procedure InitDelayHistory(iotDelayHistory in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lOldDelay     ASA_DELAY_HISTORY%rowtype;
    lCurDelay     ASA_DELAY_HISTORY%rowtype;
    lDelayUpdated boolean;
    lRecordID     ASA_RECORD.ASA_RECORD_ID%type;
  begin
    -- Récuperer l'ID du dossier SAV
    lRecordID      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotDelayHistory, 'ASA_RECORD_ID');
    -- Rechercher la dernière ligne d'historique pour le dossier SAV
    lOldDelay      := pLoadLastDelays(lRecordID);
    -- Rechercher les délais actuels du dossier SAV
    lCurDelay      := pLoadCurrentDelays(lRecordID);
    -- Màj des flags des champs modifiés
    lDelayUpdated  := pSetFlagsUpdatedFields(lOldDelay, lCurDelay);
    -- N° de séquence de la dernière ligne d'historique + 1
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_SEQ', nvl(lOldDelay.ADH_SEQ, 0) + 1);
    -- Récuperer tous les champs du rowtype
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_DELAY_UPDATE_TEXT', lCurDelay.ADH_DELAY_UPDATE_TEXT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'DIC_DELAY_UPDATE_TYPE_ID', lCurDelay.DIC_DELAY_UPDATE_TYPE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_DATE_REG_REP', lCurDelay.ARE_DATE_REG_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_DATE_REG_REP', lCurDelay.ADH_DATE_REG_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_NB_DAYS_WAIT', lCurDelay.ARE_NB_DAYS_WAIT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_NB_DAYS_WAIT', lCurDelay.ADH_NB_DAYS_WAIT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_NB_DAYS_WAIT_COMP', lCurDelay.ARE_NB_DAYS_WAIT_COMP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_NB_DAYS_WAIT_COMP', lCurDelay.ADH_NB_DAYS_WAIT_COMP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_NB_DAYS_WAIT_MAX', lCurDelay.ARE_NB_DAYS_WAIT_MAX);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_NB_DAYS_WAIT_MAX', lCurDelay.ADH_NB_DAYS_WAIT_MAX);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_DATE_START_REP', lCurDelay.ARE_DATE_START_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_DATE_START_REP', lCurDelay.ADH_DATE_START_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_NB_DAYS', lCurDelay.ARE_NB_DAYS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_NB_DAYS', lCurDelay.ADH_NB_DAYS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_DATE_END_REP', lCurDelay.ARE_DATE_END_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_DATE_END_REP', lCurDelay.ADH_DATE_END_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_NB_DAYS_CTRL', lCurDelay.ARE_NB_DAYS_CTRL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_NB_DAYS_CTRL', lCurDelay.ADH_NB_DAYS_CTRL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_DATE_END_CTRL', lCurDelay.ARE_DATE_END_CTRL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_DATE_END_CTRL', lCurDelay.ADH_DATE_END_CTRL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_NB_DAYS_EXP', lCurDelay.ARE_NB_DAYS_EXP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_NB_DAYS_EXP', lCurDelay.ADH_NB_DAYS_EXP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_DATE_START_EXP', lCurDelay.ARE_DATE_START_EXP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_DATE_START_EXP', lCurDelay.ADH_DATE_START_EXP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_NB_DAYS_SENDING', lCurDelay.ARE_NB_DAYS_SENDING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_NB_DAYS_SENDING', lCurDelay.ADH_NB_DAYS_SENDING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_DATE_END_SENDING', lCurDelay.ARE_DATE_END_SENDING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_DATE_END_SENDING', lCurDelay.ADH_DATE_END_SENDING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_REQ_DATE_C', lCurDelay.ARE_REQ_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_REQ_DATE_C', lCurDelay.ADH_REQ_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_CONF_DATE_C', lCurDelay.ARE_CONF_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_CONF_DATE_C', lCurDelay.ADH_CONF_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_UPD_DATE_C', lCurDelay.ARE_UPD_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_UPD_DATE_C', lCurDelay.ADH_UPD_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_REQ_DATE_S', lCurDelay.ARE_REQ_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_REQ_DATE_S', lCurDelay.ADH_REQ_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_CONF_DATE_S', lCurDelay.ARE_CONF_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_CONF_DATE_S', lCurDelay.ADH_CONF_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ARE_UPD_DATE_S', lCurDelay.ARE_UPD_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'ADH_UPD_DATE_S', lCurDelay.ADH_UPD_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotDelayHistory, 'C_ASA_REP_STATUS', lCurDelay.C_ASA_REP_STATUS);
  end InitDelayHistory;

  /**
  * procedure CreateDelayHistory
  * Description
  *   Création ou pas d'un historique des délais du dossier SAV
  *     s'il y a eu des modifications de ceux-ci
  */
  procedure CreateDelayHistory(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
  is
    ltDelayHistory FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Vérifier si les valeurs des délais/durées ont été modifiées
    if ASA_PRC_RECORD_DELAY.IsRecordModifiedDelay(iAsaRecordID) then
      FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaDelayHistory, ltDelayHistory, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDelayHistory, 'ASA_RECORD_ID', iAsaRecordID);
      FWK_I_MGT_ENTITY.InsertEntity(ltDelayHistory);
      FWK_I_MGT_ENTITY.Release(ltDelayHistory);
    end if;
  end CreateDelayHistory;
end ASA_PRC_RECORD_DELAY;
