--------------------------------------------------------
--  DDL for Package Body ACT_LIB_DEFERRAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_LIB_DEFERRAL" 
is
  /**
   * function HasDefImpNextTaxYear
   * description :
   *    Détermine si un document possède des imputations lissées sur l'excercice
   *    suivant.
   */
  function HasDefImpNextTaxYear(in_ActDeferDocId in ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return integer
  is
    ln_result integer;
  begin
    --Il peut y avoir deux documents pour le même compte, même dates de transaction et même dates de lissage
    for tpl in (select distinct DEF.ACT_FINANCIAL_IMPUTATION_ID
                  , DOC.ACT_JOB_ID
               from ACT_FINANCIAL_IMPUTATION IMP
                  , ACT_DOCUMENT DOC
                  , ACT_DEFERRAL_IMPUTATION DEF
              where IMP.ACT_DOCUMENT_ID = in_ActDeferDocId
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DEF.ACT_DEFER_FIN_IMP_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) loop

      select sign(count(*) )
        into ln_result
        from ACT_DEFERRAL_IMPUTATION DEF
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_JOB JOB
           , ACT_DOCUMENT DOC
       where IMP.ACT_FINANCIAL_IMPUTATION_ID = DEF.ACT_DEFER_FIN_IMP_ID
         and DEF.ACT_FINANCIAL_IMPUTATION_ID = tpl.ACT_FINANCIAL_IMPUTATION_ID
         and IMP.IMF_PRIMARY = 1
         and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and JOB.ACT_JOB_ID = DOC.ACT_JOB_ID
         and JOB.ACS_FINANCIAL_YEAR_ID = (select ACS_FINANCIAL_YEAR_FCT.GetNextFinancialYearID(JOB.ACS_FINANCIAL_YEAR_ID)
                                            from ACT_JOB JOB
                                           where JOB.ACT_JOB_ID = tpl.ACT_JOB_ID);
      if ln_result > 0 then
        return ln_result;
      end if;
    end loop;

    return ln_result;
  exception
    -- si le document n'est pas lissé
    when no_data_found then
      return 0;
  end HasDefImpNextTaxYear;
end ACT_LIB_DEFERRAL;
