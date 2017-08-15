--------------------------------------------------------
--  DDL for Package Body FAL_LIB_ALLOY_INVENTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_ALLOY_INVENTORY" 
is
  /**
  * Description
  *    Cette fonction retourne le nombre de ligne d'inventaire à traiter.
  */
  function getNbLinesToProcess(inFalAlloyInventoryID in FAL_ALLOY_INVENTORY.FAL_ALLOY_INVENTORY_ID%type)
    return number
  as
    lnNbLines number;
  begin
    select nvl(count(FAL_LINE_INVENTORY_ID), 0)
      into lnNbLines
      from FAL_LINE_INVENTORY
     where FAL_ALLOY_INVENTORY_ID = inFalAlloyInventoryID
       and FLI_SELECT = 1
       and C_LINE_STATUS <> '3';

    return lnNbLines;
  exception
    when no_data_found then
      return 0;
  end getNbLinesToProcess;

/**
  * procedure getNbLinesToExtract4Type1
  * Description
  *    Cette fonction retourne le nombre de ligne d'inventaire à extraire pour un
  *    un inventaire matière précieuse par Poste/Alliage. Cettte fonction ne soustrait
  *    pas les lignes déjà extraites au nombre de ligne à extraire.
  * @created age 28.03.2012
  * @lastUpdate
  * @public
  * @param inFalAlloyInventoryID     : Inventaire matière précieuse
  * @param inFalPositionID           : Poste de matière précieuse
  * @param inGcoAlloyID              : Alliage à inventorier
  * @param ivDicFreePosition1ID      : Position libre
  * @param ivDicFreePosition2ID      : Position libre
  * @param ivDicFreePosition3ID      : Position libre
  * @param ivDicFreePosition4ID      : Position libre
  * @param idFpiFromNextDateInvent   : Date de
  * @param idFpiToNextDateInvent     : Date à
  * @param ioNbLines : le nombre de lignes à traiter.
  */
  procedure getNbLinesToExtract4Type1(
    inFalAlloyInventoryID   in FAL_ALLOY_INVENTORY.FAL_ALLOY_INVENTORY_ID%type
  , inFalPositionID         in FAL_POSITION.FAL_POSITION_ID%type
  , inGcoAlloyID            in GCO_ALLOY.GCO_ALLOY_ID%type
  , ivDicFreePosition1ID    in DIC_FREE_POSITION1.DIC_FREE_POSITION1_ID%type
  , ivDicFreePosition2ID    in DIC_FREE_POSITION2.DIC_FREE_POSITION2_ID%type
  , ivDicFreePosition3ID    in DIC_FREE_POSITION3.DIC_FREE_POSITION3_ID%type
  , ivDicFreePosition4ID    in DIC_FREE_POSITION4.DIC_FREE_POSITION4_ID%type
  , idFpiFromNextDateInvent in FAL_POSITION_INIT_QTY.FPI_NEXT_DATE_INVENT%type
  , idFpiToNextDateInvent   in FAL_POSITION_INIT_QTY.FPI_NEXT_DATE_INVENT%type
  , ioNbLines               in out integer
  )
  is
    lnFalPositionInitQtyID FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type;
  begin
    ioNbLines  := 0;

    /* Pour chaque poste sélectionné */
    for ltplFalPositions in (select distinct FAL_POSITION_ID
                                           , STM_STOCK_ID
                                        from FAL_POSITION
                                       where (   nvl(inFalPositionID, 0) = 0
                                              or FAL_POSITION_ID = inFalPositionID)
                                         and (   nvl(ivDicFreePosition1ID, '*') = '*'
                                              or DIC_FREE_POSITION1_ID = ivDicFreePosition1ID)
                                         and (   nvl(ivDicFreePosition2ID, '*') = '*'
                                              or DIC_FREE_POSITION2_ID = ivDicFreePosition2ID)
                                         and (   nvl(ivDicFreePosition3ID, '*') = '*'
                                              or DIC_FREE_POSITION3_ID = ivDicFreePosition3ID)
                                         and (   nvl(ivDicFreePosition4ID, '*') = '*'
                                              or DIC_FREE_POSITION4_ID = ivDicFreePosition4ID) ) loop
      /* Pour chaque alliage */
      for ltplGcoAlloy in (select distinct GAL.GCO_ALLOY_ID
                                      from GCO_ALLOY GAL
                                     where (   nvl(inGcoAlloyID, 0) = 0
                                            or GAL.GCO_ALLOY_ID = inGcoAlloyID) ) loop
        /* Création de la position si inexistante */
        lnFalPositionInitQtyID  :=
          FAL_PRC_ALLOY_INVENTORY.createInventoryPos(inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                                                   , inGcoGoodID             => null
                                                   , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                                                   , ivCAlloyInventoryType   => '1'
                                                    );

        /* Pour chaque position correspondant aux dates "de... à..." */
        for ltplFalPositionInitQty in (select FAL_POSITION_INIT_QTY_ID
                                         from FAL_POSITION_INIT_QTY
                                        where FAL_POSITION_ID = ltplFalPositions.FAL_POSITION_ID
                                          and GCO_ALLOY_ID = ltplGcoAlloy.GCO_ALLOY_ID
                                          and GCO_GOOD_ID is null
                                          and (   FPI_NEXT_DATE_INVENT is null
                                               or (     (   idFpiFromNextDateInvent is null
                                                         or FPI_NEXT_DATE_INVENT >= idFpiFromNextDateInvent)
                                                   and (   idFpiToNextDateInvent is null
                                                        or FPI_NEXT_DATE_INVENT <= idFpiToNextDateInvent)
                                                  )
                                              ) ) loop
          /* incrémentation du nombre de ligne à extraire */
          ioNbLines  := ioNbLines + 1;
        end loop;
      end loop;
    end loop;
  end getNbLinesToExtract4Type1;
end FAL_LIB_ALLOY_INVENTORY;
