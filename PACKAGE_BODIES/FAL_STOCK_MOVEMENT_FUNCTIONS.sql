--------------------------------------------------------
--  DDL for Package Body FAL_STOCK_MOVEMENT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_STOCK_MOVEMENT_FUNCTIONS" 
is
  function GetFalLotMatlLinkFromComp(aFAL_COMPONENT_LINK_ID number)
    return number
  is
    aFAL_LOT_MATERIAL_LINK_ID number;
  begin
    aFAL_LOT_MATERIAL_LINK_ID  := null;

    select flm.FAL_LOT_MATERIAL_LINK_ID
      into aFAL_LOT_MATERIAL_LINK_ID
      from fal_component_link fcl
         , fal_lot_mat_link_tmp flm
     where fcl.fal_component_link_id = aFAL_COMPONENT_LINK_ID
       and fcl.fal_lot_mat_link_tmp_id = flm.fal_lot_mat_link_tmp_id;

    return aFAL_LOT_MATERIAL_LINK_ID;
  exception
    when no_data_found then
      return null;
  end;

  function GetFalLotMatLinkFromNetlink(aFAL_NETWORK_LINK_ID number)
    return number
  is
    aFAL_LOT_MATERIAL_LINK_ID number;
  begin
    aFAL_LOT_MATERIAL_LINK_ID  := null;

    select fnn.FAL_LOT_MATERIAL_LINK_ID
      into aFAL_LOT_MATERIAL_LINK_ID
      from fal_network_link fnl
         , fal_network_need fnn
     where fnl.fal_network_link_id = aFAL_NETWORK_LINK_ID
       and fnl.fal_network_need_id = fnn.fal_network_need_id;

    return aFAL_LOT_MATERIAL_LINK_ID;
  exception
    when no_data_found then
      return null;
  end;

  function GetFalLotMatLinkFromFalFactIn(aFAL_FACTORY_IN_ID number)
    return number
  is
    aFAL_LOT_MATERIAL_LINK_ID number;
  begin
    aFAL_LOT_MATERIAL_LINK_ID  := null;

    select FIN.FAL_LOT_MATERIAL_LINK_ID
      into aFAL_LOT_MATERIAL_LINK_ID
      from FAL_FACTORY_IN FIN
     where FIN.FAL_FACTORY_IN_ID = aFAL_FACTORY_IN_ID;

    return aFAL_LOT_MATERIAL_LINK_ID;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * procedure GetConfigData
  * description : Recherche du compte financier et du compte division de bilan
  *               au niveau des configurations.
  * @created ECA
  * @lastUpdate
  * @private
  * @param     aFinancialAccountID  Compte financier de bilan
  * @param     aDivisionAccountID   Compte division de bialn
  */
  procedure GetConfigData(aFinancialAccountID in out number, aDivisionAccountID in out number)
  is
  begin
    if nvl(aFinancialAccountID, 0) = 0 then
      select max(ACS_ACCOUNT_ID)
        into aFinancialAccountID
        from ACS_ACCOUNT ACC
           , ACS_FINANCIAL_ACCOUNT FIN
       where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and ACC_NUMBER = PCS.PC_CONFIG.GetConfig('FIN_LG_STOCK_FINANCIAL_ACCOUNT');
    end if;

    if nvl(aDivisionAccountID, 0) = 0 then
      select max(ACS_ACCOUNT_ID)
        into aDivisionAccountID
        from ACS_ACCOUNT ACC
           , ACS_DIVISION_ACCOUNT DIV
       where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
         and ACC_NUMBER = PCS.PC_CONFIG.GetConfig('FIN_LG_STOCK_DIVISION_ACCOUNT');
    end if;
  end;

  /**
  * function InitPreparedStockMovement
  * description : initialisation de LocPreparedStockMovements (Pour utilisation des fct depuis delphi)
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure InitPreparedStockMovement
  is
  begin
    LocPreparedStockMovements  := TPreparedStockMovements();
  end;

  /**
  * Procedure : addPreparedStockMovements
  * Description : Ajout d'un enregistrement PreparedStockMovements
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param    aPreparedStockMovement   Tableau des mouvements de stock.
  * @param    aFAL_LOT_ID              Lot de fabrication
  * @param    aGCO_GOOD_ID             Produit
  * @param    aSTM_STOCK_ID            stock
  * @param    aSTM_LOCATION_ID         Emplacement
  * @param    aOUT_QUANTITY            Quantité
  * @param    aLOM_PRICE               Prix du mouvement
  * @param    aOUTDATE                 Date du mouvement
  * @param    aMvtKind                 Type de mouvement (Cf pkg_FAL_STOCK_MOVEMENT_FUNCTIONS)
  * @param    GCO_CHARACTERIZATION1_ID...GCO_CHARACTERIZATION1_ID   ID des charactérisations
  * @param    CHARACT_VALUE1...CHARACT_VALUE5 Valeurs des charactérisations
  * @param    FAL_COMPONENT_LINK_ID    Lien de composant générateur de la sortie vers atelier
  * @param    aFAL_FACTORY_IN_ID       Lien d'entrée stock atelier du composant du lot
  * @param    aFAL_FACTORY_OUT_ID      Lien de sortie stock atelier du composant du lot
  * @param    aFactoryInOriginId       Entrée atelier à l'origine du mouvement
  * @param    aFAL_LOT_MATERIAL_LINK_ID Composant
  */
  procedure addPreparedStockMovements(
    aPreparedStockMovements   in out TPreparedStockMovements
  , aFAL_LOT_ID               in     number
  , aGCO_GOOD_ID              in     number
  , aSTM_STOCK_ID             in     number
  , aSTM_LOCATION_ID          in     number
  , aOUT_QUANTITY             in     number
  , aLOM_PRICE                in     number
  , aOUT_DATE                 in     date
  , aMvtKind                  in     integer
  , aGCO_CHARACTERIZATION1_ID in     number default null
  , aGCO_CHARACTERIZATION2_ID in     number default null
  , aGCO_CHARACTERIZATION3_ID in     number default null
  , aGCO_CHARACTERIZATION4_ID in     number default null
  , aGCO_CHARACTERIZATION5_ID in     number default null
  , aCHARACT_VALUE1           in     varchar2 default null
  , aCHARACT_VALUE2           in     varchar2 default null
  , aCHARACT_VALUE3           in     varchar2 default null
  , aCHARACT_VALUE4           in     varchar2 default null
  , aCHARACT_VALUE5           in     varchar2 default null
  , aFAL_COMPONENT_LINK_ID    in     number default null
  , aFAL_FACTORY_IN_ID        in     number default null
  , aFAL_FACTORY_OUT_ID       in     number default null
  , aFAL_NETWORK_LINK_ID      in     number default null
  , aFactoryInOriginId        in     number default null
  , aFAL_LOT_MATERIAL_LINK_ID in     number default null
  )
  is
    aLastIndex integer;
  begin
    aPreparedStockMovements.extend;
    aLastIndex                                                  := aPreparedStockMovements.last;
    aPreparedStockMovements(aLastIndex).LotID                   := aFAL_LOT_ID;
    aPreparedStockMovements(aLastIndex).GoodID                  := aGCO_GOOD_ID;
    aPreparedStockMovements(aLastIndex).StockID                 := aSTM_STOCK_ID;
    aPreparedStockMovements(aLastIndex).LocationID              := aSTM_LOCATION_ID;
    aPreparedStockMovements(aLastIndex).MvtQty                  := aOUT_QUANTITY;
    aPreparedStockMovements(aLastIndex).GoodPrice               := aLOM_PRICE;
    aPreparedStockMovements(aLastIndex).MvtDate                 := nvl(aOUT_DATE, sysdate);
    aPreparedStockMovements(aLastIndex).MvtKindType             := aMvtKind;
    aPreparedStockMovements(aLastIndex).Characterization1ID     := aGCO_CHARACTERIZATION1_ID;
    aPreparedStockMovements(aLastIndex).Characterization2ID     := aGCO_CHARACTERIZATION2_ID;
    aPreparedStockMovements(aLastIndex).Characterization3ID     := aGCO_CHARACTERIZATION3_ID;
    aPreparedStockMovements(aLastIndex).Characterization4ID     := aGCO_CHARACTERIZATION4_ID;
    aPreparedStockMovements(aLastIndex).Characterization5ID     := aGCO_CHARACTERIZATION5_ID;
    aPreparedStockMovements(aLastIndex).Characterization1Value  := aCHARACT_VALUE1;
    aPreparedStockMovements(aLastIndex).Characterization2Value  := aCHARACT_VALUE2;
    aPreparedStockMovements(aLastIndex).Characterization3Value  := aCHARACT_VALUE3;
    aPreparedStockMovements(aLastIndex).Characterization4Value  := aCHARACT_VALUE4;
    aPreparedStockMovements(aLastIndex).Characterization5Value  := aCHARACT_VALUE5;
    /* AllCharactValues sert a effectuer le tri selon les caractérisations. Ce tri doit être identique
       qu'un "order by" sur les 5 champs correspondants. L'ajout des "z" sert à obtenir le même résultat
       qu'avec les valeurs nulles.
    */
    aPreparedStockMovements(aLastIndex).AllCharactValues        :=
      rpad(nvl(aCHARACT_VALUE1, 'z'), 30, 'z') ||
      rpad(nvl(aCHARACT_VALUE2, 'z'), 30, 'z') ||
      rpad(nvl(aCHARACT_VALUE3, 'z'), 30, 'z') ||
      rpad(nvl(aCHARACT_VALUE4, 'z'), 30, 'z') ||
      rpad(nvl(aCHARACT_VALUE5, 'z'), 30, 'z');

    if aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionRebut then
      aPreparedStockMovements(aLastIndex).MvtPrice  := 0;
    elsif aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionCompensation then
      aPreparedStockMovements(aLastIndex).MvtPrice  := aLOM_PRICE;
    else
      aPreparedStockMovements(aLastIndex).MvtPrice  := aOUT_QUANTITY * aLOM_PRICE;
    end if;

    aPreparedStockMovements(aLastIndex).aFAL_COMPONENT_LINK_ID  := aFAL_COMPONENT_LINK_ID;
    aPreparedStockMovements(aLastIndex).aFAL_NETWORK_LINK_ID    := aFAL_NETWORK_LINK_ID;
    aPreparedStockMovements(aLastIndex).aFAL_FACTORY_IN_ID      := aFAL_FACTORY_IN_ID;
    aPreparedStockMovements(aLastIndex).aFAL_FACTORY_OUT_ID     := aFAL_FACTORY_OUT_ID;
    aPreparedStockMovements(aLastIndex).aFactoryInOriginId      := aFactoryInOriginId;

    if nvl(aFAL_LOT_MATERIAL_LINK_ID, 0) <> 0 then
      aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := aFAL_LOT_MATERIAL_LINK_ID;
    elsif nvl(aFAL_COMPONENT_LINK_ID, 0) <> 0 then
      aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := GetFalLotMatlLinkFromComp(aFAL_COMPONENT_LINK_ID);
    elsif nvl(aFAL_NETWORK_LINK_ID, 0) <> 0 then
      aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := GetFalLotMatLinkFromNetlink(aFAL_NETWORK_LINK_ID);
    elsif nvl(aFactoryInOriginId, 0) <> 0 then
      aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := GetFalLotMatLinkFromFalFactIn(aFactoryInOriginId);
    end if;

    /* Si on réceptionne du rebut, on met à 0 le prix du mouvement précédent
       et on crée un nouveau mouvement avec une qté à 0 et le prix du mouvement
       On aura 2 mouvement :
       - Un mvt  FabRcptReb avec la qté = qté de réception et Prix mvt = 0
       - Un mvt  FabRecept avec la qté = 0 et Prix mvt renseigné
    */
    if aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionRebut then
      aPreparedStockMovements.extend;
      aLastIndex                                                  := aPreparedStockMovements.last;
      aPreparedStockMovements(aLastIndex).LotID                   := aFAL_LOT_ID;
      aPreparedStockMovements(aLastIndex).GoodID                  := aGCO_GOOD_ID;
      aPreparedStockMovements(aLastIndex).StockID                 := aSTM_STOCK_ID;
      aPreparedStockMovements(aLastIndex).LocationID              := aSTM_LOCATION_ID;
      aPreparedStockMovements(aLastIndex).MvtQty                  := 0;
      aPreparedStockMovements(aLastIndex).GoodPrice               := aLOM_PRICE;
      aPreparedStockMovements(aLastIndex).MvtDate                 := nvl(aOUT_DATE, sysdate);
      aPreparedStockMovements(aLastIndex).MvtKindType             := mktReceptionProduitTermine;
      aPreparedStockMovements(aLastIndex).Characterization1ID     := aGCO_CHARACTERIZATION1_ID;
      aPreparedStockMovements(aLastIndex).Characterization2ID     := aGCO_CHARACTERIZATION2_ID;
      aPreparedStockMovements(aLastIndex).Characterization3ID     := aGCO_CHARACTERIZATION3_ID;
      aPreparedStockMovements(aLastIndex).Characterization4ID     := aGCO_CHARACTERIZATION4_ID;
      aPreparedStockMovements(aLastIndex).Characterization5ID     := aGCO_CHARACTERIZATION5_ID;
      aPreparedStockMovements(aLastIndex).Characterization1Value  := aCHARACT_VALUE1;
      aPreparedStockMovements(aLastIndex).Characterization2Value  := aCHARACT_VALUE2;
      aPreparedStockMovements(aLastIndex).Characterization3Value  := aCHARACT_VALUE3;
      aPreparedStockMovements(aLastIndex).Characterization4Value  := aCHARACT_VALUE4;
      aPreparedStockMovements(aLastIndex).Characterization5Value  := aCHARACT_VALUE5;
      aPreparedStockMovements(aLastIndex).AllCharactValues        :=
        rpad(nvl(aCHARACT_VALUE1, 'z'), 30, 'z') ||
        rpad(nvl(aCHARACT_VALUE2, 'z'), 30, 'z') ||
        rpad(nvl(aCHARACT_VALUE3, 'z'), 30, 'z') ||
        rpad(nvl(aCHARACT_VALUE4, 'z'), 30, 'z') ||
        rpad(nvl(aCHARACT_VALUE5, 'z'), 30, 'z');
      aPreparedStockMovements(aLastIndex).MvtPrice                := aOUT_QUANTITY * aLOM_PRICE;
      aPreparedStockMovements(aLastIndex).aFAL_COMPONENT_LINK_ID  := aFAL_COMPONENT_LINK_ID;
      aPreparedStockMovements(aLastIndex).aFAL_FACTORY_IN_ID      := aFAL_FACTORY_IN_ID;
      aPreparedStockMovements(aLastIndex).aFAL_FACTORY_OUT_ID     := aFAL_FACTORY_OUT_ID;

      if nvl(aFAL_LOT_MATERIAL_LINK_ID, 0) <> 0 then
        aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := aFAL_LOT_MATERIAL_LINK_ID;
      elsif nvl(aFAL_COMPONENT_LINK_ID, 0) <> 0 then
        aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := GetFalLotMatlLinkFromComp(aFAL_COMPONENT_LINK_ID);
      elsif nvl(aFAL_NETWORK_LINK_ID, 0) <> 0 then
        aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := GetFalLotMatLinkFromNetlink(aFAL_NETWORK_LINK_ID);
      elsif nvl(aFactoryInOriginId, 0) <> 0 then
        aPreparedStockMovements(aLastIndex).aFAL_LOT_MATERIAL_LINK_ID  := GetFalLotMatLinkFromFalFactIn(aFactoryInOriginId);
      end if;
    end if;
  end;

  /**
  * function DefineProductAlternativQty
  * description : Recherche pour le produit donné, les coefficients de conversion
  *               pour les qtés alternatives et les applique à Qty.
  *               Retourner Vrai si GCO_GOOD_ID trouvé
  * @created ECA
  * @lastUpdate
  * @private
  * @param     aGCO_GOOD_ID          Bien
  * @param     Qty                   Quantité
  * @param     AlternativQty1Used    Utilisation Quantité alternative 1
  * @param     AlternativQty2Used    Utilisation Quantité alternative 2
  * @param     AlternativQty3Used    Utilisation Quantité alternative 3
  * @param     AlternativQty1        Quantité alternative 1
  * @param     AlternativQty2        Quantité alternative 2
  * @param     AlternativQty3        Quantité alternative 3
  */
  procedure DefineProductAlternativQty(
    aGCO_GOOD_ID              number
  , Qty                       number
  , AlternativQty1Used in out boolean
  , AlternativQty2Used in out boolean
  , AlternativQty3Used in out boolean
  , AlternativQty1     in out number
  , AlternativQty2     in out number
  , AlternativQty3     in out number
  )
  is
    PdtAlternativQty1    number;
    PdtAlternativQty2    number;
    PdtAlternativQty3    number;
    PdtConversionFactor1 number;
    PdtConversionFactor2 number;
    PdtConversionFactor3 number;
  begin
    AlternativQty1Used  := false;
    AlternativQty2Used  := false;
    AlternativQty3Used  := false;
    AlternativQty1      := 0;
    AlternativQty2      := 0;
    AlternativQty3      := 0;

    select PDT_ALTERNATIVE_QUANTITY_1
         , PDT_ALTERNATIVE_QUANTITY_2
         , PDT_ALTERNATIVE_QUANTITY_3
         , PDT_CONVERSION_FACTOR_1
         , PDT_CONVERSION_FACTOR_2
         , PDT_CONVERSION_FACTOR_3
      into PdtAlternativQty1
         , PdtAlternativQty2
         , PdtAlternativQty3
         , PdtConversionFactor1
         , PdtConversionFactor2
         , PdtConversionFactor3
      from GCO_PRODUCT
     where GCO_GOOD_ID = aGCO_GOOD_ID;

    AlternativQty1Used  :=(PdtAlternativQty1 = 1);
    AlternativQty2Used  :=(PdtAlternativQty2 = 1);
    AlternativQty3Used  :=(PdtAlternativQty3 = 1);

    if AlternativQty1Used then
      AlternativQty1  := Qty * PdtConversionFactor1;
    end if;

    if AlternativQty2Used then
      AlternativQty2  := Qty * PdtConversionFactor2;
    end if;

    if AlternativQty3Used then
      AlternativQty3  := Qty * PdtConversionFactor3;
    end if;
  exception
    when no_data_found then
      AlternativQty1Used  := false;
      AlternativQty2Used  := false;
      AlternativQty3Used  := false;
      AlternativQty1      := 0;
      AlternativQty2      := 0;
      AlternativQty3      := 0;
  end;

  /**
  * function PeriodeActiveExercise
  * description : Retourne l'ID de la période active de l'exercice passé en param
  * @created ECA
  * @lastUpdate
  * @private
  * @param     ExerciceId    Exercice
  */
  function PeriodeActiveExercise(ExerciseId number)
    return number
  is
    StmPeriodId number;
  begin
    select max(STM_PERIOD_ID)
      into StmPeriodId
      from STM_PERIOD
     where C_PERIOD_STATUS = '02'
       and STM_EXERCISE_ID = ExerciseId;

    return StmPeriodId;
  end;

  /**
  * function GetPeriodDates
  * description : Retourne les dates de début et de fin et description de
  *               la période passée en paramètre
  * @created ECA
  * @lastUpdate
  * @private
  * @param     PeriodId     ID Période
  * @param     BeginDate    Date début
  * @param     EndDate      Date fin
  * @param     PeriodDescr  Description
  */
  procedure GetPeriodDates(PeriodId number, BeginDate in out date, EndDate in out date, PeriodDescr in out varchar2)
  is
  begin
    select PER_STARTING_PERIOD
         , PER_ENDING_PERIOD
         , PER_DESCRIPTION
      into BeginDate
         , EndDate
         , PeriodDescr
      from STM_PERIOD
     where STM_PERIOD_ID = PeriodId;
  exception
    when no_data_found then
      BeginDate    := to_date('01.01/1900', 'DD.MM.YYYY');
      EndDate      := to_date('01.01/1900', 'DD.MM.YYYY');
      PeriodDescr  := '';
  end;

  /**
  * function GetPrevExercice
  * description : Cette fonction renvoie le numéro de l'exercice précédent
  *               l'exercice en paramètre, sinon renvoie l'id de l'exercice actuel
  * @created ECA
  * @lastUpdate
  * @private
  * @param     ExerciceId    Exercice
  */
  function GetPrevExercice(ExerciceId number)
    return number
  is
    StmExerciceId number;
  begin
    select A.STM_EXERCISE_ID
      into StmExerciceId
      from STM_EXERCISE A
     where A.EXE_ENDING_EXERCISE = (select B.EXE_STARTING_EXERCISE - 1
                                      from STM_EXERCISE B
                                     where B.STM_EXERCISE_ID = ExerciceId);

    return StmExerciceId;
  exception
    when no_data_found then
      return ExerciceId;
  end;

  /**
  * function GetExerciseStatus
  * description : renvoie le status de l'exercice
  * @created ECA
  * @lastUpdate
  * @private
  * @param     ExerciceId    Exercice
  */
  function GetExerciseStatus(ExerciseId number)
    return varchar2
  is
    CExerciceStatus STM_EXERCISE.C_EXERCISE_STATUS%type;
  begin
    select max(C_EXERCISE_STATUS)
      into CExerciceStatus
      from STM_EXERCISE
     where STM_EXERCISE_ID = ExerciseId;

    return CExerciceStatus;
  end;

  /**
  * function ValDateInActivePeriod
  * description : Contrôle de validation de la date passée en paramètre, afin que cette
  *               dernière soit incluse dans la limites de la période active, en cas d'échec,
  *               retourne une des deux bornes de la période active
  * @created ECA
  * @lastUpdate
  * @private
  * @param     DateInPeriod     Date à valider
  * @param     fActivePeriodId  ID Période active
  * @param     ExerciceID       ID Exercice
  */
  function ValDateInActivePeriod(DateInPeriod date, fActivePeriodId number, ExerciceID number)
    return date
  is
    fPriorPeriodId      number;   -- Période active de l'exercice arrêté
    fPrevExercice       number;
    dtBeginActivePeriod date;   -- Date Début de la période courante
    dtEndActivePeriod   date;   -- Date fin de la période courante
    dtBeginPriorPeriod  date;   -- Date Début de la période active de l'exercice arrêté
    dtEndPriorPeriod    date;   -- Date fin de la période active de l'exercice arrêté
    strTmp              STM_PERIOD.PER_DESCRIPTION%type;
    result              date;
  begin
    fPriorPeriodId  := fActivePeriodId;
    -- Recherche de l'Id de la période active de l'exercice arrêté si celui-ci existe
    fPrevExercice   := GetPrevExercice(ExerciceID);

    if GetExerciseStatus(fPrevExercice) = '03' then
      fPriorPeriodId  := PeriodeActiveExercise(fPrevExercice);
    end if;

    -- Retourne les dates de début et de fin de la période passée en paramètre
    GetPeriodDates(fActivePeriodId, dtBeginActivePeriod, dtEndActivePeriod, strTmp);
    GetPeriodDates(fPriorPeriodId, dtBeginPriorPeriod, dtEndPriorPeriod, strTmp);

    -- Contrôle que la date entrée en paramètre soit comprise dans les limites de la période active
    if DateInPeriod < dtBeginPriorPeriod then
      result  := dtBeginPriorPeriod;
    elsif     (DateInPeriod > dtEndPriorPeriod)
          and (DateInPeriod < dtBeginActivePeriod) then
      result  := dtBeginActivePeriod;
    elsif DateInPeriod > dtEndActivePeriod then
      result  := dtEndActivePeriod;
    else
      result  := DateInPeriod;
    end if;

    return result;
  end;

  /**
  * procedure getActivePeriod
  * description : Retourne l'ID de la période active pour l'exercice
  * @created ECA
  * @lastUpdate
  * @private
  * @param     StmExerciceId       ID Exercice
  */
  function getActivePeriod(StmExerciceId number, aErrorCode in out varchar2, aErrorMsg in out varchar2)
    return number
  is
    result number;
  begin
    select STM_PERIOD_ID
      into result
      from STM_PERIOD
     where C_PERIOD_STATUS = '02'
       and STM_EXERCISE_ID = StmExerciceId;

    return result;
  exception
    when no_data_found then
      begin
        aErrorCode  := 'excNoActiveExcPeriod';
        aErrorMsg   := PCS.PC_FUNCTIONS.TranslateWord('Pas de période active sur l''exercice!');
        raise_application_error(-20120, aErrorMsg);
        return null;
      end;
    when too_many_rows then
      begin
        aErrorCode  := 'excTooManyActivePeriod';
        aErrorMsg   := PCS.PC_FUNCTIONS.TranslateWord('Plusieurs périodes actives sur l''exercice!');
        raise_application_error(-20130, aErrorMsg);
        return null;
      end;
    when others then
      begin
        aErrorCode  := 'excGenericException';
        aErrorMsg   := 'Erreur détectée lors des passages des mouvements de stock' || ' : ' || sqlerrm;
        raise_application_error(-20001, aErrorMsg);
        return null;
      end;
  end;

  /**
  * procedure procedure GetImputationAccount
  * description : Recherche du compte financier et du compte division de résultat
  *               au niveau de l'imputation Financier Mvt Stock.
  * @created ECA
  * @lastUpdate
  * @private
  * @param     aSTM_MOVEMENT_KIND_ID       Genre de mouvement
  * @param     StrMovementType             Type de mouvement
  * @param     aGCO_GOOD_ID                Produit
  * @param     ResultFinancierAccountID    Compte financier de résultat
  * @param     ResultDivisionAccountID     Compte division de résultat
  */
  procedure GetImputationAccount(
    aSTM_MOVEMENT_KIND_ID           number
  , StrMovementType                 STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type
  , aGCO_GOOD_ID                    number
  , ResultFinancierAccountID in out number
  , ResultDivisionAccountID  in out number
  )
  is
    cursor Cur_FINANCIAL
    is
      select GCO_IMPUT_STOCK.ACS_FINANCIAL_ACCOUNT_ID
           , GCO_IMPUT_STOCK.ACS_DIVISION_ACCOUNT_ID
        from GCO_IMPUT_STOCK
           , STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND.C_MOVEMENT_TYPE = StrMovementType
         and STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID = GCO_IMPUT_STOCK.STM_MOVEMENT_KIND_ID
         and GCO_IMPUT_STOCK.GCO_GOOD_ID = aGCO_GOOD_ID;

    cursor Cur_FINANCIAL_2
    is
      select STM_MOVEMENT_KIND.ACS_FINANCIAL_ACCOUNT_ID
           , STM_MOVEMENT_KIND.ACS_DIVISION_ACCOUNT_ID
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID = aSTM_MOVEMENT_KIND_ID;

    CurFINANCIAL Cur_FINANCIAL%rowtype;
  begin
    if    (nvl(ResultFinancierAccountID, 0) = 0)
       or (nvl(ResultDivisionAccountID, 0) = 0) then
      -- Recherche du compte financier et division pour le bien et le genre de mouvement de stock
      open Cur_FINANCIAL;

      fetch Cur_FINANCIAL
       into CurFINANCIAL;

      if Cur_FINANCIAL%found then
        if (ResultFinancierAccountID = 0) then
          ResultFinancierAccountID  := CurFINANCIAL.ACS_FINANCIAL_ACCOUNT_ID;
        end if;

        if (ResultDivisionAccountID = 0) then
          ResultDivisionAccountID  := CurFINANCIAL.ACS_DIVISION_ACCOUNT_ID;
        end if;
      else
        open Cur_FINANCIAL_2;

        fetch Cur_FINANCIAL_2
         into CurFINANCIAL;

        if Cur_FINANCIAL_2%found then
          if (ResultFinancierAccountID = 0) then
            ResultFinancierAccountID  := CurFINANCIAL.ACS_FINANCIAL_ACCOUNT_ID;
          end if;

          if (ResultDivisionAccountID = 0) then
            ResultDivisionAccountID  := CurFINANCIAL.ACS_DIVISION_ACCOUNT_ID;
          end if;
        end if;

        close Cur_FINANCIAL_2;
      end if;

      close Cur_FINANCIAL;
    end if;

    GetConfigData(ResultFinancierAccountID, ResultDivisionAccountID);
  end;

  /**
  * procedure GetStockImputationAccount
  * description : Recherche du compte financier et du compte division de bilan
  *               au niveau du stock logique du mouvement de stock }
  * @created ECA
  * @lastUpdate
  * @private
  * @param     aStockID             Stock
  * @param     aFinancialAccountID  Compte financier de bilan
  * @param     aDivisionAccountID   Compte division de bialn
  */
  procedure GetStockImputationAccount(aStockID number, aFinancialAccountID in out number, aDivisionAccountID in out number)
  is
    cursor cur_STM_STOCK
    is
      select ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
        from STM_STOCK
       where STM_STOCK_ID = aStockID;

    curSTM_STOCK cur_STM_STOCK%rowtype;
  begin
    if    (nvl(aFinancialAccountID, 0) = 0)
       or (nvl(aDivisionAccountID, 0) = 0) then
      -- Recherche du compte financier et du compte division lié au stock logique
      open cur_STM_STOCK;

      fetch cur_STM_STOCK
       into curSTM_STOCK;

      if cur_STM_STOCK%found then
        aFinancialAccountID  := curSTM_STOCK.ACS_FINANCIAL_ACCOUNT_ID;
        aDivisionAccountID   := curSTM_STOCK.ACS_DIVISION_ACCOUNT_ID;
      end if;

      -- Si les comptes ne sont pas initialisés dans le stock, on récupère les valeurs de la config
      GetConfigData(aFinancialAccountID, aDivisionAccountID);

      close cur_STM_STOCK;
    end if;
  end;

  /**
  * procedure DefineAccounts
  * description : Définir, pour les paramètres donnés, les ID des comptes associés.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param    aGCO_GOOD_ID              Produit
  * @param    aSTOCK_ID                 Stock
  * @param    aSTM_MOVEMENT_KIND_ID     Genre de mouvement
  * @param    BilanFinancierAccountID   Compte de bilan financier
  * @param    BilanDivisionAccountID    Compte de bilan division
  * @param    ResultFinancierAccountID  Compte  de résultat financier
  * @param    ResultDivisionAccountID   Compte de résultat division
  */
  procedure DefineAccounts(
    aGCO_GOOD_ID                    number
  , aSTOCK_ID                       number
  , aSTM_MOVEMENT_KIND_ID           number
  , BilanFinancierAccountID  in out number
  , BilanDivisionAccountID   in out number
  , ResultFinancierAccountID in out number
  , ResultDivisionAccountID  in out number
  )
  is
    StrMovementType STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
  begin
    BilanFinancierAccountID   := null;
    BilanDivisionAccountID    := null;
    ResultFinancierAccountID  := null;
    ResultDivisionAccountID   := null;

    -- Obtention de l'attibuts <Type> du mouvement.
    select max(C_MOVEMENT_TYPE)
      into StrMovementType
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = aSTM_MOVEMENT_KIND_ID;

    -- Imputation financière au niveau des mouvements de stock ( Comptes de bilan )
    -- Recherche du compte financier et du compte division de bilan au niveau du stock logique du mouvement de stock
    GetStockImputationAccount(aSTOCK_ID, BilanFinancierAccountID, BilanDivisionAccountID);
    -- Imputation financière au niveau des mouvements de stock ( Comptes de résultat )
    -- Recherche du compte financier et du compte division de résultat au niveau de l'imputation Financier Mvt Stock
    GetImputationAccount(aSTM_MOVEMENT_KIND_ID, StrMovementType, aGCO_GOOD_ID, ResultFinancierAccountID, ResultDivisionAccountID);
  end;

  /**
  * procedure GetMovementKindID
  * description : Recherche de l'ID du genre de mouvement correspondant au type et sens
  */
  function GetMovementKindID(iMvtKindType in integer, iMvtKindWay in varchar2)
    return number
  is
    lvMovementCode   varchar2(10);
    lvMovementType   varchar2(10);
    lnMovementKindId number;
  begin
    -- Déterminer la valeur des DCOD ...
    if iMvtKindWay is null then
      return 0;
    end if;

    case iMvtKindType
      when mktSortieStockVersAtelier then
        lvMovementType  := mtTransfertFabrication;
        lvMovementCode  := mcConsommationFabrication;
      when mktRetourAtelierVersDechet then
        lvMovementType  := mtTransfertFabrication;
        lvMovementCode  := mcDechetFabrication;
      when mktRetourAtelierVersStock then
        lvMovementType  := mtTransfertFabrication;
        lvMovementCode  := mcRetourFabrication;
      when mktComposantConsomme then
        lvMovementType  := mtFabrication;
        lvMovementCode  := mcConsommationFabrication;
      when mktReceptionProduitTermine then
        lvMovementType  := mtFabrication;
        lvMovementCode  := mcReceptionFabrication;
      when mktReceptionCompensation then
        lvMovementType  := mtFabrication;
        lvMovementCode  := mcReceptionCorrection;
      when mktReceptionProduitDerive then
        lvMovementType  := mtFabrication;
        lvMovementCode  := mcReceptionFabrication;
      when mktReceptionRebut then
        lvMovementType  := mtFabrication;
        lvMovementCode  := mcReceptionRebut;
    end case;

    select STM_MOVEMENT_KIND_ID
      into lnMovementKindId
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = (select max(STM_MOVEMENT_KIND_ID)
                                     from STM_MOVEMENT_KIND
                                    where C_MOVEMENT_CODE = lvMovementCode
                                      and C_MOVEMENT_TYPE = lvMovementType
                                      and C_MOVEMENT_SORT = iMvtKindWay);

    return lnMovementKindId;
  exception
    when others then
      return null;
  end GetMovementKindID;

  /**
  * function GetMvtKindCompoStockOut
  * description : Retourne le genre de mouvement de sortie composant stock vers atelier
  * @created CLG
  * @lastUpdate
  */
  function GetMvtKindCompoStockOut
    return number
  is
  begin
    return GetMovementKindId(mktSortieStockVersAtelier, 'SOR');
  end;

  /**
  * function GetMvtKindCompoWorkshopIn
  * description : Retourne le genre de mouvement d'entrée en atelier
  * @created CLG
  * @lastUpdate
  */
  function GetMvtKindCompoWorkshopIn
    return number
  is
  begin
    return GetMovementKindId(mktSortieStockVersAtelier, 'ENT');
  end;

  /**
  * function GetMvtKindByProductRecept
  * description : Retourne le genre de mouvement de réception d'un produit dérivé
  * @created CLG
  * @lastUpdate
  */
  function GetMvtKindByProductRecept
    return number
  is
  begin
    return GetMovementKindId(mktReceptionProduitDerive, 'ENT');
  end;

  /**
  * function GetMvtKindConsumedComp
  * description : Retourne le genre de mouvement de consommation de composant
  * @created CLG
  * @lastUpdate
  */
  function GetMvtKindConsumedComp
    return number
  is
  begin
    return GetMovementKindId(mktComposantConsomme, 'SOR');
  end;

  /**
  * function GetMvtKindStockReturn
  * description : Retourne le genre de mouvement de retour en stock
  * @created CLG
  * @lastUpdate
  */
  function GetMvtKindStockReturn
    return number
  is
  begin
    return GetMovementKindId(mktRetourAtelierVersStock, 'ENT');
  end;

  /**
  * function GetMvtKindReturnInTrash
  * description : Retourne le genre de mouvement de mise en déchet (entrée en stock déchet)
  * @created CLG
  * @lastUpdate
  */
  function GetMvtKindReturnInTrash
    return number
  is
  begin
    return GetMovementKindId(mktRetourAtelierVersDechet, 'ENT');
  end;

  /**
  * function IsMvtKindCompatible
  * description : Vérifie la compatibilité des informations de genre, sens, type
  *               et code de mouvements.
  * @created ECA
  * @lastUpdate
  * @private
  * @param     MvtKindType            Genre de mouvement
  * @param     PrmC_MOVEMENT_SORT     Sens du mouvement
  * @param     PrmC_MOVEMENT_TYPE     Type du mouvement
  * @param     PrmC_MOVEMENT_CODE     Code du mouvement
  */
  function IsMvtKindCompatible(
    MvtKindType               integer
  , PrmC_MOVEMENT_SORT        varchar2
  , PrmC_MOVEMENT_TYPE        varchar2
  , PrmC_MOVEMENT_CODE        varchar2
  , aErrorCode         in out varchar2
  , aErrorMsg          in out varchar2
  )
    return boolean
  is
    MvtKindID       number;
    MvtKindSens     varchar2(3);
    CntMovementKind integer;
  begin
    MvtKindID  := 0;

    case MvtKindType
      when mktSortieStockVersAtelier then
        MvtKindSens  := mksOUT;
      when mktRetourAtelierVersDechet then
        MvtKindSens  := mksOUT;
      when mktRetourAtelierVersStock then
        MvtKindSens  := mksOUT;
      when mktComposantConsomme then
        MvtKindSens  := mksOUT;
      when mktReceptionProduitTermine then
        MvtKindSens  := mksIN;
      when mktReceptionCompensation then
        MvtKindSens  := mksIN;
      when mktReceptionRebut then
        MvtKindSens  := mksIN;
      when mktReceptionProduitDerive then
        MvtKindSens  := mksIN;
      else
        aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Type de mouvement inconnu') || ' : ' || MvtKindType;
        raise_application_error(-20060, aErrorMsg);
        return false;
    end case;

    -- Déteminer l'ID du MovementKind selon le type et le sens ...
    MvtKindID  := GetMovementKindID(MvtKindType, MvtKindSens);

    if MvtKindID = 0 then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Genre de mouvement inconnu') || ' : ' || MvtKindType || ', ' || MvtKindSens;
      raise_application_error(-20070, aErrorMsg);
      return false;
    end if;

    -- récupérer les C_MOVEMENT_SORT C_MOVEMENT_TYPE C_MOVEMENT_CODE pour le STM_MOVEMENT_KIND_ID trouvé
    -- et voir s'il est conforme à celui qui doit être traité
    select count(*)
      into CntMovementKind
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = MvtKindID
       and C_MOVEMENT_SORT = PrmC_MOVEMENT_SORT
       and C_MOVEMENT_TYPE = PrmC_MOVEMENT_TYPE
       and C_MOVEMENT_CODE = PrmC_MOVEMENT_CODE;

    if CntMovementKind > 0 then
      return true;
    else
      return false;
    end if;
  exception
    when excUnDefinedMvtType then
      begin
        aErrorCode  := 'excUnDefinedMvtType';
        raise_application_error(-20060, aErrorMsg);
        return false;
      end;
    when excUndefinedFirstMvtKind then
      begin
        aErrorCode  := 'excUndefinedFirstMvtKind';
        raise_application_error(-20070, aErrorMsg);
        return false;
      end;
    when others then
      begin
        aErrorCode  := 'excGenericException';
        aErrorMsg   := 'Erreur détectée lors des passages des mouvements de stock' || ' : ' || sqlerrm;
        raise_application_error(-20001, aErrorMsg);
        return false;
      end;
  end;

  /**
  * function SortMovementByGoodId
  * description : Tri du tableau des mouvements selon GCO_GOOD_ID et des 5 caractérisations
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aPreparedStockMovements     Tableau des mouvements de stock
  */
  procedure SortMovementByGoodId(aPreparedStockMovements in out TPreparedStockMovements)
  is
    i           integer;
    j           integer;
    tmpStockMvt TPreparedStockMovement;
  begin
    i  := 1;

    while i < aPreparedStockMovements.count loop
      j  := i + 1;

      while j <= aPreparedStockMovements.count loop
        if    (aPreparedStockMovements(j).GoodID < aPreparedStockMovements(i).GoodID)
           or (     (aPreparedStockMovements(j).GoodID = aPreparedStockMovements(i).GoodID)
               and (aPreparedStockMovements(j).AllCharactValues < aPreparedStockMovements(i).AllCharactValues)
              ) then
          tmpStockMvt                 := aPreparedStockMovements(i);
          aPreparedStockMovements(i)  := aPreparedStockMovements(j);
          aPreparedStockMovements(j)  := tmpStockMvt;
        end if;

        j  := j + 1;
      end loop;

      i  := i + 1;
    end loop;
  end;

  /**
  * function InsertStockMovementRecord
  * description : insertion dans la base du mouvement de stock
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param     TransfertStockMvtID      ID mouvement de transfert de stock
  * @param     MvtKindID                Genre de mouvement
  * @param     FirstStockID             Stock
  * @param     FirstLocationID          Emplacement
  * @param     GoodID                   Produit
  * @param     Characterization1ID      ID Caract.1
  * @param     Characterization2ID      ID Caract.2
  * @param     Characterization3ID      ID Caract.3
  * @param     Characterization4ID      ID Caract.4
  * @param     Characterization5ID      ID Caract.5
  * @param     DocRecordID              Dossier
  * @param     BilanFinancialAccountID  Compte financier de bilan
  * @param     BilanDivisionAccountID   Compte division de bilan
  * @param     ResultFinancialAccountID Compte financier de résultat
  * @param     ResultDivisionAccountID  Compte division de résultat
  * @param     Characterization1Value   Valeur Caract.1
  * @param     Characterization2Value   Valeur Caract.2
  * @param     Characterization3Value   Valeur Caract.3
  * @param     Characterization4Value   Valeur Caract.4
  * @param     Characterization5Value   Valeur Caract.5
  * @param     MvtDate                  Date du mouvement
  * @param     MvtQty                   Quantité du mouvement
  * @param     GoodPriceReference       Prix produit
  * @param     MvtPrice                 Prix du mouvement
  * @param     LotRefCompl              Référence complète lot de fabrication
  * @param     aFalFactoryInId          Lien d'entrée stock atelier du composant du lot
  * @param     aFalFactoryOutId         Lien de sortie stock atelier du composant du lot
  * @return    aErrorCode               Code erreur
  * @return    aErrorMsg                Msg erreur
  * @parama    SmoPrcsValue             Valeur prcs
  * @parama    FalHistoLotId            id de l'historique du lot
  * @param     aFalLotId                Id du lot
  */
  function InsertStockMovementRecord(
    TransfertStockMvtID             number
  , MvtKindID                       number
  , FirstStockID                    number
  , FirstLocationID                 number
  , GoodID                          number
  , Characterization1ID             number
  , Characterization2ID             number
  , Characterization3ID             number
  , Characterization4ID             number
  , Characterization5ID             number
  , DocRecordID                     number
  , BilanFinancialAccountID         number
  , BilanDivisionAccountID          number
  , ResultFinancialAccountID        number
  , ResultDivisionAccountID         number
  , Characterization1Value          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization2Value          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization3Value          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization4Value          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization5Value          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , MvtDate                         date
  , MvtQty                          number
  , GoodPriceReference              number
  , MvtPrice                        number
  , LotRefCompl                     FAL_LOT.LOT_REFCOMPL%type
  , aFalFactoryInId                 number
  , aFalFactoryOutId                number
  , aErrorCode               in out varchar2
  , aErrorMsg                in out varchar2
  , aSmoPrcsValue                   number
  , aFalHistoLotId                  number
  , aFalLotId                       FAL_LOT.FAL_LOT_ID%type
  , iSmoLinkId1              in     STM_STOCK_MOVEMENT.SMO_LINK_ID_1%type default null
  , iSmoLinkName1            in     STM_STOCK_MOVEMENT.SMO_LINK_NAME_1%type default null
  )
    return number
  is
    MvtStockID         number;
    ExerciceID         number;
    PeriodID           number;
    AlternativQty1     number;
    AlternativQty2     number;
    AlternativQty3     number;
    AlternativQty1Used boolean;
    AlternativQty2Used boolean;
    AlternativQty3Used boolean;
    aMvtDate           date;
    aFinCharging       number(1);
  begin
    if     (MvtQty = 0)
       and (MvtPrice = 0) then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('La quantité ou le prix du mouvement doivent être différents de 0!');
      raise_application_error(-20110, aErrorMsg);
    end if;

    -- Obtenir un nouvel ID pour le nouveau record ...
    MvtStockID  := GetNewId;
    -- Déterminer l'exercice en cours ...
    ExerciceID  := STM_FUNCTIONS.getActiveExercise;
    -- Déterminer la période active et modifier la date insérée ...
    PeriodID    := getActivePeriod(ExerciceID, aErrorCode, aErrorMsg);
    -- la date du mouvement est-elle dans une période active?
    aMvtDate    := ValDateInActivePeriod(MvtDate, PeriodID, ExerciceID);
    -- Déterminer les quantités alternatives ...
    DefineProductAlternativQty(GoodID, MvtQty, AlternativQty1Used, AlternativQty2Used, AlternativQty3Used, AlternativQty1, AlternativQty2, AlternativQty3);

    if upper(PCS.PC_CONFIG.GetConfig('STM_FINANCIAL_CHARGING') ) = 'TRUE' then
      aFinCharging  := 1;
    else
      aFinCharging  := 0;
    end if;

    STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => MvtStockID
                                    , iGoodId                => GoodID
                                    , iMovementKindId        => MvtKindID
                                    , iExerciseId            => ExerciceID
                                    , iPeriodId              => PeriodID
                                    , iMvtDate               => trunc(aMvtDate)
                                    , iStockId               => FirstStockID
                                    , iLocationId            => FirstLocationID
                                    , iRecordId              => DocRecordID
                                    , iChar1Id               => Characterization1ID
                                    , iChar2Id               => Characterization2ID
                                    , iChar3Id               => Characterization3ID
                                    , iChar4Id               => Characterization4ID
                                    , iChar5Id               => Characterization5ID
                                    , iCharValue1            => Characterization1Value
                                    , iCharValue2            => Characterization2Value
                                    , iCharValue3            => Characterization3Value
                                    , iCharValue4            => Characterization4Value
                                    , iCharValue5            => Characterization5Value
                                    , iMovement2Id           => TransfertStockMvtID
                                    , iWording               => LotRefCompl
                                    , iMvtQty                => MvtQty
                                    , iMvtPrice              => MvtPrice
                                    , iDocQty                => 0
                                    , iDocPrice              => 0
                                    , iUnitPrice             => GoodPriceReference
                                    , iRefUnitPrice          => GoodPriceReference
                                    , iAltQty1               => AlternativQty1
                                    , iAltQty2               => AlternativQty2
                                    , iAltQty3               => AlternativQty3
                                    , iFinancialAccountId    => BilanFinancialAccountID
                                    , iDivisionAccountId     => BilanDivisionAccountID
                                    , iAFinancialAccountId   => ResultFinancialAccountID
                                    , iADivisionAccountId    => ResultDivisionAccountID
                                    , iFinancialCharging     => aFinCharging
                                    , iFalFactoryInId        => aFalFactoryInId
                                    , iFalFactoryOutId       => aFalFactoryOutId
                                    , iSmoPrcsValue          => aSmoPrcsValue
                                    , iFalHistoLotId         => aFalHistoLotId
                                    , iFalLotId              => aFalLotId
                                    , iSmoLinkId1            => iSmoLinkId1
                                    , iSmoLinkName1          => iSmoLinkName1
                                     );
    -- Retourner le mouvement de stock créé...
    return MvtStockID;
  exception
    when excBadMvtQtyOrPrice then
      begin
        aErrorCode  := 'excBadMvtQtyOrPrice';
        raise_application_error(-20110, aErrorMsg);
        return null;
      end;
    when excNoActiveExcPeriod then
      begin
        aErrorCode  := 'excNoActiveExcPeriod';
        aErrorMsg   := PCS.PC_FUNCTIONS.TranslateWord('Pas de période active sur l''exercice!');
        raise_application_error(-20120, aErrorMsg);
        return null;
      end;
    when excTooManyActivePeriod then
      begin
        aErrorCode  := 'excTooManyActivePeriod';
        aErrorMsg   := PCS.PC_FUNCTIONS.TranslateWord('Plusieurs périodes actives sur l''exercice!');
        raise_application_error(-20130, aErrorMsg);
        return null;
      end;
    when excGenericException then
      begin
        aErrorCode  := 'excGenericException';
        aErrorMsg   := 'Erreur détectée lors des passages des mouvements de stock' || ' : ' || sqlerrm;
        raise_application_error(-20001, aErrorMsg);
        return null;
      end;
    when others then
      begin
        aErrorCode  := 'excGenericException';
        aErrorMsg   := substr('Erreur détectée lors des passages des mouvements de stock' || ' : ' || sqlerrm, 1, 255);
        raise_application_error(-20001, aErrorMsg);
        return null;
      end;
  end;

  /**
  * function ReleaseQtyLinkedOnStock
  * description : Libère la quantité attribuée sur stock
  *
  * @created CLG
  * @lastUpdate
  * @private
  * @param    iNetworkLinkId    Attribution sur laquelle libérer la quantité
  * @param    iQty              Quantité à libérer
  */
  procedure ReleaseQtyLinkedOnStock(iNetworkLinkId in number, iQty in number)
  is
    cursor crNetwork
    is
      select FAL_NETWORK_NEED_ID
           , FLN_QTY
        from FAL_NETWORK_LINK
       where FAL_NETWORK_LINK_ID = iNetworkLinkId
         and STM_STOCK_POSITION_ID is not null;
  begin
    for tplNetwork in crNetwork loop
      FAL_NETWORK.Attribution_MAJ_BesoinStock(aNeedID      => tplNetwork.FAL_NETWORK_NEED_ID
                                            , aBeforeQty   => tplNetwork.FLN_QTY
                                            , aAfterQty    => (tplNetwork.FLN_QTY - iQty)
                                            , aAttribID    => iNetworkLinkId
                                             );

      -- Sur le besoin, On ne met à jour que la quantité attribuée stock. Une mise à jour réseaux est effectuée plus loin dans le code de réception ou sortie composants.
      update FAL_NETWORK_NEED
         set FAN_STK_QTY = greatest( (FAN_STK_QTY - iQty), 0)
       where FAL_NETWORK_NEED_ID = tplNetwork.FAL_NETWORK_NEED_ID;
    end loop;
  end;

  /**
  * function DoStockMovement
  * description : Génération des mouvements de stock (entrée/sortie)
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param     MvtKindType                    Type de mouvement
  * @return    StockID                        Stock
  * @return    AErrorCode                     retour d'un code erreur
  * @return    AErrorMsg                      retour message d'erreur
  * @param     LocationID                     Emplacement
  * @param     GoodID                         Produit
  * @param     LotID                          Lot de fabrication
  * @param     Characterization1ID            ID Caract.1
  * @param     Characterization2ID            ID Caract.2
  * @param     Characterization3ID            ID Caract.3
  * @param     Characterization4ID            ID Caract.4
  * @param     Characterization5ID            ID Caract.5
  * @param     Characterization1Value         Valeur caract.1
  * @param     Characterization2Value         Valeur caract.2
  * @param     Characterization3Value         Valeur caract.3
  * @param     Characterization4Value         Valeur caract.4
  * @param     Characterization5Value         Valeur caract.5
  * @param     MvtDate                        Date du mouvement
  * @param     MvtQty                         Quantité du mouvement
  * @param     MvtPrice                       Prix du mouvement
  * @param     GoodPrice                      Prix du produit
  * @param     CreatedFactoryFloorPositionID  ID du mouvement correspondant à l'entrée atelier effectuée
  * @param     ReceptedPositionID             Position de stock créés en réception PT
  * @param     aMvtsContext                   context d'appel (défaut ou désassemblage)
  * @param     aFAL_NETWORK_LINK_ID           Attribution cible du lien composant
  * @param     aFalFactoryInId                Lien de sortie stock atelier du composant du lot
  * @param     aFalFactoryOutId               Lien de sortie stock atelier du composant du lot
  * @param     aFactoryInOriginId             Entrée atelier à l'origine du mouvement
  */
  procedure DoStockMovement(
    MvtKindType                          integer
  , StockID                       in out number
  , aErrorCode                    in out varchar2
  , aErrorMsg                     in out varchar2
  , LocationID                           number
  , GoodID                               number
  , LotID                                number
  , Characterization1ID                  number
  , Characterization2ID                  number
  , Characterization3ID                  number
  , Characterization4ID                  number
  , Characterization5ID                  number
  , Characterization1Value               STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization2Value               STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization3Value               STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization4Value               STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , Characterization5Value               STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , MvtDate                              date
  , MvtQty                               number
  , MvtPrice                             number
  , GoodPrice                            number
  , CreatedFactoryFloorPositionID in out number
  , aMvtsContext                         integer
  , aFAL_NETWORK_LINK_ID                 number
  , aFalFactoryInId                      number
  , aFalFactoryOutId                     number
  , aFactoryInOriginId                   number
  , aFalLotMaterialLinkId                number
  , aFalHistoLotId                       number
  )
  is
    FirstMvtKindSens         varchar2(3);
    SecondMvtKindSens        varchar2(3);
    FirstStockID             number;
    FirstLocationID          number;
    SecondStockID            number;
    SecondLocationID         number;
    FirstStockMvtID          number;
    SecondStockMvtID         number;
    MvtKindID                number;
    DocRecordID              number;
    BilanFinancialAccountID  number;
    BilanDivisionAccountID   number;
    ResultFinancialAccountID number;
    ResultDivisionAccountID  number;
    GoodPriceReference       number;
    LotRefCompl              FAL_LOT.LOT_REFCOMPL%type;
    StockAtelierID           number;
    LocationAtelierId        number;
    NeedSecondMovement       boolean;
    aMOK_ABBREVIATION        varchar2(10);
    aReceptedPositionID      number;
    vSmoPrcsValue            number;
    lSmoLinkId1              STM_STOCK_MOVEMENT.SMO_LINK_ID_1%type;
    lSmoLinkName1            STM_STOCK_MOVEMENT.SMO_LINK_NAME_1%type;
  begin
    CreatedFactoryFloorPositionID  := null;
    SecondMvtKindSens              := null;
    aErrorMsg                      := '';
    aErrorCode                     := '';

    -- Vérification des paramètres ...
    if     (nvl(MvtQty, 0) = 0)
       and (nvl(MvtPrice, 0) = 0) then
      return;
    end if;

    if     (nvl(LocationID, 0) = 0)
       and (MvtKindType <> mktComposantConsomme)
       and (nvl(StockID, 0) <> FAL_TOOLS.GetDefaultStock) then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Mouvements de stock : emplacement de stock non défini!');
      raise_application_error(-20010, aErrorMsg);
      return;
    end if;

    if nvl(GoodID, 0) = 0 then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Mouvements de stock : bien du mouvement non défini!');
      raise_application_error(-20020, aErrorMsg);
      return;
    end if;

    if     (aMvtsContext <> ctxDeAssemblage)
       and (nvl(LotID, 0) = 0) then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Mouvements de stock : Lot de fabrication non défini!');
      raise_application_error(-20030, aErrorMsg);
      return;
    end if;

    -- Déterminer le stock logique à partir de la location si nécéssaire ...
    if     (nvl(StockID, 0) = 0)
       and (nvl(LocationID, 0) <> 0) then
      select max(STM_STOCK_ID)
        into StockID
        from STM_LOCATION
       where STM_LOCATION_ID = LocationID;
    end if;

    -- Déterminer le Stock et l'emplacement Atelier ...
    StockAtelierID                 := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_FLOOR');

    if StockAtelierID is null then
      aErrorMsg  :=
        PCS.PC_FUNCTIONS.TranslateWord('Le stock défini par la configuration PPS_DefltSTOCK_FLOOR n''existe pas!') ||
        chr(13) ||
        PCS.PC_FUNCTIONS.TranslateWord('Stock') ||
        ' = ' ||
        PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_FLOOR');
      raise_application_error(-20040, aErrorMsg);
      return;
    end if;

    LocationAtelierID              := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_FLOOR', StockAtelierID);

    if LocationAtelierID is null then
      aErrorMsg  :=
        PCS.PC_FUNCTIONS.TranslateWord('L''emplacement défini par la configuration PPS_DefltLOCATION_FLOOR n''existe pas!') ||
        chr(13) ||
        PCS.PC_FUNCTIONS.TranslateWord('Emplacement') ||
        ' = ' ||
        PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_FLOOR') ||
        PCS.PC_FUNCTIONS.TranslateWord('Stock') ||
        ' = ' ||
        PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_FLOOR');
      raise_application_error(-20050, aErrorMsg);
      return;
    end if;

    -- Déterminer le DocRecordID et la RefCompl du lot ...
    select max(DOC_RECORD_ID)
      into DocRecordID
      from FAL_LOT
     where FAL_LOT_ID = LotID;

    -- Si le contexte des mouvements de stock est différent de celui du dé-assemblage
    if aMvtsContext <> ctxDeAssemblage then
      select max(LOT_REFCOMPL)
        into LotRefCompl
        from FAL_LOT
       where FAL_LOT_ID = LotID;

      /* Si lot de sous-traitance Achat */
      if FAL_LIB_BATCH.getCFabType(iLotID => LotID) = FAL_BATCH_FUNCTIONS.btSubcontract then
        /* Lors de la confirmation de document impliquant la réception du lot STT, l'ID de la position du lot est stocké dans la table COM_LIST_ID_TEMP. */
        lSmoLinkId1    := COM_LIB_LIST_ID_TEMP.getGlobalVar(iVarName => 'DOC_STT_RECEPT_POSITION_ID');
        lSmoLinkName1  := 'DOC_STT_RECEPT_POSITION_ID';
        LotRefCompl    :=
                        FAL_LIB_SUBCONTRACTP.getNewSubCoRefCompl(iPositionID => lSmoLinkId1) || ' ' || PCS.PC_FUNCTIONS.TranslateWord('du') || ' '
                        || LotRefCompl;
      end if;
    else
      LotRefCompl  :=
            PCS.PC_FUNCTIONS.TranslateWord('Dé-assemblage') || cteSeparatorDeAssemblage || sysdate || cteSeparatorDeAssemblage
            || PCS.PC_I_LIB_SESSION.GetUserIni;
    end if;

    -- Déterminer le prix de référence du produit ...
    GoodPriceReference             := GoodPrice;

    /* Déterminer les StockLogique/Emplacement pour les 1 ou 2 mouvements ...
       Déterminer le sens du premier mouvement et du second mouvement
       Déteminer si 2 mouvements sont nécéssaires */
    case MvtKindType
      when mktSortieStockVersAtelier then
        FirstMvtKindSens    := mksOUT;
        FirstStockID        := StockID;
        FirstLocationID     := LocationID;
        SecondMvtKindSens   := mksIN;
        SecondStockID       := StockAtelierID;
        SecondLocationID    := LocationAtelierID;
        NeedSecondMovement  := true;
      when mktRetourAtelierVersDechet then
        FirstMvtKindSens    := mksOUT;
        FirstStockID        := StockAtelierID;
        FirstLocationID     := LocationAtelierID;
        SecondMvtKindSens   := mksIN;
        SecondStockID       := StockID;
        SecondLocationID    := LocationID;
        NeedSecondMovement  := true;
      when mktRetourAtelierVersStock then
        FirstMvtKindSens    := mksOUT;
        FirstStockID        := StockAtelierID;
        FirstLocationID     := LocationAtelierID;
        SecondMvtKindSens   := mksIN;
        SecondStockID       := StockID;
        SecondLocationID    := LocationID;
        NeedSecondMovement  := true;
      when mktComposantConsomme then
        FirstMvtKindSens    := mksOUT;
        FirstStockID        := StockAtelierID;
        FirstLocationID     := LocationAtelierID;
        -- Pas de mouvement IN ...
        SecondStockID       := 0;
        SecondLocationID    := 0;
        NeedSecondMovement  := false;
      when mktReceptionProduitTermine then
        FirstMvtKindSens    := mksIN;
        FirstStockID        := StockID;
        FirstLocationID     := LocationID;
        -- Pas de mouvement OUT ...
        SecondStockID       := 0;
        SecondLocationID    := 0;
        NeedSecondMovement  := false;
      when mktReceptionCompensation then
        FirstMvtKindSens    := mksIN;
        FirstStockID        := StockID;
        FirstLocationID     := LocationID;
        -- Pas de mouvement OUT ...
        SecondStockID       := 0;
        SecondLocationID    := 0;
        NeedSecondMovement  := false;
      when mktReceptionRebut then
        FirstMvtKindSens    := mksIN;
        FirstStockID        := StockID;
        FirstLocationID     := LocationID;
        -- Pas de mouvement OUT ...
        SecondStockID       := 0;
        SecondLocationID    := 0;
        NeedSecondMovement  := false;
      when mktReceptionProduitDerive then
        FirstMvtKindSens    := mksIN;
        FirstStockID        := StockID;
        FirstLocationID     := LocationID;
        -- Pas de mouvement OUT ...
        SecondStockID       := 0;
        SecondLocationID    := 0;
        NeedSecondMovement  := false;
      else
        aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Type de mouvement inconnu : ') || MvtKindType;
        raise_application_error(-20060, aErrorMsg);
        return;
    end case;

    -- Déteminer l'ID du MovementKind selon le type et le sens ...
    MvtKindID                      := GetMovementKindID(MvtKindType, FirstMvtKindSens);

    if nvl(MvtKindID, 0) = 0 then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Genre du premier mouvement non défini!');
      raise_application_error(-20070, aErrorMsg);
      return;
    end if;

    -- Le mouvement est'il un mouvement autorisé sur ce stock?
    if STM_LIB_MOVEMENT.ExistsNonAllowedMvt(iStockID => FirstStockID, iMovementKindID => MvtKindID) <> 0 then
      aErrorMsg  :=
        PCS.PC_FUNCTIONS.TranslateWord('Un mouvement de stock de ce genre n''est pas autorisé pour ce stock!') ||
        chr(13) ||
        'Genre' ||
        ' : ' ||
        FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_MOVEMENT_KIND', 'MOK_ABBREVIATION', MvtKindID) ||
        chr(13) ||
        'Stock' ||
        ' : ' ||
        FAL_TOOLS.GetSTO_DESCRIPTION(FirstStockID);
      Raise_application_error(-20080, aErrorMsg);
    end if;

    -- Déterminer les comptes de bilan et de résultats (Financier/Division)
    DefineAccounts(GoodID, StockID, MvtKindID, BilanFinancialAccountID, BilanDivisionAccountID, ResultFinancialAccountID, ResultDivisionAccountID);
    vSmoPrcsValue                  := null;

    if MvtKindType in(mktRetourAtelierVersDechet, mktRetourAtelierVersStock) then
      -- Initialisation de SMO_PRCS_VALUE avec celui du mouvement de stock lié au FAL_FACTORY_IN
      select max(SMO_PRCS_AFTER * MvtQty)
        into vSmoPrcsValue
        from STM_STOCK_MOVEMENT
       where FAL_FACTORY_IN_ID = aFactoryInOriginId
         and FAL_FACTORY_OUT_ID is null
         and STM_STOCK_ID = StockAtelierID;
    end if;

    ReleaseQtyLinkedOnStock(aFAL_NETWORK_LINK_ID, MvtQty);
    -- Effectuer le premier mouvement de stock (sortie) ...
    FirstStockMvtID                :=
      InsertStockMovementRecord(0
                              , MvtKindID
                              , FirstStockID
                              , FirstLocationID
                              , GoodID
                              , Characterization1ID
                              , Characterization2ID
                              , Characterization3ID
                              , Characterization4ID
                              , Characterization5ID
                              , DocRecordID
                              , BilanFinancialAccountID
                              , BilanDivisionAccountID
                              , ResultFinancialAccountID
                              , ResultDivisionAccountID
                              , Characterization1Value
                              , Characterization2Value
                              , Characterization3Value
                              , Characterization4Value
                              , Characterization5Value
                              , MvtDate
                              , MvtQty
                              , GoodPriceReference
                              , MvtPrice
                              , LotRefCompl
                              , aFalFactoryInId
                              , aFalFactoryOutId
                              , aErrorCode
                              , aErrorMsg
                              , vSmoPrcsValue
                              , aFalHistoLotId
                              , LotID
                              , lSmoLinkId1
                              , lSmoLinkName1
                               );

    -- Update de l'export KLS dans le cas d'éclatement de lot
    if aMvtsContext = ctxBatchSplitting then
      UpdateKLSBuffer(FirstStockMvtID);
    end if;

    -- Comptabilité industrielle
    FAL_ACCOUNTING_FUNCTIONS.InsertMatElementCost(LotID, aFalLotMaterialLinkId, MvtPrice, FirstStockMvtID, MvtKindType, FirstMvtKindSens, MvtQty);

    -- On stock les position entrée en stock (Pour le processus d'attribution complètes).
    if MvtKindType = mktReceptionProduitTermine then
      -- Si c'est le premier ID de position de stock alors on initialise avec la valeur
      aReceptedPositionID  := '';

      if ReceptedPositionID is null then
        GetStockPositionFromCharact(GoodID
                                  , FirstStockID
                                  , FirstLocationID
                                  , Characterization1Value
                                  , Characterization2Value
                                  , Characterization3Value
                                  , Characterization4Value
                                  , Characterization5Value
                                  , aReceptedPositionID
                                   );
        ReceptedPositionID  := aReceptedPositionID;
      else
        GetStockPositionFromCharact(GoodID
                                  , FirstStockID
                                  , FirstLocationID
                                  , Characterization1Value
                                  , Characterization2Value
                                  , Characterization3Value
                                  , Characterization4Value
                                  , Characterization5Value
                                  , aReceptedPositionID
                                   );

        if aReceptedPositionID is not null then
          ReceptedPositionID  := ReceptedPositionID || ',' || aReceptedPositionID;
        end if;
      end if;
    end if;

    -- Faut-il effectuer un second mouvement (Transfert)...
    if NeedSecondMovement then
      -- Déteminer l'ID du MovementKind selon le type et le sens ...
      MvtKindID         := GetMovementKindID(MvtKindType, SecondMvtKindSens);

      if nvl(MvtKindID, 0) = 0 then
        aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Genre du second mouvement non défini!');
        raise_application_error(-20090, aErrorMsg);
      end if;

      -- Le mouvement est'il un mouvement autorisé sur ce stock?
      if STM_LIB_MOVEMENT.ExistsNonAllowedMvt(iStockID => SecondStockID, iMovementKindID => MvtKindID) <> 0 then
        aErrorMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Un mouvement de stock de ce genre n''est pas autorisé pour ce stock!') ||
          chr(13) ||
          'Genre' ||
          ' : ' ||
          FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_MOVEMENT_KIND', 'MOK_ABBREVIATION', MvtKindID) ||
          chr(13) ||
          'Stock' ||
          ' : ' ||
          FAL_TOOLS.GetSTO_DESCRIPTION(SecondStockID);
        Raise_application_error(-20080, aErrorMsg);
      end if;

      -- Déterminer les comptes de bilan et de résultats (Financier/Division)...
      DefineAccounts(GoodID, StockID, MvtKindID, BilanFinancialAccountID, BilanDivisionAccountID, ResultFinancialAccountID, ResultDivisionAccountID);
      -- Effectuer le second mouvement de stock (entrée) ...
      SecondStockMvtID  :=
        InsertStockMovementRecord(FirstStockMvtID
                                , MvtKindID
                                , SecondStockID
                                , SecondLocationID
                                , GoodID
                                , Characterization1ID
                                , Characterization2ID
                                , Characterization3ID
                                , Characterization4ID
                                , Characterization5ID
                                , DocRecordID
                                , BilanFinancialAccountID
                                , BilanDivisionAccountID
                                , ResultFinancialAccountID
                                , ResultDivisionAccountID
                                , Characterization1Value
                                , Characterization2Value
                                , Characterization3Value
                                , Characterization4Value
                                , Characterization5Value
                                , MvtDate
                                , MvtQty
                                , GoodPriceReference
                                , MvtPrice
                                , LotRefCompl
                                , aFalFactoryInId
                                , aFalFactoryOutId
                                , aErrorCode
                                , aErrorMsg
                                , vSmoPrcsValue
                                , aFalHistoLotId
                                , LotID
                                 );

      -- Update de l'export KLS dans le cas d'éclatement de lot
      if aMvtsContext = ctxBatchSplitting then
        UpdateKLSBuffer(SecondStockMvtID);
      end if;

      -- Comptabilité industrielle.
      FAL_ACCOUNTING_FUNCTIONS.InsertMatElementCost(LotID, aFalLotMaterialLinkId, MvtPrice, SecondStockMvtID, MvtKindType, SecondMvtKindSens, MvtQty);
    end if;

    -- Déterminer le paramètre CreatedFactoryFloorPositionID ...
    if MvtKindType = mktSortieStockVersAtelier then
      -- Récupérer la position créée dans l'atelier par le mouvement ...
      GetStockPositionFromCharact(GoodID
                                , SecondStockID
                                , SecondLocationID
                                , Characterization1Value
                                , Characterization2Value
                                , Characterization3Value
                                , Characterization4Value
                                , Characterization5Value
                                , CreatedFactoryFloorPositionID
                                 );

      if CreatedFactoryFloorPositionID = 0 then
        aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('La position de stock créée en atelier est introuvable!');
        raise_application_error(-20100, aErrorMsg);
      end if;
    else
      CreatedFactoryFloorPositionID  := 0;
    end if;
  exception
    when excUndefinedLocation then
      begin
        aErrorCode  := 'excUndefinedLocation';
        raise_application_error(-20010, aErrorMsg);
      end;
    when excUndefinedGood then
      begin
        aErrorCode  := 'excUndefinedGood';
        raise_application_error(-20020, aErrorMsg);
      end;
    when excUndefinedBatch then
      begin
        aErrorCode  := 'excUndefinedBatch';
        raise_application_error(-20030, aErrorMsg);
      end;
    when excUndefinedStockFloor then
      begin
        aErrorCode  := 'excUndefinedStockFloor';
        raise_application_error(-20040, aErrorMsg);
      end;
    when excUndefinedLocationFloor then
      begin
        aErrorCode  := 'excUndefinedLocationFloor';
        raise_application_error(-20050, aErrorMsg);
      end;
    when excUnDefinedMvtType then
      begin
        aErrorCode  := 'excUnDefinedMvtType';
        raise_application_error(-20060, aErrorMsg);
      end;
    when excUndefinedFirstMvtKind then
      begin
        aErrorCode  := 'excUndefinedFirstMvtKind';
        raise_application_error(-20070, aErrorMsg);
      end;
    when excUnAuthorizedMvt then
      begin
        aErrorCode  := 'excUnAuthorizedMvt';
        raise_application_error(-20080, aErrorMsg);
      end;
    when excUndefinedSecondMvtKind then
      begin
        aErrorCode  := 'excUndefinedSecondMvtKind';
        raise_application_error(-20090, aErrorMsg);
      end;
    when excUndefinedStockPosition then
      begin
        aErrorCode  := 'excUndefinedStockPosition';
        raise_application_error(-20100, aErrorMsg);
      end;
    when excBadMvtQtyOrPrice then
      begin
        aErrorCode  := 'excBadMvtQtyOrPrice';
        raise_application_error(-20110, aErrorMsg);
      end;
    when excNoActiveExcPeriod then
      begin
        aErrorCode  := 'excNoActiveExcPeriod';
        raise_application_error(-20120, aErrorMsg);
      end;
    when excTooManyActivePeriod then
      begin
        aErrorCode  := 'excTooManyActivePeriod';
        raise_application_error(-20130, aErrorMsg);
      end;
    when others then
      begin
        aErrorCode  := 'excGenericException';
        aErrorMsg   := substr(replace(sqlerrm, 'ORA' || sqlcode || ':', ''), 1, 255);
        raise_application_error(-20001, aErrorMsg);
      end;
  end DoStockMovement;

  /* Idem fonction suivante, mais avec en retour la liste des positions de stock impactée
     par une réception PT si les mouvements passés sont de ce type */
  procedure ApplyPreparedStockMovements(
    aPreparedStockMovements in out TPreparedStockMovements
  , aErrorCode              in out varchar2
  , aErrorMsg               in out varchar2
  , aReceptedPositionID     in out varchar2
  , MvtsContext                    integer default ctxDefault
  , aiShutdownExceptions           integer default 0
  , aFalHistoLotId                 number default null
  )
  is
  begin
    ApplyPreparedStockMovements(aPreparedStockMovements, aErrorCode, aErrorMsg, MvtsContext, aiShutdownExceptions, aFalHistoLotId);
    aReceptedPositionID  := ReceptedPositionID;
  end;

  /**
  * function ApplyPreparedStockMovements
  * description : Génération des mouvements de stock préalablements préparés dans
  *               aPreparedStockMovements
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPreparedStockMovements     Tableau des mouvements de stock
  * @return  aErrorcode                  Code erreur
  * @return  aErrorMsg                   Message d'erreur
  * @param   aMvtsContext                Context de passage des mouvements
  * @param   aiShutdownExceptions        indique si le raise d'une eventuelle erreure est exécuté depuis de PL
  * @param   aFalHistoLotId              Id de l'historique du lot de l'événement qui a déclenché les mouvements de stock
  */
  procedure ApplyPreparedStockMovements(
    aPreparedStockMovements in out TPreparedStockMovements
  , aErrorCode              in out varchar2
  , aErrorMsg               in out varchar2
  , MvtsContext                    integer default ctxDefault
  , aiShutdownExceptions           integer default 0
  , aFalHistoLotId                 number default null
  )
  is
    idxCurrentPosition integer;
    aMaxidxPosition    integer;
    aFinished          boolean;
    idxMinPosForGood   integer;
    idxMaxPosForGood   integer;
    CurrentGoodId      number;
  begin
    ReceptedPositionID  := '';

    -- Si aucun mouvement préparés, on sort de la fonction
    if aPreparedStockMovements.count = 0 then
      return;
    end if;

    -- Tri des mouvements de stock selon le Gco_Good_Id
    SortMovementByGoodId(aPreparedStockMovements);
    -- raz du marqueur de mouvement de stock effectué
    idxCurrentPosition  := aPreparedStockMovements.first;

    -- Mise à False du flag indiquant les enregistrements traités sur tous les
    -- enregistrements et suppression dans le même temps des liens composants liés
    -- (la suppression doit être faite avant d'appliquer les mouvements sinon il y a
    -- des problèmes de deadlock dans certains cas. Ex : 2 composants identiques).
    while idxCurrentPosition is not null loop
      aPreparedStockMovements(idxCurrentPosition).checked  := false;

      if nvl(aPreparedStockMovements(idxCurrentPosition).aFAL_COMPONENT_LINK_ID, 0) <> 0 then
        FAL_COMPONENT_LINK_FCT.DeleteComponentLink(aPreparedStockMovements(idxCurrentPosition).aFAL_COMPONENT_LINK_ID);
      end if;

      idxCurrentPosition                                   := aPreparedStockMovements.next(idxCurrentPosition);
    end loop;

    -- Parcours de la liste des mouvement de stock à exécuter
    idxCurrentPosition  := aPreparedStockMovements.first;
    aMaxidxPosition     := aPreparedStockMovements.count;
    aFinished           := false;

    while not aFinished loop
      idxMinposForGood  := idxCurrentPosition;
      CurrentGoodId     := aPreparedStockMovements(idxCurrentPosition).GoodId;

      -- Recherche de P2
      while(idxCurrentPosition <= aMaxidxPosition)
       and (aPreparedStockMovements(idxCurrentPosition).GoodId = CurrentGoodId) loop
        idxMaxPosForGood    := idxCurrentPosition;

        if idxCurrentPosition = aMaxidxPosition then
          afinished  := true;
        end if;

        idxCurrentPosition  := idxCurrentPosition + 1;
      end loop;

      -- on traite les mouvement ds un ordre bien particulier pour le produit en cours
      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabCompSor SOR TRF 017
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'SOR', 'TRF', '017', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabCompEnt ENT TRF 017
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'ENT', 'TRF', '017', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabConsom SOR FAC 017
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'SOR', 'FAC', '017', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabDecSor SOR TRF 018
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'SOR', 'TRF', '018', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabDecEnt ENT TRF 018
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'ENT', 'TRF', '018', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabRetSor SOR TRF 019
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'SOR', 'TRF', '019', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabRetEnt ENT TRF 019
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'ENT', 'TRF', '019', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabRcptReb ENT FAC 023
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'ENT', 'FAC', '023', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabRecept ENT FAC 020
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'ENT', 'FAC', '020', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter les FabDechet ENT FAC 018
        if     IsMvtKindCompatible(aPreparedStockMovements(j).MvtKindType, 'ENT', 'FAC', '018', aErrorCode, aErrorMsg)
           and (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      for j in idxMinPosForGood .. idxMaxPosForGood loop
        -- Traiter TOUS CEUX QUI RESTENT
        if (not aPreparedStockMovements(j).checked) then
          DoStockMovement(aPreparedStockMovements(j).MvtKindType
                        , aPreparedStockMovements(j).StockID
                        , aErrorCode
                        , aErrorMsg
                        , aPreparedStockMovements(j).LocationID
                        , aPreparedStockMovements(j).GoodID
                        , aPreparedStockMovements(j).LotID
                        , aPreparedStockMovements(j).Characterization1ID
                        , aPreparedStockMovements(j).Characterization2ID
                        , aPreparedStockMovements(j).Characterization3ID
                        , aPreparedStockMovements(j).Characterization4ID
                        , aPreparedStockMovements(j).Characterization5ID
                        , aPreparedStockMovements(j).Characterization1Value
                        , aPreparedStockMovements(j).Characterization2Value
                        , aPreparedStockMovements(j).Characterization3Value
                        , aPreparedStockMovements(j).Characterization4Value
                        , aPreparedStockMovements(j).Characterization5Value
                        , aPreparedStockMovements(j).MvtDate
                        , aPreparedStockMovements(j).MvtQty
                        , aPreparedStockMovements(j).MvtPrice
                        , aPreparedStockMovements(j).GoodPrice
                        , aPreparedStockMovements(j).CreatedFactoryStockPositionID
                        , MvtsContext
                        , aPreparedStockMovements(j).aFAL_NETWORK_LINK_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_IN_ID
                        , aPreparedStockMovements(j).aFAL_FACTORY_OUT_ID
                        , aPreparedStockMovements(j).aFactoryInOriginId
                        , aPreparedStockMovements(j).aFAL_LOT_MATERIAL_LINK_ID
                        , aFalHistoLotId
                         );
          aPreparedStockMovements(j).checked  := true;
        end if;
      end loop;

      idxMinPosForGood  := idxMaxPosForGood;
    end loop;
  exception
    when excUndefinedLocation then
      begin
        aErrorCode  := 'excUndefinedLocation';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20010, aErrorMsg);
        end if;
      end;
    when excUndefinedGood then
      begin
        aErrorCode  := 'excUndefinedGood';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20020, aErrorMsg);
        end if;
      end;
    when excUndefinedBatch then
      begin
        aErrorCode  := 'excUndefinedBatch';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20030, aErrorMsg);
        end if;
      end;
    when excUndefinedStockFloor then
      begin
        aErrorCode  := 'excUndefinedStockFloor';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20040, aErrorMsg);
        end if;
      end;
    when excUndefinedLocationFloor then
      begin
        aErrorCode  := 'excUndefinedLocationFloor';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20050, aErrorMsg);
        end if;
      end;
    when excUnDefinedMvtType then
      begin
        aErrorCode  := 'excUnDefinedMvtType';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20060, aErrorMsg);
        end if;
      end;
    when excUndefinedFirstMvtKind then
      begin
        aErrorCode  := 'excUndefinedFirstMvtKind';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20070, aErrorMsg);
        end if;
      end;
    when excUnAuthorizedMvt then
      begin
        aErrorCode  := 'excUnAuthorizedMvt';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20080, aErrorMsg);
        end if;
      end;
    when excUndefinedSecondMvtKind then
      begin
        aErrorCode  := 'excUndefinedSecondMvtKind';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20090, aErrorMsg);
        end if;
      end;
    when excUndefinedStockPosition then
      begin
        aErrorCode  := 'excUndefinedStockPosition';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20100, aErrorMsg);
        end if;
      end;
    when excBadMvtQtyOrPrice then
      begin
        aErrorCode  := 'excBadMvtQtyOrPrice';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20110, aErrorMsg);
        end if;
      end;
    when excNoActiveExcPeriod then
      begin
        aErrorCode  := 'excNoActiveExcPeriod';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20120, aErrorMsg);
        end if;
      end;
    when excTooManyActivePeriod then
      begin
        aErrorCode  := 'excTooManyActivePeriod';

        if aiShutdownExceptions = 0 then
          raise_application_error(-20130, aErrorMsg);
        end if;
      end;
    when others then
      begin
        if trim(aErrorCode) is null then
          aErrorCode  := 'excGenericException';
          aErrorMsg   := substr(replace(sqlerrm, 'ORA' || sqlcode || ':', ''), 1, 255);
        end if;

        if aiShutdownExceptions = 0 then
          raise_application_error(-20001, aErrorMsg);
        end if;
      end;
  end ApplyPreparedStockMovements;

  /**
  * function GetStockPositionFromCharact
  * description : récupération de l'ID d'une position de stock à partir de son stock
  *              ,emplacement et caractérisations.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_GOOD_ID                    Bien
  * @param   aSTM_STOCK_ID                   Stock
  * @param   aSTM_LOCATION_ID                Emplacement
  * @param   aSTM_CHARACTERIZATION_VALUE_1   Valeur Caract.1
  * @param   aSTM_CHARACTERIZATION_VALUE_2   Valeur Caract.2
  * @param   aSTM_CHARACTERIZATION_VALUE_3   Valeur Caract.3
  * @param   aSTM_CHARACTERIZATION_VALUE_4   Valeur Caract.4
  * @param   aSTM_CHARACTERIZATION_VALUE_5   Valeur Caract.5
  * @param   aSTM_STOCK_POSITION_ID          Position de stock trouvée
  */
  procedure GetStockPositionFromCharact(
    aGCO_GOOD_ID                  in     number
  , aSTM_STOCK_ID                 in     number
  , aSTM_LOCATION_ID              in     number
  , aSTM_CHARACTERIZATION_VALUE_1 in     varchar2
  , aSTM_CHARACTERIZATION_VALUE_2 in     varchar2
  , aSTM_CHARACTERIZATION_VALUE_3 in     varchar2
  , aSTM_CHARACTERIZATION_VALUE_4 in     varchar2
  , aSTM_CHARACTERIZATION_VALUE_5 in     varchar2
  , aSTM_STOCK_POSITION_ID        in out number
  )
  is
  begin
    select max(STM_STOCK_POSITION_ID)
      into aSTM_STOCK_POSITION_ID
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = aGCO_GOOD_ID
       and STM_STOCK_ID = aSTM_STOCK_ID
       and STM_LOCATION_ID = aSTM_LOCATION_ID
       and (    (    aSTM_CHARACTERIZATION_VALUE_1 is null
                 and GCO_CHARACTERIZATION_ID is null)
            or SPO_CHARACTERIZATION_VALUE_1 = aSTM_CHARACTERIZATION_VALUE_1)
       and (    (    aSTM_CHARACTERIZATION_VALUE_2 is null
                 and GCO_GCO_CHARACTERIZATION_ID is null)
            or SPO_CHARACTERIZATION_VALUE_2 = aSTM_CHARACTERIZATION_VALUE_2)
       and (    (    aSTM_CHARACTERIZATION_VALUE_3 is null
                 and GCO2_GCO_CHARACTERIZATION_ID is null)
            or SPO_CHARACTERIZATION_VALUE_3 = aSTM_CHARACTERIZATION_VALUE_3)
       and (    (    aSTM_CHARACTERIZATION_VALUE_4 is null
                 and GCO3_GCO_CHARACTERIZATION_ID is null)
            or SPO_CHARACTERIZATION_VALUE_4 = aSTM_CHARACTERIZATION_VALUE_4)
       and (    (    aSTM_CHARACTERIZATION_VALUE_5 is null
                 and GCO4_GCO_CHARACTERIZATION_ID is null)
            or SPO_CHARACTERIZATION_VALUE_5 = aSTM_CHARACTERIZATION_VALUE_5);
  end;

  /**
  * function UpdFactEntriesWthAppliedStkMvt
  * description : Pour chaque mouvement du tableau, recherche l'entrée atelier associée
  *               et renseigne sur celle-ci le mouvement de stock qui lui correspond
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aPreparedStockMovement    Tableau des mouvements de stock.
  */
  procedure UpdFactEntriesWthAppliedStkMvt(aPreparedStockMovements TPreparedStockMovements)
  is
    idx integer;
  begin
    null;

    if aPreparedStockMovements.count = 0 then
      return;
    end if;

    idx  := aPreparedStockMovements.first;

    while idx is not null loop
      if aPreparedStockMovements(idx).CreatedFactoryStockPositionID <> 0 then
        update FAL_FACTORY_IN
           set STM_STOCK_POSITION_ID = aPreparedStockMovements(idx).CreatedFactoryStockPositionID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_LOT_ID = aPreparedStockMovements(idx).LotID
           and GCO_GOOD_ID = aPreparedStockMovements(idx).GoodID
           and STM_LOCATION_ID = aPreparedStockMovements(idx).LocationID
           and (   aPreparedStockMovements(idx).Characterization1Value is null
                or (IN_CHARACTERIZATION_VALUE_1 = aPreparedStockMovements(idx).Characterization1Value)
               )
           and (   aPreparedStockMovements(idx).Characterization2Value is null
                or (IN_CHARACTERIZATION_VALUE_2 = aPreparedStockMovements(idx).Characterization2Value)
               )
           and (   aPreparedStockMovements(idx).Characterization3Value is null
                or (IN_CHARACTERIZATION_VALUE_3 = aPreparedStockMovements(idx).Characterization3Value)
               )
           and (   aPreparedStockMovements(idx).Characterization4Value is null
                or (IN_CHARACTERIZATION_VALUE_4 = aPreparedStockMovements(idx).Characterization4Value)
               )
           and (   aPreparedStockMovements(idx).Characterization5Value is null
                or (IN_CHARACTERIZATION_VALUE_5 = aPreparedStockMovements(idx).Characterization5Value)
               );
      end if;

      idx  := aPreparedStockMovements.next(idx);
    end loop;
  end;

  /**
  * procedure GenReversalMvt
  * description : Génération d'extournes partielles de mouvements lors de l'éclatement
  *               de lot de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSTM_STOCK_MOVEMENT_ID : Mouvement à extourner (l'extourne du mvt lié
  *                                   est également réalisée)
  * @param   aReverseQty : Qté à extourner
  */
  procedure GenReversalMvt(aSTM_STOCK_MOVEMENT_ID number, aReverseQty number)
  is
  begin
    -- Extourne des mouvements
    STM_PRC_MOVEMENT.GenerateReversalMvt(aSTM_STOCK_MOVEMENT_ID, aReverseQty, 1);
    -- Génération des éléments de coûts associés
    FAL_ACCOUNTING_FUNCTIONS.InsertReversalMatElementCost(aSTM_STOCK_MOVEMENT_ID, aReverseQty);
  end GenReversalMvt;

  /**
  * procedure UpdateKLSBuffer
  * description : Mise à jour de la table tampon des exports KLS. Dans le cas d'éclatement
  *               de lots, les mouvements à exporter sont marqués comme exporté, car ils ne doivent
  *               pas être retraités par le Kardex (Ils doivent physiquement rester en stock atelier)
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSTM_STOCK_MOVEMENT_ID : Mouvement à l'origine de l'export
  */
  procedure UpdateKLSBuffer(aSTM_STOCK_MOVEMENT_ID number)
  is
  begin
    update STM_KLS_BUFFER
       set KLS_EXPORT = 1
     where STM_STOCK_MOVEMENT_ID = aSTM_STOCK_MOVEMENT_ID;
  end UpdateKLSBuffer;
end;
