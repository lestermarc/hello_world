--------------------------------------------------------
--  DDL for Package Body FAL_TRACABILITY_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_TRACABILITY_FCT" 
is
  -- ID unique de la session utilisé dans toutes les procédures de (dé)réservation
  cSessionId constant FAL_PROCESS_TRAC_PRNT.FPT_SESSION_ID%type   := DBMS_SESSION.unique_session_id;

  /**
  * Procedure IsUsedElementNumber
  * Description
  *   Indique si un élement de tracabilité donné est utilisé dans des tables.
  * @author ECA
  * @public
  * @param   aSTM_ELEMENT_NUMBER_ID : Valeur de caractérisation
  * @return  0 ou 1
  */
  function IsUsedElementNumber(aSTM_ELEMENT_NUMBER_ID number)
    return integer
  is
    cursor crTablesWithElementNumber(aOwner varchar2)
    is
      select distinct TABLE_NAME
                    , ATC.COLUMN_NAME
                 from sys.ALL_TAB_COLUMNS ATC
                where ATC.COLUMN_NAME like 'STM%ELEMENT%NUMBER%ID'
                  and ATC.OWNER = AOWNER
                  and TABLE_NAME <> 'STM_ELEMENT_NUMBER'
                  and TABLE_NAME not like 'MV_%'
                  and TABLE_NAME not like 'V_%';

    strUserName       varchar2(2000);
    strSearchExisting varchar2(2000);
    NbUsed            integer;
  begin
    NbUsed  := 0;

--     begin
--       select scrdbowner
--         into strUserName
--         from pcs.pc_scrip
--        where pc_scrip_id = (select PC_SCRIP_ID
--                               from PCS.PC_COMP
--                              where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId);
--     exception
--       when no_data_found then
--         strUserName  := user;
--     end;
--
--     -- Pour chaque table du shéma en cours, contenant le champs STM_ELEMENT_NUMBER_ID.
--     for tplTablesWithElementNumber in crTablesWithElementNumber(strUserName) loop
--       begin
--         strSearchExisting  :=
--           ' select count(*) NbElementNumber ' ||
--           '   from ' || tplTablesWithElementNumber.TABLE_NAME ||
--           '  where ' || tplTablesWithElementNumber.COLUMN_NAME || ' = :STM_ELEMENT_NUMBER_ID';
--
--         execute immediate strSearchExisting
--                      into NbUsed
--                     using aSTM_ELEMENT_NUMBER_ID;
--       exception
--         when others then
--           nbUsed  := 0;
--       end;
--
--       if NbUsed > 0 then
--         exit;
--       end if;
--     end loop;
    if NbUsed > 0 then
      return 1;
    else
      return 0;
    end if;
  end;

  /**
  * function DelObsoleteTracaPrint
  * Description : Suppression des enregistrements obsolètes de la table d'impression traçabilité
  * @created CLG
  * @lastUpdate
  * @public
  */
  procedure DelObsoleteTracaPrint
  is
    pragma autonomous_transaction;

    cursor crOracleSession
    is
      select distinct FPT_SESSION_ID
                 from FAL_PROCESS_TRAC_PRNT;
  begin
    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.FPT_SESSION_ID) = 0 then
        delete from FAL_PROCESS_TRAC_PRNT
              where FPT_SESSION_ID = tplOracleSession.FPT_SESSION_ID;
      end if;
    end loop;

    commit;
  end;

  /**
  * procedure : DelReservedTracaPrint
  * Description : Suppression de toutes les réservations faites pour la session en cours
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   iSessionId    Session Oracle qui a fait la réservation
  */
  procedure DelReservedTracaPrint(iSessionId in FAL_PROCESS_TRAC_PRNT.FPT_SESSION_ID%type default null)
  is
    pragma autonomous_transaction;
  begin
    delete from FAL_PROCESS_TRAC_PRNT
          where FPT_SESSION_ID = nvl(iSessionId, cSessionId);

    commit;
    DelObsoleteTracaPrint;
  end;
end FAL_TRACABILITY_FCT;
