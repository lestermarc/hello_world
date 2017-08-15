--------------------------------------------------------
--  DDL for Package Body FAL_LIB_FACTORY_FLOOR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_FACTORY_FLOOR" 
is
  /**
  * Description
  *    Retourne l'ID de l'atelier en fonction de sa référence
  */
  function getFactoryFloorIDByRef(ivFacReference in FAL_FACTORY_FLOOR.FAC_REFERENCE%type)
    return FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  as
    lnFalFactoryFloorID FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
  begin
    select FAL_FACTORY_FLOOR_ID
      into lnFalFactoryFloorID
      from FAL_FACTORY_FLOOR
     where upper(FAC_REFERENCE) = upper(ivFacReference);

    return lnFalFactoryFloorID;
  exception
    when no_data_found then
      return null;
  end getFactoryFloorIDByRef;

  /**
  * function GetIsle
  * Description
  *    Retourne l'Id de l'îlot de l'atelier
  *      - Si l'atelier est îlot, retourne son propre Id
  *      - Si l'atelier est machine, retourne l'Id de l'îlot
  *      - Dans les autres cas, retourne null
  */
  function GetIsle(iFactoryFloorId in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type)
    return FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  is
    lnIsBlock         FAL_FACTORY_FLOOR.FAC_IS_BLOCK%type;
    lnIsMachine       FAL_FACTORY_FLOOR.FAC_IS_MACHINE%type;
    lnIsleFactFloorId FAL_FACTORY_FLOOR.FAL_FAL_FACTORY_FLOOR_ID%type;
  begin
    select nvl(FAC_IS_BLOCK, 0)
         , nvl(FAC_IS_MACHINE, 0)
         , FAL_FAL_FACTORY_FLOOR_ID
      into lnIsBlock
         , lnIsMachine
         , lnIsleFactFloorId
      from FAL_FACTORY_FLOOR
     where FAL_FACTORY_FLOOR_ID = iFactoryFloorId;

    if lnIsBlock = 1 then
      return iFactoryFloorId;
    elsif lnIsMachine = 1 then
      return lnIsleFactFloorId;
    else
      return null;
    end if;
  exception
    when no_data_found then
      return null;
  end GetIsle;
end FAL_LIB_FACTORY_FLOOR;
