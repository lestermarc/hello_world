--------------------------------------------------------
--  DDL for Package Body FAL_LIB_LOT_PROP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_LOT_PROP" 
is
  /**
  * Description
  *    Cette function retourne la clef primaire du bien lié à l'ordre de fabrication
  *    dont la clef primaire est transmise en paramètre.
  */
  function getGcoGoodID(inFalLotPropID in FAL_LOT_PROP.FAL_LOT_PROP_ID%type)
    return FAL_LOT_PROP.GCO_GOOD_ID%type
  as
    lnGcoGoodID FAL_LOT_PROP.GCO_GOOD_ID%type;
  begin
    select GCO_GOOD_ID
      into lnGcoGoodID
      from FAL_LOT_PROP
     where FAL_LOT_PROP_ID = inFalLotPropID;

    return lnGcoGoodID;
  end getGcoGoodID;

  /**
  * Description
  *   Table function that return a list of propositions that have the good
  *   for finished products in progress
  */
  function GetDocPropInProgress(iGoodId in FAL_DOC_PROP.GCO_GOOD_ID%type)
    return ID_TABLE_TYPE
  is
    lResult ID_TABLE_TYPE;
  begin
    select DOC.FAL_DOC_PROP_ID
    bulk collect into lResult
      from FAL_DOC_PROP DOC
     where DOC.GCO_GOOD_ID = iGoodId;

    return lResult;
  end GetDocPropInProgress;

  /**
  * Description
  *   Return 1 if there is document propositions that refer to the good
  */
  function IsDocPropInProgress(iGoodId in FAL_DOC_PROP.GCO_GOOD_ID%type)
    return number
  is
    lResult pls_integer;
  begin
    select sign(count(*) )
      into lResult
      from table(FAL_LIB_LOT_PROP.GetDocPropInProgress(iGoodId) );

    return lResult;
  end IsDocPropInProgress;

  /**
  * Description
  *   Table function that return a list of propositions that have the good
  *   for finished products in progress
  */
  function GetFPInProgress(iGoodId in FAL_LOT_PROP.GCO_GOOD_ID%type, iVersion in FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type)
    return ID_TABLE_TYPE
  is
    lResult ID_TABLE_TYPE := ID_TABLE_TYPE();
    lIndex  integer       := 1;
  begin
    for ltplProp in (select *
                       from FAL_LOT_PROP LOT
                      where LOT.GCO_GOOD_ID = iGoodId) loop
      declare
        lPiece         FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lSet           FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lVersion       FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lChronological FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lCharStd1      FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lCharStd2      FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lCharStd3      FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lCharStd4      FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
        lCharStd5      FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
      begin
        GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(iCharac1Id       => ltplProp.GCO_CHARACTERIZATION1_ID
                                                           , iCharac2Id       => ltplProp.GCO_CHARACTERIZATION2_ID
                                                           , iCharac3Id       => ltplProp.GCO_CHARACTERIZATION3_ID
                                                           , iCharac4Id       => ltplProp.GCO_CHARACTERIZATION4_ID
                                                           , iCharac5Id       => ltplProp.GCO_CHARACTERIZATION5_ID
                                                           , iCharValue1      => ltplProp.FAD_CHARACTERIZATION_VALUE_1
                                                           , iCharValue2      => ltplProp.FAD_CHARACTERIZATION_VALUE_2
                                                           , iCharValue3      => ltplProp.FAD_CHARACTERIZATION_VALUE_3
                                                           , iCharValue4      => ltplProp.FAD_CHARACTERIZATION_VALUE_4
                                                           , iCharValue5      => ltplProp.FAD_CHARACTERIZATION_VALUE_5
                                                           , oPiece           => lPiece
                                                           , oSet             => lSet
                                                           , oVersion         => lVersion
                                                           , oChronological   => lChronological
                                                           , oCharStd1        => lCharStd1
                                                           , oCharStd2        => lCharStd2
                                                           , oCharStd3        => lCharStd3
                                                           , oCharStd4        => lCharStd4
                                                           , oCharStd5        => lCharStd5
                                                            );

        if    iVersion is null
           or lVersion = iVersion then
          lResult.Extend(1);
          lResult(lIndex)  := ltplProp.FAL_LOT_PROP_ID;
          lIndex           := lIndex + 1;
        end if;
      end;
    end loop;

    return lResult;
  end GetFPInProgress;

  /**
  * Description
  *   Return 1 if there is active orders that have the good/version
  *   for finished products in progress
  */
  function IsFPInProgress(iGoodId in FAL_LOT_PROP.GCO_GOOD_ID%type, iVersion in FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type default null)
    return number
  is
    lResult pls_integer;
  begin
    select sign(count(*) )
      into lResult
      from table(FAL_LIB_LOT_PROP.GetFPInProgress(iGoodId, iVersion) );

    return lResult;
  end IsFPInProgress;

  /**
  * Description
  *   Table function that return a list of active orders that have the good
  *   for components in progress
  */
  function GetCptInProgress(iGoodId in FAL_LOT_MAT_LINK_PROP.GCO_GOOD_ID%type)
    return ID_TABLE_TYPE
  is
    lResult ID_TABLE_TYPE;
  begin
    select LOM.FAL_LOT_MAT_LINK_PROP_ID
    bulk collect into lResult
      from FAL_LOT_MAT_LINK_PROP LOM
     where LOM.GCO_GOOD_ID = iGoodId;

    return lResult;
  end GetCptInProgress;

  /**
  * Description
  *   Return 1 if there is active orders that have the good
  *   for components in progress
  */
  function IsCptInProgress(iGoodId in FAL_LOT_MAT_LINK_PROP.GCO_GOOD_ID%type)
    return number
  is
    lResult pls_integer;
  begin
    select sign(count(*) )
      into lResult
      from table(FAL_LIB_LOT_PROP.GetCptInProgress(iGoodId) );

    return lResult;
  end IsCptInProgress;
end FAL_LIB_LOT_PROP;
