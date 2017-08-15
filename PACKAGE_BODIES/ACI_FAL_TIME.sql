--------------------------------------------------------
--  DDL for Package Body ACI_FAL_TIME
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_FAL_TIME" 
is
  /**
  *   Réinitialisation des montants cumulés utilisés lors de l'insertion d'une imputation financière
  */
  procedure InitFinAmounts(
    aAmountAdjOper  in out TSumAmounts
  , aAmountAdjMach  in out TSumAmounts
  , aAmountWorkOper in out TSumAmounts
  , aAmountWorkMach in out TSumAmounts
  )
  is
  begin
    aAmountAdjOper.vLC   := 0;
    aAmountAdjMach.vLC   := 0;
    aAmountWorkOper.vLC  := 0;
    aAmountWorkMach.vLC  := 0;
  end InitFinAmounts;

  /**
  *   Réinitialisation des montants cumulés utilisés lors de l'insertion d'une imputation analytique
  */
  procedure InitMgmAmounts(
    aAmountAdjOper  in out TSumAmounts
  , aAmountAdjMach  in out TSumAmounts
  , aAmountWorkOper in out TSumAmounts
  , aAmountWorkMach in out TSumAmounts
  )
  is
  begin
    aAmountAdjOper.vMGM_LC   := 0;
    aAmountAdjOper.vQTY      := 0;
    aAmountAdjMach.vMGM_LC   := 0;
    aAmountAdjMach.vQTY      := 0;
    aAmountWorkOper.vMGM_LC  := 0;
    aAmountWorkOper.vQTY     := 0;
    aAmountWorkMach.vMGM_LC  := 0;
    aAmountWorkMach.vQTY     := 0;
  end InitMgmAmounts;

  /*
  * Mise à jour du flag TIH_ENTERED_INTO_ACI qui évite d'aller chercher dans les détails
  *   les enregistrements principaux ENTIÈREMENT traités (ACI_DOCUMENT_ID not null)
  * @private
  */
  procedure UpdateFlagTreatedDocs
  is
  begin
    -- Si un détail ne contient pas de ACI_DOCUMENT, ne pas faire la mise à jour du flag FAL_ACI_TIME_HIST.TIH_ENTERED_INTO_ACI

    update FAL_ACI_TIME_HIST TIH
       set TIH.TIH_ENTERED_INTO_ACI = 1
     where TIH.TIH_ENTERED_INTO_ACI = 0
       and not exists(select 1
                        from FAL_ACI_TIME_HIST_DET DET
                       where DET.ACI_DOCUMENT_ID is null
                         and DET.FAL_ACI_TIME_HIST_ID = TIH.FAL_ACI_TIME_HIST_ID);

  end UpdateFlagTreatedDocs;

  /**
  * Description
  *   Intégration des heures FAL/GAL dans la finance via l'ACI.
  *   Lecture des valeurs et création des documents selon des paramètres
  *   contenu dans l'objet FAL_ FINANCIAL_TRANSACTION
  */
  procedure IntegrateFAL_GALTime
  is
/*
    Création des documents selon le descodes C_ACI_HOURS_DOC_GENERATION
      -0: 1 document par timbrage (1 doc par ligne)
      -1: 1 document par jour
      -2: 1 document par semaine
      -3: 1 document par mois
      -4: 1 document par transfert soit 1 document incluant le tout

    Regroupement des imputations selon le descodes C_ACI_HOURS_GROUP
      -0: pas de regroupement
      -1: regroupement par jour
      -2: regroupement par semaine
      -3: regroupement par mois

    Toutes les clés de regroupement seront composées de 24 digits. C'est important pour l'Order By de la commande SQL
    La clé de regroupement par semaine-mois doit contenir la numéro de la période+année
    afin que si le milieu de semaine-mois correspond à la fin d'une période,
    la semaine-mois en cours de regroupement s'arrête à la fin de la période et non à la fin de semaine-mois
    --|---------------------------|----------------|----------------------|------------------------|------------------->
    Début semaine            date doc1         fin période           date doc2                 fin semaine
    Regroupement par semaine: les 2 documents doc1 et doc2 ne seront pas regroupés ensemble car la période s'arrête en milieu de semaine
    Composition de la clé:
      - code de regroupement (2 digits)
      - année (4 digits)
      - période (2 digits)
      - date (complété à 16 digits à cause du numéro de ligne) en format char aura comme valeur
        - numéro de ligne        pour le code 0 (pas de regroupement)
        - numéro du jour du mois pour le code 1 (par jour),
        - numéro de la semaine   pour le code 2 (par semaine)
        - '0'                    pour le code 4 (regroupement par transfert)
*/
    type TTblFAL_ACI_TIME_HIST_DET is table of crRefEntries%rowtype
      index by binary_integer;

    vAmountAdjOper  TSumAmounts;
    vAmountAdjMach  TSumAmounts;
    vAmountWorkOper TSumAmounts;
    vAmountWorkMach TSumAmounts;
    vCreateDocument boolean;
    vCreateEntry    boolean                             := false;
    vRefEntries     TTblFAL_ACI_TIME_HIST_DET;
    vPrecEntry      crRefEntries%rowtype;
    vAciDocumentId  ACI_DOCUMENT.ACI_DOCUMENT_ID%type   := 0;
  begin
    InitFinAmounts(aAmountAdjOper    => vAmountAdjOper
                 , aAmountAdjMach    => vAmountAdjMach
                 , aAmountWorkOper   => vAmountWorkOper
                 , aAmountWorkMach   => vAmountWorkMach
                  );
    InitMgmAmounts(aAmountAdjOper    => vAmountAdjOper
                 , aAmountAdjMach    => vAmountAdjMach
                 , aAmountWorkOper   => vAmountWorkOper
                 , aAmountWorkMach   => vAmountWorkMach
                  );

    open crRefEntries;

    loop
      fetch crRefEntries
      bulk collect into vRefEntries limit 10000;   --Forcer une limite sinon risque d'erreur (capacité mémoire)

      exit when vRefEntries.count < 1;

      -- On crée d'abord un document puis au passage suivant et si les conditions le requiert,
      -- il faut ajouter une imputation dans le document précédemment créé
      -- Une fois toutes les lignes traitées, il est OBLIGATOIRE de créer l'imputation de la dernière ligne (avec les montants éventuellement cumulés),
      -- le document ayant déjà été créé dans la dernière ligne
      -- Cette façon de faire facilite le traitement de la dernière ligne car si on crée un document puis on teste s'il faut lui ajouter les imputations,
      -- un test SUPPLÉMENTAIRE sera INDISPENSABLE afin de savoir si TOUTES les imputations existent ou s'il manque la dernière ligne
      for vRefIndex in vRefEntries.first .. vRefEntries.last loop
        -- Cumuls des montants de l'imputation précédante (nvl si premier passage car vPrecEntry sera vide)
        if nvl(vPrecEntry.ACCMgm, 0) > 0 then
          UpdateFALAciDocumentId(aFAL_ACI_TIME_HIST_DET_ID   => vPrecEntry.FAL_ACI_TIME_HIST_DET_ID
                               , aACI_DOCUMENT_ID            => vAciDocumentId
                                );   -- Faire la mise à jour de ACI_DOCUMENT_ID dans FAL_ACI_TIME_HIST_DET lors de chaque prise en compte d'imputation
          vAmountAdjOper.vLC   := vAmountAdjOper.vLC + vPrecEntry.TIH_ADJ_TIME_OPER_AMOUNT;
          vAmountAdjMach.vLC   := vAmountAdjMach.vLC + vPrecEntry.TIH_ADJ_TIME_MACH_AMOUNT;
          vAmountWorkOper.vLC  := vAmountWorkOper.vLC + vPrecEntry.TIH_WORK_TIME_OPER_AMOUNT;
          vAmountWorkMach.vLC  := vAmountWorkMach.vLC + vPrecEntry.TIH_WORK_TIME_MACH_AMOUNT;
        end if;

        if nvl(vPrecEntry.CPNMgm, 0) > 0 then
          UpdateFALAciDocumentId(aFAL_ACI_TIME_HIST_DET_ID   => vPrecEntry.FAL_ACI_TIME_HIST_DET_ID
                               , aACI_DOCUMENT_ID            => vAciDocumentId
                                );   -- Faire la mise à jour de ACI_DOCUMENT_ID dans FAL_ACI_TIME_HIST_DET lors de chaque prise en compte d'imputation
          vAmountAdjOper.vMGM_LC   := vAmountAdjOper.vMGM_LC + vPrecEntry.TIH_ADJ_TIME_OPER_AMOUNT;
          vAmountAdjMach.vMGM_LC   := vAmountAdjMach.vMGM_LC + vPrecEntry.TIH_ADJ_TIME_MACH_AMOUNT;
          vAmountWorkOper.vMGM_LC  := vAmountWorkOper.vMGM_LC + vPrecEntry.TIH_WORK_TIME_OPER_AMOUNT;
          vAmountWorkMach.vMGM_LC  := vAmountWorkMach.vMGM_LC + vPrecEntry.TIH_WORK_TIME_MACH_AMOUNT;
          vAmountAdjOper.vQTY      := vAmountAdjOper.vQTY + vPrecEntry.TIH_ADJ_TIME_OPER_QTY;
          vAmountAdjMach.vQTY      := vAmountAdjMach.vQTY + vPrecEntry.TIH_ADJ_TIME_MACH_QTY;
          vAmountWorkOper.vQTY     := vAmountWorkOper.vQTY + vPrecEntry.TIH_WORK_TIME_OPER_QTY;
          vAmountWorkMach.vQTY     := vAmountWorkMach.vQTY + vPrecEntry.TIH_WORK_TIME_MACH_QTY;
        end if;

        vCreateEntry     :=(not CompareEntries(aRefEntry => vRefEntries(vRefIndex), aPrecEntry => vPrecEntry) );

        if vCreateEntry then
          -- Création des imputations cumulées jusqu'à maintenant, puis remise à 0 des montants
          if nvl(vPrecEntry.ACCMgm, 0) > 0 then
            CreateFinEntries(aACI_DOCUMENT_ID            => vAciDocumentId
                           , aTplFAL_ACI_TIME_HIST_DET   => vPrecEntry
                           , aAmountAdjOper              => vAmountAdjOper
                           , aAmountAdjMach              => vAmountAdjMach
                           , aAmountWorkOper             => vAmountWorkOper
                           , aAmountWorkMach             => vAmountWorkMach
                            );
            InitFinAmounts(aAmountAdjOper    => vAmountAdjOper
                         , aAmountAdjMach    => vAmountAdjMach
                         , aAmountWorkOper   => vAmountWorkOper
                         , aAmountWorkMach   => vAmountWorkMach
                          );
          end if;

          if nvl(vPrecEntry.CPNMgm, 0) > 0 then
            CreateMgmEntry(aACI_DOCUMENT_ID            => vAciDocumentId
                         , aTplFAL_ACI_TIME_HIST_DET   => vPrecEntry
                         , aAmountAdjOper              => vAmountAdjOper
                         , aAmountAdjMach              => vAmountAdjMach
                         , aAmountWorkOper             => vAmountWorkOper
                         , aAmountWorkMach             => vAmountWorkMach
                          );
            InitMgmAmounts(aAmountAdjOper    => vAmountAdjOper
                         , aAmountAdjMach    => vAmountAdjMach
                         , aAmountWorkOper   => vAmountWorkOper
                         , aAmountWorkMach   => vAmountWorkMach
                          );
          end if;
        end if;

        vCreateDocument  := not CompareDocuments(aRefEntry => vRefEntries(vRefIndex), aPrecEntry => vPrecEntry);

        if vCreateDocument then
          -- Mise à jour du montant total du document
          UpdateDocTotalAmountDC(aACI_DOCUMENT_ID => vAciDocumentId);
          -- Création du statut. En cas d'intégration direct, il faut que le statut soit créé tout à la fin du processus de création,
          -- sinon le contrôle ne peut être fait (sur des données qui n'existent pas encore)
          CreateDocumentStatus(aACI_DOCUMENT_ID => vAciDocumentId);
          --Création d'un document avec en retour ACI_DOCUMENT_ID
          vAciDocumentId  := CreateDocument(aFAL_ACI_TIME_HIST_DET => vRefEntries(vRefIndex) );
        end if;

        vPrecEntry       := vRefEntries(vRefIndex);
      end loop;
    end loop;

    close crRefEntries;

    -- Cumuler les imputations de la dernière ligne pour autant qu'elle existe
    if nvl(vPrecEntry.ACCMgm, 0) > 0 then
      UpdateFALAciDocumentId(aFAL_ACI_TIME_HIST_DET_ID   => vPrecEntry.FAL_ACI_TIME_HIST_DET_ID
                           , aACI_DOCUMENT_ID            => vAciDocumentId
                            );   -- Faire la mise à jour de ACI_DOCUMENT_ID dans FAL_ACI_TIME_HIST_DET lors de chaque prise en compte d'imputation
      vAmountAdjOper.vLC   := vAmountAdjOper.vLC + vPrecEntry.TIH_ADJ_TIME_OPER_AMOUNT;
      vAmountAdjMach.vLC   := vAmountAdjMach.vLC + vPrecEntry.TIH_ADJ_TIME_MACH_AMOUNT;
      vAmountWorkOper.vLC  := vAmountWorkOper.vLC + vPrecEntry.TIH_WORK_TIME_OPER_AMOUNT;
      vAmountWorkMach.vLC  := vAmountWorkMach.vLC + vPrecEntry.TIH_WORK_TIME_MACH_AMOUNT;
      --Création des imputations financières
      CreateFinEntries(aACI_DOCUMENT_ID            => vAciDocumentId
                     , aTplFAL_ACI_TIME_HIST_DET   => vPrecEntry
                     , aAmountAdjOper              => vAmountAdjOper
                     , aAmountAdjMach              => vAmountAdjMach
                     , aAmountWorkOper             => vAmountWorkOper
                     , aAmountWorkMach             => vAmountWorkMach
                      );
    end if;

    if nvl(vPrecEntry.CPNMgm, 0) > 0 then
      UpdateFALAciDocumentId(aFAL_ACI_TIME_HIST_DET_ID   => vPrecEntry.FAL_ACI_TIME_HIST_DET_ID
                           , aACI_DOCUMENT_ID            => vAciDocumentId
                            );   -- Faire la mise à jour de ACI_DOCUMENT_ID dans FAL_ACI_TIME_HIST_DET lors de chaque prise en compte d'imputation
      vAmountAdjOper.vMGM_LC   := vAmountAdjOper.vMGM_LC + vPrecEntry.TIH_ADJ_TIME_OPER_AMOUNT;
      vAmountAdjMach.vMGM_LC   := vAmountAdjMach.vMGM_LC + vPrecEntry.TIH_ADJ_TIME_MACH_AMOUNT;
      vAmountWorkOper.vMGM_LC  := vAmountWorkOper.vMGM_LC + vPrecEntry.TIH_WORK_TIME_OPER_AMOUNT;
      vAmountWorkMach.vMGM_LC  := vAmountWorkMach.vMGM_LC + vPrecEntry.TIH_WORK_TIME_MACH_AMOUNT;
      vAmountAdjOper.vQTY      := vAmountAdjOper.vQTY + vPrecEntry.TIH_ADJ_TIME_OPER_QTY;
      vAmountAdjMach.vQTY      := vAmountAdjMach.vQTY + vPrecEntry.TIH_ADJ_TIME_MACH_QTY;
      vAmountWorkOper.vQTY     := vAmountWorkOper.vQTY + vPrecEntry.TIH_WORK_TIME_OPER_QTY;
      vAmountWorkMach.vQTY     := vAmountWorkMach.vQTY + vPrecEntry.TIH_WORK_TIME_MACH_QTY;
      --Création des imputations analytiques
      CreateMgmEntry(aACI_DOCUMENT_ID            => vAciDocumentId
                   , aTplFAL_ACI_TIME_HIST_DET   => vPrecEntry
                   , aAmountAdjOper              => vAmountAdjOper
                   , aAmountAdjMach              => vAmountAdjMach
                   , aAmountWorkOper             => vAmountWorkOper
                   , aAmountWorkMach             => vAmountWorkMach
                    );
    end if;

    -- Mise à jour du montant total du document
    UpdateDocTotalAmountDC(aACI_DOCUMENT_ID => vAciDocumentId);
    -- Création du statut. En cas d'intégration direct, il faut que le statut soit créé tout à la fin du processus de création,
    -- sinon le contrôle ne peut être fait sur des données qui n'existent pas encore
    CreateDocumentStatus(aACI_DOCUMENT_ID => vAciDocumentId);
    -- Mise à jour du flag TIH_ENTERED_INTO_ACI qui évite d'aller chercher dans les détails (ACI_DOCUMENT_ID not null) les enregistrements principaux ENTIÈREMENT traités
    UpdateFlagTreatedDocs;
  end IntegrateFAL_GALTime;

  /**
  *   Comparaison des valeurs des imputations pour détecter un changement dans la création des documents
  */
  function CompareDocuments(
    aRefEntry  in crRefEntries%rowtype   -- imputation en cours de traitement
  , aPrecEntry in crRefEntries%rowtype   -- imputation précédemment traitée
  )
    return boolean
  is
  begin
    --premier passage, les documents sont considérés comme DIFFÉRENTS si le précédent n'existe pas ( nvl(aPrecEntry.ACJ_JOB_TYPE_S_CATALOGUE_ID, 0) ) => Création du document
    return     aRefEntry.ACJ_JOB_TYPE_S_CATALOGUE_ID = nvl(aPrecEntry.ACJ_JOB_TYPE_S_CATALOGUE_ID, 0)
           and aRefEntry.DOCS_TO_GENERATE = aPrecEntry.DOCS_TO_GENERATE;
--       and aRefEntry.C_PROGRESS_ORIGIN = aPrecEntry.C_PROGRESS_ORIGIN
--       and aRefEntry.C_FAL_ENTRY_TYPE = aPrecEntry.C_FAL_ENTRY_TYPE
  end CompareDocuments;

  /**
  *   Comparaison des valeurs des imputations pour détecter un changement dans le regroupement des imputations
  */
  function CompareEntries(
    aRefEntry  in crRefEntries%rowtype   -- imputation en cours de traitement
  , aPrecEntry in crRefEntries%rowtype   -- imputation précédemment traitée
  )
    return boolean
  is
  begin
    -- premier passage les imputations sont considérées comme ÉQUIVALENTE si la précédente n'existe pas  => Regroupement des imputations
    return    aPrecEntry.ACJ_JOB_TYPE_S_CATALOGUE_ID is null
           or (    aRefEntry.GROUPED_IMPS = aPrecEntry.GROUPED_IMPS
               and aRefEntry.C_FAL_ENTRY_SIGN = aPrecEntry.C_FAL_ENTRY_SIGN
               -- Données complémentaires
               and nvl(aRefEntry.DOC_RECORD_ID, 0) = nvl(aPrecEntry.DOC_RECORD_ID, 0)
               and nvl(aRefEntry.FAM_FIXED_ASSETS_ID, 0) = nvl(aPrecEntry.FAM_FIXED_ASSETS_ID, 0)
               and nvl(aRefEntry.GCO_GOOD_ID, 0) = nvl(aPrecEntry.GCO_GOOD_ID, 0)
               and nvl(aRefEntry.HRM_PERSON_ID, 0) = nvl(aPrecEntry.HRM_PERSON_ID, 0)
               and nvl(aRefEntry.PAC_PERSON_ID, 0) = nvl(aPrecEntry.PAC_PERSON_ID, 0)
               and aRefEntry.DIC_IMP_FREE1_ID = aPrecEntry.DIC_IMP_FREE1_ID
               and aRefEntry.DIC_IMP_FREE2_ID = aPrecEntry.DIC_IMP_FREE2_ID
               and aRefEntry.DIC_IMP_FREE3_ID = aPrecEntry.DIC_IMP_FREE3_ID
               and aRefEntry.DIC_IMP_FREE4_ID = aPrecEntry.DIC_IMP_FREE4_ID
               and aRefEntry.DIC_IMP_FREE5_ID = aPrecEntry.DIC_IMP_FREE5_ID
               and aRefEntry.IMF_NUMBER = aPrecEntry.IMF_NUMBER
               and aRefEntry.IMF_NUMBER2 = aPrecEntry.IMF_NUMBER2
               and aRefEntry.IMF_NUMBER3 = aPrecEntry.IMF_NUMBER3
               and aRefEntry.IMF_NUMBER4 = aPrecEntry.IMF_NUMBER4
               and aRefEntry.IMF_NUMBER5 = aPrecEntry.IMF_NUMBER5
               and aRefEntry.IMF_TEXT1 = aPrecEntry.IMF_TEXT1
               and aRefEntry.IMF_TEXT2 = aPrecEntry.IMF_TEXT2
               and aRefEntry.IMF_TEXT3 = aPrecEntry.IMF_TEXT3
               and aRefEntry.IMF_TEXT4 = aPrecEntry.IMF_TEXT4
               and aRefEntry.IMF_TEXT5 = aPrecEntry.IMF_TEXT5
               -- Catalogue ACC
               and (    (aRefEntry.ACCMgm = 0)
                    or (     (aRefEntry.ACCMgm > 0)
                        and nvl(aRefEntry.ACS_FINANCIAL_ACCOUNT_ID, 0) = nvl(aPrecEntry.ACS_FINANCIAL_ACCOUNT_ID, 0)
                        and nvl(aRefEntry.ACS_DIVISION_ACCOUNT_ID, 0) = nvl(aPrecEntry.ACS_DIVISION_ACCOUNT_ID, 0)
                       )
                   )
               -- Catalogue CPN
               and (    (aRefEntry.CPNMgm = 0)
                    or (     (aRefEntry.CPNMgm > 0)
                        and nvl(aRefEntry.ACS_CPN_ACCOUNT_ID, 0) = nvl(aPrecEntry.ACS_CPN_ACCOUNT_ID, 0)
                        and nvl(aRefEntry.ACS_CDA_ACCOUNT_ID, 0) = nvl(aPrecEntry.ACS_CDA_ACCOUNT_ID, 0)
                        and nvl(aRefEntry.ACS_PF_ACCOUNT_ID, 0) = nvl(aPrecEntry.ACS_PF_ACCOUNT_ID, 0)
                        and nvl(aRefEntry.ACS_PJ_ACCOUNT_ID, 0) = nvl(aPrecEntry.ACS_PJ_ACCOUNT_ID, 0)
                        and nvl(aRefEntry.ACS_QTY_UNIT_ID, 0) = nvl(aPrecEntry.ACS_QTY_UNIT_ID, 0)
                       )
                   )
              );
  end CompareEntries;

  /**
  *   Création du document ACI
  */
  function CreateDocument(aFAL_ACI_TIME_HIST_DET crRefEntries%rowtype)
    return ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  is
    vResult        ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vAcjJobTypeId  ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type;
    vFinCurId      ACI_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    vCurrency      PCS.PC_CURR.CURRENCY%type;
    vFyeNoExercice varchar2(4)                                   := '';
    vPerNoPeriod   varchar2(2)                                   := '';
    vGroupKey      signtype;
  begin
    --Création du document
    select ACI_ID_SEQ.nextval
      into vResult
      from dual;

    select FIN.ACS_FINANCIAL_CURRENCY_ID
         , (select CURRENCY
              from PCS.PC_CURR
             where PC_CURR_ID = FIN.PC_CURR_ID) CURRENCY
      into vFinCurId
         , vCurrency
      from ACS_FINANCIAL_CURRENCY FIN
     where FIN.FIN_LOCAL_CURRENCY = 1;

    if aFAL_ACI_TIME_HIST_DET.C_ACI_HOURS_GROUP <> '0' then
      select lpad(to_char(FYE_NO_EXERCICE), 4, '0')
        into vFyeNoExercice
        from ACS_FINANCIAL_YEAR
       where ACS_FINANCIAL_YEAR_ID = aFAL_ACI_TIME_HIST_DET.ACS_FINANCIAL_YEAR_ID;

      select lpad(to_char(PER.PER_NO_PERIOD), 2, '0')
        into vPerNoPeriod
        from ACS_PERIOD PER
       where PER.C_TYPE_PERIOD = '2'
         and aFAL_ACI_TIME_HIST_DET.TIH_VALUE_DATE between PER.PER_START_DATE and PER.PER_END_DATE;
    end if;

    select SCA.ACJ_JOB_TYPE_ID
         , (select case
                     when C_ACI_FINANCIAL_LINK in('4', '5') then 1
                     else 0
                   end
              from ACJ_JOB_TYPE
             where ACJ_JOB_TYPE_ID = SCA.ACJ_JOB_TYPE_ID)
      into vAcjJobTypeId
         , vGroupKey
      from ACJ_JOB_TYPE_S_CATALOGUE SCA
     where SCA.ACJ_JOB_TYPE_S_CATALOGUE_ID = aFAL_ACI_TIME_HIST_DET.ACJ_JOB_TYPE_S_CATALOGUE_ID;

    insert into ACI_DOCUMENT
                (ACI_DOCUMENT_ID
               , C_INTERFACE_ORIGIN
               , C_INTERFACE_CONTROL
               , ACJ_JOB_TYPE_S_CATALOGUE_ID
               , CAT_KEY
               , TYP_KEY
               , DOC_GRP_KEY
               , DOC_NUMBER
               , ACS_FINANCIAL_YEAR_ID
               , FYE_NO_EXERCICE
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , VAT_CURRENCY
               , DOC_DOCUMENT_DATE
               , C_STATUS_DOCUMENT
               , A_DATECRE
               , A_IDCRE
                )
         values (vResult
               , '4'
               , '3'
               , aFAL_ACI_TIME_HIST_DET.ACJ_JOB_TYPE_S_CATALOGUE_ID
               , (select CAT_KEY
                    from ACJ_CATALOGUE_DOCUMENT
                   where ACJ_CATALOGUE_DOCUMENT_ID =
                                (select ACJ_CATALOGUE_DOCUMENT_ID
                                   from ACJ_JOB_TYPE_S_CATALOGUE
                                  where ACJ_JOB_TYPE_S_CATALOGUE_ID = aFAL_ACI_TIME_HIST_DET.ACJ_JOB_TYPE_S_CATALOGUE_ID) )
               , (select TYP_KEY
                    from ACJ_JOB_TYPE
                   where ACJ_JOB_TYPE_ID = vAcjJobTypeId)
               , case
                   when vGroupKey > 0 then case aFAL_ACI_TIME_HIST_DET.C_ACI_HOURS_GROUP
                                             when '0' then null   -- pas regroupées
                                             when '1' then (select vFyeNoExercice ||
                                                                   ':' ||
                                                                   vPerNoPeriod ||
                                                                   '-' ||
                                                                   to_char( (aFAL_ACI_TIME_HIST_DET.TIH_VALUE_DATE), 'YYYY.MM.DD')
                                                              from dual)   -- regroupées par jour
                                             when '2' then (select vFyeNoExercice ||
                                                                   ':' ||
                                                                   vPerNoPeriod ||
                                                                   '-' ||
                                                                   to_char( (aFAL_ACI_TIME_HIST_DET.TIH_VALUE_DATE), 'YYYY.WW')
                                                              from dual)   -- regroupées par semaine
                                             when '3' then (select vFyeNoExercice ||
                                                                   ':' ||
                                                                   vPerNoPeriod ||
                                                                   '-' ||
                                                                   to_char( (aFAL_ACI_TIME_HIST_DET.TIH_VALUE_DATE), 'YYYY.MM')
                                                              from dual)   -- regroupées par mois
                 end
                   else null
                 end
               , aFAL_ACI_TIME_HIST_DET.DOC_NUMBER
               , aFAL_ACI_TIME_HIST_DET.ACS_FINANCIAL_YEAR_ID
               , (select FYE_NO_EXERCICE
                    from ACS_FINANCIAL_YEAR
                   where ACs_FINANCIAL_YEAR_ID = aFAL_ACI_TIME_HIST_DET.ACS_FINANCIAL_YEAR_ID)
               , vFinCurId
               , vCurrency
               , vFinCurId
               , vCurrency
               , trunc(sysdate)
               , 'DEF'
               , sysdate
               , PCS.PC_I_LIB_SESSION.GETUSERINI
                );

    return vResult;
  end CreateDocument;

  /**
  *   Création du statut du document ACI
  */
  procedure CreateDocumentStatus(aACI_DOCUMENT_ID in ACI_DOCUMENT_STATUS.ACI_DOCUMENT_ID%type)
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
                 , (select C_ACI_FINANCIAL_LINK
                      from ACJ_JOB_TYPE
                     where ACJ_JOB_TYPE_ID =
                                    (select SCA.ACJ_JOB_TYPE_ID
                                       from ACJ_JOB_TYPE_S_CATALOGUE SCA
                                      where SCA.ACJ_JOB_TYPE_S_CATALOGUE_ID = (select ACJ_JOB_TYPE_S_CATALOGUE_ID
                                                                                 from ACI_DOCUMENT
                                                                                where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID) ) )
                  );
    end if;
  end CreateDocumentStatus;

  /*
  * Mise à jour du montant total du document
  */
  procedure UpdateDocTotalAmountDC(aACI_DOCUMENT_ID in ACI_DOCUMENT.ACI_DOCUMENT_ID%type)
  is
  begin
    if     aACI_DOCUMENT_ID is not null
       and aACI_DOCUMENT_ID > 0 then
      update ACI_DOCUMENT
         set DOC_TOTAL_AMOUNT_DC =
               case
                 when (select nvl(max(1), 0)
                         from ACJ_SUB_SET_CAT SUB
                        where SUB.ACJ_CATALOGUE_DOCUMENT_ID =
                                    (select SCA.ACJ_CATALOGUE_DOCUMENT_ID
                                       from ACJ_JOB_TYPE_S_CATALOGUE SCA
                                      where SCA.ACJ_JOB_TYPE_S_CATALOGUE_ID = (select ACJ_JOB_TYPE_S_CATALOGUE_ID
                                                                                 from ACI_DOCUMENT
                                                                                where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID) )
                          and SUB.C_SUB_SET = 'ACC') > 0 then (select nvl(sum(IMF_AMOUNT_LC_D), 0)
                                                                 from ACI_FINANCIAL_IMPUTATION
                                                                where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID)
                 else (select nvl(sum(IMM_AMOUNT_LC_D), 0)
                         from ACI_MGM_IMPUTATION
                        where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID)
               end
       where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;
    end if;
  end UpdateDocTotalAmountDC;

  /*
  * Mise à jour du lien ACI_DOCUMENT de la table FAL_ACI_TIME_HIST
  */
  procedure UpdateFALAciDocumentId(
    aFAL_ACI_TIME_HIST_DET_ID in FAL_ACI_TIME_HIST_DET.FAL_ACI_TIME_HIST_DET_ID%type
  , aACI_DOCUMENT_ID          in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  )
  is
  begin
    update FAL_ACI_TIME_HIST_DET
       set ACI_DOCUMENT_ID = aACI_DOCUMENT_ID
     where FAL_ACI_TIME_HIST_DET_ID = aFAL_ACI_TIME_HIST_DET_ID
       and ACI_DOCUMENT_ID is null;
  end UpdateFALAciDocumentId;

  /**
  *   Création des imputations financières
  */
  procedure CreateFinEntries(
    aACI_DOCUMENT_ID          in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aTplFAL_ACI_TIME_HIST_DET in crRefEntries%rowtype
  , aAmountAdjOper            in TSumAmounts
  , aAmountAdjMach            in TSumAmounts
  , aAmountWorkOper           in TSumAmounts
  , aAmountWorkMach           in TSumAmounts
  )
  is
    vFinCurId ACI_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    vCurrency PCS.PC_CURR.CURRENCY%type;
  begin
    select FIN.ACS_FINANCIAL_CURRENCY_ID
         , (select CURRENCY
              from PCS.PC_CURR
             where PC_CURR_ID = FIN.PC_CURR_ID) CURRENCY
      into vFinCurId
         , vCurrency
      from ACS_FINANCIAL_CURRENCY FIN
     where FIN.FIN_LOCAL_CURRENCY = 1;

    insert into ACI_FINANCIAL_IMPUTATION
                (ACI_FINANCIAL_IMPUTATION_ID
               , ACI_DOCUMENT_ID
               , IMF_PRIMARY
               , IMF_TYPE
               , IMF_GENRE
               , C_GENRE_TRANSACTION
               , IMF_DESCRIPTION
               , ACS_PERIOD_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
               , IMF_BASE_PRICE
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY1
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY2
               , IMF_TRANSACTION_DATE
               , IMF_VALUE_DATE
               , FAM_FIXED_ASSETS_ID
               , PAC_PERSON_ID
               , DOC_RECORD_ID
               , GCO_GOOD_ID
               , HRM_PERSON_ID
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
         values (ACI_ID_SEQ.nextval
               , aACI_DOCUMENT_ID
               , (select case
                           when count(1) > 0 then 0
                           else 1
                         end
                    from ACI_FINANCIAL_IMPUTATION
                   where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID)
               , 'MAN'
               , 'STD'
               , '1'
               , aTplFAL_ACI_TIME_HIST_DET.TIH_DESCRIPTION
               , aTplFAL_ACI_TIME_HIST_DET.ACS_PERIOD_ID
               , aTplFAL_ACI_TIME_HIST_DET.ACS_FINANCIAL_ACCOUNT_ID
               , aTplFAL_ACI_TIME_HIST_DET.ACS_DIVISION_ACCOUNT_ID
               , case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN = 0 then case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 10 then aAmountWorkMach.vLC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 20 then aAmountAdjMach.vLC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 30 then aAmountWorkOper.vLC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 40 then aAmountAdjOper.vLC
                 end
                   else 0
                 end
               , case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN = 1 then case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 10 then aAmountWorkMach.vLC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 20 then aAmountAdjMach.vLC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 30 then aAmountWorkOper.vLC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 40 then aAmountAdjOper.vLC
                 end
                   else 0
                 end
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , vFinCurId
               , vCurrency
               , vFinCurId
               , vCurrency
               , aTplFAL_ACI_TIME_HIST_DET.TIH_PROGRESS_DATE
               , aTplFAL_ACI_TIME_HIST_DET.TIH_VALUE_DATE
               , aTplFAL_ACI_TIME_HIST_DET.FAM_FIXED_ASSETS_ID
               , aTplFAL_ACI_TIME_HIST_DET.PAC_PERSON_ID
               , aTplFAL_ACI_TIME_HIST_DET.DOC_RECORD_ID
               , aTplFAL_ACI_TIME_HIST_DET.GCO_GOOD_ID
               , aTplFAL_ACI_TIME_HIST_DET.HRM_PERSON_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE1_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE2_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE3_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE4_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE5_ID
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER2
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER3
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER4
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER5
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT1
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT2
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT3
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT4
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT5
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end CreateFinEntries;

  /**
  *   Création des imputations analytiques
  */
  procedure CreateMgmEntry(
    aACI_DOCUMENT_ID          in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aTplFAL_ACI_TIME_HIST_DET in crRefEntries%rowtype
  , aAmountAdjOper            in TSumAmounts
  , aAmountAdjMach            in TSumAmounts
  , aAmountWorkOper           in TSumAmounts
  , aAmountWorkMach           in TSumAmounts
  )
  is
    vFinCurId ACI_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    vCurrency PCS.PC_CURR.CURRENCY%type;
  begin
    select FIN.ACS_FINANCIAL_CURRENCY_ID
         , (select CURRENCY
              from PCS.PC_CURR
             where PC_CURR_ID = FIN.PC_CURR_ID) CURRENCY
      into vFinCurId
         , vCurrency
      from ACS_FINANCIAL_CURRENCY FIN
     where FIN.FIN_LOCAL_CURRENCY = 1;

    insert into ACI_MGM_IMPUTATION
                (ACI_MGM_IMPUTATION_ID
               , ACI_DOCUMENT_ID
               , IMM_TYPE
               , IMM_GENRE
               , IMM_PRIMARY
               , IMM_DESCRIPTION
               , ACS_PERIOD_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , IMM_AMOUNT_LC_D
               , IMM_AMOUNT_LC_C
               , IMM_EXCHANGE_RATE
               , IMM_BASE_PRICE
               , IMM_AMOUNT_FC_D
               , IMM_AMOUNT_FC_C
               , IMM_AMOUNT_EUR_D
               , IMM_AMOUNT_EUR_C
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY1
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY2
               , ACS_QTY_UNIT_ID
               , IMM_QUANTITY_D
               , IMM_QUANTITY_C
               , IMM_VALUE_DATE
               , IMM_TRANSACTION_DATE
               , FAM_FIXED_ASSETS_ID
               , PAC_PERSON_ID
               , DOC_RECORD_ID
               , GCO_GOOD_ID
               , HRM_PERSON_ID
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
               , 'MAN'
               , 'STD'
               , case aTplFAL_ACI_TIME_HIST_DET.ACCMgm
                   when 0 then 0   -- pas d'imputation primaire en analytique si le catalogue ne gére pas le sous-ensemble ACC
                   else (select case
                                  when count(1) > 0 then 0
                                  else 1
                                end
                           from ACI_MGM_IMPUTATION
                          where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID)
                 end
               , aTplFAL_ACI_TIME_HIST_DET.TIH_DESCRIPTION
               , aTplFAL_ACI_TIME_HIST_DET.ACS_PERIOD_ID
               , aTplFAL_ACI_TIME_HIST_DET.ACS_CPN_ACCOUNT_ID
               , aTplFAL_ACI_TIME_HIST_DET.ACS_CDA_ACCOUNT_ID
               , aTplFAL_ACI_TIME_HIST_DET.ACS_PF_ACCOUNT_ID
               , aTplFAL_ACI_TIME_HIST_DET.ACS_PJ_ACCOUNT_ID
               , case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN = 0 then case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 10 then aAmountWorkMach.vMGM_LC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 20 then aAmountAdjMach.vMGM_LC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 30 then aAmountWorkOper.vMGM_LC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 40 then aAmountAdjOper.vMGM_LC
                 end
                   else 0
                 end
               , case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN = 1 then case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 10 then aAmountWorkMach.vMGM_LC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 20 then aAmountAdjMach.vMGM_LC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 30 then aAmountWorkOper.vMGM_LC
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 40 then aAmountAdjOper.vMGM_LC
                 end
                   else 0
                 end
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , vFinCurId
               , vCurrency
               , vFinCurId
               , vCurrency
               , aTplFAL_ACI_TIME_HIST_DET.ACS_QTY_UNIT_ID
               , case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN = 0 then case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 10 then aAmountWorkMach.vQTY
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 20 then aAmountAdjMach.vQTY
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 30 then aAmountWorkOper.vQTY
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 40 then aAmountAdjOper.vQTY
                 end
                   else 0
                 end
               , case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN = 1 then case
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 10 then aAmountWorkMach.vQTY
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 20 then aAmountAdjMach.vQTY
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 30 then aAmountWorkOper.vQTY
                   when aTplFAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE = 40 then aAmountAdjOper.vQTY
                 end
                   else 0
                 end
               , aTplFAL_ACI_TIME_HIST_DET.TIH_VALUE_DATE
               , aTplFAL_ACI_TIME_HIST_DET.TIH_PROGRESS_DATE
               , aTplFAL_ACI_TIME_HIST_DET.FAM_FIXED_ASSETS_ID
               , aTplFAL_ACI_TIME_HIST_DET.PAC_PERSON_ID
               , aTplFAL_ACI_TIME_HIST_DET.DOC_RECORD_ID
               , aTplFAL_ACI_TIME_HIST_DET.GCO_GOOD_ID
               , aTplFAL_ACI_TIME_HIST_DET.HRM_PERSON_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE1_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE2_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE3_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE4_ID
               , aTplFAL_ACI_TIME_HIST_DET.DIC_IMP_FREE5_ID
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER2
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER3
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER4
               , aTplFAL_ACI_TIME_HIST_DET.IMF_NUMBER5
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT1
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT2
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT3
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT4
               , aTplFAL_ACI_TIME_HIST_DET.IMF_TEXT5
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end CreateMgmEntry;
end ACI_FAL_TIME;
