--------------------------------------------------------
--  DDL for Package Body PTC_COSTPRICE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_COSTPRICE" 
is
  /**
  * Description
  *    Mise a jour du prix de revient passé en paramètre
  */
  procedure Calc1ManCostPrice(CALC_COSTPRICE_ID in number, GOOD_ID in number)
  is
    Movement_Sort     STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    Movement_Quantity STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    Movement_Value    STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    Movement_Sign     number(1);
    Old_Quantity      STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    Old_Value         STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    Exercise_ID       STM_EXERCISE.STM_EXERCISE_ID%type;

    -- Curseur sur tous les mouvemnts de stock à prendre en compte
    -- dans la mise à jour du prix de revient
    cursor MOVEMENTs_PRICE(idPRICE number, idGOOD number, idEXERCISE number)
    is
      select C_MOVEMENT_SORT
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_PRICE
           , MOK_STANDARD_SIGN
        from STM_STOCK_MOVEMENT
           , STM_MOVEMENT_KIND
       where GCO_GOOD_ID = idGOOD
         and STM_STOCK_MOVEMENT.STM_MOVEMENT_KIND_ID = STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID
         and STM_STOCK_MOVEMENT.STM_EXERCISE_ID = idEXERCISE
         and STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID in(
                                    select STM_MOVEMENT_KIND_ID
                                      from PTC_PRC_S_STOCK_MVT A
                                         , PTC_CALC_COSTPRICE B
                                     where B.PTC_CALC_COSTPRICE_ID = idPrice
                                       and A.PTC_CALC_COSTPRICE_ID = B.PTC_CALC_COSTPRICE_ID
                                       and C_COSTPRICE_STATUS = 'ACT');
  begin
    -- Recherche de l'ID de l'exercice actif
    select STM_EXERCISE_ID
      into Exercise_Id
      from STM_EXERCISE
     where C_EXERCISE_STATUS = '02';

    -- Remise a zero des compteurs
    update PTC_CALC_COSTPRICE
       set CCP_ADDED_QUANTITY = 0
         , CCP_ADDED_VALUE = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where PTC_CALC_COSTPRICE_ID = CALC_COSTPRICE_ID
       and C_COSTPRICE_STATUS = 'ACT';

    -- Ouverture du curseur sur les mouvements a traiter
    open MOVEMENTs_PRICE(CALC_COSTPRICE_ID, GOOD_ID, Exercise_ID);

    -- Valeurs du premier mouvement
    fetch MOVEMENTs_PRICE
     into Movement_Sort
        , Movement_Quantity
        , Movement_Value
        , Movement_Sign;

    while MOVEMENTs_PRICE%found loop
      -- Recherche du signe arithmétique du mouvement
      if Movement_Sort = 'SOR' then
        Movement_Sign  := -1 * Movement_Sign;
      end if;

      -- Recherche des anciennes valeurs cumulées
      select CCP_ADDED_QUANTITY
           , CCP_ADDED_VALUE
        into Old_Quantity
           , Old_Value
        from PTC_CALC_COSTPRICE
       where PTC_CALC_COSTPRICE_ID = CALC_COSTPRICE_ID;

      -- test pour eviter une division par zero
      if (Old_Quantity + Movement_Sign * Movement_Quantity = 0) then
        update PTC_CALC_COSTPRICE
           set CCP_ADDED_VALUE = Old_Value + Movement_Sign * Movement_Value
             , CCP_ADDED_QUANTITY = 0
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PTC_CALC_COSTPRICE_ID = CALC_COSTPRICE_ID;
      else
        update PTC_CALC_COSTPRICE
           set CCP_ADDED_VALUE = Old_Value + Movement_Sign * Movement_Value
             , CCP_ADDED_QUANTITY = Old_Quantity + Movement_Sign * Movement_Quantity
             , CPR_PRICE = (Old_Value + Movement_Sign * Movement_Value) /(Old_Quantity + Movement_Sign * Movement_Quantity)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PTC_CALC_COSTPRICE_ID = CALC_COSTPRICE_ID;
      end if;

      -- Valeurs du mouvement suivant
      fetch MOVEMENTs_PRICE
       into Movement_Sort
          , Movement_Quantity
          , Movement_Value
          , Movement_Sign;
    end loop;
  end Calc1ManCostPrice;

  /**
  * Description
  *   Mise a jour de tous les prix de revient dont le cycle de mise à jour est manuel
  */
  procedure UpdateAllManualCostPrice
  is
    -- variables
    Good_Id           GCO_GOOD.GCO_GOOD_ID%type;
    Calc_CostPrice_Id PTC_CALC_COSTPRICE.PTC_CALC_COSTPRICE_ID%type;
    Exercise_Id       STM_EXERCISE.STM_EXERCISE_ID%type;

    -- Curseur sur tous les prix de revient qui doivent ˆtre mis à jour
    cursor MAN_COSTPRICES
    is
      select PTC_CALC_COSTPRICE_ID
           , GCO_GOOD_ID
        from PTC_CALC_COSTPRICE
       where C_UPDATE_CYCLE = 'MAN'
         and C_COSTPRICE_STATUS = 'ACT';
  begin
    -- Ouverture du curseur
    open MAN_COSTPRICES;

    -- Positionnement sur le premier prix de revient manuel
    fetch MAN_COSTPRICES
     into Calc_Costprice_Id
        , Good_ID;

    -- Pour tous les prix 'Manuels'
    while MAN_COSTPRICES%found loop
      -- Appel de la mise à jour unitaire pour chaque prix
      Calc1ManCostPrice(Calc_CostPrice_Id, Good_Id);

      -- Positionnement sur le prochain prix de revient manuel
      fetch MAN_COSTPRICES
       into Calc_Costprice_Id
          , Good_ID;
    end loop;
  end UpdateAllManualCostPrice;

  /*
  * Mise à jour des prix dont le réajustement se fait sur l'ouverture des exercices
  */
  procedure UpdateAllExPerCostPrice(UPDATE_CYCLE varchar2)
  is
    costprice_id PTC_CALC_COSTPRICE.PTC_CALC_COSTPRICE_ID%type;

    cursor EXERCISE_COSTPRICE(cycle varchar2)
    is
      select PTC_CALC_COSTPRICE_ID
        from PTC_CALC_COSTPRICE
       where C_UPDATE_CYCLE = cycle
         and C_COSTPRICE_STATUS = 'ACT';
  begin
    -- ouverture du curseur sur les prix de revient
    open EXERCISE_COSTPRICE(UPDATE_CYCLE);

    -- positionnement sur le premier prix de revient
    fetch EXERCISE_COSTPRICE
     into costprice_id;

    -- tant que l'on est pas en fin de table on met a jour les prix
    while EXERCISE_COSTPRICE%found loop
      resetCostprice(costprice_id);

      fetch EXERCISE_COSTPRICE
       into costprice_id;
    end loop;
  end UpdateAllExPerCostPrice;

  /*
  * Réinitialisation du prix de revient calculé lors du réajustement
  */
  procedure resetCostprice(costprice_id in number)
  is
    total_update   number(1);
    total_quantity ptc_calc_costprice.ccp_added_quantity%type;
    good_id        gco_good.gco_good_id%type;
  begin
    -- recherche du type de réajustement
    select ccp_total_update
         , gco_good_id
      into total_update
         , good_id
      from ptc_calc_costprice
     where ptc_calc_costprice_id = costprice_id;

    if total_update = 1 then
      -- Réajustement complet
      -- mise à jour d'après les compteurs de stocks pris en compte pour le réajustement
      select nvl(sum(spo_available_quantity), 0)
        into total_quantity
        from stm_stock_position spo
           , stm_stock stk
       where spo.gco_good_id = good_id
         and spo.stm_stock_id = stk.stm_stock_id
         and stk.sto_costprice_reset = 1;

      update ptc_calc_costprice
         set ccp_added_quantity = total_quantity
           , ccp_added_value = total_quantity * cpr_price
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where ptc_calc_costprice_id = costprice_id;
    else
      -- mise à zéro des quantités et valeurs cumulées
      update ptc_calc_costprice
         set ccp_added_quantity = 0
           , ccp_added_value = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where ptc_calc_costprice_id = costprice_id;
    end if;
  end resetCostprice;

  /**
  * Description
  *   Initialisation des prix lors de leur création
  */
  procedure InitCostPrice(COSTPRICE_ID in number, GOOD_ID in number, UPDATE_CYCLE in varchar2)
  is
    Exercise_ID       STM_EXERCISE.STM_EXERCISE_ID%type;
    Period_ID         STM_PERIOD.STM_PERIOD_ID%type;
    Movement_Sort     STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    Movement_Quantity STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    Movement_Value    STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    Movement_Sign     number(1);
    Old_Quantity      STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    Old_Value         STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;

    -- Curseur sur tous les mouvemnts de stock à prendre en compte
    -- dans la mise à jour du prix de revient en mode exercice
    cursor MOVEMENT_EXER_PRICE(idPRICE number, idGOOD number, idEXERCISE number)
    is
      select C_MOVEMENT_SORT
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_PRICE
           , MOK_STANDARD_SIGN
        from STM_STOCK_MOVEMENT
           , STM_MOVEMENT_KIND
       where GCO_GOOD_ID = idGOOD
         and STM_STOCK_MOVEMENT.STM_MOVEMENT_KIND_ID = STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID
         and STM_STOCK_MOVEMENT.STM_EXERCISE_ID = idEXERCISE
         and STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID in(
                                    select STM_MOVEMENT_KIND_ID
                                      from PTC_PRC_S_STOCK_MVT A
                                         , PTC_CALC_COSTPRICE B
                                     where B.PTC_CALC_COSTPRICE_ID = idPrice
                                       and A.PTC_CALC_COSTPRICE_ID = B.PTC_CALC_COSTPRICE_ID
                                       and C_COSTPRICE_STATUS = 'ACT');

    -- Curseur sur tous les mouvemnts de stock à prendre en compte
    -- dans la mise à jour du prix de revient en mode periodes
    cursor MOVEMENT_PER_PRICE(idPRICE number, idGOOD number, idPERIOD number)
    is
      select C_MOVEMENT_SORT
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_PRICE
           , MOK_STANDARD_SIGN
        from STM_STOCK_MOVEMENT
           , STM_MOVEMENT_KIND
       where GCO_GOOD_ID = idGOOD
         and STM_STOCK_MOVEMENT.STM_MOVEMENT_KIND_ID = STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID
         and STM_STOCK_MOVEMENT.STM_PERIOD_ID = idPERIOD
         and STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID in(
                                    select STM_MOVEMENT_KIND_ID
                                      from PTC_PRC_S_STOCK_MVT A
                                         , PTC_CALC_COSTPRICE B
                                     where B.PTC_CALC_COSTPRICE_ID = idPrice
                                       and A.PTC_CALC_COSTPRICE_ID = B.PTC_CALC_COSTPRICE_ID
                                       and C_COSTPRICE_STATUS = 'ACT');

    cursor LAST_MOVE_CURSOR(idGOOD number, idCOSTPRICE number)
    is
      select C_MOVEMENT_SORT
           , SMO_MOVEMENT_QUANTITY
           , SMO_MOVEMENT_PRICE
           , MOK_STANDARD_SIGN
        from STM_STOCK_MOVEMENT
           , STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID = STM_STOCK_MOVEMENT.STM_MOVEMENT_KIND_ID
         and STM_STOCK_MOVEMENT_ID =
               (select max(STM_STOCK_MOVEMENT_ID)
                  from STM_STOCK_MOVEMENT
                     , STM_MOVEMENT_KIND
                 where GCO_GOOD_ID = idGOOD
                   and STM_STOCK_MOVEMENT.STM_MOVEMENT_KIND_ID = STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID
                   and STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID in(
                                select STM_MOVEMENT_KIND_ID
                                  from PTC_PRC_S_STOCK_MVT A
                                     , PTC_CALC_COSTPRICE B
                                 where B.PTC_CALC_COSTPRICE_ID = idCOSTPRICE
                                   and A.PTC_CALC_COSTPRICE_ID = B.PTC_CALC_COSTPRICE_ID
                                   and C_COSTPRICE_STATUS = 'ACT') );
  begin
    if UPDATE_CYCLE = 'EXE' then
      -- Recherche de l'ID de l'exercice actif
      select STM_EXERCISE_ID
        into Exercise_Id
        from STM_EXERCISE
       where C_EXERCISE_STATUS = '02';

      -- ouverture du curseur des mouvements
      open MOVEMENT_EXER_PRICE(COSTPRICE_ID, GOOD_ID, Exercise_id);

      -- Valeurs du premier mouvement
      fetch MOVEMENT_EXER_PRICE
       into Movement_Sort
          , Movement_Quantity
          , Movement_Value
          , Movement_Sign;

      -- remise à 0 des compteurs
      update PTC_CALC_COSTPRICE
         set CCP_ADDED_VALUE = 0
           , CCP_ADDED_QUANTITY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
         and C_COSTPRICE_STATUS = 'ACT';

      while MOVEMENT_EXER_PRICE%found loop
        -- Recherche du signe arithmétique du mouvement
        if Movement_Sort = 'SOR' then
          Movement_Sign  := -1 * Movement_Sign;
        end if;

        -- Recherche des anciennes valeurs cumulées
        select CCP_ADDED_QUANTITY
             , CCP_ADDED_VALUE
          into Old_Quantity
             , Old_Value
          from PTC_CALC_COSTPRICE
         where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID;

        -- test pour eviter une division par zero
        if (Old_Quantity + Movement_Sign * Movement_Quantity = 0) then
          update PTC_CALC_COSTPRICE
             set CCP_ADDED_VALUE = Old_Value + Movement_Sign * Movement_Value
               , CCP_ADDED_QUANTITY = 0
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
             and C_COSTPRICE_STATUS = 'ACT';
        else
          update PTC_CALC_COSTPRICE
             set CCP_ADDED_VALUE = Old_Value + Movement_Sign * Movement_Value
               , CCP_ADDED_QUANTITY = Old_Quantity + Movement_Sign * Movement_Quantity
               , CPR_PRICE = (Old_Value + Movement_Sign * Movement_Value) /(Old_Quantity + Movement_Sign * Movement_Quantity)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
             and C_COSTPRICE_STATUS = 'ACT';
        end if;

        -- Valeurs du mouvement suivant
        fetch MOVEMENT_EXER_PRICE
         into Movement_Sort
            , Movement_Quantity
            , Movement_Value
            , Movement_Sign;
      end loop;
    elsif UPDATE_CYCLE = 'PER' then
      -- Recherche de l'ID de l'exercice actif
      select STM_PERIOD_ID
        into Period_Id
        from STM_PERIOD
       where C_PERIOD_STATUS = '02'
         and STM_EXERCISE_ID = (select STM_EXERCISE_ID
                                  from STM_EXERCISE
                                 where C_EXERCISE_STATUS = '02');

      -- ouverture du curseur des mouvements
      open MOVEMENT_PER_PRICE(COSTPRICE_ID, GOOD_ID, Period_id);

      -- Valeurs du premier mouvement
      fetch MOVEMENT_PER_PRICE
       into Movement_Sort
          , Movement_Quantity
          , Movement_Value
          , Movement_Sign;

      -- remise à zero des compteurs
      update PTC_CALC_COSTPRICE
         set CCP_ADDED_VALUE = 0
           , CCP_ADDED_QUANTITY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
         and C_COSTPRICE_STATUS = 'ACT';

      while MOVEMENT_PER_PRICE%found loop
        -- Recherche du signe arithmétique du mouvement
        if Movement_Sort = 'SOR' then
          Movement_Sign  := -1 * Movement_Sign;
        end if;

        -- Recherche des anciennes valeurs cumulées
        select CCP_ADDED_QUANTITY
             , CCP_ADDED_VALUE
          into Old_Quantity
             , Old_Value
          from PTC_CALC_COSTPRICE
         where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
           and C_CoSTPRICE_STATUS = 'ACT';

        -- test pour eviter une division par zero
        if (Old_Quantity + Movement_Sign * Movement_Quantity = 0) then
          update PTC_CALC_COSTPRICE
             set CCP_ADDED_VALUE = Old_Value + Movement_Sign * Movement_Value
               , CCP_ADDED_QUANTITY = 0
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
             and C_COSTPRICE_STATUS = 'ACT';
        else
          update PTC_CALC_COSTPRICE
             set CCP_ADDED_VALUE = Old_Value + Movement_Sign * Movement_Value
               , CCP_ADDED_QUANTITY = Old_Quantity + Movement_Sign * Movement_Quantity
               , CPR_PRICE = (Old_Value + Movement_Sign * Movement_Value) /(Old_Quantity + Movement_Sign * Movement_Quantity)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
             and C_COSTPRICE_STATUS = 'ACT';
        end if;

        -- Valeurs du mouvement suivant
        fetch MOVEMENT_PER_PRICE
         into Movement_Sort
            , Movement_Quantity
            , Movement_Value
            , Movement_Sign;
      end loop;
    elsif UPDATE_CYCLE = 'SYS' then
      -- recherche des caractéristiques du dernier mouvement
      open Last_Move_Cursor(GOOD_ID, COSTPRICE_ID);

      fetch Last_Move_Cursor
       into Movement_Sort
          , Movement_Quantity
          , Movement_Value
          , Movement_Sign;

      -- Si il y a un dernier mouvement: mise à jour des compteurs
      if Last_Move_Cursor%notfound then
        Movement_Sort      := 'ENT';
        Movement_Quantity  := 0;
        Movement_Value     := 0;
        Movement_Sign      := 1;
      end if;

      -- Recherche du signe arithmétique du mouvement
      if Movement_Sort = 'SOR' then
        Movement_Sign  := -1 * Movement_Sign;
      end if;

      -- Mise à jour du prix de revient
      if Movement_Quantity <> 0 then
        update PTC_CALC_COSTPRICE
           set CCP_ADDED_VALUE = Movement_Sign * Movement_Value
             , CCP_ADDED_QUANTITY = Movement_Sign * Movement_Quantity
             , CPR_PRICE = (Movement_Sign * Movement_Value) /(Movement_Sign * Movement_Quantity)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
           and C_COSTPRICE_STATUS = 'ACT';
      else
        update PTC_CALC_COSTPRICE
           set CCP_ADDED_VALUE = Movement_Sign * Movement_Value
             , CCP_ADDED_QUANTITY = Movement_Sign * Movement_Quantity
             , CPR_PRICE = 0
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PTC_CALC_COSTPRICE_ID = COSTPRICE_ID
           and C_COSTPRICE_STATUS = 'ACT';
      end if;
    end if;
  end InitCostPrice;

  /**
  * Description
  *   Création d'un mouvement de correction lors de la modification du PRF par défaut
  *   d'un bien géré avec inventaire permanent
  */
  procedure GenPRFCorrectionMove(GOOD_ID in number, DIFF in number)
  is
    continuous_inventar  number(1);
    movement_kind_id     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    exercise_id          STM_EXERCISE.STM_EXERCISE_ID%type;
    period_id            STM_PERIOD.STM_PERIOD_ID%type;
    move_price           STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    move_date            date;
    financialCharging    STM_STOCK_MOVEMENT.SMO_FINANCIAL_CHARGING%type;

    -- curseur sur toutes les positions de stock liées au bien
    cursor stock_position(good_id number)
    is
      select STM_STOCK_ID
           , GCO_CHARACTERIZATION_ID
           , GCO_GCO_CHARACTERIZATION_ID
           , GCO2_GCO_CHARACTERIZATION_ID
           , GCO3_GCO_CHARACTERIZATION_ID
           , GCO4_GCO_CHARACTERIZATION_ID
           , SPO_CHARACTERIZATION_VALUE_1
           , SPO_CHARACTERIZATION_VALUE_2
           , SPO_CHARACTERIZATION_VALUE_3
           , SPO_CHARACTERIZATION_VALUE_4
           , SPO_CHARACTERIZATION_VALUE_5
           , SPO_STOCK_QUANTITY
        from STM_STOCK_POSITION
       where GCO_GOOD_ID = good_id
         and SPO_STOCK_QUANTITY <> 0;

    stock_position_tuple stock_position%rowtype;
  begin
    -- recherche du mode d'inventaire si le produit est gêré au PRF
    select max(PDT_CONTINUOUS_INVENTAR)
      into continuous_inventar
      from GCO_PRODUCT
         , GCO_GOOD
     where GCO_PRODUCT.GCO_GOOD_ID = GOOD_ID
       and GCO_GOOD.GCO_GOOD_ID = GCO_PRODUCT.GCO_GOOD_ID
       and C_MANAGEMENT_MODE = '3';

    -- si on a la gestion d'inventaire
    if continuous_inventar = 1 then
      -- recherche de l'exercice actif
      select STM_EXERCISE_ID
        into exercise_id
        from STM_EXERCISE
       where C_EXERCISE_STATUS = '02';

      -- recherche de la période active de l'exercice actif
      select STM_PERIOD_ID
        into period_id
        from STM_PERIOD
       where C_PERIOD_STATUS = '02'
         and STM_EXERCISE_ID = exercise_id;

      -- définition de la date du mouvement
      -- si la date du jour est dans la période active, alors date du jour
      select max(sysdate)
        into move_date
        from STM_PERIOD
       where STM_PERIOD_ID = period_id
         and sysdate between PER_STARTING_PERIOD and PER_ENDING_PERIOD + 0.99999;

      -- si la date du jour n'est pas dans la période active, on prend la
      -- date début de période si la date du jour est inférieure à la date début de la période active
      if move_date is null then
        select max(PER_STARTING_PERIOD)
          into move_date
          from STM_PERIOD
         where STM_PERIOD_ID = period_id
           and sysdate < PER_STARTING_PERIOD;

        -- autrement, on prend la date de fin
        if move_date is null then
          select max(PER_ENDING_PERIOD)
            into move_date
            from STM_PERIOD
           where STM_PERIOD_ID = period_id;
        end if;
      end if;

      -- recherche du type de mouvement selon que ce soit une entrée ou une sortie
      if DIFF > 0 then
        -- mouvement d'entrée
        begin
          select STM_MOVEMENT_KIND_ID
               , MOK_FINANCIAL_IMPUTATION
            into movement_kind_id
               , financialCharging
            from STM_MOVEMENT_KIND
           where C_MOVEMENT_SORT = 'ENT'
             and C_MOVEMENT_TYPE = 'VAL'
             and C_MOVEMENT_CODE = '014';
        exception
          when no_data_found then
            raise_application_error(-20033, 'PCS - No input PRF correction move kind defined!');
        end;
      else
        -- mouvement de sortie
        begin
          select STM_MOVEMENT_KIND_ID
               , MOK_FINANCIAL_IMPUTATION
            into movement_kind_id
               , financialCharging
            from STM_MOVEMENT_KIND
           where C_MOVEMENT_SORT = 'SOR'
             and C_MOVEMENT_TYPE = 'VAL'
             and C_MOVEMENT_CODE = '014';
        exception
          when no_data_found then
            raise_application_error(-20034, 'PCS - No output PRF correction move kind defined!');
        end;
      end if;

      open stock_position(GOOD_ID);

      fetch stock_position
       into stock_position_tuple;

      while stock_position%found loop
        declare
          stockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
        begin
          -- le prix du mouvement est toujours positif
          move_price  := abs(DIFF) * stock_position_tuple.spo_stock_quantity;
          -- insertion d'un mouvement de stock de correction
          STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => stockMovementId
                                          , iGoodId                => GOOD_ID
                                          , iMovementKindId        => movement_kind_id
                                          , iExerciseId            => exercise_id
                                          , iPeriodId              => period_id
                                          , iMvtDate               => move_date
                                          , iValueDate             => move_date
                                          , iStockId               => stock_position_tuple.stm_stock_id
                                          , iLocationId            => FAL_TOOLS.GetDefltSTM_LOCATION_ID(GOOD_ID, stock_position_tuple.stm_stock_id)
                                          , iThirdId               => null
                                          , iThirdAciId            => null
                                          , iThirdDeliveryId       => null
                                          , iThirdTariffId         => null
                                          , iRecordId              => null
                                          , iChar1Id               => stock_position_tuple.GCO_CHARACTERIZATION_ID
                                          , iChar2Id               => stock_position_tuple.GCO_GCO_CHARACTERIZATION_ID
                                          , iChar3Id               => stock_position_tuple.GCO2_GCO_CHARACTERIZATION_ID
                                          , iChar4Id               => stock_position_tuple.GCO3_GCO_CHARACTERIZATION_ID
                                          , iChar5Id               => stock_position_tuple.GCO4_GCO_CHARACTERIZATION_ID
                                          , iCharValue1            => stock_position_tuple.SPO_CHARACTERIZATION_VALUE_1
                                          , iCharValue2            => stock_position_tuple.SPO_CHARACTERIZATION_VALUE_2
                                          , iCharValue3            => stock_position_tuple.SPO_CHARACTERIZATION_VALUE_3
                                          , iCharValue4            => stock_position_tuple.SPO_CHARACTERIZATION_VALUE_4
                                          , iCharValue5            => stock_position_tuple.SPO_CHARACTERIZATION_VALUE_5
                                          , iMovement2Id           => null
                                          , iMovement3Id           => null
                                          , iWording               => 'PRF Correction move'
                                          , iExternalDocument      => null
                                          , iExternalPartner       => null
                                          , iMvtQty                => 0
                                          , iMvtPrice              => move_price
                                          , iDocQty                => 0
                                          , iDocPrice              => 0
                                          , iUnitPrice             => 0
                                          , iRefUnitPrice          => abs(DIFF)
                                          , iAltQty1               => 0
                                          , iAltQty2               => 0
                                          , iAltQty3               => 0
                                          , iDocPositionDetailId   => null
                                          , iDocPositionId         => null
                                          , iFinancialAccountId    => null
                                          , iDivisionAccountId     => null
                                          , iaFinancialAccountId   => null
                                          , iaDivisionAccountId    => null
                                          , iCPNAccountId          => null
                                          , iaCPNAccountId         => null
                                          , iCDAAccountId          => null
                                          , iaCDAAccountId         => null
                                          , iPFAccountId           => null
                                          , iaPFAccountId          => null
                                          , iPJAccountId           => null
                                          , iaPJAccountId          => null
                                          , iFamFixedAssetsId      => null
                                          , iFamTransactionTyp     => null
                                          , iHrmPersonId           => null
                                          , iDicImpfree1Id         => null
                                          , iDicImpfree2Id         => null
                                          , iDicImpfree3Id         => null
                                          , iDicImpfree4Id         => null
                                          , iDicImpfree5Id         => null
                                          , iImpText1              => null
                                          , iImpText2              => null
                                          , iImpText3              => null
                                          , iImpText4              => null
                                          , iImpText5              => null
                                          , iImpNumber1            => null
                                          , iImpNumber2            => null
                                          , iImpNumber3            => null
                                          , iImpNumber4            => null
                                          , iImpNumber5            => null
                                          , iFinancialCharging     => financialCharging
                                          , iUpdateProv            => 0
                                          , iExtourneMvt           => 0
                                          , iRecStatus             => null
                                           );

          fetch stock_position
           into stock_position_tuple;
        end;
      end loop;
    end if;
  end GenPRFCorrectionMove;

  /**
  * procedure SelectFixedCostPrices
  * Description
  *   Sélectionne PRF dont on souhaite faire évoluer le statut, ou la caract.
  *   par défaut
  * @version 2003
  * @author ECA 13.08.2008
  * @lastUpdate
  * @public
  * @param   aDIC_FIXED_COSTPRICE_DESCR_ID : Dico prix de revient
  * @param   aC_COSTPRICE_STATUS : Statut
  * @param   aPAC_THIRD_ID : Tier
  * @param   aFCP_START_DATEFrom : Date début validité de
  * @param   aFCP_START_DATETo : Date début validité à
  * @param   aFCP_END_DATEFrom : Date fin validité de
  * @param   aFCP_END_DATEto : Date fin validité à
  * @param   aMinDeltaFromDefault : Différence min / Prix actif par défaut
  * @param   aMaxDeltaFromDefault : Différence max / Prix actif par défaut
  * @param   aCPR_DEFAULT : Prix par défaut
  * @param   aCPR_MANUFACTURE_ACCOUNTING : Prix flagués comptabilité industrielle
  * @param   aOnlyMoreRecentByProduct integer default 0
  */
  procedure SelectFixedCostPrices(
    aDIC_FIXED_COSTPRICE_DESCR_ID PTC_FIXED_COSTPRICE.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , aC_COSTPRICE_STATUS           PTC_FIXED_COSTPRICE.C_COSTPRICE_STATUS%type
  , aPAC_THIRD_ID                 PTC_FIXED_COSTPRICE.PAC_THIRD_ID%type
  , aFCP_START_DATEFrom           PTC_FIXED_COSTPRICE.FCP_START_DATE%type
  , aFCP_START_DATETo             PTC_FIXED_COSTPRICE.FCP_START_DATE%type
  , aFCP_END_DATEFrom             PTC_FIXED_COSTPRICE.FCP_END_DATE%type
  , aFCP_END_DATETo               PTC_FIXED_COSTPRICE.FCP_END_DATE%type
  , aMinDeltaFromDefault          integer
  , aMaxDeltaFromDefault          integer
  , aCPR_DEFAULT                  PTC_FIXED_COSTPRICE.CPR_DEFAULT%type
  , aCPR_MANUFACTURE_ACCOUNTING   PTC_FIXED_COSTPRICE.CPR_MANUFACTURE_ACCOUNTING%type
  , aDefaultSelected              integer default 1
  , aOnlyMoreRecentByProduct      integer default 0
  )
  is
    vStrSQL varchar2(32000);
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'PTC_FIXED_COSTPRICE_ID';

    -- Sélection des ID de lots
    vStrSQL  :=
      'insert into COM_LIST_ID_TEMP ' ||
      '            (COM_LIST_ID_TEMP_ID ' ||
      '           , LID_CODE ' ||
      '           , LID_FREE_NUMBER_1 ' ||
      '            ) ' ||
      '  select distinct PTC.PTC_FIXED_COSTPRICE_ID ' ||
      '                , ''PTC_FIXED_COSTPRICE_ID'' ' ||
      '                , NVL(:aDefaultSelected, 0) ' ||
      '             from PTC_FIXED_COSTPRICE PTC ';

    if aOnlyMoreRecentByProduct = 1 then
      vStrSQL  :=
        vStrSQL ||
        '                , (select MAX(PTC2.PTC_FIXED_COSTPRICE_ID) PTC_FIXED_COSTPRICE_ID ' ||
        '                        , PTC2.GCO_GOOD_ID ' ||
        '                     from PTC_FIXED_COSTPRICE PTC2 ' ||
        '                    where PTC2.GCO_GOOD_ID in (select COM_LIST_ID_TEMP_ID ' ||
        '                                                from COM_LIST_ID_TEMP ' ||
        '                                               where LID_CODE = ''GCO_GOOD_ID'') ' ||
        '                      and (:aDIC_FIXED_COSTPRICE_DESCR_ID is null or PTC2.DIC_FIXED_COSTPRICE_DESCR_ID = :aDIC_FIXED_COSTPRICE_DESCR_ID) ' ||
        '                      and (:aC_COSTPRICE_STATUS is null or PTC2.C_COSTPRICE_STATUS = :aC_COSTPRICE_STATUS) ' ||
        '                      and (:aPAC_THIRD_ID is null or PTC2.PAC_THIRD_ID = :aPAC_THIRD_ID) ' ||
        '                      and (:aFCP_START_DATEFrom is null or Trunc(PTC2.FCP_START_DATE) >= Trunc(:aFCP_START_DATEFrom)) ' ||
        '                      and (:aFCP_START_DATETo is null or Trunc(PTC2.FCP_START_DATE) <= Trunc(:aFCP_START_DATETo)) ' ||
        '                      and (:aFCP_END_DATEFrom is null or Trunc(PTC2.FCP_END_DATE) >= Trunc(:aFCP_END_DATEFrom)) ' ||
        '                      and (:aFCP_END_DATETo is null or Trunc(PTC2.FCP_END_DATE) <= Trunc(:aFCP_END_DATETo)) ' ||
        '                      and (:aMinDeltaFromDefault is null or abs(PTC_COSTPRICE.GetDifferenceWithActivePrice(PTC2.GCO_GOOD_ID, PTC2.CPR_PRICE)) >= :aMinDeltaFromDefault) ' ||
        '                      and (:aMaxDeltaFromDefault is null or abs(PTC_COSTPRICE.GetDifferenceWithActivePrice(PTC2.GCO_GOOD_ID, PTC2.CPR_PRICE)) <= :aMaxDeltaFromDefault) ' ||
        '                      and (:aCPR_DEFAULT is null or PTC2.CPR_DEFAULT = :aCPR_DEFAULT) ' ||
        '                      and (:aCPR_MANUFACTURE_ACCOUNTING is null or PTC2.CPR_MANUFACTURE_ACCOUNTING = :aCPR_MANUFACTURE_ACCOUNTING) ' ||
        '                  group by PTC2.GCO_GOOD_ID) RECENT ';
    end if;

    vStrSQL  :=
      vStrSQL ||
      '            where PTC.GCO_GOOD_ID in (select COM_LIST_ID_TEMP_ID ' ||
      '                                        from COM_LIST_ID_TEMP ' ||
      '                                       where LID_CODE = ''GCO_GOOD_ID'') ' ||
      '              and (:aDIC_FIXED_COSTPRICE_DESCR_ID is null or PTC.DIC_FIXED_COSTPRICE_DESCR_ID = :aDIC_FIXED_COSTPRICE_DESCR_ID) ' ||
      '              and (:aC_COSTPRICE_STATUS is null or PTC.C_COSTPRICE_STATUS = :aC_COSTPRICE_STATUS) ' ||
      '              and (:aPAC_THIRD_ID is null or PTC.PAC_THIRD_ID = :aPAC_THIRD_ID) ' ||
      '              and (:aFCP_START_DATEFrom is null or Trunc(PTC.FCP_START_DATE) >= Trunc(:aFCP_START_DATEFrom)) ' ||
      '              and (:aFCP_START_DATETo is null or Trunc(PTC.FCP_START_DATE) <= Trunc(:aFCP_START_DATETo)) ' ||
      '              and (:aFCP_END_DATEFrom is null or Trunc(PTC.FCP_END_DATE) >= Trunc(:aFCP_END_DATEFrom)) ' ||
      '              and (:aFCP_END_DATETo is null or Trunc(PTC.FCP_END_DATE) <= Trunc(:aFCP_END_DATETo)) ' ||
      '              and (:aMinDeltaFromDefault is null or abs(PTC_COSTPRICE.GetDifferenceWithActivePrice(PTC.GCO_GOOD_ID, PTC.CPR_PRICE)) >= :aMinDeltaFromDefault) ' ||
      '              and (:aMaxDeltaFromDefault is null or abs(PTC_COSTPRICE.GetDifferenceWithActivePrice(PTC.GCO_GOOD_ID, PTC.CPR_PRICE)) <= :aMaxDeltaFromDefault) ' ||
      '              and (:aCPR_DEFAULT is null or PTC.CPR_DEFAULT = :aCPR_DEFAULT) ' ||
      '              and (:aCPR_MANUFACTURE_ACCOUNTING is null or PTC.CPR_MANUFACTURE_ACCOUNTING = :aCPR_MANUFACTURE_ACCOUNTING) ';

    if aOnlyMoreRecentByProduct = 1 then
      vStrSQL  := vStrSQL || '              and PTC.PTC_FIXED_COSTPRICE_ID = RECENT.PTC_FIXED_COSTPRICE_ID ';
    end if;

    if aOnlyMoreRecentByProduct = 1 then
      execute immediate vStrSQL
                  using aDefaultSelected
                      , aDIC_FIXED_COSTPRICE_DESCR_ID
                      , aDIC_FIXED_COSTPRICE_DESCR_ID
                      , aC_COSTPRICE_STATUS
                      , aC_COSTPRICE_STATUS
                      , aPAC_THIRD_ID
                      , aPAC_THIRD_ID
                      , aFCP_START_DATEFrom
                      , aFCP_START_DATEFrom
                      , aFCP_START_DATETo
                      , aFCP_START_DATETo
                      , aFCP_END_DATEFrom
                      , aFCP_END_DATEFrom
                      , aFCP_END_DATETo
                      , aFCP_END_DATETo
                      , aMinDeltaFromDefault
                      , aMinDeltaFromDefault
                      , aMaxDeltaFromDefault
                      , aMaxDeltaFromDefault
                      , aCPR_DEFAULT
                      , aCPR_DEFAULT
                      , aCPR_MANUFACTURE_ACCOUNTING
                      , aCPR_MANUFACTURE_ACCOUNTING
                      , aDIC_FIXED_COSTPRICE_DESCR_ID
                      , aDIC_FIXED_COSTPRICE_DESCR_ID
                      , aC_COSTPRICE_STATUS
                      , aC_COSTPRICE_STATUS
                      , aPAC_THIRD_ID
                      , aPAC_THIRD_ID
                      , aFCP_START_DATEFrom
                      , aFCP_START_DATEFrom
                      , aFCP_START_DATETo
                      , aFCP_START_DATETo
                      , aFCP_END_DATEFrom
                      , aFCP_END_DATEFrom
                      , aFCP_END_DATETo
                      , aFCP_END_DATETo
                      , aMinDeltaFromDefault
                      , aMinDeltaFromDefault
                      , aMaxDeltaFromDefault
                      , aMaxDeltaFromDefault
                      , aCPR_DEFAULT
                      , aCPR_DEFAULT
                      , aCPR_MANUFACTURE_ACCOUNTING
                      , aCPR_MANUFACTURE_ACCOUNTING;
    else
      execute immediate vStrSQL
                  using aDefaultSelected
                      , aDIC_FIXED_COSTPRICE_DESCR_ID
                      , aDIC_FIXED_COSTPRICE_DESCR_ID
                      , aC_COSTPRICE_STATUS
                      , aC_COSTPRICE_STATUS
                      , aPAC_THIRD_ID
                      , aPAC_THIRD_ID
                      , aFCP_START_DATEFrom
                      , aFCP_START_DATEFrom
                      , aFCP_START_DATETo
                      , aFCP_START_DATETo
                      , aFCP_END_DATEFrom
                      , aFCP_END_DATEFrom
                      , aFCP_END_DATETo
                      , aFCP_END_DATETo
                      , aMinDeltaFromDefault
                      , aMinDeltaFromDefault
                      , aMaxDeltaFromDefault
                      , aMaxDeltaFromDefault
                      , aCPR_DEFAULT
                      , aCPR_DEFAULT
                      , aCPR_MANUFACTURE_ACCOUNTING
                      , aCPR_MANUFACTURE_ACCOUNTING;
    end if;
  end SelectFixedCostPrices;

  /**
  * procedure GetDifferenceWithActivePrice
  * Description
  *   Retourne la différence en % d'un prix pour un produit avec le prix actif par défaut
  *   en vigueur
  * @author ECA
  * @public
  * @param aGCO_GOOD_ID : id du bien
  * @param aCPR_PRICE : Valeur du PRF à Comparer
  */
  function GetDifferenceWithActivePrice(aGCO_GOOD_ID number, aCPR_PRICE number)
    return number
  is
    aDefltCPR_PRICE number;
  begin
    -- Sélection du prix actif par défaut en vigueur
    select nvl(CPR_PRICE, 0)
      into aDefltCPR_PRICE
      from PTC_FIXED_COSTPRICE
     where GCO_GOOD_ID = aGCO_GOOD_ID
       and CPR_DEFAULT = 1
       and C_COSTPRICE_STATUS = 'ACT'
       and PAC_THIRD_ID is null;

    -- Calcul du pourcentage de différence
    if aCPR_PRICE <> 0 then
      return ( (aCPR_PRICE * 100) / aDefltCPR_PRICE) - 100;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end GetDifferenceWithActivePrice;

  /**
  * procedure ProcessPricesUpdates
  * Description
  *   Mise à jour en série des status et coches par défaut des prix de revient
  *
  * @version 2003
  * @author ECA 19.08.2008
  * @lastUpdate
  * @public
  * @param   aNewPriceDefault : Coche par défaut Nouveau prix
  * @param   aNewPriceStatus : Statut Nouveau prix
  * @param   aOldPriceStatus : Statut ancien prix
  * @param   aSuccessfulCount : Succès
  * @param   aTotalCount : Total traités
  */
  procedure ProcessPricesUpdates(
    aNewPriceDefault in     integer
  , aNewPriceStatus  in     varchar2
  , aOldPriceStatus  in     varchar2
  , aSuccessfulCount out    integer
  , aTotalCount      out    integer
  )
  is
    cursor crPricesToUpdate
    is
      select FCP.PTC_FIXED_COSTPRICE_ID
           , FCP.C_COSTPRICE_STATUS
           , FCP.CPR_DEFAULT
           , FCP.GCO_GOOD_ID
           , FCP.PAC_THIRD_ID
        from COM_LIST_ID_TEMP LID
           , PTC_FIXED_COSTPRICE FCP
       where FCP.PTC_FIXED_COSTPRICE_ID = LID.COM_LIST_ID_TEMP_ID
         and LID.LID_CODE = 'PTC_FIXED_COSTPRICE_ID'
         and LID.LID_FREE_NUMBER_1 = 1;

    type TPricesToUpdate is table of crPricesToUpdate%rowtype;

    vPricesToUpdate     TPricesToUpdate;
    cBulkLimit constant number          := 10000;
    vIndex              integer;
    vSqlMsg             varchar2(4000);
  begin
    aSuccessfulCount  := 0;
    aTotalCount       := 0;

    open crPricesToUpdate;

    fetch crPricesToUpdate
    bulk collect into vPricesToUpdate limit cBulkLimit;

    -- Pour chaque élément sélectionné de la table temporaire
    while vPricesToUpdate.count > 0 loop
      for vIndex in vPricesToUpdate.first .. vPricesToUpdate.last loop
        begin
          -- Incrémentation du compteur total
          vSqlMsg      := null;
          aTotalCount  := aTotalCount + 1;
          savepoint SP_BeforeUpdate;

          -- Mise à jour d'abord des anciens prix, si le nouveau prix est par défaut
          if aNewPriceDefault = 1 then
            -- Le prix en cours de modification est déjà par défaut
            if vPricesToUpdate(vIndex).CPR_DEFAULT = 1 then
              null;
            else
              -- Il s'agit d'un nouveau prix par défaut, décoche des prix par défaut actuels
              -- La règle à respecter est : La case à cocher "Prix de revient par défaut" ne peut être sélectionnée
              --                            que pour un seul PRF par partenaire et pour un seul PRF sans partenaire.
              update PTC_FIXED_COSTPRICE
                 set C_COSTPRICE_STATUS = nvl(aOldPriceStatus, C_COSTPRICE_STATUS)
                   , CPR_DEFAULT = 0
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
               where PTC_FIXED_COSTPRICE_ID in(
                       select PTC_FIXED_COSTPRICE_ID
                         from PTC_FIXED_COSTPRICE
                        where GCO_GOOD_ID = vPricesToUpdate(vIndex).GCO_GOOD_ID
                          and CPR_DEFAULT = 1
                          and (    (    vPricesToUpdate(vIndex).PAC_THIRD_ID is null
                                    and PAC_THIRD_ID is null)
                               or (    vPricesToUpdate(vIndex).PAC_THIRD_ID is not null
                                   and PAC_THIRD_ID = vPricesToUpdate(vIndex).PAC_THIRD_ID)
                              ) );
            end if;
          end if;

          -- Mise à jour du nouveau prix
          update PTC_FIXED_COSTPRICE
             set C_COSTPRICE_STATUS = aNewPriceStatus
               , CPR_DEFAULT = aNewPriceDefault
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
           where PTC_FIXED_COSTPRICE_ID = vPricesToUpdate(vIndex).PTC_FIXED_COSTPRICE_ID;
        exception
          when others then
            -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
            vSqlMsg  :=
              PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement :') ||
              co.cLineBreak ||
              DBMS_UTILITY.FORMAT_ERROR_STACK ||
              DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        end;

        -- Annulation du traitement de l'imputation en cours s'il y a eu le moindre problème
        if vSqlMsg is not null then
          rollback to savepoint SP_BeforeUpdate;

          -- Mise à jour de l'erreur
          update COM_LIST_ID_TEMP
             set LID_DESCRIPTION = vSqlMsg
           where COM_LIST_ID_TEMP_ID = vPricesToUpdate(vIndex).PTC_FIXED_COSTPRICE_ID
             and LID_CODE = 'PTC_FIXED_COSTPRICE_ID';
        else
          aSuccessfulCount  := aSuccessfulCount + 1;

          delete      COM_LIST_ID_TEMP
                where COM_LIST_ID_TEMP_ID = vPricesToUpdate(vIndex).PTC_FIXED_COSTPRICE_ID
                  and LID_CODE = 'PTC_FIXED_COSTPRICE_ID';
        end if;
      end loop;

      fetch crPricesToUpdate
      bulk collect into vPricesToUpdate limit cBulkLimit;
    end loop;

    close crPricesToUpdate;
  end ProcessPricesUpdates;

  /**
  * procedure FlagSelectedFixedCostPrices
  * Description
  *   Sélection / Désélection dans la table OM_LIST_ID_TEMP
  *
  * @version 2003
  * @author ECA 19.08.2008
  * @lastUpdate
  * @public
  * @param   aPTC_FIXED_COSTPRICE_ID : un prix en particulier
  * @param   aBlnFlag : Sélectionne / Désélectionne
  */
  procedure FlagSelectedFixedCostPrices(aPTC_FIXED_COSTPRICE_ID number, aBlnFlag integer)
  is
  begin
    update COM_LIST_ID_TEMP
       set LID_FREE_NUMBER_1 = aBlnFlag
     where LID_CODE = 'PTC_FIXED_COSTPRICE_ID'
       and (   nvl(aPTC_FIXED_COSTPRICE_ID, 0) = 0
            or COM_LIST_ID_TEMP_ID = aPTC_FIXED_COSTPRICE_ID);
  end FlagSelectedFixedCostPrices;

  /**
   * procedure SelectProducts
   * Description
   *   Sélectionne les produits selon les filtres
   */
  procedure SelectProducts(
    aPRODUCT_FROM           in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aPRODUCT_TO             in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aGOOD_CATEGORY_FROM     in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aGOOD_CATEGORY_TO       in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aGOOD_FAMILY_FROM       in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aGOOD_FAMILY_TO         in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aACCOUNTABLE_GROUP_FROM in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aACCOUNTABLE_GROUP_TO   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aGOOD_LINE_FROM         in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aGOOD_LINE_TO           in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aGOOD_GROUP_FROM        in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aGOOD_GROUP_TO          in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aGOOD_MODEL_FROM        in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , aGOOD_MODEL_TO          in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct GOO.GCO_GOOD_ID
                    , 'GCO_GOOD_ID'
                 from GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , GCO_GOOD_CATEGORY CAT
                where GOO.GOO_MAJOR_REFERENCE between nvl(aPRODUCT_FROM, GOO.GOO_MAJOR_REFERENCE) and nvl(aPRODUCT_TO, GOO.GOO_MAJOR_REFERENCE)
                  and PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and (    (    aGOOD_CATEGORY_FROM is null
                            and aGOOD_CATEGORY_TO is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(aGOOD_CATEGORY_FROM, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(aGOOD_CATEGORY_TO, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    aGOOD_FAMILY_FROM is null
                            and aGOOD_FAMILY_TO is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(aGOOD_FAMILY_FROM, GOO.DIC_GOOD_FAMILY_ID) and nvl(aGOOD_FAMILY_TO, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    aACCOUNTABLE_GROUP_FROM is null
                            and aACCOUNTABLE_GROUP_TO is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(aACCOUNTABLE_GROUP_FROM, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(aACCOUNTABLE_GROUP_TO, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    aGOOD_LINE_FROM is null
                            and aGOOD_LINE_TO is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(aGOOD_LINE_FROM, GOO.DIC_GOOD_LINE_ID) and nvl(aGOOD_LINE_TO, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    aGOOD_GROUP_FROM is null
                            and aGOOD_GROUP_TO is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(aGOOD_GROUP_FROM, GOO.DIC_GOOD_GROUP_ID) and nvl(aGOOD_GROUP_TO, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    aGOOD_MODEL_FROM is null
                            and aGOOD_MODEL_TO is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(aGOOD_MODEL_FROM, GOO.DIC_GOOD_MODEL_ID) and nvl(aGOOD_MODEL_TO, GOO.DIC_GOOD_MODEL_ID)
                      );
  end SelectProducts;
end PTC_COSTPRICE;
