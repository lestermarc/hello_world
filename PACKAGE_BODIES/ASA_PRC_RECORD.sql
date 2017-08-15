--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD" 
is
  /**
   * procedure ExecExternProc
   * Description
   *   Execution de procédures externes utilisateur (pour les procédures définies dans le gabarit)
   * @created AGA 09.2011
   * @lastUpdate
   * @public
   * @param iotASA_RECORD enregistrement ASA_RECORD actif
   * @param  iTransMode : type de procédure externe :
   *     'BeforeValidate'  , 'AfterValidate'
   *     'BeforeEdit'      , 'AfterEdit'
   *     'BeforeDelete'    , 'AfterDelete'
   */
  procedure ExecExternProc(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def, iTransMode varchar2)
  is
    lProcText   varchar2(100);
    lStoredProc DOC_GAUGE_STRUCTURED.GAS_STORED_PROC_VALIDATE%type;
    lGaugeName  PCS.PC_CBASE.CBACVALUE%type;
    lGaugeField varchar2(50);
    vSql        varchar2(200);
    lErrorText  varchar2(2000);
    lnError     integer;
    lcError     varchar2(2000);
  begin
    if     (iTransMode <> 'BeforeValidate')
       and (iTransMode <> 'AfterValidate')
       and (iTransMode <> 'BeforeEdit')
       and (iTransMode <> 'AfterEdit')
       and (iTransMode <> 'BeforeDelete')
       and (iTransMode <> 'AfterDelete') then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  :=
        'Transaction (iTransMode) mode must be one of these codes : ''BeforeValidate'', ''AfterValidate'', ''BeforeEdit'', ''AfterEdit'', ''BeforeDelete'', ''AfterDelete''';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => ' ExecExternProc'
                                         );
    end if;

    if iTransMode = 'BeforeValidate' then
      lGaugeField  := 'GAS_STORED_PROC_VALIDATE';
      lProcText    := 'External procedure - Before validation';
    elsif iTransMode = 'BeforeEdit' then
      lGaugeField  := 'GAS_STORED_PROC_EDIT';
      lProcText    := 'External procedure - Before edition';
    elsif iTransMode = 'BeforeDelete' then
      lGaugeField  := 'GAS_STORED_PROC_DELETE';
      lProcText    := 'External procedure - Before deletion';
    elsif iTransMode = 'AfterValidate' then
      lGaugeField  := 'GAS_STORED_PROC_AFTER_VALIDATE';
      lProcText    := 'External procedure - After validation';
    elsif iTransMode = 'AfterEdit' then
      lGaugeField  := 'GAS_STORED_PROC_AFTER_EDIT';
      lProcText    := 'External procedure - After edition';
    elsif iTransMode = 'AfterDelete' then
      lGaugeField  := 'GAS_STORED_PROC_AFTER_DELETE';
      lProcText    := 'External procedure - After deletion';
    end if;

    --Gabarit correspondant au statut du dossier SAV
    lGaugeName  := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_GAUGE_NAME') || '_' || FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'C_ASA_REP_STATUS');
    vSql        :=
      'SELECT  GAS.' ||
      lGaugeField ||
      ' FROM DOC_GAUGE GAU, DOC_GAUGE_STRUCTURED GAS WHERE GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID  AND GAU.GAU_DESCRIBE =  ''' ||
      lGaugeName ||
      '''';

    begin
      execute immediate vSql
                   into lStoredProc;
    exception
      when no_data_found then
        lErrorText  := '[ABORT] - Data does not exists in DOC_GAUGE_STRUCTURED : DOC_GAUGE.GAU_DESCRIBE = ' || lGaugeName;
    end;

    if lStoredProc is not null then
      DOC_FUNCTIONS.ExecuteExternProc(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID'), lStoredProc, lErrorText);
    end if;

    if     lErrorText is not null
       and instr(upper(lErrorText), '[ABORT]') > 0 then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lProcText || ' -> ' || lErrorText
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'ExecExternProc'
                                         );
    end if;
  end ExecExternProc;

/**
  * procedure CheckRecordBeforeUpdate
  * Description
  *    Contrôle avant édition d'un dossier SAV au autre maj lié à un dossier SAV
  *    déclenche les procédure externes BeforeEdit, AfterEdit
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotASA_RECORD : Dossier SAV
  */
  procedure CheckRecordBeforeUpdate(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    ASA_I_PRC_RECORD.ExecExternProc(iotASA_RECORD, 'BeforeEdit');

    if ASA_I_LIB_RECORD.IsRecordProtected(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID') ) then
      RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Ce dossier est protégé !'), aErrNo => -20900);
    end if;

    ASA_I_PRC_RECORD.ExecExternProc(iotASA_RECORD, 'AfterEdit');
  end CheckRecordBeforeUpdate;

  /**
  * procedure FinalizeRecord
  * Description
  *   Finalisation du dossier SAV
  *    déclenche les procédure externes BeforeValidate, AfterValidate
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param iAsaRecordID : ID du dossier SAV
  */
  procedure FinalizeRecord(iAsaRecordId in ASA_RECORD.ASA_RECORD_ID%type)
  is
    ltRecord FWK_I_TYP_DEFINITION.t_crud_def;

    -- Initialisation des données à la validation d'un dossier de réparation TASA_RECORD.BeforePost
    procedure CheckData
    is
    begin
      -- S'il s'agit d'un échange standard, ou autre produit (pas de réparation)
      if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltRecord, 'C_ASA_REP_TYPE_KIND') <> '3' then
        -- Réactualisation du code de gestion des composants
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltRecord
                                      , 'ARE_USE_COMP'
                                      , ASA_I_LIB_RECORD_COMP.ComponentExists(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRecord, 'ASA_RECORD_ID') )
                                       );
        -- Réactualisation du code de gestion des opérations
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltRecord
                                      , 'ARE_USE_TASK'
                                      , ASA_I_LIB_RECORD_TASK.TaskExists(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRecord, 'ASA_RECORD_ID') )
                                       );

        --  Si échange, article a échanger = article a réparer
        if    (    FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltRecord, 'C_ASA_REP_TYPE_KIND') = '1'
               and not FWK_I_MGT_ENTITY_DATA.IsNull(ltRecord, 'GCO_ASA_TO_REPAIR_ID')
              )
           or (    FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltRecord, 'C_ASA_REP_TYPE_KIND') = '2'
               and not FWK_I_MGT_ENTITY_DATA.IsNull(ltRecord, 'GCO_ASA_TO_REPAIR_ID')
               and FWK_I_MGT_ENTITY_DATA.IsNull(ltRecord, 'GCO_ASA_EXCHANGE_ID')
              ) then
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltRecord, 'GCO_ASA_EXCHANGE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRecord, 'GCO_ASA_TO_REPAIR_ID') );
        end if;
      end if;
    end CheckData;
  begin
    -- Création de l'entité ASA_RECORD
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecord, ltRecord);
    FWK_I_MGT_ENTITY.load(ltRecord, iAsaRecordId);
    ExecExternProc(ltRecord, 'BeforeValidate');
    -- procedure FinalizeRecord
    -- réinitialisation des données liées tâches ,composants, données article à échanger
    CheckData;
    -- Initialisation des données relative au bien a échanger  (si modifié)
    InitExchangeGoodData(ltRecord);
    -- Recalcul des montants
    CalcRecordPrices(ltRecord);
    -- Recalcul des montants en monnaie étrangère
    ASA_I_PRC_RECORD.ConvertRecordPrices(ltRecord);
    -- mise à jour des données du dossier SAV
    FWK_I_MGT_ENTITY.UpdateEntity(ltRecord);
    -- Mise à jour des documents d'attribution associés au dossier SAV
    ASA_RECORD_GENERATE_DOC.UpdateAttrib(aRecordID => iAsaRecordId);
    ExecExternProc(ltRecord, 'AfterValidate');
    FWK_I_MGT_ENTITY.Release(ltRecord);
  end FinalizeRecord;

  /**
  * procedure CheckRecordBeforeDelete
  * Description
  *   Contrôle avant effacement d'un dossier de réparation
  *    déclenche les procédure externes BeforeDelete, AfterDelete
  * @created AGA 09.2011
  * @lastUpdate
  * @public
  * @param iotASA_RECORD enregistrement ASA_RECORD actif
  */
  procedure CheckRecordBeforeDelete(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplRecord FWK_TYP_ASA_ENTITY.tRecord := FWK_TYP_ASA_ENTITY.gttRecord(iotASA_RECORD.entity_id);

    procedure CheckData
    is
      lnId     number;
      lResult  boolean;
      lMessage varchar2(200);
    begin
      select count(*)
        into lnId
        from ASA_RECORD_COMP
       where (STM_COMP_STOCK_MVT_ID > 0)
         and (   ASA_RECORD_EVENTS_ID = ltplRecord.ASA_RECORD_EVENTS_ID
              or ASA_RECORD_EVENTS_ID is null)
         and ASA_RECORD_ID = ltplRecord.ASA_RECORD_ID;

      if lnId > 0 then
        lMessage  := PCS.PC_FUNCTIONS.TranslateWord('Des mouvements de stock ont été effectués sur les composants !');
      else
        select count(*)
          into lnId
          from ASA_RECORD_TASK
         where (RET_FINISHED = 1)
           and (   ASA_RECORD_EVENTS_ID = ltplRecord.ASA_RECORD_EVENTS_ID
                or ASA_RECORD_EVENTS_ID is null)
           and ASA_RECORD_ID = ltplRecord.ASA_RECORD_ID;

        if lnId > 0 then
          lMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce dossier contient des opérations effectuées !');
        else
          select count(*)
            into lnId
            from ASA_RECORD_EVENTS
           where DOC_POSITION_ID > 0
             and ASA_RECORD_ID = ltplRecord.ASA_RECORD_ID;

          if lnId > 0 then
            lMessage  := PCS.PC_FUNCTIONS.TranslateWord('Des documents ont été générés pour ce dossier !');
          end if;
        end if;
      end if;

      if lMessage is not null then
        fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                          , iv_message       => lMessage
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'CheckRecordBeforeDelete'
                                           );
      end if;
    end CheckData;

    procedure SetFkToNull
    is
      ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      for tplLinkedDocPosition in (select DOC_POSITION_ID
                                     from DOC_POSITION
                                    where ASA_RECORD_ID = ltplRecord.ASA_RECORD_ID) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcdocposition, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_POSITION_ID', tplLinkedDocPosition.DOC_POSITION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_ID', cast(null as number) );
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;

      FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_ID', ltplRecord.ASA_RECORD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_EVENTS_ID', cast(null as number) );
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end SetFkToNull;

    procedure DeleteChildren
    is
      ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      for tplDescr in (select rowid
                         from ASA_RECORD_DESCR
                        where ASA_RECORD_ID = ltplRecord.ASA_RECORD_ID) loop
        FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_ASA_ENTITY.gcAsaRecordDescr
                           , iot_crud_definition   => ltCRUD_DEF
                           , iv_row_id             => tplDescr.rowid
                           , iv_primary_col        => 'ASA_RECORD_ID'
                            );
        FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;

      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'ASA_BINDED_DOCUMENTS'
                                    , iv_parent_key_name    => 'ASA_RECORD_ID'
                                    , iv_parent_key_value   => ltplRecord.ASA_RECORD_ID
                                     );
      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'ASA_DELAY_HISTORY'
                                    , iv_parent_key_name    => 'ASA_RECORD_ID'
                                    , iv_parent_key_value   => ltplRecord.ASA_RECORD_ID
                                     );
      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name => 'ASA_FREE_CODE', iv_parent_key_name => 'ASA_RECORD_ID', iv_parent_key_value => ltplRecord.ASA_RECORD_ID);
      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name => 'ASA_FREE_DATA', iv_parent_key_name => 'ASA_RECORD_ID', iv_parent_key_value => ltplRecord.ASA_RECORD_ID);
      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'ASA_RECORD_DETAIL'
                                    , iv_parent_key_name    => 'ASA_RECORD_ID'
                                    , iv_parent_key_value   => ltplRecord.ASA_RECORD_ID
                                     );
      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'ASA_RECORD_COMP', iv_parent_key_name => 'ASA_RECORD_ID'
                                    , iv_parent_key_value   => ltplRecord.ASA_RECORD_ID);
      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'ASA_RECORD_TASK', iv_parent_key_name => 'ASA_RECORD_ID'
                                    , iv_parent_key_value   => ltplRecord.ASA_RECORD_ID);
      FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'ASA_RECORD_EVENTS'
                                    , iv_parent_key_name    => 'ASA_RECORD_ID'
                                    , iv_parent_key_value   => ltplRecord.ASA_RECORD_ID
                                     );
    end DeleteChildren;
  begin
    -- procedure CheckBeforeDeleteRecord
    if ASA_I_LIB_RECORD.IsRecordProtected(ltplRecord.ASA_RECORD_ID) then
      RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Ce dossier est protégé !'), aErrNo => -20900);
    end if;

    if    (    ASA_I_LIB_RECORD.GetQtyMgm(ltplRecord.ASA_REP_TYPE_ID)
           and (   ASA_I_LIB_RECORD.IsDetMvtGen(ltplRecord.ASA_RECORD_ID)
                or ASA_I_LIB_RECORD.IsDetExchMvtGen(ltplRecord.ASA_RECORD_ID) )
          )
       or (ltplRecord.STM_ASA_DEFECT_MVT_ID is not null)
       or (ltplRecord.STM_ASA_EXCH_MVT_ID is not null) then
      RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Le mouvement d''extourne a été effectué !'), aErrNo => -20900);
    end if;

    CheckData;
    SetFkToNull;
    DeleteDocumentAttrib(iotASA_RECORD);
    DeleteChildren;
  end CheckRecordBeforeDelete;

  /**
  * procedure DeleteDocumentAttrib
  * Description
  *   Effacement des données ainsi que du document logistique lié aux attribs
  */
  procedure DeleteDocumentAttrib(iotAsaRecord in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- Effacer le lien de la position d'attrib de tous les composants du dossier SAV
    ASA_I_PRC_RECORD_COMP.ClearAttribLink(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ASA_RECORD_ID') );

    -- Effacement du document logistique
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'DOC_ATTRIB_DOCUMENT_ID') then
      DOC_DELETE.deleteDocument(aDocumentId => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'DOC_ATTRIB_DOCUMENT_ID'), aCreditLimit => 0);
    end if;

    -- Effacer le lien sur le document d'attrib
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotAsaRecord, 'DOC_ATTRIB_DOCUMENT_ID');
  end DeleteDocumentAttrib;

  /**
  * procedure InitRepairedGoodData
  * Description
  *   Init des données liées au produit réparé
  */
  procedure InitRepairedGoodData(iotAsaRecord in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lQtyMgt boolean := true;
  begin
    -- Init des données du produit réparé
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'GCO_NEW_GOOD_ID') then
      -- Rechercher  "Gestion quantité en réparation" sur le type de réparation
      lQtyMgt  := ASA_I_LIB_RECORD.GetQtyMgm(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ASA_REP_TYPE_ID') );

      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'GCO_ASA_TO_REPAIR_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'GCO_NEW_GOOD_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'GCO_ASA_TO_REPAIR_ID') );
      end if;

      if not lQtyMgt then
        -- Gestion quantité en réparation = NON
        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'GCO_CHAR1_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'GCO_NEW_CHAR1_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'GCO_CHAR1_ID') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'GCO_CHAR2_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'GCO_NEW_CHAR2_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'GCO_CHAR2_ID') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'GCO_CHAR3_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'GCO_NEW_CHAR3_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'GCO_CHAR3_ID') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'GCO_CHAR4_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'GCO_NEW_CHAR4_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'GCO_CHAR4_ID') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'GCO_CHAR5_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'GCO_NEW_CHAR5_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'GCO_CHAR5_ID') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_CHAR1_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NEW_CHAR1_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'ARE_CHAR1_VALUE') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_CHAR2_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NEW_CHAR2_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'ARE_CHAR2_VALUE') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_CHAR3_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NEW_CHAR3_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'ARE_CHAR3_VALUE') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_CHAR4_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NEW_CHAR4_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'ARE_CHAR4_VALUE') );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_CHAR5_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_NEW_CHAR5_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'ARE_CHAR5_VALUE') );
        end if;
      else
        -- Gestion quantité en réparation = OUI
        -- Mise à jour du détail du produit réparé avec le détail du produit à réparer
        ASA_FUNCTIONS.AutoInsertRepDetail(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ASA_RECORD_ID') );
      end if;
    end if;
  end InitRepairedGoodData;

      /**
  * procedure InitExchangeGoodData
  * Description
  *   Initialisation des éléments liés au produit à échanger
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @private
  * @param iotASA_RECORD enregistrement ASA_RECORD actif
  * @param   iForceUpdade : Forcer la mise à jour des descriptions de produit
  */
  procedure InitExchangeGoodData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lbQtyManagement       boolean;
    lvShortDescription    GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    lvLongDescription     GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    lvFreeDescription     GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    lnSalesPrice          number;
    lnCostPrice           number;
    lnTempAmountB         number;
    lnTempAmountEuro      number;
    lnSTM_ASA_EXCH_STK_ID number;
    lnSTM_ASA_EXCH_LOC_ID number;
    lnASA_RECORD_ID       number;
    lnGCO_ASA_EXCHANGE_ID number;
    ltCRUD_DEF            FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then
      -- Recherche flag, gestion de la quantité, du type de réparation
      lbQtyManagement        := ASA_I_LIB_RECORD.GetQtyMgm(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_ID') );

      if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID')
         and FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_EXCH_QTY') > 1
         and GCO_LIB_CHARACTERIZATION.IsPieceChar(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') ) = 1
         and not lbQtyManagement then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_EXCH_QTY', 1);
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'GCO_EXCH_CHAR1_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'GCO_EXCH_CHAR2_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'GCO_EXCH_CHAR3_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'GCO_EXCH_CHAR4_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'GCO_EXCH_CHAR5_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'ARE_EXCH_CHAR1_VALUE');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'ARE_EXCH_CHAR2_VALUE');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'ARE_EXCH_CHAR3_VALUE');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'ARE_EXCH_CHAR4_VALUE');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotASA_RECORD, 'ARE_EXCH_CHAR5_VALUE');

      if lbQtyManagement then
        lnASA_RECORD_ID  := FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID');

        for TplAsaRecordDetail in (select ASA_RECORD_EXCH_DETAIL_ID
                                     from ASA_RECORD_DETAIL ARD
                                        , ASA_RECORD_EXCH_DETAIL AED
                                    where ARD.ASA_RECORD_ID = lnASA_RECORD_ID
                                      and ARD.ASA_RECORD_DETAIL_ID = AED.ASA_RECORD_DETAIL_ID) loop
          begin
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecordExchDetail, ltCRUD_DEF);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_EXCH_DETAIL_ID', TplAsaRecordDetail.ASA_RECORD_EXCH_DETAIL_ID);
            FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
            FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
          end;
        end loop;
      end if;

      -- Initialisation des stocks et emplacements du produit à échanger
      lnGCO_ASA_EXCHANGE_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID');

      select STM_STOCK_ID
           , STM_LOCATION_ID
        into lnSTM_ASA_EXCH_STK_ID
           , lnSTM_ASA_EXCH_LOC_ID
        from GCO_PRODUCT
       where GCO_GOOD_ID = lnGCO_ASA_EXCHANGE_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', lnSTM_ASA_EXCH_STK_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', lnSTM_ASA_EXCH_LOC_ID);

      -- Initialisation des descriptions du produit à échanger
      if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID')
         and not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID')
         and ( (    FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_GCO_SHORT_DESCR_EX')
                and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_GCO_LONG_DESCR_EX')
                and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_GCO_FREE_DESCR_EX')
               )
             ) then
        ASA_LIB_RECORD.GetGoodDescr(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID')
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID')
                                  , lvShortDescription
                                  , lvLongDescription
                                  , lvFreeDescription
                                   );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_GCO_SHORT_DESCR_EX', lvShortDescription);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_GCO_LONG_DESCR_EX', lvLongDescription);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_GCO_FREE_DESCR_EX', lvFreeDescription);
      end if;

      -- Recalcul tarif de vente produit à échanger
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then
        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF_ID') then
          lnSalesPrice  :=
            ASA_I_LIB_RECORD.GetGoodSalePrice(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID')
                                            , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID')
                                            , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'DOC_RECORD_ID')
                                            , FWK_I_MGT_ENTITY_DATA.getcolumnvarchar2(iotASA_RECORD, 'DIC_TARIFF_ID')
                                            , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                                            , ASA_LIB_RECORD.GetTariffDateRef(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_DATECRE') )
                                             );

          if lnSalesPrice <> 0 then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME', lnSalesPrice);
            -- Convertion en Monnaie de base ainsi qu'en euro
            ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME')
                                     , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                                     , ACS_FUNCTION.GetLocalCurrencyId
                                     , FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_DATECRE')   -- Date pas prise en compte (car on passe le cours)
                                     , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                                     , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                                     , 0
                                     , lnTempAmountEuro
                                     , lnTempAmountB
                                      );
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', lnTempAmountB);
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_EURO', lnTempAmountEuro);
          end if;
        end if;

        -- Recalcul prix de revient produit à échanger
        lnCostPrice  :=
          ASA_I_LIB_RECORD.GetGoodCostPrice(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID')
                                          , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID')
                                          , sysdate
                                           );

        if lnCostPrice <> 0 then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_COST_PRICE_T', lnCostPrice);
        end if;
      end if;
    end if;
  end InitExchangeGoodData;

  /**
  * procedure BalanceOrderDocument
  * Description
  *   Solder les documents Commandes clients liés au flux défini dans la cfg ASA_DEFAULT_CMDC_GAUGE_NAME
  */
  procedure BalanceOrderDocument(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
  is
    lRepStatus varchar2(10);
  begin
    -- Rechercher le 1er statut défini dans la config ASA_DEFAULT_CMDC_GAUGE_NAME
    -- si vide utiliser le statut 05'
    select nvl(max(REP_STATUS), '05')
      into lRepStatus
      from (select case
                     when SEP = 0 then column_value
                     else substr(column_value, 1, SEP - 1)
                   end as GAUGE_NAME
                 , case
                     when SEP = 0 then null
                     else substr(column_value, SEP + 1, 2)
                   end as REP_STATUS
                 , rownum rownumber
              from (select column_value
                         , instr(column_value, ';') SEP
                      from table(PCS.charListToTable(PCS.PC_CONFIG.GetConfig('ASA_GEN_STK_MVT_ON_REPAIR'), ',') ) ) )
     where ROWNUMBER = 1;

    -- Solder les documents
    for tplDoc in (select   POS.DOC_DOCUMENT_ID
                       from ASA_RECORD_EVENTS EVE
                          , DOC_POSITION POS
                      where EVE.ASA_RECORD_ID = iAsaRecordID
                        and EVE.C_ASA_REP_STATUS = lRepStatus
                        and EVE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                   group by POS.DOC_DOCUMENT_ID) loop
      DOC_DOCUMENT_FUNCTIONS.balanceDocument(aDocumentId => tplDoc.DOC_DOCUMENT_ID, aBalanceMvt => 0);
    end loop;
  end BalanceOrderDocument;

  /**
  * procedure ManageStatus
  * Description
  *   Changement du statut du dossier SAV suite à l'ajout d'une étape dans le flux
  */
  procedure ManageStatus(iotAsaRecord in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lAsaRecordID   ASA_RECORD.ASA_RECORD_ID%type          := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ASA_RECORD_ID');
    lRecordEventID ASA_RECORD.ASA_RECORD_EVENTS_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotAsaRecord, 'ASA_RECORD_EVENTS_ID');
    lNewStatus     ASA_RECORD.C_ASA_REP_STATUS%type       := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'C_ASA_REP_STATUS');
    lMvtErrMess    varchar2(32767);

    -- consomation des composants
    procedure pCompCreateStkMvts(iRecordId in ASA_RECORD.ASA_RECORD_ID%type, iRecordEventId in ASA_RECORD.ASA_RECORD_EVENTS_ID%type)
    is
      lMvtErrMess varchar2(32767);
    begin
      for ltplComp in (select   *
                           from ASA_RECORD_COMP
                          where ASA_RECORD_ID = iRecordId
                            and ASA_RECORD_EVENTS_ID = iRecordEventID
                       order by GCO_COMPONENT_ID
                              , ARC_POSITION) loop
        if    not PCS.PC_CONFIG.GetBooleanConfig('ASA_WORK_STOCK_MNG')
           or FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_MOVEMENT_KIND', 'C_MOVEMENT_SORT', ltplComp.STM_COMP_MVT_KIND_ID) = 'ENT' then
          ASA_PRC_STOCK_MOVEMENTS.CpSimpleOutputMvt(ltplComp.ASA_RECORD_COMP_ID, lMvtErrMess);
        else
          ASA_PRC_STOCK_MOVEMENTS.CpFactoryTransfertMvt(ltplComp.ASA_RECORD_COMP_ID, lMvtErrMess);
        end if;

        if lMvtErrMess is not null then
          -- On ne termine pas le traitement si le mouvement de stock déjà été effectué avant l'appel de CpSimpleOutputMvt ou CpFactoryTransfertMvt
          if ltplComp.STM_COMP_STOCK_MVT_ID is not null then
            null;   -- if movements already done, continue
          else
            ra(aMessage => lMvtErrMess, aErrNo => -20900);
          end if;
        end if;
      end loop;
    end pCompCreateStkMvts;
  begin
    -- Init des délais en fonction du nouveau statut
    ASA_I_PRC_RECORD_DELAY.InitAsaRecordDelay(iotAsaRecord);

    -- Création des mvts de stock et init du temps effectif des opérations
    if ASA_I_LIB_RECORD.isStatusInConfig(lNewStatus, 'ASA_REP_STATUS_MVTSTK_TIME') then
      -- Si la réparation utilise des composants, et que le code de mise à jour
      -- des mvt de stock est activé par le code de configuration ASA_GEN_STK_MVT_ON_REPAIR
      -- alors les mouvements de stock sont générés sur les composants
      if     FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotAsaRecord, 'ARE_USE_COMP')
         and (upper(PCS.PC_CONFIG.GetConfig('ASA_GEN_STK_MVT_ON_REPAIR') ) = 'TRUE') then
        pCompCreateStkMvts(lAsaRecordId, lRecordEventID);
      end if;

      -- Init du temps effectif des opérations
      if     FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotAsaRecord, 'ARE_USE_TASK')
         and (upper(PCS.PC_CONFIG.GetConfig('ASA_GEN_EFF_TIME_ON_REPAIR') ) = 'TRUE') then
        ASA_I_PRC_RECORD_TASK.InitTasksUsedTime(lAsaRecordID, lRecordEventID);
      end if;
    end if;

    -- Init des données du produit réparé
    if     lNewStatus >= PCS.PC_CONFIG.GetConfig('ASA_REP_STATUS_INIT_NEW_GOOD')
       and (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'C_ASA_REP_TYPE_KIND') = '3') then
      ASA_I_PRC_RECORD.InitRepairedGoodData(iotAsaRecord);
    end if;

    -- Réparation terminée
    if ASA_I_LIB_RECORD.isStatusInConfig(lNewStatus, 'ASA_REP_STATUS_CTR_STK_TIME') then
      -- Echange standard ou Echange avec un article ET Mvt pas encore fait
      if     (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotAsaRecord, 'C_ASA_REP_TYPE_KIND') in('1', '2') )
         and FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'STM_ASA_EXCH_MVT_ID') then
        -- Ctrl de la saisie des qtés et caract si gestion qté en rép.
        if ASA_I_LIB_RECORD.CtrlExchangeData(iotAsaRecord) then
          -- Mvt de stock pour échange

          -- Entrée article défectueux
          ASA_PRC_STOCK_MOVEMENTS.PdtRepairMvt(lAsaRecordID, lMvtErrMess);

          if lMvtErrMess is not null then
            ra(lMvtErrMess);
          end if;

          -- Sortie article pour échange
          ASA_PRC_STOCK_MOVEMENTS.PdtExchMvt(lAsaRecordID, lMvtErrMess);

          if lMvtErrMess is not null then
            ra(lMvtErrMess);
          end if;
        end if;
      end if;

      -- Réparation avec composants -> contrôle mvt de stock
      if FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotAsaRecord, 'ARE_USE_COMP') then
        if not ASA_I_PRC_RECORD_COMP.CtrlAllStkMvt(iAsaRecordID => lAsaRecordID, iRecordEventID => lRecordEventID) then
          RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Les mouvements de stock n''ont pas été effectués pour tous les composants !'), aErrNo => -20900);
        end if;
      end if;

      -- Réparation avec opérations -> contrôle si le temps effectif est saisi
      if FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotAsaRecord, 'ARE_USE_TASK') then
        if not ASA_I_PRC_RECORD_TASK.CtrlAllUsedTime(iAsaRecordID => lAsaRecordID, iRecordEventID => lRecordEventID) then
          RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Le temps effectif n''a pas été saisi sur toutes les opérations !'), aErrNo => -20900);
        end if;
      end if;
    end if;

    -- Début de garantie de la réparation
    if     ASA_I_LIB_RECORD.isStatusInConfig(lNewStatus, 'ASA_REP_STATUS_INIT_DATE_GAR')
       and FWK_I_MGT_ENTITY_DATA.IsNull(iotAsaRecord, 'ARE_REP_BEGIN_GUAR_DATE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_REP_BEGIN_GUAR_DATE', trunc(sysdate) );
      -- Calcul de la fin de garantie
      ASA_PRC_RECORD.InitRecordGarantyInfo(iotAsaRecord);
    end if;

    -- Sortie du stock atelier
    if ASA_I_LIB_RECORD.isStatusInConfig(lNewStatus, 'ASA_REP_STATUS_WORK_GEN_MVT') then
      ASA_I_PRC_RECORD_COMP.CreateWorkshopOutStkMvts(iAsaRecordID => lAsaRecordID, iRecordEventID => lRecordEventID);
    end if;

    -- Enregistrement de la traçabilité
    if ASA_I_LIB_RECORD.isStatusInConfig(lNewStatus, 'ASA_REP_STATUS_TRACABILITY') then
      declare
        lnErrorCode number;
      begin
        ASA_TRACABILITY.SaveTracability(lAsaRecordID, lnErrorCode);

        if lnErrorCode = 1 then
          RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Défaut d''appairage des composants et produits à réparer !'), aErrNo => -20900);
        end if;
      end;
    end if;

    -- Solde de la commande client
    if    ASA_I_LIB_RECORD.isStatusInConfig(lNewStatus, 'ASA_REP_STATUS_BALANCE_ORDER')
       or (lNewStatus = '11') then
      ASA_I_PRC_RECORD.BalanceOrderDocument(lAsaRecordID);
    end if;

    -- Suppression du document d'attribution
    if    ASA_I_LIB_RECORD.isStatusInConfig(lNewStatus, 'ASA_REP_STATUS_DEL_ATTRIB')
       or (lNewStatus = '11') then
      ASA_I_PRC_RECORD.DeleteDocumentAttrib(iotAsaRecord);
    end if;

    -- Màj de la date de modification du statut
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotAsaRecord, 'ARE_UPDATE_STATUS', trunc(sysdate) );
    -- Effacer la date d'impression
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotAsaRecord, 'ARE_PRINT_STATUS');
  end ManageStatus;

  /**
  * procedure CalcRecordPrices
  * Description
  *    Calcul des prix du dossier de réparation en monnaie de base
  * @created AGA 09.2011
  * @lastUpdate
  * @public
  * @param iotASA_RECORD enregistrement ASA_RECORD actif
  */
  procedure CalcRecordPrices(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnTotalCompSalePrice number;
    lnTotalCompCostPrice number;
    lnTotalTaskSalePrice number;
    lnTotalTaskCostPrice number;
  begin
    -- Recalcul des prix d'opérations
    if     FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_USE_TASK') = 1
       and (   FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_SALE_PRICE_2') = 1
            or FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_COST_PRICE_2') = 1
           ) then
      ASA_I_LIB_RECORD.GetTotalTaskPrice(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID'), lnTotalTaskSalePrice, lnTotalTaskCostPrice);

      if FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_SALE_PRICE_2') = 1 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_W', lnTotalTaskSalePrice);
      end if;

      if FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_COST_PRICE_2') = 1 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_W', lnTotalTaskCostPrice);
      end if;
    end if;

    -- Recalcul des prix de composants
    if     FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_USE_COMP') = 1
       and (   FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_SALE_PRICE_2') = 1
            or FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_COST_PRICE_2') = 1
           ) then
      ASA_I_LIB_RECORD.GetTotalCompPrice(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID'), lnTotalCompSalePrice, lnTotalCompCostPrice);

      if FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_SALE_PRICE_2') = 1 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_C', lnTotalCompSalePrice);
      end if;

      if FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_RECALC_COST_PRICE_2') = 1 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_C', lnTotalCompCostPrice);
      end if;
    end if;

    -- Recalcul prix total de l'article
    if    FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_USE_TASK') = 1
       or FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_USE_COMP') = 1 then
      -- Vente
      if    FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_W') <> 0
         or FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_C') <> 0
         or FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_S') <> 0 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                      , 'ARE_SALE_PRICE_T_MB'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_W') +
                                        FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_C') +
                                        FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_S')
                                       );
      end if;

      -- Revient
      if    FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_W') <> 0
         or FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_C') <> 0
         or FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_S') <> 0 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                      , 'ARE_COST_PRICE_T'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_W') +
                                        FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_C') +
                                        FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_S')
                                       );
      end if;
    end if;
  end CalcRecordPrices;

   /**
  * procedure ConvertRecordPrices
  * Description
  *    Convertion des prix du dossier de réparation en monnaie étrangère
  * @created AGA 09.2011
  * @lastUpdate
  * @public
  * @param iotASA_RECORD enregistrement ASA_RECORD actif
  */
  procedure ConvertRecordPrices(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lTempAmountB    number;
    lTempAmountE    number;
    lTempAmountEuro number;
    lTariffDateRef  date;
  begin
    lTariffDateRef  := ASA_LIB_RECORD.GetTariffDateRef(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_DATECRE') );

    -- prix de vente maximum
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_ME')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_MB') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_ME')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , 0
                               , lTempAmountEuro
                               , lTempAmountB
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_MB', lTempAmountB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_EURO', lTempAmountEuro);
    elsif     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_MB')
          and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_ME') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_MB')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , 0
                               , lTempAmountEuro
                               , lTempAmountE
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_ME', lTempAmountE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_EURO', lTempAmountEuro);
    end if;

    -- prix de vente minimum
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_ME')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_MB') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_ME')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , 0
                               , lTempAmountEuro
                               , lTempAmountB
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_MB', lTempAmountB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_EURO', lTempAmountEuro);
    elsif     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_MB')
          and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_ME') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_MB')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , 0
                               , lTempAmountEuro
                               , lTempAmountE
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_ME', lTempAmountE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_EURO', lTempAmountEuro);
    end if;

    -- prix de vente
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , 0
                               , lTempAmountEuro
                               , lTempAmountB
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', lTempAmountB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_EURO', lTempAmountEuro);
    elsif     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB')
          and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , 0
                               , lTempAmountEuro
                               , lTempAmountE
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME', lTempAmountE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_EURO', lTempAmountEuro);
    end if;

    -- prix du devis
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_PRICE_DEVIS_ME')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_PRICE_DEVIS_MB') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_PRICE_DEVIS_ME')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , 1
                               , lTempAmountEuro
                               , lTempAmountB
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PRICE_DEVIS_MB', lTempAmountB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PRICE_DEVIS_EURO', lTempAmountEuro);
    elsif     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_PRICE_DEVIS_MB')
          and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_PRICE_DEVIS_ME') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_PRICE_DEVIS_MB')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , 1
                               , lTempAmountEuro
                               , lTempAmountE
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PRICE_DEVIS_ME', lTempAmountE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PRICE_DEVIS_EURO', lTempAmountEuro);
    end if;

    -- prix de devis minimum
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_DEVIS_ME')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_DEVIS_MB') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_MIN_DEVIS_ME')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , 1
                               , lTempAmountEuro
                               , lTempAmountB
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_DEVIS_MB', lTempAmountB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_DEVIS_EURO', lTempAmountEuro);
    elsif     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_DEVIS_MB')
          and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_DEVIS_ME') then
      ACS_FUNCTION.ConvertAmount(FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotASA_RECORD, 'ARE_MIN_DEVIS_MB')
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                               , lTariffDateRef   -- Date pas prise en compte (car on passe le cours)
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH')
                               , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_CURR_BASE_PRICE')
                               , 1
                               , lTempAmountEuro
                               , lTempAmountE
                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_DEVIS_ME', lTempAmountE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_DEVIS_EURO', lTempAmountEuro);
    end if;
  end ConvertRecordPrices;

  /**
  * Procedure AcceptEstimateOption
  * Description
  *   Acceptation pour le devis de composants et/ou d'opérations
  *   en fonction de l'option
  */
  procedure AcceptEstimateOption(iAsaRecordId in ASA_RECORD.ASA_RECORD_ID%type, iOption in DIC_ASA_OPTION.DIC_ASA_OPTION_ID%type, iAccept in number)
  is
  begin
    -- Parcourir tous les composants pour cette option
    for tplComp in (select ASA_RECORD_COMP_ID
                      from ASA_RECORD_COMP
                     where ASA_RECORD_ID = iAsaRecordId
                       and DIC_ASA_OPTION_ID = iOption) loop
      ASA_I_PRC_RECORD_COMP.AcceptEstimateComponent(iComponentId => tplComp.ASA_RECORD_COMP_ID, iAccept => iAccept);
    end loop;

    -- Parcourir tous les opérations pour cette option
    for tplTask in (select ASA_RECORD_TASK_ID
                      from ASA_RECORD_TASK
                     where ASA_RECORD_ID = iAsaRecordId
                       and DIC_ASA_OPTION_ID = iOption) loop
      ASA_I_PRC_RECORD_TASK.AcceptEstimateTask(iTaskId => tplTask.ASA_RECORD_TASK_ID, iAccept => iAccept);
    end loop;
  end AcceptEstimateOption;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Initialisation des données d'entête
  */
  procedure InitRecordHeaderData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lGaugeId          DOC_GAUGE.DOC_GAUGE_ID%type                       := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'DOC_GAUGE_ID');
    lGaugeNumberingID DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
    lAreNumber        ASA_RECORD.ARE_NUMBER%type                        := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_NUMBER');
  begin
    if lAreNumber is null then
      DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(lGaugeId, lGaugeNumberingID, lAreNumber);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_NUMBER', lAreNumber);
    end if;
  end InitRecordHeaderData;

  /**
  * Description
  *   Initialisation des données à partir d'une carte de garantie
  */
  procedure InitRecordGuarantyCardData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplGuarantyCard ASA_GUARANTY_CARDS%rowtype;
    lGuarantyCardId  ASA_GUARANTY_CARDS.ASA_GUARANTY_CARDS_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_GUARANTY_CARDS_ID');
  begin
    select *
      into ltplGuarantyCard
      from ASA_GUARANTY_CARDS
     where ASA_GUARANTY_CARDS_ID = lGuarantyCardId;

    -- In the case of no good to repair is initialized
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID', ltplGuarantyCard.GCO_GOOD_ID);
    end if;

    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_FIN_SALE_DATE') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_FIN_SALE_DATE', ltplGuarantyCard.AGC_SALEDATE);
    end if;

    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_DET_SALE_DATE') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_DET_SALE_DATE', ltplGuarantyCard.AGC_SALEDATE_DET);
    end if;

    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_SALE_DATE') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_DATE', ltplGuarantyCard.AGC_SALEDATE_AGENT);
    end if;

    if ltplGuarantyCard.AGC_END is not null then
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE', ltplGuarantyCard.AGC_BEGIN);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_GUARANTY') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GUARANTY', ltplGuarantyCard.AGC_DAYS);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT', ltplGuarantyCard.C_ASA_GUARANTY_UNIT);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_END_GUARANTY_DATE') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_END_GUARANTY_DATE', ltplGuarantyCard.AGC_END);
      end if;
    end if;

    -- if no customer defined
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID')
       and ltplGuarantyCard.PAC_ASA_AGENT_ID is not null then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID', ltplGuarantyCard.PAC_ASA_AGENT_ID);

      -- if no customer language defined
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID', ltplGuarantyCard.PC_ASA_AGENT_LANG_ID);
      end if;

      -- if no customer address defined
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PAC_ASA_ADDR1_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_ADDR1_ID', ltplGuarantyCard.PAC_ASA_AGENT_ADDR_ID);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS1', ltplGuarantyCard.AGC_ADDRESS_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE1', ltplGuarantyCard.AGC_POSTCODE_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN1', ltplGuarantyCard.AGC_TOWN_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE1', ltplGuarantyCard.AGC_STATE_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF1', ltplGuarantyCard.AGC_CARE_OF_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX1', ltplGuarantyCard.AGC_PO_BOX_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR1', ltplGuarantyCard.AGC_PO_BOX_NBR_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY1', ltplGuarantyCard.AGC_COUNTY_AGENT);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CNTRY1_ID', ltplGuarantyCard.PC_ASA_AGENT_CNTRY_ID);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                      , 'ARE_FORMAT_CITY1'
                                      , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplGuarantyCard.AGC_POSTCODE_AGENT
                                                                              , ltplGuarantyCard.AGC_TOWN_AGENT
                                                                              , ltplGuarantyCard.AGC_STATE_AGENT
                                                                              , ltplGuarantyCard.AGC_COUNTY_AGENT
                                                                              , ltplGuarantyCard.PC_ASA_AGENT_CNTRY_ID
                                                                               )
                                       );
      end if;
    elsif     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID')
          and ltplGuarantyCard.PAC_ASA_DISTRIB_ID is not null then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID', ltplGuarantyCard.PAC_ASA_DISTRIB_ID);

      -- if no customer language defined
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID', ltplGuarantyCard.PC_ASA_DISTRIB_LANG_ID);
      end if;

      -- if no customer address defined
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PAC_ASA_ADDR1_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_ADDR1_ID', ltplGuarantyCard.PAC_ASA_DISTRIB_ADDR_ID);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS1', ltplGuarantyCard.AGC_ADDRESS_DISTRIB);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE1', ltplGuarantyCard.AGC_POSTCODE_DISTRIB);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN1', ltplGuarantyCard.AGC_TOWN_DISTRIB);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE1', ltplGuarantyCard.AGC_STATE_DISTRIB);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF1', ltplGuarantyCard.AGC_CARE_OF_DET);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX1', ltplGuarantyCard.AGC_PO_BOX_DET);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR1', ltplGuarantyCard.AGC_PO_BOX_NBR_DET);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY1', ltplGuarantyCard.AGC_COUNTY_DET);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CNTRY1_ID', ltplGuarantyCard.PC_ASA_DISTRIB_CNTRY_ID);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                      , 'ARE_FORMAT_CITY1'
                                      , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplGuarantyCard.AGC_POSTCODE_DISTRIB
                                                                              , ltplGuarantyCard.AGC_TOWN_DISTRIB
                                                                              , ltplGuarantyCard.AGC_STATE_DISTRIB
                                                                              , ltplGuarantyCard.AGC_COUNTY_DET
                                                                              , ltplGuarantyCard.PC_ASA_DISTRIB_CNTRY_ID
                                                                               )
                                       );
      end if;
    elsif     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID')
          and ltplGuarantyCard.PAC_ASA_FIN_CUST_ID is not null then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID', ltplGuarantyCard.PAC_ASA_FIN_CUST_ID);

      -- if no customer language defined
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID', ltplGuarantyCard.PC_ASA_FIN_CUST_LANG_ID);
      end if;

      -- if no customer address defined
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PAC_ASA_ADDR1_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_ADDR1_ID', ltplGuarantyCard.PAC_ASA_FIN_CUST_ADDR_ID);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS1', ltplGuarantyCard.AGC_ADDRESS_FIN_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE1', ltplGuarantyCard.AGC_POSTCODE_FIN_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN1', ltplGuarantyCard.AGC_TOWN_FIN_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE1', ltplGuarantyCard.AGC_STATE_FIN_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF1', ltplGuarantyCard.AGC_CARE_OF_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX1', ltplGuarantyCard.AGC_PO_BOX_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR1', ltplGuarantyCard.AGC_PO_BOX_NBR_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY1', ltplGuarantyCard.AGC_COUNTY_CUST);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CNTRY1_ID', ltplGuarantyCard.PC_ASA_FIN_CUST_CNTRY_ID);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                      , 'ARE_FORMAT_CITY1'
                                      , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplGuarantyCard.AGC_POSTCODE_FIN_CUST
                                                                              , ltplGuarantyCard.AGC_TOWN_FIN_CUST
                                                                              , ltplGuarantyCard.AGC_STATE_FIN_CUST
                                                                              , ltplGuarantyCard.AGC_COUNTY_CUST
                                                                              , ltplGuarantyCard.PC_ASA_FIN_CUST_CNTRY_ID
                                                                               )
                                       );
      end if;
    end if;

    -- if no agent defined
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PAC_ASA_AGENT_ID') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_AGENT_ID', ltplGuarantyCard.PAC_ASA_AGENT_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_AGENT_LANG_ID', ltplGuarantyCard.PC_ASA_AGENT_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_AGENT_ADDR_ID', ltplGuarantyCard.PAC_ASA_AGENT_ADDR_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS_AGENT', ltplGuarantyCard.AGC_ADDRESS_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE_AGENT', ltplGuarantyCard.AGC_POSTCODE_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN_AGENT', ltplGuarantyCard.AGC_TOWN_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE_AGENT', ltplGuarantyCard.AGC_STATE_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF_AGENT', ltplGuarantyCard.AGC_CARE_OF_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_AGENT', ltplGuarantyCard.AGC_PO_BOX_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR_AGENT', ltplGuarantyCard.AGC_PO_BOX_NBR_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY_AGENT', ltplGuarantyCard.AGC_COUNTY_AGENT);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_AGENT_CNTRY_ID', ltplGuarantyCard.PC_ASA_AGENT_CNTRY_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                    , 'ARE_FORMAT_CITY_AGENT'
                                    , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplGuarantyCard.AGC_POSTCODE_AGENT
                                                                            , ltplGuarantyCard.AGC_TOWN_AGENT
                                                                            , ltplGuarantyCard.AGC_STATE_AGENT
                                                                            , ltplGuarantyCard.AGC_COUNTY_AGENT
                                                                            , ltplGuarantyCard.PC_ASA_AGENT_CNTRY_ID
                                                                             )
                                     );
    end if;

    -- if no distributor defined
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PAC_ASA_DISTRIB_ID') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_DISTRIB_ID', ltplGuarantyCard.PAC_ASA_DISTRIB_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_DISTRIB_LANG_ID', ltplGuarantyCard.PC_ASA_DISTRIB_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_DISTRIB_ADDR_ID', ltplGuarantyCard.PAC_ASA_DISTRIB_ADDR_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS_DISTRIB', ltplGuarantyCard.AGC_ADDRESS_DISTRIB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE_DISTRIB', ltplGuarantyCard.AGC_POSTCODE_DISTRIB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN_DISTRIB', ltplGuarantyCard.AGC_TOWN_DISTRIB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE_DISTRIB', ltplGuarantyCard.AGC_STATE_DISTRIB);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF_DET', ltplGuarantyCard.AGC_CARE_OF_DET);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_DET', ltplGuarantyCard.AGC_PO_BOX_DET);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR_DET', ltplGuarantyCard.AGC_PO_BOX_NBR_DET);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY_DET', ltplGuarantyCard.AGC_COUNTY_DET);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_DISTRIB_CNTRY_ID', ltplGuarantyCard.PC_ASA_DISTRIB_CNTRY_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                    , 'ARE_FORMAT_CITY_DISTRIB'
                                    , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplGuarantyCard.AGC_POSTCODE_DISTRIB
                                                                            , ltplGuarantyCard.AGC_TOWN_DISTRIB
                                                                            , ltplGuarantyCard.AGC_STATE_DISTRIB
                                                                            , ltplGuarantyCard.AGC_COUNTY_DET
                                                                            , ltplGuarantyCard.PC_ASA_DISTRIB_CNTRY_ID
                                                                             )
                                     );
    end if;

    -- if no final customer defined
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PAC_ASA_FIN_CUST_ID') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_FIN_CUST_ID', ltplGuarantyCard.PAC_ASA_FIN_CUST_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_FIN_CUST_LANG_ID', ltplGuarantyCard.PC_ASA_FIN_CUST_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_FIN_CUST_ADDR_ID', ltplGuarantyCard.PAC_ASA_FIN_CUST_ADDR_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS_FIN_CUST', ltplGuarantyCard.AGC_ADDRESS_FIN_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE_FIN_CUST', ltplGuarantyCard.AGC_POSTCODE_FIN_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN_FIN_CUST', ltplGuarantyCard.AGC_TOWN_FIN_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE_FIN_CUST', ltplGuarantyCard.AGC_STATE_FIN_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF_CUST', ltplGuarantyCard.AGC_CARE_OF_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_CUST', ltplGuarantyCard.AGC_PO_BOX_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR_CUST', ltplGuarantyCard.AGC_PO_BOX_NBR_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY_CUST', ltplGuarantyCard.AGC_COUNTY_CUST);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_FIN_CUST_CNTRY_ID', ltplGuarantyCard.PC_ASA_FIN_CUST_CNTRY_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                    , 'ARE_FORMAT_CITY_FIN_CUST'
                                    , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplGuarantyCard.AGC_POSTCODE_FIN_CUST
                                                                            , ltplGuarantyCard.AGC_TOWN_FIN_CUST
                                                                            , ltplGuarantyCard.AGC_STATE_FIN_CUST
                                                                            , ltplGuarantyCard.AGC_COUNTY_CUST
                                                                            , ltplGuarantyCard.PC_ASA_FIN_CUST_CNTRY_ID
                                                                             )
                                     );
    end if;

    -- Initialization of charaterizations
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR1_ID', ltplGuarantyCard.GCO_CHAR1_ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR2_ID', ltplGuarantyCard.GCO_CHAR2_ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR3_ID', ltplGuarantyCard.GCO_CHAR3_ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR4_ID', ltplGuarantyCard.GCO_CHAR4_ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR5_ID', ltplGuarantyCard.GCO_CHAR5_ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR1_VALUE', ltplGuarantyCard.AGC_CHAR1_VALUE);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR2_VALUE', ltplGuarantyCard.AGC_CHAR2_VALUE);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR3_VALUE', ltplGuarantyCard.AGC_CHAR3_VALUE);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR4_VALUE', ltplGuarantyCard.AGC_CHAR4_VALUE);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR5_VALUE', ltplGuarantyCard.AGC_CHAR5_VALUE);
  end InitRecordGuarantyCardData;

  /**
  * Description
  *   Initialisation des données à partir d'un détail de position document source
  */
  procedure InitRecordFromPositionDetail(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lPositionDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'DOC_ORIGIN_POSITION_DETAIL_ID');
    lPositionId       DOC_POSITION_DETAIL.DOC_POSITION_ID%type          := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'DOC_ORIGIN_POSITION_ID');
    lDistribConfig    varchar2(1)                                       := PCS.PC_CONFIG.GetConfig('ASA_DISTRIBUTION_MODE');
  begin
    if     lPositionDetailId is null
       and lPositionId is not null then
      select min(DOC_POSITION_DETAIL_ID)
        into lPositionDetailId
        from DOC_POSITION_DETAIL
       where DOC_POSITION_ID = lPositionId;

      if lPositionDetailId is null then
        return;
      end if;
    end if;

    -- boucle à une seule row
    for ltplPositionDetail in (select A.PAC_THIRD_ID
                                    , PAC_ADDRESS_ID
                                    , PC_LANG_ID
                                    , DMT_ADDRESS1
                                    , DMT_POSTCODE1
                                    , DMT_TOWN1
                                    , DMT_STATE1
                                    , DMT_FORMAT_CITY1
                                    , DMT_DATE_DOCUMENT
                                    , PC_CNTRY_ID
                                    , B.GCO_GOOD_ID
                                    , B.DOC_POSITION_ID
                                    , C.PDE_CHARACTERIZATION_VALUE_1 ARE_CHAR1_VALUE
                                    , C.PDE_CHARACTERIZATION_VALUE_2 ARE_CHAR2_VALUE
                                    , C.PDE_CHARACTERIZATION_VALUE_3 ARE_CHAR3_VALUE
                                    , C.PDE_CHARACTERIZATION_VALUE_4 ARE_CHAR4_VALUE
                                    , C.PDE_CHARACTERIZATION_VALUE_5 ARE_CHAR5_VALUE
                                    , C.GCO_CHARACTERIZATION_ID GCO_CHAR1_ID
                                    , C.GCO_GCO_CHARACTERIZATION_ID GCO_CHAR2_ID
                                    , C.GCO2_GCO_CHARACTERIZATION_ID GCO_CHAR3_ID
                                    , C.GCO3_GCO_CHARACTERIZATION_ID GCO_CHAR4_ID
                                    , C.GCO4_GCO_CHARACTERIZATION_ID GCO_CHAR5_ID
                                 from DOC_POSITION_DETAIL C
                                    , DOC_POSITION B
                                    , DOC_DOCUMENT A
                                where C.DOC_POSITION_DETAIL_ID = lPositionDetailId
                                  and B.DOC_POSITION_ID = C.DOC_POSITION_ID
                                  and A.DOC_DOCUMENT_ID = B.DOC_DOCUMENT_ID) loop
      -- In the case of the position is not initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DOC_ORIGIN_POSITION_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DOC_ORIGIN_POSITION_ID', ltplPositionDetail.DOC_POSITION_ID);
      end if;

      -- In the case of no good to repair is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID', ltplPositionDetail.GCO_GOOD_ID);
      end if;

      -- In the case of no customer is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID', ltplPositionDetail.PAC_THIRD_ID);
      end if;

      --Dates
      case
        -- Vente à l'agent -> Vente au détaillant ->  Vente au client final
      when lDistribConfig = '1' then
          if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_SALE_DATE') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_DATE', ltplPositionDetail.DMT_DATE_DOCUMENT);
          end if;
        -- Vente au détaillant ->  Vente au client final
      when lDistribConfig = '2' then
          if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_DET_SALE_DATE') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_DET_SALE_DATE', ltplPositionDetail.DMT_DATE_DOCUMENT);
          end if;
        -- Vente directe au client final
      when lDistribConfig = '3' then
          if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_FIN_SALE_DATE') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_FIN_SALE_DATE', ltplPositionDetail.DMT_DATE_DOCUMENT);
          end if;
      end case;
    end loop;
  end InitRecordFromPositionDetail;

  /**
  * Description
  *    Initialisation des champs depuis le dossier
  */
  procedure InitRecordFromSourceRecord(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lSourceRecordId ASA_RECORD.ASA_RECORD_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_LAST_RECORD_ID');
  begin
    -- boucle à une seule row
    for ltplSourceRecord in (select *
                               from ASA_RECORD
                              where ASA_RECORD_ID = lSourceRecordId) loop
      -- In the case of the position is not initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DOC_ORIGIN_POSITION_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DOC_ORIGIN_POSITION_ID', ltplSourceRecord.DOC_ORIGIN_POSITION_ID);
      end if;

      -- In the case of no good to repair is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID', ltplSourceRecord.GCO_NEW_GOOD_ID);
      end if;

      -- In the case of no customer is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID', ltplSourceRecord.PAC_CUSTOM_PARTNER_ID);
      end if;

      if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_END_GUARANTY_DATE')
         and ltplSourceRecord.ARE_END_GUARANTY_DATE is not null then
        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE', ltplSourceRecord.ARE_BEGIN_GUARANTY_DATE);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GUARANTY') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GUARANTY', ltplSourceRecord.ARE_GUARANTY);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT', ltplSourceRecord.C_ASA_GUARANTY_UNIT);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_END_GUARANTY_DATE') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                        , 'ARE_END_GUARANTY_DATE'
                                        , greatest(ltplSourceRecord.ARE_END_GUARANTY_DATE, ltplSourceRecord.ARE_REP_END_GUAR_DATE)
                                         );
        end if;
      end if;
    end loop;
  end InitRecordFromSourceRecord;

  /**
  * Description
  *    Initialisation du dossier d'après la liste des biens volés
  */
  procedure InitRecordFromStolenGood(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lStolenGoodId ASA_STOLEN_GOODS.ASA_STOLEN_GOODS_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_STOLEN_GOODS_ID');
  begin
    -- boucle à une seule row
    for ltplStolenGood in (select *
                             from ASA_STOLEN_GOODS
                            where ASA_STOLEN_GOODS_ID = lStolenGoodId) loop
      -- In the case of no good to repair is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID', ltplStolenGood.GCO_GOOD_ID);
      end if;

      -- In the case of no finnacial customer is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_ASA_FIN_CUST_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_FIN_CUST_ID', ltplStolenGood.PAC_ASA_FIN_CUST_ID);
      end if;

      -- In the case of no agent is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_ASA_AGENT_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_AGENT_ID', ltplStolenGood.PAC_ASA_AGENT_ID);
      end if;

      -- In the case of no distributor is initialized
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_ASA_DISTRIB_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_DISTRIB_ID', ltplStolenGood.PAC_ASA_DISTRIB_ID);
      end if;

      -- Initialization of charaterizations
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR1_ID', ltplStolenGood.GCO_CHAR1_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR2_ID', ltplStolenGood.GCO_CHAR2_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR3_ID', ltplStolenGood.GCO_CHAR3_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR4_ID', ltplStolenGood.GCO_CHAR4_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR5_ID', ltplStolenGood.GCO_CHAR5_ID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR1_VALUE', ltplStolenGood.ASG_CHAR1_VALUE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR2_VALUE', ltplStolenGood.ASG_CHAR2_VALUE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR3_VALUE', ltplStolenGood.ASG_CHAR3_VALUE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR4_VALUE', ltplStolenGood.ASG_CHAR4_VALUE);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR5_VALUE', ltplStolenGood.ASG_CHAR5_VALUE);
    end loop;
  end InitRecordFromStolenGood;

  /**
  * Description
  *    Initialisation à partir d'un numéro de pièce
  */
  procedure InitRecordFromPieceNumber(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lPos    pls_integer;
    lnID    ASA_RECORD.ASA_RECORD_ID%type;
    lCharId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    GCO_LIB_CHARACTERIZATION.getCharIDandPos(iGoodId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                           , iType     => '3'
                                           , oCharID   => lCharId
                                           , oPos      => lPos
                                            );

    if lCharId <> 0 then
      case
        when lPos = 1 then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR1_ID', lCharId);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR1_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE') );
        when lPos = 2 then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR2_ID', lCharId);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR2_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE') );
        when lPos = 3 then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR3_ID', lCharId);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR3_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE') );
        when lPos = 4 then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR4_ID', lCharId);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR4_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE') );
        when lPos = 5 then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_CHAR5_ID', lCharId);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CHAR5_VALUE', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE') );
      end case;
    end if;

    -- Recherche de l'id de la dernière réparation concernant le bien/n°série
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ASA_LAST_RECORD_ID') then
      lnID  :=
        ASA_I_LIB_RECORD.GetLastRecordID(iAsaRecordID      => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID')
                                       , iGoodToRepairID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                       , iCharValue        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE')
                                       , iCustomerID       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID')
                                        );

      if lnID is not null then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ASA_LAST_RECORD_ID', lnID);
      end if;
    end if;

    -- Recherche du document logistique
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DOC_ORIGIN_POSITION_ID') then
      lnID  :=
        ASA_I_LIB_RECORD.GetOriginPosID(iGoodToRepairID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                      , iCharValue        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE')
                                       );

      if lnID is not null then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DOC_ORIGIN_POSITION_ID', lnID);
      end if;
    end if;

    -- Recherche de l'id carte de garantie pour un bien/n°série
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ASA_GUARANTY_CARDS_ID') then
      lnID  :=
        ASA_I_LIB_RECORD.GetGoodGuarantyCardsID(iGoodID      => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                              , iCharValue   => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE')
                                               );

      if lnID is not null then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ASA_GUARANTY_CARDS_ID', lnID);
      end if;
    end if;

    -- Recherche de l'id de la pièce volée validée pour un bien/n°série
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ASA_STOLEN_GOODS_ID') then
      lnID  :=
        ASA_I_LIB_RECORD.GetStolenGoodsID(iGoodID      => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                        , iCharValue   => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE')
                                         );

      if lnID is not null then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ASA_STOLEN_GOODS_ID', lnID);
      end if;
    end if;
  end InitRecordFromPieceNumber;

  /**
  * Description
  *   Initialisation of data from DOC_RECORD
  */
  procedure InitRecordDocRecordData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lThirdId  PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    lRecordId DOC_RECORD.DOC_RECORD_ID%type                   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'DOC_RECORD_ID');
  begin
    -- if no pac_custom_partner defined, look for it in DOC_RECORD
    if     lRecordId is not null
       and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID') then
      select max(CUS.PAC_CUSTOM_PARTNER_ID)
        into lThirdId
        from DOC_RECORD REC
           , PAC_CUSTOM_PARTNER CUS
       where CUS.PAC_CUSTOM_PARTNER_ID = REC.PAC_THIRD_ID
         and REC.DOC_RECORD_ID = lRecordId;

      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID', lThirdId);
    end if;
  end InitRecordDocRecordData;

  /**
  * Description
  *   Initialisation of data from PAC_CUSTOM_PARTNER
  */
  procedure InitRecordCustomerData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lCustomerId          PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type         := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID');
    lGaugeId             DOC_GAUGE.DOC_GAUGE_ID%type                             := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'DOC_GAUGE_ID');
    lFinCurrId           ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lARE_NB_DAYS_SENDING PAC_CUSTOM_PARTNER.CUS_DELIVERY_DELAY%type              := -1;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_CUSTOMER_ERROR') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_CUSTOMER_ERROR', 0);
    end if;

    -- if Customer defined then init fileds from customer datas
    if lCustomerId is not null then
      for tplCustomer in (select CUS.PAC_REPRESENTATIVE_ID
                               , CUS.ACS_FIN_ACC_S_PAYMENT_ID
                               , CUS.PAC_PAYMENT_CONDITION_ID
                               , CUS.PAC_SENDING_CONDITION_ID
                               , CUS.CUS_DELIVERY_DELAY
                               , CUS.DIC_TARIFF_ID
                               , CUS.DIC_TYPE_SUBMISSION_ID
                            from PAC_CUSTOM_PARTNER CUS
                           where CUS.PAC_CUSTOM_PARTNER_ID = lCustomerId) loop
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_REPRESENTATIVE_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_REPRESENTATIVE_ID', tplCustomer.PAC_REPRESENTATIVE_ID);
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ACS_FIN_ACC_S_PAYMENT_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ACS_FIN_ACC_S_PAYMENT_ID', tplCustomer.ACS_FIN_ACC_S_PAYMENT_ID);
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_PAYMENT_CONDITION_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_PAYMENT_CONDITION_ID', tplCustomer.PAC_PAYMENT_CONDITION_ID);
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_SENDING_CONDITION_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_SENDING_CONDITION_ID', tplCustomer.PAC_SENDING_CONDITION_ID);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_NB_DAYS_SENDING') then
          lARE_NB_DAYS_SENDING  := tplCustomer.CUS_DELIVERY_DELAY;
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'DIC_TARIFF_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TARIFF_ID', tplCustomer.DIC_TARIFF_ID);
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TYPE_SUBMISSION_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TYPE_SUBMISSION_ID', tplCustomer.DIC_TYPE_SUBMISSION_ID);
        end if;
      end loop;

      -- recherche de la communication par défaut si aucune n'a été passée en paramètre
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_COMMUNICATION_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_COMMUNICATION_ID', PAC_I_LIB_THIRD.GetDefaultCommunication(lCustomerId) );
      end if;

      -- recherche de la communication par défaut si aucune n'a été passée en paramètre
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_COMMUNICATION_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn
                                       (iotASA_RECORD
                                      , 'ARE_CONTACT_COMMENT'
                                      , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name   => 'PAC_COMMUNICATION'
                                                                              , iv_column_name   => 'COM_COMMENT'
                                                                              , it_pk_value      => FWK_I_MGT_ENTITY_DATA.GetColumnNumber
                                                                                                                                         (iotASA_RECORD
                                                                                                                                        , 'PAC_COMMUNICATION_ID'
                                                                                                                                         )
                                                                               )
                                       );
      end if;
    end if;

    for ltplGauge in (select GAU.C_ADMIN_DOMAIN
                           , GAU.DIC_ADDRESS_TYPE_ID
                           , GAU.DIC_ADDRESS_TYPE1_ID
                           , GAU.DIC_ADDRESS_TYPE2_ID
                           , GAS.GAS_PAY_CONDITION
                           , GAS.PAC_PAYMENT_CONDITION_ID
                           , GAS.ACS_FIN_ACC_S_PAYMENT_ID
                        from DOC_GAUGE GAU
                           , DOC_GAUGE_STRUCTURED GAS
                       where GAU.DOC_GAUGE_ID = lGaugeId
                         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID) loop
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID') then
        lFinCurrId  := DOC_DOCUMENT_FUNCTIONS.GetAdminDomainCurrencyId(ltplGauge.C_ADMIN_DOMAIN, lCustomerId);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID', lFinCurrId);

        if lFinCurrId = ACS_FUNCTION.GetLocalCurrencyId then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH', 1);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CURR_BASE_PRICE', 1);
        end if;
      end if;

      if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_PAYMENT_CONDITION_ID')
         and ltplGauge.PAC_PAYMENT_CONDITION_ID is not null
         and ltplGauge.GAS_PAY_CONDITION = 1 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_PAYMENT_CONDITION_ID', ltplGauge.PAC_PAYMENT_CONDITION_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ACS_FIN_ACC_S_PAYMENT_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ACS_FIN_ACC_S_PAYMENT_ID', ltplGauge.ACS_FIN_ACC_S_PAYMENT_ID);
      end if;

      -- si pas de données d'adresses définies, init automatique des adresses
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_TOWN1') then
        for ltplAdresse in (select   ADR.PAC_ADDRESS_ID
                                   , ADR.DIC_ADDRESS_TYPE_ID
                                   , ADR.ADD_ADDRESS1
                                   , ADR.ADD_ZIPCODE
                                   , ADR.ADD_CITY
                                   , ADR.ADD_STATE
                                   , ADR.ADD_CARE_OF
                                   , ADR.ADD_PO_BOX
                                   , ADR.ADD_PO_BOX_NBR
                                   , ADR.ADD_COUNTY
                                   , ADR.PC_CNTRY_ID
                                   , ADR.PC_LANG_ID
                                   , MAIN.ROWNB
                                from PAC_ADDRESS ADR
                                   , (select max(PAC_ADDRESS_ID) PAC_ADDRESS_ID
                                           , 1 ROWNB
                                        from PAC_ADDRESS
                                       where PAC_PERSON_ID = lCustomerId
                                         and DIC_ADDRESS_TYPE_ID = ltplGauge.DIC_ADDRESS_TYPE_ID
                                      union all
                                      select max(PAC_ADDRESS_ID) PAC_ADDRESS_ID
                                           , 2 ROWNB
                                        from PAC_ADDRESS
                                       where PAC_PERSON_ID = lCustomerId
                                         and DIC_ADDRESS_TYPE_ID = ltplGauge.DIC_ADDRESS_TYPE1_ID
                                      union all
                                      select max(PAC_ADDRESS_ID) PAC_ADDRESS_ID
                                           , 3 ROWNB
                                        from PAC_ADDRESS
                                       where PAC_PERSON_ID = lCustomerId
                                         and DIC_ADDRESS_TYPE_ID = ltplGauge.DIC_ADDRESS_TYPE2_ID) MAIN
                               where ADR.PAC_ADDRESS_ID = nvl(MAIN.PAC_ADDRESS_ID, (select PAC_ADDRESS_ID
                                                                                      from PAC_ADDRESS
                                                                                     where PAC_PERSON_ID = lCustomerId
                                                                                       and ADD_PRINCIPAL = 1) )
                            order by MAIN.ROWNB) loop
          case
            when ltplAdresse.ROWNB = 1 then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_ADDR1_ID', ltplAdresse.PAC_ADDRESS_ID);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS1', ltplAdresse.ADD_ADDRESS1);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE1', ltplAdresse.ADD_ZIPCODE);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN1', ltplAdresse.ADD_CITY);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE1', ltplAdresse.ADD_STATE);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF1', ltplAdresse.ADD_CARE_OF);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX1', ltplAdresse.ADD_PO_BOX);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR1', ltplAdresse.ADD_PO_BOX_NBR);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY1', ltplAdresse.ADD_COUNTY);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CNTRY1_ID', ltplAdresse.PC_CNTRY_ID);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID', ltplAdresse.PC_LANG_ID);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                            , 'ARE_FORMAT_CITY1'
                                            , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplAdresse.ADD_ZIPCODE
                                                                                    , ltplAdresse.ADD_CITY
                                                                                    , ltplAdresse.ADD_STATE
                                                                                    , ltplAdresse.ADD_COUNTY
                                                                                    , ltplAdresse.PC_CNTRY_ID
                                                                                     )
                                             );
            when ltplAdresse.ROWNB = 2 then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_ADDR2_ID', ltplAdresse.PAC_ADDRESS_ID);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS2', ltplAdresse.ADD_ADDRESS1);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE2', ltplAdresse.ADD_ZIPCODE);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN2', ltplAdresse.ADD_CITY);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE2', ltplAdresse.ADD_STATE);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF2', ltplAdresse.ADD_CARE_OF);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX2', ltplAdresse.ADD_PO_BOX);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR2', ltplAdresse.ADD_PO_BOX_NBR);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY2', ltplAdresse.ADD_COUNTY);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CNTRY2_ID', ltplAdresse.PC_CNTRY_ID);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                            , 'ARE_FORMAT_CITY2'
                                            , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplAdresse.ADD_ZIPCODE
                                                                                    , ltplAdresse.ADD_CITY
                                                                                    , ltplAdresse.ADD_STATE
                                                                                    , ltplAdresse.ADD_COUNTY
                                                                                    , ltplAdresse.PC_CNTRY_ID
                                                                                     )
                                             );
            when ltplAdresse.ROWNB = 3 then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_ASA_ADDR3_ID', ltplAdresse.PAC_ADDRESS_ID);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_ADDRESS3', ltplAdresse.ADD_ADDRESS1);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_POSTCODE3', ltplAdresse.ADD_ZIPCODE);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_TOWN3', ltplAdresse.ADD_CITY);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_STATE3', ltplAdresse.ADD_STATE);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CARE_OF3', ltplAdresse.ADD_CARE_OF);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX3', ltplAdresse.ADD_PO_BOX);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PO_BOX_NBR3', ltplAdresse.ADD_PO_BOX_NBR);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COUNTY3', ltplAdresse.ADD_COUNTY);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CNTRY3_ID', ltplAdresse.PC_CNTRY_ID);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                            , 'ARE_FORMAT_CITY3'
                                            , PAC_PARTNER_MANAGEMENT.FormatingAddress(ltplAdresse.ADD_ZIPCODE
                                                                                    , ltplAdresse.ADD_CITY
                                                                                    , ltplAdresse.ADD_STATE
                                                                                    , ltplAdresse.ADD_COUNTY
                                                                                    , ltplAdresse.PC_CNTRY_ID
                                                                                     )
                                             );
          end case;
        end loop;
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID', PCS.PC_I_LIB_SESSION.GetUserLangId);
      end if;
    end loop;
  end InitRecordCustomerData;

  /**
  * Description
  *   Initialisation of currency rate
  */
  procedure InitRecordExchangeRate(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRateExchange       number;
    lBasePrice          number;
    lBaseChange         number;
    lRateExchangeEUR_ME number;
    lFixedRateEUR_ME    number;
    lRateExchangeEUR_MB number;
    lFixedRateEUR_MB    number;
    lIsRate             number;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID') then
      RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('La monnaie n''est pas définie !'), aErrNo => -20900);
    elsif     FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID') = ACS_FUNCTION.GetLocalCurrencyId
          and (ACS_FUNCTION.IsFinCurrInEuro(ACS_FUNCTION.GetLocalCurrencyId, trunc(sysdate) ) = 0) then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH', 1);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CURR_BASE_PRICE', 1);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_EURO_CURRENCY', 0);
    else
      lIsrate  :=
        ACS_FUNCTION.GetRateOfExchangeEUR(aCurrencyID           => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ACS_FINANCIAL_CURRENCY_ID')
                                        , aSortRate             => '5'   -- cours de facturation
                                        , aDate                 => ASA_LIB_RECORD.GetTariffDateRef(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD
                                                                                                                                     , 'ARE_DATECRE'
                                                                                                                                      )
                                                                                                  )
                                        , aRateExchange         => lRateExchange
                                        , aBasePrice            => lBasePrice
                                        , aBaseChange           => lBaseChange
                                        , aRateExchangeEUR_ME   => lRateExchangeEUR_ME
                                        , aFixedRateEUR_ME      => lFixedRateEUR_ME
                                        , aRateExchangeEUR_MB   => lRateExchangeEUR_MB
                                        , aFixedRateEUR_MB      => lFixedRateEUR_MB
                                         );

      if lIsRate = 1 then
        --Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base
        if (lBaseChange = 0) then
          lRateExchange  :=( (lBasePrice * lBasePrice) / lRateExchange);
        end if;

        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CURR_RATE_OF_EXCH', lRateExchange);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CURR_BASE_PRICE', lBasePrice);

        if lFixedRateEUR_ME = 1 then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_CURR_RATE_EURO', lRateExchangeEUR_MB);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_EURO_CURRENCY', 1);
        else
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_EURO_CURRENCY', 0);
        end if;
      else
        RA(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Pas de cours de change défini pour cette monnaie !'), aErrNo => -20900);
      end if;
    end if;
  end InitRecordExchangeRate;

  /**
  * Description
  *   Initialisation of devis datas
  */
  procedure InitRecordDevisData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    --FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_USE_COMP', 0);
    --FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_USE_TASK', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_DATECRE', trunc(sysdate) );

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'C_ASA_DEVIS_CODE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'C_ASA_DEVIS_CODE', nvl(PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_DEVIS_CODE'), '3') );
    end if;

    if     FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'C_ASA_DEVIS_CODE') = '3'
       and nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_MIN_DEVIS_MB'), 0) = 0 then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_DEVIS_MB', nvl(PCS.PC_CONFIG.GetConfig('ASA_MINIMAL_DEVIS_AMOUNT'), 0) );
    else
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_DEVIS_MB', 0);
    end if;
  end InitRecordDevisData;

  /**
  * Description
  *   Normalize characterizations informations
  */
  procedure NormalizeRecordClassif(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    declare
      lGoodRepairId GCO_GOOD.GCO_GOOD_ID%type                           := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID');
      lCharId1      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId2      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId3      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId4      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId5      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharValue1   ASA_RECORD.ARE_CHAR1_VALUE%type;
      lCharValue2   ASA_RECORD.ARE_CHAR1_VALUE%type;
      lCharValue3   ASA_RECORD.ARE_CHAR1_VALUE%type;
      lCharValue4   ASA_RECORD.ARE_CHAR1_VALUE%type;
      lCharValue5   ASA_RECORD.ARE_CHAR1_VALUE%type;
    begin
      if lGoodRepairId is not null then
        -- if "normal way" is given we used it
        if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_CHAR1_VALUE') then
          GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => lGoodRepairId
                                                   , iNoStkChar     => 1
                                                   , oCharactID_1   => lCharId1
                                                   , oCharactID_2   => lCharId2
                                                   , oCharactID_3   => lCharId3
                                                   , oCharactID_4   => lCharId4
                                                   , oCharactID_5   => lCharId5
                                                    );
        elsif    not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_PIECE')
              or not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SET')
              or not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_VERSION')
              or not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_CHRONOLOGICAL')
              or not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_STD_CHAR_1') then
          -- retrieve from denormalized fields like iARE_PIECE
          GCO_I_LIB_CHARACTERIZATION.ReverseClassify(iGoodId          => lGoodRepairId
                                                   , iOnlyGestStock   => 0
                                                   , iPiece           => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_PIECE')
                                                   , iSet             => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_SET')
                                                   , iVersion         => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_VERSION')
                                                   , iChronological   => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_CHRONOLOGICAL')
                                                   , iCharStd1        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STD_CHAR_1')
                                                   , iCharStd2        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STD_CHAR_2')
                                                   , iCharStd3        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STD_CHAR_3')
                                                   , iCharStd4        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STD_CHAR_4')
                                                   , iCharStd5        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STD_CHAR_5')
                                                   , oCharId1         => lCharId1
                                                   , oCharId2         => lCharId2
                                                   , oCharId3         => lCharId3
                                                   , oCharId4         => lCharId4
                                                   , oCharId5         => lCharId5
                                                   , oCharValue1      => lCharValue1
                                                   , oCharValue2      => lCharValue2
                                                   , oCharValue3      => lCharValue3
                                                   , oCharValue4      => lCharValue4
                                                   , oCharValue5      => lCharValue5
                                                    );
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_CHAR1_VALUE', lCharValue1);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_CHAR2_VALUE', lCharValue2);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_CHAR3_VALUE', lCharValue3);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_CHAR4_VALUE', lCharValue4);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'ARE_CHAR5_VALUE', lCharValue5);
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR1_ID', lCharId1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR2_ID', lCharId2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR3_ID', lCharId3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR4_ID', lCharId4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR5_ID', lCharId5);
      end if;
    end;

    declare
      lExchangeGoodId GCO_GOOD.GCO_GOOD_ID%type                           := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID');
      lCharId1        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_EXCH_CHAR1_ID');
      lCharId2        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId3        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId4        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId5        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    begin
      if     lExchangeGoodId is not null
         and lCharId1 is null
         and not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_EXCH_CHAR1_VALUE') then
        GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => lExchangeGoodId
                                                 , iNoStkChar     => 1
                                                 , oCharactID_1   => lCharId1
                                                 , oCharactID_2   => lCharId2
                                                 , oCharactID_3   => lCharId3
                                                 , oCharactID_4   => lCharId4
                                                 , oCharactID_5   => lCharId5
                                                  );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_EXCH_CHAR1_ID', lCharId1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_EXCH_CHAR2_ID', lCharId2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_EXCH_CHAR3_ID', lCharId3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_EXCH_CHAR4_ID', lCharId4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_EXCH_CHAR5_ID', lCharId5);
      end if;
    end;

    -- Bien de remplacement
    declare
      lNewGoodId GCO_GOOD.GCO_GOOD_ID%type                           := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_NEW_GOOD_ID');
      lCharId1   GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_NEW_CHAR1_ID');
      lCharId2   GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId3   GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId4   GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
      lCharId5   GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    begin
      if     lNewGoodId is not null
         and lCharId1 is null
         and not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_NEW_CHAR1_VALUE') then
        GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => lNewGoodId
                                                 , iNoStkChar     => 1
                                                 , oCharactID_1   => lCharId1
                                                 , oCharactID_2   => lCharId2
                                                 , oCharactID_3   => lCharId3
                                                 , oCharactID_4   => lCharId4
                                                 , oCharactID_5   => lCharId5
                                                  );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_NEW_CHAR1_ID', lCharId1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_NEW_CHAR2_ID', lCharId2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_NEW_CHAR3_ID', lCharId3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_NEW_CHAR4_ID', lCharId4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_NEW_CHAR5_ID', lCharId5);
      end if;
    end;
  end NormalizeRecordClassif;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Initialisation of repairing datas
  */
  procedure InitRecordRepairData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRepairGoodId GCO_GOOD.GCO_GOOD_ID%type                           := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID');
    lCharId1      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId2      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId3      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId4      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId5      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                  , 'STM_REPAIR_MVT_KIND_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('STM_MOVEMENT_KIND', 'MOK_ABBREVIATION', PCS.PC_CONFIG.GetConfig('ASA_INPUT_KIND_MVT') )
                                   );

    if     lRepairGoodId is not null
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_CHAR1_VALUE') then
      GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => lRepairGoodId
                                               , iNoStkChar     => 1
                                               , oCharactID_1   => lCharId1
                                               , oCharactID_2   => lCharId2
                                               , oCharactID_3   => lCharId3
                                               , oCharactID_4   => lCharId4
                                               , oCharactID_5   => lCharId5
                                                );
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR1_ID', lCharId1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR2_ID', lCharId2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR3_ID', lCharId3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR4_ID', lCharId4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotASA_RECORD, 'GCO_CHAR5_ID', lCharId5);
    end if;
  end InitRecordRepairData;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Initialisation of exchange datas
  */
  procedure InitRecordExchData(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lStockId    STM_STOCK.STM_STOCK_ID%type;
    lLocationId STM_LOCATION.STM_LOCATION_ID%type;
    lExchGoodId GCO_GOOD.GCO_GOOD_ID%type                           := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID');
    lCharId1    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId2    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId3    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId4    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharId5    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_EXCH_MVT_KIND_ID') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                    , 'STM_EXCH_MVT_KIND_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2('STM_MOVEMENT_KIND', 'MOK_ABBREVIATION', PCS.PC_CONFIG.GetConfig('ASA_OUTPUT_KIND_MVT') )
                                     );
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then
      -- recherche des id de caracterisation
      GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => lExchGoodId
                                               , iNoStkChar     => 1
                                               , oCharactID_1   => lCharId1
                                               , oCharactID_2   => lCharId2
                                               , oCharactID_3   => lCharId3
                                               , oCharactID_4   => lCharId4
                                               , oCharactID_5   => lCharId5
                                                );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_EXCH_CHAR1_ID', lCharId1);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_EXCH_CHAR2_ID', lCharId2);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_EXCH_CHAR3_ID', lCharId3);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_EXCH_CHAR4_ID', lCharId4);
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_EXCH_CHAR5_ID', lCharId5);

      if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID')
         and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID') then
        select STM_STOCK_ID
             , STM_LOCATION_ID
          into lStockId
             , lLocationId
          from GCO_PRODUCT
         where GCO_GOOD_ID = lExchGoodId;

        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', lStockId);
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', lLocationId);
      end if;
    end if;
  end InitRecordExchData;

  /**
  * Description
  *   Initialisation garanty dates
  */
  procedure InitRecordGarantyInfo(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lStart          date        := FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE');
    lEnd            date        := FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_END_GUARANTY_DATE');
    lOffset         pls_integer := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_GUARANTY');
    lGarantyUnit    varchar2(1) := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT');
    lRepGarantyUnit varchar2(1) := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'C_ASA_REP_GUAR_UNIT');
    lStartRepDate   date        := FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_REP_BEGIN_GUAR_DATE');
    lEndRepDate     date        := FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_REP_END_GUAR_DATE');
    lRepOffset      pls_integer := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_REP_GUAR');
  begin
    if     lStart is not null
       and lEnd is null
       and lGarantyUnit is not null
       and lOffset > 0 then
      if lGarantyUnit = 'D' then   -- unité de garantie en jour
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_END_GUARANTY_DATE', lStart + lOffset);
      elsif lGarantyUnit = 'M' then   -- unité de garantie en mois
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_END_GUARANTY_DATE', add_months(lStart, lOffset) );
      elsif lGarantyUnit = 'Y' then   -- unité de garantie en années
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_END_GUARANTY_DATE', add_months(lStart, lOffset * 12) );
      elsif lGarantyUnit = 'W' then   -- unité de garantie en semaine
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_END_GUARANTY_DATE', lStart + lOffset * 7);
      end if;
    end if;

    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_END_GUARANTY_DATE') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                    , 'ARE_GUARANTY_CODE'
                                    , Bool2Byte(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_END_GUARANTY_DATE') >
                                                                                                 FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'A_DATECRE')
                                               )
                                     );
    end if;

    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_FIN_SALE_DATE')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE', FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_FIN_SALE_DATE') );
    end if;

    if     lStartRepDate is not null
       and lEndRepDate is null
       and lRepGarantyUnit is not null
       and lRepOffset > 0 then
      case
        when lRepGarantyUnit = 'D' then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_REP_END_GUAR_DATE', lStartRepDate + lRepOffset);
        when lRepGarantyUnit = 'M' then   -- unité de garantie en mois
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_REP_END_GUAR_DATE', add_months(lStartRepDate, lRepOffset) );
        when lRepGarantyUnit = 'Y' then   -- unité de garantie en années
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_REP_END_GUAR_DATE', add_months(lStartRepDate, lRepOffset * 12) );
        when lRepGarantyUnit = 'W' then   -- unité de garantie en semaine
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_REP_END_GUAR_DATE', lStartRepDate + lRepOffset * 7);
      end case;
    end if;
  end InitRecordGarantyInfo;

  /**
  * Description
  *   Manage boolean flags
  */
  procedure RecordFlagManagement(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GUARANTY_CODE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_CUSTOMER_ERROR')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_OFFERED_CODE') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                    , 'ARE_GENERATE_BILL'
                                    ,     (   not FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotASA_RECORD, 'ARE_GUARANTY_CODE')
                                           or FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotASA_RECORD, 'ARE_CUSTOMER_ERROR')
                                          )
                                      and not FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotASA_RECORD, 'ARE_OFFERED_CODE')
                                     );
    end if;
  end RecordFlagManagement;

  /**
  * Description
  *   Manage boolean flags
  */
  procedure RecordZipCodeManagement(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- Code inutile, en principe, le nom de la ville doit être donné au système
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PC_ASA_CNTRY1_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_TOWN1') then
      null;
    end if;
  end RecordZipCodeManagement;

  /**
  * Description
  *   Throw an exception if piece management and qty > 1
  */
  procedure CheckRecordRepairQuantity(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- Test if qty not more than 1 for good with piece number management
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
       and GCO_I_LIB_CHARACTERIZATION.IsPieceChar(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') ) = 1 then
      ra(aMessage   => PCS.PC_FUNCTIONS.TranslateWord('La qté à réparer ne peut pas être supérieure à 1, car le bien est géré en numéro de pièce !')
       , aErrNo     => -20900
        );
    end if;
  end CheckRecordRepairQuantity;

  /**
  * Description
  *   Initialisation from ASA_REP_TYPE_GOOD datas
  */
  procedure RecordRepTypeGoodInit(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def, itplRepType ASA_REP_TYPE%rowtype)
  is
    lRepTypeId        ASA_REP_TYPE.ASA_REP_TYPE_ID%type      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_ID');
    lGoodToRepairId   ASA_RECORD.GCO_ASA_TO_REPAIR_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID');
    lGoodToExchangeId ASA_RECORD.GCO_ASA_TO_REPAIR_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID');
    lIsGood           boolean                                := false;
  begin
    for ltplRepGood in (select   A.ASA_REP_TYPE_GOOD_ID
                               , A.ASA_REP_TYPE_ID
                               , A.GCO_GOOD_TO_REPAIR_ID
                               , A.RTG_GARANTEE
                               , A.RTG_GARANTEE_DAYS
                               , A.C_ASA_GUARANTY_UNIT
                               , A.GCO_GOOD_FOR_EXCH_ID
                               , A.STM_ASA_IN_STOCK_ID
                               , A.STM_ASA_OUT_STOCK_ID
                               , A.STM_ASA_IN_LOC_ID
                               , A.STM_ASA_OUT_LOC_ID
                               , nvl(A.RTG_COST_PRICE_W, D.RET_COST_PRICE_W) RTG_COST_PRICE_W
                               , nvl(A.RTG_COST_PRICE_C, D.RET_COST_PRICE_C) RTG_COST_PRICE_C
                               , nvl(A.RTG_COST_PRICE_T, D.RET_COST_PRICE_T) RTG_COST_PRICE_T
                               , nvl(A.RTG_SALE_PRICE_W, D.RET_SALE_PRICE_W) RTG_SALE_PRICE_W
                               , nvl(A.RTG_SALE_PRICE_C, D.RET_SALE_PRICE_C) RTG_SALE_PRICE_C
                               , nvl(A.RTG_SALE_PRICE_T, D.RET_SALE_PRICE_T) RTG_SALE_PRICE_T
                               , nvl(A.RTG_COST_PRICE_S, D.RET_COST_PRICE_S) RTG_COST_PRICE_S
                               , nvl(A.RTG_SALE_PRICE_S, D.RET_SALE_PRICE_S) RTG_SALE_PRICE_S
                               , nvl(A.RTG_NB_DAYS, D.RET_NB_DAYS) RTG_NB_DAYS
                               , nvl(A.RTG_NB_DAYS_WAIT, D.RET_NB_DAYS_WAIT) RTG_NB_DAYS_WAIT
                               , nvl(A.RTG_NB_DAYS_CTRL, D.RET_NB_DAYS_CTRL) RTG_NB_DAYS_CTRL
                               , nvl(A.RTG_NB_DAYS_EXP, D.RET_NB_DAYS_EXP) RTG_NB_DAYS_EXP
                               , nvl(A.RTG_NB_DAYS_SENDING, D.RET_NB_DAYS_SENDING) RTG_NB_DAYS_SENDING
                               , B.STM_STOCK_ID STM_GOOD_STOCK_REP_ID
                               , B.STM_LOCATION_ID STM_GOOD_LOCATION_REP_ID
                               , C.STM_STOCK_ID STM_GOOD_STOCK_EXC_ID
                               , C.STM_LOCATION_ID STM_GOOD_LOCATION_EXC_ID
                            from ASA_REP_TYPE_GOOD A
                               , GCO_PRODUCT B
                               , GCO_PRODUCT C
                               , GCO_GOOD E
                               , ASA_REP_TYPE D
                           where A.ASA_REP_TYPE_ID = lRepTypeId
                             and D.ASA_REP_TYPE_ID = lRepTypeId
                             and E.GCO_GOOD_ID = lGoodToRepairId
                             and E.GCO_GOOD_ID = B.GCO_GOOD_ID(+)
                             and A.GCO_GOOD_FOR_EXCH_ID = C.GCO_GOOD_ID(+)
                             and nvl(A.GCO_GOOD_TO_REPAIR_ID, lGoodToRepairId) = lGoodToRepairId
                        order by A.GCO_GOOD_TO_REPAIR_ID) loop
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ASA_REP_TYPE_GOOD_ID') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ASA_REP_TYPE_GOOD_ID', ltplRepGood.ASA_REP_TYPE_GOOD_ID);
      end if;

      -- initialisation des données bien
      if Byte2Bool(itplRepType.RET_INIT_PRODUCT_DATA) then
        -- stock article défectueux
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID') then
          if ltplRepGood.STM_ASA_IN_STOCK_ID is not null then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID', ltplRepGood.STM_ASA_IN_STOCK_ID);
          else
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
          end if;
        end if;

        -- emplacement de stock article défectueux
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID') then
          if ltplRepGood.STM_ASA_IN_LOC_ID is not null then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID', ltplRepGood.STM_ASA_IN_LOC_ID);
          else
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
          end if;
        end if;

        -- données d'échange
        if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'C_ASA_REP_TYPE_KIND') <> '3' then
          -- article pour échange
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then
            if ltplRepGood.GCO_GOOD_FOR_EXCH_ID is not null then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID', ltplRepGood.GCO_GOOD_FOR_EXCH_ID);
            else
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                            , 'GCO_ASA_EXCHANGE_ID'
                                            , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                             );
            end if;
          end if;

          -------- Stock / location de sortie article pour échange ---------------
          -- stock article pour échange
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID') then
            if ltplRepGood.STM_ASA_OUT_STOCK_ID is not null then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', ltplRepGood.STM_ASA_OUT_STOCK_ID);
            else
              if itplRepType.C_ASA_REP_TYPE_KIND = '1' then   -- échange
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
              else
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', ltplRepGood.STM_GOOD_STOCK_EXC_ID);
              end if;
            end if;
          end if;

          -- emplacement de stock article pour échange
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID') then
            if ltplRepGood.STM_ASA_OUT_LOC_ID is not null then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', ltplRepGood.STM_ASA_OUT_LOC_ID);
            else
              if itplRepType.C_ASA_REP_TYPE_KIND = '1' then   -- échange
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
              else
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_EXC_ID);
              end if;
            end if;
          end if;
        end if;
      end if;

      -- init des données de base
      if Byte2Bool(itplRepType.RET_INIT_BASE_DATA) then
        if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_BEGIN_GUARANTY_DATE')
           and Byte2Bool(nvl(ltplRepGood.RTG_GARANTEE, 0) ) then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GUARANTY', ltplRepGood.RTG_GARANTEE_DAYS);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT', ltplRepGood.C_ASA_GUARANTY_UNIT);
        end if;
      end if;

      -- init des données de prix activé
      if Byte2Bool(itplRepType.RET_INIT_PRICE) then
        -- Prix de revient
        --if     nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_S'),0) = 0
        --   and nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_T'),0) = 0 then
        if itplRepType.C_ASA_REP_TYPE_KIND = '3' then   -- réparation
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_S', nvl(ltplRepGood.RTG_COST_PRICE_S, 0) );
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_W', nvl(ltplRepGood.RTG_COST_PRICE_W, 0) );
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_C', nvl(ltplRepGood.RTG_COST_PRICE_C, 0) );
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_T', nvl(ltplRepGood.RTG_COST_PRICE_T, 0) );
        else
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_S', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_W', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_C', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_T', nvl(ltplRepGood.RTG_COST_PRICE_T, 0) );

          if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then
            if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_T'), 0) = 0 then
              FWK_I_MGT_ENTITY_DATA.setcolumn
                             (iotASA_RECORD
                            , 'ARE_COST_PRICE_T'
                            , GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(iGCO_GOOD_ID    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD
                                                                                                                                    , 'GCO_ASA_EXCHANGE_ID'
                                                                                                                                     )
                                                                           , iPAC_THIRD_ID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD
                                                                                                                                    , 'PAC_CUSTOM_PARTNER_ID'
                                                                                                                                     )
                                                                            )
                             );
            end if;
          end if;
        end if;

        --end if;

        -- Prix de vente
        --if     nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_S'),0) = 0
        --   and nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB'),0) = 0 then
        if itplRepType.C_ASA_REP_TYPE_KIND = '3' then   -- réparation
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_S', nvl(ltplRepGood.RTG_SALE_PRICE_S, 0) );
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_W', nvl(ltplRepGood.RTG_SALE_PRICE_W, 0) );
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_C', nvl(ltplRepGood.RTG_SALE_PRICE_C, 0) );
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', nvl(ltplRepGood.RTG_SALE_PRICE_T, 0) );
        else
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_S', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_W', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_C', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', nvl(ltplRepGood.RTG_SALE_PRICE_T, 0) );
        -- TASA_CalcPrice.InitGoodExchSalePrice -> code déjà affectué auparavant
        end if;
      --end if;
      end if;

      -- Article pour échange
      if     itplRepType.C_ASA_REP_TYPE_KIND in('1', '2')
         and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then   -- échange standard ou produit pour échange est nul
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') );
      end if;

      if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_GUARANTY')
         and PCS.PC_CONFIG.GetConfig('ASA_TARIFF_CODE') = '2'
         and Byte2Bool(itplRepType.RET_INIT_BASE_DATA) then
        for tplComplData in (select   A.CAS_WITH_GUARANTEE
                                    , A.CAS_GUARANTEE_DELAY
                                    , A.C_ASA_GUARANTY_UNIT
                                    , A.DIC_TARIFF_ID
                                 from GCO_COMPL_DATA_ASS A
                                where A.GCO_GOOD_ID = lGoodToRepairId
                                  and (   A.ASA_REP_TYPE_ID = lRepTypeId
                                       or A.ASA_REP_TYPE_ID is null)
                             order by ASA_REP_TYPE_ID) loop
          if FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GUARANTY') then
            -- cas avec garantie, init des info de garantie
            if Byte2Bool(tplComplData.CAS_WITH_GUARANTEE) then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GUARANTY', tplComplData.CAS_GUARANTEE_DELAY);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT', tplComplData.C_ASA_GUARANTY_UNIT);
            end if;

            -- init code tarif
            if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF_ID')
               and PCS.PC_CONFIG.GetConfig('ASA_TARIFF_CODE') = '2' then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TARIFF_ID', tplComplData.DIC_TARIFF_ID);
            end if;

            --init code tarif partenaire uniquement pour les type réparation
            if     PCS.PC_CONFIG.GetConfig('ASA_TARIFF_CODE') = '2'
               and itplRepType.C_ASA_REP_TYPE_KIND = '3'
               and   -- réparation
                   FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF_ID') then
              declare
                lDicTariffId DIC_TARIFF.DIC_TARIFF_ID%type;
                lCustomerId  PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID');
              begin
                select A.DIC_TARIFF_ID
                  into lDicTariffId
                  from PAC_CUSTOM_PARTNER A
                 where A.PAC_CUSTOM_PARTNER_ID = lCustomerId;

                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TARIFF_ID', lDicTariffId);
              exception
                when no_data_found then
                  null;
              end;
            end if;
          end if;

          exit;
        end loop;
      end if;

      -- Si initialisation données bien
      if Byte2Bool(itplRepType.RET_INIT_PRODUCT_DATA) then
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID') then
          for ltplStocks in (select B.STM_STOCK_ID STM_GOOD_STOCK_REP_ID
                                  , B.STM_LOCATION_ID STM_GOOD_LOCATION_REP_ID
                                  , C.STM_STOCK_ID STM_GOOD_STOCK_EXC_ID
                                  , C.STM_LOCATION_ID STM_GOOD_LOCATION_EXC_ID
                               from GCO_PRODUCT B
                                  , GCO_PRODUCT C
                                  , GCO_GOOD D
                              where B.GCO_GOOD_ID = lGoodToRepairId
                                and D.GCO_GOOD_ID = lGoodToExchangeId
                                and D.GCO_GOOD_ID = C.GCO_GOOD_ID(+)) loop
            -- stock article défectueux
            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID') then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
            end if;

            -- emplacement de stock article défectueux
            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID') then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
            end if;

            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID') then
              if itplRepType.C_ASA_REP_TYPE_KIND = '1' then   -- échange
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
              else
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', ltplRepGood.STM_GOOD_STOCK_EXC_ID);
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_EXC_ID);
              end if;
            end if;

            exit;
          end loop;
        end if;
      end if;

      lIsGood  := true;
      exit;   -- un p'tit tour et puis s'en va
    end loop;

    if not lIsGood then
      for ltplRepGood in (select D.ASA_REP_TYPE_ID
                               , C.GCO_GOOD_ID GCO_GOOD_TO_REPAIR_ID
                               , D.RET_COST_PRICE_W RTG_COST_PRICE_W
                               , D.RET_COST_PRICE_C RTG_COST_PRICE_C
                               , D.RET_COST_PRICE_T RTG_COST_PRICE_T
                               , D.RET_SALE_PRICE_W RTG_SALE_PRICE_W
                               , D.RET_SALE_PRICE_C RTG_SALE_PRICE_C
                               , D.RET_SALE_PRICE_T RTG_SALE_PRICE_T
                               , D.RET_COST_PRICE_S RTG_COST_PRICE_S
                               , D.RET_SALE_PRICE_S RTG_SALE_PRICE_S
                               , D.RET_NB_DAYS RTG_NB_DAYS
                               , D.RET_NB_DAYS_WAIT RTG_NB_DAYS_WAIT
                               , D.RET_NB_DAYS_CTRL RTG_NB_DAYS_CTRL
                               , D.RET_NB_DAYS_EXP RTG_NB_DAYS_EXP
                               , D.RET_NB_DAYS_SENDING RTG_NB_DAYS_SENDING
                               , B.STM_STOCK_ID STM_GOOD_STOCK_REP_ID
                               , B.STM_LOCATION_ID STM_GOOD_LOCATION_REP_ID
                            from GCO_PRODUCT B
                               , GCO_GOOD C
                               , ASA_REP_TYPE D
                           where D.ASA_REP_TYPE_ID = lRepTypeId
                             and C.GCO_GOOD_ID = B.GCO_GOOD_ID(+)
                             and C.GCO_GOOD_ID = lGoodToRepairId) loop
--         -- initialisation des données bien
--         if Byte2Bool(itplRepType.RET_INIT_PRODUCT_DATA)then
--           -- stock article défectueux
--           if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD,'STM_ASA_DEFECT_STK_ID') then
--             FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD,'STM_ASA_DEFECT_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
--           end if;
--         end if;
        -- initialisation des données bien
        if Byte2Bool(itplRepType.RET_INIT_PRODUCT_DATA) then
          -- stock article défectueux
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
          end if;

          -- emplacement de stock article défectueux
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
          end if;

          -- article pour échange
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') );
          end if;

          -------- Stock / location de sortie article pour échange ---------------
          -- stock article pour échange
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID') then
            if itplRepType.C_ASA_REP_TYPE_KIND = '1' then   -- échange
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
            end if;
          end if;

          -- emplacement de stock article pour échange
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID') then
            if itplRepType.C_ASA_REP_TYPE_KIND = '1' then   -- échange
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
            end if;
          end if;
        end if;

        -- init des données de base
        -- init des données de prix activé
        if Byte2Bool(itplRepType.RET_INIT_PRICE) then
          -- Prix de revient
          if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_COST_PRICE_S')
             and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_COST_PRICE_T') then
            if itplRepType.C_ASA_REP_TYPE_KIND = '3' then   -- réparation
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_S', nvl(ltplRepGood.RTG_COST_PRICE_S, 0) );
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_W', nvl(ltplRepGood.RTG_COST_PRICE_W, 0) );
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_C', nvl(ltplRepGood.RTG_COST_PRICE_C, 0) );
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_T', nvl(ltplRepGood.RTG_COST_PRICE_T, 0) );
            else
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_S', 0);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_W', 0);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_C', 0);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_T', nvl(ltplRepGood.RTG_COST_PRICE_T, 0) );
            end if;
          end if;

          -- Prix de vente
          if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_S')
             and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB') then
            if itplRepType.C_ASA_REP_TYPE_KIND = '3' then   -- réparation
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_S', nvl(ltplRepGood.RTG_SALE_PRICE_S, 0) );
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_W', nvl(ltplRepGood.RTG_SALE_PRICE_W, 0) );
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_C', nvl(ltplRepGood.RTG_SALE_PRICE_C, 0) );
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', nvl(ltplRepGood.RTG_SALE_PRICE_T, 0) );
            else
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_S', 0);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_W', 0);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_C', 0);
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', nvl(ltplRepGood.RTG_SALE_PRICE_T, 0) );
            -- TASA_CalcPrice.InitGoodExchSalePrice -> code déjà affectué auparavant
            end if;
          end if;
        end if;

        -- Article pour échange
        if     itplRepType.C_ASA_REP_TYPE_KIND in('1', '2')
           and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then   -- échange standard ou produit pour échange est nul
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') );
        end if;

        if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_GUARANTY')
           and PCS.PC_CONFIG.GetConfig('ASA_TARIFF_CODE') = '2'
           and Byte2Bool(itplRepType.RET_INIT_BASE_DATA) then
          for tplComplData in (select   A.CAS_WITH_GUARANTEE
                                      , A.CAS_GUARANTEE_DELAY
                                      , A.C_ASA_GUARANTY_UNIT
                                      , A.DIC_TARIFF_ID
                                   from GCO_COMPL_DATA_ASS A
                                  where A.GCO_GOOD_ID = lGoodToRepairId
                                    and (   A.ASA_REP_TYPE_ID = lRepTypeId
                                         or A.ASA_REP_TYPE_ID is null)
                               order by ASA_REP_TYPE_ID) loop
            if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GUARANTY') then
              -- cas avec garantie, init des info de garantie
              if Byte2Bool(tplComplData.CAS_WITH_GUARANTEE) then
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GUARANTY', tplComplData.CAS_GUARANTEE_DELAY);
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_GUARANTY_UNIT', tplComplData.C_ASA_GUARANTY_UNIT);
              end if;

              -- init code tarif
              if     FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF_ID')
                 and PCS.PC_CONFIG.GetConfig('ASA_TARIFF_CODE') = '2' then
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TARIFF_ID', tplComplData.DIC_TARIFF_ID);
              end if;

              --init code tarif partenaire uniquement pour les type réparation
              if     PCS.PC_CONFIG.GetConfig('ASA_TARIFF_CODE') = '2'
                 and itplRepType.C_ASA_REP_TYPE_KIND = '3'
                 and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF_ID') then
                declare
                  lDicTariffId DIC_TARIFF.DIC_TARIFF_ID%type;
                  lCustomerId  PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID');
                begin
                  select A.DIC_TARIFF_ID
                    into lDicTariffId
                    from PAC_CUSTOM_PARTNER A
                   where A.PAC_CUSTOM_PARTNER_ID = lCustomerId;

                  FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TARIFF_ID', lDicTariffId);
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            end if;

            exit;
          end loop;
        end if;

        -- Si initialisation données bien
        if     Byte2Bool(itplRepType.RET_INIT_PRODUCT_DATA)
           and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID') then
          for ltplStocks in (select B.STM_STOCK_ID STM_GOOD_STOCK_REP_ID
                                  , B.STM_LOCATION_ID STM_GOOD_LOCATION_REP_ID
                                  , C.STM_STOCK_ID STM_GOOD_STOCK_EXC_ID
                                  , C.STM_LOCATION_ID STM_GOOD_LOCATION_EXC_ID
                               from GCO_PRODUCT B
                                  , GCO_PRODUCT C
                                  , GCO_GOOD D
                              where B.GCO_GOOD_ID = lGoodToRepairId
                                and D.GCO_GOOD_ID = lGoodToExchangeId
                                and D.GCO_GOOD_ID = C.GCO_GOOD_ID(+)) loop
            -- stock article défectueux
            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID') then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
            end if;

            -- emplacement de stock article défectueux
            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID') then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_DEFECT_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
            end if;

            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID') then
              if itplRepType.C_ASA_REP_TYPE_KIND = '1' then   -- échange
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_STK_ID', ltplRepGood.STM_GOOD_STOCK_REP_ID);
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'STM_ASA_EXCH_LOC_ID', ltplRepGood.STM_GOOD_LOCATION_REP_ID);
              end if;
            end if;

            exit;
          end loop;
        end if;

        exit;   -- un p'tit tour et puis s'en va
      end loop;
    end if;
  end RecordRepTypeGoodInit;

  /**
  * Description
  *   Initialisation of record status
  */
  procedure InitRecordStatus(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRepTypeId       ASA_REP_TYPE.ASA_REP_TYPE_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_ID');
    lInitStatus      varchar2(10);
    lDefaultStatus   varchar2(2);
    lAsaDefaultGauge varchar2(30)                        := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_GAUGE_NAME');
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ASA_REP_TYPE_ID') then
      lDefaultStatus  := '00';
    else
      lDefaultStatus  := '01';
    end if;

    -- cas d'un bien volé
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ASA_STOLEN_GOODS_ID') then
      if PCS.PC_CONFIG.GetConfig('ASA_REP_STATUS_STOLEN_GOODS') is not null then
        lInitStatus  := PCS.PC_CONFIG.GetConfig('ASA_REP_STATUS_STOLEN_GOODS');
      else
        lInitStatus  := lDefaultStatus;
      end if;
    else
      if PCS.PC_CONFIG.GetConfig('ASA_INIT_STATUS_VALUE') is not null then
        lInitStatus  := PCS.PC_CONFIG.GetConfig('ASA_INIT_STATUS_VALUE');
      else
        lInitStatus  := lDefaultStatus;
      end if;
    end if;

    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_REP_STATUS', lInitStatus);
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD
                                  , 'DOC_GAUGE_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE'
                                                                , 'GAU_DESCRIBE'
                                                                , PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_GAUGE_NAME') || '_' || lInitStatus
                                                                 )
                                   );
  end InitRecordStatus;

  /**
  * Description
  *   Initialisation of goods descrioptions
  */
  procedure InitRecordGoodDataDescr(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- recherche des descriptions du bien à réparer
    declare
      lStockId            number;
      lLocationId         number;
      lReference          GCO_GOOD.GOO_MAJOR_REFERENCE%type;
      lSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
      lShortDescription   GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
      lLongDescription    GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
      lFreeDescription    GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
      lEanCode            GCO_GOOD.GOO_EAN_CODE%type;
      lEanUCC14Code       GCO_GOOD.GOO_EAN_CODE%type;
      lHIBCPrimaryCode    GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
      lDicUnitOfMeasure   varchar2(10);
      lConvertFactor      number;
      lNumberOfDecimal    number;
      lQuantity           number;
    begin
      GCO_I_LIB_COMPL_DATA.GetComplementaryData(iGoodID               => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                              , iAdminDomain          => '7'
                                              , iThirdID              => 0
                                              , iLangID               => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID')
                                              , iOperationID          => 0
                                              , iTransProprietor      => 0
                                              , iComplDataID          => 0
                                              , oStockId              => lStockId
                                              , oLocationId           => lStockId
                                              , oReference            => lReference
                                              , oSecondaryReference   => lSecondaryReference
                                              , oShortDescription     => lShortDescription
                                              , oLongDescription      => lLongDescription
                                              , oFreeDescription      => lFreeDescription
                                              , oEanCode              => lEanCode
                                              , oEanUCC14Code         => lEanUCC14Code
                                              , oHIBCPrimaryCode      => lHIBCPrimaryCode
                                              , oDicUnitOfMeasure     => lDicUnitOfMeasure
                                              , oConvertFactor        => lConvertFactor
                                              , oNumberOfDecimal      => lNumberOfDecimal
                                              , oQuantity             => lQuantity
                                               );

      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GCO_SHORT_DESCR') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GCO_SHORT_DESCR', lShortDescription);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GCO_LONG_DESCR') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GCO_LONG_DESCR', lLongDescription);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GCO_FREE_DESCR') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GCO_FREE_DESCR', lFreeDescription);
      end if;
    end;

    -- recherche des descriptions du bien à réparer
    declare
      lStockId            number;
      lLocationId         number;
      lReference          GCO_GOOD.GOO_MAJOR_REFERENCE%type;
      lSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
      lShortDescription   GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
      lLongDescription    GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
      lFreeDescription    GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
      lEanCode            GCO_GOOD.GOO_EAN_CODE%type;
      lEanUCC14Code       GCO_GOOD.GOO_EAN_CODE%type;
      lHIBCPrimaryCode    GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
      lDicUnitOfMeasure   varchar2(10);
      lConvertFactor      number;
      lNumberOfDecimal    number;
      lQuantity           number;
    begin
      GCO_I_LIB_COMPL_DATA.GetComplementaryData(iGoodID               => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID')
                                              , iAdminDomain          => '7'
                                              , iThirdID              => 0
                                              , iLangID               => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID')
                                              , iOperationID          => 0
                                              , iTransProprietor      => 0
                                              , iComplDataID          => 0
                                              , oStockId              => lStockId
                                              , oLocationId           => lStockId
                                              , oReference            => lReference
                                              , oSecondaryReference   => lSecondaryReference
                                              , oShortDescription     => lShortDescription
                                              , oLongDescription      => lLongDescription
                                              , oFreeDescription      => lFreeDescription
                                              , oEanCode              => lEanCode
                                              , oEanUCC14Code         => lEanUCC14Code
                                              , oHIBCPrimaryCode      => lHIBCPrimaryCode
                                              , oDicUnitOfMeasure     => lDicUnitOfMeasure
                                              , oConvertFactor        => lConvertFactor
                                              , oNumberOfDecimal      => lNumberOfDecimal
                                              , oQuantity             => lQuantity
                                               );

      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GCO_SHORT_DESCR_EX') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GCO_SHORT_DESCR_EX', lShortDescription);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GCO_LONG_DESCR_EX') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GCO_LONG_DESCR_EX', lLongDescription);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_GCO_FREE_DESCR_EX') then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_GCO_FREE_DESCR_EX', lFreeDescription);
      end if;
    end;
  end InitRecordGoodDataDescr;

  /**
  * Description
  *   Initialisation from ASA_REP_TYPE datas
  */
  procedure InitRecordRepType(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRepTypeId       ASA_REP_TYPE.ASA_REP_TYPE_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_ID');
    lInitStatus      varchar2(10);
    lAsaDefaultGauge varchar2(30)                        := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_GAUGE_NAME');
    lRepairGoodId    GCO_GOOD.GCO_GOOD_ID%type           := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID');
  begin
    for ltplRepType in (select *
                          from ASA_REP_TYPE
                         where ASA_REP_TYPE_ID = lRepTypeId) loop
      if ltplRepType.RET_QTY_MGM = 0 then
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_REPAIR_QTY', 1);
      end if;

      -- if flag is on, init basis datas
      if Byte2Bool(ltplRepType.RET_INIT_BASE_DATA) then
        -- Type de réparation : 1=échange standard, 2=échange avec un autre produit, 3=réparation
        FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_REP_TYPE_KIND', ltplRepType.C_ASA_REP_TYPE_KIND);

        -- réparation
        if ltplRepType.C_ASA_REP_TYPE_KIND = '3' then
          if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_USE_COMP') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_USE_COMP', ltplRepType.RET_USE_COMP);
          end if;

          if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_USE_TASK') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_USE_TASK', ltplRepType.RET_USE_TASK);
          end if;

          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_LPOS_COMP_TASK', ltplRepType.RET_LPOS_COMP_TASK);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_RECALC_SALE_PRICE_2', ltplRepType.RET_RECALC_SALE_PRICE_2);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_RECALC_COST_PRICE_2', ltplRepType.RET_RECALC_COST_PRICE_2);
        else
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_USE_COMP', false);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_USE_TASK', false);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_LPOS_COMP_TASK', false);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_RECALC_SALE_PRICE_2', false);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_RECALC_COST_PRICE_2', false);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotASA_RECORD, 'ARE_LPOS_COMP_TASK') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_MB', nvl(ltplRepType.RET_MIN_SALE_PRICE, 0) );
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_MB', nvl(ltplRepType.RET_MAX_SALE_PRICE, 0) );
        else
          FWK_I_MGT_ENTITY_DATA.setcolumnNull(iotASA_RECORD, 'ARE_MIN_SALE_PRICE_MB');
          FWK_I_MGT_ENTITY_DATA.setcolumnNull(iotASA_RECORD, 'ARE_MAX_SALE_PRICE_MB');
        end if;

        if     PCS.PC_CONFIG.GetConfig('ASA_TARIFF_CODE') = '2'
           and FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TARIFF_ID', ltplRepType.DIC_TARIFF_ID);
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF2_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DIC_TARIFF2_ID', ltplRepType.DIC_TARIFF2_ID);
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'C_ASA_SELECT_PRICE') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_SELECT_PRICE', ltplRepType.C_ASA_SELECT_PRICE);
        end if;

        if ltplRepType.C_ASA_REP_TYPE_KIND = '1' then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID', lRepairGoodId);
        end if;

        -- Dossier logistique
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DOC_RECORD_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'DOC_RECORD_ID', ltplRepType.DOC_RECORD_ID);
        end if;

        -- Fournisseur
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'PAC_SUPPLIER_PARTNER_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'PAC_SUPPLIER_PARTNER_ID', ltplRepType.PAC_SUPPLIER_PARTNER_ID);
        end if;

        -- Produit fournisseur
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_SUPPLIER_GOOD_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_SUPPLIER_GOOD_ID', ltplRepType.GCO_SUPPLIER_GOOD_ID);
        end if;

        --Produit utilisé pour la génération des position des documents logistiques
        --si le dossier de réparation crée une position avec le prix de vente total de la réparation
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_BILL_GOOD_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_BILL_GOOD_ID', ltplRepType.GCO_BILL_GOOD_ID);
        end if;

        ------- Donnée relatives à la gestion du devis  --------

        --Code de gestion du devis : 1=devis obligatoire, 2=pas de devis, 3=Devis en fonction d'un montant minimum
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'C_ASA_DEVIS_CODE') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_DEVIS_CODE', ltplRepType.C_ASA_DEVIS_CODE);
        end if;

        --Prix de vente de la réparation minimum pour l'établissement du devis
        --if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_MIN_DEVIS_MB') then
        if ltplRepType.RET_MIN_DEVIS <> 0 then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_MIN_DEVIS_MB', ltplRepType.RET_MIN_DEVIS);
        end if;

        -- Produit utilisé pour la génération des position des documents logistiques
        -- pour la facturation du devis si le devis est refusé
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_DEVIS_BILL_GOOD_ID') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'GCO_DEVIS_BILL_GOOD_ID', ltplRepType.GCO_DEVIS_BILL_GOOD_ID);
        end if;

        -- Prix de vente du devis si le devis est refusé
        if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_PRICE_DEVIS_MB')
           and ltplRepType.RET_PRICE_DEVIS is not null then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_PRICE_DEVIS_MB', ltplRepType.RET_PRICE_DEVIS);
        end if;

        -------- Donnée relatives à la garantie de la réparation  --------}
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_REP_GUAR') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_REP_GUAR', ltplRepType.RET_GUARANTY);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'C_ASA_REP_GUAR_UNIT') then
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'C_ASA_REP_GUAR_UNIT', ltplRepType.C_ASA_GUARANTY_UNIT);
        end if;
      end if;

      -- if flag is on, init prices
      if Byte2Bool(ltplRepType.RET_INIT_PRICE) then
        -- réparation
        if ltplRepType.C_ASA_REP_TYPE_KIND = '3' then
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_COST_PRICE_S') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_S', nvl(ltplRepType.RET_COST_PRICE_S, 0) );
          end if;

          -- Prix de revient du travail
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_COST_PRICE_W') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_W', nvl(ltplRepType.RET_COST_PRICE_W, 0) );
          end if;

          -- Prix de revient fourniture
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_COST_PRICE_C') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_C', nvl(ltplRepType.RET_COST_PRICE_C, 0) );
          end if;

          -- Prix de revient total
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_COST_PRICE_T') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_T', nvl(ltplRepType.RET_COST_PRICE_T, 0) );
          end if;
        else   -- échanges
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_S', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_W', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_C', 0);

          -- Prix de revient total
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_COST_PRICE_T') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_COST_PRICE_T', nvl(ltplRepType.RET_COST_PRICE_T, 0) );
          end if;

          if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_EXCHANGE_ID') then
            if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_T'), 0) = 0 then
              FWK_I_MGT_ENTITY_DATA.setcolumn
                             (iotASA_RECORD
                            , 'ARE_COST_PRICE_T'
                            , GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(iGCO_GOOD_ID    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD
                                                                                                                                    , 'GCO_ASA_EXCHANGE_ID'
                                                                                                                                     )
                                                                           , iPAC_THIRD_ID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD
                                                                                                                                    , 'PAC_CUSTOM_PARTNER_ID'
                                                                                                                                     )
                                                                            )
                             );
            end if;
          end if;
        end if;

        -- réparation
        if ltplRepType.C_ASA_REP_TYPE_KIND = '3' then
          -- Prix de vente de la prestation externe
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_S') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_S', nvl(ltplRepType.RET_SALE_PRICE_S, 0) );
          end if;

          -- Prix de vente du travail
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_W') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_W', nvl(ltplRepType.RET_SALE_PRICE_W, 0) );
          end if;

          -- Prix de vente fourniture
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_C') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_C', nvl(ltplRepType.RET_SALE_PRICE_C, 0) );
          end if;

          -- Prix de vente total de la réparation
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB') then
            FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', nvl(ltplRepType.RET_SALE_PRICE_T, 0) );
          end if;
        -- échanges
        else
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_S', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_w', 0);
          FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_c', 0);

          if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'DIC_TARIFF_ID') then
            --Recalcul des prix de l'échange en fonction du code tarif
            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME') then
              declare
                lPrice number
                  := GCO_I_LIB_PRICE.GetGoodPriceForView(iGoodId              => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID')
                                                       , iTypePrice           => '2'   -- tariff d'achat
                                                       , iThirdId             => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PAC_CUSTOM_PARTNER_ID')
                                                       , iRecordId            => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'DOC_RECORD_ID')
                                                       , iFalScheduleStepId   => null
                                                       , ilDicTariff          => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'DIC_TARIFF_ID')
                                                       , iQuantity            => 1
                                                       , iDateRef             => FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotASA_RECORD, 'ARE_DATEREF')
                                                       , ioCurrencyId         => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD
                                                                                                                     , 'ACS_FINANCIAL_CURRENCY_ID'
                                                                                                                      )
                                                        );
              begin
                FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_ME', lPrice);
              end;
            end if;
          else
            -- Prix de vente total de la réparation
            if FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB') then
              FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_SALE_PRICE_T_MB', nvl(ltplRepType.RET_SALE_PRICE_T, 0) );
            end if;
          end if;
        end if;
      end if;

      -- if flag is on, init good datas
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotASA_RECORD, 'GCO_ASA_TO_REPAIR_ID') then
        RecordRepTypeGoodInit(iotASA_RECORD, ltplRepType);
      end if;
    end loop;

    InitRecordGoodDataDescr(iotASA_RECORD);
  end InitRecordRepType;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Initialisation du flux du dossier
  */
  procedure InitRecordFlow(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lEventSeq ASA_RECORD_EVENTS.RRE_SEQ%type;
  begin
    -- création du premier événement
    ASA_PRC_RECORD_EVENTS.CreateRecordEvents(iAsaRecordId   => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ASA_RECORD_ID')
                                           , iNewStatus     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'C_ASA_REP_STATUS')
                                           , oEventsSeq     => lEventSeq
                                            );
  end InitRecordFlow;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Initialisation des descriptions du dossier
  */
  procedure InitRecordDescriptions(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRepTypeId ASA_REP_TYPE.ASA_REP_TYPE_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_ID');
    lRecordId  ASA_RECORD.ASA_RECORD_ID%type       := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID');
  begin
    for ltplDescription in (select *
                              from ASA_REP_TYPE_DESCR
                             where ASA_REP_TYPE_ID = lRepTypeId) loop
      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecordDescr, ltCRUD_DEF, true);
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ASA_RECORD_ID', lRecordId);
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'C_ASA_DESCRIPTION_TYPE', ltplDescription.C_ASA_DESCRIPTION_TYPE);
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'PC_LANG_ID', ltplDescription.PC_LANG_ID);
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARD_SHORT_DESCRIPTION', ltplDescription.DTR_SHORT_DESCRIPTION);
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARD_LONG_DESCRIPTION', ltplDescription.DTR_LONG_DESCRIPTION);
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARD_FREE_DESCRIPTION', ltplDescription.DTR_FREE_DESCRIPTION);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;
    end loop;
  end InitRecordDescriptions;

  /**
  * procedure InitRecordFreeDatas
  * Description
  *   Methode de surcharge du framework
  *   Initialisation des codes/données libres du dossier
  */
  procedure InitRecordFreeDatas(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRepTypeID ASA_REP_TYPE.ASA_REP_TYPE_ID%type;
    lRecordID  ASA_RECORD.ASA_RECORD_ID%type;
    lnCount    integer;
    ltFreeCode FWK_I_TYP_DEFINITION.t_crud_def;
    ltFreeData FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lRepTypeID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_ID');

    if lRepTypeID is not null then
      lRecordID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID');

      -- Vérifier si l'enregistrement ASA_FREE_CODE a déjà été crée pour le dossier SAV
      select count(*)
        into lnCount
        from ASA_FREE_CODE
       where ASA_RECORD_ID = lRecordID;

      if lnCount = 0 then
        -- Copie de l'enregistrement ASA_FREE_CODE du type de réparation (si existant)
        for ltplFreeCode in (select ASA_FREE_CODE_ID
                               from ASA_FREE_CODE
                              where ASA_REP_TYPE_ID = lRepTypeID) loop
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaFreeCode, ltFreeCode);
          FWK_I_MGT_ENTITY.PrepareDuplicate(ltFreeCode, true, ltplFreeCode.ASA_FREE_CODE_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeCode, 'ASA_RECORD_ID', lRecordID);
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltFreeCode, 'ASA_REP_TYPE_ID');
          FWK_I_MGT_ENTITY.InsertEntity(ltFreeCode);
          FWK_I_MGT_ENTITY.Release(ltFreeCode);
        end loop;
      end if;

      -- Vérifier si un ou plusieurs enregistrements ASA_FREE_DATA ont déjà été créés pour le dossier SAV
      select count(*)
        into lnCount
        from ASA_FREE_DATA
       where ASA_RECORD_ID = lRecordID;

      if lnCount = 0 then
        -- Copie de l'enregistrement ASA_FREE_DATA du type de réparation (si existant)
        for ltplFreeData in (select ASA_FREE_DATA_ID
                               from ASA_FREE_DATA
                              where ASA_REP_TYPE_ID = lRepTypeID) loop
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaFreeData, ltFreeData);
          FWK_I_MGT_ENTITY.PrepareDuplicate(ltFreeData, true, ltplFreeData.ASA_FREE_DATA_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'ASA_RECORD_ID', lRecordID);
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltFreeData, 'ASA_REP_TYPE_ID');
          FWK_I_MGT_ENTITY.InsertEntity(ltFreeData);
          FWK_I_MGT_ENTITY.Release(ltFreeData);
        end loop;
      end if;
    end if;
  end InitRecordFreeDatas;

  /**
   * Description
   *   Mise à jour du prix total des composants
   */
  procedure UpdateRecordCompPrice(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltCRUD_DEF      fwk_i_typ_definition.t_crud_def;
    lAsaRecordId    ASA_RECORD.ASA_RECORD_ID%type      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID');
    lTotalSalePrice ASA_RECORD.ARE_COST_PRICE_C%type;
    lTotalCostPrice ASA_RECORD.ARE_COST_PRICE_C%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'C_ASA_REP_TYPE_KIND') = '3' then
      ASA_LIB_RECORD.GetTotalCompPrice(iRecordID => lAsaRecordId, ioTotalSalePrice => lTotalSalePrice, ioTotalCostPrice => lTotalCostPrice);
      FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_ID', lAsaRecordId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COST_PRICE_C', lTotalCostPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                    , 'ARE_COST_PRICE_T'
                                    , nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_W'), 0) +
                                      nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ARE_COST_PRICE_S'), 0) +
                                      lTotalCostPrice
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_PRICE_C', lTotalSalePrice);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end if;
  end UpdateRecordCompPrice;

  /**
   * Description
   *   Mise à jour du dernier événement
   */
  procedure UpdateLastEventId(iRecordId in ASA_RECORD.ASA_RECORD_ID%type, iLastEventId in ASA_RECORD.ASA_RECORD_EVENTS_ID%type)
  is
    ltCRUD_DEF fwk_i_typ_definition.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_ID', iRecordId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_EVENTS_ID', iLastEventId);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateLastEventId;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Initialisation des composants du dossier
  */
  procedure InitRecordComp(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRepTypeGoodId ASA_REP_TYPE_GOOD.ASA_REP_TYPE_GOOD_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_GOOD_ID');
    lRecordId      ASA_RECORD.ASA_RECORD_ID%type                 := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID');
  begin
    if     lRepTypeGoodId is not null
       and FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotASA_RECORD, 'ARE_USE_COMP') then
      for ltplComponent in (select   *
                                from ASA_REP_TYPE_COMP
                               where nvl(ASA_REP_TYPE_GOOD_ID, -1) = nvl(lRepTypeGoodId, -1)
                            order by RTC_POSITION) loop
        declare
          ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
        begin
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecordComp, ltCRUD_DEF, true);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ASA_RECORD_ID', lRecordId);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_OPTIONAL', ltplComponent.RTC_OPTIONAL);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'C_ASA_GEN_DOC_POS', ltplComponent.C_ASA_GEN_DOC_POS);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_CDMVT', ltplComponent.RTC_CDMVT);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_POSITION', ltplComponent.RTC_POSITION);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'STM_COMP_MVT_KIND_ID', ltplComponent.STM_COMP_MVT_KIND_ID);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'GCO_COMPONENT_ID', ltplComponent.GCO_COMPONENT_ID);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_QUANTITY', ltplComponent.RTC_QUANTITY);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_DESCR', ltplComponent.RTC_DESCR, true, FWK_I_TYP_DEFINITION.gcv_SCOPE_DEFAULT);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_DESCR2', ltplComponent.RTC_DESCR2, true, FWK_I_TYP_DEFINITION.gcv_SCOPE_DEFAULT);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_DESCR3', ltplComponent.RTC_DESCR3, true, FWK_I_TYP_DEFINITION.gcv_SCOPE_DEFAULT);
          --FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_COST_PRICE', ltplComponent.XXX);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_NUM1', ltplComponent.RTC_FREE_NUM1);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_NUM2', ltplComponent.RTC_FREE_NUM2);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_NUM3', ltplComponent.RTC_FREE_NUM3);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_NUM4', ltplComponent.RTC_FREE_NUM4);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_NUM5', ltplComponent.RTC_FREE_NUM5);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_CHAR1', ltplComponent.RTC_FREE_CHAR1);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_CHAR2', ltplComponent.RTC_FREE_CHAR2);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_CHAR3', ltplComponent.RTC_FREE_CHAR3);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_CHAR4', ltplComponent.RTC_FREE_CHAR4);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ARC_FREE_CHAR5', ltplComponent.RTC_FREE_CHAR5);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'DIC_ASA_FREE_DICO_COMP1_ID', ltplComponent.DIC_ASA_FREE_DICO_COMP1_ID);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'DIC_ASA_FREE_DICO_COMP2_ID', ltplComponent.DIC_ASA_FREE_DICO_COMP2_ID);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'STM_COMP_LOCATION_ID', ltplComponent.STM_LOCATION_ID, true, FWK_I_TYP_DEFINITION.gcv_SCOPE_DEFAULT);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'STM_COMP_STOCK_ID', ltplComponent.STM_STOCK_ID, true, FWK_I_TYP_DEFINITION.gcv_SCOPE_DEFAULT);
          FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        end;
      end loop;

      -- Maj du total des prix des composants sur ASA_RECORD
      UpdateRecordCompPrice(iotASA_RECORD);
    end if;
  end InitRecordComp;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Initialisation des tâches du dossier
  */
  procedure InitRecordTask(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lRepTypeGoodId ASA_REP_TYPE_GOOD.ASA_REP_TYPE_GOOD_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_REP_TYPE_GOOD_ID');
    lRecordId      ASA_RECORD.ASA_RECORD_ID%type                 := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'ASA_RECORD_ID');
  begin
    if     lRepTypeGoodId is not null
       and FWK_I_MGT_ENTITY_DATA.GetColumnBoolean(iotASA_RECORD, 'ARE_USE_TASK') then
      for ltplTask in (select   *
                           from ASA_REP_TYPE_TASK
                          where nvl(ASA_REP_TYPE_GOOD_ID, -1) = nvl(lRepTypeGoodId, -1)
                       order by RTT_POSITION) loop
        declare
          ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
        begin
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecordTask, ltCRUD_DEF, true);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'ASA_RECORD_ID', lRecordId);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'C_ASA_GEN_DOC_POS', ltplTask.C_ASA_GEN_DOC_POS);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_EXTERNAL', ltplTask.RTT_EXTERNAL);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_POSITION', ltplTask.RTT_POSITION);
          -- Si le produit pour facturation n'est pas défini, on en affecte un
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'FAL_TASK_ID', ltplTask.FAL_TASK_ID, true, FWK_I_TYP_DEFINITION.gcv_SCOPE_DEFAULT);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_TIME', ltplTask.RTT_TIME);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_WORK_RATE', ltplTask.RTT_WORK_RATE);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_DESCR', ltplTask.RTT_DESCR);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_DESCR2', ltplTask.RTT_DESCR2);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_DESCR3', ltplTask.RTT_DESCR3);

          if     ltplTask.GCO_BILL_GOOD_ID is null
             and PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_TASK_BILL_GOOD') is not null then
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                          , 'GCO_BILL_GOOD_ID'
                                          , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD'
                                                                        , 'GOO_MAJOR_REFERENCE'
                                                                        , PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_TASK_BILL_GOOD')
                                                                         )
                                           );
          else
            FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'GCO_BILL_GOOD_ID', ltplTask.GCO_BILL_GOOD_ID, true, FWK_I_TYP_DEFINITION.gcv_SCOPE_DEFAULT);
          end if;

          declare
            lShortDescr GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
            lLongDescr  GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
            lFreeDescr  GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
          begin
            -- Recherche les descriptions du bien
            ASA_I_LIB_RECORD.GetGoodDescr(iGoodID       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'GCO_BILL_GOOD_ID')
                                        , iLangID       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_CUST_LANG_ID')
                                        , oShortDescr   => lShortDescr
                                        , oLongDescr    => lLongDescr
                                        , oFreeDescr    => lFreeDescr
                                         );

            -- Descriptions courte, longue et libre
            if lShortDescr is not null then
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'RET_DESCR', lShortDescr);
            end if;

            if lLongDescr is not null then
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'RET_DESCR2', lLongDescr);
            end if;

            if lFreeDescr is not null then
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'RET_DESCR3', lFreeDescr);
            end if;
          end;

          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_NUM1', ltplTask.RTT_FREE_NUM1);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_NUM2', ltplTask.RTT_FREE_NUM2);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_NUM3', ltplTask.RTT_FREE_NUM3);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_NUM4', ltplTask.RTT_FREE_NUM4);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_NUM5', ltplTask.RTT_FREE_NUM5);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_CHAR1', ltplTask.RTT_FREE_CHAR1);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_CHAR2', ltplTask.RTT_FREE_CHAR2);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_CHAR3', ltplTask.RTT_FREE_CHAR3);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_CHAR4', ltplTask.RTT_FREE_CHAR4);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'RET_FREE_CHAR5', ltplTask.RTT_FREE_CHAR5);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'DIC_ASA_FREE_DICO_TASK1_ID', ltplTask.DIC_ASA_FREE_DICO_TASK1_ID);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'DIC_ASA_FREE_DICO_TASK2_ID', ltplTask.DIC_ASA_FREE_DICO_TASK2_ID);
          FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        end;
      end loop;
    end if;
  end InitRecordTask;

  /**
  * procedure FormatRecordAddresses
  * Description
  *   Methode de surcharge du framework
  *   Màj des champs formatés des adresses du dossier SAV
  * @created NGV NOV 2011
  * @lastUpdate
  * @private
  * @param
  */
  procedure FormatRecordAddresses(iotASA_RECORD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lvFormattedAddress PAC_ADDRESS.ADD_FORMAT%type;
  begin
    -- Formatage des adresses
    -- ARE_FORMAT_CITY1
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_POSTCODE1')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_TOWN1')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_STATE1')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PC_ASA_CNTRY1_ID') then
      lvFormattedAddress  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_POSTCODE1')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_TOWN1')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STATE1')
                                              , pAddCounty      => ''
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_CNTRY1_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_FORMAT_CITY1', lvFormattedAddress);
    end if;

    -- ARE_FORMAT_CITY2
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_POSTCODE2')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_TOWN2')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_STATE2')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PC_ASA_CNTRY2_ID') then
      lvFormattedAddress  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_POSTCODE2')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_TOWN2')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STATE2')
                                              , pAddCounty      => ''
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_CNTRY2_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_FORMAT_CITY2', lvFormattedAddress);
    end if;

    -- ARE_FORMAT_CITY3
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_POSTCODE3')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_TOWN3')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_STATE3')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PC_ASA_CNTRY3_ID') then
      lvFormattedAddress  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_POSTCODE3')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_TOWN3')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STATE3')
                                              , pAddCounty      => ''
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_CNTRY3_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_FORMAT_CITY3', lvFormattedAddress);
    end if;

    -- ARE_FORMAT_CITY_FIN_CUST
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_POSTCODE_FIN_CUST')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_TOWN_FIN_CUST')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_STATE_FIN_CUST')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PC_ASA_FIN_CUST_CNTRY_ID') then
      lvFormattedAddress  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_POSTCODE_FIN_CUST')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_TOWN_FIN_CUST')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STATE_FIN_CUST')
                                              , pAddCounty      => ''
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_FIN_CUST_CNTRY_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_FORMAT_CITY_FIN_CUST', lvFormattedAddress);
    end if;

    -- ARE_FORMAT_CITY_SUPPLIER
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_POSTCODE_SUPPLIER')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_TOWN_SUPPLIER')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'ARE_STATE_SUPPLIER')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotASA_RECORD, 'PC_ASA_SUPPLIER_CNTRY_ID') then
      lvFormattedAddress  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_POSTCODE_SUPPLIER')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_TOWN_SUPPLIER')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotASA_RECORD, 'ARE_STATE_SUPPLIER')
                                              , pAddCounty      => ''
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotASA_RECORD, 'PC_ASA_SUPPLIER_CNTRY_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotASA_RECORD, 'ARE_FORMAT_CITY_SUPPLIER', lvFormattedAddress);
    end if;
  end FormatRecordAddresses;
end ASA_PRC_RECORD;
