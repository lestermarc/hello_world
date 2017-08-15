--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_TASK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_TASK" 
is
  /**
  * procedure pConvertTaskAmounts
  * Description
  *   Conversion de montants en diverses monnaies
  */
  procedure pConvertTaskAmounts(
    iUpdateAmount in     varchar2
  , iCurrencyID   in     number
  , iLocalCurrID  in     number
  , iEuroCurrID   in     number
  , iDate         in     date
  , ioAmountME    in out number
  , ioAmount      in out number
  , ioAmountEUR   in out number
  )
  is
  begin
    -- Changement du montant en monnaie dossier SAV
    if iUpdateAmount = 'AMOUNT_ME' then
      -- Monnaie dossier SAV = Monnaie locale
      if iCurrencyID = iLocalCurrID then
        ioAmount  := ioAmountME;

        -- Monnaie dossier SAV = Monnaie EURO
        if iCurrencyID = iEuroCurrID then
          ioAmountEUR  := ioAmountME;
        else
          -- Monnaie dossier SAV <> Monnaie locale
          ioAmountEUR  := null;
        end if;
      else
        -- Monnaie dossier SAV <> Monnaie locale
        -- Convertion -> Rechercher : Montant et Montant EUR
        ACS_FUNCTION.ConvertAmount(aAmount          => ioAmountME
                                 , aFromFinCurrId   => iCurrencyID
                                 , aToFinCurrId     => iLocalCurrID
                                 , aDate            => ASA_LIB_RECORD.GetTariffDateRef(iDate)
                                 , aExchangeRate    => 0
                                 , aBasePrice       => 0
                                 , aRound           => 2
                                 , aAmountEUR       => ioAmountEUR
                                 , aAmountConvert   => ioAmount
                                 , aRateType        => 5
                                  );
      end if;
    -- Changement du montant en monnaie de base
    else
      -- Monnaie dossier SAV = Monnaie locale
      if iCurrencyID = iLocalCurrID then
        ioAmountME  := ioAmount;

        -- Monnaie dossier SAV = Monnaie EURO
        if iCurrencyID = iEuroCurrID then
          ioAmountEUR  := ioAmount;
        else
          -- Monnaie locale <> Monnaie EURO
          ioAmountEUR  := null;
        end if;
      else
        -- Monnaie dossier SAV <> Monnaie locale
        -- Convertion -> Rechercher : Montant ME et Montant EUR
        ACS_FUNCTION.ConvertAmount(aAmount          => ioAmount
                                 , aFromFinCurrId   => iLocalCurrID
                                 , aToFinCurrId     => iCurrencyID
                                 , aDate            => ASA_LIB_RECORD.GetTariffDateRef(iDate)
                                 , aExchangeRate    => 0
                                 , aBasePrice       => 0
                                 , aRound           => 2
                                 , aAmountEUR       => ioAmountEUR
                                 , aAmountConvert   => ioAmountME
                                 , aRateType        => 5
                                  );
      end if;
    end if;
  end pConvertTaskAmounts;

  /**
  * procedure ClearPositionTaskLink
  * Description
  *   Effacer le lien de l'opération SAV sur les positions de document
  */
  procedure ClearPositionTaskLink(iTaskID in ASA_RECORD_TASK.ASA_RECORD_TASK_ID%type)
  is
    ltPos FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Effacer le lien de l'opération SAV sur les positions de document
    for tplPos in (select DOC_POSITION_ID
                     from DOC_POSITION
                    where ASA_RECORD_TASK_ID = iTaskID) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocPosition, iot_crud_definition => ltPos, in_main_id => tplPos.DOC_POSITION_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltPos, 'ASA_RECORD_TASK_ID');
      FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
      FWK_I_MGT_ENTITY.Release(ltPos);
    end loop;
  end ClearPositionTaskLink;

  /**
  * procedure InitializeData
  * Description
  *   Init des données de base de l'opération
  * @author NGV
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param iotRecordTask : ASA_RECORD_TASK de type T_CRUD_DEF
  * @API
  */
  procedure InitializeData(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lASA_RECORD_ID        ASA_RECORD.ASA_RECORD_ID%type            default null;
    lASA_RECORD_EVENTS_ID ASA_RECORD.ASA_RECORD_EVENTS_ID%type     default null;
    lASA_REP_TYPE_ID      ASA_REP_TYPE.ASA_REP_TYPE_ID%type        default null;
    lGenPosTask           ASA_RECORD_TASK.C_ASA_GEN_DOC_POS%type   default null;
    lRET_POSITION         ASA_RECORD_TASK.RET_POSITION%type;
  begin
    lASA_RECORD_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordTask, 'ASA_RECORD_ID');

    -- Recherche de données sur le dossier SAV
    -- ID du type de réparation
    select max(ASA_REP_TYPE_ID)
      into lASA_REP_TYPE_ID
      from ASA_RECORD
     where ASA_RECORD_ID = lASA_RECORD_ID;

    -- Rechercher des infos sur le type de rép.
    if lASA_REP_TYPE_ID is not null then
      select max(C_ASA_GEN_DOC_POS_TASK)
        into lGenPosTask
        from ASA_REP_TYPE
       where ASA_REP_TYPE_ID = lASA_REP_TYPE_ID;
    end if;

    -- Champ "Logistique" -> C_ASA_GEN_DOC_POS
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'C_ASA_GEN_DOC_POS') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'C_ASA_GEN_DOC_POS', nvl(lGenPosTask, PCS.PC_CONFIG.GetConfig('ASA_TASK_DEFAULT_DOC_POS') ) );
    end if;

    -- ID de l'événement initialisé par rapport au dossier SAV si pas renseigné
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'ASA_RECORD_EVENTS_ID') then
      select max(ASA_RECORD_EVENTS_ID)
        into lASA_RECORD_EVENTS_ID
        from ASA_RECORD
       where ASA_RECORD_ID = lASA_RECORD_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'ASA_RECORD_EVENTS_ID', lASA_RECORD_EVENTS_ID);
    else
      lASA_RECORD_EVENTS_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordTask, 'ASA_RECORD_EVENTS_ID');
    end if;

    -- N° de séquence de l'opération
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_POSITION') then
      select nvl(max(RET_POSITION), 0) + PCS.PC_CONFIG.GetConfig('ASA_TASK_INCREMENT')
        into lRET_POSITION
        from ASA_RECORD_TASK
       where ASA_RECORD_ID = lASA_RECORD_ID
         and ASA_RECORD_EVENTS_ID = lASA_RECORD_EVENTS_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_POSITION', lRET_POSITION);
    end if;

    -- N° taux atelier si pas déjà défini
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_WORK_RATE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_WORK_RATE', 1);
    end if;
  end InitializeData;

  /**
  * procedure InitTime
  * Description
  *   Init du temps effectif
  */
  procedure InitTime(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- Initialisation automatique du temps effectif a partir du temps prévu
    if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_TIME_USED') then
      if     FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_FINISHED')
         and (FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_FINISHED = 1)
         and FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'RET_TIME_USED')
         and (upper(PCS.PC_CONFIG.GetConfig('ASA_TASK_AUTO_INIT_TIME_USED') ) = 'TRUE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_TIME_USED', FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_TIME);
      end if;
    end if;
  end InitTime;

  /**
  * procedure InitFalTaskData
  * Description
  *   Init des données relatives à l'opération de fabrication
  */
  procedure InitFalTaskData(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lFAL_TASK_ID           FAL_TASK.FAL_TASK_ID%type;
    lFAL_FACTORY_FLOOR_ID  FAL_TASK.FAL_FACTORY_FLOOR_ID%type;
    lTAS_SHORT_DESCR       FAL_TASK.TAS_SHORT_DESCR%type;
    lTAS_LONG_DESCR        FAL_TASK.TAS_LONG_DESCR%type;
    lTAS_FREE_DESCR        FAL_TASK.TAS_FREE_DESCR%type;
    lRET_WORK_RATE         ASA_RECORD_TASK.RET_WORK_RATE%type;
    lRET_COST_PRICE        ASA_RECORD_TASK.RET_COST_PRICE%type;
    lcfgASA_TASK_INIT_DATA varchar2(30);
  begin
    lFAL_TASK_ID  := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).FAL_TASK_ID;

    -- Opération de fabrication renseignée
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'FAL_TASK_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'FAL_TASK_ID') then
      -- Recherche les infos de l'opération de fabrication
      select FAL_FACTORY_FLOOR_ID
           , TAS_SHORT_DESCR
           , TAS_LONG_DESCR
           , TAS_FREE_DESCR
        into lFAL_FACTORY_FLOOR_ID
           , lTAS_SHORT_DESCR
           , lTAS_LONG_DESCR
           , lTAS_FREE_DESCR
        from FAL_TASK
       where FAL_TASK_ID = lFAL_TASK_ID;

      -- Atelier spécifié dans l'opération de fabrication
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'FAL_FACTORY_FLOOR_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'FAL_FACTORY_FLOOR_ID', lFAL_FACTORY_FLOOR_ID);
      end if;

      -- cfg ASA_TASK_INIT_DATA
      --   1 : Utilisation des données du fichiers des opérations FAL_TASK
      --   2 : Utilisation d'un pseudo article relatif à une opération
      --   3 : Si un lien existe avec le fichier des opération FAL_TASK -> utilisation des données de FAL_TASK,
      --       sinon utilisation d'un Pseudo article
      lcfgASA_TASK_INIT_DATA  := PCS.PC_CONFIG.GetConfig('ASA_TASK_INIT_DATA');

      if lcfgASA_TASK_INIT_DATA <> '2' then
        -- Description courte
        if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_DESCR')
           and (lTAS_SHORT_DESCR is not null)
           and (   FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'RET_DESCR')
                or (lcfgASA_TASK_INIT_DATA = '1') ) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_DESCR', lTAS_SHORT_DESCR);
        end if;

        -- Description longue
        if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_DESCR2')
           and (lTAS_LONG_DESCR is not null)
           and (   FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'RET_DESCR2')
                or (lcfgASA_TASK_INIT_DATA = '1') ) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_DESCR2', lTAS_LONG_DESCR);
        end if;

        -- Description libre
        if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_DESCR3')
           and (lTAS_FREE_DESCR is not null)
           and (   FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'RET_DESCR3')
                or (lcfgASA_TASK_INIT_DATA = '1') ) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_DESCR3', lTAS_FREE_DESCR);
        end if;
      end if;
    end if;

    -- Recalcul du prix de revient si le N° taux atelier a été modifié
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'FAL_TASK_ID')
       and FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_WORK_RATE') then
      lRET_WORK_RATE  := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_WORK_RATE;

      select nvl(max(FAL_FACT_FLOOR.GetDateRateValue(TAS.FAL_FACTORY_FLOOR_ID, sysdate, lRET_WORK_RATE) ), 0)
        into lRET_COST_PRICE
        from FAL_TASK TAS
       where TAS.FAL_TASK_ID = lFAL_TASK_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_COST_PRICE', lRET_COST_PRICE);
    end if;
  end InitFalTaskData;

  /**
  * procedure InitBillGoodData
  * Description
  *   Init des données relatives au produit pour la facturation
  */
  procedure InitBillGoodData(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lGCO_BILL_GOOD_ID ASA_RECORD_TASK.GCO_BILL_GOOD_ID%type;
    lASA_RECORD_ID    ASA_RECORD.ASA_RECORD_ID%type;
    ltRecord          ASA_RECORD%rowtype;
    lShortDescr       ASA_RECORD_TASK.RET_DESCR%type;
    lLongDescr        ASA_RECORD_TASK.RET_DESCR2%type;
    lFreeDescr        ASA_RECORD_TASK.RET_DESCR3%type;
    lAmount           ASA_RECORD_TASK.RET_SALE_AMOUNT_ME%type;
  begin
    -- Produit pour facturation
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'GCO_BILL_GOOD_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'GCO_BILL_GOOD_ID') then
      lGCO_BILL_GOOD_ID  := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).GCO_BILL_GOOD_ID;
      lASA_RECORD_ID     := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).ASA_RECORD_ID;

      -- Récupere les infos du dossier sav
      select *
        into ltRecord
        from ASA_RECORD
       where ASA_RECORD_ID = lASA_RECORD_ID;

      -- Recherche les descriptions du bien
      ASA_I_LIB_RECORD.GetGoodDescr(iGoodID       => lGCO_BILL_GOOD_ID
                                  , iLangID       => ltRecord.PC_ASA_CUST_LANG_ID
                                  , oShortDescr   => lShortDescr
                                  , oLongDescr    => lLongDescr
                                  , oFreeDescr    => lFreeDescr
                                   );

      -- Descriptions courte, longue et libre
      if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_DESCR')
         and lShortDescr is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_DESCR', lShortDescr);
      end if;

      if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_DESCR2')
         and lLongDescr is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_DESCR2', lLongDescr);
      end if;

      if     not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_DESCR3')
         and lFreeDescr is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_DESCR3', lFreeDescr);
      end if;

      -- Prix de vente ME
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT_ME') then
        if ltRecord.DIC_TARIFF_ID is not null then
          lAmount  :=
            ASA_I_LIB_RECORD.GetGoodSalePrice(iGoodID       => lGCO_BILL_GOOD_ID
                                            , iThirdID      => ltRecord.PAC_CUSTOM_PARTNER_ID
                                            , iRecordID     => ltRecord.DOC_RECORD_ID
                                            , iDicTariff    => ltRecord.DIC_TARIFF_ID
                                            , iCurrencyID   => ltRecord.ACS_FINANCIAL_CURRENCY_ID
                                            , iDate         => ASA_LIB_RECORD.GetTariffDateRef(ltRecord.ARE_DATECRE)
                                             );

          if lAmount <> 0 then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT_ME', lAmount);
          end if;
        end if;
      end if;

      -- Prix de vente 2 ME
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT2_ME') then
        if ltRecord.DIC_TARIFF2_ID is not null then
          lAmount  :=
            ASA_I_LIB_RECORD.GetGoodSalePrice(iGoodID       => lGCO_BILL_GOOD_ID
                                            , iThirdID      => ltRecord.PAC_CUSTOM_PARTNER_ID
                                            , iRecordID     => ltRecord.DOC_RECORD_ID
                                            , iDicTariff    => ltRecord.DIC_TARIFF2_ID
                                            , iCurrencyID   => ltRecord.ACS_FINANCIAL_CURRENCY_ID
                                            , iDate         => ASA_LIB_RECORD.GetTariffDateRef(ltRecord.ARE_DATECRE)
                                             );

          if lAmount <> 0 then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT2_ME', lAmount);
          end if;
        end if;
      end if;

      -- Prix de revient
      if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_COST_PRICE') then
        if    FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordTask, 'FAL_TASK_ID')
           or (PCS.PC_CONFIG.GetConfig('ASA_TASK_INIT_DATA') = '2') then
          lAmount  :=
            ASA_I_LIB_RECORD.GetGoodCostPrice(iGoodID    => lGCO_BILL_GOOD_ID
                                            , iThirdID   => ltRecord.PAC_CUSTOM_PARTNER_ID
                                            , iDate      => ASA_LIB_RECORD.GetTariffDateRef(ltRecord.ARE_DATECRE)
                                             );

          if lAmount <> 0 then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_COST_PRICE', lAmount);
          end if;
        end if;
      end if;
    end if;
  end InitBillGoodData;

  /**
  * procedure CalcAmounts
  * Description
  *   Recalcul des divers montants en MB et ME
  */
  procedure CalcAmounts(iotRecordTask in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lAmountME      number                                                  := 0.0;
    lAmount        number                                                  := 0.0;
    lAmountEUR     number                                                  := 0.0;
    lUpdateAmount  varchar2(30);
    lTariffDateRef date;
    lCurrencyID    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lLocalCurrID   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lEuroCurrID    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lASA_RECORD_ID ASA_RECORD.ASA_RECORD_ID%type;
  begin
    -- Vérifier qu'il y ai au moins un champ montant modifié
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT_ME')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT2_ME')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT2')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_AMOUNT_ME')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_AMOUNT') then
      lASA_RECORD_ID  := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).ASA_RECORD_ID;

      -- Rechercher la monnaie du dossier Sav et la date du dossier
      select ACS_FINANCIAL_CURRENCY_ID
           , ASA_LIB_RECORD.GetTariffDateRef(ARE_DATECRE)
        into lCurrencyID
           , lTariffDateRef
        from ASA_RECORD
       where ASA_RECORD_ID = lASA_RECORD_ID;

      -- Rechercher la monnaie locale
      lLocalCurrID    := ACS_FUNCTION.GetLocalCurrencyId;

      -- Rechercher la monnaie EURO
      select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
        into lEuroCurrID
        from ACS_FINANCIAL_CURRENCY FIN
           , PCS.PC_CURR CUR
       where FIN.PC_CURR_ID = CUR.PC_CURR_ID
         and CUR.CURRENCY = 'EUR';

      -- Modification du montant de vente
      if    FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT_ME')
         or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT') then
        lAmountME   := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_SALE_AMOUNT_ME;
        lAmount     := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_SALE_AMOUNT;
        lAmountEUR  := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_SALE_AMOUNT_EURO;

        -- Définition du champ modifié pour le recalcul
        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT_ME') then
          lUpdateAmount  := 'AMOUNT_ME';
        else
          lUpdateAmount  := 'AMOUNT';
        end if;

        pConvertTaskAmounts(iUpdateAmount   => lUpdateAmount
                          , iCurrencyID     => lCurrencyID
                          , iLocalCurrID    => lLocalCurrID
                          , iEuroCurrID     => lEuroCurrID
                          , iDate           => lTariffDateRef
                          , ioAmountME      => lAmountME
                          , ioAmount        => lAmount
                          , ioAmountEUR     => lAmountEUR
                           );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT_ME', lAmountME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT', lAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT_EURO', lAmountEUR);
      end if;

      -- Modification du montant de vente 2
      if    FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT2_ME')
         or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT2') then
        lAmountME   := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_SALE_AMOUNT2_ME;
        lAmount     := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_SALE_AMOUNT2;
        lAmountEUR  := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_SALE_AMOUNT2_EURO;

        -- Définition du champ modifié pour le recalcul
        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_SALE_AMOUNT2_ME') then
          lUpdateAmount  := 'AMOUNT_ME';
        else
          lUpdateAmount  := 'AMOUNT';
        end if;

        pConvertTaskAmounts(iUpdateAmount   => lUpdateAmount
                          , iCurrencyID     => lCurrencyID
                          , iLocalCurrID    => lLocalCurrID
                          , iEuroCurrID     => lEuroCurrID
                          , iDate           => lTariffDateRef
                          , ioAmountME      => lAmountME
                          , ioAmount        => lAmount
                          , ioAmountEUR     => lAmountEUR
                           );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT2_ME', lAmountME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT2', lAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_SALE_AMOUNT2_EURO', lAmountEUR);
      end if;

      -- Modification du montant opération externe
      if    FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_AMOUNT_ME')
         or FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_AMOUNT') then
        lAmountME   := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_AMOUNT_ME;
        lAmount     := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_AMOUNT;
        lAmountEUR  := FWK_TYP_ASA_ENTITY.gttRecordTask(iotRecordTask.entity_id).RET_AMOUNT_EURO;

        -- Définition du champ modifié pour le recalcul
        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordTask, 'RET_AMOUNT_ME') then
          lUpdateAmount  := 'AMOUNT_ME';
        else
          lUpdateAmount  := 'AMOUNT';
        end if;

        pConvertTaskAmounts(iUpdateAmount   => lUpdateAmount
                          , iCurrencyID     => lCurrencyID
                          , iLocalCurrID    => lLocalCurrID
                          , iEuroCurrID     => lEuroCurrID
                          , iDate           => lTariffDateRef
                          , ioAmountME      => lAmountME
                          , ioAmount        => lAmount
                          , ioAmountEUR     => lAmountEUR
                           );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_AMOUNT_ME', lAmountME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_AMOUNT', lAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordTask, 'RET_AMOUNT_EURO', lAmountEUR);
      end if;
    end if;
  end CalcAmounts;

  /**
  * procedure InitTasksUsedTime
  * Description
  *   Màj du temps effectif de toutes les opérations d'un dossier SAV
  */
  procedure InitTasksUsedTime(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type, iRecordEventID in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type)
  is
    ltTask FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplTask in (select   ASA_RECORD_TASK_ID
                           , nvl(RET_OPTIONAL, 0) RET_OPTIONAL
                           , C_ASA_ACCEPT_OPTION
                           , RET_TIME_USED
                           , RET_TIME
                        from ASA_RECORD_TASK
                       where ASA_RECORD_ID = iAsaRecordID
                         and nvl(ASA_RECORD_EVENTS_ID, -1) = nvl(iRecordEventID, -1)
                    order by RET_POSITION) loop
      -- Màj du temps effectif
      if     (    (tplTask.RET_OPTIONAL = 0)
              or (tplTask.C_ASA_ACCEPT_OPTION = '2') )
         and (tplTask.RET_TIME_USED is null)
         and (tplTask.RET_TIME is not null) then
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltTask);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_TASK_ID', tplTask.ASA_RECORD_TASK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'RET_TIME_USED', tplTask.RET_TIME);
        FWK_I_MGT_ENTITY.UpdateEntity(ltTask);
        FWK_I_MGT_ENTITY.Release(ltTask);
      end if;
    end loop;
  end InitTasksUsedTime;

  /**
  * procedure UpdateRecordEvent
  * Description
  *   Màj de l'ID d'une étape de flux sur toutes les opérations d'un dossier SAV
  */
  procedure UpdateRecordEvent(
    iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type
  , iNewEventID  in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type
  , iOldEventID  in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type
  )
  is
    ltTask         FWK_I_TYP_DEFINITION.t_crud_def;
    ltPos          FWK_I_TYP_DEFINITION.t_crud_def;
    lExistOldEvent integer;
  begin
    -- Vérifier s'il y a eu une suppression d'une étape de flux
    select sign(nvl(max(ASA_RECORD_EVENTS_ID), 0) )
      into lExistOldEvent
      from ASA_RECORD_EVENTS
     where ASA_RECORD_EVENTS_ID = iOldEventID;

    -- Une étape du flux a été supprimée
    if lExistOldEvent = 0 then
      -- Màj des DOC_POSITION avec le nouveau lien opération
      for tplTask in (select   RET_NEW.RET_POSITION
                             , RET_NEW.ASA_RECORD_TASK_ID NEW_TASK_ID
                             , RET_OLD.ASA_RECORD_TASK_ID OLD_TASK_ID
                          from (select RET_POSITION
                                     , ASA_RECORD_TASK_ID
                                  from ASA_RECORD_TASK
                                 where ASA_RECORD_ID = iAsaRecordID
                                   and ASA_RECORD_EVENTS_ID = iOldEventID) RET_OLD
                             , (select RET_POSITION
                                     , ASA_RECORD_TASK_ID
                                  from ASA_RECORD_TASK
                                 where ASA_RECORD_ID = iAsaRecordID
                                   and ASA_RECORD_EVENTS_ID = iNewEventID) RET_NEW
                         where RET_OLD.RET_POSITION = RET_NEW.RET_POSITION
                      order by RET_NEW.RET_POSITION) loop
        -- Màj des DOC_POSITION liées à l'ancienne opération
        for tplPos in (select DOC_POSITION_ID
                         from DOC_POSITION
                        where ASA_RECORD_TASK_ID = tplTask.OLD_TASK_ID) loop
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPosition, ltPos);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', tplPos.DOC_POSITION_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'ASA_RECORD_TASK_ID', tplTask.NEW_TASK_ID);
          FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
          FWK_I_MGT_ENTITY.Release(ltPos);
        end loop;

        -- Màj des DOC_POSITION imputées à l'ancienne opération
        for tplPos in (select DOC_POSITION_ID
                         from DOC_POSITION
                        where ASA_RECORD_TASK_IMPUT_ID = tplTask.OLD_TASK_ID) loop
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPosition, ltPos);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', tplPos.DOC_POSITION_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'ASA_RECORD_TASK_IMPUT_ID', tplTask.NEW_TASK_ID);
          FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
          FWK_I_MGT_ENTITY.Release(ltPos);
        end loop;
      end loop;

      -- Effacer les opérations historiées liées au flux qui va devenir le dernier flux
      for tplTask in (select   ASA_RECORD_TASK_ID
                          from ASA_RECORD_TASK
                         where ASA_RECORD_ID = iAsaRecordID
                           and nvl(ASA_RECORD_EVENTS_ID, -1) = iNewEventID
                      order by RET_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltTask);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_TASK_ID', tplTask.ASA_RECORD_TASK_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltTask);
        FWK_I_MGT_ENTITY.Release(ltTask);
      end loop;

      -- Les opérations liées au flux supprimé deviennent liées au dernier flux
      for tplTask in (select   ASA_RECORD_TASK_ID
                          from ASA_RECORD_TASK
                         where ASA_RECORD_ID = iAsaRecordID
                           and nvl(ASA_RECORD_EVENTS_ID, -1) = nvl(iOldEventID, -1)
                      order by RET_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltTask);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_TASK_ID', tplTask.ASA_RECORD_TASK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_EVENTS_ID', iNewEventID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltTask);
        FWK_I_MGT_ENTITY.Release(ltTask);
      end loop;
    -- Gestion de l'historique des opérations = NON
    elsif    (upper(PCS.PC_CONFIG.GetConfig('ASA_TASK_AND_COMP_HISTORY') ) = 'FALSE')
          or (iOldEventID is null) then
      -- Màj l'id de l'étape de flux sur les opérations
      for tplTask in (select   ASA_RECORD_TASK_ID
                          from ASA_RECORD_TASK
                         where ASA_RECORD_ID = iAsaRecordID
                           and nvl(ASA_RECORD_EVENTS_ID, -1) = nvl(iOldEventID, -1)
                      order by RET_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltTask);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_TASK_ID', tplTask.ASA_RECORD_TASK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_EVENTS_ID', iNewEventID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltTask);
        FWK_I_MGT_ENTITY.Release(ltTask);
      end loop;
    elsif     (upper(PCS.PC_CONFIG.GetConfig('ASA_TASK_AND_COMP_HISTORY') ) = 'TRUE')
          and (iOldEventID is not null) then
      -- Gestion de l'historique des opérations = OUI
      -- et pas première étape du flux
      --
      -- Balayer les opérations liées à l'id de nouvelle étape de flux
      for tplTask in (select ASA_RECORD_TASK_ID
                        from ASA_RECORD_TASK
                       where ASA_RECORD_ID = iAsaRecordID
                         and ASA_RECORD_EVENTS_ID = iNewEventID) loop
        -- Effacer le lien ASA_RECORD_TASK_ID sur les positions document qui
        -- ont un id d'opération qui est liée l'id de la nouvelle étape de flux
        for tplPos in (select DOC_POSITION_ID
                         from DOC_POSITION
                        where ASA_RECORD_TASK_ID = tplTask.ASA_RECORD_TASK_ID) loop
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPosition, ltPos);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', tplPos.DOC_POSITION_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltPos, 'ASA_RECORD_TASK_ID');
          FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
          FWK_I_MGT_ENTITY.Release(ltPos);
        end loop;

        -- Effacer les opérations liées à l'id de la nouvelle étape de flux
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltTask);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_TASK_ID', tplTask.ASA_RECORD_TASK_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltTask);
        FWK_I_MGT_ENTITY.Release(ltTask);
      end loop;

      -- Copie des opérations pour le nouveau statut
      for tplTask in (select   ASA_RECORD_TASK_ID
                          from ASA_RECORD_TASK
                         where ASA_RECORD_ID = iAsaRecordID
                           and ASA_RECORD_EVENTS_ID = iOldEventID
                      order by RET_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltTask);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltTask, true, tplTask.ASA_RECORD_TASK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_TASK_ID', INIT_ID_SEQ.nextval);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'ASA_RECORD_EVENTS_ID', iNewEventID);
        FWK_I_MGT_ENTITY.InsertEntity(ltTask);
        FWK_I_MGT_ENTITY.Release(ltTask);

        -- Liste des positions liées à l'ancienne opération
        for tplPos in (select DOC_POSITION_ID
                         from DOC_POSITION
                        where ASA_RECORD_TASK_IMPUT_ID = tplTask.ASA_RECORD_TASK_ID) loop
          -- Màj le lien sur la nouvelle opération
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPosition, ltPos);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', tplPos.DOC_POSITION_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'ASA_RECORD_TASK_IMPUT_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTask, 'ASA_RECORD_TASK_ID') );
          FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
          FWK_I_MGT_ENTITY.Release(ltPos);
        end loop;
      end loop;
    end if;
  end UpdateRecordEvent;

  /**
  * procedure CtrlAllUsedTime
  * Description
  *   Vérifier si tous les temps effectifs des opérations ont été saisis
  */
  function CtrlAllUsedTime(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type, iRecordEventID in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type)
    return boolean
  is
    lResult boolean := true;
  begin
    -- Liste des opérations du dossier pour le ctrl des temps effectifs
    for tplTask in (select   RET_POSITION
                           , RET_TIME_USED
                           , nvl(RET_OPTIONAL, 0) RET_OPTIONAL
                           , C_ASA_ACCEPT_OPTION
                        from ASA_RECORD_TASK
                       where ASA_RECORD_ID = iAsaRecordID
                         and ASA_RECORD_EVENTS_ID = iRecordEventID
                    order by RET_POSITION) loop
      -- Vérifie si le temps effectif a été saisi pour toutes les opérations
      -- qui ne sont pas optionnelles
      if     (tplTask.RET_TIME_USED is null)
         and (    (tplTask.RET_OPTIONAL = 0)
              or (tplTask.C_ASA_ACCEPT_OPTION = '2') ) then
        lResult  := false;
      end if;
    end loop;

    return lResult;
  end CtrlAllUsedTime;

  /**
  * Procedure AcceptEstimateTask
  * Description
  *   Acceptation d'opérations pour le devis
  */
  procedure AcceptEstimateTask(iTaskId in ASA_RECORD_TASK.ASA_RECORD_TASK_ID%type, iAccept in number)
  is
    ltRecordTask       FWK_I_TYP_DEFINITION.t_crud_def;
    lvCAsaAcceptOption varchar2(10);
  begin
    -- Création de l'entité ASA_RECORD_TASK
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltRecordTask);
    -- Init de l'id de l'opération
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'ASA_RECORD_TASK_ID', iTaskId);

    -- Init de l'acceptation de l'option
    if iAccept = 0 then
      lvCAsaAcceptOption  := '1';
    else
      lvCAsaAcceptOption  := '2';
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'C_ASA_ACCEPT_OPTION', lvCAsaAcceptOption);
    --Modification de l'opération
    FWK_I_MGT_ENTITY.UpdateEntity(ltRecordTask);
    FWK_I_MGT_ENTITY.Release(ltRecordTask);
  end AcceptEstimateTask;
end ASA_PRC_RECORD_TASK;
