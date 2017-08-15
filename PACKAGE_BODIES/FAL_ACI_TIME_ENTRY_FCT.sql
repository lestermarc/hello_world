--------------------------------------------------------
--  DDL for Package Body FAL_ACI_TIME_ENTRY_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ACI_TIME_ENTRY_FCT" 
is
  -- Statuts des enregistrements temporaires C_TIE_STATUS
  tsToProcess         constant FAL_ACI_TIME_ENTRY.C_TIE_STATUS%type          := '10';   -- A imputer
  tsProcessed         constant FAL_ACI_TIME_ENTRY.C_TIE_STATUS%type          := '20';   -- Imputé sans erreur
  tsProcessError      constant FAL_ACI_TIME_ENTRY.C_TIE_STATUS%type          := '30';   -- Erreur lors de l'imputation
  tsProcessAborted    constant FAL_ACI_TIME_ENTRY.C_TIE_STATUS%type          := '40';   -- Abandon par procédure indiv
  -- Statuts de lot C_LOT_STATUS
  lsLaunched                   FAL_LOT.C_LOT_STATUS%type                     := '2';   -- Lancé
  lsBalanced                   FAL_LOT.C_LOT_STATUS%type                     := '5';   -- Soldé (Réception)
  -- Sens d'imputation C_FAL_ENTRY_SIGN
  esDebit             constant FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN%type   := '0';   -- Débit
  esCredit            constant FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN%type   := '1';   -- Crédit
  -- Valeur par défaut des descriptions des heures
  cDefaultDescr       constant FAL_ACI_TIME_ENTRY.TIE_DESCRIPTION%type       := '<...>';
  cMaxDescrLength     constant integer                                       := 100;
  cMaxDocNumberLength constant integer                                       := 30;
  -- Configuration
  cDelayWeekStart     constant integer                                       := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

  /**
   * procedure ProcessFullAciTimeEntry
   * Description
   *   Applique le profil passé en paramètre (le premier paramètre non nul),
   *   génère les données pour l'imputation des heures et lance le processus.
   */
  procedure ProcessFullAciTimeEntry(
    aProfileID       in     number default null
  , aClobProfile     in     clob default null
  , aProfileName     in     varchar2 default null
  , aSuccessfulCount out    integer
  , aTotalCount      out    integer
  )
  is
    vOptions         TTIEOptions;
    vLastWeek        varchar2(7);
    vLastMonth       varchar2(7);
    vDateFrom        date;
    vDateTo          date;
    vSuccessfulCount integer;
    vTotalCount      integer;
  begin
    if aProfileID is not null then
      vOptions  := GetTIEProfileValues(PCS.COM_PROFILE_FUNCTIONS.GetXMLProfile(aProfileID) );
    elsif aClobProfile is not null then
      vOptions  := GetTIEProfileValues(xmltype.CreateXML(aClobProfile) );
    elsif aProfileName is not null then
      vOptions  := GetTIEProfileValues(PCS.COM_PROFILE_FUNCTIONS.GetXMLProfileByName(aProfileName => aProfileName, aVariant => 'WIZARD') );
    end if;

    ApplyTIEOptions(vOptions);

    -- Recherche des dates d'après les options
    case vOptions.TIE_DATE_UNIT
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
    GenerateTimeEntries(aDefaultSelection   => vOptions.TIE_SELECTION
                      , aInclLotProgr       => vOptions.TIE_INCL_BATCH_PROGR
                      , aInclGalHours       => vOptions.TIE_INCL_GAL_HOURS
                      , aDateFrom           => vDateFrom
                      , aDateTo             => vDateTo
                       );
    -- Traitement des heures sélectionnées
    ProcessTimeEntries(aSuccessfulCount => vSuccessfulCount, aTotalCount => vTotalCount);
  end ProcessFullAciTimeEntry;

  /**
   * procedure ApplyTIEOptions
   * Description
   *   Applique les options du profil (sélection des produits et lots)
   */
  procedure ApplyTIEOptions(aOptions in TTIEOptions)
  is
  begin
    if aOptions.TIE_INCL_BATCH_PROGR = 1 then
      SelectProducts(aTIE_PRODUCT_FROM             => aOptions.TIE_PRODUCT_FROM
                   , aTIE_PRODUCT_TO               => aOptions.TIE_PRODUCT_TO
                   , aTIE_GOOD_CATEGORY_FROM       => aOptions.TIE_GOOD_CATEGORY_FROM
                   , aTIE_GOOD_CATEGORY_TO         => aOptions.TIE_GOOD_CATEGORY_TO
                   , aTIE_GOOD_FAMILY_FROM         => aOptions.TIE_GOOD_FAMILY_FROM
                   , aTIE_GOOD_FAMILY_TO           => aOptions.TIE_GOOD_FAMILY_TO
                   , aTIE_ACCOUNTABLE_GROUP_FROM   => aOptions.TIE_ACCOUNTABLE_GROUP_FROM
                   , aTIE_ACCOUNTABLE_GROUP_TO     => aOptions.TIE_ACCOUNTABLE_GROUP_TO
                   , aTIE_GOOD_LINE_FROM           => aOptions.TIE_GOOD_LINE_FROM
                   , aTIE_GOOD_LINE_TO             => aOptions.TIE_GOOD_LINE_TO
                   , aTIE_GOOD_GROUP_FROM          => aOptions.TIE_GOOD_GROUP_FROM
                   , aTIE_GOOD_GROUP_TO            => aOptions.TIE_GOOD_GROUP_TO
                   , aTIE_GOOD_MODEL_FROM          => aOptions.TIE_GOOD_MODEL_FROM
                   , aTIE_GOOD_MODEL_TO            => aOptions.TIE_GOOD_MODEL_TO
                    );
      SelectBatches(aTIE_JOB_PROGRAM_FROM   => aOptions.TIE_JOB_PROGRAM_FROM
                  , aTIE_JOB_PROGRAM_TO     => aOptions.TIE_JOB_PROGRAM_TO
                  , aTIE_ORDER_FROM         => aOptions.TIE_ORDER_FROM
                  , aTIE_ORDER_TO           => aOptions.TIE_ORDER_TO
                  , aTIE_C_PRIORITY_FROM    => aOptions.TIE_C_PRIORITY_FROM
                  , aTIE_C_PRIORITY_TO      => aOptions.TIE_C_PRIORITY_TO
                  , aTIE_FAMILY_FROM        => aOptions.TIE_FAMILY_FROM
                  , aTIE_FAMILY_TO          => aOptions.TIE_FAMILY_TO
                  , aTIE_RECORD_FROM        => aOptions.TIE_RECORD_FROM
                  , aTIE_RECORD_TO          => aOptions.TIE_RECORD_TO
                   );
      SelectProgresses(aTIE_OPERATOR_FROM        => aOptions.TIE_OPERATOR_FROM
                     , aTIE_OPERATOR_TO          => aOptions.TIE_OPERATOR_TO
                     , aTIE_FACTORY_FLOOR_FROM   => aOptions.TIE_FLP_FACTORY_FLOOR_FROM
                     , aTIE_FACTORY_FLOOR_TO     => aOptions.TIE_FLP_FACTORY_FLOOR_TO
                      );
    end if;

    if aOptions.TIE_INCL_GAL_HOURS = 1 then
      SelectGalProjects(aTIE_GAL_PROJECT_FROM        => aOptions.TIE_GAL_PROJECT_FROM
                      , aTIE_GAL_PROJECT_TO          => aOptions.TIE_GAL_PROJECT_TO
                      , aTIE_GAL_PRJ_CATEGORY_FROM   => aOptions.TIE_GAL_PRJ_CATEGORY_FROM
                      , aTIE_GAL_PRJ_CATEGORY_TO     => aOptions.TIE_GAL_PRJ_CATEGORY_TO
                       );
      SelectGalHours(aTIE_EMPLOYEE_FROM            => aOptions.TIE_EMPLOYEE_FROM
                   , aTIE_EMPLOYEE_TO              => aOptions.TIE_EMPLOYEE_TO
                   , aTIE_GAL_TASK_FROM            => aOptions.TIE_GAL_TASK_FROM
                   , aTIE_GAL_TASK_TO              => aOptions.TIE_GAL_TASK_TO
                   , aTIE_FACTORY_FLOOR_FROM       => aOptions.TIE_GAL_FACTORY_FLOOR_FROM
                   , aTIE_FACTORY_FLOOR_TO         => aOptions.TIE_GAL_FACTORY_FLOOR_TO
                   , aTIE_GAL_BUDGET_FROM          => aOptions.TIE_GAL_BUDGET_FROM
                   , aTIE_GAL_BUDGET_TO            => aOptions.TIE_GAL_BUDGET_TO
                   , aTIE_GAL_HOUR_CODE_IND_FROM   => aOptions.TIE_GAL_HOUR_CODE_IND_FROM
                   , aTIE_GAL_HOUR_CODE_IND_TO     => aOptions.TIE_GAL_HOUR_CODE_IND_TO
                    );
    end if;
  end;

  /**
   * procedure SelectProduct
   * Description
   *   Sélectionne le produit
  *
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
    aTIE_PRODUCT_FROM           in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aTIE_PRODUCT_TO             in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aTIE_GOOD_CATEGORY_FROM     in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aTIE_GOOD_CATEGORY_TO       in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aTIE_GOOD_FAMILY_FROM       in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aTIE_GOOD_FAMILY_TO         in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aTIE_ACCOUNTABLE_GROUP_FROM in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aTIE_ACCOUNTABLE_GROUP_TO   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aTIE_GOOD_LINE_FROM         in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aTIE_GOOD_LINE_TO           in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aTIE_GOOD_GROUP_FROM        in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aTIE_GOOD_GROUP_TO          in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aTIE_GOOD_MODEL_FROM        in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , aTIE_GOOD_MODEL_TO          in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
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
                where GOO.GOO_MAJOR_REFERENCE between nvl(aTIE_PRODUCT_FROM, GOO.GOO_MAJOR_REFERENCE) and nvl(aTIE_PRODUCT_TO, GOO.GOO_MAJOR_REFERENCE)
                  and PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and (    (    aTIE_GOOD_CATEGORY_FROM is null
                            and aTIE_GOOD_CATEGORY_TO is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(aTIE_GOOD_CATEGORY_FROM, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(aTIE_GOOD_CATEGORY_TO, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    aTIE_GOOD_FAMILY_FROM is null
                            and aTIE_GOOD_FAMILY_TO is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(aTIE_GOOD_FAMILY_FROM, GOO.DIC_GOOD_FAMILY_ID) and nvl(aTIE_GOOD_FAMILY_TO, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    aTIE_ACCOUNTABLE_GROUP_FROM is null
                            and aTIE_ACCOUNTABLE_GROUP_TO is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(aTIE_ACCOUNTABLE_GROUP_FROM, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(aTIE_ACCOUNTABLE_GROUP_TO, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    aTIE_GOOD_LINE_FROM is null
                            and aTIE_GOOD_LINE_TO is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(aTIE_GOOD_LINE_FROM, GOO.DIC_GOOD_LINE_ID) and nvl(aTIE_GOOD_LINE_TO, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    aTIE_GOOD_GROUP_FROM is null
                            and aTIE_GOOD_GROUP_TO is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(aTIE_GOOD_GROUP_FROM, GOO.DIC_GOOD_GROUP_ID) and nvl(aTIE_GOOD_GROUP_TO, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    aTIE_GOOD_MODEL_FROM is null
                            and aTIE_GOOD_MODEL_TO is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(aTIE_GOOD_MODEL_FROM, GOO.DIC_GOOD_MODEL_ID) and nvl(aTIE_GOOD_MODEL_TO, GOO.DIC_GOOD_MODEL_ID)
                      );
  end SelectProducts;

  /**
   * procedure SelectBatch
   * Description
   *   Sélectionne un lot dont les avancements sont à imputer
   */
  procedure SelectBatch(aFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection de l'ID du lot dont les avancements sont à imputer
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
   *   Sélectionne les lots dont les avancements sont à imputer
   */
  procedure SelectBatches(
    aTIE_JOB_PROGRAM_FROM in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aTIE_JOB_PROGRAM_TO   in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aTIE_ORDER_FROM       in FAL_ORDER.ORD_REF%type
  , aTIE_ORDER_TO         in FAL_ORDER.ORD_REF%type
  , aTIE_C_PRIORITY_FROM  in FAL_LOT.C_PRIORITY%type
  , aTIE_C_PRIORITY_TO    in FAL_LOT.C_PRIORITY%type
  , aTIE_FAMILY_FROM      in DIC_FAMILY.DIC_FAMILY_ID%type
  , aTIE_FAMILY_TO        in DIC_FAMILY.DIC_FAMILY_ID%type
  , aTIE_RECORD_FROM      in DOC_RECORD.RCO_TITLE%type
  , aTIE_RECORD_TO        in DOC_RECORD.RCO_TITLE%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection des ID de lots dont les avancements sont à imputer
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
                  and LOT.LOT_OPEN__DTE is not null
--                   and (   LOT.C_LOT_STATUS = lsLaunched
--                        or LOT.C_LOT_STATUS = lsBalanced)
                  and exists(select FAL_LOT_PROGRESS_ID
                               from FAL_LOT_PROGRESS FLP
                              where FLP.FAL_LOT_ID = LOT.FAL_LOT_ID
                                and (   FLP.FLP_ADJUSTING_TIME <> 0
                                     or FLP.FLP_WORK_TIME <> 0
                                     or FLP.FLP_AMOUNT <> 0) )
                  and LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                  and (    (    aTIE_JOB_PROGRAM_FROM is null
                            and aTIE_JOB_PROGRAM_TO is null)
                       or JOP.JOP_REFERENCE between nvl(aTIE_JOB_PROGRAM_FROM, JOP.JOP_REFERENCE) and nvl(aTIE_JOB_PROGRAM_TO, JOP.JOP_REFERENCE)
                      )
                  and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
                  and (    (    aTIE_ORDER_FROM is null
                            and aTIE_ORDER_TO is null)
                       or ORD.ORD_REF between nvl(aTIE_ORDER_FROM, ORD.ORD_REF) and nvl(aTIE_ORDER_TO, ORD.ORD_REF)
                      )
                  and (    (    aTIE_C_PRIORITY_FROM is null
                            and aTIE_C_PRIORITY_TO is null)
                       or LOT.C_PRIORITY between nvl(aTIE_C_PRIORITY_FROM, LOT.C_PRIORITY) and nvl(aTIE_C_PRIORITY_TO, LOT.C_PRIORITY)
                      )
                  and (    (    aTIE_FAMILY_FROM is null
                            and aTIE_FAMILY_TO is null)
                       or LOT.DIC_FAMILY_ID between nvl(aTIE_FAMILY_FROM, LOT.DIC_FAMILY_ID) and nvl(aTIE_FAMILY_TO, LOT.DIC_FAMILY_ID)
                      )
                  and RCO.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
                  and (    (    aTIE_RECORD_FROM is null
                            and aTIE_RECORD_TO is null)
                       or RCO.RCO_TITLE between nvl(aTIE_RECORD_FROM, RCO.RCO_TITLE) and nvl(aTIE_RECORD_TO, RCO.RCO_TITLE)
                      );
  end SelectBatches;

  /**
   * procedure SelectProgresses
   * Description
   *   Sélectionne les avancements lot à imputer
   */
  procedure SelectProgresses(
    aTIE_OPERATOR_FROM      in DIC_OPERATOR.DIC_OPERATOR_ID%type
  , aTIE_OPERATOR_TO        in DIC_OPERATOR.DIC_OPERATOR_ID%type
  , aTIE_FACTORY_FLOOR_FROM in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aTIE_FACTORY_FLOOR_TO   in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_PROGRESS_ID';

    -- Sélection des ID de lots dont les avancements sont à imputer
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct FLP.FAL_LOT_PROGRESS_ID
                    , 'FAL_LOT_PROGRESS_ID'
                 from FAL_LOT_PROGRESS FLP
                    , FAL_LOT LOT
                    , FAL_FACTORY_FLOOR FAC_MACH
                    , FAL_FACTORY_FLOOR FAC_OPER
                where FLP.FAL_LOT_ID in(select COM_LIST_ID_TEMP_ID
                                          from COM_LIST_ID_TEMP
                                         where LID_CODE = 'FAL_LOT_ID')
                  and FLP.FAL_ACI_TIME_HIST_ID is null
                  and (   FLP.FLP_ADJUSTING_TIME <> 0
                       or FLP.FLP_WORK_TIME <> 0
                       or FLP.FLP_AMOUNT <> 0)
                  and (    (    aTIE_OPERATOR_FROM is null
                            and aTIE_OPERATOR_TO is null)
                       or FLP.DIC_OPERATOR_ID between nvl(aTIE_OPERATOR_FROM, FLP.DIC_OPERATOR_ID) and nvl(aTIE_OPERATOR_TO, FLP.DIC_OPERATOR_ID)
                      )
                  and FAC_MACH.FAL_FACTORY_FLOOR_ID(+) = FLP.FAL_FACTORY_FLOOR_ID
                  and FAC_OPER.FAL_FAL_FACTORY_FLOOR_ID(+) = FLP.FAL_FACTORY_FLOOR_ID
                  and (    (    aTIE_FACTORY_FLOOR_FROM is null
                            and aTIE_FACTORY_FLOOR_TO is null)
                       or FAC_MACH.FAC_REFERENCE between nvl(aTIE_FACTORY_FLOOR_FROM, FAC_MACH.FAC_REFERENCE) and nvl(aTIE_FACTORY_FLOOR_TO
                                                                                                                    , FAC_MACH.FAC_REFERENCE
                                                                                                                     )
                       or FAC_OPER.FAC_REFERENCE between nvl(aTIE_FACTORY_FLOOR_FROM, FAC_OPER.FAC_REFERENCE) and nvl(aTIE_FACTORY_FLOOR_TO
                                                                                                                    , FAC_OPER.FAC_REFERENCE
                                                                                                                     )
                      );
  end SelectProgresses;

  /**
   * procedure SelectGalProjects
   * Description
   *   Sélectionne les affaires dont les heures sont à imputer
   */
  procedure SelectGalProjects(
    aTIE_GAL_PROJECT_FROM      in GAL_PROJECT.PRJ_CODE%type
  , aTIE_GAL_PROJECT_TO        in GAL_PROJECT.PRJ_CODE%type
  , aTIE_GAL_PRJ_CATEGORY_FROM in DIC_GAL_PRJ_CATEGORY.DIC_GAL_PRJ_CATEGORY_ID%type
  , aTIE_GAL_PRJ_CATEGORY_TO   in DIC_GAL_PRJ_CATEGORY.DIC_GAL_PRJ_CATEGORY_ID%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GAL_PROJECT_ID';

    -- Sélection des ID de lots dont les avancements sont à imputer
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct PRJ.GAL_PROJECT_ID
                    , 'GAL_PROJECT_ID'
                 from GAL_PROJECT PRJ
                where exists(select GAL_HOURS_ID
                               from GAL_HOURS HOU
                              where HOU.GAL_PROJECT_ID = PRJ.GAL_PROJECT_ID
                                and HOU.HOU_WORKED_TIME <> 0)
                  and (    (    aTIE_GAL_PROJECT_FROM is null
                            and aTIE_GAL_PROJECT_TO is null)
                       or PRJ.PRJ_CODE between nvl(aTIE_GAL_PROJECT_FROM, PRJ.PRJ_CODE) and nvl(aTIE_GAL_PROJECT_TO, PRJ.PRJ_CODE)
                      )
                  and (    (    aTIE_GAL_PRJ_CATEGORY_FROM is null
                            and aTIE_GAL_PRJ_CATEGORY_TO is null)
                       or PRJ.DIC_GAL_PRJ_CATEGORY_ID between nvl(aTIE_GAL_PRJ_CATEGORY_FROM, PRJ.DIC_GAL_PRJ_CATEGORY_ID)
                                                          and nvl(aTIE_GAL_PRJ_CATEGORY_TO, PRJ.DIC_GAL_PRJ_CATEGORY_ID)
                      );
  end SelectGalProjects;

  /**
   * procedure SelectGalHours
   * Description
   *   Sélectionne les heures affaires à imputer
   */
  procedure SelectGalHours(
    aTIE_EMPLOYEE_FROM          in HRM_PERSON.EMP_NUMBER%type
  , aTIE_EMPLOYEE_TO            in HRM_PERSON.EMP_NUMBER%type
  , aTIE_GAL_TASK_FROM          in GAL_TASK.TAS_CODE%type
  , aTIE_GAL_TASK_TO            in GAL_TASK.TAS_CODE%type
  , aTIE_FACTORY_FLOOR_FROM     in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aTIE_FACTORY_FLOOR_TO       in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aTIE_GAL_BUDGET_FROM        in GAL_BUDGET.BDG_CODE%type
  , aTIE_GAL_BUDGET_TO          in GAL_BUDGET.BDG_CODE%type
  , aTIE_GAL_HOUR_CODE_IND_FROM in DIC_GAL_HOUR_CODE_IND.DIC_GAL_HOUR_CODE_IND_ID%type
  , aTIE_GAL_HOUR_CODE_IND_TO   in DIC_GAL_HOUR_CODE_IND.DIC_GAL_HOUR_CODE_IND_ID%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GAL_HOURS_ID';

    -- Sélection des ID de lots dont les avancements sont à imputer
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct HOU.GAL_HOURS_ID
                    , 'GAL_HOURS_ID'
                 from GAL_HOURS HOU
                    , HRM_PERSON EMP
                    , GAL_TASK TAS
                    , GAL_TASK_LINK TAL
                    , FAL_FACTORY_FLOOR FAC
                    , GAL_BUDGET BDG
                where HOU.GAL_PROJECT_ID in(select COM_LIST_ID_TEMP_ID
                                              from COM_LIST_ID_TEMP
                                             where LID_CODE = 'GAL_PROJECT_ID')
                  and HOU.FAL_ACI_TIME_HIST_ID is null
                  and HOU.HOU_WORKED_TIME <> 0
                  and EMP.HRM_PERSON_ID(+) = HOU.HRM_PERSON_ID
                  and (    (    aTIE_EMPLOYEE_FROM is null
                            and aTIE_EMPLOYEE_TO is null)
                       or EMP.EMP_NUMBER between nvl(aTIE_EMPLOYEE_FROM, EMP.EMP_NUMBER) and nvl(aTIE_EMPLOYEE_TO, EMP.EMP_NUMBER)
                      )
                  and TAS.GAL_TASK_ID(+) = HOU.GAL_TASK_ID
                  and (    (    aTIE_GAL_TASK_FROM is null
                            and aTIE_GAL_TASK_TO is null)
                       or TAS.TAS_CODE between nvl(aTIE_GAL_TASK_FROM, TAS.TAS_CODE) and nvl(aTIE_GAL_TASK_TO, TAS.TAS_CODE)
                      )
                  and TAL.GAL_TASK_LINK_ID(+) = HOU.GAL_TASK_LINK_ID
                  and FAC.FAL_FACTORY_FLOOR_ID(+) = TAL.FAL_FACTORY_FLOOR_ID
                  and (    (    aTIE_FACTORY_FLOOR_FROM is null
                            and aTIE_FACTORY_FLOOR_TO is null)
                       or FAC.FAC_REFERENCE between nvl(aTIE_FACTORY_FLOOR_FROM, FAC.FAC_REFERENCE) and nvl(aTIE_FACTORY_FLOOR_TO, FAC.FAC_REFERENCE)
                      )
                  and BDG.GAL_BUDGET_ID(+) = HOU.GAL_BUDGET_ID
                  and (    (    aTIE_GAL_TASK_FROM is null
                            and aTIE_GAL_TASK_TO is null)
                       or BDG.BDG_CODE between nvl(aTIE_GAL_BUDGET_FROM, BDG.BDG_CODE) and nvl(aTIE_GAL_BUDGET_TO, BDG.BDG_CODE)
                      )
                  and HOU.DIC_GAL_HOUR_CODE_IND_ID is null;
-- Heures indirectes non imputées
--                   and (    (    aTIE_GAL_HOUR_CODE_IND_FROM is null
--                             and aTIE_GAL_HOUR_CODE_IND_TO is null)
--                        or HOU.DIC_GAL_HOUR_CODE_IND_ID between nvl(aTIE_GAL_HOUR_CODE_IND_FROM
--                                                                  , HOU.DIC_GAL_HOUR_CODE_IND_ID
--                                                                   )
--                                                            and nvl(aTIE_GAL_HOUR_CODE_IND_TO
--                                                                  , HOU.DIC_GAL_HOUR_CODE_IND_ID
--                                                                   )
--                       );
  end SelectGalHours;

  procedure CalcRates(
    aAdjustingTime     in     FAL_LOT_PROGRESS.FLP_ADJUSTING_TIME%type
  , aWorkTime          in     FAL_LOT_PROGRESS.FLP_WORK_TIME%type
  , aFactoryFloorId    in     FAL_LOT_PROGRESS.FAL_FACTORY_FLOOR_ID%type
  , aFactoryOperId     in     FAL_LOT_PROGRESS.FAL_FAL_FACTORY_FLOOR_ID%type
  , aDate              in     FAL_LOT_PROGRESS.FLP_DATE1%type
  , aOperRateNumber    in     FAL_LOT_PROGRESS.FLP_ADJUSTING_RATE%type
  , aMachRateNumber    in     FAL_LOT_PROGRESS.FLP_RATE%type
  , aSchedulePlanning  in     FAL_LOT.C_SCHEDULE_PLANNING%type
  , aTaskImputation    in     FAL_TASK_LINK.C_TASK_IMPUTATION%type
  , aAdjustingFloor    in     FAL_TASK_LINK.SCS_ADJUSTING_FLOOR%type
  , aWorkFloor         in     FAL_TASK_LINK.SCS_WORK_FLOOR%type
  , aAdjustingOperator in     FAL_TASK_LINK.SCS_ADJUSTING_OPERATOR%type
  , aWorkOperator      in     FAL_TASK_LINK.SCS_WORK_OPERATOR%type
  , aNumAdjustOper     in     FAL_TASK_LINK.SCS_NUM_ADJUST_OPERATOR%type
  , aNumWorkOper       in     FAL_TASK_LINK.SCS_NUM_WORK_OPERATOR%type
  , aPercentAdjustOper in     FAL_TASK_LINK.SCS_PERCENT_ADJUST_OPER%type
  , aPercentWorkOper   in     FAL_TASK_LINK.SCS_PERCENT_WORK_OPER%type
  , aMachAdjTime       out    FAL_ACI_TIME_ENTRY.TIE_MACH_ADJ_TIME%type
  , aMachWorkTime      out    FAL_ACI_TIME_ENTRY.TIE_MACH_WORK_TIME%type
  , aMachRate          out    FAL_ACI_TIME_ENTRY.TIE_MACH_RATE%type
  , aOperAdjTime       out    FAL_ACI_TIME_ENTRY.TIE_OPER_ADJ_TIME%type
  , aOperWorkTime      out    FAL_ACI_TIME_ENTRY.TIE_OPER_WORK_TIME%type
  , aOperRate          out    FAL_ACI_TIME_ENTRY.TIE_OPER_RATE%type
  )
  is
    vAdjustingTime FAL_LOT_PROGRESS.FLP_ADJUSTING_TIME%type;
    vWorkTime      FAL_LOT_PROGRESS.FLP_WORK_TIME%type;
  begin
    aMachRate  := FAL_FACT_FLOOR.GetDateRateValue(aFactoryFloorId, aDate, aMachRateNumber);
    aOperRate  := FAL_FACT_FLOOR.GetDateRateValue(nvl(aFactoryOperId, aFactoryFloorId), aDate, aOperRateNumber);

    if PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') = 'M' then
      vAdjustingTime  := aAdjustingTime / 60;
      vWorkTime       := aWorkTime / 60;
    else
      vAdjustingTime  := aAdjustingTime;
      vWorkTime       := aWorkTime;
    end if;

    --     + aMontant ? -> aMachAmount ?
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
  end CalcRates;

  /**
   * procedure GenerateDescription
   * Description
   *   Génère une description du suivi
   */
  function GenerateDescription(
    aProgressOrigin in FAL_ACI_TIME_ENTRY.C_PROGRESS_ORIGIN%type
  , aGalHoursId     in FAL_ACI_TIME_ENTRY.GAL_HOURS_ID%type default null
  , aLotProgressId  in FAL_ACI_TIME_ENTRY.FAL_LOT_PROGRESS_ID%type default null
  )
    return FAL_ACI_TIME_ENTRY.TIE_DESCRIPTION%type
  is
    cursor crProdInfos(aLotProgressId in FAL_ACI_TIME_ENTRY.FAL_LOT_PROGRESS_ID%type)
    is
      select LOT.LOT_REFCOMPL
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
           , TAL.SCS_STEP_NUMBER
        from FAL_LOT_PROGRESS FLP
           , FAL_TASK_LINK TAL
           , FAL_LOT LOT
           , GCO_GOOD GOO
       where FLP.FAL_LOT_PROGRESS_ID = aLotProgressId
         and TAL.FAL_SCHEDULE_STEP_ID = FLP.FAL_SCHEDULE_STEP_ID
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
         and GOO.GCO_GOOD_ID = LOT.GCO_GOOD_ID;

    tplProdInfos    crProdInfos%rowtype;

    cursor crProjectInfos(aGalHoursId in FAL_ACI_TIME_ENTRY.GAL_HOURS_ID%type)
    is
      select HOU.GAL_BUDGET_ID
           , HOU.GAL_TASK_ID
           , HOU.GAL_TASK_LINK_ID
           , PRJ.PRJ_CODE
           , PRJ.PRJ_WORDING
           , BDG.BDG_CODE
           , BDG.BDG_WORDING
           , TAS.TAS_CODE
           , TAS.TAS_WORDING
           , TAL.SCS_STEP_NUMBER
        from GAL_HOURS HOU
           , GAL_PROJECT PRJ
           , GAL_BUDGET BDG
           , GAL_TASK TAS
           , GAL_TASK_LINK TAL
       where HOU.GAL_HOURS_ID = aGalHoursId
         and PRJ.GAL_PROJECT_ID(+) = HOU.GAL_PROJECT_ID
         and BDG.GAL_BUDGET_ID(+) = HOU.GAL_BUDGET_ID
         and TAS.GAL_TASK_ID(+) = HOU.GAL_TASK_ID
         and TAL.GAL_TASK_LINK_ID(+) = HOU.GAL_TASK_LINK_ID;

    tplProjectInfos crProjectInfos%rowtype;
    vResult         varchar2(4000);
  begin
    case aProgressOrigin
      when poProduction then
        open crProdInfos(aLotProgressId);

        fetch crProdInfos
         into tplProdInfos;

        close crProdInfos;

        vResult  :=
          tplProdInfos.LOT_REFCOMPL ||
          ' / ' ||
          tplProdInfos.GOO_MAJOR_REFERENCE ||
          ' / ' ||
          tplProdInfos.GOO_SECONDARY_REFERENCE ||
          ' / ' ||
          tplProdInfos.SCS_STEP_NUMBER;

        -- Si la description est trop longue on enlève la référence secondaire du produit
        if length(vResult) > cMaxDescrLength then
          vResult  := tplProdInfos.LOT_REFCOMPL || ' / ' || tplProdInfos.GOO_MAJOR_REFERENCE || ' / / ' || tplProdInfos.SCS_STEP_NUMBER;
        end if;

        -- Tronquage et valeur par défaut
        return nvl(truncstr(vResult, cMaxDescrLength), cDefaultDescr);
      when poProject then
        open crProjectInfos(aGalHoursId);

        fetch crProjectInfos
         into tplProjectInfos;

        close crProjectInfos;

        if tplProjectInfos.GAL_BUDGET_ID is not null then
          -- Heures sur budget
          vResult  := tplProjectInfos.PRJ_CODE || ' ' || tplProjectInfos.PRJ_WORDING || '/' || tplProjectInfos.BDG_CODE || ' ' || tplProjectInfos.BDG_WORDING;

          -- Si la description est trop longue on enlève les libellés
          if length(vResult) > cMaxDescrLength then
            vResult  := tplProjectInfos.PRJ_CODE || '/' || tplProjectInfos.BDG_CODE;
          end if;
        elsif tplProjectInfos.GAL_TASK_ID is not null then
          if tplProjectInfos.GAL_TASK_LINK_ID is null then
            -- Heures sur tâche
            vResult  := tplProjectInfos.PRJ_CODE || ' ' || tplProjectInfos.PRJ_WORDING || '/' || tplProjectInfos.TAS_CODE || ' ' || tplProjectInfos.TAS_WORDING;

            -- Si la description est trop longue on enlève les libellés
            if length(vResult) > cMaxDescrLength then
              vResult  := tplProjectInfos.PRJ_CODE || '/' || tplProjectInfos.TAS_CODE;
            end if;
          else
            -- Heures sur opération de tâche ou de dossier de fabrication
            vResult  :=
              tplProjectInfos.PRJ_CODE ||
              ' ' ||
              tplProjectInfos.PRJ_WORDING ||
              '/' ||
              tplProjectInfos.TAS_CODE ||
              ' ' ||
              tplProjectInfos.TAS_WORDING ||
              '/' ||
              tplProjectInfos.SCS_STEP_NUMBER;

            -- Si la description est trop longue on enlève les libellés
            if length(vResult) > cMaxDescrLength then
              vResult  := tplProjectInfos.PRJ_CODE || '/' || tplProjectInfos.TAS_CODE || '/' || tplProjectInfos.SCS_STEP_NUMBER;
            end if;
          end if;
        end if;

        -- Tronquage à gauche et valeur par défaut
        return nvl(truncstr(vResult, -cMaxDescrLength), cDefaultDescr);
    end case;
  end GenerateDescription;

  /**
   * procedure GenerateTimeEntries
   * Description
   *   Crée les enregistrements temporaires et calcule les données à utiliser
   *   pour l'imputation des heures
   */
  procedure GenerateTimeEntries(
    aDefaultSelection in FAL_ACI_TIME_ENTRY.TIE_SELECTION%type
  , aInclLotProgr     in integer default 1
  , aInclGalHours     in integer default 1
  , aDateFrom         in date default null
  , aDateTo           in date default sysdate
  )
  is
    cursor crLotProgresses(aDateFrom in date, aDateTo in date)
    is
      select FLP.FAL_LOT_PROGRESS_ID
           , FLP.FLP_DATE1
           , FLP.FLP_ADJUSTING_TIME
           , FLP.FLP_WORK_TIME
           , FLP.FAL_FACTORY_FLOOR_ID
           , FLP.FLP_AMOUNT
           , nvl(FLP.FAL_FAL_FACTORY_FLOOR_ID, FLP.FAL_FACTORY_FLOOR_ID) FAL_FACTORY_OPER_ID
           , FLP.FLP_RATE FLP_MACH_RATE_NUMBER
           , FLP.FLP_ADJUSTING_RATE FLP_OPER_RATE_NUMBER
           , TAL.C_TASK_IMPUTATION
           , TAL.SCS_ADJUSTING_FLOOR
           , TAL.SCS_WORK_FLOOR
           , TAL.SCS_ADJUSTING_OPERATOR
           , TAL.SCS_WORK_OPERATOR
           , TAL.SCS_NUM_ADJUST_OPERATOR
           , TAL.SCS_NUM_WORK_OPERATOR
           , TAL.SCS_PERCENT_ADJUST_OPER
           , TAL.SCS_PERCENT_WORK_OPER
           , LOT.C_SCHEDULE_PLANNING
        from FAL_LOT_PROGRESS FLP
           , FAL_TASK_LINK TAL
           , FAL_LOT LOT
       where FLP.FAL_LOT_PROGRESS_ID in(select COM_LIST_ID_TEMP_ID
                                          from COM_LIST_ID_TEMP
                                         where LID_CODE = 'FAL_LOT_PROGRESS_ID')
         and (    (    aDateFrom is null
                   and aDateTo is null)
              or trunc(FLP.FLP_DATE1) between nvl(trunc(aDateFrom), trunc(FLP.FLP_DATE1) ) and nvl(trunc(aDateTo), trunc(FLP.FLP_DATE1) )
             )
         and (   FLP.FLP_ADJUSTING_TIME <> 0
              or FLP.FLP_WORK_TIME <> 0
              or FLP.FLP_AMOUNT <> 0)
         and TAL.FAL_SCHEDULE_STEP_ID = FLP.FAL_SCHEDULE_STEP_ID
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID;

    type TLotProgresses is table of crLotProgresses%rowtype;

    vLotProgresses      TLotProgresses;

    cursor crGalHours(aDateFrom in date, aDateTo in date)
    is
      select HOU.GAL_HOURS_ID
           , HOU.HOU_POINTING_DATE
           , HOU.HOU_WORKED_TIME
           , HOU.HOU_HOURLY_RATE
           , TAL.FAL_FACTORY_FLOOR_ID
        from GAL_HOURS HOU
           , GAL_TASK_LINK TAL
       where HOU.GAL_HOURS_ID in(select COM_LIST_ID_TEMP_ID
                                   from COM_LIST_ID_TEMP
                                  where LID_CODE = 'GAL_HOURS_ID')
         and (    (    aDateFrom is null
                   and aDateTo is null)
              or trunc(HOU.HOU_POINTING_DATE) between nvl(trunc(aDateFrom), trunc(HOU.HOU_POINTING_DATE) ) and nvl(trunc(aDateTo), trunc(HOU.HOU_POINTING_DATE) )
             )
         and HOU.HOU_WORKED_TIME <> 0
         and TAL.GAL_TASK_LINK_ID(+) = HOU.GAL_TASK_LINK_ID;

    type TGalHours is table of crGalHours%rowtype;

    vGalHours           TGalHours;
    cBulkLimit constant number                                       := 10000;
    vIndex              integer;
    vMachAdjTime        FAL_ACI_TIME_ENTRY.TIE_MACH_ADJ_TIME%type;
    vMachWorkTime       FAL_ACI_TIME_ENTRY.TIE_MACH_WORK_TIME%type;
    vMachRate           FAL_ACI_TIME_ENTRY.TIE_MACH_RATE%type;
    vOperAdjTime        FAL_ACI_TIME_ENTRY.TIE_OPER_ADJ_TIME%type;
    vOperWorkTime       FAL_ACI_TIME_ENTRY.TIE_OPER_WORK_TIME%type;
    vOperRate           FAL_ACI_TIME_ENTRY.TIE_OPER_RATE%type;
    vDescription        FAL_ACI_TIME_ENTRY.TIE_DESCRIPTION%type;
  begin
    -- Suppression des enregistrements précédents non-traités
    delete from FAL_ACI_TIME_ENTRY
          where C_TIE_STATUS = tsToProcess;

    -- Recherche des avancements lot
    if aInclLotProgr = 1 then
      open crLotProgresses(aDateFrom, aDateTo);

      fetch crLotProgresses
      bulk collect into vLotProgresses limit cBulkLimit;

      while vLotProgresses.count > 0 loop
        -- Pour chaque avancement
        for vIndex in vLotProgresses.first .. vLotProgresses.last loop
          -- Génération de la description limitée à 100 char
          vDescription  := GenerateDescription(aProgressOrigin => poProduction, aLotProgressId => vLotProgresses(vIndex).FAL_LOT_PROGRESS_ID);
          -- Recherche et calcul des durées et taux
          CalcRates(aAdjustingTime       => vLotProgresses(vIndex).FLP_ADJUSTING_TIME
                  , aWorkTime            => vLotProgresses(vIndex).FLP_WORK_TIME
                  , aFactoryFloorId      => vLotProgresses(vIndex).FAL_FACTORY_FLOOR_ID
                  , aFactoryOperId       => vLotProgresses(vIndex).FAL_FACTORY_OPER_ID
                  , aDate                => vLotProgresses(vIndex).FLP_DATE1
                  , aOperRateNumber      => vLotProgresses(vIndex).FLP_OPER_RATE_NUMBER
                  , aMachRateNumber      => vLotProgresses(vIndex).FLP_MACH_RATE_NUMBER
                  , aSchedulePlanning    => vLotProgresses(vIndex).C_SCHEDULE_PLANNING
                  , aTaskImputation      => vLotProgresses(vIndex).C_TASK_IMPUTATION
                  , aAdjustingFloor      => vLotProgresses(vIndex).SCS_ADJUSTING_FLOOR
                  , aWorkFloor           => vLotProgresses(vIndex).SCS_WORK_FLOOR
                  , aAdjustingOperator   => vLotProgresses(vIndex).SCS_ADJUSTING_OPERATOR
                  , aWorkOperator        => vLotProgresses(vIndex).SCS_WORK_OPERATOR
                  , aNumAdjustOper       => vLotProgresses(vIndex).SCS_NUM_ADJUST_OPERATOR
                  , aNumWorkOper         => vLotProgresses(vIndex).SCS_NUM_WORK_OPERATOR
                  , aPercentAdjustOper   => vLotProgresses(vIndex).SCS_PERCENT_ADJUST_OPER
                  , aPercentWorkOper     => vLotProgresses(vIndex).SCS_PERCENT_WORK_OPER
                  , aMachAdjTime         => vMachAdjTime
                  , aMachWorkTime        => vMachWorkTime
                  , aMachRate            => vMachRate
                  , aOperAdjTime         => vOperAdjTime
                  , aOperWorkTime        => vOperWorkTime
                  , aOperRate            => vOperRate
                   );

-- On abandonne ce test car il pose problème au contrôle du solde du lot car
-- avec ce test l'élément de coût n'est pas créé
--           -- Insertion de l'enregistrement si au moins un montant sera <> 0
--           if    vLotProgresses(vIndex).FLP_AMOUNT <> 0
--              or (     (   vMachAdjTime <> 0
--                        or vMachWorkTime <> 0)
--                  and vMachRate <> 0)
--              or (     (   vOperAdjTime <> 0
--                        or vOperWorkTime <> 0)
--                  and vOperRate <> 0) then
            -- Insertion de l'enregistrement à traiter
          insert into FAL_ACI_TIME_ENTRY
                      (FAL_ACI_TIME_ENTRY_ID
                     , C_TIE_STATUS
                     , TIE_DESCRIPTION
                     , TIE_SELECTION
                     , C_PROGRESS_ORIGIN
                     , FAL_LOT_PROGRESS_ID
                     , TIE_VALUE_DATE
                     , TIE_PROGRESS_DATE
                     , TIE_ADDITIONAL_AMOUNT
                     , TIE_MACH_ADJ_TIME
                     , TIE_MACH_WORK_TIME
                     , TIE_MACH_RATE
                     , FAL_MACH_FAC_FLOOR_ID
                     , TIE_OPER_ADJ_TIME
                     , TIE_OPER_WORK_TIME
                     , TIE_OPER_RATE
                     , FAL_OPER_FAC_FLOOR_ID
                      )
               values (INIT_TEMP_ID_SEQ.nextval   -- FAL_ACI_TIME_ENTRY_ID
                     , tsToProcess
                     , nvl(vDescription, cDefaultDescr)
                     , aDefaultSelection
                     , poProduction
                     , vLotProgresses(vIndex).FAL_LOT_PROGRESS_ID
                     , vLotProgresses(vIndex).FLP_DATE1
                     , vLotProgresses(vIndex).FLP_DATE1
                     , zvl(vLotProgresses(vIndex).FLP_AMOUNT, null)
                     , zvl(vMachAdjTime, null)
                     , zvl(vMachWorkTime, null)
                     , zvl(vMachRate, null)
                     , vLotProgresses(vIndex).FAL_FACTORY_FLOOR_ID
                     , zvl(vOperAdjTime, null)
                     , zvl(vOperWorkTime, null)
                     , zvl(vOperRate, null)
                     , vLotProgresses(vIndex).FAL_FACTORY_OPER_ID
                      );
        end loop;

        fetch crLotProgresses
        bulk collect into vLotProgresses limit cBulkLimit;
      end loop;

      close crLotProgresses;
    end if;

    -- Recherche des heures gestion à l'affaire
    if aInclGalHours = 1 then
      open crGalHours(aDateFrom, aDateTo);

      fetch crGalHours
      bulk collect into vGalHours limit cBulkLimit;

      while vGalHours.count > 0 loop
        -- Pour chaque pointage
        for vIndex in vGalHours.first .. vGalHours.last loop
          -- Génération de la description limitée à 100 char
          vDescription  := GenerateDescription(aProgressOrigin => poProject, aGalHoursId => vGalHours(vIndex).GAL_HOURS_ID);

          -- Insertion de l'enregistrement à traiter
          -- Insertion de l'enregistrement si le montant sera <> 0
          if     vGalHours(vIndex).HOU_WORKED_TIME <> 0
             and vGalHours(vIndex).HOU_HOURLY_RATE <> 0 then
            insert into FAL_ACI_TIME_ENTRY
                        (FAL_ACI_TIME_ENTRY_ID
                       , C_TIE_STATUS
                       , TIE_DESCRIPTION
                       , TIE_SELECTION
                       , C_PROGRESS_ORIGIN
                       , GAL_HOURS_ID
                       , TIE_VALUE_DATE
                       , TIE_PROGRESS_DATE
                       , TIE_MACH_WORK_TIME
                       , TIE_MACH_RATE
                       , FAL_MACH_FAC_FLOOR_ID
                        )
                 values (INIT_TEMP_ID_SEQ.nextval   -- FAL_ACI_TIME_ENTRY_ID
                       , tsToProcess
                       , nvl(vDescription, cDefaultDescr)
                       , aDefaultSelection
                       , poProject
                       , vGalHours(vIndex).GAL_HOURS_ID
                       , vGalHours(vIndex).HOU_POINTING_DATE
                       , vGalHours(vIndex).HOU_POINTING_DATE
                       , zvl(vGalHours(vIndex).HOU_WORKED_TIME, null)
                       , zvl(vGalHours(vIndex).HOU_HOURLY_RATE, null)
                       , vGalHours(vIndex).FAL_FACTORY_FLOOR_ID
                        );
          end if;
        end loop;

        fetch crGalHours
        bulk collect into vGalHours limit cBulkLimit;
      end loop;

      close crGalHours;
    end if;
  end GenerateTimeEntries;

  /**
   * procedure GetAccounts
   * Description
   *   Recherche des comptes pour l'imputation des heures
   *
   */
  procedure GetAccounts(
    aEntryType      in     FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE%type
  , aEntrySign      in     FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN%type
  , aValueDate      in     FAL_ACI_TIME_HIST.TIH_VALUE_DATE%type
  , aProgressOrigin in     FAL_ACI_TIME_HIST.C_PROGRESS_ORIGIN%type default poProduction
  , aLotProgressId  in     FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type default null
  , aGalHoursId     in     GAL_HOURS.GAL_TASK_ID%type default null
  , aFactoryFloorId in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type default null
  , aCostCenterId   in     GAL_COST_CENTER.GAL_COST_CENTER_ID%type default null
  , aProjectId      in     GAL_HOURS.GAL_PROJECT_ID%type default null
  , aLotId          in     FAL_LOT_PROGRESS.FAL_LOT_ID%type default null
  , aGoodId         in     FAL_LOT.GCO_GOOD_ID%type default null
  , aDocRecordId    out    DOC_RECORD.DOC_RECORD_ID%type
  , aHrmPersonId    in out HRM_PERSON.HRM_PERSON_ID%type
  , aFinancialId    out    ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , aDivisionId     out    ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , aCpnId          out    ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aCdaId          out    ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , aPfId           out    ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , aPjId           out    ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  , aQtyId          out    ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , aAccountInfo    in out ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo
  )
  is
    cursor crAccountsDatas(
      aEntryType      in FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE%type
    , aEntrySign      in FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN%type
    , aProgressOrigin in FAL_ACI_TIME_HIST.C_PROGRESS_ORIGIN%type
    , aFactoryFloorId in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
    , aCostCenterId   in GAL_COST_CENTER.GAL_COST_CENTER_ID%type
    )
    is
      select FFA.DOC_RECORD_ID
           , FAC.FAM_FIXED_ASSETS_ID
           , FAC.HRM_PERSON_ID
           , FAC.GAL_COST_CENTER_ID
        from FAL_FACTORY_FLOOR FAC
           , FAL_FACTORY_ACCOUNT FFA
       where (    (FFA.FAL_FACTORY_FLOOR_ID = aFactoryFloorId)
              or (FFA.GAL_COST_CENTER_ID = aCostCenterId) )
         and FFA.C_FAL_ENTRY_TYPE = aEntryType
         and FFA.C_FAL_ENTRY_SIGN = aEntrySign
         and FAC.FAL_FACTORY_FLOOR_ID(+) = FFA.FAL_FACTORY_FLOOR_ID;

    tplAccountsData crAccountsDatas%rowtype;
    vGalPrjRecordId GAL_PROJECT.DOC_RECORD_ID%type;
  begin
    open crAccountsDatas(aEntryType, aEntrySign, aProgressOrigin, aFactoryFloorId, aCostCenterId);

    fetch crAccountsDatas
     into tplAccountsData;

    close crAccountsDatas;

    -- Recherche de l'employé lié à la ressource (pour les ressources de type opérateur)
    -- s'il n'est pas passé en paramètre
    aHrmPersonId                      := nvl(aHrmPersonId, tplAccountsData.HRM_PERSON_ID);

    -- Recherche des comptes par défaut et déplacements
    case aProgressOrigin
      when poProduction then
        -- Recherche des comptes pour l'imputation
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetProgressAccounts(iCurId               => aLotProgressId
                                                       , iElementType         => case aEntrySign
                                                           when esCredit then ACS_I_LIB_LOGISTIC_FINANCIAL.cgEtProgressSrcEntryCredit
                                                           when esDebit then ACS_I_LIB_LOGISTIC_FINANCIAL.cgEtProgressDestEntryDebit
                                                         end
                                                       , iAdminDomain         => ACS_I_LIB_LOGISTIC_FINANCIAL.gcAdProduction
                                                       , iEntryType           => aEntryType
                                                       , iEntrySign           => aEntrySign
                                                       , iDateRef             => aValueDate
                                                       , iFalLotId            => aLotId
                                                       , iFalFactoryFloorId   => aFactoryFloorId
                                                       , iHrmPersonId         => aHrmPersonId
                                                       , ioFinancialId        => aFinancialId
                                                       , ioDivisionId         => aDivisionId
                                                       , ioCpnId              => aCpnId
                                                       , ioCdaId              => aCdaId
                                                       , ioPfId               => aPfId
                                                       , ioPjId               => aPjId
                                                       , ioQtyId              => aQtyId
                                                       , iotAccountInfo       => aAccountInfo
                                                        );
      when poProject then
        -- Recherche du dossier lié à l'affaire
        select DOC_RECORD_ID
          into vGalPrjRecordId
          from GAL_PROJECT
         where GAL_PROJECT_ID = aProjectId;

        -- Recherche des comptes pour l'imputation
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetProgressAccounts(iCurId               => aGalHoursId
                                                       , iElementType         => case aEntrySign
                                                           when esCredit then ACS_I_LIB_LOGISTIC_FINANCIAL.cgEtProgressSrcEntryCredit
                                                           when esDebit then ACS_I_LIB_LOGISTIC_FINANCIAL.cgEtProgressDestEntryDebit
                                                         end
                                                       , iAdminDomain         => ACS_I_LIB_LOGISTIC_FINANCIAL.gcAdProjectBasedERP
                                                       , iEntryType           => aEntryType
                                                       , iEntrySign           => aEntrySign
                                                       , iDateRef             => aValueDate
                                                       , iRecordId            => vGalPrjRecordId
                                                       , iFalFactoryFloorId   => aFactoryFloorId
                                                       , iGalCostCenterId     => nvl(aCostCenterId, tplAccountsData.GAL_COST_CENTER_ID)
                                                       , iHrmPersonId         => aHrmPersonId
                                                       , ioFinancialId        => aFinancialId
                                                       , ioDivisionId         => aDivisionId
                                                       , ioCpnId              => aCpnId
                                                       , ioCdaId              => aCdaId
                                                       , ioPfId               => aPfId
                                                       , ioPjId               => aPjId
                                                       , ioQtyId              => aQtyId
                                                       , iotAccountInfo       => aAccountInfo
                                                        );
        aDocRecordId  := tplAccountsData.DOC_RECORD_ID;

        if     aDocRecordId is null
           and tplAccountsData.GAL_COST_CENTER_ID is not null then
          select max(FFA.DOC_RECORD_ID)
            into aDocRecordId
            from FAL_FACTORY_ACCOUNT FFA
           where FFA.GAL_COST_CENTER_ID = tplAccountsData.GAL_COST_CENTER_ID
             and FFA.C_FAL_ENTRY_TYPE = aEntryType
             and FFA.C_FAL_ENTRY_SIGN = aEntrySign;
        end if;
    end case;

    if aAccountInfo.DEF_HRM_PERSON is not null then
      select HRM_PERSON_ID
        into aHrmPersonId
        from HRM_PERSON
       where EMP_NUMBER = aAccountInfo.DEF_HRM_PERSON;
    end if;

    aAccountInfo.FAM_FIXED_ASSETS_ID  := nvl(aAccountInfo.FAM_FIXED_ASSETS_ID, tplAccountsData.FAM_FIXED_ASSETS_ID);
  end GetAccounts;

  /**
   * procedure CreateDetail
   * Description
   *
   */
  procedure CreateDetail(
    aAciTimeHistId  in FAL_ACI_TIME_HIST_DET.FAL_ACI_TIME_HIST_ID%type
  , aEntryType      in FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_TYPE%type
  , aEntrySign      in FAL_ACI_TIME_HIST_DET.C_FAL_ENTRY_SIGN%type
  , aValueDate      in FAL_ACI_TIME_HIST.TIH_VALUE_DATE%type
  , aProgressOrigin in FAL_ACI_TIME_HIST.C_PROGRESS_ORIGIN%type
  , aLotProgressId  in FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type
  , aGalHoursId     in GAL_HOURS.GAL_TASK_ID%type
  , aFactoryFloorId in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aCostCenterId   in GAL_COST_CENTER.GAL_COST_CENTER_ID%type
  , aProjectId      in GAL_HOURS.GAL_PROJECT_ID%type
  , aHrmPersonId    in GAL_HOURS.HRM_PERSON_ID%type
  , aLotId          in FAL_LOT_PROGRESS.FAL_LOT_ID%type
  , aGoodId         in FAL_LOT.GCO_GOOD_ID%type
  )
  is
    vHrmPersonId HRM_PERSON.HRM_PERSON_ID%type;
    vDocRecordId DOC_RECORD.DOC_RECORD_ID%type;
    vFinancialId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    vDivisionId  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vCpnId       ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    vCdaId       ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type;
    vPfId        ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type;
    vPjId        ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type;
    vQtyId       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    vAccountInfo ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
  begin
    -- Recherche des comptes
    vHrmPersonId  := aHrmPersonId;
    GetAccounts(aEntryType        => aEntryType
              , aEntrySign        => aEntrySign
              , aValueDate        => aValueDate
              , aProgressOrigin   => aProgressOrigin
              , aLotProgressId    => aLotProgressId
              , aGalHoursId       => aGalHoursId
              , aFactoryFloorId   => aFactoryFloorId
              , aCostCenterId     => aCostCenterId
              , aProjectId        => aProjectId
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

    -- Insertion dans la table détail
    insert into FAL_ACI_TIME_HIST_DET
                (FAL_ACI_TIME_HIST_DET_ID
               , FAL_ACI_TIME_HIST_ID
               , C_FAL_ENTRY_TYPE
               , C_FAL_ENTRY_SIGN
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_QTY_UNIT_ID
               , DOC_RECORD_ID
               , FAM_FIXED_ASSETS_ID
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
         values (GetNewId   -- FAL_ACI_TIME_HIST_DET_ID
               , aAciTimeHistId   -- FAL_ACI_TIME_HIST_ID
               , aEntryType
               , aEntrySign
               , vFinancialId
               , vDivisionId
               , vCpnId
               , vCdaId
               , vPfId
               , vPjId
               , vQtyId
               , vDocRecordId
               , vAccountInfo.FAM_FIXED_ASSETS_ID
               , aGoodId
               , vHrmPersonId
               , vAccountInfo.DEF_DIC_IMP_FREE1
               , vAccountInfo.DEF_DIC_IMP_FREE2
               , vAccountInfo.DEF_DIC_IMP_FREE3
               , vAccountInfo.DEF_DIC_IMP_FREE4
               , vAccountInfo.DEF_DIC_IMP_FREE5
               , vAccountInfo.DEF_NUMBER1
               , vAccountInfo.DEF_NUMBER2
               , vAccountInfo.DEF_NUMBER3
               , vAccountInfo.DEF_NUMBER4
               , vAccountInfo.DEF_NUMBER5
               , vAccountInfo.DEF_TEXT1
               , vAccountInfo.DEF_TEXT2
               , vAccountInfo.DEF_TEXT3
               , vAccountInfo.DEF_TEXT4
               , vAccountInfo.DEF_TEXT5
               , sysdate
               , PCS.PC_I_LIB_SESSION.USERINI
                );
  end CreateDetail;

  /**
   * procedure PrepareTimeEntry
   * Description
   *   Renseigne la table XXXXX à partir des données des enregistrements temporaires
   */
  procedure PrepareTimeEntry(
    aProgressOrigin   in FAL_ACI_TIME_ENTRY.C_PROGRESS_ORIGIN%type
  , aGalHoursId       in FAL_ACI_TIME_ENTRY.GAL_HOURS_ID%type
  , aLotProgressId    in FAL_ACI_TIME_ENTRY.FAL_LOT_PROGRESS_ID%type
  , aDocNumber        in FAL_ACI_TIME_HIST.DOC_NUMBER%type
  , aDescription      in FAL_ACI_TIME_ENTRY.TIE_DESCRIPTION%type
  , aValueDate        in FAL_ACI_TIME_ENTRY.TIE_VALUE_DATE%type
  , aProgressDate     in FAL_ACI_TIME_ENTRY.TIE_PROGRESS_DATE%type
  , aAdditionvlAmount in FAL_ACI_TIME_ENTRY.TIE_ADDITIONAL_AMOUNT%type
  , aMachAdjTime      in FAL_ACI_TIME_ENTRY.TIE_MACH_ADJ_TIME%type
  , aMachWorkTime     in FAL_ACI_TIME_ENTRY.TIE_MACH_WORK_TIME%type
  , aMachRate         in FAL_ACI_TIME_ENTRY.TIE_MACH_RATE%type
  , aMachFacFloorId   in FAL_ACI_TIME_ENTRY.FAL_MACH_FAC_FLOOR_ID%type
  , aOperAdjTime      in FAL_ACI_TIME_ENTRY.TIE_OPER_ADJ_TIME%type
  , aOperWorkTime     in FAL_ACI_TIME_ENTRY.TIE_OPER_WORK_TIME%type
  , aOperRate         in FAL_ACI_TIME_ENTRY.TIE_OPER_RATE%type
  , aOperFacFloorId   in FAL_ACI_TIME_ENTRY.FAL_OPER_FAC_FLOOR_ID%type
  , aHrmPersonId      in GAL_HOURS.HRM_PERSON_ID%type
  , aProjectId        in GAL_HOURS.GAL_PROJECT_ID%type
  , aCostCenterId     in GAL_HOURS.GAL_COST_CENTER_ID%type
  , aLotId            in FAL_LOT_PROGRESS.FAL_LOT_ID%type
  , aGoodId           in FAL_LOT.GCO_GOOD_ID%type
  )
  is
    vAdjTimeOperAmount  FAL_ACI_TIME_HIST.TIH_ADJ_TIME_OPER_AMOUNT%type;
    vAdjTimeMachAmount  FAL_ACI_TIME_HIST.TIH_ADJ_TIME_MACH_AMOUNT%type;
    vWorkTimeOperAmount FAL_ACI_TIME_HIST.TIH_WORK_TIME_OPER_AMOUNT%type;
    vWorkTimeMachAmount FAL_ACI_TIME_HIST.TIH_WORK_TIME_MACH_AMOUNT%type;
    vAciTimeEntryId     FAL_ACI_TIME_HIST.FAL_ACI_TIME_HIST_ID%type;
  begin
    vAdjTimeOperAmount   := trunc(aOperAdjTime * aOperRate, 2);
    vAdjTimeMachAmount   := trunc(aMachAdjTime * aMachRate, 2);
    vWorkTimeOperAmount  := trunc(aOperWorkTime * aOperRate, 2);
    vWorkTimeMachAmount  := trunc(aMachWorkTime * aMachRate, 2);

    -- Insertion dans la table principale
    insert into FAL_ACI_TIME_HIST
                (FAL_ACI_TIME_HIST_ID
               , C_PROGRESS_ORIGIN
               , DOC_NUMBER
               , TIH_DESCRIPTION
               , TIH_VALUE_DATE
               , TIH_PROGRESS_DATE
               , TIH_ADJ_TIME_OPER_QTY
               , TIH_ADJ_TIME_OPER_RATE
               , TIH_ADJ_TIME_OPER_AMOUNT
               , TIH_ADJ_TIME_MACH_QTY
               , TIH_ADJ_TIME_MACH_RATE
               , TIH_ADJ_TIME_MACH_AMOUNT
               , TIH_WORK_TIME_OPER_QTY
               , TIH_WORK_TIME_OPER_RATE
               , TIH_WORK_TIME_OPER_AMOUNT
               , TIH_WORK_TIME_MACH_QTY
               , TIH_WORK_TIME_MACH_RATE
               , TIH_WORK_TIME_MACH_ADD_AMOUNT
               , TIH_WORK_TIME_MACH_AMOUNT
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId   --FAL_ACI_TIME_HIST_ID
               , aProgressOrigin
               , truncstr(aDocNumber, cMaxDocNumberLength)
               , nvl(aDescription, cDefaultDescr)
               , aValueDate
               , aProgressDate
               , aOperAdjTime
               , aOperRate
               , vAdjTimeOperAmount
               , aMachAdjTime
               , aMachRate
               , vAdjTimeMachAmount
               , aOperWorkTime
               , aOperRate
               , vWorkTimeOperAmount
               , aMachWorkTime
               , aMachRate
               , aAdditionvlAmount
               , vWorkTimeMachAmount
               , sysdate
               , PCS.PC_I_LIB_SESSION.USERINI
                )
      returning FAL_ACI_TIME_HIST_ID
           into vAciTimeEntryId;

    -- Mise à jour de l'ID sur la table d'où provient l'avancement
    case aProgressOrigin
      when poProduction then
        update FAL_LOT_PROGRESS
           set FAL_ACI_TIME_HIST_ID = vAciTimeEntryId
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_LOT_PROGRESS_ID = aLotProgressId;
      when poProject then
        update GAL_HOURS
           set FAL_ACI_TIME_HIST_ID = vAciTimeEntryId
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GAL_HOURS_ID = aGalHoursId;
    end case;

    -- Génération des détails
    --  POUR Chaque type d’heure > 0 FAIRE
    --     // Type = Regl. MO, Regl. MA
    --     //        Trav. MO, Trav. MA
    --     -Insérer détail historique crédit
    --     -Rechercher comptes défaut + appel méthodes de
    --      déplacement des comptes
    --     -Insérer détail historique débit
    --     -Rechercher comptes défaut + appel méthodes de
    --      déplacement des comptes
    if    aMachAdjTime <> 0
       or vAdjTimeMachAmount <> 0 then
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etMachAdj
                 , aEntrySign        => esCredit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aMachFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etMachAdj
                 , aEntrySign        => esDebit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aMachFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
    end if;

    if    aMachWorkTime <> 0
       or vWorkTimeMachAmount <> 0 then
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etMachWork
                 , aEntrySign        => esCredit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aMachFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etMachWork
                 , aEntrySign        => esDebit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aMachFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
    end if;

    if    aOperAdjTime <> 0
       or vAdjTimeOperAmount <> 0 then
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etOperAdj
                 , aEntrySign        => esCredit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aOperFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etOperAdj
                 , aEntrySign        => esDebit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aOperFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
    end if;

    if    aOperWorkTime <> 0
       or vWorkTimeOperAmount <> 0 then
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etOperWork
                 , aEntrySign        => esCredit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aOperFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
      CreateDetail(aAciTimeHistId    => vAciTimeEntryId
                 , aEntryType        => etOperWork
                 , aEntrySign        => esDebit
                 , aValueDate        => aValueDate
                 , aProgressOrigin   => aProgressOrigin
                 , aLotProgressId    => aLotProgressId
                 , aGalHoursId       => aGalHoursId
                 , aFactoryFloorId   => aOperFacFloorId
                 , aCostCenterId     => aCostCenterId
                 , aProjectId        => aProjectId
                 , aHrmPersonId      => aHrmPersonId
                 , aLotId            => aLotId
                 , aGoodId           => aGoodId
                  );
    end if;
  end PrepareTimeEntry;

  /**
  * procedure ProcessTimeEntries
  * Description
  *   Impute les avancements de lots et heures affaire à partir des données des enregistrements temporaires
  */
  procedure ProcessTimeEntries(
    aTIE_GLOBAL_BEFORE_PROC in     varchar2 default null
  , aTIE_DETAIL_BEFORE_PROC in     varchar2 default null
  , aTIE_DETAIL_AFTER_PROC  in     varchar2 default null
  , aSuccessfulCount        out    integer
  , aTotalCount             out    integer
  )
  is
    cursor crTimeEntries
    is
      select   TIE.FAL_ACI_TIME_ENTRY_ID
             , TIE.C_PROGRESS_ORIGIN
             , TIE.GAL_HOURS_ID
             , TIE.FAL_LOT_PROGRESS_ID
             , LOT.LOT_REFCOMPL DOC_NUMBER
             , TIE.TIE_DESCRIPTION
             , TIE.TIE_VALUE_DATE
             , TIE.TIE_PROGRESS_DATE
             , TIE.TIE_ADDITIONAL_AMOUNT
             , TIE.TIE_MACH_ADJ_TIME
             , TIE.TIE_MACH_WORK_TIME
             , TIE.TIE_MACH_RATE
             , TIE.FAL_MACH_FAC_FLOOR_ID
             , TIE.TIE_OPER_ADJ_TIME
             , TIE.TIE_OPER_WORK_TIME
             , TIE.TIE_OPER_RATE
             , TIE.FAL_OPER_FAC_FLOOR_ID
             , HOU.HRM_PERSON_ID
             , HOU.GAL_PROJECT_ID
             , HOU.GAL_TASK_ID
             , HOU.GAL_TASK_LINK_ID
             , HOU.GAL_COST_CENTER_ID
             , FLP.DIC_OPERATOR_ID
             , FLP.FAL_LOT_ID
             , FLP.FAL_SCHEDULE_STEP_ID FAL_TASK_LINK_ID
             , LOT.GCO_GOOD_ID
          from FAL_ACI_TIME_ENTRY TIE
             , GAL_HOURS HOU
             , FAL_LOT_PROGRESS FLP
             , FAL_LOT LOT
         where TIE.TIE_SELECTION = 1
           and TIE.C_TIE_STATUS = tsToProcess
           and HOU.GAL_HOURS_ID(+) = TIE.GAL_HOURS_ID
           and FLP.FAL_LOT_PROGRESS_ID(+) = TIE.FAL_LOT_PROGRESS_ID
           and LOT.FAL_LOT_ID(+) = FLP.FAL_LOT_ID
      order by TIE.TIE_VALUE_DATE
             , TIE.FAL_ACI_TIME_ENTRY_ID;

    type TTimeEntries is table of crTimeEntries%rowtype;

    vTimeEntries            TTimeEntries;
    cBulkLimit     constant number                      := 10000;
    vIndex                  integer;

    cursor crLotProgressLock(aFAL_LOT_PROGRESS_ID in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type)
    is
      select     FLP.FAL_LOT_PROGRESS_ID
               , FLP.FAL_ACI_TIME_HIST_ID
            from FAL_LOT_PROGRESS FLP
           where FLP.FAL_LOT_PROGRESS_ID = aFAL_LOT_PROGRESS_ID
      for update nowait;

    cursor crGalHourLock(aGAL_HOURS_ID in GAL_HOURS.GAL_HOURS_ID%type)
    is
      select     HOU.GAL_HOURS_ID
               , HOU.FAL_ACI_TIME_HIST_ID
            from GAL_HOURS HOU
           where HOU.GAL_HOURS_ID = aGAL_HOURS_ID
      for update nowait;

    tplLotProgressLock      crLotProgressLock%rowtype;
    tplGalHourLock          crGalHourLock%rowtype;
    vTIE_GLOBAL_BEFORE_PROC varchar2(255);
    vTIE_DETAIL_BEFORE_PROC varchar2(255);
    vTIE_DETAIL_AFTER_PROC  varchar2(255);
    vProcResult             integer                     := 1;
    vReturnCompoIsScrap     integer(1);
    vSqlMsg                 varchar2(4000);
  begin
    -- Recherche des procédures stockées si elles n'ont pas été passées en pramètre
    vTIE_GLOBAL_BEFORE_PROC  := nvl(aTIE_GLOBAL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_TIE_GLOBAL_PROC') );
    vTIE_DETAIL_BEFORE_PROC  := nvl(aTIE_DETAIL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_TIE_DETAIL_BEFORE_PROC') );
    vTIE_DETAIL_AFTER_PROC   := nvl(aTIE_DETAIL_AFTER_PROC, PCS.PC_CONFIG.GetConfig('FAL_TIE_DETAIL_AFTER_PROC') );
    -- Iinitialisation des compteurs
    aSuccessfulCount         := 0;
    aTotalCount              := 0;

    open crTimeEntries;

    fetch crTimeEntries
    bulk collect into vTimeEntries limit cBulkLimit;

    -- Vérouillages de tous les avancements lot et heures à l'affaire
    while vTimeEntries.count > 0 loop
      for vIndex in vTimeEntries.first .. vTimeEntries.last loop
        -- Verrouillage de l'avancement lot ou de l'heure affaire
        begin
          if vTimeEntries(vIndex).FAL_LOT_PROGRESS_ID is not null then
            open crLotProgressLock(vTimeEntries(vIndex).FAL_LOT_PROGRESS_ID);

            close crLotProgressLock;
          elsif vTimeEntries(vIndex).GAL_HOURS_ID is not null then
            open crGalHourLock(vTimeEntries(vIndex).GAL_HOURS_ID);

            close crGalHourLock;
          end if;
        exception
          when others then
            null;
        end;
      end loop;

      fetch crTimeEntries
      bulk collect into vTimeEntries limit cBulkLimit;
    end loop;

    close crTimeEntries;

    -- Execution de la procédure stockée globale
    if vTIE_GLOBAL_BEFORE_PROC is not null then
      begin
        execute immediate 'begin :Result :=  ' || vTIE_GLOBAL_BEFORE_PROC || '; end;'
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
              chr(13) ||
              chr(10) ||
              DBMS_UTILITY.FORMAT_ERROR_STACK ||
              DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          end;
      end;
    end if;

    if vSqlMsg is not null then
      -- Abandon du traitement pour tous les enregistrements sélectionnés
      -- Supression des résultats des tentatives d'imputations précédentes
      delete from FAL_ACI_TIME_ENTRY
            where (   GAL_HOURS_ID in(select GAL_HOURS_ID
                                        from FAL_ACI_TIME_ENTRY
                                       where TIE_SELECTION = 1
                                         and C_TIE_STATUS = tsToProcess)
                   or FAL_LOT_PROGRESS_ID in(select FAL_LOT_PROGRESS_ID
                                               from FAL_ACI_TIME_ENTRY
                                              where TIE_SELECTION = 1
                                                and C_TIE_STATUS = tsToProcess)
                  )
              and FAL_ACI_TIME_ENTRY_ID not in(select FAL_ACI_TIME_ENTRY_ID
                                                 from FAL_ACI_TIME_ENTRY
                                                where TIE_SELECTION = 1
                                                  and C_TIE_STATUS = tsToProcess);

      -- Mise à jour des statuts et des détails de l'abandon dans la table temporaire
      update FAL_ACI_TIME_ENTRY
         set TIE_SELECTION = 0
           , C_TIE_STATUS = tsProcessAborted
           , TIE_ERROR_MESSAGE = vSqlMsg
       where TIE_SELECTION = 1
         and C_TIE_STATUS = tsToProcess;
    else
      open crTimeEntries;

      fetch crTimeEntries
      bulk collect into vTimeEntries limit cBulkLimit;

      -- Pour chaque élément sélectionné de la table temporaire
      while vTimeEntries.count > 0 loop
        for vIndex in vTimeEntries.first .. vTimeEntries.last loop
          begin
            -- Incrémentation du compteur total
            aTotalCount  := aTotalCount + 1;

            -- Supression des résultats des tentatives d'imputations précédentes
            delete from FAL_ACI_TIME_ENTRY
                  where (   FAL_LOT_PROGRESS_ID = vTimeEntries(vIndex).FAL_LOT_PROGRESS_ID
                         or GAL_HOURS_ID = vTimeEntries(vIndex).GAL_HOURS_ID)
                    and FAL_ACI_TIME_ENTRY_ID <> vTimeEntries(vIndex).FAL_ACI_TIME_ENTRY_ID;

            savepoint SP_BeforeProcessTimeEntry;

            -- Verrouillage de l'avancement lot ou de l'heure affaire
            begin
              if vTimeEntries(vIndex).FAL_LOT_PROGRESS_ID is not null then
                open crLotProgressLock(vTimeEntries(vIndex).FAL_LOT_PROGRESS_ID);

                fetch crLotProgressLock
                 into tplLotProgressLock;

                if tplLotProgressLock.FAL_ACI_TIME_HIST_ID is not null then
                  vSqlMsg  := PCS.PC_FUNCTIONS.TranslateWord('L''avancement a été traité par un autre utilisateur.');
                end if;
              elsif vTimeEntries(vIndex).GAL_HOURS_ID is not null then
                open crGalHourLock(vTimeEntries(vIndex).GAL_HOURS_ID);

                fetch crGalHourLock
                 into tplGalHourLock;

                if tplGalHourLock.FAL_ACI_TIME_HIST_ID is not null then
                  vSqlMsg  := PCS.PC_FUNCTIONS.TranslateWord('L''avancement a été traité par un autre utilisateur.');
                end if;
              end if;
            exception
              when others then
                begin
                  case sqlcode
                    when -54 then
                      vSqlMsg  := PCS.PC_FUNCTIONS.TranslateWord('L''avancement est cours de modification par un autre utilisateur.');
                    else
                      vSqlMsg  :=
                        PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement :') ||
                        chr(13) ||
                        chr(10) ||
                        DBMS_UTILITY.FORMAT_ERROR_STACK ||
                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                  end case;
                end;
            end;

            -- Execution de la procédure stockée de pré-traitement
            if     vSqlMsg is null
               and vTIE_DETAIL_BEFORE_PROC is not null then
              begin
                execute immediate 'begin :Result :=  ' || vTIE_DETAIL_BEFORE_PROC || '(:FAL_ACI_TIME_ENTRY_ID); end;'
                            using out vProcResult, in vTimeEntries(vIndex).FAL_ACI_TIME_ENTRY_ID;

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
                      chr(13) ||
                      chr(10) ||
                      DBMS_UTILITY.FORMAT_ERROR_STACK ||
                      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                  end;
              end;
            end if;

            if vSqlMsg is null then
              -- Imputation de l'avancement de lot ou heure affaire
              PrepareTimeEntry(aProgressOrigin     => vTimeEntries(vIndex).C_PROGRESS_ORIGIN
                             , aGalHoursId         => vTimeEntries(vIndex).GAL_HOURS_ID
                             , aLotProgressId      => vTimeEntries(vIndex).FAL_LOT_PROGRESS_ID
                             , aDocNumber          => vTimeEntries(vIndex).DOC_NUMBER
                             , aDescription        => vTimeEntries(vIndex).TIE_DESCRIPTION
                             , aValueDate          => vTimeEntries(vIndex).TIE_VALUE_DATE
                             , aProgressDate       => vTimeEntries(vIndex).TIE_PROGRESS_DATE
                             , aAdditionvlAmount   => vTimeEntries(vIndex).TIE_ADDITIONAL_AMOUNT
                             , aMachAdjTime        => vTimeEntries(vIndex).TIE_MACH_ADJ_TIME
                             , aMachWorkTime       => vTimeEntries(vIndex).TIE_MACH_WORK_TIME
                             , aMachRate           => vTimeEntries(vIndex).TIE_MACH_RATE
                             , aMachFacFloorId     => vTimeEntries(vIndex).FAL_MACH_FAC_FLOOR_ID
                             , aOperAdjTime        => vTimeEntries(vIndex).TIE_OPER_ADJ_TIME
                             , aOperWorkTime       => vTimeEntries(vIndex).TIE_OPER_WORK_TIME
                             , aOperRate           => vTimeEntries(vIndex).TIE_OPER_RATE
                             , aOperFacFloorId     => vTimeEntries(vIndex).FAL_OPER_FAC_FLOOR_ID
                             , aHrmPersonId        => vTimeEntries(vIndex).HRM_PERSON_ID
                             , aProjectId          => vTimeEntries(vIndex).GAL_PROJECT_ID
                             , aCostCenterId       => vTimeEntries(vIndex).GAL_COST_CENTER_ID
                             , aLotId              => vTimeEntries(vIndex).FAL_LOT_ID
                             , aGoodId             => vTimeEntries(vIndex).GCO_GOOD_ID
                              );
            end if;
          exception
            when others then
              -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
              vSqlMsg  :=
                PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement :') ||
                chr(13) ||
                chr(10) ||
                DBMS_UTILITY.FORMAT_ERROR_STACK ||
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          end;

          if vSqlMsg is null then
            begin
              -- Execution de la procédure stockée de post-traitement
              if vTIE_DETAIL_AFTER_PROC is not null then
                execute immediate 'begin :Result :=  ' || vTIE_DETAIL_AFTER_PROC || '(:FAL_ACI_TIME_ENTRY_ID); end;'
                            using out vProcResult, in vTimeEntries(vIndex).FAL_ACI_TIME_ENTRY_ID;

                if vProcResult < 1 then
                  vSqlMsg  :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a signvlé un problème. Valeur retournée') ||
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
                    chr(13) ||
                    chr(10) ||
                    DBMS_UTILITY.FORMAT_ERROR_STACK ||
                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                end;
            end;
          end if;

          -- Fermeture du curseur de l'avancement lot ou de l'heure affaire
          if crLotProgressLock%isopen then
            close crLotProgressLock;
          end if;

          if crGalHourLock%isopen then
            close crGalHourLock;
          end if;

          -- Annulation du traitement de l'imputation en cours s'il y a eu le moindre problème
          if vSqlMsg is not null then
            rollback to savepoint SP_BeforeProcessTimeEntry;
          end if;

          if vSqlMsg is null then
            -- Mise à jour du statut dans la table temporaire
            update FAL_ACI_TIME_ENTRY
               set TIE_SELECTION = 0
                 , C_TIE_STATUS = tsProcessed
                 , TIE_ERROR_MESSAGE = null
             where FAL_ACI_TIME_ENTRY_ID = vTimeEntries(vIndex).FAL_ACI_TIME_ENTRY_ID;

            -- Incrémentation du compteur d'imputations terminées sans erreur
            aSuccessfulCount  := aSuccessfulCount + 1;
          else
            -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
            update FAL_ACI_TIME_ENTRY
               set TIE_SELECTION = 0
                 , C_TIE_STATUS = tsProcessError
                 , TIE_ERROR_MESSAGE = vSqlMsg
             where FAL_ACI_TIME_ENTRY_ID = vTimeEntries(vIndex).FAL_ACI_TIME_ENTRY_ID;

            -- Remise à zero des erreurs pour l'enregistrement suivant
            vSqlMsg  := null;
          end if;
        end loop;

        fetch crTimeEntries
        bulk collect into vTimeEntries limit cBulkLimit;
      end loop;

      close crTimeEntries;

      -- Appel de la procédure de traitement ACI
      ProcessAciTimeEntries;
    end if;
  end ProcessTimeEntries;

  /**
   * procedure ProcessAciTimeEntries
   * Description
   *   Impute les avancements de lots et heures affaire à partir de l'historique
   */
  procedure ProcessAciTimeEntries
  is
    cursor crAciTimeEntries
    is
      select   TIH.FAL_ACI_TIME_HIST_ID
             , TIH.C_PROGRESS_ORIGIN
             , TIH.TIH_DESCRIPTION
             , TIH.TIH_VALUE_DATE
             , TIH.TIH_PROGRESS_DATE
             , TIH.TIH_ADJ_TIME_OPER_QTY
             , TIH.TIH_ADJ_TIME_OPER_RATE
             , TIH.TIH_ADJ_TIME_OPER_AMOUNT
             , TIH.TIH_ADJ_TIME_MACH_QTY
             , TIH.TIH_ADJ_TIME_MACH_RATE
             , TIH.TIH_ADJ_TIME_MACH_AMOUNT
             , TIH.TIH_WORK_TIME_OPER_QTY
             , TIH.TIH_WORK_TIME_OPER_RATE
             , TIH.TIH_WORK_TIME_OPER_AMOUNT
             , TIH.TIH_WORK_TIME_MACH_QTY
             , TIH.TIH_WORK_TIME_MACH_RATE
             , TIH.TIH_WORK_TIME_MACH_ADD_AMOUNT
             , TIH.TIH_WORK_TIME_MACH_AMOUNT
          from FAL_ACI_TIME_HIST TIH
         where TIH.TIH_ENTERED_INTO_WIP = 0
           and TIH.TIH_ENTERED_INTO_ACI = 1
      order by TIH.TIH_VALUE_DATE
             , TIH.FAL_ACI_TIME_HIST_ID;

    type TAciTimeEntries is table of crAciTimeEntries%rowtype;

    vAciTimeEntries     TAciTimeEntries;
    cBulkLimit constant number          := 10000;
    vIndex              integer;
  begin
    -- Intégration des données en ACI selon les règles de regroupement, etc.
    -- Mise à jour de TIH_ENTERED_INTO_ACI et, sur les détails, de ACI_DOCUMENT_ID.
    ACI_FAL_TIME.IntegrateFAL_GALTime;

    -- Intégration des données dans les en-cours si on utilise la compta industrielle
    -- Mise à jour de TIH_ENTERED_INTO_WIP.
    if PCS.PC_CONFIG.GetConfig('FAL_USE_ACCOUNTING') in('1', '2') then
      open crAciTimeEntries;

      fetch crAciTimeEntries
      bulk collect into vAciTimeEntries limit cBulkLimit;

      -- Pour chaque élément sélectionné de la table temporaire
      while vAciTimeEntries.count > 0 loop
        for vIndex in vAciTimeEntries.first .. vAciTimeEntries.last loop
          -- Mise à jour des éléments de coût Machine et main d'oeuvre.
          FAL_ACCOUNTING_FUNCTIONS.InsertCurrentWorkElementCost(aFAL_ACI_TIME_HIST_ID => vAciTimeEntries(vindex).FAL_ACI_TIME_HIST_ID);
        end loop;

        fetch crAciTimeEntries
        bulk collect into vAciTimeEntries limit cBulkLimit;
      end loop;

      close crAciTimeEntries;
    end if;
  end;

  /**
   * procedure DeleteTIEItems
   * Description
   *   Supprime les enregistrements temporaires déterminés par les paramètres
   */
  procedure DeleteTIEItems(aC_TIE_STATUS in FAL_ACI_TIME_ENTRY.C_TIE_STATUS%type, aOnlySelected in integer default 0)
  is
  begin
    -- Suppression des enregistrements séléctionnés du statut précisé
    delete from FAL_ACI_TIME_ENTRY
          where C_TIE_STATUS = aC_TIE_STATUS
            and (   aOnlySelected = 0
                 or TIE_SELECTION = 1);
  end DeleteTIEItems;

  /**
   * function GetTIEProfileValues
   * Description
   *   Extrait les valeurs des options d'un profil xml.
   */
  function GetTIEProfileValues(aXmlProfile xmltype)
    return TTIEOptions
  is
    vOptions TTIEOptions;
  begin
    begin
      -- Initialiser les valeurs du record sortant avec les valeurs stockées dans le xml du profil
      select extractvalue(aXmlProfile, '//TIE_MODE')
           , extractvalue(aXmlProfile, '//TIE_GLOBAL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//TIE_DETAIL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//TIE_DETAIL_AFTER_PROC')
           , extractvalue(aXmlProfile, '//TIE_SELECTION')
           , extractvalue(aXmlProfile, '//TIE_DATE_UNIT')
           , extractvalue(aXmlProfile, '//TIE_INCL_BATCH_PROGR')
           , extractvalue(aXmlProfile, '//TIE_PRODUCT_FROM')
           , extractvalue(aXmlProfile, '//TIE_PRODUCT_TO')
           , extractvalue(aXmlProfile, '//TIE_GOOD_CATEGORY_FROM')
           , extractvalue(aXmlProfile, '//TIE_GOOD_CATEGORY_TO')
           , extractvalue(aXmlProfile, '//TIE_GOOD_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//TIE_GOOD_FAMILY_TO')
           , extractvalue(aXmlProfile, '//TIE_ACCOUNTABLE_GROUP_FROM')
           , extractvalue(aXmlProfile, '//TIE_ACCOUNTABLE_GROUP_TO')
           , extractvalue(aXmlProfile, '//TIE_GOOD_LINE_FROM')
           , extractvalue(aXmlProfile, '//TIE_GOOD_LINE_TO')
           , extractvalue(aXmlProfile, '//TIE_GOOD_GROUP_FROM')
           , extractvalue(aXmlProfile, '//TIE_GOOD_GROUP_TO')
           , extractvalue(aXmlProfile, '//TIE_GOOD_MODEL_FROM')
           , extractvalue(aXmlProfile, '//TIE_GOOD_MODEL_TO')
           , extractvalue(aXmlProfile, '//TIE_JOB_PROGRAM_FROM')
           , extractvalue(aXmlProfile, '//TIE_JOB_PROGRAM_TO')
           , extractvalue(aXmlProfile, '//TIE_ORDER_FROM')
           , extractvalue(aXmlProfile, '//TIE_ORDER_TO')
           , extractvalue(aXmlProfile, '//TIE_C_PRIORITY_FROM')
           , extractvalue(aXmlProfile, '//TIE_C_PRIORITY_TO')
           , extractvalue(aXmlProfile, '//TIE_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//TIE_FAMILY_TO')
           , extractvalue(aXmlProfile, '//TIE_RECORD_FROM')
           , extractvalue(aXmlProfile, '//TIE_RECORD_TO')
           , extractvalue(aXmlProfile, '//TIE_OPERATOR_FROM')
           , extractvalue(aXmlProfile, '//TIE_OPERATOR_TO')
           , extractvalue(aXmlProfile, '//TIE_FLP_FACTORY_FLOOR_FROM')
           , extractvalue(aXmlProfile, '//TIE_FLP_FACTORY_FLOOR_TO')
           , extractvalue(aXmlProfile, '//TIE_INCL_GAL_HOURS')
           , extractvalue(aXmlProfile, '//TIE_GAL_PROJECT_FROM')
           , extractvalue(aXmlProfile, '//TIE_GAL_PROJECT_TO')
           , extractvalue(aXmlProfile, '//TIE_GAL_PRJ_CATEGORY_FROM')
           , extractvalue(aXmlProfile, '//TIE_GAL_PRJ_CATEGORY_TO')
           , extractvalue(aXmlProfile, '//TIE_EMPLOYEE_FROM')
           , extractvalue(aXmlProfile, '//TIE_EMPLOYEE_TO')
           , extractvalue(aXmlProfile, '//TIE_GAL_TASK_FROM')
           , extractvalue(aXmlProfile, '//TIE_GAL_TASK_TO')
           , extractvalue(aXmlProfile, '//TIE_GAL_FACTORY_FLOOR_FROM')
           , extractvalue(aXmlProfile, '//TIE_GAL_FACTORY_FLOOR_TO')
           , extractvalue(aXmlProfile, '//TIE_GAL_BUDGET_FROM')
           , extractvalue(aXmlProfile, '//TIE_GAL_BUDGET_TO')
           , extractvalue(aXmlProfile, '//TIE_GAL_HOUR_CODE_IND_FROM')
           , extractvalue(aXmlProfile, '//TIE_GAL_HOUR_CODE_IND_TO')
        into vOptions
        from dual;

      null;
    exception
      when others then
        raise_application_error(-20801, PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant l''extraction des valeurs du profil!') );
    end;

    return vOptions;
  end GetTIEProfileValues;

  /**
   * procedure ProcessBatch
   * Description
   *   Procédure de remontée en ACI des heures pour un unique lot de fabrication
   * @version 2003
   * @author ECA 23.07.2008
   * @lastUpdate SMA 06.2012
   * @public
   * @param  aFAL_LOT_ID : lot de fabrication
   * @param  aErrorMsg : Message d'erreur eventuel.
   */
  procedure ProcessBatch(aFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%type, aErrorMsg out integer)
  is
    vSuccessfulCount integer;
    vTotalCount      integer;
  begin
    -- Sélection de l'of
    SelectBatch(aFAL_LOT_ID);
    -- sélection de tous les avancements non encore imputés
    SelectProgresses(null, null, null, null);
    -- Génération des enregistrements temporaires
    GenerateTimeEntries(aDefaultSelection => 1);
    -- imputation des avancements
    ProcessTimeEntries(aSuccessfulCount => vSuccessfulCount, aTotalCount => vTotalCount);

    if vSuccessfulCount <> vTotalCount then
      aErrorMsg  := FAL_SUIVI_OPERATION.faErrorWithACI;
    else
      aErrorMsg  := FAL_SUIVI_OPERATION.faNoError;
    end if;

    -- Effacer les informations de la table COM_LIST_ID_TEMP
    COM_I_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_LOT_ID');
    COM_I_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_LOT_PROGRESS_ID');
  end;
end FAL_ACI_TIME_ENTRY_FCT;
