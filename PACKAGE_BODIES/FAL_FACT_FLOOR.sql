--------------------------------------------------------
--  DDL for Package Body FAL_FACT_FLOOR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_FACT_FLOOR" 
is
  /**
  * procedure GetIlot
  * Description : récupération de l'ilot d'une machine
  *
  * @created CLE
  * @lastUpdate
  * @private
  * @param   FalFactoryFloorId : ID de la machine
  * @return  ID de l'ilots
  */
  function GetIlot(FalFactoryFloorId number)
    return number
  is
    cursor CUR_FAL_FACTORY_FLOOR(FalFactoryFloorId number)
    is
      select FAL_FAL_FACTORY_FLOOR_ID
        from FAL_FACTORY_FLOOR
       where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId;

    result number;
  begin
    result  := null;

    open CUR_FAL_FACTORY_FLOOR(FalFactoryFloorId);

    fetch CUR_FAL_FACTORY_FLOOR
     into result;

    close CUR_FAL_FACTORY_FLOOR;

    return nvl(result, 0);
  end;

  /**
  * procedure Delete_Old_LMU
  * Description :  Pour chaque enregistrement de FAL_LIST_STEP_USE, FAL_TASK_LINK_USE et
  *                FAL_TASK_LINK_PROP_USE, on vérifie que la machine porte bien sur l'îlot
  *                de l'opération. Si ce n'est pas le cas, on supprime l'enregistrement.
  *                On supprime également des LMU les machine hors-services
  *
  * @created CLE
  * @lastUpdate
  * @private
  */
  procedure Delete_Old_LMU
  is
    -- Déclaration des curseurs
    cursor CUR_FAL_LIST_STEP_USE
    is
      select FAL_LIST_STEP_USE_ID
           , FLSU.FAL_FACTORY_FLOOR_ID FACTORY_FLOOR_USE
           , FLSL.FAL_FACTORY_FLOOR_ID FACTORY_FLOOR_LINK
           , FAC_IS_MACHINE
           , FAC_OUT_OF_ORDER
        from FAL_LIST_STEP_USE FLSU
           , FAL_LIST_STEP_LINK FLSL
           , FAL_FACTORY_FLOOR FFF
       where FLSU.FAL_SCHEDULE_STEP_ID = FLSL.FAL_SCHEDULE_STEP_ID
         and FLSL.FAl_FACTORY_FLOOR_ID = FFF.FAl_FACTORY_FLOOR_ID;

    cursor CUR_FAL_TASK_LINK_USE
    is
      select FAL_TASK_LINK_USE_ID
           , FTLU.FAL_FACTORY_FLOOR_ID FACTORY_FLOOR_USE
           , FTL.FAL_FACTORY_FLOOR_ID FACTORY_FLOOR_LINK
           , FAC_IS_MACHINE
           , FAC_OUT_OF_ORDER
        from FAL_TASK_LINK_USE FTLU
           , FAL_TASK_LINK FTL
           , FAL_FACTORY_FLOOR FFF
       where FTLU.FAL_SCHEDULE_STEP_ID = FTL.FAL_SCHEDULE_STEP_ID
         and FTL.FAl_FACTORY_FLOOR_ID = FFF.FAl_FACTORY_FLOOR_ID;

    cursor CUR_FAL_TASK_LINK_PROP_USE
    is
      select FAL_TASK_LINK_PROP_USE_ID
           , FTLPU.FAL_FACTORY_FLOOR_ID FACTORY_FLOOR_USE
           , FTLP.FAL_FACTORY_FLOOR_ID FACTORY_FLOOR_LINK
           , FAC_IS_MACHINE
           , FAC_OUT_OF_ORDER
        from FAL_TASK_LINK_PROP_USE FTLPU
           , FAL_TASK_LINK_PROP FTLP
           , FAL_FACTORY_FLOOR FFF
       where FTLPU.FAL_TASK_LINK_PROP_ID = FTLP.FAL_TASK_LINK_PROP_ID
         and FTLP.FAl_FACTORY_FLOOR_ID = FFF.FAl_FACTORY_FLOOR_ID;

    -- Déclaration des variables
    CurFalListStepUse     CUR_FAL_LIST_STEP_USE%rowtype;
    CurFalTaskLinkUse     CUR_FAL_TASK_LINK_USE%rowtype;
    CurFalTaskLinkPropUse CUR_FAL_TASK_LINK_PROP_USE%rowtype;
    IlotOperation         number;
  begin
    -- Pour chaque "Machine Utilisable" des Opérations de gammes
    open CUR_FAL_LIST_STEP_USE;

    loop
      fetch CUR_FAL_LIST_STEP_USE
       into CurFalListStepUse;

      exit when CUR_FAL_LIST_STEP_USE%notfound;

      -- Récupération de l'ilôt de l'opération
      if nvl(CurFalListStepUse.FAC_IS_MACHINE, 0) = 0 then
        IlotOperation  := CurFalListStepUse.FACTORY_FLOOR_LINK;
      else
        IlotOperation  := GetIlot(CurFalListStepUse.FACTORY_FLOOR_LINK);
      end if;

      -- Si la machine est hors-service ou que l'ilôt de la "Machine Utilisable"
      -- n'est pas le même que celui de l'opération, on supprime la "Machine Utilisable"
      if    (CurFalListStepUse.FAC_OUT_OF_ORDER = 1)
         or not(IlotOperation = GetIlot(CurFalListStepUse.FACTORY_FLOOR_USE) ) then
        delete from FAL_LIST_STEP_USE
              where FAL_LIST_STEP_USE_ID = CurFalListStepUse.FAL_LIST_STEP_USE_ID;
      end if;
    end loop;

    close CUR_FAL_LIST_STEP_USE;

    -- Pour chaque "Machine Utilisable" des Opérations de lots
    open CUR_FAL_TASK_LINK_USE;

    loop
      fetch CUR_FAL_TASK_LINK_USE
       into CurFalTaskLinkUse;

      exit when CUR_FAL_TASK_LINK_USE%notfound;

      -- Récupération de l'ilôt de l'opération
      if nvl(CurFalTaskLinkUse.FAC_IS_MACHINE, 0) = 0 then
        IlotOperation  := CurFalTaskLinkUse.FACTORY_FLOOR_LINK;
      else
        IlotOperation  := GetIlot(CurFalTaskLinkUse.FACTORY_FLOOR_LINK);
      end if;

      -- Si la machine est hors-service ou que l'ilôt de la "Machine Utilisable"
      -- n'est pas le même que celui de l'opération, on supprime la "Machine Utilisable"
      if    (CurFalTaskLinkUse.FAC_OUT_OF_ORDER = 1)
         or not(IlotOperation = GetIlot(CurFalTaskLinkUse.FACTORY_FLOOR_USE) ) then
        delete from FAL_TASK_LINK_USE
              where FAL_TASK_LINK_USE_ID = CurFalTaskLinkUse.FAL_TASK_LINK_USE_ID;
      end if;
    end loop;

    close CUR_FAL_TASK_LINK_USE;

    -- Pour chaque "Machine Utilisable" des Opérations de propositions de lots
    open CUR_FAL_TASK_LINK_PROP_USE;

    loop
      fetch CUR_FAL_TASK_LINK_PROP_USE
       into CurFalTaskLinkPropUse;

      exit when CUR_FAL_TASK_LINK_PROP_USE%notfound;

      -- Récupération de l'ilôt de l'opération
      if nvl(CurFalTaskLinkPropUse.FAC_IS_MACHINE, 0) = 0 then
        IlotOperation  := CurFalTaskLinkPropUse.FACTORY_FLOOR_LINK;
      else
        IlotOperation  := GetIlot(CurFalTaskLinkPropUse.FACTORY_FLOOR_LINK);
      end if;

      -- Si la machine est hors-service ou que l'ilôt de la "Machine Utilisable"
      -- n'est pas le même que celui de l'opération, on supprime la "Machine Utilisable"
      if    (CurFalTaskLinkPropUse.FAC_OUT_OF_ORDER = 1)
         or not(IlotOperation = GetIlot(CurFalTaskLinkPropUse.FACTORY_FLOOR_USE) ) then
        delete from FAL_TASK_LINK_PROP_USE
              where FAL_TASK_LINK_PROP_USE_ID = CurFalTaskLinkPropUse.FAL_TASK_LINK_PROP_USE_ID;
      end if;
    end loop;

    close CUR_FAL_TASK_LINK_PROP_USE;
  end;

  /**
  * procedure Add_New_LMU
  * Description :  Ajout des nouvelles machines utilisables
  *
  * @created CLE
  * @lastUpdate
  * @private
  */
  procedure Add_New_LMU
  is
    -- Déclaration des curseurs
    cursor crFactoryFloor
    is
      select FAL_FACTORY_FLOOR_ID MACHINE_ID
           , FAL_FAL_FACTORY_FLOOR_ID ILOT_ID
        from FAL_FACTORY_FLOOR
       where FAC_IS_MACHINE = 1
         and FAC_UPDATE_LMU = 0
         and FAC_OUT_OF_ORDER = 0;

    cursor crFalListStepLink(FalFactoryFloorId number)
    is
      select FAL_SCHEDULE_STEP_ID
           , SCS_WORK_TIME
           , SCS_QTY_REF_WORK
        from FAL_LIST_STEP_LINK
       where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId;

    cursor crFalTaskLink(FalFactoryFloorId number)
    is
      select FAL_SCHEDULE_STEP_ID
           , SCS_WORK_TIME
           , SCS_QTY_REF_WORK
        from FAL_TASK_LINK
       where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId;

    cursor crFalTaskLinkProp(FalFactoryFloorId number)
    is
      select FAL_TASK_LINK_PROP_ID
           , SCS_WORK_TIME
           , SCS_QTY_REF_WORK
        from FAL_TASK_LINK_PROP
       where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId;

    -- Déclaration des variables
    CountLMU integer;
  begin
    -- Sélection des Machines non mises à jour et en service
    for tplFactoryFloor in crFactoryFloor loop
      -- Pour toutes les opérations qui porte sur l'îlot de la machine
      for tplFalListStepLink in crFalListStepLink(tplFactoryFloor.ILOT_ID) loop
        select count(1)
          into CountLMU
          from FAL_LIST_STEP_USE
         where FAL_FACTORY_FLOOR_ID = tplFactoryFloor.MACHINE_ID
           and FAL_SCHEDULE_STEP_ID = tplFalListStepLink.FAL_SCHEDULE_STEP_ID;

        if CountLMU = 0 then
          insert into FAL_LIST_STEP_USE
                      (FAL_LIST_STEP_USE_ID
                     , FAL_FACTORY_FLOOR_ID
                     , FAL_SCHEDULE_STEP_ID
                     , LSU_WORK_TIME
                     , LSU_QTY_REF_WORK
                     , LSU_PRIORITY
                     , LSU_EXCEPT_MACH
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , tplFactoryFloor.MACHINE_ID
                     , tplFalListStepLink.FAL_SCHEDULE_STEP_ID
                     , tplFalListStepLink.SCS_WORK_TIME
                     , tplFalListStepLink.SCS_QTY_REF_WORK
                     , 100
                     , 0
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;
      end loop;

      -- Pour toutes les opérations qui porte sur l'îlot de la machine
      for tplFalTaskLink in crFalTaskLink(tplFactoryFloor.ILOT_ID) loop
        select count(1)
          into CountLMU
          from FAL_TASK_LINK_USE
         where FAL_FACTORY_FLOOR_ID = tplFactoryFloor.MACHINE_ID
           and FAL_SCHEDULE_STEP_ID = tplFalTaskLink.FAL_SCHEDULE_STEP_ID;

        if CountLMU = 0 then
          insert into FAL_TASK_LINK_USE
                      (FAL_TASK_LINK_USE_ID
                     , FAL_FACTORY_FLOOR_ID
                     , FAL_SCHEDULE_STEP_ID
                     , SCS_WORK_TIME
                     , SCS_QTY_REF_WORK
                     , SCS_PRIORITY
                     , SCS_EXCEPT_MACH
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , tplFactoryFloor.MACHINE_ID
                     , tplFalTaskLink.FAL_SCHEDULE_STEP_ID
                     , tplFalTaskLink.SCS_WORK_TIME
                     , tplFalTaskLink.SCS_QTY_REF_WORK
                     , 100
                     , 0
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;
      end loop;

      -- Pour toutes les opérations qui porte sur l'îlot de la machine
      for tplFalTaskLinkProp in crFalTaskLinkProp(tplFactoryFloor.ILOT_ID) loop
        select count(1)
          into CountLMU
          from FAL_TASK_LINK_PROP_USE
         where FAL_FACTORY_FLOOR_ID = tplFactoryFloor.MACHINE_ID
           and FAL_TASK_LINK_PROP_ID = tplFalTaskLinkProp.FAL_TASK_LINK_PROP_ID;

        if CountLMU = 0 then
          insert into FAL_TASK_LINK_PROP_USE
                      (FAL_TASK_LINK_PROP_USE_ID
                     , FAL_FACTORY_FLOOR_ID
                     , FAL_TASK_LINK_PROP_ID
                     , SCS_WORK_TIME
                     , SCS_QTY_REF_WORK
                     , SCS_PRIORITY
                     , SCS_EXCEPT_MACH
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , tplFactoryFloor.MACHINE_ID
                     , tplFalTaskLinkProp.FAL_TASK_LINK_PROP_ID
                     , tplFalTaskLinkProp.SCS_WORK_TIME
                     , tplFalTaskLinkProp.SCS_QTY_REF_WORK
                     , 100
                     , 0
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;
      end loop;

      update FAL_FACTORY_FLOOR
         set FAC_UPDATE_LMU = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_FACTORY_FLOOR_ID = tplFactoryFloor.MACHINE_ID;
    end loop;
  end;

  /**
  * procedure Update_LMU
  * Description : Procédure de remise à jour de la liste des machines utilisables
  *               dans ORTEMS
  * @created CLE
  * @lastUpdate
  * @public
  */
  procedure Update_LMU
  is
  begin
    -- Suppression des Machines non utilisées
    Delete_Old_LMU;
    -- Ajout des nouvelles machines
    Add_New_LMU;
  end;

  /**
  * function GetCurrentRate
  * Description : Renvoie l'ID du taux courant.
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_FLOOR_ID   : Atelier
  * @return  aFAL_FACTORY_RATE : Taux
  */
  function GetCurrentRate(aFAL_FACTORY_FLOOR_ID number)
    return number
  is
    aRate number;
  begin
    select max(ffr.fal_factory_rate_id)
      into aRate
      from fal_factory_rate ffr
     where ffr.fal_factory_floor_id = afal_factory_floor_id
       and ffr.ffr_validity_date = (select max(ffr2.ffr_validity_date)
                                      from fal_factory_rate ffr2
                                     where ffr2.ffr_validity_date <= sysdate
                                       and ffr2.fal_factory_floor_id = afal_factory_floor_id);

    return aRate;
  exception
    when others then
      return 0;
  end;

  /**
  * procedure DuplicateRate
  * Description : Duplication d'un taux à date
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_RATE_ID : Taux Source
  * @param   aNewDate : Nouvelle date de validité
  * @param   aDuplicateDecomposition : Dupliquer la décomposition
  */
  procedure DuplicateRate(aFAL_FACTORY_RATE_ID number, aNewDate date default sysdate, aDuplicateDecomposition integer default 0)
  is
    aNewFAL_FACTORY_RATE_ID number;
  begin
    aNewFAL_FACTORY_RATE_ID  := GetNewId;

    insert into FAL_FACTORY_RATE
                (FAL_FACTORY_RATE_ID
               , FAL_FACTORY_FLOOR_ID
               , FFR_RATE1
               , FFR_RATE2
               , FFR_RATE3
               , FFR_RATE4
               , FFR_RATE5
               , FFR_VALIDITY_DATE
               , FFR_USED_IN_PRECALC_FIN
               , A_DATECRE
               , A_IDCRE
                )
      select aNewFAL_FACTORY_RATE_ID
           , FFR.FAL_FACTORY_FLOOR_ID
           , FFR.FFR_RATE1
           , FFR.FFR_RATE2
           , FFR.FFR_RATE3
           , FFR.FFR_RATE4
           , FFR.FFR_RATE5
           , trunc(aNewDate)
           , 0
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from FAL_FACTORY_RATE FFR
       where FFR.FAL_FACTORY_RATE_ID = aFAL_FACTORY_RATE_ID;

    if aDuplicateDecomposition = 1 then
      insert into FAL_FACT_RATE_DECOMP
                  (FAL_FACT_RATE_DECOMP_ID
                 , C_COST_TYPE
                 , DIC_FACT_RATE_DESCR_ID
                 , DIC_FACT_RATE_FREE1_ID
                 , DIC_FACT_RATE_FREE2_ID
                 , DIC_FACT_RATE_FREE3_ID
                 , DIC_FACT_RATE_FREE4_ID
                 , FRD_RATE_NUMBER
                 , FRD_VALUE
                 , FRD_RATE
                 , A_DATECRE
                 , A_IDCRE
                 , FAL_FACTORY_RATE_ID
                  )
        select GetNewId
             , FRD.C_COST_TYPE
             , FRD.DIC_FACT_RATE_DESCR_ID
             , FRD.DIC_FACT_RATE_FREE1_ID
             , FRD.DIC_FACT_RATE_FREE2_ID
             , FRD.DIC_FACT_RATE_FREE3_ID
             , FRD.DIC_FACT_RATE_FREE4_ID
             , FRD.FRD_RATE_NUMBER
             , FRD.FRD_VALUE
             , FRD.FRD_RATE
             , sysdate
             , PCS.PC_I_LIB_SESSION.GETUSERINI
             , aNewFAL_FACTORY_RATE_ID
          from FAL_FACT_RATE_DECOMP FRD
         where FAL_FACTORY_RATE_ID = aFAL_FACTORY_RATE_ID;
    end if;
  end;

  /**
  * procedure CheckDecompositionSum
  * Description : Vérification de l'intégrité de décompositions d'un taux
  *               Somme des pourcentages <= à 100
  *               et Somme des valeurs = Taux correspondant.
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_RATE_ID : Taux à vérifier.
  * @param   aFRD_RATE_NUMBER : N° du taux (1,2,3...)
  * @param   aNewRatePercent : Pourcentage souhaité pour la nouvelle rubrique
  * @param   aNewRateValue : Valeur souhaité pour la nouvelle rubrique
  * @param   aFAL_FACT_RATE_DECOMP_ID : Ligne de décomposition en cours de modification
  * @return  aErrorCode :
  */
  procedure CheckDecompositionSum(
    aFAL_FACTORY_RATE_ID     in     number
  , aFRD_RATE_NUMBER         in     integer
  , aNewRatePercent          in     number
  , aNewRateValue            in     number
  , aFAL_FACT_RATE_DECOMP_ID in     number
  , aErrorCode               in out integer
  )
  is
    aRateValue  number;
    aValueSum   number;
    aPercentSum number;
  begin
    aRateValue   := 0;
    aValueSum    := 0;
    aPercentSum  := 0;

    select   (case
                when aFRD_RATE_NUMBER = 1 then FFR.FFR_RATE1
                when aFRD_RATE_NUMBER = 2 then FFR.FFR_RATE2
                when aFRD_RATE_NUMBER = 3 then FFR.FFR_RATE3
                when aFRD_RATE_NUMBER = 4 then FFR.FFR_RATE4
                when aFRD_RATE_NUMBER = 5 then FFR.FFR_RATE5
                else 0
              end
             ) FFR_RATE
           , sum(DECOMP.FRD_VALUE) VALUE_SUM
           , sum(DECOMP.FRD_RATE) PERCENT_SUM
        into aRateValue
           , aValueSum
           , aPercentSum
        from FAL_FACTORY_RATE FFR
           , FAL_FACT_RATE_DECOMP DECOMP
       where FFR.FAL_FACTORY_RATE_ID = aFAL_FACTORY_RATE_ID
         and (   aFAL_FACT_RATE_DECOMP_ID is null
              or (    aFAL_FACT_RATE_DECOMP_ID is not null
                  and DECOMP.FAL_FACT_RATE_DECOMP_ID <> aFAL_FACT_RATE_DECOMP_ID) )
         and FFR.FAL_FACTORY_RATE_ID = DECOMP.FAL_FACTORY_RATE_ID
         and DECOMP.FRD_RATE_NUMBER = aFRD_RATE_NUMBER
    group by (case
                when aFRD_RATE_NUMBER = 1 then FFR.FFR_RATE1
                when aFRD_RATE_NUMBER = 2 then FFR.FFR_RATE2
                when aFRD_RATE_NUMBER = 3 then FFR.FFR_RATE3
                when aFRD_RATE_NUMBER = 4 then FFR.FFR_RATE4
                when aFRD_RATE_NUMBER = 5 then FFR.FFR_RATE5
                else 0
              end
             );

    aValueSum    := aValueSum + nvl(aNewRateValue, 0);
    aPercentSum  := aPercentSum + nvl(aNewRatePercent, 0);

    -- Somme des rubriques supérieure à 100% et Somme des valeurs
    -- (Test ET pour eviter le problème d'arrondi suivant que les taux sont saisi en pourcentages ou en valeur)
    if     (aPercentSum > 100)
       and (aValueSum <> aRateValue) then
      aErrorCode  := 1;
    else
      aErrorCode  := 0;
    end if;
  exception
    when others then
      aErrorCode  := 0;
  end;

  /**
  * procedure UpdateRateWithDecomposition
  * Description : Mise à jour d'un taux via sa décomposition.
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_RATE_ID : Taux à vérifier.
  * @param   aFRD_RATE_NUMBER : N° du taux (1,2,3...)
  */
  procedure UpdateRateWithDecomposition(aFAL_FACTORY_RATE_ID number, aFRD_RATE_NUMBER integer)
  is
    aUpdtQry varchar2(2000);
  begin
    -- MAJ du champs Taux correspondant
    aUpdtQry  :=
      ' update FAL_FACTORY_RATE FFR ' ||
      '    set FFR_RATE' ||
      aFRD_RATE_NUMBER ||
      ' = (select sum(FRD.FRD_VALUE) ' ||
      '                                                from FAL_FACT_RATE_DECOMP FRD ' ||
      '                                               where FRD.FAL_FACTORY_RATE_ID = :aFAL_FACTORY_RATE_ID ' ||
      '                                                 and FRD.FRD_RATE_NUMBER = :aFRD_RATE_NUMBER) ' ||
      '  where FAL_FACTORY_RATE_ID = :aFAL_FACTORY_RATE_ID ';

    execute immediate aUpdtQry
                using aFAL_FACTORY_RATE_ID, aFRD_RATE_NUMBER, aFAL_FACTORY_RATE_ID;

    -- Recalcul des %ages de décomposition correspondant
    aUpdtQry  :=
      ' update FAL_FACT_RATE_DECOMP FRD ' ||
      '    set FRD.FRD_RATE = (FRD.FRD_VALUE / (select FFR.FFR_RATE' ||
      aFRD_RATE_NUMBER ||
      '                                           from FAL_FACTORY_RATE FFR ' ||
      '                                          where FFR.FAL_FACTORY_RATE_ID = :aFAL_FACTORY_RATE_ID) * 100) ' ||
      '  where FRD.FAL_FACTORY_RATE_ID = :aFAL_FACTORY_RATE_ID ' ||
      '    and FRD.FRD_RATE_NUMBER = :aFRD_RATE_NUMBER ';

    execute immediate aUpdtQry
                using aFAL_FACTORY_RATE_ID, aFAL_FACTORY_RATE_ID, aFRD_RATE_NUMBER;
  exception
    when others then
      raise;
  end;

  /**
  * procedure UpdateDecompositionWithRate
  * Description : Mise à jour de la décomposition d'un taux via son taux.
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_RATE_ID : Taux à vérifier.
  * @param   aFRD_RATE_NUMBER : N° du taux (1,2,3...)
  */
  procedure UpdateDecompositionWithRate(aFAL_FACTORY_RATE_ID number)
  is
    aUpdtQry varchar2(2000);
    RateNum  integer;
  begin
    RateNum  := 1;

    loop
      exit when RateNum > 5;
      aUpdtQry  :=
        ' update FAL_FACT_RATE_DECOMP FRD ' ||
        '    set FRD.FRD_VALUE = (FRD.FRD_RATE * (select FFR.FFR_RATE' ||
        RateNum ||
        '                                           from FAL_FACTORY_RATE FFR ' ||
        '                                          where FFR.FAL_FACTORY_RATE_ID = :aFAL_FACTORY_RATE_ID) / 100) ' ||
        '  where FRD.FAL_FACTORY_RATE_ID = :aFAL_FACTORY_RATE_ID ' ||
        '    and FRD.FRD_RATE_NUMBER = :aRateNum';

      execute immediate aUpdtQry
                  using aFAL_FACTORY_RATE_ID, aFAL_FACTORY_RATE_ID, RateNum;

      RateNum   := RateNum + 1;
    end loop;
  exception
    when others then
      raise;
  end;

  /**
  * procedure InsertOrUpdateAccount
  * Description : Génération ou mise à jour d'un compte
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_FLOOR_ID : Atelier
  * @param   aDOC_RECORD_ID : Dossier
  * @param   aACS_CDA_ACCOUNT_ID : Centre d'analyse
  * @param   aACS_FINANCIAL_ACCOUNT_ID : Compte
  * @param   aACS_DIVISION_ACCOUNT_ID : Division
  * @param   aACS_CPN_ACCOUNT_ID : Charge par nature
  * @param   aACS_PF_ACCOUNT_ID : Porteur
  * @param   aACS_PJ_ACCOUNT_ID : Projet
  * @param   aACS_QTY_UNIT_ID : Quantité
  * @param   aC_FAL_ENTRY_TYPE : Type de l'imputation
  * @param   aC_FAL_ENTRY_SIGN : Signe de l'imputation
  */
  procedure InsertOrUpdateAccount(
    aFAL_FACTORY_FLOOR_ID     number
  , aC_FAL_ENTRY_TYPE         varchar2
  , aC_FAL_ENTRY_SIGN         varchar2
  , aDOC_RECORD_ID            number
  , aACS_CDA_ACCOUNT_ID       number
  , aACS_FINANCIAL_ACCOUNT_ID number
  , aACS_DIVISION_ACCOUNT_ID  number
  , aACS_CPN_ACCOUNT_ID       number
  , aACS_PF_ACCOUNT_ID        number
  , aACS_PJ_ACCOUNT_ID        number
  , aACS_QTY_UNIT_ID          number
  )
  is
    StrUpdtQry      varchar2(2000);
    aUpdatedAccount number;
  begin
    StrUpdtQry  :=
      ' update FAL_FACTORY_ACCOUNTS ' ||
      '    set DOC_RECORD_ID = :aDOC_RECORD_ID ' ||
      '      , ACS_CDA_ACCOUNT_ID = :aACS_CDA_ACCOUNT_ID ' ||
      '      , ACS_FINANCIAL_ACCOUNT_ID = :aACS_FINANCIAL_ACCOUNT_ID ' ||
      '      , ACS_DIVISION_ACCOUNT_ID = :aACS_DIVISION_ACCOUNT_ID ' ||
      '      , ACS_CPN_ACCOUNT_ID = :aACS_CPN_ACCOUNT_ID ' ||
      '      , ACS_PF_ACCOUNT_ID = :aACS_PF_ACCOUNT_ID ' ||
      '      , ACS_PJ_ACCOUNT_ID = :aACS_PJ_ACCOUNT_ID ' ||
      '      , ACS_QTY_UNIT_ID = :aACS_QTY_UNIT_ID ' ||
      '      , A_DATEMOD = sysdate ' ||
      '      , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI ' ||
      '  where FAL_FACTORY_FLOOR_ID = :aFAL_FACTORY_FLOOR_ID ' ||
      '    and C_FAL_ENTRY_TYPE = :aC_FAL_ENTRY_TYPE ' ||
      '    and C_FAL_ENTRY_SIGN = :aC_FAL_ENTRY_SIGN ' ||
      ' returning FAL_FACTORY_ACCOUNT_ID into :aUpdatedAccount ';

    execute immediate StrUpdtQry
                using aDOC_RECORD_ID
                    , aACS_CDA_ACCOUNT_ID
                    , aACS_FINANCIAL_ACCOUNT_ID
                    , aACS_DIVISION_ACCOUNT_ID
                    , aACS_CPN_ACCOUNT_ID
                    , aACS_PF_ACCOUNT_ID
                    , aACS_PJ_ACCOUNT_ID
                    , aACS_QTY_UNIT_ID
                    , aFAL_FACTORY_FLOOR_ID
                    , aC_FAL_ENTRY_TYPE
                    , aC_FAL_ENTRY_SIGN
       returning into aUpdatedAccount;

    if aUpdatedAccount is null then
      insert into FAL_FACTORY_ACCOUNT
                  (FAL_FACTORY_ACCOUNT_ID
                 , FAL_FACTORY_FLOOR_ID
                 , DOC_RECORD_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , ACS_QTY_UNIT_ID
                 , C_FAL_ENTRY_TYPE
                 , C_FAL_ENTRY_SIGN
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aFAL_FACTORY_FLOOR_ID
                 , aDOC_RECORD_ID
                 , aACS_CDA_ACCOUNT_ID
                 , aACS_FINANCIAL_ACCOUNT_ID
                 , aACS_DIVISION_ACCOUNT_ID
                 , aACS_CPN_ACCOUNT_ID
                 , aACS_PF_ACCOUNT_ID
                 , aACS_PJ_ACCOUNT_ID
                 , aACS_QTY_UNIT_ID
                 , aC_FAL_ENTRY_TYPE
                 , aC_FAL_ENTRY_SIGN
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end;

  /**
  * function AccountExists
  * Description : Indique l'existance d'un compte pour un atelier
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_FLOOR_ID : Atelier
  * @param   aC_FAL_ENTRY_TYPE : Type de l'imputation
  * @param   aC_FAL_ENTRY_SIGN : Signe de l'imputation
  * @return  integer
  */
  procedure AccountExists(aFAL_FACTORY_FLOOR_ID in number, aC_FAL_ENTRY_TYPE in varchar2, aC_FAL_ENTRY_SIGN in varchar2, aExists in out integer)
  is
  begin
    select 1
      into aExists
      from FAL_FACTORY_ACCOUNT FFA
     where FFA.FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID
       and FFA.C_FAL_ENTRY_TYPE = aC_FAL_ENTRY_TYPE
       and FFA.C_FAL_ENTRY_SIGN = aC_FAL_ENTRY_SIGN;
  exception
    when no_data_found then
      aExists  := 0;
  end AccountExists;

  /**
  * procedure GetFreeIlotRessource
  * Description : Recherche du nombre de ressource libre d'un ilot
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_FLOOR_ID : ID ilot
  * @return  aNbFreeRessource : Nbre de ressources libres
  */
  procedure GetFreeIlotRessource(aFAL_FACTORY_FLOOR_ID in number, aNbFreeRessource in out integer)
  is
  begin
    select nvl(ILOT.FAC_RESOURCE_NUMBER, 0) - nvl( (select count(*)
                                                      from FAL_FACTORY_FLOOR MACHINE
                                                     where MACHINE.FAL_FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID), 0)
      into aNbFreeRessource
      from FAL_FACTORY_FLOOR ILOT
     where ILOT.FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID;
  exception
    when others then
      aNbFreeRessource  := 0;
  end GetFreeIlotRessource;

  /**
  * procedure DuplicateAccounts
  * Description : Duplication des comptes d'ateliers
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aSrcFAL_FACTORY_FLOOR_ID : Atelier Source
  * @param   aDestFAL_FACTORY_FLOOR_ID : Atelier Cible
  */
  procedure DuplicateAccounts(aSrcFAL_FACTORY_FLOOR_ID in number, aDestFAL_FACTORY_FLOOR_ID in out number)
  is
  begin
    insert into FAL_FACTORY_ACCOUNT
                (FAL_FACTORY_ACCOUNT_ID
               , FAL_FACTORY_FLOOR_ID
               , DOC_RECORD_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_QTY_UNIT_ID
               , C_FAL_ENTRY_TYPE
               , C_FAL_ENTRY_SIGN
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , aDestFAL_FACTORY_FLOOR_ID
           , DOC_RECORD_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_QTY_UNIT_ID
           , C_FAL_ENTRY_TYPE
           , C_FAL_ENTRY_SIGN
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_FACTORY_ACCOUNT
       where FAL_FACTORY_FLOOR_ID = aSrcFAL_FACTORY_FLOOR_ID;
  end DuplicateAccounts;

  /**
  * procedure DuplicateRates
  * Description : Duplication des taux d'ateliers (ceux encore valables)
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aSrcFAL_FACTORY_FLOOR_ID : Atelier Source
  * @param   aDestFAL_FACTORY_FLOOR_ID : Atelier Cible
  */
  procedure DuplicateRates(aSrcFAL_FACTORY_FLOOR_ID in number, aDestFAL_FACTORY_FLOOR_ID in out number)
  is
    cursor crSrcRates
    is
      select *
        from fal_factory_rate ffr1
       where ffr1.fal_factory_floor_id = aSrcFAL_FACTORY_FLOOR_ID
         and trunc(ffr1.ffr_validity_date) >= (select trunc(ffr_validity_date)
                                                 from fal_factory_rate ffr2
                                                where fal_factory_rate_id = FAL_FACT_FLOOR.GetCurrentRate(aSrcFAL_FACTORY_FLOOR_ID) );

    aNewFAL_FACTORY_RATE_ID number;
    tplSrcRates             crSrcRates%rowtype;
  begin
    for tplSrcRates in crSrcRates loop
      aNewFAL_FACTORY_RATE_ID  := GetNewId;

      insert into FAL_FACTORY_RATE
                  (FAL_FACTORY_RATE_ID
                 , FAL_FACTORY_FLOOR_ID
                 , FFR_RATE1
                 , FFR_RATE2
                 , FFR_RATE3
                 , FFR_RATE4
                 , FFR_RATE5
                 , FFR_VALIDITY_DATE
                 , FFR_USED_IN_PRECALC_FIN
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aNewFAL_FACTORY_RATE_ID
                 , aDestFAL_FACTORY_FLOOR_ID
                 , tplSrcRates.FFR_RATE1
                 , tplSrcRates.FFR_RATE2
                 , tplSrcRates.FFR_RATE3
                 , tplSrcRates.FFR_RATE4
                 , tplSrcRates.FFR_RATE5
                 , tplSrcRates.FFR_VALIDITY_DATE
                 , 0
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  );

      insert into FAL_FACT_RATE_DECOMP
                  (FAL_FACT_RATE_DECOMP_ID
                 , C_COST_TYPE
                 , DIC_FACT_RATE_DESCR_ID
                 , DIC_FACT_RATE_FREE1_ID
                 , DIC_FACT_RATE_FREE2_ID
                 , DIC_FACT_RATE_FREE3_ID
                 , DIC_FACT_RATE_FREE4_ID
                 , FRD_RATE_NUMBER
                 , FRD_VALUE
                 , FRD_RATE
                 , A_DATECRE
                 , A_IDCRE
                 , FAL_FACTORY_RATE_ID
                  )
        select GetNewId
             , FRD.C_COST_TYPE
             , FRD.DIC_FACT_RATE_DESCR_ID
             , FRD.DIC_FACT_RATE_FREE1_ID
             , FRD.DIC_FACT_RATE_FREE2_ID
             , FRD.DIC_FACT_RATE_FREE3_ID
             , FRD.DIC_FACT_RATE_FREE4_ID
             , FRD.FRD_RATE_NUMBER
             , FRD.FRD_VALUE
             , FRD.FRD_RATE
             , sysdate
             , PCS.PC_I_LIB_SESSION.GETUSERINI
             , aNewFAL_FACTORY_RATE_ID
          from FAL_FACT_RATE_DECOMP FRD
         where FAL_FACTORY_RATE_ID = tplSrcRates.FAL_FACTORY_RATE_ID;
    end loop;
  end;

  /**
  * procedure GetDateRateValues
  * Description : Recherche d'un taux à date, pour une date donnée
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_FLOOR_ID : ID de la ressource
  * @param   aValidityDate : Date de recherche
  * @return  aFFR_RATE1 : TauxHoraire1
  * @return  aFFR_RATE2 : TauxHoraire2
  * @return  aFFR_RATE3 : TauxHoraire3
  * @return  aFFR_RATE4 : TauxHoraire4
  * @return  aFFR_RATE5 : TauxHoraire5
  */
  procedure GetDateRateValues(
    aFAL_FACTORY_FLOOR_ID in     number
  , aValidityDate         in     date default sysdate
  , aFFR_RATE1            in out number
  , aFFR_RATE2            in out number
  , aFFR_RATE3            in out number
  , aFFR_RATE4            in out number
  , aFFR_RATE5            in out number
  )
  is
  begin
    select nvl(ffr.ffr_rate1, 0)
         , nvl(ffr.ffr_rate2, 0)
         , nvl(ffr.ffr_rate3, 0)
         , nvl(ffr.ffr_rate4, 0)
         , nvl(ffr.ffr_rate5, 0)
      into aFFR_RATE1
         , aFFR_RATE2
         , aFFR_RATE3
         , aFFR_RATE4
         , aFFR_RATE5
      from fal_factory_rate ffr
     where ffr.fal_factory_floor_id = aFAL_FACTORY_FLOOR_ID
       and trunc(ffr.ffr_validity_date) = (select max(trunc(ffr2.ffr_validity_date) )
                                             from fal_factory_rate ffr2
                                            where trunc(ffr2.ffr_validity_date) <= trunc(aValidityDate)
                                              and ffr2.fal_factory_floor_id = aFAL_FACTORY_FLOOR_ID);
  exception
    when no_data_found then
      begin
        aFFR_RATE1  := 0;
        aFFR_RATE2  := 0;
        aFFR_RATE3  := 0;
        aFFR_RATE4  := 0;
        aFFR_RATE5  := 0;
      end;
  end;

  /**
  * function GetDateRateValue
  * Description : Recherche d'un taux à date, pour une date donnée
  *               par son numéro.
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_FLOOR_ID : ID de la ressource
  * @param   aValidityDate : Date de recherche
  * @return  Taux horaire
  */
  function GetDateRateValue(aFAL_FACTORY_FLOOR_ID in number, aValidityDate in date default sysdate, aRateNumber integer default 1)
    return number
  is
    aFFR_RATE1 number;
    aFFR_RATE2 number;
    aFFR_RATE3 number;
    aFFR_RATE4 number;
    aFFR_RATE5 number;
  begin
    FAL_FACT_FLOOR.GetDateRateValues(aFAL_FACTORY_FLOOR_ID, aValidityDate, aFFR_RATE1, aFFR_RATE2, aFFR_RATE3, aFFR_RATE4, aFFR_RATE5);
    return(case
             when aRateNumber = 1 then aFFR_RATE1
             when aRateNumber = 2 then aFFR_RATE2
             when aRateNumber = 3 then aFFR_RATE3
             when aRateNumber = 4 then aFFR_RATE4
             when aRateNumber = 5 then aFFR_RATE5
             else 0
           end
          );
  exception
    when others then
      return 0;
  end;

  /**
  * procedure AddMachineInLMU
  * Description : Ajout de la machine dans les listes de machines utilisables
  *   des opérations de gamme liés à l'îlot de la machine
  *
  * @created CLE
  * @lastUpdate
  * @public
  *
  * @param   aFAL_FACTORY_FLOOR_ID : ID de la machine
  */
  procedure AddMachineInLMU(aFAL_FACTORY_FLOOR_ID in number)
  is
  begin
    insert into FAL_LIST_STEP_USE
                (FAL_LIST_STEP_USE_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_SCHEDULE_STEP_ID
               , LSU_WORK_TIME
               , LSU_QTY_REF_WORK
               , LSU_PRIORITY
               , LSU_EXCEPT_MACH
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , aFAL_FACTORY_FLOOR_ID
           , FAL_SCHEDULE_STEP_ID
           , SCS_WORK_TIME
           , SCS_QTY_REF_WORK
           , 100
           , 0
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_LIST_STEP_LINK
       where FAL_FACTORY_FLOOR_ID = (select FAL_FAL_FACTORY_FLOOR_ID
                                       from FAL_FACTORY_FLOOR
                                      where FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID);
  end;

  /**
  * procedure CheckHierarchyIntegrity
  * Description : Vérification de l'intégrité père -> Fils des resources suivant les règles métier suivantes :
  *                  . Un Ilot ou un Groupe d'opérateur ne peuvent être fils d'une autre ressource,
  *                    et est père de 0 à n ressources
  *                  . Une machine ou un opérateur ne peuvent être fils de 0 ou 1 îlot
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iFAC_IS_BLOCK             : Ilot (fils)
  * @param   iFAC_IS_MACHINE           : Machine (fils)
  * @param   iFAC_IS_OPERATOR          : Groupe d'Operateur (fils)
  * @param   iFAC_IS_PERSON            : Operateur / Personne (fils)
  * @param   iFAL_FAL_FACTORY_FLOOR_ID : Ilot père (fils)
  * @param   iFAL_GRP_FACTORY_FLOOR_ID : Groupe d'opérateur père (fils)
  * @param   oResult                   : 1 => Intégrité respectée, 0 sinon
  * @param   oMsg                      : Message d'avertissement éventuel
  */
  procedure CheckHierarchyIntegrity(
    iFAC_IS_BLOCK             in     FAL_FACTORY_FLOOR.FAC_IS_BLOCK%type
  , iFAC_IS_MACHINE           in     FAL_FACTORY_FLOOR.FAC_IS_MACHINE%type
  , iFAC_IS_OPERATOR          in     FAL_FACTORY_FLOOR.FAC_IS_OPERATOR%type
  , iFAC_IS_PERSON            in     FAL_FACTORY_FLOOR.FAC_IS_PERSON%type
  , iFAL_FAL_FACTORY_FLOOR_ID in     FAL_FACTORY_FLOOR.FAL_FAL_FACTORY_FLOOR_ID%type
  , iFAL_GRP_FACTORY_FLOOR_ID in     FAL_FACTORY_FLOOR.FAL_GRP_FACTORY_FLOOR_ID%type
  , ioResult                  in out integer
  , ioMsg                     in out varchar2
  )
  is
    liFatherIsBlock    integer;
    liFatherIsMachine  integer;
    liFatherIsOPerator integer;
    liFatherIsPerson   integer;
  begin
    -- Sélection des caracteristiques du Père potentiel
    begin
      select FATHER.FAC_IS_BLOCK
           , FATHER.FAC_IS_MACHINE
           , FATHER.FAC_IS_OPERATOR
           , FATHER.FAC_IS_PERSON
        into liFatherIsBlock
           , liFatherIsMachine
           , liFatherIsOPerator
           , liFatherIsPerson
        from FAL_FACTORY_FLOOR FATHER
       where FATHER.FAL_FACTORY_FLOOR_ID = nvl(iFAL_FAL_FACTORY_FLOOR_ID, 0)
          or FATHER.FAL_FACTORY_FLOOR_ID = nvl(iFAL_GRP_FACTORY_FLOOR_ID, 0);
    exception
      when no_data_found then
        begin
          liFatherIsBlock     := 0;
          liFatherIsMachine   := 0;
          liFatherIsOPerator  := 0;
          liFatherIsPerson    := 0;
        end;
    end;

    ioResult  := 1;

    -- Ilot sur une autre ressource
    if     iFAC_IS_BLOCK = 1
       and (   nvl(iFAL_FAL_FACTORY_FLOOR_ID, 0) <> 0
            or nvl(iFAL_GRP_FACTORY_FLOOR_ID, 0) <> 0) then
      ioMsg     := PCS.PC_FUNCTIONS.TRANSLATEWORD('Un îlot ne peut appartenir à un autre îlot ou a un groupe d''opérateurs.');
      ioResult  := 0;
    -- Groupe d'opérateur sur une autre ressource
    elsif     iFAC_IS_OPERATOR = 1
          and (   nvl(iFAL_FAL_FACTORY_FLOOR_ID, 0) <> 0
               or nvl(iFAL_GRP_FACTORY_FLOOR_ID, 0) <> 0) then
      ioMsg     := PCS.PC_FUNCTIONS.TRANSLATEWORD('Un groupe d''opérateurs ne peut appartenir à un autre groupe d''opérateur ou à un îlot.');
      ioResult  := 0;
    -- Machine sur une machine, un opérateur ou un groupe d'opérateur
    elsif     iFAC_IS_MACHINE = 1
          and (   liFatherIsMachine = 1
               or liFatherIsOperator = 1
               or liFatherIsPerson = 1) then
      ioMsg     := PCS.PC_FUNCTIONS.TRANSLATEWORD('Une machine ne peut appartenir qu''à un îlot.');
      ioResult  := 0;
    -- Opérateur / Personne sur une machine, un opérateur, ou un ilot
    elsif     iFAC_IS_PERSON = 1
          and (   liFatherIsMachine = 1
               or liFatherIsBlock = 1
               or liFatherIsPerson = 1) then
      ioMsg     := PCS.PC_FUNCTIONS.TRANSLATEWORD('Un opérateur ne peut appartenir qu''à un groupe d''opérateur.');
      ioResult  := 0;
    end if;
  end CheckHierarchyIntegrity;
end;
