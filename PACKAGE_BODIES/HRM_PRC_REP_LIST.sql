--------------------------------------------------------
--  DDL for Package Body HRM_PRC_REP_LIST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_REP_LIST" 
is
  gv_year          varchar2(4);
  gd_beginofperiod date;
  gd_endofperiod   date;

  procedure SetYear(iv_year in varchar2)
  is
  begin
    if iv_year is not null then
      gv_year           := iv_year;
      gd_beginOfPeriod  := to_date(iv_year || '0101', 'yyyymmdd');
      gd_endOfPeriod    := to_date(iv_year || '1231', 'yyyymmdd');
    end if;
  end SetYear;

  procedure SetPeriod(id_validasof in date)
  is
  begin
    gv_year           := to_char(id_validasof, 'yyyy');
    gd_beginOfPeriod  := trunc(id_validasof, 'month');
    gd_endOfPeriod    := last_day(id_validasOf);
  end SetPeriod;

  procedure SetPeriod(id_from in date, id_to in date)
  is
  begin
    gv_year           := to_char(id_to, 'yyyy');
    gd_beginOfPeriod  := trunc(id_from, 'month');
    gd_endOfPeriod    := last_day(id_to);
  end SetPeriod;

  function BeginOfPeriod
    return date
  is
  begin
    return gd_beginOfPeriod;
  end BeginOfPeriod;

  function EndOfPeriod
    return date
  is
  begin
    return gd_endOfPeriod;
  end EndOfPeriod;

  function getYear
    return varchar2
  is
  begin
    return gv_year;
  end getYear;

  /**
   * Date de début et de fin de la période précédente (rétroactif)
   */
  function BeginOfPrevPeriod
    return date
  is
  begin
    return add_months(BeginOfPeriod, -12);
  end BeginOfPrevPeriod;

  function EndOfPrevPeriod
    return date
  is
  begin
    return BeginOfPeriod - 1;
  end EndOfPrevPeriod;

  procedure DeleteList
  is
  begin
    delete from hrm_tmp_rep_period;
  end;

  function getInsuranceEquivalence(
    iInsuranceId in hrm_insurance.hrm_insurance_id%type
  , iRootId      in hrm_elements_root.hrm_elements_root_id%type
  , iCode        in hrm_insurance_code.ins_elm_code%type
  )
    return hrm_insurance_code.ins_elm_code%type deterministic
  is
    lv_code hrm_insurance_code.ins_elm_code%type;
  begin
    lv_code  := replace(iCode, '"', '');

    select coalesce( (select INS.INS_ELM_CODE
                        from HRM_INSURANCE_CODE INS
                       where INS.HRM_INSURANCE_ID = iInsuranceId
                         and INS.HRM_ELEMENTS_ROOT_ID = iRootId
                         and INS.INS_ORIGINAL_CODE = lv_code), lv_code)
      into lv_code
      from dual;

    return lv_code;
  end;

  function getInsuranceEquivalence(
    iListId in hrm_control_list.hrm_control_list_id%type
  , iEmpId  in hrm_history_detail.hrm_employee_id%type
  , iPayNum in hrm_history.hit_pay_num%type
  , iCoeBox in hrm_control_elements.coe_box%type
  , iCode   in hrm_insurance_code.ins_elm_code%type default null
  )
    return hrm_insurance_code.ins_elm_code%type
  is
    lv_code         hrm_insurance_code.ins_elm_code%type;
    ln_insurance_id hrm_insurance.hrm_insurance_id%type;
    ln_root_id      hrm_elements_root.hrm_elements_root_id%type;

    function GetErrorMsg
      return varchar2
    is
      lv_msg varchar2(32767);
    begin
      select (select COL_NAME
                from HRM_CONTROL_LIST
               where HRM_CONTROL_LIST_ID = iListId) || ' - ' || iCoeBox || ' / ' || (select PER_FIRST_NAME || '  ' || PER_LAST_NAME
                                                                                       from HRM_PERSON
                                                                                      where HRM_PERSON_ID = iEmpId)
        into lv_msg
        from dual;

      return lv_msg;
    end;
  begin
    select HRM_INSURANCE_ID
      into ln_insurance_id
      from hrm_insurance
     where HRM_CONTROL_LIST_ID = iListId;

    begin
      select HRM_ELEMENTS_ROOT_ID
        into ln_root_id
        from HRM_ELEMENTS_FAMILY ELF
       where ELF.HRM_ELEMENTS_ID in(select HRM_CONTROL_ELEMENTS_ID
                                      from HRM_CONTROL_ELEMENTS
                                     where COE_BOX = iCoeBox
                                       and HRM_CONTROL_LIST_ID = iListId);
    exception
      when no_data_found then
        null;   --raise_application_error(-20000, GetErrorMsg || 'Positionnement non défini dans la liste');
      when too_many_rows then
        raise_application_error(-20000, GetErrorMsg || 'Positionnement défini à double dans la liste');
    end;

    if iCode is null then
      begin
        select replace(DET.HIS_PAY_VALUE, '"', '')
          into lv_code
          from HRM_ELEMENTS_FAMILY ELF
             , HRM_HISTORY_DETAIL DET
         where ELF.HRM_ELEMENTS_ID = DET.HRM_ELEMENTS_ID
           and DET.HRM_EMPLOYEE_ID = iEmpId
           and DET.HIS_PAY_NUM = iPayNum
           and DET.HRM_ELEMENTS_ID = (select HRM_CONTROL_ELEMENTS_ID
                                        from HRM_CONTROL_ELEMENTS
                                       where COE_BOX = iCoeBox
                                         and HRM_CONTROL_LIST_ID = iListId);
      exception
        when no_data_found then
          return GetInsuranceEquivalence(ln_insurance_id, ln_root_id, '0');
        when too_many_rows then
          raise_application_error(-20000, GetErrorMsg || 'Positionnement défini à double dans la liste');
      end;
    end if;

    return getInsuranceEquivalence(ln_insurance_id, ln_root_id, nvl(iCode, lv_code) );
  end;

  function GetDefaultEstablishment
    return HRM_ESTABLISHMENT.HRM_ESTABLISHMENT_ID%type
  is
    lnDefEstablishmentId HRM_ESTABLISHMENT.HRM_ESTABLISHMENT_ID%type;
  begin
    select EST.HRM_ESTABLISHMENT_ID
      into lnDefEstablishmentId
      from HRM_ESTABLISHMENT EST
     where EST.EST_DEFAULT = 1
       and exists(select 1
                    from PCS.PC_CNTRY
                   where CNTID = 'CH'
                     and PC_CNTRY_ID = EST.PC_CNTRY_ID)
       and (PCS.PC_CONFIG.GETCONFIG('HRM_LOCALISATION') = 'CH');

    return lnDefEstablishmentId;
  end GetDefaultEstablishment;

  procedure PrepareList(pListId in number, pYear in varchar2, pCoeBox in varchar2, pGroup in number default null)
  is
  begin
    SetYear(pYear);
    PrepareList(pListId, beginofperiod, pCoeBox, pGroup);
  end;

  procedure PrepareList(pListId in number, pYear in varchar2, pCoeBox in varchar2, pCoeBox2 in varchar2)
  is
  begin
    SetYear(pYear);
    PrepareList(pListId, beginofperiod, pCoeBox, pCoeBox2);
  end;

  procedure PrepareList(pListId in number, pBeginOfYear in date, pCoeBox in varchar2, pGroup in number default null)
  is
    PrevEmpId         number;
    PrevIn            date;
    PrevOut           date;
    PrevCode          varchar2(255);
    PrevNum           number;
    PrevPeriod        date;
    FirstNum          number;
    FirstPeriod       date;
    lnEstablishmentId number;
    EndOfYear         date;

    -- Il faut que pCoeBox soit unique dans hrm_control_list (ne doit concerner qu'un seul GS)
    cursor csPrepare
    is
      select   *
          from (select H.HIT_PAY_NUM
                     , H.HIT_PAY_PERIOD
                     , H.HRM_EMPLOYEE_ID
                     , I.INO_IN
                     , I.INO_OUT
                     , I.HRM_ESTABLISHMENT_ID
                     , coalesce(getInsuranceEquivalence(pListId, H.HRM_EMPLOYEE_ID, H.HIT_PAY_NUM, pCoeBox)
                              , getInsuranceEquivalence(pListId, H.HRM_EMPLOYEE_ID, H.HIT_PAY_NUM, pCoeBox, 'N/A')
                               ) CODE
                  from HRM_HISTORY H
                     , (select INO_IN
                             , INO_OUT
                             , NEXT_IN
                             , HRM_EMPLOYEE_ID
                             , HRM_ESTABLISHMENT_ID
                          from (select INO_IN
                                     , nvl(INO_OUT, EndOfYear) INO_OUT
                                     , hrm_date.NextInOutInDate(INO_IN, HRM_EMPLOYEE_ID) NEXT_IN
                                     , HRM_EMPLOYEE_ID
                                     , nvl(HRM_ESTABLISHMENT_ID, GetDefaultEstablishment) HRM_ESTABLISHMENT_ID
                                  from HRM_IN_OUT
                                 where C_IN_OUT_CATEGORY = '3')
                         where pBeginOfYear between trunc(INO_IN, 'year') and NEXT_IN) I
                 where H.HRM_EMPLOYEE_ID = I.HRM_EMPLOYEE_ID
                   and H.HIT_PAY_PERIOD between I.INO_IN and I.NEXT_IN
                   and trunc(H.HIT_PAY_PERIOD, 'Y') = pBeginOfYear)
      --where code not in ('N/A','0')
      order by HRM_EMPLOYEE_ID
             , HIT_PAY_NUM;
  begin
    EndOfYear  := hrm_date.EndOfYear;
    PrevEmpId  := -1;

    for aPrepare in csPrepare loop
      if    (PrevEmpId <> aPrepare.hrm_employee_id)
         or (PrevIn <> aPrepare.ino_in) then
        if not(PrevEmpId < 0) then
          insert into hrm_tmp_rep_period
                      (hrm_employee_id
                     , fromnum
                     , tonum
                     , hisval
                     , ino_in
                     , ino_out
                     , hrm_control_list_id
                     , hisgrp
                     , hrm_establishment_id
                      )
               values (PrevEmpId
                     , FirstNum
                     , PrevNum
                     , PrevCode
                     , FirstPeriod
                     , greatest(FirstPeriod, PrevOut)
                     , pListId
                     , pGroup
                     , lnEstablishmentId
                      );
        end if;

        FirstPeriod  := aPrepare.ino_in;
        FirstNum     := aPrepare.hit_pay_num;
      elsif(PrevCode <> aPrepare.code) then
        insert into hrm_tmp_rep_period
                    (hrm_employee_id
                   , fromnum
                   , tonum
                   , hisval
                   , ino_in
                   , ino_out
                   , hrm_control_list_id
                   , hisgrp
                   , hrm_establishment_id
                    )
             values (PrevEmpId
                   , FirstNum
                   , PrevNum
                   , PrevCode
                   , FirstPeriod
                   , greatest(PrevPeriod, FirstPeriod)
                   , pListId
                   , pGroup
                   , lnEstablishmentId
                    );

        FirstPeriod  := trunc(aPrepare.hit_pay_period, 'month');
        FirstNum     := aPrepare.hit_pay_num;
      end if;

      PrevEmpId          := aPrepare.hrm_employee_id;
      PrevIn             := aPrepare.ino_in;
      PrevOut            := aPrepare.ino_out;
      PrevCode           := aPrepare.code;
      PrevNum            := aPrepare.hit_pay_num;
      PrevPeriod         := aPrepare.hit_pay_period;
      lnEstablishmentId  := aPrepare.HRM_ESTABLISHMENT_ID;
    end loop;

    if not(PrevEmpId < 0) then
      insert into hrm_tmp_rep_period
                  (hrm_employee_id
                 , fromnum
                 , tonum
                 , hisval
                 , ino_in
                 , ino_out
                 , hrm_control_list_id
                 , hisgrp
                 , hrm_establishment_id
                  )
           values (PrevEmpId
                 , FirstNum
                 , PrevNum
                 , PrevCode
                 , FirstPeriod
                 , greatest(PrevOut, FirstPeriod)
                 , pListId
                 , pGroup
                 , lnEstablishmentId
                  );
    end if;
  end;

  procedure PrepareList(pListId in number, pBeginOfYear in date, pCoeBox1 in varchar2, pCoeBox2 in varchar2)
  is
    PrevEmpId         number;
    PrevIn            date;
    PrevOut           date;
    PrevCode          varchar2(255);
    PrevNum           number;
    PrevPeriod        date;
    FirstNum          number;
    FirstPeriod       date;
    EndOfYear         date;
    lnEstablishmentId number;

    -- Il faut que pCoeBox1 soit unique dans hrm_control_list (ne doit concerner qu'un seul GS)
    -- Il faut que pCoeBox2 soit unique dans hrm_control_list (ne doit concerner qu'un seul GS)
    cursor csPrepare
    is
      select *
        from (select   hit_pay_num
                     , hit_pay_period
                     , h.hrm_employee_id
                     , ino_in
                     , ino_out
                     , hrm_establishment_id
                     , coalesce(getInsuranceEquivalence(pListId, H.HRM_EMPLOYEE_ID, H.HIT_PAY_NUM, pCoeBox1)
                              , getInsuranceEquivalence(pListId, H.HRM_EMPLOYEE_ID, H.HIT_PAY_NUM, pCoeBox1, 'N/A')
                               ) ||
                       '-' ||
                       coalesce(getInsuranceEquivalence(pListId, H.HRM_EMPLOYEE_ID, H.HIT_PAY_NUM, pCoeBox2)
                              , getInsuranceEquivalence(pListId, H.HRM_EMPLOYEE_ID, H.HIT_PAY_NUM, pCoeBox2, 'N/A')
                               ) CODE
                  from HRM_HISTORY H
                     , (select INO_IN
                             , INO_OUT
                             , NEXT_IN
                             , HRM_EMPLOYEE_ID
                             , HRM_ESTABLISHMENT_ID
                          from (select INO_IN
                                     , nvl(INO_OUT, EndOfYear) INO_OUT
                                     , hrm_date.NextInOutInDate(ino_in, HRM_EMPLOYEE_ID) NEXT_IN
                                     , HRM_EMPLOYEE_ID
                                     , nvl(HRM_ESTABLISHMENT_ID, GetDefaultEstablishment) HRM_ESTABLISHMENT_ID
                                  from HRM_IN_OUT
                                 where C_IN_OUT_CATEGORY = '3')
                         where pBeginOfYear between trunc(INO_IN, 'year') and NEXT_IN) I
                 where H.HRM_EMPLOYEE_ID = I.HRM_EMPLOYEE_ID
                   and H.HIT_PAY_PERIOD between I.INO_IN and I.NEXT_IN
                   and trunc(H.HIT_PAY_PERIOD, 'Y') = pBeginOfYear
              order by H.HRM_EMPLOYEE_ID
                     , H.HIT_PAY_NUM);
  -- where code not in ( 'N/A','0','0-0') ;
  begin
    EndOfYear  := hrm_date.EndOfYear;
    PrevEmpId  := -1;

    for aPrepare in csPrepare loop
      if    (PrevEmpId <> aPrepare.hrm_employee_id)
         or (PrevIn <> aPrepare.ino_in) then
        if not(PrevEmpId < 0) then
          insert into hrm_tmp_rep_period
                      (hrm_employee_id
                     , fromnum
                     , tonum
                     , hisval
                     , ino_in
                     , ino_out
                     , hrm_control_list_id
                     , hrm_establishment_id
                      )
               values (PrevEmpId
                     , FirstNum
                     , PrevNum
                     , PrevCode
                     , FirstPeriod
                     , PrevOut
                     , pListId
                     , lnEstablishmentId
                      );
        end if;

        FirstPeriod  := aPrepare.ino_in;
        FirstNum     := aPrepare.hit_pay_num;
      elsif(PrevCode <> aPrepare.code) then
        insert into hrm_tmp_rep_period
                    (hrm_employee_id
                   , fromnum
                   , tonum
                   , hisval
                   , ino_in
                   , ino_out
                   , hrm_control_list_id
                   , hrm_establishment_id
                    )
             values (PrevEmpId
                   , FirstNum
                   , PrevNum
                   , PrevCode
                   , FirstPeriod
                   , PrevPeriod
                   , pListId
                   , lnEstablishmentId
                    );

        FirstPeriod  := trunc(aPrepare.hit_pay_period, 'month');
        FirstNum     := aPrepare.hit_pay_num;
      end if;

      PrevEmpId          := aPrepare.hrm_employee_id;
      PrevIn             := aPrepare.ino_in;
      PrevOut            := aPrepare.ino_out;
      PrevCode           := aPrepare.code;
      PrevNum            := aPrepare.hit_pay_num;
      PrevPeriod         := aPrepare.hit_pay_period;
      lnEstablishmentId  := aPrepare.HRM_ESTABLISHMENT_ID;
    end loop;

    if not(PrevEmpId < 0) then
      insert into hrm_tmp_rep_period
                  (hrm_employee_id
                 , fromnum
                 , tonum
                 , hisval
                 , ino_in
                 , ino_out
                 , hrm_control_list_id
                 , hrm_establishment_id
                  )
           values (PrevEmpId
                 , FirstNum
                 , PrevNum
                 , PrevCode
                 , FirstPeriod
                 , PrevOut
                 , pListId
                 , lnEstablishmentId
                  );
    end if;
  end;

  procedure PrepareList(pListId in number, pYear in varchar2)
  is
  begin
    SetYear(pYear);
    PrepareList(pListId, beginofperiod);
  end;

  procedure PrepareList(pListId in number, pBeginOfYear in date)
  is
    EndOfYear date;
  begin
    EndOfYear  := hrm_date.EndOfYear;

    insert into HRM_TMP_REP_PERIOD
                (HRM_EMPLOYEE_ID
               , FROMNUM
               , TONUM
               , INO_IN
               , INO_OUT
               , HRM_CONTROL_LIST_ID
               , HRM_ESTABLISHMENT_ID
                )
      select   H.HRM_EMPLOYEE_ID
             , min(HIT_PAY_NUM)
             , max(HIT_PAY_NUM)
             , INO_IN
             , INO_OUT
             , pListId
             , HRM_ESTABLISHMENT_ID
          from HRM_HISTORY H
             , (select INO_IN
                     , INO_OUT
                     , NEXT_IN
                     , HRM_EMPLOYEE_ID
                     , HRM_ESTABLISHMENT_ID
                  from (select INO_IN
                             , nvl(INO_OUT, EndOfYear) INO_OUT
                             , hrm_date.NextInOutInDate(INO_IN, HRM_EMPLOYEE_ID) NEXT_IN
                             , HRM_EMPLOYEE_ID
                             , nvl(HRM_ESTABLISHMENT_ID, GetDefaultEstablishment) HRM_ESTABLISHMENT_ID
                          from HRM_IN_OUT
                         where C_IN_OUT_CATEGORY = '3') i
                 where pBeginOfYear between trunc(INO_IN, 'year') and NEXT_IN) I
         where H.HRM_EMPLOYEE_ID = I.HRM_EMPLOYEE_ID
           and HIT_PAY_PERIOD between ino_in and NEXT_IN
           and trunc(HIT_PAY_PERIOD, 'Y') = pBeginOfYear
      group by H.HRM_EMPLOYEE_ID
             , INO_IN
             , INO_OUT
             , HRM_ESTABLISHMENT_ID;
  end;

  function get_entry(in_empid in hrm_person.hrM_person_id%type, in_adaptedvalue in pls_integer default 1)
    return date
  is
    ld_entry date;

    cursor entry_date
    is
      select   case
                 when in_adaptedvalue = 1 then greatest(INO_IN, beginofprevperiod)
                 else ino_in
               end MINIL
          into ld_entry
          from HRM_IN_OUT
         where HRM_EMPLOYEE_ID = in_empid
           and C_IN_OUT_CATEGORY = '3'
           and INO_IN <= EndOfPeriod
      order by ino_in desc;
  begin
    begin
      select case
               when in_adaptedvalue = 1 then greatest(min(ino_in), beginofperiod)
               else min(ino_in)
             end
        into ld_entry
        from hrm_in_out
       where hrm_employee_id = in_empid
         and C_IN_OUT_CATEGORY = '3'
         and INO_IN <= EndOfPeriod
         and (   INO_OUT is null
              or INO_OUT >= BeginOfPeriod);
    exception
      when no_data_found then
        null;
    end;

    if ld_entry is null then
      -- Entrée / Sortie année précédente (RétroActif)
      open entry_date;

      fetch entry_date
       into ld_entry;

      close entry_date;
    end if;

    return ld_entry;
  end get_entry;

  function get_leave(in_empid in hrm_person.hrM_person_id%type, in_withenddate in pls_integer default 1)
    return date
  is
    ld_leave date;
    ld_entry date;

    cursor leave_date
    is
      select   nvl(INO_OUT, case
                     when in_withenddate = 1 then EndOfPeriod
                   end) MAXIL
          from HRM_IN_OUT
         where HRM_EMPLOYEE_ID = in_empid
           and C_IN_OUT_CATEGORY = '3'
           and INO_IN <= EndOfPeriod
      order by ino_in desc;
  begin
    open leave_date;

    fetch leave_date
     into ld_leave;

    close leave_date;

    return ld_leave;
  end get_leave;

  function get_last_taxcode(in_empid in hrm_person.hrM_person_id%type)
    return hrm_employee_taxsource.emt_canton%type
  is
    lv_result hrm_employee_taxsource.emt_canton%type;

    cursor canton(empid in hrm_person.hrM_person_id%type)
    is
      select   emt_canton
          into lv_result
          from hrm_employee_taxsource
         where hrm_person_id = empid
           and beginofperiod between trunc(emt_from, 'year') and nvl(emt_to, beginofperiod)
      order by emt_from desc;
  begin
    open canton(in_empid);

    fetch canton
     into lv_result;

    close canton;

    return lv_result;
  end get_last_taxcode;

  function get_TextList(
    pListId    in HRM_CONTROL_ELEMENTS.HRM_CONTROL_LIST_ID%type
  , pCoeBox    in HRM_CONTROL_ELEMENTS.COE_BOX%type
  , pLangId    in number
  , pDescrType in number default 1
  )
    return varchar2
  is
    strConcat varchar2(32767);

    cursor csText
    is
      select case pDescrType
               when 0 then elr_root_code
               when 1 then erd_descr
               else erd_subst_code
             end || ' ' || coe_descr as Text
        from hrm_control_elements e
           , hrm_elements_family f
           , hrm_elements_root_descr d
           , hrm_elements_root r
       where f.hrm_elements_id = e.hrm_control_elements_id
         and d.hrm_elements_root_id = f.hrm_elements_root_id
         and r.hrm_elements_root_id = f.hrm_elements_root_id
         and r.c_root_variant = 'Text'
         and e.coe_box = pCoeBox
         and e.hrm_control_list_id = pListId
         and d.pc_lang_id = pLangId;
  begin
    for aText in csText loop
      strConcat  := strConcat || aText.Text || ';';
    end loop;

    return strConcat;
  end;

  function get_ofs_list(in_transmissionId in hrm_elm_transmission.hrm_elm_transmission_id%type)
    return hrm_control_list.hrm_control_list_id%type deterministic
  is
    ln_result hrm_control_list.hrm_control_list_id%type;
  begin
    select l.hrm_control_list_id
      into ln_result
      from hrm_elm_recipient r
         , hrm_control_list l
     where hrm_elm_transmission_id = in_transmissionId
       and r.hrm_control_list_id = l.hrm_control_list_id
       and c_control_list_type = '011'
       and elm_selected = 1;

    return ln_result;
  exception
    when no_data_found then
      return null;
  end get_ofs_list;

  function get_tax_list(in_transmissionId in hrm_elm_transmission.hrm_elm_transmission_id%type)
    return hrm_control_list.hrm_control_list_id%type deterministic
  is
    ln_result hrm_control_list.hrm_control_list_id%type;
  begin
    select l.hrm_control_list_id
      into ln_result
      from hrm_elm_recipient r
         , hrm_control_list l
     where hrm_elm_transmission_id = in_transmissionId
       and r.hrm_control_list_id = l.hrm_control_list_id
       and c_control_list_type = '110'
       and elm_selected = 1;

    return ln_result;
  exception
    when no_data_found then
      return null;
  end get_tax_list;
end HRM_PRC_REP_LIST;
