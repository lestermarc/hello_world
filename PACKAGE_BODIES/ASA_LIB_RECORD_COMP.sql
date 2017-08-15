--------------------------------------------------------
--  DDL for Package Body ASA_LIB_RECORD_COMP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_LIB_RECORD_COMP" 
is
  /**
  * function ComponentExists
  * Description
  *   Indique si le dossier SAV Comporte des composants
  * @author ECA
  * @created 09.2011
  * @lastUpdate
  * @public
  * @param iAsaRecordID : id du dossier SAV
  */
  function ComponentExists(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    liNbComponents integer;
  begin
    select count(*)
      into liNbComponents
      from ASA_RECORD are
         , ASA_RECORD_COMP ARC
     where are.ASA_RECORD_ID = iAsaRecordID
       and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
       and (   are.ASA_RECORD_EVENTS_ID is null
            or     are.ASA_RECORD_EVENTS_ID is not null
               and are.ASA_RECORD_EVENTS_ID = ARC.ASA_RECORD_EVENTS_ID
           );

    return liNbComponents > 0;
  end ComponentExists;
end ASA_LIB_RECORD_COMP;
