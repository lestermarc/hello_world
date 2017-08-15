--------------------------------------------------------
--  DDL for Package Body GAL_PROJECT_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PROJECT_CALCULATION" 
is
  /*
  xx/xx/xx LSE test plsql: exec pcs.PC_I_LIB_SESSION.InitSession('DEVELOP','LSEYSSEL');
  06/01/06 CMI Modif de la méthode de recherche des documents "Besoin affaire" existants
           --> Test sur le dossier impératif pour éliminer le pb des n° de tâche "similaires"
           --> Exemple: pour la tâche n° CB, on trouvait le document de la tâche n° CBA
  06/01/06 CMI Le dispo est donné via les documents + les mvts hors-document
  09/01/06 CMI Le dispo est aussi donné via les OF (FAL_LOT)
  23/01/06 CMI Dans les mvts hors-documents, on prend aussi les mvts sur le stock affaire
               RAZ des variables (notamment v_lien_pseudo) au changement de tâche et task_good
  MLE 09/06/2015 Ajout PROC AFTER CBA
  CHMI 17/06/2015 Ajout PROC BEFORE CBA
  CHMI 01/07/2015 Ajout procs BEFORE CBA et AFTER CBA dans le calcul de besoins des DF (procédure LAUNCH_PROJECT_MANUFACTURE)
  */
  x_sessionid                    number;
  x_aff_id                       gal_project.gal_project_id%type;
  v_taches_art_id                gal_task_good.gco_good_id%type;
  v_taches_quantite              gal_task_good.gml_quantity%type;
  v_taches_tac_id                gal_task_good.gal_task_id%type;
  v_demaff_dem_id                gal_task_good.gal_task_good_id%type;
  v_taches_aff_id                gal_task.gal_project_id%type;
  v_taches_date_fin              gal_task.tas_end_date%type;
  v_bud_id                       gal_task.gal_budget_id%type;
  v_compose                      pps_nomenclature.gco_good_id%type;
  v_composant                    pps_nomenclature.gco_good_id%type;
  v_qt_lien                      pps_nom_bond.com_util_coeff%type;
  v_del_ajust                    pps_nom_bond.com_interval%type;
  v_compose_del_obt              v_gal_pcs_good.ggo_obtaining_delay%type;
  v_lien_descriptif              pps_nom_bond.c_type_com%type;
  v_lien_pseudo                  pps_nom_bond.c_kind_com%type;
  v_lien_texte                   pps_nom_bond.c_type_com%type;
  v_flag_lien_desc               pps_nom_bond.c_type_com%type;
  v_repartition                  pps_nom_bond.c_kind_com%type;
  v_type_gestion                 pps_nom_bond.c_type_com%type;
  v_nivo                         number;
  v_flag_nivo                    number;
  v_cpt                          number;
  v_dbms                         varchar2(2000);
  v_branche_desc                 char(1);
  v_flag_nivo_desc               number;
  v_flag_maj_qte                 char(1);
  v_flag_maj_qte_need            char(1);
  v_unite_stock                  v_gal_pcs_good.ggo_unit_of_measure%type;
  v_branche_stock                char(1);
  v_flag_nivo_gestion_stock      number;
  v_branche_of                   char(1);
  v_flag_nivo_of                 number;
  v_branche_da                   char(1);
  v_flag_nivo_da                 number;
  v_date_besoin_net              gal_project_need.pjn_need_date%type;
  v_besoin_net                   number;   --QTE A LANCER
  v_flag_simulation              char(1)                                           := 'N';
  v_level                        number                                            := 0;
  v_sui_codart                   v_gal_pcs_good.ggo_major_reference%type;
  v_sui_libart                   v_gal_pcs_good.ggo_short_description%type;
  v_sui_long_descr               v_gal_pcs_good.ggo_long_description%type;
  v_sui_plan                     v_gal_pcs_good.ggo_plan_number%type;
  v_sui_un_st                    v_gal_pcs_good.ggo_unit_of_measure%type;
  v_sui_description              v_gal_pcs_good.ggo_description%type;
  v_sui_repere                   varchar2(30);
  v_situ                         varchar2(30);
  v_couleur                      varchar2(30);
  v_tri                          varchar2(3);
  v_besoin_a_induire             number;
  v_besoin_a_induire_tot         number;
  v_besoin_brut                  number;
  v_besoin_tot                   number;
  x_trace                        char(1);
  v_ress_art_dispo               number;
  v_ress_raf_date_dispo          date;
  v_ress_manufacture_task_id     number;
  v_qt_utilisee_appro            number;
  v_qt_utilisee_dispo            number;
  v_composant_del_obt            number;
  v_ress_art                     number;
  v_ress_raf_id                  number;
  v_ress_oac_id                  number;
  v_ress_cfo_id                  number;
  v_ress_doc_doc_id              number;
  v_ress_aoa_id                  number;
  v_ress_aof_id                  number;
  v_ress_pjr_number              gal_project_resource.pjr_number%type;
  v_qt_util_sur_ress             number;
  v_ress_comment                 varchar2(2000);
  v_ress_of                      number;
  v_ress_raf_date                gal_project_resource.pjr_date%type;
  v_ress_start_date              gal_project_resource.pjr_minimum_need_date%type;
  v_max_date_prevue              date;
  v_id                           number;
  v_task_good_id                 gal_task_good.gal_task_good_id%type;
  v_dispo_stk                    number;
  pps                            pps_nomenclature.pps_nomenclature_id%type;
  v_com_seq                      pps_nom_bond.com_seq%type;
  v_task_doc_record_id           gal_task.doc_record_id%type;
  v_task_no_tache                gal_task.tas_code%type;
  v_task_no_affaire              gal_project.prj_code%type;
  v_task_aff_id                  gal_task.gal_project_id%type;
  outdocumentid                  doc_document.doc_document_id%type;
  outpositionid                  doc_position.doc_position_id%type;
  astockid                       doc_position.stm_stock_id%type;
  alocationid                    doc_position.stm_location_id%type;
  v_task_tac_id                  gal_task.gal_task_id%type;
  v_gauge_id                     doc_gauge.doc_gauge_id%type                       := null;
  v_gml_sequence                 GAL_TASK_GOOD.GML_SEQUENCE%type;
  v_pps_nom_bond_id              PPS_NOM_BOND.PPS_NOM_BOND_ID%type;
  v_pps_nomenclature_id          PPS_NOM_BOND.PPS_NOMENCLATURE_ID%type;
  v_pps_pps_nomenclature_id      PPS_NOM_BOND.PPS_PPS_NOMENCLATURE_ID%type;
  v_pps_path                     varchar2(4000);
  V_SUPPLY_TYPE                  V_GAL_PCS_GOOD.GGO_SUPPLY_TYPE%type;
  V_SUPPLY_MODE                  V_GAL_PCS_GOOD.GGO_SUPPLY_MODE%type;
  v_force_appro                  char(1);
  v_manufacturing_mode           number;
  v_task_cta_id                  gal_task.gal_task_category_id%type;
  V_DOC_GAUGE_NUMBERING_ID       DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  V_GAL_PROC_INIT_LOC_STK        varchar2(255);
  v_GAL_PROC_INIT_QTE_STK_ENT    varchar2(255);
  v_GAL_PROC_INIT_QTE_STK_NET    varchar2(255);
  V_GAL_PROC_LOAD_RESOURCES      varchar2(255);
  v_GCO_DefltSTOCK_not_PROJECT   STM_STOCK.STM_STOCK_ID%type;
  v_GCO_DefltLOC_not_PROJECT     STM_STOCK.STM_STOCK_ID%type;
  v_pdt_stk_dflt                 GCO_PRODUCT.STM_STOCK_ID%type;
  v_stm_stock_id_project         stm_stock.stm_stock_id%type;
  v_stm_location_id_project      stm_stock.stm_stock_id%type;
  v_date1_df                     GAL_TASK.TAS_START_DATE%type;
  v_date2_df                     GAL_TASK.TAS_END_DATE%type;
  v_exist_of                     char(1);
  v_qte_a_deduire_of             number;
  v_besoin_stock_df              number;
  v_Type_Supply_To_Generate_DF   integer;
  v_Type_Supply_To_Generate_TA   integer;
  v_branche_df                   char(1);   --Défini si le composant fait partie d'une branche gérée sur DF
  v_compose_df                   char(1);
  v_on_df                        char(1);   --Défini si le compose fabrique est géré sur DF
  v_branche_df_launch            char(1);
  v_is_read_from_df              char(1);
  V_GAL_GAUGE_NEED_PROJECT       DOC_GAUGE.DOC_GAUGE_ID%type;
  v_GAL_GAUGE_SUPPLY_MANUFACTURE DOC_GAUGE.DOC_GAUGE_ID%type;
  V_GAL_GAUGE_SUPPLY_REQUEST     DOC_GAUGE.DOC_GAUGE_ID%type;
  V_GAL_GAUGE_NEED_MANUFACTURE   DOC_GAUGE.DOC_GAUGE_ID%type;
  V_GAL_GAUGE_DELIVERY_ORDER     DOC_GAUGE.DOC_GAUGE_ID%type;
  V_GAL_GAUGE_OUTPUT_PROJECT     DOC_GAUGE.DOC_GAUGE_ID%type;
  V_GAL_GAUGE_OUTPUT_MANUFACTURE DOC_GAUGE.DOC_GAUGE_ID%type;
  V_GAL_GAUGE_ENTRY_MANUFACTURE  DOC_GAUGE.DOC_GAUGE_ID%type;
  v_cum_qt_util_sur_ress         number;
  v_task_good_df                 char(1);
  V_POS_QTY_TO_UPDATE            number;
  v_assemblee                    char(1);
  v_branche_assemblee            char(1);
  v_task_good_assemblee          char(1);
  v_from_cse_df                  char(1);
  v_manquant_need                char(1);
  v_list_df_use                  varchar2(4000);
  v_ress_gauge_id                DOC_GAUGE.DOC_GAUGE_ID%type;
  v_force_to_launch_status       char(1);
  v_force_to_launch_qty          number;
  v_nfu_supply_mode              GAL_NEED_FOLLOW_UP.NFU_SUPPLY_MODE%type;
  v_csant_del_manuf              number;
  v_csant_del_supl               number;
  v_cse_del_manuf                number;
  v_cse_del_supl                 number;
  v_del_manuf                    number;
  v_del_supl                     number;
  v_header_repart                pps_nom_bond.c_kind_com%type;
  v_delai_obt                    number;
  v_flag_new_df                  varchar2(1);
  v_cpt_doc                      number;
  v_list_doc                     varchar2(32000);
  v_flag_doc                     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  v_upd_task_status              varchar2(1);
  vdocid                         doc_document.doc_document_id%type;
  verrormsg                      varchar2(4000);
  vprjcode                       gal_project.prj_code%type;
  vtascode                       gal_task.tas_code%type;
  vdocnumber                     doc_document.dmt_number%type;
  vprojectid                     gal_task.gal_project_id%type;
  vrecordid                      gal_task.doc_record_id%type;
  aGaugeNumberingID              DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  sqlStatement                   varchar2(2000);
  v_qte_besoin_net_need          number;
  v_pseudo_text                  varchar2(4000);
  v_calc_df                      integer;
  v_planif_df                    integer;
  acalendarID                    number;

  --TABLEAU DE TRAVAIL
  type lign_niveau is record(
    tache_id            gal_project_need.gal_good_id%type
  , article_id          gal_project_need.gal_good_id%type
  , qte_besoin_net      gal_project_need.pjn_quantity%type
  , qte_a_induire       gal_project_need.pjn_quantity%type
  , qte_a_induire_tot   gal_project_need.pjn_quantity%type
  , qte_besoin_brut     gal_project_need.pjn_quantity%type
  , qte_besoin_net_need gal_project_need.pjn_quantity%type
  , qte_a_deduire_of    gal_project_need.pjn_quantity%type
  , del_besoin_net      number
  , del_besoin_sup      number
  , del_besoin_man      number
  , repartition         pps_nom_bond.c_kind_com%type
  , type_gestion        pps_nom_bond.c_type_com%type
  , dat_besoin_net      gal_project_need.pjn_need_date%type
  , lien_pseudo         pps_nom_bond.c_kind_com%type
  , doc_record_id       doc_record.doc_record_id%type
  , on_df               char(1)
  , branche_df          char(1)
  , assemblee           char(1)
  , df_to_use_for_csant varchar2(4000)   --liste des df utilisés comme appro par le compose (les composant doivent avoir la meme ressource)
  );

  type type_niveau is table of lign_niveau
    index by binary_integer;

  tableau_niveau                 type_niveau;

  --TABLEAU FINAL
  type lign_niveau_final is record(
    tache_id              gal_project_need.gal_good_id%type
  , article_id            gal_project_need.gal_good_id%type
  , qte_besoin_net        gal_project_need.pjn_quantity%type
  , qte_besoin_brut       gal_project_need.pjn_quantity%type
  , del_besoin_net        number
  , del_besoin_sup        number
  , del_besoin_man        number
  , dat_besoin_net        gal_project_need.pjn_need_date%type
  , ggo_supply_type       v_gal_pcs_good.ggo_supply_type%type
  , ggo_supply_mode       v_gal_pcs_good.ggo_supply_mode%type
  , ggo_unit_of_measure   v_gal_pcs_good.ggo_unit_of_measure%type
  , branche_of            varchar2(1)
  , branche_da            varchar2(1)
  , branche_df            varchar2(1)
  , branche_assemblee     varchar2(1)
  , compose_df            varchar2(1)
  , branche_df_launch     varchar2(1)
  , force_appro           varchar2(1)
  , lien_pseudo           pps_nom_bond.c_kind_com%type
  , doc_record_id         doc_record.doc_record_id%type
  , affaire_id            gal_project.gal_project_id%type
  , tac_cat_id            gal_task.gal_task_category_id%type
  , bud_id                gal_task.gal_budget_id%type
  , gsm_nom_path          gal_project_supply_mode.gsm_nom_path%type
  , task_good_id          gal_project_supply_mode.gal_task_good_id%type
  , pps_nom_header        gal_project_supply_mode.pps_nomenclature_header_id%type
  , pps_nomenclature_id   pps_nomenclature.pps_nomenclature_id%type
  , qte_besoin_net_need   gal_project_need.pjn_quantity%type
  , gco_short_description v_gal_pcs_good.ggo_short_description%type
  , gco_long_description  v_gal_pcs_good.ggo_description%type
  , df_to_use_for_csant   varchar2(4000)   --liste des df utilisés comme appro par le compose (les composant doivent avoir la meme ressource)
  );

  type type_niveau_final is table of lign_niveau_final
    index by binary_integer;

  tableau_niveau_final           type_niveau_final;

  --TABLEAU STOCK DISPO PCS
  type lign_stock is record(
    article_id gal_project_need.gal_good_id%type
  , qte        gal_project_need.pjn_quantity%type
  , dat        gal_project_need.pjn_need_date%type
  );

  type type_qte_stock is table of lign_stock
    index by binary_integer;

  tableau_stock                  type_qte_stock;

  --TABLEAU DOC_DOCUMENT TO FINALIZE
  type lign_docid is record(
    Docid doc_document.doc_document_id%type
  );

  type type_docid is table of lign_docid
    index by binary_integer;

  tableau_document               type_docid;

  cursor c_pps_nomen
  is
    select     v_taches_art_id
             ,   --Cse principal
               --(select gco_good_id from pps_nomenclature where pps_nomenclature_id = pps_nom_bond.pps_nomenclature_id),
               gco_good_id
             ,   --csant
               com_util_coeff
             , nvl(com_interval, 0)
             , level
             , decode(c_kind_com, '2', 'O'   --Dérivé --> Texte
                                          , '4', 'O', decode(c_type_com, '1', 'N', 'O')   --lien texte = oui
                                                                                       )
             , decode(c_kind_com, '3', 'O', 'N')
             ,   --lien pseudo = oui
               decode(c_kind_com, '5', 'O', 'N')
             ,   --lien texte
               nvl(trim(substr(COM_MARK_TOPO, 1, 30) ), COM_POS)
             , com_seq
             , pps_nom_bond_id
             , pps_nomenclature_id
             , pps_pps_nomenclature_id
             , sys_connect_by_path(com_seq || '-' || gco_good_id, '/')
          from pps_nom_bond
    --WHERE
    --c_type_com not in ('2','3') AND
    --c_kind_com <> '2' --and 1=2
    start with pps_nomenclature_id = pps
    connect by prior pps_pps_nomenclature_id = pps_nomenclature_id
      order siblings by pps_nomenclature_id
              , com_seq;

--**********************************************************************************************************--
  procedure Init_Config
  is
  begin
    --calendrier par défaut
    acalendarID  := GAL_FUNCTIONS.getdefaultcalendar;

    begin
      select PCS.PC_CONFIG.GETCONFIG('GAL_PROC_INIT_LOC_STK')
        into V_GAL_PROC_INIT_LOC_STK
        from dual;
    exception
      when no_data_found then
        V_GAL_PROC_INIT_LOC_STK  := null;
    end;

    begin
      select PCS.PC_CONFIG.GETCONFIG('GAL_PROC_INIT_QTE_STK_ENT')
        into V_GAL_PROC_INIT_QTE_STK_ENT
        from dual;
    exception
      when no_data_found then
        V_GAL_PROC_INIT_QTE_STK_ENT  := null;
    end;

    begin
      select PCS.PC_CONFIG.GETCONFIG('GAL_PROC_INIT_QTE_STK_NET')
        into V_GAL_PROC_INIT_QTE_STK_NET
        from dual;
    exception
      when no_data_found then
        V_GAL_PROC_INIT_QTE_STK_NET  := null;
    end;

    begin
      select PCS.PC_CONFIG.GETCONFIG('GAL_PROC_LOAD_RESOURCES')
        into V_GAL_PROC_LOAD_RESOURCES
        from dual;
    exception
      when no_data_found then
        v_GAL_PROC_LOAD_RESOURCES  := null;
    end;

    begin
      select stm_stock_id
        into v_stm_stock_id_project
        from stm_stock
       where sto_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_PROJECT')
                                  from dual);
    exception
      when no_data_found then
        v_stm_stock_id_project  := null;
    end;

    begin
      select LOC.STM_LOCATION_ID
        into v_stm_location_id_project
        from STM_LOCATION LOC
       where LOC.LOC_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltLOCATION_PROJECT')
                                      from dual)
         and LOC.STM_STOCK_ID = v_stm_stock_id_project;
    exception
      when no_data_found then
        v_stm_location_id_project  := null;
    end;

    begin
      select stm_stock_id
        into V_GCO_DefltSTOCK_not_PROJECT
        from stm_stock
       where sto_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_not_PROJECT')
                                  from dual);
    exception
      when no_data_found then
        v_GCO_DefltSTOCK_not_PROJECT  := null;
    end;

    begin
      select LOC.STM_LOCATION_ID
        into v_GCO_DefltLOC_not_PROJECT
        from STM_LOCATION LOC
       where LOC.LOC_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltLOCATION_not_PROJECT')
                                      from dual)
         and LOC.STM_STOCK_ID = V_GCO_DefltSTOCK_not_PROJECT;
    exception
      when no_data_found then
        v_GCO_DefltLOC_not_PROJECT  := null;
    end;

    begin
      select pcs.pc_config.getconfig('GAL_CALCUL_BOM_SPC_SUPPLY')
        into v_Type_Supply_To_Generate_TA
        from dual;
    exception
      when no_data_found then
        v_Type_Supply_To_Generate_TA  := 0;
    end;

    begin
      select pcs.pc_config.getconfig('GAL_CALCUL_MANUF_SPC_SUPPLY')
        into v_Type_Supply_To_Generate_DF
        from dual;
    exception
      when no_data_found then
        v_Type_Supply_To_Generate_DF  := 0;
    end;

    begin
      select doc_gauge_id
        into V_GAL_GAUGE_NEED_PROJECT
        from doc_gauge
       where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_NEED_PROJECT')
                               from dual);
    exception
      when no_data_found then
        V_GAL_GAUGE_NEED_PROJECT  := null;
    end;

    begin
      select doc_gauge_id
        into v_GAL_GAUGE_SUPPLY_MANUFACTURE
        from doc_gauge
       where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_SUPPLY_MANUFACTURE')
                               from dual);
    exception
      when no_data_found then
        v_GAL_GAUGE_SUPPLY_MANUFACTURE  := null;
    end;

    begin
      select doc_gauge_id
        into V_GAL_GAUGE_SUPPLY_REQUEST
        from doc_gauge
       where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_SUPPLY_REQUEST')
                               from dual);
    exception
      when no_data_found then
        V_GAL_GAUGE_SUPPLY_REQUEST  := null;
    end;

    begin
      select doc_gauge_id
        into V_GAL_GAUGE_NEED_MANUFACTURE
        from doc_gauge
       where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_NEED_MANUFACTURE')
                               from dual);
    exception
      when no_data_found then
        V_GAL_GAUGE_NEED_MANUFACTURE  := null;
    end;

    --BEGIN
    --  SELECT doc_gauge_id INTO V_GAL_GAUGE_DELIVERY_ORDER FROM doc_gauge WHERE gau_describe = (SELECT pcs.pc_config.getconfig ('GAL_GAUGE_DELIVERY_ORDER') FROM DUAL);
    --EXCEPTION WHEN NO_DATA_FOUND THEN V_GAL_GAUGE_DELIVERY_ORDER := NULL; END;
    begin
      select doc_gauge_id
        into V_GAL_GAUGE_OUTPUT_PROJECT
        from doc_gauge
       where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_OUTPUT_PROJECT')
                               from dual);
    exception
      when no_data_found then
        V_GAL_GAUGE_OUTPUT_PROJECT  := null;
    end;

    begin
      select doc_gauge_id
        into V_GAL_GAUGE_OUTPUT_MANUFACTURE
        from doc_gauge
       where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_OUTPUT_MANUFACTURE')
                               from dual);
    exception
      when no_data_found then
        V_GAL_GAUGE_OUTPUT_MANUFACTURE  := null;
    end;

    begin
      select doc_gauge_id
        into V_GAL_GAUGE_ENTRY_MANUFACTURE
        from doc_gauge
       where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_ENTRY_MANUFACTURE')
                               from dual);
    exception
      when no_data_found then
        V_GAL_GAUGE_ENTRY_MANUFACTURE  := null;
    end;
  end Init_Config;

--**********************************************************************************************************--
  procedure INIT_LOCATION_STK_PRODUCT_STOC(aGoodId GCO_GOOD.GCO_GOOD_ID%type, aTaskId GAL_TASK.GAL_TASK_ID%type)
  is
    v_stock_management GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
  begin
    if trim(V_GAL_PROC_INIT_LOC_STK) is null then
      begin
        select STM_STOCK_ID
             , PDT_STOCK_MANAGEMENT
          into v_pdt_stk_dflt
             , v_stock_management
          from GCO_PRODUCT
         where GCO_GOOD_ID = aGoodId;
      exception
        when no_data_found then
          v_pdt_stk_dflt      := null;
          v_stock_management  := null;
      end;

      if v_stock_management = 0 then   --Si produit non gégé en stock...on renvoie le stock virtuel
        begin
          select STM_STOCK_ID
            into v_pdt_stk_dflt
            from STM_STOCK
           where C_ACCESS_METHOD = 'DEFAULT'
             and rownum = 1;

          astockid     := v_pdt_stk_dflt;
          alocationid  := null;
        exception
          when no_data_found then
            astockid     := V_GCO_DefltSTOCK_not_PROJECT;
            alocationid  := V_GCO_DefltLOC_not_PROJECT;
        end;
      else
        if    v_pdt_stk_dflt = v_stm_stock_id_project
           or v_pdt_stk_dflt is null then
          astockid     := V_GCO_DefltSTOCK_not_PROJECT;
          alocationid  := V_GCO_DefltLOC_not_PROJECT;
        else
          astockid  := v_pdt_stk_dflt;

          begin
            select STM_LOCATION_ID
              into alocationid
              from GCO_PRODUCT
             where GCO_GOOD_ID = aGoodId;
          exception
            when no_data_found then
              alocationid  := null;
          end;
        end if;
      end if;
    else
      -- execution de la commande
      sqlStatement  :=
        'BEGIN ' ||
        trim(V_GAL_PROC_INIT_LOC_STK) ||
        '(:aGoodId,:aTaskId,:astockid,:aLocationid,:v_GCO_DefltSTOCK_not_PROJECT,:v_GCO_DefltLOC_not_PROJECT,:v_stm_stock_id_project); END;';

      execute immediate sqlStatement
                  using in     aGoodId
                      , in     aTaskId
                      , in out astockid
                      , in out aLocationid
                      , in     v_GCO_DefltSTOCK_not_PROJECT
                      , in     v_GCO_DefltLOC_not_PROJECT
                      , in     v_stm_stock_id_project;
    end if;
  end INIT_LOCATION_STK_PRODUCT_STOC;

--**********************************************************************************************************--
  procedure INIT_STATUS_INFO(a_acces varchar2, IsNeedOrSupply varchar2, IsUnderOF varchar2)
  is
  begin
    if v_besoin_net > 0 then
      select pcs.pc_functions.translateword('A lancer')
        into v_situ
        from dual;
    /*
    IF SYSDATE >= v_date_besoin_net
    THEN
       v_couleur := 'ROUGE';
    ELSIF     SYSDATE < v_date_besoin_net
          AND (SYSDATE + NVL (v_composant_del_obt, 0)) > v_date_besoin_net
    THEN
       v_couleur := 'ORANGE';
    ELSIF     SYSDATE < v_date_besoin_net
          AND (SYSDATE + NVL (v_composant_del_obt, 0)) <= v_date_besoin_net
    THEN
       v_couleur := 'VERT';
    ELSE
       v_couleur := ' ';
    END IF;
    */
    end if;

    if v_besoin_net = 0 then
      select pcs.pc_functions.translateword('Appro')
        into v_situ
        from dual;
    /*
    IF SYSDATE >= v_date_besoin_net
    THEN
       v_couleur := 'ROUGE';
    ELSIF     SYSDATE < v_date_besoin_net
          AND v_max_date_prevue > v_date_besoin_net
    THEN
       v_couleur := 'ORANGE';
    ELSIF     v_date_besoin_net > SYSDATE
          AND v_max_date_prevue <= v_date_besoin_net
    THEN
       v_couleur := 'VERT';
    ELSE
       v_couleur := ' ';
    END IF;
    */
    end if;

    if v_qt_utilisee_dispo = v_besoin_brut then
      select pcs.pc_functions.translateword('Dispo')
        into v_situ
        from dual;

      v_couleur  := 'VERT';
    end if;

    if     (   v_type_gestion = 'F'
            or v_lien_pseudo = 'O'
            or v_branche_stock = 'O')
       /* appro sur df --> on a forcé le lecture des ressources pour le 1er niveau sous DF*/
       and (v_branche_df = 'N') then
      v_situ               := ' ';
      v_couleur            := ' ';
      v_qt_utilisee_appro  := 0;
    end if;

    if v_force_to_launch_status = 'O' then
      select pcs.pc_functions.translateword('A lancer')
        into v_situ
        from dual;
    --IF a_acces <> '1' and v_branche_df = 'O' THEN v_situ := v_situ || ' ...'; END IF;
    else
      v_situ  := v_situ;
    end if;

    if v_qte_besoin_net_need > 0 then
      if v_from_cse_df = 'O' then
        v_couleur  := 'V';
      else
        v_couleur  := 'R';
      end if;
    else
      if    (     (   v_type_gestion = 'S'
                   or v_repartition = 'T')
             and (   v_besoin_net > 0
                  or v_manquant_need = 'O')
             and IsUnderOF = 'N')
         or (    v_repartition in('A', 'F')
             and v_manquant_need = 'O')
         or (    v_repartition = 'F'
             and a_acces = 1
             and v_besoin_net > 0
            )   --Pour les composants de DF, la ressource est le need > si manquant, alors Affichage Rouge
             --IF (v_type_gestion = 'S' OR v_repartition IN ('A','F','T')) AND (v_manquant_need = 'O' OR v_besoin_net > 0)
             --IF v_manquant_need = 'N' --AND IsNeedOrSupply = 'S'
      then
        v_couleur  := 'R';
      else
        v_couleur  := 'V';
      end if;
    end if;

    if    v_force_to_launch_qty > 0   --AND v_besoin_net - v_force_to_launch_qty <= 0)
       or v_manquant_need = 'O'   -- AND v_qte_besoin_net_need <= 0 AND v_besoin_net <=0)
                               then
      v_couleur  := v_couleur || 'V';
    else
      v_couleur  := v_couleur || 'N';
    end if;   --Couleur du A lancer (pour les df non lancés)

    update gal_need_follow_up
       set nfu_available_quantity = v_qt_utilisee_dispo
         , nfu_missing_quantity = v_besoin_brut - v_qt_utilisee_dispo
         , nfu_supply_type = decode(v_repartition, 'T', (select pcs.pc_functions.translateword('Assemblé à l''affaire')
                                                           from dual), nfu_supply_type)
         , nfu_info_supply = decode(v_repartition, 'T', ' ', v_situ)
         , nfu_info_color_supply = v_couleur
         , nfu_supply_quantity = decode(v_situ, ' ', 0, (select pcs.pc_functions.translateword('Dispo')
                                                           from dual), 0, v_qt_utilisee_appro - v_force_to_launch_qty)
         , nfu_to_launch_quantity =
             decode(v_situ
                  , ' ', 0
                  , decode(v_repartition
                         , 'T', nfu_net_quantity_need - v_qt_utilisee_dispo - v_qt_utilisee_appro + v_force_to_launch_qty
                         , decode(v_type_gestion
                                , 'F', 0
                                , decode(v_repartition
                                       , 'S', nfu_net_quantity_stk - v_qt_utilisee_dispo - v_qt_utilisee_appro + v_force_to_launch_qty
                                       ,
                                         --> le nfu_net_quantity_stk est le besoin reel cad diminué de qte généré par 1 éventuel OF
                                         nfu_net_quantity_need - v_qt_utilisee_dispo - v_qt_utilisee_appro + v_force_to_launch_qty
                                        )
                                 )
                          )
                   )
     where gal_need_follow_up_id = v_id;
  end INIT_STATUS_INFO;

--************************************************************************************************************************--
--************************************************************************************************************************--
  procedure UpdateGsmAllowUpd(
    aGsmNomPath       gal_project_supply_mode.gsm_nom_path%type default ' '
  , aTaskGoodId       gal_project_supply_mode.gal_task_good_id%type default 0
  , aPpsNomenHeaderId gal_project_supply_mode.pps_nomenclature_header_id%type default 0
  , aAllowUpd         gal_project_supply_mode.gsm_allow_update%type
  )
  is   --Maj stock affaire sur les appros (composants) à l'affaire...
    n_level               number                                               := 0;
    n_cpt                 number                                               := 0;
    n_nom_level           number                                               := 0;
    n_good_id             GCO_GOOD.GCO_GOOD_ID%type;
    n_project_supply_mode GAL_PROJECT_SUPPLY_MODE.C_PROJECT_SUPPLY_MODE%type;

    cursor C_GSM
    is
      select     GSM_NOM_LEVEL
               , GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID
               , C_PROJECT_SUPPLY_MODE
            from GAL_PROJECT_SUPPLY_MODE
           where PPS_NOMENCLATURE_HEADER_ID = aPpsNomenHeaderId
             and GSM_NOM_PATH like trim(aGsmNomPath) || '%'
             and GAL_TASK_GOOD_ID = aTaskGoodId
        order by GAL_TASK_GOOD_ID
               , PPS_NOMENCLATURE_HEADER_ID
               , GSM_NOM_PATH
      for update;
  begin
    n_cpt  := 0;

    open C_GSM;

    loop
      fetch C_GSM
       into n_nom_level
          , n_good_id
          , n_project_supply_mode;

      exit when C_GSM%notfound;

      if n_cpt = 0 then
        n_level  := n_nom_level;

        update GAL_PROJECT_SUPPLY_MODE
           set GSM_ALLOW_UPDATE = aAllowUpd
         where current of C_GSM;
      else
        if n_nom_level = n_level + 1 then
          if n_project_supply_mode in('5') then
            update GAL_PROJECT_SUPPLY_MODE
               set GSM_ALLOW_UPDATE = aAllowUpd
             where current of C_GSM;
          end if;
        end if;

        if n_nom_level <= n_level then
          exit;
        end if;
      end if;

      n_cpt  := n_cpt + 1;
    end loop;

    close C_GSM;
  end UpdateGsmAllowUpd;

  --***********Liste Surplus pour Suivi Mat ***********************************************************--
  procedure INIT_SURPLUS(TacId GAL_TASK.GAL_TASK_ID%type, a_acces varchar2, a_typ varchar2)
  --Acces : 1-Full 0-Sur Nomenclature config
  --Typ : 0-Sur taches 1-sur affaire 2-sur budget de tache
  is
  begin
    insert into gal_resource_follow_up
                (gal_resource_follow_up_id
               , gal_need_follow_up_id
               , rfu_sessionid
               , rfu_type
               , gal_project_id
               , gal_task_id
               , gal_good_id
               , rfu_supply_number
               , rfu_envisaged_date
               , rfu_available_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , rfu_quantity
               ,   --dispo
                 rfu_supply_quantity
               ,   --appro
                 rfu_used_quantity
               , gal_manufacture_task_id
               , rfu_comment
               , rfu_type_need_or_supply
                )
      select gal_resource_follow_up_id_seq.nextval
           , A
           , B
           , C
           , D
           , E
           , F
           , G
           , H
           , I
           , J
           , K
           , L
           , M
           , N
           , O
           , P
           , Q
           , R
           , T
           , S
           , U
        from (select   0 A
                     ,   --pas de besoin car surplus
                       x_sessionid B
                     , decode(pjr_sort
                            , '1ST', '1ST'
                            , '2BA', '2BA'
                            , '3BA', '2BA'
                            , '2CF', '3CF'
                            , '3CF', '3CF'
                            , '2OF', '4OF'
                            , '3OF', '4OF'
                            , '1RB', '4OF'
                            , '4PA', '5PA'
                            , '4PF', '5PF'
                            , '5OA', '6OA'
                            , '6DI', '6DF'
                            , '6DF', '6DF'
                            , '6DA', '6DF'
                            , '6DB', '6DF'
                            , '6AF', '6DF'
                            , '6DG', '6DF'
                            , '6DH', '6DF'
                            , '6AH', '6DF'
                            , '4PB', '6DF'
                            , '   '
                             ) C
                     , x_aff_id D
                     , gal_task_id E
                     , gal_good_id F
                     , pjr_number G
                     , decode(pjr_remaining_quantity, 0, null, pjr_date) H
                     , decode(pjr_available_remaining_quanti, 0, null, pjr_available_date) I
                     , fal_supply_request_id J
                     , doc_position_detail_id K
                     , doc_document_id L
                     , fal_doc_prop_id M
                     , fal_lot_prop_id N
                     , fal_lot_id O
                     , pjr_available_remaining_quanti P
                     , pjr_remaining_quantity Q
                     , pjr_remaining_quantity R
                     , gal_manufacture_task_id T
                     , pjr_comment S
                     , decode(a_typ
                            , '1', 'A'
                            ,   --Affaire
                              '2', 'B'
                            ,   --Budget
                              /*
                              '3',DECODE(PJR_SORT,'6DA',NVL((SELECT '6DA' FROM GAL_TASK_GOOD GTG
                                                             WHERE GTG.GCO_GOOD_ID = gal_good_id
                                                             AND GTG.GAL_TASK_ID = TacId
                                                             AND GTG.C_PROJECT_SUPPLY_MODE =
                                                             AND ROWNUM = 1),'NULL')),--DF
                              */
                              decode(PJR_SORT
                                   , '6DI', 'R'
                                   , '6DG', 'R'
                                   , (select decode(sum(NEED.NFU_TO_LAUNCH_QUANTITY), 0, 'R', 'N')
                                        from GAL_NEED_FOLLOW_UP NEED
                                       where NEED.GCO_GOOD_ID = gal_good_id)   --Taches (R:Surplus N:Hors Mode Appro Original)
                                    )
                             ) U
                  from gal_project_resource
                 where (    (    gal_task_id = TacId
                             and a_typ = '0')
                        or (    a_typ = '1'
                            and gal_task_id = 1)
                        or (    a_typ = '2'
                            and gal_task_id = 2) )
                   and (    (    gal_good_id in(
                                   select GCO_GOOD_ID
                                     from GAL_PROJECT_SUPPLY_MODE GSM
                                    where GSM.GAL_FATHER_TASK_ID = TacId
                                      and GSM.PPS_NOMENCLATURE_HEADER_ID in(select nvl(GTG.PPS_NOMENCLATURE_ID, GTG.GCO_GOOD_ID)
                                                                              from GAL_TASK_GOOD GTG
                                                                             where GTG.GAL_TASK_ID = TacId) )
                             and a_acces = '0'
                            )
                        or a_acces = '1'
                       )
                   and (   pjr_remaining_quantity > 0
                        or pjr_available_remaining_quanti > 0)
                   and pjr_sort <> '1SM'
              order by pjr_sort asc
                     , pjr_number asc);
  --> '1','0'

  --> a_acces VARCHAR2,a_typ VARCHAR2
  end INIT_SURPLUS;

  --***********Liste Surplus pour Calcul Besoins ***********************************************************--
  procedure INIT_SURPLUS_CALC_RESULT(a_tac_id GAL_TASK.GAL_TASK_ID%type, a_type_ress varchar2)
  is
  begin
    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_task_id
               , gal_good_id
               , fal_supply_request_id
               , doc_document_id
               , doc_position_id
               , doc_position_detail_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , gal_manufacture_task_id
               , gal_pcr_qty
               , gal_pcr_remaining_qty
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
      select gal_project_calc_result_id_seq.nextval
           , T
           , A
           , B
           , C
           , D
           , E
           , F
           , G
           , H
           , O
           , I
           , J
           , K
           , L
           , M
           , N
        from (select   gal_task_id T
                     , gal_good_id A
                     , fal_supply_request_id B
                     , doc_document_id C
                     , doc_position_id D
                     , doc_position_detail_id E
                     , fal_doc_prop_id F
                     , fal_lot_prop_id G
                     , fal_lot_id H
                     , gal_manufacture_task_id O
                     , 0 I
                     , decode(pjr_remaining_quantity, 0, pjr_available_remaining_quanti, pjr_remaining_quantity) J
                     , (select pcs.pc_functions.translateword('Surplus')
                          from dual) K
                     , '10' L
                     , PCS.PC_I_LIB_SESSION.GetUserIni M
                     , sysdate N
                  from gal_project_resource
                 where gal_task_id = a_tac_id
                   and gal_good_id in(
                             select GCO_GOOD_ID
                               from GAL_PROJECT_SUPPLY_MODE GSM
                              where GSM.GAL_FATHER_TASK_ID = a_tac_id
                                and GSM.PPS_NOMENCLATURE_HEADER_ID in(select nvl(GTG.PPS_NOMENCLATURE_ID, GTG.GCO_GOOD_ID)
                                                                        from GAL_TASK_GOOD GTG
                                                                       where GTG.GAL_TASK_ID = a_tac_id) )
                   and (    (    pjr_remaining_quantity > 0
                             and PJR_SORT <> a_type_ress)
                        or pjr_available_remaining_quanti > 0)
              order by pjr_sort asc
                     , pjr_number asc);

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_task_id
               , gal_good_id
               , fal_supply_request_id
               , doc_document_id
               , doc_position_id
               , doc_position_detail_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , gal_manufacture_task_id
               , gal_pcr_qty
               , gal_pcr_remaining_qty
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
      select gal_project_calc_result_id_seq.nextval
           , T
           , A
           , B
           , C
           , D
           , E
           , F
           , G
           , H
           , O
           , I
           , J
           , K
           , L
           , M
           , N
        from (select   gal_task_id T
                     , gal_good_id A
                     , fal_supply_request_id B
                     , doc_document_id C
                     , doc_position_id D
                     , doc_position_detail_id E
                     , fal_doc_prop_id F
                     , fal_lot_prop_id G
                     , fal_lot_id H
                     , gal_manufacture_task_id O
                     , 0 I
                     , decode(pjr_remaining_quantity, 0, pjr_available_remaining_quanti, pjr_remaining_quantity) J
                     , (select pcs.pc_functions.translateword('Hors nomenclature')
                          from dual) K
                     , '12' L
                     , PCS.PC_I_LIB_SESSION.GetUserIni M
                     , sysdate N
                  from gal_project_resource
                 where gal_task_id = a_tac_id
                   and gal_good_id not in(
                             select GCO_GOOD_ID
                               from GAL_PROJECT_SUPPLY_MODE GSM
                              where GSM.GAL_FATHER_TASK_ID = a_tac_id
                                and GSM.PPS_NOMENCLATURE_HEADER_ID in(select nvl(GTG.PPS_NOMENCLATURE_ID, GTG.GCO_GOOD_ID)
                                                                        from GAL_TASK_GOOD GTG
                                                                       where GTG.GAL_TASK_ID = a_tac_id) )
                   and (    (    pjr_remaining_quantity > 0
                             and PJR_SORT <> a_type_ress)
                        or pjr_available_remaining_quanti > 0)
              order by pjr_sort asc
                     , pjr_number asc);
  end INIT_SURPLUS_CALC_RESULT;

--*************************************************************************************--
--*************************************************************************************--
  procedure INIT_REMAINING_COMPONANT(a_task_id GAL_TASK.GAL_TASK_ID%type)
  is
  begin
    insert into gal_resource_follow_up
                (gal_resource_follow_up_id
               , gal_need_follow_up_id
               , rfu_sessionid
               , rfu_type
               , gal_project_id
               , gal_task_id
               , gal_good_id
               , rfu_supply_number
               , rfu_envisaged_date
               , rfu_available_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , rfu_quantity
               ,   --dispo
                 rfu_supply_quantity
               ,   --appro
                 rfu_used_quantity
               , gal_manufacture_task_id
               , rfu_comment
               , rfu_type_need_or_supply
                )
      select gal_resource_follow_up_id_seq.nextval
           , A
           , B
           , C
           , D
           , E
           , F
           , G
           , H
           , I
           , J
           , K
           , L
           , M
           , N
           , O
           , P
           , Q
           , R
           , T
           , S
           , 'H'
        from (select   0 A
                     ,   --pas de besoin car surplus
                       x_sessionid B
                     , decode(pjr_sort
                            , '1ST', '1ST'
                            , '2BA', '2BA'
                            , '3BA', '2BA'
                            , '2CF', '3CF'
                            , '3CF', '3CF'
                            , '2OF', '4OF'
                            , '3OF', '4OF'
                            , '1RB', '4OF'
                            , '4PA', '5PA'
                            , '4PF', '5PF'
                            , '5OA', '6OA'
                            , '6DI', '6DF'
                            , '6DF', '6DF'
                            , '6DA', '6DF'
                            , '6DB', '6DF'
                            , '6AF', '6DF'
                            , '6DG', '6DF'
                            , '6DH', '6DF'
                            , '6AH', '6DF'
                            , '4PB', '6DF'
                            , '   '
                             ) C
                     , x_aff_id D
                     , gal_task_id E
                     , gal_good_id F
                     , pjr_number G
                     , decode(pjr_remaining_quantity, 0, null, pjr_date) H
                     , decode(pjr_available_remaining_quanti, 0, null, pjr_available_date) I
                     , fal_supply_request_id J
                     , doc_position_detail_id K
                     , doc_document_id L
                     , fal_doc_prop_id M
                     , fal_lot_prop_id N
                     , fal_lot_id O
                     , pjr_available_remaining_quanti P
                     , pjr_remaining_quantity Q
                     , pjr_remaining_quantity R
                     , gal_manufacture_task_id T
                     , pjr_comment S
                  from gal_project_resource
                 where gal_task_id = a_task_id
                   and (   pjr_remaining_quantity > 0
                        or pjr_available_remaining_quanti > 0)
                   and pjr_sort <> '1SM'
                   and gal_good_id not in(
                            select GCO_GOOD_ID
                              from GAL_PROJECT_SUPPLY_MODE GSM
                             where GSM.GAL_FATHER_TASK_ID = a_task_id
                               and GSM.PPS_NOMENCLATURE_HEADER_ID in(select nvl(GTG.PPS_NOMENCLATURE_ID, GTG.GCO_GOOD_ID)
                                                                       from GAL_TASK_GOOD GTG
                                                                      where GTG.GAL_TASK_ID = a_task_id) )
              order by pjr_sort asc
                     , pjr_number asc);
  end INIT_REMAINING_COMPONANT;

--*************************************************************************************************--
  procedure InitPlanifDateDF
  is
  begin
    update GAL_TASK
       set TAS_START_DATE = nvl(TAS_START_DATE, v_date_besoin_net - v_csant_del_manuf)
         , TAS_END_DATE = nvl(TAS_END_DATE, v_date_besoin_net)
     where GAL_TASK_ID = v_ress_manufacture_task_id;
  end InitPlanifDateDF;

  --******** Elimine les info de sequence dans la path ********************************* ***********--
  function GetPathNoSeq(v_string in varchar2)
    return varchar2 deterministic
  is
    v_inter_string varchar2(32000) := '/';
    init_write     boolean         := true;
    v_test         varchar2(1);
  begin
    v_test  := null;

    for i in 2 .. length(v_string) loop
      select substr(v_string, i, 1)
        into v_test
        from dual;

      if init_write then
        v_inter_string  := v_inter_string || v_test;
      end if;

      if v_test = '/' then
        init_write  := false;
      elsif v_test = '-' then
        init_write  := true;
      end if;
    end loop;

    return v_inter_string;
  --return(v_string);
  end GetPathNoSeq;

  --******** Sous pseudo fabriqué sur Of ou fabriqué sur Of (Bien géré sur stock), on ne gère pas les NEED ***********--
  function GetInfoForStkUnderPOf(aNivo number)
    return varchar2
  is   --Warning : Faire du recursif si plusieurs pseudo!!!
    v_result varchar2(30);
  begin
    v_result  := ' ';

    if aNivo >= 1 then
      if tableau_niveau(aNivo - 1).lien_pseudo = 'O' then   --n-1 est pseudo
        if aNivo >= 2 then
          if tableau_niveau(anivo - 2).qte_a_deduire_of = 0 then
            v_result  := pcs.pc_functions.translateword('A lancer');
          else
            if tableau_niveau(anivo - 2).qte_besoin_net = 0 then
              v_result  := pcs.pc_functions.translateword('Appro');
            else
              v_result  := pcs.pc_functions.translateword('A lancer');
            end if;
          end if;
        else
          v_result  := ' ';
        end if;
      else
        if tableau_niveau(anivo - 1).qte_a_deduire_of = 0 then
          v_result  := pcs.pc_functions.translateword('A lancer');
        else
          if tableau_niveau(anivo - 1).qte_besoin_net = 0 then
            v_result  := pcs.pc_functions.translateword('Appro');
          else
            v_result  := pcs.pc_functions.translateword('A lancer');
          end if;
        end if;
      end if;
    else
      v_result  := ' ';
    end if;

    return(v_result);
  end GetInfoForStkUnderPOf;

  --******** Sous un pseudo fabriqué sur of (Bien géré à l'affaire), on ne gère pas les NEED *********--
  function GetStatusUnderOf(aNivo number)
    return number
  is
    v_result number;
  begin
    v_result  := 0;

    if aNivo >= 2 then
      if (    tableau_niveau(aNivo - 2).repartition = 'F'
          and tableau_niveau(aNivo - 2).type_gestion = 'A'
          and tableau_niveau(aNivo - 2).on_df = 'N'
          and tableau_niveau(aNivo - 1).lien_pseudo = 'O'
         ) then
        v_result  := 1;
      else
        v_result  := 0;
      end if;
    else
      v_result  := 0;
    end if;

    return(v_result);
  end GetStatusUnderOf;

  --******** Sous fabriqué sur of (Bien géré sur stock), on ne gère pas les NEED ***********--
  function GetStatusForStkUnderPOf(aNivo number)
    return number
  is
    v_result number;
  begin
    v_result  := 0;

    if aNivo >= 1 then
      if (    v_type_gestion = 'S'
          and tableau_niveau(anivo - 1).repartition = 'F'
          and tableau_niveau(anivo - 1).type_gestion = 'A'
          and tableau_niveau(anivo - 1).on_df = 'N'
         ) then
        v_result  := 1;
      else
        v_result  := 0;
      end if;
    else
      v_result  := 0;
    end if;

    return(v_result);
  end GetStatusForStkUnderPOf;

  --******** Sous un pseudo fabriqué sur of (Bien géré à l'affaire), on ne gère pas les NEED *********--
  function GetStatusUnderPOf(aNivo number)
    return number
  is
    v_result number;
  begin
    v_result  := 0;

    if aNivo >= 1 then
      if (    tableau_niveau(aNivo - 1).repartition = 'F'
          and tableau_niveau(aNivo - 1).type_gestion = 'A'
          and tableau_niveau(aNivo - 1).on_df = 'N') then
        v_result  := 1;
      else
        v_result  := 0;
      end if;
    else
      v_result  := 0;
    end if;

    return(v_result);
  end GetStatusUnderPOf;

  --******** Sous un pseudo fabriqué sur of (Bien géré sur stock), on ne gère pas les NEED ***********--
  function GetStatusForStkUnderOf(aNivo number)
    return number
  is
    v_result number;
  begin
    v_result  := 0;

    if aNivo >= 2 then
      if (    v_type_gestion = 'S'
          and tableau_niveau(aNivo - 2).repartition = 'F'
          and tableau_niveau(aNivo - 2).type_gestion = 'A'
          and tableau_niveau(aNivo - 2).on_df = 'N'
          and tableau_niveau(aNivo - 1).lien_pseudo = 'O'
         ) then
        v_result  := 1;
      else
        v_result  := 0;
      end if;
    else
      v_result  := 0;
    end if;

    return(v_result);
  end GetStatusForStkUnderOf;

  --********** Pour lecture des Qte Appro et Dispo sur Document Dossier Fab *************--
  --********Permet de ne pas filter les ressources Dossier Fabrication sur l'état < 20 **--
  --********  dans le Load_resource   ***************************************************--
  function GetManufactureDocQty(aTacId gal_task.gal_task_id%type default 0, aGoodid gal_task.gal_task_id%type default 0)
    return number
  is
    v_result number;
  begin
    select sum(RES.pjr_remaining_quantity + RES.pjr_available_remaining_quanti)
      into v_result
      from GAL_PROJECT_RESOURCE RES
     where RES.GAL_TASK_ID = aTacId
       and RES.GAL_GOOD_ID = aGoodId
       and (   RES.doc_gauge_id = v_GAL_GAUGE_SUPPLY_MANUFACTURE
            or RES.doc_gauge_id = V_GAL_GAUGE_ENTRY_MANUFACTURE);

    return(v_result);
  end GetManufactureDocQty;

  --********** Défini si la ressource est sur le bon DF (si géré sur DF) ****************--
  function GetResourceAffectation(a_tac_id gal_task.gal_task_id%type, a_manufacture_task_id gal_task.gal_task_id%type)
    return number
  is
    v_result number;
  begin
    if v_nivo > 1 then
      if tableau_niveau(v_nivo - 1).on_df = 'O' then
        if instr(nvl(tableau_niveau(v_nivo - 1).df_to_use_for_csant, ';' || to_char(a_tac_id) ),(';' || to_char(nvl(a_manufacture_task_id, a_tac_id) ) ), 1, 1) <>
                                                                                                                                                              0 then
          v_result  := 1;
        else
          v_result  := 0;
        end if;
      else
        v_result  := 1;
      end if;
    else
      v_result  := 1;
    end if;

    return(v_result);
  end GetResourceAffectation;

  function GetGoodSupplyMode(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return varchar2 deterministic
  is
    lvSupplyMode GCO_PRODUCT.C_SUPPLY_MODE%type;
  begin
    -- 1.Service -> Mode d'appro = '2' - Produit fabriqué
    -- 2.Pseudo-bien  -> Mode d'appro = '5' (valeur de descode inexistante !!!)
    -- 3.Produit
    --     Si type d'appro = '1' - 'Stock' -> Mode d'appro = '1' - Produit acheté
    --     Sinon Type d'appro = '2' - 'Affaire' Alors
    --       Si Mode d'appro du produit est
    --           '1' - Produit acheté -> '2' - Produit fabriqué
    --           '2' - Produit fabriqué -> '3' - Produit assemblé sur tâche
    --           '3' - Produit assemblé sur tâche -> '4' - Produit acheté sous-traité
    select case
             when SER.GCO_GOOD_ID is not null then '2'
             when PSE.GCO_GOOD_ID is not null then '5'
             when PDT.GCO_GOOD_ID is not null then case nvl(PDT.C_SUPPLY_TYPE, '1')
                                                    when '1' then '1'
                                                    when '2' then case nvl(PDT.C_SUPPLY_MODE, '1')
                                                                   when '1' then '2'
                                                                   when '2' then '3'
                                                                   when '3' then '4'
                                                                   else null
                                                                 end
                                                  end
           end as GOOD_SUPPLY_MODE
      into lvSupplyMode
      from GCO_GOOD GOO
         , GCO_PRODUCT PDT
         , GCO_SERVICE SER
         , GCO_PSEUDO_GOOD PSE
     where GOO.GCO_GOOD_ID = iGoodID
       and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
       and GOO.GCO_GOOD_ID = SER.GCO_GOOD_ID(+)
       and GOO.GCO_GOOD_ID = PSE.GCO_GOOD_ID(+);

    return lvSupplyMode;
  exception
    when no_data_found then
      return null;
  end GetGoodSupplyMode;

  --********** Pour lescture des ressource (filtre lecture des ressources selon mode d'appro) ***--
  function GetResourceType(
    a_pjr_sort     gal_project_resource.PJR_SORT%type
  , a_repartition  V_GAL_PCS_GOOD.GGO_SUPPLY_MODE%type
  , a_type_gestion V_GAL_PCS_GOOD.GGO_SUPPLY_TYPE%type
  , a_branche_df   char
  , a_branche_desc char
  )
    return number deterministic
  is
    v_result number;
  begin
    v_result  := 0;

    --Dans tous les cas les types BA sont retenus (les filtres sont au niveau des config de gabarit besoin/sortie Affaire et Df )
    if a_pjr_sort in('2BA', '3BA') then
      v_result  := 1;
    end if;

    --IF a_pjr_sort IN ('2CF','3CF','4PA','5OA') AND a_repartition = 'A' AND a_type_gestion <> 'S' AND a_branche_df = 'N'
    if     a_pjr_sort in('2CF', '3CF', '4PA', '5OA', '6DA')
       and a_repartition = 'A'
       and a_type_gestion <> 'S'
       and a_branche_df = 'N'
       and a_branche_desc = 'N' then
      v_result  := 1;
    end if;

    if     a_pjr_sort in('6DA', '4PB', '5OA')
       and a_repartition = 'A'
       and a_type_gestion <> 'S'
       and a_branche_df = 'O'
       and a_branche_desc = 'N' then
      v_result  := 1;
    end if;

    /* Acheté
    '2CF' Dispo Commande Fourn
    '3CF' Appro Commadne Fourn
    '4PA' Appro POA
    '4PB' Appro POA sur DF
    '5OA' Appro DA
    '6DA' Appro Doc Demande d'achat

    '2BA' Dispo Doc besoin affaire
    '3BA' Appro Doc besoin affaire
    */

    --POUR LECTURE DES RESSOURCE GAL_TASK_GOOD (requete est débranchée)
    if     a_pjr_sort in('6DG')
       and a_branche_df = 'O'
       and (   a_repartition not in('A', 'F')
            or a_type_gestion = 'S') then
      v_result  := 1;
    end if;

    if v_is_read_from_df = 'N' then
      --IF a_pjr_sort IN ('1RB','2OF','3OF','4PF','5OA','6DI','6DB','6AF') AND a_repartition = 'F' AND a_type_gestion <> 'S'
      if     a_pjr_sort in('1RB', '2OF', '3OF', '4PF', '5OA', '6DI', '6DB', '6AF')
         and a_repartition = 'F'
         and a_type_gestion <> 'S'
         and a_branche_desc = 'N' then
        v_result  := 1;
      end if;   --Lecture depuis suivi mat : lecture des type Appro
    else
      --IF a_pjr_sort IN ('1RB','2OF','3OF','4PF','5OA','6DB','6AF') AND a_repartition = 'F' AND a_type_gestion <> 'S'
      if     a_pjr_sort in('1RB', '2OF', '3OF', '4PF', '5OA', '6DB', '6AF')
         and a_repartition = 'F'
         and a_type_gestion <> 'S'
         and a_branche_desc = 'N' then
        v_result  := 1;
      end if;   --Lecture depuis suivi mat : lecture des type besoin
    end if;

    /* Fabriqué
    '1RB' Rebus Fab
    '2OF' Dispo OF
    '3OF' Appro OF
    '4PF' Appro POF
    '5OA' Appro DA
    '6DI' Appro Doc Dossier fab  non lancé
    '6DB' Appro Doc besoin dossier Fab
    '6AF' Dispo Doc Sortie dossier Fab

    '2BA' Dispo Doc besoin affaire
    '3BA' Appro Doc besoin affaire
    */
    if     a_pjr_sort in('1ST', '1SM')
       and a_branche_desc = 'N' then
      v_result  := 1;
    end if;

    /* Dispo Stock*/
    if     a_pjr_sort in('2BA', '3BA')
       and a_type_gestion = 'S'
       and a_branche_df = 'N'
       and a_branche_desc = 'N' then
      v_result  := 1;
    end if;

    if     a_pjr_sort in('6DB', '6AF')
       and a_type_gestion = 'S'
       and a_branche_df = 'O'
       and a_branche_desc = 'N' then
      v_result  := 1;
    end if;

    /* Géré sur stock
    '2BA' Dispo Doc besoin affaire
    '3BA' Appro Doc besoin affaire
    '6DB' Appro Doc besoin dossier Fab
    '6AF' Dispo Doc Sortie dossier Fab
    */

    /* Assemblé sur tache*/
    --plus de ressources
    --IF a_pjr_sort IN ('2BA','3BA') AND a_repartition = 'T' AND a_branche_df = 'N' AND a_branche_desc = 'N' THEN v_result := 1; END IF;
    --IF a_pjr_sort IN ('6DB','6AF') AND a_repartition = 'T' AND a_branche_df = 'O' AND a_branche_desc = 'N'
    --THEN v_result := 1; END IF;
    return(v_result);
  end GetResourceType;

  --********** Définition du mode d'appro (Plsql / delphi initfield *******************************************--
  function GetDeftSupplyMode(a_supply_type V_GAL_PCS_GOOD.GGO_SUPPLY_TYPE%type, a_supply_mode V_GAL_PCS_GOOD.GGO_SUPPLY_MODE%type)
    return char deterministic
  is
    v_result varchar2(10);
  begin
    begin
      select decode(a_supply_type, 'A', decode(a_supply_mode, 'A', '2', 'T', '4', 'F', '3', '5'), 'S', '1', '5')
        into v_result
        from dual;
    exception
      when no_data_found then
        v_result  := '5';
    end;

    return(v_result);
  end GetDeftSupplyMode;

  --********** Modifiation du delai d'obtention selon le mode d'appro ****************************************--
  procedure GetCseObtainingDelay
  is
  begin
    if v_nivo > 1 then
      if tableau_niveau(v_nivo - 1).repartition = 'F' then
        v_delai_obt  := tableau_niveau(v_nivo - 1).del_besoin_man;
      elsif tableau_niveau(v_nivo - 1).repartition = 'A' then
        v_delai_obt  := tableau_niveau(v_nivo - 1).del_besoin_sup;
      else
        v_delai_obt  := 0;
      end if;
    else   --Niveau 1 : le delai est celui de l'article N-1 = celui de la tache d'appro
      if v_header_repart = 'F' then
        v_delai_obt  := v_del_manuf;
      elsif v_header_repart = 'A' then
        v_delai_obt  := v_del_supl;
      else
        v_delai_obt  := 0;
      end if;
    end if;
  end GetCseObtainingDelay;

  --********** Modifiation des règles d'appro selon GAL_PROJECT_SUPPLY_MODE **********************************--
  procedure SetSupplyMode(a_type_acces char, aGoodID number)
  is
  begin
    if a_type_acces = '0'   --Pour le composant
                         then
      if v_supply_type = ' ' then
        v_lien_descriptif  := 'O';   --si pas approvisionné
      end if;

      v_repartition   := v_supply_mode;
      v_type_gestion  := v_supply_type;

      if     v_supply_mode = 'T'
         and v_supply_type <> 'S' then   --> bug 06/10/2008  ajout filtre <> 'S'
        v_assemblee  := 'O';
      else
        v_assemblee  := 'N';
      end if;

      if     v_supply_mode = 'T'
         and v_supply_type = 'S' then
        v_repartition  := 'F';
      end if;   --> bug 06/10/2008  ajout de ce test pour forcer à fabriquer un appro Assemblé

      if v_supply_mode = 'F' then   --Si composant est fabriqué
        begin
          select 'O'
            into v_exist_of
            from gal_project_resource
           where gal_task_id = v_task_tac_id
             and gal_good_id = aGoodID
             and pjr_sort in('1RB', '2OF', '3OF', '4PF', '5OA')   --Si ressource OF ouverte sur compose fabriqué, alors pas DF
             and rownum = 1
             and 1 = 1;

          v_on_df  := 'N';
        --DBMS_OUTPUT.PUT_LINE('Set Supply Mode 1 : ' || v_sui_libart || ' - ' || v_on_df || ' - ' || v_manufacturing_mode);
        exception
          when no_data_found then
            begin
              select 'O'
                into v_on_df
                from GAL_TASK TAS
                   , GAL_TASK_LOT
               where GAL_TASK_LOT.GAL_TASK_ID in(select TSK.GAL_TASK_ID
                                                   from GAL_TASK TSK
                                                  where GAL_FATHER_TASK_ID = v_task_tac_id)
                 and GAL_TASK_LOT.GCO_GOOD_ID = aGoodId
                 and GAL_TASK_LOT.GAL_TASK_ID = TAS.GAL_TASK_ID
                 and rownum = 1;

              v_on_df  := 'O';
            --DBMS_OUTPUT.PUT_LINE('Set Supply Mode 2 : ' || v_sui_libart || ' - ' || v_on_df || ' - ' || v_manufacturing_mode);
            exception
              when no_data_found then
                if v_manufacturing_mode = '1' then
                  v_on_df  := 'O';
                else
                  v_on_df  := 'N';
                end if;
            --DBMS_OUTPUT.PUT_LINE('Set Supply Mode 3 : ' || v_sui_libart || ' - ' || v_on_df || ' - ' || v_manufacturing_mode);
            end;
        end;

        if v_nivo > 1 then
          if tableau_niveau(v_nivo - 1).on_df = 'O'   --tester si 2 niveaus 2 puis 3...
                                                   then
            v_branche_df  := 'O';
          else
            v_branche_df  := 'N';
          end if;

          if tableau_niveau(v_nivo - 1).assemblee = 'O' then
            v_branche_assemblee  := 'O';
          else
            v_branche_assemblee  := 'N';
          end if;
        else
          if v_task_good_df = 'O' then
            v_branche_df  := 'O';
          else
            v_branche_df  := 'N';
          end if;

          if v_task_good_assemblee = 'O' then
            v_branche_assemblee  := 'O';
          else
            v_branche_assemblee  := 'N';
          end if;
        end if;
      else
        if v_nivo > 1 then
          if tableau_niveau(v_nivo - 1).on_df = 'O'   --tester si 2 niveaus 2 puis 3...
                                                   then
            v_branche_df  := 'O';
          else
            v_branche_df  := 'N';
          end if;

          if tableau_niveau(v_nivo - 1).assemblee = 'O' then
            v_branche_assemblee  := 'O';
          else
            v_branche_assemblee  := 'N';
          end if;
        else
          if v_task_good_df = 'O' then
            v_branche_df  := 'O';
          else
            v_branche_df  := 'N';
          end if;

          if v_task_good_assemblee = 'O' then
            v_branche_assemblee  := 'O';
          else
            v_branche_assemblee  := 'N';
          end if;
        end if;

        v_on_df  := 'N';
      --DBMS_OUTPUT.PUT_LINE('Set Supply Mode 4 : ' || v_sui_libart || ' - ' || v_on_df || ' - ' || v_manufacturing_mode);
      end if;
    end if;
  end SetSupplyMode;

  --********** Définition du mode d'appro pour Composant DF *******************************************--
  procedure SetSupplyModeDF(A_PROJECT_SUPPLY_MODE GAL_TASK_GOOD.C_PROJECT_SUPPLY_MODE%type, A_SUPPLY_MODE V_GAL_PCS_GOOD.GGO_SUPPLY_MODE%type)
  is
  begin
    select decode(A_PROJECT_SUPPLY_MODE, '1', 'S', '2', 'A', '3', 'A', '4', 'A', '5', ' ', 'S')
         , decode(A_PROJECT_SUPPLY_MODE
                , '1', a_supply_mode   --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                , '2', 'A'
                , '3', 'F'
                , '4', 'T'
                , '5', ' '
                , a_supply_mode
                 )
      into V_SUPPLY_TYPE
         , V_SUPPLY_MODE
      from dual;

    SetSupplyMode('0', null);   --verif si optimal access dans le setsupplymode avec good id null
  end SetSupplyModeDF;

  --********** Défini si le compose est Fabriqué sur DF *****************************************************--
  procedure IsComposeDf(aGoodId GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID%type)
  is
  begin
    begin
      select TAS.TAS_START_DATE
           , TAS.TAS_END_DATE
        into v_date1_df
           , v_date2_df
        from GAL_TASK TAS
           , GAL_TASK_LOT
       where GAL_TASK_LOT.GAL_TASK_ID in(select TSK.GAL_TASK_ID
                                           from GAL_TASK TSK
                                          where GAL_FATHER_TASK_ID = v_task_tac_id)
         and GAL_TASK_LOT.GCO_GOOD_ID = aGoodId
         and GAL_TASK_LOT.GAL_TASK_ID = TAS.GAL_TASK_ID
         and rownum = 1;

      v_branche_df  := 'O';   --On est dans une branche DF
      v_compose_df  := 'O';   --le composant est aussi fab sur DF

      if     v_date1_df is not null
         and v_date2_df is not null then
        v_branche_df_launch  := 'O';
      else
        v_branche_df_launch  := 'N';
      end if;
    exception
      when no_data_found then
        begin
          select TAS_START_DATE
               , TAS_END_DATE
            into v_date1_df
               , v_date2_df
            from GAL_TASK TAS
               , GAL_TASK_LOT GTL
               , PPS_NOMENCLATURE PPS
           where GTL.GAL_TASK_ID in(select TSK.GAL_TASK_ID
                                      from GAL_TASK TSK
                                     where GAL_FATHER_TASK_ID = v_task_tac_id)
             and GTL.GCO_GOOD_ID = PPS.GCO_GOOD_ID
             and PPS_NOMENCLATURE_ID = v_pps_nomenclature_id
             and GTL.GAL_TASK_ID = TAS.GAL_TASK_ID
             and rownum = 1;

          v_branche_df  := 'O';   --Branche DF
          v_compose_df  := 'N';   --le composant n'est pas fabriqué sur DF

          if     v_date1_df is not null
             and v_date2_df is not null then
            v_branche_df_launch  := 'O';
          else
            v_branche_df_launch  := 'N';
          end if;
        exception
          when no_data_found then
            v_branche_df         := 'N';
            v_compose_df         := 'N';
            v_branche_df_launch  := 'N';
        end;
    end;
  end IsComposeDf;

     /*
     --********************************************************************************************************--
     PROCEDURE GetSupplyMode (a_type_acces CHAR
                            , a_supply_type V_GAL_PCS_GOOD.GGO_SUPPLY_TYPE%TYPE
                            , a_supply_mode V_GAL_PCS_GOOD.GGO_SUPPLY_MODE%TYPE
                            , a_path GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%TYPE
                            , a_task_id GAL_TASK.GAL_TASK_ID%TYPE
                            , a_nomen_header_id GAL_PROJECT_SUPPLY_MODE.PPS_NOMENCLATURE_ID%TYPE
                            , a_good_id GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID%TYPE
                            )
     IS
       v_sp_mode GAL_PROJECT_SUPPLY_MODE.C_PROJECT_SUPPLY_MODE%TYPE;
     BEGIN
  /*
       SELECT s_type
             ,s_mode
       INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
       FROM
       ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                ,'2','A'
                                                ,'3','A'
                                                ,'4','A'
                                                ,'5',' '
                                                ,'S') s_type,
               DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1',a_supply_mode
                                                ,'2','A'
                                                ,'3','F'
                                                ,'4','T'
                                                ,'5',' '
                                                ,a_supply_mode) s_mode
         FROM GAL_PROJECT_SUPPLY_MODE GSM
         WHERE GSM.GSM_NOM_PATH = a_path
         AND GSM.GAL_FATHER_TASK_ID = a_task_id
         AND GSM.PPS_NOMENCLATURE_HEADER_ID = NVL(a_nomen_header_id,a_good_id)
         AND EXISTS (SELECT '*' FROM GAL_TASK_GOOD GTG
                          WHERE (GTG.PPS_NOMENCLATURE_ID = GSM.PPS_NOMENCLATURE_HEADER_ID OR GTG.GCO_GOOD_ID = GSM.PPS_NOMENCLATURE_HEADER_ID)
                          AND GTG.GAL_TASK_GOOD_ID = GSM.GAL_TASK_GOOD_ID AND ROWNUM = 1)
         ORDER BY a_datecre DESC)
       WHERE ROWNUM = 1;

       SetSupplyMode(a_type_acces,a_good_id);

     EXCEPTION WHEN NO_DATA_FOUND THEN
  * /
      BEGIN

       SELECT s_type
             ,s_mode
       INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
       FROM
       ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                ,'2','A'
                                                ,'3','A'
                                                ,'4','A'
                                                ,'5',' '
                                                ,'S') s_type,
               DECODE(GSM.C_PROJECT_SUPPLY_MODE, '1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                                ,'2','A'
                                                ,'3','F'
                                                ,'4','T'
                                                ,'5',' '
                                                ,a_supply_mode) s_mode
         FROM GAL_PROJECT_SUPPLY_MODE GSM
         WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
         AND GSM.GAL_FATHER_TASK_ID = a_task_id
         AND GSM.PPS_NOMENCLATURE_HEADER_ID = NVL(a_nomen_header_id,a_good_id)
         AND EXISTS (SELECT '*' FROM GAL_TASK_GOOD GTG
                          WHERE (GTG.PPS_NOMENCLATURE_ID = GSM.PPS_NOMENCLATURE_HEADER_ID OR GTG.GCO_GOOD_ID = GSM.PPS_NOMENCLATURE_HEADER_ID)
                          AND GTG.GAL_TASK_GOOD_ID = GSM.GAL_TASK_GOOD_ID AND ROWNUM = 1)
         ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
       WHERE ROWNUM = 1;

       SetSupplyMode(a_type_acces,a_good_id);

     EXCEPTION WHEN NO_DATA_FOUND THEN

       BEGIN
         SELECT s_type
               ,s_mode
         INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
         FROM
         ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                ,'2','A'
                                                ,'3','A'
                                                ,'4','A'
                                                  ,'5',' '
                                                ,a_supply_type) s_type,
                DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                                ,'2','A'
                                                ,'3','F'
                                                ,'4','T'
                                                ,'5',' '
                                                ,a_supply_mode) s_mode
           FROM GAL_PROJECT_SUPPLY_MODE GSM
           WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
           AND GSM.GAL_FATHER_TASK_ID = a_task_id
           AND GSM.PPS_NOMENCLATURE_HEADER_ID = NVL(a_nomen_header_id,a_good_id)
           ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
         WHERE ROWNUM = 1;

         SetSupplyMode(a_type_acces,a_good_id);

       EXCEPTION WHEN NO_DATA_FOUND THEN

         BEGIN -- <> NOMEN HEADER
           SELECT s_type
                 ,s_mode
           INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
           FROM
           ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                  ,'2','A'
                                                  ,'3','A'
                                                  ,'4','A'
                                                  ,'5',' '
                                                  ,'S')  s_type,
                  DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                                  ,'2','A'
                                                  ,'3','F'
                                                  ,'4','T'
                                                  ,'5',' '
                                                  ,a_supply_mode) s_mode
             FROM GAL_PROJECT_SUPPLY_MODE GSM
             WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
             AND GSM.GAL_FATHER_TASK_ID = a_task_id
             AND GSM.PPS_NOMENCLATURE_HEADER_ID <> NVL(a_nomen_header_id,a_good_id)
             AND EXISTS (SELECT '*' FROM GAL_TASK_GOOD GTG
                              WHERE (GTG.PPS_NOMENCLATURE_ID = GSM.PPS_NOMENCLATURE_HEADER_ID OR GTG.GCO_GOOD_ID = GSM.PPS_NOMENCLATURE_HEADER_ID)
                              AND GTG.GAL_TASK_GOOD_ID = GSM.GAL_TASK_GOOD_ID AND ROWNUM = 1)
             ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
           WHERE ROWNUM = 1;

           SetSupplyMode(a_type_acces,a_good_id);

         EXCEPTION WHEN NO_DATA_FOUND THEN

           BEGIN
             SELECT s_type
                   ,s_mode
             INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
             FROM
             ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                      ,'2','A'
                                                      ,'3','A'
                                                      ,'4','A'
                                                        ,'5',' '
                                                      ,a_supply_type) s_type,
                    DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                                    ,'2','A'
                                                    ,'3','F'
                                                    ,'4','T'
                                                    ,'5',' '
                                                    ,a_supply_mode) s_mode
               FROM GAL_PROJECT_SUPPLY_MODE GSM
               WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
               AND GSM.GAL_FATHER_TASK_ID = a_task_id
               AND GSM.PPS_NOMENCLATURE_HEADER_ID <> NVL(a_nomen_header_id,a_good_id)
               ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
             WHERE ROWNUM = 1;

             SetSupplyMode(a_type_acces,a_good_id);

           EXCEPTION WHEN NO_DATA_FOUND THEN
             /*Dans la cas de compose anticipé sur DF, je force le mode d'appro à fabriqué à l'affaire,
             ensuite, l'utilisateur peut contrarié ce mode par la nomenclature* /

             v_sp_mode := ' ';

             IF a_type_acces = '0' --Pour le composant
             THEN
               IsComposeDf(a_good_id);
               IF v_compose_df = 'O' THEN
                 v_supply_mode := 'F';
                 v_supply_type := 'A';
               ELSE
                 --composant DF = si n'existe pas dans de GSM = on prend le mode d'appro des composants sur DF
                 --> LECTURE DES GAL_TASK pour recuperer le mode d'appro
                 BEGIN --BUG : TROUVE PAS lES DONNEES A VOIR !!!!
                   SELECT C_PROJECT_SUPPLY_MODE INTO v_sp_mode FROM GAL_TASK_GOOD
                   WHERE GAL_TASK_ID IN (SELECT GAL_TASK_ID FROM GAL_TASK WHERE GAL_FATHER_TASK_ID = a_task_id) ---??? FIWER EN TROUVANT UN LIEN SUR LE BON DF
                   AND GCO_GOOD_ID = a_good_id AND ROWNUM = 1;

                   SetSupplyModeDF (v_sp_mode,v_repartition);

                 EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
                   v_supply_mode := v_repartition;
                   v_supply_type := v_type_gestion;
                 END;
               END IF;

               SetSupplyMode (a_type_acces,a_good_id); --Pour le composant

             ELSE --La table GSM n'est pas renseignée et le compose est fabriqué => branche DF si config DF
               IsComposeDf(a_good_id);
               IF v_branche_df = 'N'
               THEN
                 BEGIN
                   SELECT 'O','N','N' INTO v_branche_df,v_compose_df,v_branche_df_launch
                     FROM v_gal_pcs_good fichart_composant
                     WHERE fichart_composant.gal_good_id = a_good_id
                     AND fichart_composant.ggo_supply_mode = 'F'
                     AND v_manufacturing_mode = '1';
                 EXCEPTION WHEN NO_DATA_FOUND THEN
                   v_branche_df  := 'N';
                   v_compose_df  := 'N';
                   v_branche_df_launch := 'N';
                 END;
               END IF;
             END IF;

           END;
         END;
       END;
      END;
     END GetSupplyMode; */

  --********************************************************************************************************--
  procedure GetSupplyMode(
    a_type_acces      char
  , a_supply_type     V_GAL_PCS_GOOD.GGO_SUPPLY_TYPE%type
  , a_supply_mode     V_GAL_PCS_GOOD.GGO_SUPPLY_MODE%type
  , a_path            GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type
  , a_task_id         GAL_TASK.GAL_TASK_ID%type
  , a_nomen_header_id GAL_PROJECT_SUPPLY_MODE.PPS_NOMENCLATURE_ID%type
  , a_good_id         GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID%type
  )
  is
    v_sp_mode GAL_PROJECT_SUPPLY_MODE.C_PROJECT_SUPPLY_MODE%type;
  begin
    /*
         SELECT s_type
               ,s_mode
         INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
         FROM
         ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                  ,'2','A'
                                                  ,'3','A'
                                                  ,'4','A'
                                                  ,'5',' '
                                                  ,'S') s_type,
                 DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1',a_supply_mode
                                                  ,'2','A'
                                                  ,'3','F'
                                                  ,'4','T'
                                                  ,'5',' '
                                                  ,a_supply_mode) s_mode
           FROM GAL_PROJECT_SUPPLY_MODE GSM
           WHERE GSM.GSM_NOM_PATH = a_path
           AND GSM.GAL_FATHER_TASK_ID = a_task_id
           AND GSM.PPS_NOMENCLATURE_HEADER_ID = NVL(a_nomen_header_id,a_good_id)
           AND EXISTS (SELECT '*' FROM GAL_TASK_GOOD GTG
                            WHERE (GTG.PPS_NOMENCLATURE_ID = GSM.PPS_NOMENCLATURE_HEADER_ID OR GTG.GCO_GOOD_ID = GSM.PPS_NOMENCLATURE_HEADER_ID)
                            AND GTG.GAL_TASK_GOOD_ID = GSM.GAL_TASK_GOOD_ID AND ROWNUM = 1)
           ORDER BY a_datecre DESC)
         WHERE ROWNUM = 1;

         SetSupplyMode(a_type_acces,a_good_id);

       EXCEPTION WHEN NO_DATA_FOUND THEN
    */
    begin
      /*SELECT s_type
            ,s_mode
      INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
      FROM
      ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                               ,'2','A'
                                               ,'3','A'
                                               ,'4','A'
                                               ,'5',' '
                                               ,'S') s_type,
              DECODE(GSM.C_PROJECT_SUPPLY_MODE, '1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                               ,'2','A'
                                               ,'3','F'
                                               ,'4','T'
                                               ,'5',' '
                                               ,a_supply_mode) s_mode
        FROM GAL_PROJECT_SUPPLY_MODE GSM
        WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
        AND GSM.GAL_FATHER_TASK_ID = a_task_id
        --AND GSM.PPS_NOMENCLATURE_HEADER_ID = NVL(a_nomen_header_id,a_good_id)
        --AND EXISTS (SELECT '*' FROM GAL_TASK_GOOD GTG
        --                 WHERE (GTG.PPS_NOMENCLATURE_ID = GSM.PPS_NOMENCLATURE_HEADER_ID OR GTG.GCO_GOOD_ID = GSM.PPS_NOMENCLATURE_HEADER_ID)
        --                 AND GTG.GAL_TASK_GOOD_ID = GSM.GAL_TASK_GOOD_ID AND ROWNUM = 1)
        ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
      WHERE ROWNUM = 1;*/
      select s_type
           , s_mode
        into V_SUPPLY_TYPE
           , V_SUPPLY_MODE
        from (select   decode(c_mode, '1', 'S', '2', 'A', '3', 'A', '4', 'A', '5', ' ', 'S') s_type
                     , decode(c_mode
                            , '1', a_supply_mode   --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                            , '2', 'A'
                            , '3', 'F'
                            , '4', 'T'
                            , '5', ' '
                            , a_supply_mode
                             ) s_mode
                  from (select GSM.C_PROJECT_SUPPLY_MODE c_mode
                             , GSM.GSM_NOM_PATH x_path
                             , GSM.A_DATECRE x_datecre
                             , GSM.A_DATEMOD x_datemod
                          from GAL_PROJECT_SUPPLY_MODE GSM
                         where GSM.GCO_GOOD_ID = a_good_id
                           and GSM.GAL_FATHER_TASK_ID = a_task_id)
                 where gal_project_calculation.GetPathNoSeq(x_path) = gal_project_calculation.GetPathNoSeq(a_path)
              order by x_datecre desc
                     , nvl(x_datemod, sysdate - 10000) desc)
       where rownum = 1;

      SetSupplyMode(a_type_acces, a_good_id);
    exception
      when no_data_found then
           /*
             BEGIN
               SELECT s_type
                     ,s_mode
               INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
               FROM
               ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                      ,'2','A'
                                                      ,'3','A'
                                                      ,'4','A'
                                                        ,'5',' '
                                                      ,a_supply_type) s_type,
                      DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                                      ,'2','A'
                                                      ,'3','F'
                                                      ,'4','T'
                                                      ,'5',' '
                                                      ,a_supply_mode) s_mode
                 FROM GAL_PROJECT_SUPPLY_MODE GSM
                 WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
                 AND GSM.GAL_FATHER_TASK_ID = a_task_id
                 AND GSM.PPS_NOMENCLATURE_HEADER_ID = NVL(a_nomen_header_id,a_good_id)
                 ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
               WHERE ROWNUM = 1;

               SetSupplyMode(a_type_acces,a_good_id);

             EXCEPTION WHEN NO_DATA_FOUND THEN

               BEGIN -- <> NOMEN HEADER
                 SELECT s_type
                       ,s_mode
                 INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
                 FROM
                 ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                        ,'2','A'
                                                        ,'3','A'
                                                        ,'4','A'
                                                        ,'5',' '
                                                        ,'S')  s_type,
                        DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                                        ,'2','A'
                                                        ,'3','F'
                                                        ,'4','T'
                                                        ,'5',' '
                                                        ,a_supply_mode) s_mode
                   FROM GAL_PROJECT_SUPPLY_MODE GSM
                   WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
                   AND GSM.GAL_FATHER_TASK_ID = a_task_id
                   AND GSM.PPS_NOMENCLATURE_HEADER_ID <> NVL(a_nomen_header_id,a_good_id)
                   AND EXISTS (SELECT '*' FROM GAL_TASK_GOOD GTG
                                    WHERE (GTG.PPS_NOMENCLATURE_ID = GSM.PPS_NOMENCLATURE_HEADER_ID OR GTG.GCO_GOOD_ID = GSM.PPS_NOMENCLATURE_HEADER_ID)
                                    AND GTG.GAL_TASK_GOOD_ID = GSM.GAL_TASK_GOOD_ID AND ROWNUM = 1)
                   ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
                 WHERE ROWNUM = 1;

                 SetSupplyMode(a_type_acces,a_good_id);

               EXCEPTION WHEN NO_DATA_FOUND THEN

                 BEGIN
                   SELECT s_type
                         ,s_mode
                   INTO V_SUPPLY_TYPE, V_SUPPLY_MODE
                   FROM
                   ( SELECT DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1','S'
                                                            ,'2','A'
                                                            ,'3','A'
                                                            ,'4','A'
                                                              ,'5',' '
                                                            ,a_supply_type) s_type,
                          DECODE(GSM.C_PROJECT_SUPPLY_MODE,'1', a_supply_mode --decode(a_supply_mode,'T','F',a_supply_mode) -- a_supply_mode --> bug 06/10/2008
                                                          ,'2','A'
                                                          ,'3','F'
                                                          ,'4','T'
                                                          ,'5',' '
                                                          ,a_supply_mode) s_mode
                     FROM GAL_PROJECT_SUPPLY_MODE GSM
                     WHERE gal_project_calculation.GetPathNoSeq(GSM.GSM_NOM_PATH) = gal_project_calculation.GetPathNoSeq(a_path)
                     AND GSM.GAL_FATHER_TASK_ID = a_task_id
                     AND GSM.PPS_NOMENCLATURE_HEADER_ID <> NVL(a_nomen_header_id,a_good_id)
                     ORDER BY a_datecre DESC,nvl(a_datemod,sysdate-10000) DESC)
                   WHERE ROWNUM = 1;

                   SetSupplyMode(a_type_acces,a_good_id);

                 EXCEPTION WHEN NO_DATA_FOUND THEN
                   /*Dans la cas de compose anticipé sur DF, je force le mode d'appro à fabriqué à l'affaire,
                   ensuite, l'utilisateur peut contrarié ce mode par la nomenclature* /
        */
        v_sp_mode  := ' ';

        if a_type_acces = '0'   --Pour le composant
                             then
          IsComposeDf(a_good_id);

          if v_compose_df = 'O' then
            v_supply_mode  := 'F';
            v_supply_type  := 'A';
          else
            --composant DF = si n'existe pas dans de GSM = on prend le mode d'appro des composants sur DF
            --> LECTURE DES GAL_TASK pour recuperer le mode d'appro
            begin   --BUG : TROUVE PAS lES DONNEES A VOIR !!!!
              select C_PROJECT_SUPPLY_MODE
                into v_sp_mode
                from GAL_TASK_GOOD
               where GAL_TASK_ID in(select GAL_TASK_ID
                                      from GAL_TASK
                                     where GAL_FATHER_TASK_ID = a_task_id)   ---??? FIWER EN TROUVANT UN LIEN SUR LE BON DF
                 and GCO_GOOD_ID = a_good_id
                 and rownum = 1;

              SetSupplyModeDF(v_sp_mode, v_repartition);
            exception
              when no_data_found then
                null;
                v_supply_mode  := v_repartition;
                v_supply_type  := v_type_gestion;
            end;
          end if;

          SetSupplyMode(a_type_acces, a_good_id);   --Pour le composant
        else   --La table GSM n'est pas renseignée et le compose est fabriqué => branche DF si config DF
          IsComposeDf(a_good_id);

          if v_branche_df = 'N' then
            begin
              select 'O'
                   , 'N'
                   , 'N'
                into v_branche_df
                   , v_compose_df
                   , v_branche_df_launch
                from v_gal_pcs_good fichart_composant
               where fichart_composant.gal_good_id = a_good_id
                 and fichart_composant.ggo_supply_mode = 'F'
                 and v_manufacturing_mode = '1';
            exception
              when no_data_found then
                v_branche_df         := 'N';
                v_compose_df         := 'N';
                v_branche_df_launch  := 'N';
            end;
          end if;
        end if;
    --END;
    --END;
    --END;
    end;
  end GetSupplyMode;

  --********** Info Produit *******************************************************--
  procedure ReadInfoGcoGood(
    a_compose   gco_good.gco_good_id%type
  , a_composant gco_good.gco_good_id%type
  , a_verif_df  number   --1 verif compose DF, 0 pas de verif
  )
  is
  begin
    --DBMS_OUTPUT.PUT_LINE('Cse : ' || to_char(a_compose) || ' - Csant : ' ||  to_char(a_composant));
    select distinct max(nvl(fichart_composant.ggo_obtaining_delay, 0) )
                  , max(nvl(fichart_compose.ggo_obtaining_delay, 0) )
                  , max(nvl(fichart_composant.GGO_MANUFACTURING_DELAY, 0) )
                  , max(nvl(fichart_composant.GGO_SUPPLY_DELAY, 0) )
                  , max(nvl(fichart_compose.GGO_MANUFACTURING_DELAY, 0) )
                  , max(nvl(fichart_compose.GGO_SUPPLY_DELAY, 0) )
                  , fichart_composant.ggo_supply_mode
                  , fichart_composant.ggo_supply_type
                  , fichart_composant.ggo_unit_of_measure
                  , fichart_composant.ggo_major_reference
                  , fichart_composant.ggo_short_description
                  , fichart_composant.ggo_long_description
                  , fichart_composant.ggo_plan_number
                  , fichart_composant.ggo_unit_of_measure
                  , fichart_composant.ggo_description
               into v_composant_del_obt
                  , v_compose_del_obt
                  , v_csant_del_manuf
                  , v_csant_del_supl
                  , v_cse_del_manuf
                  , v_cse_del_supl
                  , v_repartition
                  , v_type_gestion
                  , v_unite_stock
                  , v_sui_codart
                  , v_sui_libart
                  , v_sui_long_descr
                  , v_sui_plan
                  , v_sui_un_st
                  , v_sui_description
               from v_gal_pcs_good fichart_compose
                  , v_gal_pcs_good fichart_composant
              where a_compose = fichart_compose.gal_good_id
                and nvl(a_composant, 0) = fichart_composant.gal_good_id
           group by fichart_composant.ggo_supply_mode
                  , fichart_composant.ggo_supply_type
                  , fichart_composant.ggo_unit_of_measure
                  , fichart_composant.ggo_major_reference
                  , fichart_composant.ggo_short_description
                  , fichart_composant.ggo_long_description
                  , fichart_composant.ggo_plan_number
                  , fichart_composant.ggo_unit_of_measure
                  , fichart_composant.ggo_description;

    v_branche_df         := 'N';
    v_branche_df_launch  := 'N';

    if v_lien_pseudo = 'O' then
      v_repartition   := 'A';
      v_type_gestion  := 'T';
      v_supply_mode   := 'A';
      v_supply_type   := 'T';
    end if;
  end ReadInfoGcoGood;

  procedure WriteErrorInResult(
    ataskid        gal_task.gal_task_id%type
  , agoodid        doc_position.gco_good_id%type
  , abasisquantity doc_position.pos_basis_quantity%type
  , adocumentid    doc_document.doc_document_id%type
  , aerrormsg      varchar2
  )
  is
  begin
    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_task_id
               , gal_good_id
               , fal_supply_request_id
               , doc_document_id
               , doc_position_id
               , doc_position_detail_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , gal_manufacture_task_id
               , gal_pcr_qty
               , gal_pcr_remaining_qty
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , ataskid
               , agoodid
               , null
               , adocumentid
               , null
               , null
               , null
               , null
               , null
               , null
               , abasisquantity
               , 0
               , substr(aerrormsg, 1, decode(instr(aerrormsg, 'xxxxxx', 1, 1), 0, 150) )
               , '16'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );
  end WriteErrorInResult;

  --********** Finalisation d'1 documents avec gestion d'erreur ********************************************--
  procedure finalizedocument(aLine number, aTskId GAL_TASK.GAL_TASK_ID%type, aGcoId GAL_TASK.GAL_TASK_ID%type)
  is
    vGauDescribe doc_gauge.gau_describe%type;
    vDocNo       doc_document.dmt_number%type;
  begin
    verrormsg  := ' ';
    doc_finalize.finalizedocument(tableau_document(aLine).docid);
  exception
    when others then
      begin
        select trim(gau.Gau_Describe)
             , trim(dmt_number)
          into vGauDescribe
             , vDocNo
          from doc_gauge gau
             , doc_document doc
         where gau.doc_gauge_id = doc.doc_gauge_id
           and doc.doc_document_id = tableau_document(aLine).docid;
      exception
        when no_data_found then
          vGauDescribe  := ' ';
      end;

      verrormsg  := vGauDescribe || ' > Erreur dans la finalisation du document : ' || trim(vDocNo);
      WriteErrorInResult(aTskId, aGcoId, 1, tableau_document(aLine).docid, verrormsg);
  --err := 1;
  --commit;
  end;

  --********** Finalisation des documents *****************************************************************--
  procedure doc_finalize_finalizedocument(aCpt number, aTskId GAL_TASK.GAL_TASK_ID%type, aGcoId GAL_TASK.GAL_TASK_ID%type)
  is
  begin
    if aCpt > 0 then   --Finalisation des documents générés par le calcul
      for v_line_doc in 1 .. aCpt loop
        finalizedocument(v_line_doc, aTskId, aGcoId);
      end loop;
    end if;
  end doc_finalize_finalizedocument;

  --********** Génération d'un document Besoin affaire *******************************************************--
  procedure generatedocument(
    ataskid                  gal_task.gal_task_id%type
  , aprefixe                 varchar2
  , outdocid          out    doc_document.doc_document_id%type
  , v_pac_supplier_id        PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , v_doc_mono_pos           boolean
  , is_ST                    boolean
  , v_gauge_id               doc_gauge.doc_gauge_id%type
  , vgoodid                  doc_position.gco_good_id%type
  , vbasisquantity           doc_position.pos_basis_quantity%type
  , err               out    number
  , iDmtNumber        in     varchar2 default null
  )
  is
    vGauDescribe doc_gauge.gau_describe%type;

    ------------ SET les variables nécessaires à la génération du document Besoin affaire ------------------------
    procedure setvarfordocumentbesoinaffaire
    is
    begin
      vdocid      := null;
      verrormsg   := null;
      vdocnumber  := null;
      err         := 0;
      -- Lecture du gabarit nécessaire --------------------------------
      vprjcode    := v_task_no_affaire;
      vtascode    := v_task_no_tache;
      vprojectid  := v_task_aff_id;

      if is_ST   --Pour generation des DA-ST
              then
        vrecordid  := ataskid;   --Warning !!!!: on passe dans la variable ataskid le doc_record_id de l'ope externe
      else
        vrecordid  := v_task_doc_record_id;   --Pour génération standard calcul besoin et DF
      end if;

      if v_gauge_id is not null then
        -- N° de document passé (utilisé pour les DF uniquement)
        if iDmtNumber is not null then
          declare
            lvStatus DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
          begin
            -- Vérifier si le document existe et dans quel état est-il
            select DOC_DOCUMENT_ID
                 , DMT_NUMBER
                 , C_DOCUMENT_STATUS
              into vdocid
                 , vdocnumber
                 , lvStatus
              from DOC_DOCUMENT
             where DMT_NUMBER = iDmtNumber;

            -- Le document existe et est ouvert (pas liquidé ou annulé)
            if lvStatus in('01', '02', '03') then
              -- La variable vdocid contient le bon id document -> Pas de génération de document
              null;
            else
              -- Le document existe et est  liquidé ou annulé
              vdocid      := null;   -- Création d'un nouveau document
              vdocnumber  := null;   -- Un nouveau n° de document sera généré
            end if;
          exception
            when no_data_found then
              -- Le document n'existe pas
              vdocid      := null;   -- Création d'un nouveau document
              vdocnumber  := iDmtNumber;   -- Utilisation du n° de DF passé en param
          end;
        else
          -- On recherche, pour l'affaire/tâche, s'il existe déjà un document "Besoin Affaire" encore ouvert
          -- Si c'est le cas, on va ajouter des positions à ce document
          -- Si ce n'est pas le cas, on va créer un nouveau document avec indiçage
          if not v_doc_mono_pos then
            begin
              select DOC_DOCUMENT_ID
                   , dmt_number
                into vdocid
                   , vdocnumber
                from doc_document
               where doc_record_id = vrecordid
                 and doc_gauge_id = v_gauge_id
                 and c_document_status in('01', '02', '03')
                 and rownum = 1;
            exception
              when no_data_found then
                vdocid      := null;
                vdocnumber  := null;
            end;
          else
            vdocid      := null;
            vdocnumber  := null;
          end if;
        end if;
      end if;
    end setvarfordocumentbesoinaffaire;
--------------------------------------------------------------------------------------------------------------

  -- PROCEDURE PRINCIPALE -------------------------------------------------
  begin
    setvarfordocumentbesoinaffaire;

    -- Si aucun document ouvert n'existe, alors on crée un nouveau document
    if     vdocid is null   -- Contrôle des valeurs obligatoires
       and v_gauge_id is not null
       and vrecordid is not null then
      doc_document_generate.generatedocument(anewdocumentid   => vdocid
                                           , aerrormsg        => verrormsg
                                           , amode            => null
                                           , agaugeid         => v_gauge_id
                                           , adocnumber       => vdocnumber
                                           , arecordid        => vrecordid
                                           , aThirdID         => v_pac_supplier_id
                                            );

      if verrormsg is not null then
        --DBMS_OUTPUT.put_line ('Erreur création entête de document');
        vdocid  := null;
      end if;

      err  := 0;
    /*
    IF vdocid IS NOT NULL
    THEN
      -- Cette procédure libère le document et recalcule les montants
      doc_finalize.finalizedocument (vdocid);
    END IF;
    */
    end if;

    outdocid  := vdocid;
  exception
    when others then
      begin
        select trim(Gau_Describe)
          into vGauDescribe
          from doc_gauge
         where doc_gauge_id = v_gauge_id;
      exception
        when no_data_found then
          vGauDescribe  := ' ';
      end;

      verrormsg  := vGauDescribe || ' > ' || DBMS_UTILITY.format_error_stack;   -- || DBMS_UTILITY.format_call_stack;
      WriteErrorInResult(ataskid, vgoodid, vbasisquantity, vdocid, verrormsg);
      err        := 1;
  --commit;
  end generatedocument;

--**********************************************************************************************************--

  --********** Génération d'une position de document Besoin affaire ******************************************--
  procedure generateposdoc(
    vdocumentid        doc_document.doc_document_id%type
  , vgoodid            doc_position.gco_good_id%type
  , vbasisquantity     doc_position.pos_basis_quantity%type
  , vstockid           doc_position.stm_stock_id%type default null
  , vlocationid        doc_position.stm_location_id%type default null
  , vFinaldelay        doc_position_detail.pde_basis_delay%type
  , ataskid            gal_task.gal_task_id%type
  , outposid       out doc_position.doc_position_id%type
  , err            out number
  )
  is
    vpositionid         doc_position.doc_position_id%type;
    --verrormsg         VARCHAR2 (2000);
    v_doc_gauge_id      doc_document.DOC_GAUGE_ID%type;
    v_pac_supplier_id   pac_supplier_partner.pac_supplier_partner_id%type;
    v_N                 number;
    v_C                 varchar2(4000);
    aConvertFactor      number;
    aNumberOfDecimal    number;
    vGauDescribe        doc_gauge.gau_describe%type;
    v_Def_BasisQuantity number;
  begin
    vpositionid  := null;
    verrormsg    := null;
    err          := 0;

    -- Contrôle des valeurs obligatoires
    if     vdocumentid is not null
       and vgoodid is not null
       and vbasisquantity is not null
       and vFinaldelay is not null then
      select doc_gauge_id
           , pac_third_id
        into v_doc_gauge_id
           , v_pac_supplier_id
        from doc_document
       where doc_document_id = vdocumentid;

      if v_doc_gauge_id = V_GAL_GAUGE_SUPPLY_REQUEST then
        GCO_I_LIB_COMPL_DATA.GetComplementarydata(vgoodid
                                                , '1'
                                                , v_pac_supplier_id
                                                , pcs.PC_I_LIB_SESSION.getuserlangid
                                                , null
                                                , null
                                                , null
                                                , v_N
                                                , v_N
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , aConvertFactor
                                                , aNumberOfDecimal
                                                , v_N
                                                 );
        v_Def_BasisQuantity  := ACS_FUNCTION.RoundNear(vbasisquantity / aConvertFactor, 1 / power(10, aNumberOfDecimal), 0);
      else
        v_Def_BasisQuantity  := vbasisquantity;
      end if;

      doc_position_generate.generateposition(apositionid       => vpositionid
                                           , aerrormsg         => verrormsg
                                           , adocumentid       => vdocumentid
                                           , aposcreatetype    => 'INSERT'
                                           , atypepos          => '1'
                                           , agoodid           => vgoodid
                                           , abasisquantity    => v_Def_BasisQuantity
                                           , astockid          => vstockid
                                           , alocationid       => vlocationid
                                           , ageneratedetail   => 1
                                           , aFinalDelay       => vFinaldelay   --Bug dans le GeneratePosDoc => FinalDelay Pas géré encore (a venir)
                                            );

      if verrormsg is not null then
        DBMS_OUTPUT.put_line('Erreur création position de document');
        vpositionid  := null;
      end if;

      if vpositionid is not null then
        if v_flag_doc <> vdocumentid then
          v_flag_doc  := vdocumentid;

          if instr(trim(v_list_doc), ';' || trim(to_char(vdocumentid) ) || ';', 1, 1) = 0 then
            v_cpt_doc                          := v_cpt_doc + 1;
            tableau_document(v_cpt_doc).docid  := vdocumentid;
          end if;

          v_list_doc  := trim(v_list_doc) || trim(to_char(vdocumentid) ) || ';';
        end if;
      -- Cette procédure libère le document et recalcule les montants
      --doc_finalize.finalizedocument (vdocumentid);
      end if;
    end if;

    err          := 0;
    outposid     := vpositionid;
  exception
    when others then
      begin
        select trim(gau.Gau_Describe)
          into vGauDescribe
          from doc_gauge gau
             , doc_document doc
         where gau.doc_gauge_id = doc.doc_gauge_id
           and doc.doc_document_id = vdocumentid;
      exception
        when no_data_found then
          vGauDescribe  := ' ';
      end;

      verrormsg  := vGauDescribe || ' > ' || DBMS_UTILITY.format_error_stack;   -- || DBMS_UTILITY.format_call_stack;
      WriteErrorInResult(ataskid, vgoodid, vbasisquantity, vdocumentid, verrormsg);
      err        := 1;
  --commit;
  end generateposdoc;

--*******************************************************************************************************--
  function GetDecalageForward(a_date date, a_delai number)
    return date
  is
    v_date_ret date;
  begin
    v_date_ret  := FAL_SCHEDULE_FUNCTIONS.getdecalageforwarddate(null, null, null, null, null, acalendarID, a_date, a_delai);
    return(v_date_ret);
  end GetDecalageForward;

--*******************************************************************************************************--
  function GetDecalageBackward(a_date date, a_delai number)
    return date
  is
    v_date_ret date;
  begin
    v_date_ret  := FAL_SCHEDULE_FUNCTIONS.getdecalagebackwarddate(null, null, null, null, null, acalendarID, a_date, a_delai);
    return(v_date_ret);
  end GetDecalageBackward;

--*******************************************************************************************************--
  function cherche_date_besoin_net(a_date_besoin_n_moins_1 date, a_delai_n number)
    return date
  is
    v_date_ret date;
  begin
    if sign(a_delai_n) = -1 then
      v_date_ret  := FAL_SCHEDULE_FUNCTIONS.getdecalagebackwarddate(null, null, null, null, null, acalendarID, a_date_besoin_n_moins_1, abs(a_delai_n) );
    else
      v_date_ret  := FAL_SCHEDULE_FUNCTIONS.getdecalageforwarddate(null, null, null, null, null, acalendarID, a_date_besoin_n_moins_1, abs(a_delai_n) );
    end if;

    /* SELECT a_date_besoin_n_moins_1 + a_delai_n INTO v_date_ret FROM DUAL; */
    return(v_date_ret);
  end cherche_date_besoin_net;

--*******************************************************************************************************--
  procedure generate_need_project(a_line in number, a_qty in number)
  is
    v_err number;
  begin
    outdocumentid  := null;
    outpositionid  := null;
    v_err          := 0;

    --astockid := NULL;
    --alocationid := NULL;
    if a_qty > 0 then
      if outdocumentid is null then
        generatedocument(ataskid             => v_task_tac_id
                       , aprefixe            => ''
                       , outdocid            => outdocumentid
                       , v_pac_supplier_id   => null
                       , v_doc_mono_pos      => false
                       , is_ST               => false
                       , v_gauge_id          => V_GAL_GAUGE_NEED_PROJECT
                       , vgoodid             => tableau_niveau_final(a_line).article_id
                       , vbasisquantity      => a_qty
                       , err                 => v_err
                        );
      end if;

      if outdocumentid is not null then
        generateposdoc(vdocumentid      => outdocumentid
                     , vgoodid          => tableau_niveau_final(a_line).article_id
                     , vbasisquantity   => a_qty
                     , vstockid         => astockid
                     , vlocationid      => alocationid
                     , vFinaldelay      => tableau_niveau_final(a_line).dat_besoin_net
                     , ataskid          => v_task_tac_id
                     , outposid         => outpositionid
                     , err              => v_err
                      );

        if     a_qty > 0
           and v_err = 0 then
          insert into gal_project_calc_result
                      (gal_project_calc_result_id
                     , gal_task_id
                     , gal_good_id
                     , fal_supply_request_id
                     , doc_document_id
                     , doc_position_id
                     , doc_position_detail_id
                     , fal_doc_prop_id
                     , fal_lot_prop_id
                     , fal_lot_id
                     , gal_pcr_qty
                     , gal_pcr_remaining_qty
                     , gal_pcr_comment
                     , gal_pcr_sort
                     , a_idcre
                     , a_datecre
                      )
               values (gal_project_calc_result_id_seq.nextval
                     , tableau_niveau_final(a_line).tache_id
                     , tableau_niveau_final(a_line).article_id
                     , null
                     , outdocumentid
                     , outpositionid
                     , outpositionid
                     , null
                     , null
                     , null
                     , a_qty
                     , 0
                     ,   --tableau_niveau_final (a_line).qte_besoin_net, 0, --remaining qty
                       (select pcs.pc_functions.translateword('Besoins')
                          from dual)
                     , '2'
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                      );
        end if;
      end if;
    else
      null;   --DELETE POSITION
    end if;
  end generate_need_project;

--*******************************************************************************************************--
  procedure generate_supply_request(a_line in number, v_Type_Supply_To_Generate in integer)
  is
    v_compteur              fal_supply_request.fsr_number%type;
    outreqid                fal_supply_request.fal_supply_request_id%type;
    v_fal_supply_request_id fal_supply_request.fal_supply_request_id%type;
    v_pac_supplier_id       PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    ResPropDocId            FAL_DOC_PROP.FAL_DOC_PROP_ID%type;
    v_err                   number;
    v_N                     number;
    v_C                     varchar2(4000);
    aConvertFactor          number;
    aNumberOfDecimal        number;
    v_Def_BasisQuantity     number;
  begin
    outdocumentid            := null;
    outpositionid            := null;
    --astockid := NULL;
    --alocationid := NULL;
    outreqid                 := null;
    ResPropDocId             := null;
    v_fal_supply_request_id  := null;
    v_err                    := 0;

    if v_Type_Supply_To_Generate < 2 then
      if v_Type_Supply_To_Generate = 0 then   -- multi poitio
        gal_project_calculation.generatedocument(ataskid             => v_task_tac_id
                                               , aprefixe            => 'DA - '
                                               , outdocid            => outdocumentid
                                               , v_pac_supplier_id   => null
                                               , v_doc_mono_pos      => false
                                               , is_ST               => false
                                               , v_gauge_id          => V_GAL_GAUGE_SUPPLY_REQUEST
                                               , vgoodid             => tableau_niveau_final(a_line).article_id
                                               , vbasisquantity      => tableau_niveau_final(a_line).qte_besoin_net
                                               , err                 => v_err
                                                );
      elsif v_Type_Supply_To_Generate = 1 then   -- mono positioin
        begin
          select GCO_COMPL_DATA_PURCHASE.PAC_SUPPLIER_PARTNER_ID
            into v_pac_supplier_id
            from GCO_COMPL_DATA_PURCHASE
           where GCO_COMPL_DATA_PURCHASE.GCO_GOOD_ID = tableau_niveau_final(a_line).article_id
             and GCO_COMPL_DATA_PURCHASE.CPU_DEFAULT_SUPPLIER = 1;
        exception
          when no_data_found then
            v_pac_supplier_id  := null;
        end;

        gal_project_calculation.generatedocument(ataskid             => v_task_tac_id
                                               , aprefixe            => 'DA - '
                                               , outdocid            => outdocumentid
                                               , v_pac_supplier_id   => v_pac_supplier_id
                                               , v_doc_mono_pos      => true
                                               , is_ST               => false
                                               , v_gauge_id          => V_GAL_GAUGE_SUPPLY_REQUEST
                                               , vgoodid             => tableau_niveau_final(a_line).article_id
                                               , vbasisquantity      => tableau_niveau_final(a_line).qte_besoin_net
                                               , err                 => v_err
                                                );
      end if;   -- type_supply_togenerate

      if outdocumentid is not null then
        gal_project_calculation.generateposdoc(vdocumentid      => outdocumentid
                                             , vgoodid          => tableau_niveau_final(a_line).article_id
                                             , vbasisquantity   => tableau_niveau_final(a_line).qte_besoin_net
                                             , vstockid         => astockid
                                             , vlocationid      => alocationid
                                             , vFinaldelay      => tableau_niveau_final(a_line).dat_besoin_net
                                             , ataskid          => v_task_tac_id
                                             , outposid         => outpositionid
                                             , err              => v_err
                                              );
      end if;
    else
      -- Config Achat : 0/1 Doc Demande d'achat Mono position / Milti Position (ci-dessus)
      -- Config Achat : 2 POA
      -- Config Achat : 3 DA
      if v_Type_Supply_To_Generate = '2' then
        /*Anciennement Methode Generation DA...*/
        --On garde temporairement une DA pour que le calcaul de besoin régénératif ne supprime pas les POx

        /*2008/03/15 : On génère toute les DA pour des questions de calcul de délai sur la POA
        BEGIN
          SELECT fal_supply_request_id INTO v_fal_supply_request_id
          FROM fal_supply_request WHERE doc_record_id = tableau_niveau_final(a_line).doc_record_id
          AND ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
        */
        select lpad(nvl(max(to_number(fsr.fsr_number) ), 0) + 1, 6, '0')
          into v_compteur
          from fal_supply_request fsr;

        fal_supply_request_functions.updatesupplyrequestproject(tableau_niveau_final(a_line).article_id
                                                              , tableau_niveau_final(a_line).doc_record_id
                                                              , v_compteur
                                                              ,   --ex numero d'OA
                                                                substr(tableau_niveau_final(a_line).gco_short_description, 1, 50)
                                                              ,   --ex libelle d'OA
                                                                tableau_niveau_final(a_line).qte_besoin_net
                                                              , tableau_niveau_final(a_line).dat_besoin_net
                                                              , tableau_niveau_final(a_line).gco_long_description
                                                              , null
                                                              ,   --ex commentaire
                                                                outreqid
                                                               );

        --Mise au statut refusée...
        update fal_supply_request
           set c_request_status = '2'
             , fsr_validate_date = sysdate
         where fal_supply_request_id = outreqid;

        v_fal_supply_request_id  := outreqid;
        outreqid                 := null;

        --END; /*Anciennement Methode Generation DA...*/
        begin
          select GCO_COMPL_DATA_PURCHASE.PAC_SUPPLIER_PARTNER_ID
            into v_pac_supplier_id
            from GCO_COMPL_DATA_PURCHASE
           where GCO_COMPL_DATA_PURCHASE.GCO_GOOD_ID = tableau_niveau_final(a_line).article_id
             and GCO_COMPL_DATA_PURCHASE.CPU_DEFAULT_SUPPLIER = 1;
        exception
          when no_data_found then
            v_pac_supplier_id  := null;
        end;

        GCO_I_LIB_COMPL_DATA.GetComplementarydata(tableau_niveau_final(a_line).article_id
                                                , '1'
                                                , v_pac_supplier_id
                                                , pcs.PC_I_LIB_SESSION.getuserlangid
                                                , null
                                                , null
                                                , null
                                                , v_N
                                                , v_N
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , v_C
                                                , aConvertFactor
                                                , aNumberOfDecimal
                                                , v_N
                                                 );
        v_Def_BasisQuantity      := ACS_FUNCTION.RoundNear(tableau_niveau_final(a_line).qte_besoin_net / aConvertFactor, 1 / power(10, aNumberOfDecimal), 0);
        /*Nouvelle methode POA...*/
        gal_pox_generate.CreatePropApproLog(tableau_niveau_final(a_line).article_id
                                          , tableau_niveau_final(a_line).dat_besoin_net
                                          , v_Def_BasisQuantity
                                          , tableau_niveau_final(a_line).doc_record_id
                                          , '1'
                                          ,   --HA
                                            v_stm_stock_id_project
                                          , v_stm_location_id_project
                                          , 0
                                          ,   --SupplierId
                                            v_fal_supply_request_id
                                          , ResPropDocId
                                           );
      else   --> Config Achat : 3 DA
        select lpad(nvl(max(to_number(fsr.fsr_number) ), 0) + 1, 6, '0')
          into v_compteur
          from fal_supply_request fsr;

        fal_supply_request_functions.updatesupplyrequestproject(tableau_niveau_final(a_line).article_id
                                                              , tableau_niveau_final(a_line).doc_record_id
                                                              , v_compteur
                                                              ,   --ex numero d'OA
                                                                substr(tableau_niveau_final(a_line).gco_short_description, 1, 50)
                                                              ,   --ex libelle d'OA
                                                                tableau_niveau_final(a_line).qte_besoin_net
                                                              , tableau_niveau_final(a_line).dat_besoin_net
                                                              , tableau_niveau_final(a_line).gco_long_description
                                                              , null
                                                              ,   --ex commentaire
                                                                outreqid
                                                               );
      end if;
    end if;

    if     tableau_niveau_final(a_line).qte_besoin_net > 0
       and v_err = 0 then
      insert into gal_project_calc_result
                  (gal_project_calc_result_id
                 , gal_task_id
                 , gal_good_id
                 , fal_supply_request_id
                 , doc_document_id
                 , doc_position_id
                 , doc_position_detail_id
                 , fal_doc_prop_id
                 , fal_lot_prop_id
                 , fal_lot_id
                 , gal_pcr_qty
                 , gal_pcr_remaining_qty
                 , gal_pcr_comment
                 , gal_pcr_sort
                 , a_idcre
                 , a_datecre
                  )
           values (gal_project_calc_result_id_seq.nextval
                 , tableau_niveau_final(a_line).tache_id
                 , tableau_niveau_final(a_line).article_id
                 , outreqid
                 , outdocumentid
                 , outpositionid
                 , outpositionid
                 , ResPropDocId
                 , null
                 , null
                 , tableau_niveau_final(a_line).qte_besoin_net
                 , 0
                 ,   --remaining qty
                   (select pcs.pc_functions.translateword('Approvisionnements')
                      from dual)
                 , '4'
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );
    end if;
  end generate_supply_request;

--*******************************************************************************************************--
  procedure generate_supply_manufacture(a_line in number)
  is
    v_StartDate GAL_TASK.TAS_START_DATE%type;
    v_EndDate   GAL_TASK.TAS_END_DATE%type;
    lnTacID     GAL_TASK.GAL_TASK_ID%type;
  begin
    select decode(v_calc_df
                , 1, gal_project_calculation.GetDecalageForward(tableau_niveau_final(a_line).dat_besoin_net, 0)
                , decode(v_planif_df, 0, null, gal_project_calculation.GetDecalageForward(tableau_niveau_final(a_line).dat_besoin_net, 0) )
                 )
      into v_StartDate
      from dual;

    select decode(v_calc_df
                , 1, gal_project_calculation.GetDecalageBackward(tableau_niveau_final(a_line).dat_besoin_net, tableau_niveau_final(a_line).del_besoin_man)
                , decode(v_planif_df
                       , 0, null
                       , gal_project_calculation.GetDecalageBackward(tableau_niveau_final(a_line).dat_besoin_net, tableau_niveau_final(a_line).del_besoin_man)
                        )
                 )
      into v_EndDate
      from dual;

    gal_project_manufacture.generate_task_of_manufacture(iProjectID      => tableau_niveau_final(a_line).affaire_id
                                                       , iTaskCategID    => tableau_niveau_final(a_line).tac_cat_id
                                                       , iBudgetID       => tableau_niveau_final(a_line).bud_id
                                                       , iFatherTaskID   => tableau_niveau_final(a_line).tache_id
                                                       , ioManufTaskID   => lnTacID
                                                       , iGsmNomPath     => tableau_niveau_final(a_line).gsm_nom_path
                                                       , iGoodID         => tableau_niveau_final(a_line).article_id
                                                       , iSupplyMode     => null
                                                       , iTaskGoodID     => tableau_niveau_final(a_line).task_good_id
                                                       , iEndDate        => v_StartDate
                                                       , iStartDate      => v_EndDate
                                                       , iNomHeaderID    => nvl(tableau_niveau_final(a_line).pps_nom_header
                                                                              , tableau_niveau_final(a_line).article_id
                                                                               )
                                                        );

    if (v_planif_df = 1) then   -- or v_calc_df = 1)
      v_flag_new_df  := 'O';
    end if;

    if tableau_niveau_final(a_line).qte_besoin_net > 0 then
      insert into gal_project_calc_result
                  (gal_project_calc_result_id
                 , gal_task_id
                 , gal_good_id
                 , fal_supply_request_id
                 , doc_document_id
                 , doc_position_id
                 , doc_position_detail_id
                 , fal_doc_prop_id
                 , fal_lot_prop_id
                 , fal_lot_id
                 , gal_manufacture_task_id
                 , gal_pcr_qty
                 , gal_pcr_remaining_qty
                 , gal_pcr_comment
                 , gal_pcr_sort
                 , a_idcre
                 , a_datecre
                  )
           values (gal_project_calc_result_id_seq.nextval
                 , tableau_niveau_final(a_line).tache_id
                 , tableau_niveau_final(a_line).article_id
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , lnTacID
                 , tableau_niveau_final(a_line).qte_besoin_net
                 , 0
                 ,   --remaining qty
                   (select pcs.pc_functions.translateword('Dossier de fabrication')
                      from dual) ||
                   ' ' ||
                   FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GAL_TASK', 'TAS_CODE', lnTacID)
                 , '6'
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );
    end if;
  end;

--*******************************************************************************************************--
  procedure generate_componant_manufacture(a_line in number)
  is
    v_use_ini   varchar2(5);
    OutNumberID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    OutNumber   DOC_DOCUMENT.DMT_NUMBER%type;
    v_NextSeq   number;
  begin
    /*Numerotation auto*/
    v_NextSeq  := 0;

    begin
      select trim(substr(tableau_niveau_final(a_line).df_to_use_for_csant, 2, instr(tableau_niveau_final(a_line).df_to_use_for_csant, ';') - 1) )
        into OutNumberID
        from dual;   --On reporte toute la quantité de besoin sur le 1er DF trouvé (+ tard maybe calcul sur prorata des Qte du compose par DF)

      begin
        select TAS_CODE
          into OutNumber
          from GAL_TASK
         where GAL_TASK_ID = OutNumberID;

        if OutNumber is not null then
          begin
            select nvl(max(GML_SEQUENCE), 0)
              into v_NextSeq
              from GAL_TASK_GOOD
             where GAL_TASK_ID = OutNumberID;
          exception
            when no_data_found then
              v_NextSeq  := 0;
          end;

          select PCS.PC_I_LIB_SESSION.GetUserIni
            into v_use_ini
            from dual;

          gal_project_manufacture.insert_manufacture_good(   --**Genere Composants DF
                                                          OutNumberID
                                                        ,   --**a_tac_id
                                                          tableau_niveau_final(a_line).article_id
                                                        ,   --**a_good_id
                                                          tableau_niveau_final(a_line).task_good_id
                                                        ,   --**a_task_good_id
                                                          nvl(tableau_niveau_final(a_line).pps_nom_header, tableau_niveau_final(a_line).article_id)
                                                        ,   --**a_pps_nomen_header_id
                                                          tableau_niveau_final(a_line).gsm_nom_path
                                                        ,   --**a_gsm_nom_path
                                                          '1'
                                                        ,   --**a_project_supply_mode
                                                          v_NextSeq
                                                        , v_use_ini
                                                         );

          if tableau_niveau_final(a_line).qte_besoin_net > 0 then
            insert into gal_project_calc_result
                        (gal_project_calc_result_id
                       , gal_task_id
                       , gal_good_id
                       , fal_supply_request_id
                       , doc_document_id
                       , doc_position_id
                       , doc_position_detail_id
                       , fal_doc_prop_id
                       , fal_lot_prop_id
                       , fal_lot_id
                       , gal_pcr_qty
                       , gal_pcr_remaining_qty
                       , gal_pcr_comment
                       , gal_pcr_sort
                       , a_idcre
                       , a_datecre
                        )
                 values (gal_project_calc_result_id_seq.nextval
                       , tableau_niveau_final(a_line).tache_id
                       , tableau_niveau_final(a_line).article_id
                       , null
                       , null
                       , null
                       , null
                       , null
                       , null
                       , null
                       , tableau_niveau_final(a_line).qte_besoin_net
                       , 0
                       ,   --remaining qty
                         (select pcs.pc_functions.translateword('Dossier de fabrication')
                            from dual) || ' ' || OutNumber
                       , '6'
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                       , sysdate
                        );
          end if;
        end if;
      exception
        when no_data_found then
          null;
      end;
    exception
      when no_data_found then
        null;
    end;
  end;

--*******************************************************************************************************--
  procedure generate_supply_lot(a_line in number)
  is
    ResPropId               FAL_LOT_PROP.FAL_LOT_PROP_ID%type;
    v_compteur              fal_supply_request.fsr_number%type;
    outreqid                fal_supply_request.fal_supply_request_id%type;
    v_fal_supply_request_id fal_supply_request.fal_supply_request_id%type;
  begin
    outreqid                 := null;
    ResPropId                := null;
    v_fal_supply_request_id  := null;

    -- Config Fabrication : 1 Sur Dossier de fabrication
    -- Config Fabrication : 2 POF
    -- Config Fabrication : 3 DA
    if v_manufacturing_mode = 3 then
      /*Anciennement Methode Generation DA...*/
      generate_supply_request(a_line, 3);
    else   --On garde temporairement une DA pour que le calcaul de besoin régénératif ne supprime pas les POx
      begin
        select fal_supply_request_id
          into v_fal_supply_request_id
          from fal_supply_request
         where doc_record_id = tableau_niveau_final(a_line).doc_record_id
           and rownum = 1;
      exception
        when no_data_found then
          select lpad(nvl(max(to_number(fsr.fsr_number) ), 0) + 1, 6, '0')
            into v_compteur
            from fal_supply_request fsr;

          fal_supply_request_functions.updatesupplyrequestproject(tableau_niveau_final(a_line).article_id
                                                                , tableau_niveau_final(a_line).doc_record_id
                                                                , v_compteur
                                                                ,   --ex numero d'OA
                                                                  substr(tableau_niveau_final(a_line).gco_short_description, 1, 50)
                                                                ,   --ex libelle d'OA
                                                                  tableau_niveau_final(a_line).qte_besoin_net
                                                                , tableau_niveau_final(a_line).dat_besoin_net
                                                                , tableau_niveau_final(a_line).gco_long_description
                                                                , null
                                                                ,   --ex commentaire
                                                                  outreqid
                                                                 );

          --Mise au statut refusée...
          update fal_supply_request
             set c_request_status = '2'
               , fsr_validate_date = sysdate
           where fal_supply_request_id = outreqid;

          v_fal_supply_request_id  := outreqid;
          outreqid                 := null;
      end;   /*Anciennement Methode Generation DA...*/

      gal_pox_generate.CreatePropApproFab(tableau_niveau_final(a_line).article_id
                                        , tableau_niveau_final(a_line).dat_besoin_net
                                        , tableau_niveau_final(a_line).qte_besoin_net
                                        , tableau_niveau_final(a_line).doc_record_id
                                        , '2'
                                        ,   --Fab
                                          v_stm_stock_id_project
                                        , v_stm_location_id_project
                                        , tableau_niveau_final(a_line).pps_nomenclature_id
                                        , tableau_niveau_final(a_line).gsm_nom_path
                                        , tableau_niveau_final(a_line).task_good_id
                                        , tableau_niveau_final(a_line).pps_nom_header
                                        , v_fal_supply_request_id
                                        , ResPropId
                                         );

      /*
      DBMS_OUTPUT.PUT_LINE('FAL_LOT_PROP ' || to_char(tableau_niveau_final (a_line).article_id)
         || ' - ' || to_char(tableau_niveau_final (a_line).dat_besoin_net,'DD/MM/YYYY')
         || ' - ' || to_char(tableau_niveau_final (a_line).qte_besoin_net)
         || ' - ' || to_char(tableau_niveau_final (a_line).doc_record_id)
         || ' - ' || tableau_niveau_final (a_line).ggo_supply_mode
         || ' - ' || to_char(v_stm_stock_id_project)
         || ' - ' || to_char(v_stm_location_id_project)
         || ' - ' || to_char(tableau_niveau_final (a_line).pps_nomenclature_id)
         || ' - ' || to_char(ResPropId));
      */
      if tableau_niveau_final(a_line).qte_besoin_net > 0 then
        insert into gal_project_calc_result
                    (gal_project_calc_result_id
                   , gal_task_id
                   , gal_good_id
                   , fal_supply_request_id
                   , doc_document_id
                   , doc_position_id
                   , doc_position_detail_id
                   , fal_doc_prop_id
                   , fal_lot_prop_id
                   , fal_lot_id
                   , gal_pcr_qty
                   , gal_pcr_remaining_qty
                   , gal_pcr_comment
                   , gal_pcr_sort
                   , a_idcre
                   , a_datecre
                    )
             values (gal_project_calc_result_id_seq.nextval
                   , tableau_niveau_final(a_line).tache_id
                   , tableau_niveau_final(a_line).article_id
                   , outreqid
                   , null
                   , null
                   , null
                   , null
                   , ResPropId
                   , null
                   , tableau_niveau_final(a_line).qte_besoin_net
                   , 0
                   ,   --remaining qty
                     (select pcs.pc_functions.translateword('Approvisionnements')
                        from dual)
                   , '4'
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                   , sysdate
                    );
      end if;
    end if;
  end generate_supply_lot;

--*******************************************************************************************************--
  procedure load_resource(aTaskId gal_task.gal_task_id%type, aDocRecordId doc_record.doc_record_id%type, a_typ varchar2   --0:Tache 1:Affaire 2:Budget
                                                                                                                       )
  is
  begin
    --****** APPROS sur FAL_SUPPLY_REQUEST (C_REQUEST_STATUS = '1', '2') ******--
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_sort
               , pjr_comment
               , gal_manufacture_task_id
                )
      select fsr_number ||
             ' ' ||
             COM_FUNCTIONS.GETDESCODEDESCR('C_REQUEST_STATUS', FAL_SUPPLY_REQUEST.C_REQUEST_STATUS, to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) )
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , fal_supply_request.gco_good_id
           , fsr_asked_qty
           , fsr_asked_qty
           , fsr_delay
           , 0
           , 0
           , null
           , null
           , fal_supply_request.fal_supply_request_id
           , null
           , null
           , null
           , null
           , null
           , null
           , '5OA'
           , PAC_PERSON.PER_NAME
           , (select T1.GAL_TASK_ID
                from GAL_TASK T1
               where T1.DOC_RECORD_ID = fal_supply_request.doc_record_id
                 and T1.GAL_FATHER_TASK_ID is not null)
        from gco_good
           , fal_supply_request
           , pac_person
       where pac_person.PAC_PERSON_ID(+) = fal_supply_request.PAC_SUPPLIER_PARTNER_ID
         and gco_good.gco_good_id = fal_supply_request.gco_good_id
         --and fal_supply_request.doc_record_id = aDocRecordId
         and (   fal_supply_request.doc_record_id = aDocRecordId
              or fal_supply_request.doc_record_id in(select doc_record_id
                                                       from gal_task
                                                      where gal_father_task_id = aTaskId) )
         and C_REQUEST_STATUS = '1';

    --****** APPROS sur Documents    --***********************************************************************************
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date   --!!!!checker cette date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_position_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , gal_manufacture_task_id
               , pjr_sort
               , pjr_comment
               , doc_gauge_id
                )
      select dmt_number ||
             ' [' ||
             trim(to_char(pos_number) ) ||
             '] ' ||
             COM_FUNCTIONS.GETDESCODEDESCR('C_DOCUMENT_STATUS', DOC_DOCUMENT.C_DOCUMENT_STATUS, to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) )
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , doc_position_detail.gco_good_id
           , decode(doc_gauge_structured.dic_project_consol_1_id
                  , '1', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , '3', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF QTE APPRO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '1', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , '3', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF_QTE_RESTANTE APPRO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '1', nvl(pde_final_delay, nvl(doc_document.dmt_date_value, doc_document.dmt_date_document) )
                  , '3', nvl(pde_final_delay, nvl(doc_document.dmt_date_value, doc_document.dmt_date_document) )
                  , null
                   )
           ,   --PJR_DATE APPRO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '2', round(PDE_FINAL_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF QTE DISPO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '2', round(PDE_FINAL_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF_QTE_RESTANTE DISPO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '2', nvl(pde_final_delay, nvl(doc_document.dmt_date_value, doc_document.dmt_date_document) )
                  , null
                   )
           ,   --PJR_DATE DISPO
             null
           , null
           , doc_position_detail_id
           , doc_position_detail.doc_position_id
           , doc_position_detail.doc_document_id
           , null
           , null
           , null
           , null
           , (select T1.GAL_TASK_ID
                from GAL_TASK T1
               where T1.DOC_RECORD_ID = doc_position.doc_record_id)
           , decode(   --Initialisé pour que cela fonctionne depuis le suivi matière sur Dossier Fab
                    (select nvl(gal_father_task_id, 0)
                       from gal_task
                      where doc_record_id = aDocRecordId)
                  , 0, decode(doc_gauge.c_admin_domain
                            , '3', decode(doc_gauge_structured.dic_project_consol_1_id, '1', '3BA', '3', '3BA', '2BA')
                            , decode(doc_gauge_structured.dic_project_consol_1_id, '1', '3CF', '3', '3CF', '2CF')
                             )
                  , decode(doc_gauge.c_admin_domain, '3', decode(doc_gauge_structured.dic_project_consol_1_id, '1', '6DB', '3', '6DB', '6AF'), '6DA')
                   )
           , PAC_PERSON.PER_NAME
           , DOC_GAUGE.doc_gauge_id
        from pac_person
           , gco_good
           , doc_position_detail
           , doc_position
           , doc_document
           , doc_gauge_structured
           , doc_gauge
       where pac_person.pac_person_id(+) = doc_document.pac_third_id
         and gco_good.gco_good_id = doc_position_detail.gco_good_id
         and (    (    doc_position_detail.pde_balance_quantity <> 0
                   and doc_gauge_structured.dic_project_consol_1_id in('1', '3') )   --APPRO
              or (    doc_position_detail.pde_final_quantity <> 0
                  and doc_gauge_structured.dic_project_consol_1_id in('2') )
             )   --DISPO
         and doc_position_detail.doc_position_id = doc_position.doc_position_id
         and doc_position.doc_document_id = doc_document.doc_document_id
         and (   doc_gauge_structured.dic_project_consol_1_id in('1', '2')   --gabarit configuré appro (appro affaire)
              or (    doc_gauge_structured.dic_project_consol_1_id in('3')
                  and c_document_status = '01')
             )
         and doc_gauge_structured.doc_gauge_id(+) = doc_gauge.doc_gauge_id
         and doc_gauge.doc_gauge_id = doc_document.doc_gauge_id
         and (doc_position.doc_record_id = aDocRecordId)
         -- or doc_document.doc_record_id = aDocRecordId) --position prend le dessus mais peut etre vide alors doc_record_id de doc_document (et multi doc_record_id sur les position....)
         and c_doc_pos_status <> '05';   --non selection des doc. annulés

    --****** APPROS sur document DF   --***********************************************************************************
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date   --!!!!checker cette date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_position_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , gal_manufacture_task_id
               , pjr_sort
               , pjr_comment
               , doc_gauge_id
                )
      select dmt_number ||
             ' [' ||
             trim(to_char(pos_number) ) ||
             '] ' ||
             COM_FUNCTIONS.GETDESCODEDESCR('C_DOCUMENT_STATUS', DOC_DOCUMENT.C_DOCUMENT_STATUS, to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) )
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , doc_position_detail.gco_good_id
           , decode(doc_gauge_structured.dic_project_consol_1_id
                  , '1', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , '3', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF QTE APPRO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '1', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , '3', round(PDE_BALANCE_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF_QTE_RESTANTE APPRO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '1', nvl(pde_final_delay, nvl(doc_document.dmt_date_value, doc_document.dmt_date_document) )
                  , '3', nvl(pde_final_delay, nvl(doc_document.dmt_date_value, doc_document.dmt_date_document) )
                  , null
                   )
           ,   --PJR_DATE APPRO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '2', round(PDE_FINAL_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF QTE DISPO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '2', round(PDE_FINAL_QUANTITY * DOC_POSITION.POS_CONVERT_FACTOR, GCO_GOOD.GOO_NUMBER_OF_DECIMAL)
                  , 0
                   )
           ,   --RAF_QTE_RESTANTE DISPO
             decode(doc_gauge_structured.dic_project_consol_1_id
                  , '2', nvl(pde_final_delay, nvl(doc_document.dmt_date_value, doc_document.dmt_date_document) )
                  , null
                   )
           ,   --PJR_DATE DISPO
             null
           , null
           , doc_position_detail_id
           , doc_position_detail.doc_position_id
           , doc_position_detail.doc_document_id
           , null
           , null
           , null
           , null
           , (select T1.GAL_TASK_ID
                from GAL_TASK T1
               where T1.DOC_RECORD_ID = doc_position.doc_record_id)
           , decode(doc_gauge.c_admin_domain
                  , '3',   /*
                           decode(doc_gauge.gau_describe,(SELECT pcs.pc_config.getconfig ('GAL_GAUGE_SUPPLY_MANUFACTURE') FROM DUAL)
                                                            ,decode(doc_gauge_structured.dic_project_consol_1_id,'1','6DH'
                                                                                                                ,'3','6DH'
                                                                                                                ,'6AH') --type Appro fab
                                                            ,decode(doc_gauge_structured.dic_project_consol_1_id,'1','6DB'
                                                                                                                ,'3','6DB'
                                                                                                                ,'6AF') --type Besoin st
                                 )
                           */
                           /*
                           decode(doc_gauge.c_gauge_type,'2',decode(doc_gauge_structured.dic_project_consol_1_id,'1','6DH'
                                                                                                                ,'3','6DH'
                                                                                                                ,'6AH') --type Appro fab
                                                            ,decode(doc_gauge_structured.dic_project_consol_1_id,'1','6DB'
                                                                                                                ,'3','6DB'
                                                                                                                ,'6AF') --type Besoin st
                                 )
                           */
                    decode(doc_gauge_structured.dic_project_consol_1_id, '1', '6DB', '3', '6DB', '6AF')
                  , '6DA'
                   )
           ,   --RAF QTE APPRO OU DISPO
             PAC_PERSON.PER_NAME
           , DOC_GAUGE.doc_gauge_id
        from pac_person
           , gco_good
           , doc_position_detail
           , doc_position
           , doc_document
           , doc_gauge_structured
           , doc_gauge
       where pac_person.pac_person_id(+) = doc_document.pac_third_id
         and gco_good.gco_good_id = doc_position_detail.gco_good_id
         and doc_position_detail.doc_position_id = doc_position.doc_position_id
         and (    (    doc_position_detail.pde_balance_quantity <> 0
                   and doc_gauge_structured.dic_project_consol_1_id in('1', '3') )   --APPRO
              or (    doc_position_detail.pde_final_quantity <> 0
                  and doc_gauge_structured.dic_project_consol_1_id in('2') )
             )   --DISPO
         and doc_position.doc_document_id = doc_document.doc_document_id
         and (   doc_gauge_structured.dic_project_consol_1_id in('1', '2')   --gabarit configuré appro (appro affaire)
              or (    doc_gauge_structured.dic_project_consol_1_id in('3')
                  and c_document_status = '01')
             )
         and doc_gauge_structured.doc_gauge_id(+) = doc_gauge.doc_gauge_id
         and doc_gauge.doc_gauge_id = doc_document.doc_gauge_id
         and (doc_position.doc_record_id in(select doc_record_id
                                              from gal_task
                                             where gal_father_task_id = aTaskId) )
         -- or doc_document.doc_record_id IN (select doc_record_id from gal_task where gal_father_task_id = aTaskId))
         and c_doc_pos_status <> '05'
         and a_typ = '0';   --0:tache

    --****** DISPO sur mvts de stock (STM_STOCK_MOUVEMENT), sauf mvts sur stock affaire et mvts sur DOC/OF  --********
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date   --!!!!checker cette date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date   --!!!!checker cette date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_sort
                )
      select   --stm_movement_kind.mok_abbreviation,
             COM_FUNCTIONS.GETDESCODEDESCR('C_MOVEMENT_SORT', STM_MOVEMENT_KIND.C_MOVEMENT_SORT, pcs.PC_I_LIB_SESSION.GetUserLangId) ||
             '/' ||
             COM_FUNCTIONS.GETDESCODEDESCR('C_MOVEMENT_TYPE', STM_MOVEMENT_KIND.C_MOVEMENT_TYPE, pcs.PC_I_LIB_SESSION.GetUserLangId)
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , stm_stock_movement.gco_good_id
           , 0
           , 0
           , null
           , decode(stm_movement_kind.c_movement_sort
                  , 'SOR',(case
                       when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                       when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                     end
                    )
                  , 'ENT',(case
                       when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                       when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                     end
                    )
                   )
           , decode(stm_movement_kind.c_movement_sort
                  , 'SOR',(case
                       when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                       when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                     end
                    )
                  , 'ENT',(case
                       when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                       when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                     end
                    )
                   )
           , SMO_MOVEMENT_DATE
           , null
           , null
           , null
           , null
           , stm_stock_movement_id
           , null
           , null
           , null
           , '1SM'
        from gco_good
           , stm_movement_kind
           , stm_stock_movement
       where gco_good.gco_good_id = stm_stock_movement.gco_good_id
         --and stm_stock_movement.doc_record_id = aDocRecordId
         and (   stm_stock_movement.doc_record_id = aDocRecordId
              or stm_stock_movement.doc_record_id in(select doc_record_id
                                                       from gal_task
                                                      where gal_father_task_id = aTaskId) )
         and stm_movement_kind.stm_movement_kind_id = stm_stock_movement.stm_movement_kind_id
         and stm_movement_kind.c_movement_sort in('SOR', 'ENT')
         and stm_stock_movement.doc_position_id is null
         and stm_stock_movement.doc_position_detail_id is null
         and stm_movement_kind.c_movement_type not in('DOC', 'TRD', 'FAC', 'TRF', 'EXE');   --que les mouvements hors Doc et Hors OF

    --****** DISPO STOCK AFFAIRE > DETAIL STM_STOCK_MOUVEMENT !!!!!! --********
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_sort
               , pjr_comment
                )
      select (select pcs.pc_functions.translateword('Mouvements de stock')
                from dual)
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , gco_good_id
           , 0
           , 0
           , SUM_AVAILABLE
           , SUM_REMAINING_AVAILABLE
           , MAX_DATE_MVT
           , '1ST'
           , (select STO_DESCRIPTION
                from STM_STOCK
               where STM_STOCK.STM_STOCK_ID = stm_id)
        from (select   gco_good_id
                     , stm_sto_id stm_id
                     , sum(SMO_MVT_QT_AVAILABLE) SUM_AVAILABLE
                     , sum(SMO_MVT_QT_REMAINING_AVAILABLE) SUM_REMAINING_AVAILABLE
                     , max(SMO_MOVEMENT_DATE) MAX_DATE_MVT
                  from (select stm_stock_movement.gco_good_id
                             , stm_stock_movement.stm_stock_id stm_sto_id
                             , decode(stm_movement_kind.c_movement_sort
                                    , 'SOR',(case
                                         when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                                         when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                                       end
                                      )
                                    , 'ENT',(case
                                         when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                                         when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                                       end
                                      )
                                     ) SMO_MVT_QT_AVAILABLE
                             , decode(stm_movement_kind.c_movement_sort
                                    , 'SOR',(case
                                         when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                                         when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                                       end
                                      )
                                    , 'ENT',(case
                                         when stm_stock_movement.stm_stock_id <> v_stm_stock_id_project then 0 - SMO_MOVEMENT_QUANTITY
                                         when stm_stock_movement.stm_stock_id = v_stm_stock_id_project then SMO_MOVEMENT_QUANTITY
                                       end
                                      )
                                     ) SMO_MVT_QT_REMAINING_AVAILABLE
                             , SMO_MOVEMENT_DATE
                          from stm_stock
                             , gco_good
                             , stm_movement_kind
                             , stm_stock_movement
                         where stm_stock.stm_stock_id = stm_stock_movement.stm_stock_id
                           and gco_good.gco_good_id = stm_stock_movement.gco_good_id
                           --and stm_stock_movement.doc_record_id = aDocRecordId
                           and (   stm_stock_movement.doc_record_id = aDocRecordId
                                or stm_stock_movement.doc_record_id in(select doc_record_id
                                                                         from gal_task
                                                                        where gal_father_task_id = aTaskId) )
                           and stm_movement_kind.stm_movement_kind_id = stm_stock_movement.stm_movement_kind_id
                           and stm_movement_kind.c_movement_sort in('SOR', 'ENT')
                           and stm_stock_movement.doc_position_id is null
                           and stm_stock_movement.doc_position_detail_id is null
                           and stm_movement_kind.c_movement_type not in('DOC', 'TRD', 'FAC', 'TRF', 'EXE')   --que les mouvements hors Doc et Hors OF
                                                                                                          )
              group by gco_good_id
                     , stm_sto_id);

    --****** Proposition AOA/AOF --*********
    --****** > AOA
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_sort
               , pjr_comment
               , gal_manufacture_task_id
                )
      select FAL_DOC_PROP.C_PREFIX_PROP || fdp_number
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , fal_doc_prop.gco_good_id   --, round(fdp_final_qty*nvl(CDA_CONVERSION_FACTOR,1) , nvl(CDA_NUMBER_OF_DECIMAL,50)) --> fdp_final_qty
                                        --, round(fdp_final_qty*nvl(CDA_CONVERSION_FACTOR,1) , nvl(CDA_NUMBER_OF_DECIMAL,50)) --> fdp_final_qty
           , (select ACS_FUNCTION.RoundNear(fdp_final_qty * nvl(FDP_CONVERT_FACTOR, 1), 1 / power(10, nvl(GCO_GOOD.GOO_NUMBER_OF_DECIMAL, 50) ), 0)
                from dual)   --> fdp_final_qty
           , (select ACS_FUNCTION.RoundNear(fdp_final_qty * nvl(FDP_CONVERT_FACTOR, 1), 1 / power(10, nvl(GCO_GOOD.GOO_NUMBER_OF_DECIMAL, 50) ), 0)
                from dual)   --> fdp_final_qty
           , fdp_final_delay
           , 0
           , 0
           , null
           , null
           , null
           , null
           , null
           , null
           , fal_doc_prop_id
           , null
           , null
           , decode(   --Initialisé pour que cela fonctionne depuis le suivi matière sur Dossier Fab
                    (select nvl(gal_father_task_id, 0)
                       from gal_task
                      where doc_record_id = fal_doc_prop.doc_record_id)
                  , 0, '4PA'   --sur tache
                  , '4PB'
                   )   --sur DF
           , per_name
           , (select T1.GAL_TASK_ID
                from GAL_TASK T1
               where T1.DOC_RECORD_ID = fal_doc_prop.doc_record_id)
        from gco_good
           , pac_person
           , fal_doc_prop   --gco_compl_data_purchase,
       where gco_good.gco_good_id = fal_doc_prop.gco_good_id
         --gco_compl_data_purchase.GCO_GOOD_ID (+) = fal_doc_prop.gco_good_id
         --and gco_compl_data_purchase.pac_supplier_partner_id (+) = fal_doc_prop.pac_supplier_partner_id
         --and doc_record_id = aDocRecordId
         and pac_person.pac_person_id(+) = fal_doc_prop.PAC_SUPPLIER_PARTNER_ID
         and (   doc_record_id = aDocRecordId
              or doc_record_id in(select doc_record_id
                                    from gal_task
                                   where gal_father_task_id = aTaskId) );

    --****** > AOF
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_sort
                )
      select FAL_LOT_PROP.C_PREFIX_PROP || lot_number
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , fal_lot_prop.gco_good_id
           , lot_total_qty
           , lot_total_qty
           , lot_plan_end_dte
           , 0
           , 0
           , null
           , null
           , null
           , null
           , null
           , null
           , null
           , fal_lot_prop_id
           , null
           , '4PF'
        from gco_good
           , fal_lot_prop
       where gco_good.gco_good_id = fal_lot_prop.gco_good_id
         --and doc_record_id = aDocRecordId
         and (   doc_record_id = aDocRecordId
              or doc_record_id in(select doc_record_id
                                    from gal_task
                                   where gal_father_task_id = aTaskId) );

    --****** APPROS sur OF  --******************************
    --fal_job_program  > n fal_order > n fal_lot
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_sort
                )
      select lot_refcompl || ' ' || COM_FUNCTIONS.GETDESCODEDESCR('C_LOT_STATUS', FAL_LOT.C_LOT_STATUS, to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) )
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , gco_good_id
           , lot_inprod_qty
           , lot_inprod_qty
           , lot_plan_end_dte
           , 0
           , 0
           , null
           , null
           , null
           , null
           , null
           , null
           , null
           , null
           , fal_lot_id
           , '3OF'
        from fal_lot
       where   --doc_record_id = aDocRecordId
             (   doc_record_id = aDocRecordId
              or doc_record_id in(select doc_record_id
                                    from gal_task
                                   where gal_father_task_id = aTaskId) )
         and fal_lot.c_lot_status in('1', '2', '4');

    -- and fal_lot.doc_record_id = a_doc_record_id --avec doc_record_id dans fal_lot ou fal_order ou fal_job_program (multi doc_record_id sur les sous-entités)

    --****** DISPO sur OF via mvts de réception fabrication (STM_STOCK_MOVEMENT)  --********
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date   --!!!!checker cette date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date   --!!!!checker cette date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_sort
                )
      select smo_wording || ' ' || COM_FUNCTIONS.GETDESCODEDESCR('C_LOT_STATUS', FAL_LOT.C_LOT_STATUS, to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) )
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , stm_stock_movement.gco_good_id
           , 0
           , 0
           , null
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_DATE
           , null
           , null
           , null
           , null
           , null
           , null
           , null
           , FAL_LOT.FAL_LOT_ID
           , '2OF'
        from stm_movement_kind
           , stm_stock_movement
           , fal_lot
       where   --stm_stock_movement.doc_record_id = aDocRecordId
             (   stm_stock_movement.doc_record_id = aDocRecordId
              or stm_stock_movement.doc_record_id in(select doc_record_id
                                                       from gal_task
                                                      where gal_father_task_id = aTaskId)
             )
         and stm_movement_kind.stm_movement_kind_id = stm_stock_movement.stm_movement_kind_id
         and fal_lot.lot_refcompl = stm_stock_movement.smo_wording   -- Jointure sur libellé mvt car stm_stock_movement.fal_lot_id pas implémenté
         and stm_movement_kind.c_movement_code = '020'   -- que les mvts de réception fabrication
         and stm_movement_kind.c_movement_type in('FAC', 'TRF');   --que les mouvements sur OF

    --****** REBUTS DE FAB (pour augmenter la qté à induire --********
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date   --!!!!checker cette date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , pjr_available_date
               , pjr_minimum_need_date   --!!!!checker cette date
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , stm_stock_movement_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_sort
                )
      select   --stm_movement_kind.mok_abbreviation,
             COM_FUNCTIONS.GETDESCODEDESCR('C_MOVEMENT_SORT', STM_MOVEMENT_KIND.C_MOVEMENT_SORT, pcs.PC_I_LIB_SESSION.GetUserLangId) ||
             '/' ||
             COM_FUNCTIONS.GETDESCODEDESCR('C_MOVEMENT_TYPE', STM_MOVEMENT_KIND.C_MOVEMENT_TYPE, pcs.PC_I_LIB_SESSION.GetUserLangId)
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , stm_stock_movement.gco_good_id
           , 0
           , 0
           , null
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_DATE
           , null
           , null
           , null
           , null
           , stm_stock_movement_id
           , null
           , null
           , null
           , '1RB'
        from gco_good
           , stm_movement_kind
           , stm_stock_movement
       where gco_good.gco_good_id = stm_stock_movement.gco_good_id
         --and stm_stock_movement.doc_record_id = aDocRecordId
         and (   stm_stock_movement.doc_record_id = aDocRecordId
              or stm_stock_movement.doc_record_id in(select doc_record_id
                                                       from gal_task
                                                      where gal_father_task_id = aTaskId) )
         and stm_movement_kind.stm_movement_kind_id = stm_stock_movement.stm_movement_kind_id
         and stm_movement_kind.c_movement_code = '023';   --RELU EN 1 GRACE A OPERATUER MAJ

    /*APPRO DOSSIER FABRICATION*/
    --****** > Dossier Fab non lancé
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date
               , pjr_minimum_need_date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , gal_manufacture_task_id
               , pjr_sort
                )
      select Code
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , gco_goodid
           , sum_qty
           , sum_qty
           , DateEnd
           , DateStart
           , 0
           , 0
           , gal_task_id
           , '6DI'
        from (select   tas_code || ' - ' || (select pcs.pc_functions.translateword('A lancer')
                                               from dual) Code
                     , aTaskId aTaskId
                     , gal_task_lot.gco_good_id gco_goodid
                     , sum(gtl_quantity) -
                       nvl( (select sum(nvl(RES.pjr_remaining_quantity, 0) + nvl(RES.pjr_available_remaining_quanti, 0) )
                               from GAL_PROJECT_RESOURCE RES
                              where RES.GAL_MANUFACTURE_TASK_ID = gal_task_lot.gal_task_id
                                and RES.GAL_GOOD_ID = gal_task_lot.gco_good_id
                                and (   RES.doc_gauge_id = v_GAL_GAUGE_SUPPLY_MANUFACTURE
                                     or RES.doc_gauge_id = V_GAL_GAUGE_ENTRY_MANUFACTURE) )
                         , 0
                          ) sum_qty   --On enleve les appros sur Doc
                     , tas_end_date DateEnd
                     , tas_start_date DateStart
                     , gal_task_lot.gal_task_id gal_task_id
                     , gal_task.doc_record_id doc_record_id
                  from gal_task_lot
                     , gal_task
                 where gal_task_lot.gal_task_id = gal_task.gal_task_id
                   and gal_task.gal_father_task_id = aTaskId
                   and gal_task.c_tas_state <> '40'
                   and a_typ = '0'   --type tache
              group by tas_code
                     , C_TAS_STATE
                     , gal_task_lot.gco_good_id
                     , tas_end_date
                     , tas_start_date
                     , gal_task_lot.gal_task_id
                     , gal_task.doc_record_id);

    --A Voir si integre les composant DF en ressource
    insert into gal_project_resource
                (pjr_number
               , gal_project_resource_id
               , gal_task_id
               , gal_good_id
               , pjr_quantity
               , pjr_remaining_quantity
               , pjr_date
               , pjr_available_quantity
               , pjr_available_remaining_quanti
               , gal_manufacture_task_id
               , pjr_sort
                )
      select Code
           , gal_project_resource_id_seq.nextval
           , aTaskId
           , gco_good_id
           , sum_qty
           , sum_qty
           , DateEnd
           , 0
           , 0
           , gal_task_id
           , '6DG'
        from (select   tas_code || ' - ' || (select pcs.pc_functions.translateword('A lancer')
                                               from dual) Code
                     , aTaskId aTaskId
                     , gal_task_good.gco_good_id gco_good_id
                     , sum(gml_quantity) -
                       nvl( (select sum(nvl(RES.pjr_remaining_quantity, 0) + nvl(RES.pjr_available_remaining_quanti, 0) )
                               from GAL_PROJECT_RESOURCE RES
                              where RES.GAL_MANUFACTURE_TASK_ID = gal_task_good.gal_task_id
                                and RES.GAL_GOOD_ID = gal_task_good.gco_good_id
                                and (   RES.doc_gauge_id = v_GAL_GAUGE_NEED_MANUFACTURE
                                     or RES.doc_gauge_id = V_GAL_GAUGE_OUTPUT_MANUFACTURE) )
                         , 0
                          ) sum_qty
                     , tas_end_date DateEnd
                     , gal_task_good.gal_task_id gal_task_id
                     , gal_task.doc_record_id doc_record_id
                  from gal_task_good
                     , gal_task
                 where gal_task_good.gal_task_id = gal_task.gal_task_id
                   and gal_task.gal_father_task_id = aTaskId
                   and gal_task.c_tas_state <> '40'
                   and a_typ = '0'   --type tache
              group by tas_code
                     , C_TAS_STATE
                     , gal_task_good.gco_good_id
                     , tas_end_date
                     , gal_task_good.gal_task_id
                     , gal_task.doc_record_id);

    if trim(v_GAL_PROC_LOAD_RESOURCES) is not null then
      -- execution de la commande
      sqlStatement  := 'BEGIN ' || trim(v_GAL_PROC_LOAD_RESOURCES) || '(:aTaskId,:aDocRecordId); END;';

      execute immediate sqlStatement
                  using in aTaskId, in aDocRecordId;
    end if;
  end load_resource;

  -- Hmo 10.2012
  -- màj des colonnes state1 à 6 de la table gal_need_follow_up pour intégration du suivi de détail sur la chaîne d'appro
  -- config sur le champ doc_gauge_structured.dic_doc_journal_5_id des gabarits pour les documemts
  procedure init_need_follow_appro_details(
    a_qte_dispo                       number
  , a_qte_util_sur_ress               number
  , a_supply_mode                     varchar2
  , a_supply_type                     varchar2
  , a_rfu_need_or_supply              varchar2
  , v_good_id                         number
  , v_quantity_state1          in out number
  , v_quantity_state2          in out number
  , v_quantity_state3          in out number
  , v_quantity_state4          in out number
  , v_quantity_state5          in out number
  , v_quantity_state6          in out number
  , v_stm_project_quantity_out in out number
  )
  --les variables v_quantity sont en in out pour mettre à jour également la table gal_ressource follow up
  is
    v_dic_doc_journal_5_id doc_gauge_structured.dic_doc_journal_5_id%type;
    v_gauge_id             doc_gauge.doc_gauge_id%type;
  begin
    -- si on est sur un document, on va cherche le gauge pour savoir sur quel gabarit on se trouve (besoin, affaire, sortie affaire, dossier fabrication) -> utiliser après
    if nvl(v_ress_doc_doc_id, 0) > 0 then
      select nvl(max(doc_gauge_id), 0)
        into v_gauge_id
        from gal_project_resource
       where doc_document_id = v_ress_doc_doc_id;
    end if;

    if a_qte_dispo = 0 then   -- qte_dispo = 0 les ressources sont utilisées pour de l'appro -> mise à jour des champs state 1 à 6
      case
        --Pour DA, POA, POF -> info en dur (pas de param possible) dans la colonne state1 -> a traiter
      when    nvl(v_ress_oac_id, 0) > 0   -- DA
           or nvl(v_ress_aoa_id, 0) > 0   -- POA
           or nvl(v_ress_aof_id, 0) > 0 then   -- POF
          update gal_need_follow_up
             set nfu_quantity_state1 = a_qte_util_sur_ress + nvl(nfu_quantity_state1, 0)
           where gal_need_follow_up_id = v_id;

          v_quantity_state1  := a_qte_util_sur_ress;
        when nvl(v_ress_doc_doc_id, 0) > 0 then
          -- on est sur un document appro (pas besoin affaire) pour le matériel affaire ou un document besion affaire pour le matériel stock
          -- on excclut les documenst DF, pour être sur le même fonctionnement que les OF (pas d'info dans les colonnes 1 à 6)
          if     a_supply_type <> 'S'
             and a_rfu_need_or_supply = 'S'
             and v_gal_gauge_supply_manufacture <> v_gauge_id then
            -- info de config sur le gabarit
            select nvl(max(dic_doc_journal_5_id), 0)
              into v_dic_doc_journal_5_id
              from doc_gauge_structured gas
                 , gal_project_resource gpr
             where gpr.doc_document_id = v_ress_doc_doc_id
               and gpr.doc_gauge_id = gas.doc_gauge_id;

            if v_dic_doc_journal_5_id > 0 then
              case
                when v_dic_doc_journal_5_id = 1 then
                  update gal_need_follow_up
                     set nfu_quantity_state1 = a_qte_util_sur_ress + nvl(nfu_quantity_state1, 0)
                   -- on additionne sur la table gal_need_follow_up, car un appro peut être composé de plusieurs documents (idem pour state 2 à 6)
                  where  gal_need_follow_up_id = v_id;

                  v_quantity_state1  := a_qte_util_sur_ress;   -- màj de la variable out pour mise à jour de gal_resource follow_up depuis la procédure appelante, idem state 2 à 6
                when v_dic_doc_journal_5_id = 2 then
                  update gal_need_follow_up
                     set nfu_quantity_state2 = a_qte_util_sur_ress + nvl(nfu_quantity_state2, 0)
                   where gal_need_follow_up_id = v_id;

                  v_quantity_state2  := a_qte_util_sur_ress;
                when v_dic_doc_journal_5_id = 3 then
                  update gal_need_follow_up
                     set nfu_quantity_state3 = a_qte_util_sur_ress + nvl(nfu_quantity_state3, 0)
                   where gal_need_follow_up_id = v_id;

                  v_quantity_state3  := a_qte_util_sur_ress;
                when v_dic_doc_journal_5_id = 4 then
                  update gal_need_follow_up
                     set nfu_quantity_state4 = a_qte_util_sur_ress + nvl(nfu_quantity_state4, 0)
                   where gal_need_follow_up_id = v_id;

                  v_quantity_state4  := a_qte_util_sur_ress;
                when v_dic_doc_journal_5_id = 5 then
                  update gal_need_follow_up
                     set nfu_quantity_state5 = a_qte_util_sur_ress + nvl(nfu_quantity_state5, 0)
                   where gal_need_follow_up_id = v_id;

                  v_quantity_state5  := a_qte_util_sur_ress;
                when v_dic_doc_journal_5_id = 6 then
                  update gal_need_follow_up
                     set nfu_quantity_state6 = a_qte_util_sur_ress + nvl(nfu_quantity_state6, 0)
                   where gal_need_follow_up_id = v_id;

                  v_quantity_state6  := a_qte_util_sur_ress;
              end case;
            end if;
          end if;
        else
          null;
      end case;
    else
      -- on met à jour la quantité sortie (on travaille sur les gabarits sortie affaire et entrée dossier de fabrication)
      if     a_rfu_need_or_supply = 'N'
         and v_gauge_id in(v_gal_gauge_output_manufacture, v_gal_gauge_output_project) then
        update gal_need_follow_up
           set nfu_stm_project_quantity_out = a_qte_dispo + nvl(nfu_stm_project_quantity_out, 0)
         where gal_need_follow_up_id = v_id;

        v_stm_project_quantity_out  := a_qte_dispo;
      end if;
    end if;

    -- pour les appros sur stock, on met à les infons dans gal_need_followup stock entreprise et stock dispo net
    if   -- (a_supply_mode = 'S' OR a_supply_mode = 'A')
           a_supply_type = 'S'
       and a_rfu_need_or_supply = 'N' then
      update gal_need_follow_up
         set nfu_stm_available_net = gal_project_calculation.StockDispoNet(v_good_id, v_taches_tac_id)
       where gal_need_follow_up_id = v_id
         and nvl(nfu_stm_available_net, 0) = 0;

      update gal_need_follow_up
         set nfu_stm_available_firm = gal_project_calculation.StockDispoEntreprise(v_good_id, v_taches_tac_id)
       where gal_need_follow_up_id = v_id
         and nvl(nfu_stm_available_firm, 0) = 0;
    end if;
  end init_need_follow_appro_details;

--*******************************************************************************************************--

  -- hmo 11.2012 -> mise à jour des champs (state1 à state6 et stm_project_quantity_out) pour affinage du suivi des appros voir procedureinit_need_follow_appro_details
  --
  procedure init_resource_follow_up(
    a_art_id             number
  , qte_dispo            number
  , qte_appro            number
  , a_pjr_number         varchar2
  , a_qte_util_sur_ress  number
  , a_sor                varchar2
  , a_rfu_need_or_supply varchar2
  ,   --type 'S' supply,'N' need,'R' surplus
    a_supply_mode        varchar2
  , a_supply_type        varchar2
  )
  is
    v_quantity_state1          number := null;
    v_quantity_state2          number := null;
    v_quantity_state3          number := null;
    v_quantity_state4          number := null;
    v_quantity_state5          number := null;
    v_quantity_state6          number := null;
    v_stm_project_quantity_out number := null;
  begin
    if    a_qte_util_sur_ress <> 0
       or qte_dispo <> 0 then
      -- initialisation des quantités à poser sur les ressources (gal_resource_follow_up) lors de la mise à jour de la table gal_need_follow_up via un in_out
      init_need_follow_appro_details(qte_dispo
                                   , a_qte_util_sur_ress
                                   , a_supply_mode
                                   , a_supply_type
                                   , a_rfu_need_or_supply
                                   , a_art_id
                                   , v_quantity_state1
                                   , v_quantity_state2
                                   , v_quantity_state3
                                   , v_quantity_state4
                                   , v_quantity_state5
                                   , v_quantity_state6
                                   , v_stm_project_quantity_out
                                    );

      insert into gal_resource_follow_up
                  (gal_resource_follow_up_id
                 , gal_need_follow_up_id
                 , rfu_sessionid
                 , rfu_type
                 , gal_project_id
                 , gal_task_id
                 , gal_good_id
                 , rfu_supply_number
                 , rfu_envisaged_date
                 , rfu_available_date
                 , fal_supply_request_id
                 , doc_position_detail_id
                 , doc_document_id
                 , fal_doc_prop_id
                 , fal_lot_prop_id
                 , fal_lot_id
                 , rfu_quantity
                 , rfu_supply_quantity
                 , rfu_used_quantity
                 , gal_manufacture_task_id
                 , rfu_comment
                 , rfu_type_need_or_supply
                 , rfu_supply_mode
                 , rfu_supply_type
                 , rfu_quantity_state1
                 , rfu_quantity_state2
                 , rfu_quantity_state3
                 , rfu_quantity_state4
                 , rfu_quantity_state5
                 , rfu_quantity_state6
                 , rfu_stm_project_quantity_out
                  )
           values (gal_resource_follow_up_id_seq.nextval
                 , v_id
                 , x_sessionid
                 , decode(a_sor
                        , '1ST', '1ST'
                        , '2BA', '2BA'
                        , '3BA', '2BA'
                        , '2CF', '3CF'
                        , '3CF', '3CF'
                        , '2OF', '4OF'
                        , '3OF', '4OF'
                        , '1RB', '4OF'
                        , '4PA', '5PA'
                        , '4PF', '5PF'
                        , '5OA', decode(v_ress_manufacture_task_id, null, '6OA', '6DF')
                        , '6DI', '6DF'
                        , '6DF', '6DF'
                        , '6DA', '6DF'
                        , '6DB', '6DF'
                        , '6AF', '6DF'
                        , '6DG', '6DF'
                        , '6DH', '6DF'
                        , '6AH', '6DF'
                        , '4PB', '6DF'
                        , '   '
                         )
                 , x_aff_id
                 , v_taches_tac_id
                 , a_art_id
                 , a_pjr_number
                 ,   -- sor_order_number || ' / ' || TRIM (TO_CHAR (sor_position_number)),
                   v_ress_raf_date
                 ,   --NVL (sor_confirmed_delivery_date, sor_planned_delivery_date),
                   v_ress_raf_date_dispo
                 ,   -->sor_input_date,
                   v_ress_oac_id
                 ,   -->fal_supply_request_id
                   v_ress_cfo_id
                 ,   -->doc_position_detail_id
                   v_ress_doc_doc_id
                 ,   -->doc_document_id
                   v_ress_aoa_id
                 ,   -->fal_doc_prop_id
                   v_ress_aof_id
                 ,   -->fal_lot_prop_id
                   v_ress_of
                 ,   -->fal_lot_id
                   (case
                      when     a_rfu_need_or_supply = 'N'
                           and (   a_supply_mode = 'S'
                                or a_supply_mode = 'A')
                           and a_supply_type = 'S' then null
                      else qte_dispo
                    end
                   )
                 , qte_appro
                 , a_qte_util_sur_ress
                 , v_ress_manufacture_task_id
                 , v_ress_comment
                 , a_rfu_need_or_supply
                 , a_supply_mode
                 , a_supply_type
                 , v_quantity_state1
                 , v_quantity_state2
                 , v_quantity_state3
                 , v_quantity_state4
                 , v_quantity_state5
                 , v_quantity_state6
                 , v_stm_project_quantity_out
                  );

            -- les variables (state1 à state6 et v_stm_project_quantity_out) sont mises à jour via la procédure init_need_follow_appro_details via in out
      -- on a l'info resource par ressource dans la table gal_resource_follow_up, alors que dans gal_need _follow_up elle est cumulée par produit
      if v_max_date_prevue < v_ress_raf_date then
        v_max_date_prevue  := v_ress_raf_date;
      end if;
    end if;
  end init_resource_follow_up;

--*******************************************************************************************************--
  procedure init_need_follow_up(
    y_aff_id           number
  , y_tac_id           number
  , y_level            number
  , y_repere           varchar2
  , y_art_id           number
  , y_codart           varchar2
  , y_libart           varchar2
  , y_plan             varchar2
  , y_type_gest        v_gal_pcs_good.ggo_supply_type%type
  , y_repart           v_gal_pcs_good.ggo_supply_mode%type
  , y_qte_lien         number
  , y_besoin_net       number
  , y_besoin_brut      number
  , y_unite            varchar2
  , y_date_besoin_net  date
  , y_com_seq          number
  , y_art_tete_id      number
  , y_com_seq_tete     number
  , y_besoin_stock_df  number
  , iInterNeedQuantity number
  )
  is
  begin
    insert into gal_need_follow_up
                (gal_need_follow_up_id
               , nfu_sessionid
               , gal_project_id
               , gal_task_id
               , nfu_nomenclature_level
               , nfu_com_seq
               , nfu_plan_mark
               , gco_good_id
               , nfu_major_reference
               , nfu_short_description
               , nfu_plan_number
               , nfu_supply_type
               , nfu_supply_mode
               , nfu_coef_util
               , nfu_net_quantity_need
               , nfu_gross_quantity_need
               ,   --ON TIENT COMPTE UNIQUEMENT DES RESSOURCE "SERVI SUR STOCK"...
                 nfu_unit_of_measure
               , nfu_need_date
               , nfu_available_quantity
               , nfu_missing_quantity
               , nfu_info_supply
               , nfu_info_color_supply
               , ggo_supply_type
               , ggo_supply_mode
               , gsm_nom_level
               , gal_task_good_id
               , pps_nomenclature_id
               , pps_nom_bond_id
               , gsm_nom_path
               , pps_nomenclature_header_id
               , nfu_net_quantity_stk   --utilisé pour calculé qte stock sur DF.
               , nfu_inter_need_quantity
                )
         values (gal_need_follow_up_id_seq.nextval
               , x_sessionid
               , y_aff_id
               , y_tac_id
               , to_char(y_level)
               , y_com_seq
               , y_repere
               , y_art_id
               , y_codart
               , y_libart
               , y_plan
               , decode(y_level
                      , 0, null
                      , decode(v_lien_pseudo
                             , 'O', (select pcs.pc_functions.translateword('Pseudo')
                                       from dual)
                             , decode(y_type_gest
                                    , 'A', decode(y_repart
                                                , 'A', (select pcs.pc_functions.translateword('Acheté à l''affaire')
                                                          from dual)
                                                , 'T', (select pcs.pc_functions.translateword('Assemblé à l''affaire')
                                                          from dual)
                                                , 'F', (select pcs.pc_functions.translateword('Fabriqué à l''affaire')
                                                          from dual)
                                                , (select pcs.pc_functions.translateword('Non approvisionné')
                                                     from dual)
                                                 )
                                    , 'S', (select pcs.pc_functions.translateword('Prélevé sur stock')
                                              from dual)
                                    , (select pcs.pc_functions.translateword('Non approvisionné')
                                         from dual)
                                     )
                              )
                       )
               , ''
               , decode(y_level, 0, null, 1, 1, y_qte_lien)
               , y_besoin_net
               , y_besoin_brut
               , y_unite
               , y_date_besoin_net
               , 0
               ,   --MAJ APRES Use_resource
                 0
               ,   --MAJ APRES Use_resource
                 decode(y_level, 0, v_situ, decode(y_besoin_net, 0, ' ', v_situ) )
               , decode(y_level, 0, 'N', null)
               ,   --COULEUR
                 y_type_gest
               , y_repart
               , y_level
               , v_task_good_id
               , decode(y_level, 1, pps, v_pps_nomenclature_id)
               , decode(y_level, 1, null, v_pps_nom_bond_id)
               , decode(y_level
                      , 1, '/' || trim(to_char(y_com_seq_tete) ) || '-' || trim(to_char(y_art_tete_id) )
                      , '/' || trim(to_char(y_com_seq_tete) ) || '-' || trim(to_char(y_art_tete_id) ) || v_pps_path
                       )
               , nvl(pps, y_art_id)
               , y_besoin_stock_df
               , iInterNeedQuantity
                )
      returning gal_need_follow_up_id
           into v_id;
  end init_need_follow_up;

--*******************************************************************************************************--
  procedure Need_balance(a_Tac_id gal_task.gal_task_id%type, a_type_ress varchar2)
  is
  begin
    INIT_SURPLUS_CALC_RESULT(a_tac_id, a_type_ress);

    --DELETE DES POSITIONS EN APPRO (PAS SUR LE DISPO) SUR DOCUMENTS BESOINS AFFAIRE SI SURPLUS
    for RES in (select   *
                    from gal_project_resource
                   where gal_task_id = a_tac_id
                     and (    pjr_remaining_quantity > 0
                          and PJR_SORT = a_type_ress)   --Surplus qui seront supprime sur doc Besoin Affaire (appro)
                order by pjr_sort asc
                       , pjr_number asc) loop
      begin   --UPDATE OU DELETE SUR DOC BESOIN AFFAIRE
        select DOC.POS_BALANCE_QUANTITY
          into V_POS_QTY_TO_UPDATE
          from DOC_POSITION DOC
         where DOC.DOC_POSITION_ID = RES.DOC_POSITION_ID;

        if V_POS_QTY_TO_UPDATE > RES.pjr_remaining_quantity then
          insert into gal_project_calc_result
                      (gal_project_calc_result_id
                     , gal_task_id
                     , gal_good_id
                     , fal_supply_request_id
                     , doc_document_id
                     , doc_position_id
                     , doc_position_detail_id
                     , fal_doc_prop_id
                     , fal_lot_prop_id
                     , fal_lot_id
                     , gal_manufacture_task_id
                     , gal_pcr_qty
                     , gal_pcr_remaining_qty
                     , gal_pcr_comment
                     , gal_pcr_sort
                     , a_idcre
                     , a_datecre
                      )
               values (gal_project_calc_result_id_seq.nextval
                     , RES.gal_task_id
                     , RES.gal_good_id
                     , RES.fal_supply_request_id
                     , RES.doc_document_id
                     , null
                     , (select POS_NUMBER
                          from DOC_POSITION
                         where DOC_POSITION_ID = RES.DOC_POSITION_ID)
                     , RES.fal_doc_prop_id
                     , RES.fal_lot_prop_id
                     , RES.fal_lot_id
                     , RES.gal_manufacture_task_id
                     , 0
                     , decode(RES.pjr_remaining_quantity, 0, RES.pjr_available_remaining_quanti, RES.pjr_remaining_quantity)
                     , (select pcs.pc_functions.translateword('Surplus')
                          from dual)
                     , '10'
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                      );

          -- Effacer le détail source
          --delete from DOC_POSITION_DETAIL
          --where DOC_POSITION_DETAIL_ID = RES.DOC_POSITION_DETAIL_ID;

          -- Màj la qté de la position source
          doc_position_functions.UpdateQuantityPosition(apositionid     => RES.DOC_POSITION_ID
                                                      , aNewQuantity    => V_POS_QTY_TO_UPDATE - RES.pjr_remaining_quantity
                                                      , aKeepPosPrice   => 1
                                                       );

          /*
          UPDATE DOC_POSITION SET POS_BALANCE_QUANTITY = POS_BALANCE_QUANTITY - RES.pjr_remaining_quantity
                                 ,POS_BASIS_QUANTITY = POS_BASIS_QUANTITY - RES.pjr_remaining_quantity
                                 ,POS_INTERMEDIATE_QUANTITY = POS_INTERMEDIATE_QUANTITY - RES.pjr_remaining_quantity
                                 ,POS_FINAL_QUANTITY = POS_FINAL_QUANTITY - RES.pjr_remaining_quantity
          WHERE DOC_POSITION_ID = RES.DOC_POSITION_ID;
          */
          update DOC_POSITION_DETAIL
             set PDE_BALANCE_QUANTITY = PDE_BALANCE_QUANTITY - RES.pjr_remaining_quantity
               , PDE_BASIS_QUANTITY = PDE_BASIS_QUANTITY - RES.pjr_remaining_quantity
               , PDE_INTERMEDIATE_QUANTITY = PDE_INTERMEDIATE_QUANTITY - RES.pjr_remaining_quantity
               , PDE_FINAL_QUANTITY = PDE_FINAL_QUANTITY - RES.pjr_remaining_quantity
           where DOC_POSITION_DETAIL_ID = RES.DOC_POSITION_DETAIL_ID;
        else
          insert into gal_project_calc_result
                      (gal_project_calc_result_id
                     , gal_task_id
                     , gal_good_id
                     , fal_supply_request_id
                     , doc_document_id
                     , doc_position_id
                     , doc_position_detail_id
                     , fal_doc_prop_id
                     , fal_lot_prop_id
                     , fal_lot_id
                     , gal_manufacture_task_id
                     , gal_pcr_qty
                     , gal_pcr_remaining_qty
                     , gal_pcr_comment
                     , gal_pcr_sort
                     , a_idcre
                     , a_datecre
                      )
               values (gal_project_calc_result_id_seq.nextval
                     , RES.gal_task_id
                     , RES.gal_good_id
                     , RES.fal_supply_request_id
                     , RES.doc_document_id
                     , (select POS_NUMBER
                          from DOC_POSITION
                         where DOC_POSITION_ID = RES.DOC_POSITION_ID)
                     , null
                     , RES.fal_doc_prop_id
                     , RES.fal_lot_prop_id
                     , RES.fal_lot_id
                     , RES.gal_manufacture_task_id
                     , 0
                     , decode(RES.pjr_remaining_quantity, 0, RES.pjr_available_remaining_quanti, RES.pjr_remaining_quantity)
                     , (select pcs.pc_functions.translateword('Surplus')
                          from dual)
                     , '10'
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                      );

          delete from DOC_POSITION
                where DOC_POSITION_ID = RES.DOC_POSITION_ID                     /*IN (SELECT doc_position_id FROM gal_project_resource
                                                              WHERE gal_task_id = a_tac_id
                                                              AND pjr_remaining_quantity > 0 AND PJR_SORT = a_type_ress)*/
                                                           ;

          delete from DOC_POSITION_DETAIL
                where DOC_POSITION_DETAIL_ID = RES.DOC_POSITION_DETAIL_ID                           /*IN (SELECT doc_position_detail_id FROM gal_project_resource
                                                                            WHERE gal_task_id = a_tac_id
                                                                            AND pjr_remaining_quantity > 0 AND PJR_SORT = a_type_ress)*/
                                                                         ;
        end if;
      exception
        when no_data_found then
          V_POS_QTY_TO_UPDATE  := 0;
      end;
    end loop;
  --DELETE FROM gal_project_resource WHERE gal_task_id = a_tac_id AND pjr_remaining_quantity > 0 AND PJR_SORT = a_type_ress;
  --FIN DELETE DES POSITIONS
  end Need_balance;

--*******************************************************************************************************--
  procedure Update_Doc_Need_Project(a_art_id v_gal_pcs_good.gal_good_id%type, a_tac_id gal_task.gal_task_id%type, a_acces varchar2   --1 composant df, 0 else
                                                                                                                                  )
  is
    v_pjr_available_remaining_qty number;
    v_pjr_remaining_qty           number;
    v_pjr_number                  gal_project_resource.pjr_number%type;
    v_pjr_sort                    gal_project_resource.pjr_sort%type;
    IsNeedOrSupply                varchar2(1);
    v_cpt_ress_need               number;

    cursor c_need_besoin_affaire
    is
      select     pjr_number
               , pjr_sort
               , pjr_available_remaining_quanti
               , pjr_remaining_quantity
               , pjr_date
               , pjr_available_remaining_quanti
               , pjr_available_date
               , gal_project_resource_id
               , fal_supply_request_id
               , doc_position_detail_id
               , doc_document_id
               , fal_doc_prop_id
               , fal_lot_prop_id
               , fal_lot_id
               , pjr_comment
               , gal_manufacture_task_id
            from gal_project_resource
           where gal_task_id = a_tac_id
             and gal_good_id = a_art_id
             and (   pjr_remaining_quantity > 0
                  or pjr_available_remaining_quanti > 0)
             and (    (    a_acces = '0'
                       and v_branche_df = 'N'
                       and v_repartition in('A', 'F')
                       and v_type_gestion <> 'S'
                       and pjr_sort in('2BA', '3BA')
                       and nvl(doc_gauge_id, 0) in(nvl(V_GAL_GAUGE_NEED_PROJECT, 1), nvl(V_GAL_GAUGE_OUTPUT_PROJECT, 1) )
                      )
                  or (    a_acces = '0'
                      and v_branche_df = 'O'
                      and v_repartition in('A', 'F')
                      and v_type_gestion <> 'S'
                      and pjr_sort in('6DB', '6AF')
                      and nvl(doc_gauge_id, 0) in(nvl(V_GAL_GAUGE_NEED_MANUFACTURE, 1), nvl(V_GAL_GAUGE_OUTPUT_MANUFACTURE, 1) )
                     )
                  or (    a_acces = '0'
                      and v_branche_df = 'O'
                      and v_repartition in('A', 'F')
                      and v_type_gestion <> 'S'
                      and pjr_sort =('6DG') )
                  or (    a_acces = '1'
                      and v_branche_df = 'O'
                      and v_repartition = 'A'
                      and v_type_gestion <> 'S'
                      and nvl(doc_gauge_id, 0) in(nvl(V_GAL_GAUGE_NEED_MANUFACTURE, 1), nvl(V_GAL_GAUGE_OUTPUT_MANUFACTURE, 1) )
                     )   --(a_acces = '1' AND v_branche_df = 'O' AND v_repartition IN ('A','F') AND v_type_gestion <> 'S' AND nvl(doc_gauge_id,0) IN (V_GAL_GAUGE_NEED_MANUFACTURE,V_GAL_GAUGE_OUTPUT_MANUFACTURE))
                 )
             /*
             AND (
                   (a_acces = '0' AND v_branche_df = 'N' AND nvl(doc_gauge_id,0) IN (V_GAL_GAUGE_NEED_PROJECT,V_GAL_GAUGE_OUTPUT_PROJECT))
                  OR
                   (a_acces = '0' AND v_branche_df = 'O' AND nvl(doc_gauge_id,0) IN (V_GAL_GAUGE_NEED_MANUFACTURE,V_GAL_GAUGE_OUTPUT_MANUFACTURE))
                  OR
                   (a_acces = '1' AND v_branche_df = 'O' AND nvl(doc_gauge_id,0) IN (V_GAL_GAUGE_NEED_MANUFACTURE,V_GAL_GAUGE_OUTPUT_MANUFACTURE))
                 )*/
             and 1 = (select gal_project_calculation.GetResourceAffectation(a_tac_id, nvl(gal_manufacture_task_id, a_tac_id) )
                        from dual)
        order by pjr_sort asc
               , decode(sign(v_qte_besoin_net_need - gal_project_resource.pjr_available_remaining_quanti)   --Si match
                      , 0, -1000000
                      , abs(v_qte_besoin_net_need - gal_project_resource.pjr_available_remaining_quanti)   --Sinon
                       ) asc
               , decode(sign(v_qte_besoin_net_need - gal_project_resource.pjr_remaining_quantity)   --Si positif
                      , 0, -1000000
                      , abs(v_qte_besoin_net_need - gal_project_resource.pjr_remaining_quantity)   --Sinon
                       ) asc
      for update;
  begin
    /* Warning : verifier si apres ajout des type 6DG si pose pas un pb sur les need !!! (il faudra alors gerer une quantité à part pour les need....*/

    --DBMS_OUTPUT.PUT_LINE('Use need : ' || v_sui_libart || ' - ' || to_char(v_besoin_net) || ' - ' || v_type_gestion || ' - ' || v_repartition || ' - ' || v_branche_df || ' - ' || v_on_df);-- || ' - ' || tableau_niveau (a_nivo - 1).on_df);
    IsNeedOrSupply          := 'N';
    v_cpt_ress_need         := 0;
    v_cum_qt_util_sur_ress  := v_cum_qt_util_sur_ress + v_besoin_net;

    --Apres utilisation de la ressource, je diminue les NEED dans le doc besoin affaire pour le special.
    --Ceci servira a savoir si ces NEED exprimes sont correct (egalite avec la nomen)
    open c_need_besoin_affaire;

    loop
      fetch c_need_besoin_affaire
       into v_pjr_number
          , v_pjr_sort
          , v_pjr_available_remaining_qty
          , v_pjr_remaining_qty
          , v_ress_raf_date
          ,   -->pjr_date   >date ou sera dispo
            v_ress_art_dispo
          , v_ress_raf_date_dispo
          , v_ress_raf_id
          , v_ress_oac_id
          , v_ress_cfo_id
          , v_ress_doc_doc_id
          , v_ress_aoa_id
          , v_ress_aof_id
          , v_ress_of
          , v_ress_comment
          , v_ress_manufacture_task_id;

      exit when c_need_besoin_affaire%notfound;
      v_cpt_ress_need  := v_cpt_ress_need + 1;

      if v_pjr_sort = '6DG' then
        v_manquant_need  := 'O';
      end if;

      if v_pjr_available_remaining_qty > 0 then
        if v_pjr_available_remaining_qty >= v_cum_qt_util_sur_ress then
          update gal_project_resource
             set pjr_available_remaining_quanti = pjr_available_remaining_quanti - v_cum_qt_util_sur_ress
           where current of c_need_besoin_affaire;

          init_resource_follow_up(a_art_id, v_cum_qt_util_sur_ress, 0, v_pjr_number, 0, v_pjr_sort, IsNeedOrSupply, v_repartition, v_type_gestion);
          v_cum_qt_util_sur_ress  := v_cum_qt_util_sur_ress - v_pjr_available_remaining_qty;
          exit;
        else
          update gal_project_resource
             set pjr_available_remaining_quanti = 0
           where current of c_need_besoin_affaire;

          v_cum_qt_util_sur_ress  := v_cum_qt_util_sur_ress - v_pjr_available_remaining_qty;
          init_resource_follow_up(a_art_id, v_pjr_available_remaining_qty, 0, v_pjr_number, 0, v_pjr_sort, IsNeedOrSupply, v_repartition, v_type_gestion);
        end if;
      end if;

      if v_pjr_remaining_qty > 0 then
        if v_pjr_remaining_qty >= v_cum_qt_util_sur_ress then
          update gal_project_resource
             set pjr_remaining_quantity = pjr_remaining_quantity - v_cum_qt_util_sur_ress
           where current of c_need_besoin_affaire;

          init_resource_follow_up(a_art_id, 0, 0, v_pjr_number, v_cum_qt_util_sur_ress, v_pjr_sort, IsNeedOrSupply, v_repartition, v_type_gestion);
          v_cum_qt_util_sur_ress  := v_cum_qt_util_sur_ress - v_pjr_remaining_qty;
          exit;
        else
          update gal_project_resource
             set pjr_remaining_quantity = 0
           where current of c_need_besoin_affaire;

          v_cum_qt_util_sur_ress  := v_cum_qt_util_sur_ress - v_pjr_remaining_qty;
          init_resource_follow_up(a_art_id, 0, 0, v_pjr_number, v_pjr_remaining_qty, v_pjr_sort, IsNeedOrSupply, v_repartition, v_type_gestion);
        end if;
      end if;
    end loop;

    close c_need_besoin_affaire;

    if v_cpt_ress_need > 0 then
      if v_cum_qt_util_sur_ress > 0 then   --Ressources existe mais pas en phase avec le doc Besoin affaire
        -->manquant sur les NEED
        v_qte_besoin_net_need  := v_cum_qt_util_sur_ress;
      end if;
    else
      v_qte_besoin_net_need  := v_besoin_tot;
    end if;

    if     a_acces = '1'
       and v_repartition = 'F'
       and v_type_gestion <> 'S' then
      --DEPUIS LANCEMENT DF ET COMPOSANT FABRIQUE (la ressource est le NEED)
      v_qte_besoin_net_need  := 0;
    end if;
  end Update_Doc_Need_Project;

--*******************************************************************************************************--
  procedure Use_resource(a_art_id v_gal_pcs_good.gal_good_id%type, a_tac_id gal_task.gal_task_id%type, a_acces varchar2,   --(1 DF/0 Nomen)
                                                                                                                        a_nivo number)
  is
    IsNeedOrSupply    varchar2(1);
    v_GsmNomPath      GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type;
    v_qte_mcal_result number;
    v_cpt_ress        number;

    cursor c_ress
    is
      select     pjr_number
               , pjr_remaining_quantity
               , pjr_date
               ,   -->date prevu
                 pjr_available_remaining_quanti
               , pjr_available_date
               ,   -->date dispo
                 gal_project_resource_id
               , fal_supply_request_id
               , doc_position_detail_id
               ,   --gal_supplier_order_id,
                 doc_document_id
               , fal_doc_prop_id
               ,   --ofa_id,
                 fal_lot_prop_id
               ,   --gal_stock_booking_id,
                 fal_lot_id
               , pjr_comment
               , gal_manufacture_task_id
               , doc_gauge_id
               , pjr_sort
               , pjr_minimum_need_date
            from gal_project_resource
           where gal_task_id = a_tac_id
             and gal_good_id = a_art_id
             and (   pjr_remaining_quantity > 0
                  or pjr_available_remaining_quanti > 0)
             and (    (    v_repartition = 'A'
                       and a_acces = '1'
                       and v_type_gestion <> 'S'
                       and nvl(doc_gauge_id, 0) not in
                             (nvl(V_GAL_GAUGE_NEED_MANUFACTURE, 1)
                            , nvl(V_GAL_GAUGE_NEED_PROJECT, 1)
                            , nvl(V_GAL_GAUGE_OUTPUT_PROJECT, 1)
                            , nvl(V_GAL_GAUGE_OUTPUT_MANUFACTURE, 1)
                             )
                      )   --On ne retient pas les NEED
                  or (    v_repartition = 'F'
                      and a_acces = '1'
                      and v_type_gestion <> 'S'
                      and nvl(doc_gauge_id, 0) not in(nvl(V_GAL_GAUGE_NEED_PROJECT, 1), nvl(V_GAL_GAUGE_OUTPUT_PROJECT, 1) )
                     )   --sur composant DF, la ressource est le need
                  or (    v_type_gestion = 'S'
                      and a_acces = '1')
                  --OR (v_repartition = 'T' AND a_acces = '1' )
                  or (    v_repartition in('A', 'F')
                      and a_acces = '0'
                      and v_type_gestion <> 'S'
                      and nvl(doc_gauge_id, 0) not in
                            (nvl(V_GAL_GAUGE_NEED_MANUFACTURE, 1)
                           , nvl(V_GAL_GAUGE_NEED_PROJECT, 1)
                           , nvl(V_GAL_GAUGE_OUTPUT_PROJECT, 1)
                           , nvl(V_GAL_GAUGE_OUTPUT_MANUFACTURE, 1)
                            )
                     )
                  or (    v_type_gestion = 'S'
                      and v_branche_df = 'N'
                      and a_acces = '0'
                      and nvl(doc_gauge_id, 0) not in(nvl(V_GAL_GAUGE_NEED_MANUFACTURE, 1), nvl(V_GAL_GAUGE_OUTPUT_MANUFACTURE, 1) )
                     )
                  or (    v_type_gestion = 'S'
                      and v_branche_df = 'O'
                      and a_acces = '0'
                      and nvl(doc_gauge_id, 0) not in(nvl(V_GAL_GAUGE_NEED_PROJECT, 1), nvl(V_GAL_GAUGE_OUTPUT_PROJECT, 1) )
                     )
                  --OR (v_repartition = 'T' AND v_branche_df = 'N' AND a_acces = '0' AND nvl(doc_gauge_id,0) not in (V_GAL_GAUGE_NEED_MANUFACTURE,V_GAL_GAUGE_OUTPUT_MANUFACTURE))
                  --OR (v_repartition = 'T' AND v_branche_df = 'O' AND a_acces = '0' AND nvl(doc_gauge_id,0) not in (V_GAL_GAUGE_NEED_PROJECT,V_GAL_GAUGE_OUTPUT_PROJECT))
                  or (    v_repartition = 'T'
                      and v_branche_df = 'O'
                      and a_acces = '0'
                      and pjr_sort =('6DG') )
                 )
             and pjr_sort <> '1SM'   --> ligne de détail des mouvements pour control
             and 1 = decode(v_repartition, 'F', 1, (select gal_project_calculation.GetResourceAffectation(a_tac_id, nvl(gal_manufacture_task_id, a_tac_id) )
                                                      from dual) )
             and 1 = (select gal_project_calculation.GetResourceType(pjr_sort, v_repartition, v_type_gestion, v_branche_df, v_branche_desc)
                        from dual)
        order by pjr_sort asc
               , decode(sign(v_besoin_net - pjr_available_remaining_quanti)   --Si match
                                                                           , 0, -1000000, abs(v_besoin_net - pjr_available_remaining_quanti)   --Sinon
                                                                                                                                            ) asc
               , decode(sign(v_besoin_net - pjr_remaining_quantity)   --Si positif
                                                                   , 0, -1000000, abs(v_besoin_net - pjr_remaining_quantity)   --Sinon
                                                                                                                            ) asc
      for update;
  begin
    v_qte_mcal_result         := 0;
    v_cpt_ress                := 0;
    v_situ                    := ' ';
    v_couleur                 := ' ';
    v_qt_utilisee_appro       := 0;
    v_qt_utilisee_dispo       := 0;
    v_qt_util_sur_ress        := 0;
    v_qte_a_deduire_of        := 0;
    v_cum_qt_util_sur_ress    := 0;
    v_qte_besoin_net_need     := 0;
    v_list_df_use             := null;
    v_manquant_need           := 'N';
    v_force_to_launch_status  := 'N';
    v_force_to_launch_qty     := 0;
    v_GsmNomPath              := null;

    select to_date('01/01/1901', 'DD/MM/YYYY')
      into v_max_date_prevue
      from dual;

    --      if a_nivo >= 1
    --      THEN
    --        DBMS_OUTPUT.PUT_LINE('Use ress : ' || v_sui_libart || ' - ' || to_char(v_besoin_net) || ' - ' || v_type_gestion || ' - ' || v_repartition || ' - ' || v_branche_df || ' - ' || v_on_df || ' - ' || tableau_niveau (a_nivo - 1).on_df || ' - ' || to_char(tableau_niveau (a_nivo - 1).qte_a_deduire_of));
    --      ELSE
    --        DBMS_OUTPUT.PUT_LINE('Use ress : ' || v_sui_libart || ' - ' || to_char(v_besoin_net) || ' - ' || v_type_gestion || ' - ' || v_repartition || ' - ' || v_branche_df || ' - ' || v_on_df || ' - nada' || ' - ' || to_char(tableau_niveau (a_nivo - 1).qte_a_deduire_of) );
    --      END IF;
    open c_ress;

    loop
      fetch c_ress
       into v_ress_pjr_number
          , v_ress_art
          ,   -->Appro
            v_ress_raf_date
          ,   -->date Appro
            v_ress_art_dispo
          ,   -->Dispo
            v_ress_raf_date_dispo
          ,   -->date dispo
            v_ress_raf_id
          ,   -->gal_project_resource_id
            v_ress_oac_id
          ,   -->fal_supply_request_id
            v_ress_cfo_id
          ,   -->doc_position_detail_id
            v_ress_doc_doc_id
          ,   -->pour ihm delphi
            v_ress_aoa_id
          ,   -->fal_doc_prop_id
            v_ress_aof_id
          ,   -->fal_lot_prop_id
            v_ress_of
          ,   -->fal_lot_id
            v_ress_comment
          ,   -->partner
            v_ress_manufacture_task_id
          ,   -->dossier fab
            v_ress_gauge_id
          ,   -->doc_gauge_id
            v_tri
          ,   -->pjr_sort
            v_ress_start_date;   -->Date debut DF

      exit when c_ress%notfound;
      v_cpt_ress              := v_cpt_ress + 1;

      if    (v_type_gestion = 'S')
         or (v_repartition = 'T')
         or (    v_repartition = 'F'
             and a_acces = '1'
             and v_type_gestion <> 'S') then
        IsNeedOrSupply  := 'N';
      else
        IsNeedOrSupply  := 'S';
      end if;

      --IF v_tri IN ('6DG','6DI') THEN v_force_to_launch_status := 'O'; v_force_to_launch_qty := v_force_to_launch_qty + v_qt_util_sur_ress; END IF;
      if v_tri = '1RB'   --Pour un rebus, on augmente les quantités à induire
                      then
        if v_ress_art_dispo > 0 then
          v_besoin_a_induire  := v_besoin_a_induire + v_ress_art_dispo;

          update gal_project_resource
             set pjr_available_remaining_quanti = 0
           where current of c_ress;
        end if;
      else
        --RESSOURCE DISPO COUVRE LE BESOIN
        if     v_ress_art_dispo >= v_besoin_net
           and v_ress_art_dispo <> 0 then
          v_qte_mcal_result    := v_besoin_net;

          update gal_project_resource
             set pjr_available_remaining_quanti = pjr_available_remaining_quanti - v_besoin_net
           where current of c_ress;

          if v_tri = '1ST'   --SORTIE STOCK
                          then
            v_besoin_a_induire  := 0;
          end if;

          v_qt_util_sur_ress   := v_besoin_net;
          v_qt_utilisee_dispo  := v_qt_utilisee_dispo + v_besoin_net;
          v_besoin_net         := 0;

          if     v_tri in('2OF', '3OF', '4PF', '5OA')
             and V_REPARTITION = 'F' then
            v_qte_a_deduire_of  := v_qt_util_sur_ress;
          end if;

          if v_repartition <> 'T' then
            init_resource_follow_up(a_art_id, v_qt_util_sur_ress, 0, v_ress_pjr_number, 0, v_tri, IsNeedOrSupply, v_repartition, v_type_gestion);
          end if;
        --             EXIT;
        else
          --SI RESSOURCE DISPO COUVRE PARTIELLEMENT LE BESOIN
          if v_ress_art_dispo > 0 then
            v_qte_mcal_result    := v_ress_art_dispo;

            update gal_project_resource
               set pjr_available_remaining_quanti = 0
             where current of c_ress;   --LA RESSOURCE DEVIENT 0

            if v_tri = '1ST'   --SORTIE STOCK
                            then
              v_besoin_a_induire  := v_besoin_a_induire - v_ress_art_dispo;
            end if;

            v_besoin_net         := v_besoin_net - v_ress_art_dispo;
            v_qt_util_sur_ress   := v_ress_art_dispo;
            v_qt_utilisee_dispo  := v_qt_utilisee_dispo + v_ress_art_dispo;

            if     v_tri in('2OF', '3OF', '4PF', '5OA')
               and V_REPARTITION = 'F' then
              v_qte_a_deduire_of  := v_qte_a_deduire_of + v_qt_util_sur_ress;
            end if;

            if v_repartition <> 'T' then
              init_resource_follow_up(a_art_id, v_qt_util_sur_ress, 0, v_ress_pjr_number, 0, v_tri, IsNeedOrSupply, v_repartition, v_type_gestion);
            end if;
          end if;
        end if;

        --SI RESTE UN BESOIN, JE PREND DANS LES RESSOURCES OUVERTES
        if v_besoin_net > 0 then
          --SI RESSOURCES OUVERTES COUVRE LE BESOIN
          if v_ress_art >= v_besoin_net then
            v_qte_mcal_result    := v_qte_mcal_result + v_besoin_net;

            update gal_project_resource
               set pjr_remaining_quantity = pjr_remaining_quantity - v_besoin_net
             where current of c_ress;

            v_qt_utilisee_appro  := v_qt_utilisee_appro + v_besoin_net;
            v_qt_util_sur_ress   := v_besoin_net;
            v_besoin_net         := 0;

            if     v_tri in('2OF', '3OF', '4PF', '5OA')
               and V_REPARTITION = 'F' then
              v_qte_a_deduire_of  := v_qte_a_deduire_of + v_qt_util_sur_ress;
            end if;

            if v_repartition <> 'T' then
              init_resource_follow_up(a_art_id, 0, 0, v_ress_pjr_number, v_qt_util_sur_ress, v_tri, IsNeedOrSupply, v_repartition, v_type_gestion);
            end if;
          --                  EXIT;
          else   --SI RESSOURCE OUVERTES COUVRE PARTIELLEMENT LE BESOIN
            if v_ress_art <> 0 then
              v_qte_mcal_result    := v_qte_mcal_result + v_ress_art;

              update gal_project_resource
                 set pjr_remaining_quantity = 0
               where current of c_ress;   --LA RESSOURCE DEVIENT 0

              v_qt_util_sur_ress   := v_ress_art;
              v_besoin_net         := v_besoin_net - v_ress_art;
              v_qt_utilisee_appro  := v_qt_utilisee_appro + v_ress_art;

              if     v_tri in('2OF', '3OF', '4PF', '5OA')
                 and V_REPARTITION = 'F' then
                v_qte_a_deduire_of  := v_qte_a_deduire_of + v_qt_util_sur_ress;
              end if;

              if v_repartition <> 'T' then
                init_resource_follow_up(a_art_id, 0, 0, v_ress_pjr_number, v_qt_util_sur_ress, v_tri, IsNeedOrSupply, v_repartition, v_type_gestion);
              end if;
            --Pour l'assemble sur tache, on lit les ressources DF mais seulement pour signalé un surplus
            end if;
          end if;
        end if;
      end if;

      v_cum_qt_util_sur_ress  := v_cum_qt_util_sur_ress + v_qt_util_sur_ress;

      if     a_acces = '0'
         and v_on_df = 'O'
         and (   nvl(v_ress_gauge_id, 0) = V_GAL_GAUGE_SUPPLY_MANUFACTURE
              or nvl(v_ress_gauge_id, 0) = V_GAL_GAUGE_ENTRY_MANUFACTURE
              or v_tri = '6DI')
                               --Objectif:s'assurer que les composants en need et supply utilise des ressources du meme df que le compose (sinon surplus)
      then
        v_list_df_use  := v_list_df_use || ';' || trim(to_char(v_ress_manufacture_task_id) );
      else
        v_list_df_use  := null;
      end if;

      if     IsNeedOrSupply = 'N'
         and v_tri = '6DG' then
        v_manquant_need  := 'O';
      end if;

      if v_tri in('6DG', '6DI') then
        v_force_to_launch_status  := 'O';
        v_force_to_launch_qty     := v_force_to_launch_qty + v_qt_util_sur_ress;
      end if;

      if     v_flag_simulation = 'N'
         and v_planif_df = 1   --OR v_calc_df = 1)
         and v_tri = '6DI'
         and (   v_ress_start_date is null
              or v_ress_raf_date is null)   --si date DF non renseignées
                                         then
        InitPlanifDateDF;
      end if;

      /*
      IF v_nivo > 1
      THEN
        DBMS_OUTPUT.PUT_LINE ('SUIVI RESS : ' || v_sui_libart || ' > ' || nvl(tableau_niveau (v_nivo-1).df_to_use_for_csant,to_char(nvl(a_tac_id,0))) || ' -> RESS : ' || to_char(nvl(v_ress_manufacture_task_id,0)));
      --(instr(nvl(tableau_niveau (v_nivo-1).df_to_use_for_csant,'0'),(';'||to_char(nvl(gal_manufacture_task_id,0))),1,1) <> 0)
      END IF;
      */
      if v_besoin_net = 0 then
        exit;
      end if;
    end loop;

    close c_ress;

    /*
    IF v_nivo > 1
    THEN
      DBMS_OUTPUT.PUT_LINE ('SUIVI UTILISATION DF ' || v_sui_libart || ' > ' || NVL(v_list_df_use,'XXXXXXXX') || ' > TO USE ON : ' || tableau_niveau (v_nivo-1).df_to_use_for_csant);
    ELSE
      DBMS_OUTPUT.PUT_LINE ('SUIVI UTILISATION DF ' || v_sui_libart || ' > ' || NVL(v_list_df_use,'XXXXXXXX') || ' > TO USE ON : ' || 'NADA');
    END IF;
    */

    /*
    IF a_nivo >= 1
    THEN
      DBMS_OUTPUT.PUT_LINE('Use ress 2A: ' || v_sui_libart || ' - ' || to_char(v_besoin_net) || ' - ' || v_type_gestion || ' - ' || v_repartition || ' - ' || v_branche_df || ' - ' || v_on_df || ' - ' || tableau_niveau (a_nivo - 1).on_df || ' - ' || to_char(a_nivo));
    ELSE
      DBMS_OUTPUT.PUT_LINE('Use ress 2B: ' || v_sui_libart || ' - ' || to_char(v_besoin_net) || ' - ' || v_type_gestion || ' - ' || v_repartition || ' - ' || v_branche_df || ' - ' || v_on_df || ' - nada - ' || to_char(a_nivo) );
    END IF;
    */
    if v_qte_a_deduire_of <> 0 then
      null;   --Si appro sur OF, les modes d'appro n et n+1 ne peuvent plus être changé

      select decode(v_level
                  , 1, '/' || trim(to_char(v_gml_sequence) ) || '-' || trim(to_char(v_taches_art_id) )
                  , '/' || trim(to_char(v_gml_sequence) ) || '-' || trim(to_char(v_taches_art_id) ) || v_pps_path
                   )
        into v_GsmNomPath
        from dual;

      UpdateGsmAllowUpd(v_GsmNomPath, v_task_good_id, Pps, 0);   --> 0 => Mode d'appro non modifiable ( pour le niveau N fabriqué sur OF, et N+1 non approvisionné )
    else
      if v_repartition = 'F' then
        select decode(v_level
                    , 1, '/' || trim(to_char(v_gml_sequence) ) || '-' || trim(to_char(v_taches_art_id) )
                    , '/' || trim(to_char(v_gml_sequence) ) || '-' || trim(to_char(v_taches_art_id) ) || v_pps_path
                     )
          into v_GsmNomPath
          from dual;

        UpdateGsmAllowUpd(v_GsmNomPath, v_task_good_id, Pps, 1);   --> 1 => Mode d'appro est modifiable ( pour le niveau N non fabriqué sur OF, et N+1 non approvisionné )
      end if;
    end if;

    if     v_type_gestion <> 'S'
       and v_repartition <> 'T'
       and v_branche_desc = 'N' then
      if nvl(a_nivo, 0) >= 1 then
        if    (tableau_niveau(a_nivo - 1).qte_a_deduire_of <> 0)   -- AND tableau_niveau (a_nivo - 1).qte_a_deduire_of <> 0 )
           or (1 = GetStatusUnderPOf(a_nivo) )   --Sous un of, on ne génère pas de besoins
           --OR (tableau_niveau (a_nivo - 1).repartition = 'F'
           --     AND tableau_niveau (a_nivo - 1).type_gestion = 'A'
           --     AND tableau_niveau (a_nivo - 1).on_df = 'N') --Sous un of, on ne génère pas de besoins
           or (1 = GetStatusUnderOf(a_nivo) )   --sous un pseudo fabriqué sur of
                                             --    tableau_niveau (a_nivo - 2).repartition = 'F'
                                             --AND tableau_niveau (a_nivo - 2).type_gestion = 'A'
                                             --AND tableau_niveau (a_nivo - 2).on_df = 'N'
                                             --AND tableau_niveau (a_nivo - 1).lien_pseudo = 'O') --sous un pseudo fabriqué sur of
        then
          --(Si utilisation des OF, les need sont gérés par OF)
          v_qte_besoin_net_need  := 0;
        --DBMS_OUTPUT.PUT_LINE('Use ress 2C: ' || v_sui_libart);
        else
          Update_Doc_Need_Project(a_art_id, a_tac_id, a_acces);
        end if;
      else
        Update_Doc_Need_Project(a_art_id, a_tac_id, a_acces);
      end if;
    end if;

    if v_level >= 1 then
      v_situ     := ' ';
      v_couleur  := ' ';

      if nvl(a_nivo, 0) >= 1 then
        if    tableau_niveau(a_nivo - 1).qte_a_deduire_of <> 0
           or (1 = GetStatusUnderPOf(a_nivo) )   --Sous un of, on ne génère pas de besoins
           --OR (tableau_niveau (a_nivo - 1).repartition = 'F'
           --     AND tableau_niveau (a_nivo - 1).type_gestion = 'A'
           --     AND tableau_niveau (a_nivo - 1).on_df = 'N') --Sous un OF, on ne génère pas de besoins
           or (1 = GetStatusUnderOf(a_nivo) )   --sous un pseudo fabriqué sur of
                                             --      (tableau_niveau (a_nivo - 2).repartition = 'F' --> no data found si level 1
                                             --   AND tableau_niveau (a_nivo - 2).type_gestion = 'A'
                                             --   AND tableau_niveau (a_nivo - 2).on_df = 'N'
                                             --   AND tableau_niveau (a_nivo - 1).lien_pseudo = 'O') --sous un pseudo fabriqué sur of
        then
          --(Si utilisation des OF, les need sont gérés par OF)
          Init_Status_info(a_acces, IsNeedOrSupply, 'O');   --Situation, couleur IHM
        else
          Init_Status_info(a_acces, IsNeedOrSupply, 'N');
        end if;
      else
        Init_Status_info(a_acces, IsNeedOrSupply, 'N');
      end if;
    --Init_Status_info(a_acces,IsNeedOrSupply);--Situation, couleur IHM
    end if;
  end Use_resource;

--*******************************************************************************************************--
  procedure besoins_net(
    a_art_id           v_gal_pcs_good.gal_good_id%type
  , a_tac_id           gal_task.gal_task_id%type
  , a_inter_qte_besoin number
  , a_date_besoin      date
  , a_delai            number
  , a_nivo             number
  )
  is
    a_com_seq              number;
    a_qte_besoin           number;
    a_inter_qte_besoin_tot number;
    a_AddNeedIfWaste       number;
  begin
    --hmo 01.2016  a_qte_besoin :=
    -- a_inter_qte_besoin + AddNeedIfWaste (a_art_id, a_inter_qte_besoin);
    a_qte_besoin                                := a_inter_qte_besoin;

    if a_nivo = 0 then
      a_inter_qte_besoin_tot  := a_qte_besoin;
      v_besoin_net            := a_qte_besoin;
      v_besoin_a_induire      := a_qte_besoin;
      v_besoin_a_induire_tot  := a_qte_besoin;
      v_besoin_brut           := a_qte_besoin;
      v_besoin_tot            := a_qte_besoin;
      a_com_seq               := v_gml_sequence;
      v_besoin_stock_df       := a_qte_besoin;
      v_date_besoin_net       := gal_project_calculation.GetDecalageForward(a_date_besoin, 0);
    else
      --DBMS_OUTPUT.PUT_LINE('Besoin Net : ' || v_sui_libart || ' - ' || to_char(a_qte_besoin) || ' - ' || v_type_gestion || ' - ' || v_repartition || ' - '
      --                     || v_branche_df || ' - ' || v_on_df || ' - ' || tableau_niveau (a_nivo - 1).qte_a_induire || ' - '
      --                       || to_char(tableau_niveau (a_nivo - 1).qte_a_deduire_of) || ' - ' || to_char(tableau_niveau (a_nivo - 1).article_id) || ' - '
      --                    );--|| tableau_niveau (a_nivo - 1).gsm_nom_path);
      a_inter_qte_besoin_tot  := a_inter_qte_besoin * tableau_niveau(a_nivo - 1).qte_a_induire;
      a_AddNeedIfWaste        := AddNeedIfWaste(a_art_id, a_inter_qte_besoin);

      if v_type_gestion = 'S' then
        v_besoin_net  := (a_qte_besoin *(tableau_niveau(a_nivo - 1).qte_a_induire - tableau_niveau(a_nivo - 1).qte_a_deduire_of) ) + a_AddNeedIfWaste;
      /*
      IF NVL(a_nivo,0) > 1
      THEN
        IF tableau_niveau (a_nivo - 1).qte_a_deduire_of <> 0
        THEN
          --(Si utilisation des OF, les need sont gérés par OF)
          v_besoin_net := 0;
        ELSE
          v_besoin_net := (a_qte_besoin * (tableau_niveau (a_nivo - 1).qte_a_induire - tableau_niveau (a_nivo - 1).qte_a_deduire_of));
        END IF;
      ELSE
        v_besoin_net := (a_qte_besoin * (tableau_niveau (a_nivo - 1).qte_a_induire - tableau_niveau (a_nivo - 1).qte_a_deduire_of));
      END IF;
      */
      else
        v_besoin_net  :=(a_qte_besoin * tableau_niveau(a_nivo - 1).qte_a_induire + a_AddNeedIfWaste);
      end if;

      v_besoin_a_induire      :=(a_qte_besoin * tableau_niveau(a_nivo - 1).qte_a_induire + a_AddNeedIfWaste);
      v_besoin_a_induire_tot  :=(a_qte_besoin * tableau_niveau(a_nivo - 1).qte_a_induire_tot + a_AddNeedIfWaste);
      v_besoin_brut           :=(a_qte_besoin * tableau_niveau(a_nivo - 1).qte_a_induire + a_AddNeedIfWaste);
      v_besoin_tot            :=(a_qte_besoin * tableau_niveau(a_nivo - 1).qte_a_induire_tot + a_AddNeedIfWaste);
      v_besoin_stock_df       := (a_qte_besoin *(tableau_niveau(a_nivo - 1).qte_a_induire - tableau_niveau(a_nivo - 1).qte_a_deduire_of) ) + a_AddNeedIfWaste;
      v_date_besoin_net       := cherche_date_besoin_net(tableau_niveau(a_nivo - 1).dat_besoin_net, a_delai);
      a_com_seq               := v_com_seq;
    end if;

    init_need_follow_up(y_aff_id             => x_aff_id
                      , y_tac_id             => a_tac_id
                      , y_level              => v_level
                      , y_repere             => v_sui_repere
                      , y_art_id             => a_art_id
                      , y_codart             => v_sui_codart
                      , y_libart             => v_sui_long_descr
                      , y_plan               => v_sui_plan
                      , y_type_gest          => v_type_gestion
                      , y_repart             => v_repartition
                      , y_qte_lien           => a_qte_besoin
                      , y_besoin_net         => v_besoin_brut
                      , y_besoin_brut        => v_besoin_tot
                      , y_unite              => v_sui_un_st
                      , y_date_besoin_net    => v_date_besoin_net
                      , y_com_seq            => a_com_seq
                      , y_art_tete_id        => v_taches_art_id
                      , y_com_seq_tete       => v_gml_sequence
                      , y_besoin_stock_df    => v_besoin_stock_df
                      , iInterNeedQuantity   => a_inter_qte_besoin_tot
                       );

    if    (    v_branche_stock = 'N'
           and v_lien_pseudo = 'N'
           and v_branche_desc = 'N'
           and v_lien_descriptif = 'N'
           and v_type_gestion <> 'S')
       or (   --sous un OF --> besoins sont gérés par l'of
               v_branche_stock = 'N'
           and v_lien_pseudo = 'N'
           and v_branche_desc = 'N'
           and v_lien_descriptif = 'N'
           --AND v_type_gestion = 'S'
           and not(1 = GetStatusForStkUnderPOf(a_nivo) )   --Stock sous un OF
           --AND NOT (v_type_gestion = 'S' AND tableau_niveau (a_nivo - 1).repartition = 'F'
           --                              AND tableau_niveau (a_nivo - 1).type_gestion = 'A'
           --                                 AND tableau_niveau (a_nivo - 1).on_df = 'N') --Stock sous un OF
           and not(1 = GetStatusForStkUnderOf(a_nivo) )   --sous un pseudo fabriqué sur of
          --AND NOT (v_type_gestion = 'S' AND tableau_niveau (a_nivo - 2).repartition = 'F'
          --                              AND tableau_niveau (a_nivo - 2).type_gestion = 'A'
          --                                AND tableau_niveau (a_nivo - 2).on_df = 'N'
          --                                AND tableau_niveau (a_nivo - 1).lien_pseudo = 'O') --Stock sous un pseudo fabriqué sur of
          )
           --16/01
           --      AND ((v_type_gestion <> 'S') OR (v_type_gestion = 'S' AND (v_branche_of = 'N' OR (v_branche_da = 'O' AND v_force_appro = 'O'))))
           --          )
           /* appro sur df --> force lecture des ressources */
           --      OR (v_branche_df = 'O' AND v_lien_descriptif = 'N')
           --      OR (v_branche_assemblee = 'O' AND v_lien_descriptif = 'N')
    then
      Use_resource(a_art_id, a_tac_id, '0', a_nivo);
    else
      v_situ                    := ' ';
      v_couleur                 := ' ';
      v_qt_utilisee_appro       := 0;
      v_qt_utilisee_dispo       := 0;
      v_qt_util_sur_ress        := 0;
      v_qte_a_deduire_of        := 0;   --bug appro si on passe pas dans use_resource
      v_cum_qt_util_sur_ress    := 0;
      v_qte_besoin_net_need     := 0;
      v_list_df_use             := null;
      v_manquant_need           := 'N';
      v_force_to_launch_status  := 'N';
      v_force_to_launch_qty     := 0;
    end if;

    /*
    DBMS_OUTPUT.PUT_LINE('BEFORE TAB NIVO : ' || v_sui_codart || ' - ' || v_lien_pseudo || ' - ' || v_branche_stock || ' - ' ||
    v_branche_desc || ' - ' || v_lien_descriptif || ' - ' || v_type_gestion || ' - ' || v_branche_of || ' - ' || v_branche_da || ' - ' || v_force_appro || ' - ' ||
    v_branche_df || ' - ' || v_branche_assemblee);
    */

    --LA QTE DISPO FAIT LA SOMME DES COMMANDE FOURN RECUE + SORTIE STOCk POUR GAL_TASK_ID / GAL_GOOD_ID
    --LA QTE MANQUANTE = (V_BESOIN_BRUT - QTE_DISPO)
    --ON ECRIT LE BESOIN NET + DATE BESOIN DANS LE TABLEAU DE TRAVAIL
    --POUR TEST, ON ECRIT AUSSI LE DELAI MAIS EN FAIT PAS BESOIN
    tableau_niveau(a_nivo).tache_id             := a_tac_id;
    tableau_niveau(a_nivo).article_id           := a_art_id;

    if nvl(a_nivo, 0) >= 1 then
      --IF v_repartition = 'S' AND tableau_niveau (a_nivo - 1).qte_a_deduire_of <> 0
      if    (    v_type_gestion = 'S'
             and tableau_niveau(a_nivo - 1).qte_a_deduire_of <> 0)   --Stock sous un OF
         or (1 = GetStatusForStkUnderPOf(a_nivo) )   ----Stock sous un OF
         --OR (v_type_gestion = 'S' AND tableau_niveau (a_nivo - 1).repartition = 'F'
         --                         AND tableau_niveau (a_nivo - 1).type_gestion = 'A'
         --                            AND tableau_niveau (a_nivo - 1).on_df = 'N') --Stock sous un OF
         or (1 = GetStatusForStkUnderOf(a_nivo) )   --sous un pseudo fabriqué sur of
                                                 --OR (v_type_gestion = 'S' AND tableau_niveau (a_nivo - 2).repartition = 'F'
                                                 --                         AND tableau_niveau (a_nivo - 2).type_gestion = 'A'
                                                 --                            AND tableau_niveau (a_nivo - 2).on_df = 'N'
                                                 --                         AND tableau_niveau (a_nivo - 1).lien_pseudo = 'O') --Stock sous un pseudo fabriqué sur of
      then
        tableau_niveau(a_nivo).qte_besoin_net  := 0;
        v_situ                                 := GetInfoForStkUnderPOf(a_nivo);

        update gal_need_follow_up
           set nfu_to_launch_quantity = 0
             , nfu_info_supply = v_situ   --decode(tableau_niveau (a_nivo - 1).qte_a_deduire_of,0,pcs.pc_functions.translateword ('A lancer')
             --                                                     ,decode(tableau_niveau (a_nivo - 1).qte_besoin_net
             --                                                               ,0,pcs.pc_functions.translateword ('Appro')
             --                                                                 ,pcs.pc_functions.translateword ('A lancer')))
        ,      nfu_info_color_supply = 'V'
         where gal_need_follow_up_id = v_id;
      else
        tableau_niveau(a_nivo).qte_besoin_net  := v_besoin_net;   -- = BESOIN - RESSOURCE
      end if;
    else
      tableau_niveau(a_nivo).qte_besoin_net  := v_besoin_net;   -- = BESOIN - RESSOURCE
    end if;

    if (   v_lien_pseudo = 'O'
        or v_branche_stock = 'O'
        or v_branche_desc = 'O'
        or v_lien_descriptif = 'O'
        or v_repartition = 'T'
       )   --Plus d'appro pour les assemblés sur tâche
        then
      v_situ               := ' ';
      v_couleur            := ' ';
      v_qt_utilisee_appro  := 0;

      update gal_need_follow_up
         set nfu_supply_type =
               decode(v_branche_desc
                    , 'O', (select pcs.pc_functions.translateword('Non approvisionné')
                              from dual)
                    , decode(v_lien_descriptif
                           , 'O', (select pcs.pc_functions.translateword('Non approvisionné')
                                     from dual)
                           , decode(a_nivo
                                  , 0, decode(v_lien_pseudo, 'O', (select pcs.pc_functions.translateword('Assemblé à l''affaire')
                                                                     from dual), nfu_supply_type)
                                  , nfu_supply_type
                                   )
                            )
                     )
           , nfu_available_quantity = decode(v_branche_desc, 'O', 0, decode(v_lien_descriptif, 'O', 0, v_qt_utilisee_dispo) )
           , nfu_missing_quantity = decode(v_branche_desc, 'O', 0, decode(v_lien_descriptif, 'O', 0, v_besoin_brut - v_qt_utilisee_dispo) )
           , nfu_info_supply = ' '
           , nfu_info_color_supply = ' '
           , nfu_supply_quantity = 0
           , nfu_to_launch_quantity = 0
       where gal_need_follow_up_id = v_id;
    end if;

    tableau_niveau(a_nivo).qte_a_induire        := v_besoin_a_induire;
    tableau_niveau(a_nivo).qte_a_induire_tot    := v_besoin_a_induire_tot;
    tableau_niveau(a_nivo).qte_besoin_brut      := v_besoin_brut;
    tableau_niveau(a_nivo).qte_besoin_net_need  := v_qte_besoin_net_need;
    --DBMS_OUTPUT.PUT_LINE('Tab Net : ' || v_sui_libart || ' - ' || to_char(v_qte_a_deduire_of));
    tableau_niveau(a_nivo).qte_a_deduire_of     := v_qte_a_deduire_of;
    tableau_niveau(a_nivo).lien_pseudo          := v_lien_pseudo;
    tableau_niveau(a_nivo).doc_record_id        := v_task_doc_record_id;
    tableau_niveau(a_nivo).on_df                := v_on_df;
    tableau_niveau(a_nivo).branche_df           := v_branche_df;
    tableau_niveau(a_nivo).assemblee            := v_assemblee;

    if nvl(a_nivo, 0) >= 1   --Lien pseudo sous DF, les composants sont rattachés au Df
                          then
      if v_lien_pseudo = 'O' then
        tableau_niveau(a_nivo).on_df                := tableau_niveau(a_nivo - 1).on_df;
        tableau_niveau(a_nivo).df_to_use_for_csant  := tableau_niveau(a_nivo - 1).df_to_use_for_csant;
      else
        tableau_niveau(a_nivo).on_df                := v_on_df;
        tableau_niveau(a_nivo).df_to_use_for_csant  := v_list_df_use;
      end if;
    else
      tableau_niveau(a_nivo).on_df                := v_on_df;
      tableau_niveau(a_nivo).df_to_use_for_csant  := v_list_df_use;
    end if;

    tableau_niveau(a_nivo).repartition          := v_repartition;   --sert a calculer le delai du niveu + 1
    tableau_niveau(a_nivo).type_gestion         := v_type_gestion;   --sert a calculer le delai du niveu + 1
    tableau_niveau(a_nivo).del_besoin_sup       := v_csant_del_supl;   --sert a calculer le delai du niveu + 1
    tableau_niveau(a_nivo).del_besoin_man       := v_csant_del_manuf;   --sert a calculer le delai du niveu + 1

    if a_nivo = 0 then
      tableau_niveau(a_nivo).del_besoin_net  := a_delai;   -- = 0
      tableau_niveau(a_nivo).dat_besoin_net  := a_date_besoin;   -- = DATE FIN TACHE
    else
      tableau_niveau(a_nivo).del_besoin_net  := a_delai + tableau_niveau(a_nivo - 1).del_besoin_net;   -- =   DELAI + DELAI NIVEAU N-1
      tableau_niveau(a_nivo).dat_besoin_net  := v_date_besoin_net;   -- = DATE BESOIN N-1 + DELAI
    end if;

    if v_branche_stock = 'N' then
      if (    v_branche_stock = 'N'
          and v_lien_pseudo = 'N'
          and v_branche_desc = 'N'
          and v_lien_descriptif = 'N'   --16/01
                                     --       AND ((v_type_gestion <> 'S') or (v_repartition = 'T') OR (v_type_gestion = 'S' AND (v_branche_of = 'N' OR (v_branche_da = 'O' AND v_force_appro = 'O') OR v_branche_assemblee = 'O')))
                                     /* appro sur df --> on a forcé le lecture des ressources pour le 1er niveau sous DF
                                        > les appro sont générés pas calcul de besoin sur DF */
         ) then
        --J'ECRIT LE TABLEAU FINAL
        --JE BOUCLE SUR LE TABLEAU FINAL POUR VOIR SI PAS DEJA UN ARTICLE IDENTIQUE A LA MEME DATE DE BESOIN
        v_flag_maj_qte       := 'N';
        v_flag_maj_qte_need  := 'N';

        --         IF a_nivo <> 0
        --         THEN
        --          IF 1 = 1
        --          THEN
        for v_line in 0 .. v_cpt loop
          begin
            if     tableau_niveau_final(v_line).article_id = tableau_niveau(a_nivo).article_id
               and tableau_niveau_final(v_line).dat_besoin_net = tableau_niveau(a_nivo).dat_besoin_net then   --JE MET A JOUR LA QTE DE BESOIN NET ....
              if     tableau_niveau_final(v_line).ggo_supply_mode = tableau_niveau(a_nivo).repartition
                 and tableau_niveau_final(v_line).ggo_supply_type = tableau_niveau(a_nivo).type_gestion
                                                                                                       --Si meme mode d'appro
              then
                if     tableau_niveau_final(v_line).branche_df = 'N'
                   and v_branche_df = 'N'
                                         --Si on n'est pas sur DF (composant)
                then
                  if tableau_niveau_final(v_line).compose_df = 'N' then
                    --Si on n'est pas sur DF (compose)
                    tableau_niveau_final(v_line).qte_besoin_net       := tableau_niveau_final(v_line).qte_besoin_net + tableau_niveau(a_nivo).qte_besoin_net;
                    tableau_niveau_final(v_line).qte_besoin_brut      := tableau_niveau_final(v_line).qte_besoin_brut + tableau_niveau(a_nivo).qte_besoin_brut;
                    v_flag_maj_qte                                    := 'O';
                    tableau_niveau_final(v_line).qte_besoin_net_need  :=
                                                                  tableau_niveau_final(v_line).qte_besoin_net_need + tableau_niveau(a_nivo).qte_besoin_net_need;
                    v_flag_maj_qte_need                               := 'O';
                    exit;
                  else
                    tableau_niveau_final(v_line).qte_besoin_net_need  :=
                                                                  tableau_niveau_final(v_line).qte_besoin_net_need + tableau_niveau(a_nivo).qte_besoin_net_need;
                    v_flag_maj_qte_need                               := 'O';
                    exit;
                  end if;
                end if;
              else   --Mode d'appro different, seul la quantité de besoin (Need) est mise à jour
                if     tableau_niveau_final(v_line).branche_df = 'N'
                   and v_branche_df = 'N'
                                         --Si on n'est pas sur un DF (composant)
                then
                  tableau_niveau_final(v_line).qte_besoin_net_need  :=
                                                                  tableau_niveau_final(v_line).qte_besoin_net_need + tableau_niveau(a_nivo).qte_besoin_net_need;
                  v_flag_maj_qte_need                               := 'O';
                  exit;
                end if;
              end if;
            end if;
          exception
            when no_data_found then
              v_flag_maj_qte  := 'N';
          end;
        end loop;

        --         END IF;
        if v_flag_maj_qte = 'N' then
          --.....SINON JE RAJOUTE LE BESOIN DANS LA TABLE FINAL
          v_cpt                                              := v_cpt + 1;
          tableau_niveau_final(v_cpt).tache_id               := tableau_niveau(a_nivo).tache_id;
          tableau_niveau_final(v_cpt).article_id             := tableau_niveau(a_nivo).article_id;
          tableau_niveau_final(v_cpt).qte_besoin_net         := tableau_niveau(a_nivo).qte_besoin_net;
          tableau_niveau_final(v_cpt).qte_besoin_brut        := tableau_niveau(a_nivo).qte_besoin_brut;
          tableau_niveau_final(v_cpt).del_besoin_net         := tableau_niveau(a_nivo).del_besoin_net;
          tableau_niveau_final(v_cpt).dat_besoin_net         := tableau_niveau(a_nivo).dat_besoin_net;
          tableau_niveau_final(v_cpt).doc_record_id          := tableau_niveau(a_nivo).doc_record_id;
          tableau_niveau_final(v_cpt).ggo_supply_type        := v_type_gestion;
          tableau_niveau_final(v_cpt).ggo_supply_mode        := v_repartition;
          tableau_niveau_final(v_cpt).ggo_unit_of_measure    := v_unite_stock;
          tableau_niveau_final(v_cpt).branche_of             := v_branche_of;
          tableau_niveau_final(v_cpt).branche_da             := v_branche_da;
          tableau_niveau_final(v_cpt).branche_df             := v_branche_df;
          tableau_niveau_final(v_cpt).branche_assemblee      := v_branche_assemblee;
          tableau_niveau_final(v_cpt).compose_df             := v_on_df;
          tableau_niveau_final(v_cpt).branche_df_launch      := v_branche_df_launch;
          tableau_niveau_final(v_cpt).force_appro            := v_force_appro;
          tableau_niveau_final(v_cpt).lien_pseudo            := tableau_niveau(a_nivo).lien_pseudo;
          tableau_niveau_final(v_cpt).affaire_id             := x_aff_id;
          tableau_niveau_final(v_cpt).tac_cat_id             := v_task_cta_id;
          tableau_niveau_final(v_cpt).bud_id                 := v_bud_id;
          tableau_niveau_final(v_cpt).gsm_nom_path           := '/' || trim(to_char(v_gml_sequence) ) || '-' || trim(to_char(v_taches_art_id) ) || v_pps_path;
          tableau_niveau_final(v_cpt).task_good_id           := v_task_good_id;
          tableau_niveau_final(v_cpt).pps_nom_header         := pps;
          tableau_niveau_final(v_cpt).pps_nomenclature_id    := v_pps_pps_nomenclature_id;

          if v_flag_maj_qte_need = 'N' then
            tableau_niveau_final(v_cpt).qte_besoin_net_need  := tableau_niveau(a_nivo).qte_besoin_net_need;   --v_qte_besoin_net_need;
          else
            tableau_niveau_final(v_cpt).qte_besoin_net_need  := 0;
          end if;   --Mise à jour au dessus (la nouvelle ligne du tableau est à 0 pour les qte Need)

          tableau_niveau_final(v_cpt).gco_short_description  := v_sui_libart;
          tableau_niveau_final(v_cpt).gco_long_description   := v_sui_long_descr;
          tableau_niveau_final(v_cpt).del_besoin_sup         := v_csant_del_supl;
          tableau_niveau_final(v_cpt).del_besoin_man         := v_csant_del_manuf;
          tableau_niveau_final(v_cpt).df_to_use_for_csant    := tableau_niveau(a_nivo).df_to_use_for_csant;
        end if;
      end if;
    end if;   --FIN SIMULATION N
  end besoins_net;

--**********************************************************************************************************--
--*******************************************************************************************************--
  procedure RAZ_VAR
  is
  begin
    v_level                    := 1;
    v_branche_of               := 'N';
    v_flag_nivo_of             := 9999;
    v_branche_da               := 'N';
    v_flag_nivo_da             := 9999;
    v_branche_desc             := 'N';
    v_flag_nivo_desc           := 9999;
    v_branche_stock            := 'N';
    v_flag_nivo_gestion_stock  := 9999;
    v_lien_pseudo              := 'N';
    v_force_appro              := 'N';
    v_flag_nivo                := 0;
    v_branche_df               := 'N';
    v_branche_df_launch        := 'N';
    v_qte_a_deduire_of         := 0;
    v_compose_df               := 'N';
    v_on_df                    := 'N';
    v_branche_df               := 'N';
    v_task_good_df             := 'N';
    v_nivo                     := 0;
    v_delai_obt                := 0;
    v_header_repart            := 'T';
    v_nfu_supply_mode          := 'InNomen';
    v_cpt_doc                  := 0;
    v_list_doc                 := ';';
    v_flag_doc                 := 0;
  end RAZ_VAR;

--**********************************************************************************************************--
--**********************************************************************************************************--
--**********************************************************************************************************--

  -- hmo 11.2012 -> gestion de la notion de sorti <> dispo affaire  (matériel acheté à l'affaire dont le gabarit est à dispo / OF réceptionné / DF dans e gabarit entrée dossier fab) <> sorti sorti dans le doc besoin affaire  ou pour un DF dans un DF (soirti dossier de fabrication)
  -- le matériel stock n'est plus jamais dispo affaire il est directmenet en état sorti
  procedure main(a_aff_id gal_project.gal_project_id%type default 0, a_tac_id gal_task.gal_task_id%type default 0, a_sessionid number, a_trace char)
  is
    v_task_tas_state    gal_task.c_tas_state%type;
    v_task_tac_date_deb gal_task.tas_start_date%type;
    v_task_tac_date_fin gal_task.tas_end_date%type;
    v_task_libel_tache  gal_task.tas_wording%type;
    v_to_launch_qty     number;

    cursor c_task
    is
      select   gal_task_id
             , gal_task.gal_project_id
             , gal_task_category.gal_task_category_id
             , c_tas_state
             , tas_start_date
             , tas_end_date
             , tas_code
             , tas_wording
             , gal_task.doc_record_id
             , prj_code
             , gal_task.gal_budget_id
          from gal_project
             , gal_task_category
             , gal_task
         where gal_task_category.gal_task_category_id = gal_task.gal_task_category_id
           and gal_task_category.c_tca_task_type = '1'
           and gal_project.gal_project_id = a_aff_id
           and gal_task.gal_task_id = a_tac_id
           and gal_father_task_id is null
      order by tas_code;

    cursor c_task_good
    is
      select   gal_task_good.gal_task_good_id
             , gal_task_good.gco_good_id
             , pps_nomenclature_id
             , gal_task_good.gml_quantity
             , gal_task_good.gal_task_id
             , v_task_aff_id
             , v_task_tac_date_fin
             , gal_good.ggo_unit_of_measure
             , null
             , gal_good.ggo_major_reference
             , gal_good.ggo_short_description
             , decode(trim(gal_task_good.gml_description), '', gal_good.ggo_long_description, gal_task_good.gml_description)
             , gal_good.ggo_plan_number
             , gal_good.ggo_supply_mode
             , gal_good.ggo_supply_type
             , gal_good.ggo_unit_of_measure
             , nvl(gal_good.ggo_obtaining_delay, 0)
             , nvl(gal_good.GGO_SUPPLY_DELAY, 0)
             , nvl(gal_good.GGO_MANUFACTURING_DELAY, 0)
             , gml_sequence
          from gal_task_good
             , v_gal_pcs_good gal_good
         where gal_task_good.gco_good_id = gal_good.gal_good_id
           and gal_task_good.gal_task_id = v_task_tac_id
           and v_task_tac_date_deb is not null
           and v_task_tac_date_fin is not null
      order by gal_task_good.gal_task_id
             , gal_task_good.gml_sequence;
  begin
    v_cpt          := 0;
    x_trace        := a_trace;
    v_from_cse_df  := 'N';
    x_aff_id       := a_aff_id;
    x_sessionid    := a_sessionid;
    Init_config;

    select pcs.pc_config.getconfig('GAL_MANUFACTURING_MODE')
      into v_manufacturing_mode
      from dual;

    if     v_flag_simulation = 'N'
       and v_manufacturing_mode = '1' then
      begin
        select DOC_GAUGE_NUMBERING_ID
          into V_DOC_GAUGE_NUMBERING_ID
          from DOC_GAUGE_NUMBERING
         where GAN_DESCRIBE = (select pcs.pc_config.getconfig('GAL_NUMBERING_MANUFACTURE')
                                 from dual);
      exception
        when no_data_found then
          V_DOC_GAUGE_NUMBERING_ID  := null;
          WriteErrorInResult(a_tac_id, 0, 1, 0, pcs.pc_functions.translateword('Dossiers de fabrication : Manque compteur automatique') );
      end;
    end if;

    select pcs.pc_functions.translateword('Pseudo')
      into v_pseudo_text
      from dual;

    --Pour test en base depuis TOAD
    --v_manufacturing_mode := '2';

    /*Mode de gestion de la fabrication dans le module Affaire.
     '1' = Fabrication sur DF (dossier de fabrication)
     '2' = Fabrication sur OF (Ordre de fabrication)
    */
    Load_Project_Waste(a_tac_id);

    --V_FLAG_TAC_ID := NULL;
    open c_task;

    loop
      fetch c_task
       into v_task_tac_id
          , v_task_aff_id
          , v_task_cta_id
          , v_task_tas_state
          , v_task_tac_date_deb
          , v_task_tac_date_fin
          , v_task_no_tache
          , v_task_libel_tache
          , v_task_doc_record_id
          , v_task_no_affaire
          , v_bud_id;

      exit when c_task%notfound;
--***********************************************************************--
--CHARGEMENT DES RESSOURCES (OA/CDE/OF/RESERVATIONS STOCK/SORTIES STOCK) --
--***********************************************************************--
      load_resource(v_task_tac_id, v_task_doc_record_id, '0');
--***********************************************************************--
      v_situ         := ' ';
      v_couleur      := ' ';
      outdocumentid  := null;
      outpositionid  := null;
      astockid       := null;
      alocationid    := null;
      tableau_niveau_final.delete;
      tableau_document.delete;

      --IF v_flag_simulation = 'O'
      --LA LIGNE D'ENTETE TACHE EST TOUJOURS CREEE MEME SI AUCUN GAL_TASK_GOOD
      --THEN
      --IF NVL(V_FLAG_TAC_ID,0) <> v_task_TAC_ID
      --THEN
      select decode(v_task_tas_state
                  , '10', (select pcs.pc_functions.translateword('Nouvelle')
                             from dual)
                  , '20', (select pcs.pc_functions.translateword('Lancée')
                             from dual)
                  , '30', (select pcs.pc_functions.translateword('Commencée')
                             from dual)
                  , '40', (select pcs.pc_functions.translateword('Soldée')
                             from dual)
                  , '99', (select pcs.pc_functions.translateword('Suspendue')
                             from dual)
                  , ' '
                   )
        into v_situ
        from dual;

      RAZ_VAR;
      init_need_follow_up(y_aff_id             => v_task_aff_id
                        , y_tac_id             => v_task_tac_id
                        , y_level              => 0
                        , y_repere             => ' '
                        , y_art_id             => null   --'Tâches'
                        , y_codart             => v_task_no_tache
                        , y_libart             => v_task_libel_tache
                        , y_plan               => null
                        , y_type_gest          => null
                        , y_repart             => null
                        , y_qte_lien           => null
                        , y_besoin_net         => null
                        , y_besoin_brut        => null
                        , y_unite              => null
                        , y_date_besoin_net    => v_task_tac_date_fin
                        , y_com_seq            => null
                        , y_art_tete_id        => null
                        , y_com_seq_tete       => null
                        , y_besoin_stock_df    => 0
                        , iInterNeedQuantity   => 0
                         );

      --END IF;
      --V_FLAG_TAC_ID := v_task_TAC_ID;
      --END IF;
      open c_task_good;

      --****BOUCLE GAL_PROJECT/GAL_TASK/GAL_TASK_GOOD****--
      loop
        fetch c_task_good
         into v_task_good_id
            , v_taches_art_id
            , pps
            , v_taches_quantite
            , v_taches_tac_id
            , v_taches_aff_id
            , v_taches_date_fin
            , v_unite_stock
            , v_sui_repere
            , v_sui_codart
            , v_sui_libart
            , v_sui_long_descr
            , v_sui_plan
            , v_repartition
            , v_type_gestion
            , v_sui_un_st
            , v_compose_del_obt
            , v_del_supl
            , v_del_manuf
            , v_gml_sequence;

        exit when c_task_good%notfound;
        tableau_niveau.delete;
        --          tableau_niveau_final.DELETE;
        --            tableau_document.DELETE;
        tableau_stock.delete;
        --            v_cpt := 0;
        v_lien_descriptif          := 'N';   --26/06/06 LSE : lien descriptif et/ou non approvisionné.
        RAZ_VAR;
        --Pour le composant
        GetSupplyMode('0'
                    , v_repartition
                    , v_type_gestion
                    , '/' || trim(to_char(v_gml_sequence) ) || '-' || trim(to_char(v_taches_art_id) )
                    , v_task_tac_id
                    , pps
                    , v_taches_art_id
                     );
        v_header_repart            := v_repartition;
        v_csant_del_manuf          := v_del_manuf;

        --            IF v_repartition = 'F' THEN
        --              --Suppression des ressources Composant DF por les FAB (Ressource est le compose DF, sinon Surplus)
        --              DELETE FROM GAL_PROJECT_RESOURCE WHERE PJR_SORT = '6DG' AND GAL_GOOD_ID = v_taches_art_id;
        --            END IF;

        --if v_repartition = 'T' AND v_type_gestion <> 'S' then v_lien_pseudo := 'O';end if;
        if v_on_df = 'O' then
          v_task_good_df  := 'O';
        else
          v_task_good_df  := 'N';
        end if;

        if v_supply_mode = 'T' then
          v_task_good_assemblee  := 'O';
          v_lien_pseudo          := 'O';
        else
          v_task_good_assemblee  := 'N';
        end if;

        if v_type_gestion = 'F' then
          v_situ     := ' ';
          v_couleur  := ' ';
        end if;

        if v_lien_descriptif = 'O' then   --26/06/06 LSE : Si article de tete est descriptif.
          v_flag_nivo_desc  := 0;
          v_branche_desc    := 'O';
        end if;

        v_pps_path                 := null;
        v_pps_pps_nomenclature_id  := nvl(pps, 0);
        --****ECRITURE BESOIN 1er niveau (Tache) ****--
        besoins_net(v_taches_art_id, v_taches_tac_id, v_taches_quantite, v_taches_date_fin, 0, 0);   -- 0 = DELAI ; 0 = NIVEAU NOMAFF

        if v_repartition = 'F' then
          v_branche_of    := 'O';
          v_branche_da    := 'N';
          v_flag_nivo_of  := 0;
        elsif v_repartition = 'A' then
          v_branche_da    := 'O';
          v_branche_of    := 'N';
          v_flag_nivo_da  := 0;
        end if;

        if v_type_gestion <> 'S'
                                --SI ARTICLE GAL_TASK_GOOD GERE SUR STOCK ALORS, ON DESCEND PAS LA NOMENCLAURE
        then
          open c_pps_nomen;

          --****BOUCLE NOMENCLATURE : PPS_NOMENCLATURE + PPS_NOM_BOND  (avec un gco_good_id qui peut etre un pps_nomenclature_id ) ****--
          loop
            fetch c_pps_nomen
             into v_compose
                , v_composant
                , v_qt_lien
                , v_del_ajust
                , v_nivo
                , v_lien_descriptif
                , v_lien_pseudo
                , v_lien_texte
                , v_sui_repere
                , v_com_seq
                , v_pps_nom_bond_id
                , v_pps_nomenclature_id
                , v_pps_pps_nomenclature_id
                , v_pps_path;

            exit when c_pps_nomen%notfound;

            if     v_lien_texte = 'O'
               and trim(v_composant) is null then
              null;
            else
              ReadInfoGcoGood(v_compose, v_composant, 1);
              --Si modif manuelle du mode d'appro pour le composant
              GetSupplyMode('0'
                          , v_repartition
                          , v_type_gestion
                          , '/' || trim(to_char(v_gml_sequence) ) || '-' || trim(to_char(v_taches_art_id) ) || v_pps_path
                          , v_task_tac_id
                          , pps
                          , v_composant
                           );
              GetCseObtainingDelay;   --corrige le delai d'obtention du compose si changement de mode d'appro
              --                  IF v_repartition = 'F' THEN
              --                    --Suppression des ressources Composant DF por les FAB (Ressource est le compose DF, sinon Surplus)
              --                    DELETE FROM GAL_PROJECT_RESOURCE WHERE PJR_SORT = '6DG' AND GAL_GOOD_ID = v_composant;
              --                  END IF;
              v_level      := v_nivo + 1;

              if v_nivo < v_flag_nivo
                                     --J'AI DESCENDU TOUTES LA BRANCHE ET REMONTE D'UN OU PLUSIEURS NIVEAUX
              then
                tableau_niveau.delete(v_nivo, v_flag_nivo);
              --**JE SUPPRIME DU TABLEAU TOUTES LES LIGNES DE LA BRANCHE QUE JE VIENS DE TRAITER
              end if;

--*****************************************************************--
--*** GESTION DES MODES D'APPRO (SUIVI ET CALCUL)  = OF       **** --
--*****************************************************************--
              if v_nivo > v_flag_nivo_of then
                v_branche_of  := 'O';
              else
                v_branche_of    := 'N';
                v_flag_nivo_of  := 9999;   --REPOSITIONNE LE FLAG NIVO A 9999
              end if;

              if     v_repartition = 'F'
                 and v_flag_nivo_of <> 0
                 and v_branche_of = 'N' then
                v_flag_nivo_of  := v_nivo;
              end if;

--*****************************************************************--
--*** GESTION DES MODES D'APPRO (SUIVI ET CALCUL)  =  HA   ******* --
--*****************************************************************--
              if v_nivo > v_flag_nivo_da then
                v_branche_da  := 'O';

                if v_flag_nivo_da > v_flag_nivo_of then
                  v_force_appro  := 'O';
                else
                  v_force_appro  := 'N';
                end if;
              else
                v_branche_da    := 'N';
                v_flag_nivo_da  := 9999;   --REPOSITIONNE LE FLAG NIVO A 9999
                v_force_appro   := 'N';
              end if;

              if     v_repartition = 'A'
                 and v_flag_nivo_da <> 0
                 and v_branche_da = 'N' then
                v_flag_nivo_da  := v_nivo;
              end if;

--****************************************************--
--*** GESTION DES ARTICLE TYPE GESTION = STOCK ****** --
--****************************************************--
              if v_nivo > v_flag_nivo_gestion_stock then
                v_branche_stock  := 'O';
              else
                v_branche_stock            := 'N';
                v_flag_nivo_gestion_stock  := 9999;   --REPOSITIONNE LE FLAG NIVO A 9999
              end if;

              if     v_type_gestion = 'S'
                 and v_branche_stock = 'N' then
                v_flag_nivo_gestion_stock  := v_nivo;
              end if;

--****************************************************--
--*** GESTION DES LIENS DESCRIPTIFS*******************--
--****************************************************--
              if     v_lien_descriptif = 'O'
                 and v_branche_desc = 'N'   --26/06/06 LSE : Si article de tete est descriptif.
                                         then
                v_flag_nivo_desc  := v_nivo;
              end if;

              if v_nivo > v_flag_nivo_desc then
                v_branche_desc  := 'O';
              else
                if v_lien_descriptif = 'N' then
                  v_branche_desc    := 'N';
                  v_flag_nivo_desc  := 9999;   --REPOSITIONNE LE FLAG NIVO A 9999
                end if;
              end if;

              besoins_net(v_composant, v_taches_tac_id, v_qt_lien, null,   --> Date de besoin est calculé dans "Use_resource"
                          v_del_ajust - v_delai_obt,   --> Délai aujust. nomenc.(décalage) - délai obt. du compose (varie selon mode d'appro)
                          v_nivo);
              v_flag_nivo  := v_nivo;
            end if;   --Lien texte
          end loop;

          close c_pps_nomen;
        end if;
      /*
                 IF v_flag_simulation = 'N'
                 THEN
                     --ON LIT LE TABLEAU DES BESOIN NET POUR GENERER LES APPROS (OA,OF) ET BESOINS AFFAIRE;
                     --UNE SEULE ENTITE GENERéE PAR GAL_PROJECT,TACHE,ARTICLE,DATE_BESOIN (CUMUL QTE GERé DANS LE TABLEAU)
                     --RECALAGE EVENTUELLE DE DATE OA OF ET RESERVATIONS
                     FOR v_line IN 1 .. v_cpt
                     LOOP
                        IF x_trace = 'O'
                        THEN
                           --*****TRACE TABLEAU FINAL ******--
                           INSERT INTO gal_project_need
                                       (gal_project_need_id,
                                        gal_task_id,
                                        gal_good_id,
                                        pjn_quantity,
                                        pjn_need_date
                                       )
                                VALUES (gal_project_need_id_seq.NEXTVAL,
                                        v_taches_tac_id,
                                        tableau_niveau_final (v_line).article_id,
                                        tableau_niveau_final (v_line).qte_besoin_brut,
                                        tableau_niveau_final (v_line).dat_besoin_net
                                       );
                        END IF;

                        IF     tableau_niveau_final (v_line).ggo_supply_type <> 'F'
                           AND tableau_niveau_final (v_line).ggo_supply_mode <> 'T'
                           AND tableau_niveau_final (v_line).lien_pseudo = 'N'
                        THEN

                           --Traitement FABRICATION
                           IF     tableau_niveau_final (v_line).ggo_supply_type = 'A'
                              AND tableau_niveau_final (v_line).ggo_supply_mode = 'F'
                              AND (tableau_niveau_final (v_line).qte_besoin_net <> 0
                               OR tableau_niveau_final (v_line).qte_besoin_net_need <> 0)
                           THEN

                             IF (v_manufacturing_mode = '1' AND tableau_niveau_final (v_line).compose_df = 'O')
                               OR tableau_niveau_final (v_line).compose_df = 'O' --SUR DF
                             THEN
                                    astockid := v_stm_stock_id_project;
                                    alocationid :=  v_stm_location_id_project;
                                    IF tableau_niveau_final (v_line).qte_besoin_net <> 0
                                      THEN generate_supply_manufacture (v_line); END IF;
                                    IF tableau_niveau_final (v_line).branche_df = 'N'
                                    THEN
                                      IF tableau_niveau_final (v_line).qte_besoin_net_need <> 0
                                      THEN generate_need_project (v_line,tableau_niveau_final (v_line).qte_besoin_net_need); END IF;
                                    END IF;
                             ELSE --SUR OF MAIS COMPOSE NON FABRIQUE SUR DF (DF CREE MANUELLEMENT)
                                  astockid := v_stm_stock_id_project;
                                  alocationid :=  v_stm_location_id_project;
                                  IF tableau_niveau_final (v_line).qte_besoin_net <> 0
                                    THEN generate_supply_lot (v_line); END IF;
                                  IF tableau_niveau_final (v_line).qte_besoin_net_need <> 0
                                    THEN generate_need_project (v_line,tableau_niveau_final (v_line).qte_besoin_net_need); END IF;
                             END IF;
                           END IF;

                           --Traitement ACHAT
                           IF     tableau_niveau_final (v_line).ggo_supply_type = 'A'
                              AND tableau_niveau_final (v_line).ggo_supply_mode = 'A'
                              AND (tableau_niveau_final (v_line).qte_besoin_net <> 0 OR tableau_niveau_final (v_line).qte_besoin_net_need <> 0)
                              AND tableau_niveau_final (v_line).branche_df = 'N'
                           THEN
                              astockid := v_stm_stock_id_project;
                              alocationid :=  v_stm_location_id_project;
                              IF tableau_niveau_final (v_line).qte_besoin_net <> 0
                                THEN generate_supply_request (v_line, v_Type_Supply_To_Generate_TA); END IF;
                              IF tableau_niveau_final (v_line).qte_besoin_net_need <> 0 AND tableau_niveau_final (v_line).branche_df = 'N'
                                THEN generate_need_project (v_line,tableau_niveau_final (v_line).qte_besoin_net_need); END IF;
                           END IF;

                           --Traitement STOCK
                           / *
                           DBMS_OUTPUT.PUT_LINE ('TRACE AVANT WRITE : ' || tableau_niveau_final (v_line).gco_short_description
                                                || '-' || tableau_niveau_final (v_line).ggo_supply_type || '-' || tableau_niveau_final (v_line).ggo_supply_mode
                                                 || '-' || to_char(tableau_niveau_final (v_line).qte_besoin_net) || '-' || tableau_niveau_final (v_line).branche_of
                                                || '-' || tableau_niveau_final (v_line).branche_da || '-' || tableau_niveau_final (v_line).force_appro
                                                || '-' || tableau_niveau_final (v_line).branche_assemblee || '-' || tableau_niveau_final (v_line).branche_df);
                           * /

                           IF     (tableau_niveau_final (v_line).ggo_supply_type = 'S')
                                   --OR //plus d'appro pour les assemblés sur tâche
                                   --tableau_niveau_final (v_line).ggo_supply_mode = 'T')
                              AND tableau_niveau_final (v_line).qte_besoin_net <> 0
      --16/01
      --                        AND (tableau_niveau_final (v_line).branche_of = 'N'
      --                             OR
      --                            (tableau_niveau_final (v_line).branche_da = 'O' AND tableau_niveau_final (v_line).force_appro = 'O')
      --                             OR
      --                             tableau_niveau_final (v_line).branche_assemblee = 'O')
                              AND tableau_niveau_final (v_line).branche_df = 'N'
                                --> generation des documents besoin pour articles HA également
                           THEN
                              Init_location_stk_product_stoc(tableau_niveau_final (v_line).article_id,v_task_tac_id);
                              generate_need_project (v_line,tableau_niveau_final (v_line).qte_besoin_net);
                           END IF;

                           / *
                           --Traitement des Composants DF -- ON attend d'y voir plus clair
                           IF tableau_niveau_final (v_line).branche_df = 'O'
                           THEN
                             generate_componant_manufacture (v_line);
                           END IF;
                           * /

                        END IF;
                     END LOOP;

                     --****************************************************--
                  END IF;
      */
      end loop;

      close c_task_good;

--*******************************************************--
--*******************************************************--
      if v_flag_simulation = 'N' then
        --ON LIT LE TABLEAU DES BESOIN NET POUR GENERER LES APPROS (OA,OF) ET BESOINS AFFAIRE;
        --UNE SEULE ENTITE GENERéE PAR GAL_PROJECT,TACHE,ARTICLE,DATE_BESOIN (CUMUL QTE GERé DANS LE TABLEAU)
        --RECALAGE EVENTUELLE DE DATE OA OF ET RESERVATIONS
        for v_line in 0 .. v_cpt loop
          begin
            if x_trace = 'O' then
              --*****TRACE TABLEAU FINAL ******--
              insert into gal_project_need
                          (gal_project_need_id
                         , gal_task_id
                         , gal_good_id
                         , pjn_quantity
                         , pjn_need_date
                          )
                   values (gal_project_need_id_seq.nextval
                         , v_taches_tac_id
                         , tableau_niveau_final(v_line).article_id
                         , tableau_niveau_final(v_line).qte_besoin_brut
                         , tableau_niveau_final(v_line).dat_besoin_net
                          );
            end if;

            if     tableau_niveau_final(v_line).ggo_supply_type <> 'F'
               and tableau_niveau_final(v_line).ggo_supply_mode <> 'T'
               and tableau_niveau_final(v_line).lien_pseudo = 'N' then
              --Traitement FABRICATION
              if     tableau_niveau_final(v_line).ggo_supply_type = 'A'
                 and tableau_niveau_final(v_line).ggo_supply_mode = 'F'
                 and (   tableau_niveau_final(v_line).qte_besoin_net <> 0
                      or tableau_niveau_final(v_line).qte_besoin_net_need <> 0) then
                if    (    v_manufacturing_mode = '1'
                       and tableau_niveau_final(v_line).compose_df = 'O')
                   or tableau_niveau_final(v_line).compose_df = 'O'   --SUR DF
                                                                   then
                  astockid     := v_stm_stock_id_project;
                  alocationid  := v_stm_location_id_project;

                  if tableau_niveau_final(v_line).qte_besoin_net <> 0 then
                    generate_supply_manufacture(v_line);
                  end if;

                  if tableau_niveau_final(v_line).branche_df = 'N' then
                    if tableau_niveau_final(v_line).qte_besoin_net_need <> 0 then
                      generate_need_project(v_line, tableau_niveau_final(v_line).qte_besoin_net_need);
                    end if;
                  end if;
                else   --SUR OF MAIS COMPOSE NON FABRIQUE SUR DF (DF CREE MANUELLEMENT)
                  astockid     := v_stm_stock_id_project;
                  alocationid  := v_stm_location_id_project;

                  if tableau_niveau_final(v_line).qte_besoin_net <> 0 then
                    generate_supply_lot(v_line);
                  end if;

                  if tableau_niveau_final(v_line).qte_besoin_net_need <> 0 then
                    generate_need_project(v_line, tableau_niveau_final(v_line).qte_besoin_net_need);
                  end if;
                end if;
              end if;

              --Traitement ACHAT
              if     tableau_niveau_final(v_line).ggo_supply_type = 'A'
                 and tableau_niveau_final(v_line).ggo_supply_mode = 'A'
                 and (   tableau_niveau_final(v_line).qte_besoin_net <> 0
                      or tableau_niveau_final(v_line).qte_besoin_net_need <> 0)
                 and tableau_niveau_final(v_line).branche_df = 'N' then
                astockid     := v_stm_stock_id_project;
                alocationid  := v_stm_location_id_project;

                if tableau_niveau_final(v_line).qte_besoin_net <> 0 then
                  generate_supply_request(v_line, v_Type_Supply_To_Generate_TA);
                end if;

                if     tableau_niveau_final(v_line).qte_besoin_net_need <> 0
                   and tableau_niveau_final(v_line).branche_df = 'N' then
                  generate_need_project(v_line, tableau_niveau_final(v_line).qte_besoin_net_need);
                end if;
              end if;

              --Traitement STOCK
              /*
              DBMS_OUTPUT.PUT_LINE ('TRACE AVANT WRITE : ' || tableau_niveau_final (v_line).gco_short_description
                                   || '-' || tableau_niveau_final (v_line).ggo_supply_type || '-' || tableau_niveau_final (v_line).ggo_supply_mode
                                    || '-' || to_char(tableau_niveau_final (v_line).qte_besoin_net) || '-' || tableau_niveau_final (v_line).branche_of
                                   || '-' || tableau_niveau_final (v_line).branche_da || '-' || tableau_niveau_final (v_line).force_appro
                                   || '-' || tableau_niveau_final (v_line).branche_assemblee || '-' || tableau_niveau_final (v_line).branche_df);
              */
              if     (tableau_niveau_final(v_line).ggo_supply_type = 'S')   --OR //plus d'appro pour les assemblés sur tâche
                 --tableau_niveau_final (v_line).ggo_supply_mode = 'T')
                 and tableau_niveau_final(v_line).qte_besoin_net <> 0   --16/01
                 --                        AND (tableau_niveau_final (v_line).branche_of = 'N'
                 --                             OR
                 --                            (tableau_niveau_final (v_line).branche_da = 'O' AND tableau_niveau_final (v_line).force_appro = 'O')
                 --                             OR
                 --                             tableau_niveau_final (v_line).branche_assemblee = 'O')
                 and tableau_niveau_final(v_line).branche_df = 'N'
                                                                  --> generation des documents besoin pour articles HA également
              then
                Init_location_stk_product_stoc(tableau_niveau_final(v_line).article_id, v_task_tac_id);
                generate_need_project(v_line, tableau_niveau_final(v_line).qte_besoin_net);
              end if;
            /*
            --Traitement des Composants DF -- ON attend d'y voir plus clair
            IF tableau_niveau_final (v_line).branche_df = 'O'
            THEN
              generate_componant_manufacture (v_line);
            END IF;
            */
            end if;
          exception
            when no_data_found then
              null;
          end;
        end loop;
      end if;

--*******************************************************--
--*******************************************************--
      doc_finalize_finalizedocument(v_cpt_doc, v_task_tac_id, v_taches_art_id);

      --Pour la finalisation, le good_id est pris de facon aléatoire
      /*
      IF v_cpt_doc > 0
      THEN--Finalisation des documents générés par le calcul
        FOR v_line_doc IN 1 .. v_cpt_doc
        LOOP
          doc_finalize.finalizedocument(tableau_document(v_line_doc).docid);
        END LOOP;
      END IF;
      */

      --AVANT LE DELETE SUR RESSOURCE AFFAIRE, JE RENSEIGNE LES EVENTUELLES SURPLUS DANS LA TABLE RESULTAT Du CALCUL GAL_PROJECT....
      --Egalisation des NEED (surplus > update ou delete sur Doc NEED)

      --**CREATION POUR L'HISTORIQUE NOMENCLATURE **--
      insert into GAL_PROJECT_SUPPLY_MODE
                  (GAL_PROJECT_SUPPLY_MODE_ID
                 , GAL_TASK_GOOD_ID
                 , C_PROJECT_SUPPLY_MODE
                 , GSM_DESCRIPTION
                 , GSM_COMMENT
                 , A_IDCRE
                 , A_DATECRE
                 , A_IDMOD
                 , A_DATEMOD
                 , PPS_NOM_BOND_ID
                 , GSM_NOM_PATH
                 , C_PROJECT_SUPPLY_MODE_OLD
                 , GSM_NOM_LEVEL
                 , PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , GAL_FATHER_TASK_ID
                 , GAL_TASK_ID
                 , PPS_NOMENCLATURE_HEADER_ID
                 , GSM_ALLOW_UPDATE
                  )
        select   NEED.GAL_NEED_FOLLOW_UP_ID
               , NEED.GAL_TASK_GOOD_ID
               , decode(trim(NFU_SUPPLY_TYPE), trim(v_pseudo_text), '4', GetDeftSupplyMode(NEED.GGO_SUPPLY_TYPE, NEED.GGO_SUPPLY_MODE) )
               , null
               , null
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
               , null
               , null
               , nvl(NEED.PPS_NOM_BOND_ID, 0)
               , NEED.GSM_NOM_PATH
               , decode(trim(NFU_SUPPLY_TYPE), trim(v_pseudo_text), '4', GetDeftSupplyMode(NEED.GGO_SUPPLY_TYPE, NEED.GGO_SUPPLY_MODE) )
               , NEED.GSM_NOM_LEVEL
               , NEED.PPS_NOMENCLATURE_ID
               , NEED.GCO_GOOD_ID
               , NEED.GAL_TASK_ID
               ,   --ID TACHE APPRO
                 null
               ,   --ID DOSSIER FAB
                 NEED.PPS_NOMENCLATURE_HEADER_ID
               , decode(trim(NFU_SUPPLY_TYPE), trim(v_pseudo_text), -1, 1)
            from GAL_NEED_FOLLOW_UP NEED
           where not exists(
                   select '*'
                     from GAL_PROJECT_SUPPLY_MODE NOMEN
                    where NOMEN.GSM_NOM_PATH = NEED.GSM_NOM_PATH
                      and nvl(NOMEN.PPS_NOMENCLATURE_HEADER_ID, 0) = nvl(NEED.PPS_NOMENCLATURE_HEADER_ID, 0)
                      and nvl(NOMEN.PPS_NOMENCLATURE_ID, 0) = nvl(NEED.PPS_NOMENCLATURE_ID, 0)
                      /*
                      AND NOT EXISTS (SELECT '*' FROM GAL_PROJECT_SUPPLY_MODE NOMEN2
                                      WHERE NOMEN.PPS_NOMENCLATURE_HEADER_ID = NOMEN2.PPS_NOMENCLATURE_HEADER_ID
                                      AND NOMEN.PPS_NOMENCLATURE_ID = NOMEN2.PPS_NOMENCLATURE_ID
                                      AND NOMEN.GAL_TASK_GOOD_ID = NOMEN.GAL_TASK_GOOD_ID
                                      AND ROWNUM = 1)
                      */
                      and nvl(NOMEN.GAL_TASK_GOOD_ID, 0) = nvl(NEED.GAL_TASK_GOOD_ID, 0)
                      and rownum = 1)
             and NEED.GSM_NOM_LEVEL <> 0
        order by NEED.GAL_NEED_FOLLOW_UP_ID;

      --**Egalisation des NEED **--
      --    Désactivé tant qu'on n'a pas de plsql d'update de positio_detail
      /*
      IF v_flag_simulation = 'N'
      THEN
        Need_balance(v_task_tac_id,'3BA');
      END IF;
      */

      --**CREATION POUR SUIVI DES SURPLUS **--
      if v_flag_simulation = 'O' then
        INIT_SURPLUS(v_task_tac_id, '0', '0');
      end if;

      if v_flag_simulation = 'O' then
        INIT_REMAINING_COMPONANT(v_task_tac_id);
      end if;

      if     v_flag_simulation = 'N'
         and v_task_tac_date_deb is not null
         and v_task_tac_date_fin is not null then
        update GAL_TASK
           set tas_task_must_be_launch = 0
             , TAS_LAST_CALCULATION_DATE = sysdate
         where GAL_TASK_ID = a_tac_id;
      end if;
    end loop;

    close c_task;

    PutInfoRessDocumentWaste(v_task_tac_id, a_aff_id);

    --hmo 11.2012 _> le flag est à sorti que si tout le dispo affaire = sorti et rien à lancer et rien en appro
    update gal_need_follow_up
       set nfu_info_supply =
             (case
                when nfu_available_quantity = nfu_stm_project_quantity_out
                and nvl(nfu_to_launch_quantity, 0) = 0
                and nvl(nfu_supply_quantity, 0) = 0 then pcs.pc_functions.translateword('Sorti')
                else nfu_info_supply
              end
             );

    -- Matériel stock plus jamais en état dispo affaire , la colonne sorti a déjà été màj voir modif hmo 11.2012
    update gal_need_follow_up
       set nfu_available_quantity = null
     where ggo_supply_type = 'S'
       and ggo_supply_mode = 'S'
       and nvl(nfu_available_quantity, 0) > 0;   -- si jamais on a déjà mis à jour dans un autre étage de éla nomenclature

    --on remet le besoin sans les rebuts
    update gal_need_follow_up
       set nfu_net_quantity_need = nfu_inter_need_quantity;
  end main;

--**********************************************************************************************************--
--**********************************************************************************************************--
--***************SUIVI D'APPRO SUR TACHES *****************--
  procedure suivi_materiel(
    a_aff_id           gal_project.gal_project_id%type default 0
  , a_tac_id           gal_task.gal_task_id%type default 0
  , a_sessionid        number
  , a_trace            char default 'N'
  , a_reset_temp_table char default 'Y'
  )
  is
  begin
    v_flag_simulation  := 'O';
    v_flag_new_df      := 'N';
    v_calc_df          := 0;
    v_planif_df        := 0;
    v_is_read_from_df  := 'N';

    if a_reset_temp_table = 'Y' then
      delete from gal_project_need;

      delete from gal_project_resource;

      delete from gal_need_follow_up;

      delete from gal_resource_follow_up;
    end if;

    main(a_aff_id, a_tac_id, a_sessionid, a_trace);
    commit;
  end suivi_materiel;

--**********************************************************************************************************--
  procedure INIT_HEADER_RESULT
  is
  begin
    delete from gal_project_calc_result;

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_datecre
               , a_idcre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Besoins')
                    from dual)
               , '1'
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Approvisionnements')
                    from dual)
               , '3'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Surplus')
                    from dual)
               , '9'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Dossier de fabrication')
                    from dual)
               , '5'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Sous-traitance')
                    from dual)
               , '7'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Hors nomenclature')
                    from dual)
               , '11'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Hors mode d''appro')
                    from dual)
               , '13'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Anomalies Documents')
                    from dual)
               , '15'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    insert into gal_project_calc_result
                (gal_project_calc_result_id
               , gal_pcr_comment
               , gal_pcr_sort
               , a_idcre
               , a_datecre
                )
         values (gal_project_calc_result_id_seq.nextval
               , (select pcs.pc_functions.translateword('Anomalies Sous-traitance')
                    from dual)
               , '17'
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );
  end INIT_HEADER_RESULT;

--**********************************************************************************************************--
--**********************************************************************************************************--
--***************CALCUL D'APPRO SUR TACHES *****************************************************************--
  procedure full_launch_prj_manufacture(
    a_aff_id       gal_project.gal_project_id%type default 0
  , a_tac_id       gal_task.gal_task_id%type default 0
  , a_sessionid    number
  , a_trace        char default 'N'
  , is_Init_Header char
  )
  is
    v_gal_task_id   GAL_TASK.GAL_TASK_ID%type;
    v_doc_record_id GAL_TASK.DOC_RECORD_ID%type;
    v_tas_state     GAL_TASK.C_TAS_STATE%type;

    cursor C_PROJECT_MANUFACTURE
    is
      select   GAL_TASK_ID
             , DOC_RECORD_ID
             , C_TAS_STATE
          from GAL_TASK
         where GAL_FATHER_TASK_ID = a_tac_id
           and TAS_START_DATE is not null
           and TAS_END_DATE is not null
           and C_TAS_STATE < '40'
      order by TAS_CODE;
  begin
    open C_PROJECT_MANUFACTURE;

    loop
      fetch C_PROJECT_MANUFACTURE
       into v_gal_task_id
          , v_doc_record_id
          , v_tas_state;

      exit when C_PROJECT_MANUFACTURE%notfound;
      launch_project_manufacture(v_gal_task_id, v_doc_record_id, v_tas_state, a_sessionid, a_trace, is_Init_Header);
    end loop;

    close C_PROJECT_MANUFACTURE;
  end full_launch_prj_manufacture;

  --***************CALCUL D'APPRO SUR TACHES ******************************************************************--
  procedure calcul_affaire(
    a_aff_id    gal_project.gal_project_id%type default 0
  , a_tac_id    gal_task.gal_task_id%type default 0
  , a_tas_state gal_task.c_tas_state%type default '20'
  , a_planif_df integer default 1
  , a_calc_df   integer default 1
  , a_sessionid number
  , a_trace     char default 'N'
  )
  is
    lvCfg_GAL_PROC_BEFORE_CBA varchar2(255);
    lvCfg_GAL_PROC_AFTER_CBA  varchar2(255);
  begin
    if a_tas_state in('10', '20', '30') then
      --CHMI 17/06/2015 Ajout PROC BEFORE CBA
      lvCfg_GAL_PROC_BEFORE_CBA  := trim(PCS.PC_CONFIG.GetConfig('GAL_PROC_BEFORE_CBA') );

      if lvCfg_GAL_PROC_BEFORE_CBA is not null then
        sqlstatement  := 'BEGIN ' || lvCfg_GAL_PROC_BEFORE_CBA || '(:a_aff_id,:a_tac_id,:a_tas_state,:a_planif_df,:a_calc_df); END;';

        execute immediate sqlstatement
                    using in a_aff_id, in a_tac_id, in a_tas_state, in a_planif_df, in a_calc_df;
      end if;

      v_flag_simulation          := 'N';
      v_flag_new_df              := 'N';
      Init_Header_result;
      v_calc_df                  := a_calc_df;
      v_planif_df                := a_planif_df;

      /*
      SELECT COUNT(*) INTO v_df_to_date FROM GAL_TASK
      WHERE v_planif_df = 1 AND (TAS_START_DATE IS NULL OR TAS_END_DATE IS NULL) AND GAL_FATHER_TASK_ID = a_tac_id;
      */
      --si DF non datés, alors calcul de besoin global sur Nomenclature (pose date sur df) puis calcul des df, puis suivi mat pour display final
      --si tous DF sont datés, alors calcul de besoin sur DF puis calcul de besoin global sur nomenclature (+ si nouveau DF crée alors repasse sur calcul DF et suivi matériel pour affichage)

      --       IF v_calc_df = 1 AND v_df_to_date = 0 THEN full_launch_prj_manufacture (a_aff_id, a_tac_id, a_sessionid, a_trace,'Y'); END IF;
      delete from gal_project_need;

      delete from gal_project_resource;

      delete from gal_need_follow_up;

      delete from gal_resource_follow_up;

      v_is_read_from_df          := 'N';
      v_calc_df                  := a_calc_df;
      v_planif_df                := a_planif_df;
      main(a_aff_id, a_tac_id, a_sessionid, a_trace);

      if v_calc_df = 1   --AND (v_flag_new_df = 'O' OR v_df_to_date <> 0)
                      then
        full_launch_prj_manufacture(a_aff_id, a_tac_id, a_sessionid, a_trace, 'Y');
        v_flag_simulation  := 'O';   --refresh simple du suivi mat
        v_flag_new_df      := 'N';
        v_calc_df          := 0;
        v_planif_df        := 0;
        v_is_read_from_df  := 'N';

        delete from gal_project_need;

        delete from gal_project_resource;

        delete from gal_need_follow_up;

        delete from gal_resource_follow_up;

        main(a_aff_id, a_tac_id, a_sessionid, a_trace);
      end if;

      --UPDATE GAL_TASK SET tas_task_must_be_launch = 0, TAS_LAST_CALCULATION_DATE = SYSDATE WHERE GAL_TASK_ID = a_tac_id;

      --Suppression des lignes d'entete (surplus,besoins,appro,DF) qui n'ont pas de données liés dans la table
      delete from GAL_PROJECT_CALC_RESULT
            where GAL_PCR_SORT not in(select distinct (PCR.GAL_PCR_SORT - 1)
                                                 from GAL_PROJECT_CALC_RESULT PCR
                                                where PCR.GAL_GOOD_ID is not null)
              and GAL_GOOD_ID is null;

      --MLE 09/06/2015 Ajout PROC AFTER CBA
      lvCfg_GAL_PROC_AFTER_CBA   := trim(PCS.PC_CONFIG.GetConfig('GAL_PROC_AFTER_CBA') );

      if lvCfg_GAL_PROC_AFTER_CBA is not null then
        sqlstatement  := 'BEGIN ' || lvCfg_GAL_PROC_AFTER_CBA || '(:a_aff_id,:a_tac_id,:a_tas_state,:a_planif_df,:a_calc_df); END;';

        execute immediate sqlstatement
                    using in a_aff_id, in a_tac_id, in a_tas_state, in a_planif_df, in a_calc_df;
      end if;

      commit;
    end if;
  end calcul_affaire;

--**********************************************************************************************************--
--**********************************************************************************************************--
--***************SUIVI/CALCUL D'APPRO SUR COMPOSES SUR DOSSIER FABRICATION *****************--
  procedure create_doc_supply_manufacture(
    a_aff_id       gal_task.gal_project_id%type default 0
  , a_tac_id       gal_task.gal_task_id%type default 0
  , a_no_tache     gal_task.TAS_CODE%type
  , a_libel_tache  gal_task.TAS_WORDING%type
  , a_tac_date_fin gal_task.TAS_END_DATE%type
  )
  is
    V_GCO_GOOD_ID     GCO_GOOD.GCO_GOOD_ID%type;
    V_GTL_QUANTITY    GAL_TASK_LOT.GTL_QUANTITY%type;
    V_TAS_END_DATE    GAL_TASK.TAS_END_DATE%type;
    V_TAS_START_DATE  GAL_TASK.TAS_END_DATE%type;
    V_CPT             number;
    V_GTL_SEQUENCE    GAL_TASK_LOT.GTL_SEQUENCE%type;
    V_LIB_CSE         varchar2(200);
    V_ERR             number;
    v_gtl_description gal_task_lot.dtl_description%type;

    cursor C_TASK_LOT
    is
      select   GAL_TASK_LOT.GCO_GOOD_ID
             , sum(GTL_QUANTITY)
             , TAS_END_DATE
             , TAS_START_DATE
             , TAS_CODE
             , GAL_PROJECT.GAL_PROJECT_ID
             , GAL_TASK.DOC_RECORD_ID
             , GAL_PROJECT.PRJ_CODE
             , max(GAL_TASK_LOT.GTL_SEQUENCE)
             , dtl_description
          from GAL_PROJECT
             , GAL_TASK_LOT
             , GAL_TASK
         where GAL_TASK.GAL_PROJECT_ID = GAL_PROJECT.GAL_PROJECT_ID
           and GAL_TASK_LOT.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
           and GAL_TASK.GAL_TASK_ID = a_tac_id
      group by GAL_TASK_LOT.GCO_GOOD_ID
             , TAS_END_DATE
             , TAS_START_DATE
             , TAS_CODE
             , GAL_PROJECT.GAL_PROJECT_ID
             , GAL_TASK.DOC_RECORD_ID
             , GAL_PROJECT.PRJ_CODE
             , dtl_description
      order by max(GTL_SEQUENCE);
  begin
    v_cpt                   := 0;
    outdocumentid           := null;
    outpositionid           := null;
    --astockid               := NULL;
    --alocationid            := NULL;
    v_besoin_net            := 0;
    v_besoin_a_induire      := 0;
    v_besoin_a_induire_tot  := 0;
    v_besoin_brut           := 0;
    v_besoin_tot            := 0;
    v_date_besoin_net       := null;
    v_situ                  := ' ';
    v_from_cse_df           := 'O';
    v_err                   := 0;

    if v_flag_simulation = 'O' then
      select pcs.pc_functions.translateword('Composés')
        into v_lib_cse
        from dual;

      init_need_follow_up(y_aff_id             => a_aff_id
                        , y_tac_id             => a_tac_id
                        , y_level              => 0
                        , y_repere             => ' '
                        , y_art_id             => null
                        , y_codart             => v_lib_cse
                        , y_libart             => null   --a_no_tache,
                        , y_plan               => null   --a_libel_tache,
                        , y_type_gest          => null
                        , y_repart             => null
                        , y_qte_lien           => null
                        , y_besoin_net         => null
                        , y_besoin_brut        => null
                        , y_unite              => null
                        , y_date_besoin_net    => a_tac_date_fin
                        , y_com_seq            => null
                        , y_art_tete_id        => null
                        , y_com_seq_tete       => null
                        , y_besoin_stock_df    => 0
                        , iInterNeedQuantity   => 0
                         );
    end if;

    open C_TASK_LOT;

    loop
      fetch C_TASK_LOT
       into v_gco_good_id
          , v_gtl_quantity
          , v_tas_end_date
          , v_tas_start_date
          , v_task_no_tache
          , v_task_aff_id
          , v_task_doc_record_id
          , v_task_no_affaire
          , v_gtl_sequence
          , v_gtl_description;

      exit when C_TASK_LOT%notfound;
      v_besoin_net            := v_gtl_quantity;
      v_besoin_a_induire      := v_gtl_quantity;
      v_besoin_a_induire_tot  := v_gtl_quantity;
      v_besoin_brut           := v_gtl_quantity;
      v_besoin_tot            := v_gtl_quantity;
      v_date_besoin_net       := V_TAS_END_DATE;
      v_situ                  := ' ';
      ReadInfoGcoGood(v_gco_good_id, v_gco_good_id, 0);
      v_type_gestion          := 'A';
      v_repartition           := 'F';
      v_branche_df            := 'N';
      v_compose_df            := 'O';
      v_on_df                 := 'O';
      v_err                   := 0;

      select decode(trim(v_gtl_description), '', v_sui_long_descr, v_gtl_description)
        into v_sui_long_descr
        from dual;

      if v_flag_simulation = 'O' then
        init_need_follow_up(y_aff_id             => x_aff_id
                          , y_tac_id             => a_tac_id
                          , y_level              => 1
                          , y_repere             => v_sui_repere   --v_level,
                          , y_art_id             => v_gco_good_id
                          , y_codart             => v_sui_codart   --a_art_id,
                          , y_libart             => v_sui_long_descr
                          , y_plan               => v_sui_plan
                          , y_type_gest          => v_type_gestion
                          , y_repart             => v_repartition
                          , y_qte_lien           => v_besoin_net
                          , y_besoin_net         => v_besoin_net   --a_qte_besoin,
                          , y_besoin_brut        => v_besoin_net   --v_besoin_brut,
                          , y_unite              => v_sui_un_st   --v_besoin_tot,
                          , y_date_besoin_net    => v_tas_end_date
                          , y_com_seq            => v_gtl_sequence
                          , y_art_tete_id        => null
                          , y_com_seq_tete       => v_gtl_sequence
                          , y_besoin_stock_df    => 0
                          , iInterNeedQuantity   => 0
                           );
      end if;

      Use_resource(v_gco_good_id, a_tac_id, '0', null);

      if     v_flag_simulation = 'N'
         and v_tas_start_date is not null
         and v_tas_end_date is not null then
        v_upd_task_status  := 'Y';

        if v_besoin_net <> 0 then
          if v_cpt = 0 then
            if outdocumentid is null then
              gal_project_calculation.generatedocument(ataskid             => a_tac_id
                                                     , aprefixe            => 'DF - '
                                                     , outdocid            => outdocumentid
                                                     , v_pac_supplier_id   => null
                                                     , v_doc_mono_pos      => false
                                                     , is_ST               => false
                                                     , v_gauge_id          => v_GAL_GAUGE_SUPPLY_MANUFACTURE
                                                     , vgoodid             => V_GCO_GOOD_ID
                                                     , vbasisquantity      => v_besoin_net
                                                     , err                 => v_err
                                                     , iDmtNumber          => v_task_no_tache
                                                      );
            end if;
          end if;

          if outdocumentid is not null then
            gal_project_calculation.generateposdoc(vdocumentid      => outdocumentid
                                                 , vgoodid          => V_GCO_GOOD_ID
                                                 , vbasisquantity   => v_besoin_net
                                                 , vstockid         => v_stm_stock_id_project
                                                 , vlocationid      => v_stm_location_id_project
                                                 , vFinaldelay      => V_TAS_END_DATE
                                                 , ataskid          => a_tac_id
                                                 , outposid         => outpositionid
                                                 , err              => v_err
                                                  );
          end if;

          v_cpt  := v_cpt + 1;

          if     v_besoin_net > 0
             and v_err = 0 then
            insert into gal_project_calc_result
                        (gal_project_calc_result_id
                       , gal_task_id
                       , gal_good_id
                       , fal_supply_request_id
                       , doc_document_id
                       , doc_position_id
                       , doc_position_detail_id
                       , fal_doc_prop_id
                       , fal_lot_prop_id
                       , fal_lot_id
                       , gal_manufacture_task_id
                       , gal_pcr_qty
                       , gal_pcr_remaining_qty
                       , gal_pcr_comment
                       , gal_pcr_sort
                       , a_idcre
                       , a_datecre
                        )
                 values (gal_project_calc_result_id_seq.nextval
                       , a_tac_id
                       , v_gco_good_id
                       , null
                       , outdocumentid
                       , outpositionid
                       , outpositionid
                       , null
                       , null
                       , null
                       , a_tac_id
                       , v_besoin_net
                       , 0
                       ,   --remaining qty
                         (select pcs.pc_functions.translateword('Dossier de fabrication')
                            from dual)
                       , '6'
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                       , sysdate
                        );
          end if;
        end if;
      end if;   -- simulation = 'N'
    end loop;

    close C_TASK_LOT;
  end create_doc_supply_manufacture;

  --***************SUIVI/CALCUL D'APPRO SUR COMPOSANTS SUR DOSSIER FABRICATION *****************--
  procedure create_doc_componant(
    a_aff_id       gal_task.gal_project_id%type default 0
  , a_tac_id       gal_task.gal_task_id%type default 0
  , a_no_tache     gal_task.TAS_CODE%type
  , a_libel_tache  gal_task.TAS_WORDING%type
  , a_tac_date_fin gal_task.TAS_END_DATE%type
  )
  is
    V_GCO_GOOD_ID           GCO_GOOD.GCO_GOOD_ID%type;
    V_GTL_QUANTITY          GAL_TASK_LOT.GTL_QUANTITY%type;
    V_TAS_END_DATE          GAL_TASK.TAS_END_DATE%type;
    V_TAS_START_DATE        GAL_TASK.TAS_START_DATE%type;
    V_CPT                   number;
    V_GML_SEQUENCE          GAL_TASK_GOOD.GML_SEQUENCE%type;
    V_LIB_CSANT             varchar2(200);
    V_SUPPLY_MODE           GAL_TASK_GOOD.C_PROJECT_SUPPLY_MODE%type;
    V_FATHER_TASK_ID        GAL_TASK.GAL_TASK_ID%type;
    v_long_descr            GAL_TASK_GOOD.GML_DESCRIPTION%type;
    v_pac_supplier_id       PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    ResPropDocId            FAL_DOC_PROP.FAL_DOC_PROP_ID%type;
    v_err                   number;
    v_N                     number;
    v_C                     varchar2(4000);
    aConvertFactor          number;
    aNumberOfDecimal        number;
    v_Def_BasisQuantity     number;
    v_compteur              fal_supply_request.fsr_number%type;
    outreqid                fal_supply_request.fal_supply_request_id%type;
    v_fal_supply_request_id fal_supply_request.fal_supply_request_id%type;

    cursor C_TASK_GOOD
    is
      select   GAL_TASK_GOOD.GCO_GOOD_ID
             , sum(GML_QUANTITY)
             , TAS_END_DATE
             , TAS_START_DATE
             , TAS_CODE
             , GAL_PROJECT.GAL_PROJECT_ID
             , GAL_TASK.DOC_RECORD_ID
             , GAL_PROJECT.PRJ_CODE
             , max(GAL_TASK_GOOD.GML_SEQUENCE)
             , C_PROJECT_SUPPLY_MODE
             , GAL_TASK.GAL_FATHER_TASK_ID
             , GML_DESCRIPTION
          from GAL_PROJECT
             , GAL_TASK_GOOD
             , GAL_TASK
         where GAL_TASK.GAL_PROJECT_ID = GAL_PROJECT.GAL_PROJECT_ID
           and GAL_TASK_GOOD.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
           and GAL_TASK.GAL_TASK_ID = a_tac_id
      --AND GAL_TASK.C_TAS_STATE < '20'
      group by GAL_TASK_GOOD.GCO_GOOD_ID
             , TAS_END_DATE
             , TAS_START_DATE
             , TAS_CODE
             , GAL_PROJECT.GAL_PROJECT_ID
             , GAL_TASK.DOC_RECORD_ID
             , GAL_PROJECT.PRJ_CODE
             , C_PROJECT_SUPPLY_MODE
             , GAL_TASK.GAL_FATHER_TASK_ID
             , GML_DESCRIPTION
      order by max(GML_SEQUENCE);

    procedure create_doc_componant_pos(aNeedOrSupply char, aQte number)
    is
      aTypeAppro   varchar2(60);
      aSortResult1 number;
      aSortResult2 number;
    begin
      if outdocumentid is not null then
        aTypeAppro    := 'Besoins';
        aSortResult1  := 1;
        aSortResult2  := 2;

        if v_supply_mode = '1' then
          Init_location_stk_product_stoc(V_GCO_GOOD_ID, A_TAC_ID);
        elsif v_supply_mode = '2' then
          astockid     := v_stm_stock_id_project;
          alocationid  := v_stm_location_id_project;

          if aNeedOrSupply = 'S' then
            aTypeAppro    := 'Approvisionnements';
            aSortResult1  := 3;
            aSortResult2  := 4;
          end if;
        elsif v_supply_mode = '3' then
          astockid     := v_stm_stock_id_project;
          alocationid  := v_stm_location_id_project;
        end if;

        gal_project_calculation.generateposdoc(vdocumentid      => outdocumentid
                                             , vgoodid          => V_GCO_GOOD_ID
                                             , vbasisquantity   => aQte
                                             , vstockid         => astockid
                                             , vlocationid      => alocationid
                                             , vFinaldelay      => V_TAS_START_DATE
                                             , ataskid          => a_tac_id
                                             , outposid         => outpositionid
                                             , err              => v_err
                                              );

        update DOC_POSITION
           set POS_LONG_DESCRIPTION = v_long_descr
         where DOC_POSITION_ID = outpositionid;
      end if;

      if     aQte > 0
         and v_err = 0 then
        insert into gal_project_calc_result
                    (gal_project_calc_result_id
                   , gal_task_id
                   , gal_good_id
                   , fal_supply_request_id
                   , doc_document_id
                   , doc_position_id
                   , doc_position_detail_id
                   , fal_doc_prop_id
                   , fal_lot_prop_id
                   , fal_lot_id
                   , gal_manufacture_task_id
                   , gal_pcr_qty
                   , gal_pcr_remaining_qty
                   , gal_pcr_comment
                   , gal_pcr_sort
                   , a_idcre
                   , a_datecre
                    )
             values (gal_project_calc_result_id_seq.nextval
                   , a_tac_id
                   , v_gco_good_id
                   , null
                   , outdocumentid
                   , outpositionid
                   , outpositionid
                   , null
                   , null
                   , null
                   , a_tac_id
                   , aQte
                   , 0
                   ,   --remaining qty
                     (select pcs.pc_functions.translateword(aTypeAppro)
                        from dual)
                   , aSortResult2
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                   , sysdate
                    );
      end if;
    end create_doc_componant_pos;
  begin
    v_besoin_net             := 0;
    v_besoin_a_induire       := 0;
    v_besoin_a_induire_tot   := 0;
    v_besoin_brut            := 0;
    v_besoin_tot             := 0;
    v_qte_besoin_net_need    := 0;
    v_date_besoin_net        := null;
    v_situ                   := ' ';
    v_from_cse_df            := 'N';
    v_lien_pseudo            := 'N';
    ResPropDocId             := null;
    v_err                    := 0;
    outreqid                 := null;
    v_fal_supply_request_id  := null;

    if v_flag_simulation = 'O' then
      select pcs.pc_functions.translateword('Composants')
        into v_lib_csant
        from dual;

      init_need_follow_up(y_aff_id             => a_aff_id
                        , y_tac_id             => a_tac_id
                        , y_level              => 0
                        , y_repere             => ' '
                        , y_art_id             => null
                        , y_codart             => v_lib_csant
                        , y_libart             => null   --a_no_tache,
                        , y_plan               => null   --a_libel_tache,
                        , y_type_gest          => null
                        , y_repart             => null
                        , y_qte_lien           => null
                        , y_besoin_net         => null
                        , y_besoin_brut        => null
                        , y_unite              => null
                        , y_date_besoin_net    => a_tac_date_fin
                        , y_com_seq            => null
                        , y_art_tete_id        => null
                        , y_com_seq_tete       => null
                        , y_besoin_stock_df    => 0
                        , iInterNeedQuantity   => 0
                         );
    end if;

    open C_TASK_GOOD;

    loop
      fetch C_TASK_GOOD
       into v_gco_good_id
          , v_gtl_quantity
          , v_tas_end_date
          , v_tas_start_date
          , v_task_no_tache
          , v_task_aff_id
          , v_task_doc_record_id
          , v_task_no_affaire
          , v_gml_sequence
          , v_supply_mode
          , v_father_task_id
          , v_long_descr;

      exit when C_TASK_GOOD%notfound;
      /*dans tous les cas*/
      outdocumentid      := null;
      outpositionid      := null;
      v_err              := 0;

      --astockid := NULL;
      --alocationid := NULL;
      if    v_supply_mode = '4'
         or v_supply_mode = '5' then
        v_besoin_net            := 0;
        v_besoin_a_induire      := 0;
        v_besoin_a_induire_tot  := 0;
        v_besoin_brut           := 0;
        v_besoin_tot            := 0;
      else
        v_besoin_net            := v_gtl_quantity;
        v_besoin_a_induire      := v_gtl_quantity;
        v_besoin_a_induire_tot  := v_gtl_quantity;
        v_besoin_brut           := v_gtl_quantity;
        v_besoin_tot            := v_gtl_quantity;
      end if;

      v_date_besoin_net  := v_tas_end_date;
      v_situ             := ' ';
      ReadInfoGcoGood(v_gco_good_id, v_gco_good_id, 0);
      --Si modif manuelle du mode d'appro
      SetSupplyModeDF(v_supply_mode, v_repartition);
      v_branche_df       := 'O';
      v_compose_df       := 'N';
      v_on_df            := 'N';

      select decode(trim(v_long_descr), '', v_sui_long_descr, v_long_descr)
        into v_sui_long_descr
        from dual;

      if v_flag_simulation = 'O' then
        init_need_follow_up(y_aff_id             => x_aff_id
                          , y_tac_id             => a_tac_id
                          , y_level              => 1
                          , y_repere             => v_sui_repere   --v_level,
                          , y_art_id             => v_gco_good_id
                          , y_codart             => v_sui_codart   --a_art_id,
                          , y_libart             => v_sui_long_descr
                          , y_plan               => v_sui_plan
                          , y_type_gest          => v_type_gestion
                          , y_repart             => v_repartition
                          , y_qte_lien           => v_besoin_net
                          , y_besoin_net         => v_besoin_net   --a_qte_besoin,
                          , y_besoin_brut        => v_besoin_net   --v_besoin_brut,
                          , y_unite              => v_sui_un_st   --v_besoin_tot,
                          , y_date_besoin_net    => v_tas_end_date
                          , y_com_seq            => v_gml_sequence
                          , y_art_tete_id        => null
                          , y_com_seq_tete       => v_gml_sequence
                          , y_besoin_stock_df    => 0
                          , iInterNeedQuantity   => 0
                           );
      end if;

      if v_supply_mode <>('5') then
        Use_resource(v_gco_good_id, a_tac_id, '1', null);
      /*dans tous les cas*/
      end if;

      if     v_flag_simulation = 'N'
         and v_tas_start_date is not null
         and v_tas_end_date is not null then
        v_upd_task_status  := 'Y';
      end if;

      if     v_flag_simulation = 'N'
         and v_supply_mode in('1', '2', '3')   ---,'4') --Stock/acheté/fabriqué
         and v_tas_start_date is not null
         and v_tas_end_date is not null then
        if v_besoin_net <> 0 then
          if outdocumentid is null then
            if v_supply_mode = '2' then
              if v_Type_Supply_To_Generate_DF = 0 then   -- multi poitio
                gal_project_calculation.generatedocument(ataskid             => a_tac_id
                                                       , aprefixe            => 'DA - '
                                                       , outdocid            => outdocumentid
                                                       , v_pac_supplier_id   => null
                                                       , v_doc_mono_pos      => false
                                                       , is_ST               => false
                                                       , v_gauge_id          => V_GAL_GAUGE_SUPPLY_REQUEST
                                                       , vgoodid             => v_gco_good_id
                                                       , vbasisquantity      => v_besoin_net
                                                       , err                 => v_err
                                                        );
              elsif v_Type_Supply_To_Generate_DF = 1 then   -- mono positioin
                begin
                  select GCO_COMPL_DATA_PURCHASE.PAC_SUPPLIER_PARTNER_ID
                    into v_pac_supplier_id
                    from GCO_COMPL_DATA_PURCHASE
                   where GCO_COMPL_DATA_PURCHASE.GCO_GOOD_ID = V_GCO_GOOD_ID
                     and GCO_COMPL_DATA_PURCHASE.CPU_DEFAULT_SUPPLIER = 1;
                exception
                  when no_data_found then
                    v_pac_supplier_id  := null;
                end;

                gal_project_calculation.generatedocument(ataskid             => a_tac_id
                                                       , aprefixe            => 'DA - '
                                                       , outdocid            => outdocumentid
                                                       , v_pac_supplier_id   => v_pac_supplier_id
                                                       , v_doc_mono_pos      => true
                                                       , is_ST               => false
                                                       , v_gauge_id          => V_GAL_GAUGE_SUPPLY_REQUEST
                                                       , vgoodid             => v_gco_good_id
                                                       , vbasisquantity      => v_besoin_net
                                                       , err                 => v_err
                                                        );
              elsif v_Type_Supply_To_Generate_DF = 2 then
                /*Anciennement Methode Generation DA...*/
                --On garde temporairement une DA pour que le calcaul de besoin régénératif ne supprime pas les POx
                /*
                BEGIN
                  SELECT fal_supply_request_id INTO v_fal_supply_request_id
                  FROM fal_supply_request WHERE doc_record_id = v_task_doc_record_id
                  AND ROWNUM = 1;
                EXCEPTION WHEN NO_DATA_FOUND THEN
                */
                select lpad(nvl(max(to_number(fsr.fsr_number) ), 0) + 1, 6, '0')
                  into v_compteur
                  from fal_supply_request fsr;

                fal_supply_request_functions.updatesupplyrequestproject(v_gco_good_id
                                                                      , v_task_doc_record_id
                                                                      , v_compteur
                                                                      ,   --ex numero d'OA
                                                                        nvl(trim(v_sui_codart), 'CBA')
                                                                      , v_besoin_net
                                                                      , v_tas_end_date
                                                                      , nvl(trim(v_sui_codart), 'CBA')
                                                                      , null
                                                                      ,   --ex commentaire
                                                                        outreqid
                                                                       );

                --Mise au statut refusée...
                update fal_supply_request
                   set c_request_status = '2'
                     , fsr_validate_date = sysdate
                 where fal_supply_request_id = outreqid;

                v_fal_supply_request_id  := outreqid;
                outreqid                 := null;

                --END; /*Anciennement Methode Generation DA...*/
                begin
                  select GCO_COMPL_DATA_PURCHASE.PAC_SUPPLIER_PARTNER_ID
                    into v_pac_supplier_id
                    from GCO_COMPL_DATA_PURCHASE
                   where GCO_COMPL_DATA_PURCHASE.GCO_GOOD_ID = v_gco_good_id
                     and GCO_COMPL_DATA_PURCHASE.CPU_DEFAULT_SUPPLIER = 1;
                exception
                  when no_data_found then
                    v_pac_supplier_id  := null;
                end;

                GCO_I_LIB_COMPL_DATA.GetComplementarydata(v_gco_good_id
                                                        , '1'
                                                        , v_pac_supplier_id
                                                        , pcs.PC_I_LIB_SESSION.getuserlangid
                                                        , null
                                                        , null
                                                        , null
                                                        , v_N
                                                        , v_N
                                                        , v_C
                                                        , v_C
                                                        , v_C
                                                        , v_C
                                                        , v_C
                                                        , v_C
                                                        , v_C
                                                        , v_C
                                                        , v_C
                                                        , aConvertFactor
                                                        , aNumberOfDecimal
                                                        , v_N
                                                         );
                v_Def_BasisQuantity      := ACS_FUNCTION.RoundNear(v_besoin_net / aConvertFactor, 1 / power(10, aNumberOfDecimal), 0);
                -- POA
                gal_pox_generate.CreatePropApproLog(v_gco_good_id
                                                  , v_tas_end_date
                                                  , v_Def_BasisQuantity
                                                  , v_task_doc_record_id
                                                  , '1'
                                                  ,   --HA
                                                    v_stm_stock_id_project
                                                  , v_stm_location_id_project
                                                  , 0
                                                  ,   --SupplierId
                                                    v_fal_supply_request_id
                                                  , ResPropDocId
                                                   );

                if     v_besoin_net > 0
                   and v_err = 0 then
                  insert into gal_project_calc_result
                              (gal_project_calc_result_id
                             , gal_task_id
                             , gal_good_id
                             , fal_supply_request_id
                             , doc_document_id
                             , doc_position_id
                             , doc_position_detail_id
                             , fal_doc_prop_id
                             , fal_lot_prop_id
                             , fal_lot_id
                             , gal_manufacture_task_id
                             , gal_pcr_qty
                             , gal_pcr_remaining_qty
                             , gal_pcr_comment
                             , gal_pcr_sort
                             , a_idcre
                             , a_datecre
                              )
                       values (gal_project_calc_result_id_seq.nextval
                             , a_tac_id
                             , v_gco_good_id
                             , null
                             , outdocumentid
                             , outpositionid
                             , outpositionid
                             , ResPropDocId
                             , null
                             , null
                             , a_tac_id
                             , v_besoin_net
                             , 0
                             ,   --remaining qty
                               (select pcs.pc_functions.translateword('Approvisionnements')
                                  from dual)
                             , '4'
                             , PCS.PC_I_LIB_SESSION.GetUserIni
                             , sysdate
                              );
                end if;
              elsif v_Type_Supply_To_Generate_DF = 3 then   --> Methode Generation DA (FAL_SUPPLY_REQUEST)
                select lpad(nvl(max(to_number(fsr.fsr_number) ), 0) + 1, 6, '0')
                  into v_compteur
                  from fal_supply_request fsr;

                fal_supply_request_functions.updatesupplyrequestproject(v_gco_good_id
                                                                      , v_task_doc_record_id
                                                                      , v_compteur
                                                                      ,   --ex numero d'OA
                                                                        nvl(trim(v_sui_codart), 'CBA')
                                                                      , v_besoin_net
                                                                      , v_tas_end_date
                                                                      , nvl(trim(v_sui_codart), 'CBA')
                                                                      , null
                                                                      ,   --ex commentaire
                                                                        outreqid
                                                                       );

                if v_besoin_net > 0 then
                  insert into gal_project_calc_result
                              (gal_project_calc_result_id
                             , gal_task_id
                             , gal_good_id
                             , fal_supply_request_id
                             , doc_document_id
                             , doc_position_id
                             , doc_position_detail_id
                             , fal_doc_prop_id
                             , fal_lot_prop_id
                             , fal_lot_id
                             , gal_manufacture_task_id
                             , gal_pcr_qty
                             , gal_pcr_remaining_qty
                             , gal_pcr_comment
                             , gal_pcr_sort
                             , a_idcre
                             , a_datecre
                              )
                       values (gal_project_calc_result_id_seq.nextval
                             , a_tac_id
                             , v_gco_good_id
                             , outreqid
                             , null
                             , null
                             , null
                             , null
                             , null
                             , null
                             , a_tac_id
                             , v_besoin_net
                             , 0
                             ,   --remaining qty
                               (select pcs.pc_functions.translateword('Approvisionnements')
                                  from dual)
                             , '4'
                             , PCS.PC_I_LIB_SESSION.GetUserIni
                             , sysdate
                              );
                end if;
              end if;   -- type_supply_togenerate : HA selon config GAL_CALCUL_MANUF_SPC_SUPPLY (0/1/2/3)

              if v_Type_Supply_To_Generate_DF in(0, 1)   --DA mono/multi position
                                                      then
                create_doc_componant_pos('S', v_besoin_net);
              end if;
            end if;   --> v_supply mode 2 (HA --> Appro HA selon config GAL_CALCUL_MANUF_SPC_SUPPLY

            if v_supply_mode in('1', '3')   --> Stock ou fabriqué : Document Besoin Dossier Fab
                                         then
              gal_project_calculation.generatedocument(ataskid             => a_tac_id
                                                     , aprefixe            => 'BF - '
                                                     , outdocid            => outdocumentid
                                                     , v_pac_supplier_id   => null
                                                     , v_doc_mono_pos      => false
                                                     , is_ST               => false
                                                     , v_gauge_id          => V_GAL_GAUGE_NEED_MANUFACTURE
                                                     , vgoodid             => v_gco_good_id
                                                     , vbasisquantity      => v_besoin_net
                                                     , err                 => v_err
                                                      );
              create_doc_componant_pos('N', v_besoin_net);   --Type Need
            end if;
          end if;
        end if;   -- v_besoin_net <> 0

        outdocumentid  := null;
        outpositionid  := null;

        if v_qte_besoin_net_need > 0 then
          if outdocumentid is null then
            if v_supply_mode in('2') then
              gal_project_calculation.generatedocument(ataskid             => a_tac_id
                                                     , aprefixe            => 'BF - '
                                                     , outdocid            => outdocumentid
                                                     , v_pac_supplier_id   => null
                                                     , v_doc_mono_pos      => false
                                                     , is_ST               => false
                                                     , v_gauge_id          => V_GAL_GAUGE_NEED_MANUFACTURE
                                                     , vgoodid             => v_gco_good_id
                                                     , vbasisquantity      => v_qte_besoin_net_need
                                                     , err                 => v_err
                                                      );
              create_doc_componant_pos('N', v_qte_besoin_net_need);   --Type Need
            end if;   --> HA : Document Besoin Dossier Fab
          end if;
        end if;   -- v_besoin_net <> 0
      end if;   --simulation = 'N' et supply = stock ou acheté
    end loop;

    close c_task_good;
  end create_doc_componant;

--************************************************************************************************************************--
  procedure create_doc_ST(v_tsk_id gal_task.gal_task_id%type default 0)
  is
    v_c_task_type       GAL_TASK_LINK.C_TASK_TYPE%type;
    v_gco_gco_good_id   GCO_GOOD.GCO_GOOD_ID%type;
    v_pac_supplier_id   PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    v_doc_record_id     DOC_RECORD.DOC_RECORD_ID%type;
    v_tal_end_plan_date GAL_TASK_LINK.TAL_END_PLAN_DATE%type;
    v_cnt               number;
    v_scs_step_number   FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    v_ope_long_descr    GAL_TASK_LINK.SCS_LONG_DESCR%type;
    v_descr_art         varchar2(4000);
    v_descr_art2        varchar2(4000);
    v_gal_task_link_id  GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
    v_proj              GAL_PROJECT.PRJ_CODE%type;
    v_gal_father_id     GAL_TASK.GAL_FATHER_TASK_ID%type;
    v_cpt_art           number;
    v_err               number;
    v_exit_lot_link     char(1);

    cursor C_OPER
    is
      select   LNK.C_TASK_TYPE
             , LNK.GCO_GCO_GOOD_ID
             , LNK.PAC_SUPPLIER_PARTNER_ID
             , LNK.DOC_RECORD_ID
             , LNK.TAL_END_PLAN_DATE
             , LNK.scs_step_number
             , LNK.scs_long_descr
             , LNK.gal_task_link_id
          from GAL_TASK_LINK LNK
         where LNK.GAL_TASK_ID = v_tsk_id
           and LNK.C_TAL_STATE < '40'
      --AND EXISTS (SELECT '*' FROM GAL_TASK_LOT_LINK LLNK WHERE LLNK.GAL_TASK_ID = v_tsk_id AND LLNK.GAL_TASK_LINK_ID = LNK.gal_task_link_id AND ROWNUM = 1);
      --AND LNK.TAL_END_PLAN_DATE IS NOT NULL;
      order by LNK.SCS_STEP_NUMBER;

    --Description libre du document => qté Unité de gestion x major reference  description courte Plan: Plan Version: Version
    cursor C_ART
    is
      select   --TO_CHAR(GAL_TASK_LOT.GTL_SEQUENCE)
             to_char(GAL_TASK_LOT.GTL_QUANTITY) ||
             ' x ' ||
             GCO_GOOD.GOO_MAJOR_REFERENCE ||
             '  ' ||
             GCO_GOOD.GOO_SECONDARY_REFERENCE
                                             --|| ' ' || (SELECT pcs.pc_functions.translateword ('Quantité:') FROM DUAL) || ' ' || TO_CHAR(GAL_TASK_LOT.GTL_QUANTITY)
             ||
             ' ' ||
             (select pcs.pc_functions.translateword('Plan:')
                from dual) ||
             ' ' ||
             GAL_TASK_LOT.GTL_PLAN_NUMBER ||
             ' ' ||
             (select pcs.pc_functions.translateword('Version:')
                from dual) ||
             ' ' ||
             GAL_TASK_LOT.GTL_PLAN_VERSION
        from GAL_TASK_LOT_LINK
           , GAL_TASK_LOT
           , GCO_GOOD
       where GAL_TASK_LOT.GAL_TASK_LOT_ID = GAL_TASK_LOT_LINK.GAL_TASK_LOT_ID
         and GCO_GOOD.GCO_GOOD_ID = GAL_TASK_LOT.GCO_GOOD_ID
         and GAL_TASK_LOT_LINK.GAL_TASK_LINK_ID = v_gal_task_link_id;
  begin
    select tas_code
         , gal_task.gal_project_id
         , prj_code
         , gal_father_task_id
      into v_task_no_affaire
         , v_task_aff_id
         , v_proj
         , v_gal_father_id
      from gal_project
         , gal_task
     where gal_project.gal_project_id = gal_task.gal_project_id
       and gal_task_id = v_tsk_id;

    open C_OPER;

    loop
      fetch C_OPER
       into v_c_task_type
          , v_gco_gco_good_id
          , v_pac_supplier_id
          , v_doc_record_id
          , v_tal_end_plan_date
          , v_scs_step_number
          , v_ope_long_descr
          , v_gal_task_link_id;

      exit when C_OPER%notfound;
      v_err  := 0;

      if v_c_task_type <> 1 then
        if v_flag_simulation = 'N' then
          v_upd_task_status  := 'Y';
        end if;

        --IF v_tal_end_plan_date IS NOT NULL
        --THEN
        select count(*)
          into v_cnt
          from DOC_POSITION
         where DOC_RECORD_ID = v_doc_record_id;

        select trim(to_char(v_scs_step_number) )
          into v_task_no_tache
          from dual;

        outdocumentid  := null;
        outpositionid  := null;

        --astockid               := NULL;
        --alocationid            := NULL;

        --IF v_cnt = 0 THEN
        begin
          select '*'
            into v_exit_lot_link
            from GAL_TASK_LOT_LINK LNK
           where LNK.GAL_TASK_ID = v_tsk_id
             and LNK.GAL_TASK_LINK_ID = v_gal_task_link_id
             and rownum = 1;

          --Test si le compose est coché dans la définition de la gamme de l'opé externe en cours
          if     v_cnt = 0
             and v_tal_end_plan_date is not null then
            gal_project_calculation.generatedocument(ataskid             => v_doc_record_id
                                                   ,   --Checker la remonter de planté plsql dans delphi sur ce cas !!!
                                                     aprefixe            => 'DA - '
                                                   , outdocid            => outdocumentid
                                                   , v_pac_supplier_id   => v_pac_supplier_id
                                                   , v_doc_mono_pos      => false
                                                   , is_ST               => true
                                                   , v_gauge_id          => V_GAL_GAUGE_SUPPLY_REQUEST
                                                   , vgoodid             => v_gco_gco_good_id
                                                   , vbasisquantity      => 1
                                                   , err                 => v_err
                                                    );

            if outdocumentid is not null then
              gal_project_calculation.generateposdoc(vdocumentid      => outdocumentid
                                                   , vgoodid          => v_gco_gco_good_id
                                                   , vbasisquantity   => 1
                                                   , vstockid         => null
                                                   , vlocationid      => null
                                                   , vFinaldelay      => v_tal_end_plan_date
                                                   , ataskid          => v_tsk_id
                                                   , outposid         => outpositionid
                                                   , err              => v_err
                                                    );
              v_descr_art2  := '';
              v_cpt_art     := 0;

              open C_ART;

              loop
                fetch C_ART
                 into v_descr_art;

                exit when C_ART%notfound;

                if length(trim(v_descr_art2) || chr(13) || trim(v_descr_art) ) <= 4000 then
                  if v_cpt_art = 0 then
                    v_descr_art2  := trim(v_descr_art);
                  else
                    v_descr_art2  := trim(v_descr_art2) || chr(13) || trim(v_descr_art);
                  end if;
                end if;

                v_cpt_art  := v_cpt_art + 1;
              end loop;

              close C_ART;

              update DOC_POSITION
                 set POS_LONG_DESCRIPTION = v_ope_long_descr
                   , POS_FREE_DESCRIPTION = substr(v_descr_art2, 1, 4000)
               where DOC_POSITION_ID = outpositionid;

              /*UPDATE DOC_FREE_DATA SET FRD_ALPHA_SHORT_1 = dest , FRD_ALPHA_SHORT_2 = destid, A_DATEMOD = SYSDATE, A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni WHERE DOC_DOCUMENT_ID = outdocumentid;
              IF SQL%NOTFOUND THEN
                INSERT INTO DOC_FREE_DATA (DOC_FREE_DATA_ID,DOC_DOCUMENT_ID,FRD_ALPHA_SHORT_1,FRD_ALPHA_SHORT_2,A_DATECRE,A_IDCRE)
                VALUES (INIT_ID_SEQ.NEXTVAL,outdocumentid,dest,destid,sysdate,PCS.PC_I_LIB_SESSION.GetUserIni);
              END IF;
              */
              if v_err = 0 then
                insert into gal_project_calc_result
                            (gal_project_calc_result_id
                           , gal_task_id
                           , gal_good_id
                           , fal_supply_request_id
                           , doc_document_id
                           , doc_position_id
                           , doc_position_detail_id
                           , fal_doc_prop_id
                           , fal_lot_prop_id
                           , fal_lot_id
                           , gal_manufacture_task_id
                           , gal_pcr_qty
                           , gal_pcr_remaining_qty
                           , gal_pcr_comment
                           , gal_pcr_sort
                           , a_idcre
                           , a_datecre
                            )
                     values (gal_project_calc_result_id_seq.nextval
                           , v_tsk_id
                           , v_gco_gco_good_id
                           , null
                           , outdocumentid
                           , outpositionid
                           ,   --v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                             v_gal_task_link_id
                           , null
                           , null
                           , null
                           , v_tsk_id
                           , 1
                           , 0
                           , ' (' || v_scs_step_number || ') '   /*(SELECT pcs.pc_functions.translateword ('Sous-traitance') FROM DUAL)*/
                           , '8'
                           , PCS.PC_I_LIB_SESSION.GetUserIni
                           , sysdate
                            );
              end if;
            end if;   --> outdocumentid IS NOT NULL
          end if;   -->v_cnt=0
        exception
          when no_data_found then
            insert into gal_project_calc_result
                        (gal_project_calc_result_id
                       , gal_task_id
                       , gal_good_id
                       , fal_supply_request_id
                       , doc_document_id
                       , doc_position_id
                       , doc_position_detail_id
                       , fal_doc_prop_id
                       , fal_lot_prop_id
                       , fal_lot_id
                       , gal_manufacture_task_id
                       , gal_pcr_qty
                       , gal_pcr_remaining_qty
                       , gal_pcr_comment
                       , gal_pcr_sort
                       , a_idcre
                       , a_datecre
                        )
                 values (gal_project_calc_result_id_seq.nextval
                       , v_tsk_id
                       , v_gco_gco_good_id
                       , null
                       , null
                       , null
                       ,   --v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                         v_gal_task_link_id
                       , null
                       , null
                       , null
                       , v_tsk_id
                       , 1
                       , 0
                       , ' (' ||
                         v_scs_step_number ||
                         ') : ' ||
                         (select pcs.pc_functions.translateword('Opération externe')
                            from dual) ||
                         ' ' ||
                         trim(v_scs_step_number)   --no_ope
                                                ||
                         ' (' ||
                         trim(v_proj) ||
                         ' - ' ||
                         (select nvl(min(TAS_CODE), ' ')
                            from GAL_TASK
                           where GAL_TASK_ID = v_gal_father_id) ||
                         ' - ' ||
                         trim(v_task_no_affaire) ||
                         ') : '   --no_affaire + no_tache
                               ||
                         (select pcs.pc_functions.translateword('Aucun composé n''est lié à cette opération (cf.Gamme)')
                            from dual)
                       , '18'
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                       , sysdate
                        );
        end;

        --END IF;--v_cnt=0

        --ELSE--v_tal_end_plan_date NULL
        if v_tal_end_plan_date is null then
          insert into gal_project_calc_result
                      (gal_project_calc_result_id
                     , gal_task_id
                     , gal_good_id
                     , fal_supply_request_id
                     , doc_document_id
                     , doc_position_id
                     , doc_position_detail_id
                     , fal_doc_prop_id
                     , fal_lot_prop_id
                     , fal_lot_id
                     , gal_manufacture_task_id
                     , gal_pcr_qty
                     , gal_pcr_remaining_qty
                     , gal_pcr_comment
                     , gal_pcr_sort
                     , a_idcre
                     , a_datecre
                      )
               values (gal_project_calc_result_id_seq.nextval
                     , v_tsk_id
                     , v_gco_gco_good_id
                     , null
                     , null
                     , null
                     ,   --v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                       v_gal_task_link_id
                     , null
                     , null
                     , null
                     , v_tsk_id
                     , 1
                     , 0
                     , ' (' ||
                       v_scs_step_number ||
                       ') : ' ||
                       (select pcs.pc_functions.translateword('Opération externe')
                          from dual) ||
                       ' ' ||
                       trim(v_scs_step_number)   --no_ope
                                              ||
                       ' (' ||
                       trim(v_proj) ||
                       ' - ' ||
                       (select nvl(min(TAS_CODE), ' ')
                          from GAL_TASK
                         where GAL_TASK_ID = v_gal_father_id) ||
                       ' - ' ||
                       trim(v_task_no_affaire) ||
                       ') : '   --no_affaire + no_tache
                             ||
                       (select pcs.pc_functions.translateword('manque dates opérations')
                          from dual)
                     , '18'
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                      );
        end if;   --> v_tal_end_plan_date NULL
      end if;   --> v_c_task_type <> 1
    end loop;

    close C_OPER;
  end create_doc_ST;

--************************************************************************************************************************--
  procedure check_doc_ST(aTskId gal_task.gal_task_id%type, aResetResultTable number default 1)
  is
    v_c_task_type         GAL_TASK_LINK.C_TASK_TYPE%type;
    v_gco_gco_good_id     GCO_GOOD.GCO_GOOD_ID%type;
    v_pac_supplier_id     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    v_doc_record_id       DOC_RECORD.DOC_RECORD_ID%type;
    v_tal_end_plan_date   GAL_TASK_LINK.TAL_END_PLAN_DATE%type;
    v_cnt                 number;
    v_scs_step_number     FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    v_ope_long_descr      GAL_TASK_LINK.SCS_LONG_DESCR%type;
    v_gal_task_link_id    GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
    v_proj                GAL_PROJECT.PRJ_CODE%type;
    v_gal_father_task_id  GAL_TASK.GAL_FATHER_TASK_ID%type;
    v_tsk_id              GAL_TASK.GAL_TASK_ID%type;
    v_tsk_code            GAL_TASK.TAS_CODE%type;
    v_dc_id               DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    v_dc_pos_id           DOC_POSITION.DOC_POSITION_ID%type;
    v_dc_pos_dt_id        DOC_POSITION.DOC_POSITION_ID%type;
    v_pos_free_descr      DOC_POSITION.POS_FREE_DESCRIPTION%type;
    v_pos_free_descr_conc varchar2(32000);
    v_exit_lot_link       char(1);

    cursor C_OPER
    is
      select   PRJ.PRJ_CODE
             , TSK.TAS_CODE
             , LNK.GAL_TASK_ID
             , TSK.GAL_FATHER_TASK_ID
             , LNK.C_TASK_TYPE
             , LNK.GCO_GCO_GOOD_ID
             , LNK.PAC_SUPPLIER_PARTNER_ID
             , LNK.DOC_RECORD_ID
             , LNK.TAL_END_PLAN_DATE
             , LNK.scs_step_number
             , LNK.scs_long_descr
             , LNK.gal_task_link_id
          from GAL_PROJECT PRJ
             , GAL_TASK TSK
             , GAL_TASK_LINK LNK
         where PRJ.GAL_PROJECT_ID = TSK.GAL_PROJECT_ID
           and LNK.C_TAL_STATE < '40'
           and TSK.GAL_TASK_ID = LNK.GAL_TASK_ID
           and (   LNK.GAL_TASK_ID = aTskId
                or LNK.GAL_TASK_ID in(select TAS.GAL_TASK_ID
                                        from GAL_TASK TAS
                                       where TAS.GAL_FATHER_TASK_ID = aTskId) )
      --AND EXISTS (SELECT '*' FROM GAL_TASK_LOT_LINK LLNK WHERE LLNK.GAL_TASK_ID = LNK.GAL_TASK_ID AND LLNK.GAL_TASK_LINK_ID = LNK.gal_task_link_id AND ROWNUM = 1) --Checker avec HMO
      --AND LNK.TAL_END_PLAN_DATE IS NOT NULL;
      order by PRJ.PRJ_CODE
             , TSK.TAS_CODE
             , LNK.SCS_STEP_NUMBER;

    cursor C_DC
    is
      select   POS.DOC_DOCUMENT_ID
             , POS.DOC_POSITION_ID
             , PDE.DOC_POSITION_DETAIL_ID
             , POS.POS_FREE_DESCRIPTION
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
         where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and POS.DOC_RECORD_ID = v_doc_record_id
      order by DOC_POSITION_ID;
  begin
    if aResetResultTable = 1 then
      delete from gal_project_calc_result;

      insert into gal_project_calc_result
                  (gal_project_calc_result_id
                 , gal_pcr_comment
                 , gal_pcr_sort
                 , a_idcre
                 , a_datecre
                  )
           values (gal_project_calc_result_id_seq.nextval
                 , (select pcs.pc_functions.translateword('Sous-traitance')
                      from dual)
                 , '7'
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );

      insert into gal_project_calc_result
                  (gal_project_calc_result_id
                 , gal_pcr_comment
                 , gal_pcr_sort
                 , a_idcre
                 , a_datecre
                  )
           values (gal_project_calc_result_id_seq.nextval
                 , (select pcs.pc_functions.translateword('Anomalies Sous-traitance')
                      from dual)
                 , '17'
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );

      insert into gal_project_calc_result
                  (gal_project_calc_result_id
                 , gal_pcr_comment
                 , gal_pcr_sort
                 , a_idcre
                 , a_datecre
                  )
           values (gal_project_calc_result_id_seq.nextval
                 , (select pcs.pc_functions.translateword('A générer')
                      from dual)
                 , '19'
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );
    end if;

    --select tas_code,gal_task.gal_project_id,prj_code,gal_father_task_id into v_task_no_affaire,v_task_aff_id,v_proj,v_gal_father_id  from gal_project,gal_task
    --where gal_project.gal_project_id = gal_task.gal_project_id and gal_task_id = aTskId;
    open C_OPER;

    loop
      fetch C_OPER
       into v_proj
          , v_tsk_code
          , v_tsk_id
          , v_gal_father_task_id
          , v_c_task_type
          , v_gco_gco_good_id
          , v_pac_supplier_id
          , v_doc_record_id
          , v_tal_end_plan_date
          , v_scs_step_number
          , v_ope_long_descr
          , v_gal_task_link_id;

      exit when C_OPER%notfound;

      if v_c_task_type <> 1 then
        --IF v_tal_end_plan_date IS NOT NULL
        --THEN
        v_cnt                  := 0;
        v_pos_free_descr_conc  := ' ';

        open C_DC;

        loop
          fetch C_DC
           into v_dc_id
              , v_dc_pos_id
              , v_dc_pos_dt_id
              , v_pos_free_descr;

          exit when C_DC%notfound;

          insert into gal_project_calc_result
                      (gal_project_calc_result_id
                     , gal_task_id
                     , gal_good_id
                     , fal_supply_request_id
                     , doc_document_id
                     , doc_position_id
                     , doc_position_detail_id
                     , fal_doc_prop_id
                     , fal_lot_prop_id
                     , fal_lot_id
                     , gal_manufacture_task_id
                     , gal_pcr_qty
                     , gal_pcr_remaining_qty
                     , gal_pcr_comment
                     , gal_pcr_sort
                     , a_idcre
                     , a_datecre
                      )
               values (gal_project_calc_result_id_seq.nextval
                     , v_tsk_id
                     , v_gco_gco_good_id
                     , null
                     , v_dc_id
                     , v_dc_pos_id
                     ,   --v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                       v_gal_task_link_id
                     , null
                     , null
                     , null
                     , v_tsk_id
                     , 1
                     , 0
                     , ' (' || v_scs_step_number || ') '
                     ,   /*(SELECT pcs.pc_functions.translateword ('Sous-traitance') FROM DUAL)*/

                       --(SELECT pcs.pc_functions.translateword ('Une Demande d''achat existe pour l''opération externe') FROM DUAL)
                       --|| ' ' || trim(v_scs_step_number) --no_ope
                       --|| ' ('|| trim(v_proj)
                       --||' - '|| (SELECT NVL(MIN(TAS_CODE),' ') FROM GAL_TASK WHERE GAL_TASK_ID = v_gal_father_task_id)
                       --||' - '|| trim(v_tsk_code) || ')', --no_affaire + no_tache
                       '8'
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                      );

          v_cnt  := v_cnt + 1;

          if length(trim(v_pos_free_descr_conc) || ' ' || trim(v_pos_free_descr) ) <= 32000 then
            v_pos_free_descr_conc  := trim(v_pos_free_descr_conc) || ' ' || trim(v_pos_free_descr);
          end if;
        --A terminer ci-dessous : Controle des composés present dans POS.FREE_DESCR par rapport à la définition de gamme...
        end loop;

        close C_DC;

        /*
        IF v_cnt <> 0
        THEN
          FOR ART IN (SELECT GCO_GOOD.GOO_MAJOR_REFERENCE
                      FROM GAL_TASK_LOT_LINK,GAL_TASK_LOT,GCO_GOOD
                      WHERE GAL_TASK_LOT.GAL_TASK_LOT_ID = GAL_TASK_LOT_LINK.GAL_TASK_LOT_ID
                      AND GCO_GOOD.GCO_GOOD_ID = GAL_TASK_LOT.GCO_GOOD_ID
                      AND GAL_TASK_LOT_LINK.GAL_TASK_LINK_ID = v_gal_task_link_id) LOOP
            IF INSTR(v_pos_free_descr_conc,art.GOO_MAJOR_REFERENCE) = 0
            THEN
               INSERT INTO gal_project_calc_result
                          (gal_project_calc_result_id,gal_task_id,
                           gal_good_id, fal_supply_request_id,
                           doc_document_id, doc_position_id,
                           doc_position_detail_id, fal_doc_prop_id,
                           fal_lot_prop_id, fal_lot_id, gal_manufacture_task_id,
                           gal_pcr_qty, gal_pcr_remaining_qty,
                           gal_pcr_comment, gal_pcr_sort, a_idcre, a_datecre
                           )
               VALUES (gal_project_calc_result_id_seq.NEXTVAL,
                       v_tsk_id,v_gco_gco_good_id,NULL,NULL,NULL,--v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                       v_gal_task_link_id,NULL,NULL,NULL,v_tsk_id,
                       1,0,' (' || v_scs_step_number || ') : ' || (SELECT pcs.pc_functions.translateword ('Opération externe') FROM DUAL)
                             || ' ' || trim(v_scs_step_number) --no_ope
                             || ' ('|| trim(v_proj)
                               ||' - '|| (SELECT NVL(MIN(TAS_CODE),' ') FROM GAL_TASK WHERE GAL_TASK_ID = v_gal_father_task_id)
                             ||' - '|| trim(v_tsk_code) || ') : ' --no_affaire + no_tache
                             || (SELECT pcs.pc_functions.translateword ('Manque composé sur document existant') FROM DUAL)
                             || ' (' || trim(art.GOO_MAJOR_REFERENCE) || ')',
                       '18',PCS.PC_I_LIB_SESSION.GetUserIni,SYSDATE
                      );
            END IF;
          END LOOP;
        END IF;
        */

        --IF v_cnt = 0 THEN --Pas de DOC ST
        begin
          select '*'
            into v_exit_lot_link
            from GAL_TASK_LOT_LINK LNK
           where LNK.GAL_TASK_ID = v_tsk_id
             and LNK.GAL_TASK_LINK_ID = v_gal_task_link_id
             and rownum = 1;

          --Test si le compose est coché dans la définition de la gamme de l'opé externe en cours
          if     v_tal_end_plan_date is not null
             and v_cnt = 0   --Date OK et pas de DOC ST
                          then
            insert into gal_project_calc_result
                        (gal_project_calc_result_id
                       , gal_task_id
                       , gal_good_id
                       , fal_supply_request_id
                       , doc_document_id
                       , doc_position_id
                       , doc_position_detail_id
                       , fal_doc_prop_id
                       , fal_lot_prop_id
                       , fal_lot_id
                       , gal_manufacture_task_id
                       , gal_pcr_qty
                       , gal_pcr_remaining_qty
                       , gal_pcr_comment
                       , gal_pcr_sort
                       , a_idcre
                       , a_datecre
                        )
                 values (gal_project_calc_result_id_seq.nextval
                       , v_tsk_id
                       , v_gco_gco_good_id
                       , null
                       , null
                       , null
                       ,   --v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                         v_gal_task_link_id
                       , null
                       , null
                       , null
                       , v_tsk_id
                       , 1
                       , 0
                       , ' (' || v_scs_step_number || ') '
                       ,   /*(SELECT pcs.pc_functions.translateword ('Sous-traitance') FROM DUAL)*/

                         --(SELECT pcs.pc_functions.translateword ('Une Demande d''achat sera générée pour l''opération externe') FROM DUAL)
                         --|| ' ' || trim(v_scs_step_number) --no_ope
                         --|| ' ('|| trim(v_proj)
                         --||' - '|| (SELECT NVL(MIN(TAS_CODE),' ') FROM GAL_TASK WHERE GAL_TASK_ID = v_gal_father_task_id)
                         --||' - '|| trim(v_tsk_code) || ')', --no_affaire + no_tache
                         '20'
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                       , sysdate
                        );
          end if;
        exception
          when no_data_found then
            insert into gal_project_calc_result
                        (gal_project_calc_result_id
                       , gal_task_id
                       , gal_good_id
                       , fal_supply_request_id
                       , doc_document_id
                       , doc_position_id
                       , doc_position_detail_id
                       , fal_doc_prop_id
                       , fal_lot_prop_id
                       , fal_lot_id
                       , gal_manufacture_task_id
                       , gal_pcr_qty
                       , gal_pcr_remaining_qty
                       , gal_pcr_comment
                       , gal_pcr_sort
                       , a_idcre
                       , a_datecre
                        )
                 values (gal_project_calc_result_id_seq.nextval
                       , v_tsk_id
                       , v_gco_gco_good_id
                       , null
                       , null
                       , null
                       ,   --v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                         v_gal_task_link_id
                       , null
                       , null
                       , null
                       , v_tsk_id
                       , 1
                       , 0
                       , ' (' ||
                         v_scs_step_number ||
                         ') : ' ||
                         (select pcs.pc_functions.translateword('Opération externe')
                            from dual) ||
                         ' ' ||
                         trim(v_scs_step_number)   --no_ope
                                                ||
                         ' (' ||
                         trim(v_proj) ||
                         ' - ' ||
                         (select nvl(min(TAS_CODE), ' ')
                            from GAL_TASK
                           where GAL_TASK_ID = v_gal_father_task_id) ||
                         ' - ' ||
                         trim(v_tsk_code) ||
                         ') : '   --no_affaire + no_tache
                               ||
                         (select pcs.pc_functions.translateword('Aucun composé n''est lié à cette opération (cf.Gamme)')
                            from dual)
                       , '18'
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                       , sysdate
                        );
        end;

        --END IF;

        --ELSE--v_tal_end_plan_date NULL
        if v_tal_end_plan_date is null then
          insert into gal_project_calc_result
                      (gal_project_calc_result_id
                     , gal_task_id
                     , gal_good_id
                     , fal_supply_request_id
                     , doc_document_id
                     , doc_position_id
                     , doc_position_detail_id
                     , fal_doc_prop_id
                     , fal_lot_prop_id
                     , fal_lot_id
                     , gal_manufacture_task_id
                     , gal_pcr_qty
                     , gal_pcr_remaining_qty
                     , gal_pcr_comment
                     , gal_pcr_sort
                     , a_idcre
                     , a_datecre
                      )
               values (gal_project_calc_result_id_seq.nextval
                     , v_tsk_id
                     , v_gco_gco_good_id
                     , null
                     , null
                     , null
                     ,   --v_dc_pos_dt_id, --> Id ope externe est stocké dans le champ Position_detail_id
                       v_gal_task_link_id
                     , null
                     , null
                     , null
                     , v_tsk_id
                     , 1
                     , 0
                     , ' (' ||
                       v_scs_step_number ||
                       ') : ' ||
                       (select pcs.pc_functions.translateword('Opération externe')
                          from dual) ||
                       ' ' ||
                       trim(v_scs_step_number)   --no_ope
                                              ||
                       ' (' ||
                       trim(v_proj) ||
                       ' - ' ||
                       (select nvl(min(TAS_CODE), ' ')
                          from GAL_TASK
                         where GAL_TASK_ID = v_gal_father_task_id) ||
                       ' - ' ||
                       trim(v_tsk_code) ||
                       ') : '   --no_affaire + no_tache
                             ||
                       (select pcs.pc_functions.translateword('manque dates opérations')
                          from dual)
                     , '18'
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                      );
        end if;   --v_tal_end_plan_date NULL
      end if;   --v_c_task_type <> 1
    end loop;

    close C_OPER;

    --Suppression des lignes d'entete (surplus,besoins,appro,DF) qui n'ont pas de données liés dans la table
    delete from GAL_PROJECT_CALC_RESULT
          where GAL_PCR_SORT not in(select distinct (PCR.GAL_PCR_SORT - 1)
                                               from GAL_PROJECT_CALC_RESULT PCR
                                              where PCR.GAL_GOOD_ID is not null)
            and GAL_GOOD_ID is null;
  end check_doc_ST;

--**********************************************************************************************************--
--**********************************************************************************************************--
--***************CALCUL DE BESION SUR DOSSIER FABRICATION **************************************************--
  procedure launch_project_manufacture(
    a_tac_id       gal_task.gal_task_id%type default 0
  , a_doc_id       gal_task.doc_record_id%type default 0
  , a_tas_state    gal_task.c_tas_state%type default '10'
  , a_sessionid    number
  , a_trace        char default 'N'
  , is_Init_Header char
  )
  is
    vGcoId                    GCO_GOOD.GCO_GOOD_ID%type;
    a_aff_id                  gal_project.gal_project_id%type;
    a_planif_df               integer                           default 1;
    a_calc_df                 integer                           default 1;
    lvCfg_GAL_PROC_BEFORE_CBA varchar2(255);
    lvCfg_GAL_PROC_AFTER_CBA  varchar2(255);
  begin
    if a_tas_state < '40' then
      --CHMI 01/07/2015 Ajout PROC BEFORE CBA
      select min(gal_project_id)
        into a_aff_id
        from gal_task
       where gal_task_id = a_tac_id;   -- Nécessaire aux 2 procs BEFORE CBA et AFTER CBA

      --CHMI 17/06/2015 Ajout PROC BEFORE CBA
      lvCfg_GAL_PROC_BEFORE_CBA  := trim(PCS.PC_CONFIG.GetConfig('GAL_PROC_BEFORE_CBA') );

      if lvCfg_GAL_PROC_BEFORE_CBA is not null then
        sqlstatement  := 'BEGIN ' || lvCfg_GAL_PROC_BEFORE_CBA || '(:a_aff_id,:a_tac_id,:a_tas_state,:a_planif_df,:a_calc_df); END;';

        execute immediate sqlstatement
                    using in a_aff_id, in a_tac_id, in a_tas_state, in a_planif_df, in a_calc_df;
      end if;

      v_upd_task_status          := 'N';
      v_flag_simulation          := 'N';
      v_is_read_from_df          := 'O';
      v_level                    := 0;
      v_besoin_net               := 0;
      v_besoin_a_induire         := 0;
      v_calc_df                  := 0;
      v_planif_df                := 0;
      RAZ_VAR;

      if is_Init_Header = 'N' then
        Init_Config;
        Init_Header_result;
      end if;

      delete from gal_project_need;

      delete from gal_project_resource;

      delete from gal_need_follow_up;

      delete from gal_resource_follow_up;

      tableau_document.delete;
      gal_project_calculation.load_resource(a_tac_id, a_doc_id, '0');
      create_doc_supply_manufacture(null, a_tac_id, null, null, null);
      create_doc_componant(null, a_tac_id, null, null, null);
      create_doc_ST(a_tac_id);

      begin
        select gco_good_id
          into vGcoId
          from gal_task_lot
         where gal_task_id = a_tac_id
           and rownum = 1;
      exception
        when no_data_found then
          begin
            select gco_good_id
              into vGcoId
              from gal_task_good
             where gal_task_id = a_tac_id
               and rownum = 1;
          exception
            when no_data_found then
              vGcoId  := null;
          end;
      end;   --Pour la finalisation, le good_id est pris de facon aléatoire

      doc_finalize_finalizedocument(v_cpt_doc, a_tac_id, vGcoId);

      /*
      IF v_cpt_doc > 0
      THEN--Finalisation des documents générés par le calcul
        FOR v_line_doc IN 1 .. v_cpt_doc
        LOOP
          doc_finalize.finalizedocument(tableau_document(v_line_doc).docid);
        END LOOP;
      END IF;
      */
      if v_upd_task_status = 'Y' then
        update GAL_TASK
           set TAS_LAST_CALCULATION_DATE = sysdate
         where GAL_TASK_ID = a_tac_id;
      end if;

      --CHMI 01/07/2015 Ajout PROC AFTER CBA
      lvCfg_GAL_PROC_AFTER_CBA   := trim(PCS.PC_CONFIG.GetConfig('GAL_PROC_AFTER_CBA') );

      if lvCfg_GAL_PROC_AFTER_CBA is not null then
        sqlstatement  := 'BEGIN ' || lvCfg_GAL_PROC_AFTER_CBA || '(:a_aff_id,:a_tac_id,:a_tas_state,:a_planif_df,:a_calc_df); END;';

        execute immediate sqlstatement
                    using in a_aff_id, in a_tac_id, in a_tas_state, in a_planif_df, in a_calc_df;
      end if;

      --Ecriture des surplus et égalisation des document type NEED (surplus > update ou delete)
      --    Désactivé tant qu'on n'a pas de plsql d'update de positio_detail
      --Need_balance(a_tac_id,'6DB');
      if is_Init_Header = 'N' then
        --Suppression des lignes d'entete (surplus,besoins,appro,DF) qui n'ont pas de données liés dans la table
        delete from GAL_PROJECT_CALC_RESULT
              where GAL_PCR_SORT not in(select distinct (PCR.GAL_PCR_SORT - 1)
                                                   from GAL_PROJECT_CALC_RESULT PCR
                                                  where PCR.GAL_GOOD_ID is not null)
                and GAL_GOOD_ID is null;
      end if;

      commit;
    end if;
  end launch_project_manufacture;

--**********************************************************************************************************--
--**********************************************************************************************************--
--***************SUIVI MATIERE SUR DOSSIER FABRICATION *****************--
  procedure project_manufacture_follow_up(
    a_aff_id           gal_task.gal_project_id%type default 0
  , a_tac_id           gal_task.gal_task_id%type default 0
  , a_no_tache         gal_task.TAS_CODE%type
  , a_libel_tache      gal_task.TAS_WORDING%type
  , a_tac_date_fin     gal_task.TAS_END_DATE%type
  , a_doc_id           gal_task.doc_record_id%type default 0
  , a_sessionid        number
  , a_trace            char default 'N'
  , is_Init_Header     char
  , a_reset_temp_table char default 'Y'
  )
  is
  begin
    v_flag_simulation   := 'O';
    v_is_read_from_df   := 'O';
    v_level             := 0;
    v_besoin_net        := 0;
    v_besoin_a_induire  := 0;
    x_aff_id            := a_aff_id;
    x_sessionid         := a_sessionid;
    x_trace             := a_trace;
    RAZ_VAR;

    if is_Init_Header = 'N' then
      Init_Config;
    end if;

    if a_reset_temp_table = 'Y' then
      delete from gal_project_need;

      delete from gal_project_resource;

      delete from gal_need_follow_up;

      delete from gal_resource_follow_up;
    end if;

    gal_project_calculation.load_resource(a_tac_id, a_doc_id, '0');
    v_level             := 1;
    create_doc_supply_manufacture(a_aff_id, a_tac_id, a_no_tache, a_libel_tache, a_tac_date_fin);
    create_doc_componant(a_aff_id, a_tac_id, a_no_tache, a_libel_tache, a_tac_date_fin);
    --**CREATION POUR SUIVI DES SURPLUS **--
    INIT_SURPLUS(a_tac_id, '1', '0');

    --hmo 11.2012 _> le flag est à sorti que si tout le dispo affaire = sorti et rien à lancer et rien en appro
    update gal_need_follow_up
       set nfu_info_supply =
             (case
                when nfu_available_quantity = nfu_stm_project_quantity_out
                and nvl(nfu_to_launch_quantity, 0) = 0
                and nvl(nfu_supply_quantity, 0) = 0 then pcs.pc_functions.translateword('Sorti')
                else nfu_info_supply
              end
             );

    -- Matériel stock plus jamais en état dispo affaire , la colonne sorti a déjà été màj voir modif hmo 11.2012
    update gal_need_follow_up
       set nfu_available_quantity = null
     where ggo_supply_type = 'S'
       and ggo_supply_mode = 'A'
       and nvl(nfu_available_quantity, 0) > 0;

    commit;
  end project_manufacture_follow_up;

  --***************GENERATION DES DOCUMENTS BL (Appel Delphi Matrice Dossier Fab **************************--
  procedure create_doc_bl(a_tac_id gal_task.GAL_TASK_ID%type default 0, a_doc_record_id gal_task.DOC_RECORD_ID%type)
  is
    v_good_id         gal_task.GAL_PROJECT_ID%type;
    v_tas_ref         gal_task_link.SCS_SHORT_DESCR%type;
    v_c_task_type     GAL_TASK_LINK.C_TASK_TYPE%type;
    v_pac_supplier_id gal_task.GAL_PROJECT_ID%type;
    v_step_number     number;
    v_qty             number;
    v_flag_sort       varchar2(100);
    v_destin          gal_task.GAL_PROJECT_ID%type;
    v_destid_prev     gal_task.GAL_PROJECT_ID%type;
    v_sort            varchar2(100);
    v_err             number;

    cursor C_DOC
    is
      select   GCO_GOOD_ID
             , GTD_QUANTITY
             , GAL_TASK_LINK_ID
             , GAL_TASK_LINK_ID_PREV
             , trim(to_char(GAL_TASK_LINK_ID) || to_char(GAL_TASK_LINK_ID_PREV) )
          from GAL_TASK_LOT_LINK_DOC
         where GAL_TASK_LOT_LINK_DOC.GAL_TASK_ID = a_tac_id
           and DOC_DOCUMENT_ID is null
           and DOC_POSITION_ID is null
      order by trim(to_char(GAL_TASK_LINK_ID) || to_char(GAL_TASK_LINK_ID_PREV) );
  begin
    outdocumentid  := null;
    outpositionid  := null;
    --astockid      := NULL;
    --alocationid   := NULL;
    v_flag_sort    := '0';
    vdocnumber     := null;
    vrecordid      := a_doc_record_id;
    vdocid         := null;
    raz_var;
    tableau_document.delete;
    v_err          := 0;

    open C_DOC;

    loop
      fetch C_DOC
       into v_good_id
          , v_qty
          , v_destin
          , v_destid_prev
          , v_sort;

      exit when C_DOC%notfound;
      v_err        := 0;
      verrormsg    := ' ';

      if v_sort <> v_flag_sort then
        outdocumentid  := null;
        vdocnumber     := null;
        vrecordid      := a_doc_record_id;
        vdocid         := null;

        begin
          select doc_gauge_id
            into V_GAL_GAUGE_DELIVERY_ORDER
            from doc_gauge
           where gau_describe = (select pcs.pc_config.getconfig('GAL_GAUGE_DELIVERY_ORDER')
                                   from dual);
        exception
          when no_data_found then
            V_GAL_GAUGE_DELIVERY_ORDER  := null;
        end;

        if     V_GAL_GAUGE_DELIVERY_ORDER is not null
           and vrecordid is not null then
          begin
            select C_TASK_TYPE
                 , PAC_SUPPLIER_PARTNER_ID
              into v_c_task_type
                 , v_pac_supplier_id
              from GAL_TASK_LINK
             where GAL_TASK_LINK.GAL_TASK_LINK_ID = v_destin;   --v_destid_prev;

            if v_c_task_type = 1 then
              v_pac_supplier_id  := null;
            end if;
          exception
            when no_data_found then
              v_pac_supplier_id  := null;
          end;

          doc_document_generate.generatedocument(anewdocumentid   => vdocid
                                               , aerrormsg        => verrormsg
                                               , amode            => null
                                               , agaugeid         => V_GAL_GAUGE_DELIVERY_ORDER
                                               , adocnumber       => vdocnumber
                                               , arecordid        => vrecordid
                                               , aThirdID         => v_pac_supplier_id
                                                );

          if verrormsg is not null then
            DBMS_OUTPUT.put_line('Erreur création entête de document');
            vdocid  := null;
          end if;
        /*
        IF vdocid IS NOT NULL
        THEN
          -- Cette procédure libère le document et recalcule les montants
          doc_finalize.finalizedocument (vdocid);
        END IF;
        */
        end if;

        outdocumentid  := vdocid;
      end if;

      if outdocumentid is not null then
        /*
        BEGIN
          SELECT STM_STOCK_ID INTO x_pdt_stk_dflt FROM GCO_PRODUCT WHERE GCO_GOOD_ID = V_GOOD_ID;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          x_pdt_stk_dflt := null;
        END;
        */
        gal_project_calculation.generateposdoc(vdocumentid      => outdocumentid
                                             , vgoodid          => v_good_id
                                             , vbasisquantity   => v_qty
                                             , vstockid         => null
                                             ,   --x_pdt_stk_dflt,
                                               vlocationid      => null
                                             ,   --alocationid,
                                               vFinaldelay      => sysdate
                                             , ataskid          => a_tac_id
                                             , outposid         => outpositionid
                                             , err              => v_err
                                              );

        if v_err = 0 then
          update GAL_TASK_LOT_LINK_DOC
             set DOC_DOCUMENT_ID = outdocumentid
               , DOC_POSITION_ID = outpositionid
           where GAL_TASK_ID = a_tac_id
             and GAL_TASK_LINK_ID = v_destin
             and GAL_TASK_LINK_ID_PREV = v_destid_prev
             and GCO_GOOD_ID = v_good_id
             and GTD_QUANTITY = v_qty
             and DOC_DOCUMENT_ID is null
             and DOC_POSITION_ID is null;
        end if;
      end if;

      v_flag_sort  := v_sort;
    end loop;

    close C_DOC;

    if v_cpt_doc > 0 then   --Finalisation des documents générés par le calcul
      for v_line_doc in 1 .. v_cpt_doc loop
        doc_finalize.finalizedocument(tableau_document(v_line_doc).docid);
      end loop;
    end if;
  /*
  EXCEPTION
    WHEN OTHERS THEN
       BEGIN
         SELECT trim(Gau_Describe) INTO vGauDescribe FROM doc_gauge WHERE doc_gauge_id = V_GAL_GAUGE_DELIVERY_ORDER;
       EXCEPTION WHEN NO_DATA_FOUND THEN vGauDescribe := ' '; END;
       verrormsg := vGauDescribe || ' > ' || DBMS_UTILITY.format_error_stack; -- || DBMS_UTILITY.format_call_stack;
       WriteErrorInResult (v_taches_tac_id,vgoodid,vbasisquantity,vdocid,verrormsg);
       err := 1; --Traper dans delphi a faire  !!!!!!!!!!!
       --commit;
  */
  end create_doc_bl;

  --*************** Stock Dispo Entreprise **************************--
  function StockDispoEntreprise(aGoodId GCO_GOOD.GCO_GOOD_ID%type, aTaskId GAL_TASK.GAL_TASK_ID%type)
    return number
  is
    vStockDispoEntreprise number;
  begin
    vStockDispoEntreprise  := 0;

    if trim(V_GAL_PROC_INIT_QTE_STK_ENT) is null then
      begin
        select sum(SPO.SPO_AVAILABLE_QUANTITY + SPO.SPO_PROVISORY_INPUT)
          into vStockDispoEntreprise
          from STM_STOCK_POSITION SPO
         where SPO.GCO_GOOD_ID = aGoodId
           and SPO.STM_STOCK_ID <> v_stm_stock_id_project;
      exception
        when no_data_found then
          vStockDispoEntreprise  := 0;
      end;
    else
      -- execution de la commande
      execute immediate 'SELECT ' || trim(V_GAL_PROC_INIT_QTE_STK_ENT) || '(:aGoodId,:aTaskId) FROM DUAL'
                   into vStockDispoEntreprise
                  using aGoodId, aTaskId;
    end if;

    return(nvl(vStockDispoEntreprise, 0) );
  end StockDispoEntreprise;

  --*************** Stock Dispo Net ****** **************************--
  function StockDispoNet(aGoodId GCO_GOOD.GCO_GOOD_ID%type, aTaskId GAL_TASK.GAL_TASK_ID%type)
    return number
  is
    vStockDispoNet              number;
    SommeSPO_AVAILABLE_QUANTITY STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    SommeBesoinsLibre           FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    SommeApprosLibre            FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    SommeStocksMini             number;
  begin
    SommeSPO_AVAILABLE_QUANTITY  := 0;
    SommeBesoinsLibre            := 0;
    SommeApprosLibre             := 0;
    SommeStocksMini              := 0;

    if trim(V_GAL_PROC_INIT_QTE_STK_NET) is null then
      -- Récupérer la Qté dispoinible enstock.
      select sum(SPO_AVAILABLE_QUANTITY)
        into SommeSPO_AVAILABLE_QUANTITY
        from STM_STOCK_POSITION
       where GCO_GOOD_ID = aGoodId
         and STM_STOCK_ID in(select STM_STOCK_ID
                               from STM_STOCK
                              where C_ACCESS_METHOD = 'PUBLIC'
                                and STM_STOCK_ID <> v_stm_stock_id_project);   -- and STO_NEED_CALCULATION = 1);

      -- Récupérer la somme des besoins libres
      select sum(FAN_FREE_QTY)
        into SommeBesoinsLibre
        from FAL_NETWORK_NEED
       where GCO_GOOD_ID = aGoodId
         and FAN_FREE_QTY > 0
         and STM_STOCK_ID <> v_stm_stock_id_project;

      --       AND TRUNC(FAN_BEG_PLAN) <= PrmDate;

      --if PrmTakeFreeOnSupply = 1 then
      -- Récupérer la somme des Appros libres
      select sum(FAN_FREE_QTY)
        into SommeApprosLibre
        from FAL_NETWORK_SUPPLY
       where GCO_GOOD_ID = aGoodId
         and FAN_FREE_QTY > 0
         and STM_STOCK_ID <> v_stm_stock_id_project;

      --         AND TRUNC(FAN_END_PLAN) <= PrmDate;
      --end if;

      --if PrmWithStockMini= 1 then
      -- Récupérer la somme des stocks minis
      select sum(CST_QUANTITY_MIN)
        into SommeStocksMini
        from GCO_COMPL_DATA_STOCK
       where GCO_GOOD_ID = aGoodId
         and STM_STOCK_ID <> v_stm_stock_id_project;

      --end if;

      --Dbms_output.put_line('SommeSPO_AVAILABLE_QUANTITY:' || SommeSPO_AVAILABLE_QUANTITY);
      --Dbms_output.put_line('SommeBesoinsLibre          :' || SommeBesoinsLibre);
      --Dbms_output.put_line('SommeApprosLibre           :' || SommeApprosLibre);
      --Dbms_output.put_line('SommeStocksMini            :' || SommeStocksMini);
      vStockDispoNet  := nvl(SommeSPO_AVAILABLE_QUANTITY, 0) - nvl(SommeBesoinsLibre, 0) + nvl(SommeApprosLibre, 0) - nvl(SommeStocksMini, 0);
    else
      -- execution de la commande
      execute immediate 'SELECT ' || trim(V_GAL_PROC_INIT_QTE_STK_NET) || '(:aGoodId,:aTaskId) FROM DUAL'
                   into vStockDispoNet
                  using aGoodId, aTaskId;
    end if;

    return nvl(vStockDispoNet, 0);
  -- ENF;
  end StockDispoNet;

  /**
  * procédure  Load_Project_Waste
  * Description
  *   Cumule les rebuts sur affaires pendant le clacul de besoisn
  */
  procedure Load_Project_Waste(iGalTaskID number)
  is
    pgaudescribe varchar2(4000);
    lDocRecordID DOC_RECORD.DOC_RECORD_ID%type;
  begin
    begin
      select ';' || nvl(trim(pcs.pc_config.getconfig('GAL_GAUGE_WASTE_PROJECT') ), '') || ';'
        into pgaudescribe
        from dual;
    exception
      when no_data_found then
        pgaudescribe  := null;
    end;

    begin
      select doc_record_id
        into lDocRecordID
        from GAL_TASK
       where GAL_TASK_ID = iGalTaskId;
    exception
      when no_data_found then
        lDocRecordID  := null;
    end;

    delete from GAL_WASTE_PROJECT;

    if     (pgaudescribe is not null)
       and (lDocRecordID is not null) then
      insert into GAL_WASTE_PROJECT
                  (GCO_GOOD_ID
                 , GWP_QUANTITY
                  )
        (select   POS.GCO_GOOD_ID
                , sum(round(POS.POS_FINAL_QUANTITY * POS.POS_CONVERT_FACTOR, GOO.GOO_NUMBER_OF_DECIMAL) )
             from DOC_POSITION POS
                , DOC_GAUGE GAU
                , DOC_DOCUMENT DMT
                , GCO_GOOD GOO
            where POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
              and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
              and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
              and POS.DOC_RECORD_ID = lDocRecordID
              and POS.C_DOC_POS_STATUS <> '05'   --non selection des doc. annulés
              and instr(pgaudescribe, ';' || trim(gau.gau_describe) || ';') <> 0
         group by POS.GCO_GOOD_ID);
    end if;
  end Load_Project_Waste;

  /**
  * function  AddNeedIfWaste
  * Description
  *   Augmente les besoins sur le produit si il y a du rebut
  */
  function AddNeedIfWaste(iGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNeedQuantity in number)
    return number
  is
    lInterNumber number;
  begin
    begin
      select GWP_QUANTITY
        into lInterNumber
        from GAL_WASTE_PROJECT
       where GCO_GOOD_ID = iGcoGoodID;

      if lInterNumber = 0 then
        return 0;
      else
        if iNeedQuantity < lInterNumber then
          update GAL_WASTE_PROJECT
             set GWP_QUANTITY = lInterNumber - iNeedQuantity
           where gco_good_id = iGcoGoodID;

          return iNeedQuantity;
        else
          update GAL_WASTE_PROJECT
             set GWP_QUANTITY = 0
           where gco_good_id = iGcoGoodID;

          return lInterNumber;
        end if;
      end if;
    exception
      when no_data_found then
        return 0;
    end;
  end AddNeedIfWaste;

  /*
  * procédure  init_resource_follow_up_forWaste
  * Description
  *   Met à jour la table Gal_Ressource_Folow_Up avec les rebut -> Possible de voir pour chaque article quels sont les documents de rebut
  */
  procedure InitResourceFollowUpForWaste(
    iGalTaskID         in GAL_TASK.GAL_TASK_ID%type
  , IGalProjectID      in GAL_PROJECT.GAL_PROJECT_ID%type
  , iGalNeedFollowUpID in GAL_NEED_FOLLOW_UP.GAL_NEED_FOLLOW_UP_ID%type
  , iGcoGoodID         in GCO_GOOD.GCO_GOOD_ID%type
  , iDmtNumber         in DOC_DOCUMENT.DMT_NUMBER%type
  , iDocDocumentID     in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iDmtDateDocument   in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , iWasteQuantity     in GAL_WASTE_PROJECT.GWP_QUANTITY%type
  )
  is
  begin
    insert into gal_resource_follow_up
                (gal_resource_follow_up_id
               , gal_need_follow_up_id
               , gal_project_id
               , gal_task_id
               , gal_good_id
               , rfu_supply_number
               , rfu_envisaged_date
               , doc_document_id
               , rfu_used_quantity
               , rfu_type
               , rfu_supply_mode
               , rfu_supply_type
               , doc_position_detail_id
                )
         values (gal_resource_follow_up_id_seq.nextval
               , iGalNeedFollowUpID
               , iGalProjectID
               , iGalTaskID
               , iGcoGoodID
               , iDmtNumber
               , iDmtDateDocument
               , iDocDocumentID
               , -1 * iWasteQuantity
               , '2BA'
               , 'S'
               , 'S'
               , 1
                );
  end InitResourceFollowUpForWaste;

  /**
  * procédure  PutInfoRessDocumentWaste
  * Description
  *   Met à jour et calcule la liste des ressources en rebuts dans la table galressourcefollowup
  * @created hmo 29.03.2014
  * @private
  * @param good id, iDoc_Record_ID : lNeedQuantity le besoin du produit selon la nomenclature ou autre
  * @Return  besoin augmenté:
  */
  procedure PutInfoRessDocumentWaste(iGalTaskID in GAL_TASK.GAL_TASK_ID%type, iGalProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
  is
    pgaudescribe             varchar2(4000);
    lDocRecordID             DOC_RECORD.DOC_RECORD_ID%type;
    lCptWasteToCover         number;
    lCptWasteToUseByDocument number;
  begin
    begin
      select ';' || nvl(trim(pcs.pc_config.getconfig('GAL_GAUGE_WASTE_PROJECT') ), '') || ';'
        into pgaudescribe
        from dual;
    exception
      when no_data_found then
        pgaudescribe  := null;
    end;

    begin
      select doc_record_id
        into lDocRecordID
        from GAL_TASK
       where GAL_TASK_ID = iGalTaskId;
    exception
      when no_data_found then
        lDocRecordID  := null;
    end;

    delete      GAL_WASTE_PROJECT;

    if     (pgaudescribe is not null)
       and (lDocRecordID is not null) then
      for tblDocumentWaste in (select   POS.GCO_GOOD_ID
                                      , sum(round(POS.POS_FINAL_QUANTITY * POS.POS_CONVERT_FACTOR, GOO.GOO_NUMBER_OF_DECIMAL) ) WASTE_QUANTITY
                                      , DMT.DOC_DOCUMENT_ID
                                      , DMT.DMT_NUMBER
                                      , DMT.DMT_DATE_DOCUMENT
                                   from DOC_POSITION POS
                                      , DOC_GAUGE GAU
                                      , DOC_DOCUMENT DMT
                                      , GCO_GOOD GOO
                                  where POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                    and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                                    and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                    and POS.DOC_RECORD_ID = lDocRecordID
                                    and POS.C_DOC_POS_STATUS <> '05'   --non selection des doc. annulés
                                    and instr(pgaudescribe, ';' || trim(gau.gau_describe) || ';') <> 0
                               group by DMT.DOC_DOCUMENT_ID
                                      , DMT.DMT_NUMBER
                                      , DMT.DMT_DATE_DOCUMENT
                                      , POS.GCO_GOOD_ID) loop
        insert into GAL_WASTE_PROJECT
                    (GAL_WASTE_PROJECT_ID
                   , GCO_GOOD_ID
                   , GWP_QUANTITY
                   , DOC_DOCUMENT_ID
                   , DMT_NUMBER
                   , DMT_DATE_DOCUMENT
                    )
             values (gal_resource_follow_up_id_seq.nextval
                   , tblDocumentWaste.GCO_GOOD_ID
                   , tblDocumentWaste.WASTE_QUANTITY
                   , tblDocumentWaste.DOC_DOCUMENT_ID
                   , tblDocumentWaste.DMT_NUMBER
                   , tblDocumentWaste.DMT_DATE_DOCUMENT
                    );
      end loop;

      for tblNeedRessourceFollowUp in (select GAL_NEED_FOLLOW_UP_ID
                                            , GCO_GOOD_ID
                                            , NFU_NET_QUANTITY_NEED
                                            , NFU_INTER_NEED_QUANTITY
                                            , (NFU_NET_QUANTITY_NEED - NFU_INTER_NEED_QUANTITY) WASTEQTY
                                         from GAL_NEED_FOLLOW_UP
                                        where nfu_net_quantity_need <> nfu_inter_need_quantity) loop
        lCptWasteToCover  := tblNeedRessourceFollowUp.WASTEQTY;

        for tbl_GalWasteProjectDocument in (select GAL_WASTE_PROJECT_ID
                                                 , GWP_QUANTITY
                                                 , DMT_DATE_DOCUMENT
                                                 , DOC_DOCUMENT_ID
                                                 , DMT_NUMBER
                                              from GAL_WASTE_PROJECT
                                             where GCO_GOOD_ID = tblNeedRessourceFollowUp.GCO_GOOD_ID
                                               and GWP_QUANTITY > 0) loop
          if tbl_GalWasteProjectDocument.GWP_QUANTITY <= lCptWasteToCover then
            update GAL_WASTE_PROJECT
               set GWP_QUANTITY = 0
             where GAL_WASTE_PROJECT_ID = tbl_GalWasteProjectDocument.GAL_WASTE_PROJECT_ID;

            lCptWasteToCover          := lCptWasteToCover - tbl_GalWasteProjectDocument.GWP_QUANTITY;
            lCptWasteToUseByDocument  := tbl_GalWasteProjectDocument.GWP_QUANTITY;
          else
            update GAL_WASTE_PROJECT
               set GWP_QUANTITY = tbl_GalWasteProjectDocument.GWP_QUANTITY - lCptWasteToCover
             where GAL_WASTE_PROJECT_ID = tbl_GalWasteProjectDocument.GAL_WASTE_PROJECT_ID;

            lCptWasteToUseByDocument  := lCptWasteToCover;
            lCptWasteToCover          := 0;
          end if;

          InitResourceFollowUpForWaste(iGalTaskID
                                     , iGalProjectID
                                     , tblNeedRessourceFollowUp.GAL_NEED_FOLLOW_UP_ID
                                     , tblNeedRessourceFollowUp.GCO_GOOD_ID
                                     , tbl_GalWasteProjectDocument.DMT_NUMBER
                                     , tbl_GalWasteProjectDocument.DOC_DOCUMENT_ID
                                     , tbl_GalWasteProjectDocument.DMT_DATE_DOCUMENT
                                     , lCptWasteToUseByDocument
                                      );
          exit when lCptWasteToCover = 0;
        end loop;
      end loop;
    end if;
  end PutInfoRessDocumentWaste;
end gal_project_calculation;
