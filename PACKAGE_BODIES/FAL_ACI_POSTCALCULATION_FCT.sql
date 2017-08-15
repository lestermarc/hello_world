--------------------------------------------------------
--  DDL for Package Body FAL_ACI_POSTCALCULATION_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ACI_POSTCALCULATION_FCT" 
is
--   -- Origines d'avancement C_PROGRESS_ORIGIN
--   poProduction     constant FAL_ACI_POSTCALCULATION.C_PROGRESS_ORIGIN%type     := '10';   -- Opération d'OF
--   poProject        constant FAL_ACI_POSTCALCULATION.C_PROGRESS_ORIGIN%type     := '20';   -- Opération de DF
  -- Statuts des enregistrements temporaires C_APC_STATUS
  asToProcess          constant FAL_ACI_POSTCALCULATION.C_APC_STATUS%type       := '10';   -- A imputer
  asProcessed          constant FAL_ACI_POSTCALCULATION.C_APC_STATUS%type       := '20';   -- Imputé sans erreur
  asProcessError       constant FAL_ACI_POSTCALCULATION.C_APC_STATUS%type       := '30';   -- Erreur lors de l'imputation
  asProcessAborted     constant FAL_ACI_POSTCALCULATION.C_APC_STATUS%type       := '40';   -- Abandon par procédure indiv
  -- Statuts de lot C_LOT_STATUS
  lsLaunched                    FAL_LOT.C_LOT_STATUS%type                       := '2';   -- Lancé
  lsBalanced                    FAL_LOT.C_LOT_STATUS%type                       := '5';   -- Soldé (Réception)
  -- Sortes d'imputation C_FAL_ENTRY_KIND
  ekExpProduct         constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '10';   -- Coût prévu (produit terminé)
  ekExpEltCost         constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '11';   -- Coût prévu (élément de coût)
  ekRealProduct        constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '20';   -- Coût réel (produit terminé)
  ekRealEltCost        constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '21';   -- Coût réel (élément de coût)
  ekFavorQtyCostDiff   constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '30';   -- Ecart de coût favorable en quantité
  ekUnfavorQtyCostDiff constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '31';   -- Ecart de coût défavorable en quantité
  ekFavorValCostDiff   constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '40';   -- Ecart de coût favorable en valeur
  ekUnfavorValCostDiff constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type     := '41';   -- Ecart de coût défavorable en valeur
  -- Sens d'imputation C_FAL_ENTRY_SIGN
  esDebit              constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_SIGN%type     := '0';   -- Débit
  esCredit             constant FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_SIGN%type     := '1';   -- Crédit
  -- Types d'élément de coût C_COST_ELEMENT_TYPE
  ctMaterial           constant FAL_ELT_COST_DIFF.C_COST_ELEMENT_TYPE%type      := 'MAT';   -- Coût matière
  ctSubContract        constant FAL_ELT_COST_DIFF.C_COST_ELEMENT_TYPE%type      := 'SST';   -- Coût sous-traitance
  ctMachine            constant FAL_ELT_COST_DIFF.C_COST_ELEMENT_TYPE%type      := 'TMA';   -- Coût travail machine
  ctOperator           constant FAL_ELT_COST_DIFF.C_COST_ELEMENT_TYPE%type      := 'TMO';   -- Coût travail main d'oeuvre
  -- sous-types d'élément de coût C_COST_ELEMENT_SUBTYPE
  cstWork              constant FAL_ELT_COST_DIFF.C_COST_ELEMENT_SUBTYPE%type   := 'WORK';   -- Coût travail
  cstAdjusting         constant FAL_ELT_COST_DIFF.C_COST_ELEMENT_SUBTYPE%type   := 'ADJ';   -- Coût réglage
  -- Valeur par défaut des descriptions des heures
  cDefaultDescr        constant FAL_ACI_POSTCALCULATION.APC_DESCRIPTION%type    := '<...>';
  cMaxDescrLength      constant integer                                         := 100;
  cMaxDocNumberLength  constant integer                                         := 30;
  -- Configuration
  cDelayWeekStart      constant integer                                         := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

  /* Record de stockage des données de comptes
     Attention : doit avoir la même structure que les curseurs de recherche
                 des comptes imputés lorts de l'en-cours. */
  type TAccounts is record(
    FEC_COMPLETED_AMOUNT     FAL_ELEMENT_COST.FEC_COMPLETED_AMOUNT%type
  , FEC_COMPLETED_QUANTITY   FAL_ELEMENT_COST.FEC_COMPLETED_QUANTITY%type
  , ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , ACS_DIVISION_ACCOUNT_ID  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , ACS_CPN_ACCOUNT_ID       ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , ACS_CDA_ACCOUNT_ID       ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , ACS_PF_ACCOUNT_ID        ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , ACS_PJ_ACCOUNT_ID        ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  , ACS_QTY_UNIT_ID          ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , DOC_RECORD_ID            DOC_RECORD.DOC_RECORD_ID%type
  , GCO_GOOD_ID              GCO_GOOD.GCO_GOOD_ID%type
  , FAM_FIXED_ASSETS_ID      FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , C_FAM_TRANSACTION_TYP    FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type
  , HRM_PERSON_ID            HRM_PERSON.HRM_PERSON_ID%type
  , PAC_PERSON_ID            PAC_PERSON.PAC_PERSON_ID%type
  , PAC_THIRD_ID             PAC_THIRD.PAC_THIRD_ID%type
  , DIC_IMP_FREE1_ID         FAL_ELT_COST_DIFF_DET.DIC_IMP_FREE1_ID%type
  , DIC_IMP_FREE2_ID         FAL_ELT_COST_DIFF_DET.DIC_IMP_FREE2_ID%type
  , DIC_IMP_FREE3_ID         FAL_ELT_COST_DIFF_DET.DIC_IMP_FREE3_ID%type
  , DIC_IMP_FREE4_ID         FAL_ELT_COST_DIFF_DET.DIC_IMP_FREE4_ID%type
  , DIC_IMP_FREE5_ID         FAL_ELT_COST_DIFF_DET.DIC_IMP_FREE5_ID%type
  , IMF_NUMBER               FAL_ELT_COST_DIFF_DET.IMF_NUMBER%type
  , IMF_NUMBER2              FAL_ELT_COST_DIFF_DET.IMF_NUMBER2%type
  , IMF_NUMBER3              FAL_ELT_COST_DIFF_DET.IMF_NUMBER3%type
  , IMF_NUMBER4              FAL_ELT_COST_DIFF_DET.IMF_NUMBER4%type
  , IMF_NUMBER5              FAL_ELT_COST_DIFF_DET.IMF_NUMBER5%type
  , IMF_TEXT1                FAL_ELT_COST_DIFF_DET.IMF_TEXT1%type
  , IMF_TEXT2                FAL_ELT_COST_DIFF_DET.IMF_TEXT2%type
  , IMF_TEXT3                FAL_ELT_COST_DIFF_DET.IMF_TEXT3%type
  , IMF_TEXT4                FAL_ELT_COST_DIFF_DET.IMF_TEXT4%type
  , IMF_TEXT5                FAL_ELT_COST_DIFF_DET.IMF_TEXT5%type
  );

  /**
   * procedure ProcessFullAciPostCalculation
   */
  procedure ProcessFullAciPostCalculation(
    aProfileID       in     number default null
  , aClobProfile     in     clob default null
  , aProfileName     in     varchar2 default null
  , aSuccessfulCount out    integer
  , aTotalCount      out    integer
  )
  is
    vOptions         TAPCOptions;
    vLastWeek        varchar2(7);
    vLastMonth       varchar2(7);
    vDateFrom        date;
    vDateTo          date;
    vSuccessfulCount integer;
    vTotalCount      integer;
  begin
    if aProfileID is not null then
      vOptions  := GetAPCProfileValues(PCS.COM_PROFILE_FUNCTIONS.GetXMLProfile(aProfileID) );
    elsif aClobProfile is not null then
      vOptions  := GetAPCProfileValues(xmltype.CreateXML(aClobProfile) );
    elsif aProfileName is not null then
      vOptions  := GetAPCProfileValues(PCS.COM_PROFILE_FUNCTIONS.GetXMLProfileByName(aProfileName => aProfileName, aVariant => 'WIZARD') );
    end if;

    ApplyAPCOptions(vOptions);

    -- Recherche des dates d'après les options
    case vOptions.APC_DATE_UNIT
      when 3 then
        -- Semaine dernière
        vLastWeek  := DOC_DELAY_FUNCTIONS.DateToWeek(sysdate - 7);
        vDateFrom  := DOC_DELAY_FUNCTIONS.WeekToDate(aWeek => vLastWeek, aDay => cDelayWeekStart);
        vDateTo    := DOC_DELAY_FUNCTIONS.WeekToDate(aWeek => vLastWeek, aDay => mod(cDelayWeekStart + 6, 7) );
      when 4 then
        -- Mois dernier
        vLastMonth  := to_char(sysdate, 'YYYY') || '.' || lpad(zvl(to_number(to_char(sysdate, 'MM') ) - 1, 12), 2, 0);
        vDateFrom   := DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate => vLastMonth, aPosDelay => 1, aCheckOpenDay => 0);
        vDateTo     := DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate => vLastMonth, aPosDelay => 31, aCheckOpenDay => 0);
      else
        -- Jusqu'à aujourd'hui
        vDateFrom  := null;
        vDateTo    := sysdate;
    end case;

    -- Génération des enregistrements temporaires d'après les options
    GenerateTempRecords(aDefaultSelection => vOptions.APC_SELECTION, aDateFrom => vDateFrom, aDateTo => vDateTo);
    -- Traitement des heures sélectionnées
    ProcessPostCalculations(aSuccessfulCount => vSuccessfulCount, aTotalCount => vTotalCount);
  end ProcessFullAciPostCalculation;

  /**
   * procedure ApplyAPCOptions
   * Description
   *   Applique les options du profil (sélection des produits et lots)
   */
  procedure ApplyAPCOptions(aOptions in TAPCOptions)
  is
  begin
    SelectProducts(aAPC_PRODUCT_FROM             => aOptions.APC_PRODUCT_FROM
                 , aAPC_PRODUCT_TO               => aOptions.APC_PRODUCT_TO
                 , aAPC_GOOD_CATEGORY_FROM       => aOptions.APC_GOOD_CATEGORY_FROM
                 , aAPC_GOOD_CATEGORY_TO         => aOptions.APC_GOOD_CATEGORY_TO
                 , aAPC_GOOD_FAMILY_FROM         => aOptions.APC_GOOD_FAMILY_FROM
                 , aAPC_GOOD_FAMILY_TO           => aOptions.APC_GOOD_FAMILY_TO
                 , aAPC_ACCOUNTABLE_GROUP_FROM   => aOptions.APC_ACCOUNTABLE_GROUP_FROM
                 , aAPC_ACCOUNTABLE_GROUP_TO     => aOptions.APC_ACCOUNTABLE_GROUP_TO
                 , aAPC_GOOD_LINE_FROM           => aOptions.APC_GOOD_LINE_FROM
                 , aAPC_GOOD_LINE_TO             => aOptions.APC_GOOD_LINE_TO
                 , aAPC_GOOD_GROUP_FROM          => aOptions.APC_GOOD_GROUP_FROM
                 , aAPC_GOOD_GROUP_TO            => aOptions.APC_GOOD_GROUP_TO
                 , aAPC_GOOD_MODEL_FROM          => aOptions.APC_GOOD_MODEL_FROM
                 , aAPC_GOOD_MODEL_TO            => aOptions.APC_GOOD_MODEL_TO
                  );
    SelectBatches(aAPC_JOB_PROGRAM_FROM   => aOptions.APC_JOB_PROGRAM_FROM
                , aAPC_JOB_PROGRAM_TO     => aOptions.APC_JOB_PROGRAM_TO
                , aAPC_ORDER_FROM         => aOptions.APC_ORDER_FROM
                , aAPC_ORDER_TO           => aOptions.APC_ORDER_TO
                , aAPC_C_PRIORITY_FROM    => aOptions.APC_C_PRIORITY_FROM
                , aAPC_C_PRIORITY_TO      => aOptions.APC_C_PRIORITY_TO
                , aAPC_FAMILY_FROM        => aOptions.APC_FAMILY_FROM
                , aAPC_FAMILY_TO          => aOptions.APC_FAMILY_TO
                , aAPC_RECORD_FROM        => aOptions.APC_RECORD_FROM
                , aAPC_RECORD_TO          => aOptions.APC_RECORD_TO
                 );
  end;

  /**
   * procedure SelectProduct
   * Description
   *   Sélectionne le produit
   */
  procedure SelectProduct(aGCO_GOOD_ID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    -- Sélection de l'ID du produit traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aGCO_GOOD_ID
               , 'GCO_GOOD_ID'
                );
  end SelectProduct;

  /**
   * procedure SelectProducts
   * Description
   *   Sélectionne les produits selon les filtres
   */
  procedure SelectProducts(
    aAPC_PRODUCT_FROM           in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aAPC_PRODUCT_TO             in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aAPC_GOOD_CATEGORY_FROM     in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aAPC_GOOD_CATEGORY_TO       in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aAPC_GOOD_FAMILY_FROM       in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aAPC_GOOD_FAMILY_TO         in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aAPC_ACCOUNTABLE_GROUP_FROM in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aAPC_ACCOUNTABLE_GROUP_TO   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aAPC_GOOD_LINE_FROM         in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aAPC_GOOD_LINE_TO           in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aAPC_GOOD_GROUP_FROM        in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aAPC_GOOD_GROUP_TO          in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aAPC_GOOD_MODEL_FROM        in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , aAPC_GOOD_MODEL_TO          in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct GOO.GCO_GOOD_ID
                    , 'GCO_GOOD_ID'
                 from GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , GCO_GOOD_CATEGORY CAT
                where GOO.GOO_MAJOR_REFERENCE between nvl(aAPC_PRODUCT_FROM, GOO.GOO_MAJOR_REFERENCE) and nvl(aAPC_PRODUCT_TO, GOO.GOO_MAJOR_REFERENCE)
                  and PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and (    (    aAPC_GOOD_CATEGORY_FROM is null
                            and aAPC_GOOD_CATEGORY_TO is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(aAPC_GOOD_CATEGORY_FROM, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(aAPC_GOOD_CATEGORY_TO, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    aAPC_GOOD_FAMILY_FROM is null
                            and aAPC_GOOD_FAMILY_TO is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(aAPC_GOOD_FAMILY_FROM, GOO.DIC_GOOD_FAMILY_ID) and nvl(aAPC_GOOD_FAMILY_TO, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    aAPC_ACCOUNTABLE_GROUP_FROM is null
                            and aAPC_ACCOUNTABLE_GROUP_TO is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(aAPC_ACCOUNTABLE_GROUP_FROM, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(aAPC_ACCOUNTABLE_GROUP_TO, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    aAPC_GOOD_LINE_FROM is null
                            and aAPC_GOOD_LINE_TO is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(aAPC_GOOD_LINE_FROM, GOO.DIC_GOOD_LINE_ID) and nvl(aAPC_GOOD_LINE_TO, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    aAPC_GOOD_GROUP_FROM is null
                            and aAPC_GOOD_GROUP_TO is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(aAPC_GOOD_GROUP_FROM, GOO.DIC_GOOD_GROUP_ID) and nvl(aAPC_GOOD_GROUP_TO, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    aAPC_GOOD_MODEL_FROM is null
                            and aAPC_GOOD_MODEL_TO is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(aAPC_GOOD_MODEL_FROM, GOO.DIC_GOOD_MODEL_ID) and nvl(aAPC_GOOD_MODEL_TO, GOO.DIC_GOOD_MODEL_ID)
                      );
  end SelectProducts;

  /**
   * procedure SelectBatch
   * Description
   *   Sélectionne un lot
   */
  procedure SelectBatch(aFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection de l'ID du lot
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aFAL_LOT_ID
               , 'FAL_LOT_ID'
                );
  end SelectBatch;

  /**
   * procedure SelectBatches
   * Description
   *   Sélectionne les lots
   */
  procedure SelectBatches(
    aAPC_JOB_PROGRAM_FROM in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aAPC_JOB_PROGRAM_TO   in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aAPC_ORDER_FROM       in FAL_ORDER.ORD_REF%type
  , aAPC_ORDER_TO         in FAL_ORDER.ORD_REF%type
  , aAPC_C_PRIORITY_FROM  in FAL_LOT.C_PRIORITY%type
  , aAPC_C_PRIORITY_TO    in FAL_LOT.C_PRIORITY%type
  , aAPC_FAMILY_FROM      in DIC_FAMILY.DIC_FAMILY_ID%type
  , aAPC_FAMILY_TO        in DIC_FAMILY.DIC_FAMILY_ID%type
  , aAPC_RECORD_FROM      in DOC_RECORD.RCO_TITLE%type
  , aAPC_RECORD_TO        in DOC_RECORD.RCO_TITLE%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection des ID de lots
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_ID
                    , 'FAL_LOT_ID'
                 from FAL_LOT LOT
                    , FAL_JOB_PROGRAM JOP
                    , FAL_ORDER ORD
                    , DOC_RECORD RCO
                where LOT.GCO_GOOD_ID in(select COM_LIST_ID_TEMP_ID
                                           from COM_LIST_ID_TEMP
                                          where LID_CODE = 'GCO_GOOD_ID')
                  and LOT.C_LOT_STATUS = lsBalanced
                  and nvl(LOT.LOT_IS_POSTCALCULATED, 0) = 0
                  and LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                  and (    (    aAPC_JOB_PROGRAM_FROM is null
                            and aAPC_JOB_PROGRAM_TO is null)
                       or JOP.JOP_REFERENCE between nvl(aAPC_JOB_PROGRAM_FROM, JOP.JOP_REFERENCE) and nvl(aAPC_JOB_PROGRAM_TO, JOP.JOP_REFERENCE)
                      )
                  and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
                  and (    (    aAPC_ORDER_FROM is null
                            and aAPC_ORDER_TO is null)
                       or ORD.ORD_REF between nvl(aAPC_ORDER_FROM, ORD.ORD_REF) and nvl(aAPC_ORDER_TO, ORD.ORD_REF)
                      )
                  and (    (    aAPC_C_PRIORITY_FROM is null
                            and aAPC_C_PRIORITY_TO is null)
                       or LOT.C_PRIORITY between nvl(aAPC_C_PRIORITY_FROM, LOT.C_PRIORITY) and nvl(aAPC_C_PRIORITY_TO, LOT.C_PRIORITY)
                      )
                  and (    (    aAPC_FAMILY_FROM is null
                            and aAPC_FAMILY_TO is null)
                       or LOT.DIC_FAMILY_ID between nvl(aAPC_FAMILY_FROM, LOT.DIC_FAMILY_ID) and nvl(aAPC_FAMILY_TO, LOT.DIC_FAMILY_ID)
                      )
                  and RCO.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
                  and (    (    aAPC_RECORD_FROM is null
                            and aAPC_RECORD_TO is null)
                       or RCO.RCO_TITLE between nvl(aAPC_RECORD_FROM, RCO.RCO_TITLE) and nvl(aAPC_RECORD_TO, RCO.RCO_TITLE)
                      );
  end SelectBatches;

  procedure CalcProdData(
    aProdQty           in     PTC_USED_COMPONENT.PUC_CALCUL_QTY%type
  , aSchedulePlanning  in     FAL_LOT.C_SCHEDULE_PLANNING%type
  , aTaskImputation    in     FAL_TASK_LINK.C_TASK_IMPUTATION%type
  , aAdjustingTime     in     PTC_USED_TASK.PUT_ADJUSTING_TIME%type
  , aQtyFixAdjusting   in     PTC_USED_TASK.PUT_QTY_FIX_ADJUSTING%type
  , aWorkTime          in     PTC_USED_TASK.PUT_WORK_TIME%type
  , aQtyRefWork        in     PTC_USED_TASK.PUT_QTY_REF_WORK%type
  , aAmount            in     PTC_USED_TASK.PUT_AMOUNT%type
  , aDivisorAmount     in     PTC_USED_TASK.PUT_DIVISOR%type
  , aQtyRefAmount      in     PTC_USED_TASK.PUT_QTY_REF_AMOUNT%type
  , aAdjustingFloor    in     FAL_TASK_LINK.SCS_ADJUSTING_FLOOR%type
  , aWorkFloor         in     FAL_TASK_LINK.SCS_WORK_FLOOR%type
  , aAdjustingOperator in     FAL_TASK_LINK.SCS_ADJUSTING_OPERATOR%type
  , aWorkOperator      in     FAL_TASK_LINK.SCS_WORK_OPERATOR%type
  , aNumAdjustOper     in     FAL_TASK_LINK.SCS_NUM_ADJUST_OPERATOR%type
  , aNumWorkOper       in     FAL_TASK_LINK.SCS_NUM_WORK_OPERATOR%type
  , aPercentAdjustOper in     FAL_TASK_LINK.SCS_PERCENT_ADJUST_OPER%type
  , aPercentWorkOper   in     FAL_TASK_LINK.SCS_PERCENT_WORK_OPER%type
  , aMinuteRate        in     PTC_USED_TASK.PUT_MINUTE_RATE%type
  , aMachAdjTime       out    PTC_USED_TASK.PUT_ADJUSTING_TIME%type
  , aMachWorkTime      out    PTC_USED_TASK.PUT_WORK_TIME%type
  , aOperAdjTime       out    PTC_USED_TASK.PUT_ADJUSTING_TIME%type
  , aOperWorkTime      out    PTC_USED_TASK.PUT_WORK_TIME%type
  , aMachWorkAmount    out    PTC_USED_TASK.PUT_AMOUNT%type
  )
  is
    vAdjustingTime PTC_USED_TASK.PUT_ADJUSTING_TIME%type;
    vWorkTime      PTC_USED_TASK.PUT_WORK_TIME%type;
  begin
    /* Le code ci-dessous est tiré de FAL_SUIVI_OPERATION, dupliqué pour l'instant */
    -- Réglage
    if nvl(aQtyFixAdjusting, 0) = 0 then
      vAdjustingTime  := aAdjustingTime;
    else
      vAdjustingTime  := ceil(aProdQty / aQtyFixAdjusting) * aAdjustingTime;
    end if;

    -- Travail
    vWorkTime  := aProdQty / aQtyRefWork * aWorkTime;

    -- Montant
    if nvl(aDivisorAmount, 0) = 1 then
      aMachWorkAmount  := aProdQty / aQtyRefAmount * aAmount;
    else
      aMachWorkAmount  := aProdQty * aQtyRefAmount * aAmount;
    end if;

    -- La valeur de la config PPS_WORK_UNIT à été sauvegardée
    if aMinuteRate = 1 then
      vAdjustingTime  := vAdjustingTime / 60;
      vWorkTime       := vWorkTime / 60;
    end if;

    /* Le code ci-dessous est tiré de FAL_ACI_TIME_ENTRY, dupliqué pour l'instant */
    if aSchedulePlanning <> 3 then
      -- Initialisation des temps avec les temps réglage et travail
      aOperAdjTime   := vAdjustingTime;
      aMachAdjTime   := vAdjustingTime;
      aOperWorkTime  := vWorkTime;
      aMachWorkTime  := vWorkTime;

      -- Mise à 0 des temps qui ne sont pas pris en compte selon le code d'imputation
      if aTaskImputation = '2' then
        aMachAdjTime   := 0;
        aOperWorkTime  := 0;
      elsif aTaskImputation = '3' then
        aMachAdjTime  := 0;
      elsif aTaskImputation = '4' then
        aOperWorkTime  := 0;
      end if;
    else
      -- Initialisation des temps à 0
      aMachAdjTime   := 0;
      aMachWorkTime  := 0;
      aOperAdjTime   := 0;
      aOperWorkTime  := 0;

      -- Mise à jour des temps selon les données de l'opération
      if aAdjustingFloor = 1 then
        aMachAdjTime  := vAdjustingTime;
      end if;

      if aWorkFloor = 1 then
        aMachWorkTime  := vWorkTime;
      end if;

      if aAdjustingOperator = 1 then
        aOperAdjTime  := vAdjustingTime * aNumAdjustOper * aPercentAdjustOper / 100;
      end if;

      if aWorkOperator = 1 then
        aOperWorkTime  := vWorkTime * aNumWorkOper * aPercentWorkOper / 100;
      end if;
    end if;
  end CalcProdData;

  /**
   * procedure GenerateDescription
   * Description
   *   Génère une description
   */
  function GenerateDescription(
    aLotId           in FAL_ACI_POSTCALCULATION.FAL_LOT_ID%type default null
  , aBaseDescription in FAL_ACI_POSTCALCULATION.APC_DESCRIPTION%type default null
  , aCompSeq         in PTC_USED_COMPONENT.PUC_SEQ%type default null
  , aCompGoodId      in GCO_GOOD.GCO_GOOD_ID%type default null
  , aTaskSeq         in PTC_USED_TASK.PUT_STEP_NUMBER%type default null
  , aTaskId          in FAL_TASK.FAL_TASK_ID%type default null
  )
    return FAL_ACI_POSTCALCULATION.APC_DESCRIPTION%type
  is
    cursor crLotInfos(aLotId in FAL_ACI_POSTCALCULATION.FAL_LOT_ID%type)
    is
      select LOT.LOT_REFCOMPL
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
        from FAL_LOT LOT
           , GCO_GOOD GOO
       where LOT.FAL_LOT_ID = aLotId
         and GOO.GCO_GOOD_ID = LOT.GCO_GOOD_ID;

    tplLotInfos  crLotInfos%rowtype;

    cursor crCompInfos(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
        from GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodId;

    tplCompInfos crCompInfos%rowtype;

    cursor crTaskInfos(aTaskId in FAL_TASK.FAL_TASK_ID%type)
    is
      select TAS.TAS_REF
        from FAL_TASK TAS
       where TAS.FAL_TASK_ID = aTaskId;

    tplTaskInfos crTaskInfos%rowtype;
    vResult      varchar2(4000);
  begin
    if aLotId > 0 then
      open crLotInfos(aLotId);

      fetch crLotInfos
       into tplLotInfos;

      close crLotInfos;

      vResult  := tplLotInfos.LOT_REFCOMPL || ' / ' || tplLotInfos.GOO_MAJOR_REFERENCE || ' / ' || tplLotInfos.GOO_SECONDARY_REFERENCE;

      -- Si la description est trop longue on enlève la référence secondaire du produit
      if length(vResult) > cMaxDescrLength then
        vResult  := tplLotInfos.LOT_REFCOMPL || ' / ' || tplLotInfos.GOO_MAJOR_REFERENCE;
      end if;
    elsif aCompGoodId > 0 then
      open crCompInfos(aCompGoodId);

      fetch crCompInfos
       into tplCompInfos;

      close crCompInfos;

      vResult  := aBaseDescription || ' / ' || aCompSeq || ' / ' || tplCompInfos.GOO_MAJOR_REFERENCE || ' / ' || tplCompInfos.GOO_SECONDARY_REFERENCE;

      -- Si la description est trop longue on enlève la référence secondaire du produit
      if length(vResult) > cMaxDescrLength then
        vResult  := aBaseDescription || ' / ' || aCompSeq || ' / ' || tplCompInfos.GOO_MAJOR_REFERENCE;
      end if;
    elsif aTaskId > 0 then
      open crTaskInfos(aTaskId);

      fetch crTaskInfos
       into tplTaskInfos;

      close crTaskInfos;

      vResult  := aBaseDescription || ' / ' || aTaskSeq || ' / ' || tplTaskInfos.TAS_REF;
    elsif aBaseDescription is not null then
      vResult  := aBaseDescription || ' / ' || cDefaultDescr;
    end if;

    -- Tronquage et valeur par défaut
    return nvl(truncstr(vResult, cMaxDescrLength), cDefaultDescr);
  end GenerateDescription;

  /**
   * procedure GenerateTempRecords
   * Description
   *   Crée les enregistrements temporaires et calcule les données à utiliser
   *   pour la post-calculation des écarts et leur imputation en ACI.
   */
  procedure GenerateTempRecords(
    aDefaultSelection in FAL_ACI_POSTCALCULATION.APC_SELECTION%type default 1
  , aDateFrom         in date default null
  , aDateTo           in date default sysdate
  )
  is
  begin
    -- Suppression des enregistrements précédents non-traités
    delete from FAL_ACI_POSTCALCULATION
          where C_APC_STATUS = asToProcess;

    -- Insertion des lots dans la table temporaire
    insert into FAL_ACI_POSTCALCULATION
                (FAL_ACI_POSTCALCULATION_ID
               , FAL_LOT_ID
               , C_APC_STATUS
               , APC_DESCRIPTION
               , APC_SELECTION
               , APC_VALUE_DATE
               , APC_BALANCED_DATE
                )
      select INIT_TEMP_ID_SEQ.nextval   -- FAL_ACI_POSTCALCULATION_ID
           , LOT.FAL_LOT_ID
           , asToProcess
--            , GenerateDescription(LOT.FAL_LOT_ID)
      ,      nvl(LOT.LOT_REFCOMPL || ' / ' || GOO.GOO_MAJOR_REFERENCE || ' / ' || GOO.GOO_SECONDARY_REFERENCE, cDefaultDescr)
           , aDefaultSelection
           , LOT.LOT_FULL_REL_DTE
           , LOT.LOT_FULL_REL_DTE
        from FAL_LOT LOT
           , GCO_GOOD GOO
       where LOT.FAL_LOT_ID in(select COM_LIST_ID_TEMP_ID
                                 from COM_LIST_ID_TEMP
                                where LID_CODE = 'FAL_LOT_ID')
         and LOT.C_LOT_STATUS = lsBalanced
         and nvl(LOT.LOT_IS_POSTCALCULATED, 0) = 0
         and (    (    aDateFrom is null
                   and aDateTo is null)
              or trunc(LOT.LOT_FULL_REL_DTE) between nvl(trunc(aDateFrom), trunc(LOT.LOT_FULL_REL_DTE) ) and nvl(trunc(aDateTo), trunc(LOT.LOT_FULL_REL_DTE) )
             )
         and GOO.GCO_GOOD_ID = LOT.GCO_GOOD_ID;
  end GenerateTempRecords;

  /**
   * procedure CreateDetail
   * Description
   *
   */
  procedure CreateDetail(
    aEltCostDiffId in FAL_ELT_COST_DIFF_DET.FAL_ELT_COST_DIFF_ID%type
  , aEntryKind     in FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type
  , aAmount        in FAL_ELT_COST_DIFF_DET.CDD_AMOUNT%type
  , aCpnId         in ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type default null
  , aInitialCpnId  in ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type default null
  , aLotId         in FAL_LOT.FAL_LOT_ID%type default null
  , aAccounts      in TAccounts
  )
  is
  begin
    -- On ne crée l'imputation que si le montant est différent de zéro
    if aAmount <> 0 then
      insert into FAL_ELT_COST_DIFF_DET
                  (FAL_ELT_COST_DIFF_DET_ID
                 , FAL_ELT_COST_DIFF_ID
                 , C_FAL_ENTRY_KIND
                 , C_FAL_ENTRY_SIGN
                 , CDD_AMOUNT
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_INITIAL_CPN_ACCOUNT_ID
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
                 , PAC_THIRD_ID
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
           values (GetNewId   -- FAL_ELT_COST_DIFF_DET_ID
                 , aEltCostDiffId   -- FAL_ELT_COST_DIFF_ID
                 , aEntryKind
                 , case
                     when aAmount > 0 then esDebit
                     else esCredit
                   end   -- C_FAL_ENTRY_SIGN
                 , abs(aAmount)
                 , aAccounts.ACS_FINANCIAL_ACCOUNT_ID
                 , aAccounts.ACS_DIVISION_ACCOUNT_ID
                 , nvl(aCpnId, aAccounts.ACS_CPN_ACCOUNT_ID)
                 , aInitialCpnId
                 , aAccounts.ACS_CDA_ACCOUNT_ID
                 , aAccounts.ACS_PF_ACCOUNT_ID
                 , aAccounts.ACS_PJ_ACCOUNT_ID
                 , aAccounts.ACS_QTY_UNIT_ID
                 , aAccounts.DOC_RECORD_ID
                 , aAccounts.FAM_FIXED_ASSETS_ID
                 , aAccounts.C_FAM_TRANSACTION_TYP
                 , aAccounts.GCO_GOOD_ID
                 , aAccounts.HRM_PERSON_ID
                 , aAccounts.PAC_PERSON_ID
                 , aAccounts.PAC_THIRD_ID
                 , aAccounts.DIC_IMP_FREE1_ID
                 , aAccounts.DIC_IMP_FREE2_ID
                 , aAccounts.DIC_IMP_FREE3_ID
                 , aAccounts.DIC_IMP_FREE4_ID
                 , aAccounts.DIC_IMP_FREE5_ID
                 , aAccounts.IMF_NUMBER
                 , aAccounts.IMF_NUMBER2
                 , aAccounts.IMF_NUMBER3
                 , aAccounts.IMF_NUMBER4
                 , aAccounts.IMF_NUMBER5
                 , aAccounts.IMF_TEXT1
                 , aAccounts.IMF_TEXT2
                 , aAccounts.IMF_TEXT3
                 , aAccounts.IMF_TEXT4
                 , aAccounts.IMF_TEXT5
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.USERINI
                  );
    end if;
  end CreateDetail;

  /**
   * procedure CreateEltCostDiff
   * Description
   *
   */
  function CreateEltCostDiff(
    aLotId              in FAL_LOT.FAL_LOT_ID%type
  , aPtcElementCostId   in PTC_ELEMENT_COST.PTC_ELEMENT_COST_ID%type
  , aCostElementType    in FAL_ELT_COST_DIFF.C_COST_ELEMENT_TYPE%type
  , aCostElementSubType in FAL_ELT_COST_DIFF.C_COST_ELEMENT_SUBTYPE%type
  , aDocNumber          in FAL_ELT_COST_DIFF.DOC_NUMBER%type
  , aDescription        in FAL_ELT_COST_DIFF.CTD_DESCRIPTION%type
  , aValueDate          in FAL_ELT_COST_DIFF.CTD_VALUE_DATE%type
  , aExpectedQty        in FAL_ELT_COST_DIFF.CTD_EXPECTED_QTY%type
  , aExpectedUnitValue  in FAL_ELT_COST_DIFF.CTD_EXPECTED_UNIT_VALUE%type
  , aExpectedCost       in FAL_ELT_COST_DIFF.CTD_EXPECTED_COST%type
  , aRealQty            in FAL_ELT_COST_DIFF.CTD_REAL_QTY%type
  , aRealUnitValue      in FAL_ELT_COST_DIFF.CTD_REAL_UNIT_VALUE%type
  , aRealCost           in FAL_ELT_COST_DIFF.CTD_REAL_COST%type
  , aQtyCostDiff        in FAL_ELT_COST_DIFF.CTD_QTY_COST_DIFF%type
  , aValueCostDiff      in FAL_ELT_COST_DIFF.CTD_VALUE_COST_DIFF%type
  )
    return FAL_ELT_COST_DIFF.FAL_ELT_COST_DIFF_ID%type
  is
    vEltCostDiffId FAL_ELT_COST_DIFF.FAL_ELT_COST_DIFF_ID%type;
  begin
    -- Insertion dans la table d'écarts
    insert into FAL_ELT_COST_DIFF
                (FAL_ELT_COST_DIFF_ID
               , FAL_LOT_ID
               , PTC_ELEMENT_COST_ID
               , C_COST_ELEMENT_TYPE
               , C_COST_ELEMENT_SUBTYPE
               , DOC_NUMBER
               , CTD_DESCRIPTION
               , CTD_VALUE_DATE
               , CTD_EXPECTED_QTY
               , CTD_EXPECTED_UNIT_VALUE
               , CTD_EXPECTED_COST
               , CTD_REAL_QTY
               , CTD_REAL_UNIT_VALUE
               , CTD_REAL_COST
               , CTD_QTY_COST_DIFF
               , CTD_VALUE_COST_DIFF
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId   --FAL_ELT_COST_DIFF_ID
               , aLotId
               , aPtcElementCostId
               , aCostElementType
               , aCostElementSubType
               , aDocNumber
               , nvl(aDescription, cDefaultDescr)
               , aValueDate
               , aExpectedQty
               , aExpectedUnitValue
               , aExpectedCost
               , aRealQty
               , aRealUnitValue
               , aRealCost
               , aQtyCostDiff
               , aValueCostDiff
               , sysdate
               , PCS.PC_I_LIB_SESSION.USERINI
                )
      returning FAL_ELT_COST_DIFF_ID
           into vEltCostDiffId;

    return vEltCostDiffId;
  end CreateEltCostDiff;

  /**
   * procedure CreateDetails
   * Description
   *
   */
  procedure CreateDetails(
    aEltCostDiffId in FAL_ELT_COST_DIFF.FAL_ELT_COST_DIFF_ID%type
  , aExpectedCost  in FAL_ELT_COST_DIFF_DET.CDD_AMOUNT%type
  , aQtyCostDiff   in FAL_ELT_COST_DIFF_DET.CDD_AMOUNT%type
  , aValueCostDiff in FAL_ELT_COST_DIFF_DET.CDD_AMOUNT%type
  , aLotId         in FAL_LOT.FAL_LOT_ID%type default null
  , aAccounts      in TAccounts
  )
  is
    vEntryKind FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_KIND%type;
    vEntrySign FAL_ELT_COST_DIFF_DET.C_FAL_ENTRY_SIGN%type;
    vDiffCpnId ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
  begin
    -- Création du détail prévisionnel crédit sur compo
    -- Contre-éciture partielle de celle effectuée sur le PT par ProcessPostCalculation
    CreateDetail(aEltCostDiffId => aEltCostDiffId, aEntryKind => ekExpEltCost, aAmount => -aExpectedCost, aLotId => aLotId, aAccounts => aAccounts);

    -- S'il existe un écart coût quantité
    if aQtyCostDiff <> 0 then
      -- Recherche du type d'écart et de la CPN d'écart quantité
      if aQtyCostDiff > 0 then
        vEntryKind  := ekUnfavorQtyCostDiff;

        select nvl(max(ACS_CPN_DEBIT_QTY_ID), aAccounts.ACS_CPN_ACCOUNT_ID)
          into vDiffCpnId
          from ACS_CPN_VARIANCE
         where ACS_CPN_VARIANCE_ID = aAccounts.ACS_CPN_ACCOUNT_ID;
      else
        vEntryKind  := ekFavorQtyCostDiff;

        select nvl(max(ACS_CPN_CREDIT_QTY_ID), aAccounts.ACS_CPN_ACCOUNT_ID)
          into vDiffCpnId
          from ACS_CPN_VARIANCE
         where ACS_CPN_VARIANCE_ID = aAccounts.ACS_CPN_ACCOUNT_ID;
      end if;

      -- Création du détail qté charge (compte écart)
      CreateDetail(aEltCostDiffId   => aEltCostDiffId
                 , aEntryKind       => vEntryKind
                 , aAmount          => aQtyCostDiff
                 , aCpnId           => vDiffCpnId
                 , aInitialCpnId    => aAccounts.ACS_CPN_ACCOUNT_ID
                 , aLotId           => aLotId
                 , aAccounts        => aAccounts
                  );
      -- Création du détail qté contre-écriture (compte élément de coût)
      CreateDetail(aEltCostDiffId => aEltCostDiffId, aEntryKind => vEntryKind, aAmount => -aQtyCostDiff, aLotId => aLotId, aAccounts => aAccounts);
    end if;

    -- S'il existe un écart coût valeur
    if aValueCostDiff <> 0 then
      -- Recherche de la CPN d'écart valeur
      if aValueCostDiff > 0 then
        vEntryKind  := ekUnfavorQtyCostDiff;

        select nvl(max(ACS_CPN_DEBIT_VALUE_ID), aAccounts.ACS_CPN_ACCOUNT_ID)
          into vDiffCpnId
          from ACS_CPN_VARIANCE
         where ACS_CPN_VARIANCE_ID = aAccounts.ACS_CPN_ACCOUNT_ID;
      else
        vEntryKind  := ekFavorQtyCostDiff;

        select nvl(max(ACS_CPN_CREDIT_VALUE_ID), aAccounts.ACS_CPN_ACCOUNT_ID)
          into vDiffCpnId
          from ACS_CPN_VARIANCE
         where ACS_CPN_VARIANCE_ID = aAccounts.ACS_CPN_ACCOUNT_ID;
      end if;

      -- Création du détail valeur charge (compte écart)
      CreateDetail(aEltCostDiffId   => aEltCostDiffId
                 , aEntryKind       => vEntryKind
                 , aAmount          => aValueCostDiff
                 , aCpnId           => vDiffCpnId
                 , aInitialCpnId    => aAccounts.ACS_CPN_ACCOUNT_ID
                 , aLotId           => aLotId
                 , aAccounts        => aAccounts
                  );
      -- Création du détail valeur contre-écriture (compte élément de coût)
      CreateDetail(aEltCostDiffId => aEltCostDiffId, aEntryKind => vEntryKind, aAmount => -aValueCostDiff, aLotId => aLotId, aAccounts => aAccounts);
    end if;
  end CreateDetails;

  /**
   * function GetAccountsCursor
   * Description
   *
   */
  function GetAccountsCursor(
    aCostElementType    in FAL_ELT_COST_DIFF.C_COST_ELEMENT_TYPE%type
  , aCostElementSubType in FAL_ELT_COST_DIFF.C_COST_ELEMENT_SUBTYPE%type
  , aLotId              in FAL_LOT.FAL_LOT_ID%type default null
  , aLotMaterialLinkId  in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aTaskLinkId         in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  )
    return SYS_REFCURSOR
  is
    crAccounts SYS_REFCURSOR;
  begin
    case aCostElementType
      when ctMaterial then
        -- Consommation composant et réception dérivé
        open crAccounts for
          select   sum(FEC.FEC_COMPLETED_AMOUNT) FEC_COMPLETED_AMOUNT
                 , sum(FEC.FEC_COMPLETED_QUANTITY) FEC_COMPLETED_QUANTITY
                 , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , SMO.ACS_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                 , SMO.ACS_ACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT_ID
                 , SMO.ACS_ACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT_ID
                 , SMO.ACS_ACS_PF_ACCOUNT_ID ACS_PF_ACCOUNT_ID
                 , SMO.ACS_ACS_PJ_ACCOUNT_ID ACS_PJ_ACCOUNT_ID
                 , null ACS_QTY_UNIT_ID
                 , SMO.DOC_RECORD_ID
                 , SMO.GCO_GOOD_ID
                 , SMO.FAM_FIXED_ASSETS_ID
                 , SMO.C_FAM_TRANSACTION_TYP
                 , SMO.HRM_PERSON_ID
                 , null PAC_PERSON_ID
                 , nvl(SMO.PAC_THIRD_ACI_ID, SMO.PAC_THIRD_ID) PAC_THIRD_ID
                 , SMO.DIC_IMP_FREE1_ID
                 , SMO.DIC_IMP_FREE2_ID
                 , SMO.DIC_IMP_FREE3_ID
                 , SMO.DIC_IMP_FREE4_ID
                 , SMO.DIC_IMP_FREE5_ID
                 , SMO.SMO_IMP_NUMBER_1 IMF_NUMBER
                 , SMO.SMO_IMP_NUMBER_2 IMF_NUMBER2
                 , SMO.SMO_IMP_NUMBER_3 IMF_NUMBER3
                 , SMO.SMO_IMP_NUMBER_4 IMF_NUMBER4
                 , SMO.SMO_IMP_NUMBER_5 IMF_NUMBER5
                 , SMO.SMO_IMP_TEXT_1 IMF_TEXT1
                 , SMO.SMO_IMP_TEXT_2 IMF_TEXT2
                 , SMO.SMO_IMP_TEXT_3 IMF_TEXT3
                 , SMO.SMO_IMP_TEXT_4 IMF_TEXT4
                 , SMO.SMO_IMP_TEXT_5 IMF_TEXT5
              from FAL_ELEMENT_COST FEC
                 , STM_STOCK_MOVEMENT SMO
                 , STM_MOVEMENT_KIND MOK
             where FEC.FAL_LOT_ID = aLotId
               and FEC.FAL_LOT_MATERIAL_LINK_ID = aLotMaterialLinkId
               and FEC.C_COST_ELEMENT_TYPE = aCostElementType
               and SMO.STM_STOCK_MOVEMENT_ID = FEC.STM_STOCK_MOVEMENT_ID
               and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
               and (    (    MOK.C_MOVEMENT_CODE = '017'
                         and MOK.C_MOVEMENT_SORT = 'SOR'
                         and MOK.C_MOVEMENT_TYPE = 'FAC')
                    or (    MOK.C_MOVEMENT_CODE = '020'
                        and MOK.C_MOVEMENT_SORT = 'ENT'
                        and MOK.C_MOVEMENT_TYPE = 'FAC'
                        and SMO.FAL_FACTORY_OUT_ID is not null)
                   )
          group by SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
                 , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
                 , SMO.ACS_ACS_CPN_ACCOUNT_ID
                 , SMO.ACS_ACS_CDA_ACCOUNT_ID
                 , SMO.ACS_ACS_PF_ACCOUNT_ID
                 , SMO.ACS_ACS_PJ_ACCOUNT_ID
                 , SMO.DOC_RECORD_ID
                 , SMO.GCO_GOOD_ID
                 , SMO.FAM_FIXED_ASSETS_ID
                 , SMO.C_FAM_TRANSACTION_TYP
                 , SMO.HRM_PERSON_ID
                 , nvl(SMO.PAC_THIRD_ACI_ID, SMO.PAC_THIRD_ID)
                 , SMO.DIC_IMP_FREE1_ID
                 , SMO.DIC_IMP_FREE2_ID
                 , SMO.DIC_IMP_FREE3_ID
                 , SMO.DIC_IMP_FREE4_ID
                 , SMO.DIC_IMP_FREE5_ID
                 , SMO.SMO_IMP_NUMBER_1
                 , SMO.SMO_IMP_NUMBER_2
                 , SMO.SMO_IMP_NUMBER_3
                 , SMO.SMO_IMP_NUMBER_4
                 , SMO.SMO_IMP_NUMBER_5
                 , SMO.SMO_IMP_TEXT_1
                 , SMO.SMO_IMP_TEXT_2
                 , SMO.SMO_IMP_TEXT_3
                 , SMO.SMO_IMP_TEXT_4
                 , SMO.SMO_IMP_TEXT_5;
      when ctSubContract then
        -- Sous-traitance
        -- Attention, on utilise FEC_CURRENT_AMOUNT et FEC_CURRENT_QUANTITY car
        -- les comptes sont portés par la facture qui a généré les en-cours.
        open crAccounts for
          select   sum(FEC.FEC_CURRENT_AMOUNT) FEC_COMPLETED_AMOUNT
                 , sum(FEC.FEC_CURRENT_QUANTITY) FEC_COMPLETED_QUANTITY
                 , POS.ACS_FINANCIAL_ACCOUNT_ID
                 , POS.ACS_DIVISION_ACCOUNT_ID
                 , POS.ACS_CPN_ACCOUNT_ID
                 , POS.ACS_CDA_ACCOUNT_ID
                 , POS.ACS_PF_ACCOUNT_ID
                 , POS.ACS_PJ_ACCOUNT_ID
                 , null ACS_QTY_UNIT_ID
                 , POS.DOC_RECORD_ID
                 , POS.GCO_GOOD_ID
                 , POS.FAM_FIXED_ASSETS_ID
                 , POS.C_FAM_TRANSACTION_TYP
                 , POS.HRM_PERSON_ID
                 , POS.PAC_PERSON_ID
                 , nvl(POS.PAC_THIRD_ACI_ID, POS.PAC_THIRD_ID) PAC_THIRD_ID
                 , POS.DIC_IMP_FREE1_ID
                 , POS.DIC_IMP_FREE2_ID
                 , POS.DIC_IMP_FREE3_ID
                 , POS.DIC_IMP_FREE4_ID
                 , POS.DIC_IMP_FREE5_ID
                 , POS.POS_NUMBER IMF_NUMBER
                 , POS.POS_IMF_NUMBER_2 IMF_NUMBER2
                 , POS.POS_IMF_NUMBER_3 IMF_NUMBER3
                 , POS.POS_IMF_NUMBER_4 IMF_NUMBER4
                 , POS.POS_IMF_NUMBER_5 IMF_NUMBER5
                 , POS.POS_IMF_TEXT_1 IMF_TEXT1
                 , POS.POS_IMF_TEXT_2 IMF_TEXT2
                 , POS.POS_IMF_TEXT_3 IMF_TEXT3
                 , POS.POS_IMF_TEXT_4 IMF_TEXT4
                 , POS.POS_IMF_TEXT_5 IMF_TEXT5
              from FAL_ELEMENT_COST FEC
                 , STM_STOCK_MOVEMENT SMO
                 , DOC_POSITION_DETAIL PDE
                 , DOC_POSITION POS
             where FEC.FAL_LOT_ID = aLotId
               and FEC.FAL_SCHEDULE_STEP_ID = aTaskLinkId
               and FEC.C_COST_ELEMENT_TYPE = aCostElementType
               and SMO.STM_STOCK_MOVEMENT_ID = FEC.STM_STOCK_MOVEMENT_ID
               and PDE.DOC_POSITION_DETAIL_ID = SMO.DOC_POSITION_DETAIL_ID
               and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
          group by POS.ACS_FINANCIAL_ACCOUNT_ID
                 , POS.ACS_DIVISION_ACCOUNT_ID
                 , POS.ACS_CPN_ACCOUNT_ID
                 , POS.ACS_CDA_ACCOUNT_ID
                 , POS.ACS_PF_ACCOUNT_ID
                 , POS.ACS_PJ_ACCOUNT_ID
                 , POS.DOC_RECORD_ID
                 , POS.GCO_GOOD_ID
                 , POS.FAM_FIXED_ASSETS_ID
                 , POS.C_FAM_TRANSACTION_TYP
                 , POS.HRM_PERSON_ID
                 , POS.PAC_PERSON_ID
                 , nvl(POS.PAC_THIRD_ACI_ID, POS.PAC_THIRD_ID)
                 , POS.DIC_IMP_FREE1_ID
                 , POS.DIC_IMP_FREE2_ID
                 , POS.DIC_IMP_FREE3_ID
                 , POS.DIC_IMP_FREE4_ID
                 , POS.DIC_IMP_FREE5_ID
                 , POS.POS_NUMBER
                 , POS.POS_IMF_NUMBER_2
                 , POS.POS_IMF_NUMBER_3
                 , POS.POS_IMF_NUMBER_4
                 , POS.POS_IMF_NUMBER_5
                 , POS.POS_IMF_TEXT_1
                 , POS.POS_IMF_TEXT_2
                 , POS.POS_IMF_TEXT_3
                 , POS.POS_IMF_TEXT_4
                 , POS.POS_IMF_TEXT_5;
      else
        -- Suivi de fabrication
        -- Attention, on utilise FEC_CURRENT_AMOUNT et FEC_CURRENT_QUANTITY car
        -- les comptes sont portés par les détails d'historique d'imputation des
        -- heures qui ont généré les en-cours.
        open crAccounts for
          select   sum(FEC.FEC_CURRENT_AMOUNT) FEC_COMPLETED_AMOUNT
                 , sum(FEC.FEC_CURRENT_QUANTITY) FEC_COMPLETED_QUANTITY
                 , THD.ACS_FINANCIAL_ACCOUNT_ID
                 , THD.ACS_DIVISION_ACCOUNT_ID
                 , THD.ACS_CPN_ACCOUNT_ID
                 , THD.ACS_CDA_ACCOUNT_ID
                 , THD.ACS_PF_ACCOUNT_ID
                 , THD.ACS_PJ_ACCOUNT_ID
                 , THD.ACS_QTY_UNIT_ID
                 , THD.DOC_RECORD_ID
                 , THD.GCO_GOOD_ID
                 , THD.FAM_FIXED_ASSETS_ID
                 , null C_FAM_TRANSACTION_TYP
                 , THD.HRM_PERSON_ID
                 , THD.PAC_PERSON_ID
                 , null PAC_THIRD_ID
                 , THD.DIC_IMP_FREE1_ID
                 , THD.DIC_IMP_FREE2_ID
                 , THD.DIC_IMP_FREE3_ID
                 , THD.DIC_IMP_FREE4_ID
                 , THD.DIC_IMP_FREE5_ID
                 , THD.IMF_NUMBER
                 , THD.IMF_NUMBER2
                 , THD.IMF_NUMBER3
                 , THD.IMF_NUMBER4
                 , THD.IMF_NUMBER5
                 , THD.IMF_TEXT1
                 , THD.IMF_TEXT2
                 , THD.IMF_TEXT3
                 , THD.IMF_TEXT4
                 , THD.IMF_TEXT5
              from FAL_ELEMENT_COST FEC
                 , FAL_ACI_TIME_HIST TIH
                 , FAL_ACI_TIME_HIST_DET THD
             where FEC.FAL_LOT_ID = aLotId
               and FEC.FAL_SCHEDULE_STEP_ID = aTaskLinkId
               and FEC.C_COST_ELEMENT_TYPE = aCostElementType
               and TIH.FAL_ACI_TIME_HIST_ID = FEC.FAL_ACI_TIME_HIST_ID
               and THD.FAL_ACI_TIME_HIST_ID = TIH.FAL_ACI_TIME_HIST_ID
               and THD.C_FAL_ENTRY_SIGN = esDebit
               and (    (    aCostElementSubType = cstWork
                         and THD.C_FAL_ENTRY_TYPE in(FAL_ACI_TIME_ENTRY_FCT.etMachWork, FAL_ACI_TIME_ENTRY_FCT.etOperWork) )
                    or (    aCostElementSubType = cstAdjusting
                        and THD.C_FAL_ENTRY_TYPE in(FAL_ACI_TIME_ENTRY_FCT.etMachAdj, FAL_ACI_TIME_ENTRY_FCT.etOperAdj) )
                   )
          group by THD.ACS_FINANCIAL_ACCOUNT_ID
                 , THD.ACS_DIVISION_ACCOUNT_ID
                 , THD.ACS_CPN_ACCOUNT_ID
                 , THD.ACS_CDA_ACCOUNT_ID
                 , THD.ACS_PF_ACCOUNT_ID
                 , THD.ACS_PJ_ACCOUNT_ID
                 , THD.ACS_QTY_UNIT_ID
                 , THD.DOC_RECORD_ID
                 , THD.GCO_GOOD_ID
                 , THD.FAM_FIXED_ASSETS_ID
                 , THD.HRM_PERSON_ID
                 , THD.PAC_PERSON_ID
                 , THD.DIC_IMP_FREE1_ID
                 , THD.DIC_IMP_FREE2_ID
                 , THD.DIC_IMp_FREE3_ID
                 , THD.DIC_IMP_FREE4_ID
                 , THD.DIC_IMP_FREE5_ID
                 , THD.IMF_NUMBER
                 , THD.IMF_NUMBER2
                 , THD.IMF_NUMBER3
                 , THD.IMF_NUMBER4
                 , THD.IMF_NUMBER5
                 , THD.IMF_TEXT1
                 , THD.IMF_TEXT2
                 , THD.IMF_TEXT3
                 , THD.IMF_TEXT4
                 , THD.IMF_TEXT5;
    end case;

    return crAccounts;
  end GetAccountsCursor;

  /**
   * function CreateEltCostDiffAndDetails
   * Description
   *
   */
  function CreateEltCostDiffAndDetails(
    aLotId              in FAL_LOT.FAL_LOT_ID%type
  , aGoodId             in GCO_GOOD.GCO_GOOD_ID%type
  , aCostElementType    in FAL_ELT_COST_DIFF.C_COST_ELEMENT_TYPE%type
  , aCostElementSubType in FAL_ELT_COST_DIFF.C_COST_ELEMENT_SUBTYPE%type default null
  , aPtcElementCostId   in PTC_ELEMENT_COST.PTC_ELEMENT_COST_ID%type
  , aPtcUsedComponentId in PTC_USED_COMPONENT.PTC_USED_COMPONENT_ID%type default null
  , aLotMaterialLinkId  in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aPtcUsedTaskId      in PTC_USED_TASK.PTC_USED_TASK_ID%type default null
  , aTaskLinkId         in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , aDocNumber          in FAL_ELT_COST_DIFF.DOC_NUMBER%type
  , aDescription        in FAL_ELT_COST_DIFF.CTD_DESCRIPTION%type
  , aValueDate          in FAL_ELT_COST_DIFF.CTD_VALUE_DATE%type
  , aExpectedQty        in FAL_ELT_COST_DIFF.CTD_EXPECTED_QTY%type
  , aExpectedUnitValue  in FAL_ELT_COST_DIFF.CTD_EXPECTED_UNIT_VALUE%type
  , aExpectedCost       in FAL_ELT_COST_DIFF.CTD_EXPECTED_COST%type
  , aRealQty            in FAL_ELT_COST_DIFF.CTD_REAL_QTY%type
  , aRealUnitValue      in FAL_ELT_COST_DIFF.CTD_REAL_UNIT_VALUE%type
  , aRealCost           in FAL_ELT_COST_DIFF.CTD_REAL_COST%type
  , aProductAccounts    in TAccounts
  )
    return FAL_ELT_COST_DIFF.FAL_ELT_COST_DIFF_ID%type
  is
    -- Comptes
    crAccounts           SYS_REFCURSOR;
    tplAccount           TAccounts;
    vAccounts            TAccounts;
    vHrmPersonId         HRM_PERSON.HRM_PERSON_ID%type;
    vDocRecordId         DOC_RECORD.DOC_RECORD_ID%type;
    vFactoryFloorId      FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
    vFinancialId         ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    vDivisionId          ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vCpnId               ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    vCdaId               ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type;
    vPfId                ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type;
    vPjId                ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type;
    vQtyId               ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    vAccountInfo         ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vStockFinancialId    ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    vStockDivisionId     ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vStockCpnId          ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    vStockCdaId          ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type;
    vStockPflId          ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type;
    vStockPjId           ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type;
    vStockAccountInfo    ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vFinancial           STM_MOVEMENT_KIND.MOK_FINANCIAL_IMPUTATION%type;
    vAnalytical          STM_MOVEMENT_KIND.MOK_ANAL_IMPUTATION%type;
    vInfoCompl           STM_MOVEMENT_KIND.MOK_USE_MANAGED_DATA%type;
    vKindCom             varchar2(10);
    vStockId             number;
    vStockLocationId     number;
    vMvtKindId           number;
    vErrorMsg            varchar2(4000);
    vGaugeId             number;
    vThirdId             number;
    vServiceId           number;
    -- Variables calculs
    vQtyCostDiff         FAL_ELT_COST_DIFF.CTD_QTY_COST_DIFF%type;
    vValueCostDiff       FAL_ELT_COST_DIFF.CTD_VALUE_COST_DIFF%type;
    vRemainExpectedCost  FAL_ELT_COST_DIFF.CTD_EXPECTED_COST%type;
    vRemainQtyCostDiff   FAL_ELT_COST_DIFF.CTD_QTY_COST_DIFF%type;
    vRemainValueCostDiff FAL_ELT_COST_DIFF.CTD_VALUE_COST_DIFF%type;
    vDetExpectedCost     FAL_ELT_COST_DIFF.CTD_EXPECTED_COST%type;
    vDetQtyCostDiff      FAL_ELT_COST_DIFF.CTD_QTY_COST_DIFF%type;
    vDetValueCostDiff    FAL_ELT_COST_DIFF.CTD_VALUE_COST_DIFF%type;
    vCount               integer;
    vTotalCount          integer;
    vEltCostDiffId       FAL_ELT_COST_DIFF.FAL_ELT_COST_DIFF_ID%type;
    vEntryType           FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE%type;
  begin
    if     aExpectedQty = 0
       and aRealQty <> 0 then
      vQtyCostDiff    := aRealCost;
      vValueCostDiff  := 0;
    elsif     aExpectedQty <> 0
          and aRealQty = 0 then
      vQtyCostDiff    := -aExpectedCost;
      vValueCostDiff  := 0;
    elsif     aExpectedQty = 0
          and aRealQty = 0 then
      vQtyCostDiff    := 0;
      vValueCostDiff  := aRealCost - aExpectedCost;
    else
      vQtyCostDiff    := aExpectedUnitValue *(aRealQty - aExpectedQty);
      vValueCostDiff  := aRealQty *(aRealUnitValue - aExpectedUnitValue);
    end if;

    if (aRealCost - aExpectedCost) <>(vQtyCostDiff + vValueCostDiff) then
      ra('(RealCost - ExpectedCost) <> (QtyCostDiff + ValueCostDiff)');
    end if;

    vEltCostDiffId  :=
      CreateEltCostDiff(aLotId                => aLotId
                      , aPtcElementCostId     => aPtcElementCostId
                      , aCostElementType      => aCostElementType
                      , aCostElementSubType   => aCostElementSubType
                      , aDocNumber            => aDocNumber
                      , aDescription          => aDescription
                      , aValueDate            => aValueDate
                      , aExpectedQty          => aExpectedQty
                      , aExpectedUnitValue    => aExpectedUnitValue
                      , aExpectedCost         => aExpectedCost
                      , aRealQty              => aRealQty
                      , aRealUnitValue        => aRealUnitValue
                      , aRealCost             => aRealCost
                      , aQtyCostDiff          => vQtyCostDiff
                      , aValueCostDiff        => vValueCostDiff
                       );
    -- Réalisé : débit sur compo + crédit sur stock compo (généré par les suivis et mvts de composants)

    -- Prévisionnel : débit sur PT + crédit sur compo

    -- Réception : débit sur stock PT + crédit sur PT (généré par la réception)

    -- Ecarts : débit sur compo  + favorable sur CPN écart compo
    --       ou crédit sur compo + défavorable sur CPN écart compo

    -- Création du détail prévisionnel débit sur PT
    CreateDetail(aEltCostDiffId => vEltCostDiffId, aEntryKind => ekExpProduct, aAmount => aExpectedCost, aLotId => aLotId, aAccounts => aProductAccounts);

    -- Si des comptes ont été imputés par le réalisé, on les reprends
    -- (répartition de l'écart au prorata de la quantité),
    -- sinon on simule la recherche des comptes qui aurait eu lieu.
    if    aLotMaterialLinkId is not null
       or aTaskLinkId is not null then
      vRemainExpectedCost   := aExpectedCost;
      vRemainQtyCostDiff    := vQtyCostDiff;
      vRemainValueCostDiff  := vValueCostDiff;
      vCount                := 0;
      crAccounts            :=
        GetAccountsCursor(aCostElementType      => aCostElementType
                        , aCostElementSubType   => aCostElementSubType
                        , aLotId                => aLotId
                        , aLotMaterialLinkId    => aLotMaterialLinkId
                        , aTaskLinkId           => aTaskLinkId
                         );

      -- Pour chaque groupe de comptes trouvé
      fetch crAccounts
       into tplAccount;

      vTotalCount           := crAccounts%rowcount;

      while crAccounts%found loop
        vCount                := vCount + 1;

        if vCount = vTotalCount then
          -- Si c'est le dernier groupe, on attribue tout ce qu'il reste
          vDetExpectedCost   := vRemainExpectedCost;
          vDetQtyCostDiff    := vRemainQtyCostDiff;
          vDetValueCostDiff  := vRemainValueCostDiff;
        elsif aRealQty = 0 then
          -- Si la quantité réelle est nulle, on attribue équitablement (au maximum des diffs de coût restantes)
          vDetExpectedCost   := sign(aExpectedCost) * least(abs(vRemainExpectedCost), abs(aExpectedCost / vTotalCount) );
          vDetQtyCostDiff    := sign(vQtyCostDiff) * least(abs(vRemainQtyCostDiff), abs(vQtyCostDiff / vTotalCount) );
          vDetValueCostDiff  := sign(vValueCostDiff) * least(abs(vRemainValueCostDiff), abs(vValueCostDiff / vTotalCount) );
        else
          -- Sinon on attribue au prorata de la quantité (au maximum des diffs de coût restantes)
          vDetExpectedCost   := sign(aExpectedCost) * least(abs(vRemainExpectedCost), abs(aExpectedCost * tplAccount.FEC_COMPLETED_QUANTITY / aRealQty) );
          vDetQtyCostDiff    := sign(vQtyCostDiff) * least(abs(vRemainQtyCostDiff), abs(vQtyCostDiff * tplAccount.FEC_COMPLETED_QUANTITY / aRealQty) );
          vDetValueCostDiff  := sign(vValueCostDiff) * least(abs(vRemainValueCostDiff), abs(vValueCostDiff * tplAccount.FEC_COMPLETED_QUANTITY / aRealQty) );
        end if;

        -- Création des détails :
        --  - prévisionnel crédit sur compo
        --  - qté charge
        --  - qté contre-écriture
        --  - valeur charge
        --  - valeur contre-écriture
        CreateDetails(aEltCostDiffId   => vEltCostDiffId
                    , aExpectedCost    => vDetExpectedCost
                    , aQtyCostDiff     => vDetQtyCostDiff
                    , aValueCostDiff   => vDetValueCostDiff
                    , aLotId           => aLotId
                    , aAccounts        => tplAccount
                     );
        -- Mise à jour des diffs de coût restantes
        vRemainExpectedCost   := sign(aExpectedCost) * greatest(0, abs(vRemainExpectedCost) - abs(vDetExpectedCost) );
        vRemainQtyCostDiff    := sign(vQtyCostDiff) * greatest(0, abs(vRemainQtyCostDiff) - abs(vDetQtyCostDiff) );
        vRemainValueCostDiff  := sign(vValueCostDiff) * greatest(0, abs(vRemainValueCostDiff) - abs(vDetValueCostDiff) );

        fetch crAccounts
         into tplAccount;
      end loop;
    else
      -- Recherche des comptes qui auraient été trouvés en conso compo/confirmation FST/imputation d'heures
      if aCostElementType = ctMaterial then
        -- Recherche du type de composant
        select C_KIND_COM
             , STM_STOCK_ID
             , STM_LOCATION_ID
          into vKindCom
             , vStockId
             , vStockLocationId
          from PTC_USED_COMPONENT
         where PTC_USED_COMPONENT_ID = aPtcUsedComponentId;

        if vKindCom = 2 then
          -- Recherche du genre de mouvement de réception d'un produit dérivé
              -- Utilisation du stock et emplacement du composant
          vMvtKindId  := FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindByProductRecept;
        else
          -- Recherche du genre de mouvement de consommation composant
          vMvtKindId        := FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindConsumedComp;
          -- Déterminer le Stock et l'emplacement Atelier ...
          vStockId          := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_FLOOR');
          vStockLocationId  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_FLOOR', vStockId);
        end if;

        -- Recherche des comptes
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetMvtAccounts(iGoodId           => aGoodId
                                                  , iLocationId       => vStockLocationId
                                                  , iStockId          => vStockId
                                                  , iMovementKindId   => vMvtKindId
                                                  , iPositionId       => null
                                                  , iDocumentId       => null
                                                  , iDateRef          => aValueDate
                                                  , ioFinAccountId    => vStockFinancialId
                                                  , ioDivAccountId    => vStockDivisionId
                                                  , ioCpnAccountId    => vStockCpnId
                                                  , ioCdaAccountId    => vStockCdaId
                                                  , ioPfAccountId     => vStockPflId
                                                  , ioPjAccountId     => vStockPjId
                                                  , ioFinAccountId2   => vFinancialId
                                                  , ioDivAccountId2   => vDivisionId
                                                  , ioCpnAccountId2   => vCpnId
                                                  , ioCdaAccountId2   => vCdaId
                                                  , ioPfAccountId2    => vPfId
                                                  , ioPjAccountId2    => vPjId
                                                  , iotAccountInfo    => vStockAccountInfo
                                                  , iotAccountInfo2   => vAccountInfo
                                                  , obFinancial       => vFinancial
                                                  , obAnalytical      => vAnalytical
                                                  , obInfoCompl       => vInfoCompl
                                                  , iThirdId          => null
                                                   );
        vHrmPersonId  := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON);
      elsif aCostElementType = ctSubContract then
        -- Recherche du gabarit - A améliorer
        select GAU.DOC_GAUGE_ID
          into vGaugeId
          from DOC_GAUGE GAU
         where instr(PCS.PC_CONFIG.GetConfig('DOC_GAUGE_OP_SUBCONTRACT'), GAU.DIC_GAUGE_TYPE_DOC_ID) <> 0
           and instr(PCS.PC_CONFIG.GetConfig('DOC_GAUGE_OP_SUBCONTRACT'), GAU.DIC_GAUGE_TYPE_DOC_ID) =
                                                            (select min(instr(PCS.PC_CONFIG.GetConfig('DOC_GAUGE_OP_SUBCONTRACT'), GAU.DIC_GAUGE_TYPE_DOC_ID) )
                                                               from DOC_GAUGE GAU
                                                              where instr(PCS.PC_CONFIG.GetConfig('DOC_GAUGE_OP_SUBCONTRACT'), GAU.DIC_GAUGE_TYPE_DOC_ID) <> 0);

        -- Recherche du tiers et du bien connecté
        select PAC_SUPPLIER_PARTNER_ID
             , GCO_GOOD_ID
          into vThirdId
             , vServiceId
          from PTC_USED_TASK
         where PTC_USED_TASK_ID = aPtcUsedTaskId;

        -- Recherche des comptes
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(iElementId         => vServiceId
                                               , iElementType       => '10'   -- Bien (position)
                                               , iAdminDomain       => '1'   -- Achat
                                               , iDateRef           => aValueDate
                                               , iGoodId            => vServiceId
                                               , iGaugeId           => vGaugeId
                                               , iDocumentId        => null
                                               , iPositionId        => null
                                               , iRecordId          => null
                                               , iThirdId           => vThirdId
                                               , iInFinancialId     => null
                                               , iInDivisionId      => null
                                               , iInCPNAccountId    => null
                                               , iInCDAAccountId    => null
                                               , iInPFAccountId     => null
                                               , iInPJAccountId     => null
                                               , ioFinancialId      => vFinancialId
                                               , ioDivisionId       => vDivisionId
                                               , iOutCPNAccountId   => vCpnId
                                               , iOutCDAAccountId   => vCdaId
                                               , iOutPFAccountId    => vPfId
                                               , iOutPJAccountId    => vPjId
                                               , iotAccountInfo     => vAccountInfo
                                                );
      elsif aCostElementType in(ctMachine, ctOperator) then
        case
          when aCostElementType = ctMachine then
            select FAL_FACTORY_FLOOR_ID
              into vFactoryFloorId
              from PTC_USED_TASK
             where PTC_USED_TASK_ID = aPtcUsedTaskId;

            case
              when aCostElementSubType = cstWork then
                vEntryType  := FAL_ACI_TIME_ENTRY_FCT.etMachWork;
              when aCostElementSubType = cstAdjusting then
                vEntryType  := FAL_ACI_TIME_ENTRY_FCT.etMachAdj;
            end case;
          when aCostElementType = ctOperator then
            select nvl(FAL_FAL_FACTORY_FLOOR_ID, FAL_FACTORY_FLOOR_ID)
              into vFactoryFloorId
              from PTC_USED_TASK
             where PTC_USED_TASK_ID = aPtcUsedTaskId;

            case
              when aCostElementSubType = cstWork then
                vEntryType  := FAL_ACI_TIME_ENTRY_FCT.etOperWork;
              when aCostElementSubType = cstAdjusting then
                vEntryType  := FAL_ACI_TIME_ENTRY_FCT.etOperAdj;
            end case;
        end case;

        -- Simulation de recherche des comptes pour l'imputation des heures
        FAL_ACI_TIME_ENTRY_FCT.GetAccounts(aEntryType        => vEntryType
                                         , aEntrySign        => esCredit
                                         , aValueDate        => aValueDate
                                         , aProgressOrigin   => FAL_ACI_TIME_ENTRY_FCT.poProduction
                                         , aLotProgressId    => null
                                         , aFactoryFloorId   => vFactoryFloorId
                                         , aLotId            => aLotId
                                         , aGoodId           => aGoodId
                                         , aDocRecordId      => vDocRecordId
                                         , aHrmPersonId      => vHrmPersonId
                                         , aFinancialId      => vFinancialId
                                         , aDivisionId       => vDivisionId
                                         , aCpnId            => vCpnId
                                         , aCdaId            => vCdaId
                                         , aPfId             => vPfId
                                         , aPjId             => vPjId
                                         , aQtyId            => vQtyId
                                         , aAccountInfo      => vAccountInfo
                                          );
      end if;

      vAccounts.GCO_GOOD_ID               := aGoodId;
      vAccounts.DOC_RECORD_ID             := vDocRecordId;
      vAccounts.HRM_PERSON_ID             := vHrmPersonId;
      vAccounts.ACS_FINANCIAL_ACCOUNT_ID  := vFinancialId;
      vAccounts.ACS_DIVISION_ACCOUNT_ID   := vDivisionId;
      vAccounts.ACS_CPN_ACCOUNT_ID        := vCpnId;
      vAccounts.ACS_CDA_ACCOUNT_ID        := vCdaId;
      vAccounts.ACS_PF_ACCOUNT_ID         := vPfId;
      vAccounts.ACS_PJ_ACCOUNT_ID         := vPjId;
      vAccounts.ACS_QTY_UNIT_ID           := vQtyId;
      vAccounts.FAM_FIXED_ASSETS_ID       := vAccountInfo.FAM_FIXED_ASSETS_ID;
      vAccounts.C_FAM_TRANSACTION_TYP     := vAccountInfo.C_FAM_TRANSACTION_TYP;
      vAccounts.DIC_IMP_FREE1_ID          := vAccountInfo.DEF_DIC_IMP_FREE1;
      vAccounts.DIC_IMP_FREE2_ID          := vAccountInfo.DEF_DIC_IMP_FREE2;
      vAccounts.DIC_IMP_FREE3_ID          := vAccountInfo.DEF_DIC_IMP_FREE3;
      vAccounts.DIC_IMP_FREE4_ID          := vAccountInfo.DEF_DIC_IMP_FREE4;
      vAccounts.DIC_IMP_FREE5_ID          := vAccountInfo.DEF_DIC_IMP_FREE5;
      vAccounts.IMF_NUMBER                := vAccountInfo.DEF_NUMBER1;
      vAccounts.IMF_NUMBER2               := vAccountInfo.DEF_NUMBER2;
      vAccounts.IMF_NUMBER3               := vAccountInfo.DEF_NUMBER3;
      vAccounts.IMF_NUMBER4               := vAccountInfo.DEF_NUMBER4;
      vAccounts.IMF_NUMBER5               := vAccountInfo.DEF_NUMBER5;
      vAccounts.IMF_TEXT1                 := vAccountInfo.DEF_TEXT1;
      vAccounts.IMF_TEXT2                 := vAccountInfo.DEF_TEXT2;
      vAccounts.IMF_TEXT3                 := vAccountInfo.DEF_TEXT3;
      vAccounts.IMF_TEXT4                 := vAccountInfo.DEF_TEXT4;
      vAccounts.IMF_TEXT5                 := vAccountInfo.DEF_TEXT5;
      -- Création des détails
      CreateDetails(aEltCostDiffId   => vEltCostDiffId
                  , aExpectedCost    => aExpectedCost
                  , aQtyCostDiff     => -aExpectedCost
                  , aValueCostDiff   => 0
                  , aLotId           => aLotId
                  , aAccounts        => vAccounts
                   );
    end if;

    return vEltCostDiffId;
  end CreateEltCostDiffAndDetails;

     /**
  * procedure ProcessPostCalculation
  * Description
  *   Renseigne la table XXXXX à partir des données des enregistrements temporaires
  */
  procedure ProcessPostCalculation(
    aLotId        in FAL_ACI_POSTCALCULATION.FAL_LOT_ID%type
  , aDescription  in FAL_ACI_POSTCALCULATION.APC_DESCRIPTION%type
  , aValueDate    in FAL_ACI_POSTCALCULATION.APC_VALUE_DATE%type
  , aBalancedDate in FAL_ACI_POSTCALCULATION.APC_BALANCED_DATE%type
  , aGoodId       in FAL_LOT.GCO_GOOD_ID%type
  )
  is
    cursor crElementCosts(aLotId in FAL_ACI_POSTCALCULATION.FAL_LOT_ID%type)
    is
      select   FEC.C_COST_ELEMENT_TYPE
             , ELC.PTC_ELEMENT_COST_ID
             , nvl(ELC.ELC_AMOUNT, 0) ELC_AMOUNT
             , nvl(FEC.FEC_COMPLETED_AMOUNT, 0) FEC_COMPLETED_AMOUNT
             , nvl(ELC.LOM_SEQ, FEC.LOM_SEQ) LOM_SEQ
             , nvl(ELC.SCS_STEP_NUMBER, FEC.SCS_STEP_NUMBER) SCS_STEP_NUMBER
             , nvl(ELC.GCO_GOOD_ID, FEC.GCO_GOOD_ID) GCO_GOOD_ID
             , nvl(ELC.FAL_TASK_ID, FEC.FAL_TASK_ID) FAL_TASK_ID
             , ELC.PUT_ADJUSTING_TIME
             , ELC.PUT_QTY_FIX_ADJUSTING
             , ELC.PUT_WORK_TIME
             , ELC.PUT_QTY_REF_WORK
             , ELC.PUT_AMOUNT
             , nvl(ELC.PUT_QTY_REF_AMOUNT, 0) PUT_QTY_REF_AMOUNT
             , ELC.PUT_DIVISOR
             , ELC.PUT_ADJUSTING_FLOOR
             , ELC.PUT_WORK_FLOOR
             , ELC.PUT_ADJUSTING_OPERATOR
             , ELC.PUT_WORK_OPERATOR
             , ELC.PUT_NUM_ADJUST_OPERATOR
             , ELC.PUT_NUM_WORK_OPERATOR
             , ELC.PUT_PERCENT_ADJUST_OPER
             , ELC.PUT_PERCENT_WORK_OPER
             , ELC.PUT_MINUTE_RATE
             , ELC.C_TASK_IMPUTATION
             , ELC.PUT_MACH_RATE
             , ELC.PUT_MO_RATE
             , nvl(ELC.PUC_CALCUL_QTY, 0) PUC_CALCUL_QTY
             , nvl(ELC.PUC_UTIL_COEFF, 1) PUC_UTIL_COEFF
             , nvl(ELC.PUC_NUMBER_OF_DECIMAL, 0) PUC_NUMBER_OF_DECIMAL
             , nvl(FEC.FEC_COMPLETED_QUANTITY, 0) FEC_COMPLETED_QUANTITY
             , ELC.PTC_USED_COMPONENT_ID
             , ELC.PTC_USED_TASK_ID
             , FEC.FAL_LOT_MATERIAL_LINK_ID
             , FEC.FAL_SCHEDULE_STEP_ID
             , nvl(FEC.TIH_ADJ_TIME_MACH_AMOUNT, 0) TIH_ADJ_TIME_MACH_AMOUNT
             , nvl(FEC.TIH_ADJ_TIME_MACH_QTY, 0) TIH_ADJ_TIME_MACH_QTY
             , nvl(FEC.TIH_ADJ_TIME_MACH_RATE, 0) TIH_ADJ_TIME_MACH_RATE
             , nvl(FEC.TIH_ADJ_TIME_OPER_AMOUNT, 0) TIH_ADJ_TIME_OPER_AMOUNT
             , nvl(FEC.TIH_ADJ_TIME_OPER_QTY, 0) TIH_ADJ_TIME_OPER_QTY
             , nvl(FEC.TIH_ADJ_TIME_OPER_RATE, 0) TIH_ADJ_TIME_OPER_RATE
             , nvl(FEC.TIH_WORK_TIME_MACH_ADD_AMOUNT, 0) TIH_WORK_TIME_MACH_ADD_AMOUNT
             , nvl(FEC.TIH_WORK_TIME_MACH_AMOUNT, 0) TIH_WORK_TIME_MACH_AMOUNT
             , nvl(FEC.TIH_WORK_TIME_MACH_QTY, 0) TIH_WORK_TIME_MACH_QTY
             , nvl(FEC.TIH_WORK_TIME_MACH_RATE, 0) TIH_WORK_TIME_MACH_RATE
             , nvl(FEC.TIH_WORK_TIME_OPER_AMOUNT, 0) TIH_WORK_TIME_OPER_AMOUNT
             , nvl(FEC.TIH_WORK_TIME_OPER_QTY, 0) TIH_WORK_TIME_OPER_QTY
             , nvl(FEC.TIH_WORK_TIME_OPER_RATE, 0) TIH_WORK_TIME_OPER_RATE
          from (select ELC_P.PTC_ELEMENT_COST_ID
                     , ELC_P.PTC_FIXED_COSTPRICE_ID
                     , ELC_P.C_COST_ELEMENT_TYPE
                     , ELC_P.PTC_USED_COMPONENT_ID
                     , nvl(PUC_P.PUC_SEQ, -1) LOM_SEQ
                     , nvl(nvl(PUC_P.GCO_GCO_GOOD_ID, PUC_P.GCO_GOOD_ID), 0) GCO_GOOD_ID
                     , ELC_P.PTC_USED_TASK_ID
                     , nvl(PUT_P.PUT_STEP_NUMBER, -1) SCS_STEP_NUMBER
                     , nvl(PUT_P.FAL_TASK_ID, 0) FAL_TASK_ID
                     , ELC_AMOUNT
                     , PUT_P.PUT_ADJUSTING_TIME
                     , PUT_P.PUT_QTY_FIX_ADJUSTING
                     , PUT_P.PUT_WORK_TIME
                     , PUT_P.PUT_QTY_REF_WORK
                     , PUT_P.PUT_AMOUNT
                     , PUT_P.PUT_QTY_REF_AMOUNT
                     , PUT_P.PUT_DIVISOR
                     , PUT_P.PUT_ADJUSTING_FLOOR
                     , PUT_P.PUT_WORK_FLOOR
                     , PUT_P.PUT_ADJUSTING_OPERATOR
                     , PUT_P.PUT_WORK_OPERATOR
                     , PUT_P.PUT_NUM_ADJUST_OPERATOR
                     , PUT_P.PUT_NUM_WORK_OPERATOR
                     , PUT_P.PUT_PERCENT_ADJUST_OPER
                     , PUT_P.PUT_PERCENT_WORK_OPER
                     , PUT_P.PUT_MINUTE_RATE
                     , PUT_P.C_TASK_IMPUTATION
                     , PUT_P.PUT_MACH_RATE
                     , PUT_P.PUT_MO_RATE
                     , PUC_P.PUC_CALCUL_QTY
                     , PUC_P.PUC_UTIL_COEFF
                     , PUC_P.PUC_NUMBER_OF_DECIMAL
                  from PTC_ELEMENT_COST ELC_P
                     , FAL_LOT LOT_P
                     , PTC_USED_COMPONENT PUC_P
                     , PTC_USED_TASK PUT_P
                 where LOT_P.FAL_LOT_ID = aLotId
                   and ELC_P.PTC_FIXED_COSTPRICE_ID = LOT_P.PTC_FIXED_COSTPRICE_ID
                   and PUT_P.PTC_USED_TASK_ID(+) = ELC_P.PTC_USED_TASK_ID
                   and PUC_P.PTC_USED_COMPONENT_ID(+) = ELC_P.PTC_USED_COMPONENT_ID) ELC
             , (select   FEC_F.C_COST_ELEMENT_TYPE
                       , FEC_F.FAL_LOT_MATERIAL_LINK_ID
                       , nvl(LOM_F.LOM_SEQ, -1) LOM_SEQ
                       , nvl(LOM_F.GCO_GOOD_ID, 0) GCO_GOOD_ID
                       , FEC_F.FAL_SCHEDULE_STEP_ID
                       , nvl(TAL_F.SCS_STEP_NUMBER, -1) SCS_STEP_NUMBER
                       , nvl(TAL_F.FAL_TASK_ID, 0) FAL_TASK_ID
                       , sum(FEC_F.FEC_COMPLETED_AMOUNT) FEC_COMPLETED_AMOUNT
                       , sum(FEC_F.FEC_COMPLETED_QUANTITY) FEC_COMPLETED_QUANTITY
                       , sum(TIH_F.TIH_ADJ_TIME_MACH_AMOUNT) TIH_ADJ_TIME_MACH_AMOUNT
                       , sum(TIH_F.TIH_ADJ_TIME_MACH_QTY) TIH_ADJ_TIME_MACH_QTY
                       , avg(TIH_F.TIH_ADJ_TIME_MACH_RATE) TIH_ADJ_TIME_MACH_RATE
                       , sum(TIH_F.TIH_ADJ_TIME_OPER_AMOUNT) TIH_ADJ_TIME_OPER_AMOUNT
                       , sum(TIH_F.TIH_ADJ_TIME_OPER_QTY) TIH_ADJ_TIME_OPER_QTY
                       , avg(TIH_F.TIH_ADJ_TIME_OPER_RATE) TIH_ADJ_TIME_OPER_RATE
                       , sum(TIH_F.TIH_WORK_TIME_MACH_ADD_AMOUNT) TIH_WORK_TIME_MACH_ADD_AMOUNT
                       , sum(TIH_F.TIH_WORK_TIME_MACH_AMOUNT) TIH_WORK_TIME_MACH_AMOUNT
                       , sum(TIH_F.TIH_WORK_TIME_MACH_QTY) TIH_WORK_TIME_MACH_QTY
                       , avg(TIH_F.TIH_WORK_TIME_MACH_RATE) TIH_WORK_TIME_MACH_RATE
                       , sum(TIH_F.TIH_WORK_TIME_OPER_AMOUNT) TIH_WORK_TIME_OPER_AMOUNT
                       , sum(TIH_F.TIH_WORK_TIME_OPER_QTY) TIH_WORK_TIME_OPER_QTY
                       , avg(TIH_F.TIH_WORK_TIME_OPER_RATE) TIH_WORK_TIME_OPER_RATE
                    from FAL_ELEMENT_COST FEC_F
                       , FAL_TASK_LINK TAL_F
                       , FAL_LOT_MATERIAL_LINK LOM_F
                       , FAL_ACI_TIME_HIST TIH_F
                   where FEC_F.FAL_LOT_ID = aLotId
                     and TAL_F.FAL_SCHEDULE_STEP_ID(+) = FEC_F.FAL_SCHEDULE_STEP_ID
                     and TIH_F.FAL_ACI_TIME_HIST_ID(+) = FEC_F.FAL_ACI_TIME_HIST_ID
                     and LOM_F.FAL_LOT_MATERIAL_LINK_ID(+) = FEC_F.FAL_LOT_MATERIAL_LINK_ID
                group by FEC_F.FAL_LOT_ID
                       , FEC_F.C_COST_ELEMENT_TYPE
                       , FEC_F.FAL_LOT_MATERIAL_LINK_ID
                       , LOM_F.LOM_SEQ
                       , LOM_F.GCO_GOOD_ID
                       , FEC_F.FAL_SCHEDULE_STEP_ID
                       , TAL_F.SCS_STEP_NUMBER
                       , TAL_F.FAL_TASK_ID) FEC
         where ELC.C_COST_ELEMENT_TYPE(+) = FEC.C_COST_ELEMENT_TYPE
           and ELC.SCS_STEP_NUMBER(+) = FEC.SCS_STEP_NUMBER
           and ELC.FAL_TASK_ID(+) = FEC.FAL_TASK_ID
           and ELC.LOM_SEQ(+) = FEC.LOM_SEQ
           and ELC.GCO_GOOD_ID(+) = FEC.GCO_GOOD_ID
      union
      select   ELC.C_COST_ELEMENT_TYPE
             , ELC.PTC_ELEMENT_COST_ID
             , nvl(ELC.ELC_AMOUNT, 0) ELC_AMOUNT
             , nvl(FEC.FEC_COMPLETED_AMOUNT, 0) FEC_COMPLETED_AMOUNT
             , nvl(ELC.LOM_SEQ, FEC.LOM_SEQ) LOM_SEQ
             , nvl(ELC.SCS_STEP_NUMBER, FEC.SCS_STEP_NUMBER) SCS_STEP_NUMBER
             , nvl(ELC.GCO_GOOD_ID, FEC.GCO_GOOD_ID) GCO_GOOD_ID
             , nvl(ELC.FAL_TASK_ID, FEC.FAL_TASK_ID) FAL_TASK_ID
             , ELC.PUT_ADJUSTING_TIME
             , ELC.PUT_QTY_FIX_ADJUSTING
             , ELC.PUT_WORK_TIME
             , ELC.PUT_QTY_REF_WORK
             , ELC.PUT_AMOUNT
             , nvl(ELC.PUT_QTY_REF_AMOUNT, 0) PUT_QTY_REF_AMOUNT
             , ELC.PUT_DIVISOR
             , ELC.PUT_ADJUSTING_FLOOR
             , ELC.PUT_WORK_FLOOR
             , ELC.PUT_ADJUSTING_OPERATOR
             , ELC.PUT_WORK_OPERATOR
             , ELC.PUT_NUM_ADJUST_OPERATOR
             , ELC.PUT_NUM_WORK_OPERATOR
             , ELC.PUT_PERCENT_ADJUST_OPER
             , ELC.PUT_PERCENT_WORK_OPER
             , ELC.PUT_MINUTE_RATE
             , ELC.C_TASK_IMPUTATION
             , ELC.PUT_MACH_RATE
             , ELC.PUT_MO_RATE
             , nvl(ELC.PUC_CALCUL_QTY, 0) PUC_CALCUL_QTY
             , nvl(ELC.PUC_UTIL_COEFF, 1) PUC_UTIL_COEFF
             , nvl(ELC.PUC_NUMBER_OF_DECIMAL, 0) PUC_NUMBER_OF_DECIMAL
             , nvl(FEC.FEC_COMPLETED_QUANTITY, 0) FEC_COMPLETED_QUANTITY
             , ELC.PTC_USED_COMPONENT_ID
             , ELC.PTC_USED_TASK_ID
             , FEC.FAL_LOT_MATERIAL_LINK_ID
             , FEC.FAL_SCHEDULE_STEP_ID
             , nvl(FEC.TIH_ADJ_TIME_MACH_AMOUNT, 0) TIH_ADJ_TIME_MACH_AMOUNT
             , nvl(FEC.TIH_ADJ_TIME_MACH_QTY, 0) TIH_ADJ_TIME_MACH_QTY
             , nvl(FEC.TIH_ADJ_TIME_MACH_RATE, 0) TIH_ADJ_TIME_MACH_RATE
             , nvl(FEC.TIH_ADJ_TIME_OPER_AMOUNT, 0) TIH_ADJ_TIME_OPER_AMOUNT
             , nvl(FEC.TIH_ADJ_TIME_OPER_QTY, 0) TIH_ADJ_TIME_OPER_QTY
             , nvl(FEC.TIH_ADJ_TIME_OPER_RATE, 0) TIH_ADJ_TIME_OPER_RATE
             , nvl(FEC.TIH_WORK_TIME_MACH_ADD_AMOUNT, 0) TIH_WORK_TIME_MACH_ADD_AMOUNT
             , nvl(FEC.TIH_WORK_TIME_MACH_AMOUNT, 0) TIH_WORK_TIME_MACH_AMOUNT
             , nvl(FEC.TIH_WORK_TIME_MACH_QTY, 0) TIH_WORK_TIME_MACH_QTY
             , nvl(FEC.TIH_WORK_TIME_MACH_RATE, 0) TIH_WORK_TIME_MACH_RATE
             , nvl(FEC.TIH_WORK_TIME_OPER_AMOUNT, 0) TIH_WORK_TIME_OPER_AMOUNT
             , nvl(FEC.TIH_WORK_TIME_OPER_QTY, 0) TIH_WORK_TIME_OPER_QTY
             , nvl(FEC.TIH_WORK_TIME_OPER_RATE, 0) TIH_WORK_TIME_OPER_RATE
          from (select ELC_P.PTC_ELEMENT_COST_ID
                     , ELC_P.PTC_FIXED_COSTPRICE_ID
                     , ELC_P.C_COST_ELEMENT_TYPE
                     , ELC_P.PTC_USED_COMPONENT_ID
                     , nvl(PUC_P.PUC_SEQ, -1) LOM_SEQ
                     , nvl(nvl(PUC_P.GCO_GCO_GOOD_ID, PUC_P.GCO_GOOD_ID), 0) GCO_GOOD_ID
                     , ELC_P.PTC_USED_TASK_ID
                     , nvl(PUT_P.PUT_STEP_NUMBER, -1) SCS_STEP_NUMBER
                     , nvl(PUT_P.FAL_TASK_ID, 0) FAL_TASK_ID
                     , ELC_P.ELC_AMOUNT
                     , PUT_P.PUT_ADJUSTING_TIME
                     , PUT_P.PUT_QTY_FIX_ADJUSTING
                     , PUT_P.PUT_WORK_TIME
                     , PUT_P.PUT_QTY_REF_WORK
                     , PUT_P.PUT_AMOUNT
                     , PUT_P.PUT_QTY_REF_AMOUNT
                     , PUT_P.PUT_DIVISOR
                     , PUT_P.PUT_ADJUSTING_FLOOR
                     , PUT_P.PUT_WORK_FLOOR
                     , PUT_P.PUT_ADJUSTING_OPERATOR
                     , PUT_P.PUT_WORK_OPERATOR
                     , PUT_P.PUT_NUM_ADJUST_OPERATOR
                     , PUT_P.PUT_NUM_WORK_OPERATOR
                     , PUT_P.PUT_PERCENT_ADJUST_OPER
                     , PUT_P.PUT_PERCENT_WORK_OPER
                     , PUT_P.PUT_MINUTE_RATE
                     , PUT_P.C_TASK_IMPUTATION
                     , PUT_P.PUT_MACH_RATE
                     , PUT_P.PUT_MO_RATE
                     , PUC_P.PUC_CALCUL_QTY
                     , PUC_P.PUC_UTIL_COEFF
                     , PUC_P.PUC_NUMBER_OF_DECIMAL
                  from PTC_ELEMENT_COST ELC_P
                     , FAL_LOT LOT_P
                     , PTC_USED_COMPONENT PUC_P
                     , PTC_USED_TASK PUT_P
                 where LOT_P.FAL_LOT_ID = aLotId
                   and ELC_P.PTC_FIXED_COSTPRICE_ID = LOT_P.PTC_FIXED_COSTPRICE_ID
                   and PUT_P.PTC_USED_TASK_ID(+) = ELC_P.PTC_USED_TASK_ID
                   and PUC_P.PTC_USED_COMPONENT_ID(+) = ELC_P.PTC_USED_COMPONENT_ID) ELC
             , (select   FEC_F.C_COST_ELEMENT_TYPE
                       , FEC_F.FAL_LOT_MATERIAL_LINK_ID
                       , nvl(LOM_F.LOM_SEQ, -1) LOM_SEQ
                       , nvl(LOM_F.GCO_GOOD_ID, 0) GCO_GOOD_ID
                       , FEC_F.FAL_SCHEDULE_STEP_ID
                       , nvl(TAL_F.SCS_STEP_NUMBER, -1) SCS_STEP_NUMBER
                       , nvl(TAL_F.FAL_TASK_ID, 0) FAL_TASK_ID
                       , sum(FEC_F.FEC_COMPLETED_AMOUNT) FEC_COMPLETED_AMOUNT
                       , sum(FEC_F.FEC_COMPLETED_QUANTITY) FEC_COMPLETED_QUANTITY
                       , sum(TIH_F.TIH_ADJ_TIME_MACH_AMOUNT) TIH_ADJ_TIME_MACH_AMOUNT
                       , sum(TIH_F.TIH_ADJ_TIME_MACH_QTY) TIH_ADJ_TIME_MACH_QTY
                       , avg(TIH_F.TIH_ADJ_TIME_MACH_RATE) TIH_ADJ_TIME_MACH_RATE
                       , sum(TIH_F.TIH_ADJ_TIME_OPER_AMOUNT) TIH_ADJ_TIME_OPER_AMOUNT
                       , sum(TIH_F.TIH_ADJ_TIME_OPER_QTY) TIH_ADJ_TIME_OPER_QTY
                       , avg(TIH_F.TIH_ADJ_TIME_OPER_RATE) TIH_ADJ_TIME_OPER_RATE
                       , sum(TIH_F.TIH_WORK_TIME_MACH_ADD_AMOUNT) TIH_WORK_TIME_MACH_ADD_AMOUNT
                       , sum(TIH_F.TIH_WORK_TIME_MACH_AMOUNT) TIH_WORK_TIME_MACH_AMOUNT
                       , sum(TIH_F.TIH_WORK_TIME_MACH_QTY) TIH_WORK_TIME_MACH_QTY
                       , avg(TIH_F.TIH_WORK_TIME_MACH_RATE) TIH_WORK_TIME_MACH_RATE
                       , sum(TIH_F.TIH_WORK_TIME_OPER_AMOUNT) TIH_WORK_TIME_OPER_AMOUNT
                       , sum(TIH_F.TIH_WORK_TIME_OPER_QTY) TIH_WORK_TIME_OPER_QTY
                       , avg(TIH_F.TIH_WORK_TIME_OPER_RATE) TIH_WORK_TIME_OPER_RATE
                    from FAL_ELEMENT_COST FEC_F
                       , FAL_TASK_LINK TAL_F
                       , FAL_LOT_MATERIAL_LINK LOM_F
                       , FAL_ACI_TIME_HIST TIH_F
                   where FEC_F.FAL_LOT_ID = aLotId
                     and TAL_F.FAL_SCHEDULE_STEP_ID(+) = FEC_F.FAL_SCHEDULE_STEP_ID
                     and TIH_F.FAL_ACI_TIME_HIST_ID(+) = FEC_F.FAL_ACI_TIME_HIST_ID
                     and LOM_F.FAL_LOT_MATERIAL_LINK_ID(+) = FEC_F.FAL_LOT_MATERIAL_LINK_ID
                group by FEC_F.FAL_LOT_ID
                       , FEC_F.C_COST_ELEMENT_TYPE
                       , FEC_F.FAL_LOT_MATERIAL_LINK_ID
                       , LOM_F.LOM_SEQ
                       , LOM_F.GCO_GOOD_ID
                       , FEC_F.FAL_SCHEDULE_STEP_ID
                       , TAL_F.SCS_STEP_NUMBER
                       , TAL_F.FAL_TASK_ID) FEC
         where ELC.C_COST_ELEMENT_TYPE = FEC.C_COST_ELEMENT_TYPE(+)
           and ELC.SCS_STEP_NUMBER = FEC.SCS_STEP_NUMBER(+)
           and ELC.FAL_TASK_ID = FEC.FAL_TASK_ID(+)
           and ELC.LOM_SEQ = FEC.LOM_SEQ(+)
           and ELC.GCO_GOOD_ID = FEC.GCO_GOOD_ID(+)
      order by C_COST_ELEMENT_TYPE
             , LOM_SEQ
             , SCS_STEP_NUMBER;

    cursor crLotInfos(aLotId in FAL_LOT.FAL_LOT_ID%type)
    is
      select PUC.PTC_FIXED_COSTPRICE_ID
           , PUC.GCO_GOOD_ID
           , LOT.LOT_RELEASED_QTY
           , LOT.LOT_REFCOMPL
           , LOT.C_SCHEDULE_PLANNING
           , PUC.PUC_CALCUL_QTY LOT_CALCUL_QTY
           , PUC.PUC_NUMBER_OF_DECIMAL LOT_NUMBER_OF_DECIMAL
        from FAL_LOT LOT
           , PTC_USED_COMPONENT PUC
       where LOT.FAL_LOT_ID = aLotId
         and PUC.PTC_FIXED_COSTPRICE_ID = LOT.PTC_FIXED_COSTPRICE_ID
         and PUC.GCO_GOOD_ID = LOT.GCO_GOOD_ID;

    tplLotInfos        crLotInfos%rowtype;

    cursor crProductAccounts(aLotId in FAL_LOT.FAL_LOT_ID%type)
    is
      select   null FEC_COMPLETED_AMOUNT
             , null FEC_COMPLETED_QUANTITY
             , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID ACS_PJ_ACCOUNT_ID
             , null ACS_QTY_UNIT_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_GOOD_ID
             , SMO.FAM_FIXED_ASSETS_ID
             , SMO.C_FAM_TRANSACTION_TYP
             , SMO.HRM_PERSON_ID
             , null PAC_PERSON_ID
             , nvl(SMO.PAC_THIRD_ACI_ID, SMO.PAC_THIRD_ID) PAC_THIRD_ID
             , SMO.DIC_IMP_FREE1_ID
             , SMO.DIC_IMP_FREE2_ID
             , SMO.DIC_IMP_FREE3_ID
             , SMO.DIC_IMP_FREE4_ID
             , SMO.DIC_IMP_FREE5_ID
             , SMO.SMO_IMP_NUMBER_1 IMF_NUMBER
             , SMO.SMO_IMP_NUMBER_2 IMF_NUMBER2
             , SMO.SMO_IMP_NUMBER_3 IMF_NUMBER3
             , SMO.SMO_IMP_NUMBER_4 IMF_NUMBER4
             , SMO.SMO_IMP_NUMBER_5 IMF_NUMBER5
             , SMO.SMO_IMP_TEXT_1 IMF_TEXT1
             , SMO.SMO_IMP_TEXT_2 IMF_TEXT2
             , SMO.SMO_IMP_TEXT_3 IMF_TEXT3
             , SMO.SMO_IMP_TEXT_4 IMF_TEXT4
             , SMO.SMO_IMP_TEXT_5 IMF_TEXT5
          from STM_STOCK_MOVEMENT SMO
             , STM_MOVEMENT_KIND MOK
             , FAL_LOT LOT
         where LOT.FAL_LOT_ID = aLotId
           and SMO.SMO_WORDING = LOT.LOT_REFCOMPL
           and SMO.FAL_FACTORY_OUT_ID is null
           and SMO.SMO_MOVEMENT_QUANTITY > 0
           and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
           and MOK.C_MOVEMENT_CODE = '020'
      group by SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_GOOD_ID
             , SMO.FAM_FIXED_ASSETS_ID
             , SMO.C_FAM_TRANSACTION_TYP
             , SMO.HRM_PERSON_ID
             , nvl(SMO.PAC_THIRD_ACI_ID, SMO.PAC_THIRD_ID)
             , SMO.DIC_IMP_FREE1_ID
             , SMO.DIC_IMP_FREE2_ID
             , SMO.DIC_IMP_FREE3_ID
             , SMO.DIC_IMP_FREE4_ID
             , SMO.DIC_IMP_FREE5_ID
             , SMO.SMO_IMP_NUMBER_1
             , SMO.SMO_IMP_NUMBER_2
             , SMO.SMO_IMP_NUMBER_3
             , SMO.SMO_IMP_NUMBER_4
             , SMO.SMO_IMP_NUMBER_5
             , SMO.SMO_IMP_TEXT_1
             , SMO.SMO_IMP_TEXT_2
             , SMO.SMO_IMP_TEXT_3
             , SMO.SMO_IMP_TEXT_4
             , SMO.SMO_IMP_TEXT_5;

    tplProductAccounts TAccounts;
    vEltCostDiff1Id    FAL_ELT_COST_DIFF.FAL_ELT_COST_DIFF_ID%type;
    vEltCostDiff2Id    FAL_ELT_COST_DIFF.FAL_ELT_COST_DIFF_ID%type;
    vQtyAdjustment     number(15, 6);
    vExpectedQty       FAL_ELT_COST_DIFF.CTD_EXPECTED_QTY%type;
    vExpectedUnitValue FAL_ELT_COST_DIFF.CTD_EXPECTED_UNIT_VALUE%type;
    vExpectedCost      FAL_ELT_COST_DIFF.CTD_EXPECTED_COST%type;
    vExpectedTotalCost FAL_ELT_COST_DIFF.CTD_EXPECTED_COST%type;
    vRealQty           FAL_ELT_COST_DIFF.CTD_REAL_QTY%type;
    vRealCost          FAL_ELT_COST_DIFF.CTD_REAL_COST%type;
    vExpectedAmount    FAL_ELT_COST_DIFF.CTD_EXPECTED_COST%type;
    vMachAdjTime       PTC_USED_TASK.PUT_ADJUSTING_TIME%type;
    vMachWorkTime      PTC_USED_TASK.PUT_WORK_TIME%type;
    vOperAdjTime       PTC_USED_TASK.PUT_ADJUSTING_TIME%type;
    vOperWorkTime      PTC_USED_TASK.PUT_WORK_TIME%type;
    vMachWorkAmount    PTC_USED_TASK.PUT_AMOUNT%type;
    vDocNumber         FAL_ELT_COST_DIFF.DOC_NUMBER%type;
    vDescription       FAL_ELT_COST_DIFF.CTD_DESCRIPTION%type;
  begin
    open crLotInfos(aLotId);

    fetch crLotInfos
     into tplLotInfos;

    close crLotInfos;

    open crProductAccounts(aLotId);

    fetch crProductAccounts
     into tplProductAccounts;

    close crProductAccounts;

    vQtyAdjustment  := tplLotInfos.LOT_RELEASED_QTY / zvl(tplLotInfos.LOT_CALCUL_QTY, 1);
    vDocNumber      := truncstr(tplLotInfos.LOT_REFCOMPL, cMaxDocNumberLength);

    for tplElementCost in crElementCosts(aLotId) loop
      vDescription     :=
        GenerateDescription(aBaseDescription   => aDescription
                          , aCompSeq           => tplElementCost.LOM_SEQ
                          , aCompGoodId        => tplElementCost.GCO_GOOD_ID
                          , aTaskSeq           => tplElementCost.SCS_STEP_NUMBER
                          , aTaskId            => tplElementCost.FAL_TASK_ID
                           );
      vEltCostDiff1Id  := null;
      vEltCostDiff2Id  := null;

      if tplElementCost.C_COST_ELEMENT_TYPE = ctMaterial then
        vExpectedQty        := tplElementCost.PUC_CALCUL_QTY * vQtyAdjustment;
        vExpectedQty        := round(vExpectedQty, tplElementCost.PUC_NUMBER_OF_DECIMAL);
        vExpectedUnitValue  := tplElementCost.ELC_AMOUNT / tplElementCost.PUC_UTIL_COEFF;
        vEltCostDiff1Id     :=
          CreateEltCostDiffAndDetails(aLotId                => aLotId
                                    , aGoodId               => tplLotInfos.GCO_GOOD_ID
                                    , aCostElementType      => tplElementCost.C_COST_ELEMENT_TYPE
                                    , aPtcElementCostId     => tplElementCost.PTC_ELEMENT_COST_ID
                                    , aPtcUsedComponentId   => tplElementCost.PTC_USED_COMPONENT_ID
                                    , aLotMaterialLinkId    => tplElementCost.FAL_LOT_MATERIAL_LINK_ID
                                    , aDocNumber            => vDocNumber
                                    , aDescription          => vDescription
                                    , aValueDate            => aValueDate
                                    , aExpectedQty          => vExpectedQty
                                    , aExpectedUnitValue    => vExpectedUnitValue
                                    , aExpectedCost         => vExpectedUnitValue * vExpectedQty
                                    , aRealQty              => tplElementCost.FEC_COMPLETED_QUANTITY
                                    , aRealUnitValue        => tplElementCost.FEC_COMPLETED_AMOUNT / zvl(tplElementCost.FEC_COMPLETED_QUANTITY, 1)
                                    , aRealCost             => tplElementCost.FEC_COMPLETED_AMOUNT
                                    , aProductAccounts      => tplProductAccounts
                                     );
      elsif tplElementCost.C_COST_ELEMENT_TYPE = ctSubContract then
        vExpectedQty     := tplLotInfos.LOT_RELEASED_QTY;
        vEltCostDiff1Id  :=
          CreateEltCostDiffAndDetails(aLotId               => aLotId
                                    , aGoodId              => tplLotInfos.GCO_GOOD_ID
                                    , aCostElementType     => tplElementCost.C_COST_ELEMENT_TYPE
                                    , aPtcElementCostId    => tplElementCost.PTC_ELEMENT_COST_ID
                                    , aPtcUsedTaskId       => tplElementCost.PTC_USED_TASK_ID
                                    , aTaskLinkId          => tplElementCost.FAL_SCHEDULE_STEP_ID
                                    , aDocNumber           => vDocNumber
                                    , aDescription         => vDescription
                                    , aValueDate           => aValueDate
                                    , aExpectedQty         => vExpectedQty
                                    , aExpectedUnitValue   => tplElementCost.ELC_AMOUNT
                                    , aExpectedCost        => tplElementCost.ELC_AMOUNT * vExpectedQty
                                    , aRealQty             => tplElementCost.FEC_COMPLETED_QUANTITY
                                    , aRealUnitValue       => tplElementCost.FEC_COMPLETED_AMOUNT / zvl(tplElementCost.FEC_COMPLETED_QUANTITY, 1)
                                    , aRealCost            => tplElementCost.FEC_COMPLETED_AMOUNT
                                    , aProductAccounts     => tplProductAccounts
                                     );
      elsif tplElementCost.C_COST_ELEMENT_TYPE in(ctMachine, ctOperator) then
        CalcProdData(aProdQty             => tplLotInfos.LOT_CALCUL_QTY
                   , aSchedulePlanning    => tplLotInfos.C_SCHEDULE_PLANNING
                   , aTaskImputation      => tplElementCost.C_TASK_IMPUTATION
                   , aAdjustingTime       => tplElementCost.PUT_ADJUSTING_TIME
                   , aQtyFixAdjusting     => tplElementCost.PUT_QTY_FIX_ADJUSTING
                   , aWorkTime            => tplElementCost.PUT_WORK_TIME
                   , aQtyRefWork          => tplElementCost.PUT_QTY_REF_WORK
                   , aAmount              => tplElementCost.PUT_AMOUNT
                   , aDivisorAmount       => tplElementCost.PUT_DIVISOR
                   , aQtyRefAmount        => tplElementCost.PUT_QTY_REF_AMOUNT
                   , aAdjustingFloor      => tplElementCost.PUT_ADJUSTING_FLOOR
                   , aWorkFloor           => tplElementCost.PUT_WORK_FLOOR
                   , aAdjustingOperator   => tplElementCost.PUT_ADJUSTING_OPERATOR
                   , aWorkOperator        => tplElementCost.PUT_WORK_OPERATOR
                   , aNumAdjustOper       => tplElementCost.PUT_NUM_ADJUST_OPERATOR
                   , aNumWorkOper         => tplElementCost.PUT_NUM_WORK_OPERATOR
                   , aPercentAdjustOper   => tplElementCost.PUT_PERCENT_ADJUST_OPER
                   , aPercentWorkOper     => tplElementCost.PUT_PERCENT_WORK_OPER
                   , aMinuteRate          => tplElementCost.PUT_MINUTE_RATE
                   , aMachAdjTime         => vMachAdjTime
                   , aMachWorkTime        => vMachWorkTime
                   , aOperAdjTime         => vOperAdjTime
                   , aOperWorkTime        => vOperWorkTime
                   , aMachWorkAmount      => vMachWorkAmount
                    );
        vExpectedTotalCost  := tplElementCost.ELC_AMOUNT * tplLotInfos.LOT_RELEASED_QTY;

        if tplElementCost.C_COST_ELEMENT_TYPE = ctMachine then
          if (vMachWorkAmount > 0) then
            vExpectedAmount  := vExpectedTotalCost * vMachWorkAmount /(vMachWorkAmount + (vMachAdjTime + vMachWorkTime) * tplElementCost.PUT_MACH_RATE);
          else
            vExpectedAmount  := 0;
          end if;

          -- Quantité et coût réglage MA
          vExpectedQty  := vMachAdjTime * vQtyAdjustment;

          if (vMachAdjTime + vMachWorkTime) = 0 then
            vExpectedCost  := 0;
          else
            vExpectedCost  := (vExpectedTotalCost - vExpectedAmount) * vMachAdjTime /(vMachAdjTime + vMachWorkTime);
          end if;

          vRealQty      := tplElementCost.TIH_ADJ_TIME_MACH_QTY;
          vRealCost     := tplElementCost.TIH_ADJ_TIME_MACH_AMOUNT;
        else
          vExpectedAmount  := 0;
          -- Quantité et coût réglage MO
          vExpectedQty     := vOperAdjTime * vQtyAdjustment;

          if (vOperAdjTime + vOperWorkTime) = 0 then
            vExpectedCost  := 0;
          else
            vExpectedCost  := (vExpectedTotalCost - vExpectedAmount) * vOperAdjTime /(vOperAdjTime + vOperWorkTime);
          end if;

          vRealQty         := tplElementCost.TIH_ADJ_TIME_OPER_QTY;
          vRealCost        := tplElementCost.TIH_ADJ_TIME_OPER_AMOUNT;
        end if;

        vEltCostDiff1Id     :=
          CreateEltCostDiffAndDetails(aLotId                => aLotId
                                    , aGoodId               => tplLotInfos.GCO_GOOD_ID
                                    , aCostElementType      => tplElementCost.C_COST_ELEMENT_TYPE
                                    , aCostElementSubType   => cstAdjusting
                                    , aPtcElementCostId     => tplElementCost.PTC_ELEMENT_COST_ID
                                    , aPtcUsedTaskId        => tplElementCost.PTC_USED_TASK_ID
                                    , aTaskLinkId           => tplElementCost.FAL_SCHEDULE_STEP_ID
                                    , aDocNumber            => vDocNumber
                                    , aDescription          => vDescription
                                    , aValueDate            => aValueDate
                                    , aExpectedQty          => vExpectedQty
                                    , aExpectedUnitValue    => vExpectedCost / zvl(vExpectedQty, 1)
                                    , aExpectedCost         => vExpectedCost
                                    , aRealQty              => vRealQty
                                    , aRealUnitValue        => vRealCost / zvl(vRealQty, 1)
                                    , aRealCost             => vRealCost
                                    , aProductAccounts      => tplProductAccounts
                                     );

        if tplElementCost.C_COST_ELEMENT_TYPE = ctMachine then
          -- Quantité et coût travail MA incluant le montant
          vExpectedQty   := vMachWorkTime * vQtyAdjustment;
          vExpectedCost  := vExpectedTotalCost /*- vExpectedAmount*/ - vExpectedCost;
          vRealQty       := tplElementCost.TIH_WORK_TIME_MACH_QTY;
          vRealCost      := tplElementCost.TIH_WORK_TIME_MACH_AMOUNT;   -- Le montant additionnel est inclus
        else
          -- Quantité et coût travail MO
          vExpectedQty   := vOperWorkTime * vQtyAdjustment;
          vExpectedCost  := vExpectedTotalCost - vExpectedCost;
          vRealQty       := tplElementCost.TIH_WORK_TIME_OPER_QTY;
          vRealCost      := tplElementCost.TIH_WORK_TIME_OPER_AMOUNT;
        end if;

        vEltCostDiff2Id     :=
          CreateEltCostDiffAndDetails(aLotId                => aLotId
                                    , aGoodId               => tplLotInfos.GCO_GOOD_ID
                                    , aCostElementType      => tplElementCost.C_COST_ELEMENT_TYPE
                                    , aCostElementSubType   => cstWork
                                    , aPtcElementCostId     => tplElementCost.PTC_ELEMENT_COST_ID
                                    , aPtcUsedTaskId        => tplElementCost.PTC_USED_TASK_ID
                                    , aTaskLinkId           => tplElementCost.FAL_SCHEDULE_STEP_ID
                                    , aDocNumber            => vDocNumber
                                    , aDescription          => vDescription
                                    , aValueDate            => aValueDate
                                    , aExpectedQty          => vExpectedQty
                                    , aExpectedUnitValue    => vExpectedCost / zvl(vExpectedQty, 1)
                                    , aExpectedCost         => vExpectedCost
                                    , aRealQty              => vRealQty
                                    , aRealUnitValue        => vRealCost / zvl(vRealQty, 1)
                                    , aRealCost             => vRealCost
                                    , aProductAccounts      => tplProductAccounts
                                     );
      end if;

      -- Mise à jour des ID élément coût écart sur les élément de coût OF
      -- L'élément de coût PRF est sauvegardé sur l'élément coût écart
      update FAL_ELEMENT_COST
         set FAL_ELT_COST_DIFF1_ID = vEltCostDiff1Id
           , FAL_ELT_COST_DIFF2_ID = vEltCostDiff2Id
       where FAL_LOT_ID = aLotId
         and C_COST_ELEMENT_TYPE = tplElementCost.C_COST_ELEMENT_TYPE
         and FAL_LOT_MATERIAL_LINK_ID = tplElementCost.FAL_LOT_MATERIAL_LINK_ID
         and STM_STOCK_MOVEMENT_ID in(
               select FEC.STM_STOCK_MOVEMENT_ID
                 from FAL_ELEMENT_COST FEC
                    , STM_STOCK_MOVEMENT SMO
                    , STM_MOVEMENT_KIND MOK
                where FEC.FAL_LOT_ID = aLotId
                  and FEC.FAL_LOT_MATERIAL_LINK_ID = tplElementCost.FAL_LOT_MATERIAL_LINK_ID
                  and FEC.C_COST_ELEMENT_TYPE = tplElementCost.C_COST_ELEMENT_TYPE
                  and SMO.STM_STOCK_MOVEMENT_ID = FEC.STM_STOCK_MOVEMENT_ID
                  and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
                  and (    (    MOK.C_MOVEMENT_CODE = '017'
                            and MOK.C_MOVEMENT_SORT = 'SOR'
                            and MOK.C_MOVEMENT_TYPE = 'FAC')
                       or (    MOK.C_MOVEMENT_CODE = '020'
                           and MOK.C_MOVEMENT_SORT = 'ENT'
                           and MOK.C_MOVEMENT_TYPE = 'FAC'
                           and SMO.FAL_FACTORY_OUT_ID is not null)
                      ) );

      update FAL_ELEMENT_COST
         set FAL_ELT_COST_DIFF1_ID = vEltCostDiff1Id
           , FAL_ELT_COST_DIFF2_ID = vEltCostDiff2Id
       where FAL_LOT_ID = aLotId
         and C_COST_ELEMENT_TYPE = tplElementCost.C_COST_ELEMENT_TYPE
         and FAL_SCHEDULE_STEP_ID = tplElementCost.FAL_SCHEDULE_STEP_ID
         and (   FAL_ACI_TIME_HIST_ID is not null
              or STM_STOCK_MOVEMENT_ID is not null);
    end loop;

    -- Mise à jour du flag sur le lot
    update FAL_LOT
       set LOT_IS_POSTCALCULATED = 1
     where FAL_LOT_ID = aLotId;
  end ProcessPostCalculation;

      /**
  * procedure ProcessPostCalculations
  */
  procedure ProcessPostCalculations(
    aAPC_GLOBAL_BEFORE_PROC in     varchar2 default null
  , aAPC_DETAIL_BEFORE_PROC in     varchar2 default null
  , aAPC_DETAIL_AFTER_PROC  in     varchar2 default null
  , aSuccessfulCount        out    integer
  , aTotalCount             out    integer
  )
  is
    cursor crPostCalculations
    is
      select   APC.FAL_ACI_POSTCALCULATION_ID
             , APC.FAL_LOT_ID
             , APC.APC_DESCRIPTION
             , APC.APC_VALUE_DATE
             , APC.APC_BALANCED_DATE
             , LOT.GCO_GOOD_ID
          from FAL_ACI_POSTCALCULATION APC
             , FAL_LOT LOT
         where APC.APC_SELECTION = 1
           and APC.C_APC_STATUS = asToProcess
           and LOT.FAL_LOT_ID(+) = APC.FAL_LOT_ID
      order by APC.APC_VALUE_DATE
             , APC.FAL_ACI_POSTCALCULATION_ID;

    type TPostCalculations is table of crPostCalculations%rowtype;

    vPostCalculations       TPostCalculations;
    cBulkLimit     constant number            := 10000;
    vIndex                  integer;
    vAPC_GLOBAL_BEFORE_PROC varchar2(255);
    vAPC_DETAIL_BEFORE_PROC varchar2(255);
    vAPC_DETAIL_AFTER_PROC  varchar2(255);
    vProcResult             integer           := 1;
    vReturnCompoIsScrap     integer(1);
    vSqlMsg                 varchar2(4000);
  begin
    -- Recherche des procédures stockées si elles n'ont pas été passées en pramètre
    vAPC_GLOBAL_BEFORE_PROC  := nvl(aAPC_GLOBAL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_APC_GLOBAL_PROC') );
    vAPC_DETAIL_BEFORE_PROC  := nvl(aAPC_DETAIL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_APC_DETAIL_BEFORE_PROC') );
    vAPC_DETAIL_AFTER_PROC   := nvl(aAPC_DETAIL_AFTER_PROC, PCS.PC_CONFIG.GetConfig('FAL_APC_DETAIL_AFTER_PROC') );
    -- Purge des lots vérouillés par des sessions inactives et initialisation des compteurs
    FAL_BATCH_RESERVATION.PurgeInactiveBatchReservation;
    aSuccessfulCount         := 0;
    aTotalCount              := 0;

    -- Execution de la procédure stockée globale
    if vAPC_GLOBAL_BEFORE_PROC is not null then
      begin
        execute immediate 'begin :Result :=  ' || vAPC_GLOBAL_BEFORE_PROC || '; end;'
                    using out vProcResult;

        if vProcResult < 1 then
          vSqlMsg  :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a interrompu le traitement. Valeur retournée :') || ' '
                    || to_char(vProcResult);
        end if;
      exception
        when others then
          begin
            vSqlMsg  :=
              PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a généré une erreur :') ||
              co.cLineBreak ||
              DBMS_UTILITY.FORMAT_ERROR_STACK ||
              DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          end;
      end;
    end if;

    if vSqlMsg is not null then
      -- Abandon du traitement pour tous les enregistrements sélectionnés
      -- Supression des résultats des tentatives d'imputations précédentes
      delete from FAL_ACI_POSTCALCULATION
            where FAL_LOT_ID in(select FAL_LOT_ID
                                  from FAL_ACI_POSTCALCULATION
                                 where APC_SELECTION = 1
                                   and C_APC_STATUS = asToProcess)
              and FAL_ACI_POSTCALCULATION_ID not in(select FAL_ACI_POSTCALCULATION_ID
                                                      from FAL_ACI_POSTCALCULATION
                                                     where APC_SELECTION = 1
                                                       and C_APC_STATUS = asToProcess);

      -- Mise à jour des statuts et des détails de l'abandon dans la table temporaire
      update FAL_ACI_POSTCALCULATION
         set APC_SELECTION = 0
           , C_APC_STATUS = asProcessAborted
           , APC_ERROR_MESSAGE = vSqlMsg
       where APC_SELECTION = 1
         and C_APC_STATUS = asToProcess;
    else
      open crPostCalculations;

      fetch crPostCalculations
      bulk collect into vPostCalculations limit cBulkLimit;

      -- Pour chaque élément sélectionné de la table temporaire
      while vPostCalculations.count > 0 loop
        for vIndex in vPostCalculations.first .. vPostCalculations.last loop
          begin
            -- Incrémentation du compteur total
            aTotalCount  := aTotalCount + 1;

            -- Supression des résultats des tentatives d'imputations précédentes
            delete from FAL_ACI_POSTCALCULATION
                  where FAL_LOT_ID = vPostCalculations(vIndex).FAL_LOT_ID
                    and FAL_ACI_POSTCALCULATION_ID <> vPostCalculations(vIndex).FAL_ACI_POSTCALCULATION_ID;

            -- Réservation du lot
            begin
              FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => vPostCalculations(vIndex).FAL_LOT_ID, aErrorMsg => vSqlMsg);
            exception
              when others then
                vSqlMsg  :=
                  PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la réservation du lot :') ||
                  co.cLineBreak ||
                  DBMS_UTILITY.FORMAT_ERROR_STACK ||
                  DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            end;

            savepoint SP_BeforePostCalc;

            -- Execution de la procédure stockée de pré-traitement
            if     vSqlMsg is null
               and vAPC_DETAIL_BEFORE_PROC is not null then
              begin
                execute immediate 'begin :Result :=  ' || vAPC_DETAIL_BEFORE_PROC || '(:FAL_ACI_POSTCALCULATION_ID); end;'
                            using out vProcResult, in vPostCalculations(vIndex).FAL_ACI_POSTCALCULATION_ID;

                if vProcResult < 1 then
                  vSqlMsg  :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a interrompu le traitement. Valeur retournée :') ||
                    ' ' ||
                    to_char(vProcResult);
                end if;
              exception
                when others then
                  begin
                    vProcResult  := 0;
                    vSqlMsg      :=
                      PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a généré une erreur :') ||
                      co.cLineBreak ||
                      DBMS_UTILITY.FORMAT_ERROR_STACK ||
                      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                  end;
              end;
            end if;

            if vSqlMsg is null then
              -- Calcul et imputation des écarts
              ProcessPostCalculation(aLotId          => vPostCalculations(vIndex).FAL_LOT_ID
                                   , aDescription    => vPostCalculations(vIndex).APC_DESCRIPTION
                                   , aValueDate      => vPostCalculations(vIndex).APC_VALUE_DATE
                                   , aBalancedDate   => vPostCalculations(vIndex).APC_BALANCED_DATE
                                   , aGoodId         => vPostCalculations(vIndex).GCO_GOOD_ID
                                    );
            end if;
          exception
            when others then
              -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
              vSqlMsg  :=
                PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement :') ||
                co.cLineBreak ||
                DBMS_UTILITY.FORMAT_ERROR_STACK ||
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          end;

          if vSqlMsg is null then
            begin
              -- Execution de la procédure stockée de post-traitement
              if vAPC_DETAIL_AFTER_PROC is not null then
                execute immediate 'begin :Result :=  ' || vAPC_DETAIL_AFTER_PROC || '(:FAL_ACI_POSTCALCULATION_ID); end;'
                            using out vProcResult, in vPostCalculations(vIndex).FAL_ACI_POSTCALCULATION_ID;

                if vProcResult < 1 then
                  vSqlMsg  :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a signalé un problème. Valeur retournée') ||
                    ' ' ||
                    to_char(vProcResult);
                end if;
              end if;
            exception
              when others then
                begin
                  vProcResult  := 0;
                  vSqlMsg      :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a généré une erreur :') ||
                    co.cLineBreak ||
                    DBMS_UTILITY.FORMAT_ERROR_STACK ||
                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                end;
            end;
          end if;

          -- Annulation du traitement de l'imputation en cours s'il y a eu le moindre problème
          if vSqlMsg is not null then
            rollback to savepoint SP_BeforePostCalc;
          end if;

          -- Libération du lot
--           FAL_BATCH_RESERVATION.ReleaseBatch(aFalLotId); ne doit pas être en transaction autonome !!!!
          delete from FAL_LOT1
                where FAL_LOT_ID = vPostCalculations(vIndex).FAL_LOT_ID
                  and LT1_ORACLE_SESSION = DBMS_SESSION.unique_session_id;

          if vSqlMsg is null then
            -- Mise à jour du statut dans la table temporaire
            update FAL_ACI_POSTCALCULATION
               set APC_SELECTION = 0
                 , C_APC_STATUS = asProcessed
                 , APC_ERROR_MESSAGE = null
             where FAL_ACI_POSTCALCULATION_ID = vPostCalculations(vIndex).FAL_ACI_POSTCALCULATION_ID;

            -- Incrémentation du compteur d'imputations terminées sans erreur
            aSuccessfulCount  := aSuccessfulCount + 1;
          else
            -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
            update FAL_ACI_POSTCALCULATION
               set APC_SELECTION = 0
                 , C_APC_STATUS = asProcessError
                 , APC_ERROR_MESSAGE = vSqlMsg
             where FAL_ACI_POSTCALCULATION_ID = vPostCalculations(vIndex).FAL_ACI_POSTCALCULATION_ID;

            -- Remise à zero des erreurs pour l'enregistrement suivant
            vSqlMsg  := null;
          end if;
--           -- Commit après chaque lot pour sauvegarder les traitements et libérer
--           -- le lot immédiatement
--           commit;
--
--           -- Libération du lot
--           FAL_BATCH_RESERVATION.ReleaseBatch(aFalLotId);
        end loop;

        fetch crPostCalculations
        bulk collect into vPostCalculations limit cBulkLimit;
      end loop;

      close crPostCalculations;

      -- Appel de la procédure de traitement ACI
      ProcessAciPostCalculations;
    end if;
  end ProcessPostCalculations;

  /**
   * procedure ProcessAciPostCalculations
   */
  procedure ProcessAciPostCalculations
  is
  begin
    -- Intégration des données en ACI selon les règles de regroupement, etc.
    -- Mise à jour de ACI_DOCUMENT_ID.
    ACI_FAL_COST_DIFF.IntegratePostCalculation;
  end;

  /**
   * procedure DeleteAPCItems
   * Description
   *   Supprime les enregistrements temporaires déterminés par les paramètres
   */
  procedure DeleteAPCItems(aC_APC_STATUS in FAL_ACI_POSTCALCULATION.C_APC_STATUS%type, aOnlySelected in integer default 0)
  is
  begin
    -- Suppression des enregistrements séléctionnés du statut précisé
    delete from FAL_ACI_POSTCALCULATION
          where C_APC_STATUS = aC_APC_STATUS
            and (   aOnlySelected = 0
                 or APC_SELECTION = 1);
  end DeleteAPCItems;

  /**
   * function GetAPCProfileValues
   * Description
   *   Extrait les valeurs des options d'un profil xml.
   */
  function GetAPCProfileValues(aXmlProfile xmltype)
    return TAPCOptions
  is
    vOptions TAPCOptions;
  begin
    begin
      -- Initialiser les valeurs du record sortant avec les valeurs stockées dans le xml du profil
      select extractvalue(aXmlProfile, '//APC_MODE')
           , extractvalue(aXmlProfile, '//APC_GLOBAL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//APC_DETAIL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//APC_DETAIL_AFTER_PROC')
           , extractvalue(aXmlProfile, '//APC_SELECTION')
           , extractvalue(aXmlProfile, '//APC_DATE_UNIT')
           , extractvalue(aXmlProfile, '//APC_PRODUCT_FROM')
           , extractvalue(aXmlProfile, '//APC_PRODUCT_TO')
           , extractvalue(aXmlProfile, '//APC_GOOD_CATEGORY_FROM')
           , extractvalue(aXmlProfile, '//APC_GOOD_CATEGORY_TO')
           , extractvalue(aXmlProfile, '//APC_GOOD_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//APC_GOOD_FAMILY_TO')
           , extractvalue(aXmlProfile, '//APC_ACCOUNTABLE_GROUP_FROM')
           , extractvalue(aXmlProfile, '//APC_ACCOUNTABLE_GROUP_TO')
           , extractvalue(aXmlProfile, '//APC_GOOD_LINE_FROM')
           , extractvalue(aXmlProfile, '//APC_GOOD_LINE_TO')
           , extractvalue(aXmlProfile, '//APC_GOOD_GROUP_FROM')
           , extractvalue(aXmlProfile, '//APC_GOOD_GROUP_TO')
           , extractvalue(aXmlProfile, '//APC_GOOD_MODEL_FROM')
           , extractvalue(aXmlProfile, '//APC_GOOD_MODEL_TO')
           , extractvalue(aXmlProfile, '//APC_JOB_PROGRAM_FROM')
           , extractvalue(aXmlProfile, '//APC_JOB_PROGRAM_TO')
           , extractvalue(aXmlProfile, '//APC_ORDER_FROM')
           , extractvalue(aXmlProfile, '//APC_ORDER_TO')
           , extractvalue(aXmlProfile, '//APC_C_PRIORITY_FROM')
           , extractvalue(aXmlProfile, '//APC_C_PRIORITY_TO')
           , extractvalue(aXmlProfile, '//APC_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//APC_FAMILY_TO')
           , extractvalue(aXmlProfile, '//APC_RECORD_FROM')
           , extractvalue(aXmlProfile, '//APC_RECORD_TO')
        into vOptions
        from dual;

      null;
    exception
      when others then
        raise_application_error(-20801, PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant l''extraction des valeurs du profil!') );
    end;

    return vOptions;
  end GetAPCProfileValues;
end FAL_ACI_POSTCALCULATION_FCT;
