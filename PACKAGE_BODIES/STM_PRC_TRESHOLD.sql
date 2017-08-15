--------------------------------------------------------
--  DDL for Package Body STM_PRC_TRESHOLD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_TRESHOLD" 
is
  /**
  * Description
  *   méthode principal de contrôle des seuils
  */
  procedure TestStockExercise(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lExerciseStatus varchar2(10);
    lMovementSort   varchar2(3);
    lPdtCalc        number(1);
    lQuantity       number(18, 5);
  begin
    -- Recherche du type du mouvement pour savoir si c'est une entr,e ou une sortie
    select C_Movement_Sort
      into lMovementSort
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = iotMovementRecord.STM_MOVEMENT_KIND_ID;

    if lMovementSort = 'SOR' then
      lQuantity  := iotMovementRecord.SMO_MOVEMENT_QUANTITY * -1;
    else
      lQuantity  := iotMovementRecord.SMO_MOVEMENT_QUANTITY;
    end if;

    -- Test pour savoir si le mvt a ,t, effectu, sur l'exercice courant
    select C_EXERCISE_STATUS
      into lExerciseStatus
      from STM_EXERCISE
     where STM_EXERCISE_ID = iotMovementRecord.STM_EXERCISE_ID;

    -- Test pour savoir si le bien n'est pas g,r, dans le calcul des besoins
    select nvl(max(PDT_CALC_REQUIREMENT_MNGMENT), 1)
      into lPdtCalc
      from GCO_PRODUCT
     where GCO_GOOD_ID = iotMovementRecord.GCO_GOOD_ID;

    if     lExerciseStatus = '02'
       and lPdtCalc = 0 then
      FindSupplyingPolitical(iotMovementRecord.STM_STOCK_ID
                           , iotMovementRecord.STM_MOVEMENT_KIND_ID
                           , iotMovementRecord.GCO_GOOD_ID
                           , iotMovementRecord.STM_STOCK_MOVEMENT_ID
                           , lQuantity
                            );
    end if;
  end;

  procedure FindSupplyingPolitical(iStockId in number, iKindId in number, iGoodId in number, iMovementId in number, iMovementQuantity in number)
  is
    lSupplyingPoliticalId    number(18);
    lPoliticalGoodStockExist number(18);

    cursor lcurPoliticalGoodStock(iStockId number, iGoodId number)
    is
      select STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID
        from STM_SUPPLYING_POL_STOCK
           , STM_SUPPLYING_POL_GOOD
       where (STM_SUPPLYING_POL_STOCK.STM_STOCK_ID = iStockId)
         and (STM_SUPPLYING_POL_GOOD.GCO_GOOD_ID = iGoodId)
         and (STM_SUPPLYING_POL_GOOD.STM_SUPPLYING_POLITICAL_ID = STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID);

    cursor lcurPoliticalGood(iGoodId number)
    is
      select distinct STM_SUPPLYING_POL_GOOD.STM_SUPPLYING_POLITICAL_ID
                 from STM_SUPPLYING_POL_GOOD
                where STM_SUPPLYING_POL_GOOD.GCO_GOOD_ID = iGoodId;

    cursor lcurPoliticalGoodWithTest(iGoodId number)
    is
      select distinct STM_SUPPLYING_POL_GOOD.STM_SUPPLYING_POLITICAL_ID
                 from STM_SUPPLYING_POL_GOOD
                    , STM_SUPPLYING_POL_STOCK
                    , (select STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID
                         from STM_SUPPLYING_POL_STOCK
                            , STM_SUPPLYING_POL_GOOD
                        where STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID = STM_SUPPLYING_POL_GOOD.STM_SUPPLYING_POLITICAL_ID) POLITICALID
                where (STM_SUPPLYING_POL_GOOD.GCO_GOOD_ID = iGoodId)
                  and (STM_SUPPLYING_POL_GOOD.STM_SUPPLYING_POLITICAL_ID <> POLITICALID.STM_SUPPLYING_POLITICAL_ID);

    cursor lcurPoliticalStock(iStockId number)
    is
      select distinct STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID
                 from STM_SUPPLYING_POL_STOCK
                where STM_STOCK_ID = iStockId;

    cursor lcurPoliticalStockWithTest(iStockId number)
    is
      select distinct STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID
                 from STM_SUPPLYING_POL_GOOD
                    , STM_SUPPLYING_POL_STOCK
                    , (select STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID
                         from STM_SUPPLYING_POL_STOCK
                            , STM_SUPPLYING_POL_GOOD
                        where STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID = STM_SUPPLYING_POL_GOOD.STM_SUPPLYING_POLITICAL_ID) POLITICALID
                where (STM_STOCK_ID = iStockId)
                  and (STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID <> POLITICALID.STM_SUPPLYING_POLITICAL_ID);
  begin
    -- Recherche si il existe des politiques avec Bien et Stock, pour savoir qu'elle requ^te lancer
    select max(STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID)
      into lPoliticalGoodStockExist
      from STM_SUPPLYING_POL_STOCK
         , STM_SUPPLYING_POL_GOOD
     where STM_SUPPLYING_POL_STOCK.STM_SUPPLYING_POLITICAL_ID = STM_SUPPLYING_POL_GOOD.STM_SUPPLYING_POLITICAL_ID;

    -- Recherche politique avec parametre bien et stock
    open lcurPoliticalGoodStock(iStockId, iGoodId);

    fetch lcurPoliticalGoodStock
     into lSupplyingPoliticalId;

    if lcurPoliticalGoodStock%found then
      while lcurPoliticalGoodStock%found loop
        ControlThresholdGoodStock(lSupplyingPoliticalId, iKindId, iGoodId, iStockId, iMovementId, iMovementQuantity);

        fetch lcurPoliticalGoodStock
         into lSupplyingPoliticalId;
      end loop;
    else
      -- Recherche politique si aucune politique a un bien et un stock
      if lPoliticalGoodStockExist is null then
        -- Recherche politique avec parametre bien
        open lcurPoliticalGood(iGoodId);

        fetch lcurPoliticalGood
         into lSupplyingPoliticalId;

        if lcurPoliticalGood%found then
          while lcurPoliticalGood%found loop
            -- Enregistrement alerte
            ControlThresholdGood(lSupplyingPoliticalId, iKindId, iGoodId, iStockId, iMovementId, iMovementQuantity);

            fetch lcurPoliticalGood
             into lSupplyingPoliticalId;
          end loop;
        else
          -- Recherche politique avec parametre stock
          open lcurPoliticalStock(iStockId);

          fetch lcurPoliticalStock
           into lSupplyingPoliticalId;

          while lcurPoliticalStock%found loop
            -- Enregistrement alerte
            ControlThresholdStock(lSupplyingPoliticalId, iKindId, iStockId, iGoodId, iMovementId, iMovementQuantity);

            fetch lcurPoliticalStock
             into lSupplyingPoliticalId;
          end loop;
        end if;
      else
        -- Recherche politique si au minimum une politique a un bien et un stock
          -- Recherche politique avec parametre bien
        open lcurPoliticalGoodWithTest(iGoodId);

        fetch lcurPoliticalGoodWithTest
         into lSupplyingPoliticalId;

        if lcurPoliticalGoodWithTest%found then
          while lcurPoliticalGoodWithTest%found loop
            -- Enregistrement alerte
            ControlThresholdGood(lSupplyingPoliticalId, iKindId, iGoodId, iStockId, iMovementId, iMovementQuantity);

            fetch lcurPoliticalGoodWithTest
             into lSupplyingPoliticalId;
          end loop;
        else
          -- Recherche politique avec parametre stock
          open lcurPoliticalStockWithTest(iStockId);

          fetch lcurPoliticalStockWithTest
           into lSupplyingPoliticalId;

          while lcurPoliticalStockWithTest%found loop
            -- Enregistrement alerte
            ControlThresholdStock(lSupplyingPoliticalId, iKindId, iStockId, iGoodId, iMovementId, iMovementQuantity);

            fetch lcurPoliticalStockWithTest
             into lSupplyingPoliticalId;
          end loop;
        end if;
      end if;
    end if;
  end FindSupplyingPolitical;

  procedure ControlThresholdGoodStock(
    iSupplyingPoliticalId in number
  , iKindId               in number
  , iGoodId               in number
  , iStockId              in number
  , iMovementId           in number
  , iMovementQuantity     in number
  )
  is
    lNumberInStock number(18, 5);
  begin
    -- Calcul du nombre d'elements en stock
    select sum(SPO_STOCK_QUANTITY)
      into lNumberInStock
      from STM_STOCK_POSITION
     where (GCO_GOOD_ID = iGoodId)
       and (STM_STOCK_ID = iStockId);

    -- Test les seuils et rempli les eventuelles alertes
    ThresholdOk(iSupplyingPoliticalId, iMovementId, iStockId, iGoodId, lNumberInStock, iMovementQuantity);
  end ControlThresholdGoodStock;

  procedure ControlThresholdGood(
    iSupplyingPoliticalId in number
  , iKindId               in number
  , iGoodId               in number
  , iStockId              in number
  , iMovementId           in number
  , iMovementQuantity     in number
  )
  is
    lNumberInStock number(18, 5);
  begin
    -- Calcul du nombre d'elements en stock
    select sum(SPO_STOCK_QUANTITY)
      into lNumberInStock
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = iGoodId;

    -- Test les seuils et rempli les eventuelles alertes
    ThresholdOk(iSupplyingPoliticalId, iMovementId, iStockId, iGoodId, lNumberInStock, iMovementQuantity);
  end ControlThresholdGood;

  procedure ControlThresholdStock(
    iSupplyingPoliticalId in number
  , iKindId                  number
  , iStockId              in number
  , iGoodId               in number
  , iMovementId           in number
  , iMovementQuantity     in number
  )
  is
    lNumberInStock number(18, 5);
  begin
    -- Calcul du nombre d'elements en stock
    select sum(SPO_STOCK_QUANTITY)
      into lNumberInStock
      from STM_STOCK_POSITION
     where (GCO_GOOD_ID = iGoodId)
       and (STM_STOCK_ID = iStockId);

    -- Test les seuils et rempli les eventuelles alertes
    ThresholdOk(iSupplyingPoliticalId, iMovementId, iStockId, iGoodId, lNumberInStock, iMovementQuantity);
  end ControlThresholdStock;

  procedure ThresholdOk(
    iSupplyingPoliticalId in number
  , iMovementId           in number
  , iStockId              in number
  , iGoodId               in number
  , lNumberInStock        in number
  , iMovementQuantity     in number
  )
  is
    lStockSecu      number(18, 5);
    lStockAlerte    number(18, 5);
    lStockMax       number(18, 5);
    lGeneratingProp number(18);
    lTmp            number(18);

    cursor lcurAlert(IdSuppPolitic number, Alert_Type varchar2)
    is
      select   RES_THRESHOLD_DOWN
          from STM_RESTOCKING_ALERT
         where (STM_SUPPLYING_POLITICAL_ID = IdSuppPolitic)
           and (C_ALERT_TYPE = Alert_Type)
      order by STM_RESTOCKING_ALERT_ID desc;
  begin
    select SUP_SECURITY_STOCK
         , SUP_ALERT_STOCK
         , SUP_MAXIMUM_STOCK
      into lStockSecu
         , lStockAlerte
         , lStockMax
      from STM_SUPPLYING_POLITICAL
     where STM_SUPPLYING_POLITICAL_ID = iSupplyingPoliticalId;

    if     (lNumberInStock < lStockAlerte)
       and (lNumberInStock - iMovementQuantity >= lStockAlerte) then
      -- Passage stock alerte vers le bas
      open lcurAlert(iSupplyingPoliticalId, '01');

      fetch lcurAlert
       into lTmp;

      close lcurAlert;

      if    (lTmp = 0)
         or (lTmp is null) then
        insert into STM_RESTOCKING_ALERT
                    (STM_RESTOCKING_ALERT_ID
                   , STM_ALERT_MOVEMENT_ID
                   , STM_STOCK_ID
                   , GCO_GOOD_ID
                   , STM_SUPPLYING_POLITICAL_ID
                   , C_ALERT_TYPE
                   , RES_ALERT_DATE
                   , RES_THRESHOLD_DOWN
                   , A_DATECRE
                   , A_IDCRE
                   , RES_BEFORE_QUANTITY
                   , RES_AFTER_QUANTITY
                    )
             values (init_id_seq.nextval
                   , iMovementId
                   , iStockId
                   , iGoodId
                   , iSupplyingPoliticalId
                   , '01'
                   , sysdate
                   , 1
                   , sysdate
                   , substr(user, 1, 5)
                   , lNumberInStock - iMovementQuantity
                   , lNumberInStock
                    );
      end if;
    else
      if     (lNumberInStock > lStockAlerte)
         and (lNumberInStock - iMovementQuantity <= lStockAlerte) then
        -- Passage stock alerte vers le haut
        open lcurAlert(iSupplyingPoliticalId, '01');

        fetch lcurAlert
         into lTmp;

        close lcurAlert;

        if    (lTmp = 1)
           or (lTmp is null) then
          insert into STM_RESTOCKING_ALERT
                      (STM_RESTOCKING_ALERT_ID
                     , STM_ALERT_MOVEMENT_ID
                     , STM_STOCK_ID
                     , GCO_GOOD_ID
                     , STM_SUPPLYING_POLITICAL_ID
                     , C_ALERT_TYPE
                     , RES_ALERT_DATE
                     , RES_THRESHOLD_DOWN
                     , A_DATECRE
                     , A_IDCRE
                     , RES_BEFORE_QUANTITY
                     , RES_AFTER_QUANTITY
                      )
               values (init_id_seq.nextval
                     , iMovementId
                     , iStockId
                     , iGoodId
                     , iSupplyingPoliticalId
                     , '01'
                     , sysdate
                     , 0
                     , sysdate
                     , substr(user, 1, 5)
                     , lNumberInStock - iMovementQuantity
                     , lNumberInStock
                      );
        end if;
      end if;
    end if;

    if     (lNumberInStock > lStockSecu)
       and (lNumberInStock - iMovementQuantity <= lStockSecu) then
      -- Passage du stock secu vers le haut
      open lcurAlert(iSupplyingPoliticalId, '02');

      fetch lcurAlert
       into lTmp;

      close lcurAlert;

      if    (lTmp = 1)
         or (lTmp is null) then
        insert into STM_RESTOCKING_ALERT
                    (STM_RESTOCKING_ALERT_ID
                   , STM_ALERT_MOVEMENT_ID
                   , STM_STOCK_ID
                   , GCO_GOOD_ID
                   , STM_SUPPLYING_POLITICAL_ID
                   , C_ALERT_TYPE
                   , RES_ALERT_DATE
                   , RES_THRESHOLD_DOWN
                   , A_DATECRE
                   , A_IDCRE
                   , RES_BEFORE_QUANTITY
                   , RES_AFTER_QUANTITY
                    )
             values (init_id_seq.nextval
                   , iMovementId
                   , iStockId
                   , iGoodId
                   , iSupplyingPoliticalId
                   , '02'
                   , sysdate
                   , 0
                   , sysdate
                   , substr(user, 1, 5)
                   , lNumberInStock - iMovementQuantity
                   , lNumberInStock
                    );
      end if;
    else
      if     (lNumberInStock < lStockSecu)
         and (lNumberInStock - iMovementQuantity >= lStockSecu) then
        -- Passage du stock secu vers le bas
        open lcurAlert(iSupplyingPoliticalId, '02');

        fetch lcurAlert
         into lTmp;

        close lcurAlert;

        if    (lTmp = 0)
           or (lTmp is null) then
          insert into STM_RESTOCKING_ALERT
                      (STM_RESTOCKING_ALERT_ID
                     , STM_ALERT_MOVEMENT_ID
                     , STM_STOCK_ID
                     , GCO_GOOD_ID
                     , STM_SUPPLYING_POLITICAL_ID
                     , C_ALERT_TYPE
                     , RES_ALERT_DATE
                     , RES_THRESHOLD_DOWN
                     , A_DATECRE
                     , A_IDCRE
                     , RES_BEFORE_QUANTITY
                     , RES_AFTER_QUANTITY
                      )
               values (init_id_seq.nextval
                     , iMovementId
                     , iStockId
                     , iGoodId
                     , iSupplyingPoliticalId
                     , '02'
                     , sysdate
                     , 1
                     , sysdate
                     , substr(user, 1, 5)
                     , lNumberInStock - iMovementQuantity
                     , lNumberInStock
                      );
        end if;
      end if;
    end if;

    if     (lNumberInStock > lStockMax)
       and (lNumberInStock - iMovementQuantity <= lStockMax) then
      -- Passage du stock maxi vers le haut
      open lcurAlert(iSupplyingPoliticalId, '03');

      fetch lcurAlert
       into lTmp;

      close lcurAlert;

      if    (lTmp = 1)
         or (lTmp is null) then
        insert into STM_RESTOCKING_ALERT
                    (STM_RESTOCKING_ALERT_ID
                   , STM_ALERT_MOVEMENT_ID
                   , STM_STOCK_ID
                   , GCO_GOOD_ID
                   , STM_SUPPLYING_POLITICAL_ID
                   , C_ALERT_TYPE
                   , RES_ALERT_DATE
                   , RES_THRESHOLD_DOWN
                   , A_DATECRE
                   , A_IDCRE
                   , RES_BEFORE_QUANTITY
                   , RES_AFTER_QUANTITY
                    )
             values (init_id_seq.nextval
                   , iMovementId
                   , iStockId
                   , iGoodId
                   , iSupplyingPoliticalId
                   , '03'
                   , sysdate
                   , 0
                   , sysdate
                   , substr(user, 1, 5)
                   , lNumberInStock - iMovementQuantity
                   , lNumberInStock
                    );
      end if;
    else
      if     (lNumberInStock < lStockMax)
         and (lNumberInStock - iMovementQuantity >= lStockMax) then
        -- Passage du stock maxi vers le bas
        open lcurAlert(iSupplyingPoliticalId, '03');

        fetch lcurAlert
         into lTmp;

        close lcurAlert;

        if    (lTmp = 0)
           or (lTmp is null) then
          insert into STM_RESTOCKING_ALERT
                      (STM_RESTOCKING_ALERT_ID
                     , STM_ALERT_MOVEMENT_ID
                     , STM_STOCK_ID
                     , GCO_GOOD_ID
                     , STM_SUPPLYING_POLITICAL_ID
                     , C_ALERT_TYPE
                     , RES_ALERT_DATE
                     , RES_THRESHOLD_DOWN
                     , A_DATECRE
                     , A_IDCRE
                     , RES_BEFORE_QUANTITY
                     , RES_AFTER_QUANTITY
                      )
               values (init_id_seq.nextval
                     , iMovementId
                     , iStockId
                     , iGoodId
                     , iSupplyingPoliticalId
                     , '03'
                     , sysdate
                     , 1
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , lNumberInStock - iMovementQuantity
                     , lNumberInStock
                      );
        end if;
      end if;
    end if;
  end ThresholdOk;
end STM_PRC_TRESHOLD;
