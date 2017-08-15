--------------------------------------------------------
--  DDL for Package Body LPM_LIB_VIEW_HRM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_LIB_VIEW_HRM" 
is
/* Source des données de la vue LPM_JOB */
  function jobs
    return tt_job pipelined
  is
    type t_ref_cursor is ref cursor;

    lRc         t_ref_cursor;
    lRecData    t_job;
    lStmtSelect varchar2(4000);
    lStmtUnionUR varchar2(4000);
  begin
    lStmtSelect  :=
      'SELECT HRM_JOB_ID,
              JOB_CODE,
              HRM_IN_CHARGE_ID,
              DIC_DEPARTMENT_ID,
              DIC_JOB_TYPE_ID,
              C_JOB_STATUS,
              JOB_TITLE,
              JOB_DESCR,
              JOB_ACTIVITY,
              JOB_HOME,
              DIC_RESPONSABILITY_ID,
              A_DATECRE,
              A_IDCRE,
              A_DATEMOD,
              A_IDMOD ';
    if pcs.PC_CONFIG.getconfig('LPM_USER_RIGHTS', GetCompanyID, GetConliID) = 1 then
     open lRc for
        select LPM_EMP_EXT_ASSIGNMENT_ID HRM_JOB_ID
             , null
             , null
             , DIV.DIC_DEPARTMENT_ID
             , null
             , null
             , null
             , null
             , null
             , null
             , DIC_RESPONSABILITY_ID
             , EXT.A_DATECRE
             , EXT.A_IDCRE
             , EXT.A_DATEMOD
             , EXT.A_IDMOD
          from LPM_EMP_EXT_ASSIGNMENT EXT
             , HRM_DIVISION DIV
         where EXT.HRM_DIVISION_ID = DIV.HRM_DIVISION_ID;
    else
      if pcs.PC_CONFIG.getconfig('LPM_USER_RIGHTS', GetCompanyID, GetConliID) = 2 then
        lStmtUnionUR  :=
          ' UNION ALL SELECT LPM_EMP_EXT_ASSIGNMENT_ID HRM_JOB_ID
             , null
             , null
             , DIV.DIC_DEPARTMENT_ID
             , null
             , null
             , null
             , null
             , null
             , null
             , DIC_RESPONSABILITY_ID
             , EXT.A_DATECRE
             , EXT.A_IDCRE
             , EXT.A_DATEMOD
             , EXT.A_IDMOD
             FROM LPM_EMP_EXT_ASSIGNMENT EXT
             , HRM_DIVISION DIV
         where EXT.HRM_DIVISION_ID = DIV.HRM_DIVISION_ID';
      end if;

      if pcs.PC_CONFIG.getconfig('LPM_JOB_VIEW', GetCompanyID, GetConliID) is not null then
        open lRc for lStmtSelect || ' FROM ' || pcs.PC_CONFIG.getconfig('LPM_JOB_VIEW', GetCompanyID, GetConliID) || lStmtUnionUR;
      else
        if pcs.PC_CONFIG.getconfig('LPM_DIVISION_MGT', GetCompanyID, GetConliID) <> 'PN' then
          open lRc for lStmtSelect || ' FROM HRM_JOB ' || lStmtUnionUR;
        else
          open lRc for
            ' select Pj.HRM_PERSON_JOB_ID
                 , j.JOB_CODE
                 , j.HRM_IN_CHARGE_ID
                 , PEJ_FREE_03
                 , j.DIC_JOB_TYPE_ID
                 , j.C_JOB_STATUS
                 , j.JOB_TITLE
                 , j.JOB_DESCR
                 , j.JOB_ACTIVITY
                 , j.JOB_HOME
                 , j.DIC_RESPONSABILITY_ID
                 , j.A_DATECRE
                 , j.A_IDCRE
                 , j.A_DATEMOD
                 , j.A_IDMOD
              from HRM_JOB J
                 , hrm_person_job pj
             where j.hrm_job_id = pj.hrm_job_id ' || lStmtUnionUR;
        end if;
      end if;
    end if;

    loop
      fetch lRc
       into lRecData.HRM_JOB_ID
          , lRecData.JOB_CODE
          , lRecData.HRM_IN_CHARGE_ID
          , lRecData.DIC_DEPARTMENT_ID
          , lRecData.DIC_JOB_TYPE_ID
          , lRecData.C_JOB_STATUS
          , lRecData.JOB_TITLE
          , lRecData.JOB_DESCR
          , lRecData.JOB_ACTIVITY
          , lRecData.JOB_HOME
          , lRecData.DIC_RESPONSABILITY_ID
          , lRecData.A_DATECRE
          , lRecData.A_IDCRE
          , lRecData.A_DATEMOD
          , lRecData.A_IDMOD;

      exit when lRc%notfound;
      pipe row(lRecData);
    end loop;

    close lRc;

    return;
  exception
    when NO_DATA_NEEDED then
      return;
  end jobs;

/* Source des données de la vue LPM_ALLOCATION */
  function allocations
    return tt_allocation pipelined
  is
    type t_ref_cursor is ref cursor;

    lRc          t_ref_cursor;
    lRecData     t_allocation;
    lStmtSelect  varchar2(4000);
    lStmtUnionUR varchar2(4000);
  begin
    lStmtSelect  :=
      'SELECT HRM_PERSON_JOB_ID,
          HRM_JOB_ID,
          PEJ_FROM,
          PEJ_AFFECT_RATE,
          PEJ_TO,
          C_HRM_PERSON_JOB_STATUS,
          HRM_TENURED_ID,
          HRM_PERSON_ID,
          0 EXT_ASSIGNMENT ';

    -- On ne veut que les affectations supplémentaires
    if pcs.PC_CONFIG.getconfig('LPM_USER_RIGHTS', GetCompanyID, GetConliID) = 1 then
      open lRc for
        select LPM_EMP_EXT_ASSIGNMENT_ID HRM_PERSON_JOB_ID
             , LPM_EMP_EXT_ASSIGNMENT_ID HRM_JOB_ID
             , LEE_START_DATE PEJ_FROM
             , 0 PEJ_AFFECT_RATE
             , LEE_END_DATE PEJ_TO
             , C_HRM_PERSON_JOB_STATUS
             , HRM_TENURED_ID
             , HRM_PERSON_ID
             , 1
          from LPM_EMP_EXT_ASSIGNMENT;
    else
      if pcs.PC_CONFIG.getconfig('LPM_USER_RIGHTS', GetCompanyID, GetConliID) = 2 then
        lStmtUnionUR  :=
          ' UNION ALL SELECT LPM_EMP_EXT_ASSIGNMENT_ID,
                                  LPM_EMP_EXT_ASSIGNMENT_ID HRM_JOB_ID,
                                  LEE_START_DATE,
                                  0,
                                  LEE_END_DATE,
                                  C_HRM_PERSON_JOB_STATUS,
                                  HRM_TENURED_ID,
                                  HRM_PERSON_ID,
                                  1
                         FROM LPM_EMP_EXT_ASSIGNMENT ';
      end if;

      if pcs.PC_CONFIG.getconfig('LPM_ALLOCATION_VIEW', GetCompanyID, GetConliID) is not null then
        open lRc for lStmtSelect || ' from ' || pcs.PC_CONFIG.getconfig('LPM_ALLOCATION_VIEW', GetCompanyID, GetConliID) || lStmtUnionUR;
      else
        if pcs.PC_CONFIG.getconfig('LPM_DIVISION_MGT', GetCompanyID, GetConliID) <> 'PN' then
          open lRc for lStmtSelect || ' FROM HRM_PERSON_JOB' || lStmtUnionUR;
        else
          open lRc for 'select hrm_person_job_id
                 , hrm_person_job_id
                 , pej_from
                 , pej_affect_rate
                 , pej_to
                 , C_HRM_PERSON_JOB_STATUS
                 , HRM_TENURED_ID
                 , hrm_person_id
                 , 0 EXT_ASSIGNMENT
              from hrm_person_job' ||
                       lStmtUnionUR;
        end if;
      end if;
    end if;

    loop
      fetch lRc
       into lRecData.HRM_PERSON_JOB_ID
          , lRecData.HRM_JOB_ID
          , lRecData.PEJ_FROM
          , lRecData.PEJ_AFFECT_RATE
          , lRecData.PEJ_TO
          , lRecData.C_HRM_PERSON_JOB_STATUS
          , lRecData.HRM_TENURED_ID
          , lRecData.HRM_PERSON_ID
          , lRecData.EXT_ASSIGNMENT;

      exit when lRc%notfound;
      pipe row(lRecData);
    end loop;

    close lRc;

    return;
  exception
    when NO_DATA_NEEDED then
      return;
  end allocations;

  /* Source des données de la vue LPM_DIVISION */
  function divisions
    return tt_division pipelined
  is
    type t_ref_cursor is ref cursor;

    lRc         t_ref_cursor;
    lRecData    t_division;
    lStmtSelect varchar2(4000);
  begin
    lStmtSelect  :=
      'SELECT   HRM_DIVISION_ID
              , DIC_DEPARTMENT_ID
              , DIV_DESCR
              , HRM_IN_CHARGE_ID
              , HRM_DIV_SUPERIOR_ID
              , DIC_DIVISION_TYPE_ID
              , A_DATECRE
              , A_IDCRE
              , A_DATEMOD
              , A_IDMOD ';

    if pcs.PC_CONFIG.getconfig('LPM_DIVISION_VIEW', GetCompanyID, GetConliID) is not null then
      open lRc for lStmtSelect || ' FROM ' || pcs.PC_CONFIG.getconfig('LPM_DIVISION_VIEW', GetCompanyID, GetConliID);
    else
      if pcs.PC_CONFIG.getconfig('LPM_DIVISION_MGT', GetCompanyID, GetConliID) <> 'PN' then
        open lRc for lStmtSelect || ' FROM HRM_DIVISION';
      else
        open lRc for
          select HRM_DIVISION_ID
               , DIC_DEPARTMENT_ID
               , DIV_DESCR
               , HRM_IN_CHARGE_ID
               , HRM_DIV_SUPERIOR_ID
               , DIC_DIVISION_TYPE_ID
               , A_DATECRE
               , A_IDCRE
               , A_DATEMOD
               , A_IDMOD
            from HRM_DIVISION;
      end if;
    end if;

    loop
      fetch lRc
       into lRecData.HRM_DIVISION_ID
          , lRecData.DIC_DEPARTMENT_ID
          , lRecData.DIV_DESCR
          , lRecData.HRM_IN_CHARGE_ID
          , lRecData.HRM_DIV_SUPERIOR_ID
          , lRecData.DIC_DIVISION_TYPE_ID
          , lRecData.A_DATECRE
          , lRecData.A_IDCRE
          , lRecData.A_DATEMOD
          , lRecData.A_IDMOD;

      exit when lRc%notfound;
      pipe row(lRecData);
    end loop;

    close lRc;

    return;
  exception
    when NO_DATA_NEEDED then
      return;
  end divisions;

  /* Source des données de la vue LPM_DIVISION_ATTENDANCE */
  function div_attendances
    return tt_div_attendance pipelined
  is
    type t_ref_cursor is ref cursor;

    lRc         t_ref_cursor;
    lRecData    t_div_attendance;
    lStmtSelect varchar2(4000);
  begin
    if pcs.PC_CONFIG.getconfig('LPM_DIVISION_ATTENDANCE_VIEW', GetCompanyID, GetConliID) is not null then
      lStmtSelect  :=
        'select   HRM_DIVISION_ID
                , DIV_DESCR
                , A_DATECRE
                , A_IDCRE
                , A_DATEMOD
                , A_IDMOD ';

      open lRc for lStmtSelect || ' from ' || pcs.PC_CONFIG.getconfig('LPM_DIVISION_ATTENDANCE_VIEW', GetCompanyID, GetConliID);
    else
      open lRc for lStmtSelect ||
                   ' select  HRM_DIVISION_ID
                , DIV_DESCR
                , LPM_DIVISION.A_DATECRE
                , LPM_DIVISION.A_IDCRE
                , LPM_DIVISION.A_DATEMOD
                , LPM_DIVISION.A_IDMOD
          from LPM_DIVISION
          inner join lpm_job on lpm_job.dic_department_id = lpm_division.dic_department_id
          inner join lpm_allocation on lpm_allocation.hrm_job_id = lpm_job.hrm_job_id
          where lpm_allocation.hrm_person_id = ' ||
                   pcs.PC_I_LIB_SESSION.GetLpmUserId ||
                   '
          and sysdate between lpm_allocation.pej_from and nvl(lpm_allocation.pej_to, sysdate)
        union all
        select LPM_DIVISION.HRM_DIVISION_ID
             , LPM_DIVISION.DIV_DESCR
             , LPM_DIVISION.A_DATECRE
             , LPM_DIVISION.A_IDCRE
             , LPM_DIVISION.A_DATEMOD
             , LPM_DIVISION.A_IDMOD
          from LPM_DIVISION
          inner join lpm_job on lpm_job.dic_department_id = lpm_division.dic_department_id
          inner join lpm_allocation on lpm_allocation.hrm_job_id = lpm_job.hrm_job_id
          where lpm_allocation.hrm_tenured_id = ' ||
                   pcs.PC_I_LIB_SESSION.GetLpmUserId ||
                   '
          and sysdate between lpm_allocation.pej_from and nvl(lpm_allocation.pej_to, sysdate)';
    end if;

    loop
      fetch lRc
       into lRecData.HRM_DIVISION_ID
          , lRecData.DIV_DESCR
          , lRecData.A_DATECRE
          , lRecData.A_IDCRE
          , lRecData.A_DATEMOD
          , lRecData.A_IDMOD;

      exit when lRc%notfound;
      pipe row(lRecData);
    end loop;

    close lRc;

    return;
  exception
    when NO_DATA_NEEDED then
      return;
  end div_attendances;

  function emails
    return tt_email pipelined
  is
    type t_ref_cursor is ref cursor;

    lRc         t_ref_cursor;
    lRecData    t_email;
    lStmtSelect varchar2(4000);
  begin
    lStmtSelect  :=
      'SELECT  HRM_PERSON_ID
                 , PAC_PERSON_ID
                 , SCH_STUDENT_ID
                 , PER_LAST_NAME
                 , PER_FIRST_NAME
                 , EMAIL
                 , TYPEMAIL';

    if pcs.PC_CONFIG.getconfig('LPM_MAIL_DIRECTORY', GetCompanyID, GetConliID) is not null then
      open lRc for lStmtSelect || ' FROM ' || pcs.PC_CONFIG.getconfig('LPM_MAIL_DIRECTORY', GetCompanyID, GetConliID);
    else
      open lRc for
        select LEM.HRM_PERSON_ID
             , null PAC_PERSON_ID
             , null LPM_BENEFICIARY_ID
             , LEM.PER_LAST_NAME
             , LEM.PER_FIRST_NAME
             , LEM.PER_EMAIL as EMAIL
             , 'EMPLOYEE' as TYPEMAIL
          from LPM_EMPLOYEE LEM
         where LEM.PER_EMAIL is not null
        union
        select null HRM_PERSON_ID
             , LAD.PAC_PERSON_ID
             , null LPM_BENEFICIARY_ID
             , LAD.PER_NAME
             , LAD.PER_FORENAME
             , LAD.DCO_EMAIL
             , 'ADDRESS'
          from LPM_ADDRESS LAD
         where LAD.DCO_EMAIL is not null
        union
        select distinct null
                      , null
                      , null
                      , null
                      , null
                      , LEN_MAIL
                      , 'HISTO'
                   from LPM_EVENT_NOTIFICATION LEN
                      , LPM_EVENT EVT
                  where EVT.LPM_EVENT_ID = LEN.LPM_EVENT_ID
                    and LEN.LEN_MAIL is not null;
    end if;

    loop
      fetch lRc
       into lRecData.HRM_PERSON_ID
          , lRecData.PAC_PERSON_ID
          , lRecData.SCH_STUDENT_ID
          , lRecData.PER_LAST_NAME
          , lRecData.PER_FIRST_NAME
          , lRecData.EMAIL
          , lRecData.TYPEMAIL;

      exit when lRc%notfound;
      pipe row(lRecData);
    end loop;

    close lRc;

    return;
  exception
    when NO_DATA_NEEDED then
      return;
  end emails;

  /**
  * function GetCompanyID
  * Description
  *    Fonction permettant de chercher l'id de la compagnie du schémas courant.
  * @author JFR
  * @return  L'ID de la compagnie courante.
  */
  function GetCompanyID
    return integer
  is
    CompanyID number;
  begin
    select pc_comp_id
      into CompanyID
      from pcs.pc_comp
         , pcs.PC_SCRIP
     where PCS.PC_COMP.PC_SCRIP_ID = PCS.PC_SCRIP.PC_SCRIP_ID
       and PC_SCRIP.SCRDBOWNER = sys_context('USERENV', 'CURRENT_SCHEMA');

    return CompanyID;
  end GetCompanyID;

  /**
  * procedure GetConliID
  * Description
  *    Retourn l'id du groupe de config "Default"
  * @author JFR
  * @lastUpdate
  * @return  L'ID du groupe de config "Default"
  */
  function GetConliID
    return integer
  is
    ConliID number;
  begin
    select PC_CONLI_ID
      into ConliID
      from pcs.PC_CONLI
     where CONNAME = 'DEFAULT';

    return ConliID;
  end GetConliID;
end LPM_LIB_VIEW_HRM;
