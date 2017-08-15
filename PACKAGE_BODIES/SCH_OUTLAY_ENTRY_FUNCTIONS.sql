--------------------------------------------------------
--  DDL for Package Body SCH_OUTLAY_ENTRY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_OUTLAY_ENTRY_FUNCTIONS" 
is
  /**
  * procedure SplitSchEnteredOutlayIndiv
  * Description : Appel de la procédure individualisée définie dans la configuration
  *               pour le Split des présaisies
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   lcSchPrcSplitSchOutlayEntry : procedure
  * @param   ioEOU_QTY : Quantité valorizée
  * @param   ioExecStandard : Execution standard
  *
  */
  procedure SplitSchEnteredOutlayIndiv(lcSchPrcSplitSchOutlayEntry varchar2, iSCH_ENTERED_OUTLAY_ID in number, ioExecStandard in out integer)
  is
    lvPrcSql varchar2(2000);
  begin
    lvPrcSql  := ' begin ';
    lvPrcSql  := lvPrcSql || lcSchPrcSplitSchOutlayEntry || '(:iSCH_ENTERED_OUTLAY_ID,' || ' :ioExecStandard);';
    lvPrcSql  := lvPrcSql || ' end; ';

    execute immediate lvPrcSql
                using in iSCH_ENTERED_OUTLAY_ID, in out ioExecStandard;
  end SplitSchEnteredOutlayIndiv;

  /**
  * procedure InsertSchEnteredOutlay
  * Description : Insertion
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @paramètres champs de la table SCH_ENTERED_OUTLAY
  */
  procedure InsertSchEnteredOutlay(
    iSCH_ENTERED_OUTLAY_ID        in number
  , iSCH_OUTLAY_ID                in number default null
  , iSCH_OUTLAY_CATEGORY_ID       in number default null
  , iPAC_CUSTOM_PARTNER_ID        in number default null
  , iSCH_STUDENT_ID               in number default null
  , iEOU_STATUS                   in number default null
  , iEOU_PIECE_NUMBER             in varchar2 default null
  , iEOU_QTY                      in number default null
  , iEOU_TTC_AMOUNT               in number default null
  , iEOU_MARGIN_RATE              in number default null
  , iEOU_MARGIN_AMOUNT            in number default null
  , iSCH_YEAR_PERIOD_ID           in number default null
  , iSCH_SCHOOL_YEAR_ID           in number default null
  , iEOU_SESSION                  in varchar2 default null
  , iEOU_VALUE_DATE               in date default sysdate
  , iEOU_BASIS_QUANTITY           in number default 1
  , iSCH_FATHER_ENTERED_OUTLAY_ID in number default null
  , iEOU_COMMENT                  in varchar2 default null
  )
  is
  begin
    declare
      ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      FWK_I_MGT_ENTITY.new(FWK_TYP_SCH_ENTITY.gcSchEnteredOutlay, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_ENTERED_OUTLAY_ID', iSCH_ENTERED_OUTLAY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_OUTLAY_ID', iSCH_OUTLAY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_OUTLAY_CATEGORY_ID', iSCH_OUTLAY_CATEGORY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER_ID', iPAC_CUSTOM_PARTNER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_STUDENT_ID', iSCH_STUDENT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_STATUS', 1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_PIECE_NUMBER', iEOU_PIECE_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_QTY', iEOU_QTY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_TTC_AMOUNT', iEOU_TTC_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_MARGIN_RATE', iEOU_MARGIN_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_MARGIN_AMOUNT', iEOU_MARGIN_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_YEAR_PERIOD_ID', iSCH_YEAR_PERIOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_SCHOOL_YEAR_ID', iSCH_SCHOOL_YEAR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_SESSION', iEOU_SESSION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_VALUE_DATE', iEOU_VALUE_DATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_BASIS_QUANTITY', iEOU_BASIS_QUANTITY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_FATHER_ENTERED_OUTLAY_ID', iSCH_FATHER_ENTERED_OUTLAY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EOU_COMMENT', iEOU_COMMENT);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end;
  end InsertSchEnteredOutlay;

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
  */
  procedure SelectStudents(
    aSTU_NAME_FROM           varchar2
  , aSTU_NAME_TO             varchar2
  , aSTU_ACCOUNT_NUMBER_FROM integer
  , aSTU_ACCOUNT_NUMBER_TO   integer
  , aSTU_ENTRY_DATE_FROM     date
  , aSTU_ENTRY_DATE_TO       date
  , aSTU_EXIT_DATE_FROM      date
  , aSTU_EXIT_DATE_TO        date
  , aSTUDENT_STATUS          varchar2
  , aEDUCATION_DEGREE        varchar2
  , aSTU_SCHOOL_YEAR         integer
  , aSTU_CLASS               varchar2
  , aSCH_YEAR_PERIOD_ID      number
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
                                      , 1
                                      , aSCH_YEAR_PERIOD_ID
                                       );
  end SelectStudents;

  /**
  * procedure GenerateGroupedOutlay
  * Description : Génération groupée des débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aEOU_QTY : Qté
  * @param   aEOU_TTC_AMOUNT : Montant TTC
  * @param   aEOU_PIECE_NUMBER : Numéro de pièce
  * @param   aSCH_YEAR_PERIOD_ID : Période
  * @param   aEOU_SESSION : Session oracle
  * @param   aUseCase : Cas d'utilisation
  * @param   aGenFreeData : Génération de données libres
  * @param   aSFD_* : Données libres
  */
  procedure GenerateGroupedOutlay(
    aSCH_OUTLAY_ID          number
  , aSCH_OUTLAY_CATEGORY_ID number
  , aEOU_QTY                number
  , aEOU_TTC_AMOUNT         number
  , aEOU_PIECE_NUMBER       varchar2
  , aSCH_YEAR_PERIOD_ID     number
  , aEOU_SESSION            varchar2
  , aUseCase                integer default 0
  , aGenFreeData            integer default 0
  , aDIC_SCH_FREE_TABLE1_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE2_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE3_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE4_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE5_ID varchar2 default null
  , aSFD_ALPHA_SHORT_1      varchar2 default null
  , aSFD_ALPHA_SHORT_2      varchar2 default null
  , aSFD_ALPHA_SHORT_3      varchar2 default null
  , aSFD_ALPHA_SHORT_4      varchar2 default null
  , aSFD_ALPHA_SHORT_5      varchar2 default null
  , aSFD_ALPHA_LONG_1       varchar2 default null
  , aSFD_ALPHA_LONG_2       varchar2 default null
  , aSFD_ALPHA_LONG_3       varchar2 default null
  , aSFD_ALPHA_LONG_4       varchar2 default null
  , aSFD_ALPHA_LONG_5       varchar2 default null
  , aSFD_INTEGER_1          integer default null
  , aSFD_INTEGER_2          integer default null
  , aSFD_INTEGER_3          integer default null
  , aSFD_INTEGER_4          integer default null
  , aSFD_INTEGER_5          integer default null
  , aSFD_BOOLEAN_1          integer default null
  , aSFD_BOOLEAN_2          integer default null
  , aSFD_BOOLEAN_3          integer default null
  , aSFD_BOOLEAN_4          integer default null
  , aSFD_BOOLEAN_5          integer default null
  , aSFD_DECIMAL_1          number default null
  , aSFD_DECIMAL_2          number default null
  , aSFD_DECIMAL_3          number default null
  , aSFD_DECIMAL_4          number default null
  , aSFD_DECIMAL_5          number default null
  , aSFD_DATE_1             date default null
  , aSFD_DATE_2             date default null
  , aSFD_DATE_3             date default null
  , aSFD_DATE_4             date default null
  , aSFD_DATE_5             date default null
  , aSFD_TRANSFERT          integer default null
  )
  is
    cursor crSelectedStudent
    is
      select STU.SCH_STUDENT_ID
           , STU.STU_ACCOUNT_NUMBER
           , STU.PAC_CUSTOM_PARTNER2_ID
           , out.OUT_MAJOR_REFERENCE
           , COU.COU_MAJOR_REFERENCE
           , nvl(STU.STU_OUT_MIXED_BILLING, 0) STU_OUT_MIXED_BILLING
           , nvl(STU.STU_OUT_OTHER_ADDRESS, 0) STU_OUT_OTHER_ADDRESS
           , YEA.SCH_SCHOOL_YEAR_ID
           , COU.COU_MARGIN_RATE
           , COU.COU_MARGIN_AMOUNT
           , COU.COU_QTY
        from SCH_STUDENT STU
           , COM_LIST_ID_TEMP LID
           , SCH_OUTLAY out
           , SCH_OUTLAY_CATEGORY COU
           , SCH_YEAR_PERIOD YEA
       where STU.SCH_STUDENT_ID = LID.COM_LIST_ID_TEMP_ID
         and LID.LID_CODE = 'SCH_STUDENT_ID'
         and out.SCH_OUTLAY_ID = aSCH_OUTLAY_ID
         and out.SCH_OUTLAY_ID = COU.SCH_OUTLAY_ID
         and COU.SCH_OUTLAY_CATEGORY_ID = aSCH_OUTLAY_CATEGORY_ID
         and YEA.SCH_YEAR_PERIOD_ID = aSCH_YEAR_PERIOD_ID;

    aPAC_CUSTOM_PARTNER_ID number;
    aSCH_ENTERED_OUTLAY_ID number;
    ldEOU_VALUE_DATE       date;
    lnEOU_QTY              number;
    lnEOU_TTC_AMOUNT       number;
  begin
    for tplSelectedStudent in crSelectedStudent loop
      aPAC_CUSTOM_PARTNER_ID  := null;
      -- Date valeur = Date début + 1 de la période
      ldEOU_VALUE_DATE        := nvl(SCH_TOOLS.GetPeriodStartDate(aSCH_YEAR_PERIOD_ID), sysdate);
      -- Recherche du débiteur : les associations sont prioritaires
      SCH_OUTLAY_FUNCTIONS.GetCustomerByAssociation(tplSelectedStudent.SCH_STUDENT_ID
                                                  , aSCH_OUTLAY_ID
                                                  , aSCH_OUTLAY_CATEGORY_ID
                                                  , null
                                                  , null
                                                  , ldEOU_VALUE_DATE
                                                  , aUseCase
                                                  , aPAC_CUSTOM_PARTNER_ID
                                                   );

      -- Débiteur spécifique
      if     aPAC_CUSTOM_PARTNER_ID is null
         and aUseCase = SCh_OUTLAY_BILLING.ucSchooling then
        aPAC_CUSTOM_PARTNER_ID  := tplSelectedStudent.PAC_CUSTOM_PARTNER2_ID;
      end if;

      -- Valorisation de la quantité
      lnEOU_QTY               := nvl(tplSelectedStudent.COU_QTY, aEOU_QTY);

      if nvl(lnEOU_QTY, 0) = 0 then
        lnEOU_QTY  := 1;
      end if;

      if aUseCase = SCH_OUTLAY_BILLING.ucFundation then
        lnEOU_QTY  :=
          SCH_OUTLAY_FUNCTIONS.GetValorizedQuantity(tplSelectedStudent.SCH_STUDENT_ID
                                                  , aPAC_CUSTOM_PARTNER_ID
                                                  , lnEOU_QTY
                                                  , ldEOU_VALUE_DATE
                                                  , aSCH_OUTLAY_ID
                                                  , aSCH_OUTLAY_CATEGORY_ID
                                                   );
      end if;

      -- Recherche du tarif
      if     aUseCase = SCH_OUTLAY_BILLING.ucSchooling
         and nvl(aEOU_TTC_AMOUNT, 0) <> 0 then
        lnEOU_TTC_AMOUNT  := aEOU_TTC_AMOUNT;
      else
        lnEOU_TTC_AMOUNT  :=
          SCH_OUTLAY_FUNCTIONS.GetOutlayTariff(tplSelectedStudent.SCH_STUDENT_ID, aPAC_CUSTOM_PARTNER_ID, lnEOU_QTY, ldEOU_VALUE_DATE, aSCH_OUTLAY_CATEGORY_ID);
      end if;

      -- Insertion du débours
      if    (    aUseCase = SCH_OUTLAY_BILLING.ucSchooling
             and aPAC_CUSTOM_PARTNER_ID is not null)
         or (aUseCase = SCH_OUTLAY_BILLING.ucFundation) then
        aSCH_ENTERED_OUTLAY_ID  := GetNewId;
        InsertSchEnteredOutlay(iSCH_ENTERED_OUTLAY_ID    => aSCH_ENTERED_OUTLAY_ID
                             , iSCH_OUTLAY_ID            => aSCH_OUTLAY_ID
                             , iSCH_OUTLAY_CATEGORY_ID   => aSCH_OUTLAY_CATEGORY_ID
                             , iPAC_CUSTOM_PARTNER_ID    => aPAC_CUSTOM_PARTNER_ID
                             , iSCH_STUDENT_ID           => tplSelectedStudent.SCH_STUDENT_ID
                             , iEOU_STATUS               => 1
                             , iEOU_PIECE_NUMBER         => aEOU_PIECE_NUMBER
                             , iEOU_QTY                  => lnEOU_QTY
                             , iEOU_TTC_AMOUNT           => lnEOU_TTC_AMOUNT
                             , iEOU_MARGIN_RATE          => tplSelectedStudent.COU_MARGIN_RATE
                             , iEOU_MARGIN_AMOUNT        => tplSelectedStudent.COU_MARGIN_AMOUNT
                             , iSCH_YEAR_PERIOD_ID       => aSCH_YEAR_PERIOD_ID
                             , iSCH_SCHOOL_YEAR_ID       => tplSelectedStudent.SCH_SCHOOL_YEAR_ID
                             , iEOU_SESSION              => aEOU_SESSION
                             , iEOU_VALUE_DATE           => ldEOU_VALUE_DATE
                             , iEOU_BASIS_QUANTITY       => aEOU_QTY
                              );

        -- Insertion données libres
        if aGenFreeData = 1 then
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
                     , SFD_TRANSFERT
                      )
               values (GetNewId
                     , aSCH_ENTERED_OUTLAY_ID
                     , aDIC_SCH_FREE_TABLE1_ID
                     , aDIC_SCH_FREE_TABLE2_ID
                     , aDIC_SCH_FREE_TABLE3_ID
                     , aDIC_SCH_FREE_TABLE4_ID
                     , aDIC_SCH_FREE_TABLE5_ID
                     , aSFD_ALPHA_SHORT_1
                     , aSFD_ALPHA_SHORT_2
                     , aSFD_ALPHA_SHORT_3
                     , aSFD_ALPHA_SHORT_4
                     , aSFD_ALPHA_SHORT_5
                     , aSFD_ALPHA_LONG_1
                     , aSFD_ALPHA_LONG_2
                     , aSFD_ALPHA_LONG_3
                     , aSFD_ALPHA_LONG_4
                     , aSFD_ALPHA_LONG_5
                     , aSFD_INTEGER_1
                     , aSFD_INTEGER_2
                     , aSFD_INTEGER_3
                     , aSFD_INTEGER_4
                     , aSFD_INTEGER_5
                     , aSFD_BOOLEAN_1
                     , aSFD_BOOLEAN_2
                     , aSFD_BOOLEAN_3
                     , aSFD_BOOLEAN_4
                     , aSFD_BOOLEAN_5
                     , aSFD_DECIMAL_1
                     , aSFD_DECIMAL_2
                     , aSFD_DECIMAL_3
                     , aSFD_DECIMAL_4
                     , aSFD_DECIMAL_5
                     , aSFD_DATE_1
                     , aSFD_DATE_2
                     , aSFD_DATE_3
                     , aSFD_DATE_4
                     , aSFD_DATE_5
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , aSFD_TRANSFERT
                      );
        end if;

        -- Fusion / Génération données libres depuis débours et catégories
        SCH_OUTLAY_FUNCTIONS.CopyFreeDataFromOutlay(aSCH_OUTLAY_ID, aSCH_OUTLAY_CATEGORY_ID, aSCH_ENTERED_OUTLAY_ID);
        -- Split éventuel, y compris données libres
        SplitSchEnteredOutlay(aSCH_ENTERED_OUTLAY_ID, 1);

        -- Sélection de l'enregistrement nouvellement créé
        insert into COM_LIST_ID_TEMP
                    (COM_LIST_ID_TEMP_ID
                   , LID_CODE
                   , LID_FREE_NUMBER_1
                    )
          select SCH_ENTERED_OUTLAY_ID
               , 'SCH_ENTERED_OUTLAY_ID'
               , 1
            from SCH_ENTERED_OUTLAY
           where SCH_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID
              or SCH_FATHER_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID;
      end if;
    end loop;
  end GenerateGroupedOutlay;

  /**
  * procedure GeneratePeriodicOutlay
  * Description : Génération périodique des débours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aEOU_QTY : Qté
  * @param   aEOU_TTC_AMOUNT : Montant TTC
  * @param   aSCH_YEAR_PERIOD_ID : Période
  * @param   aEOU_PIECE_NUMBER : Numéro de pièce
  * @param   aEOU_SESSION : Session oracle
  * @param   aGenFreeData : Génération de données libres
  * @param   aSFD_* : Données libres
  */
  procedure GeneratePeriodicOutlay(
    aSCH_OUTLAY_ID          number
  , aSCH_OUTLAY_CATEGORY_ID number
  , aEOU_QTY                number
  , aEOU_TTC_AMOUNT         number
  , aSCH_YEAR_PERIOD_ID     number
  , aEOU_PIECE_NUMBER       varchar2
  , aEOU_SESSION            varchar2
  , aGenFreeData            integer default 0
  , aUseCase                integer default 0
  , aDIC_SCH_FREE_TABLE1_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE2_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE3_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE4_ID varchar2 default null
  , aDIC_SCH_FREE_TABLE5_ID varchar2 default null
  , aSFD_ALPHA_SHORT_1      varchar2 default null
  , aSFD_ALPHA_SHORT_2      varchar2 default null
  , aSFD_ALPHA_SHORT_3      varchar2 default null
  , aSFD_ALPHA_SHORT_4      varchar2 default null
  , aSFD_ALPHA_SHORT_5      varchar2 default null
  , aSFD_ALPHA_LONG_1       varchar2 default null
  , aSFD_ALPHA_LONG_2       varchar2 default null
  , aSFD_ALPHA_LONG_3       varchar2 default null
  , aSFD_ALPHA_LONG_4       varchar2 default null
  , aSFD_ALPHA_LONG_5       varchar2 default null
  , aSFD_INTEGER_1          integer default null
  , aSFD_INTEGER_2          integer default null
  , aSFD_INTEGER_3          integer default null
  , aSFD_INTEGER_4          integer default null
  , aSFD_INTEGER_5          integer default null
  , aSFD_BOOLEAN_1          integer default null
  , aSFD_BOOLEAN_2          integer default null
  , aSFD_BOOLEAN_3          integer default null
  , aSFD_BOOLEAN_4          integer default null
  , aSFD_BOOLEAN_5          integer default null
  , aSFD_DECIMAL_1          number default null
  , aSFD_DECIMAL_2          number default null
  , aSFD_DECIMAL_3          number default null
  , aSFD_DECIMAL_4          number default null
  , aSFD_DECIMAL_5          number default null
  , aSFD_DATE_1             date default null
  , aSFD_DATE_2             date default null
  , aSFD_DATE_3             date default null
  , aSFD_DATE_4             date default null
  , aSFD_DATE_5             date default null
  , aSFD_TRANSFERT          integer default null
  )
  is
    cursor crPeriodicAssociations(aDateValidity date)
    is
      select CUS.PAC_CUSTOM_PARTNER_ID
           , CUS.SCH_STUDENT_ID
           , CUS.SCH_OUTLAY_ID
           , CUS.SCH_OUTLAY_CATEGORY_ID
           , STU.STU_ACCOUNT_NUMBER
           , out.OUT_MAJOR_REFERENCE
           , COU.COU_MARGIN_AMOUNT
           , COU.COU_MARGIN_RATE
           , COU.COU_QTY
           , COU.COU_UNIT_AMOUNT
           , COU.COU_MAJOR_REFERENCE
           , PER.SCH_SCHOOL_YEAR_ID
        from SCH_CUSTOMERS_ASSOCIATION CUS
           , SCH_STUDENT STU
           , COM_LIST_ID_TEMP LID
           , SCH_OUTLAY out
           , SCH_OUTLAY_CATEGORY COU
           , SCH_YEAR_PERIOD PER
       where CUS.CAS_PERIODIC_BILLING = 1
         and (   nvl(aSCH_OUTLAY_ID, 0) = 0
              or CUS.SCH_OUTLAY_ID = aSCH_OUTLAY_ID)
         and (   nvl(aSCH_OUTLAY_CATEGORY_ID, 0) = 0
              or CUS.SCH_OUTLAY_CATEGORY_ID = aSCH_OUTLAY_CATEGORY_ID)
         and CUS.SCH_OUTLAY_ID = out.SCH_OUTLAY_ID
         and CUS.SCH_OUTLAY_CATEGORY_ID = COU.SCH_OUTLAY_CATEGORY_ID
         and CUS.SCH_STUDENT_ID = STU.SCH_STUDENT_ID
         and STU.SCH_STUDENT_ID = LID.COM_LIST_ID_TEMP_ID
         and LID.LID_CODE = 'SCH_STUDENT_ID'
         and PER.SCH_YEAR_PERIOD_ID = aSCH_YEAR_PERIOD_ID
         and (trunc(aDateValidity) between nvl(CUS.CAS_VALIDITY_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                       and nvl(CUS.CAS_VALIDITY_DATE_TO, to_date('31.12.2999', 'DD.MM.YYYY') )
             );

    aSCH_ENTERED_OUTLAY_ID number;
    aQty                   number;
    aAmount                number;
    ldEOU_VALUE_DATE       date;
    lnEOU_TTC_AMOUNT       number;
  begin
    -- Date valeur = Date début + 1 de la période
    ldEOU_VALUE_DATE  := nvl(SCH_TOOLS.GetPeriodStartDate(aSCH_YEAR_PERIOD_ID), sysdate);

    -- Génération des facturations périoques
    for tplPeriodicAssociations in crPeriodicAssociations(ldEOU_VALUE_DATE) loop
      -- Valorisation de la quantité
      if aUseCase = SCH_OUTLAY_BILLING.ucSchooling then
        aQty  := nvl(tplPeriodicAssociations.COU_QTY, aEOU_QTY);

        if nvl(aQTY, 0) = 0 then
          aQty  := 1;
        end if;
      else
        aQty  :=
          SCH_OUTLAY_FUNCTIONS.GetValorizedQuantity(tplPeriodicAssociations.SCH_STUDENT_ID
                                                  , tplPeriodicAssociations.PAC_CUSTOM_PARTNER_ID
                                                  , nvl(tplPeriodicAssociations.COU_QTY, aEOU_QTY)
                                                  , ldEOU_VALUE_DATE
                                                  , tplPeriodicAssociations.SCH_OUTLAY_ID
                                                  , tplPeriodicAssociations.SCH_OUTLAY_CATEGORY_ID
                                                   );
      end if;

      -- Recherche du tarif
      lnEOU_TTC_AMOUNT        :=
        SCH_OUTLAY_FUNCTIONS.GetOutlayTariff(tplPeriodicAssociations.SCH_STUDENT_ID
                                           , tplPeriodicAssociations.PAC_CUSTOM_PARTNER_ID
                                           , aQty
                                           , ldEOU_VALUE_DATE
                                           , tplPeriodicAssociations.SCH_OUTLAY_CATEGORY_ID
                                            );

      if nvl(lnEOU_TTC_AMOUNT, 0) = 0 then
        lnEOU_TTC_AMOUNT  := aEOU_TTC_AMOUNT;
      end if;

      aSCH_ENTERED_OUTLAY_ID  := GetNewId;
      InsertSchEnteredOutlay(iSCH_ENTERED_OUTLAY_ID    => aSCH_ENTERED_OUTLAY_ID
                           , iSCH_OUTLAY_ID            => tplPeriodicAssociations.SCH_OUTLAY_ID
                           , iSCH_OUTLAY_CATEGORY_ID   => tplPeriodicAssociations.SCH_OUTLAY_CATEGORY_ID
                           , iPAC_CUSTOM_PARTNER_ID    => tplPeriodicAssociations.PAC_CUSTOM_PARTNER_ID
                           , iSCH_STUDENT_ID           => tplPeriodicAssociations.SCH_STUDENT_ID
                           , iEOU_STATUS               => 1
                           , iEOU_PIECE_NUMBER         => aEOU_PIECE_NUMBER
                           , iEOU_QTY                  => aQty
                           , iEOU_TTC_AMOUNT           => lnEOU_TTC_AMOUNT
                           , iEOU_MARGIN_RATE          => tplPeriodicAssociations.COU_MARGIN_RATE
                           , iEOU_MARGIN_AMOUNT        => tplPeriodicAssociations.COU_MARGIN_AMOUNT
                           , iSCH_YEAR_PERIOD_ID       => aSCH_YEAR_PERIOD_ID
                           , iSCH_SCHOOL_YEAR_ID       => tplPeriodicAssociations.SCH_SCHOOL_YEAR_ID
                           , iEOU_SESSION              => aEOU_SESSION
                           , iEOU_VALUE_DATE           => ldEOU_VALUE_DATE
                           , iEOU_BASIS_QUANTITY       => nvl(tplPeriodicAssociations.COU_QTY, aEOU_QTY)
                            );

      -- Insertion données libres
      if aGenFreeData = 1 then
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
                   , SFD_TRANSFERT
                    )
             values (GetNewId
                   , aSCH_ENTERED_OUTLAY_ID
                   , aDIC_SCH_FREE_TABLE1_ID
                   , aDIC_SCH_FREE_TABLE2_ID
                   , aDIC_SCH_FREE_TABLE3_ID
                   , aDIC_SCH_FREE_TABLE4_ID
                   , aDIC_SCH_FREE_TABLE5_ID
                   , aSFD_ALPHA_SHORT_1
                   , aSFD_ALPHA_SHORT_2
                   , aSFD_ALPHA_SHORT_3
                   , aSFD_ALPHA_SHORT_4
                   , aSFD_ALPHA_SHORT_5
                   , aSFD_ALPHA_LONG_1
                   , aSFD_ALPHA_LONG_2
                   , aSFD_ALPHA_LONG_3
                   , aSFD_ALPHA_LONG_4
                   , aSFD_ALPHA_LONG_5
                   , aSFD_INTEGER_1
                   , aSFD_INTEGER_2
                   , aSFD_INTEGER_3
                   , aSFD_INTEGER_4
                   , aSFD_INTEGER_5
                   , aSFD_BOOLEAN_1
                   , aSFD_BOOLEAN_2
                   , aSFD_BOOLEAN_3
                   , aSFD_BOOLEAN_4
                   , aSFD_BOOLEAN_5
                   , aSFD_DECIMAL_1
                   , aSFD_DECIMAL_2
                   , aSFD_DECIMAL_3
                   , aSFD_DECIMAL_4
                   , aSFD_DECIMAL_5
                   , aSFD_DATE_1
                   , aSFD_DATE_2
                   , aSFD_DATE_3
                   , aSFD_DATE_4
                   , aSFD_DATE_5
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                   , aSFD_TRANSFERT
                    );
      end if;

      -- Fusion / Génération données libres depuis débours et catégories
      SCH_OUTLAY_FUNCTIONS.CopyFreeDataFromOutlay(tplPeriodicAssociations.SCH_OUTLAY_ID, tplPeriodicAssociations.SCH_OUTLAY_CATEGORY_ID, aSCH_ENTERED_OUTLAY_ID);
      -- Split éventuel, y compris données libres
      SplitSchEnteredOutlay(aSCH_ENTERED_OUTLAY_ID, 1);

      -- Sélection de l'enregistrement nouvellement créé
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                 , LID_FREE_NUMBER_1
                  )
        select SCH_ENTERED_OUTLAY_ID
             , 'SCH_ENTERED_OUTLAY_ID'
             , 1
          from SCH_ENTERED_OUTLAY
         where SCH_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID
            or SCH_FATHER_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID;
    end loop;
  end GeneratePeriodicOutlay;

  /**
  * procedure FlagSelectedEnteredOutlays
  * Description
  *   Sélection / Désélection dans la table COM_LIST_ID_TEMP, des débours saisis
  *   en génération groupée des débours
  * @version 2003
  * @author ECA 5.11.2008
  * @lastUpdate
  * @public
  * @param   aSCH_ENTERED_OUTLAY_ID : Débours saisis
  * @param   aBlnFlag : Sélectionne / Désélectionne
  */
  procedure FlagSelectedEnteredOutlays(aSCH_ENTERED_OUTLAY_ID number, aBlnFlag integer)
  is
  begin
    update COM_LIST_ID_TEMP
       set LID_FREE_NUMBER_1 = aBlnFlag
     where LID_CODE = 'SCH_ENTERED_OUTLAY_ID'
       and (   nvl(aSCH_ENTERED_OUTLAY_ID, 0) = 0
            or COM_LIST_ID_TEMP_ID = aSCH_ENTERED_OUTLAY_ID);
  end FlagSelectedEnteredOutlays;

  /**
  * procedure ConfirmSelectedOutlay
  * Description
  *   Confirmation de la conservation des débours générés, et sélectionnés
  * @version 2003
  * @author ECA 5.11.2008
  * @lastUpdate
  * @public
  */
  procedure ConfirmSelectedOutlay
  is
  begin
    -- Update des saisies de débours
    update SCH_ENTERED_OUTLAY EOU
       set EOU.EOU_SESSION = null
     where EOU.EOU_SESSION is not null
       and EOU.SCH_ENTERED_OUTLAY_ID in(select LID.COM_LIST_ID_TEMP_ID
                                          from COM_LIST_ID_TEMP LID
                                         where LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID'
                                           and LID.LID_FREE_NUMBER_1 = 1);

    -- Suppression de la sélection
    delete from COM_LIST_ID_TEMP LID
          where LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID'
            and LID.LID_FREE_NUMBER_1 = 1;
  end ConfirmSelectedOutlay;

  /**
  * procedure DeleteUnConfirmedOutlay
  * Description
  *   Suppression des débours générés qui n'ont pas encore été confirmés.
  * @version 2003
  * @author ECA 5.11.2008
  * @lastUpdate
  * @public
  */
  procedure DeleteUnConfirmedOutlay
  is
  begin
    -- Update des saisies de débours
    delete from SCH_ENTERED_OUTLAY EOU
          where EOU.SCH_ENTERED_OUTLAY_ID in(select LID.COM_LIST_ID_TEMP_ID
                                               from COM_LIST_ID_TEMP LID
                                              where LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID')
            and EOU.SCH_FATHER_ENTERED_OUTLAY_ID is not null;

    delete from SCH_ENTERED_OUTLAY EOU
          where EOU.SCH_ENTERED_OUTLAY_ID in(select LID.COM_LIST_ID_TEMP_ID
                                               from COM_LIST_ID_TEMP LID
                                              where LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID');

    -- Suppression de la sélection
    delete from COM_LIST_ID_TEMP LID
          where LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID';
  end DeleteUnConfirmedOutlay;

  /**
  * function ExistsUnConfirmedOutlay
  * Description
  *   teste l'existance de débours en série générés mais non confirmés
  * @version 2003
  * @author ECA 5.11.2008
  * @lastUpdate
  * @public
  * @return   Nbre de débours non confirmés
  */
  function ExistsUnConfirmedOutlay
    return integer
  is
    NbOutlays integer;
  begin
    select count(*)
      into NbOutlays
      from SCH_ENTERED_OUTLAY EOU
     where EOU.EOU_SESSION is not null
       and EOU.SCH_ENTERED_OUTLAY_ID in(select LID.COM_LIST_ID_TEMP_ID
                                          from COM_LIST_ID_TEMP LID
                                         where LID.LID_CODE = 'SCH_ENTERED_OUTLAY_ID');

    return NbOutlays;
  exception
    when others then
      return 0;
  end;

  /**
  * function InsertSchEnteredOutlay
  * Description : Insertion Saisie de débours
  *
  * @version 2003
  * @author ECA 5.11.2008
  * @lastUpdate
  * @public
  * @param   iSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   iPAC_CUSTOM_PARTNER_ID : Client
  * @param   iSCH_STUDENT_ID : ELève
  * @param   iEOU_QTY : Quantité
  * @param   iAMOUNT_TTC : Montant TTC
  * @param   iEOU_PIECE_NUMBER : N° de pièce
  * @param   iEOU_DATEVALUE : Date valeur
  * @param   iSCH_YEAR_PERIOD_ID  number
  * @param   ioSCH_ENTERED_OUTLAY_ID number
  * @param   ioErrorMsg : Message d'erreur éventuel.
  */
  procedure InsertSchEnteredOutlay(
    iSCH_OUTLAY_CATEGORY_ID in     number
  , iPAC_CUSTOM_PARTNER_ID  in     number
  , iSCH_STUDENT_ID         in     number
  , iEOU_BASIS_QUANTITY     in     number
  , iEOU_QTY                in     number
  , iAMOUNT_TTC             in     number
  , iEOU_PIECE_NUMBER       in     varchar2
  , iEOU_VALUE_DATE         in     date
  , iSCH_YEAR_PERIOD_ID     in     number
  , ioSCH_ENTERED_OUTLAY_ID in out number
  , ioErrorMsg              in out varchar2
  , iEOU_COMMENT            in     varchar2 default null
  )
  is
    lnSCH_OUTLAY_ID          number;
    lnSCH_OUTLAY_CATEGORY_ID number;
    lnPAC_CUSTOM_PARTNER_ID  number;
    lnSCH_STUDENT_ID         number;
    lnEOU_BASIS_QUANTITY     number;
    lnEOU_QTY                number;
    lnAMOUNT_TTC             number;
    lnSCH_YEAR_PERIOD_ID     number;
    lnSCH_SCHOOL_YEAR_ID     number;
    lvEOU_PIECE_NUMBER       SCH_ENTERED_OUTLAY.EOU_PIECE_NUMBER%type;
    lnEOU_MARGIN_RATE        number;
    lnEOU_MARGIN_AMOUNT      number;
    ldEOU_VALUE_DATE         date;
    lvEOU_COMMENT            SCH_ENTERED_OUTLAY.EOU_COMMENT%type;
  begin
    ioErrorMsg               := null;
    ioSCH_ENTERED_OUTLAY_ID  := null;

    -- Vérification intégrité période / année
    begin
      select PER.SCH_YEAR_PERIOD_ID
           , SCO.SCH_SCHOOL_YEAR_ID
        into lnSCH_YEAR_PERIOD_ID
           , lnSCH_SCHOOL_YEAR_ID
        from SCH_YEAR_PERIOD PER
           , SCH_SCHOOL_YEAR SCO
       where PER.SCH_YEAR_PERIOD_ID = iSCH_YEAR_PERIOD_ID
         and PER.SCH_SCHOOL_YEAR_ID = SCO.SCH_SCHOOL_YEAR_ID;
    exception
      when no_data_found then
        begin
          ioErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Période de saisie inconnue!');
        end;
    end;

    -- Adaptation de la date si hors période
    ldEOU_VALUE_DATE         := nvl(iEOU_VALUE_DATE, sysdate);

    if ioErrorMsg is null then
      -- Vérification intégrité débours et catégories
      begin
        select out.SCH_OUTLAY_ID
             , CAT.SCH_OUTLAY_CATEGORY_ID
             , CAT.COU_MARGIN_RATE
             , CAT.COU_MARGIN_AMOUNT
          into lnSCH_OUTLAY_ID
             , lnSCH_OUTLAY_CATEGORY_ID
             , lnEOU_MARGIN_RATE
             , lnEOU_MARGIN_AMOUNT
          from SCH_OUTLAY out
             , SCH_OUTLAY_CATEGORY CAT
         where out.SCH_OUTLAY_ID = CAT.SCH_OUTLAY_ID
           and CAT.SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID;
      exception
        when no_data_found then
          begin
            lnSCH_OUTLAY_ID           := null;
            lnSCH_OUTLAY_CATEGORY_ID  := null;
            ioErrorMsg                := PCS.PC_FUNCTIONS.TranslateWord('Catégorie de débours inconnue!');
          end;
      end;

      -- Vérification Elève et débiteur choisi
      if ioErrorMsg is null then
        if nvl(iPAC_CUSTOM_PARTNER_ID, 0) <> 0 then
          begin
            select STU.SCH_STUDENT_ID
                 , STU.PAC_CUSTOM_PARTNER_ID
              into lnSCH_STUDENT_ID
                 , lnPAC_CUSTOM_PARTNER_ID
              from SCH_STUDENT_S_CUSTOMER STU
             where STU.PAC_CUSTOM_PARTNER_ID = iPAC_CUSTOM_PARTNER_ID
               and STU.SCH_STUDENT_ID = iSCH_STUDENT_ID;
          exception
            when no_data_found then
              begin
                lnSCH_STUDENT_ID         := null;
                lnPAC_CUSTOM_PARTNER_ID  := null;
                ioErrorMsg               := PCS.PC_FUNCTIONS.TranslateWord('Problème d''intégrité des élèves et débiteurs saisis');
              end;
          end;
        else
          lnSCH_STUDENT_ID         := iSCH_STUDENT_ID;
          lnPAC_CUSTOM_PARTNER_ID  := null;
        end if;

        if ioErrorMsg is null then
          ioSCH_ENTERED_OUTLAY_ID  := init_id_seq.nextval;
          -- Initialisation par défaut des valeurs nulles
          lnEOU_BASIS_QUANTITY     := nvl(iEOU_BASIS_QUANTITY, 0);
          lnEOU_QTY                := nvl(iEOU_QTY, 0);
          lnAMOUNT_TTC             := nvl(iAMOUNT_TTC, 0);
          lvEOU_PIECE_NUMBER       := nvl(iEOU_PIECE_NUMBER, '<none>');
          lvEOU_COMMENT            := nvl(iEOU_COMMENT, '');
          -- Insertion du débours
          InsertSchEnteredOutlay(iSCH_ENTERED_OUTLAY_ID    => ioSCH_ENTERED_OUTLAY_ID
                               , iSCH_OUTLAY_ID            => lnSCH_OUTLAY_ID
                               , iSCH_OUTLAY_CATEGORY_ID   => lnSCH_OUTLAY_CATEGORY_ID
                               , iPAC_CUSTOM_PARTNER_ID    => lnPAC_CUSTOM_PARTNER_ID
                               , iSCH_STUDENT_ID           => lnSCH_STUDENT_ID
                               , iEOU_STATUS               => 1
                               , iEOU_PIECE_NUMBER         => lvEOU_PIECE_NUMBER
                               , iEOU_BASIS_QUANTITY       => lnEOU_BASIS_QUANTITY
                               , iEOU_QTY                  => lnEOU_QTY
                               , iEOU_TTC_AMOUNT           => lnAMOUNT_TTC
                               , iEOU_MARGIN_RATE          => lnEOU_MARGIN_RATE
                               , iEOU_MARGIN_AMOUNT        => lnEOU_MARGIN_AMOUNT
                               , iSCH_YEAR_PERIOD_ID       => lnSCH_YEAR_PERIOD_ID
                               , iSCH_SCHOOL_YEAR_ID       => lnSCH_SCHOOL_YEAR_ID
                               , iEOU_VALUE_DATE           => ldEOU_VALUE_DATE
                               , iEOU_COMMENT              => lvEOU_COMMENT
                                );
          -- Split si la param le demande
          SplitSchEnteredOutlay(ioSCH_ENTERED_OUTLAY_ID, 1);
        end if;
      end if;
    end if;
  end InsertSchEnteredOutlay;

  /**
  * function UpdateSchEnteredOutlay
  * Description : Mise à jour écolage.
  *
  * @version 2003
  * @author ECA 5.11.2008
  * @lastUpdate
  * @public
  * @param   aSCH_ENTERED_OUTLAY_ID : Débours saisis
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aPAC_CUSTOM_PARTNER_ID : Client
  * @param   aSCH_STUDENT_ID : ELève
  * @param   aEOU_QTY : Quantité
  * @param   aAMOUNT_TTC : Montant TTC
  * @param   aMARGIN_RATE : Taux marge
  * @param   aMARGIN_AMOUNT : Montant Marge
  * @param   aEOU_PIECE_NUMBER : N° de pièce
  * @param   aEOU_VALUE_DATE : Date
  * @param   aEOU_BASIS_QUANTITY : Quantité de base
  * @param   aErrorMsg : Message d'erreur éventuel.
  */
  procedure UpdateSchEnteredOutlay(
    aSCH_ENTERED_OUTLAY_ID  in     number
  , aSCH_OUTLAY_ID          in     number
  , aSCH_OUTLAY_CATEGORY_ID in     number
  , aPAC_CUSTOM_PARTNER_ID  in     number
  , aSCH_STUDENT_ID         in     number
  , aEOU_QTY                in     number
  , aAMOUNT_TTC             in     number
  , aMARGIN_RATE            in     number
  , aMARGIN_AMOUNT          in     number
  , aEOU_PIECE_NUMBER       in     varchar2
  , aEOU_VALUE_DATE         in     date
  , aEOU_BASIS_QUANTITY     in     number
  , aErrorMsg               in out varchar2
  )
  is
    cursor crStudent
    is
      select STU.SCH_STUDENT_ID
           , STU.STU_ACCOUNT_NUMBER
           , EOU.OUT_MAJOR_REFERENCE
           , CAT.COU_MAJOR_REFERENCE
           , EOU.SCH_OUTLAY_ID
           , CAT.SCH_OUTLAY_CATEGORY_ID
        from SCH_STUDENT STU
           , SCH_OUTLAY EOU
           , SCH_OUTLAY_CATEGORY CAT
       where STU.SCH_STUDENT_ID = aSCH_STUDENT_ID
         and EOU.SCH_OUTLAY_ID = aSCH_OUTLAY_ID
         and EOU.SCH_OUTLAY_ID = CAT.SCH_OUTLAY_ID
         and CAT.SCH_OUTLAY_CATEGORY_ID = aSCH_OUTLAY_CATEGORY_ID;

    tplStudent crStudent%rowtype;
  begin
    -- Contrôle infos débiteur, et recherche information complémentaire
    open crStudent;

    fetch crStudent
     into tplStudent;

    if crStudent%found then
      -- Recherche informations complémentaires
      if    tplStudent.SCH_OUTLAY_ID is null
         or tplStudent.SCH_OUTLAY_CATEGORY_ID is null then
        aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Saisie de débours ou catégorie incomplète ou incohérente');
      end if;
    else
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Informations insuffisantes!');
    end if;

    if aErrorMsg is null then
      -- Update du débours
      update SCH_ENTERED_OUTLAY
         set SCH_OUTLAY_ID = aSCH_OUTLAY_ID
           , SCH_OUTLAY_CATEGORY_ID = aSCH_OUTLAY_CATEGORY_ID
           , PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID
           , SCH_STUDENT_ID = aSCH_STUDENT_ID
           , EOU_QTY = aEOU_QTY
           , EOU_TTC_AMOUNT = aAMOUNT_TTC
           , EOU_MARGIN_RATE = aMARGIN_RATE
           , EOU_MARGIN_AMOUNT = aMARGIN_AMOUNT
           , EOU_PIECE_NUMBER = aEOU_PIECE_NUMBER
           , EOU_VALUE_DATE = aEOU_VALUE_DATE
           , EOU_BASIS_QUANTITY = aEOU_BASIS_QUANTITY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SCH_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID;
    end if;

    close crStudent;
  exception
    when others then
      begin
        close crStudent;

        aErrorMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la modification de l''enregistrement :') ||
          chr(13) ||
          chr(10) ||
          DBMS_UTILITY.FORMAT_ERROR_STACK;
      end;
  end UpdateSchEnteredOutlay;

  /**
  * function SplitSchEnteredOutlay
  * Description : Split des débours saisis en fonction du pourcentage de répartition
  *
  * @version 2003
  * @author ECA 5.11.2008
  * @lastUpdate
  * @public
  * @param   iSCH_ENTERED_OUTLAY_ID : Débours à splitter
  */
  procedure SplitSchEnteredOutlay(iSCH_ENTERED_OUTLAY_ID number, iSplitFreeDatas in integer default 0)
  is
    lSCH_ENTERED_OUTLAY          SCH_ENTERED_OUTLAY%rowtype;
    lnSplittedENTERED_OUTLAY_ID  number;
    liExecStandard               integer;
    lcSplitSchEnteredOutlayindiv varchar2(255);
  begin
    liExecStandard                := 1;
    lcSplitSchEnteredOutlayindiv  := PCS.PC_CONFIG.GetConfig('SCH_PRC_SPLIT_OUTLAY_ENTRY');

    if not lcSplitSchEnteredOutlayindiv is null then
      SplitSchEnteredOutlayIndiv(lcSplitSchEnteredOutlayindiv, iSCH_ENTERED_OUTLAY_ID, liExecStandard);
    end if;

    if liExecStandard = 1 then
      -- sélection des informations relatives au débours saisis
      select *
        into lSCH_ENTERED_OUTLAY
        from SCH_ENTERED_OUTLAY
       where SCH_ENTERED_OUTLAY_ID = iSCH_ENTERED_OUTLAY_ID;

      -- Parcours de la matrice et recherche de pourcentages de répartition
      for tplMatrixPercent in (select CAS.PAC_CUSTOM_PARTNER_ID
                                    , CAS_PERCENT
                                 from SCH_CUSTOMERS_ASSOCIATION CAS
                                where (trunc(lSCH_ENTERED_OUTLAY.EOU_VALUE_DATE) between nvl(CAS_VALIDITY_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                                                                     and nvl(CAS_VALIDITY_DATE_TO, to_date('31.12.2999', 'DD.MM.YYYY') )
                                      )
                                  and CAS.SCH_STUDENT_ID = lSCH_ENTERED_OUTLAY.SCH_STUDENT_ID
                                  and CAS.SCH_OUTLAY_ID = lSCH_ENTERED_OUTLAY.SCH_OUTLAY_ID
                                  and (   CAS.SCH_OUTLAY_CATEGORY_ID is null
                                       or CAS.SCH_OUTLAY_CATEGORY_ID = lSCH_ENTERED_OUTLAY.SCH_OUTLAY_CATEGORY_ID)
                                  and CAS.PAC_CUSTOM_PARTNER_ID is not null
                                  and nvl(CAS_PERCENT, 0) <> 0) loop
        lnSplittedENTERED_OUTLAY_ID  := init_id_seq.nextval;

        -- Insertion des saisies
        if lSCH_ENTERED_OUTLAY.PAC_CUSTOM_PARTNER_ID <> tplMatrixPercent.PAC_CUSTOM_PARTNER_ID then
          InsertSchEnteredOutlay(iSCH_ENTERED_OUTLAY_ID          => lnSplittedENTERED_OUTLAY_ID
                               , iSCH_OUTLAY_ID                  => lSCH_ENTERED_OUTLAY.SCH_OUTLAY_ID
                               , iSCH_OUTLAY_CATEGORY_ID         => lSCH_ENTERED_OUTLAY.SCH_OUTLAY_CATEGORY_ID
                               , iPAC_CUSTOM_PARTNER_ID          => tplMatrixPercent.PAC_CUSTOM_PARTNER_ID
                               , iSCH_STUDENT_ID                 => lSCH_ENTERED_OUTLAY.SCH_STUDENT_ID
                               , iEOU_STATUS                     => lSCH_ENTERED_OUTLAY.EOU_STATUS
                               , iEOU_PIECE_NUMBER               => lSCH_ENTERED_OUTLAY.EOU_PIECE_NUMBER
                               , iEOU_QTY                        => lSCH_ENTERED_OUTLAY.EOU_QTY
                               , iEOU_TTC_AMOUNT                 => ( (lSCH_ENTERED_OUTLAY.EOU_TTC_AMOUNT * tplMatrixPercent.CAS_PERCENT) / 100)
                               , iEOU_MARGIN_RATE                => lSCH_ENTERED_OUTLAY.EOU_MARGIN_RATE
                               , iEOU_MARGIN_AMOUNT              => lSCH_ENTERED_OUTLAY.EOU_MARGIN_AMOUNT
                               , iSCH_YEAR_PERIOD_ID             => lSCH_ENTERED_OUTLAY.SCH_YEAR_PERIOD_ID
                               , iSCH_SCHOOL_YEAR_ID             => lSCH_ENTERED_OUTLAY.SCH_SCHOOL_YEAR_ID
                               , iEOU_VALUE_DATE                 => lSCH_ENTERED_OUTLAY.EOU_VALUE_DATE
                               , iEOU_BASIS_QUANTITY             => lSCH_ENTERED_OUTLAY.EOU_BASIS_QUANTITY
                               , iSCH_FATHER_ENTERED_OUTLAY_ID   => lSCH_ENTERED_OUTLAY.SCH_ENTERED_OUTLAY_ID
                               , iEOU_SESSION                    => lSCH_ENTERED_OUTLAY.EOU_SESSION
                                );

          -- copie des données libres
          if iSplitFreeDatas = 1 then
            SCH_OUTLAY_FUNCTIONS.CopyFreeDataFromEnteredOutlay(iSCH_ENTERED_OUTLAY_ID, lnSplittedENTERED_OUTLAY_ID);
          end if;
        -- Mise à jour du montant de la saisie mère
        else
          update SCH_ENTERED_OUTLAY
             set EOU_TTC_AMOUNT =( (EOU_TTC_AMOUNT * tplMatrixPercent.CAS_PERCENT) / 100)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where SCH_ENTERED_OUTLAY_ID = lSCH_ENTERED_OUTLAY.SCH_ENTERED_OUTLAY_ID;
        end if;
      end loop;
    end if;
  end SplitSchEnteredOutlay;

  /**
  * procedure DeleteSchEnteredOutlay
  * Description : Suppression d'un débours saisi
  *
  * @version 2003
  * @author ECA 06.03.2011
  * @lastUpdate
  * @public
  * @param   iSCH_ENTERED_OUTLAY_ID : Débours à supprimer
  * @param   iUseCase : Schooling / fundation
  * @param   ioErrorMsg : Message d'erreur
  *
  */
  procedure DeleteSchEnteredOutlay(iSCH_ENTERED_OUTLAY_ID in number, iUseCase in integer default 0, ioErrorMsg in out varchar2)
  is
    lbDeleted boolean;
  begin
    lbDeleted   := false;
    ioErrorMsg  := null;

    for TplEnteredOutlay in (select EOU.*
                               from SCH_ENTERED_OUTLAY EOU
                              where EOU.SCH_ENTERED_OUTLAY_ID = iSCH_ENTERED_OUTLAY_ID
                                and not exists(select 1
                                                 from SCH_BILL_POSITION BPO
                                                where BPO.SCH_ENTERED_OUTLAY_ID = EOU.SCH_ENTERED_OUTLAY_ID) ) loop
      -- Mise à null de la clef étrangère s'il s'agit d'un débours splité père
      update SCH_ENTERED_OUTLAY
         set SCH_FATHER_ENTERED_OUTLAY_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SCH_FATHER_ENTERED_OUTLAY_ID = TplEnteredOutlay.SCH_ENTERED_OUTLAY_ID;

      -- Suppression
      delete from SCH_ENTERED_OUTLAY
            where SCH_ENTERED_OUTLAY_ID = TplEnteredOutlay.SCH_ENTERED_OUTLAY_ID;

      lbDeleted  := true;
      exit;
    end loop;

    -- Déjà facturés, ils ne peuvent être détruits
    if lbDeleted = false then
      if iUseCase = SCH_OUTLAY_BILLING.ucSchooling then
        ioErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Ce débours est déjà facturé, il ne peut être supprimé !');
      else
        ioErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Cette prestation est déjà facturée, elle ne peut être supprimée !');
      end if;
    end if;
  end DeleteSchEnteredOutlay;
end SCH_OUTLAY_ENTRY_FUNCTIONS;
