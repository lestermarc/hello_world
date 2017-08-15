--------------------------------------------------------
--  DDL for Package Body SCH_PRC_LPM_INTERFACE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_PRC_LPM_INTERFACE" 
is
  type ttblNewOutlay is table of sch_entered_outlay%rowtype
    index by pls_integer;

  vtblNewOutlay ttblNewOutlay;

  -- Récupération des commandes SQL pour facturation conditionnelle
  function GetSQLCommand(iPC_SQLST_ID in number)
    return varchar2
  is
    lvSQLCommand varchar2(32000);
    lvTableName  PCS.PC_TABLE.TABNAME%type;
    lvGroup      PCS.PC_SQLST.C_SQGTYPE%type;
    lvSqlId      PCS.PC_SQLST.SQLID%type;
  begin
    select TAB.TABNAME
         , SQLST.C_SQGTYPE
         , SQLST.SQLID
      into lvTableName
         , lvGroup
         , lvSqlId
      from PCS.PC_SQLST SQLST
         , PCS.PC_TABLE TAB
     where SQLST.PC_SQLST_ID = iPC_SQLST_ID
       and SQLST.PC_TABLE_ID = TAB.PC_TABLE_ID;

    -- Recherche commande du dictionnaire
    lvSQLCommand  := PCS.PC_I_LIB_SQL.GetSQL(iTableName => lvTableName, iGroup => lvGroup, iSqlId => lvSqlId);
    return lvSQLCommand;
  exception
    when others then
      return null;
  end GetSQLCommand;

  -- Vérification des conditions SQL de sélection des prestations à facturer
  function CheckSQLCondition(iPC_SQLST_ID in number, iSchStudentId in number, iEouOutlayDate in date, iSchOultayCategoryId in number)
    return integer
  is
    CrCheckCondition integer;
    liIgnore         integer;
    liVerified       integer;
    lvSqlCondition   varchar2(32000);
  begin
    -- Recherche de la commande SQL
    lvSqlCondition  := GetSQLCommand(iPC_SQLST_ID);

    --raise_application_error(-20001, lvSqlCondition);

    -- Condition non précisée
    if lvSQLCondition is null then
      return 0;
    else
      CrCheckCondition  := DBMS_SQL.open_cursor;
      DBMS_SQL.Parse(CrCheckCondition, lvSQLCondition, DBMS_SQL.V7);
      DBMS_SQL.Define_column(CrCheckCondition, 1, liVerified);

      if instr(lvSQLCondition, ':LPM_BENEFICIARY_ID') > 0 then
        DBMS_SQL.BIND_VARIABLE(CrCheckCondition, 'LPM_BENEFICIARY_ID', iSchStudentId);
      end if;

      if instr(lvSQLCondition, ':EOU_OUTLAY_DATE') > 0 then
        DBMS_SQL.BIND_VARIABLE(CrCheckCondition, 'EOU_OUTLAY_DATE', iEouOutlayDate);
      end if;

      if instr(lvSQLCondition, ':SCH_OUTLAY_CATEGORY_ID') > 0 then
        DBMS_SQL.BIND_VARIABLE(CrCheckCondition, 'SCH_OUTLAY_CATEGORY_ID', iSchOultayCategoryId);
      end if;

      LiIgnore          := DBMS_SQL.execute(CrCheckCondition);

      while DBMS_SQL.fetch_rows(CrCheckCondition) > 0 loop
        DBMS_SQL.column_value(CrCheckCondition, 1, liVerified);
        exit;
      end loop;

      DBMS_SQL.close_cursor(CrCheckCondition);
      return liVerified;
    end if;
  exception
    when others then
      begin
        if DBMS_SQL.IS_OPEN(CrCheckCondition) then
          DBMS_SQL.close_cursor(CrCheckCondition);
        end if;

        raise;
      end;
  end CheckSQLCondition;

  -- Récupération du code tarif à appliquer
  function SQLGetTarifCode(iPC_SQLST_ID in number, iSchStudentId in number, iEouOutlayDate in date, iSchOultayCategoryId in number)
    return integer
  is
    CrCheckCondition  integer;
    liIgnore          integer;
    liTarifCode       number;
    lvSQLGetTarifCode varchar2(32000);
  begin
    -- Recherche de la commande SQL
    lvSQLGetTarifCode  := GetSQLCommand(iPC_SQLST_ID);

    -- Condition non précisée
    if lvSQLGetTarifCode is null then
      return null;
    else
      CrCheckCondition  := DBMS_SQL.open_cursor;
      DBMS_SQL.Parse(CrCheckCondition, lvSQLGetTarifCode, DBMS_SQL.V7);
      DBMS_SQL.Define_column(CrCheckCondition, 1, liTarifCode);

      if instr(lvSQLGetTarifCode, ':LPM_BENEFICIARY_ID') > 0 then
        DBMS_SQL.BIND_VARIABLE(CrCheckCondition, 'LPM_BENEFICIARY_ID', iSchStudentId);
      end if;

      if instr(lvSQLGetTarifCode, ':EOU_OUTLAY_DATE') > 0 then
        DBMS_SQL.BIND_VARIABLE(CrCheckCondition, 'EOU_OUTLAY_DATE', iEouOutlayDate);
      end if;

      if instr(lvSQLGetTarifCode, ':SCH_OUTLAY_CATEGORY_ID') > 0 then
        DBMS_SQL.BIND_VARIABLE(CrCheckCondition, 'SCH_OUTLAY_CATEGORY_ID', iSchOultayCategoryId);
      end if;

      LiIgnore          := DBMS_SQL.execute(CrCheckCondition);

      while DBMS_SQL.fetch_rows(CrCheckCondition) > 0 loop
        DBMS_SQL.column_value(CrCheckCondition, 1, liTarifCode);
        exit;
      end loop;

      DBMS_SQL.close_cursor(CrCheckCondition);
      return liTarifCode;
    end if;
  exception
    when others then
      begin
        if DBMS_SQL.IS_OPEN(CrCheckCondition) then
          DBMS_SQL.close_cursor(CrCheckCondition);
        end if;

        return null;
      end;
  end SQLGetTarifCode;

   /**
  * function GetSessionOutlaysID
  * Description : Récupération des lignes de facturation de la session
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  function GetSessionOutlaysID
    return ID_TABLE_TYPE pipelined
  is
  begin
    if vtblNewOutlay.count > 0 then
      for i in vtblNewOutlay.first .. vtblNewOutlay.last loop
        pipe row(vtblNewOutlay(i).SCH_ENTERED_OUTLAY_ID);
      end loop;
    end if;
  end GetSessionOutlaysID;

   /**
  * function CheckBilledPrestation
  * Description : Recherche si la prestation a déjà été facturée pour la date donnée
  *                   (exemple : Cas des prés. matin, et pré après midi qui déclenchent
  *                  Si l'un, l'autre ou les edux sont cochées, la facturation d'un unique jour)
  * @created ECA
  * @lastUpdate
  * @public
  */
  function CheckBilledPrestation(iSCH_STUDENT_ID in number, iSCH_OUTLAY_CATEGORY_ID in number, iEOU_OUTLAY_DATE in date)
    return integer
  is
    liExist integer;
  begin
    select max(1)
      into liExist
      from SCH_ENTERED_OUTLAY EOU
         , table(GetSessionOutlaysID) SESSION_EOU
     where EOU.SCH_ENTERED_OUTLAY_ID = SESSION_EOU.column_value
       and trunc(EOU.EOU_VALUE_DATE) = trunc(iEOU_OUTLAY_DATE)
       and EOU.SCH_STUDENT_ID = iSCH_STUDENT_ID
       and EOU.SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID;

    return liExist;
  exception
    when others then
      return 0;
  end CheckBilledPrestation;

  /**
  * procedure UpdateProcessedEou
  * Description : Mise à jour des lignes traitées
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iEnteredOutlayId : LIgne à mettre à jour
  * @param   iErrorMsg : Msg d'erreur
  */
  procedure UpdateProcessedEou(iEnteredOutlayId number default null, iErrorMsg varchar2 default null)
  is
  begin
    -- Mise à jour de la saisie LPM - Importé / Erreurs
    if iErrorMsg is null then
      if nvl(iEnteredOutlayId, 0) <> 0 then
        update LPM_ENTERED_OUTLAY
           set EOU_BILLED = 1
             , EOU_BILLED_DATE = sysdate
             , EOU_BILLED_BY = PCS.PC_I_LIB_SESSION.GetUserIni
             , EOU_BILLING_ERROR = null
         where LPM_ENTERED_OUTLAY_ID = iEnteredOutlayId;
      else
        update LPM_ENTERED_OUTLAY
           set EOU_BILLED = 1
             , EOU_BILLED_DATE = sysdate
             , EOU_BILLED_BY = PCS.PC_I_LIB_SESSION.GetUserIni
             , EOU_BILLING_ERROR = null
         where LPM_ENTERED_OUTLAY_ID in(select COM.LID_ID_1
                                          from COM_LIST_ID_TEMP COM
                                         where COM.LID_CODE = 'SELECTED_LPM_REF');
      end if;
    else
      if nvl(iEnteredOutlayId, 0) <> 0 then
        update LPM_ENTERED_OUTLAY
           set EOU_BILLING_ERROR = iErrorMsg
         where LPM_ENTERED_OUTLAY_ID = iEnteredOutlayId;
      else
        update LPM_ENTERED_OUTLAY
           set EOU_BILLING_ERROR = iErrorMsg
         where LPM_ENTERED_OUTLAY_ID in(select COM.LID_ID_1
                                          from COM_LIST_ID_TEMP COM
                                         where COM.LID_CODE = 'SELECTED_LPM_REF');
      end if;
    end if;
  end UpdateProcessedEou;

  /**
  * procedure UpdateReferencedEou
  * Description : Mise à jour des références des lignes traitées
  *
  * @created JFR
  * @lastUpdate
  * @public
  * @param   iEnteredOutlayId : Ligne à mettre à jour
  * @param   iSchEnteredOutlayId : Ligne à mettre à jour
  */
  procedure UpdateReferencedEou(iEnteredOutlayId number default null, iSchEnteredOutlayId number default null)
  is
  begin
    if nvl(iEnteredOutlayId, 0) <> 0 then
      update LPM_ENTERED_OUTLAY
         set EOU_SCH_REFERENCE = iSchEnteredOutlayId
       where LPM_ENTERED_OUTLAY_ID = iEnteredOutlayId
         and eou_qty > 0;
    else
      update LPM_ENTERED_OUTLAY EOU
         set EOU_SCH_REFERENCE = iSchEnteredOutlayId
       where EOU.LPM_ENTERED_OUTLAY_ID in(select COM.LID_ID_1
                                            from COM_LIST_ID_TEMP COM
                                           where COM.LID_CODE = 'SELECTED_LPM_REF')
         and eou_qty > 0;
    end if;
  end UpdateReferencedEou;

  /**
  * procedure GetYearPeriod
  * Description : Recherche de la période
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  */
  function GetYearPeriod(iDate in date)
    return number
  is
    lnPeriod number;
  begin
    select max(SCH_YEAR_PERIOD_ID)
      into lnPeriod
      from SCH_YEAR_PERIOD
     where trunc(nvl(iDate, sysdate) ) >= trunc(PER_BEGIN_DATE)
       and trunc(nvl(iDate, sysdate) ) <= trunc(PER_END_DATE);

    return lnPeriod;
  exception
    when others then
      begin
        return null;
      end;
  end GetYearPeriod;

  /**
  * procedure DeleteSelectedServices
  * Description : suppression des prestations sélectionnées
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  */
  procedure DeleteSelectedServices
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SELECTED_LPM_SERVICES';
  end DeleteSelectedServices;

  /**
  * procedure InitialiseSelectedReference
  * Description : suppression des references sélectionnées
  *
  *
  * @created RBA
  * @lastUpdate
  * @public
  * @param
  */
  procedure AddSelectedReference(iEnteredOutlayId in number, iInitialiseList in boolean default false)
  is
  begin
    -- Suppression sélection précédente éventuelle
    if iInitialiseList then
      delete from COM_LIST_ID_TEMP
            where LID_CODE = 'SELECTED_LPM_REF';
    end if;

    -- Initialise la première sélection
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_ID_1
               , LID_CODE
                )
      select GetNewId
           , iEnteredOutlayId
           , 'SELECTED_LPM_REF'
        from dual
       where not exists(select 1
                          from COM_LIST_ID_TEMP
                         where LID_CODE = 'SELECTED_LPM_REF'
                           and LID_ID_1 = iEnteredOutlayId);
  end AddSelectedReference;

  /**
  * procedure SetImportErrorToNull
  * Description : Mise à null des erreurs d'importations
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  */
  procedure SetImportErrorToNull
  is
  begin
    update LPM_ENTERED_OUTLAY
       set EOU_BILLING_ERROR = null
     where EOU_BILLING_ERROR is not null;
  end SetImportErrorToNull;

  /**
  * procedure SelectLPMServices
  * Description : Sélection des prestations en provenance du LPM
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSelectType : Type de sélection / (1) Tout / (2) libre / (3) Critères
  * @param   iDateFrom : Date de...
  * @param   iDateTo : Date à...
  * @param   iBeneficiary : Bénéficiaire
  * @param   iService : Prestation
  * @param   iDivision : Structure
  * @param   iCDA : centre d'analyse
  */
  procedure SelectLPMServices(
    iSelectType  in integer
  , iDateFrom    in date
  , iDateTo      in date
  , iBeneficiary in number
  , iService     in number
  , iDivision    in number
  , iCDA         in number
  )
  is
  begin
    -- en mode indiv, sélection par l'interface (Commandes SQL indiv)
    if iSelectType <> 2 then
      -- Suppression sélection précédente éventuelle
      delete from COM_LIST_ID_TEMP
            where LID_CODE = 'SELECTED_LPM_SERVICES';

      -- Sélection prestations LPM
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select LEO.LPM_ENTERED_OUTLAY_ID
             , 'SELECTED_LPM_SERVICES'
          from LPM_ENTERED_OUTLAY LEO
             , LPM_DIVISION_OUTLAY LDO
             , SCH_OUTLAY_CATEGORY CAT
         where LEO.LPM_DIVISION_OUTLAY_ID = LDO.LPM_DIVISION_OUTLAY_ID(+)
           and LEO.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID(+)
           and LEO.EOU_BILLED = 0
           and LEO.EOU_INVOICED = 1
           and (    (iSelectType = 1)
                or (    iSelectType = 3
                    and (trunc(LEO.EOU_OUTLAY_DATE) between nvl(trunc(iDateFrom), trunc(LEO.EOU_OUTLAY_DATE) ) and nvl(trunc(iDateTo)
                                                                                                                     , trunc(LEO.EOU_OUTLAY_DATE)
                                                                                                                      )
                        )
                    and (    (    nvl(iBeneficiary, 0) <> 0
                              and LEO.SCH_STUDENT_ID = iBeneficiary)
                         or (    nvl(iBeneficiary, 0) = 0
                             and exists(select 1
                                          from COM_LIST_ID_TEMP CO1
                                         where CO1.LID_CODE = 'BENEFICIARY')
                             and LEO.SCH_STUDENT_ID in(select CO1.COM_LIST_ID_TEMP_ID
                                                         from COM_LIST_ID_TEMP CO1
                                                        where CO1.LID_CODE = 'BENEFICIARY')
                            )
                         or (    nvl(iBeneficiary, 0) = 0
                             and not exists(select 1
                                              from COM_LIST_ID_TEMP CO1
                                             where CO1.LID_CODE = 'BENEFICIARY') )
                        )
                    and (    (    nvl(iService, 0) <> 0
                              and nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) = iService)
                         or (    nvl(iService, 0) = 0
                             and exists(select 1
                                          from COM_LIST_ID_TEMP CO2
                                         where CO2.LID_CODE = 'SERVICE')
                             and nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) in(select CO2.COM_LIST_ID_TEMP_ID
                                                                                                  from COM_LIST_ID_TEMP CO2
                                                                                                 where CO2.LID_CODE = 'SERVICE')
                            )
                         or (    nvl(iService, 0) = 0
                             and not exists(select 1
                                              from COM_LIST_ID_TEMP CO2
                                             where CO2.LID_CODE = 'SERVICE') )
                        )
                    and (    (    nvl(iDivision, 0) <> 0
                              and coalesce(LEO.HRM_DIVISION_ID
                                         , (select LDO.HRM_DIVISION_ID
                                              from LPM_DIVISION_OUTLAY LDO
                                             where LDO.LPM_DIVISION_OUTLAY_ID = LEO.LPM_DIVISION_OUTLAY_ID)
                                         , (select LRE.HRM_DIVISION_ID
                                              from LPM_EVENT EVT
                                                 , LPM_REFERENTS LRE
                                             where EVT.LPM_EVENT_ID = LEO.LPM_EVENT_ID
                                               and EVT.LPM_REFERENTS_ID = LRE.LPM_REFERENTS_ID)
                                          ) = iDivision
                             )
                         or (    nvl(iDivision, 0) = 0
                             and exists(select 1
                                          from COM_LIST_ID_TEMP CO1
                                         where CO1.LID_CODE = 'DIVISION')
                             and coalesce(LEO.HRM_DIVISION_ID
                                        , (select LDO.HRM_DIVISION_ID
                                             from LPM_DIVISION_OUTLAY LDO
                                            where LDO.LPM_DIVISION_OUTLAY_ID = LEO.LPM_DIVISION_OUTLAY_ID)
                                        , (select LRE.HRM_DIVISION_ID
                                             from LPM_EVENT EVT
                                                , LPM_REFERENTS LRE
                                            where EVT.LPM_EVENT_ID = LEO.LPM_EVENT_ID
                                              and EVT.LPM_REFERENTS_ID = LRE.LPM_REFERENTS_ID)
                                         ) in(select CO1.COM_LIST_ID_TEMP_ID
                                                from COM_LIST_ID_TEMP CO1
                                               where CO1.LID_CODE = 'DIVISION')
                            )
                         or (    nvl(iDivision, 0) = 0
                             and not exists(select 1
                                              from COM_LIST_ID_TEMP CO1
                                             where CO1.LID_CODE = 'DIVISION') )
                        )
                    and (    (    nvl(iCDA, 0) <> 0
                              and SCH_BILLING_FUNCTIONS.GetFilterCDA(LEO.LPM_ENTERED_OUTLAY_ID, null, null) = iCDA)
                         or (    nvl(iCDA, 0) = 0
                             and exists(select 1
                                          from COM_LIST_ID_TEMP CO1
                                         where CO1.LID_CODE = 'CDA_ACC')
                             and SCH_BILLING_FUNCTIONS.GetFilterCDA(LEO.LPM_ENTERED_OUTLAY_ID, null, null) in(select CO1.COM_LIST_ID_TEMP_ID
                                                                                                                from COM_LIST_ID_TEMP CO1
                                                                                                               where CO1.LID_CODE = 'CDA_ACC')
                            )
                         or (    nvl(iCDA, 0) = 0
                             and not exists(select 1
                                              from COM_LIST_ID_TEMP CO1
                                             where CO1.LID_CODE = 'CDA_ACC') )
                        )
                   )
               );
    end if;
  end SelectLPMServices;

  /**
  * procedure ImportSelection
  * Description : Génération des lignes de saisie
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure ImportSelection
  is
    ioErrorMsg              varchar2(2000);
    liBilled                integer;
    ioSCH_ENTERED_OUTLAY_ID number;
  begin
    SetImportErrorToNull;

    -- Prestations LPM sélectionnées
    for tplSelectedLPMServices in (select   LEO.LPM_ENTERED_OUTLAY_ID
                                          , LEO.EOU_OUTLAY_DATE
                                          , LEO.SCH_STUDENT_ID
                                          , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) SCH_OUTLAY_CATEGORY_ID
                                          , LEO.EOU_QTY
                                          , nvl(LEO.LPM_EVENT_ID, 0) LPM_EVENT_ID
                                          , LEO.EOU_COMMENT
                                       from LPM_ENTERED_OUTLAY LEO
                                          , LPM_DIVISION_OUTLAY LDO
                                          , SCH_OUTLAY_CATEGORY CAT
                                      where LEO.LPM_DIVISION_OUTLAY_ID = LDO.LPM_DIVISION_OUTLAY_ID(+)
                                        and LEO.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID(+)
                                        and LEO.EOU_BILLED = 0
                                        and LEO.EOU_INVOICED = 1
                                        and LEO.LPM_ENTERED_OUTLAY_ID in(select COM.COM_LIST_ID_TEMP_ID
                                                                           from COM_LIST_ID_TEMP COM
                                                                          where COM.LID_CODE = 'SELECTED_LPM_SERVICES')
                                   order by LEO.EOU_OUTLAY_DATE asc) loop
      -- Génération de l'écriture
      ioErrorMsg  := null;
      GenerateOutlayEntry(tplSelectedLPMServices.EOU_OUTLAY_DATE
                        , tplSelectedLPMServices.SCH_STUDENT_ID
                        , tplSelectedLPMServices.EOU_QTY
                        , tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID
                        , ioErrorMsg
                        , liBilled
                        , tplSelectedLPMServices.LPM_EVENT_ID
                        , tplSelectedLPMServices.EOU_COMMENT
                        , ioSCH_ENTERED_OUTLAY_ID
                         );
      -- Mise à jour de la saisie LPM - Importé / Erreurs
      UpdateProcessedEou(iEnteredOutlayId => tplSelectedLPMServices.LPM_ENTERED_OUTLAY_ID, iErrorMsg => ioErrorMsg);
      -- Mise à jour des références des lignes traitées
      UpdateReferencedEou(iEnteredOutlayId => tplSelectedLPMServices.LPM_ENTERED_OUTLAY_ID, iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
    end loop;

    DeleteSelectedServices;
  end ImportSelection;

  /**
  * procedure ImportDateGroupedSelection
  * Description : Génération des lignes de saisie, pré-groupées par
  *               Date, bénéficiaire, prestation
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure ImportDateGroupedSelection
  is
    ioErrorMsg              varchar2(2000);
    ldDate                  date;
    lnBeneficiary           number;
    lnCategory              number;
    lnEvent                 number;
    lnSumQty                number;
    lbFirstRec              boolean;
    liBilled                integer;
    lvComment               varchar2(32000);
    ioSCH_ENTERED_OUTLAY_ID number;
  begin
    SetImportErrorToNull;
    -- Prestations LPM sélectionnées
    lbFirstRec     := true;
    ldDate         := null;
    lnBeneficiary  := null;
    lnCategory     := null;
    lnEvent        := 0;
    lnSumQty       := 0;
    lvComment      := '';
    -- Initialise la liste des références sélectionnées
    AddSelectedReference(0, true);

    for tplSelectedLPMServices in (select   LEO.LPM_ENTERED_OUTLAY_ID
                                          , trunc(nvl(LEO.EOU_OUTLAY_DATE, sysdate) ) EOU_OUTLAY_DATE
                                          , LEO.SCH_STUDENT_ID
                                          , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) SCH_OUTLAY_CATEGORY_ID
                                          , LEO.EOU_QTY
                                          , nvl(LEO.LPM_EVENT_ID, 0) LPM_EVENT_ID
                                          , LEO.EOU_COMMENT
                                       from LPM_ENTERED_OUTLAY LEO
                                          , LPM_DIVISION_OUTLAY LDO
                                          , SCH_OUTLAY_CATEGORY CAT
                                      where LEO.LPM_DIVISION_OUTLAY_ID = LDO.LPM_DIVISION_OUTLAY_ID(+)
                                        and LEO.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID(+)
                                        and LEO.EOU_BILLED = 0
                                        and LEO.EOU_INVOICED = 1
                                        and LEO.LPM_ENTERED_OUTLAY_ID in(select COM.COM_LIST_ID_TEMP_ID
                                                                           from COM_LIST_ID_TEMP COM
                                                                          where COM.LID_CODE = 'SELECTED_LPM_SERVICES')
                                   order by LEO.EOU_OUTLAY_DATE
                                          , LEO.SCH_STUDENT_ID
                                          , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID)
                                          , nvl(LEO.LPM_EVENT_ID, 0) ) loop
      -- Test génération groupée
      if     (lbFirstRec = false)
         and (    (ldDate <> tplSelectedLPMServices.EOU_OUTLAY_DATE)
              or (lnBeneficiary <> tplSelectedLPMServices.SCH_STUDENT_ID)
              or (lnCategory <> tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID)
              or (lnEvent <> tplSelectedLPMServices.LPM_EVENT_ID)
             ) then
        -- Génération de l'écriture
        ioErrorMsg  := null;
        GenerateOutlayEntry(ldDate
                          , lnBeneficiary
                          , lnSumQty
                          , lnCategory
                          , ioErrorMsg
                          , liBilled
                          , tplSelectedLPMServices.LPM_EVENT_ID
                          , lvComment
                          , ioSCH_ENTERED_OUTLAY_ID
                           );
        -- Mise à jour de la saisie LPM - Importé / Erreurs
        UpdateProcessedEou(iErrorMsg => ioErrorMsg);
        -- Mise à jour des références des lignes traitées
        UpdateReferencedEou(iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
        -- RAZ qté groupée
        lnSumQty    := 0;
        AddSelectedReference(0, true);
      end if;

      ldDate         := tplSelectedLPMServices.EOU_OUTLAY_DATE;
      lnBeneficiary  := tplSelectedLPMServices.SCH_STUDENT_ID;
      lnCategory     := tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID;
      AddSelectedReference(tplSelectedLPMServices.LPM_ENTERED_OUTLAY_ID);
      lnSumQty       := lnSumQty + tplSelectedLPMServices.EOU_QTY;
      lnEvent        := tplSelectedLPMServices.LPM_EVENT_ID;
      lbFirstRec     := false;

      if tplSelectedLPMServices.EOU_COMMENT is not null then
        lvComment  := lvComment || ' / ' || tplSelectedLPMServices.EOU_COMMENT;
      end if;
    end loop;

    -- Génération de la dernière écriture
    if     (ldDate is not null)
       and (lnBeneficiary is not null)
       and (lnCategory is not null) then
      ioErrorMsg  := null;
      GenerateOutlayEntry(ldDate, lnBeneficiary, lnSumQty, lnCategory, ioErrorMsg, liBilled, lnEvent, lvComment, ioSCH_ENTERED_OUTLAY_ID);
      -- Mise à jour de la saisie LPM - Importé / Erreurs
      UpdateProcessedEou(iErrorMsg => ioErrorMsg);
      -- Mise à jour des références des lignes traitées
      UpdateReferencedEou(iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
    end if;

    DeleteSelectedServices;
  end ImportDateGroupedSelection;

  /**
  * procedure ImportPeriodGroupedSelection
  * Description : Génération des lignes de saisie , pré-groupées par
  *               Période, bénéficiaire, prestation
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure ImportPeriodGroupedSelection
  is
    ioErrorMsg              varchar2(2000);
    lnPeriod                number;
    lnBeneficiary           number;
    lnCategory              number;
    lnEvent                 number;
    lnSumQty                number;
    lbFirstRec              boolean;
    ldDate                  date;
    liBilled                integer;
    lvComment               varchar2(32000);
    ioSCH_ENTERED_OUTLAY_ID number;
  begin
    SetImportErrorToNull;
    -- Prestations LPM sélectionnées
    lbFirstRec     := true;
    ldDate         := null;
    lnPeriod       := null;
    lnBeneficiary  := null;
    lnCategory     := null;
    lnEvent        := 0;
    lnSumQty       := 0;
    lvComment      := '';
    -- Initialise la liste des références sélectionnées
    AddSelectedReference(0, true);

    for tplSelectedLPMServices in (select   LEO.LPM_ENTERED_OUTLAY_ID
                                          , SCH_PRC_LPM_INTERFACE.GetYearPeriod(nvl(LEO.EOU_OUTLAY_DATE, sysdate) ) PERIOD
                                          , trunc(nvl(LEO.EOU_OUTLAY_DATE, sysdate) ) EOU_OUTLAY_DATE
                                          , LEO.SCH_STUDENT_ID
                                          , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) SCH_OUTLAY_CATEGORY_ID
                                          , LEO.EOU_QTY
                                          , nvl(LEO.LPM_EVENT_ID, 0) LPM_EVENT_ID
                                          , LEO.EOU_COMMENT
                                       from LPM_ENTERED_OUTLAY LEO
                                          , LPM_DIVISION_OUTLAY LDO
                                          , SCH_OUTLAY_CATEGORY CAT
                                      where LEO.LPM_DIVISION_OUTLAY_ID = LDO.LPM_DIVISION_OUTLAY_ID(+)
                                        and LEO.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID(+)
                                        and LEO.EOU_BILLED = 0
                                        and LEO.EOU_INVOICED = 1
                                        and LEO.LPM_ENTERED_OUTLAY_ID in(select COM.COM_LIST_ID_TEMP_ID
                                                                           from COM_LIST_ID_TEMP COM
                                                                          where COM.LID_CODE = 'SELECTED_LPM_SERVICES')
                                   order by SCH_PRC_LPM_INTERFACE.GetYearPeriod(nvl(LEO.EOU_OUTLAY_DATE, sysdate) )
                                          , LEO.SCH_STUDENT_ID
                                          , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID)
                                          , nvl(LEO.LPM_EVENT_ID, 0) ) loop
      -- test génération groupée
      if     (lbFirstRec = false)
         and (    (lnPeriod <> tplSelectedLPMServices.PERIOD)
              or (lnBeneficiary <> tplSelectedLPMServices.SCH_STUDENT_ID)
              or (lnCategory <> tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID)
              or (lnEvent <> tplSelectedLPMServices.LPM_EVENT_ID)
             ) then
        -- Génération de l'écriture
        GenerateOutlayEntry(ldDate, lnBeneficiary, lnSumQty, lnCategory, ioErrorMsg, liBilled, lnEvent, lvComment, ioSCH_ENTERED_OUTLAY_ID);
        -- Mise à jour de la saisie LPM - Importé / Erreurs
        UpdateProcessedEou(iErrorMsg => ioErrorMsg);
        -- Mise à jour des références des lignes traitées
        UpdateReferencedEou(iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
        -- RAZ qté groupée
        lnSumQty  := 0;
        AddSelectedReference(0, true);
      end if;

      ldDate         := tplSelectedLPMServices.EOU_OUTLAY_DATE;
      lnPeriod       := tplSelectedLPMServices.PERIOD;
      lnBeneficiary  := tplSelectedLPMServices.SCH_STUDENT_ID;
      lnCategory     := tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID;
      lnSumQty       := lnSumQty + tplSelectedLPMServices.EOU_QTY;
      lnEvent        := tplSelectedLPMServices.LPM_EVENT_ID;
      AddSelectedReference(tplSelectedLPMServices.LPM_ENTERED_OUTLAY_ID);
      lbFirstRec     := false;

      if tplSelectedLPMServices.EOU_COMMENT is not null then
        lvComment  := lvComment || ' / ' || tplSelectedLPMServices.EOU_COMMENT;
      end if;
    end loop;

    -- Génération de la dernière écriture
    if     (ldDate is not null)
       and (lnBeneficiary is not null)
       and (lnCategory is not null) then
      GenerateOutlayEntry(ldDate, lnBeneficiary, lnSumQty, lnCategory, ioErrorMsg, liBilled, lnEvent, lvComment, ioSCH_ENTERED_OUTLAY_ID);
      -- Mise à jour de la saisie LPM - Importé / Erreurs
      UpdateProcessedEou(iErrorMsg => ioErrorMsg);
      -- Mise à jour des références des lignes traitées
      UpdateReferencedEou(iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
    end if;

    DeleteSelectedServices;
  end ImportPeriodGroupedSelection;

  /**
  * procedure ImportMonthlyGroupedSelection
  * Description : Génération des lignes de saisie , pré-groupées par
  *               Mois, bénéficiaire, prestation
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure ImportMonthlyGroupedSelection
  is
    ioErrorMsg              varchar2(2000);
    lnPeriod                date;
    lnBeneficiary           number;
    lnCategory              number;
    lnEvent                 number;
    lnSumQty                number;
    lbFirstRec              boolean;
    ldDate                  date;
    liBilled                integer;
    lvComment               varchar2(32000);
    ioSCH_ENTERED_OUTLAY_ID number;
  begin
    SetImportErrorToNull;
    -- Import des prestations conditionnelles, suivi de l'import standard
    ImportConditionnalOutlays;
    -- Prestations LPM sélectionnées
    lbFirstRec     := true;
    ldDate         := null;
    lnPeriod       := null;
    lnBeneficiary  := null;
    lnCategory     := null;
    lnEvent        := 0;
    lnSumQty       := 0;
    lvComment      := '';
    -- Initialise la liste des références sélectionnées
    AddSelectedReference(0, true);

    for tplSelectedLPMServices in (select   LEO.LPM_ENTERED_OUTLAY_ID
                                          , trunc(nvl(LEO.EOU_OUTLAY_DATE, sysdate), 'mm') PERIOD
                                          , trunc(nvl(LEO.EOU_OUTLAY_DATE, sysdate), 'mm') EOU_OUTLAY_DATE
                                          , LEO.SCH_STUDENT_ID
                                          , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) SCH_OUTLAY_CATEGORY_ID
                                          , LEO.EOU_QTY
                                          , nvl(LEO.LPM_EVENT_ID, 0) LPM_EVENT_ID
                                          , LEO.EOU_COMMENT
                                       from LPM_ENTERED_OUTLAY LEO
                                          , LPM_DIVISION_OUTLAY LDO
                                          , SCH_OUTLAY_CATEGORY CAT
                                      where LEO.LPM_DIVISION_OUTLAY_ID = LDO.LPM_DIVISION_OUTLAY_ID(+)
                                        and LEO.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID(+)
                                        and LEO.EOU_BILLED = 0
                                        and LEO.EOU_INVOICED = 1
                                        and LEO.LPM_ENTERED_OUTLAY_ID in(select COM.COM_LIST_ID_TEMP_ID
                                                                           from COM_LIST_ID_TEMP COM
                                                                          where COM.LID_CODE = 'SELECTED_LPM_SERVICES')
                                   order by trunc(nvl(LEO.EOU_OUTLAY_DATE, sysdate), 'mm')
                                          , LEO.SCH_STUDENT_ID
                                          , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID)
                                          , nvl(LEO.LPM_EVENT_ID, 0) ) loop
      -- Test génération groupée
      if     (lbFirstRec = false)
         and (    (lnPeriod <> tplSelectedLPMServices.PERIOD)
              or (lnBeneficiary <> tplSelectedLPMServices.SCH_STUDENT_ID)
              or (lnCategory <> tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID)
              or (lnEvent <> tplSelectedLPMServices.LPM_EVENT_ID)
             ) then
        -- Génération de l'écriture
        GenerateOutlayEntry(ldDate, lnBeneficiary, lnSumQty, lnCategory, ioErrorMsg, liBilled, lnEvent, lvComment, ioSCH_ENTERED_OUTLAY_ID);
        -- Mise à jour de la saisie LPM - Importé / Erreurs
        UpdateProcessedEou(iErrorMsg => ioErrorMsg);
        -- Mise à jour des références des lignes traitées
        UpdateReferencedEou(iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
        -- RAZ qté groupée
        lnSumQty  := 0;
        AddSelectedReference(0, true);
      end if;

      ldDate         := tplSelectedLPMServices.EOU_OUTLAY_DATE;
      lnPeriod       := tplSelectedLPMServices.PERIOD;
      lnBeneficiary  := tplSelectedLPMServices.SCH_STUDENT_ID;
      lnCategory     := tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID;
      lnSumQty       := lnSumQty + tplSelectedLPMServices.EOU_QTY;
      AddSelectedReference(tplSelectedLPMServices.LPM_ENTERED_OUTLAY_ID);
      lnEvent        := tplSelectedLPMServices.LPM_EVENT_ID;
      lbFirstRec     := false;

      if tplSelectedLPMServices.EOU_COMMENT is not null then
        lvComment  := lvComment || ' / ' || tplSelectedLPMServices.EOU_COMMENT;
      end if;
    end loop;

    -- Génération de la dernière écriture
    if     (ldDate is not null)
       and (lnBeneficiary is not null)
       and (lnCategory is not null) then
      GenerateOutlayEntry(ldDate, lnBeneficiary, lnSumQty, lnCategory, ioErrorMsg, liBilled, lnEvent, lvComment, ioSCH_ENTERED_OUTLAY_ID);
      -- Mise à jour de la saisie LPM - Importé / Erreurs
      UpdateProcessedEou(iErrorMsg => ioErrorMsg);
      -- Mise à jour des références des lignes traitées
      UpdateReferencedEou(iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
    end if;

    DeleteSelectedServices;
  end ImportMonthlyGroupedSelection;

   /**
  * procedure ImportConditionnalOutlays
  * Description : Génération des lignes de saisie , Indiv facturation bénéficiaire
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure ImportConditionnalOutlays
  is
    -- Sélection des groupes et bornes
    cursor CrGroupByMonth
    is
      select distinct to_char(nvl(LEO.EOU_OUTLAY_DATE, sysdate), 'yyyy.mm') PERIOD
                    , trunc(last_day(nvl(LEO.EOU_OUTLAY_DATE, sysdate) ) ) LastDayOfMonth
                    , trunc(last_day(add_months(nvl(LEO.EOU_OUTLAY_DATE, sysdate), -1) ) + 1) FirstDayOfMonth
                 from LPM_ENTERED_OUTLAY LEO
                    , LPM_DIVISION_OUTLAY LDO
                    , SCH_OUTLAY_CATEGORY CAT
                where LEO.LPM_DIVISION_OUTLAY_ID = LDO.LPM_DIVISION_OUTLAY_ID(+)
                  and nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) = CAT.SCH_OUTLAY_CATEGORY_ID
                  and LEO.EOU_BILLED = 0
                  and LEO.EOU_INVOICED = 1
                  and LEO.LPM_ENTERED_OUTLAY_ID in(select COM.COM_LIST_ID_TEMP_ID
                                                     from COM_LIST_ID_TEMP COM
                                                    where COM.LID_CODE = 'SELECTED_LPM_SERVICES')
             order by to_char(nvl(LEO.EOU_OUTLAY_DATE, sysdate), 'yyyy.mm');

    -- Prestations issues du projet de vie sélectionnées, soumises à facturation conditionnelle
    cursor crLPMPrestations(aStartDate date, aEndDate date)
    is
      select   LEO.LPM_ENTERED_OUTLAY_ID
             , trunc(nvl(LEO.EOU_OUTLAY_DATE, sysdate), 'mm') PERIOD
             , trunc(nvl(LEO.EOU_OUTLAY_DATE, sysdate) ) EOU_OUTLAY_DATE
             , LEO.SCH_STUDENT_ID
             , nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) SCH_OUTLAY_CATEGORY_ID
             , LEO.EOU_QTY
             , nvl(LEO.LPM_EVENT_ID, 0) LPM_EVENT_ID
             , LEO.EOU_COMMENT
             , LDO.HRM_DIVISION_ID
          from LPM_ENTERED_OUTLAY LEO
             , LPM_DIVISION_OUTLAY LDO
             , SCH_OUTLAY_CATEGORY CAT
         where LEO.LPM_DIVISION_OUTLAY_ID = LDO.LPM_DIVISION_OUTLAY_ID(+)
           and nvl(LDO.SCH_OUTLAY_CATEGORY_ID, CAT.SCH_OUTLAY_CATEGORY_ID) = CAT.SCH_OUTLAY_CATEGORY_ID
           and LEO.EOU_BILLED = 0
           and LEO.EOU_INVOICED = 1
           and trunc(LEO.EOU_OUTLAY_DATE) between aStartdate and aEndDate
           and LEO.LPM_ENTERED_OUTLAY_ID in(select COM.COM_LIST_ID_TEMP_ID
                                              from COM_LIST_ID_TEMP COM
                                             where COM.LID_CODE = 'SELECTED_LPM_SERVICES')
      order by LEO.SCH_STUDENT_ID
             , LEO.EOU_OUTLAY_DATE
             , CAT.SCH_OUTLAY_CATEGORY_ID;

    -- Prestations liées, réelleement facturées, soumise à facturation conditionnelle
    cursor crLinkedPrestations(iLpmCategory number)
    is
      select distinct CAT.SCH_OUTLAY_CATEGORY_ID
                    , CAT.PC_SQLST_SEL_ID
                    , CAT.COU_ONE_BY_DAY
                 from SCH_OUT_CAT_S_CAT_LINKED CLK
                    , SCH_OUTLAY_CATEGORY CAT
                where CLK.SCH_OUTLAY_CATEGORY_ID = iLpmCategory
                  and CLK.SCH_OUTLAY_CATEGORY_LINKED_ID = CAT.SCH_OUTLAY_CATEGORY_ID
                  and CAT.COU_CONDITIONNAL = 1;

    ioErrorMsg              varchar2(2000);
    liBilled                integer;
    ioSCH_ENTERED_OUTLAY_ID number;
    vtblNewOutlayidx        number;
    lnNewTariff             number;
    lvDicTariffId           varchar2(10);
    lnSumqty                number;
  begin
    if PCS.PC_CONFIG.GetConfigUpper('LPM_CONDITIONNAL_BILLING') = 'TRUE' then
      -- Pour chaque groupe mensuel des prestations sélectionnées.
      for tplGroupByMonth in CrGroupByMonth loop
        -- Réinitialisations des variables
        vtblNewOutlay.delete;
        AddSelectedReference(0, true);
        vtblNewOutlayidx  := 1;

        -- Pour chaque prestation avec facturation conditionnelle, sélectionnée,  issue du projet de vie
        for tplSelectedLPMServices in crLPMPrestations(tplGroupByMonth.FirstDayOfMonth, tplGroupByMonth.LastDayOfMonth) loop
          -- Pour chaque prestation liée
          for tplLinkedPrestations in crLinkedPrestations(tplSelectedLPMServices.SCH_OUTLAY_CATEGORY_ID) loop
            -- Vérification du nombre d'occurence autorisées par jour.
            if     TplLinkedPrestations.COU_ONE_BY_DAY = 1
               and CheckBilledPrestation(tplSelectedLPMServices.SCH_STUDENT_ID
                                       , tplLinkedPrestations.SCH_OUTLAY_CATEGORY_ID
                                       , tplSelectedLPMServices.EOU_OUTLAY_DATE
                                        ) = 1 then
              SCH_PRC_LPM_INTERFACE.UpdateProcessedEou(iEnteredOutlayId => tplSelectedLPMServices.LPM_ENTERED_OUTLAY_ID);
            else
              -- Vérification de la condition SQL.
              if tplLinkedPrestations.PC_SQLST_SEL_ID is not null then
                if CheckSQLCondition(tplLinkedPrestations.PC_SQLST_SEL_ID
                                   , tplSelectedLPMServices.SCH_STUDENT_ID
                                   , tplSelectedLPMServices.EOU_OUTLAY_DATE
                                   , tplLinkedPrestations.SCH_OUTLAY_CATEGORY_ID
                                    ) = 1 then
                  -- Facturation de la prestation
                  ioSCH_ENTERED_OUTLAY_ID  := null;
                  SCH_PRC_LPM_INTERFACE.GenerateOutlayEntry(tplSelectedLPMServices.EOU_OUTLAY_DATE
                                                          , tplSelectedLPMServices.SCH_STUDENT_ID
                                                          , tplSelectedLPMServices.EOU_QTY
                                                          , tplLinkedPrestations.SCH_OUTLAY_CATEGORY_ID
                                                          , ioErrorMsg
                                                          , liBilled
                                                          , null
                                                          , tplSelectedLPMServices.EOU_COMMENT
                                                          , ioSCH_ENTERED_OUTLAY_ID
                                                           );

                  -- Stockage en mémoire des prestations générées pendant cette session de facturation
                  if nvl(ioSCH_ENTERED_OUTLAY_ID, 0) <> 0 then
                    begin
                      select *
                        into vTblNewOutlay(vtblNewOutlayidx)
                        from SCH_ENTERED_OUTLAY
                       where SCH_ENTERED_OUTLAY_ID = ioSCH_ENTERED_OUTLAY_ID;

                      vtblNewOutlayidx  := vtblNewOutlayidx + 1;
                    exception
                      when others then
                        null;
                    end;
                  end if;

                  -- Stockage de la prestation projet de vie traitée pour mise àjour ultérieure
                  AddSelectedReference(tplSelectedLPMServices.LPM_ENTERED_OUTLAY_ID);
                  -- Mise à jour de la saisie LPM - Importé / Erreurs
                  SCH_PRC_LPM_INTERFACE.UpdateProcessedEou(iErrorMsg => ioErrorMsg);
                  -- Mise à jour des références des lignes traitées
                  SCH_PRC_LPM_INTERFACE.UpdateReferencedEou(iSchEnteredOutlayId => ioSCH_ENTERED_OUTLAY_ID);
                end if;
              end if;
            end if;
          end loop;
        end loop;

        -- Regroupement
        if vtblNewOutlayidx > 0 then
          -- Calcul de la quantité : Sommage sur la dernière prestation du groupe, et suppression des autres.
          for tplGeneratedOutlay in (select   max(EOU.SCH_ENTERED_OUTLAY_ID) SCH_ENTERED_OUTLAY_ID
                                            , EOU.SCH_STUDENT_ID
                                            , EOU.SCH_OUTLAY_CATEGORY_ID
                                         from SCH_ENTERED_OUTLAY EOU
                                            , (select distinct S.column_value
                                                          from table(GetSessionOutlaysId) S) SESSION_EOU
                                        where EOU.SCH_ENTERED_OUTLAY_ID = SESSION_EOU.column_value
                                     group by EOU.SCH_STUDENT_ID
                                            , EOU.SCH_OUTLAY_CATEGORY_ID) loop
            select nvl(sum(EOU.EOU_QTY), 0)
              into lnSumqty
              from SCH_ENTERED_OUTLAY EOU
                 , (select distinct S.column_value
                               from table(GetSessionOutlaysId) S) SESSION_EOU
             where EOU.SCH_ENTERED_OUTLAY_ID = SESSION_EOU.column_value
               and SCH_ENTERED_OUTLAY_ID <> tplGeneratedOutlay.SCH_ENTERED_OUTLAY_ID
               and SCH_STUDENT_ID = tplGeneratedOutlay.SCH_STUDENT_ID
               and SCH_OUTLAY_CATEGORY_ID = tplGeneratedOutlay.SCH_OUTLAY_CATEGORY_ID;

            update SCH_ENTERED_OUTLAY
               set EOU_QTY = EOU_QTY + lnSumQty
                 , EOU_BASIS_QUANTITY = EOU_BASIS_QUANTITY + lnSumQty
             where SCH_ENTERED_OUTLAY_ID = tplGeneratedOutlay.SCH_ENTERED_OUTLAY_ID;

            delete from SCH_ENTERED_OUTLAY
                  where SCH_ENTERED_OUTLAY_ID in(select SESSION_EOU.column_value
                                                   from table(GetSessionOutlaysId) SESSION_EOU)
                    and SCH_ENTERED_OUTLAY_ID <> tplGeneratedOutlay.SCH_ENTERED_OUTLAY_ID
                    and SCH_STUDENT_ID = tplGeneratedOutlay.SCH_STUDENT_ID
                    and SCH_OUTLAY_CATEGORY_ID = tplGeneratedOutlay.SCH_OUTLAY_CATEGORY_ID;
          end loop;

          -- Calcul des tarifs en fonction de la nouvelle quantité
          for tplProratPrestations in (select distinct EOU.SCH_STUDENT_ID
                                                     , EOU.PAC_CUSTOM_PARTNER_ID
                                                     , EOU.EOU_QTY
                                                     , EOU.EOU_VALUE_DATE
                                                     , EOU.SCH_OUTLAY_CATEGORY_ID
                                                     , EOU.SCH_ENTERED_OUTLAY_ID
                                                     , CAT.PC_SQLST_SEL_TARIFF_ID
                                                     , CAT.COU_INCLUSIVE_TARIFF
                                                  from SCH_ENTERED_OUTLAY EOU
                                                     , SCH_OUTLAY_CATEGORY CAT
                                                     , table(GetSessionOutlaysId) SESSION_EOU
                                                 where EOU.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID
                                                   and EOU.SCH_ENTERED_OUTLAY_ID = SESSION_EOU.column_value) loop
            -- Sélection du code tarif conditionnelle
            lvDicTariffId  :=
              SQLGetTarifCode(tplProratPrestations.PC_SQLST_SEL_TARIFF_ID
                            , tplProratPrestations.SCH_STUDENT_ID
                            , tplProratPrestations.EOU_VALUE_DATE
                            , tplProratPrestations.SCH_OUTLAY_CATEGORY_ID
                             );
            -- Sinon tarif standard
            lnNewTariff    :=
              SCH_OUTLAY_FUNCTIONS.GetOutlayTariff(iSCH_STUDENT_ID           => tplProratPrestations.SCH_STUDENT_ID
                                                 , iPAC_CUSTOM_PARTNER_ID    => tplProratPrestations.PAC_CUSTOM_PARTNER_ID
                                                 , iEOU_BASIS_QUANTITY       => tplProratPrestations.EOU_QTY
                                                 , iEOU_VALUE_DATE           => tplProratPrestations.EOU_VALUE_DATE
                                                 , iSCH_OUTLAY_CATEGORY_ID   => tplProratPrestations.SCH_OUTLAY_CATEGORY_ID
                                                 , iDIC_TARIFF_ID            => lvDicTariffId
                                                  );

            -- Forfaitaire ou journalier
            if tplProratPrestations.COU_INCLUSIVE_TARIFF = 0 then
              lnNewTariff  := lnNewTariff * tplProratPrestations.EOU_QTY;
            end if;

            -- Mise à jour
            update SCH_ENTERED_OUTLAY
               set EOU_TTC_AMOUNT = lnNewTariff
             where SCH_ENTERED_OUTLAY_ID = tplProratPrestations.SCH_ENTERED_OUTLAY_ID;
          end loop;

          -- Recalcul des tarifs au prorata
          for tplProratPrestations in (select distinct EOU.SCH_ENTERED_OUTLAY_ID
                                                     , CAT.COU_PRORATE_CALCUL_BASE
                                                  from SCH_ENTERED_OUTLAY EOU
                                                     , SCH_OUTLAY_CATEGORY CAT
                                                     , table(GetSessionOutlaysId) SESSION_EOU
                                                 where EOU.SCH_OUTLAY_CATEGORY_ID = CAT.SCH_OUTLAY_CATEGORY_ID
                                                   and EOU.SCH_ENTERED_OUTLAY_ID = SESSION_EOU.column_value
                                                   and CAT.COU_PRORATE_CALCUL = 1) loop   --> Calcul au prorata
            update SCH_ENTERED_OUTLAY
               set EOU_TTC_AMOUNT = ACS_FUNCTION.RoundNear( (EOU_TTC_AMOUNT * EOU_QTY) / nvl(tplProratPrestations.COU_PRORATE_CALCUL_BASE, 1), 0, 0)
             where SCH_ENTERED_OUTLAY_ID = tplProratPrestations.SCH_ENTERED_OUTLAY_ID;
          end loop;
        end if;
      end loop;
    end if;
  end ImportConditionnalOutlays;

  /**
  * procedure GenerateOneOutlayEntry
  * Description : Génération d'une ligne de saisie
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param iDate : Date écriture
  * @param iBeneficiary : Bénéficiaire
  * @param iQty : Quantité
  * @param iService : Prestation
  * @param iPeriod : période
  * @param ioErrorMsg : Message d'erreur éventuel
  */
  procedure GenerateOneOutlayEntry(
    iDate                   in     date
  , iBeneficiary            in     number
  , iQty                    in     number
  , iService                in     number
  , iPeriod                 in     number
  , ioErrorMsg              in out varchar2
  , iComment                in     varchar2
  , ioSCH_ENTERED_OUTLAY_ID in out number
  )
  is
    lnCustomer     number;
    lnValorizedQty number;
    lnAmount       number;
    lnOutlay       number;
  begin
    -- Recherche prestation correspondante à la catégorie
    begin
      select SCH_OUTLAY_ID
        into lnOutlay
        from SCH_OUTLAY_CATEGORY
       where SCH_OUTLAY_CATEGORY_ID = iService;
    exception
      when no_data_found then
        ioErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Prestation inconnue!');
    end;

    if ioErrorMsg is null then
      -- Recherche du tiers
      SCH_OUTLAY_FUNCTIONS.GetCustomerByAssociation(aSCH_STUDENT_ID            => iBeneficiary
                                                  , aSCH_OUTLAY_ID             => lnOutlay
                                                  , aSCH_OUTLAY_CATEGORY_ID    => iService
                                                  , aSCH_ECOLAGE_ID            => null
                                                  , aSCH_ECOLAGE_CATEGORY_ID   => null
                                                  , aDateValue                 => iDate
                                                  , aUseCase                   => SCH_OUTLAY_BILLING.ucFundation
                                                  , aPAC_CUSTOM_PARTNER_ID     => lnCustomer
                                                   );
      -- Valorisation de la quantité
      lnValorizedQty  :=
        SCH_OUTLAY_FUNCTIONS.GetValorizedQuantity(iSCH_STUDENT_ID           => iBeneficiary
                                                , iPAC_CUSTOM_PARTNER_ID    => lnCustomer
                                                , iEOU_BASIS_QUANTITY       => iQty
                                                , iEOU_VALUE_DATE           => iDate
                                                , iSCH_OUTLAY_ID            => iService
                                                , iSCH_OUTLAY_CATEGORY_ID   => lnOutlay
                                                 );
      -- Recherche du tarif
      lnAmount        :=
        SCH_OUTLAY_FUNCTIONS.GetOutlayTariff(iSCH_STUDENT_ID           => iBeneficiary
                                           , iPAC_CUSTOM_PARTNER_ID    => lnCustomer
                                           , iEOU_BASIS_QUANTITY       => iQty
                                           , iEOU_VALUE_DATE           => iDate
                                           , iSCH_OUTLAY_CATEGORY_ID   => iService
                                            );
      -- Insertion de l'écriture
      SCH_OUTLAY_ENTRY_FUNCTIONS.InsertSchEnteredOutlay(iSCH_OUTLAY_CATEGORY_ID   => iService
                                                      , iPAC_CUSTOM_PARTNER_ID    => lnCustomer
                                                      , iSCH_STUDENT_ID           => iBeneficiary
                                                      , iEOU_BASIS_QUANTITY       => iQty
                                                      , iEOU_QTY                  => lnValorizedQty
                                                      , iAMOUNT_TTC               => lnAmount
                                                      , iEOU_PIECE_NUMBER         => '<LPM_IMP>'
                                                      , iEOU_VALUE_DATE           => iDate
                                                      , iSCH_YEAR_PERIOD_ID       => iPeriod
                                                      , ioSCH_ENTERED_OUTLAY_ID   => ioSCH_ENTERED_OUTLAY_ID
                                                      , ioErrorMsg                => ioErrorMsg
                                                      , iEOU_COMMENT              => iComment
                                                       );
    end if;
  end GenerateOneOutlayEntry;

  /**
  * procedure GenerateOutlayEntry
  * Description : Génération des lignes de saisie
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param iDate : Date écriture
  * @param iBeneficiary : Bénéficiaire
  * @param iQty : Quantité
  * @param iService : Prestation
  * @param ioErrorMsg : Message d'erreur éventuel
  * @param ioBilled : importée ou pas (On laisse dans le LPM les prestations
  * @param iEvent : événement LPM
  * non corrélées dans la matrice d'association, sans pour autant afficher d'erreur)
  */
  procedure GenerateOutlayEntry(
    iDate                   in     date
  , iBeneficiary            in     number
  , iQty                    in     number
  , iService                in     number
  , ioErrorMsg              in out varchar2
  , ioBilled                in out integer
  , iEvent                  in     number
  , iComment                in     varchar2
  , ioSCH_ENTERED_OUTLAY_ID in out number
  )
  is
    lnCustomer        number;
    lnValorizedQty    number;
    lnAmount          number;
    lnPeriod          number;
    lnOutlay          number;
    lbLinkedCatExists boolean;
  begin
    ioErrorMsg  := null;
    ioBilled    := 0;
    -- Recherche de la période
    lnPeriod    := GetYearPeriod(iDate);

    if nvl(lnPeriod, 0) = 0 then
      ioErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Aucune période trouvée!');
    elsif nvl(iQty, 0) = 0 then
      ioBilled  := 1;
    else
      -- Pour chaque prestation liée à la prestation LPM
      lbLinkedCatExists  := false;

      for tplLinkedCategory in (select distinct CLK.SCH_OUTLAY_CATEGORY_LINKED_ID
                                              , SCA.SCH_CUSTOMERS_ASSOCIATION_ID
                                           from SCH_OUT_CAT_S_CAT_LINKED CLK
                                              , (select *
                                                   from SCH_CUSTOMERS_ASSOCIATION
                                                  where SCH_STUDENT_ID = iBeneficiary
                                                    and iDate between cas_validity_date and nvl(cas_validity_date_to, iDate) ) SCA
                                          where CLK.SCH_OUTLAY_CATEGORY_ID = iService
                                            and CLK.SCH_OUTLAY_CATEGORY_LINKED_ID = SCA.SCH_OUTLAY_CATEGORY_ID(+)) loop
        -- Si l'association existe, ou qu'il s'agit d'un event
        if    tplLinkedCategory.SCH_CUSTOMERS_ASSOCIATION_ID is not null
           or nvl(iEvent, 0) <> 0 then
          -- Génération des lignes de saisies correspondant aux prestations liées
          GenerateOneOutlayEntry(iDate
                               , iBeneficiary
                               , iQty
                               , tplLinkedCategory.SCH_OUTLAY_CATEGORY_LINKED_ID
                               , lnPeriod
                               , ioErrorMsg
                               , iComment
                               , ioSCH_ENTERED_OUTLAY_ID
                                );

          -- Si pas d'erreur alors la ligne est facturée
          if ioErrorMsg is null then
            ioBilled  := 1;
          end if;
        end if;

        lbLinkedCatExists  := true;
      end loop;

      -- Si pas de prestation liée (corrélées ou pas), on l'importe
      if not lbLinkedCatExists then
        GenerateOneOutlayEntry(iDate, iBeneficiary, iQty, iService, lnPeriod, ioErrorMsg, iComment, ioSCH_ENTERED_OUTLAY_ID);

        -- Si pas d'erreur alors la ligne est facturée
        if ioErrorMsg is null then
          ioBilled  := 1;
        end if;
      end if;
    end if;
  end GenerateOutlayEntry;
end SCH_PRC_LPM_INTERFACE;
