--------------------------------------------------------
--  DDL for Package Body GAL_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_FUNCTIONS" 
is
  lCDAFRecordCategoryLinkId DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type   default null;

--******************************************************************************************************
  function getCDAFRecordCategoryLinkId
    return DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type
  is
  begin
    if lCDAFRecordCategoryLinkId is null then
      begin
        select DOC_RECORD_CATEGORY_LINK_ID
          into lCDAFRecordCategoryLinkId
          from DOC_RECORD_CATEGORY_LINK
         where C_RCO_LINK_CODE = 'CDAF';
      exception
        when no_data_found then
          null;
      end;
    end if;

    return lCDAFRecordCategoryLinkId;
  end getCDAFRecordCategoryLinkId;

  /**
  * procedure SetDefaultCompanyName
  * Description
  *   Initialise la société PCS en fonction du paramètre aCompanyName ou si null en fonction de l'utilisateur
  *   PCS propriétaire du schéma courant. Cela implique la création d'un utilisateur PCS de même nom que le schéma
  *   courant.
  * @created VJ 23.03.2005
  */
  procedure SetDefaultCompanyName
  is
    cursor crDefaultCompany
    is
      select   PC_COMP_ID
             , COM_NAME
             , SCRDBOWNER
          from PCS.V_PC_COMP_OWNER
         where SCRDBOWNER = sys_context('USERENV', 'CURRENT_SCHEMA')
           and SCRDB_LINK is null
      order by COM_NAME asc;

    tplDefaultCompany crDefaultCompany%rowtype;
  begin
    open crDefaultCompany;

    fetch crDefaultCompany
     into tplDefaultCompany;

    if crDefaultCompany%found then
      PCS.PC_I_LIB_SESSION.InitSession(tplDefaultCompany.COM_NAME, 'GALEI', null, null);
    end if;

    close crDefaultCompany;
  end SetDefaultCompanyName;

--******************************************************************************************************
  procedure SetOptimizerModeOn
  is   --Bug oracle en version 10.0.2.0 du order by siglings dans les connect by (oblige à modifier ce param de session)
    v_version varchar2(60);
  begin
      --select version into v_version from GV$INSTANCE;
    --if v_version like ('10.2.0.2%')
    --then
    execute immediate 'alter session set "_optimizer_connect_by_cost_based" = true';
  exception
    when others then
      null;
  --end if;
  --exception when no_data_found then null;
  end SetOptimizerModeOn;

--******************************************************************************************************
  procedure SetOptimizerModeOff
  is
    v_version varchar2(60);
  begin
      --select version into v_version from GV$INSTANCE;
    --if v_version like ('10.2.0.2%')
    --then
    execute immediate 'alter session set "_optimizer_connect_by_cost_based" = false';
  exception
    when others then
      null;
  --end if;
  --exception when no_data_found then null;
  end SetOptimizerModeOff;

--******************************************************************************************************
  function GET_CC_PC_CONFIG(a_pc_conf_name in varchar2)
    return varchar2
  is
    v_res number := null;
  begin
    -- Initialise les variables de l'environnement PCS
    --SetDefaultCompanyName;
    select GAL_COST_CENTER_ID
      into v_res
      from GAL_COST_CENTER
     where GCC_CODE = PCS.PC_CONFIG.GetConfig(a_pc_conf_name);

    --where GCC_CODE = GAL_FUNCTIONS.INIT_PARAM('GAL_ANALYTIC_NATURE_STOCK');
    return(v_res);
  exception
    when no_data_found then
      return(null);
  end GET_CC_PC_CONFIG;

--******************************************************************************************************
  function GET_PC_CONFIG(a_pc_conf_name in varchar2)
    return varchar2
  is
    v_res varchar2(100) := null;
  begin
    -- Initialise les variables de l'environnement PCS
    --SetDefaultCompanyName;
    select PCS.PC_CONFIG.GetConfig(a_pc_conf_name)
      into v_res
      from dual;

    return(v_res);
  exception
    when no_data_found then
      return(null);
  end GET_PC_CONFIG;

--******************************************************************************************************
-- Contrôle d'existence d'une ou plusieurs demandes d'approvisionnement sur un dossier -----------------
  function GET_CPT_FSR(a_doc_record_id in number, a_status in varchar2)
    return number
  is
    v_cpt number := 0;
  -- a_status doit avoir une des valeurs suivantes
  -- * si on veut tous les status
  -- 1 si on veut le status 1 (ou 2, 3, ...)
  -- A si on veut les status correspondants à des données actives (ouvertes). Exemple: DA "à valider" ou "validée"
  begin
    select count(*)
      into v_cpt
      from fal_supply_request
     where DOC_RECORD_ID = a_doc_record_id
       and (   a_status = '*'
            or C_REQUEST_STATUS = a_status
            or (    a_status = 'A'
                and C_REQUEST_STATUS in('1', '2') ) );

    return(v_cpt);
  exception
    when no_data_found then
      return(0);
  end GET_CPT_FSR;

--******************************************************************************************************
-- Contrôle d'existence d'une ou plusieurs propositions d'approvisionnement sur un dossier -------------
  function GET_CPT_POA(a_doc_record_id in number)
    return number
  is
    v_cpt number := 0;
  begin
    select count(*)
      into v_cpt
      from fal_doc_prop
     where DOC_RECORD_ID = a_doc_record_id;

    return(v_cpt);
  exception
    when no_data_found then
      return(0);
  end GET_CPT_POA;

--******************************************************************************************************
-- Contrôle d'existence d'une ou plusieurs propositions de fabrication sur un dossier ------------------
  function GET_CPT_POF(a_doc_record_id in number)
    return number
  is
    v_cpt number := 0;
  begin
    select count(*)
      into v_cpt
      from fal_lot_prop
     where DOC_RECORD_ID = a_doc_record_id;

    return(v_cpt);
  exception
    when no_data_found then
      return(0);
  end GET_CPT_POF;

--******************************************************************************************************
-- Contrôle d'existence d'un ou plusieurs documents sur un dossier -------------------------------------
  function GET_CPT_DOC(a_doc_record_id in number, a_status in varchar2)
    return number
  is
    v_cpt number := 0;
  -- a_status doit avoir une des valeurs suivantes
  -- * si on veut tous les status
  -- 1 si on veut le status 1 (ou 2, 3, ...)
  -- A si on veut les status correspondants à des données actives (ouvertes). Exemple: DA "à valider" ou "validée"
  begin
    select count(*)
      into v_cpt
      from doc_position
     where DOC_RECORD_ID = a_doc_record_id
       and (   a_status = '*'
            or C_DOC_POS_STATUS = a_status
            or (    a_status = 'A'
                and C_DOC_POS_STATUS in('01', '02', '03') ) );

    return(v_cpt);
  exception
    when no_data_found then
      return(0);
  end GET_CPT_DOC;

--******************************************************************************************************
-- Contrôle d'existence d'un ou plusieurs OF sur un dossier --------------------------------------------
  function GET_CPT_OF(a_doc_record_id in number, a_status in varchar2)
    return number
  is
    v_cpt number := 0;
  -- a_status doit avoir une des valeurs suivantes
  -- * si on veut tous les status
  -- 1 si on veut le status 1 (ou 2, 3, ...)
  -- A si on veut les status correspondants à des données actives (ouvertes). Exemple: DA "à valider" ou "validée"
  begin
    select count(*)
      into v_cpt
      from fal_lot
     where DOC_RECORD_ID = a_doc_record_id
       and (   a_status = '*'
            or C_LOT_STATUS = a_status
            or (    a_status = 'A'
                and C_LOT_STATUS in('1', '2', '4') ) );

    return(v_cpt);
  exception
    when no_data_found then
      return(0);
  end GET_CPT_OF;

--******************************************************************************************************
-- Appel de la fonction standard de recherche du calendrier par defaut ---------------------------------
  function getdefaultcalendar
    return number
  is
  begin
    return FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar;
  end getdefaultcalendar;

--******************************************************************************************************
-- Retourne la liste des produit sur un gal_task_lot_link ----------------------------------------------
  function get_Goods_gal_task_lot_link(pGal_Task_Link_Id in GAL_TASK_LINK.GAL_TASK_LINK_ID%type)
    return varchar2
  is
    result varchar2(4000);
  begin
    result  := null;

    for Cur in (select   g.goo_major_reference
                       , l.GTL_SEQUENCE
                    from gco_good g
                       , gal_task_lot l
                       , gal_task_lot_link k
                   where k.GAL_TASK_LINK_ID = pGal_Task_Link_Id
                     and k.GAL_TASK_LOT_ID = l.GAL_TASK_LOT_ID
                     and l.GCO_GOOD_ID = g.GCO_GOOD_ID
                order by l.GTL_SEQUENCE) loop
      if result is null then
        result  := Cur.goo_major_reference;
      else
        result  := result || '; ' || Cur.goo_major_reference;
      end if;
    end loop;

    return result;
  exception
    when no_data_found then
      return null;
  end get_Goods_gal_task_lot_link;

  /**
  * Description
  *    retourne sous forme de curseur, les affaires liées à une commande
  */
  function GetProjectRecord(aRecordId in DOC_RECORD.DOC_RECORD_ID%type, aTblRecordId ID_TABLE_TYPE default null, aExcludeList ID_TABLE_TYPE default null)
    return ID_TABLE_TYPE
  is
    vRcoType     DOC_RECORD.C_RCO_TYPE%type;
    vResult      ID_TABLE_TYPE;
    vSubSet      ID_TABLE_TYPE;
    vExcludeList ID_TABLE_TYPE;
  begin
    -- teste si on a la fabrication sur DF (dossier de fabrication)
    if PCS.PC_CONFIG.GetConfig('GAL_PROJECT_MANAGEMENT') = '1' then
      if aRecordID = 0 then
        -- Traitement d'une liste de dossier
        if aExcludeList is not null then
          vExcludeList  := aExcludeList multiset union distinct aTblRecordId;
        else
          vExcludeList  := aTblRecordId;

          begin
            select column_value
            bulk collect into vExcludeList
              from table(aTblRecordID) TMP
                 , DOC_RECORD RCO
             where RCO.DOC_RECORD_ID = TMP.column_value
               and RCO.C_RCO_TYPE = '01';
          exception
            when no_data_found then
              vExcludeList  := ID_TABLE_TYPE();
          end;
        end if;

        vResult  := vExcludeList;

        -- type "Affaire"
        select distinct RCL2.DOC_RECORD_SON_ID
        bulk collect into vSubSet
                   from DOC_RECORD_LINK RCL1
                      , DOC_RECORD_LINK RCL2
                  where RCL1.DOC_RECORD_SON_ID in(select column_value
                                                    from table(aTblRecordId) )
                    and RCL1.DOC_RECORD_CATEGORY_LINK_ID = GAL_FUNCTIONS.getCDAFRecordCategoryLinkId
                    and RCL2.DOC_RECORD_CATEGORY_LINK_ID = GAL_FUNCTIONS.getCDAFRecordCategoryLinkId
                    and RCL2.DOC_RECORD_FATHER_ID = RCL1.DOC_RECORD_FATHER_ID
                    and RCL2.DOC_RECORD_SON_ID not in(select column_value
                                                        from table(vExcludeList) );

        vSubSet := vSubSet multiset except vResult;

        if vSubSet.exists(1) then
          --Retirer des dossiers trouvés les dossiers trouvés précédemment
          vResult := vResult multiset union distinct GetProjectRecord(0, vSubSet, vResult);
        end if;
      else   -- Traitement d'un dossier unique
        -- recherche du type de dossier
        select C_RCO_TYPE
          into vRcoType
          from DOC_RECORD
         where DOC_RECORD_ID = aRecordId
           and C_RCO_TYPE in('01', '09');

        if aExcludeList is not null then
          vExcludeList  := aExcludeList multiset union distinct ID_TABLE_TYPE(aRecordId);
        elsif vRcoType = '01' then
          vExcludeList  := ID_TABLE_TYPE(aRecordId);
        else
          vExcludeList  := ID_TABLE_TYPE();
        end if;

        vResult  := vExcludeList;

        -- type "Affaire"
        if vRcoType = '01' then
          select distinct RCL2.DOC_RECORD_SON_ID
          bulk collect into vSubSet
                     from DOC_RECORD_LINK RCL1
                        , DOC_RECORD_LINK RCL2
                    where RCL1.DOC_RECORD_CATEGORY_LINK_ID = GetCDAFRecordCategoryLinkId
                      and RCL2.DOC_RECORD_CATEGORY_LINK_ID = GetCDAFRecordCategoryLinkId
                      and RCL1.DOC_RECORD_SON_ID = aRecordId
                      and RCL2.DOC_RECORD_FATHER_ID = RCL1.DOC_RECORD_FATHER_ID;

          --Retirer des dossiers trouvés les dossiers trouvés précédemment
          vSubSet := vSubSet multiset except vResult;
          -- si on a des dossiers enfants
          if vSubSet.exists(1) then
            vResult := vResult multiset union distinct GetProjectRecord(0, vSubSet, vResult);
          end if;
        -- type "Commande d'affaire"
        elsif vRcoType = '09' then
          -- liste des affaires liées au document
          select distinct RCL1.DOC_RECORD_SON_ID
          bulk collect into vSubSet
                     from DOC_RECORD_LINK RCL1
                    where RCL1.DOC_RECORD_CATEGORY_LINK_ID = GetCDAFRecordCategoryLinkId
                      and rcl1.DOC_RECORD_FATHER_ID = aRecordId;

          -- si le dossier n'a pas déjà été traité
          vSubSet := vSubSet multiset except vResult;

          if vSubSet.exists(1) then
            vResult := vResult multiset union distinct GetProjectRecord(0, vSubSet, vResult);
          end if;
        end if;
      end if;
    end if;

    return vResult;
  exception
    when no_data_found then
      -- si le dossier n'est pas du bon type
      return ID_TABLE_TYPE();
  end GetProjectRecord;

     /**
  * Description
  *    retourne sous forme de curseur, les affaires liées à une commande
  */
  function GetOrderRecord(aRecordId in DOC_RECORD.DOC_RECORD_ID%type, aTblRecordID ID_TABLE_TYPE default null, aExcludeList ID_TABLE_TYPE default null)
    return ID_TABLE_TYPE
  is
    vResult ID_TABLE_TYPE;
  begin
    -- teste si on a la fabrication sur DF (dossier de fabrication)
    if PCS.PC_CONFIG.GetConfig('GAL_PROJECT_MANAGEMENT') = '1' then
      select cast(multiset(select distinct RCL.DOC_RECORD_FATHER_ID
                                      from table(GetProjectRecord(aRecordId, aTblRecordID) ) RCO
                                         , DOC_RECORD_LINK RCL
                                     where RCO.column_value = RCL.DOC_RECORD_SON_ID) as ID_TABLE_TYPE)
        into vResult
        from dual;
    else
      vResult  := ID_TABLE_TYPE();
    end if;

    return vResult;
  exception
    when no_data_found then
      return ID_TABLE_TYPE();
  end GetOrderRecord;

  function GetProjectOrderRecord(aRecordId in DOC_RECORD.DOC_RECORD_ID%type, aTblRecordID ID_TABLE_TYPE default null, aExcludeList ID_TABLE_TYPE default null)
    return ID_TABLE_TYPE
  is
    vResult        ID_TABLE_TYPE;
    vProjectRecord ID_TABLE_TYPE;
  begin
    -- teste si on a la fabrication sur DF (dossier de fabrication)
    if PCS.PC_CONFIG.GetConfig('GAL_PROJECT_MANAGEMENT') = '1' then
      if aRecordID = 0 then
        vProjectRecord  := GetProjectRecord(0, aTblRecordID);
      else
        vProjectRecord  := GetProjectRecord(aRecordID);
      end if;

      select cast(multiset(select distinct rcl2.doc_record_son_id
                                      from table(vProjectRecord) RCO
                                         , DOC_RECORD_LINK RCL1
                                         , DOC_RECORD_LINK RCL2
                                     where RCL1.DOC_RECORD_CATEGORY_LINK_ID = GetCDAFRecordCategoryLinkId
                                       and RCL2.DOC_RECORD_CATEGORY_LINK_ID = GetCDAFRecordCategoryLinkId
                                       and rcl1.DOC_RECORD_SON_ID = RCO.column_value
                                       and rcl2.DOC_RECORD_FATHER_ID = rcl1.DOC_RECORD_FATHER_ID
                          ) as ID_TABLE_TYPE
                 )
        into vResult
        from dual;

      vResult := vResult multiset union distinct vProjectRecord;
    else
      vResult  := ID_TABLE_TYPE();
    end if;

    return vResult;
  exception
    when no_data_found then
      return ID_TABLE_TYPE();
  end GetProjectOrderRecord;

     /**
  * procédure Planification_Lot_Prop
  * Description : Planification d'une proposition de fabrication avec MAJ des champs
  *
  * @created ECA
  * @lastUpdate Lse Intégration pkg_GAL_POX_GENERATE
  * @public
  * @param   PrmFAL_LOT_PROP_ID : Proposition de fabrication
  * @param   DatePlanification : Date de départ de la planification
  * @param   SelonDateDebut : Planif date début ou date fin
  * @param   MAJReqLiensComposantsLot : MAJ des composants.
  * @param   MAJ_Reseaux_Requise : MAJ des réseaux
  */
  procedure Planification_Lot_Prop(
    PrmFAL_LOT_PROP_ID        number
  , DatePlanification         date
  , SelonDateDebut            integer
  , MAJReqLiensComposantsProp integer
  , MAJ_Reseaux_Requise       integer
  )
  is
  begin
    FAL_PLANIF.Planification_Lot_Prop(PrmFAL_LOT_PROP_ID, DatePlanification, SelonDateDebut, MAJReqLiensComposantsProp, MAJ_Reseaux_Requise);
  end Planification_Lot_Prop;

  function GetProjectRecord_Table(aRecordId in DOC_RECORD.DOC_RECORD_ID%type, aTblRecordId ID_TABLE_TYPE default null, aExcludeList ID_TABLE_TYPE default null)
    return ID_TABLE_TYPE pipelined
  is
    lTemp ID_TABLE_TYPE;
  begin
    lTemp  := gal_functions.GetProjectRecord(aRecordId, aTblRecordId, aExcludeList);

    if lTemp.count > 0 then
      for i in lTemp.first .. lTemp.last loop
        pipe row(lTemp(i) );
      end loop;
    end if;
  end GetProjectRecord_Table;

  function GetOrderRecord_Table(aRecordId in DOC_RECORD.DOC_RECORD_ID%type, aTblRecordId ID_TABLE_TYPE default null, aExcludeList ID_TABLE_TYPE default null)
    return ID_TABLE_TYPE pipelined
  is
    lTemp ID_TABLE_TYPE;
  begin
    lTemp  := gal_functions.GetOrderRecord(aRecordId, aTblRecordId, aExcludeList);

    if lTemp.count > 0 then
      for i in lTemp.first .. lTemp.last loop
        pipe row(lTemp(i) );
      end loop;
    end if;
  end GetOrderRecord_Table;

  function GetProjectOrderRecord_Table(
    aRecordId    in DOC_RECORD.DOC_RECORD_ID%type
  , aTblRecordId    ID_TABLE_TYPE default null
  , aExcludeList    ID_TABLE_TYPE default null
  )
    return ID_TABLE_TYPE pipelined
  is
    lTemp ID_TABLE_TYPE;
  begin
    lTemp  := gal_functions.GetProjectOrderRecord(aRecordId, aTblRecordId, aExcludeList);

    if lTemp.count > 0 then
      for i in lTemp.first .. lTemp.last loop
        pipe row(lTemp(i) );
      end loop;
    end if;
  end GetProjectOrderRecord_Table;

  procedure Group_Order_Project(a_acr_cash_flow_analysis_id ACR_CASH_FLOW_IMPUTATION.acr_cash_flow_imputation_id%type)
  is
  begin
    update gal_group_project_order grp
       set gal_project_record_id =
             (case (select c_rco_type
                      from doc_record rco
                     where rco.doc_record_id = grp.doc_record_id)
                when '01' then doc_record_id
                when '04' then (select prj.doc_record_id
                                  from gal_project prj
                                     , gal_budget bdg
                                 where prj.gal_project_id = bdg.gal_project_id
                                   and bdg.doc_record_id = grp.doc_record_id)
                when '03' then (select prj.doc_record_id
                                  from gal_project prj
                                     , gal_task tsk
                                 where prj.gal_project_id = tsk.gal_project_id
                                   and tsk.doc_record_id = grp.doc_record_id)
                when '02' then (select prj.doc_record_id
                                  from gal_project prj
                                     , gal_task tsk
                                 where prj.gal_project_id = tsk.gal_project_id
                                   and tsk.doc_record_id = grp.doc_record_id)
                when '05' then (select prj.doc_record_id
                                  from gal_project prj
                                     , gal_task tsk
                                     , gal_task_link lnk
                                 where prj.gal_project_id = tsk.gal_project_id
                                   and lnk.doc_record_id = grp.doc_record_id
                                   and lnk.gal_task_id = tsk.gal_task_id)
                else null
              end
             )
     where acr_cash_flow_analysis_id = a_acr_cash_flow_analysis_id;

    for s_search in (select distinct gal_project_record_id
                                from gal_group_project_order
                               where gal_project_record_id is not null
                                 and acr_cash_flow_analysis_id = a_acr_cash_flow_analysis_id) loop
      update gal_group_project_order
         set ORDER_GROUP =
                      (select TableToCharListClob(cursor(select substr(rco_title, 4)
                                                           from table(gal_functions.GetorderRecord_Table(s_search.gal_project_record_id) )
                                                              , doc_record rco
                                                          where column_value = rco.doc_record_id), ';')
                         from dual)
       where gal_project_record_id = s_search.gal_project_record_id;
    end loop;
  end Group_Order_Project;

  procedure Grp_Order_Project_In_ACR_Cash(a_acr_cash_flow_analysis_id ACR_CASH_FLOW_IMPUTATION.acr_cash_flow_imputation_id%type)
  is
    vSalePrice       number;
    vDmtNumber       DOC_DOCUMENT.DMT_NUMBER%type;
    vPacThirdId      DOC_DOCUMENT.PAC_THIRD_ID%type;
    vDmtDateDocument DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    vPdeFinalDelay   DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
  begin
    insert into gal_group_project_order
                (doc_record_id
                )
      (select distinct doc_record_id
                  from acr_cash_flow_imputation
                 where acr_cash_flow_analysis_id = a_acr_cash_flow_analysis_id
                   and doc_record_id is not null);

    update gal_group_project_order
       set acr_cash_flow_analysis_id = a_acr_cash_flow_analysis_id
     where acr_cash_flow_analysis_id is null;

    Group_Order_Project(a_acr_cash_flow_analysis_id);

    update gal_group_project_order
       set gal_project_id = (select gal_project_id
                               from gal_project prj
                              where prj.doc_record_id = gal_project_record_id)
     where acr_cash_flow_analysis_id = a_acr_cash_flow_analysis_id;

    for s_search in (select distinct gal_project_id
                                from gal_group_project_order
                               where gal_project_id is not null
                                 and acr_cash_flow_analysis_id = a_acr_cash_flow_analysis_id) loop
      GAL_PRJ_FUNCTIONS.Get_Balance_Order_information(s_search.gal_project_id, null, vSalePrice, vDmtNumber, vPacThirdId, vDmtDateDocument, vPdeFinalDelay);

      update gal_group_project_order
         set dmt_number = vDmtNumber
           , doc_document_id = (select doc_document_id
                                  from doc_document doc
                                 where dmt_number = vDmtNumber)
       where gal_project_id = s_search.gal_project_id
         and acr_cash_flow_analysis_id = a_acr_cash_flow_analysis_id;
    end loop;
  end Grp_Order_Project_In_ACR_Cash;
end GAL_FUNCTIONS;
