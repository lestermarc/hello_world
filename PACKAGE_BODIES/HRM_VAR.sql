--------------------------------------------------------
--  DDL for Package Body HRM_VAR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_VAR" 
/**
 * Package pour le calcul des salaires.
 *
 * @version 1.0
 * @date 10.1999
 * @author jsomers
 * @author spfister
 * @author ireber
 * @author pvogel
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
as
  GCD_MAX_VALIDITY constant date                                        := to_date('31.12.2022', 'dd.mm.yyyy');
  -- Décompte par défaut sélectioné
  gn_PaySelected            hrm_salary_sheet.hrm_salary_sheet_id%type   := 1;
  -- Définition des exceptions utilisées en interne
  ex_ventil_exists          exception;
  ex_payment_exists         exception;
  ex_not_last_pay           exception;
  ex_taxsource_declared     exception;

  function get_PaySelected
    return hrm_salary_sheet.hrm_salary_sheet_id%type
  is
  begin
    return gn_PaySelected;
  end;

  procedure set_paySelected(SalarySheetId in hrm_salary_sheet.hrm_salary_sheet_id%type)
  is
  begin
    gn_PaySelected  := SalarySheetId;
  end;

  procedure get_Constant_Validity(vConFrom out nocopy date, vConTo out nocopy date, vElemId in hrm_constants.hrm_constants_id%type)
  is
  begin
    select con_from
         , con_to
      into vConFrom
         , vConTo
      from hrm_constants
     where hrm_constants_id = vElemId;
  exception
    when no_data_found then
      vConFrom  := sysdate;
      vConTo    := vConFrom + 365;
  end;

  procedure set_Additional_Fields(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
  is
  begin
    -- Updates History_detail with Link1
    update Hrm_History_Detail a
       set (Acs_financial_currency_id, His_Currency_Value, His_Ref_Value, His_ZL) =
             (select b.currency
                   , b.ExValue
                   , b.refValue
                   , b.ZL
                from v_hrm_elements_link1 b
               where a.hrm_elements_id = b.Main_id
                 and b.empid = a.hrm_employee_id
                 and b.currency is not null)
     where a.hrm_employee_id = vEmpId
       and a.hrm_salary_sheet_id = vSheet
       and a.his_pay_num = vPayNum
       and exists(
             select 1
               from v_hrm_elements_link1 b
              where a.hrm_elements_id = b.Main_id
                and a.hrm_employee_id = b.empid
                and a.hrm_employee_id = vEmpId
                and a.his_pay_num = vPayNum
                and a.hrm_salary_sheet_id = vSheet
                and b.currency is not null);

    -- Updates History_detail with link2
    update Hrm_History_Detail a
       set (Acs_financial_currency_id, His_Currency_Value, His_Ref_Value, His_ZL) = (select b.currency
                                                                                          , b.ExValue
                                                                                          , b.refValue
                                                                                          , b.ZL
                                                                                       from v_hrm_elements_link2 b
                                                                                      where a.hrm_elements_id = b.Main_id
                                                                                        and b.empid = a.hrm_employee_id)
     where a.hrm_employee_id = vEmpId
       and a.hrm_salary_sheet_id = vSheet
       and a.his_pay_num = vPayNum
       and exists(
             select 1
               from v_hrm_elements_link2 b
              where a.hrm_elements_id = b.Main_id
                and a.hrm_employee_id = b.empid
                and a.hrm_employee_id = vEmpId
                and a.his_pay_num = vPayNum
                and a.hrm_salary_sheet_id = vSheet);

    -- insert history_detail_sup with Link1
    insert into Hrm_History_Detail_Sup
                (hrm_history_detail_id
               , hds_Code
               , hds_Text
               , hds_override
               , hds_base_amount
               , hds_per_rate
               , hds_rate
                )
      select a.hrm_history_detail_id
           , b.Main_code
           , b.Text
           , b.Override
           , b.baseamount
           , b.perrate
           , b.rate
        from hrm_history_detail a
           , v_hrm_elements_link1 b
       where a.hrm_employee_id = vEmpId
         and a.his_pay_num = vPayNum
         and a.hrm_salary_sheet_id = vSheet
         and b.empid = a.hrm_employee_id
         and a.hrm_elements_id = b.main_id
         and (    (b.Text is not null)
              or (b.baseAmount is not null) );

    -- insert history_detail_sup with Link2
    insert into Hrm_History_Detail_Sup
                (hrm_history_detail_id
               , hds_Code
               , hds_Text
               , hds_override
               , hds_base_amount
               , hds_per_rate
               , hds_rate
                )
      select a.hrm_history_detail_id
           , b.Main_code
           , b.Text
           , b.Override
           , b.baseamount
           , b.perrate
           , b.rate
        from hrm_history_detail a
           , v_hrm_elements_link2 b
       where a.hrm_employee_id = vEmpId
         and a.his_pay_num = vPayNum
         and a.hrm_salary_sheet_id = vSheet
         and b.empid = a.hrm_employee_id
         and a.hrm_elements_id = b.main_id
         and (    (b.Text is not null)
              or (b.baseAmount is not null) );

    insert into hrm_history_detail_break
                (hrm_history_detail_id
               , eeb_Sequence
               , eeb_Time_Ratio
               , eeb_Base_Amount
               , eeb_rate
               , eeb_Per_Rate
               , eeb_value
               , eeb_ratio_group
               , eeb_Is_Break_Debit
               , eeb_Is_Break_Credit
               , eeb_D_CGBase
               , eeb_C_CGBase
               , eeb_DivBase
               , eeb_CPNBase
               , eeb_CDABase
               , eeb_PFBase
               , eeb_PJBase
               , Dic_department_id
               , job_code
                )
      select a.hrm_history_detail_id
           , hrm_history_detail_seq.nextval eeb_sequence
           , c.eeb_Time_Ratio
           , c.eeb_Base_Amount
           , c.eeb_rate
           , c.eeb_Per_Rate
           , sign(a.his_pay_sum_val) * abs(c.eeb_value)
           , c.eeb_ratio_group
           , c.eeb_Is_Break_Debit
           , c.eeb_Is_Break_Credit
           , c.eeb_D_CGBase
           , c.eeb_C_CGBase
           , c.eeb_DivBase
           , c.eeb_CPNBase
           , c.eeb_CDABase
           , c.eeb_PFBase
           , c.eeb_PJBase
           , c.Dic_department_id
           , d.job_code
        from hrm_history_detail a
           , v_hrm_elements_link1 b
           , hrm_employee_elem_break c
           , hrm_job d
       where a.hrm_employee_id = vEmpId
         and a.his_pay_num = vPayNum
         and a.hrm_salary_sheet_id = vSheet
         and b.empid = a.hrm_employee_id
         and a.hrm_elements_id = b.main_id
         and b.EmpElemId = c.hrm_emp_elements_id
         and c.hrm_job_id = d.hrm_job_id;

    insert into hrm_history_detail_break
                (hrm_history_detail_id
               , eeb_Sequence
               , eeb_Time_Ratio
               , eeb_Base_Amount
               , eeb_rate
               , eeb_Per_Rate
               , eeb_value
               , eeb_ratio_group
               , eeb_Is_Break_Debit
               , eeb_Is_Break_Credit
               , eeb_D_CGBase
               , eeb_C_CGBase
               , eeb_DivBase
               , eeb_CPNBase
               , eeb_CDABase
               , eeb_PFBase
               , eeb_PJBase
               , Dic_department_id
               , job_code
                )
      select a.hrm_history_detail_id
           , hrm_history_detail_seq.nextval eeb_sequence
           , c.eeb_Time_Ratio
           , c.eeb_Base_Amount
           , c.eeb_rate
           , c.eeb_Per_Rate
           , sign(a.his_pay_sum_val) * abs(c.eeb_value)
           , c.eeb_ratio_group
           , c.eeb_Is_Break_Debit
           , c.eeb_Is_Break_Credit
           , c.eeb_D_CGBase
           , c.eeb_C_CGBase
           , c.eeb_DivBase
           , c.eeb_CPNBase
           , c.eeb_CDABase
           , c.eeb_PFBase
           , c.eeb_PJBase
           , c.Dic_department_id
           , d.job_code
        from hrm_history_detail a
           , v_hrm_elements_link2 b
           , hrm_employee_elem_break c
           , hrm_job d
       where a.hrm_employee_id = vEmpId
         and a.his_pay_num = vPayNum
         and a.hrm_salary_sheet_id = vSheet
         and b.empid = a.hrm_employee_id
         and a.hrm_elements_id = b.main_id
         and b.EmpElemId = c.hrm_emp_elements_id
         and c.hrm_job_id = d.hrm_job_id;

    -- TO PREPARE BREAKDOWN
    insert into hrm_history_detail_break
                (hrm_history_detail_id
               , eeb_Sequence
               , eeb_Time_Ratio
               , eeb_Base_Amount
               , eeb_rate
               , eeb_Per_Rate
               , eeb_value
               , eeb_ratio_group
               , eeb_Is_Break_Debit
               , eeb_Is_Break_Credit
               , eeb_D_CGBase
               , eeb_C_CGBase
               , eeb_DivBase
               , eeb_CPNBase
               , eeb_CDABase
               , eeb_PFBase
               , eeb_PJBase
               , Dic_department_id
               , job_code
                )
      select B.hrm_history_detail_id
           , hrm_history_detail_seq.nextval eeb_sequence
           , 0 eeb_Time_Ratio
           , 0 eeb_Base_Amount
           , 0 eeb_rate
           , 0 eeb_Per_Rate
           , b.his_pay_sum_val * rate
           , a.eeb_ratio_group
           , null eeb_Is_Break_Debit
           , null eeb_Is_Break_Credit
           , a.eeb_D_CGBase
           , a.eeb_C_CGBase
           , a.eeb_DivBase
           , null eeb_CPNBase
           , null eeb_CDABase
           , null eeb_PFBase
           , null eeb_PJBase
           , a.Dic_department_id
           , a.job_code
        from (select det.eeb_sequence
                   , b.eeb_ratio_group
                   , det.eeb_value / b.tot Rate
                   , det.eeb_d_cgbase
                   , det.eeb_c_cgbase
                   , det.eeb_divbase
                   , det.dic_department_id
                   , det.job_code
                from (select   eeb_ratio_group
                             , sum(eeb_value) tot
                          from hrm_history_detail_break t
                             , hrm_history_detail tt
                         where tt.hrm_employee_id = vEmpId
                           and tt.his_pay_num = vPayNum
                           and tt.hrm_salary_sheet_id = vSheet
                           and t.hrm_history_detail_id = tt.hrm_history_detail_id
                      group by eeb_ratio_group) B
                   , (select   rv.eeb_sequence
                             , rv.eeb_ratio_group
                             , rv.eeb_value
                             , rv.eeb_d_cgbase
                             , rv.eeb_c_cgbase
                             , rv.eeb_divbase
                             , rv.dic_department_id
                             , rv.job_code
                          from hrm_history_detail_break rv
                             , hrm_history_detail rva
                         where rva.hrm_employee_id = vEmpId
                           and rva.his_pay_num = vPayNum
                           and rva.hrm_salary_sheet_id = vSheet
                           and rva.hrm_history_detail_id = rv.hrm_history_detail_id
                      group by eeb_ratio_group
                             , eeb_value
                             , eeb_d_cgbase
                             , eeb_c_cgbase
                             , eeb_divbase
                             , dic_department_id
                             , job_code
                             , eeb_sequence) det
               where det.eeb_ratio_group = B.eeb_ratio_group) A
           , hrm_history_detail b
           , hrm_elements e
       where b.hrm_employee_id = vEmpId
         and b.his_pay_num = vPayNum
         and b.hrm_salary_sheet_id = vSheet
         and b.hrm_elements_id = e.hrm_elements_id
         and e.ele_use_ratio_group = a.eeb_ratio_group
         and b.hrm_history_detail_id not in(select hrm_history_detail_id
                                              from hrm_history_detail_break);
  end;

  procedure set_Additional_Fields_New(
    in_employee_id   in hrm_person.hrm_person_id%type
  , in_sheet_id      in hrm_salary_sheet.hrm_salary_sheet_id%type
  , in_paynum        in hrm_history_detail.his_pay_num%type
  , in_break_version in integer
  )
  is
    ln_calc_version integer;
  begin
    -- convertion implicite!
    ln_calc_version  := pcs.pc_config.GetConfig('HRM_CALCVERSION', pcs.PC_I_LIB_SESSION.getCompanyId, pcs.PC_I_LIB_SESSION.getConliId);

    if (ln_calc_version != 3) then
      -- Update History_Detail with Employee ElemConst link
      update HRM_HISTORY_DETAIL H
         set (ACS_FINANCIAL_CURRENCY_ID, HIS_CURRENCY_VALUE, HIS_REF_VALUE, HIS_ZL) =
               (select CURRENCY
                     , EXVALUE
                     , REFVALUE
                     , ZL
                  from V_HRM_EMP_ELEMENTS_LINK
                 where EMPID = H.HRM_EMPLOYEE_ID
                   and MAIN_ID = H.HRM_ELEMENTS_ID
                   and SHEET_ID = in_sheet_id
                   and (   CURRENCY is not null
                        or ZL is not null) )
       where H.HRM_EMPLOYEE_ID = in_employee_id
         and H.HRM_SALARY_SHEET_ID = in_sheet_id
         and H.HIS_PAY_NUM = in_paynum
         and exists(select 1
                      from V_HRM_EMP_ELEMENTS_LINK
                     where EMPID = H.HRM_EMPLOYEE_ID
                       and MAIN_ID = H.HRM_ELEMENTS_ID
                       and SHEET_ID = in_sheet_id
                       and (   CURRENCY is not null
                            or ZL is not null) );

      -- Insert History_Detail_Sup with Employee ElemConst link
      insert into HRM_HISTORY_DETAIL_SUP
                  (HRM_HISTORY_DETAIL_ID
                 , HDS_CODE
                 , HDS_TEXT
                 , HDS_OVERRIDE
                 , HDS_BASE_AMOUNT
                 , HDS_PER_RATE
                 , HDS_RATE
                 , HDS_CURRENCY
                  )
        select H.HRM_HISTORY_DETAIL_ID
             , L.MAIN_CODE
             , L.TEXT
             , L.OVERRIDE
             , L.BASEAMOUNT
             , L.PERRATE
             , L.RATE
             , (select CURRENCY
                  from V_ACS_FINANCIAL_CURRENCY
                 where ACS_FINANCIAL_CURRENCY_ID = L.CURRENCY) HDS_CURRENCY
          from HRM_HISTORY_DETAIL H
             , V_HRM_EMP_ELEMENTS_LINK L
         where L.EMPID = in_employee_id
           and L.SHEET_ID = in_sheet_id
           and (   L.TEXT is not null
                or L.BASEAMOUNT is not null
                or L.CURRENCY is not null)
           and H.HRM_EMPLOYEE_ID = L.EMPID
           and H.HRM_ELEMENTS_ID = L.MAIN_ID
           and H.HIS_PAY_NUM = in_paynum
           and H.HRM_SALARY_SHEET_ID = in_sheet_id;

      insert into HRM_HISTORY_DETAIL_BREAK
                  (HRM_HISTORY_DETAIL_ID
                 , EEB_SEQUENCE
                 , EEB_TIME_RATIO
                 , EEB_BASE_AMOUNT
                 , EEB_RATE
                 , EEB_PER_RATE
                 , EEB_VALUE
                 , EEB_RATIO_GROUP
                 , EEB_IS_BREAK_DEBIT
                 , EEB_IS_BREAK_CREDIT
                 , EEB_D_CGBASE
                 , EEB_C_CGBASE
                 , EEB_DIVBASE
                 , EEB_CPNBASE
                 , EEB_CDABASE
                 , EEB_PFBASE
                 , EEB_PJBASE
                 , EEB_SHIFT
                 , EEB_RCO_TITLE
                 , DIC_DEPARTMENT_ID
                 , JOB_CODE
                  )
        select A.HRM_HISTORY_DETAIL_ID
             , hrm_history_detail_seq.nextval EEB_SEQUENCE
             , C.EEB_TIME_RATIO
             , C.EEB_BASE_AMOUNT
             , C.EEB_RATE
             , C.EEB_PER_RATE
             , sign(A.HIS_PAY_SUM_VAL) * abs(C.EEB_VALUE) EEB_VALUE
             , C.EEB_RATIO_GROUP
             , C.EEB_IS_BREAK_DEBIT
             , C.EEB_IS_BREAK_CREDIT
             , C.EEB_D_CGBASE
             , C.EEB_C_CGBASE
             , C.EEB_DIVBASE
             , C.EEB_CPNBASE
             , C.EEB_CDABASE
             , C.EEB_PFBASE
             , C.EEB_PJBASE
             , C.EEB_SHIFT
             , C.EEB_RCO_TITLE
             , C.DIC_DEPARTMENT_ID
             , (select JOB_CODE
                  from HRM_JOB
                 where HRM_JOB_ID = C.HRM_JOB_ID) JOB_CODE
          from HRM_EMPLOYEE_ELEM_BREAK C
             , HRM_HISTORY_DETAIL A
             , V_HRM_ELEMENTS_NEW_LINK1 B
         where B.EMPID = in_employee_id
           and A.HRM_EMPLOYEE_ID = B.EMPID
           and A.HRM_ELEMENTS_ID = B.MAIN_ID
           and A.HIS_PAY_NUM = in_paynum
           and A.HRM_SALARY_SHEET_ID = in_sheet_id
           and C.HRM_EMP_ELEMENTS_ID = B.EMPELEMID;

      insert into HRM_HISTORY_DETAIL_BREAK
                  (HRM_HISTORY_DETAIL_ID
                 , EEB_SEQUENCE
                 , EEB_TIME_RATIO
                 , EEB_BASE_AMOUNT
                 , EEB_RATE
                 , EEB_PER_RATE
                 , EEB_VALUE
                 , EEB_RATIO_GROUP
                 , EEB_IS_BREAK_DEBIT
                 , EEB_IS_BREAK_CREDIT
                 , EEB_D_CGBASE
                 , EEB_C_CGBASE
                 , EEB_DIVBASE
                 , EEB_CPNBASE
                 , EEB_CDABASE
                 , EEB_PFBASE
                 , EEB_PJBASE
                 , EEB_SHIFT
                 , EEB_RCO_TITLE
                 , DIC_DEPARTMENT_ID
                 , JOB_CODE
                  )
        select A.HRM_HISTORY_DETAIL_ID
             , hrm_history_detail_seq.nextval EEB_SEQUENCE
             , C.EEB_TIME_RATIO
             , C.EEB_BASE_AMOUNT
             , C.EEB_RATE
             , C.EEB_PER_RATE
             , sign(A.HIS_PAY_SUM_VAL) * abs(C.EEB_VALUE)
             , C.EEB_RATIO_GROUP
             , C.EEB_IS_BREAK_DEBIT
             , C.EEB_IS_BREAK_CREDIT
             , C.EEB_D_CGBASE
             , C.EEB_C_CGBASE
             , C.EEB_DIVBASE
             , C.EEB_CPNBASE
             , C.EEB_CDABASE
             , C.EEB_PFBASE
             , C.EEB_PJBASE
             , C.EEB_SHIFT
             , C.EEB_RCO_TITLE
             , C.DIC_DEPARTMENT_ID
             , (select JOB_CODE
                  from HRM_JOB
                 where HRM_JOB_ID = C.HRM_JOB_ID) JOB_CODE
          from HRM_EMPLOYEE_ELEM_BREAK C
             , HRM_HISTORY_DETAIL A
             , V_HRM_ELEMENTS_NEW_LINK2 B
         where B.EMPID = in_employee_id
           and A.HRM_EMPLOYEE_ID = B.EMPID
           and A.HRM_ELEMENTS_ID = B.MAIN_ID
           and A.HIS_PAY_NUM = in_paynum
           and A.HRM_SALARY_SHEET_ID = in_sheet_id
           and C.HRM_EMP_ELEMENTS_ID = B.EMPELEMID;
    else   -- (ln_calc_version = 3)
      -- Update History_Detail with Employee ElemConst link
      update HRM_HISTORY_DETAIL H
         set (ACS_FINANCIAL_CURRENCY_ID, HIS_CURRENCY_VALUE, HIS_REF_VALUE, HIS_ZL) =
               (select (select ACS_FINANCIAL_CURRENCY_ID
                          from V_ACS_FINANCIAL_CURRENCY
                         where CURRENCY = L.CURRENCY) CURRENCY
                     , EXVALUE
                     , REFVALUE
                     , ZL
                  from V_HRM_EMP_CUST_SAL_ELEM_LINK L
                 where EMPID = H.HRM_EMPLOYEE_ID
                   and MAIN_ID = H.HRM_ELEMENTS_ID
                   and (   CURRENCY is not null
                        or ZL is not null) )
       where H.HRM_EMPLOYEE_ID = in_employee_id
         and H.HRM_SALARY_SHEET_ID = in_sheet_id
         and H.HIS_PAY_NUM = in_paynum
         and exists(select 1
                      from V_HRM_EMP_CUST_SAL_ELEM_LINK
                     where EMPID = H.HRM_EMPLOYEE_ID
                       and MAIN_ID = H.HRM_ELEMENTS_ID
                       and (   CURRENCY is not null
                            or ZL is not null) );

      -- Insert History_Detail_Sup with Employee ElemConst link
      insert into HRM_HISTORY_DETAIL_SUP
                  (HRM_HISTORY_DETAIL_ID
                 , HDS_CODE
                 , HDS_TEXT
                 , HDS_OVERRIDE
                 , HDS_BASE_AMOUNT
                 , HDS_PER_RATE
                 , HDS_RATE
                 , HDS_CURRENCY
                  )
        select H.HRM_HISTORY_DETAIL_ID
             , L.MAIN_CODE
             , L.TEXT
             , L.OVERRIDE
             , L.BASEAMOUNT
             , L.PERRATE
             , L.RATE
             , L.CURRENCY
          from HRM_HISTORY_DETAIL H
             , V_HRM_EMP_CUST_SAL_ELEM_LINK L
         where L.EMPID = in_employee_id
           and (   L.TEXT is not null
                or L.BASEAMOUNT is not null
                or L.CURRENCY is not null)
           and H.HRM_EMPLOYEE_ID = L.EMPID
           and H.HRM_ELEMENTS_ID = L.MAIN_ID
           and H.HIS_PAY_NUM = in_paynum
           and H.HRM_SALARY_SHEET_ID = in_sheet_id;

      insert into HRM_HISTORY_DETAIL_BREAK
                  (HRM_HISTORY_DETAIL_ID
                 , EEB_SEQUENCE
                 , EEB_TIME_RATIO
                 , EEB_BASE_AMOUNT
                 , EEB_RATE
                 , EEB_PER_RATE
                 , EEB_VALUE
                 , EEB_RATIO_GROUP
                 , EEB_IS_BREAK_DEBIT
                 , EEB_IS_BREAK_CREDIT
                 , EEB_D_CGBASE
                 , EEB_C_CGBASE
                 , EEB_DIVBASE
                 , EEB_CPNBASE
                 , EEB_CDABASE
                 , EEB_PFBASE
                 , EEB_PJBASE
                 , EEB_SHIFT
                 , EEB_RCO_TITLE
                 , DIC_DEPARTMENT_ID
                 , JOB_CODE
                  )
        select A.HRM_HISTORY_DETAIL_ID
             , hrm_history_detail_seq.nextval EEB_SEQUENCE
             , C.EEB_TIME_RATIO
             , C.EEB_BASE_AMOUNT
             , C.EEB_RATE
             , C.EEB_PER_RATE
             , sign(A.HIS_PAY_SUM_VAL) * abs(C.EEB_VALUE)
             , C.EEB_RATIO_GROUP
             , C.EEB_IS_BREAK_DEBIT
             , C.EEB_IS_BREAK_CREDIT
             , C.EEB_D_CGBASE
             , C.EEB_C_CGBASE
             , C.EEB_DIVBASE
             , C.EEB_CPNBASE
             , C.EEB_CDABASE
             , C.EEB_PFBASE
             , C.EEB_PJBASE
             , C.EEB_SHIFT
             , C.EEB_RCO_TITLE
             , C.DIC_DEPARTMENT_ID
             , (select JOB_CODE
                  from HRM_JOB
                 where HRM_JOB_ID = C.HRM_JOB_ID) JOB_CODE
          from HRM_EMPLOYEE_ELEM_BREAK C
             , HRM_HISTORY_DETAIL A
             , V_HRM_EMP_CUST_SAL_ELEM_LINK L
         where L.EMPID = in_employee_id
           and A.HRM_EMPLOYEE_ID = L.EMPID
           and A.HRM_ELEMENTS_ID = L.MAIN_ID
           and A.HIS_PAY_NUM = in_paynum
           and A.HRM_SALARY_SHEET_ID = in_sheet_id
           and A.HRM_EMPLOYEE_ID = C.HRM_PERSON_ID
           and C.HRM_ELEMENTS_ID = L.link2_ID;
    end if;
  end;

  procedure set_PayDefinitive(
    vEmpId        in hrm_person.hrm_person_id%type
  , vSheet        in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum       in hrm_history_detail.his_pay_num%type
  , vBreakVersion in integer
  )
/**
*  Changes flags to definitive and update necessary tables
*  @param vEmpid: Employee Number
*   vSheet: Salarary sheet id
*   vPayNum: Incremental number of pays for this employee
*/
  is
    lnCheckBreakVal     binary_integer;
    inEmpTaxSeq         number;
    lnTaxSourceLedgerID HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type;
  begin
    select init_id_seq.nextval
      into inEmpTaxSeq
      from dual;

    -- Contrôle des données de répartition pour HRM_BREAK_VERSION = 1
    case vBreakVersion
      when 1 then
        select count(*)
          into lnCheckBreakVal
          from dual
         where exists(
                 select 1
                   from HRM_HISTORY_DETAIL_BREAK A
                      , HRM_HISTORY_DETAIL B
                  where B.HRM_EMPLOYEE_ID = vEmpId
                    and B.HIS_PAY_NUM = vPayNum
                    and B.HRM_SALARY_SHEET_ID = vSheet
                    and A.HRM_HISTORY_DETAIL_ID = B.HRM_HISTORY_DETAIL_ID
                    and A.EEB_RATIO_GROUP + 0 = 1   -- Forcer l'utilisation du bon index
                                                 );

        if (lnCheckBreakVal = 0) then
          raise_application_error(-20110, 'Aucune donnée de répartition');
        end if;
      when 4 then
        select count(*)
          into lnCheckBreakVal
          from dual
         where exists(select 1
                        from HRM_PERSON_JOB
                       where HRM_PERSON_ID = vEmpId
                         and hrm_date.validForActivePeriod(PEJ_FROM, nvl(PEJ_TO, hrm_date.ActivePeriodEndDate) ) = 1);

        if (lnCheckBreakVal = 0) then
          raise_application_error(-20111, 'Aucun poste pour la période active');
        end if;
      else
        null;
    end case;

    -- Contrôle si correction IS non déclarée pour un employé soumis à l'IS qui est parti
--     if     HRM_LIB_TAXSOURCE_LEDGER.IsEmployeePaySourceTaxed(iEmployeeID => vEmpId, iPayNum => vPayNum) = 1
--        and hrm_date.HasInOutInActivePeriod(vEmpId) = 0
--        and hrm_lib_taxsource.HasActiveTaxSource(vEmpId) = 0
--        and HRM_LIB_TAXSOURCE_LEDGER.HasUndeclaredEntries(vEmpId) = 1 then
--       raise_application_error
--                              (-20113
--                             , PCS.PC_FUNCTIONS.TranslateWord('Il existe des corrections dans le journal de l''impôt à la source qui n''ont pas été déclarés.')
--                              );
--     end if;

    -- Updates hrm_history_detail
    update hrm_history_detail
       set his_definitive = 1
         , his_paid = 1
     where hrm_employee_id = vEmpId
       and hrm_salary_sheet_id = vSheet
       and his_pay_num = vPayNum;

    -- Updates hrm_history
    update hrm_history
       set hit_definitive = 1
     where hrm_employee_id = vEmpid
       and hrm_salary_sheet_id = vSheet
       and hit_pay_num = vPayNum;

    -- updates hrm_Pay_Log
    -- Passage des record en définitif
    update hrm_Pay_log
       set pay_definitive = 1
     where hrm_employee_id = vEmpId
       and hrm_salary_sheet_id = vSheet
       and pay_Salary_sheet_num = vPayNum;

    -- Mise à jour du N° contrôle de clé RIB
    update hrm_pay_log p
       set pay_acc_control =
             (select fin_account_control
                from hrm_financial_ref f
               where f.hrm_employee_id = p.hrm_employee_id
                 and f.acs_financial_currency_id = p.acs_financial_currency_id
                 and f.fin_account_number = p.pay_acc_num
                 and f.fin_account_control is not null)
     where p.hrm_employee_id = vEmpId
       and p.hrm_salary_sheet_id = vSheet
       and p.pay_Salary_sheet_num = vPayNum
       and exists(
             select hrm_employee_id
               from hrm_financial_ref f
              where f.hrm_employee_id = p.hrm_employee_id
                and f.acs_financial_currency_id = p.acs_financial_currency_id
                and f.fin_account_number = p.pay_acc_num
                and f.fin_account_control is not null);

    -- updates and inserts Employee constants
    hrm_var.Insert_EmpConstants_Def(vEmpId, vPayNum, vSheet);

/*
  -- Changes active flag of out of date valuedates to false
  update hrm_employee_elements e
  set e.emp_Active = 0
  where e.hrm_employee_id = vEmpId and
    Trunc(e.emp_value_to, 'MM') = Trunc(hrm_date.ActivePeriod, 'MM') and
    exists(select 0 from hrm_salary_sheet_elements s
           where s.hrm_elements_id = e.hrm_elements_id and
             s.hrm_salary_sheet_id = vSheet);
  -- Changes active flag of out of date valuedates to false
  update hrm_employee_const c
  set c.emc_Active = 0
  where c.hrm_employee_id = vEmpId and
    Trunc(c.emc_value_to, 'MM') = Trunc(hrm_date.ActivePeriod, 'MM') and
    exists(select 0 from hrm_salary_sheet_elements s
           where s.hrm_elements_id = c.hrm_constants_id and
             s.hrm_salary_sheet_id = vSheet);
*/-- met à jour le numéro et la date du dernier décompte avec le dernier jour de la période.
  -- met à jour la date du dernier décompte avec paiement jrs AC
    update hrm_person a
       set emp_last_pay_num = vPayNum
         , emp_last_pay_date = hrm_date.ActivePeriodEndDate
         , emp_last_pay_date_ac = (select case
                                            when(sal_is_acompte = 0) then hrm_date.ActivePeriodEndDate
                                            else emp_last_pay_date_ac
                                          end
                                     from hrm_salary_sheet
                                    where hrm_salary_sheet_id = vSheet)
     where hrm_person_id = vEmpId;

    -- Ajout d'un certificat de salaire pour l'année de la période active (si pas déjà existant)
    HRM_PRC_PERSON_TAX.InsertPersonTax(iEmployeeID => vEmpId);

    -- Ajout d'une ligne de journalisation de l'impôt à la source
    if    HRM_FUNCTIONS.GETTAXCODE(vEmpId, hrm_date.activeperiodenddate) is not null
       or HRM_LIB_HISTORY.HasAdditionalData(vEmpId, vPayNum) = 1
       or HRM_LIB_TAXSOURCE_LEDGER.IsEmployeePaySourceTaxed(iEmployeeID => vEmpId, iPayNum => vPayNum) = 1 then
      -- Extourne du mois de départ si l'employé est partie
      if     hrm_date.HasInOutInActivePeriod(vEmpId) = 0
         and hrm_lib_taxsource.HasActiveTaxSource(vEmpId) = 0
         and HRM_LIB_HISTORY.HasAdditionalData(vEmpId, vPayNum) = 0 then
        HRM_PRC_TAXSOURCE_LEDGER.ReverseOutgoingEmployee(vEmpId);
      end if;

      HRM_PRC_TAXSOURCE_LEDGER.UpdatePayNumTaxSourceLedger(iEmployeeID => vEmpId, iPayNum => vPayNum);
      HRM_PRC_TAXSOURCE_LEDGER.InsertTaxSourceLedger(iEmployeeID => vEmpId, iPayNum => vPayNum, oTaxSourceLedgerID => lnTaxSourceLedgerID);
    end if;
  end set_PayDefinitive;

  function IsBreakDowned(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(select 1
                    from hrm_history
                   where hrm_employee_id = vEmpId
                     and hrm_salary_sheet_id = vSheet
                     and hit_pay_num = vPayNum
                     and hit_accounted != 0);

    return ln_result;
  end;

  function IsPaid(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(
             select 1
               from hrm_pay_log
              where hrm_employee_id = vEmpId
                and hrm_salary_sheet_id = vSheet
                and pay_salary_sheet_num = vPayNum
                and pay_selected != 0
                and hrm_pay_doc_id is not null);

    return ln_result;
  end;

  function IsReversal(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(select 1
                    from hrm_history
                   where hrm_employee_id = vEmpId
                     and hrm_salary_sheet_id = vSheet
                     and hit_pay_num = vPayNum
                     and hit_reversal != 0);

    return ln_result;
  end;

/**
 * Suppression d'un décompte normal définitif.
 * @param vEmpId Identifiant de l'employé.
 * @param vSheet Identifiant du décompte.
 * @param vPayNum Numéro du décompte.
 */
  procedure p_ErasePay(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
  is
  begin
    -- delete HRM_TAXSOURCE_LEDGER
    HRM_PRC_TAXSOURCE_LEDGER.DeletePayNumTaxSourceLedger(iEmployeeID => vEmpId, iPayNum => vPayNum);

    -- updates hrm_history_detail
    begin
      update hrm_history_detail
         set his_definitive = 0
           , his_paid = 0
       where hrm_employee_id = vEmpId
         and hrm_salary_sheet_id = vSheet
         and his_pay_num = vPayNum;
    exception
      when others then
        raise ex_ventil_exists;
    end;

    -- Updates hrm_history
    update hrm_history
       set hit_definitive = 0
     where hrm_employee_id = vEmpId
       and hrm_salary_sheet_id = vSheet
       and hit_pay_num = vPayNum;

    -- Updates hrm_Pay_Log
    update hrm_Pay_log
       set pay_definitive = 0
     where hrm_employee_id = vEmpId
       and hrm_salary_sheet_id = vSheet
       and pay_Salary_sheet_num = vPayNum;

    -- Remove the exported pdf (if any)
    delete      HRM_PAYSLIP
          where HRM_PERSON_ID = vEmpId
            and HRM_SALARY_SHEET_ID = vSheet
            and HPS_PAY_NUM = vPayNum
            and C_HRM_PAYSLIP_TYPE = HRM_LIB_CONSTANT.gcPayslipTypeBreakdown;

    -- updates and inserts Employee constants
    -- Rollback Constants storing sums with aged values stored in history
    -- mise à zéro des montants (dans le cas d'un premier décompte, comme
    -- la valeur n'existe pas dans hrm_history_detail, ce premier passage
    -- évite que l'on retrouve les valeurs calculées du premier décompte
    -- puisque pas mise à jour dans 2ème partie du script
    update hrm_employee_const ec
       set emc_num_value = 0
         , emc_zl = null
     where ec.hrm_employee_id = vEmpId
       and ec.emc_active = 1
       and hrm_date.ActivePeriod between ec.emc_value_from and ec.emc_value_to
       and exists(select 1
                    from hrm_constants c
                   where c.hrm_constants_id = ec.hrm_constants_id
                     and c.c_hrm_sal_const_type = 3)
       and exists(select 1
                    from hrm_salary_sheet_elements
                   where hrm_elements_id = ec.hrm_constants_id
                     and hrm_salary_sheet_id = vSheet);

    -- Mise à jour des constantes de l'employé depuis ce qui est stocké dans la table
    -- HRM_HISTORY_DETAIL Remontée des valeurs (les textes ne sont pas
    -- remontés puisque pas de risque de mise à jour du texte depuis
    -- OutCon-> Con
    update hrm_employee_const ec
       set (emc_active, emc_num_value, emc_zl) = (select 1
                                                       ,   -- EMC_ACTIVE
                                                         h.his_pay_sum_val
                                                       ,   -- EMC_NUM_VALUE
                                                         h.his_zl emc_zl   -- EMC_ZL
                                                    from hrm_history_detail h
                                                   where h.hrm_employee_id = vEmpId
                                                     and
--             h.hrm_salary_sheet_id = vSheet and
                                                         h.his_pay_num = vPayNum
                                                     and ec.hrm_constants_id = h.hrm_elements_id)
     where ec.hrm_employee_id = vEmpId
       and hrm_date.ActivePeriod between ec.emc_value_from and ec.emc_value_to
       and exists(select 1
                    from hrm_history_detail h
                   where h.hrm_employee_id = vEmpId
                     and
--                 h.hrm_salary_sheet_id = vSheet and
                         h.his_pay_num = vPayNum
                     and ec.hrm_constants_id = h.hrm_elements_id)
       and exists(select 1
                    from hrm_constants c
                   where c.hrm_constants_id = ec.hrm_constants_id
                     and c.c_hrm_sal_const_type = 3)
       and exists(select 1
                    from hrm_salary_sheet_elements
                   where hrm_elements_id = ec.hrm_constants_id
                     and hrm_salary_sheet_id = vSheet);

    -- Suppression des répartitions de ventilation si le total de la répartition
    -- est différent du montant mis à jour. Dans le cas où l'utilisateur
    -- à modifier le montant après calcul définitif.
    delete      hrm_employee_elem_break
          where hrm_emp_elements_id in(select hrm_employee_const_id
                                         from hrm_employee_const a
                                            , (select   hrm_emp_elements_id
                                                      , sum(eeb_value) TotValue
                                                   from hrm_employee_elem_break
                                               group by hrm_emp_elements_id) b
                                        where hrm_employee_id = vEmpId
                                          and hrm_employee_const_id = hrm_emp_elements_id
                                          and a.emc_num_value <> TotValue);

    -- Changes active flag of out of date valuedates to false
    /*
    update hrm_employee_elements e
    set e.emp_Active = 1
    where e.hrm_employee_id = vEmpId and
      Trunc(e.emp_value_to, 'MM') = Trunc(hrm_date.ActivePeriod, 'MM') and
      exists(select 1 from hrm_salary_sheet_elements s
             where s.hrm_elements_id = e.hrm_elements_id and
               s.hrm_salary_sheet_id = vSheet);

    -- Changes active flag of out of date valuedates to false
    update hrm_employee_const c
    set c.emc_Active = 1
    where c.hrm_employee_id = vEmpId and
      Trunc(c.emc_value_to, 'MM') = Trunc(hrm_date.ActivePeriod, 'MM') and
      exists(select 1 from hrm_salary_sheet_elements s
             where s.hrm_elements_id = c.hrm_constants_id and
               s.hrm_salary_sheet_id = vSheet);
    */

    -- update employee's last pay number and last pay date
    update hrm_person p
       set (p.emp_last_pay_num, p.emp_last_pay_date) = (select max(h.hit_pay_num)
                                                             , max(h.hit_pay_period)
                                                          from hrm_history h
                                                         where h.hrm_employee_id = vEmpId
                                                           and h.hit_definitive = 1)
     where p.hrm_person_id = vEmpId;

    -- update employee's last pay date ac
    update hrm_person p
       set p.emp_last_pay_date_ac =
                          (select max(h.hit_pay_period)
                             from hrm_history h
                                , hrm_salary_sheet s
                            where h.hrm_employee_id = vEmpId
                              and h.hit_definitive = 1
                              and h.hrm_salary_sheet_id = s.hrm_salary_sheet_id
                              and s.sal_is_acompte = 0)
     where p.hrm_person_id = vEmpId;
  end p_ErasePay;

/**
 * Suppression d'un décompte d'extourne définitif.
 * @param vEmpId Identifiant de l'employé.
 * @param vSheet Identifiant du décompte.
 * @param vPayNum Numéro du décompte.
 */
  procedure p_DeletePay(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
  is
  begin
    -- delete HRM_TAXSOURCE_LEDGER
    HRM_PRC_TAXSOURCE_LEDGER.DeletePayNumTaxSourceLedger(iEmployeeID => vEmpId, iPayNum => vPayNum);

    -- Delete hrm_history_detail
    begin
      delete      hrm_history_detail
            where hrm_employee_id = vEmpId
              and hrm_salary_sheet_id = vSheet
              and his_pay_num = vPayNum;
    exception
      when others then
        raise ex_ventil_exists;
    end;

    -- Delete hrm_history
    delete      hrm_history
          where hrm_employee_id = vEmpId
            and hrm_salary_sheet_id = vSheet
            and hit_pay_num = vPayNum;

    -- Remove the exported pdf (if any)
    delete      HRM_PAYSLIP
          where HRM_PERSON_ID = vEmpId
            and HRM_SALARY_SHEET_ID = vSheet
            and HPS_PAY_NUM = vPayNum
            and C_HRM_PAYSLIP_TYPE = HRM_LIB_CONSTANT.gcPayslipTypeBreakdown;

    -- Update previous payroll hit_reversed field
    update hrm_history
       set hit_reversed = 0
     where hrm_employee_id = vEmpId
       and hrm_salary_sheet_id = vSheet
       and hit_pay_num = vPayNum - 1;

    -- Update employee's last pay number and last pay date
    update hrm_person p
       set (p.emp_last_pay_num, p.emp_last_pay_date) = (select max(h.hit_pay_num)
                                                             , max(h.hit_pay_period)
                                                          from hrm_history h
                                                         where h.hrm_employee_id = vEmpId
                                                           and h.hit_definitive = 1)
     where p.hrm_person_id = vEmpId;

    -- update employee's last pay date ac
    update hrm_person p
       set p.emp_last_pay_date_ac =
                          (select max(h.hit_pay_period)
                             from hrm_history h
                                , hrm_salary_sheet s
                            where h.hrm_employee_id = vEmpId
                              and h.hit_definitive = 1
                              and h.hrm_salary_sheet_id = s.hrm_salary_sheet_id
                              and s.sal_is_acompte = 0)
     where p.hrm_person_id = vEmpId;
  end p_DeletePay;

  procedure set_PayDefinitiveRollBack(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
  is
  begin
    if (hrm_var.IsLastPayNumActivePeriod(vEmpId, vPayNum) = 0) then
      raise ex_not_last_pay;
    end if;

    if (hrm_var.IsPaid(vEmpId, vSheet, vPayNum) = 1) then
      raise ex_payment_exists;
    end if;

    if (hrm_var.IsBreakDowned(vEmpId, vSheet, vPayNum) = 1) then
      raise ex_ventil_exists;
    end if;

    if HRM_LIB_TAXSOURCE_LEDGER.CanDeleteTaxSourceLedger(iEmployeeID => vEmpId, iPayNum => vPayNum) = 0 then
      raise EX_TAXSOURCE_DECLARED;
    end if;

    if (hrm_var.IsReversal(vEmpId, vSheet, vPayNum) = 0) then
      p_ErasePay(vEmpId, vSheet, vPayNum);
    else
      p_DeletePay(vEmpId, vSheet, vPayNum);
    end if;
  exception
    when EX_VENTIL_EXISTS then
      raise_application_error(-20102, 'Annulation du décompte impossible, Vous devez supprimer la ventilation comptable avant de pouvoir annuler le décompte.');
    when EX_NOT_LAST_PAY then
      raise_application_error(-20103, 'Annulation du décompte impossible, le décompte n''est pas le dernier en cours.');
    when EX_PAYMENT_EXISTS then
      raise_application_error(-20104, 'Annulation du décompte impossible, le décompte est déjà payé.');
    when EX_TAXSOURCE_DECLARED then
      raise_application_error(-20105, 'Annulation du décompte impossible !' || ' ' || 'La déclaration d''impôt à la source a déjà été effectuée.');
    when others then
      raise_application_error(-20110, 'Annulation du décompte impossible');
  end;

  procedure set_PayDefinitiveReversal(
    vEmpId        in hrm_person.hrm_person_id%type
  , vSheet        in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum       in hrm_history_detail.his_pay_num%type
  , vBreakVersion in integer
  )
  is
  begin
    -- Passage en définitif du décompte
    hrm_var.set_PayDefinitive(vEmpId, vSheet, vPayNum, vBreakVersion);

    -- Update previous payroll hit_reversed field
    update hrm_history
       set hit_reversed = 1
     where hrm_employee_id = vEmpId
       and hrm_salary_sheet_id = vSheet
       and hit_pay_num =(vPayNum - 1);

    -- met à jour l'employé avec le numéro de décompte actuel et
    -- la date du dernier décompte pas extourné.
    -- la date du dernier décompte 'normal' pas extourné (dernier calcul AC)
    update hrm_person a
       set emp_last_pay_num = vPayNum
         , emp_last_pay_date = (select max(hit_pay_period)
                                  from hrm_history
                                 where hrm_employee_id = vEmpId
                                   and hit_pay_num <(vPayNum - 1) )
         , emp_last_pay_date_ac =
             (select max(h.hit_pay_period)
                from hrm_history h
                   , hrm_salary_sheet s
               where h.hrm_employee_id = vEmpId
                 and h.hit_pay_num <(vPayNum - 1)
                 and h.hrm_salary_sheet_id = s.hrm_salary_sheet_id
                 and s.hrm_salary_sheet_id = vSheet
                 and s.sal_is_acompte = 0)
     where hrm_person_id = vEmpId;

    commit;
  exception
    when others then
      rollback;
      raise_application_error(-20110, 'Extourne du décompte impossible');
  end;

  /**
   *  Procédure PeriodClosing
   */
  procedure PeriodClosing(vBreakVersion in integer)
  is
    ld_new_period   hrm_period.per_begin%type;
    ld_month_period date;
    ln_new_month    number;
    tmp             binary_integer;
  begin
    if (vBreakVersion in(1, 4) ) then
      -- Controle de la ventilation transférée en compta (c_interface_status=1)
      select count(*)
        into tmp
        from hrm_break
       where brk_value_date = hrm_date.ActivePeriodEndDate
         and brk_status = 2
         and brk_document_cg in(select doc_number
                                  from aci_document
                                 where c_interface_control = '1');

      if (tmp = 0) then
        raise_application_error(-20120, 'Ventilation pas transférée en comptabilité');
      else
        begin
          -- Suppression des ventilations provisoires
          delete      hrm_break_detail
                where hrm_break_id in(select hrm_break_id
                                        from hrm_break
                                       where brk_status = 0);

          delete      hrm_break
                where brk_status = 0;

          commit;
        exception
          when others then
            raise_application_error(-20110, 'Attention, Il existe des ventilations provisoires');
        end;
      end if;
    end if;

    begin
      select count(*)
        into tmp
        from dual
       where exists(select 1
                      from hrm_history
                     where hit_definitive = 0
                       and hit_pay_period = hrm_date.ActivePeriodEndDate);

      if (tmp = 0) then
        ld_month_period  := trunc(hrm_date.ActivePeriod, 'MM');

        -- Changes active flag of out of date valuedates to false for all
        -- company constants
        update HRM_COMPANY_ELEMENTS
           set COM_ACTIVE = 0
         where trunc(COM_TO, 'MM') <= ld_month_period;

        -- Changes active flag of out of date valuedates to false for all
        -- employee constants
        update HRM_EMPLOYEE_CONST
           set EMC_ACTIVE = 0
         where trunc(EMC_VALUE_TO, 'MM') <= ld_month_period;

        -- Deletes all employee elements out of date
        -- Inserting old records into history table is made by trigger
        delete      HRM_EMPLOYEE_ELEMENTS
              where trunc(EMP_VALUE_TO, 'MM') <= ld_month_period;

        -- updates all periods to inactive
        update HRM_PERIOD
           set PER_ACT = 0
             , PER_CLOSED = 1
         where PER_ACT = 1;

        -- Put begin date of new period into period variable
        ld_new_period    := add_months(ld_month_period, 1);

        -- inserts the new active period
        insert into HRM_PERIOD
                    (HRM_PERIOD_ID
                   , PER_BEGIN
                   , PER_END
                   , PER_ACT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (hrm_period_seq.nextval
                   , ld_new_period
                   , last_day(ld_new_period)
                   , 1
                   , sysdate
                   , pcs.PC_I_LIB_SESSION.GetUserIni
                    );

        -- update ino/out
        -- Désactiver uniquement s'il existe une autre entrée/sortie pour la nvlle période.
        -- Autrement ne pas désactiver même si périmé (décomptes complémentaires après sortie)
        for tplInOut in (select   distinct HRM_EMPLOYEE_ID
                             from HRM_IN_OUT) loop
          -- tous les employés ayant des contrats doivent être contrôlés
          UpdateInOutStatut(tplInOut.HRM_EMPLOYEE_ID);
        end loop;

        -- Certificat de salaire par défaut (iEmployeeID is null) pour le nouvel exercice
        HRM_PRC_PERSON_TAX.InsertPersonTax(null);

        -- deletes errors
        delete      HRM_ERRORS_LOG
              where ELO_TYPE = 1;
      end if;
    exception
      when others then
        raise_application_error(-20100, 'Cloture de la période impossible');
    end;
  end PeriodClosing;

  /**
   *  Procédure UpdateInOutStatut
   */
  procedure UpdateInOutStatut(vHRM_EMPLOYEE_ID in HRM_IN_OUT.HRM_EMPLOYEE_ID%type)
  is
    lvCount       number(1);
    ld_new_period hrm_period.per_begin%type;
  begin
    ld_new_period  := hrm_date.ActivePeriod;

    update HRM_IN_OUT io
       set C_IN_OUT_STATUS =
             case
               -- Période active antérieure à l'entrée => INA ( sera activé au changement de période )
               when last_day(ld_new_period) < ino_in then 'INA'
               -- S'il existe une autre période ultérieure dans le mois => INA
               when exists(select 1
                             from hrm_in_out ni
                            where ni.hrm_employee_id = io.hrm_employee_id
                              and ld_new_period >= trunc(ni.INO_IN, 'MM')
                              and ni.ino_in > io.ino_in) then 'INA'
               else 'ACT'
             end
     where HRM_EMPLOYEE_ID = vHRM_EMPLOYEE_ID
       and c_in_out_status <>
             case
               -- Période active antérieure à l'entrée => INA ( sera activé au changement de période )
               when last_day(ld_new_period) < ino_in then 'INA'
               -- S'il existe une autre période ultérieure dans le mois => INA
               when exists(select 1
                             from hrm_in_out ni
                            where ni.hrm_employee_id = io.hrm_employee_id
                              and ld_new_period >= trunc(ni.INO_IN, 'MM')
                              and ni.ino_in > io.ino_in) then 'INA'
               else 'ACT'
             end;
  end UpdateInOutStatut;

  function hrm_memoline(data in varchar2, lineNbr in integer default 1)
    return varchar2
  is
  begin
    return pcs.ExtractLine(data, lineNbr);
  end;

  function IsNumber(data in varchar2)
    return integer
  is
  begin
    return case
      when(to_number(data) != 0) then 1
      else 0
    end;
  exception
    when others then
      return 0;
  end;

  function IsLastPayNum(vEmpId in hrm_person.hrm_person_id%type, vPayNum in hrm_history.hit_pay_num%type)
    return integer
  is
    ln_result integer;
  begin
    select case
             when(nvl(max(HIT_PAY_NUM), -1) = vPayNum) then 1
             else 0
           end
      into ln_result
      from HRM_HISTORY
     where HRM_EMPLOYEE_ID = vEmpid;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function IsLastPayNumActivePeriod(vEmpId in hrm_person.hrm_person_id%type, vPayNum in hrm_history.hit_pay_num%type)
    return integer
  is
    ln_result integer;
  begin
    select case
             when(nvl(max(HIT_PAY_NUM), -1) = vPayNum) then 1
             else 0
           end
      into ln_result
      from HRM_HISTORY
     where HRM_EMPLOYEE_ID = vEmpId
       and HIT_PAY_PERIOD between hrm_date.ActivePeriod and hrm_date.ActivePeriodEndDate;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function Convert_to_Number(data in varchar2)
    return number
  is
  begin
    return to_number(data);
  exception
    when others then
      return 0;
  end;

  procedure Insert_EmpConstants_Def(
    vEmpId  in hrm_person.hrm_person_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  )
/*
* updates or inserts hrm_employee_const.EMC_NUM_VALUE with last values found
* in hrm_history_detail the pay_num used is the last one calculated for the
* employee
*/
  is
    vConFrom date;
    vConTo   date;
  begin
    for tplConst in (select a.hrm_employee_const_id as id
                          , c.ele_correlated_id as elemId
                          , b.his_pay_sum_val as val
                          , a.emc_num_value as Oldval
                          , b.his_pay_value as valString
                       from hrm_salary_sheet_elements d
                          , hrm_employee_const a
                          , hrm_elements c
                          , hrm_history_detail b
                      where b.hrm_employee_id = vEmpId
                        and b.his_pay_num = vPayNum
                        and c.hrm_elements_id = b.hrm_elements_id
                        and c.ele_correlated_id is not null
                        and c.ele_code like 'OutCon%'
                        and a.hrm_employee_id(+) = vEmpId
                        and a.hrm_constants_id(+) = c.ele_correlated_id
                        and d.hrm_salary_sheet_id = vSheet
                        and d.hrm_elements_id = c.ele_correlated_id) loop
      if     (tplConst.id is null)
         and (tplConst.val <> 0) then
        -- we've not found this constant for that employee so we search validity
        -- period from original constant and then insert a new record into
        -- hrm_employee_const and skip to next loop
        hrm_var.get_constant_validity(vConFrom, vConTo, tplConst.ElemId);

        insert into hrm_employee_const
                    (hrm_employee_const_id
                   , hrm_employee_id
                   , hrm_constants_id
                   , emc_num_value
                   , emc_from
                   , emc_to
                   , emc_value_from
                   , emc_value_to
                   , a_datecre
                   , a_idcre
                    )
             values (init_id_seq.nextval
                   , vEmpId
                   , tplConst.ElemId
                   , tplConst.Val
                   , vConFrom
                   , vConTo
                   , vConFrom
                   , vConTo
                   , sysdate
                   , 'AUTO'
                    );
      elsif(tplConst.OldVal <> tplConst.Val) then
        -- we've found the constant and the value we've got is different so
        -- we update hrm_employee_const with the new value
        update hrm_Employee_const a
           set a.emc_num_value = tplConst.Val
         where hrm_Employee_Const_Id = tplConst.id;
      end if;
    end loop;
  end;

  procedure ClearEmployeeInputHistory(vEmpId in hrm_person.hrm_person_id%type, vElemId in hrm_elements.hrm_elements_id%type)
  is
  begin
    -- Suppression dans l'historique de saisie des constantes
    delete      hrm_empl_const_history
          where hrm_employee_id = vEmpId
            and hrm_constants_id = vElemId;

    -- Suppression dans l'historique de saisie des éléments
    delete      hrm_empl_elem_history
          where hrm_employee_id = vEmpId
            and hrm_elements_id = vElemId;
  exception
    when others then
      raise_application_error(-20200, 'Impossible de supprimer l''historique de saisie');
  end;

  procedure ClearInputHistory(vDateTo in date)
  is
  begin
    -- Suppression des historiques de saisie des constantes
    delete      hrm_empl_const_history
          where trunc(a_datecre) <= vDateTo;

    -- Suppression des historiques de saisie des éléments
    delete      hrm_empl_elem_history
          where trunc(a_datecre) <= vDateTo;
  exception
    when others then
      raise_application_error(-20210, 'Impossible de supprimer tous les historiques de saisie');
  end;

  function employeeToCalculate(vSheet in hrm_salary_sheet.hrm_salary_sheet_id%type, vEmpid in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_provisory_exists binary_integer;
    ln_salary_exists    binary_integer;
  begin
    select count(*)
      into ln_provisory_exists
      from dual
     where exists(select 1
                    from hrm_history
                   where hrm_employee_id = vEmpid
                     and hit_definitive = 0
                     and hrm_date.validForActivePeriod2(hit_pay_period) = 1);

    if (ln_provisory_exists = 0) then
      select count(*)
        into ln_salary_exists
        from dual
       where exists(
               select 1
                 from hrm_person p
                    , hrm_history h
                where h.hrm_employee_id = vEmpid
                  and h.hrm_salary_sheet_id = vSheet
                  and hrm_date.ValidForActivePeriod2(h.hit_pay_period) = 1
                  and h.hit_reversal = 0
                  and p.hrm_person_id = h.hrm_employee_id
                  and p.emp_last_pay_num = h.hit_pay_num);
    end if;

    return case
      when     (ln_provisory_exists = 0)
           and (ln_salary_exists = 0) then 1
      else 0
    end;
  end;

  function PayrollToReversal(
    vEmpId  in hrm_person.hrm_person_id%type
  , vSheet  in hrm_salary_sheet.hrm_salary_sheet_id%type
  , vPayNum in hrm_history_detail.his_pay_num%type
  )
    return integer
  is
    ln_result integer := 0;
  begin
    if     (hrm_var.IsLastPayNumActivePeriod(vEmpid, vPayNum) = 1)
       and (hrm_var.IsReversal(vEmpId, vSheet, vPayNum) = 0)
       and (hrm_var.IsPaid(vEmpId, vSheet, vPayNum) = 1)
       and (hrm_var.IsBreakDowned(vEmpId, vSheet, vPayNum) = 1) then
      select   case
                 when(B.BRK_STATUS = 2) then 1
                 else 0
               end
          into ln_result
          from HRM_BREAK B
             , HRM_SALARY_BREAKDOWN SB
             , HRM_HISTORY_DETAIL HD
         where HD.HRM_EMPLOYEE_ID = vEmpId
           and HD.HRM_SALARY_SHEET_ID = vSheet
           and HD.HIS_PAY_NUM = vPayNum
           and SB.HRM_HISTORY_DETAIL_ID = HD.HRM_HISTORY_DETAIL_ID
           and B.HRM_BREAK_ID = SB.HRM_BREAK_ID
      group by B.HRM_BREAK_ID
             , B.BRK_STATUS;
    end if;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function get_DefaultCodeTableId(vCodeDicId in hrm_code_dic.hrm_code_dic_id%type)
    return hrm_code_table.hrm_code_table_id%type
  is
    ln_result hrm_code_table.hrm_code_table_id%type;
  begin
    -- we look for the default value of the given dictionary
    select HRM_CODE_TABLE_ID
      into ln_result
      from HRM_CODE_TABLE
     where HRM_CODE_DIC_ID = vCodeDicId
       and COD_DEFAULT = 1;

    return ln_result;
  exception
    when no_data_found then
      return null;
  end;

  procedure Insert_ConstantsToEmployee(vEmpId in hrm_person.hrm_person_id%type)
  is
  begin
    for tplConst in (select B.HRM_CONSTANTS_ID
                          , B.C_HRM_SAL_CONST_TYPE
                          , B.HRM_CODE_DIC_ID
                          , B.CON_DEFAULT_VALUE STRVALUE
                          , B.CON_DEFAULT_VALUE value
                          , B.CON_FROM
                          , B.CON_TO
                          , C.HRM_EMPLOYEE_ID
                          , C.HRM_CODE_TABLE_ID
                          , greatest(nvl(D.BEGINDATE, hrm_date.ActivePeriod), hrm_date.ActivePeriod) BEGINDATE
                       from (select   HRM_EMPLOYEE_ID
                                    , trunc(max(INO_IN), 'MM') BEGINDATE
                                 from HRM_IN_OUT
                                where C_IN_OUT_CATEGORY = '3'
                             group by HRM_EMPLOYEE_ID) D
                          , HRM_CONSTANTS B
                          , HRM_EMPLOYEE_CONST C
                      where C.HRM_EMPLOYEE_ID(+) = vEmpId
                        and B.HRM_CONSTANTS_ID = C.HRM_CONSTANTS_ID(+)
                        and B.CON_MANDATORY = 1
                        and D.HRM_EMPLOYEE_ID(+) = vEmpId) loop
      -- we look for all mandatory constants not attributed to employee
      if (tplConst.hrm_employee_id is null) then
        -- we found one wich is not attributed
        -- if type is 1 or 2 (avec tabelle ou soumission) we ask for default value
        if (tplConst.c_hrm_sal_const_type = '3') then
          tplConst.hrm_code_table_id  := null;
          tplConst.StrValue           := null;
        elsif(tplConst.c_hrm_sal_const_type in('1', '2') ) then
          tplConst.hrm_code_table_id  := hrm_var.get_DefaultCodeTableId(tplConst.hrm_code_dic_id);
          tplConst.StrValue           := null;
          tplConst.value              := null;
        else
          tplConst.hrm_code_table_id  := null;
          tplConst.value              := null;
        end if;

        -- we insert into table
        insert into hrm_employee_const
                    (hrm_employee_const_id
                   , hrm_employee_id
                   , hrm_constants_id
                   , hrm_code_table_id
                   , emc_value
                   , emc_num_value
                   , emc_from
                   , emc_to
                   , emc_value_from
                   , emc_value_to
                   , a_datecre
                   , a_idcre
                    )
             values (init_id_seq.nextval
                   , vEmpId
                   , tplConst.hrm_constants_id
                   , tplConst.hrm_code_table_id
                   , tplConst.StrValue
                   , case
                       when tplConst.value != 'NA()' then to_number(tplConst.value)
                     end
                   , tplConst.con_from
                   , tplConst.con_to
                   , tplConst.BeginDate
                   , tplConst.con_to
                   , sysdate
                   , 'AUTO'
                    );
      end if;
    end loop;
  end;

  procedure Insert_ConstantToEmployees(vConst_id in hrm_constants.hrm_constants_id%type)
  is
  begin
    for tplConst in (select A.HRM_PERSON_ID
                          , B.HRM_EMPLOYEE_ID
                          , C.C_HRM_SAL_CONST_TYPE
                          , C.HRM_CODE_DIC_ID
                          , C.CON_DEFAULT_VALUE STRVALUE
                          , C.CON_DEFAULT_VALUE value
                          , C.CON_FROM
                          , C.CON_TO
                          , B.HRM_CODE_TABLE_ID
                          , greatest(nvl(D.BEGINDATE, hrm_date.ActivePeriod), hrm_date.ActivePeriod) BEGINDATE
                       from (select   HRM_EMPLOYEE_ID
                                    , trunc(max(INO_IN), 'MM') BEGINDATE
                                 from HRM_IN_OUT
                                where C_IN_OUT_CATEGORY = '3'
                             group by HRM_EMPLOYEE_ID) D
                          , HRM_PERSON A
                          , HRM_EMPLOYEE_CONST B
                          , HRM_CONSTANTS C
                      where C.HRM_CONSTANTS_ID = vConst_Id
                        and B.HRM_CONSTANTS_ID(+) = vConst_Id
                        and A.HRM_PERSON_ID = B.HRM_EMPLOYEE_ID(+)
                        and A.EMP_CALCULATION = 1
                        and D.HRM_EMPLOYEE_ID(+) = A.HRM_PERSON_ID) loop
      -- we look all employees fro unattributed constant
      if (tplConst.hrm_employee_id is null) then
        -- we found one wich is not this constant
        -- if type is 1 or 2 (avec tabelle ou soumission) we ask for default value
        if (tplConst.c_hrm_sal_const_type = '3') then
          tplConst.hrm_code_table_id  := null;
          tplConst.StrValue           := null;
        elsif(tplConst.c_hrm_sal_const_type in('1', '2') ) then
          tplConst.hrm_code_table_id  := hrm_var.get_DefaultCodeTableId(tplConst.hrm_code_dic_id);
          tplConst.StrValue           := null;
          tplConst.value              := null;
        else
          tplConst.hrm_code_table_id  := null;
          tplConst.value              := null;
        end if;

        -- we insert into table
        insert into hrm_employee_const
                    (hrm_employee_const_id
                   , hrm_employee_id
                   , hrm_constants_id
                   , hrm_code_table_id
                   , emc_value
                   , emc_num_value
                   , emc_from
                   , emc_to
                   , emc_value_from
                   , emc_value_to
                   , a_datecre
                   , a_idcre
                    )
             values (init_id_seq.nextval
                   , tplConst.hrm_person_id
                   , vConst_id
                   , tplConst.hrm_CODE_TABLE_ID
                   , tplConst.StrValue
                   , case
                       when tplConst.value != 'NA()' then to_number(tplConst.value)
                     end
                   , tplConst.con_from
                   , tplConst.con_to
                   , tplConst.BeginDate
                   , tplConst.con_to
                   , sysdate
                   , 'AUTO'
                    );
      end if;
    end loop;
  end;

/**
 * Procédure Insert_EmplElemWConst
 *   Ajoute une variable (EmplElement) avec reprise des infos de la constante (EmplConst)
 */
  procedure Insert_EmplElemWConst(
    pEmpId      in     hrm_person.hrm_person_id%type
  , pElemId     in     hrm_elements.hrm_elements_id%type
  , pActive     in     hrm_employee_elements.emp_active%type
  , pValidFrom  in     hrm_employee_elements.emp_value_from%type
  , pValidTo    in     hrm_employee_elements.emp_value_to%type
  , pEmplElemId out    hrm_employee_elements.hrm_employee_elements_id%type
  )
  is
    vEmplConstId hrm_employee_const.hrm_employee_const_id%type;
  begin
    -- Initialisation de la valeur de retour
    pEmplElemId  := 0;

    -- Recherche de la constante à reprendre
    begin
      select hrm_employee_const_id
        into vEmplConstId
        from hrm_employee_const
       where hrm_employee_id = pEmpId
         and hrm_constants_id =
                     (select hrm_elements_id
                        from hrm_elements_family
                       where hrm_elements_root_id = (select hrm_elements_root_id
                                                       from hrm_elements_family
                                                      where hrm_elements_id = pElemId)
                         and hrm_elements_prefixes_id = 'CONEM'
                         and hrm_elements_suffixes_id = 'NONE')
         and emc_active = 1
         and hrm_date.ActivePeriod between emc_value_from and emc_value_to;
    exception
      when no_data_found then
        null;
    end;

    if (vEmplConstId is not null) then
      select init_id_seq.nextval
        into pEmplElemId
        from dual;

      -- Reprise des infos de la constante
      insert into hrm_employee_elements
                  (hrm_employee_elements_id
                 , hrm_employee_id
                 , hrm_elements_id
                 , emp_value
                 , emp_num_value
                 , emp_base_amount
                 , emp_rate
                 , emp_per_rate
                 , emp_ratio_group
                 , emp_foreign_value
                 , emp_ref_value
                 , emp_zl
                 , emp_ex_type
                 , emp_ex_rate
                 , acs_financial_currency_id
                 , emp_text
                 , emp_override
                 , emp_value_from
                 , emp_value_to
                 , emp_active
                 , emp_from
                 , emp_to
                 , a_datecre
                 , a_idcre
                  )
        select pEmplElemId
             , pEmpId
             , pElemId
             , nvl(emc_value, to_char(emc_num_value) )
             , emc_num_value
             , emc_base_amount
             , emc_rate
             , emc_per_rate
             , emc_ratio_group
             , emc_foreign_value
             , emc_ref_value
             , emc_zl
             , emc_ex_type
             , emc_ex_rate
             , acs_financial_currency_id
             , emc_text
             , emc_override
             , pValidFrom
             , pValidTo
             , pActive
             , emc_from
             , emc_to
             , sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni
          from hrm_employee_const
         where hrm_employee_const_id = vEmplConstId;

      -- Ajout ventilation
      insert into HRM_EMPLOYEE_ELEM_BREAK
                  (hrm_employee_elem_break_id
                 , hrm_person_id
                 , hrm_elements_id
                 , hrm_emp_elements_id
                 , eeb_serial
                 , eeb_time_ratio
                 , eeb_base_amount
                 , eeb_rate
                 , eeb_per_rate
                 , eeb_value
                 , eeb_ratio_group
                 , dic_department_id
                 , hrm_job_id
                 , eeb_d_cgbase
                 , eeb_c_cgbase
                 , eeb_divbase
                 , eeb_cdabase
                 , eeb_pfbase
                 , eeb_pjbase
                 , eeb_shift
                 , eeb_rco_title
                 , a_datecre
                 , a_idcre
                  )
        select init_id_seq.nextval
             , hrm_person_id
             , pElemId
             , pEmplElemId
             , eeb_serial
             , eeb_time_ratio
             , eeb_base_amount
             , eeb_rate
             , eeb_per_rate
             , eeb_value
             , eeb_ratio_group
             , dic_department_id
             , hrm_job_id
             , eeb_d_cgbase
             , eeb_c_cgbase
             , eeb_divbase
             , eeb_cdabase
             , eeb_pfbase
             , eeb_pjbase
             , eeb_shift
             , eeb_rco_title
             , sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni
          from hrm_employee_elem_break
         where hrm_emp_elements_id = vEmplConstId;
    end if;
  end;

  procedure Insert_ConstantsToProfile(vProfileId in hrm_elements_profile.hrm_elements_profile_id%type)
  is
  begin
    -- Affectation des constantes obligatoires à un profil (tous les profils si id null)
    insert into hrm_elements_profile_link
                (hrm_elements_profile_id
               , hrm_elements_id
               , elp_value
               , elp_num_value
               , hrm_code_table_id
               , a_datecre
               , a_idcre
                )
      select vProfileId hrm_elements_profile_id
           , hrm_constants_id hrm_elements_id
           , case
               when(c_hrm_sal_const_type = '0') then con_default_value
             end elp_value
           , case
               when(c_hrm_sal_const_type = '3') then to_number(con_default_value)
             end elp_num_value
           , case
               when(c_hrm_sal_const_type in('1', '2') ) then hrm_var.get_DefaultCodeTableId(hrm_code_dic_id)
             end hrm_code_table_id
           , sysdate
           , 'AUTO'
        from hrm_constants c
       where con_mandatory = 1
         and not exists(select 1
                          from hrm_elements_profile_link
                         where hrm_elements_profile_id = vProfileId
                           and hrm_elements_id = c.hrm_constants_id);
  end;

  procedure Insert_ConstantToProfiles(vConst_Id in hrm_constants.hrm_constants_id%type)
  is
  begin
    -- Affectation d'une constante obligatoire aux profils
    insert into hrm_elements_profile_link
                (hrm_elements_profile_id
               , hrm_elements_id
               , elp_value
               , elp_num_value
               , hrm_code_table_id
               , a_datecre
               , a_idcre
                )
      select p.hrm_elements_profile_id
           , c.hrm_constants_id hrm_elements_id
           , case
               when(c.c_hrm_sal_const_type = '0') then c.con_default_value
             end elp_value
           , case
               when(c.c_hrm_sal_const_type = '3') then to_number(c.con_default_value)
             end elp_num_value
           , case
               when(c.c_hrm_sal_const_type in('1', '2') ) then hrm_var.get_DefaultCodeTableId(c.hrm_code_dic_id)
             end hrm_code_table_id
           , sysdate
           , 'AUTO'
        from hrm_elements_profile p
           , hrm_constants c
       where c.hrm_constants_id = vConst_Id
         and not exists(select 1
                          from hrm_elements_profile_link
                         where hrm_elements_profile_id = p.hrm_elements_profile_id
                           and hrm_elements_id = vConst_Id);
  end;

  procedure Import_ProfileToEmployee(
    vProfileId in hrm_elements_profile.hrm_elements_profile_id%type
  , vEmpId     in hrm_person.hrm_person_id%type
  , vReplace   in integer default 1
  )
  is
  begin
    -- Mise à jour des valeurs existants
    -- (pour les enregistrements concernant la période active et les enregistrements ultérieurs)
    if (vReplace = 1) then
      -- Constante
      update hrm_employee_const ec
         set (emc_value, emc_num_value, hrm_code_table_id, a_datemod, a_idmod) =
               (select elp_value
                     , elp_num_value
                     , hrm_code_table_id
                     , sysdate
                     , pcs.PC_I_LIB_SESSION.GetUserIni
                  from hrm_elements_profile_link ep
                 where ep.hrm_elements_id = ec.hrm_constants_id
                   and ep.hrm_elements_profile_id = vProfileId)
       where ec.hrm_employee_id = vEmpId
         and exists(
               select 1
                 from hrm_elements_profile_link ep2
                where ep2.hrm_elements_profile_id = vProfileId
                  and ep2.hrm_elements_id = ec.hrm_constants_id
                  and (   nvl(emc_value, to_char(emc_num_value) ) <> nvl(elp_value, to_char(elp_num_value) )
                       or ec.hrm_code_table_id <> ep2.hrm_code_table_id) )
         and ec.emc_value_to >= hrm_date.ActivePeriod;

      -- Variable
      update hrm_employee_elements ee
         set (emp_value, emp_num_value, a_datemod, a_idmod) = (select elp_value
                                                                    , elp_num_value
                                                                    , sysdate
                                                                    , pcs.PC_I_LIB_SESSION.GetUserIni
                                                                 from hrm_elements_profile_link ep
                                                                where ep.hrm_elements_id = ee.hrm_elements_id
                                                                  and ep.hrm_elements_profile_id = vProfileId)
       where ee.hrm_employee_id = vEmpId
         and exists(
               select 1
                 from hrm_elements_profile_link ep2
                where ep2.hrm_elements_profile_id = vProfileId
                  and ep2.hrm_elements_id = ee.hrm_elements_id
                  and (   ee.emp_num_value <> ep2.elp_num_value
                       or ee.emp_value <> ep2.elp_value) )
         and ee.emp_value_to >= hrm_date.ActivePeriod;
    end if;

    -- Insertion des nouveaux enregistrements
    -- Constantes
    insert into hrm_employee_const
                (hrm_employee_const_id
               , hrm_employee_id
               , hrm_constants_id
               , emc_num_value
               , emc_value
               , hrm_code_table_id
               , emc_active
               , emc_value_from
               , emc_value_to
               , emc_from
               , emc_to
               , a_datecre
               , a_idcre
                )
      select init_id_seq.nextval
           , vEmpId
           , c.hrm_constants_id
           , p.elp_num_value
           , p.elp_value
           , p.hrm_code_table_id
           , 1
           , hrm_date.ActivePeriod
           , GCD_MAX_VALIDITY
           , c.con_from
           , c.con_to
           , sysdate
           , pcs.PC_I_LIB_SESSION.GetUserIni
        from hrm_constants c
           , hrm_elements_profile_link p
       where p.hrm_elements_profile_id = vProfileId
         and c.hrm_constants_id = p.hrm_elements_id
         and not exists(select 1
                          from hrm_employee_const ec
                         where ec.hrm_employee_id = vEmpId
                           and ec.hrm_constants_id = p.hrm_elements_id
                           and ec.emc_value_to >= hrm_date.ActivePeriod);

    -- Variables
    insert into hrm_employee_elements
                (hrm_employee_elements_id
               , hrm_employee_id
               , hrm_elements_id
               , emp_num_value
               , emp_value
               , emp_active
               , emp_value_from
               , emp_value_to
               , emp_from
               , emp_to
               , a_datecre
               , a_idcre
                )
      select init_id_seq.nextval
           , vEmpId
           , e.hrm_elements_id
           , p.elp_num_value
           , p.elp_value
           , 1
           , hrm_date.ActivePeriod
           , hrm_date.ActivePeriodEndDate
           , e.ele_valid_from
           , e.ele_valid_to
           , sysdate
           , pcs.PC_I_LIB_SESSION.GetUserIni
        from hrm_elements e
           , hrm_elements_profile_link p
       where p.hrm_elements_profile_id = vProfileId
         and e.hrm_elements_id = p.hrm_elements_id
         and not exists(select 1
                          from hrm_employee_elements ee
                         where ee.hrm_employee_id = vEmpId
                           and ee.hrm_elements_id = p.hrm_elements_id
                           and ee.emp_value_to >= hrm_date.ActivePeriod);
  end;

  function IsProvisoryCalc(vEmpid in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(select 1
                    from HRM_HISTORY
                   where HRM_EMPLOYEE_ID = vEmpid
                     and HIT_DEFINITIVE = 0);

    return ln_result;
  end;

  procedure InsertUpdateBrutAmount(vEmpId in hrm_person.hrm_person_id%type, vElemCode in varchar2, vValue in number)
  is
    tmp     binary_integer;
    nElemId hrm_elements.hrm_elements_id%type;
    dFrom   date;
    dTo     date;
  begin
    select (select p.elp_is_const * 2 + p.elp_is_var
              from hrm_elements_prefixes p
             where p.hrm_elements_prefixes_id = f.hrm_elements_prefixes_id) elem_type
         , v.elemid
         , r.elr_from
         , r.elr_to
      into tmp
         , nElemId
         , dFrom
         , dTo
      from hrm_elements_root r
         , hrm_elements_family f
         , v_hrm_elements_short v
     where v.code = vElemCode
       and f.hrm_elements_id = v.elemid
       and r.hrm_elements_root_id = f.hrm_elements_root_id;

    case tmp
      when 2 then
        -- Est une constante
        -- ~todo~ Utiliser une commande MERGE
        select count(*)
          into tmp
          from hrm_employee_const
         where hrm_employee_id = vEmpId
           and hrm_constants_id = nElemId
           and hrm_date.ActivePeriod between emc_value_from and emc_value_to;

        if (tmp > 0) then
          -- Mise à jour de la constante
          update hrm_employee_const
             set emc_num_value = vValue
               , emc_active = 1
           where hrm_employee_id = vEmpId
             and hrm_constants_id = nElemId
             and hrm_date.ActivePeriod between emc_value_from and emc_value_to;
        else
          -- Création de la constante
          insert into hrm_employee_const
                      (hrm_employee_const_id
                     , hrm_employee_id
                     , hrm_constants_id
                     , emc_num_value
                     , emc_active
                     , emc_from
                     , emc_to
                     , emc_value_from
                     , emc_value_to
                     , a_datecre
                     , a_idcre
                      )
               values (init_id_seq.nextval
                     , vEmpId
                     , nElemId
                     , vValue
                     , 1
                     , dFrom
                     , dTo
                     , hrm_date.ActivePeriod
                     , hrm_date.ActivePeriodEndDate
                     , trunc(sysdate)
                     , pcs.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;
      when 1 then
        -- Est une variable
        -- ~todo~ Utiliser une commande MERGE
        select count(*)
          into tmp
          from hrm_employee_elements
         where hrm_employee_id = vEmpId
           and hrm_elements_id = nElemId
           and hrm_date.ActivePeriod between emp_value_from and emp_value_to;

        if (tmp > 0) then
          -- Mise à jour de la variable
          update hrm_employee_elements
             set emp_value = to_char(vValue)
               , emp_num_value = vValue
               , emp_active = 1
           where hrm_employee_id = vEmpId
             and hrm_elements_id = nElemId
             and hrm_date.ActivePeriod between emp_value_from and emp_value_to;
        else
          -- Création de la variable
          insert into hrm_employee_elements
                      (hrm_employee_elements_id
                     , hrm_employee_id
                     , hrm_elements_id
                     , emp_value
                     , emp_num_value
                     , emp_active
                     , emp_from
                     , emp_to
                     , emp_value_from
                     , emp_value_to
                     , a_datecre
                     , a_idcre
                      )
               values (init_id_seq.nextval
                     , vEmpId
                     , nElemId
                     , to_char(vValue)
                     , vValue
                     , 1
                     , dFrom
                     , dTo
                     , hrm_date.ActivePeriod
                     , hrm_date.ActivePeriodEndDate
                     , trunc(sysdate)
                     , pcs.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;
      else
        null;
    end case;
  end;

  function exchangeRate(vCurrency in pcs.pc_curr.currency%type, vType in integer)
    return number
  is
    fSelectedRate number;
  begin
    select case vType
             when 1 then c.pcu_dayly_price / c.pcu_base_price   --Daily
             when 2 then c.pcu_valuation_price / c.pcu_base_price   --Evaluation
             when 3 then c.pcu_inventory_price / c.pcu_base_price   --Inventory
             when 4 then c.pcu_closing_price / c.pcu_base_price   --Close
           end SELECTED_RATE
      into fSelectedRate
      from acs_price_currency c
         , (select   max(pcu_start_validity) pcu_start_validity
                   , acs_between_curr_id
                   , acs_and_curr_id
                from acs_price_currency c
                   , acs_financial_currency a
                   , pcs.pc_curr b
               where b.currency = vCurrency
                 and a.pc_curr_id = b.pc_curr_id
                 and c.acs_between_curr_id = a.acs_financial_currency_id
                 and c.acs_and_curr_id = acs_function.getlocalcurrencyid
                 and c.pcu_start_validity <= sysdate
            group by acs_and_curr_id
                   , acs_between_curr_id) v
     where c.acs_and_curr_id = v.acs_and_curr_id
       and c.acs_between_curr_id = v.acs_between_curr_id
       and c.pcu_start_validity = v.pcu_start_validity;

    return nvl(fSelectedRate, 0.0);
  exception
    when no_data_found then
      return 0.0;
  end;

  function ChildBenefitsForPeriod(vEmpId in hrm_person.hrm_person_id%type)
    return number
  is
    ln_result number := 0.0;
  begin
    if (hrm_date.get_IsBudgetInit <> 1) then
      -- we look for child benefits with dates valid for period
      select nvl(sum(A.ALLO_AMOUNT), 0)
        into ln_result
        from HRM_RELATED_ALLOCATION A
           , HRM_RELATED_TO R
       where A.HRM_RELATED_TO_ID = R.HRM_RELATED_TO_ID
         and R.HRM_EMPLOYEE_ID = vEmpId
         and hrm_date.ActivePeriod between A.ALLO_BEGIN and A.ALLO_END;
    else
      -- we look for child benefits with dates valid for budget
      select round(sum(A.ALLO_AMOUNT * A.DAYS_BETWEEN) / sum(A.DAYS_BETWEEN) * least(hrm_date.Ac_Days_Sincebeginofyear(vEmpid), sum(A.DAYS_BETWEEN) / 30), 2)
        into ln_result
        from (select HRM_RELATED_TO_ID
                   , nvl(ALLO_AMOUNT, 0) as ALLO_AMOUNT
                   , hrm_date.Days_Between(greatest(trunc(ALLO_BEGIN, 'MM'), hrm_date.ActivePeriod)
                                         , case
                                             when(ALLO_END is null) then hrm_date.ActivePeriodEndDate
                                             else least(last_day(ALLO_END), hrm_date.ActivePeriodEndDate)
                                           end
                                          ) as DAYS_BETWEEN
                from HRM_RELATED_ALLOCATION
               where hrm_date.ValidForActivePeriod(ALLO_BEGIN, nvl(ALLO_END, hrm_date.ActivePeriodEndDate) ) = 1) A
           , HRM_RELATED_TO R
       where R.HRM_EMPLOYEE_ID = vEmpid
         and A.HRM_RELATED_TO_ID = R.HRM_RELATED_TO_ID;
    end if;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function ChildBenefitsByTypeForPeriod(vEmpId in hrm_person.hrm_person_id%type, vType in dic_allowance_type.dic_allowance_type_id%type)
    return number
  is
    ln_result number := 0.0;
  begin
    if (hrm_date.get_IsBudgetInit <> 1) then
      -- we look for child benefits with dates valid for period
      select nvl(sum(A.ALLO_AMOUNT), 0)
        into ln_result
        from HRM_RELATED_ALLOCATION A
           , HRM_RELATED_TO R
       where A.HRM_RELATED_TO_ID = R.HRM_RELATED_TO_ID
         and A.DIC_ALLOWANCE_TYPE_ID = vType
         and R.HRM_EMPLOYEE_ID = vEmpId
         and hrm_date.ActivePeriod between A.ALLO_BEGIN and A.ALLO_END;
    else
      -- we look for child benefits with dates valid for budget
      select round(sum(A.ALLO_AMOUNT * A.DAYS_BETWEEN) / sum(A.DAYS_BETWEEN) * least(hrm_date.Ac_Days_SinceBeginOfYear(vEmpid), sum(A.DAYS_BETWEEN) / 30), 2)
        into ln_result
        from (select HRM_RELATED_TO_ID
                   , nvl(ALLO_AMOUNT, 0) as ALLO_AMOUNT
                   , hrm_date.Days_Between(greatest(trunc(ALLO_BEGIN, 'MM'), hrm_date.ActivePeriod)
                                         , case
                                             when(ALLO_END is null) then hrm_date.ActivePeriodEndDate
                                             else least(last_day(ALLO_END), hrm_date.ActivePeriodEndDate)
                                           end
                                          ) as DAYS_BETWEEN
                from HRM_RELATED_ALLOCATION
               where DIC_ALLOWANCE_TYPE_ID = vType
                 and hrm_date.ValidForActivePeriod(allo_begin, nvl(ALLO_END, hrm_date.ActivePeriodEndDate) ) = 1) a
           , HRM_RELATED_TO R
       where R.HRM_EMPLOYEE_ID = vEmpid
         and A.HRM_RELATED_TO_ID = R.HRM_RELATED_TO_ID;
    end if;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function ChildrenAllowance(in_person_id in hrm_person.hrm_person_id%type, in_type in integer, iv_array in varchar2)
    return number
  is
    ln_result     number         := 0.0;
    ln_allowance  number;
    ln_accademics number;
    ln_rank       binary_integer := 0;
  begin
    if (in_type not in(1, 2) ) then
      return 0.0;
    end if;

    -- Recherche de tous les enfants à charge
    for tpl in (select   trunc(months_between(hrm_date.ActivePeriod, trunc(REL_BIRTH_DATE, 'month') ) / 12, 3) AGING
                       , P.DIC_CANTON_WORK_ID || '1' CHILD_CODE
                       , P.DIC_CANTON_WORK_ID || '2' TRAINING_CODE
                       , P.DIC_CANTON_WORK_ID || '3' HUGE_FAMILY_CODE
                    from HRM_RELATED_TO T
                       , HRM_PERSON P
                   where P.HRM_PERSON_ID = in_person_id
                     and T.HRM_EMPLOYEE_ID = P.HRM_PERSON_ID
                     and T.C_RELATED_TO_TYPE = '2'
                     and T.REL_IS_DEPENDANT = 1
                     and T.REL_BIRTH_DATE is not null
                     and not exists(
                            select 1
                              from HRM_RELATED_ALLOCATION
                             where HRM_RELATED_TO_ID = T.HRM_RELATED_TO_ID
                               and hrm_date.ActivePeriod between trunc(ALLO_BEGIN, 'month') and nvl(ALLO_END, sysdate) )
                order by T.REL_BIRTH_DATE asc) loop
      -- Calcul de l'allocation normale si pas forcée
      ln_allowance   := nvl(hrm_functions.ArrayValue2(iv_array, tpl.CHILD_CODE, tpl.AGING), 0);
      ln_accademics  := nvl(hrm_functions.ArrayValue2(iv_array, tpl.TRAINING_CODE, tpl.AGING), 0);

      -- Incrémentation du rang de l'enfant et ajout éventuel du supplément pour famille nombreuse
      if ( (ln_allowance + ln_accademics) <> 0.0) then
        ln_rank  := ln_rank + 1;

        if (ln_allowance <> 0.0) then
          ln_allowance  := ln_allowance + hrm_functions.ArrayValue2(iv_array, tpl.HUGE_FAMILY_CODE, ln_rank);
        elsif(ln_accademics <> 0.0) then
          ln_accademics  := ln_accademics + hrm_functions.ArrayValue2(iv_array, tpl.HUGE_FAMILY_CODE, ln_rank);
        end if;
      end if;

      -- Incrémentation de la somme totale
      ln_result      := case in_type
                         when 1 then ln_result + ln_allowance
                         when 2 then ln_result + ln_accademics
                       end;
    end loop;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function IsFinalPay(vEmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result binary_integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(select 1
                    from (select trunc(INO_OUT, 'MM') as INO_OUT
                            from HRM_IN_OUT
                           where HRM_EMPLOYEE_ID = vEmpId
                             and C_IN_OUT_STATUS = 'ACT'
                             and INO_FINAL_PAYMENT = 1
                             and C_IN_OUT_CATEGORY = '3')
                   where INO_OUT <= hrm_date.ActivePeriod);

    return ln_result;
  end;

  function IsFirstSalaryInYear(vEmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result binary_integer;
  begin
    if (hrm_date.get_CalcRetro = 1) then
      return 0;
    end if;

    select case
             when(EMP_LAST_PAY_DATE is null) then 1
             when(EMP_LAST_PAY_DATE <= hrm_date.BeginOfYear) then 1
             else (select SAL_IS_RETRO
                     from HRM_SALARY_SHEET
                    where HRM_SALARY_SHEET_ID = (select HRM_SALARY_SHEET_ID
                                                   from HRM_HISTORY
                                                  where HIT_PAY_NUM = P.EMP_LAST_PAY_NUM
                                                    and HRM_EMPLOYEE_ID = P.HRM_PERSON_ID) )
           end
      into ln_result
      from HRM_PERSON P
     where HRM_PERSON_ID = vEmpId;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function IsPdfExported(vEmpId in hrm_person.hrm_person_id%type, vPayNum in hrm_history_detail.his_pay_num%type)
    return integer
  is
    ln_result binary_integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(select 1
                    from HRM_PAYSLIP
                   where HRM_PERSON_ID = vEmpId
                     and HPS_PAY_NUM = vPayNum
                     and C_HRM_PAYSLIP_TYPE = HRM_LIB_CONSTANT.gcPayslipTypeBreakdown);

    return ln_result;
  end;

  function GetPdfExported(vEmpId in hrm_person.hrm_person_id%type, vPayNum in hrm_history_detail.his_pay_num%type)
    return hrm_payslip.hps_payslip%type
  is
    llob_result hrm_payslip.hps_payslip%type;
  begin
    select HPS_PAYSLIP
      into llob_result
      from HRM_PAYSLIP
     where HRM_PERSON_ID = vEmpId
       and HPS_PAY_NUM = vPayNum
       and C_HRM_PAYSLIP_TYPE = HRM_LIB_CONSTANT.gcPayslipTypeBreakdown;

    return llob_result;
  exception
    when no_data_found then
      return null;
  end;

  procedure recalcul_base(
    iv_root_name   in hrm_elements_root.elr_root_name%type
  , in_year        in acs_financial_year.fye_no_exercice%type
  , in_employee_id in hrm_person.hrm_person_id%type default null
  )
  is
    lv_test_root hrm_elements_root.elr_base_cond_code%type;
  begin
    begin
      select ELR_BASE_COND_CODE
        into lv_test_root
        from HRM_ELEMENTS_ROOT
       where ELR_ROOT_NAME = iv_root_name;
    exception
      when no_data_found then
        raise_application_error(-20300, 'Genre salaire inexistant');
    end;

    if lv_test_root is not null then
      raise_application_error(-20310, 'Impossible de recalculer une base conditionnelle');
    end if;

    for tpl in (select HRM_EMPLOYEE_ID
                     , HIT_PAY_NUM
                  from (select HRM_EMPLOYEE_ID
                             , HIT_PAY_NUM
                             , to_char(HIT_PAY_PERIOD, 'yyyy') HIT_PAY_PERIOD
                          from HRM_HISTORY
                         where HRM_EMPLOYEE_ID = in_employee_id
                            or in_employee_id is null)
                 where HIT_PAY_PERIOD = in_year) loop
      update HRM_HISTORY_DETAIL D1
         set (HIS_PAY_VALUE, HIS_PAY_SUM_VAL) =
               (select to_char(nvl(PAYVAL, 0) )
                     , nvl(PAYVAL, 0)
                  from (select sum(HIS_PAY_SUM_VAL) PAYVAL
                          from HRM_FORMULAS_STRUCTURE S
                             , HRM_HISTORY_DETAIL D
                         where D.HRM_ELEMENTS_ID = S.RELATED_ID
                           and MAIN_ID = (select HRM_ELEMENTS_ID
                                            from HRM_ELEMENTS_ROOT
                                           where ELR_ROOT_NAME = iv_root_name)
                           and D.HIS_PAY_NUM = tpl.HIT_PAY_NUM
                           and D.HRM_EMPLOYEE_ID = tpl.HRM_EMPLOYEE_ID) )
       where HRM_EMPLOYEE_ID = tpl.HRM_EMPLOYEE_ID
         and HIS_PAY_NUM = tpl.HIT_PAY_NUM
         and HRM_ELEMENTS_ID = (select HRM_ELEMENTS_ID
                                  from HRM_ELEMENTS_ROOT
                                 where ELR_ROOT_NAME = iv_root_name);

      insert into HRM_HISTORY_DETAIL
                  (HRM_HISTORY_DETAIL_ID
                 , HRM_ELEMENTS_ID
                 , HRM_EMPLOYEE_ID
                 , HRM_SALARY_SHEET_ID
                 , HIS_PAY_NUM
                 , HIS_PAY_PERIOD
                 , HIS_PAY_VALUE
                 , HIS_PAY_SUM_VAL
                 , ACS_FINANCIAL_CURRENCY_ID
                 , HIS_CURRENCY_VALUE
                 , HIS_REF_VALUE
                 , HIS_DEFINITIVE
                 , HIS_ACCOUNTED
                 , HIS_PAID
                 , HIS_DATE
                 , HIS_ZL
                  )
        select hrm_history_detail_seq.nextval
             , HRM_ELEMENTS_ID
             , HRM_EMPLOYEE_ID
             , HRM_SALARY_SHEET_ID
             , HIS_PAY_NUM
             , HIS_PAY_PERIOD
             , HIS_PAY_VALUE
             , HIS_PAY_SUM_VAL
             , ACS_FINANCIAL_CURRENCY_ID
             , HIS_CURRENCY_VALUE
             , HIS_REF_VALUE
             , HIS_DEFINITIVE
             , HIS_ACCOUNTED
             , HIS_PAID
             , HIS_DATE
             , HIS_ZL
          from (select   MAIN_ID HRM_ELEMENTS_ID
                       , HRM_EMPLOYEE_ID
                       , HRM_SALARY_SHEET_ID
                       , HIS_PAY_NUM
                       , HIS_PAY_PERIOD
                       , to_char(sum(HIS_PAY_SUM_VAL) ) HIS_PAY_VALUE
                       , sum(HIS_PAY_SUM_VAL) HIS_PAY_SUM_VAL
                       , ACS_FINANCIAL_CURRENCY_ID
                       , null HIS_CURRENCY_VALUE
                       , null HIS_REF_VALUE
                       , max(HIS_DEFINITIVE) HIS_DEFINITIVE
                       , max(HIS_ACCOUNTED) HIS_ACCOUNTED
                       , max(HIS_PAID) HIS_PAID
                       , max(HIS_DATE) HIS_DATE
                       , max(HIS_ZL) HIS_ZL
                    from HRM_FORMULAS_STRUCTURE S
                       , HRM_HISTORY_DETAIL D
                   where D.HRM_ELEMENTS_ID = S.RELATED_ID
                     and MAIN_ID = (select HRM_ELEMENTS_ID
                                      from HRM_ELEMENTS_ROOT
                                     where ELR_ROOT_NAME = iv_root_name)
                     and D.HIS_PAY_NUM = tpl.HIT_PAY_NUM
                     and D.HRM_EMPLOYEE_ID = tpl.HRM_EMPLOYEE_ID
                group by MAIN_ID
                       , HRM_EMPLOYEE_ID
                       , HRM_SALARY_SHEET_ID
                       , HIS_PAY_NUM
                       , HIS_PAY_PERIOD
                       , ACS_FINANCIAL_CURRENCY_ID
                  having sum(HIS_PAY_SUM_VAL) <> 0) A
         where not exists(select 1
                            from HRM_HISTORY_DETAIL D
                           where D.HIS_PAY_NUM = tpl.HIT_PAY_NUM
                             and D.HRM_EMPLOYEE_ID = tpl.HRM_EMPLOYEE_ID
                             and D.HRM_ELEMENTS_ID = A.HRM_ELEMENTS_ID);
    end loop;
  end recalcul_base;

  procedure recalcul_cumul(
    iv_root_name   in hrm_elements_root.elr_root_name%type
  , in_year        in acs_financial_year.fye_no_exercice%type
  , in_employee_id in hrm_person.hrm_person_id%type default null
  )
  is
    ln_cem_value      number;   --hrm_history_detail.his_pay_sum_val%TYPE;
    ln_outcum_value   number;   --hrm_history_detail.his_pay_sum_val%TYPE;
    ln_elem_id        hrm_history_detail.hrm_elements_id%type;
    ln_cum_elem_id    hrm_history_detail.hrm_elements_id%type;
    ln_outcum_elem_id hrm_history_detail.hrm_elements_id%type;
  begin
    begin
      select max(case
                   when HRM_ELEMENTS_PREFIXES_ID = 'CEM' then HRM_ELEMENTS_ID
                   else 0
                 end)
           , max(case
                   when HRM_ELEMENTS_PREFIXES_ID = 'CUMCEM' then HRM_ELEMENTS_ID
                   else 0
                 end)
           , max(case
                   when HRM_ELEMENTS_PREFIXES_ID = 'OUTCUMCEM' then HRM_ELEMENTS_ID
                   else 0
                 end)
        into ln_elem_id
           , ln_cum_elem_id
           , ln_outcum_elem_id
        from HRM_ELEMENTS_FAMILY f
       where exists(select 1
                      from HRM_ELEMENTS_ROOT
                     where ELR_ROOT_NAME = iv_root_name
                       and HRM_ELEMENTS_ROOT_ID = F.HRM_ELEMENTS_ROOT_ID);
    exception
      when no_data_found then
        raise_application_error(-20300, 'Genre salaire inexistant');
    end;

    if (ln_elem_id = 0.0) then
      raise_application_error(-20311, 'Element CEM not found');
    elsif(ln_cum_elem_id = 0.0) then
      raise_application_error(-20312, 'Element CUMCEM not found');
    elsif(ln_outcum_elem_id = 0.0) then
      raise_application_error(-20313, 'Element OUTCUMCEM not found');
    end if;

    for tplPayNum in (select   HRM_EMPLOYEE_ID
                             , min(HIT_PAY_NUM) MINI
                             , max(HIT_PAY_NUM) MAXI
                          from (select HRM_EMPLOYEE_ID
                                     , HIT_PAY_NUM
                                     , to_char(HIT_PAY_PERIOD, 'yyyy') HIT_PAY_PERIOD
                                  from HRM_HISTORY
                                 where HRM_EMPLOYEE_ID = in_employee_id
                                    or in_employee_id is null)
                         where HIT_PAY_PERIOD = in_year
                      group by HRM_EMPLOYEE_ID) loop
      ln_outcum_value  := 0.0;

      for tplHist in (select   HRM_EMPLOYEE_ID
                             , HIT_PAY_NUM
                             , HIT_DATE
                             , HIT_DEFINITIVE
                             , HIT_PAY_PERIOD
                             , HRM_SALARY_SHEET_ID
                             , HIT_ACCOUNTED
                          from HRM_HISTORY
                         where HIT_PAY_NUM between tplPayNum.MINI and tplPayNum.MAXI
                           and HRM_EMPLOYEE_ID = tplPayNum.HRM_EMPLOYEE_ID
                      order by HIT_PAY_NUM asc) loop
        begin
          select HIS_PAY_SUM_VAL
            into ln_cem_value
            from HRM_HISTORY_DETAIL
           where HRM_EMPLOYEE_ID = tplHist.HRM_EMPLOYEE_ID
             and HIS_PAY_NUM = tplHist.HIT_PAY_NUM
             and HRM_ELEMENTS_ID = ln_elem_id;
        exception
          when no_data_found then
            ln_cem_value  := 0.0;
        end;

        -- update cum dans période si <> 0
        if (ln_outcum_value <> 0.0) then
          update hrm_history_detail d
             set HIS_PAY_SUM_VAL = ln_outcum_value
               , HIS_PAY_VALUE = to_char(ln_outcum_value)
           where D.HRM_EMPLOYEE_ID = tplHist.HRM_EMPLOYEE_ID
             and D.HIS_PAY_NUM = tplHist.HIT_PAY_NUM
             and D.HRM_ELEMENTS_ID = ln_cum_elem_id;

          insert into hrm_history_detail
                      (HRM_HISTORY_DETAIL_ID
                     , HRM_ELEMENTS_ID
                     , HRM_EMPLOYEE_ID
                     , HRM_SALARY_SHEET_ID
                     , HIS_PAY_NUM
                     , HIS_PAY_PERIOD
                     , HIS_PAY_VALUE
                     , HIS_PAY_SUM_VAL
                     , HIS_DEFINITIVE
                     , HIS_ACCOUNTED
                     , HIS_DATE
                      )
            select hrm_history_detail_seq.nextval
                 , ln_cum_elem_id
                 , tplHist.HRM_EMPLOYEE_ID
                 , tplHist.HRM_SALARY_SHEET_ID
                 , tplHist.HIT_PAY_NUM
                 , tplHist.HIT_PAY_PERIOD
                 , to_char(ln_outcum_value)
                 , ln_outcum_value
                 , tplHist.HIT_DEFINITIVE
                 , tplHist.HIT_ACCOUNTED
                 , tplHist.HIT_DATE
              from dual
             where not exists(select 1
                                from hrm_history_detail
                               where hrm_employee_id = tplHist.hrm_employee_id
                                 and his_pay_num = tplHist.hit_pay_num
                                 and hrm_elements_id = ln_cum_elem_id);
        else
          delete from hrm_history_detail d
                where D.HRM_EMPLOYEE_ID = tplHist.HRM_EMPLOYEE_ID
                  and D.HIS_PAY_NUM = tplHist.HIT_PAY_NUM
                  and D.HRM_ELEMENTS_ID = ln_cum_elem_id;
        end if;

        ln_outcum_value  := ln_outcum_value + ln_cem_value;

        -- update cum dans période si <> 0
        begin
          if (ln_outcum_value <> 0.0) then
            update hrm_history_detail d
               set his_pay_sum_val = ln_outcum_value
                 , his_pay_value = to_char(ln_outcum_value)
             where D.HRM_EMPLOYEE_ID = tplHist.HRM_EMPLOYEE_ID
               and D.HIS_PAY_NUM = tplHist.HIT_PAY_NUM
               and D.HRM_ELEMENTS_ID = ln_outcum_elem_id;

            insert into hrm_history_detail
                        (HRM_HISTORY_DETAIL_ID
                       , HRM_ELEMENTS_ID
                       , HRM_EMPLOYEE_ID
                       , HRM_SALARY_SHEET_ID
                       , HIS_PAY_NUM
                       , HIS_PAY_PERIOD
                       , HIS_PAY_VALUE
                       , HIS_PAY_SUM_VAL
                       , HIS_DEFINITIVE
                       , HIS_ACCOUNTED
                       , HIS_DATE
                        )
              select hrm_history_detail_seq.nextval
                   , ln_outcum_elem_id
                   , tplHist.HRM_EMPLOYEE_ID
                   , tplHist.HRM_SALARY_SHEET_ID
                   , tplHist.HIT_PAY_NUM
                   , tplHist.HIT_PAY_PERIOD
                   , to_char(ln_outcum_value)
                   , ln_outcum_value
                   , tplHist.HIT_DEFINITIVE
                   , tplHist.HIT_ACCOUNTED
                   , tplHist.HIT_DATE
                from dual
               where not exists(select 1
                                  from hrm_history_detail
                                 where hrm_employee_id = tplHist.hrm_employee_id
                                   and his_pay_num = tplHist.hit_pay_num
                                   and hrm_elements_id = ln_outcum_elem_id);
          else
            delete from hrm_history_detail d
                  where D.HRM_EMPLOYEE_ID = tplHist.HRM_EMPLOYEE_ID
                    and D.HIS_PAY_NUM = tplHist.HIT_PAY_NUM
                    and D.HRM_ELEMENTS_ID = ln_outcum_elem_id;
          end if;
        exception
          when others then
            raise_application_error(-20314, 'Error empid ' || tplHist.HRM_EMPLOYEE_ID || ' paynum ' || tplHist.HIT_PAY_NUM || ' elem ' || ln_outcum_elem_id);
        end;
      end loop;
    end loop;
  end recalcul_cumul;
end HRM_VAR;
