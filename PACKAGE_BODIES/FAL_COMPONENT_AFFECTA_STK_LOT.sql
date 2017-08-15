--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_AFFECTA_STK_LOT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_AFFECTA_STK_LOT" 
is
  /**
  * procedure : Refresh_SPO_AVAILABLE_QTY
  * Description : R�cup�ration Qt� dispo position + Qt� attribu�e au besoin du
  *               composant concern�
  * @created ECA
  * @lastUpdate
  * @private
  * @param  aSTM_STOCK_POSITION_ID : Position de stock
  * @Return Qt� dispo pour l'affectation
  */
  function Refresh_SPO_AVAILABLE_QTY(aSTM_STOCK_POSITION_ID number)
    return number
  is
    result number;
  begin
    select nvl(SPO_AVAILABLE_QUANTITY, 0)
      into result
      from STM_STOCK_POSITION
     where STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID;

    return result;
  exception
    when others then
      return 0;
  end;

  /**
  * procedure : Refresh_SPO_ASSIGN_QTY
  * Description : R�cup�ration Qt� dispo position + Qt� attribu�e au besoin du
  *               composant concern�
  * @created ECA
  * @lastUpdate
  * @private
  * @param  aSTM_LOCATION_ID : Emplacement de stock
  * @Return Qt� dispo pour l'affectation
  */
  function Refresh_SPO_ASSIGN_QTY(aSTM_LOCATION_ID number, aFAL_LOT_MATERIAL_LINK_ID number)
    return number
  is
    result number;
  begin
    select nvl(sum(FNL.FLN_QTY), 0)
      into result
      from FAL_NETWORK_LINK FNL
         , FAL_NETWORK_NEED FNN
     where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
       and FNN.FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID
       and FNL.STM_STOCK_POSITION_ID in(select STM_STOCK_POSITION_ID
                                          from STM_STOCK_POSITION
                                         where STM_LOCATION_ID = aSTM_LOCATION_ID);

    return result;
  exception
    when others then
      return 0;
  end;

  /**
  * procedure : ParseLocationList
  * Description : Procedure utilitaire de parcours d'une liste de type
  *               [element1][separator][element2][separator]...etc
  *               Les tuples sont stock�s dans une structure type TLocationsToAffect
  * @created ECA
  * @lastUpdate
  * @public
  * @param aLocationList : Liste � parcourir
  * @Return aElement : Premier �l�ment trouv�
  * @param aSeparator : S�parateur
  * @param aElementFounded : Element trouv�
  */
  procedure ParseLocationList(aLocationList in out varchar2, aElement in out varchar2, aSeparator in varchar2, aElementFounded in out integer)
  is
    SeparatorPos integer;
  begin
    SeparatorPos  := instr(aLocationList, aSeparator);

    if SeparatorPos > 0 then
      aElementFounded  := 1;
      aElement         := substr(aLocationList, 0, SeparatorPos - 1);
      aLocationList    := substr(aLocationList, SeparatorPos + length(aSeparator), length(aLocationList) );
    else
      if aLocationList is not null then
        aElement       := aLocationList;
        aLocationList  := '';
      else
        aElementFounded  := 0;
        aElement         := '';
        aLocationList    := '';
      end if;
    end if;
  end;

  /**
  * procedure : ComponentGenForAllocation
  * Description : G�n�ration des composants temporaires.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param      aGCO_GOOD_ID : Composant
  * @param      aFCL_SESSION_ID : Session oracle
  * @param      aFAL_JOB_PROGRAM_ID : Programme de fabrication
  * @param      aC_PRIORITY : Priorit� des lots de fabrication
  * @param      aDOC_RECORD_ID : Dossier
  */
  procedure ComponentGenForAllocation(
    aGCO_GOOD_ID        number
  , aFCL_SESSION_ID     varchar2
  , aFAL_JOB_PROGRAM_ID number default null
  , aC_PRIORITY         varchar2 default null
  , aDOC_RECORD_ID      number default null
  )
  is
  begin
    -- G�n�ration des composants temporaires
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aSessionId         => aFCL_SESSION_ID
                                                  , aContext           => FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation
                                                  , aGcoGoodId         => aGCO_GOOD_ID
                                                  , aFalJobProgramId   => aFAL_JOB_PROGRAM_ID
                                                  , aCPriority         => aC_PRIORITY
                                                  , aDocRecordId       => aDOC_RECORD_ID
                                                   );
  end ComponentGenForAllocation;

  /**
  * procedure : LinksGenForAllocation
  * Description : G�n�ration des liens temporaires de r�servation pour
  *               l'affectation de composants.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFCL_SESSION_ID : Session oracle
  * @Param   aListOfLocation : String
  * @param   aBalanceNeed : Sodler besoin
  * @param   aAffectedqty : Qt� affect�e
  * @param   aGCO_GOOD_ID : produit concern� par l'affectation
  */
  procedure LinksGenForAllocation(
    aFCL_SESSION_ID in     varchar2
  , aListOfLocation in     varchar2
  , aBalanceNeed    in     integer
  , aAffectedQty    in out number
  , aGCO_GOOD_ID    in     number
  )
  is
    type TTabSTM_STOCK_POSITION is table of STM_PRC_STOCK_POSITION.gcurSPO%rowtype;

    -- Curseurs sur les composants temporaires
    cursor CUR_FAL_LOT_MAT_LINK_TMP
    is
      select   LOM.FAL_LOT_MAT_LINK_TMP_ID
             , LOM.LOM_NEED_QTY
             , LOM.GCO_GOOD_ID
             , LOT.LOT_REFCOMPL
             , LOT.FAL_LOT_ID
             , LOM.FAL_LOT_MATERIAL_LINK_ID
             , nvl(LOM.C_CHRONOLOGY_TYPE, '0') C_CHRONOLOGY_TYPE
             , FAL_TOOLS.PrcIsFullTracability(LOM.GCO_GOOD_ID) IS_FULL_TRACABILITY
             , LOM.STM_LOCATION_ID
          from FAL_LOT_MAT_LINK_TMP LOM
             , FAL_LOT LOT
         where LOM.LOM_SESSION = aFCL_SESSION_ID
           and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
           and LOM.LOM_NEED_QTY > (select nvl(sum(FCL.FCL_HOLD_QTY), 0) FCL_HOLD_QTY
                                     from FAL_COMPONENT_LINK FCL
                                    where FCL.FAL_LOT_MAT_LINK_TMP_ID = LOM.FAL_LOT_MAT_LINK_TMP_ID)
      order by LOM.LOM_NEED_DATE asc
             , LOT.LOT_REFCOMPL asc;

    CurFalLotMatLinkTmp     CUR_FAL_LOT_MAT_LINK_TMP%rowtype;
    aSumHoldedQty           number;
    aSumReturnQty           number;
    aSumTrashQty            number;
    aSumReplacedQty         number;
    aSumReplacingQty        number;
    aSumSPO_AVAILABLE_QTY   number;
    LocationsToAffect       TLocationsToAffect;
    aLocationIndex          integer;
    vElement1               varchar2(255);
    vElement2               varchar2(255);
    blnElement1Founded      integer;
    blnElement2Founded      integer;
    workLocationList        varchar2(32000);
    blnIsQtyHolded          integer;
    aQtyAffectedOnComponent number;
    aStrLocIDToAffect       varchar2(32000);
    aStrLocAffectOrder      varchar2(32000);
    TabSTM_STOCK_POSITION   TTabSTM_STOCK_POSITION;
    aUpdatedQtyToHold       number;
    aHoldedQty              number;

    -- R�cup�ration de la qt� � affecter par emplacement
    function GetQtyToAffectByLocation(aSTM_LOCATION_ID number)
      return number
    is
      result number;
    begin
      if LocationsToAffect.first is not null then
        result  := 0;

        for i in LocationsToAffect.first .. LocationsToAffect.last loop
          if LocationsToAffect(i).aSTM_LOCATION_ID = aSTM_LOCATION_ID then
            result  := LocationsToAffect(i).aQtyToAffect;
            exit;
          end if;
        end loop;

        return result;
      else
        return 0;
      end if;
    end GetQtyToAffectByLocation;

    -- R�cup�ration de la qt� � affecter par emplacement
    procedure SetQtyToAffectByLocation(aSTM_LOCATION_ID number, aQty number)
    is
    begin
      if LocationsToAffect.first is not null then
        for i in LocationsToAffect.first .. LocationsToAffect.last loop
          if LocationsToAffect(i).aSTM_LOCATION_ID = aSTM_LOCATION_ID then
            LocationsToAffect(i).aQtyToAffect  := LocationsToAffect(i).aInitialQtyToAffect - aQty;
            LocationsToAffect(i).aAffectedQty  := aQty;
            exit;
          end if;
        end loop;
      end if;
    end SetQtyToAffectByLocation;

    -- R�cup�ration de la qt� totale affect�e d'un composants
    function GetComponentAffectedQty(aFCL_SESSION_ID varchar2, aFAL_LOT_MAT_LINK_TMP_ID number, aSTM_LOCATION_ID number)
      return number
    is
      result number;
    begin
      result  := 0;

      select nvl(sum(FCL.FCL_HOLD_QTY), 0)
        into result
        from FAL_COMPONENT_LINK FCL
       where FCL.FCL_SESSION = aFCL_SESSION_ID
         and (   aFAL_LOT_MAT_LINK_TMP_ID is null
              or FCL.FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID)
         and (   aSTM_LOCATION_ID is null
              or FCL.STM_LOCATION_ID = aSTM_LOCATION_ID);

      return result;
    exception
      when others then
        return 0;
    end;
  begin
    aQtyAffectedOnComponent  := 0;

    -- Si l'on doit solder les besoins
    if aBalanceNeed = 1 then
      -- Initialisations, r�cup�ration des tuples emplacement / Quantit�s � saisir.
      aAffectedQty        := 0;
      aStrLocIDToAffect   := '0';
      LocationsToAffect   := TLocationsToAffect();
      -- Parse du param�tre liste des emplacements Formatage : emplacement1/qt�;emplacement2/qt�;.....etc
      workLocationList    := aListOfLocation;
      blnElement1founded  := 1;
      blnIsQtyHolded      := 0;

      loop
        exit when blnElement1founded = 0;
        -- R�cup�ration d'une �l�ment Emplacement/Qt�
        ParseLocationList(workLocationList, vElement1, ';', blnElement1Founded);
        blnElement2Founded  := 1;

        loop
          exit when blnElement2Founded = 0;
          -- R�cup�ration d'une �l�ment Emplacement/Qt�
          ParseLocationList(vElement1, vElement2, '/', blnElement2Founded);

          -- Ajout dans la table m�moire
          if     blnElement2Founded = 1
             and vElement1 is not null
             and vElement2 is not null then
            LocationsToAffect.extend;
            aLocationIndex                                         := LocationsToAffect.last;
            aStrLocIDToAffect                                      := aStrLocIDToAffect || ',' || nvl(vElement2, '0');
            LocationsToAffect(aLocationIndex).aSTM_LOCATION_ID     := to_number(nvl(vElement2, '0') );
            LocationsToAffect(aLocationIndex).aQtyToAffect         := to_number(nvl(vElement1, '0') );
            LocationsToAffect(aLocationIndex).aInitialQtyToAffect  := to_number(nvl(vElement1, '0') );
            LocationsToAffect(aLocationIndex).aAffectedQty         := 0;

            if LocationsToAffect(aLocationIndex).aQtyToAffect <> 0 then
              blnIsQtyHolded  := 1;
            end if;
          end if;
        end loop;
      end loop;

      -- Parcours des composants.
      open CUR_FAL_LOT_MAT_LINK_TMP;

      fetch CUR_FAL_LOT_MAT_LINK_TMP
       into CurFalLotMatLinkTmp;

      loop
        aQtyAffectedOnComponent  := 0;
        -- Tous les composants ont �t� parcourus, et les quantit�s r�serv�es
        exit when CUR_FAL_LOT_MAT_LINK_TMP%notfound;

        -- On attribue d'abord les quantit�s attribu�es au composant sur les emplacements de stock s�lectionn�s
        if LocationsToAffect.first is not null then
          for aLocationIndex in LocationsToAffect.first .. LocationsToAffect.last loop
            aUpdatedQtyToHold        :=
              least( (case
                        when BlnIsQtyHolded = 1 then GetQtyToAffectByLocation(LocationsToAffect(aLocationIndex).aSTM_LOCATION_ID)
                        else Refresh_SPO_ASSIGN_QTY(LocationsToAffect(aLocationIndex).aSTM_LOCATION_ID, CurFalLotMatLinkTmp.FAL_LOT_MATERIAL_LINK_ID)
                      end
                     )
                  , Refresh_SPO_ASSIGN_QTY(LocationsToAffect(aLocationIndex).aSTM_LOCATION_ID, CurFalLotMatLinkTmp.FAL_LOT_MATERIAL_LINK_ID)
                  , (CurFalLotMatLinkTmp.LOM_NEED_QTY - aQtyAffectedOnComponent)
                   );
            FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFromAttribution(aFCL_SESSION_ID
                                                                      , CurFalLotMatLinkTmp.FAL_LOT_MATERIAL_LINK_ID
                                                                      , CurFalLotMatLinkTmp.FAL_LOT_MAT_LINK_TMP_ID
                                                                      , aHoldedQty
                                                                      , CurFalLotMatLinkTmp.C_CHRONOLOGY_TYPE
                                                                      , CurFalLotMatLinkTmp.IS_FULL_TRACABILITY
                                                                      , LocationsToAffect(aLocationIndex).aSTM_LOCATION_ID
                                                                      , aUpdatedQtyToHold
                                                                      , 0
                                                                      , 0
                                                                      , 1
                                                                      , FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation
                                                                       );
            -- Qt� affect�e et restante � affecter de l'emplacement
            SetQtyToAffectByLocation(LocationsToAffect(aLocationIndex).aSTM_LOCATION_ID
                                   , GetComponentAffectedQty(aFCL_SESSION_ID, null, LocationsToAffect(aLocationIndex).aSTM_LOCATION_ID)
                                    );
            -- Qt� affect�e sur ce composant
            aQtyAffectedOnComponent  := GetComponentAffectedQty(aFCL_SESSION_ID, CurFalLotMatLinkTmp.FAL_LOT_MAT_LINK_TMP_ID, null);
          end loop;
        end if;

        -- S'il reste un besoin sur le composants � combler, alors on poursuit en affectant les Qt�s disponibles des emplacements.
        if CurFalLotMatLinkTmp.LOM_NEED_QTY - aQtyAffectedOnComponent > 0 then
          -- Requ�te d�finissant l'ordre de saisie sur les emplacements s�lectionn�s en fonctions des caract�risations (ex FIFO, LIFO...)
          -- Les positions des emplacements s�lectionn�s seront donc trait�es dans leur globalit� afin de respecter les r�gles de sortie
          -- de stock des composants.
          STM_PRC_STOCK_POSITION.BuildSTM_STOCK_POSITIONQuery(oSQLQuery            => aStrLocAffectOrder
                                                            , iLocationId          => CurFalLotMatLinkTmp.STM_LOCATION_ID
                                                            , iGoodId              => aGCO_GOOD_ID
                                                            , iForceLocation       => 1
                                                            , iLotId               => 0
                                                            , iInStrLocationList   => aStrLocIDToAffect
                                                            , iPriorityToAttribs   => 0
                                                             );

          execute immediate aStrLocAffectOrder
          bulk collect into TabSTM_STOCK_POSITION;

          if TabSTM_STOCK_POSITION.first is not null then
            for aLocationIndex in TabSTM_STOCK_POSITION.first .. TabSTM_STOCK_POSITION.last loop
              if    blnIsQtyHolded = 0
                 or (    blnIsQtyHolded = 1
                     and GetQtyToAffectByLocation(TabSTM_STOCK_POSITION(aLocationIndex).STM_LOCATION_ID) > 0) then
                aUpdatedQtyToHold        :=
                  least( (case
                            when BlnIsQtyHolded = 1 then GetQtyToAffectByLocation(TabSTM_STOCK_POSITION(aLocationIndex).STM_LOCATION_ID)
                            else Refresh_SPO_AVAILABLE_QTY(TabSTM_STOCK_POSITION(aLocationIndex).STM_STOCK_POSITION_ID)
                          end
                         )
                      , Refresh_SPO_AVAILABLE_QTY(TabSTM_STOCK_POSITION(aLocationIndex).STM_STOCK_POSITION_ID)
                      , (CurFalLotMatLinkTmp.LOM_NEED_QTY - aQtyAffectedOnComponent)
                       );

                if aUpdatedQtyToHold > 0 then
                  -- G�n�ration des liens de r�servation
                  FAL_COMPONENT_LINK_FCT.GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => CurFalLotMatLinkTmp.FAL_LOT_MAT_LINK_TMP_ID
                                                                     , aFAL_LOT_ID                => null
                                                                     , aLOM_SESSION               => aFCL_SESSION_ID
                                                                     , aContext                   => FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation
                                                                     , aBalanceNeed               => aBalanceNeed
                                                                     , aUseParamQty               => 1
                                                                     , aUpdatedQtyToHold          => aUpdatedQtyToHold
                                                                     , iLocationId                => TabSTM_STOCK_POSITION(aLocationIndex).STM_LOCATION_ID
                                                                     , aSelectFromAttribsFirst    => 0
                                                                      );
                end if;

                -- Qt� affect�e et restante � affecter de l'emplacement
                SetQtyToAffectByLocation(TabSTM_STOCK_POSITION(aLocationIndex).STM_LOCATION_ID
                                       , GetComponentAffectedQty(aFCL_SESSION_ID, null, TabSTM_STOCK_POSITION(aLocationIndex).STM_LOCATION_ID)
                                        );
                -- Qt� affect�e sur ce composant
                aQtyAffectedOnComponent  := GetComponentAffectedQty(aFCL_SESSION_ID, CurFalLotMatLinkTmp.FAL_LOT_MAT_LINK_TMP_ID, null);
              end if;
            end loop;
          end if;
        end if;

        fetch CUR_FAL_LOT_MAT_LINK_TMP
         into CurFalLotMatLinkTmp;
      end loop;

      close CUR_FAL_LOT_MAT_LINK_TMP;

      -- Qt� affect�e totale sur tous les composants
      aAffectedQty        := GetComponentAffectedQty(aFCL_SESSION_ID, null, null);
    end if;
  end;

  /**
  * procedure : DoComponentAllocation
  * Description : Validation de l'affectation des composants de stock vers lot
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFCL_SESSION_ID : Session oracle
  * @param   aAllocationDate : DateAffectation
  * @return  aErrorCode : Code retour d'erreur
  * @return  aErrorMsg : Message d'erreur
  * @param   aiShutDownExceptions : indique si l'on doit faire le raise depuis le PL
  */
  procedure DoComponentAllocation(
    aFCL_SESSION_ID      in     varchar2
  , aAllocationDate      in     date
  , aErrorCode           in out varchar2
  , aErrorMsg            in out varchar2
  , aiShutdownExceptions        integer default 0
  )
  is
    -- Curseur de d�finition de structure (destin� � recevoir les positions de stock s�lectionn�es pour r�servation)
    cursor CUR_COMPONENT_TO_ALLOCATE
    is
      select distinct LOM.FAL_LOT_MATERIAL_LINK_ID
                    , LOM.FAL_LOT_MAT_LINK_TMP_ID
                    , LOM.FAL_LOT_ID
                 from FAL_LOT_MAT_LINK_TMP LOM
                    , FAL_COMPONENT_LINK FCL
                where LOM.LOM_SESSION = aFCL_SESSION_ID
                  and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID;

    type TCurComponentToAllocate is table of CUR_COMPONENT_TO_ALLOCATE%rowtype;

    CurComponentToAllocate TCurComponentToAllocate;
    strComponentToAllocate varchar2(4000);
    NbComp                 integer;
  begin
    -- Pr�paration de la liste des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.InitPreparedStockMovement;
    -- Requ�te de s�lection des composants necessitant un mvt
    strComponentToAllocate  :=
      ' select Distinct LOM.FAL_LOT_MATERIAL_LINK_ID ' ||
      '      , LOM.FAL_LOT_MAT_LINK_TMP_ID ' ||
      '      , LOM.FAL_LOT_ID ' ||
      '   from FAL_LOT_MAT_LINK_TMP LOM ' ||
      '      , FAL_COMPONENT_LINK FCL ' ||
      '  where LOM.LOM_SESSION = :aFCL_SESSION_ID ' ||
      '    and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID ';

    execute immediate strComponentToAllocate
    bulk collect into CurComponentToAllocate
                using aFCl_SESSION_ID;

    -- Parcours des composants � affecter
    if CurComponentToAllocate.first is not null then
      for nbComp in CurComponentToAllocate.first .. CurComponentToAllocate.last loop
        -- Mise � jour du composant du lot de fabrication
        FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aFCL_SESSION_ID
                                                             , CurComponentToAllocate(NbComp).FAL_LOT_ID
                                                             , CurComponentToAllocate(NbComp).FAL_LOT_MATERIAL_LINK_ID
                                                             , FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation
                                                              );
        -- Mise � jour du lot de fabrication (qt� max r�ceptionnable)
        FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(CurComponentToAllocate(NbComp).FAL_LOT_ID, -1);
        -- Mise � jour de l'ordre de fabrication
        FAL_ORDER_FUNCTIONS.UpdateOrder(0, CurComponentToAllocate(NbComp).FAL_LOT_ID);
        -- Cr�ation des sortie de stocks conso vers le stock atelier
        FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID                 => CurComponentToAllocate(NbComp).FAL_LOT_ID
                                                        , aFCL_SESSION                => aFCL_SESSION_ID
                                                        , aPreparedStockMovement      => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                        , aOUT_DATE                   => aAllocationDate
                                                        , aMovementKind               => FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier
                                                        , aC_IN_ORIGINE               => '4'
                                                        , aFAL_LOT_MATERIAL_LINK_ID   => CurComponentToAllocate(NbComp).FAL_LOT_MATERIAL_LINK_ID
                                                         );
        -- Purge des liens composants temporaires (lib�rations des qt� provisoires)
        FAL_COMPONENT_LINK_FUNCTIONS.PurgeComponentLink(CurComponentToAllocate(NbComp).FAL_LOT_MAT_LINK_TMP_ID, aFCL_SESSION_ID);
      end loop;
    end if;

    -- Mise � jour des r�seaux (Sortie de la boucle pr�c�dente pour �viter les deadlock).
    if CurComponentToAllocate.first is not null then
      for nbComp in CurComponentToAllocate.first .. CurComponentToAllocate.last loop
        FAL_NETWORK.MiseAJourReseaux(CurComponentToAllocate(nbComp).FAL_LOT_ID, FAL_NETWORK.ncAffectationComposantStockLot, '');
      end loop;
    end if;

    -- G�n�ration des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                           , aErrorCode
                                                           , aErrorMsg
                                                           , FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                           , aiShutDownExceptions
                                                            );
    -- Mise � jour des entr�es atelier avec les positions de stock cr��es dans le stock Atelier par les mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements);
  exception
    when others then
      raise;
  end DoComponentAllocation;

  /**
  * procedure : GetAffectedQty
  * Description : R�cup�ration de la somme des qt�s affect�es
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFCL_SESSION_ID : Session oracle
  * @param   aSTM_LOCATION_ID
  */
  procedure GetAffectedQty(aFCL_SESSION_ID in varchar2, aSTM_LOCATION_ID in number default null, aAffectedQty in out number)
  is
  begin
    select sum(nvl(FCL_HOLD_QTY, 0) )
      into aAffectedQty
      from FAL_COMPONENT_LINK
     where FCL_SESSION = aFCL_SESSION_ID
       and (   nvl(aSTM_LOCATION_ID, 0) = 0
            or STM_LOCATION_ID = aSTM_LOCATION_ID);
  exception
    when others then
      aAffectedQty  := 0;
  end;
end;
