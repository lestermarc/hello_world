--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_LINK_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_LINK_FCT" 
is
  cInitLotRefCompl         constant boolean      := PCS.PC_CONFIG.GetBooleanConfig('FAL_INIT_LOTREFCOMPL');
  cInitLotRefCompl2        constant varchar2(50) := PCS.PC_CONFIG.GetConfig('FAL_INIT_LOTREFCOMPL2');
  cUseLocationSelectLaunch constant boolean      := PCS.PC_CONFIG.GetBooleanConfig('FAL_USE_LOCATION_SELECT_LAUNCH');
  cLocationSelectLaunch    constant integer      := to_number(PCS.PC_CONFIG.GetConfig('FAL_LOCATION_SELECT_LAUNCH') );
  cPairingCaract           constant varchar2(10) := PCS.PC_CONFIG.GetConfig('FAL_PAIRING_CHARACT') || ',3';
  cAutoInitCharCpt         constant varchar2(10) := PCS.PC_CONFIG.GetConfig('FAL_AUTO_INIT_CHARAC_COMP');
  cWorkshopStockId         constant number       := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_FLOOR');
  cWorkshopLocationId      constant number   := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_FLOOR', FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_FLOOR') );

  /**
  * procedure : FormatQtyWithDecimalNumber
  * Description : Formatage des qt�s avec le nombre de d�cimales
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param  aFCL_HOLD_QTY : Quantit� saisie
  * @param  aFCL_RETURN_QTY : Quantit� retour
  * @param  aFCL_TRASH_QTY : Quantit� d�chet
  * @param  aFAL_LOT_MAT_LINK_TMP_ID : Composant temporaire
  */
  procedure FormatQtyWithDecimalNumber(
    aFCL_HOLD_QTY            in out number
  , aFCL_RETURN_QTY          in out number
  , aFCL_TRASH_QTY           in out number
  , aFAL_LOT_MAT_LINK_TMP_ID in     number
  )
  is
    liDigits integer := 0;
  begin
    if aFAL_LOT_MAT_LINK_TMP_ID is not null then
      select nvl(FAL_TOOLS.GetGoo_Number_Of_Decimal(LOM.GCO_GOOD_ID), 0)
        into liDigits
        from FAL_LOT_MAT_LINK_TMP LOM
       where LOM.FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID;
    end if;

    aFCL_HOLD_QTY    := round(aFCL_HOLD_QTY, liDigits);
    aFCL_RETURN_QTY  := round(aFCL_RETURN_QTY, liDigits);
    aFCL_TRASH_QTY   := round(aFCL_TRASH_QTY, liDigits);
  exception
    when others then
      null;
  end;

  /**
  * fonction : GetComponentQtyOnFactory
  * Description : R�cup�ration des quantit�s saisies du composant temporaire, portant
  *               sur les entr�es atelier.
  * @created ECA
  * @lastUpdate
  * @public
  * @param  aLOM_SESSION   Composant
  * @param  aFAL_LOT_MAT_LINK_TMP_ID : Composant temporaire
  * @return Qt� saisie
  */
  function GetComponentQtyOnFactory(aLOM_SESSION in varchar2, aFAL_LOT_MAT_LINK_TMP_ID in number)
    return number
  is
    aFCL_HOLD_QTY number;
  begin
    select sum(nvl(FCL.FCL_HOLD_QTY, 0) )
      into aFCL_HOLD_QTY
      from FAL_COMPONENT_LINK FCL
     where FCL.FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID
       and FCL.FCL_SESSION = aLOM_SESSION
       and FCL.FAL_FACTORY_IN_ID is not null;

    return nvl(aFCL_HOLD_QTY, 0);
  exception
    when no_data_found then
      return 0;
  end;

  /**
  * proc�dure SumOfComponentAttributions
  * Description : Somme des quantit�s attribu�es pour le composant
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_MATERIAL_LINK_ID      Composant
  * @param   aSTM_STOCK_ID                  Stock
  */
  function SumOfComponentAttributions(
    aFAL_LOT_MATERIAL_LINK_ID FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , aSTM_STOCK_ID             STM_STOCK.STM_STOCK_ID%type default null
  , aSTM_LOCATION_ID          STM_LOCATION.STM_LOCATION_ID%type default null
  )
    return FAL_NETWORK_LINK.FLN_QTY%type
  is
    aSumFlnQty FAL_NETWORK_LINK.FLN_QTY%type;
  begin
    if aSTM_LOCATION_ID is not null then
      select sum(FLN_QTY)
        into aSumFlnQty
        from FAL_NETWORK_LINK FNL
           , STM_STOCK_POSITION SST
       where FNL.STM_STOCK_POSITION_ID is not null
         and FNL.STM_STOCK_POSITION_ID = SST.STM_STOCK_POSITION_ID
         and SST.STM_LOCATION_ID = aSTM_LOCATION_ID
         and FAL_NETWORK_NEED_ID in(select FAL_NETWORK_NEED_ID
                                      from FAL_NETWORK_NEED
                                     where FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID);
    elsif aSTM_STOCK_ID is not null then
      select sum(FLN_QTY)
        into aSumFlnQty
        from FAL_NETWORK_LINK FNL
           , STM_STOCK_POSITION SST
       where FNL.STM_STOCK_POSITION_ID is not null
         and FNL.STM_STOCK_POSITION_ID = SST.STM_STOCK_POSITION_ID
         and SST.STM_STOCK_ID = aSTM_STOCK_ID
         and FAL_NETWORK_NEED_ID in(select FAL_NETWORK_NEED_ID
                                      from FAL_NETWORK_NEED
                                     where FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID);
    else
      select sum(FLN_QTY)
        into aSumFlnQty
        from FAL_NETWORK_LINK
       where STM_STOCK_POSITION_ID is not null
         and FAL_NETWORK_NEED_ID in(select FAL_NETWORK_NEED_ID
                                      from FAL_NETWORK_NEED
                                     where FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID);
    end if;

    return nvl(aSumFlnQty, 0);
  exception
    when no_data_found then
      return 0;
  end;

  /**
  * proc�dure CreateCompoLinkFalFactoryIn
  * Description : Cr�e un lien entre un composant de lot et une entr�e atelier destin� au retour de composants.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMatLinkTmpId    ID du composant temporaire de lot
  * @param   aFalfactoryInId        ID de l'entr�e atelier
  * @param   aTrashQty              Qt� d�chet
  * @param   aReturnQty             Qt� retour
  * @param   aHoldQty               Qt� Saisie
  */
  procedure CreateCompoLinkFalFactoryIn(
    aSessionId          FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMatLinkTmpId FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , aFalFactoryInId     FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type
  , aTrashQty           number default 0
  , aReturnQty          number default 0
  , aHoldQty            number default 0
  , iLocationId         number default null
  )
  is
  begin
    if    nvl(aTrashQty, 0) > 0
       or nvl(aReturnQty, 0) > 0
       or nvl(aHoldQty, 0) > 0 then
      insert into FAL_COMPONENT_LINK
                  (FAL_COMPONENT_LINK_ID
                 , FCL_SESSION
                 , FAL_LOT_MAT_LINK_TMP_ID
                 , FAL_LOT_ID
                 , GCO_GOOD_ID
                 , FCL_HOLD_QTY
                 , FCL_TRASH_QTY
                 , FCL_RETURN_QTY
                 , GCO_CHARACTERIZATION1_ID
                 , GCO_CHARACTERIZATION2_ID
                 , GCO_CHARACTERIZATION3_ID
                 , GCO_CHARACTERIZATION4_ID
                 , GCO_CHARACTERIZATION5_ID
                 , FCL_CHARACTERIZATION_VALUE_1
                 , FCL_CHARACTERIZATION_VALUE_2
                 , FCL_CHARACTERIZATION_VALUE_3
                 , FCL_CHARACTERIZATION_VALUE_4
                 , FCL_CHARACTERIZATION_VALUE_5
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , STM_STOCK_POSITION_ID
                 , FAL_FACTORY_IN_ID
                 , FAL_NETWORK_LINK_ID
                 , FCL_SELECTED
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , aSessionId
             , aFalLotMatLinkTmpId
             , FLML.FAL_LOT_ID
             , FLML.GCO_GOOD_ID
             , nvl(aHoldQty, 0)
             , nvl(aTrashQty, 0)
             , nvl(aReturnQty, 0)
             , FIN.GCO_CHARACTERIZATION_ID
             , FIN.GCO_GCO_CHARACTERIZATION_ID
             , FIN.GCO2_GCO_CHARACTERIZATION_ID
             , FIN.GCO3_GCO_CHARACTERIZATION_ID
             , FIN.GCO4_GCO_CHARACTERIZATION_ID
             , FIN.IN_CHARACTERIZATION_VALUE_1
             , FIN.IN_CHARACTERIZATION_VALUE_2
             , FIN.IN_CHARACTERIZATION_VALUE_3
             , FIN.IN_CHARACTERIZATION_VALUE_4
             , FIN.IN_CHARACTERIZATION_VALUE_5
             , (select STM_STOCK_ID
                  from STM_LOCATION
                 where STM_LOCATION_ID = nvl(iLocationId, FIN.STM_LOCATION_ID) )
             , nvl(iLocationId, FIN.STM_LOCATION_ID)
             , null   -- STM_STOCK_POSITION_ID
             , FIN.FAL_FACTORY_IN_ID
             , null   -- FAL_NETWORK_LINK_ID
             , 0   -- FCL_SELECTED
             , sysdate
             , PCS.PC_INIT_SESSION.GetUserIni
          from FAL_LOT_MAT_LINK_TMP FLML
             , FAL_FACTORY_IN FIN
         where FLML.FAL_LOT_MAT_LINK_TMP_ID = aFalLotMatLinkTmpId
           and FIN.FAL_FACTORY_IN_ID = aFalFactoryInId;
    end if;
  end;

  /**
  * proc�dure CreateCompoLinkStockAvalaible
  * Description
  *   Cr�e une r�servation entre un composant de lot et une position de stock
  *   (la r�servation sur le stock se fait par trigger sur la table FAL_COMPONENT_LINK)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMatLinkTmpId    ID du composant temporaire de lot
  * @param   aStmStockPositionId    ID de la position de stock
  * @param   aHoldQty                   Quantit� � r�serv�
  */
  procedure CreateCompoLinkStockAvalaible(
    aSessionId          FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMatLinkTmpId FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , aStmStockPositionId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , aHoldQty            FAL_COMPONENT_LINK.FCL_HOLD_QTY%type default 0
  , aTrashQty           FAL_COMPONENT_LINK.FCL_TRASH_QTY%type default 0
  , aReturnQty          FAL_COMPONENT_LINK.FCL_RETURN_QTY%type default 0
  , aContext            number default ctxNull
  )
  is
  begin
    if     (    (    (nvl(aHoldQty, 0) > 0)
                 or (nvl(aTrashQty, 0) > 0)
                 or (nvl(aReturnQty, 0) > 0) )
            or (aContext = ctxtSubContractPReturn)
            or (aContext = ctxtSubContractOReturn)
           )
       and nvl(aStmStockPositionId, 0) <> 0 then
      insert into FAL_COMPONENT_LINK
                  (FAL_COMPONENT_LINK_ID
                 , FCL_SESSION
                 , FAL_LOT_MAT_LINK_TMP_ID
                 , FAL_LOT_ID
                 , GCO_GOOD_ID
                 , FCL_HOLD_QTY
                 , FCL_TRASH_QTY
                 , FCL_RETURN_QTY
                 , GCO_CHARACTERIZATION1_ID
                 , GCO_CHARACTERIZATION2_ID
                 , GCO_CHARACTERIZATION3_ID
                 , GCO_CHARACTERIZATION4_ID
                 , GCO_CHARACTERIZATION5_ID
                 , FCL_CHARACTERIZATION_VALUE_1
                 , FCL_CHARACTERIZATION_VALUE_2
                 , FCL_CHARACTERIZATION_VALUE_3
                 , FCL_CHARACTERIZATION_VALUE_4
                 , FCL_CHARACTERIZATION_VALUE_5
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , STM_STOCK_POSITION_ID
                 , FAL_FACTORY_IN_ID
                 , FAL_NETWORK_LINK_ID
                 , FCL_SELECTED
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , aSessionId
             , aFalLotMatLinkTmpId
             , FLML.FAL_LOT_ID
             , FLML.GCO_GOOD_ID
             , case FLML.C_KIND_COM
                 when '2' then nvl(aHoldQty, 0)
                 else least(nvl(aHoldQty, 0)
                          , (SSP.SPO_AVAILABLE_QUANTITY -
                             decode(aContext
                                  , ctxtSubContractPTransfer, DOC_LIB_SUBCONTRACTP.GetCompDelivQty(FLML.FAL_LOT_MATERIAL_LINK_ID, SSP.STM_LOCATION_ID, 1)
                                  , ctxtSubContractOTransfer, DOC_LIB_SUBCONTRACTO.GetCompDelivQty(FLML.FAL_LOT_MATERIAL_LINK_ID, SSP.STM_LOCATION_ID, 1)
                                  , 0
                                   )
                            )
                           )
               end
             , nvl(aTrashQty, 0)
             , nvl(aReturnQty, 0)
             , SSP.GCO_CHARACTERIZATION_ID
             , SSP.GCO_GCO_CHARACTERIZATION_ID
             , SSP.GCO2_GCO_CHARACTERIZATION_ID
             , SSP.GCO3_GCO_CHARACTERIZATION_ID
             , SSP.GCO4_GCO_CHARACTERIZATION_ID
             , SSP.SPO_CHARACTERIZATION_VALUE_1
             , SSP.SPO_CHARACTERIZATION_VALUE_2
             , SSP.SPO_CHARACTERIZATION_VALUE_3
             , SSP.SPO_CHARACTERIZATION_VALUE_4
             , SSP.SPO_CHARACTERIZATION_VALUE_5
             , SSP.STM_STOCK_ID
             , SSP.STM_LOCATION_ID
             , aStmStockPositionId
             , null   -- FAL_FACTORY_IN_ID
             , null   -- FAL_NETWORK_LINK_ID
             , 0   -- FCL_SELECTED
             , sysdate
             , PCS.PC_INIT_SESSION.GetUserIni
          from FAL_LOT_MAT_LINK_TMP FLML
             , STM_STOCK_POSITION SSP
         where FLML.FAL_LOT_MAT_LINK_TMP_ID = aFalLotMatLinkTmpId
           and SSP.STM_STOCK_POSITION_ID = aStmStockPositionId;
    end if;
  end;

  /**
  * proc�dure GetCharactElements
  * Description
  *   R�cup�re les donn�es de caract�risation d'un bien dans un record
  * @created CLE
  * @lastUpdate
  * @public
  * @param   iGcoGoodId        Id du bien � rechercher
  * @return  un tuple avec les donn�es de caract. (Id, type, ...)
  */
  function GetCharactElements(iGcoGoodId number)
    return TCharactElements
  is
    tplCharactElements TCharactElements;
  begin
    -- Recherche du genre de mouvement de r�ception d'un produit d�riv�
    tplCharactElements.MovementKindId  := FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindByProductRecept;
    -- recherche la liste des caract�risations du bien du lot
    GCO_I_LIB_CHARACTERIZATION.GetListOfCharacterization(iGcoGoodId
                                                       , 0
                                                       , 'ENT'
                                                       , '2'
                                                       , tplCharactElements.Charac1Id
                                                       , tplCharactElements.Charac2Id
                                                       , tplCharactElements.Charac3Id
                                                       , tplCharactElements.Charac4Id
                                                       , tplCharactElements.Charac5Id
                                                       , tplCharactElements.CharacType1
                                                       , tplCharactElements.CharacType2
                                                       , tplCharactElements.CharacType3
                                                       , tplCharactElements.CharacType4
                                                       , tplCharactElements.CharacType5
                                                       , tplCharactElements.CharacStk1
                                                       , tplCharactElements.CharacStk2
                                                       , tplCharactElements.CharacStk3
                                                       , tplCharactElements.CharacStk4
                                                       , tplCharactElements.CharacStk5
                                                       , tplCharactElements.PieceManagement
                                                        );
    return tplCharactElements;
  end;

  /**
  * proc�dure CreateCompoLinkForDerived
  * Description
  *   Cr�e une r�servation entre un composant de lot type "d�riv�" et un emplacement de stock
  * @created CLE
  * @lastUpdate
  * @public
  * @param   iFalLotMatLinkTmpId        Id du composant temporaire de lot
  * @param   iQty                       Quantit� du lien composant
  * @param   iStmStockId                Id du stock
  * @param   aStmLocationId             Id de l'emplacement de stock
  * @param   iCharacVal1 � iCharacVal1  Valeurs de caract�risation du composant
  */
  procedure CreateCompoLinkForDerived(
    iFalLotMatLinkTmpId in     number
  , iGcoGoodId          in     number
  , iFalComponentLinkId in     number default null
  , iQty                in     number
  , iStmStockId         in     number
  , iStmLocationId      in     number
  , iCharacVal1         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal2         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal3         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal4         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal5         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCheckValues        in     integer
  , ioResultMessage     in out varchar2
  )
  is
    tplCharactElements TCharactElements;
    liRetouche         integer;
  begin
    ioResultMessage  := '';

    if iCheckValues = 1 then
      if nvl(iQty, 0) = 0 then
        ioResultMessage  := PCS.PC_PUBLIC.TranslateWord('La quantit� doit �tre sup�rieure � 0') || '[ABORT]';
      elsif nvl(iStmStockId, 0) = 0 then
        ioResultMessage  := PCS.PC_PUBLIC.TranslateWord('Identifiant du stock pas d�fini') || '[ABORT]';
      elsif nvl(iStmLocationId, 0) = 0 then
        ioResultMessage  := PCS.PC_PUBLIC.TranslateWord('Identifiant de la location de stockage pas d�fini') || '[ABORT]';
      else
        tplCharactElements  := GetCharactElements(iGcoGoodId);

        if     (tplCharactElements.PieceManagement = 1)
           and (nvl(iQty, 0) <> 1) then
          ioResultMessage  := PCS.PC_PUBLIC.TranslateWord('Caract�risation de type pi�ce : la quantit� doit �tre �gale � 1') || '[ABORT]';
        else
          if iCharacVal1 is not null then
            STM_I_LIB_CHARACTERIZATION.VerifyElement(iGoodId               => iGcoGoodId
                                                   , iCharacterizationId   => tplCharactElements.Charac1Id
                                                   , iMovementKindId       => tplCharactElements.MovementKindId
                                                   , iElementType          => tplCharactElements.CharacType1
                                                   , iElementValue         => iCharacVal1
                                                   , ioRetouche            => liRetouche
                                                   , ioResultMessage       => ioResultMessage
                                                    );
          end if;

          if     (trim(ioResultMessage) is null)
             and iCharacVal2 is not null then
            STM_I_LIB_CHARACTERIZATION.VerifyElement(iGoodId               => iGcoGoodId
                                                   , iCharacterizationId   => tplCharactElements.Charac2Id
                                                   , iMovementKindId       => tplCharactElements.MovementKindId
                                                   , iElementType          => tplCharactElements.CharacType2
                                                   , iElementValue         => iCharacVal2
                                                   , ioRetouche            => liRetouche
                                                   , ioResultMessage       => ioResultMessage
                                                    );
          end if;

          if     (trim(ioResultMessage) is null)
             and iCharacVal3 is not null then
            STM_I_LIB_CHARACTERIZATION.VerifyElement(iGoodId               => iGcoGoodId
                                                   , iCharacterizationId   => tplCharactElements.Charac3Id
                                                   , iMovementKindId       => tplCharactElements.MovementKindId
                                                   , iElementType          => tplCharactElements.CharacType3
                                                   , iElementValue         => iCharacVal3
                                                   , ioRetouche            => liRetouche
                                                   , ioResultMessage       => ioResultMessage
                                                    );
          end if;

          if     (trim(ioResultMessage) is null)
             and iCharacVal4 is not null then
            STM_I_LIB_CHARACTERIZATION.VerifyElement(iGoodId               => iGcoGoodId
                                                   , iCharacterizationId   => tplCharactElements.Charac4Id
                                                   , iMovementKindId       => tplCharactElements.MovementKindId
                                                   , iElementType          => tplCharactElements.CharacType4
                                                   , iElementValue         => iCharacVal4
                                                   , ioRetouche            => liRetouche
                                                   , ioResultMessage       => ioResultMessage
                                                    );
          end if;

          if     (trim(ioResultMessage) is null)
             and iCharacVal5 is not null then
            STM_I_LIB_CHARACTERIZATION.VerifyElement(iGoodId               => iGcoGoodId
                                                   , iCharacterizationId   => tplCharactElements.Charac5Id
                                                   , iMovementKindId       => tplCharactElements.MovementKindId
                                                   , iElementType          => tplCharactElements.CharacType5
                                                   , iElementValue         => iCharacVal5
                                                   , ioRetouche            => liRetouche
                                                   , ioResultMessage       => ioResultMessage
                                                    );
          end if;
        end if;
      end if;
    else
      tplCharactElements  := GetCharactElements(iGcoGoodId);
    end if;

    if trim(ioResultMessage) is null then
      insert into FAL_COMPONENT_LINK
                  (FAL_COMPONENT_LINK_ID
                 , FCL_SESSION
                 , FAL_LOT_MAT_LINK_TMP_ID
                 , FAL_LOT_ID
                 , GCO_GOOD_ID
                 , FCL_HOLD_QTY
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , GCO_CHARACTERIZATION1_ID
                 , GCO_CHARACTERIZATION2_ID
                 , GCO_CHARACTERIZATION3_ID
                 , GCO_CHARACTERIZATION4_ID
                 , GCO_CHARACTERIZATION5_ID
                 , FCL_CHARACTERIZATION_VALUE_1
                 , FCL_CHARACTERIZATION_VALUE_2
                 , FCL_CHARACTERIZATION_VALUE_3
                 , FCL_CHARACTERIZATION_VALUE_4
                 , FCL_CHARACTERIZATION_VALUE_5
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , FLML.LOM_SESSION
             , FLML.FAL_LOT_MAT_LINK_TMP_ID
             , FLML.FAL_LOT_ID
             , FLML.GCO_GOOD_ID
             , iQty
             , decode(iStmStockId, null, (select STM_STOCK_ID
                                            from STM_LOCATION
                                           where STM_LOCATION_ID = iStmLocationId), iStmStockId)
             , iStmLocationId
             , decode(tplCharactElements.Charac1Id, 0, null, tplCharactElements.Charac1Id)
             , decode(tplCharactElements.Charac2Id, 0, null, tplCharactElements.Charac2Id)
             , decode(tplCharactElements.Charac3Id, 0, null, tplCharactElements.Charac3Id)
             , decode(tplCharactElements.Charac4Id, 0, null, tplCharactElements.Charac4Id)
             , decode(tplCharactElements.Charac5Id, 0, null, tplCharactElements.Charac5Id)
             , iCharacVal1
             , iCharacVal2
             , iCharacVal3
             , iCharacVal4
             , iCharacVal5
             , sysdate
             , PCS.PC_INIT_SESSION.GetUserIni
          from FAL_LOT_MAT_LINK_TMP FLML
         where FLML.FAL_LOT_MAT_LINK_TMP_ID = iFalLotMatLinkTmpId;

      if iFalComponentLinkId is not null then
        delete from FAL_COMPONENT_LINK
              where FAL_COMPONENT_LINK_ID = iFalComponentLinkId;
      end if;
    end if;
  end;

  /**
  * fonction GetCharactValue
  * Description
  *   Recherche de la valeur de caract�risation d'un composant de lot
  * @created CLE
  * @lastUpdate
  * @public
  * @param   iCharacId     Id de la caract�risation
  * @param   iCharacStk    D�termine si la caract�risation est g�r�e sur stock
  * @param   iCharacType   Type de caract�risation
  * @param   iFalLotId     Id du lot
  * @param   iLotRefcompl  R�f�rence compl�te du lot
  * @param   iGcoGoodId    Id du composant
  */
  function GetCharactValue(
    iCharacId       in number
  , iCharacStk      in number
  , iCharacType     in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , iFalLotId       in number
  , iLotRefcompl    in FAL_LOT.LOT_REFCOMPL%type
  , iGcoGoodId      in number
  , iMovementKindId in number
  )
    return varchar2
  is
    vCharactValue   FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    liRetouche      integer;
    lvResultMessage varchar2(4000);
  begin
    if    (iCharacId is null)
       or (iCharacStk = 0) then
      return null;
    end if;

    -- Caract�risations avec possibilit� d'un incr�ment auto
    -- Version, Pi�ces et Lots
    if iCharacType in('1', '3', '4') then
      vCharactValue  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(iCharacId, null, iFalLotId);

      if     (vCharactValue is null)
         and (iCharacType = '4') then
        if cInitLotRefCompl then
          vCharactValue  := iLotRefcompl;
        elsif cInitLotRefCompl2 is not null then
          execute immediate 'begin ' || cInitLotRefCompl2 || '(:iGcoGoodId, :iFalLotId, :ioResult); end;'
                      using in iGcoGoodId, iFalLotId, out vCharactValue;
        end if;
      end if;
    -- Caract�risation de type Chrono
    elsif iCharacType = '5' then
      vCharactValue  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(iCharacId, sysdate);
    end if;

    -- V�rification que la valeur soit compatible avec les config d'unicit�
    if vCharactValue is not null then
      STM_I_LIB_CHARACTERIZATION.VerifyElement(iGoodId               => iGcoGoodId
                                             , iCharacterizationId   => iCharacId
                                             , iMovementKindId       => iMovementKindId
                                             , iElementType          => iCharacType
                                             , iElementValue         => vCharactValue
                                             , ioRetouche            => liRetouche
                                             , ioResultMessage       => lvResultMessage
                                              );

      if lvResultMessage is not null then
        return null;
      end if;
    end if;

    return vCharactValue;
  end;

  /**
  * proc�dure GenerateCompoLinkForDerived
  * Description
  *   Cr�e une r�servation entre un composant de lot type "d�riv�" et un emplacement de stock
  *   (Aucune r�servation de stock dans ce cas car pas de position de stock pr�cis�)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMatLinkTmpId    ID du composant temporaire de lot
  * @param   aStmLocationId         ID de l'emplacement de stock
  * @param   aQty                   Quantit� � r�serv�
  */
  procedure GenerateCompoLinkForDerived(
    aSessionId          in FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMatLinkTmpId in number
  , aStmLocationId      in number
  , aQty                in number
  )
  is
    cursor crCompoAndBatchInfo
    is
      select COMP.GCO_GOOD_ID
           , COMP.FAL_LOT_ID
           , (select LOT_REFCOMPL
                from FAL_LOT
               where FAL_LOT_ID = COMP.FAL_LOT_ID) LOT_REFCOMPL
           , (select GOO_NUMBER_OF_DECIMAL
                from GCO_GOOD
               where GCO_GOOD_ID = COMP.GCO_GOOD_ID) GOO_NUMBER_OF_DECIMAL
        from FAL_LOT_MAT_LINK_TMP COMP
       where FAL_LOT_MAT_LINK_TMP_ID = aFalLotMatLinkTmpId;

    tplCompoAndBatchInfo crCompoAndBatchInfo%rowtype;
    vStmLocationId       number;
    vDefaultNetworkStock number;
    nQty                 number;
    tplCharactElements   TCharactElements;
    CharacVal1           FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type;
    CharacVal2           FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type;
    CharacVal3           FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type;
    CharacVal4           FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type;
    CharacVal5           FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type;
    lvMessage            varchar2(32000);
  begin
    FAL_COMPONENT_LINK_FUNCTIONS.PurgeComponentLink(aFalLotMatLinkTmpId => aFalLotMatLinkTmpId, aSessionId => aSessionId);

    if nvl(aQty, 0) <= 0 then
      return;
    end if;

    if nvl(aStmLocationId, 0) = 0 then
      vDefaultNetworkStock  := FAL_TOOLS.GetConfig_StockID('GCO_DefltSTOCK');
      vStmLocationId        := FAL_TOOLS.GetMinusLocClaOnStock(vDefaultNetworkStock);
    else
      vStmLocationId  := aStmLocationId;
    end if;

    open crCompoAndBatchInfo;

    fetch crCompoAndBatchInfo
     into tplCompoAndBatchInfo;

    if crCompoAndBatchInfo%notfound then
      close crCompoAndBatchInfo;

      return;
    end if;

    close crCompoAndBatchInfo;

    tplCharactElements  := GetCharactElements(tplCompoAndBatchInfo.GCO_GOOD_ID);
    nQty                := round(aQty, tplCompoAndBatchInfo.GOO_NUMBER_OF_DECIMAL);

    /* Si on a une gestion de pi�ces on cr�e autant de d�tails que la quantit� totale */
    for i in 1 .. ceil(nQty) loop
      CharacVal1  :=
        GetCharactValue(tplCharactElements.Charac1Id
                      , tplCharactElements.CharacStk1
                      , tplCharactElements.CharacType1
                      , tplCompoAndBatchInfo.FAL_LOT_ID
                      , tplCompoAndBatchInfo.LOT_REFCOMPL
                      , tplCompoAndBatchInfo.GCO_GOOD_ID
                      , tplCharactElements.MovementKindId
                       );
      CharacVal2  :=
        GetCharactValue(tplCharactElements.Charac2Id
                      , tplCharactElements.CharacStk2
                      , tplCharactElements.CharacType2
                      , tplCompoAndBatchInfo.FAL_LOT_ID
                      , tplCompoAndBatchInfo.LOT_REFCOMPL
                      , tplCompoAndBatchInfo.GCO_GOOD_ID
                      , tplCharactElements.MovementKindId
                       );
      CharacVal3  :=
        GetCharactValue(tplCharactElements.Charac3Id
                      , tplCharactElements.CharacStk3
                      , tplCharactElements.CharacType3
                      , tplCompoAndBatchInfo.FAL_LOT_ID
                      , tplCompoAndBatchInfo.LOT_REFCOMPL
                      , tplCompoAndBatchInfo.GCO_GOOD_ID
                      , tplCharactElements.MovementKindId
                       );
      CharacVal4  :=
        GetCharactValue(tplCharactElements.Charac4Id
                      , tplCharactElements.CharacStk4
                      , tplCharactElements.CharacType4
                      , tplCompoAndBatchInfo.FAL_LOT_ID
                      , tplCompoAndBatchInfo.LOT_REFCOMPL
                      , tplCompoAndBatchInfo.GCO_GOOD_ID
                      , tplCharactElements.MovementKindId
                       );
      CharacVal5  :=
        GetCharactValue(tplCharactElements.Charac5Id
                      , tplCharactElements.CharacStk5
                      , tplCharactElements.CharacType5
                      , tplCompoAndBatchInfo.FAL_LOT_ID
                      , tplCompoAndBatchInfo.LOT_REFCOMPL
                      , tplCompoAndBatchInfo.GCO_GOOD_ID
                      , tplCharactElements.MovementKindId
                       );
      FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkForDerived(iFalLotMatLinkTmpId   => aFalLotMatLinkTmpId
                                                           , iGcoGoodId            => tplCompoAndBatchInfo.GCO_GOOD_ID
                                                           , iQty                  => case tplCharactElements.PieceManagement
                                                               when 1 then 1
                                                               else nQty
                                                             end
                                                           , iStmStockId           => null
                                                           , iStmLocationId        => vStmLocationId
                                                           , iCharacVal1           => CharacVal1
                                                           , iCharacVal2           => CharacVal2
                                                           , iCharacVal3           => CharacVal3
                                                           , iCharacVal4           => CharacVal4
                                                           , iCharacVal5           => CharacVal5
                                                           , iCheckValues          => 0
                                                           , ioResultMessage       => lvMessage
                                                            );

      if tplCharactElements.PieceManagement = 0 then
        exit;
      end if;
    end loop;
  end;

  /**
  * proc�dure CreateCompoLinkFromAttribution
  * Description
  *   Report (depuis les attributions) des r�servations de stock entre un composant de lot
  *   et les positions de stock dans la table de "dispo composant" (FAL_COMPONENT_LINK)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMaterialLinkId  ID du composant de lot
  * @param   aFalLotMatLinkTmpID    ID Du composant temporaire
  * @param   aHoldedQty             Quantit� r�ellement saisie
  * @param   aC_CHRONOLOGY_TYPE     Type de chronologie
  * @param   aIS_FULL_TRACABILITY   produit en tracabilit� compl�te
  * @param   aSTM_LOCATION_ID       Emplacement (pour une saisie manuelle)
  * @param   aHoldQty             Quantit� � saisir
  * @param   aForceWithStmLocation  Forcer l'emplaceent de saisie
  */
  procedure CreateCompoLinkFromAttribution(
    aSessionId            in     FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMaterialLinkId in     FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aFalLotMatLinkTmpID   in     FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type default null
  , aHoldedQty            in out number
  , aC_CHRONOLOGY_TYPE    in     varchar2
  , aIS_FULL_TRACABILITY  in     integer
  , aSTM_LOCATION_ID      in     number
  , aHoldQty              in     FAL_COMPONENT_LINK.FCL_HOLD_QTY%type
  , aTrashQty             in     FAL_COMPONENT_LINK.FCL_TRASH_QTY%type
  , aReturnQty            in     FAL_COMPONENT_LINK.FCL_RETURN_QTY%type
  , aForceWithStmLocation in     integer
  , aContext              in     number
  )
  is
    type TYPE_CURSOR is ref cursor;

    /*Curseur d�finissant la structure de la table de r�cption des attributions*/
    cursor cNetworklink
    is
      select LOM.FAL_LOT_MAT_LINK_TMP_ID
           , LOM.FAL_LOT_ID
           , LOM.GCO_GOOD_ID
           , LOM.LOM_NEED_QTY FLN_QTY
           , SPO.GCO_CHARACTERIZATION_ID
           , SPO.GCO_GCO_CHARACTERIZATION_ID
           , SPO.GCO2_GCO_CHARACTERIZATION_ID
           , SPO.GCO3_GCO_CHARACTERIZATION_ID
           , SPO.GCO4_GCO_CHARACTERIZATION_ID
           , SPO.SPO_CHARACTERIZATION_VALUE_1
           , SPO.SPO_CHARACTERIZATION_VALUE_2
           , SPO.SPO_CHARACTERIZATION_VALUE_3
           , SPO.SPO_CHARACTERIZATION_VALUE_4
           , SPO.SPO_CHARACTERIZATION_VALUE_5
           , SPO.STM_STOCK_ID
           , SPO.STM_LOCATION_ID
           , SPO.STM_STOCK_POSITION_ID
           , LOM.FAL_LOT_MAT_LINK_TMP_ID FAL_NETWORK_LINK_ID
           , 0 TIME_LIMIT_ORDER_BY
        from FAL_LOT_MAT_LINK_TMP LOM
           , STM_STOCK_POSITION SPO;

    /*Structure table de r�ception des enregistrements */
    type TNetworkLinks is table of cNetworklink%rowtype
      index by binary_integer;

    /*Variable de r�ception des positions du tableau */
    vNetworkLinks        TNetworkLinks;
    CUR_FAL_NETWORK_LINK varchar2(4000);
    CurFalNetworkLink    TYPE_CURSOR;
    StrInsertLinks       varchar2(4000);
    StrSelectLinks       varchar2(4000);
    StrLocationSelection varchar2(1000);
    aLinkHoldQty         number;
    aLinkTrashQty        number;
    aLinkReturnQty       number;
    nNeedId              number;
    nPositionid          number;
    nLocationId          number;
    nAttribTot           number;
    nAttribHoldQty       number;
    nAttribTrashQty      number;
    nAttribReturnQty     number;
    nQtyLeft             number;
    lStrDateRef          varchar2(100)  := 'to_date(trunc(sysdate),''DD.MM.YYYY'')';
  begin
    if nvl(aFalLotMaterialLinkId, 0) = 0 then
      raise_application_error(-20000, 'CreateCompoLinkFromAttribution - aFalLotMaterialLinkId must be defined !');
    end if;

    aHoldedQty            := 0;
    StrInsertLinks        :=
      'insert into FAL_COMPONENT_LINK ' ||
      '           (FAL_COMPONENT_LINK_ID ' ||
      '          , FCL_SESSION ' ||
      '          , FAL_LOT_MAT_LINK_TMP_ID ' ||
      '          , FAL_LOT_ID ' ||
      '          , GCO_GOOD_ID ' ||
      '          , FCL_HOLD_QTY ' ||
      '          , FCL_TRASH_QTY ' ||
      '          , FCL_RETURN_QTY ' ||
      '          , GCO_CHARACTERIZATION1_ID ' ||
      '          , GCO_CHARACTERIZATION2_ID ' ||
      '          , GCO_CHARACTERIZATION3_ID ' ||
      '          , GCO_CHARACTERIZATION4_ID ' ||
      '          , GCO_CHARACTERIZATION5_ID ' ||
      '          , FCL_CHARACTERIZATION_VALUE_1 ' ||
      '          , FCL_CHARACTERIZATION_VALUE_2 ' ||
      '          , FCL_CHARACTERIZATION_VALUE_3 ' ||
      '          , FCL_CHARACTERIZATION_VALUE_4 ' ||
      '          , FCL_CHARACTERIZATION_VALUE_5 ' ||
      '          , STM_STOCK_ID ' ||
      '          , STM_LOCATION_ID ' ||
      '          , STM_STOCK_POSITION_ID ' ||
      '          , FAL_FACTORY_IN_ID ' ||
      '          , FAL_NETWORK_LINK_ID ' ||
      '          , FCL_SELECTED ' ||
      '          , A_DATECRE ' ||
      '          , A_IDCRE ' ||
      '          ) ';
    -- Restriction sur les stocks et emplacements de saisie
    StrLocationSelection  := '';

    if aIS_FULL_TRACABILITY = 1 then
      StrLocationSelection  := '';
    elsif     nvl(aForceWithStmLocation, 0) = 0
          and cUseLocationSelectLaunch then
      -- Utilisation des positions de stocks de l'emplacement de stock du composant
      if cLocationSelectLaunch = 1 then
        StrLocationSelection  := ' AND SPO.STM_LOCATION_ID = ' || to_char(nvl(aSTM_LOCATION_ID, 0) );
      -- Utilisation des positions de stocks des emplacements de stock du stock du composant
      elsif cLocationSelectLaunch = 2 then
        StrLocationSelection  :=
          ' AND SPO.STM_STOCK_ID = (select MAX(STM_STOCK_ID) ' ||
          '                           from STM_LOCATION ' ||
          '                          where STM_LOCATION_ID = ' ||
          to_char(nvl(aSTM_LOCATION_ID, 0) ) ||
          ') ';
      -- utilisation des positions de stocks des emplacements de stock des stocks " public " g�r�s dans le calcul des besoins.
      elsif cLocationSelectLaunch = 3 then
        StrLocationSelection  :=
          ' AND SPO.STM_STOCK_ID IN (SELECT STM_STOCK_ID ' ||
          '                            FROM STM_STOCK ' ||
          '                           WHERE C_ACCESS_METHOD = ''PUBLIC'' ' ||
          '                             AND STO_NEED_CALCULATION = 1)';
      end if;
    elsif nvl(aSTM_LOCATION_ID, 0) <> 0 then
      StrLocationSelection  := 'AND SPO.STM_LOCATION_ID = ' || to_char(aSTM_LOCATION_ID);
    end if;

    -- Si Saisie de la quantit� totale attribu�e au composant (on prend toutes les attributions)
    if     nvl(aHoldQty, 0) = 0
       and nvl(aTrashQty, 0) = 0
       and nvl(aReturnQty, 0) = 0 then
      StrSelectLinks  :=
        '     select GetNewId ' ||
        '          , :aSessionId ' ||
        '          , FLMLT.FAL_LOT_MAT_LINK_TMP_ID ' ||
        '          , FNN.FAL_LOT_ID ' ||
        '          , FNN.GCO_GOOD_ID ' ||
        '          , FNL.FLN_QTY ' ||
        '          , 0 ' ||
        '          , 0 ' ||
        '          , SPO.GCO_CHARACTERIZATION_ID ' ||
        '          , SPO.GCO_GCO_CHARACTERIZATION_ID ' ||
        '          , SPO.GCO2_GCO_CHARACTERIZATION_ID ' ||
        '          , SPO.GCO3_GCO_CHARACTERIZATION_ID ' ||
        '          , SPO.GCO4_GCO_CHARACTERIZATION_ID ' ||
        '          , SPO.SPO_CHARACTERIZATION_VALUE_1 ' ||
        '          , SPO.SPO_CHARACTERIZATION_VALUE_2 ' ||
        '          , SPO.SPO_CHARACTERIZATION_VALUE_3 ' ||
        '          , SPO.SPO_CHARACTERIZATION_VALUE_4 ' ||
        '          , SPO.SPO_CHARACTERIZATION_VALUE_5 ' ||
        '          , SPO.STM_STOCK_ID ' ||
        '          , FNL.STM_LOCATION_ID ' ||
        '          , FNL.STM_STOCK_POSITION_ID ' ||
        '          , null ' ||   -- FAL_FACTORY_IN_ID
        '          , FNL.FAL_NETWORK_LINK_ID ' ||
        '          , 0 ' ||   -- FCL_SELECTED
        '          , sysdate ' ||
        '          , PCS.PC_INIT_SESSION.GetUserIni ' ||
        '       from FAL_NETWORK_LINK FNL ' ||
        '          , FAL_NETWORK_NEED FNN ' ||
        '          , STM_STOCK_POSITION SPO ' ||
        '          , STM_ELEMENT_NUMBER SEM ' ||
        '          , FAL_LOT_MAT_LINK_TMP FLMLT ' ||
        '      where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID ' ||
        '        and FNL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID ' ||
        '        and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID (+) ' ||
        '        and FLMLT.FAL_LOT_MATERIAL_LINK_ID = FNN.FAL_LOT_MATERIAL_LINK_ID ' ||
        '        and FLMLT.LOM_SESSION = :aSessionId ' ||
        '        and FNN.FAL_LOT_MATERIAL_LINK_ID = :aFalLotMaterialLinkId ' ||
        '        and FNL.STM_STOCK_POSITION_ID is not null ' ||

        -- V�rifie si le genre de mouvement sortie est autoris� pour la position de stock
        '      and STM_I_LIB_MOVEMENT.VerifyStockOutputCond(SPO.GCO_GOOD_ID ' ||
        '         , SPO.STM_STOCK_ID ' ||
        '         , SPO.STM_LOCATION_ID ' ||
        '         , SEM.GCO_QUALITY_STATUS_ID ' ||
        '         , SPO.SPO_CHRONOLOGICAL ' ||
        '         , SPO.SPO_PIECE ' ||
        '         , SPO.SPO_SET ' ||
        '         , SPO.SPO_VERSION ' ||
        '         , FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoStockOut ' ||
        '         , trunc(sysdate) ' ||
        '         , 0) is null ' ||

        -- V�rifie si le genre de mouvement entr�e atelier est autoris� pour la position de stock
        '      and STM_I_LIB_MOVEMENT.VerifyStockOutputCond(SPO.GCO_GOOD_ID ' ||
        '         , :WorkshopStockId ' ||
        '         , :WorkshopLocationId ' ||
        '         , SEM.GCO_QUALITY_STATUS_ID ' ||
        '         , SPO.SPO_CHRONOLOGICAL ' ||
        '         , SPO.SPO_PIECE ' ||
        '         , SPO.SPO_SET ' ||
        '         , SPO.SPO_VERSION ' ||
        '         , FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoWorkshopIn ' ||
        '         , trunc(sysdate) ' ||
        '         , 0) is null ' ||
        StrLocationSelection;

      execute immediate (StrInsertLinks || StrSelectLinks)
                  using aSessionId, aSessionId, aFalLotMaterialLinkId, cWorkshopStockId, cWorkshopLocationId;

      -- R�cup�ration quantit� saisie
      select nvl(sum(FCL_HOLD_QTY), 0)
        into aHoldedQty
        from FAL_COMPONENT_LINK
       where FAL_LOT_MAT_LINK_TMP_ID = aFalLotMatLinkTmpID;
    -- Si Quantit� � saisir pr�cis�e
    else
      CUR_FAL_NETWORK_LINK  :=
        ' select FLMLT.FAL_LOT_MAT_LINK_TMP_ID ' ||
        '      , FNN.FAL_LOT_ID ' ||
        '      , FNN.GCO_GOOD_ID ' ||
        '      , FNL.FLN_QTY ' ||
        '      , SPO.GCO_CHARACTERIZATION_ID ' ||
        '      , SPO.GCO_GCO_CHARACTERIZATION_ID ' ||
        '      , SPO.GCO2_GCO_CHARACTERIZATION_ID ' ||
        '      , SPO.GCO3_GCO_CHARACTERIZATION_ID ' ||
        '      , SPO.GCO4_GCO_CHARACTERIZATION_ID ' ||
        '      , SPO.SPO_CHARACTERIZATION_VALUE_1 ' ||
        '      , SPO.SPO_CHARACTERIZATION_VALUE_2 ' ||
        '      , SPO.SPO_CHARACTERIZATION_VALUE_3 ' ||
        '      , SPO.SPO_CHARACTERIZATION_VALUE_4 ' ||
        '      , SPO.SPO_CHARACTERIZATION_VALUE_5 ' ||
        '      , SPO.STM_STOCK_ID ' ||
        '      , FNL.STM_LOCATION_ID ' ||
        '      , FNL.STM_STOCK_POSITION_ID ' ||
        '      , FNL.FAL_NETWORK_LINK_ID ' ||

        /* Ordre de la p�remption (test de lStrChronoValue - sysdate)
           - 0 si la valeur de chrono est sup�rieure � la date de r�f�rence (non p�rim�e)
           - 1 si les dates sont �gales
           - 2 si la date de r�f�rence est sup�rieure (p�rim�) */
        '      , decode(sign(trunc(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO.SPO_CHRONOLOGICAL, GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(SPO.GCO_GOOD_ID) ) ) ' ||
        '          - nvl(GCO_I_LIB_CHARACTERIZATION.getLapsingMarge(SPO.GCO_GOOD_ID), 0) - trunc(sysdate) ), 1, 0, 0, 1, 2) TIME_LIMIT_ORDER_BY' ||
        '   from FAL_NETWORK_LINK FNL ' ||
        '      , FAL_NETWORK_NEED FNN ' ||
        '      , STM_STOCK_POSITION SPO  ' ||
        '      , STM_ELEMENT_NUMBER SEM ' ||
        '      , FAL_LOT_MAT_LINK_TMP FLMLT ' ||
        '  where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID ' ||
        '    and FNL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID ' ||
        '    and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID (+) ' ||
        '    and FLMLT.FAL_LOT_MATERIAL_LINK_ID = FNN.FAL_LOT_MATERIAL_LINK_ID ' ||
        '    and FLMLT.LOM_SESSION = :aSessionId ' ||
        '    and FNN.FAL_LOT_MATERIAL_LINK_ID = :aFalLotMaterialLinkId ' ||
        '    and FNL.STM_STOCK_POSITION_ID is not null ' ||

        -- V�rifie si le genre de mouvement sortie est autoris� pour la position de stock
        '      and STM_I_LIB_MOVEMENT.VerifyStockOutputCond(SPO.GCO_GOOD_ID ' ||
        '         , SPO.STM_STOCK_ID ' ||
        '         , SPO.STM_LOCATION_ID ' ||
        '         , SEM.GCO_QUALITY_STATUS_ID ' ||
        '         , SPO.SPO_CHRONOLOGICAL ' ||
        '         , SPO.SPO_PIECE ' ||
        '         , SPO.SPO_SET ' ||
        '         , SPO.SPO_VERSION ' ||
        '         , FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoStockOut ' ||
        '         , trunc(sysdate) ' ||
        '         , 0) is null ' ||

        -- V�rifie si le genre de mouvement entr�e atelier est autoris� pour la position de stock
        '      and STM_I_LIB_MOVEMENT.VerifyStockOutputCond(SPO.GCO_GOOD_ID ' ||
        '         , :WorkshopStockId ' ||
        '         , :WorkshopLocationId ' ||
        '         , SEM.GCO_QUALITY_STATUS_ID ' ||
        '         , SPO.SPO_CHRONOLOGICAL ' ||
        '         , SPO.SPO_PIECE ' ||
        '         , SPO.SPO_SET ' ||
        '         , SPO.SPO_VERSION ' ||
        '         , FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoWorkshopIn ' ||
        '         , trunc(sysdate) ' ||
        '         , 0) is null ' ||
        StrLocationSelection ||
        '  order by null ';

      -- Si chronologie FIFO
      if aC_CHRONOLOGY_TYPE = '1' then
        -- Tri par chrono ascendante
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_CHRONOLOGICAL ASC ';
      -- Chronologie de type LIFO
      elsif aC_CHRONOLOGY_TYPE = '2' then
        -- Tri par chrono descendante
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_CHRONOLOGICAL DESC ';
      -- Chronologie de type p�remption
      elsif aC_CHRONOLOGY_TYPE = '3' then
        -- Tri par chrono ascendante mais les p�rim�s en dernier
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', TIME_LIMIT_ORDER_BY || SPO.SPO_CHRONOLOGICAL ASC ';
      end if;

      -- Si chronologie FIFO ou p�remption
      -- Si tracabilit� compl�te
      if aIS_FULL_TRACABILITY = 1 then
        -- Tri par lot, version, pi�ce ASC
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_SET ASC ';
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_VERSION ASC ';
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_PIECE ASC ';
      else
        -- Tri par version, lot, pi�ce ASC
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_VERSION ASC ';
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_SET ASC ';
        CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ', SPO.SPO_PIECE ASC ';
      end if;

      -- et en dernier lieu par qt� dispo max
      CUR_FAL_NETWORK_LINK  := CUR_FAL_NETWORK_LINK || ' , SPO.SPO_AVAILABLE_QUANTITY DESC';

      execute immediate CUR_FAL_NETWORK_LINK
      bulk collect into vNetworkLinks
                  using aSessionId, aFalLotMaterialLinkId, cWorkshopStockId, cWorkshopLocationId;

      nAttribHoldQty        := 0;
      nAttribTrashQty       := 0;
      nAttribReturnQty      := 0;

      if vNetworkLinks.count > 0 then
        for i in vNetworkLinks.first .. vNetworkLinks.last loop
          -- Toute la quantit� � �t� saisie
          if     (nAttribHoldQty = aHoldQty)
             and (nAttribTrashQty = aTrashQty)
             and (nAttribReturnQty = aReturnQty) then
            exit;
          end if;

          -- Quantit� du lien
          aLinkHoldQty      := least(vNetworkLinks(i).FLN_QTY,(aHoldQty - nAttribHoldQty) );
          nQtyLeft          := vNetworkLinks(i).FLN_QTY - aLinkHoldQty;
          aLinkTrashQty     := least(nQtyLeft,(aTrashQty - nAttribTrashQty) );
          nQtyLeft          := vNetworkLinks(i).FLN_QTY - aLinkHoldQty - aLinkTrashQty;
          aLinkReturnQty    := least(nQtyLeft,(aReturnQty - nAttribReturnQty) );
          -- Cr�ation du lien sur attribution
          StrSelectLinks    :=
            ' Values(GetNewId ' ||
            '      , :aSessionId ' ||
            '      , :FAL_LOT_MAT_LINK_TMP_ID ' ||
            '      , :FAL_LOT_ID ' ||
            '      , :GCO_GOOD_ID ' ||
            '      , :aLinkHoldQty ' ||
            '      , :aLinkTrashQty ' ||
            '      , :aLinkReturnQty ' ||
            '      , :GCO_CHARACTERIZATION_ID ' ||
            '      , :GCO_GCO_CHARACTERIZATION_ID ' ||
            '      , :GCO2_GCO_CHARACTERIZATION_ID ' ||
            '      , :GCO3_GCO_CHARACTERIZATION_ID ' ||
            '      , :GCO4_GCO_CHARACTERIZATION_ID ' ||
            '      , :SPO_CHARACTERIZATION_VALUE_1 ' ||
            '      , :SPO_CHARACTERIZATION_VALUE_2 ' ||
            '      , :SPO_CHARACTERIZATION_VALUE_3 ' ||
            '      , :SPO_CHARACTERIZATION_VALUE_4 ' ||
            '      , :SPO_CHARACTERIZATION_VALUE_5 ' ||
            '      , :STM_STOCK_ID ' ||
            '      , :STM_LOCATION_ID ' ||
            '      , :STM_STOCK_POSITION_ID ' ||
            '      , null '   -- FAL_FACTORY_IN_ID
                           ||
            '      , :FAL_NETWORK_LINK_ID ' ||
            '      , 0 '   -- FCL_SELECTED
                        ||
            '      , sysdate ' ||
            '      , PCS.PC_INIT_SESSION.GetUserIni ' ||
            ' )';

          execute immediate (StrInsertLinks || StrSelectLinks)
                      using aSessionId
                          , vNetworkLinks(i).FAL_LOT_MAT_LINK_TMP_ID
                          , vNetworkLinks(i).FAL_LOT_ID
                          , vNetworkLinks(i).GCO_GOOD_ID
                          , aLinkHoldQty
                          , aLinkTrashQty
                          , aLinkReturnQty
                          , vNetworkLinks(i).GCO_CHARACTERIZATION_ID
                          , vNetworkLinks(i).GCO_GCO_CHARACTERIZATION_ID
                          , vNetworkLinks(i).GCO2_GCO_CHARACTERIZATION_ID
                          , vNetworkLinks(i).GCO3_GCO_CHARACTERIZATION_ID
                          , vNetworkLinks(i).GCO4_GCO_CHARACTERIZATION_ID
                          , vNetworkLinks(i).SPO_CHARACTERIZATION_VALUE_1
                          , vNetworkLinks(i).SPO_CHARACTERIZATION_VALUE_2
                          , vNetworkLinks(i).SPO_CHARACTERIZATION_VALUE_3
                          , vNetworkLinks(i).SPO_CHARACTERIZATION_VALUE_4
                          , vNetworkLinks(i).SPO_CHARACTERIZATION_VALUE_5
                          , vNetworkLinks(i).STM_STOCK_ID
                          , vNetworkLinks(i).STM_LOCATION_ID
                          , vNetworkLinks(i).STM_STOCK_POSITION_ID
                          , vNetworkLinks(i).FAL_NETWORK_LINK_ID;

          -- Compteur Quantit� saisie
          nAttribHoldQty    := nAttribHoldQty + aLinkHoldQty;
          nAttribTrashQty   := nAttribTrashQty + aLinkTrashQty;
          nAttribReturnQty  := nAttribReturnQty + aLinkReturnQty;
          aHoldedQty        := aHoldedQty +(aLinkHoldQty + aLinkTrashQty + aLinkReturnQty);
        end loop;
      end if;
    end if;
  end;

  /**
  * proc�dure CompoLinkModifyQuantity
  * Description
  *   Modifie une r�servation entre un composant de lot et une position de stock
  *     - Si la quantit� est � 0, supprime le lien de r�servation
  *     - Si le lien de r�servation n'existe pas, cr�ation de l'enregistrement
  *       (dans la table FAL_COMPONENT_LINK)
  *   (la r�servation sur le stock se fait par trigger sur la table FAL_COMPONENT_LINK)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalComponentLinkId    ID du lien de r�servation (table FAL_COMPONENT_LINK)
  * @param   aContext               Context
  * @param   aFalLotMatLinkTmpId    ID du composant de lot temporaire
  * @param   aStmStockPositionId    ID de la position de stock
  * @param   aFalFactoryInId        Entr�e atelier
  * @param   aHoldQty               Quantit� saisie
  * @param   aTrashQty              Quantit� d�chet (retour de composant)
  * @param   aReturnQty             Quantit� retour (retour de composant)
  */
  procedure CompoLinkModifyQuantity(
    aSessionId             FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalComponentLinkId    FAL_COMPONENT_LINK.FAL_COMPONENT_LINK_ID%type default null
  , aContext               integer
  , aFalLotMatLinkTmpId    FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type default null
  , aStmStockPositionId    STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type default null
  , aFalFactoryInId        FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type default null
  , aHoldQty               FAL_COMPONENT_LINK.FCL_HOLD_QTY%type default 0
  , aTrashQty              FAL_COMPONENT_LINK.FCL_TRASH_QTY%type default 0
  , aReturnQty             FAL_COMPONENT_LINK.FCL_RETURN_QTY%type default 0
  , iLocationId         in number default null
  , iTrashLocationId    in number default null
  )
  is
    lnTrashLocationId number
               := nvl(iTrashLocationId, FWK_I_LIB_ENTITY.getIdfromPk2('STM_LOCATION', 'LOC_DESCRIPTION', PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_TRASH') ) );
  begin
    if    nvl(aHoldQty, 0) > 0
       or nvl(aTrashQty, 0) > 0
       or nvl(aReturnQty, 0) > 0 then
      if nvl(aFalComponentLinkId, 0) <> 0 then
        update FAL_COMPONENT_LINK
           set FCL_HOLD_QTY = nvl(aHoldQty, 0)
             , FCL_TRASH_QTY = nvl(aTrashQty, 0)
             , FCL_RETURN_QTY = nvl(aReturnQty, 0)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_INIT_SESSION.GetUserIni
         where FAL_COMPONENT_LINK_ID = aFalComponentLinkId;
      else
        -- Retour de composants, remplacement de composants saisie
        -- de qt� en atelier -> Cr�ation d'un lien vers une entr�e en atelier
        if    aContext = ctxtComponentReturn
           or aContext = ctxtBatchBalance
           or aContext = ctxtComponentReplacingOut
           or aContext = ctxtBatchSplitting
           or aContext = ctxtBatchToStockAllocation
           or (    aContext = ctxtManufacturingReceipt
               and nvl(aStmStockPositionId, 0) = 0) then
          -- insertion du lien si quantit� retour � saisir
          if    nvl(aReturnQty, 0) <> 0
             or nvl(aHoldQty, 0) <> 0 then
            FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFalFactoryIn(aSessionId            => aSessionId
                                                                   , aFalLotMatLinkTmpId   => aFalLotMatLinkTmpId
                                                                   , aFalFactoryInId       => aFalFactoryInId
                                                                   , aReturnQty            => aReturnQty
                                                                   , aHoldQty              => aHoldQty
                                                                   , iLocationId           => iLocationId
                                                                    );
          end if;

          -- insertion du lien si quantit� d�chet � saisir
          if nvl(aTrashQty, 0) <> 0 then
            FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFalFactoryIn(aSessionId            => aSessionId
                                                                   , aFalLotMatLinkTmpId   => aFalLotMatLinkTmpId
                                                                   , aFalFactoryInId       => aFalFactoryInId
                                                                   , aTrashQty             => aTrashQty
                                                                   , iLocationId           => lnTrashLocationId
                                                                    );
          end if;
        else
          -- Autres contexte -> Cr�ation d'un lien vers une position de stock
          FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkStockAvalaible(aSessionId
                                                                   , aFalLotMatLinkTmpId
                                                                   , aStmStockPositionId
                                                                   , aHoldQty
                                                                   , aTrashQty
                                                                   , aReturnQty
                                                                   , aContext
                                                                    );
        end if;
      end if;
    else
      delete from FAL_COMPONENT_LINK
            where FAL_COMPONENT_LINK_ID = aFalComponentLinkId;
    end if;
  end;

  /**
  * proc�dure PurgeComponentLinkTable
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK dont la
  *   session Oracle n'est plus valide
  *   (La suppression remet � jour par trigger les r�servation de stock provisoires)
  * @created CLE
  * @lastUpdate
  * @public
  */
  procedure PurgeComponentLinkTable
  is
    cursor crOracleSession
    is
      select distinct FCL_SESSION
                 from FAL_COMPONENT_LINK;
  begin
    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.FCL_SESSION) = 0 then
        delete from FAL_COMPONENT_LINK
              where FCL_SESSION = tplOracleSession.FCL_SESSION;
      end if;
    end loop;
  end;

  /**
  * proc�dure PurgeComponentLink
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK pour un lot donn�
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFalLotId     Id du lot
  */
  procedure PurgeComponentLink(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    delete from FAL_COMPONENT_LINK
          where FAL_LOT_ID = aFalLotId;
  end;

  /**
  * proc�dure PurgeComponentLink
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK pour un composant donn�.
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFalLotMatLinkTmpId     Composant temporaire.
  */
  procedure PurgeComponentLink(aFalLotMatLinkTmpId number, aSessionId varchar2)
  is
  begin
    delete from FAL_COMPONENT_LINK
          where FAL_LOT_MAT_LINK_TMP_ID = aFalLotMatLinkTmpId
            and FCL_SESSION = aSessionId;
  end;

  /**
  * proc�dure PurgeLinkForAComponent
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK pour un
  *   composant temporaire donn�
  *   (La suppression remet � jour par trigger les r�servation de stock provisoires)
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_MAT_LINK_TMP_ID     ID Composant
  * @param   aContext                     contexte d'utilisation
  * @param   aSTM_LOCATION_ID             Emplacement de stock concern� par la suppression
  * @param   aDeleteAllCompoLink          En r�ception, si = 1, supprime tous les liens composants d'un composant temporaire (atelier et stock)
  */
  procedure PurgeLinkForAComponent(
    aFAL_LOT_MAT_LINK_TMP_ID FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , aContext                 integer default 0
  , aSTM_LOCATION_ID         number default null
  , aDeleteAllCompoLink      integer default 0
  )
  is
  begin
    -- Remplacement, saisie de qt� a remplacer
    if aContext = ctxtComponentReplacingOut then
      delete from FAL_COMPONENT_LINK
            where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID
              and FAL_FACTORY_IN_ID is not null;
    -- Remplacement de composants, saisie de composant de remplacement
    elsif aContext = ctxtComponentReplacingIn then
      delete from FAL_COMPONENT_LINK
            where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID
              and (   nvl(aSTM_LOCATION_ID, 0) = 0
                   or (    nvl(aSTM_LOCATION_ID, 0) <> 0
                       and STM_LOCATION_ID = aSTM_LOCATION_ID) )
              and FAL_FACTORY_IN_ID is null;
    elsif aContext = ctxtManufacturingReceipt then
      delete from FAL_COMPONENT_LINK
            where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID
              and (    (aDeleteAllCompoLink = 1)
                   or ( (    (    STM_LOCATION_ID = nvl(aSTM_LOCATION_ID, 0)
                              and FAL_FACTORY_IN_ID is null)
                         or (    nvl(aSTM_LOCATION_ID, 0) = 0
                             and FAL_FACTORY_IN_ID is not null)
                        )
                      )
                  );
    else
      delete from FAL_COMPONENT_LINK
            where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID
              and (   nvl(aSTM_LOCATION_ID, 0) = 0
                   or (     (nvl(aSTM_LOCATION_ID, 0) <> 0)
                       and (STM_LOCATION_ID = aSTM_LOCATION_ID) ) );
    end if;
  end;

  /**
  * proc�dure PurgeLinkForAComponentAT
  * Description
  *   Idem que PurgeLinkForAComponent en transaction autonome
  */
  procedure PurgeLinkForAComponentAT(
    iLotMatLinkTmpId    FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , iContext            integer
  , iLocationId         FAL_LOT_MAT_LINK_TMP.STM_LOCATION_ID%type
  , iDeleteAllCompoLink integer
  )
  is
    pragma autonomous_transaction;
  begin
    PurgeLinkForAComponent(iLotMatLinkTmpId, iContext, iLocationId, iDeleteAllCompoLink);
    commit;
  end;

  /**
  * proc�dure PurgeComponentLinkTable
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK pour une
  *   session Oracle donn�e en param�tre
  *   (La suppression remet � jour par trigger les r�servation de stock provisoires)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  */
  procedure PurgeComponentLinkTable(aSessionId FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
  begin
    delete from FAL_COMPONENT_LINK
          where FCL_SESSION = aSessionId;
  end;

  /**
  * procedure : updateComponentLinkMissing
  * Description : Mise � jour de l'alerte
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_MAT_LINK_TMP_ID : ID Du composant � traiter
  */
  procedure updateComponentLinkMissing(aFAL_LOT_MAT_LINK_TMP_ID FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type)
  is
  begin
    update FAL_LOT_MAT_LINK_TMP
       set LOM_MISSING = 1
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_INIT_SESSION.GetUserIni
     where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID;
  end;

  /**
  * procedure : updateComponentLinkMissingAT
  * Description : Mise � jour de l'alerte
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   iLotMatLinkTmpId : Id du composant � traiter
  */
  procedure updateComponentLinkMissingAT(iLotMatLinkTmpId FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type)
  is
    pragma autonomous_transaction;
  begin
    updateComponentLinkMissing(iLotMatLinkTmpId);
    commit;
  end;

  /**
  * procedure : CompoLinkGenFactoryInOnSplit
  * Description : Cr�ation des liens composants entre les composants temporaires
  *               et les sorties atelier dans le cas d'un �clatement de lot.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aOriginBatchID : Lot origine
  * @param   aSession : Session oracle
  * @param   aFAL_LOT_MAT_LINK_TMP_ID : Composants concern�
  * @param   aUpdatedQtyToHold : Qt� � saisir
  * @param   aAutoSelectAllCompo : D�termine si on s�lectionne automatiquement tous les composants � l'�clatement (m�me les caract�ris�s)
  *
  */
  procedure CompoLinkGenFactoryInOnSplit(
    aOriginBatchID           number
  , aSession                 varchar2
  , aFAL_LOT_MAT_LINK_TMP_ID number
  , aUpdatedQtyToHold        number
  , aAutoSelectAllCompo      integer
  )
  is
    cursor Cur_Fal_Factory_In
    is
      select   FIN.IN_BALANCE
             , FIN.FAL_FACTORY_IN_ID
             , LOM.FAL_LOT_MAT_LINK_TMP_ID
             , LOM.LOM_SEQ
             , LOM.LOM_FULL_REQ_QTY
             , LOM.GCO_GOOD_ID
             , (select count(*)
                  from FAL_FACTORY_IN
                 where FAL_LOT_MATERIAL_LINK_ID = FIN.FAL_LOT_MATERIAL_LINK_ID
                   and IN_BALANCE > 0
                   and (   nvl(GCO_CHARACTERIZATION_ID, 0) <> nvl(FIN.GCO_CHARACTERIZATION_ID, 0)
                        or nvl(GCO_GCO_CHARACTERIZATION_ID, 0) <> nvl(FIN.GCO_GCO_CHARACTERIZATION_ID, 0)
                        or nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) <> nvl(FIN.GCO2_GCO_CHARACTERIZATION_ID, 0)
                        or nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) <> nvl(FIN.GCO3_GCO_CHARACTERIZATION_ID, 0)
                        or nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) <> nvl(FIN.GCO4_GCO_CHARACTERIZATION_ID, 0)
                        or nvl(IN_CHARACTERIZATION_VALUE_1, 0) <> nvl(FIN.IN_CHARACTERIZATION_VALUE_1, 0)
                        or nvl(IN_CHARACTERIZATION_VALUE_2, 0) <> nvl(FIN.IN_CHARACTERIZATION_VALUE_2, 0)
                        or nvl(IN_CHARACTERIZATION_VALUE_3, 0) <> nvl(FIN.IN_CHARACTERIZATION_VALUE_3, 0)
                        or nvl(IN_CHARACTERIZATION_VALUE_4, 0) <> nvl(FIN.IN_CHARACTERIZATION_VALUE_4, 0)
                        or nvl(IN_CHARACTERIZATION_VALUE_5, 0) <> nvl(FIN.IN_CHARACTERIZATION_VALUE_5, 0)
                       ) ) NB_FACT_IN
          from FAL_FACTORY_IN FIN
             , FAL_LOT_MAT_LINK_TMP LOM
         where (   nvl(aOriginBatchID, 0) = 0
                or LOM.FAL_LOT_ID = aOriginBatchID)
           and (   nvl(aFAL_LOT_MAT_LINK_TMP_ID, 0) = 0
                or LOM.FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID)
           and (   nvl(aFAL_LOT_MAT_LINK_TMP_ID, 0) <> 0
                or nvl(aOriginBatchID, 0) <> 0)
           and LOM.LOM_SESSION = aSession
           and LOM.FAL_LOT_MATERIAL_LINK_ID = FIN.FAL_LOT_MATERIAL_LINK_ID
           and FIN.IN_BALANCE > 0
           and LOM.C_TYPE_COM = '1'
           and LOM.C_KIND_COM in('1', '4', '5')
           and LOM.LOM_STOCK_MANAGEMENT = 1
      order by LOM.LOM_SEQ
             , FIN.IN_CHRONOLOGY
             , FIN.IN_VERSION
             , FIN.IN_LOT
             , FIN.IN_PIECE;

    CurFalFactoryIn Cur_Fal_Factory_In%rowtype;
    aFCL_HOLD_QTY   number;
    aQtyToSwitch    number;
    aCurrentLOM_SEQ number;
  begin
    aCurrentLOM_SEQ  := 0;

    -- Parcours des entr�es ateliers des composants
    for CurFalFactoryIn in Cur_Fal_Factory_In loop
      -- Initialisation de la quantit� � saisir
      aFCL_HOLD_QTY    := 0;

      if    (aCurrentLOM_SEQ = 0)
         or (    aCurrentLOM_SEQ <> 0
             and CurFalFactoryIn.LOM_SEQ <> aCurrentLOM_SEQ) then
        -- Si Saisie manuelle depuis l'interface (Pour un composants donn�)
        -- Utilisation de la quantit� pass�e en param�tres
        if nvl(aFAL_LOT_MAT_LINK_TMP_ID, 0) <> 0 then
          aQtyToSwitch  := nvl(aUpdatedQtyToHold, 0);
        else
          aQtyToSwitch  := CurFalFactoryIn.LOM_FULL_REQ_QTY;
        end if;
      end if;

      /* - Composant non caract�ris�
         - ou saisie manuelle
         - ou composant caract�ris�
           Dans ce cas on n'initialise la quantit� que s'il n'existe qu'une entr�e atelier pour le composant
           � moins que toutes les entr�es atelier soient de m�me caract�risation (ex : toute du m�me lot) */
      if    aAutoSelectAllCompo = 1
         or FAL_TOOLS.GoodHasCaracterization(CurFalFactoryIn.GCO_GOOD_ID) = 0
         or nvl(aFAL_LOT_MAT_LINK_TMP_ID, 0) <> 0
         or CurFalFactoryIn.NB_FACT_IN = 0 then
        aFCL_HOLD_QTY  := least(aQtyToSwitch, CurFalFactoryIn.IN_BALANCE);
      end if;

      -- G�n�ration du lien, si une qt� est � saisir
      if aFCL_HOLD_QTY > 0 then
        FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFalFactoryIn(aSessionId            => aSession
                                                               , aFalLotMatLinkTmpId   => CurFalFactoryIn.FAL_LOT_MAT_LINK_TMP_ID
                                                               , aFalFactoryInId       => CurFalFactoryIn.FAL_FACTORY_IN_ID
                                                               , aHoldQty              => aFCL_HOLD_QTY
                                                                );
        aQtyToSwitch  := aQtyToSwitch - aFCL_HOLD_QTY;
      end if;

      -- Sauvegarde du dernier composant trait�
      aCurrentLOM_SEQ  := CurFalFactoryIn.LOM_SEQ;
    end loop;
  end CompoLinkGenFactoryInOnSplit;

  /**
  * procedure : CompoLinkGenFactoryInOnReceipt
  * Description : Cr�ation des liens composants entre les composants temporaires et les sorties atelier
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param        iLotMatLinkTmpId          : ID du composant temporaire
  * @param        iFalLotId                 : ID du lot � traiter
  * @param        iSessionId                : ID unique de Session Oracle
  * @out          ioUpdatedQtyToHold        : Qt� � saisir (sort avec la quantit� restante � saisir)
  */
  procedure CompoLinkGenFactoryInOnReceipt(
    iLotMatLinkTmpId   in     FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , iFalLotId          in     FAL_LOT.FAL_LOT_ID%type
  , iSessionId         in     FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type
  , ioUpdatedQtyToHold in out number
  )
  is
    cursor crComponent
    is
      select LOM.FAL_LOT_MATERIAL_LINK_ID
           , LOM.FAL_LOT_MAT_LINK_TMP_ID
           , LOM.LOM_FULL_REQ_QTY
           , LOM.C_KIND_COM
           , LOM.STM_LOCATION_ID
           , (select max(CHA_STOCK_MANAGEMENT)
                from GCO_CHARACTERIZATION
               where GCO_GOOD_ID = LOM.GCO_GOOD_ID
                 and instr(cPairingCaract, C_CHARACT_TYPE) > 0) CHA_STOCK_COMPONENT
           , LOT.CHA_STOCK_FINISHED_PDT
           , LOT.C_FAB_TYPE
        from FAL_LOT_MAT_LINK_TMP LOM
           , (select C_FAB_TYPE
                   , (select CHA_STOCK_MANAGEMENT
                        from GCO_CHARACTERIZATION
                       where GCO_GOOD_ID = FL.GCO_GOOD_ID
                         and C_CHARACT_TYPE = '3') CHA_STOCK_FINISHED_PDT
                from FAL_LOT FL
               where FAL_LOT_ID = nvl(iFalLotId, (select FAL_LOT_ID
                                                    from FAL_LOT_MAT_LINK_TMP
                                                   where FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId) ) ) LOT
       where (   nvl(iFalLotId, 0) = 0
              or LOM.FAL_LOT_ID = iFalLotId)
         and (       nvl(iLotMatLinkTmpId, 0) = 0
                 and ( (select count(*)
                          from GCO_CHARACTERIZATION
                         where GCO_GOOD_ID = LOM.GCO_GOOD_ID
                           and instr(cAutoInitCharCpt, C_CHARACT_TYPE) > 0) = 0)
              or LOM.FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId
             )
         and LOM.LOM_SESSION = iSessionId
         and C_KIND_COM in('1', '2');

    cursor crFalFactoryIn(iMaterialLinkId FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type)
    is
      select   FIN.FAL_FACTORY_IN_ID
             , FIN.IN_BALANCE
          from FAL_FACTORY_IN FIN
             , STM_ELEMENT_NUMBER ELE
         where FIN.FAL_LOT_MATERIAL_LINK_ID = iMaterialLinkId
           and FIN.IN_BALANCE > 0
           and STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(FIN.GCO_GOOD_ID, FIN.IN_PIECE, FIN.IN_LOT, FIN.IN_VERSION) = ELE.STM_ELEMENT_NUMBER_ID(+)
           and STM_I_LIB_MOVEMENT.VerifyStockOutputCond(FIN.GCO_GOOD_ID
                                                      , cWorkshopStockId
                                                      , cWorkshopLocationId
                                                      , ELE.GCO_QUALITY_STATUS_ID
                                                      , FIN.IN_CHRONOLOGY
                                                      , FIN.IN_PIECE
                                                      , FIN.IN_LOT
                                                      , FIN.IN_VERSION
                                                      , FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindConsumedComp
                                                      , trunc(sysdate)
                                                      , 0
                                                       ) is null
      order by IN_CHRONOLOGY
             , IN_VERSION
             , IN_LOT
             , IN_PIECE;
  begin
    for tplComponent in crComponent loop
      -- Si on est sur un composant temporaire bien pr�cis, on effectue une modification depuis l'interface avec une quantit� pass�e en param�tre
      if nvl(iLotMatLinkTmpId, 0) = 0 then
        ioUpdatedQtyToHold  := tplComponent.LOM_FULL_REQ_QTY;
      else
        ioUpdatedQtyToHold  := ioUpdatedQtyToHold;
      end if;

      -- En r�ception, pour les d�riv�s on fait directement le lien avec la quantit� saisie
      -- (il s'agit d'une entr�e en stock, il n'y a pas de r�servation)
      if (tplComponent.C_KIND_COM = '2') then
        GenerateCompoLinkForDerived(aSessionId            => iSessionId
                                  , aFalLotMatLinkTmpId   => tplComponent.FAL_LOT_MAT_LINK_TMP_ID
                                  , aStmLocationId        => tplComponent.STM_LOCATION_ID
                                  , aQty                  => ioUpdatedQtyToHold
                                   );
        ioUpdatedQtyToHold  := 0;
      end if;

      -- Si le produit termin� est charact�ris� "pi�ce", les composants de type "pi�ce"et ceux d�finis par la config FAL_PAIRING_CHARACT ne sont pas g�r�s ici mais lors de l'appairage
      -- (except� pour un OF de type SAV)
      if     (tplComponent.C_KIND_COM = '1')
         and (   nvl(tplComponent.C_FAB_TYPE, '0') = '3'
              or nvl(tplComponent.CHA_STOCK_COMPONENT, 0) = 0
              or nvl(tplComponent.CHA_STOCK_FINISHED_PDT, 0) = 0) then
        for tplFalFactoryIn in crFalFactoryIn(tplComponent.FAL_LOT_MATERIAL_LINK_ID) loop
          exit when ioUpdatedQtyToHold <= 0;
          FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFalFactoryIn(aSessionId            => iSessionId
                                                                 , aFalLotMatLinkTmpId   => tplComponent.FAL_LOT_MAT_LINK_TMP_ID
                                                                 , aFalFactoryInId       => tplFalFactoryIn.FAL_FACTORY_IN_ID
                                                                 , aHoldQty              => least(tplFalFactoryIn.IN_BALANCE, ioUpdatedQtyToHold)
                                                                  );
          ioUpdatedQtyToHold  := ioUpdatedQtyToHold - least(tplFalFactoryIn.IN_BALANCE, ioUpdatedQtyToHold);
        end loop;
      end if;
    end loop;
  end;

  function GetLocationId(aCptLocationId number, aManualLocationId number, ForceLocation in out integer)
    return number
  is
    vLocationId number;
  begin
    ForceLocation  := 0;
    vLocationId    := null;

    -- Si Saisie manuelle des quantit�s, l'emplacement de saisie est celui pr�cis� en param�tres.
    if nvl(aManualLocationId, 0) <> 0 then
      ForceLocation  := 1;
      vLocationId    := aManualLocationId;
    -- Sinon si configuration Utilisation de l'emplacement du composants
    elsif    not cUseLocationSelectLaunch
          or (    cUseLocationSelectLaunch
              and (cLocationSelectLaunch = 1) ) then
      ForceLocation  := 1;
      vLocationId    := aCptLocationId;
    -- Sinon si configuration utilisation
    elsif     cUseLocationSelectLaunch
          and (   cLocationSelectLaunch = 2
               or cLocationSelectLaunch = 3) then
      ForceLocation  := 0;
      vLocationId    := aCptLocationId;
    end if;

    return vLocationId;
  end;

  /**
  * procedure : GetSubcontractLocationId
  * Description : Retourne l'emplacement de stock du sous-traitant li� � l'op�ration si l'OF est
  *               de type sous-traitance (C_FAB_TYPE = '4'), retourne null sinon.
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   iFalLotId : ID du lot
  */
  function GetSubcontractLocationId(iFalLotId in number, iFalLotMatLinkTmpId number)
    return number
  is
    vCFabType FAL_LOT.C_FAB_TYPE%type;
    nFalLotId number;
  begin
    if iFalLotId is null then
      begin
        select FAL_LOT_ID
          into nFalLotId
          from FAL_LOT_MAT_LINK_TMP
         where FAL_LOT_MAT_LINK_TMP_ID = iFalLotMatLinkTmpId;
      exception
        when no_data_found then
          return null;
      end;
    else
      nFalLotId  := iFalLotId;
    end if;

    begin
      select nvl(C_FAB_TYPE, '0') C_FAB_TYPE
        into vCFabType
        from FAL_LOT
       where FAL_LOT_ID = nFalLotId;
    exception
      when no_data_found then
        return null;
    end;

    if vCFabType = '4' then
      return FAL_TOOLS.GetSubcontractLocationId(nFalLotId);
    else
      return null;
    end if;
  end;

  /**
  * procedure : GenerateLinkForReturn
  * Description : G�n�ration des liens composants pour les mouvements de type retour
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param
  */
  procedure GenerateLinkForReturn(
    iSession            in varchar2
  , iLotMatLinkTmpId    in number
  , iLotId              in number
  , iTrashQty           in number
  , iReturnQty          in number
  , iStmLocationId      in number
  , iTrashLocationId    in number
  , iReturnCompoIsScrap in integer
  , iSelectAllFactoryIn in boolean
  )
  is
    -- Curseur de parcours des composants temporaires pour les mouvements de retour en stock de composants
    cursor crFalLomLinkTmpReturn
    is
      select LOM.GCO_GOOD_ID
           , LOM.LOM_UTIL_COEF
           , nvl(LOM.LOM_REF_QTY, 1) LOM_REF_QTY
           , LOM.FAL_LOT_MATERIAL_LINK_ID
           , FAL_LOT_MAT_LINK_TMP_ID
           , LOM_SESSION
        from FAL_LOT_MAT_LINK_TMP LOM
       where (    nvl(iLotMatLinkTmpId, 0) <> 0
              and LOM.FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId)
          or (    nvl(iLotMatLinkTmpId, 0) = 0
              and LOM.FAL_LOT_ID = iLotId
              and LOM.LOM_SESSION = iSession);

    -- Curseur de parcours des entr�es atelier pour les mouvements de retour de composants vers les stocks
    cursor crFalFactoryIn(iMaterialLinkId number)
    is
      select   FIN.FAL_FACTORY_IN_ID
             , nvl(FIN.IN_BALANCE, 0) IN_BALANCE
             , FIN.GCO_GOOD_ID
             , FIN.IN_CHRONOLOGY
             , FIN.IN_VERSION
             , FIN.IN_LOT
             , FIN.IN_PIECE
             , nvl(iStmLocationId, FIN.STM_LOCATION_ID) STM_LOCATION_ID
             , ELE.GCO_QUALITY_STATUS_ID
          from FAL_FACTORY_IN FIN
             , STM_ELEMENT_NUMBER ELE
         where FIN.FAL_LOT_MATERIAL_LINK_ID = iMaterialLinkId
           and FIN.IN_BALANCE > 0
           and STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(FIN.GCO_GOOD_ID, FIN.IN_PIECE, FIN.IN_LOT, FIN.IN_VERSION) = ELE.STM_ELEMENT_NUMBER_ID(+)
      order by FIN.IN_CHRONOLOGY
             , FIN.IN_VERSION
             , FIN.IN_LOT
             , FIN.IN_PIECE;

    lnTrashQty        number;
    lnReturnQty       number;
    lnTrashQtyToHold  number;
    lnReturnQtyToHold number;
    lvMsg             varchar2(2000);
    lnTrashLocationId number
                := nvl(iTrashLocationId, FWK_I_LIB_ENTITY.getIdfromPk2('STM_LOCATION', 'LOC_DESCRIPTION', PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_TRASH') ) );
  begin
    -- Parcours des composants � traiter
    for tplFalLomLinkTmpReturn in crFalLomLinkTmpReturn loop
      -- Calcul des quantit�s, si pour un composant, alors les quantit�s sont celles du composant,
      -- si pour un lot, alors ce sont celles du lot, et doivent �tre recalcul�es au niveau du composant
      if     nvl(iLotId, 0) = 0
         and nvl(iLotMatLinkTmpId, 0) <> 0 then
        -- Modification de la quantit� par l'utilisateur
        -- Calcul qt� d�chet du composants
        lnTrashQty   := FAL_TOOLS.ArrondiInferieur(nvl(iTrashQty, 0), tplFalLomLinkTmpReturn.GCO_GOOD_ID);
        -- Calcul Qt� retour du composant
        lnReturnQty  := FAL_TOOLS.ArrondiInferieur(nvl(iReturnQty, 0), tplFalLomLinkTmpReturn.GCO_GOOD_ID);
      else
        -- Calcul qt� d�chet du composants
        lnTrashQty   :=
          nvl(FAL_TOOLS.ArrondiInferieur( (nvl(iTrashQty, 0) * tplFalLomLinkTmpReturn.LOM_UTIL_COEF) / tplFalLomLinkTmpReturn.LOM_REF_QTY
                                       , tplFalLomLinkTmpReturn.GCO_GOOD_ID
                                        )
            , 0
             );
        -- Calcul Qt� retour du composant
        lnReturnQty  :=
          nvl(FAL_TOOLS.ArrondiInferieur( (nvl(iReturnQty, 0) * tplFalLomLinkTmpReturn.LOM_UTIL_COEF) / tplFalLomLinkTmpReturn.LOM_REF_QTY
                                       , tplFalLomLinkTmpReturn.GCO_GOOD_ID
                                        )
            , 0
             );
      end if;

      -- Parcours des entr�es atelier pour ce composant
      for tplFalFactoryIn in crFalFactoryIn(tplFalLomLinkTmpReturn.FAL_LOT_MATERIAL_LINK_ID) loop
        -- Calcul des quantit�s � saisir sur l'entr�e atelier pour la sortie de l'atelier
        if iSelectAllFactoryIn then
          if iReturnCompoIsScrap = 1 then
            lnReturnQtyToHold  := 0;
            lnTrashQtyToHold   := tplFalFactoryIn.IN_BALANCE;
          else
            lnReturnQtyToHold  := tplFalFactoryIn.IN_BALANCE;
            lnTrashQtyToHold   := 0;
          end if;
        else
          exit when nvl(lntrashQty, 0) <= 0
               and nvl(lnReturnQty, 0) <= 0;
          lnTrashQtyToHold   := least(tplFalFactoryIn.IN_BALANCE, lnTrashQty);
          lnReturnQtyToHold  := least(tplFalFactoryIn.IN_BALANCE - lnTrashQtyToHold, lnReturnQty);
        end if;

        -- Test si le type de mouvement retour de composant en stock est autoris�. Si non, on met les quantit�s � 0.
        if nvl(lnReturnQtyToHold, 0) <> 0 then
          lvMsg  :=
            STM_I_LIB_MOVEMENT.VerifyStockOutputCond(iGoodId            => tplFalFactoryIn.GCO_GOOD_ID
                                                   , iStockId           => FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_LOCATION'
                                                                                                               , 'STM_STOCK_ID'
                                                                                                               , tplFalFactoryIn.STM_LOCATION_ID
                                                                                                                )
                                                   , iLocationId        => tplFalFactoryIn.STM_LOCATION_ID
                                                   , iQualityStatusId   => tplFalFactoryIn.GCO_QUALITY_STATUS_ID
                                                   , iChronological     => tplFalFactoryIn.IN_CHRONOLOGY
                                                   , iPiece             => tplFalFactoryIn.IN_PIECE
                                                   , iSet               => tplFalFactoryIn.IN_LOT
                                                   , iVersion           => tplFalFactoryIn.IN_VERSION
                                                   , iMovementKindId    => FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindStockReturn
                                                   , iCheckAll          => 0
                                                    );

          if lvMsg is not null then
            lnReturnQtyToHold  := 0;
          end if;
        end if;

        -- Test si le type de mouvement retour de composant en d�chet est autoris�. Si non, on met la quantit� � 0.
        if nvl(lnTrashQtyToHold, 0) <> 0 then
          lvMsg  :=
            STM_I_LIB_MOVEMENT.VerifyStockOutputCond(iGoodId            => tplFalFactoryIn.GCO_GOOD_ID
                                                   , iStockId           => FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_LOCATION'
                                                                                                               , 'STM_STOCK_ID'
                                                                                                               , lnTrashLocationId
                                                                                                                )
                                                   , iLocationId        => lnTrashLocationId
                                                   , iQualityStatusId   => tplFalFactoryIn.GCO_QUALITY_STATUS_ID
                                                   , iChronological     => tplFalFactoryIn.IN_CHRONOLOGY
                                                   , iPiece             => tplFalFactoryIn.IN_PIECE
                                                   , iSet               => tplFalFactoryIn.IN_LOT
                                                   , iVersion           => tplFalFactoryIn.IN_VERSION
                                                   , iMovementKindId    => FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindReturnInTrash
                                                   , iCheckAll          => 0
                                                    );

          if lvMsg is not null then
            lnTrashQtyToHold  := 0;
          end if;
        end if;

        -- insertion du lien si quantit� retour � saisir
        if nvl(lnReturnQtyToHold, 0) <> 0 then
          FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFalFactoryIn(aSessionId            => tplFalLomLinkTmpReturn.LOM_SESSION
                                                                 , aFalLotMatLinkTmpId   => tplFalLomLinkTmpReturn.FAL_LOT_MAT_LINK_TMP_ID
                                                                 , aFalFactoryInId       => tplFalFactoryIn.FAL_FACTORY_IN_ID
                                                                 , aReturnQty            => lnReturnQtyToHold
                                                                 , iLocationId           => tplFalFactoryIn.STM_LOCATION_ID
                                                                  );
          lnReturnQty  := lnReturnQty - lnReturnQtyToHold;
        end if;

        -- insertion du lien si quantit� d�chet � saisir
        if nvl(lnTrashQtyToHold, 0) <> 0 then
          FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFalFactoryIn(aSessionId            => tplFalLomLinkTmpReturn.LOM_SESSION
                                                                 , aFalLotMatLinkTmpId   => tplFalLomLinkTmpReturn.FAL_LOT_MAT_LINK_TMP_ID
                                                                 , aFalFactoryInId       => tplFalFactoryIn.FAL_FACTORY_IN_ID
                                                                 , aTrashQty             => lnTrashQtyToHold
                                                                 , iLocationId           => lnTrashLocationId
                                                                  );
          lnTrashQty  := lnTrashQty - lnTrashQtyToHold;
        end if;
      end loop;
    end loop;
  end GenerateLinkForReturn;

  /**
  * procedure : GenLinkForSubcontractReturn
  * Description : G�n�ration des liens composants pour les mouvements de type retour de sous-traitance
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param
  */
  procedure GenLinkForSubcontractReturn(
    iSession               varchar2
  , iContext               integer
  , iCallMode              integer
  , iLotMatLinkTmpId       number
  , iDocDocumentId         number
  , iLotId                 number
  , iUpdatedQtyToHold      number
  , iTrashQty              number
  , iReturnQty             number
  , iSubcontractLocationId number
  )
  is
    type TTabSTM_STOCK_POSITION is table of STM_PRC_STOCK_POSITION.gcurSPO%rowtype;

    -- Curseur de parcours des composants temporaires pour les mouvements de retour en stock de composants
    cursor crFalLomLinkTmpReturn
    is
      select LOM.GCO_GOOD_ID
           , LOM.LOM_UTIL_COEF
           , nvl(LOM.LOM_REF_QTY, 1) LOM_REF_QTY
           , LOM.FAL_LOT_MATERIAL_LINK_ID
           , FAL_LOT_MAT_LINK_TMP_ID
           , TAL.PAC_SUPPLIER_PARTNER_ID
           , LOM_SESSION
           , nvl(LOM.C_CHRONOLOGY_TYPE, '0') C_CHRONOLOGY_TYPE
           , FAL_TOOLS.PrcIsFullTracability(LOM.GCO_GOOD_ID) IS_FULL_TRACABILITY
        from FAL_LOT_MAT_LINK_TMP LOM
           , GCO_PRODUCT PDT
           , FAL_LOT_MATERIAL_LINK MAT
           , FAL_TASK_LINK TAL
       where PDT.PDT_STOCK_MANAGEMENT = 1
         and LOM.GCO_GOOD_ID = PDT.GCO_GOOD_ID
         and LOM.FAL_LOT_MATERIAL_LINK_ID = MAT.FAL_LOT_MATERIAL_LINK_ID
         and MAT.FAL_LOT_ID = TAL.FAL_LOT_ID(+)
         and MAT.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+)
         and (    (    nvl(iLotMatLinkTmpId, 0) <> 0
                   and LOM.FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId)
              or (    nvl(iLotMatLinkTmpId, 0) = 0
                  and (   LOM.FAL_LOT_ID = iLotId
                       or LOM.DOC_DOCUMENT_ID = iDocDocumentId)
                  and LOM.LOM_SESSION = iSession)
             );

    -- Curseur de parcours des entr�es atelier pour les mouvements de retour de composants vers les stocks
    cursor crFalFactoryIn(iMaterialLinkId number)
    is
      select   FAL_FACTORY_IN_ID
             , nvl(IN_BALANCE, 0) IN_BALANCE
          from FAL_FACTORY_IN
         where FAL_LOT_MATERIAL_LINK_ID = iMaterialLinkId
           and IN_BALANCE > 0
      order by IN_CHRONOLOGY
             , IN_VERSION
             , IN_LOT
             , IN_PIECE;

    -- Curseur de rafraichissement de la qt� dispo
    cursor crStockPosition(iStockPositionId number)
    is
      select     nvl(SPO_AVAILABLE_QUANTITY, 0) SPO_AVAILABLE_QUANTITY
            from STM_STOCK_POSITION
           where STM_STOCK_POSITION_ID = iStockPositionId
      for update;

    lbUpdateQuantity        boolean;
    lnHoldQty               number;
    lnTrashQty              number;
    lnReturnQty             number;
    lnSubcontractLocationId number;
    lnSubcontractStockId    number;
    lnTrashQtyToHold        number;
    lnReturnQtyToHold       number;
    lnQtyToHold             number;
    lnHoldedQtyOnAttrib     number;
    lStrSQLQuery            varchar2(32000);
    ltabStockPosition       TTabSTM_STOCK_POSITION;
    tplStockPosition        crStockPosition%rowtype;
    lnSpoAvailableQty       number;
  begin
    -- Modification de la quantit� par l'utilisateur
    lbUpdateQuantity         :=(nvl(iLotMatLinkTmpId, 0) <> 0);
    lnSubcontractLocationId  := iSubcontractLocationId;

    -- Parcours des composants � traiter
    for tplFalLomLinkTmpReturn in crFalLomLinkTmpReturn loop
      -- Calcul des quantit�s, si pour un composant, alors les quantit�s sont celles du composant,
      -- si pour un lot, alors ce sont celles du lot, et doivent �tre recalcul�es au niveau du composant
      if     (    (iCallMode <> ctxtBatchCall)
              or (nvl(iLotId, 0) = 0) )
         and lbUpdateQuantity then
        -- Calcul quantit� saisie du composant
        lnHoldQty    := FAL_TOOLS.ArrondiInferieur(nvl(iUpdatedQtyToHold, 0), tplFalLomLinkTmpReturn.GCO_GOOD_ID);
        -- Calcul qt� d�chet du composants
        lnTrashQty   := FAL_TOOLS.ArrondiInferieur(nvl(iTrashQty, 0), tplFalLomLinkTmpReturn.GCO_GOOD_ID);
        -- Calcul Qt� retour du composant
        lnReturnQty  := FAL_TOOLS.ArrondiInferieur(nvl(iReturnQty, 0), tplFalLomLinkTmpReturn.GCO_GOOD_ID);
      else
        -- Calcul quantit� saisie du composant
        lnHoldQty    :=
          nvl(FAL_TOOLS.ArrondiInferieur( (nvl(iUpdatedQtyToHold, 0) * tplFalLomLinkTmpReturn.LOM_UTIL_COEF) / tplFalLomLinkTmpReturn.LOM_REF_QTY
                                       , tplFalLomLinkTmpReturn.GCO_GOOD_ID
                                        )
            , 0
             );
        -- Calcul qt� d�chet du composants
        lnTrashQty   :=
          nvl(FAL_TOOLS.ArrondiInferieur( (nvl(iTrashQty, 0) * tplFalLomLinkTmpReturn.LOM_UTIL_COEF) / tplFalLomLinkTmpReturn.LOM_REF_QTY
                                       , tplFalLomLinkTmpReturn.GCO_GOOD_ID
                                        )
            , 0
             );
        -- Calcul Qt� retour du composant
        lnReturnQty  :=
          nvl(FAL_TOOLS.ArrondiInferieur( (nvl(iReturnQty, 0) * tplFalLomLinkTmpReturn.LOM_UTIL_COEF) / tplFalLomLinkTmpReturn.LOM_REF_QTY
                                       , tplFalLomLinkTmpReturn.GCO_GOOD_ID
                                        )
            , 0
             );
      end if;

      -- Dans le cas ou l'emplacement du sous-traitant n'a pas encore �t� trouv�, on tente la recherche avec le fournisseur de
      -- l'�ventuelle op�ration li� au composant courant.
      if     lnSubcontractLocationId is null
         and tplFalLomLinkTmpReturn.PAC_SUPPLIER_PARTNER_ID is not null then
        -- Recherche � nouveau le stock et l'emplacement du sous-traitant si le sous-traitant li� � l'op�ration li� au composant
        -- a chang�. A faire uniquement dans le contexte d'un retour de composants en sous-traitance op�ratoire. }
        STM_I_LIB_STOCK.getSubCStockAndLocation(tplFalLomLinkTmpReturn.PAC_SUPPLIER_PARTNER_ID, lnSubcontractStockId, lnSubcontractLocationId);
      end if;

      -- Cr�ation de tous les liens relatifs aux attributions du composants (Cr�ation automatique)
      FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFromAttribution
                                                             (aSessionId              => tplFalLomLinkTmpReturn.LOM_SESSION
                                                            , aFalLotMaterialLinkId   => tplFalLomLinkTmpReturn.FAL_LOT_MATERIAL_LINK_ID
                                                            , aFalLotMatLinkTmpID     => tplFalLomLinkTmpReturn.FAL_LOT_MAT_LINK_TMP_ID
                                                            , aHoldedQty              => lnHoldedQtyOnAttrib
                                                            , aC_CHRONOLOGY_TYPE      => tplFalLomLinkTmpReturn.C_CHRONOLOGY_TYPE
                                                            , aIS_FULL_TRACABILITY    => tplFalLomLinkTmpReturn.IS_FULL_TRACABILITY
                                                            , aSTM_LOCATION_ID        => lnSubcontractLocationId
                                                            , aHoldQty                => 0
                                                            , aTrashQty               => lnTrashQty   -- Qt� d�chet
                                                            , aReturnQty              => lnReturnQty   -- Qt� retour
                                                            , aForceWithStmLocation   => 1   -- Force l'utilisation de l'emplacement du sous-traitant pour le retour
                                                            , aContext                => iContext
                                                             );

      -- lnHoldedQtyOnAttrib contient la quantit� qui a �t� prise sur attribution. Calcul de ce qu'il reste � prendre sur le libre du stock sous-traitant
      -- sachant que la proc�dure CreateCompoLinkFromAttribution va prendre les quantit� dans l'ordre aHoldQty, aTrashQty, aReturnQty.
      if lnHoldedQtyOnAttrib >=(lnTrashQty + lnReturnQty) then
        exit;
      elsif lnHoldedQtyOnAttrib <= lnTrashQty then
        lnTrashQty  := lnTrashQty - lnHoldedQtyOnAttrib;
      else
        lnReturnQty  := lnReturnQty -(lnHoldedQtyOnAttrib - lnTrashQty);
        lnTrashQty   := 0;
      end if;

      -- Construction de la requ�te de s�lection des positions de stock
      STM_PRC_STOCK_POSITION.BuildSTM_STOCK_POSITIONQuery(oSQLQuery            => lStrSQLQuery
                                                        , iLocationId          => lnSubcontractLocationId
                                                        , iGoodId              => tplFalLomLinkTmpReturn.GCO_GOOD_ID
                                                        , iForceLocation       => 1
                                                        , iLotId               => iLotId
                                                        , iPriorityToAttribs   => 0
                                                         );

      -- G�n�ration des liens de saisie des quantit�s
      execute immediate lStrSQLQuery
      bulk collect into ltabStockPosition;

      if ltabStockPosition.first is not null then
        for i in ltabStockPosition.first .. ltabStockPosition.last loop
          -- R�cup�ration de la qt� dispo de la position de la vue, qui peut changer pendant le parcours
          -- de ce curseur...doit donc �tre relue � chaque fois.
          -- la position est lock�e le temps de l'update
          open crStockPosition(ltabStockPosition(i).STM_STOCK_POSITION_ID);

          fetch crStockPosition
           into tplStockPosition;

          if crStockPosition%found then
            lnSpoAvailableQty  := tplStockPosition.SPO_AVAILABLE_QUANTITY;
          else
            lnSpoAvailableQty  := 0;
          end if;

          -- Si la position � du disponible
          if (lnSpoAvailableQty > 0) then
            if lnSpoAvailableQty < lnTrashQty then
              lnTrashQtyToHold   := lnSpoAvailableQty;
              lnReturnQtyToHold  := 0;
            else
              lnTrashQtyToHold   := lnTrashQty;
              lnReturnQtyToHold  := least(lnReturnQty, lnSpoAvailableQty - lnTrashQty);
            end if;

            -- G�n�ration des liens de type r�servation sur position de stock.
            FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkStockAvalaible(tplFalLomLinkTmpReturn.LOM_SESSION
                                                                     , tplFalLomLinkTmpReturn.FAL_LOT_MAT_LINK_TMP_ID
                                                                     , ltabStockPosition(i).STM_STOCK_POSITION_ID
                                                                     , 0
                                                                     , lnTrashQtyToHold
                                                                     , lnReturnQtyToHold
                                                                     , iContext
                                                                      );
            lnTrashQty   := lnTrashQty - lnTrashQtyToHold;
            lnReturnQty  := lnReturnQty - lnReturnQtyToHold;
          end if;

          -- Fermeture et d�blocage de la position
          close crStockPosition;

          -- Plus de r�servation � faire.
          exit when(lnTrashQty <= 0)
               and (lnReturnQty <= 0);
        end loop;
      end if;
    end loop;
  end GenLinkForSubcontractReturn;

  /**
  * procedure : GenerateLinkForOutput
  * Description : G�n�ration des liens composants pour les mouvements de type sortie
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param
  */
  procedure GenerateLinkForOutput(
    iSession                in varchar2
  , iContext                in integer
  , iUseParamQty            in integer
  , iCallMode               in integer
  , iReceptionType          in integer
  , iLotMatLinkTmpId        in number
  , iDocDocumentId          in number
  , iLotId                  in number
  , iUpdatedQtyToHold       in number
  , iLeftQtyToHold          in number
  , iSubcontractStockId     in number
  , iSubcontractLocationId  in number
  , iSelectFromAttribsFirst in integer
  , iStmLocationId          in number
  , iBalanceNeed            in integer
  , iUseRemainNeedQty       in integer
  , iUseOnlyReservedQtySTT  in integer
  , iAutoInitQty            in boolean
  , iCFabType               in number
  , iAutoCommit             in integer
  )
  is
    -- Curseur de parcours des composants temporaires pour des mouvements de sortie de stock
    cursor crCompoForOutput
    is
      select LOM.GCO_GOOD_ID
           , PDT.PDT_STOCK_ALLOC_BATCH
           , FAL_TOOLS.PrcIsFullTracability(LOM.GCO_GOOD_ID) IS_FULL_TRACABILITY
           , LOM.FAL_LOT_MAT_LINK_TMP_ID
           , TAL.PAC_SUPPLIER_PARTNER_ID
           , LOM.LOM_SEQ
           , LOM.STM_LOCATION_ID
           , nvl(LOM.C_CHRONOLOGY_TYPE, '0') C_CHRONOLOGY_TYPE
           , nvl(LOM.LOM_NEED_QTY, 0) -
             decode(iContext
                  , ctxtSubContractPTransfer, DOC_LIB_SUBCONTRACTP.GetCompDelivQty(LOM.FAL_LOT_MATERIAL_LINK_ID, null, 1)
                  , ctxtSubContractOTransfer, DOC_LIB_SUBCONTRACTO.GetCompDelivQty(LOM.FAL_LOT_MATERIAL_LINK_ID, null, 1)
                  , 0
                   ) LOM_NEED_QTY
           , LOM.FAL_LOT_ID
           , LOM.DOC_DOCUMENT_ID
           , LOM.LOM_SESSION
           , LOM.FAL_LOT_MATERIAL_LINK_ID
           , LOM.C_KIND_COM
           , LOM.C_DISCHARGE_COM
           , nvl(LOM.LOM_FULL_REQ_QTY, 0) LOM_FULL_REQ_QTY
        from FAL_LOT_MAT_LINK_TMP LOM
           , GCO_PRODUCT PDT
           , FAL_LOT_MATERIAL_LINK MAT
           , FAL_TASK_LINK TAL
       where PDT.PDT_STOCK_MANAGEMENT = 1
         and LOM.GCO_GOOD_ID = PDT.GCO_GOOD_ID
         and LOM.FAL_LOT_MATERIAL_LINK_ID = MAT.FAL_LOT_MATERIAL_LINK_ID
         and MAT.FAL_LOT_ID = TAL.FAL_LOT_ID(+)
         and MAT.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+)
         and (   iContext = ctxtComponentReplacingIn
              or iUseParamQty = 1
              or nvl(LOM.LOM_NEED_QTY, 0) > 0)
         and (    (    nvl(iLotMatLinkTmpId, 0) <> 0
                   and LOM.FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId)
              or (    nvl(iLotMatLinkTmpId, 0) = 0
                  and ( (select count(*)
                           from GCO_CHARACTERIZATION
                          where GCO_GOOD_ID = LOM.GCO_GOOD_ID
                            and instr(cAutoInitCharCpt, C_CHARACT_TYPE) > 0) = 0)
                  and (   LOM.FAL_LOT_ID = iLotId
                       or LOM.DOC_DOCUMENT_ID = iDocDocumentId)
                  and LOM.LOM_SESSION = iSession
                 )
             )
            /* Il ne faut pas effectuer les s�lections en r�ception pour les composants qui doivent �tre appair�s
               (produit termin� type "Pi�ce" et composant en fonction de la config FAL_PAIRING_CHARACT)
         sauf si l'OF est de type sous-traitance Achat. */
         and (   not(    iContext = ctxtManufacturingReceipt
                     and (select nvl(max(CHA_STOCK_MANAGEMENT), 0)
                            from GCO_CHARACTERIZATION
                           where GCO_GOOD_ID = (select GCO_GOOD_ID
                                                  from FAL_LOT
                                                 where FAL_LOT_ID = iLotId)
                             and C_CHARACT_TYPE = '3') = 1
                     and (select nvl(max(CHA_STOCK_MANAGEMENT), 0)
                            from GCO_CHARACTERIZATION
                           where GCO_GOOD_ID = LOM.GCO_GOOD_ID
                             and instr(cPairingCaract, C_CHARACT_TYPE) > 0) = 1
                    )
              or (iCFabType = FAL_BATCH_FUNCTIONS.btSubcontract)
             );

    type TTabSTM_STOCK_POSITION is table of STM_PRC_STOCK_POSITION.gcurSPO%rowtype;

    TabSTM_STOCK_POSITION   TTabSTM_STOCK_POSITION;
    lvStrSQLQuery           varchar2(32000);
    lnLastAvailableQty      STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    lnPermittedQtyToHold    FAL_COMPONENT_LINK.FCL_HOLD_QTY%type;
    lnPriorityLocationId    number;
    lnLocationId            number;
    liForceLocation         integer;
    lnTotalQtyToHold        FAL_COMPONENT_LINK.FCL_HOLD_QTY%type;
    lnQtyToHold             FAL_COMPONENT_LINK.FCL_HOLD_QTY%type;
    lnAttribQtyOnThisComp   FAL_NETWORK_LINK.FLN_QTY%type;
    lnRemainQtyOnLaunched   number;
    nSubcontractStockId     number;
    lnSubcontractLocationId number;
    lbSkipLocation          boolean;
    lCFabType               FAL_LOT.C_FAB_TYPE%type;
  begin
    nSubcontractStockId      := iSubcontractStockId;
    lnSubcontractLocationId  := iSubcontractLocationId;

    -- Parcours des composants � traiter
    for tplCompoForOutput in crCompoForOutput loop
      -- Recherche le stock et l'emplacement du sous-traitant en transfert dans le cadre de la sous-traitance op�ratoire
      -- mais uniquement si le contexte d'appel est le lot (donc que le document ou la position ne sont pas identifi�s en entr�e).
      -- Effectue cette recherche �galement lors du lancement du lot pour les composants � envoyer au sous-traitant. Dans ce cas,
      -- il est possible que plusieurs composant � livrer au sous-traitant soit associ� � des sous-traitant diff�rent dans le m�me lot.
      if     tplCompoForOutput.PAC_SUPPLIER_PARTNER_ID is not null
         and (    (    iContext in(ctxtSubContractOTransfer)
                   and (iCallMode = ctxtBatchCall) )
              or (    iContext in(ctxtBatchLaunch)
                  and tplCompoForOutput.C_DISCHARGE_COM = '6')
             ) then
        STM_I_LIB_STOCK.getSubCStockAndLocation(tplCompoForOutput.PAC_SUPPLIER_PARTNER_ID, nSubcontractStockId, lnSubcontractLocationId);
      end if;

      -- D�termine l'emplacement � prendre en compte en priorit� pour les composants '6' (� livrer au sous-traitant) ou �galement
      -- pour tous les composants d'un lot de sous-traitance au lancement du lot.
      -- L'emplacement prioritaire est utilis� pour d�terminer les positions de stock � prendre en compte pour les r�servations.
      -- En premier l'emplacement du sous-traitant et ensuite tous les emplacements g�r�s par la calcul des besoins en fonction de la
      -- quantit� disponible mais en excluant les emplacements des autres sous-traitants.
      lnPriorityLocationId  := null;
      lCFabType             := FAL_LIB_BATCH.getCFabType(iLotID => tplCompoForOutput.FAL_LOT_ID);

      if (    iContext in(ctxtBatchLaunch)
          and (   tplCompoForOutput.C_DISCHARGE_COM = '6'
               or (lCFabType = FAL_BATCH_FUNCTIONS.btSubcontract) ) ) then
        lnPriorityLocationId  := lnSubcontractLocationId;
      end if;

      -- Recherche l'emplacement � utiliser en fonction des configurations, de l'emplacement du composant courant et �ventuellement,
      -- en r�ception d'un lot de sous-traitance d'achat, l'emplacement du sous-traitant. Peut �galement �tre forc� par une saisie manuelle.
      lnLocationId          := GetLocationId(tplCompoForOutput.STM_LOCATION_ID, iStmLocationId, liForceLocation);

      -- G�n�ration des liens de saisie de quantit�
      if     tplCompoForOutput.GCO_GOOD_ID is not null
         and tplCompoForOutput.STM_LOCATION_ID is not null
         and tplCompoForOutput.FAL_LOT_MAT_LINK_TMP_ID is not null
         and tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID is not null
         and tplCompoForOutput.LOM_SEQ is not null then
        -- G�n�ration des liens sur les composants temporaires en fonction du contexte d'utilisation.
        if iContext in
             (ctxtComponentOutput
            , ctxtSubcOComponentOutput
            , ctxtProductionAdvance
            , ctxtBatchAssembly
            , ctxtBatchLaunch
            , ctxtStocktoBatchAllocation
            , ctxtComponentReplacingIn
            , ctxtManufacturingReceipt
            , ctxtSubContractPTransfer
            , ctxtSubContractOTransfer
             ) then
          -- utilisation de la quantit� � saisir, param�tre de la fonction
          if iUseParamQty = 1 then
            lnTotalQtyToHold  := iLeftQtyToHold;
          -- Si l'on est pas en tracabilit� compl�te
          elsif(tplCompoForOutput.IS_FULL_TRACABILITY = 0) then
            -- en r�ception, initialisation avec qt� besoin totale - la qt� d�j� prise sur l'atelier
            if (    iReceptionType in(FAL_BATCH_FUNCTIONS.rtFinishedProduct, FAL_BATCH_FUNCTIONS.rtReject)
                and iAutoInitQty
                and nvl(iUpdatedQtyToHold, 0) = 0
                and (   nvl(iStmLocationId, 0) = 0
                     or lCFabType = FAL_BATCH_FUNCTIONS.btSubcontract)
                and iContext = ctxtManufacturingReceipt
               ) then
              if tplCompoForOutput.C_KIND_COM = '2' then
                lnTotalQtyToHold  := 0;
              else
                lnTotalQtyToHold  :=
                  nvl(tplCompoForOutput.LOM_FULL_REQ_QTY, 0) -
                  GetComponentQtyOnFactory(tplCompoForOutput.LOM_SESSION, tplCompoForOutput.FAL_LOT_MAT_LINK_TMP_ID);
              end if;
            else
              -- Sinon avec la qt� besoin
              lnTotalQtyToHold  := nvl(tplCompoForOutput.LOM_NEED_QTY, 0);
            end if;
          -- Si tracabilit� compl�te et attribution sur stock des besoins fab
          elsif     tplCompoForOutput.IS_FULL_TRACABILITY = 1
                and tplCompoForOutput.PDT_STOCK_ALLOC_BATCH = 1 then
            -- calcul de la quantit� attribu�e
            lnTotalQtyToHold  := nvl(SumOfComponentAttributions(tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID), 0);
          end if;

          if     iUseParamQty = 0
             and (   iContext = ctxtSubContractPTransfer
                  or iContext = ctxtSubContractOTransfer) then
            lnTotalQtyToHold  :=
                lnTotalQtyToHold - nvl(SumOfComponentAttributions(tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID, nSubcontractStockId, lnSubcontractLocationId), 0);

            if nvl(iUseOnlyReservedQtySTT, 0) = 0 then
              lnTotalQtyToHold  :=
                        lnTotalQtyToHold - nvl(STM_FUNCTIONS.GetStockAvailable(tplCompoForOutput.GCO_GOOD_ID, nSubcontractStockId, lnSubcontractLocationId), 0);
            end if;
          end if;

          -- composant li� � une op�ration externe g�r� par la sous-traitance op�ratoire
          if     iContext in(ctxtComponentOutput)
             and tplCompoForOutput.C_DISCHARGE_COM = '6' then
            lnTotalQtyToHold  := 0;
          end if;

          lnQtyToHold  := lnTotalQtyToHold;

          -- G�n�ration des liens sur les composants, s'il y a une quantit� � affecter
          -- ou si ne pas solder besoin, pour recherche de l'alerte
          if    lnQtyToHold > 0
             or (iBalanceNeed = 0) then
            -- En r�ception, pour les d�riv�s on fait directement le lien avec la quantit� saisie
            -- (il s'agit d'une entr�e en stock, il n'y a pas de r�servation)
            if     (iContext = ctxtManufacturingReceipt)
               and (tplCompoForOutput.C_KIND_COM = '2') then
              GenerateCompoLinkForDerived(aSessionId            => tplCompoForOutput.LOM_SESSION
                                        , aFalLotMatLinkTmpId   => tplCompoForOutput.FAL_LOT_MAT_LINK_TMP_ID
                                        , aStmLocationId        => lnLocationId
                                        , aQty                  => lnQtyToHold
                                         );
              lnQtyToHold  := 0;
            end if;

            if     (lnQtyToHold > 0)
               and (iSelectFromAttribsFirst = 1) then
              -- G�n�ration des liens sur attribution
              if iBalanceNeed = 1 then
                -- Cr�ation de tous les liens relatifs aux attributions du composants (Cr�ation automatique)
                FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFromAttribution
                  (tplCompoForOutput.LOM_SESSION
                 , tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID
                 , tplCompoForOutput.FAL_LOT_MAT_LINK_TMP_ID
                 , lnAttribQtyOnThisComp
                 , tplCompoForOutput.C_CHRONOLOGY_TYPE
                 , tplCompoForOutput.IS_FULL_TRACABILITY
                 , lnLocationId
                 , (case
                      when    (iContext in(ctxtManufacturingReceipt, ctxtSubCOComponentOutput)
                              )   -- 20120619 AGE : Transfert partiel possible en STO   ctxtSubContractPTransfer
                           or nvl(iLotMatLinkTmpId, 0) <> 0 then lnQtyToHold   -- Qt� � saisir
                      else null   -- Saisie quantit� totale attribu�e
                    end
                   )
                 , 0
                 , 0
                 , liForceLocation
                 , iContext
                  );   -- @Return : Quantit� r�elle saisie
                -- Reste � r�server
                lnQtyToHold  := lnQtyToHold - lnAttribQtyOnThisComp;
              else
                -- Reste � r�server
                lnQtyToHold  := lnQtyToHold - nvl(SumOfComponentAttributions(tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID), 0);
              end if;
            end if;

            -- Il reste des qt� (Hors attributions, � prendre sur le stock)
            if lnQtyToHold > 0 then
              -- Au besoin, r�cup�ration des qt� restantes � sortie sur les OFs lanc�s
              if iUseRemainNeedQty = 1 then
                lnRemainQtyOnLaunched  := FAL_COMPONENT_FUNCTIONS.GetFreeQtyForLaunchedBatches(tplCompoForOutput.GCO_GOOD_ID);
              else
                lnRemainQtyOnLaunched  := 0;
              end if;

              -- Construction de la requ�te de s�lection des positions de stock
              STM_PRC_STOCK_POSITION.BuildSTM_STOCK_POSITIONQuery(oSQLQuery             => lvStrSQLQuery
                                                                , iLocationId           => lnLocationId
                                                                , iGoodId               => tplCompoForOutput.GCO_GOOD_ID
                                                                , iForceLocation        => liForceLocation
                                                                , iLotId                => tplCompoForOutput.FAL_LOT_ID
                                                                , iPriorityToAttribs    => 0
                                                                , iPriorityLocationId   => lnPriorityLocationId
                                                                 );

              -- G�n�ration des liens de saisie des quantit�s
              execute immediate lvStrSQLQuery
              bulk collect into TabSTM_STOCK_POSITION;

              if TabSTM_STOCK_POSITION.first is not null then
                for i in TabSTM_STOCK_POSITION.first .. TabSTM_STOCK_POSITION.last loop
                  lbSkipLocation  := false;

                  -- Pour les composants � envoyer chez le sous-traitance ou pour les composants des lots de sous-traitance, il faut exclure
                  -- les emplacements des autres sous-traitants.
                  if     (lnPriorityLocationId is not null)
                     and (TabSTM_STOCK_POSITION(i).STM_LOCATION_ID <> lnPriorityLocationId) then
                    -- V�rifie si c'est un emplacement d'un stock de sous-traitant
                    lbSkipLocation  :=
                      (STM_I_LIB_STOCK.getSubContract(FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_LOCATION'
                                                                                          , 'STM_STOCK_ID'
                                                                                          , TabSTM_STOCK_POSITION(i).STM_LOCATION_ID
                                                                                           )
                                                     ) = 1
                      );
                  end if;

                  if not lbSkipLocation then
                    -- R�cup�ration de la qt� dispo de la position de la vue, qui peut changer pendant le parcours
                    -- de ce curseur...doit donc �tre relue � chaque fois.
                    -- la position est lock�e le temps de l'update
                    select nvl(max(SPO_AVAILABLE_QUANTITY), 0)
                      into lnLastAvailableQty
                      from STM_STOCK_POSITION
                     where STM_STOCK_POSITION_ID = TabSTM_STOCK_POSITION(i).STM_STOCK_POSITION_ID;

                    if lnLastAvailableQty > 0 then
                      -- tenir compte des bulletins non confirm�s
                      if iContext = ctxtSubContractPTransfer then
                        lnLastAvailableQty  :=
                          lnLastAvailableQty -
                          DOC_LIB_SUBCONTRACTP.GetCompDelivQty(tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID, TabSTM_STOCK_POSITION(i).STM_LOCATION_ID, 1);
                      elsif iContext = ctxtSubContractOTransfer then
                        lnLastAvailableQty  :=
                          lnLastAvailableQty -
                          DOC_LIB_SUBCONTRACTO.GetCompDelivQty(tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID, TabSTM_STOCK_POSITION(i).STM_LOCATION_ID, 1);
                      elsif iContext = ctxtSubContractPReturn then
                        lnLastAvailableQty  :=
                          lnLastAvailableQty -
                          DOC_LIB_SUBCONTRACTP.GetCompReturnQty(tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID, TabSTM_STOCK_POSITION(i).STM_LOCATION_ID, 1);
                      elsif iContext = ctxtSubContractOReturn then
                        lnLastAvailableQty  :=
                          lnLastAvailableQty -
                          DOC_LIB_SUBCONTRACTO.GetCompReturnQty(tplCompoForOutput.FAL_LOT_MATERIAL_LINK_ID, TabSTM_STOCK_POSITION(i).STM_LOCATION_ID, 1);
                      end if;
                    end if;

                    -- Si lnRemainQtyOnLaunched > 0, on d�compte d'abord pour les lots lanc�s avant de sortir sur ce composant.
                    if lnRemainQtyOnLaunched > 0 then
                      if lnRemainQtyOnLaunched >= lnLastAvailableQty then
                        lnRemainQtyOnLaunched  := lnRemainQtyOnLaunched - lnLastAvailableQty;
                        lnLastAvailableQty     := 0;
                      else
                        lnLastAvailableQty     := lnLastAvailableQty - lnRemainQtyOnLaunched;
                        lnRemainQtyOnLaunched  := 0;
                      end if;
                    end if;

                    -- Si la position � du disponible
                    if    (lnLastAvailableQty > 0)
                       or (tplCompoForOutput.C_KIND_COM = '2') then
                      -- Peut �tre r�serv� sur cette position (si c'est un d�riv�, toute la quantit� prise en compte vu que ce sera une entr�e en stock et non une sortie)
                      if tplCompoForOutput.C_KIND_COM = '2' then
                        lnPermittedQtyToHold  := nvl(lnQtyToHold, 0);
                      else
                        lnPermittedQtyToHold  := least(nvl(lnQtyToHold, 0), nvl(lnLastAvailableQty, 0) );
                      end if;

                      -- G�n�ration des liens de type r�servation sur position de stock.
                      if iBalanceNeed = 1 then
                        if iAutoCommit = 1 then
                          FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkStockAvalaible(aSessionId            => tplCompoForOutput.LOM_SESSION
                                                                                   , aFalLotMatLinkTmpId   => tplCompoForOutput.FAL_LOT_MAT_LINK_TMP_ID
                                                                                   , aStmStockPositionId   => TabSTM_STOCK_POSITION(i).STM_STOCK_POSITION_ID
                                                                                   , aHoldQty              => lnPermittedQtyToHold
                                                                                   , aContext              => iContext
                                                                                    );
                        else
                          CreateCompoLinkStockAvalaible(aSessionId            => tplCompoForOutput.LOM_SESSION
                                                      , aFalLotMatLinkTmpId   => tplCompoForOutput.FAL_LOT_MAT_LINK_TMP_ID
                                                      , aStmStockPositionId   => TabSTM_STOCK_POSITION(i).STM_STOCK_POSITION_ID
                                                      , aHoldQty              => lnPermittedQtyToHold
                                                      , aContext              => iContext
                                                       );
                        end if;
                      end if;

                      -- Reste � r�server
                      lnQtyToHold  := lnQtyToHold - lnPermittedQtyToHold;
                    end if;
                  end if;   -- not lbSkipLocation

                  -- Plus de r�servation � faire.
                  exit when lnQtyToHold <= 0;
                end loop;
              end if;
            -- La totalit� de la quantit� � �t� prise sur les attributions
            else
              lnQtyToHold  := 0;
            end if;

            if lnQtyToHold > 0 then
              updateComponentLinkMissingAT(tplCompoForOutput.FAL_LOT_MAT_LINK_TMP_ID);
            end if;
          end if;
        end if;
      end if;
    end loop;
  end GenerateLinkForOutput;

  /**
  * Description : Proc�dure globale de g�n�ration des liens entre composants temporaires,
  *               attributions, entr�e atelier.
  *
  */
  procedure GlobalComponentLinkGeneration(
    aFAL_LOT_MAT_LINK_TMP_ID   in FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type default null
  , aFAL_LOT_ID                in FAL_LOT.FAL_LOT_ID%type default null
  , aDOC_DOCUMENT_ID           in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aDOC_POSITION_ID           in DOC_POSITION.DOC_POSITION_ID%type default null
  , aLOM_SESSION               in FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type
  , aContext                   in integer
  , aBalanceNeed               in integer default 1
  , aUseParamQty               in integer default 0
  , aUpdatedQtyToHold          in number default 0
  , aTrashQty                  in number default 0
  , aReturnQty                 in number default 0
  , iLocationId                in number default null
  , iTrashLocationId           in number default null
  , ReturnCompoIsScrap         in integer default 1
  , ReceptionType              in integer default FAL_BATCH_FUNCTIONS.rtFinishedProduct
  , aUseRemainNeedQty          in integer default 0
  , aSelectFromAttribsFirst    in integer default 1
  , aCFabType                  in FAL_LOT.C_FAB_TYPE%type default 0
  , aAutoSelectAllCompoOnSplit in integer default 0
  , aUseOnlyReservedQtySTT     in integer default 0
  , iAutoCommit                in integer default 1
  )
  is
    -- Qt� d�chet et retour CPT Calcul�es
    nStmLocationId         number;
    nSubcontractLocationId number;
    nSubcontractStockId    number;
    bAutoInitQty           boolean;
    lnLotId                number;
    lnUpdatedQtyToHold     number;
    lnDocumentId           number;
    lnPositionId           number;
    lnTaskLinkId           number;
    lCFabType              FAL_LOT.C_FAB_TYPE%type;
    lnCallMode             integer;
  begin
    lnCallMode          := ctxtNullCall;

    if nvl(aFAL_LOT_MAT_LINK_TMP_ID, 0) <> 0 then
      -- Recherche le document et le lot associ� au composant sp�cifi�. Appel� dans le cas de la modification de la quantit� sur le composant.
      select DOC_DOCUMENT_ID
           , DOC_POSITION_ID
           , FAL_LOT_ID
        into lnDocumentId
           , lnPositionId
           , lnLotId
        from FAL_LOT_MAT_LINK_TMP
       where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID;

      -- Garantit le m�me fonctionnement pour les contextes ind�pendants de la sous-traitance.
      lnLotId     := aFAL_LOT_ID;
      -- Par d�faut, on consid�re que le mode d'appel est le lot (donc que le document ou la position ne sont pas identifi� en entr�e)
      lnCallMode  := ctxtBatchCall;

      -- Si le document n'existe pas sur le composant, on tente avec la position �ventuellement associ�e.
      if     lnDocumentId is null
         and lnPositionId is not null then
        select DOC_DOCUMENT_ID
          into lnDocumentId
          from DOC_POSITION
         where DOC_POSITION_ID = lnPositionId;

        lnCallMode  := ctxtPositionCall;
      elsif lnDocumentId is not null then
        lnCallMode  := ctxtDocumentCall;
      end if;
    elsif nvl(aDOC_POSITION_ID, 0) <> 0 then
      -- Recherche le document et le lot associ� � la position sp�cifi�e. Appel� dans le cas d'un transfert ou d'un retour � partir
      -- de la position du document. Remarque : si le lot est renseign� sur la position, nous sommes en sous-traitance d'achat, par contre,
      -- si l'op�ration est renseign� nous sommes en sous-traitance op�ratoire.
      select DOC_DOCUMENT_ID
           , FAL_LOT_ID
           , FAL_SCHEDULE_STEP_ID
        into lnDocumentId
           , lnLotId
           , lnTaskLinkId
        from DOC_POSITION
       where DOC_POSITION_ID = aDOC_POSITION_ID;

      -- Si le lot n'existe pas directement sur la position, recherche le lot sur l'op�ration associ�e � la position.
      if     lnLotId is null
         and lnTaskLinkId is not null then
        select FAL_LOT_ID
          into lnLotId
          from FAL_TASK_LINK
         where FAL_SCHEDULE_STEP_ID = lnTaskLinkId;
      end if;

      lnCallMode  := ctxtPositionCall;
    elsif nvl(aDOC_DOCUMENT_ID, 0) <> 0 then
      -- Document sp�cifi�. Appel� dans le cas d'un transfert ou d'un retour � partir de la position du document
      lnDocumentId  := aDOC_DOCUMENT_ID;
      lnLotId       := aFAL_LOT_ID;
      lnCallMode    := ctxtDocumentCall;
    elsif nvl(aFAL_LOT_ID, 0) <> 0 then
      -- Lot sp�cifi�. Appel� dans les objets Mouvements de composants
      if aContext in(ctxtSubContractPTransfer, ctxtSubContractPReturn) then
        -- Recherche le document li� au lot sp�cifi�. Appel� dans le cas d'un transfert � partir de l'objet Mouvements de composants stock sous-traitant
        FAL_LIB_SUBCONTRACTP.GetBatchOriginDocument(iFalLotId => aFAL_LOT_ID, ioDocDocumentId => lnDocumentId, ioDocPositionId => lnPositionId);
      end if;

      lnLotId     := aFAL_LOT_ID;
      -- D�finit le mode d'appel lot (donc que le document ou la position ne sont pas identifi� en entr�e).
      lnCallMode  := ctxtBatchCall;
    end if;

    -- D�termine le type de lot en traitement
    lCFabType           := FAL_LIB_BATCH.getCFabType(iLotID => lnLotId);
    bAutoInitQty        :=    (lCFabType = FAL_BATCH_FUNCTIONS.btSubcontract)
                           or PCS.PC_CONFIG.GetBooleanConfig('PPS_MISSING_COMP_RECEPT');

    -- D�termine le stock et l'emplacement du sous-traitant si le contexte le demande
    if     (aContext in(ctxtManufacturingReceipt, ctxtBatchLaunch) )
       and (lCFabType = FAL_BATCH_FUNCTIONS.btSubcontract) then
      -- Si on est sur un OF de sous-traitance d'achat et en r�ception ou en lancement du lot, on initialise l'emplacement de stock avec celui du sous-traitant
      nSubcontractLocationId  := GetSubcontractLocationId(lnLotId, aFAL_LOT_MAT_LINK_TMP_ID);

      if nSubcontractLocationId is not null then
        nSubcontractStockId  := STM_I_LIB_STOCK.GetStockId(nSubcontractLocationId);
      end if;

      -- D�finit l'emplacement du sous-traitant comme emplacement � utiliser lors de la recherche de l'emplacement du composant � traiter
      -- dans le cadre des sorties de composants
      nStmLocationId          := nvl(nSubcontractLocationId, iLocationId);
    elsif     aContext in(ctxtSubContractPTransfer, ctxtSubContractOTransfer, ctxtSubContractPReturn, ctxtSubContractOReturn, ctxtSubCOComponentOutput)
          and lnDocumentId is not null then
      -- Si transfert ou retour en sous-traitance et sortie de composant en sous-traitance op�ratoire, on d�finit le stock et
      -- l'emplacement li� au tiers (sous-traitant) � l'aide du document courant
      nSubcontractStockId     := STM_I_LIB_STOCK.getSubCStockID(iSupplierId => DOC_I_LIB_DOCUMENT.GetPacThird(lnDocumentId) );
      nSubcontractLocationId  := STM_I_LIB_STOCK.GetDefaultLocation(nSubcontractStockId);
      -- D�finit l'emplacement particulier � utiliser lors de la recherche de l'emplacement du composant � traiter dans le cadre des
      -- sorties de composants. Renseign� uniqument dans le cas d'une saisie manuelle.
      nStmLocationId          := iLocationId;
    else
      -- D�finit l'emplacement particulier � utiliser lors de la recherche de l'emplacement du composant � traiter dans le cadre des
      -- sorties de composants. Renseign� uniqument dans le cas d'une saisie manuelle.
      nStmLocationId  := iLocationId;
    end if;

    -- lnUpdatedQtyToHold utilis� en r�ception. La valeur est d�cr�ment�e dans la proc�dure ci-dessous (CompoLinkGenFactoryInOnReceipt) des saisies effectu�es en atelier
    lnUpdatedQtyToHold  := aUpdatedQtyToHold;

    -- G�n�ration des liens composants en atelier pour la r�ception
    -- Si nStmLocationId est null, on est en modification qt� en interface atelier et non sur stock
    if     (aContext = ctxtManufacturingReceipt)
       and (ReceptionType <> FAL_BATCH_FUNCTIONS.rtDismantling)
       and (nvl(nStmLocationId, 0) = 0) then
      CompoLinkGenFactoryInOnReceipt(iLotMatLinkTmpId     => aFAL_LOT_MAT_LINK_TMP_ID
                                   , iFalLotId            => lnLotId
                                   , iSessionId           => aLOM_SESSION
                                   , ioUpdatedQtyToHold   => lnUpdatedQtyToHold
                                    );
    end if;

    -- G�n�ration des liens composants en atelier pour un �clatement de lots
    if aContext = ctxtBatchSplitting then
      CompoLinkGenFactoryInOnSplit(aOriginBatchID             => lnLotId
                                 , aSession                   => aLOM_SESSION
                                 , aFAL_LOT_MAT_LINK_TMP_ID   => aFAL_LOT_MAT_LINK_TMP_ID
                                 , aUpdatedQtyToHold          => aUpdatedQtyToHold
                                 , aAutoSelectAllCompo        => aAutoSelectAllCompoOnSplit
                                  );
    -- R�ception de composants d�riv�s
    elsif aContext = ctxtDerivativeReturn then
      for tplComponents in (select FAL_LOT_MAT_LINK_TMP_ID
                                 , STM_LOCATION_ID
                                 , LOM_FULL_REQ_QTY
                              from FAL_LOT_MAT_LINK_TMP
                             where LOM_SESSION = aLOM_SESSION
                               and FAL_LOT_ID = lnLotId) loop
        GenerateCompoLinkForDerived(aSessionId            => aLOM_SESSION
                                  , aFalLotMatLinkTmpId   => tplComponents.FAL_LOT_MAT_LINK_TMP_ID
                                  , aStmLocationId        => nvl(iLocationId, tplComponents.STM_LOCATION_ID)
                                  , aQty                  => tplComponents.LOM_FULL_REQ_QTY
                                   );
      end loop;
    -- Mouvements de composants de type retour en stock, remplacement
    elsif    aContext = ctxtComponentReturn
          or aContext = ctxtComponentReplacingOut
          or aContext = ctxtBatchToStockAllocation
          or (aContext = ctxtBatchBalance)
          or (     (aContext = ctxtManufacturingReceipt)
              and (ReceptionType = FAL_BATCH_FUNCTIONS.rtDismantling) ) then
      GenerateLinkForReturn(iSession              => aLOM_SESSION
                          , iLotMatLinkTmpId      => aFAL_LOT_MAT_LINK_TMP_ID
                          , iLotId                => lnLotId
                          , iTrashQty             => aTrashQty
                          , iReturnQty            => aReturnQty
                          , iStmLocationId        => iLocationId
                          , iTrashLocationId      => iTrashLocationId
                          , iReturnCompoIsScrap   => ReturnCompoIsScrap
                          , iSelectAllFactoryIn   =>     (aContext = ctxtBatchBalance)
                                                     and (nvl(aFAL_LOT_MAT_LINK_TMP_ID, 0) = 0)
                           );
    -- Mouvements de composants de type retour de sous-traitance
    elsif    aContext = ctxtSubContractPReturn
          or aContext = ctxtSubContractOReturn then
      GenLinkForSubcontractReturn(iSession                 => aLOM_SESSION
                                , iContext                 => aContext
                                , iCallMode                => lnCallMode
                                , iLotMatLinkTmpId         => aFAL_LOT_MAT_LINK_TMP_ID
                                , iDocDocumentId           => aDOC_DOCUMENT_ID
                                , iLotId                   => lnLotId
                                , iUpdatedQtyToHold        => aUpdatedQtyToHold
                                , iTrashQty                => aTrashQty
                                , iReturnQty               => aReturnQty
                                , iSubcontractLocationId   => nSubcontractLocationId
                                 );
    -- Mouvements de composants de type sortie de stock
    elsif    aContext <> ctxtManufacturingReceipt
          or (   ReceptionType = FAL_BATCH_FUNCTIONS.rtBatchAssembly
              or (    ReceptionType in(FAL_BATCH_FUNCTIONS.rtFinishedProduct, FAL_BATCH_FUNCTIONS.rtReject)
                  and bAutoInitQty
                  and nvl(aUpdatedQtyToHold, 0) = 0
                  and (    (nvl(nStmLocationId, 0) = 0)
                       or (nSubcontractLocationId is not null) )
                 )
              or (    ReceptionType in(FAL_BATCH_FUNCTIONS.rtFinishedProduct, FAL_BATCH_FUNCTIONS.rtReject)
                  and nvl(aUpdatedQtyToHold, 0) > 0
                  and aUseParamQty = 1)
             ) then
      GenerateLinkForOutput(iSession                  => aLOM_SESSION
                          , iContext                  => aContext
                          , iUseParamQty              => aUseParamQty
                          , iCallMode                 => lnCallMode
                          , iReceptionType            => ReceptionType
                          , iLotMatLinkTmpId          => aFAL_LOT_MAT_LINK_TMP_ID
                          , iDocDocumentId            => aDOC_DOCUMENT_ID
                          , iLotId                    => lnLotId
                          , iUpdatedQtyToHold         => aUpdatedQtyToHold
                          , iLeftQtyToHold            => lnUpdatedQtyToHold
                          , iSubcontractStockId       => nSubcontractStockId
                          , iSubcontractLocationId    => nSubcontractLocationId
                          , iSelectFromAttribsFirst   => aSelectFromAttribsFirst
                          , iStmLocationId            => nStmLocationId
                          , iBalanceNeed              => aBalanceNeed
                          , iUseRemainNeedQty         => aUseRemainNeedQty
                          , iUseOnlyReservedQtySTT    => aUseOnlyReservedQtySTT
                          , iAutoInitQty              => bAutoInitQty
                          , iCFabType                 => lCFabType
                          , iAutoCommit               => iAutoCommit
                           );
    end if;
  end GlobalComponentLinkGeneration;

  /**
  * procedure : UpdateComponentLinkAdjQty
  * Description : Recalcul de la quantit� sup / inf, sur modification de la quantit� saisie.
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_MAT_LINK_TMP_ID : ID Du composant � traiter
  */
  procedure updateComponentLinkAdjQty(aFAL_LOT_MAT_LINK_TMP_ID FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type)
  is
    aSumHoldedQty         number;
    aLOM_ADJUSTED_QTY     number;
    aLOM_FULL_REQ_QTY     number;
    aLOM_NEED_QTY         number;
    aC_KIND_COM           varchar2(10);
    aLOM_STOCK_MANAGEMENT number;
    aLOM_BOM_REQ_QTY      number;
    aLOM_CONSUMPTION_QTY  number;
    aLOM_REJECTED_QTY     number;
    aLOM_BACK_QTY         number;
  begin
    -- R�cup�ration de la somme des quantit�s saisies pour le composant
    select nvl(sum(FCL_HOLD_QTY), 0)
      into aSumHoldedQty
      from FAL_COMPONENT_LINK
     where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID;

    -- R�cup�ration des compteurs du composant
    begin
      select nvl(LOM_ADJUSTED_QTY, 0)
           , nvl(LOM_FULL_REQ_QTY, 0)
           , nvl(LOM_NEED_QTY, 0)
           , nvl(LOM_BOM_REQ_QTY, 0)
           , nvl(LOM_CONSUMPTION_QTY, 0)
           , nvl(LOM_REJECTED_QTY, 0)
           , nvl(LOM_BACK_QTY, 0)
           , C_KIND_COM
           , LOM_STOCK_MANAGEMENT
        into aLOM_ADJUSTED_QTY
           , aLOM_FULL_REQ_QTY
           , aLOM_NEED_QTY
           , aLOM_BOM_REQ_QTY
           , aLOM_CONSUMPTION_QTY
           , aLOM_REJECTED_QTY
           , aLOM_BACK_QTY
           , aC_KIND_COM
           , aLOM_STOCK_MANAGEMENT
        from FAL_LOT_MAT_LINK_TMP LML
       where LML.FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID;
    exception
      when others then
        aLOM_ADJUSTED_QTY      := 0;
        aLOM_FULL_REQ_QTY      := 0;
        aLOM_NEED_QTY          := 0;
        aC_KIND_COM            := '';
        aLOM_STOCK_MANAGEMENT  := 0;
    end;

    -- MAJ de la qt� sup inf, quantit� besoin totale, quantit� besoin CPT si n�cessaire.
    if aSumHoldedQty > aLOM_NEED_QTY then
      -- Calcul quantit� sup/inf
      aLOM_ADJUSTED_QTY  := aLOM_ADJUSTED_QTY + aSumHoldedQty - aLOM_NEED_QTY;
      -- Calcul quantit� besoin totale
      aLOM_FULL_REQ_QTY  := aLOM_ADJUSTED_QTY + aLOM_BOM_REQ_QTY;

      -- Calcul quantit� besoin CPT
      if    aC_KIND_COM in('2', '4', '5')
         or nvl(aLOM_STOCK_MANAGEMENT, 0) <> 1 then
        aLOM_NEED_QTY  := 0;
      elsif aC_KIND_COM = '1' then
        -- Si qt� sup inf n�gative.
        if nvl(aLOM_ADJUSTED_QTY, 0) < 0 then
          aLOM_NEED_QTY  := aLOM_FULL_REQ_QTY + aLOM_REJECTED_QTY + aLOM_BACK_QTY - aLOM_CONSUMPTION_QTY;
        else
          aLOM_NEED_QTY  := aLOM_FULL_REQ_QTY + greatest(aLOM_REJECTED_QTY - aLOM_ADJUSTED_QTY, 0) + aLOM_BACK_QTY - aLOM_CONSUMPTION_QTY;
        end if;
      end if;

      update FAL_LOT_MAT_LINK_TMP LML
         set LML.LOM_ADJUSTED_QTY = aLOM_ADJUSTED_QTY
           , LML.LOM_FULL_REQ_QTY = aLOM_FULL_REQ_QTY
           , LML.LOM_NEED_QTY = aLOM_NEED_QTY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_INIT_SESSION.GetUserIni
       where LML.FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID;
    end if;
  end;

  /**
  * procedure : UpdateComponentLinkAdjQtyAT
  * Description : idem que UpdateComponentLinkAdjQty en transaction autonome
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   iLotMatLinkTmpId : Id du composant � traiter
  */
  procedure updateComponentLinkAdjQtyAT(iLotMatLinkTmpId FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type)
  is
    pragma autonomous_transaction;
  begin
    UpdateComponentLinkAdjQty(iLotMatLinkTmpId);
    commit;
  end;

  /**
  * function CheckMovementKindConditions
  * Description : V�rification si le type de mouvement de sortie de stock est autoris�
  *
  * @created CLG
  * @lastUpdate
  * @private
  * @param
  */
  function CheckMovementKindConditions(
    iContext         in integer
  , iLocationId      in number
  , iStockPositionId in number
  , iFactoryInId     in number
  , iQtyToHold       in number
  , iTrashQty        in number
  , iReturnQty       in number
  , iTrashLocationId in number default null
  , iReceptionType   in integer default FAL_BATCH_FUNCTIONS.rtFinishedProduct
  )
    return varchar2
  is
    cursor crFalFactoryIn
    is
      select FIN.GCO_GOOD_ID
           , FIN.IN_CHRONOLOGY
           , FIN.IN_PIECE
           , FIN.IN_LOT
           , FIN.IN_VERSION
           , nvl(iLocationId, FIN.STM_LOCATION_ID) STM_LOCATION_ID
           , ELE.GCO_QUALITY_STATUS_ID
        from FAL_FACTORY_IN FIN
           , STM_ELEMENT_NUMBER ELE
       where FIN.FAL_FACTORY_IN_ID = iFactoryInId
         and STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(FIN.GCO_GOOD_ID, FIN.IN_PIECE, FIN.IN_LOT, FIN.IN_VERSION) = ELE.STM_ELEMENT_NUMBER_ID(+);

    cursor crStockPosition
    is
      select SPO.GCO_GOOD_ID
           , SPO.STM_STOCK_ID
           , SPO.STM_LOCATION_ID
           , SEM.GCO_QUALITY_STATUS_ID
           , SPO.SPO_CHRONOLOGICAL
           , SPO_PIECE
           , SPO_SET
           , SPO_VERSION
        from STM_STOCK_POSITION SPO
           , STM_ELEMENT_NUMBER SEM
       where SPO.STM_STOCK_POSITION_ID = iStockPositionId
         and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+);

    lvMsg             varchar2(2000);
    lnTrashLocationId number
                := nvl(iTrashLocationId, FWK_I_LIB_ENTITY.getIdfromPk2('STM_LOCATION', 'LOC_DESCRIPTION', PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_TRASH') ) );
  begin
    if     nvl(iQtyToHold, 0) = 0
       and nvl(iReturnQty, 0) = 0
       and nvl(iTrashQty, 0) = 0 then
      return null;
    end if;

    if    iContext = ctxtComponentReturn
       or iContext = ctxtComponentReplacingOut
       or iContext = ctxtBatchToStockAllocation
       or (iContext = ctxtBatchBalance)
       or (     (iContext = ctxtManufacturingReceipt)
           and (iReceptionType = FAL_BATCH_FUNCTIONS.rtDismantling) ) then
      for tplFalFactoryIn in crFalFactoryIn loop
        if nvl(iReturnQty, 0) > 0 then
          -- Test si le type de mouvement retour de composant en stock est autoris�
          lvMsg  :=
            STM_I_LIB_MOVEMENT.VerifyStockOutputCond(iGoodId            => tplFalFactoryIn.GCO_GOOD_ID
                                                   , iStockId           => FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_LOCATION'
                                                                                                               , 'STM_STOCK_ID'
                                                                                                               , tplFalFactoryIn.STM_LOCATION_ID
                                                                                                                )
                                                   , iLocationId        => tplFalFactoryIn.STM_LOCATION_ID
                                                   , iQualityStatusId   => tplFalFactoryIn.GCO_QUALITY_STATUS_ID
                                                   , iChronological     => tplFalFactoryIn.IN_CHRONOLOGY
                                                   , iPiece             => tplFalFactoryIn.IN_PIECE
                                                   , iSet               => tplFalFactoryIn.IN_LOT
                                                   , iVersion           => tplFalFactoryIn.IN_VERSION
                                                   , iMovementKindId    => FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindStockReturn
                                                   , iCheckAll          => 0
                                                    );

          if lvMsg is not null then
            return lvMsg;
          end if;
        end if;

        -- Test si le type de mouvement retour de composant en d�chet est autoris�
        if nvl(iTrashQty, 0) > 0 then
          lvMsg  :=
            STM_I_LIB_MOVEMENT.VerifyStockOutputCond(iGoodId            => tplFalFactoryIn.GCO_GOOD_ID
                                                   , iStockId           => FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_LOCATION'
                                                                                                               , 'STM_STOCK_ID'
                                                                                                               , lnTrashLocationId
                                                                                                                )
                                                   , iLocationId        => lnTrashLocationId
                                                   , iQualityStatusId   => tplFalFactoryIn.GCO_QUALITY_STATUS_ID
                                                   , iChronological     => tplFalFactoryIn.IN_CHRONOLOGY
                                                   , iPiece             => tplFalFactoryIn.IN_PIECE
                                                   , iSet               => tplFalFactoryIn.IN_LOT
                                                   , iVersion           => tplFalFactoryIn.IN_VERSION
                                                   , iMovementKindId    => FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindReturnInTrash
                                                   , iCheckAll          => 0
                                                    );

          if lvMsg is not null then
            return lvMsg;
          end if;
        end if;
      end loop;
    elsif iContext = ctxtManufacturingReceipt then
      for tplFalFactoryIn in crFalFactoryIn loop
        -- Test si le type de mouvement de consommation de composant � la r�ception est autoris�
        return STM_I_LIB_MOVEMENT.VerifyStockOutputCond(iGoodId            => tplFalFactoryIn.GCO_GOOD_ID
                                                      , iStockId           => cWorkshopStockId
                                                      , iLocationId        => cWorkshopLocationId
                                                      , iQualityStatusId   => tplFalFactoryIn.GCO_QUALITY_STATUS_ID
                                                      , iChronological     => tplFalFactoryIn.IN_CHRONOLOGY
                                                      , iPiece             => tplFalFactoryIn.IN_PIECE
                                                      , iSet               => tplFalFactoryIn.IN_LOT
                                                      , iVersion           => tplFalFactoryIn.IN_VERSION
                                                      , iMovementKindId    => FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindConsumedComp
                                                      , iCheckAll          => 0
                                                       );
      end loop;
    else   --On consid�re que tout autre contexte concerne la sortie de composants
      for tplStockPosition in crStockPosition loop
        return STM_I_LIB_MOVEMENT.VerifyStockOutputCond(iGoodId            => tplStockPosition.GCO_GOOD_ID
                                                      , iStockId           => tplStockPosition.STM_STOCK_ID
                                                      , iLocationId        => tplStockPosition.STM_LOCATION_ID
                                                      , iQualityStatusId   => tplStockPosition.GCO_QUALITY_STATUS_ID
                                                      , iChronological     => tplStockPosition.SPO_CHRONOLOGICAL
                                                      , iPiece             => tplStockPosition.SPO_PIECE
                                                      , iSet               => tplStockPosition.SPO_SET
                                                      , iVersion           => tplStockPosition.SPO_VERSION
                                                      , iMovementKindId    => FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoStockOut
                                                      , iCheckAll          => 0
                                                       );
      end loop;
    end if;

    return null;
  end CheckMovementKindConditions;

  /**
  * function CheckQtyBeforeUPdate
  * Description : V�rification de la validit� des quantit�s � saisir
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param
  */
  function CheckQtyBeforeUpdate(
    aContext         in integer
  , iLotMatLinkTmpId in number default null
  , iLocationId      in number default null
  , iStockPositionId in number default null
  , aFalFactoryInId  in number default null
  , iCompoLinkId     in number default null
  , aQtyToHold       in number default 0
  , aTrashQty        in number default 0
  , aReturnQty       in number default 0
  , aFactoryInQty    in number default 0
  , aLomNeedQty      in number default 0
  , iCKindCom        in varchar2 default '1'
  , aHoldQtyOverNeed in integer default 0
  , iPreviousHoldQty in number default 0
  , iTrashLocationId in number default null
  )
    return varchar2
  is
    aSumHoldedQty     number;
    lnAvailableQty    number;
    lnReplacingOutQty number;
  begin
    -- On v�rifie que la quantit� saisie n'est pas n�gative
    if nvl(aQtyToHold, 0) < 0 then
      return PCS.PC_PUBLIC.TranslateWord('La quantit� saisie ne peut �tre n�gative!');
    end if;

    -- On v�rifie que la quantit� d�chet n'est pas n�gative
    if nvl(aTrashQty, 0) < 0 then
      return PCS.PC_PUBLIC.TranslateWord('La quantit� D�chet ne peut �tre n�gative');
    end if;

    -- On v�rifie que la quantit� retour n'est pas n�gative
    if nvl(aReturnQty, 0) < 0 then
      return PCS.PC_PUBLIC.TranslateWord('La quantit� Retour ne peut �tre n�gative');
    end if;

    -- On v�rifie que la qt� D�chet + la quantit� retour n'est pas sup�rieure � la quantit� en atelier
    if     (aContext <> ctxtSubContractPReturn)
       and (aContext <> ctxtSubContractOReturn)
       and nvl(aReturnQty, 0) + nvl(aTrashQty, 0) > nvl(aFactoryInQty, 0) then
      return PCS.PC_PUBLIC.TranslateWord('Les quantit�s Retour + D�chets ne peuvent �tre sup�rieures � la quantit� en Atelier');
    end if;

    -- En Affectation de composants lots -> Stk ou  en �clatement de lots
    -- On v�rifie que la qt� saisie n'est pas sup�rieure � la quantit� en atelier
    if     (   aContext = ctxtBatchToStockAllocation
            or aContext = ctxtBatchSplitting
            or (    aContext = ctxtManufacturingReceipt
                and nvl(aFalFactoryInId, 0) > 0) )
       and nvl(aQtyToHold, 0) > nvl(aFactoryInQty, 0) then
      return PCS.PC_PUBLIC.TranslateWord('La quantit� � affecter ne peut �tre sup�rieure � la quantit� en atelier du composant !');
    end if;

    -- R�cup�ration de la valeur actuellement saisie
      -- TODO Voir quand ona a abesoin de faire FAL_LOT_MAT_LINK_TMP_FUNCTIONS.GetSumOfComponentQty avec iLocationId <> null
    select nvl(sum(FCL_HOLD_QTY), 0)
      into aSumHoldedQty
      from FAL_COMPONENT_LINK
     where FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId;

    -- On v�rifie que la quantit� saisie n'est pas sup�rieure � la quantit� dispo de la position.
    if     aContext in
                      (ctxtComponentOutput, ctxtSubContractPTransfer, ctxtSubContractOTransfer, ctxtSubContractPReturn, ctxtSubContractOReturn, ctxtBatchLaunch)
       and nvl(iStockPositionId, 0) <> 0 then
      -- ainsi que la quantit� dispo de la position
      select nvl(max(SPO_AVAILABLE_QUANTITY), 0)
        into lnAvailableQty
        from STM_STOCK_POSITION
       where STM_STOCK_POSITION_ID = iStockPositionId;

      -- on v�rifie que la quantit� saisie n'est pas > � la quantit� disponible de la position
      if     (nvl(aQtyToHold, 0) >(lnAvailableQty + aSumHoldedQty) )
         and (iCKindCom <> '2') then
        return PCS.PC_PUBLIC.TranslateWord('La quantit� saisie ne peut �tre sup�rieure � la quantit� dispo!');
      end if;
    end if;

    -- V�rification des qt� saisies "� remplacer" et "de remplacement"
    if aContext = ctxtComponentReplacingOut then
      -- R�cup�ration de la quantit� d�j� saisie sur cette entr�e atelier
      select nvl(sum(FCL_RETURN_QTY), 0) + nvl(sum(FCL_TRASH_QTY), 0)
        into lnReplacingOutQty
        from FAL_COMPONENT_LINK
       where FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId
         and FAL_FACTORY_IN_ID = aFalFactoryInId;

      -- On v�rifie que la quantit� saisie � remplacer n'est pas sup�rieure � la quantit� en atelier
      if (aTrashQty + aReturnQty + lnReplacingOutQty) > aFactoryInQty then
        return PCS.PC_PUBLIC.TranslateWord('La quantit� � remplacer ne peut �tre sup�rieure � la quantit� en Atelier');
      end if;

      -- R�cup�ration de la quantit� d�j� saisie sur le composant
      select nvl(sum(FCL_RETURN_QTY), 0) + nvl(sum(FCL_TRASH_QTY), 0)
        into lnReplacingOutQty
        from FAL_COMPONENT_LINK
       where FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId
         and FAL_COMPONENT_LINK_ID <> iCompoLinkId;

      -- Et que la qt� saisie � remplacer n'est pas inf�rieure � la qt� saisie
      if (aTrashQty + aReturnQty + lnReplacingOutQty) < aSumHoldedQty then
        return PCS.PC_PUBLIC.TranslateWord('La quantit� � remplacer ne peut �tre inf�rieure � la somme des quantit�s de remplacement !');
      end if;
    elsif aContext = ctxtComponentReplacingIn then
      select nvl(sum(FCL_RETURN_QTY), 0) + nvl(sum(FCL_TRASH_QTY), 0)
        into lnReplacingOutQty
        from FAL_COMPONENT_LINK
       where FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId;

      -- On v�rifie que la somme des qt� saisies ne sera pas sup�rieure � la quantit� � remplacer
      if (aSumHoldedQty - iPreviousHoldQty + aQtyToHold) > lnReplacingOutQty then
        return PCS.PC_PUBLIC.TranslateWord('La somme des quantit�s saisies ne peut �tre sup�rieure � la quantit� � remplacer !');
      end if;
    elsif    aContext = ctxtStockToBatchAllocation
          or (     (   aContext = ctxtComponentOutput
                    or aContext = ctxtSubContractPTransfer
                    or aContext = ctxtSubContractOTransfer
                    or aContext = ctxtManufacturingReceipt
                    or aContext = ctxtBatchLaunch
                   )
              and aHoldQtyOverNeed = 0
             ) then
      -- On v�rifie que la somme des quantit� saisies ne sera pas sup�rieure � la quantit� besoin � affecter
      if (aSumHoldedQty - iPreviousHoldQty + aQtyToHold) > aLomNeedQty then
        return PCS.PC_PUBLIC.TranslateWord('La quantit� � affecter ne peut �tre sup�rieure � la quantit� besoin du composant !');
      end if;
    end if;

    -- V�rification si le type de mouvement de sortie de stock est autoris�
    return CheckMovementKindConditions(iContext           => aContext
                                     , iLocationId        => iLocationId
                                     , iStockPositionId   => iStockPositionId
                                     , iFactoryInId       => aFalFactoryInId
                                     , iQtyToHold         => aQtyToHold
                                     , iTrashQty          => aTrashQty
                                     , iReturnQty         => aReturnQty
                                     , iTrashLocationId   => iTrashLocationId
                                      );
  end;

  /**
  * procedure   : UpdateComponentQty
  * Description : Proc�dure de mise � jour des qt� saisies au niveau du composant attributions, entr�e atelier.
  *
  * @created ECA
  * @lastUpdate
  */
  procedure UpdateComponentQty(
    iLotMatLinkTmpId in     FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , iSessionId       in     FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type
  , aContext         in     integer
  , aQtyToHold       in     number
  , aTrashQty        in     number
  , aReturnQty       in     number
  , afactoryInqty    in     number
  , aLomNeedQty      in     number
  , iPreviousHoldQty in     number
  , ReceptionType    in     integer
  , aHoldQtyOverNeed in     integer
  , iLocationId      in     number
  , iTrashLocationId in     number
  , ioErrorMessage   in out varchar2
  )
  is
    aFCL_HOLD_QTY   number;
    aFCL_RETURN_QTY number;
    aFCL_TRASH_QTY  number;
  begin
    aFCL_HOLD_QTY    := aQtyToHold;
    aFCL_RETURN_QTY  := aReturnQty;
    aFCL_TRASH_QTY   := aTrashQty;
    -- Formatage des qt�s au nombre de d�cimales du produit
    FormatQtyWithDecimalNumber(aFCL_HOLD_QTY              => aFCL_HOLD_QTY
                             , aFCL_RETURN_QTY            => aFCL_RETURN_QTY
                             , aFCL_TRASH_QTY             => aFCL_TRASH_QTY
                             , aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                              );
    -- V�rification des quantit�s � saisir
    ioErrorMessage   :=
      CheckQtyBeforeUpdate(aContext           => aContext
                         , iLotMatLinkTmpId   => iLotMatLinkTmpId
                         , aQtyToHold         => aFCL_HOLD_QTY
                         , aTrashQty          => aFCL_TRASH_QTY
                         , aReturnQty         => aFCL_RETURN_QTY
                         , aFactoryinQty      => aFactoryinQty
                         , aLomNeedQty        => aLomNeedQty
                         , aHoldQtyOverNeed   => aHoldQtyOverNeed
                         , iPreviousHoldQty   => iPreviousHoldQty
                         , iLocationId        => iLocationId
                         , iTrashLocationId   => iTrashLocationId
                          );

    if trim(ioErrorMessage) is null then
      -- Suppression de tous les liens existants pour le composant
      PurgeLinkForAComponentAT(iLotMatLinkTmpId => iLotMatLinkTmpId, iContext => aContext, iLocationId => null, iDeleteAllCompoLink => 1);

      -- Regen�ration des liens - Eclatement de lots
      if aContext = ctxtBatchSplitting then
        GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                                    , aLOM_SESSION               => iSessionId
                                    , aContext                   => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
                                    , aUpdatedQtyToHold          => aFCL_HOLD_QTY
                                     );
      -- Regen�ration des liens - Sortie de composants
      elsif    aContext = ctxtComponentOutput
            or aContext = ctxtSubContractPTransfer
            or aContext = ctxtSubContractOTransfer
            or aContext = ctxtBatchLaunch
            or aContext = ctxtComponentReplacingIn then
        GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                                    , aLOM_SESSION               => iSessionId
                                    , aContext                   => aContext
                                    , aUseParamQty               => 1
                                    , aUpdatedQtyToHold          => aFCL_HOLD_QTY
                                     );
        -- Mise � jour, au besoin, de la quantit� sup/inf du composant
        updateComponentLinkAdjQtyAT(iLotMatLinkTmpId);

        -- Mise � jour Qt� max r�ceptionnable et quantit� fabricable.
        if aContext = ctxtBatchLaunch then
          FAL_LOT_MAT_LINK_TMP_FUNCTIONS.UpdateMaxReceiptQty(aSessionId => iSessionId, FalLotMatLinkTmpId => iLotMatLinkTmpId);
        end if;
      -- Regen�ration des liens - Retour de composants
      elsif    aContext = ctxtComponentReturn
            or aContext = ctxtSubContractPReturn
            or aContext = ctxtSubContractOReturn
            or aContext = ctxtBatchBalance then
        GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                                    , aLOM_SESSION               => iSessionId
                                    , aContext                   => aContext
                                    , aTrashQty                  => aFCL_TRASH_QTY
                                    , aReturnQty                 => aFCL_RETURN_QTY
                                    , iLocationId                => iLocationId
                                    , iTrashLocationId           => iTrashLocationId
                                     );
      -- Regen�ration des liens - Affectation de composants de stock vers lots.
      elsif aContext = ctxtStockToBatchAllocation then
        GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                                    , aLOM_SESSION               => iSessionId
                                    , aContext                   => aContext
                                    , aUseParamQty               => 1
                                    , aUpdatedQtyToHold          => aFCL_HOLD_QTY
                                     );
      -- Regen�ration des liens - Affectation de composants de Lots vers stocks
      elsif aContext = ctxtBatchToStockAllocation then
        GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                                    , aLOM_SESSION               => iSessionId
                                    , aContext                   => aContext
                                    , aReturnQty                 => aFCL_RETURN_QTY
                                    , iLocationId                => iLocationId
                                     );
      elsif aContext = ctxtManufacturingReceipt then
        GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                                    , aLOM_SESSION               => iSessionId
                                    , aContext                   => aContext
                                    , aUseParamQty               => 1
                                    , aUpdatedQtyToHold          => aFCL_HOLD_QTY
                                    , aTrashQty                  => aFCL_TRASH_QTY
                                    , aReturnQty                 => aFCL_RETURN_QTY
                                    , ReceptionType              => ReceptionType
                                     );
        -- Mise � jour, au besoin, de la quantit� sup/inf du composant
        updateComponentLinkAdjQtyAT(iLotMatLinkTmpId);
      end if;
    end if;
  end UpdateComponentQty;

  /**
   * procedure : UpdateOneLink
   * Description : Proc�dure de mise � jour d'un lien entre composants et stock, attrib, ou entr�e atelier.
   */
  procedure UpdateOneLink(
    iCompoLinkId     in     FAL_COMPONENT_LINK.FAL_COMPONENT_LINK_ID%type
  , iSessionId       in     FAL_COMPONENT_LINK.FCL_SESSION%type
  , iContext         in     integer
  , iQtyToHold       in     number
  , iTrashQty        in     number
  , iReturnQty       in     number
  , iFactoryInQty    in     number
  , iLotMatLinkTmpId in     number
  , iFalFactoryInId  in     number
  , iStockPositionId in     number
  , iLomNeedId       in     number
  , iCKindCom        in     varchar2
  , iHoldQtyOverNeed in     integer
  , iPreviousHoldQty in     number
  , iLocationId      in     number
  , iTrashLocationId in     number
  , ioErrorMessage   in out varchar2
  )
  is
    aSumHoldedQty number;
    aLomNeedQty   number;
    nQtyToHold    number;
    nTrashQty     number;
    nReturnQty    number;
  begin
    nQtyToHold      := iQtyToHold;
    nTrashQty       := iTrashQty;
    nReturnQty      := iReturnQty;
    -- Formatage des qt�s au nombre de d�cimales du produit
    FormatQtyWithDecimalNumber(aFCL_HOLD_QTY              => nQtyToHold
                             , aFCL_RETURN_QTY            => nReturnQty
                             , aFCL_TRASH_QTY             => nTrashQty
                             , aFAL_LOT_MAT_LINK_TMP_ID   => iLotMatLinkTmpId
                              );
    ioErrorMessage  :=
      CheckQtyBeforeUpdate(aContext           => iContext
                         , iLotMatLinkTmpId   => iLotMatLinkTmpId
                         , iStockPositionId   => iStockPositionId
                         , aFalFactoryInId    => iFalFactoryInId
                         , iCompoLinkId       => iCompoLinkId
                         , aQtyToHold         => nQtyToHold
                         , aTrashQty          => nTrashQty
                         , aReturnQty         => nReturnQty
                         , aFactoryInQty      => iFactoryInQty
                         , aLomNeedQty        => iLomNeedId
                         , iCKindCom          => iCKindCom
                         , aHoldQtyOverNeed   => iHoldQtyOverNeed
                         , iPreviousHoldQty   => iPreviousHoldQty
                         , iLocationId        => iLocationId
                         , iTrashLocationId   => iTrashLocationId
                          );

    if trim(ioErrorMessage) is null then
      -- Suppression du lien composant
      FAL_COMPONENT_LINK_FUNCTIONS.DeleteComponentLink(iCompoLinkId);
      -- (re)cr�ation du lien avec les nouvelles quantit�s
      FAL_COMPONENT_LINK_FUNCTIONS.CompoLinkModifyQuantity(aSessionId            => iSessionId
                                                         , aContext              => iContext
                                                         , aFalLotMatLinkTmpId   => iLotMatLinkTmpId
                                                         , aStmStockPositionId   => iStockPositionId
                                                         , aFalFactoryInId       => iFalFactoryInId
                                                         , aHoldQty              => nQtyToHold
                                                         , aTrashQty             => nTrashQty
                                                         , aReturnQty            => nReturnQty
                                                         , iLocationId           => iLocationId
                                                         , iTrashLocationId      => iTrashLocationId
                                                          );

      -- Si la somme des Qt� saisies pour le composant est diff�rente de la qt� besoin, on adapte celle-ci via la quantit� sup/inf
      if    iContext = ctxtComponentOutput
         or iContext = ctxtSubContractPTransfer
         or iContext = ctxtSubContractOTransfer
         or iContext = ctxtBatchLaunch
         or iContext = ctxtManufacturingReceipt then
        begin
          select   nvl(sum(FCL.FCL_HOLD_QTY), 0)
                 , nvl(LOM.LOM_NEED_QTY, 0)
              into aSumHoldedQty
                 , aLomNeedQty
              from FAL_COMPONENT_LINK FCL
                 , FAL_LOT_MAT_LINK_TMP LOM
             where LOM.FAL_LOT_MAT_LINK_TMP_ID = iLotMatLinkTmpId
               and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID(+)
          group by LOM.LOM_NEED_QTY;
        exception
          when no_data_found then
            begin
              aSumHoldedQty  := 0;
              aLomNeedQty    := 0;
            end;
        end;

        if nvl(aSumHoldedQty, 0) > aLomNeedQty then
          updateComponentLinkAdjQtyAT(iLotMatLinkTmpId);
        end if;
      end if;
    end if;
  end UpdateOneLink;

  /**
  * procedure : DeleteComponentLinkReleaseCode5
  * Description : Suppression des r�servations pour les composants de type
  *      code d�charge = 5 (dispo au lancement) ou 6 (mvts de stock pour la sous-traitance). On en tient compte pour la
  *      simulation mais on ne sort pas les composants au lancement.
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId    Session Oracle
  * @param   aFalLotId     Lot � mettre � jour (tous les lots1 s�lectionn�s si ce param�tre est null)
  */
  procedure DeleteCompoLinkReleaseCode5(aSessionId varchar2, aFalLotId FAL_LOT.FAL_LOT_ID%type default null)
  is
  begin
    delete      FAL_COMPONENT_LINK
          where FCL_SESSION = aSessionId
            and FAL_LOT_MAT_LINK_TMP_ID in(
                  select FAL_LOT_MAT_LINK_TMP_ID
                    from FAL_LOT_MAT_LINK_TMP
                   where LOM_SESSION = aSessionId
                     and (    (    aFalLotId is not null
                               and FAL_LOT_ID = aFalLotId)
                          or (    aFalLotId is null
                              and FAL_LOT_ID in(select FAL_LOT_ID
                                                  from FAL_LOT1
                                                 where LT1_ORACLE_SESSION = aSessionId
                                                   and LT1_SELECT = 1) )
                         )
                     and (   C_DISCHARGE_COM = '5'
                          or C_DISCHARGE_COM = '6') );
  end;

  /**
  * procedure : DeleteComponentLinkReleaseCode234
  * Description : Suppression des r�servations pour les composants de type
  *      code d�charge = 2,3,4 . On en tient compte pour la
  *      simulation afin d'afficher l'info de disponibilit� � l'utilisateur
  *      mais on ne sort pas les composants au lancement.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionId    Session Oracle
  * @param   aFalLotId     Lot � mettre � jour (tous les lots1 s�lectionn�s si ce param�tre est null)
  */
  procedure DeleteCompoLinkReleaseCode234(aSessionId varchar2, aFalLotId FAL_LOT.FAL_LOT_ID%type default null)
  is
  begin
    delete      FAL_COMPONENT_LINK
          where FCL_SESSION = aSessionId
            and FAL_LOT_MAT_LINK_TMP_ID in(
                  select FAL_LOT_MAT_LINK_TMP_ID
                    from FAL_LOT_MAT_LINK_TMP
                   where LOM_SESSION = aSessionId
                     and (    (    aFalLotId is not null
                               and FAL_LOT_ID = aFalLotId)
                          or (    aFalLotId is null
                              and FAL_LOT_ID in(select FAL_LOT_ID
                                                  from FAL_LOT1
                                                 where LT1_ORACLE_SESSION = aSessionId
                                                   and LT1_SELECT = 1) )
                         )
                     and C_DISCHARGE_COM in('2', '3', '4') );
  end;

  /**
  * proc�dure DeleteComponentLink
  * Description Suppression d'un lien composant temporaire
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFalComponentLinkId    ID du lien de r�servation (table FAL_COMPONENT_LINK)
  */
  procedure DeleteComponentLink(aFalComponentLinkId FAL_COMPONENT_LINK.FAL_COMPONENT_LINK_ID%type)
  is
  begin
    delete from fal_component_link
          where fal_component_link_id = aFalComponentLinkId;
  end;
end FAL_COMPONENT_LINK_FCT;
