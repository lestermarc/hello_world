--------------------------------------------------------
--  DDL for Package Body COM_PRC_LIST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_LIST" 
is
  /**
  * procedure InsertIDList
  * Description
  *   Insertion d'un Id dans la table COM_LIST
  *
  */
  procedure InsertIDList(
    aID      in     COM_LIST.LIS_ID_1%type
  , aCode    in     COM_LIST.LIS_CODE%type
  , aDescr   in     COM_LIST.LIS_DESCRIPTION%type
  , aJobID   in out COM_LIST.LIS_JOB_ID%type
  , aSession in out COM_LIST.LIS_SESSION_ID%type
  )
  is
  begin
    if aJobID is null then
      select INIT_TEMP_ID_SEQ.nextval
        into aJobID
        from dual;
    end if;

    if aSession is null then
      select DBMS_SESSION.unique_session_id
        into aSession
        from dual;
    end if;

    insert into COM_LIST
                (COM_LIST_ID
               , LIS_SESSION_ID
               , LIS_JOB_ID
               , LIS_ID_1
               , LIS_CODE
               , LIS_DESCRIPTION
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , aSession
               , aJobID
               , aID
               , aCode
               , aDescr
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end InsertIDList;

  /**
  * procedure DeleteIDList
  * Description
  *   Suppression des ID d'un même code dans la table COM_LIST
  *
  */
  procedure DeleteIDList(
    aJobID   in COM_LIST.LIS_JOB_ID%type
  , aSession in COM_LIST.LIS_SESSION_ID%type
  , aCode    in COM_LIST.LIS_CODE%type
  )
  is
  begin
    if     aCode is not null
       and aSession is not null
       and aJobID is not null then
      delete from COM_LIST
            where LIS_SESSION_ID = aSession
              and LIS_JOB_ID = aJobID
              and LIS_CODE = aCode;
    elsif     aCode is not null
          and aSession is not null
          and aJobID is null then
      delete from COM_LIST
            where LIS_SESSION_ID = aSession
              and LIS_CODE = aCode;
    elsif     aCode is not null
          and aSession is null
          and aJobID is not null then
      delete from COM_LIST
            where LIS_JOB_ID = aJobID
              and LIS_CODE = aCode;
    elsif     aCode is null
          and aSession is null
          and aJobID is not null then
      delete from COM_LIST
            where LIS_JOB_ID = aJobID;
    elsif     aCode is null
          and aSession is not null
          and aJobID is null then
      delete from COM_LIST
            where LIS_SESSION_ID = aSession;
    end if;
  end DeleteIDList;

  /**
  * procedure ClearIDList
  * Description
  *   Suppression des enregistrements qui ne sont pas lié à une session vivante.
  *
  */
  procedure ClearIDList
  is
  begin
    -- Effacement des enregistrements qui ne sont pas lié à une session Oracle active.
    delete from COM_LIST
          where COM_FUNCTIONS.IS_SESSION_ALIVE(LIS_SESSION_ID) = 0;
  end ClearIDList;

  /**
  * procedure DeleteOneIDList
  * Description
  *   Suppression d'un ID dans la table COM_LIST (LIS_ID_1)
  *
  */
  procedure DeleteOneIDList(
    aID      in COM_LIST.LIS_ID_1%type
  , aCode    in COM_LIST.LIS_CODE%type
  , aJobID   in COM_LIST.LIS_JOB_ID%type
  , aSession in COM_LIST.LIS_SESSION_ID%type
  )
  is
  begin
    if     aID is not null
       and aCode is not null
       and aJobID is not null
       and aSession is not null then
      delete from COM_LIST
            where LIS_SESSION_ID = aSession
              and LIS_ID_1 = aID
              and LIS_JOB_ID = aJobID
              and LIS_CODE = aCode;
    end if;
  end DeleteOneIDList;

  /**
  * procedure ClearObsolete
  * Description
  *   Suppression des enregistrements qui ne sont pas lié à une session vivante
  *     et plus vieux de n Jours (a_datecre).
  */
  procedure ClearObsolete(aDays in integer default 1)
  is
  begin
    -- Effacement des enregistrements qui ne sont pas lié à une session Oracle active.
    -- Et qui sont plus vieux que N jours
    delete from COM_LIST
          where COM_FUNCTIONS.IS_SESSION_ALIVE(LIS_SESSION_ID) = 0
            and (    (A_DATECRE is null)
                 or (A_DATECRE <(sysdate - aDays) ) );
  end ClearObsolete;

  /**
  * procedure CountSelected
  * Description
  *   Renvoi le nbr d'éléments sélectionnées présents dans la table COM_LIST
  *
  */
  function CountSelected(
    aJobID   in COM_LIST.LIS_JOB_ID%type
  , aSession in COM_LIST.LIS_SESSION_ID%type
  , aCode    in COM_LIST.LIS_CODE%type
  )
    return number
  is
    vCount integer;
  begin
    select count(*)
      into vCount
      from COM_LIST
     where nvl(LIS_SESSION_ID, '-1') = nvl(aSession, '-1')
       and nvl(LIS_JOB_ID, -1) = nvl(aJobID, -1)
       and nvl(LIS_CODE, '-1') = nvl(aCode, '-1');

    return vCount;
  end CountSelected;
end COM_PRC_LIST;
