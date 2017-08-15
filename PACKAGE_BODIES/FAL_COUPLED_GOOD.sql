--------------------------------------------------------
--  DDL for Package Body FAL_COUPLED_GOOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COUPLED_GOOD" 
is
--
-- Créer le 24/10/2005 pour la tache PRD-A051005-62536 Modif Produit couplés
-- Auteur: Denis Jeanneret
--

  -- Processus Génération Détail Lot
  procedure GenerateOneDetailLot(
    iGoodId         in GCO_GOOD.GCO_GOOD_ID%type
  , iQty            in FAL_LOT.LOT_ASKED_QTY%type
  , iFalLotId       in FAL_LOT.FAL_LOT_ID%type
  , iRefGcgQty      in GCO_COUPLED_GOOD.GCG_REF_QUANTITY%type
  , iGcgQty         in GCO_COUPLED_GOOD.GCG_REF_QUANTITY%type
  , iLotRefcompl    in FAL_LOT.LOT_REFCOMPL%type
  , iCLotDetail     in FAL_LOT_DETAIL.C_LOT_DETAIL%type
  , iGcgIncludeGood in GCO_COUPLED_GOOD.GCG_INCLUDE_GOOD%type
  )
  is
    lnGcgTotalQty number;
    lnIDCar1      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIDCar2      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIDCar3      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIDCar4      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnIDCar5      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    -- récupérer les ID des caractérisations
    GCO_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => iGoodId
                                           , oCharactID_1   => lnIDCar1
                                           , oCharactID_2   => lnIDCar2
                                           , oCharactID_3   => lnIDCar3
                                           , oCharactID_4   => lnIDCar4
                                           , oCharactID_5   => lnIDCar5
                                            );

    select nvl(sum(nvl(FAD.FAD_QTY, 0) ), 0) GCG_QTY
      into lnGcgTotalQty
      from FAL_LOT_DETAIL FAD
     where FAD.FAL_LOT_ID = iFalLotId
       and FAD.GCO_GOOD_ID = iGoodId
       and FAD.C_LOT_DETAIL = '1';

    insert into FAL_LOT_DETAIL
                (FAL_LOT_DETAIL_ID
               , FAL_LOT_ID
               , FAD_LOT_REFCOMPL
               , GCO_GOOD_ID
               , FAD_QTY
               , FAD_BALANCE_QTY
               , GCG_REF_QTY
               , GCG_QTY
               , GCG_TOTAL_QTY
               , GCG_INCLUDE_GOOD
               , C_LOT_DETAIL
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , iFalLotId
               , iLotRefcompl
               , iGoodId
               , iQty - lnGcgTotalQty   -- FAD_QTY
               , iQty - lnGcgTotalQty   -- FAD_BALANCE_QTY
               , iRefGcgQty
               , iGcgQty
               , iQty   -- GCG_TOTAL_QTY
               , iGcgIncludeGood
               , iCLotDetail
               , lnIDCar1   -- GCO_CHARACTERIZATION_ID
               , lnIDCar2   -- GCO_GCO_CHARACTERIZATION_ID
               , lnIDCar3   -- GCO2_GCO_CHARACTERIZATION_ID
               , lnIDCar4   -- GCO3_GCO_CHARACTERIZATION_ID
               , lnIDCar5   -- GCO4_GCO_CHARACTERIZATION_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end;

-- Calculer la somme des Qté Par Qté Ref. pour les produits couplés inclus de la nomenclature
  function GetSumQteByRefOfCoupledDC(PrmGCO_COMPL_DATA_MANUFACTURE GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type)
    return number
  is
    SumQtyRef number;
  begin
    select nvl(sum(nvl(GCG_QUANTITY, 0) / nvl(GCG_REF_QUANTITY, 1) ), 0)
      into SumQtyRef
      from GCO_COUPLED_GOOD
     where GCO_COMPL_DATA_MANUFACTURE_ID = PrmGCO_COMPL_DATA_MANUFACTURE
       and GCG_INCLUDE_GOOD = 1;

    return SumQtyRef;
  end;

-- Calculer la somme des Qté Par Qté Ref. pour un produit donné
  function GetSumQteByRefOfCoupledGood(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return FAL_LOT.LOT_ASKED_QTY%type
  is
    aID      GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;
    Resultat FAL_LOT.LOT_ASKED_QTY%type;
  begin
    select GCO_COMPL_DATA_MANUFACTURE_ID
      into aId
      from GCO_COMPL_DATA_MANUFACTURE
     where GCO_GOOD_ID = PrmGCO_GOOD_ID
       and CMA_DEFAULT = 1;

    Resultat  := GetSumQteByRefOfCoupledDC(aID);
    return Resultat;
  exception
    -- Tout à fait possible, tous les produits ne sont pas des produits fabriqués.
    when no_data_found then
      return 0;
  end;

-- Création des appros pour les Produits couplés
  procedure CreateApproForCoupledGood(
    PrmGCO_COMPL_DATA_MANUFACTURE     GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type
  , prmCreatedPropID                  FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , PrmQteDemande                     FAL_LOT.LOT_ASKED_QTY%type
  , OutTOTQteCouple               out FAL_LOT.LOT_ASKED_QTY%type
  )
  is
    -- Pour chaque produit couplé de la donnée complémentaire de Fab.
    cursor CurCOUPLED_GOOD
    is
      select *
        from GCO_COUPLED_GOOD
       where
             -- De la donnée complémentaire
             GCo_COMPL_DATA_MANUFACTURE_ID = PrmGCO_COMPL_DATA_MANUFACTURE;

    EnrCOUPLED_GOOD CurCOUPLED_GOOD%rowtype;
    aQteCouple      FAL_LOT.LOT_ASKED_QTY%type;
    Inutilise_Ici   FAL_NETWORK_SUPPLY.FAl_NETWORK_SUPPLY_ID%type;
  begin
    OutTOTQteCouple  := 0;
    aQteCouple       := 0;

    -- Parcourir les Pdts couplés
    open CurCOUPLED_GOOD;

    loop
      fetch CurCOUPLED_GOOD
       into EnrCOUPLED_GOOD;

      exit when CurCOUPLED_GOOD%notfound;
      aQteCouple  :=
        FAL_TOOLS.ArrondiInferieur(PrmQteDemande *(nvl(EnrCOUPLED_GOOD.GCG_QUANTITY, 0) / nvl(EnrCOUPLED_GOOD.GCG_REF_QUANTITY, 1) )
                                 , EnrCOUPLED_GOOD.GCO_GCO_GOOD_ID
                                  );
      FAL_NETWORK_DOC.CreateReseauApproPropApproFabC(PrmCreatedPropID, Inutilise_Ici, aQteCouple, EnrCOUPLED_GOOD.GCO_GCO_GOOD_ID);

      -- Seulement pour les non inclus
      if EnrCOUPLED_GOOD.GCG_INCLUDE_GOOD = 1 then
        OutTOTQteCouple  := outTOTQteCouple + aQteCouple;
      end if;
    end loop;

    close CurCOUPLED_GOOD;
  end;

  -- Génération des détails lot pour les produits couplés
  procedure GENERATE_DETAIL_LOT(
    aFAL_LOT_ID               FAL_LOT.FAL_LOT_ID%type
  , aGCO_COMPL_MANUFACTURE_ID FAL_LOT.FAL_LOT_ID%type
  , aQte                      FAL_LOT.LOT_TOTAL_QTY%type
  , aForcedUpdate             integer default 0
  )
  is
    -- Pour chaque produit couplé de la donnée complémentaire de Fab.
    cursor crCoupledProduct
    is
      select GCO_GCO_GOOD_ID
           , GCG_QUANTITY
           , GCG_REF_QUANTITY
           , GCG_INCLUDE_GOOD
           , (select max(GCG_REF_QUANTITY)
                from GCO_COUPLED_GOOD
               where GCO_COMPL_DATA_MANUFACTURE_ID = aGCO_COMPL_MANUFACTURE_ID
                 and GCG_INCLUDE_GOOD = 1) MAX_REF_QTY
        from GCO_COUPLED_GOOD
       where GCO_COMPL_DATA_MANUFACTURE_ID = aGCO_COMPL_MANUFACTURE_ID;

    lnCoupledQty          number(15, 4);
    lnTotalIncludQty      number;
    lnSumRefIncludQty     number;
    lnMainProductRefQty   number;
    lnLotRefcompl         FAL_LOT.LOT_REFCOMPL%type;
    lnGoodId              number;
    lbCoupledProductFound boolean;
  begin
    if aForcedUpdate = 0 then
      delete      FAl_LOT_DETAIL
            where FAL_LOT_ID = aFAL_LOT_ID;
    end if;

    select LOT_REFCOMPL
         , GCO_GOOD_ID
      into lnLotRefcompl
         , lnGoodId
      from FAL_LOT
     where FAl_LOT_ID = aFAL_LOT_ID;

    lnTotalIncludQty       := 0;
    lnSumRefIncludQty      := 0;
    -- rechercher les Pdts couplés
    lbCoupledProductFound  :=(aForcedUpdate = 1);

    for tplCoupledProduct in crCoupledProduct loop
      -- Pour le produit référent on prend la quantité de référence maximale pour plus de précision
      lnMainProductRefQty  := tplCoupledProduct.MAX_REF_QTY;
      lnCoupledQty         := FAL_TOOLS.ArrondiInferieur(aQte *(tplCoupledProduct.GCG_QUANTITY / tplCoupledProduct.GCG_REF_QUANTITY), lnGoodId);

      if lnCoupledQty > 0 then
        lbCoupledProductFound  := true;
        -- Création du Détail lot couplé
        GenerateOneDetailLot(iGoodId           => tplCoupledProduct.GCO_GCO_GOOD_ID
                           , iQty              => lnCoupledQty
                           , iFalLotId         => aFAL_LOT_ID
                           , iRefGcgQty        => tplCoupledProduct.GCG_REF_QUANTITY
                           , iGcgQty           => tplCoupledProduct.GCG_QUANTITY
                           , iLotRefcompl      => lnLotRefcompl
                           , iCLotDetail       => '2'   -- C_LOT_DETAIL Couplé (par opposition à "Produit de référence" = 3)
                           , iGcgIncludeGood   => tplCoupledProduct.GCG_INCLUDE_GOOD
                            );

        if tplCoupledProduct.GCG_INCLUDE_GOOD = 1 then
          /* Pour les inclus, on calcule la somme de leur Qté Référence par rapport à la QtéRefMax (qui sera la quantité ref du produit référent)
             et le total des inclus. Ces valeurs servent ensuite à déterminer les Qté Couplé et Qté Ref du produit référent. */
          lnSumRefIncludQty  := lnSumRefIncludQty + (tplCoupledProduct.GCG_QUANTITY / tplCoupledProduct.GCG_REF_QUANTITY) * lnMainProductRefQty;
          lnTotalIncludQty   := lnTotalIncludQty + lnCoupledQty;
        end if;
      end if;
    end loop;

    if     lbCoupledProductFound
       and (aQte - lnTotalIncludQty > 0) then
      -- Création du détail lot Master
      GenerateOneDetailLot(lnGoodId
                         , aQte - lnTotalIncludQty
                         , aFAL_LOT_ID
                         , lnMainProductRefQty
                         , lnMainProductRefQty - lnSumRefIncludQty
                         , lnLotRefcompl
                         , '3'   -- C_LOT_DETAIL "Produit de référence" (par opposition à "Couplé" = 2)
                         , 1   -- GCG_INCLUDE_GOOD
                          );
    end if;
  end;

  -- Modif Produit couplés ajustage des Qtés des détails lot.
  procedure UpdateCoupledProductQty(iFalLotId FAL_LOT.FAL_LOT_ID%type, iNewQty FAL_LOT.LOT_TOTAL_QTY%type)
  is
    lNewFadQty FAL_LOT_DETAIL.FAD_QTY%type;
  begin
    -- Mise à jour des détails détails lots de couplés
    update FAL_LOT_DETAIL
       set FAD_QTY = FAL_TOOLS.ArrondiInferieur(iNewQty *(GCG_QTY / GCG_REF_QTY), GCO_GOOD_ID)
         , GCG_TOTAL_QTY = FAL_TOOLS.ArrondiInferieur(iNewQty *(GCG_QTY / GCG_REF_QTY), GCO_GOOD_ID)
         , FAD_BALANCE_QTY = FAD_BALANCE_QTY +( (FAL_TOOLS.ArrondiInferieur(iNewQty *(GCG_QTY / GCG_REF_QTY), GCO_GOOD_ID) ) - FAD_QTY)
     where FAL_LOT_ID = iFalLotId
       and C_LOT_DETAIL = 2;

    -- Calcul la nouvelle qté du détail "Produit de référence"
    -- Il faut prendre pour le calcul des Qtés déjà existante
    -- Tout les inclus
    -- +
    -- Tout ceux qui ne sont ni "couplés" ni "Produit de référence"
    select iNewQty - nvl(sum(FAD_QTY), 0)
      into lNewFadQty
      from FAL_LOT_DETAIL
     where FAL_LOT_ID = iFalLotId
       and (    (    GCG_INCLUDE_GOOD = 1
                 and C_LOT_DETAIL <> '3')
            or (    nvl(GCG_INCLUDE_GOOD, 0) = 0
                and C_LOT_DETAIL = '1') );

    update FAL_LOT_DETAIL
       set FAD_QTY = lNewFadQty
         , FAD_BALANCE_QTY = FAD_BALANCE_QTY +(lNewFadQty - FAD_QTY)
         , GCG_TOTAL_QTY = lNewFadQty
     where fal_lot_id = iFalLotId
       and C_LOT_DETAIL = 3;
  end;

  /**
  * procedure : ExistsDetailForCoupledGood
  * Description : Indique l'existance ou non de détails lots pour des produits couplés
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     aFAL_LOT_ID    Lot de fabrication
  * @return    true or false
  */
  function ExistsDetailForCoupledGood(aFAL_LOT_ID number)
    return integer
  is
    iresult integer;
  begin
    select least(count(*), 1)
      into iResult
      from FAL_LOT_DETAIL
     where FAL_LOT_ID = aFAL_LOT_ID
       and (   C_LOT_DETAIL = '2'
            or C_LOT_DETAIL = '3');

    return iresult;
  end;

  /**
  * procedure : IsProductWithCoupledGood
  * Description : Indique si le produit est avec gestion des produits couplés
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     aGCO_GOOD_ID    produit de référence
  * @return    0 ou 1
  */
  function IsProductWithCoupledGood(aGCO_GOOD_ID number)
    return integer
  is
    result integer;
  begin
    result  := 0;

    select distinct 1
               into result
               from gco_coupled_good
              where gco_good_id = aGCO_GOOD_ID;

    return result;
  exception
    when others then
      return 0;
  end;

  function ExistsCoupledForDataManuf(aGcoComplDataManufId number)
    return boolean
  is
    CoupledGoodCount integer;
  begin
    if nvl(aGcoComplDataManufId, 0) = 0 then
      return false;
    end if;

    select count(*)
      into CoupledGoodCount
      from GCO_COUPLED_GOOD
     where GCO_COMPL_DATA_MANUFACTURE_ID = aGcoComplDataManufId;

    return(CoupledGoodCount > 0);
  end;
end;
