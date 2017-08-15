--------------------------------------------------------
--  DDL for Package Body HRM_REP_LIST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_REP_LIST" 
/**
  * Génération des listes officielles et documents XML pour déclaration Swissdec.
  *
  * @version 1.0
  * @date 01/2005
  * @author rhermann
  * @author ireber
  * @author spfister
  * @author skalayci
  *
  * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
  */
as
  function GetListDescription(pListId in number, pLangId in number)
    return HRM_CONTROL_LIST_DESCR.HLD_NAME%type deterministic
  is
    lv_result HRM_CONTROL_LIST_DESCR.HLD_DESCR%type;
  begin
    select max(hld_name)
      into lv_result
      from hrm_control_list_descr d
     where d.hrm_control_list_id = pListId
       and d.pc_lang_id = pLangId;

    return lv_result;
  end GetListDescription;

  function GetLAAHeader(pListId in number, pBeginOfYear in date, pCoeBox in varchar2)
    return number
  is
    result number;
  begin
    select max(com_num_amount)
      into result
      from hrm_company_elements
         , hrm_control_elements
     where hrm_control_elements_id = hrm_elements_id
       and pBeginOfYear between com_from and com_to
       and hrm_control_list_id = pListId
       and coe_box = pCoeBox;

    return result;
  exception
    when no_data_found then
      return 0.0;
  end;

  procedure GetLAAHeadCount(pRefDate in date, LAAMenCount out number, LAAWomenCount out number)
  is
  begin
    select nvl(sum(case
                     when per_gender = 'M' then 1
                     else 0
                   end), 0)
         , nvl(sum(case
                     when per_gender = 'F' then 1
                     else 0
                   end), 0)
      into LAAMenCount
         , LAAWomenCount
      from hrm_tmp_rep_period m
         , hrm_person p
     where m.hrm_employee_id = p.hrm_person_id
       and pRefDate between ino_in and ino_out
       and substr(hisval, -1) <> '0';
  end;

  procedure LaaList(
    aRefCursor in out crystal_cursor_types.DualCursorTyp
  , pListId    in     number
  , pYear      in     number
  , pLAAC      in     number
  , pLangId    in     PCS.PC_LANG.PC_LANG_ID%type default null
  )
  is
    Header1         number;
    Header2         number;
    LAAMenCount     number;
    LAAWomenCount   number;
    lv_name         hrm_control_list_descr.hld_name%type;
    lv_ins_name     hrm_insurance.ins_name%type;
    lv_ins_member   hrm_insurance.ins_member_nr%type;
    lv_ins_contract hrm_insurance.ins_contract_nr%type;
  begin
    hrm_prc_rep_list.setYear(pYear);
    hrm_prc_rep_list.DeleteList;

    begin
      select getListDescription(pListId, pLangId) hld_name
           , ins.ins_name
           , ins.ins_member_nr
           , ins.ins_contract_nr
        into lv_name
           , lv_ins_name
           , lv_ins_member
           , lv_ins_contract
        from hrm_insurance INS
       where hrm_control_list_id = pListId;
    exception
      when no_data_found then
        null;
    end;

    if pLAAC <> 1 then
      hrm_prc_rep_list.prepareList(pListId, hrm_prc_rep_list.beginofperiod, 'CODE');
      GetLAAHeadCount(add_months(hrm_prc_rep_list.beginofperiod, 9) - 1, LAAMenCount, LAAWomenCount);
    else
      hrm_prc_rep_list.prepareList(pListId, hrm_prc_rep_list.beginofperiod, 'CODE', 'CODE2');
    end if;

    Header1  := GetLAAHeader(pListId, hrm_prc_rep_list.beginofperiod, 'HEADER1');
    Header2  := GetLAAHeader(pListId, hrm_prc_rep_list.beginofperiod, 'HEADER2');

    open aRefCursor for
      select   coe_box
             , t.hrm_employee_id
             , sum(his_pay_sum_val) hispaysumval
             , hisval code
             , fromnum
             , tonum
             , ino_in
             , nvl(ino_out, hrm_prc_rep_list.endofperiod) ino_out
             , min(his_pay_period) fromperiod
             , max(his_pay_period) toperiod
             , emp_number
             , per_last_name || ' ' || per_first_name per_name
             , per_search_name || to_char(t.hrm_employee_id) empgroup
             , per_gender
             , per_birth_date
             , case
                 when ino_out < hrm_prc_rep_list.beginofperiod then 1
                 else 0
               end sal_is_retro
             , Header1 as MaxLAA
             , LAAMenCount as MenCount
             , LAAWomenCount as WomenCount
             , Header2 as MaxLAA2
             , lv_name hld_name
             , lv_ins_name ins_name
             , lv_ins_member ins_member_nr
             , lv_ins_contract ins_contract_nr
          from hrm_tmp_rep_period t
             , hrm_history_detail d
             , hrm_control_elements e
             , hrm_person p
         where t.hrm_control_list_id = pListId
           and d.hrm_employee_id = t.hrm_employee_id
           and d.his_pay_num between t.fromnum and t.tonum
           and e.hrm_control_list_id = t.hrm_control_list_id
           and d.hrm_elements_id = e.hrm_control_elements_id
           and p.hrm_person_id = t.hrm_employee_id
           and hisval not in('0', 'N/A')
      group by coe_box
             , t.hrm_employee_id
             , hisval
             , fromnum
             , tonum
             , ino_in
             , ino_out
             , emp_number
             , per_last_name
             , per_first_name
             , per_search_name
             , per_gender
             , per_birth_date;
  end;

  procedure LaacList(
    aRefCursor in out crystal_cursor_types.DualCursorTyp
  , pListId    in     number
  , pYear      in     number
  , pLAAC      in     number
  , pLangId    in     PCS.PC_LANG.PC_LANG_ID%type default null
  )
  is
    Header1         number;
    Header2         number;
    LAAMenCount     number;
    LAAWomenCount   number;
    lv_name         hrm_control_list_descr.hld_name%type;
    lv_ins_name     hrm_insurance.ins_name%type;
    lv_ins_member   hrm_insurance.ins_member_nr%type;
    lv_ins_contract hrm_insurance.ins_contract_nr%type;
  begin
    hrm_prc_rep_list.setYear(pYear);
    hrm_prc_rep_list.DeleteList;
    hrm_prc_rep_list.prepareList(pListId, hrm_prc_rep_list.beginofperiod, 'CODE', 'CODE2');

    begin
      select getListDescription(pListId, pLangId) hld_name
           , ins.ins_name
           , ins.ins_member_nr
           , ins.ins_contract_nr
        into lv_name
           , lv_ins_name
           , lv_ins_member
           , lv_ins_contract
        from hrm_insurance INS
       where hrm_control_list_id = pListId;
    exception
      when no_data_found then
        null;
    end;

    open aRefCursor for
      select   '1' grp
             , coe_box
             , t.hrm_employee_id
             , sum(his_pay_sum_val) hispaysumval
             , substr(hisval, 1, instr(hisval, '-') - 1) code1
             , substr(hisval, instr(hisval, '-') + 1) code2
             , fromnum
             , tonum
             , ino_in
             , nvl(ino_out, hrm_prc_rep_list.endofperiod) ino_out
             , min(his_pay_period) fromperiod
             , max(his_pay_period) toperiod
             , emp_number
             , per_last_name || ' ' || per_first_name per_name
             , per_search_name || to_char(t.hrm_employee_id) empgroup
             , per_gender
             , per_birth_date
             , case
                 when ino_out < hrm_prc_rep_list.beginofperiod then 1
                 else 0
               end sal_is_retro
             , lv_name hld_name
             , lv_ins_name ins_name
             , lv_ins_member ins_member_nr
             , lv_ins_contract ins_contract_nr
          from hrm_tmp_rep_period t
             , hrm_history_detail d
             , hrm_control_elements e
             , hrm_person p
         where t.hrm_control_list_id = pListId
           and d.hrm_employee_id = t.hrm_employee_id
           and d.his_pay_num between t.fromnum and t.tonum
           and e.hrm_control_list_id = t.hrm_control_list_id
           and d.hrm_elements_id = e.hrm_control_elements_id
           and p.hrm_person_id = t.hrm_employee_id
           and (   substr(hisval, 1, instr(hisval, '-') - 1) not in('0', 'N/A')
                or substr(hisval, instr(hisval, '-') + 1) not in('0', 'N/A') )
      group by coe_box
             , t.hrm_employee_id
             , hisval
             , fromnum
             , tonum
             , ino_in
             , ino_out
             , emp_number
             , per_last_name
             , per_first_name
             , per_search_name
             , per_gender
             , per_birth_date;
  end;

  procedure LPPList(aRefCursor in out crystal_cursor_types.DualCursorTyp, pListId in number, pYear in number, PROCUSER_LANID in PCS.PC_LANG.LANID%type)
  is
    strUnknown      varchar2(255);
    lv_name         hrm_control_list_descr.hld_name%type;
    lv_ins_name     hrm_insurance.ins_name%type;
    lv_ins_member   hrm_insurance.ins_member_nr%type;
    lv_ins_contract hrm_insurance.ins_contract_NR%type;
    vpc_lang_id     PCS.PC_LANG.PC_LANG_ID%type            := null;
  begin
    hrm_prc_rep_list.setYear(pYear);
    hrm_prc_rep_list.DeleteList;
    hrm_prc_rep_list.prepareList(pListId, hrm_prc_rep_list.beginofperiod, 'CODE');

    if (PROCUSER_LANID is not null) then
      select pcs.pc_public.translateWord('Inconnu', pc_lang_id)
           , PC_LANG_ID
        into strUnknown
           , vpc_lang_id
        from pcs.pc_lang
       where lanid = PROCUSER_LANID;
    end if;

    begin
      select getListDescription(pListId, vpc_lang_id) hld_name
           , ins.ins_name
           , ins.ins_member_nr
           , ins.ins_contract_nr
        into lv_name
           , lv_ins_name
           , lv_ins_member
           , lv_ins_contract
        from hrm_insurance INS
       where hrm_control_list_id = pListId;
    exception
      when no_data_found then
        null;
    end;

    open aRefCursor for
      select   coe_box
             , t.hrm_employee_id
             , sum(his_pay_sum_val) hispaysumval
             , max(his_pay_sum_val) hispaymaxval
             , hisval code
             , fromnum
             , tonum
             , ino_in
             , nvl(ino_out, hrm_prc_rep_list.endofperiod) ino_out
             , min(his_pay_period) fromperiod
             , max(his_pay_period) toperiod
             , nvl(emp_social_securityno2, emp_social_securityno) emp_social_securityno
             , case
                 when length(nvl(emp_social_securityno2, emp_social_securityno) ) in(14, 16) then 1
                 else 0
               end SecurityNo_IsValid
             , emp_number
             , per_last_name || ' ' || per_first_name per_name
             , per_search_name || to_char(t.hrm_employee_id) empgroup
             , per_birth_date
             , case
                 when ino_out < hrm_prc_rep_list.beginofperiod then 1
                 else 0
               end sal_is_retro
             , emp_lpp_contributor
             , c_civil_status
             , nvl(des.gcdtext1, strUnknown) gcdtext1
             , per_activity_rate
             , lv_name hld_name
             , lv_ins_name ins_name
             , lv_ins_member ins_member_nr
             , lv_ins_contract ins_contract_nr
          from hrm_tmp_rep_period t
             , hrm_history_detail d
             , hrm_control_elements e
             , hrm_person p
             , (select gcdtext1
                     , gclcode
                  from pcs.pc_gcodes g
                 where lanid = procuser_lanid
                   and gcgname = 'C_CIVIL_STATUS') des
         where t.hrm_control_list_id = pListId
           and d.hrm_employee_id = t.hrm_employee_id
           and d.his_pay_num between t.fromnum and t.tonum
           and e.hrm_control_list_id = t.hrm_control_list_id
           and d.hrm_elements_id = e.hrm_control_elements_id
           and p.hrm_person_id = t.hrm_employee_id
           and p.c_civil_status = gclcode(+)
      group by coe_box
             , t.hrm_employee_id
             , hisval
             , fromnum
             , tonum
             , ino_in
             , ino_out
             , emp_social_securityno2
             , emp_social_securityno
             , per_birth_date
             , emp_number
             , per_last_name
             , per_first_name
             , per_search_name
             , c_civil_status
             , gcdtext1
             , emp_lpp_contributor
             , per_activity_rate;
  end;

  procedure cafList(
    aRefCursor in out crystal_cursor_types.DualCursorTyp
  , pListId    in     number
  , pYear      in     number
  , pLangId    in     PCS.PC_LANG.PC_LANG_ID%type default null
  )
  is
    lv_name hrm_control_list_descr.hld_name%type;
  begin
    hrm_prc_rep_list.setYear(pYear);
    hrm_prc_rep_list.DeleteList;
    hrm_prc_rep_list.prepareList(pListId, hrm_prc_rep_list.beginofperiod, 'CODE');
    lv_name  := getListDescription(pListId, pLangId);

    open aRefCursor for
      select   coe_box
             , t.hrm_employee_id
             , sum(his_pay_sum_val) hispaysumval
             , hisval code
             , fromnum
             , tonum
             , ino_in
             , nvl(ino_out, hrm_prc_rep_list.endofperiod) ino_out
             , min(his_pay_period) fromperiod
             , max(his_pay_period) toperiod
             , case
                 when emp_social_securityno2 is null then emp_social_securityno
                 else emp_social_securityno2
               end emp_social_securityno
             , case
                 when length(nvl(emp_social_securityno2, emp_social_securityno) ) in(14, 16) then 1
                 else 0
               end SecurityNo_IsValid
             , emp_number
             , per_last_name || ' ' || per_first_name per_name
             , per_search_name || to_char(t.hrm_employee_id) empgroup
             , per_birth_date
             , per_gender
             , emp_lpp_contributor
             , c_civil_status
             , per_activity_rate as tauxocc
             , per_search_name
             , case
                 when ino_out < hrm_prc_rep_list.beginofperiod then 1
                 else 0
               end sal_is_retro
             , I.INS_name
             , I.INS_MEMBER_NR
             , I.INS_CONTRACT_NR
             , lv_name hld_name
          from hrm_tmp_rep_period t
             , HRM_HISTORY_DETAIL d
             , hrm_control_elements e
             , hrm_person p
             , hrm_insurance i
         where t.hrm_control_list_id = pListId
           and d.hrm_employee_id = t.hrm_employee_id
           and d.his_pay_num between t.fromnum and t.tonum
           and e.hrm_control_list_id = t.hrm_control_list_id
           and d.hrm_elements_id = e.hrm_control_elements_id
           and p.hrm_person_id = t.hrm_employee_id
           and t.hisval <> 'N/A'
           and i.hrm_control_list_id = e.hrm_control_list_id
           and (   i.dic_canton_work_id = t.hisval
                or i.dic_canton_work_id is null)
           and not exists(select 1
                            from hrm_insurance
                           where c_hrm_insurance = '06'
                             and dic_canton_work_id = t.hisval
                             and hrm_insurance_id <> i.hrm_insurance_id)
      group by coe_box
             , t.hrm_employee_id
             , hisval
             , fromnum
             , tonum
             , ino_in
             , ino_out
             , emp_social_securityno
             , emp_social_securityno2
             , emp_number
             , per_last_name
             , per_first_name
             , per_search_name
             , per_birth_date
             , per_gender
             , c_civil_status
             , emp_lpp_contributor
             , per_activity_rate
             , per_search_name
             , I.INS_name
             , I.INS_MEMBER_NR
             , I.INS_CONTRACT_NR;
  end;

  procedure AvsList(
    aRefCursor in out crystal_cursor_types.DualCursorTyp
  , pListId    in     number
  , pYear      in     number
  , pLangId    in     PCS.PC_LANG.PC_LANG_ID%type default null
  )
  is
    first_lpp_insurance varchar2(100);
    first_laa_insurance varchar2(100);
    lv_name             hrm_control_list_descr.hld_name%type;
    lv_ins_name         hrm_insurance.ins_name%type;
    lv_ins_member       hrm_insurance.ins_member_nr%type;
    lv_ins_contract     hrm_insurance.ins_contract_nr%type;
  begin
    hrm_prc_rep_list.SETYear(pYear);
    hrm_prc_rep_list.DeleteList;
    hrm_prc_rep_list.prepareList(pListId, hrm_prc_rep_list.beginofperiod, 'CODE');

    select min(ins_name || ',' || ins_contract_nr)
      into first_lpp_insurance
      from hrm_insurance
     where c_hrM_insurance = '07';

    select min(ins_name || ',' || ins_member_nr)
      into first_laa_insurance
      from hrm_insurance
     where c_hrM_insurance = '02';

    if first_laa_insurance is null then
      select min(ins_name || ',' || ins_contract_nr)
        into first_laa_insurance
        from hrm_insurance
       where c_hrM_insurance = '04';
    end if;

    begin
      select getListDescription(pListId, pLangId) hld_name
           , ins.ins_name
           , ins.ins_member_nr
           , ins.ins_contract_nr
        into lv_name
           , lv_ins_name
           , lv_ins_member
           , lv_ins_contract
        from hrm_insurance ins
       where hrm_control_list_id = pListId;
    exception
      when no_data_found then
        null;
    end;

    open aRefCursor for
      select   coe_box
             , t.hrm_employee_id
             , sum(his_pay_sum_val) hispaysumval
             , per_gender
             , hisval code
             , fromnum
             , tonum
             , ino_in
             , ino_out
             , min(his_pay_period) fromperiod
             , max(his_pay_period) toperiod
             , emp_social_securityno2 emp_social_securityno
             , case
                 when emp_social_securityno2 is not null then 1
                 else 0
               end SecurityNo_IsValid
             , emp_number
             , per_last_name || ' ' || per_first_name per_name
             , per_search_name || to_char(per_birth_date, 'yyyymmdd') || to_char(t.hrm_employee_id) EMPGROUP
             , per_birth_date
             , case
                 when ino_out < hrm_prc_rep_list.beginofperiod then 1
                 else 0
               end sal_is_retro
             , FIRST_LPP_INSURANCE LPP_INSURANCE
             , FIRST_LAA_INSURANCE LAA_INSURANCE
             , lv_name hld_name
             , lv_ins_name ins_name
             , lv_ins_member ins_member_nr
             , lv_ins_contract ins_contract_nr
          from hrm_tmp_rep_period t
             , HRM_HISTORY_DETAIL d
             , hrm_control_elements e
             , hrm_person p
         where t.hrm_control_list_id = pListId
           and d.hrm_employee_id = t.hrm_employee_id
           and d.his_pay_num between t.fromnum and t.tonum
           and e.hrm_control_list_id = t.hrm_control_list_id
           and d.hrm_elements_id = e.hrm_control_elements_id
           and p.hrm_person_id = t.hrm_employee_id
      group by coe_box
             , t.hrm_employee_id
             , per_gender
             , hisval
             , fromnum
             , tonum
             , ino_in
             , ino_out
             , emp_social_securityno2
             , emp_number
             , per_last_name
             , per_first_name
             , per_search_name
             , per_birth_date;
  end;

  procedure CertifList(
    aRefCursor in out crystal_cursor_types.DualCursorTyp
  , pListId    in     number
  , pYear      in     number
  , pLangType  in     number
  , pFromEmp   in     varchar2 default 'A'
  , pToEmp     in     varchar2 default 'zzzz'
  , pDescrType in     number default 1
  )
  is
  begin
    hrm_prc_rep_list.setYear(pYear);
    CertifPeriodList(aRefCursor, pListId, pYear, hrm_prc_rep_list.beginofperiod, hrm_prc_rep_list.endofperiod, pLangType, pFromEmp, pToEmp, pDescrType);
  end;

  procedure CertifPeriodList(
    aRefCursor  in out crystal_cursor_types.DualCursorTyp
  , pListId     in     number
  , pYear       in     number
  , pPeriodFrom in     date
  , pPeriodTo   in     date
  , pLangType   in     number
  , pFromEmp    in     varchar2
  , pToEmp      in     varchar2
  , pDescrType  in     number default 1
  )
  is
    langid  number;
    FromEmp varchar2(255);
    ToEmp   varchar2(255);
    vText   varchar2(4000);
  begin
    hrm_elm.set_period(pYear, to_char(pPeriodTo, 'MM'));
    hrm_prc_rep_list.setYear(pYear);
    hrm_prc_rep_list.SetPeriod(pPeriodFrom, pPeriodTo); -- décompte intermédiaire

    if pLangType = 0 then
      langid  := pcs.PC_I_LIB_SESSION.GetUserLangId;
    elsif pLangType = 1 then
      langid  := pcs.PC_I_LIB_SESSION.GetCompLangId;
    else
      langid  := null;
    end if;

    FromEmp  := hrm_utils.ConvertToSearchText(pFromEmp);
    ToEmp    := hrm_utils.ConvertToSearchText(pToEmp);

    if langid is not null then
      vText  := hrm_prc_rep_list.get_TextList(pListId, '15.1', langid, pDescrType);
    -- else fait dans le cursor en fonction de la langue de l'employé
    end if;

    open aRefCursor for
      select s.hrm_control_list_id
           , t.hrm_person_id
           , t.c_hrm_tax_certif_type
           , t.contact_name
           , t.contact_phone
           , t.contact_email
           , t.c_hrm_canton_tax_car
           , t.emp_tax_car_date
           , t.emp_tax_fullfilled
           , t.c_hrm_canton_tax_share
           , t.emp_tax_share_date
           , t.emp_tax_third_share
           , t.emp_tax_third_share_name
           , t.emp_tax_expat_expenses
           , t.emp_tax_other_benefits
           , t.c_hrm_canton_tax_fees
           , t.emp_tax_fees_date
           , t.emp_tax_child_allow_peravs
           , t.emp_tax_relocation_costs
           , t.emp_tax_car_check
           , t.emp_carrier_free
           , t.emp_canteen
           , t.emp_tax_remarks emp_certif_observation
           , t.emp_social_securityno
           , t.emp_social_securityno2
           , per_mail_add_selected
           , t.per_search_name || to_char(t.hrm_person_id) empgroup
           , t.per_title
           , t.per_fullname per_name
           , t.pc_lang_id
           , coe_box
           , c_root_variant
           , elr_root_rate
           , elr_root_code
           , coe_descr
           , erd_descr
           , erd_subst_code
           , payval
           , case
               when hrm_prc_rep_list.get_leave(t.hrm_person_id) < hrm_prc_rep_list.beginofperiod then 1
               else 0
             end sal_is_retro
           , nvl( (select trunc(sum(nvl(con_activity_rate, 0) ) )
                     from hrm_contract
                    where hrm_employee_id = t.hrm_person_id
                      and nvl(hrm_prc_rep_list.get_leave(t.hrm_person_id), hrm_prc_rep_list.endofperiod) between con_begin
                                                                                                             and nvl(con_end, hrm_prc_rep_list.endofperiod) )
               , 100
                ) per_activity_rate
           , t.per_birth_date
           , nvl2(langid, vText, hrm_prc_rep_list.get_TextList(pListId, '15.1', t.pc_lang_id, pDescrType) ) text_151
           , case
               when t.dic_hrm_tax_share_reason_id is not null then com_dic_functions.GetDicoDescr('DIC_HRM_TAX_SHARE_REASON'
                                                                                                , t.dic_hrm_tax_share_reason_id
                                                                                                , nvl(langid, t.pc_lang_id)
                                                                                                 )
             end DIC_HRM_TAX_SHARE_REASON_ID
           , case
               when t.dic_hrm_tax_share_reason2_id is not null then com_dic_functions.GetDicoDescr('DIC_HRM_TAX_SHARE_REASON'
                                                                                                 , t.DIC_HRM_TAX_SHARE_REASON2_ID
                                                                                                 , nvl(langid, t.pc_lang_id)
                                                                                                  )
             end dic_hrm_tax_share_reason2_id
           , (select lanid
                from pcs.pc_lang
               where pc_lang_id = nvl(langid, t.pc_lang_id) ) lanid
           , case
               when hrm_prc_rep_list.get_leave(t.hrm_person_id) < hrm_prc_rep_list.beginofperiod then greatest
                                                                                                           (hrm_prc_rep_list.get_entry(t.hrm_person_id)
                                                                                                          , trunc(hrm_prc_rep_list.get_leave(t.hrm_person_id)
                                                                                                                , 'year'
                                                                                                                 )
                                                                                                           )
               else greatest(hrm_prc_rep_list.get_entry(t.hrm_person_id), hrm_prc_rep_list.beginofperiod)
             end ino_in
           , least(nvl(hrm_prc_rep_list.get_leave(t.hrm_person_id), hrm_prc_rep_list.endofperiod), hrm_prc_rep_list.endofperiod) ino_out
           , case
               when bareme = 'GE' then PCS.PC_PUBLIC.TRANSLATEWORD('Info certificat sourciers GE', t.pc_lang_id)
               when bareme is not null then PCS.PC_PUBLIC.TRANSLATEWORD('Info certificat sourciers autres', t.pc_lang_id)
             end info_tax
           , case
               when EMP_TAX_CAR_MIN_PART = 1 then pcs.pc_public.translateword('Info EMP_TAX_CAR_MIN_PART', t.pc_lang_id)
             end info_tax_car_min_part
        from V_HRM_TAX_PERSON T
           , (select e.hrm_control_list_id
                   , erd_subst_code
                   , erd_descr
                   , coe_descr
                   , elr_root_rate
                   , c_root_variant
                   , elr_root_code
                   , coe_box
                   , his_pay_sum_val payval
                   , h.hrm_employee_id
                   , d.pc_lang_id
                from hrm_control_elements e
                   , hrm_history_detail d
                   , hrm_history h
                   , hrm_elements_root r
                   , hrm_elements_root_descr d
                   , hrm_elements_family f
               where e.hrm_control_list_id = pListId
                 and d.hrm_elements_id = e.hrm_control_elements_id
                 and d.hrm_elements_id = f.hrm_elements_id
                 and f.hrm_elements_root_id = d.hrm_elements_root_id
                 and r.hrm_elements_root_id = f.hrm_elements_root_id
                 and hit_pay_num = his_pay_num
                 and d.hrm_employee_id = h.hrm_employee_id
                 and hit_pay_period between hrm_prc_rep_list.BeginOfPeriod and hrm_prc_rep_list.EndOfPeriod) s
       where t.hrm_person_id = s.hrm_employee_id
         and s.hrm_control_list_id = pListId
         and s.pc_lang_id = langid
         and per_search_name between FromEmp and ToEmp;
  end;

  procedure OfsList(
    aRefCursor     in out crystal_cursor_types.DualCursorTyp
  , pListId        in     number
  , pYear          in     number
  , procuser_lanid in     PCS.PC_LANG.LANID%type
  , pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type default null
  )
  is
    vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type   := null;
    vpc_comp_id PCS.PC_COMP.PC_COMP_ID%type   := null;
  begin
    hrm_prc_rep_list.setYear(pYear);
    hrm_prc_rep_list.DeleteList;
    hrm_prc_rep_list.prepareList(pListId, hrm_prc_rep_list.beginofperiod);

    if procuser_lanid is not null then
      pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.GetUserLangId;
    end if;

    if pc_comp_id is not null then
      vpc_comp_id  := PCS.PC_I_LIB_SESSION.getCompanyId;
    end if;

    open aRefCursor for
      select   coe_box
             , t.hrm_employee_id
             , sum(his_pay_sum_val) hispaysumval
             , fromnum
             , tonum
             , ino_in
             , nvl(ino_out, hrm_prc_rep_list.endofperiod) ino_out
             , emp_number
             , per_last_name || ' ' || per_first_name per_name
             , per_search_name || to_char(t.hrm_employee_id) EMPGROUP
             , case
                 when ino_out < hrm_prc_rep_list.beginofperiod then 1
                 else 0
               end sal_is_retro
             , dic_nationality_id
             , c_ofs_training
             , c_ofs_responsability
             , c_ofs_salary_contract
             , emp_ofs_position
             ,
               -- A voir, crééer un fonction pour cela...
               to_number(substr(hrm_functions.EmplYearMonthsOfServiceWDate(t.hrm_employee_id, to_char(hrm_prc_rep_list.endofperiod, 'YYYY-MM-DD') ), 1, 2) )
                                                                                                                                                 YearsOfService
             , permit
             , hours
             , lessons
             , apprentice
             , r.erd_descr
             , r.elr_root_code
             , getListDescription(pListId, vpc_lang_id) hld_name
             , activityrate
             , leavedays
          from hrm_tmp_rep_period t
             , HRM_HISTORY_DETAIL d
             , hrm_control_elements e
             , (select erd_descr
                     , elr_root_code
                     , f.hrm_elements_id
                  from hrm_elements_root_descr d
                     , hrm_elements_root r
                     , hrm_elements_family f
                 where d.pc_lang_id = (select pc_lang_id
                                         from pcs.pc_lang
                                        where lanid = procuser_lanid)
                   and d.hrm_elements_root_id = r.hrm_elements_root_id
                   and r.hrm_elements_root_id = f.hrm_elements_root_id) r
             , (select emp_number
                     , p.hrm_person_id
                     , per_last_name
                     , per_first_name
                     , per_search_name
                     , permit
                     , hours
                     , lessons
                     , nvl(p.emp_con_apprentice, 0) apprentice
                     , dic_nationality_id
                     , ofse.gcdtext1 c_ofs_training
                     , ofsr.gcdtext1 c_ofs_responsability
                     , ofsc.gcdtext1 c_ofs_salary_contract
                     , nvl(emp_ofs_position, (select job_title
                                                from hrm_job
                                               where hrm_job_id = p.hrm_job_id) ) emp_ofs_position
                     , activityrate
                     , leavedays
                  from hrm_person p
                     ,
                       /* Recherche du dernier permit */
                       (select   max(dic_work_permit_id) permit
                               , w.hrm_person_id
                            from hrm_employee_wk_permit w
                           where wop_valid_from =
                                   (select max(wop_valid_from) wop_valid_from
                                      from hrm_employee_wk_permit wl
                                     where hrm_prc_rep_list.beginofperiod between trunc(wop_valid_from, 'Y') and nvl(wop_valid_to, hrm_date.ActivePeriodEndDate)
                                       and w.hrm_person_id = wl.hrm_person_id)
                        group by w.hrm_person_id) w
                     ,
                       /* Recherche du dernier contrat */
                       (select   sum(con_weekly_lessons) lessons
                               , sum(con_weekly_hours) hours
                               , trunc(sum(nvl(con_activity_rate, 0) ) ) activityrate
                               , trunc(max(nvl(con_leave_days,0))) leavedays
                               , hrm_employee_id
                            from hrm_contract
                           where least(nvl(hrm_prc_rep_list.get_leave(hrm_employee_id), hrm_prc_rep_list.endofperiod), hrm_prc_rep_list.endofperiod)
                                   between con_begin
                                       and nvl(con_end, hrm_prc_rep_list.endofperiod)
                        group by hrm_employee_id) c
                     , (select gcdtext1
                             , gclcode
                          from pcs.pc_gcodes g
                         where lanid = procuser_lanid
                           and gcgname = 'C_OFS_TRAINING') ofse
                     , (select gcdtext1
                             , gclcode
                          from pcs.pc_gcodes g
                         where lanid = procuser_lanid
                           and gcgname = 'C_OFS_RESPONSABILITY') ofsr
                     , (select gcdtext1
                             , gclcode
                          from pcs.pc_gcodes g
                         where lanid = procuser_lanid
                           and gcgname = 'C_OFS_SALARY_CONTRACT') ofsc
                 where p.emp_ofs_included = 1
                   and c.hrm_employee_id(+) = p.hrm_person_id
                   and w.hrm_person_id(+) = p.hrm_person_id
                   and ofse.gclcode(+) = c_ofs_training
                   and ofsr.gclcode(+) = c_ofs_responsability
                   and ofsc.gclcode(+) = c_ofs_salary_contract
                   and p.hrm_person_id = c.hrm_employee_id) p
         where t.hrm_control_list_id = pListId
           and d.hrm_employee_id = t.hrm_employee_id
           and d.his_pay_num between t.fromnum and t.tonum
           and e.hrm_control_list_id = t.hrm_control_list_id
           and d.hrm_elements_id = e.hrm_control_elements_id
           and p.hrm_person_id = t.hrm_employee_id
           and r.hrm_elements_id = e.hrm_control_elements_id
      group by dic_nationality_id
             , c_ofs_training
             , c_ofs_responsability
             , c_ofs_salary_contract
             , emp_ofs_position
             , coe_box
             , elr_root_code
             , erd_descr
             , t.hrm_employee_id
             , fromnum
             , tonum
             , ino_in
             , ino_out
             , emp_number
             , per_last_name
             , per_first_name
             , per_search_name
             , permit
             , hours
             , lessons
             , apprentice
             , activityrate
             , leavedays;
  end;
end HRM_REP_LIST;
