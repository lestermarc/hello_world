--------------------------------------------------------
--  DDL for Package Body ASA_LIB_RECORD_TASK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_LIB_RECORD_TASK" 
is
  /**
  * function TaskExists
  * Description
  *   Indique si le dossier SAV comporte des opérations
  * @author ECA
  * @created 09.2011
  * @lastUpdate
  * @public
  * @param iAsaRecordID : id du dossier SAV
  */
  function TaskExists(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    liNbTasks integer;
  begin
    select count(*)
      into liNbTasks
      from ASA_RECORD are
         , ASA_RECORD_TASK ART
     where are.ASA_RECORD_ID = iAsaRecordID
       and are.ASA_RECORD_ID = ART.ASA_RECORD_ID
       and (   are.ASA_RECORD_EVENTS_ID is null
            or     are.ASA_RECORD_EVENTS_ID is not null
               and are.ASA_RECORD_EVENTS_ID = ART.ASA_RECORD_EVENTS_ID
           );

    return liNbTasks > 0;
  end TaskExists;
end ASA_LIB_RECORD_TASK;
