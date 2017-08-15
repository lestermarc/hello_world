--------------------------------------------------------
--  DDL for Package Body STM_LIB_ELEMENT_NUMBER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_LIB_ELEMENT_NUMBER" 
is
  /**
  * Description
  *   recherche le bien pour un détail de caractérisation
  */
  function GetGoodId(iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    return STM_ELEMENT_NUMBER.GCO_GOOD_ID%type
  is
    lResult STM_ELEMENT_NUMBER.GCO_GOOD_ID%type;
  begin
    select GCO_GOOD_ID
      into lResult
      from STM_ELEMENT_NUMBER
     where STM_ELEMENT_NUMBER_ID = iElementNumberID;

    return lResult;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * function GetElementId
  * Description
  *   recherche l'identifiant d'un ddetail de caracterisation
  * @created fpe 10.10.2013
  * @updated
  * @public
  * @param iGoodId : identifiant du bien
  * @param iElementType : type d'élément C_ELEMENT_TYPE
  * @param iValue : valeur
  * @return voir description
  */
  function GetElementId(
    iGoodID      in GCO_GOOD.GCO_GOOD_ID%type
  , iElementType in STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type
  , iValue       in STM_ELEMENT_NUMBER.SEM_VALUE%type
  )
    return STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  is
    lResult STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
  begin
    select STM_ELEMENT_NUMBER_ID
      into lResult
      from STM_ELEMENT_NUMBER
     where GCO_GOOD_ID = nvl(iGoodId, GCO_GOOD_ID)
       and C_ELEMENT_TYPE = iElementType
       and SEM_VALUE = iValue;

    return lResult;
  exception
    when no_data_found then
      return null;
    when too_many_rows then
      -- cas ou on aurait l'unicité par mandat
      ra(replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Plus d''un detail de caractérisation trouvé.')
               , '[GOO_MAJOR_REFERENCE]'
               , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId)
                )
        );
  end GetElementId;

  /**
  * function GetDetailCharType
  * Description
  *   Recherche pour un bien dletype de caractérisation porteur du detail
  * @created fpe 13.11.2013
  * @updated
  * @public
  * @param iGoodID : bien
  * @return voir description
  */
  function GetDetailCharType(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  is
    lCharId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type   := GCO_I_LIB_CHARACTERIZATION.GetUseDetailCharID(iGoodId);
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_CHARACTERIZATION', 'C_CHARACT_TYPE', lCharId);
  end GetDetailCharType;

  function ConvertCharT2ElementT(iCharType in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type)
    return STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type
  is
  begin
    case
      when iCharType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
        return STM_I_LIB_CONSTANT.gcElementTypeVersion;
      when iCharType = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        return STM_I_LIB_CONSTANT.gcElementTypePiece;
      when iCharType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
        return STM_I_LIB_CONSTANT.gcElementTypeSet;
      else
        return null;
    end case;
  end ConvertCharT2ElementT;

  /**
  * Description
  *   retourne le detail caracterisation entre un no de pièce, de lot et de version
  */
  function GetDetailElement(
    iGoodId  in GCO_GOOD.GCO_GOOD_ID%type
  , iPiece   in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iSet     in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iVersion in STM_ELEMENT_NUMBER.SEM_VALUE%type
  )
    return STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  is
    lResult   STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lCharType GCO_CHARACTERIZATION.C_CHARACT_TYPE%type        := GetDetailCharType(iGoodId);
  begin
    case
      when lCharType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
        lResult  := getElementId(iGoodId, STM_I_LIB_CONSTANT.gcElementTypeVersion, iVersion);
      when lCharType = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        lResult  := getElementId(iGoodId, STM_I_LIB_CONSTANT.gcElementTypePiece, iPiece);
      when lCharType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
        lResult  := getElementId(iGoodId, STM_I_LIB_CONSTANT.gcElementTypeSet, iSet);
      else
        lResult  := null;
    end case;

    return lResult;
  end GetDetailElement;

  /**
  * Description
  *   retourne l'élément portant le detail parmis 3 éléments
  */
  function GetDetailElement(
    iGoodId  in GCO_GOOD.GCO_GOOD_ID%type
  , iDetail1 in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iDetail2 in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iDetail3 in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  )
    return STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  is
    lResult      STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lCharTypeDet GCO_CHARACTERIZATION.C_CHARACT_TYPE%type        := GetDetailCharType(iGoodId);
  begin
    if lCharTypeDet is not null then
      select STM_ELEMENT_NUMBER_ID
        into lResult
        from STM_ELEMENT_NUMBER
       where STM_ELEMENT_NUMBER_ID in(iDetail1, iDetail2, iDetail3)
         and C_ELEMENT_TYPE = ConvertCharT2ElementT(lCharTypeDet);

      return lResult;
    else
      return null;
    end if;
  exception
    when no_data_found then
      return null;
  end GetDetailElement;

  /**
  * Description
  *   retourne le detail caracterisation lié à une position de stock
  */
  function GetDetailElementFromStockPos(iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
    return STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  is
  begin
    return GetDetailElement(iGoodId    => FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_STOCK_POSITION', 'GCO_GOOD_ID', iStockPositionId)
                          , iPiece     => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK_POSITION', 'SPO_PIECE', iStockPositionId)
                          , iSet       => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK_POSITION', 'SPO_SET', iStockPositionId)
                          , iVersion   => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK_POSITION', 'SPO_VERSION', iStockPositionId)
                           );
  end GetDetailElementFromStockPos;

    /**
  * Description
  *   retourne le detail caracterisation lié à un mouvement de stock
  */
  function GetDetailElementFromStockMov(iStockMovementId in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type)
    return STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  is
  begin
    return GetDetailElement(iGoodId    => FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_STOCK_MOVEMENT', 'GCO_GOOD_ID', iStockMovementId)
                          , iPiece     => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK_MOVEMENT', 'SMO_PIECE', iStockMovementId)
                          , iSet       => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK_MOVEMENT', 'SMO_SET', iStockMovementId)
                          , iVersion   => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK_MOVEMENT', 'SMO_VERSION', iStockMovementId)
                           );
  end GetDetailElementFromStockMov;

  /**
  * Description
  *   retourne le detail caracterisation lié à un détail de position de document
  */
  function GetDetailElementFromDocPosDet(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  is
  begin
    return GetDetailElement(iGoodId    => FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL', 'GCO_GOOD_ID', iPositionDetailId)
                          , iPiece     => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('DOC_POSITION_DETAIL', 'PDE_PIECE', iPositionDetailId)
                          , iSet       => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('DOC_POSITION_DETAIL', 'PDE_SET', iPositionDetailId)
                          , iVersion   => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('DOC_POSITION_DETAIL', 'PDE_VERSION', iPositionDetailId)
                           );
  end GetDetailElementFromDocPosDet;

  /**
  * Description
  *   retourne le detail caracterisation lié un bien et une valeur
  */
  function GetDetailElementFromValue(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iValue in STM_ELEMENT_NUMBER.SEM_VALUE%type)
    return STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  is
  begin
    return GetDetailElement(iGoodId => iGoodId, iPiece => iValue, iSet => iValue, iVersion => iValue);
  end GetDetailElementFromValue;

  /**
  * function GetImproperAnalyzeStatus
  * Description
  *   Renvoi le statut qualité en fonction d'une ré-analyse non-conforme
  */
  function GetImproperAnalyzeStatus(iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    return GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type
  is
    lStatusID GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type;
  begin
    select GCO_I_LIB_QUALITY_STATUS.GetNegativeRetestStatus(CHA.GCO_QUALITY_STAT_FLOW_ID)
      into lStatusID
      from GCO_CHARACTERIZATION CHA
     where CHA.GCO_CHARACTERIZATION_ID = STM_LIB_ELEMENT_NUMBER.GetCharFromDetailElement(iElementNumberID);

    return lStatusID;
  end GetImproperAnalyzeStatus;

  /**
  * function GetCharFromDetailElement
  * Description
  *   Renvoi l'id de la caractérisation en fonction d'un id du détail de caractérisation
  */
  function GetCharFromDetailElement(iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    return GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  is
    lCharID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    begin
      select GCO_CHARACTERIZATION_ID
        into lCharID
        from GCO_CHARACTERIZATION CHA
           , STM_ELEMENT_NUMBER SEM
       where SEM.STM_ELEMENT_NUMBER_ID = iElementNumberID
         and CHA.GCO_GOOD_ID = SEM.GCO_GOOD_ID
         and SEM.C_ELEMENT_TYPE =(case CHA.C_CHARACT_TYPE
                                    when '1' then '03'
                                    when '3' then '02'
                                    when '4' then '01'
                                  end);

      return lCharID;
    exception
      when no_data_found then
        return null;
    end;
  end GetCharFromDetailElement;

  /**
  * function GetCharFromElementType
  * Description
  *   Renvoi l'id de la caractérisation en fonction du bien et du type de détail de caractérisation
  */
  function GetCharFromElementType(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iElementType in STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type)
    return GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  is
    lCharID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    begin
      select GCO_CHARACTERIZATION_ID
        into lCharID
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and iElementType =(case C_CHARACT_TYPE
                              when '1' then '03'
                              when '3' then '02'
                              when '4' then '01'
                            end);

      return lCharID;
    exception
      when no_data_found then
        return null;
    end;
  end GetCharFromElementType;
end STM_LIB_ELEMENT_NUMBER;
