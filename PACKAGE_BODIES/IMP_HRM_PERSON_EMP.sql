--------------------------------------------------------
--  DDL for Package Body IMP_HRM_PERSON_EMP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_HRM_PERSON_EMP" 
as
  lcDomain constant varchar2(15) := 'HRM_PERSON';

  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_HRM_PERSON. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_HRM_PERSON(
    pPER_LAST_NAME                   varchar2
  , pPER_GENDER                      varchar2
  , pPER_BIRTH_DATE                  varchar2
  , pEMP_STATUS                      varchar2
  , pPER_FIRST_NAME                  varchar2
  , pC_CIVIL_STATUS                  varchar2
  , pEMP_SINGLE_PARENT               varchar2
  , pPC_LANG_ID                      varchar2
  , pDIC_CANTON_WORK_ID              varchar2
  , pC_IN_OUT_STATUS_1               varchar2
  , pINO_IN_1                        varchar2
  , pC_FINANCIAL_REF_TYPE_1          varchar2
  , pFIN_SEQUENCE_1                  varchar2
  , pACS_FINANCIAL_CURRENCY_ID_1     varchar2
  , pHEB_RATIO_1                     varchar2
  , pPER_TITLE                       varchar2
  , pPER_INITIALS                    varchar2
  , pPER_COMMENT                     varchar2
  , pPER_HOME_PHONE                  varchar2
  , pPER_HOME2_PHONE                 varchar2
  , pPER_MOBILE_PHONE                varchar2
  , pPER_EMAIL                       varchar2
  , pPER_HOMESTREET                  varchar2
  , pPER_HOMECITY                    varchar2
  , pPER_HOMESTATE                   varchar2
  , pPER_HOMEPOSTALCODE              varchar2
  , pPER_HOMECOUNTRY                 varchar2
  , pEMP_NUMBER                      varchar2
  , pEMP_SECONDARY_KEY               varchar2
  , pEMP_SOCIAL_SECURITYNO           varchar2
  , pDIC_WORKREGION_ID               varchar2
  , pEMP_NATIVE_OF                   varchar2
  , pEMP_CALCULATION                 varchar2
  , pEMP_HOBBIES                     varchar2
  , pDIC_WORKPLACE_ID                varchar2
  , pDIC_DEPARTMENT_ID               varchar2
  , pDIC_NATIONALITY_ID              varchar2
  , pDIC_CONFESSION_ID               varchar2
  , pEMP_SOCIAL_SECURITYNO2          varchar2
  , pEMP_CERTIF_OBSERVATION          varchar2
  , pEMP_LPP_CONTRIBUTOR             varchar2
  , pINO_OUT_1                       varchar2
  , pC_IN_OUT_STATUS_2               varchar2
  , pINO_IN_2                        varchar2
  , pINO_OUT_2                       varchar2
  , pFIN_ACCOUNT_NUMBER_1            varchar2
  , pBAN_CLEAR_1                     varchar2
  , pBAN_NAME1_1                     varchar2
  , pBAN_ZIP_1                       varchar2
  , pFIN_AMOUNT_1                    varchar2
  , pC_FINANCIAL_REF_TYPE_2          varchar2
  , pFIN_SEQUENCE_2                  varchar2
  , pACS_FINANCIAL_CURRENCY_ID_2     varchar2
  , pFIN_ACCOUNT_NUMBER_2            varchar2
  , pBAN_CLEAR_2                     varchar2
  , pBAN_NAME1_2                     varchar2
  , pBAN_ZIP_2                       varchar2
  , pFIN_AMOUNT_2                    varchar2
  , pREL_NAME_1                      varchar2
  , pREL_FIRST_NAME_1                varchar2
  , pREL_BIRTH_DATE_1                varchar2
  , pC_SEX_1                         varchar2
  , pREL_IS_DEPENDANT_1              varchar2
  , pREL_ALLOC_BEGIN_1               varchar2
  , pREL_ALLOC_END_1                 varchar2
  , pREL_ALLOC_AMOUNT_1              varchar2
  , pREL_NAME_2                      varchar2
  , pREL_FIRST_NAME_2                varchar2
  , pREL_BIRTH_DATE_2                varchar2
  , pC_SEX_2                         varchar2
  , pREL_IS_DEPENDANT_2              varchar2
  , pREL_ALLOC_BEGIN_2               varchar2
  , pREL_ALLOC_END_2                 varchar2
  , pREL_ALLOC_AMOUNT_2              varchar2
  , pREL_NAME_3                      varchar2
  , pREL_FIRST_NAME_3                varchar2
  , pREL_BIRTH_DATE_3                varchar2
  , pC_SEX_3                         varchar2
  , pREL_IS_DEPENDANT_3              varchar2
  , pREL_ALLOC_BEGIN_3               varchar2
  , pREL_ALLOC_END_3                 varchar2
  , pREL_ALLOC_AMOUNT_3              varchar2
  , pREL_NAME_4                      varchar2
  , pREL_FIRST_NAME_4                varchar2
  , pREL_BIRTH_DATE_4                varchar2
  , pC_SEX_4                         varchar2
  , pREL_IS_DEPENDANT_4              varchar2
  , pREL_ALLOC_BEGIN_4               varchar2
  , pREL_ALLOC_END_4                 varchar2
  , pREL_ALLOC_AMOUNT_4              varchar2
  , pHEB_DEPARTMENT_ID_1             varchar2
  , pHEB_DIV_NUMBER_1                varchar2
  , pHEB_CDA_NUMBER_1                varchar2
  , pHEB_CPN_NUMBER_1                varchar2
  , pHEB_PF_NUMBER_1                 varchar2
  , pHEB_PJ_NUMBER_1                 varchar2
  , pHEB_RATIO_2                     varchar2
  , pHEB_DEPARTMENT_ID_2             varchar2
  , pHEB_DIV_NUMBER_2                varchar2
  , pHEB_CDA_NUMBER_2                varchar2
  , pHEB_CPN_NUMBER_2                varchar2
  , pHEB_PF_NUMBER_2                 varchar2
  , pHEB_PJ_NUMBER_2                 varchar2
  , pWOP_NUMBER_ID                   varchar2
  , pDIC_WORK_PERMIT_ID              varchar2
  , pWOP_VALID_FROM                  varchar2
  , pWOP_VALID_TO                    varchar2
  , pC_HRM_TAX_CERTIF_TYPE           varchar2
  , pEMP_TAX_IS_EXPATRIATE           varchar2
  , pEMP_CANTEEN                     varchar2
  , pEMP_CARRIER_FREE                varchar2
  , pC_HRM_CANTON_TAX_FEES           varchar2
  , pEMP_TAX_FEES_DATE               varchar2
  , pEMP_TAX_FULLFILLED              varchar2
  , pC_HRM_CANTON_TAX_CAR            varchar2
  , pEMP_TAX_CAR_DATE                varchar2
  , pEMP_TAX_CAR_CHECK               varchar2
  , pPER_ACTIVITY_RATE               varchar2
  , pFREE1                           varchar2
  , pFREE2                           varchar2
  , pFREE3                           varchar2
  , pFREE4                           varchar2
  , pFREE5                           varchar2
  , pFREE6                           varchar2
  , pFREE7                           varchar2
  , pFREE8                           varchar2
  , pFREE9                           varchar2
  , pFREE10                          varchar2
  , pEXCEL_LINE                      integer
  , pRESULT                      out integer
  )
  is
  begin
    --Insertion dans la table IMP_HRM_PERSON
    insert into IMP_HRM_PERSON
                (id
               , EXCEL_LINE
               , HRM_PERSON_ID
               , PER_LAST_NAME
               , PER_GENDER
               , PER_BIRTH_DATE
               , EMP_STATUS
               , PER_FIRST_NAME
               , C_CIVIL_STATUS
               , EMP_SINGLE_PARENT
               , PC_LANG_ID
               , DIC_CANTON_WORK_ID
               , C_IN_OUT_STATUS_1
               , INO_IN_1
               , C_FINANCIAL_REF_TYPE_1
               , FIN_SEQUENCE_1
               , ACS_FINANCIAL_CURRENCY_ID_1
               , HEB_RATIO_1
               , PER_TITLE
               , PER_INITIALS
               , PER_COMMENT
               , PER_HOME_PHONE
               , PER_HOME2_PHONE
               , PER_MOBILE_PHONE
               , PER_EMAIL
               , PER_HOMESTREET
               , PER_HOMECITY
               , PER_HOMESTATE
               , PER_HOMEPOSTALCODE
               , PER_HOMECOUNTRY
               , EMP_NUMBER
               , EMP_SECONDARY_KEY
               , EMP_SOCIAL_SECURITYNO
               , DIC_WORKREGION_ID
               , EMP_NATIVE_OF
               , EMP_CALCULATION
               , EMP_HOBBIES
               , DIC_WORKPLACE_ID
               , DIC_DEPARTMENT_ID
               , DIC_NATIONALITY_ID
               , DIC_CONFESSION_ID
               , EMP_SOCIAL_SECURITYNO2
               , EMP_CERTIF_OBSERVATION
               , EMP_LPP_CONTRIBUTOR
               , INO_OUT_1
               , C_IN_OUT_STATUS_2
               , INO_IN_2
               , INO_OUT_2
               , FIN_ACCOUNT_NUMBER_1
               , BAN_CLEAR_1
               , BAN_NAME1_1
               , BAN_ZIP_1
               , FIN_AMOUNT_1
               , C_FINANCIAL_REF_TYPE_2
               , FIN_SEQUENCE_2
               , ACS_FINANCIAL_CURRENCY_ID_2
               , FIN_ACCOUNT_NUMBER_2
               , BAN_CLEAR_2
               , BAN_NAME1_2
               , BAN_ZIP_2
               , FIN_AMOUNT_2
               , HRM_RELATED_TO_ID_1
               , REL_NAME_1
               , REL_FIRST_NAME_1
               , REL_BIRTH_DATE_1
               , C_SEX_1
               , REL_IS_DEPENDANT_1
               , REL_ALLOC_BEGIN_1
               , REL_ALLOC_END_1
               , REl_ALLOC_AMOUNT_1
               , HRM_RELATED_TO_ID_2
               , REL_NAME_2
               , REL_FIRST_NAME_2
               , REL_BIRTH_DATE_2
               , C_SEX_2
               , REL_IS_DEPENDANT_2
               , REL_ALLOC_BEGIN_2
               , REL_ALLOC_END_2
               , REL_ALLOC_AMOUNT_2
               , HRM_RELATED_TO_ID_3
               , REL_NAME_3
               , REL_FIRST_NAME_3
               , REL_BIRTH_DATE_3
               , C_SEX_3
               , REL_IS_DEPENDANT_3
               , REL_ALLOC_BEGIN_3
               , REL_ALLOC_END_3
               , REL_ALLOC_AMOUNT_3
               , HRM_RELATED_TO_ID_4
               , REL_NAME_4
               , REL_FIRST_NAME_4
               , REL_BIRTH_DATE_4
               , C_SEX_4
               , REL_IS_DEPENDANT_4
               , REL_ALLOC_BEGIN_4
               , REL_ALLOC_END_4
               , REL_ALLOC_AMOUNT_4
               , HEB_DEPARTMENT_ID_1
               , HEB_DIV_NUMBER_1
               , HEB_CDA_NUMBER_1
               , HEB_CPN_NUMBER_1
               , HEB_PF_NUMBER_1
               , HEB_PJ_NUMBER_1
               , HEB_RATIO_2
               , HEB_DEPARTMENT_ID_2
               , HEB_DIV_NUMBER_2
               , HEB_CDA_NUMBER_2
               , HEB_CPN_NUMBER_2
               , HEB_PF_NUMBER_2
               , HEB_PJ_NUMBER_2
               , WOP_NUMBER_ID
               , DIC_WORK_PERMIT_ID
               , WOP_VALID_FROM
               , WOP_VALID_TO
               , C_HRM_TAX_CERTIF_TYPE
               , EMP_TAX_IS_EXPATRIATE
               , EMP_CANTEEN
               , EMP_CARRIER_FREE
               , C_HRM_CANTON_TAX_FEES
               , EMP_TAX_FEES_DATE
               , EMP_TAX_FULLFILLED
               , C_HRM_CANTON_TAX_CAR
               , EMP_TAX_CAR_DATE
               , EMP_TAX_CAR_CHECK
               , PER_ACTIVITY_RATE
               , FREE1
               , FREE2
               , FREE3
               , FREE4
               , FREE5
               , FREE6
               , FREE7
               , FREE8
               , FREE9
               , FREE10
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , pEXCEL_LINE
               , GetNewId
               , trim(pPER_LAST_NAME)
               , trim(pPER_GENDER)
               , trim(pPER_BIRTH_DATE)
               , trim(pEMP_STATUS)
               , trim(pPER_FIRST_NAME)
               , trim(pC_CIVIL_STATUS)
               , trim(pEMP_SINGLE_PARENT)
               , trim(pPC_LANG_ID)
               , trim(pDIC_CANTON_WORK_ID)
               , trim(pC_IN_OUT_STATUS_1)
               , trim(pINO_IN_1)
               , trim(pC_FINANCIAL_REF_TYPE_1)
               , trim(pFIN_SEQUENCE_1)
               , trim(pACS_FINANCIAL_CURRENCY_ID_1)
               , trim(pHEB_RATIO_1)
               , trim(pPER_TITLE)
               , trim(pPER_INITIALS)
               , trim(pPER_COMMENT)
               , trim(pPER_HOME_PHONE)
               , trim(pPER_HOME2_PHONE)
               , trim(pPER_MOBILE_PHONE)
               , trim(pPER_EMAIL)
               , trim(pPER_HOMESTREET)
               , trim(pPER_HOMECITY)
               , trim(pPER_HOMESTATE)
               , trim(pPER_HOMEPOSTALCODE)
               , trim(pPER_HOMECOUNTRY)
               , trim(pEMP_NUMBER)
               , trim(pEMP_SECONDARY_KEY)
               , trim(pEMP_SOCIAL_SECURITYNO)
               , trim(pDIC_WORKREGION_ID)
               , trim(pEMP_NATIVE_OF)
               , trim(pEMP_CALCULATION)
               , trim(pEMP_HOBBIES)
               , trim(pDIC_WORKPLACE_ID)
               , trim(pDIC_DEPARTMENT_ID)
               , trim(pDIC_NATIONALITY_ID)
               , trim(pDIC_CONFESSION_ID)
               , trim(pEMP_SOCIAL_SECURITYNO2)
               , trim(pEMP_CERTIF_OBSERVATION)
               , trim(pEMP_LPP_CONTRIBUTOR)
               , trim(pINO_OUT_1)
               , trim(pC_IN_OUT_STATUS_2)
               , trim(pINO_IN_2)
               , trim(pINO_OUT_2)
               , trim(pFIN_ACCOUNT_NUMBER_1)
               , trim(pBAN_CLEAR_1)
               , trim(pBAN_NAME1_1)
               , trim(pBAN_ZIP_1)
               , trim(pFIN_AMOUNT_1)
               , trim(pC_FINANCIAL_REF_TYPE_2)
               , trim(pFIN_SEQUENCE_2)
               , trim(pACS_FINANCIAL_CURRENCY_ID_2)
               , trim(pFIN_ACCOUNT_NUMBER_2)
               , trim(pBAN_CLEAR_2)
               , trim(pBAN_NAME1_2)
               , trim(pBAN_ZIP_2)
               , trim(pFIN_AMOUNT_2)
               , GetNewId
               , trim(pREL_NAME_1)
               , trim(pREL_FIRST_NAME_1)
               , trim(pREL_BIRTH_DATE_1)
               , trim(pC_SEX_1)
               , trim(pREL_IS_DEPENDANT_1)
               , trim(pREL_ALLOC_BEGIN_1)
               , trim(pREL_ALLOC_END_1)
               , trim(pREL_ALLOC_AMOUNT_1)
               , GetNewId
               , trim(pREL_NAME_2)
               , trim(pREL_FIRST_NAME_2)
               , trim(pREL_BIRTH_DATE_2)
               , trim(pC_SEX_2)
               , trim(pREL_IS_DEPENDANT_2)
               , trim(pREL_ALLOC_BEGIN_2)
               , trim(pREL_ALLOC_END_2)
               , trim(pREL_ALLOC_AMOUNT_2)
               , GetNewId
               , trim(pREL_NAME_3)
               , trim(pREL_FIRST_NAME_3)
               , trim(pREL_BIRTH_DATE_3)
               , trim(pC_SEX_3)
               , trim(pREL_IS_DEPENDANT_3)
               , trim(pREL_ALLOC_BEGIN_3)
               , trim(pREL_ALLOC_END_3)
               , trim(pREL_ALLOC_AMOUNT_3)
               , GetNewId
               , trim(pREL_NAME_4)
               , trim(pREL_FIRST_NAME_4)
               , trim(pREL_BIRTH_DATE_4)
               , trim(pC_SEX_4)
               , trim(pREL_IS_DEPENDANT_4)
               , trim(pREL_ALLOC_BEGIN_4)
               , trim(pREL_ALLOC_END_4)
               , trim(pREL_ALLOC_AMOUNT_4)
               , trim(pHEB_DEPARTMENT_ID_1)
               , trim(pHEB_DIV_NUMBER_1)
               , trim(pHEB_CDA_NUMBER_1)
               , trim(pHEB_CPN_NUMBER_1)
               , trim(pHEB_PF_NUMBER_1)
               , trim(pHEB_PJ_NUMBER_1)
               , trim(pHEB_RATIO_2)
               , trim(pHEB_DEPARTMENT_ID_2)
               , trim(pHEB_DIV_NUMBER_2)
               , trim(pHEB_CDA_NUMBER_2)
               , trim(pHEB_CPN_NUMBER_2)
               , trim(pHEB_PF_NUMBER_2)
               , trim(pHEB_PJ_NUMBER_2)
               , trim(pWOP_NUMBER_ID)
               , trim(pDIC_WORK_PERMIT_ID)
               , trim(pWOP_VALID_FROM)
               , trim(pWOP_VALID_TO)
               , trim(pC_HRM_TAX_CERTIF_TYPE)
               , trim(pEMP_TAX_IS_EXPATRIATE)
               , trim(pEMP_CANTEEN)
               , trim(pEMP_CARRIER_FREE)
               , trim(pC_HRM_CANTON_TAX_FEES)
               , trim(pEMP_TAX_FEES_DATE)
               , trim(pEMP_TAX_FULLFILLED)
               , trim(pC_HRM_CANTON_TAX_CAR)
               , trim(pEMP_TAX_CAR_DATE)
               , trim(pEMP_TAX_CAR_CHECK)
               , trim(pPER_ACTIVITY_RATE)
               , trim(pFREE1)
               , trim(pFREE2)
               , trim(pFREE3)
               , trim(pFREE4)
               , trim(pFREE5)
               , trim(pFREE6)
               , trim(pFREE7)
               , trim(pFREE8)
               , trim(pFREE9)
               , trim(pFREE10)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    --Nombre de ligne insérées
    pResult  := 1;
    commit;

    update IMP_HRM_PERSON
       set HRM_RELATED_TO_ID_1 = GetNewId;

    commit;

    update IMP_HRM_PERSON
       set HRM_RELATED_TO_ID_2 = GetNewId;

    commit;

    update IMP_HRM_PERSON
       set HRM_RELATED_TO_ID_3 = GetNewId;

    commit;

    update IMP_HRM_PERSON
       set HRM_RELATED_TO_ID_4 = GetNewId;

    commit;
  end IMP_TMP_HRM_PERSON;

  /**
  * Description
  *    Contrôle des données de la table IMP_HRM_PERSON avant importation.
  */
  procedure IMP_HRM_PERSON_CTRL
  is
    tmp       varchar2(200);
    tmp_int   integer;
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Contrôle de l'existence des langues 'FR', 'GE' et 'EN' dans l'ERP
    IMP_PRC_TOOLS.checkLanguage('FR', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('GE', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('EN', lcDomain, 0, '-');

    --Parcours de toutes les lignes de la table IMP_HRM_PERSON
    for tdata in (select *
                    from IMP_HRM_PERSON) loop
--***********************************************************************************
--Est-ce qu'il n'a pas de doublon dans le nom de famille, prénom et date de naissance
--et est-ce que tous les enregistrements ont une om de famille, prénom et date de naissance?
--*******************************************************************************************
      select count(per_last_name || per_first_name || per_birth_date)
        into tmp_int
        from IMP_HRM_PERSON
       where (per_last_name || per_first_name || per_birth_date) =(tdata.per_last_name || tdata.per_first_name || tdata.per_birth_date);

      --Si on a plus d'un enregistrement avec le om de famille, prénom et date de naissance
      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_PERSON_2') );
      end if;

      --Si on a pas d'enregistrement
      if (tmp_int = 0) then
        --Pas de nom de famille, prénom et date de naissance!
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_PERSON') );
      end if;

--***********************************************************
    --Existe déjà une person identique dans la table HRM_PERSON
    --**********************************************************
      begin
        select (per_last_name || per_first_name || per_birth_date)
          into tmp
          from HRM_PERSON
         where (per_last_name || per_first_name || to_char(per_birth_date, 'dd.mm.yyyy') ) =
                                                                                           (tdata.per_last_name || tdata.per_first_name || tdata.per_birth_date
                                                                                           );

        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_PERSON_3') );
      exception
        when no_data_found then
          null;
      end;

--*******************************************************
 --Contrôler qu'il y a au moins un no. AVS
 --*******************************************************
      if (    tdata.emp_social_securityno is null
          and tdata.emp_social_securityno2 is null) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_SOCIAL_SEC_1_OR_2') );
      end if;

--*******************************************************
--Est-ce que tous les champs obligatoires sont présents ?
--*******************************************************
      if (   tdata.per_last_name is null
          or tdata.per_gender is null
          or tdata.per_first_name is null
          or tdata.PER_TITLE is null
          or tdata.per_birth_date is null
          or tdata.emp_status is null
          or tdata.c_civil_status is null
          or tdata.pc_lang_id is null
          or tdata.emp_single_parent is null
          or tdata.dic_canton_work_id is null
          or tdata.c_in_out_status_1 is null
          or tdata.ino_in_1 is null
          or tdata.c_financial_ref_type_1 is null
          or tdata.fin_sequence_1 is null
          or tdata.acs_financial_currency_id_1 is null
          or tdata.heb_ratio_1 is null
          or tdata.PER_HOMECOUNTRY is null
         ) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
--*******************************************************
  --Est-ce que les données pour les depantants 1 sont saisi?
  --*******************************************************
        --Si des champs manquent
        if     (tdata.rel_name_1 is not null)
           and (   tdata.rel_first_name_1 is null
                or tdata.rel_birth_date_1 is null
                or tdata.c_sex_1 is null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_RELETED_1') );
        end if;

--*******************************************************
    --Est-ce que les données pour les depantants 2 sont saisi?
    --*******************************************************
        --Si des champs manquent
        if     (tdata.rel_name_2 is not null)
           and (   tdata.rel_first_name_2 is null
                or tdata.rel_birth_date_2 is null
                or tdata.c_sex_2 is null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_RELETED_2') );
        end if;

--*******************************************************
    --Est-ce que les données pour les depantants 3 sont saisi?
    --*******************************************************
        if     (tdata.rel_name_3 is not null)
           and (   tdata.rel_first_name_3 is null
                or tdata.rel_birth_date_3 is null
                or tdata.c_sex_3 is null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_RELETED_3') );
        end if;

--*******************************************************
    --Est-ce que les données pour les depantants 4 sont saisi?
    --*******************************************************
        --Si des champs manquent
        if     (tdata.rel_name_4 is not null)
           and (   tdata.rel_first_name_4 is null
                or tdata.rel_birth_date_4 is null
                or tdata.c_sex_4 is null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_RELETED_4') );
        end if;

--***************************************************************
    --Est-ce que les données pour le Permis de travail sont cohérent
    --**************************************************************
        if (    tdata.dic_work_permit_id is not null
            and tdata.wop_valid_from is null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_WORK_PERMIT') );
        end if;

--*******************************************************
--Est-ce que le dictionnaire des code de politness existe ?
--*******************************************************
        IMP_PRC_TOOLS.checkDicoValue('DIC_PERSON_POLITNESS', tdata.PER_TITLE, lcDomain, tdata.id, tdata.EXCEL_LINE);

--*******************************************************
    --Est-ce que la date de naissance est correct et le format date?
    --*******************************************************
        if to_date(tdata.per_birth_date, 'DD.MM.YYYY') is null then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_PER_BIRTH_DATE') );
        end if;

--*******************************************************
    --Est-ce que le canton pour l'adresse est renseigné?
    --*******************************************************
        if (tdata.PER_HOMECOUNTRY = 'CH') then
          begin
            select distinct zipstate
                       into tmp
                       from pcs.pc_zipci
                      where zipstate = tdata.per_homestate;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_PER_HOMESTATE') );
          end;
        end if;

--*******************************************************
--Est-ce que le genre est cohérent ?
--*******************************************************
        if (tdata.per_gender not in('F', 'M') ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_PER_GENDER') );
        end if;

--*******************************************************
    --Est-ce que le pay est cohérent
    --*******************************************************
        begin
          select cntid
            into tmp
            from pcs.pc_cntry
               , hrm_country
           where cntid = tdata.per_homecountry
             and decode(instr(cnt_code, '|'), '3',(substr(cnt_code, 1, instr(cnt_code, '|') - 1) ), cnt_code) = tdata.per_homecountry;
        exception
          when no_data_found then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_PER_HOMECOUNTRY_HOME') );
        end;

--*******************************************************
    --Est-ce que le status est cohérent
    --*******************************************************
        if (tdata.EMP_STATUS not in('ACT', 'INA', 'SUS') ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_STATUS') );
        end if;

--*******************************************************
    --Est-ce que le état civil est cohérent
    --*******************************************************
        if (tdata.C_CIVIL_STATUS not in('Cel', 'Dec', 'Div', 'Mar', 'Sep', 'Veu', 'Cnc', 'Pab', 'Pde', 'Pdi', 'Pen') ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_C_CIVIL_STATUS') );
        end if;

--*******************************************************
    --Est-ce que le dictionnaire des code de nationalité existe ?
    --*******************************************************
        if (tdata.DIC_WORKREGION_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_WORKREGION', tdata.DIC_WORKREGION_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le dictionnaire des code de nationalité existe ?
    --*******************************************************
        if (tdata.DIC_NATIONALITY_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_NATIONALITY', tdata.DIC_NATIONALITY_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le dictionnaire des code de confession existe ?
    --*******************************************************
        if (tdata.DIC_CONFESSION_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_CONFESSION', tdata.DIC_CONFESSION_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le dictionnaire des départements existe ?
    --*******************************************************
        if (tdata.DIC_DEPARTMENT_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_DEPARTMENT', tdata.DIC_DEPARTMENT_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le dictionnaire des lieu de travail existe ?
    --*******************************************************
        if (tdata.DIC_WORKPLACE_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_WORKPLACE', tdata.DIC_WORKPLACE_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*********************************************************
    --Est-ce que le dictionnaire des canton de travail existe ?
    --*********************************************************
        IMP_PRC_TOOLS.checkDicoValue('DIC_CANTON_WORK', tdata.DIC_CANTON_WORK_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);

--*******************************************************
    --Est-ce que le etat d'entrée 1 est cohérent
    --*******************************************************
        if (tdata.c_in_out_status_1 not in('ACT', 'HIS', 'INA') ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_IN_OUT_STATUS_1') );
        end if;

--*******************************************************
    --Est-ce que le etat d'entrée 2 est cohérent
    --*******************************************************
        if (    tdata.c_in_out_status_2 not in('ACT', 'HIS', 'INA')
            and not null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_IN_OUT_STATUS_2') );
        end if;

--*******************************************************
    --Est-ce que le type référence financière 1 est cohérent
    --*******************************************************
        if (    IMP_PUBLIC.TONUMBER(tdata.c_financial_ref_type_1) < 1
            and IMP_PUBLIC.TONUMBER(tdata.c_financial_ref_type_1) > 5) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_FINANCIAL_REF_TYPE_1') );
        end if;

--*******************************************************
    --Est-ce que le monnaie comptable 1 est cohérent
    --*******************************************************
        begin
          select pc_curr.currency
            into tmp
            from pcs.pc_curr
               , acs_financial_currency
           where pc_curr.currency = tdata.acs_financial_currency_id_1
             and pc_curr.pc_curr_id = acs_financial_currency.pc_curr_id;
        exception
          when no_data_found then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_ACS_FINANCIAL_CURRENCY_ID_1') );
        end;

--***************************************************************************************************
    --Est-ce que le Type référence financière 1 est cohérent et sont les donnée de correspondoce sont la
    --***************************************************************************************************
        if (    tdata.c_financial_ref_type_1 = '1'
            and (   tdata.ban_clear_1 is null
                 or tdata.ban_name1_1 is null
                 or tdata.ban_clear_1 is null
                 or tdata.ban_zip_1 is null)
           ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_BAN_CLEAR_1') );
        end if;

--*******************************************************
    --Est-ce que le clearing 1 existe ?
    --*******************************************************
        if (tdata.ban_clear_1 is not null) then
          begin
            select distinct ban_clear
                       into tmp
                       from pcs.pc_bank
                      where ban_clear = tdata.ban_clear_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_BAN_CLEAR_1_2') );
          end;
        end if;

        --*******************************************************
--Est-ce que le code postal 1 existe ?
--*******************************************************
        if (tdata.ban_zip_1 is not null) then
          begin
            select distinct ban_clear || ' ' || ban_zip
                       into tmp
                       from pcs.pc_bank
                      where ban_clear || ' ' || ban_zip like tdata.ban_clear_1 || ' ' || tdata.ban_zip_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_BAN_ZIP_1') );
          end;
        end if;

--*******************************************************
    --Est-ce que le ccp 1 est correct
    --*******************************************************
        if (    tdata.c_financial_ref_type_1 = '2'
            and tdata.fin_account_number_1 is not null) then
          begin
            if imp_checkccp(tdata.fin_account_number_1) = 0 then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_FIN_ACCOUNT_NUMBER_CCP_1') );
            end if;
          end;
        end if;

--*******************************************************
    --Est-ce que le iban 1 est correct
    --*******************************************************
        if     (    tdata.c_financial_ref_type_1 = '5'
                and tdata.fin_account_number_1 is not null)
           and (PAC_PARTNER_MANAGEMENT.CheckIBANNumber(tdata.fin_account_number_1) = 0) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_FIN_ACCOUNT_NUMBER_IBAN_1') );
        end if;

--*******************************************************
    --Est-ce que le type référence financière 2 est cohérent
    --*******************************************************
        if     (tdata.c_financial_ref_type_2 is not null)
           and (    IMP_PUBLIC.TONUMBER(tdata.c_financial_ref_type_2) < 1
                and IMP_PUBLIC.TONUMBER(tdata.c_financial_ref_type_2) > 5) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_FINANCIAL_REF_TYPE_2') );
        end if;

--*******************************************************
    --Est-ce que le monnaie comptable 2 est cohérent
    --*******************************************************
        if (tdata.acs_financial_currency_id_2 is not null) then
          begin
            select pc_curr.currency
              into tmp
              from pcs.pc_curr
                 , acs_financial_currency
             where pc_curr.currency = tdata.acs_financial_currency_id_2
               and pc_curr.pc_curr_id = acs_financial_currency.pc_curr_id;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_ACS_FINANCIAL_CURRENCY_ID_2') );
          end;
        end if;

--*******************************************************
    --Est-ce que le Type référence financière 2 est cohérent
    --*******************************************************
        if (    tdata.c_financial_ref_type_2 = '1'
            and (   tdata.ban_clear_2 is null
                 or tdata.ban_name1_2 is null
                 or tdata.ban_clear_2 is null
                 or tdata.ban_zip_2 is null)
           ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_BAN_CLEAR_2') );
        end if;

--*******************************************************
    --Est-ce que le clearing 2 existe ?
    --*******************************************************
        if (tdata.ban_clear_2 is not null) then
          begin
            select distinct ban_clear
                       into tmp
                       from pcs.pc_bank
                      where ban_clear = tdata.ban_clear_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_BAN_CLEAR_2_2') );
          end;
        end if;

        --*******************************************************
--Est-ce que le code postal 2 existe ?
--*******************************************************
        if (tdata.ban_zip_2 is not null) then
          begin
            select distinct ban_clear || ' ' || ban_zip
                       into tmp
                       from pcs.pc_bank
                      where ban_clear || ' ' || ban_zip like tdata.ban_clear_2 || ' ' || tdata.ban_zip_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_EMP_BAN_ZIP_2') );
          end;
        end if;

--*******************************************************
   --Est-ce que le ccp 2 est correct
   --*******************************************************
        if (    tdata.c_financial_ref_type_1 = '2'
            and tdata.fin_account_number_2 is not null) then
          begin
            if imp_checkccp(tdata.fin_account_number_2) = 0 then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_FIN_ACCOUNT_NUMBER_CCP_2') );
            end if;
          end;
        end if;

--*******************************************************
    --Est-ce que le iban 2 est correct
    --*******************************************************
        if     (    tdata.c_financial_ref_type_1 = '5'
                and tdata.fin_account_number_2 is not null)
           and (PAC_PARTNER_MANAGEMENT.CheckIBANNumber(tdata.fin_account_number_2) = 0) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_FIN_ACCOUNT_NUMBER_IBAN_2') );
        end if;

--*******************************************************
    --Est-ce que le sexe du dependante 1 exist:
    --*******************************************************
        if (    tdata.c_sex_1 not in('F', 'M')
            and tdata.rel_name_1 is not null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_SEXE_1') );
        end if;

--*******************************************************
    --Est-ce que le sexe du dependante 2 exist:
    --*******************************************************
        if (    tdata.c_sex_2 not in('F', 'M')
            and tdata.rel_name_2 is not null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_SEXE_2') );
        end if;

--*******************************************************
    --Est-ce que le sexe du dependante 3 exist:
    --*******************************************************
        if (    tdata.c_sex_3 not in('F', 'M')
            and tdata.rel_name_3 is not null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_SEXE_3') );
        end if;

--*******************************************************
    --Est-ce que le sexe du dependante 4 exist:
    --*******************************************************
        if (    tdata.c_sex_4 not in('F', 'M')
            and tdata.rel_name_4 is not null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_SEXE_4') );
        end if;

--*********************************************************
    --Est-ce que le departement 1 pour l'info compta 1 existe ?
    --*********************************************************
        if (tdata.heb_department_id_1 is not null) then
          begin
            select div.dic_department_id
              into tmp
              from hrm_division div
             where div.dic_department_id = tdata.HEB_DEPARTMENT_ID_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_DEPARTMENT_ID_1') );
          end;
        end if;

--***************************************************************
    --Est-ce que le division compta 1 pour l'info compta 1 existe ?
    --**************************************************************
        if (tdata.heb_div_number_1 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_division_account
             where acs_account_id = acs_division_account_id
               and acc_number = tdata.heb_div_number_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_DIV_NUMBER_1') );
          end;
        end if;

--***************************************************************
    --Est-ce que la centre d'analyse 1 pour l'info compta 1 existe ?
    --**************************************************************
        if (tdata.heb_cda_number_1 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_cda_account
             where acs_account_id = acs_cda_account_id
               and acc_number = tdata.heb_cda_number_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_CDA_NUMBER_1') );
          end;
        end if;

--***************************************************************
    --Est-ce que la centre par nature 1 pour l'info compta 1 existe ?
    --**************************************************************
        if (tdata.heb_cpn_number_1 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_cpn_account
             where acs_account_id = acs_cpn_account_id
               and acc_number = tdata.heb_cpn_number_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_CPN_NUMBER_1') );
          end;
        end if;

--***************************************************************
    --Est-ce que le porteur de frais 1 pour l'info compta 1 existe ?
    --**************************************************************
        if (tdata.heb_pf_number_1 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_pf_account
             where acs_account_id = acs_pf_account_id
               and acc_number = tdata.heb_pf_number_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_PF_NUMBER_1') );
          end;
        end if;

--***************************************************************
    --Est-ce que le projet 1 pour l'info compta 1 existe ?
    --**************************************************************
        if (tdata.heb_pj_number_1 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_pj_account
             where acs_account_id = acs_pj_account_id
               and acc_number = tdata.heb_pj_number_1;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_PJ_NUMBER_1') );
          end;
        end if;

--*********************************************************
    --Est-ce que le departement 2 pour l'info compta 2 existe ?
    --*********************************************************
        if (tdata.heb_department_id_2 is not null) then
          begin
            select div.dic_department_id
              into tmp
              from hrm_division div
             where div.dic_department_id = tdata.heb_department_id_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_DEPARTMENT_ID_2') );
          end;
        end if;

--***************************************************************
    --Est-ce que le division compta 2 pour l'info compta 2 existe ?
    --**************************************************************
        if (tdata.heb_div_number_2 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_division_account
             where acs_account_id = acs_division_account_id
               and acc_number = tdata.heb_div_number_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_DIV_NUMBER_2') );
          end;
        end if;

--***************************************************************
    --Est-ce que la centre d'analyse 2 pour l'info compta 2 existe ?
    --**************************************************************
        if (tdata.heb_cda_number_2 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_cda_account
             where acs_account_id = acs_cda_account_id
               and acc_number = tdata.heb_cda_number_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_CDA_NUMBER_2') );
          end;
        end if;

--***************************************************************
    --Est-ce que la centre par nature 2 pour l'info compta 2 existe ?
    --**************************************************************
        if (tdata.heb_cpn_number_2 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_cpn_account
             where acs_account_id = acs_cpn_account_id
               and acc_number = tdata.heb_cpn_number_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_CPN_NUMBER_2') );
          end;
        end if;

--***************************************************************
    --Est-ce que le porteur de frais 2 pour l'info compta 2 existe ?
    --**************************************************************
        if (tdata.heb_pf_number_2 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_pf_account
             where acs_account_id = acs_pf_account_id
               and acc_number = tdata.heb_pf_number_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_PF_NUMBER_2') );
          end;
        end if;

--***************************************************************
    --Est-ce que le projet 2 pour l'info compta 2 existe ?
    --**************************************************************
        if (tdata.heb_pj_number_2 is not null) then
          begin
            select acc_number
              into tmp
              from acs_account
                 , acs_pj_account
             where acs_account_id = acs_pj_account_id
               and acc_number = tdata.heb_pj_number_2;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_HEB_PJ_NUMBER_2') );
          end;
        end if;

--*******************************************************
    --Est-ce que le dictionnaire pour le permis de travail existe ?
    --*******************************************************
        if (tdata.dic_work_permit_id is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_WORK_PERMIT', tdata.DIC_WORK_PERMIT_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le code du certification type existe ?
    --*******************************************************
        if (    tdata.c_hrm_tax_certif_type is not null
            and lpad(tdata.c_hrm_tax_certif_type, 2, '0') not in('01', '02') ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_HRM_TAX_CERTIF_TYPE') );
        end if;

--*******************************************************
    --Est-ce que le code du Expatrié existe ?
    --*******************************************************
        if (tdata.EMP_TAX_IS_EXPATRIATE is not null) then
          IMP_PRC_TOOLS.checkBooleanValue('EMP_TAX_IS_EXPATRIATE', tdata.emp_tax_is_expatriate, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le code pour la cantine existe ?
    --*******************************************************
        if (tdata.EMP_CANTEEN is not null) then
          IMP_PRC_TOOLS.checkBooleanValue('EMP_CANTEEN', tdata.EMP_CANTEEN, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le code pour le transport graduit existe ?
    --*******************************************************
        if (tdata.EMP_CARRIER_FREE is not null) then
          IMP_PRC_TOOLS.checkBooleanValue('EMP_CARRIER_FREE', tdata.EMP_CARRIER_FREE, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le canton pour règlement des frais agréé est cohérent
    --*******************************************************
        if (tdata.c_hrm_canton_tax_fees is not null) then
          begin
            select distinct zipstate
                       into tmp
                       from pcs.pc_zipci
                      where zipstate = tdata.c_hrm_canton_tax_fees;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_HRM_CANTON_TAX_FEES') );
          end;
        end if;

--*******************************************************
    --Est-ce que Conditions remboursement frais effectif remplies existe ?
    --*******************************************************
        if (tdata.EMP_TAX_FULLFILLED is not null) then
          IMP_PRC_TOOLS.checkBooleanValue('EMP_TAX_FULLFILLED', tdata.EMP_TAX_FULLFILLED, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
    --Est-ce que le canton pour la part privée de voiture de service agréée cohérent
    --*******************************************************
        if (tdata.c_hrm_canton_tax_car is not null) then
          begin
            select distinct zipstate
                       into tmp
                       from pcs.pc_zipci
                      where zipstate = tdata.c_hrm_canton_tax_car;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_HRM_C_HRM_CANTON_TAX_CAR') );
          end;
        end if;

--*******************************************************
    --Est-ce que Part privée de voiture de service à examiner existe ?
    --*******************************************************
        if (tdata.EMP_TAX_CAR_CHECK is not null) then
          IMP_PRC_TOOLS.checkBooleanValue('EMP_TAX_CAR_CHECK', tdata.EMP_TAX_CAR_CHECK, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_HRM_PERSON_CTRL;

  /**
  * Description
  *    Importation des données employés
  */
  procedure IMP_HRM_PERSON_IMPORT
  is
    tmp integer;
    L1  varchar2(10);
    L2  varchar2(10);
    L3  varchar2(10);
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_HRM_PERSON) loop
      --Insertion des données dans les tables !
      insert into HRM_PERSON
                  (HRM_PERSON_ID
                 , PER_LAST_NAME
                 , PER_GENDER
                 , PER_FIRST_NAME
                 , PER_TITLE
                 , PER_INITIALS
                 , PER_BIRTH_DATE
                 , PER_COMMENT
                 , PER_HOME_PHONE
                 , PER_HOME2_PHONE
                 , PER_MOBILE_PHONE
                 , PER_EMAIL
                 , PER_HOMESTREET
                 , PER_HOMECITY
                 , PER_HOMESTATE
                 , PER_HOMEPOSTALCODE
                 , PER_HOMECOUNTRY
                 , EMP_STATUS
                 , EMP_NUMBER
                 , EMP_SECONDARY_KEY
                 , EMP_SOCIAL_SECURITYNO
                 , C_CIVIL_STATUS
                 , DIC_WORKREGION_ID
                 , EMP_NATIVE_OF
                 , EMP_CALCULATION
                 , EMP_SINGLE_PARENT
                 , EMP_HOBBIES
                 , PC_LANG_ID
                 , DIC_WORKPLACE_ID
                 , DIC_DEPARTMENT_ID
                 , DIC_NATIONALITY_ID
                 , DIC_CONFESSION_ID
                 , DIC_CANTON_WORK_ID
                 , EMP_SOCIAL_SECURITYNO2
                 , EMP_LPP_CONTRIBUTOR
                 , PER_FULLNAME
                 , PER_IS_CONTACT
                 , PER_IS_EMPLOYEE
                 , PER_IS_DEPENDENT
                 , PER_IS_CANDIDAT
                 , PER_IS_TRAINER
                 , PER_IS_RESPONSIBLE
                 , PER_IS_QUICK_EDIT
                 , PER_ACTIVITY_RATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (tdata.hrm_person_id
                 , tdata.per_last_name
                 , tdata.per_gender
                 , tdata.per_first_name
                 , tdata.per_title
                 , tdata.per_initials
                 , to_date(tdata.per_birth_date, 'DD.MM.YYYY')
                 , tdata.per_comment
                 , tdata.per_home_phone
                 , tdata.per_home2_phone
                 , tdata.per_mobile_phone
                 , tdata.per_email
                 , tdata.per_homestreet
                 , tdata.per_homecity
                 , tdata.per_homestate
                 , tdata.per_homepostalcode
                 , (select substr(c.cnt_name, 1,(instr(c.cnt_name, '|') - 1) )
                      from hrm_country c
                     where decode(instr(cnt_code, '|'), '3',(substr(cnt_code, 1, instr(cnt_code, '|') - 1) ), cnt_code) = tdata.per_homecountry)
                 , tdata.emp_status
                 , tdata.emp_number
                 , tdata.emp_secondary_key
                 , tdata.emp_social_securityno
                 , tdata.c_civil_status
                 , tdata.dic_workregion_id
                 , tdata.emp_native_of
                 , tdata.emp_calculation
                 , tdata.emp_single_parent
                 , tdata.emp_hobbies
                 , (select p.pc_lang_id
                      from pcs.pc_lang p
                     where p.lanid = tdata.pc_lang_id)
                 , tdata.dic_workplace_id
                 , tdata.dic_department_id
                 , tdata.dic_nationality_id
                 , tdata.dic_confession_id
                 , tdata.dic_canton_work_id
                 , tdata.emp_social_securityno2
                 , tdata.emp_lpp_contributor
                 , tdata.per_title || ' ' || tdata.per_first_name || ' ' || tdata.per_last_name
                 , 0
                 , 1
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , tdata.per_activity_rate
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                  );

       --Correspondance des langues (L1, L2, L3) entre Excel et ProConcept
       --L1 = langue de la société
       --L2 = seconde langue
       --L3 = troisième langue
      /* select pc_lang_id into L1 from pcs.pc_comp c, pcs.pc_scrip s where c.pc_scrip_id = s.pc_scrip_id
         and s.SCRDBOWNER = (select COM_CURRENTSCHEMA from dual);

       case L1 when '1' then
                    L2 := '2';
                    L3 := '3';
               when '2' then
                    L2 := '1';
                    L3 := '3';
                when '3' then
                    L2 := '1';
                    L3 := '2';
        end case; */

      --Insertion le Certificat de salaire

      --- if(tdata.c_hrm_tax_certif_type is not null) then
      insert into HRM_PERSON_TAX
                  (HRM_PERSON_ID
                 , HRM_PERSON_TAX_ID
                 , EMP_TAX_YEAR
                 , C_HRM_TAX_CERTIF_TYPE
                 , EMP_TAX_IS_EXPATRIATE
                 , C_HRM_CANTON_TAX_FEES
                 , EMP_TAX_FEES_DATE
                 , EMP_TAX_FULLFILLED
                 , C_HRM_CANTON_TAX_CAR
                 , EMP_TAX_CAR_DATE
                 , EMP_TAX_CAR_CHECK
                 , EMP_TAX_THIRD_SHARE
                 , EMP_TAX_EXPAT_EXPENSES
                 , EMP_TAX_CHILD_ALLOW_PERAVS
                 , EMP_CERTIF_OBSERVATION
                 , EMP_CANTEEN
                 , EMP_CARRIER_FREE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (tdata.hrm_person_id
                 , init_id_seq.NextVal
                 , to_char(hrm_date.beginOfYear(), 'yyyy')
                 , lpad(tdata.c_hrm_tax_certif_type, 2, '0')
                 , nvl(tdata.emp_tax_is_expatriate, 0)
                 , tdata.c_hrm_canton_tax_fees
                 , to_date(tdata.emp_tax_fees_date, 'DD.MM.YYYY')
                 , nvl(tdata.emp_tax_fullfilled, 0)
                 , tdata.c_hrm_canton_tax_car
                 , to_date(tdata.emp_tax_car_date, 'DD.MM.YYYY')
                 , nvl(tdata.emp_tax_car_check, 0)
                 , 0
                 , 0
                 , 0
                 , tdata.emp_certif_observation
                 , nvl(tdata.emp_canteen, 0)
                 , nvl(tdata.emp_carrier_free, 0)
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                  );

      ----end If;

      --Insertion des descriptions HRM_IN_OUT 1
      if (   tdata.c_in_out_status_1 is not null
          or tdata.ino_in_1 is not null) then
        insert into HRM_IN_OUT
                    (HRM_IN_OUT_ID
                   , HRM_EMPLOYEE_ID
                   , DIC_IN_TYPE_ID
                   , DIC_OUT_TYPE_ID
                   , C_IN_OUT_STATUS
                   , C_IN_OUT_CATEGORY
                   , INO_IN
                   , INO_OUT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.HRM_PERSON_ID
                   , '01'
                   , case
                       when tdata.ino_out_1 is not null then '01'
                     end
                   , case
                       when tdata.ino_out_1 is not null then 'HIS'
                       else 'ACT'
                     end
                   , 3
                   , to_date(tdata.ino_in_1, 'DD.MM.YYYY')
                   , to_date(tdata.ino_out_1, 'DD.MM.YYYY')
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion des descriptions HRM_IN_OUT 2
      if (   tdata.c_in_out_status_2 is not null
          or tdata.ino_in_2 is not null) then
        insert into HRM_IN_OUT
                    (HRM_IN_OUT_ID
                   , HRM_EMPLOYEE_ID
                   , DIC_IN_TYPE_ID
                   , DIC_OUT_TYPE_ID
                   , C_IN_OUT_STATUS
                   , C_IN_OUT_CATEGORY
                   , INO_IN
                   , INO_OUT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.HRM_PERSON_ID
                   , '01'
                   , case
                       when tdata.ino_out_2 is not null then '01'
                     end
                   , case
                       when tdata.ino_out_2 is not null then 'HIS'
                       else 'ACT'
                     end
                   , 3
                   , to_date(tdata.ino_in_2, 'DD.MM.YYYY')
                   , to_date(tdata.ino_out_2, 'DD.MM.YYYY')
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion la référance financières 1
      if (    tdata.c_financial_ref_type_1 is not null
          and tdata.fin_sequence_1 is not null) then
        insert into HRM_FINANCIAL_REF
                    (HRM_FINANCIAL_REF_ID
                   , HRM_EMPLOYEE_ID
                   , PC_BANK_ID
                   , PC_CNTRY_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , C_FINANCIAL_REF_TYPE
                   , FIN_AMOUNT
                   , FIN_ACCOUNT_NUMBER
                   , FIN_SEQUENCE
                   , FIN_START_DATE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.HRM_PERSON_ID
                   , (select max(BAN.PC_BANK_ID)
                        from PCS.PC_BANK BAN
                           , HRM_PERSON PER
                       where ban.BAN_ZIP = tdata.BAN_ZIP_1
                         and ban.BAN_CLEAR = tdata.BAN_CLEAR_1
                         and PER.HRM_PERSON_ID = tdata.hrm_person_id)
                   , case
                       when tdata.c_financial_ref_type_1 = 2 then (select cen.PC_CNTRY_ID
                                                                     from pcs.pc_cntry cen
                                                                    where cen.CNTID = 'CH')
                     end
                   , (select max(acs.ACS_FINANCIAL_CURRENCY_ID)
                        from pcs.PC_CURR cur
                           , ACS_FINANCIAL_CURRENCY acs
                       where upper(cur.CURRENCY) = upper(tdata.ACS_FINANCIAL_CURRENCY_ID_1)
                         and cur.PC_CURR_ID = acs.PC_CURR_ID)   -- ACS_FINANCIAL_CURRENCY_ID
                   , tdata.c_financial_ref_type_1
                   , tdata.fin_amount_1
                   , tdata.fin_account_number_1
                   , tdata.FIN_SEQUENCE_1
                   , trunc(sysdate)
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion la référance financières 2
      if (    tdata.c_financial_ref_type_2 is not null
          and tdata.fin_sequence_2 is not null) then
        insert into HRM_FINANCIAL_REF
                    (HRM_FINANCIAL_REF_ID
                   , HRM_EMPLOYEE_ID
                   , PC_BANK_ID
                   , PC_CNTRY_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , C_FINANCIAL_REF_TYPE
                   , FIN_AMOUNT
                   , FIN_ACCOUNT_NUMBER
                   , FIN_SEQUENCE
                   , FIN_START_DATE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.HRM_PERSON_ID
                   , (select max(BAN.PC_BANK_ID)
                        from PCS.PC_BANK BAN
                           , HRM_PERSON PER
                       where ban.BAN_ZIP = tdata.BAN_ZIP_2
                         and ban.BAN_CLEAR = tdata.BAN_CLEAR_2
                         and PER.HRM_PERSON_ID = tdata.hrm_person_id)
                   , case
                       when tdata.c_financial_ref_type_2 = 2 then (select cen.PC_CNTRY_ID
                                                                     from pcs.pc_cntry cen
                                                                    where cen.CNTID = 'CH')
                     end
                   , (select max(acs.ACS_FINANCIAL_CURRENCY_ID)
                        from pcs.PC_CURR cur
                           , ACS_FINANCIAL_CURRENCY acs
                       where upper(cur.CURRENCY) = upper(tdata.ACS_FINANCIAL_CURRENCY_ID_2)
                         and cur.PC_CURR_ID = acs.PC_CURR_ID)   -- ACS_FINANCIAL_CURRENCY_ID
                   , tdata.c_financial_ref_type_2
                   , tdata.fin_amount_2
                   , tdata.fin_account_number_2
                   , tdata.FIN_SEQUENCE_2
                   , trunc(sysdate)
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion données enfants 1
      if (    tdata.rel_name_1 is not null
          and tdata.rel_first_name_1 is not null
          and tdata.c_sex_1 is not null) then
        insert into HRM_RELATED_TO
                    (HRM_RELATED_TO_ID
                   , HRM_EMPLOYEE_ID
                   , C_RELATED_TO_TYPE
                   , C_SEX
                   , REL_NAME
                   , REL_FIRST_NAME
                   , REL_BIRTH_DATE
                   , REL_ALLOC_AMOUNT
                   , REL_ALLOC_BEGIN
                   , REL_ALLOC_END
                   , REL_IS_DEPENDANT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (tdata.hrm_related_to_id_1
                   , tdata.HRM_PERSON_ID
                   , '2'
                   , tdata.c_sex_1
                   , tdata.rel_name_1
                   , tdata.rel_first_name_1
                   , to_date(tdata.rel_birth_date_1, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_1
                   , to_date(tdata.rel_alloc_begin_1, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_1, 'DD.MM.YYYY')
                   , tdata.rel_is_dependant_1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion l'allocations enfants 1
      if (    tdata.rel_alloc_begin_1 is not null
          and tdata.rel_alloc_end_1 is not null
          and tdata.rel_alloc_amount_1 is not null) then
        insert into HRM_RELATED_ALLOCATION
                    (HRM_RELATED_ALLOCATION_ID
                   , HRM_RELATED_TO_ID
                   , DIC_ALLOWANCE_TYPE_ID
                   , ALLO_BEGIN
                   , ALLO_END
                   , ALLO_AMOUNT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.hrm_related_to_id_1
                   , '0'
                   , to_date(tdata.rel_alloc_begin_1, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_1, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion données  enfants 2
      if (    tdata.rel_name_2 is not null
          and tdata.rel_first_name_2 is not null
          and tdata.c_sex_2 is not null) then
        insert into HRM_RELATED_TO
                    (HRM_RELATED_TO_ID
                   , HRM_EMPLOYEE_ID
                   , C_RELATED_TO_TYPE
                   , C_SEX
                   , REL_NAME
                   , REL_FIRST_NAME
                   , REL_BIRTH_DATE
                   , REL_ALLOC_AMOUNT
                   , REL_ALLOC_BEGIN
                   , REL_ALLOC_END
                   , REL_IS_DEPENDANT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (tdata.hrm_related_to_id_2
                   , tdata.HRM_PERSON_ID
                   , '2'
                   , tdata.c_sex_2
                   , tdata.rel_name_2
                   , tdata.rel_first_name_2
                   , to_date(tdata.rel_birth_date_2, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_2
                   , to_date(tdata.rel_alloc_begin_2, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_2, 'DD.MM.YYYY')
                   , tdata.rel_is_dependant_2
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion l'allocations enfants 2
      if (    tdata.rel_alloc_begin_2 is not null
          and tdata.rel_alloc_end_2 is not null
          and tdata.rel_alloc_amount_2 is not null) then
        insert into HRM_RELATED_ALLOCATION
                    (HRM_RELATED_ALLOCATION_ID
                   , HRM_RELATED_TO_ID
                   , DIC_ALLOWANCE_TYPE_ID
                   , ALLO_BEGIN
                   , ALLO_END
                   , ALLO_AMOUNT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.hrm_related_to_id_2
                   , '0'
                   , to_date(tdata.rel_alloc_begin_2, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_2, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_2
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion données  enfants 3
      if (    tdata.rel_name_3 is not null
          and tdata.rel_first_name_3 is not null
          and tdata.c_sex_3 is not null) then
        insert into HRM_RELATED_TO
                    (HRM_RELATED_TO_ID
                   , HRM_EMPLOYEE_ID
                   , C_RELATED_TO_TYPE
                   , C_SEX
                   , REL_NAME
                   , REL_FIRST_NAME
                   , REL_BIRTH_DATE
                   , REL_ALLOC_AMOUNT
                   , REL_ALLOC_BEGIN
                   , REL_ALLOC_END
                   , REL_IS_DEPENDANT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (tdata.hrm_related_to_id_3
                   , tdata.HRM_PERSON_ID
                   , '2'
                   , tdata.c_sex_3
                   , tdata.rel_name_3
                   , tdata.rel_first_name_3
                   , to_date(tdata.rel_birth_date_3, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_3
                   , to_date(tdata.rel_alloc_begin_3, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_3, 'DD.MM.YYYY')
                   , tdata.rel_is_dependant_3
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion l'allocations enfants 3
      if (    tdata.rel_alloc_begin_3 is not null
          and tdata.rel_alloc_end_3 is not null
          and tdata.rel_alloc_amount_3 is not null) then
        insert into HRM_RELATED_ALLOCATION
                    (HRM_RELATED_ALLOCATION_ID
                   , HRM_RELATED_TO_ID
                   , DIC_ALLOWANCE_TYPE_ID
                   , ALLO_BEGIN
                   , ALLO_END
                   , ALLO_AMOUNT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.hrm_related_to_id_3
                   , '0'
                   , to_date(tdata.rel_alloc_begin_3, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_3, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_3
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion données  enfants 4
      if (    tdata.rel_name_4 is not null
          and tdata.rel_first_name_4 is not null
          and tdata.c_sex_4 is not null) then
        insert into HRM_RELATED_TO
                    (HRM_RELATED_TO_ID
                   , HRM_EMPLOYEE_ID
                   , C_RELATED_TO_TYPE
                   , C_SEX
                   , REL_NAME
                   , REL_FIRST_NAME
                   , REL_BIRTH_DATE
                   , REL_ALLOC_AMOUNT
                   , REL_ALLOC_BEGIN
                   , REL_ALLOC_END
                   , REL_IS_DEPENDANT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (tdata.hrm_related_to_id_4
                   , tdata.HRM_PERSON_ID
                   , '2'
                   , tdata.c_sex_4
                   , tdata.rel_name_4
                   , tdata.rel_first_name_4
                   , to_date(tdata.rel_birth_date_4, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_4
                   , to_date(tdata.rel_alloc_begin_4, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_4, 'DD.MM.YYYY')
                   , tdata.rel_is_dependant_4
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion l'allocations enfants 4
      if (    tdata.rel_alloc_begin_4 is not null
          and tdata.rel_alloc_end_4 is not null
          and tdata.rel_alloc_amount_4 is not null) then
        insert into HRM_RELATED_ALLOCATION
                    (HRM_RELATED_ALLOCATION_ID
                   , HRM_RELATED_TO_ID
                   , DIC_ALLOWANCE_TYPE_ID
                   , ALLO_BEGIN
                   , ALLO_END
                   , ALLO_AMOUNT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.hrm_related_to_id_4
                   , '0'
                   , to_date(tdata.rel_alloc_begin_4, 'DD.MM.YYYY')
                   , to_date(tdata.rel_alloc_end_4, 'DD.MM.YYYY')
                   , tdata.rel_alloc_amount_4
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion les données pour la comptabilisation 1
      if (tdata.heb_ratio_1 is not null) then
        insert into HRM_EMPLOYEE_BREAK
                    (HRM_EMPLOYEE_BREAK_ID
                   , HRM_EMPLOYEE_ID
                   , HEB_DEFAULT_FLAG
                   , HEB_AN_FLAG
                   , HEB_DEPARTMENT_FLAG
                   , HEB_RATIO
                   , HEB_DEPARTMENT_ID
                   , HEB_DIV_NUMBER
                   , HEB_CDA_NUMBER
                   , HEB_CPN_NUMBER
                   , HEB_PF_NUMBER
                   , HEB_PJ_NUMBER
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.HRM_PERSON_ID
                   , '1'
                   , '1'
                   , '1'
                   , tdata.heb_ratio_1
                   , tdata.heb_department_id_1
                   , tdata.heb_div_number_1
                   , tdata.heb_cda_number_1
                   , tdata.heb_cpn_number_1
                   , tdata.heb_pf_number_1
                   , tdata.heb_pj_number_1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion les données pour la comptabilisation 2
      if (tdata.heb_ratio_2 is not null) then
        insert into HRM_EMPLOYEE_BREAK
                    (HRM_EMPLOYEE_BREAK_ID
                   , HRM_EMPLOYEE_ID
                   , HEB_DEFAULT_FLAG
                   , HEB_AN_FLAG
                   , HEB_DEPARTMENT_FLAG
                   , HEB_RATIO
                   , HEB_DEPARTMENT_ID
                   , HEB_DIV_NUMBER
                   , HEB_CDA_NUMBER
                   , HEB_CPN_NUMBER
                   , HEB_PF_NUMBER
                   , HEB_PJ_NUMBER
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.HRM_PERSON_ID
                   , '1'
                   , '1'
                   , '1'
                   , tdata.heb_ratio_2
                   , tdata.heb_department_id_2
                   , tdata.heb_div_number_2
                   , tdata.heb_cda_number_2
                   , tdata.heb_cpn_number_2
                   , tdata.heb_pf_number_2
                   , tdata.heb_pj_number_2
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion le permis de travail
      if (tdata.dic_work_permit_id is not null) then
        insert into HRM_EMPLOYEE_WK_PERMIT
                    (HRM_EMPLOYEE_WK_PERMIT_ID
                   , HRM_PERSON_ID
                   , WOP_NUMBER_ID
                   , DIC_WORK_PERMIT_ID
                   , WOP_VALID_FROM
                   , WOP_VALID_TO
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.hrm_person_id
                   , tdata.wop_number_id
                   , tdata.dic_work_permit_id
                   , to_date(tdata.wop_valid_from, 'DD.MM.YYYY')
                   , to_date(tdata.wop_valid_to, 'DD.MM.YYYY')
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion des données dans les tables hist
      insert into IMP_HIST_HRM_PERSON
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , PER_LAST_NAME
                 , PER_GENDER
                 , PER_BIRTH_DATE
                 , EMP_STATUS
                 , PER_FIRST_NAME
                 , C_CIVIL_STATUS
                 , EMP_SINGLE_PARENT
                 , C_IN_OUT_STATUS_1
                 , INO_IN_1
                 , C_FINANCIAL_REF_TYPE_1
                 , FIN_SEQUENCE_1
                 , ACS_FINANCIAL_CURRENCY_ID_1
                 , FIN_ACCOUNT_NUMBER_1
                 , HEB_RATIO_1
                 , PER_TITLE
                 , PER_INITIALS
                 , PER_COMMENT
                 , PER_HOME_PHONE
                 , PER_HOME2_PHONE
                 , PER_MOBILE_PHONE
                 , PER_EMAIL
                 , PER_HOMESTREET
                 , PER_HOMECITY
                 , PER_HOMESTATE
                 , PER_HOMEPOSTALCODE
                 , PER_HOMECOUNTRY
                 , EMP_NUMBER
                 , EMP_SECONDARY_KEY
                 , EMP_SOCIAL_SECURITYNO
                 , DIC_WORKREGION_ID
                 , EMP_NATIVE_OF
                 , EMP_CALCULATION
                 , EMP_HOBBIES
                 , PC_LANG_ID
                 , DIC_WORKPLACE_ID
                 , DIC_DEPARTMENT_ID
                 , DIC_NATIONALITY_ID
                 , DIC_CONFESSION_ID
                 , DIC_CANTON_WORK_ID
                 , EMP_SOCIAL_SECURITYNO2
                 , EMP_CERTIF_OBSERVATION
                 , EMP_LPP_CONTRIBUTOR
                 , INO_OUT_1
                 , C_IN_OUT_STATUS_2
                 , INO_IN_2
                 , INO_OUT_2
                 , BAN_CLEAR_1
                 , BAN_NAME1_1
                 , BAN_ZIP_1
                 , FIN_AMOUNT_1
                 , C_FINANCIAL_REF_TYPE_2
                 , FIN_SEQUENCE_2
                 , ACS_FINANCIAL_CURRENCY_ID_2
                 , FIN_ACCOUNT_NUMBER_2
                 , BAN_CLEAR_2
                 , BAN_NAME1_2
                 , BAN_ZIP_2
                 , FIN_AMOUNT_2
                 , REL_NAME_1
                 , REL_FIRST_NAME_1
                 , REL_BIRTH_DATE_1
                 , C_SEX_1
                 , REL_IS_DEPENDANT_1
                 , REL_ALLOC_BEGIN_1
                 , REL_ALLOC_END_1
                 , REL_ALLOC_AMOUNT_1
                 , REL_NAME_2
                 , REL_FIRST_NAME_2
                 , REL_BIRTH_DATE_2
                 , C_SEX_2
                 , REL_IS_DEPENDANT_2
                 , REL_ALLOC_BEGIN_2
                 , REL_ALLOC_END_2
                 , REL_ALLOC_AMOUNT_2
                 , REL_NAME_3
                 , REL_FIRST_NAME_3
                 , REL_BIRTH_DATE_3
                 , C_SEX_3
                 , REL_IS_DEPENDANT_3
                 , REL_ALLOC_BEGIN_3
                 , REL_ALLOC_END_3
                 , REL_ALLOC_AMOUNT_3
                 , REL_NAME_4
                 , REL_FIRST_NAME_4
                 , REL_BIRTH_DATE_4
                 , C_SEX_4
                 , REL_IS_DEPENDANT_4
                 , REL_ALLOC_BEGIN_4
                 , REL_ALLOC_END_4
                 , REL_ALLOC_AMOUNT_4
                 , HEB_DEPARTMENT_ID_1
                 , HEB_DIV_NUMBER_1
                 , HEB_CDA_NUMBER_1
                 , HEB_CPN_NUMBER_1
                 , HEB_PF_NUMBER_1
                 , HEB_PJ_NUMBER_1
                 , HEB_RATIO_2
                 , HEB_DEPARTMENT_ID_2
                 , HEB_DIV_NUMBER_2
                 , HEB_CDA_NUMBER_2
                 , HEB_CPN_NUMBER_2
                 , HEB_PF_NUMBER_2
                 , HEB_PJ_NUMBER_2
                 , WOP_NUMBER_ID
                 , DIC_WORK_PERMIT_ID
                 , WOP_VALID_FROM
                 , WOP_VALID_TO
                 , C_HRM_TAX_CERTIF_TYPE
                 , EMP_TAX_IS_EXPATRIATE
                 , EMP_CANTEEN
                 , EMP_CARRIER_FREE
                 , C_HRM_CANTON_TAX_FEES
                 , EMP_TAX_FEES_DATE
                 , EMP_TAX_FULLFILLED
                 , C_HRM_CANTON_TAX_CAR
                 , EMP_TAX_CAR_DATE
                 , EMP_TAX_CAR_CHECK
                 , PER_ACTIVITY_RATE
                 , FREE1
                 , FREE2
                 , FREE3
                 , FREE4
                 , FREE5
                 , FREE6
                 , FREE7
                 , FREE8
                 , FREE9
                 , FREE10
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.excel_line
                 , tdata.PER_LAST_NAME
                 , tdata.PER_GENDER
                 , tdata.PER_BIRTH_DATE
                 , tdata.EMP_STATUS
                 , tdata.PER_FIRST_NAME
                 , tdata.C_CIVIL_STATUS
                 , tdata.EMP_SINGLE_PARENT
                 , tdata.C_IN_OUT_STATUS_1
                 , tdata.INO_IN_1
                 , tdata.C_FINANCIAL_REF_TYPE_1
                 , tdata.FIN_SEQUENCE_1
                 , tdata.ACS_FINANCIAL_CURRENCY_ID_1
                 , tdata.FIN_ACCOUNT_NUMBER_1
                 , tdata.HEB_RATIO_1
                 , tdata.PER_TITLE
                 , tdata.PER_INITIALS
                 , tdata.PER_COMMENT
                 , tdata.PER_HOME_PHONE
                 , tdata.PER_HOME2_PHONE
                 , tdata.PER_MOBILE_PHONE
                 , tdata.PER_EMAIL
                 , tdata.PER_HOMESTREET
                 , tdata.PER_HOMECITY
                 , tdata.PER_HOMESTATE
                 , tdata.PER_HOMEPOSTALCODE
                 , tdata.PER_HOMECOUNTRY
                 , tdata.EMP_NUMBER
                 , tdata.EMP_SECONDARY_KEY
                 , tdata.EMP_SOCIAL_SECURITYNO
                 , tdata.DIC_WORKREGION_ID
                 , tdata.EMP_NATIVE_OF
                 , tdata.EMP_CALCULATION
                 , tdata.EMP_HOBBIES
                 , tdata.PC_LANG_ID
                 , tdata.DIC_WORKPLACE_ID
                 , tdata.DIC_DEPARTMENT_ID
                 , tdata.DIC_NATIONALITY_ID
                 , tdata.DIC_CONFESSION_ID
                 , tdata.DIC_CANTON_WORK_ID
                 , tdata.EMP_SOCIAL_SECURITYNO2
                 , tdata.EMP_CERTIF_OBSERVATION
                 , tdata.EMP_LPP_CONTRIBUTOR
                 , tdata.INO_OUT_1
                 , tdata.C_IN_OUT_STATUS_2
                 , tdata.INO_IN_2
                 , tdata.INO_OUT_2
                 , tdata.BAN_CLEAR_1
                 , tdata.BAN_NAME1_1
                 , tdata.BAN_ZIP_1
                 , tdata.FIN_AMOUNT_1
                 , tdata.C_FINANCIAL_REF_TYPE_2
                 , tdata.FIN_SEQUENCE_2
                 , tdata.ACS_FINANCIAL_CURRENCY_ID_2
                 , tdata.FIN_ACCOUNT_NUMBER_2
                 , tdata.BAN_CLEAR_2
                 , tdata.BAN_NAME1_2
                 , tdata.BAN_ZIP_2
                 , tdata.FIN_AMOUNT_2
                 , tdata.REL_NAME_1
                 , tdata.REL_FIRST_NAME_1
                 , tdata.REL_BIRTH_DATE_1
                 , tdata.C_SEX_1
                 , tdata.REL_IS_DEPENDANT_1
                 , tdata.REL_ALLOC_BEGIN_1
                 , tdata.REL_ALLOC_END_1
                 , tdata.REL_ALLOC_AMOUNT_1
                 , tdata.REL_NAME_2
                 , tdata.REL_FIRST_NAME_2
                 , tdata.REL_BIRTH_DATE_2
                 , tdata.C_SEX_2
                 , tdata.REL_IS_DEPENDANT_2
                 , tdata.REL_ALLOC_BEGIN_2
                 , tdata.REL_ALLOC_END_2
                 , tdata.REL_ALLOC_AMOUNT_2
                 , tdata.REL_NAME_3
                 , tdata.REL_FIRST_NAME_3
                 , tdata.REL_BIRTH_DATE_3
                 , tdata.C_SEX_3
                 , tdata.REL_IS_DEPENDANT_3
                 , tdata.REL_ALLOC_BEGIN_3
                 , tdata.REL_ALLOC_END_3
                 , tdata.REL_ALLOC_AMOUNT_3
                 , tdata.REL_NAME_4
                 , tdata.REL_FIRST_NAME_4
                 , tdata.REL_BIRTH_DATE_4
                 , tdata.C_SEX_4
                 , tdata.REL_IS_DEPENDANT_4
                 , tdata.REL_ALLOC_BEGIN_4
                 , tdata.REL_ALLOC_END_4
                 , tdata.REL_ALLOC_AMOUNT_4
                 , tdata.HEB_DEPARTMENT_ID_1
                 , tdata.HEB_DIV_NUMBER_1
                 , tdata.HEB_CDA_NUMBER_1
                 , tdata.HEB_CPN_NUMBER_1
                 , tdata.HEB_PF_NUMBER_1
                 , tdata.HEB_PJ_NUMBER_1
                 , tdata.HEB_RATIO_2
                 , tdata.HEB_DEPARTMENT_ID_2
                 , tdata.HEB_DIV_NUMBER_2
                 , tdata.HEB_CDA_NUMBER_2
                 , tdata.HEB_CPN_NUMBER_2
                 , tdata.HEB_PF_NUMBER_2
                 , tdata.HEB_PJ_NUMBER_2
                 , tdata.WOP_NUMBER_ID
                 , tdata.DIC_WORK_PERMIT_ID
                 , tdata.WOP_VALID_FROM
                 , tdata.WOP_VALID_TO
                 , tdata.C_HRM_TAX_CERTIF_TYPE
                 , tdata.EMP_TAX_IS_EXPATRIATE
                 , tdata.EMP_CANTEEN
                 , tdata.EMP_CARRIER_FREE
                 , tdata.C_HRM_CANTON_TAX_FEES
                 , tdata.EMP_TAX_FEES_DATE
                 , tdata.EMP_TAX_FULLFILLED
                 , tdata.C_HRM_CANTON_TAX_CAR
                 , tdata.EMP_TAX_CAR_DATE
                 , tdata.EMP_TAX_CAR_CHECK
                 , tdata.PER_ACTIVITY_RATE
                 , tdata.FREE1
                 , tdata.FREE2
                 , tdata.FREE3
                 , tdata.FREE4
                 , tdata.FREE5
                 , tdata.FREE6
                 , tdata.FREE7
                 , tdata.FREE8
                 , tdata.FREE9
                 , tdata.FREE10
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_HRM_PERSON_IMPORT;
end IMP_HRM_PERSON_EMP;
