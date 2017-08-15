--------------------------------------------------------
--  DDL for Package Body FAL_PRC_FAL_PROP_COMMON
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_FAL_PROP_COMMON" 
is
  /**
  * procedure PushInfoUser
  * Description : Info. progression par le biais de la table COM_LIST_ID_TEMP
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iInfoDescription: Varchar2(4000)
  */
  procedure PushInfoUser(iInfoDescription varchar2, aNbProp integer default null)
  is
  begin
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_DESCRIPTION
               , LID_FREE_NUMBER_1
                )
         values (GetNewId
               , cstProgressInfoCode
               , iInfoDescription
               , aNbProp
                );
  end PushInfoUser;

  /**
  *  Function GetPropositionDefinition
  *  Description : Récupération des définitions de propositions
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iCPropType: Type de proposition
  * @param   iCSupplyMode : Mode d'approvisionnement
  * @return enregistrement de la table FAL_PROP_DEF
  */
  function GetPropositionDefinition(iCPropType in varchar2, iCSupplyMode in varchar2)
    return FAL_PROP_DEF%rowtype
  is
    result FAL_PROP_DEF%rowtype;
  begin
    if trim(iCSupplyMode) is null then
      select *
        into result
        from FAL_PROP_DEF
       where C_PROP_TYPE = iCPropType;
    else
      select *
        into result
        from FAL_PROP_DEF
       where C_PROP_TYPE = iCPropType
         and C_SUPPLY_MODE = iCSupplyMode;
    end if;

    return result;
  exception
    when no_data_found then
      return result;
  end GetPropositionDefinition;

  /**
  *  Function PropositionExists
  *  Description : Recherche de l'existance de proposition de type et mode d'appro donnée
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iTableName : Nom de la table de propositions concernées
  * @param   iCPropType : Type de proposition
  * @param   iCSupplyMode : Mode d'approvisionnement
  * @return true/false
  */
  function PropositionExists(iTableName in varchar2, iCPropType in varchar2, iCSupplyMode in varchar2)
    return boolean
  is
    lnNbProp   number;
    vPropExist varchar2(2000);
  begin
    vPropExist  :=
      ' select count(*) ' ||
      '   from ' ||
      iTableName ||
      ' A ' ||
      '      , FAL_PROP_DEF B ' ||
      '  where A.C_PREFIX_PROP = B.C_PREFIX_PROP ' ||
      '    and B.C_PROP_TYPE = :C_PROP_TYPE ' ||
      '    and B.C_SUPPLY_MODE = :C_SUPPLY_MODE ';

    execute immediate vPropExist
                 into lnNbProp
                using in iCPropType, in icSupplyMode;

    return lnNbProp > 0;
  end PropositionExists;

  /**
  * procedure UpdatePropDefinition
  * Description : Mise à jour des définitions de propositions
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  */
  procedure UpdatePropDefinition(
    iCPropType    in varchar2 default null
  , iCSupplyMode  in varchar2 default null
  , iFalPropDefID in number default null
  , iFprMeter     in integer default 0
  )
  is
  begin
    update FAL_PROP_DEF
       set FPR_METER = iFprMeter
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where (    nvl(iFalPropDefID, 0) = 0
            and c_prop_type = iCPropType
            and c_supply_mode = iCSupplyMode)
        or (    nvl(iFalPropDefID, 0) <> 0
            and FAL_PROP_DEF_ID = iFalPropDefID);
  end UpdatePropDefinition;

  /**
  * procedure DeletePropositions
  * Description : Suppression des propositions d'approvisionnement logistique
  *               et fabrication.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iGCO_GOOD_ID : Produit.
  * @param   iListOfStockID : List des stock sélectionnés dans le CB (Restreind la suppression)
  * @param   iDeletePropMode : Mode suppresion proposition
  * @param   iDeleteRequestMode : Mode suppression demande d'appro
  * @param   iUpdateRequestvalueMode : Mode Mise à jour demande d'appro
  * @param   iPropOrigin  : Origine de la proposition
  * @param   iDeleteWithDate : Suppression proposition plan directeur postérieur à
  * @param   iDate : Date pour suppression à partir de
  */
  procedure DeletePropositions(
    iGCO_GOOD_ID            in number default null
  , iListOfStockId          in varchar2 default null
  , iDeletePropMode         in integer default NO_DELETE_PROP
  , iDeleteRequestMode      in integer default NO_DELETE_REQUEST
  , iUpdateRequestvalueMode in integer default NO_UPDATE_REQUEST
  , iPropOrigin             in integer default STD_PROP
  , iDeleteWithdate         in integer default 0
  , iDate                   in date default null
  )
  is
  begin
    -- Suppression des propositions d'approvisionnement logistiques.
    FAL_PRC_FAL_DOC_PROP.DeleteFAL_DOC_PROP(iGCO_GOOD_ID
                                          , iListOfStockId
                                          , iDeletePropMode
                                          , iDeleteRequestMode
                                          , iUpdateRequestvalueMode
                                          , iPropOrigin
                                          , iDeleteWithdate
                                          , iDate
                                           );
    -- Suppression des propositions d'approvisionnements Fabrication.
    FAL_PRC_FAL_LOT_PROP.DeleteFAL_LOT_PROP(iGCO_GOOD_ID
                                          , iListOfStockId
                                          , iDeletePropMode
                                          , iDeleteRequestMode
                                          , iUpdateRequestvalueMode
                                          , iPropOrigin
                                          , iDeleteWithdate
                                          , iDate
                                           );
    -- Mise à jours des compteurs de propositions d'achat
    FAL_PRC_FAL_DOC_PROP.UpdatePropCounters;
    -- Mise à jours des compteurs de propositions de fabrication
    FAL_PRC_FAL_LOT_PROP.UpdatePropCounters;
  end DeletePropositions;

  /**
  * procedure DeletePropOnProdLevel
  * Description : Suppression des propositions d'approvisionnement logistique
  *               et fabrication, pour les produits de la table des niveaux
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSessionId : Session Oracle.
  * @param   iListOfStockID : List des stock sélectionnés dans le CB (Restreint la suppression)
  */
  procedure DeletePropOnProdLevel(iSessionId in varchar2, iListOfStockId in varchar2 default null)
  is
  begin
    for tplProdLevel in (select distinct FPL.GCO_GOOD_ID
                                    from FAL_PROD_LEVEL FPL
                                       , GCO_PRODUCT PDT
                                   where FPL.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                                     and FPL.FAL_PROD_LEVEL_ID < 0
                                     and FPL.FPL_SESSION_ID = iSessionId) loop
      DeletePropositions(tplProdLevel.GCO_GOOD_ID, iListOfStockId, DELETE_PROP, NO_DELETE_REQUEST, NO_UPDATE_REQUEST, STD_PROP);
    end loop;
  end DeletePropOnProdLevel;

  /**
  * procedure DeletePropComplLevel
  * Description : Suppression des propositions d'approvisionnement logistique
  *               et fabrication, pour les produits de la table des niveaux complémentaires
  *               (gestion des blocs d'équivalence).
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSessionId : Session Oracle.
  * @param   iListOfStockID : List des stock sélectionnés dans le CB (Restreint la suppression)
  */
  procedure DeletePropOnComplLevel(iSessionId in FAL_CB_COMP_LEVEL.CCL_SESSION_ID%type, iListOfStockId in varchar2 default null)
  is
    cursor CUR_FAL_CB_COMP_LEVEL
    is
      select GCO_GOOD_ID
        from FAL_CB_COMP_LEVEL
       where CCL_SESSION_ID = iSessionId
         and GCO_GOOD_ID is not null;

    CurFalCbCompLevel CUR_FAL_CB_COMP_LEVEL%rowtype;
  begin
    for CurFalCbCompLevel in CUR_FAL_CB_COMP_LEVEL loop
      DeletePropositions(CurFalCbCompLevel.GCO_GOOD_ID, iListOfStockId, DELETE_PROP, NO_DELETE_REQUEST, NO_UPDATE_REQUEST, STD_PROP);
    end loop;
  end DeletePropOnComplLevel;

  /**
  * Description
  *    Delete all propositions linked to a product/version (used by the good synchronisation feature)
  */
  procedure DeleteVersionProp(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iVersion in STM_STOCK_POSITION.SPO_VERSION%type)
  is
  begin
    -- Delete all purchase propositions linked to the good
    for tplProp in (select column_value FAL_DOC_PROP_ID
                      from table(FAL_I_LIB_LOT_PROP.GetDocPropInProgress(iGoodID) ) ) loop
      FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(aPropID => tplProp.FAL_DOC_PROP_ID, aDeleteProp => 1, aDeleteRequest => 1, aUpdateRequestValue => 0);
    end loop;

    -- Delete all manufacturing propositions linked to the good as finished product
    for tplProp in (select column_value FAL_LOT_PROP_ID
                      from table(FAL_I_LIB_LOT_PROP.GetFPInProgress(iGoodID, iVersion) ) ) loop
      FAL_PRC_FAL_LOT_PROP.DeleteOneFABProposition(aPropID => tplProp.FAL_LOT_PROP_ID, aDeleteProp => 1, aDeleteRequest => 1, aUpdateRequestValue => 0);
    end loop;

    -- Delete all manufacturing propositions linked to the good as component
    for tplProp in (select LOP.FAL_LOT_PROP_ID
                      from table(FAL_I_LIB_LOT_PROP.GetCptInProgress(iGoodID) ) A
                         , FAL_LOT_MAT_LINK_PROP LOM
                         , FAL_LOT_PROP LOP
                     where LOM.FAL_LOT_MAT_LINK_PROP_ID = A.column_value
                       and LOP.FAL_LOT_PROP_ID = LOM.FAL_LOT_PROP_ID) loop
      FAL_PRC_FAL_LOT_PROP.DeleteOneFABProposition(aPropID => tplProp.FAL_LOT_PROP_ID, aDeleteProp => 1, aDeleteRequest => 1, aUpdateRequestValue => 0);
    end loop;
  end DeleteVersionProp;
end;
