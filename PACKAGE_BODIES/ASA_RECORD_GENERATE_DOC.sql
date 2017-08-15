--------------------------------------------------------
--  DDL for Package Body ASA_RECORD_GENERATE_DOC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_RECORD_GENERATE_DOC" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Renvoie le champ à rechercher pour la description des positions
  */
  function GetDescriptionFromConfig(aConfigText in varchar2, aIndex number)
    return varchar2
  is
    pos1 number;
    pos2 number;
  begin
    if aIndex > 0 then
      Pos1  := 0;

      if aIndex > 1 then
        Pos1  := instr(aConfigText, ';', 1, aIndex - 1);
      end if;

      Pos1  := Pos1 + 1;
      Pos2  := instr(aConfigText, ';', 1, aIndex);

      if Pos2 = 0 then
        Pos2  := length(aConfigText) + 1;
      end if;

      return substr(aconfigtext, pos1, pos2 - pos1);
    else
      return '';
    end if;
  end GetDescriptionFromConfig;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Génération des documents logistiques
  */
  procedure GenerateDocuments(
    aASA_RECORD_ID     in     ASA_RECORD.ASA_RECORD_ID%type default null
  , aTypeGauge         in     varchar2
  , aDOC_GAUGE_ID      in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDMT_DATE_DOCUMENT in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aDMT_DATE_VALUE    in     DOC_DOCUMENT.DMT_DATE_VALUE%type
  , aDMT_DATE_DELIVERY in     DOC_DOCUMENT.DMT_DATE_DELIVERY%type
  , aAutoNum           in     number default 0
  , aGroupedByThird    in     number default 0
  , aError             out    varchar2
  )
  is
    tplASA_RECORD            ASA_RECORD%rowtype;
    vDOC_DOCUMENT_ID         DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vPDE_BASIS_DELAY         DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    vPOS_GROSS_UNIT_VALUE    DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    LocalCurrencyID          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vGCO_GOOD_ID             DOC_POSITION.GCO_GOOD_ID%type;
    vPOS_BASIS_QUANTITY      DOC_POSITION.POS_BASIS_QUANTITY%type;
    vPOS_UNIT_COST_PRICE     DOC_POSITION.POS_UNIT_COST_PRICE%type;
    vPC_APPLTXT_ID           ASA_RECORD_DOC_TEXT.PC_APPLTXT_ID%type;
    vATE_TEXT                ASA_RECORD_DOC_TEXT.ATE_TEXT%type;
    vConfigText              PCS.PC_CBASE.CBACVALUE%type;
    vPosTextBodyTextParam    varchar2(50);
    vPosGoodValBodyTextParam varchar2(50);
    vPosArtDescrParam        varchar2(50);
    vPosCompBodyTextParam    varchar2(50);
    vPosTaskBodyTextParam    varchar2(50);
    vPosTextBodyText         DOC_POSITION.POS_BODY_TEXT%type;
    vPosGoodValBodyText      DOC_POSITION.POS_BODY_TEXT%type;
    vCompTaskDescr           DOC_POSITION.POS_BODY_TEXT%type;
    FOldDescr2               varchar2(4000);
    vPAC_PARTNER_ID          ASA_RECORD.PAC_CUSTOM_PARTNER_ID%type;
    vACS_CURRENCY_ID         ASA_RECORD.ACS_FINANCIAL_CURRENCY_ID%type;
    vActivePartnerID         ASA_RECORD.PAC_CUSTOM_PARTNER_ID%type;
    vActiveCurrencyID        ASA_RECORD.ACS_FINANCIAL_CURRENCY_ID%type;
    vDOC_POSITION_ID         DOC_POSITION.DOC_POSITION_ID%type;
    vSQLDescr                varchar2(4000);
    vSQLComponents           varchar2(4000);
    vSQLTasks                varchar2(4000);
    vTaskRef                 FAL_TASK.TAS_REF%type;
    vC_GAUGE_TYPE_POS        DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;

    type crCompTasks is ref cursor;

    cr_Comp                  crCompTasks;
    tplComp                  ASA_RECORD_COMP%rowtype;
    cr_Task                  crCompTasks;
    tplTask                  ASA_RECORD_TASK%rowtype;
  begin
    FoldDescr2                := '';

    -- en création depuis un seul dossier SAV, on ajoute l'ID du dossier SAV à la table des ID
    -- Pour la modification en série, l'ajout de tous les ID se fait depuis Delphi
    if aASA_RECORD_ID is not null then
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (aASA_RECORD_ID
                 , 'ASA_RECORD_ID'
                  );
    end if;

    vPAC_PARTNER_ID           := 0;
    vACS_CURRENCY_ID          := 0;
    LocalCurrencyID           := ACS_FUNCTION.GetLocalCurrencyID;

    -- Recherche de la configuration appropriée définissant les descriptions
    select pcs.PC_CONFIG.GetConfig(case aTypeGauge
                                     when 'gtyOffer' then 'ASA_OFFER_DESCRIPTIONS'
                                     when 'gtyOfferBill' then 'ASA_OFFER_BILL_DESCRIPTIONS'
                                     when 'gtyCmdC' then 'ASA_CMDC_DESCRIPTIONS'
                                     when 'gtyAttrib' then 'ASA_CMDC_DESCRIPTIONS'
                                     when 'gtyCmdS' then 'ASA_CMDS_DESCRIPTIONS'
                                     when 'gtyBill' then 'ASA_BILL_DESCRIPTIONS'
                                     when 'gtyNC' then 'ASA_NC_DESCRIPTIONS'
                                     when 'gtyBuLiv' then 'ASA_BULIV_DESCRIPTIONS'
                                     else ''
                                   end
                                  )
      into vConfigText
      from dual;

    -- Récupération des intitulés des champs nécessaires à l'initialisation des descriptions
    vPosTextBodyTextParam     := GetDescriptionFromConfig(vConfigText, 1);
    vPosGoodValBodyTextParam  := GetDescriptionFromConfig(vConfigText, 2);
    vPosArtDescrParam         := GetDescriptionFromConfig(vConfigText, 3);
    vPosCompBodyTextParam     := GetDescriptionFromConfig(vConfigText, 4);
    vPosTaskBodyTextParam     := GetDescriptionFromConfig(vConfigText, 5);

    -- Code par défaut d'initialisation des descriptions article de la position logistique
    if vPosArtDescrParam is null then
      vPosArtDescrParam  := case
                             when(aTypeGauge <> 'gtyCmdS') then 'ASA'
                             else 'DOC'
                           end;
    end if;

    -- Commande SQL de recherche des descriptions
    vSQLDescr                 :=
      'select   ARE.* ' ||
      '       , RET.* ' ||
      '       , ARD1.ARD_SHORT_DESCRIPTION ARD_SHORT_DESCRIPTION_1 ' ||
      '       , ARD1.ARD_LONG_DESCRIPTION ARD_LONG_DESCRIPTION_1 ' ||
      '       , ARD1.ARD_FREE_DESCRIPTION ARD_FREE_DESCRIPTION_1 ' ||
      '       , ARD2.ARD_SHORT_DESCRIPTION ARD_SHORT_DESCRIPTION_2 ' ||
      '       , ARD2.ARD_LONG_DESCRIPTION ARD_LONG_DESCRIPTION_2 ' ||
      '       , ARD2.ARD_FREE_DESCRIPTION ARD_FREE_DESCRIPTION_2 ' ||
      '    from ASA_RECORD ARE ' ||
      '       , ASA_REP_TYPE RET ' ||
      '       , ASA_RECORD_DESCR ARD1 ' ||
      '       , ASA_RECORD_DESCR ARD2 ' ||
      '   where ARE.ASA_RECORD_ID = :ASA_RECORD_ID ' ||
      '     and ARE.ASA_RECORD_ID = ARD1.ASA_RECORD_ID(+) ' ||
      '     and ARD1.C_ASA_DESCRIPTION_TYPE(+) = ''1'' ' ||
      '     and ARD1.PC_LANG_ID(+) = case ' ||
      '                               when :aTypeGauge = ''gtyCmdS'' then ARE.PC_ASA_SUP_LANG_ID ' ||
      '                               else ARE.PC_ASA_CUST_LANG_ID ' ||
      '                             end ' ||
      '     and ARE.ASA_RECORD_ID = ARD2.ASA_RECORD_ID(+) ' ||
      '     and ARD2.C_ASA_DESCRIPTION_TYPE(+) = ''2'' ' ||
      '     and ARD2.PC_LANG_ID(+) = case ' ||
      '                               when :aTypeGauge = ''gtyCmdS'' then ARE.PC_ASA_SUP_LANG_ID ' ||
      '                               else ARE.PC_ASA_CUST_LANG_ID ' ||
      '                             end ' ||
      '     and ARE.ASA_REP_TYPE_ID = RET.ASA_REP_TYPE_ID(+) ' ||
      'order by case ' ||
      '           when :aTypeGauge = ''gtyCmdS'' then ARE.PAC_SUPPLIER_PARTNER_ID ' ||
      '           else ARE.PAC_CUSTOM_PARTNER_ID ' ||
      '         end ' ||
      '       , case ' ||
      '           when :aTypeGauge = ''gtyCmdS'' then ARE.ACS_ASA_SUP_FIN_CURR_ID ' ||
      '           else ARE.ACS_FINANCIAL_CURRENCY_ID ' ||
      '         end ' ||
      '       , ARE.ARE_NUMBER ';

    -- On vide la table des ID des documents générés (à imprimer)
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_DOCUMENT_ID';

    -- Recherche des infos des différents dossiers SAV
    for tplASA_RECORD in (select   are.ARE_PRICE_DEVIS_MB
                                 , case
                                     when aTypeGauge = 'gtyCmdS' then are.PAC_SUPPLIER_PARTNER_ID
                                     else are.PAC_CUSTOM_PARTNER_ID
                                   end PAC_PARTNER_ID
                                 , case
                                     when aTypeGauge = 'gtyCmdS' then are.ACS_ASA_SUP_FIN_CURR_ID
                                     else are.ACS_FINANCIAL_CURRENCY_ID
                                   end ACS_FINANCIAL_CURRENCY_ID
                                 , are.ACS_ASA_SUP_FIN_CURR_ID
                                 , are.ARE_UPD_DATE_C
                                 , are.ARE_CONF_DATE_C
                                 , are.ARE_REQ_DATE_C
                                 , are.ARE_SALE_PRICE_T_MB
                                 , are.ARE_MIN_SALE_PRICE_MB
                                 , are.ARE_MAX_SALE_PRICE_MB
                                 , are.ARE_SALE_PRICE_T_ME
                                 , are.ARE_MIN_SALE_PRICE_ME
                                 , are.ARE_MAX_SALE_PRICE_ME
                                 , are.ARE_COST_PRICE_T
                                 , are.GCO_BILL_GOOD_ID
                                 , are.ARE_REPAIR_QTY
                                 , are.ARE_GENERATE_BILL
                                 , are.GCO_DEVIS_BILL_GOOD_ID
                                 , are.ARE_UPD_DATE_S
                                 , are.ARE_CONF_DATE_S
                                 , are.ARE_REQ_DATE_S
                                 , are.ARE_COST_PRICE_S
                                 , are.GCO_SUPPLIER_GOOD_ID
                                 , are.ASA_RECORD_ID
                                 , are.ARE_PRICE_DEVIS_ME
                                 , are.ASA_RECORD_EVENTS_ID
                                 , case
                                     when aTypeGauge = 'gtyCmdS' then are.PC_ASA_SUP_LANG_ID
                                     else PC_ASA_CUST_LANG_ID
                                   end PC_LANG_ID
                                 , case
                                     when vPosArtDescrParam = 'ASA' then are.ARE_GCO_SHORT_DESCR
                                     else ''
                                   end ARE_GCO_SHORT_DESCR
                                 , case
                                     when vPosArtDescrParam = 'ASA' then are.ARE_GCO_LONG_DESCR
                                     else ''
                                   end ARE_GCO_LONG_DESCR
                                 , case
                                     when vPosArtDescrParam = 'ASA' then are.ARE_GCO_FREE_DESCR
                                     else ''
                                   end ARE_GCO_FREE_DESCR
                                 , are.ARE_LPOS_COMP_TASK
                                 , are.ARE_CUSTOMER_REF
                                 , are.C_ASA_SELECT_PRICE
                              from ASA_RECORD are
                                 , COM_LIST_ID_TEMP COM
                             where are.ASA_RECORD_ID = COM.COM_LIST_ID_TEMP_ID
                          order by case
                                     when aTypeGauge = 'gtyCmdS' then are.PAC_SUPPLIER_PARTNER_ID
                                     else are.PAC_CUSTOM_PARTNER_ID
                                   end
                                 , case
                                     when aTypeGauge = 'gtyCmdS' then are.ACS_ASA_SUP_FIN_CURR_ID
                                     else are.ACS_FINANCIAL_CURRENCY_ID
                                   end
                                 , are.ARE_NUMBER) loop
      -- Contrôle des données pour la commande Fournisseur
      if aTypeGauge = 'gtyCmds' then
        if tplASA_RECORD.PAC_PARTNER_ID is null then
          aError  := pcs.PC_PUBLIC.TranslateWord('Le fournisseur n''est pas défini');
        end if;

        if tplASA_RECORD.GCO_SUPPLIER_GOOD_ID is null then
          aError  := pcs.PC_PUBLIC.TranslateWord('L''article de commande au fournisseur n''est pas défini');
        end if;
      end if;

      -- Récupération du texte de pied 1 pour les documents générés
      begin
        select PC_APPLTXT_ID
             , ATE_TEXT
          into vPC_APPLTXT_ID
             , vATE_TEXT
          from ASA_RECORD_DOC_TEXT
         where ASA_RECORD_ID = tplASA_RECORD.ASA_RECORD_ID
           and C_ASA_GAUGE_TYPE =
                 (case aTypeGauge
                    when 'gtyOffer' then '12'   -- Devis
                    when 'gtyOfferBill' then '8_1'   -- Facture client pour devis
                    when 'gtyCmdC' then '6'   -- Accusé de réception
                    when 'gtyCmdS' then '1'   -- Commande fournisseur
                    when 'gtyBill' then '8'   -- Facture client
                    when 'gtyNC' then '9'   -- Note de crédit
                    when 'gtyBuLiv' then '7'   -- Bulletin de livraison
                    else ''
                  end
                 )
           and C_ASA_TEXT_TYPE = '5_1';   -- Texte de pied 1
      exception
        when no_data_found then
          null;
        when too_many_rows then
          raise_application_error(-20950, pcs.PC_PUBLIC.TranslateWord('Plusieurs ''Texte de pied 1'' trouvés pour ce type de document !') );
      end;

      if aError is null then
        -- S'il s'agit d'un facturation pour une offre refusée, on contrôle si le montant à facturer est supérieur à 0
        if not(     (aTypeGauge = 'gtyOfferBill')
               and (tplASA_RECORD.ARE_PRICE_DEVIS_MB = 0) ) then
          vActivePartnerID   := tplASA_RECORD.PAC_PARTNER_ID;
          vActiveCurrencyID  := tplASA_RECORD.ACS_FINANCIAL_CURRENCY_ID;

          if    (vPAC_PARTNER_ID <> vActivePartnerID)
             or (vACS_CURRENCY_ID <> vActiveCurrencyID)
             or (aGroupedByThird = 0)
             or (aTypeGauge = 'gtyAttrib') then
            -- Clôturer le document généré actif
            if vPAC_PARTNER_ID <> 0 then
              DOC_FINALIZE.FinalizeDocument(vDOC_DOCUMENT_ID, 1, 1, 1);
            end if;

            -- générer un nouveau document
            vDOC_DOCUMENT_ID  := null;
            GenerateDocumentASA(aRecordId          => tplASA_RECORD.ASA_RECORD_ID
                              , aDocumentId        => vDOC_DOCUMENT_ID
                              , aDocGaugeId        => aDOC_GAUGE_ID
                              , aDocumentDate      => aDMT_DATE_DOCUMENT
                              , aDateValue         => aDMT_DATE_VALUE
                              , aDateDelivery      => aDMT_DATE_DELIVERY
                              , aFootPcAppltxtId   => vPC_APPLTXT_ID
                              , aFootText          => vATE_TEXT
                              , aErrorMsg          => aError
                              , aAutoNum           => aAutoNum
                               );
            vPAC_PARTNER_ID   := tplASA_RECORD.PAC_PARTNER_ID;
            vACS_CURRENCY_ID  := tplASA_RECORD.ACS_FINANCIAL_CURRENCY_ID;

            if vDOC_DOCUMENT_ID is not null then
              insert into COM_LIST_ID_TEMP
                          (COM_LIST_ID_TEMP_ID
                         , LID_CODE
                          )
                   values (vDOC_DOCUMENT_ID
                         , 'DOC_DOCUMENT_ID'
                          );
            end if;
          end if;

          if     vDOC_DOCUMENT_ID is not null
             and aError is null then
            vPDE_BASIS_DELAY  := trunc(sysdate);

            if aTypeGauge <> 'gtyCmdS' then   -- Autre que commande au fournisseur
              if aTypeGauge <> 'gtyOfferBill' then   -- Autre que facture pour l'établissement du devis
                if not tplASA_RECORD.ARE_UPD_DATE_C is null then
                  vPDE_BASIS_DELAY  := tplASA_RECORD.ARE_UPD_DATE_C;
                elsif not tplASA_RECORD.ARE_CONF_DATE_C is null then
                  vPDE_BASIS_DELAY  := tplASA_RECORD.ARE_CONF_DATE_C;
                elsif not tplASA_RECORD.ARE_REQ_DATE_C is null then
                  vPDE_BASIS_DELAY  := tplASA_RECORD.ARE_REQ_DATE_C;
                end if;

                if pcs.PC_CONFIG.GetConfigUpper('ASA_RECALC_ME_PRICE_FOR_LOG') = 'TRUE' then
                  -- Recalcul du montant en monnaie étrangère
                  vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_SALE_PRICE_T_MB;

                  if     (tplASA_RECORD.ARE_MIN_SALE_PRICE_MB > 0)
                     and (vPOS_GROSS_UNIT_VALUE < tplASA_RECORD.ARE_MIN_SALE_PRICE_MB) then
                    vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_MIN_SALE_PRICE_MB;
                  end if;

                  if     (tplASA_RECORD.ARE_MAX_SALE_PRICE_MB > 0)
                     and (vPOS_GROSS_UNIT_VALUE > tplASA_RECORD.ARE_MAX_SALE_PRICE_MB) then
                    vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_MAX_SALE_PRICE_MB;
                  end if;

                  vPOS_GROSS_UNIT_VALUE  :=
                    ACS_FUNCTION.ConvertAmountForView(aAmount          => vPOS_GROSS_UNIT_VALUE
                                                    , aFromFinCurrId   => LocalCurrencyID
                                                    , aToFinCurrId     => vACS_CURRENCY_ID
                                                    , aDate            => aDMT_DATE_DOCUMENT
                                                    , aExchangeRate    => 0
                                                    , aBasePrice       => 0
                                                    , aRound           => 1
                                                    , aRateType        => 5
                                                     );
                else
                  vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_SALE_PRICE_T_ME;

                  if     (tplASA_RECORD.ARE_MIN_SALE_PRICE_ME > 0)
                     and (vPOS_GROSS_UNIT_VALUE < tplASA_RECORD.ARE_MIN_SALE_PRICE_ME) then
                    vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_MIN_SALE_PRICE_ME;
                  end if;

                  if     (tplASA_RECORD.ARE_MAX_SALE_PRICE_ME > 0)
                     and (vPOS_GROSS_UNIT_VALUE > tplASA_RECORD.ARE_MAX_SALE_PRICE_ME) then
                    vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_MAX_SALE_PRICE_ME;
                  end if;
                end if;

                vPOS_UNIT_COST_PRICE  := tplASA_RECORD.ARE_COST_PRICE_T;
                vGCO_GOOD_ID          := tplASA_RECORD.GCO_BILL_GOOD_ID;
                vPOS_BASIS_QUANTITY   := tplASA_RECORD.ARE_REPAIR_QTY;

                if     (tplASA_RECORD.ARE_GENERATE_BILL = 0)
                   and (pcs.PC_CONFIG.GetConfigUpper('ASA_GUARANTY_SHOW_PRICE') = 'FALSE') then
                  vPOS_GROSS_UNIT_VALUE  := 0;
                end if;
              else
                vPDE_BASIS_DELAY      := null;

                if (pcs.PC_CONFIG.GetConfigUpper('ASA_RECALC_ME_PRICE_FOR_LOG') = 'TRUE') then
                  -- Recalcul du montant en monnaie étrangère
                  vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_PRICE_DEVIS_MB;
                  vPOS_GROSS_UNIT_VALUE  :=
                    ACS_FUNCTION.ConvertAmountForView(aAmount          => vPOS_GROSS_UNIT_VALUE
                                                    , aFromFinCurrId   => LocalCurrencyID
                                                    , aToFinCurrId     => vACS_CURRENCY_ID
                                                    , aDate            => aDMT_DATE_DOCUMENT
                                                    , aExchangeRate    => 0
                                                    , aBasePrice       => 0
                                                    , aRound           => 1
                                                    , aRateType        => 5
                                                     );
                else
                  vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_PRICE_DEVIS_ME;
                end if;

                vPOS_UNIT_COST_PRICE  := 0;
                vGCO_GOOD_ID          := tplASA_RECORD.GCO_DEVIS_BILL_GOOD_ID;
                vPOS_BASIS_QUANTITY   := tplASA_RECORD.ARE_REPAIR_QTY;
              end if;
            else
              if not tplASA_RECORD.ARE_UPD_DATE_S is null then
                vPDE_BASIS_DELAY  := tplASA_RECORD.ARE_UPD_DATE_S;
              elsif not tplASA_RECORD.ARE_CONF_DATE_S is null then
                vPDE_BASIS_DELAY  := tplASA_RECORD.ARE_CONF_DATE_S;
              elsif not tplASA_RECORD.ARE_REQ_DATE_S is null then
                vPDE_BASIS_DELAY  := tplASA_RECORD.ARE_REQ_DATE_S;
              end if;

              vPOS_UNIT_COST_PRICE   := tplASA_RECORD.ARE_COST_PRICE_S;
              vGCO_GOOD_ID           := tplASA_RECORD.GCO_SUPPLIER_GOOD_ID;
              vPOS_BASIS_QUANTITY    := tplASA_RECORD.ARE_REPAIR_QTY;
              vPOS_GROSS_UNIT_VALUE  := tplASA_RECORD.ARE_COST_PRICE_S;

              if vACS_CURRENCY_ID <> LocalCurrencyID then
                vPOS_GROSS_UNIT_VALUE  :=
                  ACS_FUNCTION.ConvertAmountForView(aAmount          => vPOS_GROSS_UNIT_VALUE
                                                  , aFromFinCurrId   => LocalCurrencyID
                                                  , aToFinCurrId     => vACS_CURRENCY_ID
                                                  , aDate            => aDMT_DATE_DOCUMENT
                                                  , aExchangeRate    => 0
                                                  , aBasePrice       => 0
                                                  , aRound           => 1
                                                  , aRateType        => 5
                                                   );
              end if;
            end if;

            if aTypeGauge = 'gtyOffer' then
              --Màj date de validité du devis
              update ASA_RECORD
                 set ARE_VAL_DEVIS_DATE = trunc(sysdate) + pcs.PC_CONFIG.GetConfig('ASA_DEFAULT_DEVIS_VAL_NB_DAYS')
               where ASA_RECORD_ID = tplASA_RECORD.ASA_RECORD_ID;
            end if;

            -- Génération de la position de texte
            if not vPosTextBodyTextParam is null then
              begin
                execute immediate 'select ' || vPosTextBodyTextParam || ' from (' || vSQLDescr || ')'
                             into vPosTextBodyText
                            using tplASA_RECORD.ASA_RECORD_ID, aTypeGauge, aTypeGauge, aTypeGauge, aTypeGauge;
              exception
                when others then
                  vPosTextBodyText  := '';
              end;

              if nvl(vPosTextBodyText, '<PCS_EMPTY>') <> nvl(FOldDescr2, '<PCS_EMPTY>') then
                FOldDescr2  := vPosTextBodyText;

                if     (vPosTextBodyText is not null)
                   and (aTypeGauge <> 'gtyAttrib') then
                  GeneratePositionASA(aPositionId    => vDOC_POSITION_ID
                                    , aDocumentId    => vDOC_DOCUMENT_ID
                                    , aRecordId      => tplASA_RECORD.ASA_RECORD_ID
                                    , aGgeTypPos     => '4'
                                    , aPosBodyText   => vPosTextBodyText
                                    , aPosArtDescr   => vPosArtDescrParam
                                     );
                  -- On ne mémorise que les ID des positions articles
                  vDOC_POSITION_ID  := null;
                end if;
              end if;
            end if;

            if not vPosGoodValBodyTextParam is null then
              begin
                execute immediate 'select ' || vPosGoodValBodyTextParam || ' from (' || vSQLDescr || ')'
                             into vPosGoodValBodyText
                            using tplASA_RECORD.ASA_RECORD_ID, aTypeGauge, aTypeGauge, aTypeGauge, aTypeGauge;
              exception
                when others then
                  vPosTextBodyText  := '';
              end;
            end if;

            if aTypeGauge <> 'gtyCmdS' then   -- Autre que commande au fournisseur
              if        (aTypeGauge <> 'gtyAttrib')
                    and (tplASA_RECORD.ARE_LPOS_COMP_TASK = 0)
                 or (aTypeGauge = 'gtyOfferBill') then
                -- une position par dossier de réparation ou une facture pour l'établissement du devis
                if     (tplASA_RECORD.ARE_GENERATE_BILL = 0)
                   and (pcs.PC_CONFIG.GetConfigUpper('ASA_GUARANTY_SHOW_PRICE') = 'FALSE') then
                  vPOS_GROSS_UNIT_VALUE  := 0;
                end if;

                -- position article
                GeneratePositionASA(aPositionId      => vDOC_POSITION_ID
                                  , aDocumentId      => vDOC_DOCUMENT_ID
                                  , aGgeTypPos       => '1'
                                  , aGoodId          => vGCO_GOOD_ID
                                  , aPosBodyText     => vPosGoodValBodyText
                                  , aRecordId        => tplASA_RECORD.ASA_RECORD_ID
                                  , aPosRef          => tplASA_RECORD.ARE_CUSTOMER_REF
                                  , aPosShortDescr   => tplASA_RECORD.ARE_GCO_SHORT_DESCR
                                  , aPosLongDescr    => tplASA_RECORD.ARE_GCO_LONG_DESCR
                                  , aPosFreeDescr    => tplASA_RECORD.ARE_GCO_FREE_DESCR
                                  , aQuantity        => vPOS_BASIS_QUANTITY
                                  , aGrossUnitVal    => vPOS_GROSS_UNIT_VALUE
                                  , aCostPrice       => vPOS_UNIT_COST_PRICE
                                  , aDelay           => vPDE_BASIS_DELAY
                                  , aPosArtDescr     => vPosArtDescrParam
                                   );
              else   -- une position par composant / opération
                -- Composants
                if     (aTypeGauge = 'gtyOffer')
                   and (pcs.PC_CONFIG.GetConfigUpper('ASA_OFFER_OPTIONAL_GEN_DOC') = 'TRUE') then
                  vSQLComponents  :=
                    '  select ARC.* ' ||
                    '    from ASA_RECORD_COMP ARC ' ||
                    '   where ARC.ASA_RECORD_ID = :ASA_RECORD_ID ' ||
                    '     and ARC.ASA_RECORD_EVENTS_ID = :ASA_RECORD_EVENTS_ID ' ||
                    '     and ARC.C_ASA_GEN_DOC_POS <> ''0'' ' ||
                    'order by ARC.ARC_POSITION ';
                elsif(aTypeGauge = 'gtyAttrib') then
                  vSQLComponents  :=
                    '  select ARC.* ' ||
                    '    from ASA_RECORD_COMP ARC ' ||
                    '       , GCO_PRODUCT PDT ' ||
                    '   where ASA_RECORD_ID = :ASA_RECORD_ID ' ||
                    '     and PDT.GCO_GOOD_ID = ARC.GCO_COMPONENT_ID ' ||
                    '     and PDT.PDT_CALC_REQUIREMENT_MNGMENT = 1 ' ||
                    '     and ARC.DOC_ATTRIB_POSITION_ID is null ' ||
                    '     and ARC.ARC_CDMVT = 1 ' ||
                    '     and (   ARC.ARC_OPTIONAL = 0 ' ||
                    '          or ARC.C_ASA_ACCEPT_OPTION = ''2'') ' ||
                    '     and ARC.STM_COMP_STOCK_MVT_ID is null ' ||
                    '     and ASA_RECORD_EVENTS_ID = :ASA_RECORD_EVENTS_ID ' ||
                    'order by ARC_POSITION ';
                else
                  vSQLComponents  :=
                    '  select ARC.* ' ||
                    '    from ASA_RECORD_COMP ARC ' ||
                    '   where ARC.ASA_RECORD_ID = :ASA_RECORD_ID ' ||
                    '     and ARC.ASA_RECORD_EVENTS_ID = :ASA_RECORD_EVENTS_ID ' ||
                    '     and (   ARC.ARC_OPTIONAL = 0 ' ||
                    '          or ARC.C_ASA_ACCEPT_OPTION = ''2'') ' ||
                    '     and ARC.C_ASA_GEN_DOC_POS > ''0'' ' ||
                    'order by ARC.ARC_POSITION ';
                end if;

                open cr_Comp for vSQLComponents using tplASA_RECORD.ASA_RECORD_ID, tplASA_RECORD.ASA_RECORD_EVENTS_ID;

                fetch cr_Comp
                 into tplComp;

                if cr_Comp%found then
                  vCompTaskDescr  := pcs.PC_CONFIG.GetConfig('ASA_COMP_TITLE');

                  -- titre avant l'impression de la liste des composants
                  if     (vCompTaskDescr is not null)
                     and (aTypeGauge <> 'gtyAttrib') then
                    vCompTaskDescr  := pcs.PC_FUNCTIONS.TranslateWord(vCompTaskDescr, tplASA_RECORD.PC_LANG_ID);
                    GeneratePositionASA(aPositionId    => vDOC_POSITION_ID
                                      , aDocumentId    => vDOC_DOCUMENT_ID
                                      , aRecordId      => tplASA_RECORD.ASA_RECORD_ID
                                      , aGgeTypPos     => '4'
                                      , aPosBodyText   => vCompTaskDescr
                                      , aPosArtDescr   => vPosArtDescrParam
                                       );
                  end if;
                end if;

                -- Une position par composant
                while cr_Comp%found loop
                  if (vACS_CURRENCY_ID = LocalCurrencyID) then
                    vPOS_GROSS_UNIT_VALUE  := case
                                               when(tplASA_RECORD.C_ASA_SELECT_PRICE = '2') then tplComp.ARC_SALE_PRICE2
                                               else tplComp.ARC_SALE_PRICE
                                             end;
                  else
                    if (pcs.PC_CONFIG.GetConfigUpper('ASA_RECALC_ME_PRICE_FOR_LOG') = 'TRUE') then
                      vPOS_GROSS_UNIT_VALUE  := case
                                                 when(tplASA_RECORD.C_ASA_SELECT_PRICE = '2') then tplComp.ARC_SALE_PRICE2
                                                 else tplComp.ARC_SALE_PRICE
                                               end;
                      -- Recalcul du montant en monnaie étrangère
                      vPOS_GROSS_UNIT_VALUE  :=
                        ACS_FUNCTION.ConvertAmountForView(aAmount          => vPOS_GROSS_UNIT_VALUE
                                                        , aFromFinCurrId   => LocalCurrencyID
                                                        , aToFinCurrId     => vACS_CURRENCY_ID
                                                        , aDate            => aDMT_DATE_DOCUMENT
                                                        , aExchangeRate    => 0
                                                        , aBasePrice       => 0
                                                        , aRound           => 1
                                                        , aRateType        => 5
                                                         );
                    else
                      vPOS_GROSS_UNIT_VALUE  := case
                                                 when(tplASA_RECORD.C_ASA_SELECT_PRICE = '2') then tplComp.ARC_SALE_PRICE2_ME
                                                 else tplComp.ARC_SALE_PRICE_ME
                                               end;
                    end if;
                  end if;

                  vPOS_UNIT_COST_PRICE  := tplComp.ARC_COST_PRICE;
                  vGCO_GOOD_ID          := tplComp.GCO_COMPONENT_ID;
                  vPOS_BASIS_QUANTITY   := tplComp.ARC_QUANTITY;

                  if not vPosCompBodyTextParam is null then
                    begin
                      execute immediate 'select ' || vPosCompBodyTextParam || ' from (' || vSQLDescr || ')'
                                   into vPosGoodValBodyText
                                  using tplASA_RECORD.ASA_RECORD_ID, aTypeGauge, aTypeGauge, aTypeGauge, aTypeGauge;
                    exception
                      when others then
                        vPosGoodValBodyText  := '';
                    end;
                  end if;

                  -- Réparation sous garantie et le composant n'est pas optionnel
                  -- Composant sous garantie
                  -- Transfert sans prix
                  if    (     (pcs.PC_CONFIG.GetConfigUpper('ASA_GUARANTY_SHOW_PRICE') = 'FALSE')
                         and (    (     (tplASA_RECORD.ARE_GENERATE_BILL = 0)
                                   and (tplComp.ARC_OPTIONAL = 0) )
                              or (tplComp.ARC_GUARANTY_CODE = 1) )
                        )
                     or (tplComp.C_ASA_GEN_DOC_POS = '1') then
                    vPOS_GROSS_UNIT_VALUE  := 0;
                  end if;

                  -- position article
                  GeneratePositionASA(aPositionId      => vDOC_POSITION_ID
                                    , aDocumentId      => vDOC_DOCUMENT_ID
                                    , aGgeTypPos       => '1'
                                    , aGoodId          => vGCO_GOOD_ID
                                    , aPosBodyText     => vPosGoodValBodyText
                                    , aRecordId        => tplASA_RECORD.ASA_RECORD_ID
                                    , aRecCompId       => tplComp.ASA_RECORD_COMP_ID
                                    , aPosRef          => ''
                                    , aPosShortDescr   => case
                                        when(vPosArtDescrParam = 'ASA') then tplComp.ARC_DESCR
                                        else ''
                                      end
                                    , aPosLongDescr    => case
                                        when(vPosArtDescrParam = 'ASA') then tplComp.ARC_DESCR2
                                        else ''
                                      end
                                    , aPosFreeDescr    => case
                                        when(vPosArtDescrParam = 'ASA') then tplComp.ARC_DESCR3
                                        else ''
                                      end
                                    , aQuantity        => vPOS_BASIS_QUANTITY
                                    , aGrossUnitVal    => vPOS_GROSS_UNIT_VALUE
                                    , aCostPrice       => vPOS_UNIT_COST_PRICE
                                    , aDelay           => vPDE_BASIS_DELAY
                                    , aPosArtDescr     => vPosArtDescrParam
                                     );

                  -- Mise à jour du composant avec l'ID de la position du document d'attribution
                  if aTypeGauge = 'gtyAttrib' then
                    update ASA_RECORD_COMP
                       set DOC_ATTRIB_POSITION_ID = vDOC_POSITION_ID
                     where ASA_RECORD_COMP_ID = tplComp.ASA_RECORD_COMP_ID;
                  end if;

                  fetch cr_Comp
                   into tplComp;
                end loop;

                close cr_Comp;

                -- Opérations
                if (aTypeGauge <> 'gtyAttrib') then
                  if     (aTypeGauge = 'gtyOffer')
                     and (pcs.PC_CONFIG.GetConfigUpper('ASA_OFFER_OPTIONAL_GEN_DOC') = 'TRUE') then
                    vSQLTasks  :=
                      '  select RET.* ' ||
                      '    from ASA_RECORD_TASK RET ' ||
                      '   where RET.ASA_RECORD_ID = :ASA_RECORD_ID ' ||
                      '     and RET.ASA_RECORD_EVENTS_ID = :ASA_RECORD_EVENTS_ID ' ||
                      '     and RET.C_ASA_GEN_DOC_POS > ''0'' ' ||
                      'order by RET.RET_POSITION ';
                  else
                    vSQLTasks  :=
                      '  select RET.* ' ||
                      '    from ASA_RECORD_TASK RET ' ||
                      '   where RET.ASA_RECORD_ID = :ASA_RECORD_ID ' ||
                      '     and RET.ASA_RECORD_EVENTS_ID = :ASA_RECORD_EVENTS_ID ' ||
                      '     and (   RET.RET_OPTIONAL = 0 ' ||
                      '          or RET.C_ASA_ACCEPT_OPTION = ''2'') ' ||
                      '     and RET.C_ASA_GEN_DOC_POS > ''0'' ' ||
                      'order by RET.RET_POSITION ';
                  end if;

                  open cr_Task for vSQLTasks using tplASA_RECORD.ASA_RECORD_ID, tplASA_RECORD.ASA_RECORD_EVENTS_ID;

                  fetch cr_Task
                   into tplTask;

                  if cr_Task%found then
                    vCompTaskDescr  := pcs.PC_CONFIG.GetConfig('ASA_TASK_TITLE');

                    -- titre avant l'impression de la liste des opérations
                    if (vCompTaskDescr is not null) then
                      vCompTaskDescr  := pcs.PC_FUNCTIONS.TranslateWord(vCompTaskDescr, tplASA_RECORD.PC_LANG_ID);
                      GeneratePositionASA(aPositionId    => vDOC_POSITION_ID
                                        , aDocumentId    => vDOC_DOCUMENT_ID
                                        , aRecordId      => tplASA_RECORD.ASA_RECORD_ID
                                        , aGgeTypPos     => '4'
                                        , aPosBodyText   => vCompTaskDescr
                                        , aPosArtDescr   => vPosArtDescrParam
                                         );
                    end if;
                  end if;

                  -- Une position par opération
                  while cr_Task%found loop
                    if (vACS_CURRENCY_ID = LocalCurrencyID) then
                      vPOS_GROSS_UNIT_VALUE  := case
                                                 when(tplASA_RECORD.C_ASA_SELECT_PRICE = '2') then tplTask.RET_SALE_AMOUNT2
                                                 else tplTask.RET_SALE_AMOUNT
                                               end;
                    else
                      if (pcs.PC_CONFIG.GetConfigUpper('ASA_RECALC_ME_PRICE_FOR_LOG') = 'TRUE') then
                        vPOS_GROSS_UNIT_VALUE  := case
                                                   when(tplASA_RECORD.C_ASA_SELECT_PRICE = '2') then tplTask.RET_SALE_AMOUNT2
                                                   else tplTask.RET_SALE_AMOUNT
                                                 end;
                        -- Recalcul du montant en monnaie étrangère
                        vPOS_GROSS_UNIT_VALUE  :=
                          ACS_FUNCTION.ConvertAmountForView(aAmount          => vPOS_GROSS_UNIT_VALUE
                                                          , aFromFinCurrId   => LocalCurrencyID
                                                          , aToFinCurrId     => vACS_CURRENCY_ID
                                                          , aDate            => aDMT_DATE_DOCUMENT
                                                          , aExchangeRate    => 0
                                                          , aBasePrice       => 0
                                                          , aRound           => 1
                                                          , aRateType        => 5
                                                           );
                      else
                        vPOS_GROSS_UNIT_VALUE  := case
                                                   when(tplASA_RECORD.C_ASA_SELECT_PRICE = '2') then tplTask.RET_SALE_AMOUNT2_ME
                                                   else tplTask.RET_SALE_AMOUNT_ME
                                                 end;
                      end if;
                    end if;

                    vPOS_UNIT_COST_PRICE  := tplTask.RET_AMOUNT;
                    vGCO_GOOD_ID          := tplTask.GCO_BILL_GOOD_ID;

                    if not vPosTaskBodyTextParam is null then
                      begin
                        execute immediate 'select ' || vPosTaskBodyTextParam || ' from (' || vSQLDescr || ')'
                                     into vPosGoodValBodyText
                                    using tplASA_RECORD.ASA_RECORD_ID, aTypeGauge, aTypeGauge, aTypeGauge, aTypeGauge;
                      exception
                        when others then
                          vPosGoodValBodyText  := '';
                      end;
                    end if;

                    if (pcs.PC_CONFIG.GetConfigUpper('ASA_OPER_UNIT_SALE_PRICE') = 'FALSE') then
                      --Le Prix de vente / opération est le prix de vente total de l'opération
                      vPOS_BASIS_QUANTITY  := 1;
                    else
                      if tplTask.RET_FINISHED = 1 then
                        --Si l'opération est terminée, le calcul du prix exploite le temps utilisé
                        vPOS_BASIS_QUANTITY  := tplTask.RET_TIME_USED;
                      else
                        if (tplTask.RET_TIME_USED > 0) then
                          vPOS_BASIS_QUANTITY  := tplTask.RET_TIME_USED;
                        else
                          vPOS_BASIS_QUANTITY  := tplTask.RET_TIME;
                        end if;
                      end if;

                      -- La saisie des temps se fait en minutes ou en heure en fonction du code PPS_WORK_UNIT,
                      -- les taux sont saisis en heure, ainsi si la saisie se fait en minute il faut diviser le temps
                      -- par 60 avant de le multiplier par le taux
                      if pcs.PC_CONFIG.GetConfigUpper('PPS_WORK_UNIT') = 'M' then
                        vPOS_BASIS_QUANTITY  := vPOS_BASIS_QUANTITY / 60;
                      end if;
                    end if;

                    -- Réparation sous garantie et l'opération n'est pas optionnelle
                    -- Opération sous garantie
                    -- Transfert sans prix
                    if    (     (pcs.PC_CONFIG.GetConfigUpper('ASA_GUARANTY_SHOW_PRICE') = 'FALSE')
                           and (    (     (tplASA_RECORD.ARE_GENERATE_BILL = 0)
                                     and (tplTask.RET_OPTIONAL = 0) )
                                or (tplTask.RET_GUARANTY_CODE = 1) )
                          )
                       or (tplTask.C_ASA_GEN_DOC_POS = '1') then
                      vPOS_GROSS_UNIT_VALUE  := 0;
                    end if;

                    -- position article
                    select max(TAS_REF)
                      into vTaskRef
                      from FAL_TASK
                     where FAL_TASK_ID = tplTask.FAL_TASK_ID;

                    -- si le bien n'est pas renseigné, génération d'une position valeur
                    if vGCO_GOOD_ID is not null then
                      vC_GAUGE_TYPE_POS  := '1';
                    else
                      vC_GAUGE_TYPE_POS  := '5';
                    end if;

                    GeneratePositionASA(aPositionId      => vDOC_POSITION_ID
                                      , aDocumentId      => vDOC_DOCUMENT_ID
                                      , aGgeTypPos       => vC_GAUGE_TYPE_POS
                                      , aGoodId          => vGCO_GOOD_ID
                                      , aPosBodyText     => vPosGoodValBodyText
                                      , aRecordId        => tplASA_RECORD.ASA_RECORD_ID
                                      , aRecTaskId       => tplTask.ASA_RECORD_TASK_ID
                                      , aPosRef          => vTaskRef
                                      , aPosShortDescr   => case
                                          when(vPosArtDescrParam = 'ASA') then tplTask.RET_DESCR
                                          else ''
                                        end
                                      , aPosLongDescr    => case
                                          when(vPosArtDescrParam = 'ASA') then tplTask.RET_DESCR2
                                          else ''
                                        end
                                      , aPosFreeDescr    => case
                                          when(vPosArtDescrParam = 'ASA') then tplTask.RET_DESCR3
                                          else ''
                                        end
                                      , aQuantity        => vPOS_BASIS_QUANTITY
                                      , aGrossUnitVal    => vPOS_GROSS_UNIT_VALUE
                                      , aCostPrice       => vPOS_UNIT_COST_PRICE
                                      , aDelay           => vPDE_BASIS_DELAY
                                      , aPosArtDescr     => vPosArtDescrParam
                                       );

                    fetch cr_Task
                     into tplTask;
                  end loop;

                  close cr_Task;
                end if;
              end if;
            else   -- Commande au fournisseur
              GeneratePositionASA(aPositionId      => vDOC_POSITION_ID
                                , aDocumentId      => vDOC_DOCUMENT_ID
                                , aGgeTypPos       => '1'
                                , aGoodId          => vGCO_GOOD_ID
                                , aPosBodyText     => vPosGoodValBodyText
                                , aRecordId        => tplASA_RECORD.ASA_RECORD_ID
                                , aPosShortDescr   => tplASA_RECORD.ARE_GCO_SHORT_DESCR
                                , aPosLongDescr    => tplASA_RECORD.ARE_GCO_LONG_DESCR
                                , aPosFreeDescr    => tplASA_RECORD.ARE_GCO_FREE_DESCR
                                , aQuantity        => vPOS_BASIS_QUANTITY
                                , aGrossUnitVal    => vPOS_GROSS_UNIT_VALUE
                                , aCostPrice       => vPOS_UNIT_COST_PRICE
                                , aDelay           => vPDE_BASIS_DELAY
                                , aPosArtDescr     => vPosArtDescrParam
                                 );
            end if;

            -- Clôturer le document généré actif
            if vDOC_DOCUMENT_ID > 0 then
              DOC_FINALIZE.FinalizeDocument(vDOC_DOCUMENT_ID, 1, 1, 1);
            end if;

            if vDOC_POSITION_ID is not null then
              if aTypeGauge <> 'gtyAttrib' then
                -- Mise à jour du flux du dossier SAV
                update ASA_RECORD_EVENTS
                   set DOC_DOCUMENT_ID = vDOC_DOCUMENT_ID
                     , DOC_POSITION_ID = vDOC_POSITION_ID
                 where ASA_RECORD_ID = tplASA_RECORD.ASA_RECORD_ID
                   and ASA_RECORD_EVENTS_ID = tplASA_RECORD.ASA_RECORD_EVENTS_ID;
              else
                -- Mise à jour du document d'attribution sur le dossier SAV
                update ASA_RECORD
                   set DOC_ATTRIB_DOCUMENT_ID = vDOC_DOCUMENT_ID
                 where ASA_RECORD_ID = tplASA_RECORD.ASA_RECORD_ID;
              end if;
            else
              DOC_DELETE.DeleteDocument(vDOC_DOCUMENT_ID, 0);

              if aTypeGauge <> 'gtyAttrib' then
                aError  := pcs.PC_PUBLIC.TranslateWord('Aucune position logistique générée, aucune document lié à l''évènement');
              end if;
            end if;   -- vDOC_POSITION_ID is not null
          end if;   -- vDOC_DOCUMENT_ID is not null and aError is null
        end if;   -- if not(     (aTypeGauge = 'gtyOfferBill') and (tplASA_RECORD.ARE_PRICE_DEVIS_MB = 0) ) then
      end if;   -- aError is null
    end loop;

    -- Réinitialisation de la table des ID de dossiers SAV
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'ASA_RECORD_ID';
  end GenerateDocuments;

  /**
  * Description
  *   Procédure de génération des documents à partir du module SAV avec récupération du message d'erreur éventuel.
  */
  procedure GenerateDocumentASA(
    aRecordId        in     DOC_DOCUMENT.ASA_RECORD_ID%type
  , aDocumentId      in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocGaugeId      in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDocumentDate    in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aDateValue       in     DOC_DOCUMENT.DMT_DATE_VALUE%type
  , aDateDelivery    in     DOC_DOCUMENT.DMT_DATE_DELIVERY%type
  , aFootPcAppltxtId in     ASA_RECORD_DOC_TEXT.PC_APPLTXT_ID%type
  , aFootText        in     ASA_RECORD_DOC_TEXT.ATE_TEXT%type
  , aErrorMsg        in out varchar2
  , aAutoNum         in     number default 0
  )
  is
    vAutoInc   number(1);
    vFreeNum   number(1);
    vRecordNum ASA_RECORD.ARE_NUMBER%type;
  begin
    Doc_Document_Generate.ResetDocumentInfo(Doc_Document_Initialize.DocumentInfo);
    Doc_Document_Initialize.DocumentInfo.CLEAR_DOCUMENT_INFO    := 0;
    Doc_Document_Initialize.DocumentInfo.USE_ASA_RECORD_ID      := 1;
    Doc_Document_Initialize.DocumentInfo.ASA_RECORD_ID          := aRecordId;
    Doc_Document_Initialize.DocumentInfo.USE_DMT_DATE_VALUE     := 1;
    Doc_Document_Initialize.DocumentInfo.DMT_DATE_VALUE         := aDateValue;
    Doc_Document_Initialize.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
    Doc_Document_Initialize.DocumentInfo.DMT_DATE_DELIVERY      := aDateDelivery;
    vAutoInc                                                    := 1;
    vFreeNum                                                    := 1;

    if aFootText is not null then
      Doc_Document_Initialize.DocumentInfo.USE_FOO_FOOT_TEXT   := 1;
      Doc_Document_Initialize.DocumentInfo.FOOT_PC_APPLTXT_ID  := aFootPcAppltxtId;
      Doc_Document_Initialize.DocumentInfo.FOO_FOOT_TEXT       := aFootText;
    end if;

    if (aAutoNum = 1) then
      select GAN.GAN_INCREMENT
           , GAN.GAN_FREE_NUMBER
        into vAutoInc
           , vFreeNum
        from DOC_GAUGE_NUMBERING GAN
           , DOC_GAUGE GAU
       where GAU.DOC_GAUGE_NUMBERING_ID = GAN.DOC_GAUGE_NUMBERING_ID
         and GAU.DOC_GAUGE_ID = aDocGaugeId;

      -- Numéro de document initialisé selon numéro du dossier SAV
      if     (vAutoInc = 0)
         and (vFreeNum = 0) then
        select ARE_NUMBER
          into vRecordNum
          from ASA_RECORD
         where ASA_RECORD_ID = aRecordId;

        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER  := vRecordNum;
      end if;
    end if;

    DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => aDocumentId
                                         , aMode            => '150'
                                         , aGaugeID         => aDocGaugeId
                                         , aDocDate         => aDocumentDate
                                         , aErrorMsg        => aErrorMsg
                                         , aDebug           => 0
                                          );

    if aErrorMsg is not null then
      aDocumentId  := null;
    else
      insert into ASA_BINDED_DOCUMENTS
                  (ASA_BINDED_DOCUMENTS_ID
                 , ASA_RECORD_ID
                 , C_ASA_REP_STATUS
                 , ABD_SEQ
                 , DOC_DOCUMENT_ID
                 , ABD_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , A.ASA_RECORD_ID
             , A.C_ASA_REP_STATUS
             , nvl(MAX_SEQ + 1, 1)
             , aDocumentID
             , sysdate
             , sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni
          from ASA_RECORD A
             , (select max(ABD_SEQ) MAX_SEQ
                  from ASA_BINDED_DOCUMENTS B
                 where B.ASA_RECORD_ID = aRecordID)
         where A.ASA_RECORD_ID = aRecordID;
    end if;
  end GenerateDocumentASA;

  /**
  * Description
  *   Procédure de génération des documents à partir du module SAV
  */
  procedure GenerateDocumentASA(
    aRecordId        in     DOC_DOCUMENT.ASA_RECORD_ID%type
  , aDocumentId      in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocGaugeId      in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDocumentDate    in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aDateValue       in     DOC_DOCUMENT.DMT_DATE_VALUE%type
  , aDateDelivery    in     DOC_DOCUMENT.DMT_DATE_DELIVERY%type
  , aFootPcAppltxtId in     ASA_RECORD_DOC_TEXT.PC_APPLTXT_ID%type
  , aFootText        in     ASA_RECORD_DOC_TEXT.ATE_TEXT%type
  , aAutoNum         in     number default 0
  )
  is
    errorMsg varchar2(2000);
  begin
    GenerateDocumentASA(aRecordId          => aRecordId
                      , aDocumentId        => aDocumentId
                      , aDocGaugeId        => aDocGaugeId
                      , aDocumentDate      => aDocumentDate
                      , aDateValue         => aDateValue
                      , aDateDelivery      => aDateDelivery
                      , aFootPcAppltxtId   => aFootPcAppltxtId
                      , aFootText          => aFootText
                      , aErrorMsg          => errorMsg
                      , aAutoNum           => aAutoNum
                       );
  end GenerateDocumentASA;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de recherche de la valeur unitaire brute, des délais et des textes selon le type de documents
  */
  procedure InitDatasAttrib(
    aRecCompId  in     ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type
  , aDateRef    in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aDelay      out    DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , aGoodPrice  out    DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , aBodyTxt    out    DOC_POSITION.POS_BODY_TEXT%type
  , aShortDescr out    DOC_POSITION.POS_SHORT_DESCRIPTION%type
  , aLongDescr  out    DOC_POSITION.POS_LONG_DESCRIPTION%type
  , aFreeDescr  out    DOC_POSITION.POS_FREE_DESCRIPTION%type
  )
  is
    cursor crASARecord(RecCompId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type)
    is
      select are.*
           , ARC.ARC_SALE_PRICE
           , ARC.ARC_SALE_PRICE2
           , ARC.ARC_SALE_PRICE_ME
           , ARC.ARC_SALE_PRICE2_ME
           , ARC.ARC_OPTIONAL
           , ARC.ARC_GUARANTY_CODE
           , ARC.C_ASA_GEN_DOC_POS
           , ARC.ARC_DESCR
           , ARC.ARC_DESCR2
           , ARC.ARC_DESCR3
        from ASA_RECORD are
           , ASA_RECORD_COMP ARC
       where ARC.ASA_RECORD_COMP_ID = RecCompId
         and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID;

    tplRecord crASARecord%rowtype;
    vConfig   PCS.PC_CBASE.CBACVALUE%type;
    vCfgValue varchar2(100);

    function GetConfigParam(aConfig in varchar2, aParam in number)
      return varchar2
    is
      vConfigValue pcs.pc_cbase.cbacvalue%type;
      vValue       pcs.pc_cbase.cbacvalue%type;
      vPos1        number(3);
      vPos2        number(3);
      vLength      number(3);
    begin
      vConfigValue  := pcs.pc_config.GetConfig(aConfig);

      if aParam > 0 then
        if aParam > 1 then
          vPos1  := instr(vConfigValue, ';', 1, aParam - 1) + 1;
        else
          vPos1  := 1;
        end if;

        vPos2    := instr(vConfigValue, ';', 1, aParam);

        if vPos2 = 0 then
          vPos2  := length(vConfigValue) + 1;
        end if;

        vLength  := vPos2 - vPos1;
        vValue   := substr(vConfigValue, vPos1, vLength);

        if vValue = vConfigValue then
          vValue  := null;
        end if;
      else
        vValue  := null;
      end if;

      return vValue;
    end GetConfigParam;
  begin
    open crASARecord(aRecCompId);

    fetch crASARecord
     into tplRecord;

    close crASARecord;

    -- Délai
    aDelay     :=
      DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate          => tplRecord.ARE_DATE_REG_REP
                                         , aCalcDays      => tplRecord.ARE_NB_DAYS_WAIT
                                         , aAdminDomain   => '7'
                                         , aThirdID       => tplRecord.PAC_CUSTOM_PARTNER_ID
                                         , aForward       => 1
                                          );

    -- Valeur unitaire brute
    if (tplRecord.ACS_FINANCIAL_CURRENCY_ID = Acs_Function.GetLocalCurrencyId) then
      if tplRecord.C_ASA_SELECT_PRICE = '2' then
        aGoodPrice  := tplRecord.ARC_SALE_PRICE2;
      else
        aGoodPrice  := tplRecord.ARC_SALE_PRICE;
      end if;
    else
      if (pcs.pc_config.GetConfigUpper('ASA_RECALC_ME_PRICE_FOR_LOG') = 'TRUE') then   -- Recalcul du montant en monnaie étrangère
        if tplRecord.C_ASA_SELECT_PRICE = '2' then
          aGoodPrice  := tplRecord.ARC_SALE_PRICE2;
        else
          aGoodPrice  := tplRecord.ARC_SALE_PRICE;
        end if;

        aGoodPrice  :=
          Acs_Function.ConvertAmountForView(aGoodPrice
                                          , Acs_Function.GetLocalCurrencyId   --Monnaie de base
                                          , tplRecord.ACS_FINANCIAL_CURRENCY_ID
                                          , trunc(aDateRef)   -- Date de référence
                                          , 0
                                          , 0
                                          , 1   -- Arrondi
                                          , 5
                                           );
      else
        if tplRecord.C_ASA_SELECT_PRICE = '2' then
          aGoodPrice  := tplRecord.ARC_SALE_PRICE2_ME;
        else
          aGoodPrice  := tplRecord.ARC_SALE_PRICE_ME;
        end if;
      end if;
    end if;

    -- Réparation sous garantie et ce n'est pas une option
    if     tplRecord.ARE_GENERATE_BILL = 0
       and pcs.pc_config.GetConfigUpper('ASA_GUARANTY_SHOW_PRICE') = 'FALSE'
       and tplRecord.ARC_OPTIONAL = 0 then
      aGoodPrice  := 0;
    -- Composant sous garantie
    elsif     tplRecord.ARC_GUARANTY_CODE = 1
          and pcs.pc_config.GetConfigUpper('ASA_GUARANTY_SHOW_PRICE') = 'FALSE' then
      aGoodPrice  := 0;
    -- Transfert de prix
    elsif tplRecord.C_ASA_GEN_DOC_POS = '1' then
      aGoodPrice  := 0;
    end if;

    -- Texte de corps
    aBodyTxt   := '';
    vCfgValue  := GetConfigParam('ASA_CMDC_DESCRIPTIONS', 2);

    if vCfgValue is not null then
      begin
        execute immediate 'select ' ||
                          vCfgValue ||
                          '  from (select   ARE.*' ||
                          '               , RET.*' ||
                          '               , ARD1.ARD_SHORT_DESCRIPTION ARD_SHORT_DESCRIPTION_1' ||
                          '               , ARD1.ARD_LONG_DESCRIPTION ARD_LONG_DESCRIPTION_1' ||
                          '               , ARD1.ARD_FREE_DESCRIPTION ARD_FREE_DESCRIPTION_1' ||
                          '               , ARD2.ARD_SHORT_DESCRIPTION ARD_SHORT_DESCRIPTION_2' ||
                          '               , ARD2.ARD_LONG_DESCRIPTION ARD_LONG_DESCRIPTION_2' ||
                          '               , ARD2.ARD_FREE_DESCRIPTION ARD_FREE_DESCRIPTION_2' ||
                          '            from ASA_RECORD ARE' ||
                          '               , ASA_REP_TYPE RET' ||
                          '               , ASA_RECORD_DESCR ARD1' ||
                          '               , ASA_RECORD_DESCR ARD2' ||
                          '           where ARE.ASA_RECORD_ID = ' ||
                          tplRecord.ASA_RECORD_ID ||
                          '             and ARE.ASA_RECORD_ID = ARD1.ASA_RECORD_ID(+)' ||
                          '             and ARD1.C_ASA_DESCRIPTION_TYPE(+) = ''1''' ||
                          '             and ARD1.PC_LANG_ID(+) = ARE.PC_ASA_CUST_LANG_ID' ||
                          '             and ARE.ASA_RECORD_ID = ARD2.ASA_RECORD_ID(+)' ||
                          '             and ARD2.C_ASA_DESCRIPTION_TYPE(+) = ''2''' ||
                          '             and ARD2.PC_LANG_ID(+) = ARE.PC_ASA_CUST_LANG_ID' ||
                          '             and ARE.ASA_REP_TYPE_ID = RET.ASA_REP_TYPE_ID(+))'
                     into aBodyTxt;
      exception
        when others then
          aBodyTxt  := '';
      end;
    end if;

    -- Quatrième paramètre de la config défini le Texte de corps de la position lié au composant
    vCfgValue  := GetConfigParam('ASA_CMDC_DESCRIPTIONS', 4);

    if vCfgValue is not null then
      begin
        execute immediate 'select ' || vCfgValue || ' from ASA_RECORD_COMP where ASA_RECORD_COMP_ID = ' || aRecCompId
                     into aBodyTxt;
      exception
        when others then
          aBodyTxt  := vCfgValue;
      end;
    end if;

    -- Descriptions du bien
    -- Troisième paramètre de la config
    vCfgValue  := GetConfigParam('ASA_CMDC_DESCRIPTIONS', 3);

    if vCfgValue is null then
      vCfgValue  := 'ASA';
    end if;

    if vCfgValue = 'ASA' then
      -- les descriptions des position article générées sont initialisées à partir
      -- des descriptions de l'article à réparer du dossier de réparation
      aShortDescr  := substr(tplRecord.ARC_DESCR, 0, 30);
      aLongDescr   := tplRecord.ARC_DESCR2;
      aFreeDescr   := tplRecord.ARC_DESCR3;

      if aShortDescr = '' then
        aShortDescr  := ' ';
      end if;

      if aLongDescr = '' then
        aLongDescr  := ' ';
      end if;

      if aFreeDescr = '' then
        aFreeDescr  := ' ';
      end if;
    else
      -- les descriptions des position article générées sont initialisées à partir
      -- des descriptions de l'article utilisé pour la création d'une position (DOC_POSITION, article de facturation)
      aShortDescr  := '';
      aLongDescr   := '';
      aFreeDescr   := '';
    end if;
  end InitDatasAttrib;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de génération des positions à partir du module SAV
  */
  procedure GeneratePositionASA(
    aPositionId    in out DOC_POSITION.DOC_POSITION_ID%type
  , aDocumentId    in     DOC_POSITION.DOC_DOCUMENT_ID%type
  , aGgeTypPos     in     DOC_POSITION.C_GAUGE_TYPE_POS%type
  , aGoodId        in     DOC_POSITION.GCO_GOOD_ID%type default null
  , aPosBodyText   in     DOC_POSITION.POS_BODY_TEXT%type default null
  , aRecordId      in     DOC_POSITION.ASA_RECORD_ID%type default null
  , aRecCompId     in     DOC_POSITION.ASA_RECORD_COMP_ID%type default null
  , aRecTaskId     in     DOC_POSITION.ASA_RECORD_TASK_ID%type default null
  , aPosRef        in     DOC_POSITION.POS_REFERENCE%type default null
  , aPosShortDescr in     DOC_POSITION.POS_SHORT_DESCRIPTION%type default null
  , aPosLongDescr  in     DOC_POSITION.POS_LONG_DESCRIPTION%type default null
  , aPosFreeDescr  in     DOC_POSITION.POS_FREE_DESCRIPTION%type default null
  , aQuantity      in     DOC_POSITION.POS_BASIS_QUANTITY%type default null
  , aGrossUnitVal  in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type default null
  , aCostPrice     in     DOC_POSITION.POS_UNIT_COST_PRICE%type default null
  , aDelay         in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aPosArtDescr   in     varchar2 default null
  )
  is
    vGoodId          GCO_GOOD.GCO_GOOD_ID%type;
    vDetailId        DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vPosNumber       DOC_POSITION.POS_NUMBER%type;
    vStockID         DOC_POSITION.STM_STOCK_ID%type;
    vLocationId      DOC_POSITION.STM_LOCATION_ID%type;
    gapMvtUtility    DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type;
    tmpGaugeType     DOC_GAUGE.C_GAUGE_TYPE%type;
    tmpAutoAttrib    DOC_GAUGE_STRUCTURED.GAS_AUTO_ATTRIBUTION%type;
    vCharactValue_1  ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
    vCharactValue_2  ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
    vCharactValue_3  ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
    vCharactValue_4  ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
    vCharactValue_5  ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
    ln_DescrInitMode number;
  begin
    aPositionId                                               := null;
    Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
    Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO  := 0;
    ln_DescrInitMode                                          := PCS.PC_CONFIG.GetConfig('ASA_DESCRIPTIONS_INIT_MODE');

    -- Dossier SAV
    if aRecordId is not null then
      Doc_Position_Initialize.PositionInfo.USE_ASA_RECORD_ID  := 1;
      Doc_Position_Initialize.PositionInfo.ASA_RECORD_ID      := aRecordId;
    end if;

    -- Composant SAV
    if not(   aRecCompId is null
           or aRecCompId = 0) then
      Doc_Position_Initialize.PositionInfo.USE_ASA_RECORD_COMP_ID  := 1;
      Doc_Position_Initialize.PositionInfo.ASA_RECORD_COMP_ID      := aRecCompId;
    end if;

    -- Opération SAV
    if not(   aRecTaskId is null
           or aRecTaskId = 0) then
      Doc_Position_Initialize.PositionInfo.USE_ASA_RECORD_TASK_ID  := 1;
      Doc_Position_Initialize.PositionInfo.ASA_RECORD_TASK_ID      := aRecTaskId;
    end if;

    -- Référence position
    if aPosRef is not null then
      Doc_Position_Initialize.PositionInfo.USE_POS_REFERENCE  := 1;
      Doc_Position_Initialize.PositionInfo.POS_REFERENCE      := aPosRef;
    end if;

    -- Description courte
    if    aPosShortDescr is not null
       or (    ln_DescrInitMode = 0
           and aPosArtDescr = 'ASA') then
      Doc_Position_Initialize.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
      Doc_Position_Initialize.PositionInfo.POS_SHORT_DESCRIPTION      := substr(aPosShortDescr, 1, 50);
    end if;

    -- Description longue
    if    aPosLongDescr is not null
       or (    ln_DescrInitMode = 0
           and aPosArtDescr = 'ASA') then
      Doc_Position_Initialize.PositionInfo.USE_POS_LONG_DESCRIPTION  := 1;
      Doc_Position_Initialize.PositionInfo.POS_LONG_DESCRIPTION      := aPosLongDescr;
    end if;

    -- Description libre
    if    aPosFreeDescr is not null
       or (    ln_DescrInitMode = 0
           and aPosArtDescr = 'ASA') then
      Doc_Position_Initialize.PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;
      Doc_Position_Initialize.PositionInfo.POS_FREE_DESCRIPTION      := aPosFreeDescr;
    end if;

    -- Numéro de position
    vPosNumber                                                := null;

    -- Récupère le stock et l'emplacement du gabarit position par défaut. Il prime sur le stock et l'emplacement du composant.
    -- Attention, l'utilisation du stock du mouvement prime également sur le composant.
    begin
      select GAP.STM_STOCK_ID
           , GAP.STM_LOCATION_ID
           , GAP.GAP_MVT_UTILITY
        into vStockId
           , vLocationId
           , gapMvtUtility
        from DOC_DOCUMENT DMT
           , DOC_GAUGE_POSITION GAP
       where DMT.DOC_DOCUMENT_ID = aDocumentID
         and GAP.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS = aGgeTypPos
         and GAP.GAP_DEFAULT = 1;
    exception
      when no_data_found then
        vStockId       := null;
        vLocationId    := null;
        gapMvtUtility  := 0;
    end;

    begin
      select ARC_POSITION
           , decode(gapMvtUtility, 0, nvl(vStockId, STM_COMP_STOCK_ID), vStockId)
           , decode(gapMvtUtility, 0, nvl(vLocationId, STM_COMP_LOCATION_ID), vLocationId)
           , ARC_CHAR1_VALUE
           , ARC_CHAR2_VALUE
           , ARC_CHAR3_VALUE
           , ARC_CHAR4_VALUE
           , ARC_CHAR5_VALUE
        into vPosNumber
           , vStockId
           , vLocationId
           , vCharactValue_1
           , vCharactValue_2
           , vCharactValue_3
           , vCharactValue_4
           , vCharactValue_5
        from ASA_RECORD_COMP
       where ASA_RECORD_COMP_ID = aRecCompId;
    exception
      when no_data_found then
        vPosNumber   := null;
        vStockId     := null;
        vLocationId  := null;
    end;

    -- PMAI : DEVASA-10552
    -- Il ne faut pas reprendre les numéros d'opération pour les insérer
    -- dans les positions du document. L'ordre doit être respecté, mais
    -- tout doit être renuméroté
    if vPosNumber is not null then
      Doc_Position_Initialize.PositionInfo.USE_POS_NUMBER  := 0;
    --Doc_Position_Initialize.PositionInfo.POS_NUMBER      := vPosNumber;
    end if;

    if aGoodId = 0 then
      vGoodId  := null;
    else
      vGoodId  := aGoodId;
    end if;

    Doc_Position_Generate.GeneratePosition(aPositionID       => aPositionId
                                         , aDocumentID       => aDocumentId
                                         , aPosCreateMode    => '150'
                                         , aTypePos          => aGgeTypPos
                                         , aGoodID           => vGoodId
                                         , aPosBodyText      => aPosBodyText
                                         , aBasisQuantity    => aQuantity
                                         , aUnitCostPrice    => aCostPrice
                                         , aGoodPrice        => aGrossUnitVal
                                         , aStockId          => vStockId
                                         , aLocationId       => vLocationId
                                         , aGenerateDetail   => 0
                                          );
    -- Génération du détail de la position
    vDetailId                                                 := null;
    Doc_Detail_Generate.GenerateDetail(aDetailId         => vDetailId
                                     , aPositionID       => aPositionId
                                     , aPdeCreateMode    => '150'
                                     , aBasisDelay       => aDelay
                                     , aInterDelay       => aDelay
                                     , aFinalDelay       => aDelay
                                     , aCharactValue_1   => vCharactValue_1
                                     , aCharactValue_2   => vCharactValue_2
                                     , aCharactValue_3   => vCharactValue_3
                                     , aCharactValue_4   => vCharactValue_4
                                     , aCharactValue_5   => vCharactValue_5
                                      );

      --Mise à jour automatique des attributions
    -- Recherche les infos au niveau du gabarit pour les attributions auto.
    select GAU.C_GAUGE_TYPE
         , GAS.GAS_AUTO_ATTRIBUTION
      into tmpGaugeType
         , tmpAutoAttrib
      from DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
         , DOC_DOCUMENT DOC
     where GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and DOC.DOC_DOCUMENT_ID = aDocumentID;

    -- teste si les conditions sont remplies pour créer automatiquement les attributions
    if     tmpGaugeType = '1'
       and tmpAutoAttrib = 1
       and aQuantity > 0 then
      -- création des attributions pour la positions créée
      Fal_Redo_Attribs.ReDoAttribsByDocOrPOS(null, aPositionID);
    end if;
  end GeneratePositionASA;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de mise à jour des positions du document de gestion des attributions associées au dossier SAV
  */
  procedure UpdateAttrib(aRecordID in ASA_RECORD.ASA_RECORD_ID%type)
  is
    cursor crComponent(RecordId in ASA_RECORD.ASA_RECORD_ID%type)
    is
      select are.DOC_ATTRIB_DOCUMENT_ID
           , ARC.DOC_ATTRIB_POSITION_ID
           , ARC.GCO_COMPONENT_ID
           , ARC.ASA_RECORD_COMP_ID
           , are.ASA_RECORD_ID
           , ARC.ARC_POSITION
           , ARC.ARC_QUANTITY
           , ARC.ARC_COST_PRICE
           , ARC.ARC_SALE_PRICE
           , DOC.DMT_DATE_DOCUMENT
        from ASA_RECORD_COMP ARC
           , ASA_RECORD are
           , GCO_GOOD GOO
           , GCO_PRODUCT PDT
           , DOC_DOCUMENT DOC
       where ARC.ASA_RECORD_ID = are.ASA_RECORD_ID
         and are.ASA_RECORD_ID = RecordId
         and GOO.GCO_GOOD_ID = ARC.GCO_COMPONENT_ID
         and ARC.ASA_RECORD_EVENTS_ID = are.ASA_RECORD_EVENTS_ID
         and PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and DOC.DOC_DOCUMENT_ID = are.DOC_ATTRIB_DOCUMENT_ID
         and PDT.PDT_CALC_REQUIREMENT_MNGMENT = 1   -- gestion des attributions au niveau du composant
         and ARC.ARC_CDMVT = 1   -- le composant génère un mouvement de stock
         and (   ARC.ARC_OPTIONAL = 0
              or ARC.C_ASA_ACCEPT_OPTION = '2')   -- dont l'option a été acceptée (si optionnel)
         and ARC.DOC_ATTRIB_POSITION_ID is null   -- le composant n'a pas de position d'attribution
         and ARC.STM_COMP_STOCK_MVT_ID is null;   -- le composant n'a pas été sortie du stock

    tplComponent crComponent%rowtype;

    cursor crDeletePos(RecordId in ASA_RECORD.ASA_RECORD_ID%type)
    is
      select POS.DOC_POSITION_ID
        from DOC_POSITION POS
           , ASA_RECORD are
       where POS.DOC_DOCUMENT_ID = are.DOC_ATTRIB_DOCUMENT_ID
         and are.ASA_RECORD_ID = RecordID
         and not exists(
               select ARC.DOC_ATTRIB_POSITION_ID
                 from ASA_RECORD_COMP ARC
                where ARC.ASA_RECORD_ID = are.ASA_RECORD_ID
                  and ARC.DOC_ATTRIB_POSITION_ID = POS.DOC_POSITION_ID
                  and ARC.ARC_CDMVT = 1
                  and STM_COMP_STOCK_MVT_ID is null);

    tplDeletePos crDeletePos%rowtype;
    vPositionId  DOC_POSITION.DOC_POSITION_ID%type;
    aDelay       DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    aGoodPrice   DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    aBodyTxt     DOC_POSITION.POS_BODY_TEXT%type;
    aPosRef      DOC_POSITION.POS_REFERENCE%type;
    aShortDescr  DOC_POSITION.POS_SHORT_DESCRIPTION%type;
    aLongDescr   DOC_POSITION.POS_LONG_DESCRIPTION%type;
    aFreeDescr   DOC_POSITION.POS_FREE_DESCRIPTION%type;
    vMaxDelay    ASA_RECORD.ARE_NB_DAYS_WAIT_COMP%type;
  begin
    -- Supprimer toutes les positions du document dont les attributions doivent être modifiées
    open crDeletePos(aRecordId);

    fetch crDeletePos
     into tplDeletePos;

    while crDeletePos%found loop
      Doc_Delete.DeletePosition(tplDeletePos.DOC_POSITION_ID, true);

      fetch crDeletePos
       into tplDeletePos;
    end loop;

    close crDeletePos;

    -- Pour chaque composant modifié, recréer la position avec attribution sur le document associé
    open crComponent(aRecordId);

    fetch crComponent
     into tplComponent;

    while crComponent%found loop
      if tplComponent.DOC_ATTRIB_DOCUMENT_ID is not null then
        vPositionId  := null;
        -- Recherche de la valeur unitaire brut, des délais et des textes à utiliser
        InitDatasAttrib(tplComponent.ASA_RECORD_COMP_ID, tplComponent.DMT_DATE_DOCUMENT, aDelay, aGoodPrice, aBodyTxt, aShortDescr, aLongDescr, aFreeDescr);
        -- Génération de la nouvelle position
        GeneratePositionASA(vPositionId
                          , tplComponent.DOC_ATTRIB_DOCUMENT_ID
                          , '1'
                          , tplComponent.GCO_COMPONENT_ID
                          , aBodyTxt
                          , tplComponent.ASA_RECORD_ID
                          , tplComponent.ASA_RECORD_COMP_ID
                          , null
                          , aPosRef
                          , aShortDescr
                          , aLongDescr
                          , aFreeDescr
                          , tplComponent.ARC_QUANTITY
                          , aGoodPrice
                          , tplComponent.ARC_COST_PRICE
                          , aDelay
                           );

        -- Mettre à jour le lien DOC_ATTRIB_POSITION_ID avec l'ID de la position créée
        update ASA_RECORD_COMP
           set (DOC_ATTRIB_POSITION_ID, GCO_CHAR1_ID, GCO_CHAR2_ID, GCO_CHAR3_ID, GCO_CHAR4_ID, GCO_CHAR5_ID, ARC_CHAR1_VALUE, ARC_CHAR2_VALUE, ARC_CHAR3_VALUE
              , ARC_CHAR4_VALUE, ARC_CHAR5_VALUE, A_IDMOD, A_DATEMOD) =
                 (select vPositionId
                       , nvl(SPO.GCO_CHARACTERIZATION_ID, GCO_CHAR1_ID)
                       , nvl(SPO.GCO_GCO_CHARACTERIZATION_ID, GCO_CHAR2_ID)
                       , nvl(SPO.GCO2_GCO_CHARACTERIZATION_ID, GCO_CHAR3_ID)
                       , nvl(SPO.GCO3_GCO_CHARACTERIZATION_ID, GCO_CHAR4_ID)
                       , nvl(SPO.GCO4_GCO_CHARACTERIZATION_ID, GCO_CHAR5_ID)
                       , nvl(SPO.SPO_CHARACTERIZATION_VALUE_1, ARC_CHAR1_VALUE)
                       , nvl(SPO.SPO_CHARACTERIZATION_VALUE_2, ARC_CHAR2_VALUE)
                       , nvl(SPO.SPO_CHARACTERIZATION_VALUE_3, ARC_CHAR3_VALUE)
                       , nvl(SPO.SPO_CHARACTERIZATION_VALUE_4, ARC_CHAR4_VALUE)
                       , nvl(SPO.SPO_CHARACTERIZATION_VALUE_5, ARC_CHAR5_VALUE)
                       , pcs.PC_I_LIB_SESSION.GetUserIni
                       , sysdate
                    from FAL_NETWORK_NEED FAN
                       , FAL_NETWORK_LINK FLN
                       , STM_STOCK_POSITION SPO
                       , DOC_POSITION_DETAIL PDE
                   where SPO.STM_STOCK_POSITION_ID(+) = FLN.STM_STOCK_POSITION_ID
                     and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                     and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                     and PDE.DOC_POSITION_ID = vPositionId)
         where ASA_RECORD_COMP_ID = tplComponent.ASA_RECORD_COMP_ID;

        -- Application des arrondis le cas échéant
        DOC_FINALIZE.FinalizeDocument(tplComponent.DOC_ATTRIB_DOCUMENT_ID, 1, 1, 1);
      end if;

      fetch crComponent
       into tplComponent;
    end loop;

    close crComponent;

    -- Mise à jour des délais d'attente composants suite aux nouvelles attributions éventuelles
    ASA_FUNCTIONS.InitNbDaysWaitComp(aRecordID, null, vMaxDelay);
  end UpdateAttrib;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de mise à jour des caractérisations d'un composant selon attribution
  */
  procedure UpdateCharact(aRecordCompID in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type)
  is
    vPosID  DOC_POSITION.DOC_POSITION_ID%type;
    VGoodId GCO_GOOD.GCO_GOOD_ID%type;
    rComp   ASA_RECORD_COMP%rowtype;
  begin
    begin
      select distinct nvl(FLN.STM_LOCATION_ID, FUS.STM_LOCATION_ID)
                    , LOC.STM_STOCK_ID
                    , nvl(SPO.GCO_CHARACTERIZATION_ID, ARC.GCO_CHAR1_ID)
                    , nvl(SPO.GCO_GCO_CHARACTERIZATION_ID, ARC.GCO_CHAR2_ID)
                    , nvl(SPO.GCO2_GCO_CHARACTERIZATION_ID, ARC.GCO_CHAR3_ID)
                    , nvl(SPO.GCO3_GCO_CHARACTERIZATION_ID, ARC.GCO_CHAR4_ID)
                    , nvl(SPO.GCO4_GCO_CHARACTERIZATION_ID, ARC.GCO_CHAR5_ID)
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_1, ARC_CHAR1_VALUE)
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_2, ARC_CHAR2_VALUE)
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_3, ARC_CHAR3_VALUE)
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_4, ARC_CHAR4_VALUE)
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_5, ARC_CHAR5_VALUE)
                    , pcs.PC_I_LIB_SESSION.GetUserIni
                    , sysdate
                 into rComp.STM_COMP_LOCATION_ID
                    , rComp.STM_COMP_STOCK_ID
                    , rComp.GCO_CHAR1_ID
                    , rComp.GCO_CHAR2_ID
                    , rComp.GCO_CHAR3_ID
                    , rComp.GCO_CHAR4_ID
                    , rComp.GCO_CHAR5_ID
                    , rComp.ARC_CHAR1_VALUE
                    , rComp.ARC_CHAR2_VALUE
                    , rComp.ARC_CHAR3_VALUE
                    , rComp.ARC_CHAR4_VALUE
                    , rComp.ARC_CHAR5_VALUE
                    , rComp.A_IDMOD
                    , rComp.A_DATEMOD
                 from FAL_NETWORK_NEED FAN
                    , FAL_NETWORK_SUPPLY FUS
                    , FAL_NETWORK_LINK FLN
                    , STM_STOCK_POSITION SPO
                    , DOC_POSITION_DETAIL PDE
                    , ASA_RECORD_COMP ARC
                    , STM_LOCATION LOC
                where SPO.STM_STOCK_POSITION_ID(+) = FLN.STM_STOCK_POSITION_ID
                  and FLN.FAL_NETWORK_NEED_ID = FAN.FAL_NETWORK_NEED_ID
                  and FLN.FAL_NETWORK_SUPPLY_ID = FUS.FAL_NETWORK_SUPPLY_ID(+)
                  and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                  and PDE.DOC_POSITION_ID = ARC.DOC_ATTRIB_POSITION_ID(+)
                  and ARC.ASA_RECORD_COMP_ID = aRecordCompID
                  and LOC.STM_LOCATION_ID = nvl(FLN.STM_LOCATION_ID, FUS.STM_LOCATION_ID);

      update ASA_RECORD_COMP
         set GCO_CHAR1_ID = rComp.GCO_CHAR1_ID
           , GCO_CHAR2_ID = rComp.GCO_CHAR2_ID
           , GCO_CHAR3_ID = rComp.GCO_CHAR3_ID
           , GCO_CHAR4_ID = rComp.GCO_CHAR4_ID
           , GCO_CHAR5_ID = rComp.GCO_CHAR5_ID
           , ARC_CHAR1_VALUE = rComp.ARC_CHAR1_VALUE
           , ARC_CHAR2_VALUE = rComp.ARC_CHAR2_VALUE
           , ARC_CHAR3_VALUE = rComp.ARC_CHAR3_VALUE
           , ARC_CHAR4_VALUE = rComp.ARC_CHAR4_VALUE
           , ARC_CHAR5_VALUE = rComp.ARC_CHAR5_VALUE
           , STM_COMP_STOCK_ID = rComp.STM_COMP_STOCK_ID
           , STM_COMP_LOCATION_ID = rComp.STM_COMP_LOCATION_ID
           , A_IDMOD = rComp.A_IDMOD
           , A_DATEMOD = rComp.A_DATEMOD
       where ASA_RECORD_COMP_ID = aRecordCompID;
    exception
      when no_data_found then
        null;
      when too_many_rows then
        select DOC_ATTRIB_POSITION_ID
             , GCO_COMPONENT_ID
          into vPosID
             , VGOODID
          from ASA_RECORD_COMP
         where ASA_RECORD_COMP_ID = ARECORDCOMPID;

        FAL_DELETE_ATTRIBS.Delete_All_Attribs(VGOODID, null, VPOSID);
        raise_application_error
                        (-20900
                       , pcs.PC_PUBLIC.TranslateWord('Aucune attribution n''a pu être effectuée !') ||
                         ' ' ||
                         pcs.PC_PUBLIC.TranslateWord
                                                   ('Les différentes attributions doivent avoir les mêmes valeurs de stock, emplacement et caractérisations.')
                        );
    end;
  end UpdateCharact;

  /**
  * Description
  *   Procédure de suppression de la position du document de gestion des attributions associées au composant du dossier SAV
  *   Attention, cette procédure doit être appeler uniquement en garantissant, dans la même transation, que la méthode UpdateAttrib
  *   est appelée ensuite.
  */
  procedure DeleteAttribComponent(aPositionID in ASA_RECORD_COMP.DOC_ATTRIB_POSITION_ID%type)
  is
  begin
    -- Supprime l'attribution éventuelle par l'effacement de la position liée.
    if aPositionID is not null then
      DOC_DELETE.DeletePosition(aPositionID, true);
    end if;
  end DeleteAttribComponent;
end ASA_RECORD_GENERATE_DOC;
