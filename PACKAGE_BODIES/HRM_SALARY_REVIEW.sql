--------------------------------------------------------
--  DDL for Package Body HRM_SALARY_REVIEW
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_SALARY_REVIEW" 
/**
 * Fonctions pour la revue des salaires
 *
 * @version 1.0
 * @date 02/2007
 * @author ireber
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
AS

  -- Constantes SQL Initialisation de valeurs
  STMT_INIT_VAL CONSTANT VARCHAR2(2000) :=
    'declare '||
      'vElemId Number; '||
      'vPeriodBegin Date; '||
      'vPeriodEnd Date; '||
      'vRate Number; '||
      'vPrecision Number; '||
      'v_hrm_salary_revision_id Number; '||
    'begin '||
      'vElemId := :ElemId; '||
      'vPeriodBegin := :PeriodBegin; '||
      'vPeriodEnd := :PeriodEnd; '||
      'vRate := :Rate; '||
      'vPrecision := :Precision; '||
      'v_hrm_salary_revision_id := :SalaryRevId; '||
      'update hrm_salary_rev_detail rd' ||Chr(10)||
      'set [COL_NAME] = ([UPDATE_SQL])'||
      'where hrm_salary_revision_id = v_hrm_salary_revision_id;' ||
    'end;';

  STMT_UPD_ACT_CONST CONSTANT VARCHAR2(2000) :=
    'select round ( '||
        'sum (emc_num_value * emc_days) / sum (emc_days) * '||
             'case when vRate = 1 then 1 '||
                  'else least (hrm_date.days_between ( '||
                                  'greatest(rd.ino_in, vPeriodBegin), '||
                                  'least(nvl(rd.ino_out, vPeriodEnd), vPeriodEnd)), '||
                              'sum (emc_days)) / 30 end, '||
        'vPrecision) numval '||
    'from (select hrm_date.days_between( '||
                      'greatest(trunc(emc_value_from, ''Month''), vPeriodBegin), '||
                      'least(last_day(emc_value_to), vPeriodEnd)) emc_days, '||
                 'emc_num_value, hrm_employee_id '||
          'from hrm_employee_const '||
          'where emc_value_from <= vPeriodEnd and '||
                'emc_value_to >= vPeriodBegin and '||
                'hrm_constants_id = vElemId) c '||
    'where c.hrm_employee_id = rd.hrm_person_id';

  STMT_UPD_ACT_VAR CONSTANT VARCHAR2(2000) :=
    'select round ( '||
        'sum (emp_num_value * emp_days) / sum (emp_days) * '||
             'case when vRate = 1 then 1 '||
                  'else least (hrm_date.days_between ( '||
                                  'greatest(rd.ino_in, vPeriodBegin), '||
                                  'least(nvl(rd.ino_out, vPeriodEnd), vPeriodEnd)), '||
                              'sum (emp_days)) / 30 end, '||
        'vPrecision) numval '||
    'from (select hrm_date.days_between( '||
                      'greatest(trunc(emp_value_from, ''Month''), vPeriodBegin), '||
                      'least(last_day(emp_value_to), vPeriodEnd)) emp_days, '||
                 'emp_num_value, hrm_employee_id '||
          'from hrm_employee_elements '||
          'where emp_value_from <= vPeriodEnd and '||
                'emp_value_to >= vPeriodBegin and '||
                'hrm_elements_id = vElemId) c '||
    'where c.hrm_employee_id = rd.hrm_person_id';

  STMT_UPD_ACT_CONST_CODE CONSTANT VARCHAR2(2000) :=
    'select ct.cod_code val from hrm_code_table ct '||
    'where ct.hrm_code_table_id = '||
      '(select c.hrm_code_table_id from hrm_employee_const c '||
       'where c.hrm_constants_id = vElemId and '||
         'c.hrm_employee_id = rd.hrm_person_id and '||
         'emc_value_from = (select max (emc_value_from) '||
                           'from hrm_employee_const c2 '||
                           'where c2.hrm_constants_id = vElemId and '||
                              'c2.hrm_employee_id = rd.hrm_person_id and '||
                              'c2.emc_value_from <= vPeriodEnd and '||
                              'c2.emc_value_to >= vPeriodBegin))';

  STMT_UPD_HIS CONSTANT VARCHAR2(2000) :=
   'select round ( '||
       'his_pay_sum_val * '||
           'case when vRate = 1 then 1 '||
                'else (hrm_date.days_between ( '||
                                'greatest(rd.ino_in, vPeriodBegin), '||
                                'least(nvl(rd.ino_out, vPeriodEnd), vPeriodEnd)))/30 end, '||
       'vPrecision) numval '||
   'from hrm_history_detail h '||
   'where h.hrm_elements_id = vElemId and '||
     'h.hrm_employee_id = rd.hrm_person_id and '||
     'h.his_pay_num = (select max(hit_pay_num) from hrm_history h2 '||
                      'where h2.hrm_employee_id = rd.hrm_person_id and '||
                        'h2.hit_reversal = 0 and h2.hit_reversed = 0)';

  STMT_UPD_HIS_TXT CONSTANT VARCHAR2(2000) :=
    'select replace(his_pay_value, ''"'','''') '||
    'from hrm_history_detail h '||
    'where hrm_elements_id = vElemId and '||
      'h.hrm_employee_id = rd.hrm_person_id and '||
      'h.his_pay_num = (select max(hit_pay_num) from hrm_history h2 '||
                       'where h2.hrm_employee_id = rd.hrm_person_id and '||
                         'h2.hit_reversal = 0 and h2.hit_reversed = 0)';


  procedure Import(V_HRM_SALARY_REVISION_ID IN HRM_SALARY_REVISION.HRM_SALARY_REVISION_ID%Type)
  is
    vSalaryRevModelId HRM_SALARY_REV_MODEL.HRM_SALARY_REV_MODEL_ID%Type;
    vPeriodBegin HRM_SALARY_REVISION.REV_DATE_FROM%Type;
    vPeriodEnd HRM_SALARY_REVISION.REV_DATE_TO%Type;
  begin
    select hrm_salary_rev_model_id, rev_date_from, rev_date_to
    into vSalaryRevModelId, vPeriodBegin, vPeriodEnd
    from hrm_salary_revision
    where hrm_salary_revision_id = V_HRM_SALARY_REVISION_ID;

    delete HRM_SALARY_REV_DETAIL
    where HRM_SALARY_REVISION_ID = V_HRM_SALARY_REVISION_ID;

    insert into HRM_SALARY_REV_DETAIL
    (HRM_SALARY_REV_DETAIL_ID, HRM_SALARY_REVISION_ID, C_HRM_REVISION_DET_STATUS,
     HRM_PERSON_ID, PER_LAST_NAME, PER_FIRST_NAME,
     EMP_NUMBER, PER_BIRTH_DATE,
     INO_IN, INO_OUT,
     A_DATECRE, A_IDCRE)
    select init_id_seq.NextVal, V_HRM_SALARY_REVISION_ID, '01',
      P.HRM_PERSON_ID, P.PER_LAST_NAME, P.PER_FIRST_NAME,
      P.EMP_NUMBER, P.PER_BIRTH_DATE, I.INO_IN, I.INO_OUT,
      SysDate, pcs.PC_I_LIB_SESSION.GetUserIni
    from HRM_IN_OUT I, HRM_PERSON P
    where I.HRM_EMPLOYEE_ID = P.HRM_PERSON_ID and
      I.INO_IN <= vPeriodEnd and Nvl(I.INO_OUT, vPeriodEnd) >= vPeriodBegin and
      I.C_IN_OUT_CATEGORY = '3';


    -- Importation données de comptabilisation
    UPDATE HRM_SALARY_REV_DETAIL s
    SET REV_BREAK =
      get_hrm_employee_break_xml(hrm_person_id, vPeriodBegin, vPeriodEnd)
    WHERE HRM_SALARY_REVISION_ID = V_HRM_SALARY_REVISION_ID AND
        EXISTS (SELECT 1 FROM HRM_EMPLOYEE_BREAK b
                WHERE b.HRM_EMPLOYEE_ID = s.HRM_PERSON_ID AND HEB_DEFAULT_FLAG = 1);


    -- Initialisation des valeurs
    InitValues(V_HRM_SALARY_REVISION_ID, vSalaryRevModelId, vPeriodBegin, vPeriodEnd);
  end;

  function get_hrm_employee_break_xml(vEmpId IN HRM_PERSON.HRM_PERSON_ID%Type,
    vPeriodBegin IN HRM_SALARY_REVISION.REV_DATE_FROM%Type,
    vPeriodEnd IN HRM_SALARY_REVISION.REV_DATE_TO%Type)
    return Clob
  is
    xmldata XMLType;
  begin
    xmldata := get_hrm_employee_break_xmlType(vEmpId, vPeriodBegin, vPeriodEnd);
    return '<?xml version="1.0" ?>'||xmldata.getClobVal();
  end;

  function get_hrm_employee_break_xmlType(vEmpId IN HRM_PERSON.HRM_PERSON_ID%Type,
    vPeriodBegin IN HRM_SALARY_REVISION.REV_DATE_FROM%Type,
    vPeriodEnd IN HRM_SALARY_REVISION.REV_DATE_TO%Type)
    return xmltype
  is
    obj xmltype;
  begin
    if vEmpId is not null then

      SELECT XMLELEMENT(BREAK_ROOT,
         (SELECT
            XMLAGG(xmlelement(BREAK,
                XMLFOREST(
                    to_char(vPeriodBegin, 'yyyy/mm/dd') date_from,
                    to_char(vPeriodEnd, 'yyyy/mm/dd') date_to,
                    to_char(heb_ratio, 'FM999990.000') heb_ratio,
                    heb_department_id,
                    heb_div_number,
                    heb_cda_number,
                    heb_pf_number,
                    heb_pj_number,
                    heb_shift,
                    heb_rco_title)))
          FROM hrm_employee_break
          WHERE hrm_employee_id = vEmpId AND
            heb_default_flag = 1))
      into obj
      FROM dual;

    end if;

    return obj;

    exception
      when others then
        return null;
  end;

  procedure InitValues(V_HRM_SALARY_REVISION_ID IN HRM_SALARY_REVISION.HRM_SALARY_REVISION_ID%Type,
    V_HRM_SALARY_REV_MODEL_ID IN HRM_SALARY_REV_MODEL.HRM_SALARY_REV_MODEL_ID%Type,
    vPeriodBegin IN HRM_SALARY_REVISION.REV_DATE_FROM%Type,
    vPeriodEnd IN HRM_SALARY_REVISION.REV_DATE_TO%Type)
  is
    stmt VARCHAR2(32767);
    stmtUpd VARCHAR2(32767);

    cursor crModel is
      -- Recherche des éléments à initialiser
      select xmlCol, xmlMode, xmlEleCode, elemId,
             r.elr_root_rate, r.elr_input_precision, c_hrm_sal_const_type,
             case when instr(lower(xmlEleCode), 'conem') <> 1 then 0 else 1 end IsConst
      from hrm_elements_root r,
           (select EXTRACTVALUE(VALUE (P), 'COLUMN/@NAME') xmlCol,
                   EXTRACTVALUE(VALUE (P), 'COLUMN/INIT_MODE') xmlMode,
                   EXTRACTVALUE(VALUE (P), 'COLUMN/INIT_ELEM') xmlEleCode,
                   (select elemid from v_hrm_elements_short
                    where code = EXTRACTVALUE(VALUE (P), 'COLUMN/INIT_ELEM')) elemId
            from (select xmltype.createXml(rev_model_xml) xml_model
                  from hrm_salary_rev_model where hrm_salary_rev_model_id = V_HRM_SALARY_REV_MODEL_ID),
            table (XMLSEQUENCE(EXTRACT (xml_model, 'REV_MODEL/COLUMNS/COLUMN[INIT_MODE != ''NONE'']')))P
           ) x
      where r.hrm_elements_root_id = (select f.hrm_elements_root_id
                                      from hrm_elements_family f
                                      where f.hrm_elements_id = x.elemid);

  begin
    for tplModel in crModel loop

      -- Détermination de la commande SQL
      stmtUpd := null;
      if tplModel.xmlMode = 'ACT' then
        if Instr(tplModel.xmlCol, 'AMOUNT') <> 0 then
          if instr(lower(tplModel.xmlEleCode), 'conem') = 1 then
            stmtUpd := STMT_UPD_ACT_CONST;
          else
            stmtUpd := STMT_UPD_ACT_VAR;
          end if;
        elsif tplModel.c_hrm_sal_const_type in (1,2) then
          stmtUpd := STMT_UPD_ACT_CONST_CODE;
        end if;
      elsif tplModel.xmlMode = 'HIS' then
        if Instr(tplModel.xmlCol, 'AMOUNT') <> 0 then
          stmtUpd := STMT_UPD_HIS;
        else
          stmtUpd := STMT_UPD_HIS_TXT;
        end if;
      end if;

      if stmtUpd is not null then
        stmt := Replace(Replace(STMT_INIT_VAL,
                                '[COL_NAME]', tplModel.xmlCol),
                        '[UPDATE_SQL]', stmtUpd);

        execute immediate stmt using
            IN tplModel.elemId, IN vPeriodBegin, IN vPeriodEnd,
            IN tplModel.elr_root_rate, IN tplModel.elr_input_precision,
            IN V_HRM_SALARY_REVISION_ID;
      end if;

    end loop;
  end;

END HRM_SALARY_REVIEW;
