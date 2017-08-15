--------------------------------------------------------
--  DDL for Package Body FAM_TRANSACTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAM_TRANSACTIONS" 
is
  /**
  * Description
  *    Insertion Imputation comptable
  */
  procedure InsertActImputation(
    pDocumentId     FAM_ACT_IMPUTATION.FAM_DOCUMENT_ID%type
  , pFinAccId       FAM_ACT_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccid       FAM_ACT_IMPUTATION.ACS_DIVISION_ACCOUNT_ID%type
  , pCpnAccId       FAM_ACT_IMPUTATION.ACS_CPN_ACCOUNT_ID%type
  , pCdaAccid       FAM_ACT_IMPUTATION.ACS_CDA_ACCOUNT_ID%type
  , pPfAccId        FAM_ACT_IMPUTATION.ACS_PF_ACCOUNT_ID%type
  , pPjAccId        FAM_ACT_IMPUTATION.ACS_PJ_ACCOUNT_ID%type
  , pImpTyp         FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
  , pImputationId   FAM_ACT_IMPUTATION.FAM_IMPUTATION_ID%type
  , pFinancialImpId FAM_ACT_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , pImpAmountLC    FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  , pImpAmountFC    FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  , pRecordId       FAM_ACT_IMPUTATION.DOC_RECORD_ID%type
  , pPersonId       FAM_ACT_IMPUTATION.PAC_PERSON_ID%type
  , pHrmPersonId    FAM_ACT_IMPUTATION.HRM_PERSON_ID%type
  , pGcoGoodId      FAM_ACT_IMPUTATION.GCO_GOOD_ID%type
  )
  is
    vImputationId FAM_IMPUTATION.FAM_IMPUTATION_ID%type;
  begin
    select init_id_seq.nextval
      into vImputationId
      from dual;

    insert into FAM_ACT_IMPUTATION
                (FAM_ACT_IMPUTATION_ID
               , FAM_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , C_FAM_IMPUTATION_TYP
               , FAM_IMPUTATION_ID
               , FIM_AMOUNT_LC_D
               , FIM_AMOUNT_LC_C
               , FIM_AMOUNT_FC_D
               , FIM_AMOUNT_FC_C
               , A_DATECRE
               , A_IDCRE
               , ACT_FINANCIAL_IMPUTATION_ID
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , PAC_PERSON_ID
               , HRM_PERSON_ID
                )
         values (vImputationId
               , pDocumentId
               , pFinAccId
               , pDivAccid
               , pCpnAccId
               , pCdaAccid
               , pPfAccId
               , pPjAccId
               , pImpTyp
               , pImputationId
               , decode(sign(pImpAmountLC), 1, pImpAmountLC, 0)
               , decode(sign(pImpAmountLC), -1, abs(pImpAmountLC), 0)
               , decode(sign(pImpAmountFC), 1, pImpAmountFC, 0)
               , decode(sign(pImpAmountFC), -1, abs(pImpAmountFC), 0)
               , sysdate
               , UserIni
               , pFinancialImpId
               , pGcoGoodId
               , pRecordId
               , pPersonId
               , pHrmPersonId
                );
  end InsertActImputation;

  /**
  * Recherche des comptes liés au type d'imputation de la valeur géré de l'immo
  **/
  function GetFamAccounts(
    pFixedAssetsId in     FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , pImputationTyp in     FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
  , pManagedValId  in     FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , pFirstCategory in     boolean
  , pSubSets       in out SubSetAccount
  )
    return boolean
  is
    result    boolean                           default false;
    vFinAccId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivAccId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCpnAccId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCdaAccId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPfAccId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPjAccId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;

    /*Vérifie que les comptes gérés soient initialisés*/
    function IntegrityTest(pSubSets in SubSetAccount)
      return boolean
    is
      vResult boolean default false;
    begin
      vResult  :=
           (    pSubSets.ACC.AccountId is not null
            and (   pSubSets.DIV.AccountId is not null
                 or (    pSubSets.DIV.AccountId is null
                     and not pSubSets.DIV.Exist) )
            and (   pSubSets.CPN.AccountId is not null
                 or (    pSubSets.CPN.AccountId is null
                     and not pSubSets.CPN.Exist) )
            and (   pSubSets.CDA.AccountId is not null
                 or (    pSubSets.CDA.AccountId is null
                     and not pSubSets.CDA.Exist) )
            and (   pSubSets.PF.AccountId is not null
                 or (    pSubSets.PF.AccountId is null
                     and not pSubSets.PF.Exist) )
            and (   pSubSets.PJ.AccountId is not null
                 or (    pSubSets.PJ.AccountId is null
                     and not pSubSets.PJ.Exist) )
           )
        or (     (pSubSets.ACC.AccountId is null)
            and (pSubSets.CPN.AccountId is not null)
            and (   pSubSets.CDA.AccountId is not null
                 or (    pSubSets.CDA.AccountId is null
                     and not pSubSets.CDA.Exist) )
            and (   pSubSets.PF.AccountId is not null
                 or (    pSubSets.PF.AccountId is null
                     and not pSubSets.PF.Exist) )
            and (   pSubSets.PJ.AccountId is not null
                 or (    pSubSets.PJ.AccountId is null
                     and not pSubSets.PJ.Exist) )
           );
      return vResult;
    end;
  begin
    /* Recherche dans les comptes mouvementées selon les méthodes de l'immobilisation de la valeur gérée*/
    begin
      select ACC.ACS_FINANCIAL_ACCOUNT_ID
           , ACC.ACS_DIVISION_ACCOUNT_ID
           , ACC.ACS_CPN_ACCOUNT_ID
           , ACC.ACS_CDA_ACCOUNT_ID
           , ACC.ACS_PF_ACCOUNT_ID
           , ACC.ACS_PJ_ACCOUNT_ID
        into vFinAccId
           , vDivAccId
           , vCpnAccId
           , vCdaAccId
           , vPfAccId
           , vPjAccId
        from FAM_IMPUTATION_ACCOUNT ACC
           , FAM_AMO_APPLICATION APP
       where APP.FAM_FIXED_ASSETS_ID = pFixedAssetsId
         and APP.FAM_MANAGED_VALUE_ID = pManagedValId
         and APP.FAM_AMO_APPLICATION_ID = ACC.FAM_AMO_APPLICATION_ID
         and ACC.C_FAM_IMPUTATION_TYP = pImputationTyp;

      /*Mise à jour des propriétés non encore intialisées du record des comptes avec les valeurs des comptes trouvés*/
      if pSubSets.ACC.AccountId is null then
        pSubSets.ACC.AccountId  := vFinAccId;
      end if;

      if pSubSets.DIV.AccountId is null then
        pSubSets.DIV.AccountId  := vDivAccId;
      end if;

      if pSubSets.CPN.AccountId is null then
        pSubSets.CPN.AccountId  := vCpnAccId;
      end if;

      if pSubSets.CDA.AccountId is null then
        pSubSets.CDA.AccountId  := vCdaAccId;
      end if;

      if pSubSets.PF.AccountId is null then
        pSubSets.PF.AccountId  := vPfAccId;
      end if;

      if pSubSets.PJ.AccountId is null then
        pSubSets.PJ.AccountId  := vPjAccId;
      end if;

      /* Tous les comptes gérés sont-ils initialisés ??*/
      result  := IntegrityTest(pSubSets);
    exception
      when others then
        null;
    end;

    /*Il y'a encore des comptes non initialisés => Recherche des comptes sur l'immo même pour autant que */
    /*Ila division ou l'analytique existent et que l'on soit sur la première valeur gérée                */
    if     not result
       and pFirstCategory
       and (   pSubSets.DIV.Exist
            or pSubSets.CPN.Exist) then
      begin
        select ACS_DIVISION_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
          into vDivAccId
             , vCdaAccId
             , vPfAccId
             , vPjAccId
          from FAM_FIXED_ASSETS
         where FAM_FIXED_ASSETS_ID = pFixedAssetsId;

        /*Mise à jour des propriétés non encore intialisées du record des comptes avec les valeurs des comptes trouvés*/
        if pSubSets.DIV.AccountId is null then
          pSubSets.DIV.AccountId  := vDivAccId;
        end if;

        if pSubSets.CDA.AccountId is null then
          pSubSets.CDA.AccountId  := vCdaAccId;
        end if;

        if pSubSets.PF.AccountId is null then
          pSubSets.PF.AccountId  := vPfAccId;
        end if;

        if pSubSets.PJ.AccountId is null then
          pSubSets.PJ.AccountId  := vPjAccId;
        end if;

        /* Tous les comptes gérés sont-ils initialisés ??*/
        result  := IntegrityTest(pSubSets);
      exception
        when others then
          null;
      end;
    end if;

    /*Il y'a encore des comptes non initialisés => Recherche des comptes par défaut de la valeur géré de l'immo*/
    if not result then
      begin
        select ACC.ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACS_DIVISION_ACCOUNT_ID
             , ACC.ACS_CPN_ACCOUNT_ID
             , ACC.ACS_CDA_ACCOUNT_ID
             , ACC.ACS_PF_ACCOUNT_ID
             , ACC.ACS_PJ_ACCOUNT_ID
          into vFinAccId
             , vDivAccId
             , vCpnAccId
             , vCdaAccId
             , vPfAccId
             , vPjAccId
          from FAM_IMPUTATION_ACCOUNT ACC
             , FAM_DEFAULT DEF
             , FAM_FIXED_ASSETS FIX
         where FIX.FAM_FIXED_ASSETS_ID = pFixedAssetsId
           and FIX.FAM_FIXED_ASSETS_CATEG_ID = DEF.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_MANAGED_VALUE_ID = pManagedValId
           and DEF.FAM_DEFAULT_ID = ACC.FAM_DEFAULT_ID
           and ACC.C_FAM_IMPUTATION_TYP = pImputationTyp;

        /*Mise à jour des propriétés non encore intialisées du record des comptes avec les valeurs des comptes trouvés*/
        if pSubSets.ACC.AccountId is null then
          pSubSets.ACC.AccountId  := vFinAccId;
        end if;

        if pSubSets.DIV.AccountId is null then
          pSubSets.DIV.AccountId  := vDivAccId;
        end if;

        if pSubSets.CPN.AccountId is null then
          pSubSets.CPN.AccountId  := vCpnAccId;
        end if;

        if pSubSets.CDA.AccountId is null then
          pSubSets.CDA.AccountId  := vCdaAccId;
        end if;

        if pSubSets.PF.AccountId is null then
          pSubSets.PF.AccountId  := vPfAccId;
        end if;

        if pSubSets.PJ.AccountId is null then
          pSubSets.PJ.AccountId  := vPjAccId;
        end if;

        /* Tous les comptes gérés sont-ils initialisés ??*/
        result  := IntegrityTest(pSubSets);
      exception
        when others then
          null;
      end;
    end if;

    if     (pSubSets.ACC.AccountId is null)
       and (not pSubSets.DIV.AccountId is null)
       and (not pSubSets.CPN.AccountId is null) then
      pSubSets.DIV.AccountId  := null;
    end if;

    result  := IntegrityTest(pSubSets);
    return result;
  end GetFamAccounts;

  procedure InitActImpDatas(
    pFixedAssetsId      in     FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , pImputationTyp      in     FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
  , pIndex              in     binary_integer
  , pTableValImputation in     TableValImputations
  , pManagedSubSets     in out SubSetAccount
  , pTableActImputation in out TableActImputations
  )
  is
    vResult      boolean                               default false;
    vFirstValue  boolean;
    vcpt         binary_integer;
    vPacPersonId FAM_FIXED_ASSETS.PAC_PERSON_ID%type;
    vHrmPersonId FAM_FIXED_ASSETS.HRM_PERSON_ID%type;
    vDocRecordId FAM_FIXED_ASSETS.DOC_RECORD_ID%type;
    vGcoGoodId   FAM_FIXED_ASSETS.GCO_GOOD_ID%type;

    procedure TestMgmIntegrity(pSubSets in out SubSetAccount)
    is
      vPermissionCDA ACS_CPN_ACCOUNT.C_CDA_IMPUTATION%type;
      vPermissionPF  ACS_CPN_ACCOUNT.C_PF_IMPUTATION%type;
      vPermissionPJ  ACS_CPN_ACCOUNT.C_PJ_IMPUTATION%type;
    begin
      if pSubSets.CPN.AccountId is not null then
        ACT_CREATION_SBVR.GetMANImputationPermission(pSubSets.CPN.AccountId
                                                   , vPermissionCDA
                                                   , vPermissionPF
                                                   , vPermissionPJ
                                                    );

        if     (pSubSets.CDA.AccountId is not null)
           and (vPermissionCDA = '3') then
          pSubSets.CDA.AccountId  := null;
        end if;

        if     (pSubSets.PF.AccountId is not null)
           and (vPermissionPF = '3') then
          pSubSets.PF.AccountId  := null;
        end if;

        if     (pSubSets.CDA.AccountId is not null)
           and (vPermissionCDA = '2')
           and (vPermissionPF = '2') then
          pSubSets.PF.AccountId  := null;
        elsif     (pSubSets.PF.AccountId is not null)
              and (vPermissionCDA = '2')
              and (vPermissionPF = '2') then
          pSubSets.CDA.AccountId  := null;
        end if;

        if     pSubSets.PJ.AccountId is not null
           and not(vPermissionPJ in('1', '2') ) then
          pSubSets.PJ.AccountId  := null;
        end if;
      else
        pSubSets.CDA.AccountId  := null;
        pSubSets.PF.AccountId   := null;
        pSubSets.PJ.AccountId   := null;
      end if;
    end TestMgmIntegrity;
  begin
    /*Initialisation des comptes du record des comptes*/
    pManagedSubSets.ACC.AccountId                         := null;
    pManagedSubSets.DIV.AccountId                         := null;
    pManagedSubSets.CPN.AccountId                         := null;
    pManagedSubSets.CDA.AccountId                         := null;
    pManagedSubSets.PF.AccountId                          := null;
    pManagedSubSets.PJ.AccountId                          := null;
    vcpt                                                  := pTableValImputation.first;
    vFirstValue                                           := true;

    /*Récupération des comptes pour chaque valeur gérée */
    while not vResult
     and vcpt is not null loop
      vResult  :=
        FAM_TRANSACTIONS.GetFamAccounts(pFixedAssetsId
                                      , pImputationTyp
                                      , pTableValImputation(vcpt).FAM_MANAGED_VALUE_ID
                                      , vFirstValue
                                      , pManagedSubSets
                                       );

      if vFirstValue then
        vFirstValue  := false;
      end if;

      vcpt     := pTableValImputation.next(vcpt);
    end loop;

    /*Vérification interactions analytiques*/
    TestMgmIntegrity(pManagedSubSets);

    -- Permet d'inverser le montant de l'imputation (Débit/Crédit)
    if pIndex <> 1 then
      pTableActImputation(pIndex).FIM_AMOUNT_LC_D  := -1;
    else
      pTableActImputation(pIndex).FIM_AMOUNT_LC_D  := 1;
    end if;

    /*initialisation des propriétés des imputations comptables*/
    pTableActImputation(pIndex).C_FAM_IMPUTATION_TYP      := pImputationTyp;
    pTableActImputation(pIndex).ACS_FINANCIAL_ACCOUNT_ID  := pManagedSubSets.ACC.AccountId;
    pTableActImputation(pIndex).ACS_DIVISION_ACCOUNT_ID   := pManagedSubSets.DIV.AccountId;
    pTableActImputation(pIndex).ACS_CPN_ACCOUNT_ID        := pManagedSubSets.CPN.AccountId;
    pTableActImputation(pIndex).ACS_CDA_ACCOUNT_ID        := pManagedSubSets.CDA.AccountId;
    pTableActImputation(pIndex).ACS_PF_ACCOUNT_ID         := pManagedSubSets.PF.AccountId;
    pTableActImputation(pIndex).ACS_PJ_ACCOUNT_ID         := pManagedSubSets.PJ.AccountId;
    /*Initialisation des axes complémentaires Personne, Employé, Dossier*/
    vPacPersonId                                          := null;
    vHrmPersonId                                          := null;
    vDocRecordId                                          := null;
    vGcoGoodId                                            := null;

    begin
      select PAC_PERSON_ID
           , HRM_PERSON_ID
           , DOC_RECORD_ID
           , GCO_GOOD_ID
        into vPacPersonId
           , vHrmPersonId
           , vDocRecordId
           , vGcoGoodId
        from FAM_FIXED_ASSETS
       where FAM_FIXED_ASSETS_ID = pFixedAssetsId;
    exception
      when others then
        null;
    end;

    pTableActImputation(pIndex).PAC_PERSON_ID             := vPacPersonId;
    pTableActImputation(pIndex).HRM_PERSON_ID             := vHrmPersonId;
    pTableActImputation(pIndex).DOC_RECORD_ID             := vDocRecordId;
    pTableActImputation(pIndex).GCO_GOOD_ID               := vGcoGoodId;
  end InitActImpDatas;

  /**
  * Description  Intégration des imputations financières sur la base d'un document comptable, d'une immobilisation, un type de transaction et une monnaie donnés
                 dans un journal immobilisation existant
  */
  procedure DocFromFinancialImputation(
    aACT_DOCUMENT_ID           ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
  , aFAM_FIXED_ASSETS_ID       ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , aC_FAM_TRANSACTION_TYP     ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
  , aIMF_TRANSACTION_DATE      ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE            ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aFAM_JOURNAL_ID            FAM_JOURNAL.FAM_JOURNAL_ID%type
  )
  is
    cursor crFinancialImputationOk(
      aDocumentId        ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
    , aFixedAssetsId     ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID%type
    , aTransactionTyp    ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
    , aTransactionDate   ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
    , aValueDate         ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
    , aForeignCurrencyId ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
    , aFamJournalId      FAM_JOURNAL.FAM_JOURNAL_ID%type
    )
    is
      select   IMP.ACT_DOCUMENT_ID
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_TRANSACTION_DATE
          from ACT_DET_TAX TAX
             , ACT_ETAT_JOURNAL ETA
             , FAM_CATALOGUE FCA
             , ACJ_JOB_TYPE_S_CATALOGUE JSC
             , ACT_JOB JOB
             , ACT_JOURNAL JOU
             , ACT_DOCUMENT DOC
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aDocumentId
           and IMP.FAM_FIXED_ASSETS_ID = aFixedAssetsId
           and IMP.C_FAM_TRANSACTION_TYP = aTransactionTyp
           and IMP.ACS_FINANCIAL_CURRENCY_ID = aForeignCurrencyId
           and IMP.IMF_TRANSACTION_DATE = aTransactionDate
           and IMP.IMF_VALUE_DATE = aValueDate
           and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID
           and JOB.ACJ_JOB_TYPE_ID = JSC.ACJ_JOB_TYPE_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = JSC.ACJ_CATALOGUE_DOCUMENT_ID
           and JSC.ACJ_JOB_TYPE_S_CATALOGUE_ID = FCA.ACJ_JOB_TYPE_S_CATALOGUE_ID
           and JOU.ACS_FINANCIAL_YEAR_ID = (select ACS_FINANCIAL_YEAR_ID
                                              from FAM_JOURNAL
                                             where FAM_JOURNAL_ID = aFamJournalId)
           and JOU.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
           and ETA.C_SUB_SET = 'ACC'
           and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT2_ACT_FINANCIAL_IMPUTATION(+)
           and (    (IMP.IMF_TYPE = 'MAN')
                or (    IMP.IMF_TYPE = 'VAT'
                    and nvl(TAX.ACT_DET_TAX_ID, 0) <> 0) )
           and not exists(select ACT_FINANCIAL_IMPUTATION_ID
                            from FAM_ACT_IMPUTATION
                           where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID)
      group by IMP.ACT_DOCUMENT_ID
             , IMP.FAM_FIXED_ASSETS_ID
             , IMP.C_FAM_TRANSACTION_TYP
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE;

    tplFinancialImputationOk crFinancialImputationOk%rowtype;
    NewId                    FAM_DOCUMENT.FAM_DOCUMENT_ID%type;

    --------
    procedure NewDocument(
      aActDocumentId       in     ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
    , aFamFixedAssetsId    in     ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID%type
    , aTransactionTyp      in     ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
    , aTransactionDate     in     ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
    , aValueDate           in     ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
    , aFinancialCurrencyId in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
    , aFamJournalId        in     FAM_JOURNAL.FAM_JOURNAL_ID%type
    , aFamDocumentId       in out FAM_DOCUMENT.FAM_DOCUMENT_ID%type
    )
    is
      ImputationId          FAM_IMPUTATION.FAM_IMPUTATION_ID%type;
      CatalogId             FAM_DOCUMENT.FAM_CATALOGUE_ID%type;
      DocAmount             FAM_DOCUMENT.FDO_AMOUNT%type;
      vImputationTyp        FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type;
      vAdditionnalFamImpTyp FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type;
      vTransactionTyp       FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;

      --------
      procedure CreateDocument(
        aActDocumentId      in     ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
      , aFamTransactionTyp  in     ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
      , aFamJournalId       in     FAM_JOURNAL.FAM_JOURNAL_ID%type
      , aDocumentCurrencyId in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
      , aFamDocumentId      out    FAM_DOCUMENT.FAM_DOCUMENT_ID%type
      , aFamCatalogueId     out    FAM_DOCUMENT.FAM_CATALOGUE_ID%type
      )
      is
        vActDocNumber      ACT_DOCUMENT.DOC_NUMBER%type;   --Numéro document financier
        vActDocDate        ACT_DOCUMENT.DOC_DOCUMENT_DATE%type;   -- Date document financier
        vFamDocumentNumber FAM_DOCUMENT.FDO_INT_NUMBER%type;   --Numéro généré du document FAM
        vFinancialYearId   FAM_JOURNAL.ACS_FINANCIAL_YEAR_ID%type;   --Exercice financier du journal courant
        vNumberReadOnly    number(1);
      begin
        --Réception date et numéro du document financier
        select DOC_NUMBER
             , DOC_DOCUMENT_DATE
          into vActDocNumber
             , vActDocDate
          from ACT_DOCUMENT
         where ACT_DOCUMENT_ID = aActDocumentId;

        --Réception exercice du journal
        select ACS_FINANCIAL_YEAR_ID
          into vFinancialYearId
          from FAM_JOURNAL
         where FAM_JOURNAL_ID = aFamJournalId;

        --Recherche du catalogue et génération d'un nouveau numéro de document
        aFamCatalogueId  := FAM_TRANSACTIONS.GetCatalogId(aActDocumentId, aFamTransactionTyp);
        FAM_FUNCTIONS.GetFamDocNumber(aFamCatalogueId, vFinancialYearId, vFamDocumentNumber, vNumberReadOnly);

        --Réception nouvel Id de document
        select init_id_seq.nextval
          into aFamDocumentId
          from dual;

        --Création du document FAM
        begin
          insert into FAM_DOCUMENT
                      (FAM_DOCUMENT_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                     , FAM_JOURNAL_ID
                     , FAM_CATALOGUE_ID
                     , ACT_DOCUMENT_ID
                     , FDO_INT_NUMBER
                     , FDO_EXT_NUMBER
                     , FDO_AMOUNT
                     , FDO_DOCUMENT_DATE
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (aFamDocumentId
                     , aDocumentCurrencyId
                     , aFamJournalId
                     , aFamCatalogueId
                     , aActDocumentId
                     , vFamDocumentNumber
                     , vActDocNumber
                     , 0
                     , vActDocDate
                     , trunc(sysdate)
                     , UserIni
                      );
        exception
          when others then
            aFamDocumentId  := null;
        end;
      end CreateDocument;

      --------
      procedure CreateFamImputation(
        aActDocumentId       in     ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
      , aFixedAssetsId       in     ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID%type
      , aFamTransactionTyp   in     ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
      , aTransactionDate     in     ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
      , aValueDate           in     ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
      , aDocumentCurrencyId  in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
      , aFamJournalId        in     FAM_JOURNAL.FAM_JOURNAL_ID%type
      , aFamDocumentId       in     FAM_DOCUMENT.FAM_DOCUMENT_ID%type
      , aFamImputationId     in out FAM_IMPUTATION.FAM_IMPUTATION_ID%type
      , aFamImputationAmount in out FAM_DOCUMENT.FDO_AMOUNT%type
      )
      is
        LCurrencyId  ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
        PeriodId     ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type;
        AmountLC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
        AmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
        Description  ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
        ExchangeRate ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
        BasePrice    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
        vAmountLCD   FAM_IMPUTATION.FIM_AMOUNT_LC_D%type;
        vAmountLCC   FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;
        vAmountFCD   FAM_IMPUTATION.FIM_AMOUNT_FC_D%type;
        vAmountFCC   FAM_IMPUTATION.FIM_AMOUNT_FC_C%type;
        vFixCategId  FAM_IMPUTATION.FAM_FIXED_ASSETS_CATEG_ID%type;

        ------
        function GetImpDescription(
          aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type
        , aDescription     ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
        )
          return FAM_IMPUTATION.FIM_DESCR%type
        is
          ParDocument ACT_PART_IMPUTATION.PAR_DOCUMENT%type;
          PerName     PAC_PERSON.PER_NAME%type;
          result      FAM_IMPUTATION.FIM_DESCR%type;
        begin
          begin
            select PAR.PAR_DOCUMENT
                 , nvl(P1.PER_NAME, P2.PER_NAME)
              into ParDocument
                 , PerName
              from PAC_PERSON P2
                 , PAC_PERSON P1
                 , ACT_PART_IMPUTATION PAR
             where PAR.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
               and PAR.PAC_CUSTOM_PARTNER_ID = P1.PAC_PERSON_ID(+)
               and PAR.PAC_SUPPLIER_PARTNER_ID = P2.PAC_PERSON_ID(+);

            result  := PerName;

            if ParDocument is not null then
              result  := result || ' ' || ParDocument;
            end if;

            result  := result || ' ' || aDescription;
          exception
            when others then
              result  := aDescription;
          end;

          return substr(result, 1, 100);
        end GetImpDescription;
      ----
      begin
        select   ACS_ACS_FINANCIAL_CURRENCY_ID
               , ACS_PERIOD_ID
               , sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C)
               , sum(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
            into LCurrencyId
               , PeriodId
               , AmountLC
               , AmountFC
            from ACT_DET_TAX TAX
               , ACT_FINANCIAL_IMPUTATION IMP
           where IMP.ACT_DOCUMENT_ID = aActDocumentId
             and IMP.FAM_FIXED_ASSETS_ID = aFixedAssetsId
             and IMP.C_FAM_TRANSACTION_TYP = aFamTransactionTyp
             and IMP.ACS_FINANCIAL_CURRENCY_ID = aDocumentCurrencyId
             and IMP.IMF_TRANSACTION_DATE = aTransactionDate
             and IMP.IMF_VALUE_DATE = aValueDate
             and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT2_ACT_FINANCIAL_IMPUTATION(+)
             and (    (IMP.IMF_TYPE = 'MAN')
                  or (    IMP.IMF_TYPE = 'VAT'
                      and nvl(TAX.ACT_DET_TAX_ID, 0) <> 0) )
        group by ACS_ACS_FINANCIAL_CURRENCY_ID
               , ACS_PERIOD_ID
               , IMF_TRANSACTION_DATE
               , IMF_VALUE_DATE;

        if aDocumentCurrencyId <> LCurrencyId then
          aFamImputationAmount  := AmountFC;
        else
          aFamImputationAmount  := AmountLC;
        end if;

        begin
          select IMF_DESCRIPTION
            into Description
            from ACT_FINANCIAL_IMPUTATION IMP
           where IMP.ACT_DOCUMENT_ID = aActDocumentId
             and IMP.IMF_PRIMARY = 1;
        exception
          when no_data_found then
            Description  := null;
        end;

        Description       := GetImpDescription(aActDocumentId, Description);
        BasePrice         := ACS_FUNCTION.GetBasePriceEUR(aTransactionDate, aDocumentCurrencyId);
        ExchangeRate      :=
          ACS_FUNCTION.CalcRateOfExchangeEUR(abs(AmountLC)
                                           , abs(AmountFC)
                                           , aDocumentCurrencyId
                                           , aTransactionDate
                                           , BasePrice
                                            );
        vAmountLCD        := 0.0;
        vAmountFCD        := 0.0;
        vAmountLCC        := 0.0;
        vAmountFCC        := 0.0;

        if sign(AmountLC) = 1 then
          vAmountLCD  := AmountLC;
        else
          vAmountLCC  := abs(AmountLC);
        end if;

        if sign(AmountFC) = 1 then
          vAmountFCD  := AmountFC;
        else
          vAmountFCC  := abs(AmountFC);
        end if;

        vFixCategId       := FAM_FUNCTIONS.GetFixedAssetsCategory(aFAM_FIXED_ASSETS_ID);
        aFamImputationId  :=
          InsertFamImputation(aFamDocumentId
                            , aFamJournalId
                            , PeriodId
                            , aDocumentCurrencyId
                            , LCurrencyId
                            , aFAM_FIXED_ASSETS_ID
                            , vFixCategId
                            , aFamTransactionTyp
                            , Description
                            , aTransactionDate
                            , aValueDate
                            , vAmountLCD
                            , vAmountLCC
                            , vAmountFCD
                            , vAmountFCC
                            , ExchangeRate
                            , BasePrice
                            , 0
                             );
      end CreateFamImputation;

      --------
      procedure CreateACTImputations(
        aActDocumentId      in ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
      , aFixedAssetsId      in ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID%type
      , aFamTransactionTyp  in ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
      , aTransactionDate    in ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
      , aValueDate          in ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
      , aDocumentCurrencyId in ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
      , aFamDocumentId      in FAM_DOCUMENT.FAM_DOCUMENT_ID%type
      , aFamImputationId    in FAM_IMPUTATION.FAM_IMPUTATION_ID%type
      , aFamImputationTyp   in FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
      , aAdditionalImpTyp   in FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
      )
      is
        cursor FinancialImputationsCursor(
          aFinancialDocumentId in ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
        , aFamFixedAssetsId    in ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID%type
        , aTransactionTyp      in ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
        , aDateTransaction     in ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
        , aDateValue           in ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
        , aFinancialCurrencId  in ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
        )
        is
          select   max(IMP.ACT_FINANCIAL_IMPUTATION_ID) ACT_FINANCIAL_IMPUTATION_ID
                 , IMP.ACS_FINANCIAL_ACCOUNT_ID
                 , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                 , sum(nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) ) IMF_AMOUNT_LC_D
                 , sum(nvl(IMF_AMOUNT_FC_D, 0) - nvl(IMF_AMOUNT_FC_C, 0) ) IMF_AMOUNT_FC_D
              from ACT_DET_TAX TAX
                 , ACT_FINANCIAL_IMPUTATION IMP
             where IMP.ACT_DOCUMENT_ID = aFinancialDocumentId
               and IMP.FAM_FIXED_ASSETS_ID = aFamFixedAssetsId
               and IMP.C_FAM_TRANSACTION_TYP = aTransactionTyp
               and IMP.IMF_TRANSACTION_DATE = aDateTransaction
               and IMP.IMF_VALUE_DATE = aDateValue
               and IMP.ACS_FINANCIAL_CURRENCY_ID = aFinancialCurrencId
               and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT2_ACT_FINANCIAL_IMPUTATION(+)
               and (    (IMP.IMF_TYPE = 'MAN')
                    or (    IMP.IMF_TYPE = 'VAT'
                        and nvl(TAX.ACT_DET_TAX_ID, 0) <> 0) )
          group by IMP.ACT_FINANCIAL_IMPUTATION_ID
                 , IMP.ACS_FINANCIAL_ACCOUNT_ID
                 , IMP.IMF_ACS_DIVISION_ACCOUNT_ID;

        FinancialImputations FinancialImputationsCursor%rowtype;
        CPNAccountId         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
        CDAAccountId         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
        PFAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
        PJAccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
        PacPersonId          FAM_FIXED_ASSETS.PAC_PERSON_ID%type;
        HrmPersonId          FAM_FIXED_ASSETS.HRM_PERSON_ID%type;
        DocRecordId          FAM_FIXED_ASSETS.DOC_RECORD_ID%type;
        GcoGoodId            FAM_FIXED_ASSETS.GCO_GOOD_ID%type;
        vImputationTyp       FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type;
      begin
        begin
          select PAC_PERSON_ID
               , HRM_PERSON_ID
               , DOC_RECORD_ID
               , GCO_GOOD_ID
            into PacPersonId
               , HrmPersonId
               , DocRecordId
               , GcoGoodId
            from FAM_FIXED_ASSETS
           where FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID;
        exception
          when others then
            PacPersonId  := null;
            HrmPersonId  := null;
            DocRecordId  := null;
            GcoGoodId    := null;
        end;

        open FinancialImputationsCursor(aActDocumentId
                                      , aFixedAssetsId
                                      , aFamTransactionTyp
                                      , aTransactionDate
                                      , aValueDate
                                      , aDocumentCurrencyId
                                       );

        fetch FinancialImputationsCursor
         into FinancialImputations;

        while FinancialImputationsCursor%found loop
          begin
            select ACS_CPN_ACCOUNT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
              into CPNAccountId
                 , CDAAccountId
                 , PFAccountId
                 , PJAccountId
              from ACT_MGM_DISTRIBUTION DIS
                 , ACT_MGM_IMPUTATION MGM
             where MGM.ACT_MGM_IMPUTATION_ID =
                                  (select min(ACT_MGM_IMPUTATION_ID)
                                     from ACT_MGM_IMPUTATION
                                    where ACT_FINANCIAL_IMPUTATION_ID = FinancialImputations.ACT_FINANCIAL_IMPUTATION_ID)
               and MGM.ACT_MGM_IMPUTATION_ID = DIS.ACT_MGM_IMPUTATION_ID(+);
          exception
            when others then
              CPNAccountId  := null;
              CDAAccountId  := null;
              PFAccountId   := null;
              PJAccountId   := null;
          end;

          vImputationTyp  := aFamImputationTyp;

          if aAdditionalImpTyp = '61' then
            if sign(FinancialImputations.IMF_AMOUNT_LC_D) = -1 then
              vImputationTyp  := '11';
            else
              vImputationTyp  := '61';
            end if;
          elsif aAdditionalImpTyp = '62' then
            if sign(FinancialImputations.IMF_AMOUNT_LC_D) = -1 then
              vImputationTyp  := '11';
            else
              vImputationTyp  := '62';
            end if;
          end if;

          FAM_TRANSACTIONS.InsertActImputation(aFamDocumentId
                                             , FinancialImputations.ACS_FINANCIAL_ACCOUNT_ID
                                             , FinancialImputations.ACS_DIVISION_ACCOUNT_ID
                                             , CPNAccountId
                                             , CDAAccountId
                                             , PFAccountId
                                             , PJAccountId
                                             , vImputationTyp
                                             , aFamImputationId
                                             , FinancialImputations.ACT_FINANCIAL_IMPUTATION_ID
                                             , FinancialImputations.IMF_AMOUNT_LC_D
                                             , FinancialImputations.IMF_AMOUNT_FC_D
                                             , DocRecordId
                                             , PacPersonId
                                             , HrmPersonId
                                             , GcoGoodId
                                              );

          fetch FinancialImputationsCursor
           into FinancialImputations;
        end loop;

        close FinancialImputationsCursor;
      end CreateACTImputations;
    -----
    begin
      -- Création en-tête document immobilisation
      CreateDocument(aActDocumentId, aTransactionTyp, aFamJournalId, aFinancialCurrencyId, aFamDocumentId, CatalogId);

      if aFamDocumentId is not null then
        vTransactionTyp  :=
                        FAM_TRANSACTIONS.GetImputationType(CatalogId, false, '', vImputationTyp, vAdditionnalFamImpTyp);
        -- Création imputation immobilisation
        CreateFamImputation(aActDocumentId
                          , aFamFixedAssetsId
                          , aTransactionTyp
                          , aTransactionDate
                          , aValueDate
                          , aFinancialCurrencyId
                          , aFamJournalId
                          , aFamDocumentId
                          , ImputationId
                          , DocAmount
                           );
        -- Création imputation(s) valeur(s) gérée(s) en fonction des valeurs gérées par catalogue
        CreateValImputations(aFamDocumentId, ImputationId, CatalogId);
        -- Création imputation(s) financière(s) immobilisation
        CreateACTImputations(aActDocumentId
                           , aFamFixedAssetsId
                           , aTransactionTyp
                           , aTransactionDate
                           , aValueDate
                           , aFinancialCurrencyId
                           , aFamDocumentId
                           , ImputationId
                           , vImputationTyp
                           , vAdditionnalFamImpTyp
                            );

        -- Mise à jour total nouveau document immobilisation
        update FAM_DOCUMENT
           set FDO_AMOUNT = abs(DocAmount)
         where FAM_DOCUMENT_ID = aFamDocumentId;
      end if;
    end NewDocument;
  -----
  begin
    open crFinancialImputationOk(aACT_DOCUMENT_ID
                               , aFAM_FIXED_ASSETS_ID
                               , aC_FAM_TRANSACTION_TYP
                               , aIMF_TRANSACTION_DATE
                               , aIMF_VALUE_DATE
                               , aACS_FINANCIAL_CURRENCY_ID
                               , aFAM_JOURNAL_ID
                                );

    fetch crFinancialImputationOk
     into tplFinancialImputationOk;

    while crFinancialImputationOk%found loop
      NewDocument(aACT_DOCUMENT_ID
                , aFAM_FIXED_ASSETS_ID
                , aC_FAM_TRANSACTION_TYP
                , aIMF_TRANSACTION_DATE
                , aIMF_VALUE_DATE
                , aACS_FINANCIAL_CURRENCY_ID
                , aFAM_JOURNAL_ID
                , NewId
                 );

      fetch crFinancialImputationOk
       into tplFinancialImputationOk;
    end loop;
  end DocFromFinancialImputation;

  /**
  * Description  Retourne l'Id du catalogue immobilisation sur la base de l'Id d'un document comptable
  */
  function GetCatalogId(
    aACT_DOCUMENT_ID       in ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aC_FAM_TRANSACTION_TYP in ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP%type
  )
    return FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  is
    result FAM_DOCUMENT.FAM_CATALOGUE_ID%type;
  begin
    begin
      select min(CAT.FAM_CATALOGUE_ID)
        into result
        from FAM_CATALOGUE CAT
           , ACJ_JOB_TYPE_S_CATALOGUE JSC
           , ACT_JOB JOB
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOB.ACJ_JOB_TYPE_ID = JSC.ACJ_JOB_TYPE_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = JSC.ACJ_CATALOGUE_DOCUMENT_ID
         and JSC.ACJ_JOB_TYPE_S_CATALOGUE_ID = CAT.ACJ_JOB_TYPE_S_CATALOGUE_ID
         and CAT.C_FAM_TRANSACTION_TYP = aC_FAM_TRANSACTION_TYP;
    exception
      when others then
        result  := null;
    end;

    return result;
  end GetCatalogId;

  function GetManagedSubSets
    return SubSetAccount
  is
    id     ACS_SUB_SET.ACS_SUB_SET_ID%type;
    result SubSetAccount;
  begin
    result.DIV.Exist  := false;
    result.CPN.Exist  := false;
    result.CDA.Exist  := false;
    result.PF.Exist   := false;
    result.PJ.Exist   := false;

    select min(ACS_SUB_SET_ID)
      into id   -- Test existence sous-ensemble Division
      from ACS_SUB_SET
     where C_TYPE_SUB_SET = 'DIVI';

    result.DIV.Exist  := id is not null;

    select min(ACS_SUB_SET_ID)
      into id   -- Test existence sous-ensemble Charge par nature
      from ACS_SUB_SET
     where C_SUB_SET = 'CPN';

    result.CPN.Exist  := id is not null;

    if id is not null then   --Si CPN existe
      select min(ACS_SUB_SET_ID)
        into id   -- Test existence sous-ensemble Centre d'analyse
        from ACS_SUB_SET
       where C_SUB_SET = 'CDA';

      result.CDA.Exist  := id is not null;

      select min(ACS_SUB_SET_ID)
        into id   -- Test existence sous-ensemble Porteur de frais
        from ACS_SUB_SET
       where C_SUB_SET = 'COS';

      result.PF.Exist   := id is not null;

      select min(ACS_SUB_SET_ID)
        into id   -- Test existence sous-ensemble Projet
        from ACS_SUB_SET
       where C_SUB_SET = 'PRO';

      result.PJ.Exist   := id is not null;
    end if;

    return result;
  end GetManagedSubSets;

/********************************************************************************************************************/
/* Retourne les types d'imputations et les comptes des différents sous-ensembles  pour une immobilisation,          */
/* un type de transaction, et une valeur gérée donnés                                                               */
/********************************************************************************************************************/
  procedure InitAssetsAccounts(
    aFAM_FIXED_ASSETS_ID  in     FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , aFAM_CATALOGUE_ID     in     FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  , aFAM_MANAGED_VALUE_ID in     FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , aFAM_IMPUTATION_ID    in     FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  , aCreateValues         in     number
  , aInterest1            in     boolean
  , pSimTransactionType   in     FAM_IMPUTATION.C_FAM_TRANSACTION_TYP%type default ''
  , pValImputations       in out TableValImputations
  , pActImputations       in out TableActImputations
  )
  is
    ImputationTyp         FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type;
    vAdditionnalFamImpTyp FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type;
    vTransactionTyp       FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;
    SubSets               SubSetAccount;
    i                     binary_integer                                 default 0;

---------------------------------------------------------------------------
    function GetManagedValue(
      aFAM_CATALOGUE_ID     FAM_DOCUMENT.FAM_CATALOGUE_ID%type
    , aFAM_MANAGED_VALUE_ID FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
    , aFAM_IMPUTATION_ID    FAM_IMPUTATION.FAM_IMPUTATION_ID%type
    , aCreateValues         number
    )
      return TableValImputations
    is
      /*Curseur de recherche des valeurs gérées du catalogue ou des valeurs gérées déjà existantes dans l'imputation valeur de */
      /* de l'imputation si pas de création de l'imputaiotn valeur                                                             */
      cursor CatalogManagedValuesCursor(
        aFAM_CATALOGUE_ID  FAM_CATALOGUE.FAM_CATALOGUE_ID%type
      , aFAM_IMPUTATION_ID FAM_IMPUTATION.FAM_IMPUTATION_ID%type
      , aCreateValues      number
      )
      is
        select   CAT.FAM_MANAGED_VALUE_ID
               ,   /*Imputation valeur à créer => Recherche sur catalogue*/
                 VAL.C_VALUE_CATEGORY
            from FAM_MANAGED_VALUE VAL
               , FAM_CAT_MANAGED_VALUE CAT
           where CAT.FAM_CATALOGUE_ID = aFAM_CATALOGUE_ID
             and CAT.FAM_MANAGED_VALUE_ID = VAL.FAM_MANAGED_VALUE_ID
             and aCreateValues = 1
        union
        select   IMP.FAM_MANAGED_VALUE_ID
               ,   /*pas de création de l'imputation valeur => Recherche sur imputations déjà existantes*/
                 VAL.C_VALUE_CATEGORY
            from FAM_MANAGED_VALUE VAL
               , FAM_VAL_IMPUTATION IMP
           where IMP.FAM_IMPUTATION_ID = aFAM_IMPUTATION_ID
             and IMP.FAM_MANAGED_VALUE_ID = VAL.FAM_MANAGED_VALUE_ID
             and aCreateValues = 0
        order by 2 asc;

      CatalogManagedValues CatalogManagedValuesCursor%rowtype;
      result               TableValImputations;
      vManagedValueCounter binary_integer;
    begin
      if aFAM_MANAGED_VALUE_ID is not null then   /*La valeur gérée est déjà initialisée => mise à jour de la table temporaire des imputations valeurs*/
        vManagedValueCounter                               := 1;
        result(vManagedValueCounter).FAM_MANAGED_VALUE_ID  := aFAM_MANAGED_VALUE_ID;
      else   /*Pas de valeur gérée par défaut => Recherche de valeurs gérées du catalogue*/
             /* ou des valeurs déjà existantes dans l'imputation                         */
        open CatalogManagedValuesCursor(aFAM_CATALOGUE_ID, aFAM_IMPUTATION_ID, aCreateValues);

        fetch CatalogManagedValuesCursor
         into CatalogManagedValues;

        vManagedValueCounter  := 0;

        while CatalogManagedValuesCursor%found loop
          vManagedValueCounter                               := vManagedValueCounter + 1;
          result(vManagedValueCounter).FAM_MANAGED_VALUE_ID  := CatalogManagedValues.FAM_MANAGED_VALUE_ID;

          fetch CatalogManagedValuesCursor
           into CatalogManagedValues;
        end loop;

        close CatalogManagedValuesCursor;
      end if;

      return result;
    end GetManagedValue;
---------------------------------------------------------------------------
  begin
    /*Suppresion des enregistrements de la table temporaire des imputations comptables*/
    pActImputations.delete;

    if not pSimTransactionType is null then
      /*Récupération du type d'imputation selon le type de transaction du catalogue*/
      /*Réception des types d'imputations à générer*/
      vTransactionTyp  :=
        FAM_TRANSACTIONS.GetImputationType(aFAM_CATALOGUE_ID
                                         , aInterest1
                                         , pSimTransactionType
                                         , ImputationTyp
                                         , vAdditionnalFamImpTyp
                                          );
    else
      /*Récupération du type d'imputation selon le type de transaction du catalogue*/
      /*Réception des types d'imputations à générer*/
      vTransactionTyp  :=
            FAM_TRANSACTIONS.GetImputationType(aFAM_CATALOGUE_ID, aInterest1, '', ImputationTyp, vAdditionnalFamImpTyp);
    end if;

    if ImputationTyp is not null then   /*Imputation existe*/
      i                := 1;
      /*Recherche des type de comptes existants*/
      SubSets          := GetManagedSubSets;
      /*Récupération dans la table temporaire des valeurs gérées*/
      pValImputations  := GetManagedValue(aFAM_CATALOGUE_ID, aFAM_MANAGED_VALUE_ID, aFAM_IMPUTATION_ID, aCreateValues);
      InitActImpDatas(aFAM_FIXED_ASSETS_ID, ImputationTyp, i, pValImputations, SubSets, pActImputations);

      if     (ImputationTyp in(15, 16) )
         and (pActImputations(i).ACS_FINANCIAL_ACCOUNT_ID is null)
         and (pActImputations(i).ACS_CPN_ACCOUNT_ID is null) then
        ImputationTyp  := 11;
        InitActImpDatas(aFAM_FIXED_ASSETS_ID, ImputationTyp, i, pValImputations, SubSets, pActImputations);
      elsif     (ImputationTyp = 18)
            and (pActImputations(i).ACS_FINANCIAL_ACCOUNT_ID is null)
            and (pActImputations(i).ACS_CPN_ACCOUNT_ID is null) then
        ImputationTyp  := 12;
        InitActImpDatas(aFAM_FIXED_ASSETS_ID, ImputationTyp, i, pValImputations, SubSets, pActImputations);
      end if;

      if not vAdditionnalFamImpTyp is null then
        InitActImpDatas(aFAM_FIXED_ASSETS_ID, vAdditionnalFamImpTyp, i + 1, pValImputations, SubSets, pActImputations);
      end if;
    end if;
  end InitAssetsAccounts;

  /**
  * Description
  *    Vérifie la gestion du type d'imputation dans les comptes pour l'immobilisation / valeur géré
  */
  function ImpTypeExistByValue(
    pImputationTyp FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
  , pAssetsId      FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pManagedValId  FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  )
    return integer
  is
    result FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
  begin
    begin   /* Recherche dans les comptes mouvementées */
      select FAM_IMPUTATION_ACCOUNT_ID
        into result   /* selon les méthodes de l'immobilisation des valeurs gérés*/
        from FAM_IMPUTATION_ACCOUNT ACC
           ,   /* du catalogue du document*/
             FAM_AMO_APPLICATION APP
       where APP.FAM_FIXED_ASSETS_ID = pAssetsId
         and APP.FAM_MANAGED_VALUE_ID = pManagedValId
         and ACC.FAM_AMO_APPLICATION_ID = APP.FAM_AMO_APPLICATION_ID
         and ACC.C_FAM_IMPUTATION_TYP = pImputationTyp;
    exception
      when others then
        result  := 0;
    end;

    if result = 0 then   /* Type d'imputation non géré au niveau des méthodes de l'immo*/
      begin   /* => Recherche dans les comptes mouvementés*/
        select FAM_IMPUTATION_ACCOUNT_ID
          into result   /* par défaut des valeurs gérés du catalogue du document courant*/
          from FAM_IMPUTATION_ACCOUNT ACC
             , FAM_DEFAULT DEF
             , FAM_FIXED_ASSETS FIX
         where FIX.FAM_FIXED_ASSETS_ID = pAssetsId
           and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_MANAGED_VALUE_ID = pManagedValId
           and ACC.FAM_DEFAULT_ID = DEF.FAM_DEFAULT_ID
           and ACC.C_FAM_IMPUTATION_TYP = pImputationTyp;
      exception
        when others then
          result  := 0;
      end;
    end if;

    if result = 0 then
      return result;
    else
      return 1;
    end if;
  end ImpTypeExistByValue;

  /**
  * Description
  *    Vérifie la gestion du type d'imputation dans les comptes pour l'immobilisation / valeur géré
  */
  function ImpTypeExistByAsset(
    pImputationTyp FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
  , pAssetsId      FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pCatalogueId   FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  )
    return boolean
  is
    result FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
  begin
    begin   /* Recherche dans les comptes mouvementées */
      select nvl(max(ACC.FAM_IMPUTATION_ACCOUNT_ID), 0)
        into result   /* selon les méthodes de l'immobilisation des valeurs gérés*/
        from FAM_IMPUTATION_ACCOUNT ACC
           ,   /* du catalogue du document*/
             FAM_AMO_APPLICATION APP
       where APP.FAM_FIXED_ASSETS_ID = pAssetsId
         and exists(select 1
                      from FAM_CAT_MANAGED_VALUE CAT
                     where CAT.FAM_CATALOGUE_ID = pCatalogueId
                       and APP.FAM_MANAGED_VALUE_ID = CAT.FAM_MANAGED_VALUE_ID)
         and APP.FAM_AMO_APPLICATION_ID = ACC.FAM_AMO_APPLICATION_ID
         and ACC.C_FAM_IMPUTATION_TYP = pImputationTyp;
    exception
      when others then
        result  := 0;
    end;

    if result = 0 then   /* Type d'imputation non géré au niveau des méthodes de l'immo*/
      begin   /* => Recherche dans les comptes mouvementés*/
        select nvl(max(ACC.FAM_IMPUTATION_ACCOUNT_ID), 0)
          into result   /* par défaut des valeurs gérés du catalogue du document courant*/
          from FAM_IMPUTATION_ACCOUNT ACC
             , FAM_DEFAULT DEF
             , FAM_FIXED_ASSETS FIX
         where FIX.FAM_FIXED_ASSETS_ID = pAssetsId
           and exists(select 1
                        from FAM_CAT_MANAGED_VALUE CAT
                       where CAT.FAM_CATALOGUE_ID = pCatalogueId
                         and DEF.FAM_MANAGED_VALUE_ID = CAT.FAM_MANAGED_VALUE_ID)
           and FIX.FAM_FIXED_ASSETS_CATEG_ID = DEF.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_DEFAULT_ID = ACC.FAM_DEFAULT_ID
           and ACC.C_FAM_IMPUTATION_TYP = pImputationTyp;
      exception
        when others then
          result  := 0;
      end;
    end if;

    return(result <> 0);
  end ImpTypeExistByAsset;

  /**
  * Description
  *    Création de l'imputation valeur manuelle
  */
  procedure CreateManValImputations(
    aFAM_DOCUMENT_ID      FAM_IMPUTATION.FAM_DOCUMENT_ID%type
  , aFAM_IMPUTATION_ID    FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  , aFAM_MANAGED_VALUE_ID FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  )
  is
    vValImputation FAM_VAL_IMPUTATION.FAM_VAL_IMPUTATION_ID%type;
  begin
    /*Vérification de l'existence de la valeur pour l'imputation */
    begin
      select FAM_VAL_IMPUTATION_ID
        into vValImputation
        from FAM_VAL_IMPUTATION
       where FAM_IMPUTATION_ID = aFAM_IMPUTATION_ID
         and FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID;
    exception
      when others then
        vValImputation  := null;
    end;

    if vValImputation is null then   /*Création de l'imputation valeur uniquement si elle n'esiste pas déjà*/
      InsertValImputation(aFAM_MANAGED_VALUE_ID, aFAM_IMPUTATION_ID, aFAM_DOCUMENT_ID);
    end if;
  end CreateManValImputations;

  /**
  * Description
  *      Création de l'imputation comptable manuelle simulée
  */
  procedure CreateManACTImpSimulation(
    pFamImpSimulationId FAM_ACT_IMP_SIMULATION.FAM_IMP_SIMULATION_ID%type
  , pCImputationTyp     FAM_ACT_IMP_SIMULATION.C_FAM_IMPUTATION_TYP%type
  , pAmountLCD          FAM_ACT_IMP_SIMULATION.FIS_AMOUNT_LC_D%type
  , pAmountFCD          FAM_ACT_IMP_SIMULATION.FIS_AMOUNT_FC_D%type
  , pFinancialAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pDivisionAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pCpnAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pCdaAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pPFAccountId        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pPJAccountId        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pDocRecordId        FAM_ACT_IMP_SIMULATION.DOC_RECORD_ID%type
  , pPacPersonId        FAM_ACT_IMP_SIMULATION.PAC_PERSON_ID%type
  , pHrmPersonId        FAM_ACT_IMP_SIMULATION.HRM_PERSON_ID%type
  , pGcoGoodId          FAM_ACT_IMP_SIMULATION.GCO_GOOD_ID%type
  )
  is
  begin
    insert into FAM_ACT_IMP_SIMULATION
                (FAM_ACT_IMP_SIMULATION_ID
               , FAM_IMP_SIMULATION_ID
               , C_FAM_IMPUTATION_TYP
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , PAC_PERSON_ID
               , HRM_PERSON_ID
               , FIS_AMOUNT_LC_D
               , FIS_AMOUNT_LC_C
               , FIS_AMOUNT_FC_D
               , FIS_AMOUNT_FC_C
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , pFamImpSimulationId
               , pCImputationTyp
               , pFinancialAccountId
               , pDivisionAccountId
               , pCpnAccountId
               , pCdaAccountId
               , pPFAccountId
               , pPJAccountId
               , pGcoGoodId
               , pDocRecordId
               , pPacPersonId
               , pHrmPersonId
               , decode(sign(pAmountLCD), 1, pAmountLCD, 0)
               , decode(sign(pAmountLCD), -1, abs(pAmountLCD), 0)
               , decode(sign(pAmountFCD), 1, pAmountFCD, 0)
               , decode(sign(pAmountFCD), -1, abs(pAmountFCD), 0)
               , trunc(sysdate)
               , UserIni
                );
  end CreateManACTImpSimulation;

  /**
  * Description  Création des imputations Valeurs (FAM_VAL_IMPUTATION) et financières (FAM_ACT_IMPUTATION)
  *              sur la base d'une imputation immobilisation existante et d'une valeur gérée donnée (optionnelle)
  *              Si valeur gérée NULL, imputations valeurs sur la base des valeurs gérées du catalogue immobilisation
  */
  procedure Create_VAL_ACT_Imputations(
    aFAM_IMPUTATION_ID    FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  , aCreateValues         number default 1
  , aInterest1            boolean
  , pInterest             boolean
  , pSimCatalogId         FAM_AMORTIZATION_METHOD.FAM_CATALOGUE_ID%type
  , aFAM_MANAGED_VALUE_ID FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type default null
  )
  is
    type TAmounts is record(
      AmountLC FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
    , AmountFC FAM_IMPUTATION.FIM_AMOUNT_FC_D%type
    );

    DocumentId             FAM_DOCUMENT.FAM_DOCUMENT_ID%type;
    CatalogId              FAM_DOCUMENT.FAM_CATALOGUE_ID%type;
    AssetsId               FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type;
    vAmounts               TAmounts;
    vResultAmounts         TAmounts;
    vValImputations        TableValImputations;
    vActImputations        TableActImputations;
    vSimTransactionType    FAM_IMPUTATION.C_FAM_TRANSACTION_TYP%type              default '';
    vCatalogueValueFormula FAM_CAT_MANAGED_VALUE.CMV_AMOUNTS_PILOT_FORMULA%type;   --Réceptionne la formule de pilotage
    vPeriodId              ACS_PERIOD.ACS_PERIOD_ID%type;
    vSimulationId          FAM_SIMULATION.FAM_SIMULATION_ID%type;

    /* Réception de la formule de pilotage du montant envoyé à la finance pour le catalogue et valeur gérée*/
    function GetCatalogueValueFormula(
      pFamCatalogueId FAM_CAT_MANAGED_VALUE.FAM_CATALOGUE_ID%type
    , pManagedValueId FAM_CAT_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
    )
      return FAM_CAT_MANAGED_VALUE.CMV_AMOUNTS_PILOT_FORMULA%type
    is
      vResultFormula FAM_CAT_MANAGED_VALUE.CMV_AMOUNTS_PILOT_FORMULA%type;
    begin
      begin
        select CMV_AMOUNTS_PILOT_FORMULA
          into vResultFormula
          from FAM_CAT_MANAGED_VALUE
         where FAM_CATALOGUE_ID = pFamCatalogueId
           and FAM_MANAGED_VALUE_ID = pManagedValueId;
      exception
        when others then
          vResultFormula  := null;
      end;

      return vResultFormula;
    end GetCatalogueValueFormula;

    /*Application de la formule au montant initial*/
    function ApplyFormulaAmounts(
      pPeriodId      FAM_IMPUTATION.ACS_PERIOD_ID%type
    , pFixedAssetsId FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
    , pCatValFormula FAM_CAT_MANAGED_VALUE.CMV_AMOUNTS_PILOT_FORMULA%type
    , pBaseAmounts   TAmounts
    , pSimulationId  FAM_SIMULATION.FAM_SIMULATION_ID%type
    )
      return TAmounts
    is
      vCatValFormula   FAM_CAT_MANAGED_VALUE.CMV_AMOUNTS_PILOT_FORMULA%type;   --Réceptionne la formule à appliquer
      vCatValAmounts   TAmounts;   --Réceptionne le montant amortissement calculé
      vFormulaAmounts  TAmounts;   --Réceptionne le montant après y avoir appliqué la formule
      vFormulaChar     char(1);   --Caractère courant dans la formule pilotage
      vFormulaOperator char(1);   --Opérateur courant dans la formule pilotage
      vError           boolean;   --Code erreur

      /*Retour du montant amorti pour l'immobilisation selon catégorie et période donnée*/
      function ValueAmounts(
        pPeriodId      FAM_IMPUTATION.ACS_PERIOD_ID%type
      , pFixedAssetsId FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
      , pValCategory   FAM_MANAGED_VALUE.C_VALUE_CATEGORY%type
      )
        return TAmounts
      is
        vResultValAmounts TAmounts;
      begin
        begin
          select CAL_AMORTIZATION_LC
               , CAL_AMORTIZATION_FC
            into vResultValAmounts.AmountLC
               , vResultValAmounts.AmountFC
            from FAM_CALC_AMORTIZATION CAL
               , FAM_PER_CALC_BY_VALUE CBV
               , FAM_MANAGED_VALUE VAL
           where VAL.C_VALUE_CATEGORY = pValCategory
             and VAL.FAM_MANAGED_VALUE_ID = CBV.FAM_MANAGED_VALUE_ID
             and CBV.ACS_PERIOD_ID = pPeriodId
             and CBV.FAM_PER_CALC_BY_VALUE_ID = CAL.FAM_PER_CALC_BY_VALUE_ID
             and CAL.FAM_FIXED_ASSETS_ID = pFixedAssetsId;
        exception
          when others then
            vResultValAmounts.AmountLC  := 0;
            vResultValAmounts.AmountFC  := 0;
        end;

        return vResultValAmounts;
      end ValueAmounts;

      /*Retour du montant simulé pour l'immobilisation selon catégorie et période donnée*/
      function ValueAmountsSimulation(
        pPeriodId      FAM_IMPUTATION.ACS_PERIOD_ID%type
      , pFixedAssetsId FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
      , pSimulationId  FAM_SIMULATION.FAM_SIMULATION_ID%type
      , pValCategory   FAM_MANAGED_VALUE.C_VALUE_CATEGORY%type
      )
        return TAmounts
      is
        vResultValAmounts TAmounts;
      begin
        begin
          select FCS.FCS_AMORTIZATION_LC
               , FCS.FCS_AMORTIZATION_FC
            into vResultValAmounts.AmountLC
               , vResultValAmounts.AmountFC
            from FAM_CALC_SIMULATION FCS
               , FAM_MANAGED_VALUE VAL
           where FCS.ACS_PERIOD_ID = pPeriodId
             and FCS.FAM_FIXED_ASSETS_ID = pFixedAssetsId
             and FCS.FAM_SIMULATION_ID = pSimulationId
             and VAL.FAM_MANAGED_VALUE_ID = FCS.FAM_MANAGED_VALUE_ID
             and VAL.C_VALUE_CATEGORY = pValCategory;
        exception
          when others then
            vResultValAmounts.AmountLC  := 0;
            vResultValAmounts.AmountFC  := 0;
        end;

        return vResultValAmounts;
      end ValueAmountsSimulation;
    begin
      /*Initialisation des variables*/
      vFormulaAmounts.AmountLC  := 0;
      vFormulaAmounts.AmountFC  := 0;
      vCatValFormula            := pCatValFormula;
      vFormulaOperator          := '';
      vError                    := false;

      if (length(vCatValFormula) >= 1) then
        /*Parcours de la formule de pilotage caractèrepar caractère*/
        while not vError
         and (length(vCatValFormula) >= 1) loop
          vFormulaChar  := substr(vCatValFormula, 1, 1);

          if vFormulaChar = '[' then
            vFormulaChar    := substr(vCatValFormula, 2, 1);
            vCatValFormula  := substr(vCatValFormula, 4, length(vCatValFormula) - 3);
          else
            vCatValFormula  := substr(vCatValFormula, 2, length(vCatValFormula) - 1);
          end if;

          if vFormulaChar in('1', '2', '3', '4', '5') then
            /* Réception des montants d'amortissements calculés de l'immob pour la valeur gérée dont la catégorie
               est "Caractère"
            */
            if pSimulationId is null then
              vCatValAmounts  := ValueAmounts(pPeriodId, pFixedAssetsId, vFormulaChar);
            else
              vCatValAmounts  := ValueAmountsSimulation(pPeriodId, pFixedAssetsId, pSimulationId, vFormulaChar);
            end if;

            if vFormulaOperator in('-', '+', '*', '/') then
              if vFormulaOperator = '-' then
                vFormulaAmounts.AmountLC  := vFormulaAmounts.AmountLC - vCatValAmounts.AmountLC;
                vFormulaAmounts.AmountFC  := vFormulaAmounts.AmountFC - vCatValAmounts.AmountFC;
              elsif vFormulaOperator = '+' then
                vFormulaAmounts.AmountLC  := vFormulaAmounts.AmountLC + vCatValAmounts.AmountLC;
                vFormulaAmounts.AmountFC  := vFormulaAmounts.AmountFC + vCatValAmounts.AmountFC;
              elsif vFormulaOperator = '*' then
                vFormulaAmounts.AmountLC  := vFormulaAmounts.AmountLC * vCatValAmounts.AmountLC;
                vFormulaAmounts.AmountFC  := vFormulaAmounts.AmountFC * vCatValAmounts.AmountFC;
              elsif vFormulaOperator = '/' then
                begin
                  vFormulaAmounts.AmountLC  := vFormulaAmounts.AmountLC / vCatValAmounts.AmountLC;

                  if vCatValAmounts.AmountFC <> 0 then
                    vFormulaAmounts.AmountFC  := vFormulaAmounts.AmountFC / vCatValAmounts.AmountFC;
                  end if;
                exception
                  when zero_divide then
                    vError                    := true;
                    vFormulaAmounts.AmountLC  := 0;
                    vFormulaAmounts.AmountFC  := 0;
                end;
              end if;

              vFormulaOperator  := '';
            else
              vFormulaAmounts  := vCatValAmounts;
            end if;
          elsif vFormulaChar in('-', '+', '*', '/') then
            vFormulaOperator  := vFormulaChar;
          end if;
        end loop;
      else
        vFormulaAmounts  := pBaseAmounts;
      end if;

      return vFormulaAmounts;
    end ApplyFormulaAmounts;
  begin
    if not pSimCatalogId is null then
      DocumentId  := null;
      CatalogId   := pSimCatalogId;

      /*Recherche des champs sur la base de l'imputation passée en paramètre*/
      select IMP.FAM_FIXED_ASSETS_ID
           , C_FAM_TRANSACTION_TYP
           , IMP.ACS_PERIOD_ID
           , IMP.FAM_SIMULATION_ID
           , IMP.FIS_AMOUNT_LC_D - IMP.FIS_AMOUNT_LC_C
           , IMP.FIS_AMOUNT_FC_D - IMP.FIS_AMOUNT_FC_C
        into AssetsId
           , vSimTransactionType
           , vPeriodId
           , vSimulationId
           , vAmounts.AmountLC
           , vAmounts.AmountFC
        from FAM_IMP_SIMULATION IMP
       where IMP.FAM_IMP_SIMULATION_ID = aFAM_IMPUTATION_ID;

      /*Suppression des imputations comptables déjà existantes*/
      begin
        delete from FAM_ACT_IMP_SIMULATION
              where FAM_IMP_SIMULATION_ID = aFAM_IMPUTATION_ID;
      exception
        when others then
          null;
      end;
    else
      vSimTransactionType  := '';
      vSimulationId        := null;

      /*Recherche des champs sur la base de l'imputation passée en paramètre*/
      select IMP.FAM_FIXED_ASSETS_ID
           , IMP.ACS_PERIOD_ID
           , IMP.FIM_AMOUNT_LC_D - IMP.FIM_AMOUNT_LC_C
           , IMP.FIM_AMOUNT_FC_D - IMP.FIM_AMOUNT_FC_C
           , DOC.FAM_DOCUMENT_ID
           , DOC.FAM_CATALOGUE_ID
        into AssetsId
           , vPeriodId
           , vAmounts.AmountLC
           , vAmounts.AmountFC
           , DocumentId
           , CatalogId
        from FAM_DOCUMENT DOC
           , FAM_IMPUTATION IMP
       where IMP.FAM_IMPUTATION_ID = aFAM_IMPUTATION_ID
         and IMP.FAM_DOCUMENT_ID = DOC.FAM_DOCUMENT_ID;

      /*Suppression des imputations comptables déjà existantes*/
      begin
        delete from FAM_ACT_IMPUTATION
              where FAM_IMPUTATION_ID = aFAM_IMPUTATION_ID;
      exception
        when others then
          null;
      end;
    end if;

    FAM_TRANSACTIONS.InitAssetsAccounts(AssetsId
                                      , CatalogId
                                      , aFAM_MANAGED_VALUE_ID
                                      , aFAM_IMPUTATION_ID
                                      , aCreateValues
                                      , aInterest1
                                      , vSimTransactionType
                                      , vValImputations
                                      , vActImputations
                                       );

    if aCreateValues = 1 then   /*Demande de création des imputations valeurs*/
      for vValCounter in 1 .. vValImputations.count loop                                                    /*Parcours des valeurs gérées*/
                                                           /*Création imputations valeurs gérées*/
        FAM_TRANSACTIONS.CreateManValImputations(DocumentId
                                               , aFAM_IMPUTATION_ID
                                               , vValImputations(vValCounter).FAM_MANAGED_VALUE_ID
                                                );
      end loop;
    end if;

    /*Réceptionne la formule de pilotage à appliquer pour le catalogue et la valeur gérée*/
    vCatalogueValueFormula  := GetCatalogueValueFormula(CatalogId, vValImputations(1).FAM_MANAGED_VALUE_ID);

    /* La formule existe pour le catalogue / Valeur gérée =>  Applique les opérations au montant ... */
    /* pour les positions autres que intérêts */
    if    (pInterest)
       or (vCatalogueValueFormula is null) then
      vResultAmounts  := vAmounts;
    else
      vResultAmounts  := ApplyFormulaAmounts(vPeriodId, AssetsId, vCatalogueValueFormula, vAmounts, vSimulationId);
      /**
      * La formule s'appuie sur les montants non signés de FAM_CALC_AMORTIZATION....aussi il convient de de signer ce montant pour
      * que les montants des imputations soient du bon côté
      **/
      vResultAmounts.AmountLC  := vResultAmounts.AmountLC * -1;
      vResultAmounts.AmountFC  := vResultAmounts.AmountFC * -1;
    end if;

    /*Création des imputations comptables */
    for vActCounter in 1 .. vActImputations.count loop                                                             /*Parcours des comptes par valeur gérée */
                                                         /* Génération de l'imputation comptable uniquement si le type d'imputation est géré dans les comptes     */
      if FAM_TRANSACTIONS.ImpTypeExistbyAsset(vActImputations(vActCounter).C_FAM_IMPUTATION_TYP, AssetsId, CatalogId) then
        if not pSimCatalogId is null then
          /*Création imputation comptable */
          FAM_TRANSACTIONS.CreateManACTImpSimulation
                                                 (aFAM_IMPUTATION_ID
                                                , vActImputations(vActCounter).C_FAM_IMPUTATION_TYP   --Type d'imputation
                                                , vResultAmounts.AmountLC *
                                                  vActImputations(vActCounter).FIM_AMOUNT_LC_D   --Montant débit
                                                , vResultAmounts.AmountFC *
                                                  vActImputations(vActCounter).FIM_AMOUNT_LC_D   --Montant crédit
                                                , vActImputations(vActCounter).ACS_FINANCIAL_ACCOUNT_ID   --Comptes liés
                                                , vActImputations(vActCounter).ACS_DIVISION_ACCOUNT_ID
                                                , vActImputations(vActCounter).ACS_CPN_ACCOUNT_ID
                                                , vActImputations(vActCounter).ACS_CDA_ACCOUNT_ID
                                                , vActImputations(vActCounter).ACS_PF_ACCOUNT_ID
                                                , vActImputations(vActCounter).ACS_PJ_ACCOUNT_ID
                                                , vActImputations(vActCounter).DOC_RECORD_ID   --Dossier lié
                                                , vActImputations(vActCounter).PAC_PERSON_ID   --Personne liée
                                                , vActImputations(vActCounter).HRM_PERSON_ID   --Employé lié
                                                , vActImputations(vActCounter).GCO_GOOD_ID   --Bien lié
                                                 );
        else
          /*Création imputation comptable */
          FAM_TRANSACTIONS.InsertActImputation(DocumentId   --Document
                                             , vActImputations(vActCounter).ACS_FINANCIAL_ACCOUNT_ID   --Comptes liés
                                             , vActImputations(vActCounter).ACS_DIVISION_ACCOUNT_ID
                                             , vActImputations(vActCounter).ACS_CPN_ACCOUNT_ID
                                             , vActImputations(vActCounter).ACS_CDA_ACCOUNT_ID
                                             , vActImputations(vActCounter).ACS_PF_ACCOUNT_ID
                                             , vActImputations(vActCounter).ACS_PJ_ACCOUNT_ID
                                             , vActImputations(vActCounter).C_FAM_IMPUTATION_TYP   --Type d'imputation
                                             , aFAM_IMPUTATION_ID   --Imputation immob.
                                             , null
                                             , vResultAmounts.AmountLC *
                                               vActImputations(vActCounter).FIM_AMOUNT_LC_D   --Montant débit
                                             , vResultAmounts.AmountFC *
                                               vActImputations(vActCounter).FIM_AMOUNT_LC_D   --Montant crédit
                                             , vActImputations(vActCounter).DOC_RECORD_ID   --Dossier lié
                                             , vActImputations(vActCounter).PAC_PERSON_ID   --Personne liée
                                             , vActImputations(vActCounter).HRM_PERSON_ID   --Employé lié
                                             , vActImputations(vActCounter).GCO_GOOD_ID   --Bien lié
                                              );
        end if;
      end if;
    end loop;
  end Create_VAL_ACT_Imputations;

  /*
    Génération des imputations immobilisations pour le document donné
  */
  procedure GenerateDocumentFamImputation(
    pDocumentId    FAM_IMPUTATION.FAM_DOCUMENT_ID%type
  , pFixedAssetsId FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  )
  is
    /*Curseur de recherche des imformation du document et du catalogue lié*/
    cursor DocumentCursor(pDocumentId FAM_IMPUTATION.FAM_DOCUMENT_ID%type)
    is
      select DOC.*
           , CAT.C_FAM_TRANSACTION_TYP
           , CAT.FCA_DEBIT
           , CAT.FCA_KEY
        from FAM_DOCUMENT DOC
           , FAM_CATALOGUE CAT
       where DOC.FAM_DOCUMENT_ID = pDocumentId
         and CAT.FAM_CATALOGUE_ID = DOC.FAM_CATALOGUE_ID;

    /*Curseur de recherche des valeurs gérés par catalogue donné*/
    cursor CatManagedValueCursor(pFamCatalogueId FAM_DOCUMENT.FAM_CATALOGUE_ID%type)
    is
      select   VAL.FAM_MANAGED_VALUE_ID
          from FAM_CAT_MANAGED_VALUE CAT
             , FAM_MANAGED_VALUE VAL
         where CAT.FAM_CATALOGUE_ID = pFamCatalogueId
           and VAL.FAM_MANAGED_VALUE_ID = CAT.FAM_MANAGED_VALUE_ID
      order by VAL.C_VALUE_CATEGORY;

    vDocument        DocumentCursor%rowtype;   --Réceptionne les données du curseur des documents
    vManagedValue    CatManagedValueCursor%rowtype;   --Réceptionne les données des valeurs gérées
    vPatrimoyOutput  boolean;   --Indique si transaction est une transaction de sortie de patrimoine
    vPeriodId        FAM_IMPUTATION.ACS_PERIOD_ID%type;   --Période de la transaction
    vDateTransaction FAM_IMPUTATION.FIM_TRANSACTION_DATE%type;   --Date transaction
    vFamImputationId FAM_IMPUTATION.FAM_IMPUTATION_ID%type;   --Id position imputation du type du catalogue créée
    vImputationId    FAM_IMPUTATION.FAM_IMPUTATION_ID%type;   --Id position imputation "Sortie de patrimoine" créée
    vAmount_LCD      FAM_IMPUTATION.FIM_AMOUNT_LC_D%type;   --Montant imputation immob MB - Débit
    vAmount_LCC      FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;   --Montant imputation immob MB - Crédit
    vAmount_FCD      FAM_IMPUTATION.FIM_AMOUNT_LC_D%type;   --Montant imputation immob ME - Débit
    vAmount_FCC      FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;   --Montant imputation immob ME - Crédit
    vAmount          FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;   --Variable de réception du montant total des imputation par valeur gérée
    vDocAmount       FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;
    vAmountEUR       FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;
    vAmount_LC       FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;
    vFixCategId      FAM_IMPUTATION.FAM_FIXED_ASSETS_CATEG_ID%type;
    vExchangeRate    FAM_IMPUTATION.FIM_EXCHANGE_RATE%type;
    vBasePrice       FAM_IMPUTATION.FIM_BASE_PRICE%type;
  begin
    /*Réception des données du document courant*/
    open DocumentCursor(pDocumentId);

    fetch DocumentCursor
     into vDocument;

    /*Traitement ne se fait que pour un document valide*/
    if DocumentCursor%found then
      /*Suppression des imputations déjà existantes*/
      delete from FAM_IMPUTATION
            where FAM_DOCUMENT_ID = pDocumentId
              and FAM_FIXED_ASSETS_ID = pFixedAssetsId;

      vFixCategId    := FAM_FUNCTIONS.GetFixedAssetsCategory(pFixedAssetsId);

      /*Initialisation date de transaction*/
      /*Step 1 : Date du document si celle-ci est dans une période active de gestion de l'exercice du jouranl courant*/
      begin
        select trunc(vDocument.FDO_DOCUMENT_DATE)
          into vDateTransaction
          from ACS_PERIOD PER
             , FAM_JOURNAL JOU
         where JOU.FAM_JOURNAL_ID = vDocument.FAM_JOURNAL_ID
           and PER.ACS_FINANCIAL_YEAR_ID = JOU.ACS_FINANCIAL_YEAR_ID
           and trunc(vDocument.FDO_DOCUMENT_DATE) between trunc(PER.PER_START_DATE) and trunc(PER.PER_END_DATE)
           and C_STATE_PERIOD = 'ACT'
           and C_TYPE_PERIOD = '2'
           and rownum = 1;
      exception
        when no_data_found then
          begin
            /*Step 2 : Date début période de gestion active suivant la date du document*/
            select trunc(PER.PER_START_DATE)
              into vDateTransaction
              from ACS_PERIOD PER
                 , FAM_JOURNAL JOU
             where JOU.FAM_JOURNAL_ID = vDocument.FAM_JOURNAL_ID
               and PER.ACS_FINANCIAL_YEAR_ID = JOU.ACS_FINANCIAL_YEAR_ID
               and trunc(PER.PER_START_DATE) > trunc(vDocument.FDO_DOCUMENT_DATE)
               and C_STATE_PERIOD = 'ACT'
               and C_TYPE_PERIOD = '2'
               and rownum = 1;
          exception
            when no_data_found then
              begin
                /*Step 3 : Date début période de gestion active précédent la date du document*/
                select trunc(PER.PER_START_DATE)
                  into vDateTransaction
                  from ACS_PERIOD PER
                     , FAM_JOURNAL JOU
                 where JOU.FAM_JOURNAL_ID = vDocument.FAM_JOURNAL_ID
                   and PER.ACS_FINANCIAL_YEAR_ID = JOU.ACS_FINANCIAL_YEAR_ID
                   and trunc(PER.PER_START_DATE) < trunc(vDocument.FDO_DOCUMENT_DATE)
                   and C_STATE_PERIOD = 'ACT'
                   and C_TYPE_PERIOD = '2'
                   and rownum = 1;
              exception
                when others then
                  RAISE_APPLICATION_ERROR(-20001, 'No active period ');
              end;
          end;
      end;

      /*Initialisation période*/
      if not vDateTransaction is null then
        select nvl(PER.ACS_PERIOD_ID, 0)
          into vPeriodId
          from ACS_PERIOD PER
             , FAM_JOURNAL JOU
         where JOU.FAM_JOURNAL_ID = vDocument.FAM_JOURNAL_ID
           and PER.ACS_FINANCIAL_YEAR_ID = JOU.ACS_FINANCIAL_YEAR_ID
           and trunc(vDateTransaction) between trunc(PER.PER_START_DATE) and trunc(PER.PER_END_DATE)
           and C_STATE_PERIOD = 'ACT'
           and C_TYPE_PERIOD = '2';
      end if;

      /*Vérifie si une transaction de sortie de patrimoine*/
      vPatrimoyOutput   :=     vDocument.C_FAM_TRANSACTION_TYP >= '800'
                           and vDocument.C_FAM_TRANSACTION_TYP <= '899';
      /*
      * 1ère imputation correspondant au type de transaction du catalogue
      */
      vAmount_LCD       := 0;
      vAmount_LCC       := 0;
      vAmount_FCD       := 0;
      vAmount_FCC       := 0;
      vDocAmount        := abs(vDocument.FDO_AMOUNT);
      vBasePrice        := ACS_FUNCTION.GetBasePriceEUR(vDateTransaction, vDocument.ACS_FINANCIAL_CURRENCY_ID);

      /* Mise à jour du montant correspondant (débit / crédit) */
      if vDocument.ACS_FINANCIAL_CURRENCY_ID <> LocalCurrencyId then
        vExchangeRate          :=
        ACS_FUNCTION.CalcRateOfExchangeEUR(0
                                         , abs(vDocument.FDO_AMOUNT)
                                         , vDocument.ACS_FINANCIAL_CURRENCY_ID
                                         , vDateTransaction
                                         , vBasePrice
                                          );
        ACS_FUNCTION.ConvertAmount(vDocAmount
                                 , vDocument.ACS_FINANCIAL_CURRENCY_ID
                                 , LocalCurrencyId
                                 , vDateTransaction
                                 , vExchangeRate
                                 , vBasePrice
                                 , 1
                                 , vAmountEUR
                                 , vAmount_LC
                                 , 1
                                 );

        if vDocument.FCA_DEBIT = 1 then
          vAmount_FCD  := vDocAmount;
          vAmount_LCD  := vAmount_LC;
        else
          vAmount_FCC  := vDocAmount;
          vAmount_LCC  := vAmount_LC;
        end if;
      else
        if vDocument.FCA_DEBIT = 1 then
          vAmount_LCD  := vDocAmount;
        else
          vAmount_LCC  := vDocAmount;
        end if;
      end if;

      /*Création de la position d'imputation immobilisation*/
      vFamImputationId  :=
        InsertFamImputation(pDocumentId   --Document donné
                          , vDocument.FAM_JOURNAL_ID   --Journal document
                          , vPeriodId   --Période comprenant la date document
                          , vDocument.ACS_FINANCIAL_CURRENCY_ID  --Monnaie document
                          , LocalCurrencyId   --Monnaie de base
                          , pFixedAssetsId   --Immobilisation donné
                          , vFixCategId   --Catégorie immob
                          , vDocument.C_FAM_TRANSACTION_TYP   --Type de transaction du catalogue du document donné
                          , vDocument.FCA_KEY   --Libellé initialisé /défaut avec catalogue
                          , vDateTransaction   --Date transaction selon période
                          , vDocument.FDO_DOCUMENT_DATE   --Date valeur imputation = date document
                          , vAmount_LCD   --Montant document débit MB
                          , vAmount_LCC   --Montant document crédit MB
                          , vAmount_FCD   --Montant document débit ME
                          , vAmount_FCC   --Montant document crédit ME
                          , vExchangeRate
                          , vBasePrice
                          , 0
                           );

      /* Réception des valeurs gérées par le catalogue du document donné*/
      open CatManagedValueCursor(vDocument.FAM_CATALOGUE_ID);

      fetch CatManagedValueCursor
       into vManagedValue;

      while CatManagedValueCursor%found loop
        /*Génération des imputations valeurs pour chaque valeur gérée.....*/
        InsertValImputation(vManagedValue.FAM_MANAGED_VALUE_ID, vFamImputationId, pDocumentId);

        /*.... et Génération de 2 imputations immobilisation supplémentaires par valeur gérée si
        *  sortie de patrimoine
        */
        if vPatrimoyOutput then
          /*Réception montant par valeur géré*/
          vAmount        := FAM_TRANSACTIONS.GetTotalAmountByValue(pFixedAssetsId, vManagedValue.FAM_MANAGED_VALUE_ID, '100', '599');
          /* Mise à jour du montant correspondant (débit / crédit) */
          vAmount_LCD    := 0;
          vAmount_LCC    := 0;
          vAmount_FCD    := 0;
          vAmount_FCC    := 0;
          vAmountEUR     := 0;
          vAmount_LC     := 0;
          /* Mise à jour du montant correspondant (débit / crédit) */
          if vDocument.ACS_FINANCIAL_CURRENCY_ID <> LocalCurrencyId then
            vExchangeRate          :=
            ACS_FUNCTION.CalcRateOfExchangeEUR(0
                                             , vAmount
                                             , vDocument.ACS_FINANCIAL_CURRENCY_ID
                                             , vDateTransaction
                                             , vBasePrice
                                              );
            ACS_FUNCTION.ConvertAmount(vAmount
                                     , vDocument.ACS_FINANCIAL_CURRENCY_ID
                                     , LocalCurrencyId
                                     , vDateTransaction
                                     , vExchangeRate
                                     , vBasePrice
                                     , 1
                                     , vAmountEUR
                                     , vAmount_LC
                                     , 1
                                     );

            if vAmount < 0 then
              vAmount_FCD  := abs(vAmount);
              vAmount_LCD  := abs(vAmount_LC);
            else
              vAmount_FCC  := abs(vAmount);
              vAmount_LCC  := abs(vAmount_LC);
            end if;
          else
            if vAmount < 0 then
              vAmount_LCD  := abs(vAmount);
            else
              vAmount_LCC  := abs(vAmount);
            end if;
          end if;

          /*Imputation de type sortie de compte immob*/
          vImputationId  :=
            InsertFamImputation(pDocumentId   --Document donné
                              , vDocument.FAM_JOURNAL_ID   --Journal document
                              , vPeriodId   --Période comprenant la date document
                              , vDocument.ACS_FINANCIAL_CURRENCY_ID  --Monnaie document
                              , LocalCurrencyId   --Monnaie de base
                              , pFixedAssetsId   --Immobilisation donné
                              , vFixCategId   --Catégorie immob
                              , '599'   --Type de transaction imposé -> Sortie compte immob
                              , vDocument.FCA_KEY   --Libellé initialisé /défaut avec catalogue
                              , vDateTransaction   --Date transaction selon période
                              , vDocument.FDO_DOCUMENT_DATE   --Date valeur imputation = date document
                              , vAmount_LCD   --Montant document débit MB
                              , vAmount_LCC   --Montant document crédit MB
                              , vAmount_FCD   --Montant document débit ME
                              , vAmount_FCC   --Montant document crédit ME
                              , vExchangeRate
                              , vBasePrice
                              , 0
                               );
          /*Génération imputations valeurs pour chaque valeur gérée.....*/
          InsertValImputation(vManagedValue.FAM_MANAGED_VALUE_ID, vImputationId, pDocumentId);
          /*Réception montant par valeur géré*/
          vAmount        :=
                FAM_TRANSACTIONS.GetTotalAmountByValue(pFixedAssetsId, vManagedValue.FAM_MANAGED_VALUE_ID, '600', '699');
          /* Mise à jour du montant correspondant (débit / crédit) */
          vAmount_LCD    := 0;
          vAmount_LCC    := 0;
          vAmount_FCD    := 0;
          vAmount_FCC    := 0;

          /* Mise à jour du montant correspondant (débit / crédit) */
          if vDocument.ACS_FINANCIAL_CURRENCY_ID <> LocalCurrencyId then
            vExchangeRate          :=
            ACS_FUNCTION.CalcRateOfExchangeEUR(0
                                             , vAmount
                                             , vDocument.ACS_FINANCIAL_CURRENCY_ID
                                             , vDateTransaction
                                             , vBasePrice
                                              );
            ACS_FUNCTION.ConvertAmount(vAmount
                                     , vDocument.ACS_FINANCIAL_CURRENCY_ID
                                     , LocalCurrencyId
                                     , vDateTransaction
                                     , vExchangeRate
                                     , vBasePrice
                                     , 1
                                     , vAmountEUR
                                     , vAmount_LC
                                     , 1
                                     );

            if vAmount < 0 then
              vAmount_FCD  := abs(vAmount);
              vAmount_LCD  := abs(vAmount_LC);
            else
              vAmount_FCC  := abs(vAmount);
              vAmount_LCC  := abs(vAmount_LC);
            end if;
          else
            if vAmount < 0 then
              vAmount_LCD  := abs(vAmount);
            else
              vAmount_LCC  := abs(vAmount);
            end if;
          end if;
          /*Imputation de type sortie fonds amortissement*/
          vImputationId  :=
            InsertFamImputation(pDocumentId   --Document donné
                              , vDocument.FAM_JOURNAL_ID   --Journal document
                              , vPeriodId   --Période comprenant la date document
                              , vDocument.ACS_FINANCIAL_CURRENCY_ID  --Monnaie document
                              , LocalCurrencyId   --Monnaie de base
                              , pFixedAssetsId   --Immobilisation donné
                              , vFixCategId   --Catégorie immob
                              , '699'   --Type de transaction imposé -> Sortie fonds amortissement immobilisation
                              , vDocument.FCA_KEY   --Libellé initialisé /défaut avec catalogue
                              , vDateTransaction   --Date transaction selon période
                              , vDocument.FDO_DOCUMENT_DATE   --Date valeur imputation = date document
                              , vAmount_LCD   --Montant document débit MB
                              , vAmount_LCC   --Montant document crédit MB
                              , vAmount_FCD   --Montant document débit ME
                              , vAmount_FCC   --Montant document crédit ME
                              , vExchangeRate
                              , vBasePrice
                              , 0
                               );
          /*Génération imputations valeurs pour chaque valeur gérée.....*/
          InsertValImputation(vManagedValue.FAM_MANAGED_VALUE_ID, vImputationId, pDocumentId);
        end if;

        fetch CatManagedValueCursor
         into vManagedValue;
      end loop;

      close CatManagedValueCursor;
    end if;

    commit;
  end GenerateDocumentFamImputation;

  /**
  * Description
  *    Création d'une postion d'imputation immobilisation avec toutes les valeurs données
  */
  function InsertFamImputation(
    pDocumentId      FAM_IMPUTATION.FAM_DOCUMENT_ID%type
  , pJournalId       FAM_IMPUTATION.FAM_JOURNAL_ID%type
  , pPeriodId        FAM_IMPUTATION.ACS_PERIOD_ID%type
  , pCurrencyId      FAM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , pLocalCurrency   FAM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , pFixedAssetsId   FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , pFixCategId      FAM_IMPUTATION.FAM_FIXED_ASSETS_CATEG_ID%type
  , pTransactionType FAM_IMPUTATION.C_FAM_TRANSACTION_TYP%type
  , pDescription     FAM_IMPUTATION.FIM_DESCR%type
  , pDateTransaction FAM_IMPUTATION.FIM_TRANSACTION_DATE%type
  , pDateValue       FAM_IMPUTATION.FIM_VALUE_DATE%type
  , pAmountLCD       FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  , pAmountLCC       FAM_IMPUTATION.FIM_AMOUNT_LC_C%type
  , pAmountFCD       FAM_IMPUTATION.FIM_AMOUNT_FC_D%type
  , pAmountFCC       FAM_IMPUTATION.FIM_AMOUNT_FC_C%type
  , pExchangeRate    FAM_IMPUTATION.FIM_EXCHANGE_RATE%type
  , pBasePrice       FAM_IMPUTATION.FIM_BASE_PRICE%type
  , pAdjustment      FAM_IMPUTATION.FIM_ADJUSTMENT%type
  )
    return FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  is
    vImputationId FAM_IMPUTATION.FAM_IMPUTATION_ID%type;
  begin
    select init_id_seq.nextval
      into vImputationId
      from dual;

    insert into FAM_IMPUTATION
                (FAM_IMPUTATION_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , ACS_PERIOD_ID
               , FAM_JOURNAL_ID
               , FAM_FIXED_ASSETS_ID
               , FAM_FIXED_ASSETS_CATEG_ID
               , C_FAM_TRANSACTION_TYP
               , FIM_DESCR
               , FIM_TRANSACTION_DATE
               , FIM_VALUE_DATE
               , FIM_AMOUNT_LC_D
               , FIM_AMOUNT_LC_C
               , FIM_AMOUNT_FC_D
               , FIM_AMOUNT_FC_C
               , FIM_EXCHANGE_RATE
               , FIM_BASE_PRICE
               , FAM_DOCUMENT_ID
               , FIM_ADJUSTMENT
               , A_DATECRE
               , A_IDCRE
                )
         values (vImputationId
               , pCurrencyId   --Monnaie
               , pLocalCurrency   --Monnaie par défaut
               , pPeriodId   --Période
               , pJournalId   --Journal
               , pFixedAssetsId   --Immobilisation
               , pFixCategId   --Catégorie de l'immob
               , pTransactionType   --Type de transaction
               , pDescription   --Libellé imputation
               , pDateTransaction   --Date transaction
               , pDateValue   --Date valeur
               , pAmountLCD   --Montant débit
               , pAmountLCC   --Montant crédit
               , pAmountFCD   --Montant débit ME
               , pAmountFCC   --Montant crédit ME
               , pExchangeRate   --Taux de change
               , pBasePrice   --Diviseur
               , pDocumentId   --Document
               , pAdjustment   --Ajustement
               , sysdate
               , UserIni
                );

    return vImputationId;
  end InsertFamImputation;

  /**
  * Description  Création des imputations financières (FAM_ACT_IMPUTATION)
  */
  procedure GenerateActImputations(
    pDocumentId     FAM_IMPUTATION.FAM_DOCUMENT_ID%type
  , pDocCatId       FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  , pImputationId   FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  , pFixedAssetsId  FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , pTransactionTyp FAM_IMPUTATION.C_FAM_TRANSACTION_TYP%type
  , pManagedValId1  FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pManagedValId2  FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pManagedValId3  FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pManagedValId4  FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pManagedValId5  FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pVal1           number
  , pVal2           number
  , pVal3           number
  , pVal4           number
  , pVal5           number
  , pDebit          number
  , pAmountLCD      FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  , pAmountLCC      FAM_IMPUTATION.FIM_AMOUNT_LC_C%type
  , pAmountFCD      FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  , pAmountFCC      FAM_IMPUTATION.FIM_AMOUNT_LC_C%type
  )
  is
    vTransactionTyp        FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;
    vImputationTyp         FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type;
    vAdditionnalFamImpTyp  FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type;
    vManagedValueId        FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type;
    vImputationAmountLC    FAM_IMPUTATION.FIM_AMOUNT_LC_D%type;
    vImputationAmountFC    FAM_IMPUTATION.FIM_AMOUNT_FC_D%type;
    vTableActImputations   TableActImputations;
    vTableValImputations   TableValImputations;
    vManagedSubSets        SubSetAccount;
    vGenerateImp           number;
    vCpt                   number;
    vGenerateActImputation boolean                                        default false;
  begin
    vImputationAmountLC  := 0;
    vImputationAmountFC  := 0;

    /*Mise à jour des montants document avec l'imputation correspondant à celle du catalogue*/
    if     (pTransactionTyp <> '599')
       and (pTransactionTyp <> '699') then
      update FAM_DOCUMENT
         set FDO_AMOUNT =
               case
                 when acs_financial_currency_id = LocalCurrencyId then case
                 when pDebit = 1 then pAmountLCD
                 else pAmountLCC
               end
                 else case
                 when pDebit = 1 then pAmountFCD
                 else pAmountFCC
               end
               end
       where FAM_DOCUMENT_ID = pDocumentId;
    end if;

    /*Suppression des imputations comptables déjà existantes*/
    begin
      delete from FAM_ACT_IMPUTATION
            where FAM_IMPUTATION_ID = pImputationId;
    exception
      when others then
        null;
    end;

    vTableActImputations.delete;
    vTableValImputations.delete;
    /*Réception des sous-ensembles gérés*/
    vManagedSubSets      := FAM_TRANSACTIONS.GetManagedSubSets;
    /*Réception des types d'imputations à générer*/
    vTransactionTyp      :=
                         FAM_TRANSACTIONS.GetImputationType(pDocCatId, false, '', vImputationTyp, vAdditionnalFamImpTyp);
    /*Initialisation de la table des valeurs gérées*/
    vCpt                 := 1;

    for vValCounter in 1 .. 5 loop
      if vValCounter = 1 then
        vManagedValueId  := pManagedValId1;
        vGenerateImp     := pVal1;
      elsif vValCounter = 2 then
        vManagedValueId  := pManagedValId2;
        vGenerateImp     := pVal2;
      elsif vValCounter = 3 then
        vManagedValueId  := pManagedValId3;
        vGenerateImp     := pVal3;
      elsif vValCounter = 4 then
        vManagedValueId  := pManagedValId4;
        vGenerateImp     := pVal4;
      elsif vValCounter = 5 then
        vManagedValueId  := pManagedValId5;
        vGenerateImp     := pVal5;
      end if;

      if vGenerateImp = 1 then
        vTableValImputations(vCpt).FAM_MANAGED_VALUE_ID  := vManagedValueId;
        vCpt                                             := vCpt + 1;
      end if;
    end loop;

    if vImputationTyp is not null then   --test sur cette varaible car elle n'est pas initalisée dans la procédure pour les transaction 800 - 899
      InitActImpDatas(pFixedAssetsId, vImputationTyp, 1, vTableValImputations, vManagedSubSets, vTableActImputations);

      if     (vImputationTyp in(15, 16) )
         and (vTableActImputations(1).ACS_FINANCIAL_ACCOUNT_ID is null)
         and (vTableActImputations(1).ACS_CPN_ACCOUNT_ID is null) then
        vImputationTyp  := 11;
        InitActImpDatas(pFixedAssetsId, vImputationTyp, 1, vTableValImputations, vManagedSubSets, vTableActImputations);
      elsif     (vImputationTyp = 18)
            and (vTableActImputations(1).ACS_FINANCIAL_ACCOUNT_ID is null)
            and (vTableActImputations(1).ACS_CPN_ACCOUNT_ID is null) then
        vImputationTyp  := 12;
        InitActImpDatas(pFixedAssetsId, vImputationTyp, 1, vTableValImputations, vManagedSubSets, vTableActImputations);
      end if;

      if not vAdditionnalFamImpTyp is null then
        InitActImpDatas(pFixedAssetsId
                      , vAdditionnalFamImpTyp
                      , 2
                      , vTableValImputations
                      , vManagedSubSets
                      , vTableActImputations
                       );
      end if;
    /** Sortie de patrimoine **/
    elsif     vTransactionTyp >= '800'
          and vTransactionTyp <= '899' then
      if (pTransactionTyp = '599') then   --Sortie compte immobilisation
        InitActImpDatas(pFixedAssetsId, '10', 1, vTableValImputations, vManagedSubSets, vTableActImputations);
        InitActImpDatas(pFixedAssetsId, '60', 2, vTableValImputations, vManagedSubSets, vTableActImputations);
      elsif(pTransactionTyp = '699') then   --Sortie fonds amortissement immobilisation
        InitActImpDatas(pFixedAssetsId, '11', 1, vTableValImputations, vManagedSubSets, vTableActImputations);
        InitActImpDatas(pFixedAssetsId, '60', 2, vTableValImputations, vManagedSubSets, vTableActImputations);
      else
        InitActImpDatas(pFixedAssetsId, '13', 1, vTableValImputations, vManagedSubSets, vTableActImputations);
        InitActImpDatas(pFixedAssetsId, '70', 2, vTableValImputations, vManagedSubSets, vTableActImputations);
      end if;
    end if;

    /*
      2) si la valeur gérée gère le type d'imputation '10' :
         pour chaque imputation immob (599, 699, et 8xx) il faudra contrôler que la valeur gère soit les comptes des imputations de type '10', '11' ou '13' pour générer le 'couple' d'imputations nécessaires
         10 / 60 (si comptes 10 gérés)
         11 / 60 (si comptes 11 gérés)
         13 / 70 (si comptes 13 gérés)
    */
    for vValCounter in 1 .. vTableValImputations.count loop
      if not vGenerateActImputation then
        if vImputationTyp is not null then
          vGenerateActImputation  := ( vTransactionTyp >= '600' and vTransactionTyp <= '609') or
                                     (FAM_TRANSACTIONS.ImpTypeExistByValue(vImputationTyp
                                               , pFixedAssetsId
                                               , vTableValImputations(vValCounter).FAM_MANAGED_VALUE_ID
                                                ) = 1);
        elsif     vTransactionTyp >= '800'
              and vTransactionTyp <= '899' then
          if (pTransactionTyp = '599') then
            vGenerateActImputation  :=
              FAM_TRANSACTIONS.ImpTypeExistByValue('10'
                                                 , pFixedAssetsId
                                                 , vTableValImputations(vValCounter).FAM_MANAGED_VALUE_ID
                                                  ) = 1;
          elsif(pTransactionTyp = '699') then
            vGenerateActImputation  :=
              FAM_TRANSACTIONS.ImpTypeExistByValue('11'
                                                 , pFixedAssetsId
                                                 , vTableValImputations(vValCounter).FAM_MANAGED_VALUE_ID
                                                  ) = 1;
          else
            vGenerateActImputation  :=
              FAM_TRANSACTIONS.ImpTypeExistByValue('13'
                                                 , pFixedAssetsId
                                                 , vTableValImputations(vValCounter).FAM_MANAGED_VALUE_ID
                                                  ) = 1;
          end if;
        end if;
      end if;
    end loop;

    /*Création des imputations comptables */
    if vGenerateActImputation then
      for vActCounter in 1 .. vTableActImputations.count loop
        if FAM_TRANSACTIONS.ImpTypeExistbyAsset(vTableActImputations(vActCounter).C_FAM_IMPUTATION_TYP
                                              , pFixedAssetsId
                                              , pDocCatId
                                               ) then
          vImputationAmountLC  := pAmountLCD - pAmountLCC;
          vImputationAmountFC  := pAmountFCD - pAmountFCC;
          FAM_TRANSACTIONS.InsertActImputation
                                            (pDocumentId
                                           , vTableActImputations(vActCounter).ACS_FINANCIAL_ACCOUNT_ID   --Comptes liés
                                           , vTableActImputations(vActCounter).ACS_DIVISION_ACCOUNT_ID
                                           , vTableActImputations(vActCounter).ACS_CPN_ACCOUNT_ID
                                           , vTableActImputations(vActCounter).ACS_CDA_ACCOUNT_ID
                                           , vTableActImputations(vActCounter).ACS_PF_ACCOUNT_ID
                                           , vTableActImputations(vActCounter).ACS_PJ_ACCOUNT_ID
                                           , vTableActImputations(vActCounter).C_FAM_IMPUTATION_TYP   --Type d'imputation
                                           , pImputationId
                                           , null
                                           , vTableActImputations(vActCounter).FIM_AMOUNT_LC_D * vImputationAmountLC
                                           , vTableActImputations(vActCounter).FIM_AMOUNT_LC_D * vImputationAmountFC
                                           , vTableActImputations(vActCounter).DOC_RECORD_ID   --Dossier lié
                                           , vTableActImputations(vActCounter).PAC_PERSON_ID   --Personne liée
                                           , vTableActImputations(vActCounter).HRM_PERSON_ID   --Employé lié
                                           , vTableActImputations(vActCounter).GCO_GOOD_ID   --Bien lié
                                            );
        end if;
      end loop;
    end if;
  end GenerateActImputations;

  /*
    Génération / modification des imputations valeurs
  */
  procedure GenerateValImputations(
    pDocumentId    FAM_VAL_IMPUTATION.FAM_DOCUMENT_ID%type
  , pImputationId  FAM_VAL_IMPUTATION.FAM_IMPUTATION_ID%type
  , pManagedValId1 FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , pManagedValId2 FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , pManagedValId3 FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , pManagedValId4 FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , pManagedValId5 FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , pVal1          number
  , pVal2          number
  , pVal3          number
  , pVal4          number
  , pVal5          number
  )
  is
    cursor ExistingValImpCursor(
      pImpId    FAM_IMPUTATION.FAM_IMPUTATION_ID%type
    , pManValId FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
    )
    is
      select FAM_VAL_IMPUTATION_ID
        from FAM_VAL_IMPUTATION
       where FAM_IMPUTATION_ID = pImpId
         and FAM_MANAGED_VALUE_ID = pManValId;

    vManagedValueId FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type;
    vGenerateImp    number;
    vValImputation  FAM_VAL_IMPUTATION.FAM_VAL_IMPUTATION_ID%type;

    procedure DeleteValImputation(pManagedValueId FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type)
    is
    begin
      delete from FAM_VAL_IMPUTATION
            where FAM_DOCUMENT_ID = pDocumentId
              and FAM_IMPUTATION_ID = pImputationId
              and FAM_MANAGED_VALUE_ID = pManagedValueId;
    end DeleteValImputation;
  begin
    for vValCounter in 1 .. 5 loop
      if vValCounter = 1 then
        vManagedValueId  := pManagedValId1;
        vGenerateImp     := pVal1;
      elsif vValCounter = 2 then
        vManagedValueId  := pManagedValId2;
        vGenerateImp     := pVal2;
      elsif vValCounter = 3 then
        vManagedValueId  := pManagedValId3;
        vGenerateImp     := pVal3;
      elsif vValCounter = 4 then
        vManagedValueId  := pManagedValId4;
        vGenerateImp     := pVal4;
      elsif vValCounter = 5 then
        vManagedValueId  := pManagedValId5;
        vGenerateImp     := pVal5;
      end if;

      vValImputation  := null;

      open ExistingValImpCursor(pImputationId, vManagedValueId);

      fetch ExistingValImpCursor
       into vValImputation;

      close ExistingValImpCursor;

      if (vValImputation is null) then   --L'imputation n'existe pas
        if     (vGenerateImp = 1)
           and (vManagedValueId <> 0) then   --Demande de génération et Id existant
          InsertValImputation(vManagedValueId, pImputationId, pDocumentId);   --Création de l'imputation valeur
        end if;
      else   --L'imputation existe
        if vGenerateImp = 0 then   --Pas de génération demandée
          DeleteValImputation(vManagedValueId);
        end if;
      end if;
    end loop;
  end GenerateValImputations;

  /**
  * Description
  *    Retourne les type(s) d'imputation sur la base de l'Id du catalogue de transaction
  */
  function GetImputationType(
    pFamCatalogueId                FAM_CATALOGUE.FAM_CATALOGUE_ID%type
  , aInterest1                     boolean
  , pDefaultTransactionType        FAM_IMPUTATION.C_FAM_TRANSACTION_TYP%type default ''
  , pFamImpTyp              in out FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
  , pAdditionnalFamImpTyp   in out FAM_ACT_IMPUTATION.C_FAM_IMPUTATION_TYP%type
  )
    return FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type
  is
    vTransactionTyp FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;
  begin
    /*Recherche du type de transaction du catalogue*/
    if not pDefaultTransactionType is null then
      vTransactionTyp  := pDefaultTransactionType;
    else
      begin
        select C_FAM_TRANSACTION_TYP
          into vTransactionTyp
          from FAM_CATALOGUE
         where FAM_CATALOGUE_ID = pFamCatalogueId;
      exception
        when others then
          vTransactionTyp  := null;
      end;
    end if;

    if not vTransactionTyp is null then
      /*Initialisation des variables de retour selon le type de transaction du catalogue trouvé*/
      if     vTransactionTyp >= '100'
         and vTransactionTyp <= '149' then
        pFamImpTyp             := '10';
        pAdditionnalFamImpTyp  := '14';
      elsif     vTransactionTyp >= '150'
            and vTransactionTyp <= '179' then
        pFamImpTyp             := '10';
        pAdditionnalFamImpTyp  := '17';
      elsif     vTransactionTyp >= '200'
            and vTransactionTyp <= '249' then
        pFamImpTyp             := '10';
        pAdditionnalFamImpTyp  := '24';
      elsif     vTransactionTyp >= '250'
            and vTransactionTyp <= '299' then
        pFamImpTyp             := '10';
        pAdditionnalFamImpTyp  := '29';
      elsif vTransactionTyp = '300' then
        pFamImpTyp             := '10';
        pAdditionnalFamImpTyp  := '34';
      elsif vTransactionTyp = '350' then
        pFamImpTyp             := '10';
        pAdditionnalFamImpTyp  := '39';
      elsif     vTransactionTyp >= '600'
            and vTransactionTyp <= '609' then
        pFamImpTyp             := '11';
        pAdditionnalFamImpTyp  := '61';
      elsif     vTransactionTyp >= '610'
            and vTransactionTyp <= '619' then
        pFamImpTyp             := '12';
        pAdditionnalFamImpTyp  := '62';
      elsif     vTransactionTyp >= '650'
            and vTransactionTyp <= '659' then
        pFamImpTyp             := '15';
        pAdditionnalFamImpTyp  := '65';
      elsif vTransactionTyp = '660' then
        pFamImpTyp             := '16';
        pAdditionnalFamImpTyp  := '66';
      elsif vTransactionTyp = '670' then
        pFamImpTyp             := '18';
        pAdditionnalFamImpTyp  := '67';
      elsif vTransactionTyp = '700' then
        if aInterest1 then
          pFamImpTyp  := '63';
        else
          pFamImpTyp  := '64';
        end if;

        pAdditionnalFamImpTyp  := '';
      elsif     vTransactionTyp >= '800'
            and vTransactionTyp <= '899' then
        pFamImpTyp             := '';
        pAdditionnalFamImpTyp  := '';
      elsif     vTransactionTyp >= '900'
            and vTransactionTyp <= '949' then
        pFamImpTyp             := '68';
        pAdditionnalFamImpTyp  := '';
      elsif     vTransactionTyp >= '950'
            and vTransactionTyp <= '999' then
        pFamImpTyp             := '78';
        pAdditionnalFamImpTyp  := '';
      else
        pFamImpTyp             := '';
        pAdditionnalFamImpTyp  := '';
      end if;
    end if;

    return vTransactionTyp;
  end GetImputationType;

  /**
  * Description
  *    Retourne le montant par valeur géré pour une immobilisation dont les types de transaction
  *    sont compris dans les bornes données
  */
  function GetTotalAmountByValue(
    pFixedAssetsId  FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pManagedValueId FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pTypLimInf      FAM_IMPUTATION.C_FAM_TRANSACTION_TYP%type
  , pTypLimSup      FAM_IMPUTATION.C_FAM_TRANSACTION_TYP%type
  )
    return FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type
  is
    vResult FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;
  begin
    begin
      select nvl(sum(nvl(FTO_DEBIT_LC, 0) - nvl(FTO_CREDIT_LC, 0) ), 0)
        into vResult
        from FAM_TOTAL_BY_PERIOD
       where FAM_FIXED_ASSETS_ID = pFixedAssetsId
         and FAM_MANAGED_VALUE_ID = pManagedValueId
         and C_FAM_TRANSACTION_TYP >= pTypLimInf
         and C_FAM_TRANSACTION_TYP <= pTypLimSup;
    exception
      when no_data_found then
        vResult  := 0;
    end;

    return vResult;
  end GetTotalAmountByValue;

  /**
  * Description
  *     Création imputation(s) valeur(s) gérée(s) en fonction des valeurs gérées par catalogue
  **/
  procedure CreateValImputations(
    pFamDocumentId   FAM_IMPUTATION.FAM_DOCUMENT_ID%type
  , vFamImputationId FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  , pFamCatalogueId  FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  )
  is
    cursor CatManagedValueCursor
    is
      select FAM_MANAGED_VALUE_ID
        from FAM_CAT_MANAGED_VALUE
       where FAM_CATALOGUE_ID = pFamCatalogueId;

    vManagedValue CatManagedValueCursor%rowtype;
  begin
    open CatManagedValueCursor;

    fetch CatManagedValueCursor
     into vManagedValue;

    while CatManagedValueCursor%found loop
      InsertValImputation(vManagedValue.FAM_MANAGED_VALUE_ID, vFamImputationId, pFamDocumentId);

      fetch CatManagedValueCursor
       into vManagedValue;
    end loop;

    close CatManagedValueCursor;
  end CreateValImputations;

  /**
  * Description
  *    Création de l'imputation valeur avec les clés ètrangères données
  */
  procedure InsertValImputation(
    pManagedValueId  FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , pFamImputationId FAM_VAL_IMPUTATION.FAM_IMPUTATION_ID%type
  , pDocumentId      FAM_VAL_IMPUTATION.FAM_DOCUMENT_ID%type
  )
  is
  begin
    insert into FAM_VAL_IMPUTATION
                (FAM_VAL_IMPUTATION_ID
               , FAM_IMPUTATION_ID
               , FAM_MANAGED_VALUE_ID
               , FAM_DOCUMENT_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , pFamImputationId
               , pManagedValueId
               , pDocumentId
               , trunc(sysdate)
               , UserIni
                );
  end InsertValImputation;
-- Initialisation des variables pour la session
begin
  UserIni          := PCS.PC_I_LIB_SESSION.GetUserIni;
  LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
end FAM_TRANSACTIONS;
