--------------------------------------------------------
--  DDL for Package Body ACS_FINANCIAL_YEAR_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_FINANCIAL_YEAR_FCT" 
is
  /**
  * Description
  *    Renvoie l'�tat de l'exercice qui pr�c�de l'exercice comptable pass� en param�tre
  */
  function GetStatePreviousFinancialYear(aACS_FINANCIAL_YEAR_ID in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type
  is
    State ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;
  begin
    begin
      select   A.C_STATE_FINANCIAL_YEAR
          into State
          from ACS_FINANCIAL_YEAR A
             , ACS_FINANCIAL_YEAR B
         where A.FYE_NO_EXERCICE =(B.FYE_NO_EXERCICE - 1)
           and B.FYE_START_DATE =(A.FYE_END_DATE + 1)
           and B.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
      order by A.FYE_START_DATE asc
             , A.FYE_END_DATE asc
             , B.FYE_START_DATE asc
             , B.FYE_END_DATE;
    exception
      when no_data_found then
        State  := null;
    end;

    return State;
  end GetStatePreviousFinancialYear;

  /**
  * Description
  *   Renvoie l'id de l'ann�e financiere pr�c�dente de celle envoy�e
  */
  function GetPreviousFinancialYearID(aACS_FINANCIAL_YEAR_ID in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
    idFinancialYear ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    begin
      select   A.ACS_FINANCIAL_YEAR_ID
          into idFinancialYear
          from ACS_FINANCIAL_YEAR A
             , ACS_FINANCIAL_YEAR B
         where B.FYE_START_DATE =(A.FYE_END_DATE + 1)
           and B.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
      order by A.FYE_START_DATE asc
             , A.FYE_END_DATE asc
             , B.FYE_START_DATE asc
             , B.FYE_END_DATE;
    exception
      when no_data_found then
        idFinancialYear  := null;
    end;

    return idFinancialYear;
  end GetPreviousFinancialYearID;

  /**
  * Description
  *   Renvoie l'id de l'ann�e financiere suivante de celle envoy�e
  */
  function GetNextFinancialYearID(aACS_FINANCIAL_YEAR_ID in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
    idFinancialYear ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    begin
      select   A.ACS_FINANCIAL_YEAR_ID
          into idFinancialYear
          from ACS_FINANCIAL_YEAR A
             , ACS_FINANCIAL_YEAR B
         where B.FYE_END_DATE =(A.FYE_START_DATE - 1)
           and B.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
      order by A.FYE_START_DATE desc
             , A.FYE_END_DATE desc
             , B.FYE_START_DATE desc
             , B.FYE_END_DATE desc;
    exception
      when no_data_found then
        idFinancialYear  := null;
    end;

    return idFinancialYear;
  end GetNextFinancialYearID;

  /**
  * Description
  *   Renvoie la date d�but ou fin de l'exercice donn�
  **/
  function GetFinYearDateById(pExerciceId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type, pType in number)
    return ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  is
    vResult ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    select decode(pType, 0, FYE_START_DATE, 1, FYE_END_DATE)
      into vResult
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = pExerciceId;

    return vResult;
  end GetFinYearDateById;

  /**
  *   Renvoie la date d�but ou fin selon param�tre de l'exercice donn�
  **/
  function GetFinYearIdByDate(pRefDate in ACS_FINANCIAL_YEAR.FYE_START_DATE%type)
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
    vResult ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    select nvl(max(ACS_FINANCIAL_YEAR_ID), 0)
      into vResult
      from ACS_FINANCIAL_YEAR
     where pRefDate between FYE_START_DATE and FYE_END_DATE;

    return vResult;
  end GetFinYearIdByDate;

  /**
  *  Num�ro exercice de l'exercice pass� en param�tre ou le + �lev� si
  *  ce dernier n'est pas renseign�
  **/
  function GetFinYearNoById(pFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type default null)
    return ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  is
    cursor FinancialYearCursor
    is
      select   FYE_NO_EXERCICE
          from ACS_FINANCIAL_YEAR
      order by FYE_NO_EXERCICE desc;

    vResult ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
  begin
    /**
    *  Num�ro exercice de l'exercice pass� en param�tre ou le + �lev� si
    *  ce dernier n'est pas renseign�
    **/
    if pFinancialYearId is null then
      open FinancialYearCursor;

      fetch FinancialYearCursor
       into vResult;

      close FinancialYearCursor;
    else
      select FYE_NO_EXERCICE
        into vResult
        from ACS_FINANCIAL_YEAR
       where ACS_FINANCIAL_YEAR_ID = pFinancialYearId;
    end if;

    return vResult;
  end GetFinYearNoById;

  function GetLastYearNo(pGreatest in number)
    return ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  is
    vResult ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
  begin
    select decode(pGreatest, 0, min(FYE_NO_EXERCICE), max(FYE_NO_EXERCICE) )
      into vResult
      from ACS_FINANCIAL_YEAR;

    return vResult;
  end GetLastYearNo;

  /**
  * Return exercise start date (end date) according the parameter (0 or 1)
  **/
  function GetExerciseDate(pFinancialYearNo ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type, pStartDate number)
    return ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  is
    vResult ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    select decode(pStartDate, 0, FYE_END_DATE, FYE_START_DATE)
      into vResult
      from ACS_FINANCIAL_YEAR
     where FYE_NO_EXERCICE = pFinancialYearNo;

    return vResult;
  end GetExerciseDate;

  /**
  *  Cr�ation d'un exercice financier sur la base du n� exercice,
  *  dates et description
  **/
  procedure DuplicateFinancialYear(
    pSourceFinYearId  in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pExerciseNumber   in     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  , pStartDate        in     ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pEndDate          in     ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , pDescription      in     ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type
  , pLargeDescription in     ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type
  , pTargetFinYearId  in out ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
  is
    vErrorCode number(1);
  begin
    vErrorCode  := 0;   --No errors

    select INIT_ID_SEQ.nextval
      into pTargetFinYearId
      from dual;

    begin
      insert into ACS_FINANCIAL_YEAR
                  (ACS_FINANCIAL_YEAR_ID
                 , C_STATE_FINANCIAL_YEAR
                 , FYE_NO_EXERCICE
                 , FYE_START_DATE
                 , FYE_END_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (pTargetFinYearId
                 , 'PLA'
                 , pExerciseNumber
                 , pStartDate
                 , pEndDate
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    exception
      when dup_val_on_index then
        pTargetFinYearId  := null;
        vErrorCode        := -1;   --Ne peut cr�er l'enregistrement principal
    end;

    if vErrorCode = 0 then
      begin
        insert into ACS_DESCRIPTION
                    (ACS_DESCRIPTION_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , PC_LANG_ID
                   , DES_DESCRIPTION_SUMMARY
                   , DES_DESCRIPTION_LARGE
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , pTargetFinYearId
               , PC_LANG_ID
               , pDescription
               , pLargeDescription
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from ACS_DESCRIPTION
           where ACS_FINANCIAL_YEAR_ID = pSourceFinYearId;
      exception
        when others then
          vErrorCode  := -2;   --Ne peut cr�er les descriptions de l'exercice
      end;
    end if;

    if vErrorCode = 0 then
      ACS_PERIOD_FCT.FinYearPeriodsCreation(pTargetFinYearId, pStartDate, pEndDate);

      --Copie des num�roteurs
      begin
        insert into ACJ_NUMBER_APPLICATION
                    (ACJ_NUMBER_APPLICATION_ID
                   , ACJ_NUMBER_METHOD_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , ACJ_CATALOGUE_DOCUMENT_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , ACJ_NUMBER_METHOD_ID
               , pTargetFinYearId
               , ACJ_CATALOGUE_DOCUMENT_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from ACJ_NUMBER_APPLICATION
           where ACS_FINANCIAL_YEAR_ID = pSourceFinYearId;
      exception
        when others then
          vErrorCode  := -3;   --Ne peut cr�er les num�roteurs de l'exercice
      end;
    end if;

    if vErrorCode < 0 then
      pTargetFinYearId  := vErrorCode;
    end if;
  end DuplicateFinancialYear;
end ACS_FINANCIAL_YEAR_FCT;
