--------------------------------------------------------
--  DDL for Package Body PAC_DEPARTMENT_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_DEPARTMENT_MANAGEMENT" 
is
  /**
  * Description
  *   recherche de l'adresse principale
  */
  function GetMainAddress(pPAC_PERSON_ID PAC_DEPARTMENT.PAC_PERSON_ID%type)
            return PAC_ADDRESS.PAC_ADDRESS_ID%type
  is
    vResult PAC_ADDRESS.PAC_ADDRESS_ID%type;
  begin
    select nvl(max(ADR.PAC_ADDRESS_ID), 0)
    into   vResult
    from   PAC_ADDRESS ADR
    where  ADR.PAC_PERSON_ID = pPAC_PERSON_ID and
           ADR.ADD_PRINCIPAL = 1;
    return vResult;
  end GetMainAddress;

  /**
  * Description
  *   recherche du dico des départements par défaut
  */
  function GetDefaultDepartmentDic return DIC_PAC_DEPARTMENT.DIC_PAC_DEPARTMENT_ID%type
  is
    vResult DIC_PAC_DEPARTMENT.DIC_PAC_DEPARTMENT_ID%type;
  begin
    select max(DPD.DIC_PAC_DEPARTMENT_ID)
    into   vResult
    from   DIC_PAC_DEPARTMENT DPD
    where  DPD.DPD_DEFAULT = 1;
    return vResult;
  end GetDefaultDepartmentDic;

  /**
  * Description
  *   recherche de l'horaire par défaut
  */
  function GetDefaultSchedule return PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  is
    vResult PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    select nvl(max(SCE.PAC_SCHEDULE_ID), 0)
    into   vResult
    from   PAC_SCHEDULE SCE
    where  SCE.SCE_DEFAULT = 1;
    return vResult;
  end GetDefaultSchedule;

  /**
  * Description
  *   recherche des valeurs par défaut pour un département
  */
  procedure GetDefaultDepartmentVals(pPAC_PERSON_ID             PAC_PERSON.PAC_PERSON_ID%type,
                                     pPAC_ADDRESS_ID        out PAC_ADDRESS.PAC_ADDRESS_ID%type,
                                     pDIC_PAC_DEPARTMENT_ID out DIC_PAC_DEPARTMENT.DIC_PAC_DEPARTMENT_ID%type,
                                     pPAC_SCHEDULE_ID       out PAC_SCHEDULE.PAC_SCHEDULE_ID%type)
  is
  begin
    pPAC_ADDRESS_ID         := GetMainAddress(pPAC_PERSON_ID);
    pDIC_PAC_DEPARTMENT_ID  := GetDefaultDepartmentDic;
    pPAC_SCHEDULE_ID        := GetDefaultSchedule;
  end GetDefaultDepartmentVals;

  /**
  * Description
  *   création d'un nouveau département
  */
  procedure CreatePersonDpt(pPAC_PERSON_ID             PAC_DEPARTMENT.PAC_PERSON_ID%type,
                            pPAC_ADDRESS_ID            PAC_DEPARTMENT.PAC_ADDRESS_ID%type,
                            pPAC_SCHEDULE_ID           PAC_DEPARTMENT.PAC_SCHEDULE_ID%type,
                            pDIC_PAC_DEPARTMENT_ID     PAC_DEPARTMENT.DIC_PAC_DEPARTMENT_ID%type,
                            pPAC_DEPARTMENT_ID     out PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type)
  is
    vPAC_DEPARTMENT_ID      PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type;
    vPAC_SCHEDULE_ID        PAC_DEPARTMENT.PAC_SCHEDULE_ID%type;
    vPAC_ADDRESS_ID         PAC_DEPARTMENT.PAC_ADDRESS_ID%type;
    vDIC_PAC_DEPARTMENT_ID  PAC_DEPARTMENT.DIC_PAC_DEPARTMENT_ID%type;
  begin
    vPAC_DEPARTMENT_ID := 0;
    --Recherche de l'adresse par défaut obligatoire
    vPAC_ADDRESS_ID := pPAC_ADDRESS_ID;
    if (vPAC_ADDRESS_ID is null) or (vPAC_ADDRESS_ID < 1) then
      vPAC_ADDRESS_ID := GetMainAddress(pPAC_PERSON_ID);
    end if;
    if (vPAC_ADDRESS_ID is not null) and (vPAC_ADDRESS_ID > 0) and
       (pPAC_PERSON_ID is not null)  and (pPAC_PERSON_ID > 0) then
      --Recherche du dico par défaut
      vDIC_PAC_DEPARTMENT_ID := pDIC_PAC_DEPARTMENT_ID;
      if vDIC_PAC_DEPARTMENT_ID is null then
        vDIC_PAC_DEPARTMENT_ID := GetDefaultDepartmentDic;
      end if;
      --Recherche du calendrier par défaut
      vPAC_SCHEDULE_ID := pPAC_SCHEDULE_ID;
      if (vPAC_SCHEDULE_ID is null) or (vPAC_SCHEDULE_ID < 1) then
        vPAC_SCHEDULE_ID := GetDefaultSchedule;
      end if;
      --identifiant pour l'ajout dans PAC_DEPARTMENT
      select init_id_seq.nextval
      into   vPAC_DEPARTMENT_ID
      from   DUAL;
      insert into PAC_DEPARTMENT(
        PAC_DEPARTMENT_ID,
        PAC_PERSON_ID,
        PAC_ADDRESS_ID,
        PAC_SCHEDULE_ID,
        DIC_PAC_DEPARTMENT_ID,
        A_DATECRE,
        A_IDCRE)
      values(
        vPAC_DEPARTMENT_ID,
        pPAC_PERSON_ID,                                            -- Personne
        vPAC_ADDRESS_ID,                                           -- Adresse par defaut si paramètre null
        decode(vPAC_SCHEDULE_ID, 0, null, vPAC_SCHEDULE_ID),       -- Calendrier par defaut si paramètre null
        vDIC_PAC_DEPARTMENT_ID,                                    -- Dico par défaut si paramètre null
        sysdate,
        PCS.PC_I_LIB_SESSION.GetUserIni);
    end if;
    pPAC_DEPARTMENT_ID := vPAC_DEPARTMENT_ID;
  end CreatePersonDpt;

  /**
  * Description
  *   Retourne 1 s'il existe d'autre clé à null que celle du département passé en paramètre
  */
  function ExistOtherNullKey(pPAC_PERSON_ID      PAC_DEPARTMENT.PAC_PERSON_ID%type,
                             pPAC_DEPARTMENT_ID  PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type)
           return number
  is
    vResult number(1);
  begin
    select decode(count(1), 0, 0, 1)
    into   vResult
    from   PAC_DEPARTMENT DEP
    where  DEP.PAC_DEPARTMENT_ID <> pPAC_DEPARTMENT_ID and
           DEP.PAC_PERSON_ID      = pPAC_PERSON_ID and
           DEP.DEP_KEY           IS NULL;
    return vResult;
  end ExistOtherNullKey;

end PAC_DEPARTMENT_MANAGEMENT;
