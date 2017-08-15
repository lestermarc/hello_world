--------------------------------------------------------
--  DDL for Package Body SCH_OUTLAY_BILLING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_OUTLAY_BILLING" 
is
  /**
  * procedure GetDocGaugeIndiv
  * Description : Forcage d'un gabarit spécifique de facturation
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe de période
  */
  procedure GetDocGaugeIndiv(iSchPrcOutlayForcDocGauge in varchar2, iSCH_BILL_HEADER_ID in number, ioDOC_GAUGE_ID in out number)
  is
    lvPrcSql varchar2(2000);
  begin
    lvPrcSql  := ' begin ';
    lvPrcSql  := lvPrcSql || iSchPrcOutlayForcDocGauge || '(:iSCH_BILL_HEADER_ID,' || ' :ioDOC_GAUGE_ID);';
    lvPrcSql  := lvPrcSql || ' end; ';

    execute immediate lvPrcSql
                using in iSCH_BILL_HEADER_ID, in out ioDOC_GAUGE_ID;
  end GetDocGaugeIndiv;

  /**
  * procedure SelectPeriods
  * Description : Sélection des périodes via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des factures de débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe de période
  */
  procedure SelectPeriods(aSCH_GROUP_YEAR_PERIOD_ID in number, iUseCase in integer default ucSchooling)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_YEAR_PERIOD_ID';

    -- Sélection des ID de produits à traiter
    if iUseCase = ucSchooling then
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct LNK.SCH_YEAR_PERIOD_ID
                      , 'SCH_YEAR_PERIOD_ID'
                   from SCH_GROUP_YEAR_PERIOD GRP
                      , SCH_PERIOD_GRP_PERIOD_LINK LNK
                  where GRP.SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
                    and GRP.SCH_GROUP_YEAR_PERIOD_ID = LNK.SCH_GROUP_YEAR_PERIOD_ID;
    else
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct SCH_YEAR_PERIOD_ID
                      , 'SCH_YEAR_PERIOD_ID'
                   from SCH_YEAR_PERIOD
                  where PER_BEGIN_DATE <=
                          (select max(PER_BEGIN_DATE)
                             from SCH_GROUP_YEAR_PERIOD GRP
                                , SCH_PERIOD_GRP_PERIOD_LINK LNK
                                , SCh_YEAR_PERIOD PER2
                            where GRP.SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
                              and GRP.SCH_GROUP_YEAR_PERIOD_ID = LNK.SCH_GROUP_YEAR_PERIOD_ID
                              and LNK.SCH_YEAR_PERIOD_ID = PER2.SCH_YEAR_PERIOD_ID);
    end if;
  end SelectPeriods;

  /**
  * procedure SelectCustomers
  * Description : Sélection des débiteurs via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des factures de débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPER_NAME_FROM : Nom de
  * @param   aPER_NAME_TO : Nom à
  * @param   aDIC_INVOICING_PERIOD_ID : Périodicité de facturation
  * @param   aDIC_CUSTOMER_TYPE_ID : Type de partenaire
  */
  procedure SelectCustomers(aPER_NAME_FROM in varchar2, aPER_NAME_TO in varchar2, aDIC_INVOICING_PERIOD_ID in varchar2, aDIC_CUSTOMER_TYPE_ID in varchar2)
  is
  begin
    SCH_OUTLAY_FUNCTIONS.SelectCustomers(aPER_NAME_FROM, aPER_NAME_TO, aDIC_INVOICING_PERIOD_ID, aDIC_CUSTOMER_TYPE_ID);
  end SelectCustomers;

  /**
  * procedure SelectOutlays
  * Description : Sélection des débours via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des factures de débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aOUT_MAJOR_REFERENCE_FROM : Référence principale de
  * @param   aOUT_MAJOR_REFERENCE_TO : Référence principale à
  * @param   aOUT_SECONDARY_REFERENCE_FROM : Référence secondaire de
  * @param   aOUT_SECONDARY_REFERENCE_TO : Référence secondaire à
  */
  procedure SelectOutlays(
    aOUT_MAJOR_REFERENCE_FROM     varchar2
  , aOUT_MAJOR_REFERENCE_TO       varchar2
  , aOUT_SECONDARY_REFERENCE_FROM varchar2
  , aOUT_SECONDARY_REFERENCE_TO   varchar2
  )
  is
  begin
    SCH_OUTLAY_FUNCTIONS.SelectOutlay(aOUT_MAJOR_REFERENCE_FROM, aOUT_MAJOR_REFERENCE_TO, aOUT_SECONDARY_REFERENCE_FROM, aOUT_SECONDARY_REFERENCE_TO);
  end SelectOutlays;

  /**
  * procedure SelectOutlaysCategory
  * Description : Sélection des catégories de débours via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des factures de débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aCOU_MAJOR_REFERENCE_FROM : Référence principale de
  * @param   aCOU_MAJOR_REFERENCE_TO : Référence principale à
  * @param   aCOU_SECONDARY_REFERENCE_FROM : Référence secondaire de
  * @param   aCOU_SECONDARY_REFERENCE_TO : Référence secondaire à
  */
  procedure SelectOutlaysCategory(
    aCOU_MAJOR_REFERENCE_FROM     varchar2
  , aCOU_MAJOR_REFERENCE_TO       varchar2
  , aCOU_SECONDARY_REFERENCE_FROM varchar2
  , aCOU_SECONDARY_REFERENCE_TO   varchar2
  )
  is
  begin
    SCH_OUTLAY_FUNCTIONS.SelectOutlayCategory(aCOU_MAJOR_REFERENCE_FROM, aCOU_MAJOR_REFERENCE_TO, aCOU_SECONDARY_REFERENCE_FROM, aCOU_SECONDARY_REFERENCE_TO);
  end SelectOutlaysCategory;

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
  , aContext                  integer default SCH_OUTLAY_FUNCTIONS.wmNone
  )
  is
  begin
    SCH_OUTLAY_FUNCTIONS.SelectStudents(aSTU_NAME_FROM
                                      , aSTU_NAME_TO
                                      , aSTU_ACCOUNT_NUMBER_FROM
                                      , aSTU_ACCOUNT_NUMBER_TO
                                      , aSTU_ENTRY_DATE_FROM
                                      , aSTU_ENTRY_DATE_TO
                                      , aSTU_EXIT_DATE_FROM
                                      , aSTU_EXIT_DATE_TO
                                      , aSTUDENT_STATUS
                                      , aEDUCATION_DEGREE
                                      , aSTU_SCHOOL_YEAR
                                      , aSTU_CLASS
                                      , aRestrictSelection
                                      , aSCH_YEAR_PERIOD_ID
                                      , aSCH_GROUP_YEAR_PERIOD_ID
                                      , aContext
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
    SCH_OUTLAY_FUNCTIONS.SelectCDA(aACS_CDA_ACCOUNT_ID);
  end SelectCDA;

  /**
  * procedure SelectEnteredOutlays
  * Description : Sélection des débours entrés et correspondant aux filtres
  *               de présélections sur les périodes, débiteurs, débours, catégories
  *               élèves et centre d'analyse.
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure SelectEnteredOutlays
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_ENTERED_OUTLAY_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_NUMBER_1
                )
      select distinct EOU.SCH_ENTERED_OUTLAY_ID
                    , 'SCH_ENTERED_OUTLAY_ID'
                    , 1
                 from SCH_ENTERED_OUTLAY EOU
                where EOU.SCH_YEAR_PERIOD_ID in(select COM_LIST_ID_TEMP_ID
                                                  from COM_LIST_ID_TEMP
                                                 where LID_CODE = 'SCH_YEAR_PERIOD_ID')
                  and EOU.PAC_CUSTOM_PARTNER_ID in(select COM_LIST_ID_TEMP_ID
                                                     from COM_LIST_ID_TEMP
                                                    where LID_CODE = 'PAC_CUSTOM_PARTNER_ID')
                  and EOU.SCH_OUTLAY_ID in(select COM_LIST_ID_TEMP_ID
                                             from COM_LIST_ID_TEMP
                                            where LID_CODE = 'SCH_OUTLAY_ID')
                  and EOU.SCH_OUTLAY_CATEGORY_ID in(select COM_LIST_ID_TEMP_ID
                                                      from COM_LIST_ID_TEMP
                                                     where LID_CODE = 'SCH_OUTLAY_CATEGORY_ID')
                  and EOU.SCH_STUDENT_ID in(select COM_LIST_ID_TEMP_ID
                                              from COM_LIST_ID_TEMP
                                             where LID_CODE = 'SCH_STUDENT_ID')
                  and ((SCH_BILLING_FUNCTIONS.GetFilterCDA(null, EOU.SCH_ENTERED_OUTLAY_ID, null) in(select COM_LIST_ID_TEMP_ID
                                                                                                       from COM_LIST_ID_TEMP
                                                                                                      where LID_CODE = 'CDA_ACC_SCH'))
                        OR
                       (SCH_BILLING_FUNCTIONS.GetFilterCDA(null, EOU.SCH_ENTERED_OUTLAY_ID, null) is null))

                  and EOU.EOU_STATUS = 1;
  end SelectEnteredOutlays;

  /**
  * procedure SelectOutlayBill
  * Description : Sélection des factures encore à générer en logistique en tenant compte des filtres
  *               de présélections sur les périodes, débiteurs, et élèves.
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure SelectOutlayBill
  is
  begin
    SCH_BILLING_FUNCTIONS.SelectBill(0);
  end SelectOutlayBill;

  /**
  * procedure ProcessOutlayBilling
  * Description : Génération des factures de débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPAC_PAYMENT_CONDITION_ID : Conditions de paiement
  * @param   aC_GROUPING_MODE : Mode de regroupement
  * @param   aDMT_DATE_VALUE : Date valeur document
  * @param   aDOC_GAUGE_ID : Gabarit
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe de périodes facturées
  * @param   aUseCase : ucSchooling ucfundation
  * @param   aSuccessfulCount : Doc générés avec succes
  * @param   aTotalCount : Factures totales sélectionnées pour génération
  * @param   iDateDocument : Date de document
  */
  procedure ProcessOutlayBilling(
    aPAC_PAYMENT_CONDITION_ID in     number
  , aC_GROUPING_MODE          in     varchar2
  , aDMT_DATE_VALUE           in     date
  , aDOC_GAUGE_ID             in     number
  , aSCH_GROUP_YEAR_PERIOD_ID in     number
  , aUseCase                  in     integer default ucSchooling
  , aSuccessfulCount          in out integer
  , aTotalCount               in out integer
  , iDateDocument             in     date default null
  )
  is
    -- Un document par débiteur
    cursor crProcessByCustomer
    is
      select distinct EOU.PAC_CUSTOM_PARTNER_ID
                    , null SCH_STUDENT_ID
                    , null STU_ACCOUNT_NUMBER
                    , null STU_OUT_OTHER_ADDRESS
                    , PAC.ACS_VAT_DET_ACCOUNT_ID
                    , PAC.ACS_FIN_ACC_S_PAYMENT_ID
                    , PAC.DIC_TYPE_SUBMISSION_ID
                    , PER.PER_KEY1
                    , PAC.PAC_PAYMENT_CONDITION_ID
                    , null as SCh_BILL_HEADER_ID
                 from SCH_ENTERED_OUTLAY EOU
                    , COM_LIST_ID_TEMP LID
                    , ACS_AUX_ACCOUNT_S_FIN_CURR AAA
                    , PAC_CUSTOM_PARTNER PAC
                    , PAC_PERSON PER
                where EOU.SCH_ENTERED_OUTLAY_ID = LID.COM_LIST_ID_TEMP_ID
                  and PAC.ACS_AUXILIARY_ACCOUNT_ID = AAA.ACS_AUXILIARY_ACCOUNT_ID(+)
                  and EOU.PAC_CUSTOM_PARTNER_ID = PAC.PAC_CUSTOM_PARTNER_ID
                  and EOU.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                  and LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID'
                  and LID.LID_FREE_NUMBER_1 = 1;

    -- Un document par débiteur / élève
    cursor crProcessByCustAndStudent
    is
      select distinct EOU.PAC_CUSTOM_PARTNER_ID
                    , EOU.SCH_STUDENT_ID
                    , STU.STU_ACCOUNT_NUMBER
                    , nvl(STU.STU_OUT_OTHER_ADDRESS, 0) STU_OUT_OTHER_ADDRESS
                    , PAC.ACS_VAT_DET_ACCOUNT_ID
                    , PAC.ACS_FIN_ACC_S_PAYMENT_ID
                    , PAC.DIC_TYPE_SUBMISSION_ID
                    , PER.PER_KEY1
                    , PAC.PAC_PAYMENT_CONDITION_ID
                    , null as SCh_BILL_HEADER_ID
                 from SCH_ENTERED_OUTLAY EOU
                    , COM_LIST_ID_TEMP LID
                    , SCH_STUDENT STU
                    , ACS_AUX_ACCOUNT_S_FIN_CURR AAA
                    , PAC_CUSTOM_PARTNER PAC
                    , PAC_PERSON PER
                where EOU.SCH_ENTERED_OUTLAY_ID = LID.COM_LIST_ID_TEMP_ID
                  and EOU.SCH_STUDENT_ID = STU.SCH_STUDENT_ID
                  and PAC.ACS_AUXILIARY_ACCOUNT_ID = AAA.ACS_AUXILIARY_ACCOUNT_ID(+)
                  and EOU.PAC_CUSTOM_PARTNER_ID = PAC.PAC_CUSTOM_PARTNER_ID
                  and EOU.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                  and LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID'
                  and LID.LID_FREE_NUMBER_1 = 1;

    -- Sélection des débours.
    cursor crAllOutlays(aPAC_CUSTOM_PARTNER_ID number, aSCH_STUDENT_ID number)
    is
      select   EOU.SCH_STUDENT_ID
             , EOU.SCH_OUTLAY_ID
             , EOU.SCH_OUTLAY_CATEGORY_ID
             , EOU.SCH_YEAR_PERIOD_ID
             , EOU.PAC_CUSTOM_PARTNER_ID
             , out.OUT_MAJOR_REFERENCE
             , out.OUT_SECONDARY_REFERENCE
             , out.OUT_SHORT_DESCR
             , out.OUT_LONG_DESCR
             , out.OUT_FREE_DESCR
             , COU.COU_MAJOR_REFERENCE
             , COU.COU_SECONDARY_REFERENCE
             , COU.COU_SHORT_DESCR
             , COU.COU_LONG_DESCR
             , COU.COU_FREE_DESCR
             , EOU.EOU_QTY
             , EOU.EOU_TTC_AMOUNT
             , COU.COU_NULL_MARGIN
             , COU.COU_MARGIN_TYPE
             , COU.COU_UNIT_MARGIN
             , EOU.EOU_MARGIN_AMOUNT
             , EOU.EOU_MARGIN_RATE
             , EOU.SCH_ENTERED_OUTLAY_ID
             , COU.GCO_GOOD_ID
             , STU.STU_ACCOUNT_NUMBER
             , EOU.SCH_FATHER_ENTERED_OUTLAY_ID
          from SCH_ENTERED_OUTLAY EOU
             , SCH_OUTLAY_CATEGORY COU
             , SCH_OUTLAY out
             , COM_LIST_ID_TEMP LID
             , SCH_STUDENT STU
         where (EOU.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID)
           and (   aSCH_STUDENT_ID is null
                or EOU.SCH_STUDENT_ID = aSCH_STUDENT_ID)
           and EOU.SCH_ENTERED_OUTLAY_ID = LID.COM_LIST_ID_TEMP_ID
           and EOU.SCH_OUTLAY_CATEGORY_ID = COU.SCH_OUTLAY_CATEGORY_ID
           and EOU.SCH_OUTLAY_ID = out.SCH_OUTLAY_ID
           and LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID'
           and LID.LID_FREE_NUMBER_1 = 1
           and EOU.SCH_STUDENT_ID = STU.SCH_STUDENT_ID
           and PAC_CUSTOM_PARTNER_ID is not null
      order by EOU.SCH_STUDENT_ID asc
             , EOU.SCH_FATHER_ENTERED_OUTLAY_ID asc nulls first
             , EOU.A_DATECRE asc;

    type TCustomers is table of crProcessByCustAndStudent%rowtype;

    vCustomers                  TCustomers;
    aACS_FINANCIAL_CURRENCY_ID  number;
    aSCH_BILL_HEADER_ID         number;
    aSCh_BILL_POSITION_ID       number;
    aTTC_AMOUNT                 number;
    aTTC_UNIT_AMOUNT            number;
    aBOP_SEQ                    integer;
    vSqlMsg                     varchar2(4000);
    vSCH_PREBILL_GLOBAL_PROC    varchar2(255);
    vSCH_PREBILL_DET_AFTER_PROC varchar2(255);
    vProcResult                 integer        := 1;
    lvSchPrcOutlayForceDocGauge varchar2(255);
    lnIndivDOC_GAUGE_ID         number;
  begin
    -- initialisation de l'indication du résultat
    aSuccessfulCount             := 0;
    aTotalCount                  := 0;

    -- Suppression des erreurs éventuellement persistantes
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'BILLING_OUTLAY_ERRORS';

    -- Récupération des procédures stockées
    vSCH_PREBILL_GLOBAL_PROC     := PCS.PC_CONFIG.GetConfig('SCH_OUT_PREBILL_GLOBAL_PROC');
    vSCH_PREBILL_DET_AFTER_PROC  := PCS.PC_CONFIG.GetConfig('SCH_OUT_PREBILL_DET_AFTER_PROC');

    -- Execution de la procédure stockée globale
    if vSCH_PREBILL_GLOBAL_PROC is not null then
      begin
        execute immediate 'begin :Result :=  ' || vSCH_PREBILL_GLOBAL_PROC || '; end;'
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
                     PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a généré une erreur :') || chr(13) || chr(10)
                     || DBMS_UTILITY.FORMAT_ERROR_STACK;
          end;
      end;
    end if;

    -- La procédure globale de pré-traitement à généré un message d'erreur
    if vSqlMsg is not null then
      -- Insertion de l'erreur dans la table temporaire
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_DESCRIPTION
                 , LID_CODE
                  )
           values (GetNewId
                 , vSqlMsg
                 , 'BILLING_OUTLAY_ERRORS'
                  );
    -- Pas d'erreur globale de pré-traitement, le traitement continue
    else
      -- Récupération de la monnaie de base de la société
      aACS_FINANCIAL_CURRENCY_ID  := SCH_TOOLS.GetBaseMoney;

      -- Un document par débiteur
      if aC_GROUPING_MODE = '0' then
        open crProcessByCustomer;

        fetch crProcessByCustomer
        bulk collect into vCustomers;
      -- Un document par débiteur et par élève
      else
        open crProcessByCustAndStudent;

        fetch crProcessByCustAndStudent
        bulk collect into vCustomers;
      end if;

      -- Pour chaque tuple de regroupement sélectionné, génération d'une facture
      if vCustomers.count > 0 then
        for vIndex in vCustomers.first .. vCustomers.last loop
          vSqlMsg      := null;
          aTotalCount  := aTotalCount + 1;
          savepoint SP_BeforeGenerate;

          begin
            -- Génération de l'entête du document
            aSCH_BILL_HEADER_ID                    :=
              SCH_BILLING_FUNCTIONS.InsertBillHeader(0
                                                   , vCustomers(vIndex).SCH_STUDENT_ID
                                                   , vCustomers(vIndex).STU_ACCOUNT_NUMBER
                                                   , vCustomers(vIndex).PAC_CUSTOM_PARTNER_ID
                                                   , vCustomers(vIndex).ACS_VAT_DET_ACCOUNT_ID
                                                   , vCustomers(vIndex).ACS_FIN_ACC_S_PAYMENT_ID
                                                   , vCustomers(vIndex).DIC_TYPE_SUBMISSION_ID
                                                   , aACS_FINANCIAL_CURRENCY_ID
                                                   , aDOC_GAUGE_ID
                                                   , aSCH_GROUP_YEAR_PERIOD_ID
                                                   , vCustomers(vIndex).STU_OUT_OTHER_ADDRESS
                                                   , vCustomers(vIndex).PER_KEY1
                                                   , aC_GROUPING_MODE
                                                   , nvl(aPAC_PAYMENT_CONDITION_ID, vCustomers(vIndex).PAC_PAYMENT_CONDITION_ID)
                                                   , iDateDocument
                                                   , aDMT_DATE_VALUE
                                                    );
            -- Stockage de la facture générée, dans le tableau
            vCustomers(vIndex).SCH_BILL_HEADER_ID  := aSCH_BILL_HEADER_ID;
            -- Forcage d'un gabarit spécifique individualisé
            lvSchPrcOutlayForceDocGauge            := PCS.PC_CONFIG.GetConfig('SCH_PRC_OUTLAY_FORCE_DOC_GAUGE');
            lnIndivDOC_GAUGE_ID                    := null;

            if not lvSchPrcOutlayForceDocGauge is null then
              GetDocGaugeIndiv(lvSchPrcOutlayForceDocGauge, aSCH_BILL_HEADER_ID, lnIndivDOC_GAUGE_ID);

              if nvl(lnIndivDOC_GAUGE_ID, 0) <> 0 then
                update SCH_BILL_HEADER
                   set DOC_GAUGE_ID = lnIndivDOC_GAUGE_ID
                 where SCH_BILL_HEADER_ID = aSCH_BILL_HEADER_ID;
              end if;
            end if;

            if nvl(lnIndivDOC_GAUGE_ID, 0) = 0 then
              lnIndivDOC_GAUGE_ID  := aDOC_GAUGE_ID;
            end if;

            aBOP_SEQ                               := aSEQInterval;

            -- Sélection des débours correspondants
            for tplAllOutlays in crAllOutlays(vCustomers(vIndex).PAC_CUSTOM_PARTNER_ID, vCustomers(vIndex).SCH_STUDENT_ID) loop
              -- Calcul des montant TTC, configuration schooling
              if aUseCase = ucSchooling then
                CalcRoundedOutlayAmount(tplAllOutlays.EOU_QTY
                                      , tplAllOutlays.EOU_TTC_AMOUNT
                                      , tplAllOutlays.COU_NULL_MARGIN
                                      , tplAllOutlays.COU_MARGIN_TYPE
                                      , tplAllOutlays.COU_UNIT_MARGIN
                                      , tplAllOutlays.EOU_MARGIN_AMOUNT
                                      , tplAllOutlays.EOU_MARGIN_RATE
                                      , aTTC_AMOUNT
                                      , aTTC_UNIT_AMOUNT
                                       );
              else
                aTTC_UNIT_AMOUNT  := tplAllOutlays.EOU_TTC_AMOUNT;
                aTTC_AMOUNT       := tplAllOutlays.EOU_QTY * aTTC_UNIT_AMOUNT;
              end if;

              -- Génération des positions
              aSCH_BILL_POSITION_ID  :=
                SCH_BILLING_FUNCTIONS.InsertBillPosition(aSCH_BILL_HEADER_ID
                                                       , tplAllOutlays.SCH_STUDENT_ID
                                                       , null
                                                       , null
                                                       , null
                                                       , tplAllOutlays.SCH_OUTLAY_ID
                                                       , tplAllOutlays.SCH_OUTLAY_CATEGORY_ID
                                                       , tplAllOutlays.SCH_YEAR_PERIOD_ID
                                                       , tplAllOutlays.PAC_CUSTOM_PARTNER_ID
                                                       , lnIndivDOC_GAUGE_ID
                                                       , tplAllOutlays.GCO_GOOD_ID
                                                       , tplAllOutlays.OUT_MAJOR_REFERENCE
                                                       , tplAllOutlays.COU_MAJOR_REFERENCE
                                                       , tplAllOutlays.OUT_SECONDARY_REFERENCE
                                                       , tplAllOutlays.COU_SECONDARY_REFERENCE
                                                       , tplAllOutlays.COU_SHORT_DESCR
                                                       , tplAllOutlays.COU_LONG_DESCR
                                                       , tplAllOutlays.COU_FREE_DESCR
                                                       , tplAllOutlays.STU_ACCOUNT_NUMBER
                                                       , 0
                                                       , 0
                                                       , aTTC_AMOUNT
                                                       , aTTC_UNIT_AMOUNT
                                                       , tplAllOutlays.EOU_QTY
                                                       , vCustomers(vIndex).DIC_TYPE_SUBMISSION_ID
                                                       , vCustomers(vIndex).ACS_VAT_DET_ACCOUNT_ID
                                                       , aDMT_DATE_VALUE
                                                       , aBOP_SEQ
                                                       , tplAllOutlays.SCH_ENTERED_OUTLAY_ID
                                                       , aUseCase
                                                        );
              aBOP_SEQ               := aBOP_SEQ + aSEQInterval;
            end loop;
          exception
            when others then
              vSqlMsg  :=
                PCS.PC_FUNCTIONS.TranslateWord('Erreur lors de la génération de la facture : ') ||
                chr(13) ||
                '(' ||
                PCS.PC_FUNCTIONS.TranslateWord('Elève : ') ||
                vCustomers(vIndex).SCH_STUDENT_ID ||
                PCS.PC_FUNCTIONS.TranslateWord('Débiteur : ') ||
                vCustomers(vIndex).PAC_CUSTOM_PARTNER_ID ||
                PCS.PC_FUNCTIONS.TranslateWord(')') ||
                chr(13) ||
                'détail : ' ||
                DBMS_UTILITY.FORMAT_ERROR_STACK ||
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          end;

          -- Annulation du traitement de génération de la facture en cours s'il y a eu le moindre problème
          if vSqlMsg is not null then
            rollback to savepoint SP_BeforeGenerate;

            -- Génération d'une erreur pour affichage
            insert into COM_LIST_ID_TEMP
                        (COM_LIST_ID_TEMP_ID
                       , LID_DESCRIPTION
                       , LID_CODE
                        )
                 values (GetNewId
                       , vSqlMsg
                       , 'BILLING_OUTLAY_ERRORS'
                        );
          -- Execution de la procédure stockée de post-traitement
          else
            begin
              -- Execution de la procédure stockée de post-traitement
              if vSCH_PREBILL_DET_AFTER_PROC is not null then
                execute immediate 'begin :Result :=  ' || vSCH_PREBILL_DET_AFTER_PROC || '(:SCH_BILL_HEADER_ID); end;'
                            using out vProcResult, in aSCH_BILL_HEADER_ID;

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
                    chr(13) ||
                    chr(10) ||
                    DBMS_UTILITY.FORMAT_ERROR_STACK;
                end;
            end;
          end if;

          -- Insertions d'éventuels messages d'erreur dans la table
          if vSqlMsg is not null then
            rollback to savepoint SP_BeforeGenerate;

            -- Génération d'une erreur pour affichage
            insert into COM_LIST_ID_TEMP
                        (COM_LIST_ID_TEMP_ID
                       , LID_DESCRIPTION
                       , LID_CODE
                        )
                 values (GetNewId
                       , vSqlMsg
                       , 'BILLING_OUTLAY_ERRORS'
                        );
          else
            aSuccessfulCount  := aSuccessfulCount + 1;
          end if;
        end loop;
      end if;

      -- Mise à jour des liens mère filles de positions
      if vCustomers.count > 0 then
        for vIndex in vCustomers.first .. vCustomers.last loop
          for tplNewPositions in (select POS.SCH_BILL_POSITION_ID
                                       , POS.SCH_ENTERED_OUTLAY_ID
                                       , EOU.SCH_FATHER_ENTERED_OUTLAY_ID
                                    from SCH_BILL_POSITION POS
                                       , SCH_ENTERED_OUTLAY EOU
                                   where POS.SCH_BILL_HEADER_ID = vCustomers(vIndex).SCH_BILL_HEADER_ID
                                     and POS.SCH_ENTERED_OUTLAY_ID = EOU.SCH_ENTERED_OUTLAY_ID
                                     and EOU.SCH_FATHER_ENTERED_OUTLAY_ID is not null) loop
            update SCH_BILL_POSITION POS
               set SCH_FATHER_POSITION_ID = (select max(POS2.SCH_BILL_POSITION_ID)
                                               from SCH_BILL_POSITION POS2
                                              where POS2.SCH_ENTERED_OUTLAY_ID = tplNewPositions.SCH_FATHER_ENTERED_OUTLAY_ID)
             where SCH_BILL_POSITION_ID = tplNewPositions.SCH_BILL_POSITION_ID;
          end loop;
        end loop;
      end if;

      -- Un document par débiteur
      if aC_GROUPING_MODE = '0' then
        close crProcessByCustomer;
      -- Un document par débiteur et par élève
      else
        close crProcessByCustAndStudent;
      end if;
    end if;
  end ProcessOutlayBilling;

  /**
  * function CalcRoundedOutlayAmount
  * Description : calcul des montants arrondis des débours facturés
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   EOU_QTY : Qté.
  * @param   aEOU_TTC_AMOUNT : Montant TTC
  * @param   aCOU_NULL_MARGIN : Marge sur montant = 0
  * @param   aCOU_MARGIN_TYPE : Marge de type taux ou montant
  * @param   aCOU_UNIT_MARGIN : Marge unitaire ou globale
  * @param   aEOU_MARGIN_AMOUNT : Montant de marge
  * @param   aEOU_MARGIN_RATE : Taux marge
  * @return  aTTC_AMOUNT  : montant TTC total calculé
  * @return  aTTC_UNIT_AMOUNT : montant TTC unitaire calculé
  */
  procedure CalcRoundedOutlayAmount(
    aEOU_QTY           in     number
  , aEOU_TTC_AMOUNT    in     number
  , aCOU_NULL_MARGIN   in     integer
  , aCOU_MARGIN_TYPE   in     integer
  , aCOU_UNIT_MARGIN   in     integer
  , aEOU_MARGIN_AMOUNT in     number
  , aEOU_MARGIN_RATE   in     number
  , aTTC_AMOUNT        in out number
  , aTTC_UNIT_AMOUNT   in out number
  )
  is
  begin
    -- Calcul du montant
    aTTC_AMOUNT  := aEOU_QTY * aEOU_TTC_AMOUNT;

    if    (aTTC_AMOUNT <> 0)
       or (    aTTC_AMOUNT = 0
           and aCOU_NULL_MARGIN = 1) then
      -- Type de marge = Montant
      if aCOU_MARGIN_TYPE = 1 then
        -- Marge unitaire
        if aCOU_UNIT_MARGIN = 1 then
          aTTC_AMOUNT  := aTTC_AMOUNT +(aEOU_QTY * nvl(aEOU_MARGIN_AMOUNT, 0) );
        -- Marge globale
        else
          aTTC_AMOUNT  := aTTC_AMOUNT + nvl(aEOU_MARGIN_AMOUNT, 0);
        end if;
      -- Type de marge = taux.
      else
        if aCOU_UNIT_MARGIN = 1 then
          aTTC_AMOUNT  := (aEOU_TTC_AMOUNT *(1 +(nvl(aEOU_MARGIN_RATE, 0) / 100) ) ) * aEOU_QTY;
        -- Marge globale
        else
          aTTC_AMOUNT  := aTTC_AMOUNT *(1 +(nvl(aEOU_MARGIN_RATE, 0) / 100) );
        end if;
      end if;
    end if;

    --Une fois la marge calculée, on arrondi à 0.05 près
    aTTC_AMOUNT  := ACS_FUNCTION.RoundNear(aTTC_AMOUNT, 0.05, 0);

    if nvl(aEOU_QTY, 0) <> 0 then
      aTTC_UNIT_AMOUNT  := aTTC_AMOUNT / aEOU_QTY;
    else
      aTTC_UNIT_AMOUNT  := aTTC_AMOUNT;
    end if;
  end CalcRoundedOutlayAmount;

  /**
  * procedure UpdateOutlayPositionAmounts
  * Description : Mise à jour après modification manuelle
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_BILL_POSITION_ID : Facture à recalculer
  */
  procedure UpdateOutlayPositionAmounts(iSCH_BILL_POSITION_ID in number, iNewQty number, iNewTTCUnitAmount number)
  is
    liCOU_NULL_MARGIN   integer;
    liCOU_MARGIN_TYPE   integer;
    liCOU_UNIT_MARGIN   integer;
    lnEOU_MARGIN_AMOUNT number;
    lnEOU_MARGIN_RATE   number;
    lnTTC_AMOUNT        number;
    lnTTC_UNIT_AMOUNT   number;
    lnACS_TAX_CODE_ID   number;
    lnBOP_VAT_AMOUNT    number;
  begin
    for tplBillPosition in (select EOU.SCH_ENTERED_OUTLAY_ID
                                 , EOU.EOU_MARGIN_AMOUNT
                                 , EOU.EOU_MARGIN_RATE
                                 , COU.COU_NULL_MARGIN
                                 , COU.COU_MARGIN_TYPE
                                 , COU.COU_UNIT_MARGIN
                                 , COU.GCO_GOOD_ID
                                 , HEA.DOC_GAUGE_ID
                                 , HEA.PAC_CUSTOM_PARTNER_ID
                                 , nvl(HEA_VALUE_DATE, sysdate) HEA_VALUE_DATE
                              from SCH_BILL_HEADER HEA
                                 , SCH_BILL_POSITION BOP
                                 , SCH_ENTERED_OUTLAY EOU
                                 , SCH_OUTLAY_CATEGORY COU
                             where HEA.SCH_BILL_HEADER_ID = BOP.SCH_BILL_HEADER_ID
                               and BOP.SCH_BILL_POSITION_ID = iSCH_BILL_POSITION_ID
                               and BOP.SCH_ENTERED_OUTLAY_ID = EOU.SCH_ENTERED_OUTLAY_ID
                               and EOU.SCH_OUTLAY_CATEGORY_ID = COU.SCH_OUTLAY_CATEGORY_ID) loop
      -- Mise à jour de la pré-saisie liée
      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_SCH_ENTITY.gcschenteredoutlay, ltCRUD_DEF, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_ENTERED_OUTLAY_ID', tplBillPosition.SCH_ENTERED_OUTLAY_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_QTY', iNewQty);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_TTC_AMOUNT', iNewTTCUnitAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;

      -- Calcul des montants TTC, TTC unitaires en fonction des marges paramétrées et arrondis
      CalcRoundedOutlayAmount(iNewQty
                            , iNewTTCUnitAmount
                            , tplBillPosition.COU_NULL_MARGIN
                            , tplBillPosition.COU_MARGIN_TYPE
                            , tplBillPosition.COU_UNIT_MARGIN
                            , tplBillPosition.EOU_MARGIN_AMOUNT
                            , tplBillPosition.EOU_MARGIN_RATE
                            , lnTTC_AMOUNT
                            , lnTTC_UNIT_AMOUNT
                             );
      -- Calcul inverse de la TVA
      ACS_VAT_FCT.GetVatInformations(1   -- Position Bien
                                   , tplBillPosition.DOC_GAUGE_ID
                                   , tplBillPosition.PAC_CUSTOM_PARTNER_ID
                                   , tplBillPosition.GCO_GOOD_ID
                                   , null
                                   , null
                                   , 'I'
                                   , tplBillPosition.HEA_VALUE_DATE
                                   , lnACS_TAX_CODE_ID
                                   , lnTTC_AMOUNT
                                   , lnBOP_VAT_AMOUNT
                                    );

      -- Mise  à jour de la position
      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_SCH_ENTITY.gcschbillposition, ltCRUD_DEF, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_BILL_POSITION_ID', iSCH_BILL_POSITION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BOP_QTY', iNewQty);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BOP_TTC_UNIT_AMOUNT', lnTTC_UNIT_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BOP_TTC_AMOUNT', lnTTC_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BOP_HT_AMOUNT', lnTTC_AMOUNT - lnBOP_VAT_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BOP_VAT_AMOUNT', lnBOP_VAT_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;

      exit;
    end loop;
  end UpdateOutlayPositionAmounts;

  /**
  * procedure UpdateEnteredOutlay
  * Description : Mise à jour des débours avant facturation
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure UpdateEnteredOutlay
  is
    lnPAC_CUSTOM_PARTNER_ID number;
    lnEOU_QTY               number;
    lnAmount                number;
  begin
    for tplOutlayToUpdate in (select SCH_ENTERED_OUTLAY_ID
                                   , SCH_STUDENT_ID
                                   , SCH_OUTLAY_ID
                                   , SCH_OUTLAY_CATEGORY_ID
                                   , EOU_BASIS_QUANTITY
                                   , EOU_VALUE_DATE
                                from SCH_ENTERED_OUTLAY
                               where PAC_CUSTOM_PARTNER_ID is null
                                 and EOU_STATUS = 1) loop
      -- Recherche du débiteur
      SCH_OUTLAY_FUNCTIONS.GetCustomerByAssociation(tplOutlayToUpdate.SCH_STUDENT_ID
                                                  , tplOutlayToUpdate.SCH_OUTLAY_ID
                                                  , tplOutlayToUpdate.SCH_OUTLAY_CATEGORY_ID
                                                  , null
                                                  , null
                                                  , tplOutlayToUpdate.EOU_VALUE_DATE
                                                  , ucFundation
                                                  , lnPAC_CUSTOM_PARTNER_ID
                                                   );

      -- Si débiteur trouvé
      if lnPAC_CUSTOM_PARTNER_ID is not null then
        -- re-valorisation de la quantité
        lnEOU_QTY  :=
          SCH_OUTLAY_FUNCTIONS.GetValorizedQuantity(tplOutlayToUpdate.SCH_STUDENT_ID
                                                  , lnPAC_CUSTOM_PARTNER_ID
                                                  , tplOutlayToUpdate.EOU_BASIS_QUANTITY
                                                  , tplOutlayToUpdate.EOU_VALUE_DATE
                                                  , tplOutlayToUpdate.SCH_OUTLAY_ID
                                                  , tplOutlayToUpdate.SCH_OUTLAY_CATEGORY_ID
                                                   );
        -- Re-Cherche du tariff
        lnAmount   :=
          SCH_OUTLAY_FUNCTIONS.GetOutlayTariff(tplOutlayToUpdate.SCH_STUDENT_ID
                                             , lnPAC_CUSTOM_PARTNER_ID
                                             , lnEOU_QTY
                                             , tplOutlayToUpdate.EOU_VALUE_DATE
                                             , tplOutlayToUpdate.SCH_OUTLAY_CATEGORY_ID
                                              );

        -- Mise à jour du débours entrés
        update SCH_ENTERED_OUTLAY
           set PAC_CUSTOM_PARTNER_ID = lnPAC_CUSTOM_PARTNER_ID
             , EOU_QTY = lnEOU_QTY
             , EOU_TTC_AMOUNT = lnAMount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where SCH_ENTERED_OUTLAY_ID = tplOutlayToUpdate.SCH_ENTERED_OUTLAY_ID
           and nvl(lnPAC_CUSTOM_PARTNER_ID, 0) <> 0
           and nvl(lnEOU_QTY, 0) <> 0
           and nvl(lnAmount, 0) <> 0;
      end if;
    end loop;
  end UpdateEnteredOutlay;
end SCH_OUTLAY_BILLING;
