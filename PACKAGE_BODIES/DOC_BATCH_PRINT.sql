--------------------------------------------------------
--  DDL for Package Body DOC_BATCH_PRINT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_BATCH_PRINT" 
is
  /**
  * procedure InsertDocIntoJobDetail
  */
  procedure InsertDocIntoJobDetail(
    paPrintJobId in DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_ID%type
  , paDocId      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSqlControl  in number default 0
  )
  is
    lPJD_ID DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_DETAIL_ID%type;
  begin
    lPJD_ID  := INIT_ID_SEQ.nextval;

    insert into DOC_PRINT_JOB_DETAIL
                (DOC_PRINT_JOB_ID
               , DOC_PRINT_JOB_DETAIL_ID
               , DOC_DOCUMENT_ID
               , DMT_NUMBER
               , PJD_WORKSTATION
               , A_DATECRE
               , A_IDCRE
                )
      select paPrintJobId
           , lPJD_ID
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_NUMBER
           , 0
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from DOC_DOCUMENT DMT
       where DMT.DOC_DOCUMENT_ID = paDocId;

    if aSqlControl = 1 then
      UpdateDetailOptions(lPJD_ID, null);
    end if;
  end InsertDocIntoJobDetail;

/*************************************************************************************************************************/
  /**
  * procedure ClearJobDetail
  */
  procedure ClearJobDetail(paPrintJobId in DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_ID%type)
  is
  begin
    delete from DOC_PRINT_JOB_DETAIL
          where DOC_PRINT_JOB_ID = paPrintJobId;
  end ClearJobDetail;

  function TestSql(aSql in clob, aDmtNumber in DOC_DOCUMENT.DMT_NUMBER%type, aUseName in PCS.PC_USER.USE_NAME%type)
    return boolean
  is
    vSqlCommand    PTC_TARIFF.TRF_SQL_CONDITIONAL%type;
    vReturnValue   boolean                               default false;
    vDynamicCursor integer;
    vErrorCursor   integer;
  begin
    begin
      -- remplace le paramètre DOC_RECORD_ID s'il est présent
      vSqlCommand     := replace(aSql, ':DMT_NUMBER', '''' || aDmtNumber || '''');
      -- remplace le(s) éventuel(s) paramètre(s) restant(s) par l'id du tiers
      vSqlCommand     := replace(vSqlCommand, ':USE_NAME', '''' || aUseName || '''');
      -- remplace le owner
      vSqlCommand     := replace(vSqlCommand, co.cCompanyOwner, PCS.PC_I_LIB_SESSION.GetCompanyOwner);
      --raise_application_error(-20000, SqlCommand);

      -- Attribution d'un Handle de curseur
      vDynamicCursor  := DBMS_SQL.open_cursor;
      -- Vérification de la syntaxe de la commande SQL
      DBMS_SQL.Parse(vDynamicCursor, vSqlCommand, DBMS_SQL.V7);
      -- Exécution de la commande SQL
      vErrorCursor    := DBMS_SQL.execute(vDynamicCursor);

      -- Obtenir le tuple suivant
      if DBMS_SQL.fetch_rows(vDynamicCursor) > 0 then
        vReturnValue  := true;
      end if;

      -- Ferme le curseur
      DBMS_SQL.close_cursor(vDynamicCursor);
    exception
      when others then
        if DBMS_SQL.is_open(vDynamicCursor) then
          DBMS_SQL.close_cursor(vDynamicCursor);
          raise_application_error(-20000, 'Mauvaise commande : ' || aSql || chr(13) || vSqlCommand);
        end if;
    end;

    return vReturnValue;
  end TestSql;

/*************************************************************************************************************************/
  /**
  * procedure UpdateDetailOptions
  */
  procedure UpdateDetailOptions(paJobDetId in DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_DETAIL_ID%type, paPrint in varchar)
  is
    vJobId   DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_ID%type;
    vGrouped DOC_PRINT_JOB.PJO_GROUPED_PRINTING%type;
    vUpdate  DOC_PRINT_JOB.PJO_UPDATE_PRINTING%type;
    formNb   number;
    tmpSql   varchar2(1000);
    vPrint   varchar2(20);
  begin
    -- initialisation des variables
    select PJO.DOC_PRINT_JOB_ID
         , PJO.PJO_GROUPED_PRINTING
         , PJO.PJO_UPDATE_PRINTING
      into vJobId
         , vGrouped
         , vUpdate
      from DOC_PRINT_JOB PJO
         , DOC_PRINT_JOB_DETAIL PJD
     where PJO.DOC_PRINT_JOB_ID = PJD.DOC_PRINT_JOB_ID
       and PJD.DOC_PRINT_JOB_DETAIL_ID = paJobDetId;

    -- flags impression groupée  et mise à jour flag impression mis à jour à partir des mêmes flags sur le travail
    update DOC_PRINT_JOB_DETAIL
       set PJD_GROUPED_PRINTING = vGrouped
         , PJD_UPDATE_PRINTING = vUpdate
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_PRINT_JOB_DETAIL_ID = paJobDetId;

    if paPrint is not null then
      vPrint  := paPrint;
    else
      declare
        vDmtNumber DOC_DOCUMENT.DMT_NUMBER%type;
        vUseName   PCS.PC_USER.USE_NAME%type;
        vSql0      DOC_PRINT_JOB.PJO_SQL0%type;
        vSql1      DOC_PRINT_JOB.PJO_SQL1%type;
        vSql2      DOC_PRINT_JOB.PJO_SQL2%type;
        vSql3      DOC_PRINT_JOB.PJO_SQL3%type;
        vSql4      DOC_PRINT_JOB.PJO_SQL4%type;
        vSql5      DOC_PRINT_JOB.PJO_SQL5%type;
        vSql6      DOC_PRINT_JOB.PJO_SQL6%type;
        vSql7      DOC_PRINT_JOB.PJO_SQL7%type;
        vSql8      DOC_PRINT_JOB.PJO_SQL8%type;
        vSql9      DOC_PRINT_JOB.PJO_SQL9%type;
        vSql10     DOC_PRINT_JOB.PJO_SQL10%type;
        vCopies0   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies1   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies2   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies3   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies4   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies5   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies6   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies7   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies8   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies9   DOC_PRINT_JOB.PJO_COPIES0%type;
        vCopies10  DOC_PRINT_JOB.PJO_COPIES0%type;
      begin
        --algo de test des conditions
        select DMT.DMT_NUMBER
             , use.USE_NAME
             , PJO.PJO_SQL0
             , PJO.PJO_SQL1
             , PJO.PJO_SQL2
             , PJO.PJO_SQL3
             , PJO.PJO_SQL4
             , PJO.PJO_SQL5
             , PJO.PJO_SQL6
             , PJO.PJO_SQL7
             , PJO.PJO_SQL8
             , PJO.PJO_SQL9
             , PJO.PJO_SQL10
             , PJO.PJO_COPIES0
             , PJO.PJO_COPIES1
             , PJO.PJO_COPIES2
             , PJO.PJO_COPIES3
             , PJO.PJO_COPIES4
             , PJO.PJO_COPIES5
             , PJO.PJO_COPIES6
             , PJO.PJO_COPIES7
             , PJO.PJO_COPIES8
             , PJO.PJO_COPIES9
             , PJO.PJO_COPIES10
          into vDmtNumber
             , vUseName
             , vSql0
             , vSql1
             , vSql2
             , vSql3
             , vSql4
             , vSql5
             , vSql6
             , vSql7
             , vSql8
             , vSql9
             , vSql10
             , vCopies0
             , vCopies1
             , vCopies2
             , vCopies3
             , vCopies4
             , vCopies5
             , vCopies6
             , vCopies7
             , vCopies8
             , vCopies9
             , vCopies10
          from DOC_PRINT_JOB PJO
             , DOC_PRINT_JOB_DETAIL PJD
             , DOC_DOCUMENT DMT
             , PCS.PC_USER use
         where PJO.DOC_PRINT_JOB_ID = PJD.DOC_PRINT_JOB_ID
           and PJD.DOC_PRINT_JOB_DETAIL_ID = paJobDetId
           and DMT.DOC_DOCUMENT_ID = PJD.DOC_DOCUMENT_ID
           and use.PC_USER_ID = PCS.PC_I_LIB_SESSION.GetUserId;

        -- test la condition du formulaire 0
        if nvl(vCopies0, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql0 is not null then
          if TestSql(vSql0, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 1
        if nvl(vCopies1, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql1 is not null then
          if TestSql(vSql1, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 2
        if nvl(vCopies2, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql2 is not null then
          if TestSql(vSql2, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 3
        if nvl(vCopies3, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql3 is not null then
          if TestSql(vSql3, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 4
        if nvl(vCopies4, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql4 is not null then
          if TestSql(vSql4, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 5
        if nvl(vCopies5, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql5 is not null then
          if TestSql(vSql5, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 6
        if nvl(vCopies6, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql6 is not null then
          if TestSql(vSql6, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 7
        if nvl(vCopies7, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql7 is not null then
          if TestSql(vSql7, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 8
        if nvl(vCopies0, 8) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql8 is not null then
          if TestSql(vSql8, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 9
        if nvl(vCopies9, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql9 is not null then
          if TestSql(vSql9, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;

        -- test la condition du formulaire 10
        if nvl(vCopies10, 0) = 0 then
          vPrint  := vPrint || '0';
        elsif vSql10 is not null then
          if TestSql(vSql10, vDmtNumber, vUseName) then
            vPrint  := vPrint || '1';
          else
            vPrint  := vPrint || '0';
          end if;
        else
          vPrint  := vPrint || '1';
        end if;
      end;
    end if;

    -- si le document ne peut être imprimé sur aucun formulaire, on le supprime du détail de l'impression
    if vPrint = '00000000000' then
      delete from DOC_PRINT_JOB_DETAIL
            where DOC_PRINT_JOB_DETAIL_ID = paJobDetId;
    else
      formNb  := 1;

      loop
        if substr(vPrint, formNb, 1) = '1' then
          tmpSql  :=
            'update DOC_PRINT_JOB_DETAIL ' ||
            '   set (PJD_EDIT_NAME' ||
            to_char(formNb - 1) ||
            '     ,  PJD_PRINTER_NAME' ||
            to_char(formNb - 1) ||
            '     ,  PJD_PRINTER_TRAY' ||
            to_char(formNb - 1) ||
            '     ,  PJD_COLLATE_COPIES' ||
            to_char(formNb - 1) ||
            '     ,  PJD_COPIES' ||
            to_char(formNb - 1) ||
            '     ,  A_IDMOD' ||
            '     ,  A_DATEMOD' ||
            ') = ' ||
            ' (select PJO_EDIT_NAME' ||
            to_char(formNb - 1) ||
            '       , PJO_PRINTER_NAME' ||
            to_char(formNb - 1) ||
            '       , PJO_PRINTER_TRAY' ||
            to_char(formNb - 1) ||
            '       , PJO_COLLATE_COPIES' ||
            to_char(formNb - 1) ||
            '       , PJO_COPIES' ||
            to_char(formNb - 1) ||
            '       , PCS.PC_I_LIB_SESSION.GetUserIni' ||
            '       , sysdate' ||
            '    from DOC_PRINT_JOB ' ||
            '   where DOC_PRINT_JOB_ID = ' ||
            to_char(vJobId) ||
            ')' ||
            '   where DOC_PRINT_JOB_DETAIL_ID = ' ||
            to_char(paJobDetId);
        else
          tmpSql  :=
            'update DOC_PRINT_JOB_DETAIL ' ||
            '   set PJD_EDIT_NAME' ||
            to_char(formNb - 1) ||
            ' = null' ||
            '     ,  PJD_PRINTER_NAME' ||
            to_char(formNb - 1) ||
            ' = null' ||
            '     ,  PJD_PRINTER_TRAY' ||
            to_char(formNb - 1) ||
            ' = null' ||
            '     ,  PJD_COLLATE_COPIES' ||
            to_char(formNb - 1) ||
            ' = null' ||
            '     ,  PJD_COPIES' ||
            to_char(formNb - 1) ||
            ' = null' ||
            '     ,  A_IDMOD = null' ||
            '     ,  A_DATEMOD = null' ||
            '   where DOC_PRINT_JOB_DETAIL_ID = ' ||
            to_char(paJobDetId);
        end if;

        execute immediate tmpSql;

        formNb  := formNb + 1;
        exit when formNb = 12;
      end loop;
    end if;
  end UpdateDetailOptions;

/*************************************************************************************************************************/
  /**
  * function CountJobDetail
  */
  function CountJobDetail(paJobId in DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type)
    return number
  is
    vCounter number;
  begin
    select count(DOC_PRINT_JOB_DETAIL_ID)
      into vCounter
      from DOC_PRINT_JOB_DETAIL
     where DOC_PRINT_JOB_ID = paJobId;

    return vCounter;
  end CountJobDetail;

/*************************************************************************************************************************/
  /**
  * procedure PurgeJob
  */
  procedure PurgeJob
  is
  begin
    delete from DOC_PRINT_JOB PJO
          where (    (PJO.PJO_SESSION_ID is null)
                 or (PJO.PJO_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID)
                 or not(COM_FUNCTIONS.IS_SESSION_ALIVE(PJO.PJO_SESSION_ID) = 1)
                )
            and not exists(select DOC_PRINT_JOB_ID
                             from DOC_PRINT_JOB_DETAIL PJD
                            where PJD.DOC_PRINT_JOB_ID = PJO.DOC_PRINT_JOB_ID);
  end PurgeJob;

/*************************************************************************************************************************/
  /**
  * function GetJobGauge
  */
  function GetJobGauge(paJobId in DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type)
    return DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type
  is
    vGaugeId number;
  begin
    select distinct DOC_GAUGE_ID
               into vGaugeId
               from DOC_DOCUMENT DOC
                  , DOC_PRINT_JOB_DETAIL PJD
              where DOC.DOC_DOCUMENT_ID = PJD.DOC_DOCUMENT_ID
                and PJD.DOC_PRINT_JOB_ID = paJobId;

    return vGaugeId;
  end GetJobGauge;

  /**
  * procedure UpdatePrintFlag
  */
  procedure UpdatePrintFlag(iJobDetailId in DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_DETAIL_ID%type)
  is
    vPrintDate date;
    pragma autonomous_transaction;
  begin
    vPrintDate  := sysdate;

    for tplDetails in (select   DOC_PRINT_JOB_DETAIL_ID
                              , PJD_UPDATE_PRINTING
                              , DOC_DOCUMENT_ID
                           from DOC_PRINT_JOB_DETAIL
                          where DOC_PRINT_JOB_DETAIL_ID = iJobDetailId
                       order by DOC_PRINT_JOB_DETAIL_ID) loop
      -- mise à jour de la table doc_document
      if tplDetails.PJD_UPDATE_PRINTING = 1 then
        update DOC_DOCUMENT DMT
           set (DMT_MAIN_PRINTING, DMT_DATE_MAIN_PRINTING, DMT_ALT1_PRINTING, DMT_DATE_ALT1_PRINTING, DMT_ALT2_PRINTING, DMT_DATE_ALT2_PRINTING
              , DMT_ALT3_PRINTING, DMT_DATE_ALT3_PRINTING, DMT_ALT4_PRINTING, DMT_DATE_ALT4_PRINTING, DMT_ALT5_PRINTING, DMT_DATE_ALT5_PRINTING
              , DMT_ALT6_PRINTING, DMT_DATE_ALT6_PRINTING, DMT_ALT7_PRINTING, DMT_DATE_ALT7_PRINTING, DMT_ALT8_PRINTING, DMT_DATE_ALT8_PRINTING
              , DMT_ALT9_PRINTING, DMT_DATE_ALT9_PRINTING, DMT_ALT10_PRINTING, DMT_DATE_ALT10_PRINTING) =
                 (select decode(PJD.PJD_EDIT_NAME0, null, DMT.DMT_MAIN_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME0, null, DMT.DMT_DATE_MAIN_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME1, null, DMT.DMT_ALT1_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME1, null, DMT.DMT_DATE_ALT1_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME2, null, DMT.DMT_ALT2_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME2, null, DMT.DMT_DATE_ALT2_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME3, null, DMT.DMT_ALT3_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME3, null, DMT.DMT_DATE_ALT3_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME4, null, DMT.DMT_ALT4_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME4, null, DMT.DMT_DATE_ALT4_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME5, null, DMT.DMT_ALT5_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME5, null, DMT.DMT_DATE_ALT5_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME6, null, DMT.DMT_ALT6_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME6, null, DMT.DMT_DATE_ALT6_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME7, null, DMT.DMT_ALT7_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME7, null, DMT.DMT_DATE_ALT7_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME8, null, DMT.DMT_ALT8_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME8, null, DMT.DMT_DATE_ALT8_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME9, null, DMT.DMT_ALT9_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME9, null, DMT.DMT_DATE_ALT9_PRINTING, vPrintDate)
                       , decode(PJD.PJD_EDIT_NAME10, null, DMT.DMT_ALT10_PRINTING, 1)
                       , decode(PJD.PJD_EDIT_NAME10, null, DMT.DMT_DATE_ALT10_PRINTING, vPrintDate)
                    from DOC_PRINT_JOB_DETAIL PJD
                   where PJD.DOC_PRINT_JOB_DETAIL_ID = tplDetails.DOC_PRINT_JOB_DETAIL_ID)
         where DMT.DOC_DOCUMENT_ID = tplDetails.DOC_DOCUMENT_ID;
      end if;

      -- mise à jour de la table doc_print_job_detail
      update DOC_PRINT_JOB_DETAIL
         set PJD_PRINTED = 1
           , PJD_PRINT_DATE = vPrintDate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_PRINT_JOB_DETAIL_ID = tplDetails.DOC_PRINT_JOB_DETAIL_ID;
    end loop;

    commit;
  end UpdatePrintFlag;

/*************************************************************************************************************************/
  /**
  * procedure UpdateJobStatus
  */
  procedure UpdateJobStatus(paJobId in DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type)
  is
    vPrintedCount number;
  begin
    -- mise à jour de la table doc_print_job si tous les détails ont été imprimés
    select count(PJD_PRINTED)
      into vPrintedCount
      from DOC_PRINT_JOB_DETAIL
     where DOC_PRINT_JOB_ID = paJobId
       and PJD_PRINTED = 0;

    if vPrintedCount = 0 then
      update DOC_PRINT_JOB
         set PJO_EXECUTED = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_PRINT_JOB_ID = paJobId;
    end if;
  end UpdateJobStatus;

/*************************************************************************************************************************/
  /**
  * function isJobTreated
  */
  function isJobTreated(paJobId in DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type)
    return number
  is
    vResult number;
  begin
    select PJO_EXECUTED
      into vResult
      from DOC_PRINT_JOB
     where DOC_PRINT_JOB_ID = paJobId;

    return vResult;
  end isJobTreated;

/*************************************************************************************************************************/
/**
* procedure CreateJob
*/
  procedure CreateJob(
    aPrintJobId      in out DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type
  , aName            in     DOC_PRINT_JOB.PJO_NAME%type
  , aComment         in     DOC_PRINT_JOB.PJO_COMMENT%type
  , aSql             in     DOC_PRINT_JOB.PJO_SQL%type
  , aExecuted        in     DOC_PRINT_JOB.PJO_EXECUTED%type
  , aNextExecution   in     DOC_PRINT_JOB.PJO_NEXT_EXECUTION%type
  , aDiffPrinting    in     DOC_PRINT_JOB.PJO_DIFFERED_PRINTING%type
  , aDiffExtraction  in     DOC_PRINT_JOB.PJO_DIFFERED_EXTRACTION%type
  , aGroupedPrinting in     DOC_PRINT_JOB.PJO_GROUPED_PRINTING%type
  , aUpdatePrinting  in     DOC_PRINT_JOB.PJO_UPDATE_PRINTING%type
  , aEditName0       in     DOC_PRINT_JOB.PJO_EDIT_NAME0%type
  , aPrinterName0    in     DOC_PRINT_JOB.PJO_PRINTER_NAME0%type
  , aPrinterTray0    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY0%type
  , aCollateCopies0  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES0%type
  , aCopies0         in     DOC_PRINT_JOB.PJO_COPIES0%type
  , aSql0            in     DOC_PRINT_JOB.PJO_SQL0%type
  , aEditName1       in     DOC_PRINT_JOB.PJO_EDIT_NAME1%type
  , aPrinterName1    in     DOC_PRINT_JOB.PJO_PRINTER_NAME1%type
  , aPrinterTray1    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY1%type
  , aCollateCopies1  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES1%type
  , aCopies1         in     DOC_PRINT_JOB.PJO_COPIES1%type
  , aSql1            in     DOC_PRINT_JOB.PJO_SQL1%type
  , aEditName2       in     DOC_PRINT_JOB.PJO_EDIT_NAME2%type
  , aPrinterName2    in     DOC_PRINT_JOB.PJO_PRINTER_NAME2%type
  , aPrinterTray2    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY2%type
  , aCollateCopies2  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES2%type
  , aCopies2         in     DOC_PRINT_JOB.PJO_COPIES2%type
  , aSql2            in     DOC_PRINT_JOB.PJO_SQL2%type
  , aEditName3       in     DOC_PRINT_JOB.PJO_EDIT_NAME3%type
  , aPrinterName3    in     DOC_PRINT_JOB.PJO_PRINTER_NAME3%type
  , aPrinterTray3    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY3%type
  , aCollateCopies3  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES3%type
  , aCopies3         in     DOC_PRINT_JOB.PJO_COPIES3%type
  , aSql3            in     DOC_PRINT_JOB.PJO_SQL3%type
  , aEditName4       in     DOC_PRINT_JOB.PJO_EDIT_NAME4%type
  , aPrinterName4    in     DOC_PRINT_JOB.PJO_PRINTER_NAME4%type
  , aPrinterTray4    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY4%type
  , aCollateCopies4  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES4%type
  , aCopies4         in     DOC_PRINT_JOB.PJO_COPIES4%type
  , aSql4            in     DOC_PRINT_JOB.PJO_SQL4%type
  , aEditName5       in     DOC_PRINT_JOB.PJO_EDIT_NAME5%type
  , aPrinterName5    in     DOC_PRINT_JOB.PJO_PRINTER_NAME5%type
  , aPrinterTray5    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY5%type
  , aCollateCopies5  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES5%type
  , aCopies5         in     DOC_PRINT_JOB.PJO_COPIES5%type
  , aSql5            in     DOC_PRINT_JOB.PJO_SQL5%type
  , aEditName6       in     DOC_PRINT_JOB.PJO_EDIT_NAME6%type
  , aPrinterName6    in     DOC_PRINT_JOB.PJO_PRINTER_NAME6%type
  , aPrinterTray6    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY6%type
  , aCollateCopies6  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES6%type
  , aCopies6         in     DOC_PRINT_JOB.PJO_COPIES6%type
  , aSql6            in     DOC_PRINT_JOB.PJO_SQL6%type
  , aEditName7       in     DOC_PRINT_JOB.PJO_EDIT_NAME7%type
  , aPrinterName7    in     DOC_PRINT_JOB.PJO_PRINTER_NAME7%type
  , aPrinterTray7    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY7%type
  , aCollateCopies7  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES7%type
  , aCopies7         in     DOC_PRINT_JOB.PJO_COPIES7%type
  , aSql7            in     DOC_PRINT_JOB.PJO_SQL7%type
  , aEditName8       in     DOC_PRINT_JOB.PJO_EDIT_NAME8%type
  , aPrinterName8    in     DOC_PRINT_JOB.PJO_PRINTER_NAME8%type
  , aPrinterTray8    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY8%type
  , aCollateCopies8  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES8%type
  , aCopies8         in     DOC_PRINT_JOB.PJO_COPIES8%type
  , aSql8            in     DOC_PRINT_JOB.PJO_SQL8%type
  , aEditName9       in     DOC_PRINT_JOB.PJO_EDIT_NAME9%type
  , aPrinterName9    in     DOC_PRINT_JOB.PJO_PRINTER_NAME9%type
  , aPrinterTray9    in     DOC_PRINT_JOB.PJO_PRINTER_TRAY9%type
  , aCollateCopies9  in     DOC_PRINT_JOB.PJO_COLLATE_COPIES9%type
  , aCopies9         in     DOC_PRINT_JOB.PJO_COPIES9%type
  , aSql9            in     DOC_PRINT_JOB.PJO_SQL9%type
  , aEditName10      in     DOC_PRINT_JOB.PJO_EDIT_NAME10%type
  , aPrinterName10   in     DOC_PRINT_JOB.PJO_PRINTER_NAME10%type
  , aPrinterTray10   in     DOC_PRINT_JOB.PJO_PRINTER_TRAY10%type
  , aCollateCopies10 in     DOC_PRINT_JOB.PJO_COLLATE_COPIES10%type
  , aCopies10        in     DOC_PRINT_JOB.PJO_COPIES10%type
  , aSql10           in     DOC_PRINT_JOB.PJO_SQL10%type
  )
  is
  begin
    select nvl(aPrintJobId, INIT_ID_SEQ.nextval)
      into aPrintJobId
      from dual;

    insert into DOC_PRINT_JOB
                (DOC_PRINT_JOB_ID
               , PJO_NAME
               , PJO_COMMENT
               , PJO_SQL
               , PJO_EXECUTED
               , PJO_NEXT_EXECUTION
               , PJO_DIFFERED_PRINTING
               , PJO_DIFFERED_EXTRACTION
               , PJO_GROUPED_PRINTING
               , PJO_UPDATE_PRINTING
               , PJO_EDIT_NAME0
               , PJO_PRINTER_NAME0
               , PJO_PRINTER_TRAY0
               , PJO_COLLATE_COPIES0
               , PJO_COPIES0
               , PJO_SQL0
               , PJO_EDIT_NAME1
               , PJO_PRINTER_NAME1
               , PJO_PRINTER_TRAY1
               , PJO_COLLATE_COPIES1
               , PJO_COPIES1
               , PJO_SQL1
               , PJO_EDIT_NAME2
               , PJO_PRINTER_NAME2
               , PJO_PRINTER_TRAY2
               , PJO_COLLATE_COPIES2
               , PJO_COPIES2
               , PJO_SQL2
               , PJO_EDIT_NAME3
               , PJO_PRINTER_NAME3
               , PJO_PRINTER_TRAY3
               , PJO_COLLATE_COPIES3
               , PJO_COPIES3
               , PJO_SQL3
               , PJO_EDIT_NAME4
               , PJO_PRINTER_NAME4
               , PJO_PRINTER_TRAY4
               , PJO_COLLATE_COPIES4
               , PJO_COPIES4
               , PJO_SQL4
               , PJO_EDIT_NAME5
               , PJO_PRINTER_NAME5
               , PJO_PRINTER_TRAY5
               , PJO_COLLATE_COPIES5
               , PJO_COPIES5
               , PJO_SQL5
               , PJO_EDIT_NAME6
               , PJO_PRINTER_NAME6
               , PJO_PRINTER_TRAY6
               , PJO_COLLATE_COPIES6
               , PJO_COPIES6
               , PJO_SQL6
               , PJO_EDIT_NAME7
               , PJO_PRINTER_NAME7
               , PJO_PRINTER_TRAY7
               , PJO_COLLATE_COPIES7
               , PJO_COPIES7
               , PJO_SQL7
               , PJO_EDIT_NAME8
               , PJO_PRINTER_NAME8
               , PJO_PRINTER_TRAY8
               , PJO_COLLATE_COPIES8
               , PJO_COPIES8
               , PJO_SQL8
               , PJO_EDIT_NAME9
               , PJO_PRINTER_NAME9
               , PJO_PRINTER_TRAY9
               , PJO_COLLATE_COPIES9
               , PJO_COPIES9
               , PJO_SQL9
               , PJO_EDIT_NAME10
               , PJO_PRINTER_NAME10
               , PJO_PRINTER_TRAY10
               , PJO_COLLATE_COPIES10
               , PJO_COPIES10
               , PJO_SQL10
               , A_DATECRE
               , A_IDCRE
                )
         values (aPrintJobId
               , aName
               , aComment
               , aSql
               , aExecuted
               , aNextExecution
               , aDiffPrinting
               , aDiffExtraction
               , aGroupedPrinting
               , aUpdatePrinting
               , aEditName0
               , aPrinterName0
               , aPrinterTray0
               , aCollateCopies0
               , aCopies0
               , aSql0
               , aEditName1
               , aPrinterName1
               , aPrinterTray1
               , aCollateCopies1
               , aCopies1
               , aSql1
               , aEditName2
               , aPrinterName2
               , aPrinterTray2
               , aCollateCopies2
               , aCopies2
               , aSql2
               , aEditName3
               , aPrinterName3
               , aPrinterTray3
               , aCollateCopies3
               , aCopies3
               , aSql3
               , aEditName4
               , aPrinterName4
               , aPrinterTray4
               , aCollateCopies4
               , aCopies4
               , aSql4
               , aEditName5
               , aPrinterName5
               , aPrinterTray5
               , aCollateCopies5
               , aCopies5
               , aSql5
               , aEditName6
               , aPrinterName6
               , aPrinterTray6
               , aCollateCopies6
               , aCopies6
               , aSql6
               , aEditName7
               , aPrinterName7
               , aPrinterTray7
               , aCollateCopies7
               , aCopies7
               , aSql7
               , aEditName8
               , aPrinterName8
               , aPrinterTray8
               , aCollateCopies8
               , aCopies8
               , aSql8
               , aEditName9
               , aPrinterName9
               , aPrinterTray9
               , aCollateCopies9
               , aCopies9
               , aSql9
               , aEditName10
               , aPrinterName10
               , aPrinterTray10
               , aCollateCopies10
               , aCopies10
               , aSql10
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end CreateJob;

/*************************************************************************************************************************/
/**
* procedure JobDuplicate
*/
  procedure JobDuplicate(paPrintJobId in DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type, paNewJobId out DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type)
  is
    vCurrentDate      date;

    cursor crPrintJobDetail(cJobId in DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_ID%type)
    is
      select *
        from DOC_PRINT_JOB_DETAIL
       where DOC_PRINT_JOB_ID = cJobId;

    tplPrintJobDetail crPrintJobDetail%rowtype;
  begin
    select sysdate
         , INIT_ID_SEQ.nextval
      into vCurrentDate
         , paNewJobId
      from dual;

    insert into DOC_PRINT_JOB
                (DOC_PRINT_JOB_ID
               , PJO_NAME
               , PJO_COMMENT
               , PJO_SQL
               , PJO_EXECUTED
               , PJO_NEXT_EXECUTION
               , PJO_DIFFERED_PRINTING
               , PJO_DIFFERED_EXTRACTION
               , PJO_GROUPED_PRINTING
               , PJO_UPDATE_PRINTING
               , PJO_EDIT_NAME0
               , PJO_PRINTER_NAME0
               , PJO_PRINTER_TRAY0
               , PJO_COLLATE_COPIES0
               , PJO_COPIES0
               , PJO_EDIT_NAME1
               , PJO_PRINTER_NAME1
               , PJO_PRINTER_TRAY1
               , PJO_COLLATE_COPIES1
               , PJO_COPIES1
               , PJO_EDIT_NAME2
               , PJO_PRINTER_NAME2
               , PJO_PRINTER_TRAY2
               , PJO_COLLATE_COPIES2
               , PJO_COPIES2
               , PJO_EDIT_NAME3
               , PJO_PRINTER_NAME3
               , PJO_PRINTER_TRAY3
               , PJO_COLLATE_COPIES3
               , PJO_COPIES3
               , PJO_EDIT_NAME4
               , PJO_PRINTER_NAME4
               , PJO_PRINTER_TRAY4
               , PJO_COLLATE_COPIES4
               , PJO_COPIES4
               , PJO_EDIT_NAME5
               , PJO_PRINTER_NAME5
               , PJO_PRINTER_TRAY5
               , PJO_COLLATE_COPIES5
               , PJO_COPIES5
               , PJO_EDIT_NAME6
               , PJO_PRINTER_NAME6
               , PJO_PRINTER_TRAY6
               , PJO_COLLATE_COPIES6
               , PJO_COPIES6
               , PJO_EDIT_NAME7
               , PJO_PRINTER_NAME7
               , PJO_PRINTER_TRAY7
               , PJO_COLLATE_COPIES7
               , PJO_COPIES7
               , PJO_EDIT_NAME8
               , PJO_PRINTER_NAME8
               , PJO_PRINTER_TRAY8
               , PJO_COLLATE_COPIES8
               , PJO_COPIES8
               , PJO_EDIT_NAME9
               , PJO_PRINTER_NAME9
               , PJO_PRINTER_TRAY9
               , PJO_COLLATE_COPIES9
               , PJO_COPIES9
               , PJO_EDIT_NAME10
               , PJO_PRINTER_NAME10
               , PJO_PRINTER_TRAY10
               , PJO_COLLATE_COPIES10
               , PJO_COPIES10
               , A_DATECRE
               , A_IDCRE
                )
      select paNewJobId   -- DOC_PRINT_JOB_ID
           , PCS.PC_I_LIB_SESSION.GetUserIni || ' - ' || to_char(vCurrentDate, 'dd.mm.yyyy hh24:mi:ss')   -- PJO_NAME
           , PJO_COMMENT
           , PJO_SQL
           , 0   -- PJO_EXECUTED
           , PJO_NEXT_EXECUTION
           , PJO_DIFFERED_PRINTING
           , PJO_DIFFERED_EXTRACTION
           , PJO_GROUPED_PRINTING
           , PJO_UPDATE_PRINTING
           , PJO_EDIT_NAME0
           , PJO_PRINTER_NAME0
           , PJO_PRINTER_TRAY0
           , PJO_COLLATE_COPIES0
           , PJO_COPIES0
           , PJO_EDIT_NAME1
           , PJO_PRINTER_NAME1
           , PJO_PRINTER_TRAY1
           , PJO_COLLATE_COPIES1
           , PJO_COPIES1
           , PJO_EDIT_NAME2
           , PJO_PRINTER_NAME2
           , PJO_PRINTER_TRAY2
           , PJO_COLLATE_COPIES2
           , PJO_COPIES2
           , PJO_EDIT_NAME3
           , PJO_PRINTER_NAME3
           , PJO_PRINTER_TRAY3
           , PJO_COLLATE_COPIES3
           , PJO_COPIES3
           , PJO_EDIT_NAME4
           , PJO_PRINTER_NAME4
           , PJO_PRINTER_TRAY4
           , PJO_COLLATE_COPIES4
           , PJO_COPIES4
           , PJO_EDIT_NAME5
           , PJO_PRINTER_NAME5
           , PJO_PRINTER_TRAY5
           , PJO_COLLATE_COPIES5
           , PJO_COPIES5
           , PJO_EDIT_NAME6
           , PJO_PRINTER_NAME6
           , PJO_PRINTER_TRAY6
           , PJO_COLLATE_COPIES6
           , PJO_COPIES6
           , PJO_EDIT_NAME7
           , PJO_PRINTER_NAME7
           , PJO_PRINTER_TRAY7
           , PJO_COLLATE_COPIES7
           , PJO_COPIES7
           , PJO_EDIT_NAME8
           , PJO_PRINTER_NAME8
           , PJO_PRINTER_TRAY8
           , PJO_COLLATE_COPIES8
           , PJO_COPIES8
           , PJO_EDIT_NAME9
           , PJO_PRINTER_NAME9
           , PJO_PRINTER_TRAY9
           , PJO_COLLATE_COPIES9
           , PJO_COPIES9
           , PJO_EDIT_NAME10
           , PJO_PRINTER_NAME10
           , PJO_PRINTER_TRAY10
           , PJO_COLLATE_COPIES10
           , PJO_COPIES10
           , vCurrentDate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from DOC_PRINT_JOB
       where DOC_PRINT_JOB_ID = paPrintJobId;

    -- Copie du détail du job
    open crPrintJobDetail(paPrintJobId);

    fetch crPrintJobDetail
     into tplPrintJobDetail;

    while crPrintJobDetail%found loop
      insert into DOC_PRINT_JOB_DETAIL
                  (DOC_PRINT_JOB_DETAIL_ID
                 , DOC_DOCUMENT_ID
                 , DOC_PRINT_JOB_ID
                 , DMT_NUMBER
                 , PJD_PRINTED
                 , PJD_PRINT_DATE
                 , PJD_UPDATE_PRINTING
                 , PJD_GROUPED_PRINTING
                 , PJD_EDIT_NAME0
                 , PJD_PRINTER_NAME0
                 , PJD_PRINTER_TRAY0
                 , PJD_COLLATE_COPIES0
                 , PJD_COPY_SUPPL0
                 , PJD_COPIES0
                 , PJD_EDIT_NAME1
                 , PJD_PRINTER_NAME1
                 , PJD_PRINTER_TRAY1
                 , PJD_COLLATE_COPIES1
                 , PJD_COPY_SUPPL1
                 , PJD_COPIES1
                 , PJD_EDIT_NAME2
                 , PJD_PRINTER_NAME2
                 , PJD_PRINTER_TRAY2
                 , PJD_COLLATE_COPIES2
                 , PJD_COPY_SUPPL2
                 , PJD_COPIES2
                 , PJD_EDIT_NAME3
                 , PJD_PRINTER_NAME3
                 , PJD_PRINTER_TRAY3
                 , PJD_COLLATE_COPIES3
                 , PJD_COPY_SUPPL3
                 , PJD_COPIES3
                 , PJD_EDIT_NAME4
                 , PJD_PRINTER_NAME4
                 , PJD_PRINTER_TRAY4
                 , PJD_COLLATE_COPIES4
                 , PJD_COPY_SUPPL4
                 , PJD_COPIES4
                 , PJD_EDIT_NAME5
                 , PJD_PRINTER_NAME5
                 , PJD_PRINTER_TRAY5
                 , PJD_COLLATE_COPIES5
                 , PJD_COPY_SUPPL5
                 , PJD_COPIES5
                 , PJD_EDIT_NAME6
                 , PJD_PRINTER_NAME6
                 , PJD_PRINTER_TRAY6
                 , PJD_COLLATE_COPIES6
                 , PJD_COPY_SUPPL6
                 , PJD_COPIES6
                 , PJD_EDIT_NAME7
                 , PJD_PRINTER_NAME7
                 , PJD_PRINTER_TRAY7
                 , PJD_COLLATE_COPIES7
                 , PJD_COPY_SUPPL7
                 , PJD_COPIES7
                 , PJD_EDIT_NAME8
                 , PJD_PRINTER_NAME8
                 , PJD_PRINTER_TRAY8
                 , PJD_COLLATE_COPIES8
                 , PJD_COPY_SUPPL8
                 , PJD_COPIES8
                 , PJD_EDIT_NAME9
                 , PJD_PRINTER_NAME9
                 , PJD_PRINTER_TRAY9
                 , PJD_COLLATE_COPIES9
                 , PJD_COPY_SUPPL9
                 , PJD_COPIES9
                 , PJD_EDIT_NAME10
                 , PJD_PRINTER_NAME10
                 , PJD_PRINTER_TRAY10
                 , PJD_COLLATE_COPIES10
                 , PJD_COPY_SUPPL10
                 , PJD_COPIES10
                 , PJD_WORKSTATION
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (INIT_ID_SEQ.nextval
                 , tplPrintJobDetail.DOC_DOCUMENT_ID
                 , paNewJobId
                 , tplPrintJobDetail.DMT_NUMBER
                 , 0   -- PJD_PRINTED
                 , null   -- PJD_PRINT_DATE
                 , tplPrintJobDetail.PJD_UPDATE_PRINTING
                 , tplPrintJobDetail.PJD_GROUPED_PRINTING
                 , tplPrintJobDetail.PJD_EDIT_NAME0
                 , tplPrintJobDetail.PJD_PRINTER_NAME0
                 , tplPrintJobDetail.PJD_PRINTER_TRAY0
                 , tplPrintJobDetail.PJD_COLLATE_COPIES0
                 , tplPrintJobDetail.PJD_COPY_SUPPL0
                 , tplPrintJobDetail.PJD_COPIES0
                 , tplPrintJobDetail.PJD_EDIT_NAME1
                 , tplPrintJobDetail.PJD_PRINTER_NAME1
                 , tplPrintJobDetail.PJD_PRINTER_TRAY1
                 , tplPrintJobDetail.PJD_COLLATE_COPIES1
                 , tplPrintJobDetail.PJD_COPY_SUPPL1
                 , tplPrintJobDetail.PJD_COPIES1
                 , tplPrintJobDetail.PJD_EDIT_NAME2
                 , tplPrintJobDetail.PJD_PRINTER_NAME2
                 , tplPrintJobDetail.PJD_PRINTER_TRAY2
                 , tplPrintJobDetail.PJD_COLLATE_COPIES2
                 , tplPrintJobDetail.PJD_COPY_SUPPL2
                 , tplPrintJobDetail.PJD_COPIES2
                 , tplPrintJobDetail.PJD_EDIT_NAME3
                 , tplPrintJobDetail.PJD_PRINTER_NAME3
                 , tplPrintJobDetail.PJD_PRINTER_TRAY3
                 , tplPrintJobDetail.PJD_COLLATE_COPIES3
                 , tplPrintJobDetail.PJD_COPY_SUPPL3
                 , tplPrintJobDetail.PJD_COPIES3
                 , tplPrintJobDetail.PJD_EDIT_NAME4
                 , tplPrintJobDetail.PJD_PRINTER_NAME4
                 , tplPrintJobDetail.PJD_PRINTER_TRAY4
                 , tplPrintJobDetail.PJD_COLLATE_COPIES4
                 , tplPrintJobDetail.PJD_COPY_SUPPL4
                 , tplPrintJobDetail.PJD_COPIES4
                 , tplPrintJobDetail.PJD_EDIT_NAME5
                 , tplPrintJobDetail.PJD_PRINTER_NAME5
                 , tplPrintJobDetail.PJD_PRINTER_TRAY5
                 , tplPrintJobDetail.PJD_COLLATE_COPIES5
                 , tplPrintJobDetail.PJD_COPY_SUPPL5
                 , tplPrintJobDetail.PJD_COPIES5
                 , tplPrintJobDetail.PJD_EDIT_NAME6
                 , tplPrintJobDetail.PJD_PRINTER_NAME6
                 , tplPrintJobDetail.PJD_PRINTER_TRAY6
                 , tplPrintJobDetail.PJD_COLLATE_COPIES6
                 , tplPrintJobDetail.PJD_COPY_SUPPL6
                 , tplPrintJobDetail.PJD_COPIES6
                 , tplPrintJobDetail.PJD_EDIT_NAME7
                 , tplPrintJobDetail.PJD_PRINTER_NAME7
                 , tplPrintJobDetail.PJD_PRINTER_TRAY7
                 , tplPrintJobDetail.PJD_COLLATE_COPIES7
                 , tplPrintJobDetail.PJD_COPY_SUPPL7
                 , tplPrintJobDetail.PJD_COPIES7
                 , tplPrintJobDetail.PJD_EDIT_NAME8
                 , tplPrintJobDetail.PJD_PRINTER_NAME8
                 , tplPrintJobDetail.PJD_PRINTER_TRAY8
                 , tplPrintJobDetail.PJD_COLLATE_COPIES8
                 , tplPrintJobDetail.PJD_COPY_SUPPL8
                 , tplPrintJobDetail.PJD_COPIES8
                 , tplPrintJobDetail.PJD_EDIT_NAME9
                 , tplPrintJobDetail.PJD_PRINTER_NAME9
                 , tplPrintJobDetail.PJD_PRINTER_TRAY9
                 , tplPrintJobDetail.PJD_COLLATE_COPIES9
                 , tplPrintJobDetail.PJD_COPY_SUPPL9
                 , tplPrintJobDetail.PJD_COPIES9
                 , tplPrintJobDetail.PJD_EDIT_NAME10
                 , tplPrintJobDetail.PJD_PRINTER_NAME10
                 , tplPrintJobDetail.PJD_PRINTER_TRAY10
                 , tplPrintJobDetail.PJD_COLLATE_COPIES10
                 , tplPrintJobDetail.PJD_COPY_SUPPL10
                 , tplPrintJobDetail.PJD_COPIES10
                 , 0   --PJD_WORKSTATION
                 , vCurrentDate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      fetch crPrintJobDetail
       into tplPrintJobDetail;
    end loop;

    close crPrintJobDetail;
  end JobDuplicate;

/*************************************************************************************************************************/
  /**
  * procedure AfterPrintUnit
  */
  procedure AfterPrintUnit(
    paDmtNb      in DOC_PRINT_JOB_DETAIL.DMT_NUMBER%type
  , paPrinted    in DOC_PRINT_JOB_DETAIL.PJD_PRINTED%type
  , paGrouped    in DOC_PRINT_JOB_DETAIL.PJD_GROUPED_PRINTING%type
  , paEdtName0   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME0%type
  , paPrntName0  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME0%type
  , paPrntTray0  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY0%type
  , paCollate0   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES0%type
  , paCopies0    in DOC_PRINT_JOB_DETAIL.PJD_COPIES0%type
  , paEdtName1   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME1%type
  , paPrntName1  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME1%type
  , paPrntTray1  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY1%type
  , paCollate1   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES1%type
  , paCopies1    in DOC_PRINT_JOB_DETAIL.PJD_COPIES1%type
  , paEdtName2   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME2%type
  , paPrntName2  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME2%type
  , paPrntTray2  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY2%type
  , paCollate2   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES2%type
  , paCopies2    in DOC_PRINT_JOB_DETAIL.PJD_COPIES2%type
  , paEdtName3   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME3%type
  , paPrntName3  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME3%type
  , paPrntTray3  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY3%type
  , paCollate3   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES3%type
  , paCopies3    in DOC_PRINT_JOB_DETAIL.PJD_COPIES3%type
  , paEdtName4   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME4%type
  , paPrntName4  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME4%type
  , paPrntTray4  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY4%type
  , paCollate4   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES4%type
  , paCopies4    in DOC_PRINT_JOB_DETAIL.PJD_COPIES4%type
  , paEdtName5   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME5%type
  , paPrntName5  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME5%type
  , paPrntTray5  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY5%type
  , paCollate5   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES5%type
  , paCopies5    in DOC_PRINT_JOB_DETAIL.PJD_COPIES5%type
  , paEdtName6   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME6%type
  , paPrntName6  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME6%type
  , paPrntTray6  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY6%type
  , paCollate6   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES6%type
  , paCopies6    in DOC_PRINT_JOB_DETAIL.PJD_COPIES6%type
  , paEdtName7   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME7%type
  , paPrntName7  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME7%type
  , paPrntTray7  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY7%type
  , paCollate7   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES7%type
  , paCopies7    in DOC_PRINT_JOB_DETAIL.PJD_COPIES7%type
  , paEdtName8   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME8%type
  , paPrntName8  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME8%type
  , paPrntTray8  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY8%type
  , paCollate8   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES8%type
  , paCopies8    in DOC_PRINT_JOB_DETAIL.PJD_COPIES8%type
  , paEdtName9   in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME9%type
  , paPrntName9  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME9%type
  , paPrntTray9  in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY9%type
  , paCollate9   in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES9%type
  , paCopies9    in DOC_PRINT_JOB_DETAIL.PJD_COPIES9%type
  , paEdtName10  in DOC_PRINT_JOB_DETAIL.PJD_EDIT_NAME10%type
  , paPrntName10 in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_NAME10%type
  , paPrntTray10 in DOC_PRINT_JOB_DETAIL.PJD_PRINTER_TRAY10%type
  , paCollate10  in DOC_PRINT_JOB_DETAIL.PJD_COLLATE_COPIES10%type
  , paCopies10   in DOC_PRINT_JOB_DETAIL.PJD_COPIES10%type
  )
  is
    vDocId       DOC_PRINT_JOB_DETAIL.DOC_DOCUMENT_ID%type;
    vCurrentDate DOC_PRINT_JOB_DETAIL.PJD_PRINT_DATE%type;
  begin
    select DOC_DOCUMENT_ID
         , sysdate
      into vDocId
         , vCurrentDate
      from DOC_DOCUMENT
     where DMT_NUMBER = paDmtNb;

    insert into DOC_PRINT_JOB_DETAIL
                (DOC_PRINT_JOB_DETAIL_ID
               , DOC_DOCUMENT_ID
               , DOC_PRINT_JOB_ID
               , DMT_NUMBER
               , PJD_PRINTED
               , PJD_PRINT_DATE
               , PJD_UPDATE_PRINTING
               , PJD_GROUPED_PRINTING
               , PJD_EDIT_NAME0
               , PJD_PRINTER_NAME0
               , PJD_PRINTER_TRAY0
               , PJD_COLLATE_COPIES0
               , PJD_COPIES0
               , PJD_EDIT_NAME1
               , PJD_PRINTER_NAME1
               , PJD_PRINTER_TRAY1
               , PJD_COLLATE_COPIES1
               , PJD_COPIES1
               , PJD_EDIT_NAME2
               , PJD_PRINTER_NAME2
               , PJD_PRINTER_TRAY2
               , PJD_COLLATE_COPIES2
               , PJD_COPIES2
               , PJD_EDIT_NAME3
               , PJD_PRINTER_NAME3
               , PJD_PRINTER_TRAY3
               , PJD_COLLATE_COPIES3
               , PJD_COPIES3
               , PJD_EDIT_NAME4
               , PJD_PRINTER_NAME4
               , PJD_PRINTER_TRAY4
               , PJD_COLLATE_COPIES4
               , PJD_COPIES4
               , PJD_EDIT_NAME5
               , PJD_PRINTER_NAME5
               , PJD_PRINTER_TRAY5
               , PJD_COLLATE_COPIES5
               , PJD_COPIES5
               , PJD_EDIT_NAME6
               , PJD_PRINTER_NAME6
               , PJD_PRINTER_TRAY6
               , PJD_COLLATE_COPIES6
               , PJD_COPIES6
               , PJD_EDIT_NAME7
               , PJD_PRINTER_NAME7
               , PJD_PRINTER_TRAY7
               , PJD_COLLATE_COPIES7
               , PJD_COPIES7
               , PJD_EDIT_NAME8
               , PJD_PRINTER_NAME8
               , PJD_PRINTER_TRAY8
               , PJD_COLLATE_COPIES8
               , PJD_COPIES8
               , PJD_EDIT_NAME9
               , PJD_PRINTER_NAME9
               , PJD_PRINTER_TRAY9
               , PJD_COLLATE_COPIES9
               , PJD_COPIES9
               , PJD_EDIT_NAME10
               , PJD_PRINTER_NAME10
               , PJD_PRINTER_TRAY10
               , PJD_COLLATE_COPIES10
               , PJD_COPIES10
               , PJD_WORKSTATION
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , vDocId
               , null   -- pas de travail d'impression associé à une impression unitaire
               , paDmtNb
               , paPrinted
               , vCurrentDate
               , 1   --PJD_UPDATE_PRINTING
               , paGrouped
               , paEdtName0
               , paPrntName0
               , paPrntTray0
               , paCollate0
               , paCopies0
               , paEdtName1
               , paPrntName1
               , paPrntTray1
               , paCollate1
               , paCopies1
               , paEdtName2
               , paPrntName2
               , paPrntTray2
               , paCollate2
               , paCopies2
               , paEdtName3
               , paPrntName3
               , paPrntTray3
               , paCollate3
               , paCopies3
               , paEdtName4
               , paPrntName4
               , paPrntTray4
               , paCollate4
               , paCopies4
               , paEdtName5
               , paPrntName5
               , paPrntTray5
               , paCollate5
               , paCopies5
               , paEdtName6
               , paPrntName6
               , paPrntTray6
               , paCollate6
               , paCopies6
               , paEdtName7
               , paPrntName7
               , paPrntTray7
               , paCollate7
               , paCopies7
               , paEdtName8
               , paPrntName8
               , paPrntTray8
               , paCollate8
               , paCopies8
               , paEdtName9
               , paPrntName9
               , paPrntTray9
               , paCollate9
               , paCopies9
               , paEdtName10
               , paPrntName10
               , paPrntTray10
               , paCollate10
               , paCopies10
               , 0   --PJD_WORKSTATION
               , vCurrentDate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end AfterPrintUnit;

/*************************************************************************************************************************/
  function GetActiveReportName(pReportName in PCS.PC_REPORT.REP_REPNAME%type)
    return PCS.PC_REPORT.REP_REPNAME%type
  is
  begin
    return PCS.PC_REPORT_FUNCTIONS.GetActiveReportName(pReportName);
  end GetActiveReportName;

  /**
  * Description :
  *   Protection d'un document lié à un détail de job d'impression
  */
  procedure DocumentProtect_AutoTrans(iJobDetailId in DOC_PRINT_JOB_DETAIL.DOC_PRINT_JOB_DETAIL_ID%type, iProtect in number, oUpdated out number)
  is
    lDocumentId         DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnProtected         DOC_DOCUMENT.DMT_PROTECTED%type;
    lvConfirmFailReason DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type;
  begin
    select DMT.DOC_DOCUMENT_ID
         , DMT.DMT_PROTECTED
         , DMT.C_CONFIRM_FAIL_REASON
      into lDocumentId
         , lnProtected
         , lvConfirmFailReason
      from DOC_PRINT_JOB_DETAIL DJD
         , DOC_DOCUMENT DMT
     where DJD.DOC_PRINT_JOB_DETAIL_ID = iJobDetailId
       and DJD.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

    -- Si le document est protégé en limite de crédit, on renvoi la valeur comme quoi on a (faussement) réussi la protection du document
    -- Grâce à cette manipulation, le document pourra être imprimé même s'il est en limite de crédit ou en risque de change
    if     (lnProtected = 1)
       and (lvConfirmFailReason in('102', '130', '131', '132', '133', '134') ) then
      oUpdated  := 1;
    else
      DOC_PRC_DOCUMENT.DocumentProtect_AutoTrans(iDocumentId => lDocumentId, iProtect => iProtect, iShowError => 0, oUpdated => oUpdated);
    end if;
  end DocumentProtect_AutoTrans;

  /**
  *  procedure pExtractPrintOptions
  *  Description
  *    Extraire les options d'impression XML -> TPrintOptionList
  */
  procedure pExtractPrintOptions(iPrintOptions in clob, oGroupedPrint out DOC_PRINT_JOB.PJO_GROUPED_PRINTING%type, oPrintOptionsList out TPrintOptionList)
  is
    lIndex      integer;
    lvCharIndex varchar2(4);
    lXml        xmltype;
  begin
    lXml  := xmltype.CreateXML(iPrintOptions);

    -- Impression groupée
    select to_number(extractvalue(lXml, '*/' || 'PRT_GROUPED_PRINT' || '[1]/text()') )
      into oGroupedPrint
      from dual;

    for lIndex in 0 .. 10 loop
      lvCharIndex  := lpad(to_char(lIndex), 2, '0');

      select to_number(extractvalue(lXml, '*/PRT_' || lvCharIndex || '_PRINT[1]/text()') )
           , extractvalue(lXml, '*/PRT_' || lvCharIndex || '_FORM_NAME[1]/text()')
           , to_number(extractvalue(lXml, '*/PRT_' || lvCharIndex || '_COPIES[1]/text()') )
           , to_number(extractvalue(lXml, '*/PRT_' || lvCharIndex || '_COLLATE[1]/text()') )
           , extractvalue(lXml, '*/PRT_' || lvCharIndex || '_PRINTER_NAME[1]/text()')
           , extractvalue(lXml, '*/PRT_' || lvCharIndex || '_PRINTER_TRAY[1]/text()')
           , extractvalue(lXml, '*/PRT_' || lvCharIndex || '_PRINT_SQL[1]/text()')
        into oPrintOptionsList(lIndex)
        from dual;
    end loop;
  end pExtractPrintOptions;

  /**
  *  procedure CreatePrintJob
  *  Description
  *    Création d'un job d'impression pour plusieurs documents
  */
  procedure CreatePrintJob(oPrintJobID out number, iJobName in DOC_PRINT_JOB.PJO_NAME%type, iDocumentList in clob, iPrintOptions in clob)
  is
    lIndex            integer;
    lvCharIndex       varchar2(4);
    lvSingleQuote     varchar2(10)                              default '''';
    lvDoubleQuote     varchar2(10)                              default '''''';
    lvSQL             varchar2(32767);
    lvBasisSQL        varchar2(32767);
    lGroupedPrint     DOC_PRINT_JOB.PJO_GROUPED_PRINTING%type;
    lPrintOptionsList TPrintOptionList;
    ltPrintJob        FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    pExtractPrintOptions(iPrintOptions => iPrintOptions, oGroupedPrint => lGroupedPrint, oPrintOptionsList => lPrintOptionsList);
    -- Création de l'entete du job d'impression
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPrintJob, ltPrintJob, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPrintJob, 'PJO_NAME', iJobName);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPrintJob, 'PJO_EXECUTED', 0);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPrintJob, 'PJO_GROUPED_PRINTING', lGroupedPrint);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPrintJob, 'PJO_UPDATE_PRINTING', 1);
    FWK_I_MGT_ENTITY.InsertEntity(ltPrintJob);
    oPrintJobID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltPrintJob, 'DOC_PRINT_JOB_ID');
    FWK_I_MGT_ENTITY.Release(ltPrintJob);
    -- Construction de la commande d'insertion des documents à imprimer
    lvBasisSQL   :=
      'insert into DOC_PRINT_JOB_DETAIL ' ||
      '  (DOC_PRINT_JOB_DETAIL_ID ' ||
      ' , DOC_PRINT_JOB_ID        ' ||
      ' , DOC_DOCUMENT_ID         ' ||
      ' , DMT_NUMBER              ' ||
      ' , PJD_GROUPED_PRINTING    ' ||
      ' , PJD_UPDATE_PRINTING     ' ||
      ' , PJD_EDIT_NAME0          ' ||
      ' , PJD_PRINTER_NAME0       ' ||
      ' , PJD_PRINTER_TRAY0       ' ||
      ' , PJD_COLLATE_COPIES0     ' ||
      ' , PJD_COPIES0             ' ||
      ' , PJD_EDIT_NAME1          ' ||
      ' , PJD_PRINTER_NAME1       ' ||
      ' , PJD_PRINTER_TRAY1       ' ||
      ' , PJD_COLLATE_COPIES1     ' ||
      ' , PJD_COPIES1             ' ||
      ' , PJD_EDIT_NAME2          ' ||
      ' , PJD_PRINTER_NAME2       ' ||
      ' , PJD_PRINTER_TRAY2       ' ||
      ' , PJD_COLLATE_COPIES2     ' ||
      ' , PJD_COPIES2             ' ||
      ' , PJD_EDIT_NAME3          ' ||
      ' , PJD_PRINTER_NAME3       ' ||
      ' , PJD_PRINTER_TRAY3       ' ||
      ' , PJD_COLLATE_COPIES3     ' ||
      ' , PJD_COPIES3             ' ||
      ' , PJD_EDIT_NAME4          ' ||
      ' , PJD_PRINTER_NAME4       ' ||
      ' , PJD_PRINTER_TRAY4       ' ||
      ' , PJD_COLLATE_COPIES4     ' ||
      ' , PJD_COPIES4             ' ||
      ' , PJD_EDIT_NAME5          ' ||
      ' , PJD_PRINTER_NAME5       ' ||
      ' , PJD_PRINTER_TRAY5       ' ||
      ' , PJD_COLLATE_COPIES5     ' ||
      ' , PJD_COPIES5             ' ||
      ' , PJD_EDIT_NAME6          ' ||
      ' , PJD_PRINTER_NAME6       ' ||
      ' , PJD_PRINTER_TRAY6       ' ||
      ' , PJD_COLLATE_COPIES6     ' ||
      ' , PJD_COPIES6             ' ||
      ' , PJD_EDIT_NAME7          ' ||
      ' , PJD_PRINTER_NAME7       ' ||
      ' , PJD_PRINTER_TRAY7       ' ||
      ' , PJD_COLLATE_COPIES7     ' ||
      ' , PJD_COPIES7             ' ||
      ' , PJD_EDIT_NAME8          ' ||
      ' , PJD_PRINTER_NAME8       ' ||
      ' , PJD_PRINTER_TRAY8       ' ||
      ' , PJD_COLLATE_COPIES8     ' ||
      ' , PJD_COPIES8             ' ||
      ' , PJD_EDIT_NAME9          ' ||
      ' , PJD_PRINTER_NAME9       ' ||
      ' , PJD_PRINTER_TRAY9       ' ||
      ' , PJD_COLLATE_COPIES9     ' ||
      ' , PJD_COPIES9             ' ||
      ' , PJD_EDIT_NAME10         ' ||
      ' , PJD_PRINTER_NAME10      ' ||
      ' , PJD_PRINTER_TRAY10      ' ||
      ' , PJD_COLLATE_COPIES10    ' ||
      ' , PJD_COPIES10            ' ||
      ' , PJD_WORKSTATION         ' ||
      ' , A_DATECRE               ' ||
      ' , A_IDCRE                 ' ||
      ' )                         ' ||
      ' select INIT_ID_SEQ.nextval           ' ||
      '      , [DOC_PRINT_JOB_ID]            ' ||
      '      , [DOC_DOCUMENT_ID]             ' ||
      '      , :DMT_NUMBER                   ' ||
      '      , [PJD_GROUPED_PRINTING]        ' ||
      '      , 1 as PJD_UPDATE_PRINTING      ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_EDIT_NAME00], null))       ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_PRINTER_NAME00], null))    ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_PRINTER_TRAY00], null))    ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_COLLATE_COPIES00], null))  ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_COPIES00], null))          ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_EDIT_NAME01], null))       ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_PRINTER_NAME01], null))    ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_PRINTER_TRAY01], null))    ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_COLLATE_COPIES01], null))  ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_COPIES01], null))          ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_EDIT_NAME02], null))       ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_PRINTER_NAME02], null))    ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_PRINTER_TRAY02], null))    ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_COLLATE_COPIES02], null))  ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_COPIES02], null))          ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_EDIT_NAME03], null))       ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_PRINTER_NAME03], null))    ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_PRINTER_TRAY03], null))    ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_COLLATE_COPIES03], null))  ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_COPIES03], null))          ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_EDIT_NAME04], null))       ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_PRINTER_NAME04], null))    ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_PRINTER_TRAY04], null))    ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_COLLATE_COPIES04], null))  ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_COPIES04], null))          ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_EDIT_NAME05], null))       ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_PRINTER_NAME05], null))    ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_PRINTER_TRAY05], null))    ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_COLLATE_COPIES05], null))  ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_COPIES05], null))          ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_EDIT_NAME06], null))       ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_PRINTER_NAME06], null))    ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_PRINTER_TRAY06], null))    ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_COLLATE_COPIES06], null))  ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_COPIES06], null))          ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_EDIT_NAME07], null))       ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_PRINTER_NAME07], null))    ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_PRINTER_TRAY07], null))    ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_COLLATE_COPIES07], null))  ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_COPIES07], null))          ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_EDIT_NAME08], null))       ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_PRINTER_NAME08], null))    ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_PRINTER_TRAY08], null))    ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_COLLATE_COPIES08], null))  ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_COPIES08], null))          ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_EDIT_NAME09], null))       ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_PRINTER_NAME09], null))    ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_PRINTER_TRAY09], null))    ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_COLLATE_COPIES09], null))  ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_COPIES09], null))          ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_EDIT_NAME10], null))      ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_PRINTER_NAME10], null))   ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_PRINTER_TRAY10], null))   ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_COLLATE_COPIES10], null)) ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_COPIES10], null))         ' ||
      '      , 0                              ' ||
      '      , sysdate                        ' ||
      '      , PCS.PC_I_LIB_SESSION.GetUserIni ' ||
      '  from (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_00]) ) SQL_00 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_01]) ) SQL_01 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_02]) ) SQL_02 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_03]) ) SQL_03 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_04]) ) SQL_04 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_05]) ) SQL_05 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_06]) ) SQL_06 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_07]) ) SQL_07 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_08]) ) SQL_08 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_09]) ) SQL_09 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_10]) ) SQL_10 ';
    /* Remplacement des macros des paramètres par leur valeur respective */
    lvBasisSQL   := replace(lvBasisSQL, '[DOC_PRINT_JOB_ID]', to_char(oPrintJobID) );
    lvBasisSQL   := replace(lvBasisSQL, '[PJD_GROUPED_PRINTING]', to_char(lGroupedPrint) );

    /* Paramètres des rapports 0 à 10 */
    for lIndex in 0 .. 10 loop
      lvCharIndex  := lpad(to_char(lIndex), 2, '0');
      lvBasisSQL   := replace(lvBasisSQL, '[PJD_PRINT_' || lvCharIndex || ']', lPrintOptionsList(lIndex).PRT_PRINT);
      lvBasisSQL   :=
        replace(lvBasisSQL
              , '[PJD_EDIT_NAME' || lvCharIndex || ']'
              , lvSingleQuote || replace(lPrintOptionsList(lIndex).PRT_FORM_NAME, lvSingleQuote, lvDoubleQuote) || lvSingleQuote
               );
      lvBasisSQL   :=
        replace(lvBasisSQL
              , '[PJD_PRINTER_NAME' || lvCharIndex || ']'
              , lvSingleQuote || replace(lPrintOptionsList(lIndex).PRT_PRINTER_NAME, lvSingleQuote, lvDoubleQuote) || lvSingleQuote
               );
      lvBasisSQL   :=
        replace(lvBasisSQL
              , '[PJD_PRINTER_TRAY' || lvCharIndex || ']'
              , lvSingleQuote || replace(lPrintOptionsList(lIndex).PRT_PRINTER_TRAY, lvSingleQuote, lvDoubleQuote) || lvSingleQuote
               );
      lvBasisSQL   := replace(lvBasisSQL, '[PJD_COLLATE_COPIES' || lvCharIndex || ']', lPrintOptionsList(lIndex).PRT_COLLATE);
      lvBasisSQL   := replace(lvBasisSQL, '[PJD_COPIES' || lvCharIndex || ']', lPrintOptionsList(lIndex).PRT_COPIES);
      lvBasisSQL   := replace(lvBasisSQL, '[SQL_COMMAND_' || lvCharIndex || ']', nvl(upper(lPrintOptionsList(lIndex).PRT_PRINT_SQL), 'select 1 from dual') );
    end loop;

    /* Balayer la liste des documents créés et inserer dans la table de l'impression */
    for ltplDocument in (select   DMT.DOC_DOCUMENT_ID
                                , DMT.DMT_NUMBER
                             from DOC_DOCUMENT DMT
                                , table(idClobListToTable(iDocumentList) ) DMT_LIST
                            where DMT.DOC_DOCUMENT_ID = DMT_LIST.column_value
                         order by DMT.DMT_NUMBER asc) loop
      /* Remplacement du paramètre :DMT_NUMBER de la commande de utilisateur pour la condition d'impression */
      lvSQL  := replace(lvBasisSQL, ':DMT_NUMBER', lvSingleQuote || replace(ltplDocument.DMT_NUMBER, lvSingleQuote, lvDoubleQuote) || lvSingleQuote);
      /* Remplacement du paramètre [DOC_DOCUMENT_ID] */
      lvSQL  := replace(lvSQL, '[DOC_DOCUMENT_ID]', to_char(ltplDocument.DOC_DOCUMENT_ID) );

      execute immediate lvSQL;
    end loop;

    -- Effacer le job d'impression si pas de documents à imprimer
    declare
      lCount integer;
    begin
      -- Nbr de documents à imprimer
      select count(DOC_PRINT_JOB_DETAIL_ID)
        into lCount
        from DOC_PRINT_JOB_DETAIL
       where DOC_PRINT_JOB_ID = oPrintJobID;

      if lCount = 0 then
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPrintJob, ltPrintJob);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPrintJob, 'DOC_PRINT_JOB_ID', oPrintJobID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltPrintJob);
        FWK_I_MGT_ENTITY.Release(ltPrintJob);
        oPrintJobID  := null;
      end if;
    end;
  end CreatePrintJob;
end DOC_BATCH_PRINT;
