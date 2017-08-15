--------------------------------------------------------
--  DDL for Package Body MGM_ACI_GENERATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MGM_ACI_GENERATION" 
is
  /**
  * Retour de la valeur d'initialisation du Libellé de l'imputation analytique
  **/
  function GetImputationDefaultLabel(pMgmDistributionId  MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type)
        return MGM_DISTRIBUTION.MDI_DESCRIPTION%type
  is
    vResult MGM_DISTRIBUTION.MDI_DESCRIPTION%type;
  begin
    /**
    * Retour du modèle de libellé lié au catalogue de la transaction du modèle de répartition
    * de la répartition donnée ou si non renseigné la description de la répartition courante.
    **/
    select decode (CAT.ACJ_DESCRIPTION_TYPE_ID,
                   NULL, MDI.MDI_DESCRIPTION,
                   DES.DES_DESCR)
    into vResult
    from MGM_DISTRIBUTION_MODEL MDM
        ,MGM_DISTRIBUTION MDI
        ,ACJ_JOB_TYPE_S_CATALOGUE TYP
	,ACJ_CATALOGUE_DOCUMENT CAT
	,ACJ_DESCRIPTION_TYPE DES
    where MDI.MGM_DISTRIBUTION_ID = pMgmDistributionId
      and MDM.MGM_DISTRIBUTION_MODEL_ID   = MDI.MGM_DISTRIBUTION_MODEL_ID
      and TYP.ACJ_JOB_TYPE_S_CATALOGUE_ID = MDM.ACJ_JOB_TYPE_S_CATALOGUE_ID
      and CAT.ACJ_CATALOGUE_DOCUMENT_ID   = TYP.ACJ_CATALOGUE_DOCUMENT_ID
      and DES.ACJ_DESCRIPTION_TYPE_ID(+)  = CAT.ACJ_DESCRIPTION_TYPE_ID;

    return vResult;
  end GetImputationDefaultLabel ;

  /**
  * Description  Intégration ACI  de la répartition donnée
  **/
  procedure DistributionToAci(pMgmDistributionId               MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                              pDocumentDate                    ACI_DOCUMENT.DOC_DOCUMENT_DATE%type,
                              pTransactionDate                 ACI_MGM_IMPUTATION.IMM_VALUE_DATE%type,
                              pValueDate                       ACI_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type,
                              pImpDescription                  ACI_MGM_IMPUTATION.IMM_DESCRIPTION%type
                             )

  is
    vDocumentId ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vImpBalance ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;
  begin
    /*Step 1 ...Génération document */
    vDocumentId := Generate_Aci_Document(pMgmDistributionId, /* Répartition                 */
                                         pDocumentDate,      /* Date document               */
                                         pTransactionDate    /* Date transaction imputation */
                                         );
    if not vDocumentId is null then
      /*Step 2 ...Génération document réussi ...création des imputations */
      Generate_Aci_Mgm_Imp(vDocumentId,          /* Document aci parent         */
                           pMgmDistributionId,   /* Répartition                 */
                           pImpDescription,      /* Description imputation      */
                           pTransactionDate,     /* Date transaction imputation */
                           pValueDate            /* Date valeur imputation      */
                           );
      /*Step 3 ...Mise à jour du montant du document avec les soldes de ses écritures */
      select sum(nvl(IMM_AMOUNT_LC_D,0) - nvl(IMM_AMOUNT_LC_C,0))
      into vImpBalance
      from  ACI_MGM_IMPUTATION
      where ACI_DOCUMENT_ID = vDocumentId;

      update ACI_DOCUMENT
      set DOC_TOTAL_AMOUNT_DC = vImpBalance
      where ACI_DOCUMENT_ID = vDocumentId;

      /*Step 4 ...Mise à jour de la table des statuts document */
      Generate_Aci_Doc_Status(vDocumentId,        /* Document aci parent         */
                              pMgmDistributionId  /* Répartition                 */
                              );

      /*Step 5 ...Mise à jour des informations ACI sur la table des répartitions */
      update MGM_DISTRIBUTION
      set PC_USER_ID             = PCS.PC_I_LIB_SESSION.GetUserId
        , MDI_ACI_TRANSFER_DATE  = sysdate
      where MGM_DISTRIBUTION_ID  = pMgmDistributionId;

    end if;
  end DistributionToAci;


  /**
  * Description  Création du document ACI selon paramètres
  **/
  function Generate_Aci_Document(pMgmDistributionId               MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                 pDocumentDate                    ACI_DOCUMENT.DOC_DOCUMENT_DATE%type,
                                 pTransactionDate                 ACI_MGM_IMPUTATION.IMM_VALUE_DATE%type
                                 ) return ACI_DOCUMENT.ACI_DOCUMENT_ID%type

  is
    vAciDocumentId   ACI_DOCUMENT.ACI_DOCUMENT_ID%type;           /*Réceptionne l'id du document ACI */
    vDocumentYearId  ACI_DOCUMENT.ACS_FINANCIAL_YEAR_ID%type;     /*Réceptionne id exercice de la date transaction */
    vDocumentYearNum ACI_DOCUMENT.FYE_NO_EXERCICE%type;           /*Réceptionne n° exercice de la date transaction */
  begin
    begin
      /*Réception de l'exercice financier selon date transaction*/
      begin
        select FYE_NO_EXERCICE, ACS_FINANCIAL_YEAR_ID
        into vDocumentYearNum,vDocumentYearId
        from ACS_FINANCIAL_YEAR
        where pTransactionDate between FYE_START_DATE  and FYE_END_DATE;
      exception
        when no_data_found then
          raise_application_error(-20001, PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_TRANSACTION_DATE_EXERCISE'));
      end;

      /*Réception d'un nouvel Id de document*/
      select ACI_ID_SEQ.NextVal
      into vAciDocumentId
      from dual;

      /* Création du document de l'interface */
      insert into ACI_DOCUMENT(
          ACI_DOCUMENT_ID
        , ACJ_JOB_TYPE_S_CATALOGUE_ID
        , C_INTERFACE_ORIGIN
        , C_INTERFACE_CONTROL
        , DOC_TOTAL_AMOUNT_DC
        , DOC_DOCUMENT_DATE
        , ACS_FINANCIAL_CURRENCY_ID
        , CURRENCY
        , ACS_FINANCIAL_YEAR_ID
        , FYE_NO_EXERCICE
        , C_STATUS_DOCUMENT
        , CAT_KEY
        , TYP_KEY
        , A_DATECRE
        , A_IDCRE)
      select
          vAciDocumentId
        , MDM.ACJ_JOB_TYPE_S_CATALOGUE_ID /* Lien du modèle de répartition de la répartition courante */
        , '3'                             /* "Autre" par défaut                                       */
        , '3'                             /* "A contrôler" par défaut                                 */
        , 0                               /* Mis à jour après création des imputations                */
        , pDocumentDate                   /* Date  document passé en paramètre                        */
        , LocalCurrencyId                 /* Id Monnaie de base                                       */
        , LocalCurrency                   /* Nom Monnaie de base                                      */
        , vDocumentYearId                 /* Exercice du document initialisé selon date transaction   */
        , vDocumentYearNum                /* N° exercice  "             "      "     "       "        */
        , 'PROV'                          /* Provisoire par défaut                                    */
        , CAT.CAT_KEY                     /* Clé du catalogue                                         */
        , JOB.TYP_KEY                     /* Clé du travail                                           */
        , SYSDATE                         /* Date création      -> Date système                       */
        , UserIni                         /* Id création        -> user                               */
      from MGM_DISTRIBUTION_MODEL MDM
          ,MGM_DISTRIBUTION DIS
          ,ACJ_JOB_TYPE_S_CATALOGUE TYP
          ,ACJ_CATALOGUE_DOCUMENT CAT
          ,ACJ_JOB_TYPE JOB
      where DIS.MGM_DISTRIBUTION_ID         = pMgmDistributionId
        and MDM.MGM_DISTRIBUTION_MODEL_ID   = DIS.MGM_DISTRIBUTION_MODEL_ID
        and TYP.ACJ_JOB_TYPE_S_CATALOGUE_ID = MDM.ACJ_JOB_TYPE_S_CATALOGUE_ID
        and CAT.ACJ_CATALOGUE_DOCUMENT_ID   = TYP.ACJ_CATALOGUE_DOCUMENT_ID
        and JOB.ACJ_JOB_TYPE_ID             = TYP.ACJ_JOB_TYPE_ID;
    exception
      when others then
        vAciDocumentId := null;
    end;

    return vAciDocumentId;
  end Generate_Aci_Document;


  /**
  * Description  Création des imputations liées au document
  *   sur la base de la répartition donnée
  **/
  procedure Generate_Aci_Mgm_Imp(pAciDocumentId      ACI_DOCUMENT.ACI_DOCUMENT_ID%type,                /* Document aci parent         */
                                 pMgmDistributionId  MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,        /* Répartition                 */
                                 pImpDescription     ACI_MGM_IMPUTATION.IMM_DESCRIPTION%type,          /* Description imputation      */
                                 pTransactionDate    ACI_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type,     /* Date transaction imputation */
                                 pValueDate          ACI_MGM_IMPUTATION.IMM_VALUE_DATE%type            /* Date valeur imputation      */
                                )

  is
    cursor curDistributionCursor
    is
       select 'O' SOURCE,
              NVL(pImpDescription,MDE.MDE_DESCRIPTION) MDE_DESCRIPTION,
              MDO.ACS_CDA_ACCOUNT_ID,
              NVL(MDO.ACS_ACS_CPN_ACCOUNT_ID, MDO.ACS_CPN_ACCOUNT_ID) ACS_CPN_ACCOUNT_ID,
              MDO.ACS_PF_ACCOUNT_ID,
              NULL ACS_PJ_ACCOUNT_ID,
              NVL (MDO.MDO_AMOUNT_D,0) AMOUNT_D,
              NVL (MDO.MDO_AMOUNT_C,0) AMOUNT_C,
              MDO.MGM_DISTRIBUTION_ORIGIN_ID
       from MGM_DISTRIBUTION_DETAIL MDD,
            MGM_DISTRIBUTION_ELEMENT MDE,
            MGM_DISTRIBUTION_ORIGIN MDO
       where MDD.MGM_DISTRIBUTION_ID         = pMgmDistributionId
         and MDO.MGM_DISTRIBUTION_DETAIL_ID  = MDD.MGM_DISTRIBUTION_DETAIL_ID
         and MDE.MGM_DISTRIBUTION_ELEMENT_ID = MDD.MGM_DISTRIBUTION_ELEMENT_ID
       union all
       select 'T' SOURCE,
              NVL(pImpDescription,MDE.MDE_DESCRIPTION) MDE_DESCRIPTION,
              MDT.ACS_CDA_ACCOUNT_ID,
              MDT.ACS_CPN_ACCOUNT_ID,
              MDT.ACS_PF_ACCOUNT_ID,
              MDT.ACS_PJ_ACCOUNT_ID,
              NVL (MDT.MDT_AMOUNT_D,0) AMOUNT_D,
              NVL (MDT.MDT_AMOUNT_C,0) AMOUNT_C,
              MDO.MGM_DISTRIBUTION_ORIGIN_ID
       from MGM_DISTRIBUTION_DETAIL MDD,
            MGM_DISTRIBUTION_ELEMENT MDE,
            MGM_DISTRIBUTION_ORIGIN MDO,
            MGM_DISTRIBUTION_TARGET MDT
       where MDD.MGM_DISTRIBUTION_ID         = pMgmDistributionId
         and MDO.MGM_DISTRIBUTION_DETAIL_ID  = MDD.MGM_DISTRIBUTION_DETAIL_ID
         and MDT.MGM_DISTRIBUTION_ORIGIN_ID  = MDO.MGM_DISTRIBUTION_ORIGIN_ID
         and MDE.MGM_DISTRIBUTION_ELEMENT_ID = MDD.MGM_DISTRIBUTION_ELEMENT_ID
       order by MGM_DISTRIBUTION_ORIGIN_ID, SOURCE;

    vcDistribution       curDistributionCursor%rowtype;                    /* Réceptionne les données du curseur            */
    vAciMgmImputationId  ACI_MGM_IMPUTATION.ACI_MGM_IMPUTATION_ID%type;    /* Réceptionne l'id de l'imputation              */
    vImpPeriodId         ACI_MGM_IMPUTATION.ACS_PERIOD_ID%type;            /* Réceptionne id période selon date transaction */
  begin
    select PER.ACS_PERIOD_ID
    into  vImpPeriodId
    from ACS_PERIOD PER
    where PER.C_TYPE_PERIOD = '2'
      and pTransactionDate between PER.PER_START_DATE and PER.PER_END_DATE;

    open curDistributionCursor;
    fetch curDistributionCursor into vcDistribution;
    while curDistributionCursor%found
    loop
      /* Réception d'un nouvel Id d'imputation */
      select ACI_ID_SEQ.NextVal into vAciMgmImputationId from dual;
      /* Création de l'imputation */
      insert into ACI_MGM_IMPUTATION (
          ACI_MGM_IMPUTATION_ID
        , ACI_DOCUMENT_ID
        , IMM_TYPE
        , IMM_GENRE
        , IMM_PRIMARY
        , IMM_DESCRIPTION
        , IMM_EXCHANGE_RATE
        , IMM_BASE_PRICE
        , IMM_AMOUNT_LC_D
        , IMM_AMOUNT_LC_C
        , IMM_VALUE_DATE
        , IMM_TRANSACTION_DATE
        , ACS_FINANCIAL_CURRENCY_ID
        , ACS_ACS_FINANCIAL_CURRENCY_ID
        , ACS_CDA_ACCOUNT_ID
        , ACS_CPN_ACCOUNT_ID
        , ACS_PF_ACCOUNT_ID
        , ACS_PJ_ACCOUNT_ID
        , ACS_PERIOD_ID
        , A_DATECRE
        , A_IDCRE)
      values (
          vAciMgmImputationId
        , pAciDocumentId                      /* Lien du document de l'interface                          */
        , 'MAN'                               /* */
        , 'STD'                               /* */
        , 0                                   /* */
        , vcDistribution.MDE_DESCRIPTION      /* Description par paramètre OU celle de l'élément de rép   */
        , 0                                   /* Valeur par défaut                                        */
        , 0                                   /* Valeur par défaut                                        */
        , vcDistribution.AMOUNT_D             /* Montant de la répartition                                */
        , vcDistribution.AMOUNT_C             /* Montant de la répartition                                */
        , pValueDate                          /* Date valeur initialisée par paramètre                    */
        , pTransactionDate                    /* Date transaction initialisée par paramètre               */
        , LocalCurrencyId                     /* les 2 monnaies sont initialisées avec...                 */
        , LocalCurrencyId                     /* ... la monnaie de base                                   */
        , vcDistribution.ACS_CDA_ACCOUNT_ID   /* Les différents axes analytiques sont repris...           */
        , vcDistribution.ACS_CPN_ACCOUNT_ID   /* ... de la répartition                                    */
        , vcDistribution.ACS_PF_ACCOUNT_ID
        , vcDistribution.ACS_PJ_ACCOUNT_ID
        , vImpPeriodId                        /* Période active contenant date transaction                */
        , SYSDATE                             /* Date création      -> Date système                       */
        , UserIni                             /* Id création        -> user                               */
        );

      fetch curDistributionCursor into vcDistribution;
    end loop;

  end Generate_Aci_Mgm_Imp;


  /**
  * Mise à jour de la table des statuts document
  **/
  procedure Generate_Aci_Doc_Status(pAciDocumentId      ACI_DOCUMENT.ACI_DOCUMENT_ID%type,                /* Document aci parent         */
                                    pMgmDistributionId  MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type         /* Répartition                 */
                                   )

  is
  begin
    /* Ajout du statut document */
    insert into ACI_DOCUMENT_STATUS(
        ACI_DOCUMENT_STATUS_ID
      , ACI_DOCUMENT_ID
      , C_ACI_FINANCIAL_LINK)
    select ACI_ID_SEQ.NextVal
          ,pAciDocumentId
          ,JOB.C_ACI_FINANCIAL_LINK
    from MGM_DISTRIBUTION_MODEL MDM
        ,MGM_DISTRIBUTION MDI
        ,ACJ_JOB_TYPE_S_CATALOGUE TYP
        ,ACJ_JOB_TYPE JOB
    where MDI.MGM_DISTRIBUTION_ID         = pMgmDistributionId
      and MDM.MGM_DISTRIBUTION_MODEL_ID   = MDI.MGM_DISTRIBUTION_MODEL_ID
      and TYP.ACJ_JOB_TYPE_S_CATALOGUE_ID = MDM.ACJ_JOB_TYPE_S_CATALOGUE_ID
      and JOB.ACJ_JOB_TYPE_ID             = TYP.ACJ_JOB_TYPE_ID;
  end Generate_Aci_Doc_Status;

begin
  UserIni         := PCS.PC_I_LIB_SESSION.GetUserIni;
  select ACS_FINANCIAL_CURRENCY_ID, CUR.CURRENCY
  into LocalCurrencyId, LocalCurrency
  from PCS.PC_CURR CUR, ACS_FINANCIAL_CURRENCY FIN
  where FIN.FIN_LOCAL_CURRENCY = 1
    and CUR.PC_CURR_ID         = FIN.PC_CURR_ID;
end MGM_ACI_GENERATION;
