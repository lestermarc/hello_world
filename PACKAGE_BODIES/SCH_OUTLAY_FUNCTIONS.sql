--------------------------------------------------------
--  DDL for Package Body SCH_OUTLAY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_OUTLAY_FUNCTIONS" 
is
  /**
  * function GetDefaultOutlayCustomer
  * Description : Recherche Débiteur défaut débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_STUDENT_ID : Elève
  */
  function GetDefaultOutlayCustomer(iSCH_STUDENT_ID in number)
    return number
  is
    lnresult number;
  begin
    select PAC_CUSTOM_PARTNER2_ID
      into lnresult
      from SCH_STUDENT
     where SCH_STUDENT_ID = iSCH_STUDENT_ID
       and nvl(STU_OUT_MIXED_BILLING, 0) = 0;

    return lnresult;
  exception
    when others then
      return null;
  end;

  /**
  * procedure GetOutlayTariffIndiv
  * Description : Recherche du tarif de prestation
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_PRC_INDIV_SALE_TARIFF : procedure indiv
  * @param   iSCH_STUDENT_ID : Elève
  * @param   iPAC_CUSTOM_PARTNER_ID : Client
  * @param   iEOU_BASIS_QUANTITY : Quantité de base
  * @param   iEOU_VALUE_DATE : Date valeur
  * @param   iSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   ioPrice : Montant indiv
  * @param   ioExecStandard : Execution du standard
  */
  procedure GetOutlayTariffIndiv(
    iSCH_PRC_INDIV_SALE_TARIFF in     varchar2
  , iSCH_STUDENT_ID            in     number
  , iPAC_CUSTOM_PARTNER_ID     in     number
  , iEOU_BASIS_QUANTITY        in     number
  , iEOU_VALUE_DATE            in     date
  , iSCH_OUTLAY_CATEGORY_ID    in     number
  , ioPrice                    in out number
  , ioExecStandard             in out integer
  )
  is
    lvPrcSql varchar2(2000);
  begin
    lvPrcSql  := ' begin ';
    lvPrcSql  :=
      lvPrcSql ||
      iSCH_PRC_INDIV_SALE_TARIFF ||
      '(:iSCH_STUDENT_ID,' ||
      ' :iPAC_CUSTOM_PARTNER_ID,' ||
      ' :iEOU_BASIS_QUANTITY,' ||
      ' :iEOU_VALUE_DATE,' ||
      ' :iSCH_OUTLAY_CATEGORY_ID,' ||
      ' :ioPrice,' ||
      ' :ioExecStandard);';
    lvPrcSql  := lvPrcSql || ' end; ';

    execute immediate lvPrcSql
                using in     iSCH_STUDENT_ID
                    , in     iPAC_CUSTOM_PARTNER_ID
                    , in     iEOU_BASIS_QUANTITY
                    , in     iEOU_VALUE_DATE
                    , in     iSCH_OUTLAY_CATEGORY_ID
                    , in out ioPrice
                    , in out ioExecStandard;
  end GetOutlayTariffIndiv;

  /**
  * procedure GetValorizedQuantityIndiv
  * Description : Appel de la procédure individualisée définie dans la configuration
  *               pour le calcul de la quantié valorizée
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   lcSchPrcGetValorizedQty : procedure
  * @param   iEOU_VALUE_DATE : Date valeur
  * @param   iPAC_CUSTOM_PARTNER_ID : Débiteur
  * @param   iSCH_OUTLAY_ID : Prestation
  * @param   iSCH_OUTLAY_CATEGORY : Catégorie de débours
  * @param   iEOU_BASIS_QUANTITY : Quantité de base
  * @param   ioEOU_QTY : Quantité valorizée
  * @param   ioExecStandard : Execution standard
  *
  */
  procedure GetValorizedQuantityIndiv(
    lcSchPrcGetValorizedQty        varchar2
  , iEOU_VALUE_DATE         in     date
  , iPAC_CUSTOM_PARTNER_ID  in     number
  , iSCH_OUTLAY_ID          in     number
  , iSCH_OUTLAY_CATEGORY_ID in     number
  , iEOU_BASIS_QUANTITY     in     number
  , ioEOU_QTY               in out number
  , ioExecStandard          in out integer
  )
  is
    lvPrcSql varchar2(2000);
  begin
    lvPrcSql  := ' begin ';
    lvPrcSql  :=
      lvPrcSql ||
      lcSchPrcGetValorizedQty ||
      '(:iEOU_VALUE_DATE,' ||
      ' :iPAC_CUSTOM_PARTNER_ID,' ||
      ' :iSCH_OUTLAY_ID,' ||
      ' :iSCH_OUTLAY_CATEGORY_ID,' ||
      ' :iEOU_BASIS_QUANTITY,' ||
      ' :ioEOU_QTY,' ||
      ' :ioExecStandard);';
    lvPrcSql  := lvPrcSql || ' end; ';

    execute immediate lvPrcSql
                using in     iEOU_VALUE_DATE
                    , in     iPAC_CUSTOM_PARTNER_ID
                    , in     iSCH_OUTLAY_ID
                    , in     iSCH_OUTLAY_CATEGORY_ID
                    , in     iEOU_BASIS_QUANTITY
                    , in out ioEOU_QTY
                    , in out ioExecStandard;
  end GetValorizedQuantityIndiv;

  /**
  * procedure SelectOutlay
  * Description : Sélection des débours via la table COM_LIST_ID_TEMP pour les
  *              traitements de génération des associations débours - débiteurs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   V_OUT_MAJOR_REF_FROM : référence principale de
  * @param   V_OUT_MAJOR_REF_TO : référence principale à
  * @param   V_OUT_SECOND_REF_FROM : référence secondaire de
  * @param   V_OUT_SECOND_REF_TO varchar2 : référence secondaire à
  */
  procedure SelectOutlay(V_OUT_MAJOR_REF_FROM varchar2, V_OUT_MAJOR_REF_TO varchar2, V_OUT_SECOND_REF_FROM varchar2, V_OUT_SECOND_REF_TO varchar2)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_OUTLAY_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct out.SCH_OUTLAY_ID
                    , 'SCH_OUTLAY_ID'
                 from SCH_OUTLAY out
                where (    (    V_OUT_MAJOR_REF_FROM is null
                            and V_OUT_MAJOR_REF_TO is null)
                       or out.OUT_MAJOR_REFERENCE between nvl(V_OUT_MAJOR_REF_FROM, out.OUT_MAJOR_REFERENCE) and nvl(V_OUT_MAJOR_REF_TO
                                                                                                                   , out.OUT_MAJOR_REFERENCE)
                      )
                  and (    (    V_OUT_SECOND_REF_FROM is null
                            and V_OUT_SECOND_REF_TO is null)
                       or out.OUT_SECONDARY_REFERENCE between nvl(V_OUT_SECOND_REF_FROM, out.OUT_SECONDARY_REFERENCE)
                                                          and nvl(V_OUT_SECOND_REF_TO, out.OUT_SECONDARY_REFERENCE)
                      );
  end SelectOutlay;

  /**
  * procedure SelectOutlayCategory
  * Description : Sélection des catégories de débours via la table COM_LIST_ID_TEMP pour les
  *              traitements de génération des associations débours - débiteurs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   V_COU_MAJOR_REF_FROM : référence principale de
  * @param   V_COU_MAJOR_REF_TO : référence principale à
  * @param   V_COU_SECOND_REF_FROM : référence secondaire de
  * @param   V_COU_SECOND_REF_TO varchar2 : référence secondaire à
  */
  procedure SelectOutlayCategory(V_COU_MAJOR_REF_FROM varchar2, V_COU_MAJOR_REF_TO varchar2, V_COU_SECOND_REF_FROM varchar2, V_COU_SECOND_REF_TO varchar2)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_OUTLAY_CATEGORY_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct COU.SCH_OUTLAY_CATEGORY_ID
                    , 'SCH_OUTLAY_CATEGORY_ID'
                 from SCH_OUTLAY_CATEGORY COU
                where COU.SCH_OUTLAY_ID in(select COM_LIST_ID_TEMP_ID
                                             from COM_LIST_ID_TEMP
                                            where LID_CODE = 'SCH_OUTLAY_ID')
                  and (    (    V_COU_MAJOR_REF_FROM is null
                            and V_COU_MAJOR_REF_TO is null)
                       or COU.COU_MAJOR_REFERENCE between nvl(V_COU_MAJOR_REF_FROM, COU.COU_MAJOR_REFERENCE) and nvl(V_COU_MAJOR_REF_TO
                                                                                                                   , COU.COU_MAJOR_REFERENCE)
                      )
                  and (    (    V_COU_SECOND_REF_FROM is null
                            and V_COU_SECOND_REF_TO is null)
                       or COU.COU_SECONDARY_REFERENCE between nvl(V_COU_SECOND_REF_FROM, COU.COU_SECONDARY_REFERENCE)
                                                          and nvl(V_COU_SECOND_REF_TO, COU.COU_SECONDARY_REFERENCE)
                      );
  end SelectOutlayCategory;

  /**
  * procedure SelectCustomers
  * Description : Sélection des débiteurs via la table COM_LIST_ID_TEMP pour les
  *              traitements de génération des associations débours - débiteurs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPER_NAME_FROM : Nom 1 de
  * @param   aPER_NAME_TO : Nom 1 à
  * @param   aDIC_INVOICING_PERIOD_ID : Périodicité de facturation
  * @param   aDIC_CUSTOMER_TYPE_ID varchar2
  */
  procedure SelectCustomers(aPER_NAME_FROM varchar2, aPER_NAME_TO varchar2, aDIC_INVOICING_PERIOD_ID varchar2 default null, aDIC_CUSTOMER_TYPE_ID varchar2)
  is
    aInsertQry varchar2(4000);
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'PAC_CUSTOM_PARTNER_ID';

    -- Construction requête d'insertion
    aInsertQry  :=
      'insert into COM_LIST_ID_TEMP' ||
      '(COM_LIST_ID_TEMP_ID' ||
      ' , LID_CODE' ||
      '  )' ||
      ' select distinct PER.PAC_PERSON_ID' ||
      '      , ''PAC_CUSTOM_PARTNER_ID'' ' ||
      '   from SCH_STUDENT_S_CUSTOMER STU' ||
      '      , PAC_PERSON PER' ||
      '      , PAC_CUSTOM_PARTNER CUS' ||
      '  where STU.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID' ||
      '    and PER.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID' ||
      '    and PER.PER_NAME between nvl(:aPER_NAME_FROM, PER.PER_NAME)' ||
      '                         and nvl(:aPER_NAME_TO, PER.PER_NAME)' ||
      '    and (:aDIC_INVOICING_PERIOD_ID is null or CUS.DIC_INVOICING_PERIOD_ID = :aDIC_INVOICING_PERIOD_ID) ' ||
      '    and (:aDIC_CUSTOMER_TYPE_ID is null or STU.DIC_CUSTOMER_TYPE_ID = :aDIC_CUSTOMER_TYPE_ID) ';

    execute immediate aInsertQry
                using aPER_NAME_FROM, aPER_NAME_TO, aDIC_INVOICING_PERIOD_ID, aDIC_INVOICING_PERIOD_ID, aDIC_CUSTOMER_TYPE_ID, aDIC_CUSTOMER_TYPE_ID;
  end SelectCustomers;

  /**
  * procedure SelectStudents
  * Description : Sélection des élèves via la table COM_LIST_ID_TEMP pour les
  *              traitements de génération des associations débours - débiteurs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSTU_NAME_FROM : Nom de
  * @param   aSTU_NAME_TO : Nom à
  * @param   aSTU_ACCOUNT_NUMBER_FROM : N° de compte de
  * @param   aSTU_ACCOUNT_NUMBER_TO : N° de compte à
  * @param   aSTU_ENTRY_DATE_FROM : Date entrée de
  * @param   aSTU_ENTRY_DATE_TO : Dtae entrée à
  * @param   aSTU_EXIT_DATE_FROM : Date sortie de
  * @param   aSTU_EXIT_DATE_TO : Date sortie à
  * @param   aSTUDENT_STATUS : Status élève
  * @param   aEDUCATION_DEGREE : Degré d'éducation
  * @param   aSTU_SCHOOL_YEAR : Année de scolarité
  * @param   aSTU_CLASS : Classe
  * @param   aRestrictSelection : restriction de la sélection aux élèves facturables
  *                               pour le paramètre période ou groupe de période
  * @param   aSCH_YEAR_PERIOD_ID : Période
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe de Période
  * @param   aContext : context de la sélection
  */
  procedure SelectStudents(
    aSTU_NAME_FROM            varchar2
  , aSTU_NAME_TO              varchar2
  , aSTU_ACCOUNT_NUMBER_FROM  integer
  , aSTU_ACCOUNT_NUMBER_TO    integer
  , aSTU_ENTRY_DATE_FROM      date
  , aSTU_ENTRY_DATE_TO        date
  , aSTU_EXIT_DATE_FROM       date
  , aSTU_EXIT_DATE_TO         date
  , aSTUDENT_STATUS           varchar2
  , aEDUCATION_DEGREE         varchar2
  , aSTU_SCHOOL_YEAR          integer
  , aSTU_CLASS                varchar2
  , aRestrictSelection        integer default 0
  , aSCH_YEAR_PERIOD_ID       number default null
  , aSCH_GROUP_YEAR_PERIOD_ID number default null
  , aContext                  integer default wmNone
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_STUDENT_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct STU.SCH_STUDENT_ID
                    , 'SCH_STUDENT_ID'
                 from SCH_STUDENT STU
                    , SCH_STUDENT_STATUS STA
                    , SCH_EDUCATION_DEGREE DEG
                where STU.SCH_STUDENT_STATUS_ID = STA.SCH_STUDENT_STATUS_ID(+)
                  and STU.SCH_EDUCATION_DEGREE_ID = DEG.SCH_EDUCATION_DEGREE_ID(+)
                  and STU.STU_NAME between nvl(aSTU_NAME_FROM, STU.STU_NAME) and nvl(aSTU_NAME_TO, STU.STU_NAME)
                  and (   aSTU_ACCOUNT_NUMBER_FROM is null
                       or STU.STU_ACCOUNT_NUMBER >= aSTU_ACCOUNT_NUMBER_FROM)
                  and (   aSTU_ACCOUNT_NUMBER_TO is null
                       or STU.STU_ACCOUNT_NUMBER <= aSTU_ACCOUNT_NUMBER_FROM)
                  and (   aSTU_ENTRY_DATE_FROM is null
                       or trunc(STU.STU_ENTRY_DATE) >= trunc(aSTU_ENTRY_DATE_FROM) )
                  and (   aSTU_ENTRY_DATE_TO is null
                       or trunc(STU.STU_ENTRY_DATE) >= trunc(aSTU_ENTRY_DATE_TO) )
                  and (   aSTU_EXIT_DATE_FROM is null
                       or trunc(STU.STU_EXIT_DATE) >= trunc(aSTU_EXIT_DATE_FROM) )
                  and (   aSTU_EXIT_DATE_TO is null
                       or trunc(STU.STU_EXIT_DATE) >= trunc(aSTU_EXIT_DATE_TO) )
                  and (   aSTUDENT_STATUS is null
                       or STA.STA_NAME = aSTUDENT_STATUS)
                  and (   aEDUCATION_DEGREE is null
                       or DEG.DEG_NAME = aEDUCATION_DEGREE)
                  and (   aSTU_SCHOOL_YEAR is null
                       or STU.STU_SCHOOL_YEAR = aSTU_SCHOOL_YEAR)
                  and (   aSTU_CLASS is null
                       or STU.STU_CLASS = aSTU_CLASS)
                  and (   aRestrictSelection = 0
                       or (    aRestrictSelection = 1
                           and nvl(aSCH_YEAR_PERIOD_ID, 0) <> 0
                           and (SCH_ECOLAGE_BILLING.StudentToBill(STU.SCH_STUDENT_ID, aSCH_YEAR_PERIOD_ID, null) = 1)
                          )
                       or (    aRestrictSelection = 1
                           and nvl(aSCH_GROUP_YEAR_PERIOD_ID, 0) <> 0
                           and (SCH_ECOLAGE_BILLING.StudentToBill(STU.SCH_STUDENT_ID, null, aSCH_GROUP_YEAR_PERIOD_ID) = 1)
                          )
                      )
                  and (   aContext = wmNone
                       or aContext = wmGenerateEcoBill
                       or (    aContext = wmGenerateEcoDoc
                           and exists(
                                 select 1
                                   from SCH_BILL_POSITION POS
                                      , SCH_BILL_HEADER HEA
                                  where POS.SCH_STUDENT_ID = STU.SCH_STUDENT_ID
                                    and POS.SCH_BILL_HEADER_ID = HEA.SCH_BILL_HEADER_ID
                                    and HEA.SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
                                    and HEA.DOC_DOCUMENT_ID is null
                                    and HEA.HEA_ECOLAGE = 1)
                          )
                       or (    aContext = wmGenerateDoc
                           and exists(
                                 select 1
                                   from SCH_BILL_POSITION POS
                                      , SCH_BILL_HEADER HEA
                                  where POS.SCH_STUDENT_ID = STU.SCH_STUDENT_ID
                                    and POS.SCH_BILL_HEADER_ID = HEA.SCH_BILL_HEADER_ID
                                    and HEA.SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
                                    and HEA.DOC_DOCUMENT_ID is null
                                    and HEA.HEA_ECOLAGE = 0)
                          )
                       or (    aContext = wmGenerateBill
                           and exists(
                                 select 1
                                   from SCH_ENTERED_OUTLAY EOU
                                  where EOU.SCH_STUDENT_ID = STU.SCH_STUDENT_ID
                                    and EOU.SCH_YEAR_PERIOD_ID in(select LNK.SCH_YEAR_PERIOD_ID
                                                                    from SCH_PERIOD_GRP_PERIOD_LINK LNK
                                                                   where LNK.SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID)
                                    and EOU_STATUS = 1)
                          )
                      );
  end SelectStudents;

  /**
  * procedure SelectCDA
  * Description : Sélection des centres d'analyse via la table COM_LIST_ID_TEMP pour les
  *              traitements de génération des factures
  *
  * @created RBA
  * @lastUpdate
  * @public
  * @param   aACS_CDA_ACCOUNT_ID : Identifiant du centre d'analyse
  *
  */
  procedure SelectCDA(aACS_CDA_ACCOUNT_ID number)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'CDA_ACC_SCH';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct ACS_CDA_ACCOUNT_ID
                    , 'CDA_ACC_SCH'
                 from ACS_CDA_ACCOUNT
                where aACS_CDA_ACCOUNT_ID = 0
                   or ACS_CDA_ACCOUNT_ID = aACS_CDA_ACCOUNT_ID;
  end SelectCDA;

  /**
  * procedure GenTemporaryAssociations
  * Description : Génération des associations temporaires
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aUseStudents : Génération associations par élèves
  * @param   aUseOutlayCatégory : Génération associations par catégorie de débours
  * @param   aUseEcolageCategory : Génération associations par catégorie d'écolages
  * @param   aOutlayAssociation : Associations débours - débiteur ou ecolages - débiteurs
  * @param   aDefaultSelected : Enregistrement sélectionnés par défaut
  * @param   aForCreate : Génération pour génération de nouvelles associations, sinon
  *          sélection pour suppression
  * @param   aUsedInPeriodicBilling : Utilisable en facturation périodique
  * @param   aValidDateFrom : date de validité
  * @param   aValidDateTo : date de validité
  * @param   aPercent : % de prise en charge
  * @param   aConvertFactor : Facteur de conversion
  * @param   aAcsAccountId : Centre d'analyse
  */
  procedure GenTemporaryAssociations(
    aUseStudents           integer
  , aUseOutlayCategory     integer
  , aUseEcolageCategory    integer
  , aOutlayAssociation     integer
  , aDefaultSelected       integer default 1
  , aForCreate             integer default 1
  , aUsedInPeriodicBilling integer default 0
  , aValidDateFrom         date default null
  , aValidDateTo           date default null
  , aPercent               number default null
  , aConvertFactor         number default null
  , aAcsAccountId          number default null
  )
  is
    aInsertQuery varchar2(32000);
  begin
    -- Suppression des enregistrements éventuels de la session
    delete from SCH_CUSTOMERS_ASSOC_TMP;

    -- Génération de nouvelles associations
    if aForCreate = 1 then
      -- Génération des associations temporaires
      aInsertQuery  :=
        'insert into SCH_CUSTOMERS_ASSOC_TMP( ' ||
        '            SCH_CUSTOMERS_ASSOC_TMP_ID ' ||
        '          , PAC_CUSTOM_PARTNER_ID ' ||
        '          , SCH_STUDENT_ID ' ||
        '          , SCH_OUTLAY_ID ' ||
        '          , SCH_OUTLAY_CATEGORY_ID ' ||
        '          , SCH_ECOLAGE_ID ' ||
        '          , SCH_ECOLAGE_CATEGORY_ID ' ||
        '          , CAS_SELECT ' ||
        '          , CAS_PERIODIC_BILLING ' ||
        '          , CAS_VALIDITY_DATE ' ||
        '          , CAS_VALIDITY_DATE_TO ' ||
        '          , CAS_PERCENT ' ||
        '          , CAS_CONV_FACTOR ' ||
        '          , ACS_CDA_ACCOUNT_ID ' ||
        '          ) ' ||
        '     select GetNewId ' ||
        '          , PAC_CUSTOM_PARTNER_ID ' ||
        '          , SCH_STUDENT_ID ' ||
        '          , SCH_OUTLAY_ID ' ||
        '          , SCH_OUTLAY_CATEGORY_ID ' ||
        '          , SCH_ECOLAGE_ID ' ||
        '          , SCH_ECOLAGE_CATEGORY_ID ' ||
        '          , :aDefaultSelected ' ||
        '          , :aUsedInPeriodicBilling ' ||
        '          , :aValidDateFrom ' ||
        '          , :aValidDateTo ' ||
        '          , :aPercent ' ||
        '          , :aConvertFactor ' ||
        '          , :aAcsAccountId ' ||
        '       from ';

      -- Associations débours - débiteurs
      if aOutlayAssociation = 1 then
        -- Associations catégories de débours débiteurs
        if aUseOutlayCategory = 1 then
          aInsertQuery  :=
            aInsertQuery ||
            '            (Select Distinct CAT.SCH_OUTLAY_ID ' ||
            '                   , CAT.SCH_OUTLAY_CATEGORY_ID ' ||
            '                   , null SCH_ECOLAGE_ID ' ||
            '                   , null SCH_ECOLAGE_CATEGORY_ID ' ||
            '                from COM_LIST_ID_TEMP COM2 ' ||
            '                   , COM_LIST_ID_TEMP COM3 ' ||
            '                   , SCH_OUTLAY_CATEGORY CAT ' ||
            '               where COM2.LID_CODE = ''SCH_OUTLAY_ID'' ' ||
            '                 and COM3.LID_CODE = ''SCH_OUTLAY_CATEGORY_ID'' ' ||
            '                 and CAT.SCH_OUTLAY_ID = COM2.COM_LIST_ID_TEMP_ID ' ||
            '                 and CAT.SCH_OUTLAY_CATEGORY_ID = COM3.COM_LIST_ID_TEMP_ID) ';
        else
          aInsertQuery  :=
            aInsertQuery ||
            '            (Select Distinct COM2.COM_LIST_ID_TEMP_ID SCH_OUTLAY_ID ' ||
            '                   , null SCH_OUTLAY_CATEGORY_ID ' ||
            '                   , null SCH_ECOLAGE_ID ' ||
            '                   , null SCH_ECOLAGE_CATEGORY_ID ' ||
            '               from COM_LIST_ID_TEMP COM2 ' ||
            '              where COM2.LID_CODE = ''SCH_OUTLAY_ID'') OUT ';
        end if;
      -- Associations Ecolages débiteurs
      else
        -- Associations catégories d'écolages débiteurs
        if aUseEcolageCategory = 1 then
          aInsertQuery  :=
            aInsertQuery ||
            '            (Select Distinct null SCH_OUTLAY_ID ' ||
            '                   , null SCH_OUTLAY_CATEGORY_ID ' ||
            '                   , CAT.SCH_ECOLAGE_ID ' ||
            '                   , CAT.SCH_ECOLAGE_CATEGORY_ID ' ||
            '                from COM_LIST_ID_TEMP COM2 ' ||
            '                   , COM_LIST_ID_TEMP COM3 ' ||
            '                   , SCH_ECOLAGE_CATEGORY CAT ' ||
            '               where COM2.LID_CODE = ''SCH_ECOLAGE_ID'' ' ||
            '                 and COM3.LID_CODE = ''SCH_ECOLAGE_CATEGORY_ID'' ' ||
            '                 and CAT.SCH_ECOLAGE_ID = COM2.COM_LIST_ID_TEMP_ID ' ||
            '                 and CAT.SCH_ECOLAGE_CATEGORY_ID = COM3.COM_LIST_ID_TEMP_ID) ';
        else
          aInsertQuery  :=
            aInsertQuery ||
            '            (Select Distinct null SCH_OUTLAY_ID ' ||
            '                  , null SCH_OUTLAY_CATEGORY_ID ' ||
            '                  , COM2.COM_LIST_ID_TEMP_ID SCH_ECOLAGE_ID ' ||
            '                  , null SCH_ECOLAGE_CATEGORY_ID ' ||
            '               from COM_LIST_ID_TEMP COM2 ' ||
            '              where COM2.LID_CODE = ''SCH_ECOLAGE_ID'') OUT ';
        end if;
      end if;

      if aUseStudents = 1 then
        aInsertQuery  :=
          aInsertQuery ||
          '                ,(Select Distinct COM2.COM_LIST_ID_TEMP_ID PAC_CUSTOM_PARTNER_ID ' ||
          '                      , STU.SCH_STUDENT_ID' ||
          '                   from SCH_STUDENT STU ' ||
          '                      , COM_LIST_ID_TEMP COM1' ||
          '                      , COM_LIST_ID_TEMP COM2' ||
          '                      , SCH_STUDENT_S_CUSTOMER SCU' ||
          '                  where STU.SCH_STUDENT_ID = COM1.COM_LIST_ID_TEMP_ID ' ||
          '                    and COM1.LID_CODE = ''SCH_STUDENT_ID'' ' ||
          '                    and COM2.LID_CODE = ''PAC_CUSTOM_PARTNER_ID'' ' ||
          '                    and STU.SCH_STUDENT_ID = SCU.SCH_STUDENT_ID ' ||
          '                    and SCU.PAC_CUSTOM_PARTNER_ID = COM2.COM_LIST_ID_TEMP_ID) ';
      else
        aInsertQuery  :=
          aInsertQuery ||
          '                ,(Select Distinct COM1.COM_LIST_ID_TEMP_ID PAC_CUSTOM_PARTNER_ID ' ||
          '                   from COM_LIST_ID_TEMP COM1 ' ||
          '                  where COM1.LID_CODE = ''PAC_CUSTOM_PARTNER_ID'') CUS, ' ||
          '                (Select null SCH_STUDENT_ID ' ||
          '                   from dual) ';
      end if;

      execute immediate aInsertQuery
                  using aDefaultSelected, aUsedInPeriodicBilling, aValidDateFrom, aValidDateTo, aPercent, aConvertFactor, aAcsAccountId;
    -- Sélection d'associations existantes pour suppression
    else
      aInsertQuery  :=
        ' insert into SCH_CUSTOMERS_ASSOC_TMP( ' ||
        '             SCH_CUSTOMERS_ASSOC_TMP_ID ' ||
        '           , PAC_CUSTOM_PARTNER_ID ' ||
        '           , SCH_STUDENT_ID ' ||
        '           , SCH_OUTLAY_ID ' ||
        '           , SCH_OUTLAY_CATEGORY_ID ' ||
        '           , SCH_ECOLAGE_ID ' ||
        '           , SCH_ECOLAGE_CATEGORY_ID ' ||
        '           , CAS_SELECT ' ||
        '           , CAS_PERIODIC_BILLING ' ||
        '           , CAS_VALIDITY_DATE ' ||
        '           , CAS_VALIDITY_DATE_TO ' ||
        '           , CAS_PERCENT ' ||
        '           , CAS_CONV_FACTOR ' ||
        '           , ACS_CDA_ACCOUNT_ID ' ||
        '           ) ' ||
        '           select SCH_CUSTOMERS_ASSOCIATION_ID ' ||
        '                , PAC_CUSTOM_PARTNER_ID ' ||
        '                , SCH_STUDENT_ID ' ||
        '                , SCH_OUTLAY_ID ' ||
        '                , SCH_OUTLAY_CATEGORY_ID ' ||
        '                , SCH_ECOLAGE_ID ' ||
        '                , SCH_ECOLAGE_CATEGORY_ID ' ||
        '                , :aDefaultSelected ' ||
        '                , :aUsedInPeriodicBilling ' ||
        '                , :aValidDateFrom ' ||
        '                , :aValidDateTo ' ||
        '                , :aPercent ' ||
        '                , :aConvertFactor ' ||
        '                , :aAcsAccountId ' ||
        '             from SCH_CUSTOMERS_ASSOCIATION ' ||
        '            where PAC_CUSTOM_PARTNER_ID in (Select Distinct COM1.COM_LIST_ID_TEMP_ID ' ||
        '                                              from COM_LIST_ID_TEMP COM1 ' ||
        '                                             where COM1.LID_CODE = ''PAC_CUSTOM_PARTNER_ID'') ';

      if aOutlayAssociation = 1 then
        aInsertQuery  :=
          aInsertQuery ||
          '              and SCH_OUTLAY_ID in (Select Distinct COM2.COM_LIST_ID_TEMP_ID ' ||
          '                                      from COM_LIST_ID_TEMP COM2 ' ||
          '                                     where COM2.LID_CODE = ''SCH_OUTLAY_ID'') ';

        if aUseOutlayCategory = 1 then
          aInsertQuery  :=
            aInsertQuery ||
            '              and SCH_OUTLAY_CATEGORY_ID in (Select Distinct COM2.COM_LIST_ID_TEMP_ID SCH_OUTLAY_ID ' ||
            '                                               from COM_LIST_ID_TEMP COM2 ' ||
            '                                              where COM2.LID_CODE = ''SCH_OUTLAY_CATEGORY_ID'') ';
        end if;
      else
        aInsertQuery  :=
          aInsertQuery ||
          '              and SCH_ECOLAGE_ID in (Select Distinct COM2.COM_LIST_ID_TEMP_ID ' ||
          '                                       from COM_LIST_ID_TEMP COM2 ' ||
          '                                      where COM2.LID_CODE = ''SCH_ECOLAGE_ID'') ';

        if aUseEcolageCategory = 1 then
          aInsertQuery  :=
            aInsertQuery ||
            '              and SCH_ECOLAGE_CATEGORY_ID in (Select Distinct COM2.COM_LIST_ID_TEMP_ID SCH_OUTLAY_ID ' ||
            '                                                from COM_LIST_ID_TEMP COM2 ' ||
            '                                               where COM2.LID_CODE = ''SCH_ECOLAGE_CATEGORY_ID'') ';
        end if;
      end if;

      if aUseStudents = 1 then
        aInsertQuery  :=
          aInsertQuery ||
          '              and SCh_STUDENT_ID in (Select Distinct COM2.COM_LIST_ID_TEMP_ID SCH_STUDENT_ID ' ||
          '                                                from COM_LIST_ID_TEMP COM2 ' ||
          '                                               where COM2.LID_CODE = ''SCH_STUDENT_ID'') ';
      end if;

      execute immediate aInsertQuery
                  using aDefaultSelected, aUsedInPeriodicBilling, aValidDateFrom, aValidDateTo, aPercent, aConvertFactor, aAcsAccountId;
    end if;
  end GenTemporaryAssociations;

  /**
  * procedure ProcessTemporaryAssociations
  * Description : Génération des associations, à partir des associations temporaires
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   ablnInsert : = 1 Insertion des éléments sélectionnés.
  *                       = 0 suppression des éléments sélectionnés.
  */
  procedure ProcessTemporaryAssociations(ablnInsert integer default 1)
  is
  begin
    -- Mode insertion de nouveaux éléments
    if ablnInsert = 1 then
      -- Insertion des associations définitives
      insert into SCH_CUSTOMERS_ASSOCIATION
                  (SCH_CUSTOMERS_ASSOCIATION_ID
                 , PAC_CUSTOM_PARTNER_ID
                 , SCH_STUDENT_ID
                 , SCH_OUTLAY_ID
                 , SCH_OUTLAY_CATEGORY_ID
                 , SCH_ECOLAGE_ID
                 , SCH_ECOLAGE_CATEGORY_ID
                 , CAS_VALIDITY_DATE
                 , CAS_VALIDITY_DATE_TO
                 , CAS_CONV_FACTOR
                 , CAS_PERCENT
                 , ACS_CDA_ACCOUNT_ID
                 , A_DATECRE
                 , A_IDCRE
                 , CAS_PERIODIC_BILLING
                  )
        select CAT.SCH_CUSTOMERS_ASSOC_TMP_ID
             , CAT.PAC_CUSTOM_PARTNER_ID
             , CAT.SCH_STUDENT_ID
             , CAT.SCH_OUTLAY_ID
             , CAT.SCH_OUTLAY_CATEGORY_ID
             , CAT.SCH_ECOLAGE_ID
             , CAT.SCH_ECOLAGE_CATEGORY_ID
             , CAT.CAS_VALIDITY_DATE
             , CAT.CAS_VALIDITY_DATE_TO
             , CAT.CAS_CONV_FACTOR
             , CAT.CAS_PERCENT
             , CAT.ACS_CDA_ACCOUNT_ID
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , CAS_PERIODIC_BILLING
          from SCH_CUSTOMERS_ASSOC_TMP CAT
         where CAS_SELECT = 1
           and not exists(
                 select 1
                   from SCH_CUSTOMERS_ASSOCIATION CAS
                  where (    (    CAT.PAC_CUSTOM_PARTNER_ID is null
                              and CAS.PAC_CUSTOM_PARTNER_ID is null)
                         or (    CAT.PAC_CUSTOM_PARTNER_ID is not null
                             and CAS.PAC_CUSTOM_PARTNER_ID = CAT.PAC_CUSTOM_PARTNER_ID)
                        )
                    and (    (    CAT.SCH_STUDENT_ID is null
                              and CAS.SCH_STUDENT_ID is null)
                         or (    CAT.SCH_STUDENT_ID is not null
                             and CAS.SCH_STUDENT_ID = CAT.SCH_STUDENT_ID)
                        )
                    and (    (    CAT.SCH_OUTLAY_ID is null
                              and CAS.SCH_OUTLAY_ID is null)
                         or (    CAT.SCH_OUTLAY_ID is not null
                             and CAS.SCH_OUTLAY_ID = CAT.SCH_OUTLAY_ID) )
                    and (    (    CAT.SCH_OUTLAY_CATEGORY_ID is null
                              and CAS.SCH_OUTLAY_CATEGORY_ID is null)
                         or (    CAT.SCH_OUTLAY_CATEGORY_ID is not null
                             and CAS.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID)
                        )
                    and (    (    CAT.SCH_ECOLAGE_ID is null
                              and CAS.SCH_ECOLAGE_ID is null)
                         or (    CAT.SCH_ECOLAGE_ID is not null
                             and CAS.SCH_ECOLAGE_ID = CAT.SCH_ECOLAGE_ID)
                        )
                    and (    (    CAT.SCH_ECOLAGE_CATEGORY_ID is null
                              and CAS.SCH_ECOLAGE_CATEGORY_ID is null)
                         or (    CAT.SCH_ECOLAGE_CATEGORY_ID is not null
                             and CAS.SCH_ECOLAGE_CATEGORY_ID = CAT.SCH_ECOLAGE_CATEGORY_ID)
                        ) );
    -- Suppression des enregistrement sélectionnés
    else
      delete from SCH_CUSTOMERS_ASSOCIATION
            where SCH_CUSTOMERS_ASSOCIATION_ID in(select CAT.SCH_CUSTOMERS_ASSOC_TMP_ID
                                                    from SCH_CUSTOMERS_ASSOC_TMP CAT
                                                   where CAS_SELECT = 1);
    end if;

    -- Suppresion des enregistrements temporaires
    delete from SCH_CUSTOMERS_ASSOC_TMP CAT
          where CAS_SELECT = 1;
  end ProcessTemporaryAssociations;

  /**
  * procedure CheckAssociationsIntegrity
  * Description : Vérification de l'intégrité des associations
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aCurrentAssociationID : Association en cours d'édition
  * @param   aPAC_CUSTOM_PARTNER_ID : Débiteur
  * @param   aSCH_STUDENT_ID : élève
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aSCH_ECOLAGE_ID : 2colage
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie d'écolage
  * @return  aErrorMsg : Message d'erreur éventuel
  */
  procedure CheckAssociationsIntegrity(
    aCurrentAssociationID           number
  , aPAC_CUSTOM_PARTNER_ID   in     number
  , aSCH_STUDENT_ID          in     number
  , aSCH_OUTLAY_ID           in     number
  , aSCH_OUTLAY_CATEGORY_ID  in     number
  , aSCH_ECOLAGE_ID          in     number
  , aSCH_ECOLAGE_CATEGORY_ID in     number
  , aErrorMsg                in out varchar2
  )
  is
    aExists number;
  begin
    aErrorMsg  := '';

    -- Au moins un débiteur et un debours ou un écolage est nécessaire à
    -- la génération d'une association
    if     nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
       and nvl(aSCH_OUTLAY_ID, 0) = 0
       and nvl(aSCH_ECOLAGE_ID, 0) = 0 then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Au moins un débiteur et un débours ou un écolage sont nécessaires à la génération d''une association');
      return;
    end if;

    -- Vérification de l'unicité
    /*
    begin
      select count(*)
        into aExists
        from SCH_CUSTOMERS_ASSOCIATION
       where ((NVL(aPAC_CUSTOM_PARTNER_ID, 0) = 0 and PAC_CUSTOM_PARTNER_ID is null)
              or (NVL(aPAC_CUSTOM_PARTNER_ID, 0) <> 0 and PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID))
         and ((NVL(aSCH_STUDENT_ID, 0) = 0 and SCH_STUDENT_ID is null)
              or (NVL(aSCH_STUDENT_ID, 0) <> 0 and SCH_STUDENT_ID = aSCH_STUDENT_ID))
         and ((NVL(aSCH_OUTLAY_ID, 0) = 0 and SCH_OUTLAY_ID is null)
              or (NVL(aSCH_OUTLAY_ID, 0) <> 0 and SCH_OUTLAY_ID = aSCH_OUTLAY_ID))
         and ((NVL(aSCH_OUTLAY_CATEGORY_ID, 0) = 0 and SCH_OUTLAY_CATEGORY_ID is null)
              or (NVL(aSCH_OUTLAY_CATEGORY_ID, 0) <> 0 and SCH_OUTLAY_CATEGORY_ID = aSCH_OUTLAY_CATEGORY_ID))
         and ((NVL(aSCH_ECOLAGE_ID, 0) = 0 and SCH_ECOLAGE_ID is null)
              or (NVL(aSCH_ECOLAGE_ID, 0) <> 0 and SCH_ECOLAGE_ID = aSCH_ECOLAGE_ID))
         and ((NVL(aSCH_ECOLAGE_CATEGORY_ID, 0) = 0 and SCH_ECOLAGE_CATEGORY_ID is null)
              or (NVL(aSCH_ECOLAGE_CATEGORY_ID, 0) <> 0 and SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID))
         and (NVL(aCurrentAssociationID,0) = 0 or SCH_CUSTOMERS_ASSOCIATION_ID <> aCurrentAssociationID);

       aErrorMsg := PCS.PC_FUNCTIONS.TranslateWord('Cette association est déjà existante!');
      return;
    exception
      when no_data_found then
        null;
    end;
    */
    -- Vérification de l'intégrité débours - catégorie de débours
    if     nvl(aSCH_OUTLAY_ID, 0) <> 0
       and nvl(aSCH_OUTLAY_CATEGORY_ID, 0) <> 0 then
      begin
        select COU.SCH_OUTLAY_CATEGORY_ID
          into aExists
          from SCH_OUTLAY_CATEGORY COU
         where COU.SCH_OUTLAY_ID = aSCH_OUTLAY_ID
           and COU.SCH_OUTLAY_CATEGORY_ID = aSCH_OUTLAY_CATEGORY_ID;
      exception
        when no_data_found then
          begin
            aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Les débours et catégorie de débours saisis ne correspondent pas!');
            return;
          end;
      end;
    end if;

    -- Vérification de l'intégrité écolage - catégorie d'écolage
    if     nvl(aSCH_ECOLAGE_ID, 0) <> 0
       and nvl(aSCH_ECOLAGE_CATEGORY_ID, 0) <> 0 then
      begin
        select CAT.SCH_ECOLAGE_CATEGORY_ID
          into aExists
          from SCH_ECOLAGE_CATEGORY CAT
         where CAT.SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID
           and CAT.SCH_ECOLAGE_ID = aSCH_ECOLAGE_ID;
      exception
        when no_data_found then
          begin
            aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Les écolage et catégorie d''écolage saisis ne correspondent pas!');
            return;
          end;
      end;
    end if;

    -- Vérification de l'intégrité débiteur - élève
    if     nvl(aSCH_STUDENT_ID, 0) <> 0
       and nvl(aPAC_CUSTOM_PARTNER_ID, 0) <> 0 then
      begin
        select STU.SCH_STUDENT_ID
          into aExists
          from SCH_STUDENT_S_CUSTOMER STU
         where STU.SCH_STUDENT_ID = aSCH_STUDENT_ID
           and STU.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID;
      exception
        when no_data_found then
          begin
            aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Le débiteur et l''élève saisis ne correspondent pas!');
            return;
          end;
      end;
    end if;
  end CheckAssociationsIntegrity;

  /**
  * procedure FlagSelectedAssociations
  * Description : Sélection / Désélection des enregistrement dans la table temporaire
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_CUSTOMERS_ASSOC_TMP_ID : Enregistrement temporaire à flaguer
  * @param   aBlnFlag : Flag / Déflag
  */
  procedure FlagSelectedAssociations(aSCH_CUSTOMERS_ASSOC_TMP_ID number, aBlnFlag integer)
  is
  begin
    update SCH_CUSTOMERS_ASSOC_TMP
       set CAS_SELECT = aBlnFlag
     where (   nvl(aSCH_CUSTOMERS_ASSOC_TMP_ID, 0) = 0
            or SCH_CUSTOMERS_ASSOC_TMP_ID = aSCH_CUSTOMERS_ASSOC_TMP_ID);
  end FlagSelectedAssociations;

  /**
  * procedure GetCustomerByAssociation
  * Description : Recherche de débiteur associé aux éléments saisis lors d'une
  *               saisie de débours ou une facturation d'écolages
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_STUDENT_ID : élève
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aSCH_ECOLAGE_ID : écolage
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie d'écolage
  * @param   aDateValue : Date Valeur
  * @param   aUseCase : Cas d'utilisation (Ecole / Fondations)
  * @return  aPAC_CUSTOM_PARTNER_ID : ID Débiteur
  */
  procedure GetCustomerByAssociation(
    aSCH_STUDENT_ID          in     number
  , aSCH_OUTLAY_ID           in     number
  , aSCH_OUTLAY_CATEGORY_ID  in     number
  , aSCH_ECOLAGE_ID          in     number
  , aSCH_ECOLAGE_CATEGORY_ID in     number
  , aDateValue               in     date default sysdate
  , aUseCase                 in     integer default 0
  , aPAC_CUSTOM_PARTNER_ID   in out number
  )
  is
    -- Curseur de recherche ordonnées des associations
    cursor crCustomersOutAssociations
    is
      select   cas.pac_custom_partner_id
             , cas.sch_outlay_id
             , cas.sch_outlay_category_id
             , cas.sch_student_id
             , cas.cas_decision
             , nvl(cou.cou_decision, 0) cou_decision
             , case
                 when cas.sch_student_id is not null
                 and cas.sch_outlay_id is not null
                 and cas.sch_outlay_category_id is not null then 0
                 when cas.sch_student_id is not null
                 and cas.sch_outlay_id is not null
                 and cas.sch_outlay_category_id is null then 1
                 when cas.sch_student_id is null
                 and cas.sch_outlay_id is not null
                 and cas.sch_outlay_category_id is not null then 2
                 when cas.sch_student_id is null
                 and cas.sch_outlay_id is not null
                 and cas.sch_outlay_category_id is null then 3
               end order_field
          from sch_customers_association cas
             , sch_outlay_category cou
         where cou.sch_outlay_category_id = aSCH_OUTLAY_CATEGORY_ID
           and exists(select 1
                        from sch_student_s_customer stu
                       where stu.sch_student_id = aSCH_STUDENT_ID
                         and (stu.pac_custom_partner_id = cas.pac_custom_partner_id) )
           and (   cas.sch_student_id is null
                or cas.sch_student_id = aSCH_STUDENT_ID)
           and cas.sch_outlay_id = aSCH_OUTLAY_ID
           and (    (cas.sch_outlay_category_id is null)
                or (    aSCH_OUTLAY_CATEGORY_ID is not null
                    and cas.sch_outlay_category_id = aSCH_OUTLAY_CATEGORY_ID) )
           and (trunc(nvl(aDateValue, sysdate) ) between nvl(CAS_VALIDITY_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                                     and nvl(CAS_VALIDITY_DATE_TO, to_date('31.12.2999', 'DD.MM.YYYY') )
               )
           and (   aUseCase = SCH_OUTLAY_BILLING.ucSchooling
                or (    aUseCase = SCH_OUTLAY_BILLING.ucFundation
                    and (   nvl(cou.cou_decision, 0) = 0
                         or (    nvl(cou.cou_decision, 0) = 1
                             and cas_decision is not null) ) )
               )
      order by order_field asc;

    cursor crCustomersEcoAssociations
    is
      select   pac_custom_partner_id
             , sch_Ecolage_id
             , sch_Ecolage_category_id
             , sch_student_id
             , case
                 when sch_student_id is not null
                 and sch_Ecolage_id is not null
                 and sch_Ecolage_category_id is not null then 0
                 when sch_student_id is not null
                 and sch_Ecolage_id is not null
                 and sch_Ecolage_category_id is null then 1
                 when sch_student_id is null
                 and sch_Ecolage_id is not null
                 and sch_Ecolage_category_id is not null then 2
                 when sch_student_id is null
                 and sch_Ecolage_id is not null
                 and sch_Ecolage_category_id is null then 3
               end order_field
          from sch_customers_association cas
         where exists(select 1
                        from sch_student_s_customer stu
                       where stu.sch_student_id = aSCH_STUDENT_ID
                         and (stu.pac_custom_partner_id = cas.pac_custom_partner_id) )
           and (   cas.sch_student_id is null
                or cas.sch_student_id = aSCH_STUDENT_ID)
           and (    (cas.sch_Ecolage_category_id is null)
                or (    aSCH_Ecolage_CATEGORY_ID is not null
                    and cas.sch_Ecolage_category_id = aSCH_Ecolage_CATEGORY_ID) )
           and cas.sch_Ecolage_id = aSCH_Ecolage_ID
      order by order_field asc;

    vSCH_SEARCH_OUT_CUSTOMER_PROC varchar2(255);
    vSCH_SEARCH_ECO_CUSTOMER_PROC varchar2(255);
    vIndivQry                     varchar2(4000);
    vProcResult                   number                               := null;
    tplCustomersOutAssociations   crCustomersOutAssociations%rowtype;
    tplCustomersEcoAssociations   crCustomersEcoAssociations%rowtype;
    liExecStandard                integer;
  begin
    -- Récupérations des éventuelles procédures de recherche indiv.
    vSCH_SEARCH_OUT_CUSTOMER_PROC  := PCS.PC_CONFIG.GetConfig('SCH_SEARCH_OUT_CUSTOMER_PROC');
    vSCH_SEARCH_ECO_CUSTOMER_PROC  := PCS.PC_CONFIG.GetConfig('SCH_SEARCH_ECO_CUSTOMER_PROC');
    liExecStandard                 := 1;

    -- Saisie de débours - recheche indiv
    if     aSCH_OUTLAY_ID is not null
       and vSCH_SEARCH_OUT_CUSTOMER_PROC is not null then
      begin
        vIndivQry  :=
          'begin ' ||
          '  :Result :=  ' ||
          vSCH_SEARCH_OUT_CUSTOMER_PROC ||
          '( ' ||
          '      :aSCH_STUDENT_ID ' ||
          '    , :aSCH_OUTLAY_ID ' ||
          '    , :aSCH_OUTLAY_CATEGORY_ID ' ||
          '    , :aDateValue ' ||
          '    , :ioExecStandard ' ||
          '    ); ' ||
          'end;';

        execute immediate vIndivQry
                    using out vProcResult, in aSCH_STUDENT_ID, in aSCH_OUTLAY_ID, in aSCH_OUTLAY_CATEGORY_ID, in aDateValue, in out liExecStandard;

        if nvl(vProcResult, 0) <> 0 then
          aPAC_CUSTOM_PARTNER_ID  := vProcResult;
        else
          aPAC_CUSTOM_PARTNER_ID  := null;
        end if;
      exception
        when others then
          begin
            aPAC_CUSTOM_PARTNER_ID  := null;
          end;
      end;
    -- Facturation d'écolages - Recherche indiv
    elsif     aSCH_ECOLAGE_ID is not null
          and vSCH_SEARCH_ECO_CUSTOMER_PROC is not null then
      begin
        vIndivQry  :=
          'begin ' ||
          '  :Result :=  ' ||
          vSCH_SEARCH_ECO_CUSTOMER_PROC ||
          '( ' ||
          '      :aSCH_STUDENT_ID ' ||
          '    , :aSCH_ECOLAGE_ID ' ||
          '    , :aSCH_ECOLAGE_CATEGORY_ID ' ||
          '    , :aDatevalue ' ||
          '    , :ioExecStandard ' ||
          '    ); ' ||
          'end;';

        execute immediate vIndivQry
                    using out vProcResult, in aSCH_STUDENT_ID, in aSCH_ECOLAGE_ID, in aSCH_ECOLAGE_CATEGORY_ID, in aDateValue, in out liExecStandard;

        if nvl(vProcResult, 0) <> 0 then
          aPAC_CUSTOM_PARTNER_ID  := vProcResult;
        else
          aPAC_CUSTOM_PARTNER_ID  := null;
        end if;
      exception
        when others then
          begin
            aPAC_CUSTOM_PARTNER_ID  := null;
          end;
      end;
    end if;

    -- Recherche standard
    if liExecStandard = 1 then
      aPAC_CUSTOM_PARTNER_ID  := null;

      -- Débours
      if    nvl(aSCH_OUTLAY_ID, 0) <> 0
         or nvl(aSCH_OUTLAY_CATEGORY_ID, 0) <> 0 then
        begin
          open crCustomersOutAssociations;

          fetch crCustomersOutAssociations
           into tplCustomersOutAssociations;

          if crCustomersOutAssociations%notfound then
            if aUseCase = SCH_OUTLAY_BILLING.ucFundation then
              aPAC_CUSTOM_PARTNER_ID  := null;
            else
              aPAC_CUSTOM_PARTNER_ID  := GetDefaultOutlayCustomer(aSCH_STUDENT_ID);
            end if;
          else
            aPAC_CUSTOM_PARTNER_ID  := tplCustomersOutAssociations.PAC_CUSTOM_PARTNER_ID;
          end if;

          close crCustomersOutAssociations;
        exception
          when others then
            begin
              close crCustomersOutAssociations;

              aPAC_CUSTOM_PARTNER_ID  := null;
            end;
        end;
      --Ecolages
      elsif    nvl(aSCH_ECOLAGE_ID, 0) <> 0
            or nvl(aSCH_ECOLAGE_CATEGORY_ID, 0) <> 0 then
        begin
          open crCustomersEcoAssociations;

          fetch crCustomersEcoAssociations
           into tplCustomersEcoAssociations;

          if crCustomersEcoAssociations%notfound then
            aPAC_CUSTOM_PARTNER_ID  := null;
          else
            aPAC_CUSTOM_PARTNER_ID  := tplCustomersEcoAssociations.PAC_CUSTOM_PARTNER_ID;
          end if;

          close crCustomersEcoAssociations;
        exception
          when others then
            begin
              close crCustomersEcoAssociations;

              aPAC_CUSTOM_PARTNER_ID  := null;
            end;
        end;
      end if;
    end if;
  end GetCustomerByAssociation;

  /**
  * procedure CopyFreeDataFromEnteredOutlay
  * Description : Copie des données libres depuis les débours entrés
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aSCH_ENTERED_OUTLAY_ID : débours saisi
  */
  procedure CopyFreeDataFromEnteredOutlay(iSCH_ENTERED_OUTLAY_ID_FROM in number, iSCH_ENTERED_OUTLAY_ID_TO in number)
  is
  begin
    insert into SCH_FREE_DATA
                (SCH_FREE_DATA_ID
               , SCH_ENTERED_OUTLAY_ID
               , DIC_SCH_FREE_TABLE1_ID
               , DIC_SCH_FREE_TABLE2_ID
               , DIC_SCH_FREE_TABLE3_ID
               , DIC_SCH_FREE_TABLE4_ID
               , DIC_SCH_FREE_TABLE5_ID
               , SFD_ALPHA_SHORT_1
               , SFD_ALPHA_SHORT_2
               , SFD_ALPHA_SHORT_3
               , SFD_ALPHA_SHORT_4
               , SFD_ALPHA_SHORT_5
               , SFD_ALPHA_LONG_1
               , SFD_ALPHA_LONG_2
               , SFD_ALPHA_LONG_3
               , SFD_ALPHA_LONG_4
               , SFD_ALPHA_LONG_5
               , SFD_INTEGER_1
               , SFD_INTEGER_2
               , SFD_INTEGER_3
               , SFD_INTEGER_4
               , SFD_INTEGER_5
               , SFD_BOOLEAN_1
               , SFD_BOOLEAN_2
               , SFD_BOOLEAN_3
               , SFD_BOOLEAN_4
               , SFD_BOOLEAN_5
               , SFD_DECIMAL_1
               , SFD_DECIMAL_2
               , SFD_DECIMAL_3
               , SFD_DECIMAL_4
               , SFD_DECIMAL_5
               , SFD_DATE_1
               , SFD_DATE_2
               , SFD_DATE_3
               , SFD_DATE_4
               , SFD_DATE_5
               , A_DATECRE
               , A_IDCRE
               , SFD_CATEGORY_COPY
               , SFD_TRANSFERT
                )
      select GetNewId
           , iSCH_ENTERED_OUTLAY_ID_TO
           , DIC_SCH_FREE_TABLE1_ID
           , DIC_SCH_FREE_TABLE2_ID
           , DIC_SCH_FREE_TABLE3_ID
           , DIC_SCH_FREE_TABLE4_ID
           , DIC_SCH_FREE_TABLE5_ID
           , SFD_ALPHA_SHORT_1
           , SFD_ALPHA_SHORT_2
           , SFD_ALPHA_SHORT_3
           , SFD_ALPHA_SHORT_4
           , SFD_ALPHA_SHORT_5
           , SFD_ALPHA_LONG_1
           , SFD_ALPHA_LONG_2
           , SFD_ALPHA_LONG_3
           , SFD_ALPHA_LONG_4
           , SFD_ALPHA_LONG_5
           , SFD_INTEGER_1
           , SFD_INTEGER_2
           , SFD_INTEGER_3
           , SFD_INTEGER_4
           , SFD_INTEGER_5
           , SFD_BOOLEAN_1
           , SFD_BOOLEAN_2
           , SFD_BOOLEAN_3
           , SFD_BOOLEAN_4
           , SFD_BOOLEAN_5
           , SFD_DECIMAL_1
           , SFD_DECIMAL_2
           , SFD_DECIMAL_3
           , SFD_DECIMAL_4
           , SFD_DECIMAL_5
           , SFD_DATE_1
           , SFD_DATE_2
           , SFD_DATE_3
           , SFD_DATE_4
           , SFD_DATE_5
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , 0
           , SFD_TRANSFERT
        from SCH_FREE_DATA
       where SCH_ENTERED_OUTLAY_ID = iSCH_ENTERED_OUTLAY_ID_FROM;
  end CopyFreeDataFromEnteredOutlay;

  /**
  * procedure CopyFreeDataFromOutlay
  * Description : Copie des données libres depuis les débours si besoin
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aSCH_ENTERED_OUTLAY_ID : débours saisi
  */
  procedure CopyFreeDataFromOutlay(aSCH_OUTLAY_ID in number, aSCH_OUTLAY_CATEGORY_ID in number, aSCH_ENTERED_OUTLAY_ID in number default null)
  is
    cursor crFreeData
    is
      select *
        from SCH_FREE_DATA
       where nvl(aSCH_ENTERED_OUTLAY_ID, 0) <> 0
         and SCH_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID;

    tplFreeData crFreeData%rowtype;
  begin
    -- Copie des données libres du débours sur la catégorie.
    if nvl(aSCH_ENTERED_OUTLAY_ID, 0) = 0 then
      insert into SCH_FREE_DATA
                  (SCH_FREE_DATA_ID
                 , SCH_OUTLAY_CATEGORY_ID
                 , DIC_SCH_FREE_TABLE1_ID
                 , DIC_SCH_FREE_TABLE2_ID
                 , DIC_SCH_FREE_TABLE3_ID
                 , DIC_SCH_FREE_TABLE4_ID
                 , DIC_SCH_FREE_TABLE5_ID
                 , SFD_ALPHA_SHORT_1
                 , SFD_ALPHA_SHORT_2
                 , SFD_ALPHA_SHORT_3
                 , SFD_ALPHA_SHORT_4
                 , SFD_ALPHA_SHORT_5
                 , SFD_ALPHA_LONG_1
                 , SFD_ALPHA_LONG_2
                 , SFD_ALPHA_LONG_3
                 , SFD_ALPHA_LONG_4
                 , SFD_ALPHA_LONG_5
                 , SFD_INTEGER_1
                 , SFD_INTEGER_2
                 , SFD_INTEGER_3
                 , SFD_INTEGER_4
                 , SFD_INTEGER_5
                 , SFD_BOOLEAN_1
                 , SFD_BOOLEAN_2
                 , SFD_BOOLEAN_3
                 , SFD_BOOLEAN_4
                 , SFD_BOOLEAN_5
                 , SFD_DECIMAL_1
                 , SFD_DECIMAL_2
                 , SFD_DECIMAL_3
                 , SFD_DECIMAL_4
                 , SFD_DECIMAL_5
                 , SFD_DATE_1
                 , SFD_DATE_2
                 , SFD_DATE_3
                 , SFD_DATE_4
                 , SFD_DATE_5
                 , A_DATECRE
                 , A_IDCRE
                 , SFD_CATEGORY_COPY
                 , SFD_TRANSFERT
                  )
        select GetNewId
             , aSCH_OUTLAY_CATEGORY_ID
             , DIC_SCH_FREE_TABLE1_ID
             , DIC_SCH_FREE_TABLE2_ID
             , DIC_SCH_FREE_TABLE3_ID
             , DIC_SCH_FREE_TABLE4_ID
             , DIC_SCH_FREE_TABLE5_ID
             , SFD_ALPHA_SHORT_1
             , SFD_ALPHA_SHORT_2
             , SFD_ALPHA_SHORT_3
             , SFD_ALPHA_SHORT_4
             , SFD_ALPHA_SHORT_5
             , SFD_ALPHA_LONG_1
             , SFD_ALPHA_LONG_2
             , SFD_ALPHA_LONG_3
             , SFD_ALPHA_LONG_4
             , SFD_ALPHA_LONG_5
             , SFD_INTEGER_1
             , SFD_INTEGER_2
             , SFD_INTEGER_3
             , SFD_INTEGER_4
             , SFD_INTEGER_5
             , SFD_BOOLEAN_1
             , SFD_BOOLEAN_2
             , SFD_BOOLEAN_3
             , SFD_BOOLEAN_4
             , SFD_BOOLEAN_5
             , SFD_DECIMAL_1
             , SFD_DECIMAL_2
             , SFD_DECIMAL_3
             , SFD_DECIMAL_4
             , SFD_DECIMAL_5
             , SFD_DATE_1
             , SFD_DATE_2
             , SFD_DATE_3
             , SFD_DATE_4
             , SFD_DATE_5
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , 0
             , 0
          from SCH_FREE_DATA
         where SCH_OUTLAY_ID = aSCH_OUTLAY_ID
           and SFD_CATEGORY_COPY = 1
           and nvl(aSCH_OUTLAY_ID, 0) <> 0
           and nvl(aSCH_OUTLAY_CATEGORY_ID, 0) <> 0;
    -- Copie des données libres de la catégorie, sur le débours saisis (la fusion donnée libre
    -- débours, donnée libre catégorie à préalablement été effectuée au besoin)
    else
      -- la donnée libre existe-elle déjà
      open crFreeData;

      fetch crFreeData
       into tplFreeData;

      if crFreeData%found then
        update SCH_FREE_DATA
           set DIC_SCH_FREE_TABLE1_ID = nvl(DIC_SCH_FREE_TABLE1_ID, tplFreeData.DIC_SCH_FREE_TABLE1_ID)
             , DIC_SCH_FREE_TABLE2_ID = nvl(DIC_SCH_FREE_TABLE2_ID, tplFreeData.DIC_SCH_FREE_TABLE2_ID)
             , DIC_SCH_FREE_TABLE3_ID = nvl(DIC_SCH_FREE_TABLE3_ID, tplFreeData.DIC_SCH_FREE_TABLE3_ID)
             , DIC_SCH_FREE_TABLE4_ID = nvl(DIC_SCH_FREE_TABLE4_ID, tplFreeData.DIC_SCH_FREE_TABLE4_ID)
             , DIC_SCH_FREE_TABLE5_ID = nvl(DIC_SCH_FREE_TABLE5_ID, tplFreeData.DIC_SCH_FREE_TABLE5_ID)
             , SFD_ALPHA_SHORT_1 = nvl(SFD_ALPHA_SHORT_1, tplFreeData.SFD_ALPHA_SHORT_1)
             , SFD_ALPHA_SHORT_2 = nvl(SFD_ALPHA_SHORT_2, tplFreeData.SFD_ALPHA_SHORT_2)
             , SFD_ALPHA_SHORT_3 = nvl(SFD_ALPHA_SHORT_3, tplFreeData.SFD_ALPHA_SHORT_3)
             , SFD_ALPHA_SHORT_4 = nvl(SFD_ALPHA_SHORT_4, tplFreeData.SFD_ALPHA_SHORT_4)
             , SFD_ALPHA_SHORT_5 = nvl(SFD_ALPHA_SHORT_5, tplFreeData.SFD_ALPHA_SHORT_5)
             , SFD_ALPHA_LONG_1 = nvl(SFD_ALPHA_LONG_1, tplFreeData.SFD_ALPHA_LONG_1)
             , SFD_ALPHA_LONG_2 = nvl(SFD_ALPHA_LONG_2, tplFreeData.SFD_ALPHA_LONG_2)
             , SFD_ALPHA_LONG_3 = nvl(SFD_ALPHA_LONG_3, tplFreeData.SFD_ALPHA_LONG_3)
             , SFD_ALPHA_LONG_4 = nvl(SFD_ALPHA_LONG_4, tplFreeData.SFD_ALPHA_LONG_4)
             , SFD_ALPHA_LONG_5 = nvl(SFD_ALPHA_LONG_5, tplFreeData.SFD_ALPHA_LONG_5)
             , SFD_INTEGER_1 = nvl(SFD_INTEGER_1, tplFreeData.SFD_INTEGER_1)
             , SFD_INTEGER_2 = nvl(SFD_INTEGER_2, tplFreeData.SFD_INTEGER_2)
             , SFD_INTEGER_3 = nvl(SFD_INTEGER_3, tplFreeData.SFD_INTEGER_3)
             , SFD_INTEGER_4 = nvl(SFD_INTEGER_4, tplFreeData.SFD_INTEGER_4)
             , SFD_INTEGER_5 = nvl(SFD_INTEGER_5, tplFreeData.SFD_INTEGER_5)
             , SFD_BOOLEAN_1 = nvl(SFD_BOOLEAN_1, tplFreeData.SFD_BOOLEAN_1)
             , SFD_BOOLEAN_2 = nvl(SFD_BOOLEAN_2, tplFreeData.SFD_BOOLEAN_2)
             , SFD_BOOLEAN_3 = nvl(SFD_BOOLEAN_3, tplFreeData.SFD_BOOLEAN_3)
             , SFD_BOOLEAN_4 = nvl(SFD_BOOLEAN_4, tplFreeData.SFD_BOOLEAN_4)
             , SFD_BOOLEAN_5 = nvl(SFD_BOOLEAN_5, tplFreeData.SFD_BOOLEAN_5)
             , SFD_DECIMAL_1 = nvl(SFD_DECIMAL_1, tplFreeData.SFD_DECIMAL_1)
             , SFD_DECIMAL_2 = nvl(SFD_DECIMAL_2, tplFreeData.SFD_DECIMAL_2)
             , SFD_DECIMAL_3 = nvl(SFD_DECIMAL_3, tplFreeData.SFD_DECIMAL_3)
             , SFD_DECIMAL_4 = nvl(SFD_DECIMAL_4, tplFreeData.SFD_DECIMAL_4)
             , SFD_DECIMAL_5 = nvl(SFD_DECIMAL_5, tplFreeData.SFD_DECIMAL_5)
             , SFD_DATE_1 = nvl(SFD_DATE_1, tplFreeData.SFD_DATE_1)
             , SFD_DATE_2 = nvl(SFD_DATE_2, tplFreeData.SFD_DATE_2)
             , SFD_DATE_3 = nvl(SFD_DATE_3, tplFreeData.SFD_DATE_3)
             , SFD_DATE_4 = nvl(SFD_DATE_4, tplFreeData.SFD_DATE_4)
             , SFD_DATE_5 = nvl(SFD_DATE_5, tplFreeData.SFD_DATE_5)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where SCH_FREE_DATA_ID = tplFreeData.SCH_FREE_DATA_ID;
      else
        insert into SCH_FREE_DATA
                    (SCH_FREE_DATA_ID
                   , SCH_ENTERED_OUTLAY_ID
                   , DIC_SCH_FREE_TABLE1_ID
                   , DIC_SCH_FREE_TABLE2_ID
                   , DIC_SCH_FREE_TABLE3_ID
                   , DIC_SCH_FREE_TABLE4_ID
                   , DIC_SCH_FREE_TABLE5_ID
                   , SFD_ALPHA_SHORT_1
                   , SFD_ALPHA_SHORT_2
                   , SFD_ALPHA_SHORT_3
                   , SFD_ALPHA_SHORT_4
                   , SFD_ALPHA_SHORT_5
                   , SFD_ALPHA_LONG_1
                   , SFD_ALPHA_LONG_2
                   , SFD_ALPHA_LONG_3
                   , SFD_ALPHA_LONG_4
                   , SFD_ALPHA_LONG_5
                   , SFD_INTEGER_1
                   , SFD_INTEGER_2
                   , SFD_INTEGER_3
                   , SFD_INTEGER_4
                   , SFD_INTEGER_5
                   , SFD_BOOLEAN_1
                   , SFD_BOOLEAN_2
                   , SFD_BOOLEAN_3
                   , SFD_BOOLEAN_4
                   , SFD_BOOLEAN_5
                   , SFD_DECIMAL_1
                   , SFD_DECIMAL_2
                   , SFD_DECIMAL_3
                   , SFD_DECIMAL_4
                   , SFD_DECIMAL_5
                   , SFD_DATE_1
                   , SFD_DATE_2
                   , SFD_DATE_3
                   , SFD_DATE_4
                   , SFD_DATE_5
                   , A_DATECRE
                   , A_IDCRE
                   , SFD_CATEGORY_COPY
                   , SFD_TRANSFERT
                    )
          select GetNewId
               , aSCH_ENTERED_OUTLAY_ID
               , DIC_SCH_FREE_TABLE1_ID
               , DIC_SCH_FREE_TABLE2_ID
               , DIC_SCH_FREE_TABLE3_ID
               , DIC_SCH_FREE_TABLE4_ID
               , DIC_SCH_FREE_TABLE5_ID
               , SFD_ALPHA_SHORT_1
               , SFD_ALPHA_SHORT_2
               , SFD_ALPHA_SHORT_3
               , SFD_ALPHA_SHORT_4
               , SFD_ALPHA_SHORT_5
               , SFD_ALPHA_LONG_1
               , SFD_ALPHA_LONG_2
               , SFD_ALPHA_LONG_3
               , SFD_ALPHA_LONG_4
               , SFD_ALPHA_LONG_5
               , SFD_INTEGER_1
               , SFD_INTEGER_2
               , SFD_INTEGER_3
               , SFD_INTEGER_4
               , SFD_INTEGER_5
               , SFD_BOOLEAN_1
               , SFD_BOOLEAN_2
               , SFD_BOOLEAN_3
               , SFD_BOOLEAN_4
               , SFD_BOOLEAN_5
               , SFD_DECIMAL_1
               , SFD_DECIMAL_2
               , SFD_DECIMAL_3
               , SFD_DECIMAL_4
               , SFD_DECIMAL_5
               , SFD_DATE_1
               , SFD_DATE_2
               , SFD_DATE_3
               , SFD_DATE_4
               , SFD_DATE_5
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , 0
               , 0
            from SCH_FREE_DATA
           where SCH_OUTLAY_CATEGORY_ID = aSCH_OUTLAY_CATEGORY_ID
             and SFD_TRANSFERT = 1
             and nvl(aSCH_OUTLAY_CATEGORY_ID, 0) <> 0;
      end if;

      close crfreedata;
    end if;
  end CopyFreeDataFromOutlay;

  /**
  * procedure GetValorizedQuantity
  * Description : Calcul de la quantité valorisée
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_STUDENT_ID : Elève
  * @param   iPAC_CUSTOM_PARTNER_ID : Client
  * @param   iEOU_BASIS_QUANTITY : Quantité de base
  * @param   iEOU_VALUE_DATE : Date valeur
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  */
  function GetValorizedQuantity(
    iSCH_STUDENT_ID         in number
  , iPAC_CUSTOM_PARTNER_ID  in number
  , iEOU_BASIS_QUANTITY     in number
  , iEOU_VALUE_DATE         in date
  , iSCH_OUTLAY_ID          in number
  , iSCH_OUTLAY_CATEGORY_ID in number
  )
    return number
  is
    cursor crGetConvFactor
    is
      select   CAS.CAS_CONV_FACTOR
             , case
                 when sch_student_id is not null
                 and sch_outlay_id is not null
                 and sch_outlay_category_id is not null then 0
                 when sch_student_id is not null
                 and sch_outlay_id is not null
                 and sch_outlay_category_id is null then 1
                 when sch_student_id is null
                 and sch_outlay_id is not null
                 and sch_outlay_category_id is not null then 2
                 when sch_student_id is null
                 and sch_outlay_id is not null
                 and sch_outlay_category_id is null then 3
               end order_field
          from SCH_CUSTOMERS_ASSOCIATION CAS
         where (   CAS.SCH_STUDENT_ID is null
                or CAS.SCH_STUDENT_ID = iSCH_STUDENT_ID)
           and (   iPAC_CUSTOM_PARTNER_ID is null
                or (    iPAC_CUSTOM_PARTNER_ID is not null
                    and CAS.PAC_CUSTOM_PARTNER_ID = iPAC_CUSTOM_PARTNER_ID) )
           and CAS.SCH_OUTLAY_ID = iSCH_OUTLAY_ID
           and (   CAS.SCH_OUTLAY_CATEGORY_ID is null
                or CAS.SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID)
           and CAS.CAS_CONV_FACTOR is not null
           and (trunc(iEOU_VALUE_DATE) between nvl(CAS_VALIDITY_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                           and nvl(CAS_VALIDITY_DATE_TO, to_date('31.12.2999', 'DD.MM.YYYY') )
               )
           and CAS.CAS_CONV_FACTOR is not null
      order by order_field asc;

    lcSchPrcGetValorizedQty varchar2(255);
    lnEOU_QTY               number;
    liExecStandard          integer;
    lnConversionFactor      number;
  begin
    liExecStandard           := 1;
    lcSchPrcGetValorizedQty  := PCS.PC_CONFIG.GetConfig('SCH_PRC_GET_VALORIZED_QTY');

    if not lcSchPrcGetValorizedQty is null then
      GetValorizedQuantityIndiv(lcSchPrcGetValorizedQty
                              , iEOU_VALUE_DATE
                              , iPAC_CUSTOM_PARTNER_ID
                              , iSCH_OUTLAY_ID
                              , iSCH_OUTLAY_CATEGORY_ID
                              , iEOU_BASIS_QUANTITY
                              , lnEOU_QTY
                              , liExecStandard
                               );
    end if;

    if liExecStandard = 1 then
      -- Recherche du facteur de conversion dans la matrice
      lnConversionFactor  := null;

      for tplGetConvFactor in crGetConvFactor loop
        lnConversionFactor  := tplGetConvFactor.CAS_CONV_FACTOR;
        exit;
      end loop;

      if lnConversionfactor is not null then
        lnEOU_QTY  := iEOU_BASIS_QUANTITY * lnConversionfactor;
      else
        lnEOU_QTY  := iEOU_BASIS_QUANTITY;
      end if;
    end if;

    return lnEOU_QTY;
  end GetValorizedQuantity;

  /**
  * function GetOutlayTariff
  * Description : Recherche du tarif de prestation
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_STUDENT_ID : Elève
  * @param   iPAC_CUSTOM_PARTNER_ID : Client
  * @param   iEOU_BASIS_QUANTITY : Quantité de base
  * @param   iEOU_VALUE_DATE : Date valeur
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  */
  function GetOutlayTariff(
    iSCH_STUDENT_ID         in number
  , iPAC_CUSTOM_PARTNER_ID  in number
  , iEOU_BASIS_QUANTITY     in number
  , iEOU_VALUE_DATE         in date
  , iSCH_OUTLAY_CATEGORY_ID in number
  , iDIC_TARIFF_ID          in number default null
  )
    return number
  is
    lscfgSCH_OUTLAY_USE_STD_T   varchar2(255);
    lnGCO_GOOD_ID               number;
    lnDOC_RECORD_ID             number;
    lnPAC_CUSTOM_PARTNER_ID     number;
    lvDic_Tariff                varchar2(10);
    lvroundType                 PTC_TARIFF.C_ROUND_TYPE%type;
    lnroundAmount               PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    lnCurrencyId                number;
    lnNet                       number;
    lnSpecial                   number;
    lnFlatRate                  number;
    lnTariffUnit                number;
    liExecStandard              integer;
    lnPrice                     number;
    lvSCH_PRC_INDIV_SALE_TARIFF varchar2(255);
  begin
    -- selon la configuration montants standards ou pas
    lscfgSCH_OUTLAY_USE_STD_T    := PCS.PC_CONFIG.GetConfig('SCH_OUTLAY_USE_STD_TARIFFS');
    lvDic_Tariff                 := null;
    -- Individualisation de la recherche
    liExecStandard               := 1;
    lvSCH_PRC_INDIV_SALE_TARIFF  := PCS.PC_CONFIG.GetConfig('SCH_PRC_INDIV_SALE_TARIFF');

    if not lvSCH_PRC_INDIV_SALE_TARIFF is null then
      GetOutlayTariffIndiv(lvSCH_PRC_INDIV_SALE_TARIFF
                         , iSCH_STUDENT_ID
                         , iPAC_CUSTOM_PARTNER_ID
                         , iEOU_BASIS_QUANTITY
                         , iEOU_VALUE_DATE
                         , iSCH_OUTLAY_CATEGORY_ID
                         , lnPrice
                         , liExecStandard
                          );
    end if;

    -- Execution standard
    if liExecStandard = 1 then
      -- Montant sur débours
      if lscfgSCH_OUTLAY_USE_STD_T = 0 then
        begin
          select nvl(SOC.COU_UNIT_AMOUNT, 0)
            into lnPrice
            from SCH_OUTLAY_CATEGORY SOC
           where SOC.SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID;
        exception
          when others then
            lnPrice  := 0;
        end;
      -- Montants stockés dans PTC, utilisation fonct. standard GCO
      else
        -- Monnaie de base de la société
        lnCurrencyId  := SCH_TOOLS.GetBaseMoney;

        -- Recherche produit associé à la prestation
        select GCO_GOOD_ID
          into lnGCO_GOOD_ID
          from SCH_OUTLAY_CATEGORY
         where SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID;

        -- Recherche du dossier correspondant à l'élève
        begin
          select max(DOC_RECORD_ID)
            into lnDOC_RECORD_ID
            from DOC_RECORD
           where RCO_TITLE = to_char( (select STU_ACCOUNT_NUMBER
                                         from SCH_STUDENT STU
                                        where SCH_STUDENT_ID = iSCH_STUDENT_ID) );
        exception
          when others then
            lnDOC_RECORD_ID  := null;
        end;

        -- Si le tier est nul, on recherche par rapport au tiers par défaut.
        if nvl(iPAC_CUSTOM_PARTNER_ID, 0) = 0 then
          begin
            select STU.PAC_CUSTOM_PARTNER2_ID
                 , PAC.DIC_TARIFF_ID
              into lnPAC_CUSTOM_PARTNER_ID
                 , lvDic_Tariff
              from SCH_STUDENT STU
                 , PAC_CUSTOM_PARTNER PAC
             where STU.SCH_STUDENT_ID = iSCH_STUDENT_ID
               and STU.PAC_CUSTOM_PARTNER2_ID = PAC.PAC_CUSTOM_PARTNER_ID;
          exception
            when others then
              lnPAC_CUSTOM_PARTNER_ID  := null;
              lvDic_Tariff             := null;
          end;
        else
          begin
            select PAC.PAC_CUSTOM_PARTNER_ID
                 , PAC.DIC_TARIFF_ID
              into lnPAC_CUSTOM_PARTNER_ID
                 , lvDic_Tariff
              from PAC_CUSTOM_PARTNER PAC
             where PAC.PAC_CUSTOM_PARTNER_ID = iPAC_CUSTOM_PARTNER_ID;
          exception
            when others then
              lnPAC_CUSTOM_PARTNER_ID  := null;
              lvDic_Tariff             := null;
          end;
        end if;

        -- Le code tarif passé en paramètre à la priorité sur celui du tiers
        if nvl(iDIC_TARIFF_ID, 0) <> 0 then
          lvDic_Tariff  := iDIC_TARIFF_ID;
        end if;

        -- Appel fonction standard
        lnPrice       :=
          GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => lnGCO_GOOD_ID
                                     , iTypePrice           => '2'   -- tarif de vente
                                     , iThirdId             => lnPAC_CUSTOM_PARTNER_ID
                                     , iRecordId            => lnDOC_RECORD_ID
                                     , iFalScheduleStepId   => null
                                     , ioDicTariff          => lvDic_Tariff
                                     , iQuantity            => iEOU_BASIS_QUANTITY
                                     , iDateRef             => nvl(iEOU_VALUE_DATE, sysdate)
                                     , ioRoundType          => lvroundType
                                     , ioRoundAmount        => lnroundamount
                                     , ioCurrencyId         => lnCurrencyId
                                     , oNet                 => lnNet
                                     , oSpecial             => lnSpecial
                                     , oFlatRate            => lnFlatRate
                                     , oTariffUnit          => lnTariffUnit
                                     , iDicTariff2          => lvDic_Tariff
                                      );
      end if;
    end if;

    return nvl(lnPrice, 0);
  end GetOutlayTariff;

  /**
  * function GetOutlayCatDefltQty
  * Description : Recherche Qté défaut
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  */
  function GetOutlayCatDefltQty(iSCH_OUTLAY_CATEGORY_ID in number)
    return number
  is
    lnResult number;
  begin
    select COU_QTY
      into lnResult
      from SCH_OUTLAY_CATEGORY
     where SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID;

    return lnResult;
  exception
    when no_data_found then
      return 0;
  end GetOutlayCatDefltQty;

  /**
  * procedure SelectLinkedCategory
  * Description : Procedure de liaison/déliaison d'une ou plusieurs catégories
  *   à une catégorie disponible LPM.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iLPMCategoryId : Catégorie disponible LPM
  * @param   iLinkedCategory : Categorie liée
  * @param   iSelect : Sélection / Dé-sélection
  */
  procedure SelectLinkedCategory(iLPMCategoryId in number, iLinkedCategory in number default null, iSelect in integer default 1)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Sélection
    if iSelect = 1 then
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchOutCatSCatLinked, ltCRUD_DEF);

      for tplCategory in (select CAT.SCH_OUTLAY_CATEGORY_ID
                               , init_id_seq.nextval NEWID
                            from SCH_OUTLAY_CATEGORY CAT
                           where (    nvl(iLinkedCategory, 0) <> 0
                                  and CAT.SCH_OUTLAY_CATEGORY_ID = iLinkedCategory)
                              or (nvl(iLinkedCategory, 0) = 0) ) loop
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_OUT_CAT_S_CAT_LINKED_ID', tplCategory.NEWID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_OUTLAY_CATEGORY_ID', iLPMCategoryId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_OUTLAY_CATEGORY_LINKED_ID', tplCategory.SCH_OUTLAY_CATEGORY_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Dé-sélection
    else
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchOutCatSCatLinked, ltCRUD_DEF);

      for tplCategory in (select CAT.SCH_OUT_CAT_S_CAT_LINKED_ID
                            from SCH_OUT_CAT_S_CAT_LINKED CAT
                           where CAT.SCH_OUTLAY_CATEGORY_ID = iLPMCategoryId
                             and (    (    nvl(iLinkedCategory, 0) <> 0
                                       and CAT.SCH_OUTLAY_CATEGORY_LINKED_ID = iLinkedCategory)
                                  or (nvl(iLinkedCategory, 0) = 0) ) ) loop
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_OUT_CAT_S_CAT_LINKED_ID', tplCategory.SCH_OUT_CAT_S_CAT_LINKED_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end if;
  end SelectLinkedCategory;
end SCH_OUTLAY_FUNCTIONS;
