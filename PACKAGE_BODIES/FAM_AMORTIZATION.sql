--------------------------------------------------------
--  DDL for Package Body FAM_AMORTIZATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAM_AMORTIZATION" 
is
  function GetAmortizationEndDate(
    pDuration  in FAM_AMO_APPLICATION.APP_MONTH_DURATION%type
  , pBeginDate in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  )
    return ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  is
    vResult                ACS_FINANCIAL_YEAR.FYE_END_DATE%type;   --Valeur de retour
    --Mois et jour de la date d�but exercice de l'exercice suivant l'exercice comprenant la date de d�but d'amortissement
    vNextYearStartMonthDay number(4);
    --Nombre de mois couvert par l'exercice contenant la date d�but d'amortissement
    vExerciseMonthNumber   number(3);
    --Ann�e CALCULEE selon r�gles de la date d�but amortissement calcul�e sous format num�rique
    vExerciseYear          number(4);
    --Ann�e de la date d�but amortissement sous forme num�rique
    vAmoBeginExerciseYear  number(4);
    --Mois et jour de la date d�but amortissement sous forme num�rique selon format 'MMDD'
    vAmoBeginMonthDay      number(4);
    --Date de r�f�rence calcul�e de d�but amortissement
    vRefDateAmoBegin       ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
    --Date d�but exercice de l'exercice de d�but amortissement
    vAmoBeginExerciseStart ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    vRefDateAmoBegin  := pBeginDate;

    begin
      /**
      * Calcul de la date de r�f�rence � partir de laquelle on ajoute la dur�e pour calculer la date de fin amortissement.
      * Cete date change selon que la date de d�but amortissement est dans un exercice couvrant plusieurs ann�es civiles ou
      * que la date d�but exercice n'est pas le 01.janvier civil.
      *
      * Si l'exercice dans lequel se trouve la date d�but amortissement couvre plus de 23 mois (round) :
      * Rechercher le mois et le jour (MM.DD) de d�but 'standard' des exercice comptable
      * (la date pourra�t �tre d�cal�e par rapport au d�but de l'exercice civile)
      * MM.DD de la date d�but du prochain exercice comptable (dans notre exemple : '01.01')
      * Si 'MM.DD' de la date d�but amortissement (01.31 dans notre exemple) >= 'MM.DD'. Recherch� ('01.01') -->
      * ann�e (YYYY) = ann�e de la date d�but amortissement ('2002' dans notre exemple)
      * Date d�but calcul dur�e : 01.01.2002
      * Si 'MM.DD' de la date d�but amortissement  < 'MM.DD'. Recherch� --> ann�e (YYYY) = ann�e de la date d�but amortissement - 1
      * Exemple : exercice 2 : 01.04.2004
      * Date d�but calcul dur�e : 01.04.2001 (2002 - 1, parce que '01.31' est plus petit que '04.01'
      *
      * A�  - Nombre de mois couvert par l'exercice contenant la date d�but d'amortissement
      * B�  - Ann�e de la date d�but amortissement sous forme num�rique
      * C�  - Mois et jour de la date d�but amortissement sous forme num�rique selon format 'MMDD'
      * D�  - Mois et jour de la date d�but exercice de l'exercice suivant l'exercice contenant la date d�but amortissement
      *       sous forme num�rique selon format 'MMDD'
      * E�  - Date d�but exercice de l'exercice couvrant la date d�but amortissement
      **/
      select abs(round(months_between(FIX_YEAR.FYE_END_DATE, FIX_YEAR.FYE_START_DATE) ) ) A
           , to_number(to_char(pBeginDate, 'YYYY') ) B
           , to_number(to_char(pBeginDate, 'MMDD') ) C
           , nvl(to_number(to_char(NEXT_YEAR.FYE_START_DATE, 'MMDD') ), 101) D
           , FIX_YEAR.FYE_START_DATE E
        into vExerciseMonthNumber
           , vAmoBeginExerciseYear
           , vAmoBeginMonthDay
           , vNextYearStartMonthDay
           , vAmoBeginExerciseStart
        from ACS_FINANCIAL_YEAR FIX_YEAR
           , ACS_FINANCIAL_YEAR NEXT_YEAR
       where (vRefDateAmoBegin between FIX_YEAR.FYE_START_DATE and FIX_YEAR.FYE_END_DATE)
         and (NEXT_YEAR.FYE_NO_EXERCICE(+) = FIX_YEAR.FYE_NO_EXERCICE + 1);

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

    /**
    * Date r�f�rence est incr�ment�e du nombre de mois du nombre d'ann�e totale, on obtient la date de fin amortissement calcul�e
    **/
    select add_months(vRefDateAmoBegin,(pDuration * 12) ) - 1
      into vResult
      from dual;

    return vResult;
  end GetAmortizationEndDate;

  function GetCoveredDays(
    pAmortizationType in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type
  , pPeriodId         in FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type
  , pEndDate          in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  )
    return FAM_CALC_AMORTIZATION.CAL_DAYS%type
  is
    vResult                    number(4);
    vCalcStartDateMonth        number(2);   --R�ceptionne le mois de la date de d�but de calcul de jours
    vCalcEndDateMonth          number(2);   --R�ceptionne le mois de la date de fin de calcul de jours
    vCalcStartDateDay          number(2);   --R�ceptionne le jour de la date d�but
    vCalcEndDateDay            number(2);   --R�ceptionne le jour de la date fin
    vCalcStartDateMonthLastDay number(2);   --R�ceptionne le dernier jour du mois de d�but de calcul de jours
    vCalcEndDateMonthLastDay   number(2);   --R�ceptionne le dernier jour du mois de fin de calcul de jours
    vCalcStartDateYear         number(4);   --R�ceptionne l'ann�e de la date de d�but de calcul
    vCalcEndDateYear           number(4);   --R�ceptionne l'ann�e de la date de fin de calcul
  begin
    begin
      if pAmortizationType = '4' then   /** Cadence annuelle **/
        vResult  := 360;
      elsif pAmortizationType = '1' then                                         /** Cadence mensuelle **/
                                           /* Calcul du nombre de jours */
        select to_number(to_char(PER.PER_START_DATE, 'MM') )
             , to_number(to_char(pEndDate, 'MM') )
             , to_number(to_char(PER.PER_START_DATE, 'DD') )
             , to_number(to_char(pEndDate, 'DD') )
             , to_number(to_char(last_day(PER.PER_START_DATE), 'DD') )
             , to_number(to_char(last_day(pEndDate), 'DD') )
             , to_number(to_char(PER.PER_START_DATE, 'YYYY') )
             , to_number(to_char(pEndDate, 'YYYY') )
          into vCalcStartDateMonth
             , vCalcEndDateMonth
             , vCalcStartDateDay
             , vCalcEndDateDay
             , vCalcStartDateMonthLastDay
             , vCalcEndDateMonthLastDay
             , vCalcStartDateYear
             , vCalcEndDateYear
          from ACS_PERIOD PER
         where PER.ACS_PERIOD_ID = pPeriodId
           and pEndDate between PER.PER_START_DATE and PER.PER_END_DATE;

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
      end if;
    exception
      when no_data_found then
        vResult  := 360;
    end;

    return vResult;
  end GetCoveredDays;

  function GetAmortizationDays(
    pFixAssetsId           in FAM_CALC_AMORTIZATION.FAM_FIXED_ASSETS_ID%type
  , pManagedValId          in FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , pAmortizationType      in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type
  , pPerStartDate          in ACS_PERIOD.PER_START_DATE%type
  , pPerEndDate            in ACS_PERIOD.PER_END_DATE%type
  , pYearStartDate         in ACS_PERIOD.PER_START_DATE%type
  , pYearEndDate           in ACS_PERIOD.PER_END_DATE%type
  , pAmortizationStartDate in FAM_AMO_APPLICATION.APP_AMORTIZATION_BEGIN%type
  , pAmortizationEndDate   in FAM_AMO_APPLICATION.APP_AMORTIZATION_END%type
  , pIsSimulation          in number default 0
  , pIsBudget              in number default 0
  )
    return FAM_CALC_AMORTIZATION.CAL_DAYS%type
  is
    vCoverBeginDate            ACS_PERIOD.PER_START_DATE%type;   --R�ceptionne la date d�but de la p�riode / ann�e selon le cadencement
    vCoverEndDate              ACS_PERIOD.PER_END_DATE%type;   --R�ceptionne la date fin de la p�riode / ann�e selon le cadencement
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
    vDays                      FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --R�ceptionne le nombre de jours calcul�s
  begin
    /* R�ception des dates d�but et fin � prendre en comte selon cadencement*/
    if pAmortizationType = '1' then   -- Cadence p�riodique
      vCoverBeginDate  := pPerStartDate;   -- => Date prise en compte =  dates d�but et fin p�riode
      vCoverEndDate    := pPerEndDate;
    elsif pAmortizationType = '4' then   -- Cadence annuelle
      vCoverBeginDate  := pYearStartDate;   -- => Date prise en compte =  dates d�but et fin exercice
      vCoverEndDate    := pYearEndDate;
    end if;

    /* D�termination de la date d�but de calcul selon la date d�but amortissement de l'immob*/
    if pAmortizationStartDate < vCoverBeginDate then   --D�but d'amortissement est ant�rieure � la p�riode consid�r�e
      if     (FAM_AMORTIZATION.AmortizationImputations(pAmortizationType, pFixAssetsId, pManagedValId, null) = 0)
         and (FAM_AMORTIZATION.InterestImputations(pAmortizationType, pFixAssetsId, pManagedValId, null) = 0) then
        if pIsSimulation = 0 then
          if pAmortizationStartDate < pYearStartDate then   -- Si aucun amortissement n'a encore �t� fait pour l'immobilisation et la valeur g�r�e,
            vCalcDaysStart  := pYearStartDate;   --ind�pendamment de la p�riode comptable
          else   -- => Calcul depuis le d�but de l'exercice (resp. depuis le d�but amortissment si
            vCalcDaysStart  := pAmortizationStartDate;   --    d�but amortissment est post�rieur au d�but de l'exercice)
          end if;   -- sinon date d�but de calcul = date d�but selon cadencement
        elsif pIsSimulation = 1 then   --Si aucun amortissement n'a encore �t� fait pour l'immobilisation et la valeur g�r�e
          if     (abs(pIsBudget) = 1)
             and (sign(pIsBudget) = 1) then
            if pAmortizationStartDate < pYearStartDate then   -- => Calcul depuis le d�but de l'exercice (resp. depuis le d�but amortissment si
              vCalcDaysStart  := pYearStartDate;   --    d�but amortissment est post�rieur au d�but de l'exercice) uniquement
            else   -- pour la premi�re p�riode de simulation
              vCalcDaysStart  := pAmortizationStartDate;   --sinon date d�but de calcul = date d�but selon cadencement
            end if;
          else
            vCalcDaysStart  := vCoverBeginDate;
          end if;
        end if;
      else
        vCalcDaysStart  := vCoverBeginDate;
      end if;
    elsif pAmortizationStartDate between vCoverBeginDate and vCoverEndDate then   --D�but d'amortissement est compris dans l'intervalle
      vCalcDaysStart  := pAmortizationStartDate;   -- => Date d�but de calcul = date d�but d'amortissement
    else
      vCalcDaysStart  := null;
    end if;

    /* D�termination de la date finde calcul selon la date fin amortissement de l'immob*/
    if pAmortizationEndDate is not null then
      if pAmortizationEndDate between vCoverBeginDate and vCoverEndDate then   --Fin d'amortissement est compris dans l'intervalle
        vCalcDaysEnd  := pAmortizationEndDate;   -- => Date fin de calcul = date fin d'amortissement
      elsif pAmortizationEndDate > vCoverEndDate then   --Fin d'amortissement est post�rieur � la date de fiin de l'intervalle consid�r�e
        vCalcDaysEnd  := vCoverEndDate;   -- => Date fin de calcul = date fin d'amortissement
      else
        vCalcDaysEnd  := null;
      end if;
    else
      vCalcDaysEnd  := vCoverEndDate;
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

    -- date d�but et date fin sont dans le m�me mois de la m�me ann�e
    if     (vCalcStartDateMonth = vCalcEndDateMonth)
       and (vCalcStartDateYear = vCalcEndDateYear) then
      --Si date de fin > 27 pour le mois de f�vrier...
      -- => 30 jours pour les mois complets
      if (vCalcStartDateMonth = 2) and (vCalcEndDateDay > 27) then
        vDays  := 30-vCalcStartDateDay +1;
      else
        vDays  := vCalcEndDateDay - vCalcStartDateDay + 1;
      end if;
    else
      --                             |           nombre de jours par mois complet s�parant les deux dates                |
      --       |jours du mois d�but  | |mois complet s�parant les 2 dates  |   |12 mois par ann�e de diff�rence    |     |jours du mois fin|
      vDays  :=
        30 -
        vCalcStartDateDay +
        ( ( (vCalcEndDateMonth - vCalcStartDateMonth) - 1 +( (vCalcEndDateYear - vCalcStartDateYear) * 12) ) * 30
        ) +
        vCalcEndDateDay +
        1;
    end if;

    return vDays;
  end GetAmortizationDays;

-----------------------------
  procedure CategoryCalculation(
    pPeriodId       in     FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type
  , pManagedValueId in     FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , pFixCategId     in     FAM_FIXED_ASSETS_CATEG.FAM_FIXED_ASSETS_CATEG_ID%type
  , pIndicator      out    number
  )
  is
    /*Curseur globale de recherche selon param�tres g�n�rales de la proc�dure*/
    cursor FixedAssetsCursor
    is
      select FIX.FAM_FIXED_ASSETS_ID   -- Amortissement
           , FIX.C_OWNERSHIP --Propri�t�
           , AMO.AMO_AMORTIZATION_PLAN   -- Plan d'amortissement
           , AMO.FAM_AMORTIZATION_METHOD_ID   -- M�thode d'amortissement
           , AMO.AMO_ROUNDED_AMOUNT   -- Montant arrondi
           , AMO.AMO_ROUNDED_AMOUNT_INT   -- Montant arrondi int�r�t
           , AMO.C_AMORTIZATION_PERIOD   -- Cadence d'amortissment
           , case   --Taux 1 selon type amortissement
               when AMO.C_AMORTIZATION_TYP in('1', '3', '5', '6') then nvl(AAP.APP_LIN_AMORTIZATION
                                                                         , DEF.DEF_LIN_AMORTIZATION
                                                                                       )
               when AMO.C_AMORTIZATION_TYP in('2', '4') then nvl(AAP.APP_DEC_AMORTIZATION, DEF.DEF_DEC_AMORTIZATION)
               else 0
             end Rate1
           , AMO.C_INTEREST_CALC_RULES
             , case   --Taux 2 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('5', '6') then nvl(AAP.APP_DEC_AMORTIZATION
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
           , nvl(AAP.APP_INTEREST_RATE, DEF.DEF_INTEREST_RATE)   INTEREST_RATE_1 -- Taux d'int�r�t 1
           , nvl(AAP.APP_INTEREST_RATE_2, DEF.DEF_INTEREST_RATE_2)   INTEREST_RATE_2 -- Taux d'int�r�t 2
           , AMO.C_AMORTIZATION_TYP   -- Type d'amortissment
           , AMO.C_ROUND_TYPE   -- Type d'arrondi
           , AMO.C_ROUND_TYPE_INT   -- Type d'arrondi int�r�t
           , AAP.APP_AMORTIZATION_BEGIN   -- D�but d'amortissement
           , AAP.APP_AMORTIZATION_END   -- Fin d'amortissement
           , round
               (100 /
                decode
                  (decode
                     (AAP.APP_LIN_AMORTIZATION
                    , 0, null
                    , AAP.APP_LIN_AMORTIZATION
                     )   --La dur�e est syst�matiquement calcul�e (100 / taux1) m�me si elle est renseign�e
                 , null, decode(nvl(DEF.DEF_LIN_AMORTIZATION,0), 0, null, DEF.DEF_LIN_AMORTIZATION)
                 , AAP.APP_LIN_AMORTIZATION
                  )
              , 2
               ) APP_MONTH_DURATION
           ,   /**Les �l�ments de structures n�cessaires; d'abord ceux des cat�gories / Valeur et Ensuite ceux des valeurs*/
             nvl(DEF.FAM_STRUCTURE_ELEMENT1_ID, VAL.FAM_STRUCTURE_ELEMENT_ID) FAM_STRUCTURE_ELEMENT_ID   -- Base amortissement 1
           , nvl(DEF.FAM_STRUCTURE_ELEMENT6_ID, VAL.FAM_STRUCTURE_ELEMENT6_ID) FAM_STRUCTURE_ELEMENT6_ID   -- Base amortissement 2
           , nvl(DEF.FAM_STRUCTURE_ELEMENT3_ID, VAL.FAM_STRUCTURE_ELEMENT3_ID) FAM_STRUCTURE_ELEMENT3_ID   -- Limite amortissment
           , nvl(DEF.FAM_STRUCTURE_ELEMENT2_ID, VAL.FAM_STRUCTURE_ELEMENT2_ID) FAM_STRUCTURE_ELEMENT2_ID   -- Base int�r�ts
           , nvl(DEF.FAM_STRUCTURE_ELEMENT4_ID, VAL.FAM_STRUCTURE_ELEMENT4_ID) FAM_STRUCTURE_ELEMENT4_ID   --Acquisition
           , PER.PER_START_DATE   -- D�but p�riode amortissement
           , PER.PER_END_DATE   -- Fin p�riode amortissement
           , PER2.PER_START_DATE YEAR_START_DATE   -- D�but exercice comptable
           , PER2.PER_END_DATE YEAR_END_DATE   -- Fin exercice comptable
           , DEF.DEF_MIN_RESIDUAL_VALUE   -- Valeur r�siduelle minimum
           , decode(nvl(AAP.APP_NEGATIVE_BASE,0),0, DEF.DEF_NEGATIVE_BASE, AAP.APP_NEGATIVE_BASE) APP_NEGATIVE_BASE
        from (select min(PER_START_DATE) PER_START_DATE
                   , max(PER_END_DATE) PER_END_DATE
                from ACS_PERIOD
               where ACS_FINANCIAL_YEAR_ID = (select ACS_FINANCIAL_YEAR_ID
                                                from ACS_PERIOD
                                               where ACS_PERIOD_ID = pPeriodId) ) PER2
           , ACS_PERIOD PER
           , FAM_MANAGED_VALUE VAL
           , FAM_AMORTIZATION_METHOD AMO
           , FAM_FIXED_ASSETS FIX
           , FAM_DEFAULT DEF
           , FAM_AMO_APPLICATION AAP
       where FIX.FAM_FIXED_ASSETS_CATEG_ID = pFixCategId
         and AAP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
         and AAP.FAM_MANAGED_VALUE_ID = pManagedValueId
         and AMO.FAM_AMORTIZATION_METHOD_ID = AAP.FAM_AMORTIZATION_METHOD_ID
         and VAL.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
         and FIX.C_FIXED_ASSETS_STATUS = '01'
         and FIX.C_OWNERSHIP <> '9'
         and DEF.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
         and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
         and DEF.FAM_AMORTIZATION_METHOD_ID = AMO.FAM_AMORTIZATION_METHOD_ID
         and PER.ACS_PERIOD_ID = pPeriodId
         and AAP.APP_AMORTIZATION_BEGIN <= PER.PER_END_DATE
         /**
         * Cadence amortissement 1(Mensuelle) => En tous les cas
         *                       4(Annuelle)  => Uniquement si p�riode de calcul = Derni�re p�ridoe exercice
         **/
         and decode(AMO.C_AMORTIZATION_PERIOD   -- Cadence d'amortissement
                  , '1', 1   --     Mensuelle ->    OK
                  , '4', decode(to_char(PER.PER_START_DATE, 'MM')   --     Annuelle  ->  mois d�but amortissment
                              , to_char(PER2.PER_END_DATE, 'MM'), 1   --                 = mois de fin d'exercice => OK
                              , 0
                               )
                  , 0
                   ) = 1
         /**
         * Pas d'amortissement calcul� pour le tuple Immobilisation, valeur g�r�e, p�riode courante
         **/
         and not exists(
               select 1
                 from FAM_CALC_AMORTIZATION CAL
                    , FAM_PER_CALC_BY_VALUE CVAL
                where CVAL.ACS_PERIOD_ID = pPeriodId
                  and CVAL.FAM_MANAGED_VALUE_ID = pManagedValueId
                  and CVAL.FAM_PER_CALC_BY_VALUE_ID = CAL.FAM_PER_CALC_BY_VALUE_ID
                  and CAL.FAM_FIXED_ASSETS_ID = AAP.FAM_FIXED_ASSETS_ID)
         /**
         * Fin d'amortissement si renseign�  � Est >= � fin p�riode courante pour types <> 6 � Est >= � fin exercice de la p�riode pour types 6
         **/
         and (   AAP.APP_AMORTIZATION_END is null
              or (    AMO.C_AMORTIZATION_TYP <> '6'
                  and AAP.APP_AMORTIZATION_END is not null
                  and AAP.APP_AMORTIZATION_END >= PER.PER_START_DATE
                 )
              or (    AMO.C_AMORTIZATION_TYP = '6'
                  and AAP.APP_AMORTIZATION_END is not null
                  and AAP.APP_AMORTIZATION_END >= PER2.PER_START_DATE
                 )
             )
         /**
         * Pas d'amortissement imput� pour le tuple Immobilisation, valeur g�r�e, p�riode courante
         **/
         and FAM_AMORTIZATION.AmortizationImputations
                                        (AMO.C_AMORTIZATION_PERIOD,   --Pas d'amortissement (imput�) pour l'immobilisation,
                                         AAP.FAM_FIXED_ASSETS_ID,   --la valeur g�r�e et la p�riode couverte
                                         pManagedValueId, pPeriodId) = 0;

    --Types 6, c'est la date de fin de l'exercice de la date "fin d'amortissement" qui ne doit pas �tre d�pass�e
    --Autres types, Date de fin amortissement doit �tre  >= � la date d�but p�riode de calcul
    vCurrentFixedAssets   FixedAssetsCursor%rowtype;   --R�ceptionne les infos du curseur de recherche des informations de l'immob.
    vCurrentCalcByValueId FAM_PER_CALC_BY_VALUE.FAM_PER_CALC_BY_VALUE_ID%type;   --R�ceptionne l'id du calcul p�riodique par valeur courante
    vAmortizationRate     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --R�ceptionne le taux d'amortissement
    vAmortizationDays     FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --Nombre de jours d'amortissement
    vAmortizationExercise number(3);   --Nombre d'exercice encore � amortir
    vExistAmortization    number(1);   --R�ceptionne 1(0)  pour indiquer l'existence d'amortissement
    vCalculatedEndDate    FAM_AMO_APPLICATION.APP_AMORTIZATION_END%type;   --Date fin d'amortissement caclul�
    vCoveredDays          FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --Nombre de jours couverts dans l'exercice pour type 6 mensualis�
    vPlanHeaderId         FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type;
    vErrCode              number(1);
    vErrText              varchar2(5000);
  begin
    /* R�ception de l'id du calcul p�riodique par valeur                                                */
    select FAM_PER_CALC_BY_VALUE_ID
      into vCurrentCalcByValueId
      from FAM_PER_CALC_BY_VALUE
     where ACS_PERIOD_ID = pPeriodId
       and FAM_MANAGED_VALUE_ID = pManagedValueId;

    /*Recherche et parcours des informations des immobilisations                                        */
    open FixedAssetsCursor;

    fetch FixedAssetsCursor
     into vCurrentFixedAssets;

    while FixedAssetsCursor%found loop
      vCoveredDays       := 360;
      vAmortizationRate  := vCurrentFixedAssets.Rate1;
      gNegativeBase      := vCurrentFixedAssets.APP_NEGATIVE_BASE;

      /*Calcul du nombre de jours a amortir pour types <> 6 avec la date de fin amortissement renseign�e au niveau de la fiche  */
      if vCurrentFixedAssets.C_AMORTIZATION_TYP <> '6' then
        vCalculatedEndDate  := vCurrentFixedAssets.APP_AMORTIZATION_END;
        vAmortizationDays   :=
          GetAmortizationDays(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immobilisation
                            , pManagedValueId   --Valeur g�r�e
                            , vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
                            , vCurrentFixedAssets.PER_START_DATE   --D�but p�riode
                            , vCurrentFixedAssets.PER_END_DATE   --Fin p�riode
                            , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
                            , vCurrentFixedAssets.YEAR_END_DATE   --Fin d'exercice
                            , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   --D�but d'amortissement
                            , vCalculatedEndDate   --Fin d'amortissement
                            , 0   --Indique si simulation (1) ou non(0)
                            , 0   --Indique si budget (1) ou non(0)
                             );
      /*Calcul du nombre de jours a amortir pour types 6 avec la date de fin amortissement calcul�e   */
      elsif     (vCurrentFixedAssets.C_AMORTIZATION_TYP = '6')
            and (not vCurrentFixedAssets.APP_MONTH_DURATION is null) then
        /**Initialisation de la date caclul�e avec fin d'exercice courant **/
        vCalculatedEndDate     := vCurrentFixedAssets.YEAR_END_DATE;
        /**
        * R�ception du nombre d'ann�es encore � amortir (vAmortizationExercise)
        * calcul de la date de fin d'amortissement calcul�e (vCalculatedEndDate) et du nombre de jours prise en consid�ration (vCoveredDays)
        **/
        vCalculatedEndDate     :=
          GetAmortizationEndDate(vCurrentFixedAssets.APP_MONTH_DURATION   -- Dur�e
                               , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   -- D�but d'amortissement
                                );
        vAmortizationExercise  := AmortizationExercise(pPeriodId,   --P�riode de calcul
                                                       vCalculatedEndDate);
        vCoveredDays           :=
          GetCoveredDays(vCurrentFixedAssets.C_AMORTIZATION_PERIOD,   --Cadence d'amortissement
                         pPeriodId,   --P�riode de calcul
                         vCalculatedEndDate   -- Fin d'amortissement
                                           );
        /**
        * R�ception du nombre de jours � amortir (vAmortizationDays)
        **/
        vAmortizationDays      :=
          GetAmortizationDays(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immobilisation
                            , pManagedValueId   --Valeur g�r�e
                            , vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
                            , vCurrentFixedAssets.PER_START_DATE   --D�but p�riode
                            , vCurrentFixedAssets.PER_END_DATE   --Fin p�riode
                            , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
                            , vCurrentFixedAssets.YEAR_END_DATE   --Fin d'exercice
                            , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   --D�but d'amortissement
                            , vCalculatedEndDate   --Fin d'amortissement CALCULE
                            , 0   --Indique si simulation (1) ou non(0)
                            , 0   --Indique si budget (1) ou non(0)
                             );
        /**
        * Si amortissements existent d�j� pour l'exercice , le taux 2 � du etre m�j lors du premier calcul
        * et donc la suite des op�rations se fait avec cette valeur si elle n'est pas nulle .
        * Si pas d'amortissement pour l'ann�e en cours ou que la valeur du taux 2 est nulle --> Calcul du taux et m�j du taux 2
        * avec le taux le + favorable utilis� pour le calcul
        **/
        vExistAmortization     :=
                       AmortizationImputations('4', vCurrentFixedAssets.FAM_FIXED_ASSETS_ID, pManagedValueId, pPeriodId);

        if     (vExistAmortization = 1)
           and (not vCurrentFixedAssets.Rate2 is null) then
          vAmortizationRate  := vCurrentFixedAssets.Rate2;
        else
          vAmortizationRate  := 100 / vAmortizationExercise;

          if (vAmortizationRate < vCurrentFixedAssets.Rate1 * to_number(vCurrentFixedAssets.COEFFICIENT) ) then
            vAmortizationRate  := vCurrentFixedAssets.Rate1 * to_number(vCurrentFixedAssets.COEFFICIENT);
          end if;
        end if;
      end if;

      --M�thode d'amortissement est coch�e "Plan d'amortissement"
      if vCurrentFixedAssets.AMO_AMORTIZATION_PLAN = 1 then
        FAM_AMORTIZATION_PLAN.gNegativeBase := FAM_AMORTIZATION.gNegativeBase;
        --G�n�rer les plans manquants si certaines fiches n'ont pas de plan avec le statut 0 ou 1
        if     (FAM_AMORTIZATION_PLAN.ExistFamPlanByManagedValue(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                                                               , pManagedValueId
                                                               , '0'
                                                               , '00'
                                                               , vPlanHeaderId
                                                                ) = 0
               )
           and (FAM_AMORTIZATION_PLAN.ExistFamPlanByManagedValue(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                                                               , pManagedValueId
                                                               , '1'
                                                               , '00'
                                                               , vPlanHeaderId
                                                                ) = 0
               ) then
          FAM_AMORTIZATION_PLAN.CalculateAmortizationPlan
                                               (vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immob
                                              , pManagedValueId   --Valeur g�r�e
                                              , vCurrentFixedAssets.FAM_AMORTIZATION_METHOD_ID   --M�thode amortissement
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID   --Base amortissement 1
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --El�ment "Base int�r�ts"
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT4_ID   --El�ment "Acquisition"
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT6_ID   --Base amortissement 2
                                              , vCurrentFixedAssets.C_AMORTIZATION_TYP   --Type de calcul amortissement
                                              , vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
                                              , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   --D�but amortissement
                                              , vCurrentFixedAssets.APP_MONTH_DURATION   --Dur�e amortissement
                                              , vAmortizationRate   --Taux amortissement1
                                              , vCurrentFixedAssets.Rate2   --Taux amortissement2
                                              , vCurrentFixedAssets.COEFFICIENT
                                              , vCurrentFixedAssets.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                                              , vCurrentFixedAssets.C_ROUND_TYPE   --Type arrondi amortissement
                                              , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT   --Montant arrondi amortissement
                                              , 1
                                              , 0
                                               );
        elsif(FAM_AMORTIZATION_PLAN.ExistFamPlanByManagedValue(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                                                             , pManagedValueId
                                                             , '0'
                                                             , '00'
                                                             , vPlanHeaderId
                                                              ) = 1
             ) then
          FAM_AMORTIZATION_PLAN.ValidatePlan(vPlanHeaderId, vErrCode, vErrText, -1);
        end if;

        --G�n�ration des �critures d'int�r�ts en tous les cas pour les immobilisation g�rant les plans
        Int_Calculation(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immob
                      , pManagedValueId   --Valeur g�r�e
                      , pPeriodId   --P�riode de calcul
                      , vCurrentFixedAssets.INTEREST_RATE_1   --Taux int�r�t 1
                      , vCurrentFixedAssets.INTEREST_RATE_2   --Taux int�r�t 2
                      , vCurrentFixedAssets.C_ROUND_TYPE_INT   --Type arrondi int�r�t
                      , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT_INT   --Montant arrondi int�r�t
                      , vCurrentFixedAssets.C_INTEREST_CALC_RULES   --Type de calcul int�r�t
                      , vAmortizationDays   --Nombre de jours amortissement
                      , vCoveredDays   --Nombre total de jours couverts
                      , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
                      , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID   --Base amortissement 1
                      , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --Base int�r�t
                      , vCurrentCalcByValueId   --Id du calcul parent (calcul p�riodique, Simulation...)
                      , 0   --Indique si simulation (1) ou non(0)
                      , 0   --Indique si position de budget pris en compte(1) ou non(0)
                       );
      else
        /*M�j de la fiche immob avec le taux appliqu� dans le calcul*/
        update FAM_AMO_APPLICATION
           set APP_DEC_AMORTIZATION = vAmortizationRate
             , A_DATEMOD = sysdate
             , A_IDMOD = UserIni
         where FAM_FIXED_ASSETS_ID = vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
           and FAM_MANAGED_VALUE_ID = pManagedValueId;

        Amo_Int_Calculation(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immob
                          , pManagedValueId   --Valeur g�r�e
                          , pPeriodId   --P�riode de calcul
                          , vAmortizationRate   --Taux amortissement1
                          , vCurrentFixedAssets.Rate2   --Taux amortissement2
                          , vCurrentFixedAssets.INTEREST_RATE_1   --Taux int�r�t 1
                          , vCurrentFixedAssets.INTEREST_RATE_2   --Taux int�r�t 2
                          , vCurrentFixedAssets.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                          , vCurrentFixedAssets.C_ROUND_TYPE   --Type arrondi amortissement
                          , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT   --Montant arrondi amortissement
                          , vCurrentFixedAssets.C_ROUND_TYPE_INT   --Type arrondi int�r�t
                          , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT_INT   --Montant arrondi int�r�t
                          , vCurrentFixedAssets.C_AMORTIZATION_TYP   --Type de calcul amortissement
                          , vCurrentFixedAssets.C_INTEREST_CALC_RULES   --Type de calcul int�r�t
                          , vCurrentFixedAssets.C_OWNERSHIP   --Propri�t�
                          , vAmortizationDays   --Nombre de jours amortissement
                          , vCoveredDays   --Nombre total de jours couverts
                          , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
                          , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID   --Base amortissement 1
                          , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT6_ID   --Base amortissement 2
                          , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
                          , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --Base int�r�t
                          , vCurrentCalcByValueId   --Id du calcul parent (calcul p�riodique, Simulation...)
                          , 0   --Indique si simulation (1) ou non(0)
                          , 0   --Indique si position de budget pris en compte(1) ou non(0)
                           );
      end if;

      fetch FixedAssetsCursor
       into vCurrentFixedAssets;
    end loop;

    close FixedAssetsCursor;

    pIndicator  := FAM_AMORTIZATION_PLAN.ExistSessionError;

    if pIndicator = 0 then
      MoveAmortizationPlan(vCurrentCalcByValueId, pPeriodId, pManagedValueId, pFixCategId, 0);
    end if;
  end CategoryCalculation;

  procedure AmortizationSimulation(
    pStartPeriodId  in     FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type
  , pEndPeriodId    in     FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type
  , pManagedValueId in     FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , pSimulationId   in     FAM_CALC_SIMULATION.FAM_SIMULATION_ID%type
  , pIsBudget       in     number default 0   --Indique si position de budget pris en compte(1) ou non(0)
  , pIndicator      out    number
  )
  is
    /*Curseur globale de recherche selon param�tres g�n�rales de la proc�dure*/
    cursor FixedAssetsCursor(pPeriodId FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type)
    is
      select FIX.FAM_FIXED_ASSETS_ID   -- Amortissement
           , FIX.C_OWNERSHIP
           , AMO.AMO_AMORTIZATION_PLAN   -- Plan d'amortissement
           , AMO.FAM_AMORTIZATION_METHOD_ID   -- M�thode d'amortissement
           , AMO.AMO_ROUNDED_AMOUNT   -- Montant arrondi
           , AMO.AMO_ROUNDED_AMOUNT_INT   -- Montant arrondi int�r�t
           , AMO.C_AMORTIZATION_PERIOD   -- Cadence d'amortissment
             , case   --Taux 1 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('1', '3', '5', '6') then nvl(AAP.APP_LIN_AMORTIZATION
                                                                                      , DEF.DEF_LIN_AMORTIZATION
                                                                                       )
                 when AMO.C_AMORTIZATION_TYP in('2', '4') then nvl(AAP.APP_DEC_AMORTIZATION, DEF.DEF_DEC_AMORTIZATION)
                 else 0
               end Rate1
           , AMO.C_INTEREST_CALC_RULES
             , case   --Taux 2 selon type amortissement
                 when AMO.C_AMORTIZATION_TYP in('5', '6') then nvl(AAP.APP_DEC_AMORTIZATION
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
           , nvl(AAP.APP_INTEREST_RATE, DEF.DEF_INTEREST_RATE) INTEREST_RATE_1 -- Taux d'int�r�t 1
           , nvl(AAP.APP_INTEREST_RATE_2, DEF.DEF_INTEREST_RATE_2) INTEREST_RATE_2 -- Taux d'int�r�t 2
           , AMO.C_AMORTIZATION_TYP   -- Type d'amortissment
           , AMO.C_ROUND_TYPE   -- Type d'arrondi
           , AMO.C_ROUND_TYPE_INT   -- Type d'arrondi int�r�t
           , AAP.APP_AMORTIZATION_BEGIN   -- D�but d'amortissement
           , AAP.APP_AMORTIZATION_END   -- Fin d'amortissement
           , round
               (100 /
                decode
                  (decode
                     (AAP.APP_LIN_AMORTIZATION
                    , 0, null
                    , AAP.APP_LIN_AMORTIZATION
                     )   --La dur�e est syst�matiquement calcul�e (100 / taux1) m�me si elle ext renseign�e
                 , null, decode(DEF.DEF_LIN_AMORTIZATION, 0, null, DEF.DEF_LIN_AMORTIZATION)
                 , AAP.APP_LIN_AMORTIZATION
                  )
              , 2
               ) APP_MONTH_DURATION
           /** Les �l�ments de structures n�cessaires, D'abord ceux des cat�gories / Valeur  Ensuite ceux des valeurs **/
          ,  nvl(DEF.FAM_STRUCTURE_ELEMENT1_ID, VAL.FAM_STRUCTURE_ELEMENT_ID)
                                                                                               FAM_STRUCTURE_ELEMENT_ID   -- Base amortissement 1
           , nvl(DEF.FAM_STRUCTURE_ELEMENT6_ID, VAL.FAM_STRUCTURE_ELEMENT6_ID)
                                                                                              FAM_STRUCTURE_ELEMENT6_ID   -- Base amortissement 2
           , nvl(DEF.FAM_STRUCTURE_ELEMENT3_ID, VAL.FAM_STRUCTURE_ELEMENT3_ID)
                                                                                              FAM_STRUCTURE_ELEMENT3_ID   -- Limite amortissment
           , nvl(DEF.FAM_STRUCTURE_ELEMENT2_ID, VAL.FAM_STRUCTURE_ELEMENT2_ID)
                                                                                              FAM_STRUCTURE_ELEMENT2_ID   -- Base int�r�ts
           , nvl(DEF.FAM_STRUCTURE_ELEMENT4_ID, VAL.FAM_STRUCTURE_ELEMENT4_ID)
                                                                                              FAM_STRUCTURE_ELEMENT4_ID   --Acquisition
           , PER.PER_START_DATE   -- D�but p�riode amortissement
           , PER.PER_END_DATE   -- Fin p�riode amortissement
           , PER2.PER_START_DATE YEAR_START_DATE   -- D�but exercice comptable
           , PER2.PER_END_DATE YEAR_END_DATE   -- Fin exercice comptable
           , DEF.DEF_MIN_RESIDUAL_VALUE   -- Valeur r�siduelle minimum
           , decode(nvl(AAP.APP_NEGATIVE_BASE,0),0, DEF.DEF_NEGATIVE_BASE, AAP.APP_NEGATIVE_BASE) APP_NEGATIVE_BASE
        from (select min(PER_START_DATE) PER_START_DATE
                   , max(PER_END_DATE) PER_END_DATE
                from ACS_PERIOD
               where ACS_FINANCIAL_YEAR_ID = (select ACS_FINANCIAL_YEAR_ID
                                                from ACS_PERIOD
                                               where ACS_PERIOD_ID = pPeriodId) ) PER2
           , ACS_PERIOD PER
           , FAM_MANAGED_VALUE VAL
           , FAM_AMORTIZATION_METHOD AMO
           , FAM_FIXED_ASSETS FIX
           , FAM_DEFAULT DEF
           , FAM_AMO_APPLICATION AAP
       where AAP.FAM_MANAGED_VALUE_ID = pManagedValueId
         and AAP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
         and AMO.FAM_AMORTIZATION_METHOD_ID = AAP.FAM_AMORTIZATION_METHOD_ID
         and VAL.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
         and FIX.C_FIXED_ASSETS_STATUS = '01'
         and DEF.FAM_MANAGED_VALUE_ID = AAP.FAM_MANAGED_VALUE_ID
         and DEF.FAM_FIXED_ASSETS_CATEG_ID = FIX.FAM_FIXED_ASSETS_CATEG_ID
         and DEF.FAM_AMORTIZATION_METHOD_ID = AMO.FAM_AMORTIZATION_METHOD_ID
         and PER.ACS_PERIOD_ID = pPeriodId
         and AAP.APP_AMORTIZATION_BEGIN <= PER.PER_END_DATE
         /**
         * Cadence amortissement � 1(Mensuelle) => En tous les cas �4(Annuelle) => Uniquement si p�riode de calcul = Derni�re p�ridoe exercice
         **/
         and decode(AMO.C_AMORTIZATION_PERIOD   -- Cadence d'amortissement
                  , '1', 1   --     Mensuelle ->    OK
                  , '4', decode(to_char(PER.PER_START_DATE, 'MM')   --     Annuelle  ->  mois d�but amortissment
                              , to_char(PER2.PER_END_DATE, 'MM'), 1   --                 = mois de fin d'exercice => OK
                              , 0
                               )
                  , 0
                   ) = 1
         /**
         * Fin d'amortissement si renseign�  � Est >= � fin p�riode courante pour types <> 6 � Est >= � fin exercice de la p�riode pour types 6
         **/
         and (   AAP.APP_AMORTIZATION_END is null
              or   -- Fin amort . si renseign� >= fin p�riode d'amort
                 (    AMO.C_AMORTIZATION_TYP <> '6'
                  and AAP.APP_AMORTIZATION_END is not null
                  and AAP.APP_AMORTIZATION_END >= PER.PER_START_DATE
                 )
              or (    AMO.C_AMORTIZATION_TYP = '6'
                  and AAP.APP_AMORTIZATION_END is not null
                  and AAP.APP_AMORTIZATION_END >= PER2.PER_START_DATE
                 )
             );

    /*Curseur de recherche des p�riodes de l'intervalle donn�                                                          */
    cursor PeriodCursor
    is
      select   PER.ACS_PERIOD_ID
          from ACS_PERIOD PER
             , ACS_FINANCIAL_YEAR FYE
         where exists(select 1
                        from ACS_PERIOD PER1
                       where PER1.ACS_PERIOD_ID = pStartPeriodId
                         and PER.PER_START_DATE >= PER1.PER_START_DATE)
           and exists(select 1
                        from ACS_PERIOD PER2
                       where PER2.ACS_PERIOD_ID = pEndPeriodId
                         and PER.PER_START_DATE <= PER2.PER_START_DATE)
           and PER.C_TYPE_PERIOD = 2
           and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
      order by FYE.FYE_NO_EXERCICE
             , PER.PER_NO_PERIOD;

    vCurrentSimPeriod     PeriodCursor%rowtype;
    vCurrentFixedAssets   FixedAssetsCursor%rowtype;
    vAmortizationDays     FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --Nombre de jours d'amortissement
    vExistBudget          number(1);
    vFirstPeriod          number(1);
    vCurrentFixedAsset    FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type;
    vAmortizationRate     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --R�ceptionne le taux d'amortissement
    vAmortizationExercise number(3);   --Nombre d'exercice encore � amortir
    vCalculatedEndDate    FAM_AMO_APPLICATION.APP_AMORTIZATION_END%type;   --Date fin d'amortissement caclul�
    vCoveredDays          FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --Nombre de jours couverts dans l'exercice
    vPlanHeaderId         FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type;
    vErrCode              number(1);
    vErrText              varchar2(5000);
    vFixedAssetsFound     boolean;
    vPlanCreated          boolean;
  begin
    /*Suppression des positions d�j� existantes*/
    delete from FAM_CALC_SIMULATION
          where FAM_SIMULATION_ID = pSimulationId
            and FAM_MANAGED_VALUE_ID = pManagedValueId;

    /*Parcours des p�riodes de calcul */
    vFirstPeriod        := 1;
    vCurrentFixedAsset  := 0;
    vPlanCreated        := false;

    open PeriodCursor;

    fetch PeriodCursor
     into vCurrentSimPeriod;

    while PeriodCursor%found loop
      vFixedAssetsFound  := false;

      /*Recherche et parcours des informations des immobilisations                                        */
      open FixedAssetsCursor(vCurrentSimPeriod.ACS_PERIOD_ID);

      fetch FixedAssetsCursor
       into vCurrentFixedAssets;

      while FixedAssetsCursor%found loop
        vFixedAssetsFound  := true;

        if vCurrentFixedAsset <> vCurrentFixedAssets.FAM_FIXED_ASSETS_ID then
          vCurrentFixedAsset  := vCurrentFixedAssets.FAM_FIXED_ASSETS_ID;
          vPlanCreated        := false;
          gNegativeBase       := vCurrentFixedAssets.APP_NEGATIVE_BASE;

          if vFirstPeriod = 1 then
            begin
              select decode(nvl(max(VER.ACB_BUDGET_VERSION_ID), 0), 0, 0, 1)
                into vExistBudget
                from ACB_BUDGET_VERSION VER
                   , ACB_GLOBAL_BUDGET GLO
                   , ACB_PERIOD_AMOUNT PER
                   , ACS_PERIOD PER1
                   , ACS_PERIOD PER2
               where VER.VER_FIX_ASSETS = 1
                 and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
                 and GLO.FAM_FIXED_ASSETS_ID = vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                 and PER.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
                 and PER1.ACS_PERIOD_ID = vCurrentSimPeriod.ACS_PERIOD_ID
                 and trunc(PER1.PER_START_DATE) >= trunc(PER2.PER_START_DATE)
                 and PER2.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                 and exists(
                       select 1
                         from FAM_ELEMENT_DETAIL DET
                        where DET.FAM_STRUCTURE_ELEMENT_ID = vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID
                          and GLO.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP);
            exception
              when others then
                vExistBudget  := 0;
            end;
          else
            begin
              select decode(nvl(max(VER.ACB_BUDGET_VERSION_ID), 0), 0, 0, 1)
                into vExistBudget
                from ACB_BUDGET_VERSION VER
                   , ACB_GLOBAL_BUDGET GLO
                   , ACB_PERIOD_AMOUNT PER
                   , ACS_PERIOD PER1
                   , ACS_PERIOD PER2
               where VER.VER_FIX_ASSETS = 1
                 and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
                 and GLO.FAM_FIXED_ASSETS_ID = vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                 and PER.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
                 and PER1.ACS_PERIOD_ID = vCurrentSimPeriod.ACS_PERIOD_ID
                 and trunc(PER1.PER_START_DATE) > trunc(PER2.PER_START_DATE)
                 and PER2.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                 and exists(
                       select 1
                         from FAM_ELEMENT_DETAIL DET
                        where DET.FAM_STRUCTURE_ELEMENT_ID = vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID
                          and GLO.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP);
            exception
              when others then
                vExistBudget  := 0;
            end;
          end if;
        end if;

        vCoveredDays       := 360;
        vAmortizationRate  := vCurrentFixedAssets.Rate1;

        /*Calcul du nombre de jours a amortir pour types <> 6 avec la date de fin amortissement renseign�e au niveau de la fiche  */
        if vCurrentFixedAssets.C_AMORTIZATION_TYP <> '6' then
          vAmortizationDays  :=
            GetAmortizationDays
              (vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immobilisation
             , pManagedValueId   --Valeur g�r�e
             , vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
             , vCurrentFixedAssets.PER_START_DATE   --D�but p�riode
             , vCurrentFixedAssets.PER_END_DATE   --Fin p�riode
             , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
             , vCurrentFixedAssets.YEAR_END_DATE   --Fin d'exercice
             , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   --D�but d'amortissement
             , vCurrentFixedAssets.APP_AMORTIZATION_END   --Fin d'amortissement
             , 1   --Indique si simulation (1) ou non(0)
             , vFirstPeriod *
               vExistBudget   --Indique une r�partition budget pour la p�riode (avec indication de la permi�re p�riode (+1) ou non (-1))
              );
        /*Calcul du nombre de jours a amortir pour types 6 avec la date de fin amortissement calcul�e   */
        elsif     (vCurrentFixedAssets.C_AMORTIZATION_TYP = '6')
              and (not vCurrentFixedAssets.APP_MONTH_DURATION is null) then
          /**Initialisation de la date caclul�e avec fin d'exercice courant **/
          vCalculatedEndDate     := vCurrentFixedAssets.YEAR_END_DATE;
          /**
          * R�ception du nombre d'ann�es encore � amortir (vAmortizationExercise)
          * calcul de la date de fin d'amortissement calcul�e (vCalculatedEndDate) et du nombre de jours prise en consid�ration (vCoveredDays)
          **/
          vCalculatedEndDate     :=
            GetAmortizationEndDate(vCurrentFixedAssets.APP_MONTH_DURATION   -- Dur�e
                                 , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   -- D�but d'amortissement
                                  );
          vAmortizationExercise  :=
                            AmortizationExercise(vCurrentSimPeriod.ACS_PERIOD_ID,   --P�riode de calcul
                                                 vCalculatedEndDate);
          vCoveredDays           :=
            GetCoveredDays(vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
                         , vCurrentSimPeriod.ACS_PERIOD_ID   --P�riode de calcul
                         , vCalculatedEndDate   -- Fin d'amortissement
                          );
          /**
          * R�ception du nombre de jours � amortir (vAmortizationDays)
          **/
          vAmortizationDays      :=
            GetAmortizationDays
              (vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immobilisation
             , pManagedValueId   --Valeur g�r�e
             , vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
             , vCurrentFixedAssets.PER_START_DATE   --D�but p�riode
             , vCurrentFixedAssets.PER_END_DATE   --Fin p�riode
             , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
             , vCurrentFixedAssets.YEAR_END_DATE   --Fin d'exercice
             , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   --D�but d'amortissement
             , vCalculatedEndDate   --Fin d'amortissement CALCULE
             , 1   --Indique si simulation (1) ou non(0)
             , vFirstPeriod *
               vExistBudget   --Indique une r�partition budget pour la p�riode (avec indication de la permi�re p�riode (+1) ou non (-1))
              );
          vAmortizationRate      := 100 / vAmortizationExercise;

          if (vAmortizationRate < vCurrentFixedAssets.Rate1 * to_number(vCurrentFixedAssets.COEFFICIENT) ) then
            vAmortizationRate  := vCurrentFixedAssets.Rate1 * to_number(vCurrentFixedAssets.COEFFICIENT);
          end if;
        end if;

        --M�thode d'amortissement est coch�e "Plan d'amortissement"
        if (vCurrentFixedAssets.AMO_AMORTIZATION_PLAN = 1) then
          FAM_AMORTIZATION_PLAN.gNegativeBase := FAM_AMORTIZATION.gNegativeBase;

          if (vCurrentFixedAssets.C_OWNERSHIP = '9') then
            if (pIsBudget = 1) then
              if not vPlanCreated then
                FAM_AMORTIZATION_PLAN.CalculateAmortizationPlan
                                               (vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immob
                                              , pManagedValueId   --Valeur g�r�e
                                              , vCurrentFixedAssets.FAM_AMORTIZATION_METHOD_ID   --M�thode amortissement
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID   --Base amortissement 1
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --El�ment "Base int�r�ts"
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT4_ID   --El�ment "Acquisition"
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT6_ID   --Base amortissement 2
                                              , vCurrentFixedAssets.C_AMORTIZATION_TYP   --Type de calcul amortissement
                                              , vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
                                              , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   --D�but amortissement
                                              , vCurrentFixedAssets.APP_MONTH_DURATION   --Dur�e amortissement
                                              , vAmortizationRate   --Taux amortissement1
                                              , vCurrentFixedAssets.Rate2   --Taux amortissement2
                                              , vCurrentFixedAssets.COEFFICIENT
                                              , vCurrentFixedAssets.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                                              , vCurrentFixedAssets.C_ROUND_TYPE   --Type arrondi amortissement
                                              , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT   --Montant arrondi amortissement
                                              , 1
                                              , 1
                                               );
                vPlanCreated  := true;
              end if;
            end if;
          else
            --G�n�rer les plans manquants si certaines fiches n'ont pas de plan avec le statut 0 ou 1
            if     (FAM_AMORTIZATION_PLAN.ExistFamPlanByManagedValue(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                                                                   , pManagedValueId
                                                                   , '0'
                                                                   , '00'
                                                                   , vPlanHeaderId
                                                                    ) = 0
                   )
               and (FAM_AMORTIZATION_PLAN.ExistFamPlanByManagedValue(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                                                                   , pManagedValueId
                                                                   , '1'
                                                                   , '00'
                                                                   , vPlanHeaderId
                                                                    ) = 0
                   ) then
              FAM_AMORTIZATION_PLAN.CalculateAmortizationPlan
                                               (vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immob
                                              , pManagedValueId   --Valeur g�r�e
                                              , vCurrentFixedAssets.FAM_AMORTIZATION_METHOD_ID   --M�thode amortissement
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID   --Base amortissement 1
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --El�ment "Base int�r�ts"
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT4_ID   --El�ment "Acquisition"
                                              , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT6_ID   --Base amortissement 2
                                              , vCurrentFixedAssets.C_AMORTIZATION_TYP   --Type de calcul amortissement
                                              , vCurrentFixedAssets.C_AMORTIZATION_PERIOD   --Cadence d'amortissement
                                              , vCurrentFixedAssets.APP_AMORTIZATION_BEGIN   --D�but amortissement
                                              , vCurrentFixedAssets.APP_MONTH_DURATION   --Dur�e amortissement
                                              , vAmortizationRate   --Taux amortissement1
                                              , vCurrentFixedAssets.Rate2   --Taux amortissement2
                                              , vCurrentFixedAssets.COEFFICIENT
                                              , vCurrentFixedAssets.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                                              , vCurrentFixedAssets.C_ROUND_TYPE   --Type arrondi amortissement
                                              , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT   --Montant arrondi amortissement
                                              , 1
                                              , 0
                                               );
            elsif(FAM_AMORTIZATION_PLAN.ExistFamPlanByManagedValue(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID
                                                                 , pManagedValueId
                                                                 , '0'
                                                                 , '00'
                                                                 , vPlanHeaderId
                                                                  ) = 1
                 ) then
              FAM_AMORTIZATION_PLAN.ValidatePlan(vPlanHeaderId, vErrCode, vErrText, -1);
            end if;
          end if;

          --G�n�ration des �critures d'int�r�ts en tous les cas pour les immobilisation g�rant les plans
          Int_Calculation(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immob
                        , pManagedValueId   --Valeur g�r�e
                        , vCurrentSimPeriod.ACS_PERIOD_ID   --P�riode de calcul
                        , vCurrentFixedAssets.INTEREST_RATE_1   --Taux int�r�t 1
                        , vCurrentFixedAssets.INTEREST_RATE_2   --Taux int�r�t 2
                        , vCurrentFixedAssets.C_ROUND_TYPE_INT   --Type arrondi int�r�t
                        , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT_INT   --Montant arrondi int�r�t
                        , vCurrentFixedAssets.C_INTEREST_CALC_RULES   --Type de calcul int�r�t
                        , vAmortizationDays   --Nombre de jours amortissement
                        , vCoveredDays   --Nombre total de jours couverts
                        , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
                        , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID   --Base amortissement 1
                        , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --Base int�r�t
                        , pSimulationId   --Id du calcul parent (calcul p�riodique, Simulation...)
                        , 1   --Indique si simulation (1) ou non(0)
                        , pIsBudget   --Indique si position de budget pris en compte(1) ou non(0)
                         );
        else
          Amo_Int_Calculation(vCurrentFixedAssets.FAM_FIXED_ASSETS_ID   --Immob
                            , pManagedValueId   --Valeur g�r�e
                            , vCurrentSimPeriod.ACS_PERIOD_ID   --P�riode de calcul
                            , vAmortizationRate   --Taux amortissement1
                            , vCurrentFixedAssets.Rate2   --Taux amortissement2
                            , vCurrentFixedAssets.INTEREST_RATE_1   --Taux int�r�t 1
                            , vCurrentFixedAssets.INTEREST_RATE_2   --Taux int�r�t 2
                            , vCurrentFixedAssets.DEF_MIN_RESIDUAL_VALUE   --Valeur r�siduelle
                            , vCurrentFixedAssets.C_ROUND_TYPE   --Type arrondi amortissement
                            , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT   --Montant arrondi amortissement
                            , vCurrentFixedAssets.C_ROUND_TYPE_INT   --Type arrondi int�r�t
                            , vCurrentFixedAssets.AMO_ROUNDED_AMOUNT_INT   --Montant arrondi int�r�t
                            , vCurrentFixedAssets.C_AMORTIZATION_TYP   --Type de calcul amortissement
                            , vCurrentFixedAssets.C_INTEREST_CALC_RULES   --Type de calcul int�r�t
                            , vCurrentFixedAssets.C_OWNERSHIP   --Propri�t�
                            , vAmortizationDays   --Nombre de jours amortissement
                            , vCoveredDays   --Nombre total de jours couverts
                            , vCurrentFixedAssets.YEAR_START_DATE   --D�but exercice
                            , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT_ID   --Base amortissement 1
                            , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT6_ID   --Base amortissement 2
                            , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT3_ID   --Limite amortissement
                            , vCurrentFixedAssets.FAM_STRUCTURE_ELEMENT2_ID   --Base int�r�t
                            , pSimulationId   --Id du calcul parent (calcul p�riodique, Simulation...)
                            , 1   --Indique si simulation (1) ou non(0)
                            , pIsBudget   --Indique si position de budget pris en compte(1) ou non(0)
                             );
        end if;

        fetch FixedAssetsCursor
         into vCurrentFixedAssets;
      end loop;

      close FixedAssetsCursor;

      if vFixedAssetsFound then
        vFirstPeriod  := -1;
        pIndicator    := FAM_AMORTIZATION_PLAN.ExistSessionError;

        if pIndicator = 0 then
          MoveAmortizationPlan(pSimulationId, vCurrentSimPeriod.ACS_PERIOD_ID, pManagedValueId, 0, 1);
        end if;
      end if;

      fetch PeriodCursor
       into vCurrentSimPeriod;
    end loop;

    close PeriodCursor;
  end AmortizationSimulation;

  /**
  * Description  Procedure centrale de calcul des int�r�ts
  **/
  procedure Int_Calculation(
    pFixedAssetsId       in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immob
  , pManagedValueId      in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type   --Valeur g�r�e
  , pPeriodId            in ACS_PERIOD.ACS_PERIOD_ID%type   --P�riode de calcul
  , pInterestRate1       in FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type   --Taux int�r�t 1
  , pInterestRate2       in FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type   --Taux int�r�t 2
  , pIntRoundType        in FAM_AMORTIZATION_METHOD.C_ROUND_TYPE_INT%type   --Type arrondi int�r�t
  , pIntRoundAmount      in FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT_INT%type   --Montant arrondi int�r�t
  , pInterestTyp         in FAM_AMORTIZATION_METHOD.C_INTEREST_CALC_RULES%type   --Type de calcul int�r�t
  , pAmortizationDays    in FAM_CALC_AMORTIZATION.CAL_DAYS%type   --Nombre de jours amortissement
  , pCoveredDays         in FAM_CALC_AMORTIZATION.CAL_DAYS%type   --Nombre total de jours couverts dans l'exercice
  , pFyeStartDate        in ACS_FINANCIAL_YEAR.FYE_START_DATE%type   --D�but exercice
  , pAmoStructureElemId1 in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 1
  , pIntStructureElemId1 in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base int�r�t
  , pCalculationParentId in FAM_PER_CALC_BY_VALUE.FAM_PER_CALC_BY_VALUE_ID%type   --Id du calcul parent (calcul p�riodique, Simulation...)
  , pIsSimulation        in number default 0   --Indique si simulation (1) ou non(0)
  , pIsBudgetPosition    in number default 0   --Indique si position de budget pris en compte(1) ou non(0)
  )
  is
    /* Montants des imputations immob dont les transactions correspondent � celles des
    * �l�ments de "Base amortissement" jusqu'� la p�riode(Tot1 et Tot2) et en d�but d'exercice
    * (Tot3 et Tot4)
    */
    cursor AmortizationBaseCursor(
      pFixedAssetsId       FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immobilisation
    , pPeriodId            FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type   --P�riode
    , pFyeStartDate        ACS_FINANCIAL_YEAR.FYE_START_DATE%type   --D�but Exercice
    , pManagedValueId      FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type   --Valeur g�r�e
    , pStructureElementId1 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 1
    , pStructureElementId2 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissment 2
    )
    is
      select TOT1.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID1
           , TOT1.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID1
           , TOT1.FTO_DEBIT_LC FTO_DEBIT_LC1
           , TOT1.FTO_DEBIT_FC FTO_DEBIT_FC1
           , TOT2.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID2
           , TOT2.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID2
           , TOT2.FTO_DEBIT_LC FTO_DEBIT_LC2
           , TOT2.FTO_DEBIT_FC FTO_DEBIT_FC2
           , TOT3.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID3
           , TOT3.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID3
           , TOT3.FTO_DEBIT_LC FTO_DEBIT_LC3
           , TOT3.FTO_DEBIT_FC FTO_DEBIT_FC3
           , TOT4.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID4
           , TOT4.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID4
           , TOT4.FTO_DEBIT_LC FTO_DEBIT_LC4
           , TOT4.FTO_DEBIT_FC FTO_DEBIT_FC4
        from (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER2
                     , ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER2.ACS_PERIOD_ID = pPeriodId
                   and PER.PER_END_DATE <= PER2.PER_END_DATE
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId1
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT1
           , (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER2
                     , ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER2.ACS_PERIOD_ID = pPeriodId
                   and PER.PER_END_DATE <= PER2.PER_END_DATE
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId2
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT2
           , (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.PER_END_DATE <= pFyeStartDate
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId1
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT3
           , (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.PER_END_DATE <= pFyeStartDate
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId2
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT4
           , ACS_FINANCIAL_CURRENCY CUR
       where CUR.ACS_FINANCIAL_CURRENCY_ID = TOT1.ACS_FINANCIAL_CURRENCY_ID(+)
         and CUR.ACS_FINANCIAL_CURRENCY_ID = TOT2.ACS_FINANCIAL_CURRENCY_ID(+)
         and CUR.ACS_FINANCIAL_CURRENCY_ID = TOT3.ACS_FINANCIAL_CURRENCY_ID(+)
         and CUR.ACS_FINANCIAL_CURRENCY_ID = TOT4.ACS_FINANCIAL_CURRENCY_ID(+)
         and (    (not TOT1.ACS_FINANCIAL_CURRENCY_ID is null)
              or (not TOT2.ACS_FINANCIAL_CURRENCY_ID is null)
              or (not TOT3.ACS_FINANCIAL_CURRENCY_ID is null)
              or (not TOT4.ACS_FINANCIAL_CURRENCY_ID is null)
             );

    cursor BudgetPositionCursor(
      pFixedAssetsId       FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immobilisation
    , pSimStartPerId       FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type   --P�riode d�but simulation
    , pPeriodId            FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type   --P�riode
    , pAmoStructureElemId1 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 1
    )
    is
      select   GLO.ACS_FINANCIAL_CURRENCY_ID
             , sum(PER.PER_AMOUNT_D - PER.PER_AMOUNT_C) PER_AMOUNT_D
          from ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PER
             , ACS_PERIOD PER1
             , ACS_PERIOD PER2
             , ACS_PERIOD PER3
         where VER.VER_FIX_ASSETS = 1
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and GLO.FAM_FIXED_ASSETS_ID = pFixedAssetsId
           and PER.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
           and PER1.ACS_PERIOD_ID = pPeriodId
           and trunc(PER1.PER_START_DATE) >= trunc(PER2.PER_START_DATE)
           and PER3.ACS_PERIOD_ID = pSimStartPerId
           and trunc(PER2.PER_START_DATE) >= trunc(PER3.PER_START_DATE)
           and PER2.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = pAmoStructureElemId1
                    and GLO.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
      group by GLO.ACS_FINANCIAL_CURRENCY_ID;

    vCurrentBase          AmortizationBaseCursor%rowtype;   --R�ceptionne les infos des montant de base amortissement
    vBudgetPosition       BudgetPositionCursor%rowtype;   --R�ceptionne les infos des positions de budget
    vTransactionDate      FAM_CALC_AMORTIZATION.CAL_TRANSACTION_DATE%type;   --R�ceptionne date de fin p�riode courante = date comptabilisation
    vAmortizationDays     FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --Nombre de jours d'amortissement
    vAmoAmountLC          FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul�
    vAmoAmountFC          FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul�
    vInterestAmountRate1  FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_1%type;   --Montant int�r�t calcul� taux 1
    vInterestAmountRate2  FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_2%type;   --Montant int�r�t calcul� taux 2
    vAmoBaseLC            FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type;   --R�ceptionne le montant base amortissement
    vAmoBaseFC            FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type;   --R�ceptionne le montant base amortissement
    vLocalCurrency        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;   --R�ceptionne la monnaie base
    vForeignCurrency      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;   --R�ceptionne la monnaie �trang�re
    vCalPositionId        FAM_CALC_AMORTIZATION.FAM_CALC_AMORTIZATION_ID%type;   --R�ceptionn id de la position de calcul cr��e
    vInterestRate1        FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type;   --Taux int�r�t 1
    vInterestRate2        FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type;   --Taux int�r�t 2
    vBudgetCurrencyId     ACB_GLOBAL_BUDGET.ACS_FINANCIAL_CURRENCY_ID%type;
    vBudgetPeriodAmount   ACB_PERIOD_AMOUNT.PER_AMOUNT_D%type;
    vBudgetIntAmountRate1 FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_1%type;   --Montant int�r�t calcul� taux 1
    vBudgetIntAmountRate2 FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_2%type;   --Montant int�r�t calcul� taux 2
    vBudAmountStructure1  FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul� budget
    vAmoPositionExist     number(1);
    vSimParentId          FAM_SIMULATION.FAM_SIMULATION_ID%type;
    vSimStartPerId        FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type;   --P�riode d�but simulation
  begin
    /* Initialisation de la date de transaction avec la date de fin de la p�riode courante              */
    begin
      select trunc(PER_END_DATE)
        into vTransactionDate
        from ACS_PERIOD
       where ACS_PERIOD_ID = pPeriodId;
    exception
      when others then
        vTransactionDate  := null;
    end;

    /*R�ception du taux d'amortissement, nbr de jours,taux int�r�ts...dans une variable car susceptibles de changer */
    vAmortizationDays  := pAmortizationDays;
    vInterestRate1     := pInterestRate1;
    vInterestRate2     := pInterestRate2;
    vAmoPositionExist  := 0;
    vSimParentId       := null;

    if pIsSimulation = 1 then
      vSimParentId  := pCalculationParentId;

      select nvl(max(ACS_PERIOD_START_ID), 0)
        into vSimStartPerId
        from FAM_SIMULATION
       where FAM_SIMULATION_ID = vSimParentId;
    end if;

    if (not pInterestTyp is null) then
      /*Recherche et parcours des imputations de l'immob, pour la p�riode , la valeur g�r�e et le type  */
      /*de transaction de l'�l�ment "Base int�r�ts" de la valeur g�r�e                                  */
      open AmortizationBaseCursor(pFixedAssetsId, pPeriodId, pFyeStartDate, pManagedValueId, pIntStructureElemId1
                                , null);

      fetch AmortizationBaseCursor
       into vCurrentBase;

      while AmortizationBaseCursor%found loop
        vInterestAmountRate1  := 0;
        vInterestAmountRate2  := 0;
        vLocalCurrency        := vCurrentBase.ACS_ACS_FINANCIAL_CURRENCY_ID1;
        vForeignCurrency      := vCurrentBase.ACS_FINANCIAL_CURRENCY_ID1;

        if (vCurrentBase.FTO_DEBIT_LC1 > 0) then
          /*Calcul int�r�t selon taux 1 si celui n'est pas nul ,calcul suivant le taux 2 ou les deux
            d�fini dans les m�thodes
          */
          if     (vInterestRate1 <> 0)
             and (pInterestTyp in('1', '3') ) then
            vInterestAmountRate1  :=
              GetInterestAmount(vCurrentBase.FTO_DEBIT_LC1   --Montant base d�but exercice
                              , vLocalCurrency   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate1   --Taux d'int�r�t 1
                               );
          end if;

          /*Calcul int�r�t selon taux 2 si celui n'est pas nul et si calcul suivant le taux 1 ou les deux
            d�fini dans les m�thodes
          */
          if     (vInterestRate2 <> 0)
             and (pInterestTyp in('2', '3') ) then
            vInterestAmountRate2  :=
              GetInterestAmount(vCurrentBase.FTO_DEBIT_LC1   --Montant base d�but exercice
                              , vLocalCurrency   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate2   --Taux d'int�r�t 1
                               );
          end if;

          /*G�n�ration uniquement des int�r�ts avec montant non n�gatif et non nul*/
          if    (vInterestAmountRate1 > 0)
             or (vInterestAmountRate2 > 0) then
            if pIsSimulation = 0 then
              NewCalcAmortization(pCalculationParentId   --Calcul p�riodique par valeur
                                , pFixedAssetsId   --Immobilisation
                                , vTransactionDate   --Date Comptabilisation
                                , null   --Base amortissement MB
                                , null   --Base amortissement ME
                                , null   --Taux amortissement
                                , null   --Amortissement MB
                                , null   --Amortissement ME
                                , vCurrentBase.FTO_DEBIT_LC1   --Base Int�r�t
                                , vInterestRate1   --Taux int�r�t 1
                                , vInterestRate2   --Taux int�r�t 2
                                , vInterestAmountRate1   --Montant Int�r�t 1
                                , vInterestAmountRate2   --Montant Int�r�t 2
                                , vLocalCurrency   --MB
                                , vForeignCurrency   --ME
                                , vAmortizationDays   --Nombre de jours
                                , vCalPositionId
                                 );
            elsif pIsSimulation = 1 then
              NewSimAmortization(pCalculationParentId   --Calcul parent
                               , pManagedValueId   --Valeur g�r�e
                               , pPeriodId   --P�riode de simulation
                               , pFixedAssetsId   --Immobilisation
                               , null   --Base amortissement MB
                               , null   --Base amortissement ME
                               , null   --Taux amortissement
                               , null   --Amortissement MB
                               , null   --Amortissement ME
                               , vCurrentBase.FTO_DEBIT_LC1   --Base Int�r�t
                               , vInterestRate1   --Taux int�r�t 1
                               , vInterestRate2   --Taux int�r�t 2
                               , vInterestAmountRate1   --Montant Int�r�t 1
                               , vInterestAmountRate2   --Montant Int�r�t 2
                               , vForeignCurrency   --ME
                               , vLocalCurrency   --MB
                               , vAmortizationDays   --Nombre de jours
                               , 0
                               , vCalPositionId   --Position nouvellement cr��e
                                );
            end if;
          end if;
        end if;

        /*Calcul int�r�t selon taux 1 si celui n'est pas nul ,calcul suivant le taux 2 ou les deux
          d�fini dans les m�thodes  des montants budgetis� si gestion du budget
        */
        if (pIsBudgetPosition = 1) then
          vBudgetPeriodAmount    := 0.0;
          vBudgetCurrencyId      := 0.0;
          vBudgetIntAmountRate1  := 0.0;
          vBudgetIntAmountRate2  := 0.0;

          open BudgetPositionCursor(pFixedAssetsId, vSimStartPerId, pPeriodId, pAmoStructureElemId1);

          fetch BudgetPositionCursor
           into vBudgetPosition;

          if BudgetPositionCursor%found then
            vBudgetCurrencyId    := vBudgetPosition.ACS_FINANCIAL_CURRENCY_ID;
            vBudgetPeriodAmount  := vBudgetPosition.PER_AMOUNT_D;
          end if;

          close BudgetPositionCursor;

          if vBudgetPeriodAmount > 0.0 then
            if     (vInterestRate1 <> 0.0)
               and (pInterestTyp in('1', '3') ) then
              vBudgetIntAmountRate1  :=
                GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                                , vBudgetCurrencyId   --MB
                                , pIntRoundType   --Type arrondi int�r�t
                                , pIntRoundAmount   --Montant arrondi
                                , pCoveredDays   --Nb de jours couverts
                                , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                                , vInterestRate1   --Taux d'int�r�t 1
                                 );
            end if;

            /*Calcul int�r�t selon taux 2 si celui n'est pas nul et si calcul suivant le taux 1 ou les deux
              d�fini dans les m�thodes
            */
            if     (vInterestRate2 <> 0.0)
               and (pInterestTyp in('2', '3') ) then
              vBudgetIntAmountRate2  :=
                GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                                , vBudgetCurrencyId   --MB
                                , pIntRoundType   --Type arrondi int�r�t
                                , pIntRoundAmount   --Montant arrondi
                                , pCoveredDays   --Nb de jours couverts
                                , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                                , vInterestRate2   --Taux d'int�r�t 1
                                 );
            end if;
          end if;

          /*G�n�ration des positions de budget*/
          if    (vBudgetIntAmountRate1 > 0)
             or (vBudgetIntAmountRate2 > 0) then
            if vBudgetCurrencyId = vLocalCurrency then
              vAmoBaseLC    := vBudgetPeriodAmount;
              vAmoBaseFC    := null;
              vAmoAmountLC  := vBudAmountStructure1;
              vAmoAmountFC  := null;
              NewSimAmortization(pCalculationParentId   --Calcul parent
                               , pManagedValueId   --Valeur g�r�e
                               , pPeriodId   --P�riode de simulation
                               , pFixedAssetsId   --Immobilisation
                               , null   --Base amortissement MB
                               , null   --Base amortissement ME
                               , null   --Taux amortissement
                               , null   --Amortissement MB
                               , null   --Amortissement ME
                               , vAmoBaseLC   --Base Int�r�t
                               , vInterestRate1   --Taux int�r�t 1
                               , vInterestRate2   --Taux int�r�t 2
                               , vBudgetIntAmountRate1   --Montant Int�r�t 1
                               , vBudgetIntAmountRate2   --Montant Int�r�t 2
                               , vForeignCurrency   --ME
                               , vLocalCurrency   --MB
                               , vAmortizationDays   --Nombre de jours
                               , 0
                               , vCalPositionId   --Position nouvellement cr��e
                                );
            end if;
          end if;
        end if;

        fetch AmortizationBaseCursor
         into vCurrentBase;
      end loop;

      close AmortizationBaseCursor;

      /*Cr�ation des positions budget dans le cas ou il n'y a pas eu de positions amortissement*/
      if     (vAmoPositionExist = 0)
         and (pIsBudgetPosition = 1) then
        vBudgetPeriodAmount    := 0.0;
        vBudgetCurrencyId      := 0.0;
        vBudgetIntAmountRate1  := 0.0;
        vBudgetIntAmountRate2  := 0.0;

        open BudgetPositionCursor(pFixedAssetsId, vSimStartPerId, pPeriodId, pAmoStructureElemId1);

        fetch BudgetPositionCursor
         into vBudgetPosition;

        if BudgetPositionCursor%found then
          vBudgetCurrencyId    := vBudgetPosition.ACS_FINANCIAL_CURRENCY_ID;
          vBudgetPeriodAmount  := vBudgetPosition.PER_AMOUNT_D;
        end if;

        close BudgetPositionCursor;

        if vBudgetPeriodAmount > 0 then
          if     (vInterestRate1 <> 0.0)
             and (pInterestTyp in('1', '3') ) then
            vBudgetIntAmountRate1  :=
              GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                              , vBudgetCurrencyId   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate1   --Taux d'int�r�t 1
                               );
          end if;

          /*Calcul int�r�t selon taux 2 si celui n'est pas nul et si calcul suivant le taux 1 ou les deux
            d�fini dans les m�thodes
          */
          if     (vInterestRate2 <> 0.0)
             and (pInterestTyp in('2', '3') ) then
            vBudgetIntAmountRate2  :=
              GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                              , vBudgetCurrencyId   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate2   --Taux d'int�r�t 1
                               );
          end if;
        end if;

        /*G�n�ration des positions de budget*/
        if    (vBudgetIntAmountRate1 > 0)
           or (vBudgetIntAmountRate2 > 0) then
          vAmoBaseLC    := vBudgetPeriodAmount;
          vAmoBaseFC    := null;
          vAmoAmountLC  := vBudAmountStructure1;
          vAmoAmountFC  := null;
          NewSimAmortization(pCalculationParentId   --Calcul parent
                           , pManagedValueId   --Valeur g�r�e
                           , pPeriodId   --P�riode de simulation
                           , pFixedAssetsId   --Immobilisation
                           , null   --Base amortissement MB
                           , null   --Base amortissement ME
                           , null   --Taux amortissement
                           , null   --Amortissement MB
                           , null   --Amortissement ME
                           , vAmoBaseLC   --Base Int�r�t
                           , vInterestRate1   --Taux int�r�t 1
                           , vInterestRate2   --Taux int�r�t 2
                           , vBudgetIntAmountRate1   --Montant Int�r�t 1
                           , vBudgetIntAmountRate2   --Montant Int�r�t 2
                           , vForeignCurrency   --ME
                           , vLocalCurrency   --MB
                           , vAmortizationDays   --Nombre de jours
                           , 0
                           , vCalPositionId   --Position nouvellement cr��e
                            );
        end if;
      end if;
    end if;
  end Int_Calculation;

  /**
  * Description  Procedure centrale de calcul des int�r�ts et amortissements
  **/
  procedure Amo_Int_Calculation(
    pFixedAssetsId       in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immob
  , pManagedValueId      in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type   --Valeur g�r�e
  , pPeriodId            in ACS_PERIOD.ACS_PERIOD_ID%type   --P�riode de calcul
  , pAmortizationRate1   in FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type   --Taux amortissement
  , pAmortizationRate2   in FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type   --Taux amortissement
  , pInterestRate1       in FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type   --Taux int�r�t 1
  , pInterestRate2       in FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type   --Taux int�r�t 2
  , pResidualValue       in FAM_DEFAULT.DEF_MIN_RESIDUAL_VALUE%type   --Valeur r�siduelle
  , pAmoRoundType        in FAM_AMORTIZATION_METHOD.C_ROUND_TYPE%type   --Type arrondi amortissement
  , pAmoRoundAmount      in FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT%type   --Montant arrondi amortissement
  , pIntRoundType        in FAM_AMORTIZATION_METHOD.C_ROUND_TYPE_INT%type   --Type arrondi int�r�t
  , pIntRoundAmount      in FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT_INT%type   --Montant arrondi int�r�t
  , pAmortizationTyp     in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_TYP%type   --Type de calcul amortissement
  , pInterestTyp         in FAM_AMORTIZATION_METHOD.C_INTEREST_CALC_RULES%type   --Type de calcul int�r�t
  , pOwnership           in FAM_FIXED_ASSETS.C_OWNERSHIP%type   --Propri�t�
  , pAmortizationDays    in FAM_CALC_AMORTIZATION.CAL_DAYS%type   --Nombre de jours amortissement
  , pCoveredDays         in FAM_CALC_AMORTIZATION.CAL_DAYS%type   --Nombre de jours couverts dans l'exercice
  , pFyeStartDate        in ACS_FINANCIAL_YEAR.FYE_START_DATE%type   --D�but exercice
  , pAmoStructureElemId1 in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 1
  , pAmoStructureElemId2 in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 2
  , pAmoStructureElemId3 in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Limite amortissement
  , pIntStructureElemId1 in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base int�r�t
  , pCalculationParentId in FAM_PER_CALC_BY_VALUE.FAM_PER_CALC_BY_VALUE_ID%type   --Id du calcul parent (calcul p�riodique, Simulation...)
  , pIsSimulation        in number default 0   --Indique si simulation (1) ou non(0)
  , pIsBudgetPosition    in number default 0   --Indique si position de budget pris en compte(1) ou non(0)
  )
  is
    /*Curseur de recherche des montants des imputations immob de l'immob jusqu'� la p�riode et en d�but d'exercice
      pour les types de transaction de la valeur g�r�e
    */
    cursor AmortizationBaseCursor(
      pFixedAssetsId       FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immobilisation
    , pPeriodId            FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type   --P�riode
    , pFyeStartDate        ACS_FINANCIAL_YEAR.FYE_START_DATE%type   --D�but Exercice
    , pManagedValueId      FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type   --Valeur g�r�e
    , pStructureElementId1 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 1
    , pStructureElementId2 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissment 2
    )
    is
      select TOT1.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID1
           , TOT1.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID1
           , TOT1.FTO_DEBIT_LC FTO_DEBIT_LC1
           , TOT1.FTO_DEBIT_FC FTO_DEBIT_FC1
           , TOT2.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID2
           , TOT2.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID2
           , TOT2.FTO_DEBIT_LC FTO_DEBIT_LC2
           , TOT2.FTO_DEBIT_FC FTO_DEBIT_FC2
           , TOT3.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID3
           , TOT3.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID3
           , TOT3.FTO_DEBIT_LC FTO_DEBIT_LC3
           , TOT3.FTO_DEBIT_FC FTO_DEBIT_FC3
           , TOT4.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID4
           , TOT4.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID4
           , TOT4.FTO_DEBIT_LC FTO_DEBIT_LC4
           , TOT4.FTO_DEBIT_FC FTO_DEBIT_FC4
        from (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER2
                     , ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER2.ACS_PERIOD_ID = pPeriodId
                   and PER.PER_END_DATE <= PER2.PER_END_DATE
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId1
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT1
           , (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER2
                     , ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER2.ACS_PERIOD_ID = pPeriodId
                   and PER.PER_END_DATE <= PER2.PER_END_DATE
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId2
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT2
           , (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.PER_END_DATE <= pFyeStartDate
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId1
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT3
           , (select   TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0) FTO_DEBIT_LC
                     , nvl(sum(nvl(TOT.FTO_DEBIT_FC, 0) - nvl(TOT.FTO_CREDIT_FC, 0) ), 0) FTO_DEBIT_FC
                  from ACS_PERIOD PER
                     , FAM_TOTAL_BY_PERIOD TOT
                 where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.PER_END_DATE <= pFyeStartDate
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId2
                            and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
              group by TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) TOT4
           , ACS_FINANCIAL_CURRENCY CUR
       where CUR.ACS_FINANCIAL_CURRENCY_ID = TOT1.ACS_FINANCIAL_CURRENCY_ID(+)
         and CUR.ACS_FINANCIAL_CURRENCY_ID = TOT2.ACS_FINANCIAL_CURRENCY_ID(+)
         and CUR.ACS_FINANCIAL_CURRENCY_ID = TOT3.ACS_FINANCIAL_CURRENCY_ID(+)
         and CUR.ACS_FINANCIAL_CURRENCY_ID = TOT4.ACS_FINANCIAL_CURRENCY_ID(+)
         and (    (not TOT1.ACS_FINANCIAL_CURRENCY_ID is null)
              or (not TOT2.ACS_FINANCIAL_CURRENCY_ID is null)
              or (not TOT3.ACS_FINANCIAL_CURRENCY_ID is null)
              or (not TOT4.ACS_FINANCIAL_CURRENCY_ID is null)
             );

    cursor BudgetPositionCursor(
      pFixedAssetsId       FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immobilisation
    , pSimStartPerId       FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type   --P�riode d�but simulation
    , pPeriodId            FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type   --P�riode
    , pAmoStructureElemId1 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 1
    )
    is
      select   GLO.ACS_FINANCIAL_CURRENCY_ID
             , sum(PER.PER_AMOUNT_D - PER.PER_AMOUNT_C) PER_AMOUNT_D
          from ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PER
             , ACS_PERIOD PER1
             , ACS_PERIOD PER2
             , ACS_PERIOD PER3
         where VER.VER_FIX_ASSETS = 1
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and GLO.FAM_FIXED_ASSETS_ID = pFixedAssetsId
           and PER.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
           and PER1.ACS_PERIOD_ID = pPeriodId
           and trunc(PER1.PER_START_DATE) >= trunc(PER2.PER_START_DATE)
           and PER3.ACS_PERIOD_ID = pSimStartPerId
           and trunc(PER2.PER_START_DATE) >= trunc(PER3.PER_START_DATE)
           and PER2.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = pAmoStructureElemId1
                    and GLO.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP)
      group by GLO.ACS_FINANCIAL_CURRENCY_ID;

    cursor SimulatedPositionCursor(
      pFixedAssetsId       FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type   --Immobilisation
    , pSimulationId        FAM_CALC_SIMULATION.FAM_SIMULATION_ID%type   --Simulation
    , pFyeStartDate        ACS_FINANCIAL_YEAR.FYE_START_DATE%type   --D�but Exercice
    , pManagedValueId      FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type   --Valeur g�r�e
    , pStructureElementId1 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissement 1
    , pStructureElementId2 FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type   --Base amortissment 2
    )
    is
      select SIM1.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID1
           , SIM1.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID1
           , SIM1.FCS_AMORTIZATION_LC FCS_AMORTIZATION_LC1
           , SIM1.FCS_AMORTIZATION_FC FCS_AMORTIZATION_FC1
           , SIM2.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID2
           , SIM2.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID2
           , SIM2.FCS_AMORTIZATION_LC FCS_AMORTIZATION_LC2
           , SIM2.FCS_AMORTIZATION_FC FCS_AMORTIZATION_FC2
        from (select   FCS.ACS_FINANCIAL_CURRENCY_ID
                     , FCS.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(FCS.FCS_AMORTIZATION_LC, 0) ), 0) FCS_AMORTIZATION_LC
                     , nvl(sum(nvl(FCS.FCS_AMORTIZATION_FC, 0) ), 0) FCS_AMORTIZATION_FC
                  from ACS_PERIOD PER1
                     , FAM_CALC_SIMULATION FCS
                 where FCS.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and FCS.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and FCS.FAM_SIMULATION_ID = pSimulationId
                   and FCS.ACS_PERIOD_ID = PER1.ACS_PERIOD_ID
                   and PER1.PER_END_DATE <= pFyeStartDate
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId1
                            and DET.C_FAM_TRANSACTION_TYP between '600' and '699')
              group by FCS.ACS_FINANCIAL_CURRENCY_ID
                     , FCS.ACS_ACS_FINANCIAL_CURRENCY_ID) SIM1
           , (select   FCS.ACS_FINANCIAL_CURRENCY_ID
                     , FCS.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl(sum(nvl(FCS.FCS_AMORTIZATION_LC, 0) ), 0) FCS_AMORTIZATION_LC
                     , nvl(sum(nvl(FCS.FCS_AMORTIZATION_FC, 0) ), 0) FCS_AMORTIZATION_FC
                  from ACS_PERIOD PER1
                     , FAM_CALC_SIMULATION FCS
                 where FCS.FAM_FIXED_ASSETS_ID = pFixedAssetsId
                   and FCS.FAM_MANAGED_VALUE_ID = pManagedValueId
                   and FCS.FAM_SIMULATION_ID = pSimulationId
                   and FCS.ACS_PERIOD_ID = PER1.ACS_PERIOD_ID
                   and PER1.PER_END_DATE <= pFyeStartDate
                   and exists(
                         select 1
                           from FAM_ELEMENT_DETAIL DET
                          where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElementId2
                            and DET.C_FAM_TRANSACTION_TYP between '600' and '699')
              group by FCS.ACS_FINANCIAL_CURRENCY_ID
                     , FCS.ACS_ACS_FINANCIAL_CURRENCY_ID) SIM2
           , ACS_FINANCIAL_CURRENCY CUR
       where CUR.ACS_FINANCIAL_CURRENCY_ID = SIM1.ACS_FINANCIAL_CURRENCY_ID(+)
         and CUR.ACS_FINANCIAL_CURRENCY_ID = SIM2.ACS_FINANCIAL_CURRENCY_ID(+)
         and (    (not SIM1.ACS_FINANCIAL_CURRENCY_ID is null)
              or (not SIM2.ACS_FINANCIAL_CURRENCY_ID is null) );

    vCurrentBase          AmortizationBaseCursor%rowtype;   --R�ceptionne les infos des montant de base amortissement
    vBudgetPosition       BudgetPositionCursor%rowtype;   --R�ceptionne les infos des positions de budget
    vSimulatedPosition    SimulatedPositionCursor%rowtype;   --R�ceptionne les infos des positions d�j� simul�es
    vTransactionDate      FAM_CALC_AMORTIZATION.CAL_TRANSACTION_DATE%type;   --R�ceptionne date de fin p�riode courante = date comptabilisation
    vAmortizationRate     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --R�ceptionne le taux d'amortissement
    vAmortizationRate1    FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --R�ceptionne le taux d'amortissement
    vAmortizationRate2    FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --R�ceptionne le taux d'amortissement
    vAmortizationDays     FAM_CALC_AMORTIZATION.CAL_DAYS%type;   --Nombre de jours d'amortissement
    vAmoAmountStructure1  FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul� base 1
    vAmoAmountStructure2  FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul� base 2
    vAmoAmountLC          FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul�
    vAmoAmountFC          FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul�
    vInterestAmountRate1  FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_1%type;   --Montant int�r�t calcul� taux 1
    vInterestAmountRate2  FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_2%type;   --Montant int�r�t calcul� taux 2
    vAmoBaseLC            FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type;   --R�ceptionne le montant base amortissement
    vAmoBaseFC            FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type;   --R�ceptionne le montant base amortissement
    vLocalCurrency        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;   --R�ceptionne la monnaie base
    vForeignCurrency      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;   --R�ceptionne la monnaie �trang�re
    vCalPositionId        FAM_CALC_AMORTIZATION.FAM_CALC_AMORTIZATION_ID%type;   --R�ceptionn id de la position de calcul cr��e
    vInterestRate1        FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type;   --Taux int�r�t 1
    vInterestRate2        FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type;   --Taux int�r�t 2
    vBudgetCurrencyId     ACB_GLOBAL_BUDGET.ACS_FINANCIAL_CURRENCY_ID%type;
    vBudgetPeriodAmount   ACB_PERIOD_AMOUNT.PER_AMOUNT_D%type;
    vBudgetIntAmountRate1 FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_1%type;   --Montant int�r�t calcul� taux 1
    vBudgetIntAmountRate2 FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_2%type;   --Montant int�r�t calcul� taux 2
    vBudAmountStructure1  FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type;   --Montant d'amortissement calcul� budget
    vAmoPositionExist     number(1);
    vSimParentId          FAM_SIMULATION.FAM_SIMULATION_ID%type;
    vSimStartPerId        FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type;   --P�riode d�but simulation
  begin
    /* Initialisation de la date de transaction avec la date de fin de la p�riode courante              */
    begin
      select trunc(PER_END_DATE)
        into vTransactionDate
        from ACS_PERIOD
       where ACS_PERIOD_ID = pPeriodId;
    exception
      when others then
        vTransactionDate  := null;
    end;

    /*R�ception du taux d'amortissement, nbr de jours,taux int�r�ts...dans une variable car susceptibles de changer */
    vAmortizationRate   := pAmortizationRate1;
    vAmortizationRate1  := pAmortizationRate1;
    vAmortizationRate2  := pAmortizationRate2;
    vAmortizationDays   := pAmortizationDays;
    vInterestRate1      := pInterestRate1;
    vInterestRate2      := pInterestRate2;
    vAmoPositionExist   := 0;
    vSimParentId        := null;

    if pIsSimulation = 1 then
      vSimParentId  := pCalculationParentId;

      select nvl(max(ACS_PERIOD_START_ID), 0)
        into vSimStartPerId
        from FAM_SIMULATION
       where FAM_SIMULATION_ID = vSimParentId;
    end if;

    /*Recherche et parcours des imputations de l'immob, pour la p�riode , la valeur g�r�e et le type  */
    /*de transaction de l'�l�ment "Base amortissement" de la valeur g�r�e                             */
    open AmortizationBaseCursor(pFixedAssetsId
                              , pPeriodId
                              , pFyeStartDate
                              , pManagedValueId
                              , pAmoStructureElemId1
                              , pAmoStructureElemId2
                               );

    fetch AmortizationBaseCursor
     into vCurrentBase;

    while AmortizationBaseCursor%found loop
      vAmoAmountLC          := 0;
      vAmoAmountFC          := 0;
      vAmoAmountStructure1  := 0;
      vAmoAmountStructure2  := 0;
      vAmoPositionExist     := 1;

      /**
      * Les montants correpondant aux transactions de type "Base Amortissement" n'est pas null
      * => Calcul du montant d'amortissement sur la base du montant en d�but d'exercice
      **/
      if ( (gNegativeBase = 1 ) and (vCurrentBase.FTO_DEBIT_LC1 < 0) ) or
         ( (vCurrentBase.FTO_DEBIT_LC1 > 0) ) then
        vAmoAmountStructure1  :=
          GetAmortizationAmount(pFixedAssetsId   --Immobilisation
                              , pManagedValueId   --Valeur g�r�e
                              , pPeriodId   --P�riode
                              , vCurrentBase.ACS_ACS_FINANCIAL_CURRENCY_ID3   --MB
                              , pAmoStructureElemId3   --El�m. Limite amortissement
                              , pResidualValue   --Valeur r�siduelle
                              , vCurrentBase.FTO_DEBIT_LC3   --Montant base d�but exercice structure 1
                              , pAmoRoundType   --Type arrondi
                              , pAmoRoundAmount   --Montant arrondi
                              , vSimParentId   --Id simulation
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'amortissement
                              , vAmortizationRate1   --Taux d'amortissement
                               );
      end if;

      /**
      *  Montant Base d'amortissement existe pour la p�riode donn�e et la structure 2 et type amortissement = 3,4,5
      *  => Calcul montant amortissement du montant de base 2 de d�but d'exercice
      **/
      if (pAmortizationTyp in('3', '4', '5')) and
         ( ( (gNegativeBase = 1 ) and (vCurrentBase.FTO_DEBIT_LC2 < 0) ) or
           ( (vCurrentBase.FTO_DEBIT_LC2 > 0) )) then
        if pAmortizationTyp = '5' then
          vAmortizationRate2  := pAmortizationRate2;
        else
          vAmortizationRate2  := vAmortizationRate1;
        end if;

        vAmoAmountStructure2  :=
          GetAmortizationAmount(pFixedAssetsId   --Immobilisation
                              , pManagedValueId   --Valeur g�r�e
                              , pPeriodId   --P�riode
                              , vCurrentBase.ACS_ACS_FINANCIAL_CURRENCY_ID4   --MB
                              , pAmoStructureElemId3   --El�m. Limite amortissement
                              , pResidualValue   --Valeur r�siduelle
                              , vCurrentBase.FTO_DEBIT_LC4   --Montant base d�but exercice structure 2
                              , pAmoRoundType   --Type arrondi
                              , pAmoRoundAmount   --Montant arrondi
                              , vSimParentId   --Id simulation
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'amortissement
                              , vAmortizationRate2
                               );   --Taux d'amortissement
      end if;

      /**
      * D�termine la base la + favorable ; celle qui amorti le + sur le montant de d�but d'exercice
      **/
      if (vAmoAmountStructure2 > vAmoAmountStructure1) and (pAmortizationTyp in('3', '4', '5'))then
        vAmoBaseLC         := vCurrentBase.FTO_DEBIT_LC2;
        vAmoBaseFC         := vCurrentBase.FTO_DEBIT_FC2;
        vLocalCurrency     := vCurrentBase.ACS_ACS_FINANCIAL_CURRENCY_ID2;
        vForeignCurrency   := vCurrentBase.ACS_FINANCIAL_CURRENCY_ID2;
        vAmortizationRate  := vAmortizationRate2;

        if (pIsSimulation = 1) then
          open SimulatedPositionCursor(pFixedAssetsId
                                     , pCalculationParentId
                                     , pFyeStartDate
                                     , pManagedValueId
                                     , pAmoStructureElemId1
                                     , pAmoStructureElemId2
                                      );

          fetch SimulatedPositionCursor
           into vSimulatedPosition;

          if SimulatedPositionCursor%found then
            vAmoBaseLC  := vAmoBaseLC - vSimulatedPosition.FCS_AMORTIZATION_LC2;
            vAmoBaseFC  := vAmoBaseFC - vSimulatedPosition.FCS_AMORTIZATION_FC2;
          end if;

          close SimulatedPositionCursor;
        end if;
      else
        vAmoBaseLC         := vCurrentBase.FTO_DEBIT_LC1;
        vAmoBaseFC         := vCurrentBase.FTO_DEBIT_FC1;
        vLocalCurrency     := vCurrentBase.ACS_ACS_FINANCIAL_CURRENCY_ID1;
        vForeignCurrency   := vCurrentBase.ACS_FINANCIAL_CURRENCY_ID1;
        vAmortizationRate  := vAmortizationRate1;

        if (pIsSimulation = 1) then
          open SimulatedPositionCursor(pFixedAssetsId
                                     , pCalculationParentId
                                     , pFyeStartDate
                                     , pManagedValueId
                                     , pAmoStructureElemId1
                                     , pAmoStructureElemId2
                                      );

          fetch SimulatedPositionCursor
           into vSimulatedPosition;

          if SimulatedPositionCursor%found then
            vAmoBaseLC  := vAmoBaseLC - vSimulatedPosition.FCS_AMORTIZATION_LC1;
            vAmoBaseFC  := vAmoBaseFC - vSimulatedPosition.FCS_AMORTIZATION_FC1;
          end if;

          close SimulatedPositionCursor;
        end if;
      end if;

      /**
        Calcul d�finitif selon nouvelles bases d�finies
      **/
      vAmoAmountLC          :=
        GetAmortizationAmount(pFixedAssetsId
                            , pManagedValueId
                            , pPeriodId
                            , vLocalCurrency
                            , pAmoStructureElemId3
                            , pResidualValue
                            , vAmoBaseLC
                            , pAmoRoundType
                            , pAmoRoundAmount
                            , vSimParentId
                            , pCoveredDays
                            , vAmortizationDays
                            , vAmortizationRate
                             );

      if (pIsBudgetPosition = 1) and (pOwnership = '9')then
        vBudgetPeriodAmount  := 0.0;
        vBudgetCurrencyId    := 0.0;

        open BudgetPositionCursor(pFixedAssetsId, vSimStartPerId, pPeriodId, pAmoStructureElemId1);

        fetch BudgetPositionCursor
         into vBudgetPosition;

        if BudgetPositionCursor%found then
          vBudgetCurrencyId    := vBudgetPosition.ACS_FINANCIAL_CURRENCY_ID;
          vBudgetPeriodAmount  := vBudgetPosition.PER_AMOUNT_D;
        end if;

        close BudgetPositionCursor;

        if ( (gNegativeBase = 1 ) and (vBudgetPeriodAmount < 0) ) or
           ( (vBudgetPeriodAmount > 0) ) then
          vBudAmountStructure1  :=
            GetAmortizationAmount(pFixedAssetsId   --Immobilisation
                                , pManagedValueId   --Valeur g�r�e
                                , pPeriodId   --P�riode
                                , vBudgetCurrencyId   --MB
                                , pAmoStructureElemId3   --El�m. Limite amortissement
                                , pResidualValue   --Valeur r�siduelle
                                , vBudgetPeriodAmount   --Montant base d�but exercice structure 1
                                , pAmoRoundType   --Type arrondi
                                , pAmoRoundAmount   --Montant arrondi
                                , vSimParentId   --Id simulation
                                , pCoveredDays   --Nb de jours couverts
                                , vAmortizationDays   --Nb de jours d'amortissement
                                , vAmortizationRate   --Taux d'amortissement
                                 );
        end if;
      end if;

      /*G�n�ration uniquement des amortissments avec montant non n�gatif et non null*/
      --Deuxi�me test sur la validit� du montant dans le cas o� l'�l�ment de base n'inclut pas les amortissments d�j� effectu�s
      if ( (gNegativeBase = 1 ) and (vAmoAmountLC < 0) ) or
         ( (vAmoAmountLC > 0) ) then
        vCalPositionId  := null;

        if pIsSimulation = 0 then
          NewCalcAmortization(pCalculationParentId   --Calcul parent
                            , pFixedAssetsId   --Immobilisation
                            , vTransactionDate   --Date Comptabilisation
                            , vAmoBaseLC   --Base amortissement MB
                            , vAmoBaseFC   --Base amortissement ME
                            , vAmortizationRate   --Taux amortissement
                            , vAmoAmountLC   --Amortissement MB
                            , vAmoAmountFC   --Amortissement ME
                            , null   --Base Int�r�t
                            , null   --Taux int�r�t 1
                            , null   --Taux int�r�t 2
                            , null   --Montant Int�r�t 1
                            , null   --Montant Int�r�t 2
                            , vLocalCurrency   --MB
                            , vForeignCurrency   --ME
                            , vAmortizationDays   --Nombre de jours
                            , vCalPositionId
                             );
        elsif pIsSimulation = 1 then
          NewSimAmortization(pCalculationParentId   --Calcul parent
                           , pManagedValueId   --Valeur g�r�e
                           , pPeriodId   --P�riode de simulation
                           , pFixedAssetsId   --Immobilisation
                           , vAmoBaseLC   --Base amortissement MB
                           , vAmoBaseFC   --Base amortissement ME
                           , vAmortizationRate   --Taux amortissement
                           , vAmoAmountLC   --Amortissement MB
                           , vAmoAmountFC   --Amortissement ME
                           , null   --Base Int�r�t
                           , null   --Taux int�r�t 1
                           , null   --Taux int�r�t 2
                           , null   --Montant Int�r�t 1
                           , null   --Montant Int�r�t 2
                           , vForeignCurrency   --ME
                           , vLocalCurrency   --MB
                           , vAmortizationDays   --Nombre de jours
                           , 0
                           , vCalPositionId   --Position nouvellement cr��e
                            );
        end if;
      end if;

      /*G�n�ration des positions de budget*/
      if (pIsBudgetPosition = 1) and (pOwnership = '9') and
         ( ( (gNegativeBase = 1 ) and (vBudAmountStructure1 < 0) ) or
           ( (vBudAmountStructure1 > 0) )) then
        if vBudgetCurrencyId = vLocalCurrency then
          vAmoBaseLC    := vBudgetPeriodAmount;
          vAmoBaseFC    := null;
          vAmoAmountLC  := vBudAmountStructure1;
          vAmoAmountFC  := null;
        elsif vBudgetCurrencyId = vForeignCurrency then
          vAmoBaseLC    := null;
          vAmoBaseFC    := vBudgetPeriodAmount;
          vAmoAmountLC  := null;
          vAmoAmountFC  := vBudAmountStructure1;
        end if;

        NewSimAmortization(pCalculationParentId   --Calcul parent
                         , pManagedValueId   --Valeur g�r�e
                         , pPeriodId   --P�riode de simulation
                         , pFixedAssetsId   --Immobilisation
                         , vAmoBaseLC   --Base amortissement MB
                         , vAmoBaseFC   --Base amortissement ME
                         , vAmortizationRate   --Taux amortissement
                         , vAmoAmountLC   --Amortissement MB
                         , vAmoAmountFC   --Amortissement ME
                         , null   --Base Int�r�t
                         , null   --Taux int�r�t 1
                         , null   --Taux int�r�t 2
                         , null   --Montant Int�r�t 1
                         , null   --Montant Int�r�t 2
                         , vForeignCurrency   --ME
                         , vLocalCurrency   --MB
                         , vAmortizationDays   --Nombre de jours
                         , pIsBudgetPosition
                         , vCalPositionId   --Position nouvellement cr��e
                          );
      end if;

      fetch AmortizationBaseCursor
       into vCurrentBase;
    end loop;

    /*Cr�ation des positions budget dans le cas ou il n'y a pas eu de positions amortissement*/
    if     (vAmoPositionExist = 0)
       and (pIsBudgetPosition = 1) and (pOwnership = '9')then
      vBudgetPeriodAmount  := 0.0;
      vBudgetCurrencyId    := 0.0;

      open BudgetPositionCursor(pFixedAssetsId, vSimStartPerId, pPeriodId, pAmoStructureElemId1);

      fetch BudgetPositionCursor
       into vBudgetPosition;

      if BudgetPositionCursor%found then
        vBudgetCurrencyId    := vBudgetPosition.ACS_FINANCIAL_CURRENCY_ID;
        vBudgetPeriodAmount  := vBudgetPosition.PER_AMOUNT_D;
      end if;

      close BudgetPositionCursor;

      if ( (gNegativeBase = 1 ) and (vBudgetPeriodAmount < 0) ) or
         ( (vBudgetPeriodAmount > 0) ) then
        vBudAmountStructure1  :=
          GetAmortizationAmount(pFixedAssetsId   --Immobilisation
                              , pManagedValueId   --Valeur g�r�e
                              , pPeriodId   --P�riode
                              , vBudgetCurrencyId   --MB
                              , pAmoStructureElemId3   --El�m. Limite amortissement
                              , pResidualValue   --Valeur r�siduelle
                              , vBudgetPeriodAmount   --Montant base d�but exercice structure 1
                              , pAmoRoundType   --Type arrondi
                              , pAmoRoundAmount   --Montant arrondi
                              , vSimParentId   --Id simulation
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'amortissement
                              , vAmortizationRate   --Taux d'amortissement
                               );
      end if;

      /*G�n�ration des positions de budget*/
      if ( (gNegativeBase = 1 ) and (vBudAmountStructure1 < 0) ) or
         ( (vBudAmountStructure1 > 0) ) then
        vAmoBaseLC    := vBudgetPeriodAmount;
        vAmoBaseFC    := null;
        vAmoAmountLC  := vBudAmountStructure1;
        vAmoAmountFC  := null;
        NewSimAmortization(pCalculationParentId   --Calcul parent
                         , pManagedValueId   --Valeur g�r�e
                         , pPeriodId   --P�riode de simulation
                         , pFixedAssetsId   --Immobilisation
                         , vAmoBaseLC   --Base amortissement MB
                         , vAmoBaseFC   --Base amortissement ME
                         , vAmortizationRate   --Taux amortissement
                         , vAmoAmountLC   --Amortissement MB
                         , vAmoAmountFC   --Amortissement ME
                         , null   --Base Int�r�t
                         , null   --Taux int�r�t 1
                         , null   --Taux int�r�t 2
                         , null   --Montant Int�r�t 1
                         , null   --Montant Int�r�t 2
                         , vBudgetCurrencyId   --ME
                         , vBudgetCurrencyId   --MB
                         , vAmortizationDays   --Nombre de jours
                         , pIsBudgetPosition
                         , vCalPositionId   --Position nouvellement cr��e
                          );
      end if;
    end if;

    close AmortizationBaseCursor;

    vAmoPositionExist   := 0;

    if (not pInterestTyp is null) then
      /*Recherche et parcours des imputations de l'immob, pour la p�riode , la valeur g�r�e et le type  */
      /*de transaction de l'�l�ment "Base int�r�ts" de la valeur g�r�e                                  */
      open AmortizationBaseCursor(pFixedAssetsId, pPeriodId, pFyeStartDate, pManagedValueId, pIntStructureElemId1
                                , null);

      fetch AmortizationBaseCursor
       into vCurrentBase;

      while AmortizationBaseCursor%found loop
        vInterestAmountRate1  := 0;
        vInterestAmountRate2  := 0;
        vLocalCurrency        := vCurrentBase.ACS_ACS_FINANCIAL_CURRENCY_ID1;
        vForeignCurrency      := vCurrentBase.ACS_FINANCIAL_CURRENCY_ID1;

        if (vCurrentBase.FTO_DEBIT_LC1 > 0) then
          /*Calcul int�r�t selon taux 1 si celui n'est pas nul ,calcul suivant le taux 2 ou les deux
            d�fini dans les m�thodes
          */
          if     (vInterestRate1 <> 0)
             and (pInterestTyp in('1', '3') ) then
            vInterestAmountRate1  :=
              GetInterestAmount(vCurrentBase.FTO_DEBIT_LC1   --Montant base d�but exercice
                              , vLocalCurrency   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate1   --Taux d'int�r�t 1
                               );
          end if;

          /*Calcul int�r�t selon taux 2 si celui n'est pas nul et si calcul suivant le taux 1 ou les deux
            d�fini dans les m�thodes
          */
          if     (vInterestRate2 <> 0)
             and (pInterestTyp in('2', '3') ) then
            vInterestAmountRate2  :=
              GetInterestAmount(vCurrentBase.FTO_DEBIT_LC1   --Montant base d�but exercice
                              , vLocalCurrency   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate2   --Taux d'int�r�t 2
                               );
          end if;

          /*G�n�ration uniquement des int�r�ts avec montant non n�gatif et non nul*/
          if    (vInterestAmountRate1 > 0)
             or (vInterestAmountRate2 > 0) then
            if pIsSimulation = 0 then
              NewCalcAmortization(pCalculationParentId   --Calcul p�riodique par valeur
                                , pFixedAssetsId   --Immobilisation
                                , vTransactionDate   --Date Comptabilisation
                                , null   --Base amortissement MB
                                , null   --Base amortissement ME
                                , null   --Taux amortissement
                                , null   --Amortissement MB
                                , null   --Amortissement ME
                                , vCurrentBase.FTO_DEBIT_LC1   --Base Int�r�t
                                , vInterestRate1   --Taux int�r�t 1
                                , vInterestRate2   --Taux int�r�t 2
                                , vInterestAmountRate1   --Montant Int�r�t 1
                                , vInterestAmountRate2   --Montant Int�r�t 2
                                , vLocalCurrency   --MB
                                , vForeignCurrency   --ME
                                , vAmortizationDays   --Nombre de jours
                                , vCalPositionId
                                 );
            elsif pIsSimulation = 1 then
              NewSimAmortization(pCalculationParentId   --Calcul parent
                               , pManagedValueId   --Valeur g�r�e
                               , pPeriodId   --P�riode de simulation
                               , pFixedAssetsId   --Immobilisation
                               , null   --Base amortissement MB
                               , null   --Base amortissement ME
                               , null   --Taux amortissement
                               , null   --Amortissement MB
                               , null   --Amortissement ME
                               , vCurrentBase.FTO_DEBIT_LC1   --Base Int�r�t
                               , vInterestRate1   --Taux int�r�t 1
                               , vInterestRate2   --Taux int�r�t 2
                               , vInterestAmountRate1   --Montant Int�r�t 1
                               , vInterestAmountRate2   --Montant Int�r�t 2
                               , vForeignCurrency   --ME
                               , vLocalCurrency   --MB
                               , vAmortizationDays   --Nombre de jours
                               , 0
                               , vCalPositionId   --Position nouvellement cr��e
                                );
            end if;
          end if;
        end if;

        /*Calcul int�r�t selon taux 1 si celui n'est pas nul ,calcul suivant le taux 2 ou les deux
          d�fini dans les m�thodes  des montants budgetis� si gestion du budget
        */
        if (pIsBudgetPosition = 1) and (pOwnership = '9')then
          vBudgetPeriodAmount    := 0.0;
          vBudgetCurrencyId      := 0.0;
          vBudgetIntAmountRate1  := 0.0;
          vBudgetIntAmountRate2  := 0.0;

          open BudgetPositionCursor(pFixedAssetsId, vSimStartPerId, pPeriodId, pAmoStructureElemId1);

          fetch BudgetPositionCursor
           into vBudgetPosition;

          if BudgetPositionCursor%found then
            vBudgetCurrencyId    := vBudgetPosition.ACS_FINANCIAL_CURRENCY_ID;
            vBudgetPeriodAmount  := vBudgetPosition.PER_AMOUNT_D;
          end if;

          close BudgetPositionCursor;

          if vBudgetPeriodAmount > 0.0 then
            if     (vInterestRate1 <> 0.0)
               and (pInterestTyp in('1', '3') ) then
              vBudgetIntAmountRate1  :=
                GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                                , vBudgetCurrencyId   --MB
                                , pIntRoundType   --Type arrondi int�r�t
                                , pIntRoundAmount   --Montant arrondi
                                , pCoveredDays   --Nb de jours couverts
                                , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                                , vInterestRate1   --Taux d'int�r�t 1
                                 );
            end if;

            /*Calcul int�r�t selon taux 2 si celui n'est pas nul et si calcul suivant le taux 1 ou les deux
              d�fini dans les m�thodes
            */
            if     (vInterestRate2 <> 0.0)
               and (pInterestTyp in('2', '3') ) then
              vBudgetIntAmountRate2  :=
                GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                                , vBudgetCurrencyId   --MB
                                , pIntRoundType   --Type arrondi int�r�t
                                , pIntRoundAmount   --Montant arrondi
                                , pCoveredDays   --Nb de jours couverts
                                , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                                , vInterestRate2   --Taux d'int�r�t 1
                                 );
            end if;
          end if;

          /*G�n�ration des positions de budget*/
          if    (vBudgetIntAmountRate1 > 0)
             or (vBudgetIntAmountRate2 > 0) then
            if vBudgetCurrencyId = vLocalCurrency then
              vAmoBaseLC    := vBudgetPeriodAmount;
              vAmoBaseFC    := null;
              vAmoAmountLC  := vBudAmountStructure1;
              vAmoAmountFC  := null;
              NewSimAmortization(pCalculationParentId   --Calcul parent
                               , pManagedValueId   --Valeur g�r�e
                               , pPeriodId   --P�riode de simulation
                               , pFixedAssetsId   --Immobilisation
                               , null   --Base amortissement MB
                               , null   --Base amortissement ME
                               , null   --Taux amortissement
                               , null   --Amortissement MB
                               , null   --Amortissement ME
                               , vAmoBaseLC   --Base Int�r�t
                               , vInterestRate1   --Taux int�r�t 1
                               , vInterestRate2   --Taux int�r�t 2
                               , vBudgetIntAmountRate1   --Montant Int�r�t 1
                               , vBudgetIntAmountRate2   --Montant Int�r�t 2
                               , vForeignCurrency   --ME
                               , vLocalCurrency   --MB
                               , vAmortizationDays   --Nombre de jours
                               , 0
                               , vCalPositionId   --Position nouvellement cr��e
                                );
            end if;
          end if;
        end if;

        fetch AmortizationBaseCursor
         into vCurrentBase;
      end loop;

      close AmortizationBaseCursor;

      /*Cr�ation des positions budget dans le cas ou il n'y a pas eu de positions amortissement*/
      if     (vAmoPositionExist = 0)
         and (pIsBudgetPosition = 1) and (pOwnership = '9') then
        vBudgetPeriodAmount    := 0.0;
        vBudgetCurrencyId      := 0.0;
        vBudgetIntAmountRate1  := 0.0;
        vBudgetIntAmountRate2  := 0.0;

        open BudgetPositionCursor(pFixedAssetsId, vSimStartPerId, pPeriodId, pAmoStructureElemId1);

        fetch BudgetPositionCursor
         into vBudgetPosition;

        if BudgetPositionCursor%found then
          vBudgetCurrencyId    := vBudgetPosition.ACS_FINANCIAL_CURRENCY_ID;
          vBudgetPeriodAmount  := vBudgetPosition.PER_AMOUNT_D;
        end if;

        close BudgetPositionCursor;

        if vBudgetPeriodAmount > 0 then
          if     (vInterestRate1 <> 0.0)
             and (pInterestTyp in('1', '3') ) then
            vBudgetIntAmountRate1  :=
              GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                              , vBudgetCurrencyId   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate1   --Taux d'int�r�t 1
                               );
          end if;

          /*Calcul int�r�t selon taux 2 si celui n'est pas nul et si calcul suivant le taux 1 ou les deux
            d�fini dans les m�thodes
          */
          if     (vInterestRate2 <> 0.0)
             and (pInterestTyp in('2', '3') ) then
            vBudgetIntAmountRate2  :=
              GetInterestAmount(vBudgetPeriodAmount   --Montant budget de la p�riode courante
                              , vBudgetCurrencyId   --MB
                              , pIntRoundType   --Type arrondi int�r�t
                              , pIntRoundAmount   --Montant arrondi
                              , pCoveredDays   --Nb de jours couverts
                              , vAmortizationDays   --Nb de jours d'int�r�t = amortissement
                              , vInterestRate2   --Taux d'int�r�t 1
                               );
          end if;
        end if;

        /*G�n�ration des positions de budget*/
        if    (vBudgetIntAmountRate1 > 0)
           or (vBudgetIntAmountRate2 > 0) then
          vAmoBaseLC    := vBudgetPeriodAmount;
          vAmoBaseFC    := null;
          vAmoAmountLC  := vBudAmountStructure1;
          vAmoAmountFC  := null;
          NewSimAmortization(pCalculationParentId   --Calcul parent
                           , pManagedValueId   --Valeur g�r�e
                           , pPeriodId   --P�riode de simulation
                           , pFixedAssetsId   --Immobilisation
                           , null   --Base amortissement MB
                           , null   --Base amortissement ME
                           , null   --Taux amortissement
                           , null   --Amortissement MB
                           , null   --Amortissement ME
                           , vAmoBaseLC   --Base Int�r�t
                           , vInterestRate1   --Taux int�r�t 1
                           , vInterestRate2   --Taux int�r�t 2
                           , vBudgetIntAmountRate1   --Montant Int�r�t 1
                           , vBudgetIntAmountRate2   --Montant Int�r�t 2
                           , vForeignCurrency   --ME
                           , vLocalCurrency   --MB
                           , vAmortizationDays   --Nombre de jours
                           , 0
                           , vCalPositionId   --Position nouvellement cr��e
                            );
        end if;
      end if;
    end if;
  end Amo_Int_Calculation;

  /**
  * Description  Cr�e toutes les valeurs g�r�es � amortir, dans le cadre d'une p�riode comptable
  *              pour autant qu'aucune valeur g�r�e pour cette p�riode ne figure d�j� dans la table
  */
  procedure CreateAllManagedValue(aACS_PERIOD_ID in FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type, aOk out boolean)
  is
    id FAM_PER_CALC_BY_VALUE.FAM_PER_CALC_BY_VALUE_ID%type;
  begin
    aOk  := false;

    select min(FAM_PER_CALC_BY_VALUE_ID)
      into id
      from FAM_PER_CALC_BY_VALUE
     where ACS_PERIOD_ID = aACS_PERIOD_ID;

    if id is null then
      insert into FAM_PER_CALC_BY_VALUE
                  (FAM_PER_CALC_BY_VALUE_ID
                 , ACS_PERIOD_ID
                 , FAM_MANAGED_VALUE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , aACS_PERIOD_ID
             , VAL.FAM_MANAGED_VALUE_ID
             , trunc(sysdate)
             , UserIni
          from FAM_MANAGED_VALUE VAL;

      aOk  := true;
    end if;
  end CreateAllManagedValue;

  /**
  * Description  V�rifie si un amortissement (imput�) a d�j� �t� effectu� pour une immobilisation, une p�riode et une valeur g�r�e donn�s
  *              pour une cadence d'amortissement donn�e
  */
  function AmortizationImputations(
    aC_AMORTIZATION_PERIOD in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type
  , aFAM_FIXED_ASSETS_ID   in FAM_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
  , aFAM_MANAGED_VALUE_ID  in FAM_TOTAL_BY_PERIOD.FAM_MANAGED_VALUE_ID%type
  , aACS_PERIOD_ID         in FAM_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  )
    return number
  is
    AmountLC FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;
    blnExist number(1)                               default 0;
  begin
    begin
      -- V�rification existence amortissement ind�pendamment d'une p�riode comptable
      if aACS_PERIOD_ID is null then
        select sum(nvl(FTO_DEBIT_LC, 0) + nvl(FTO_CREDIT_LC, 0) )
          into AmountLC
          from FAM_TOTAL_BY_PERIOD
         where FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
           and FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID
           and C_FAM_TRANSACTION_TYP between '600' and '604';
      else
        -- Cadence p�riodique
        if aC_AMORTIZATION_PERIOD = '1' then
          select sum(nvl(FTO_DEBIT_LC, 0) + nvl(FTO_CREDIT_LC, 0) )
            into AmountLC
            from FAM_TOTAL_BY_PERIOD
           where FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
             and FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID
             and ACS_PERIOD_ID = aACS_PERIOD_ID
             and C_FAM_TRANSACTION_TYP between '600' and '604';
        -- Cadence annuelle
        elsif aC_AMORTIZATION_PERIOD = '4' then
          select sum(nvl(TOT.FTO_DEBIT_LC, 0) + nvl(TOT.FTO_CREDIT_LC, 0) )
            into AmountLC
            from FAM_TOTAL_BY_PERIOD TOT
           where TOT.FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
             and TOT.FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID
             and TOT.ACS_PERIOD_ID in(select PER1.ACS_PERIOD_ID
                                        from ACS_PERIOD PER1
                                       where PER1.ACS_FINANCIAL_YEAR_ID = (select PER2.ACS_FINANCIAL_YEAR_ID
                                                                             from ACS_PERIOD PER2
                                                                            where PER2.ACS_PERIOD_ID = aACS_PERIOD_ID) )
             and TOT.C_FAM_TRANSACTION_TYP between '600' and '604';
        else
          AmountLC  := null;
        end if;
      end if;
    exception
      when others then
        AmountLC  := null;
    end;

    if     AmountLC is not null
       and AmountLC <> 0 then
      blnExist  := 1;
    end if;

    return blnExist;
  end AmortizationImputations;

  /**
  * function InterestImputations
  * Description  V�rifie si une �criture d'int�r�t automatique a d�j� �t� effectu� pour une immobilisation, une p�riode et une valeur g�r�e
  *              et pour une cadence d'amortissement donn�e
  **/
  function InterestImputations(
    pAmortizationPeriod in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type
  , pFixedAssetsId      in FAM_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
  , pManagedValueId     in FAM_TOTAL_BY_PERIOD.FAM_MANAGED_VALUE_ID%type
  , pPeriodId           in FAM_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  )
    return number
  is
    AmountLC FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;
    blnExist number(1)                               default 0;
  begin
    begin
      -- V�rification existence int�r�t ind�pendemment d'une p�riode comptable
      if pPeriodId is null then
        select sum(nvl(FTO_DEBIT_LC, 0) + nvl(FTO_CREDIT_LC, 0) )
          into AmountLC
          from FAM_TOTAL_BY_PERIOD
         where FAM_FIXED_ASSETS_ID = pFixedAssetsId
           and FAM_MANAGED_VALUE_ID = pManagedValueId
           and C_FAM_TRANSACTION_TYP = '700';
      else
        -- Cadence p�riodique
        if pAmortizationPeriod = '1' then
          select sum(nvl(TOT.FTO_DEBIT_LC, 0) + nvl(TOT.FTO_CREDIT_LC, 0) )
            into AmountLC
            from FAM_TOTAL_BY_PERIOD TOT
           where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
             and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
             and TOT.ACS_PERIOD_ID = pPeriodId
             and TOT.C_FAM_TRANSACTION_TYP = '700';
        -- Cadence annuelle
        elsif pAmortizationPeriod = '4' then
          select sum(nvl(TOT.FTO_DEBIT_LC, 0) + nvl(TOT.FTO_CREDIT_LC, 0) )
            into AmountLC
            from FAM_TOTAL_BY_PERIOD TOT
           where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
             and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
             and TOT.ACS_PERIOD_ID in(select PER1.ACS_PERIOD_ID
                                        from ACS_PERIOD PER1
                                       where PER1.ACS_FINANCIAL_YEAR_ID = (select PER2.ACS_FINANCIAL_YEAR_ID
                                                                             from ACS_PERIOD PER2
                                                                            where PER2.ACS_PERIOD_ID = pPeriodId) )
             and TOT.C_FAM_TRANSACTION_TYP = '700';
        else
          AmountLC  := null;
        end if;
      end if;
    exception
      when others then
        AmountLC  := null;
    end;

    if     AmountLC is not null
       and AmountLC <> 0 then
      blnExist  := 1;
    end if;

    return blnExist;
  end InterestImputations;

  function AmortizationExercise(
    pCalcPeriodId in FAM_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , pCalcEndDate  in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  )
    return number
  is
    vResult        number(3) default 1;
    vCalcYear      number(4);
    vEndYear       number(4);
    vFoundExercise boolean;

    function EndDateIsInExercise(pYearToAdd in number, pPeriodId in FAM_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type)
      return boolean
    is
      vExerciseMatch number(1);
    begin
      select nvl(max(1), 0)
        into vExerciseMatch
        from ACS_FINANCIAL_YEAR FYE
           , ACS_PERIOD PER
       where PER.ACS_PERIOD_ID = pPeriodId
         and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
         and pCalcEndDate between to_date(to_char(lpad(to_number(to_char(FYE.FYE_START_DATE, 'MMDD') ), 4, '0') ) ||
                                          to_char(to_number(to_char(FYE.FYE_START_DATE, 'YYYY') ) + pYearToAdd)
                                        , 'MMDDYY'
                                         )
                              and to_date(to_char(lpad(to_number(to_char(FYE.FYE_END_DATE, 'MMDD') ), 4, '0') ) ||
                                          to_char(to_number(to_char(FYE.FYE_END_DATE, 'YYYY') ) + pYearToAdd)
                                        , 'MMDDYY'
                                         );

      return vExerciseMatch = 1;
    end EndDateIsInExercise;
  begin
    begin
      select to_number(to_char(FYE.FYE_START_DATE, 'YYYY') )
           , to_number(to_char(pCalcEndDate, 'YYYY') )
        into vCalcYear
           , vEndYear
        from ACS_FINANCIAL_YEAR FYE
           , ACS_PERIOD PER
       where PER.ACS_PERIOD_ID = pCalcPeriodId
         and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID;

      if vCalcYear = vEndYear then
        vResult  := 1;
      elsif vEndYear > vCalcYear then
        vFoundExercise  := EndDateIsInExercise(0, pCalcPeriodId);

        while not vFoundExercise loop
          vFoundExercise  := EndDateIsInExercise(vResult, pCalcPeriodId);
          vResult         := vResult + 1;
        end loop;
      end if;
    exception
      when others then
        vResult  := 1;
        raise;
    end;

    return vResult;
  end AmortizationExercise;

  /**
  * Description  V�rifie si une simulation amortissement a d�j� �t� effectu� pour une immobilisation, une p�riode et une valeur g�r�e donn�s
  *              pour une cadence d'amortissement donn�e
  */
  function SimulationImputations(
    aC_AMORTIZATION_PERIOD in FAM_AMORTIZATION_METHOD.C_AMORTIZATION_PERIOD%type
  , aFAM_FIXED_ASSETS_ID   in FAM_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
  , aFAM_MANAGED_VALUE_ID  in FAM_TOTAL_BY_PERIOD.FAM_MANAGED_VALUE_ID%type
  , aACS_PERIOD_ID         in FAM_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  )
    return number
  is
    AmountLC FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;
    blnExist number(1)                               default 0;
  begin
    begin
      -- V�rification existence amortissement ind�pendamment d'une p�riode comptable
      if aACS_PERIOD_ID is null then
        select sum(nvl(FCS.FCS_AMORTIZATION_LC, 0) )
          into AmountLC
          from FAM_CALC_SIMULATION FCS
         where FCS.FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
           and FCS.FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID;
      else
        -- Cadence p�riodique
        if aC_AMORTIZATION_PERIOD = '1' then
          select sum(nvl(FCS.FCS_AMORTIZATION_LC, 0) )
            into AmountLC
            from FAM_CALC_SIMULATION FCS
           where FCS.FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
             and FCS.FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID
             and FCS.ACS_PERIOD_ID = aACS_PERIOD_ID;
        -- Cadence annuelle
        elsif aC_AMORTIZATION_PERIOD = '4' then
          select sum(nvl(FCS.FCS_AMORTIZATION_LC, 0) )
            into AmountLC
            from FAM_CALC_SIMULATION FCS
           where FCS.FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
             and FCS.FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID
             and FCS.ACS_PERIOD_ID in(select PER1.ACS_PERIOD_ID
                                        from ACS_PERIOD PER1
                                       where PER1.ACS_FINANCIAL_YEAR_ID = (select PER2.ACS_FINANCIAL_YEAR_ID
                                                                             from ACS_PERIOD PER2
                                                                            where PER2.ACS_PERIOD_ID = aACS_PERIOD_ID) );
        else
          AmountLC  := null;
        end if;
      end if;
    exception
      when others then
        AmountLC  := null;
    end;

    if     AmountLC is not null
       and AmountLC <> 0 then
      blnExist  := 1;
    end if;

    return blnExist;
  end SimulationImputations;

  /**
  * Description  Cr�ation documents d'amortissement automatique
  */
  procedure DocGeneration(
    pPeriodId        in FAM_AMORTIZATION_PERIOD.ACS_PERIOD_ID%type
  , pDocumentDate    in FAM_DOCUMENT.FDO_DOCUMENT_DATE%type
  , pTransactionDate in FAM_IMPUTATION.FIM_TRANSACTION_DATE%type
  , pValueDate       in FAM_IMPUTATION.FIM_VALUE_DATE%type
  , pJouDescription  in FAM_IMPUTATION.FIM_DESCR%type
  , pIntDescription  in FAM_IMPUTATION.FIM_DESCR%type
  , pDescription     in FAM_IMPUTATION.FIM_DESCR%type
  )
  is
    /*Curseur de recherche des champs relatifs aux positions d'amortissement calcul�s*/
    cursor vCalculationPositionCursor
    is
      select CAL.FAM_FIXED_ASSETS_ID
           , VAL.FAM_MANAGED_VALUE_ID
           , CAL.ACS_FINANCIAL_CURRENCY_ID
           , CAL.ACS_ACS_FINANCIAL_CURRENCY_ID
           , CAL.CAL_AMORTIZATION_BASE_LC
           , CAL.CAL_AMORTIZATION_LC
           , CAL.CAL_AMORTIZATION_FC
           , CAL.CAL_INTEREST_BASE
           , CAL.CAL_INTEREST_AMOUNT_1
           , CAL.CAL_INTEREST_AMOUNT_2
           , CAL.CAL_ADJUSTMENT
           , APP.FAM_AMORTIZATION_METHOD_ID
           , AMO.FAM_CATALOGUE_ID
           , AMO.FAM_FAM_CATALOGUE_ID
           , AMO.C_INTEREST_CALC_RULES
           , substr(pDescription || ' (' || FMV.VAL_DESCR, 1, 99) || ')' FIM_DESCR
           , substr(pIntDescription || ' (' || FMV.VAL_DESCR, 1, 99) || ')' FIM_INT_DESCR
           , CAL.FAM_CALC_AMORTIZATION_ID
        from FAM_MANAGED_VALUE FMV
           , FAM_AMORTIZATION_METHOD AMO
           , FAM_AMO_APPLICATION APP
           , FAM_CALC_AMORTIZATION CAL
           , FAM_PER_CALC_BY_VALUE VAL
       where VAL.ACS_PERIOD_ID = pPeriodId
         and VAL.FAM_PER_CALC_BY_VALUE_ID = CAL.FAM_PER_CALC_BY_VALUE_ID
         and CAL.FAM_IMPUTATION_ID is null
         and CAL.FAM_FIXED_ASSETS_ID = APP.FAM_FIXED_ASSETS_ID
         and VAL.FAM_MANAGED_VALUE_ID = FMV.FAM_MANAGED_VALUE_ID
         and VAL.FAM_MANAGED_VALUE_ID = APP.FAM_MANAGED_VALUE_ID
         and APP.FAM_AMORTIZATION_METHOD_ID = AMO.FAM_AMORTIZATION_METHOD_ID;

    /*Curseur de recherche des champs relatifs aux positions d'amortissement calcul�s*/
    cursor crManagedValues
    is
      select VAL.FAM_MANAGED_VALUE_ID
        from FAM_MANAGED_VALUE VAL;

    cursor crAmortizedFixedAssets(
      pCalcPeriodId          FAM_AMORTIZATION_PERIOD.ACS_PERIOD_ID%type
    , pCurrentManagedValueId FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
    )
    is
      select distinct FIX.FIX_NUMBER
                    , FIX.FAM_FIXED_ASSETS_ID
                    , APP.FAM_MANAGED_VALUE_ID
                    , substr(pDescription || ' (' || FMV.VAL_DESCR, 1, 99) || ')' FIM_DESCR
                    , FCA.FAM_CATALOGUE_ID
                    , CAL.ACS_FINANCIAL_CURRENCY_ID
                    , CAL.ACS_ACS_FINANCIAL_CURRENCY_ID
                    , CAL.CAL_ADJUSTMENT
                 from FAM_FIXED_ASSETS FIX
                    , FAM_AMO_APPLICATION APP
                    , FAM_MANAGED_VALUE FMV
                    , FAM_CATALOGUE FCA
                    , FAM_AMORTIZATION_METHOD AMO
                    , FAM_CALC_AMORTIZATION CAL
                where   --valeur g�r�e courante g�r�e par la fiche
                      APP.FAM_MANAGED_VALUE_ID = pCurrentManagedValueId
                  and FIX.FAM_FIXED_ASSETS_ID = APP.FAM_FIXED_ASSETS_ID
                  --lien sur les valeurs g�r�es pour recherche champs
                  and FMV.FAM_MANAGED_VALUE_ID = APP.FAM_MANAGED_VALUE_ID
                  --lien sur catalogues pour recherche champs
                  and AMO.FAM_AMORTIZATION_METHOD_ID = APP.FAM_AMORTIZATION_METHOD_ID
                  and FCA.FAM_CATALOGUE_ID = AMO.FAM_CATALOGUE_ID
                  --fiche n'existe pas dans le calcul de la valeur courante
                  and not exists(
                        select 1
                          from FAM_PER_CALC_BY_VALUE PCV
                             , FAM_CALC_AMORTIZATION CAL
                         where PCV.ACS_PERIOD_ID = pCalcPeriodId
                           and PCV.FAM_MANAGED_VALUE_ID = APP.FAM_MANAGED_VALUE_ID
                           and CAL.FAM_PER_CALC_BY_VALUE_ID = PCV.FAM_PER_CALC_BY_VALUE_ID
                           and FIX.FAM_FIXED_ASSETS_ID = CAL.FAM_FIXED_ASSETS_ID)
                  --fiche existe pour au moins une valeur g�r�e diff�rente de celle en cours
                  -- et pour la valeur g�r�e courante ,la m�thode d'amortissement est rattach�e
                  -- � un catalogue avec formule de pilotage o� intervient la valeur g�r�e diff�rente
                  and exists(
                        select 1
                          from FAM_PER_CALC_BY_VALUE PCV
                         where CAL.FAM_PER_CALC_BY_VALUE_ID = PCV.FAM_PER_CALC_BY_VALUE_ID
                           and FIX.FAM_FIXED_ASSETS_ID = CAL.FAM_FIXED_ASSETS_ID
                           and PCV.ACS_PERIOD_ID = pCalcPeriodId
                           and PCV.FAM_MANAGED_VALUE_ID <> APP.FAM_MANAGED_VALUE_ID
                           and exists(
                                 select 1
                                   from FAM_AMO_APPLICATION FAP
                                      , FAM_PER_CALC_BY_VALUE FPC
                                      , FAM_CAT_MANAGED_VALUE CMV
                                      , FAM_AMORTIZATION_METHOD FAM
                                      , FAM_CATALOGUE CAT
                                      , FAM_MANAGED_VALUE VAL
                                  where CAT.FAM_CATALOGUE_ID = CMV.FAM_CATALOGUE_ID
                                    and instr(CMV.CMV_AMOUNTS_PILOT_FORMULA, FMV.C_VALUE_CATEGORY) > 0
                                    and VAL.FAM_MANAGED_VALUE_ID = PCV.FAM_MANAGED_VALUE_ID
                                    and instr(CMV.CMV_AMOUNTS_PILOT_FORMULA, VAL.C_VALUE_CATEGORY) > 0
                                    and FAM.FAM_CATALOGUE_ID = CAT.FAM_CATALOGUE_ID
                                    and FAM.FAM_AMORTIZATION_METHOD_ID = FAP.FAM_AMORTIZATION_METHOD_ID
                                    and FAP.FAM_FIXED_ASSETS_ID = CAL.FAM_FIXED_ASSETS_ID
                                    and FAP.FAM_MANAGED_VALUE_ID = APP.FAM_MANAGED_VALUE_ID) )
             order by 1;

    tplAmortizedFixedAssets crAmortizedFixedAssets%rowtype;
    tplManagedValues        crManagedValues%rowtype;
    vCalculationPosition    vCalculationPositionCursor%rowtype;   --R�ceptionne les enregistrements du curseur
    vFinancialYearId        ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;   --R�ceptionne l'exercice de la p�riode donn�e
    vJournalId              FAM_JOURNAL.FAM_JOURNAL_ID%type;   --R�ceptionne id Journal  cr��
    vDocumentId             FAM_DOCUMENT.FAM_DOCUMENT_ID%type;   --R�ceptionne id document cr��
    vDocumentAmount         FAM_DOCUMENT.FDO_AMOUNT%type;
    vFamImputationId        FAM_IMPUTATION.FAM_IMPUTATION_ID%type;
    vNumberReadOnly         number(1);

    /* V�rifie l'existence de positions calcul�s non encore imput�s pour la p�riode de calcul donn�e*/
    function ExistNotChargedCalcPosition(pPeriodId in FAM_AMORTIZATION_PERIOD.ACS_PERIOD_ID%type)
      return boolean
    is
      vResult   boolean                                      default false;
      vPeriodId FAM_AMORTIZATION_PERIOD.ACS_PERIOD_ID%type;
    begin
      begin
        select PER.ACS_PERIOD_ID
          into vPeriodId
          from FAM_AMORTIZATION_PERIOD PER
         where ACS_PERIOD_ID = pPeriodId
           and PER.C_FAM_PERIOD_STATUS = '1'
           and exists(
                 select CAL.FAM_CALC_AMORTIZATION_ID
                   from FAM_CALC_AMORTIZATION CAL
                      , FAM_PER_CALC_BY_VALUE VAL
                  where VAL.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                    and VAL.FAM_PER_CALC_BY_VALUE_ID = CAL.FAM_PER_CALC_BY_VALUE_ID
                    and CAL.FAM_IMPUTATION_ID is null);

        vResult  :=(vPeriodId is not null);
      exception
        when others then
          vResult  := false;
      end;

      return vResult;
    end ExistNotChargedCalcPosition;

    function CreateDocument(
      pDocCatalogueId   in FAM_DOCUMENT.FAM_CATALOGUE_ID%type
    , pDocFinCurrencyId in FAM_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
    )
      return FAM_DOCUMENT.FAM_DOCUMENT_ID%type
    is
      vResultDocumentId FAM_DOCUMENT.FAM_DOCUMENT_ID%type;   --R�ceptionne la valeur de retour
      vDocumentNumber   FAM_DOCUMENT.FDO_INT_NUMBER%type;
    begin
      /*R�ception du num�ro document selon catalogue et exercice*/
      FAM_FUNCTIONS.GetFamDocNumber(pDocCatalogueId, vFinancialYearId, vDocumentNumber, vNumberReadOnly);

      /*R�ception nouvel id de document */
      select init_id_seq.nextval
        into vResultDocumentId
        from dual;

      /*Cr�ation du document*/
      begin
        insert into FAM_DOCUMENT
                    (FAM_DOCUMENT_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , FAM_JOURNAL_ID
                   , FAM_CATALOGUE_ID
                   , ACT_DOCUMENT_ID
                   , FDO_INT_NUMBER
                   , FDO_EXT_NUMBER
                   , FDO_AMOUNT
                   , FDO_DOCUMENT_DATE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vResultDocumentId
                   , pDocFinCurrencyId
                   , vJournalId
                   , pDocCatalogueId
                   , null
                   , vDocumentNumber
                   , null
                   , 0
                   , pDocumentDate
                   , sysdate
                   , UserIni
                    );
      exception
        when others then
          vResultDocumentId  := null;
      end;

      return vResultDocumentId;
    end CreateDocument;
  begin
    /*Des positions de calcul non encore imput�s existent pour la p�riode de calcul*/
    if ExistNotChargedCalcPosition(pPeriodId) then
      /*Cr�ation du journal immobilisation */
      vJournalId  := CreateJournal(pPeriodId, pJouDescription, 'PROV');

      /*R�ception de l'exercice financier de la p�riode*/
      select nvl(max(ACS_FINANCIAL_YEAR_ID), 0)
        into vFinancialYearId
        from ACS_PERIOD
       where ACS_PERIOD_ID = pPeriodId;

      if vJournalId is not null then
        open vCalculationPositionCursor;

        fetch vCalculationPositionCursor
         into vCalculationPosition;

        while vCalculationPositionCursor%found loop
          --Catalogue amortissement existe
          if     (vCalculationPosition.FAM_CATALOGUE_ID is not null)
             and (vCalculationPosition.CAL_AMORTIZATION_BASE_LC is not null) then
            -- Cr�ation en-t�te document amortissement
            vDocumentId  :=
                  CreateDocument(vCalculationPosition.FAM_CATALOGUE_ID, vCalculationPosition.ACS_ACS_FINANCIAL_CURRENCY_ID);

            if vDocumentId is not null then
              /*Cr�ation imputation immobilisation selon catalogue amortissement*/
              vFamImputationId  :=
                CreateFamImputation(vJournalId
                                  , vDocumentId
                                  , pPeriodId
                                  , pTransactionDate
                                  , pValueDate
                                  , vCalculationPosition.FIM_DESCR
                                  , vCalculationPosition.FAM_FIXED_ASSETS_ID
                                  , vCalculationPosition.FAM_CATALOGUE_ID
                                  , vCalculationPosition.ACS_FINANCIAL_CURRENCY_ID
                                  , vCalculationPosition.ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , vCalculationPosition.CAL_AMORTIZATION_LC
                                  , vCalculationPosition.CAL_AMORTIZATION_FC
                                  , false
                                  , false
                                  , vCalculationPosition.CAL_ADJUSTMENT
                                  , vDocumentAmount
                                   );

              if vFamImputationId is not null then
                FAM_TRANSACTIONS.Create_VAL_ACT_Imputations(vFamImputationId
                                                          , 1
                                                          , false
                                                          , false
                                                          , null
                                                          , vCalculationPosition.FAM_MANAGED_VALUE_ID
                                                           );

                -- Mise � jour total nouveau document immobilisation
                update FAM_DOCUMENT
                   set FDO_AMOUNT = abs(vDocumentAmount)
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_DOCUMENT_ID = vDocumentId;

                -- Mise � jour table amortissements calcul�s
                update FAM_CALC_AMORTIZATION
                   set FAM_IMPUTATION_ID = vFamImputationId
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_CALC_AMORTIZATION_ID = vCalculationPosition.FAM_CALC_AMORTIZATION_ID;

                -- Mise � jour Plan d'amortissement concern�s
                update FAM_PLAN_HEADER
                   set C_FPH_BLOCKING_REASON = '00'
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_FIXED_ASSETS_ID = vCalculationPosition.FAM_FIXED_ASSETS_ID
                   and FAM_MANAGED_VALUE_ID = vCalculationPosition.FAM_MANAGED_VALUE_ID
                   and C_AMO_PLAN_STATUS = '1';
              end if;
            end if;
          end if;

          --Catalogue int�r�t  existe
          if     (vCalculationPosition.FAM_FAM_CATALOGUE_ID is not null)
             and (vCalculationPosition.CAL_INTEREST_BASE is not null) then
            -- Cr�ation en-t�te document int�r�t
            vDocumentId  :=
              CreateDocument(vCalculationPosition.FAM_FAM_CATALOGUE_ID, vCalculationPosition.ACS_ACS_FINANCIAL_CURRENCY_ID);

            if vCalculationPosition.C_INTEREST_CALC_RULES in('1', '3') then
              /*Cr�ation imputation immobilisation int�r�t selon catalogue int�r�ts */
              vFamImputationId  :=
                CreateFamImputation(vJournalId
                                  , vDocumentId
                                  , pPeriodId
                                  , pTransactionDate
                                  , pValueDate
                                  , vCalculationPosition.FIM_INT_DESCR
                                  , vCalculationPosition.FAM_FIXED_ASSETS_ID
                                  , vCalculationPosition.FAM_FAM_CATALOGUE_ID
                                  , vCalculationPosition.ACS_FINANCIAL_CURRENCY_ID
                                  , vCalculationPosition.ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , vCalculationPosition.CAL_INTEREST_AMOUNT_1
                                  , 0
                                  , true
                                  , false
                                  , vCalculationPosition.CAL_ADJUSTMENT
                                  , vDocumentAmount
                                   );

              if vFamImputationId is not null then
                FAM_TRANSACTIONS.Create_VAL_ACT_Imputations(vFamImputationId
                                                          , 1
                                                          , true
                                                          , true
                                                          , null
                                                          , vCalculationPosition.FAM_MANAGED_VALUE_ID
                                                           );

                -- Mise � jour total nouveau document immobilisation
                update FAM_DOCUMENT
                   set FDO_AMOUNT = abs(vDocumentAmount)
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_DOCUMENT_ID = vDocumentId;

                -- Mise � jour table amortissements calcul�s
                update FAM_CALC_AMORTIZATION
                   set FAM_FAM_IMPUTATION_ID = vFamImputationId
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_CALC_AMORTIZATION_ID = vCalculationPosition.FAM_CALC_AMORTIZATION_ID;
              end if;
            end if;

            /*Cr�ation imputation immob int�r�ts 2 si r�gles de calcul sur les 2 */
            if vCalculationPosition.C_INTEREST_CALC_RULES in('2', '3') then
              -- Cr�ation imputation immobilisation int�r�t
              vFamImputationId  :=
                CreateFamImputation(vJournalId
                                  , vDocumentId
                                  , pPeriodId
                                  , pTransactionDate
                                  , pValueDate
                                  , vCalculationPosition.FIM_INT_DESCR
                                  , vCalculationPosition.FAM_FIXED_ASSETS_ID
                                  , vCalculationPosition.FAM_FAM_CATALOGUE_ID
                                  , vCalculationPosition.ACS_FINANCIAL_CURRENCY_ID
                                  , vCalculationPosition.ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , vCalculationPosition.CAL_INTEREST_AMOUNT_2
                                  , 0
                                  , true
                                  , false
                                  , vCalculationPosition.CAL_ADJUSTMENT
                                  , vDocumentAmount
                                   );

              if vFamImputationId is not null then
                FAM_TRANSACTIONS.Create_VAL_ACT_Imputations(vFamImputationId
                                                          , 1
                                                          , false
                                                          , true
                                                          , null
                                                          , vCalculationPosition.FAM_MANAGED_VALUE_ID
                                                           );

                -- Mise � jour total nouveau document immobilisation
                update FAM_DOCUMENT
                   set FDO_AMOUNT = abs(vDocumentAmount)
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_DOCUMENT_ID = vDocumentId;

                -- Mise � jour table amortissements calcul�s
                update FAM_CALC_AMORTIZATION
                   set FAM2_FAM_IMPUTATION_ID = vFamImputationId
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_CALC_AMORTIZATION_ID = vCalculationPosition.FAM_CALC_AMORTIZATION_ID;
              end if;
            end if;
          end if;

          fetch vCalculationPositionCursor
           into vCalculationPosition;
        end loop;

        close vCalculationPositionCursor;
      end if;

      open crManagedValues;

      fetch crManagedValues
       into tplManagedValues;

      while crManagedValues%found loop
        open crAmortizedFixedAssets(pPeriodId, tplManagedValues.FAM_MANAGED_VALUE_ID);

        fetch crAmortizedFixedAssets
         into tplAmortizedFixedAssets;

        while crAmortizedFixedAssets%found loop
          vDocumentId       :=
            CreateDocument(tplAmortizedFixedAssets.FAM_CATALOGUE_ID, tplAmortizedFixedAssets.ACS_ACS_FINANCIAL_CURRENCY_ID);
          --
          vFamImputationId  :=
            CreateFamImputation(vJournalId
                              , vDocumentId
                              , pPeriodId
                              , pTransactionDate
                              , pValueDate
                              , tplAmortizedFixedAssets.FIM_DESCR
                              , tplAmortizedFixedAssets.FAM_FIXED_ASSETS_ID
                              , tplAmortizedFixedAssets.FAM_CATALOGUE_ID
                              , tplAmortizedFixedAssets.ACS_FINANCIAL_CURRENCY_ID
                              , tplAmortizedFixedAssets.ACS_ACS_FINANCIAL_CURRENCY_ID
                              , 0
                              , 0
                              , false
                              , false
                              , tplAmortizedFixedAssets.CAL_ADJUSTMENT
                              , vDocumentAmount
                               );

          if vFamImputationId is not null then
            FAM_TRANSACTIONS.Create_VAL_ACT_Imputations(vFamImputationId
                                                      , 1
                                                      , false
                                                      , false
                                                      , null
                                                      , tplManagedValues.FAM_MANAGED_VALUE_ID
                                                       );
          end if;

          fetch crAmortizedFixedAssets
           into tplAmortizedFixedAssets;
        end loop;

        close crAmortizedFixedAssets;

        fetch crManagedValues
         into tplManagedValues;
      end loop;

      close crManagedValues;
    end if;
  end DocGeneration;

  /**
  * Description  Cr�ation d'une position d'amortissement calcul� selon param�tres donn�s
  */
  procedure NewCalcAmortization(
    pPeriodCalcValueId  in     FAM_CALC_AMORTIZATION.FAM_PER_CALC_BY_VALUE_ID%type   --Calcul p�riodique par valeur
  , pFixedAssetsId      in     FAM_CALC_AMORTIZATION.FAM_FIXED_ASSETS_ID%type   --Immobilisation
  , pTransactionDate    in     FAM_CALC_AMORTIZATION.CAL_TRANSACTION_DATE%type   --Comptabilisation
  , pAmortizationBaseLC in     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type   --Base amortissement MB
  , pAmortizationBaseFC in     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_FC%type   --Base amortissement ME
  , pAmortizationRate   in     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type   --Taux amortissement
  , pAmortizationLC     in     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_LC%type   --Amortissement MB
  , pAmortizationFC     in     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_FC%type   --Amortissement ME
  , pInterestBase       in     FAM_CALC_AMORTIZATION.CAL_INTEREST_BASE%type   --Base Int�r�t
  , pInterestRate1      in     FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type   --Taux amortissement 1
  , pInterestRate2      in     FAM_CALC_AMORTIZATION.CAL_INTEREST_RATE_1%type   --Taux amortissement 2
  , pInterestAmount1    in     FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_1%type   --Int�r�t 1
  , pInterestAmount2    in     FAM_CALC_AMORTIZATION.CAL_INTEREST_AMOUNT_1%type   --Int�r�t 2
  , pLocalCurrencyId    in     FAM_CALC_AMORTIZATION.ACS_FINANCIAL_CURRENCY_ID%type   --ME
  , pForeignCurrencyId  in     FAM_CALC_AMORTIZATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type   --MB
  , pAmortizationDays   in     FAM_CALC_AMORTIZATION.CAL_DAYS%type   --Nombre de jours
  , pCalcPositionId     in out FAM_CALC_AMORTIZATION.FAM_CALC_AMORTIZATION_ID%type   --Position nouvellement cr��e
  )
  is
  begin
    /* Une seule position calcul�e par immob, valeur g�r�e, p�riode....pour les calcul int�r�ts et amortissements*/
    if pCalcPositionId is null then
      select init_id_seq.nextval
        into pCalcPositionId
        from dual;

      insert into FAM_CALC_AMORTIZATION
                  (FAM_CALC_AMORTIZATION_ID   --Amortissement calcul�
                 , FAM_PER_CALC_BY_VALUE_ID   --Calcul p�riodique par valeur
                 , FAM_FIXED_ASSETS_ID   --Immobilisation
                 , CAL_TRANSACTION_DATE   --Comptabilisation
                 , CAL_VALUE_DATE   --Valeur
                 , CAL_AMORTIZATION_BASE_LC   --Base amortissement MB
                 , CAL_AMORTIZATION_BASE_FC   --Base amortissement ME
                 , CAL_AMORTIZATION_RATE   --Taux amortissement
                 , CAL_AMORTIZATION_LC   --Amortissement MB
                 , CAL_AMORTIZATION_FC   --Amortissement ME
                 , CAL_INTEREST_BASE   --Base int�r�t
                 , CAL_INTEREST_RATE_1   --Taux int�r�t 1
                 , CAL_INTEREST_RATE_2   --Taux int�r�t 1
                 , CAL_INTEREST_AMOUNT_1   --Int�r�t 1
                 , CAL_INTEREST_AMOUNT_2   --Int�r�t 2
                 , ACS_FINANCIAL_CURRENCY_ID   --ME
                 , ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                 , CAL_DAYS   --Nombre de jours
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (pCalcPositionId   --Amortissement calcul�
                 , pPeriodCalcValueId   --Calcul p�riodique par valeur
                 , pFixedAssetsId   --Immobilisation
                 , pTransactionDate   --Comptabilisation
                 , pTransactionDate   --Valeur
                 , pAmortizationBaseLC   --Base amortissement MB
                 , pAmortizationBaseFC   --Base amortissement ME
                 , pAmortizationRate   --Taux amortissement
                 , pAmortizationLC   --Amortissement MB
                 , pAmortizationFC   --Amortissement ME
                 , pInterestBase   --Base int�r�t
                 , pInterestRate1   --Taux int�r�t 1
                 , pInterestRate2   --Taux int�r�t 1
                 , pInterestAmount1   --Int�r�t 1
                 , pInterestAmount2   --Int�r�t 2
                 , pForeignCurrencyId   --ME
                 , pLocalCurrencyId   --MB
                 , pAmortizationDays   --Nombre de jours
                 , trunc(sysdate)
                 , UserIni
                  );
    else
      update FAM_CALC_AMORTIZATION
         set CAL_INTEREST_RATE_1 = pInterestRate1
           , CAL_INTEREST_AMOUNT_1 = pInterestAmount1
           , CAL_INTEREST_RATE_2 = pInterestRate2
           , CAL_INTEREST_AMOUNT_2 = pInterestAmount2
           , CAL_INTEREST_BASE = pInterestBase
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAM_CALC_AMORTIZATION_ID = pCalcPositionId;
    end if;
  end NewCalcAmortization;

  /**
  * Description  Cr�ation d'une position de simulation d'amortissement selon param�tres donn�s
  */
  procedure NewSimAmortization(
    pSimulationId       in     FAM_CALC_SIMULATION.FAM_SIMULATION_ID%type   --Simulation
  , pManagedValueId     in     FAM_CALC_SIMULATION.FAM_MANAGED_VALUE_ID%type   --Valeur g�r�e
  , pPeriodId           in     FAM_CALC_SIMULATION.ACS_PERIOD_ID%type   --P�riode de simulation
  , pFixedAssetsId      in     FAM_CALC_SIMULATION.FAM_FIXED_ASSETS_ID%type   --Immobilisation
  , pAmortizationBaseLC in     FAM_CALC_SIMULATION.FCS_AMORTIZATION_BASE_LC%type   --Base amortissement MB
  , pAmortizationBaseFC in     FAM_CALC_SIMULATION.FCS_AMORTIZATION_BASE_FC%type   --Base amortissement ME
  , pAmortizationRate   in     FAM_CALC_SIMULATION.FCS_AMORTIZATION_RATE%type   --Taux amortissement
  , pAmortizationLC     in     FAM_CALC_SIMULATION.FCS_AMORTIZATION_LC%type   --Amortissement MB
  , pAmortizationFC     in     FAM_CALC_SIMULATION.FCS_AMORTIZATION_FC%type   --Amortissement ME
  , pInterestBase       in     FAM_CALC_SIMULATION.FCS_INTEREST_BASE%type   --Base Int�r�t
  , pInterestRate1      in     FAM_CALC_SIMULATION.FCS_INTEREST_RATE_1%type   --Taux int�r�t 1
  , pInterestRate2      in     FAM_CALC_SIMULATION.FCS_INTEREST_RATE_1%type   --Taux int�r�t 2
  , pInterestAmount1    in     FAM_CALC_SIMULATION.FCS_INTEREST_AMOUNT_1%type   --Montant Int�r�t 1
  , pInterestAmount2    in     FAM_CALC_SIMULATION.FCS_INTEREST_AMOUNT_1%type   --Montant Int�r�t 2
  , pForeignCurrencyId  in     FAM_CALC_SIMULATION.ACS_FINANCIAL_CURRENCY_ID%type   --ME
  , pLocalCurrencyId    in     FAM_CALC_SIMULATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type   --MB
  , pAmortizationDays   in     FAM_CALC_SIMULATION.FCS_DAYS%type   --Nombre de jours
  , pIsBudgetPosition   in     number default 0
  , pCalcPositionId     in out FAM_CALC_SIMULATION.FAM_CALC_SIMULATION_ID%type   --Position nouvellement cr��e
  )
  is
    vFixCategId FAM_FIXED_ASSETS_CATEG.FAM_FIXED_ASSETS_CATEG_ID%type;
  begin
    /* Une seule position calcul�e par immob, valeur g�r�e, p�riode....pour les calcul int�r�ts et amortissements*/
    if pCalcPositionId is null then
      select init_id_seq.nextval
        into pCalcPositionId
        from dual;

      select FAM_FIXED_ASSETS_CATEG_ID
        into vFixCategId
        from FAM_FIXED_ASSETS
       where FAM_FIXED_ASSETS_ID = pFixedAssetsId;

      insert into FAM_CALC_SIMULATION
                  (FAM_CALC_SIMULATION_ID   --Simulation calcul�e
                 , FAM_SIMULATION_ID   --Simulation li�e
                 , FAM_FIXED_ASSETS_ID   --Immob
                 , FAM_FIXED_ASSETS_CATEG_ID   --Cat�gorie de l'immob
                 , FAM_MANAGED_VALUE_ID   --Valeur g�r�e
                 , ACS_PERIOD_ID   --P�riode de simulation
                 , ACS_FINANCIAL_CURRENCY_ID   --ME
                 , ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                 , FCS_AMORTIZATION_BASE_LC   --Base amortissement LC
                 , FCS_AMORTIZATION_BASE_FC   --Base amortissement FC
                 , FCS_DAYS   --Nombre de jours
                 , FCS_AMORTIZATION_RATE   --Taux amortissement
                 , FCS_AMORTIZATION_LC   --Montant amortissement LC
                 , FCS_AMORTIZATION_FC   --Montant amortissement FC
                 , FCS_AMORTIZATION_BEGIN   --D�but p�riode amortissement
                 , FCS_AMORTIZATION_END   --Fin p�riode amortissement
                 , FCS_INTEREST_BASE   --Base int�r�t
                 , FCS_INTEREST_RATE_1   --Taux int�r�t 1
                 , FCS_INTEREST_RATE_2   --Taux int�r�t 2
                 , FCS_INTEREST_AMOUNT_1   --Montant int�r�t 1
                 , FCS_INTEREST_AMOUNT_2   --Montant int�r�t 2
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (pCalcPositionId   --Simulation calcul�e
                 , pSimulationId   --Simulation li�e
                 , pFixedAssetsId   --Immob
                 , vFixCategId   --Cat�gorie de l'immob
                 , pManagedValueId   --Valeur g�r�e
                 , pPeriodId   --P�riode de simulation
                 , pForeignCurrencyId   --ME
                 , pLocalCurrencyId   --MB
                 , pAmortizationBaseLC   --Base amortissement LC
                 , pAmortizationBaseFC   --Base amortissement FC
                 , pAmortizationDays   --Nombre de jours
                 , pAmortizationRate   --Taux amortissement
                 , pAmortizationLC   --Montant amortissement LC
                 , pAmortizationFC   --Montant amortissement FC
                 , null   --D�but p�riode amortissement
                 , null   --Fin p�riode amortissement
                 , pInterestBase   --Base int�r�t
                 , pInterestRate1   --Taux int�r�t 1
                 , pInterestRate2   --Taux int�r�t 2
                 , pInterestAmount1   --Montant int�r�t 1
                 , pInterestAmount2   --Montant int�r�t 2
                 , trunc(sysdate)
                 , UserIni
                  );
    elsif pIsBudgetPosition = 0 then
      update FAM_CALC_SIMULATION
         set FCS_INTEREST_RATE_1 = pInterestRate1
           , FCS_INTEREST_AMOUNT_1 = pInterestAmount1
           , FCS_INTEREST_RATE_2 = pInterestRate2
           , FCS_INTEREST_AMOUNT_2 = pInterestAmount2
           , FCS_INTEREST_BASE = pInterestBase
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAM_CALC_SIMULATION_ID = pCalcPositionId;
    elsif pIsBudgetPosition = 1 then
      update FAM_CALC_SIMULATION
         set FCS_AMORTIZATION_BASE_LC = FCS_AMORTIZATION_BASE_LC + pAmortizationBaseLC
           , FCS_AMORTIZATION_BASE_FC = FCS_AMORTIZATION_BASE_FC + pAmortizationBaseFC
           , FCS_AMORTIZATION_LC = FCS_AMORTIZATION_LC + pAmortizationLC
           , FCS_AMORTIZATION_FC = FCS_AMORTIZATION_FC + pAmortizationFC
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAM_CALC_SIMULATION_ID = pCalcPositionId;
    end if;
  end NewSimAmortization;

  /**
  * Description  Retour du montant d'amortissement selon param�tres
  */
  function GetAmortizationAmount(
    pFixedAssetsId    in     FAM_CALC_AMORTIZATION.FAM_FIXED_ASSETS_ID%type
  , pManagedValueId   in     FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , pPeriodId         in     FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type
  , pLocalCurrencyId  in     FAM_CALC_AMORTIZATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , pStructureElemId  in     FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
  , pResidualValue    in     FAM_DEFAULT.DEF_MIN_RESIDUAL_VALUE%type
  , pAmortizationBase in     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type
  , pRoundType        in     FAM_AMORTIZATION_METHOD.C_ROUND_TYPE%type
  , pRoundAmount      in     FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT%type
  , pSimulationId     in     FAM_CALC_SIMULATION.FAM_SIMULATION_ID%type
  , pCoveredDays      in     FAM_CALC_AMORTIZATION.CAL_DAYS%type
  , pAmortizationDays in out FAM_CALC_AMORTIZATION.CAL_DAYS%type
  , pAmortizationRate in out FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type
  )
    return FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type
  is
    vAmortizationLimit  FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;   --R�ceptionne le montant limite d'amortissement LC
    vAmortizationAmount FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --R�ceptionne le montant d'amortissement de retour LC
    vAmortizedAmount    FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;   --R�ceptionne le montant d�j� amorti
    vSimulatedAmount    FAM_CALC_SIMULATION.FCS_AMORTIZATION_LC%type;   --R�ceptionne le montant d�j� simul�
    vBalanceAmount      FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --Solde du montant de base
    vRoundedBalance     FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --Solde arrondi

    function AssetsImputationsAmount(
      pFixedAssetsId   in FAM_FIXED_ASSETS.FAM_FIXED_ASSETS_ID%type
    , pManagedValueId  in FAM_MANAGED_VALUE.FAM_MANAGED_VALUE_ID%type
    , pPeriodId        in FAM_AMORTIZATION_PERIOD.ACS_PERIOD_ID%type
    , pLocalCurrencyId in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
    , pStructureElemId in FAM_STRUCTURE_ELEMENT.FAM_STRUCTURE_ELEMENT_ID%type
    )
      return FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type
    is
      vResult FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type   default 0;
    begin
      begin
        select nvl(sum(nvl(TOT.FTO_DEBIT_LC, 0) - nvl(TOT.FTO_CREDIT_LC, 0) ), 0)
          into vResult
          from ACS_PERIOD PER2
             , ACS_PERIOD PER
             , FAM_TOTAL_BY_PERIOD TOT
         where TOT.FAM_FIXED_ASSETS_ID = pFixedAssetsId
           and TOT.FAM_MANAGED_VALUE_ID = pManagedValueId
           and TOT.ACS_FINANCIAL_CURRENCY_ID = pLocalCurrencyId
           and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER2.ACS_PERIOD_ID = pPeriodId
           and PER.PER_END_DATE <= PER2.PER_END_DATE
           and exists(
                 select 1
                   from FAM_ELEMENT_DETAIL DET
                  where DET.FAM_STRUCTURE_ELEMENT_ID = pStructureElemId
                    and TOT.C_FAM_TRANSACTION_TYP = DET.C_FAM_TRANSACTION_TYP);
      exception
        when others then
          vResult  := 0;
      end;

      return vResult;
    end AssetsImputationsAmount;

    /** Retour du montant d'amortissement d�j� comptabilis�s i.e montants imput�s avec transaction
        de type 600..699
    **/
    function GetFixAssetAmortizedAmount(
      pFixedAssetsId  in FAM_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
    , pManagedValueId in FAM_TOTAL_BY_PERIOD.FAM_MANAGED_VALUE_ID%type
    )
      return FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type
    is
      vResult FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type;
    begin
      begin
        select nvl(sum(nvl(FTO_CREDIT_LC, 0) - nvl(FTO_DEBIT_LC, 0) ), 0)
          into vResult
          from FAM_TOTAL_BY_PERIOD
         where FAM_FIXED_ASSETS_ID = pFixedAssetsId
           and FAM_MANAGED_VALUE_ID = pManagedValueId
           and C_FAM_TRANSACTION_TYP between '600' and '699';
      exception
        when others then
          vResult  := 0;
      end;

      return vResult;
    end GetFixAssetAmortizedAmount;

    /** Retour du montant d'amortissement simul� pour le calcul courant **/
    function GetFixAssetSimulatedAmount(
      pFixedAssetsId  in FAM_CALC_SIMULATION.FAM_FIXED_ASSETS_ID%type
    , pManagedValueId in FAM_CALC_SIMULATION.FAM_MANAGED_VALUE_ID%type
    , pSimulationId   in FAM_CALC_SIMULATION.FAM_SIMULATION_ID%type
    )
      return FAM_CALC_SIMULATION.FCS_AMORTIZATION_LC%type
    is
      vResult FAM_CALC_SIMULATION.FCS_AMORTIZATION_LC%type;
    begin
      begin
        select nvl(sum(nvl(FCS_AMORTIZATION_LC, 0) ), 0)
          into vResult
          from FAM_CALC_SIMULATION
         where FAM_FIXED_ASSETS_ID = pFixedAssetsId
           and FAM_MANAGED_VALUE_ID = pManagedValueId
           and FAM_SIMULATION_ID = pSimulationId;
      exception
        when others then
          vResult  := 0;
      end;

      return vResult;
    end GetFixAssetSimulatedAmount;
  begin
    /*Recherche de la limite d'amortissment par rapport � l'�lement de structure correspondant */
    vAmortizationLimit  :=
      AssetsImputationsAmount(pFixedAssetsId   --Immobilisation
                            , pManagedValueId   --Valeur g�r�e
                            , pPeriodId   --P�riode d'amortissement
                            , pLocalCurrencyId   --Monnaie
                            , pStructureElemId   --El�ment "Limite d'amortissment"
                             );

    /*Si valeur r�siduelle renseign�e et que le montant "Base amortissement" y est inf�rieure on amorti la totalit�
        ==> montant amortissement = montant r�siduel
        ==> Taux est forc� � 100 %
        ==> Nb jours amortis forc� � 0
      Sinon
        ==> Montant amortissement  =   Montant amortissment selon calcul (Base * taux * dur�e)
                                     + Diff�rence d'arrondi du montant solde
    */
    if ((gNegativeBase = 0) and (pResidualValue is not null)
       and (pResidualValue <> 0)
       and (pAmortizationBase <= pResidualValue)) then
      vAmortizationAmount  := pAmortizationBase;
      pAmortizationRate    := 100;
      pAmortizationDays    := 0;
    else
      vAmortizationAmount  := pAmortizationBase *(pAmortizationRate / 100) *(pAmortizationDays / pCoveredDays);
      vBalanceAmount       := pAmortizationBase - vAmortizationAmount;

      if nvl(pRoundType, '0') = '0' then
        vRoundedBalance  := ACS_FUNCTION.RoundAmount(vBalanceAmount, pLocalCurrencyId);
      else
        vRoundedBalance  := ACS_FUNCTION.PCSRound(vBalanceAmount, pRoundType, pRoundAmount);
      end if;

      vAmortizationAmount  := vAmortizationAmount +(vBalanceAmount - vRoundedBalance);
    end if;

    /*R�ception amortissement d�j� comptabilis�s                                                         */
    vAmortizedAmount    := GetFixAssetAmortizedAmount(pFixedAssetsId, pManagedValueId);

    if pSimulationId is null then
      /*Force le montant d'amortissement � la diff�rence entre la limite d'amortissement et les          */
      /*amortissements d�j� effectu�s => Emp�cher le d�passement du montant � amortir                    */
      if     (vAmortizationLimit > 0)
         and (vAmortizationAmount > vAmortizationLimit - vAmortizedAmount) then
        vAmortizationAmount  := vAmortizationLimit - vAmortizedAmount;
      end if;
    else
      /*R�ception simulation d�j� calcul�es                                                              */
      vSimulatedAmount  := GetFixAssetSimulatedAmount(pFixedAssetsId, pManagedValueId, pSimulationId);

      /*Force le montant de simulation � la diff�rence entre la limite d'amortissement et les            */
      /*amortissements d�j� simul�es  => Emp�cher le d�passement du montant � amortir                    */
      if     (vAmortizationLimit > 0)
         and (vAmortizationAmount > vAmortizationLimit - vSimulatedAmount - vAmortizedAmount) then
        vAmortizationAmount  := vAmortizationLimit - vSimulatedAmount - vAmortizedAmount;
      end if;
    end if;

    return vAmortizationAmount;
  end GetAmortizationAmount;

  /**
  * Description  Retour du montant d'int�r�ts selon param�tres
  */
  function GetInterestAmount(
    pInterestBase    in FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type
  , pLocalCurrencyId in FAM_CALC_AMORTIZATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , pRoundType       in FAM_AMORTIZATION_METHOD.C_ROUND_TYPE%type
  , pRoundAmount     in FAM_AMORTIZATION_METHOD.AMO_ROUNDED_AMOUNT%type
  , pCoveredDays     in FAM_CALC_AMORTIZATION.CAL_DAYS%type
  , pInterestDays    in FAM_CALC_AMORTIZATION.CAL_DAYS%type
  , pInterestRate    in FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type
  )
    return FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_BASE_LC%type
  is
    vInterestAmount FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --R�ceptionne le montant d'int�r�t de retour LC
    vBalanceAmount  FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --Solde du montant de base
    vRoundedBalance FAM_CALC_AMORTIZATION.CAL_AMORTIZATION_RATE%type;   --Solde arrondi
  begin
    vInterestAmount  := pInterestBase *(pInterestRate / 100) *(pInterestDays / pCoveredDays);
    vBalanceAmount   := pInterestBase - vInterestAmount;

    if nvl(pRoundType, '0') = '0' then
      vRoundedBalance  := ACS_FUNCTION.RoundAmount(vBalanceAmount, pLocalCurrencyId);
    else
      vRoundedBalance  := ACS_FUNCTION.PCSRound(vBalanceAmount, pRoundType, pRoundAmount);
    end if;

    vInterestAmount  := vInterestAmount +(vBalanceAmount - vRoundedBalance);
    return vInterestAmount;
  end GetInterestAmount;

  /**
  * Description  Cr�ation d'un journal Immobilisation selon param�tres
  */
  function CreateJournal(
    pPeriodId    in ACS_PERIOD.ACS_PERIOD_ID%type
  , pDescription in FAM_JOURNAL.FJO_DESCR%type
  , pStatus      in FAM_JOURNAL.C_JOURNAL_STATUS%type
  )
    return FAM_JOURNAL.FAM_JOURNAL_ID%type
  is
    vResult          FAM_JOURNAL.FAM_JOURNAL_ID%type;   --R�ceptionne l'id journal nouvellement cr��
    vFinancialYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;   --R�ceptionne l'exercice de la p�riode donn�e
    vJouNumber       FAM_JOURNAL.FJO_NUMBER%type;   --R�ceptionne num�ro de journal
  begin
    begin
      /*R�ception de l'exercice financier de la p�riode*/
      select nvl(max(ACS_FINANCIAL_YEAR_ID), 0)
        into vFinancialYearId
        from ACS_PERIOD
       where ACS_PERIOD_ID = pPeriodId;

      /*R�ception d'un nouvel id de journal*/
      select init_id_seq.nextval
        into vResult
        from dual;

      /*R�ception d'un nouveau num�ro de journal */
      select nvl(max(FJO_NUMBER), 0) + 1
        into vJouNumber
        from FAM_JOURNAL
       where ACS_FINANCIAL_YEAR_ID = vFinancialYearId;

      /* Cr�ation du nouveau journal*/
      insert into FAM_JOURNAL
                  (FAM_JOURNAL_ID
                 , C_JOURNAL_STATUS
                 , ACS_FINANCIAL_YEAR_ID
                 , FJO_NUMBER
                 , FJO_DESCR
                 , PC_USER_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vResult
                 , pStatus
                 , vFinancialYearId
                 , vJouNumber
                 , pDescription
                 , null
                 , trunc(sysdate)
                 , UserIni
                  );
    exception
      when others then
        vResult  := null;
    end;

    return vResult;
  end CreateJournal;

  function CreateFamImputation(
    pJournalId             in     FAM_IMPUTATION.FAM_JOURNAL_ID%type
  , pDocumentId            in     FAM_IMPUTATION.FAM_DOCUMENT_ID%type
  , pPeriodId              in     FAM_IMPUTATION.ACS_PERIOD_ID%type
  , pTransactionDate       in     FAM_IMPUTATION.FIM_TRANSACTION_DATE%type
  , pValueDate             in     FAM_IMPUTATION.FIM_VALUE_DATE%type
  , pImputationDescr       in     FAM_IMPUTATION.FIM_DESCR%type
  , pFixedAssetsId         in     FAM_IMPUTATION.FAM_FIXED_ASSETS_ID%type
  , pCatalogueId           in     FAM_DOCUMENT.FAM_CATALOGUE_ID%type
  , pForeignCurrencyId     in     FAM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , pLocalCurrencyId       in     FAM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , pLocalCurrencyAmount   in     FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
  , pForeignCurrencyAmount in     FAM_IMPUTATION.FIM_AMOUNT_FC_D%type
  , pInterestImputation    in     boolean
  , pSimulationImputation  in     boolean
  , pAdjustment            in     FAM_IMPUTATION.FIM_ADJUSTMENT%type
  , pDocumentAmount        out    FAM_DOCUMENT.FDO_AMOUNT%type
  )
    return FAM_IMPUTATION.FAM_IMPUTATION_ID%type
  is
    type TAmounts is record(
      AmountLC FAM_IMPUTATION.FIM_AMOUNT_LC_D%type
    , AmountFC FAM_IMPUTATION.FIM_AMOUNT_FC_D%type
    );

    vResultImputationId FAM_IMPUTATION.FAM_IMPUTATION_ID%type;
    vBaseAmounts        TAmounts;
    vCalculatedAmounts  TAmounts;
    vExchangeRate       FAM_IMPUTATION.FIM_EXCHANGE_RATE%type;
    vBasePrice          FAM_IMPUTATION.FIM_BASE_PRICE%type;
    vTransactionTyp     FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;   --R�ceptionne le type de transaction du catalogue
    vFixCategId         FAM_IMPUTATION.FAM_FIXED_ASSETS_CATEG_ID%type;   --Cat�gorie de l'immob.
    vAmountLCD          FAM_IMPUTATION.FIM_AMOUNT_LC_D%type;
    vAmountLCC          FAM_IMPUTATION.FIM_AMOUNT_LC_C%type;
    vAmountFCD          FAM_IMPUTATION.FIM_AMOUNT_FC_D%type;
    vAmountFCC          FAM_IMPUTATION.FIM_AMOUNT_FC_C%type;

    -----
    function GetAmounts(pFamCatalogueId in FAM_DOCUMENT.FAM_CATALOGUE_ID%type, pAmounts in TAmounts)
      return TAmounts
    is
      vCatDebit      FAM_CATALOGUE.FCA_DEBIT%type;   --R�ceptionne le falg d'indication des montants au d�bit
      vResultAmounts TAmounts;   --R�ceptionne les montants de retour
    begin
      /* R�ception du flag indiquant le mouvement au d�bit*/
      select nvl(max(FCA_DEBIT), 1)
        into vCatDebit
        from FAM_CATALOGUE
       where FAM_CATALOGUE_ID = pFamCatalogueId;

      vResultAmounts  := pAmounts;

      if vCatDebit = 0 then
        -- Montant Imputation au Cr�dit
        vResultAmounts.AmountLC  := vResultAmounts.AmountLC * -1;
        vResultAmounts.AmountFC  := vResultAmounts.AmountFC * -1;
      end if;

      return vResultAmounts;
    end GetAmounts;

    function GetCatTransactionType(pFamCatalogueId in FAM_DOCUMENT.FAM_CATALOGUE_ID%type)
      return FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type
    is
      vTransactionTyp FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;
    begin
      begin
        select C_FAM_TRANSACTION_TYP
          into vTransactionTyp
          from FAM_CATALOGUE
         where FAM_CATALOGUE_ID = pFamCatalogueId;
      exception
        when others then
          vTransactionTyp  := null;
      end;

      return vTransactionTyp;
    end GetCatTransactionType;
  begin
    vBaseAmounts.AmountLC  := pLocalCurrencyAmount;
    vBaseAmounts.AmountFC  := pForeignCurrencyAmount;

    if pInterestImputation then
      vCalculatedAmounts  := vBaseAmounts;
    else
      vCalculatedAmounts  := GetAmounts(pCatalogueId, vBaseAmounts);
    end if;

    if sign(vCalculatedAmounts.AmountLC) = 1 then
      vAmountLCD  := vCalculatedAmounts.AmountLC;
      vAmountLCC  := 0;
    else
      vAmountLCD  := 0;
      vAmountLCC  := abs(vCalculatedAmounts.AmountLC);
    end if;

    if sign(vCalculatedAmounts.AmountFC) = 1 then
      vAmountFCD  := vCalculatedAmounts.AmountFC;
      vAmountFCC  := 0;
    else
      vAmountFCD  := 0;
      vAmountFCC  := abs(vCalculatedAmounts.AmountFC);
    end if;

    vBasePrice             := ACS_FUNCTION.GetBasePriceEUR(pTransactionDate, pForeignCurrencyId);
    vExchangeRate          :=
      ACS_FUNCTION.CalcRateOfExchangeEUR(abs(vCalculatedAmounts.AmountLC)
                                       , abs(vCalculatedAmounts.AmountFC)
                                       , pForeignCurrencyId
                                       , pTransactionDate
                                       , vBasePrice
                                        );
    vTransactionTyp        := GetCatTransactionType(pCatalogueId);
    vFixCategId            := FAM_FUNCTIONS.GetFixedAssetsCategory(pFixedAssetsId);

    select init_id_seq.nextval
      into vResultImputationId
      from dual;

    if pSimulationImputation then
      begin
        insert into FAM_IMP_SIMULATION
                    (FAM_IMP_SIMULATION_ID
                   , FAM_SIMULATION_ID
                   , FAM_FIXED_ASSETS_ID
                   , ACS_PERIOD_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , FAM_FIXED_ASSETS_CATEG_ID
                   , C_FAM_TRANSACTION_TYP
                   , FIS_VALUE_DATE
                   , FIS_TRANSACTION_DATE
                   , FIS_AMOUNT_LC_D
                   , FIS_AMOUNT_LC_C
                   , FIS_AMOUNT_FC_D
                   , FIS_AMOUNT_FC_C
                   , FIS_EXCHANGE_RATE
                   , FIS_BASE_PRICE
                   , FIS_ADJUSTMENT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vResultImputationId
                   , pDocumentId
                   , pFixedAssetsId
                   , pPeriodId
                   , pLocalCurrencyId
                   , pLocalCurrencyId
                   , vFixCategId
                   , vTransactionTyp
                   , pValueDate
                   , pValueDate
                   , vAmountLCD
                   , vAmountLCC
                   , vAmountFCD
                   , vAmountFCC
                   , 0
                   , 0
                   , pAdjustment
                   , sysdate
                   , UserIni
                    );
      exception
        when others then
          vResultImputationId  := null;
      end;
    else
      begin
        vResultImputationId  :=
          FAM_TRANSACTIONS.InsertFamImputation(pDocumentId
                                             , pJournalId
                                             , pPeriodId
                                             , pLocalCurrencyId
                                             , pLocalCurrencyId
                                             , pFixedAssetsId
                                             , vFixCategId
                                             , vTransactionTyp
                                             , pImputationDescr
                                             , pTransactionDate
                                             , pValueDate
                                             , vAmountLCD
                                             , vAmountLCC
                                             , vAmountFCD
                                             , vAmountFCC
                                             ,0
                                             ,0
                                             , pAdjustment
                                              );
        pDocumentAmount  := vCalculatedAmounts.AmountLC;
      exception
        when others then
          vResultImputationId  := null;
      end;
    end if;

    return vResultImputationId;
  end CreateFamImputation;

  /* Description
   *    Proc�dure globale de g�n�ration des document , imputations de simulation
   */
  procedure SimDocumentGenerate(
    pSimulationId  in FAM_SIMULATION.FAM_SIMULATION_id%type
  , pStartPeriodId in ACS_PERIOD.ACS_PERIOD_ID%type
  , pEndPeriodId   in ACS_PERIOD.ACS_PERIOD_ID%type
  )
  is
    /*Curseur de retour des p�riodes simul�es comprises dans les intervalles donn�es*/
    cursor vSimulatedPeriodCursor(
      pStartPeriodId ACS_PERIOD.ACS_PERIOD_ID%type
    , pEndPeriodId   ACS_PERIOD.ACS_PERIOD_ID%type
    )
    is
      select PER.ACS_PERIOD_ID
           , PER.PER_NO_PERIOD
        from ACS_PERIOD PER
       where exists(select 1
                      from ACS_PERIOD PER1
                     where PER1.ACS_PERIOD_ID = pStartPeriodId
                       and PER.PER_START_DATE >= PER1.PER_START_DATE)
         and exists(select 1
                      from ACS_PERIOD PER2
                     where PER2.ACS_PERIOD_ID = pEndPeriodId
                       and PER.PER_START_DATE <= PER2.PER_START_DATE)
         and PER.C_TYPE_PERIOD = 2;

    /*Curseur de retour des positions simul�es pour la simulation et la p�riode donn�e*/
    cursor vSimulatedPositionCursor(
      pSimulationId FAM_SIMULATION.FAM_SIMULATION_id%type
    , pPeriodId     ACS_PERIOD.ACS_PERIOD_ID%type
    )
    is
      select FCS.FAM_FIXED_ASSETS_ID
           , FCS.FAM_MANAGED_VALUE_ID
           , FCS.ACS_FINANCIAL_CURRENCY_ID
           , FCS.ACS_ACS_FINANCIAL_CURRENCY_ID
           , FCS.FCS_AMORTIZATION_BASE_LC
           , FCS.FCS_AMORTIZATION_LC
           , FCS.FCS_AMORTIZATION_FC
           , FCS.FCS_INTEREST_BASE
           , FCS.FCS_INTEREST_AMOUNT_1
           , FCS.FCS_INTEREST_AMOUNT_2
           , FCS.FCS_ADJUSTMENT
           , APP.FAM_AMORTIZATION_METHOD_ID
           , AMO.FAM_CATALOGUE_ID
           , AMO.FAM_FAM_CATALOGUE_ID
           , AMO.C_INTEREST_CALC_RULES
           , FCS.FAM_CALC_SIMULATION_ID
        from FAM_AMORTIZATION_METHOD AMO
           , FAM_AMO_APPLICATION APP
           , FAM_CALC_SIMULATION FCS
       where FCS.FAM_SIMULATION_ID = pSimulationId
         and FCS.ACS_PERIOD_ID = pPeriodId
         and APP.FAM_FIXED_ASSETS_ID = FCS.FAM_FIXED_ASSETS_ID
         and APP.FAM_MANAGED_VALUE_ID = FCS.FAM_MANAGED_VALUE_ID
         and AMO.FAM_AMORTIZATION_METHOD_ID = APP.FAM_AMORTIZATION_METHOD_ID;

    vSimulatedPeriod    vSimulatedPeriodCursor%rowtype;
    vSimulatedPosition  vSimulatedPositionCursor%rowtype;
    vFinancialYearId    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;   --R�ceptionne l'exercice de la p�riode donn�e
    vFamSimImputationId FAM_IMPUTATION.FAM_IMPUTATION_ID%type;   --R�ceptionne id imputation simulation cr��e
    vDocumentAmount     FAM_DOCUMENT.FDO_AMOUNT%type;

    /* V�rifie l'existence de positions calcul�s non encore imput�s pour la p�riode de calcul donn�e*/
    function ExistNotChargedSimPosition(
      pSimulationId in FAM_SIMULATION.FAM_SIMULATION_id%type
    , pPeriodId     in ACS_PERIOD.ACS_PERIOD_ID%type
    )
      return boolean
    is
      vResult   boolean                         default false;
      vPeriodId ACS_PERIOD.ACS_PERIOD_ID%type;
    begin
      begin
        select nvl(max(ACS_PERIOD_ID), 0)
          into vPeriodId
          from FAM_CALC_SIMULATION FCS
         where FCS.FAM_SIMULATION_ID = pSimulationId
           and FCS.ACS_PERIOD_ID = pPeriodId
           and FAM_IMP_SIMULATION_ID is null;

        vResult  :=(vPeriodId <> 0);
      exception
        when others then
          vResult  := false;
      end;

      return vResult;
    end ExistNotChargedSimPosition;

    function GetPeriodEndDate(pPeriodId in ACS_PERIOD.ACS_PERIOD_ID%type)
      return ACS_PERIOD.PER_START_DATE%type
    is
      vResult ACS_PERIOD.PER_START_DATE%type;
    begin
      begin
        select PER_END_DATE
          into vResult
          from ACS_PERIOD
         where ACS_PERIOD_ID = pPeriodId;
      exception
        when others then
          vResult  := sysdate;
      end;

      return vResult;
    end GetPeriodEndDate;
  begin
    /*Parcours des positions simul�es par p�riode de simulation*/
    open vSimulatedPeriodCursor(pStartPeriodId, pEndPeriodId);

    fetch vSimulatedPeriodCursor
     into vSimulatedPeriod;

    while vSimulatedPeriodCursor%found loop
      if ExistNotChargedSimPosition(pSimulationId, vSimulatedPeriod.ACS_PERIOD_ID) then
        /*R�ception de l'exercice financier de la p�riode*/
        select nvl(max(ACS_FINANCIAL_YEAR_ID), 0)
          into vFinancialYearId
          from ACS_PERIOD
         where ACS_PERIOD_ID = vSimulatedPeriod.ACS_PERIOD_ID;

        /*Parcours des positions simul�es*/
        open vSimulatedPositionCursor(pSimulationId, vSimulatedPeriod.ACS_PERIOD_ID);

        fetch vSimulatedPositionCursor
         into vSimulatedPosition;

        while vSimulatedPositionCursor%found loop
          --Catalogue amortissement existe
          if     (vSimulatedPosition.FAM_CATALOGUE_ID is not null)
             and (vSimulatedPosition.FCS_AMORTIZATION_BASE_LC is not null) then
            /*Cr�ation imputation simulation immobilisation selon catalogue */
            vFamSimImputationId  :=
              CreateFamImputation(null
                                , pSimulationId
                                , vSimulatedPeriod.ACS_PERIOD_ID
                                , GetPeriodEndDate(vSimulatedPeriod.ACS_PERIOD_ID)
                                , GetPeriodEndDate(vSimulatedPeriod.ACS_PERIOD_ID)
                                , null
                                , vSimulatedPosition.FAM_FIXED_ASSETS_ID
                                , vSimulatedPosition.FAM_CATALOGUE_ID
                                , vSimulatedPosition.ACS_FINANCIAL_CURRENCY_ID
                                , vSimulatedPosition.ACS_ACS_FINANCIAL_CURRENCY_ID
                                , vSimulatedPosition.FCS_AMORTIZATION_LC
                                , vSimulatedPosition.FCS_AMORTIZATION_FC
                                , false
                                , true
                                , vSimulatedPosition.FCS_ADJUSTMENT
                                , vDocumentAmount
                                 );

            if vFamSimImputationId is not null then
              FAM_TRANSACTIONS.Create_VAL_ACT_Imputations(vFamSimImputationId
                                                        , 0
                                                        , false
                                                        , false
                                                        , vSimulatedPosition.FAM_CATALOGUE_ID
                                                        , vSimulatedPosition.FAM_MANAGED_VALUE_ID
                                                         );

              -- Mise � jour table amortissements calcul�s
              update FAM_CALC_SIMULATION
                 set FAM_IMP_SIMULATION_ID = vFamSimImputationId
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where FAM_CALC_SIMULATION_ID = vSimulatedPosition.FAM_CALC_SIMULATION_ID;
            end if;
          end if;

          --Catalogue int�r�t  existe
          if     (vSimulatedPosition.FAM_FAM_CATALOGUE_ID is not null)
             and (vSimulatedPosition.FCS_INTEREST_BASE is not null) then
            if vSimulatedPosition.C_INTEREST_CALC_RULES in('1', '3') then
              vFamSimImputationId  :=
                CreateFamImputation(null
                                  , pSimulationId
                                  , vSimulatedPeriod.ACS_PERIOD_ID
                                  , GetPeriodEndDate(vSimulatedPeriod.ACS_PERIOD_ID)
                                  , GetPeriodEndDate(vSimulatedPeriod.ACS_PERIOD_ID)
                                  , null
                                  , vSimulatedPosition.FAM_FIXED_ASSETS_ID
                                  , vSimulatedPosition.FAM_FAM_CATALOGUE_ID
                                  , vSimulatedPosition.ACS_FINANCIAL_CURRENCY_ID
                                  , vSimulatedPosition.ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , vSimulatedPosition.FCS_INTEREST_AMOUNT_1
                                  , 0
                                  , true
                                  , true
                                  , 0
                                  , vDocumentAmount
                                   );

              if vFamSimImputationId is not null then
                FAM_TRANSACTIONS.Create_VAL_ACT_Imputations(vFamSimImputationId
                                                          , 0
                                                          , true
                                                          , true
                                                          , vSimulatedPosition.FAM_FAM_CATALOGUE_ID
                                                          , vSimulatedPosition.FAM_MANAGED_VALUE_ID
                                                           );

                -- Mise � jour table amortissements calcul�s
                update FAM_CALC_SIMULATION
                   set FAM_FAM_IMP_SIMULATION_ID = vFamSimImputationId
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_CALC_SIMULATION_ID = vSimulatedPosition.FAM_CALC_SIMULATION_ID;
              end if;
            end if;

            /*Cr�ation imputation immob int�r�ts 2 si r�gles de calcul sur les 2 */
            if vSimulatedPosition.C_INTEREST_CALC_RULES in('2', '3') then
              -- Cr�ation imputation immobilisation int�r�t
              vFamSimImputationId  :=
                CreateFamImputation(null
                                  , pSimulationId
                                  , vSimulatedPeriod.ACS_PERIOD_ID
                                  , GetPeriodEndDate(vSimulatedPeriod.ACS_PERIOD_ID)
                                  , GetPeriodEndDate(vSimulatedPeriod.ACS_PERIOD_ID)
                                  , null
                                  , vSimulatedPosition.FAM_FIXED_ASSETS_ID
                                  , vSimulatedPosition.FAM_FAM_CATALOGUE_ID
                                  , vSimulatedPosition.ACS_FINANCIAL_CURRENCY_ID
                                  , vSimulatedPosition.ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , vSimulatedPosition.FCS_INTEREST_AMOUNT_2
                                  , 0
                                  , true
                                  , true
                                  , 0
                                  , vDocumentAmount
                                   );

              if vFamSimImputationId is not null then
                FAM_TRANSACTIONS.Create_VAL_ACT_Imputations(vFamSimImputationId
                                                          , 0
                                                          , false
                                                          , true
                                                          , vSimulatedPosition.FAM_FAM_CATALOGUE_ID
                                                          , vSimulatedPosition.FAM_MANAGED_VALUE_ID
                                                           );

                update FAM_CALC_SIMULATION
                   set FAM2_FAM_IMP_SIMULATION_ID = vFamSimImputationId
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where FAM_CALC_SIMULATION_ID = vSimulatedPosition.FAM_CALC_SIMULATION_ID;
              end if;
            end if;
          end if;

          fetch vSimulatedPositionCursor
           into vSimulatedPosition;
        end loop;

        close vSimulatedPositionCursor;
      end if;

      fetch vSimulatedPeriodCursor
       into vSimulatedPeriod;
    end loop;

    close vSimulatedPeriodCursor;
  end SimDocumentGenerate;

  /**
  * Description Diff�rence entre montant comptabilis� et montant planifi�
  **/
  function GetAmortizationDiffAmount(
    aFamPlanHeaderId in FAM_PLAN_HEADER.FAM_PLAN_HEADER_ID%type
  , aPeriodId        in ACS_PERIOD.ACS_PERIOD_ID%type
  )
    return FAM_PLAN_EXERCISE.FPE_ADAPTED_AMO_LC%type
  is
    vResult       FAM_PLAN_EXERCISE.FPE_AMORTIZATION_LC%type;
    vLastCalcDate ACS_PERIOD.PER_END_DATE%type;
  begin
    select max(PER.PER_END_DATE)
      into vLastCalcDate
      from ACS_PERIOD PER
     where exists(
             select 1
               from FAM_CALC_AMORTIZATION CAL
                  , FAM_PER_CALC_BY_VALUE FPC
                  , FAM_AMORTIZATION_PERIOD FAP
              where PER.ACS_PERIOD_ID = FPC.ACS_PERIOD_ID
                and FPC.ACS_PERIOD_ID = FAP.ACS_PERIOD_ID
                and FPC.FAM_PER_CALC_BY_VALUE_ID = CAL.FAM_PER_CALC_BY_VALUE_ID(+)
                and FAP.ACS_PERIOD_ID <> aPeriodId
                and CAL.FAM_IMPUTATION_ID is not null);

    vResult  := 0;

    if vLastCalcDate is not null then
      begin
        select   sum(FPP.FPP_ADAPTED_AMO_LC) -
                 FAM_AMORTIZATION_PLAN.GetAmortizedAmount(FPH.FAM_FIXED_ASSETS_ID
                                                        , FPH.FAM_MANAGED_VALUE_ID
                                                        , vLastCalcDate
                                                         )
            into vResult
            from FAM_PLAN_HEADER FPH
               , FAM_PLAN_EXERCISE FPE
               , FAM_PLAN_PERIOD FPP
           where FPH.FAM_PLAN_HEADER_ID = aFamPlanHeaderId
             and FPE.FAM_PLAN_HEADER_ID = FPH.FAM_PLAN_HEADER_ID
             and FPP.FAM_PLAN_EXERCISE_ID = FPE.FAM_PLAN_EXERCISE_ID
             and FPP.FPP_AMORTIZATION_END <= vLastCalcDate
        group by FPH.FAM_FIXED_ASSETS_ID
               , FPH.FAM_MANAGED_VALUE_ID;
      exception
        when no_data_found then
          vResult  := 0;
      end;
    end if;

    return vResult;
  end GetAmortizationDiffAmount;

  /**
  * Cr�ation des positions d'amortissement calcul�es par copie des positions des plan
  * correspondants.
  **/
  procedure MoveAmortizationPlan(
    aCalcByValueId  in FAM_PER_CALC_BY_VALUE.FAM_PER_CALC_BY_VALUE_ID%type
  , pPeriodId       in FAM_PER_CALC_BY_VALUE.ACS_PERIOD_ID%type
  , pManagedValueId in FAM_PER_CALC_BY_VALUE.FAM_MANAGED_VALUE_ID%type
  , pFixCategId     in FAM_FIXED_ASSETS_CATEG.FAM_FIXED_ASSETS_CATEG_ID%type
  , pIsSimulation   in number   --Indique si simulation (1) ou non(0)
  )
  is
    --Curseur de recherche des positions d'immob. encore amorties � la date de calcul
    --( i.e. existant dans fam_plan_period) et n�cessitant un ajustement
    -- et les positions immob. qui ne sont plus amorties � la date de calcul mais n�cessitant
    -- n�anmoins un ajustement
    --Produit cart�sien avec ACS_PERIOD mais comme on y acc�de par l'Id celui ne
    --nous retourne qu'un seul row
    cursor crPlanTreatment
    is
      select init_id_seq.nextval NEW_ID
           , FIX.FAM_FIXED_ASSETS_ID
           , PER.PER_END_DATE APP_END_DATE
           , FIX.FAM_FIXED_ASSETS_CATEG_ID
           , LocalCurrencyId ACS_FINANCIAL_CURRENCY_ID
           , LocalCurrencyId ACS_ACS_FINANCIAL_CURRENCY_ID
           , FAM_AMORTIZATION.GetAmortizationDiffAmount(FPH.FAM_PLAN_HEADER_ID, pPeriodId) DIFF
        from FAM_FIXED_ASSETS FIX
           , FAM_PLAN_HEADER FPH
           , ACS_PERIOD PER
       where FIX.FAM_FIXED_ASSETS_CATEG_ID = decode(pFixCategId, 0, FIX.FAM_FIXED_ASSETS_CATEG_ID, pFixCategId)
         and FPH.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
         and FPH.FAM_MANAGED_VALUE_ID = pManagedValueId
         and FPH.C_AMO_PLAN_STATUS = '1'
         and FPH.C_FPH_BLOCKING_REASON = '04'
         and PER.ACS_PERIOD_ID = pPeriodId;

    tplPlanTreatment crPlanTreatment%rowtype;
  begin
    --1� Traitement.
    --Pour les fiches dont le plan actif a le code C_FPH_BLOCKING_REASON = '04'
    --G�n�rer une mise � niveau de l'�cart
    open crPlanTreatment;

    fetch crPlanTreatment
     into tplPlanTreatment;

    while crPlanTreatment%found loop
      if pIsSimulation = 0 then
        insert into FAM_CALC_AMORTIZATION
                    (FAM_CALC_AMORTIZATION_ID
                   , FAM_PER_CALC_BY_VALUE_ID
                   , FAM_FIXED_ASSETS_ID
                   , CAL_TRANSACTION_DATE
                   , CAL_VALUE_DATE
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , CAL_AMORTIZATION_BASE_LC
                   , CAL_DAYS
                   , CAL_AMORTIZATION_RATE
                   , CAL_AMORTIZATION_LC
                   , CAL_ADJUSTMENT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (tplPlanTreatment.NEW_ID
                   , aCalcByValueId
                   , tplPlanTreatment.FAM_FIXED_ASSETS_ID
                   , tplPlanTreatment.APP_END_DATE
                   , tplPlanTreatment.APP_END_DATE
                   , tplPlanTreatment.ACS_FINANCIAL_CURRENCY_ID
                   , tplPlanTreatment.ACS_ACS_FINANCIAL_CURRENCY_ID
                   , 0
                   , 0
                   , 0
                   , tplPlanTreatment.DIFF
                   , 1
                   , trunc(sysdate)
                   , UserIni
                    );
      else
        insert into FAM_CALC_SIMULATION
                    (FAM_CALC_SIMULATION_ID
                   , FAM_SIMULATION_ID
                   , ACS_PERIOD_ID
                   , FAM_FIXED_ASSETS_ID
                   , FAM_MANAGED_VALUE_ID
                   , FAM_FIXED_ASSETS_CATEG_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , FCS_AMORTIZATION_BASE_LC
                   , FCS_AMORTIZATION_RATE
                   , FCS_DAYS
                   , FCS_AMORTIZATION_LC
                   , FCS_ADJUSTMENT
                   , A_DATECRE
                   , A_IDCRE
                    )
          select tplPlanTreatment.NEW_ID
               , aCalcByValueId
               , pPeriodId
               , tplPlanTreatment.FAM_FIXED_ASSETS_ID
               , pManagedValueId
               , tplPlanTreatment.FAM_FIXED_ASSETS_CATEG_ID
               , tplPlanTreatment.ACS_FINANCIAL_CURRENCY_ID
               , tplPlanTreatment.ACS_ACS_FINANCIAL_CURRENCY_ID
               , 0
               , 0
               , 0
               , tplPlanTreatment.DIFF
               , SIM_ADJUSTMENT
               , trunc(sysdate)
               , UserIni
            from FAM_SIMULATION
           where FAM_SIMULATION_ID = aCalcByValueId
             and SIM_ADJUSTMENT = 1;
      end if;

      fetch crPlanTreatment
       into tplPlanTreatment;
    end loop;

    close crPlanTreatment;

    --2� Traitement.
    --Insertion des plans d'amortissements par p�riode correspondantes
    if pIsSimulation = 0 then
      insert into FAM_CALC_AMORTIZATION
                  (FAM_CALC_AMORTIZATION_ID
                 , FAM_PER_CALC_BY_VALUE_ID
                 , FAM_FIXED_ASSETS_ID
                 , CAL_TRANSACTION_DATE
                 , CAL_VALUE_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CAL_AMORTIZATION_BASE_LC
                 , CAL_DAYS
                 , CAL_AMORTIZATION_RATE
                 , CAL_AMORTIZATION_LC
                 , CAL_ADJUSTMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , aCalcByValueId
             , FIX.FAM_FIXED_ASSETS_ID
             , FPP.APP_END_DATE
             , FPP.APP_END_DATE
             , FPE.ACS_FINANCIAL_CURRENCY_ID
             , FPE.ACS_ACS_FINANCIAL_CURRENCY_ID
             , FPP.FPP_AMORTIZATION_BASE_LC
             , FPP.FPP_DAYS
             , FPE.FPE_RATE
             , FPP.FPP_ADAPTED_AMO_LC
             , 0
             , trunc(sysdate)
             , UserIni
          from FAM_FIXED_ASSETS FIX
             , FAM_PLAN_HEADER FPH
             , FAM_PLAN_EXERCISE FPE
             , FAM_PLAN_PERIOD FPP
         where FIX.FAM_FIXED_ASSETS_CATEG_ID = pFixCategId
           and FPH.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
           and FPH.FAM_MANAGED_VALUE_ID = pManagedValueId
           and FPH.C_AMO_PLAN_STATUS = '1'
           and FPE.FAM_PLAN_HEADER_ID = FPH.FAM_PLAN_HEADER_ID
           and FPP.FAM_PLAN_EXERCISE_ID = FPE.FAM_PLAN_EXERCISE_ID
           and exists(select 1
                        from ACS_PERIOD PER
                       where PER.ACS_PERIOD_ID = pPeriodId
                         and FPP.APP_END_DATE = PER.PER_END_DATE);
    else
      insert into FAM_CALC_SIMULATION
                  (FAM_CALC_SIMULATION_ID
                 , FAM_SIMULATION_ID
                 , ACS_PERIOD_ID
                 , FAM_FIXED_ASSETS_ID
                 , FAM_MANAGED_VALUE_ID
                 , FAM_FIXED_ASSETS_CATEG_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , FCS_AMORTIZATION_BASE_LC
                 , FCS_AMORTIZATION_RATE
                 , FCS_DAYS
                 , FCS_AMORTIZATION_LC
                 , FCS_ADJUSTMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , aCalcByValueId
             , pPeriodId
             , FIX.FAM_FIXED_ASSETS_ID
             , FPH.FAM_MANAGED_VALUE_ID
             , FIX.FAM_FIXED_ASSETS_CATEG_ID
             , FPE.ACS_FINANCIAL_CURRENCY_ID
             , FPE.ACS_ACS_FINANCIAL_CURRENCY_ID
             , FPP.FPP_AMORTIZATION_BASE_LC
             , FPE.FPE_RATE
             , FPP.FPP_DAYS
             , FPP.FPP_ADAPTED_AMO_LC
             , 0
             , trunc(sysdate)
             , UserIni
          from FAM_FIXED_ASSETS FIX
             , FAM_PLAN_HEADER FPH
             , FAM_PLAN_EXERCISE FPE
             , FAM_PLAN_PERIOD FPP
         where FIX.FAM_FIXED_ASSETS_CATEG_ID = decode(pFixCategId, 0, FIX.FAM_FIXED_ASSETS_CATEG_ID, pFixCategId)
           and FPH.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
           and FPH.FAM_MANAGED_VALUE_ID = pManagedValueId
           and (    (FPH.C_AMO_PLAN_STATUS = '1')
                or (FPH.C_AMO_PLAN_STATUS = '9') )
           and FPE.FAM_PLAN_HEADER_ID = FPH.FAM_PLAN_HEADER_ID
           and FPP.FAM_PLAN_EXERCISE_ID = FPE.FAM_PLAN_EXERCISE_ID
           and exists(select 1
                        from ACS_PERIOD PER
                       where PER.ACS_PERIOD_ID = pPeriodId
                         and FPP.APP_END_DATE = PER.PER_END_DATE);
    end if;
  end MoveAmortizationPlan;
begin
  -- Initialisation des variables pour la session
  UserIni          := PCS.PC_I_LIB_SESSION.GetUserIni;
  LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
end FAM_AMORTIZATION;
