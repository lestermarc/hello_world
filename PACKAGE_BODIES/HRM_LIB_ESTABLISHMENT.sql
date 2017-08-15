--------------------------------------------------------
--  DDL for Package Body HRM_LIB_ESTABLISHMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_LIB_ESTABLISHMENT" 
as
  /**
  * function ZipBelongsToOFSCity
  * description :
  *    Détermine si un code postal appartient à une commune OFS donnée.
  */
  function ZipBelongsToOFSCity(iZip in HRM_ESTABLISHMENT.EST_ZIP%type, iPcOFSCityID in HRM_ESTABLISHMENT.PC_OFS_CITY_ID%type)
    return integer
  is
    ln_result integer;
  begin
    select sign(count(*) )
      into ln_result
      from PCS.PC_OFS_CITY OFS
     where OFS.PC_OFS_CITY_ID = iPcOFSCityID
       and ',' || trim(OFS.OFS_RELATED_ZIP) || ',' like '%,' || trim(iZip) || ',%';

    return ln_result;
  end ZipBelongsToOFSCity;

  /**
   *  Procédure GetEstablishmentHours
   */
  procedure GetEstablishmentHours(
    iHRM_IN_OUT_ID    in     HRM_IN_OUT.HRM_IN_OUT_ID%type
  , oEST_HOURS_WEEK   out    HRM_ESTABLISHMENT.EST_HOURS_WEEK%type
  , oEST_LESSONS_WEEK out    HRM_ESTABLISHMENT.EST_LESSONS_WEEK%type
  )
  is
  begin
    select nvl(max(EST_HOURS_WEEK), 0)
         , nvl(max(EST_LESSONS_WEEK), 0)
      into oEST_HOURS_WEEK
         , oEST_LESSONS_WEEK
      from HRM_ESTABLISHMENT EST
         , HRM_IN_OUT INO
     where INO.HRM_IN_OUT_ID = iHRM_IN_OUT_ID
       and EST.HRM_ESTABLISHMENT_ID = INO.HRM_ESTABLISHMENT_ID;
  end GetEstablishmentHours;
end HRM_LIB_ESTABLISHMENT;
