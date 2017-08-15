--------------------------------------------------------
--  DDL for Package Body ACS_DEF_ACCOUNT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_DEF_ACCOUNT" 
is
--------------------------------
  function GetDefaultAccountHeader(
    aId                     number
  , aC_DEFAULT_ELEMENT_TYPE ACS_DEFAULT_ACCOUNT.C_DEFAULT_ELEMENT_TYPE%type
  , aC_ADMIN_DOMAIN         ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type
  )
    return ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  is
    cursor DefaultHeaderCursor(
      aC_DEFAULT_ELEMENT_TYPE ACS_DEFAULT_ACCOUNT.C_DEFAULT_ELEMENT_TYPE%type
    , aC_ADMIN_DOMAIN         ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type
    )
    is
      select   ACS_DEFAULT_ACCOUNT_ID
             , DEF_CONDITION
          from ACS_DEFAULT_ACCOUNT
         where C_DEFAULT_ELEMENT_TYPE = aC_DEFAULT_ELEMENT_TYPE
           and (    (C_ADMIN_DOMAIN = aC_ADMIN_DOMAIN)
                or (    C_ADMIN_DOMAIN is null
                    and aC_ADMIN_DOMAIN is null) )
           and DEF_DEFAULT = 0
      order by DEF_DESCR;

    DefaultAccountId ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type;
    SqlCondition     ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type;
    Domain           ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type;
    DefaultSeek      boolean                                           default true;
    ConditionOk      boolean                                           default false;
  begin
    -- 11: Bien (Mouvement de Stock), 12: Bien (Stock)
    if aC_DEFAULT_ELEMENT_TYPE in('11', '12') then
      Domain  := null;
    else
      Domain  := aC_ADMIN_DOMAIN;
    end if;

    open DefaultHeaderCursor(aC_DEFAULT_ELEMENT_TYPE, Domain);

    fetch DefaultHeaderCursor
     into DefaultAccountId
        , SqlCondition;

    while DefaultHeaderCursor%found
     and not ConditionOk loop
      ConditionOk  := ConditionTest(aId, SqlCondition);

      if not ConditionOk then
        fetch DefaultHeaderCursor
         into DefaultAccountId
            , SqlCondition;
      end if;
    end loop;

    close DefaultHeaderCursor;

    DefaultSeek  := not ConditionOk;

    if DefaultSeek then
      begin
        select ACS_DEFAULT_ACCOUNT_ID
          into DefaultAccountId
          from ACS_DEFAULT_ACCOUNT
         where C_DEFAULT_ELEMENT_TYPE = aC_DEFAULT_ELEMENT_TYPE
           and (    (C_ADMIN_DOMAIN = Domain)
                or (    C_ADMIN_DOMAIN is null
                    and Domain is null) )
           and DEF_DEFAULT = 1;
      exception
        when no_data_found then
          DefaultAccountId  := null;
      end;
    end if;

    return DefaultAccountId;
  end GetDefaultAccountHeader;

----------------------------
  procedure GetAccountOfHeader(
    aACS_DEFAULT_ACCOUNT_ID in     ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  , aDate                   in     date
  , aId                     in     number
  , aDefAccounts            in out DefAccountsRecType
  )
  is
  begin
    GetAccountOfHeader(aACS_DEFAULT_ACCOUNT_ID
                     , aDate
                     , aId
                     , aDefAccounts.DEF_FIN_ACCOUNT
                     , aDefAccounts.DEF_DIV_ACCOUNT
                     , aDefAccounts.DEF_CPN_ACCOUNT
                     , aDefAccounts.DEF_CDA_ACCOUNT
                     , aDefAccounts.DEF_PF_ACCOUNT
                     , aDefAccounts.DEF_PJ_ACCOUNT
                     , aDefAccounts.DEF_QTY_ACCOUNT
                     , aDefAccounts.DEF_HRM_PERSON
                     , aDefAccounts.DEF_NUMBER1
                     , aDefAccounts.DEF_NUMBER2
                     , aDefAccounts.DEF_NUMBER3
                     , aDefAccounts.DEF_NUMBER4
                     , aDefAccounts.DEF_NUMBER5
                     , aDefAccounts.DEF_TEXT1
                     , aDefAccounts.DEF_TEXT2
                     , aDefAccounts.DEF_TEXT3
                     , aDefAccounts.DEF_TEXT4
                     , aDefAccounts.DEF_TEXT5
                     , aDefAccounts.DEF_DIC_IMP_FREE1
                     , aDefAccounts.DEF_DIC_IMP_FREE2
                     , aDefAccounts.DEF_DIC_IMP_FREE3
                     , aDefAccounts.DEF_DIC_IMP_FREE4
                     , aDefAccounts.DEF_DIC_IMP_FREE5
                     , aDefAccounts.DEF_DATE1
                     , aDefAccounts.DEF_DATE2
                     , aDefAccounts.DEF_DATE3
                     , aDefAccounts.DEF_DATE4
                     , aDefAccounts.DEF_DATE5
                      );
  end GetAccountOfHeader;

----------------------------
  procedure GetAccountOfHeader(
    aACS_DEFAULT_ACCOUNT_ID in     ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  , aDate                   in     date
  , aId                     in     number
  , aDEF_FIN_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type
  , aDEF_DIV_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type
  , aDEF_CPN_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type
  , aDEF_CDA_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type
  , aDEF_PF_ACCOUNT         in out ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type
  , aDEF_PJ_ACCOUNT         in out ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type
  , aDEF_QTY_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type
  , aDEF_HRM_PERSON         in out ACS_DEF_ACCOUNT_VALUES.DEF_HRM_PERSON%type
  , aDEF_NUMBER1            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER1%type
  , aDEF_NUMBER2            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER2%type
  , aDEF_NUMBER3            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER3%type
  , aDEF_NUMBER4            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER4%type
  , aDEF_NUMBER5            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER5%type
  , aDEF_TEXT1              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT1%type
  , aDEF_TEXT2              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT2%type
  , aDEF_TEXT3              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT3%type
  , aDEF_TEXT4              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT4%type
  , aDEF_TEXT5              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT5%type
  , aDEF_DIC_IMP_FREE1      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE1%type
  , aDEF_DIC_IMP_FREE2      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE2%type
  , aDEF_DIC_IMP_FREE3      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE3%type
  , aDEF_DIC_IMP_FREE4      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE4%type
  , aDEF_DIC_IMP_FREE5      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE5%type
  , aDEF_DATE1              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE1%type
  , aDEF_DATE2              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE2%type
  , aDEF_DATE3              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE3%type
  , aDEF_DATE4              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE4%type
  , aDEF_DATE5              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE5%type
  )
  is
    ACCQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    CPNQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DIVQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    CDAQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    PFQry    ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    PJQry    ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    QTYQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    HRMQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM1Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM2Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM3Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM4Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM5Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT1Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT2Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT3Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT4Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT5Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE1Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE2Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE3Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE4Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE5Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE1Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE2Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE3Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE4Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE5Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NoSql    boolean                             default false;
  -----
  begin
    begin
      select DEF_FIN_ACCOUNT
           , DEF_CPN_ACCOUNT
           , DEF_DIV_ACCOUNT
           , DEF_CDA_ACCOUNT
           , DEF_PF_ACCOUNT
           , DEF_PJ_ACCOUNT
           , DEF_QTY_ACCOUNT
           , DEF_HRM_PERSON
           , DEF_NUMBER1
           , DEF_NUMBER2
           , DEF_NUMBER3
           , DEF_NUMBER4
           , DEF_NUMBER5
           , DEF_TEXT1
           , DEF_TEXT2
           , DEF_TEXT3
           , DEF_TEXT4
           , DEF_TEXT5
           , DEF_DIC_IMP_FREE1
           , DEF_DIC_IMP_FREE2
           , DEF_DIC_IMP_FREE3
           , DEF_DIC_IMP_FREE4
           , DEF_DIC_IMP_FREE5
           , DEF_DATE1
           , DEF_DATE2
           , DEF_DATE3
           , DEF_DATE4
           , DEF_DATE5
           , ACCSQL.MOV_SQL
           , CPNSQL.MOV_SQL
           , DIVSQL.MOV_SQL
           , CDASQL.MOV_SQL
           , PFSQL.MOV_SQL
           , PJSQL.MOV_SQL
           , QTYSQL.MOV_SQL
           , HRMSQL.MOV_SQL
           , NUM1SQL.MOV_SQL
           , NUM2SQL.MOV_SQL
           , NUM3SQL.MOV_SQL
           , NUM4SQL.MOV_SQL
           , NUM5SQL.MOV_SQL
           , TEXT1SQL.MOV_SQL
           , TEXT2SQL.MOV_SQL
           , TEXT3SQL.MOV_SQL
           , TEXT4SQL.MOV_SQL
           , TEXT5SQL.MOV_SQL
           , FREE1SQL.MOV_SQL
           , FREE2SQL.MOV_SQL
           , FREE3SQL.MOV_SQL
           , FREE4SQL.MOV_SQL
           , FREE5SQL.MOV_SQL
           , null
           ,   --DATE1SQL.MOV_SQL,
             null
           ,   --DATE2SQL.MOV_SQL,
             null
           ,   --DATE3SQL.MOV_SQL,
             null
           ,   --DATE4SQL.MOV_SQL,
             null   --DATE5SQL.MOV_SQL
        into aDEF_FIN_ACCOUNT
           , aDEF_CPN_ACCOUNT
           , aDEF_DIV_ACCOUNT
           , aDEF_CDA_ACCOUNT
           , aDEF_PF_ACCOUNT
           , aDEF_PJ_ACCOUNT
           , aDEF_QTY_ACCOUNT
           , aDEF_HRM_PERSON
           , aDEF_NUMBER1
           , aDEF_NUMBER2
           , aDEF_NUMBER3
           , aDEF_NUMBER4
           , aDEF_NUMBER5
           , aDEF_TEXT1
           , aDEF_TEXT2
           , aDEF_TEXT3
           , aDEF_TEXT4
           , aDEF_TEXT5
           , aDEF_DIC_IMP_FREE1
           , aDEF_DIC_IMP_FREE2
           , aDEF_DIC_IMP_FREE3
           , aDEF_DIC_IMP_FREE4
           , aDEF_DIC_IMP_FREE5
           , aDEF_DATE1
           , aDEF_DATE2
           , aDEF_DATE3
           , aDEF_DATE4
           , aDEF_DATE5
           , ACCQry
           , CPNQry
           , DIVQry
           , CDAQry
           , PFQry
           , PJQry
           , QTYQry
           , HRMQry
           , NUM1Qry
           , NUM2Qry
           , NUM3Qry
           , NUM4Qry
           , NUM5Qry
           , TEXT1Qry
           , TEXT2Qry
           , TEXT3Qry
           , TEXT4Qry
           , TEXT5Qry
           , FREE1Qry
           , FREE2Qry
           , FREE3Qry
           , FREE4Qry
           , FREE5Qry
           , DATE1Qry
           , DATE2Qry
           , DATE3Qry
           , DATE4Qry
           , DATE5Qry
        from ACS_DEF_MOVEMENT_SQL FREE5SQL
           , ACS_DEF_MOVEMENT_SQL FREE4SQL
           , ACS_DEF_MOVEMENT_SQL FREE3SQL
           , ACS_DEF_MOVEMENT_SQL FREE2SQL
           , ACS_DEF_MOVEMENT_SQL FREE1SQL
           , ACS_DEF_MOVEMENT_SQL TEXT5SQL
           , ACS_DEF_MOVEMENT_SQL TEXT4SQL
           , ACS_DEF_MOVEMENT_SQL TEXT3SQL
           , ACS_DEF_MOVEMENT_SQL TEXT2SQL
           , ACS_DEF_MOVEMENT_SQL TEXT1SQL
           , ACS_DEF_MOVEMENT_SQL NUM5SQL
           , ACS_DEF_MOVEMENT_SQL NUM4SQL
           , ACS_DEF_MOVEMENT_SQL NUM3SQL
           , ACS_DEF_MOVEMENT_SQL NUM2SQL
           , ACS_DEF_MOVEMENT_SQL NUM1SQL
           , ACS_DEF_MOVEMENT_SQL HRMSQL
           , ACS_DEF_MOVEMENT_SQL ACCSQL
           , ACS_DEF_MOVEMENT_SQL CPNSQL
           , ACS_DEF_MOVEMENT_SQL DIVSQL
           , ACS_DEF_MOVEMENT_SQL CDASQL
           , ACS_DEF_MOVEMENT_SQL PFSQL
           , ACS_DEF_MOVEMENT_SQL PJSQL
           , ACS_DEF_MOVEMENT_SQL QTYSQL
           , ACS_DEF_ACCOUNT_VALUES DEF
       where DEF.ACS_DEFAULT_ACCOUNT_ID = aACS_DEFAULT_ACCOUNT_ID
         and (   aDate >= DEF.DEF_SINCE
              or DEF.DEF_SINCE is null)
         and (   aDate <= DEF.DEF_TO
              or DEF.DEF_TO is null)
         and DEF.ACS_SQL_ACC_ID = ACCSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_SQL_CPN_ID = CPNSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_SQL_DIV_ID = DIVSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_SQL_CDA_ID = CDASQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_SQL_PF_ID = PFSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_SQL_PJ_ID = PJSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_SQL_QTY_ID = QTYSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_HRM_PERSON_SQL_ID = HRMSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_NUMBER1_SQL_ID = NUM1SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_NUMBER2_SQL_ID = NUM2SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_NUMBER3_SQL_ID = NUM3SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_NUMBER4_SQL_ID = NUM4SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_NUMBER5_SQL_ID = NUM5SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_TEXT1_SQL_ID = TEXT1SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_TEXT2_SQL_ID = TEXT2SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_TEXT3_SQL_ID = TEXT3SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_TEXT4_SQL_ID = TEXT4SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_TEXT5_SQL_ID = TEXT5SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_FREE1_SQL_ID = FREE1SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_FREE2_SQL_ID = FREE2SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_FREE3_SQL_ID = FREE3SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_FREE4_SQL_ID = FREE4SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and DEF.ACS_FREE5_SQL_ID = FREE5SQL.ACS_DEF_MOVEMENT_SQL_ID(+);
    exception
      when no_data_found then
        aDEF_FIN_ACCOUNT    := null;
        aDEF_CPN_ACCOUNT    := null;
        aDEF_DIV_ACCOUNT    := null;
        aDEF_CDA_ACCOUNT    := null;
        aDEF_PF_ACCOUNT     := null;
        aDEF_PJ_ACCOUNT     := null;
        aDEF_QTY_ACCOUNT    := null;
        aDEF_HRM_PERSON     := null;
        aDEF_NUMBER1        := null;
        aDEF_NUMBER2        := null;
        aDEF_NUMBER3        := null;
        aDEF_NUMBER4        := null;
        aDEF_NUMBER5        := null;
        aDEF_TEXT1          := null;
        aDEF_TEXT2          := null;
        aDEF_TEXT3          := null;
        aDEF_TEXT4          := null;
        aDEF_TEXT5          := null;
        aDEF_DIC_IMP_FREE1  := null;
        aDEF_DIC_IMP_FREE2  := null;
        aDEF_DIC_IMP_FREE3  := null;
        aDEF_DIC_IMP_FREE4  := null;
        aDEF_DIC_IMP_FREE5  := null;
        aDEF_DATE1          := null;
        aDEF_DATE2          := null;
        aDEF_DATE3          := null;
        aDEF_DATE4          := null;
        aDEF_DATE5          := null;
        NoSql               := true;
    end;

    if not NoSql then
      GetQueryMovement(aId, ACCQry, aDEF_FIN_ACCOUNT);
      GetQueryMovement(aId, CPNQry, aDEF_CPN_ACCOUNT);
      GetQueryMovement(aId, DIVQry, aDEF_DIV_ACCOUNT);
      GetQueryMovement(aId, CDAQry, aDEF_CDA_ACCOUNT);
      GetQueryMovement(aId, PFQry, aDEF_PF_ACCOUNT);
      GetQueryMovement(aId, PJQry, aDEF_PJ_ACCOUNT);
      GetQueryMovement(aId, QTYQry, aDEF_QTY_ACCOUNT);
      GetQueryMovement(aId, HRMQry, aDEF_HRM_PERSON);
      GetQueryMovement(aId, NUM1Qry, aDEF_NUMBER1);
      GetQueryMovement(aId, NUM2Qry, aDEF_NUMBER2);
      GetQueryMovement(aId, NUM3Qry, aDEF_NUMBER3);
      GetQueryMovement(aId, NUM4Qry, aDEF_NUMBER4);
      GetQueryMovement(aId, NUM5Qry, aDEF_NUMBER5);
      GetQueryMovement(aId, TEXT1Qry, aDEF_TEXT1);
      GetQueryMovement(aId, TEXT2Qry, aDEF_TEXT2);
      GetQueryMovement(aId, TEXT3Qry, aDEF_TEXT3);
      GetQueryMovement(aId, TEXT4Qry, aDEF_TEXT4);
      GetQueryMovement(aId, TEXT5Qry, aDEF_TEXT5);
      GetQueryMovement(aId, FREE1Qry, aDEF_DIC_IMP_FREE1);
      GetQueryMovement(aId, FREE2Qry, aDEF_DIC_IMP_FREE2);
      GetQueryMovement(aId, FREE3Qry, aDEF_DIC_IMP_FREE3);
      GetQueryMovement(aId, FREE4Qry, aDEF_DIC_IMP_FREE4);
      GetQueryMovement(aId, FREE5Qry, aDEF_DIC_IMP_FREE5);
      GetQueryMovement(aId, DATE1Qry, aDEF_DATE1);
      GetQueryMovement(aId, DATE2Qry, aDEF_DATE2);
      GetQueryMovement(aId, DATE3Qry, aDEF_DATE3);
      GetQueryMovement(aId, DATE4Qry, aDEF_DATE4);
      GetQueryMovement(aId, DATE5Qry, aDEF_DATE5);
    end if;
  end GetAccountOfHeader;

---------------------------
  procedure GetDefaultAccount(
    aId                     in     number
  , aC_DEFAULT_ELEMENT_TYPE in     ACS_DEFAULT_ACCOUNT.C_DEFAULT_ELEMENT_TYPE%type
  , aC_ADMIN_DOMAIN         in     ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type
  , aDate                   in     date
  , aDEF_FIN_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type
  , aDEF_DIV_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type
  , aDEF_CPN_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type
  , aDEF_CDA_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type
  , aDEF_PF_ACCOUNT         in out ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type
  , aDEF_PJ_ACCOUNT         in out ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type
  , aDEF_QTY_ACCOUNT        in out ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type
  , aDEF_HRM_PERSON         in out ACS_DEF_ACCOUNT_VALUES.DEF_HRM_PERSON%type
  , aDEF_NUMBER1            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER1%type
  , aDEF_NUMBER2            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER2%type
  , aDEF_NUMBER3            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER3%type
  , aDEF_NUMBER4            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER4%type
  , aDEF_NUMBER5            in out ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER5%type
  , aDEF_TEXT1              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT1%type
  , aDEF_TEXT2              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT2%type
  , aDEF_TEXT3              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT3%type
  , aDEF_TEXT4              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT4%type
  , aDEF_TEXT5              in out ACS_DEF_ACCOUNT_VALUES.DEF_TEXT5%type
  , aDEF_DIC_IMP_FREE1      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE1%type
  , aDEF_DIC_IMP_FREE2      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE2%type
  , aDEF_DIC_IMP_FREE3      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE3%type
  , aDEF_DIC_IMP_FREE4      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE4%type
  , aDEF_DIC_IMP_FREE5      in out ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE5%type
  , aDEF_DATE1              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE1%type
  , aDEF_DATE2              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE2%type
  , aDEF_DATE3              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE3%type
  , aDEF_DATE4              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE4%type
  , aDEF_DATE5              in out ACS_DEF_ACCOUNT_VALUES.DEF_DATE5%type
  )
  is
    DefaultAccountId ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type;
  begin
    DefaultAccountId  := GetDefaultAccountHeader(aId, aC_DEFAULT_ELEMENT_TYPE, aC_ADMIN_DOMAIN);

    if DefaultAccountId is not null then
      GetAccountofHeader(DefaultAccountId
                       , aDate
                       , aId
                       , aDEF_FIN_ACCOUNT
                       , aDEF_DIV_ACCOUNT
                       , aDEF_CPN_ACCOUNT
                       , aDEF_CDA_ACCOUNT
                       , aDEF_PF_ACCOUNT
                       , aDEF_PJ_ACCOUNT
                       , aDEF_QTY_ACCOUNT
                       , aDEF_HRM_PERSON
                       , aDEF_NUMBER1
                       , aDEF_NUMBER2
                       , aDEF_NUMBER3
                       , aDEF_NUMBER4
                       , aDEF_NUMBER5
                       , aDEF_TEXT1
                       , aDEF_TEXT2
                       , aDEF_TEXT3
                       , aDEF_TEXT4
                       , aDEF_TEXT5
                       , aDEF_DIC_IMP_FREE1
                       , aDEF_DIC_IMP_FREE2
                       , aDEF_DIC_IMP_FREE3
                       , aDEF_DIC_IMP_FREE4
                       , aDEF_DIC_IMP_FREE5
                       , aDEF_DATE1
                       , aDEF_DATE2
                       , aDEF_DATE3
                       , aDEF_DATE4
                       , aDEF_DATE5
                        );
    end if;
  end GetDefaultAccount;

--------------------------------
  function GetDefAccMovementHeader(
    aActorId                in     number
  , aElementId              in     number
  , aC_ACTOR                in     ACS_DEF_ACC_MOVEMENT.C_ACTOR%type
  , aC_ADMIN_DOMAIN         in     ACS_DEF_ACC_MOVEMENT.C_ADMIN_DOMAIN%type
  , aC_DEFAULT_ELEMENT_TYPE in     ACS_DEF_ACC_MOVEMENT.C_DEFAULT_ELEMENT_TYPE%type
  , aMOV_CUMUL              in out ACS_DEF_ACC_MOVEMENT.MOV_CUMUL%type
  )
    return ACS_DEF_ACC_MOVEMENT.ACS_DEF_ACC_MOVEMENT_ID%type
  is
    cursor DefAccMovementHeaderCursor(
      aC_ACTOR                ACS_DEF_ACC_MOVEMENT.C_ACTOR%type
    , aC_ADMIN_DOMAIN         ACS_DEF_ACC_MOVEMENT.C_ADMIN_DOMAIN%type
    , aC_DEFAULT_ELEMENT_TYPE ACS_DEF_ACC_MOVEMENT.C_DEFAULT_ELEMENT_TYPE%type
    )
    is
      select ACS_DEF_ACC_MOVEMENT_ID
           , MOV_CONDITION
           , MOV_CONDITION_ELEMENT
           , MOV_CUMUL
        from ACS_DEF_ACC_MOVEMENT
       where C_ACTOR = aC_ACTOR
         and (    (C_ADMIN_DOMAIN = aC_ADMIN_DOMAIN)
              or (    aC_ADMIN_DOMAIN is null
                  and C_ADMIN_DOMAIN is null) )
         and (    (C_DEFAULT_ELEMENT_TYPE = aC_DEFAULT_ELEMENT_TYPE)
              or (    aC_DEFAULT_ELEMENT_TYPE is null
                  and C_DEFAULT_ELEMENT_TYPE is null) );

/*
          and ((aC_ADMIN_DOMAIN is not null         and C_ADMIN_DOMAIN = aC_ADMIN_DOMAIN)
            or (aC_ADMIN_DOMAIN is null             and C_ADMIN_DOMAIN is null))
          and ((aC_DEFAULT_ELEMENT_TYPE is not null and C_DEFAULT_ELEMENT_TYPE = aC_DEFAULT_ELEMENT_TYPE)
            or (aC_DEFAULT_ELEMENT_TYPE is null     and C_DEFAULT_ELEMENT_TYPE is null));
*/
    DefAccMovementId    ACS_DEF_ACC_MOVEMENT.ACS_DEF_ACC_MOVEMENT_ID%type;
    SqlActorCondition   ACS_DEF_ACC_MOVEMENT.MOV_CONDITION%type;
    SqlElementCondition ACS_DEF_ACC_MOVEMENT.MOV_CONDITION_ELEMENT%type;
    ConditionOk         boolean                                             default false;
  begin
---------------------------------------------------------------------------------------------------
-- Recherche : Type intervenant, Cond.intervenant, Domaine logistique, Type d'élément, Cond.élément
    open DefAccMovementHeaderCursor(aC_ACTOR, aC_ADMIN_DOMAIN, aC_DEFAULT_ELEMENT_TYPE);

    fetch DefAccMovementHeaderCursor
     into DefAccMovementId
        , SqlActorCondition
        , SqlElementCondition
        , aMOV_CUMUL;

    while DefAccMovementHeaderCursor%found
     and not ConditionOk loop
      ConditionOk  := ConditionTest(aActorId, SqlActorCondition);

      if ConditionOk then
        ConditionOk  := ConditionTest(aElementId, SqlElementCondition);
      end if;

      if not ConditionOk then
        fetch DefAccMovementHeaderCursor
         into DefAccMovementId
            , SqlActorCondition
            , SqlElementCondition
            , aMOV_CUMUL;
      end if;
    end loop;

    close DefAccMovementHeaderCursor;

    if not ConditionOk then
-------------------------------------------------------------------------------------
-- Recherche : Type intervenant, Cond.intervenant, Domaine logistique, Type d'élément
      open DefAccMovementHeaderCursor(aC_ACTOR, aC_ADMIN_DOMAIN, aC_DEFAULT_ELEMENT_TYPE);

      fetch DefAccMovementHeaderCursor
       into DefAccMovementId
          , SqlActorCondition
          , SqlElementCondition
          , aMOV_CUMUL;

      while DefAccMovementHeaderCursor%found
       and not ConditionOk loop
        if SqlElementCondition is null then
          ConditionOk  := ConditionTest(aActorId, SqlActorCondition);
        end if;

        if not ConditionOk then
          fetch DefAccMovementHeaderCursor
           into DefAccMovementId
              , SqlActorCondition
              , SqlElementCondition
              , aMOV_CUMUL;
        end if;
      end loop;

      close DefAccMovementHeaderCursor;
    end if;

    /* Effectue la recherche du déplacement, sans le type d'élement, que dans les
       cas ou le type d'élement est différent de '01' (Imputation comptable).
       Cela oblige donc l'utilisation du type d'élement ('01') pour définir une imputation
       primaire (???) (document logistque par exemple). */
    if     not ConditionOk
       and (aC_DEFAULT_ELEMENT_TYPE <> '01') then
---------------------------------------------------------------------
-- Recherche : Type intervenant, Cond.intervenant, Domaine logistique
      open DefAccMovementHeaderCursor(aC_ACTOR, aC_ADMIN_DOMAIN, null);

      fetch DefAccMovementHeaderCursor
       into DefAccMovementId
          , SqlActorCondition
          , SqlElementCondition
          , aMOV_CUMUL;

      while DefAccMovementHeaderCursor%found
       and not ConditionOk loop
        ConditionOk  := ConditionTest(aActorId, SqlActorCondition);

        if not ConditionOk then
          fetch DefAccMovementHeaderCursor
           into DefAccMovementId
              , SqlActorCondition
              , SqlElementCondition
              , aMOV_CUMUL;
        end if;
      end loop;

      close DefAccMovementHeaderCursor;
    end if;

    /* Effectue la recherche du déplacement, sans le type d'élement, que dans les
       cas ou le type d'élement est différent de '01' (Imputation comptable).
       Cela oblige donc l'utilisation du type d'élement ('01') pour définir une imputation
       primaire (???) (document logistque par exemple). */
    if     not ConditionOk
       and (aC_DEFAULT_ELEMENT_TYPE <> '01') then
-------------------------------------------------
-- Recherche : Type intervenant, Cond.intervenant
      open DefAccMovementHeaderCursor(aC_ACTOR, null, null);

      fetch DefAccMovementHeaderCursor
       into DefAccMovementId
          , SqlActorCondition
          , SqlElementCondition
          , aMOV_CUMUL;

      while DefAccMovementHeaderCursor%found
       and not ConditionOk loop
        ConditionOk  := ConditionTest(aActorId, SqlActorCondition);

        if not ConditionOk then
          fetch DefAccMovementHeaderCursor
           into DefAccMovementId
              , SqlActorCondition
              , SqlElementCondition
              , aMOV_CUMUL;
        end if;
      end loop;

      close DefAccMovementHeaderCursor;
    end if;

    if ConditionOk then
      return DefAccMovementId;
    else
      aMOV_CUMUL  := 0;
      return null;
    end if;
  end GetDefAccMovementHeader;

-----------------------------
  procedure GetMovementOfHeader(
    aACS_DEF_ACC_MOVEMENT_ID in     ACS_DEF_ACC_MOVEMENT.ACS_DEF_ACC_MOVEMENT_ID%type
  , aDate                    in     date
  , aId                      in     number
  , aMOV_ACCOUNT_VALUE       in out ACS_DEF_ACC_MOV_VALUES.MOV_ACCOUNT_VALUE%type
  , aMOV_DIVISION_VALUE      in out ACS_DEF_ACC_MOV_VALUES.MOV_DIVISION_VALUE%type
  , aMOV_CPN_VALUE           in out ACS_DEF_ACC_MOV_VALUES.MOV_CPN_VALUE%type
  , aMOV_CDA_VALUE           in out ACS_DEF_ACC_MOV_VALUES.MOV_CDA_VALUE%type
  , aMOV_PF_VALUE            in out ACS_DEF_ACC_MOV_VALUES.MOV_PF_VALUE%type
  , aMOV_PJ_VALUE            in out ACS_DEF_ACC_MOV_VALUES.MOV_PJ_VALUE%type
  , aMOV_QTY_VALUE           in out ACS_DEF_ACC_MOV_VALUES.MOV_QTY_VALUE%type
  , aMOV_HRM_PERSON          in out ACS_DEF_ACC_MOV_VALUES.MOV_HRM_PERSON%type
  , aMOV_NUMBER1             in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER1%type
  , aMOV_NUMBER2             in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER2%type
  , aMOV_NUMBER3             in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER3%type
  , aMOV_NUMBER4             in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER4%type
  , aMOV_NUMBER5             in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER5%type
  , aMOV_TEXT1               in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT1%type
  , aMOV_TEXT2               in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT2%type
  , aMOV_TEXT3               in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT3%type
  , aMOV_TEXT4               in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT4%type
  , aMOV_TEXT5               in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT5%type
  , aMOV_DIC_IMP_FREE1       in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE1%type
  , aMOV_DIC_IMP_FREE2       in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE2%type
  , aMOV_DIC_IMP_FREE3       in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE3%type
  , aMOV_DIC_IMP_FREE4       in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE4%type
  , aMOV_DIC_IMP_FREE5       in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE5%type
  , aMOV_DATE1               in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER1%type
  , aMOV_DATE2               in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER2%type
  , aMOV_DATE3               in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER3%type
  , aMOV_DATE4               in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER4%type
  , aMOV_DATE5               in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER5%type
  )
  is
    ACCQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    CPNQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DIVQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    CDAQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    PFQry    ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    PJQry    ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    QTYQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    HRMQry   ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM1Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM2Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM3Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM4Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NUM5Qry  ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT1Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT2Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT3Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT4Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    TEXT5Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE1Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE2Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE3Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE4Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    FREE5Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE1Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE2Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE3Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE4Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DATE5Qry ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    NoSql    boolean                             default false;
  begin
    begin
      select MOV_ACCOUNT_VALUE
           , MOV_CPN_VALUE
           , MOV_DIVISION_VALUE
           , MOV_CDA_VALUE
           , MOV_PF_VALUE
           , MOV_PJ_VALUE
           , MOV_QTY_VALUE
           , MOV_HRM_PERSON
           , MOV_NUMBER1
           , MOV_NUMBER2
           , MOV_NUMBER3
           , MOV_NUMBER4
           , MOV_NUMBER5
           , MOV_TEXT1
           , MOV_TEXT2
           , MOV_TEXT3
           , MOV_TEXT4
           , MOV_TEXT5
           , MOV_DIC_IMP_FREE1
           , MOV_DIC_IMP_FREE2
           , MOV_DIC_IMP_FREE3
           , MOV_DIC_IMP_FREE4
           , MOV_DIC_IMP_FREE5
           -- pas de mouvements prévu pour les données complémentaires dates
           , null
           ,   --MOV_DATE1,
             null
           ,   --MOV_DATE2,
             null
           ,   --MOV_DATE3,
             null
           ,   --MOV_DATE4,
             null
           ,   --MOV_DATE5,
             ACCSQL.MOV_SQL
           , CPNSQL.MOV_SQL
           , DIVSQL.MOV_SQL
           , CDASQL.MOV_SQL
           , PFSQL.MOV_SQL
           , PJSQL.MOV_SQL
           , QTYSQL.MOV_SQL
           , HRMSQL.MOV_SQL
           , NUM1SQL.MOV_SQL
           , NUM2SQL.MOV_SQL
           , NUM3SQL.MOV_SQL
           , NUM4SQL.MOV_SQL
           , NUM5SQL.MOV_SQL
           , TEXT1SQL.MOV_SQL
           , TEXT2SQL.MOV_SQL
           , TEXT3SQL.MOV_SQL
           , TEXT4SQL.MOV_SQL
           , TEXT5SQL.MOV_SQL
           , FREE1SQL.MOV_SQL
           , FREE2SQL.MOV_SQL
           , FREE3SQL.MOV_SQL
           , FREE4SQL.MOV_SQL
           , FREE5SQL.MOV_SQL
           -- pas de mouvements prévu pour les données complémentaires dates
           , null
           ,   --DATE1SQL.MOV_SQL,
             null
           ,   --DATE2SQL.MOV_SQL,
             null
           ,   --DATE3SQL.MOV_SQL,
             null
           ,   --DATE4SQL.MOV_SQL,
             null   --DATE5SQL.MOV_SQL,
        into aMOV_ACCOUNT_VALUE
           , aMOV_CPN_VALUE
           , aMOV_DIVISION_VALUE
           , aMOV_CDA_VALUE
           , aMOV_PF_VALUE
           , aMOV_PJ_VALUE
           , aMOV_QTY_VALUE
           , aMOV_HRM_PERSON
           , aMOV_NUMBER1
           , aMOV_NUMBER2
           , aMOV_NUMBER3
           , aMOV_NUMBER4
           , aMOV_NUMBER5
           , aMOV_TEXT1
           , aMOV_TEXT2
           , aMOV_TEXT3
           , aMOV_TEXT4
           , aMOV_TEXT5
           , aMOV_DIC_IMP_FREE1
           , aMOV_DIC_IMP_FREE2
           , aMOV_DIC_IMP_FREE3
           , aMOV_DIC_IMP_FREE4
           , aMOV_DIC_IMP_FREE5
           , aMOV_DATE1
           , aMOV_DATE2
           , aMOV_DATE3
           , aMOV_DATE4
           , aMOV_DATE5
           , ACCQry
           , CPNQry
           , DIVQry
           , CDAQry
           , PFQry
           , PJQry
           , QTYQry
           , HRMQry
           , NUM1Qry
           , NUM2Qry
           , NUM3Qry
           , NUM4Qry
           , NUM5Qry
           , TEXT1Qry
           , TEXT2Qry
           , TEXT3Qry
           , TEXT4Qry
           , TEXT5Qry
           , FREE1Qry
           , FREE2Qry
           , FREE3Qry
           , FREE4Qry
           , FREE5Qry
           , DATE1Qry
           , DATE2Qry
           , DATE3Qry
           , DATE4Qry
           , DATE5Qry
        from ACS_DEF_MOVEMENT_SQL FREE5SQL
           , ACS_DEF_MOVEMENT_SQL FREE4SQL
           , ACS_DEF_MOVEMENT_SQL FREE3SQL
           , ACS_DEF_MOVEMENT_SQL FREE2SQL
           , ACS_DEF_MOVEMENT_SQL FREE1SQL
           , ACS_DEF_MOVEMENT_SQL TEXT5SQL
           , ACS_DEF_MOVEMENT_SQL TEXT4SQL
           , ACS_DEF_MOVEMENT_SQL TEXT3SQL
           , ACS_DEF_MOVEMENT_SQL TEXT2SQL
           , ACS_DEF_MOVEMENT_SQL TEXT1SQL
           , ACS_DEF_MOVEMENT_SQL NUM5SQL
           , ACS_DEF_MOVEMENT_SQL NUM4SQL
           , ACS_DEF_MOVEMENT_SQL NUM3SQL
           , ACS_DEF_MOVEMENT_SQL NUM2SQL
           , ACS_DEF_MOVEMENT_SQL NUM1SQL
           , ACS_DEF_MOVEMENT_SQL HRMSQL
           , ACS_DEF_MOVEMENT_SQL ACCSQL
           , ACS_DEF_MOVEMENT_SQL CPNSQL
           , ACS_DEF_MOVEMENT_SQL DIVSQL
           , ACS_DEF_MOVEMENT_SQL CDASQL
           , ACS_DEF_MOVEMENT_SQL PFSQL
           , ACS_DEF_MOVEMENT_SQL PJSQL
           , ACS_DEF_MOVEMENT_SQL QTYSQL
           , ACS_DEF_ACC_MOV_VALUES MOV
       where ACS_DEF_ACC_MOVEMENT_ID = aACS_DEF_ACC_MOVEMENT_ID
         and (   aDate >= MOV_SINCE
              or MOV_SINCE is null)
         and (   aDate <= MOV_TO
              or MOV_TO is null)
         and ACS_SQL_ACC_ID = ACCSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and ACS_SQL_CPN_ID = CPNSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and ACS_SQL_DIV_ID = DIVSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and ACS_SQL_CDA_ID = CDASQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and ACS_SQL_PF_ID = PFSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and ACS_SQL_PJ_ID = PJSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and ACS_SQL_QTY_ID = QTYSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_HRM_PERSON_SQL_ID = HRMSQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_NUMBER1_SQL_ID = NUM1SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_NUMBER2_SQL_ID = NUM2SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_NUMBER3_SQL_ID = NUM3SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_NUMBER4_SQL_ID = NUM4SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_NUMBER5_SQL_ID = NUM5SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_TEXT1_SQL_ID = TEXT1SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_TEXT2_SQL_ID = TEXT2SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_TEXT3_SQL_ID = TEXT3SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_TEXT4_SQL_ID = TEXT4SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_TEXT5_SQL_ID = TEXT5SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_FREE1_SQL_ID = FREE1SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_FREE2_SQL_ID = FREE2SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_FREE3_SQL_ID = FREE3SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_FREE4_SQL_ID = FREE4SQL.ACS_DEF_MOVEMENT_SQL_ID(+)
         and MOV.ACS_FREE5_SQL_ID = FREE5SQL.ACS_DEF_MOVEMENT_SQL_ID(+);
    exception
      when no_data_found then
        aMOV_ACCOUNT_VALUE   := null;
        aMOV_CPN_VALUE       := null;
        aMOV_DIVISION_VALUE  := null;
        aMOV_CDA_VALUE       := null;
        aMOV_PF_VALUE        := null;
        aMOV_PJ_VALUE        := null;
        aMOV_QTY_VALUE       := null;
        aMOV_HRM_PERSON      := null;
        aMOV_NUMBER1         := null;
        aMOV_NUMBER2         := null;
        aMOV_NUMBER3         := null;
        aMOV_NUMBER4         := null;
        aMOV_NUMBER5         := null;
        aMOV_TEXT1           := null;
        aMOV_TEXT2           := null;
        aMOV_TEXT3           := null;
        aMOV_TEXT4           := null;
        aMOV_TEXT5           := null;
        aMOV_DIC_IMP_FREE1   := null;
        aMOV_DIC_IMP_FREE2   := null;
        aMOV_DIC_IMP_FREE3   := null;
        aMOV_DIC_IMP_FREE4   := null;
        aMOV_DIC_IMP_FREE5   := null;
        aMOV_DATE1           := null;
        aMOV_DATE2           := null;
        aMOV_DATE3           := null;
        aMOV_DATE4           := null;
        aMOV_DATE5           := null;
        NoSql                := true;
    end;

    if not NoSql then
      GetQueryMovement(aId, ACCQry, aMOV_ACCOUNT_VALUE);
      GetQueryMovement(aId, CPNQry, aMOV_CPN_VALUE);
      GetQueryMovement(aId, DIVQry, aMOV_DIVISION_VALUE);
      GetQueryMovement(aId, CDAQry, aMOV_CDA_VALUE);
      GetQueryMovement(aId, PFQry, aMOV_PF_VALUE);
      GetQueryMovement(aId, PJQry, aMOV_PJ_VALUE);
      GetQueryMovement(aId, QTYQry, aMOV_QTY_VALUE);
      GetQueryMovement(aId, HRMQry, aMOV_HRM_PERSON);
      GetQueryMovement(aId, NUM1Qry, aMOV_NUMBER1);
      GetQueryMovement(aId, NUM2Qry, aMOV_NUMBER2);
      GetQueryMovement(aId, NUM3Qry, aMOV_NUMBER3);
      GetQueryMovement(aId, NUM4Qry, aMOV_NUMBER4);
      GetQueryMovement(aId, NUM5Qry, aMOV_NUMBER5);
      GetQueryMovement(aId, TEXT1Qry, aMOV_TEXT1);
      GetQueryMovement(aId, TEXT2Qry, aMOV_TEXT2);
      GetQueryMovement(aId, TEXT3Qry, aMOV_TEXT3);
      GetQueryMovement(aId, TEXT4Qry, aMOV_TEXT4);
      GetQueryMovement(aId, TEXT5Qry, aMOV_TEXT5);
      GetQueryMovement(aId, FREE1Qry, aMOV_DIC_IMP_FREE1);
      GetQueryMovement(aId, FREE2Qry, aMOV_DIC_IMP_FREE2);
      GetQueryMovement(aId, FREE3Qry, aMOV_DIC_IMP_FREE3);
      GetQueryMovement(aId, FREE4Qry, aMOV_DIC_IMP_FREE4);
      GetQueryMovement(aId, FREE5Qry, aMOV_DIC_IMP_FREE5);
      GetQueryMovement(aId, DATE1Qry, aMOV_DATE1);
      GetQueryMovement(aId, DATE2Qry, aMOV_DATE2);
      GetQueryMovement(aId, DATE3Qry, aMOV_DATE3);
      GetQueryMovement(aId, DATE4Qry, aMOV_DATE4);
      GetQueryMovement(aId, DATE5Qry, aMOV_DATE5);
    end if;
  end GetMovementOfHeader;

---------------------------
  procedure GetDefAccMovement(
    aActorId                in     number
  , aElementId              in     number
  , aC_ACTOR                in     ACS_DEF_ACC_MOVEMENT.C_ACTOR%type
  , aC_ADMIN_DOMAIN         in     ACS_DEF_ACC_MOVEMENT.C_ADMIN_DOMAIN%type
  , aC_DEFAULT_ELEMENT_TYPE in     ACS_DEF_ACC_MOVEMENT.C_DEFAULT_ELEMENT_TYPE%type
  , aDate                   in     date
  , aMOV_CUMUL              in out ACS_DEF_ACC_MOVEMENT.MOV_CUMUL%type
  , aMOV_ACCOUNT_VALUE      in out ACS_DEF_ACC_MOV_VALUES.MOV_ACCOUNT_VALUE%type
  , aMOV_DIVISION_VALUE     in out ACS_DEF_ACC_MOV_VALUES.MOV_DIVISION_VALUE%type
  , aMOV_CPN_VALUE          in out ACS_DEF_ACC_MOV_VALUES.MOV_CPN_VALUE%type
  , aMOV_CDA_VALUE          in out ACS_DEF_ACC_MOV_VALUES.MOV_CDA_VALUE%type
  , aMOV_PF_VALUE           in out ACS_DEF_ACC_MOV_VALUES.MOV_PF_VALUE%type
  , aMOV_PJ_VALUE           in out ACS_DEF_ACC_MOV_VALUES.MOV_PJ_VALUE%type
  , aMOV_QTY_VALUE          in out ACS_DEF_ACC_MOV_VALUES.MOV_QTY_VALUE%type
  , aMOV_HRM_PERSON         in out ACS_DEF_ACC_MOV_VALUES.MOV_HRM_PERSON%type
  , aMOV_NUMBER1            in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER1%type
  , aMOV_NUMBER2            in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER2%type
  , aMOV_NUMBER3            in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER3%type
  , aMOV_NUMBER4            in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER4%type
  , aMOV_NUMBER5            in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER5%type
  , aMOV_TEXT1              in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT1%type
  , aMOV_TEXT2              in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT2%type
  , aMOV_TEXT3              in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT3%type
  , aMOV_TEXT4              in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT4%type
  , aMOV_TEXT5              in out ACS_DEF_ACC_MOV_VALUES.MOV_TEXT5%type
  , aMOV_DIC_IMP_FREE1      in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE1%type
  , aMOV_DIC_IMP_FREE2      in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE2%type
  , aMOV_DIC_IMP_FREE3      in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE3%type
  , aMOV_DIC_IMP_FREE4      in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE4%type
  , aMOV_DIC_IMP_FREE5      in out ACS_DEF_ACC_MOV_VALUES.MOV_DIC_IMP_FREE5%type
  , aMOV_DATE1              in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER1%type
  , aMOV_DATE2              in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER2%type
  , aMOV_DATE3              in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER3%type
  , aMOV_DATE4              in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER4%type
  , aMOV_DATE5              in out ACS_DEF_ACC_MOV_VALUES.MOV_NUMBER5%type
  )
  is
    DefAccMovementId ACS_DEF_ACC_MOVEMENT.ACS_DEF_ACC_MOVEMENT_ID%type;
  begin
    DefAccMovementId  := GetDefAccMovementHeader(aActorId, aElementId, aC_ACTOR, aC_ADMIN_DOMAIN, aC_DEFAULT_ELEMENT_TYPE, aMOV_CUMUL);

    if not DefAccMovementId is null then
      GetMovementOfHeader(DefAccMovementId
                        , aDate
                        , aActorId
                        , aMOV_ACCOUNT_VALUE
                        , aMOV_DIVISION_VALUE
                        , aMOV_CPN_VALUE
                        , aMOV_CDA_VALUE
                        , aMOV_PF_VALUE
                        , aMOV_PJ_VALUE
                        , aMOV_QTY_VALUE
                        , aMOV_HRM_PERSON
                        , aMOV_NUMBER1
                        , aMOV_NUMBER2
                        , aMOV_NUMBER3
                        , aMOV_NUMBER4
                        , aMOV_NUMBER5
                        , aMOV_TEXT1
                        , aMOV_TEXT2
                        , aMOV_TEXT3
                        , aMOV_TEXT4
                        , aMOV_TEXT5
                        , aMOV_DIC_IMP_FREE1
                        , aMOV_DIC_IMP_FREE2
                        , aMOV_DIC_IMP_FREE3
                        , aMOV_DIC_IMP_FREE4
                        , aMOV_DIC_IMP_FREE5
                        , aMOV_DATE1
                        , aMOV_DATE2
                        , aMOV_DATE3
                        , aMOV_DATE4
                        , aMOV_DATE5
                         );
    end if;
  end GetDefAccMovement;

--------------------------
  procedure GetQueryMovement(aId in number, aQry in ACS_DEF_MOVEMENT_SQL.MOV_SQL%type, aMovementValue in out ACS_DEF_ACC_MOV_VALUES.MOV_ACCOUNT_VALUE%type)
  is
    SqlCommand    ACS_DEF_MOVEMENT_SQL.MOV_SQL%type;
    DynamicCursor integer;
    ErrorCursor   integer;
    movement      ACS_DEF_ACC_MOV_VALUES.MOV_ACCOUNT_VALUE%type;
  begin
--    raise_application_error(-20000, to_char(aMovementValue));
--    dbms_OutPut.put_line('Value in : ' || to_char(aMovementValue));
    if not aQry is null then
      SqlCommand     := ReplaceParam(aQry, aId);
      --   raise_application_error(-20000, SqlCommand);

      -- Attribution d'un Handle de curseur
      DynamicCursor  := DBMS_SQL.open_cursor;
      -- Vérification de la syntaxe de la commande SQL
      DBMS_SQL.Parse(DynamicCursor, SqlCommand, DBMS_SQL.V7);
      -- Définition des colonnes dont on va stocker les valeurs
      -- Attention : Pour les Varchar, il faut préciser la taille
      DBMS_SQL.Define_column(DynamicCursor, 1, movement, 30);
      -- DBMS_SQL.bind_variable(DynamicCursor, 'C_TYPE_CUMUL', aC_TYPE_CUMUL);

      -- Exécution de la commande SQL
      ErrorCursor    := DBMS_SQL.execute(DynamicCursor);

      -- Obtenir le tuple suivant
      if DBMS_SQL.fetch_rows(DynamicCursor) > 0 then
        DBMS_SQL.column_value(DynamicCursor, 1, movement);
      end if;

      if not movement is null then
        aMovementValue  := movement;
      end if;

      -- Ferme le curseur
      DBMS_SQL.close_cursor(DynamicCursor);
    end if;
  exception
    when others then
      if DBMS_SQL.is_open(DynamicCursor) then
        DBMS_SQL.close_cursor(DynamicCursor);
      end if;
  --   raise;
  end GetQueryMovement;

----------------------
  function ConditionTest(aId number, aDEF_CONDITION ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type)
    return boolean
  is
    SqlCommand    ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type;
    ReturnValue   boolean                                  default false;
    DynamicCursor integer;
    ErrorCursor   integer;
  begin
    begin
      SqlCommand     := ReplaceParam(aDEF_CONDITION, aId);
      --   raise_application_error(-20000, SqlCommand);

      -- Attribution d'un Handle de curseur
      DynamicCursor  := DBMS_SQL.open_cursor;
      -- Vérification de la syntaxe de la commande SQL
      DBMS_SQL.Parse(DynamicCursor, SqlCommand, DBMS_SQL.V7);
      -- Définition des colonnes dont on va stocker les valeurs
      -- Attention : Pour les Varchar, il faut préciser la taille
      -- DBMS_SQL.Define_column(DynamicCursor, 1, Id);

      -- DBMS_SQL.bind_variable(DynamicCursor, 'C_TYPE_CUMUL', aC_TYPE_CUMUL);

      -- Exécution de la commande SQL
      ErrorCursor    := DBMS_SQL.execute(DynamicCursor);
      -- while IdFound = 0 loop

      -- Obtenir le tuple suivant
      ReturnValue    := DBMS_SQL.fetch_rows(DynamicCursor) > 0;
/*        DBMS_SQL.column_Value(DynamicCursor, 1, Id);
          if Id = aId then
            IdFound := 1;
          end if;

        else
          exit;
        end if;

      end loop;

*/    -- Ferme le curseur
      DBMS_SQL.close_cursor(DynamicCursor);
    exception
      when others then
        if DBMS_SQL.is_open(DynamicCursor) then
          DBMS_SQL.close_cursor(DynamicCursor);
        end if;
--      raise;
    end;

    return ReturnValue;
  end ConditionTest;

---------------------
  function ReplaceParam(aSqlCommand ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type, aId number)
    return ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type
  is
    ParamPos     number(4);
    ParamLength1 number(4);
    ParamLength2 number(4);
    ParamLength  number(4);
    Parameter    varchar2(30);
    SqlCommand   ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type;
  begin
    SqlCommand  := aSqlCommand;
    ParamPos    := instr(aSqlCommand, ':');

    if ParamPos > 0 then
      ParamLength1  := instr(substr(aSqlCommand, ParamPos), ' ');
      ParamLength2  := instr(substr(aSqlCommand, ParamPos), chr(10) );

      if     (ParamLength1 > ParamLength2)
         and (ParamLength2 > 0) then
        ParamLength  := ParamLength2;
      elsif     (ParamLength1 > ParamLength2)
            and (ParamLength2 = 0) then
        ParamLength  := ParamLength1;
      elsif     (ParamLength1 < ParamLength2)
            and (ParamLength1 > 0) then
        ParamLength  := ParamLength1;
      elsif     (ParamLength1 < ParamLength2)
            and (ParamLength1 = 0) then
        ParamLength  := ParamLength2;
      else
        ParamLength  := 0;
      end if;

      if ParamLength > 0 then
        Parameter  := replace(replace(substr(aSqlCommand, ParamPos, ParamLength - 1), chr(10), ''), chr(13), '');
      else
        Parameter  := replace(replace(substr(aSqlCommand, ParamPos), chr(10), ''), chr(13), '');
      end if;

      SqlCommand    := replace(aSqlCommand, Parameter, to_char(aId) );
    end if;

    return SqlCommand;
  end ReplaceParam;

  function GetHrmPerson(aEmpNumber in varchar2)
    return number
  is
    vPersonID HRM_PERSON.HRM_PERSON_ID%type;
  begin
    begin
      select HRM_PERSON_ID
        into vPersonID
        from HRM_PERSON
       where PER_IS_EMPLOYEE = 1
         and EMP_NUMBER = AEmpNumber
         and (   EMP_STATUS = 'SUS'
              or EMP_STATUS = 'ACT');
    exception
      when no_data_found then
        vPersonID  := null;
    end;

    return vPersonID;
  end GetHrmPerson;

  procedure GetDefAccountsId(aDefAccounts in DefAccountsRecType, aDefAccountsId in out DefAccountsIdRecType)
  is
  begin
    /**
    * Recherche des id des comptes en fonction du numéro de compte
    */
    aDefAccountsId.DEF_FIN_ACCOUNT_ID  := ACS_FUNCTION.GetFinancialAccountId(aDefAccounts.DEF_FIN_ACCOUNT);
    aDefAccountsId.DEF_DIV_ACCOUNT_ID  := ACS_FUNCTION.GetDivisionAccountId(aDefAccounts.DEF_DIV_ACCOUNT);
    aDefAccountsId.DEF_CPN_ACCOUNT_ID  := ACS_FUNCTION.GetCpnAccountId(aDefAccounts.DEF_CPN_ACCOUNT);
    aDefAccountsId.DEF_CDA_ACCOUNT_ID  := ACS_FUNCTION.GetCdaAccountId(aDefAccounts.DEF_CDA_ACCOUNT);
    aDefAccountsId.DEF_PF_ACCOUNT_ID   := ACS_FUNCTION.GetPfAccountId(aDefAccounts.DEF_PF_ACCOUNT);
    aDefAccountsId.DEF_PJ_ACCOUNT_ID   := ACS_FUNCTION.GetPjAccountId(aDefAccounts.DEF_PJ_ACCOUNT);
    aDefAccountsId.DEF_QTY_ACCOUNT_ID  := ACS_FUNCTION.GetQtyAccountId(aDefAccounts.DEF_QTY_ACCOUNT);
    aDefAccountsId.DEF_HRM_PERSON_ID   := GetHrmPerson(aDefAccounts.DEF_HRM_PERSON);
  end GetDefAccountsId;
end ACS_DEF_ACCOUNT;
