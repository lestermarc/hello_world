--------------------------------------------------------
--  DDL for Package Body GCO_LIB_VERSION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_VERSION" 
is
  /**
  * function IsInProgressData
  * Description
  *   Indicates if there is some in progress data for the version
  * @created fpe 23.09.2014
  * @updated
  * @public
  * @param iGoodId : good identifier
  * @param iVersion : version value
  * @return
  */
  function IsInProgressData(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iVersion in GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type)
    return number
  is
  begin
    if    STM_I_LIB_STOCK_POSITION.IsVersionInProgress(iGoodId, iVersion) = 1
       or DOC_I_LIB_POSITION.IsVersionInProgress(iGoodId, iVersion) = 1
       or FAL_I_LIB_BATCH.IsFPVersionInProgress(iGoodId, iVersion) = 1
       or FAL_I_LIB_BATCH.IsCptVersionInProgress(iGoodId, iVersion) = 1
       or FAL_I_LIB_LOT_PROP.IsDocPropInProgress(iGoodId) = 1
       or FAL_I_LIB_LOT_PROP.IsFPInProgress(iGoodId, iVersion) = 1
       or FAL_I_LIB_LOT_PROP.IsCptInProgress(iGoodId) = 1 then
      return 1;
    else
      return 0;
    end if;
  end IsInProgressData;

  /**
  * Description
  *   Return all kind of data those are linked to in progress data
  */
  procedure InProgressDataDetail(
    iGoodId     in     GCO_GOOD.GCO_GOOD_ID%type
  , iVersion    in     GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type
  , oStock      out    number
  , oInProgress out    number
  , oProp       out    number
  )
  is
  begin
    oStock       := STM_I_LIB_STOCK_POSITION.IsVersionInProgress(iGoodId, iVersion);
    oInProgress  :=
      sign(DOC_I_LIB_POSITION.IsVersionInProgress(iGoodId, iVersion) +
           FAL_I_LIB_BATCH.IsFPVersionInProgress(iGoodId, iVersion) +
           FAL_I_LIB_BATCH.IsCptVersionInProgress(iGoodId, iVersion)
          );
    oProp        :=
                 sign(FAL_I_LIB_LOT_PROP.IsDocPropInProgress(iGoodId) + FAL_I_LIB_LOT_PROP.IsFPInProgress(iGoodId, iVersion) + FAL_I_LIB_LOT_PROP.IsCptInProgress(iGoodId) );
  end InProgressDataDetail;

  /**
  * Description
  *   Pré-initialisation des options de traitement des en cours lros de la synchronisation des version de produits
  */
  procedure PreInitSynchOptions(
    iTargetGoodId         in     GCO_GOOD.GCO_GOOD_ID%type
  , iSourceGoodId         in     GCO_GOOD.GCO_GOOD_ID%type
  , oTargetStockMode      out    pls_integer
  , oTargetStockEnabled   out pls_integer
  , oTargetInProgressMode out    pls_integer
  , oTargetInProgressEnabled out    pls_integer
  , oTargetForecastMode out    pls_integer
  , oTargetForecastEnabled out    pls_integer
  , oSourceStockMode      out    pls_integer
  , oSourceStockEnabled      out    pls_integer
  , oSourceInProgressMode out    pls_integer
  , oSourceInProgressEnabled out    pls_integer
  , oSourceForecastMode   out    pls_integer
  , oSourceForecastEnabled   out    pls_integer
  )
  is
  begin
    oTargetStockMode       := 0;
    oTargetStockEnabled       := 1;
    oTargetInProgressMode  := 0;
    oTargetInProgressEnabled  := 1;
    oTargetForecastMode    := 0;
    oTargetForecastEnabled    := 1;
    oSourceStockMode       := 0;
    oSourceStockEnabled       := 1;
    oSourceInProgressMode  := 0;
    oSourceInProgressEnabled  := 1;
    oSourceForecastMode    := 0;
    oSourceForecastEnabled    := 1;
  end PreInitSynchOptions;
end GCO_LIB_VERSION;
