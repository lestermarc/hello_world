--------------------------------------------------------
--  DDL for Package Body ASA_MGT_RECORD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_MGT_RECORD" 
is
  /**
  * Description
  *    Code m�tier de l'insertion d'un dossier SAV
  */
  function insertRECORD(iotRecord in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des donn�es selon la carte de garantie
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'ASA_GUARANTY_CARDS_ID') then
      ASA_PRC_RECORD.InitRecordGuarantyCardData(iotRecord);
    -- Init des donn�es selon le n� de s�rie du produit � r�parer
    elsif     not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'ARE_PIECE')
          and not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'GCO_ASA_TO_REPAIR_ID') then
      -- Init des donn�es
      ASA_PRC_RECORD.InitRecordFromPieceNumber(iotRecord);

      -- Si l'init du n� s�rie a r�cup�r� une carte de garantie, effectuer l'init selon la carte de garantie
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'ASA_GUARANTY_CARDS_ID') then
        ASA_PRC_RECORD.InitRecordGuarantyCardData(iotRecord);
      end if;
    end if;

    -- Initialization from source logistic document datas
    if    not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'DOC_ORIGIN_POSITION_DETAIL_ID')
       or not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'DOC_ORIGIN_POSITION_ID') then
      ASA_PRC_RECORD.InitRecordFromPositionDetail(iotRecord);
    end if;

    -- Initialization from stolen good datas
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'ASA_STOLEN_GOODS_ID') then
      ASA_PRC_RECORD.InitRecordFromStolenGood(iotRecord);
    end if;

    -- Initialization from source record datas
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'ASA_LAST_RECORD_ID') then
      ASA_PRC_RECORD.InitRecordFromSourceRecord(iotRecord);
    end if;

    -- Initialization from reparation type
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'ASA_REP_TYPE_ID') then
      ASA_PRC_RECORD.InitRecordRepType(iotRecord);
    end if;

    -- Initialisation du status de d�part
    ASA_PRC_RECORD.InitRecordStatus(iotRecord);
    -- Initialisation des donn�es g�n�riques d'ent�te
    ASA_PRC_RECORD.InitRecordHeaderData(iotRecord);
    -- Initialisation des donn�es client
    ASA_PRC_RECORD.InitRecordCustomerData(iotRecord);
    -- Initialisation du taux de change
    ASA_PRC_RECORD.InitRecordExchangeRate(iotRecord);
    -- Initialisation des donn�es de garantie
    ASA_PRC_RECORD.InitRecordGarantyInfo(iotRecord);
    -- Initialisation des donn�es de devis
    ASA_PRC_RECORD.InitRecordDevisData(iotRecord);
    -- Initialisation des donn�es de r�paration
    ASA_PRC_RECORD.InitRecordRepairData(iotRecord);
    -- Initialisation des donn�es d'�change
    ASA_PRC_RECORD.InitRecordExchData(iotRecord);
    -- Initialisation des donn�es li�es au dissier logistique
    ASA_PRC_RECORD.InitRecordDocRecordData(iotRecord);
    -- Normalisation des caracte�risations
    ASA_PRC_RECORD.NormalizeRecordClassif(iotRecord);
    -- Calcul des prix
    ASA_PRC_RECORD.CalcRecordPrices(iotRecord);
    -- Maj des flag d'�tat
    ASA_PRC_RECORD.RecordFlagManagement(iotRecord);
    -- Conversion des prix "monnnaie de base"-"monnaie dossier"
    ASA_PRC_RECORD.ConvertRecordPrices(iotRecord);
    -- Formatage des adresses
    ASA_PRC_RECORD.FormatRecordAddresses(iotRecord);
    -- Gestion du statut
    ASA_PRC_RECORD.ManageStatus(iotRecord);
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iotRecord);
    -- initialisation du flux
    ASA_PRC_RECORD.InitRecordFlow(iotRecord);
    -- initialisation des composants du dossier
    ASA_PRC_RECORD.InitRecordComp(iotRecord);
    -- initialisation des t�ches du dossier
    ASA_PRC_RECORD.InitRecordTask(iotRecord);
    -- initialisation des descriptions du dossier
    ASA_PRC_RECORD.InitRecordDescriptions(iotRecord);
    -- initialisation des donn�es libres et des codes libres du dossier
    ASA_PRC_RECORD.InitRecordFreeDatas(iotRecord);
    -- Mise � jour des documents d'attribution associ�s au dossier SAV
    ASA_RECORD_GENERATE_DOC.UpdateAttrib(aRecordID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecord, 'ASA_RECORD_ID') );
    -- procedures externes de validation (dans le cas de la cr�ation, on execute tout � la suite)
    ASA_PRC_RECORD.ExecExternProc(iotRecord, 'BeforeValidate');
    ASA_PRC_RECORD.ExecExternProc(iotRecord, 'AfterValidate');
    -- retourne le rowid de l'enregistrement cr�� (obligatoire)
    return lResult;
  end insertRECORD;

  /**
  * function updateRECORD
  * Description
  *    Code m�tier de la modification d'un dossier SAV
  */
  function updateRECORD(iotRecord in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult          varchar2(40);
    lAsaRecordID     ASA_RECORD.ASA_RECORD_ID%type;
    lNewEventID      ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type;
    lOldEventID      ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type;
    lbStatusModified boolean;
    lMvtErrMess      varchar2(32767);
  begin
    -- Initialisation des donn�es d'�change (teste si qqch � chang�)
    ASA_PRC_RECORD.InitRecordExchData(iotRecord);
    -- Formatage des adresses
    ASA_PRC_RECORD.FormatRecordAddresses(iotRecord);

    -- Modif du lien de l'�tape de flux du dossier SAV
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecord, 'ASA_RECORD_EVENTS_ID') then
      lAsaRecordID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecord, 'ASA_RECORD_ID');
      lNewEventID   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecord, 'ASA_RECORD_EVENTS_ID');

      -- Rechercher la valeur actuellement du lien de l'�tape de flux
      select max(ASA_RECORD_EVENTS_ID)
        into lOldEventID
        from ASA_RECORD
       where ASA_RECORD_ID = lAsaRecordID;

      -- M�j du lien de l'�tape du flux sur les op�rations
      ASA_PRC_RECORD_TASK.UpdateRecordEvent(iAsaRecordID => lAsaRecordID, iNewEventID => lNewEventID, iOldEventID => lOldEventID);
      -- M�j du lien de l'�tape du flux sur les composants
      ASA_PRC_RECORD_COMP.UpdateRecordEvent(iAsaRecordID => lAsaRecordID, iNewEventID => lNewEventID, iOldEventID => lOldEventID);
    end if;

    -- Bool�en indiquant si le statut du dossier SAV a �t� modifi�
    lbStatusModified  := FWK_I_MGT_ENTITY_DATA.IsModified(iotRecord, 'C_ASA_REP_STATUS');

    -- Modif du statut du dossier SAV
    if lbStatusModified then
      ASA_I_PRC_RECORD.ManageStatus(iotAsaRecord => iotRecord);
    end if;

    -- Execution of CRUD instruction
    lResult           := FWK_I_DML_TABLE.CRUD(iotRecord);

    -- Appel de la proc�dure de transfert de dossier (si changement de statut)
    if     lbStatusModified
       and (upper(pcs.pc_config.GetConfig('ASA_RECORD_TRANSFERT') ) = 'TRUE') then
      ASA_PRC_RECORD_TRF.MessageTransfertFlow(lAsaRecordID, lMvtErrMess);
    end if;

    -- Cr�ation (si n�cessaire) d'un historique de modif des d�lais
    ASA_I_PRC_RECORD_DELAY.CreateDelayHistory(iAsaRecordID => lAsaRecordID);
    return lResult;
  end updateRECORD;

  /**
  * function deleteRECORD
  * Description
  * Code m�tier de l'effacement d'un dossier SAV
  * @created AGA
  * @lastUpdate
  * @public
  * @param iotRecord : ASA_RECORD de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteRECORD(iotRecord in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lnError integer;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecord, 'ASA_RECORD_ID') then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Donn�es manquantes') || ' : ASA_RECORD_ID !'
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DeleteRECORD'
                                         );
    end if;

    -- Suppression du lien composant / position de document
    ASA_I_PRC_RECORD.ExecExternProc(iotRecord, 'BeforeDelete');
    ASA_I_PRC_RECORD.CheckRecordBeforeDelete(iotRecord);
    lResult  := FWK_I_DML_TABLE.CRUD(iotRecord);
    ASA_I_PRC_RECORD.ExecExternProc(iotRecord, 'AfterDelete');
    return null;
  end deleteRECORD;

  /**
  * function insertDELAY_HISTORY
  * Description
  *    Code m�tier de l'insertion d'un historique des d�lais d'un dossier SAV
  */
  function insertDELAY_HISTORY(iotDelayHistory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des donn�es du tuple � ins�rer avec les valeurs d�finies sur
    -- le dossier SAV
    ASA_I_PRC_RECORD_DELAY.InitDelayHistory(iotDelayHistory);
    lResult  := FWK_I_DML_TABLE.CRUD(iotDelayHistory);
    return lResult;
  end insertDELAY_HISTORY;

  /**
  * function insertRECORD_TASK
  * Description
  *    Code m�tier de l'insertion d'une op�ration d'un dossier SAV
  */
  function insertRECORD_TASK(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- V�rifier que l'id du dossier SAV soit d�fini
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'ASA_RECORD_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Donn�es manquantes') || ' : ASA_RECORD_ID !'
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'insertRECORD_TASK'
                                         );
    end if;

    -- Init des donn�es de l'op�ration
    ASA_I_PRC_RECORD_TASK.InitializeData(iotRecordTask);
    -- Init des donn�es relatives � l'op�ration de fabrication
    ASA_I_PRC_RECORD_TASK.InitFalTaskData(iotRecordTask);
    -- Init des donn�es relatives au produit pour la facturation
    ASA_I_PRC_RECORD_TASK.InitBillGoodData(iotRecordTask);
    -- Recalcul des divers montants
    ASA_I_PRC_RECORD_TASK.CalcAmounts(iotRecordTask);
    -- Init du temps effectif
    ASA_I_PRC_RECORD_TASK.InitTime(iotRecordTask);

    -- V�rifier qu'au moins un de ces 2 champs soit renseign�
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'FAL_TASK_ID')
       and FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'GCO_BILL_GOOD_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Donn�es manquantes') || ' : FAL_TASK_ID, GCO_BILL_GOOD_ID !'
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'insertRECORD_TASK'
                                         );
    end if;

    lResult  := FWK_I_DML_TABLE.CRUD(iotRecordTask);
    return lResult;
  end insertRECORD_TASK;

  /**
  * function updateRECORD_TASK
  * Description
  *    Code m�tier de la modificationd'une op�ration d'un dossier SAV
  */
  function updateRECORD_TASK(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des donn�es relatives � l'op�ration de fabrication
    ASA_I_PRC_RECORD_TASK.InitFalTaskData(iotRecordTask);
    -- Init des donn�es relatives au produit pour la facturation
    ASA_I_PRC_RECORD_TASK.InitBillGoodData(iotRecordTask);
    -- Recalcul des divers montants
    ASA_I_PRC_RECORD_TASK.CalcAmounts(iotRecordTask);
    -- Init du temps effectif
    ASA_I_PRC_RECORD_TASK.InitTime(iotRecordTask);

    -- V�rifier qu'au moins un de ces 2 champs soit renseign�
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'FAL_TASK_ID')
       and FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'GCO_BILL_GOOD_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Donn�es manquantes') || ' : FAL_TASK_ID, GCO_BILL_GOOD_ID !'
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'updateRECORD_TASK'
                                         );
    end if;

    lResult  := FWK_I_DML_TABLE.CRUD(iotRecordTask);
    return lResult;
  end updateRECORD_TASK;

  /**
  * function deleteRECORD_TASK
  * Description
  *    Code m�tier de l'effacement d'une op�ration d'un dossier SAV
  */
  function deleteRECORD_TASK(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- V�rifier si l'op�ration est li�e � un ordre de fabrication
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'FAL_LOT_PROGRESS_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Effacement interdit !') ||
                                                              chr(10) ||
                                                              PCS.PC_FUNCTIONS.TranslateWord
                                                                                           ('Le champ "Avancement lot" (FAL_LOT_PROGRESS_ID) est renseign� !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'deleteRECORD_TASK'
                                         );
    end if;

    -- V�rifier si le dossier SAV n'est pas prot�g�
    if ASA_I_LIB_RECORD.IsRecordProtected(FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).ASA_RECORD_ID) then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Effacement interdit !') ||
                                                              chr(10) ||
                                                              PCS.PC_FUNCTIONS.TranslateWord('Ce dossier est prot�g� !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'deleteRECORD_TASK'
                                         );
    end if;

    lResult  := FWK_I_DML_TABLE.CRUD(iotRecordTask);
    -- Effacer le lien de l'op�ration SAV sur les positions de document
    ASA_I_PRC_RECORD_TASK.ClearPositionTaskLink(FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).ASA_RECORD_TASK_ID);
    return null;
  end deleteRECORD_TASK;

  /**
  * Description
  *    Insert of ASA_RECORD_COMP
  */
  function insertRECORD_COMP(iotRecordComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lnError integer;
    lcError varchar2(100);
  begin
    -- V�rifier que l'id du dossier SAV soit d�fini
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ASA_RECORD_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Donn�es manquantes') || ' : ASA_RECORD_ID !'
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'insertRECORD_COMP'
                                         );
    end if;

    -- Traitement des donn�es du composant
    ASA_I_PRC_RECORD_COMP.ManageData(iotRecordComp);
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iotRecordComp);

    --Check ID
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ASA_RECORD_COMP_ID') then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := 'Cannot create record ASA_RECORD_COMP';
      RA(aMessage => lcError, aErrNo => lnError);
    end if;

    return lResult;
  end insertRECORD_COMP;

  /**
  * Update of ASA_RECORD_COMP
  */
  function updateRECORD_COMP(iotRecordComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- V�rifier que l'id du dossier SAV soit d�fini
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ASA_RECORD_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Donn�es manquantes') || ' : ASA_RECORD_ID !'
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'updateRECORD_COMP'
                                         );
    end if;

    -- Les composants d'ordre de fabrication ne peuvent �tre modifi�s.
    --
    -- TODO revoir le principe, car c'est en principe la modification utilisateur qui est interdite dans le cas ou le dossier est prot�g�
    --
    --if ASA_LIB_RECORD.IsRecordProtected(FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id).ASA_RECORD_ID) then
    --  fwk_i_mgt_exception.raise_exception(in_error_code    => -20900
    --                                    , iv_message       => 'This file is protected. Update impossible.'
    --                                    , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
    --                                    , iv_cause         => 'updateRECORD_COMP'
    --                                     );
    --end if;

    -- Composant avec tracabilit�, suppresion impossible
    if FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id).ARC_PROTECTED = 1 then
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Modification interdite !') ||
                                                              chr(10) ||
                                                              PCS.PC_FUNCTIONS.TranslateWord('Ce composant figure dans la tra�abilit� !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'updateRECORD_COMP'
                                         );
    end if;

    -- Traitement des donn�es du composant
    ASA_I_PRC_RECORD_COMP.ManageData(iotRecordComp);
    /***********************************
    ** Update record in table
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iotRecordComp);
    return lResult;
  end updateRECORD_COMP;

  /**
  * function deleteRECORD_COMP
  * Description
  *    Code m�tier de l'effacement d'un composant d'un dossier SAV
  * @created ECA
  * @lastUpdate
  * @public
  * @param iotRecordComp : ASA_RECORD_COMP de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteRECORD_COMP(iotRecordComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'STM_COMP_STOCK_MVT_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Effacement interdit !') ||
                                                              chr(10) ||
                                                              PCS.PC_FUNCTIONS.TranslateWord('Un mouvement de stock a �t� g�n�r� !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'deleteRECORD_COMP'
                                         );
    end if;

    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'STM_WORK_STOCK_MOVEMENT_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception
                 (in_error_code    => -20900
                , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Effacement interdit !') ||
                                      chr(10) ||
                                      PCS.PC_FUNCTIONS.TranslateWord
                                                              ('Le champ "Mouvement de stock sortie d''atelier" (STM_WORK_STOCK_MOVEMENT_ID) est renseign� !')
                , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                , iv_cause         => 'deleteRECORD_COMP'
                 );
    end if;

    -- Les composants d'ordre de fabrication ne peuvent �tre supprim�s.
    if    ASA_LIB_RECORD.IsRecordProtected(FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id).ASA_RECORD_ID)
       or not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'FAL_FACTORY_OUT_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Effacement interdit !') ||
                                                              chr(10) ||
                                                              PCS.PC_FUNCTIONS.TranslateWord('Ce composant est issu d''un lot de fabrication !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'deleteRECORD_COMP'
                                         );
    end if;

    -- Composant avec tracabilit�, suppresion impossible
    if FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id).ARC_PROTECTED = 1 then
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Effacement interdit !') ||
                                                              chr(10) ||
                                                              PCS.PC_FUNCTIONS.TranslateWord('Ce composant figure dans la tra�abilit� !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'deleteRECORD_COMP'
                                         );
    end if;

    -- Suppression du lien composant / position de document
    ASA_I_PRC_RECORD_COMP.ClearPositionCompLink(FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id).ASA_RECORD_COMP_ID);
    lResult  := FWK_I_DML_TABLE.CRUD(iotRecordComp);
    return null;
  end deleteRECORD_COMP;

  /**
  * function insertRECORD_EVENTS
  * Description
  *    Code m�tier de l'insertion d'un �v�nement de flux
  */
  function insertRECORD_EVENTS(iotRecordEvents in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltRecord     fwk_i_typ_definition.t_crud_def;
    lResult      varchar2(40);
    lAsaRecordId ASA_RECORD.ASA_RECORD_ID%type;
    lOldStatus   ASA_RECORD.C_ASA_REP_STATUS%type;
    lRreSeq      ASA_RECORD_EVENTS.RRE_SEQ%type;
  begin
    -- V�rifier que l'id du dossier SAV soit d�fini
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordEvents, 'ASA_RECORD_ID') then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Donn�es manquantes') || ' : ASA_RECORD_ID !'
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'insertRECORD_EVENTS'
                                         );
    end if;

    lAsaRecordId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordEvents, 'ASA_RECORD_ID');

    begin
      select C_ASA_REP_STATUS
           , RRE_SEQ
        into lOldStatus
           , lRreSeq
        from ASA_RECORD_EVENTS
       where ASA_RECORD_ID = lAsaRecordId
         and RRE_SEQ = (select max(RRE_SEQ)
                          from ASA_RECORD_EVENTS
                         where ASA_RECORD_ID = lAsaRecordId);
    exception
      when no_data_found then
        lOldStatus  := null;
        lRreSeq     := 0;
    end;

    if ASA_I_LIB_RECORD.CheckStatus(lAsaRecordId, lOldStatus, FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotRecordEvents, 'C_ASA_REP_STATUS') ) = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordEvents, 'RRE_DATE', trunc(sysdate) );
      -- Init de la s�quense de l'�v�nement
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordEvents, 'RRE_SEQ', lRreSeq + 1);
      lResult  := FWK_I_DML_TABLE.CRUD(iotRecordEvents);
      -- Mise � jour du dossier SAV
      -- Cr�ation de l'entit� ASA_RECORD
      FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltRecord, true);
      -- Init de l'id du dossier SAV
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'ASA_RECORD_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordEvents, 'ASA_RECORD_ID') );
      -- Init de l'id du dossier SAV
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'ASA_RECORD_EVENTS_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordEvents, 'ASA_RECORD_EVENTS_ID') );
      -- Init du status
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'C_ASA_REP_STATUS', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotRecordEvents, 'C_ASA_REP_STATUS') );
      FWK_I_MGT_ENTITY.UpdateEntity(ltRecord);
      FWK_I_MGT_ENTITY.Release(ltRecord);
    else
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20900
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Ce statut n''est pas autoris� dans cette phase du flux !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'insertRECORD_EVENTS'
                                         );
    end if;

    return lResult;
  end insertRECORD_EVENTS;
end ASA_MGT_RECORD;
