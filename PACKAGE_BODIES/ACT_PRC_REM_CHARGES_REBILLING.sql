--------------------------------------------------------
--  DDL for Package Body ACT_PRC_REM_CHARGES_REBILLING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PRC_REM_CHARGES_REBILLING" 
is
  /*Curseur définissant les éléments du log */
  cursor cLogElements
  is
    select RCT_ISE_CONTRACT
         , RCT_ISE_INVOICE_NUMBER
         , RCT_ISE_SUBSCRIPTION_NUMBER
         , lpad(' ', 30) PAR_DOCUMENT
         , lpad(' ', 250) RRJ_FREE_TEXT1
         , lpad(' ', 4000) RRJ_LOG_TEXT
         , ACT_REM_CHARGES_REBILLING_ID
      from ACT_REM_EXP_CHARGES_TMP
     where ACT_REM_CHARGES_REBILLING_ID = -1;

  /*Structure table de réception des éléments du log*/
  type TLogElement is table of cLogElements%rowtype
    index by binary_integer;

  t_LogElement TLogElement;

  /**
  * Description
  *   Journalisation des traitements. Respectivement transfert depuis la structure initialisée à chaque traitement à la table de log
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param  iRemChargesRebillingId   Id lot de facturation
  */
  procedure p_Journalize(iRemChargesRebillingId in number)
  is
    pragma autonomous_transaction;
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    --Suppression des log des précédentes opérations du lot
    delete from ACT_REM_REBILLING_LOG
          where ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingId;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActRemRebillingLog, lt_crud_def);

    for ln_Counter in t_LogElement.first .. t_LogElement.last loop
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RRJ_DATE', current_timestamp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RRJ_LOG_TEXT', t_LogElement(ln_Counter).RRJ_LOG_TEXT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RRJ_DOCUMENT', t_LogElement(ln_Counter).PAR_DOCUMENT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RRJ_ISE_CONTRACT', t_LogElement(ln_Counter).RCT_ISE_CONTRACT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RRJ_ISE_INVOICE_NUMBER', t_LogElement(ln_Counter).RCT_ISE_INVOICE_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RRJ_ISE_SUBSCRIPTION_NUMBER', t_LogElement(ln_Counter).RCT_ISE_SUBSCRIPTION_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RRJ_FREE_TEXT1', t_LogElement(ln_Counter).RRJ_FREE_TEXT1);
      FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    end loop;

    FWK_I_MGT_ENTITY.Release(lt_crud_def);
    commit;
  exception
    when others then
      rollback;
  end p_Journalize;

  /**
  * Description
  *   Imporation des frais et intérêts de relances selon critères saisies dans le lot
  *   passé en paramètre
  * @created Sener Kalayci
  * @lastUpdate age 09.06.2015
  * @private
  * @param  iRemChargesRebillingId   Id lot de facturation
  * @return Nombre de ligne de données extraites
  */
  function p_ImportCharges(iRemChargesRebillingId in number)
    return number
  is
    lt_crud_def   FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    ln_Counter    number;
    ln_Treated    number;
    ln_Reminder   ACT_REM_CHARGES_REBILLING.RCR_REMINDER%type;
    lv_ChargeType ACT_REM_REBILLING_PAR.RBP_CHARGE_TYPE%type;
    ln_RemMin     ACT_REM_CHARGES_REBILLING.RCR_REMINDER_MIN_AMOUNT%type;
    ln_IntMin     ACT_REM_CHARGES_REBILLING.RCR_INTEREST_MIN_AMOUNT%type;
  begin
    ln_Treated                                             := -1;
    ln_Counter                                             := t_LogElement.count + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Début] Préparation des données');
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;

    --Types  et montants de frais à prendre en compte
    begin
      select RBP_CHARGE_TYPE
           , RCR_REMINDER_MIN_AMOUNT
           , RCR_INTEREST_MIN_AMOUNT
        into lv_ChargeType
           , ln_RemMin
           , ln_IntMin
        from ACT_REM_CHARGES_REBILLING rcr
           , ACT_REM_REBILLING_PAR rbp
       where ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingId
         and rbp.ACT_REM_REBILLING_PAR_ID = rcr.ACT_REM_REBILLING_PAR_ID;

      if (nvl(length(lv_ChargeType), 0) = 0) then   --Frais non sélectionnés
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Fin] Préparation des données - Frais non sélectionnés');
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
        return ln_Treated;
      end if;
    exception
      when no_data_found then
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Fin] Erreur lors de la préparation des données');
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  :=
                                                  t_LogElement(ln_Counter).RRJ_FREE_TEXT1 || chr(10) || sqlerrm || chr(10)
                                                  || DBMS_UTILITY.format_error_backtrace;
        return ln_Treated;
    end;

    -- Ajout des lignes de frais de rappel
    if (nvl(length(lv_ChargeType), 0) > 0) then
      ln_Counter                                             := ln_Counter + 1;
      t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
      t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
        PCS.PC_FUNCTIONS.TranslateWord
                               ('[2]-[Début] Importation des frais de la table ''ACT_REMINDER_EXP_CHARGES'' dans la table temporaire ''ACT_REM_EXP_CHARGES_TMP');
      t_LogElement(ln_Counter).RRJ_LOG_TEXT                  :=
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1 ||
        chr(10) ||
        'select ACT_REMINDER_EXP_CHARGES_ID, PAR_DOCUMENT, REM_NUMBER, REM_CHARGE_AMOUNT_RC, REM_INTEREST_AMOUNT_RC ' ||
        chr(10) ||
        'from ACT_REMINDER_EXP_CHARGES ARC ' ||
        chr(10) ||
        ' where C_REM_EXP_CHARGES_STATUS in (''0'',''3'')' ||
        chr(10) ||
        '   and instr(ARC.PAR_DOCUMENT,''-X'') = 0 ' ||
        '   and REM_CHARGE_AMOUNT_RC >= ' ||
        ln_RemMin ||
        chr(10) ||
        '   and REM_INTEREST_AMOUNT_RC >= ' ||
        ln_IntMin ||
        chr(10) ||
        '   and (    (REM_CHARGE_AMOUNT_RC > 0.00) or (REM_INTEREST_AMOUNT_RC > 0.00) ) ' ||
        chr(10) ||
        '   and REM_NUMBER between 1 and 4  order by PAR_DOCUMENT desc';
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActRemExpChargesTmp, lt_crud_def);

      for tplActiveRecord in (select   ACT_REMINDER_EXP_CHARGES_ID
                                     , PAR_DOCUMENT
                                     , REM_NUMBER
                                     , REM_CHARGE_AMOUNT_RC
                                     , REM_INTEREST_AMOUNT_RC
                                     , substr(PER_NAME, 1, 50) PER_NAME
                                  from ACT_REMINDER_EXP_CHARGES ARC
                                     , PAC_PERSON PER
                                 where C_REM_EXP_CHARGES_STATUS = '0'
                                   and instr(ARC.PAR_DOCUMENT, '-X') = 0
                                   and (    (REM_CHARGE_AMOUNT_RC >= ln_RemMin and ln_RemMin <> 0)
                                        or (REM_INTEREST_AMOUNT_RC >= ln_IntMin)  and ln_IntMin <> 0 )
                                   /*
                                   and (    (REM_CHARGE_AMOUNT_RC >= ln_RemMin)
                                        or (REM_INTEREST_AMOUNT_RC >= ln_IntMin) )
                                   */
                                   and (    (REM_CHARGE_AMOUNT_RC > 0.00)
                                        or (REM_INTEREST_AMOUNT_RC > 0.00) )
                                   and REM_NUMBER between 1 and 4
                                   and PER.PAC_PERSON_ID = ARC.PAC_CUSTOM_PARTNER_ID
                              order by PAR_DOCUMENT desc) loop
        FWK_I_MGT_ENTITY.clear(lt_crud_def);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REMINDER_EXP_CHARGES_ID', tplActiveRecord.ACT_REMINDER_EXP_CHARGES_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', iRemChargesRebillingId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_BILLING', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_CANCELLATION', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_CHARGE_TYPE', lv_ChargeType);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_CHARGE_AMOUNT', tplActiveRecord.REM_CHARGE_AMOUNT_RC);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_INTEREST_AMOUNT', tplActiveRecord.REM_INTEREST_AMOUNT_RC);
        FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
        ln_Treated                                             := 1;
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
          PCS.PC_FUNCTIONS.TranslateWord('[3]- Traitement position : Document / rappel no   -> ') ||
          tplActiveRecord.PAR_DOCUMENT ||
          ' / ' ||
          tplActiveRecord.REM_NUMBER;
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
        t_LogElement(ln_Counter).PAR_DOCUMENT                  := tplActiveRecord.PAR_DOCUMENT;
        t_LogElement(ln_Counter).RCT_ISE_SUBSCRIPTION_NUMBER   := tplActiveRecord.PER_NAME;
      end loop;

      if ln_Treated = -1 then
        ln_Treated                                             := 0;
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
                   PCS.PC_FUNCTIONS.TranslateWord('[3]- Pas de position correspondant aux critères : Montant frais (@C_AMOUNT) /  Montant intérêt (I_AMOUNT) ');
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := replace(t_LogElement(ln_Counter).RRJ_FREE_TEXT1, '@C_AMOUNT', ln_RemMin);
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := replace(t_LogElement(ln_Counter).RRJ_FREE_TEXT1, '@I_AMOUNT', ln_IntMin);
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
      end if;

      FWK_I_MGT_ENTITY.Release(lt_crud_def);
      ln_Counter                                             := ln_Counter + 1;
      t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
      t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
        PCS.PC_FUNCTIONS.TranslateWord
                                  ('[2]-[Fin] Importation des frais de la table ''ACT_REMINDER_EXP_CHARGES'' dans la table temporaire ''ACT_REM_EXP_CHARGES_TMP');
      t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    else
      ln_Treated                                             := 0;
      ln_Counter                                             := ln_Counter + 1;
      t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
      t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[3]- Aucun type de frais sélectionné');
      t_LogElement(ln_Counter).RRJ_LOG_TEXT                  :=
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1 ||
        chr(10) ||
        'select rbp.RBP_CHARGE_TYPE, rcr.RCR_REMINDER_MIN_AMOUNT, rcr.RCR_INTEREST_MIN_AMOUNT from ACT_REM_CHARGES_REBILLING rcr, ACT_REM_REBILLING_PAR rbp  where rcr.ACT_REM_CHARGES_REBILLING_ID = ' ||
        iRemChargesRebillingId ||
        ' and rbp.ACT_REM_REBILLING_PAR_ID = rcr.ACT_REM_REBILLING_PAR_ID';
    end if;

    ln_Counter                                             := ln_Counter + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Fin] Préparation des données');
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    return ln_Treated;
  end p_ImportCharges;

  /**
  * Description
  *   Contrôle des frais de relances sélectionnés
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param  iRemChargesRebillingId   Id lot de facturation
  */
  function p_VerifyCharges(iRemChargesRebillingId in number)
    return number
  is
    cursor crReminderDocument
    is
      select   ARC.PAR_DOCUMENT
             , TMP.ACT_REM_EXP_CHARGES_TMP_ID
             , TMP.ACT_REMINDER_EXP_CHARGES_ID
             , TMP.ACT_REM_CHARGES_REBILLING_ID
          from ACT_REM_EXP_CHARGES_TMP TMP
             , ACT_REMINDER_EXP_CHARGES ARC
         where TMP.ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingID
           and ARC.ACT_REMINDER_EXP_CHARGES_ID = TMP.ACT_REMINDER_EXP_CHARGES_ID
      order by TMP.ACT_REM_EXP_CHARGES_TMP_ID desc;

    cursor crChargesStructure(iParDocument ACT_REMINDER_EXP_CHARGES.PAR_DOCUMENT%type)
    is
      select RCT_ISE_CONTRACT
           , RCT_ISE_TARIFF
           , RCT_ISE_INVOICE_NUMBER
           , RCT_ISE_SUBSCRIPTION_NUMBER
        from ACT_REM_EXP_CHARGES_TMP
       where ACT_REM_CHARGES_REBILLING_ID = -1;

    type TCharges is table of crChargesStructure%rowtype
      index by binary_integer;

    tplCharges   TCharges;
    tplRemDoc    crReminderDocument%rowtype;
    lvChargesSQL varchar2(4000);
    lvAboSQL     varchar2(4000);
    lt_crud_def  FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    ln_Counter   number;
    ln_Treated   number;
    lv_DbLink    varchar2(32767);
    l_abo_ok     number;
  begin
    ln_Treated                                             := -1;
    ln_Counter                                             := t_LogElement.count + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Début] Contrôle des données');
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;

    --Récupération des données ISE se rapportant aux documents importés
    --Ne pas prendre les document dont le numéro se terminent par "-X"...
    open crReminderDocument;

    fetch crReminderDocument
     into tplRemDoc;

    if crReminderDocument%found then
      ln_Counter                                             := ln_Counter + 1;
      t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
      t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[2]-[Début] Contrôle des données importées');
      t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActRemExpChargesTmp, lt_crud_def);
      --Récupère le nom du Db link renseigné par la config.
      lv_DbLink                                              := pcs.pc_config.GetConfig('ACI_ISAG_KUNDE_DB_LINK');
      lvChargesSQL                                           :=
        ' select "id_subjekt"  , "subjekt_name" ' ||
        '      , "belegnrrech" , "id_sammelrechnung" ' ||
        '  from V_Prime_ISE_R_Facture@[PCS_ISAG_KUNDE_DB_LINK] ' ||
        '  where "id_rechnung" = :PAR_DOCUMENT';
      lvChargesSQL                                           := replace(lvChargesSQL, '[PCS_ISAG_KUNDE_DB_LINK]', lv_DbLink);

      while crReminderDocument%found loop
        tplCharges.delete;

        begin
          execute immediate lvChargesSQL
          bulk collect into tplCharges
                      using tplRemDoc.PAR_DOCUMENT;

          if tplCharges.count > 0 then
            for ln_RemCnt in tplCharges.first .. tplCharges.last loop
              --- Vérifiction que l'abonnement est valable
              lvAboSQL := 'select count("id_vertrag")  from V_Prime_Refact_Fact_prev@[PCS_ISAG_KUNDE_DB_LINK] where  "id_sammelrechnung" = '||  tplCharges(ln_RemCnt).RCT_ISE_SUBSCRIPTION_NUMBER;
              lvAboSQL := replace(lvAboSQL, '[PCS_ISAG_KUNDE_DB_LINK]', lv_DbLink);
              execute immediate lvAboSQL into l_abo_ok;


              FWK_I_MGT_ENTITY.Clear(lt_crud_def);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_EXP_CHARGES_TMP_ID', tplRemDoc.ACT_REM_EXP_CHARGES_TMP_ID);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REMINDER_EXP_CHARGES_ID', tplRemDoc.ACT_REMINDER_EXP_CHARGES_ID);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', tplRemDoc.ACT_REM_CHARGES_REBILLING_ID);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_ISE_INVOICE_NUMBER', tplCharges(ln_RemCnt).RCT_ISE_INVOICE_NUMBER);
              if l_abo_ok > 0 then
                FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_ISE_SUBSCRIPTION_NUMBER', tplCharges(ln_RemCnt).RCT_ISE_SUBSCRIPTION_NUMBER);
                FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_BILLING',1);
              else
                FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_ISE_SUBSCRIPTION_NUMBER', tplCharges(ln_RemCnt).RCT_ISE_SUBSCRIPTION_NUMBER||' - Abonnement pas valable');
                FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_CANCELLATION',1);
              end if;
              FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_ISE_CONTRACT', tplCharges(ln_RemCnt).RCT_ISE_CONTRACT);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_ISE_TARIFF', tplCharges(ln_RemCnt).RCT_ISE_TARIFF);
              FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
              ln_Counter                                             := ln_Counter + 1;
              t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
              t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
                                                       PCS.PC_FUNCTIONS.TranslateWord('[3]- Position ISE trouvée pour le document...')
                                                       || tplRemDoc.PAR_DOCUMENT;
              t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1 || chr(10) || lvChargesSQL;
              t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_LOG_TEXT || chr(10) || lvAboSQL;
              t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_LOG_TEXT ||CHR(10)||'Abonnement trouv? : '||(CASE WHEN l_abo_ok > 0 THEN 'Abonnement pas valable' else 'Abonnement pas valable' end);
              t_LogElement(ln_Counter).PAR_DOCUMENT                  := tplRemDoc.PAR_DOCUMENT;
              t_LogElement(ln_Counter).RCT_ISE_CONTRACT              := tplCharges(ln_RemCnt).RCT_ISE_CONTRACT;
              t_LogElement(ln_Counter).RCT_ISE_INVOICE_NUMBER        := tplCharges(ln_RemCnt).RCT_ISE_INVOICE_NUMBER;
              t_LogElement(ln_Counter).RCT_ISE_SUBSCRIPTION_NUMBER   :=
                                              substr(tplCharges(ln_RemCnt).RCT_ISE_SUBSCRIPTION_NUMBER || ' / ' || tplCharges(ln_RemCnt).RCT_ISE_TARIFF, 1, 50);
            end loop;
          else
            ln_Treated                                             := 0;
            ln_Counter                                             := ln_Counter + 1;
            t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
            t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
                                                PCS.PC_FUNCTIONS.TranslateWord('[2]- Pas de données ISE correspondant au document...')
                                                || tplRemDoc.PAR_DOCUMENT;
            t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1 || chr(10) || lvChargesSQL;
          end if;
        exception
          when others then
            ln_Treated                                             := -1;
            ln_Counter                                             := ln_Counter + 1;
            t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
            t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
              PCS.PC_FUNCTIONS.TranslateWord
                                   ('[!!!]- Erreurs lors du contrôle des données. Conrôler la connexion à '' V_Prime_ISE_R_Facture@[PCS_ISAG_KUNDE_DEB_LINK]''');
            t_LogElement(ln_Counter).RRJ_LOG_TEXT                  :=
                                  t_LogElement(ln_Counter).RRJ_FREE_TEXT1 || chr(10) || lvChargesSQL || sqlerrm || chr(10)
                                  || DBMS_UTILITY.format_error_backtrace;
        end;

        fetch crReminderDocument
         into tplRemDoc;
      end loop;

      ln_Treated                                             := 1;
      FWK_I_MGT_ENTITY.Release(lt_crud_def);
      ln_Counter                                             := ln_Counter + 1;
      t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
      t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[2]-[Fin] Contrôle des données importées');
      t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    else
      ln_Counter                                             := ln_Counter + 1;
      t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
      t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[2]- Pas de données à vérifier');
      t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    end if;

    ln_Counter                                             := ln_Counter + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Fin] Contrôle des données');
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    return ln_Treated;
  end p_VerifyCharges;

  /**
  * Description
  *   Traitement des position "A Annuler" de la table temporaire
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param
  */
  function p_CancelCharges(iRemChargesRebillingId in number)
    return number
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    ln_Counter  number;
    ln_Treated  number;
  begin
    ln_Treated                                             := -1;
    ln_Counter                                             := t_LogElement.count + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Début] Traitement des positions marquées ''Annulation''');
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActReminderExpCharges, lt_crud_def);

    begin
      for tplActiveRecord in (select   ARC.PAR_DOCUMENT
                                     , TMP.RCT_ISE_SUBSCRIPTION_NUMBER || ' / ' || (select PER_NAME
                                                                                      from PAC_PERSON
                                                                                     where PAC_PERSON_ID = ARC.PAC_CUSTOM_PARTNER_ID)
                                                                                                                                    RCT_ISE_SUBSCRIPTION_NUMBER
                                     , RCT_ISE_CONTRACT
                                     , RCT_ISE_INVOICE_NUMBER
                                     , TMP.ACT_REMINDER_EXP_CHARGES_ID
                                     , TMP.ACT_REM_CHARGES_REBILLING_ID
                                  from ACT_REM_EXP_CHARGES_TMP TMP
                                     , ACT_REMINDER_EXP_CHARGES ARC
                                 where TMP.ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingID
                                   and TMP.RCT_CANCELLATION = 1
                                   and ARC.ACT_REMINDER_EXP_CHARGES_ID = TMP.ACT_REMINDER_EXP_CHARGES_ID
                              order by TMP.ACT_REM_EXP_CHARGES_TMP_ID desc) loop
        FWK_I_MGT_ENTITY.clear(lt_crud_def);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REMINDER_EXP_CHARGES_ID', tplActiveRecord.ACT_REMINDER_EXP_CHARGES_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', tplActiveRecord.ACT_REM_CHARGES_REBILLING_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_REM_EXP_CHARGES_STATUS', '2');   --Annulé
        FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
        ln_Treated                                             := 1;
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[2]- Traitement document...') || tplActiveRecord.PAR_DOCUMENT;
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
        t_LogElement(ln_Counter).PAR_DOCUMENT                  := tplActiveRecord.PAR_DOCUMENT;
        t_LogElement(ln_Counter).RCT_ISE_CONTRACT              := tplActiveRecord.RCT_ISE_CONTRACT;
        t_LogElement(ln_Counter).RCT_ISE_INVOICE_NUMBER        := tplActiveRecord.RCT_ISE_INVOICE_NUMBER;
        t_LogElement(ln_Counter).RCT_ISE_SUBSCRIPTION_NUMBER   := substr(tplActiveRecord.RCT_ISE_SUBSCRIPTION_NUMBER,1,50);
        commit;
      end loop;

      if ln_Treated = -1 then
        ln_Treated                                             := 0;
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[2]- Aucune position à annuler ');
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
      end if;
    exception
      when others then
        ln_Treated                                             := -1;
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
                                                      PCS.PC_FUNCTIONS.TranslateWord('[!!!]- Erreurs lors du traitement des positions marquées ''Annulation''');
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  :=
                                                  t_LogElement(ln_Counter).RRJ_FREE_TEXT1 || chr(10) || sqlerrm || chr(10)
                                                  || DBMS_UTILITY.format_error_backtrace;
    end;

    FWK_I_MGT_ENTITY.Release(lt_crud_def);
    ln_Counter                                             := ln_Counter + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Fin] Traitement des positions marquées ''Annulation''');
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    return ln_Treated;
  end p_CancelCharges;

  /*
  * Description
  *   Mise à jour de la position de rappel traitée
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param
  */
  procedure p_TreatRemExpPosition(in_RemExpChargesId in number, in_RemChargesRebillingId in number, iv_Status varchar2, iv_Msg varchar2)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActReminderExpCharges, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REMINDER_EXP_CHARGES_ID', in_RemExpChargesId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', in_RemChargesRebillingId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'REM_TREATMENT_COMMENT', iv_Msg);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_REM_EXP_CHARGES_STATUS', iv_Status);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
    commit;
  end p_TreatRemExpPosition;

  /*
  * Description
  *   Mise à jour des indications "refacturé" des position du lot
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param iRemChargesRebillingId   Id lot de facturation
  */
  procedure p_UpdateRebillingPosition(iRemChargesRebillingId in number)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    --Déflaguer l'indicateur "Refacturation" des positions sélectionnées...et les marquer à nouveau sur la base des positions
    --effectivement traitées
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActRemExpChargesTmp, lt_crud_def);

    --Traiter toutes les positions du lot => déflaguer l'indicateur "Refacturation"
    for tplActiveRecord in (select   TMP.ACT_REMINDER_EXP_CHARGES_ID
                                   , TMP.ACT_REM_CHARGES_REBILLING_ID
                                from ACT_REM_EXP_CHARGES_TMP TMP
                               where TMP.ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingID
                                 and TMP.RCT_BILLING = 1
                            order by TMP.RCT_ISE_SUBSCRIPTION_NUMBER) loop
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REMINDER_EXP_CHARGES_ID', tplActiveRecord.ACT_REMINDER_EXP_CHARGES_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', iRemChargesRebillingID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_BILLING', '0');
      FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    end loop;

    --Traiter les positions du lot "Repris" => Flaguer l'indicateur "Refacturation" pour les positions reprises
    for tplActiveRecord in (select ACT_REMINDER_EXP_CHARGES_ID
                              from ACT_REMINDER_EXP_CHARGES
                             where ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingID
                               and C_REM_EXP_CHARGES_STATUS = '1') loop
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REMINDER_EXP_CHARGES_ID', tplActiveRecord.ACT_REMINDER_EXP_CHARGES_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', iRemChargesRebillingID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'RCT_BILLING', '1');
      FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    end loop;

    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end p_UpdateRebillingPosition;

  /*
  * Description
  *   Génération position de refacturation
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param
  */
  procedure p_execute_bill_charges(
    iRemChargesRebillingId in     number
  , iv_Abo                 in     varchar2
  , ingTarif               in     number
  , ingElement             in     number
  , iv_datDate             in     varchar2
  , strBase                in     varchar2
  , dblValeur              in     number
  , strDescription         in     varchar2 default null
  , strCompar              in     varchar2 default null
  , io_LogText             in out varchar2
  , o_invoiceNum           out    number
  )
  is
    ln_result number;
    lv_cmd    varchar2(32767);
    lv_DbLink varchar2(32767);
  begin
    ln_result     := -1;
    lv_cmd        :=
      'insert into "Prime_Indiv_Rechnungspos_PI"@[PCS_ISAG_KUNDE_DB_LINK]( ' ||
      '  "ID_Indiv_Rechnungspos"  , "ID_Leistkat" , "ID_Verrechnungstyp"    ' ||
      ', "Ruecklieferung" , "Datum" ,"MwStInkl" , "ID_Sammelrechnung"      ' ||
      ', "Abrechnungsart" , "Betrag" ';

    if (strDescription is not null) then
      lv_cmd  := lv_cmd || ', "VertragZusatztext" ';
    end if;

    if (strBase = 'Base') then
      lv_cmd  := lv_cmd || ',  "Basis" ';
    end if;

    if (strCompar is not null) then
      lv_cmd  := lv_cmd || ',  "Textvergleich" ';
    end if;

    lv_cmd        := lv_cmd || ' )  ' || ' values( 0 , :1 , :2 , 0 ,' || '''' || iv_datDate || '''' || ' , 0 , :4  , 1 , :5 ';

    if (strDescription is not null) then
      lv_cmd  := lv_cmd || ' , ''' || replace(strDescription, '''', '''''') || ' '' ';
    end if;

    if (strBase = 'Base') then
      lv_cmd  := lv_cmd || ', ''1'' ';
    end if;

    if (strCompar is not null) then
      lv_cmd  := lv_cmd || ' , ''' || replace(strCompar, '''', '''''') || ' '' ';
    end if;

    lv_cmd        := lv_cmd || ' )  ';
    lv_DbLink     := pcs.pc_config.GetConfig('ACI_ISAG_KUNDE_DB_LINK');
    lv_cmd        := replace(lv_cmd, '[PCS_ISAG_KUNDE_DB_LINK]', lv_DbLink);

    begin
      execute immediate lv_cmd
                  using in ingTarif, in ingElement, in iv_Abo, in dblValeur;

      commit;
      io_LogText  := io_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[] Génération position de refacturation');
      ln_result   := 0;
    exception
      when others then
        io_LogText  := io_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[] Erreur lors de la génératin de la position') || chr(10) || '     ' || lv_cmd;
        rollback;
    end;

    if ln_result = 0 then
      begin
        lv_DbLink   := pcs.pc_config.GetConfig('ACI_ISAG_FAKTURA_DB_LINK');
        lv_cmd      :=
          ' select *  from (select "ID_Indiv_Rechnungspos" from "Indiv_Rechnungspos"@[PCS_ISAG_FAKTURA_DB_LINK] ' ||
          ' where "ID_Sammelrechnung" = ' ||
          iv_Abo ||
          '   and "ID_Leistkat" = ' ||
          ingTarif ||

--                   '   and "LastDate" = '|| sysdate ||
          '   and "ID_Verrechnungstyp" = ' ||
          ingElement ||
          ' order by  "LastDate" desc ) where rownum = 1';
        lv_cmd      := replace(lv_cmd, '[PCS_ISAG_FAKTURA_DB_LINK]', lv_DbLink);

        execute immediate lv_cmd
                     into ln_result;

        commit;
        io_LogText  := io_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[] Récupération position générée...') || ln_result;
      exception
        when others then
          ln_result   := 0;
          io_LogText  :=
                   io_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[] Erreur lors de la recherche de la positon générée') || chr(10) || '     '
                   || lv_cmd;
          rollback;
      end;
    end if;

    o_invoiceNum  := ln_result;
  end p_execute_bill_charges;

  /*
  * Description
  *   Recherche date de facture
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param
  */
  procedure p_Get_billing_date(iSubscriptionNumber in varchar2, iContractNumber in varchar2, io_LogText in out varchar2, oBillingDate out varchar2)
  is
    lv_SQL     varchar2(32767);
    ld_MaxDate date;
    ld_Result  date;
    lv_DbLink  varchar2(32767);
  begin
    lv_DbLink     := pcs.pc_config.GetConfig('ACI_ISAG_KUNDE_DB_LINK');
    /*
    lv_SQL        :=
      'select "max_termin" from V_Prime_ISE_R_FactureDateMax@[PCS_ISAG_KUNDE_DB_LINK] ' ||
      '  where "id_sammelrechnung" = ' ||
      iSubscriptionNumber ||
      '    and "id_subjekt" = ' ||
      iContractNumber;
    */
    -- dgr recherche de la date de la facture possible.
    lv_SQL        :=
       'select  max( "Datum" ) + 1 from  V_Prime_Refact_Date_fact_imp@[PCS_ISAG_KUNDE_DB_LINK] '||
      ' where  "id_subjekt" = '||iContractNumber ||
     ' and "id_sammelrechnung" = '|| iSubscriptionNumber ;
    lv_SQL        := replace(lv_SQL, '[PCS_ISAG_KUNDE_DB_LINK]', lv_DbLink);

    begin
      execute immediate lv_SQL
                   into ld_Result;

      if ld_Result is null then
        ld_Result  := ld_MaxDate;
      end if;

      io_LogText  :=
        io_LogText ||
        chr(10) ||
        PCS.PC_FUNCTIONS.TranslateWord('[] Date de refacturation trouvée ...') ||
        ld_Result ||
        chr(10) ||
        '     ' ||
        PCS.PC_FUNCTIONS.TranslateWord('N° Abt / Contrat') ||
        chr(10) ||
        '     ' ||
        iSubscriptionNumber ||
        ' / ' ||
        iContractNumber;
    exception
      when others then
        ld_Result   := null;
        io_LogText  := io_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[] Date de refacturation non trouvée') || chr(10) || '     ' || lv_SQL;
    end;

    oBillingDate  := to_char(ld_Result, 'YYYYMMDD');
  end p_Get_billing_date;

  /*
  * Description
  *   Recherche du numéro de contrat et description liée
  * @created Sener Kalayci
  * @lastUpdate
  * @private
  * @param
  */
  procedure p_Get_Contract_Data(
    iRemChargesRebillingId in     number
  , iSubscriptionNumber    in     varchar2
  , iContractNumber        in     varchar2
  , iv_BillDate            in     varchar2
  , lvContractNum          out    varchar2
  , lvSubscrNumber         out    varchar2
  , io_LogText             in out varchar2
  )
  is
    lv_SQL    varchar2(32767);
    lv_DbLink varchar2(32767);
  begin
    lv_DbLink  := pcs.pc_config.GetConfig('ACI_ISAG_KUNDE_DB_LINK');
    lv_SQL     :=
      ' select bezeichnung, sammelrechnung  ' ||
      ' from (select C."bezeichnung" bezeichnung , C."id_sammelrechnung" sammelrechnung ,C."id_vertrag"' ||
      '       from V_Prime_ISE_R_Contrat@[PCS_ISAG_KUNDE_DB_LINK] C ,  ACT_REM_REBILLING_PAR PAR ' ||
      '       where ((to_number( PAR.DIC_ISAG_BILL_SERVICES1_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES2_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES3_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES4_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES5_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES6_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES7_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES8_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES9_ID) = C."statistikgruppe") or ' ||
      '              (to_number( PAR.DIC_ISAG_BILL_SERVICES10_ID) = C."statistikgruppe") ) ' ||
      '         and C."id_sammelrechnung" = ' ||
      iSubscriptionNumber ||
      '         and C."id_subjekt" = ' ||
      iContractNumber ||
      '         and par.ACT_REM_REBILLING_PAR_ID = (select ACT_REM_REBILLING_PAR_ID ' ||
      '                                               from ACT_REM_CHARGES_REBILLING ' ||
      '                                              where ACT_REM_CHARGES_REBILLING_ID = ' ||
      iRemChargesRebillingId ||
      ') ' ||
      '         and to_date(''' ||
      iv_BillDate ||
      ''',''YYYYMMDD'') >= to_date(C."gueltigvon" , ''YYYYMMDD'')  ' ||
      '         and (to_date(''' ||
      iv_BillDate ||
      ''',''YYYYMMDD'') <=  to_date(C."gueltigbis" , ''YYYYMMDD'')  OR C. "gueltigbis" is null)' ||
      '       order by C."statistikgruppe", C."id_vertrag")' ||
      ' where rownum = 1';
    lv_SQL     := replace(lv_SQL, '[PCS_ISAG_KUNDE_DB_LINK]', lv_DbLink);

    begin
      execute immediate lv_SQL
                   into lvContractNum
                      , lvSubscrNumber;

      io_LogText  :=
        io_LogText ||
        chr(10) ||
        PCS.PC_FUNCTIONS.TranslateWord('[] Contrat trouvé...') ||
        lvContractNum ||
        chr(10) ||
        '     ' ||
        PCS.PC_FUNCTIONS.TranslateWord(' N° Abt / Contrat / Date') ||
        chr(10) ||
        '     ' ||
        iSubscriptionNumber ||
        ' / ' ||
        iContractNumber ||
        ' / ' ||
        iv_BillDate;
    exception
      when others then
        io_LogText  := io_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[] Contrat non trouvé') || chr(10) || '     ' || lv_SQL;
    end;
  end p_Get_Contract_Data;

  /**
  * Description
  *   Traitement des position sélectionnées de la table temporaire
  *   => Refacturation des frais sélectionnée
  * @created Sener Kalayci
  * @LastUpdate
  * @param  iRemChargesRebillingId   Id lot de facturation
  */
  function p_BillCharges(iRemChargesRebillingId in number)
    return number
  is
    tplBillParams     ACT_REM_REBILLING_PAR%rowtype;
    lnInvoiceNum      number;
    lnChargeAmount    number;
    lnInterestAmount  number;
    lvElement         ACT_REM_REBILLING_PAR.DIC_ISAG_BILL_ELEMENT1_ID%type;
    lvDescription     ACT_REM_REBILLING_PAR.RBP_BILL_LABEL_1%type;
    lvBase            ACT_REM_REBILLING_PAR.DIC_ISAG_BILL_AMOUNT1_ID%type;
    lvCompare         ACT_REM_REBILLING_PAR.RBP_TEXT_1%type;
    lbBillCharges     boolean;
    lbBillInterest    boolean;
    lvBillDate        varchar2(10);
    ln_Counter        number;
    ln_Treated        number;
    lv_LogText        ACT_REM_REBILLING_LOG.RRJ_LOG_TEXT%type;
    lv_FreeText       ACT_REM_REBILLING_LOG.RRJ_FREE_TEXT1%type;
    lv_RemMsg         ACT_REMINDER_EXP_CHARGES.REM_TREATMENT_COMMENT%type;
  begin
    ln_Treated                                             := -1;
    lv_LogText                                             := '';
    ln_Counter                                             := t_LogElement.count + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := '[1]-[Début] Refacturation des positions marquées ''Refacturer''';
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;

    --Paramètres de refacturation
    select *
      into tplBillParams
      from ACT_REM_REBILLING_PAR
     where ACT_REM_REBILLING_PAR_ID = (select ACT_REM_REBILLING_PAR_ID
                                         from ACT_REM_CHARGES_REBILLING
                                        where ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingId);

    begin
      --Traitement de tous les enregistrements de la table ACT_REM_EXP_CHARGES_TMP marqué "Refacturation"
      for tplCharges in (select   ARC.ACT_REMINDER_EXP_CHARGES_ID
                                , ARC.PAR_DOCUMENT
                                , ARC.REM_NUMBER
                                , (select PER_NAME
                                     from PAC_PERSON
                                    where PAC_PERSON_ID = ARC.PAC_CUSTOM_PARTNER_ID) PER_NAME
                                , nvl(TMP.RCT_CHARGE_AMOUNT, 0) RCT_CHARGE_AMOUNT
                                , nvl(TMP.RCT_INTEREST_AMOUNT, 0) RCT_INTEREST_AMOUNT
                                , TMP.RCT_ISE_INVOICE_NUMBER
                                , TMP.RCT_ISE_SUBSCRIPTION_NUMBER
                                , TMP.RCT_ISE_CONTRACT
                                , (select DOC_DOCUMENT_DATE
                                     from ACT_DOCUMENT RAP
                                    where RAP.ACT_DOCUMENT_ID = ARC.ACT_DOCUMENT_ID) RAP_DATE
                             from ACT_REM_EXP_CHARGES_TMP TMP
                                , ACT_REMINDER_EXP_CHARGES ARC
                            where TMP.ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingId
                              and TMP.RCT_BILLING = 1
                              and ARC.ACT_REMINDER_EXP_CHARGES_ID = TMP.ACT_REMINDER_EXP_CHARGES_ID
                         order by ACT_REM_EXP_CHARGES_TMP_ID desc) loop
        lv_LogText                                             := '';
        lv_FreeText                                            := '';
        lv_RemMsg                                              := '';
        lnInvoiceNum                                           := 0;
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := '[2]-[Début] Traitement document ' || tplCharges.PAR_DOCUMENT;
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
        t_LogElement(ln_Counter).PAR_DOCUMENT                  := tplCharges.PAR_DOCUMENT;
        t_LogElement(ln_Counter).RCT_ISE_CONTRACT              := tplCharges.RCT_ISE_CONTRACT;
        t_LogElement(ln_Counter).RCT_ISE_INVOICE_NUMBER        := tplCharges.RCT_ISE_INVOICE_NUMBER;
        t_LogElement(ln_Counter).RCT_ISE_SUBSCRIPTION_NUMBER   := substr(tplCharges.RCT_ISE_SUBSCRIPTION_NUMBER || ' / ' || tplCharges.PER_NAME, 1, 50);

        if tplCharges.RCT_ISE_INVOICE_NUMBER is not null then
          lnChargeAmount  := tplCharges.RCT_CHARGE_AMOUNT;
          lv_LogText      := PCS.PC_FUNCTIONS.TranslateWord('[]Montant de refacturation') || ' = ' || lnChargeAmount;

          if (tplCharges.REM_NUMBER < tplBillParams.RBP_REM_COUNT) then
            lnInterestAmount  := 0.00;
            lv_LogText        :=
                               lv_LogText || chr(10)
                               || PCS.PC_FUNCTIONS.TranslateWord('[]Nombre de rappel avant intérêt non atteint => Montant intérêt = 0.00');
          else
            lnInterestAmount  := tplCharges.RCT_INTEREST_AMOUNT;
            lv_LogText        := lv_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[]Montant intérêt') || ' = ' || lnInterestAmount;
          end if;

          lvElement       := '';
          lvDescription   := '';
          lvBase          := '';
          lvCompare       := '';

          if tplCharges.REM_NUMBER = 1 then
            lvElement      := tplBillParams.DIC_ISAG_BILL_ELEMENT1_ID;
            lvDescription  := tplBillParams.RBP_BILL_LABEL_1;
            lvBase         := tplBillParams.DIC_ISAG_BILL_AMOUNT1_ID;
            lvCompare      := tplBillParams.RBP_TEXT_1;
            lv_LogText     := lv_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[]N° de relance = 1');
          elsif tplCharges.REM_NUMBER = 2 then
            lvElement      := tplBillParams.DIC_ISAG_BILL_ELEMENT2_ID;
            lvDescription  := tplBillParams.RBP_BILL_LABEL_2;
            lvBase         := tplBillParams.DIC_ISAG_BILL_AMOUNT2_ID;
            lvCompare      := tplBillParams.RBP_TEXT_2;
            lv_LogText     := lv_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[]N° de relance = 2');
          elsif tplCharges.REM_NUMBER = 3 then
            lvElement      := tplBillParams.DIC_ISAG_BILL_ELEMENT3_ID;
            lvDescription  := tplBillParams.RBP_BILL_LABEL_3;
            lvBase         := tplBillParams.DIC_ISAG_BILL_AMOUNT3_ID;
            lvCompare      := tplBillParams.RBP_TEXT_3;
            lv_LogText     := lv_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[]N° de relance = 3');
          elsif tplCharges.REM_NUMBER = 4 then
            lvElement      := tplBillParams.DIC_ISAG_BILL_ELEMENT4_ID;
            lvDescription  := tplBillParams.RBP_BILL_LABEL_4;
            lvBase         := tplBillParams.DIC_ISAG_BILL_AMOUNT4_ID;
            lvCompare      := tplBillParams.RBP_TEXT_4;
            lv_LogText     := lv_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[]N° de relance = 4');
          end if;

          lbBillCharges   :=     (lnChargeAmount > 0.00)
                             and (lvElement <> ' ');
          lbBillInterest  :=     (lnInterestAmount > 0.00)
                             and (tplBillParams.DIC_ISAG_BILL_ELEMENT5_ID <> ' ');

          if lbBillCharges then
            lv_LogText  := lv_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[]Refacturation des frais');
            lv_LogText  :=
              lv_LogText ||
              chr(10) ||
              '     ' ||
              PCS.PC_FUNCTIONS.TranslateWord('Elément / Description sur facture / Montant facture / Comparaison de texte') ||
              chr(10) ||
              '     ' ||
              lvElement ||
              ' / ' ||
              lvDescription ||
              ' / ' ||
              lvBase ||
              ' / ' ||
              lvCompare ||
              chr(10);
          elsif lbBillInterest then
            lv_LogText  := lv_LogText || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('[]Refacturation des intérêts');
            lv_LogText  :=
              lv_LogText ||
              chr(10) ||
              '     ' ||
              PCS.PC_FUNCTIONS.TranslateWord('Elément / Description sur facture / Montant facture / Comparaison de texte') ||
              chr(10) ||
              '     ' ||
              tplBillParams.DIC_ISAG_BILL_ELEMENT5_ID ||
              ' / ' ||
              tplBillParams.RBP_BILL_LABEL_5 ||
              ' / ' ||
              tplBillParams.DIC_ISAG_BILL_AMOUNT5_ID ||
              ' / ' ||
              tplBillParams.RBP_TEXT_5 ||
              chr(10);
          else
            lv_LogText  :=
              lv_LogText ||
              chr(10) ||
              PCS.PC_FUNCTIONS.TranslateWord('[]Pas de refacturation des frais et intérêts, soit le montant = 0.00, soit l''élément est vide');
          end if;

          if    lbBillCharges
             or lbBillInterest then
            p_Get_billing_date(tplCharges.RCT_ISE_SUBSCRIPTION_NUMBER, tplCharges.RCT_ISE_CONTRACT, lv_LogText, lvBillDate);
           /*
            p_Get_Contract_Data(iRemChargesRebillingId
                              , tplCharges.RCT_ISE_SUBSCRIPTION_NUMBER
                              , tplCharges.RCT_ISE_CONTRACT
                              , lvBillDate
                              , lvContractNum
                              , lvSubscriptionNum
                              , lv_LogText
                               );
            */
          end if;

            if lbBillCharges then
              if lvDescription = '' then
                lvDescription  := 'Frais rappel no ' || tplCharges.REM_NUMBER || 'facture no @FAC';
              end if;

              if instr(lvDescription, '@FAC') > 0 then
                lvDescription  := replace(lvDescription, '@FAC', to_char(tplCharges.RCT_ISE_INVOICE_NUMBER) );
              end if;

              if instr(lvDescription, '@RAPPEL') > 0 then
                lvDescription  := replace(lvDescription, '@RAPPEL', TO_CHAR(tplCharges.RAP_DATE,'DD.MM.YYYY') );
              end if;

              if lvBase = 'Base' then
                lnChargeAmount  := null;   --'c'est IS-E qui détermine le prix et non l'ERP
              end if;

              --Ajouter dans IS-E
              p_execute_bill_charges(iRemChargesRebillingId
                                   , tplCharges.RCT_ISE_SUBSCRIPTION_NUMBER
                                   , tplBillParams.DIC_ISAG_BILL_TARIFF_ID
                                   , lvElement
                                   , lvBillDate
                                   , lvBase
                                   , lnChargeAmount
                                   , lvDescription
                                   , lvCompare
                                   , lv_LogText
                                   , lnInvoiceNum
                                    );

              if (lnInvoiceNum <= 0) then
                lv_RemMsg  := PCS.PC_FUNCTIONS.TranslateWord('Position intérêt non générée.');
              end if;
            elsif lbBillInterest then
              lvElement      := tplBillParams.DIC_ISAG_BILL_ELEMENT5_ID;
              lvDescription  := tplBillParams.RBP_BILL_LABEL_5;
              lvBase         := tplBillParams.DIC_ISAG_BILL_AMOUNT5_ID;
              lvCompare      := tplBillParams.RBP_TEXT_5;

              if lvDescription = '' then
                lvDescription  := PCS.PC_FUNCTIONS.TranslateWord('Intérêts de retard, facture no @FAC');
              end if;

              --Insérer le numéro de facture s'il est demandé dans le texte (indiqué par @FAC)
              if instr(lvDescription, '@FAC') > 0 then
                lvDescription  := replace(lvDescription, '@FAC', to_char(tplCharges.RCT_ISE_INVOICE_NUMBER) );
              end if;

              if instr(lvDescription, '@RAPPEL') > 0 then
                lvDescription  := replace(lvDescription, '@RAPPEL', TO_CHAR(tplCharges.RAP_DATE,'DD.MM.YYYY') );
              end if;
              p_execute_bill_charges(iRemChargesRebillingId
                                   , tplCharges.RCT_ISE_SUBSCRIPTION_NUMBER
                                   , tplBillParams.DIC_ISAG_BILL_TARIFF_ID
                                   , lvElement
                                   , lvBillDate
                                   , lvBase
                                   , lnInterestAmount
                                   , lvDescription
                                   , lvCompare
                                   , lv_LogText
                                   , lnInvoiceNum
                                    );

              if (lnInvoiceNum <= 0) then
                lv_RemMsg  := PCS.PC_FUNCTIONS.TranslateWord('Position intérêt non générée.');
              end if;
            end if;
        else
          lv_RemMsg  := PCS.PC_FUNCTIONS.TranslateWord('Numéro de facture est vide.');
        end if;

        ln_Treated                                             := 1;

        if lnInvoiceNum > 0 then
          p_TreatRemExpPosition(tplCharges.ACT_REMINDER_EXP_CHARGES_ID, iRemChargesRebillingId, '1', PCS.PC_FUNCTIONS.TranslateWord('Traitement réussi') );
        else
          p_TreatRemExpPosition(tplCharges.ACT_REMINDER_EXP_CHARGES_ID, iRemChargesRebillingId, '3', lv_RemMsg);
        end if;

        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_LOG_TEXT || chr(10) || lv_LogText;
      end loop;

      --Aucune position sélectionnée
      if ln_Treated = -1 then
        ln_Treated                                             := 0;
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[2]- Aucune position à refacturer ');
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
      end if;
    exception
      when no_data_found then
        ln_Counter                                             := ln_Counter + 1;
        t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
        t_LogElement(ln_Counter).RRJ_FREE_TEXT1                :=
                                                         PCS.PC_FUNCTIONS.TranslateWord('[!!!]- Aucun paramètres de refacturation. Contrôler la configuration');
        t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    end;

    ln_Counter                                             := ln_Counter + 1;
    t_LogElement(ln_Counter).ACT_REM_CHARGES_REBILLING_ID  := iRemChargesRebillingId;
    t_LogElement(ln_Counter).RRJ_FREE_TEXT1                := PCS.PC_FUNCTIONS.TranslateWord('[1]-[Fin] Refacturation des positions marquées ''Refacturer''');
    t_LogElement(ln_Counter).RRJ_LOG_TEXT                  := t_LogElement(ln_Counter).RRJ_FREE_TEXT1;
    return ln_Treated;
  end p_BillCharges;

  /**
  * Description
  *   Flux de préparation des données
  * @public
  */
  procedure Import(iRemChargesRebillingId in number, oStatus out number)
  is
  begin
    oStatus  := -1;
    t_LogElement.delete;

    --Suppression des importations temporaires précédentes
    --=> Une position de charge ne peut être traitée que danS une seule importation !!!
    execute immediate 'truncate table ACT_REM_EXP_CHARGES_TMP';

    --Sélection et importations des positions de charges dans la table temporaire
    --de traitement
    oStatus  := p_ImportCharges(iRemChargesRebillingId);

    --Modification du statut du lot si importation réussie.
    -- 1 -> 2 ...En cours -> Préparé
    if oStatus > 0 then
      ChangeRebillingStatus(iRemChargesRebillingId, '2');
    end if;

    --Après chaque étape journaliser les événements.
    p_Journalize(iRemChargesRebillingId);
  end Import;

  /**
  * Description
  *   Flux de contrôle de données sélectionnées
  * @public
  */
  procedure Verify(iRemChargesRebillingId in number, oStatus out number)
  is
  begin
    oStatus  := -1;
    t_LogElement.delete;
    --Mise à jour de la table d'importation avec les informations correspondantes de la base ISE
    oStatus  := p_VerifyCharges(iRemChargesRebillingId);

    --Modification du statut du lot si vérification d'au moins une position de charge réussie
    -- 2 -> 3 ...Préparé -> Vérifié
    if oStatus > 0 then
      ChangeRebillingStatus(iRemChargesRebillingId, '3');
    end if;

    --Après chaque étape journaliser les événements.
    p_Journalize(iRemChargesRebillingId);
  end Verify;

  /**
  * Description
  *   Flux de refacturation des frais sélectionnée
  */
  procedure Bill(iRemChargesRebillingId in number, oStatus out number)
  is
  begin
    oStatus  := -1;
    t_LogElement.delete;
    --Annuler les positions marquées "A Annuler"
    oStatus  := p_CancelCharges(iRemChargesRebillingId);

    --    -1 - ('[!!!]- Erreurs lors du traitement des positions marquées ''Annulation''');
    --     0 - ('[2]- Aucune position à annuler ')
    --     1 - ('[2]- Traitement document...')
    if oStatus >= 0 then
      oStatus  := p_BillCharges(iRemChargesRebillingId);

      --  -1 - ('[!!!]- Aucun paramètres de refacturation. Contrôler la configuration');
      --   0 - ('[2]- Aucune position à refacturer')
      --   1 - ('[2]- Traitement réussi...')
      if oStatus >= 0 then
        --Mise à jour des indications "refacturé" des position du lot
        p_UpdateRebillingPosition(iRemChargesRebillingId);
        ChangeRebillingStatus(iRemChargesRebillingId, '4');
      end if;
    end if;

    --Après chaque étape journaliser les événements.
    p_Journalize(iRemChargesRebillingId);
  end Bill;

  /**
  * Description
  *   Mise à jour du statut du lot donné avec la valeur donnée
  */
  procedure ChangeRebillingStatus(iRemChargesRebillingId in number, iStatusValue in varchar2)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActRemChargesRebilling, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_REM_CHARGES_REBILLING_ID', iRemChargesRebillingId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_CHARGES_REBILLING_STATUS', iStatusValue);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end ChangeRebillingStatus;

  /**
  * Description
  *    Suppression des importations temporaires d'un lot.
  */
  procedure DeleteTmpPos(iRemChargesRebillingId in ACT_REM_CHARGES_REBILLING.ACT_REM_CHARGES_REBILLING_ID%type)
  as
  begin
    --Suppression des importations temporaires, uniquement pour un lot de statut = 2 (Prepared)
    for ltplRemChargesRebilling in (select 'x'
                                      from ACT_REM_CHARGES_REBILLING
                                     where ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingId
                                       and C_CHARGES_REBILLING_STATUS = '2') loop
      delete from ACT_REM_EXP_CHARGES_TMP
            where ACT_REM_CHARGES_REBILLING_ID = iRemChargesRebillingId;
    end loop;
  end DeleteTmpPos;
end ACT_PRC_REM_CHARGES_REBILLING;
