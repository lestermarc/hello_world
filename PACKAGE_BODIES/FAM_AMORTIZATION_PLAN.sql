--------------------------------------------------------
--  DDL for Package Body FAM_AMORTIZATION_PLAN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAM_AMORTIZATION_PLAN" 
is
  /**
  * Arrondi du montant donn� selon la monnaie, le type d'arrondi et le montant d'arrondi
  **/
  function RoundAmount(
    aRoundType     in FAM_AMORTIZATION_METHOD.C_ROUND_TYPE%type   --Type d'arrondi
  , aRoundAmount   in FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT%type   --Montant d'arrondi
  , aLocalCurrency in FAM_PLAN_EXERCISE.ACS_ACS_FINANCIAL_CURRENCY_ID%type   --Monnaie de base   du montant de base pour calcul d�finitif
  , aAmount        in FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type   --Montant d'amortissement calcul�
  )
    return FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type
  is
    vResult FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;
  begin
    if nvl(aRoundType, '0') = '0' then
      vResult  := ACS_FUNCTION.RoundAmount(aAmount, aLocalCurrency);
    else
      vResult  := ACS_FUNCTION.PCSRound(aAmount, aRoundType, aRoundAmount);
    end if;

    return vResult;
  end RoundAmount;

  /**
  * Retour du nombre de jour � amortir
  **/
  function GetAmortizationDays(
    aYearStartDate         in ACS_PERIOD.PER_START_DATE%type
  , aYearEndDate           in ACS_PERIOD.PER_END_DATE%type
  , aAmortizationStartDate in FAM_AMO_APPLICATION.APP_AMORTIZATION_BEGIN%type
  , aAmortizationEndDate   in FAM_AMO_APPLICATION.APP_AMORTIZATION_END%type
  )
    return FAM_PLAN_EXERCISE.FPE_DAYS%type
  is
    vCalcDaysStart             ACS_PERIOD.PER_START_DATE%type;   --R�ceptionne la date d�but prise en compte pour calcul du nombre de jours
    vCalcDaysEnd               ACS_PERIOD.PER_END_DATE%type;   --R�ceptionne la date fin prise en compte pour calcul du nombre de jours
    vCalcStartDateMonth        number(2);   --R�ceptionne le mois de la date de d�but de calcul de jours
    vCalcEndDateMonth          number(2);   --R�ceptionne le mois de la date de fin de calcul de jours
    vCalcStartDateDay          number(2);   --R�ceptionne le jour de la date d�but
    vCalcEndDateDay            number(2);   --R�ceptionne le jour de la date fin
    vCalcStartDateMonthLastDay number(2);   --R�ceptionne le dernier jour du mois de d�but de calcul de jours
    vCalcEndDateMonthLastDay   number(2);   --R�ceptionne le dernier jour du mois de fin de calcul de jours
    vCalcStartDateYear         number(4);   --R�ceptionne l'ann�e de la date de d�but de calcul
    vCalcEndDateYear           number(4);   --R�ceptionne l'ann�e de la date de fin de calcul
    vResult                    FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --R�ceptionne le nombre de jours calcul�s
  begin
    /* D�termination de la date d�but de calcul selon la date d�but amortissement de l'immob*/
    if aAmortizationStartDate < aYearStartDate then   --D�but d'amortissement est ant�rieure � la p�riode consid�r�e
      vCalcDaysStart  := aYearStartDate;
    elsif aAmortizationStartDate between aYearStartDate and aYearEndDate then   --D�but d'amortissement est compris dans l'intervalle
      vCalcDaysStart  := aAmortizationStartDate;   -- => Date d�but de calcul = date d�but d'amortissement
    else
      vCalcDaysStart  := null;
    end if;

    /* D�termination de la date finde calcul selon la date fin amortissement de l'immob*/
    if aAmortizationEndDate is not null then
      if aAmortizationEndDate between aYearStartDate and aYearEndDate then   --Fin d'amortissement est compris dans l'intervalle
        vCalcDaysEnd  := aAmortizationEndDate;   -- => Date fin de calcul = date fin d'amortissement
      elsif aAmortizationEndDate > aYearEndDate then   --Fin d'amortissement est post�rieur � la date de fiin de l'intervalle consid�r�e
        vCalcDaysEnd  := aYearEndDate;   -- => Date fin de calcul = date fin d'amortissement
      else
        vCalcDaysEnd  := null;
      end if;
    else
      vCalcDaysEnd  := aYearEndDate;
    end if;

    /* Calcul du nombre de jours */
    select to_number(to_char(vCalcDaysStart, 'MM') )
         , to_number(to_char(vCalcDaysEnd, 'MM') )
         , to_number(to_char(vCalcDaysStart, 'DD') )
         , to_number(to_char(vCalcDaysEnd, 'DD') )
         , to_number(to_char(last_day(vCalcDaysStart), 'DD') )
         , to_number(to_char(last_day(vCalcDaysEnd), 'DD') )
         , to_number(to_char(vCalcDaysStart, 'YYYY') )
         , to_number(to_char(vCalcDaysEnd, 'YYYY') )
      into vCalcStartDateMonth
         , vCalcEndDateMonth
         , vCalcStartDateDay
         , vCalcEndDateDay
         , vCalcStartDateMonthLastDay
         , vCalcEndDateMonthLastDay
         , vCalcStartDateYear
         , vCalcEndDateYear
      from dual;

    /*Si la date d�but et date fin de la p�riode sont dans le m�me mois  et que la date d�but = premier jour du mois et que la date fin = dernier jour du mois ou consid�r� comme tel (max 30 jours par mois) :
        30
      Si la date d�but et date fin de la p�riode sont dans le m�me mois :
        date fin - date d�but + 1
      Si la date d�but et date fin de la p�riode ne sont pas dans le m�me mois :
       ((30 - date d�but) + 1) + 30 jours par mois complet + (date fin, max 30)
    */--Force le nb de jours � 30 si date = dernier jour du mois
    if (vCalcStartDateDay = vCalcStartDateMonthLastDay) then
      vCalcStartDateDay  := 30;
    end if;

    if (vCalcEndDateDay = vCalcEndDateMonthLastDay) then
      vCalcEndDateDay  := 30;
    end if;

    -- date d�but et date fin sont dans le m�me mois
    -- date d�but et date fin sont dans le m�me mois de la m�me ann�e
    if     (vCalcStartDateMonth = vCalcEndDateMonth)
       and (vCalcStartDateYear = vCalcEndDateYear) then
      if vCalcStartDateMonth = 2 then
        vResult  := 30;
      else
        vResult  := vCalcEndDateDay - vCalcStartDateDay + 1;
      end if;
    else
      --                             |           nombre de jours par mois complet s�parant les deux dates                |
      --       |jours du mois d�but  | |mois complet s�parant les 2 dates  |   |12 mois par ann�e de diff�rence    |     |jours du mois fin|
      vResult  :=
        30 -
        vCalcStartDateDay +
        ( ( (vCalcEndDateMonth - vCalcStartDateMonth) - 1 +( (vCalcEndDateYear - vCalcStartDateYear) * 12) ) * 30
        ) +
        vCalcEndDateDay +
        1;
    end if;

    return vResult;
  end GetAmortizationDays;

  /**
  * Retour du nombre de jour couvert par le calcul
  **/
  function GetCoveredDays(
    aPlanYearId in FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type
  , aEndDate    in FAM_PLAN_EXERCISE.PYE_END_DATE%type
  )
    return FAM_PLAN_EXERCISE.FPE_DAYS%type
  is
    vResult                    FAM_PLAN_EXERCISE.FPE_DAYS%type;
    vCalcStartDateMonth        number(2);   --R�ceptionne le mois de la date de d�but de calcul de jours
    vCalcEndDateMonth          number(2);   --R�ceptionne le mois de la date de fin de calcul de jours
    vCalcStartDateDay          number(2);   --R�ceptionne le jour de la date d�but
    vCalcEndDateDay            number(2);   --R�ceptionne le jour de la date fin
    vCalcStartDateMonthLastDay number(2);   --R�ceptionne le dernier jour du mois de d�but de calcul de jours
    vCalcEndDateMonthLastDay   number(2);   --R�ceptionne le dernier jour du mois de fin de calcul de jours
    vCalcStartDateYear         number(4);   --R�ceptionne l'ann�e de la date de d�but de calcul
    vCalcEndDateYear           number(4);   --R�ceptionne l'ann�e de la date de fin de calcul
    vPlanYearId                FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type;
  begin
    select nvl(max(PYE.ACS_PLAN_YEAR_ID), 0)
      into vPlanYearId
      from ACS_PLAN_YEAR PYE
     where PYE.ACS_PLAN_YEAR_ID = aPlanYearId
       and aEndDate between PYE.PYE_START_DATE and PYE.PYE_END_DATE;

    if vPlanYearId <> 0 then
      /* Calcul du nombre de jours */
      select to_number(to_char(PYE.PYE_START_DATE, 'MM') )
           , to_number(to_char(aEndDate, 'MM') )
           , to_number(to_char(PYE.PYE_START_DATE, 'DD') )
           , to_number(to_char(aEndDate, 'DD') )
           , to_number(to_char(last_day(PYE.PYE_START_DATE), 'DD') )
           , to_number(to_char(last_day(aEndDate), 'DD') )
           , to_number(to_char(PYE.PYE_START_DATE, 'YYYY') )
           , to_number(to_char(aEndDate, 'YYYY') )
        into vCalcStartDateMonth
           , vCalcEndDateMonth
           , vCalcStartDateDay
           , vCalcEndDateDay
           , vCalcStartDateMonthLastDay
           , vCalcEndDateMonthLastDay
           , vCalcStartDateYear
           , vCalcEndDateYear
        from ACS_PLAN_YEAR PYE
       where PYE.ACS_PLAN_YEAR_ID = aPlanYearId
         and aEndDate between PYE.PYE_START_DATE and PYE.PYE_END_DATE;

      /*Si la date d�but et date fin de la p�riode sont dans le m�me mois  et que la date d�but = premier jour du mois et que la date fin = dernier jour du mois ou consid�r� comme tel (max 30 jours par mois) :
          30
        Si la date d�but et date fin de la p�riode sont dans le m�me mois :
          date fin - date d�but + 1
        Si la date d�but et date fin de la p�riode ne sont pas dans le m�me mois :
         ((30 - date d�but) + 1) + 30 jours par mois complet + (date fin, max 30)
      */
      --Force le nb de jours � 30 si date = dernier jour du mois
      if (vCalcStartDateDay = vCalcStartDateMonthLastDay) then
        vCalcStartDateDay  := 30;
      end if;

      if (vCalcEndDateDay = vCalcEndDateMonthLastDay) then
        vCalcEndDateDay  := 30;
      end if;

      -- date d�but et date fin sont dans le m�me mois
      if     (vCalcStartDateMonth = vCalcEndDateMonth)
         and (vCalcStartDateYear = vCalcEndDateYear) then
        vResult  := vCalcEndDateDay - vCalcStartDateDay + 1;
      else
        --                             |           nombre de jours par mois complet s�parant les deux dates                |
        --       |jours du mois d�but  | |mois complet s�parant les 2 dates  |   |12 mois par ann�e de diff�rence    |     |jours du mois fin|
        vResult  :=
          30 -
          vCalcStartDateDay +
          ( ( (vCalcEndDateMonth - vCalcStartDateMonth) - 1 +( (vCalcEndDateYear - vCalcStartDateYear) * 12) ) * 30
          ) +
          vCalcEndDateDay +
          1;
      end if;
    else
      vResult  := 360;
    end if;

    return vResult;
  end GetCoveredDays;

  /**
  * Calcul de la date de fin amortissement selon date d�but et dur�e donn�es
  **/
  function GetAmortizationEndDate(
    aDuration  in FAM_AMO_APPLICATION.APP_MONTH_DURATION%type
  , aBeginDate in ACS_PLAN_YEAR.PYE_START_DATE%type
  )
    return ACS_PLAN_YEAR.PYE_END_DATE%type
  is
    vNextYearStartMonthDay number(4);   --Mois et jour de la date d�but exercice de l'exercice suivant l'exercice comprenant la date de d�but d'amortissement
    vExerciseMonthNumber   number(4);   --Nombre de mois couvert par l'exercice contenant la date d�but d'amortissement
    vExerciseYear          number(4);   --Ann�e CALCULEE selon r�gles de la date d�but amortissement calcul�e sous format num�rique
    vAmoBeginExerciseYear  number(4);   --Ann�e de la date d�but amortissement sous forme num�rique
    vAmoBeginMonthDay      number(4);   --Mois et jour de la date d�but amortissement sous forme num�rique selon format 'MMDD'
    vRefDateAmoBegin       ACS_PLAN_YEAR.PYE_START_DATE%type;   --Date de r�f�rence calcul�e de d�but amortissement
    vAmoBeginExerciseStart ACS_PLAN_YEAR.PYE_START_DATE%type;   --Date d�but exercice de l'exercice de d�but amortissement
    vResult                ACS_PLAN_YEAR.PYE_END_DATE%type;   --Valeur de retour
  begin
    /* Une immo au taux 1 = 25%, coeff X, dont la date d'amortissement d�marre le 01/09/2006
       La m�thode de type 6 effectue:
         Amortissement tronqu� au prorata sur 2006
         Fin d'amortissement ramen� au 31/12/2009 --> Les valeurs des amortissements calcul�s en d�coulent donc.
       La m�thode de type 60 effectue:
         Amortissement idem au prorata sur 2006
         Fin d'amortissement pr�vue au 31/08/2010, soit (100/25=) 4 ann�es COMPLETES (4 x 12 = 48 mois)
    */
    vRefDateAmoBegin  := aBeginDate;

    if gAmoType = '6' then
      begin
        --Calcul de la date de r�f�rence � partir de laquelle on ajoute la dur�e pour calculer la date de fin amortissement.
        --Cete date change selon que la date de d�but amortissement est dans un exercice couvrant plusieurs ann�es civiles ou
        --que la date d�but exercice n'est pas le 01.janvier civil.
        --Si l'exercice dans lequel se trouve la date d�but amortissement couvre plus de 23 mois (round) :
        --Rechercher le mois et le jour (MM.DD) de d�but 'standard' des exercice comptable
        --(la date pourra�t �tre d�cal�e par rapport au d�but de l'exercice civile)
        --MM.DD de la date d�but du prochain exercice comptable (dans notre exemple : '01.01')
        --Si 'MM.DD' de la date d�but amortissement (01.31 dans notre exemple) >= 'MM.DD'. Recherch� ('01.01') -->
        --ann�e (YYYY) = ann�e de la date d�but amortissement ('2002' dans notre exemple)
        --Date d�but calcul dur�e : 01.01.2002
        --Si 'MM.DD' de la date d�but amortissement  < 'MM.DD'. Recherch� --> ann�e (YYYY) = ann�e de la date d�but amortissement - 1
        --Exemple : exercice 2 : 01.04.2004
        --Date d�but calcul dur�e : 01.04.2001 (2002 - 1, parce que '01.31' est plus petit que '04.01'
        --
        --A�  - Nombre de mois couvert par l'exercice contenant la date d�but d'amortissement
        --B�  - Ann�e de la date d�but amortissement sous forme num�rique
        --C�  - Mois et jour de la date d�but amortissement sous forme num�rique selon format 'MMDD'
        --D�  - Mois et jour de la date d�but exercice de l'exercice suivant l'exercice contenant la date d�but amortissement
        --      sous forme num�rique selon format 'MMDD'
        --E�  - Date d�but exercice de l'exercice couvrant la date d�but amortissement
        select abs(round(months_between(FIX_YEAR.PYE_END_DATE, FIX_YEAR.PYE_START_DATE) ) ) A
             , to_number(to_char(aBeginDate, 'YYYY') ) B
             , to_number(to_char(aBeginDate, 'MMDD') ) C
             , nvl(to_number(to_char(NEXT_YEAR.PYE_START_DATE, 'MMDD') ), 101) D
             , FIX_YEAR.PYE_START_DATE E
          into vExerciseMonthNumber
             , vAmoBeginExerciseYear
             , vAmoBeginMonthDay
             , vNextYearStartMonthDay
             , vAmoBeginExerciseStart
          from ACS_PLAN_YEAR FIX_YEAR
             , ACS_PLAN_YEAR NEXT_YEAR
         where vRefDateAmoBegin between FIX_YEAR.PYE_START_DATE and FIX_YEAR.PYE_END_DATE
           and NEXT_YEAR.PYE_NO_EXERCISE(+) =(FIX_YEAR.PYE_NO_EXERCISE + 1);

        if vExerciseMonthNumber > 23 then
          if vAmoBeginMonthDay >= vNextYearStartMonthDay then
            vExerciseYear  := vAmoBeginExerciseYear;
          else
            vExerciseYear  := vAmoBeginExerciseYear - 1;
          end if;

          vRefDateAmoBegin  :=
                            to_date(to_char(lpad(vNextYearStartMonthDay, 4, '0') ) || to_char(vExerciseYear)
                                  , 'MMDDYYYY');
        else
          vRefDateAmoBegin  := vAmoBeginExerciseStart;
        end if;
      exception
        when no_data_found then
          select to_date('01.01.' ||(to_char(vRefDateAmoBegin, 'YYYY') ), 'dd.mm.yyyy')
            into vRefDateAmoBegin
            from dual;
      end;
    end if;

    --Date r�f�rence est incr�ment�e du nombre de mois du nombre d'ann�e totale, on obtient la date de fin amortissement calcul�e
    select add_months(vRefDateAmoBegin,(aDuration * 12) ) - 1
      into vResult
      from dual;

    return vResult;
  end GetAmortizationEndDate;

  /**
  * Retour du nombre d'exercices encore � amortir selon date fin th�orique
  * d'amortissement et l'exercice de calcul
  **/
  function GetExercisesToPlan(
    aPlanYearId  in ACS_PLAN_YEAR.ACS_PLAN_YEAR_ID%type
  , aCalcEndDate in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  )
    return number
  is
    vResult              number(5)                            default 1;
    vCurrentExerciseYear ACS_PLAN_YEAR.PYE_NO_EXERCISE%type;
    vCalculatedDateYear  ACS_PLAN_YEAR.PYE_NO_EXERCISE%type;
    vFoundExercise       boolean;

    function EndDateIsInExercise(
      aYearId    in ACS_PLAN_YEAR.ACS_PLAN_YEAR_ID%type
    , aEndDate   in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , aYearToAdd in number
    )
      return boolean
    is
      vExerciseMatch number(1);
    begin
      select nvl(max(1), 0)
        into vExerciseMatch
        from ACS_PLAN_YEAR PYE
       where PYE.ACS_PLAN_YEAR_ID = aYearId
         and aEndDate between to_date(to_char(lpad(to_number(to_char(PYE.PYE_START_DATE, 'MMDD') ), 4, '0') ) ||
                                      to_char(to_number(to_char(PYE.PYE_START_DATE, 'YYYY') ) + aYearToAdd)
                                    , 'MMDDYYYY'
                                     )
                          and to_date(to_char(lpad(to_number(to_char(PYE.PYE_END_DATE, 'MMDD') ), 4, '0') ) ||
                                      to_char(to_number(to_char(PYE.PYE_END_DATE, 'YYYY') ) + aYearToAdd)
                                    , 'MMDDYYYY'
                                     );

      return vExerciseMatch = 1;
    end EndDateIsInExercise;
  begin
    begin
      --R�ception ann�e de la date de fin et de l'exercice courant
      select to_number(to_char(PYE.PYE_START_DATE, 'YYYY') )
           , to_number(to_char(aCalcEndDate, 'YYYY') )
        into vCurrentExerciseYear
           , vCalculatedDateYear
        from ACS_PLAN_YEAR PYE
       where PYE.ACS_PLAN_YEAR_ID = aPlanYearId;

      --Si les deux ann�es correspondent, nombre d'exercice � planifier = 1
      if vCurrentExerciseYear = vCalculatedDateYear then
        vResult  := 1;
      --Sinon parcours des exercices jusqu'� l'exercice englobant la date de fin calcul�e
      --Le nombre d'exercice vaut le nombre de boucle fait pour arriver � ce r�sultat.
      elsif vCalculatedDateYear > vCurrentExerciseYear then
        vFoundExercise  := EndDateIsInExercise(aPlanYearId, aCalcEndDate, 0);

        while not vFoundExercise loop
          vFoundExercise  := EndDateIsInExercise(aPlanYearId, aCalcEndDate, vResult);
          vResult         := vResult + 1;
        end loop;
      end if;
    exception
      when no_data_found then
        vResult  := 1;
        raise;
    end;

    return vResult;
  end GetExercisesToPlan;

  /**
  * Description  Retour de la derni�re p�riode de l'exercice donn�
  **/
  function GetExerciseLastPeriodId(aPlanYearId in ACS_PLAN_YEAR.ACS_PLAN_YEAR_ID%type)
    return ACS_PLAN_PERIOD.ACS_PLAN_PERIOD_ID%type
  is
    vResult ACS_PLAN_PERIOD.ACS_PLAN_PERIOD_ID%type;
  begin
    select max(ACS_PLAN_PERIOD_ID)
      into vResult
      from ACS_PLAN_PERIOD
     where ACS_PLAN_YEAR_ID = aPlanYearId
       and APP_NO_PERIOD = (select max(APP_NO_PERIOD)
                              from ACS_PLAN_PERIOD
                             where ACS_PLAN_YEAR_ID = aPlanYearId);

    return vResult;
  end GetExerciseLastPeriodId;

  /**
  * Retour du montant d'amortissement d�j� calcul� par p�riode pour l'exercice donn�
  **/
  function GetExercisePreviousAmount(aPlanExerciseId in FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type)
    return FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type
  is
    vResult FAM_CALC_SIMULATION.FCS_AMORTIZATION_LC%type;
  begin
    select nvl(sum(nvl(FPP_AMORTIZATION_LC, 0) ), 0)
      into vResult
      from FAM_PLAN_PERIOD
     where FAM_PLAN_EXERCISE_ID = aPlanExerciseId;

    return vResult;
  end GetExercisePreviousAmount;

  /**
  * Retour du montant d'amortissement d�j� calcul� pour l'en-t�te de plan courant
  **/
  function GetHeaderPreviousAmount(aPlanHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type, aType60 in boolean)
    return FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type
  is
    vResult FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type;
  begin
    --Prise en compte uniquement des id n�gatifs pour les types roumains (9,60)
    if aType60 then
      select nvl(sum(nvl(FPE_AMORTIZATION_LC, 0) ), 0)
        into vResult
        from FAM_PLAN_EXERCISE
       where FAM_PLAN_HEADER_ID = aPlanHeaderId
         and sign(FAM_PLAN_EXERCISE_ID) = -1;
    else
      select nvl(sum(nvl(FPE_AMORTIZATION_LC, 0) ), 0)
        into vResult
        from FAM_PLAN_EXERCISE
       where FAM_PLAN_HEADER_ID = aPlanHeaderId
         and sign(FAM_PLAN_EXERCISE_ID) = +1;
    end if;

    return vResult;
  end GetHeaderPreviousAmount;

  /**
  *  Retour du montant d'amortissement d�j� comptabilis�s i.e montants imput�s
  *  avec transaction de type 600..699
  **/
  function GetAmortizedAmount(
    aFixedAssetsId  in FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId in FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , aReferenceDate  in FAM_IMPUTATION.FIM_TRANSACTION_DATE%type
  )
    return FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  is
    vResult FAM_IMPUTATION.FIM_AMOUNT_LC_D%type;
  begin
    select nvl(sum(nvl(FIM.FIM_AMOUNT_LC_C, 0) - nvl(FIM.FIM_AMOUNT_LC_D, 0) ), 0)
      into vResult
      from FAM_IMPUTATION FIM
     where FIM.FAM_FIXED_ASSETS_ID = aFixedAssetsId
       and FIM.FIM_TRANSACTION_DATE <= aReferenceDate
       and FIM.C_FAM_TRANSACTION_TYP between '600' and '699'
       and exists(select 1
                    from FAM_VAL_IMPUTATION VIM
                   where VIM.FAM_IMPUTATION_ID = FIM.FAM_IMPUTATION_ID
                     and VIM.FAM_MANAGED_VALUE_ID = aManagedValueId);

    return vResult;
  end GetAmortizedAmount;

  function GetHeaderPlanedAmount(
    aPlanHeaderId  in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aReferenceDate in FAM_IMPUTATION.FIM_TRANSACTION_DATE%type
  )
    return FAM_PLAN_PERIOD.FPP_ADAPTED_AMO_LC%type
  is
    vResult FAM_PLAN_PERIOD.FPP_ADAPTED_AMO_LC%type;
  begin
    select nvl(sum(FPP.FPP_ADAPTED_AMO_LC), 0)
      into vResult
      from FAM_PLAN_HEADER FPH
         , FAM_PLAN_EXERCISE FPE
         , FAM_PLAN_PERIOD FPP
     where FPH.FAM_PLAN_HEADER_ID = aPlanHeaderId
       and FPE.FAM_PLAN_HEADER_ID = FPH.FAM_PLAN_HEADER_ID
       and FPP.FAM_PLAN_EXERCISE_ID = FPE.FAM_PLAN_EXERCISE_ID
       and FPP.FPP_AMORTIZATION_END <= aReferenceDate;

    return vResult;
  end GetHeaderPlanedAmount;

  function GetFixAssetsPlanAmount(
    aFixedAssetsId  in FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId in FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  , aReferenceDate  in FAM_IMPUTATION.FIM_TRANSACTION_DATE%type
  )
    return FAM_PLAN_PERIOD.FPP_ADAPTED_AMO_LC%type
  is
    vResult       FAM_PLAN_PERIOD.FPP_ADAPTED_AMO_LC%type;
    vPlanHeaderId FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type;
  begin
    select max(FAM_PLAN_HEADER_ID)
      into vPlanHeaderId
      from FAM_PLAN_HEADER FPH
     where FPH.FAM_FIXED_ASSETS_ID = aFixedAssetsId
       and FPH.FAM_MANAGED_VALUE_ID = aManagedValueId;

    vResult  := GetHeaderPlanedAmount(vPlanHeaderId, aReferenceDate);
    return vResult;
  end GetFixAssetsPlanAmount;

  /**
  *  Retour du montant calcul� mais pas encore comptabilis�
  **/
  function GetInProgressAmoAmount(
    aFixedAssetsId  in FAM_CALC_AMORTIZATION.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId in FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , aReferenceDate  in ACS_PERIOD.PER_START_DATE%type
  )
    return FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type
  is
    vResult FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;
  begin
    select nvl(sum(nvl(FCA.CAL_AMORTIZATION_LC, 0) ), 0)
      into vResult
      from FAM_CALC_AMORTIZATION FCA
         , FAM_PER_CALC_BY_VALUE FPC
         , ACS_PERIOD PER
     where FCA.FAM_FIXED_ASSETS_ID = aFixedAssetsId
       and FPC.FAM_MANAGED_VALUE_ID = aManagedValueId
       and FPC.FAM_PER_CALC_BY_VALUE_ID = FCA.FAM_PER_CALC_BY_VALUE_ID
       and FCA.FAM_IMPUTATION_ID is null
       and PER.PER_END_DATE <= aReferenceDate
       and FPC.ACS_PERIOD_ID = PER.ACS_PERIOD_ID;

    return vResult;
  end GetInProgressAmoAmount;

  /**
  * Retour du montant d�j� comptabilis�s jusqu'� la date de fin exercice donn�e
  * correspondant � l'�l�ment de structure de la limite amortissement
  **/
  function GetStructureElemAmount(
    aFixedAssetsId      in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId     in FAM_PLAN_HEADER.FAM_MANAGED_VALUE_ID%type
  , aFyeEndDate         in ACS_PLAN_YEAR.PYE_START_DATE%type
  , aStructureElementId in FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT1_ID%type
  , aIsBudget           in number   --Indique si simulation (1) ou non(0)
  )
    return FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  is
    vResult FAM_IMPUTATION.FIM_AMOUNT_LC_D%type;
  begin
    if aIsBudget = 1 then
      if aFyeEndDate is null then
        select nvl(sum(nvl(PER.PER_AMOUNT_D, 0) - nvl(PER.PER_AMOUNT_C, 0) ), 0) PER_AMOUNT_D
          into vResult
          from ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PER
             , ACS_PERIOD PER1
         where VER.VER_FIX_ASSETS = 1
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and GLO.FAM_FIXED_ASSETS_ID = aFixedAssetsId
           and PER.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
                    and GLO.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP);
      else
        select nvl(sum(nvl(PER.PER_AMOUNT_D, 0) - nvl(PER.PER_AMOUNT_C, 0) ), 0) PER_AMOUNT_D
          into vResult
          from ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PER
             , ACS_PERIOD PER1
         where VER.VER_FIX_ASSETS = 1
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and GLO.FAM_FIXED_ASSETS_ID = aFixedAssetsId
           and PER.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
           and PER.ACS_PERIOD_ID = PER1.ACS_PERIOD_ID
           and PER1.PER_END_DATE <= aFyeEndDate
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
                    and GLO.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP);
      end if;
    else
      if aFyeEndDate is null then
        select nvl(sum(nvl(FIM.FIM_AMOUNT_LC_D, 0) - nvl(FIM.FIM_AMOUNT_LC_C, 0) ), 0)
          into vResult
          from FAM_IMPUTATION FIM
         where FIM.FAM_FIXED_ASSETS_ID = aFixedAssetsId
           and exists(
                      select 1
                        from FAM_VAL_IMPUTATION VIM
                       where VIM.FAM_IMPUTATION_ID = FIM.FAM_IMPUTATION_ID
                         and VIM.FAM_MANAGED_VALUE_ID = aManagedValueId)
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
                    and FIM.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP);
      else
        select nvl(sum(nvl(FIM.FIM_AMOUNT_LC_D, 0) - nvl(FIM.FIM_AMOUNT_LC_C, 0) ), 0)
          into vResult
          from FAM_IMPUTATION FIM
         where FIM.FAM_FIXED_ASSETS_ID = aFixedAssetsId
           and FIM.FIM_TRANSACTION_DATE <= aFyeEndDate
           and exists(
                      select 1
                        from FAM_VAL_IMPUTATION VIM
                       where VIM.FAM_IMPUTATION_ID = FIM.FAM_IMPUTATION_ID
                         and VIM.FAM_MANAGED_VALUE_ID = aManagedValueId)
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
                    and FIM.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP);
      end if;
    end if;

    return vResult;
  end GetStructureElemAmount;

  /**
  * Retour du montant amorti dans le premier exercice de l'en-t�te donn�,
  **/
  function GetFirstExerciseAmoAmount(aPlanHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type)
    return FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type
  is
    vResult FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type;
  begin
    select nvl(max(FPE_AMORTIZATION_LC), 0)
      into vResult
      from FAM_PLAN_EXERCISE
     where FAM_PLAN_HEADER_ID = aPlanHeaderId
       and sign(FAM_PLAN_EXERCISE_ID) = -1
       and FAM_PLAN_EXERCISE_ID = (select max(FAM_PLAN_EXERCISE_ID)
                                     from FAM_PLAN_EXERCISE
                                    where FAM_PLAN_HEADER_ID = aPlanHeaderId
                                      and sign(FAM_PLAN_EXERCISE_ID) = -1);

    return vResult;
  end GetFirstExerciseAmoAmount;

  /**
  * Teste existence de positions d'amortissement d�j� comptabilis� pour l'immobilisation et la valeur g�r�e donn�e
  **/
  function ExistAmortizedPositions(
    aFixedAssetsId  in FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId in FAM_VAL_IMPUTATION.FAM_MANAGED_VALUE_ID%type
  )
    return FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  is
    vResult FAM_IMPUTATION.FAM_IMPUTATION_ID%type;
  begin
    select nvl(max(FAM_IMPUTATION_ID), 0)
      into vResult
      from FAM_IMPUTATION FIM
     where FIM.FAM_FIXED_ASSETS_ID = aFixedAssetsId
       and FIM.C_FAM_TRANSACTION_TYP between '600' and '699'
       and exists(select 1
                    from FAM_VAL_IMPUTATION VIM
                   where VIM.FAM_IMPUTATION_ID = FIM.FAM_IMPUTATION_ID
                     and VIM.FAM_MANAGED_VALUE_ID = aManagedValueId);

    return vResult;
  end ExistAmortizedPositions;

  /**
  * Teste existence de plan d'amortissement A activer pour l'immobilisation et la valeur g�r�e donn�e
  **/
  function ExistFamPlanByManagedValue(
    aFixedAssetsId  in     FAM_PLAN_HEADER.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId in     FAM_PLAN_HEADER.FAM_MANAGED_VALUE_ID%type
  , aPlanStatus     in     FAM_PLAN_HEADER.C_AMO_PLAN_STATUS%type default '1'
  , aBlockingCode   in     FAM_PLAN_HEADER.C_FPH_BLOCKING_REASON%type
  , aHeaderId       out    FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  )
    return FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  is
    cursor crPlanHeader
    is
      select C_FPH_BLOCKING_REASON
           , FAM_PLAN_HEADER_ID
        from FAM_PLAN_HEADER
       where FAM_FIXED_ASSETS_ID = aFixedAssetsId
         and FAM_MANAGED_VALUE_ID = aManagedValueId
         and C_AMO_PLAN_STATUS = aPlanStatus;

    vCode   FAM_PLAN_HEADER.C_FPH_BLOCKING_REASON%type;
    vResult number(1);
  begin
    open crPlanHeader;

    fetch crPlanHeader
     into vCode
        , aHeaderId;

    if vCode is not null then
      if     (aBlockingCode = '00')
         and (    (vCode = '00')
              or (vCode = '01')
              or (vCode = '04') ) then
        vResult  := 1;
      elsif     (aBlockingCode = '04')
            and (vCode = '04') then
        vResult  := 4;
      elsif     (aBlockingCode = '09')
            and (vCode = '09') then
        vResult  := 9;
      else
        vResult  := 0;
      end if;
    else
      vResult  := 0;
    end if;

    return vResult;
  end ExistFamPlanByManagedValue;

  /**
  * Teste existence de plan d'amortissement pour TOUTES les valeurs g�r�es de l'immobilisation donn�
  **/
  function ExistFamPlan(
    aFixedAssetsId in FAM_PLAN_HEADER.FAM_FIXED_ASSETS_ID%type
  , aBlockingCode  in FAM_PLAN_HEADER.C_FPH_BLOCKING_REASON%type
  )
    return FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  is
    cursor crFamActive(aCurrentFixId in FAM_PLAN_HEADER.FAM_FIXED_ASSETS_ID%type)
    is
      select FIX.FAM_FIXED_ASSETS_ID
        from FAM_FIXED_ASSETS FIX
       where FIX.FAM_FIXED_ASSETS_ID = aCurrentFixId
         and FIX.C_FIXED_ASSETS_STATUS = '01'
         and exists(select 1
                      from FAM_IMPUTATION FIM
                     where FIM.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID);

    cursor crFamManagedValue(aFixAssetsId in FAM_PLAN_HEADER.FAM_FIXED_ASSETS_ID%type)
    is
      select APP.FAM_MANAGED_VALUE_ID
        from FAM_AMO_APPLICATION APP
           , FAM_AMORTIZATION_METHOD FAM
       where APP.FAM_FIXED_ASSETS_ID = aFixAssetsId
         and FAM.FAM_AMORTIZATION_METHOD_ID = APP.FAM_AMORTIZATION_METHOD_ID
         and FAM.AMO_AMORTIZATION_PLAN = 1;

    vFixedAssetsId  FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
    vManagedValueId FAM_AMO_APPLICATION.FAM_MANAGED_VALUE_ID%type;
    vHeaderId       FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type;
    vResult         FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type;
  begin
    open crFamActive(aFixedAssetsId);

    fetch crFamActive
     into vFixedAssetsId;

    if crFamActive%found then
      ---Valeur par d�faut pour les immob n'ayant pas de lien sur des m�thodes
      vResult  := 1;

      open crFamManagedValue(aFixedAssetsId);

      fetch crFamManagedValue
       into vManagedValueId;

      while(crFamManagedValue%found) loop
        if     (aBlockingCode = '00')
           and (vResult > 0) then
          vResult  := ExistFamPlanByManagedValue(aFixedAssetsId, vManagedValueId, '1', aBlockingCode, vHeaderId);
        elsif     (aBlockingCode = '04')
              and (vResult <> 4) then
          vResult  := ExistFamPlanByManagedValue(aFixedAssetsId, vManagedValueId, '1', aBlockingCode, vHeaderId);
        end if;

        fetch crFamManagedValue
         into vManagedValueId;
      end loop;

      close crFamManagedValue;
    else
      ---Valeur par d�faut pour les immob inactives
      vResult  := 1;
    end if;

    return vResult;
  end ExistFamPlan;

  /**
  * Teste si amortissement d�gressif (v�rifi�e par la pr�sence de transaction 6...dans l'�l�ment de base amortissement)
  **/
  function IsDecreasingPlan(aStructureElementId in FAM_ELEMENT_DETAIL.FAM_STRUCTURE_ELEMENT_ID%type)
    return number
  is
    vResult number(1);
  begin
    select count(*)
      into vResult
      from FAM_ELEMENT_DETAIL DET
     where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
       and C_FAM_TRANSACTION_TYP between '600' and '699'
       and rownum = 1;

    return vResult;
  end IsDecreasingPlan;

  procedure AmortizationPlan(
    aMinFixNumber in FAM_FIXED_ASSETS.FIX_NUMBER%type
  , aMaxFixNumber in FAM_FIXED_ASSETS.FIX_NUMBER%type
  )
  is
    /*Recherche des donn�es n�cessaires aux diff�rents calculs selon les bornes d�finies */
    cursor crFixedAssets(aMinNumber FAM_FIXED_ASSETS.FIX_NUMBER%type, aMaxNumber FAM_FIXED_ASSETS.FIX_NUMBER%type)
    is
      select   FIX.FAM_FIXED_ASSETS_ID   -- Immobilisation
             , AMO.FAM_AMORTIZATION_METHOD_ID   -- M�thode d'amortissement
             , AMO.AMO_ROUNDED_AMOUNT   -- Montant arrondi
             , AMO.C_AMORTIZATION_PERIOD   -- Cadence d'amortissment
             , AMO.C_AMORTIZATION_TYP   -- Type d'amortissment
             , AMO.C_ROUND_TYPE   -- Type d'arrondi
             , AAP.APP_AMORTIZATION_BEGIN   -- D�but d'amortissement
             , AAP.APP_AMORTIZATION_END   -- Fin d'amortissement
             , AAP.FAM_MANAGED_VALUE_ID   -- Valeur g�r�e
             , nvl(DEF.DEF_MIN_RESIDUAL_VALUE, 0) DEF_MIN_RESIDUAL_VALUE   -- Valeur r�siduelle minimum
             , case   --Taux 1 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('1', '3', '5', '6', '9', '60') then nvl(AAP.APP_LIN_AMORTIZATION
                                                                                      , DEF.DEF_LIN_AMORTIZATION
                                                                                       )
                 when AMO.C_AMORTIZATION_TYP in('2', '4') then nvl(AAP.APP_DEC_AMORTIZATION, DEF.DEF_DEC_AMORTIZATION)
                 else 0
               end Rate1
             , case   --Taux 2 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('5', '6', '9', '60') then nvl(AAP.APP_DEC_AMORTIZATION
                                                                            , DEF.DEF_DEC_AMORTIZATION
                                                                             )
                 else null
               end Rate2
             , case   --Coeeficient pour types 6,60
                 when AMO.C_AMORTIZATION_TYP in('6', '60') then nvl(AAP.DIC_FAM_COEFFICIENT_ID
                                                                  , DEF.DIC_FAM_COEFFICIENT_ID
                                                                   )
                 else null
               end COEFFICIENT
             , nvl(AAP.APP_INTEREST_RATE, DEF.DEF_INTEREST_RATE) INTEREST_RATE_1   -- Taux d'int�r�t 1 cascade Application / D�faut
             , nvl(AAP.APP_INTEREST_RATE_2, DEF.DEF_INTEREST_RATE_2) INTEREST_RATE_2   -- Taux d'int�r�t 2 cascade Application / D�faut
             ,
               -- Dur�e d'amortissement syst�matiquement calcul�e(100/taux1)m�me si renseign�e sur la fiche Arrondi � 2 d�c. comme d�finie
               round(100 /
                     decode(decode(AAP.APP_LIN_AMORTIZATION, 0, null, AAP.APP_LIN_AMORTIZATION)
                          , null, decode(DEF.DEF_LIN_AMORTIZATION, 0, null, DEF.DEF_LIN_AMORTIZATION)
                          , AAP.APP_LIN_AMORTIZATION
                           )
                   , 2
                    ) APP_MONTH_DURATION
             ,   --El�ments de structure n�cessaires au calcul selon cascade Cat�gories par valeur / valeur g�r�e
               nvl(DEF.FAM_STRUCTURE_ELEMENT1_ID, VAL.FAM_STRUCTURE_ELEMENT_ID) FAM_STRUCTURE_ELEMENT1_ID   -- Base amortissement 1
             , nvl(DEF.FAM_STRUCTURE_ELEMENT6_ID, VAL.FAM_STRUCTURE_ELEMENT6_ID) FAM_STRUCTURE_ELEMENT6_ID   -- Base amortissement 2
             , nvl(DEF.FAM_STRUCTURE_ELEMENT3_ID, VAL.FAM_STRUCTURE_ELEMENT3_ID) FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
             , nvl(DEF.FAM_STRUCTURE_ELEMENT2_ID, VAL.FAM_STRUCTURE_ELEMENT2_ID) FAM_STRUCTURE_ELEMENT2_ID   -- Base int�r�ts
             , nvl(DEF.FAM_STRUCTURE_ELEMENT4_ID, VAL.FAM_STRUCTURE_ELEMENT4_ID) FAM_STRUCTURE_ELEMENT4_ID   -- Acquisition
             , decode(nvl(AAP.APP_NEGATIVE_BASE,0),0, DEF.DEF_NEGATIVE_BASE, AAP.APP_NEGATIVE_BASE) APP_NEGATIVE_BASE
          from FAM_FIXED_ASSETS FIX
             , FAM_AMO_APPLICATION AAP
             , FAM_AMORTIZATION_METHOD AMO
             , FAM_DEFAULT DEF
             , FAM_MANAGED_VALUE VAL
         where FIX.FIX_NUMBER <= aMaxNumber
           and FIX.FIX_NUMBER >= aMinNumber
           and FIX.C_FIXED_ASSETS_STATUS = '01'
           and FIX.C_OWNERSHIP <> '9'
           and AAP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
           and AMO.FAM_AMORTIZATION_METHOD_ID = AAP.FAM_AMORTIZATION_METHOD_ID
           and AMO.AMO_AMORTIZATION_PLAN = 1
           and DEF.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
           and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_AMORTIZATION_METHOD_ID = AMO.FAM_AMORTIZATION_METHOD_ID
           and VAL.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
      order by FIX.FIX_NUMBER;

    tplFixedAssets crFixedAssets%rowtype;   --R�ceptionne les donn�es immob. du curseur
  begin
    --Parcours des immobilisations se trouvant entre les bornes d�finies
    open crFixedAssets(aMinFixNumber, aMaxFixNumber);

    fetch crFixedAssets
     into tplFixedAssets;

    while crFixedAssets%found loop
      gNegativeBase      := tplFixedAssets.APP_NEGATIVE_BASE;
      CalculateAmortizationPlan(tplFixedAssets.FAM_FIXED_ASSETS_ID   --Immobilisation
                              , tplFixedAssets.FAM_MANAGED_VALUE_ID   --Valeur g�r�e
                              , tplFixedAssets.FAM_AMORTIZATION_METHOD_ID   --M�thode amortissement
                              , tplFixedAssets.FAM_STRUCTURE_ELEMENT1_ID   --El�ment "Base amortissement"
                              , tplFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --El�ment "Base int�r�ts"
                              , tplFixedAssets.FAM_STRUCTURE_ELEMENT3_ID   --El�ment "Limite amortissement"
                              , tplFixedAssets.FAM_STRUCTURE_ELEMENT4_ID   --El�ment "Acquisition"
                              , tplFixedAssets.FAM_STRUCTURE_ELEMENT6_ID   --El�ment "Base amortissement 6"
                              , tplFixedAssets.C_AMORTIZATION_TYP   --Type amortissement
                              , tplFixedAssets.C_AMORTIZATION_PERIOD   --Cadence
                              , tplFixedAssets.APP_AMORTIZATION_BEGIN   --D�but amortissement
                              , tplFixedAssets.APP_MONTH_DURATION   --Dur�e amortissement
                              , tplFixedAssets.Rate1   --Taux 1
                              , tplFixedAssets.Rate2   --Taux 2
                              , tplFixedAssets.COEFFICIENT   --Coefficient
                              , tplFixedAssets.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                              , tplFixedAssets.C_ROUND_TYPE   --Type arrondi
                              , tplFixedAssets.AMO_ROUNDED_AMOUNT   --Montant arrondi
                              , 0
                              , 0
                               );

      fetch crFixedAssets
       into tplFixedAssets;
    end loop;

    close crFixedAssets;
  end AmortizationPlan;

  procedure InitExerciseTable(
    aStartDate       in     ACS_PLAN_YEAR.PYE_START_DATE%type
  , aExercise        in out TExercise
  , aExerciseCnt     in out number
  , aLastPlanYearNum out    ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
  )
  is
    tplExercises crExercises%rowtype;   --R�ceptionne les exercices du curseur
  begin
    open crExercises(aStartDate);

    fetch crExercises
     into tplExercises;

    while(crExercises%found) loop
      aExerciseCnt                              := aExerciseCnt + 1;
      aExercise(aExerciseCnt).ACS_PLAN_YEAR_ID  := tplExercises.ACS_PLAN_YEAR_ID;
      aExercise(aExerciseCnt).PYE_NO_EXERCISE   := tplExercises.PYE_NO_EXERCISE;
      aExercise(aExerciseCnt).PYE_START_DATE    := tplExercises.PYE_START_DATE;
      aExercise(aExerciseCnt).PYE_END_DATE      := tplExercises.PYE_END_DATE;
      aLastPlanYearNum                          := aExercise(aExerciseCnt).PYE_NO_EXERCISE;

      fetch crExercises
       into tplExercises;
    end loop;

    close crExercises;
  end InitExerciseTable;

  /**
  * Description  Proc�dure centrale de calcul des plans d'amortissement
  **/
  procedure CalculateAmortizationPlan(
    aFamFixedAssetsId     in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immobilisation
  , aFamManagedValueId    in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type   --Valeur g�r�e
  , aFamAmoMethodId       in FAM_AMORTIZATION_METHOD.FAM_AMORTIZATION_METHOD_ID%type   --M�thode amortissement
  , aStrElementId_1       in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --El�ment "Base amortissement"
  , aStrElementId_2       in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --El�ment "Base int�r�ts"
  , aStrElementId_3       in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --El�ment "Limite amortissement"
  , aStrElementId_4       in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --El�ment "Acquisition"
  , aStrElementId_6       in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --El�ment "Base amortissement 6"
  , aCAmortizationType    in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_TYP%type   --Type amortissement
  , aCAmortizationPeriod  in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type   --Cadence
  , aAmortizationBegin    in FAM_AMO_APPLICATION.APP_AMORTIZATION_BEGIN%type   --D�but amortissement
  , aAmortizationDuration in FAM_AMO_APPLICATION.APP_MONTH_DURATION%type   --Dur�e amortissement
  , aRate1                in FAM_AMO_APPLICATION.APP_LIN_AMORTIZATION%type   --Taux 1
  , aRate2                in FAM_AMO_APPLICATION.APP_DEC_AMORTIZATION%type   --Taux 2
  , aCoefficient          in FAM_AMO_APPLICATION.DIC_FAM_COEFFICIENT_ID%type   --Coefficient
  , aResidualValue        in FAM_DEFAULT.DEF_MIN_RESIDUAL_VALUE%type   --Valeur r�siduelle
  , aCRoundType           in FAM_AMORTIZATION_METHOD.C_ROUND_TYPE%type   --Type arrondi
  , aRoundAmount          in FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT%type   --Montant arrondi
  , aActivatePlan         in number
  , aIsBudget             in number   --Indique si position bud�tis�e (1) ou non(0)
  )
  is
    vExercise              TExercise;   --R�ceptionne les donn�es des exercices
    vCoveredDays           FAM_PLAN_EXERCISE.FPE_DAYS%type;   --Nombre de jours couverts dans l'exercice
    vAmortizationDays      FAM_PLAN_EXERCISE.FPE_DAYS%type;   --Nombre de jours d'amortissement
    vPlanHeaderId          FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type;   --R�ceptionne Id En-t�te cr��e
    vPlanExerciseId        FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type;   --Id exercice calcul courant
    vFamExerciseId         ACS_PLAN_YEAR.ACS_PLAN_YEAR_ID%type;   --Variable permettant de d�tecter le changement d'exercices durant le traitement de calcul
    vAmortizationStartDate FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BEGIN%type;   --Date d�but amortissement dans l'exercice courant
    vAmoEffectiveStartDate FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BEGIN%type;   --Date d�but amortissement effective ...pour les cas roumains (9,60) o� la dur�e chevauche 2 exercices
    vAmortizationEndDate   FAM_PLAN_EXERCISE.FPE_AMORTIZATION_END%type;   --Date fin amortissement dans l'exercice courant
    vAmoEffectiveEndDate   FAM_PLAN_EXERCISE.FPE_AMORTIZATION_END%type;   --Date fin amortissement effective ...pour les cas roumains (9,60) o� la dur�e chevauche 2 exercices
    vAmoEffectiveDays      FAM_PLAN_EXERCISE.FPE_DAYS%type;   --Nombre de jours d'amortissement effective
    vAmoCalculatedEndDate  FAM_AMO_APPLICATION.APP_AMORTIZATION_END%type;   --Date fin d'amortissement calcul�
    vAmortizationRate1     FAM_PLAN_EXERCISE.FPE_RATE%type;   --R�ceptionne taux d'amortissement 1
    vAmortizationRate2     FAM_PLAN_EXERCISE.FPE_RATE%type;   --R�ceptionne taux d'amortissement 1
    vAmoEffectiveRate1     FAM_PLAN_EXERCISE.FPE_RATE%type;   --R�ceptionne taux d'amortissement 1
    vLocalCurrency         FAM_PLAN_EXERCISE.ACS_ACS_FINANCIAL_CURRENCY_ID%type;   --Monnaie de base du montant de base
    vExerciseCounter       number(3);   --Compteur d'exercice
    vExercisesToPlan       number(2);   --Nombre d'exercice � planifier
    vExercisesToPlan1      number(2);   --Nombre d'exercice � planifier
    vExercisesToPlan2      number(2);   --Nombre d'exercice � planifier
    vType60                boolean;   --Indique le type d'amortissement 60
    vErrCode               number(1);
    vErrText               varchar2(5000);
    vLastExercise          boolean;   -- Indique si dernier exercice d'amortissement
    vLastPlanYearNum       ACS_PLAN_YEAR.PYE_NO_EXERCISE%type;   -- Dernier exercice de planification
    vResidualValue         FAM_DEFAULT.DEF_MIN_RESIDUAL_VALUE%type;   --Valeur r�siduelle
    vInsertedYearPos       number(3);   --Compteur d'exercice
  begin
    if     (GetStructureElemAmount(aFamFixedAssetsId, aFamManagedValueId, null, aStrElementId_4, aIsBudget) <> 0)
       and (aRate1 <> 0) then
      gAmoType           := aCAmortizationType;
      vType60            := gAmoType = '60';
      /** D�gressif th�orique (m�thode de type 1 ou 2 avec Base d'Amortissement tenant compte des amortissements pass�s / 6XX)
       *   Si aucune valeur r�siduelle minimum n'est indiqu�e sur la valeur g�r�e (FAM_DEFAULT.DEF_MIN_RESIDUAL_VALUE = 0 ou null):
            o Consid�rer que la valeur r�siduelle minimum est � 1.00
      **/
      vResidualValue     := nvl(aResidualValue, 0);

      if     (gAmoType in('1', '2') )
         and (vResidualValue = 0)
         and (FAM_AMORTIZATION_PLAN.IsDecreasingPlan(aStrElementId_1) = 1) then
        vResidualValue  := 1;
      end if;

      --Cr�ation d'une position d'en-t�te pour chaque immobilisation en tous les cas
      vPlanHeaderId      :=
        CreatePlanHeaderPosition(aFamFixedAssetsId
                               , aFamManagedValueId
                               , aFamAmoMethodId
                               , aStrElementId_1
                               , aStrElementId_2
                               , aStrElementId_3
                               , aStrElementId_4
                               , aStrElementId_6
                               , aIsBudget
                                );
      --Parcours des exercices et p�riodes de planification � partir de la date
      --d�but d'amortissement de l'immobilisation courante
      vFamExerciseId     := 0;
      vAmortizationDays  := 1;   --Initialis� pour "amorcer" le calcul
      vExerciseCounter   := 0;
      vLastExercise      := false;
      InitExerciseTable(aAmortizationBegin, vExercise, vExerciseCounter, vLastPlanYearNum);

      if ( (vExercise.count > 0)
           and (vExercise(1).PYE_NO_EXERCISE <> to_char(aAmortizationBegin, 'YYYY') ))
           or (vExercise.count = 0)
           then
        ACS_FUNCTION.FillPlanExercise(to_char(to_number(to_char(aAmortizationBegin, 'YYYY') ) - 1),
                                                      to_char(to_number(to_char(aAmortizationBegin, 'YYYY') ) + 1)
                                                      );
        vExerciseCounter  := 0;
        InitExerciseTable(aAmortizationBegin, vExercise, vExerciseCounter, vLastPlanYearNum);
      end if;

      vExerciseCounter   := 1;

      while(vAmortizationDays > 0) loop
        if (vExercise.count > 0) then
          if (vExercise(vExerciseCounter).ACS_PLAN_YEAR_ID <> vFamExerciseId) then
            vAmortizationStartDate  := vExercise(vExerciseCounter).PYE_START_DATE;
            vAmortizationEndDate    := vExercise(vExerciseCounter).PYE_END_DATE;
            vCoveredDays            := 360;   --Nombre de jours couvert / d�faut
            vAmortizationRate1      := aRate1;   --Taux de calcul / d�faut

            --Traitement particulier au type 6
            if     (gAmoType = '6')
               and (not aAmortizationDuration is null) then
              --Calcul des dates d�but et fin selon date d�but amortissement + le nombre d'ann�e en cours
              --Amortissement est calcul� pour une p�riode de 12 mois compl�tes
              if vExerciseCounter = 1 then
                vAmortizationStartDate  := aAmortizationBegin;
              else
                vAmortizationStartDate  := vExercise(vExerciseCounter).PYE_START_DATE;
              end if;

              --Calcul de la date de fin d'amortissement selon date d�but amortissement et dur�e amortissement
              vAmoCalculatedEndDate  := GetAmortizationEndDate(aAmortizationDuration, aAmortizationBegin);
              --Calcul du nombre d'exercice � amortir
              vExercisesToPlan       :=
                                 GetExercisesToPlan(vExercise(vExerciseCounter).ACS_PLAN_YEAR_ID, vAmoCalculatedEndDate);
              --Calcul du nombre de jours prise en consid�ration
              vCoveredDays           :=
                                     GetCoveredDays(vExercise(vExerciseCounter).ACS_PLAN_YEAR_ID, vAmoCalculatedEndDate);
              --R�ception du nombre de jours � amortir...Les bornes sont les date d�but et fin d'exercice
              vAmortizationDays      :=
                GetAmortizationDays(vExercise(vExerciseCounter).PYE_START_DATE
                                  , vExercise(vExerciseCounter).PYE_END_DATE
                                  , aAmortizationBegin
                                  , vAmoCalculatedEndDate
                                   );
              --Calcul taux amortissement effectif pour le calcul */
              vAmortizationRate1     := 100 / vExercisesToPlan;

              if vAmortizationRate1 <(aRate1 * to_number(aCoefficient) ) then
                vAmortizationRate1  := aRate1 * to_number(aCoefficient);
              end if;
            elsif     (gAmoType = '60')
                  and (not aAmortizationDuration is null) then
              vLastExercise           := false;

              --Calcul des dates d�but et fin selon date d�but amortissement + le nombre d'ann�e en cours
              --Amortissement est calcul� pour une p�riode de 12 mois compl�tes
              if vExerciseCounter = 1 then
                vAmortizationStartDate  := aAmortizationBegin;
              else
                vAmortizationStartDate  := vExercise(vExerciseCounter).PYE_START_DATE;
              end if;

              vAmoEffectiveStartDate  :=
                to_date(to_char(aAmortizationBegin, 'DD.MM.') ||
                        to_char(to_number(to_char(aAmortizationBegin, 'YYYY') ) + vExerciseCounter - 1)
                      , 'DD.MM.YYYY'
                       );
              vAmoEffectiveEndDate    :=
                to_date(to_char(aAmortizationBegin, 'DD.MM.') ||
                        to_char(to_number(to_char(aAmortizationBegin, 'YYYY') ) + vExerciseCounter)
                      , 'DD.MM.YYYY'
                       ) -
                1;
              --Calcul de la date de fin d'amortissement selon date d�but amortissement et dur�e amortissement
              vAmoCalculatedEndDate   := GetAmortizationEndDate(aAmortizationDuration, aAmortizationBegin);
              --Ram�ne la date de fin d'amortissement � la date de fin amortissement calcul� pour le dernier exercice
              vAmoEffectiveEndDate    := least(vAmoEffectiveEndDate, vAmoCalculatedEndDate);
              vAmortizationEndDate    := vAmoEffectiveEndDate;

              --Calcul du nombre d'exercice � amortir
              --vExercisesToPlan1 permet de calculer les taux utilis�s dans le calcul effectif pour
              --exercices chevauchant 2 ann�es civiles.
              --vExercisesToPlan2 permet la cr�ation,par le caclul du taux 2, de la derni�re ann�e civile
              --qui termine l'amortissement et ainsi de rattacher les p�riodes cr��es dans le calcul effectif.
              if (aAmortizationDuration - vExerciseCounter + 1) = 0 then
                vExercisesToPlan1  := 1;
              else
                vExercisesToPlan1  := aAmortizationDuration - vExerciseCounter + 1;
              end if;

              if (aAmortizationDuration - vExerciseCounter + 2) = 0 then
                vExercisesToPlan2  := 1;
              else
                vExercisesToPlan2  := aAmortizationDuration - vExerciseCounter + 2;
              end if;

              --Calcul du nombre de jours prise en consid�ration
              vCoveredDays            :=
                                     GetCoveredDays(vExercise(vExerciseCounter).ACS_PLAN_YEAR_ID, vAmoCalculatedEndDate);
              --R�ception du nombre de jours � amortir...Les bornes sont les date d�but et fin d'exercice pour correpondre aux position d'exercice cr��es
              vAmortizationDays       :=
                GetAmortizationDays(vExercise(vExerciseCounter).PYE_START_DATE
                                  , vExercise(vExerciseCounter).PYE_END_DATE
                                  , aAmortizationBegin
                                  , vAmoCalculatedEndDate
                                   );
              vAmoEffectiveDays       :=
                GetAmortizationDays(vAmoEffectiveStartDate
                                  , vAmoEffectiveEndDate
                                  , aAmortizationBegin
                                  , vAmoCalculatedEndDate
                                   );
              --Calcul taux amortissement effectif pour le calcul */
              vAmortizationRate1      := 100 / vExercisesToPlan2;
              vAmortizationRate2      := 100 / vExercisesToPlan1;

              if vAmortizationRate1 <(aRate1 * to_number(aCoefficient) ) then
                vAmortizationRate1  := aRate1 * to_number(aCoefficient);
              end if;

              if vAmortizationRate2 <(aRate1 * to_number(aCoefficient) ) then
                vAmortizationRate2  := aRate1 * to_number(aCoefficient);
              end if;

              vAmoEffectiveRate1      := vAmortizationRate2;

              if     (to_number(to_char(vAmoCalculatedEndDate, 'YYYY') ) =
                                                to_number(to_char(vExercise(vExerciseCounter).PYE_END_DATE, 'YYYY') )
                                                + 1
                     )
                 and (to_char(vAmoEffectiveStartDate, 'YYYY') <> to_char(vAmoEffectiveEndDate, 'YYYY') ) then
                vAmoEffectiveRate1  := 100;
              end if;
            elsif(gAmoType = '9') then
              vLastExercise           := false;

              --Calcul des dates d�but et fin selon date d�but amortissement + le nombre d'ann�e en cours
              --Amortissement est calcul� pour une p�riode de 12 mois compl�tes
              if vExerciseCounter = 1 then
                vAmortizationStartDate  := aAmortizationBegin;
                vAmortizationRate1      := aRate2;
                vAmoEffectiveRate1      := vAmortizationRate1;
              else
                vAmortizationStartDate  := vExercise(vExerciseCounter).PYE_START_DATE;
                vAmortizationRate1      := 100 /( (100 / aRate1) );   --Uniquement pour que l'amortissement aille jusqu'� la vraie date de fin
                vAmoEffectiveRate1      := 100 /( (100 / aRate1) - 1);
              end if;

              vAmoEffectiveStartDate  :=
                to_date(to_char(aAmortizationBegin, 'DD.MM.') ||
                        to_char(to_number(to_char(aAmortizationBegin, 'YYYY') ) + vExerciseCounter - 1)
                      , 'DD.MM.YYYY'
                       );
              vAmoEffectiveEndDate    :=
                to_date(to_char(aAmortizationBegin, 'DD.MM.') ||
                        to_char(to_number(to_char(aAmortizationBegin, 'YYYY') ) + vExerciseCounter)
                      , 'DD.MM.YYYY'
                       ) -
                1;
              --Calcul de la date de fin d'amortissement selon date d�but amortissement et dur�e amortissement
              vAmoCalculatedEndDate   := GetAmortizationEndDate(100 / aRate1, aAmortizationBegin);
              --Calcul du nombre d'exercice � amortir
              vExercisesToPlan        :=
                                 GetExercisesToPlan(vExercise(vExerciseCounter).ACS_PLAN_YEAR_ID, vAmoCalculatedEndDate);
              --Calcul du nombre de jours prise en consid�ration
              vCoveredDays            :=
                                     GetCoveredDays(vExercise(vExerciseCounter).ACS_PLAN_YEAR_ID, vAmoCalculatedEndDate);
              --R�ception du nombre de jours � amortir...Les bornes sont les date d�but et fin d'exercice pour correpondre aux position d'exercice cr��es
              vAmortizationDays       :=
                GetAmortizationDays(vExercise(vExerciseCounter).PYE_START_DATE
                                  , vExercise(vExerciseCounter).PYE_END_DATE
                                  , aAmortizationBegin
                                  , vAmoCalculatedEndDate
                                   );
              vAmortizationEndDate    := least(vAmortizationEndDate, vAmoCalculatedEndDate);
              vAmoEffectiveDays       :=
                GetAmortizationDays(vAmoEffectiveStartDate
                                  , vAmoEffectiveEndDate
                                  , aAmortizationBegin
                                  , vAmoCalculatedEndDate
                                   );
            elsif     (gAmoType <> '6')
                  and (gAmoType <> '60') then
              vAmoCalculatedEndDate  := vAmortizationEndDate;

              if    (     (gAmoType = 1)
                     and (IsDecreasingPlan(aStrElementId_1) = 0) )
                 or (     (gAmoType = 3)
                     and (    (IsDecreasingPlan(aStrElementId_1) = 0)
                          or (IsDecreasingPlan(aStrElementId_6) = 0) )
                    )
                 or (     (gAmoType = 2)
                     and (IsDecreasingPlan(aStrElementId_1) = 0) )
                 or (     (gAmoType = 4)
                     and (    (IsDecreasingPlan(aStrElementId_1) = 0)
                          or (IsDecreasingPlan(aStrElementId_6) = 0) )
                    ) then
                vAmoCalculatedEndDate  := GetAmortizationEndDate(100 / aRate1, aAmortizationBegin);
              elsif(     (gAmoType = 5)
                    and (    (IsDecreasingPlan(aStrElementId_1) = 0)
                         or (IsDecreasingPlan(aStrElementId_6) = 0) )
                   ) then
                if     (IsDecreasingPlan(aStrElementId_1) = 0)
                   and (IsDecreasingPlan(aStrElementId_6) = 0) then
                  vAmoCalculatedEndDate  := GetAmortizationEndDate(100 / aRate1, aAmortizationBegin);

                  if vAmoCalculatedEndDate > GetAmortizationEndDate(100 / aRate2, aAmortizationBegin) then
                    vAmoCalculatedEndDate  := GetAmortizationEndDate(100 / aRate2, aAmortizationBegin);
                  end if;
                elsif(IsDecreasingPlan(aStrElementId_1) = 0) then
                  vAmoCalculatedEndDate  := GetAmortizationEndDate(100 / aRate1, aAmortizationBegin);
                else
                  vAmoCalculatedEndDate  := GetAmortizationEndDate(100 / aRate2, aAmortizationBegin);
                end if;
              end if;

              if vExerciseCounter = 1 then
                vAmortizationStartDate  := aAmortizationBegin;
              else
                vAmortizationStartDate  := vExercise(vExerciseCounter).PYE_START_DATE;
              end if;

              --R�ception du nombre de jours � amortir
              vAmortizationDays      :=
                GetAmortizationDays(vExercise(vExerciseCounter).PYE_START_DATE
                                  , vExercise(vExerciseCounter).PYE_END_DATE
                                  , aAmortizationBegin
                                  , least(vAmoCalculatedEndDate, vAmortizationEndDate)
                                   );
              vLastExercise          :=
                vAmoCalculatedEndDate between vExercise(vExerciseCounter).PYE_START_DATE
                                          and vExercise(vExerciseCounter).PYE_END_DATE;

              --Si la m�thode est de type 1 , 2, 3, 4 ou 5.
              --Si la base d'amortissement fait que l'on suit une m�thode d�gressive "th�orique pure".
              --Amortir jusqu'� atteinte:
              --   De la limite d'amortissement --> Si limite atteinte, alors arr�ter.
              --   De la valeur r�siduelle minimum --> Si valeur minimum atteinte, alors tout amortir sur la p�riode concern�e.
              --   Des exercices/p�riodes planifi�es --> Amortir jusqu'� la derni�re p�riode planifi�e connue.
              if    (     (gAmoType = 1)
                     and (IsDecreasingPlan(aStrElementId_1) = 1) )
                 or (     (gAmoType = 2)
                     and (IsDecreasingPlan(aStrElementId_1) = 1) )
                 or (     (gAmoType = 3)
                     and (    (IsDecreasingPlan(aStrElementId_1) = 1)
                          or (IsDecreasingPlan(aStrElementId_6) = 1) )
                    )
                 or (     (gAmoType = 4)
                     and (    (IsDecreasingPlan(aStrElementId_1) = 1)
                          or (IsDecreasingPlan(aStrElementId_6) = 1) )
                    )
                 or (     (gAmoType = 5)
                     and (    (IsDecreasingPlan(aStrElementId_1) = 1)
                          or (IsDecreasingPlan(aStrElementId_6) = 1) )
                    ) then
                vLastExercise  := false;
              end if;
            end if;

            --Principe de calcul...
            --1� Calcul standard avec dates exercice "civiles",taux 1, taux 2 selon taux d�finis et / ou selon le nombre d'exercice � amortir
            --pour types roumains(9,60)
            --      2� Calcul avec dates r�elles de d�but amortissement et fin amortissement et taux y relatifs
            --      3� Les positions de p�riodes cr�es au point 2 sont ensuite rattach�es aux exercice s'y reportant cr�es au point 1 => garanti
            --         date exercices / coupures des p�riodes et montants.
            vPlanExerciseId         := 0;
            CalculateExerciseAmortization(vPlanHeaderId   --En-T�te courant
                                        , vPlanExerciseId   --Id position d'exercice cr��e
                                        , aFamFixedAssetsId   --Immobilisation courante
                                        , aFamManagedValueId   --Valeur g�r�e courante
                                        , aStrElementId_1   --El�m. Base amortissement 1
                                        , aStrElementId_3   --El�m. Limite amortissement
                                        , aStrElementId_6   --El�m. Base amortissement 2
                                        , vResidualValue   --Valeur r�siduelle
                                        , aCRoundType   --Type arrondi
                                        , aRoundAmount   --Montant arrondi
                                        , vCoveredDays   --Jours couverts
                                        , vAmortizationDays   --Jours amortis
                                        , vLocalCurrency   --Monnaie de base
                                        , vExercise(vExerciseCounter).PYE_NO_EXERCISE   --Num�ro exercice
                                        , vExercise(vExerciseCounter).PYE_START_DATE   --Date d�but exercice
                                        , vExercise(vExerciseCounter).PYE_END_DATE   --Date fin exercice
                                        , vAmortizationStartDate   --D�but amortissement dans l'exercice
                                        , vAmoCalculatedEndDate   --Fin amortissement dans l'exercice
                                        , vLastExercise
                                        , vAmortizationRate1   --Taux amortissement 1
                                        , aRate2   --Taux amortissement 2
                                        , false   --Calcul selon type roumain
                                        , aIsBudget
                                         );
            --R�partition des exercices sur les p�riodes
            CalculatePeriodAmortization(vPlanExerciseId   --Exercice li�
                                      , vExercise(vExerciseCounter).PYE_START_DATE   --D�but exercice
                                      , vExercise(vExerciseCounter).PYE_END_DATE   --Fin exercice
                                      , aCAmortizationPeriod   --Cadence
                                      , false   --Calcul selon type roumain
                                       );

            if    (gAmoType = '60')
               or (gAmoType = '9') then
              vPlanExerciseId  := 0;
              CalculateExerciseAmortization(vPlanHeaderId   --En-T�te courant
                                          , vPlanExerciseId   --Id position d'exercice cr��e
                                          , aFamFixedAssetsId   --Immobilisation courante
                                          , aFamManagedValueId   --Valeur g�r�e courante
                                          , aStrElementId_1   --El�m. Base amortissement 1
                                          , aStrElementId_3   --El�m. Limite amortissement
                                          , aStrElementId_6   --El�m. Base amortissement 2
                                          , vResidualValue   --Valeur r�siduelle
                                          , aCRoundType   --Type arrondi
                                          , aRoundAmount   --Montant arrondi
                                          , vCoveredDays   --Jours couverts
                                          , vAmoEffectiveDays   --Jours amortis
                                          , vLocalCurrency   --Monnaie de base
                                          , vExercise(vExerciseCounter).PYE_NO_EXERCISE   --Num�ro exercice
                                          , vExercise(vExerciseCounter).PYE_START_DATE   --Date d�but exercice
                                          , vExercise(vExerciseCounter).PYE_END_DATE   --Date fin exercice
                                          , vAmoEffectiveStartDate   --D�but amortissement dans l'exercice
                                          , vAmoEffectiveEndDate   --Fin amortissement dans l'exercice
                                          , (vAmoEffectiveEndDate = vAmoCalculatedEndDate)
                                          , vAmoEffectiveRate1   --Taux amortissement 1
                                          , aRate2   --Taux amortissement 2
                                          , true   --Calcul selon type roumain
                                          , aIsBudget
                                           );
              CalculatePeriodAmortization(vPlanExerciseId   --Exercice li�
                                        , vAmoEffectiveStartDate   --D�but exercice
                                        , least(vAmoEffectiveEndDate, vAmoCalculatedEndDate)   --Fin exercice
                                        , aCAmortizationPeriod   --Cadence
                                        , true   --Calcul selon type roumain
                                         );
            end if;

            vFamExerciseId          := vExercise(vExerciseCounter).ACS_PLAN_YEAR_ID;

            if (vAmortizationDays > 0) then
              --D�passement des exercices existantes == > Cr�ation nouvel exercice
              if (vExercise(vExerciseCounter).PYE_NO_EXERCISE = vLastPlanYearNum) then
                vLastPlanYearNum  := vLastPlanYearNum + 1;
                ACS_FUNCTION.FillPlanExercise(vLastPlanYearNum, vLastPlanYearNum);
                InitExerciseTable(vExercise(vExerciseCounter).PYE_END_DATE + 1
                                , vExercise
                                , vExerciseCounter
                                , vLastPlanYearNum
                                 );
              --Trou dasn la suite des exercices == > Cr�ation nouvel exercice
              elsif(vExercise(vExerciseCounter).PYE_NO_EXERCISE + 1) <>
                                                                       (vExercise(vExerciseCounter + 1).PYE_NO_EXERCISE
                                                                       ) then
                vInsertedYearPos  := vExerciseCounter;
                ACS_FUNCTION.FillPlanExercise( (vExercise(vExerciseCounter).PYE_NO_EXERCISE + 1)
                                            , (vExercise(vExerciseCounter).PYE_NO_EXERCISE + 1)
                                             );
                InitExerciseTable(vExercise(vExerciseCounter).PYE_END_DATE + 1
                                , vExercise
                                , vExerciseCounter
                                , vLastPlanYearNum
                                 );
                --L'ajout du nouvel exercice interm�diaire doit nous positionner sur ce m�me record
                vExerciseCounter  := vInsertedYearPos + 1;
              else
                vExerciseCounter  := vExerciseCounter + 1;
              end if;
            end if;
          end if;
        else
          ACS_FUNCTION.FillPlanExercise(to_char(aAmortizationBegin, 'YYYY'), to_char(aAmortizationBegin, 'YYYY') );
          InitExerciseTable(aAmortizationBegin, vExercise, vExerciseCounter, vLastPlanYearNum);
        end if;
      end loop;

      --Liaison des p�riodes de aux exercices s'y reportant et m�j des donn�es.
      if    (gAmoType = '60')
         or (gAmoType = '9') then
        LinkCalculatedPeriod(vPlanHeaderId, vAmoEffectiveRate1);
      end if;

      if aIsBudget = 0 then
        if FAM_AMORTIZATION_PLAN.ExistAmortizedPositions(aFamFixedAssetsId, aFamManagedValueId) = 0 then
          ValidatePlan(vPlanHeaderId, vErrCode, vErrText, 1);
        else
          ValidatePlan(vPlanHeaderId, vErrCode, vErrText, aActivatePlan);
        end if;
      end if;
    end if;
  end CalculateAmortizationPlan;

      /**
  * Cr�ation des positions du plan d'amortissement
  **/
  function CreatePlanHeaderPosition(
    aFixedAssetsId        in FAM_PLAN_HEADER.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId       in FAM_PLAN_HEADER.FAM_MANAGED_VALUE_ID%type
  , aAmortizationMethodId in FAM_PLAN_HEADER.FAM_AMORTIZATION_METHOD_ID%type
  , aStructurElemId1      in FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT1_ID%type
  , aStructurElemId2      in FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT2_ID%type
  , aStructurElemId3      in FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT3_ID%type
  , aStructurElemId4      in FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT4_ID%type
  , aStructurElemId6      in FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT6_ID%type
  , aIsBudget             in number   --Indique si position bud�tis�e (1) ou non(0)
  )
    return FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  is
    vResult FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type;
  begin
    -- 1� Historier tous les plans existants pour l'immob et la valeur g�r�e actuelle
    update FAM_PLAN_HEADER
       set C_AMO_PLAN_STATUS = '2'
     where FAM_FIXED_ASSETS_ID = aFixedAssetsId
       and FAM_MANAGED_VALUE_ID = aManagedValueId;

    -- 2� Cr�er le nouveau plan pour l'immob et la valeur g�r�e actuelle
    select init_id_seq.nextval
      into vResult
      from dual;

    insert into FAM_PLAN_HEADER
                (FAM_PLAN_HEADER_ID
               , FAM_FIXED_ASSETS_ID
               , FAM_MANAGED_VALUE_ID
               , FAM_AMORTIZATION_METHOD_ID
               , FAM_STRUCTURE_ELEMENT1_ID
               , FAM_STRUCTURE_ELEMENT2_ID
               , FAM_STRUCTURE_ELEMENT3_ID
               , FAM_STRUCTURE_ELEMENT4_ID
               , FAM_STRUCTURE_ELEMENT6_ID
               , C_AMO_PLAN_STATUS
               , C_INACTIVATION_REASON
               , C_FPH_BLOCKING_REASON
               , FPH_USER
               , A_DATECRE
               , A_IDCRE
                )
         values (vResult
               , aFixedAssetsId
               , aManagedValueId
               , aAmortizationMethodId
               , aStructurElemId1
               , aStructurElemId2
               , aStructurElemId3
               , aStructurElemId4
               , aStructurElemId6
               , decode(aIsBudget, 1, '9', '0')
               , null
               , decode(aIsBudget, 1, '09', '01')
               , null
               , sysdate
               , gUserIni
                );

    return vResult;
  end CreatePlanHeaderPosition;

  /**
  * Cr�ation des positions du plan d'amortissement
  **/
  function CreatePlanExercisePosition(
    aPlanHeaderId         in FAM_PLAN_EXERCISE.FAM_PLAN_HEADER_ID%type
  , aExerciseNumber       in FAM_PLAN_EXERCISE.PYE_NO_EXERCISE%type
  , aExerciseStartDate    in FAM_PLAN_EXERCISE.PYE_START_DATE%type
  , aExerciseEndDate      in FAM_PLAN_EXERCISE.PYE_END_DATE%type
  , aExerciseElm1Amount   in FAM_PLAN_EXERCISE.FPE_ELEM_1_AMOUNT%type
  , aExerciseElm6Amount   in FAM_PLAN_EXERCISE.FPE_ELEM_6_AMOUNT%type
  , aExerciseBaseAmountLC in FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type
  , aExerciseAmoAmountLC  in FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type
  , aExerciseAmoStart     in FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BEGIN%type
  , aExerciseAmoEnd       in FAM_PLAN_EXERCISE.FPE_AMORTIZATION_END%type
  , aExerciseAmoRate      in FAM_PLAN_EXERCISE.FPE_RATE%type
  , aExerciseAmoDays      in FAM_PLAN_EXERCISE.FPE_DAYS%type
  , aExerciseLC           in FAM_PLAN_EXERCISE.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aType60               in boolean
  )
    return FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type
  is
    vResult             FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type;
    vExerciseElm2Amount FAM_PLAN_EXERCISE.FPE_ELEM_2_AMOUNT%type;
    vExerciseElm3Amount FAM_PLAN_EXERCISE.FPE_ELEM_3_AMOUNT%type;
    vExerciseElm4Amount FAM_PLAN_EXERCISE.FPE_ELEM_4_AMOUNT%type;
  begin
    select init_id_seq.nextval
      into vResult
      from dual;

    --Les id des types roumains(9,60) sont n�gatifs....sont supprim�es par la suite
    if aType60 then
      vResult  := vResult * -1;
    end if;

    --Recherche des montants des �l�ments 2,3,4(acquisition, int�r�ts, limite amortissement)
    --les montants �l�ments de base amortissement �tant donn�s en param�tre
    select nvl(sum(nvl(FIM2.FIM_AMOUNT_LC_D, 0) - nvl(FIM2.FIM_AMOUNT_LC_C, 0) ), 0)
         , nvl(sum(nvl(FIM3.FIM_AMOUNT_LC_D, 0) - nvl(FIM3.FIM_AMOUNT_LC_C, 0) ), 0)
         , nvl(sum(nvl(FIM4.FIM_AMOUNT_LC_D, 0) - nvl(FIM4.FIM_AMOUNT_LC_C, 0) ), 0)
      into vExerciseElm2Amount
         , vExerciseElm3Amount
         , vExerciseElm4Amount
      from FAM_IMPUTATION FIM2
         , FAM_IMPUTATION FIM3
         , FAM_IMPUTATION FIM4
         , FAM_PLAN_HEADER FPH
     where FPH.FAM_PLAN_HEADER_ID = aPlanHeaderId
       and FIM2.FAM_FIXED_ASSETS_ID = FPH.FAM_FIXED_ASSETS_ID
       and FIM2.FIM_TRANSACTION_DATE <= aExerciseAmoEnd
       and exists(
             select 1
               from FAM_ELEMENT_DETAIL DET
              where DET.FAM_STRUCTURE_ELEMENT_ID = FPH.FAM_STRUCTURE_ELEMENT2_ID
                and FIM2.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
       and exists(
             select 1
               from FAM_VAL_IMPUTATION VIM
              where VIM.FAM_IMPUTATION_ID = FIM2.FAM_IMPUTATION_ID
                and VIM.FAM_MANAGED_VALUE_ID = FPH.FAM_MANAGED_VALUE_ID)
       and FIM3.FAM_FIXED_ASSETS_ID = FPH.FAM_FIXED_ASSETS_ID
       and FIM3.FIM_TRANSACTION_DATE <= aExerciseAmoEnd
       and exists(
             select 1
               from FAM_ELEMENT_DETAIL DET
              where DET.FAM_STRUCTURE_ELEMENT_ID = FPH.FAM_STRUCTURE_ELEMENT3_ID
                and FIM3.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
       and exists(
             select 1
               from FAM_VAL_IMPUTATION VIM
              where VIM.FAM_IMPUTATION_ID = FIM3.FAM_IMPUTATION_ID
                and VIM.FAM_MANAGED_VALUE_ID = FPH.FAM_MANAGED_VALUE_ID)
       and FIM4.FAM_FIXED_ASSETS_ID = FPH.FAM_FIXED_ASSETS_ID
       and FIM4.FIM_TRANSACTION_DATE <= aExerciseAmoEnd
       and exists(
             select 1
               from FAM_ELEMENT_DETAIL DET
              where DET.FAM_STRUCTURE_ELEMENT_ID = FPH.FAM_STRUCTURE_ELEMENT4_ID
                and FIM4.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
       and exists(
             select 1
               from FAM_VAL_IMPUTATION VIM
              where VIM.FAM_IMPUTATION_ID = FIM4.FAM_IMPUTATION_ID
                and VIM.FAM_MANAGED_VALUE_ID = FPH.FAM_MANAGED_VALUE_ID);

    insert into FAM_PLAN_EXERCISE
                (FAM_PLAN_EXERCISE_ID
               , FAM_PLAN_HEADER_ID
               , PYE_NO_EXERCISE
               , PYE_START_DATE
               , PYE_END_DATE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , FPE_ELEM_1_AMOUNT
               , FPE_ELEM_2_AMOUNT
               , FPE_ELEM_3_AMOUNT
               , FPE_ELEM_4_AMOUNT
               , FPE_ELEM_6_AMOUNT
               , FPE_AMORTIZATION_BASE_LC
               , FPE_AMORTIZATION_BASE_FC
               , FPE_RATE
               , FPE_DAYS
               , FPE_AMORTIZATION_LC
               , FPE_AMORTIZATION_FC
               , FPE_ADAPTED_AMO_LC
               , FPE_ADAPTED_AMO_FC
               , FPE_INTEREST_BASE
               , FPE_INTEREST_RATE_1
               , FPE_INTEREST_RATE_2
               , FPE_INTEREST_AMOUNT_1
               , FPE_INTEREST_AMOUNT_2
               , FPE_AMORTIZATION_BEGIN
               , FPE_AMORTIZATION_END
               , A_DATECRE
               , A_IDCRE
                )
         values (vResult
               , aPlanHeaderId
               , aExerciseNumber
               , aExerciseStartDate
               , aExerciseEndDate
               , aExerciseLC
               , aExerciseLC
               , aExerciseElm1Amount
               , vExerciseElm2Amount
               , vExerciseElm3Amount
               , vExerciseElm4Amount
               , aExerciseElm6Amount
               , aExerciseBaseAmountLC
               , 0
               , aExerciseAmoRate
               , aExerciseAmoDays
               , aExerciseAmoAmountLC
               , 0
               , aExerciseAmoAmountLC
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , aExerciseAmoStart
               , aExerciseAmoEnd
               , sysdate
               , gUserIni
                );

    return vResult;
  end CreatePlanExercisePosition;

  /**
  * Description  Cr�ation des positions de p�riode du plan d'amortissement
  **/
  function CreateCalculatedPlanPeriod(
    aPlanExerciseId     in FAM_PLAN_PERIOD.FAM_PLAN_EXERCISE_ID%type
  , aPeriodNumber       in FAM_PLAN_PERIOD.APP_NO_PERIOD%type
  , aPeriodStartDate    in FAM_PLAN_PERIOD.APP_START_DATE%type
  , aPeriodEndDate      in FAM_PLAN_PERIOD.APP_END_DATE%type
  , aPeriodAmoStartDate in FAM_PLAN_PERIOD.FPP_AMORTIZATION_BEGIN%type
  , aPeriodAmoEndDate   in FAM_PLAN_PERIOD.FPP_AMORTIZATION_END%type
  , aPeriodDays         in FAM_PLAN_PERIOD.FPP_DAYS%type
  , aPeriodBaseAmountLC in FAM_PLAN_PERIOD.FPP_AMORTIZATION_BASE_LC%type
  , aPeriodAmoAmountLC  in FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type
  )
    return FAM_PLAN_PERIOD.FAM_PLAN_PERIOD_ID%type
  is
    vResult FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type;
  begin
    select init_id_seq.nextval
      into vResult
      from dual;

    insert into FAM_PLAN_PERIOD
                (FAM_PLAN_PERIOD_ID
               , FAM_PLAN_EXERCISE_ID
               , APP_NO_PERIOD
               , APP_START_DATE
               , APP_END_DATE
               , FPP_DAYS
               , FPP_AMORTIZATION_BASE_LC
               , FPP_AMORTIZATION_BASE_FC
               , FPP_AMORTIZATION_LC
               , FPP_AMORTIZATION_FC
               , FPP_ADAPTED_AMO_LC
               , FPP_ADAPTED_AMO_FC
               , FPP_AMORTIZATION_BEGIN
               , FPP_AMORTIZATION_END
               , A_DATECRE
               , A_IDCRE
                )
         values (vResult
               , aPlanExerciseId
               , aPeriodNumber
               , aPeriodStartDate
               , aPeriodEndDate
               , aPeriodDays
               , aPeriodBaseAmountLC
               , 0
               , aPeriodAmoAmountLC
               , 0
               , aPeriodAmoAmountLC
               , 0
               , aPeriodAmoStartDate
               , aPeriodAmoEndDate
               , sysdate
               , gUserIni
                );

    return vResult;
  end CreateCalculatedPlanPeriod;

  /**
  * Retour des montants d'amortissement d�j� calcul�s dans le m�me process pour le plan donn�
  * selon que l'on g�re la base 1 ou 2
  **/
  procedure GetPlanedPosAmount(
    aPlanHeaderId in     FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aType60       in     boolean
  , aPlaAmountLC1 out    FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type
  , aPlaAmountLC2 out    FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type
  )
  is
    vAmoTransaction1 FAM_ELEMENT_DETAIL.FAM_ELEMENT_DETAIL_ID%type;
    vAmoTransaction6 FAM_ELEMENT_DETAIL.FAM_ELEMENT_DETAIL_ID%type;
  begin
    aPlaAmountLC1  := 0.0;
    aPlaAmountLC2  := 0.0;

    --Recherche si l'en-t�te g�re la base 1 d'amortissement (�l�ment de structure 1)
    select nvl(max(FAM_ELEMENT_DETAIL_ID), 0)
      into vAmoTransaction1
      from FAM_ELEMENT_DETAIL DET
         , FAM_PLAN_HEADER FPH
     where FPH.FAM_PLAN_HEADER_ID = aPlanHeaderId
       and DET.FAM_STRUCTURE_ELEMENT_ID = FPH.FAM_STRUCTURE_ELEMENT1_ID
       and DET.C_FAM_TRANSACTION_TYP between '600' and '699';

    --L'�l�ment de structure 1 existe et g�re les types 600 d'amortissement
    if vAmoTransaction1 <> 0 then
      if aType60 then
        select nvl(sum(nvl(FPE.FPE_AMORTIZATION_LC, 0) ), 0)
          into aPlaAmountLC1
          from FAM_PLAN_EXERCISE FPE
         where FPE.FAM_PLAN_HEADER_ID = aPlanHeaderId
           and sign(FPE.FAM_PLAN_EXERCISE_ID) = -1;
      else
        select nvl(sum(nvl(FPE.FPE_AMORTIZATION_LC, 0) ), 0)
          into aPlaAmountLC1
          from FAM_PLAN_EXERCISE FPE
         where FPE.FAM_PLAN_HEADER_ID = aPlanHeaderId
           and sign(FAM_PLAN_EXERCISE_ID) = +1;
      end if;
    end if;

    --Recherche si l'en-t�te g�re la base 2 d'amortissement (�l�ment de structure 6)
    select nvl(max(FAM_ELEMENT_DETAIL_ID), 0)
      into vAmoTransaction6
      from FAM_ELEMENT_DETAIL DET
         , FAM_PLAN_HEADER FPH
     where FPH.FAM_PLAN_HEADER_ID = aPlanHeaderId
       and DET.FAM_STRUCTURE_ELEMENT_ID = FPH.FAM_STRUCTURE_ELEMENT6_ID
       and DET.C_FAM_TRANSACTION_TYP between '600' and '699';

    --L'�l�ment de structure 6 existe et g�re les types 600 d'amortissement
    if vAmoTransaction6 <> 0 then
      if aType60 then
        select nvl(sum(nvl(FPE.FPE_AMORTIZATION_LC, 0) ), 0)
          into aPlaAmountLC2
          from FAM_PLAN_EXERCISE FPE
         where FPE.FAM_PLAN_HEADER_ID = aPlanHeaderId
           and sign(FPE.FAM_PLAN_EXERCISE_ID) = -1;
      else
        select nvl(sum(nvl(FPE.FPE_AMORTIZATION_LC, 0) ), 0)
          into aPlaAmountLC2
          from FAM_PLAN_EXERCISE FPE
         where FPE.FAM_PLAN_HEADER_ID = aPlanHeaderId
           and sign(FPE.FAM_PLAN_EXERCISE_ID) = +1;
      end if;
    end if;
  end GetPlanedPosAmount;

  /**
  * Calcul montant amortissement
  **/
  procedure SetAmoParameterByElement(
    aPlanHeaderId    in     FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type   --Id en-t�te calcul courant
  , aResidualValue   in     FAM_DEFAULT.DEF_MIN_RESIDUAL_VALUE%type   --Valeur r�siduelle
  , aAmoLimit        in     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type   --Limite d'amortissement
  , aRoundType       in     FAM_AMORTIZATION_METHOD.C_ROUND_TYPE%type   --Type d'arrondi
  , aRoundAmount     in     FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT%type   --Montant d'arrondi
  , aLocalCurrency   in     FAM_PLAN_EXERCISE.ACS_ACS_FINANCIAL_CURRENCY_ID%type   --Monnaie de base   du montant de base pour calcul d�finitif
  , aCoveredDays     in     FAM_PLAN_EXERCISE.FPE_DAYS%type   --Nombre de jours couverts dans l'exercice
  , aAmortizedAmount in     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type   --Montant d�j� amorti
  , aAmoBaseAmountLC in     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type   --Montant base d'amortissement
  , aType60          in     boolean
  , aAmoRate         in out FAM_PLAN_EXERCISE.FPE_RATE%type   --R�ceptionne le taux d'amortissement
  , aAmoDays         in     FAM_PLAN_EXERCISE.FPE_DAYS%type   --Nombre de jours d'amortissement
  , aAmoAmountLC     in out FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type   --Montant d'amortissement calcul�
  )
  is
    vBalanceAmount      FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Solde montant � amortir
    vRoundedBalance     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant arrondi du solde
    vPreviousCalcAmount FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant d'amortissement d�j� calcul� pr�sent dans la base
  begin
    /**
      Si valeur r�siduelle renseign�e et que le montant "Base amortissement" y est inf�rieure on amorti la totalit�
        ==> montant amortissement = montant r�siduel
        ==> Taux est forc� � 100 %
        ==> Nb jours amortis forc� � 0
      Sinon
        Montant amortissement  =   Montant amortissement selon calcul (Base * taux * dur�e)
                                   + Diff�rence d'arrondi du montant solde
    **/
    if  ( (gNegativeBase = 0) and   (aResidualValue is not null)
         and (aResidualValue <> 0)
         and (aAmoBaseAmountLC <= aResidualValue) ) or
        ( (gNegativeBase = 1) and   (aResidualValue is not null)
         and (aResidualValue <> 0)
         and (abs(aAmoBaseAmountLC) <= aResidualValue) )
          then
      aAmoAmountLC  := aAmoBaseAmountLC;
      aAmoRate      := 100;
--      aAmoDays      := 0;
    else
      aAmoAmountLC     := aAmoBaseAmountLC *(aAmoRate / 100) *(aAmoDays / aCoveredDays);
      vBalanceAmount   := aAmoBaseAmountLC - aAmoAmountLC;
      vRoundedBalance  := RoundAmount(aRoundType, aRoundAmount, aLocalCurrency, vBalanceAmount);
      aAmoAmountLC     := aAmoAmountLC +(vBalanceAmount - vRoundedBalance);
    end if;

    --Cas des arrondis de toute fin de vie: Si l'amortissement calcul� pour un
    --exercice est �gal � 0 alors qu'il reste cependant une valeur � amortir (limite non-atteinte),
    --alors amortir l'int�gralit� restant � amortir pour atteindre la limite.
    if     (aAmoBaseAmountLC > 0)
       and (aAmoAmountLC = 0) then
      aAmoAmountLC  := aAmoBaseAmountLC;
    end if;

    vPreviousCalcAmount  := GetHeaderPreviousAmount(aPlanHeaderId, aType60);

    --Force le montant � la diff�rence entre la limite d'amortissement et les amortissements d�j� simul�es
    -- => Emp�cher le d�passement du montant � amortir
    if  ( (gNegativeBase = 0) and  (aAmoLimit > 0) and (aAmoAmountLC > aAmoLimit - vPreviousCalcAmount - aAmortizedAmount)
         ) or
        ( (gNegativeBase = 1) and (aAmoLimit < 0) and (aAmoAmountLC < aAmoLimit - vPreviousCalcAmount - aAmortizedAmount)
          ) then
      aAmoAmountLC  := aAmoLimit - vPreviousCalcAmount - aAmortizedAmount;
    end if;
  end SetAmoParameterByElement;

  /**
  * R�ception des montants comptabilis�s par immob et valeur g�r�e correspondant
  * � l'�l�ment de structure et jusqu'� la date donn�s
  **/
  procedure SetPlanElemAmount(
    aFixedAssetsId        in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId       in     FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , aFyeEndDate           in     ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , aStructureElementId   in     FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
  , aExerciseBaseAmountLC out    FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type
  , aBaseAmountLCurrency  out    FAM_PLAN_EXERCISE.ACS_FINANCIAL_CURRENCY_ID%type
  , aIsBudget             in     number
  )
  is
  begin
    if aIsBudget = 1 then
      GetBudgetElemAmount(aFixedAssetsId, aFyeEndDate, aStructureElementId, aExerciseBaseAmountLC
                        , aBaseAmountLCurrency);
    else
      if aFyeEndDate is not null then
        GetDatedElemAmount(aFixedAssetsId
                         , aManagedValueId
                         , aFyeEndDate
                         , aStructureElementId
                         , aExerciseBaseAmountLC
                         , aBaseAmountLCurrency
                          );
      else
        GetAllDateElemAmount(aFixedAssetsId
                           , aManagedValueId
                           , aStructureElementId
                           , aExerciseBaseAmountLC
                           , aBaseAmountLCurrency
                            );
      end if;
    end if;
  end SetPlanElemAmount;

  procedure GetAllDateElemAmount(
    aFixedAssetsId        in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId       in     FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , aStructureElementId   in     FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
  , aExerciseBaseAmountLC out    FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type
  , aBaseAmountLCurrency  out    FAM_PLAN_EXERCISE.ACS_FINANCIAL_CURRENCY_ID%type
  )
  is
  begin
    begin
      select max(ACS_ACS_FINANCIAL_CURRENCY_ID)
           , nvl(max(Amount), 0)
        into aBaseAmountLCurrency
           , aExerciseBaseAmountLC
        from (select   FIM.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
                     , sum(nvl(FIM.FIM_AMOUNT_LC_D, 0) - nvl(FIM.FIM_AMOUNT_LC_C, 0) ) Amount
                  from FAM_IMPUTATION FIM
                 where FIM.FAM_FIXED_ASSETS_ID = aFixedAssetsId
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
                            and FIM.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
                   and exists(
                         select 1
                           from FAM_VAL_IMPUTATION VIM
                          where VIM.FAM_IMPUTATION_ID = FIM.FAM_IMPUTATION_ID
                            and VIM.FAM_MANAGED_VALUE_ID = aManagedValueId)
                   and not(FIM.C_FAM_TRANSACTION_TYP like '6%')
              group by FIM.ACS_ACS_FINANCIAL_CURRENCY_ID);
    exception
      when no_data_found then
        aBaseAmountLCurrency   := null;
        aExerciseBaseAmountLC  := 0.0;
    end;
  end GetAllDateElemAmount;

  procedure GetDatedElemAmount(
    aFixedAssetsId        in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId       in     FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , aFyeEndDate           in     ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , aStructureElementId   in     FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
  , aExerciseBaseAmountLC out    FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type
  , aBaseAmountLCurrency  out    FAM_PLAN_EXERCISE.ACS_FINANCIAL_CURRENCY_ID%type
  )
  is
  begin
    begin
      select   FIM.ACS_ACS_FINANCIAL_CURRENCY_ID
             , sum(nvl(FIM.FIM_AMOUNT_LC_D, 0) - nvl(FIM.FIM_AMOUNT_LC_C, 0) )
          into aBaseAmountLCurrency
             , aExerciseBaseAmountLC
          from FAM_IMPUTATION FIM
         where FIM.FAM_FIXED_ASSETS_ID = aFixedAssetsId
           and FIM.FIM_TRANSACTION_DATE <= aFyeEndDate
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
                    and FIM.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
           and exists(
                      select 1
                        from FAM_VAL_IMPUTATION VIM
                       where VIM.FAM_IMPUTATION_ID = FIM.FAM_IMPUTATION_ID
                         and VIM.FAM_MANAGED_VALUE_ID = aManagedValueId)
           and not(FIM.C_FAM_TRANSACTION_TYP like '6%')
      group by FIM.ACS_ACS_FINANCIAL_CURRENCY_ID;
    exception
      when no_data_found then
        aBaseAmountLCurrency   := null;
        aExerciseBaseAmountLC  := 0.0;
    end;
  end GetDatedElemAmount;

  function GetDatedStrElemAmount(
    aFixedAssetsId      in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId     in FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , aFyeEndDate         in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , aStructureElementId in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
  )
    return FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type
  is
    vResult   FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;
    vCurrency FAM_PLAN_EXERCISE.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    GetDatedElemAmount(aFixedAssetsId, aManagedValueId, aFyeEndDate, aStructureElementId, vResult, vCurrency);
    return vResult;
  end GetDatedStrElemAmount;

  procedure GetBudgetElemAmount(
    aFixedAssetsId        in     FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
  , aFyeEndDate           in     ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , aStructureElementId   in     FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
  , aExerciseBaseAmountLC out    FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type
  , aBaseAmountLCurrency  out    FAM_PLAN_EXERCISE.ACS_FINANCIAL_CURRENCY_ID%type
  )
  is
  begin
    begin
      select   GLO.ACS_FINANCIAL_CURRENCY_ID
             , sum(PER.PER_AMOUNT_D - PER.PER_AMOUNT_C) PER_AMOUNT_D
          into aBaseAmountLCurrency
             , aExerciseBaseAmountLC
          from ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PER
             , ACS_PERIOD PER1
         where VER.VER_FIX_ASSETS = 1
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and GLO.FAM_FIXED_ASSETS_ID = aFixedAssetsId
           and PER.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
           and PER.ACS_PERIOD_ID = PER1.ACS_PERIOD_ID
           and PER1.PER_END_DATE <= aFyeEndDate
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = aStructureElementId
                    and GLO.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
      group by GLO.ACS_FINANCIAL_CURRENCY_ID;
    exception
      when no_data_found then
        aBaseAmountLCurrency   := null;
        aExerciseBaseAmountLC  := 0.0;
    end;
  end GetBudgetElemAmount;

  procedure SetPlanStatus(
    aPlanHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aPlanStatus   in FAM_PLAN_HEADER.C_AMO_PLAN_STATUS%type
  )
  is
  begin
    update FAM_PLAN_HEADER
       set C_AMO_PLAN_STATUS = aPlanStatus
     where FAM_PLAN_HEADER_ID = aPlanHeaderId;
  end SetPlanStatus;

  procedure SetPlanBlockingCode(
    aPlanHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aBlockinCode  in FAM_PLAN_HEADER.C_FPH_BLOCKING_REASON%type
  )
  is
  begin
    update FAM_PLAN_HEADER
       set C_FPH_BLOCKING_REASON = aBlockinCode
     where FAM_PLAN_HEADER_ID = aPlanHeaderId;
  end SetPlanBlockingCode;

  /**
  * Description Validation du plan d'amortissement donn�e selon r�gles de gestion
  **/
  procedure ValidatePlan(
    aPlanHeaderId  in     FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aErrCode       out    number
  , aErrText       out    varchar2
  , aErrorsInTable in     number default 0
  )
  is
    cursor crExercisePeriodAmount(aHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type)
    is
      --Prise en compte de TOUS les exercices et leurs p�riodes
      select   FPE.PYE_NO_EXERCISE
             , FPE.FPE_ADAPTED_AMO_LC
             , sum(nvl(FPP.FPP_ADAPTED_AMO_LC, 0) )
          from FAM_PLAN_EXERCISE FPE
             , FAM_PLAN_PERIOD FPP
             , FAM_PLAN_HEADER FPH
         where FPH.FAM_PLAN_HEADER_ID = aHeaderId
           and FPE.FAM_PLAN_HEADER_ID = FPH.FAM_PLAN_HEADER_ID
           and FPP.FAM_PLAN_EXERCISE_ID(+) = FPE.FAM_PLAN_EXERCISE_ID
      group by FPE.PYE_NO_EXERCISE
             , FPE.FPE_ADAPTED_AMO_LC
      order by FPE.PYE_NO_EXERCISE;

    vExercise      FAM_PLAN_EXERCISE.PYE_NO_EXERCISE%type;
    vFixedAssets   FAM_FIXED_ASSETS.FIX_LONG_DESCR%type;
    vFixedAssetsId FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
    vManagedVal    FAM_MANAGED_VALUE.VAL_KEY%type;
    vManagedValId  FAM_MANAGED_VALUE.VAL_KEY%type;
    vFPEAmount     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type;
    vFPPAmount     FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type;
    vLimitAmount   FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type;
    vLastCalcDate  FAM_CALC_AMORTIZATION.CAL_TRANSACTION_DATE%type;
  begin
    if aPlanHeaderId is not null then
      vFPEAmount    := 0;
      vFPPAmount    := 0;
      vLimitAmount  := 0;
      aErrCode      := 0;
      aErrText      := null;

      select FIX.FIX_NUMBER || ' - ' || FIX.FIX_SHORT_DESCR
           , FPH.FAM_FIXED_ASSETS_ID
           , FPH.FAM_MANAGED_VALUE_ID
        into vFixedAssets
           , vFixedAssetsId
           , vManagedValId
        from FAM_PLAN_HEADER FPH
           , FAM_FIXED_ASSETS FIX
       where FPH.FAM_PLAN_HEADER_ID = aPlanHeaderId
         and FIX.FAM_FIXED_ASSETS_ID = FPH.FAM_FIXED_ASSETS_ID;

      begin
        select VAL.VAL_KEY
          into vManagedVal
          from FAM_PLAN_HEADER FPH
             , FAM_MANAGED_VALUE VAL
         where FPH.FAM_PLAN_HEADER_ID = aPlanHeaderId
           and VAL.FAM_MANAGED_VALUE_ID = FPH.FAM_MANAGED_VALUE_ID;
      exception
        when ex.TABLE_MUTATING then
          vManagedVal  := null;
      end;

      --Test 1 : Somme amortissement = Limite amortissement
      begin
        select   FAM_AMORTIZATION_PLAN.GetStructureElemAmount(FPH.FAM_FIXED_ASSETS_ID
                                                            , FPH.FAM_MANAGED_VALUE_ID
                                                            , null
                                                            , FPH.FAM_STRUCTURE_ELEMENT3_ID
                                                            , 0
                                                             )
               , sum(FPE.FPE_ADAPTED_AMO_LC)
            into vLimitAmount
               , vFPEAmount
            from FAM_PLAN_HEADER FPH
               , FAM_PLAN_EXERCISE FPE
           where FPH.FAM_PLAN_HEADER_ID = aPlanHeaderId
             and FPE.FAM_PLAN_HEADER_ID = FPH.FAM_PLAN_HEADER_ID
        group by FPH.FAM_FIXED_ASSETS_ID
               , FPH.FAM_MANAGED_VALUE_ID
               , FPH.FAM_STRUCTURE_ELEMENT3_ID;

        if vLimitAmount <> vFPEAmount then
          aErrCode  := 1;
          aErrText  :=
            vFixedAssets ||
            ' / ' ||
            vManagedVal ||
            chr(13) ||
            '---------------------------------------------------------------------' ||
            chr(13) ||
            PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_LIMITE', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
            ': ' ||
            to_char(vLimitAmount, 'FM9999G999G990D009') ||
            ' ' ||
            gCurrName ||
            chr(13) ||
            PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_PLAN', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
            ': ' ||
            to_char(vFPEAmount, 'FM9999G999G990D009') ||
            ' ' ||
            gCurrName ||
            chr(13) ||
            PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_DIFF', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
            ': ' ||
            to_char( (vLimitAmount - vFPEAmount), 'FM9999G999G990D009') ||
            ' ' ||
            gCurrName ||
            chr(13) ||
            '---------------------------------------------------------------------';
        end if;
      exception
        when no_data_found then
          aErrCode  := 0;
      end;

      vFPEAmount    := 0;
      vFPPAmount    := 0;
      vLimitAmount  := 0;

      --Test 2 : Montants exercice = montants p�riode
      if aErrCode = 0 then
        open crExercisePeriodAmount(aPlanHeaderId);

        fetch crExercisePeriodAmount
         into vExercise
            , vFPEAmount
            , vFPPAmount;

        while crExercisePeriodAmount%found loop
          if vFPEAmount <> vFPPAmount then
            aErrCode  := 2;
            aErrText  :=
              vFixedAssets ||
              ' / ' ||
              vManagedVal ||
              ' / ' ||
              vExercise ||
              chr(13) ||
              '---------------------------------------------------------------------' ||
              chr(13) ||
              PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_EXERCISE', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
              ': ' ||
              to_char(vFPEAmount, 'FM9999G999G990D009') ||
              ' ' ||
              gCurrName ||
              chr(13) ||
              PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_PERIOD', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
              ': ' ||
              to_char(vFPPAmount, 'FM9999G999G990D009') ||
              ' ' ||
              gCurrName ||
              chr(13) ||
              PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_DIFF', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
              ': ' ||
              to_char( (vFPEAmount - vFPPAmount), 'FM9999G999G990D009') ||
              ' ' ||
              gCurrName ||
              chr(13) ||
              '---------------------------------------------------------------------';
          end if;

          fetch crExercisePeriodAmount
           into vExercise
              , vFPEAmount
              , vFPPAmount;
        end loop;

        close crExercisePeriodAmount;
      end if;

      --Test 3 : Somme plan = somme calculs � la date du dernier calcul
      if aErrCode = 0 then
        vLastCalcDate  := FAM_AMORTIZATION_PLAN.GetLastAmoCalculationDate;
        vFPEAmount     := 0;
        vFPPAmount     := 0;
        vLimitAmount   := 0;

        if vLastCalcDate is not null then
          --Les variable existantes sont r�utilis�es....ne pas pr�ter attention � leur d�finition initiale.
          vFPEAmount    := FAM_AMORTIZATION_PLAN.GetInProgressAmoAmount(vFixedAssetsId, vManagedValId, vLastCalcDate);
          vLimitAmount  := FAM_AMORTIZATION_PLAN.GetAmortizedAmount(vFixedAssetsId, vManagedValId, vLastCalcDate);
          vFPPAmount    := FAM_AMORTIZATION_PLAN.GetHeaderPlanedAmount(aPlanHeaderId, vLastCalcDate);
        end if;

        if (vFPEAmount + vLimitAmount) <> vFPPAmount then
          aErrCode  := 3;
          aErrText  :=
            vFixedAssets ||
            ' / ' ||
            vManagedVal ||
            ' / ' ||
            vLastCalcDate ||
            chr(13) ||
            '---------------------------------------------------------------------' ||
            chr(13) ||
            PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_CALCULATED', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
            ': ' ||
            to_char(vFPEAmount, 'FM9999G999G990D009') ||
            ' ' ||
            gCurrName ||
            chr(13) ||
            PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_CHARGED', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
            ': ' ||
            to_char(vLimitAmount, 'FM9999G999G990D009') ||
            ' ' ||
            gCurrName ||
            chr(13) ||
            PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_PLAN', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
            ': ' ||
            to_char(vFPPAmount, 'FM9999G999G990D009') ||
            ' ' ||
            gCurrName ||
            chr(13) ||
            PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_DIFF', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
            ': ' ||
            to_char( (vFPEAmount + vLimitAmount - vFPPAmount), 'FM9999G999G990D009') ||
            ' ' ||
            gCurrName ||
            chr(13) ||
            '---------------------------------------------------------------------';
        end if;
      end if;

      if aErrorsInTable <> -1 then
        if aErrCode = 0 then
          SetPlanBlockingCode(aPlanHeaderId, '01');   --Plan � activer
          SetPlanStatus(aPlanHeaderId, '1');
        elsif aErrCode = 1 then
          SetPlanBlockingCode(aPlanHeaderId, '02');   --L'immobilisation n'est pas totalement amortie
        elsif aErrCode = 2 then
          SetPlanBlockingCode(aPlanHeaderId, '03');   --Total des p�riodes <> Total des exercices
        elsif aErrCode = 3 then
          SetPlanBlockingCode(aPlanHeaderId, '04');   --Ajustement comptabilis� lors du prochain calcul
        end if;
      end if;

      if     (abs(aErrorsInTable) = 1)
         and (aErrCode > 0) then
        GeneratePlanError(aPlanHeaderId);
      end if;
    end if;
  end ValidatePlan;

  /**
  * Description Validation et activation du plan d'amortissement donn�e selon r�gles de gestion
  **/
  procedure ActivatePlan(
    aPlanHeaderId  in     FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aErrCode       in out number
  , aErrText       in out varchar2
  , aErrorsInTable in     number default 0
  )
  is
  begin
    ValidatePlan(aPlanHeaderId, aErrCode, aErrText, aErrorsInTable);

    if    (aErrCode = 0)
       or (aErrCode = 3) then
      SetPlanStatus(aPlanHeaderId, '1');
    end if;
  end ActivatePlan;

  /**
  * Description Retour du texte des erreurs de r�ajustement
  **/
  function GetErrorExplanation(pPlanHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type)
    return varchar2
  is
    vErrText       varchar2(5000);
    vFixedAssets   FAM_FIXED_ASSETS.FIX_LONG_DESCR%type;
    vFixedAssetsId FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
    vManagedVal    FAM_MANAGED_VALUE.VAL_KEY%type;
    vManagedValId  FAM_MANAGED_VALUE.VAL_KEY%type;
    vFPEAmount     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type;
    vFPPAmount     FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type;
    vLimitAmount   FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type;
    vLastCalcDate  FAM_CALC_AMORTIZATION.CAL_TRANSACTION_DATE%type;
  begin
    select FIX.FIX_NUMBER || ' - ' || FIX.FIX_SHORT_DESCR
         , FPH.FAM_FIXED_ASSETS_ID
         , FPH.FAM_MANAGED_VALUE_ID
      into vFixedAssets
         , vFixedAssetsId
         , vManagedValId
      from FAM_PLAN_HEADER FPH
         , FAM_FIXED_ASSETS FIX
     where FPH.FAM_PLAN_HEADER_ID = pPlanHeaderId
       and FIX.FAM_FIXED_ASSETS_ID = FPH.FAM_FIXED_ASSETS_ID;

    begin
      select VAL.VAL_KEY
        into vManagedVal
        from FAM_PLAN_HEADER FPH
           , FAM_MANAGED_VALUE VAL
       where FPH.FAM_PLAN_HEADER_ID = pPlanHeaderId
         and VAL.FAM_MANAGED_VALUE_ID = FPH.FAM_MANAGED_VALUE_ID;
    exception
      when ex.TABLE_MUTATING then
        vManagedVal  := null;
    end;

    vFPEAmount     := 0;
    vFPPAmount     := 0;
    vLimitAmount   := 0;
    vErrText       := null;
    vLastCalcDate  := FAM_AMORTIZATION_PLAN.GetLastAmoCalculationDate;

    if vLastCalcDate is not null then
      vFPEAmount    := FAM_AMORTIZATION_PLAN.GetInProgressAmoAmount(vFixedAssetsId, vManagedValId, vLastCalcDate);
      vLimitAmount  := FAM_AMORTIZATION_PLAN.GetAmortizedAmount(vFixedAssetsId, vManagedValId, vLastCalcDate);
      vFPPAmount    := FAM_AMORTIZATION_PLAN.GetHeaderPlanedAmount(pPlanHeaderId, vLastCalcDate);
    end if;

    if (vFPEAmount + vLimitAmount) <> vFPPAmount then
      vErrText  :=
        vFixedAssets ||
        ' / ' ||
        vManagedVal ||
        ' / ' ||
        vLastCalcDate ||
        chr(13) ||
        '---------------------------------------------------------------------' ||
        chr(13) ||
        PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_CALCULATED', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
        ': ' ||
        to_char(vFPEAmount, 'FM9999G999G990D009') ||
        ' ' ||
        gCurrName ||
        chr(13) ||
        PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_CHARGED', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
        ': ' ||
        to_char(vLimitAmount, 'FM9999G999G990D009') ||
        ' ' ||
        gCurrName ||
        chr(13) ||
        PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_PLAN', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
        ': ' ||
        to_char(vFPPAmount, 'FM9999G999G990D009') ||
        ' ' ||
        gCurrName ||
        chr(13) ||
        PCS.PC_FUNCTIONS.TRANSLATEWORD('FAM_AMO_PLAN_DIFF', PCS.PC_I_LIB_SESSION.USER_LANG_ID) ||
        ': ' ||
        to_char( (vFPEAmount + vLimitAmount - vFPPAmount), 'FM9999G999G990D009') ||
        ' ' ||
        gCurrName ||
        chr(13) ||
        '---------------------------------------------------------------------';
    end if;

    return vErrText;
  end GetErrorExplanation;

  function GetLastAmoCalculationDate
    return ACS_PERIOD.PER_END_DATE%type
  is
    vLastCalcDate ACS_PERIOD.PER_END_DATE%type;
  begin
    select max(PER.PER_END_DATE)
      into vLastCalcDate
      from ACS_PERIOD PER
     where exists(select 1
                    from FAM_AMORTIZATION_PERIOD FAP
                   where PER.ACS_PERIOD_ID = FAP.ACS_PERIOD_ID);

    return vLastCalcDate;
  end GetLastAmoCalculationDate;

  /**
  * Cr�ation d'une position d'erreur pour le plan non actif
  **/
  procedure GeneratePlanError(aPlanHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type)
  is
    vFixedAssetsId  FAM_PLAN_ERROR.FAM_FIXED_ASSETS_ID%type;
    vManagedValueId FAM_PLAN_ERROR.FAM_MANAGED_VALUE_ID%type;
  begin
    select FAM_FIXED_ASSETS_ID
         , FAM_MANAGED_VALUE_ID
      into vFixedAssetsId
         , vManagedValueId
      from FAM_PLAN_HEADER
     where FAM_PLAN_HEADER_ID = aPlanHeaderId
       and C_AMO_PLAN_STATUS <> 1;

    delete from FAM_PLAN_ERROR
          where FAM_PLAN_ERROR_ID = userenv('SESSIONID')
            and FAM_FIXED_ASSETS_ID = vFixedAssetsId
            and FAM_MANAGED_VALUE_ID = vManagedValueId;

    insert into FAM_PLAN_ERROR
                (FAM_PLAN_ERROR_ID
               , FAM_FIXED_ASSETS_ID
               , FAM_MANAGED_VALUE_ID
               , C_AMO_PLAN_STATUS
               , C_FPH_BLOCKING_REASON
               , A_DATECRE
               , A_IDCRE
                )
      select userenv('SESSIONID')
           , FAM_FIXED_ASSETS_ID
           , FAM_MANAGED_VALUE_ID
           , C_AMO_PLAN_STATUS
           , C_FPH_BLOCKING_REASON
           , sysdate
           , gUserIni
        from FAM_PLAN_HEADER
       where FAM_PLAN_HEADER_ID = aPlanHeaderId
         and C_AMO_PLAN_STATUS <> 1;
  end GeneratePlanError;

  function ExistSessionError
    return number
  is
    vResult number(1);
  begin
    select nvl(max(1), 0)
      into vResult
      from FAM_PLAN_ERROR
     where FAM_PLAN_ERROR_ID = userenv('SESSIONID');

    return vResult;
  end;

  /**
  * Proc�dure centrale de calcul des amortissement par exercice et de cr�ation des positions
  **/
  procedure CalculateExerciseAmortization(
    aPlanHeaderId          in     FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type   --Id en-t�te calcul courant
  , aPlanExerciseId        out    FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type   --Id exercice calcul courant
  , aFixedAssetsId         in     FAM_PLAN_HEADER.FAM_FIXED_ASSETS_ID%type
  , aManagedValueId        in     FAM_PLAN_HEADER.FAM_MANAGED_VALUE_ID%type
  , aStructureElementId1   in     FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT1_ID%type
  , aStructureElementId3   in     FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT3_ID%type
  , aStructureElementId6   in     FAM_PLAN_HEADER.FAM_STRUCTURE_ELEMENT6_ID%type
  , aResidualValue         in     FAM_DEFAULT.DEF_MIN_RESIDUAL_VALUE%type   --Valeur r�siduelle
  , aRoundType             in     FAM_AMORTIZATION_METHOD.C_ROUND_TYPE%type   --Type d'arrondi
  , aRoundAmount           in     FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT%type   --Montant d'arrondi
  , aCoveredDays           in     FAM_PLAN_EXERCISE.FPE_DAYS%type   --Nombre de jours couverts dans l'exercice
  , aAmortizationDays      in out FAM_PLAN_EXERCISE.FPE_DAYS%type   --Nombre de jours d'amortissement
  , aLocalCurrency         in out FAM_PLAN_EXERCISE.ACS_ACS_FINANCIAL_CURRENCY_ID%type   --Monnaie de base   du montant de base pour calcul d�finitif
  , aExerciseNumber        in     FAM_PLAN_EXERCISE.PYE_NO_EXERCISE%type
  , aStartDate             in     FAM_PLAN_EXERCISE.PYE_START_DATE%type
  , aEndDate               in     FAM_PLAN_EXERCISE.PYE_END_DATE%type
  , aAmortizationStartDate in     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BEGIN%type   --Date d�but amortissement dans l'exercice
  , aAmortizationEndDate   in     FAM_PLAN_EXERCISE.FPE_AMORTIZATION_END%type   --Date fin amortissement dans l'exercice
  , aLastExercise          in     boolean   --Indique si dernier exercice de calcul pour arrondi
  , aAmortizationRate1     in     FAM_PLAN_EXERCISE.FPE_RATE%type   --Taux d'amortissement 1
  , aAmortizationRate2     in     FAM_PLAN_EXERCISE.FPE_RATE%type   --Taux d'amortissement 2
  , aType60                in     boolean
  , aIsBudget              in     number   --Indique si position bud�tis�e (1) ou non(0)
  )
  is
    vBaseAmountLC1        FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant base amortissement 1
    vBaseAmountLC6        FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant base amortissement 2
    vBaseAmountLC         FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant base amortissement pour calcul d�finitif
    vAmortizedAmount      FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant d�j� amorti
    vAmortizationLimit    FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Limite d'amortissement
    vLocalCurrency1       FAM_PLAN_EXERCISE.ACS_ACS_FINANCIAL_CURRENCY_ID%type;   --Monnaie de base du montant de base 1
    vLocalCurrency6       FAM_PLAN_EXERCISE.ACS_ACS_FINANCIAL_CURRENCY_ID%type;   --Monnaie de base du montant de base 2
    vAmortizationLC1      FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant d'amortissement calcul� base 1
    vAmortizationLC6      FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant d'amortissement calcul� base 2
    vCalculatedAmountLC1  FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant d'amortissement d�j� calcul� dans le m�me process pour base 1
    vCalculatedAmountLC6  FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant d'amortissement d�j� calcul� dans le m�me process pour base 2
    vAmortizationLC       FAM_PLAN_EXERCISE.FPE_AMORTIZATION_BASE_LC%type;   --Montant d'amortissement d�finitif
    vAmortizationRate1    FAM_PLAN_EXERCISE.FPE_RATE%type;   --R�ceptionne taux d'amortissement 1
    vAmortizationRate2    FAM_PLAN_EXERCISE.FPE_RATE%type;   --R�ceptionne taux d'amortissement 2
    vAmortizationCalcRate FAM_PLAN_EXERCISE.FPE_RATE%type;   --R�ceptionne taux d'amortissement pour calcul d�finitif
  begin
    vBaseAmountLC1        := 0;
    vBaseAmountLC6        := 0;
    vBaseAmountLC         := 0;
    vAmortizedAmount      := 0;

    if aIsBudget = 1 then
      vAmortizationLimit  :=
                 GetStructureElemAmount(aFixedAssetsId, aManagedValueId, aAmortizationEndDate, aStructureElementId3, 1);
    else
      vAmortizationLimit  := GetStructureElemAmount(aFixedAssetsId, aManagedValueId, null, aStructureElementId3, 0);
    end if;

    vAmortizationRate1    := aAmortizationRate1;

    --R�ception montant base amortissement (Structure 1) � fin amortissement (correspond date fin exercice courant ou date fin amortissement pour type 60)
    if aIsBudget = 1 then
      SetPlanElemAmount(aFixedAssetsId
                      , aManagedValueId
                      , aAmortizationEndDate
                      , aStructureElementId1
                      , vBaseAmountLC1
                      , vLocalCurrency1
                      , aIsBudget
                       );
    else
      SetPlanElemAmount(aFixedAssetsId
                      , aManagedValueId
                      , null
                      , aStructureElementId1
                      , vBaseAmountLC1
                      , vLocalCurrency1
                      , aIsBudget
                       );
    end if;

    -- Montant <> 0 => Calcul montant amortissement par exercice
      if ( (gNegativeBase = 1 ) and (vBaseAmountLC1 < 0) ) or
         ( (gNegativeBase = 0 ) and (vBaseAmountLC1 > 0) ) then
      SetAmoParameterByElement(aPlanHeaderId
                             , aResidualValue
                             , vAmortizationLimit
                             , aRoundType
                             , aRoundAmount
                             , vLocalCurrency1
                             , aCoveredDays
                             , vAmortizedAmount
                             , vBaseAmountLC1
                             , aType60
                             , vAmortizationRate1
                             , aAmortizationDays
                             , vAmortizationLC1
                              );
    end if;

    --R�ception montant base amortissement 2 (Structure 6) � fin amortissement (correspond date fin exercice courant ou date fin amortissement pour type 60)
    if aIsBudget = 1 then
      SetPlanElemAmount(aFixedAssetsId
                      , aManagedValueId
                      , aAmortizationEndDate
                      , aStructureElementId6
                      , vBaseAmountLC6
                      , vLocalCurrency6
                      , aIsBudget
                       );
    else
      SetPlanElemAmount(aFixedAssetsId
                      , aManagedValueId
                      , null
                      , aStructureElementId6
                      , vBaseAmountLC6
                      , vLocalCurrency6
                      , aIsBudget
                       );
    end if;

    -- Montant <> 0 => Calcul montant amortissement par exercice pour types utilisant
    -- la base amortissement la plus favorable
      if (gAmoType in('3', '4', '5')) and
         ( ( (gNegativeBase = 1 ) and (vBaseAmountLC6 < 0) ) or
           ( (gNegativeBase = 0 ) and (vBaseAmountLC6 > 0) )) then
      if gAmoType = '5' then
        vAmortizationRate2  := aAmortizationRate2;
      else
        vAmortizationRate2  := vAmortizationRate1;
      end if;

      SetAmoParameterByElement(aPlanHeaderId
                             , aResidualValue
                             , vAmortizationLimit
                             , aRoundType
                             , aRoundAmount
                             , vLocalCurrency6
                             , aCoveredDays
                             , vAmortizedAmount
                             , vBaseAmountLC6
                             , aType60
                             , vAmortizationRate2
                             , aAmortizationDays
                             , vAmortizationLC6
                              );
    end if;

    vCalculatedAmountLC1  := 0;
    vCalculatedAmountLC6  := 0;

    --D�termine la base la + favorable ; celle qui amorti le + sur le montant de d�but d'exercice
    if vAmortizationLC6 > vAmortizationLC1 then
      vBaseAmountLC          := vBaseAmountLC6;
      aLocalCurrency         := vLocalCurrency6;
      vAmortizationCalcRate  := vAmortizationRate2;

      if (gAmoType = '9') then
        vBaseAmountLC  := vBaseAmountLC - GetFirstExerciseAmoAmount(aPlanHeaderId);
      else
        GetPlanedPosAmount(aPlanHeaderId, aType60, vCalculatedAmountLC1, vCalculatedAmountLC6);
      end if;

      vBaseAmountLC          := vBaseAmountLC - vCalculatedAmountLC6;
      vBaseAmountLC6         := vBaseAmountLC;
    else
      vBaseAmountLC          := vBaseAmountLC1;
      aLocalCurrency         := vLocalCurrency1;
      vAmortizationCalcRate  := vAmortizationRate1;

      if (gAmoType = '9') then
        vBaseAmountLC  := vBaseAmountLC - GetFirstExerciseAmoAmount(aPlanHeaderId);
      else
        GetPlanedPosAmount(aPlanHeaderId, aType60, vCalculatedAmountLC1, vCalculatedAmountLC6);
      end if;

      vBaseAmountLC          := vBaseAmountLC - vCalculatedAmountLC1;
      vBaseAmountLC1         := vBaseAmountLC;
    end if;

    --Calcul d�finitif selon nouvelles bases d�finies
    SetAmoParameterByElement(aPlanHeaderId
                           , aResidualValue
                           , vAmortizationLimit
                           , aRoundType
                           , aRoundAmount
                           , aLocalCurrency
                           , aCoveredDays
                           , vAmortizedAmount
                           , vBaseAmountLC
                           , aType60
                           , vAmortizationCalcRate
                           , aAmortizationDays
                           , vAmortizationLC
                            );

    --Cas du dernier exercice o� tout doit �tre amorti, calculer par diff�rence
    --permet d'�viter probl�mes d'arrondi
    if aLastExercise then
      vAmortizationLC  := vAmortizationLimit - GetHeaderPreviousAmount(aPlanHeaderId, aType60);
    end if;

    if ( (gNegativeBase = 1 ) and (vAmortizationLC < 0) ) or
       ( (gNegativeBase = 0 ) and (vAmortizationLC > 0) ) then
      --Cr�ation d'une position d'exercice par exercice de planification
      aPlanExerciseId  :=
        CreatePlanExercisePosition(aPlanHeaderId
                                 , aExerciseNumber
                                 , aStartDate
                                 , aEndDate
                                 , vBaseAmountLC1
                                 , vBaseAmountLC6
                                 , vBaseAmountLC
                                 , vAmortizationLC
                                 , aAmortizationStartDate
                                 , least(nvl(aAmortizationEndDate, aEndDate), aEndDate)
                                 , vAmortizationCalcRate
                                 , aAmortizationDays
                                 , aLocalCurrency
                                 , aType60
                                  );
    else
      aAmortizationDays  := 0;
    end if;
  end CalculateExerciseAmortization;

  /**
  * Proc�dure centrale de calcul des amortissement par p�riode et de cr�ation des positions
  * ...Split des sonn�es de l'exercice parent sur les p�riodes
  **/
  procedure CalculatePeriodAmortization(
    aPlanExerciseId   in FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type
  , aPeriodsStartDate in FAM_PLAN_EXERCISE.PYE_START_DATE%type
  , aPeriodsEndDate   in FAM_PLAN_EXERCISE.PYE_END_DATE%type
  , aAmoCadence       in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type
  , aType60           in boolean
  )
  is
    --Exercices de planification � partir de la date d�but amortissement
    cursor crHeaderExercises(aExerciseId FAM_PLAN_EXERCISE.FAM_PLAN_EXERCISE_ID%type)
    is
      select   FPE.FAM_PLAN_EXERCISE_ID
             , FPE.FPE_DAYS
             , FPE.FPE_AMORTIZATION_BASE_LC
             , FPE.FPE_AMORTIZATION_BASE_FC
             , FPE.FPE_AMORTIZATION_LC
             , FPE.FPE_AMORTIZATION_FC
             , FPE.FPE_AMORTIZATION_BEGIN
             , FPE.FPE_AMORTIZATION_END
             , FPE.PYE_START_DATE
             , FPE.PYE_END_DATE
          from FAM_PLAN_EXERCISE FPE
         where FPE.FAM_PLAN_EXERCISE_ID = aExerciseId
      order by FPE.FAM_PLAN_EXERCISE_ID;

    --P�riodes de planification de l'exercice donn�
    cursor crPeriod(aStartDate FAM_PLAN_EXERCISE.PYE_START_DATE%type, aEndDate FAM_PLAN_EXERCISE.PYE_END_DATE%type)
    is
      select   APP.ACS_PLAN_PERIOD_ID
             , APP.APP_NO_PERIOD
             , APP.APP_START_DATE
             , APP.APP_END_DATE
             , APP.ACS_PLAN_YEAR_ID
          from ACS_PLAN_PERIOD APP
         where exists(
                 select 1
                   from ACS_PLAN_PERIOD APP_START
                  where (aStartDate between APP_START.APP_START_DATE and APP_START.APP_END_DATE)
                    and APP.APP_START_DATE >= APP_START.APP_START_DATE)
           and exists(
                 select 1
                   from ACS_PLAN_PERIOD APP_END
                  where (aEndDate between APP_END.APP_START_DATE and APP_END.APP_END_DATE)
                    and APP.APP_END_DATE <= APP_END.APP_END_DATE)
      order by APP.APP_START_DATE;

    tplHeaderExercises crHeaderExercises%rowtype;
    tplPeriods         crPeriod%rowtype;   --R�ceptionne les p�riodes du curseur
    vPeriodsCnt        number(2);   --Nombre de p�riode d'un exercice
    vLastPeriodId      FAM_PLAN_PERIOD.FAM_PLAN_PERIOD_ID%type;   --R�ceptionne ID derni�re p�riode trait�e
    vPerAmoAmountLC    FAM_PLAN_PERIOD.FPP_AMORTIZATION_BASE_LC%type;   --Montant d'amortissement p�riode
    vSumAmoAmount      FAM_PLAN_PERIOD.FPP_AMORTIZATION_BASE_LC%type;   --Somme montant d'amortissement p�riode
    vPlanPeriodId      FAM_PLAN_PERIOD.FAM_PLAN_PERIOD_ID%type;   --R�ceptionne ID d�tail p�riode cr��
    vPeriodStart       FAM_PLAN_PERIOD.APP_START_DATE%type;   --date d�but d'amortissement dans p�riode
    vPeriodEnd         FAM_PLAN_PERIOD.APP_END_DATE%type;   --date fin d'amortissement dans p�riode
    vPeriodDays        FAM_PLAN_PERIOD.FPP_DAYS%type;   --Nombre de jours entre date d�but p�riode et fin de p�riode
  begin
    --R�ceptions des donn�es de l'exercice donn�
    --Pour types non roumains et annuel
    --  ...recherche des p�riodes comprises entre les dates d�but et fin effectives de l'exercice
    --  ...cr�ation de la p�riode avec les dates effectives de la p�riode et les dates amortissements de l'exercice
    open crHeaderExercises(aPlanExerciseId);

    loop
      fetch crHeaderExercises
       into tplHeaderExercises;

      exit when crHeaderExercises%notfound;

      --Type 60....Toutes les p�riodes comprises entre d�but et fin d'exercice donn�s en param�tre.
      --           peuvent �tre diff�rentes de celles de l'exercice selon calcul effective pour types 60
      -- Autres ...Toutes les p�riodes comprises entre d�but et fin d'amortissement.
      if aType60 then
        open crPeriod(aPeriodsStartDate, aPeriodsEndDate);
      else
        if aAmoCadence = 4 then
          open crPeriod(tplHeaderExercises.PYE_START_DATE, tplHeaderExercises.PYE_END_DATE);
        else
          open crPeriod(tplHeaderExercises.FPE_AMORTIZATION_BEGIN, tplHeaderExercises.FPE_AMORTIZATION_END);
        end if;
      end if;

      fetch crPeriod
       into tplPeriods;

      vPeriodsCnt  := 0;
      vPeriodDays  := 0;

      while crPeriod%found loop
        vLastPeriodId  := tplPeriods.ACS_PLAN_PERIOD_ID;
        vPeriodsCnt    := vPeriodsCnt + 1;

        fetch crPeriod
         into tplPeriods;
      end loop;

      close crPeriod;

      if aType60 then
        open crPeriod(aPeriodsStartDate, aPeriodsEndDate);
      else
        if aAmoCadence = 4 then
          open crPeriod(tplHeaderExercises.PYE_START_DATE, tplHeaderExercises.PYE_END_DATE);
        else
          open crPeriod(tplHeaderExercises.FPE_AMORTIZATION_BEGIN, tplHeaderExercises.FPE_AMORTIZATION_END);
        end if;
      end if;

      fetch crPeriod
       into tplPeriods;

      --Si Cadence = annuelle -> R�partir la totalit� de la somme annuelle sur la derni�re p�riode
      if     (aAmoCadence = 4)
         and (gAmoType <> '60') then
        while crPeriod%found loop
          if tplPeriods.ACS_PLAN_PERIOD_ID = vLastPeriodId then
            vPlanPeriodId  :=
              CreateCalculatedPlanPeriod(aPlanExerciseId
                                       , tplPeriods.APP_NO_PERIOD
                                       , tplPeriods.APP_START_DATE
                                       , tplPeriods.APP_END_DATE
                                       , tplHeaderExercises.FPE_AMORTIZATION_BEGIN
                                       , tplHeaderExercises.FPE_AMORTIZATION_END
                                       , tplHeaderExercises.FPE_DAYS
                                       , tplHeaderExercises.FPE_AMORTIZATION_BASE_LC
                                       , tplHeaderExercises.FPE_AMORTIZATION_LC
                                        );
          end if;

          fetch crPeriod
           into tplPeriods;
        end loop;
      elsif(aAmoCadence = 1) then
        vSumAmoAmount  := 0.0;

        while crPeriod%found loop
          if    (gAmoType = '60')
             or (gAmoType = '9') then
            vPeriodStart  := tplPeriods.APP_START_DATE;
            vPeriodEnd    := tplPeriods.APP_END_DATE;
            vPeriodDays   := tplHeaderExercises.FPE_DAYS / vPeriodsCnt;
          else
            --Date d�but d'amortissement dans p�riode : date d�but de p�riode ou date d�but amortissement
            vPeriodStart  := greatest(tplHeaderExercises.FPE_AMORTIZATION_BEGIN, tplPeriods.APP_START_DATE);
            --Date fin d'amortissement dans p�riode : date fin de p�riode ou fin d'amortissement
            vPeriodEnd    := least(tplHeaderExercises.FPE_AMORTIZATION_END, tplPeriods.APP_END_DATE);
            --Nombre de jours d'amortissement dans la p�riode
            vPeriodDays   :=
                      GetAmortizationDays(tplPeriods.APP_START_DATE, tplPeriods.APP_END_DATE, vPeriodStart, vPeriodEnd);
          end if;

          --Calcul par diff�rence pour la derni�re p�riode , sinon proportion selon nombre de jours
          --Arr�t si montants p�riodes = montant exercice
          if tplPeriods.ACS_PLAN_PERIOD_ID = vLastPeriodId then
            vPerAmoAmountLC  := tplHeaderExercises.FPE_AMORTIZATION_LC - vSumAmoAmount;
          else
            vPerAmoAmountLC  := (tplHeaderExercises.FPE_AMORTIZATION_LC * vPeriodDays) / tplHeaderExercises.FPE_DAYS;

            if ((gNegativeBase = 0) and (vPerAmoAmountLC >(tplHeaderExercises.FPE_AMORTIZATION_LC - vSumAmoAmount))) then
              vPerAmoAmountLC  := tplHeaderExercises.FPE_AMORTIZATION_LC - vSumAmoAmount;
            end if;
          end if;

          if ( (gNegativeBase = 1 ) and (vPerAmoAmountLC < 0) ) or
             ( (gNegativeBase = 0 ) and (vPerAmoAmountLC > 0) ) then
            vSumAmoAmount  := vSumAmoAmount + vPerAmoAmountLC;
            vPlanPeriodId  :=
              CreateCalculatedPlanPeriod(tplHeaderExercises.FAM_PLAN_EXERCISE_ID
                                       , tplPeriods.APP_NO_PERIOD
                                       , tplPeriods.APP_START_DATE
                                       , tplPeriods.APP_END_DATE
                                       , vPeriodStart
                                       , vPeriodEnd
                                       , vPeriodDays
                                       , tplHeaderExercises.FPE_AMORTIZATION_BASE_LC
                                       , vPerAmoAmountLC
                                        );
          end if;

          fetch crPeriod
           into tplPeriods;
        end loop;
      end if;

      close crPeriod;
    end loop;

    close crHeaderExercises;
  end CalculatePeriodAmortization;

  /**
  * Pour les types roumains, liaisons des p�riodes calcul�es sur une dur�e "civile"
  * avec les p�riodes de calcul et m�j des donn�es y relatives
  **/
  procedure LinkCalculatedPeriod(
    aPlanHeaderId     in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aAmoEffectiveRate in FAM_PLAN_EXERCISE.FPE_RATE%type
  )
  is
    cursor crHeaderExercises(aHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type)
    is
      select   FPE.PYE_START_DATE
             , FPE.PYE_END_DATE
             , FPE.FPE_AMORTIZATION_LC
             , FPE.FAM_PLAN_EXERCISE_ID
          from FAM_PLAN_EXERCISE FPE
         where FPE.FAM_PLAN_HEADER_ID = aHeaderId
           and sign(FPE.FAM_PLAN_EXERCISE_ID) = 1
      order by FPE.FAM_PLAN_EXERCISE_ID;

    cursor crPeriods60(aHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type)
    is
      select   FPP.APP_START_DATE
             , FPP.APP_END_DATE
             , FPP.FAM_PLAN_PERIOD_ID
             , FPP.FPP_AMORTIZATION_LC
             , FPP.FPP_AMORTIZATION_BASE_LC
          from FAM_PLAN_EXERCISE FPE
             , FAM_PLAN_PERIOD FPP
         where FPE.FAM_PLAN_HEADER_ID = aHeaderId
           and sign(FPE.FAM_PLAN_EXERCISE_ID) = -1
           and FPP.FAM_PLAN_EXERCISE_ID = FPE.FAM_PLAN_EXERCISE_ID
      order by FPP.APP_START_DATE;

    tplHeaderExercises crHeaderExercises%rowtype;
    tplPeriods60       crPeriods60%rowtype;
    vPerCounter        number(3);
    vExerciseCounter   number(3);
    vAmoAmount         FAM_PLAN_PERIOD.FPP_AMORTIZATION_LC%type;
    vAmoBase           FAM_PLAN_PERIOD.FPP_AMORTIZATION_BASE_LC%type;
  begin
    vExerciseCounter  := 0.0;

    open crHeaderExercises(aPlanHeaderId);

    loop
      fetch crHeaderExercises
       into tplHeaderExercises;

      exit when crHeaderExercises%notfound;

      delete from fam_plan_period
            where fam_plan_exercise_id = tplHeaderExercises.FAM_PLAN_EXERCISE_ID;

      vPerCounter       := 0;
      vAmoAmount        := 0.0;
      vAmoBase          := 0.0;
      vExerciseCounter  := vExerciseCounter + 1;

      open crPeriods60(aPlanHeaderId);

      loop
        fetch crPeriods60
         into tplPeriods60;

        exit when crPeriods60%notfound;

        if     (tplPeriods60.APP_START_DATE between tplHeaderExercises.PYE_START_DATE and tplHeaderExercises.PYE_END_DATE
               )
           and (tplPeriods60.APP_END_DATE between tplHeaderExercises.PYE_START_DATE and tplHeaderExercises.PYE_END_DATE
               ) then
          vPerCounter  := vPerCounter + 1;
          vAmoAmount   := vAmoAmount + tplPeriods60.FPP_AMORTIZATION_LC;
          vAmoBase     := vAmoBase + tplPeriods60.FPP_AMORTIZATION_BASE_LC;

          update FAM_PLAN_PERIOD
             set FAM_PLAN_EXERCISE_ID = tplHeaderExercises.FAM_PLAN_EXERCISE_ID
           where FAM_PLAN_PERIOD_ID = tplPeriods60.FAM_PLAN_PERIOD_ID;
        end if;
      end loop;

      close crPeriods60;

      update FAM_PLAN_EXERCISE
         set FPE_AMORTIZATION_BASE_LC = decode(vPerCounter, 0, FPE_AMORTIZATION_BASE_LC, vAmoBase / vPerCounter)
           , FPE_AMORTIZATION_LC = vAmoAmount
           , FPE_ADAPTED_AMO_LC = vAmoAmount
           , FPE_RATE = decode(gAmoType, '9', decode(vExerciseCounter, 1, FPE_RATE, aAmoEffectiveRate), FPE_RATE)
       where FAM_PLAN_EXERCISE_ID = tplHeaderExercises.FAM_PLAN_EXERCISE_ID;
    end loop;

    close crHeaderExercises;

    delete from fam_plan_period
          where sign(fam_plan_exercise_id) = -1;

    delete from fam_plan_exercise
          where sign(fam_plan_exercise_id) = -1;
  end LinkCalculatedPeriod;

  procedure AfterInsertDeleteDetails(aStrElementId in FAM_ELEMENT_DETAIL.FAM_STRUCTURE_ELEMENT_ID%type)
  is
      --Curseur des valeurs g�r�es ou  valeur g�r�e / cat�gorie utilisant l'�l�ment de structure actuel
    --dans un des �l�ments servant � calculer les amortissements(Toutes sauf 2 utilis� pour base int�r�ts)
    cursor crManagedValues(aElementId FAM_ELEMENT_DETAIL.FAM_STRUCTURE_ELEMENT_ID%type)
    is
      select   FAM_MANAGED_VALUE_ID
             , FAM_FIXED_ASSETS_CATEG_ID
          from FAM_DEFAULT
         where FAM_STRUCTURE_ELEMENT1_ID = aElementId
            or FAM_STRUCTURE_ELEMENT3_ID = aElementId
            or FAM_STRUCTURE_ELEMENT4_ID = aElementId
            or FAM_STRUCTURE_ELEMENT6_ID = aElementId
      union
      select   FAM_MANAGED_VALUE_ID
             , 0
          from FAM_MANAGED_VALUE
         where FAM_STRUCTURE_ELEMENT_ID = aElementId
            or FAM_STRUCTURE_ELEMENT3_ID = aElementId
            or FAM_STRUCTURE_ELEMENT4_ID = aElementId
            or FAM_STRUCTURE_ELEMENT5_ID = aElementId
      order by FAM_MANAGED_VALUE_ID
             , FAM_FIXED_ASSETS_CATEG_ID;

    --Curseur des immobilisations ayant un lien sur la valeur g�r�e donn�e
    cursor crFixedByValue(aFamManagedValueId FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type)
    is
      select   FIX.FAM_FIXED_ASSETS_ID   -- Immobilisation
             , AMO.FAM_AMORTIZATION_METHOD_ID   -- M�thode d'amortissement
             , AMO.AMO_ROUNDED_AMOUNT   -- Montant arrondi
             , AMO.C_AMORTIZATION_PERIOD   -- Cadence d'amortissment
             , AMO.C_AMORTIZATION_TYP   -- Type d'amortissment
             , AMO.C_ROUND_TYPE   -- Type d'arrondi
             , AAP.APP_AMORTIZATION_BEGIN   -- D�but d'amortissement
             , AAP.APP_AMORTIZATION_END   -- Fin d'amortissement
             , AAP.FAM_MANAGED_VALUE_ID   -- Valeur g�r�e
             , nvl(DEF.DEF_MIN_RESIDUAL_VALUE, 0) DEF_MIN_RESIDUAL_VALUE   -- Valeur r�siduelle minimum
             , case   --Taux 1 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('1', '3', '5', '6', '9', '60') then nvl(AAP.APP_LIN_AMORTIZATION
                                                                                      , DEF.DEF_LIN_AMORTIZATION
                                                                                       )
                 when AMO.C_AMORTIZATION_TYP in('2', '4') then nvl(AAP.APP_DEC_AMORTIZATION, DEF.DEF_DEC_AMORTIZATION)
                 else 0
               end Rate1
             , case   --Taux 2 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('5', '6', '9', '60') then nvl(AAP.APP_DEC_AMORTIZATION
                                                                            , DEF.DEF_DEC_AMORTIZATION
                                                                             )
                 else null
               end Rate2
             , case   --Coeeficient pour types 6,60
                 when AMO.C_AMORTIZATION_TYP in('6', '60') then nvl(AAP.DIC_FAM_COEFFICIENT_ID
                                                                  , DEF.DIC_FAM_COEFFICIENT_ID
                                                                   )
                 else null
               end COEFFICIENT
             , nvl(AAP.APP_INTEREST_RATE, DEF.DEF_INTEREST_RATE) INTEREST_RATE_1   -- Taux d'int�r�t 1 cascade Application / D�faut
             , nvl(AAP.APP_INTEREST_RATE_2, DEF.DEF_INTEREST_RATE_2) INTEREST_RATE_2   -- Taux d'int�r�t 2 cascade Application / D�faut
             ,
               -- Dur�e d'amortissement syst�matiquement calcul�e(100/taux1)m�me si renseign�e sur la fiche Arrondi � 2 d�c. comme d�finie
               round(100 /
                     decode(decode(AAP.APP_LIN_AMORTIZATION, 0, null, AAP.APP_LIN_AMORTIZATION)
                          , null, decode(DEF.DEF_LIN_AMORTIZATION, 0, null, DEF.DEF_LIN_AMORTIZATION)
                          , AAP.APP_LIN_AMORTIZATION
                           )
                   , 2
                    ) APP_MONTH_DURATION
             ,   --El�ments de structure n�cessaires au calcul selon cascade Cat�gories par valeur / valeur g�r�e
               nvl(DEF.FAM_STRUCTURE_ELEMENT1_ID, VAL.FAM_STRUCTURE_ELEMENT_ID) FAM_STRUCTURE_ELEMENT1_ID   -- Base amortissement 1
             , nvl(DEF.FAM_STRUCTURE_ELEMENT6_ID, VAL.FAM_STRUCTURE_ELEMENT6_ID) FAM_STRUCTURE_ELEMENT6_ID   -- Base amortissement 2
             , nvl(DEF.FAM_STRUCTURE_ELEMENT3_ID, VAL.FAM_STRUCTURE_ELEMENT3_ID) FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
             , nvl(DEF.FAM_STRUCTURE_ELEMENT2_ID, VAL.FAM_STRUCTURE_ELEMENT2_ID) FAM_STRUCTURE_ELEMENT2_ID   -- Base int�r�ts
             , nvl(DEF.FAM_STRUCTURE_ELEMENT4_ID, VAL.FAM_STRUCTURE_ELEMENT4_ID) FAM_STRUCTURE_ELEMENT4_ID   -- Acquisition
          from FAM_FIXED_ASSETS FIX
             , FAM_AMO_APPLICATION AAP
             , FAM_AMORTIZATION_METHOD AMO
             , FAM_DEFAULT DEF
             , FAM_MANAGED_VALUE VAL
         where AAP.FAM_MANAGED_VALUE_ID = aFamManagedValueId
           and FIX.FAM_FIXED_ASSETS_ID = AAP.FAM_FIXED_ASSETS_ID
           and FIX.C_FIXED_ASSETS_STATUS = '01'
           and FIX.C_OWNERSHIP <> '9'
           and AMO.FAM_AMORTIZATION_METHOD_ID = AAP.FAM_AMORTIZATION_METHOD_ID
           and AMO.AMO_AMORTIZATION_PLAN = 1
           and DEF.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
           and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_AMORTIZATION_METHOD_ID = AMO.FAM_AMORTIZATION_METHOD_ID
           and VAL.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
      order by FIX.FIX_NUMBER;

    --Curseur des immobilisations ayant un lien sur la valeur g�r�e et la cat�gorie donn�e
    cursor crFixedByCateg(
      aFamManagedValueId FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
    , aFixCategId        FAM_DEFAULT.FAM_FIXED_ASSETS_CATEG_ID%type
    )
    is
      select   FIX.FAM_FIXED_ASSETS_ID   -- Immobilisation
             , AMO.FAM_AMORTIZATION_METHOD_ID   -- M�thode d'amortissement
             , AMO.AMO_ROUNDED_AMOUNT   -- Montant arrondi
             , AMO.C_AMORTIZATION_PERIOD   -- Cadence d'amortissment
             , AMO.C_AMORTIZATION_TYP   -- Type d'amortissment
             , AMO.C_ROUND_TYPE   -- Type d'arrondi
             , AAP.APP_AMORTIZATION_BEGIN   -- D�but d'amortissement
             , AAP.APP_AMORTIZATION_END   -- Fin d'amortissement
             , AAP.FAM_MANAGED_VALUE_ID   -- Valeur g�r�e
             , nvl(DEF.DEF_MIN_RESIDUAL_VALUE, 0) DEF_MIN_RESIDUAL_VALUE   -- Valeur r�siduelle minimum
             , case   --Taux 1 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('1', '3', '5', '6', '9', '60') then nvl(AAP.APP_LIN_AMORTIZATION
                                                                                      , DEF.DEF_LIN_AMORTIZATION
                                                                                       )
                 when AMO.C_AMORTIZATION_TYP in('2', '4') then nvl(AAP.APP_DEC_AMORTIZATION, DEF.DEF_DEC_AMORTIZATION)
                 else 0
               end Rate1
             , case   --Taux 2 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('5', '6', '9', '60') then nvl(AAP.APP_DEC_AMORTIZATION
                                                                            , DEF.DEF_DEC_AMORTIZATION
                                                                             )
                 else null
               end Rate2
             , case   --Coeeficient pour types 6,60
                 when AMO.C_AMORTIZATION_TYP in('6', '60') then nvl(AAP.DIC_FAM_COEFFICIENT_ID
                                                                  , DEF.DIC_FAM_COEFFICIENT_ID
                                                                   )
                 else null
               end COEFFICIENT
             , nvl(AAP.APP_INTEREST_RATE, DEF.DEF_INTEREST_RATE) INTEREST_RATE_1   -- Taux d'int�r�t 1 cascade Application / D�faut
             , nvl(AAP.APP_INTEREST_RATE_2, DEF.DEF_INTEREST_RATE_2) INTEREST_RATE_2   -- Taux d'int�r�t 2 cascade Application / D�faut
             ,
               -- Dur�e d'amortissement syst�matiquement calcul�e(100/taux1)m�me si renseign�e sur la fiche Arrondi � 2 d�c. comme d�finie
               round(100 /
                     decode(decode(AAP.APP_LIN_AMORTIZATION, 0, null, AAP.APP_LIN_AMORTIZATION)
                          , null, decode(DEF.DEF_LIN_AMORTIZATION, 0, null, DEF.DEF_LIN_AMORTIZATION)
                          , AAP.APP_LIN_AMORTIZATION
                           )
                   , 2
                    ) APP_MONTH_DURATION
             ,   --El�ments de structure n�cessaires au calcul selon cascade Cat�gories par valeur / valeur g�r�e
               nvl(DEF.FAM_STRUCTURE_ELEMENT1_ID, VAL.FAM_STRUCTURE_ELEMENT_ID) FAM_STRUCTURE_ELEMENT1_ID   -- Base amortissement 1
             , nvl(DEF.FAM_STRUCTURE_ELEMENT6_ID, VAL.FAM_STRUCTURE_ELEMENT6_ID) FAM_STRUCTURE_ELEMENT6_ID   -- Base amortissement 2
             , nvl(DEF.FAM_STRUCTURE_ELEMENT3_ID, VAL.FAM_STRUCTURE_ELEMENT3_ID) FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
             , nvl(DEF.FAM_STRUCTURE_ELEMENT2_ID, VAL.FAM_STRUCTURE_ELEMENT2_ID) FAM_STRUCTURE_ELEMENT2_ID   -- Base int�r�ts
             , nvl(DEF.FAM_STRUCTURE_ELEMENT4_ID, VAL.FAM_STRUCTURE_ELEMENT4_ID) FAM_STRUCTURE_ELEMENT4_ID   -- Acquisition
          from FAM_FIXED_ASSETS FIX
             , FAM_AMO_APPLICATION AAP
             , FAM_AMORTIZATION_METHOD AMO
             , FAM_DEFAULT DEF
             , FAM_MANAGED_VALUE VAL
         where AAP.FAM_MANAGED_VALUE_ID = aFamManagedValueId
           and FIX.FAM_FIXED_ASSETS_ID = AAP.FAM_FIXED_ASSETS_ID
           and FIX.FAM_FIXED_ASSETS_CATEG_ID = aFixCategId
           and FIX.C_FIXED_ASSETS_STATUS = '01'
           and FIX.C_OWNERSHIP <> '9'
           and AMO.FAM_AMORTIZATION_METHOD_ID = AAP.FAM_AMORTIZATION_METHOD_ID
           and AMO.AMO_AMORTIZATION_PLAN = 1
           and DEF.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
           and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
           and DEF.FAM_AMORTIZATION_METHOD_ID = AMO.FAM_AMORTIZATION_METHOD_ID
           and VAL.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
      order by FIX.FIX_NUMBER;

    tplManagedValues crManagedValues%rowtype;
    tplFixedByValue  crFixedByValue%rowtype;
    tplFixedByCateg  crFixedByCateg%rowtype;
    vManagedValueId  FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type;
    vFixCategId      FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_CATEG_ID%type;
    vFixByCateg      boolean;
  begin
    vManagedValueId  := 0;
    vFixCategId      := 0;

    --Ouverture et parcours du curseur des valeurs g�r�es
    open crManagedValues(aStrElementId);

    fetch crManagedValues
     into tplManagedValues;

    -- Pour chaque tuple Valeur g�r�e - Cat�gorie :
    --       Si cat�gorie renseign�e ...calcul uniquement pour cette cat�gorie
    --       Sinon calcul pour toutes les cat�gories avec la valeur g�r�e courante
    -- V1....0
    -- V1....C1
    -- V2....C1
    while crManagedValues%found loop
      vFixByCateg  := false;

      if vManagedValueId <> tplManagedValues.FAM_MANAGED_VALUE_ID then
        vFixCategId  := 0;

        if vFixCategId <> tplManagedValues.FAM_FIXED_ASSETS_CATEG_ID then
          vFixCategId  := tplManagedValues.FAM_FIXED_ASSETS_CATEG_ID;
          vFixByCateg  := true;
        else
          vFixByCateg  := false;
        end if;
      elsif     (vFixCategId <> 0)
            and (vFixCategId <> tplManagedValues.FAM_FIXED_ASSETS_CATEG_ID) then
        vFixCategId  := tplManagedValues.FAM_FIXED_ASSETS_CATEG_ID;
        vFixByCateg  := true;
      end if;

      if vFixByCateg then
        --Ouverture et parcours du curseur des immobilisations li�es � la valeur g�r�e courante et la cat�gorie
        --Traitement pour chaque immobilisation retourn�e par le curseur...et non pas pour une fourchette donn�e
        open crFixedByCateg(tplManagedValues.FAM_MANAGED_VALUE_ID, tplManagedValues.FAM_FIXED_ASSETS_CATEG_ID);

        fetch crFixedByCateg
         into tplFixedByCateg;

        while crFixedByCateg%found loop
          FAM_AMORTIZATION_PLAN.CalculateAmortizationPlan
                                            (tplFixedByCateg.FAM_FIXED_ASSETS_ID   --Immobilisation
                                           , tplFixedByCateg.FAM_MANAGED_VALUE_ID   --Valeur g�r�e
                                           , tplFixedByCateg.FAM_AMORTIZATION_METHOD_ID   --M�thode amortissement
                                           , tplFixedByCateg.FAM_STRUCTURE_ELEMENT1_ID   --El�ment "Base amortissement"
                                           , tplFixedByCateg.FAM_STRUCTURE_ELEMENT2_ID   --El�ment "Base int�r�ts"
                                           , tplFixedByCateg.FAM_STRUCTURE_ELEMENT3_ID   --El�ment "Limite amortissement"
                                           , tplFixedByCateg.FAM_STRUCTURE_ELEMENT4_ID   --El�ment "Acquisition"
                                           , tplFixedByCateg.FAM_STRUCTURE_ELEMENT6_ID   --El�ment "Base amortissement 6"
                                           , tplFixedByCateg.C_AMORTIZATION_TYP   --Type amortissement
                                           , tplFixedByCateg.C_AMORTIZATION_PERIOD   --Cadence
                                           , tplFixedByCateg.APP_AMORTIZATION_BEGIN   --D�but amortissement
                                           , tplFixedByCateg.APP_MONTH_DURATION   --Dur�e amortissement
                                           , tplFixedByCateg.Rate1   --Taux 1
                                           , tplFixedByCateg.Rate2   --Taux 2
                                           , tplFixedByCateg.COEFFICIENT   --Coefficient
                                           , tplFixedByCateg.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                                           , tplFixedByCateg.C_ROUND_TYPE   --Type arrondi
                                           , tplFixedByCateg.AMO_ROUNDED_AMOUNT   --Montant arrondi
                                           , 1
                                           , 0
                                            );

          fetch crFixedByCateg
           into tplFixedByCateg;
        end loop;

        close crFixedByCateg;
      else
        --Ouverture et parcours du curseur des immobilisations li�es � la valeur g�r�e courante
        --Traitement pour chaque immobilisation retourn�e par le curseur...et non pas pour une fourchette donn�e
        open crFixedByValue(tplManagedValues.FAM_MANAGED_VALUE_ID);

        fetch crFixedByValue
         into tplFixedByValue;

        while crFixedByValue%found loop
          FAM_AMORTIZATION_PLAN.CalculateAmortizationPlan
                                            (tplFixedByValue.FAM_FIXED_ASSETS_ID   --Immobilisation
                                           , tplFixedByValue.FAM_MANAGED_VALUE_ID   --Valeur g�r�e
                                           , tplFixedByValue.FAM_AMORTIZATION_METHOD_ID   --M�thode amortissement
                                           , tplFixedByValue.FAM_STRUCTURE_ELEMENT1_ID   --El�ment "Base amortissement"
                                           , tplFixedByValue.FAM_STRUCTURE_ELEMENT2_ID   --El�ment "Base int�r�ts"
                                           , tplFixedByValue.FAM_STRUCTURE_ELEMENT3_ID   --El�ment "Limite amortissement"
                                           , tplFixedByValue.FAM_STRUCTURE_ELEMENT4_ID   --El�ment "Acquisition"
                                           , tplFixedByValue.FAM_STRUCTURE_ELEMENT6_ID   --El�ment "Base amortissement 6"
                                           , tplFixedByValue.C_AMORTIZATION_TYP   --Type amortissement
                                           , tplFixedByValue.C_AMORTIZATION_PERIOD   --Cadence
                                           , tplFixedByValue.APP_AMORTIZATION_BEGIN   --D�but amortissement
                                           , tplFixedByValue.APP_MONTH_DURATION   --Dur�e amortissement
                                           , tplFixedByValue.Rate1   --Taux 1
                                           , tplFixedByValue.Rate2   --Taux 2
                                           , tplFixedByValue.COEFFICIENT   --Coefficient
                                           , tplFixedByValue.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                                           , tplFixedByValue.C_ROUND_TYPE   --Type arrondi
                                           , tplFixedByValue.AMO_ROUNDED_AMOUNT   --Montant arrondi
                                           , 1
                                           , 0
                                            );

          fetch crFixedByValue
           into tplFixedByValue;
        end loop;

        close crFixedByValue;
      end if;

      fetch crManagedValues
       into tplManagedValues;
    end loop;

    close crManagedValues;
  end AfterInsertDeleteDetails;
begin
  gUserIni   := PCS.PC_I_LIB_SESSION.GetUserIni;
  gCurrName  := ACS_FUNCTION.GetLocalCurrencyName;
end FAM_AMORTIZATION_PLAN;
