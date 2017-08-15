--------------------------------------------------------
--  DDL for Package Body ACT_JOURNAL_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_JOURNAL_MANAGEMENT" 
is
  -------------------------

  procedure CreateJournals(aACT_JOURNAL_ID              out ACT_JOURNAL.ACT_JOURNAL_ID%type,
                           aACT_ACT_JOURNAL_ID          out ACT_JOURNAL.ACT_JOURNAL_ID%type,
                           aACT_JOB_ID                  in ACT_JOB.ACT_JOB_ID%type,
                           aACJ_CATALOGUE_DOCUMENT_ID   in ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                           aC_TYPE_JOURNAL              in ACT_JOURNAL.C_TYPE_JOURNAL%type := 'MAN',
                           aJOU_DESCRIPTION             in ACT_JOURNAL.JOU_DESCRIPTION%type := null)
  is
    journal_id ACT_JOURNAL.ACT_JOURNAL_ID%type;
    description ACT_JOURNAL.JOU_DESCRIPTION%type := aJOU_DESCRIPTION;
  begin
    for tpl_journal in
          (select distinct ACS_ACCOUNTING.C_TYPE_ACCOUNTING
                        , ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                        , ACT_JOB.ACS_FINANCIAL_YEAR_ID
                        , ACT_JOB.JOB_DESCRIPTION
                        , ACT_JOURNAL.ACT_JOURNAL_ID
                    from ACT_JOURNAL
                        , ACT_JOB
                        , ACS_SUB_SET
                        , ACJ_SUB_SET_CAT
                        , ACS_ACCOUNTING
                    where ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
                      and ACS_SUB_SET.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                      and ACT_JOB.ACT_JOB_ID = aACT_JOB_ID
                      and ACT_JOURNAL.ACS_ACCOUNTING_ID(+) = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACT_JOURNAL.ACT_JOB_ID(+) = aACT_JOB_ID
                    order by ACS_ACCOUNTING.C_TYPE_ACCOUNTING) loop

      journal_id := tpl_journal.ACT_JOURNAL_ID;

      -- Si le journal n'existe pas pour le type de compta. -> création
      if journal_id is null then

        insert into ACT_JOURNAL
                    (ACT_JOURNAL_ID
                  , ACT_JOB_ID
                  , C_TYPE_JOURNAL
                  , ACS_ACCOUNTING_ID
                  , JOU_DESCRIPTION
                  , JOU_NUMBER
                  , PC_USER_ID
                  , ACS_FINANCIAL_YEAR_ID
                  , A_DATECRE
                  , A_IDCRE
                    )
            values (INIT_ID_SEQ.NEXTVAL
                  , aACT_JOB_ID
                  , aC_TYPE_JOURNAL
                  , tpl_journal.ACS_ACCOUNTING_ID
                  , nvl(aJOU_DESCRIPTION, tpl_journal.JOB_DESCRIPTION)
                  , null
                  , PCS.PC_I_LIB_SESSION.GetUserId2
                  , tpl_journal.ACS_FINANCIAL_YEAR_ID
                  , sysdate
                  , PCS.PC_I_LIB_SESSION.GetUserIni2
                    ) returning ACT_JOURNAL_ID into journal_id;
      end if;

      -- Reprise des IDs des journaux pour retour de la fonction
      if tpl_journal.C_TYPE_ACCOUNTING = 'FIN' then
        aACT_JOURNAL_ID := journal_id;
      else
        aACT_ACT_JOURNAL_ID := journal_id;
      end if;

    end loop;

  end CreateJournals;

  -------------------------

  procedure CreateEtatJournals(aACT_JOB_ID                  in ACT_JOB.ACT_JOB_ID%type,
                               aACJ_CATALOGUE_DOCUMENT_ID   in ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                               aUpdateState                 in boolean := False)
  is
    etat_journal_id ACT_ETAT_JOURNAL.ACT_ETAT_JOURNAL_ID%type;
  begin
    for tpl_etat_journal in
          (select distinct ACJ_SUB_SET_CAT.C_METHOD_CUMUL
                        , ACJ_SUB_SET_CAT.C_SUB_SET
                        , ACT_JOURNAL.ACT_JOURNAL_ID
                    from ACT_JOURNAL
                        , ACS_SUB_SET
                        , ACJ_SUB_SET_CAT
                        , ACS_ACCOUNTING
                    where ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
                      and ACS_SUB_SET.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                      and ACT_JOURNAL.ACS_ACCOUNTING_ID(+) = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACT_JOURNAL.ACT_JOB_ID(+) = aACT_JOB_ID
                order by ACJ_SUB_SET_CAT.C_SUB_SET) loop

      -- Si un journal existe
      if tpl_etat_journal.ACT_JOURNAL_ID is not null then
        -- Recherche si l'état journal existe déjà
        select min(ACT_ETAT_JOURNAL_ID)
          into etat_journal_id
          from ACT_ETAT_JOURNAL
        where ACT_JOURNAL_ID = tpl_etat_journal.ACT_JOURNAL_ID
          and C_SUB_SET = tpl_etat_journal.C_SUB_SET;

        if etat_journal_id is null then
          -- Insertion de l'état journal pour le sous-ensemble
          insert into ACT_ETAT_JOURNAL
                      (ACT_ETAT_JOURNAL_ID
                    , ACT_JOURNAL_ID
                    , C_SUB_SET
                    , A_DATECRE
                    , A_IDCRE
                    , C_ETAT_JOURNAL
                      )
              values (INIT_ID_SEQ.nextval
                    , tpl_etat_journal.ACT_JOURNAL_ID
                    , tpl_etat_journal.C_SUB_SET
                    , sysdate
                    , PCS.PC_I_LIB_SESSION.GetUserIni2
                    , decode(tpl_etat_journal.C_METHOD_CUMUL, 'DIR', 'PROV', 'BRO')
                      );
        elsif aUpdateState then
          -- Màj de l'état journal pour le sous-ensemble si Flag UpdateState seulement
          update ACT_ETAT_JOURNAL
            set C_ETAT_JOURNAL = decode(tpl_etat_journal.C_METHOD_CUMUL, 'DIR', 'PROV', 'BRO')
          where ACT_ETAT_JOURNAL_ID = etat_journal_id;
        end if;
      end if;
    end loop;
  end CreateEtatJournals;

  -------------------------

  procedure UpdateDocuments(aACT_JOB_ID           in ACT_JOB.ACT_JOB_ID%type,
                            aACT_DOCUMENT_ID  in ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                            aACT_JOURNAL_ID              in ACT_JOURNAL.ACT_JOURNAL_ID%type := null,
                            aACT_ACT_JOURNAL_ID          in ACT_JOURNAL.ACT_JOURNAL_ID%type := null)
  is
    fin_journal_id  ACT_JOURNAL.ACT_JOURNAL_ID%type := aACT_JOURNAL_ID;
    man_journal_id  ACT_JOURNAL.ACT_JOURNAL_ID%type := aACT_ACT_JOURNAL_ID;
  begin
    -- Recherche des IDs des journaux si ils ne sont pas passé en param.
    if (fin_journal_id is null) and (man_journal_id is null) then
      if aACT_JOB_ID is not null then

        select min(ACT_JOURNAL.ACT_JOURNAL_ID)
          into fin_journal_id
          from ACT_JOURNAL
            , ACS_ACCOUNTING
        where ACT_JOURNAL.ACT_JOB_ID = aACT_JOB_ID
          and ACT_JOURNAL.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
          and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'FIN';

        select min(ACT_JOURNAL.ACT_JOURNAL_ID)
          into man_journal_id
          from ACT_JOURNAL
            , ACS_ACCOUNTING
        where ACT_JOURNAL.ACT_JOB_ID = aACT_JOB_ID
          and ACT_JOURNAL.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
          and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'MAN';

      elsif aACT_DOCUMENT_ID is not null then

        select min(ACT_JOURNAL.ACT_JOURNAL_ID)
          into fin_journal_id
          from ACT_JOURNAL
            , ACT_DOCUMENT
            , ACS_ACCOUNTING
        where ACT_DOCUMENT.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
          and ACT_JOURNAL.ACT_JOB_ID = ACT_DOCUMENT.ACT_JOB_ID
          and ACT_JOURNAL.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
          and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'FIN';

        select min(ACT_JOURNAL.ACT_JOURNAL_ID)
          into man_journal_id
          from ACT_JOURNAL
            , ACT_DOCUMENT
            , ACS_ACCOUNTING
        where ACT_DOCUMENT.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
          and ACT_JOURNAL.ACT_JOB_ID = ACT_DOCUMENT.ACT_JOB_ID
          and ACT_JOURNAL.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
          and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'MAN';

      end if;
    end if;

    -- Màj des IDs des journaux dans les documents
    if (fin_journal_id is not null) or (man_journal_id is not null) then
      if aACT_DOCUMENT_ID is not null then

        if aACT_JOURNAL_ID is not null then
          update ACT_DOCUMENT
            set ACT_JOURNAL_ID = fin_journal_id
          where ACT_DOCUMENT.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
            and exists(
                  select 0
                    from ACS_SUB_SET
                        , ACJ_SUB_SET_CAT
                        , ACS_ACCOUNTING
                        , ACT_DOCUMENT ACT_DOCUMENT2
                    where ACT_DOCUMENT2.ACT_DOCUMENT_ID = ACT_DOCUMENT.ACT_DOCUMENT_ID
                      and ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT2.ACJ_CATALOGUE_DOCUMENT_ID
                      and ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
                      and ACS_SUB_SET.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'FIN'
                      and rownum = 1);
        end if;

        if aACT_ACT_JOURNAL_ID is not null then
          update ACT_DOCUMENT
            set ACT_ACT_JOURNAL_ID = man_journal_id
          where ACT_DOCUMENT.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
            and exists(
                  select 0
                    from ACS_SUB_SET
                        , ACJ_SUB_SET_CAT
                        , ACS_ACCOUNTING
                        , ACT_DOCUMENT ACT_DOCUMENT2
                    where ACT_DOCUMENT2.ACT_DOCUMENT_ID = ACT_DOCUMENT.ACT_DOCUMENT_ID
                      and ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT2.ACJ_CATALOGUE_DOCUMENT_ID
                      and ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
                      and ACS_SUB_SET.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'MAN'
                      and rownum = 1);
        end if;

      elsif aACT_JOB_ID is not null then
        if aACT_JOURNAL_ID is not null then
          update ACT_DOCUMENT
            set ACT_JOURNAL_ID = fin_journal_id
          where ACT_DOCUMENT.ACT_JOB_ID = aACT_JOB_ID
            and exists(
                  select 0
                    from ACS_SUB_SET
                        , ACJ_SUB_SET_CAT
                        , ACS_ACCOUNTING
                        , ACT_DOCUMENT ACT_DOCUMENT2
                    where ACT_DOCUMENT2.ACT_DOCUMENT_ID = ACT_DOCUMENT.ACT_DOCUMENT_ID
                      and ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT2.ACJ_CATALOGUE_DOCUMENT_ID
                      and ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
                      and ACS_SUB_SET.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'FIN'
                      and rownum = 1);
        end if;

        if aACT_ACT_JOURNAL_ID is not null then
          update ACT_DOCUMENT
            set ACT_ACT_JOURNAL_ID = man_journal_id
          where ACT_DOCUMENT.ACT_JOB_ID = aACT_JOB_ID
            and exists(
                  select 0
                    from ACS_SUB_SET
                        , ACJ_SUB_SET_CAT
                        , ACS_ACCOUNTING
                        , ACT_DOCUMENT ACT_DOCUMENT2
                    where ACT_DOCUMENT2.ACT_DOCUMENT_ID = ACT_DOCUMENT.ACT_DOCUMENT_ID
                      and ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT2.ACJ_CATALOGUE_DOCUMENT_ID
                      and ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
                      and ACS_SUB_SET.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                      and ACS_ACCOUNTING.C_TYPE_ACCOUNTING = 'MAN'
                      and rownum = 1);
        end if;
      end if;
    end if;

  end UpdateDocuments;

  -------------------------

  procedure ProcessJournals(aACT_JOB_ID                  in ACT_JOB.ACT_JOB_ID%type,
                            aACJ_CATALOGUE_DOCUMENT_ID   in ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                            aC_TYPE_JOURNAL              in ACT_JOURNAL.C_TYPE_JOURNAL%type := 'MAN',
                            aJOU_DESCRIPTION             in ACT_JOURNAL.JOU_DESCRIPTION%type := null,
                            aAssignNumber                in Boolean := True)
  is
    fin_journal_id  ACT_JOURNAL.ACT_JOURNAL_ID%type;
    man_journal_id  ACT_JOURNAL.ACT_JOURNAL_ID%type;
  begin
    CreateJournals(fin_journal_id,
                    man_journal_id,
                    aACT_JOB_ID,
                    aACJ_CATALOGUE_DOCUMENT_ID,
                    aC_TYPE_JOURNAL,
                    aJOU_DESCRIPTION);

    CreateEtatJournals(aACT_JOB_ID,
                       aACJ_CATALOGUE_DOCUMENT_ID);

    UpdateDocuments(aACT_JOB_ID,
                   null,
                   fin_journal_id,
                   man_journal_id);

    if aAssignNumber then
      UpdateJournalsNumber(aACT_JOB_ID);
    end if;
  end ProcessJournals;

  -------------------------

  procedure UpdateEtatJournalsState(aACT_JOB_ID                  in ACT_JOB.ACT_JOB_ID%type,
                                    aACJ_CATALOGUE_DOCUMENT_ID   in ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)

  is
  begin
    CreateEtatJournals(aACT_JOB_ID,
                       aACJ_CATALOGUE_DOCUMENT_ID,
                       True);
  end UpdateEtatJournalsState;

  -------------------------

  procedure UpdateJournalsNumber(aACT_JOB_ID  in ACT_JOB.ACT_JOB_ID%type)
  is
    retry integer := 0;
  begin
    for tpl_journal in
            (select ACT_JOURNAL_ID
                , ACS_ACCOUNTING_ID
                , ACS_FINANCIAL_YEAR_ID
              from ACT_JOURNAL
            where ACT_JOB_ID = aACT_JOB_ID
              and JOU_NUMBER is null) loop
      loop
        begin
          update ACT_JOURNAL
            set JOU_NUMBER = (select nvl(max(JOU_NUMBER), 0) + 1
                                from ACT_JOURNAL
                                where ACS_ACCOUNTING_ID = tpl_journal.ACS_ACCOUNTING_ID
                                  and ACS_FINANCIAL_YEAR_ID = tpl_journal.ACS_FINANCIAL_YEAR_ID)
          where ACT_JOURNAL_ID = tpl_journal.ACT_JOURNAL_ID;

          exit;
        exception
          when DUP_VAL_ON_INDEX then
            retry := retry + 1;
            if retry = 10 then
              raise;
            end if;
        end;
      end loop;
    end loop;

  end UpdateJournalsNumber;

  -------------------------

end ACT_JOURNAL_MANAGEMENT;
