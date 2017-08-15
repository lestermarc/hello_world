--------------------------------------------------------
--  DDL for Package Body STM_MULTI_COMPANY_STOCK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_MULTI_COMPANY_STOCK" 
is
  /**
  * Description
  *   remplissage de la table d'interrogation des stock multi-sociétés
  *   en utilisant les tables tmp dans les schémas
  */
  procedure ExtractData(
    aExtractCommand varchar2
  , aParamValue1    varchar2
  , aParamValue2    varchar2 default null
  , aParamValue3    varchar2 default null
  , aParamValue4    varchar2 default null
  , aParamValue5    varchar2 default null
  )
  is
    cursor crCompanyStockList
    is
      select distinct pc_comp_id
                    , stm_stock_id
                    , stm_location_id
                    , com_name
                    , scrdbowner
                    , scrdb_link
                 from (select pc_comp.pc_comp_id
                            , pc_stock_access.stm_stock_id
                            , pc_stock_access.STM_LOCATION_ID
                            , pc_comp.com_name
                            , pc_scrip.scrdbowner
                            , pc_scrip.scrdb_link
                         from pcs.pc_comp_comp
                            , pcs.pc_comp
                            , pcs.pc_comp_access
                            , pcs.pc_user_comp
                            , pcs.pc_scrip
                            , pcs.pc_stock_access
                        where pc_comp.pc_comp_id = pc_comp_comp.pc_comp_binded_id
                          and pc_comp_comp.pc_comp_comp_id = pc_comp_access.pc_comp_comp_id
                          and pc_comp_access.pc_user_comp_id = pc_user_comp.pc_user_comp_id
                          and pc_scrip.pc_scrip_id = pc_comp.pc_scrip_id
                          and pc_user_comp.pc_user_id = PCS.PC_I_LIB_SESSION.GetUserId   -- 65235
                          and pc_user_comp.pc_comp_id = PCS.PC_I_LIB_SESSION.GetCompanyId   -- 30622
                          and pc_stock_access.pc_comp_access_id(+) = pc_comp_access.pc_comp_access_id
                       union all
                       select pc_comp.pc_comp_id
                            , pc_stock_access.stm_stock_id
                            , pc_stock_access.STM_LOCATION_ID
                            , pc_comp.com_name
                            , pc_scrip.scrdbowner
                            , pc_scrip.scrdb_link
                         from pcs.pc_comp_comp
                            , pcs.pc_comp
                            , pcs.pc_comp_access
                            , pcs.pc_user_comp
                            , pcs.pc_scrip
                            , pcs.pc_user_group
                            , pcs.pc_stock_access
                        where pc_comp.pc_comp_id = pc_comp_comp.pc_comp_binded_id
                          and pc_comp_comp.pc_comp_comp_id = pc_comp_access.pc_comp_comp_id
                          and pc_comp_access.pc_user_comp_id = pc_user_comp.pc_user_comp_id
                          and pc_scrip.pc_scrip_id = pc_comp.pc_scrip_id
                          and pc_user_group.pc_user_id = PCS.PC_I_LIB_SESSION.GetUserId   -- 65235
                          and pc_user_comp.pc_user_id = pc_user_group.use_group_id
                          and pc_user_comp.pc_comp_id = PCS.PC_I_LIB_SESSION.GetCompanyId
                          and pc_stock_access.pc_comp_access_id(+) = pc_comp_access.pc_comp_access_id)   -- 30622
             order by decode(pc_comp_id, PCS.PC_I_LIB_SESSION.GetCompanyId, 0, pc_comp_id) desc
                    , stm_stock_id desc nulls last;

    cursor crRecordsToDelete
    is
      select distinct STI_ORA_SESSION_ID
                 from STM_STOCK_INTERC_TEMP;

    stmStockId             STM_STOCK.STM_STOCK_ID%type;
    stmLocationId          STM_LOCATION.STM_LOCATION_ID%type;
    currentCompId          PCS.PC_COMP.PC_COMP_ID%type;
    lastAllStockCompId     PCS.PC_COMP.PC_COMP_ID%type         default -1;
    currentDBOwner         PCS.PC_SCRIP.SCRDBOWNER%type;
    currentDBLink          PCS.PC_SCRIP.SCRDB_LINK%type;
    dynamicTransfertCursor integer;
    errorTransfertCursor   integer;
    sqlCopyFromExt         varchar2(20000);
    sqlStockListCommand    varchar2(20000);
    dynamicStockListCursor integer;
    errorStockListCursor   integer;
    sqlInsertCommand       varchar2(20000);
    sqlCallExternalInsert  varchar2(20000);
    dynamicInsertCursor    integer;
    errorInsertCursor      integer;
    DBMS_SQL_ERROR         exception;
    pragma exception_init(DBMS_SQL_ERROR, -20100);
  begin
    -- effacement des précédents enregistrements de la session
    for tplCompanyStockList in crCompanyStockList loop
      if tplCompanyStockList.scrdb_link is not null then
        execute immediate 'delete from ' || tplCompanyStockList.scrdbowner || '.STM_STOCK_INTERC_TEMP@' || tplCompanyStockList.scrdb_link;
      else
        execute immediate 'delete from ' || tplCompanyStockList.scrdbowner || '.STM_STOCK_INTERC_TEMP';
      end if;
    end loop;

    -- pour chaque société auxquelles le user a accès
    for tplCompanyStockList in crCompanyStockList loop
      if nvl(currentCompId, -1) <> tplCompanyStockList.pc_comp_id then
        if currentCompId is not null then
          sqlCopyFromExt  := 'begin';

          if currentDBLink is not null then
            sqlCopyFromExt  :=
              sqlCopyFromExt ||
              chr(10) ||
              '  insert into STM_STOCK_INTERC_TEMP (select * from ' ||
              currentDBOwner ||
              '.STM_STOCK_INTERC_TEMP@' ||
              currentDBLink ||
              ');';
            sqlCopyFromExt  := sqlCopyFromExt || chr(10) || '  delete from ' || currentDBOwner || '.STM_STOCK_INTERC_TEMP@' || currentDBLink || ';';
          else
--             declare
--               vNbExt pls_integer;
--             begin
--               execute immediate 'select count(*) from ' || currentDBOwner || '.STM_STOCK_INTERC_TEMP'
--                            into vNbExt;
--
--               DOC_FUNCTIONS.CreateHistoryInformation(null
--                                                    , null   -- DOC_POSITION_ID
--                                                    , tplCompanyStockList.scrdbowner
--                                                    , 'STM_TRSF_CHANGE'   -- DUH_TYPE
--                                                    , 'count(*)'
--                                                    , vNbExt
--                                                    , null   -- status document
--                                                    , null   -- status position
--                                                     );
--             end;
            sqlCopyFromExt  :=
                              sqlCopyFromExt || chr(10) || '  insert into STM_STOCK_INTERC_TEMP (select * from ' || currentDBOwner
                              || '.STM_STOCK_INTERC_TEMP);';
            sqlCopyFromExt  := sqlCopyFromExt || chr(10) || '  delete from ' || currentDBOwner || '.STM_STOCK_INTERC_TEMP;';
          end if;

          sqlCopyFromExt  := sqlCopyFromExt || chr(10) || 'end;';

          begin
            dynamicTransfertCursor  := DBMS_SQL.open_cursor;
            -- Vérification
            DBMS_SQL.parse(dynamicTransfertCursor, sqlCopyFromExt, DBMS_SQL.native);
            DBMS_OUTPUT.put_line(substr(sqlCopyFromExt, 1, 255) );
            -- Execution
            errorTransfertCursor    := DBMS_SQL.execute(dynamicTransfertCursor);
--             DOC_FUNCTIONS.CreateHistoryInformation(null
--                                                  , null   -- DOC_POSITION_ID
--                                                  , tplCompanyStockList.scrdbowner
--                                                  , 'STM_TRSF_CHANGE'   -- DUH_TYPE
--                                                  , 'GetExtData'
--                                                  , sqlCopyFromExt
--                                                  , null   -- status document
--                                                  , null   -- status position
--                                                   );
          exception
            when others then
              raise_application_error(-20000, 'PCS - ' || tplCompanyStockList.COM_NAME || ' - Error in SQL statement ' || sqlCopyFromExt || chr(10) || sqlerrm);
          end;
        end if;
      end if;

      -- Aucun stock attribué -> tous les stocks
      if     tplCompanyStockList.STM_STOCK_ID is null
         and nvl(currentCompId, -1) <> tplCompanyStockList.pc_comp_id then
        lastAllStockCompId   := tplCompanyStockList.pc_comp_id;
        sqlStockListCommand  := PCS.PC_FUNCTIONS.GetSql(aTableName => 'STM_STOCK_INTERC_TEMP', aGroup => 'STOCK_LIST', aSqlId => 'DEFAULT', aHeader => false);

--         DOC_FUNCTIONS.CreateHistoryInformation(null
--                                              , null   -- DOC_POSITION_ID
--                                              , tplCompanyStockList.pc_comp_id || '/' || tplCompanyStockList.COM_NAME
--                                              , 'STM_TRSF_STOCKCMD'   -- DUH_TYPE
--                                              , 'Commande sql des stock'
--                                              , sqlStockListCommand
--                                              , null   -- status document
--                                              , null   -- status position
--                                               );
        if rtrim(sqlStockListCommand) is null then
          raise_application_error(-20000, 'Company ' || tplCompanyStockList.COM_NAME || 'SqlCommand "STM_STOCK_INTERC_TEMP/STOCK_LIST/DEFAULT" inexistante');
        end if;

        CallExternalExtract(aExtractCommand
                          , sqlStockListCommand
                          , stmStockId
                          , stmLocationId
                          , tplCompanyStockList.COM_NAME
                          , tplCompanyStockList.scrdbowner
                          , tplCompanyStockList.scrdb_link
                          , tplCompanyStockList.PC_COMP_ID
                          , aParamValue1
                          , aParamValue2
                          , aParamValue3
                          , aParamValue4
                          , aParamValue5
                           );
      elsif     lastAllStockCompId <> tplCompanyStockList.pc_comp_id
            and tplCompanyStockList.STM_STOCK_ID is not null then
--         DOC_FUNCTIONS.CreateHistoryInformation(null
--                                              , null   -- DOC_POSITION_ID
--                                              , tplCompanyStockList.STM_LOCATION_ID || '/'
--                                                || tplCompanyStockList.COM_NAME
--                                              , 'STM_TRSF_STOCKCMD'   -- DUH_TYPE
--                                              , 'unique stock'
--                                              , tplCompanyStockList.STM_LOCATION_ID
--                                              , null   -- status document
--                                              , null   -- status position
--                                               );
        CallExternalExtract(aExtractCommand
                          , to_char(tplCompanyStockList.STM_LOCATION_ID)
                          , tplCompanyStockList.STM_STOCK_ID
                          , tplCompanyStockList.STM_LOCATION_ID
                          , tplCompanyStockList.COM_NAME
                          , tplCompanyStockList.scrdbowner
                          , tplCompanyStockList.scrdb_link
                          , tplCompanyStockList.PC_COMP_ID
                          , aParamValue1
                          , aParamValue2
                          , aParamValue3
                          , aParamValue4
                          , aParamValue5
                           );
      end if;

      currentCompId   := tplCompanyStockList.pc_comp_id;
      currentDBOwner  := tplCompanyStockList.scrDbOwner;
      currentDBLink   := tplCompanyStockList.scrDb_Link;
    end loop;
  end ExtractData;

  /**
  * Description
  *   Appel de la fonction ExtractLocal dans la société à interroger via DBMS_SQL
  */
  procedure CallExternalExtract(
    aExtractCommand in varchar2
  , aStockCmd       in varchar2
  , aStmStockId     in number
  , aStmLocationId  in number
  , aCOM_NAME       in varchar2
  , aScrdbowner     in varchar2
  , aScrdb_link     in varchar2
  , aCOMP_ID        in number
  , aParamValue1    in varchar2
  , aParamValue2    in varchar2
  , aParamValue3    in varchar2
  , aParamValue4    in varchar2
  , aParamValue5    in varchar2
  )
  is
    csqlInsertCommand     clob;
    tmpChar               varchar2(10000);
    i                     integer         := 0;
    sqlInsertCommand      varchar2(32767);
    sqlCallExternalInsert varchar2(32767);
    dynamicInsertCursor   integer;
    errorInsertCursor     integer;
  begin
    -- Préparation de la commande extraction. Elle sera passée en paramètre à ExtractLocal
    -- et exécutée dans la société interrogée
    cSqlInsertCommand  :=
                PCS.PC_FUNCTIONS.GetSql(aTableName   => 'STM_STOCK_INTERC_TEMP', aGroup => 'STM_INSERT_MULTI_STOCK', aSqlId => aExtractCommand
                                      , aHeader      => false);

    if rtrim(cSqlInsertCommand) is null then
      raise_application_error(-20000
                            , 'Company ' || aCOM_NAME || ' - Command "STM_STOCK_INTERC_TEMP/STM_INSERT_MULTI_STOCK/' || aExtractCommand || '" does not inexist'
                             );
    end if;

    tmpChar            := DBMS_LOB.substr(cSqlInsertCommand, 5000, 1 + i * 5000);

    while tmpChar is not null loop
      sqlInsertCommand  := sqlInsertCommand || tmpChar;
      i                 := i + 1;
      tmpChar           := DBMS_LOB.substr(cSqlInsertCommand, 5000, 1 + i * 5000);
    end loop;

    sqlInsertCommand   := replace(sqlInsertCommand, '[STOCK_LIST]', aStockCmd);
    sqlInsertCommand   := replace(sqlInsertCommand, '[' || 'COMPANY_OWNER]', aScrdbowner);
    sqlInsertCommand   := replace(sqlInsertCommand, '[' || 'CO]', aScrdbowner);
    sqlInsertCommand   := replace(sqlInsertCommand, '[COMPANY_OWNER_2]', aScrdbowner);

    if aScrdb_link is not null then
      sqlInsertCommand  := replace(sqlInsertCommand, '@[COMPANY_DBLINK_2]', '@' || aScrdb_link);
    else
      sqlInsertCommand  := replace(sqlInsertCommand, '@[COMPANY_DBLINK_2]', ' ');
    end if;

    sqlInsertCommand   := replace(sqlInsertCommand, ':PC_COMP_ID', to_char(aCOMP_ID) );
    sqlInsertCommand   := replace(sqlInsertCommand, chr(13), chr(10) );

    -- Préparation et appel et ExtractLocal
    if aScrdb_link is not null then
      sqlCallExternalInsert  :=
        'begin ' ||
        aScrdbowner ||
        '.' ||
        'STM_MULTI_COMPANY_STOCK.ExtractLocal@' ||
        aScrdb_link ||
        '(:AEXTRACTSQL, :ASTOCKID, :ALOCATIONID, :ACOMNAME, :AUNIQUESESSIONID, :APARAMVALUE1, :APARAMVALUE2, :APARAMVALUE3, :APARAMVALUE4, :APARAMVALUE5); end;';
    else
      sqlCallExternalInsert  :=
        'begin ' ||
        aScrdbowner ||
        '.' ||
        'STM_MULTI_COMPANY_STOCK.ExtractLocal(:AEXTRACTSQL, :ASTOCKID, :ALOCATIONID, :ACOMNAME, :AUNIQUESESSIONID, :APARAMVALUE1, :APARAMVALUE2, :APARAMVALUE3, :APARAMVALUE4, :APARAMVALUE5); end;';
    end if;

--     DOC_FUNCTIONS.CreateHistoryInformation(null
--                                          , null   -- DOC_POSITION_ID
--                                          , aScrdbowner   -- no de document
--                                          , 'STM_MULTI_COMPANY'   -- DUH_TYPE
--                                          , 'CallExternalExtract'
--                                          , sqlCallExternalInsert
--                                          , null   -- status document
--                                          , null   -- status position
--                                           );
    begin
--      pcs.writelog(sqlInsertCommand);
      dynamicInsertCursor  := DBMS_SQL.open_cursor;
      -- Vérification
      DBMS_SQL.parse(dynamicInsertCursor, sqlCallExternalInsert, DBMS_SQL.native);
      -- Assignation de variables de la commande
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':AEXTRACTSQL', sqlInsertCommand);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':ASTOCKID', aStmStockId);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':ALOCATIONID', aStmLocationId);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':ACOMNAME', aCOM_NAME);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':AUNIQUESESSIONID', DBMS_SESSION.UNIQUE_SESSION_ID);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':APARAMVALUE1', aParamValue1);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':APARAMVALUE2', aParamValue2);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':APARAMVALUE3', aParamValue3);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':APARAMVALUE4', aParamValue4);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':APARAMVALUE5', aParamValue5);
      -- Execution
      errorInsertCursor    := DBMS_SQL.execute(dynamicInsertCursor);
--     exception
--       when others then
--         raise_application_error(-20000
--                               , 'PCS - Error in SQL statement ' ||
--                                 '"STM_STOCK_INTERC_TEMP/STM_INSERT_MULTI_STOCK/' ||
--                                 aExtractCommand ||
--                                 '"' ||
--                                 chr(10) ||
--                                 sqlerrm
--                                );
    end;

    -- Ferme le curseur
    DBMS_SQL.close_cursor(dynamicInsertCursor);
  end CallExternalExtract;

  /**
  * Description
  *   remplissage de la table d'interrogation des stock multi-sociétés  dans l'instance elle-même
  */
  procedure ExtractLocal(
    aExtractSql      varchar2
  , aStockId         number
  , aLocationId      number
  , aComName         varchar2
  , aUniqueSessionId varchar2
  , aParamValue1     varchar2
  , aParamValue2     varchar2 default null
  , aParamValue3     varchar2 default null
  , aParamValue4     varchar2 default null
  , aParamValue5     varchar2 default null
  )
  is
    sqlStockListCommand    varchar2(20000);
    dynamicStockListCursor integer;
    errorStockListCursor   integer;
    sqlInsertCommand       varchar2(20000);
    dynamicInsertCursor    integer;
    errorInsertCursor      integer;
    DBMS_SQL_ERROR         exception;
    pragma exception_init(DBMS_SQL_ERROR, -20100);
  begin
    begin
      dynamicInsertCursor  := DBMS_SQL.open_cursor;
      -- Vérification
      DBMS_SQL.parse(dynamicInsertCursor, aExtractSql, DBMS_SQL.native);
      -- Assignation des variables
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':COM_NAME', aComName);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':UNIQUE_SESSION_ID', aUniqueSessionId);
      DBMS_SQL.bind_variable(dynamicInsertCursor, ':PARAM_VALUE_1', aParamValue1);

      if instr(aExtractSql, ':PARAM_VALUE_2') > 0 then
        DBMS_SQL.bind_variable(dynamicInsertCursor, ':PARAM_VALUE_2', aParamValue2);
      end if;

      if instr(aExtractSql, ':PARAM_VALUE_3') > 0 then
        DBMS_SQL.bind_variable(dynamicInsertCursor, ':PARAM_VALUE_3', aParamValue3);
      end if;

      if instr(aExtractSql, ':PARAM_VALUE_4') > 0 then
        DBMS_SQL.bind_variable(dynamicInsertCursor, ':PARAM_VALUE_4', aParamValue4);
      end if;

      if instr(aExtractSql, ':PARAM_VALUE_5') > 0 then
        DBMS_SQL.bind_variable(dynamicInsertCursor, ':PARAM_VALUE_5', aParamValue5);
      end if;

      -- Execution
      errorInsertCursor    := DBMS_SQL.execute(dynamicInsertCursor);
    exception
      when others then
        raise_application_error(-20003, 'PCS - ' || length(aExtractSql) || sqlerrm || DBMS_UTILITY.format_error_backtrace);
    --raise_application_error(-20003, 'PCS - Error in SQL statement ' || substr(aExtractSql,-200,200) );
    end;

    -- Ferme le curseur
    DBMS_SQL.close_cursor(dynamicInsertCursor);
  end ExtractLocal;
end STM_MULTI_COMPANY_STOCK;
