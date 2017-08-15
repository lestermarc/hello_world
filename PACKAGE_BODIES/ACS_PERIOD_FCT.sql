--------------------------------------------------------
--  DDL for Package Body ACS_PERIOD_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_PERIOD_FCT" 
is
  /**
  * Description
  *   Renvoie la période de type donné la + récente
  **/
  function GetMaxPeriod(pPeriodTyp ACS_PERIOD.C_TYPE_PERIOD%type)
    return ACS_PERIOD.ACS_PERIOD_ID%type
  is
    vPeriodId ACS_PERIOD.ACS_PERIOD_ID%type;
  begin
    select max(ACS_PERIOD_ID)
      into vPeriodId
      from ACS_PERIOD
     where PER_END_DATE = (select max(PER_END_DATE)
                             from ACS_PERIOD
                            where C_TYPE_PERIOD = pPeriodTyp)
       and C_TYPE_PERIOD = pPeriodTyp;

    return vPeriodId;
  end GetMaxPeriod;

  /**
  * Description
  *   Renvoie la période de type donné la + récente
  **/
  function GetMinPeriod(pPeriodTyp ACS_PERIOD.C_TYPE_PERIOD%type)
    return ACS_PERIOD.ACS_PERIOD_ID%type
  is
    vPeriodId ACS_PERIOD.ACS_PERIOD_ID%type;
  begin
    select max(ACS_PERIOD_ID)
      into vPeriodId
      from ACS_PERIOD
     where PER_END_DATE = (select min(PER_END_DATE)
                             from ACS_PERIOD
                            where C_TYPE_PERIOD = pPeriodTyp)
       and C_TYPE_PERIOD = pPeriodTyp;

    return vPeriodId;
  end GetMinPeriod;

  /**
  * Description
  *   Renvoie Id de la periode comptable de type donné comprenant la date donnée
  **/
  function GetPeriodByDate(pDate date, pPeriodTyp varchar2)
    return ACS_PERIOD.ACS_PERIOD_ID%type
  is
    vPeriodId ACS_PERIOD.ACS_PERIOD_ID%type;
  begin
    vPeriodId  := ACS_FUNCTION.GetPeriodID(pDate, pPeriodTyp);
    return vPeriodId;
  end GetPeriodByDate;

  /**
  * Description
  *   Renvoie numéro de la periode comptable de type donné comprenant la date donnée
  **/
  function GetPeriodNoByDate(pDate date, pPeriodTyp varchar2)
    return ACS_PERIOD.PER_NO_PERIOD%type
  is
    vPerNoPeriod ACS_PERIOD.PER_NO_PERIOD%type;
  begin
    vPerNoPeriod  := ACS_FUNCTION.GetPeriodNo(pDate, pPeriodTyp);
    return vPerNoPeriod;
  end GetPeriodNoByDate;

  /**
  * Description
  *   Renvoie le numero de la periode donnée
  **/
  function GetPerNumById(pPeriodId ACS_PERIOD.ACS_PERIOD_ID%type)
    return ACS_PERIOD.PER_NO_PERIOD%type
  is
    vPerNoPeriod ACS_PERIOD.PER_NO_PERIOD%type;
  begin
    vPerNoPeriod  := ACS_FUNCTION.GetPerNumById(pPeriodId);
    return vPerNoPeriod;
  end GetPerNumById;

  /**
  * Description
  *   Renvoie le type de la période passée en parametre
  **/
  function GetPeriodType(pPeriodId ACS_PERIOD.ACS_PERIOD_ID%type)
    return ACS_PERIOD.C_TYPE_PERIOD%type
  is
    vType ACS_PERIOD.C_TYPE_PERIOD%type;
  begin
    vType  := ACS_FUNCTION.GetPeriodType(pPeriodId);
    return vType;
  end GetPeriodType;

  /**
  * Description
  *   Création automatique des périodes de l'exercice donné
  **/
  procedure FinYearPeriodsCreation(
    pFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pStartDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pEndDate   ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  )
  is
    vResult        boolean;
    vDateStart     ACS_PERIOD.PER_START_DATE%type;
    vDateEnd       ACS_PERIOD.PER_START_DATE%type;
    vCurrentPerNum ACS_PERIOD.PER_NO_PERIOD%type;

    /**
    * Fct de création de la position de période
    **/
    function AddPeriod(
      pFinYearId    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
    , pPerNum       ACS_PERIOD.PER_NO_PERIOD%type
    , pTypePeriod   ACS_PERIOD.C_TYPE_PERIOD%type
    , pPerStartDate ACS_PERIOD.PER_START_DATE%type
    , pPerEndDate   ACS_PERIOD.PER_END_DATE%type
    )
      return boolean
    is
      vResult   boolean;
      vPeriodId ACS_PERIOD.ACS_PERIOD_ID%type;
    begin
      vResult  := true;

      begin
        select INIT_ID_SEQ.nextval
          into vPeriodId
          from dual;   --Réception nouvel id

        insert into ACS_PERIOD
                    (   --Ajout de l'enregistrement
                     ACS_PERIOD_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , PER_NO_PERIOD
                   , C_STATE_PERIOD
                   , C_TYPE_PERIOD
                   , PER_START_DATE
                   , PER_END_DATE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vPeriodId
                   , pFinYearId
                   , pPerNum
                   , 'PLA'
                   , pTypePeriod
                   , pPerStartDate
                   , pPerEndDate
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      exception
        when others then
          vResult  := false;
      end;

      if vResult then   --Ajout des descriptions
        insert into ACS_DESCRIPTION
                    (ACS_DESCRIPTION_ID
                   , ACS_PERIOD_ID
                   , PC_LANG_ID
                   , DES_DESCRIPTION_SUMMARY
                   , DES_DESCRIPTION_LARGE
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , vPeriodId
               , PC_LANG_ID
               , decode(pTypePeriod
                      , 1, PCS.PC_FUNCTIONS.TRANSLATEWORD('Report', PC_LANG_ID)
                      , 2, substr(decode(to_char(pPerStartDate, 'MM')
                                       , '01', PCS.PC_FUNCTIONS.TRANSLATEWORD('Janvier', PC_LANG_ID)
                                       , '02', PCS.PC_FUNCTIONS.TRANSLATEWORD('Février', PC_LANG_ID)
                                       , '03', PCS.PC_FUNCTIONS.TRANSLATEWORD('Mars', PC_LANG_ID)
                                       , '04', PCS.PC_FUNCTIONS.TRANSLATEWORD('Avril', PC_LANG_ID)
                                       , '05', PCS.PC_FUNCTIONS.TRANSLATEWORD('Mai', PC_LANG_ID)
                                       , '06', PCS.PC_FUNCTIONS.TRANSLATEWORD('Juin', PC_LANG_ID)
                                       , '07', PCS.PC_FUNCTIONS.TRANSLATEWORD('Juillet', PC_LANG_ID)
                                       , '08', PCS.PC_FUNCTIONS.TRANSLATEWORD('Août', PC_LANG_ID)
                                       , '09', PCS.PC_FUNCTIONS.TRANSLATEWORD('Septembre', PC_LANG_ID)
                                       , '10', PCS.PC_FUNCTIONS.TRANSLATEWORD('Octobre', PC_LANG_ID)
                                       , '11', PCS.PC_FUNCTIONS.TRANSLATEWORD('Novembre', PC_LANG_ID)
                                       , '12', PCS.PC_FUNCTIONS.TRANSLATEWORD('Décembre', PC_LANG_ID)
                                       , ''
                                        )
                                , 01
                                , 60
                                 )
                      , 3, PCS.PC_FUNCTIONS.TRANSLATEWORD('Bouclement', PC_LANG_ID)
                      , ''
                       )
               , ''
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from PCS.PC_LANG
           where LANUSED = 1;
      end if;

      return vResult;
    end;
  begin
    vCurrentPerNum  := 0;
    vDateStart      := pStartDate;
    /*Création de la période de report à la date début exercice */
    vResult         :=
      AddPeriod(pFinYearId,   --Exercice lié
                vCurrentPerNum,   --Numéro
                '1',   --Type de période
                vDateStart,   --Date début
                vDateStart);   --Date fin

    /*Création des périodes de gestion selon découpage mensuel jusqu'à la date de fin exercice */
    while vResult
     and vCurrentPerNum < 12 loop
      vCurrentPerNum  := vCurrentPerNum + 1;

      if pEndDate < vDateStart then
        vDateEnd  := pEndDate;
      else
        select last_day(vDateStart)
          into vDateEnd
          from dual;
      end if;

      vResult         :=
        AddPeriod(pFinYearId,   --Exercice lié
                  vCurrentPerNum,   --Numéro
                  '2',   --Type de période
                  vDateStart,   --Date début
                  vDateEnd);   --Date fin

      /*Recherche date début de la période suivant en tenant compte du chevauchement sur 2 années civiles*/
      select decode(to_char(vDateStart, 'MM')
                  , '12', to_date('01.01.' || to_char(to_number(to_char(vDateStart, 'YYYY') ) + 1), 'DD.MM.YYYY')
                  , to_date('01.' || to_char(to_number(to_char(vDateStart, 'MM') ) + 1) || to_char(vDateStart, '.YYYY')
                          , 'DD.MM.YYYY'
                           )
                   )
        into vDateStart
        from dual;
    end loop;

    if vResult then
      vCurrentPerNum  := vCurrentPerNum + 1;
      vResult         :=
        AddPeriod(pFinYearId,   --Exercice lié
                  vCurrentPerNum,   --Numéro
                  '3',   --Type de période
                  vDateEnd,   --Date début
                  vDateEnd);   --Date fin
    end if;
  end FinYearPeriodsCreation;

  /**
  * Description
  *   Renumérotation des périodes de l'exercice donné
  **/
  procedure SetPeriodsNumber(pFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin
    if not pFinYearId is null then
      /* Période de report */
      update ACS_PERIOD
         set PER_NO_PERIOD = 0
       where ACS_FINANCIAL_YEAR_ID = pFinYearId
         and C_TYPE_PERIOD = '1';

      /* Période de gestion */
      update ACS_PERIOD A
         set A.PER_NO_PERIOD =
               (select count(*) + 1
                  from ACS_PERIOD B
                 where B.PER_END_DATE < A.PER_START_DATE
                   and B.ACS_FINANCIAL_YEAR_ID = A.ACS_FINANCIAL_YEAR_ID
                   and B.C_TYPE_PERIOD = A.C_TYPE_PERIOD)
       where A.ACS_FINANCIAL_YEAR_ID = pFinYearId
         and A.C_TYPE_PERIOD = '2';

      /* Période de bouclement */
      update ACS_PERIOD A
         set A.PER_NO_PERIOD = (select max(PER_NO_PERIOD) + 1
                                  from ACS_PERIOD B
                                 where B.ACS_FINANCIAL_YEAR_ID = A.ACS_FINANCIAL_YEAR_ID
                                   and B.C_TYPE_PERIOD = '2')
       where A.ACS_FINANCIAL_YEAR_ID = pFinYearId
         and A.C_TYPE_PERIOD = '3';
    end if;
  end SetPeriodsNumber;

  /**
  * function GetEndDatePeriod
  *   Renvoie la date de fin de la période passée en parametre
  */
  function GetEndDatePeriod(aPeriodId ACS_PERIOD.ACS_PERIOD_ID%type)
  return ACS_PERIOD.PER_END_DATE%type
  is
    vEndDate ACS_PERIOD.PER_END_DATE%type;
  begin
    select PER_END_DATE
      into vEndDate
      from ACS_PERIOD
     where ACS_PERIOD_ID = aPeriodId;

    return vEndDate;
end GetEndDatePeriod;

  /**
  * procedure CheckActivePeriodBetweenDates
  * Description
  *  Vérifie si l'ensemble des périodes comprises entre les dates données sont bien en statut actif
  */
  function CheckActivePeriodBetweenDates(iDateFrom date, iDateTo date)
      return pls_integer
    is
      vNotActPeriod pls_integer := 0;
      vResult       pls_integer := 0;
    begin
      if (     (iDateFrom is not null)
          and (iDateTo is not null) ) then
        select count(*)
          into vNotActPeriod
          from ACS_PERIOD
         where C_STATE_PERIOD <> 'ACT'
           and C_TYPE_PERIOD = '2'
           and (    (ACS_PERIOD_ID >= GetFirstActPeriod(iDateFrom))
                and (PER_END_DATE <= iDateTo) )
           and (select max(PER_END_DATE)
                  from ACS_PERIOD
                 where C_TYPE_PERIOD = '2') >= iDateTo;

        if (vNotActPeriod = 0) then
          vResult  := 1;
        end if;
      end if;

      return vResult;
    end CheckActivePeriodBetweenDates;

  /**
  * function PeriodIsCurrentYear
  * Description
  *  Vérifie si la période passée en paramètre fait partie de l'exercice courant
  */
    function PeriodIsCurrentYear(iPeriodId ACS_PERIOD.ACS_PERIOD_ID%type)
      return pls_integer
    is
      vResult pls_integer := 0;
    begin
      select count(*)
        into vResult
        from ACS_FINANCIAL_YEAR FYE
           , ACS_PERIOD PER
       where PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
         and sysdate between FYE.FYE_START_DATE and FYE.FYE_END_DATE
         and PER.acs_period_id = iPeriodId;

      return vResult;
    end PeriodIsCurrentYear;

  /**
  * function GetFirstActPeriod
  * Description
  *  Renvoie la première période active suivant la date passée en paramètre
  */
    function GetFirstActPeriod(iDateFrom date)
      return ACS_PERIOD.ACS_PERIOD_ID%type
    is
      vResult ACS_PERIOD.ACS_PERIOD_ID%type;
    begin
      select min(ACS_PERIOD_ID)
        into vResult
        from ACS_PERIOD
       where PER_START_DATE >= iDateFrom
         and C_STATE_PERIOD = 'ACT'
         and C_TYPE_PERIOD = '2';

      return vResult;
    end GetFirstActPeriod;

  /**
  * function GetNbMonthBetweenPer
  * Description
  *  Compte le nombre de mois entre les périodes passées an paramètre
  */
  function GetNbMonthBetweenPer(inDateIdFrom ACS_PERIOD.ACS_PERIOD_ID%type, inDateIdTo ACS_PERIOD.ACS_PERIOD_ID%type)
    return number
  is
    lnResult               number;
    lnStartMonthPeriodFrom number := 0;
    lnStartMonthPeriodTo   number := 0;
  begin
    begin
        select to_number(to_char(PER_START_DATE, 'MM') )
          into lnStartMonthPeriodFrom
          from ACS_PERIOD
         where ACS_PERIOD_ID = inDateIdFrom;
      exception
        when NO_DATA_FOUND then
           return null;
      end;

    begin
    select to_number(to_char(PER_END_DATE, 'MM') )
      into lnStartMonthPeriodTo
      from ACS_PERIOD
     where ACS_PERIOD_ID = inDateIdTo;
      exception
        when NO_DATA_FOUND then
           return null;
      end;

    lnResult  := (lnStartMonthPeriodTo - lnStartMonthPeriodFrom) + 1;
    return lnResult;
  end GetNbMonthBetweenPer;

  /**
  * function GetFirstYearPeriod
  * Description
  *  Retourne l'id de la première période de gestion de l'exercice donné
  */
    function GetFirstYearPeriod(inFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type, ivPeriodTyp ACS_PERIOD.C_TYPE_PERIOD%type)
      return ACS_PERIOD.ACS_PERIOD_ID%type
is
    lnPeriodId    ACS_PERIOD.ACS_PERIOD_ID%type;
begin
    select min(ACS_PERIOD_ID)
      into lnPeriodId
      from ACS_PERIOD
     where ACS_FINANCIAL_YEAR_ID = inFinYearId
        and C_TYPE_PERIOD = ivPeriodTyp;

    return lnPeriodId;
  end GetFirstYearPeriod;

  /**
  * function GetLastYearPeriod
  * Description
  *  Retourne l'id de la première période de gestion de l'exercice donné
  */
    function GetLastYearPeriod(inFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type, ivPeriodTyp ACS_PERIOD.C_TYPE_PERIOD%type)
      return ACS_PERIOD.ACS_PERIOD_ID%type
is
    lnPeriodId    ACS_PERIOD.ACS_PERIOD_ID%type;
begin
    select max(ACS_PERIOD_ID)
      into lnPeriodId
      from ACS_PERIOD
     where ACS_FINANCIAL_YEAR_ID = inFinYearId
        and C_TYPE_PERIOD = ivPeriodTyp;

    return lnPeriodId;
  end GetLastYearPeriod;
end ACS_PERIOD_FCT;
