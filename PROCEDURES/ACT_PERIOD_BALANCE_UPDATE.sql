--------------------------------------------------------
--  DDL for Procedure ACT_PERIOD_BALANCE_UPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "ACT_PERIOD_BALANCE_UPDATE" (aFYE_NO_EXERCICE ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type,
                                                      aJOU_NUMBER      ACT_JOURNAL.JOU_NUMBER%type)
/**
* Description
*
* @lastUpdate
* @version DEVELOP
* @public
* @param aFYE_NO_EXERCICE
* @param aJOU_NUMBER
*/
is
  ---------------------
  function IsToTransfer(aACT_JOURNAL_ID ACT_JOURNAL.ACT_JOURNAL_ID%type)
    return number
  is
    Result    number := 0;
    JournalId ACT_JOURNAL.ACT_JOURNAL_ID%type;

  begin
    begin
      select ACT_JOURNAL_ID into JournalId
        from ACT_PERIOD_BALANCE_COLL
        where ACT_JOURNAL_ID = aACT_JOURNAL_ID;
    exception
      when TOO_MANY_ROWS then
        Result := 0;
      when NO_DATA_FOUND then
        Result := 1;
    end;
    return Result;
  end IsToTransfer;

  -------------------------
  procedure JournalTransfer(aACT_JOURNAL_ID ACT_JOURNAL.ACT_JOURNAL_ID%type)
  is
    cursor JournalImputationsCursor(aACT_JOURNAL_ID ACT_JOURNAL.ACT_JOURNAL_ID%type) is
      select IMP.ACS_FINANCIAL_ACCOUNT_ID,
             IMP.ACS_PERIOD_ID,
             IMP2.ACS_PERIOD_ID ACS2_PERIOD_ID,
             CAT.ACJ_CATALOGUE_DOCUMENT_ID,
             CAT2.ACJ_CATALOGUE_DOCUMENT_ID ACJ2_CATALOGUE_DOCUMENT_ID,
             IMP.ACS_FINANCIAL_CURRENCY_ID,
             count(*) NUMBER_OF_DOCUMENT,
             sum(IMP.IMF_AMOUNT_LC_D)  IMF_AMOUNT_LC_D,
             sum(IMP.IMF_AMOUNT_LC_C)  IMF_AMOUNT_LC_C,
             sum(IMP.IMF_AMOUNT_FC_D)  IMF_AMOUNT_FC_D,
             sum(IMP.IMF_AMOUNT_FC_C)  IMF_AMOUNT_FC_C,
             sum(IMP.IMF_AMOUNT_EUR_D) IMF_AMOUNT_EUR_D,
             sum(IMP.IMF_AMOUNT_EUR_C) IMF_AMOUNT_EUR_C
        from
             ACT_FINANCIAL_IMPUTATION IMP2,
             ACJ_CATALOGUE_DOCUMENT   CAT2,
             ACT_DOCUMENT             DOC2,
             ACT_EXPIRY               EXP,
             ACT_DET_PAYMENT          DET,
             ACJ_CATALOGUE_DOCUMENT   CAT,
             ACS_FINANCIAL_ACCOUNT    FIN,
             ACT_FINANCIAL_IMPUTATION IMP,
             ACT_DOCUMENT             DOC,
             ACT_JOURNAL              JOU
        where JOU.ACT_JOURNAL_ID             = aACT_JOURNAL_ID
          and JOU.ACT_JOB_ID                 = DOC.ACT_JOB_ID
          and DOC.ACT_DOCUMENT_ID            = IMP.ACT_DOCUMENT_ID
          and IMP.ACS_FINANCIAL_ACCOUNT_ID   = FIN.ACS_FINANCIAL_ACCOUNT_ID
          and FIN.FIN_COLLECTIVE             = 1
          and DOC.ACJ_CATALOGUE_DOCUMENT_ID  = CAT.ACJ_CATALOGUE_DOCUMENT_ID
          and IMP.ACT_DET_PAYMENT_ID         = DET.ACT_DET_PAYMENT_ID(+)
          and DET.ACT_EXPIRY_ID              = EXP.ACT_EXPIRY_ID(+)
          and EXP.ACT_DOCUMENT_ID            = DOC2.ACT_DOCUMENT_ID(+)
          and DOC2.ACJ_CATALOGUE_DOCUMENT_ID = CAT2.ACJ_CATALOGUE_DOCUMENT_ID(+)
          and DOC2.ACT_DOCUMENT_ID           = IMP2.ACT_DOCUMENT_ID(+)
          and nvl(IMP2.IMF_PRIMARY, 1)       = 1
        group by IMP.ACS_FINANCIAL_ACCOUNT_ID,
                 IMP.ACS_PERIOD_ID,
                 IMP2.ACS_PERIOD_ID,
                 CAT.ACJ_CATALOGUE_DOCUMENT_ID,
                 CAT2.ACJ_CATALOGUE_DOCUMENT_ID,
                 IMP.ACS_FINANCIAL_CURRENCY_ID;

    ImputationRow JournalImputationsCursor%rowtype;
  -----
  begin
    open JournalImputationsCursor(aACT_JOURNAL_ID);
    fetch JournalImputationsCursor into ImputationRow;
    while JournalImputationsCursor%found loop
      insert into ACT_PERIOD_BALANCE_COLL
        (ACT_PERIOD_BALANCE_COLL_ID,
         ACT_JOURNAL_ID,
         ACS_FINANCIAL_ACCOUNT_ID,
         ACS_PERIOD_ID,
         ACS2_PERIOD_ID,
         ACJ_CATALOGUE_DOCUMENT_ID,
         ACJ2_CATALOGUE_DOCUMENT_ID,
         ACS_FINANCIAL_CURRENCY_ID,
         NUMBER_OF_DOCUMENT,
         IMF_AMOUNT_LC_D,
         IMF_AMOUNT_LC_C,
         IMF_AMOUNT_FC_D,
         IMF_AMOUNT_FC_C,
         IMF_AMOUNT_EUR_D,
         IMF_AMOUNT_EUR_C)
      values
        (INIT_ID_SEQ.nextval,
         aACT_JOURNAL_ID,
         ImputationRow.ACS_FINANCIAL_ACCOUNT_ID,
         ImputationRow.ACS_PERIOD_ID,
         ImputationRow.ACS2_PERIOD_ID,
         ImputationRow.ACJ_CATALOGUE_DOCUMENT_ID,
         ImputationRow.ACJ2_CATALOGUE_DOCUMENT_ID,
         ImputationRow.ACS_FINANCIAL_CURRENCY_ID,
         ImputationRow.NUMBER_OF_DOCUMENT,
         ImputationRow.IMF_AMOUNT_LC_D,
         ImputationRow.IMF_AMOUNT_LC_C,
         ImputationRow.IMF_AMOUNT_FC_D,
         ImputationRow.IMF_AMOUNT_FC_C,
         ImputationRow.IMF_AMOUNT_EUR_D,
         ImputationRow.IMF_AMOUNT_EUR_C);
      fetch JournalImputationsCursor into ImputationRow;
    end loop;
    close JournalImputationsCursor;
  end JournalTransfer;

-----
begin
  for Journal in (select JOU.ACT_JOURNAL_ID
                    from ACT_ETAT_JOURNAL   ETA,
                         ACT_JOURNAL        JOU,
                         ACS_FINANCIAL_YEAR YEA
                    where ((YEA.FYE_NO_EXERCICE       = aFYE_NO_EXERCICE) or aFYE_NO_EXERCICE is null)
                      and   YEA.ACS_FINANCIAL_YEAR_ID = JOU.ACS_FINANCIAL_YEAR_ID
                      and ((JOU.JOU_NUMBER            = aJOU_NUMBER) or aJOU_NUMBER is null)
                      and   JOU.ACT_JOURNAL_ID        = ETA.ACT_JOURNAL_ID
                      and   ETA.C_SUB_SET             = 'ACC'
                      and   ETA.C_ETAT_JOURNAL        = 'DEF') loop
    if IsToTransfer(Journal.ACT_JOURNAL_ID) = 1 then
      JournalTransfer(Journal.ACT_JOURNAL_ID);
	  commit;
    end if;
  end loop;
end ACT_PERIOD_BALANCE_UPDATE;
