--------------------------------------------------------
--  DDL for Package Body ACS_PRC_FINANCIAL_YEAR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_PRC_FINANCIAL_YEAR" 
is
  /**
  * Description  Procédure de création de l'exercice  / périodes
  *              selon paramètres donnés
  **/
  procedure CreatePlanExercisePeriods(
    iInsertTable in     varchar2
  , iNumber      in     ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
  , iStartDate   in     ACS_PLAN_YEAR.PYE_START_DATE%type
  , iEndDate     in     ACS_PLAN_YEAR.PYE_END_DATE%type
  , ioTableId    in out ACS_PLAN_YEAR.ACS_PLAN_YEAR_ID%type
  )
  is
  begin
    if iInsertTable = 'EXE' then
      select init_id_seq.nextval
        into ioTableId
        from dual;

      insert into ACS_PLAN_YEAR
                  (ACS_PLAN_YEAR_ID
                 , PYE_NO_EXERCISE
                 , PYE_START_DATE
                 , PYE_END_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (ioTableId
                 , iNumber
                 , iStartDate
                 , iEndDate
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    elsif iInsertTable = 'PER' then
      insert into ACS_PLAN_PERIOD
                  (ACS_PLAN_PERIOD_ID
                 , ACS_PLAN_YEAR_ID
                 , APP_NO_PERIOD
                 , APP_START_DATE
                 , APP_END_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , ioTableId
                 , iNumber
                 , iStartDate
                 , iEndDate
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end CreatePlanExercisePeriods;

  /**
  * Description  Création des exercice de planification selon l'exercice
  *              de référence DONNE dans l'intervalle donnée
  **/
  procedure FillRefPlanExercise(
    iRefYear   in ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
  , iStartYear in ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
  , iEndYear   in ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
  )
  is
    cursor lcurExercisePeriods(iRef ACS_PLAN_YEAR.PYE_NO_EXERCISE%type, iYear ACS_PLAN_YEAR.PYE_NO_EXERCISE%type)
    is
      select lpad(iYear, 4, '0') FYE_NO_EXERCISE
           , to_date(to_char(FYE.FYE_START_DATE, 'DDMM') ||
                     lpad(to_char(to_number(to_char(FYE.FYE_START_DATE, 'YYYY') ) +(iYear - FYE.FYE_NO_EXERCICE) )
                        , 4
                        , '0'
                         )
                   , 'DD.MM.YYYY'
                    ) FYE_START_DATE
           , to_date(to_char(FYE.FYE_END_DATE, 'DDMM') ||
                     lpad(to_char(to_number(to_char(FYE.FYE_END_DATE, 'YYYY') ) +(iYear - FYE.FYE_NO_EXERCICE) )
                        , 4
                        , '0'
                         )
                   , 'DD.MM.YYYY'
                    ) FYE_END_DATE
           , PER.PER_NO_PERIOD PER_NO_PERIOD
           , to_date(to_char(PER.PER_START_DATE, 'DDMM') ||
                     lpad(to_char(to_number(to_char(PER.PER_START_DATE, 'YYYY') ) +(iYear - FYE.FYE_NO_EXERCICE) )
                        , 4
                        , '0'
                         )
                   , 'DD.MM.YYYY'
                    ) PER_START_DATE
           , last_day(to_date(to_char(PER.PER_START_DATE, 'DDMM') ||
                     lpad(to_char(to_number(to_char(PER.PER_END_DATE, 'YYYY') ) +(iYear - FYE.FYE_NO_EXERCICE) )
                        , 4
                        , '0'
                         )
                   , 'DD.MM.YYYY'
                      )
                    ) PER_END_DATE
        from ACS_FINANCIAL_YEAR FYE
           , ACS_PERIOD PER
       where FYE.FYE_NO_EXERCICE = iRef
         and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
         and PER.C_TYPE_PERIOD = '2'
         and not exists(select 1
                          from ACS_PLAN_YEAR PYE
                         where PYE.PYE_NO_EXERCISE = lpad(iYear, 4, '0') );

    lCurrentYear        ACS_PLAN_YEAR.PYE_NO_EXERCISE%type;
    lCurrentYearId      ACS_PLAN_YEAR.ACS_PLAN_YEAR_ID%type;
    ltplExercisePeriods lcurExercisePeriods%rowtype;
  begin
    if     (iStartYear > 0)
       and (iEndYear > 0) then
      lCurrentYear  := iStartYear;

      while lCurrentYear <= iEndYear loop
        open lcurExercisePeriods(iRefYear, lCurrentYear);

        fetch lcurExercisePeriods
         into ltplExercisePeriods;

        if lcurExercisePeriods%found then
          CreatePlanExercisePeriods('EXE'
                                  , ltplExercisePeriods.FYE_NO_EXERCISE
                                  , ltplExercisePeriods.FYE_START_DATE
                                  , ltplExercisePeriods.FYE_END_DATE
                                  , lCurrentYearId
                                   );
        end if;

        while lcurExercisePeriods%found loop
          CreatePlanExercisePeriods('PER'
                                  , ltplExercisePeriods.PER_NO_PERIOD
                                  , ltplExercisePeriods.PER_START_DATE
                                  , ltplExercisePeriods.PER_END_DATE
                                  , lCurrentYearId
                                   );

          fetch lcurExercisePeriods
           into ltplExercisePeriods;
        end loop;

        close lcurExercisePeriods;

        lCurrentYear  := lCurrentYear + 1;
      end loop;
    end if;
  end FillRefPlanExercise;

  /**
  * Description  Création des exercice de planification selon cascade
  *              identique à la cascade de l'interface lors de la création manuelle
  *              1°) l'exercice de référence PAR DEFAUT dans l'intervalle donné
  *              2°) Dernier exercice comptable actif
  **/
  procedure FillPlanExercise(
    iStartYear in ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
  , iEndYear   in ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
  )
  is
    lRefYear ACS_PLAN_YEAR.PYE_NO_EXERCISE%type;
  begin
    select nvl(max(FYE.FYE_NO_EXERCICE), 0)
      into lRefYear
      from ACS_FINANCIAL_YEAR FYE
     where FYE.FYE_PLAN_REFERENCE = 1;

    if lRefYear = 0 then
      select nvl(max(FYE.FYE_NO_EXERCICE), 0)
        into lRefYear
        from ACS_FINANCIAL_YEAR FYE
       where FYE.C_STATE_FINANCIAL_YEAR = 'ACT';
    end if;

    ACS_I_PRC_FINANCIAL_YEAR.FillRefPlanExercise(lRefYear, iStartYear, iEndYear);
  end FillPlanExercise;

end ACS_PRC_FINANCIAL_YEAR;
