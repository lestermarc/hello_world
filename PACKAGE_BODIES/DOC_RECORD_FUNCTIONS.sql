--------------------------------------------------------
--  DDL for Package Body DOC_RECORD_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_RECORD_FUNCTIONS" 
is
  /**
  * Description
  *   Création ou mise à jour d'un dossier à partir du module Affaire
  */
  procedure UpdateRecordProject(
    aProjectID   in GAL_PROJECT.GAL_PROJECT_ID%type
  , aTaskID      in GAL_TASK.GAL_TASK_ID%type
  , aBudgetID    in GAL_BUDGET.GAL_BUDGET_ID%type
  , aTaskLinkID  in GAL_TASK_LINK.GAL_TASK_LINK_ID%type
  , aThirdID     in PAC_THIRD.PAC_THIRD_ID%type
  , aType        in DOC_RECORD.C_RCO_TYPE%type
  , aStatus      in DOC_RECORD.C_RCO_STATUS%type
  , aTitle       in DOC_RECORD.RCO_TITLE%type
  , aDescription in DOC_RECORD.RCO_DESCRIPTION%type
  , aAlphaShort1 in DOC_RECORD.RCO_ALPHA_SHORT1%type
  , aAlphaShort2 in DOC_RECORD.RCO_ALPHA_SHORT2%type
  , aAlphaLong1  in DOC_RECORD.RCO_ALPHA_LONG1%type
  , aAlphaLong2  in DOC_RECORD.RCO_ALPHA_LONG2%type
  , aBudCatID    in GAL_BUDGET.GAL_BUDGET_CATEGORY_ID%type
  )
  is
    docRecordID               DOC_RECORD.DOC_RECORD_ID%type;
    docRecordLinkID           DOC_RECORD_LINK.DOC_RECORD_LINK_ID%type;
    cRcoType                  DOC_RECORD_CATEGORY.C_RCO_TYPE%type;
    cRcoStatus                DOC_RECORD_CATEGORY.C_RCO_STATUS%type;
    docRecordCategoryID       DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
    docRecordCategoryLinkID   DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type;
    galSupplyTaskID           GAL_TASK.GAL_TASK_ID%type;
    galLaborTaskID            GAL_TASK.GAL_TASK_ID%type;
    galProjectID              GAL_PROJECT.GAL_PROJECT_ID%type;
    vAcs_financial_account_id gal_budget_category.acs_financial_account_id%type;
    vAcs_division_account_id  gal_budget_category.acs_division_account_id%type;
    vAcs_cpn_account_id       gal_budget_category.acs_cpn_account_id%type;
    vAcs_cda_account_id       gal_budget_category.acs_cda_account_id%type;
    vAcs_pf_account_id        gal_budget_category.acs_pf_account_id%type;
    vAcs_pj_account_id        gal_budget_category.acs_pj_account_id%type;
  begin
    galProjectID  := null;

    if (   aProjectID is not null
        or aTaskID is not null
        or aTaskLinkID is not null
        or aBudgetID is not null) then
      begin
        if aTaskID is not null then
          if    aType = '2'
             or aType = '02' then
            galSupplyTaskID  := aTaskID;
            galLaborTaskID   := null;
          else
            galSupplyTaskID  := null;
            galLaborTaskID   := aTaskID;
          end if;

          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_TASK_ID = aTaskID;
        elsif aBudgetID is not null then
          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_BUDGET_ID = aBudgetID;
        elsif aTaskLinkID is not null then
          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_TASK_LINK_ID = aTaskLinkID;
        elsif aProjectID is not null then
          galProjectID  := aProjectID;

          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_PROJECT_ID = aProjectID;
        end if;
      exception
        when no_data_found then
          docRecordID  := null;
      end;

      -- Recherche une catégorie de dossier ainsi que le lien de catégorie à partir du module Affaire
      DOC_RECORD_CATEGORY_FUNCTIONS.GetRecordCategProject(aProjectID
                                                        , galSupplyTaskID
                                                        , galLaborTaskID
                                                        , aBudgetID
                                                        , aTaskLinkID
                                                        , docRecordCategoryID
                                                        , docRecordCategoryLinkID
                                                         );

      if docRecordCategoryID is not null then
        -- Recherche les informations de création du dossier en fonction de la catégorie de dossier
        select C_RCO_TYPE
             , C_RCO_STATUS
          into cRcoType
             , cRcoStatus
          from DOC_RECORD_CATEGORY
         where DOC_RECORD_CATEGORY_ID = docRecordCategoryID;

        select min(ACS_FINANCIAL_ACCOUNT_ID)
             , min(ACS_DIVISION_ACCOUNT_ID)
             , min(ACS_CPN_ACCOUNT_ID)
             , min(ACS_CDA_ACCOUNT_ID)
             , min(ACS_PF_ACCOUNT_ID)
             , min(ACS_PJ_ACCOUNT_ID)
          into vAcs_financial_account_id
             , vAcs_division_account_id
             , vAcs_cpn_account_id
             , vAcs_cda_account_id
             , vAcs_pf_account_id
             , vAcs_pj_account_id
          from GAL_BUDGET_CATEGORY
         where GAL_BUDGET_CATEGORY_ID = aBudCatID;

        if docRecordID is null then
          select INIT_ID_SEQ.nextval
            into docRecordID
            from dual;

          insert into DOC_RECORD
                      (DOC_RECORD_ID
                     , DOC_RECORD_CATEGORY_ID
                     , PAC_THIRD_ID
                     , RCO_TITLE
                     , RCO_NUMBER
                     , RCO_DESCRIPTION
                     , RCO_ALPHA_SHORT1
                     , RCO_ALPHA_SHORT2
                     , RCO_ALPHA_LONG1
                     , RCO_ALPHA_LONG2
                     , GAL_TASK_ID
                     , GAL_PROJECT_ID
                     , GAL_BUDGET_ID
                     , GAL_TASK_LINK_ID
                     , C_RCO_STATUS
                     , C_RCO_TYPE
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_DIVISION_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_id
                     , ACS_CDA_ACCOUNT_id
                     , ACS_PF_ACCOUNT_id
                     , ACS_PJ_ACCOUNT_id
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (docRecordID   -- DOC_RECORD_ID
                     , docRecordCategoryID   -- DOC_RECORD_CATEGORY_ID
                     , aThirdID   -- PAC_THIRD_ID
                     , aTitle   -- RCO_TITLE
                     , RCO_NUMBER_SEQ.nextval   -- RCO_NUMBER
                     , aDescription   -- RCO_DESCRIPTION
                     , aAlphaShort1   -- RCO_ALPHA_SHORT1
                     , aAlphaShort2   -- RCO_ALPHA_SHORT2
                     , aAlphaLong1   -- RCO_ALPHA_LONG1
                     , aAlphaLong2   -- RCO_ALPHA_LONG2
                     , aTaskID   -- GAL_TASK_ID
                     , galProjectID   -- GAL_PROJECT_ID
                     , aBudgetID   -- GAL_BUDGET_ID
                     , aTaskLinkID
                     , nvl(aStatus, cRcoStatus)   -- C_RCO_STATUS
                     , cRcoType   -- C_RCO_TYPE
                     , vAcs_financial_account_id
                     , vAcs_division_account_id
                     , vAcs_cpn_account_id
                     , vAcs_cda_account_id
                     , vAcs_pf_account_id
                     , vAcs_pj_account_id
                     , sysdate   -- A_DATECRE
                     , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                      );
        else
          update DOC_RECORD
             set DOC_RECORD_CATEGORY_ID = docRecordCategoryID
               , PAC_THIRD_ID = nvl(aThirdID, PAC_THIRD_ID)
               , RCO_TITLE = nvl(aTitle, RCO_TITLE)
               , RCO_DESCRIPTION = nvl(aDescription, RCO_DESCRIPTION)
               , RCO_ALPHA_SHORT1 = nvl(aAlphaShort1, RCO_ALPHA_SHORT1)
               , RCO_ALPHA_SHORT2 = nvl(aAlphaShort2, RCO_ALPHA_SHORT2)
               , RCO_ALPHA_LONG1 = nvl(aAlphaLong1, RCO_ALPHA_LONG1)
               , RCO_ALPHA_LONG2 = nvl(aAlphaLong2, RCO_ALPHA_LONG2)
               , C_RCO_STATUS = nvl(aStatus, C_RCO_STATUS)
               , C_RCO_TYPE = nvl(cRcoType, C_RCO_TYPE)
               , ACS_FINANCIAL_ACCOUNT_ID = vAcs_financial_account_id
               , ACS_DIVISION_ACCOUNT_ID = vAcs_division_account_id
               , ACS_CPN_ACCOUNT_id = vAcs_cpn_account_id
               , ACS_CDA_ACCOUNT_id = vAcs_cda_account_id
               , ACS_PF_ACCOUNT_id = vAcs_pf_account_id
               , ACS_PJ_ACCOUNT_id = vAcs_pj_account_id
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_RECORD_ID = docRecordID;
        end if;

        -- Création du lien entre le dossier affaire et les dossiers de type tâche d'approvisionnement, tâche de
        -- main d'oeuvre et code budget.
        if     docRecordID is not null
           and docRecordCategoryLinkID is not null
           and cRcoType <> '01' then
          docRecordLinkID  :=
                             UpdateRecordLinkProject(aProjectID, galSupplyTaskID, galLaborTaskID, aBudgetID, aTaskLinkID, docRecordID, docRecordCategoryLinkID);
        end if;
      end if;
    end if;
  end UpdateRecordProject;

  /**
  * Description
  *   Création du lien entre le dossier affaire et les dossiers de type tâche d'approvisionnement, tâche de
  *   main d'oeuvre et code budget.
  */
  function UpdateRecordLinkProject(
    aProjectID            in GAL_PROJECT.GAL_PROJECT_ID%type
  , aSupplyTaskID         in GAL_TASK.GAL_TASK_ID%type
  , aLaborTaskID          in GAL_TASK.GAL_TASK_ID%type
  , aBudgetID             in GAL_BUDGET.GAL_BUDGET_ID%type
  , aTaskLinkID           in GAL_TASK_LINK.GAL_TASK_LINK_ID%type
  , aRecordID             in DOC_RECORD.DOC_RECORD_ID%type
  , aRecordCategoryLinkID in DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type
  )
    return DOC_RECORD_LINK.DOC_RECORD_LINK_ID%type
  is
    docRecordFatherID DOC_RECORD.DOC_RECORD_ID%type;
    docRecordLinkID   DOC_RECORD_LINK.DOC_RECORD_LINK_ID%type;
  begin
    if     aRecordCategoryLinkID is not null
       and (   aProjectID is not null
            or aSupplyTaskID is not null
            or aLaborTaskID is not null
            or aTaskLinkID is not null
            or aBudgetID is not null) then
      begin
        if aSupplyTaskID is not null then
          select RCO_FATHER.DOC_RECORD_ID
            into docRecordFatherID
            from DOC_RECORD RCO_FATHER
           where RCO_FATHER.GAL_PROJECT_ID = aProjectID;
        elsif aLaborTaskID is not null then
          select RCO_FATHER.DOC_RECORD_ID
            into docRecordFatherID
            from DOC_RECORD RCO_FATHER
           where RCO_FATHER.GAL_PROJECT_ID = aProjectID;
        elsif aBudgetID is not null then
          select RCO_FATHER.DOC_RECORD_ID
            into docRecordFatherID
            from DOC_RECORD RCO_FATHER
           where RCO_FATHER.GAL_PROJECT_ID = aProjectID;
        elsif aTaskLinkID is not null then
          /*
          v_aProjectID := null;
          for i in 1 .. gal_gtl_aiu_doc_record.gtl_index
              loop
                if gal_gtl_aiu_doc_record.table_rowid_task_link(i).new_gal_task_link_id = aTaskLinkID
          then v_aProjectID := gal_gtl_aiu_doc_record.table_rowid_task_link(i).new_gal_task_id;
          end if;
              end loop;
              select RCO_FATHER.DOC_RECORD_ID
               into docRecordFatherID
               from DOC_RECORD RCO_FATHER
              where RCO_FATHER.GAL_TASK_ID = v_aProjectID;
          */
          select RCO_FATHER.DOC_RECORD_ID
            into docRecordFatherID
            from DOC_RECORD RCO_FATHER
           where RCO_FATHER.GAL_PROJECT_ID = aProjectID;
        elsif aProjectID is not null then
          docRecordFatherID  := null;
        end if;
      exception
        when no_data_found then
          docRecordFatherID  := null;
      end;

      if docRecordFatherID is not null then
        -- Recherche les informations de création du lien dossier en fonction du dossier père et du dossier fils
        begin
          select DOC_RECORD_LINK_ID
            into docRecordLinkID
            from DOC_RECORD_LINK
           where DOC_RECORD_FATHER_ID = docRecordFatherID
             and DOC_RECORD_SON_ID = aRecordID;
        exception
          when no_data_found then
            docRecordLinkID  := null;
        end;

        if docRecordLinkID is null then
          select INIT_ID_SEQ.nextval
            into docRecordLinkID
            from dual;

          insert into DOC_RECORD_LINK
                      (DOC_RECORD_LINK_ID
                     , DOC_RECORD_CATEGORY_LINK_ID
                     , DOC_RECORD_FATHER_ID
                     , DOC_RECORD_SON_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (docRecordlinkID   -- DOC_RECORD_LINK_ID
                     , aRecordCategoryLinkID   -- DOC_RECORD_CATEGORY_LINK_ID
                     , docRecordFatherID   -- DOC_RECORD_FATHER_ID
                     , aRecordID   -- DOC_RECORD_SON_ID
                     , sysdate   -- A_DATECRE
                     , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                      );
        else
          update DOC_RECORD_LINK
             set DOC_RECORD_CATEGORY_LINK_ID = aRecordCategoryLinkID
               , DOC_RECORD_FATHER_ID = docRecordFatherID
               , DOC_RECORD_SON_ID = aRecordID
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_RECORD_LINK_ID = docRecordLinkID;
        end if;
      end if;
    end if;

    return docRecordLinkID;
  end UpdateRecordLinkProject;

  /**
  * Description
  *   Suppression d'un dossier à partir du module Affaire
  */
  procedure DeleteRecordProject(
    aProjectID  in GAL_PROJECT.GAL_PROJECT_ID%type
  , aTaskID     in GAL_TASK.GAL_TASK_ID%type
  , aBudgetID   in GAL_BUDGET.GAL_BUDGET_ID%type
  , aTaskLinkId in GAL_TASK_LINK.GAL_TASK_LINK_ID%type
  )
  is
    docRecordID DOC_RECORD.DOC_RECORD_ID%type;
  begin
    if (   aProjectID is not null
        or aTaskID is not null
        or aTaskLinkId is not null
        or aBudgetID is not null) then
      begin
        if aTaskID is not null then
          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_TASK_ID = aTaskID;
        elsif aBudgetID is not null then
          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_BUDGET_ID = aBudgetID;
        elsif aTaskLinkId is not null then
          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_TASK_LINK_ID = aTaskLinkId;
        elsif aProjectID is not null then
          select DOC_RECORD_ID
            into docRecordID
            from DOC_RECORD
           where GAL_PROJECT_ID = aProjectID;
        end if;
      exception
        when no_data_found then
          docRecordID  := null;
      end;

      -- Suppression du lien entre le dossier père et le dossier spécifié et suppression du dossier spécifié.
      if docRecordID is not null then
        begin
          DeleteRecord(docRecordID);
        exception
          when others then
            null;
        end;
      end if;
    end if;
  end DeleteRecordProject;

  /**
  * Description
  *   Suppression du lien entre le dossier père et le dossier spécifié et suppression du dossier spécifié.
  */
  procedure DeleteRecord(aRecordID in DOC_RECORD.DOC_RECORD_ID%type)
  is
  begin
    if aRecordID is not null then
      -- Effacement du lien père fils entre le dossier fils transmis et le dossier père
      delete from DOC_RECORD_LINK
            where DOC_RECORD_SON_ID = aRecordID;

      -- Supprime le dossier spécifié
      delete from DOC_RECORD
            where DOC_RECORD_ID = aRecordID;
    end if;
  end DeleteRecord;

  /**
  * Description
  *   Création d'une machine à partir d'une position
  */
  procedure CreateRecordMachine(
    aGoodID                 in     GCO_GOOD.GCO_GOOD_ID%type
  , aAdminDomain            in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aDicComplementaryDataID in     GCO_COMPL_DATA_EXTERNAL_ASA.DIC_COMPLEMENTARY_DATA_ID%type
  , aMachineLongDescr       in     DOC_RECORD.RCO_MACHINE_LONG_DESCR%type
  , aMachineFreeDescr       in     DOC_RECORD.RCO_MACHINE_FREE_DESCR%type
  , aSalePrice              in     DOC_RECORD.RCO_SALE_PRICE%type
  , aCostPrice              in     DOC_RECORD.RCO_COST_PRICE%type
  , aRecordMachineID        out    DOC_RECORD.DOC_RECORD_ID%type
  , aOrigin                 in     DOC_RECORD.C_RCO_ORIGIN%type default null
  )
  is
    docRecordID               DOC_RECORD.DOC_RECORD_ID%type;
    gcoComplDataExternalAsaID GCO_COMPL_DATA_EXTERNAL_ASA.GCO_COMPL_DATA_EXTERNAL_ASA_ID%type;
    docRecordCategoryID       DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
    cRcoStatus                DOC_RECORD_CATEGORY.C_RCO_STATUS%type;
    bNextSearch               boolean;
    checkIn                   number;
  begin
    bNextSearch       := true;

    -- Vérifie l'existence d'une donnée complémentaire de SAV externe en fonction du code donnée complémentaire
    if aDicComplementaryDataID is not null then
      begin
        select CEA.GCO_COMPL_DATA_EXTERNAL_ASA_ID
             , CEA.DOC_RECORD_CATEGORY_ID
             , RCY.C_RCO_STATUS
          into gcoComplDataExternalAsaID
             , docRecordCategoryID
             , cRcoStatus
          from GCO_COMPL_DATA_EXTERNAL_ASA CEA
             , DOC_RECORD_CATEGORY RCY
         where CEA.GCO_GOOD_ID = aGoodID
           and RCY.DOC_RECORD_CATEGORY_ID = CEA.DOC_RECORD_CATEGORY_ID
           and CEA.DIC_COMPLEMENTARY_DATA_ID = aDicComplementaryDataID;

        bNextSearch  := false;
      exception
        when no_data_found then
          gcoComplDataExternalAsaID  := null;
          docRecordCategoryID        := null;
          docRecordID                := null;
      end;
    end if;

    if bNextSearch then
      begin
        select CEA.GCO_COMPL_DATA_EXTERNAL_ASA_ID
             , CEA.DOC_RECORD_CATEGORY_ID
             , RCY.C_RCO_STATUS
          into gcoComplDataExternalAsaID
             , docRecordCategoryID
             , cRcoStatus
          from GCO_COMPL_DATA_EXTERNAL_ASA CEA
             , DOC_RECORD_CATEGORY RCY
         where CEA.GCO_GOOD_ID = aGoodID
           and RCY.DOC_RECORD_CATEGORY_ID = CEA.DOC_RECORD_CATEGORY_ID
           and CEA.DIC_COMPLEMENTARY_DATA_ID is null;
      exception
        when no_data_found then
          gcoComplDataExternalAsaID  := null;
          docRecordCategoryID        := null;
          docRecordID                := null;
      end;
    end if;

    -- Création de la machine
    if     gcoComplDataExternalAsaID is not null
       and docRecordCategoryID is not null then
      select INIT_ID_SEQ.nextval
        into docRecordID
        from dual;

      -- Le prix de vente de l'installation doit être initialisé uniquement si le gabarit est du domaine des ventes
      insert into DOC_RECORD
                  (DOC_RECORD_ID
                 , DOC_RECORD_CATEGORY_ID
                 , RCO_MACHINE_GOOD_ID
                 , RCO_MACHINE_LONG_DESCR
                 , RCO_MACHINE_FREE_DESCR
                 , RCO_NUMBER
                 , C_RCO_STATUS
                 , C_RCO_TYPE
                 , C_RCO_ORIGIN
                 , RCO_SALE_PRICE
                 , RCO_COST_PRICE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (docRecordID   -- DOC_RECORD_ID
                 , docRecordCategoryID   -- DOC_RECORD_CATEGORY_ID
                 , aGoodID   -- RCO_MACHINE_GOOD_ID
                 , aMachineLongDescr   -- RCO_MACHINE_LONG_DESCR
                 , aMachineFreeDescr   -- RCO_MACHINE_FREE_DESCR
                 , RCO_NUMBER_SEQ.nextval   -- RCO_NUMBER
                 , cRcoStatus   -- C_RCO_STATUS
                 , '11'   -- C_RCO_TYPE
                 , aOrigin   -- C_RCO_ORIGIN
                 , case
                     when aAdminDomain = '2' then aSalePrice
                     else null
                   end
                 , aCostPrice   -- RCO_COST_PRICE
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );

      -- Les compteurs associés à la nouvelle machine sont créés par trigger

      -- suivi des modifications
      select nvl(max(SLO_ACTIVE), 0)
        into checkIn
        from PCS.PC_SYS_LOG
       where C_LTM_SYS_LOG = '05'
         and PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

      if CheckIn = 1 then
        checkIn  :=
          LTM_TRACK.CheckIn(docRecordID
                          , '05'
                          , pcs.PC_FUNCTIONS.TranslateWord('Dossier créé automatiquement (Gestion des documents)', pcs.PC_I_LIB_SESSION.GetCompLangId)
                           );
      end if;
    end if;

    aRecordMachineID  := docRecordID;
  end CreateRecordMachine;

  /**
  * Description
  *   Mise à jour des données d'achat (onglet fournisseur) des
  *   installations (anciennement machines) du document
  */
  procedure UpdateRecordMachines(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDateDocument in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type)
  is
    cursor crInstallations(cDocumentID number)
    is
      select PDE.DOC_RECORD_ID
           , POS.PAC_THIRD_ID
           , POS.GCO_GOOD_ID
           , POS.DOC_POSITION_ID
           , GAS.C_GAUGE_TITLE
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
           , DOC_RECORD RCO
       where GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and GAU.C_ADMIN_DOMAIN = '1'
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAS.GAS_INSTALLATION_MGM = 1
         and ',' || GAS.C_GAUGE_TITLE || ',' in(',3,', ',4,')
         and POS.DOC_DOCUMENT_ID = cDocumentID
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and RCO.DOC_RECORD_ID = PDE.DOC_RECORD_ID;

    cursor crComplDataPurchase(cGoodID number, cThirdID number)
    is
      select   rpad(decode(CPU.PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(CPU.PAC_SUPPLIER_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , CPU.GCO_COMPL_DATA_PURCHASE_ID
             , CPU.CPU_WARRANTY_PERIOD
             , CPU.C_ASA_GUARANTY_UNIT
             , CPU.CPU_GUARANTY_PC_APPLTXT_ID
          from GCO_COMPL_DATA_PURCHASE CPU
         where CPU.GCO_GOOD_ID = cGoodId
           and CPU.DIC_COMPLEMENTARY_DATA_ID is null
           and (   CPU.PAC_SUPPLIER_PARTNER_ID = cThirdID
                or CPU.PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(CPU.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(CPU.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CPU.GCO_COMPL_DATA_PURCHASE_ID
             , CPU.CPU_WARRANTY_PERIOD
             , CPU.C_ASA_GUARANTY_UNIT
             , CPU.CPU_GUARANTY_PC_APPLTXT_ID
          from GCO_COMPL_DATA_PURCHASE CPU
             , PAC_SUPPLIER_PARTNER SUP
         where CPU.GCO_GOOD_ID = cGoodID
           and CPU.PAC_SUPPLIER_PARTNER_ID is null
           and CPU.DIC_COMPLEMENTARY_DATA_ID = SUP.DIC_COMPLEMENTARY_DATA_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = cThirdID
      order by 1
             , 2;

    tplComplDataPurchase crComplDataPurchase%rowtype;
  begin
    for tplInstallation in crInstallations(aDocumentID) loop
      if tplInstallation.C_GAUGE_TITLE = '3' then
        -- Mise à jour uniquement du fournisseur si le document est un Bulletin Fournisseur Stock
        update DOC_RECORD
           set PAC_THIRD_ID = nvl(PAC_THIRD_ID, tplInstallation.PAC_THIRD_ID)
             , C_RCO_STATUS = '0'   -- Actif
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_RECORD_ID = tplInstallation.DOC_RECORD_ID;
      else
        -- Recherche les informations de mise à jour des données d'achat de l'installation
        -- dans les données complémentaires d'achat du bien (modèle).
        open crComplDataPurchase(tplInstallation.GCO_GOOD_ID, tplInstallation.PAC_THIRD_ID);

        -- C_GAUGE_TITLE = '4' : le document est une Facture Fournisseur
        -- Recherche des données complémentaires
        fetch crComplDataPurchase
         into tplComplDataPurchase;

        if crComplDataPurchase%found then
          -- Si des données complémentaires ont été trouvées, on met à jour
          -- l'installation
          update DOC_RECORD
             set PAC_THIRD_ID = nvl(PAC_THIRD_ID, tplInstallation.PAC_THIRD_ID)
               , DOC_PURCHASE_POSITION_ID = nvl(DOC_PURCHASE_POSITION_ID, tplInstallation.DOC_POSITION_ID)
               , C_RCO_STATUS = '0'   -- Actif
               , RCO_SUPPLIER_WARRANTY_START = nvl(RCO_SUPPLIER_WARRANTY_START, aDateDocument)
               , RCO_SUPPLIER_WARRANTY_TERM = nvl(RCO_SUPPLIER_WARRANTY_TERM, tplComplDataPurchase.CPU_WARRANTY_PERIOD)
               , C_ASA_GUARANTY_UNIT = nvl(C_ASA_GUARANTY_UNIT, tplComplDataPurchase.C_ASA_GUARANTY_UNIT)
               , RCO_SUPPLIER_WARRANTY_END =
                   nvl(RCO_SUPPLIER_WARRANTY_END
                     , decode(nvl(C_ASA_GUARANTY_UNIT, tplComplDataPurchase.C_ASA_GUARANTY_UNIT)
                            , 'D', nvl(RCO_SUPPLIER_WARRANTY_START, aDateDocument) + nvl(RCO_SUPPLIER_WARRANTY_TERM, tplComplDataPurchase.CPU_WARRANTY_PERIOD)
                            , 'M', add_months(nvl(RCO_SUPPLIER_WARRANTY_START, aDateDocument)
                                            , nvl(RCO_SUPPLIER_WARRANTY_TERM, tplComplDataPurchase.CPU_WARRANTY_PERIOD)
                                             )
                            , 'W', nvl(RCO_SUPPLIER_WARRANTY_START, aDateDocument)
                               +(7 * nvl(RCO_SUPPLIER_WARRANTY_TERM, tplComplDataPurchase.CPU_WARRANTY_PERIOD) )
                            , 'Y', add_months(nvl(RCO_SUPPLIER_WARRANTY_START, aDateDocument)
                                            , 12 * nvl(RCO_SUPPLIER_WARRANTY_TERM, tplComplDataPurchase.CPU_WARRANTY_PERIOD)
                                             )
                            , RCO_SUPPLIER_WARRANTY_END
                             )
                      )
               , RCO_WARRANTY_PC_APPLTXT_ID = nvl(RCO_WARRANTY_PC_APPLTXT_ID, tplComplDataPurchase.CPU_GUARANTY_PC_APPLTXT_ID)
               , RCO_WARRANTY_TEXT =
                   nvl(RCO_WARRANTY_TEXT
                     , PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(nvl(RCO_WARRANTY_PC_APPLTXT_ID, tplComplDataPurchase.CPU_GUARANTY_PC_APPLTXT_ID)
                                                           , PCS.PC_I_LIB_SESSION.GetCompLangId
                                                            )
                      )
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_RECORD_ID = tplInstallation.DOC_RECORD_ID;
        else
          -- Aucune donnée complémentaire n'a été trouvée, donc on met à jour
          -- l'installation avec uniquement les données liées au document
          update DOC_RECORD
             set PAC_THIRD_ID = nvl(PAC_THIRD_ID, tplInstallation.PAC_THIRD_ID)
               , DOC_PURCHASE_POSITION_ID = nvl(DOC_PURCHASE_POSITION_ID, tplInstallation.DOC_POSITION_ID)
               , C_RCO_STATUS = '0'   -- Actif
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_RECORD_ID = tplInstallation.DOC_RECORD_ID;
        end if;

        close crComplDataPurchase;
      end if;
    end loop;
  end UpdateRecordMachines;

  /**
  * Description
  *    retourne la date de fin d'une tâche pour les dossiers de type tâche (gestion à l'affaire)
  */
  function getEndTaskDate(aRecordId DOC_RECORD.DOC_RECORD_ID%type)
    return date
  is
    vResult date;
  begin
    select TAS_END_DATE
      into vResult
      from DOC_RECORD RCO
         , GAL_TASK TAS
     where RCO.DOC_RECORD_ID = aRecordId
       and RCO.GAL_TASK_ID = TAS.GAL_TASK_ID;

    return vResult;
  exception
    -- si pas de tâche liée, on retourne null
    when no_data_found then
      return null;
  end getEndTaskDate;

  /**
  * Description
  *    retourne 1 si la tâche liée est soldée
  */
  function isTaskBalanced(aRecordId DOC_RECORD.DOC_RECORD_ID%type)
    return number
  is
    vEndTaskDate date;
  begin
    -- recherche de la date de fin de tâche
    select TAS_END_DATE
      into vEndTaskDate
      from DOC_RECORD RCO
         , GAL_TASK TAS
     where RCO.DOC_RECORD_ID = aRecordId
       and RCO.GAL_TASK_ID = TAS.GAL_TASK_ID;

    if vEndTaskDate is null then
      return 0;
    else
      return 1;
    end if;
  exception
    -- si pas de tâche liée, on retourne null
    when no_data_found then
      return null;
  end isTaskBalanced;

  /**
  * Description
  *    Maj du lien DOC_RECORD_LINK entre une commande et une affaire
  */
  procedure linkProjectRecord(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aRecordId in DOC_RECORD.DOC_RECORD_ID%type, aMode in number)
  is
    vRecordLinkId       DOC_RECORD_LINK.DOC_RECORD_LINK_ID%type;
    vFatherRecordId     DOC_RECORD.DOC_RECORD_Id%type;
    vSonRecordId        DOC_RECORD.DOC_RECORD_Id%type;
    vPosRecordCategType DOC_RECORD_CATEGORY.C_RCO_TYPE%type;
    vCategLinkId        DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type;
    vPosStatus          DOC_POSITION.C_DOC_POS_STATUS%type;
    vCateg01Id          DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
    vCateg09Id          DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
    vLinkCount          DOC_RECORD_LINK.RCL_COUNT%type;
  begin
    -- recherche de l'id de la catégorie '01' Affaire
    begin
      select DOC_RECORD_CATEGORY_ID
        into vCateg01Id
        from DOC_RECORD_CATEGORY
       where C_RCO_TYPE = '01';
    exception
      when no_data_found then
        raise_application_error(-20921
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Pas de catégorie de dossier de type ''01''!') ||
                                chr(13) ||
                                PCS.PC_FUNCTIONS.TranslateWord('Vous devez avoir une et une seule catégorie de dossier de type ''01''.')
                               );
      when too_many_rows then
        raise_application_error(-20922
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Plus d''une catégorie de dossier de type ''01''!') ||
                                chr(13) ||
                                PCS.PC_FUNCTIONS.TranslateWord('Vous devez avoir une et une seule catégorie de dossier de type ''01''.')
                               );
    end;

    -- recherche de l'id de la catégorie '09' Commande
    begin
      select DOC_RECORD_CATEGORY_ID
        into vCateg09Id
        from DOC_RECORD_CATEGORY
       where C_RCO_TYPE = '09';
    exception
      when no_data_found then
        raise_application_error(-20923
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Pas de catégorie de dossier de type ''09''!') ||
                                chr(13) ||
                                PCS.PC_FUNCTIONS.TranslateWord('Vous devez avoir une et une seule catégorie de dossier de type ''09''.')
                               );
      when too_many_rows then
        raise_application_error(-20924
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Plus d''une catégorie de dossier de type ''09''!') ||
                                chr(13) ||
                                PCS.PC_FUNCTIONS.TranslateWord('Vous devez avoir une et une seule catégorie de dossier de type ''09''.')
                               );
    end;

    -- recherche de l'id du dossier correspondant au document affaire
    select max(DOC_RECORD_ID)
      into vFatherRecordId
      from DOC_RECORD
     where DOC_PROJECT_DOCUMENT_ID = aDocumentId;

    if vFatherRecordId is not null then
      -- recherche de la categorie du dossier de la position
      select C_RCO_TYPE
        into vPosRecordCategType
        from DOC_RECORD
       where DOC_RECORD_ID = aRecordId;

      case
        -- Affaire
      when vPosRecordCategType = '01' then
          vSonRecordId  := aRecordId;
        -- Tâches
      when vPosRecordCategType in('02', '03') then
          select PRJ.DOC_RECORD_ID
            into vSonRecordId
            from GAL_TASK TSK
               , GAL_PROJECT PRJ
           where TSK.DOC_RECORD_ID = aRecordId
             and TSK.GAL_PROJECT_ID = PRJ.GAL_PROJECT_ID;
        -- Budget
      when vPosRecordCategType = '04' then
          select PRJ.DOC_RECORD_ID
            into vSonRecordId
            from GAL_BUDGET BUD
               , GAL_PROJECT PRJ
           where BUD.DOC_RECORD_ID = aRecordId
             and BUD.GAL_PROJECT_ID = PRJ.GAL_PROJECT_ID;
        else
          null;
      end case;

      if vSonRecordId is not null then
        -- recherche l'ID du lien entre categories
        vCategLinkId  :=
          DOC_RECORD_CATEGORY_FUNCTIONS.GetRecordCategLinkProject(aDocumentId          => aDocumentId, aRecordCatFather => vCateg09Id
                                                                , aRecordCatDaughter   => vCateg01Id);

        -- recherche si le lien existe déjà dans DOC_RECORD_LINK
        begin   /* DOC_RECORD_LINK */
          select max(DOC_RECORD_LINK_ID)
               , nvl(max(RCL_COUNT), 0)
            into vRecordLinkId
               , vLinkCount
            from DOC_RECORD_LINK
           where DOC_RECORD_FATHER_ID = vFatherRecordId
             and DOC_RECORD_SON_ID = vSonRecordId
             and DOC_RECORD_CATEGORY_LINK_ID = vCategLinkId;

          if aMode = 1 then
            if vRecordLinkId is not null then
              -- incrémentation du compteur de lien
              update DOC_RECORD_LINK
                 set RCL_COUNT = RCL_COUNT + 1
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   , A_DATEMOD = sysdate
               where DOC_RECORD_LINK_ID = vRecordLinkId;
            else
              -- Création du lien
              insert into DOC_RECORD_LINK
                          (DOC_RECORD_LINK_ID
                         , DOC_RECORD_CATEGORY_LINK_ID
                         , DOC_RECORD_FATHER_ID
                         , DOC_RECORD_SON_ID
                         , RCL_COUNT
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (INIT_ID_SEQ.nextval   -- DOC_RECORD_LINK_ID
                         , vCategLinkId   -- DOC_RECORD_CATEGORY_LINK_ID
                         , vFatherRecordId   -- DOC_RECORD_FATHER_ID
                         , vSonRecordId   -- DOC_RECORD_SON_ID
                         , 1
                         , sysdate   -- A_DATECRE
                         , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                          );
            end if;
          elsif aMode = -1 then
            if vLinkCount > 1 then
              -- si plus d'un lien, décrémentation du compteur de liens
              update DOC_RECORD_LINK
                 set RCL_COUNT = RCL_COUNT - 1
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   , A_DATEMOD = sysdate
               where DOC_RECORD_LINK_ID = vRecordLinkId;
            else
              -- suppression du lien
              delete from DOC_RECORD_LINK
                    where DOC_RECORD_LINK_ID = vRecordLinkId;
            end if;
          end if;
        exception
          when no_data_found then
            -- normalement ne devrait jamais arriver
            null;
        end;   /* DOC_RECORD_LINK */
      end if;
    end if;
  end linkProjectRecord;

  /**
  * Description
  *   Maj à jour de l'id du document commande d'affaire dans DOC_RECORD
  */
  procedure updateMissingRecordDocLink
  is
  begin
    for tplRecord in (select rco.doc_record_id
                           , doc_document_id
                           , dmt_number
                        from doc_Record rco
                           , doc_document dmt
                       where rco.c_rco_type = '09'
                         and rco.doc_project_document_id is null
                         and dmt.dmt_number = substr(rco.rco_title, 4) ) loop
      update doc_record
         set doc_project_document_id = tplRecord.doc_document_id
       where doc_record_id = tplRecord.doc_record_id;
    end loop;
  end updateMissingRecordDocLink;

  /**
  * Description
  *    Création des dossier GAL manquants
  */
  procedure createMissingGalRecord
  is
    cursor crBadDocList
    is
      select DMT.DMT_NUMBER
           , DMT.DOC_GAUGE_ID
           , DMT.DOC_RECORD_ID
           , DMT.PAC_THIRD_ID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and checkList(GAU.GAU_DESCRIBE, PCS.PC_CONFIG.getConfig('GAL_GAUGE_BALANCE_ORDER') ) = 1
         and exists(select DOC_RECORD_ID
                      from DOC_RECORD
                     where C_RCO_TYPE = '09'
                       and RCO_TITLE = DMT.DMT_NUMBER);

    cursor crDocList
    is
      select DMT.DMT_NUMBER
           , DMT.DOC_GAUGE_ID
           , DMT.DOC_RECORD_ID
           , DMT.PAC_THIRD_ID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and checkList(GAU.GAU_DESCRIBE, PCS.PC_CONFIG.getConfig('GAL_GAUGE_BALANCE_ORDER') ) = 1
         and not exists(select DOC_RECORD_ID
                          from DOC_RECORD
                         where C_RCO_TYPE = '09'
                           and RCO_TITLE = '09_' || DMT.DMT_NUMBER);

    vBulkLimit constant number                          := 10000;

    type tTblDocList is table of crDocList%rowtype
      index by pls_integer;

    type tTblBadDocList is table of crBadDocList%rowtype
      index by pls_integer;

    vTblDocList         tTblDocList;
    vTblBadDocList      tTblBadDocList;
    vLinkRecord         number(1);
    vNewRecordId        DOC_RECORD.DOC_RECORD_ID%type;
  begin
    if PCS.PC_CONFIG.GetConfig('GAL_MANUFACTURING_MODE') = '1' then
      open crBadDocList;

      fetch crBadDocList
      bulk collect into vTblBadDocList limit vBulkLimit;

      while vTblBadDocList.count > 0 loop
        for i in vTblBadDocList.first .. vTblBadDocList.last loop
          update DOC_RECORD
             set RCO_TITLE = '09_' || RCO_TITLE
           where C_RCO_TYPE = '09'
             and RCO_TITLE = vTblBadDocList(i).DMT_NUMBER;
        end loop;

        commit;

        fetch crBadDocList
        bulk collect into vTblBadDocList limit vBulkLimit;
      end loop;

      close crBadDocList;

      open crDocList;

      fetch crDocList
      bulk collect into vTblDocList limit vBulkLimit;

      while vTblDocList.count > 0 loop
        for i in vTblDocList.first .. vTblDocList.last loop
          DBMS_OUTPUT.PUT_LINE('Set' ||
                               vTblDocList(i).DOC_GAUGE_ID ||
                               'rco ' ||
                               vTblDocList(i).DOC_RECORD_ID ||
                               'dmt ' ||
                               vTblDocList(i).DMT_NUMBER ||
                               'link ' ||
                               vLinkRecord
                              );
          vNewRecordId  :=
            DOC_RECORD_MANAGEMENT.CreateRecord(vTblDocList(i).DOC_GAUGE_ID
                                             , ''
                                             , vTblDocList(i).DOC_RECORD_ID
                                             , vTblDocList(i).PAC_THIRD_ID
                                             , vTblDocList(i).DMT_NUMBER
                                             , vLinkRecord
                                              );
        end loop;

        commit;

        fetch crDocList
        bulk collect into vTblDocList limit vBulkLimit;
      end loop;

      close crDocList;
    end if;
  end createMissingGalRecord;
end DOC_RECORD_FUNCTIONS;
