--------------------------------------------------------
--  DDL for Package Body SCH_PRC_STUDENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_PRC_STUDENT" 
is
  /**
  * procedure RecalculatePositions
  * Description : Recalcule les positions de la liste d'attente des admission
  *
  * @created JFR
  * @lastUpdate 24.04.2013
  * @public
  * @param iDivisionOld : Ancienne division
  * @param iDivisionNew : Nouvelle division
  * @param iWaitingListID : id de la liste d'attente
  */
  procedure RecalculatePositions(iDivisionOld in number, iDivisionNew in number, iWaitingListID in number)
  is
    iCpt          integer;
    iPositionBase integer;
    iWaitingList  integer;
  begin
     iCpt  := 1;

    if iWaitingListID <> 0 then
      select SWL_POSITION, SWL_ACTIVE
      into iPositionBase, iWaitingList
      from SCH_WAITING_LIST
      where SCH_WAITING_LIST_ID = iWaitingListID;
    end if;

    -- Liste de la liste d'attente pour l'ancienne division
    for ltplPos in (select   WLI.SCH_WAITING_LIST_ID
                        from SCH_WAITING_LIST WLI
                       where WLI.SWL_ACTIVE = 1
                         and WLI.HRM_DIVISION_ID = iDivisionOld
                         and (SCH_WAITING_LIST_ID <> iWaitingListID OR SWL_POSITION IS NULL)
                    order by WLI.SWL_POSITION) loop
      if iPositionBase = iCpt and iWaitingList = 1 then
        iCpt  := iCpt + 1;
      end if;

      update SCH_WAITING_LIST
         set SWL_POSITION = iCpt
       where SCH_WAITING_LIST_ID = ltplPos.SCH_WAITING_LIST_ID;

      iCpt  := iCpt + 1;
    end loop;

    iCpt  := 1;

    -- Liste de la liste d'attente pour la nouvelle division
    for ltplPos in (select   WLI.SCH_WAITING_LIST_ID
                        from SCH_WAITING_LIST WLI
                       where WLI.SWL_ACTIVE = 1
                         and WLI.HRM_DIVISION_ID = iDivisionNew
                         and (SCH_WAITING_LIST_ID <> iWaitingListID OR SWL_POSITION IS NULL)
                    order by WLI.SWL_POSITION) loop

      if iPositionBase = iCpt and iWaitingList = 1 then
        iCpt  := iCpt + 1;
      end if;

      update SCH_WAITING_LIST
         set SWL_POSITION = iCpt
       where SCH_WAITING_LIST_ID = ltplPos.SCH_WAITING_LIST_ID;

      iCpt  := iCpt + 1;
    end loop;

  end RecalculatePositions;

  /**
  * function CheckDivisionCapacity
  * Description : Vérifie si la capacité de la division n'est pas dépassée
  *
  * @created JFR
  * @lastUpdate 01.05.2013
  * @public
  * @param iDivisionCapacityID : ID de la capacity de division
  * @param iCapacityNew : Capacité
  * @param iAllowExceedingNew : Dépassement autorisé
  * @return 0 : Pas de problème, peut être modifié
  *         1 : Peut être modifié, mais avec un message d'avertissement (pour le dépassement de la capacité)
  *         2 : Impossible d'être modifié, la charge a dépassé la capacité
  */
  function CheckDivisionCapacity(iDivisionCapacityID in number, iCapacityNew in number, iAllowExceedingNew in number)
    return Integer
  is
    iWorload        integer;
    iDivision       number;
    iCapacity       integer;
    iAllowExceeding integer;
    iCapacityType   varchar(30);
  begin
    select HRM_DIVISION_ID, LDC_CAPACITY, LDC_ALLOW_EXCEEDING, NVL(DIC_LPM_CAPACITY_TYPE_ID,'empty')
    into iDivision, iCapacity, iAllowExceeding, iCapacityType
    from lpm_division_capacity
    where lpm_division_capacity_id = iDivisionCapacityID;

    select count(*)
    into iWorload
    from lpm_referents
    where hrm_division_id = iDivision
      and ((iCapacityType = 'empty' and dic_lpm_capacity_type_id is null)
       or (iCapacityType <> 'empty' and dic_lpm_capacity_type_id = iCapacityType))
    and sysdate between nvl(lre_start_date, sysdate) and nvl(lre_end_date, sysdate);

    if iCapacity > iCapacityNew or iAllowExceedingNew <> iAllowExceeding then
      if iWorload > iCapacityNew then
        if iAllowExceedingNew = 0 then
          return 2;
        else
          return 1;
        end if;
      else
        return 0;
      end if;
    else
      return 0;
    end if;

  end CheckDivisionCapacity;

  /**
  * function CheckWorkloadBelongings
  * Description : Vérifie si la charge de dépasse pas la capacité capacité de la division
  *
  * @created JFR
  * @lastUpdate 04.06.2013
  * @public
  * @param iDivisionID : ID de la division de l'appartenance
  * @param iCapacityType : Type de la capacité de l'appartenance
  * @return 0 : Pas de problème, peut être modifié
  *         1 : Peut être modifié, mais avec un message d'avertissement (pour le dépassement de la capacité)
  *         2 : Impossible d'être modifié, la charge a dépassé la capacité
  */
  function CheckWorkloadBelongings(iDivisionIDNew in number, iCapacityTypeNew in string, iReferentID in number,
                                    iStartDate in Date, iEndDate in Date, iWorkloadNew in number)
    return Integer
  is
    iCapacity     integer;
    iWorkload     integer;
    iAllowExceeding integer;
    isNew         boolean;
  begin

    select LDC_CAPACITY, LDC_ALLOW_EXCEEDING
    into iCapacity, iAllowExceeding
    from lpm_division_capacity
    where hrm_division_id = iDivisionIDNew
      and ((iCapacityTypeNew = 'empty' and dic_lpm_capacity_type_id is null)
       or (iCapacityTypeNew <> 'empty' and dic_lpm_capacity_type_id = iCapacityTypeNew));

    select sum(LRE_WORKLOAD)
    into iWorkload
    from lpm_referents
    where hrm_division_id = iDivisionIDNew
      and ((iCapacityTypeNew = 'empty' and dic_lpm_capacity_type_id is null)
       or (iCapacityTypeNew <> 'empty' and dic_lpm_capacity_type_id = iCapacityTypeNew))
      and LRE_START_DATE <= NVL(iEndDate, LRE_START_DATE)
      and NVL(LRE_END_DATE, iStartDate) >= iStartDate
      and lpm_referents_id <> iReferentID;

    if ((iWorkload + iWorkloadNew) / iCapacity) > 100 then
      if iAllowExceeding = 0 then
        return 2;
      else
        return 1;
      end if;
    else
      return 0;
    end if;

  end CheckWorkloadBelongings;

  /**
  * function TreatmentDateBelongings
  * Description : Retourne la plus petite date début d'appartenance > à la date du jour
  *
  * @created JFR
  * @lastUpdate 12.06.2013
  * @public
  * @param iStudentID : ID du bénéficiaire
  * @return La plus petite date début d'appartenance > à la date du jour
  */
  function TreatmentDateBelongings(iStudentID in number)
    return Date
  is
    ReturnDate Date;
    iCpt integer;
  begin
   iCpt := 1;
   for ltplPos in (select LRE_START_DATE
                    into ReturnDate
                    from lpm_referents
                    where sch_student_id = iStudentID
                    and lre_start_date >= sysdate
                    order by lre_start_date asc) loop
     if ltplPos.LRE_START_DATE <= ReturnDate or iCpt = 1 then
      ReturnDate :=  ltplPos.LRE_START_DATE;
     end if;
     iCpt := iCpt + 1;
   end loop;
    return ReturnDate;
  end TreatmentDateBelongings;

  /**
   * procedure SelectDivisions
   * Description
   *   Sélectionne les départements selon les filtres
   */
  procedure SelectDivisions(iDivisionList in varchar2 default null)
  is
    lvInsertQuery varchar2(32000);
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'HRM_DIVISION_ID';

    -- Department selection
    lvInsertQuery  :=
      lvInsertQuery ||
      ' insert into COM_LIST_ID_TEMP ' ||
      '          (COM_LIST_ID_TEMP_ID ' ||
      '         , LID_CODE ' ||
      '          ) ' ||
      ' select DIV.HRM_DIVISION_ID ' ||
      '    , ''HRM_DIVISION_ID'' ' ||
      '  from LPM_DIVISION DIV ';

    if iDivisionList is not null then
      lvInsertQuery  :=
        lvInsertQuery ||
        ' where HRM_DIVISION_ID IN ('|| iDivisionList || ')';
    end if;

    execute immediate lvInsertQuery;


  end SelectDivisions;

  /**
   * procedure SelectDivision
   * Description
   *   Sélectionne les départements selon les filtres
   */
  procedure SelectDivision(aHRM_DIVISION_ID in HRM_DIVISION.HRM_DIVISION_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'HRM_DIVISION_ID';

    -- Sélection de l'ID du département
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aHRM_DIVISION_ID
               , 'HRM_DIVISION_ID'
                );
  end SelectDivision;

  /**
  * function WaitingTimeCalc
  * Description : Calcule le temps d'attente d'un bénéficiaire pour un département
  *
  * @created JFR
  * @lastUpdate 02.09.2013
  * @public
  */
  function WaitingTimeCalc(aSCH_WAITING_LIST_ID in SCH_WAITING_LIST.SCH_WAITING_LIST_ID%type)
  return number
  is
    WaitingListDate Date;
    CompareDate Date;
    StudentID number;
  begin
    select SCH_STUDENT_ID, A_DATECRE
    into StudentId, WaitingListDate
    from SCH_WAITING_LIST
    where SCH_WAITING_LIST_ID = aSCH_WAITING_LIST_ID;

    begin
      select MIN(LRE_START_DATE)
      into CompareDate
      from LPM_REFERENTS
      where SCH_STUDENT_ID = StudentID
        and trunc(LRE_START_DATE) > to_date(to_char(WaitingListDate,'yyyymmdd'),'yyyymmdd')
      order by LRE_START_DATE asc;
      exception
        when no_data_found then
          select STU_EXIT_DATE
          into CompareDate
          from SCH_STUDENT
          where SCH_STUDENT_ID = StudentID;
    end;
    if CompareDate is null then
      select STU_EXIT_DATE
      into CompareDate
      from SCH_STUDENT
      where SCH_STUDENT_ID = StudentID;
    end if;
    if CompareDate is null then
      select SYSDATE
      into CompareDate
      from dual;
    end if;

    return TRUNC(CompareDate - WaitingListDate, 1);
  end WaitingTimeCalc;

  procedure DisabledWaitingList(aSCH_STUDENT_ID in SCH_STUDENT.SCH_STUDENT_ID%type)
  is
  begin
    update SCH_WAITING_LIST
    set SWL_ACTIVE = 0
    where SCH_STUDENT_ID = aSCH_STUDENT_ID;

    -- Recalcule des listes d'attente
    for ltplPos in (select WLI.SCH_WAITING_LIST_ID
                          , WLI.HRM_DIVISION_ID
                        from SCH_WAITING_LIST WLI
                       where SCH_STUDENT_ID = aSCH_STUDENT_ID
                    ) loop
      RecalculatePositions(ltplPos.HRM_DIVISION_ID, 0, ltplPos.SCH_WAITING_LIST_ID);
    end loop;
  end DisabledWaitingList;

  /**
  * procedure DuplicateBelongings
  * Description : Copie d'une appartenance
  * @created JFR
  * @lastUpdate 06.11.2013
  * @public
  */
  procedure DuplicateBelongings(aLPM_REFERENTS_ID in LPM_REFERENTS.LPM_REFERENTS_ID%type,
                                CloseOldBelongings in integer,
                                CopyVField in integer,
                                DateCloseBelongings in date,
                                DateStartBelongings in date,
                                DateEndBelongings in date,
                                DateStartBilling in date,
                                DateEndBilling in date)
  is
    newLPM_REFERENTS_ID   LPM_REFERENTS.LPM_REFERENTS_ID%type;
    ltReferents           FWK_I_TYP_DEFINITION.t_crud_def;
    ltUpdateReferents     FWK_I_TYP_DEFINITION.t_crud_def;
    iStudentId            LPM_REFERENTS.SCH_STUDENT_ID%type;
    iPersonId             LPM_REFERENTS.HRM_PERSON_ID%type;
    iPerson2Id             LPM_REFERENTS.HRM_PERSON_ID%type;
    iDivisionId           LPM_REFERENTS.SCH_STUDENT_ID%type;
    iStartDate            LPM_REFERENTS.LRE_START_DATE%type;
  begin
    select SCH_STUDENT_ID, HRM_PERSON_ID, HRM_PERSON2_ID, HRM_DIVISION_ID, LRE_START_DATE
    into iStudentId, iPersonId, iPerson2Id, iDivisionId, iStartDate
    from LPM_REFERENTS
    WHERE LPM_REFERENTS_ID = aLPM_REFERENTS_ID;

    /* Récupération d'un ID pour la nouvelle appartenance */
    newLPM_REFERENTS_ID  := getNewId;
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_LPM_ENTITY.gcLpmReferents, iot_crud_definition => ltReferents
                       , iv_primary_col        => 'LPM_REFERENTS_ID');
    FWK_I_MGT_ENTITY.prepareDuplicate(ltReferents, true, aLPM_REFERENTS_ID);
    -- id principal
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'LPM_REFERENTS_ID', newLPM_REFERENTS_ID);
    -- id du bénéficiaire
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'SCH_STUDENT_ID',iStudentId);
    -- id de la personne référente
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'HRM_PERSON_ID',iPersonId);
-- id de la personne référente
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'HRM_PERSON2_ID',iPerson2Id);
    -- id de la structure
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'HRM_DIVISION_ID',iDivisionId);
    -- id date début
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'LRE_START_DATE', DateStartBelongings);
    -- id date fin
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'LRE_END_DATE', DateEndBelongings);
    -- Date début présence
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'LRE_START_BILLING_DATE', DateStartBilling);
    -- Date fin présence
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'LRE_END_BILLING_DATE', DateEndBilling);

    /* Insertion de la nouvelle position */
    FWK_I_MGT_ENTITY.InsertEntity(ltReferents);
    FWK_I_MGT_ENTITY.Release(ltReferents);

    if CloseOldBelongings = 1 then
      /* Clore les anciennes appartenances avec la date de fin */
      FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_LPM_ENTITY.gcLpmReferents, iot_crud_definition => ltUpdateReferents
                         , iv_primary_col        => 'LPM_REFERENTS_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltUpdateReferents, 'LPM_REFERENTS_ID', aLPM_REFERENTS_ID);
      if DateCloseBelongings < iStartDate then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltUpdateReferents, 'LRE_END_DATE', iStartDate);
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltUpdateReferents, 'LRE_END_DATE', DateCloseBelongings);
      end if;
      FWK_I_MGT_ENTITY.UpdateEntity(ltUpdateReferents);
      FWK_I_MGT_ENTITY.Release(ltUpdateReferents);
    end if;

    if CopyVField = 1 then
      COM_VFIELDS.DuplicateVirtualField('LPM_REFERENTS', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                  aLPM_REFERENTS_ID, newLPM_REFERENTS_ID);
    end if;
  end DuplicateBelongings;
end SCH_PRC_STUDENT;
