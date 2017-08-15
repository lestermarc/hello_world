--------------------------------------------------------
--  DDL for Package Body GAL_PROJECT_CONSOLIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PROJECT_CONSOLIDATION" 
is
  v_number_snapshot      integer;
  cprovactif             dic_gal_prj_category.dic_prj_activate_provision%type   := 0;
  cbulksize              pls_integer                                            := 1000;
  cfggal_snapshot_number varchar2(30)                                           := pcs.pc_config.getconfig('GAL_SNAPSHOT_NUMBER');
  -- Lecture des budgets
  c_gal_budget_line      varchar2(4000)
    := 'select   GAL_COST_CENTER_ID, GAL_BUDGET_PERIOD_ID ' ||
       '       , sum(BLI_BUDGET_QUANTITY) ' ||
       '       , sum(BLI_BUDGET_AMOUNT) ' ||
       '       , sum(BLI_LAST_ESTIMATION_QUANTITY) ' ||
       '       , sum(BLI_LAST_ESTIMATION_AMOUNT) ' ||
       '       , sum(BLI_REMAINING_QUANTITY) ' ||
       '       , sum(BLI_REMAINING_AMOUNT) ' ||
       '       , sum(BLI_HANGING_SPENDING_QUANTITY) ' ||
       '       , sum(BLI_HANGING_SPENDING_AMOUNT) ' ||
       '       , sum(BLI_REMAINING_AMOUNT_AT_DATE) ' ||
       '    from GAL_CONSO_BUDGET_LINE_TEMP ' ||
       '   where GAL_BUDGET_ID = :GAL_BUDGET_ID ' ||
       'group by GAL_COST_CENTER_ID, GAL_BUDGET_PERIOD_ID';
  --Lecture des dépenses détaillées
  c_gal_spending_detail  varchar2(4000)
    := 'select   GAL_COST_CENTER_ID, GAL_BUDGET_PERIOD_ID ' ||
       '       , sum(decode(nvl(GSD_WITH_QUANTITY_ACCUMULATION, 0), 0, null, GSD_COL1_QUANTITY) ) ' ||
       '       , sum(GSD_COL1_AMOUNT) ' ||
       '       , sum(decode(nvl(GSD_WITH_QUANTITY_ACCUMULATION, 0), 0, null, GSD_COL2_QUANTITY) ) ' ||
       '       , sum(GSD_COL2_AMOUNT) ' ||
       '       , sum(decode(nvl(GSD_WITH_QUANTITY_ACCUMULATION, 0), 0, null, GSD_COL3_QUANTITY) ) ' ||
       '       , sum(GSD_COL3_AMOUNT) ' ||
       '       , sum(decode(nvl(GSD_WITH_QUANTITY_ACCUMULATION, 0), 0, null, GSD_COL4_QUANTITY) ) ' ||
       '       , sum(GSD_COL4_AMOUNT) ' ||
       '       , sum(decode(nvl(GSD_WITH_QUANTITY_ACCUMULATION, 0), 0, null, GSD_COL5_QUANTITY) ) ' ||
       '       , sum(GSD_COL5_AMOUNT) ' ||
       '    from GAL_SPENDING_DETAIL ' ||
       '   where GAL_PROJECT_ID = :GAL_PROJECT_ID ' ||
       '     and GAL_BUDGET_ID = :GAL_BUDGET_ID ' ||
       '     and GAL_SNAPSHOT_ID = :GAL_SNAPSHOT_ID ' ||
       '   group by GAL_COST_CENTER_ID, GAL_BUDGET_PERIOD_ID';

  /**
  * procedure initRecordtable
  * Description
  *   Initilisation de la table variable globale contenant la liste des dossiers
  * @created fp 06.07.2007
  * @lastUpdate
  * @public
  * @param aDocRecordIdList : liste des dossiers
  */
  procedure InitTableDocRecord(iRecordList in ID_TABLE_TYPE)
  is
  begin
    delete from GAL_CONSO_DOC_RECORD_TEMP;

    insert into GAL_CONSO_DOC_RECORD_TEMP
                (DOC_RECORD_ID
                )
      select column_value
        from table(iRecordList);
  end InitTableDocRecord;

  /**
  * procedure initTableGood_To_Eliminate
  * Description
  *   bien de tape accompte que l'on ne prend pas en compte dans le suivi financier
  * liste tous les biens sur les doc défini comme gabarit d'acompte dans l'échpancier
    * @created hmo 23.05.08
  * @lastUpdate
  * @public
  */
  procedure inittable_is_acompte
  is
  begin
    delete      gal_conso_is_acompte_temp;

    insert into gal_conso_is_acompte_temp
                (gco_good_id
                )
      (select distinct (pos.gco_good_id)
                  from doc_position pos
                     , doc_document doc
                 where pos.doc_document_id = doc.doc_document_id
                   and pos.gco_good_id is not null
                   and doc.doc_gauge_id in(select doc_gauge_id
                                             from doc_gauge_invoice_expiry
                                            where c_invoice_expiry_doc_type = '1'
                                               or c_invoice_expiry_doc_type = '5') );

    update gal_conso_is_acompte_temp
       set doc_position_id = 0;
  end inittable_is_acompte;

   /**
  * procedure is_acompte
  * Description
  *  Détermine si un bien est un acompte depuis les gagbarits accompte des échéanciers
  * @created hmo 23.05.08
  * @lastUpdate
  * @public
  */
  procedure exclude_position
  is
  begin
    if v_gal_proc_conso_exclude_acpt is null then
      inittable_is_acompte;
    else
      sqlstatement  := 'BEGIN ' || trim(v_gal_proc_conso_exclude_acpt) || '(); END;';

      execute immediate sqlstatement;
    end if;
  end exclude_position;

  procedure insert_pos_not_confirmed(v_event_snapshotdate date, v_compta_snapshotdate date, v_cur_pos_prov_id doc_position.doc_position_id%type)
  is
    v_stock_id                    stm_stock.stm_stock_id%type;
    v_doc_record_id               doc_record.doc_record_id%type;
    v_prov_id_confirmed           doc_journal_detail.doc_journal_detail_id%type;
    v_doc_rec_id_doc_pos_id       varchar2(24)                                      := 0;
    v_inter_char                  varchar2(30);
    v_c_project_consolidation     doc_journal_detail.c_project_consolidation%type;
    v_c_invoice_expiry_input_type doc_document.c_invoice_expiry_input_type%type;
  begin
    for v_cur_pos_prov_tgt in (select   doc_journal_detail_prov_id
                                      , c_doc_journal_detail
                                      , djd_reversal_entry
                                      , djd_transaction_id
                                      , djp.doc_position_id
                                      , djp.doc_record_id
                                      , djp.pos_imputation
                                      , djp.c_project_consolidation
                                      , djp.djd_new_pos_balance_qty pos_balance_quantity
                                      , djp.doc_record_id || djp.doc_position_id c_test
                                      , doc_document_id
                                   from doc_journal_detail_prov djp
                                  where djp.doc_position_id = v_cur_pos_prov_id
                                    and djp.djd_journal_document_date <= v_compta_snapshotdate
                                    and djp.a_datecre <= v_event_snapshotdate
                               order by doc_journal_detail_prov_id desc) loop
      if v_doc_rec_id_doc_pos_id <> v_cur_pos_prov_tgt.c_test then
        -- le premier TGT_DATE porte des infos fausses dans le journal au niveau amount position -- pas nécessaire de tester ce cas, on va cherhcer l'info sur l'événememt suivant
        -- CONF_TGT ne nous intéresse pas
        if     v_cur_pos_prov_tgt.c_doc_journal_detail <> 'CONF_TGT'
           and v_cur_pos_prov_tgt.c_doc_journal_detail <> 'TGT_DATE' then
          v_c_project_consolidation  := v_cur_pos_prov_tgt.c_project_consolidation;

          begin
            select nvl(C_INVOICE_EXPIRY_INPUT_TYPE, 0)
              into v_c_invoice_expiry_input_type
              from doc_document
             where doc_document_id = v_cur_pos_prov_tgt.doc_document_id;
          exception
            when no_data_found then
              v_c_invoice_expiry_input_type  := 0;
          end;

          if v_cur_pos_prov_tgt.c_doc_journal_detail in('DELETE', 'CANCEL', 'BALANCE', 'BAL_EXT', 'CONFIRM') then
            v_doc_rec_id_doc_pos_id  := v_cur_pos_prov_tgt.c_test;
          -- traitement du cas de changement de dossier -> on a un update négatif. On peut avoir la même en cas d'update sur le même dossier mais
          -- avec un changement de date
          elsif     v_cur_pos_prov_tgt.c_doc_journal_detail = 'DISCHARGED'
                and v_c_project_consolidation <> 2
                and v_cur_pos_prov_tgt.pos_balance_quantity = 0
                and v_c_invoice_expiry_input_type = 0 then
            v_doc_rec_id_doc_pos_id  := v_cur_pos_prov_tgt.c_test;
          elsif     v_cur_pos_prov_tgt.c_doc_journal_detail = 'UPDATE'
                and v_cur_pos_prov_tgt.pos_balance_quantity = 0
                and v_c_project_consolidation <> 2
                and v_c_invoice_expiry_input_type = 0 then
            v_doc_rec_id_doc_pos_id  := v_cur_pos_prov_tgt.c_test;
          elsif     v_cur_pos_prov_tgt.c_doc_journal_detail = 'UPD_TGT'
                and v_cur_pos_prov_tgt.pos_balance_quantity = 0 then
            v_doc_rec_id_doc_pos_id  := v_cur_pos_prov_tgt.c_test;
          elsif     v_cur_pos_prov_tgt.c_doc_journal_detail = 'UPDATE'
                and v_cur_pos_prov_tgt.djd_reversal_entry <> 0 then
            -- pas de journalisation de la table doc_imputation -> donc comme le doc_record_id est inialisé depuis la table non historisé, on est sur que le doc_record_id est correct
            if v_cur_pos_prov_tgt.pos_imputation = 0 then
              begin
                select nvl(doc_record_id, 0)
                  into v_doc_record_id
                  from doc_journal_detail_prov
                 where doc_journal_detail_prov_id =
                                     (select max(doc_journal_detail_prov_id)
                                        from doc_journal_detail_prov
                                       where djd_transaction_id = v_cur_pos_prov_tgt.djd_transaction_id
                                         and doc_position_id = v_cur_pos_prov_tgt.doc_position_id);
              --and doc_journal_detail_prov_id > v_cur_pos_prov_tgt.doc_journal_detail_prov_id
              exception
                when no_data_found then
                  v_doc_record_id  := null;
              end;
            else
              v_doc_record_id  := v_cur_pos_prov_tgt.doc_record_id;
            end if;

            if v_doc_record_id <> v_cur_pos_prov_tgt.doc_record_id then
              v_doc_rec_id_doc_pos_id  := v_cur_pos_prov_tgt.c_test;
            end if;
          else
            -- entrée dans la boucle où la table de journal va être utilisée
            -- décharge partielle avec donc fils en attenet de confirmation -> on va les chercher dans la table prov
            -- mais la dernière trace de discharged dans la table journal contient les psotions qui n'ont pas été déchargées ni en attente de confirmation sur les fils

            -- cas à lire dans la table journal djd_reversalentry -> pas une trrace d'extourne dans la table de journal -> voir analyse jsc
            if    (    v_cur_pos_prov_tgt.c_doc_journal_detail in('CONFIRM', 'UPDATE', 'INSERT', 'INS_DISCH', 'DEL_TGT', 'DISCHARGED')
                   and v_cur_pos_prov_tgt.djd_reversal_entry = 0
                  )
               or (    v_cur_pos_prov_tgt.c_doc_journal_detail in('UPD_TGT', 'DEL_TGT')
                   and v_cur_pos_prov_tgt.pos_balance_quantity > 0)
                                                                   --and )
            then
              -- on a lu l'info -> on peut passer à la pos suivante -> le journal est trié chronologiquement
              v_doc_rec_id_doc_pos_id  := v_cur_pos_prov_tgt.c_test;

              -- cas des avenants
              begin
                select distinct doc.dmt_number
                           into v_inter_char
                           from doc_document doc
                              , doc_journal_detail_prov prov
                          where doc.doc_document_id = prov.doc_document_id
                            and prov.doc_position_id = v_cur_pos_prov_tgt.doc_position_id;
              exception
                when no_data_found then
                  select distinct dmt_number
                             into v_inter_char
                             from doc_journal_detail_prov prov
                            where prov.doc_position_id = v_cur_pos_prov_tgt.doc_position_id;
              end;

              insert into gal_conso_doc_position_temp
                          (doc_position_id
                         , doc_document_id
                         , pac_third_id
                         , pos_number
                         , pos_reference
                         , pos_long_description
                         , pos_short_description
                         , c_gauge_type_pos
                         , c_doc_pos_status
                         , gco_good_id
                         , doc_record_id
                         , pac_representative_id
                         , pac_person_id
                         , fam_fixed_assets_id
                         , c_fam_transaction_typ
                         , hrm_person_id
                         , acs_financial_account_id
                         , acs_division_account_id
                         , acs_cpn_account_id
                         , acs_cda_account_id
                         , acs_pf_account_id
                         , acs_pj_account_id
                         , pos_convert_factor
                         , pos_basis_quantity
                         , pos_intermediate_quantity
                         , pos_final_quantity
                         , pos_balance_quantity
                         , pos_basis_quantity_su
                         , pos_intermediate_quantity_su
                         , pos_final_quantity_su
                         , stm_stock_id
                         , pos_gross_unit_value
                         , pos_gross_unit_value_incl
                         , pos_net_unit_value
                         , pos_net_unit_value_incl
                         , pos_gross_value
                         , pos_gross_value_b
                         , pos_gross_value_incl
                         , pos_gross_value_incl_b
                         , pos_net_value_excl
                         , pos_net_value_excl_b
                         , pos_net_value_incl
                         , pos_net_value_incl_b
                         , dic_imp_free1_id
                         , dic_imp_free2_id
                         , dic_imp_free3_id
                         , dic_imp_free4_id
                         , dic_imp_free5_id
                         , pos_imf_number_2
                         , pos_imf_number_3
                         , pos_imf_number_4
                         , pos_imf_number_5
                         , pos_imf_text_1
                         , pos_imf_text_2
                         , pos_imf_text_3
                         , pos_imf_text_4
                         , pos_imf_text_5
                         , dmt_number
                         , dmt_date_document
                         , doc_gauge_id
                         , a_confirm
                         , a_datecre
                         , a_datemod
                         , a_idcre
                         , a_idmod
                         , a_reclevel
                         , a_recstatus
                         , is_imputation
                         , acs_financial_currency_id
                         , dmt_rate_of_exchange
                         , dmt_date_value
                         , pos_balanced
                         , c_project_consolidation
                          )
                select *
                  from (select djp.doc_position_id
                             , djp.doc_document_id
                             , djp.pac_third_id
                             , djp.pos_number
                             , djp.pos_reference
                             , djp.pos_long_description
                             , djp.pos_short_description
                             , djp.c_gauge_type_pos
                             , djp.c_doc_pos_status
                             , djp.gco_good_id
                             , djp.doc_record_id
                             , djp.pac_representative_id
                             , djp.pac_person_id
                             , djp.fam_fixed_assets_id
                             , djp.c_fam_transaction_typ
                             , djp.hrm_person_id
                             , djp.acs_financial_account_id
                             , djp.acs_division_account_id
                             , djp.acs_cpn_account_id
                             , djp.acs_cda_account_id
                             , djp.acs_pf_account_id
                             , djp.acs_pj_account_id
                             , djp.pos_convert_factor
                             , djp.djd_new_pos_basis_qty
                             , djp.djd_new_pos_inter_qty
                             , djp.djd_new_pos_final_qty
                             , djp.djd_new_pos_balance_qty
                             , djp.djd_new_pos_basis_qty_su
                             , djp.djd_new_pos_inter_qty_su
                             , djp.djd_new_pos_final_qty_su
                             , djp.stm_stock_id
                             , djp.pos_gross_unit_value
                             , djp.pos_gross_unit_value_incl
                             , djp.pos_net_unit_value
                             , djp.pos_net_unit_value_incl
                             , djp.pos_gross_value
                             , djp.pos_gross_value_b
                             , djp.pos_gross_value_incl
                             , djp.pos_gross_value_incl_b
                             , djp.pos_net_value_excl
                             , djp.pos_net_value_excl_b
                             , djp.pos_net_value_incl
                             , djp.pos_net_value_incl_b
                             , djp.dic_imp_free1_id
                             , djp.dic_imp_free2_id
                             , djp.dic_imp_free3_id
                             , djp.dic_imp_free4_id
                             , djp.dic_imp_free5_id
                             , djp.pos_imf_number_2
                             , djp.pos_imf_number_3
                             , djp.pos_imf_number_4
                             , djp.pos_imf_number_5
                             , djp.pos_imf_text_1
                             , djp.pos_imf_text_2
                             , djp.pos_imf_text_3
                             , djp.pos_imf_text_4
                             , djp.pos_imf_text_5
                             , v_inter_char
                             , djp.dmt_date_document
                             , djp.doc_gauge_id
                             , djp.a_confirm
                             , djp.a_datecre
                             , djp.a_datemod
                             , djp.a_idcre
                             , djp.a_idmod
                             , djp.a_reclevel
                             , djp.a_recstatus
                             , djp.pos_imputation
                             , acs_financial_currency_id
                             , dmt_rate_of_exchange
                             , dmt_date_value
                             , 0
                             , djp.c_project_consolidation
                          from doc_journal_detail_prov djp
                             , gal_conso_doc_record_temp rco
                             , doc_journal_header djh
                         where djp.pos_imputation = 0
                           and djp.doc_journal_header_id = djh.doc_journal_header_id
                           and djp.doc_record_id = rco.doc_record_id
                           and doc_journal_detail_prov_id = v_cur_pos_prov_tgt.doc_journal_detail_prov_id
                        union
                        select djp.doc_position_id
                             , djp.doc_document_id
                             , djp.pac_third_id
                             , djp.pos_number
                             , djp.pos_reference
                             , djp.pos_long_description
                             , djp.pos_short_description
                             , djp.c_gauge_type_pos
                             , djp.c_doc_pos_status
                             , djp.gco_good_id
                             , imp.doc_record_id
                             , djp.pac_representative_id
                             , djp.pac_person_id
                             , djp.fam_fixed_assets_id
                             , djp.c_fam_transaction_typ
                             , djp.hrm_person_id
                             , imp.acs_financial_account_id
                             , imp.acs_division_account_id
                             , imp.acs_cpn_account_id
                             , imp.acs_cda_account_id
                             , imp.acs_pf_account_id
                             , imp.acs_pj_account_id
                             , djp.pos_convert_factor
                             , djp.djd_new_pos_basis_qty
                             , djp.djd_new_pos_inter_qty
                             , djp.djd_new_pos_final_qty * det_ratio_corrector(djp.doc_position_id, imp.doc_position_imputation_id)
                             , djp.djd_new_pos_balance_qty * det_ratio_corrector(djp.doc_position_id, imp.doc_position_imputation_id)
                             , djp.djd_new_pos_basis_qty_su
                             , djp.djd_new_pos_inter_qty_su
                             , djp.djd_new_pos_final_qty_su
                             , djp.stm_stock_id
                             , djp.pos_gross_unit_value
                             , djp.pos_gross_unit_value_incl
                             , djp.pos_net_unit_value
                             , djp.pos_net_unit_value_incl
                             , djp.pos_gross_value
                             , djp.pos_gross_value_b
                             , djp.pos_gross_value_incl
                             , djp.pos_gross_value_incl_b
                             , djp.pos_net_value_excl
                             , djp.pos_net_value_excl_b * det_ratio_corrector(djp.doc_position_id, imp.doc_position_imputation_id)
                             , djp.pos_net_value_incl
                             , djp.pos_net_value_incl_b
                             , djp.dic_imp_free1_id
                             , djp.dic_imp_free2_id
                             , djp.dic_imp_free3_id
                             , djp.dic_imp_free4_id
                             , djp.dic_imp_free5_id
                             , djp.pos_imf_number_2
                             , djp.pos_imf_number_3
                             , djp.pos_imf_number_4
                             , djp.pos_imf_number_5
                             , djp.pos_imf_text_1
                             , djp.pos_imf_text_2
                             , djp.pos_imf_text_3
                             , djp.pos_imf_text_4
                             , djp.pos_imf_text_5
                             , v_inter_char
                             , djp.dmt_date_document
                             , djp.doc_gauge_id
                             , djp.a_confirm
                             , djp.a_datecre
                             , djp.a_datemod
                             , djp.a_idcre
                             , djp.a_idmod
                             , djp.a_reclevel
                             , djp.a_recstatus
                             , djp.pos_imputation
                             , acs_financial_currency_id
                             , dmt_rate_of_exchange
                             , dmt_date_value
                             , 0
                             , djp.c_project_consolidation
                          from doc_journal_detail_prov djp
                             , gal_conso_doc_record_temp rco
                             , doc_position_imputation imp
                             , doc_journal_header djh
                         where imp.doc_record_id = rco.doc_record_id
                           and djp.doc_journal_header_id = djh.doc_journal_header_id
                           and doc_journal_detail_prov_id = v_cur_pos_prov_tgt.doc_journal_detail_prov_id
                           and djp.doc_position_id = imp.doc_position_id) CMD
                 where not exists(select 1
                                    from GAL_CONSO_IS_ACOMPTE_TEMP
                                   where GCO_GOOD_ID = CMD.GCO_GOOD_ID)
                   and not exists(select 1
                                    from GAL_CONSO_IS_ACOMPTE_TEMP
                                   where DOC_POSITION_ID = CMD.DOC_POSITION_ID);

              select max(stm_stock_id)
                into v_stock_id
                from doc_journal_detail_prov
               where doc_journal_detail_prov_id = v_cur_pos_prov_tgt.doc_journal_detail_prov_id;

              if v_stock_id is null then
                update doc_journal_detail_prov
                   set stm_stock_id = (select stm_stock_id
                                         from doc_position
                                        where doc_position_id = v_cur_pos_prov_id);
              end if;

              v_doc_rec_id_doc_pos_id  := v_cur_pos_prov_tgt.c_test;
            end if;
          end if;
        end if;
      end if;
    end loop;
  end insert_pos_not_confirmed;

  function det_ratio_corrector(v_pos_id doc_position.doc_position_id%type, v_doc_pos_imp_id doc_position_imputation.doc_position_imputation_id%type)
    return number
  is
    v_imp_ratio number;
    v_tot_ratio number;
  begin
    select poi_ratio
      into v_imp_ratio
      from doc_position_imputation
     where doc_position_imputation_id = v_doc_pos_imp_id;

    select sum(poi_ratio)
      into v_tot_ratio
      from doc_position_imputation
     where doc_position_id = v_pos_id;

    return v_imp_ratio / v_tot_ratio;
  end det_ratio_corrector;

  procedure disengage_bill_book(is_not_snapshot boolean)
  is
    vtbldocposition             ttbldocposition;
    vfather_doc_gauge_id        DOC_DOCUMENT.doc_gauge_id%type;
    v_signe                     integer;
    v_c_invoice_expiry_doc_type integer;
    vfather_doc_id              DOC_DOCUMENT.doc_document_id%type;
    vcount_FinalInvoice         integer;
    v_CProjectConsolidation     DOC_GAUGE_STRUCTURED.C_PROJECT_CONSOLIDATION%type;
  begin
    -- on ne traite plus les commandes (documents) échéancés, dont toutes les factures on été générées -> tout passe en réalisé et plsu de désengagement
    if is_not_snapshot then
      delete from gal_conso_doc_position_temp
            where doc_document_id in(select distinct (pos_temp.doc_document_id)
                                                from gal_conso_doc_position_temp pos_temp
                                                   , doc_invoice_expiry inx
                                               where inx.doc_document_id = pos_temp.doc_document_id
                                                 and (select min(inx_invoice_generated)
                                                        from doc_invoice_expiry inx2
                                                       where inx2.doc_document_id = pos_temp.doc_document_id) > 0);
    --         DELETE FROM gal_conso_doc_position_temp -- changem,ent de cpode hmo 201.1.2014 -> prooblème de perf
    --               WHERE doc_document_id IN
    --                        (SELECT DISTINCT (pos_temp.doc_document_id)
    --                           FROM gal_conso_doc_position_temp pos_temp,
    --                                doc_invoice_expiry inx
    --                          WHERE inx.doc_document_id =
    --                                   pos_temp.doc_document_id)
    --                     AND doc_invoice_expiry_functions.IsAllGenerated (
    --                            doc_document_id) = 1;
    else
      for tbldocdocument in (select distinct (POS_TEMP.DOC_DOCUMENT_ID)
                                        from GAL_CONSO_DOC_POSITION_TEMP POS_TEMP
                                           , DOC_INVOICE_EXPIRY INX
                                       where INX.DOC_DOCUMENT_ID = POS_TEMP.DOC_DOCUMENT_ID) loop
        if doc_invoice_expiry_functions.IsAllGenerated(tbldocdocument.doc_document_id) = 1 then
          select count(DOC_DOCUMENT_ID)
            into vcount_FinalInvoice
            from GAL_CONSO_DOC_POSITION_TEMP
           where DOC_DOCUMENT_ID in(
                   select distinct (POS.DOC_DOCUMENT_ID)
                              from DOC_INVOICE_EXPIRY INX
                                 , DOC_POSITION POS
                             where INX.DOC_DOCUMENT_ID = tbldocdocument.doc_document_id
                               and INX.C_INVOICE_EXPIRY_DOC_TYPE = 3
                               and POS.DOC_INVOICE_EXPIRY_ID = INX.DOC_INVOICE_EXPIRY_ID);

          if vcount_FinalInvoice > 0 then
            delete from gal_conso_doc_position_temp
                  where doc_document_id = tbldocdocument.doc_document_id;
          end if;
        end if;
      end loop;
    end if;

    -- Comme on exclut les documents issus d'une déchragée d'un document échéancés, on laisse le document échéancés en état 2, comme cle il apparaît dans le suivi financier (on peut avouir uen commande liquidée, mais dont on a pa sencore généré toutes les factures
    update gal_conso_doc_position_temp pos_temp
       set pos_temp.POS_BALANCE_QUANTITY = pos_temp.POS_FINAL_QUANTITY
         , C_DOC_POS_STATUS = '02'
     where doc_document_id in(select distinct doc.doc_document_id
                                         from doc_document doc
                                            , doc_invoice_expiry inx
                                        where inx.doc_document_id = doc.doc_document_id)
       and C_DOC_POS_STATUS <> '05';

    select *
    bulk collect into vtbldocposition
      from gal_conso_doc_position_temp
     where doc_position_id in(
             select distinct (doc_position_id)
                        from (select pos_temp.doc_position_id
                                from gal_conso_doc_position_temp pos_temp
                                   , doc_position pos
                               where pos.doc_document_id = pos_temp.doc_document_id
                                 and pos.doc_invoice_expiry_id is not null
                              union
                              select pos_temp.doc_position_id
                                from gal_conso_doc_position_temp pos_temp
                                   , doc_document doc
                               where doc.doc_document_id = pos_temp.doc_document_id
                                 and doc.doc_invoice_expiry_id is not null) );

    if vtbldocposition.count > 0 then
      for i in vtbldocposition.first .. vtbldocposition.last loop
        -- si le doc_invoice expeiy_id est sur le doc, mais il peut être que sur la position si utilisation des factures groupées par tiers pour générer les factures d'échaénciers
        vfather_doc_id  :=
          nvl(doc_invoice_expiry_functions.GetInvoiceExpiryParentDoc(FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT'
                                                                                                         , 'DOC_INVOICE_EXPIRY_ID'
                                                                                                         , vtbldocposition(i).doc_document_id
                                                                                                          )
                                                                    )
            , 0
             );

        if vfather_doc_id = 0 then
          select distinct (doc_document_id)
                     into vfather_doc_id
                     from doc_invoice_expiry
                    where doc_invoice_expiry_id in(select doc_invoice_expiry_id
                                                     from doc_position
                                                    where doc_position_id = vtbldocposition(i).doc_position_id);
        end if;

        select min(doc_gauge_id)
          into vfather_doc_gauge_id
          from gal_conso_doc_position_temp
         where doc_document_id = vfather_doc_id;

        if nvl(vfather_doc_gauge_id, 0) >
                                    0   --si on ne trouve pas la comamnde dont siont ussues les factures dans la table temp (effacement) alors pas de désengagement
                                     then
          begin
            select c_invoice_expiry_doc_type
              into v_c_invoice_expiry_doc_type
              from doc_invoice_expiry inx
                 , doc_document doc
             where inx.doc_invoice_expiry_id = doc.doc_invoice_expiry_id
               and doc.doc_document_id = vtbldocposition(i).doc_document_id;
          exception
            when no_data_found then
              select c_invoice_expiry_doc_type
                into v_c_invoice_expiry_doc_type
                from doc_invoice_expiry inx
                   , doc_position pos
               where inx.doc_invoice_expiry_id = pos.doc_invoice_expiry_id
                 and pos.doc_position_id = vtbldocposition(i).doc_position_id;
          end;

          select C_PROJECT_CONSOLIDATION
            into v_CProjectConsolidation
            from DOC_GAUGE_STRUCTURED
           where doc_gauge_id = vfather_doc_gauge_id;

          if v_c_invoice_expiry_doc_type = 4 then
            v_signe  := 1;
          elsif v_c_invoice_expiry_doc_type = 6 then
            v_signe  := 0;
          else
            v_signe  := -1;
          end if;

          if v_signe <> 0 then
            vtbldocposition(i).pos_net_value_excl_b     := v_signe * vtbldocposition(i).pos_net_value_excl_b;
            vtbldocposition(i).pos_short_description    := substr('Désengagement ' || vtbldocposition(i).dmt_number, 1, 30);
            vtbldocposition(i).doc_gauge_id             := vfather_doc_gauge_id;
            vtbldocposition(i).POS_BALANCE_QUANTITY     := vtbldocposition(i).POS_FINAL_QUANTITY;
            vtbldocposition(i).c_project_consolidation  := v_CProjectConsolidation;

            insert into gal_conso_doc_position_temp
                 values vtbldocposition(i);
          end if;
        end if;
      end loop;
    end if;
  end disengage_bill_book;

  procedure read_position_not_journal(vtbldocposition in out ttbldocposition)
  is
  begin
    delete from GAL_CONSO_POS_IMPUTATION_TEMP;

    insert into GAL_CONSO_POS_IMPUTATION_TEMP
      (select IMP.*
         from DOC_POSITION_IMPUTATION IMP
            , GAL_CONSO_DOC_RECORD_TEMP RCO
        where RCO.DOC_RECORD_ID = IMP.DOC_RECORD_ID);

    exclude_position;

    delete from GAL_CONSO_POS2EXCL_FROM_EXPIRY;

    -- Création d'une liste de positions à exclure pour le désengagement (lié à l'échéancier)
    for ltplOriginDetail in (select distinct (DOC_POSITION_DETAIL_ID)
                                        from DOC_POSITION POS
                                           , GAL_CONSO_DOC_RECORD_TEMP RCO
                                           , DOC_DOCUMENT DMT
                                           , DOC_POSITION_DETAIL PDE
                                       where nvl(DMT.C_INVOICE_EXPIRY_INPUT_TYPE, 0) > 0
                                         and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID
                                         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                         and POS.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID) loop
      -- hmo 21.1.2014 traitement des cas de factures modifiées à la main l'id de la facture générée est que sur la position et du cas ou modif manuelle de factures générées par décharge puis on y met un échéancier
      insert into GAL_CONSO_POS2EXCL_FROM_EXPIRY
                  (DOC_POSITION_ID
                  )
        (select distinct PDE.DOC_POSITION_ID
                    from DOC_POSITION_DETAIL PDE
                       , DOC_DOCUMENT DMT
                       , DOC_POSITION POS
                       , DOC_GAUGE_STRUCTURED GAS
                   where DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
                     and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                     and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                     and (    DMT.DOC_INVOICE_EXPIRY_ID is null
                          and POS.DOC_INVOICE_EXPIRY_ID is null)
                     and nvl(GAS.C_PROJECT_CONSOLIDATION, 0) <> 2
              start with PDE.DOC_DOC_POSITION_DETAIL_ID = ltplOriginDetail.DOC_POSITION_DETAIL_ID
              connect by prior PDE.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID);
    --         INSERT INTO GAL_CONSO_POS2EXCL_FROM_EXPIRY (DOC_POSITION_ID)
    --            (    SELECT DISTINCT PDE.DOC_POSITION_ID
    --                   FROM DOC_POSITION_DETAIL PDE, DOC_DOCUMENT DMT
    --                  WHERE DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
    --                        AND (DMT.DOC_INVOICE_EXPIRY_ID IS NULL)
    --             START WITH PDE.DOC_DOC_POSITION_DETAIL_ID =
    --                           ltplOriginDetail.DOC_POSITION_DETAIL_ID
    --             CONNECT BY PRIOR PDE.DOC_POSITION_DETAIL_ID =
    --                           PDE.DOC_DOC_POSITION_DETAIL_ID);
    end loop;

    select doc_position_id
         , doc_document_id
         , pac_third_id
         , pos_number
         , pos_reference
         , pos_long_description
         , pos_short_description
         , c_gauge_type_pos
         , c_doc_pos_status
         , gco_good_id
         , doc_record_id
         , pac_representative_id
         , pac_person_id
         , fam_fixed_assets_id
         , c_fam_transaction_typ
         , hrm_person_id
         , acs_financial_account_id
         , acs_division_account_id
         , acs_cpn_account_id
         , acs_cda_account_id
         , acs_pf_account_id
         , acs_pj_account_id
         , pos_convert_factor
         , pos_basis_quantity
         , pos_intermediate_quantity
         , pos_final_quantity
         , pos_balance_quantity
         , pos_basis_quantity_su
         , pos_intermediate_quantity_su
         , pos_final_quantity_su
         , stm_stock_id
         , pos_gross_unit_value
         , pos_gross_unit_value_incl
         , pos_net_unit_value
         , pos_net_unit_value_incl
         , pos_gross_value
         , pos_gross_value_b
         , pos_gross_value_incl
         , pos_gross_value_incl_b
         , pos_net_value_excl
         , pos_net_value_excl_b
         , pos_net_value_incl
         , pos_net_value_incl_b
         , dic_imp_free1_id
         , dic_imp_free2_id
         , dic_imp_free3_id
         , dic_imp_free4_id
         , dic_imp_free5_id
         , pos_imf_number_2
         , pos_imf_number_3
         , pos_imf_number_4
         , pos_imf_number_5
         , pos_imf_text_1
         , pos_imf_text_2
         , pos_imf_text_3
         , pos_imf_text_4
         , pos_imf_text_5
         , dmt_number
         , dmt_date_document
         , doc_gauge_id
         , a_confirm
         , a_datecre
         , a_datemod
         , a_idcre
         , a_idmod
         , a_reclevel
         , a_recstatus
         , a
         , b
         , c
         , d
         , e
         , f
         , c_project_consolidation
         , h
         , doc_position_imputation_id
         , acs_financial_currency_id
         , dmt_rate_of_exchange
         , dmt_date_value
         , pos_balanced
    bulk collect into vtbldocposition
      from (select pos.doc_position_id
                 , pos.doc_document_id
                 , pos.pac_third_id
                 , pos.pos_number
                 , pos.pos_reference
                 , pos_long_description
                 , pos_short_description
                 , pos.c_gauge_type_pos
                 , pos.c_doc_pos_status
                 , pos.gco_good_id
                 , pos.doc_record_id
                 , pos.pac_representative_id
                 , pos.pac_person_id
                 , pos.fam_fixed_assets_id
                 , pos.c_fam_transaction_typ
                 , pos.hrm_person_id
                 , pos.acs_financial_account_id
                 , pos.acs_division_account_id
                 , pos.acs_cpn_account_id
                 , pos.acs_cda_account_id
                 , pos.acs_pf_account_id
                 , pos.acs_pj_account_id
                 , pos.pos_convert_factor
                 , pos.pos_basis_quantity
                 , pos.pos_intermediate_quantity
                 , pos.pos_final_quantity
                 , pos.pos_balance_quantity
                 , pos.pos_basis_quantity_su
                 , pos.pos_intermediate_quantity_su
                 , pos.pos_final_quantity_su
                 , pos.stm_stock_id
                 , pos.pos_gross_unit_value
                 , pos.pos_gross_unit_value_incl
                 , pos.pos_net_unit_value
                 , pos.pos_net_unit_value_incl
                 , pos.pos_gross_value
                 , pos.pos_gross_value_b
                 , pos.pos_gross_value_incl
                 , pos.pos_gross_value_incl_b
                 , pos.pos_net_value_excl
                 , pos.pos_net_value_excl_b
                 , pos.pos_net_value_incl
                 , pos.pos_net_value_incl_b
                 , pos.dic_imp_free1_id
                 , pos.dic_imp_free2_id
                 , pos.dic_imp_free3_id
                 , pos.dic_imp_free4_id
                 , pos.dic_imp_free5_id
                 , pos.pos_imf_number_2
                 , pos.pos_imf_number_3
                 , pos.pos_imf_number_4
                 , pos.pos_imf_number_5
                 , pos.pos_imf_text_1
                 , pos.pos_imf_text_2
                 , pos.pos_imf_text_3
                 , pos.pos_imf_text_4
                 , pos.pos_imf_text_5
                 , dmt.dmt_number
                 , dmt.dmt_date_document
                 , dmt.doc_gauge_id
                 , pos.a_confirm
                 , pos.a_datecre
                 , pos.a_datemod
                 , pos.a_idcre
                 , pos.a_idmod
                 , pos.a_reclevel
                 , pos.a_recstatus
                 , null as a
                 , null as b
                 , null as c
                 , null as d
                 , null as e
                 , null as f
                 , gas.c_project_consolidation
                 , null as h
                 , null as doc_position_imputation_id
                 , acs_financial_currency_id
                 , dmt_rate_of_exchange
                 , dmt.dmt_date_value
                 , pos_balanced
              from doc_position pos
                 , gal_conso_doc_record_temp rco
                 , doc_document dmt
                 , doc_gauge_structured gas
             where pos.doc_record_id = rco.doc_record_id
               and pos.doc_document_id = dmt.doc_document_id
               and dmt.doc_gauge_id = gas.doc_gauge_id
               and pos.pos_imputation = 0
               and gas.c_project_consolidation > '0'
            union
            select pos.doc_position_id
                 , pos.doc_document_id
                 , dmt.pac_third_id
                 , pos.pos_number
                 , pos.pos_reference
                 , pos_long_description
                 , pos_short_description
                 , pos.c_gauge_type_pos
                 , pos.c_doc_pos_status
                 , pos.gco_good_id
                 , imp.doc_record_id
                 , pos.pac_representative_id
                 , pos.pac_person_id
                 , pos.fam_fixed_assets_id
                 , pos.c_fam_transaction_typ
                 , pos.hrm_person_id
                 , imp.acs_financial_account_id
                 , imp.acs_division_account_id
                 , imp.acs_cpn_account_id
                 , imp.acs_cda_account_id
                 , imp.acs_pf_account_id
                 , imp.acs_pj_account_id
                 , pos.pos_convert_factor
                 , pos.pos_basis_quantity
                 , pos.pos_intermediate_quantity
                 , pos.pos_final_quantity * det_ratio_corrector(pos.doc_position_id, imp.doc_position_imputation_id) as pos_final_quantity
                 , pos.pos_balance_quantity * det_ratio_corrector(pos.doc_position_id, imp.doc_position_imputation_id) as pos_balance_quantity
                 , pos.pos_basis_quantity_su
                 , pos.pos_intermediate_quantity_su
                 , pos.pos_final_quantity_su
                 , pos.stm_stock_id
                 , pos.pos_gross_unit_value
                 , pos.pos_gross_unit_value_incl
                 , pos.pos_net_unit_value
                 , pos.pos_net_unit_value_incl
                 , pos.pos_gross_value
                 , pos.pos_gross_value_b
                 , pos.pos_gross_value_incl
                 , pos.pos_gross_value_incl_b
                 , pos.pos_net_value_excl * det_ratio_corrector(pos.doc_position_id, imp.doc_position_imputation_id) as pos_net_value_excl
                 , pos.pos_net_value_excl_b * det_ratio_corrector(pos.doc_position_id, imp.doc_position_imputation_id) as pos_net_value_excl_b
                 , pos.pos_net_value_incl
                 , pos.pos_net_value_incl_b
                 , pos.dic_imp_free1_id
                 , pos.dic_imp_free2_id
                 , pos.dic_imp_free3_id
                 , pos.dic_imp_free4_id
                 , pos.dic_imp_free5_id
                 , pos.pos_imf_number_2
                 , pos.pos_imf_number_3
                 , pos.pos_imf_number_4
                 , pos.pos_imf_number_5
                 , pos.pos_imf_text_1
                 , pos.pos_imf_text_2
                 , pos.pos_imf_text_3
                 , pos.pos_imf_text_4
                 , pos.pos_imf_text_5
                 , dmt.dmt_number
                 , dmt.dmt_date_document
                 , dmt.doc_gauge_id
                 , pos.a_confirm
                 , pos.a_datecre
                 , pos.a_datemod
                 , pos.a_idcre
                 , pos.a_idmod
                 , pos.a_reclevel
                 , pos.a_recstatus
                 , null as a
                 , null as b
                 , null as c
                 , null as d
                 , null as e
                 , null as f
                 , gas.c_project_consolidation
                 , null as h
                 , imp.doc_position_imputation_id
                 , acs_financial_currency_id
                 , dmt_rate_of_exchange
                 , dmt.dmt_date_value
                 , pos_balanced
              from gal_conso_pos_imputation_temp imp
                 , doc_position pos
                 , doc_document dmt
                 , doc_gauge_structured gas
             where pos.doc_position_id = imp.doc_position_id
               and pos.doc_document_id = dmt.doc_document_id
               and dmt.doc_gauge_id = gas.doc_gauge_id
               and pos.pos_imputation = 1
               and gas.c_project_consolidation > '0') CMD
     where not exists(select 1
                        from GAL_CONSO_IS_ACOMPTE_TEMP
                       where GCO_GOOD_ID = CMD.GCO_GOOD_ID)
       and not exists(select 1
                        from GAL_CONSO_IS_ACOMPTE_TEMP
                       where DOC_POSITION_ID = CMD.DOC_POSITION_ID)
       and not exists(select 1
                        from GAL_CONSO_POS2EXCL_FROM_EXPIRY
                       where DOC_POSITION_ID = CMD.DOC_POSITION_ID);
  end read_position_not_journal;

  procedure read_position_journal(v_event_snapshotdate date, v_compta_snapshotdate date, vtbldocpositionjournal in out ttbldocpositionjournal)
  is
  begin
    delete from gal_conso_pos_imputation_temp;

    insert into GAL_CONSO_POS_IMPUTATION_TEMP
      (select IMP.*
         from DOC_POSITION_IMPUTATION IMP
            , DOC_JOURNAL_DETAIL DJD
            , GAL_CONSO_DOC_RECORD_TEMP RCO
        where RCO.DOC_RECORD_ID = IMP.DOC_RECORD_ID
          and DJD.DOC_JOURNAL_DETAIL_ID =
                (select max(DJD2.DOC_JOURNAL_DETAIL_ID) as DOC_JOURNAL_DETAIL_ID
                   from DOC_JOURNAL_DETAIL DJD2
                  where DJD2.DOC_POSITION_ID = IMP.DOC_POSITION_ID
                    and DJD2.DJD_JOURNAL_DOCUMENT_DATE <= v_compta_snapshotdate
                    and DJD2.A_DATECRE <= v_event_snapshotdate)
          and DJD.POS_IMPUTATION = 1);

    exclude_position;

    delete from doc_position_detail_gal;

    delete from doc_tmp_pos_journal_pos;

    delete from GAL_CONSO_POS2EXCL_FROM_EXPIRY;

    -- Création d'une liste de positions à exclure pour le désengagement (lié à l'échéancier)
    for ltplOriginDetail in (select distinct (DOC_POSITION_DETAIL_ID)
                                        from DOC_JOURNAL_DETAIL DJD
                                           , GAL_CONSO_DOC_RECORD_TEMP RCO
                                           , DOC_DOCUMENT DMT
                                           , DOC_POSITION_DETAIL PDE
                                       where nvl(DMT.C_INVOICE_EXPIRY_INPUT_TYPE, 0) > 0
                                         and DJD.DOC_RECORD_ID = RCO.DOC_RECORD_ID
                                         and DJD.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                         and DJD.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID) loop
      -- hmo 21.1.2014 traitement des cas de factures modifiées à la main l'id de la facture générée est que sur la position et du cas ou modif manuelle de factures générées par décharge puis on y met un échéancier
      insert into GAL_CONSO_POS2EXCL_FROM_EXPIRY
                  (DOC_POSITION_ID
                  )
        (select distinct PDE.DOC_POSITION_ID
                    from DOC_POSITION_DETAIL PDE
                       , DOC_DOCUMENT DMT
                       , DOC_POSITION POS
                       , DOC_JOURNAL_DETAIL DJD
                   where DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
                     and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                     and DMT.DOC_DOCUMENT_ID = DJD.DOC_DOCUMENT_ID
                     and (    DMT.DOC_INVOICE_EXPIRY_ID is null
                          and POS.DOC_INVOICE_EXPIRY_ID is null)
                     and nvl(DJD.C_PROJECT_CONSOLIDATION, 0) <> 2
              start with PDE.DOC_DOC_POSITION_DETAIL_ID = ltplOriginDetail.DOC_POSITION_DETAIL_ID
              connect by prior PDE.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID);
    end loop;

    insert into doc_position_detail_gal
      select djd.doc_position_id
           , djd.doc_document_id
           , djd.pac_third_id
           , djd.pos_number
           , djd.pos_reference
           , djd.pos_long_description
           , djd.pos_short_description
           , djd.c_gauge_type_pos
           , djd.c_doc_pos_status
           , djd.gco_good_id
           , djd.doc_record_id
           , djd.pac_representative_id
           , djd.pac_person_id
           , djd.fam_fixed_assets_id
           , djd.c_fam_transaction_typ
           , djd.hrm_person_id
           , djd.acs_financial_account_id
           , djd.acs_division_account_id
           , djd.acs_cpn_account_id
           , djd.acs_cda_account_id
           , djd.acs_pf_account_id
           , djd.acs_pj_account_id
           , djd.pos_convert_factor
           , djd.djd_new_pos_basis_qty
           , djd.djd_new_pos_inter_qty
           , djd.djd_new_pos_final_qty
           , nvl(djd.djd_new_pos_balance_qty, 0)
           , djd.djd_new_pos_basis_qty_su
           , djd.djd_new_pos_inter_qty_su
           , djd.djd_new_pos_final_qty_su
           , djd.stm_stock_id
           , djd.pos_gross_unit_value
           , djd.pos_gross_unit_value_incl
           , djd.pos_net_unit_value
           , djd.pos_net_unit_value_incl
           , djd.pos_gross_value
           , djd.pos_gross_value_b
           , djd.pos_gross_value_incl
           , djd.pos_gross_value_incl_b
           , djd.pos_net_value_excl
           , djd.pos_net_value_excl_b
           , djd.pos_net_value_incl
           , djd.pos_net_value_incl_b
           , djd.dic_imp_free1_id
           , djd.dic_imp_free2_id
           , djd.dic_imp_free3_id
           , djd.dic_imp_free4_id
           , djd.dic_imp_free5_id
           , djd.pos_imf_number_2
           , djd.pos_imf_number_3
           , djd.pos_imf_number_4
           , djd.pos_imf_number_5
           , djd.pos_imf_text_1
           , djd.pos_imf_text_2
           , djd.pos_imf_text_3
           , djd.pos_imf_text_4
           , djd.pos_imf_text_5
           , djd.pos_imf_date_1
           , djd.pos_imf_date_2
           , djd.pos_imf_date_3
           , djd.pos_imf_date_4
           , djd.pos_imf_date_5
           , djd.dmt_number
           , djd.dmt_date_document
           , djd.doc_gauge_id
           , djd.a_confirm
           , djd.a_datecre
           , djd.a_datemod
           , djd.a_idcre
           , djd.a_idmod
           , djd.a_reclevel
           , djd.a_recstatus
           , djd.c_doc_journal_detail
           , djd.djd_reversal_entry
           , djd.doc_journal_detail_id
           , djd.djd_transaction_id
           , djd.doc_journal_header_id
           , 0 is_imputation
           , djd.c_project_consolidation
           , djd.doc_position_id || djd.doc_record_id as doc_rcd_id_doc_pos_id
           , null as doc_position_imputation_id
           , djh.acs_financial_currency_id
           , djd.dmt_rate_of_exchange
           , djd.dmt_date_value
           , 0
        from doc_journal_detail djd
           , gal_conso_doc_record_temp rco
           , doc_journal_header djh
       where djd.doc_record_id = rco.doc_record_id
         and djh.doc_journal_header_id = djd.doc_journal_header_id
         and djd.djd_project_consolidation = 1
         and djd_journal_document_date <= v_compta_snapshotdate
         and djd.a_datecre <= v_event_snapshotdate
         and djd.pos_imputation = 0
         and not exists(select 1
                          from GAL_CONSO_IS_ACOMPTE_TEMP
                         where GCO_GOOD_ID = DJD.GCO_GOOD_ID)
         and not exists(select 1
                          from GAL_CONSO_IS_ACOMPTE_TEMP
                         where DOC_POSITION_ID = DJD.DOC_POSITION_ID)
         and not exists(select 1
                          from GAL_CONSO_POS2EXCL_FROM_EXPIRY
                         where DOC_POSITION_ID = DJD.DOC_POSITION_ID);

    insert into doc_position_detail_gal
      select djd.doc_position_id
           , djd.doc_document_id
           , djd.pac_third_id
           , djd.pos_number
           , djd.pos_reference
           , djd.pos_long_description
           , djd.pos_short_description
           , djd.c_gauge_type_pos
           , djd.c_doc_pos_status
           , djd.gco_good_id
           , imp.doc_record_id as doc_record_id
           , djd.pac_representative_id
           , djd.pac_person_id
           , djd.fam_fixed_assets_id
           , djd.c_fam_transaction_typ
           , djd.hrm_person_id
           , imp.acs_financial_account_id as acs_financial_account_id
           , imp.acs_division_account_id as acs_division_account_id
           , imp.acs_cpn_account_id as acs_cpn_account_id
           , imp.acs_cda_account_id as acs_cda_account_id
           , imp.acs_pf_account_id as acs_pf_account_id
           , imp.acs_pj_account_id as acs_pj_account_id
           , djd.pos_convert_factor
           , djd.djd_new_pos_basis_qty
           , djd.djd_new_pos_inter_qty
           , djd.djd_new_pos_final_qty * det_ratio_corrector(djd.doc_position_id, imp.doc_position_imputation_id) as djd_new_pos_final_qty
           , nvl(djd.djd_new_pos_balance_qty, 0) * det_ratio_corrector(djd.doc_position_id, imp.doc_position_imputation_id) as djd_new_pos_balance_qty
           , djd.djd_new_pos_basis_qty_su
           , djd.djd_new_pos_inter_qty_su
           , djd.djd_new_pos_final_qty_su
           , djd.stm_stock_id
           , djd.pos_gross_unit_value
           , djd.pos_gross_unit_value_incl
           , djd.pos_net_unit_value
           , djd.pos_net_unit_value_incl
           , djd.pos_gross_value
           , djd.pos_gross_value_b
           , djd.pos_gross_value_incl
           , djd.pos_gross_value_incl_b
           , djd.pos_net_value_excl
           , djd.pos_net_value_excl_b * det_ratio_corrector(djd.doc_position_id, imp.doc_position_imputation_id) as pos_net_value_excl_b
           , djd.pos_net_value_incl
           , djd.pos_net_value_incl_b
           , djd.dic_imp_free1_id
           , djd.dic_imp_free2_id
           , djd.dic_imp_free3_id
           , djd.dic_imp_free4_id
           , djd.dic_imp_free5_id
           , djd.pos_imf_number_2
           , djd.pos_imf_number_3
           , djd.pos_imf_number_4
           , djd.pos_imf_number_5
           , djd.pos_imf_text_1
           , djd.pos_imf_text_2
           , djd.pos_imf_text_3
           , djd.pos_imf_text_4
           , djd.pos_imf_text_5
           , djd.pos_imf_date_1
           , djd.pos_imf_date_2
           , djd.pos_imf_date_3
           , djd.pos_imf_date_4
           , djd.pos_imf_date_5
           , djd.dmt_number
           , djd.dmt_date_document
           , djd.doc_gauge_id
           , djd.a_confirm
           , djd.a_datecre
           , djd.a_datemod
           , djd.a_idcre
           , djd.a_idmod
           , djd.a_reclevel
           , djd.a_recstatus
           , djd.c_doc_journal_detail
           , djd.djd_reversal_entry
           , djd.doc_journal_detail_id
           , djd.djd_transaction_id
           , djd.doc_journal_header_id
           , 1 as is_imputation
           , djd.c_project_consolidation
           , djd.doc_position_id || imp.doc_position_imputation_id as doc_rcd_id_doc_pos_id
           , imp.doc_position_imputation_id as doc_position_imputation_id
           , djh.acs_financial_currency_id
           , djd.dmt_rate_of_exchange
           , djd.dmt_date_value
           , 0
        from gal_conso_pos_imputation_temp imp
           , doc_journal_detail djd
           , doc_journal_header djh
       where imp.doc_position_id = djd.doc_position_id
         and djh.doc_journal_header_id = djd.doc_journal_header_id
         and djd_journal_document_date <= v_compta_snapshotdate
         and djd.a_datecre <= v_event_snapshotdate
         and djd.djd_project_consolidation = 1
         and not exists(select 1
                          from GAL_CONSO_IS_ACOMPTE_TEMP
                         where GCO_GOOD_ID = DJD.GCO_GOOD_ID)
         and not exists(select 1
                          from GAL_CONSO_IS_ACOMPTE_TEMP
                         where DOC_POSITION_ID = DJD.DOC_POSITION_ID)
         and not exists(select 1
                          from GAL_CONSO_POS2EXCL_FROM_EXPIRY
                         where DOC_POSITION_ID = DJD.DOC_POSITION_ID);
  end read_position_journal;

  procedure inittabledocposition(v_event_snapshotdate date, v_compta_snapshotdate date)
  is
    vtbldocposition               ttbldocposition;
    vtbldocpositionjournal        ttbldocpositionjournal;
    voldposid                     varchar2(24)                                      := '0';
    vstockid                      stm_stock.stm_stock_id%type;
    v_max_journal_discharge_id    doc_document.doc_document_id%type;
    v_doc_record_id               doc_record.doc_record_id%type;
    v_test_in_only_not_confirm    doc_position.doc_position_id%type;
    v_balance_quantity            doc_position.pos_balance_quantity%type;
    v_inter_char                  varchar2(30);
    v_c_project_consolidation     doc_journal_detail.c_project_consolidation%type;
    v_c_invoice_expiry_input_type doc_document.c_invoice_expiry_input_type%type;
    v_signe                       integer;
  begin
    delete      gal_conso_doc_position_temp;

    -- si aucune date n'est donnée, retourne les données de la table DOC_POSITION pour le projet
    if     v_event_snapshotdate is null
       and v_compta_snapshotdate is null then
      vtbldocposition  := ttbldocposition();
      -- retourne les données
      read_position_not_journal(vtbldocposition);

      if vtbldocposition.count > 0 then
        for i in vtbldocposition.first .. vtbldocposition.last loop
          insert into gal_conso_doc_position_temp
               values vtbldocposition(i);
        end loop;
      end if;

      disengage_bill_book(true);
    else
      -- photo à date
      -- recherche des données dans la table de journalisation
      begin
        read_position_journal(v_event_snapshotdate, v_compta_snapshotdate, vtbldocpositionjournal);

        -- recherche des dernières informations
        for tpldoc_position_journal in (select   *
                                            from doc_position_detail_gal
                                        order by doc_position_id desc
                                               , doc_rec_id_doc_pos_id desc
                                               , doc_journal_detail_id desc) loop
          if voldposid <> tpldoc_position_journal.doc_rec_id_doc_pos_id then
            -- le premier TGT_DATE porte des infos fausses dans le journal au niveau amount position -- pas nécessaire de tester ce cas, on va cherhcer l'info sur l'événememt suivant
            -- CONF_TGT ne nous intéresse pas
            if     tpldoc_position_journal.c_doc_journal_detail <> 'CONF_TGT'
               and tpldoc_position_journal.c_doc_journal_detail <> 'TGT_DATE' then
              v_c_project_consolidation  := tpldoc_position_journal.c_project_consolidation;
              v_signe                    := 1;

              begin
                select nvl(C_INVOICE_EXPIRY_INPUT_TYPE, 0)
                  into v_c_invoice_expiry_input_type
                  from doc_document
                 where doc_document_id = tpldoc_position_journal.doc_document_id;
              exception
                when no_data_found then
                  v_c_invoice_expiry_input_type  := 0;
              end;

              if     tpldoc_position_journal.c_doc_journal_detail = 'UPDATE'
                 and tpldoc_position_journal.pos_balance_quantity = 0
                 and tpldoc_position_journal.djd_reversal_entry = 1 then
                select (djd_old_pos_final_qty - djd_new_pos_final_qty)
                  into v_signe
                  from doc_journal_detail
                 where doc_journal_detail_id = tpldoc_position_journal.doc_journal_detail_id;

                if v_signe <> 0 then
                  v_signe  := -1;
                else
                  v_signe  := 1;
                end if;
              end if;

              if tpldoc_position_journal.c_doc_journal_detail in('DELETE', 'CANCEL', 'BALANCE', 'BAL_EXT') then
                voldposid  := tpldoc_position_journal.doc_rec_id_doc_pos_id;
              -- traitement du cas de changement de dossier -> on a un update négatif. On peut avoir la même en cas d'update sur le même dossier mais
              -- avec un changement de date
              elsif     tpldoc_position_journal.c_doc_journal_detail = 'DISCHARGED'
                    and v_c_project_consolidation <> 2
                    and tpldoc_position_journal.pos_balance_quantity = 0
                    and v_c_invoice_expiry_input_type = 0 then
                voldposid  := tpldoc_position_journal.doc_rec_id_doc_pos_id;
              elsif     tpldoc_position_journal.c_doc_journal_detail =   -- changement de qte sur un doc qui fait que la quantité balance = 0
                                                                      'UPDATE'
                    and tpldoc_position_journal.pos_balance_quantity = 0
                    and v_c_project_consolidation <> 2
                    and v_c_invoice_expiry_input_type = 0
                    and v_signe = 1 then
                voldposid  := tpldoc_position_journal.doc_rec_id_doc_pos_id;
              elsif     tpldoc_position_journal.c_doc_journal_detail = 'UPD_TGT'
                    and tpldoc_position_journal.pos_balance_quantity = 0 then
                voldposid  := tpldoc_position_journal.doc_rec_id_doc_pos_id;
              elsif     tpldoc_position_journal.c_doc_journal_detail = 'UPDATE'
                    and tpldoc_position_journal.djd_reversal_entry <> 0
                    and v_signe = 1 then
                -- pas de journalisation de la table doc_imputation -> donc comme le doc_record_id est inialisé depuis la table non historisé, on est sur que le doc_record_id est correct
                if tpldoc_position_journal.is_imputation = 0 then
                  begin
                    select nvl(doc_record_id, 0)
                      into v_doc_record_id
                      from doc_journal_detail
                     where doc_journal_detail_id =
                             (select max(doc_journal_detail_id)
                                from doc_journal_detail
                               where djd_transaction_id = tpldoc_position_journal.djd_transaction_id
                                 and doc_position_id = tpldoc_position_journal.doc_position_id);
                  --and doc_journal_detail_id > tpldoc_position_journal.doc_journal_detail_id
                  exception
                    when no_data_found then
                      v_doc_record_id  := null;
                  end;
                else
                  v_doc_record_id  := tpldoc_position_journal.doc_record_id;
                end if;

                if v_doc_record_id <> tpldoc_position_journal.doc_record_id then
                  voldposid  := tpldoc_position_journal.doc_rec_id_doc_pos_id;
                end if;
              else
                -- entrée dans la boucle où la table de journal va être utilisée
                -- décharge partielle avec donc fils en attenet de confirmation -> on va les chercher dans la table prov
                -- mais la dernière trace de discharged dans la table journal contient les psotions qui n'ont pas été déchargées ni en attente de confirmation sur les fils

                -- cas à lire dans la table journal djd_reversalentry -> pas une trrace d'extourne dans la table de journal -> voir analyse jsc
                if    (    tpldoc_position_journal.c_doc_journal_detail in('CONFIRM', 'UPDATE', 'INSERT', 'INS_DISCH', 'DEL_TGT', 'DISCHARGED')
                       and tpldoc_position_journal.djd_reversal_entry = 0
                      )
                   or (    tpldoc_position_journal.c_doc_journal_detail in('UPD_TGT', 'DEL_TGT')
                       and tpldoc_position_journal.pos_balance_quantity > 0)
                   or (    tpldoc_position_journal.c_doc_journal_detail in('UPDATE')
                       and v_signe = -1) then
                  -- on a lu l'info -> on peut passer à la pos suivante -> le journal est trié chronologiquement
                  voldposid  := tpldoc_position_journal.doc_rec_id_doc_pos_id;

                  declare
                    vtpldocposition tdocposition;
                  begin
                    -- recherche du stock si pas dans la table d'historique - le stock n'était pas renseigné dans la table journal à sa mise en pace
                    if tpldoc_position_journal.stm_stock_id is null then
                      select stm_stock_id
                        into vstockid
                        from doc_position
                       where doc_position_id = tpldoc_position_journal.doc_position_id;
                    else
                      vstockid  := tpldoc_position_journal.stm_stock_id;
                    end if;

                    vtpldocposition.doc_position_id               := tpldoc_position_journal.doc_position_id;
                    vtpldocposition.doc_document_id               := tpldoc_position_journal.doc_document_id;
                    vtpldocposition.pos_number                    := tpldoc_position_journal.pos_number;
                    vtpldocposition.pac_third_id                  := tpldoc_position_journal.pac_third_id;
                    vtpldocposition.pos_reference                 := tpldoc_position_journal.pos_reference;
                    vtpldocposition.pos_long_description          := tpldoc_position_journal.pos_long_description;
                    vtpldocposition.pos_short_description         := tpldoc_position_journal.pos_short_description;
                    vtpldocposition.c_gauge_type_pos              := tpldoc_position_journal.c_gauge_type_pos;
                    vtpldocposition.c_doc_pos_status              := tpldoc_position_journal.c_doc_pos_status;
                    vtpldocposition.gco_good_id                   := tpldoc_position_journal.gco_good_id;
                    vtpldocposition.doc_record_id                 := tpldoc_position_journal.doc_record_id;
                    vtpldocposition.pac_representative_id         := tpldoc_position_journal.pac_representative_id;
                    vtpldocposition.pac_person_id                 := tpldoc_position_journal.pac_person_id;
                    vtpldocposition.fam_fixed_assets_id           := tpldoc_position_journal.fam_fixed_assets_id;
                    vtpldocposition.c_fam_transaction_typ         := tpldoc_position_journal.c_fam_transaction_typ;
                    vtpldocposition.hrm_person_id                 := tpldoc_position_journal.hrm_person_id;
                    vtpldocposition.acs_financial_account_id      := tpldoc_position_journal.acs_financial_account_id;
                    vtpldocposition.acs_division_account_id       := tpldoc_position_journal.acs_division_account_id;
                    vtpldocposition.acs_cpn_account_id            := tpldoc_position_journal.acs_cpn_account_id;
                    vtpldocposition.acs_cda_account_id            := tpldoc_position_journal.acs_cda_account_id;
                    vtpldocposition.acs_pf_account_id             := tpldoc_position_journal.acs_pf_account_id;
                    vtpldocposition.acs_pj_account_id             := tpldoc_position_journal.acs_pj_account_id;
                    vtpldocposition.pos_convert_factor            := tpldoc_position_journal.pos_convert_factor;
                    vtpldocposition.pos_basis_quantity            := tpldoc_position_journal.pos_basis_quantity;
                    vtpldocposition.pos_intermediate_quantity     := tpldoc_position_journal.pos_intermediate_quantity;
                    vtpldocposition.pos_final_quantity            := tpldoc_position_journal.pos_final_quantity;
                    vtpldocposition.pos_balance_quantity          := tpldoc_position_journal.pos_balance_quantity;
                    vtpldocposition.pos_basis_quantity_su         := tpldoc_position_journal.pos_basis_quantity_su;
                    vtpldocposition.pos_intermediate_quantity_su  := tpldoc_position_journal.pos_intermediate_quantity_su;
                    vtpldocposition.pos_final_quantity_su         := tpldoc_position_journal.pos_final_quantity_su;
                    vtpldocposition.stm_stock_id                  := vstockid;
                    vtpldocposition.pos_gross_unit_value          := tpldoc_position_journal.pos_gross_unit_value;
                    vtpldocposition.pos_gross_unit_value_incl     := tpldoc_position_journal.pos_gross_unit_value_incl;
                    vtpldocposition.pos_net_unit_value            := tpldoc_position_journal.pos_net_unit_value;
                    vtpldocposition.pos_net_unit_value_incl       := tpldoc_position_journal.pos_net_unit_value_incl;
                    vtpldocposition.pos_gross_value               := tpldoc_position_journal.pos_gross_value;
                    vtpldocposition.pos_gross_value_b             := tpldoc_position_journal.pos_gross_value_b;
                    vtpldocposition.pos_gross_value_incl          := tpldoc_position_journal.pos_gross_value_incl;
                    vtpldocposition.pos_gross_value_incl_b        := tpldoc_position_journal.pos_gross_value_incl_b;
                    vtpldocposition.pos_net_value_excl            := tpldoc_position_journal.pos_net_value_excl;

                    -- dans le gestion à l'affaire on est obligé de calculer le montant de la pos sur ds doc qui ont toujours le montant de pos total
                    -- ici, le montant de la pos peut être recalculé selon les cas (cas des décharge de type 2)
                    case
                      when tpldoc_position_journal.pos_balance_quantity = 0
                                                                           --AND v_c_invoice_expiry_input_type > 0
                    then
                        vtpldocposition.pos_net_value_excl_b  := tpldoc_position_journal.pos_net_value_excl_b * v_signe;
                      else
                        vtpldocposition.pos_net_value_excl_b  :=
                          (tpldoc_position_journal.pos_final_quantity *
                           tpldoc_position_journal.pos_net_value_excl_b /
                           tpldoc_position_journal.pos_balance_quantity
                          );
                    end case;

                    vtpldocposition.pos_net_value_incl            := tpldoc_position_journal.pos_net_value_incl;
                    vtpldocposition.pos_net_value_incl_b          := tpldoc_position_journal.pos_net_value_incl_b;
                    vtpldocposition.dic_imp_free1_id              := tpldoc_position_journal.dic_imp_free1_id;
                    vtpldocposition.dic_imp_free2_id              := tpldoc_position_journal.dic_imp_free2_id;
                    vtpldocposition.dic_imp_free3_id              := tpldoc_position_journal.dic_imp_free3_id;
                    vtpldocposition.dic_imp_free4_id              := tpldoc_position_journal.dic_imp_free4_id;
                    vtpldocposition.dic_imp_free5_id              := tpldoc_position_journal.dic_imp_free5_id;
                    vtpldocposition.pos_imf_number_2              := tpldoc_position_journal.pos_imf_number_2;
                    vtpldocposition.pos_imf_number_3              := tpldoc_position_journal.pos_imf_number_3;
                    vtpldocposition.pos_imf_number_4              := tpldoc_position_journal.pos_imf_number_4;
                    vtpldocposition.pos_imf_number_5              := tpldoc_position_journal.pos_imf_number_5;
                    vtpldocposition.pos_imf_text_1                := tpldoc_position_journal.pos_imf_text_1;
                    vtpldocposition.pos_imf_text_2                := tpldoc_position_journal.pos_imf_text_2;
                    vtpldocposition.pos_imf_text_3                := tpldoc_position_journal.pos_imf_text_3;
                    vtpldocposition.pos_imf_text_4                := tpldoc_position_journal.pos_imf_text_4;
                    vtpldocposition.pos_imf_text_5                := tpldoc_position_journal.pos_imf_text_5;
                    vtpldocposition.a_confirm                     := tpldoc_position_journal.a_confirm;
                    vtpldocposition.a_datecre                     := tpldoc_position_journal.a_datecre;
                    vtpldocposition.a_datemod                     := tpldoc_position_journal.a_datemod;
                    vtpldocposition.a_idcre                       := tpldoc_position_journal.a_idcre;
                    vtpldocposition.a_idmod                       := tpldoc_position_journal.a_idmod;
                    vtpldocposition.a_reclevel                    := tpldoc_position_journal.a_reclevel;
                    vtpldocposition.a_recstatus                   := tpldoc_position_journal.a_recstatus;
                    vtpldocposition.c_project_consolidation       := tpldoc_position_journal.c_project_consolidation;

                    -- cas de avenant, pas de journaéisation du numéro
                    begin
                      select dmt_number
                        into v_inter_char
                        from doc_document
                       where doc_document_id = tpldoc_position_journal.doc_document_id;

                      vtpldocposition.dmt_number  := v_inter_char;
                    exception
                      when no_data_found then
                        vtpldocposition.dmt_number  := tpldoc_position_journal.dmt_number;
                    end;

                    vtpldocposition.dmt_date_document             := tpldoc_position_journal.dmt_date_document;
                    vtpldocposition.doc_gauge_id                  := tpldoc_position_journal.doc_gauge_id;
                    vtpldocposition.doc_journal_header_id         := tpldoc_position_journal.doc_journal_header_id;
                    vtpldocposition.is_imputation                 := tpldoc_position_journal.is_imputation;
                    vtpldocposition.doc_rcd_id_doc_pos_id         := tpldoc_position_journal.doc_rec_id_doc_pos_id;
                    vtpldocposition.doc_position_imputation_id    := tpldoc_position_journal.doc_position_imputation_id;
                    vtpldocposition.doc_journal_detail_id         := tpldoc_position_journal.doc_journal_detail_id;
                    vtpldocposition.doc_journal_header_id         := tpldoc_position_journal.doc_journal_header_id;
                    vtpldocposition.acs_financial_currency_id     := tpldoc_position_journal.acs_financial_currency_id;

                    -- le rate of excange n'est pas journalisé sur toutes les lignes
                    if nvl(tpldoc_position_journal.dmt_rate_of_exchange, 0) <> 0 then
                      vtpldocposition.dmt_rate_of_exchange  := tpldoc_position_journal.dmt_rate_of_exchange;
                    else
                      begin
                        select dmt_rate_of_exchange
                          into vtpldocposition.dmt_rate_of_exchange
                          from DOC_POSITION_DETAIL_GAL dpdg1
                         where doc_journal_detail_id =
                                              (select max(doc_journal_detail_id)
                                                 from DOC_POSITION_DETAIL_GAL dpdg2
                                                where dpdg2.doc_position_id = tpldoc_position_journal.doc_position_id
                                                  and dpdg2.dmt_rate_of_exchange is not null);
                      exception
                        when no_data_found then
                          select dmt_rate_of_exchange
                            into vtpldocposition.dmt_rate_of_exchange
                            from doc_position pos
                               , doc_document doc
                           where pos.doc_position_id = tpldoc_position_journal.doc_position_id
                             and doc.doc_document_id = pos.doc_document_id;
                      end;
                    end if;

                    vtpldocposition.dmt_date_value                := tpldoc_position_journal.dmt_date_value;
                    vtpldocposition.pos_balanced                  := tpldoc_position_journal.pos_balanced;

                    insert into gal_conso_doc_position_temp
                         values vtpldocposition;
                  end;
                end if;
              end if;
            end if;
          end if;
        end loop;
      end;

      -- Ventilation = NON
      insert into DOC_TMP_POS_JOURNAL_POS
                  (DOC_POSITION_ID
                  )
        select DJD.DOC_POSITION_ID
          from DOC_JOURNAL_DETAIL_PROV DJD
             , (select   DJD2.DOC_POSITION_ID
                       , max(DJD2.DOC_JOURNAL_DETAIL_PROV_ID) as DOC_JOURNAL_DETAIL_PROV_ID
                    from DOC_JOURNAL_DETAIL_PROV DJD2
                       , GAL_CONSO_DOC_RECORD_TEMP RCO2
                   where DJD2.DOC_RECORD_ID = RCO2.DOC_RECORD_ID
                     and DJD2.DJD_JOURNAL_DOCUMENT_DATE <= v_compta_snapshotdate
                     and DJD2.A_DATECRE <= v_event_snapshotdate
                     and DJD2.DJD_PROJECT_CONSOLIDATION = 1
                     and not exists(select 1
                                      from GAL_CONSO_IS_ACOMPTE_TEMP
                                     where GCO_GOOD_ID = DJD2.GCO_GOOD_ID)
                     and not exists(select 1
                                      from GAL_CONSO_IS_ACOMPTE_TEMP
                                     where DOC_POSITION_ID = DJD2.DOC_POSITION_ID)
                     and not exists(select 1
                                      from GAL_CONSO_POS2EXCL_FROM_EXPIRY
                                     where DOC_POSITION_ID = DJD2.DOC_POSITION_ID)
                group by DJD2.DOC_POSITION_ID) DJD_MAX
         where DJD.DOC_JOURNAL_DETAIL_PROV_ID = DJD_MAX.DOC_JOURNAL_DETAIL_PROV_ID
           and DJD.POS_IMPUTATION = 0;

      -- Ventilation = OUI
      insert into DOC_TMP_POS_JOURNAL_POS
                  (DOC_POSITION_ID
                  )
        select DJD.DOC_POSITION_ID
          from DOC_JOURNAL_DETAIL_PROV DJD
             , (select   max(DJD2.DOC_JOURNAL_DETAIL_PROV_ID) as DOC_JOURNAL_DETAIL_PROV_ID
                    from DOC_JOURNAL_DETAIL_PROV DJD2
                       , GAL_CONSO_POS_IMPUTATION_TEMP IMP
                   where DJD2.DOC_POSITION_ID = IMP.DOC_POSITION_ID
                     and DJD2.DJD_JOURNAL_DOCUMENT_DATE <= v_compta_snapshotdate
                     and DJD2.A_DATECRE <= v_event_snapshotdate
                     and DJD2.DJD_PROJECT_CONSOLIDATION = 1
                     and not exists(select 1
                                      from GAL_CONSO_IS_ACOMPTE_TEMP
                                     where GCO_GOOD_ID = DJD2.GCO_GOOD_ID)
                     and not exists(select 1
                                      from GAL_CONSO_IS_ACOMPTE_TEMP
                                     where DOC_POSITION_ID = DJD2.DOC_POSITION_ID)
                     and not exists(select 1
                                      from GAL_CONSO_POS2EXCL_FROM_EXPIRY
                                     where DOC_POSITION_ID = DJD2.DOC_POSITION_ID)
                group by DJD2.DOC_POSITION_ID) DJD_MAX
         where DJD.DOC_JOURNAL_DETAIL_PROV_ID = DJD_MAX.DOC_JOURNAL_DETAIL_PROV_ID
           and DJD.POS_IMPUTATION = 1
           and not exists(select 1
                            from DOC_TMP_POS_JOURNAL_POS
                           where DOC_POSITION_ID = DJD.DOC_POSITION_ID);

      -- doc non confirmés
      for v_cur_pos_to_confirm in ( (select doc_position_id
                                       from doc_tmp_pos_journal_pos)
                                   minus
                                   (select distinct doc_position_id
                                               from doc_position_detail_gal) ) loop
        begin
          select doc_position_id
            into v_test_in_only_not_confirm
            from gal_conso_doc_position_temp
           where doc_position_id = v_cur_pos_to_confirm.doc_position_id;
        exception
          when no_data_found then
            insert_pos_not_confirmed(v_event_snapshotdate, v_compta_snapshotdate, v_cur_pos_to_confirm.doc_position_id);
        end;
      end loop;

      disengage_bill_book(false);
    end if;
  end inittabledocposition;

  procedure inittablegal_hours(
    aprojectid             gal_project.gal_project_id%type
  , v_event_snapshootdate  date
  , v_compta_snapshootdate date
  , v_TauxEco              integer default 0
  , aDateMax               date
  )
  is
    vtblgalhours ttblgalhours := ttblgalhours();
  begin
    delete      gal_conso_hours_temp;

    if     v_event_snapshootdate is null
       and v_compta_snapshootdate is null then
      -- si aucune date n'est donnée, retourne les données de la table GAL_HOURS pour le projet
      select gal_hours_id
           , hrm_person_id
           , gal_project_id
           , gal_task_id
           , gal_task_link_id
           , gal_cost_center_id
           , gal_budget_id
           , gal_task_budget_id
           , hou_pointing_date
           , hou_worked_time
           , hou_hourly_rate
           , a_datecre
           , a_idcre
      bulk collect into vtblgalhours
        from (select hou.gal_hours_id
                   , hou.hrm_person_id
                   , hou.gal_project_id
                   , hou.gal_task_id
                   , hou.gal_task_link_id
                   , hou.gal_cost_center_id
                   , hou.gal_budget_id
                   , tas.gal_budget_id gal_task_budget_id
                   , hou.hou_pointing_date
                   , hou.hou_worked_time
                   , case
                       when v_TauxEco = 0 then hou.hou_hourly_rate
                       else hou.hou_hourly_rate_eco
                     end as hou_hourly_rate
                   , hou.a_datecre
                   , hou.a_idcre
                   , hou.hou_hourly_rate_eco
                from gal_hours hou
                   , gal_task tas
                   , gal_conso_doc_record_temp rco
               where hou.gal_project_id = aprojectid
                 and hou.gal_budget_id is null
                 and tas.gal_task_id = hou.gal_task_id
                 and tas.doc_record_id = rco.doc_record_id
              union
              select hou.gal_hours_id
                   , hou.hrm_person_id
                   , hou.gal_project_id
                   , hou.gal_task_id
                   , hou.gal_task_link_id
                   , hou.gal_cost_center_id
                   , hou.gal_budget_id
                   , null gal_task_budget_id
                   , hou.hou_pointing_date
                   , hou.hou_worked_time
                   , case
                       when v_TauxEco = 0 then hou.hou_hourly_rate
                       else hou.hou_hourly_rate_eco
                     end as hou_hourly_rate
                   , hou.a_datecre
                   , hou.a_idcre
                   , hou.hou_hourly_rate_eco
                from gal_hours hou
                   , gal_budget bud
                   , gal_conso_doc_record_temp rco
               where hou.gal_project_id = aprojectid
                 and hou.gal_budget_id is not null
                 and bud.gal_budget_id = hou.gal_budget_id
                 and bud.doc_record_id = rco.doc_record_id);

      -- retourne les données
      if vtblgalhours.count > 0 then
        for i in vtblgalhours.first .. vtblgalhours.last loop
          insert into gal_conso_hours_temp
               values vtblgalhours(i);
        end loop;
      end if;
    else
      -- photo à date
      declare
        type ttblgalhoursjournal is table of gal_hours_journal%rowtype
          index by pls_integer;

        vtblgalhoursjournal ttblgalhoursjournal;

        cursor crgal_hours_journal(acrprojectid gal_project.gal_project_id%type, v_compta_snapshotdate date, v_event_snapshotdate date)
        is
          select   hoj.*
              from gal_hours_journal hoj
             where hoj.gal_project_id = acrprojectid
               and hoj.hou_pointing_date <= v_compta_snapshootdate
               and hoj.a_datecre <= v_event_snapshootdate
          order by hoj.gal_hours_id
                 , gal_hours_journal_id desc
                 , hoj.hou_pointing_date desc;

        voldhoursid         gal_hours.gal_hours_id%type   := 0;
      begin
        -- recherche des données dans la table de journalisation
        open crgal_hours_journal(aprojectid, v_compta_snapshootdate, v_event_snapshootdate);

        fetch crgal_hours_journal
        bulk collect into vtblgalhoursjournal;

        close crgal_hours_journal;

        -- recherche des dernières informations
        if vtblgalhoursjournal.count > 0 then
          for i in vtblgalhoursjournal.first .. vtblgalhoursjournal.last loop
            if voldhoursid <> vtblgalhoursjournal(i).gal_hours_id then
              voldhoursid  := vtblgalhoursjournal(i).gal_hours_id;

              if vtblgalhoursjournal(i).hoj_new_value <> -1 then
                declare
                  vtplgalhours trecgalhours;
                begin
                  vtplgalhours.gal_hours_id        := vtblgalhoursjournal(i).gal_hours_id;
                  vtplgalhours.hrm_person_id       := vtblgalhoursjournal(i).hrm_person_id;
                  vtplgalhours.gal_project_id      := vtblgalhoursjournal(i).gal_project_id;
                  vtplgalhours.gal_task_id         := vtblgalhoursjournal(i).gal_task_id;
                  vtplgalhours.gal_task_link_id    := vtblgalhoursjournal(i).gal_task_link_id;
                  vtplgalhours.gal_cost_center_id  := vtblgalhoursjournal(i).gal_cost_center_id;
                  vtplgalhours.gal_budget_id       := vtblgalhoursjournal(i).gal_budget_id;
                  vtplgalhours.gal_task_budget_id  := vtblgalhoursjournal(i).gal_task_budget_id;
                  vtplgalhours.hou_pointing_date   := vtblgalhoursjournal(i).hou_pointing_date;
                  vtplgalhours.hou_worked_time     := vtblgalhoursjournal(i).hou_worked_time;

                  if v_TauxEco = 1 then
                    vtplgalhours.hou_hourly_rate  := vtblgalhoursjournal(i).hou_hourly_rate_eco;
                  else
                    vtplgalhours.hou_hourly_rate  := vtblgalhoursjournal(i).hou_hourly_rate;
                  end if;

                  vtplgalhours.a_datecre           := vtblgalhoursjournal(i).a_datecre;
                  vtplgalhours.a_idcre             := vtblgalhoursjournal(i).a_idcre;

                  insert into gal_conso_hours_temp
                       values vtplgalhours;
                end;
              end if;
            end if;
          end loop;
        end if;
      end;
    end if;

    if v_TauxEco = 1 then
      delete      gal_conso_hours_temp
            where trunc(hou_pointing_date, 'DDD') >= trunc(aDateMax, 'DDD');
    end if;
  end inittablegal_hours;

  /**
    * Description
    *    Retourne une structure GAL_TASK_LINK pour un projet et une date donnée
    */
  procedure inittablegal_task_link(aprojectid gal_project.gal_project_id%type, v_event_snapshootdate date, v_compta_snapshootdate date)
  is
    vtblgaltasklink      ttblgaltasklink := ttblgaltasklink();
    v_tal_hours_achieved number;
    v_number             number;
  begin
    delete      gal_conso_tas_link_temp;

    if     v_event_snapshootdate is null
       and v_compta_snapshootdate is null then
      -- si aucune date n'est donnée, retourne les données de la table GAL_TASK_LINK pour le projet
      select tal.gal_task_link_id
           , tal.gal_task_id
           , tal.c_tal_state
           , tal.fal_factory_floor_id
           , tal.fal_fal_factory_floor_id
           , null
           , tal.scs_step_number
           , tal.scs_short_descr
           , tal.scs_long_descr
           , tal.tal_begin_plan_date
           , tal.tal_due_tsk
           , tal.tal_achieved_tsk
           , tal.tal_tsk_balance
           , tal.tal_hourly_rate
           , null
           , tal.a_idcre
           , 0
      bulk collect into vtblgaltasklink
        from gal_task_link tal
           , gal_task tas
           , gal_conso_doc_record_temp rco
       where tas.gal_project_id = aprojectid
         and tal.gal_task_id = tas.gal_task_id
         and tas.doc_record_id = rco.doc_record_id;

      -- retourne les données
      if vtblgaltasklink.count > 0 then
        for i in vtblgaltasklink.first .. vtblgaltasklink.last loop
          insert into gal_conso_tas_link_temp
               values vtblgaltasklink(i);
        end loop;
      end if;
    else
      -- photo à date
      declare
        type ttblgaltasklinkjournal is table of gal_conso_tas_link_temp%rowtype
          index by pls_integer;

        vtblgaltasklinkjournal ttblgaltasklinkjournal;

        cursor crgal_task_link_journal(acrprojectid gal_project.gal_project_id%type, v_event_snapshootdate date, v_compta_snapshootdate date)
        is
          select   tlj.gal_task_link_id
                 , tlj.gal_task_id
                 , tlj.c_tal_state
                 , tlj.fal_factory_floor_id
                 , tlj.fal_fal_factory_floor_id
                 , null
                 , tlj.scs_step_number
                 , tlj.scs_short_descr
                 , tlj.scs_long_descr
                 , tal.tal_begin_plan_date
                 , tlj.tal_due_tsk
                 , tlj.tal_achieved_tsk
                 , tlj.tal_tsk_balance
                 , tlj.tal_hourly_rate
                 , tlj.taj_imputation_date
                 , tlj.a_idcre
                 , tlj.taj_new_value
              from gal_task_link_journal tlj
                 , gal_task tas
                 , gal_task_link tal
             where tas.gal_project_id = acrprojectid
               and tlj.gal_task_id = tas.gal_task_id
               and tal.gal_task_link_id = tlj.gal_task_link_id
               and tlj.taj_imputation_date <= v_compta_snapshootdate
               and tlj.a_datecre <= v_event_snapshootdate
          order by tlj.gal_task_link_id
                 , tlj.gal_task_link_journal_id desc
                 , tlj.taj_imputation_date desc;

        voldtasklinkid         gal_task_link.gal_task_link_id%type   := 0;
      begin
        -- recherche des données dans la table de journalisation
        open crgal_task_link_journal(aprojectid, v_event_snapshootdate, v_compta_snapshootdate);

        fetch crgal_task_link_journal
        bulk collect into vtblgaltasklinkjournal;

        close crgal_task_link_journal;

        -- recherche des dernières informations
        if vtblgaltasklinkjournal.count > 0 then
          for i in vtblgaltasklinkjournal.first .. vtblgaltasklinkjournal.last loop
            if voldtasklinkid <> vtblgaltasklinkjournal(i).gal_task_link_id then
              voldtasklinkid  := vtblgaltasklinkjournal(i).gal_task_link_id;

              if     vtblgaltasklinkjournal(i).taj_new_value <> -1
                 and vtblgaltasklinkjournal(i).c_tal_state <> '40'
                                                                  -- hmo: erreur de journalisation on ne tient pa compte de op soldée. Ne pose pas problème, juste un gin de temps car de toutee façon les reste à fiare est à 0 pour les op soldées
              then
                declare
                  vtplgaltasklink gal_conso_tas_link_temp%rowtype;
                begin
                  select nvl(sum(hou_worked_time), 0)
                    into v_tal_hours_achieved
                    from gal_conso_hours_temp
                   where gal_task_link_id = vtblgaltasklinkjournal(i).gal_task_link_id;

                  vtblgaltasklinkjournal(i).tal_tsk_balance  :=
                                  nvl(vtblgaltasklinkjournal(i).tal_tsk_balance, 0) -
                                  (v_tal_hours_achieved - nvl(vtblgaltasklinkjournal(i).tal_achieved_tsk, 0)
                                  );

                  if vtblgaltasklinkjournal(i).tal_tsk_balance < 0 then
                    vtblgaltasklinkjournal(i).tal_tsk_balance  := 0;
                  end if;

                  vtplgaltasklink.gal_task_link_id           := vtblgaltasklinkjournal(i).gal_task_link_id;
                  vtplgaltasklink.gal_task_id                := vtblgaltasklinkjournal(i).gal_task_id;
                  vtplgaltasklink.c_tal_state                := vtblgaltasklinkjournal(i).c_tal_state;
                  vtplgaltasklink.fal_factory_floor_id       := vtblgaltasklinkjournal(i).fal_factory_floor_id;
                  vtplgaltasklink.fal_fal_factory_floor_id   := vtblgaltasklinkjournal(i).fal_fal_factory_floor_id;
                  vtplgaltasklink.gal_task_budget_id         := vtblgaltasklinkjournal(i).gal_task_budget_id;
                  vtplgaltasklink.scs_step_number            := vtblgaltasklinkjournal(i).scs_step_number;
                  vtplgaltasklink.scs_short_descr            := vtblgaltasklinkjournal(i).scs_short_descr;
                  vtplgaltasklink.scs_long_descr             := vtblgaltasklinkjournal(i).scs_long_descr;
                  vtplgaltasklink.tal_begin_plan_date        := vtblgaltasklinkjournal(i).tal_begin_plan_date;
                  vtplgaltasklink.tal_due_tsk                := vtblgaltasklinkjournal(i).tal_due_tsk;
                  vtplgaltasklink.tal_achieved_tsk           := vtblgaltasklinkjournal(i).tal_achieved_tsk;
                  vtplgaltasklink.tal_tsk_balance            := vtblgaltasklinkjournal(i).tal_tsk_balance;
                  vtplgaltasklink.tal_hourly_rate            := vtblgaltasklinkjournal(i).tal_hourly_rate;
                  vtplgaltasklink.tal_maj_imputation_date    := vtblgaltasklinkjournal(i).tal_maj_imputation_date;
                  vtplgaltasklink.a_idcre                    := vtblgaltasklinkjournal(i).a_idcre;

                  insert into gal_conso_tas_link_temp
                       values vtplgaltasklink;
                end;
              end if;
            end if;
          end loop;
        end if;
      end;

      --cas des opération ou les heures comptables sont siaises avant le lencement cpomptab -> la requête heures va chercher des infos d'op et elles n'existent pas dans les tabls de journel
      -- utiles que pour les photo à date comptabées
      for v_cur_task_link in (select distinct (gal_task_link_id)
                                         from gal_conso_hours_temp
                                        where gal_task_link_id is not null) loop
        begin
          select distinct gal_task_link_id
                     into v_number
                     from gal_conso_tas_link_temp
                    where gal_task_link_id = v_cur_task_link.gal_task_link_id;
        exception
          when no_data_found then
            insert into gal_conso_tas_link_temp
                        (gal_task_link_id
                       , gal_task_id
                       , c_tal_state
                       , fal_factory_floor_id
                       , fal_fal_factory_floor_id
                       , scs_step_number
                       , scs_short_descr
                       , scs_long_descr
                       , tal_begin_plan_date
                       , tal_due_tsk
                       , tal_tsk_balance
                       , tal_hourly_rate
                        )
              select gal_task_link_id
                   , gal_task_id
                   , c_tal_state
                   , fal_factory_floor_id
                   , fal_fal_factory_floor_id
                   , scs_step_number
                   , scs_short_descr
                   , scs_long_descr
                   , tal_begin_plan_date
                   , tal_due_tsk
                   , 0
                   , tal_hourly_rate
                from gal_task_link
               where gal_task_link_id = v_cur_task_link.gal_task_link_id;
        end;
      end loop;
    end if;
  end inittablegal_task_link;

  /**
  * Description
  *    Retourne une structure GAL_BUDGET_LINE pour un projet et une date donnée
  */
  procedure inittablegal_budget_line(aprojectid gal_project.gal_project_id%type, v_event_snapshootdate date, v_compta_snapshootdate date)
  is
    vtblgalbudgetline ttblgalbudgetline := ttblgalbudgetline();
  begin
    delete      gal_conso_budget_line_temp;

    if     v_event_snapshootdate is null
       and v_compta_snapshootdate is null then
      -- si aucune date n'est donnée, retourne les données de la table GAL_BUDGET_LINE pour le projet
      select bul.gal_budget_line_id
           , bul.gal_budget_id
           , bul.gal_cost_center_id
           , bul.bli_sequence
           , bul.bli_wording
           , bul.bli_budget_quantity
           , bul.bli_budget_price
           , bul.bli_budget_amount
           , bul.bli_remaining_quantity
           , bul.bli_remaining_price
           , bul.bli_remaining_amount
           , bul.bli_hanging_spending_quantity
           , bul.bli_hanging_spending_amount
           , bul.bli_description
           , bul.bli_comment
           , bul.a_idcre
           , bul.a_datecre
           , bul.a_idmod
           , bul.a_datemod
           , bul.bli_last_budget_date
           , bul.bli_last_remaining_date
           , bul.bli_last_estimation_quantity
           , bul.bli_last_estimation_amount
           , 0
           , nvl(gal_budget_period_id, 0)
           , bul.bli_hanging_spending_amount_b
           , 0 as BLI_REMAINING_AMOUNT_AT_DATE
      bulk collect into vtblgalbudgetline
        from gal_budget_line bul
           , gal_budget bud   --,   gal_conso_doc_record_temp rco       ; hmo ne opermet pas de voir les budgets au niveau non-élémentaire -> dév budgétisation top_down
       where bud.gal_project_id = aprojectid
         and bul.gal_budget_id = bud.gal_budget_id;

      --and bud.doc_record_id = rco.doc_record_id            ; hmo ne opermet pas de voir les budgets au niveau non-élémentaire -> dév budgétisation top_down

      -- retourne les données
      if vtblgalbudgetline.count > 0 then
        for i in vtblgalbudgetline.first .. vtblgalbudgetline.last loop
          insert into gal_conso_budget_line_temp
               values vtblgalbudgetline(i);
        end loop;
      end if;
    else
      -- photo à date
      declare
        type ttblgalbudgetlinejournal is table of gal_conso_budget_line_temp%rowtype
          index by pls_integer;

        vtblgalbudgetlinejournal     ttblgalbudgetlinejournal;
        v_gal_budget_line_journal_id gal_budget_line_journal.gal_budget_line_journal_id%type;
        v_old_bli_last_budget_date   gal_budget_line_journal.bli_last_budget_date%type;

        cursor crgal_budget_line_journal(acrprojectid gal_project.gal_project_id%type, v_compta_snapshootdate date, v_event_snapshootdate date)
        is
          select   blj.gal_budget_line_id
                 , blj.gal_budget_id
                 , blj.gal_cost_center_id   -- lien sur budget line sne permet pa de gérer l'effacecemnt -> suppression hmo 13.05.08 -> données non utiles pourle moment
                 , null
                 , null
                 , blj.bli_budget_quantity
                 , blj.bli_budget_price
                 , blj.bli_budget_amount
                 , blj.bli_remaining_quantity
                 , blj.bli_remaining_price
                 , blj.bli_remaining_amount
                 , blj.bli_hanging_spending_quantity
                 , blj.bli_hanging_spending_amount
                 , blj.bli_description
                 , blj.bli_comment
                 , blj.a_idcre
                 , blj.a_datecre   -- lien sur budget line sne permet pa de gérer l'effacecemnt -> suppression hmo 13.05.08 -> données non utiles pour le moment
                 , null
                 , null
                 , blj.bli_last_budget_date
                 , case
                     when bli_remaining_amount is null then null
                     else blj.bli_last_remaining_date
                   end case
                 , blj.bli_last_estimation_quantity
                 , blj.bli_last_estimation_amount
                 , blj.blj_new_value
                 , nvl(gal_budget_period_id, 0)
                 , blj.bli_hanging_spending_amount_b
                 , 0 as BLI_REMAINING_AMOUNT_AT_DATE
              from gal_budget_line_journal blj
                 , gal_budget bud
             --             gal_conso_doc_record_temp rco        ; hmo ne opermet pas de voir les budgets au niveau non-élémentaire -> dév budgétisation top_down
             -- lien sur budget line sne permet pa de gérer l'effacecemnt -> suppression hmo 13.05.08
          where    bud.gal_project_id = acrprojectid
               --AND bud.doc_record_id = rco.doc_record_id            ; hmo ne opermet pas de voir les budgets au niveau non-élémentaire -> dév budgétisation top_down
               -- lien sur budget line sne permet pa de gérer l'effacecemnt -> suppression hmo 13.05.08
               and blj.gal_budget_id = bud.gal_budget_id
               and blj.a_datecre <= v_compta_snapshootdate
               and blj.a_datecre <= v_event_snapshootdate
          order by blj.gal_budget_id
                 , blj.gal_budget_line_id
                 , blj.gal_budget_line_journal_id desc;

        voldblid                     gal_budget_line.gal_budget_line_id%type                   := 0;
        j                            pls_integer                                               := 0;
      begin
        -- recherche des données dans la table de journalisation
        open crgal_budget_line_journal(aprojectid, v_compta_snapshootdate, v_event_snapshootdate);

        fetch crgal_budget_line_journal
        bulk collect into vtblgalbudgetlinejournal;

        close crgal_budget_line_journal;

        -- recherche des dernières informations
        if vtblgalbudgetlinejournal.count > 0 then
          for i in vtblgalbudgetlinejournal.first .. vtblgalbudgetlinejournal.last loop
            if voldblid <> vtblgalbudgetlinejournal(i).gal_budget_line_id then
              voldblid  := vtblgalbudgetlinejournal(i).gal_budget_line_id;

              if vtblgalbudgetlinejournal(i).blj_new_value = 1 then
                declare
                  vtplgalbudgetline gal_conso_budget_line_temp%rowtype;
                begin
                  vtplgalbudgetline.gal_budget_line_id             := vtblgalbudgetlinejournal(i).gal_budget_line_id;
                  vtplgalbudgetline.gal_budget_id                  := vtblgalbudgetlinejournal(i).gal_budget_id;
                  vtplgalbudgetline.gal_cost_center_id             := vtblgalbudgetlinejournal(i).gal_cost_center_id;
                  vtplgalbudgetline.bli_sequence                   := vtblgalbudgetlinejournal(i).bli_sequence;
                  vtplgalbudgetline.bli_wording                    := vtblgalbudgetlinejournal(i).bli_wording;
                  vtplgalbudgetline.bli_budget_quantity            := vtblgalbudgetlinejournal(i).bli_budget_quantity;
                  vtplgalbudgetline.bli_budget_price               := vtblgalbudgetlinejournal(i).bli_budget_price;
                  vtplgalbudgetline.bli_budget_amount              := vtblgalbudgetlinejournal(i).bli_budget_amount;
                  vtplgalbudgetline.bli_remaining_quantity         := vtblgalbudgetlinejournal(i).bli_remaining_quantity;
                  vtplgalbudgetline.bli_remaining_price            := vtblgalbudgetlinejournal(i).bli_remaining_price;
                  vtplgalbudgetline.bli_remaining_amount           := vtblgalbudgetlinejournal(i).bli_remaining_amount;
                  vtplgalbudgetline.bli_hanging_spending_quantity  := vtblgalbudgetlinejournal(i).bli_hanging_spending_quantity;
                  vtplgalbudgetline.bli_hanging_spending_amount    := vtblgalbudgetlinejournal(i).bli_hanging_spending_amount;
                  vtplgalbudgetline.bli_description                := vtblgalbudgetlinejournal(i).bli_description;
                  vtplgalbudgetline.bli_comment                    := vtblgalbudgetlinejournal(i).bli_comment;
                  vtplgalbudgetline.a_datecre                      := vtblgalbudgetlinejournal(i).a_datecre;
                  vtplgalbudgetline.a_idcre                        := vtblgalbudgetlinejournal(i).a_idcre;
                  vtplgalbudgetline.a_datemod                      := vtblgalbudgetlinejournal(i).a_datemod;
                  vtplgalbudgetline.a_idmod                        := vtblgalbudgetlinejournal(i).a_idmod;
                  vtplgalbudgetline.bli_last_budget_date           := vtblgalbudgetlinejournal(i).bli_last_budget_date;

                  if vtblgalbudgetlinejournal(i).bli_last_remaining_date is not null then
                    select max(gal_budget_line_journal_id)
                      into v_gal_budget_line_journal_id
                      from gal_budget_line_journal
                     where a_datecre = vtblgalbudgetlinejournal(i).a_datecre;

                    select bli_last_budget_date   --avec le nouveau mode de calcul qui part du reste à engager, on doit feinter, car la date de dernier rste à faire a été mise en sysdate depuis le début de l'historisation
                      into v_old_bli_last_budget_date   -- ce qui ne nous permet plus de savoir si on a modifier le budget ou le reste à engager (sysdate toujours > bli_last_budget_date
                      from gal_budget_line_journal
                     where gal_budget_line_journal_id = (select max(gal_budget_line_journal_id)
                                                           from gal_budget_line_journal
                                                          where gal_budget_line_journal_id < v_gal_budget_line_journal_id);

                    if v_old_bli_last_budget_date <> vtblgalbudgetlinejournal(i).bli_last_budget_date then
                      vtblgalbudgetlinejournal(i).bli_last_remaining_date  := sysdate - 100000;
                    end if;
                  end if;

                  vtplgalbudgetline.bli_last_remaining_date        := vtblgalbudgetlinejournal(i).bli_last_remaining_date;
                  vtplgalbudgetline.bli_last_estimation_quantity   := vtblgalbudgetlinejournal(i).bli_last_estimation_quantity;
                  vtplgalbudgetline.bli_last_estimation_amount     := vtblgalbudgetlinejournal(i).bli_last_estimation_amount;
                  vtplgalbudgetline.blj_new_value                  := 0;
                  vtplgalbudgetline.gal_budget_period_id           := vtblgalbudgetlinejournal(i).gal_budget_period_id;
                  vtplgalbudgetline.bli_hanging_spending_amount_B  := vtblgalbudgetlinejournal(i).bli_hanging_spending_amount_B;

                  insert into gal_conso_budget_line_temp
                       values vtplgalbudgetline;
                end;
              end if;
            end if;
          end loop;
        end if;
      end;
    end if;
  end inittablegal_budget_line;

  /**
  * Description : Crée en insert une ligne dans la table temp GAL_SPENDING_CONSOLIDATED
  *
  * @author Matthieu Lesur
  * @version Date 11.011.2005
  * @non-public
  */
  procedure create_gal_spending_consol(
    agalprojectid               gal_spending_consolidated.gal_project_id%type
  , asnapshotid                 gal_spending_detail.gal_snapshot_id%type
  , agalbudgetid                gal_spending_consolidated.gal_budget_id%type
  , agalcostcenterid            gal_spending_consolidated.gal_cost_center_id%type
  , abudgetquantity             gal_spending_consolidated.gsp_budget_quantity%type
  , abudgetamount               gal_spending_consolidated.gsp_budget_amount%type
  , acol1quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol1amount                 gal_spending_consolidated.gsp_col1_amount%type
  , acol2quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol2amount                 gal_spending_consolidated.gsp_col1_amount%type
  , acol3quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol3amount                 gal_spending_consolidated.gsp_col1_amount%type
  , acol4quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol4amount                 gal_spending_consolidated.gsp_col1_amount%type
  , acol5quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol5amount                 gal_spending_consolidated.gsp_col1_amount%type
  , atotalquantity              gal_spending_consolidated.gsp_total_quantity%type
  , atotalamount                gal_spending_consolidated.gsp_total_amount%type
  , aremainingquantity          gal_spending_consolidated.gsp_remaining_quantity%type
  , aremainingamount            gal_spending_consolidated.gsp_remaining_amount%type
  , amarginquantity             gal_spending_consolidated.gsp_margin_quantity%type
  , amarginamount               gal_spending_consolidated.gsp_margin_amount%type
  , apercmarginquantity         gal_spending_consolidated.gsp_perc_margin_quantity%type
  , apercmarginamount           gal_spending_consolidated.gsp_perc_margin_amount%type
  , aestimationtotalqty         gal_spending_consolidated.gsp_estimation_total_quantity%type
  , aestimationtotalamount      gal_spending_consolidated.gsp_estimation_total_amount%type
  , agal_budget_period_id       gal_budget_line.gal_budget_period_id%type
  , agsp_remaining_amount_delta gal_spending_consolidated.gsp_remaining_amount_delta%type
  )
  is
  begin
    insert into gal_spending_consolidated
                (gal_spending_consolidated_id
               , gal_snapshot_id
               , gal_project_id
               , gal_budget_id
               , gal_cost_center_id
               , gsp_budget_quantity
               , gsp_budget_amount
               , gsp_col1_quantity
               , gsp_col1_amount
               , gsp_col2_quantity
               , gsp_col2_amount
               , gsp_col3_quantity
               , gsp_col3_amount
               , gsp_col4_quantity
               , gsp_col4_amount
               , gsp_col5_quantity
               , gsp_col5_amount
               , gsp_total_quantity
               , gsp_total_amount
               , gsp_remaining_quantity
               , gsp_remaining_amount
               , gsp_margin_quantity
               , gsp_margin_amount
               , gsp_perc_margin_quantity
               , gsp_perc_margin_amount
               , gsp_estimation_total_quantity
               , gsp_estimation_total_amount
               , a_idcre
               , a_datecre
               , a_idmod
               , a_datemod
               , gal_budget_period_id
               , gsp_remaining_amount_delta
                )
         values (init_id_seq.nextval
               , asnapshotid
               , agalprojectid
               , agalbudgetid
               , agalcostcenterid
               , abudgetquantity
               , abudgetamount
               , acol1quantity
               , acol1amount
               , acol2quantity
               , acol2amount
               , acol3quantity
               , acol3amount
               , acol4quantity
               , acol4amount
               , acol5quantity
               , acol5amount
               , atotalquantity
               , atotalamount
               , aremainingquantity
               , aremainingamount
               , amarginquantity
               , amarginamount
               , apercmarginquantity
               , apercmarginamount
               , aestimationtotalqty
               , aestimationtotalamount
               , pcs.PC_I_LIB_SESSION.getuserini
               , sysdate
               , null
               , null
               , agal_budget_period_id
               , agsp_remaining_amount_delta
                );
  end create_gal_spending_consol;

  /**
  * Description : Màj d'une ligne dans la table GAL_SPENDING_CONSOLIDATED
  *
  * @author Matthieu Lesur
  * @version Date 11.011.2005
  * @non-public
  */
  procedure update_gal_spending_consol(
    aprojectid                  gal_spending_consolidated.gal_project_id%type
  , asnapshotid                 gal_spending_consolidated.gal_snapshot_id%type
  , abudgetid                   gal_spending_consolidated.gal_budget_id%type
  , vcostcenterid               gal_spending_consolidated.gal_cost_center_id%type
  , abudgetquantity             gal_spending_consolidated.gsp_budget_quantity%type
  , abudgetamout                gal_spending_consolidated.gsp_budget_amount%type
  , acol1quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol1amout                  gal_spending_consolidated.gsp_col1_amount%type
  , acol2quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol2amout                  gal_spending_consolidated.gsp_col1_amount%type
  , acol3quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol3amout                  gal_spending_consolidated.gsp_col1_amount%type
  , acol4quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol4amout                  gal_spending_consolidated.gsp_col1_amount%type
  , acol5quantity               gal_spending_consolidated.gsp_col1_quantity%type
  , acol5amout                  gal_spending_consolidated.gsp_col1_amount%type
  , atotalquantity              gal_spending_consolidated.gsp_total_quantity%type
  , atotalamount                gal_spending_consolidated.gsp_total_amount%type
  , aremainingquantity          gal_spending_consolidated.gsp_remaining_quantity%type
  , aremainingamount            gal_spending_consolidated.gsp_remaining_amount%type
  , amarginquantity             gal_spending_consolidated.gsp_margin_quantity%type
  , amarginamount               gal_spending_consolidated.gsp_margin_amount%type
  , aestimationtotalquantity    gal_spending_consolidated.gsp_estimation_total_quantity%type
  , aestimationtotalamount      gal_spending_consolidated.gsp_estimation_total_amount%type
  , a_gal_budget_period_id      gal_spending_consolidated.gal_budget_period_id%type
  , agsp_remaining_amount_delta gal_spending_consolidated.gsp_remaining_amount_delta%type
  )
  is
    vpercmarginquantity gal_spending_consolidated.gsp_perc_margin_quantity%type;
    vpercmarginamount   gal_spending_consolidated.gsp_perc_margin_amount%type;
  begin
    update gal_spending_consolidated
       set gsp_budget_quantity = gsp_budget_quantity + abudgetquantity
         , gsp_budget_amount = gsp_budget_amount + abudgetamout
         , gsp_col1_quantity = gsp_col1_quantity + acol1quantity
         , gsp_col1_amount = gsp_col1_amount + acol1amout
         , gsp_col2_quantity = gsp_col2_quantity + acol2quantity
         , gsp_col2_amount = gsp_col2_amount + acol2amout
         , gsp_col3_quantity = gsp_col3_quantity + acol3quantity
         , gsp_col3_amount = gsp_col3_amount + acol3amout
         , gsp_col4_quantity = gsp_col4_quantity + acol4quantity
         , gsp_col4_amount = gsp_col4_amount + acol4amout
         , gsp_col5_quantity = gsp_col5_quantity + acol5quantity
         , gsp_col5_amount = gsp_col5_amount + acol5amout
         , gsp_total_quantity = gsp_total_quantity + atotalquantity
         , gsp_total_amount = gsp_total_amount + atotalamount
         , gsp_remaining_quantity = gsp_remaining_quantity + aremainingquantity
         , gsp_remaining_amount = gsp_remaining_amount + aremainingamount
         , gsp_margin_quantity = gsp_margin_quantity + amarginquantity
         , gsp_margin_amount = gsp_margin_amount + amarginamount
         , gsp_estimation_total_quantity = gsp_estimation_total_quantity + aestimationtotalquantity
         , gsp_estimation_total_amount = gsp_estimation_total_amount + aestimationtotalamount
         , gsp_perc_margin_quantity =
             decode( (nvl(gsp_budget_quantity, 0) + nvl(abudgetquantity, 0) )
                  , 0, null
                  , ( (nvl(gsp_margin_quantity, 0) + nvl(amarginquantity, 0) ) * 100) /(nvl(gsp_budget_quantity, 0) + nvl(abudgetquantity, 0) )
                   )
         , gsp_perc_margin_amount =
             decode( (nvl(gsp_budget_amount, 0) + nvl(abudgetamout, 0) )
                  , 0, null
                  , ( (nvl(gsp_margin_amount, 0) + nvl(amarginamount, 0) ) * 100) /(nvl(gsp_budget_amount, 0) + nvl(abudgetamout, 0) )
                   )
     where gal_project_id = aprojectid
       and gal_budget_id = abudgetid
       and gal_cost_center_id = vcostcenterid
       and gal_snapshot_id = asnapshotid
       and gal_budget_period_id = a_gal_budget_period_id;

    if sql%notfound then
      if nvl(abudgetquantity, 0) <> 0 then
        vpercmarginquantity  := nvl(amarginquantity, 0) * 100 / abudgetquantity;
      end if;

      if nvl(abudgetamout, 0) <> 0 then
        vpercmarginamount  := nvl(amarginamount, 0) * 100 / abudgetamout;
      end if;

      create_gal_spending_consol(aprojectid
                               , asnapshotid
                               , abudgetid
                               , vcostcenterid
                               , abudgetquantity
                               , abudgetamout
                               , acol1quantity
                               , acol1amout
                               , acol2quantity
                               , acol2amout
                               , acol3quantity
                               , acol3amout
                               , acol4quantity
                               , acol4amout
                               , acol5quantity
                               , acol5amout
                               , atotalquantity
                               , atotalamount
                               , aremainingquantity
                               , aremainingamount
                               , amarginquantity
                               , amarginamount
                               , vpercmarginquantity
                               , vpercmarginamount
                               , aestimationtotalquantity
                               , aestimationtotalamount
                               , a_gal_budget_period_id
                               , agsp_remaining_amount_delta
                                );
    end if;
  end update_gal_spending_consol;

  /**
  * procedure purgeWorkTables
  * Description
  *    delete obsolete querying datas
  * @created fp 25.04.2007
  * @lastUpdate
  * @public
  * @param aSnapshotId : id of snapshot to purge
  ML 19/07 passer GAL_PROJECT_ID pour supp que les données de cette affaire (cas de pilotage multi affaire)
  */
  procedure purgeworktables(v_in_is_from_sel boolean)
  is
    v_is_ok_to_delete boolean := false;
    v_number          integer := 0;
  begin
    if v_in_is_from_sel then
      v_is_ok_to_delete  := true;
    elsif instr(pcs.PC_I_LIB_SESSION.getobjectname(), 'SNAPSHOT_COMPARE') > 0 then
      if v_number_snapshot > 2 then
        v_is_ok_to_delete  := true;
        v_number_snapshot  := 1;
      end if;
    else
      v_is_ok_to_delete  := true;
    end if;

    if v_is_ok_to_delete then
      delete      gal_spending_detail;

      delete      gal_spending_consolidated;
    end if;
  end purgeworktables;

  procedure create_budget_line(v_gal_budget_id gal_budget.gal_budget_id%type, v_gal_cost_center_id gal_cost_center.gal_cost_center_id%type, v_date date)
  is
    v_start_date_inter   date;
    v_end_date_inter     date;
    v_gbd_start_date     date;
    v_gbd_end_date       date;
    v_active_period      gal_budget_line.gal_budget_period_id%type;
    v_next_active_period gal_budget_line.gal_budget_period_id%type;
    v_gal_budget_line_id gal_budget_line.gal_budget_line_id%type;
    v_bli_clotured       number(1);
    anewbudgetlineid     gal_budget_line.gal_budget_line_id%type;
    v_gcc_code           gal_cost_center.gcc_code%type;
    lnProjectID          GAL_PROJECT.GAL_PROJECT_ID%type;
  begin
    -- Rechercher l'id de l'affaire, utilisé pour la rechercher des taux horaires
    select max(GAL_PROJECT_ID)
      into lnProjectID
      from GAL_BUDGET
     where GAL_BUDGET_ID = v_gal_budget_id;

    begin
      select   min(gbp.gbp_start_date)
          into v_gbd_start_date
          from gal_budget_line bdl
             , gal_budget_period gbp
         where gal_budget_id = v_gal_budget_id
           and bdl.gal_cost_center_id = v_gal_cost_center_id
           and gbp.gal_budget_period_id = bdl.gal_budget_period_id
      group by (bdl.gal_cost_center_id);
    exception
      when no_data_found then
        select init_id_seq.nextval
          into anewbudgetlineid
          from dual;

        select gcc_code
          into v_gcc_code
          from gal_cost_center
         where gal_cost_center_id = v_gal_cost_center_id;

        insert into gal_budget_line
                    (gal_budget_line_id
                   , gal_budget_id
                   , gal_cost_center_id
                   , gal_budget_period_id
                   , bli_sequence
                   , bli_wording
                   , bli_budget_price
                   , bli_clotured
                   , a_datecre
                   , a_idcre
                    )
          select anewbudgetlineid
               , v_gal_budget_id
               , v_gal_cost_center_id
               , gal_bdg_period_functions.getperiod(sysdate)
               , 10
               , v_gcc_code
               , gal_project_spending.get_hourly_rate_from_nat_ana(v_gal_cost_center_id, sysdate, '00', lnProjectID)
               , 0 as bli_clotured
               , sysdate as a_datecre
               , pcs.PC_I_LIB_SESSION.getuserini as a_idcre
            from dual;

        select gbp_start_date
          into v_gbd_start_date
          from gal_budget_line bdl
             , gal_budget_period gbp
         where gal_budget_id = v_gal_budget_id
           and gbp.gal_budget_period_id = bdl.gal_budget_period_id
           and gal_budget_line_id = anewbudgetlineid;
    end;

    select bdl.gal_budget_line_id
         , bli_clotured
      into v_gal_budget_line_id
         , v_bli_clotured
      from gal_budget_line bdl
         , gal_budget_period gbp
     where gal_budget_id = v_gal_budget_id
       and bdl.gal_cost_center_id = v_gal_cost_center_id
       and gbp.gal_budget_period_id = bdl.gal_budget_period_id
       and gbp.gbp_start_date = v_gbd_start_date;

    v_start_date_inter    := v_date;
    v_active_period       := v_gal_budget_line_id;
    v_next_active_period  := null;

    if v_bli_clotured = 0 then
      while trunc(v_start_date_inter, 'YYYY') < trunc(v_gbd_start_date, 'YYYY') loop
        gal_bdg_period_functions.duplicatebudgetline(v_active_period, gal_bdg_period_functions.getperiod(v_start_date_inter), v_next_active_period);

        update gal_budget_line
           set bli_budget_amount = 0
             , bli_last_estimation_amount = 0
         where gal_budget_line_id = v_next_active_period;

        select add_months(v_start_date_inter, 12)
          into v_start_date_inter
          from dual;

        v_next_active_period  := null;
      end loop;
    end if;

    select   max(gbp.gbp_end_date)
        into v_gbd_end_date
        from gal_budget_line bdl
           , gal_budget_period gbp
       where gal_budget_id = v_gal_budget_id
         and bdl.gal_cost_center_id = v_gal_cost_center_id
         and gbp.gal_budget_period_id = bdl.gal_budget_period_id
    group by (bdl.gal_cost_center_id);

    select bdl.gal_budget_line_id
      into v_gal_budget_line_id
      from gal_budget_line bdl
         , gal_budget_period gbp
     where gal_budget_id = v_gal_budget_id
       and bdl.gal_cost_center_id = v_gal_cost_center_id
       and gbp.gal_budget_period_id = bdl.gal_budget_period_id
       and gbp.gbp_end_date = v_gbd_end_date;

    v_end_date_inter      := v_gbd_end_date;

    select add_months(v_end_date_inter, 12)
      into v_end_date_inter
      from dual;

    v_active_period       := v_gal_budget_line_id;
    v_next_active_period  := null;

    while trunc(v_end_date_inter, 'YYYY') <= trunc(v_date, 'YYYY') loop
      gal_bdg_period_functions.duplicatebudgetline(v_active_period, gal_bdg_period_functions.getperiod(v_end_date_inter), v_next_active_period);

      update gal_budget_line
         set bli_budget_amount = 0
           , bli_last_estimation_amount = 0
       where gal_budget_line_id = v_next_active_period;

      select add_months(v_end_date_inter, 12)
        into v_end_date_inter
        from dual;

      v_next_active_period  := null;
    end loop;
  end;

   /**
  * procedure Report_Engaged
  * Description
  *   Repousse l'engage des périodes clotûrées sur la première période opuverte
  */
  procedure update_periode(vprojectid gal_project.gal_project_id%type)
  is
    v_flag                      boolean;
    v_instr3                    number(2);
    v_instr4                    number(2);
    v_instr5                    number(2);
    vcfg                        varchar2(30);
    vnext_open_periodid         gal_budget_period.gal_budget_period_id%type   default null;
    v_date                      date;
    vprj_budget_period          number(1)                                     default 0;
    vprj_gal_budget_period_id   gal_budget_period.gal_budget_period_id%type;
    v_gal_budget_line_period_id gal_budget_line.gal_budget_line_id%type;
    v_number                    integer;
  begin
    select nvl(prj_budget_period, 0)
      into vprj_budget_period
      from gal_project
     where gal_project_id = vprojectid;

    if vprj_budget_period = 1 then
      begin
        gal_bdg_period_functions.updateprojectperiod(vprojectid);

        begin
          select nvl(gal_budget_period_id, 0)
            into vprj_gal_budget_period_id
            from gal_project
           where gal_project_id = vprojectid;
        exception
          when no_data_found then
            vprj_gal_budget_period_id  := null;
        end;

        begin
          select gbp_start_date
            into v_date
            from gal_budget_period
           where gal_budget_period_id = vprj_gal_budget_period_id;
        exception
          when no_data_found then
            v_date  := null;
        end;

        vnext_open_periodid  := gal_bdg_period_functions.getfirstopenperiod(vprojectid);
        vcfg                 := pcs.pc_config.getconfig('GAL_SPEND_COMMITED_COLUMNS');

        if vcfg is null then
          vcfg  := '1';
        end if;

        select instr(vcfg, '3')
          into v_instr3
          from dual;

        if v_instr3 > 0 then
          v_instr3  := 1;
        end if;

        select instr(vcfg, '4')
          into v_instr4
          from dual;

        if v_instr4 > 0 then
          v_instr4  := 1;
        end if;

        select instr(vcfg, '5')
          into v_instr5
          from dual;

        if v_instr5 > 0 then
          v_instr5  := 1;
        end if;

        for c_gal_spending_detail in (select gsd_col1_amount
                                           , gsd_col2_amount
                                           , gsd_col3_amount
                                           , gsd_col4_amount
                                           , gsd_col5_amount
                                           , gal_cost_center_id
                                           , gal_budget_period_id
                                           , gsd_date
                                           , gal_spending_detail_id
                                           , gal_budget_id
                                        from gal_spending_detail
                                       where gal_project_id = vprojectid) loop
          v_flag  := false;

          if c_gal_spending_detail.gsd_col1_amount is not null then
            v_flag  := true;
          elsif     v_instr3 = 1
                and c_gal_spending_detail.gsd_col3_amount is not null then
            v_flag  := true;
          elsif     v_instr4 = 1
                and c_gal_spending_detail.gsd_col4_amount is not null then
            v_flag  := true;
          elsif     v_instr5 = 1
                and c_gal_spending_detail.gsd_col5_amount is not null then
            v_flag  := true;
          end if;

          if v_flag then
            if c_gal_spending_detail.gsd_date >= v_date then
              c_gal_spending_detail.gal_budget_period_id  := nvl(gal_bdg_period_functions.getperiod(c_gal_spending_detail.gsd_date), 0);
            else
              c_gal_spending_detail.gal_budget_period_id  := vnext_open_periodid;
            end if;
          else
            c_gal_spending_detail.gal_budget_period_id  := nvl(gal_bdg_period_functions.getperiod(c_gal_spending_detail.gsd_date), 0);
          end if;

          update gal_spending_detail
             set gal_budget_period_id = c_gal_spending_detail.gal_budget_period_id
           where gal_spending_detail_id = c_gal_spending_detail.gal_spending_detail_id;

          if     c_gal_spending_detail.gal_cost_center_id is not null
             and c_gal_spending_detail.gal_budget_id is not null then
            begin
              select gal_budget_period_id
                into v_gal_budget_line_period_id
                from gal_budget_line
               where gal_budget_id = c_gal_spending_detail.gal_budget_id
                 and gal_budget_period_id = c_gal_spending_detail.gal_budget_period_id
                 and gal_cost_center_id = c_gal_spending_detail.gal_cost_center_id;
            exception
              when no_data_found then
                -- ici on regarde si on a encore des lignes de budgets non cloturées -> si oui on décide que on crée les lignes uisvantes. Sinon on décide que le travail sur ce budget est terminée (ie à la cloture,
                -- on a décididée de ne pas recréer de lignes pour la lsuite. On place la dépense à la bonne place dans la période, mais on ne créer pas la ligne de budget
                select count(bli_clotured)
                  into v_number
                  from gal_budget_line
                 where gal_budget_id = c_gal_spending_detail.gal_budget_id
                   and gal_cost_center_id = c_gal_spending_detail.gal_cost_center_id
                   and bli_clotured = 0;

                if v_number > 0 then
                  create_budget_line(c_gal_spending_detail.gal_budget_id, c_gal_spending_detail.gal_cost_center_id, c_gal_spending_detail.gsd_date);
                end if;
            end;
          end if;
        end loop;
      exception
        when no_data_found then
          null;
      end;
    else
      update gal_spending_detail
         set gal_budget_period_id = 0
       where gal_project_id = vprojectid;
    end if;
  end;

  /**
    * Description : Procédure met à jour les montants en fonction du type de suivi financier
    *Ne s'applaique qu'aux documents car seuls ces derniers peuvent être dans une devise autre que la monnaie de société et la monnaie de contrat
    * @author H. Monnier
    * @version Date 11.06.2012
    * @param v_LocalCurrency  monniae de société
    * @param v_ProjectCurrency  monjaie du projet
    * @param v_ProjectId             id de projet
    * @param v_ac_gal_spending_type    type de suivi financier 1: taux fixe monnaie de société, 2 taux fixe monnaie de contrat, 3 taux réel monnaie de société, 4 taux réél  monnaie de contrat
    * @non-public
    */
  procedure change_amount_for_document(
    v_LocalCurrency            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , v_ProjectCurrency          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , v_ProjectId                GAL_PROJECT.gal_project_id%type
  , v_ac_gal_spending_type     integer
  , i_valuationrate_for_SF4 in GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type
  )
  is
    a_ExchangeRate        GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    a_BasePrice           GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
    a_ProjectExchangeRate GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    a_ProjectBasePrice    GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
  begin
    if v_ac_gal_spending_type = 1   -- taux de base / Monnaie de société
                                 then
      for v_cur in (select distinct (acs_financial_currency_id)   -- on e reclacule que les positions qui sont dans une  onnaie autre que celle de la société
                               from gal_conso_doc_position_temp
                              where acs_financial_currency_id <> v_LocalCurrency) loop
        GAL_LIB_PROJECT.GetProjectCurrencyRate(v_ProjectID, v_cur.acs_financial_currency_id, a_ExchangeRate, a_BasePrice);

        if    nvl(a_ExchangeRate, 0) = 0
           or nvl(a_BasePrice, 0) = 0 then
          raise_application_error(-20000, pcs.pc_functions.translateword('PCS - Une monnaie de base n est pas définie!') );
        end if;

        update gal_conso_doc_position_temp
           set pos_net_value_excl_b =
                 (pos_net_value_excl * a_ExchangeRate / a_BasePrice) *
                 sign(pos_net_value_excl_b)   -- on prend le signe pour traiter le désengagment des factures d'échéanciers
         where acs_financial_currency_id = v_cur.acs_financial_currency_id;
      end loop;
    elsif v_ac_gal_spending_type = 2   -- taux de base monnaie de contrat
                                    then
      if v_ProjectCurrency = v_LocalCurrency   -- on traite déjà les positions qui sont dans la monnaie de al société
                                            then
        a_ProjectExchangeRate  := 1;
        a_ProjectBasePrice     := 1;
      else
        GAL_LIB_PROJECT.GetProjectCurrencyRate(v_ProjectID, v_ProjectCurrency, a_ProjectExchangeRate, a_ProjectBasePrice);

        if    nvl(a_ProjectExchangeRate, 0) = 0
           or nvl(a_ProjectBasePrice, 0) = 0 then
          raise_application_error(-20000, pcs.pc_functions.translateword('PCS - Une monnaie de base n est pas définie!') );
        end if;
      end if;

      for v_cur in (select distinct (acs_financial_currency_id) acs_financial_currency_id
                               from gal_conso_doc_position_temp
                              where acs_financial_currency_id = v_LocalCurrency) loop
        update gal_conso_doc_position_temp
           set pos_net_value_excl_b =(pos_net_value_excl_b * a_ProjectBasePrice / a_ProjectExchangeRate)
         where acs_financial_currency_id = v_LocalCurrency;
      end loop;

      for v_cur   -- on traite les positions qui sont dans une monnaie autre que celle du contrat et autre que celle de la société
               in (select distinct (acs_financial_currency_id)   -- double calcul en repasant dans la monnei de la société
                              from gal_conso_doc_position_temp
                             where acs_financial_currency_id <> v_LocalCurrency
                               and acs_financial_currency_id <> v_ProjectCurrency) loop
        GAL_LIB_PROJECT.GetProjectCurrencyRate(v_ProjectID, v_cur.acs_financial_currency_id, a_ExchangeRate, a_BasePrice);

        if    nvl(a_ExchangeRate, 0) = 0
           or nvl(a_BasePrice, 0) = 0 then
          raise_application_error(-20000, pcs.pc_functions.translateword('PCS - Une monnaie de base n est pas définie!') );
        end if;

        --DBMS_OUTPUT.PUT_LINE('exch : ' || a_ExchangeRate || ' - ' || a_BasePrice);
        update gal_conso_doc_position_temp
           set pos_net_value_excl_b =
                                 ( (pos_net_value_excl * a_ExchangeRate * a_ProjectBasePrice) /(a_BasePrice * a_ProjectExchangeRate) )
                                 * sign(pos_net_value_excl_b)
         where acs_financial_currency_id = v_cur.acs_financial_currency_id;
      end loop;

      update gal_conso_doc_position_temp   -- on traite les positions ui sont dans la monnaie du contrat -> on met juste la valeur dans la bonne colonne
         set pos_net_value_excl_b = (pos_net_value_excl) * sign(pos_net_value_excl_b)
       where acs_financial_currency_id = v_ProjectCurrency;
    elsif v_ac_gal_spending_type = 4 then   -- taux rééls monaie de contrat
      if nvl(i_valuationrate_for_SF4, 0) = 0 then   -- forcer un taux de monnaie de contrat
        update gal_conso_doc_position_temp   -- ontraite toutes les positions qui sont dans une monnaie différente de celle du contrat
           set pos_net_value_excl_b =   -- le taux s'applique depuis la datre de document -> standard du soft
                                         ACS_FUNCTION.ConvertAmountForView(pos_net_value_excl_b, v_LocalCurrency, v_ProjectCurrency, dmt_Date_Document, 0, 0, 0)
         where acs_financial_currency_id <> v_ProjectCurrency;

        update gal_conso_doc_position_temp   -- on traite les positions ui sont dans la monnaie du contrat -> on met juste la valeur dans la bonne colonne
           set pos_net_value_excl_b =(pos_net_value_excl)
         where acs_financial_currency_id = v_ProjectCurrency;
      else
        update gal_conso_doc_position_temp   -- ontraite toutes les positions qui sont dans une monnaie différente de celle du contrat
           set pos_net_value_excl_b =   -- et on force le taux de la monnaie du contrat
                                     pos_net_value_excl_b * i_valuationrate_for_SF4;
      --WHERE acs_financial_currency_id <> v_ProjectCurrency; demande de apco, traiter tous les doc de la même façon hmo 7.2015
      end if;
    --UPDATE gal_conso_doc_position_temp -- on traite les positions ui sont dans la monnaie du contrat -> on met juste la valeur dans la bonne colonne
    --   SET pos_net_value_excl_b = (pos_net_value_excl)
    -- WHERE acs_financial_currency_id = v_ProjectCurrency; demande de apco, traiter tous les doc de la même façon hmo 7.2015
    end if;
  end;

  /**
    * Description : Procédure met à jour les montants de budgets et de reste à engagger en fonction du type de suivi financier
    *Ne s'applaique qu'aux budgets car sont dans une autre table
    * @author H. Monnier
    * @version Date 11.06.2012
    * @param v_LocalCurrency  monniae de société
    * @param v_ProjectCurrency  monjaie du projet
    * @param v_ProjectId             id de projet
    * @param v_ac_gal_spending_type    type de suivi financier 1: taux fixe monnaie de société, 2 taux fixe monnaie de contrat, 3 taux réel monnaie de société, 4 taux réél  monnaie de contrat
    * @non-public
    */
  procedure change_amount_for_budget(
    v_LocalCurrency            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , v_ProjectCurrency          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , v_ProjectId                GAL_PROJECT.gal_project_id%type
  , v_ac_gal_spending_type     integer
  , i_valuationrate_for_SF4 in GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type
  , asnapshotdate              date
  )
  is
    a_ProjectExchangeRate GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    a_ProjectBasePrice    GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
  begin
    -- DEVERP-21709 , on doit mettre à jour le remaining d'entrée cvar on se base là-dessus pour l'algorithme de clacul
    -- on gère ici le cas de l'écrasement du reste par une rebudgétisation, si oui, le reste redevient le budget !!mais pas dans les tables!!

    -- on stocke 'engagement
    update gal_conso_budget_line_temp
       set bli_hanging_spending_amount =
             case
               when v_ProjectCurrency = v_LocalCurrency
               and (   v_ac_gal_spending_type = 1
                    or v_ac_gal_spending_type = 2) then bli_hanging_spending_amount_B
               else bli_hanging_spending_amount
             end;

    update gal_conso_budget_line_temp
       set bli_remaining_amount =
             case
               when bli_last_remaining_date is null then bli_budget_amount
               when bli_last_remaining_date < bli_last_budget_date then bli_budget_amount
               else bli_remaining_amount
             end
         , bli_remaining_quantity =
             case
               when bli_last_remaining_date is null then bli_budget_quantity
               when bli_last_remaining_date < bli_last_budget_date then bli_budget_quantity
               else bli_remaining_quantity
             end
         , bli_remaining_amount_at_date =
             case
               when bli_last_remaining_date is null then bli_budget_amount
               when bli_last_remaining_date < bli_last_budget_date then bli_budget_amount
               else bli_remaining_amount
             end
         , bli_hanging_spending_amount = case
                                          when bli_last_remaining_date < bli_last_budget_date then 0
                                          else bli_hanging_spending_amount
                                        end
         , bli_hanging_spending_amount_B = case
                                            when bli_last_remaining_date < bli_last_budget_date then 0
                                            else bli_hanging_spending_amount_B
                                          end
         , bli_hanging_spending_quantity = case
                                            when bli_last_remaining_date < bli_last_budget_date then 0
                                            else bli_hanging_spending_quantity
                                          end;

    update gal_conso_budget_line_temp
       set bli_last_remaining_date =
                   case
                     when bli_last_remaining_date is null
                      or bli_last_remaining_date < bli_last_budget_date then bli_last_budget_date
                     else bli_last_remaining_date
                   end;

    --   IF a_budgetcurrency = 0 -- gestion des budgets en monnaie de contrat à non (normalement pas de gestion en monnaie de contrat), les budgets en tables sont sauvés en monnaie de société
    if v_ProjectCurrency <> v_LocalCurrency then
      if v_ac_gal_spending_type = 1   --  taux fixes monnaie de contrat
                                   then
        GAL_LIB_PROJECT.GetProjectCurrencyRate(v_ProjectID, v_ProjectCurrency, a_ProjectExchangeRate, a_ProjectBasePrice);

        update gal_conso_budget_line_temp
           set bli_budget_amount =(bli_budget_amount * a_ProjectExchangeRate / a_ProjectBasePrice)
             , bli_remaining_amount =(bli_remaining_amount * a_ProjectExchangeRate / a_ProjectBasePrice)
             , bli_hanging_spending_amount =(bli_hanging_spending_amount * a_ProjectExchangeRate / a_ProjectBasePrice)
             , bli_last_estimation_amount =(bli_last_estimation_amount * a_ProjectExchangeRate / a_ProjectBasePrice)
             , bli_remaining_amount_at_date =(bli_remaining_amount_at_date * a_ProjectExchangeRate / a_ProjectBasePrice);
      elsif v_ac_gal_spending_type = 3   -- taux réél , monnaie de société
                                      then   -- on prend le taux de la date de la dernière budgétisation et de la date de la dernière estimation du reste à engager
        if i_valuationrate_for_SF4 = 0   -- on force le taux de la monnaie de contrat ??
                                      then
          update gal_conso_budget_line_temp
             set bli_budget_amount = ACS_FUNCTION.ConvertAmountForView(bli_budget_amount, v_ProjectCurrency, v_LocalCurrency, bli_last_budget_date, 0, 0, 0)
               , bli_remaining_amount =
                   case
                     when asnapshotdate is null then ACS_FUNCTION.ConvertAmountForView(bli_remaining_amount
                                                                                     , v_ProjectCurrency
                                                                                     , v_LocalCurrency
                                                                                     , sysdate()
                                                                                     , 0
                                                                                     , 0
                                                                                     , 0
                                                                                      )
                     else ACS_FUNCTION.ConvertAmountForView(bli_remaining_amount, v_ProjectCurrency, v_LocalCurrency, asnapshotdate, 0, 0, 0)
                   end
               , bli_hanging_spending_amount =
                   case
                     when v_ProjectCurrency = v_LocalCurrency then ACS_FUNCTION.ConvertAmountForView(bli_hanging_spending_amount
                                                                                                   , v_ProjectCurrency
                                                                                                   , v_LocalCurrency
                                                                                                   , bli_last_remaining_date
                                                                                                   , 0
                                                                                                   , 0
                                                                                                   , 0
                                                                                                    )
                     else bli_hanging_spending_amount_B
                   end
               , bli_remaining_amount_at_date =
                           ACS_FUNCTION.ConvertAmountForView(bli_remaining_amount_at_date, v_ProjectCurrency, v_LocalCurrency, bli_last_remaining_date, 0, 0, 0);
        else
          update gal_conso_budget_line_temp   -- on multiplie par le taux forcé de la monnaie du contrat
             set bli_budget_amount = (1 / i_valuationrate_for_SF4) * bli_budget_amount
               , bli_remaining_amount = bli_remaining_amount *(1 / i_valuationrate_for_SF4)
               , bli_hanging_spending_amount = bli_hanging_spending_amount *(1 / i_valuationrate_for_SF4)
               , bli_last_estimation_amount = bli_last_estimation_amount *(1 / i_valuationrate_for_SF4)
               , bli_remaining_amount_at_date = bli_remaining_amount_at_date *(1 / i_valuationrate_for_SF4);
        end if;
      end if;
    end if;
  end;

  /**
    * Description : Procédure met à jour les montants en fonction du type de suivi financier
    *S'applique à toutes les dépenses autres que documents et budget
    * @author H. Monnier
    * @version Date 11.06.2012
    * @param v_LocalCurrency  monniae de société
    * @param v_ProjectCurrency  monjaie du projet
    * @param v_ProjectId             id de projet
    * @param v_ac_gal_spending_type    type de suivi financier 1: taux fixe monnaie de société, 2 taux fixe monnaie de contrat, 3 taux réel monnaie de société, 4 taux réél  monnaie de contrat
    * @non-public
    */
  procedure change_amount_not_for_document(
    v_LocalCurrency            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , v_ProjectCurrency          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , v_ProjectId                GAL_PROJECT.gal_project_id%type
  , v_ac_gal_spending_type     integer
  , i_valuationrate_for_SF4 in GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type
  , asnapshotdate              date
  )
  is
    a_ProjectExchangeRate GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    a_ProjectBasePrice    GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
  begin
    if v_ac_gal_spending_type = 2   -- taux fixe, monnaie de contrat
                                 then
      if v_ProjectCurrency = v_LocalCurrency then
        a_ProjectExchangeRate  := 1;
        a_ProjectBasePrice     := 1;
      else
        GAL_LIB_PROJECT.GetProjectCurrencyRate(v_ProjectID,   -- un seul taux car les montants à trabsformer sont tous en monnaie de socitété
                                               v_ProjectCurrency, a_ProjectExchangeRate, a_ProjectBasePrice);

        if    nvl(a_ProjectExchangeRate, 0) = 0
           or nvl(a_ProjectBasePrice, 0) = 0 then
          raise_application_error(-20000, pcs.pc_functions.translateword('PCS - Une monnaie de base n est pas définie!') );
        end if;
      end if;

      update gal_spending_detail
         set gsd_col1_amount =(gsd_col1_amount * a_ProjectBasePrice / a_ProjectExchangeRate)
           , gsd_col2_amount =(gsd_col2_amount * a_ProjectBasePrice / a_ProjectExchangeRate)
           , gsd_col3_amount =(gsd_col3_amount * a_ProjectBasePrice / a_ProjectExchangeRate)
           , gsd_col4_amount =(gsd_col4_amount * a_ProjectBasePrice / a_ProjectExchangeRate)
           , gsd_col5_amount =(gsd_col5_amount * a_ProjectBasePrice / a_ProjectExchangeRate)
       where gsd_from_document = 0;
    elsif v_ac_gal_spending_type = 4   --- taux réel monnaie de contrat
                                    then
      if i_valuationrate_for_SF4 = 0   -- on force le taux de la monnaie du contrat ??
                                    then
        update gal_spending_detail
           set gsd_date = asnapshotdate
         where gsd_date > asnapshotdate;

        update gal_spending_detail   -- on change au taux de l'imputation, pour détail voir analyse
           set gsd_col1_amount = ACS_FUNCTION.ConvertAmountForView(gsd_col1_amount, v_LocalCurrency, v_ProjectCurrency, gsd_date, 0, 0, 0)
             , gsd_col2_amount = ACS_FUNCTION.ConvertAmountForView(gsd_col2_amount, v_LocalCurrency, v_ProjectCurrency, gsd_date, 0, 0, 0)
             , gsd_col3_amount = ACS_FUNCTION.ConvertAmountForView(gsd_col3_amount, v_LocalCurrency, v_ProjectCurrency, gsd_date, 0, 0, 0)
             , gsd_col4_amount = ACS_FUNCTION.ConvertAmountForView(gsd_col4_amount, v_LocalCurrency, v_ProjectCurrency, gsd_date, 0, 0, 0)
             , gsd_col5_amount = ACS_FUNCTION.ConvertAmountForView(gsd_col5_amount, v_LocalCurrency, v_ProjectCurrency, gsd_date, 0, 0, 0)
         where gsd_from_document = 0;
      else
        update gal_spending_detail   -- on force le taux de la monnaie du contrat
           set gsd_col1_amount = i_valuationrate_for_SF4 * gsd_col1_amount
             , gsd_col2_amount = i_valuationrate_for_SF4 * gsd_col2_amount
             , gsd_col3_amount = i_valuationrate_for_SF4 * gsd_col3_amount
             , gsd_col4_amount = i_valuationrate_for_SF4 * gsd_col4_amount
             , gsd_col5_amount = i_valuationrate_for_SF4 * gsd_col5_amount
         where gsd_from_document = 0;
      end if;
    end if;
  end;

  procedure inittablegalBudget_DocRecord
  is
  begin
    delete from GAL_CONSO_GAL_BUDGET;

    insert into GAL_CONSO_GAL_BUDGET
      select distinct (bdg.doc_record_id)
                    , bdg.gal_budget_id
                 from gal_budget bdg
                    , gal_conso_doc_record_temp rco_temp
                where bdg.doc_record_id = rco_temp.doc_record_id
      union
      select distinct (tas.doc_record_id)
                    , tas.gal_budget_id
                 from gal_conso_doc_record_temp rco_temp
                    , gal_task tas
                where tas.doc_record_id = rco_temp.doc_record_id
      union
      select distinct (tal.doc_record_id)
                    , tas.gal_budget_id
                 from gal_conso_doc_record_temp rco_temp
                    , gal_task_link tal
                    , gal_task tas
                where tal.doc_record_id = rco_temp.doc_record_id
                  and tal.gal_task_id = tas.gal_task_id;
  end inittablegalBudget_DocRecord;

  /**
    * Description : Procédure qui crée les dépenses détaillées. Les dépenses sont recherchées à partir des requêtes se trouvant dans la table GAL__DEF_SPENDIN
    *
    * @author Matthieu Lesur
    * @version Date 11.11.2005
    * @param aGalProjectId         : ID d'affaire
    * @param aDocRecordIdList      : string contenant tous les doc_record_id pour l'affaire / Code bdget concenée
    * @param aSnapshotDate         : date pour interro à date (si vide-> données ON-LINE)
    * @non-public
    */
  procedure gal_spending_detail_create(
    agalprojectid       gal_project.gal_project_id%type
  , adocrecordidlist    ID_TABLE_TYPE
  , asnapshotdate       date
  , asnapshotid         gal_snapshot.gal_snapshot_id%type default 0
  , aconfigreqsel       number
  , asnap_type_date     number
  , adatemin            date
  , adatemax            date
  , v_AcGalSpendingType integer
  , v_TauxEco           integer default 0
  )
  is
    type typ_tab_number is table of number;

    type typ_tab_va10 is table of varchar2(10);

    type typ_tab_va30 is table of varchar2(30);

    type typ_tab_va50 is table of varchar2(50);

    type typ_tab_va60 is table of varchar2(60);

    type typ_tab_va4000 is table of varchar2(4000);

    type typ_tab_date is table of date;

    v_gal_budget_id               typ_tab_number;
    v_doc_record_id               typ_tab_number;
    v_acs_cda_account_id          typ_tab_number;
    v_acs_cpn_account_id          typ_tab_number;
    v_gal_cost_center_id          typ_tab_number;
    v_gsd_number                  typ_tab_va50;
    v_gsd_wording                 typ_tab_va4000;
    v_gsd_date                    typ_tab_date;
    v_gsd_quantity                typ_tab_number;
    v_gsd_amount                  typ_tab_number;
    v_gsd_origin_number           typ_tab_va50;
    v_gsd_origin_wording          typ_tab_va4000;
    v_gsd_group_id                typ_tab_number;
    v_gsd_group_number            typ_tab_va50;
    v_gsd_group_wording           typ_tab_va4000;
    v_gsd_group_date              typ_tab_date;
    v_gsd_object                  typ_tab_va60;
    v_gsd_id_1                    typ_tab_number;
    v_gsd_id_2                    typ_tab_number;
    v_gsd_id_3                    typ_tab_number;
    v_project_consolidation       typ_tab_va10;
    v_consolidation_negative      typ_tab_number;
    v_gsd_object_commands         typ_tab_va4000;
    d_gds_wording                 gal_def_spending.gds_wording%type;
    d_gds_sql                     varchar2(32762);
    d_pc_sqlst_id                 number;
    d_project_consolidation       gal_def_spending.c_project_consolidation%type;
    d_gds_using_gauge             gal_def_spending.gds_using_gauge%type;
    d_gds_with_qty_accumulation   gal_def_spending.gds_with_quantity_accumulation%type;
    d_consolidation_negative      gal_def_spending.gds_consolidation_negative%type;
    d_gds_sequence                gal_def_spending.gds_sequence%type;
    v_inter_cpt_snapshotdate      date;
    v_inter_evt_snapshotdate      date;
    v_gal_proc_conso_sel_request  varchar2(255);
    v_is_request_sel              integer;
    v_event_snapshotdate          date                                                    default null;
    v_compta_snapshotdate         date                                                    default null;
    v_gal_snapshoot_type_date     number;
    v_gal_proc_conso_del_detail   varchar2(255);
    v_gal_proc_conso_det_bef_prov varchar2(255);
    v_LocalCurrency               ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    v_ProjectCurrency             ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    a_gal_proc_valuationrate_SF4  varchar2(255);
    a_valuationrate_for_SF4       GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type             := 0;

    cursor crgaldefspending
    is
      select gds_sequence
           , gds_wording
           , gds_sql
           , pc_sqlst_id
           , c_project_consolidation
           , gds_using_gauge
           , gds_with_quantity_accumulation
           , gds_consolidation_negative
        from gal_def_spending
       where nvl(gds_in_service, 0) = 1
         and nvl(c_project_consolidation, 0) <> 0;
  begin
    select nvl(prj_exclude_provision, 0)
      into cprovactif
      from gal_project
     where gal_project_id = agalprojectid;

    if cprovactif = 1 then
      cprovactif  := 0;
    else
      select nvl(min(dic_prj_activate_provision), 0)
        into cprovactif
        from dic_gal_prj_category
           , gal_project
       where dic_gal_prj_category.dic_gal_prj_category_id = gal_project.dic_gal_prj_category_id
         and gal_project_id = agalprojectid;
    end if;

    begin
      select pcs.pc_config.getconfig('GAL_PROC_CONSO_EXCLUDE_ACPT')
        into v_gal_proc_conso_exclude_acpt
        from dual;
    exception
      when no_data_found then
        v_gal_proc_conso_exclude_acpt  := null;
    end;

    v_LocalCurrency          := ACS_FUNCTION.GetLocalCurrencyID;
    v_ProjectCurrency        := GAL_LIB_PROJECT.GetProjectCurrency(agalprojectid);

    if not(v_LocalCurrency = v_ProjectCurrency) then
      begin
        select pcs.pc_config.getconfig
                                ('GAL_PROC_VALUATIONRATE_SF4')   -- recherche de la procédure qui calcule le taux forcé pour remonter en monnaie de contrat dans SF4
          into a_gal_proc_valuationrate_SF4
          from dual;
      exception
        when no_data_found then
          a_gal_proc_valuationrate_SF4  := null;
      end;

      if a_gal_proc_valuationrate_SF4 is not null   -- on initialise le taux forcé de la monnaie de contrat pour SF4
                                                 then
        sqlstatement  := 'BEGIN ' || trim(a_gal_proc_valuationrate_SF4) || '(:agalprojectid,:a_valuationrate_for_SF4); END;';

        execute immediate sqlstatement
                    using in agalprojectid, in out a_valuationrate_for_SF4;
      end if;
    end if;

    a_valuationrate_for_SF4  := nvl(a_valuationrate_for_SF4, 0);

    if asnap_type_date = -1 then
      begin
        select nvl(pcs.pc_config.getconfig('GAL_SNAPSHOT_TYPE_DATE'), 0)
          into v_gal_snapshoot_type_date
          from dual;
      exception
        when no_data_found then
          v_gal_snapshoot_type_date  := 0;
      end;
    else
      v_gal_snapshoot_type_date  := asnap_type_date;
    end if;

    -- ne pas initialiser les deux dates si on est pas en shnapshoot -> test utiliser dans les procedure suivantes
    if asnapshotdate is not null then
      if v_gal_snapshoot_type_date = 0 then
        --hnmo  le format de date n'est pas toujours le m'ême entre adatecre et la date d'imputation dans certians cas on gère les minutes d'autres fois pas
        -- donc si on fait 22.3.2012 + 1 on est 23.3.2012 00:00:00 donc ok si on compare avec une date sauve avec hh,mm,ss masi pas ok avec ne date sans hh,mm,ss car dans ce cas, Oracle considère une date
        -- dd-mm-yyyy comme dd-mm-yyyy 00:00:00
        --select to_date(to_char(trunc(asnapshotdate, 'DD') + 1, 'DD-MON-YYYY HH24:MI:SS'), 'DD-MON-YYYY HH24:MI:SS')
        -- into v_event_snapshotdate
        --from dual;
        select trunc(asnapshotdate, 'DD') + 86399 / 86400
          into v_event_snapshotdate
          from dual;

        select trunc(asnapshotdate + 4000, 'DD')
          into v_compta_snapshotdate
          from dual;
      --   select to_date(to_char(trunc(asnapshotdate, 'DD') + 200000, 'DD-MON-YYYY HH24:MI:SS'), 'DD-MON-YYYY HH24:MI:SS')
      --    into v_compta_snapshotdate
      --    from dual;
      else
        select trunc(asnapshotdate + 4000, 'DD')
          into v_event_snapshotdate
          from dual;

        select trunc(asnapshotdate, 'DD') + 86399 / 86400
          into v_compta_snapshotdate
          from dual;
      --
      --        select to_date(to_char(trunc(sysdate, 'DD') + 200000, 'DD-MON-YYYY HH24:MI:SS'), 'DD-MON-YYYY HH24:MI:SS')
      --          into v_event_snapshotdate
      --          from dual;
      --
      --        select to_date(to_char(trunc(asnapshotdate, 'DD') + 1, 'DD-MON-YYYY HH24:MI:SS'), 'DD-MON-YYYY HH24:MI:SS')
      --          into v_compta_snapshotdate
      --          from dual;
      end if;
    end if;

    inittabledocrecord(adocrecordidlist);
    inittablegalBudget_DocRecord;
    inittabledocposition(v_event_snapshotdate, v_compta_snapshotdate);

    if v_AcGalSpendingType <> 3 then
      change_amount_for_document(v_LocalCurrency, v_ProjectCurrency, agalprojectid, v_AcGalSpendingType, a_valuationrate_for_SF4);
    end if;

    inittablegal_hours(agalprojectid, v_event_snapshotdate, v_compta_snapshotdate, v_TauxEco, adatemax);
    inittablegal_task_link(agalprojectid, v_event_snapshotdate, v_compta_snapshotdate);
    inittablegal_budget_line(agalprojectid, v_event_snapshotdate, v_compta_snapshotdate);
    change_amount_for_budget(v_LocalCurrency, v_ProjectCurrency, agalprojectid, v_AcGalSpendingType, a_valuationrate_for_SF4, asnapshotdate);

    begin
      select pcs.pc_config.getconfig('GAL_PROC_CONSO_DEL_DETAIL')
        into v_gal_proc_conso_del_detail
        from dual;
    exception
      when no_data_found then
        v_gal_proc_conso_del_detail  := null;
    end;

    begin
      select pcs.pc_config.getconfig('GAL_PROC_CONSO_DET_BEF_PROV')
        into v_gal_proc_conso_det_bef_prov
        from dual;
    exception
      when no_data_found then
        v_gal_proc_conso_det_bef_prov  := null;
    end;

    begin
      select pcs.pc_config.getconfig('GAL_PROC_CONSO_SEL_REQUEST')
        into v_gal_proc_conso_sel_request
        from dual;
    exception
      when no_data_found then
        v_gal_proc_conso_sel_request  := null;
    end;

    -- Lecture des requêtes de dépenses et chargement d'un curseur contenat toutes les requêtes de dépenses
    update gal_def_spending a
       set pc_sqlst_id =
                       (select pc_sqlst_id
                          from pcs.pc_sqlst b
                             , pcs.pc_table c
                         where b.pc_table_id = c.pc_table_id
                           and c.tabname = 'GAL_DEF_SPENDING'
                           and b.c_sqgtype = 'GDS_SQL'
                           and sqlid = to_char(a.gds_sequence) )
     where a.pc_sqlst_id is null
       and gds_sequence < 1000;

    open crgaldefspending;

    loop
      fetch crgaldefspending
       into d_gds_sequence
          , d_gds_wording
          , d_gds_sql
          , d_pc_sqlst_id
          , d_project_consolidation
          , d_gds_using_gauge
          , d_gds_with_qty_accumulation
          , d_consolidation_negative;

      exit when crgaldefspending%notfound;

      -- hmo 02.06.08
      if v_gal_proc_conso_sel_request is null then
        v_is_request_sel  := 1;
      else
        sqlstatement  := 'BEGIN ' || trim(v_gal_proc_conso_sel_request) || '(:aconfigreqsel,:d_gds_sequence,:v_is_request_sel); END;';

        execute immediate sqlstatement
                    using in aconfigreqsel, in d_gds_sequence, in out v_is_request_sel;
      end if;

      if     v_compta_snapshotdate is null
         and v_event_snapshotdate is null then
        v_inter_cpt_snapshotdate  := trunc(sysdate + 200000, 'DD');
        v_inter_evt_snapshotdate  := trunc(sysdate + 200000, 'DD');
      else
        v_inter_cpt_snapshotdate  := v_compta_snapshotdate;
        v_inter_evt_snapshotdate  := v_event_snapshotdate;
      end if;

      if d_pc_sqlst_id is not null then
        select sqlstmnt
          into d_gds_sql
          from pcs.pc_sqlst
         where pc_sqlst_id = d_pc_sqlst_id;
      end if;

      if     d_gds_sql is not null
         and v_is_request_sel = 1 then
        d_gds_sql  := replace(d_gds_sql, ':SNAPSHOT_DATE', 'to_date(''' || to_char(v_inter_cpt_snapshotdate, 'DD.MM.YYYY') || ''',''DD.MM.YYYY'')');
        d_gds_sql  := replace(d_gds_sql, ':EVT_SNAPSHOT_DATE', 'to_date(''' || to_char(v_inter_evt_snapshotdate, 'DD.MM.YYYY') || ''',''DD.MM.YYYY'')');

        begin
          -- Lecture des dépenses
          execute immediate d_gds_sql
          bulk collect into v_gal_budget_id
                          , v_doc_record_id
                          , v_acs_cda_account_id
                          , v_acs_cpn_account_id
                          , v_gal_cost_center_id
                          , v_gsd_number
                          , v_gsd_wording
                          , v_gsd_date
                          , v_gsd_quantity
                          , v_gsd_amount
                          , v_gsd_origin_number
                          , v_gsd_origin_wording
                          , v_gsd_group_id
                          , v_gsd_group_number
                          , v_gsd_group_wording
                          , v_gsd_group_date
                          , v_gsd_object
                          , v_gsd_id_1
                          , v_gsd_id_2
                          , v_gsd_id_3
                          , v_project_consolidation
                          , v_consolidation_negative
                          , v_gsd_object_commands;
        exception
          when others then
            raise_application_error(-20000
                                  , replace(pcs.pc_functions.translateword('PCS - Mauvaise commande SQL. Définition : [GDS_WORDING]')
                                          , '[GDS_WORDING]'
                                          , d_gds_wording
                                           ) ||
                                    chr(13) ||
                                    sqlerrm ||
                                    chr(13) ||
                                    DBMS_UTILITY.format_error_backtrace
                                   );
        end;

        if v_doc_record_id.first is not null then
          forall i in v_doc_record_id.first .. v_doc_record_id.last
            insert into gal_spending_detail
                        (gal_spending_detail_id
                       , gal_snapshot_id
                       , gal_project_id
                       , gal_budget_id
                       , doc_record_id
                       , acs_cda_account_id
                       , acs_cpn_account_id
                       , gal_cost_center_id
                       , gsd_number
                       , gsd_wording
                       , gsd_date
                       , gsd_col1_quantity
                       , gsd_col1_amount
                       , gsd_col2_quantity
                       , gsd_col2_amount
                       , gsd_col3_quantity
                       , gsd_col3_amount
                       , gsd_col4_quantity
                       , gsd_col4_amount
                       , gsd_col5_quantity
                       , gsd_col5_amount
                       , gsd_origin_number
                       , gsd_origin_wording
                       , gsd_group_id
                       , gsd_group_number
                       , gsd_group_wording
                       , gsd_group_date
                       , gsd_object
                       , gsd_id_1
                       , gsd_id_2
                       , gsd_id_3
                       , gsd_with_quantity_accumulation
                       , a_idcre
                       , a_datecre
                       , a_idmod
                       , a_datemod
                       , gsd_object_commands
                       , gsd_from_document
                        )
                 values (init_id_seq.nextval
                       , asnapshotid
                       , agalprojectid
                       , v_gal_budget_id(i)
                       , v_doc_record_id(i)
                       , (case
                            when     v_gal_cost_center_id(i) is not null
                                 and v_acs_cda_account_id(i) is null then (select acs_cda_account_id
                                                                             from gal_cost_center
                                                                            where gal_cost_center_id = v_gal_cost_center_id(i) )
                            else v_acs_cda_account_id(i)
                          end
                         )
                       , (case
                            when     v_gal_cost_center_id(i) is not null
                                 and v_acs_cpn_account_id(i) is null then (select acs_cpn_account_id
                                                                             from gal_cost_center
                                                                            where gal_cost_center_id = v_gal_cost_center_id(i) )
                            else v_acs_cpn_account_id(i)
                          end
                         )
                       , v_gal_cost_center_id(i)
                       , v_gsd_number(i)
                       , v_gsd_wording(i)
                       , v_gsd_date(i)
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 1)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 1) then v_gsd_quantity(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 1)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 1) then -v_gsd_quantity(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 1)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 1) then v_gsd_amount(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 1)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 1) then -v_gsd_amount(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 2)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 2) then v_gsd_quantity(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 2)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 2) then -v_gsd_quantity(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 2)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 2) then v_gsd_amount(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 2)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 2) then -v_gsd_amount(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 3)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 3) then v_gsd_quantity(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 3)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 3) then -v_gsd_quantity(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 3)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 3) then v_gsd_amount(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 3)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 3) then -v_gsd_amount(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 4)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 4) then v_gsd_quantity(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 4)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 4) then -v_gsd_quantity(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 4)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 4) then v_gsd_amount(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 4)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 4) then -v_gsd_amount(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 5)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 5) then v_gsd_quantity(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 5)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 5) then -v_gsd_quantity(i)
                            else null
                          end
                         )
                       , (case
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 0
                                     and nvl(d_project_consolidation, 0) = 5)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 0
                                     and nvl(v_project_consolidation(i), 0) = 5) then v_gsd_amount(i)
                            when    (    nvl(d_gds_using_gauge, 0) = 0
                                     and nvl(d_consolidation_negative, 0) = 1
                                     and nvl(d_project_consolidation, 0) = 5)
                                 or (    nvl(d_gds_using_gauge, 0) = 1
                                     and nvl(v_consolidation_negative(i), 0) = 1
                                     and nvl(v_project_consolidation(i), 0) = 5) then -v_gsd_amount(i)
                            else null
                          end
                         )
                       , v_gsd_origin_number(i)
                       , v_gsd_origin_wording(i)
                       , v_gsd_group_id(i)
                       , v_gsd_group_number(i)
                       , v_gsd_group_wording(i)
                       , v_gsd_group_date(i)
                       , v_gsd_object(i)
                       , v_gsd_id_1(i)
                       , v_gsd_id_2(i)
                       , v_gsd_id_3(i)
                       , d_gds_with_qty_accumulation
                       , pcs.PC_I_LIB_SESSION.getuserini
                       , sysdate
                       , null
                       , null
                       , v_gsd_object_commands(i)
                       , decode(nvl(d_gds_using_gauge, 0), 0, 0, 1)
                        );
        end if;
      end if;
    end loop;

    close crgaldefspending;

    update_periode(agalprojectid);   -- les lignes créées n'ont pas de budget ni de réestimation, donc le reclaclul en fonction du type de suivi fianncier peut se faire avant

    if not v_gal_proc_conso_det_bef_prov is null then
      sqlstatement  :=
                      'BEGIN ' || trim(v_gal_proc_conso_det_bef_prov)
                      || '(:agalprojectid,:asnapshotdate,:asnapshotid,:aconfigreqsel,:adatemin,:adatemax); END;';

      execute immediate sqlstatement
                  using in agalprojectid, in asnapshotdate, in asnapshotid, in aconfigreqsel, in adatemin, in adatemax;
    end if;

    if     v_AcGalSpendingType <> 1
       and v_AcGalSpendingType <> 3 then
      change_amount_not_for_document(v_LocalCurrency, v_ProjectCurrency, agalprojectid, v_AcGalSpendingType, a_valuationrate_for_SF4, asnapshotdate);
    end if;

    -- Création des dépenses détaillées de provision
    if cprovactif = 1 then
      insert into gal_spending_detail
                  (gal_spending_detail_id
                 , gal_snapshot_id
                 , gal_project_id
                 , gal_budget_id
                 , doc_record_id
                 , acs_cda_account_id
                 , acs_cpn_account_id
                 , gal_cost_center_id
                 , gsd_number
                 , gsd_wording
                 , gsd_date
                 , gsd_col1_quantity
                 , gsd_col1_amount
                 , gsd_col2_quantity
                 , gsd_col2_amount
                 , gsd_col3_quantity
                 , gsd_col3_amount
                 , gsd_col4_quantity
                 , gsd_col4_amount
                 , gsd_col5_quantity
                 , gsd_col5_amount
                 , gsd_origin_number
                 , gsd_origin_wording
                 , gsd_group_id
                 , gsd_group_number
                 , gsd_group_wording
                 , gsd_group_date
                 , gsd_object
                 , gsd_id_1
                 , gsd_id_2
                 , gsd_id_3
                 , gsd_with_quantity_accumulation
                 , a_idcre
                 , a_datecre
                 , a_idmod
                 , a_datemod
                 , gal_budget_period_id
                  )
        select   GetNewId
               , asnapshotid
               , gsp.gal_project_id
               , gsp.gal_budget_id
               , null
               , null
               , null
               , nat.gal_gal_cost_center_id gal_cost_center_id
               , prv.gcc_code gsd_number
               , prv.gcc_wording gsd_wording
               , null
               , null
               , sum(gsp.gsd_col1_amount) * nat.gcc_provision_rate / 100 gsd_col1_amount
               , null
               , sum(gsp.gsd_col2_amount) * nat.gcc_provision_rate / 100 gsd_col2_amount
               , null
               , sum(gsp.gsd_col3_amount) * nat.gcc_provision_rate / 100 gsd_col3_amount
               , null
               , sum(gsp.gsd_col4_amount) * nat.gcc_provision_rate / 100 gsd_col4_amount
               , null
               , sum(gsp.gsd_col5_amount) * nat.gcc_provision_rate / 100 gsd_col5_amount
               , null
               , null
               , nat.gal_cost_center_id gsd_group_id
               , nat.gcc_code gsd_group_number
               , nat.gcc_wording gsd_group_wording
               , null
               , null
               , null
               , null
               , null
               , null
               , pcs.PC_I_LIB_SESSION.getuserini
               , sysdate
               , null
               , null
               , gal_budget_period_id
            from gal_cost_center prv
               , gal_cost_center nat
               , gal_spending_detail gsp
           where prv.gal_cost_center_id = nat.gal_gal_cost_center_id
             and nat.gal_cost_center_id = gsp.gal_cost_center_id
             and nat.gal_gal_cost_center_id is not null
             and gsp.gal_snapshot_id = asnapshotid
        group by gsp.gal_project_id
               , gsp.gal_budget_id
               , nat.gal_gal_cost_center_id
               , prv.gcc_code
               , prv.gcc_wording
               , nat.gal_cost_center_id
               , nat.gcc_code
               , nat.gcc_wording
               , nat.gcc_provision_rate
               , gal_budget_period_id;
    end if;

    if not v_gal_proc_conso_del_detail is null then
      -- execution de la commande
      sqlstatement  := 'BEGIN ' || trim(v_gal_proc_conso_del_detail) || '(:agalprojectid,:asnapshotdate,:asnapshotid,:aconfigreqsel); END;';

      execute immediate sqlstatement
                  using in agalprojectid, in asnapshotdate, in asnapshotid, in aconfigreqsel;
    end if;
  end gal_spending_detail_create;

  /**
  * Description : Création des dépenses consolidéles par couple nature analytique / Code budget
  *
  * @author Matthieu Lesur
  * @version Date 11.11.2005
  * @param c_gal_project_id         : ID d'affaire
  * @param c_gal_budget_id         : ID de code budget
  * @non-public
  */
  procedure gal_spending_cumul_create(
    agalprojectid          gal_project.gal_project_id%type
  , agalbudgetid           gal_budget.gal_budget_id%type
  , asnapshotdate          date default null
  , asnapshotid            gal_snapshot.gal_snapshot_id%type default 0
  , v_ac_gal_spending_type integer
  )
  is
    type typ_tab_number is table of number;

    v_gal_cost_center_id           typ_tab_number;
    v_gsp_col1_quantity            typ_tab_number;
    v_gsp_col1_amount              typ_tab_number;
    v_gsp_col2_quantity            typ_tab_number;
    v_gsp_col2_amount              typ_tab_number;
    v_gsp_col3_quantity            typ_tab_number;
    v_gsp_col3_amount              typ_tab_number;
    v_gsp_col4_quantity            typ_tab_number;
    v_gsp_col4_amount              typ_tab_number;
    v_gsp_col5_quantity            typ_tab_number;
    v_gsp_col5_amount              typ_tab_number;
    v_bli_budget_quantity          typ_tab_number;
    v_bli_budget_amount            typ_tab_number;
    v_bli_last_estimation_quantity typ_tab_number;
    v_bli_last_estimation_amount   typ_tab_number;
    v_bli_remaining_quantity       typ_tab_number;
    v_bli_remaining_amount         typ_tab_number;
    v_bli_hang_spending_quantity   typ_tab_number;
    v_bli_hang_spending_amount     typ_tab_number;
    v_gal_budget_period_id         typ_tab_number;
    v_bli_remaining_amount_at_date typ_tab_number;
    v_save_rate_change             number(12, 4);
    v_cfggalConsCalcHourFromRemain varchar2(30)                                            := pcs.pc_config.getconfig('GAL_CONS_CALC_HOUR_FROM_REMAIN');
    v_gch_hourly_rate              gal_cost_hourly_rate.GCH_HOURLY_RATE%type;
    v_LocalCurrency                ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    v_ProjectCurrency              ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    a_ProjectExchangeRate          GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    a_ProjectBasePrice             GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
    a_gal_proc_valuationrate_SF4   varchar2(255);
    a_valuationrate_for_SF4        GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type             := 0;

    type ttblspendingconsolidated is table of gal_spending_consolidated%rowtype;

    vtblspendingconsolidated       ttblspendingconsolidated;

    -- somme des dépenses
    cursor c_gal_spending_consolidated(
      acrprojectid  gal_project.gal_project_id%type
    , acrbudgetid   gal_budget.gal_budget_id%type
    , acrsnapshotid gal_snapshot.gal_snapshot_id%type
    )
    is
      select *
        from gal_spending_consolidated
       where gal_project_id = acrprojectid
         and gal_budget_id = acrbudgetid
         and gal_snapshot_id = acrsnapshotid;
  begin
    if v_cfggalConsCalcHourFromRemain = 1 then
      v_LocalCurrency          := ACS_FUNCTION.GetLocalCurrencyID;
      v_ProjectCurrency        := GAL_LIB_PROJECT.GetProjectCurrency(agalprojectid);

      if not(v_LocalCurrency = v_ProjectCurrency) then
        begin
          select pcs.pc_config.getconfig
                                ('GAL_PROC_VALUATIONRATE_SF4')   -- recherche de la procédure qui calcule le taux forcé pour remonter en monnaie de contrat dans SF4
            into a_gal_proc_valuationrate_SF4
            from dual;
        exception
          when no_data_found then
            a_gal_proc_valuationrate_SF4  := null;
        end;

        if a_gal_proc_valuationrate_SF4 is not null   -- on initialise le taux forcé de la monnaie de contrat pour SF4
                                                   then
          sqlstatement  := 'BEGIN ' || trim(a_gal_proc_valuationrate_SF4) || '(:agalprojectid,:a_valuationrate_for_SF4); END;';

          execute immediate sqlstatement
                      using in agalprojectid, in out a_valuationrate_for_SF4;
        end if;
      end if;

      a_valuationrate_for_SF4  := nvl(a_valuationrate_for_SF4, 0);
    end if;

    execute immediate c_gal_spending_detail
    bulk collect into v_gal_cost_center_id
                    , v_gal_budget_period_id
                    , v_gsp_col1_quantity
                    , v_gsp_col1_amount
                    , v_gsp_col2_quantity
                    , v_gsp_col2_amount
                    , v_gsp_col3_quantity
                    , v_gsp_col3_amount
                    , v_gsp_col4_quantity
                    , v_gsp_col4_amount
                    , v_gsp_col5_quantity
                    , v_gsp_col5_amount
                using agalprojectid, agalbudgetid, asnapshotid;

    -- Ecriture dans la table consolidée des dépenses
    if v_gal_cost_center_id.first is not null then
      forall i in v_gal_cost_center_id.first .. v_gal_cost_center_id.last
        insert into gal_spending_consolidated
                    (gal_spending_consolidated_id
                   , gal_snapshot_id
                   , gal_project_id
                   , gal_budget_id
                   , gal_cost_center_id
                   , gsp_budget_quantity
                   , gsp_budget_amount
                   , gsp_col1_quantity
                   , gsp_col1_amount
                   , gsp_col2_quantity
                   , gsp_col2_amount
                   , gsp_col3_quantity
                   , gsp_col3_amount
                   , gsp_col4_quantity
                   , gsp_col4_amount
                   , gsp_col5_quantity
                   , gsp_col5_amount
                   , gsp_total_quantity
                   , gsp_total_amount
                   , gsp_remaining_quantity
                   , gsp_remaining_amount
                   , gsp_margin_quantity
                   , gsp_margin_amount
                   , gsp_perc_margin_quantity
                   , gsp_perc_margin_amount
                   , gsp_estimation_total_quantity
                   , gsp_estimation_total_amount
                   , a_idcre
                   , a_datecre
                   , a_idmod
                   , a_datemod
                   , gal_budget_period_id
                    )
             values (init_id_seq.nextval
                   , asnapshotid
                   , agalprojectid
                   , agalbudgetid
                   , v_gal_cost_center_id(i)
                   , null
                   , null
                   , v_gsp_col1_quantity(i)
                   , v_gsp_col1_amount(i)
                   , v_gsp_col2_quantity(i)
                   , v_gsp_col2_amount(i)
                   , v_gsp_col3_quantity(i)
                   , v_gsp_col3_amount(i)
                   , v_gsp_col4_quantity(i)
                   , v_gsp_col4_amount(i)
                   , v_gsp_col5_quantity(i)
                   , v_gsp_col5_amount(i)
                   , null
                   , null
                   , null
                   , null
                   , null
                   , null
                   , null
                   , null
                   , null
                   , null
                   , pcs.PC_I_LIB_SESSION.getuserini
                   , sysdate
                   , null
                   , null
                   , v_gal_budget_period_id(i)
                    );
    end if;

    execute immediate c_gal_budget_line
    bulk collect into v_gal_cost_center_id
                    , v_gal_budget_period_id
                    , v_bli_budget_quantity
                    , v_bli_budget_amount
                    , v_bli_last_estimation_quantity
                    , v_bli_last_estimation_amount
                    , v_bli_remaining_quantity
                    , v_bli_remaining_amount
                    , v_bli_hang_spending_quantity
                    , v_bli_hang_spending_amount
                    , v_bli_remaining_amount_at_date
                using agalbudgetid;

    if v_gal_cost_center_id.first is not null then
      for i in v_gal_cost_center_id.first .. v_gal_cost_center_id.last loop
        update gal_spending_consolidated
           set gsp_budget_quantity = v_bli_budget_quantity(i)
             , gsp_budget_amount = v_bli_budget_amount(i)
             , gsp_remaining_amount = v_bli_remaining_amount(i)
             , gsp_remaining_quantity = v_bli_remaining_quantity(i)
             , gsp_total_quantity = v_bli_hang_spending_quantity(i)
             , gsp_total_amount = v_bli_hang_spending_amount(i)
             , gsp_estimation_total_quantity = v_bli_last_estimation_quantity(i)
             , gsp_estimation_total_amount = v_bli_last_estimation_amount(i)
             , gsp_remaining_amount_delta = v_bli_remaining_amount_at_date(i)
         where gal_project_id = agalprojectid
           and gal_budget_id = agalbudgetid
           and gal_snapshot_id = asnapshotid
           and gal_cost_center_id = v_gal_cost_center_id(i)
           and gal_budget_period_id = v_gal_budget_period_id(i);

        -- Pas encore de dépense,alors on crée une nouvelle ligne
        if sql%notfound then
          create_gal_spending_consol(agalprojectid
                                   , asnapshotid
                                   , agalbudgetid
                                   , v_gal_cost_center_id(i)
                                   , v_bli_budget_quantity(i)
                                   , v_bli_budget_amount(i)
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , v_bli_hang_spending_quantity(i)
                                   , v_bli_hang_spending_amount(i)
                                   , v_bli_remaining_quantity(i)
                                   , v_bli_remaining_amount(i)
                                   , null
                                   , null
                                   , null
                                   , null
                                   , v_bli_last_estimation_quantity(i)
                                   , v_bli_last_estimation_amount(i)
                                   , v_gal_budget_period_id(i)
                                   , v_bli_remaining_amount_at_date(i)
                                    );
        end if;
      end loop;
    end if;

    -- Création des budgets de povision
    if cprovactif = 1 then
      for prov in (select nat.gal_cost_center_id
                        , nat.gcc_code
                        , nat.gcc_wording
                        , nat.gal_gal_cost_center_id
                        , nat.gcc_provision_rate
                        , nvl(bud.bli_budget_amount, 0) * nat.gcc_provision_rate / 100 bli_budget_amount
                        , nvl(bud.bli_remaining_amount_at_date, 0) * nat.gcc_provision_rate / 100 bli_remaining_amount_at_date
                        , nvl(bud.bli_remaining_amount, 0) * nat.gcc_provision_rate / 100 bli_remaining_amount
                        , nvl(bud.bli_hanging_spending_amount, 0) * nat.gcc_provision_rate / 100 bli_hanging_spending_amount
                        , nvl(gal_budget_period_id, 0) gal_budget_period_id   --MLE 15/05/11
                     from gal_cost_center nat
                        , gal_conso_budget_line_temp bud   -- gal_budget_line bud
                    where nat.gal_gal_cost_center_id is not null
                      and bud.gal_budget_id = agalbudgetid
                      and nat.gal_cost_center_id = bud.gal_cost_center_id) loop
        --Ecriture dans la table consolidée des dépenses
        update gal_spending_consolidated
           set gsp_budget_amount = nvl(gsp_budget_amount, 0) + prov.bli_budget_amount
             , gsp_remaining_amount = nvl(gsp_remaining_amount, 0) + prov.bli_remaining_amount
             , gsp_remaining_amount_delta = nvl(gsp_remaining_amount_delta, 0) + prov.bli_remaining_amount_at_date
             , gsp_total_amount = nvl(gsp_total_amount, 0) + prov.bli_hanging_spending_amount
         where gal_project_id = agalprojectid
           and gal_budget_id = agalbudgetid
           and gal_cost_center_id = prov.gal_gal_cost_center_id
           and gal_budget_period_id = prov.gal_budget_period_id
           and gal_snapshot_id = asnapshotid;

        if sql%notfound then
          create_gal_spending_consol(agalprojectid
                                   , asnapshotid
                                   , agalbudgetid
                                   , prov.gal_gal_cost_center_id
                                   , null
                                   , prov.bli_budget_amount
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , prov.bli_hanging_spending_amount
                                   , null
                                   , prov.bli_remaining_amount
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , null
                                   , prov.gal_budget_period_id
                                   , prov.bli_remaining_amount_at_date
                                    );
        end if;
      end loop;
    end if;

    -- Calcul des totaux
    open c_gal_spending_consolidated(agalprojectid, agalbudgetid, asnapshotid);

    fetch c_gal_spending_consolidated
    bulk collect into vtblspendingconsolidated;

    close c_gal_spending_consolidated;

    if vtblspendingconsolidated.count > 0 then
      for i in vtblspendingconsolidated.first .. vtblspendingconsolidated.last loop
        --      pcs.writelog ('gal_budget_id' || vtblspendingconsolidated (i).gal_budget_id);
        --              pcs.writelog ('gsp_remaining_amount_delta 1 ' || vtblspendingconsolidated (i).gsp_remaining_amount_delta);
           --           pcs.writelog ('gsp_remaining_amount 1 ' || vtblspendingconsolidated (i).gsp_remaining_amount);
        if     vtblspendingconsolidated(i).gsp_remaining_amount_delta = 0
           and vtblspendingconsolidated(i).gsp_remaining_amount_delta is not null then
          null;
        else
          if nvl(vtblspendingconsolidated(i).gsp_remaining_amount, 0) = 0 then
            v_Save_rate_change  := 1;
          else
            --    pcs.writelog ('gsp_remaining_amount_delta 2 ' || vtblspendingconsolidated (i).gsp_remaining_amount_delta);
             --   pcs.writelog ('gsp_remaining_amount 2 ' || vtblspendingconsolidated (i).gsp_remaining_amount);
            v_Save_rate_change  := vtblspendingconsolidated(i).gsp_remaining_amount_delta / vtblspendingconsolidated(i).gsp_remaining_amount;
          end if;

          vtblspendingconsolidated(i).gsp_remaining_amount_delta  :=
            nvl(vtblspendingconsolidated(i).gsp_total_amount, 0) +   --attention on le hangng quantity dans cette variable et pas le total, modif hmo suite à gestion des suivi financiers multi devises pour neutraliser les efftes de change sur le reste
            nvl(vtblspendingconsolidated(i).gsp_remaining_amount_delta, 0)
                                                                          -- on cahneg la façon de calculer, avant on part du toal estimé pour claculer le reste, maintenat n le total = aux dépenses + le rste recklaculer à aujorujourd'hui
            -
            nvl(vtblspendingconsolidated(i).gsp_col1_amount, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col2_amount, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col3_amount, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col4_amount, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col5_amount, 0);
          vtblspendingconsolidated(i).gsp_remaining_amount        := vtblspendingconsolidated(i).gsp_remaining_amount_delta / v_Save_rate_change;

          --  pcs.writelog ('hanging ' || NVL (vtblspendingconsolidated (i).gsp_total_amount, 0));
          --     pcs.writelog ('hanging 2 ' ||  NVL (vtblspendingconsolidated (i).gsp_col1_amount, 0));

          --  pcs.writelog ('gsp_remaining_amount_delta 3 ' || vtblspendingconsolidated (i).gsp_remaining_amount_delta);
          --  pcs.writelog ('gsp_remaining_amount 3 ' || vtblspendingconsolidated (i).gsp_remaining_amount);
          if vtblspendingconsolidated(i).gsp_remaining_amount < 0 then
            vtblspendingconsolidated(i).gsp_remaining_amount  := 0;
          end if;
        end if;

        if     vtblspendingconsolidated(i).gsp_remaining_quantity = 0
           and vtblspendingconsolidated(i).gsp_remaining_quantity is not null then
          null;
        --  pcs.writelog (' in null');
        else
          vtblspendingconsolidated(i).gsp_remaining_quantity  :=
            nvl(vtblspendingconsolidated(i).gsp_total_quantity, 0) +
            nvl(vtblspendingconsolidated(i).gsp_remaining_quantity, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col1_quantity, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col2_quantity, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col3_quantity, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col4_quantity, 0) -
            nvl(vtblspendingconsolidated(i).gsp_col5_quantity, 0);

          if v_cfggalConsCalcHourFromRemain = 1 then
            if asnapshotdate is null   -- ici on recherche les tauix en monnaie de société, car la procédure ne tint pas compte du taux transformé en taux fixe
                                    then
              select nvl(GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_NAT_ANA(vtblspendingconsolidated(i).gal_cost_center_id, sysdate), 0)
                into v_gch_hourly_rate
                from dual;
            else
              select nvl(GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_NAT_ANA(vtblspendingconsolidated(i).gal_cost_center_id, asnapshotdate), 0)
                into v_gch_hourly_rate
                from dual;
            end if;

            --      pcs.writelog ('hmo test hourly' || v_gch_hourly_rate);
            if v_LocalCurrency <> v_ProjectCurrency then
              if v_ac_gal_spending_type = 2 then
                GAL_LIB_PROJECT.GetProjectCurrencyRate(agalprojectid,   -- un seul taux car les montants à trabsformer sont tous en monnaie de socitété
                                                       v_ProjectCurrency, a_ProjectExchangeRate, a_ProjectBasePrice);
                v_gch_hourly_rate  := v_gch_hourly_rate * a_ProjectBasePrice / a_ProjectExchangeRate;
              end if;

              if v_ac_gal_spending_type = 4 then
                if a_valuationrate_for_SF4 = 0 then
                  if asnapshotdate is null then
                    v_gch_hourly_rate  := ACS_FUNCTION.ConvertAmountForView(v_gch_hourly_rate, v_LocalCurrency, v_ProjectCurrency, sysdate, 0, 0, 0);
                  else
                    v_gch_hourly_rate  := ACS_FUNCTION.ConvertAmountForView(v_gch_hourly_rate, v_LocalCurrency, v_ProjectCurrency, asnapshotdate, 0, 0, 0);
                  end if;
                else
                  v_gch_hourly_rate  := v_gch_hourly_rate * a_valuationrate_for_SF4;
                end if;
              end if;

              if v_gch_hourly_rate <> 0 then
                vtblspendingconsolidated(i).gsp_remaining_quantity  := vtblspendingconsolidated(i).gsp_remaining_amount / v_gch_hourly_rate;
              end if;
            end if;
          end if;

          if vtblspendingconsolidated(i).gsp_remaining_quantity < 0 then
            vtblspendingconsolidated(i).gsp_remaining_quantity  := 0;
          end if;
        end if;

        vtblspendingconsolidated(i).gsp_total_quantity          :=
          vtblspendingconsolidated(i).gsp_remaining_quantity +
          nvl(vtblspendingconsolidated(i).gsp_col1_quantity, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col2_quantity, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col3_quantity, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col4_quantity, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col5_quantity, 0);
        vtblspendingconsolidated(i).gsp_total_amount            :=
          vtblspendingconsolidated(i).gsp_remaining_amount +
          nvl(vtblspendingconsolidated(i).gsp_col1_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col2_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col3_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col4_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col5_amount, 0);
        vtblspendingconsolidated(i).gsp_remaining_amount_delta  :=
          vtblspendingconsolidated(i).gsp_remaining_amount_delta +
          nvl(vtblspendingconsolidated(i).gsp_col1_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col2_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col3_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col4_amount, 0) +
          nvl(vtblspendingconsolidated(i).gsp_col5_amount, 0);
        vtblspendingconsolidated(i).gsp_margin_quantity         :=
                                                 nvl(vtblspendingconsolidated(i).gsp_budget_quantity, 0)
                                                 - nvl(vtblspendingconsolidated(i).gsp_total_quantity, 0);
        vtblspendingconsolidated(i).gsp_margin_amount           :=
                                                     nvl(vtblspendingconsolidated(i).gsp_budget_amount, 0)
                                                     - nvl(vtblspendingconsolidated(i).gsp_total_amount, 0);

        if nvl(vtblspendingconsolidated(i).gsp_budget_quantity, 0) <> 0 then
          vtblspendingconsolidated(i).gsp_perc_margin_quantity  :=
                                                 nvl(vtblspendingconsolidated(i).gsp_margin_quantity, 0) * 100
                                                 / vtblspendingconsolidated(i).gsp_budget_quantity;
        end if;

        if nvl(vtblspendingconsolidated(i).gsp_budget_amount, 0) <> 0 then
          vtblspendingconsolidated(i).gsp_perc_margin_amount  :=
                                                     nvl(vtblspendingconsolidated(i).gsp_margin_amount, 0) * 100
                                                     / vtblspendingconsolidated(i).gsp_budget_amount;
        end if;

        update gal_spending_consolidated
           set gsp_total_quantity = vtblspendingconsolidated(i).gsp_total_quantity
             , gsp_total_amount = vtblspendingconsolidated(i).gsp_total_amount
             , gsp_remaining_amount_delta = vtblspendingconsolidated(i).gsp_remaining_amount_delta
             , gsp_remaining_quantity = vtblspendingconsolidated(i).gsp_remaining_quantity
             , gsp_remaining_amount = vtblspendingconsolidated(i).gsp_remaining_amount
             , gsp_margin_quantity = vtblspendingconsolidated(i).gsp_margin_quantity
             , gsp_margin_amount = vtblspendingconsolidated(i).gsp_margin_amount
             , gsp_perc_margin_quantity = vtblspendingconsolidated(i).gsp_perc_margin_quantity
             , gsp_perc_margin_amount = vtblspendingconsolidated(i).gsp_perc_margin_amount
         where gal_spending_consolidated_id = vtblspendingconsolidated(i).gal_spending_consolidated_id;
      end loop;
    end if;
  end gal_spending_cumul_create;

  /**
  * Description : Consolidatin multi-niveaux sur la structure budgétaire
  *
  * @author Matthieu Lesur
  * @version Date 11.011.2005
  * @param aProjectId         : ID d'affaire
  * @param aBudgetId         : ID de code budget
  * @param aSnapshotId       : Id du snapshot
  * @non-public
  */
  procedure gal_spending_level_create(
    aprojectid  gal_project.gal_project_id%type
  , abudgetid   gal_budget.gal_budget_id%type
  , asnapshotid gal_snapshot.gal_snapshot_id%type
  )
  is
    v_gal_cost_center_id          gal_spending_consolidated.gal_cost_center_id%type;
    v_gsp_budget_quantity         gal_spending_consolidated.gsp_budget_quantity%type;
    v_gsp_budget_amount           gal_spending_consolidated.gsp_budget_amount%type;
    v_gsp_col1_quantity           gal_spending_consolidated.gsp_col1_quantity%type;
    v_gsp_col1_amount             gal_spending_consolidated.gsp_col1_amount%type;
    v_gsp_col2_quantity           gal_spending_consolidated.gsp_col1_quantity%type;
    v_gsp_col2_amount             gal_spending_consolidated.gsp_col1_amount%type;
    v_gsp_col3_quantity           gal_spending_consolidated.gsp_col1_quantity%type;
    v_gsp_col3_amount             gal_spending_consolidated.gsp_col1_amount%type;
    v_gsp_col4_quantity           gal_spending_consolidated.gsp_col1_quantity%type;
    v_gsp_col4_amount             gal_spending_consolidated.gsp_col1_amount%type;
    v_gsp_col5_quantity           gal_spending_consolidated.gsp_col1_quantity%type;
    v_gsp_col5_amount             gal_spending_consolidated.gsp_col1_amount%type;
    v_gsp_total_quantity          gal_spending_consolidated.gsp_total_quantity%type;
    v_gsp_total_amount            gal_spending_consolidated.gsp_total_amount%type;
    v_gsp_remaining_quantity      gal_spending_consolidated.gsp_remaining_quantity%type;
    v_gsp_remaining_amount        gal_spending_consolidated.gsp_remaining_amount%type;
    v_gsp_margin_quantity         gal_spending_consolidated.gsp_margin_quantity%type;
    v_gsp_margin_amount           gal_spending_consolidated.gsp_margin_amount%type;
    v_gsp_estimation_total_qty    gal_spending_consolidated.gsp_estimation_total_quantity%type;
    v_gsp_estimation_total_amount gal_spending_consolidated.gsp_estimation_total_amount%type;
    v_gal_budget_period_id        gal_spending_consolidated.gal_budget_period_id%type;
    v_gsp_remaining_amount_delta  gal_spending_consolidated.gsp_remaining_amount_delta%type;

    cursor c_gal_cumul_sous_budget(
      acrprojectid  gal_project.gal_project_id%type
    , acrbudgetid   gal_budget.gal_budget_id%type
    , acrsnapshotid gal_snapshot.gal_snapshot_id%type
    )
    is
      select   gal_cost_center_id
             , gal_budget_period_id
             , sum(gsp_budget_quantity)
             , sum(gsp_budget_amount)
             , sum(gsp_col1_quantity)
             , sum(gsp_col1_amount)
             , sum(gsp_col2_quantity)
             , sum(gsp_col2_amount)
             , sum(gsp_col3_quantity)
             , sum(gsp_col3_amount)
             , sum(gsp_col4_quantity)
             , sum(gsp_col4_amount)
             , sum(gsp_col5_quantity)
             , sum(gsp_col5_amount)
             , sum(gsp_total_quantity)
             , sum(gsp_total_amount)
             , sum(gsp_remaining_quantity)
             , sum(gsp_remaining_amount)
             , sum(gsp_margin_quantity)
             , sum(gsp_margin_amount)
             , sum(gsp_estimation_total_quantity)
             , sum(gsp_estimation_total_amount)
             , sum(gsp_remaining_amount_delta)
          from gal_spending_consolidated
         where gal_project_id = acrprojectid
           and gal_snapshot_id = asnapshotid
           and gal_budget_id in(select     gal_budget_id
                                      from gal_budget
                                     where gal_project_id = acrprojectid
                                connect by prior gal_budget_id = gal_father_budget_id
                                start with gal_father_budget_id = acrbudgetid)
      group by gal_cost_center_id
             , gal_budget_period_id;

    cursor c_gal_cumul_budget_niv1(acrprojectid gal_project.gal_project_id%type, acrsnapshotid gal_snapshot.gal_snapshot_id%type)
    is
      select   gal_cost_center_id
             , gal_budget_period_id
             , sum(gsp_budget_quantity)
             , sum(gsp_budget_amount)
             , sum(gsp_col1_quantity)
             , sum(gsp_col1_amount)
             , sum(gsp_col2_quantity)
             , sum(gsp_col2_amount)
             , sum(gsp_col3_quantity)
             , sum(gsp_col3_amount)
             , sum(gsp_col4_quantity)
             , sum(gsp_col4_amount)
             , sum(gsp_col5_quantity)
             , sum(gsp_col5_amount)
             , sum(gsp_total_quantity)
             , sum(gsp_total_amount)
             , sum(gsp_remaining_quantity)
             , sum(gsp_remaining_amount)
             , sum(gsp_margin_quantity)
             , sum(gsp_margin_amount)
             , sum(gsp_estimation_total_quantity)
             , sum(gsp_estimation_total_amount)
             , sum(gsp_remaining_amount_delta)
          from gal_spending_consolidated
         where gal_project_id = acrprojectid
           and gal_snapshot_id = acrsnapshotid
           and gal_budget_id in(select gal_budget_id
                                  from gal_budget
                                 where gal_project_id = acrprojectid
                                   and gal_father_budget_id is null)
      group by gal_cost_center_id
             , gal_budget_period_id;
  begin
    -- conso sur les totaux des budets
    open c_gal_cumul_sous_budget(aprojectid, abudgetid, asnapshotid);

    loop
      fetch c_gal_cumul_sous_budget
       into v_gal_cost_center_id
          , v_gal_budget_period_id
          , v_gsp_budget_quantity
          , v_gsp_budget_amount
          , v_gsp_col1_quantity
          , v_gsp_col1_amount
          , v_gsp_col2_quantity
          , v_gsp_col2_amount
          , v_gsp_col3_quantity
          , v_gsp_col3_amount
          , v_gsp_col4_quantity
          , v_gsp_col4_amount
          , v_gsp_col5_quantity
          , v_gsp_col5_amount
          , v_gsp_total_quantity
          , v_gsp_total_amount
          , v_gsp_remaining_quantity
          , v_gsp_remaining_amount
          , v_gsp_margin_quantity
          , v_gsp_margin_amount
          , v_gsp_estimation_total_qty
          , v_gsp_estimation_total_amount
          , v_gsp_remaining_amount_delta;

      exit when c_gal_cumul_sous_budget%notfound;
      update_gal_spending_consol(aprojectid
                               , asnapshotid
                               , abudgetid
                               , v_gal_cost_center_id
                               , v_gsp_budget_quantity
                               , v_gsp_budget_amount
                               , v_gsp_col1_quantity
                               , v_gsp_col1_amount
                               , v_gsp_col2_quantity
                               , v_gsp_col2_amount
                               , v_gsp_col3_quantity
                               , v_gsp_col3_amount
                               , v_gsp_col4_quantity
                               , v_gsp_col4_amount
                               , v_gsp_col5_quantity
                               , v_gsp_col5_amount
                               , v_gsp_total_quantity
                               , v_gsp_total_amount
                               , v_gsp_remaining_quantity
                               , v_gsp_remaining_amount
                               , v_gsp_margin_quantity
                               , v_gsp_margin_amount
                               , v_gsp_estimation_total_qty
                               , v_gsp_estimation_total_amount
                               , v_gal_budget_period_id
                               , v_gsp_remaining_amount_delta
                                );
    end loop;

    close c_gal_cumul_sous_budget;

    if abudgetid is null then
      -- Conso des totaux sur affaire
      open c_gal_cumul_budget_niv1(aprojectid, asnapshotid);

      loop
        fetch c_gal_cumul_budget_niv1
         into v_gal_cost_center_id
            , v_gal_budget_period_id
            , v_gsp_budget_quantity
            , v_gsp_budget_amount
            , v_gsp_col1_quantity
            , v_gsp_col1_amount
            , v_gsp_col2_quantity
            , v_gsp_col2_amount
            , v_gsp_col3_quantity
            , v_gsp_col3_amount
            , v_gsp_col4_quantity
            , v_gsp_col4_amount
            , v_gsp_col5_quantity
            , v_gsp_col5_amount
            , v_gsp_total_quantity
            , v_gsp_total_amount
            , v_gsp_remaining_quantity
            , v_gsp_remaining_amount
            , v_gsp_margin_quantity
            , v_gsp_margin_amount
            , v_gsp_estimation_total_qty
            , v_gsp_estimation_total_amount
            , v_gsp_remaining_amount_delta;

        exit when c_gal_cumul_budget_niv1%notfound;
        update_gal_spending_consol(aprojectid
                                 , asnapshotid
                                 , abudgetid
                                 , v_gal_cost_center_id
                                 , v_gsp_budget_quantity
                                 , v_gsp_budget_amount
                                 , v_gsp_col1_quantity
                                 , v_gsp_col1_amount
                                 , v_gsp_col2_quantity
                                 , v_gsp_col2_amount
                                 , v_gsp_col3_quantity
                                 , v_gsp_col3_amount
                                 , v_gsp_col4_quantity
                                 , v_gsp_col4_amount
                                 , v_gsp_col5_quantity
                                 , v_gsp_col5_amount
                                 , v_gsp_total_quantity
                                 , v_gsp_total_amount
                                 , v_gsp_remaining_quantity
                                 , v_gsp_remaining_amount
                                 , v_gsp_margin_quantity
                                 , v_gsp_margin_amount
                                 , v_gsp_estimation_total_qty
                                 , v_gsp_estimation_total_amount
                                 , v_gal_budget_period_id
                                 , v_gsp_remaining_amount_delta
                                  );
      end loop;

      close c_gal_cumul_budget_niv1;
    end if;
  end gal_spending_level_create;

  /********************************************************************************
  ***** PROCEDURE PRINCIPALE
  *****  1. ménage dans les tables de travail
  *****  2. recherche des dossiers
  *****     création des dépenses détaillées pour chaque dossier
  *****  3. recherche des budgets
  *****     création des dépenses consolidées pour chaque budget/nature analytique
  *****  4. consolidation multi niveaux sur la structure budgétaire
  ********************************************************************************/
  procedure gal_spending_generate(
    agalprojectid         gal_project.gal_project_id%type
  , agalbudgetid          gal_budget.gal_budget_id%type default null
  , agaltaskid            gal_task.gal_task_id%type default null
  , asnapshotdate         date default null
  , asnapshotid           gal_snapshot.gal_snapshot_id%type default 0
  , apurgeworktable       number default 1
  , aconfigreqsel         number default 0
  , asnap_type_date       number default -1
  , atreateafaire         boolean default false
  , adatemin              date default null
  , adatemax              date default null
  , ac_gal_spending_type  pcs.pc_gclst.gclcode%type default null
  , v_TauxEco             integer default 0
  , iIncludeProjectRecord integer default 0
  )
  is
    vcrgalbudget           type_cursor;
    vrecordidlist          ID_TABLE_TYPE;
    vsqlgalbudget          varchar2(4000);
    vbudgetid              gal_budget.gal_budget_id%type;
    vprojectid             gal_project.gal_project_id%type;
    sqlstatement           varchar2(2000);
    vbudgetid_inter        gal_budget.gal_budget_id%type;
    vprj_budget_period     gal_project.prj_budget_period%type;
    lcode                  gal_project.prj_code%type;
    lidsession             number(12)                           := getnewid;
    v_ac_gal_spending_type integer;
  begin
    if agalbudgetid <> 0 then
      begin
        select gal_project_id
          into vprojectid
          from gal_budget
         where gal_budget_id = agalbudgetid;
      exception
        when no_data_found then
          vprojectid  := null;
      end;
    elsif agaltaskid <> 0 then
      begin
        select gal_project_id
          into vprojectid
          from gal_task
         where gal_task_id = agaltaskid;
      exception
        when no_data_found then
          vprojectid  := null;
      end;
    elsif agalprojectid <> 0 then
      vprojectid  := agalprojectid;
    end if;

    if vprojectid is null then
      return;
    end if;

    select prj_code
      into lcode
      from gal_project
     where gal_project_id = vprojectid;

    if instr(pcs.PC_I_LIB_SESSION.getobjectname(), 'SNAPSHOT_COMPARE') > 0 then
      v_number_snapshot  := v_number_snapshot + 1;
    end if;

    -- Menage dans les tables de travail ML 19/07 passer GAL_PROJECT_ID pour supp que les données de cette affaire (cas de pilotage multi affaire)
    if apurgeworktable = 1 then
      purgeworktables(false);
    end if;

    declare
      lnProjectID GAL_PROJECT.GAL_PROJECT_ID%type;
      lnBudgetID  GAL_BUDGET.GAL_BUDGET_ID%type;
      lnTaskID    GAL_TASK.GAL_TASK_ID%type;
    begin
      lnProjectID    := null;
      lnBudgetID     := null;
      lnTaskID       := null;

      -- Remplacer les 0 par des null dans les variables des ID
      --  car la méthode GAL_LIB_PROJECT.GetRecordList ne gère pas les 0
      if nvl(vprojectid, 0) <> 0 then
        lnProjectID  := vprojectid;
      end if;

      if nvl(agalbudgetid, 0) <> 0 then
        lnBudgetID  := agalbudgetid;
      end if;

      if nvl(agaltaskid, 0) <> 0 then
        lnTaskID  := agaltaskid;
      end if;

      -- recherche de la liste des dossiers liés
      vrecordidlist  :=
          GAL_LIB_PROJECT.GetRecordList(iProjectID              => lnProjectID, iBudgetID => lnBudgetID, iTaskID => lnTaskID
                                      , iIncludeProjectRecord   => iIncludeProjectRecord);
    end;

    if nvl(ac_gal_spending_type, 0) = 0 then
      begin
        select pcs.pc_config.getconfig('GAL_FINANCIAL_FOLLOW_DEFAULT')
          into v_ac_gal_spending_type
          from dual;
      exception
        when no_data_found then
          v_ac_gal_spending_type  := 3;
      end;
    else
      v_ac_gal_spending_type  := ac_gal_spending_type;
    end if;

    --IF vrecordidlist IS NOT NULL            --hmo 27.3.2011 -> enlever car les bzudgets e réserve ne sont pas de doc_reord -> donc si que budget de rélserve les busgets ne sont pas affichés
    --THEN
    -- Création des dépenses détaillées
    gal_spending_detail_create(vprojectid
                             , vrecordidlist
                             , asnapshotdate
                             , asnapshotid
                             , aconfigreqsel
                             , asnap_type_date
                             , adatemin
                             , adatemax
                             , v_ac_gal_spending_type
                             , v_TauxEco
                              );

    --END IF;

    -- on remonte _id un code budget dans le projet afin depèouvoir traiter le facturé sur affaire dans le pilotage des enb-cours
    if atreateafaire then
      select min(gal_budget_id)
        into vbudgetid_inter
        from gal_spending_detail
       where gal_project_id = vprojectid;

      update gal_spending_detail
         set gal_budget_id = vbudgetid_inter
       where gal_project_id = vprojectid
         and gal_budget_id is null;
    end if;

    --Recherche des budgets

    -- Acces par AFFAIRE => tous les Budgets
    if agalprojectid <> 0 then
      vsqlgalbudget  :=
        'select GAL_BUDGET_ID from GAL_BUDGET ' ||
        'where GAL_PROJECT_ID = :GAL_PROJECT_ID ' ||
        'connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID ' ||
        'start with GAL_FATHER_BUDGET_ID is null ';
      vsqlgalbudget  := replace(vsqlgalbudget, ':GAL_PROJECT_ID', to_char(agalprojectid) );
    end if;

    -- Acces par DF/Tâche => Dossier du  DF/tâche et OP de DF
    if agaltaskid <> 0 then
      vsqlgalbudget  := 'select GAL_BUDGET_ID from GAL_TASK ' || 'where GAL_TASK_ID = :GAL_TASK_ID ';
      vsqlgalbudget  := replace(vsqlgalbudget, ':GAL_TASK_ID', to_char(agaltaskid) );
    end if;

    -- Acces par BUDGET => le Budget et tous les Sous Budgets
    if agalbudgetid <> 0 then
      vsqlgalbudget  :=
        'select GAL_BUDGET_ID from GAL_BUDGET ' ||
        'where GAL_BUDGET_ID = :GAL_BUDGET_ID ' ||
        'union ' ||
        'select GAL_BUDGET_ID from GAL_BUDGET ' ||
        'where GAL_PROJECT_ID = :GAL_PROJECT_ID ' ||
        'connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID ' ||
        'start with GAL_FATHER_BUDGET_ID = :GAL_BUDGET_ID ';
      vsqlgalbudget  := replace(vsqlgalbudget, ':GAL_PROJECT_ID', to_char(vprojectid) );
      vsqlgalbudget  := replace(vsqlgalbudget, ':GAL_BUDGET_ID', to_char(agalbudgetid) );
    end if;

    if vsqlgalbudget is not null then
      open vcrgalbudget for vsqlgalbudget;

      loop
        fetch vcrgalbudget
         into vbudgetid;

        exit when vcrgalbudget%notfound;
        gal_spending_cumul_create(vprojectid, vbudgetid, asnapshotdate, asnapshotid, v_ac_gal_spending_type);
      end loop;

      close vcrgalbudget;

      -- Acces par AFFAIRE => + Dépenses Consolidées niveau Affaire
      if agalprojectid <> 0 then
        gal_spending_cumul_create(vprojectid, null, asnapshotdate, asnapshotid, v_ac_gal_spending_type);
      end if;

      open vcrgalbudget for vsqlgalbudget;

      loop
        fetch vcrgalbudget
         into vbudgetid;

        exit when vcrgalbudget%notfound;
        -- Consolidation multi-niveau sur la structure budgétaire
        gal_spending_level_create(vprojectid, vbudgetid, asnapshotid);
      end loop;

      close vcrgalbudget;

      -- Acces par AFFAIRE => + Consolidation niveau Affaire
      if agalprojectid <> 0 then
        gal_spending_level_create(vprojectid, null, asnapshotid);
      end if;
    end if;
  end gal_spending_generate;

  procedure gal_spending_generate_with_sel(
    asqlgalproject        varchar2
  , asnapshotdate         date default null
  , aconfigreqsel         number default 0
  , asnap_type_date       number default -1
  , adatemin              date default null
  , adatemax              date default null
  , ac_gal_spending_type  pcs.pc_gclst.gclcode%type default null
  , v_mode                integer default 0
  , iIncludeProjectRecord integer default 0
  )
  is
    vcrgalproject type_cursor;
    vgalprojectid gal_project.gal_project_id%type;
    v_TauxEco     integer                           := 0;
  begin
    if asqlgalproject is not null then
      purgeworktables(true);

      if v_mode = 2 then
        v_TauxEco  := 1;
      end if;

      open vcrgalproject for asqlgalproject;

      loop
        fetch vcrgalproject
         into vgalprojectid;

        exit when vcrgalproject%notfound;
        gal_spending_generate(agalprojectid           => vgalprojectid
                            , agalbudgetid            => 0
                            , agaltaskid              => 0
                            , asnapshotdate           => asnapshotdate
                            , asnapshotid             => 0
                            , apurgeworktable         => 0
                            , aconfigreqsel           => aconfigreqsel
                            , asnap_type_date         => asnap_type_date
                            , atreateafaire           => false
                            , adatemin                => adatemin
                            , adatemax                => adatemax
                            , ac_gal_spending_type    => ac_gal_spending_type
                            , v_TauxEco               => v_TauxEco
                            , iIncludeProjectRecord   => iIncludeProjectRecord
                             );
      end loop;

      close vcrgalproject;
    end if;
  end gal_spending_generate_with_sel;

  /**
  * Description
  *    Détermine si le nombre maximum de photo n'est pas dépassé
  */
  function ismaxsnapshotreached
    return number
  is
    vnbsnapshot pls_integer;
    vresult     boolean;
  begin
    -- recherche du nombre de photo à date déjà existant
    select count(*)
      into vnbsnapshot
      from gal_snapshot;

    -- si la config est vide ou à 0, il n'y apas de limite
    vresult  :=     (nvl(cfggal_snapshot_number, 0) <> 0)
                and (vnbsnapshot >= to_number(cfggal_snapshot_number) );

    if vresult then
      return 1;
    else
      return 0;
    end if;
  end ismaxsnapshotreached;

  /**
  * Description
  *    Création de l'entête d'une photo à date
  */
  function createsnapshotheader(
    aprojectid       in gal_project.gal_project_id%type
  , asnapshotdate    in gal_snapshot.sna_date%type default sysdate
  , acomment         in gal_snapshot.sna_comment%type
  , aidentifier      in gal_snapshot.sna_identifier%type
  , afinancialorigin in gal_snapshot.sna_financial_origin%type default 0
  , aonline          in gal_snapshot.sna_online%type default 0
  , aSpendingType    in gal_snapshot.C_GAL_SPENDING_TYPE%type default null
  , ivGaugeType      in varchar2
  )
    return gal_snapshot.gal_snapshot_id%type
  is
    lnSnapShotID gal_snapshot.gal_snapshot_id%type;
  begin
    -- teste qu'on ne dépasse pas le nombre de photos à date maximal autorisé
    if ismaxsnapshotreached = 0 then
      -- création de l'entête GAL_SNAPSHOT
      GAL_PRC_SNAPSHOT.CreateSnapShot(oSnapshotID     => lnSnapShotID
                                    , iProjectID      => aprojectid
                                    , iDate           => aSnapShotDate
                                    , iComment        => aComment
                                    , iIdentifier     => aIdentifier
                                    , iSpendingType   => aSpendingType
                                    , iFinOrigin      => aFinancialOrigin
                                    , iOnline         => aOnline
                                     );

      -- création des liens documents GAL_SNAP_LINK
      if     aSpendingType in('02', '03', '04')
         and (aOnline = 1) then
        GAL_PRC_SNAPSHOT.CreateSnapLink(iSnapshotID => lnSnapShotID, ivGaugeType => ivGaugeType);
      end if;
    else
      raise_application_error(-20000, pcs.pc_functions.translateword('PCS - Le nombre maximal de photos à date autorisé est dépassé!') );
    end if;

    return lnSnapShotID;
  exception
    when others then
      -- place to log informations
      raise;
  end createsnapshotheader;

  /**
  * Description
  *    Création d'une photo à date
  */
  procedure createsnapshot(
    asnapshotid      out    gal_snapshot.gal_snapshot_id%type
  , aprojectid       in     gal_project.gal_project_id%type
  , asnapshotdate    in     gal_snapshot.sna_date%type
  , acomment         in     gal_snapshot.sna_comment%type
  , aidentifier      in     gal_snapshot.sna_identifier%type
  , afinancialorigin in     gal_snapshot.sna_financial_origin%type default 0
  , aclearsource     in     number default 0
  , aonline          in     number default 0
  , aSpendingType    in     gal_snapshot.C_GAL_SPENDING_TYPE%type default null
  , ivGaugeType      in     varchar2 default 'ORDER'
  )
  is
    type ttblsnapshot is table of gal_spending_consolidated%rowtype
      index by pls_integer;

    cursor vcursnapshot(acrprojectid gal_project.gal_project_id%type)
    is
      select *
        from gal_spending_consolidated
       where gal_project_id = acrprojectid
         and gal_snapshot_id = 0;

    vtblsnapshot ttblsnapshot;
  begin
    -- création de l'entête
    asnapshotid  := createsnapshotheader(aprojectid, asnapshotdate, acomment, aidentifier, afinancialorigin, aonline, aSpendingType, ivGaugeType);

    if asnapshotid is not null then
      open vcursnapshot(aprojectid);

      loop
        fetch vcursnapshot
        bulk collect into vtblsnapshot limit cbulksize;

        exit when vtblsnapshot.count = 0;

        for i in vtblsnapshot.first .. vtblsnapshot.last loop
          -- création des détails
          insert into gal_snap_spend_consolidated
                      (gal_snap_spend_consolidated_id
                     , gal_snapshot_id
                     , gal_project_id
                     , gal_budget_id
                     , gal_cost_center_id
                     , gal_budget_period_id
                     , gsp_budget_quantity
                     , gsp_budget_amount
                     , gsp_col1_quantity
                     , gsp_col1_amount
                     , gsp_col2_quantity
                     , gsp_col2_amount
                     , gsp_col3_quantity
                     , gsp_col3_amount
                     , gsp_col4_quantity
                     , gsp_col4_amount
                     , gsp_col5_quantity
                     , gsp_col5_amount
                     , gsp_total_quantity
                     , gsp_total_amount
                     , gsp_remaining_quantity
                     , gsp_remaining_amount
                     , gsp_margin_quantity
                     , gsp_margin_amount
                     , gsp_perc_margin_quantity
                     , gsp_perc_margin_amount
                     , gsp_estimation_total_quantity
                     , gsp_estimation_total_amount
                     , a_datecre
                     , a_idcre
                      )
               values (vtblsnapshot(i).gal_spending_consolidated_id   -- reuse this unique number
                     , asnapshotid
                     , vtblsnapshot(i).gal_project_id
                     , vtblsnapshot(i).gal_budget_id
                     , vtblsnapshot(i).gal_cost_center_id
                     , decode(nvl(vtblsnapshot(i).gal_budget_period_id, 0), 0, null, vtblsnapshot(i).gal_budget_period_id)
                     , vtblsnapshot(i).gsp_budget_quantity
                     , vtblsnapshot(i).gsp_budget_amount
                     , vtblsnapshot(i).gsp_col1_quantity
                     , vtblsnapshot(i).gsp_col1_amount
                     , vtblsnapshot(i).gsp_col2_quantity
                     , vtblsnapshot(i).gsp_col2_amount
                     , vtblsnapshot(i).gsp_col3_quantity
                     , vtblsnapshot(i).gsp_col3_amount
                     , vtblsnapshot(i).gsp_col4_quantity
                     , vtblsnapshot(i).gsp_col4_amount
                     , vtblsnapshot(i).gsp_col5_quantity
                     , vtblsnapshot(i).gsp_col5_amount
                     , vtblsnapshot(i).gsp_total_quantity
                     , vtblsnapshot(i).gsp_total_amount
                     , vtblsnapshot(i).gsp_remaining_quantity
                     , vtblsnapshot(i).gsp_remaining_amount
                     , vtblsnapshot(i).gsp_margin_quantity
                     , vtblsnapshot(i).gsp_margin_amount
                     , vtblsnapshot(i).gsp_perc_margin_quantity
                     , vtblsnapshot(i).gsp_perc_margin_amount
                     , vtblsnapshot(i).gsp_estimation_total_quantity
                     , vtblsnapshot(i).gsp_estimation_total_amount
                     , vtblsnapshot(i).a_datecre
                     , vtblsnapshot(i).a_idcre
                      );
        end loop;
      end loop;

      close vcursnapshot;
    end if;
  end createsnapshot;

  /**
  * Description
  *    Chargement des données de la table de photos à date dans la table d'analyse
  */
  procedure loadsnapshot(asnapshotid in gal_snapshot.gal_snapshot_id%type)
  is
    vtplsnapshot  gal_snapshot%rowtype;
    vrecordidlist ID_TABLE_TYPE;
  begin
    -- id de l'affaire lièe à la photo
    select *
      into vtplsnapshot
      from gal_snapshot
     where gal_snapshot_id = asnapshotid;

    -- preventive cleaning ML 19/07 passer GAL_PROJECT_ID pour supp que les données de cette affaire (cas de pilotage multi affaire)
    if instr(pcs.PC_I_LIB_SESSION.getobjectname(), 'SNAPSHOT_COMPARE') > 0 then
      v_number_snapshot  := v_number_snapshot + 1;
    end if;

    purgeworktables(false);
    -- recherche de la liste des dossiers liés
    vrecordidlist  := GAL_LIB_PROJECT.GetRecordList(iProjectID => vtplsnapshot.GAL_PROJECT_ID, iIncludeProjectRecord => 0);
    --IF vrecordidlist IS NOT NULL --hmo 27.3.2011 -> enlever car les bzudgets e réserve ne sont pas de doc_reord -> donc si que budget de rélserve les busgets ne sont pas affichés
    --THEN
    -- Création des dépenses détaillées
    gal_spending_detail_create(vtplsnapshot.gal_project_id, vrecordidlist, vtplsnapshot.sna_date, vtplsnapshot.gal_snapshot_id, 0, -1, null, null, null);   ----CTRLHMO 06.2012

    --END IF;

    -- data transfert
    insert into gal_spending_consolidated
                (gal_spending_consolidated_id
               , gal_snapshot_id
               , gal_project_id
               , gal_budget_id
               , gal_cost_center_id
               , gal_budget_period_id
               , gsp_budget_quantity
               , gsp_budget_amount
               , gsp_col1_quantity
               , gsp_col1_amount
               , gsp_col2_quantity
               , gsp_col2_amount
               , gsp_col3_quantity
               , gsp_col3_amount
               , gsp_col4_quantity
               , gsp_col4_amount
               , gsp_col5_quantity
               , gsp_col5_amount
               , gsp_total_quantity
               , gsp_total_amount
               , gsp_remaining_quantity
               , gsp_remaining_amount
               , gsp_margin_quantity
               , gsp_margin_amount
               , gsp_perc_margin_quantity
               , gsp_perc_margin_amount
               , gsp_estimation_total_quantity
               , gsp_estimation_total_amount
               , a_datecre
               , a_idcre
                )
      select gal_snap_spend_consolidated_id   -- reuse this unique ID
           , gal_snapshot_id
           , gal_project_id
           , gal_budget_id
           , gal_cost_center_id
           , nvl(gal_budget_period_id, 0)
           , gsp_budget_quantity
           , gsp_budget_amount
           , gsp_col1_quantity
           , gsp_col1_amount
           , gsp_col2_quantity
           , gsp_col2_amount
           , gsp_col3_quantity
           , gsp_col3_amount
           , gsp_col4_quantity
           , gsp_col4_amount
           , gsp_col5_quantity
           , gsp_col5_amount
           , gsp_total_quantity
           , gsp_total_amount
           , gsp_remaining_quantity
           , gsp_remaining_amount
           , gsp_margin_quantity
           , gsp_margin_amount
           , gsp_perc_margin_quantity
           , gsp_perc_margin_amount
           , gsp_estimation_total_quantity
           , gsp_estimation_total_amount
           , a_datecre
           , a_idcre
        from gal_snap_spend_consolidated
       where gal_snapshot_id = asnapshotid;
  exception
    when others then
      -- place to log informations
      raise;
  end loadsnapshot;

  /**
  * Description
  *    Suppression d'une photo à date
  */
  procedure deletesnapshot(asnapshotid in gal_snapshot.gal_snapshot_id%type)
  is
  begin
    delete from gal_snap_spend_consolidated
          where gal_snapshot_id = asnapshotid;

    delete from gal_snapshot
          where gal_snapshot_id = asnapshotid;
  exception
    when others then
      -- place to log informations
      raise;
  end deletesnapshot;

  /**
  * Description
  *    Vérifie si la photo à date correspond bien aux données actuelles
  *    à la date de la photo
  */
  function validatesnapshot(asnapshotid in gal_snapshot.gal_snapshot_id%type)
    return number
  is
    vresult         number(1);
    vnbdiff         pls_integer;
    vtplgalsnapshot gal_snapshot%rowtype;
  begin
    select *
      into vtplgalsnapshot
      from gal_snapshot
     where gal_snapshot_id = asnapshotid;

    -- génération de l'interro à date, à la même date que la photo
    gal_spending_generate(agalprojectid => vtplgalsnapshot.gal_project_id, asnapshotdate => vtplgalsnapshot.sna_date, asnapshotid => 3, asnap_type_date => -1);

    -- REVOIR HMO
    -- nombre d'enregistrements différents
    select count(*)
      into vnbdiff
      from (select gal_project_id
                 , gal_budget_id
                 , gal_cost_center_id
                 , gsp_budget_quantity
                 , gsp_budget_amount
                 , gsp_col1_quantity
                 , gsp_col1_amount
                 , gsp_col2_quantity
                 , gsp_col2_amount
                 , gsp_col3_quantity
                 , gsp_col3_amount
                 , gsp_col4_quantity
                 , gsp_col4_amount
                 , gsp_col5_quantity
                 , gsp_col5_amount
                 , gsp_total_quantity
                 , gsp_total_amount
                 , gsp_remaining_quantity
                 , gsp_remaining_amount
                 , gsp_margin_amount
                 , gsp_margin_quantity
                 , gsp_perc_margin_amount
                 , gsp_perc_margin_quantity
                 , gsp_estimation_total_quantity
                 , gsp_estimation_total_amount
              from gal_snap_spend_consolidated
             where gal_snapshot_id = asnapshotid
            minus
            select gal_project_id
                 , gal_budget_id
                 , gal_cost_center_id
                 , gsp_budget_quantity
                 , gsp_budget_amount
                 , gsp_col1_quantity
                 , gsp_col1_amount
                 , gsp_col2_quantity
                 , gsp_col2_amount
                 , gsp_col3_quantity
                 , gsp_col3_amount
                 , gsp_col4_quantity
                 , gsp_col4_amount
                 , gsp_col5_quantity
                 , gsp_col5_amount
                 , gsp_total_quantity
                 , gsp_total_amount
                 , gsp_remaining_quantity
                 , gsp_remaining_amount
                 , gsp_margin_amount
                 , gsp_margin_quantity
                 , gsp_perc_margin_amount
                 , gsp_perc_margin_quantity
                 , gsp_estimation_total_quantity
                 , gsp_estimation_total_amount
              from gal_spending_consolidated
             where gal_snapshot_id = 3
            union
            select gal_project_id
                 , gal_budget_id
                 , gal_cost_center_id
                 , gsp_budget_quantity
                 , gsp_budget_amount
                 , gsp_col1_quantity
                 , gsp_col1_amount
                 , gsp_col2_quantity
                 , gsp_col2_amount
                 , gsp_col3_quantity
                 , gsp_col3_amount
                 , gsp_col4_quantity
                 , gsp_col4_amount
                 , gsp_col5_quantity
                 , gsp_col5_amount
                 , gsp_total_quantity
                 , gsp_total_amount
                 , gsp_remaining_quantity
                 , gsp_remaining_amount
                 , gsp_margin_amount
                 , gsp_margin_quantity
                 , gsp_perc_margin_amount
                 , gsp_perc_margin_quantity
                 , gsp_estimation_total_quantity
                 , gsp_estimation_total_amount
              from gal_spending_consolidated
             where gal_snapshot_id = 3
            minus
            select gal_project_id
                 , gal_budget_id
                 , gal_cost_center_id
                 , gsp_budget_quantity
                 , gsp_budget_amount
                 , gsp_col1_quantity
                 , gsp_col1_amount
                 , gsp_col2_quantity
                 , gsp_col2_amount
                 , gsp_col3_quantity
                 , gsp_col3_amount
                 , gsp_col4_quantity
                 , gsp_col4_amount
                 , gsp_col5_quantity
                 , gsp_col5_amount
                 , gsp_total_quantity
                 , gsp_total_amount
                 , gsp_remaining_quantity
                 , gsp_remaining_amount
                 , gsp_margin_amount
                 , gsp_margin_quantity
                 , gsp_perc_margin_amount
                 , gsp_perc_margin_quantity
                 , gsp_estimation_total_quantity
                 , gsp_estimation_total_amount
              from gal_snap_spend_consolidated
             where gal_snapshot_id = asnapshotid);

    if vnbdiff > 0 then
      vresult  := 0;
    else
      -- si aucune différence, retourne 1 -> OK
      vresult  := 1;
    end if;

    return vresult;
  exception
    when no_data_found then
      raise_application_error(-20000
                            , pcs.pc_functions.translateword('PCS - Photo à date inexistante!') ||
                              chr(13) ||
                              sqlerrm ||
                              chr(13) ||
                              DBMS_UTILITY.format_error_backtrace
                             );
    when others then
      raise;
  end validatesnapshot;

  /**
  * Description
  *    Vérifie si la photo à date correspond bien aux données actuelles
  *    à la date de la photo
  */
  procedure validatesnapshot(asnapshotid in gal_snapshot.gal_snapshot_id%type, areturnvalue out number)
  is
  begin
    areturnvalue  := validatesnapshot(asnapshotid);
  end validatesnapshot;

  procedure gal_project_valuation_with_sel(
    asqlgalproject        varchar2
  , asnapshotdate         date default null
  , aconfigreqsel         number default 0
  , asnap_type_date       number default -1
  , iIncludeProjectRecord integer default 0
  )
  is
    vcrgalproject type_cursor;
    vgalprojectid gal_project.gal_project_id%type;
  begin
    if asqlgalproject is not null then
      purgeworktables(true);

      open vcrgalproject for asqlgalproject;

      loop
        fetch vcrgalproject
         into vgalprojectid;

        exit when vcrgalproject%notfound;
        -- 1er appel de la procédure pour calcul des montants à la DATE DU JOUR (besoin du GSP_TOTAL_AMOUNT à date du jour)
        gal_spending_generate(agalprojectid           => vgalprojectid
                            , agalbudgetid            => 0
                            , agaltaskid              => 0
                            , asnapshotdate           => null
                            , asnapshotid             => 0
                            , apurgeworktable         => 0
                            , aconfigreqsel           => 0
                            , asnap_type_date         => asnap_type_date
                            , iIncludeProjectRecord   => iIncludeProjectRecord
                             );

        -- gal_snapshot_id = 1 pour repérage des données à DATE DU JOUR ************************************************************
        update gal_spending_detail
           set gal_snapshot_id = 1
         where gal_project_id = vgalprojectid;

        update gal_spending_consolidated
           set gal_snapshot_id = 1
         where gal_project_id = vgalprojectid;

        -- gal_snapshot_id = 0 pour repérage des données à DATE CHOISIE ************************************************************
        gal_spending_generate(agalprojectid           => vgalprojectid
                            , agalbudgetid            => 0
                            , agaltaskid              => 0
                            , asnapshotdate           => asnapshotdate
                            , asnapshotid             => 0
                            , apurgeworktable         => 0
                            , aconfigreqsel           => aconfigreqsel
                            , asnap_type_date         => asnap_type_date
                            , atreateafaire           => true
                            , iIncludeProjectRecord   => iIncludeProjectRecord
                             );
      end loop;

      close vcrgalproject;
    end if;
  end gal_project_valuation_with_sel;
begin
  v_number_snapshot  := 0;
end gal_project_consolidation;
