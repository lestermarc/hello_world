--------------------------------------------------------
--  DDL for Package Body FAM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAM_FUNCTIONS" 
is
  gUserIni PCS.PC_USER.USE_INI%type;

-----------------------------
  procedure GetNumberMethodInfo(
    aFAM_FIXED_ASSETS_CATEG_ID in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  , aFAM_NUMBER_METHOD_ID      in out FAM_NUMBER_METHOD.FAM_NUMBER_METHOD_ID%type
  , aFNM_LAST_NUMBER           in out FAM_NUMBER_METHOD.FNM_LAST_NUMBER%type
  , aC_NUMBER_TYPE             out    ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type
  , aDNM_PREFIX                out    ACJ_NUMBER_METHOD.DNM_PREFIX%type
  , aDNM_SUFFIX                out    ACJ_NUMBER_METHOD.DNM_SUFFIX%type
  , aDNM_INCREMENT             out    ACJ_NUMBER_METHOD.DNM_INCREMENT%type
  , aDNM_FREE_MANAGEMENT       out    ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type
  , aPicPrefix                 out    ACS_PICTURE.PIC_PICTURE%type
  , aPicNumber                 out    ACS_PICTURE.PIC_PICTURE%type
  , aPicSuffix                 out    ACS_PICTURE.PIC_PICTURE%type
  )
  is
  begin
    aFAM_NUMBER_METHOD_ID  := null;

    select min(FAM_NUMBER_METHOD_ID)
      into aFAM_NUMBER_METHOD_ID
      from FAM_FIXED_ASSETS_CATEG
     where FAM_FIXED_ASSETS_CATEG_ID = aFAM_FIXED_ASSETS_CATEG_ID;

    if aFAM_NUMBER_METHOD_ID is not null then
      select FNM_LAST_NUMBER
           , C_NUMBER_TYPE
           , DNM_PREFIX
           , DNM_SUFFIX
           , DNM_INCREMENT
           , DNM_FREE_MANAGEMENT
           , PIP.PIC_PICTURE
           , PIN.PIC_PICTURE
           , PIS.PIC_PICTURE
        into aFNM_LAST_NUMBER
           , aC_NUMBER_TYPE
           , aDNM_PREFIX
           , aDNM_SUFFIX
           , aDNM_INCREMENT
           , aDNM_FREE_MANAGEMENT
           , aPicPrefix
           , aPicNumber
           , aPicSuffix
        from ACS_PICTURE PIS
           , ACS_PICTURE PIN
           , ACS_PICTURE PIP
           , ACJ_NUMBER_METHOD ACJ
           , FAM_NUMBER_METHOD FAM
       where FAM_NUMBER_METHOD_ID = aFAM_NUMBER_METHOD_ID
         and FAM.ACJ_NUMBER_METHOD_ID = ACJ.ACJ_NUMBER_METHOD_ID
         and ACJ.ACS_PIC_PREFIX_ID = PIP.ACS_PICTURE_ID(+)
         and ACJ.ACS_PIC_NUMBER_ID = PIN.ACS_PICTURE_ID(+)
         and ACJ.ACS_PIC_SUFFIX_ID = PIS.ACS_PICTURE_ID(+);

      if aFNM_LAST_NUMBER is null then
        aFNM_LAST_NUMBER  := 0;
      end if;
    end if;
  end GetNumberMethodInfo;

  /**
  * Description  Détermine le numéro d'une immobilisation, sur la base des méthodes de numérotation pré-définies
  */
  procedure GetAssetsNumber(
    aFAM_FIXED_ASSETS_CATEG_ID in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  , aFIX_NUMBER                in out FAM_FIXED_ASSETS.FIX_NUMBER%type
  )
  is
    pragma autonomous_transaction;
    FAMMethodId    FAM_NUMBER_METHOD.FAM_NUMBER_METHOD_ID%type;
    FreeNumberId   FAM_FREE_NUMBER.FAM_FREE_NUMBER_ID%type;
    LastNumber     FAM_NUMBER_METHOD.FNM_LAST_NUMBER%type;
    NumberType     ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
    Prefix         ACJ_NUMBER_METHOD.DNM_PREFIX%type;
    Suffix         ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
    increment      ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
    FreeManagement ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
    FreeNumber     FAM_FREE_NUMBER.FNU_NUMBER%type;
    PicPrefix      ACS_PICTURE.PIC_PICTURE%type;
    PicNumber      ACS_PICTURE.PIC_PICTURE%type;
    PicSuffix      ACS_PICTURE.PIC_PICTURE%type;

    cursor FreeNumberCursor(aFAM_NUMBER_METHOD_ID FAM_NUMBER_METHOD.FAM_NUMBER_METHOD_ID%type)
    is
      select FAM_FREE_NUMBER_ID
           , FNU_NUMBER
        from FAM_FREE_NUMBER
       where FAM_NUMBER_METHOD_ID = aFAM_NUMBER_METHOD_ID
         and FNU_NUMBER = (select min(FNU_NUMBER)
                             from FAM_FREE_NUMBER
                            where FAM_NUMBER_METHOD_ID = aFAM_NUMBER_METHOD_ID);
  -----
  begin
    aFIX_NUMBER  := null;
    GetNumberMethodInfo(aFAM_FIXED_ASSETS_CATEG_ID
                      , FAMMethodId
                      , LastNumber
                      , NumberType
                      , Prefix
                      , Suffix
                      , increment
                      , FreeManagement
                      , PicPrefix
                      , PicNumber
                      , PicSuffix
                       );

    if FAMMethodId is not null then
      -- Récupération d'un numéro libre
      if FreeManagement = 1 then
        open FreeNumberCursor(FAMMethodId);

        fetch FreeNumberCursor
         into FreeNumberId
            , FreeNumber;

        close FreeNumberCursor;
      end if;

      aFIX_NUMBER  :=
        ACT_FUNCTIONS.DocNumber(null
                              ,   -- aACS_FINANCIAL_YEAR_ID
                                LastNumber
                              , NumberType
                              , Prefix
                              , Suffix
                              , increment
                              , FreeManagement
                              , FreeNumber
                              , PicPrefix
                              , PicNumber
                              , PicSuffix
                               );

      if aFIX_NUMBER is not null then
        if     FreeManagement = 1
           and FreeNumberId is not null then
          -- Elimination numéro libre réutilisé
          delete from FAM_FREE_NUMBER
                where FAM_FREE_NUMBER_ID = FreeNumberId;
        else
          -- Mise à jour dernier numéro utilisé
          update FAM_NUMBER_METHOD
             set FNM_LAST_NUMBER = LastNumber + increment
           where FAM_NUMBER_METHOD_ID = FAMMethodId;
        end if;
      end if;
    end if;

    commit;
  end GetAssetsNumber;

  /**
  * Description  Indicates if numbering method of the given categories are identical or no
  **/
  function NumberingHasChanged(
    pPreviousCategId in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  , pCurrentCategId  in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  )
    return number
  is
    vResult          number(1);
    vPrevNumberingId FAM_FIXED_ASSETS_CATEG.FAM_NUMBER_METHOD_ID%type;
    vCurrNumberId    FAM_FIXED_ASSETS_CATEG.FAM_NUMBER_METHOD_ID%type;
  begin
    vResult  := 0;

    select max(PRE.FAM_NUMBER_METHOD_ID)
      into vPrevNumberingId
      from FAM_FIXED_ASSETS_CATEG PRE
     where PRE.FAM_FIXED_ASSETS_CATEG_ID = pPreviousCategId;

    select max(CUR.FAM_NUMBER_METHOD_ID)
      into vCurrNumberId
      from FAM_FIXED_ASSETS_CATEG CUR
     where CUR.FAM_FIXED_ASSETS_CATEG_ID = pCurrentCategId;

    if     (not vPrevNumberingId is null)
       and (not vCurrNumberId is null) then
      if vPrevNumberingId = vCurrNumberId then
        vResult  := 0;
      else
        vResult  := 1;
      end if;
    end if;

    return vResult;
  end NumberingHasChanged;

  /**
  * Description  Récupération d'un numéro libre, lors de la suppression d'une immobilisation ou l'abandon d'une saisie
  */
  procedure AddFreeNumber(
    aFAM_FIXED_ASSETS_CATEG_ID in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  , aFIX_NUMBER                in FAM_FIXED_ASSETS.FIX_NUMBER%type
  )
  is
    pragma autonomous_transaction;
    LastNumber     FAM_NUMBER_METHOD.FNM_LAST_NUMBER%type;
    FAMMethodId    FAM_NUMBER_METHOD.FAM_NUMBER_METHOD_ID%type;
    NumberType     ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
    Prefix         ACJ_NUMBER_METHOD.DNM_PREFIX%type;
    Suffix         ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
    increment      ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
    FreeManagement ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
    PicPrefix      ACS_PICTURE.PIC_PICTURE%type;
    PicNumber      ACS_PICTURE.PIC_PICTURE%type;
    PicSuffix      ACS_PICTURE.PIC_PICTURE%type;
  begin
    GetNumberMethodInfo(aFAM_FIXED_ASSETS_CATEG_ID
                      , FAMMethodId
                      , LastNumber
                      , NumberType
                      , Prefix
                      , Suffix
                      , increment
                      , FreeManagement
                      , PicPrefix
                      , PicNumber
                      , PicSuffix
                       );

    if FAMMethodId is not null then
      if FreeManagement = 1 then
        begin
          LastNumber  := to_number(substr(aFIX_NUMBER, nvl(length(Prefix), 0) + 1, length(PicNumber) ) );
        exception
          when value_error then
            LastNumber  := 0;
        end;

        if LastNumber > 0 then
          begin
            insert into FAM_FREE_NUMBER
                        (FAM_FREE_NUMBER_ID
                       , FAM_NUMBER_METHOD_ID
                       , FNU_NUMBER
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , FAMMethodId
                       , LastNumber
                       , sysdate
                       , gUserIni
                        );
          exception
            when dup_val_on_index then
              null;
          end;
        end if;
      end if;
    end if;

    commit;
  end AddFreeNumber;

  /**
  * Description  Indicates if document number can me chnaged manually(1) or no (0)
  **/
  function NumberLoadingAllowed(
    pFamCatalogueId in FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  , pFamJournalId   in FAM_DOCUMENT.FAM_JOURNAL_ID%type
  )
    return number
  is
    vResult          number(1);
    vFinancialYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    vYearId          ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    vMethodId        ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;
    vNumberType      ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
    vPrefix          ACJ_NUMBER_METHOD.DNM_PREFIX%type;
    vSuffix          ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
    vIncrement       ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
    vFreeManagement  ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
    vPicPrefix       ACS_PICTURE.PIC_PICTURE%type;
    vPicNumber       ACS_PICTURE.PIC_PICTURE%type;
    vPicSuffix       ACS_PICTURE.PIC_PICTURE%type;
  begin
    vResult  := 0;

    select max(ACS_FINANCIAL_YEAR_ID)
      into vFinancialYearId
      from FAM_JOURNAL
     where FAM_JOURNAL_ID = pFamJournalId;

    ACT_FUNCTIONS.GetNumberMethodInfo(pFamCatalogueId
                                    , vFinancialYearId
                                    , vYearId
                                    , vMethodId
                                    , vNumberType
                                    , vPrefix
                                    , vSuffix
                                    , vIncrement
                                    , vFreeManagement
                                    , vPicPrefix
                                    , vPicNumber
                                    , vPicSuffix
                                    , true
                                    , false
                                    , false
                                     );

    if vNumberType <> '3' then
      vResult  := 1;
    end if;
    return vResult;
  end NumberLoadingAllowed;

  /**
  * Description  Get document number incuded in the given journal
  **/
  procedure GetFamJournalDocNumber(
    pFamCatalogueId       in     FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  , pFamJournalId         in     FAM_DOCUMENT.FAM_JOURNAL_ID%type
  , pFamDocumentIntNumber in out FAM_DOCUMENT.FDO_INT_NUMBER%type
  , pNumberReadOnly       in out number
  )
  is
    vFinancialYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    pFamDocumentIntNumber  := null;

    select max(ACS_FINANCIAL_YEAR_ID)
      into vFinancialYearId
      from FAM_JOURNAL
     where FAM_JOURNAL_ID = pFamJournalId;

    if not vFinancialYearId is null then
      FAM_FUNCTIONS.GetFamDocNumber(pFamCatalogueId, vFinancialYearId, pFamDocumentIntNumber, pNumberReadOnly);
    end if;
  end GetFamJournalDocNumber;

  /**
  * Description  Détermine le numéro d'un document immobilisation, sur la base des méthodes de numérotation (ACJ) pré-définies
  */
  procedure GetFamDocNumber(
    aFAM_CATALOGUE_ID      in     FAM_CATALOGUE.FAM_CATALOGUE_ID%type
  , aACS_FINANCIAL_YEAR_ID in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aFDO_INT_NUMBER        in out FAM_DOCUMENT.FDO_INT_NUMBER%type
  , pNumberReadOnly        in out number
  )
  is
    pragma autonomous_transaction;
    LastNumber            ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type;
    YearId                ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    MethodId              ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;
    NumberType            ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
    Prefix                ACJ_NUMBER_METHOD.DNM_PREFIX%type;
    Suffix                ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
    increment             ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
    FreeManagement        ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
    PicPrefix             ACS_PICTURE.PIC_PICTURE%type;
    PicNumber             ACS_PICTURE.PIC_PICTURE%type;
    PicSuffix             ACS_PICTURE.PIC_PICTURE%type;
    intACJ_FREE_NUMBER_ID ACJ_FREE_NUMBER.ACJ_FREE_NUMBER_ID%type;
    FreeNumber            ACJ_FREE_NUMBER.FNU_NUMBER%type;

    cursor FREE_NUMBER(
      aACJ_NUMBER_METHOD_ID  ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type
    , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
    )
    is
      select ACJ_FREE_NUMBER_ID
           , FNU_NUMBER
        from ACJ_FREE_NUMBER
       where ACJ_NUMBER_METHOD_ID = aACJ_NUMBER_METHOD_ID
         and (   ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
              or (    ACS_FINANCIAL_YEAR_ID is null
                  and aACS_FINANCIAL_YEAR_ID is null)
             )
         and FNU_NUMBER =
               (select min(FNU_NUMBER)
                  from ACJ_FREE_NUMBER
                 where ACJ_NUMBER_METHOD_ID = aACJ_NUMBER_METHOD_ID
                   and (   ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                        or (    ACS_FINANCIAL_YEAR_ID is null
                            and aACS_FINANCIAL_YEAR_ID is null)
                       ) );
  begin
    pNumberReadOnly  := 0;
    ACT_FUNCTIONS.GetNumberMethodInfo(aFAM_CATALOGUE_ID
                                    , aACS_FINANCIAL_YEAR_ID
                                    , YearId
                                    , MethodId
                                    , NumberType
                                    , Prefix
                                    , Suffix
                                    , increment
                                    , FreeManagement
                                    , PicPrefix
                                    , PicNumber
                                    , PicSuffix
                                    , true
                                     );

    if MethodId is not null then
      -- Récupération d'un numéro libre
      if FreeManagement = 1 then
        open FREE_NUMBER(MethodId, YearId);

        fetch FREE_NUMBER
         into intACJ_FREE_NUMBER_ID
            , FreeNumber;

        close FREE_NUMBER;
      end if;

      -- Récupération du dernier numéro
      begin
        select NAP_LAST_NUMBER
          into LastNumber
          from ACJ_LAST_NUMBER
         where ACJ_NUMBER_METHOD_ID = MethodId
           and (   ACS_FINANCIAL_YEAR_ID = YearId
                or (    ACS_FINANCIAL_YEAR_ID is null
                    and YearId is null) );
      exception
        when no_data_found then
          LastNumber  := 0;

          insert into ACJ_LAST_NUMBER
                      (ACJ_LAST_NUMBER_ID
                     , ACJ_NUMBER_METHOD_ID
                     , ACS_FINANCIAL_YEAR_ID
                     , NAP_LAST_NUMBER
                      )
               values (INIT_ID_SEQ.nextval
                     , MethodId
                     , YearId
                     , 0
                      );
      end;

      aFDO_INT_NUMBER  :=
        ACT_FUNCTIONS.DocNumber(aACS_FINANCIAL_YEAR_ID
                              , LastNumber
                              , NumberType
                              , Prefix
                              , Suffix
                              , increment
                              , FreeManagement
                              , FreeNumber
                              , PicPrefix
                              , PicNumber
                              , PicSuffix
                               );

      if aFDO_INT_NUMBER is not null then
        if     FreeManagement = 1
           and intACJ_FREE_NUMBER_ID is not null then
          -- Elimination numéro libre réutilisé
          delete from ACJ_FREE_NUMBER
                where ACJ_FREE_NUMBER_ID = intACJ_FREE_NUMBER_ID;
        else
          -- Mise à jour dernier numéro utilisé
          update ACJ_LAST_NUMBER
             set NAP_LAST_NUMBER = LastNumber + increment
           where ACJ_NUMBER_METHOD_ID = MethodId
             and (   ACS_FINANCIAL_YEAR_ID = YearId
                  or (    ACS_FINANCIAL_YEAR_ID is null
                      and YearId is null) );
        end if;
      end if;

      if NumberType = '3' then
        pNumberReadOnly  := 1;
      end if;
    else
      aFDO_INT_NUMBER  := null;
    end if;

    commit;
  end GetFamDocNumber;

  /**
  * Description  Calcul de la somme des imputations  pour
  *              - une immobilsation
  *              - une immobilsation et ses composants
  *              - les immobilsatiosn d'une catégorie
  *              et ce pour
  *              - un exercice (ID exercice et 'période de' et 'période à')
  *              - une partie d'un exercice (ID exercice et 'période de' et ou 'période à')
  *              - Jusqu'à un exercice y compris (ID exercice et pas de 'période de' et pas de 'période à')
  */
  function StructureElementAmount(
    pSearchFilter        in number
  , pCumulFilter         in number
  , pFixedAssets_CategId in FAM_FIXED_ASSETS_CATEG.FAM_FIXED_ASSETS_CATEG_ID%type
  , pFixManagedValueId   in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pFixStructureId      in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
  , pFinYearId           in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pPerNumberFrom       in ACS_PERIOD.PER_NO_PERIOD%type default null
  , pPerNumberTo         in ACS_PERIOD.PER_NO_PERIOD%type default null
  , pFixedAssetsCategId  in FAM_FIXED_ASSETS_CATEG.FAM_FIXED_ASSETS_CATEG_ID%type default null
  )
    return FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type
  is
    vResult          FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;   /* Variable de r‚ception de la valeur de retour*/
    vFixedCompImpSum FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;   /* Variable de r‚ception des cumuls pour les composants de l'immob*/
  begin
    begin
      /*Initialisation des variables*/
      vResult           := 0;
      vFixedCompImpSum  := 0;

      /*Calcul du cumul pour l'immobilisation dans le cas de la recherchce pour immobilsation(0) ou immobilisation et composant(1)*/
      if    (pSearchFilter = 0)
         or (pSearchFilter = 1) then
        if pCumulFilter = 0 then   /*Cumul pour l'exercice donn‚*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vResult
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_ELEMENT_DETAIL DET
           where TOT.FAM_FIXED_ASSETS_ID = pFixedAssets_CategId
             and TOT.FAM_FIXED_ASSETS_CATEG_ID = nvl(pFixedAssetsCategId, TOT.FAM_FIXED_ASSETS_CATEG_ID)
             and TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and exists(
                   select 1
                     from ACS_PERIOD PERIOD
                    where PERIOD.ACS_FINANCIAL_YEAR_ID = pFinYearId
                      and PERIOD.PER_NO_PERIOD between nvl(pPerNUmberFrom, PERIOD.PER_NO_PERIOD)
                                                   and nvl(pPerNumberTo, PERIOD.PER_NO_PERIOD)
                      and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID);
        elsif pCumulFilter = 1 then   /*Cumul jusqu'… l'exercice donn‚ y compris*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vResult
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_ELEMENT_DETAIL DET
           where TOT.FAM_FIXED_ASSETS_ID = pFixedAssets_CategId
             and TOT.FAM_FIXED_ASSETS_CATEG_ID = nvl(pFixedAssetsCategId, TOT.FAM_FIXED_ASSETS_CATEG_ID)
             and TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and (   exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                     , ACS_FINANCIAL_YEAR YEAR_TO
                                 where YEAR_TO.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and year.FYE_NO_EXERCICE < YEAR_TO.FYE_NO_EXERCICE
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                  or exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                 where year.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and PERIOD.PER_NO_PERIOD <= nvl(pPerNumberTo, PERIOD.PER_NO_PERIOD)
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                 );
        elsif pCumulFilter = 2 then   /*Cumul jusqu'… l'exercice donn‚ non compris*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vResult
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_ELEMENT_DETAIL DET
           where TOT.FAM_FIXED_ASSETS_ID = pFixedAssets_CategId
             and TOT.FAM_FIXED_ASSETS_CATEG_ID = nvl(pFixedAssetsCategId, TOT.FAM_FIXED_ASSETS_CATEG_ID)
             and TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and (   exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                     , ACS_FINANCIAL_YEAR YEAR_TO
                                 where YEAR_TO.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and year.FYE_NO_EXERCICE < YEAR_TO.FYE_NO_EXERCICE
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                  or exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                 where year.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and PERIOD.PER_NO_PERIOD < nvl(pPerNumberFrom, 0)
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                 );
        end if;
      end if;

      /*Calcul du cumul pour les composants de l'immobilisation */
      if pSearchFilter = 1 then
        if pCumulFilter = 0 then   /*Cumul pour l'exercice donn‚*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vFixedCompImpSum
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_FIXED_ASSETS COMPONENT
               , FAM_ELEMENT_DETAIL DET
           where COMPONENT.FAM_FAM_FIXED_ASSETS_ID = pFixedAssets_CategId
             and TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and TOT.FAM_FIXED_ASSETS_ID = COMPONENT.FAM_FIXED_ASSETS_ID
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and exists(
                   select 1
                     from ACS_PERIOD PERIOD
                    where PERIOD.ACS_FINANCIAL_YEAR_ID = pFinYearId
                      and PERIOD.PER_NO_PERIOD between nvl(pPerNUmberFrom, PERIOD.PER_NO_PERIOD)
                                                   and nvl(pPerNumberTo, PERIOD.PER_NO_PERIOD)
                      and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID);
        elsif pCumulFilter = 1 then   /*Cumul jusqu'… l'exercice donn‚ y compris*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vFixedCompImpSum
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_FIXED_ASSETS COMPONENT
               , FAM_ELEMENT_DETAIL DET
           where TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and COMPONENT.FAM_FAM_FIXED_ASSETS_ID = pFixedAssets_CategId
             and TOT.FAM_FIXED_ASSETS_ID = COMPONENT.FAM_FIXED_ASSETS_ID
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and (   exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                     , ACS_FINANCIAL_YEAR YEAR_TO
                                 where YEAR_TO.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and year.FYE_NO_EXERCICE < YEAR_TO.FYE_NO_EXERCICE
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                  or exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                 where year.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and PERIOD.PER_NO_PERIOD <= nvl(pPerNumberTo, PERIOD.PER_NO_PERIOD)
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                 );
        elsif pCumulFilter = 2 then   /*Cumul jusqu'… l'exercice donn‚ non compris*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vFixedCompImpSum
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_FIXED_ASSETS COMPONENT
               , FAM_ELEMENT_DETAIL DET
           where TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and COMPONENT.FAM_FAM_FIXED_ASSETS_ID = pFixedAssets_CategId
             and TOT.FAM_FIXED_ASSETS_ID = COMPONENT.FAM_FIXED_ASSETS_ID
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and (   exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                     , ACS_FINANCIAL_YEAR YEAR_TO
                                 where YEAR_TO.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and year.FYE_NO_EXERCICE < YEAR_TO.FYE_NO_EXERCICE
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                  or exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                 where year.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and PERIOD.PER_NO_PERIOD < nvl(pPerNumberFrom, 0)
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                 );
        end if;

        vResult  := vResult + vFixedCompImpSum;   /* Cumul = Cumul de l'immob + cumul des composants*/
      end if;

      /*Calcul du cumul pour les immob. d'une cat‚gorie*/
      if pSearchFilter = 2 then
        if pCumulFilter = 0 then   /*Cumul pour l'exercice donn‚*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vResult
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_FIXED_ASSETS FIX
               , FAM_ELEMENT_DETAIL DET
           where FIX.FAM_FIXED_ASSETS_CATEG_ID = pFixedAssets_CategId
             and TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and TOT.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and exists(
                   select 1
                     from ACS_PERIOD PERIOD
                    where PERIOD.ACS_FINANCIAL_YEAR_ID = pFinYearId
                      and PERIOD.PER_NO_PERIOD between nvl(pPerNUmberFrom, PERIOD.PER_NO_PERIOD)
                                                   and nvl(pPerNumberTo, PERIOD.PER_NO_PERIOD)
                      and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID);
        elsif pCumulFilter = 1 then   /*Cumul jusqu'… l'exercice donn‚ y compris*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vResult
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_FIXED_ASSETS FIX
               , FAM_ELEMENT_DETAIL DET
           where FIX.FAM_FIXED_ASSETS_CATEG_ID = pFixedAssets_CategId
             and TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and TOT.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and (   exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                     , ACS_FINANCIAL_YEAR YEAR_TO
                                 where YEAR_TO.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and year.FYE_NO_EXERCICE < YEAR_TO.FYE_NO_EXERCICE
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                  or exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                 where year.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and PERIOD.PER_NO_PERIOD <=
                                                          decode(pPerNumberTo
                                                               , null, PERIOD.PER_NO_PERIOD
                                                               , pPerNumberTo
                                                                )
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                 );
        elsif pCumulFilter = 2 then   /*Cumul jusqu'‚ l'exercice donn‚ non compris*/
          select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
            into vResult
            from FAM_TOTAL_BY_PERIOD TOT
               , FAM_FIXED_ASSETS FIX
               , FAM_ELEMENT_DETAIL DET
           where FIX.FAM_FIXED_ASSETS_CATEG_ID = pFixedAssets_CategId
             and TOT.FAM_MANAGED_VALUE_ID = pFixManagedValueId
             and TOT.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
             and DET.FAM_STRUCTURE_ELEMENT_ID = pFixStructureId
             and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP
             and (   exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                     , ACS_FINANCIAL_YEAR YEAR_TO
                                 where YEAR_TO.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and year.FYE_NO_EXERCICE <= YEAR_TO.FYE_NO_EXERCICE
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                  or exists(
                       select 1
                         from ACS_PERIOD PERIOD
                        where exists(
                                select 1
                                  from ACS_FINANCIAL_YEAR year
                                 where year.ACS_FINANCIAL_YEAR_ID = pFinYearId
                                   and PERIOD.PER_NO_PERIOD < decode(pPerNumberFrom, null, 0, pPerNumberFrom)
                                   and PERIOD.ACS_FINANCIAL_YEAR_ID = year.ACS_FINANCIAL_YEAR_ID)
                          and TOT.ACS_PERIOD_ID = PERIOD.ACS_PERIOD_ID)
                 );
        end if;
      end if;
    exception
      when others then
        vResult  := 0;
    end;

    return vResult;
  end StructureElementAmount;

  /**
  * Description  Mise à jour des valeurs assurées se basant sur les indices
  */
  procedure UpdatePolicyPremium(
    pPolicyId             in FAM_INSURANCE_POLICY.FAM_INSURANCE_POLICY_ID%type
  , pUpdateFixDeclaredVal in number
  , pUpdatePolDeclaredVal in number
  , pUpdateFixPremiumVal  in number
  , pUpdatePolPremiumVal  in number
  , pDateRef              in FAM_INDEX_VALUE.IVA_INDEX_DATE%type
  , pIndexID              in FAM_INDEX.FAM_INDEX_ID%type
  , pCRoundType           in ACS_FINANCIAL_CURRENCY.C_ROUND_TYPE%type
  , pFinRoundedAmount     in ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type
  )
  is
    cursor InsurancePolicyCursor(pFAM_INSURANCE_POLICY_ID in FAM_INSURANCE_POLICY.FAM_INSURANCE_POLICY_ID%type)
    is
      select INS.FAM_INSURANCE_ID
           , INS.FAM_FIXED_ASSETS_ID
           , ASS.FIX_PURCHASE_DATE
           , INS.INS_EFFECTIVE_VALUE
           , POL.POL_INDEX
           , INS.INS_PREMIUM_RATE
           , INS.INS_DECLARED_VALUE
        from FAM_INSURANCE_POLICY POL
           , FAM_INSURANCE INS
           , FAM_FIXED_ASSETS ASS
       where POL.FAM_INSURANCE_POLICY_ID = pFAM_INSURANCE_POLICY_ID
         and INS.FAM_INSURANCE_POLICY_ID = POL.FAM_INSURANCE_POLICY_ID
         and ASS.FAM_FIXED_ASSETS_ID = INS.FAM_FIXED_ASSETS_ID;

    InsurancePolicy   InsurancePolicyCursor%rowtype;
    vNewFixDeclareVal FAM_INSURANCE.INS_DECLARED_VALUE%type;
    vNewPolDeclareVal FAM_INSURANCE_POLICY.POL_AMOUNT%type;
    vNewFixPremiumVal FAM_INSURANCE.INS_PREMIUM%type;
    vNewPolPremiumVal FAM_INSURANCE_POLICY.POL_PREMIUM%type;
    vPointInDate      FAM_INDEX_VALUE.IVA_POINT%type;
  begin
    open InsurancePolicyCursor(pPolicyId);

    fetch InsurancePolicyCursor
     into InsurancePolicy;

    while InsurancePolicyCursor%found loop
      /* Step 1 - Fixed assets assured value calculation */
      if pUpdateFixDeclaredVal = 1 then
        vPointInDate  := GetIndexPointInDate(InsurancePolicy.FIX_PURCHASE_DATE, pIndexID);

        if vPointInDate > 0 then
          vNewFixDeclareVal                   :=
                          (InsurancePolicy.INS_EFFECTIVE_VALUE / vPointInDate)
                          * GetIndexPointInDate(pDateRef, pIndexID);
          vNewFixDeclareVal                   :=
                                               ACS_FUNCTION.PcsRound(vNewFixDeclareVal, pCRoundType, pFinRoundedAmount);

          update FAM_INSURANCE
             set INS_DECLARED_VALUE = vNewFixDeclareVal
               , A_DATEMOD = sysdate
               , A_IDMOD = gUserIni
           where FAM_INSURANCE_ID = InsurancePolicy.FAM_INSURANCE_ID
             and FAM_FIXED_ASSETS_ID = InsurancePolicy.FAM_FIXED_ASSETS_ID;

          InsurancePolicy.INS_DECLARED_VALUE  := vNewFixDeclareVal;
        end if;
      end if;

      /* Step 2 - Fixed assets premium rate calculation */
      if pUpdateFixPremiumVal = 1 then
        if InsurancePolicy.INS_PREMIUM_RATE is not null then
          vNewFixPremiumVal  := (InsurancePolicy.INS_DECLARED_VALUE * InsurancePolicy.INS_PREMIUM_RATE) / 100;
        elsif InsurancePolicy.POL_INDEX is not null then
          vNewFixPremiumVal  := (InsurancePolicy.INS_DECLARED_VALUE * InsurancePolicy.POL_INDEX) / 100;
        end if;

        if    (InsurancePolicy.INS_PREMIUM_RATE is not null)
           or (InsurancePolicy.POL_INDEX is not null) then
          update FAM_INSURANCE
             set INS_PREMIUM = ACS_FUNCTION.PcsRound(vNewFixPremiumVal, pCRoundType, pFinRoundedAmount)
               , A_DATEMOD = sysdate
               , A_IDMOD = gUserIni
           where FAM_INSURANCE_ID = InsurancePolicy.FAM_INSURANCE_ID
             and FAM_FIXED_ASSETS_ID = InsurancePolicy.FAM_FIXED_ASSETS_ID;
        end if;
      end if;

      fetch InsurancePolicyCursor
       into InsurancePolicy;
    end loop;

    close InsurancePolicyCursor;

    /* Step 3 - Policy assured value calculation */
    if pUpdatePolDeclaredVal = 1 then
      select sum(INS.INS_DECLARED_VALUE)
        into vNewPolDeclareVal
        from FAM_INSURANCE INS
       where INS.FAM_INSURANCE_POLICY_ID = pPolicyId;

      update FAM_INSURANCE_POLICY
         set POL_AMOUNT = vNewPolDeclareVal
           , A_DATEMOD = sysdate
           , A_IDMOD = gUserIni
       where FAM_INSURANCE_POLICY_ID = pPolicyId;
    end if;

    /* Step 4 - Policy premium rate calculation */
    if pUpdatePolPremiumVal = 1 then
      select sum(INS.INS_PREMIUM)
        into vNewPolPremiumVal
        from FAM_INSURANCE INS
       where INS.FAM_INSURANCE_POLICY_ID = pPolicyId;

      update FAM_INSURANCE_POLICY
         set POL_PREMIUM = vNewPolPremiumVal
           , A_DATEMOD = sysdate
           , A_IDMOD = gUserIni
       where FAM_INSURANCE_POLICY_ID = pPolicyId;
    end if;
  end UpdatePolicyPremium;

  /**
  * Description  Recherche du nombre de point pour une date dans les indices
  */
  function GetIndexPointInDate(pDate in FAM_INDEX_VALUE.IVA_INDEX_DATE%type, pIndexId in FAM_INDEX.FAM_INDEX_ID%type)
    return FAM_INDEX_VALUE.IVA_POINT%type
  is
    result FAM_INDEX_VALUE.IVA_POINT%type;
  begin
    begin
      select VAL.IVA_POINT
        into result
        from FAM_INDEX_VALUE VAL
       where VAL.IVA_INDEX_DATE = (select max(IVA_INDEX_DATE)
                                     from FAM_INDEX_VALUE
                                    where FAM_INDEX_ID = pIndexId
                                      and IVA_INDEX_DATE <= pDate)
         and VAL.FAM_INDEX_ID = pIndexId;
    exception
      when others then
        result  := 0;
    end;

    return result;
  end GetIndexPointInDate;

  /**
  * Description  Recherche du compte financier de l'immob ou de la catégorie avec le type d'imputation et la valeur gérée
  */
  function GetFixedAssetFinAccId(
    pFixedAssetId   in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pManagedValueId in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pImputationType in FAM_IMPUTATION_ACCOUNT.C_FAM_IMPUTATION_TYP%type
  )
    return FAM_IMPUTATION_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  is
    vResult FAM_IMPUTATION_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    /*Recherche du compte financier du type d'imputation demandé lié à l'immob */
    select nvl(max(IMP.ACS_FINANCIAL_ACCOUNT_ID), 0)
      into vResult
      from FAM_AMO_APPLICATION AMO
         , FAM_IMPUTATION_ACCOUNT IMP
     where AMO.FAM_FIXED_ASSETS_ID = pFixedAssetId
       and AMO.FAM_MANAGED_VALUE_ID = pManagedValueId
       and IMP.FAM_AMO_APPLICATION_ID = AMO.FAM_AMO_APPLICATION_ID
       and IMP.C_FAM_IMPUTATION_TYP = pImputationType;

    if vResult = 0 then
      /*Recherche du compte financier du type d'imputation demandé lié à la catégorie de l'immob */
      select nvl(max(IMP.ACS_FINANCIAL_ACCOUNT_ID), 0)
        into vResult
        from FAM_DEFAULT DEF
           , FAM_FIXED_ASSETS FIX
           , FAM_IMPUTATION_ACCOUNT IMP
       where FIX.FAM_FIXED_ASSETS_ID = pFixedAssetId
         and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
         and DEF.FAM_MANAGED_VALUE_ID = pManagedValueId
         and IMP.FAM_DEFAULT_ID = DEF.FAM_DEFAULT_ID
         and IMP.C_FAM_IMPUTATION_TYP = pImputationType;
    end if;

    return vResult;
  end GetFixedAssetFinAccId;

  /**
  * Description  Recherche du compte division de l'immob ou de la catégorie avec le type d'imputation et la valeur gérée
  */
  function GetFixedAssetDivAccId(
    pFixedAssetId   in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pManagedValueId in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pImputationType in FAM_IMPUTATION_ACCOUNT.C_FAM_IMPUTATION_TYP%type
  )
    return FAM_IMPUTATION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  is
    vResult FAM_FIXED_ASSETS.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    /*Recherche du compte division de l'immob */
    select nvl(max(FIX.ACS_DIVISION_ACCOUNT_ID), 0)
      into vResult
      from FAM_FIXED_ASSETS FIX
     where FIX.FAM_FIXED_ASSETS_ID = pFixedAssetId;

    if vResult = 0 then
      /*Recherche du compte division du type d'imputation demandé lié à l'immob */
      select nvl(max(IMP.ACS_DIVISION_ACCOUNT_ID), 0)
        into vResult
        from FAM_AMO_APPLICATION AMO
           , FAM_IMPUTATION_ACCOUNT IMP
       where AMO.FAM_FIXED_ASSETS_ID = pFixedAssetId
         and AMO.FAM_MANAGED_VALUE_ID = pManagedValueId
         and IMP.FAM_AMO_APPLICATION_ID = AMO.FAM_AMO_APPLICATION_ID
         and IMP.C_FAM_IMPUTATION_TYP = pImputationType;

      if vResult = 0 then
        /*Recherche du compte division du type d'imputation demandé lié à la catégorie de l'immob */
        select nvl(max(IMP.ACS_DIVISION_ACCOUNT_ID), 0)
          into vResult
          from FAM_DEFAULT DEF
             , FAM_FIXED_ASSETS FIX
             , FAM_IMPUTATION_ACCOUNT IMP
         where FIX.FAM_FIXED_ASSETS_ID = pFixedAssetId
           and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_MANAGED_VALUE_ID = pManagedValueId
           and IMP.FAM_DEFAULT_ID = DEF.FAM_DEFAULT_ID
           and IMP.C_FAM_IMPUTATION_TYP = pImputationType;
      end if;
    end if;

    return vResult;
  end GetFixedAssetDivAccId;

  /**
  * Description  Recherche du compte division de l'immob ou de la catégorie avec le type d'imputation et la valeur gérée
  */
  function GetFixedAssetCDAAccId(
    pFixedAssetId   in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pManagedValueId in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pImputationType in FAM_IMPUTATION_ACCOUNT.C_FAM_IMPUTATION_TYP%type
  )
    return FAM_IMPUTATION_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  is
    vResult FAM_FIXED_ASSETS.ACS_CDA_ACCOUNT_ID%type;
  begin
    /*Recherche du compte division de l'immob */
    select nvl(max(FIX.ACS_CDA_ACCOUNT_ID), 0)
      into vResult
      from FAM_FIXED_ASSETS FIX
     where FIX.FAM_FIXED_ASSETS_ID = pFixedAssetId;

    if vResult = 0 then
      /*Recherche du compte division du type d'imputation demandé lié à l'immob */
      select nvl(max(IMP.ACS_CDA_ACCOUNT_ID), 0)
        into vResult
        from FAM_AMO_APPLICATION AMO
           , FAM_IMPUTATION_ACCOUNT IMP
       where AMO.FAM_FIXED_ASSETS_ID = pFixedAssetId
         and AMO.FAM_MANAGED_VALUE_ID = pManagedValueId
         and IMP.FAM_AMO_APPLICATION_ID = AMO.FAM_AMO_APPLICATION_ID
         and IMP.C_FAM_IMPUTATION_TYP = pImputationType;

      if vResult = 0 then
        /*Recherche du compte division du type d'imputation demandé lié à la catégorie de l'immob */
        select nvl(max(IMP.ACS_CDA_ACCOUNT_ID), 0)
          into vResult
          from FAM_DEFAULT DEF
             , FAM_FIXED_ASSETS FIX
             , FAM_IMPUTATION_ACCOUNT IMP
         where FIX.FAM_FIXED_ASSETS_ID = pFixedAssetId
           and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_MANAGED_VALUE_ID = pManagedValueId
           and IMP.FAM_DEFAULT_ID = DEF.FAM_DEFAULT_ID
           and IMP.C_FAM_IMPUTATION_TYP = pImputationType;
      end if;
    end if;

    return vResult;
  end GetFixedAssetCDAAccId;

  /**
  * Description Mise à jour des valeurs à neuf des polices d'assurance
  */
  procedure UpdatePolicyValues(
    pInsurancePolicyID  in FAM_INSURANCE_POLICY.FAM_INSURANCE_POLICY_ID%type
  , pDateRef            in FAM_INDEX_VALUE.IVA_INDEX_DATE%type
  , pStructureElementID in FAM_STRUCTURE_ELEMENT.FAM_sTRUCTURE_ELEMENT_ID%type
  , pManagedValueID     in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
  , pIndexID            in FAM_INDEX.FAM_INDEX_ID%type
  , pCRoundType         in ACS_FINANCIAL_CURRENCY.C_ROUND_TYPE%type
  , pFinRoundedAmount   in ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type
  , pIncreaseAmount     in number
  , pReplaceAmount      in number
  , pIncludeComponent   in number
  , pFieldFilter        in number
  )
  is
    cursor InsuranceCursor(pInsuranceId in FAM_INSURANCE_POLICY.FAM_INSURANCE_POLICY_ID%type)
    is
      select INS.FAM_INSURANCE_ID
           , INS.FAM_FIXED_ASSETS_ID
           , INS.INS_NEW_VALUE
           , INS.INS_EFFECTIVE_VALUE
           , ASS.C_FIXED_ASSETS_TYP
           , ASS.FIX_PURCHASE_DATE
        from FAM_INSURANCE INS
           , FAM_FIXED_ASSETS ASS
       where INS.FAM_INSURANCE_POLICY_ID = pInsuranceId
         and ASS.FAM_FIXED_ASSETS_ID = INS.FAM_FIXED_ASSETS_ID;

    Insurance              InsuranceCursor%rowtype;
    vTotAmount             FAM_INSURANCE.INS_NEW_VALUE%type;
    vACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    vPeriodTo              ACS_PERIOD.PER_NO_PERIOD%type;
    vPointInDate           FAM_INDEX_VALUE.IVA_POINT%type;
  begin
    vACS_FINANCIAL_YEAR_ID  := ACS_FUNCTION.GetFinancialYearID(pDateRef);
    vPeriodTo               := ACS_FUNCTION.GetPeriodNo(pDateRef, '');

    open InsuranceCursor(pInsurancePolicyID);

    fetch InsuranceCursor
     into Insurance;

    while InsuranceCursor%found loop
      if    (     (Insurance.INS_NEW_VALUE is null)
             and (pFieldFilter = 1) )
         or (     (Insurance.INS_EFFECTIVE_VALUE is null)
             and (pFieldFilter = 0) )
         or (     (pReplaceAmount = 1)
             and (    (     (Insurance.C_FIXED_ASSETS_TYP = '2')
                       and (pIncludeComponent = 1) )
                  or (Insurance.C_FIXED_ASSETS_TYP <> '2')
                 )
            ) then
        --calculer le montant
        vTotAmount    :=
          StructureElementAmount(pIncludeComponent
                               , 1
                               , Insurance.FAM_FIXED_ASSETS_ID
                               , pManagedValueID
                               , pStructureElementID
                               , vACS_FINANCIAL_YEAR_ID
                               , ''
                               , vPeriodTo
                                );
        --Appliquer l'indice
        vPointInDate  := GetIndexPointInDate(Insurance.FIX_PURCHASE_DATE, pIndexID);

        if vPointInDate > 0 then
          vTotAmount  := (vTotAmount / vPointInDate) * GetIndexPointInDate(pDateRef, pIndexID);
        end if;

        --Appliquer le coefficient
        vTotAmount    := vTotAmount * pIncreaseAmount;
        --arrondir le montant
        vTotAmount    := ACS_FUNCTION.PcsRound(vTotAmount, pCRoundType, pFinRoundedAmount);

        --Mise à jour du montant
        if pFieldFilter = 1 then
          update FAM_INSURANCE
             set INS_NEW_VALUE = decode(sign(vTotAmount), -1, 0, vTotAmount)
               , A_DATEMOD = sysdate
               , A_IDMOD = gUserIni
           where FAM_INSURANCE_ID = Insurance.FAM_INSURANCE_ID;
        elsif pFieldFilter = 0 then
          update FAM_INSURANCE
             set INS_EFFECTIVE_VALUE = decode(sign(vTotAmount), -1, 0, vTotAmount)
               , A_DATEMOD = sysdate
               , A_IDMOD = gUserIni
           where FAM_INSURANCE_ID = Insurance.FAM_INSURANCE_ID;
        end if;
      end if;

      fetch InsuranceCursor
       into Insurance;
    end loop;

    close InsuranceCursor;
  end;

  /**
  * Description
  *     Retour de la catégorie de l'immobilisation passé en paramètre
  */
  function GetFixedAssetsCategory(pFixedAssetsId in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type)
    return FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  is
    vResult FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type;
  begin
    select nvl(max(FAM_FIXED_ASSETS_CATEG_ID), 0)
      into vResult
      from FAM_FIXED_ASSETS
     where FAM_FIXED_ASSETS_ID = pFixedAssetsId;

    return vResult;
  end GetFixedAssetsCategory;

  /**
  * Description
  *     Vérification de l'existence de composants pour une immo. donnée
  */
  function HasComponent(pFixedAssetsId in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type)
    return number
  is
    vResult FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
  begin
    select decode(nvl(max(FAM_FIXED_ASSETS_ID), 0), 0, 0, 1)
      into vResult
      from FAM_FIXED_ASSETS
     where FAM_FAM_FIXED_ASSETS_ID = pFixedAssetsId
       and C_FIXED_ASSETS_TYP = '2';

    return vResult;
  end HasComponent;

  /**
  * Description Vérification de la validité du type de transaction donné dans la comptabilisation
  *             de l'immobilisation
  **/
  function IsManAccountingAllowed(
    pFixedAssetsId  in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pFamCatalogueId in FAM_CATALOGUE.FAM_CATALOGUE_ID%type
  )
    return integer
  is
    vTransactionTyp FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;
  begin
    if not pFamCatalogueId is null then
      select C_FAM_TRANSACTION_TYP
        into vTransactionTyp
        from FAM_CATALOGUE
       where FAM_CATALOGUE_ID = pFamCatalogueId;

      return IsManAccountingAllowed(pFixedAssetsId, vTransactionTyp);
    end if;
  end IsManAccountingAllowed;

  /**
  * Description Vérification de la validité du type de transaction donné dans la comptabilisation
  *             de l'immobilisation
  **/
  function IsManAccountingAllowed(
    pFixedAssetsId  in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pTransactionTyp in FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type
  )
    return integer
  is
    vFixAllowed FAM_FIXED_ASSETS.FIX_MAN_ACCOUNTING_ALLOWED%type;
    vResult     integer;
  begin
    select FIX_MAN_ACCOUNTING_ALLOWED
      into vFixAllowed
      from FAM_FIXED_ASSETS
     where FAM_FIXED_ASSETS_ID = pFixedAssetsId;

    if vFixAllowed = 1 then
      vResult  := 1;
    else
      select decode(max(DET.FAM_ELEMENT_DETAIL_ID), null, 1, 0)
        into vResult
        from FAM_ELEMENT_DETAIL DET
       where DET.C_FAM_TRANSACTION_TYP = pTransactionTyp
         and (   exists(select 1
                          from FAM_DEFAULT DEF
                         where DEF.FAM_STRUCTURE_ELEMENT1_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_DEFAULT DEF
                         where DEF.FAM_STRUCTURE_ELEMENT2_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_DEFAULT DEF
                         where DEF.FAM_STRUCTURE_ELEMENT3_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_DEFAULT DEF
                         where DEF.FAM_STRUCTURE_ELEMENT4_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_DEFAULT DEF
                         where DEF.FAM_STRUCTURE_ELEMENT6_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_MANAGED_VALUE VAL
                         where VAL.FAM_STRUCTURE_ELEMENT_ID = dET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_MANAGED_VALUE VAL
                         where VAL.FAM_STRUCTURE_ELEMENT2_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_MANAGED_VALUE VAL
                         where VAL.FAM_STRUCTURE_ELEMENT3_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_MANAGED_VALUE VAL
                         where VAL.FAM_STRUCTURE_ELEMENT4_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
              or exists(select 1
                          from FAM_MANAGED_VALUE VAL
                         where VAL.FAM_STRUCTURE_ELEMENT6_ID = DET.FAM_STRUCTURE_ELEMENT_ID)
             );
    end if;

    return vResult;
  end IsManAccountingAllowed;

  /**
  * Retour de la première période valide dans les calculs d'amortissement
  **/
  function GetNextValidPeriod(
    pFinancialYearId in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
  , pExerciseNumber  in ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  )
    return varchar2
  is
    cursor crPeriod(
      pFinYearId       ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pExerciseNum     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
    , pMaxTreatedPerNo ACS_PERIOD.PER_NO_PERIOD%type
    )
    is
      select   PER.ACS_PERIOD_ID
          from ACS_PERIOD PER
             , ACS_FINANCIAL_YEAR FYE
         where FYE.ACS_FINANCIAL_YEAR_ID = pFinYearId
           and FYE.FYE_NO_EXERCICE >= pExerciseNum
           and FYE.C_STATE_FINANCIAL_YEAR = 'ACT'
           and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
           and not exists(select 1
                            from FAM_AMORTIZATION_PERIOD FAP
                           where FAP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                             and C_FAM_PERIOD_STATUS = '2')
           and PER.PER_NO_PERIOD >= pMaxTreatedPerNo
           and PER.C_TYPE_PERIOD = '2'
           and FAM_FUNCTIONS.PeriodAccordingAmoType(PER.PER_NO_PERIOD, PER.ACS_FINANCIAL_YEAR_ID) = 1
      order by PER_NO_PERIOD asc;

    vResult           varchar2(200);
    vTreatedPeriodNum ACS_PERIOD.PER_NO_PERIOD%type;
    vPeriodId         ACS_PERIOD.ACS_PERIOD_ID%type;
  begin
    vPeriodId  := 0;

    --Sélection de la + grande période déjà traitée dans l'exercice
    select nvl(max(PER.PER_NO_PERIOD), 0) + 1
      into vTreatedPeriodNum
      from FAM_AMORTIZATION_PERIOD FAP
         , ACS_PERIOD PER
     where PER.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
       and FAP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and FAP.C_FAM_PERIOD_STATUS = '2';

    open crPeriod(pFinancialYearId, pExerciseNumber, vTreatedPeriodNum);

    fetch crPeriod
     into vPeriodId;

    if crPeriod%found then
      vResult  := vResult || vPeriodId;

      if vTreatedPeriodNum = 1 then
        while crPeriod%found loop
          fetch crPeriod
           into vPeriodId;

          vResult  := vResult || ',' || vPeriodId;
        end loop;
      end if;
    else
      vResult  := vResult || '0';
    end if;

    close crPeriod;

    return vResult;
  end GetNextValidPeriod;

  /**
  * Valider la période donnée dans le contexte de cadencement
  **/
  function PeriodAccordingAmoType(
    pPerNumber       in ACS_PERIOD.PER_NO_PERIOD%type
  , pFinancialYearId in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
  )
    return number
  is
    vAmoPeriod    FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type;
    vMinPerNumber ACS_PERIOD.PER_NO_PERIOD%type;
    vMaxPerNumber ACS_PERIOD.PER_NO_PERIOD%type;
    vResult       number(1);
  begin
    vResult  := 0;

    /** Réception cadence d'amortissement */
    select nvl(min(C_AMORTIZATION_PERIOD), 0)
      into vAmoPeriod
      from FAM_AMORTIZATION_METHOD;

    select min(PER_NO_PERIOD)
         , max(PER_NO_PERIOD)
      into vMinPerNumber
         , vMaxPerNumber
      from ACS_PERIOD
     where ACS_FINANCIAL_YEAR_ID = pFinancialYearId
       and C_TYPE_PERIOD = '2';

    if    (     (vAmoPeriod = 1)
           and (pPerNumber between vMinPerNumber and vMaxPerNumber) )
       or (     (vAmoPeriod = 2)
           and (mod(pPerNumber, 3) = 0) )
       or (     (vAmoPeriod = 3)
           and (mod(pPerNumber, 6) = 0) )
       or (     (vAmoPeriod = 4)
           and (pPerNumber = vMaxPerNumber) ) then
      vResult  := 1;
    end if;

    return vResult;
  end PeriodAccordingAmoType;

      /**
  * Description
  *     Fonction de copie d'une fiche immo.
  */
  procedure DuplicateFixedAssets(
    pSourceFixedAssetsId     in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pLinkedFixedAssetsId     in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pFixedAssetsCategId      in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  , pFixedAssetsNumber       in     FAM_FIXED_ASSETS.FIX_NUMBER%type
  , pFixedAssetsShortDescr   in     FAM_FIXED_ASSETS.FIX_SHORT_DESCR%type
  , pFixedAssetsLongDescr    in     FAM_FIXED_ASSETS.FIX_LONG_DESCR%type
  , pFixedAssetsDescr        in     FAM_FIXED_ASSETS.FIX_DESCRIPTION%type
  , pDuplicateAllChain       in     number
  , pDuplicatedFixedAssetsId out    FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  )
  is
    /*Curseur de recheche des adresses liées à la fiche source  */
    cursor FamAddressToDuplicate(pSourceFixedAssetsId FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type)
    is
      select *
        from FAM_ADDRESS
       where FAM_FIXED_ASSETS_ID = pSourceFixedAssetsId;

    /*Curseur de recheche des assurances liées à la fiche source  */
    cursor FamInsuranceToDuplicate(pSourceFixedAssetsId FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type)
    is
      select *
        from FAM_INSURANCE
       where FAM_FIXED_ASSETS_ID = pSourceFixedAssetsId;

    vFamInsurance            FamInsuranceToDuplicate%rowtype;
    vFamAddress              FamAddressToDuplicate%rowtype;
    vDuplicatedFixedAssetsId FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
  begin
    begin
      /*Réception d'un nouvel Id de fiche immob.*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedFixedAssetsId
        from dual;

      /* Création de l'enregistrement sur la base de l'immob. à duplifier*/
      insert into FAM_FIXED_ASSETS
                  (FAM_FIXED_ASSETS_ID
                 , FAM_FIXED_ASSETS_CATEG_ID
                 , FIX_NUMBER
                 , FIX_SHORT_DESCR
                 , C_FIXED_ASSETS_STATUS
                 , C_FIXED_ASSETS_TYP
                 , C_OWNERSHIP
                 , FAM_FAM_FIXED_ASSETS_ID
                 , FIX_AMORTIZATION_BEGIN
                 , FIX_AMORTIZATION_END
                 , FIX_DESCRIPTION
                 , FIX_LANDOWNER_NUMBER
                 , FIX_LAND_REGISTRY_NUMBER
                 , FIX_LONG_DESCR
                 , FIX_MODEL
                 , FIX_PURCHASE_DATE
                 , FIX_SERIAL_NUMBER
                 , FIX_STATE_DATE
                 , FIX_SURFACE
                 , FIX_UNIT_QUANTITY
                 , FIX_VOLUME
                 , FIX_WARRANT_DURATION
                 , FIX_WARRANT_END
                 , FIX_WORKING_DATE
                 , FIX_YEAR
                 , HRM_PERSON_ID
                 , PAC_PERSON_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , DIC_FAM_FIX_FREECOD1_ID
                 , DIC_FAM_FIX_FREECOD2_ID
                 , DIC_FAM_FIX_FREECOD3_ID
                 , DIC_FAM_FIX_FREECOD4_ID
                 , DIC_FAM_FIX_FREECOD5_ID
                 , DIC_FAM_FIX_FREECOD6_ID
                 , DIC_FAM_FIX_FREECOD7_ID
                 , DIC_FAM_FIX_FREECOD8_ID
                 , DIC_FAM_FIX_FREECOD9_ID
                 , DIC_FAM_FIX_FREECOD10_ID
                 , DIC_LIABILITY_ID
                 , DIC_LOCATION_ID
                 , DIC_STATE_ID
                 , DIC_USE_UNIT_ID
                 , DOC_RECORD_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedFixedAssetsId   /* Immobilisation     -> Nouvel Id */
             , pFixedAssetsCategId   /* Catégorie          -> Paramètre */
             , pFixedAssetsNumber   /* Numéro             -> Paramètre */
             , pFixedAssetsShortDescr   /* Désignation courte -> Paramètre */
             , C_FIXED_ASSETS_STATUS
             , C_FIXED_ASSETS_TYP
             , C_OWNERSHIP
             , decode(pLinkedFixedAssetsId
                    ,   /* Fiche immo liée    -> Paramètre  popur les composants*/
                      null, FAM_FAM_FIXED_ASSETS_ID
                    , pLinkedFixedAssetsId
                     )
             , FIX_AMORTIZATION_BEGIN
             , FIX_AMORTIZATION_END
             , decode(pLinkedFixedAssetsId
                    ,   /* Description        -> Paramètre pour principale  / source */
                      null, pFixedAssetsDescr
                    ,   /* pour composant                                         */
                      FIX_DESCRIPTION
                     )
             , FIX_LANDOWNER_NUMBER
             , FIX_LAND_REGISTRY_NUMBER
             , decode(pLinkedFixedAssetsId
                    ,   /* Désignation longue -> Paramètre pour principale  / source */
                      null, pFixedAssetsLongDescr
                    ,   /* pour composant                                    */
                      FIX_LONG_DESCR
                     )
             , FIX_MODEL
             , null   /* Initialisation de la date d'achat FIX_PURCHASE_DATE  */
             , FIX_SERIAL_NUMBER
             , FIX_STATE_DATE
             , FIX_SURFACE
             , null   /* Initialisation de la qté d'utilisation                         */
             , FIX_VOLUME
             , FIX_WARRANT_DURATION
             , FIX_WARRANT_END
             , null   /* Initialisation de la date de mise en service FIX_WORKING_DATE  */
             , FIX_YEAR
             , null   /* Initialisation du lien employé HRM_PERSON_ID                   */
             , null   /* Initialisation du lien partenaire PAC_PERSON_ID                */
             , null   /* Initialisation du lien CDA                                     */
             , null   /* Initialisation du lien division                                */
             , null   /* Initialisation du lien PF                                      */
             , null   /* Initialisation du lien PJ                                      */
             , DIC_FAM_FIX_FREECOD1_ID
             , DIC_FAM_FIX_FREECOD2_ID
             , DIC_FAM_FIX_FREECOD3_ID
             , DIC_FAM_FIX_FREECOD4_ID
             , DIC_FAM_FIX_FREECOD5_ID
             , DIC_FAM_FIX_FREECOD6_ID
             , DIC_FAM_FIX_FREECOD7_ID
             , DIC_FAM_FIX_FREECOD8_ID
             , DIC_FAM_FIX_FREECOD9_ID
             , DIC_FAM_FIX_FREECOD10_ID
             , DIC_LIABILITY_ID
             , DIC_LOCATION_ID
             , DIC_STATE_ID
             , null   /* Initialisation du lien employé Unité d'utilisation   */
             , null   /* Initialisation du lien employé Dossier               */
             , sysdate   /* Date création      -> Date système                   */
             , gUserIni   /* Id création        -> user                           */
          from FAM_FIXED_ASSETS
         where FAM_FIXED_ASSETS_ID = pSourceFixedAssetsId;
    exception
      when others then
        vDuplicatedFixedAssetsId  := null;
        raise;
    end;

    if not vDuplicatedFixedAssetsId is null then
      /*Duplification de toute la chaîne parent- enfant */
      if pDuplicateAllChain = 1 then
        /**
        * Copie des adresses liées à la fiche immob. à copier
        * Parcours des adresses, chaque adresse est duplifiée et est rattachée à la fiche cible
        **/
        begin
          open FamAddressToDuplicate(pSourceFixedAssetsId);

          fetch FamAddressToDuplicate
           into vFamAddress;

          while FamAddressToDuplicate%found loop
            DuplicateFamAddressLink(vDuplicatedFixedAssetsId,   --Fiche parente ...fiche nouvellement créée
                                    vFamAddress.FAM_ADDRESS_ID);   --Adresse immob. source

            fetch FamAddressToDuplicate
             into vFamAddress;
          end loop;

          close FamAddressToDuplicate;
        exception
          when others then
            null;
        end;

        /**
        * Copie des assurances liées à la fiche immob. à copier
        * Parcours des assurances , chaque assurance est duplifiée et est rattachée à la fiche cible
        **/
        begin
          open FamInsuranceToDuplicate(pSourceFixedAssetsId);

          fetch FamInsuranceToDuplicate
           into vFamInsurance;

          while FamInsuranceToDuplicate%found loop
            DuplicateFamInsuranceLink(vDuplicatedFixedAssetsId,   --Fiche parente ...fiche nouvellement créée
                                      vFamInsurance.FAM_INSURANCE_ID);   --Assurance immob. source

            fetch FamInsuranceToDuplicate
             into vFamInsurance;
          end loop;

          close FamInsuranceToDuplicate;
        exception
          when others then
            null;
        end;
      end if;
    end if;

    commit;
    pDuplicatedFixedAssetsId  := vDuplicatedFixedAssetsId;   /*Assignation du paramètre de retour*/
  end DuplicateFixedAssets;

  /**
  * Description  Fonction de copie d'une méthode d'amortissement
  **/
  procedure DuplicateAmortizationMethod(
    pSourceRecordId     in     FAM_AMORTIZATION_METHOD.FAM_AMORTIZATION_METHOD_ID%type
  , pDuplicatedRecordId in out FAM_AMORTIZATION_METHOD.FAM_AMORTIZATION_METHOD_ID%type
  )
  is
    vSourceRefFld     FAM_AMORTIZATION_METHOD.AMO_DESCR%type;   -- Réceptionne champ référence source
    vDuplicatedRefFld FAM_AMORTIZATION_METHOD.AMO_DESCR%type;   -- Réceptionne champ référence formaté
    vDescrPosCpt      number;   --Position du [ dans le descriptif indiquant la "version" duplifiée  et compteur
    vKeyFldLength     number;   --Longueur du champ de référence
  begin
    begin
      vKeyFldLength      := 50;   --Longueur du champ de référence AMO_DESCR

      /** Réception de la description de la méthode source **/
      select AMO_DESCR
        into vSourceRefFld
        from FAM_AMORTIZATION_METHOD
       where FAM_AMORTIZATION_METHOD_ID = pSourceRecordId;

      /** Réception de la position du car. "[" indiquant la copie **/
      select instr(vSourceRefFld, '' || ' [#' || '')
        into vDescrPosCpt
        from dual;

      vDuplicatedRefFld  := vSourceRefFld;

      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(vSourceRefFld, 1, vDescrPosCpt - 1)
          into vDuplicatedRefFld
          from dual;
      else
        vDuplicatedRefFld  := substr(vDuplicatedRefFld, 1, vKeyFldLength - 6);
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1
        into vDescrPosCpt
        from FAM_AMORTIZATION_METHOD
       where AMO_DESCR like vDuplicatedRefFld || '%';

      -- Formatage du descriptif du nouveau type
      vDuplicatedRefFld  := substr( (vDuplicatedRefFld || ' [#' || vDescrPosCpt || ']'), 1, vKeyFldLength);

      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.nextval
        into pDuplicatedRecordId
        from dual;

      insert into FAM_AMORTIZATION_METHOD
                  (FAM_AMORTIZATION_METHOD_ID
                 , FAM_CATALOGUE_ID
                 , FAM_FAM_CATALOGUE_ID
                 , C_AMORTIZATION_PERIOD
                 , C_ROUND_TYPE
                 , C_ROUND_TYPE_INT
                 , C_AMORTIZATION_TYP
                 , C_INTEREST_CALC_RULES
                 , AMO_DESCR
                 , AMO_ROUNDED_AMOUNT
                 , AMO_ROUNDED_AMOUNT_INT
                 , AMO_AMORTIZATION_PLAN
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pDuplicatedRecordId   /* Nouvel Id                                   */
             , FAM_CATALOGUE_ID   /* Catalogue amortissement repris de la source */
             , FAM_FAM_CATALOGUE_ID   /* Catalogue intéret       repris de la source */
             , C_AMORTIZATION_PERIOD   /* Cadence                 repris de la source */
             , C_ROUND_TYPE   /* Type arrondi amo.       repris de la source */
             , C_ROUND_TYPE_INT   /* Type arrondi int.       repris de la source */
             , C_AMORTIZATION_TYP   /* Type amortissement      repris de la source */
             , C_INTEREST_CALC_RULES   /* Régle calcul intérêt    repris de la source */
             , vDuplicatedRefFld   /* Description             formaté selon source*/
             , AMO_ROUNDED_AMOUNT   /* Montant arrondi amo.    repris de la source */
             , AMO_ROUNDED_AMOUNT_INT   /* Montant arrondi intérêt repris de la source */
             , AMO_AMORTIZATION_PLAN   /* Utilisation Plan amort. repris de la source */
             , sysdate   /* Date création           Date système        */
             , gUserIni   /* Id création             user                */
          from FAM_AMORTIZATION_METHOD
         where FAM_AMORTIZATION_METHOD_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;
  end DuplicateAmortizationMethod;

  /**
  * Description  Fonction de copie d'un catlogue immob.
  **/
  procedure DuplicateFamCatalogue(
    pSourceRecordId     in     FAM_CATALOGUE.FAM_CATALOGUE_ID%type
  , pDuplicateAllChain  in     number
  , pDuplicatedRecordId in out FAM_CATALOGUE.FAM_CATALOGUE_ID%type
  )
  is
    cursor curManagedValToDuplicate
    is
      select FAM_CAT_MANAGED_VALUE_ID
        from FAM_CAT_MANAGED_VALUE
       where FAM_CATALOGUE_ID = pSourceRecordId;

    vCatManagedValId  FAM_CAT_MANAGED_VALUE.FAM_CAT_MANAGED_VALUE_ID%type;
    vSourceRefFld     FAM_CATALOGUE.FCA_KEY%type;   -- Réceptionne champ référence source
    vDuplicatedRefFld FAM_CATALOGUE.FCA_KEY%type;   -- Réceptionne champ référence formaté
    vDescrPosCpt      number;   -- Position du [ dans la clé indiquant la "version" duplifiée  et compteur
    vKeyFldLength     number;   -- Longueur du champ de référence
  begin
    begin
      vKeyFldLength      := 30;   --Longueur du champ de référence FCA_KEY

      /** Réception de la clé catalogue source **/
      select FCA_KEY
        into vSourceRefFld
        from FAM_CATALOGUE
       where FAM_CATALOGUE_ID = pSourceRecordId;

      /** Réception de la position du car. "[" indiquant la copie **/
      select instr(vSourceRefFld, '' || ' [#' || '')
        into vDescrPosCpt
        from dual;

      vDuplicatedRefFld  := vSourceRefFld;

      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(vSourceRefFld, 1, vDescrPosCpt - 1)
          into vDuplicatedRefFld
          from dual;
      else
        vDuplicatedRefFld  := substr(vDuplicatedRefFld, 1, vKeyFldLength - 6);
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1
        into vDescrPosCpt
        from FAM_CATALOGUE
       where FCA_KEY like vDuplicatedRefFld || '%';

      -- Formatage du descriptif du nouveau type
      vDuplicatedRefFld  := substr( (vDuplicatedRefFld || ' [#' || vDescrPosCpt || ']'), 1, vKeyFldLength);

      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.nextval
        into pDuplicatedRecordId
        from dual;

      insert into FAM_CATALOGUE
                  (FAM_CATALOGUE_ID
                 , C_FAM_TRANSACTION_TYP
                 , ACJ_NUMBER_METHOD_ID
                 , ACJ_JOB_TYPE_S_CATALOGUE_ID
                 , ACJ_JOB_TYPE_S_CATALOGUE2_ID
                 , FCA_KEY
                 , FCA_DESCR
                 , FCA_AVAILABLE
                 , FCA_DEBIT
                 , DIC_FAM_FCA_FREECOD1_ID
                 , DIC_FAM_FCA_FREECOD2_ID
                 , DIC_FAM_FCA_FREECOD3_ID
                 , DIC_FAM_FCA_FREECOD4_ID
                 , DIC_FAM_FCA_FREECOD5_ID
                 , DIC_FAM_FCA_FREECOD6_ID
                 , DIC_FAM_FCA_FREECOD7_ID
                 , DIC_FAM_FCA_FREECOD8_ID
                 , DIC_FAM_FCA_FREECOD9_ID
                 , DIC_FAM_FCA_FREECOD10_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pDuplicatedRecordId   /* Nouvel Id                                   */
             , C_FAM_TRANSACTION_TYP   /* Toutes les valeurs  sont reprises de ...    */
             , ACJ_NUMBER_METHOD_ID   /* ...l'enregistrement source , sauf le champ  */
             , ACJ_JOB_TYPE_S_CATALOGUE_ID   /* ... de référence                            */
             , ACJ_JOB_TYPE_S_CATALOGUE2_ID
             , vDuplicatedRefFld   /* Champ de référence  FCA_KEY                 */
             , FCA_DESCR
             , FCA_AVAILABLE
             , FCA_DEBIT
             , DIC_FAM_FCA_FREECOD1_ID
             , DIC_FAM_FCA_FREECOD2_ID
             , DIC_FAM_FCA_FREECOD3_ID
             , DIC_FAM_FCA_FREECOD4_ID
             , DIC_FAM_FCA_FREECOD5_ID
             , DIC_FAM_FCA_FREECOD6_ID
             , DIC_FAM_FCA_FREECOD7_ID
             , DIC_FAM_FCA_FREECOD8_ID
             , DIC_FAM_FCA_FREECOD9_ID
             , DIC_FAM_FCA_FREECOD10_ID
             , sysdate   /* Date création           Date système        */
             , gUserIni   /* Id création             user                */
          from FAM_CATALOGUE
         where FAM_CATALOGUE_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;

    if not pDuplicatedRecordId is null then
      /*Duplification de toute la chaîne parent- enfant */
      if pDuplicateAllChain = 1 then
        /**
        * Copie des valeurs gérées liées au catalogue à copier
        * Parcours des valeurs gérées, chaque valeur est copiée et est rattachée au catalogue cible
        **/
        begin
          open curManagedValToDuplicate;

          fetch curManagedValToDuplicate
           into vCatManagedValId;

          while curManagedValToDuplicate%found loop
            DuplicateCatManagedValLink(pDuplicatedRecordId,   --Catalogue parent ...catalogue nouvellement créé
                                       vCatManagedValId);   --Valeur par catégorie source

            fetch curManagedValToDuplicate
             into vCatManagedValId;
          end loop;

          close curManagedValToDuplicate;
        exception
          when others then
            null;
        end;
      end if;
    end if;
  end DuplicateFamCatalogue;

  /**
  * Description  Fonction de copie d'une catégorie d'immob.
  **/
  procedure DuplicateFamCategory(
    pSourceRecordId     in     FAM_FIXED_ASSETS_CATEG.FAM_FIXED_ASSETS_CATEG_ID%type   -- Catalogue source
  , pDuplicateAllChain  in     number   -- Duplifier toute la chaîne
  , pDuplicatedRecordId in out FAM_FIXED_ASSETS_CATEG.FAM_FIXED_ASSETS_CATEG_ID%type   -- Catalogue créée
  )
  is
    vSourceRefFld     FAM_FIXED_ASSETS_CATEG.CAT_DESCR%type;   -- Réceptionne champ référence source
    vDuplicatedRefFld FAM_FIXED_ASSETS_CATEG.CAT_DESCR%type;   -- Réceptionne champ référence formaté
    vDescrPosCpt      number;   -- Position du [ dans la clé indiquant la "version" duplifiée  et compteur
    vKeyFldLength     number;   -- Longueur du champ de référence
  begin
    begin
      vKeyFldLength      := 50;   --Longueur du champ de référence CAT_DESCR

      /** Réception de la clé catalogue source **/
      select CAT_DESCR
        into vSourceRefFld
        from FAM_FIXED_ASSETS_CATEG
       where FAM_FIXED_ASSETS_CATEG_ID = pSourceRecordId;

      /** Réception de la position du car. "[" indiquant la copie **/
      select instr(vSourceRefFld, '' || ' [#' || '')
        into vDescrPosCpt
        from dual;

      vDuplicatedRefFld  := vSourceRefFld;

      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(vSourceRefFld, 1, vDescrPosCpt - 1)
          into vDuplicatedRefFld
          from dual;
      else
        vDuplicatedRefFld  := substr(vDuplicatedRefFld, 1, vKeyFldLength - 6);
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1
        into vDescrPosCpt
        from FAM_FIXED_ASSETS_CATEG
       where CAT_DESCR like vDuplicatedRefFld || '%';

      -- Formatage du descriptif du nouveau type
      vDuplicatedRefFld  := substr( (vDuplicatedRefFld || ' [#' || vDescrPosCpt || ']'), 1, vKeyFldLength);

      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.nextval
        into pDuplicatedRecordId
        from dual;

      insert into FAM_FIXED_ASSETS_CATEG
                  (FAM_FIXED_ASSETS_CATEG_ID
                 , FAM_NUMBER_METHOD_ID
                 , CAT_DESCR
                 , C_FIXED_ASSETS_STATUS
                 , C_FIXED_ASSETS_TYP
                 , C_OWNERSHIP
                 , DIC_FAM_CAT_FREECOD1_ID
                 , DIC_FAM_CAT_FREECOD2_ID
                 , DIC_FAM_CAT_FREECOD3_ID
                 , DIC_FAM_CAT_FREECOD4_ID
                 , DIC_FAM_CAT_FREECOD5_ID
                 , DIC_FAM_CAT_FREECOD6_ID
                 , DIC_FAM_CAT_FREECOD7_ID
                 , DIC_FAM_CAT_FREECOD8_ID
                 , DIC_FAM_CAT_FREECOD9_ID
                 , DIC_FAM_CAT_FREECOD10_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pDuplicatedRecordId   /* Nouvel Id                                   */
             , FAM_NUMBER_METHOD_ID
             , vDuplicatedRefFld   /* Champ de référence  CAT_DESCR                 */
             , C_FIXED_ASSETS_STATUS
             , C_FIXED_ASSETS_TYP
             , C_OWNERSHIP
             , DIC_FAM_CAT_FREECOD1_ID
             , DIC_FAM_CAT_FREECOD2_ID
             , DIC_FAM_CAT_FREECOD3_ID
             , DIC_FAM_CAT_FREECOD4_ID
             , DIC_FAM_CAT_FREECOD5_ID
             , DIC_FAM_CAT_FREECOD6_ID
             , DIC_FAM_CAT_FREECOD7_ID
             , DIC_FAM_CAT_FREECOD8_ID
             , DIC_FAM_CAT_FREECOD9_ID
             , DIC_FAM_CAT_FREECOD10_ID
             , sysdate   /* Date création           Date système        */
             , gUserIni   /* Id création             user                */
          from FAM_FIXED_ASSETS_CATEG
         where FAM_FIXED_ASSETS_CATEG_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;
  end DuplicateFamCategory;

  /**
  * Description  Fonction de copie d'une polica d'assurance
  **/
  procedure DuplicateFamPolicy(
    pSourceRecordId     in     FAM_INSURANCE_POLICY.FAM_INSURANCE_POLICY_ID%type   -- Police d'assurance
  , pDuplicateAllChain  in     number   -- Duplifier toute la chaîne
  , pDuplicatedRecordId in out FAM_INSURANCE_POLICY.FAM_INSURANCE_POLICY_ID%type   -- Police créée
  )
  is
    cursor curInsuranceToDuplicate
    is
      select FAM_INSURANCE_ID
        from FAM_INSURANCE
       where FAM_INSURANCE_POLICY_ID = pSourceRecordId;

    vInsuranceId      FAM_INSURANCE.FAM_INSURANCE_ID%type;
    vSourceRefFld     FAM_INSURANCE_POLICY.POL_NUMBER%type;   -- Réceptionne champ référence source
    vDuplicatedRefFld FAM_INSURANCE_POLICY.POL_NUMBER%type;   -- Réceptionne champ référence formaté
    vDescrPosCpt      number;   -- Position du [ dans la clé indiquant la "version" duplifiée  et compteur
    vKeyFldLength     number;   -- Longueur du champ de référence
  begin
    begin
      vKeyFldLength      := 30;   --Longueur du champ de référence POL_NUMBER

      /** Réception du champ de référence source **/
      select POL_NUMBER
        into vSourceRefFld
        from FAM_INSURANCE_POLICY
       where FAM_INSURANCE_POLICY_ID = pSourceRecordId;

      /** Réception de la position du car. "[" indiquant la copie **/
      select instr(vSourceRefFld, '' || ' [#' || '')
        into vDescrPosCpt
        from dual;

      vDuplicatedRefFld  := vSourceRefFld;

      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(vSourceRefFld, 1, vDescrPosCpt - 1)
          into vDuplicatedRefFld
          from dual;
      else
        vDuplicatedRefFld  := substr(vDuplicatedRefFld, 1, vKeyFldLength - 6);
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1
        into vDescrPosCpt
        from FAM_INSURANCE_POLICY
       where POL_NUMBER like vDuplicatedRefFld || '%';

      -- Formatage du descriptif du nouveau type
      vDuplicatedRefFld  := substr( (vDuplicatedRefFld || ' [#' || vDescrPosCpt || ']'), 1, vKeyFldLength);

      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.nextval
        into pDuplicatedRecordId
        from dual;

      insert into FAM_INSURANCE_POLICY
                  (FAM_INSURANCE_POLICY_ID
                 , FAM_INDEX_ID
                 , FAM_MANAGED_VALUE_ID
                 , FAM_STRUCTURE_ELEMENT_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , PAC_PERSON_ID
                 , POL_NUMBER
                 , POL_BEGIN
                 , POL_EXPIRATION
                 , POL_REMARK
                 , POL_PREMIUM
                 , POL_FRANKNESS
                 , POL_INDEX
                 , POL_AMOUNT
                 , POL_DESIGNATION
                 , POL_NEXT_ANNULMENT
                 , DIC_PAYMENT_MODE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pDuplicatedRecordId   /* Nouvel Id                                   */
             , FAM_INDEX_ID
             , FAM_MANAGED_VALUE_ID
             , FAM_STRUCTURE_ELEMENT_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , PAC_PERSON_ID
             , vDuplicatedRefFld   /* Champ de référence  FCA_KEY                 */
             , POL_BEGIN
             , POL_EXPIRATION
             , POL_REMARK
             , POL_PREMIUM
             , POL_FRANKNESS
             , POL_INDEX
             , POL_AMOUNT
             , POL_DESIGNATION
             , POL_NEXT_ANNULMENT
             , DIC_PAYMENT_MODE_ID
             , sysdate   /* Date création           Date système        */
             , gUserIni   /* Id création             user                */
          from FAM_INSURANCE_POLICY
         where FAM_INSURANCE_POLICY_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;

    if not pDuplicatedRecordId is null then
      /*Duplification de toute la chaîne parent-enfant */
      if pDuplicateAllChain = 1 then
        /**
        * Copie des valeurs gérées liées au catalogue à copier
        * Parcours des valeurs gérées, chaque valeur est copiée et est rattachée au catalogue cible
        **/
        begin
          open curInsuranceToDuplicate;

          fetch curInsuranceToDuplicate
           into vInsuranceId;

          while curInsuranceToDuplicate%found loop
            DuplicateInsuranceLink(pDuplicatedRecordId,   --Catalogue parent ...catalogue nouvellement créé
                                   vInsuranceId);   --Assurance source

            fetch curInsuranceToDuplicate
             into vInsuranceId;
          end loop;

          close curInsuranceToDuplicate;
        exception
          when others then
            null;
        end;
      end if;
    end if;
  end DuplicateFamPolicy;

  /**
  * Description  Fonction de copie d'une valeur gérée
  **/
  procedure DuplicateManagedValue(
    pSourceRecordId     in     FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type   -- Valeur gérée
  , pDuplicateAllChain  in     number   -- Duplifier toute la chaîne
  , pDuplicatedRecordId in out FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type   -- Valeur gérée créée
  )
  is
    cursor curPresentationToDuplicate
    is
      select FAM_PRESENTATION_ID
        from FAM_PRESENTATION
       where FAM_MANAGED_VALUE_ID = pSourceRecordId;

    cursor curDefaultToDuplicate
    is
      select FAM_DEFAULT_ID
        from FAM_DEFAULT
       where FAM_MANAGED_VALUE_ID = pSourceRecordId;

    cursor curAccountsToDuplicate(pFamDefaultId FAM_DEFAULT.FAM_DEFAULT_ID%type)
    is
      select FAM_IMPUTATION_ACCOUNT_ID
        from FAM_IMPUTATION_ACCOUNT
       where FAM_DEFAULT_ID = pFamDefaultId;

    vPresentationId   FAM_PRESENTATION.FAM_PRESENTATION_ID%type;
    vDefaultId        FAM_DEFAULT.FAM_DEFAULT_ID%type;
    vDuplicatedDfltId FAM_DEFAULT.FAM_DEFAULT_ID%type;
    vAccountId        FAM_IMPUTATION_ACCOUNT.FAM_IMPUTATION_ACCOUNT_ID%type;
    vSourceRefFld     FAM_MANAGED_VALUE.VAL_KEY%type;   -- Réceptionne champ référence source
    vDuplicatedRefFld FAM_MANAGED_VALUE.VAL_KEY%type;   -- Réceptionne champ référence formaté
    vCValueCategory   FAM_MANAGED_VALUE.C_VALUE_CATEGORY%type;   -- Réceptionne catégorie
    vDescrPosCpt      number;   -- Position du [ dans la clé indiquant la "version" duplifiée  et compteur
    vKeyFldLength     number;   -- Longueur du champ de référence
  begin
    begin
      vKeyFldLength      := 30;   --Longueur du champ de référence VAL_KEY

      /** Réception du champ de référence source **/
      select VAL_KEY
        into vSourceRefFld
        from FAM_MANAGED_VALUE
       where FAM_MANAGED_VALUE_ID = pSourceRecordId;

      select to_char(to_number(max(C_VALUE_CATEGORY) ) + 1)
        into vCValueCategory
        from FAM_MANAGED_VALUE;

      /** Réception de la position du car. "[" indiquant la copie **/
      select instr(vSourceRefFld, '' || ' [#' || '')
        into vDescrPosCpt
        from dual;

      vDuplicatedRefFld  := vSourceRefFld;

      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(vSourceRefFld, 1, vDescrPosCpt - 1)
          into vDuplicatedRefFld
          from dual;
      else
        vDuplicatedRefFld  := substr(vDuplicatedRefFld, 1, vKeyFldLength - 6);
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1
        into vDescrPosCpt
        from FAM_MANAGED_VALUE
       where VAL_KEY like vDuplicatedRefFld || '%';

      -- Formatage du descriptif du nouveau type
      vDuplicatedRefFld  := substr( (vDuplicatedRefFld || ' [#' || vDescrPosCpt || ']'), 1, vKeyFldLength);

      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.nextval
        into pDuplicatedRecordId
        from dual;

      insert into FAM_MANAGED_VALUE
                  (FAM_MANAGED_VALUE_ID
                 , FAM_STRUCTURE_ELEMENT_ID
                 , FAM_STRUCTURE_ELEMENT2_ID
                 , FAM_STRUCTURE_ELEMENT3_ID
                 , FAM_STRUCTURE_ELEMENT4_ID
                 , FAM_STRUCTURE_ELEMENT5_ID
                 , FAM_STRUCTURE_ELEMENT6_ID
                 , ACS_FINANCIAL_YEAR_ID
                 , VAL_KEY
                 , VAL_DESCR
                 , C_VALUE_CATEGORY
                 , DIC_FAM_VAL_FREECOD1_ID
                 , DIC_FAM_VAL_FREECOD2_ID
                 , DIC_FAM_VAL_FREECOD3_ID
                 , DIC_FAM_VAL_FREECOD4_ID
                 , DIC_FAM_VAL_FREECOD5_ID
                 , DIC_FAM_VAL_FREECOD6_ID
                 , DIC_FAM_VAL_FREECOD7_ID
                 , DIC_FAM_VAL_FREECOD8_ID
                 , DIC_FAM_VAL_FREECOD9_ID
                 , DIC_FAM_VAL_FREECOD10_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pDuplicatedRecordId   /* Nouvel Id                                   */
             , FAM_STRUCTURE_ELEMENT_ID
             , FAM_STRUCTURE_ELEMENT2_ID
             , FAM_STRUCTURE_ELEMENT3_ID
             , FAM_STRUCTURE_ELEMENT4_ID
             , FAM_STRUCTURE_ELEMENT5_ID
             , FAM_STRUCTURE_ELEMENT6_ID
             , ACS_FINANCIAL_YEAR_ID
             , vDuplicatedRefFld   /* Champ de référence  VAL_KEY                 */
             , VAL_DESCR
             , vCValueCategory   /* Prochain numéro de catégorie                */
             , DIC_FAM_VAL_FREECOD1_ID
             , DIC_FAM_VAL_FREECOD2_ID
             , DIC_FAM_VAL_FREECOD3_ID
             , DIC_FAM_VAL_FREECOD4_ID
             , DIC_FAM_VAL_FREECOD5_ID
             , DIC_FAM_VAL_FREECOD6_ID
             , DIC_FAM_VAL_FREECOD7_ID
             , DIC_FAM_VAL_FREECOD8_ID
             , DIC_FAM_VAL_FREECOD9_ID
             , DIC_FAM_VAL_FREECOD10_ID
             , sysdate   /* Date création           Date système        */
             , gUserIni   /* Id création             user                */
          from FAM_MANAGED_VALUE
         where FAM_MANAGED_VALUE_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;

    if not pDuplicatedRecordId is null then
      /*Duplification de toute la chaîne parent-enfant */
      if pDuplicateAllChain = 1 then
        /**
        * Copie des présentations liées à la valeur gérée
        **/
        begin
          open curPresentationToDuplicate;

          fetch curPresentationToDuplicate
           into vPresentationId;

          while curPresentationToDuplicate%found loop
            DuplicatePresentationLink(pDuplicatedRecordId,   --Valeur gérée
                                      vPresentationId);   --Présentation source

            fetch curPresentationToDuplicate
             into vPresentationId;
          end loop;

          close curPresentationToDuplicate;
        exception
          when others then
            null;
        end;

        /**
        * Copie des données comptables liées à la valeur gérée
        **/
        begin
          open curDefaultToDuplicate;

          fetch curDefaultToDuplicate
           into vDefaultId;

          while curDefaultToDuplicate%found loop
            vDuplicatedDfltId  := DuplicateDefaultLink(pDuplicatedRecordId,   --Valeur gérée
                                                       vDefaultId);   --Donnée source

            if not vDefaultId is null then
              /**  Copie des comptes liées à la donnée comptable  **/
              begin
                open curAccountsToDuplicate(vDefaultId);

                fetch curAccountsToDuplicate
                 into vAccountId;

                while curAccountsToDuplicate%found loop
                  DuplicateAccountLink(vDuplicatedDfltId,   --Donnée comptable
                                       vAccountId);   --Présentation source

                  fetch curAccountsToDuplicate
                   into vAccountId;
                end loop;

                close curAccountsToDuplicate;
              exception
                when others then
                  null;
              end;
            end if;

            fetch curDefaultToDuplicate
             into vDefaultId;
          end loop;

          close curDefaultToDuplicate;
        exception
          when others then
            null;
        end;
      end if;
    end if;
  end DuplicateManagedValue;

  /**
  * Description  Fonction de copie de données comptables
  **/
  procedure DuplicateFamDefault(
    pSourceRecordId     in     FAM_DEFAULT.FAM_FIXED_ASSETS_CATEG_ID%type   -- Catalogue source
  , pDuplicateAllChain  in     number   -- Duplifier toute la chaîne
  , pCategoryId         in     FAM_DEFAULT.FAM_FIXED_ASSETS_CATEG_ID%type   --Catégorie d'assignation
  , pDuplicatedRecordId in out FAM_DEFAULT.FAM_FIXED_ASSETS_CATEG_ID%type   -- Catalogue créée
  )
  is
    cursor curAccountsToDuplicate
    is
      select FAM_IMPUTATION_ACCOUNT_ID
        from FAM_IMPUTATION_ACCOUNT
       where FAM_DEFAULT_ID = pSourceRecordId;

    vAccountId FAM_IMPUTATION_ACCOUNT.FAM_IMPUTATION_ACCOUNT_ID%type;
  begin
    select INIT_ID_SEQ.nextval
      into pDuplicatedRecordId
      from dual;

    begin
      insert into FAM_DEFAULT
                  (FAM_DEFAULT_ID
                 , FAM_MANAGED_VALUE_ID
                 , FAM_AMORTIZATION_METHOD_ID
                 , FAM_FIXED_ASSETS_CATEG_ID
                 , FAM_STRUCTURE_ELEMENT1_ID
                 , FAM_STRUCTURE_ELEMENT2_ID
                 , FAM_STRUCTURE_ELEMENT3_ID
                 , FAM_STRUCTURE_ELEMENT4_ID
                 , FAM_STRUCTURE_ELEMENT6_ID
                 , DEF_LIN_AMORTIZATION
                 , DEF_DEC_AMORTIZATION
                 , DEF_INTEREST_RATE
                 , DEF_INTEREST_RATE_2
                 , DEF_MIN_RESIDUAL_VALUE
                 , DIC_FAM_COEFFICIENT_ID
                 , DEF_NEGATIVE_BASE
                 , C_AMORTIZATION_DATE
                 , C_DEPRECIATION_PRORATA
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pDuplicatedRecordId
             , FAM_MANAGED_VALUE_ID
             , FAM_AMORTIZATION_METHOD_ID
             , pCategoryId
             , FAM_STRUCTURE_ELEMENT1_ID
             , FAM_STRUCTURE_ELEMENT2_ID
             , FAM_STRUCTURE_ELEMENT3_ID
             , FAM_STRUCTURE_ELEMENT4_ID
             , FAM_STRUCTURE_ELEMENT6_ID
             , DEF_LIN_AMORTIZATION
             , DEF_DEC_AMORTIZATION
             , DEF_INTEREST_RATE
             , DEF_INTEREST_RATE_2
             , DEF_MIN_RESIDUAL_VALUE
             , DIC_FAM_COEFFICIENT_ID
             , DEF_NEGATIVE_BASE
             , C_AMORTIZATION_DATE
             , C_DEPRECIATION_PRORATA
             , sysdate
             , gUserIni
          from FAM_DEFAULT
         where FAM_DEFAULT_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;

    if not pDuplicatedRecordId is null then
      /*Duplification de toute la chaîne parent-enfant */
      if pDuplicateAllChain = 1 then
        /**  Copie des comptes liées à la donnée comptable  **/
        begin
          open curAccountsToDuplicate;

          fetch curAccountsToDuplicate
           into vAccountId;

          while curAccountsToDuplicate%found loop
            DuplicateAccountLink(pDuplicatedRecordId,   --Donnée comptable
                                 vAccountId);   --Présentation source

            fetch curAccountsToDuplicate
             into vAccountId;
          end loop;

          close curAccountsToDuplicate;
        exception
          when others then
            null;
        end;
      end if;
    end if;
  end DuplicateFamDefault;

  /**
  * Description
  *     Fonction de copie d'une adresse immob.
  */
  procedure DuplicateFamAddressLink(
    pLinkedParentId in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   -- Immobilisation parente
  , pSourceRecordId in FAM_ADDRESS.FAM_ADDRESS_ID%type   -- Addresse source
  )
  is
  begin
    insert into FAM_ADDRESS
                (FAM_ADDRESS_ID
               , FAM_FIXED_ASSETS_ID
               , PAC_PERSON_ID
               , DIC_LINK_TYP_ID
               , ADD_REMARK
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   /* Nouvel Id                           */
           , pLinkedParentId   /* Immobilisation parente              */
           , PAC_PERSON_ID   /* Personne reprise de la source       */
           , DIC_LINK_TYP_ID   /* Type de lien repris de la source    */
           , ADD_REMARK   /* Remarque reprise de la source       */
           , sysdate   /* Date création      -> Date système  */
           , gUserIni   /* Id création        -> user          */
        from FAM_ADDRESS
       where FAM_ADDRESS_ID = pSourceRecordId;
  end DuplicateFamAddressLink;

  /**
  * Description
  *     Fonction de copie d'une Assurance immob.
  */
  procedure DuplicateFamInsuranceLink(
    pLinkedParentId in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   -- Immobilisation parente
  , pSourceRecordId in FAM_INSURANCE.FAM_INSURANCE_ID%type   -- Assurance source
  )
  is
  begin
    insert into FAM_INSURANCE
                (FAM_INSURANCE_ID
               , FAM_INSURANCE_POLICY_ID
               , FAM_FIXED_ASSETS_ID
               , INS_DECLARED_VALUE
               , INS_EFFECTIVE_VALUE
               , INS_NEW_VALUE
               , INS_PREMIUM
               , INS_PREMIUM_RATE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   /* Nouvel Id                                 */
           , FAM_INSURANCE_POLICY_ID   /* Police d'assurance reprise de la source   */
           , pLinkedParentId   /* Immobilisation parente                    */
           , INS_DECLARED_VALUE   /* Valeur déclarée reprise de la source      */
           , INS_EFFECTIVE_VALUE   /* Valeur effective reprise de la source     */
           , INS_NEW_VALUE   /* Valeur à neuf reprise de la source        */
           , INS_PREMIUM   /* Valeur de prime reprise de la source      */
           , INS_PREMIUM_RATE   /*  Taux de la prime reprise de la source    */
           , sysdate   /* Date création      -> Date système        */
           , gUserIni   /* Id création        -> user                */
        from FAM_INSURANCE
       where FAM_INSURANCE_ID = pSourceRecordId;
  end DuplicateFamInsuranceLink;

  /**
  * Description  Copie des valeurs gérées par catalogue
  **/
  procedure DuplicateCatManagedValLink(
    pLinkedParentId in FAM_CATALOGUE.FAM_CATALOGUE_ID%type
  , pSourceRecordId in FAM_CAT_MANAGED_VALUE.FAM_CAT_MANAGED_VALUE_ID%type
  )
  is
  begin
    insert into FAM_CAT_MANAGED_VALUE
                (FAM_CAT_MANAGED_VALUE_ID
               , FAM_CATALOGUE_ID
               , FAM_MANAGED_VALUE_ID
               , CMV_AMOUNTS_PILOT_FORMULA
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   /* Nouvel Id                           */
           , pLinkedParentId   /* Id Parent                           */
           , FAM_MANAGED_VALUE_ID   /* Valeur gérée reprise de la source   */
           , CMV_AMOUNTS_PILOT_FORMULA   /* Formule reprise de la source        */
           , sysdate   /* Date création      -> Date système  */
           , gUserIni   /* Id création        -> user          */
        from FAM_CAT_MANAGED_VALUE
       where FAM_CAT_MANAGED_VALUE_ID = pSourceRecordId;
  end DuplicateCatManagedValLink;

  /**
  * Description  Copie des assurances par police
  **/
  procedure DuplicateInsuranceLink(
    pLinkedParentId in FAM_INSURANCE_POLICY.FAM_INSURANCE_POLICY_ID%type
  , pSourceRecordId in FAM_INSURANCE.FAM_INSURANCE_ID%type
  )
  is
  begin
    insert into FAM_INSURANCE
                (FAM_INSURANCE_ID
               , FAM_INSURANCE_POLICY_ID
               , FAM_FIXED_ASSETS_ID
               , INS_DECLARED_VALUE
               , INS_EFFECTIVE_VALUE
               , INS_NEW_VALUE
               , INS_PREMIUM
               , INS_PREMIUM_RATE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   /* Nouvel Id                           */
           , pLinkedParentId   /* Id Parent                           */
           , FAM_FIXED_ASSETS_ID
           , INS_DECLARED_VALUE
           , INS_EFFECTIVE_VALUE
           , INS_NEW_VALUE
           , INS_PREMIUM
           , INS_PREMIUM_RATE
           , sysdate   /* Date création      -> Date système  */
           , gUserIni   /* Id création        -> user          */
        from FAM_INSURANCE
       where FAM_INSURANCE_ID = pSourceRecordId;
  end DuplicateInsuranceLink;

  /**
  * Description  Copie des présentations par valeur gérée
  **/
  procedure DuplicatePresentationLink(
    pLinkedParentId in FAM_PRESENTATION.FAM_MANAGED_VALUE_ID%type
  , pSourceRecordId in FAM_PRESENTATION.FAM_PRESENTATION_ID%type
  )
  is
  begin
    insert into FAM_PRESENTATION
                (FAM_PRESENTATION_ID
               , FAM_MANAGED_VALUE_ID
               , FAM_STRUCTURE_ID
               , PRE_DEFAULT
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   /* Nouvel Id                           */
           , pLinkedParentId   /* Id Parent                           */
           , FAM_STRUCTURE_ID
           , PRE_DEFAULT
           , sysdate   /* Date création      -> Date système  */
           , gUserIni   /* Id création        -> user          */
        from FAM_PRESENTATION
       where FAM_PRESENTATION_ID = pSourceRecordId;
  end DuplicatePresentationLink;

  /**
  * Description  Copie des données comptables par valeur gérée
  **/
  function DuplicateDefaultLink(
    pLinkedParentId in FAM_DEFAULT.FAM_MANAGED_VALUE_ID%type
  , pSourceRecordId in FAM_DEFAULT.FAM_DEFAULT_ID%type
  )
    return FAM_DEFAULT.FAM_DEFAULT_ID%type
  is
    vResult FAM_DEFAULT.FAM_DEFAULT_ID%type;
  begin
    select INIT_ID_SEQ.nextval
      into vResult
      from dual;

    begin
      insert into FAM_DEFAULT
                  (FAM_DEFAULT_ID
                 , FAM_MANAGED_VALUE_ID
                 , FAM_AMORTIZATION_METHOD_ID
                 , FAM_FIXED_ASSETS_CATEG_ID
                 , FAM_STRUCTURE_ELEMENT1_ID
                 , FAM_STRUCTURE_ELEMENT2_ID
                 , FAM_STRUCTURE_ELEMENT3_ID
                 , FAM_STRUCTURE_ELEMENT4_ID
                 , FAM_STRUCTURE_ELEMENT6_ID
                 , DEF_LIN_AMORTIZATION
                 , DEF_DEC_AMORTIZATION
                 , DEF_INTEREST_RATE
                 , DEF_INTEREST_RATE_2
                 , DEF_MIN_RESIDUAL_VALUE
                 , DIC_FAM_COEFFICIENT_ID
                 , DEF_NEGATIVE_BASE
                 , C_AMORTIZATION_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vResult   /* Nouvel Id                           */
             , pLinkedParentId   /* Id Parent                           */
             , FAM_AMORTIZATION_METHOD_ID
             , FAM_FIXED_ASSETS_CATEG_ID
             , FAM_STRUCTURE_ELEMENT1_ID
             , FAM_STRUCTURE_ELEMENT2_ID
             , FAM_STRUCTURE_ELEMENT3_ID
             , FAM_STRUCTURE_ELEMENT4_ID
             , FAM_STRUCTURE_ELEMENT6_ID
             , DEF_LIN_AMORTIZATION
             , DEF_DEC_AMORTIZATION
             , DEF_INTEREST_RATE
             , DEF_INTEREST_RATE_2
             , DEF_MIN_RESIDUAL_VALUE
             , DIC_FAM_COEFFICIENT_ID
             , DEF_NEGATIVE_BASE
             , C_AMORTIZATION_DATE
             , sysdate   /* Date création      -> Date système  */
             , gUserIni   /* Id création        -> user          */
          from FAM_DEFAULT
         where FAM_DEFAULT_ID = pSourceRecordId;
    exception
      when others then
        vResult  := null;
    end;

    return vResult;
  end DuplicateDefaultLink;

  /**
  * Description  Copie des comptes par données comptables
  **/
  procedure DuplicateAccountLink(
    pLinkedParentId in FAM_IMPUTATION_ACCOUNT.FAM_DEFAULT_ID%type
  , pSourceRecordId in FAM_IMPUTATION_ACCOUNT.FAM_IMPUTATION_ACCOUNT_ID%type
  )
  is
  begin
    insert into FAM_IMPUTATION_ACCOUNT
                (FAM_IMPUTATION_ACCOUNT_ID
               , FAM_DEFAULT_ID
               , FAM_AMO_APPLICATION_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , C_FAM_IMPUTATION_TYP
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   /* Nouvel Id                           */
           , pLinkedParentId   /* Id Parent                           */
           , FAM_AMO_APPLICATION_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , C_FAM_IMPUTATION_TYP
           , sysdate   /* Date création      -> Date système  */
           , gUserIni   /* Id création        -> user          */
        from FAM_IMPUTATION_ACCOUNT
       where FAM_IMPUTATION_ACCOUNT_ID = pSourceRecordId;
  end DuplicateAccountLink;

  /**
  * Description  Generate a record into table FAM_AMO_APPLICATION
  *              according to the given parameters
  **/
  procedure CreateFamAmoApplication(
    pAmoApplicationId  in out FAM_AMO_APPLICATION.FAM_AMO_APPLICATION_ID%type
  , pAmoFixedAssetsId  in     FAM_AMO_APPLICATION.FAM_FIXED_ASSETS_ID%type
  , pAmoMethodId       in     FAM_AMO_APPLICATION.FAM_AMORTIZATION_METHOD_ID%type
  , pAmoMAnagedValueId in     FAM_AMO_APPLICATION.FAM_MANAGED_VALUE_ID%type
  , pAmoBeginDate      in     FAM_AMO_APPLICATION.APP_AMORTIZATION_BEGIN%type
  , pAmoEndDate        in     FAM_AMO_APPLICATION.APP_AMORTIZATION_END%type
  , pAmoLinRate        in     FAM_AMO_APPLICATION.APP_LIN_AMORTIZATION%type
  , pAmoDecRate        in     FAM_AMO_APPLICATION.APP_DEC_AMORTIZATION%type
  , pAmoMonthDuration  in     FAM_AMO_APPLICATION.APP_MONTH_DURATION%type
  , pAmoYearDuration   in     FAM_AMO_APPLICATION.APP_YEAR_DURATION%type
  , pAmoInterestRate1  in     FAM_AMO_APPLICATION.APP_INTEREST_RATE%type
  , pAmoInterestRate2  in     FAM_AMO_APPLICATION.APP_INTEREST_RATE_2%type
  , pAmoNegativeBase   in     FAM_AMO_APPLICATION.APP_NEGATIVE_BASE%type
  , pAmoDicCoeffId     in     FAM_AMO_APPLICATION.DIC_FAM_COEFFICIENT_ID%type
  )
  is
  begin
    if    (pAmoApplicationId is null)
       or (pAmoApplicationId = 0) then
      select INIT_ID_SEQ.nextval
        into pAmoApplicationId
        from dual;
    end if;

    insert into FAM_AMO_APPLICATION
                (FAM_AMO_APPLICATION_ID
               , FAM_FIXED_ASSETS_ID
               , FAM_AMORTIZATION_METHOD_ID
               , FAM_MANAGED_VALUE_ID
               , APP_AMORTIZATION_BEGIN
               , APP_AMORTIZATION_END
               , APP_LIN_AMORTIZATION
               , APP_DEC_AMORTIZATION
               , APP_MONTH_DURATION
               , APP_YEAR_DURATION
               , APP_INTEREST_RATE
               , APP_INTEREST_RATE_2
               , APP_NEGATIVE_BASE
               , DIC_FAM_COEFFICIENT_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (pAmoApplicationId
               , pAmoFixedAssetsId
               , pAmoMethodId
               , pAmoMAnagedValueId
               , pAmoBeginDate
               , pAmoEndDate
               , pAmoLinRate
               , pAmoDecRate
               , pAmoMonthDuration
               , pAmoYearDuration
               , pAmoInterestRate1
               , pAmoInterestRate2
               , pAmoNegativeBase
               , pAmoDicCoeffId
               , sysdate
               , gUserIni
                );
  end CreateFamAmoApplication;

  /**
  * Description  Generate a record into table FAM_DOCUMENT
  *              according to the given parameters
  **/
  procedure CreateFamDocument(
    pDocFamDocumentId  in out FAM_DOCUMENT.FAM_DOCUMENT_ID%type
  , pDocFinCurrencyId  in     FAM_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , pDocJournalId      in     FAM_DOCUMENT.FAM_JOURNAL_ID%type
  , pDocCatalogueId    in     FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  , pDocFinDocumentId  in     FAM_DOCUMENT.ACT_DOCUMENT_ID%type
  , pDocIntNumber      in     FAM_DOCUMENT.FDO_INT_NUMBER%type
  , pDocExtNumber      in     FAM_DOCUMENT.FDO_EXT_NUMBER%type
  , pDocDocumentAmount in     FAM_DOCUMENT.FDO_AMOUNT%type
  , pDocDocumentDate   in     FAM_DOCUMENT.FDO_DOCUMENT_DATE%type
  )
  is
  begin
    if    (pDocFamDocumentId is null)
       or (pDocFamDocumentId = 0) then
      select INIT_ID_SEQ.nextval
        into pDocFamDocumentId
        from dual;
    end if;

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
         values (pDocFamDocumentId
               , pDocFinCurrencyId
               , pDocJournalId
               , pDocCatalogueId
               , pDocFinDocumentId
               , pDocIntNumber
               , pDocExtNumber
               , pDocDocumentAmount
               , pDocDocumentDate
               , sysdate
               , gUserIni
                );
  end CreateFamDocument;

  /**
  * Description  Calculate and return a date acco according to intializing code
  **/
  function GetAmortDate(
    pC_AMORTIZATION_DATE in FAM_DEFAULT.C_AMORTIZATION_DATE%type
  , pDate                in FAM_DEFAULT.A_DATECRE%type
  )
    return FAM_DEFAULT.A_DATECRE%type
  is
    cursor crExercise(pRefDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type)
    is
      select FYE_START_DATE StartDate
           , FYE_END_DATE EndDate
        from ACS_FINANCIAL_YEAR
       where pRefDate between FYE_START_DATE and FYE_END_DATE;

    cursor crPeriod(pRefDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type)
    is
      select PER_START_DATE StartDate
           , PER_END_DATE EndDate
        from ACS_PERIOD
       where (pRefDate between PER_START_DATE and PER_END_DATE)
         and C_TYPE_PERIOD = '2';

    cursor crNextPeriod(pRefDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type)
    is
      select PER.PER_START_DATE StartDate
           , PER.PER_END_DATE EndDate
        from ACS_PERIOD DAT
           , ACS_PERIOD PER
       where (pRefDate between DAT.PER_START_DATE and DAT.PER_END_DATE)
         and (PER.PER_START_DATE = DAT.PER_END_DATE + 1)
         and DAT.C_TYPE_PERIOD = '2'
         and PER.C_TYPE_PERIOD = '2';

    cursor crNextExercise(pRefDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type)
    is
      select FYE.FYE_START_DATE StartDate
           , FYE.FYE_END_DATE EndDate
        from ACS_FINANCIAL_YEAR DAT
           , ACS_FINANCIAL_YEAR FYE
       where (pRefDate between DAT.FYE_START_DATE and DAT.FYE_END_DATE)
         and (FYE.FYE_START_DATE = DAT.FYE_END_DATE + 1);

    tplDates crExercise%rowtype;
    vResult  FAM_DEFAULT.A_DATECRE%type;
  begin
    if pC_AMORTIZATION_DATE in('01', '02', '06', '07') then
      open crExercise(pDate);

      fetch crExercise
       into tplDates;
    elsif pC_AMORTIZATION_DATE in('03', '04', '08', '09') then
      open crPeriod(pDate);

      fetch crPeriod
       into tplDates;
    elsif pC_AMORTIZATION_DATE in('11', '12') then
      open crNextPeriod(pDate);

      fetch crNextPeriod
       into tplDates;
    elsif pC_AMORTIZATION_DATE in('13', '14') then
      open crNextExercise(pDate);

      fetch crNextExercise
       into tplDates;
    end if;

    case
      when pC_AMORTIZATION_DATE in('01', '03', '06', '08', '11', '12', '13', '14') then
        vResult  := tplDates.StartDate;
      when pC_AMORTIZATION_DATE in('02', '04', '07', '09') then
        vResult  := tplDates.EndDate;
      else
        vResult  := pDate;
    end case;

    if vResult is null then
      vResult  := pDate;
    end if;

    return vResult;
  end GetAmortDate;

  /**
  * Description  Retourne le nom du champ 'date' à prendre en compte selon le descode
  */
  function GetAmortizationDateField(pC_AMORTIZATION_DATE in FAM_DEFAULT.C_AMORTIZATION_DATE%type)
    return varchar2
  is
  begin
    return case
        when  pC_AMORTIZATION_DATE in ('01', '02', '03', '04', '05', '12', '14') then 'FIX_PURCHASE_DATE'
        when  pC_AMORTIZATION_DATE in ('06', '07', '08', '09', '10', '11', '13') then 'FIX_WORKING_DATE'
        else ''
      end;
  end GetAmortizationDateField;

  /**
   * Description Initialize fixed assets managed values
  **/
  procedure ManagedValuesInitialization(
    pFixedAssetsId      in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , pFixedAssetsCategId in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type
  , pDeleteImputation   in     number
  , pErrorCode          out    number
  )
  is
    cursor crFamDefault(pCategId FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type)
    is
      select   DEF.FAM_AMORTIZATION_METHOD_ID
             , DEF.FAM_MANAGED_VALUE_ID
             , DEF.C_AMORTIZATION_DATE
             , FAM_FUNCTIONS.GetAmortizationDateField(DEF.C_AMORTIZATION_DATE) AmortizationDateField
             , MET.C_AMORTIZATION_TYP
          from FAM_DEFAULT DEF
             , FAM_AMORTIZATION_METHOD MET
         where DEF.FAM_FIXED_ASSETS_CATEG_ID = pCategId
           and MET.FAM_AMORTIZATION_METHOD_ID = DEF.FAM_AMORTIZATION_METHOD_ID
      order by FAM_MANAGED_VALUE_ID;

    cursor crFamFixedAssets(pAssetsId FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type)
    is
      select FIX_PURCHASE_DATE
           , FIX_WORKING_DATE
        from FAM_FIXED_ASSETS
       where FAM_FIXED_ASSETS_ID = pAssetsId;

    tplFamDefault     crFamDefault%rowtype;
    tplFamFixedAssets crFamFixedAssets%rowtype;
    vblnCoefficient   boolean;
    vAmoApplicationId FAM_AMO_APPLICATION.FAM_AMO_APPLICATION_ID%type;
    vAmoDateBegin     FAM_AMO_APPLICATION.APP_AMORTIZATION_BEGIN%type;
  begin
    pErrorCode  := 0;

    delete from FAM_AMO_APPLICATION
          where FAM_FIXED_ASSETS_ID = pFixedAssetsId;

    open crFamFixedAssets(pFixedAssetsId);

    fetch crFamFixedAssets
     into tplFamFixedAssets;

    close crFamFixedAssets;

    open crFamDefault(pFixedAssetsCategId);

    fetch crFamDefault
     into tplFamDefault;

    while(crFamDefault%found)
     and (pErrorCode = 0) loop
      vblnCoefficient  :=(    (tplFamDefault.C_AMORTIZATION_TYP = '6')
                          or (tplFamDefault.C_AMORTIZATION_TYP = '60') );

      -- Purchase date or working date are required
      if tplFamDefault.AmortizationDateField = 'FIX_PURCHASE_DATE' then --in('01', '02', '03', '04', '05', '12', '14') then
        if (tplFamFixedAssets.FIX_PURCHASE_DATE is null) then
          pErrorCode  := 1;
        else
          vAmoDateBegin  :=
                     FAM_FUNCTIONS.GetAmortDate(tplFamDefault.C_AMORTIZATION_DATE, tplFamFixedAssets.FIX_PURCHASE_DATE);
        end if;
      elsif tplFamDefault.AmortizationDateField = 'FIX_WORKING_DATE' then --C_AMORTIZATION_DATE in('06', '07', '08', '09', '10', '11', '13') then
        if tplFamFixedAssets.FIX_WORKING_DATE is null then
          pErrorCode  := 2;
        else
          vAmoDateBegin  :=
                      FAM_FUNCTIONS.GetAmortDate(tplFamDefault.C_AMORTIZATION_DATE, tplFamFixedAssets.FIX_WORKING_DATE);
        end if;
      end if;

      if (pErrorCode = 0) then
        if pDeleteImputation = 1 then
          select max(FAM_AMO_APPLICATION_ID)
            into vAmoApplicationId
            from FAM_AMO_APPLICATION
           where FAM_FIXED_ASSETS_ID = pFixedAssetsId
             and FAM_MANAGED_VALUE_ID = tplFamDefault.FAM_MANAGED_VALUE_ID;

          if not vAmoApplicationId is null then
            delete from FAM_IMPUTATION_ACCOUNT
                  where FAM_AMO_APPLICATION_ID = vAmoApplicationId;
          end if;
        end if;

        vAmoApplicationId  := null;
        FAM_FUNCTIONS.CreateFamAmoApplication(vAmoApplicationId
                                            , pFixedAssetsId
                                            , tplFamDefault.FAM_AMORTIZATION_METHOD_ID
                                            , tplFamDefault.FAM_MANAGED_VALUE_ID
                                            , vAmoDateBegin
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                             );
      end if;

      fetch crFamDefault
       into tplFamDefault;
    end loop;

    close crFamDefault;
  end ManagedValuesInitialization;
begin
  gUserIni  := PCS.PC_I_LIB_SESSION.GetUserIni;
end FAM_FUNCTIONS;
