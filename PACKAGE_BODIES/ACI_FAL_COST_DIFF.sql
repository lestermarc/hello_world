--------------------------------------------------------
--  DDL for Package Body ACI_FAL_COST_DIFF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_FAL_COST_DIFF" 
is
  cursor crPostCalculation
  is
--     select *
--       from dual;

  select   CDD.*
         , (select max(ACJ_JOB_TYPE_S_CATALOGUE_ID)
              from FAL_FINANCIAL_TRANSACTION FFT
             where FFT.C_FAL_TRANSACTION_TYPE = CDD.C_FAL_TRANSACTION_TYPE) as ACJ_JOB_TYPE_S_CATALOGUE_ID
         , row_number () over (partition by DOC_NUMBER, C_FAL_TRANSACTION_TYPE
                               order by DOC_NUMBER, C_FAL_TRANSACTION_TYPE) as ROWNUMBER -- valeur 1 sera l'imputation primaire
      from (select CDD.FAL_ELT_COST_DIFF_ID
                 , CDD.FAL_ELT_COST_DIFF_DET_ID
                 , CDD.C_FAL_ENTRY_KIND
                 , CDD.C_FAL_ENTRY_SIGN
                 , CDD.CDD_AMOUNT
                 , CDD.ACS_FINANCIAL_ACCOUNT_ID
                 , CDD.ACS_DIVISION_ACCOUNT_ID
                 , CDD.ACS_CPN_ACCOUNT_ID
                 , CDD.ACS_INITIAL_CPN_ACCOUNT_ID
                 , CDD.ACS_CDA_ACCOUNT_ID
                 , CDD.ACS_PF_ACCOUNT_ID
                 , CDD.ACS_PJ_ACCOUNT_ID
                 , CDD.ACS_QTY_UNIT_ID
                 , CDD.DOC_RECORD_ID
                 , CDD.FAM_FIXED_ASSETS_ID
                 , CDD.C_FAM_TRANSACTION_TYP
                 , CDD.GCO_GOOD_ID
                 , CDD.HRM_PERSON_ID
                 , CDD.PAC_PERSON_ID
                 , CDD.PAC_THIRD_ID
                 , CDD.DIC_IMP_FREE1_ID
                 , CDD.DIC_IMP_FREE2_ID
                 , CDD.DIC_IMP_FREE3_ID
                 , CDD.DIC_IMP_FREE4_ID
                 , CDD.DIC_IMP_FREE5_ID
                 , CDD.IMF_NUMBER
                 , CDD.IMF_NUMBER2
                 , CDD.IMF_NUMBER3
                 , CDD.IMF_NUMBER4
                 , CDD.IMF_NUMBER5
                 , CDD.IMF_TEXT1
                 , CDD.IMF_TEXT2
                 , CDD.IMF_TEXT3
                 , CDD.IMF_TEXT4
                 , CDD.IMF_TEXT5
                 , CTD.DOC_NUMBER
                 , CTD.CTD_VALUE_DATE
                 , CTD.CTD_DESCRIPTION
                 , case
                     when to_number(CDD.C_FAL_ENTRY_KIND) in(10, 11) then '30'
                     when to_number(CDD.C_FAL_ENTRY_KIND) >= 30 then '40'
                     else '0'
                   end C_FAL_TRANSACTION_TYPE
              from FAL_ELT_COST_DIFF_DET CDD
                 , FAL_ELT_COST_DIFF CTD
             where CTD.FAL_ELT_COST_DIFF_ID = CDD.FAL_ELT_COST_DIFF_ID
               and CDD.ACI_DOCUMENT_ID is null) CDD
  order by CDD.DOC_NUMBER
         , CDD.C_FAL_TRANSACTION_TYPE;

  type TTblFAL_ELT_COST_DIFF_DET is table of crPostCalculation%rowtype
    index by binary_integer;

  type TCatProperties is record(
    CatKey                 ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type                     := ''
  , TypKey                 ACJ_JOB_TYPE.TYP_KEY%type                               := ''
  , CAciFinancialLink      ACJ_JOB_TYPE.C_ACI_FINANCIAL_LINK%type                  := ''
  , CTypCat                ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type            := ''
  , WithAcc                signtype                                                := 0
  , WithMgm                signtype                                                := 0
  , AcjJobTypeId           ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type                       := 0
  , AcjCatalogueDocumentId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type   := 0
  );

  -- Valeurs à comparer pour créer un nouveau document
  type TCompareCalculation is record(
    DocNumber           ACI_DOCUMENT.DOC_NUMBER%type                            := ''
  , CFalTransactionType FAL_FINANCIAL_TRANSACTION.C_FAL_TRANSACTION_TYPE%type   := ''
  );

  gLocalCurrencyName PCS.PC_CURR.CURRENCY%type;
  gLocalCurrencyId   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;

  /* Description
    * Get - Set de la variable globale
  */
  procedure SetLocalCurrencies
  is
  begin
    gLocalCurrencyName  := ACS_FUNCTION.GetLocalCurrencyName;
    gLocalCurrencyId    := ACS_FUNCTION.GetLocalCurrencyId;
  end SetLocalCurrencies;

  function GetLocalCurrencyName
    return PCS.PC_CURR.CURRENCY%type
  is
  begin
    return gLocalCurrencyName;
  end GetLocalCurrencyName;

  function GetLocalCurrencyId
    return ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  is
  begin
    return gLocalCurrencyId;
  end GetLocalCurrencyId;

  /* Description
    * Recherche des propriétés du catalogue + modèle
  */
  procedure InitialiseCatProperties(
    aACJ_JOB_TYPE_S_CATALOGUE_ID in            ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type
  , aCatProps                    in out nocopy TCatProperties
  )
  is
  begin
    select SCA.ACJ_CATALOGUE_DOCUMENT_ID
         , SCA.ACJ_JOB_TYPE_ID
         , CAT.C_TYPE_CATALOGUE
         , CAT.CAT_KEY
         , TYP.TYP_KEY
         , TYP.C_ACI_FINANCIAL_LINK
      into aCatProps.AcjCatalogueDocumentId
         , aCatProps.AcjJobTypeId
         , aCatProps.CTypCat
         , aCatProps.CatKey
         , aCatProps.TypKey
         , aCatProps.CAciFinancialLink
      from ACJ_JOB_TYPE_S_CATALOGUE SCA
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACJ_JOB_TYPE TYP
     where SCA.ACJ_JOB_TYPE_S_CATALOGUE_ID = aACJ_JOB_TYPE_S_CATALOGUE_ID
       and SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
       and SCA.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID;

    for tplSubSetCat in (select SCA.C_SUB_SET
                           from ACJ_SUB_SET_CAT SCA
                          where SCA.ACJ_CATALOGUE_DOCUMENT_ID = aCatProps.AcjCatalogueDocumentId
                            and SCA.C_SUB_SET in('ACC', 'CPN') ) loop
      if tplSubSetCat.C_SUB_SET = 'CPN' then
        aCatProps.WithMgm  := 1;
      elsif tplSubSetCat.C_SUB_SET = 'ACC' then
        aCatProps.WithAcc  := 1;
      end if;
    end loop;
  end InitialiseCatProperties;

  /*
  * Description
    * Création du statut du document selon le modèle de travail
  */
  procedure CreateDocumentStatus(
    aACI_DOCUMENT_ID      in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aC_ACI_FINANCIAL_LINK in ACJ_JOB_TYPE.C_ACI_FINANCIAL_LINK%type
  )
  is
  begin
    if aACI_DOCUMENT_ID > 0 then
      insert into ACI_DOCUMENT_STATUS
                  (ACI_DOCUMENT_STATUS_ID
                 , ACI_DOCUMENT_ID
                 , C_ACI_FINANCIAL_LINK
                  )
           values (ACI_ID_SEQ.nextval
                 , aACI_DOCUMENT_ID
                 , aC_ACI_FINANCIAL_LINK
                  );
    end if;
  end CreateDocumentStatus;

  /*
  * Description
    * Finalisation du document (montant total, document statut)
  */
  procedure FinaliseDocument(aACI_DOCUMENT_ID in ACI_DOCUMENT.ACI_DOCUMENT_ID%type, aCatProperties in TCatProperties)
  is
    vTotalAmount ACI_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
  begin
    if aACI_DOCUMENT_ID > 0 then
      -- Mise à jour du montant total du document
      if aCatProperties.WithAcc > 0 then
        select sum(IMF_AMOUNT_LC_D)
          into vTotalAmount
          from ACI_FINANCIAL_IMPUTATION
         where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;
      else
        select sum(IMM_AMOUNT_LC_D)
          into vTotalAmount
          from ACI_MGM_IMPUTATION
         where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;
      end if;

      update ACI_DOCUMENT
         set DOC_TOTAL_AMOUNT_DC = vTotalAmount
       where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

      CreateDocumentStatus(aACI_DOCUMENT_ID, aCatProperties.CAciFinancialLink);
    end if;
  end FinaliseDocument;

  /*
  * Description
    * Création des imputations analytiques
  */
  procedure CreateMgmImputation(
    aACI_DOCUMENT_ID             in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPostCalc                    in crPostCalculation%rowtype
  , aCatProperties               in TCatProperties
  , aACI_FINANCIAL_IMPUTATION_ID in ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type
  )
  is
    vCurrencyName PCS.PC_CURR.CURRENCY%type;
    vCurrencyId   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    vCurrencyName  := GetLocalCurrencyName;
    vCurrencyId    := GetLocalCurrencyId;

    insert into ACI_MGM_IMPUTATION
                (ACI_MGM_IMPUTATION_ID
               , ACI_DOCUMENT_ID
               , ACI_FINANCIAL_IMPUTATION_ID
               , IMM_TYPE
               , IMM_GENRE
               , IMM_PRIMARY
               , IMM_DESCRIPTION
               , IMM_VALUE_DATE
               , IMM_TRANSACTION_DATE
               , ACS_PERIOD_ID
               , PER_NO_PERIOD
               , ACS_ACS_FINANCIAL_CURRENCY_ID   -- MB
               , CURRENCY2
               , IMM_AMOUNT_LC_D
               , IMM_AMOUNT_LC_C
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY1
               , IMM_EXCHANGE_RATE   -- ME
               , IMM_BASE_PRICE
               , IMM_AMOUNT_FC_D
               , IMM_AMOUNT_FC_C
               , IMM_AMOUNT_EUR_D
               , IMM_AMOUNT_EUR_C
               , IMM_QUANTITY_D
               , IMM_QUANTITY_C
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_QTY_UNIT_ID
               , DOC_RECORD_ID
               , FAM_FIXED_ASSETS_ID
               , C_FAM_TRANSACTION_TYP
               , GCO_GOOD_ID
               , HRM_PERSON_ID
               , PAC_PERSON_ID
               , DIC_IMP_FREE1_ID
               , DIC_IMP_FREE2_ID
               , DIC_IMP_FREE3_ID
               , DIC_IMP_FREE4_ID
               , DIC_IMP_FREE5_ID
               , IMM_NUMBER
               , IMM_NUMBER2
               , IMM_NUMBER3
               , IMM_NUMBER4
               , IMM_NUMBER5
               , IMM_TEXT1
               , IMM_TEXT2
               , IMM_TEXT3
               , IMM_TEXT4
               , IMM_TEXT5
               , A_DATECRE
               , A_IDCRE
                )
         values (ACI_ID_SEQ.nextval
               , aACI_DOCUMENT_ID
               , aACI_FINANCIAL_IMPUTATION_ID
               , 'MAN'
               , 'STD'
               , 0
               , aPostCalc.CTD_DESCRIPTION
               , aPostCalc.CTD_VALUE_DATE
               , aPostCalc.CTD_VALUE_DATE
               , (select ACS_PERIOD_ID
                    from ACS_PERIOD
                   where aPostCalc.CTD_VALUE_DATE between PER_START_DATE and PER_END_DATE)
               , (select PER_NO_PERIOD
                    from ACS_PERIOD
                   where aPostCalc.CTD_VALUE_DATE between PER_START_DATE and PER_END_DATE)
               , vCurrencyId
               , vCurrencyName
               , case
                   when aPostCalc.C_FAL_ENTRY_SIGN = 0 then aPostCalc.CDD_AMOUNT
                   else 0
                 end   -- Montants MB
               , case
                   when aPostCalc.C_FAL_ENTRY_SIGN = 1 then aPostCalc.CDD_AMOUNT
                   else 0
                 end
               , vCurrencyId
               , vCurrencyName
               , 0   -- Taux de change
               , 0
               , 0   -- Montants en ME
               , 0
               , 0
               , 0
               , 0   -- Quantités
               , 0
               , aPostCalc.ACS_CPN_ACCOUNT_ID
               , aPostCalc.ACS_CDA_ACCOUNT_ID
               , aPostCalc.ACS_PF_ACCOUNT_ID
               , aPostCalc.ACS_PJ_ACCOUNT_ID
               , aPostCalc.ACS_QTY_UNIT_ID
               , aPostCalc.DOC_RECORD_ID
               , aPostCalc.FAM_FIXED_ASSETS_ID
               , aPostCalc.C_FAM_TRANSACTION_TYP
               , aPostCalc.GCO_GOOD_ID
               , aPostCalc.HRM_PERSON_ID
               , aPostCalc.PAC_PERSON_ID
               , aPostCalc.DIC_IMP_FREE1_ID
               , aPostCalc.DIC_IMP_FREE2_ID
               , aPostCalc.DIC_IMP_FREE3_ID
               , aPostCalc.DIC_IMP_FREE4_ID
               , aPostCalc.DIC_IMP_FREE5_ID
               , aPostCalc.IMF_NUMBER
               , aPostCalc.IMF_NUMBER2
               , aPostCalc.IMF_NUMBER3
               , aPostCalc.IMF_NUMBER4
               , aPostCalc.IMF_NUMBER5
               , aPostCalc.IMF_TEXT1
               , aPostCalc.IMF_TEXT2
               , aPostCalc.IMF_TEXT3
               , aPostCalc.IMF_TEXT4
               , aPostCalc.IMF_TEXT5
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end CreateMgmImputation;

  /*
  * Description
    * Création des imputations financières
  */
  procedure CreateImputations(
    aAciDocumentId in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPostCalc      in crPostCalculation%rowtype
  , aCatProperties in TCatProperties
  )
  is
    vFinImpId     ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type   := null;
    vCurrencyName PCS.PC_CURR.CURRENCY%type;
    vCurrencyId   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if aCatProperties.WithAcc > 0 then
      select ACI_ID_SEQ.nextval
        into vFinImpId
        from dual;

      vCurrencyName  := GetLocalCurrencyName;
      vCurrencyId    := GetLocalCurrencyId;

      insert into ACI_FINANCIAL_IMPUTATION
                  (ACI_FINANCIAL_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , IMF_TYPE
                 , IMF_GENRE
                 , IMF_PRIMARY
                 , IMF_DESCRIPTION
                 , IMF_VALUE_DATE
                 , IMF_TRANSACTION_DATE
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , ACS_ACS_FINANCIAL_CURRENCY_ID   -- MB
                 , CURRENCY2
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_LC_C
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , IMF_EXCHANGE_RATE   -- ME
                 , IMF_BASE_PRICE
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_FC_C
                 , IMF_AMOUNT_EUR_D
                 , IMF_AMOUNT_EUR_C
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , DOC_RECORD_ID
                 , FAM_FIXED_ASSETS_ID
                 , C_FAM_TRANSACTION_TYP
                 , GCO_GOOD_ID
                 , HRM_PERSON_ID
                 , PAC_PERSON_ID
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , IMF_NUMBER
                 , IMF_NUMBER2
                 , IMF_NUMBER3
                 , IMF_NUMBER4
                 , IMF_NUMBER5
                 , IMF_TEXT1
                 , IMF_TEXT2
                 , IMF_TEXT3
                 , IMF_TEXT4
                 , IMF_TEXT5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vFinImpId
                 , aAciDocumentId
                 , 'MAN'
                 , 'STD'
                 , case
                     when aPostCalc.ROWNUMBER > 1 then 0
                     else 1
                   end
                 , aPostCalc.CTD_DESCRIPTION
                 , aPostCalc.CTD_VALUE_DATE
                 , aPostCalc.CTD_VALUE_DATE
                 , (select ACS_PERIOD_ID
                      from ACS_PERIOD
                     where aPostCalc.CTD_VALUE_DATE between PER_START_DATE and PER_END_DATE)
                 , (select PER_NO_PERIOD
                      from ACS_PERIOD
                     where aPostCalc.CTD_VALUE_DATE between PER_START_DATE and PER_END_DATE)
                 , vCurrencyId
                 , vCurrencyName
                 , case
                     when aPostCalc.C_FAL_ENTRY_SIGN = 0 then aPostCalc.CDD_AMOUNT
                     else 0
                   end   -- Montants MB
                 , case
                     when aPostCalc.C_FAL_ENTRY_SIGN = 1 then aPostCalc.CDD_AMOUNT
                     else 0
                   end
                 , vCurrencyId
                 , vCurrencyName
                 , 0   -- Taux de change
                 , 0
                 , 0   -- Montants en ME
                 , 0
                 , 0
                 , 0
                 , aPostCalc.ACS_FINANCIAL_ACCOUNT_ID
                 , aPostCalc.ACS_DIVISION_ACCOUNT_ID
                 , aPostCalc.DOC_RECORD_ID
                 , aPostCalc.FAM_FIXED_ASSETS_ID
                 , aPostCalc.C_FAM_TRANSACTION_TYP
                 , aPostCalc.GCO_GOOD_ID
                 , aPostCalc.HRM_PERSON_ID
                 , aPostCalc.PAC_PERSON_ID
                 , aPostCalc.DIC_IMP_FREE1_ID
                 , aPostCalc.DIC_IMP_FREE2_ID
                 , aPostCalc.DIC_IMP_FREE3_ID
                 , aPostCalc.DIC_IMP_FREE4_ID
                 , aPostCalc.DIC_IMP_FREE5_ID
                 , aPostCalc.IMF_NUMBER
                 , aPostCalc.IMF_NUMBER2
                 , aPostCalc.IMF_NUMBER3
                 , aPostCalc.IMF_NUMBER4
                 , aPostCalc.IMF_NUMBER5
                 , aPostCalc.IMF_TEXT1
                 , aPostCalc.IMF_TEXT2
                 , aPostCalc.IMF_TEXT3
                 , aPostCalc.IMF_TEXT4
                 , aPostCalc.IMF_TEXT5
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    --Création de l'imputation analytique
    if aCatProperties.WithMgm > 0 then
      CreateMgmImputation(aAciDocumentId, aPostCalc, aCatProperties, vFinImpId);
    end if;
  end CreateImputations;

  /*
  * Description
    * Création du document
    * @return ACI_DOCUMENT.ACI_DOCUMENT_ID ID du document créé
  */
  function CreateDocument(aPostCalc in crPostCalculation%rowtype, aCatProperties in TCatProperties)
    return ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  is
    vResult       ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vCurrencyName PCS.PC_CURR.CURRENCY%type;
    vCurrencyId   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    select ACI_ID_SEQ.nextval
      into vResult
      from dual;

    vCurrencyName  := GetLocalCurrencyName;
    vCurrencyId    := GetLocalCurrencyId;

    insert into ACI_DOCUMENT
                (ACI_DOCUMENT_ID
               , ACJ_JOB_TYPE_S_CATALOGUE_ID
               , DOC_NUMBER
               , DOC_GRP_KEY
               , C_INTERFACE_ORIGIN
               , C_INTERFACE_CONTROL
               , DOC_TOTAL_AMOUNT_DC
               , DOC_DOCUMENT_DATE
               , C_STATUS_DOCUMENT
               , CAT_KEY
               , TYP_KEY
               , FYE_NO_EXERCICE
               , ACS_FINANCIAL_YEAR_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , VAT_CURRENCY
               , A_DATECRE
               , A_IDCRE
                )
         values (vResult
               , aPostCalc.ACJ_JOB_TYPE_S_CATALOGUE_ID
               , aPostCalc.DOC_NUMBER
               , aPostCalc.DOC_NUMBER   --DOC_GRP_KEY
               , '4'
               , '3'
               , 0   -- est mis à jour à la fin du traitement, lors de la création de ACI_DOCUMENT_STATUS
               , aPostCalc.CTD_VALUE_DATE
               , 'DEF'
               , aCatProperties.CatKey
               , aCatProperties.TypKey
               , (select FYE_NO_EXERCICE
                    from ACS_FINANCIAL_YEAR
                   where aPostCalc.CTD_VALUE_DATE between FYE_START_DATE and FYE_END_DATE)
               , (select ACS_FINANCIAL_YEAR_ID
                    from ACS_FINANCIAL_YEAR
                   where aPostCalc.CTD_VALUE_DATE between FYE_START_DATE and FYE_END_DATE)
               , vCurrencyId
               , vCurrencyName
               , vCurrencyId
               , vCurrencyName
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return vResult;
  end CreateDocument;

  /*
  * Description
    * Intégration des données de post-calculation prod. (coûts standards / écarts) dans l'interface finance
  */
  procedure IntegratePostCalculation
  is
    vRefPostCalc    TTblFAL_ELT_COST_DIFF_DET;
    vCreateDocument boolean                             := true;
    vAciDocumentId  ACI_DOCUMENT.ACI_DOCUMENT_ID%type   := 0;
    vCatProperties  TCatProperties;
    vPrecCalc       TCompareCalculation;
  begin
    SetLocalCurrencies;   -- Initialisation des variables globales

    open crPostCalculation;

    loop
      fetch crPostCalculation
      bulk collect into vRefPostCalc limit 10000;

      exit when vRefPostCalc.count < 1;
      vPrecCalc.DocNumber            := '';
      vPrecCalc.CFalTransactionType  := '';

      for vRefIndex in vRefPostCalc.first .. vRefPostCalc.last loop
        vCreateDocument                :=
             nvl(vPrecCalc.DocNumber, ' ') <> nvl(vRefPostCalc(vRefIndex).DOC_NUMBER, ' ')
          or nvl(vPrecCalc.CFalTransactionType, ' ') <> nvl(vRefPostCalc(vRefIndex).C_FAL_TRANSACTION_TYPE, ' ');

        if vCreateDocument then
          -- Avant de créer un nouveau document, il faut terminer le document précédant (montant total, status, etc...)
          FinaliseDocument(vAciDocumentId, vCatProperties);   -- 1er passage vAciDocumentId = 0 donc aucun traitement ne sera fait dans FinaliseDocument
          InitialiseCatProperties(vRefPostCalc(vRefIndex).ACJ_JOB_TYPE_S_CATALOGUE_ID, vCatProperties);
          vAciDocumentId  := CreateDocument(vRefPostCalc(vRefIndex), vCatProperties);
        end if;

        CreateImputations(vAciDocumentId, vRefPostCalc(vRefIndex), vCatProperties);
        -- Mise à jour de FAL_ELT_COST_DIFF_DET.ACI_DOCUMENT_ID avec le document ACI créé
        update FAL_ELT_COST_DIFF_DET
           set ACI_DOCUMENT_ID = vAciDocumentId
         where FAL_ELT_COST_DIFF_DET_ID = vRefPostCalc(vRefIndex).FAL_ELT_COST_DIFF_DET_ID;

        -- Sauvegarder les valeurs pour les comparer avec celles de l'enregistrement suivant
        vPrecCalc.DocNumber            := vRefPostCalc(vRefIndex).DOC_NUMBER;
        vPrecCalc.CFalTransactionType  := vRefPostCalc(vRefIndex).C_FAL_TRANSACTION_TYPE;
      end loop;
    end loop;

    FinaliseDocument(vAciDocumentId, vCatProperties);

    close crPostCalculation;
  end IntegratePostCalculation;
end ACI_FAL_COST_DIFF;
