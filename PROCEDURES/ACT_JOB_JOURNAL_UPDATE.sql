--------------------------------------------------------
--  DDL for Procedure ACT_JOB_JOURNAL_UPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "ACT_JOB_JOURNAL_UPDATE" (aFYE_NO_EXERCICE ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type,
                                                   aJOU_NUMBER      ACT_JOURNAL.JOU_NUMBER%type)
/**
* Description
*
* @lastUpdate
* @version 2003
* @public
* @param aFYE_NO_EXERCICE
* @param aJOU_NUMBER
*/
is
  JournalId ACT_JOURNAL.ACT_JOURNAL_ID%type;
  JobId     ACT_JOURNAL.ACT_JOB_ID%type;
  Integrate ACJ_JOB_TYPE.C_ACI_FINANCIAL_LINK%type;

-----
begin
  -- Recherche info journal Financier
  begin
    select JOU.ACT_JOURNAL_ID,
          JOU.ACT_JOB_ID,
          TYP.C_ACI_FINANCIAL_LINK into JournalId, JobId, Integrate
      from ACS_ACCOUNTING     ACC,
          ACJ_JOB_TYPE       TYP,
          ACT_JOB            JOB,
          ACT_JOURNAL        JOU,
          ACS_FINANCIAL_YEAR YEA
        where YEA.FYE_NO_EXERCICE       = aFYE_NO_EXERCICE
          and YEA.ACS_FINANCIAL_YEAR_ID = JOU.ACS_FINANCIAL_YEAR_ID
          and JOU.ACT_JOB_ID            = JOB.ACT_JOB_ID
          and JOU.ACS_ACCOUNTING_ID     = ACC.ACS_ACCOUNTING_ID
          and TYP.ACJ_JOB_TYPE_ID       = JOB.ACJ_JOB_TYPE_ID
          and ACC.C_TYPE_ACCOUNTING     = 'FIN'
          and JOU.JOU_NUMBER            = aJOU_NUMBER
          and JOB.C_JOB_STATE           = 'DEF';
  exception
    when NO_DATA_FOUND then
      JobId := null;
  end;

  -- Recherche info journal Analytique
  if JobId is null then
    begin
      select JOU.ACT_JOURNAL_ID,
            JOU.ACT_JOB_ID,
            TYP.C_ACI_FINANCIAL_LINK into JournalId, JobId, Integrate
        from ACS_ACCOUNTING     ACC,
            ACJ_JOB_TYPE       TYP,
            ACT_JOB            JOB,
            ACT_JOURNAL        JOU,
            ACS_FINANCIAL_YEAR YEA
          where YEA.FYE_NO_EXERCICE       = aFYE_NO_EXERCICE
            and YEA.ACS_FINANCIAL_YEAR_ID = JOU.ACS_FINANCIAL_YEAR_ID
            and JOU.ACT_JOB_ID            = JOB.ACT_JOB_ID
            and JOU.ACS_ACCOUNTING_ID     = ACC.ACS_ACCOUNTING_ID
            and TYP.ACJ_JOB_TYPE_ID       = JOB.ACJ_JOB_TYPE_ID
            and ACC.C_TYPE_ACCOUNTING     = 'MAN'
            and JOU.JOU_NUMBER            = aJOU_NUMBER
            and JOB.C_JOB_STATE           = 'DEF';
    exception
      when NO_DATA_FOUND then
        JobId := null;
    end;
  end if;

  if JobId is null then
    raise_application_error(-20000, 'PCS - procedure ACT_JOB_JOURNAL_UPDATE - Journal not found !');
  end if;

  update ACT_JOB
    set C_JOB_STATE = decode(Integrate, 1, 'PEND', 'FINT')
    where ACT_JOB_ID = JobId;

  update ACT_ETAT_JOURNAL
    set C_ETAT_JOURNAL = 'PROV'
    where ACT_JOURNAL_ID in (select ACT_JOURNAL_ID
	                           from ACT_JOURNAL
                               where ACT_JOB_ID = JobId);

  delete from ACT_PERIOD_BALANCE_COLL
    where ACT_JOURNAL_ID = JournalId;

  commit;

end ACT_JOB_JOURNAL_UPDATE;
