--------------------------------------------------------
--  DDL for Package Body STM_PRC_STOCK_EVOLUTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_STOCK_EVOLUTION" 
is
  /* Déclarations variables globales */
  gMvtDate           date;
  gAnnualEvolutionId STM_ANNUAL_EVOLUTION.STM_ANNUAL_EVOLUTION_ID%type;
  iMonthNumber       char(2);
  gFirstYear         number;
  gFirstMonth        number;
  gLastMonth         number;
  gLastYear          number;
  gCurrentMonth      number;   --month number
  gCurrentYear       number;   --Acurrent year

  /**
  * function pSeekExerciseEvolutionId
  * Description
  *   recherche de l'id da table STM_EXERCISE_EVOL_MOVEMENT à mettre à jour
  * @created fp 2000
  * @lastUpdate
  */
  function pSeekExerciseEvolutionId(
    iGoodId     in number
  , iStockId    in number
  , iExerciseId in number
  , iPeriodId   in number
  , iCharacId1  in number
  , iCharacId2  in number
  , iCharacId3  in number
  , iCharacId4  in number
  , iCharacId5  in number
  , iCharac1    in varchar2
  , iCharac2    in varchar2
  , iCharac3    in varchar2
  , iCharac4    in varchar2
  , iCharac5    in varchar2
  )
    return number
  is
    lTemp    STM_EXERCISE_EVOLUTION.STM_EXERCISE_EVOLUTION_ID%type;
    lExeName STM_EXERCISE.EXE_DESCRIPTION%type;
    lCharac1 STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_1%type;
    lCharac2 STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_2%type;
    lCharac3 STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_3%type;
    lCharac4 STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_4%type;
    lCharac5 STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_5%type;
  begin
    if iCharacId1 is not null then
      lCharac1 := nvl(iCharac1, 'N/A');
    end if;
    if iCharacId2 is not null then
      lCharac2 := nvl(iCharac2, 'N/A');
    end if;
    if iCharacId3 is not null then
      lCharac3 := nvl(iCharac3, 'N/A');
    end if;
    if iCharacId4 is not null then
      lCharac4 := nvl(iCharac4, 'N/A');
    end if;
    if iCharacId5 is not null then
      lCharac5 := nvl(iCharac5, 'N/A');
    end if;
    if lCharac5 is not null then
      select max(stm_exercise_evolution_id)
        into lTemp
        from stm_exercise_evolution
       where gco_good_id = iGoodId
         and stm_exercise_id = iExerciseId
         and stm_period_id = iPeriodId
         and stm_stock_id = iStockId
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and gco3_gco_characterization_id = iCharacId4
         and gco4_gco_characterization_id = iCharacId5
         and spe_characterization_value_1 = lCharac1
         and spe_characterization_value_2 = lCharac2
         and spe_characterization_value_3 = lCharac3
         and spe_characterization_value_4 = lCharac4
         and spe_characterization_value_5 = lCharac5;
    elsif lCharac4 is not null then
      select max(stm_exercise_evolution_id)
        into lTemp
        from stm_exercise_evolution
       where gco_good_id = iGoodId
         and stm_exercise_id = iExerciseId
         and stm_period_id = iPeriodId
         and stm_stock_id = iStockId
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and gco3_gco_characterization_id = iCharacId4
         and spe_characterization_value_1 = lCharac1
         and spe_characterization_value_2 = lCharac2
         and spe_characterization_value_3 = lCharac3
         and spe_characterization_value_4 = lCharac4;
    elsif lCharac3 is not null then
      select max(stm_exercise_evolution_id)
        into lTemp
        from stm_exercise_evolution
       where gco_good_id = iGoodId
         and stm_exercise_id = iExerciseId
         and stm_period_id = iPeriodId
         and stm_stock_id = iStockId
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and spe_characterization_value_1 = lCharac1
         and spe_characterization_value_2 = lCharac2
         and spe_characterization_value_3 = lCharac3;
    elsif lCharac2 is not null then
      select max(stm_exercise_evolution_id)
        into lTemp
        from stm_exercise_evolution
       where gco_good_id = iGoodId
         and stm_exercise_id = iExerciseId
         and stm_period_id = iPeriodId
         and stm_stock_id = iStockId
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and spe_characterization_value_1 = lCharac1
         and spe_characterization_value_2 = lCharac2;
    elsif lCharac1 is not null then
      select max(stm_exercise_evolution_id)
        into lTemp
        from stm_exercise_evolution
       where gco_good_id = iGoodId
         and stm_exercise_id = iExerciseId
         and stm_period_id = iPeriodId
         and stm_stock_id = iStockId
         and gco_characterization_id = iCharacId1
         and spe_characterization_value_1 = lCharac1;
    else
      select max(stm_exercise_evolution_id)
        into lTemp
        from stm_exercise_evolution
       where gco_good_id = iGoodId
         and stm_exercise_id = iExerciseId
         and stm_period_id = iPeriodId
         and stm_stock_id = iStockId;
    end if;

    --Si pas de position dans STM_EXERCISE_EVOLUTION,
    --on crée une position pour toutes les périodes
    if lTemp is null then
      insert into stm_exercise_evolution
                  (stm_exercise_evolution_id
                 , gco_good_id
                 , stm_stock_id
                 , stm_exercise_id
                 , stm_period_id
                 , gco_characterization_id
                 , gco_gco_characterization_id
                 , gco2_gco_characterization_id
                 , gco3_gco_characterization_id
                 , gco4_gco_characterization_id
                 , spe_characterization_value_1
                 , spe_characterization_value_2
                 , spe_characterization_value_3
                 , spe_characterization_value_4
                 , spe_characterization_value_5
                 , a_datecre
                 , a_idcre
                  )
        select Init_id_seq.nextval
             , iGoodId
             , iStockId
             , iExerciseId
             , stm_period_id
             , iCharacId1
             , iCharacId2
             , iCharacId3
             , iCharacId4
             , iCharacId5
             , lCharac1
             , lCharac2
             , lCharac3
             , lCharac4
             , lCharac5
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from stm_period
         where stm_exercise_id = iExerciseId;

      --Une fois les positions créées, on recheche à nouveau l'Id
      --de la position correpondante
      if lCharac5 is not null then
        select max(stm_exercise_evolution_id)
          into lTemp
          from stm_exercise_evolution
         where gco_good_id = iGoodId
           and stm_exercise_id = iExerciseId
           and stm_period_id = iPeriodId
           and stm_stock_id = iStockId
           and gco_characterization_id = iCharacId1
           and gco_gco_characterization_id = iCharacId2
           and gco2_gco_characterization_id = iCharacId3
           and gco3_gco_characterization_id = iCharacId4
           and gco4_gco_characterization_id = iCharacId5
           and spe_characterization_value_1 = lCharac1
           and spe_characterization_value_2 = lCharac2
           and spe_characterization_value_3 = lCharac3
           and spe_characterization_value_4 = lCharac4
           and spe_characterization_value_5 = lCharac5;
      elsif lCharac4 is not null then
        select max(stm_exercise_evolution_id)
          into lTemp
          from stm_exercise_evolution
         where gco_good_id = iGoodId
           and stm_exercise_id = iExerciseId
           and stm_period_id = iPeriodId
           and stm_stock_id = iStockId
           and gco_characterization_id = iCharacId1
           and gco_gco_characterization_id = iCharacId2
           and gco2_gco_characterization_id = iCharacId3
           and gco3_gco_characterization_id = iCharacId4
           and spe_characterization_value_1 = lCharac1
           and spe_characterization_value_2 = lCharac2
           and spe_characterization_value_3 = lCharac3
           and spe_characterization_value_4 = lCharac4;
      elsif lCharac3 is not null then
        select max(stm_exercise_evolution_id)
          into lTemp
          from stm_exercise_evolution
         where gco_good_id = iGoodId
           and stm_exercise_id = iExerciseId
           and stm_period_id = iPeriodId
           and stm_stock_id = iStockId
           and gco_characterization_id = iCharacId1
           and gco_gco_characterization_id = iCharacId2
           and gco2_gco_characterization_id = iCharacId3
           and spe_characterization_value_1 = lCharac1
           and spe_characterization_value_2 = lCharac2
           and spe_characterization_value_3 = lCharac3;
      elsif lCharac2 is not null then
        select max(stm_exercise_evolution_id)
          into lTemp
          from stm_exercise_evolution
         where gco_good_id = iGoodId
           and stm_exercise_id = iExerciseId
           and stm_period_id = iPeriodId
           and stm_stock_id = iStockId
           and gco_characterization_id = iCharacId1
           and gco_gco_characterization_id = iCharacId2
           and spe_characterization_value_1 = lCharac1
           and spe_characterization_value_2 = lCharac2;
      elsif lCharac1 is not null then
        select max(stm_exercise_evolution_id)
          into lTemp
          from stm_exercise_evolution
         where gco_good_id = iGoodId
           and stm_exercise_id = iExerciseId
           and stm_period_id = iPeriodId
           and stm_stock_id = iStockId
           and gco_characterization_id = iCharacId1
           and spe_characterization_value_1 = lCharac1;
      else
        select max(stm_exercise_evolution_id)
          into lTemp
          from stm_exercise_evolution
         where gco_good_id = iGoodId
           and stm_exercise_id = iExerciseId
           and stm_period_id = iPeriodId
           and stm_stock_id = iStockId;
      end if;

      -- si on a toujours pas de période correspondante
      if lTemp is null then
        select max(EXE_DESCRIPTION)
          into lExeName
          from STM_EXERCISE
         where STM_EXERCISE_ID = iExerciseId;
        raise_application_error(-20078, 'PCS - Problem with stock exercice-period definition. Please check exercise : ' || lExeName);
      end if;
    end if;

    return lTemp;
  end pSeekExerciseEvolutionId;

  /**
  * Function pMonth
  * Description
  *    retourne le numéro du mois de la date passée en paramètre
  * @author JS
  * @lastUpdate
  * @param  lDate date de référence
  * @return  pMonth number
  */
  function pMonth(lDate date)
    return number
  is
  begin
    -- returns the iMonth number out of lDate
    return to_number(to_char(lDate, 'MM') );
  end pMonth;

  /**
  * Function pYear
  * Description
  *   retrourne l'année de la date passée en paramètre
  * @author JS
  * @lastUpdate
  * @param lDate : date de référence
  * @return  year using format ('YYYY')
  */
  function pYear(lDate date)
    return number
  is
  begin
    return to_number(to_char(lDate, 'YYYY') );
  end pYear;

  /**
  * procedure pSetStartingValues
  * Description
  *    Mise à jour des quantités et valeurs de début d'année
  * @author FP
  * @created 22/05/2002
  * @lastUpdate
  * @private
  * @param iGoodId   id du bien
  * @param iStockId  id du stock
  * @param iYearNumber  année
  * @param iCharacId1..5  id de caractérisation
  * @param iCharac1..5  caractérisation1 à 5
  */
  procedure pSetStartingValues(
    iGoodId     in number
  , iStockId    in number
  , iYearNumber in number
  , iCharacId1  in number
  , iCharacId2  in number
  , iCharacId3  in number
  , iCharacId4  in number
  , iCharacId5  in number
  , iCharac1    in varchar2
  , iCharac2    in varchar2
  , iCharac3    in varchar2
  , iCharac4    in varchar2
  , iCharac5    in varchar2
  )
  is
    lNewStartQuantity STM_ANNUAL_EVOLUTION.SAE_START_QUANTITY%type;
    lNewStartValue    STM_ANNUAL_EVOLUTION.SAE_START_VALUE%type;
  begin
    if iCharac5 is not null then
      -- recherche des quantités début d'après les quantités en fin d'année précédente
      select sum(nvl(sae_start_quantity, 0) ) + sum(nvl(sae_input_quantity, 0) ) - sum(nvl(sae_output_quantity, 0) )
           , sum(nvl(sae_start_value, 0) ) + sum(nvl(sae_input_value, 0) ) - sum(nvl(sae_output_value, 0) )
        into lNewStartQuantity
           , lNewStartValue
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber - 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and gco3_gco_characterization_id = iCharacId4
         and gco4_gco_characterization_id = iCharacId5
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2
         and sae_characterization_value_3 = iCharac3
         and sae_characterization_value_4 = iCharac4
         and sae_characterization_value_5 = iCharac5;

      -- assignation des quantités début
      update stm_annual_evolution
         set sae_start_quantity = nvl(lNewStartQuantity, 0)
           , sae_start_value = nvl(lNewStartValue, 0)
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and gco3_gco_characterization_id = iCharacId4
         and gco4_gco_characterization_id = iCharacId5
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2
         and sae_characterization_value_3 = iCharac3
         and sae_characterization_value_4 = iCharac4
         and sae_characterization_value_5 = iCharac5;
    elsif iCharac4 is not null then
      -- recherche des quantités début d'après les quantités en fin d'année précédente
      select sum(nvl(sae_start_quantity, 0) ) + sum(nvl(sae_input_quantity, 0) ) - sum(nvl(sae_output_quantity, 0) )
           , sum(nvl(sae_start_value, 0) ) + sum(nvl(sae_input_value, 0) ) - sum(nvl(sae_output_value, 0) )
        into lNewStartQuantity
           , lNewStartValue
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber - 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and gco3_gco_characterization_id = iCharacId4
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2
         and sae_characterization_value_3 = iCharac3
         and sae_characterization_value_4 = iCharac4;

      -- assignation des quantités début
      update stm_annual_evolution
         set sae_start_quantity = nvl(lNewStartQuantity, 0)
           , sae_start_value = nvl(lNewStartValue, 0)
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and gco3_gco_characterization_id = iCharacId4
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2
         and sae_characterization_value_3 = iCharac3
         and sae_characterization_value_4 = iCharac4;
    elsif iCharac3 is not null then
      -- recherche des quantités début d'après les quantités en fin d'année précédente
      select sum(nvl(sae_start_quantity, 0) ) + sum(nvl(sae_input_quantity, 0) ) - sum(nvl(sae_output_quantity, 0) )
           , sum(nvl(sae_start_value, 0) ) + sum(nvl(sae_input_value, 0) ) - sum(nvl(sae_output_value, 0) )
        into lNewStartQuantity
           , lNewStartValue
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber - 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2
         and sae_characterization_value_3 = iCharac3;

      -- assignation des quantités début
      update stm_annual_evolution
         set sae_start_quantity = nvl(lNewStartQuantity, 0)
           , sae_start_value = nvl(lNewStartValue, 0)
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and gco2_gco_characterization_id = iCharacId3
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2
         and sae_characterization_value_3 = iCharac3;
    elsif iCharac2 is not null then
      -- recherche des quantités début d'après les quantités en fin d'année précédente
      select sum(nvl(sae_start_quantity, 0) ) + sum(nvl(sae_input_quantity, 0) ) - sum(nvl(sae_output_quantity, 0) )
           , sum(nvl(sae_start_value, 0) ) + sum(nvl(sae_input_value, 0) ) - sum(nvl(sae_output_value, 0) )
        into lNewStartQuantity
           , lNewStartValue
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber - 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2;

      -- assignation des quantités début
      update stm_annual_evolution
         set sae_start_quantity = nvl(lNewStartQuantity, 0)
           , sae_start_value = nvl(lNewStartValue, 0)
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = 1
         and gco_characterization_id = iCharacId1
         and gco_gco_characterization_id = iCharacId2
         and sae_characterization_value_1 = iCharac1
         and sae_characterization_value_2 = iCharac2;
    elsif iCharac1 is not null then
      -- recherche des quantités début d'après les quantités en fin d'année précédente
      select sum(nvl(sae_start_quantity, 0) ) + sum(nvl(sae_input_quantity, 0) ) - sum(nvl(sae_output_quantity, 0) )
           , sum(nvl(sae_start_value, 0) ) + sum(nvl(sae_input_value, 0) ) - sum(nvl(sae_output_value, 0) )
        into lNewStartQuantity
           , lNewStartValue
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber - 1
         and gco_characterization_id = iCharacId1
         and sae_characterization_value_1 = iCharac1;

      -- assignation des quantités début
      update stm_annual_evolution
         set sae_start_quantity = nvl(lNewStartQuantity, 0)
           , sae_start_value = nvl(lNewStartValue, 0)
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = 1
         and gco_characterization_id = iCharacId1
         and sae_characterization_value_1 = iCharac1;
    else
      -- recherche des quantités début d'après les quantités en fin d'année précédente
      select sum(nvl(sae_start_quantity, 0) ) + sum(nvl(sae_input_quantity, 0) ) - sum(nvl(sae_output_quantity, 0) )
           , sum(nvl(sae_start_value, 0) ) + sum(nvl(sae_input_value, 0) ) - sum(nvl(sae_output_value, 0) )
        into lNewStartQuantity
           , lNewStartValue
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber - 1;

      -- assignation des quantités début
      update stm_annual_evolution
         set sae_start_quantity = nvl(lNewStartQuantity, 0)
           , sae_start_value = nvl(lNewStartValue, 0)
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = 1;
    end if;
  end pSetStartingValues;

  /**
  * Function pSeekAnnualEvolutionId
  * Description
  *     Seeks a record for the current year starting with gFirstYear
  *     Loops until current year reaches gLastYear. if no record exist
  *     creates it for each year;
  * @author FP
  * @lastUpdate
  * @param iGoodId   id du bien
  * @param iStockId  id du stock
  * @param iMonthNumber mois
  * @param iYearNumber  année
  * @param charac_id1..5  id de caractérisation
  * @param charac1..5  caractérisation1 à 5
  * @param iCreated : flag indiquant si la fonction a créé l'année dans STM_ANNUAL_EVOLUTION
  * @return id de l'évolution annuelle correspondante
  */
  function pSeekAnnualEvolutionId(
    iGoodId      in     number
  , iStockId     in     number
  , iMonthNumber in     number
  , iYearNumber  in     number
  , iCharacId1   in     number
  , iCharacId2   in     number
  , iCharacId3   in     number
  , iCharacId4   in     number
  , iCharacId5   in     number
  , iCharac1     in     varchar2
  , iCharac2     in     varchar2
  , iCharac3     in     varchar2
  , iCharac4     in     varchar2
  , iCharac5     in     varchar2
  , iCreated     out    number
  )
    return number
  is
    cursor lcurMorphChar(
      iCrCharac_id1 in number
    , iCrCharac_id2 in number
    , iCrCharac_id3 in number
    , iCrCharac_id4 in number
    , iCrCharac_id5 in number
    , iCrCharac1    in varchar2
    , iCrCharac2    in varchar2
    , iCrCharac3    in varchar2
    , iCrCharac4    in varchar2
    , iCrCharac5    in varchar2
    )
    is
      select   1 ordre
             , iCrCharac_id1 GCO_CHARACTERIZATION_ID
             , iCrCharac1 GCO_CHARACTERIZATION_VALUE
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharac_id1
           and C_CHARACT_TYPE in('1', '2')
      union
      select   2 ordre
             , iCrCharac_id2
             , iCrCharac2
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharac_id2
           and C_CHARACT_TYPE in('1', '2')
      union
      select   3 ordre
             , iCrCharac_id3
             , iCrCharac3
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharac_id3
           and C_CHARACT_TYPE in('1', '2')
      union
      select   4 ordre
             , iCrCharac_id4
             , iCrCharac4
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharac_id4
           and C_CHARACT_TYPE in('1', '2')
      union
      select   5 ordre
             , iCrCharac_id5
             , iCrCharac5
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharac_id5
           and C_CHARACT_TYPE in('1', '2')
      order by ordre;

    ltplMorphChar lcurMorphChar%rowtype;
    lTemp         STM_ANNUAL_EVOLUTION.STM_ANNUAL_EVOLUTION_ID%type;
    lBidon        number(1);
    lCharacId1    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId2    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId3    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId4    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId5    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharac1      STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharac2      STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type;
    lCharac3      STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type;
    lCharac4      STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type;
    lCharac5      STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type;
  begin
    if iCharacId1 is not null then
      if PCS.PC_CONFIG.GetBooleanConfig('STM_EVOLUTION_DETAILED') then
        lCharacId1  := iCharacId1;
        lCharacId2  := iCharacId2;
        lCharacId3  := iCharacId3;
        lCharacId4  := iCharacId4;
        lCharacId5  := iCharacId5;
        lCharac1    := iCharac1;
        lCharac2    := iCharac2;
        lCharac3    := iCharac3;
        lCharac4    := iCharac4;
        lCharac5    := iCharac5;
      else
        open lcurMorphChar(iCharacId1, iCharacId2, iCharacId3, iCharacId4, iCharacId5, iCharac1, iCharac2, iCharac3, iCharac4, iCharac5);

        fetch lcurMorphChar
         into ltplMorphChar;

        lCharacId1     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
        lCharac1       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
        ltplMorphChar  := null;

        if lcurMorphChar%found then
          fetch lcurMorphChar
           into ltplMorphChar;

          lCharacId2     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
          lCharac2       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
          ltplMorphChar  := null;

          if lcurMorphChar%found then
            fetch lcurMorphChar
             into ltplMorphChar;

            lCharacId3     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
            lCharac3       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
            ltplMorphChar  := null;

            if lcurMorphChar%found then
              fetch lcurMorphChar
               into ltplMorphChar;

              lCharacId4     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
              lCharac4       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
              ltplMorphChar  := null;

              if lcurMorphChar%found then
                fetch lcurMorphChar
                 into ltplMorphChar;

                lCharacId5     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
                lCharac5       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
                ltplMorphChar  := null;
              end if;
            end if;
          end if;

          close lcurMorphChar;
        end if;
      end if;
    end if;
    if iCharacId1 is not null then
      lCharac1 := nvl(lCharac1, 'N/A');
    end if;
    if iCharacId2 is not null then
      lCharac2 := nvl(lCharac2, 'N/A');
    end if;
    if iCharacId3 is not null then
      lCharac3 := nvl(lCharac3, 'N/A');
    end if;
    if iCharacId4 is not null then
      lCharac4 := nvl(lCharac4, 'N/A');
    end if;
    if iCharacId5 is not null then
      lCharac5 := nvl(lCharac5, 'N/A');
    end if;
    if lCharac5 is not null then
      select max(stm_annual_evolution_id)
        into lTemp
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = iMonthNumber
         and gco_characterization_id = lCharacId1
         and gco_gco_characterization_id = lCharacId2
         and gco2_gco_characterization_id = lCharacId3
         and gco3_gco_characterization_id = lCharacId4
         and gco4_gco_characterization_id = lCharacId5
         and sae_characterization_value_1 = lCharac1
         and sae_characterization_value_2 = lCharac2
         and sae_characterization_value_3 = lCharac3
         and sae_characterization_value_4 = lCharac4
         and sae_characterization_value_5 = lCharac5;
    elsif lCharac4 is not null then
      select max(stm_annual_evolution_id)
        into lTemp
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = iMonthNumber
         and gco_characterization_id = lCharacId1
         and gco_gco_characterization_id = lCharacId2
         and gco2_gco_characterization_id = lCharacId3
         and gco3_gco_characterization_id = lCharacId4
         and sae_characterization_value_1 = lCharac1
         and sae_characterization_value_2 = lCharac2
         and sae_characterization_value_3 = lCharac3
         and sae_characterization_value_4 = lCharac4;
    elsif lCharac3 is not null then
      select max(stm_annual_evolution_id)
        into lTemp
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = iMonthNumber
         and gco_characterization_id = lCharacId1
         and gco_gco_characterization_id = lCharacId2
         and gco2_gco_characterization_id = lCharacId3
         and sae_characterization_value_1 = lCharac1
         and sae_characterization_value_2 = lCharac2
         and sae_characterization_value_3 = lCharac3;
    elsif lCharac2 is not null then
      select max(stm_annual_evolution_id)
        into lTemp
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = iMonthNumber
         and gco_characterization_id = lCharacId1
         and gco_gco_characterization_id = lCharacId2
         and sae_characterization_value_1 = lCharac1
         and sae_characterization_value_2 = lCharac2;
    elsif lCharac1 is not null then
      select max(stm_annual_evolution_id)
        into lTemp
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = iMonthNumber
         and gco_characterization_id = lCharacId1
         and sae_characterization_value_1 = lCharac1;
    else
      select max(stm_annual_evolution_id)
        into lTemp
        from stm_annual_evolution
       where gco_good_id = iGoodId
         and stm_stock_id = iStockId
         and sae_year = iYearNumber
         and sae_month = iMonthNumber;
    end if;

    -- initialisation de la variable de retour Created
    select decode(lTemp, null, 1, 0)
      into iCreated
      from dual;

    if lTemp is null then
      insert into stm_annual_evolution
                  (stm_annual_evolution_id
                 , gco_good_id
                 , stm_stock_id
                 , sae_year
                 , sae_month
                 , gco_characterization_id
                 , gco_gco_characterization_id
                 , gco2_gco_characterization_id
                 , gco3_gco_characterization_id
                 , gco4_gco_characterization_id
                 , sae_characterization_value_1
                 , sae_characterization_value_2
                 , sae_characterization_value_3
                 , sae_characterization_value_4
                 , sae_characterization_value_5
                 , a_datecre
                 , a_idcre
                  )
        select Init_Id_Seq.nextval
             , iGoodId
             , iStockId
             , to_char(iYearNumber)
             , PYM_MONTH
             , lCharacId1
             , lCharacId2
             , lCharacId3
             , lCharacId4
             , lCharacId5
             , lCharac1
             , lCharac2
             , lCharac3
             , lCharac4
             , lCharac5
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from PCS.PC_YEAR_MONTH
         where PYM_YEAR = iYearNumber;

      pSetStartingValues(iGoodId
                       , iStockId
                       , iYearNumber
                       , lCharacId1
                       , lCharacId2
                       , lCharacId3
                       , lCharacId4
                       , lCharacId5
                       , lCharac1
                       , lCharac2
                       , lCharac3
                       , lCharac4
                       , lCharac5
                        );
      lTemp  :=
        pSeekAnnualEvolutionId(iGoodId
                             , iStockId
                             , iMonthNumber
                             , iYearNumber
                             , lCharacId1
                             , lCharacId2
                             , lCharacId3
                             , lCharacId4
                             , lCharacId5
                             , lCharac1
                             , lCharac2
                             , lCharac3
                             , lCharac4
                             , lCharac5
                             , lBidon
                              );
    end if;

    return lTemp;
  end pSeekAnnualEvolutionId;

  /**
  * procedure pInitPeriod
  * initialize the period variables
  * Description
  *    initialize the period variables
  * @author JS
  * @lastUpdate
  */
  procedure pInitPeriod
  is
    ltplExercise stm_exercise%rowtype;
  begin
    iMonthNumber  := to_char(gMvtDate, 'MM');

    -- Use a row to initialize last year and first year values
    select *
      into ltplExercise
      from stm_exercise
     where c_exercise_status = '02';

    gLastMonth    := pMonth(ltplExercise.exe_ending_exercise);
    gLastYear     := pYear(ltplExercise.exe_ending_exercise);
    gFirstMonth   := pMonth(ltplExercise.exe_starting_exercise);
    gFirstYear    := pYear(ltplExercise.exe_starting_exercise);
    gCurrentYear  := gFirstYear;
  end pInitPeriod;

  /**
  * Description
  *   Update exercise and annual evolutions
  */
  procedure updateEvolutions(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
  begin
    updateExerciseEvolution(iotMovementRecord);
    updateAnnualEvolution(iotMovementRecord);
  end updateEvolutions;

  /**
  * Description
  *   Global recalc of both exercise and annual evolutions
  */
  procedure redoEvolutions
  is
  begin
    RedoExerciseEvolution;
    RedoAnnualEvolution;
  end;

  /*
  * Reconstruction des évolution de stock par périodes
  */
  procedure RedoExerciseEvolution
  is
    lIndex          integer;
    ltStockMovement FWK_TYP_STM_ENTITY.tStockMovement;

    cursor lcurStockMovements return FWK_TYP_STM_ENTITY.tStockMovement
    is
      select *
        from STM_STOCK_MOVEMENT;
  begin
    -- Effacement des données d'évolution annuelle
    delete from STM_EXERCISE_EVOLUTION;

    --commit;

    -- Appel de la fonction de mise à jour de l'évolution annuelle
    -- pour chaque mouvement de stock
    open lcurStockMovements;

    lIndex  := 0;

    fetch lcurStockMovements
     into ltStockMovement;

    while lcurStockMovements%found loop
      lIndex  := lIndex + 1;
      updateExerciseEvolution(ltStockMovement);

      -- Tuple suivant
      fetch lcurStockMovements
       into ltStockMovement;

      -- commit toutes les 100 iterrations
      if lIndex = 100 then
        lIndex  := 0;
      --commit;
      end if;
    end loop;

    --commit;
    close lcurStockMovements;
  end RedoExerciseEvolution;

  /*
  * Reconstruction des évolution de stock par périodes
  */
  procedure RedoGoodExerciseEvolution(iGoodId in number)
  is
    ltStockMovement FWK_TYP_STM_ENTITY.tStockMovement;
    lMinDate        date;
    lNumberOfMvt    integer;

    cursor lcurStockMovements(cGoodId number) return FWK_TYP_STM_ENTITY.tStockMovement
    is
      select *
        from STM_STOCK_MOVEMENT
       where GCO_GOOD_ID = cGoodId;
  begin
    -- Effacement des données d'évolution annuelle
    delete from STM_EXERCISE_EVOLUTION
          where GCO_GOOD_ID = iGoodId;

    commit;

    select min(smo_movement_date)
         , count(*)
      into lminDate
         , lNumberOfMvt
      from stm_stock_movement
     where gco_good_id = iGoodId;

    if lNumberOfMvt > 1000 then
      insert into stm_exercise_evolution
                  (STM_exercise_EVOLUTION_ID
                 , STM_EXERCISE_ID
                 , STM_PERIOD_ID
                 , GCO_GOOD_ID
                 , STM_STOCK_ID
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , SPE_CHARACTERIZATION_VALUE_1
                 , SPE_CHARACTERIZATION_VALUE_2
                 , SPE_CHARACTERIZATION_VALUE_3
                 , SPE_CHARACTERIZATION_VALUE_4
                 , SPE_CHARACTERIZATION_VALUE_5
                 , a_datecre
                 , a_idcre
                  )
        select init_id_seq.nextval STM_EXERCISE_EVOLUTION_ID
             , a.*
             , sysdate
             , PCS.PC_I_LIB_SESSION.GETUSERINI
          from (select distinct EXE.STM_EXERCISE_ID
                              , PER.STM_PERIOD_ID
                              , gco_good_id
                              , stm_stock_id
                              , GCO_CHARACTERIZATION_ID
                              , GCO_GCO_CHARACTERIZATION_ID
                              , GCO2_GCO_CHARACTERIZATION_ID
                              , GCO3_GCO_CHARACTERIZATION_ID
                              , GCO4_GCO_CHARACTERIZATION_ID
                              , SMO_CHARACTERIZATION_VALUE_1
                              , SMO_CHARACTERIZATION_VALUE_2
                              , SMO_CHARACTERIZATION_VALUE_3
                              , SMO_CHARACTERIZATION_VALUE_4
                              , SMO_CHARACTERIZATION_VALUE_5
                           from stm_stock_movement
                              , STM_EXERCISE EXE
                              , STM_PERIOD PER
                          where gco_good_id = iGoodId
                            and PER.STM_EXERCISE_ID = EXE.STM_EXERCISE_ID
                            and to_char(EXE.EXE_STARTING_EXERCISE, 'YYYY') between to_char(lMinDate, 'YYYY') and to_char(sysdate, 'YYYY') ) a;

      commit;
    end if;

    -- Appel de la fonction de mise à jour de l'évolution annuelle
    -- pour chaque mouvement de stock
    open lcurStockMovements(iGoodId);

    fetch lcurStockMovements
     into ltStockMovement;

    while lcurStockMovements%found loop
      updateExerciseEvolution(ltStockMovement);

      -- Tuple suivant
      fetch lcurStockMovements
       into ltStockMovement;
    end loop;

    close lcurStockMovements;
  end RedoGoodExerciseEvolution;

  /*
  * Cette procédure met à jour les informations d'évolution périodique de stock d'après un mouvement de stock
  */
  procedure updateExerciseEvolution(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    cursor lcurMorphChar(
      iCrCharacId1 in number
    , iCrCharacId2 in number
    , iCrCharacId3 in number
    , iCrCharacId4 in number
    , iCrCharacId5 in number
    , iCrCharac1   in varchar2
    , iCrCharac2   in varchar2
    , iCrCharac3   in varchar2
    , iCrCharac4   in varchar2
    , iCrCharac5   in varchar2
    )
    is
      select   1 ordre
             , iCrCharacId1 GCO_CHARACTERIZATION_ID
             , iCrCharac1 GCO_CHARACTERIZATION_VALUE
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharacId1
           and C_CHARACT_TYPE in('1', '2')
      union
      select   2 ordre
             , iCrCharacId2
             , iCrCharac2
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharacId2
           and C_CHARACT_TYPE in('1', '2')
      union
      select   3 ordre
             , iCrCharacId3
             , iCrCharac3
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharacId3
           and C_CHARACT_TYPE in('1', '2')
      union
      select   4 ordre
             , iCrCharacId4
             , iCrCharac4
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharacId4
           and C_CHARACT_TYPE in('1', '2')
      union
      select   5 ordre
             , iCrCharacId5
             , iCrCharac5
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCrCharacId5
           and C_CHARACT_TYPE in('1', '2')
      order by ordre;

    ltplMorphChar        lcurMorphChar%rowtype;
    lExerciseEvolutionId STM_EXERCISE_EVOLUTION.STM_EXERCISE_EVOLUTION_ID%type;
    lPeriodNumber        STM_PERIOD.PER_NUMBER%type;
    lRefPeriodNumber     STM_PERIOD.PER_NUMBER%type;
    lMovementSort        STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMovementType        STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lLastPeriod          STM_PERIOD.STM_PERIOD_ID%type;
    lCurrentPeriodId     STM_PERIOD.STM_PERIOD_ID%type;
    lCharacId1           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId2           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId3           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId4           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacId5           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharac1             STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharac2             STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type;
    lCharac3             STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type;
    lCharac4             STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type;
    lCharac5             STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type;
  begin
    if iotMovementRecord.GCO_CHARACTERIZATION_ID is not null then
      if PCS.PC_CONFIG.GetBooleanConfig('STM_EVOLUTION_DETAILED') then
        lCharacId1  := iotMovementRecord.GCO_CHARACTERIZATION_ID;
        lCharac1    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1;
        lCharacId2  := iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID;
        lCharac2    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2;
        lCharacId3  := iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID;
        lCharac3    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3;
        lCharacId4  := iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID;
        lCharac4    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4;
        lCharacId5  := iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID;
        lCharac5    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5;
      else
        open lcurMorphChar(iotMovementRecord.GCO_CHARACTERIZATION_ID
                         , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                         , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                         , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                         , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                         , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                         , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                         , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                         , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                         , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                          );

        fetch lcurMorphChar
         into ltplMorphChar;

        lCharacId1     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
        lCharac1       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
        ltplMorphChar  := null;

        if lcurMorphChar%found then
          fetch lcurMorphChar
           into ltplMorphChar;

          lCharacId2     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
          lCharac2       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
          ltplMorphChar  := null;

          if lcurMorphChar%found then
            fetch lcurMorphChar
             into ltplMorphChar;

            lCharacId3     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
            lCharac3       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
            ltplMorphChar  := null;

            if lcurMorphChar%found then
              fetch lcurMorphChar
               into ltplMorphChar;

              lCharacId4     := ltplMorphChar.GCO_CHARACTERIZATION_ID;
              lCharac4       := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
              ltplMorphChar  := null;

              if lcurMorphChar%found then
                fetch lcurMorphChar
                 into ltplMorphChar;

                lCharacId5  := ltplMorphChar.GCO_CHARACTERIZATION_ID;
                lCharac5    := ltplMorphChar.GCO_CHARACTERIZATION_VALUE;
              end if;
            end if;
          end if;

          close lcurMorphChar;
        end if;
      end if;
    end if;

    -- constante de la dernière période
    select max(per_number)
      into lLastPeriod
      from stm_period
     where stm_exercise_id = iotMovementRecord.STM_EXERCISE_ID;

    -- recherche de l'id de la table STM_EXERCISE_EVOL_MOVEMENT à mettre à jour
    lExerciseEvolutionId  :=
      pSeekExerciseEvolutionId(iotMovementRecord.GCO_GOOD_ID
                             , iotMovementRecord.STM_STOCK_ID
                             , iotMovementRecord.STM_EXERCISE_ID
                             , iotMovementRecord.STM_PERIOD_ID
                             , lCharacId1
                             , lCharacId2
                             , lCharacId3
                             , lCharacId4
                             , lCharacId5
                             , lCharac1
                             , lCharac2
                             , lCharac3
                             , lCharac4
                             , lCharac5
                              );

    -- recherche le numéro de la période active
    select per_number
      into lRefPeriodNumber
      from stm_period
     where stm_period_id = iotMovementRecord.STM_PERIOD_ID;

    -- initialisation du compteur de périodes
    lPeriodNumber         := lRefPeriodNumber;

    -- recherche si on a affaire à une entrée ou une sortie
    select c_movement_sort
         , c_movement_type
      into lMovementSort
         , lMovementType
      from stm_movement_kind
     where stm_movement_kind_id = iotMovementRecord.STM_MOVEMENT_KIND_ID;

    -- Si le mouvement est une entrée
    if lMovementSort = 'ENT' then
      -- mise à jour des valeurs entrée de la période du mouvement
      if lMovementType <> 'EXE' then
        select stm_period_id
          into lCurrentPeriodId
          from STM_PERIOD
         where STM_EXERCISE_ID = iotMovementRecord.STM_EXERCISE_ID
           and PER_NUMBER = lPeriodNumber;

        lExerciseEvolutionId  :=
          pSeekExerciseEvolutionId(iotMovementRecord.GCO_GOOD_ID
                                 , iotMovementRecord.STM_STOCK_ID
                                 , iotMovementRecord.STM_EXERCISE_ID
                                 , lCurrentPeriodId
                                 , lCharacId1
                                 , lCharacId2
                                 , lCharacId3
                                 , lCharacId4
                                 , lCharacId5
                                 , lCharac1
                                 , lCharac2
                                 , lCharac3
                                 , lCharac4
                                 , lCharac5
                                  );

        update stm_exercise_evolution
           set spe_input_quantity = spe_input_quantity + iotMovementRecord.SMO_MOVEMENT_QUANTITY
             , spe_input_value = spe_input_value + iotMovementRecord.SMO_MOVEMENT_PRICE
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where stm_exercise_evolution_id = lExerciseEvolutionId;
      else
        select stm_period_id
          into lCurrentPeriodId
          from STM_PERIOD
         where STM_EXERCISE_ID = iotMovementRecord.STM_EXERCISE_ID
           and PER_NUMBER = 1;

        lExerciseEvolutionId  :=
          pSeekExerciseEvolutionId(iotMovementRecord.GCO_GOOD_ID
                                 , iotMovementRecord.STM_STOCK_ID
                                 , iotMovementRecord.STM_EXERCISE_ID
                                 , lCurrentPeriodId
                                 , lCharacId1
                                 , lCharacId2
                                 , lCharacId3
                                 , lCharacId4
                                 , lCharacId5
                                 , lCharac1
                                 , lCharac2
                                 , lCharac3
                                 , lCharac4
                                 , lCharac5
                                  );

        update stm_exercise_evolution
           set spe_start_quantity = spe_start_quantity + iotMovementRecord.SMO_MOVEMENT_QUANTITY
             , spe_start_value = spe_start_value + iotMovementRecord.SMO_MOVEMENT_PRICE
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where stm_exercise_evolution_id = lExerciseEvolutionId;
      end if;
    else
      -- mise à jour des valeurs de la première période
      -- si le mouvement n'est pas une entrée (sortie)
      -- mise à jour des vals de la première période
      select stm_period_id
        into lCurrentPeriodId
        from STM_PERIOD
       where STM_EXERCISE_ID = iotMovementRecord.STM_EXERCISE_ID
         and PER_NUMBER = lPeriodNumber;

      lExerciseEvolutionId  :=
        pSeekExerciseEvolutionId(iotMovementRecord.GCO_GOOD_ID
                               , iotMovementRecord.STM_STOCK_ID
                               , iotMovementRecord.STM_EXERCISE_ID
                               , lCurrentPeriodId
                               , lCharacId1
                               , lCharacId2
                               , lCharacId3
                               , lCharacId4
                               , lCharacId5
                               , lCharac1
                               , lCharac2
                               , lCharac3
                               , lCharac4
                               , lCharac5
                                );

      update stm_exercise_evolution
         set spe_output_quantity = spe_output_quantity + iotMovementRecord.SMO_MOVEMENT_QUANTITY
           , spe_output_value = spe_output_value + iotMovementRecord.SMO_MOVEMENT_PRICE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where stm_exercise_evolution_id = lExerciseEvolutionId;
    end if;
  end updateExerciseEvolution;

  procedure RedoAnnualEvolution
  is
    cursor lcurStockMovements
    is
      select   *
          from STM_STOCK_MOVEMENT
      order by STM_STOCK_MOVEMENT_ID;

    lIndex integer;
  begin
    -- Effacement des donn‚es d'‚volution annuelle
    delete from STM_ANNUAL_EVOLUTION;

    --commit;
    -- Appel de la fonction de mise à jour de l'évolution annuelle
    -- pour chaque mouvement de stock
    lIndex  := 0;

    for tplStockMovement in lcurStockMovements loop
      lIndex  := lIndex + 1;
      updateAnnualEvolution(tplStockMovement);

      -- Commit tous les 100 enregistrement afin d'éviter une explosion du
      -- rollback segment
      if lIndex = 100 then
        lIndex  := 0;
      --commit;
      end if;
    end loop;
  --Commit;
  end RedoAnnualEvolution;

  procedure RedoGoodAnnualEvolution(iGoodId in number)
  is
    cursor lcurStockMovements(iCrGoodId number)
    is
      select   *
          from STM_STOCK_MOVEMENT
         where GCO_GOOD_ID = iCrGoodId
      order by STM_STOCK_MOVEMENT_ID;

    lIndex       integer;
    lMinDate     date;
    lNumberOfMvt integer;
  begin
    -- Effacement des données d'évolution annuelle
    delete from STM_ANNUAL_EVOLUTION
          where GCO_GOOD_ID = iGoodId;

    commit;

    select min(smo_movement_date)
         , count(*)
      into lminDate
         , lNumberOfMvt
      from stm_stock_movement
     where gco_good_id = iGoodId;

    if lNumberOfMvt > 1000 then
      insert into stm_annual_evolution
                  (STM_ANNUAL_EVOLUTION_ID
                 , SAE_YEAR
                 , SAE_MONTH
                 , GCO_GOOD_ID
                 , STM_STOCK_ID
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , SAE_CHARACTERIZATION_VALUE_1
                 , SAE_CHARACTERIZATION_VALUE_2
                 , SAE_CHARACTERIZATION_VALUE_3
                 , SAE_CHARACTERIZATION_VALUE_4
                 , SAE_CHARACTERIZATION_VALUE_5
                 , a_datecre
                 , a_idcre
                  )
        select init_id_seq.nextval STM_ANNUAL_EVOLUTION_ID
             , a.*
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from (select distinct year.no year_no
                              , month.no month_no
                              , gco_good_id
                              , stm_stock_id
                              , GCO_CHARACTERIZATION_ID
                              , GCO_GCO_CHARACTERIZATION_ID
                              , GCO2_GCO_CHARACTERIZATION_ID
                              , GCO3_GCO_CHARACTERIZATION_ID
                              , GCO4_GCO_CHARACTERIZATION_ID
                              , SMO_CHARACTERIZATION_VALUE_1
                              , SMO_CHARACTERIZATION_VALUE_2
                              , SMO_CHARACTERIZATION_VALUE_3
                              , SMO_CHARACTERIZATION_VALUE_4
                              , SMO_CHARACTERIZATION_VALUE_5
                           from stm_stock_movement
                              , pcs.pc_number month
                              , pcs.pc_number year
                          where gco_good_id = iGoodId
                            and month.no between 1 and 12
                            and year.no between to_number(to_char(lMinDate, 'YYYY') ) and to_number(to_char(sysdate, 'YYYY') ) ) a;

      commit;
    end if;

    -- Appel de la fonction de mise à jour de l'évolution annuelle
    -- pour chaque mouvement de stock
    for tplStockMovement in lcurStockMovements(iGoodId) loop
      lIndex  := lIndex + 1;
      updateAnnualEvolution(tplStockMovement);

      -- Commit tous les 100 enregistrement afin d'éviter une explosion du
      -- rollback segment
      if lIndex = 1000 then
        lIndex  := 0;
        commit;
      end if;
    end loop;

    commit;
  end RedoGoodAnnualEvolution;

  /*
  * Mise à jour des évolutions annuelle selon un mouvement de stock
  */
  procedure updateAnnualEvolution(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lLastMonthYear number(2);
    lMoveYear      number(4);
    lMoveMonth     number(2);
    lTextSql       varchar2(2000);
    lTextPrep      varchar2(2000);
    lMovementType  STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lMovementSort  STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lYearCreated   number(1);
  begin
    -- Traitement uniquement si la gestion des évolutions est activée au niveau de la config
    if PCS.PC_CONFIG.GetBooleanConfig('STM_ANNUAL_EVOLUTION') then
      gMvtDate            := iotMovementRecord.SMO_MOVEMENT_DATE;
      pInitPeriod;
      lMoveYear           := pYear(iotMovementRecord.SMO_MOVEMENT_DATE);
      -- recherche du numéro de mois
      iMonthNumber        := to_char(pMonth(iotMovementRecord.SMO_MOVEMENT_DATE) );
      lMoveMonth          := pMonth(iotMovementRecord.SMO_MOVEMENT_DATE);

      -- recherche si on a affaire à une entrée ou une sortie
      select c_movement_sort
           , c_movement_type
        into lMovementSort
           , lMovementType
        from stm_movement_kind
       where stm_movement_kind_id = iotMovementRecord.STM_MOVEMENT_KIND_ID;

      -- si le mouvement est en entrée, on met à jour les compteurs d'entrée

      -- recherche de l'id et en même temps création des période de l'année du mouvement
      gAnnualEvolutionId  :=
        pSeekAnnualEvolutionId(iotMovementRecord.GCO_GOOD_ID
                             , iotMovementRecord.STM_STOCK_ID
                             , lMoveMonth
                             , lMoveYear
                             , iotMovementRecord.GCO_CHARACTERIZATION_ID
                             , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                             , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                             , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                             , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                             , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                             , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                             , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                             , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                             , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                             , lYearCreated
                              );

      if lMovementSort = 'ENT' then
        -- maj des quantité et valeurs entrée
        update stm_annual_evolution
           set sae_input_quantity = nvl(sae_input_quantity, 0) + iotMovementRecord.SMO_MOVEMENT_QUANTITY
             , sae_input_value = nvl(sae_input_value, 0) + iotMovementRecord.SMO_MOVEMENT_PRICE
             , a_datemod = sysdate
             , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
         where stm_annual_evolution_id = gAnnualEvolutionId
           and lMovementType <> 'EXE';

        -- mise à jour des quantités de débuts des années à venir
        gCurrentYear  := lMoveYear + 1;

        -- boucle sur les années suivant le mouvement jusqu'à l'année de fin de l'exercice actif
        while gCurrentYear <= gLastYear loop
          gAnnualEvolutionId  :=
            pSeekAnnualEvolutionId(iotMovementRecord.GCO_GOOD_ID
                                 , iotMovementRecord.STM_STOCK_ID
                                 , 1
                                 , gCurrentYear
                                 , iotMovementRecord.GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                                 , lYearCreated
                                  );

          -- le cumul est mis à jour seulement si le mouvement n'est pas un report d'exercice et
          -- si le detail de l'année ne vient pas d'être créé
          update stm_annual_evolution
             set sae_start_quantity = sae_start_quantity + iotMovementRecord.SMO_MOVEMENT_QUANTITY
               , sae_start_value = sae_start_value + iotMovementRecord.SMO_MOVEMENT_PRICE
               , a_datemod = sysdate
               , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
           where stm_annual_evolution_id = gAnnualEvolutionId
             and lMovementType <> 'EXE'
             and lYearCreated = 0;

          gCurrentYear        := gCurrentYear + 1;
        end loop;
      -- Mouvements de sortie
      else
        -- maj des quantité et valeurs sorties
        update stm_annual_evolution
           set sae_output_quantity = nvl(sae_output_quantity, 0) + iotMovementRecord.SMO_MOVEMENT_QUANTITY
             , sae_output_value = nvl(sae_output_value, 0) + iotMovementRecord.SMO_MOVEMENT_PRICE
             , a_datemod = sysdate
             , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
         where stm_annual_evolution_id = gAnnualEvolutionId
           and lMovementType <> 'EXE';

        -- mise à jour des quantités de débuts des années à venir
        gCurrentYear  := lMoveYear + 1;

        -- boucle sur les années suivant le mouvement jusqu'à l'année de fin de l'exercice actif
        while gCurrentYear <= gLastYear loop
          gAnnualEvolutionId  :=
            pSeekAnnualEvolutionId(iotMovementRecord.GCO_GOOD_ID
                                 , iotMovementRecord.STM_STOCK_ID
                                 , 1
                                 , gCurrentYear
                                 , iotMovementRecord.GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                                 , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                                 , lYearCreated
                                  );

          -- le cumul est mis à jour seulement si le mouvement n'est pas un report d'exercice et
          -- si le detail de l'année ne vient pas d'être créé
          update stm_annual_evolution
             set sae_start_quantity = nvl(sae_start_quantity, 0) - iotMovementRecord.SMO_MOVEMENT_QUANTITY
               , sae_start_value = nvl(sae_start_value, 0) - iotMovementRecord.SMO_MOVEMENT_PRICE
               , a_datemod = sysdate
               , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
           where stm_annual_evolution_id = gAnnualEvolutionId
             and lMovementType <> 'EXE'
             and lYearCreated = 0;

          gCurrentYear        := gCurrentYear + 1;
        end loop;
      end if;
    end if;
  end updateAnnualEvolution;

  /*
  * Renvoie la quantité solde en tenant compte des caractérisations
  */
  function GetMonthBalanceQty_Char(
    iGoodId                 number
  , iStockId                number
  , iRequestedYear          varchar2
  , iMonth                  number
  , iCharacterizationId1    number
  , iCharacterizationId2    number
  , iCharacterizationId3    number
  , iCharacterizationId4    number
  , iCharacterizationId5    number
  , iCharacterizationValue1 varchar2
  , iCharacterizationValue2 varchar2
  , iCharacterizationValue3 varchar2
  , iCharacterizationValue4 varchar2
  , iCharacterizationValue5 varchar2
  , iTotalizationMode       number
  )
    return number
  is
    lResult   number;
    lStartQty number default 0;
  begin
    -- MODE : 0 solde en fin de mois, 1: solde en début de mois

    -- Solde en début de mois
    if iTotalizationMode = 1 then
      select nvl(max(SAE_START_QUANTITY), 0)
        into lStartQty
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH = 1
         and (     (   gco_characterization_id = iCharacterizationId1
                    or (    iCharacterizationId1 is null
                        and gco_characterization_id is null) )
              and (   gco_gco_characterization_id = iCharacterizationId2
                   or (    iCharacterizationId2 is null
                       and gco_gco_characterization_id is null) )
              and (   gco2_gco_characterization_id = iCharacterizationId3
                   or (    iCharacterizationId3 is null
                       and gco2_gco_characterization_id is null) )
              and (   gco3_gco_characterization_id = iCharacterizationId4
                   or (    iCharacterizationId4 is null
                       and gco3_gco_characterization_id is null) )
              and (   gco4_gco_characterization_id = iCharacterizationId5
                   or (    iCharacterizationId5 is null
                       and gco4_gco_characterization_id is null) )
              and (   sae_characterization_value_1 = iCharacterizationValue1
                   or (    iCharacterizationValue1 is null
                       and sae_characterization_value_1 is null) )
              and (   sae_characterization_value_2 = iCharacterizationValue2
                   or (    iCharacterizationValue2 is null
                       and sae_characterization_value_2 is null) )
              and (   sae_characterization_value_3 = iCharacterizationValue3
                   or (    iCharacterizationValue3 is null
                       and sae_characterization_value_3 is null) )
              and (   sae_characterization_value_4 = iCharacterizationValue4
                   or (    iCharacterizationValue4 is null
                       and sae_characterization_value_4 is null) )
              and (   sae_characterization_value_5 = iCharacterizationValue5
                   or (    iCharacterizationValue5 is null
                       and sae_characterization_value_5 is null) )
             );

      select nvl(sum(nvl(SAE_INPUT_QUANTITY, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_QUANTITY, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth - 1
         and (     (   gco_characterization_id = iCharacterizationId1
                    or (    iCharacterizationId1 is null
                        and gco_characterization_id is null) )
              and (   gco_gco_characterization_id = iCharacterizationId2
                   or (    iCharacterizationId2 is null
                       and gco_gco_characterization_id is null) )
              and (   gco2_gco_characterization_id = iCharacterizationId3
                   or (    iCharacterizationId3 is null
                       and gco2_gco_characterization_id is null) )
              and (   gco3_gco_characterization_id = iCharacterizationId4
                   or (    iCharacterizationId4 is null
                       and gco3_gco_characterization_id is null) )
              and (   gco4_gco_characterization_id = iCharacterizationId5
                   or (    iCharacterizationId5 is null
                       and gco4_gco_characterization_id is null) )
              and (   sae_characterization_value_1 = iCharacterizationValue1
                   or (    iCharacterizationValue1 is null
                       and sae_characterization_value_1 is null) )
              and (   sae_characterization_value_2 = iCharacterizationValue2
                   or (    iCharacterizationValue2 is null
                       and sae_characterization_value_2 is null) )
              and (   sae_characterization_value_3 = iCharacterizationValue3
                   or (    iCharacterizationValue3 is null
                       and sae_characterization_value_3 is null) )
              and (   sae_characterization_value_4 = iCharacterizationValue4
                   or (    iCharacterizationValue4 is null
                       and sae_characterization_value_4 is null) )
              and (   sae_characterization_value_5 = iCharacterizationValue5
                   or (    iCharacterizationValue5 is null
                       and sae_characterization_value_5 is null) )
             );

      lResult  := lStartQty + lResult;
    -- Solde en fin de mois
    else
      select nvl(sum(nvl(SAE_START_QUANTITY, 0) ), 0) + nvl(sum(nvl(SAE_INPUT_QUANTITY, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_QUANTITY, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth
         and (     (   gco_characterization_id = iCharacterizationId1
                    or (    iCharacterizationId1 is null
                        and gco_characterization_id is null) )
              and (   gco_gco_characterization_id = iCharacterizationId2
                   or (    iCharacterizationId2 is null
                       and gco_gco_characterization_id is null) )
              and (   gco2_gco_characterization_id = iCharacterizationId3
                   or (    iCharacterizationId3 is null
                       and gco2_gco_characterization_id is null) )
              and (   gco3_gco_characterization_id = iCharacterizationId4
                   or (    iCharacterizationId4 is null
                       and gco3_gco_characterization_id is null) )
              and (   gco4_gco_characterization_id = iCharacterizationId5
                   or (    iCharacterizationId5 is null
                       and gco4_gco_characterization_id is null) )
              and (   sae_characterization_value_1 = iCharacterizationValue1
                   or (    iCharacterizationValue1 is null
                       and sae_characterization_value_1 is null) )
              and (   sae_characterization_value_2 = iCharacterizationValue2
                   or (    iCharacterizationValue2 is null
                       and sae_characterization_value_2 is null) )
              and (   sae_characterization_value_3 = iCharacterizationValue3
                   or (    iCharacterizationValue3 is null
                       and sae_characterization_value_3 is null) )
              and (   sae_characterization_value_4 = iCharacterizationValue4
                   or (    iCharacterizationValue4 is null
                       and sae_characterization_value_4 is null) )
              and (   sae_characterization_value_5 = iCharacterizationValue5
                   or (    iCharacterizationValue5 is null
                       and sae_characterization_value_5 is null) )
             );
    end if;

    return lResult;
  end GetMonthBalanceQty_Char;

  /*
  * Renvoie la quantité solde sans tenir compte des caractérisations
  */
  function GetMonthBalanceQty_NoChar(iGoodId number, iStockId number, iRequestedYear varchar2, iMonth number, iTotalizationMode number)
    return number
  is
    lResult   number;
    lStartQty number default 0;
  begin
    -- MODE : 0 solde en fin de mois, 1: solde en début de mois

    -- Solde en début de mois
    if iTotalizationMode = 1 then
      select nvl(sum(nvl(SAE_START_QUANTITY, 0) ), 0)
        into lStartQty
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH = 1;

      select nvl(sum(nvl(SAE_INPUT_QUANTITY, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_QUANTITY, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth - 1;

      lResult  := lStartQty + lResult;
    -- Solde en fin de mois
    else
      select nvl(sum(nvl(SAE_START_QUANTITY, 0) ), 0) + nvl(sum(nvl(SAE_INPUT_QUANTITY, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_QUANTITY, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth;
    end if;

    return lResult;
  end GetMonthBalanceQty_NoChar;

  /*
  * Renvoie la quantité solde en tenant compte des caractérisations
  */
  function GetMonthBalanceValue_Char(
    iGoodId                 number
  , iStockId                number
  , iRequestedYear          varchar2
  , iMonth                  number
  , iCharacterizationId1    number
  , iCharacterizationId2    number
  , iCharacterizationId3    number
  , iCharacterizationId4    number
  , iCharacterizationId5    number
  , iCharacterizationValue1 varchar2
  , iCharacterizationValue2 varchar2
  , iCharacterizationValue3 varchar2
  , iCharacterizationValue4 varchar2
  , iCharacterizationValue5 varchar2
  , iTotalizationMode       number
  )
    return number
  is
    lResult     number;
    lStartValue number default 0;
  begin
    -- MODE : 0 solde en fin de mois, 1: solde en début de mois

    -- Solde en début de mois
    if iTotalizationMode = 1 then
      select nvl(max(SAE_START_VALUE), 0)
        into lStartValue
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH = 1
         and (     (   gco_characterization_id = iCharacterizationId1
                    or (    iCharacterizationId1 is null
                        and gco_characterization_id is null) )
              and (   gco_gco_characterization_id = iCharacterizationId2
                   or (    iCharacterizationId2 is null
                       and gco_gco_characterization_id is null) )
              and (   gco2_gco_characterization_id = iCharacterizationId3
                   or (    iCharacterizationId3 is null
                       and gco2_gco_characterization_id is null) )
              and (   gco3_gco_characterization_id = iCharacterizationId4
                   or (    iCharacterizationId4 is null
                       and gco3_gco_characterization_id is null) )
              and (   gco4_gco_characterization_id = iCharacterizationId5
                   or (    iCharacterizationId5 is null
                       and gco4_gco_characterization_id is null) )
              and (   sae_characterization_value_1 = iCharacterizationValue1
                   or (    iCharacterizationValue1 is null
                       and sae_characterization_value_1 is null) )
              and (   sae_characterization_value_2 = iCharacterizationValue2
                   or (    iCharacterizationValue2 is null
                       and sae_characterization_value_2 is null) )
              and (   sae_characterization_value_3 = iCharacterizationValue3
                   or (    iCharacterizationValue3 is null
                       and sae_characterization_value_3 is null) )
              and (   sae_characterization_value_4 = iCharacterizationValue4
                   or (    iCharacterizationValue4 is null
                       and sae_characterization_value_4 is null) )
              and (   sae_characterization_value_5 = iCharacterizationValue5
                   or (    iCharacterizationValue5 is null
                       and sae_characterization_value_5 is null) )
             );

      select nvl(sum(nvl(SAE_INPUT_VALUE, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_VALUE, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth - 1
         and (     (   gco_characterization_id = iCharacterizationId1
                    or (    iCharacterizationId1 is null
                        and gco_characterization_id is null) )
              and (   gco_gco_characterization_id = iCharacterizationId2
                   or (    iCharacterizationId2 is null
                       and gco_gco_characterization_id is null) )
              and (   gco2_gco_characterization_id = iCharacterizationId3
                   or (    iCharacterizationId3 is null
                       and gco2_gco_characterization_id is null) )
              and (   gco3_gco_characterization_id = iCharacterizationId4
                   or (    iCharacterizationId4 is null
                       and gco3_gco_characterization_id is null) )
              and (   gco4_gco_characterization_id = iCharacterizationId5
                   or (    iCharacterizationId5 is null
                       and gco4_gco_characterization_id is null) )
              and (   sae_characterization_value_1 = iCharacterizationValue1
                   or (    iCharacterizationValue1 is null
                       and sae_characterization_value_1 is null) )
              and (   sae_characterization_value_2 = iCharacterizationValue2
                   or (    iCharacterizationValue2 is null
                       and sae_characterization_value_2 is null) )
              and (   sae_characterization_value_3 = iCharacterizationValue3
                   or (    iCharacterizationValue3 is null
                       and sae_characterization_value_3 is null) )
              and (   sae_characterization_value_4 = iCharacterizationValue4
                   or (    iCharacterizationValue4 is null
                       and sae_characterization_value_4 is null) )
              and (   sae_characterization_value_5 = iCharacterizationValue5
                   or (    iCharacterizationValue5 is null
                       and sae_characterization_value_5 is null) )
             );

      lResult  := lStartValue + lResult;
    -- Solde en fin de mois
    else
      select nvl(sum(nvl(SAE_START_VALUE, 0) ), 0) + nvl(sum(nvl(SAE_INPUT_VALUE, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_VALUE, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth
         and (     (   gco_characterization_id = iCharacterizationId1
                    or (    iCharacterizationId1 is null
                        and gco_characterization_id is null) )
              and (   gco_gco_characterization_id = iCharacterizationId2
                   or (    iCharacterizationId2 is null
                       and gco_gco_characterization_id is null) )
              and (   gco2_gco_characterization_id = iCharacterizationId3
                   or (    iCharacterizationId3 is null
                       and gco2_gco_characterization_id is null) )
              and (   gco3_gco_characterization_id = iCharacterizationId4
                   or (    iCharacterizationId4 is null
                       and gco3_gco_characterization_id is null) )
              and (   gco4_gco_characterization_id = iCharacterizationId5
                   or (    iCharacterizationId5 is null
                       and gco4_gco_characterization_id is null) )
              and (   sae_characterization_value_1 = iCharacterizationValue1
                   or (    iCharacterizationValue1 is null
                       and sae_characterization_value_1 is null) )
              and (   sae_characterization_value_2 = iCharacterizationValue2
                   or (    iCharacterizationValue2 is null
                       and sae_characterization_value_2 is null) )
              and (   sae_characterization_value_3 = iCharacterizationValue3
                   or (    iCharacterizationValue3 is null
                       and sae_characterization_value_3 is null) )
              and (   sae_characterization_value_4 = iCharacterizationValue4
                   or (    iCharacterizationValue4 is null
                       and sae_characterization_value_4 is null) )
              and (   sae_characterization_value_5 = iCharacterizationValue5
                   or (    iCharacterizationValue5 is null
                       and sae_characterization_value_5 is null) )
             );
    end if;

    return lResult;
  end GetMonthBalanceValue_Char;

  /*
  * Renvoie la quantité solde sans tenir compte des caractérisations
  */
  function GetMonthBalanceValue_NoChar(iGoodId number, iStockId number, iRequestedYear varchar2, iMonth number, iTotalizationMode number)
    return number
  is
    lResult     number;
    lStartValue number default 0;
  begin
    -- MODE : 0 solde en fin de mois, 1: solde en début de mois

    -- Solde en début de mois
    if iTotalizationMode = 1 then
      select nvl(sum(nvl(SAE_START_VALUE, 0) ), 0)
        into lStartValue
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH = 1;

      select nvl(sum(nvl(SAE_INPUT_VALUE, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_VALUE, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth - 1;

      lResult  := lStartValue + lResult;
    -- Solde en fin de mois
    else
      select nvl(sum(nvl(SAE_START_VALUE, 0) ), 0) + nvl(sum(nvl(SAE_INPUT_VALUE, 0) ), 0) - nvl(sum(nvl(SAE_OUTPUT_VALUE, 0) ), 0)
        into lResult
        from STM_ANNUAL_EVOLUTION
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and SAE_YEAR = iRequestedYear
         and SAE_MONTH <= iMonth;
    end if;

    return lResult;
  end GetMonthBalanceValue_NoChar;
end STM_PRC_STOCK_EVOLUTION;
