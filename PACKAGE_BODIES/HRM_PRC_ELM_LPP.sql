--------------------------------------------------------
--  DDL for Package Body HRM_PRC_ELM_LPP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_ELM_LPP" 
/**
 * Package de gestion des salaires LPP des employés.
 *
 * @version 1.0
 * @date 05.2011
 * @author agabus
 * @author spfister
 * @author skalayci
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
AS

function p_lpp_included(in_transmission_id IN hrm_elm_transmission.hrm_elm_transmission_id%TYPE) return boolean deterministic
is
lb_result number(1);
begin
    select
    case when exists(select 1 from hrm_elm_recipient r, hrm_insurance i
                     where hrm_elm_transmission_id = in_transmission_id
                     and r.hrm_insurance_id = i.hrm_insurance_id
                     and elm_selected = 1
                     and c_hrm_insurance = '07') then 1 else 0 end
             into lb_result
    from
    dual;
    return (lb_result=1);
end p_lpp_included;

procedure LoadSalary(
  in_transmission_id IN hrm_elm_transmission.hrm_elm_transmission_id%TYPE,
  id_valid_on IN hrm_lpp_emp_calc.lpp_valid_on%TYPE,
  in_employee_id IN hrm_person.hrm_person_id%TYPE)
is
  ln_lpp_emp_calc_id hrm_lpp_emp_calc.hrm_lpp_emp_calc_id%TYPE;
  ld_from DATE;
  ld_to DATE;
begin
  hrm_prc_elm_lpp.DeleteSalary(in_transmission_id, in_employee_id);

  select add_months(VALID_FROM,-12), VALID_FROM-1
  into ld_from, ld_to
  from (
    select Trunc(ELM_VALID_AS_OF,'YEAR') VALID_FROM
    from HRM_ELM_TRANSMISSION
    where HRM_ELM_TRANSMISSION_ID = in_transmission_id);


  ln_lpp_emp_calc_id := init_id_seq.nextval;

  begin
      insert into HRM_LPP_EMP_CALC(
        HRM_LPP_EMP_CALC_ID,
        HRM_ELM_TRANSMISSION_ID,
        HRM_PERSON_ID,
        LPP_VALID_ON,
        LPP_YEARLY_AMOUNT,
        C_LPP_MUTATION_TYPE,
        LPP_IN,
        LPP_OUT,
        A_DATECRE,
        A_IDCRE
        )
      SELECT
        ln_lpp_emp_calc_id,
        in_transmission_id,
        in_employee_id,
        nvl(case when trunc(ino_in,'month') = trunc(id_valid_on,'month')  then ino_in
             when trunc(ino_out,'month')=trunc(id_valid_on,'month') then ino_out
        end,id_valid_on),
        0,
        case when trunc(ino_in,'month') = trunc(id_valid_on,'month')  and trunc(ino_out,'month')=trunc(id_valid_on,'month') then '03'
             when trunc(ino_in,'month') = trunc(id_valid_on,'month')  then '01'
             when trunc(ino_out,'month')=trunc(id_valid_on,'month') then '02'
        end,
         case when trunc(ino_in,'month') = trunc(id_valid_on,'month')  and trunc(ino_out,'month')=trunc(id_valid_on,'month') then ino_in
             when trunc(ino_in,'month') = trunc(id_valid_on,'month')  then ino_in
        end,
        case
          when trunc(ino_out,'month') = trunc(id_valid_on,'month') then ino_out
        end,
        Sysdate,
        pcs.pc_public.GetUserIni
      FROM
        HRM_IN_OUT
      where c_in_out_category='3'
       and c_in_out_status ='ACT'
       and hrm_employee_id = in_employee_id;

    exception when dup_val_on_index then
        raise_application_error(-20000,pcs.pc_public.translateword('L''employé a plusieurs entrées/sorties actives'));
    end;

  if p_lpp_included(in_transmission_id) then

      insert into HRM_LPP_EMP_CALC_DETAIL(
        HRM_LPP_EMP_CALC_DETAIL_ID,
        HRM_LPP_EMP_CALC_ID,
        HRM_PERSON_ID,
        HRM_ELEMENTS_ROOT_ID,
        HRM_IN_OUT_ID,
        C_HRM_LPP_REF_TYPE,
        LPP_MONTHLY_AMOUNT,
        LPP_FACTOR,
        LPP_REF_AMOUNT)
      (select init_id_seq.nextval,
              ln_lpp_emp_calc_id,
              DETAIL.HRM_PERSON_ID,
              DETAIL.HRM_ELEMENTS_ROOT_ID,
              DETAIL.HRM_IN_OUT_ID,
              DETAIL.C_HRM_LPP_REF_TYPE,
              DETAIL.LPP_MONTHLY_AMOUNT,
              DETAIL.LPP_FACTOR,
              DETAIL.LPP_REF_AMOUNT
        from (
          -- salaires présumables à prendre en compte
          select I.HRM_EMPLOYEE_ID HRM_PERSON_ID,
                 HRM_ELEMENTS_ROOT_ID,
                 HRM_IN_OUT_ID,
                 '02' C_HRM_LPP_REF_TYPE, -- présumable
                 EMC_NUM_VALUE LPP_MONTHLY_AMOUNT,
                 to_number(Substr(COE_BOX, 2, 2)) LPP_FACTOR,
                 EMC_NUM_VALUE * to_number(Substr(COE_BOX, 2, 2)) LPP_REF_AMOUNT
            from HRM_IN_OUT I,
                 HRM_ELEMENTS_FAMILY F,
                 (select HRM_CONSTANTS_ID,
                         EMC_NUM_VALUE,
                         HRM_EMPLOYEE_ID
                    from HRM_EMPLOYEE_CONST
                   where Sysdate between EMC_VALUE_FROM and EMC_VALUE_TO
                  union all
                  select HRM_ELEMENTS_ID,
                         EMP_NUM_VALUE,
                         HRM_EMPLOYEE_ID
                    from HRM_EMPLOYEE_ELEMENTS
                   where Sysdate between EMP_VALUE_FROM and EMP_VALUE_TO) V,
                 HRM_CONTROL_ELEMENTS CE
           where V.HRM_EMPLOYEE_ID = in_employee_id
             and I.HRM_EMPLOYEE_ID = in_employee_id
             and C_IN_OUT_STATUS = 'ACT'
             AND C_IN_OUT_CATEGORY = '3'
             and id_valid_on between trunc(INO_IN,'year') and Nvl(INO_OUT, id_valid_on)
             and CE.HRM_CONTROL_ELEMENTS_ID = V.HRM_CONSTANTS_ID
             and F.HRM_ELEMENTS_ID = V.HRM_CONSTANTS_ID
             and HRM_CONTROL_LIST_ID in
                    (select R.HRM_CONTROL_LIST_ID
                       from HRM_ELM_RECIPIENT R,
                            HRM_CONTROL_LIST L
                      where R.HRM_ELM_TRANSMISSION_ID = in_transmission_id
                        and R.HRM_CONTROL_LIST_ID =  L.HRM_CONTROL_LIST_ID
                        and C_CONTROL_LIST_TYPE = '116')
              /* la date de sortie de l'entrée active doit étre supérieure à la date d'effet sinon remontée à 0 */
              and not exists(select 1 from hrm_in_out io where io.hrm_employee_id = in_employee_id
                                and c_in_out_category='3'
                                and c_in_out_status ='ACT'
                                and nvl(ino_out,to_date('31.12.2022','dd.mm.yyyy')) <= id_valid_on)
             and Substr(COE_BOX, 1, 1) = 'F'
          union
          -- salaires rétroactifs à prendre en compte
          select HRM_EMPLOYEE_ID HRM_PERSON_ID,
                 HRM_ELEMENTS_ROOT_ID,
                 HRM_IN_OUT_ID,
                 '01' C_HRM_LPP_REF_TYPE, -- rétroactif
                 HISVAL LPP_MONTHLY_AMOUNT,
                 days LPP_FACTOR,
                 case when days = 0
                   then 0
                   else round(HISVAL * 360 / days,2)
                 end LPP_REF_AMOUNT
            from (
              select Sum(HIS_PAY_SUM_VAL) HISVAL,
                     in_employee_id HRM_EMPLOYEE_ID,
                     HRM_IN_OUT_ID,
                     HRM_ELEMENTS_ROOT_ID,
                     i.days
                from ( select sum(hrm_date.days_between(Greatest(INO_IN, ld_from), Least(last_day(Nvl(INO_OUT, ld_to)), ld_to))) days
                       from HRM_IN_OUT
                       where
                       c_in_out_category='3'
                       and ld_from between trunc(ino_in,'year') and nvl(ino_out,ld_to)
                       and hrm_employee_id = in_employee_id) I,
                     HRM_ELEMENTS_FAMILY F,
                     HRM_HISTORY_DETAIL D,
                     HRM_CONTROL_ELEMENTS CE,
                     HRM_IN_OUT IO
               where D.HRM_EMPLOYEE_ID = in_employee_id
                 and CE.HRM_CONTROL_ELEMENTS_ID = D.HRM_ELEMENTS_ID
                 and F.HRM_ELEMENTS_ID = D.HRM_ELEMENTS_ID
                 and io.hrm_employee_id = in_employee_id
                 and his_pay_period between ino_in and last_day(nvl(ino_out,ld_to))
                 and HRM_CONTROL_LIST_ID in
                        (select R.HRM_CONTROL_LIST_ID
                           from HRM_ELM_RECIPIENT R, HRM_CONTROL_LIST L
                          where R.HRM_ELM_TRANSMISSION_ID = in_transmission_id
                            and R.HRM_CONTROL_LIST_ID = L.HRM_CONTROL_LIST_ID
                            and L.C_CONTROL_LIST_TYPE = '116')
                 and HIS_PAY_PERIOD between ld_from and ld_to
                 /* la date de sortie de l'entrée active doit étre supérieure à la date d'effet sinon remontée à 0 */
                 and not exists(select 1 from hrm_in_out io where io.hrm_employee_id = in_employee_id
                                and c_in_out_category='3'
                                and c_in_out_status ='ACT'
                                and nvl(ino_out,to_date('31.12.2022','dd.mm.yyyy')) <= id_valid_on)
                 and Substr(coe_box, 1, 1) = 'P'
                 /* Prise en compte des rétroactifs uniquement pour les déclarations avec effet au 01.01 */
                 and id_valid_on = trunc(id_valid_on,'year')
            group by
                     HRM_ELEMENTS_ROOT_ID, d.HRM_EMPLOYEE_ID, DAYS, HRM_IN_OUT_ID
            )
        ) DETAIL
      );

      update HRM_LPP_EMP_CALC
         set LPP_YEARLY_AMOUNT = Nvl(
                (select Sum(LPP_REF_AMOUNT)
                   from HRM_LPP_EMP_CALC_DETAIL
                  where HRM_LPP_EMP_CALC_ID = ln_lpp_emp_calc_id), 0)
       where HRM_LPP_EMP_CALC_ID = ln_lpp_emp_calc_id;
  end if;
end;


procedure LoadSalary(
  in_transmission_id IN hrm_elm_transmission.hrm_elm_transmission_id%TYPE,
  id_valid_on IN hrm_lpp_emp_calc.lpp_valid_on%TYPE)
is
 lv_transmission_type varchar2(10);
 lv_year hrm_elm_transmission.elm_year%type;
begin
  select C_ELM_TRANSMISSION_TYPE, ELM_YEAR
    into lv_transmission_type, lv_year
    from HRM_ELM_TRANSMISSION
    where HRM_ELM_TRANSMISSION_ID = in_transmission_id;

  for tpl_employee in (
    select distinct C.HRM_EMPLOYEE_ID
      from HRM_EMPLOYEE_CONST C,
           HRM_CONTROL_ELEMENTS E,
           HRM_ELM_RECIPIENT R,
           HRM_CODE_TABLE T,
           HRM_CONTROL_LIST L
     where R.HRM_CONTROL_LIST_ID = E.HRM_CONTROL_LIST_ID
       and C.HRM_CONSTANTS_ID = E.HRM_CONTROL_ELEMENTS_ID
       and C.HRM_CODE_TABLE_ID = T.HRM_CODE_TABLE_ID
       and T.COD_CODE != 'N/A'
       and E.COE_BOX = 'CODE'
       and R.HRM_ELM_TRANSMISSION_ID = in_transmission_id
       and E.HRM_CONTROL_LIST_ID = L.HRM_CONTROL_LIST_ID
       and (( lv_transmission_type ='2' and
            -- Mutation : on charge les employés entrants ou sortants
             Exists(select 1 from HRM_IN_OUT
                     where HRM_EMPLOYEE_ID = C.HRM_EMPLOYEE_ID
                       and C_IN_OUT_CATEGORY = '3'
                       and (trunc(id_valid_on,'month')= trunc(ino_in,'month') or
                            trunc(id_valid_on,'month')= last_day(ino_out)+1
                           )
                   )
           )
             or
            -- Déclaration annuelle et synchronisation : on charge tous les employés présents dans l'année
            (lv_transmission_type in ('1','3') and
             C_CONTROL_LIST_TYPE = '116' and
             Exists(select 1 from HRM_IN_OUT
                     where HRM_EMPLOYEE_ID = C.HRM_EMPLOYEE_ID
                       and C_IN_OUT_CATEGORY = '3'
                       and to_date('01.01.'||lv_year,'dd.mm.yyyy') between Trunc(INO_IN,'year') and Nvl(INO_OUT, id_valid_on)) )
           )
       and not Exists(select 1 from HRM_LPP_EMP_CALC
                      where HRM_PERSON_ID = C.HRM_EMPLOYEE_ID
                        and HRM_ELM_TRANSMISSION_ID = in_transmission_id)
  ) loop
    hrm_prc_elm_lpp.LoadSalary(
      in_transmission_id, id_valid_on,
      tpl_employee.HRM_EMPLOYEE_ID);
  end loop;
end;

procedure CopySalary(
  in_from_transmission_id IN hrm_elm_transmission.hrm_elm_transmission_id%TYPE,
  in_to_transmission_id IN hrm_elm_transmission.hrm_elm_transmission_id%TYPE)
is
  ln_from_emp_calc_id hrm_lpp_emp_calc.hrm_lpp_emp_calc_id%TYPE;
  ln_to_emp_calc_id hrm_lpp_emp_calc.hrm_lpp_emp_calc_id%TYPE;
  ld_valid_on hrm_elm_transmission.elm_valid_as_of%type;
begin
  select ELM_VALID_AS_OF
  into ld_valid_on
  from HRM_ELM_TRANSMISSION
  where HRM_ELM_TRANSMISSION_ID = in_to_transmission_id;

  for tpl_employee in (
    select distinct C.HRM_EMPLOYEE_ID
      from HRM_EMPLOYEE_CONST C,
           HRM_CONTROL_ELEMENTS E,
           HRM_ELM_RECIPIENT R,
           HRM_CODE_TABLE T
     where R.HRM_CONTROL_LIST_ID = E.HRM_CONTROL_LIST_ID
       and C.HRM_CONSTANTS_ID = E.HRM_CONTROL_ELEMENTS_ID
       and C.HRM_CODE_TABLE_ID = T.HRM_CODE_TABLE_ID
       and T.COD_CODE != 'N/A'
       and E.COE_BOX = 'CODE'
       and R.HRM_ELM_TRANSMISSION_ID = in_from_transmission_id
       and Exists(select 1 from HRM_IN_OUT
                  where HRM_EMPLOYEE_ID = C.HRM_EMPLOYEE_ID
                    and C_IN_OUT_CATEGORY = '3'
                    and ld_valid_on between INO_IN and Nvl(INO_OUT, ld_valid_on))
  ) loop
    hrm_prc_elm_lpp.DeleteSalary(in_to_transmission_id, tpl_employee.HRM_EMPLOYEE_ID);

    ln_from_emp_calc_id := null;
    begin
      select HRM_LPP_EMP_CALC_ID
        into ln_from_emp_calc_id
        from HRM_LPP_EMP_CALC
       where HRM_ELM_TRANSMISSION_ID = in_from_transmission_id
         and HRM_PERSON_ID = tpl_employee.HRM_EMPLOYEE_ID;
    exception
      when NO_DATA_FOUND then null;
    end;

    if (ln_from_emp_calc_id is not null) then
      select init_id_seq.nextval
        into ln_to_emp_calc_id
        from DUAL;
      insert into HRM_LPP_EMP_CALC(
        HRM_LPP_EMP_CALC_ID,
        HRM_ELM_TRANSMISSION_ID,
        HRM_PERSON_ID,
        LPP_VALID_ON,
        LPP_YEARLY_AMOUNT,
        A_DATECRE,
        A_IDCRE)
      (select ln_to_emp_calc_id,
              in_to_transmission_id,
              HRM_PERSON_ID,
              LPP_VALID_ON,
              LPP_YEARLY_AMOUNT,
              Sysdate,
              pcs.pc_public.GetUserIni
         from HRM_LPP_EMP_CALC
        where HRM_ELM_TRANSMISSION_ID = in_from_transmission_id
          and HRM_PERSON_ID = tpl_employee.HRM_EMPLOYEE_ID);

      insert into HRM_LPP_EMP_CALC_DETAIL(
        HRM_LPP_EMP_CALC_DETAIL_ID,
        HRM_LPP_EMP_CALC_ID,
        HRM_PERSON_ID,
        HRM_ELEMENTS_ROOT_ID,
        HRM_IN_OUT_ID,
        C_HRM_LPP_REF_TYPE,
        LPP_MONTHLY_AMOUNT,
        LPP_FACTOR,
        LPP_REF_AMOUNT)
      (select init_id_seq.nextval,
              ln_to_emp_calc_id,
              HRM_PERSON_ID,
              HRM_ELEMENTS_ROOT_ID,
              HRM_IN_OUT_ID,
              C_HRM_LPP_REF_TYPE,
              LPP_MONTHLY_AMOUNT,
              LPP_FACTOR,
              LPP_REF_AMOUNT
         from HRM_LPP_EMP_CALC_DETAIL
        where HRM_LPP_EMP_CALC_ID = ln_from_emp_calc_id);
     end if;
   end loop;
end;

procedure DeleteSalary(
  in_transmission_id IN hrm_elm_transmission.hrm_elm_transmission_id%TYPE,
  in_employee_id IN hrm_person.hrm_person_id%TYPE)
is
  ln_lpp_emp_calc_id hrm_lpp_emp_calc.hrm_lpp_emp_calc_id%TYPE;
begin
  begin
    select HRM_LPP_EMP_CALC_ID
      into ln_lpp_emp_calc_id
      from HRM_LPP_EMP_CALC
     where HRM_ELM_TRANSMISSION_ID = in_transmission_id
       and HRM_PERSON_ID = in_employee_id;

    delete HRM_LPP_EMP_CALC_DETAIL where HRM_LPP_EMP_CALC_ID = ln_lpp_emp_calc_id;
    delete HRM_LPP_EMP_CALC where HRM_LPP_EMP_CALC_ID = ln_lpp_emp_calc_id;
  exception
    when NO_DATA_FOUND then null;
  end;
end;

procedure DeleteSalary(
  in_transmission_id IN hrm_elm_transmission.hrm_elm_transmission_id%TYPE)
is
begin
    for tmp_lpp_emp_calc in (select HRM_LPP_EMP_CALC_ID
                                 from HRM_LPP_EMP_CALC
                                where HRM_ELM_TRANSMISSION_ID = in_transmission_id) loop
      delete HRM_LPP_EMP_CALC_DETAIL where HRM_LPP_EMP_CALC_ID = tmp_lpp_emp_calc.HRM_LPP_EMP_CALC_ID;
      delete HRM_LPP_EMP_CALC where HRM_LPP_EMP_CALC_ID = tmp_lpp_emp_calc.HRM_LPP_EMP_CALC_ID;
    end loop;
end;

END HRM_PRC_ELM_LPP;
