--------------------------------------------------------
--  DDL for Package Body COM_PRC_CONFIG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_CONFIG" 
is
  /**
  * procedure pLoadObjectConfigAllCompanies
  * Description
  *    Load a config for an object or a basic object and control it for all schemas
  * @created fp/mde 04.05.2010
  * @lastUpdate
  * @public
  * @param iOgeId : object identifier
  */
  procedure pLoadObjectConfigAllCompanies(iOgeId in PCS.PC_OBJECT.PC_OBJECT_ID%type, oConfigsCount out number)
  is
    ltplComList      PCS.COM_LIST_ID_TEMP%rowtype;
    lintIsCompObject integer;
  begin
    ClearComListConfig;
    oConfigsCount  := 0;

    select case
             when coalesce(OBJ.OBJ_TYPE, BOB.OBJ_TYPE) <> 'NOCOMPOEXE' then 1
             else 0
           end
      into lintIsCompObject
      from PCS.PC_BASIC_OBJECT BOB
         , PCS.PC_OBJECT OBJ
     where OBJ.PC_OBJECT_ID = iOgeId
       and BOB.PC_BASIC_OBJECT_ID = OBJ.PC_BASIC_OBJECT_ID;

    for ltplConfig in (select   CBA.PC_CBASE_ID
                              , CBA.CBACNAME
                              , CBA.CBACTYPE
                              , OSC.OSC_SHOW
                              , OSC.OSC_CONTROL
                              , COM.PC_COMP_ID
                              , OBJ.PC_CONLI_ID
                              , COM.COM_NAME
                              , COM.OWNER
                              , CBA.CBACNOTNULL
                           from PCS.PC_CBASE CBA
                              , PCS.PC_OBJECT OBJ
                              , (select SCOM.PC_COMP_ID
                                      , SCOM.COM_NAME
                                      , PCS.PC_FUNCTIONS.GetCompanyOwner(SCOM.COM_NAME) OWNER
                                   from PCS.PC_COMP SCOM
                                      , PCS.PC_OBJECT_COMPANY SOCO
                                  where SCOM.PC_COMP_ID = SOCO.PC_COMP_ID
                                    and SOCO.PC_OBJECT_ID = iOgeId
                                    and lintIsCompObject = 1
                                 union all
                                 select null PC_COMP_ID
                                      , 'PCS' COM_NAME
                                      , 'PCS' OWNER
                                   from dual
                                  where lintIsCompObject = 0) COM
                              , (select OBJ_OSC.PC_CBASE_ID
                                      , OBJ_OSC.OSC_SHOW
                                      , OBJ_OSC.OSC_CONTROL
                                   from PCS.PC_OBJECT_S_CBASE OBJ_OSC
                                  where OBJ_OSC.PC_OBJECT_ID = iOgeId
                                 union all
                                 select BOB_OSC.PC_CBASE_ID
                                      , BOB_OSC.OSC_SHOW
                                      , BOB_OSC.OSC_CONTROL
                                   from PCS.PC_OBJECT BOB_OBJ
                                      , PCS.PC_OBJECT_S_CBASE BOB_OSC
                                  where BOB_OBJ.PC_OBJECT_ID = iOgeId
                                    and BOB_OSC.PC_BASIC_OBJECT_ID = BOB_OBJ.PC_BASIC_OBJECT_ID
                                    and BOB_OSC.PC_CBASE_ID not in(select SUB_OSC.PC_CBASE_ID
                                                                     from PCS.PC_OBJECT_S_CBASE SUB_OSC
                                                                    where SUB_OSC.PC_OBJECT_ID = iOgeId) ) OSC
                          where CBA.PC_CBASE_ID = OSC.PC_CBASE_ID
                            and OBJ.PC_OBJECT_ID = iOgeId
                       order by OWNER) loop
      begin
        ltplComList.COM_LIST_ID_TEMP_ID  := getNewId;
        ltplComList.LID_DESCRIPTION      := 'PC_CBASE_ID';
        ltplComList.LID_FREE_NUMBER_1    := ltplConfig.PC_CBASE_ID;
        ltplComList.LID_FREE_CHAR_1      := ltplConfig.CBACNAME;
        ltplComList.LID_FREE_CHAR_4      := ltplConfig.CBACTYPE;
        ltplComList.LID_FREE_NUMBER_2    := ltplConfig.OSC_SHOW;
        ltplComList.LID_FREE_NUMBER_3    := ltplConfig.OSC_CONTROL;
        ltplComList.LID_FREE_NUMBER_4    := ltplConfig.PC_COMP_ID;
        ltplComList.LID_FREE_NUMBER_5    := ltplConfig.PC_CONLI_ID;
        ltplComList.LID_FREE_CHAR_3      := ltplConfig.COM_NAME;
        ltplComList.LID_FREE_CHAR_2      := ltplConfig.OWNER;
        ltplComList.LID_FREE_MEMO_1      := PCS.PC_CONFIG.GetConfig(ltplConfig.CBACNAME, ltplConfig.PC_COMP_ID, ltplConfig.PC_CONLI_ID);
        ltplComList.LID_ID_5             := ltplConfig.CBACNOTNULL;
        begin
          if ltplConfig.OSC_CONTROL = 1 then
            execute immediate 'begin :LID_CODE := ' ||
                              ltplConfig.OWNER ||
                              '.COM_CONFIG_CONTROL.ControlConfig( :CBACNAME, :LID_FREE_MEMO_1, 0, :OWNER); end;'
                        using out    ltplComList.LID_CODE
                            , in     ltplConfig.CBACNAME
                            , in     ltplComList.LID_FREE_MEMO_1
                            , in     ltplConfig.OWNER;
          end if;
        exception
          when others then
            ltplComList.LID_CODE  := 0;
        end;

        insert into PCS.COM_LIST_ID_TEMP
             values ltplComList;

        oConfigsCount                    := oConfigsCount + 1;
      end;
    end loop;
  end pLoadObjectConfigAllCompanies;

  /**
  * procedure pLoadObjectConfigCurrentComp
  * Description
  *    Load a config for an object or a basic object and control it for the current schema
  * @created fp/mde 04.05.2010
  * @lastUpdate
  * @public
  * @param iOgeId : object identifier
  */
  procedure pLoadObjectConfigCurrentComp(iOgeId in PCS.PC_OBJECT.PC_OBJECT_ID%type, oConfigsCount out number)
  is
    ltplComList PCS.COM_LIST_ID_TEMP%rowtype;
    lCompId     PCS.PC_COMP.PC_COMP_ID%type;
    lCompName   PCS.PC_COMP.COM_NAME%type;
    lCompOwner  PCS.PC_SCRIP.SCRDBOWNER%type;
  begin
    ClearComListConfig;
    oConfigsCount  := 0;

    if PCS.PC_I_LIB_SESSION.GetCompanyId is null then
      lCompId     := null;
      lCompName   := 'PCS';
      lCompOwner  := 'PCS';
    else
      lCompId     := PCS.PC_I_LIB_SESSION.GetCompanyId;
      lCompName   := PCS.PC_I_LIB_SESSION.GetComName;
      lCompOwner  := PCS.PC_I_LIB_SESSION.GetCompanyOwner;
    end if;

    for ltplConfig in (select CBA.PC_CBASE_ID
                            , CBA.CBACNAME
                            , CBA.CBACTYPE
                            , OSC.OSC_SHOW
                            , OSC.OSC_CONTROL
                            , OBJ.PC_CONLI_ID
                            , CBA.CBACNOTNULL
                         from PCS.PC_CBASE CBA
                            , PCS.PC_OBJECT OBJ
                            , (select OBJ_OSC.PC_CBASE_ID
                                    , OBJ_OSC.OSC_SHOW
                                    , OBJ_OSC.OSC_CONTROL
                                 from PCS.PC_OBJECT_S_CBASE OBJ_OSC
                                where OBJ_OSC.PC_OBJECT_ID = iOgeId
                               union all
                               select BOB_OSC.PC_CBASE_ID
                                    , BOB_OSC.OSC_SHOW
                                    , BOB_OSC.OSC_CONTROL
                                 from PCS.PC_OBJECT BOB_OBJ
                                    , PCS.PC_OBJECT_S_CBASE BOB_OSC
                                where BOB_OBJ.PC_OBJECT_ID = iOgeId
                                  and BOB_OSC.PC_BASIC_OBJECT_ID = BOB_OBJ.PC_BASIC_OBJECT_ID
                                  and BOB_OSC.PC_CBASE_ID not in(select SUB_OSC.PC_CBASE_ID
                                                                   from PCS.PC_OBJECT_S_CBASE SUB_OSC
                                                                  where SUB_OSC.PC_OBJECT_ID = iOgeId) ) OSC
                        where CBA.PC_CBASE_ID = OSC.PC_CBASE_ID
                          and OBJ.PC_OBJECT_ID = iOgeId) loop
      begin
        ltplComList.COM_LIST_ID_TEMP_ID  := getNewId;
        ltplComList.LID_DESCRIPTION      := 'PC_CBASE_ID';
        ltplComList.LID_FREE_NUMBER_1    := ltplConfig.PC_CBASE_ID;
        ltplComList.LID_FREE_CHAR_1      := ltplConfig.CBACNAME;
        ltplComList.LID_FREE_CHAR_4      := ltplConfig.CBACTYPE;
        ltplComList.LID_FREE_NUMBER_2    := ltplConfig.OSC_SHOW;
        ltplComList.LID_FREE_NUMBER_3    := ltplConfig.OSC_CONTROL;
        ltplComList.LID_FREE_NUMBER_4    := lCompId;
        ltplComList.LID_FREE_NUMBER_5    := ltplConfig.PC_CONLI_ID;
        ltplComList.LID_FREE_CHAR_3      := lCompName;
        ltplComList.LID_FREE_CHAR_2      := lCompOwner;
        ltplComList.LID_ID_5             := ltplConfig.CBACNOTNULL;
        ltplComList.LID_FREE_MEMO_1      := PCS.PC_CONFIG.GetConfig(ltplConfig.CBACNAME, lCompId, ltplConfig.PC_CONLI_ID);

        if ltplConfig.OSC_CONTROL = 1 then
          ltplComList.LID_CODE  :=
            COM_CONFIG_CONTROL.ControlConfig(ltplConfig.CBACNAME
                                           , ltplComList.LID_FREE_MEMO_1   -- config value
                                           , 0
                                           , lCompOwner
                                            );
        end if;

        insert into PCS.COM_LIST_ID_TEMP
             values ltplComList;

        oConfigsCount                    := oConfigsCount + 1;
      end;
    end loop;
  end pLoadObjectConfigCurrentComp;

  procedure LoadObjectConfig(
    iOgeId             in     PCS.PC_OBJECT.PC_OBJECT_ID%type
  , io_cur_PATH_CONFIG in out tcur_PATH_CONFIG
  , io_cur_ID_SEQ      in out tcur_ID_SEQ
  )
  is
  begin
    -- Contrôle des codes de configuration.
    LoadObjectConfig(iOgeId);

    open io_cur_ID_SEQ
     for
       select LID.LID_FREE_CHAR_1   CBACNAME
            , LID.LID_FREE_MEMO_1   CBACVALUE
            , LID.LID_FREE_CHAR_4   CBACTYPE
            , LID.LID_FREE_NUMBER_3 OSC_CONTROL
         from pcs.COM_LIST_ID_TEMP LID
        where LID.LID_DESCRIPTION = 'PC_CBASE_ID';

    open io_cur_PATH_CONFIG
     for
       select CLT.COM_LIST_ID_TEMP_ID
            , CLT.LID_FREE_CHAR_1   CBACNAME
            , CLT.LID_FREE_MEMO_1   CBACVALUE
            , CLT.LID_FREE_CHAR_4   CBACTYPE
            , CLT.LID_FREE_CHAR_3   COMPANY_NAME
            , CLT.LID_FREE_CHAR_2   COMPANY_OWNER
         from PCS.COM_LIST_ID_TEMP CLT
        where CLT.LID_DESCRIPTION = 'PC_CBASE_ID'
          and CLT.LID_FREE_NUMBER_3 /*OSC_CONTROL*/ = 1
          and CLT.LID_FREE_CHAR_4 /*CBACTYPE*/ = 'DIRECTORY'
          and not (CLT.LID_FREE_MEMO_1 /*CBACVALUE*/ is null and CLT.LID_ID_5 /*CBACNOTNULL*/ = 0);
  end LoadObjectConfig;

  procedure LoadObjectConfig(iOgeId in PCS.PC_OBJECT.PC_OBJECT_ID%type)
  is
  begin
    LoadObjectConfig(iOgeId, 0);
  end LoadObjectConfig;

  procedure LoadObjectConfig(iOgeId in PCS.PC_OBJECT.PC_OBJECT_ID%type, iIsMultiCompanies in number)
  is
    lnConfigCount number;
  begin
    lnConfigCount  := 0;

    if iIsMultiCompanies = 1 then
      pLoadObjectConfigAllCompanies(iOgeId, lnConfigCount);
    else
      pLoadObjectConfigCurrentComp(iOgeId, lnConfigCount);
    end if;
  end LoadObjectConfig;

  procedure LoadObjectConfig(
    iOgeId            in     PCS.PC_OBJECT.PC_OBJECT_ID%type
  , iIsMultiCompanies in     number
  , oConfigsCount     out    number
  )
  is
  begin
    if iIsMultiCompanies = 1 then
      pLoadObjectConfigAllCompanies(iOgeId, oConfigsCount);
    else
      pLoadObjectConfigCurrentComp(iOgeId, oConfigsCount);
    end if;
  end LoadObjectConfig;

  procedure ClearComListConfig
  is
  begin
    delete from PCS.com_list_id_temp
          where lid_description = 'PC_CBASE_ID';
  end ClearComListConfig;
end COM_PRC_CONFIG;
